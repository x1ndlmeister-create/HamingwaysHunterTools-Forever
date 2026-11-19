-- Easy tame: an icon for a tameable beast in range while no pet is out. First click lays a Freezing Trap, the next one tames.
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Easy tame"] = "Einfach zähmen",
    ["Icon for a tameable beast in range while no pet is out: click to lay a Freezing Trap, click again to tame."] = "Symbol für ein zähmbares Tier in Reichweite, solange kein Begleiter da ist: Klick legt eine Eisfalle, erneuter Klick zähmt.",
    ["Lay a Freezing Trap before taming"] = "Vor dem Zähmen eine Eisfalle legen",
    ["Show the step under the icon"] = "Schritt unter dem Symbol zeigen",
    ["Trap"] = "Falle",
    ["Tame"] = "Zähmen",
    ["Click: %s"] = "Klick: %s",
    ["Tame key: %s"] = "Zähm-Taste: %s",
    ["not set"] = "nicht gesetzt",
    ["Clear tame key"] = "Zähm-Taste entfernen",
    ["Without a key your own keys for Freezing Trap and Tame Beast keep working, the icon follows them. A set key replaces its normal function and applies after combat."] = "Ohne Taste funktionieren deine eigenen Tasten für Eisfalle und Wildtier zähmen weiter, das Symbol folgt ihnen. Eine gesetzte Taste ersetzt ihre normale Funktion und gilt nach dem Kampf.",
})

local M = HHT:NewModule("easytame", {
    name = "Easy tame",
    desc = "Icon for a tameable beast in range while no pet is out: click to lay a Freezing Trap, click again to tame.",
    enabledByDefault = true,
    positions = { main = { "CENTER", "CENTER", -200, 110 } },
    defaults = {
        size = 44, shape = "round", borderSize = 2, borderAlpha = 1,
        useTrap = true, showText = true, key = "",
        showKeys = true, keySize = 14, keyPos = "TOPRIGHT",
        colors = { border = { 0.67, 0.83, 0.45 }, key = { 1, 1, 0.4 } },
    },
})

-- Visible while there is no pet and a living enemy is targeted. Whether the beast can be tamed and is in range
-- only changes the icon alpha, because the frame itself cannot be shown or hidden in combat.
local DRIVER = "[nopet,harm,exists,nodead] show; hide"

local function NpcId(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or type(guid) ~= "string" or HHT.IsSecret(guid) then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind ~= "Creature" then return nil end
    return tonumber(id)
end

-- true / false, nil when the target cannot be read (keeps the last answer).
local function ReadTameable()
    if not HHT.HasAttackableTarget() then return false end
    local okF, fam = pcall(UnitCreatureFamily, "target")
    if not okF or HHT.IsSecret(fam) then return nil end
    local pd = HHT.PetDex
    local id = NpcId("target")
    local known = id and pd and pd.byId and pd.byId[id]
    if not known and (type(fam) ~= "string" or fam == "") then return false end
    if HHT.SafeBool(UnitPlayerControlled, "target") == true then return false end
    local lvl, mine = HHT.SafeNumber(UnitLevel("target")), HHT.SafeNumber(UnitLevel("player"))
    if lvl and (lvl < 1 or (mine and lvl > mine)) then return false end
    if not known then
        local okC, class = pcall(UnitClassification, "target")
        if okC and not HHT.IsSecret(class) and (class == "elite" or class == "worldboss") then return false end
    end
    return true
end

function M:OnInit()
    self.stage = 1
    self.owner = CreateFrame("Frame")
    self.bindDirty = true
    HHT:Listen(self, "PLAYER_TARGET_CHANGED", "OnTarget")
    HHT:Listen(self, "UNIT_SPELLCAST_SUCCEEDED", "OnCast")
    HHT:Listen(self, "UNIT_SPELLCAST_START", "OnCast")
    HHT:Listen(self, "UNIT_SPELLCAST_CHANNEL_START", "OnCast")
    HHT:Listen(self, "SPELLS_CHANGED", function(m) m.macro = nil end)
    HHT:Listen(self, "PLAYER_REGEN_ENABLED", function(m)
        if m.driverDirty then m:ApplyDriver() end
        m:Tick()
    end)
    HHT:Every(self, 0.2, M.Tick)
end

function M:ApplyBinding()
    if InCombatLockdown() then self.bindDirty = true; return end
    self.bindDirty = false
    ClearOverrideBindings(self.owner)
    if self.enabled and self.db.key ~= "" then
        HHT.BindClick(self.owner, self.db.key, "HamingwaysHunterToolsEasyTameButton")
    end
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsEasyTame", UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(200)
    f:SetSize(44, 44)
    self.frame = f
    f.icon = Icon.New(f)
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    local b = CreateFrame("Button", "HamingwaysHunterToolsEasyTameButton", f, "SecureActionButtonTemplate")
    b:SetAllPoints(f.icon)
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("useOnKeyDown", false)
    b:SetAttribute("type1", "macro")
    b:SetAttribute("macrotext1", "")
    b:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        local rs = M.shown
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L("Easy tame"), 1, 1, 1)
        if rs then GameTooltip:AddLine(string.format(L("Click: %s"), rs.name), 0.7, 0.7, 0.7) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.button = b

    f:Hide()
    HHT:MakeMovable(f, self, "main", L("Easy tame"))
    self:Layout()
