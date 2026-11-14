-- Aspect and tracking buttons: secure buttons with an own key, Shift/Ctrl/Alt variants and a toggle between two spells.
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Aspect and tracking"] = "Aspekt und Aufspueren",
    ["Buttons and keybinds for aspects and tracking, with toggle and Shift, Ctrl and Alt variants."] = "Knoepfe und Tasten fuer Aspekte und Aufspueren, mit Umschalten und Shift-, Strg- und Alt-Varianten.",
    ["Aspect"] = "Aspekt",
    ["Tracking"] = "Aufspueren",
    ["Turn tracking off"] = "Aufspueren ausschalten",
    ["Key: %s"] = "Taste: %s",
    ["not set"] = "nicht gesetzt",
    ["Press a key (Esc cancels)"] = "Taste druecken (Esc bricht ab)",
    ["Clear key"] = "Taste entfernen",
    ["Main spell"] = "Hauptzauber",
    ["Toggles with"] = "Wechselt mit",
    ["Shift: spell"] = "Shift: Zauber",
    ["Shift: toggles with"] = "Shift: wechselt mit",
    ["Ctrl: spell"] = "Strg: Zauber",
    ["Ctrl: toggles with"] = "Strg: wechselt mit",
    ["Alt: spell"] = "Alt: Zauber",
    ["Alt: toggles with"] = "Alt: wechselt mit",
    ["None"] = "Keiner",
    ["Left-click or key: use"] = "Linksklick oder Taste: wirken",
    ["Right-click: choose the main spell"] = "Rechtsklick: Hauptzauber waehlen",
    ["Changes apply after combat."] = "Aenderungen gelten nach dem Kampf.",
    ["Choose the spell you press the key for. With a second spell the key switches between the two. Shift, Ctrl and Alt use their own spells on the same key."] = "Waehle den Zauber fuer die Taste. Mit einem zweiten Zauber wechselt die Taste zwischen beiden. Shift, Strg und Alt wirken eigene Zauber auf derselben Taste.",
    ["The key replaces its normal function while it is set."] = "Die Taste ersetzt ihre normale Funktion, solange sie gesetzt ist.",
})

local SLOTS = {
    { "base", "", "" },
    { "shift", "shift-", "SHIFT-" },
    { "ctrl", "ctrl-", "CTRL-" },
    { "alt", "alt-", "ALT-" },
}

local M = HHT:NewModule("aspects", {
    name = "Aspect and tracking",
    desc = "Buttons and keybinds for aspects and tracking, with toggle and Shift, Ctrl and Alt variants.",
    positions = {
        aspect = { "CENTER", "CENTER", 190, -110 },
        tracking = { "CENTER", "CENTER", 240, -110 },
    },
    defaults = {
        size = 44, shape = "round", borderSize = 2, borderAlpha = 1,
        aspect = {
            show = true, key = "",
            base = "aspectHawk", baseAlt = "aspectCheetah", shift = "aspectPack", shiftAlt = "",
            ctrl = "aspectMonkey", ctrlAlt = "", alt = "", altAlt = "",
        },
        tracking = {
            show = true, key = "",
            base = "trackBeasts", baseAlt = "trackHumanoids", shift = "trackHidden", shiftAlt = "",
            ctrl = "", ctrlAlt = "", alt = "", altAlt = "",
        },
        colors = {
            active = { 0.67, 0.83, 0.45 },
            none = { 0.95, 0.25, 0.20 },
        },
    },
})

local function Known(key)
    if not key or key == "" then return nil end
    local rs = S.Resolve("@" .. key)
    if rs.known then return rs end
end

-- Aspects are buffs, readable out of combat; the last known state is kept while they are hidden.
local function ReadAspect(list)
    for _, key in ipairs(list) do
        local rs = Known(key)
        if rs then
            local found = S.AuraByName("player", rs.name, "HELPFUL")
            if found == nil then return nil, false end
            if found then return key, true end
        end
    end
    return false, true
end

local function ReadTracking(list)
    if InCombatLockdown() then return nil, false end
    local api = C_Minimap
    if not (api and api.GetNumTrackingTypes and api.GetTrackingInfo) then return nil, false end
    local okN, n = pcall(api.GetNumTrackingTypes)
    n = okN and HHT.SafeNumber(n)
    if not n then return nil, false end
    for i = 1, n do
        local ok, info = pcall(api.GetTrackingInfo, i)
        if ok and type(info) == "table" and not HHT.IsSecret(info) and not HHT.IsSecret(info.active) and info.active == true then
            for _, key in ipairs(list) do
                local rs = Known(key)
                if rs and ((not HHT.IsSecret(info.spellID) and info.spellID == rs.id) or (not HHT.IsSecret(info.name) and info.name == rs.name)) then
                    M.trackIndex = i
                    return key, true
                end
            end
        end
    end
    M.trackIndex = nil
    return false, true
