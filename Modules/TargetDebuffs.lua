-- Target debuffs via the client's native aura container: the engine fills icons, timers and stacks itself, so it works while auras are secret.
-- Also hosts HHT.AuraBar, the shared engine plumbing (used by Warnings too).
local ADDON, HHT = ...
local L, S, Icon, UI = HHT.L, HHT.Spells, HHT.Icon, HHT.UI
local IsSecret = HHT.IsSecret

HHT:AddGerman({
    ["Target Debuffs"] = "Ziel-Debuffs",
    ["Your Serpent Sting and other debuffs on the target, with timer, also in combat."] = "Dein Schlangenbiss und andere Debuffs auf dem Ziel, mit Zeit, auch im Kampf.",
    ["Show my other debuffs"] = "Meine anderen Debuffs anzeigen",
    ["Maximum icons"] = "Maximale Symbole",
    ["Which debuffs"] = "Welche Debuffs",
    ["Only my debuffs"] = "Nur meine Debuffs",
    ["All debuffs"] = "Alle Debuffs",
    ["Border color"] = "Randfarbe",
    ["Blink the red placeholder when a tracked debuff is missing"] = "Roten Platzhalter blinken lassen, wenn ein ueberwachter Debuff fehlt",
    ["Tracked debuffs"] = "Ueberwachte Debuffs",
    ["Ticked debuffs get a fixed slot and a red placeholder while they are missing. The button sets on which targets the placeholder shows. Debuffs that are not ticked still appear in the normal row when active."] =
        "Angehakte Debuffs bekommen einen festen Platz und einen roten Platzhalter, solange sie fehlen. Der Knopf legt fest, bei welchen Zielen der Platzhalter erscheint. Nicht angehakte Debuffs erscheinen weiter in der normalen Reihe, wenn sie aktiv sind.",
    ["All targets"] = "Alle Ziele",
    ["Elites and bosses"] = "Elite und Bosse",
    ["Bosses only"] = "Nur Bosse",
    ["Spell ID(s), several ranks separated by comma"] = "Zauber-ID(s), mehrere Raenge mit Komma getrennt",
    ["Add"] = "Hinzufuegen",
    ["Spell ID"] = "Zauber-ID",
    ["The game fills these icons itself. A red dimmed icon means the debuff is not on the target (missed, immune or expired). Size and border changes apply out of combat."] =
        "Das Spiel befuellt diese Symbole selbst. Ein rotes, abgedunkeltes Symbol heisst: der Debuff ist nicht auf dem Ziel (verfehlt, immun oder ausgelaufen). Aenderungen an Groesse und Rand wirken ausserhalb des Kampfes.",
    ["This client has no aura container, Target Debuffs cannot work here."] = "Dieser Client hat keinen Aura-Container, Ziel-Debuffs funktionieren hier nicht.",
})

local function Aura(name) return _G[name] end

local function EnumValue(tbl, ...)
    if not tbl then return nil end
    for i = 1, select("#", ...) do
        local v = tbl[select(i, ...)]
        if v ~= nil then return v end
    end
end

-- Flow layout per grow direction: axis, horizontal/vertical direction, anchor corner.
local FLOW = {
    right = { "HORIZONTAL", "FORWARD", "FORWARD", "BOTTOMLEFT" },
    left = { "HORIZONTAL", "BACKWARD", "FORWARD", "BOTTOMRIGHT" },
    up = { "VERTICAL", "FORWARD", "FORWARD", "BOTTOMLEFT" },
}

local function ApplyFlow(container, grow, wrap)
    local f = FLOW[grow] or FLOW.right
    local A = AnchorUtil
    local axisE, dirE = A and A.FlowLayoutAxis, A and A.FlowDirection
    local axis = f[1] == "VERTICAL" and EnumValue(axisE, "Vertical", "VERTICAL", "Y") or EnumValue(axisE, "Horizontal", "HORIZONTAL", "X")
    local function Dir(v)
        if v == "BACKWARD" then return EnumValue(dirE, "Down", "Left", "Backward", "BACKWARD", "Negative") end
        return EnumValue(dirE, "Up", "Right", "Forward", "FORWARD", "Positive")
    end
    local h, v = Dir(f[2]), Dir(f[3])
    if axis == nil or not h or not v then return false end
    container:SetFlowLayoutAxis(axis)
    container:SetFlowLayoutGrowthDirection(h, v)
    container:SetFlowLayoutAnchorPoint(f[4])
    container:SetFlowLayoutMaximumLineSize(math.max(1, wrap))
    return true
