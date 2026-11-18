-- Optional player cast bar (cast and channel) with icon, spell name and time.
local ADDON, HHT = ...
local L, UI, Bar = HHT.L, HHT.UI, HHT.Bar

HHT:AddGerman({
    ["Cast bar"] = "Zauberleiste",
    ["Player cast bar with icon, spell name and time."] = "Zauberleiste des Spielers mit Symbol, Zaubername und Zeit.",
    ["Show spell icon"] = "Zaubersymbol zeigen",
    ["Space to icon"] = "Abstand zum Symbol",
    ["Show spell name"] = "Zaubernamen zeigen",
    ["Hide the default cast bar"] = "Standard-Zauberleiste ausblenden",
    ["Move cast bar to back"] = "Zauberleiste nach hinten legen",
    ["Cast"] = "Zauber",
    ["Looting"] = "Looten",
    ["Channel"] = "Kanalisierung",
    ["Failed"] = "Fehlgeschlagen",
    ["Interrupted"] = "Unterbrochen",
})

local M = HHT:NewModule("castbar", {
    name = "Cast bar",
    desc = "Player cast bar with icon, spell name and time.",
    positions = { main = { "CENTER", "CENTER", 0, -128 } },
    defaults = {
        showIcon = true, showLabel = true, showTime = true, showSpark = true, border = true, borderSize = 1, shape = "square", iconGap = 2,
        hideDefault = true, visibility = "always", barTexture = "blizzard", barShape = "square", bevel = 0.6, flash = true, flashGlow = 1, flashGlowSize = 8,
        width = 260, height = 22, bgAlpha = 0.85,
        colors = {
            cast = { 0.67, 0.83, 0.45 },
            channel = { 0.40, 0.70, 0.90 },
            fail = { 0.90, 0.20, 0.20 },
            bg = { 0.05, 0.04, 0.03 },
            edge = { 0.55, 0.42, 0.20 },
            text = { 0.95, 0.93, 0.85 },
        },
    },
})

local function Num(v)
    return HHT.SafeNumber(v)
end

-- Opening a quest object or chest runs an internal spell called "Opening - No Text"
local function Pretty(name)
    if name:find("No Text", 1, true) or name:find("Kein Text", 1, true) then return L("Looting") end
    return name
end

-- name, icon, startSec, endSec, channel, spellID for the current cast or channel; nil when none or unreadable
local function ReadCast()
    local ok, name, _, icon, s, e, _, _, _, spellID = pcall(UnitCastingInfo, "player")
    if ok and name and not HHT.IsSecret(name) then
        s, e = Num(s), Num(e)
        if s and e and e > s then return Pretty(name), icon, s / 1000, e / 1000, false, Num(spellID) end
    end
    ok, name, _, icon, s, e, _, _, spellID = pcall(UnitChannelInfo, "player")
    if ok and name and not HHT.IsSecret(name) then
        s, e = Num(s), Num(e)
        if s and e and e > s then return Pretty(name), icon, s / 1000, e / 1000, true, Num(spellID) end
    end
end

-- "m:ss" from one minute up, otherwise seconds with one decimal
local function Clock(sec)
    if sec >= 60 then return string.format("%d:%02d", sec / 60, sec % 60) end
    return string.format("%.1f", sec)
end

-- A crafting window asking for several items runs one cast per item; the requested amount is only known at that call.
function M:HookCrafting()
    local function Queue(count)
        count = tonumber(count)
        self.batch = nil
        self.pending = count and count > 1 and { total = math.floor(count), t = GetTime() } or nil
    end
    if _G.DoTradeSkill then pcall(hooksecurefunc, "DoTradeSkill", function(_, n) Queue(n) end) end
    if _G.C_TradeSkillUI and C_TradeSkillUI.CraftRecipe then
        pcall(hooksecurefunc, C_TradeSkillUI, "CraftRecipe", function(_, n) Queue(n) end)
    end
end

function M:OnInit()
    self.state = nil
    self:HookCrafting()
    for _, ev in ipairs({
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_CHANNEL_UPDATE",
    }) do
        HHT:Listen(self, ev, "OnCastEvent")
    end
    HHT:Every(self, 0.02, M.Tick)
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsCastbar", UIParent)
    f:SetSize(260, 22)
    f:Hide()
    self.frame = f
    f.icon = HHT.Icon.New(f)
    f.bar = Bar.New(f)
    HHT:MakeMovable(f, self, "main", L("Cast bar"))
    self:Layout()
end