end

local function CancelTracking()
    local api = C_Minimap
    local i = M.trackIndex
    if i and api and api.SetTracking then
        pcall(api.SetTracking, i, false)
    elseif CancelTrackingBuff then
        pcall(CancelTrackingBuff)
    elseif SetTracking then
        pcall(SetTracking, 0)
    end
end

local GROUPS = {
    { key = "aspect", title = "Aspect", list = S.Aspects, read = ReadAspect, btn = "HamingwaysHunterToolsAspectButton", fallback = "aspectHawk" },
    { key = "tracking", title = "Tracking", list = S.Trackings, read = ReadTracking, btn = "HamingwaysHunterToolsTrackingButton", fallback = "trackBeasts" },
}

-- Toggle: the sequence starts with the spell that is not active, so the next press switches.
local function MacroText(gd, slot, cur)
    local a, b = Known(gd[slot]), Known(gd[slot .. "Alt"])
    if a and b and a.name ~= b.name then
        local first, second = a, b
        if cur == gd[slot] then first, second = b, a end
        return "/castsequence " .. first.name .. ", " .. second.name
    end
    local x = a or b
    return x and ("/cast " .. x.name) or ""
end

local function SlotSummary(gd, slot)
    local a, b = Known(gd[slot]), Known(gd[slot .. "Alt"])
    if a and b and a.name ~= b.name then return a.name .. " <-> " .. b.name end
    local x = a or b
    return x and x.name or nil
end

function M:OnInit()
    self.owner = CreateFrame("Frame", nil, UIParent)
    self.bindDirty = true
    for _, ev in ipairs({ "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED", "PLAYER_ENTERING_WORLD" }) do
        HHT:Listen(self, ev, "OnEvent")
    end
    HHT:Listen(self, "UNIT_SPELLCAST_SUCCEEDED", "OnCast")
    HHT:Every(self, 0.4, M.Tick)
    -- Bindings left over after switching the module off in combat are removed here.
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:SetScript("OnEvent", function() if M.bindDirty then M:ApplyBindings() end end)
end

function M:OnEvent()
    self.bindDirty = true
    self:Tick()
end

-- Auras and tracking are unreadable in combat, so a successful cast of a listed spell sets the state.
function M:OnCast(_, unit, _, spellId)
    if unit ~= "player" or HHT.IsSecret(spellId) or type(spellId) ~= "number" then return end
    local castName = S.Name(spellId)
    for _, g in ipairs(GROUPS) do
        for _, key in ipairs(g.list) do
            local rs = Known(key)
            if rs and (rs.id == spellId or (castName and rs.name == castName)) then
                if g.cur ~= key then g.cur = key; self:Tick() end
                return
            end
        end
    end
end

function M:BuildGroup(g)
    if g.frame then return end
    local f = CreateFrame("Frame", g.btn .. "Frame", UIParent)
    f:SetSize(44, 44)
    g.frame = f
    HHT:MakeMovable(f, self, g.key, L(g.title))
    g.icon = Icon.New(f)
    g.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    local holder = CreateFrame("Frame", nil, f)
    holder:SetAllPoints(f)
    holder:SetFrameLevel(g.icon.over:GetFrameLevel() + 1)
    local b = CreateFrame("Button", g.btn, holder, "SecureActionButtonTemplate")
    b:SetAllPoints(holder)
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("useOnKeyDown", false)
    b.group = g
    b:SetScript("PostClick", function(self, button)
        if button == "RightButton" then M:OpenPick(g, self) end
    end)
    b:SetScript("OnEnter", function(self) M:ShowTip(g, self) end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    g.btnFrame = b
    g.texts = {}

    -- A key press does not reliably carry the modifier state into the click, so every
    -- modifier variant gets its own hidden button that the modified key is bound to.
    g.slotBtn = {}
    for _, s in ipairs(SLOTS) do
        if s[1] ~= "base" then
            local sb = CreateFrame("Button", g.btn .. s[1], UIParent, "SecureActionButtonTemplate")
            sb:SetSize(1, 1)
            sb:RegisterForClicks("AnyUp")
            sb:SetAttribute("useOnKeyDown", false)
            sb:SetAttribute("type1", "macro")
            g.slotBtn[s[1]] = sb
        end
    end

    if g.key == "tracking" then
        local x = CreateFrame("Button", nil, f)
        x:SetSize(16, 16)
        x:SetFrameLevel(holder:GetFrameLevel() + 3)
        x:SetPoint("TOPLEFT", f, "TOPLEFT", -5, 5)
        x:RegisterForClicks("LeftButtonUp")
        x:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        x:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
        x:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up", "ADD")
        x:SetScript("OnClick", function()
            CancelTracking()
            g.cur = false
            M:Tick()
        end)
        x:SetScript("OnEnter", function(btn)
            if not GameTooltip then return end
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L("Turn tracking off"))
            GameTooltip:Show()
        end)
        x:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        x:Hide()
        g.xbtn = x
    end
