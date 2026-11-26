-- Pet stance button: a secure button with an own key, Shift/Ctrl/Alt variants and a toggle between two stances, also in combat.
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Pet stance"] = "Begleiter-Haltung",
    ["One button and key that switches your pet between its stances, with toggle and Shift, Ctrl and Alt variants, also in combat."] = "Ein Knopf und eine Taste, die deinen Begleiter zwischen seinen Haltungen wechseln, mit Umschalten und Shift-, Strg- und Alt-Varianten, auch im Kampf.",
    ["Show the stance under the icon"] = "Haltung unter dem Symbol zeigen",
    ["Stance key: %s"] = "Haltungs-Taste: %s",
    ["not set"] = "nicht gesetzt",
    ["Clear stance key"] = "Haltungs-Taste entfernen",
    ["Aggressive"] = "Aggressiv",
    ["Assist"] = "Assistieren",
    ["Defensive"] = "Defensiv",
    ["Passive"] = "Passiv",
    ["No pet"] = "Kein Begleiter",
    ["Border: Aggressive"] = "Rand: Aggressiv",
    ["Border: Assist"] = "Rand: Assistieren",
    ["Border: Defensive"] = "Rand: Defensiv",
    ["Border: Passive"] = "Rand: Passiv",
    ["Reset stance colors"] = "Haltungsfarben zurücksetzen",
    ["None"] = "Keiner",
    ["Main stance"] = "Haupthaltung",
    ["Toggles with"] = "Wechselt mit",
    ["Shift: stance"] = "Shift: Haltung",
    ["Shift: toggles with"] = "Shift: wechselt mit",
    ["Ctrl: stance"] = "Strg: Haltung",
    ["Ctrl: toggles with"] = "Strg: wechselt mit",
    ["Alt: stance"] = "Alt: Haltung",
    ["Alt: toggles with"] = "Alt: wechselt mit",
    ["Left-click or key: switch stance"] = "Linksklick oder Taste: Haltung wechseln",
    ["Right-click: choose the main stance"] = "Rechtsklick: Haupthaltung wählen",
    ["Changes apply after combat."] = "Änderungen gelten nach dem Kampf.",
    ["Choose the stance you press the key for. With a second stance the key switches between the two. Shift, Ctrl and Alt use their own stances on the same key."] = "Wähle die Haltung für die Taste. Mit einer zweiten Haltung wechselt die Taste zwischen beiden. Shift, Strg und Alt setzen eigene Haltungen auf derselben Taste.",
    ["The key replaces its normal function while it is set."] = "Die Taste ersetzt ihre normale Funktion, solange sie gesetzt ist.",
    ["Enter a slot from 1 to 180."] = "Gib einen Slot von 1 bis 180 ein.",
    ["Slot %d is already in use."] = "Slot %d ist schon belegt.",
    ["automatic"] = "automatisch",
    ["free"] = "frei",
    ["in use"] = "belegt",
    ["placed"] = "gesetzt",
    ["%s: action slot"] = "%s: Aktionsslot",
    ["Stances that are not on the pet bar are placed on an empty action slot, which keeps the button working in combat. Leave empty for automatic (slots 120 downwards). A slot in use is never replaced."] = "Haltungen, die nicht auf der Begleiter-Leiste liegen, werden auf einen leeren Aktionsslot gelegt, damit der Knopf auch im Kampf geht. Leer lassen für automatisch (Slots ab 120 abwärts). Ein belegter Slot wird nie ersetzt.",
    ["Stances not on the pet bar are placed on an unused action slot (115-120) once, out of combat, so the button also works in combat."] = "Haltungen, die nicht auf der Begleiter-Leiste liegen, werden einmalig außerhalb des Kampfes auf einen unbenutzten Aktionsslot (115-120) gelegt, damit der Knopf auch im Kampf geht.",
})

local SLOTS = {
    { "base", "" },
    { "shift", "SHIFT-" },
    { "ctrl", "CTRL-" },
    { "alt", "ALT-" },
}

local M = HHT:NewModule("petstance", {
    name = "Pet stance",
    desc = "One button and key that switches your pet between its stances, with toggle and Shift, Ctrl and Alt variants, also in combat.",
    positions = { main = { "CENTER", "CENTER", 290, -110 } },
    defaults = {
        size = 44, shape = "round", borderSize = 2, borderAlpha = 1,
        showText = true, key = "", hidden = {},
        showKeys = true, keySize = 14, keyPos = "TOPRIGHT",
        slots = {
            base = "aggressive", baseAlt = "passive", shift = "defensive", shiftAlt = "",
            ctrl = "assist", ctrlAlt = "", alt = "", altAlt = "",
        },
        colors = { border = { 0.67, 0.83, 0.45 }, key = { 1, 1, 0.4 }, stance = {} },
    },
})