-- Blizzard raises the bar's alpha again whenever a cast starts, so the hidden state is enforced by hooks.
function M:SetDefaultBar(hidden)
    local b = _G.PlayerCastingBarFrame
    if not b then return end
    M.defaultHidden = hidden and true or false
    if hidden then b:SetAlpha(0) else b:SetAlpha(1) end
    -- detaching the unit stops the bar from reacting to cast events at all (interrupt and failed states included)
    if b.SetUnit then
        if hidden then pcall(b.SetUnit, b, nil) else pcall(b.SetUnit, b, "player", true, false) end
    end
    if M.defaultHooked then return end
    M.defaultHooked = true
    local busy = false
    if b.SetUnit then
        pcall(hooksecurefunc, b, "SetUnit", function(f, unit)
            if M.defaultHidden and unit and not busy then
                busy = true
                pcall(f.SetUnit, f, nil)
                busy = false
            end
        end)
    end
    local function Enforce(f)
        if not M.defaultHidden or busy then return end
        busy = true
        f:SetAlpha(0)
        busy = false
    end
    -- the alpha passed in can be a secret value, so it is never compared; every call is simply overridden
    for _, fn in ipairs({ "SetAlpha", "SetAlphaFromBoolean", "Show", "SetShown" }) do
        if b[fn] then pcall(hooksecurefunc, b, fn, Enforce) end
    end
    pcall(b.HookScript, b, "OnShow", Enforce)
    pcall(b.HookScript, b, "OnUpdate", Enforce)
end

function M:OnEnable()
    self:Build()
    self:SetDefaultBar(self.db.hideDefault)
    self:Sync()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
    self:SetDefaultBar(false)
end

function M:OnLockChanged()
    self:Layout()
end

function M:Refresh()
    self:Layout()
    self:SetDefaultBar(self.db.hideDefault)
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self.db
    local h = db.height
    f:SetSize(db.width, h)
    f:SetFrameStrata(db.toBack and "MEDIUM" or "FULLSCREEN_DIALOG")
    Bar.Apply(f.bar, db, "cast")
    local bs = db.border ~= false and math.max(0, math.min(4, db.borderSize or 1)) or 0
    f.icon:SetBorderColor(HHT.Col(db, "edge"))
    f.icon:Style(h, db.shape, bs, 1, false)
    f.icon:ClearAllPoints()
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.icon:SetShown(db.showIcon)
    f.bar:ClearAllPoints()
    local off = db.showIcon and (h + 2 * bs + (db.iconGap or 2)) or 0
    f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", off, 0)
    f.bar:SetSize(db.width - off, h)
    HHT:ApplyGlobalLook(f)
end

function M:Sync()
    local name, icon, s, e, channel, spellID = ReadCast()
    if name then
        self.state = { name = name, icon = icon, s = s, e = e, channel = channel, spellID = spellID }
    else
        self.state = nil
    end
end

-- Counts the casts of a multi-craft; any other spell, a cancel or a pause ends it.
function M:TrackBatch(event)
    local st = self.state
    local b = self.batch
    if event == "UNIT_SPELLCAST_INTERRUPTED" then self.batch, self.pending = nil, nil; return end
    if event ~= "UNIT_SPELLCAST_START" or not st then return end
    local p = self.pending
    if p and GetTime() - p.t < 5 then
        self.batch = { total = p.total, index = 1, spellID = st.spellID, dur = st.e - st.s, name = st.name, icon = st.icon }
    elseif b and b.spellID == st.spellID and b.index < b.total then
        b.index = b.index + 1
        b.dur = st.e - st.s
    else
        self.batch = nil
    end
    self.pending = nil
end

