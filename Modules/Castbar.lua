-- Optional player cast bar (cast and channel) with icon, spell name and time.
local ADDON, HHT = ...
local L, UI, Bar = HHT.L, HHT.UI, HHT.Bar

HHT:AddGerman({
    ["Cast bar"] = "Zauberleiste",
    ["Player cast bar with icon, spell name and time."] = "Zauberleiste des Spielers mit Symbol, Zaubername und Zeit.",
    ["Show spell icon"] = "Zaubersymbol zeigen",
    ["Show spell name"] = "Zaubernamen zeigen",
    ["Hide the default cast bar"] = "Standard-Zauberleiste ausblenden",
    ["Cast"] = "Zauber",
    ["Channel"] = "Kanalisierung",
    ["Failed"] = "Fehlgeschlagen",
    ["Interrupted"] = "Unterbrochen",
})

local M = HHT:NewModule("castbar", {
    name = "Cast bar",
    desc = "Player cast bar with icon, spell name and time.",
    positions = { main = { "CENTER", "CENTER", 0, -128 } },
    defaults = {
        showIcon = true, showLabel = true, showTime = true, showSpark = true, border = true,
        hideDefault = false, barTexture = "blizzard", bevel = 0.6, flash = true, flashGlow = 1, flashGlowSize = 8,
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

-- name, icon, startSec, endSec for the current cast or channel; nil when none or unreadable
local function ReadCast()
    local ok, name, _, icon, s, e = pcall(UnitCastingInfo, "player")
    if ok and name and not HHT.IsSecret(name) then
        s, e = Num(s), Num(e)
        if s and e and e > s then return name, icon, s / 1000, e / 1000, false end
    end
    ok, name, _, icon, s, e = pcall(UnitChannelInfo, "player")
    if ok and name and not HHT.IsSecret(name) then
        s, e = Num(s), Num(e)
        if s and e and e > s then return name, icon, s / 1000, e / 1000, true end
    end
end

function M:OnInit()
    self.state = nil
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
    f.icon = CreateFrame("Frame", nil, f)
    f.icon.tex = f.icon:CreateTexture(nil, "ARTWORK")
    f.icon.tex:SetAllPoints()
    f.icon.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.icon.edge = UI.Border(f.icon, 1, 1, 1, 1)
    f.bar = Bar.New(f)
    HHT:MakeMovable(f, self, "main", L("Cast bar"))
    self:Layout()
end

function M:SetDefaultBar(hidden)
    local b = _G.PlayerCastingBarFrame
    if b and b.SetAlpha then b:SetAlpha(hidden and 0 or 1) end
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
    Bar.Apply(f.bar, db, "cast")
    f.icon:SetSize(h, h)
    f.icon:ClearAllPoints()
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.icon.edge:SetColor(HHT.Col(db, "edge"))
    f.icon:SetShown(db.showIcon)
    f.bar:ClearAllPoints()
    local off = db.showIcon and (h + 2) or 0
    f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", off, 0)
    f.bar:SetSize(db.width - off, h)
    HHT:ApplyGlobalLook(f)
end

function M:Sync()
    local name, icon, s, e, channel = ReadCast()
    if name then
        self.state = { name = name, icon = icon, s = s, e = e, channel = channel }
    else
        self.state = nil
    end
end

function M:OnCastEvent(event, unit)
    if unit ~= "player" then return end
    local prev = self.state
    self:Sync()
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
    if not self.db.flash or not UI.Anim() or not self.frame then return end
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

    local name, icon, progress, remain, color
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
    if st then
        local dur = st.e - st.s
        local t = math.min(dur, math.max(0, now - st.s))
        progress = st.channel and (1 - t / dur) or (t / dur)
        remain = dur - t
        name, icon = st.name, st.icon
        color = st.channel and "channel" or "cast"
    elseif self.done and now < self.done.till then
        progress, remain, name, icon = 1, nil, self.done.name, self.done.icon
        color = self.done.channel and "channel" or "cast"
    elseif self.failUntil and now < self.failUntil then
        progress, remain, name, color = 1, nil, self.failText, "fail"
        icon = f.icon.tex:GetTexture()
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

    if not progress then
        if f:IsShown() then f:Hide() end
        return
    end
    if not f:IsShown() then f:Show() end

    bar.bar:SetMinMaxValues(0, 1)
    bar.bar:SetValue(progress)
    bar.bar:SetStatusBarColor(HHT.Col(db, color))
    bar.label:SetText(name or "")
    bar.time:SetText(remain and string.format("%.1f", remain) or "")
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
    form:Check(L("Show spell name"), db, "showLabel")
    form:Check(L("Show remaining time"), db, "showTime")
    form:Check(L("Show spark"), db, "showSpark")
    form:Check(L("Show border"), db, "border")
    form:Stepper(L("Bar width"), db, "width", 100, 600, 10)
    form:Stepper(L("Bar height"), db, "height", 8, 48, 1)
    form:Stepper(L("Background opacity"), db, "bgAlpha", 0, 1, 0.05)
    Bar.AddOptions(form, db)
    Bar.AddFlash(form, db)
    form:Header(L("Behavior"))
    form:Check(L("Hide the default cast bar"), db, "hideDefault")
    form:Header(L("Colors"))
    form:Color(L("Cast"), db.colors, "cast")
    form:Color(L("Channel"), db.colors, "channel")
    form:Color(L("Failed"), db.colors, "fail")
    form:Color(L("Background color"), db.colors, "bg")
    form:Color(L("Border color"), db.colors, "edge")
    form:Color(L("Text color"), db.colors, "text")
end