-- Hidden without a pet. The driver works in combat too, where the frame cannot be hidden by code.
local DRIVER = "[nopet] hide; show"

local STANCES = {
    { key = "aggressive", token = "PET_MODE_AGGRESSIVE", cmd = "/petaggressive", label = "Aggressive", icon = "Interface\\Icons\\Ability_Racial_BloodRage" },
    { key = "assist", token = "PET_MODE_ASSIST", cmd = "/petassist", label = "Assist", icon = "Interface\\Icons\\Ability_Hunter_Pet_Assist" },
    { key = "defensive", token = "PET_MODE_DEFENSIVE", cmd = "/petdefensive", label = "Defensive", icon = "Interface\\Icons\\Ability_Defend" },
    { key = "passive", token = "PET_MODE_PASSIVE", cmd = "/petpassive", label = "Passive", icon = "Interface\\Icons\\Ability_Seal" },
}
local BY_KEY, BY_TOKEN, BY_NAME = {}, {}, {}
for _, s in ipairs(STANCES) do
    BY_KEY[s.key] = s; BY_TOKEN[s.token] = s
    if type(_G[s.token]) == "string" then BY_NAME[_G[s.token]] = s end
end
-- This client names the defensive stance on the pet bar PET_MODE_DEFENSIVEASSIST.
BY_TOKEN.PET_MODE_DEFENSIVEASSIST = BY_KEY.defensive
if type(_G.PET_MODE_DEFENSIVEASSIST) == "string" then BY_NAME[_G.PET_MODE_DEFENSIVEASSIST] = BY_KEY.defensive end

-- Runs in the secure environment, so the toggle also works in combat. Every button holds the targets of its
-- slot ("a<slot>"/"b<slot>" is an id, "ta"/"na" and "tb"/"nb" the action type and number); the last id used is
-- kept on the main button ("cur"), so all keys share it. The click then runs that action directly, no macro.
-- The main button gets the action of every slot under its own modifier prefix ("shift-type1" ...), so the
-- game picks by the held modifier; the hidden key buttons have a fixed slot.
local CLICK = [[
    if button ~= "LeftButton" then return end
    local fixed = self:GetAttribute("slot")
    local st = self:GetFrameRef("main") or self
    local cur = st:GetAttribute("cur")
    local names, pres = newtable("base", "shift", "ctrl", "alt"), newtable("", "shift-", "ctrl-", "alt-")
    local chosen = "base"
    if IsShiftKeyDown() then chosen = "shift" elseif IsControlKeyDown() then chosen = "ctrl" elseif IsAltKeyDown() then chosen = "alt" end
    local newCur
    for i = 1, fixed and 1 or 4 do
        local slot = fixed or names[i]
        local pre = fixed and "" or pres[i]
        local a = self:GetAttribute("a" .. slot)
        if (not a or a == "") and not fixed then
            slot = "base"
            a = self:GetAttribute("a" .. slot)
        end
        local t, n
        if a and a ~= "" then
            local b = self:GetAttribute("b" .. slot)
            local p = "a"
            if b and b ~= "" and cur == a then p = "b" end
            t, n = self:GetAttribute("t" .. p .. slot), self:GetAttribute("n" .. p .. slot)
            if fixed or names[i] == chosen then newCur = self:GetAttribute(p .. slot) end
        end
        self:SetAttribute(pre .. "type1", t)
        self:SetAttribute(pre .. "action1", n)
    end
    if newCur then st:SetAttribute("cur", newCur) end
    self:SetAttribute("chosen", fixed or chosen)
]]

local function StanceName(s)
    local g = _G[s.token]
    return type(g) == "string" and g or L(s.label)
end

-- All four stances are always offered; the pet bar is only read for the active one and the icons.
local function Known(key)
    return key and key ~= "" and BY_KEY[key] or nil
end

-- /petaggressive and /petdefensive do nothing in this client (a game bug), so no stance uses a slash command.
-- A stance is triggered through its pet bar button ("pet" action) or, when it is not on the pet bar,
-- through an action slot holding it (see EnsureActions). Both work in combat.
-- What an action slot holds, to notice when something else was put on a slot we placed a stance on.
local function ActionSig(slot)
    local kind, id = GetActionInfo(slot)
    return tostring(kind) .. ":" .. tostring(id) .. ":" .. tostring(GetActionTexture(slot))
end