function M:OnCastEvent(event, unit)
    if unit ~= "player" then return end
    local prev = self.state
    self:Sync()
    self:TrackBatch(event)
    -- a stop right at the end of the cast is a completion; earlier stops are cancels
    if prev and not self.state and GetTime() >= prev.e - 0.25
        and (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP") then
        self:Complete(prev)
    end
    -- FAILED also fires for spell queueing (e.g. Aimed Shot then Arcane Shot), so only real interrupts show
    if not self.state and event == "UNIT_SPELLCAST_INTERRUPTED" then
        self.failUntil = GetTime() + 0.6
        self.failText = L("Interrupted")
    end
end

-- Keeps the full bar on screen for the length of the flash.
function M:Complete(st)
    if not self.db.flash or not self.frame then return end
    -- inside a multi-craft only the last cast fills the bar and flashes
    local b = self.batch
    if b and b.spellID == st.spellID and b.index < b.total then return end
    if self.doneS == st.s and self.doneE == st.e then return end
    self.doneS, self.doneE = st.s, st.e
    self.done = { name = st.name, icon = st.icon, channel = st.channel, till = GetTime() + Bar.FLASH_TIME }
    Bar.Flash(self.frame.bar)
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    local now = GetTime()
    local st = self.state
    local unlocked = HHT:IsUnlocked(self)
    local bar = f.bar

    local name, icon, progress, remain, color, total
    if st then
        local dur = st.e - st.s
        local t = now - st.s
        if t >= dur then
            self:Complete(st)
            self.state = nil
            self:Sync()
            st = self.state
        end
    end
    if st and not (self.doneS == st.s and self.doneE == st.e) then self.done = nil end
    local b = self.batch
    if b then
        -- the next cast of a batch starts right after the last one; a longer pause means it ended
        if st then b.gap = nil
        else
            b.gap = b.gap or now
            if now - b.gap > 1.5 then self.batch, b = nil, nil end
        end
    end
    if st then
        local dur = st.e - st.s
        local t = math.min(dur, math.max(0, now - st.s))
        progress = st.channel and (1 - t / dur) or (t / dur)
        remain = dur - t
        name, icon = st.name, st.icon
        color = st.channel and "channel" or "cast"
        if b and b.spellID == st.spellID then
            name = string.format("%s (%d/%d)", name, b.index, b.total)
            total = remain + (b.total - b.index) * dur
            -- the bar covers the whole batch and only fills when the last item is done
            progress = ((b.index - 1) * dur + t) / (b.total * dur)
        end
    elseif self.done and now < self.done.till then
        progress, remain, name, icon = 1, nil, self.done.name, self.done.icon
        color = self.done.channel and "channel" or "cast"
    elseif b and b.index < b.total then
        -- short pause between two casts of a batch
        progress, name, icon, color = b.index / b.total, string.format("%s (%d/%d)", b.name, b.index, b.total), b.icon, "cast"
    elseif self.failUntil and now < self.failUntil then
        progress, remain, name, color = 1, nil, self.failText, "fail"
        icon = f.icon.tex:GetTexture()
    elseif unlocked and HHT.shotValues and HHT.shotValues.cast then
        local pct = HHT.shotValues.cast
        progress, remain = pct / 100, pct < 100 and 2.5 * (1 - pct / 100) or nil
        name, color = L("Cast bar"), "cast"
        icon = HHT.Spells.Resolve("@autoShot").icon
    elseif unlocked then
        local dur = 2.5
        local pause = db.flash and Bar.FLASH_TIME or 0
        local t = now % (dur + pause)
        if t < dur then
            progress, remain = t / dur, dur - t
            self.demoFull = false
        else
            progress, remain = 1, nil
            if not self.demoFull then Bar.Flash(bar) end
            self.demoFull = true
        end
        name, color = L("Cast bar"), "cast"
        icon = HHT.Spells.Resolve("@autoShot").icon
    end

    if not progress or not HHT:ShouldShow(db.visibility, self) then
        if f:IsShown() then f:Hide() end
        return
    end
    if not f:IsShown() then f:Show() end

    bar.bar:SetMinMaxValues(0, 1)
    bar.bar:SetValue(progress)
    bar.bar:SetStatusBarColor(HHT.Col(db, color))
    bar.label:SetText(name or "")
    local timeText = remain and string.format("%.1f", remain) or ""
    if total and remain then timeText = timeText .. "  (" .. Clock(total) .. ")" end
    bar.time:SetText(timeText)
    if icon then f.icon.tex:SetTexture(icon) end
    if db.showSpark and remain then
        bar.spark:ClearAllPoints()
        bar.spark:SetPoint("CENTER", bar.bar, "LEFT", (bar:GetWidth() - 2) * progress, 0)
        bar.spark:Show()
    else
        bar.spark:Hide()
    end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Check(L("Show spell icon"), db, "showIcon")
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Space to icon"), db, "iconGap", 0, 20, 1)
    form:Check(L("Show spell name"), db, "showLabel")
    form:Check(L("Show remaining time"), db, "showTime")
    form:Check(L("Show spark"), db, "showSpark")
    Bar.AddBorder(form, db)
    form:Stepper(L("Bar width"), db, "width", 100, 600, 10)
    form:Stepper(L("Bar height"), db, "height", 8, 48, 1)
    form:Stepper(L("Background opacity"), db, "bgAlpha", 0, 1, 0.05)
    Bar.AddOptions(form, db)
    Bar.AddFlash(form, db)
    form:Header(L("Behavior"))
    form:Check(L("Hide the default cast bar"), db, "hideDefault")
    form:Check(L("Move cast bar to back"), db, "toBack")
    form:Header(L("Colors"))
    form:Color(L("Cast"), db.colors, "cast")
    form:Color(L("Channel"), db.colors, "channel")
    form:Color(L("Failed"), db.colors, "fail")
    form:Color(L("Background color"), db.colors, "bg")
    form:Color(L("Border color"), db.colors, "edge")
    form:Color(L("Text color"), db.colors, "text")
end