end

function M:ShowTip(g, anchor)
    if not GameTooltip then return end
    local gd = self.db[g.key]
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L(g.title), 1, 1, 1)
    GameTooltip:AddLine(L("Left-click or key: use"), 0.7, 0.7, 0.7)
    for _, s in ipairs(SLOTS) do
        local text = SlotSummary(gd, s[1])
        if text then
            local label = s[1] == "base" and "" or (s[3]:sub(1, 1) .. s[3]:sub(2, -2):lower() .. ": ")
            GameTooltip:AddLine(label .. text, 0.67, 0.83, 0.45)
        end
    end
    GameTooltip:AddLine(L("Right-click: choose the main spell"), 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function M:OpenPick(g, anchor)
    local gd = self.db[g.key]
    local items = {}
    for _, key in ipairs(g.list) do
        local rs = Known(key)
        if rs then items[#items + 1] = { label = rs.name, icon = rs.icon, value = key } end
    end
    UI.ShowMenu(anchor, items, function(item)
        gd.base = item.value
        if InCombatLockdown() then HHT.Print(L("Changes apply after combat.")) end
        self.bindDirty = true
        self:Tick()
    end)
end

function M:ApplyGroup(g)
    local gd = self.db[g.key]
    local b = g.btnFrame
    for _, s in ipairs(SLOTS) do
        local text = MacroText(gd, s[1], g.cur)
        if g.texts[s[1]] ~= text then
            if (g.texts[s[1]] or "") == "" or text == "" then self.bindDirty = true end
            g.texts[s[1]] = text
            b:SetAttribute(s[2] .. "type1", "macro")
            b:SetAttribute(s[2] .. "macrotext1", text)
            if g.slotBtn[s[1]] then g.slotBtn[s[1]]:SetAttribute("macrotext1", text) end
        end
    end
    local wantMouse = (gd.show and not HHT:IsUnlocked(self)) and true or false
    if g.mouse ~= wantMouse then
        g.mouse = wantMouse
        b:EnableMouse(wantMouse)
    end
end

function M:PaintGroup(g)
    local db, gd = self.db, self.db[g.key]
    local ic = g.icon
    local sig = table.concat({ db.size, db.shape, db.borderSize, db.borderAlpha }, ",")
    if g.styleSig ~= sig then
        g.styleSig = sig
        g.frame:SetSize(db.size, db.size)
        ic:Style(db.size, db.shape, db.borderSize, db.borderAlpha, false)
    end
    ic:SetAlpha((gd.show or HHT:IsUnlocked(self)) and 1 or 0)
    if g.btnFrame:IsShown() ~= (gd.show and true or false) and not InCombatLockdown() then
        g.btnFrame:SetShown(gd.show and true or false)
    end
    local rs = Known(g.cur) or Known(gd.base) or Known(gd.baseAlt) or Known(g.fallback) or S.Resolve("@" .. g.fallback)
    ic:SetIcon(rs.icon)
    ic:SetBorderColor(HHT.Col(db, g.cur and "active" or "none"))
    ic:SetDesaturated(not g.cur)
    if g.xbtn then g.xbtn:SetShown(g.cur and gd.show and not HHT:IsUnlocked(self) and true or false) end
    local key = gd.key ~= "" and gd.key:upper() or nil
    ic:SetKey(key, 12, "TOPRIGHT", 1, 1, 0.4)
end

function M:ApplyBindings()
    if InCombatLockdown() then self.bindDirty = true; return end
    if not (self.owner and ClearOverrideBindings and SetOverrideBindingClick) then return end
    self.bindDirty = false
    ClearOverrideBindings(self.owner)
    if not self.enabled then return end
    for _, g in ipairs(GROUPS) do
        local gd = self.db[g.key]
        if gd.key ~= "" and gd.show then
            for _, s in ipairs(SLOTS) do
                if SlotSummary(gd, s[1]) then
                    local target = g.slotBtn[s[1]] and g.slotBtn[s[1]]:GetName() or g.btn
                    pcall(SetOverrideBindingClick, self.owner, true, s[3] .. gd.key, target, "LeftButton")
                end
            end
        end
    end
end

function M:Tick()
    for _, g in ipairs(GROUPS) do
        if g.frame then
            local cur, readable = g.read(g.list)
            if readable then g.cur = cur end
            if not InCombatLockdown() then self:ApplyGroup(g) end
            self:PaintGroup(g)
            HHT.FlushHidden(g.frame)
        end
    end
    if self.bindDirty and not InCombatLockdown() then self:ApplyBindings() end
end

function M:OnEnable()
    for _, g in ipairs(GROUPS) do
        self:BuildGroup(g)
        HHT.ShowSecure(g.frame)
        g.styleSig = nil
    end
    self.bindDirty = true
    self:Tick()
end

function M:OnDisable()
    for _, g in ipairs(GROUPS) do
        if g.frame then HHT.HideSecure(g.frame) end
    end
    self.bindDirty = true
    self:ApplyBindings()
end

function M:Refresh()
    for _, g in ipairs(GROUPS) do g.styleSig = nil end
    self.bindDirty = true
    for _, g in ipairs(GROUPS) do
        if g.frame then HHT:ApplyGlobalLook(g.frame) end
    end
    self:Tick()
end

function M:OnLockChanged()
    self:Tick()
end

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
local MODS = {
    LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
    LMETA = true, RMETA = true,
}

local capture
local function CaptureKey(done)
    if not capture then
        capture = CreateFrame("Frame", nil, UIParent)
        capture:SetSize(1, 1)
        capture:SetPoint("CENTER")
        capture:EnableKeyboard(true)
        capture:Hide()
        capture:SetScript("OnKeyDown", function(self, key)
            if MODS[key] then return end
            local cb = self.done
            self.done = nil
            self:Hide()
            if key ~= "ESCAPE" and cb then cb(key) end
        end)
    end
    capture.done = done
    capture:Show()
    HHT.Print(L("Press a key (Esc cancels)"))
end
HHT.CaptureKey = CaptureKey

local function PickRow(form, label, tbl, key, list, allowNone)
    local f = CreateFrame("Frame", nil, form.content)
    f:SetSize(380, 22)
    local text = UI.Text(f, label, 12)
    text:SetPoint("LEFT", f, "LEFT", 0, 0)
    local btn = UI.Button(f, 130, 20, "", function(self)
        local items = {}
        if allowNone then items[1] = { label = L("None"), value = "" } end
        for _, k in ipairs(list) do
            local rs = Known(k)
            if rs then items[#items + 1] = { label = rs.name, icon = rs.icon, value = k } end
        end
        UI.ShowMenu(self, items, function(item)
            tbl[key] = item.value
            form:Changed()
            f:Refresh()
        end)
    end)
    btn:SetPoint("LEFT", f, "LEFT", 250, 0)
    btn.label:SetWidth(122)
    btn.label:SetWordWrap(false)
    function f:Refresh()
        local rs = Known(tbl[key])
        btn:SetLabel(rs and rs.name or L("None"))
    end
    f:Refresh()
    return form:Place(f, 22, 4, 5)
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 24, 96, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Note(L("Choose the spell you press the key for. With a second spell the key switches between the two. Shift, Ctrl and Alt use their own spells on the same key."))
    form:Note(L("The key replaces its normal function while it is set."))
    for _, g in ipairs(GROUPS) do
        local gd = db[g.key]
        form:Header(L(g.title))
        local keyBtn = form:Button("", function()
            CaptureKey(function(key)
                gd.key = key
                M.bindDirty = true
                M:Tick()
                form:Refresh()
            end)
        end, 220)
        function keyBtn:Refresh()
            self:SetLabel(string.format(L("Key: %s"), gd.key ~= "" and gd.key:upper() or L("not set")))
        end
        keyBtn:Refresh()
        form:Button(L("Clear key"), function()
            gd.key = ""
            M.bindDirty = true
            M:Tick()
        end, 220)
        local names = { base = "", shift = "Shift: ", ctrl = "Ctrl: ", alt = "Alt: " }
        for _, s in ipairs(SLOTS) do
            local slot = s[1]
            local spellLabel = slot == "base" and L("Main spell") or L(names[slot] .. "spell")
            local altLabel = slot == "base" and L("Toggles with") or L(names[slot] .. "toggles with")
            PickRow(form, spellLabel, gd, slot, g.list, slot ~= "base")
            PickRow(form, altLabel, gd, slot .. "Alt", g.list, true)
        end
    end
    form:Header(L("Colors"))
    form:Color(L("Active border"), db.colors, "active")
    form:Color(L("Warning border"), db.colors, "none")
end