end

local MASK = "Interface\\AddOns\\" .. ADDON .. "\\Media\\RoundMask"
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Round look for an engine-made button: mask on icon and border, round swipe.
local function SetRound(e, on)
    for _, tex in ipairs({ e.tex, e.border }) do
        if on then
            if not tex.hhtMask then
                local m = e.button:CreateMaskTexture()
                m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                m:SetAllPoints(tex)
                tex.hhtMask = m
            end
            if not tex.hhtOn then tex:AddMaskTexture(tex.hhtMask); tex.hhtOn = true end
        elseif tex.hhtOn then
            tex:RemoveMaskTexture(tex.hhtMask)
            tex.hhtOn = false
        end
    end
    pcall(e.cd.SetSwipeTexture, e.cd, on and MASK or WHITE)
end

-- ---------------------------------------------------------------------------
-- AuraBar: containers and groups of engine-drawn aura icons inside one frame.
-- style() returns { size, spacing, shape, borderSize, borderAlpha, color = {r,g,b} }.
-- ---------------------------------------------------------------------------
local AuraBar = {}
AuraBar.__index = AuraBar
HHT.AuraBar = AuraBar
AuraBar.FLOW = FLOW

function AuraBar.New(frame, style)
    local bar = setmetatable({ frame = frame, style = style, buttons = {}, groups = {}, conts = {}, errors = {} }, AuraBar)
    local ok, probe = pcall(CreateFrame, "AuraContainer", nil, frame, "CustomAuraContainerTemplate")
    bar.engine = ok and probe ~= nil
    if bar.engine then probe:Hide() end
    return bar
end

function AuraBar:Guard(label, fn, ...)
    local ok, err = pcall(fn, ...)
    self.errors[label] = (not ok) and tostring(err) or nil
    return ok, err
end

-- Applies size and border to one engine-made button; only possible where the engine allows access.
function AuraBar:StyleButton(e)
    local b = e.button
    if b.CanBeAccessedInContext and not b:CanBeAccessedInContext() then return end
    local st = self.style()
    local s, bs = st.size, st.borderSize
    b:SetSize(s, s)
    e.border:ClearAllPoints()
    e.border:SetPoint("TOPLEFT", b, "TOPLEFT", -bs, bs)
    e.border:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", bs, -bs)
    e.border:SetShown(bs > 0)
    e.border:SetColorTexture(st.color[1], st.color[2], st.color[3], st.borderAlpha)
    SetRound(e, st.shape == "round")
    if e.fin then Icon.ApplyFinish(e.fin, s, st.shape == "round", bs) end
end

function AuraBar:StyleAll()
    for _, e in ipairs(self.buttons) do self:Guard("style", self.StyleButton, self, e) end
end

function AuraBar:InitButton(button)
    button:EnableMouse(false)
    local border = button:CreateTexture(nil, "BACKGROUND")
    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button:SetIcon(tex)
    local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetHideCountdownNumbers(false)
    cd:SetDrawEdge(false)
    cd:SetReverse(true)
    button:SetDurationCooldown(cd)
    local tf = CreateFrame("Frame", nil, button)
    tf:SetAllPoints()
    tf:SetFrameLevel(button:GetFrameLevel() + 3)
    local count = tf:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", -1, 2)
    button:SetApplicationCount(count, {})
    local e = { button = button, border = border, tex = tex, cd = cd }
    e.fin = Icon.NewFinish(button, border)
    self.buttons[#self.buttons + 1] = e
    self:StyleButton(e)
end

function AuraBar:NewContainer(unit)
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, self.frame, "CustomAuraContainerTemplate")
    if not (ok and c) then
        self.errors.container = tostring(c)
        return nil
    end
    pcall(c.SetUnit, c, unit)
    if c.SetEnabled then pcall(c.SetEnabled, c, true) end
    pcall(c.SetFrameLevel, c, self.frame:GetFrameLevel() + 5)
    return c
end