local function Owned(key, slot)
    if not (slot and HasAction(slot)) then return false end
    local want = M.db and M.db.sig and M.db.sig[key]
    if not want then return true end
    local ok, now = pcall(ActionSig, slot)
    return not ok or now == want
end

local function Target(s)
    local slot = M.db and M.db.hidden and M.db.hidden[s.key]
    if Owned(s.key, slot) then return "action", slot end
    slot = M.slotOf and M.slotOf[s.key]
    if slot then return "pet", slot end
end

-- Identifies what a click on the stance does; "" when the stance cannot be triggered yet.
local function CmdOf(s)
    local t, n = Target(s)
    return t and (t .. ":" .. n) or ""
end

-- The key bound to the stance's pet bar button.
local function BarKey(s)
    local slot = M.slotOf and M.slotOf[s.key]
    local k = slot and GetBindingKey("BONUSACTIONBUTTON" .. slot)
    if not k then return nil end
    return GetBindingText and GetBindingText(k, "KEY_") or k
end

-- Returns the stances found on the pet bar (key -> icon), the active one and the bar slot of each; nil when the bar cannot be read.
local function ReadBar()
    local found, active, any, slots = {}, nil, false, {}
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local ok, name, tex, isToken, isActive = pcall(GetPetActionInfo, slot)
        if not ok or HHT.IsSecret(name) or HHT.IsSecret(isToken) or HHT.IsSecret(isActive) then return nil end
        local s = type(name) == "string" and (BY_TOKEN[name] or BY_NAME[name])
        if s then
            any = true
            slots[s.key] = slot
            if type(tex) == "string" and type(_G[tex]) == "string" then tex = _G[tex] end
            found[s.key] = type(tex) == "string" and tex or s.icon
            if isActive then active = s.key end
        end
    end
    return found, active, slots, any
end

local function Summary(slot)
    local gd = M.db.slots
    local a, b = Known(gd[slot]), Known(gd[slot .. "Alt"])
    if a and b and a ~= b then return StanceName(a) .. " <-> " .. StanceName(b) end
    local x = a or b
    return x and StanceName(x) or nil
end

function M:OnInit()
    self.owner = CreateFrame("Frame")
    self.bindDirty = true
    self.tex = {}
    for _, ev in ipairs({ "PET_BAR_UPDATE", "UNIT_PET", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }) do
        HHT:Listen(self, ev, "OnEvent")
    end
    HHT:Every(self, 0.4, M.Tick)
end

function M:OnEvent()
    self:Tick()
end