end

function M:OnEnable()
    self:Build()
    self.macro = nil
    self.bindDirty = true
    self:ApplyDriver()
    self:Refresh()
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
    self:Tick()
end

function M:OnLockChanged()
    self:ApplyDriver()
    if self.button and not InCombatLockdown() then self.button:EnableMouse(not HHT:IsUnlocked(self)) end
    self.sig = nil
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self.db
    local c = db.colors.border
    f.icon:Style(db.size, db.shape, db.borderSize, db.borderAlpha, true)
    f.icon:SetBorderColor(c[1], c[2], c[3])
    f.icon.label:SetWidth(db.size + 40)
    if not InCombatLockdown() then f:SetSize(db.size, db.size) end
    HHT:ApplyGlobalLook(f)
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

function M:OnTarget()
    -- In combat the sequence behind the click cannot be reset, so the shown step stays in step with it.
    if not InCombatLockdown() then self.stage = 1 end
    self.tameable, self.inRange = nil, nil
    self:Tick()
end

-- A laid Freezing Trap moves to step 2. Every started Tame Beast (finished or interrupted) moves back to step 1,
-- which is also where the click sequence is after it.
function M:OnCast(event, unit, _, spellId)
    if unit ~= "player" or HHT.IsSecret(spellId) or type(spellId) ~= "number" then return end
    local tame, trap = S.Resolve("@tameBeast"), S.Resolve("@freezingTrap")
    local name = S.Name(spellId)
    local function Is(r) return r.known and (spellId == r.id or (name and name == r.name)) end
    if event == "UNIT_SPELLCAST_SUCCEEDED" and Is(trap) then
        self.stage = 2
    elseif Is(tame) then
        self.stage = 1
    else
        return
    end
    self:Tick()
end

-- Out of combat the click is a plain cast of the current step. In combat the text cannot change, so a sequence
-- starting at the current step takes over; its pointer moves with every cast, like the shown step does.
function M:MacroText()
    local tame, trap = S.Resolve("@tameBeast"), S.Resolve("@freezingTrap")
    if not tame.known then return "" end
    if not (self.db.useTrap and trap.known) then return "/cast " .. tame.name end
    local first, second = trap, tame
    if self.stage == 2 then first, second = tame, trap end
    return "/cast [nocombat] " .. first.name .. "\n/castsequence [combat] reset=combat " .. first.name .. ", " .. second.name
end

-- A pet that is out, one dismissed but still in the active stable slot, or a full set of 3 pets: taming is not possible.
local MAX_PETS = 3
local function HasPet()
    if HHT.SafeBool(UnitExists, "pet") == true then return true end
    local pd = HHT.PetDex
    if not pd then return false end
    if pd.ActiveSlotName and pd.ActiveSlotName() ~= nil then return true end
    return pd.PetCount and pd.PetCount() >= MAX_PETS or false
end