-- Adds the group once, afterwards only re-applies its settings. The unit is fixed per key.
function AuraBar:Setup(key, unit, filter, candidate, count, grow, x, y, perLine)
    if not self.engine then return end
    local container = self.conts[key] or self:NewContainer(unit)
    if not container then return end
    self.conts[key] = container
    container:Show()
    local st = self.style()
    local s, sp = st.size, st.spacing
    if not self.groups[key] then
        local sortM = Aura("AuraContainerSortMethod")
        local sortD = Aura("AuraContainerSortDirection")
        local ok = self:Guard("add:" .. key, container.AddAuraGroup, container, key, filter, {
            maxFrameCount = count,
            sortMethod = sortM and sortM.Default,
            sortDirection = sortD and sortD.Normal,
            candidateFilters = candidate,
            initializeFrame = function(button) self:Guard("init:" .. key, self.initFn or self.InitButton, self, button, key) end,
        })
        if not ok then return end
        self.groups[key] = true
    else
        self:Guard("count:" .. key, container.SetAuraGroupMaxFrameCount, container, key, count)
        self:Guard("filter:" .. key, container.SetAuraGroupFilterString, container, key, filter)
        self:Guard("cand:" .. key, container.SetAuraGroupCandidateFilters, container, key, candidate)
    end
    local wrap = (perLine or count) * (s + sp)
    if not self:Guard("flow:" .. key, ApplyFlow, container, grow, wrap) then
        self.errors["flow:" .. key] = self.errors["flow:" .. key] or "flow enums missing"
    end
    self:Guard("layout:" .. key, container.SetAuraGroupLayout, container, key, {
        elementWidth = s, elementHeight = s, elementSpacing = sp, lineSpacing = sp, layoutIndex = 1,
    })
    local anchor = (FLOW[grow] or FLOW.right)[4]
    container:ClearAllPoints()
    container:SetPoint(anchor, self.frame, anchor, x, y)
    self:Guard("update:" .. key, container.UpdateAllAuras, container)
end

function AuraBar:Hide(key)
    local c = self.conts[key]
    if c then c:Hide() end
end

-- ---------------------------------------------------------------------------
-- Tracked debuff catalog. cast = ids of the spell (knowledge, name, icon); aura = extra ids of the applied debuff.
-- ---------------------------------------------------------------------------
local Cat = S.Catalog
local BUILTIN = {
    { key = "serpentSting", cast = Cat.serpentSting.ids, track = true },
    { key = "hunterMark", cast = Cat.hunterMark.ids, track = true, targets = "elite" },
    { key = "scorpidSting", cast = { 14277, 14276, 14275, 3043 } },
    { key = "viperSting", cast = { 27018, 14280, 14279, 3034 } },
    { key = "wyvernSting", cast = { 27068, 24133, 24132, 19386 }, aura = { 27069, 24135, 24134, 24131 } },
    { key = "wingClip", cast = { 14268, 14267, 2974 } },
    { key = "concussive", cast = { 5116 } },
    { key = "scatterShot", cast = { 19503 } },
    { key = "immolationTrap", cast = { 27023, 14305, 14304, 14303, 14302, 13795 }, aura = { 27024, 14301, 14300, 14299, 14298, 13797 } },
    { key = "explosiveTrap", cast = { 27025, 14317, 14316, 13813 }, aura = { 27026, 14315, 14314, 13812 } },
    { key = "freezingTrap", cast = { 14311, 14310, 1499 }, aura = { 14309, 14308, 3355 } },
    { key = "counterattack", cast = { 27067, 20910, 20909, 19306 } },
    { key = "scareBeast", cast = { 14327, 14326, 1513 } },
}
local LEGACY = { serpentSting = "showSting", hunterMark = "showMark" }

local MAXTRACK = 8
local MAXCUSTOM = 10
local MAXROW = 12
local ROW_KEY = "hht_row"

local function IdSet(...)
    local set = {}
    for i = 1, select("#", ...) do
        for _, id in ipairs((select(i, ...))) do set[id] = true end
    end
    return set
end
for _, d in ipairs(BUILTIN) do d.ids = IdSet(d.cast, d.aura or {}) end

local M = HHT:NewModule("debuffs", {
    name = "Target Debuffs",
    desc = "Your Serpent Sting and other debuffs on the target, with timer, also in combat.",
    positions = { main = { "CENTER", "CENTER", 0, 60 } },
    defaults = {
        size = 36, shape = "round", borderSize = 2, borderAlpha = 1, spacing = 6, grow = "right", perRow = 20,
        showRow = true, max = 5, filter = "mine", visibility = "target", blink = true,
        entries = {}, custom = {},
        colors = { border = { 0.55, 0.42, 0.20 } },
    },
})
HHT.Debuffs = M