function M:ApplyBinding()
    if InCombatLockdown() then self.bindDirty = true; return end
    self.bindDirty = false
    ClearOverrideBindings(self.owner)
    local db = self.db
    if not (self.enabled and db.key ~= "") then return end
    for _, s in ipairs(SLOTS) do
        if Summary(s[1]) then
            local target = self.slotBtn[s[1]] and self.slotBtn[s[1]]:GetName() or "HamingwaysHunterToolsPetStanceButton"
            HHT.BindClick(self.owner, db.key, target, s[2])
        end
    end
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsPetStance", UIParent)
    f:SetSize(44, 44)
    self.frame = f
    f.icon = Icon.New(f)
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    local function Secure(name, parent)
        local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
        b:RegisterForClicks("AnyUp")
        b:SetAttribute("useOnKeyDown", false)
        SecureHandlerWrapScript(b, "OnClick", b, CLICK)
        b:SetScript("PostClick", function(_, button)
            if M.trace then
                HHT.Print(string.format("click %s %s%s%s chosen=%q type=%q shift-type=%q ctrl-type=%q cur=%q", tostring(button),
                    IsShiftKeyDown() and "S" or "-", IsControlKeyDown() and "C" or "-", IsAltKeyDown() and "A" or "-",
                    tostring(b:GetAttribute("chosen")), tostring(b:GetAttribute("type1")), tostring(b:GetAttribute("shift-type1")),
                    tostring(b:GetAttribute("ctrl-type1")), tostring(M.button and M.button:GetAttribute("cur"))))
            end
            if button == "RightButton" then M:OpenPick(b) else M:AfterClick() end
        end)
        return b
    end

    local b = Secure("HamingwaysHunterToolsPetStanceButton", f)
    b:SetAllPoints(f.icon)
    b:SetScript("OnEnter", function(self) M:ShowTip(self) end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.button = b

    -- A key press does not reliably carry the modifier state into the click, so every
    -- modifier variant gets its own hidden button that the modified key is bound to.
    self.slotBtn = {}
    for _, s in ipairs(SLOTS) do
        if s[1] ~= "base" then
            local sb = Secure("HamingwaysHunterToolsPetStance" .. s[1], UIParent)
            sb:SetSize(1, 1)
            sb:SetAttribute("slot", s[1])
            sb:SetFrameRef("main", b)
            self.slotBtn[s[1]] = sb
        end
    end

    HHT:MakeMovable(f, self, "main", L("Pet stance"))
    self:Layout()
end

function M:ShowTip(anchor)
    if not GameTooltip then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L("Pet stance"), 1, 1, 1)
    GameTooltip:AddLine(L("Left-click or key: switch stance"), 0.7, 0.7, 0.7)
    for _, s in ipairs(SLOTS) do
        local text = Summary(s[1])
        if text then
            local label = s[1] == "base" and "" or (s[2]:sub(1, 1) .. s[2]:sub(2, -2):lower() .. ": ")
            GameTooltip:AddLine(label .. text, 0.67, 0.83, 0.45)
        end
    end
    GameTooltip:AddLine(L("Right-click: choose the main stance"), 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function M:OpenPick(anchor)
    local items = {}
    for _, s in ipairs(STANCES) do
        if Known(s.key) then items[#items + 1] = { label = StanceName(s), icon = self.tex[s.key] or s.icon, value = s.key } end
    end
    UI.ShowMenu(anchor, items, function(item)
        self.db.slots.base = item.value
        if InCombatLockdown() then HHT.Print(L("Changes apply after combat.")) end
        self.attrSig = nil
        self.bindDirty = true
        self:Tick()
    end)
end

-- The pet spellbook lists the stances as pet actions without a spell ID, so /cast cannot reach them.
local function FindBook(s)
    local api = C_SpellBook
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    if not (api and api.GetSpellBookItemInfo and bank) then return end
    local want = StanceName(s):lower()
    for i = 1, 120 do
        local ok, info = pcall(api.GetSpellBookItemInfo, i, bank)
        if ok and type(info) == "table" and type(info.name) == "string" and not HHT.IsSecret(info.name)
            and (info.name:lower() == want or BY_NAME[info.name] == s or info.name:lower() == s.label:lower()) then
            return i, bank, info
        end
    end
end

-- Active stance and icons of the stances held on the hidden action slots.
function M:ReadHidden()
    local active, seen
    for _, s in ipairs(STANCES) do
        local key = s.key
        local slot = self.db.hidden and self.db.hidden[key]
        if Owned(key, slot) then
            seen = true
            local ok, cur = pcall(IsCurrentAction, slot)
            if ok and cur == true then active = key end
            local tex = GetActionTexture(slot)
            if type(tex) == "string" or type(tex) == "number" then self.tex[key] = tex end
        end
    end
    return active, seen
end

-- Unused action slots for the hidden buttons: 115-120 belong to a class page hunters do not have, so no bar shows them.
local HIDDEN = { 120, 119, 118, 117, 116, 115 }

-- A slot among the hidden ones that already holds the stance (placed earlier, but no longer remembered) is taken over instead of
-- placing it again on another slot.
local function AdoptSlot(db, key, info)
    local want = {}
    if info and info.iconID then want[tostring(info.iconID)] = true end
    if M.tex[key] then want[tostring(M.tex[key])] = true end
    local used = {}
    for _, n in pairs(db.hidden) do used[n] = true end
    for _, c in ipairs(HIDDEN) do
        if not used[c] and HasAction(c) and want[tostring(GetActionTexture(c))] then return c end
    end
end

-- Puts the stances on free action slots, once and out of combat, so the button can use them in combat.
-- Only stances that are not on the pet bar are placed, only on empty slots (a slot chosen in the
-- settings is never replaced), and only the placed slot is remembered. A slot that now holds something
-- else is left alone and the stance is placed again elsewhere.
function M:EnsureActions()
    if InCombatLockdown() or GetTime() < (self.ensureAt or 0) then return end
    self.ensureAt = GetTime() + 10
    local db = self.db
    db.hidden, db.pref, db.sig = db.hidden or {}, db.pref or {}, db.sig or {}
    local api = C_SpellBook
    for _, s in ipairs(STANCES) do
        local key = s.key
        local slot = db.hidden[key]
        if slot and not Owned(key, slot) then
            db.hidden[key], db.sig[key] = nil, nil
            slot = nil
        end
        if slot then
            if not db.sig[key] then
                local ok, now = pcall(ActionSig, slot)
                if ok then db.sig[key] = now end
            end
        else
            local onBar = self.slotOf and self.slotOf[key]
            local i, bank, info = FindBook(s)
            local found = self.pet and not onBar and i and AdoptSlot(db, key, info)
            if found then
                db.hidden[key] = found
                local ok, now = pcall(ActionSig, found)
                db.sig[key] = ok and now or nil
            elseif self.pet and not onBar and i and api.PickupSpellBookItem and GetCursorInfo() == nil then
                local free
                for _, c in ipairs(db.pref[key] and { db.pref[key] } or HIDDEN) do
                    if not HasAction(c) then free = c; break end
                end
                if free then
                    pcall(api.PickupSpellBookItem, i, bank)
                    if GetCursorInfo() ~= nil and not HasAction(free) then pcall(PlaceAction, free) end
                    ClearCursor()
                    if HasAction(free) then
                        db.hidden[key] = free
                        local ok, now = pcall(ActionSig, free)
                        db.sig[key] = ok and now or nil
                    end
                end
            end
        end
    end
end

-- Moves a stance to a slot typed in the settings. Returns false and a reason when the slot is not free.
function M:SetStanceSlot(key, n)
    local db = self.db
    db.hidden, db.pref = db.hidden or {}, db.pref or {}
    if n == nil or n == "" then
        db.pref[key] = nil
        return true
    end
    if type(n) ~= "number" or n ~= math.floor(n) or n < 1 or n > 180 then return false, L("Enter a slot from 1 to 180.") end
    if db.hidden[key] == n then return true end
    if InCombatLockdown() then return false, L("Changes apply after combat.") end
    if HasAction(n) then return false, string.format(L("Slot %d is already in use."), n) end
    local old = db.hidden[key]
    if old and Owned(key, old) and GetCursorInfo() == nil then
        pcall(PickupAction, old)
        ClearCursor()
    end
    db.sig = db.sig or {}
    db.hidden[key], db.pref[key], db.sig[key] = nil, n, nil
    self.ensureAt = 0
    self.attrSig = nil
    return true
end

-- The click already ran the stance through the secure snippet; show it until the pet bar confirms it.
function M:AfterClick()
    local cur = self.button:GetAttribute("cur") or ""
    local s
    if cur ~= "" then
        for _, x in ipairs(STANCES) do if CmdOf(x) == cur then s = x; break end end
    end
    if not s then return end
    self.cur = s.key
    self.holdUntil = GetTime() + 0.6
    self:Tick()
end

function M:ApplyDriver()
    local f = self.frame
    if not f then return end
    if InCombatLockdown() then self.driverDirty = true; return end
    self.driverDirty = false
    if HHT:IsUnlocked(self) or not self.enabled then
        if self.driverOn then UnregisterStateDriver(f, "visibility"); self.driverOn = false end
        if self.enabled then f:Show() end
    elseif not self.driverOn then
        RegisterStateDriver(f, "visibility", DRIVER)
        self.driverOn = true
    end
end

function M:OnEnable()
    self:Build()
    self.attrSig = nil
    self.bindDirty = true
    self:ApplyDriver()
    self.sig = nil
    self:Tick()
end

function M:OnDisable()
    self.bindDirty = true
    self:ApplyBinding()
    local f = self.frame
    if not f then return end
    if InCombatLockdown() then
        HHT.HideSecure(f)
        self.driverDirty = true
        return
    end
    if self.driverOn then UnregisterStateDriver(f, "visibility"); self.driverOn = false end
    f:Hide()
end

function M:Refresh()
    self:Layout()
    self:ApplyDriver()
    self.sig = nil
    self.attrSig = nil
    self.bindDirty = true
    self:Tick()
end

function M:OnLockChanged()
    self.mouse = nil
    self:ApplyDriver()
    self:Tick()
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self.db
    -- The frame holds a secure button, so it can only be resized out of combat; Tick repeats it after the fight.
    if InCombatLockdown() then self.layoutDirty = true; return end
    self.layoutDirty = false
    f:SetSize(db.size, db.size)
    f.icon:Style(db.size, db.shape, db.borderSize, db.borderAlpha, true)
    f.icon.label:SetWidth(db.size + 40)
    HHT:ApplyGlobalLook(f)
end

-- Puts the commands of every slot on the buttons; only possible out of combat.
function M:ApplyAttributes()
    local gd = self.db.slots
    local sig, data = {}, {}
    for _, s in ipairs(SLOTS) do
        local a, b = Known(gd[s[1]]), Known(gd[s[1] .. "Alt"])
        if not a then a, b = b, nil end
        if a and a == b then b = nil end
        local d = {}
        for i, st in ipairs({ a or false, b or false }) do
            local t, n
            if st then t, n = Target(st) end
            d[i] = { t and (t .. ":" .. n) or "", t or "", n or "" }
        end
        data[s[1]] = d
        sig[#sig + 1] = d[1][1] .. "," .. d[2][1]
    end
    local key = table.concat(sig, "|")
    if key == self.attrSig then return end
    self.attrSig = key
    local list = { self.button }
    for _, s in ipairs(SLOTS) do list[#list + 1] = self.slotBtn[s[1]] end
    for _, b in ipairs(list) do
        for slot, d in pairs(data) do
            for i, p in ipairs({ "a", "b" }) do
                b:SetAttribute(p .. slot, d[i][1])
                b:SetAttribute("t" .. p .. slot, d[i][2])
                b:SetAttribute("n" .. p .. slot, d[i][3])
            end
        end
    end
    self.bindDirty = true
end

function M:Tick()
    local f = self.frame
    if not f then return end
    HHT.FlushHidden(f)
    local db, ic = self.db, f.icon

    self.pet = HHT.SafeBool(UnitExists, "pet") == true
    local bar, active, slots, any = ReadBar()
    if bar then
        self.slotOf = slots
        for _, s in ipairs(STANCES) do
            self.tex[s.key] = bar[s.key] or self.tex[s.key]
        end
    end
    -- Stances that do not sit on the pet bar are read from their hidden action slots.
    local hiddenActive, hiddenSeen = self:ReadHidden()
    active = active or hiddenActive
    if self.pet and ((bar and any) or hiddenSeen) then
        if not self.holdUntil or GetTime() >= self.holdUntil then self.cur = active end
    elseif not self.pet then
        self.cur = nil
    end

    local gd = db.slots
    local shown = BY_KEY[self.cur or ""] or Known(gd.base) or Known(gd.baseAlt)
    if not shown then
        for _, s in ipairs(STANCES) do if Known(s.key) then shown = s; break end end
    end
    shown = shown or BY_KEY.aggressive
    local cols = db.colors.stance
    local c = cols and cols[shown.key] or db.colors.border
    local kr, kg, kb = HHT.Col(db, "key")
    local keyText = db.key ~= "" and db.key:upper() or (db.showKeys and BarKey(shown)) or ""
    local sig = table.concat({ shown.key, tostring(self.cur), tostring(self.pet), tostring(db.showText), tostring(self.tex[shown.key]), c[1], c[2], c[3], keyText, db.keySize, db.keyPos, kr, kg, kb }, ",")
    if sig ~= self.sig then
        self.sig = sig
        ic:SetIcon(self.tex[shown.key] or shown.icon)
        ic:SetDesaturated(not self.pet or self.cur == nil)
        ic:SetBorderColor(c[1], c[2], c[3])
        ic:SetKey(keyText ~= "" and keyText or nil, db.keySize, db.keyPos, kr, kg, kb)
        ic.label:SetText(db.showText and (self.pet and (self.cur and StanceName(shown) or "") or L("No pet")) or "")
    end

    if InCombatLockdown() then return end
    if self.layoutDirty then self:Layout() end
    if self.driverDirty then self:ApplyDriver() end
    self:EnsureActions()
    self:ApplyAttributes()
    -- The toggle continues from the real stance, not from the last click.
    if not self.holdUntil or GetTime() >= self.holdUntil then
        local s = BY_KEY[self.cur or ""]
        local cmd = s and CmdOf(s) or ""
        if self.button:GetAttribute("cur") ~= cmd then self.button:SetAttribute("cur", cmd) end
    end
    local mouse = not HHT:IsUnlocked(self)
    if self.mouse ~= mouse then
        self.mouse = mouse
        self.button:EnableMouse(mouse)
    end
    if self.bindDirty then self:ApplyBinding() end
end

-- /hht stance: lists the pet bar slots as the game reports them.
function M:Debug()
    HHT.Print(string.format("stance: pet=%s cur=%s hold=%s key=%q", tostring(self.pet), tostring(self.cur), tostring(self.holdUntil), self.db.key))
    for _, s in ipairs(SLOTS) do
        HHT.Print(string.format("  %s: a=%q b=%q", s[1], tostring(self.button:GetAttribute("a" .. s[1])), tostring(self.button:GetAttribute("b" .. s[1]))))
    end
    HHT.Print(string.format("  cur attr=%q", tostring(self.button:GetAttribute("cur"))))
    HHT.Print(string.format("  button: shown=%s mouse=%s w=%.0f type1=%q action1=%q clickKeyDown=%s", tostring(self.button:IsShown()), tostring(self.button:IsMouseEnabled()),
        self.button:GetWidth() or 0, tostring(self.button:GetAttribute("type1")), tostring(self.button:GetAttribute("action1")), tostring(GetCVar and GetCVar("ActionButtonUseKeyDown"))))
    if not (HHT.Report and HHT.Report.capturing) then
        self.trace = not self.trace
        HHT.Print("  click trace " .. (self.trace and "ON" or "OFF"))
    end
    for _, s in ipairs(STANCES) do
        local key = s.key
        local slot = self.db.hidden and self.db.hidden[key]
        local kind, id = nil, nil
        if slot then kind, id = GetActionInfo(slot) end
        HHT.Print(string.format("  %s: slot=%s kind=%s id=%s current=%s target=%s", key, tostring(slot), tostring(kind), tostring(id), tostring(slot and IsCurrentAction(slot)), CmdOf(s)))
    end
    for _, s in ipairs(STANCES) do
        local i, _, info = FindBook(s)
        HHT.Print(string.format("  place %s: onBar=%s book=%s icon=%s cursor=%s ensureIn=%.0fs", s.key, tostring(self.slotOf and self.slotOf[s.key]), tostring(i), tostring(info and info.iconID), tostring((GetCursorInfo())), math.max((self.ensureAt or 0) - GetTime(), 0)))
    end
    for _, c in ipairs(HIDDEN) do
        local kind, id = GetActionInfo(c)
        HHT.Print(string.format("  action slot %d: has=%s kind=%s id=%s tex=%s", c, tostring(HasAction(c)), tostring(kind), tostring(id), tostring(GetActionTexture(c))))
    end
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local ok, name, tex, isToken, isActive = pcall(GetPetActionInfo, slot)
        if not ok then
            HHT.Print(string.format("  %d: error", slot))
        elseif HHT.IsSecret(name) then
            HHT.Print(string.format("  %d: secret", slot))
        else
            local s = type(name) == "string" and (BY_TOKEN[name] or BY_NAME[name])
            HHT.Print(string.format("  %d: name=%s token=%s active=%s -> %s", slot, tostring(name), tostring(isToken), tostring(isActive), s and s.key or "-"))
        end
    end
    local api = C_SpellBook
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    HHT.Print(string.format("book api=%s bank=%s hasPetSpells=%s cast=%s", tostring(api and api.GetSpellBookItemInfo ~= nil), tostring(bank), tostring((pcall(HasPetSpells)) and select(2, pcall(HasPetSpells))), tostring(api and api.CastSpellBookItem ~= nil)))
    if api and api.GetSpellBookItemInfo and bank then
        local shownN = 0
        for i = 1, 120 do
            local ok, info = pcall(api.GetSpellBookItemInfo, i, bank)
            if ok and type(info) == "table" and info.name then
                shownN = shownN + 1
                HHT.Print(string.format("  book %d: %s type=%s spellID=%s actionID=%s sub=%s", i, tostring(info.name), tostring(info.itemType), tostring(info.spellID), tostring(info.actionID), tostring(info.subName)))
            end
        end
        if shownN == 0 then HHT.Print("  pet bank: no items") end
    end
end

local function PickRow(form, label, tbl, key, allowNone)
    local f = CreateFrame("Frame", nil, form.content)
    f:SetSize(380, 22)
    local text = UI.Text(f, label, 12)
    text:SetPoint("LEFT", f, "LEFT", 0, 0)
    local btn = UI.Button(f, 130, 20, "", function(self)
        local items = {}
        if allowNone then items[1] = { label = L("None"), value = "" } end
        for _, s in ipairs(STANCES) do
            items[#items + 1] = { label = StanceName(s), icon = M.tex[s.key] or s.icon, value = s.key }
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
        local s = BY_KEY[tbl[key] or ""]
        btn:SetLabel(s and StanceName(s) or L("None"))
    end
    f:Refresh()
    return form:Place(f, 22, 4, 5)
end

-- Action slot of a stance that is not on the pet bar; empty means automatic. Checks that the slot is free.
local function SlotRow(form, key, label)
    local db = M.db
    local f = CreateFrame("Frame", nil, form.content)
    f:SetSize(380, 22)
    local text = UI.Text(f, label, 12)
    text:SetPoint("LEFT", f, "LEFT", 0, 0)
    local status = UI.Text(f, "", 11)
    local function Live(t)
        local n = tonumber(t)
        if t == "" then status:SetText(L("automatic")); status:SetTextColor(0.68, 0.65, 0.58)
        elseif n and n >= 1 and n <= 180 and n == math.floor(n) and (n == db.hidden[key] or not HasAction(n)) then
            status:SetText(L("free")); status:SetTextColor(0.67, 0.83, 0.45)
        else
            status:SetText(L("in use")); status:SetTextColor(0.9, 0.35, 0.3)
        end
    end
    local e = UI.EditBox(f, 56, Live)
    e:SetPoint("LEFT", f, "LEFT", 250, 0)
    e:SetMaxLetters(3)
    status:SetPoint("LEFT", e, "RIGHT", 8, 0)
    e:HookScript("OnEditFocusLost", function(self)
        local t = self:GetText()
        local ok, reason = M:SetStanceSlot(key, t == "" and "" or tonumber(t))
        if not ok and reason then HHT.Print(reason) end
        f:Refresh()
    end)
    function f:Refresh()
        db.hidden, db.pref = db.hidden or {}, db.pref or {}
        local n = db.hidden[key] or db.pref[key]
        e:SetTextSafe(n and tostring(n) or "")
        Live(n and tostring(n) or "")
        if db.hidden[key] then status:SetText(L("placed")); status:SetTextColor(0.67, 0.83, 0.45) end
    end
    f:Refresh()
    return form:Place(f, 22, 4, 5)
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 24, 128, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Stepper(L("Border alpha"), db, "borderAlpha", 0, 1, 0.1)
    form:Check(L("Show the stance under the icon"), db, "showText")
    form:Note(L("Choose the stance you press the key for. With a second stance the key switches between the two. Shift, Ctrl and Alt use their own stances on the same key."))
    form:Group("stance key notes")
    form:Note(L("The key replaces its normal function while it is set."))
    form:Group("stance key notes")
    form:Note(L("Stances not on the pet bar are placed on an unused action slot (115-120) once, out of combat, so the button also works in combat."))
    form:Group("stance key notes")
    form:Header(L("Pet stance"))
    local keyBtn = form:Button("", function()
        if HHT.CaptureKey then
            HHT.CaptureKey(function(key)
                db.key = key
                self.bindDirty = true
                self.sig = nil
                form:Refresh()
            end)
        end
    end, 220)
    form:Name("stance: set key")
    function keyBtn:Refresh()
        self:SetLabel(string.format(L("Stance key: %s"), db.key ~= "" and db.key:upper() or L("not set")))
    end
    keyBtn:Refresh()
    form:Button(L("Clear stance key"), function()
        db.key = ""
        self.bindDirty = true
        self.sig = nil
        keyBtn:Refresh()
    end, 220)
    form:Name("stance: clear key")
    local names = { base = "", shift = "Shift: ", ctrl = "Ctrl: ", alt = "Alt: " }
    for _, s in ipairs(SLOTS) do
        local slot = s[1]
        local stanceLabel = slot == "base" and L("Main stance") or L(names[slot] .. "stance")
        local altLabel = slot == "base" and L("Toggles with") or L(names[slot] .. "toggles with")
        PickRow(form, stanceLabel, db.slots, slot, slot ~= "base")
        form:Group(slot == "base" and "stance: main spell" or "stance: more spells")
        PickRow(form, altLabel, db.slots, slot .. "Alt", true)
        form:Group("stance: more spells")
    end
    for _, s in ipairs(STANCES) do
        SlotRow(form, s.key, string.format(L("%s: action slot"), StanceName(s)))
        form:Group("stance: slots")
    end
    form:Note(L("Stances that are not on the pet bar are placed on an empty action slot, which keeps the button working in combat. Leave empty for automatic (slots 120 downwards). A slot in use is never replaced."))
    form:Group("stance: slots")
    form:Header(L("Colors"))
    form:Color(L("Border"), db.colors, "border")
    -- A stance without an own colour follows the border colour above.
    db.colors.stance = db.colors.stance or {}
    local swatches = {}
    for _, s in ipairs(STANCES) do
        local label = L("Border: " .. s.label)
        local sw = UI.Color(form.content, label,
            function()
                local t = db.colors.stance[s.key] or db.colors.border
                return t[1], t[2], t[3]
            end,
            function(r, g, b)
                db.colors.stance[s.key] = { r, g, b }
                self.sig = nil
                form:Changed()
            end)
        form:Place(sw, 22, 4, 8)
        form:Tag(label)
        swatches[#swatches + 1] = sw
    end
    form:Button(L("Reset stance colors"), function()
        db.colors.stance = {}
        self.sig = nil
        for _, sw in ipairs(swatches) do sw:Refresh() end
    end, 220)
    form:Name("Reset stance colors")
    HHT.Keys.AddOptions(form, db)
end
