-- Hamingway's HunterTools (WoW Forever). Core: namespace, saved variables, module registry, shared helpers.
local ADDON, HHT = ...
_G.HamingwaysHunterTools = HHT

local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
HHT.version = (GetMeta and GetMeta(ADDON, "Version")) or "?"
HHT.modules = {}
HHT.moduleList = {}
HHT.movables = {}

local pcall, type, pairs, ipairs, tostring, tonumber = pcall, type, pairs, ipairs, tostring, tonumber
local GetTime = GetTime

local PREFIX = "|cffabd473Hamingway's HunterTools|r: "
function HHT.Print(msg) print(PREFIX .. tostring(msg)) end

-- ---------------------------------------------------------------------------
-- Secret value safety
-- ---------------------------------------------------------------------------
function HHT.IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) == true
end
local IsSecret = HHT.IsSecret

-- Calls fn(...) and returns true/false only when the result is a readable boolean.
function HHT.SafeBool(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, r = pcall(fn, ...)
    if not ok or IsSecret(r) or r == nil then return nil end
    if r == true or r == 1 then return true end
    if r == false or r == 0 then return false end
    return nil
end

function HHT.SafeNumber(v)
    if IsSecret(v) or type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return nil end
    return v
end

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = DeepCopy(v) end
    return c
end
HHT.DeepCopy = DeepCopy

-- Fills missing keys. Arrays (tables with [1]) are treated as values and never merged.
local function Fill(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = DeepCopy(v)
        elseif type(v) == "table" and type(dst[k]) == "table" and v[1] == nil then
            Fill(dst[k], v)
        end
    end
end
HHT.Fill = Fill

function HHT.Col(tbl, key)
    local c = tbl.colors and tbl.colors[key]
    if not c then return 1, 1, 1 end
    return c[1], c[2], c[3]
end

-- ---------------------------------------------------------------------------
-- Defaults
-- ---------------------------------------------------------------------------
local GENERAL_DEFAULTS = {
    locked = true,
    outline = true,
    lang = "auto",
    minimap = true,
    minimapAngle = 215,
    versionNotice = true,
    scale = 1.0,
    alpha = 1.0,
}

-- ---------------------------------------------------------------------------
-- Modules
-- ---------------------------------------------------------------------------
-- def: name, desc, defaults, positions = { main = {point, relPoint, x, y} },
--      OnInit(m), OnEnable(m), OnDisable(m), Refresh(m), BuildOptions(m, form)
function HHT:NewModule(key, def)
    local m = { key = key, enabled = false }
    for k, v in pairs(def) do m[k] = v end
    self.modules[key] = m
    self.moduleList[#self.moduleList + 1] = key
    return m
end

function HHT:EachModule(fn)
    for _, key in ipairs(self.moduleList) do fn(self.modules[key]) end
end

function HHT:SetEnabled(m, on)
    on = (on and not m.wip) and true or false
    m.db.enabled = on
    if on and not m.enabled then
        m.enabled = true
        if m.OnEnable then m:OnEnable() end
        if m.Refresh then m:Refresh() end
    elseif not on and m.enabled then
        m.enabled = false
        if m.OnDisable then m:OnDisable() end
    end
end

function HHT:RefreshModule(m)
    if m.enabled and m.Refresh then m:Refresh() end
end

function HHT:RefreshAll()
    self:EachModule(function(m) self:RefreshModule(m) end)
end

function HHT:ResetModule(m)
    local wasOn = m.enabled
    if wasOn then self:SetEnabled(m, false) end
    local fresh = DeepCopy(m.defaults or {})
    fresh.enabled = (m.enabledByDefault ~= false)
    self.db.mods[m.key] = fresh
    m.db = fresh
    if m.OnReset then m:OnReset() end
    if wasOn then self:SetEnabled(m, true) end
    self:ApplyAllPositions()
end

-- ---------------------------------------------------------------------------
-- Events (one shared frame, modules only receive events while enabled)
-- ---------------------------------------------------------------------------
local evFrame = CreateFrame("Frame")
HHT.handlers = {}

function HHT:Listen(m, event, fn)
    local list = self.handlers[event]
    if not list then
        list = {}
        self.handlers[event] = list
        pcall(evFrame.RegisterEvent, evFrame, event)
    end
    list[#list + 1] = { m, fn }
end

evFrame:SetScript("OnEvent", function(_, event, ...)
    local list = HHT.handlers[event]
    if not list then return end
    for i = 1, #list do
        local h = list[i]
        local m, fn = h[1], h[2]
        if m.enabled then
            if type(fn) == "string" then fn = m[fn] end
            if fn then fn(m, event, ...) end
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Movable frames
-- ---------------------------------------------------------------------------
function HHT:IsUnlocked()
    return self.db and self.db.general and self.db.general.locked == false
end

function HHT:ApplyPosition(frame)
    local info = frame.hht
    if not info then return end
    local m = info.module
    local pos = m.db.pos and m.db.pos[info.key]
    if not pos then
        local d = m.positions and m.positions[info.key] or { "CENTER", "CENTER", 0, 0 }
        pos = d
    end
    frame:ClearAllPoints()
    frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

function HHT:ApplyAllPositions()
    for _, f in ipairs(self.movables) do self:ApplyPosition(f) end
end

function HHT:ApplyLock()
    local unlocked = self:IsUnlocked()
    local outline = self.db.general.outline
    for _, f in ipairs(self.movables) do
        f:EnableMouse(unlocked and true or false)
        if f.hhtOutline then f.hhtOutline:SetShown(unlocked and outline and true or false) end
        if f.hhtLabel then f.hhtLabel:SetShown(unlocked and outline and true or false) end
    end
    self:EachModule(function(m)
        if m.enabled and m.OnLockChanged then m:OnLockChanged(unlocked) end
    end)
    self:ApplyAllLooks()
end

function HHT:SetLocked(locked)
    self.db.general.locked = locked and true or false
    self:ApplyLock()
    self.Print(locked and self.L("Frames locked.") or self.L("Frames are unlocked. Drag them with the left mouse button."))
end

function HHT:ApplyGlobalLook(frame)
    local g = self.db.general
    local info = frame.hht
    local ms = info and info.module.db.scale or 1
    local ma = info and info.module.db.alpha or 1
    local hidden = info and info.module.db.onlyCombat and not self:IsUnlocked() and not self.InCombat()
    frame:SetScale((g.scale or 1) * ms)
    frame:SetAlpha(hidden and 0 or (g.alpha or 1) * ma)
end

function HHT:ApplyAllLooks()
    for _, f in ipairs(self.movables) do self:ApplyGlobalLook(f) end
end

-- Registers frame as draggable. label = shown while unlocked.
function HHT:MakeMovable(frame, m, key, label)
    frame.hht = { module = m, key = key or "main", label = label }
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if HHT:IsUnlocked() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint(1)
        m.db.pos = m.db.pos or {}
        m.db.pos[self.hht.key] = { p, rp, math.floor(x + 0.5), math.floor(y + 0.5) }
    end)

    local o = CreateFrame("Frame", nil, frame)
    o:SetAllPoints(frame)
    o:SetFrameLevel(frame:GetFrameLevel() + 20)
    self.UI.Border(o, 0.67, 0.83, 0.45, 0.9)
    o:Hide()
    frame.hhtOutline = o
    local fs = self.UI.Text(o, label or m.name or "", 10, 0.67, 0.83, 0.45)
    fs:SetPoint("BOTTOM", o, "TOP", 0, 2)
    frame.hhtLabel = fs
    fs:Hide()

    self.movables[#self.movables + 1] = frame
    self:ApplyPosition(frame)
    self:ApplyGlobalLook(frame)
    frame:EnableMouse(self:IsUnlocked() and true or false)
    o:SetShown(self:IsUnlocked() and self.db.general.outline and true or false)
    fs:SetShown(self:IsUnlocked() and self.db.general.outline and true or false)
end

-- ---------------------------------------------------------------------------
-- Visibility rules shared by modules
-- ---------------------------------------------------------------------------
function HHT.HasAttackableTarget()
    if not UnitExists("target") then return false end
    if UnitIsDead("target") then return false end
    local ok, r = pcall(UnitCanAttack, "player", "target")
    return ok and r == true
end

function HHT.InCombat()
    return UnitAffectingCombat("player") and true or false
end

-- Frames with secure buttons cannot be hidden in combat: fade them and finish with FlushHidden afterwards.
function HHT.HideSecure(f)
    if InCombatLockdown() then f:SetAlpha(0); f.hhtFaded = true else f:Hide() end
end

function HHT.ShowSecure(f)
    f:SetAlpha(1)
    f.hhtFaded = nil
    f:Show()
end

function HHT.FlushHidden(f)
    if f and f.hhtFaded and not InCombatLockdown() then
        f:Hide()
        f:SetAlpha(1)
        f.hhtFaded = nil
    end
end

function HHT:ShouldShow(mode)
    if self:IsUnlocked() then return true end
    if mode == "always" then return true end
    if mode == "combat" then return self.InCombat() end
    if mode == "target" then return self.HasAttackableTarget() end
    if mode == "combattarget" then return self.InCombat() or self.HasAttackableTarget() end
    return true
end

function HHT.VisibilityChoices()
    local L = HHT.L
    return {
        { "always", L("Always") },
        { "combat", L("In combat") },
        { "target", L("With target") },
        { "combattarget", L("Combat or target") },
    }
end

function HHT.ShapeChoices()
    local L = HHT.L
    return { { "square", L("Square") }, { "round", L("Round") } }
end

-- Small ticker so modules can poll cheaply without owning a frame.
function HHT:Every(m, interval, fn)
    local f = CreateFrame("Frame")
    local acc = 0
    f:SetScript("OnUpdate", function(_, dt)
        if not m.enabled then return end
        acc = acc + dt
        if acc >= interval then
            local el = acc
            acc = 0
            fn(m, el)
        end
    end)
    return f
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function HHT:InitDB()
    HamingwaysHunterToolsDB = HamingwaysHunterToolsDB or {}
    local db = HamingwaysHunterToolsDB
    db.general = db.general or {}
    Fill(db.general, GENERAL_DEFAULTS)
    db.mods = db.mods or {}
    self.db = db
    self:EachModule(function(m)
        local d = db.mods[m.key]
        if not d then d = {}; db.mods[m.key] = d end
        local defaults = DeepCopy(m.defaults or {})
        if defaults.enabled == nil then defaults.enabled = (m.enabledByDefault ~= false) end
        if defaults.scale == nil then defaults.scale = 1.0 end
        if defaults.alpha == nil then defaults.alpha = 1.0 end
        if defaults.onlyCombat == nil then defaults.onlyCombat = false end
        Fill(d, defaults)
        if m.wip then d.enabled = false end
        m.db = d
    end)
end

function HHT:Start()
    self:EachModule(function(m)
        if m.OnInit then m:OnInit() end
    end)
    self:EachModule(function(m)
        m.enabled = false
        if m.db.enabled then self:SetEnabled(m, true) end
    end)
    if self.Config and self.Config.Init then self.Config:Init() end
    for _, ev in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_ENTERING_WORLD" }) do
        local f = self.combatFrame or CreateFrame("Frame")
        self.combatFrame = f
        f:RegisterEvent(ev)
        f:SetScript("OnEvent", function() HHT:ApplyAllLooks() end)
    end
    self:ApplyAllLooks()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON then return end
        local _, class = UnitClass("player")
        HHT.isHunter = (class == "HUNTER")
        if HHT.isHunter then HHT:InitDB() end
    elseif event == "PLAYER_LOGIN" then
        if not HHT.isHunter then
            HHT.db = nil
            HHT.Print(HHT.L("Hunter only. Addon is inactive on this character."))
            return
        end
        HHT:Start()
        boot:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
SLASH_HAMINGWAYSHUNTERTOOLS1 = "/hht"
SLASH_HAMINGWAYSHUNTERTOOLS2 = "/hamingway"

-- /hht test <name>: shows a feature without having to go somewhere.
local TESTS = {
    { "rare", "rare beast alert", function() local m = HHT.modules.petwatch; return m and m.enabled and m:Test() end },
    { "arrow", "direction arrow to a rare", function() return HHT.PetWatch and HHT.PetWatch.TestArrow() end },
    { "nearby", "pet ability alert", function() local m = HHT.modules.petnearby; return m and m.enabled and m:Test() end },
    { "train", "pet training hint", function() local m = HHT.modules.pettrain; return m and m.enabled and m:Test() end },
    { "minimap", "minimap pins around you", function() return HHT.PetMap and HHT.PetMap:TestMinimap() end },
}

function HHT.RunTest(what)
    for _, t in ipairs(TESTS) do
        if t[1] == what then
            if not t[3]() then HHT.Print("test " .. what .. ": module is off or not ready.") end
            return
        end
    end
    local names = {}
    for _, t in ipairs(TESTS) do names[#names + 1] = t[1] .. " (" .. t[2] .. ")" end
    HHT.Print("/hht test: " .. table.concat(names, ", "))
end

SlashCmdList["HAMINGWAYSHUNTERTOOLS"] = function(msg)
    if not HHT.db then return end
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    local testWhat = msg:match("^test%s*(.*)$")
    local petSearch = msg:match("^pets%s*(.*)$")
    if petSearch then
        if HHT.PetDex then HHT.PetDex:Toggle(petSearch ~= "" and petSearch or nil) end
    elseif testWhat then
        HHT.RunTest(testWhat)
    elseif msg == "petmap" then
        if HHT.PetMap then HHT.PetMap:Debug() end
    elseif msg == "ammo" then
        if HHT.AmmoVendors then HHT.AmmoVendors.Show() end
    elseif msg == "ammo go" then
        if HHT.AmmoVendors then HHT.AmmoVendors.Nearest() end
    elseif msg == "stable" then
        if HHT.StableMasters then HHT.StableMasters.Show() end
    elseif msg == "stable go" then
        if HHT.StableMasters then HHT.StableMasters.Nearest() end
    elseif msg == "watch" then
        if HHT.PetWatch then HHT.PetWatch.Debug() end
    elseif msg == "debuffs" then
        if HHT.Debuffs then HHT.Debuffs:Debug() end
    elseif msg == "nearby" then
        if HHT.modules.petnearby then HHT.modules.petnearby:Why() end
    elseif msg == "train" then
        if HHT.modules.pettrain and HHT.modules.pettrain.enabled then HHT.modules.pettrain:Recheck() end
    elseif msg == "procs" then
        if HHT.Procs then HHT.Procs:Debug() end
    elseif msg == "totems" then
        if HHT.Summons then HHT.Summons:Debug() end
    elseif msg == "auras" then
        if HHT.Procs then HHT.Procs:ListAuras() end
    elseif msg == "auras pet" then
        if HHT.Procs then HHT.Procs:ListAuras(false, "pet") end
    elseif msg == "auras watch" then
        if HHT.Procs then
            HHT.Procs.watch = not HHT.Procs.watch
            HHT.Print("auras watch: " .. (HHT.Procs.watch and "on, short buffs are listed when combat ends" or "off"))
        end
    elseif msg == "proctex" then
        if HHT.Procs then HHT.Procs:TexPreview() end
    elseif msg == "petinfo" then
        if HHT.PetDex and HHT.PetDex.Inspect then HHT.PetDex.Inspect() end
    elseif msg == "lock" then
        HHT:SetLocked(true)
    elseif msg == "unlock" then
        HHT:SetLocked(false)
    elseif msg == "debug" then
        local S = HHT.Spells
        HHT.Print("aurasSecret=" .. tostring(S.AurasSecret()) .. " combat=" .. tostring(HHT.InCombat()))
        local keys = {}
        for _, k in ipairs(S.Aspects) do keys[#keys + 1] = k end
        keys[#keys + 1] = "trueshotAura"; keys[#keys + 1] = "hunterMark"; keys[#keys + 1] = "callPet"
        for _, k in ipairs(keys) do
            local rs = S.Resolve("@" .. k)
            local found = rs.known and S.AuraByName("player", rs.name, "HELPFUL")
            HHT.Print(string.format("%s known=%s id=%s name=%s aura=%s", k, tostring(rs.known), tostring(rs.id), tostring(rs.name), tostring(found)))
        end
        local pm = HHT.modules.pet
        if pm and pm.ReadHappiness then
            local okC, c1 = false, nil
            if C_PetInfo and C_PetInfo.GetPetHappiness then okC, c1 = pcall(C_PetInfo.GetPetHappiness) end
            local g1, g2 = nil, nil
            if GetPetHappiness then g1, g2 = GetPetHappiness() end
            HHT.Print("happiness: C_PetInfo=" .. tostring(c1) .. " global=" .. tostring(g1) .. "/" .. tostring(g2) .. " used=" .. tostring(pm.ReadHappiness()))
        end
        local fm = HHT.modules.feeder
        if fm and fm.Debug then fm:Debug() end
        local w = HHT.modules.warnings
        if w and w.Collect then
            local keys2 = {}
            for _, e in ipairs(w:Collect()) do keys2[#keys2 + 1] = e.key end
            HHT.Print("warnings: quiet=" .. tostring(w.Quiet()) .. " enabled=" .. tostring(w.enabled) .. " list=" .. table.concat(keys2, ","))
        end
    elseif msg == "reset" then
        for _, m in pairs(HHT.modules) do m.db.pos = nil end
        HHT:ApplyAllPositions()
        HHT.Print(HHT.L("Positions reset."))
    else
        if HHT.Config then HHT.Config:Toggle() end
    end
end