function M:Tick()
    local f = self.frame
    if not f then return end
    HHT.FlushHidden(f)
    local db, ic = self.db, f.icon
    local unlocked = HHT:IsUnlocked(self)
    -- With a pet there is nothing to show; skip all the spell and target reads.
    if not unlocked and HasPet() then
        if not self.idle then
            self.idle = true
            ic:SetAlpha(0)
            ic:ClearCooldown()
            self.sig = nil
        end
        if not InCombatLockdown() then
            if self.mouse then self.mouse = false; self.button:EnableMouse(false) end
            if self.bindDirty then self:ApplyBinding() end
            if self.driverDirty then self:ApplyDriver() end
        end
        return
    end
    self.idle = nil
    local tame, trap = S.Resolve("@tameBeast"), S.Resolve("@freezingTrap")
    local useTrap = db.useTrap and trap.known
    local rs = (useTrap and self.stage ~= 2) and trap or tame
    self.shown = rs
    local onCd, cdObj = false, nil
    if rs == trap and not unlocked then
        local c, d = S.CooldownState(trap.id)
        onCd, cdObj = c == true, d
    end

    local want
    if unlocked then
        want = true
    else
        local t = ReadTameable()
        if t ~= nil then self.tameable = t end
        local r = tame.known and S.InRange(tame.id, "target")
        if r ~= nil then self.inRange = r end
        want = tame.known and self.tameable == true and self.inRange ~= false
    end

    -- Own key if one is set here, otherwise the key of the action bar button holding the current step's spell.
    local keyText = db.key ~= "" and db.key:upper() or (db.showKeys and HHT.Keys.Get(rs.name)) or ""
    local sig = table.concat({ rs.icon or 0, tostring(db.showText), tostring(self.stage), tostring(useTrap), tostring(onCd), keyText }, ",")
    if sig ~= self.sig then
        self.sig = sig
        ic:SetIcon(rs.icon)
        ic:SetDesaturated(onCd)
        ic:SetKey(keyText ~= "" and keyText or nil, db.keySize, db.keyPos, HHT.Col(db, "key"))
        local c = db.colors.border
        ic:SetBorderColor(c[1], c[2], c[3])
        ic.label:SetText(db.showText and (rs == tame and L("Tame") or L("Trap")) or "")
    end
    ic:SetAlpha(want and 1 or 0)
    if onCd and cdObj then ic:ShowCooldown(cdObj) else ic:ClearCooldown() end

    if InCombatLockdown() then return end
    local b = self.button
    if b then
        local mouse = want and not unlocked
        if self.mouse ~= mouse then
            self.mouse = mouse
            b:EnableMouse(mouse)
        end
        local text = self:MacroText()
        if text ~= self.macro then
            self.macro = text
            b:SetAttribute("macrotext1", text)
        end
    end
    if self.bindDirty then self:ApplyBinding() end
    if self.driverDirty then self:ApplyDriver() end
end

function M:Debug()
    local tame, trap = S.Resolve("@tameBeast"), S.Resolve("@freezingTrap")
    local db = self.db
    HHT.Print(string.format("easytame: stage=%s tameable=%s inRange=%s showKeys=%s ownKey=%q",
        tostring(self.stage), tostring(self.tameable), tostring(self.inRange), tostring(db.showKeys), db.key))
    for _, rs in ipairs({ trap, tame }) do
        HHT.Print(string.format("  %s known=%s id=%s barKey=%s", tostring(rs.name), tostring(rs.known), tostring(rs.id), tostring(HHT.Keys.Get(rs.name))))
    end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 24, 128, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Stepper(L("Border alpha"), db, "borderAlpha", 0, 1, 0.1)
    form:Check(L("Show the step under the icon"), db, "showText")
    form:Header(L("Easy tame"))
    form:Check(L("Lay a Freezing Trap before taming"), db, "useTrap")
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
    form:Name("Set tame key")
    function keyBtn:Refresh()
        self:SetLabel(string.format(L("Tame key: %s"), db.key ~= "" and db.key:upper() or L("not set")))
    end
    keyBtn:Refresh()
    form:Button(L("Clear tame key"), function()
        db.key = ""
        self.bindDirty = true
        self.sig = nil
        keyBtn:Refresh()
    end, 220)
    form:Note(L("Without a key your own keys for Freezing Trap and Tame Beast keep working, the icon follows them. A set key replaces its normal function and applies after combat."))
    form:Header(L("Colors"))
    form:Color(L("Border"), db.colors, "border")
    HHT.Keys.AddOptions(form, db)
end