local function ReadTier()
    local ok, c = pcall(UnitClassification, "target")
    if not ok or IsSecret(c) or type(c) ~= "string" then return nil end
    if c == "worldboss" then return 2 end
    local okL, lvl = pcall(UnitLevel, "target")
    if okL and not IsSecret(lvl) and lvl == -1 then return 2 end
    if c == "elite" or c == "rareelite" then return 1 end
    return 0
end
HHT.ReadTier = ReadTier

local TIER = { all = 0, elite = 1, boss = 2 }

function M:BuildEntries()
    local db = self.db
    local list = {}
    for _, d in ipairs(BUILTIN) do
        local cfg = db.entries[d.key]
        if not cfg then
            local legacy = LEGACY[d.key]
            local track = d.track and true or false
            if legacy and db[legacy] == false then track = false end
            cfg = { track = track, targets = d.targets or "all" }
            db.entries[d.key] = cfg
        end
        list[#list + 1] = { key = d.key, cast = d.cast, ids = d.ids, cfg = cfg }
    end
    for i, c in ipairs(db.custom) do
        list[#list + 1] = { key = "custom" .. i, custom = i, cast = c.ids, ids = IdSet(c.ids), cfg = c }
    end
    self.entries = list
    db.showSting, db.showMark, db.markTargets = nil, nil, nil
end

-- Name and icon of an entry from the first id the client knows.
local function Info(e)
    if e.name and e.icon then return e end
    for _, id in ipairs(e.cast) do
        local name = S.Name(id)
        if name then
            e.name = name
            e.icon = S.Texture(id) or S.FALLBACK_ICON
            return e
        end
    end
    e.name = e.custom and (L("Spell ID") .. " " .. tostring(e.cast[1])) or e.key
    e.icon = S.FALLBACK_ICON
    return e
end

local function Known(e)
    if e.custom then return true end
    for _, id in ipairs(e.cast) do
        if S.IsKnown(id) then return true end
    end
    return false
end

function M:Style()
    local db = self.db
    local r, g, b = HHT.Col(db, "border")
    return { size = db.size, spacing = db.spacing, shape = db.shape, borderSize = db.borderSize, borderAlpha = db.borderAlpha, color = { r, g, b } }
end

function M:OnInit()
    self.slotEntry = {}
    self.phs = {}
    self.tier = nil
    self:BuildEntries()
    HHT:Every(self, 0.2, M.Tick)
    HHT:Listen(self, "PLAYER_TARGET_CHANGED", function(m) m.tier = nil end)
    HHT:Listen(self, "SPELLS_CHANGED", function(m) if not HHT.InCombat() then m:Layout() end end)
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsDebuffs", UIParent)
    f:SetSize(36, 36)
    self.frame = f
    for i = 1, MAXTRACK do
        local ph = Icon.New(f)
        ph.tex:SetVertexColor(1, 0.3, 0.3)
        ph:SetAlpha(0.7)
        ph:Hide()
        self.phs[i] = ph
    end
    HHT:MakeMovable(f, self, "main", L("Target Debuffs"))
    self.bar = AuraBar.New(f, function() return self:Style() end)
    if not self.bar.engine then HHT.Print(L("This client has no aura container, Target Debuffs cannot work here.")) end
end

-- Tracked, known entries in list order (at most MAXTRACK).
function M:Active()
    local out = {}
    for _, e in ipairs(self.entries) do
        if e.cfg.track and Known(e) and #out < MAXTRACK then out[#out + 1] = e end
    end
    return out
end

function M:Layout()
    local f, db, bar = self.frame, self.db, self.bar
    if not f then return end
    local s, sp, grow = db.size, db.spacing, db.grow
    local active = self:Active()
    local nRow = db.showRow and math.min(db.max, MAXROW) or 0
    local n = #active + nRow
    local per = math.max(1, db.perRow or 20)
    local step = s + sp
    -- Tracked slots fill the first lines; the other debuffs continue the line when everything fits, else start a new line.
    local oneLine = n <= per
    local trackedLines = math.ceil(#active / per)
    local cols, lines
    if oneLine then
        cols, lines = math.max(1, n), 1
    else
        cols = math.max(math.min(#active, per), math.min(nRow, per))
        lines = trackedLines + math.ceil(nRow / per)
    end
    local across, along = cols * step - sp, lines * step - sp
    if grow == "up" then f:SetSize(along, across) else f:SetSize(across, along) end

    local anchor = (FLOW[grow] or FLOW.right)[4]
    local function Offset(col, line)
        local a, b = col * step, line * step
        if grow == "up" then return b, a end
        return grow == "left" and -a or a, b
    end

    local excl = {}
    for i = 1, MAXTRACK do
        local e = active[i]
        self.slotEntry[i] = e
        local ph = self.phs[i]
        if e then
            local x, y = Offset((i - 1) % per, math.floor((i - 1) / per))
            ph:Style(s, db.shape, 0, 0, false)
            ph:ClearAllPoints()
            ph:SetPoint(anchor, f, anchor, x, y)
            for id in pairs(e.ids) do excl[id] = true end
            bar:Setup("hht_slot" .. i, "target", "HARMFUL|PLAYER", { includeSpellIDs = e.ids }, 1, grow, x, y)
        else
            ph:Hide()
            bar:Hide("hht_slot" .. i)
        end
    end

    if nRow > 0 then
        local rx, ry
        if oneLine then rx, ry = Offset(#active, 0) else rx, ry = Offset(0, trackedLines) end
        bar:Setup(ROW_KEY, "target", db.filter == "all" and "HARMFUL" or "HARMFUL|PLAYER", { excludeSpellIDs = excl }, nRow, grow, rx, ry, per)
    else
        bar:Hide(ROW_KEY)
    end
    bar:StyleAll()
    HHT:ApplyGlobalLook(f)
end

function M:OnEnable()
    self:Build()
    self.frame:Show()
    self:Layout()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
end

function M:Refresh()
    self:BuildEntries()
    self:Layout()
end

function M:OnLockChanged()
    self:Layout()
end

function M:OnReset()
    self:BuildEntries()
end

-- Visibility only by alpha: a hidden container stops parsing auras and comes back stale.
function M:Tick()
    local f, db = self.frame, self.db
    if not f then return end
    local unlocked = HHT:IsUnlocked(self)
    local show = self.bar.engine and (unlocked or (HHT.HasAttackableTarget() and HHT:ShouldShow(db.visibility, self)))
    local g = HHT.db.general
    f:SetAlpha(show and (g.alpha or 1) * (db.alpha or 1) or 0)

    local tier = ReadTier()
    if tier ~= nil then self.tier = tier end
    for i = 1, MAXTRACK do
        local ph, e = self.phs[i], self.slotEntry[i]
        local on = e ~= nil
        if on and not unlocked and self.tier then
            on = self.tier >= (TIER[e.cfg.targets] or 0)
        end
        if on then
            Info(e)
            if ph.hhtIcon ~= e.icon then
                ph.hhtIcon = e.icon
                ph:SetIcon(e.icon)
            end
        end
        if ph:IsShown() ~= on then ph:SetShown(on) end
        ph:SetBlink(on and show and db.blink and not unlocked and true or false)
    end
end

function M:Debug()
    local bar = self.bar
    HHT.Print(string.format("debuffs: engine=%s aurasSecret=%s combat=%s tier=%s", tostring(bar.engine), tostring(S.AurasSecret()), tostring(HHT.InCombat()), tostring(self.tier)))
    for i = 1, MAXTRACK do
        local e = self.slotEntry[i]
        if e then HHT.Print(string.format("slot %d: %s container=%s group=%s", i, Info(e).name, tostring(bar.conts["hht_slot" .. i] ~= nil), tostring(bar.groups["hht_slot" .. i]))) end
    end
    HHT.Print(string.format("row: container=%s group=%s buttons=%d", tostring(bar.conts[ROW_KEY] ~= nil), tostring(bar.groups[ROW_KEY]), #bar.buttons))
    local any
    for label, err in pairs(bar.errors) do
        any = true
        HHT.Print("error " .. label .. ": " .. err)
    end
    if not any then HHT.Print("no errors recorded") end
end

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
local ROW_H = 24
local MODES = { "all", "elite", "boss" }

local function ModeLabel(mode)
    if mode == "elite" then return L("Elites and bosses") end
    if mode == "boss" then return L("Bosses only") end
    return L("All targets")
end

local function BuildTrackList(m, form)
    local db = m.db
    local list = CreateFrame("Frame", nil, form.content)
    list:SetSize(380, 10)
    list.rows = {}

    local function Changed() HHT:RefreshModule(m) end

    local function NewRow(i)
        local row = CreateFrame("Frame", nil, list)
        row:SetSize(380, ROW_H)
        row.on = UI.Check(row, "", function() return row.entry and row.entry.cfg.track end,
            function(v) if row.entry then row.entry.cfg.track = v and true or false; Changed() end end)
        row.on:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.on:SetWidth(18)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", row, "LEFT", 24, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        HHT.Icon.Attach(row.icon)
        row.text = UI.Text(row, "", 12)
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetWidth(150)
        row.text:SetJustifyH("LEFT")
        row.mode = UI.Button(row, 118, 20, "", function()
            local e = row.entry
            if not e then return end
            local cur = 1
            for k, v in ipairs(MODES) do if v == e.cfg.targets then cur = k end end
            e.cfg.targets = MODES[cur % #MODES + 1]
            row.mode:SetLabel(ModeLabel(e.cfg.targets))
            Changed()
        end)
        row.mode:SetPoint("RIGHT", row, "RIGHT", -30, 0)
        row.del = UI.Button(row, 20, 20, "x", function()
            local e = row.entry
            if e and e.custom then
                table.remove(db.custom, e.custom)
                Changed()
                list:Refresh()
            end
        end)
        row.del:SetPoint("LEFT", row.mode, "RIGHT", 6, 0)
        list.rows[i] = row
        return row
    end

    local addLabel, addBox, addBtn

    local function Rebuild()
        local entries = m.entries
        local n = #entries
        for i = 1, n do
            local row = list.rows[i] or NewRow(i)
            local e = entries[i]
            row.entry = e
            Info(e)
            local known = Known(e)
            row.icon:SetTexture(e.icon)
            row.icon:SetDesaturated(not known)
            row.text:SetText(e.name)
            row.text:SetTextColor(known and 0.92 or 0.5, known and 0.94 or 0.5, known and 0.97 or 0.5)
            row.mode:SetLabel(ModeLabel(e.cfg.targets))
            row.del:SetShown(e.custom ~= nil)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(i - 1) * ROW_H)
            row.on:Refresh()
            row:Show()
        end
        for i = n + 1, #list.rows do list.rows[i]:Hide() end
        local y = n * ROW_H + 8
        addLabel:ClearAllPoints()
        addLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -y)
        addBox:ClearAllPoints()
        addBox:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(y + 18))
        addBtn:ClearAllPoints()
        addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
        local h = y + 18 + 28
        list:SetHeight(h)
        form:SetTail(h)
    end

    addLabel = UI.Text(list, L("Spell ID(s), several ranks separated by comma"), 11, 0.68, 0.65, 0.58)
    addBox = UI.EditBox(list, 250, nil)
    addBox:SetMaxLetters(60)
    addBtn = UI.Button(list, 110, 20, L("Add"), function()
        if #db.custom >= MAXCUSTOM then return end
        local ids = {}
        for token in addBox:GetText():gmatch("%d+") do ids[#ids + 1] = tonumber(token) end
        if #ids == 0 then return end
        table.sort(ids, function(a, b) return a > b end)
        db.custom[#db.custom + 1] = { ids = ids, track = true, targets = "all" }
        addBox:SetText("")
        Changed()
        list:Refresh()
    end)

    list.Refresh = Rebuild
    form:PlaceTail(list)
    Rebuild()
    return list
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 16, 80, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Stepper(L("Border alpha"), db, "borderAlpha", 0, 1, 0.1)
    form:Stepper(L("Spacing"), db, "spacing", 0, 40, 1)
    form:Cycle(L("Grow direction"), db, "grow", {
        { "right", L("Right") }, { "left", L("Left") }, { "up", L("Up") } })
    form:Stepper(L("Icons per row"), db, "perRow", 1, 20, 1)
    form:Header(L("Behavior"))
    form:Check(L("Blink the red placeholder when a tracked debuff is missing"), db, "blink")
    form:Check(L("Show my other debuffs"), db, "showRow")
    form:Cycle(L("Which debuffs"), db, "filter", {
        { "mine", L("Only my debuffs") }, { "all", L("All debuffs") } })
    form:Stepper(L("Maximum icons"), db, "max", 1, MAXROW, 1)
    form:Cycle(L("Visibility"), db, "visibility", HHT.VisibilityChoices())
    form:Note(L("The game fills these icons itself. A red dimmed icon means the debuff is not on the target (missed, immune or expired). Size and border changes apply out of combat."))
    form:Header(L("Colors"))
    form:Color(L("Border color"), db.colors, "border")
    form:Header(L("Tracked debuffs"))
    form:Note(L("Ticked debuffs get a fixed slot and a red placeholder while they are missing. The button sets on which targets the placeholder shows. Debuffs that are not ticked still appear in the normal row when active."))
    BuildTrackList(self, form)
end
