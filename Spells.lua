-- Spell catalog and secret-safe spell helpers.
local ADDON, HHT = ...

local IsSecret, SafeBool = HHT.IsSecret, HHT.SafeBool
local pcall, type, tonumber, tostring, ipairs, pairs = pcall, type, tonumber, tostring, ipairs, pairs
local GetTime = GetTime

local S = {}
HHT.Spells = S

S.FALLBACK_ICON = 134400

-- "@key" resolves to the highest known id in the list (highest rank first). Unknown ranks fall back to a name lookup.
S.Catalog = {
    autoShot      = { en = "Auto Shot",          ids = { 75 } },
    rapidFire     = { en = "Rapid Fire",         ids = { 3045 } },
    feignDeath    = { en = "Feign Death",        ids = { 5384 } },
    freezingTrap  = { en = "Freezing Trap",      ids = { 14311, 14310, 1499 } },
    frostTrap     = { en = "Frost Trap",         ids = { 13809 } },
    immolationTrap= { en = "Immolation Trap",    ids = { 14305, 14304, 14303, 14302, 13795 } },
    explosiveTrap = { en = "Explosive Trap",     ids = { 14317, 14316, 13813 } },
    scatterShot   = { en = "Scatter Shot",       ids = { 19503 } },
    concussive    = { en = "Concussive Shot",    ids = { 5116 } },
    deterrence    = { en = "Deterrence",         ids = { 19263 } },
    intimidation  = { en = "Intimidation",       ids = { 19577 } },
    bestialWrath  = { en = "Bestial Wrath",      ids = { 19574 } },
    readiness     = { en = "Readiness",          ids = { 23989 } },
    tranq         = { en = "Tranquilizing Shot", ids = { 19801 } },
    disengage     = { en = "Disengage",          ids = { 14273, 14272, 781 } },
    distracting   = { en = "Distracting Shot",   ids = { 20736 } },
    wyvern        = { en = "Wyvern Sting",       ids = { 19386 } },
    counterattack = { en = "Counterattack",      ids = { 20910, 20909, 19306 } },
    flare         = { en = "Flare",              ids = { 1543 } },
    wingClip      = { en = "Wing Clip",          ids = { 2974 } },
    raptorStrike  = { en = "Raptor Strike",      ids = { 2973 } },
    mongoose      = { en = "Mongoose Bite",      ids = { 1495 } },
    beastLore     = { en = "Beast Lore",         ids = { 1462 } },
    tameBeast     = { en = "Tame Beast",         ids = { 1515 } },
    trackBeasts   = { en = "Track Beasts",       ids = { 1494 } },
    trackHumanoids = { en = "Track Humanoids",   ids = { 19883 } },
    trackHidden   = { en = "Track Hidden",       ids = { 19885 } },
    growl         = { en = "Growl",              ids = { 2649 } },
    mendPet       = { en = "Mend Pet",           ids = { 136 } },
    callPet       = { en = "Call Pet",           ids = { 883 } },
    dismissPet    = { en = "Dismiss Pet",        ids = { 2641 } },
    revivePet     = { en = "Revive Pet",         ids = { 982 } },
    feedPet       = { en = "Feed Pet",           ids = { 6991 } },
    hunterMark    = { en = "Hunter's Mark",      ids = { 14325, 14324, 14323, 1130 } },
    serpentSting  = { en = "Serpent Sting",      ids = { 27016, 25295, 13555, 13554, 13553, 13552, 13551, 13550, 13549, 1978 } },
    trueshotAura  = { en = "Trueshot Aura",      ids = { 20906, 20905, 19506 } },
    aspectHawk    = { en = "Aspect of the Hawk", ids = { 25296, 14322, 14321, 14320, 14319, 14318, 13165 } },
    aspectMonkey  = { en = "Aspect of the Monkey", ids = { 13163 } },
    aspectCheetah = { en = "Aspect of the Cheetah", ids = { 5118 } },
    aspectPack    = { en = "Aspect of the Pack", ids = { 13159 } },
    aspectWild    = { en = "Aspect of the Wild", ids = { 20190, 20043 } },
    aspectBeast   = { en = "Aspect of the Beast", ids = { 13161 } },
    aspectViper   = { en = "Aspect of the Viper", ids = { 34074 } },
    aspectDragonhawk = { en = "Aspect of the Dragonhawk", ids = { 61847, 61846 } },
}

S.Aspects = { "aspectHawk", "aspectMonkey", "aspectCheetah", "aspectPack", "aspectWild", "aspectBeast", "aspectViper", "aspectDragonhawk" }

-- ---------------------------------------------------------------------------
-- Safe wrappers
-- ---------------------------------------------------------------------------
local function InfoTable(x)
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, r = pcall(C_Spell.GetSpellInfo, x)
        if ok and type(r) == "table" and not IsSecret(r) and r.name then return r end
    end
    if GetSpellInfo then
        local ok, name, _, icon, _, _, _, id = pcall(GetSpellInfo, x)
        if ok and type(name) == "string" and not IsSecret(name) then
            return { name = name, iconID = icon, spellID = id }
        end
    end
end
S.Info = InfoTable

function S.Name(id)
    local info = InfoTable(id)
    return info and info.name
end

function S.Texture(id)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, t = pcall(C_Spell.GetSpellTexture, id)
        if ok and t and not IsSecret(t) then return t end
    end
    local info = InfoTable(id)
    return info and info.iconID
end

function S.IsKnown(id)
    if IsPlayerSpell then
        local ok, r = pcall(IsPlayerSpell, id)
        if ok and r then return true end
    end
    if IsSpellKnown then
        local ok, r = pcall(IsSpellKnown, id)
        if ok and r then return true end
    end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, r = pcall(C_SpellBook.IsSpellKnown, id)
        if ok and r then return true end
    end
    return false
end
local IsKnown = S.IsKnown

-- ---------------------------------------------------------------------------
-- Resolve "@catalogKey" / spell id / spell name
-- ---------------------------------------------------------------------------
local cache, stamp = {}, 0

function S.Invalidate()
    stamp = stamp + 1
end

function S.Resolve(spec)
    spec = tostring(spec or "")
    local c = cache[spec]
    if c and c.stamp == stamp and (c.known or GetTime() - c.at < 2) then return c end
    c = { stamp = stamp, at = GetTime(), spec = spec, known = false, name = spec, icon = S.FALLBACK_ICON }
    local key = spec:match("^@(.+)$")
    if key then
        local def = S.Catalog[key]
        if def then
            for _, id in ipairs(def.ids) do
                if IsKnown(id) then c.id = id; break end
            end
            local base = def.ids[#def.ids]
            if not c.id then
                -- name lookup finds the highest known rank on clients that hide lower ranks
                local nm = S.Name(base)
                local info = nm and InfoTable(nm)
                if info and info.spellID and IsKnown(info.spellID) then c.id = info.spellID end
            end
            c.known = c.id ~= nil
            local ref = c.id or base
            c.name = S.Name(ref) or def.en
            c.icon = S.Texture(ref) or S.FALLBACK_ICON
        end
    elseif tonumber(spec) then
        local id = tonumber(spec)
        if IsKnown(id) then c.id = id; c.known = true end
        c.name = S.Name(id) or spec
        c.icon = S.Texture(id) or S.FALLBACK_ICON
    elseif spec ~= "" then
        local info = InfoTable(spec)
        if info and info.spellID then
            c.known = IsKnown(info.spellID) or true
            c.id = info.spellID
            c.name = info.name
            c.icon = info.iconID or S.FALLBACK_ICON
        end
    end
    cache[spec] = c
    return c
end

function S.CatalogName(key)
    local def = S.Catalog[key]
    if not def then return key end
    local rs = S.Resolve("@" .. key)
    return rs.name or def.en
end

-- Known player spells for the picker.
function S.ListSpellbook()
    local out, seen = {}, {}
    local SB = C_SpellBook
    if SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemInfo then
        local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
        local spellType = (Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell) or 1
        local okN, n = pcall(SB.GetNumSpellBookSkillLines)
        if okN and type(n) == "number" then
            for i = 1, n do
                local ok, line = pcall(SB.GetSpellBookSkillLineInfo, i)
                if ok and type(line) == "table" and line.itemIndexOffset and line.numSpellBookItems then
                    for j = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
                        local ok2, info = pcall(SB.GetSpellBookItemInfo, j, bank)
                        if ok2 and type(info) == "table" and info.name and not IsSecret(info.name)
                            and info.itemType == spellType and not info.isPassive and not info.isOffSpec
                            and not seen[info.name] then
                            seen[info.name] = true
                            out[#out + 1] = { label = info.name, icon = info.iconID, value = info.name }
                        end
                    end
                end
            end
        end
    end
    if #out == 0 then
        for key in pairs(S.Catalog) do
            local rs = S.Resolve("@" .. key)
            if rs.known and not seen[rs.name] then
                seen[rs.name] = true
                out[#out + 1] = { label = rs.name, icon = rs.icon, value = rs.name }
            end
        end
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end

-- ---------------------------------------------------------------------------
-- Cooldowns (secret safe)
-- ---------------------------------------------------------------------------
local shadowCD = {}
local function Shadow(id)
    local cd = shadowCD[id]
    if cd then return cd end
    cd = CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate")
    cd:SetSize(2, 2)
    cd:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -400, 400)
    pcall(cd.SetDrawSwipe, cd, false)
    pcall(cd.SetDrawEdge, cd, false)
    pcall(cd.SetDrawBling, cd, false)
    pcall(cd.SetHideCountdownNumbers, cd, true)
    cd:SetAlpha(0)
    cd:SetCooldown(0, 0)
    shadowCD[id] = cd
    return cd
end

function S.CooldownDuration(spellId)
    if not (C_Spell and C_Spell.GetSpellCooldownDuration) then return nil end
    local ok, d = pcall(C_Spell.GetSpellCooldownDuration, spellId)
    if ok then return d end
    return nil
end

-- Returns onCooldown (true/false/nil) and the DurationObject when a real cooldown (not the GCD) runs.
function S.CooldownState(spellId)
    if not (C_Spell and C_Spell.GetSpellCooldownDuration) then return nil end
    local cd = Shadow(spellId)
    local info
    if C_Spell.GetSpellCooldown then
        local ok, r = pcall(C_Spell.GetSpellCooldown, spellId)
        if ok and type(r) == "table" then info = r end
    end
    if info and not IsSecret(info.isOnGCD) and info.isOnGCD == true then
        cd:SetCooldown(0, 0)
        return false
    end
    local dur = S.CooldownDuration(spellId)
    if not dur then
        cd:SetCooldown(0, 0)
        return false
    end
    if info then
        local ok, real = pcall(function() return info.duration > 1.6 end)
        if ok and real == false then
            cd:SetCooldown(0, 0)
            return false
        end
    end
    cd:Clear()
    if not pcall(cd.SetCooldownFromDurationObject, cd, dur, true) then return nil end
    if cd:IsShown() then return true, dur end
    return false
end

-- ---------------------------------------------------------------------------
-- Auras (readable only when not secret)
-- ---------------------------------------------------------------------------
function S.AurasSecret()
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local ok, r = pcall(C_Secrets.ShouldAurasBeSecret)
        if ok and r == true then return true end
    end
    return false
end

-- Returns found(bool|nil), remaining seconds (nil when permanent/unknown). nil = could not read.
function S.AuraByName(unit, name, filter)
    if not name or S.AurasSecret() then return nil end
    local data, apiOk
    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local ok, r = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, name, filter)
        if ok then data, apiOk = r, true end
    end
    if not apiOk and AuraUtil and AuraUtil.FindAuraByName then
        local ok, n, _, _, _, _, exp = pcall(AuraUtil.FindAuraByName, name, unit, filter)
        if ok then
            apiOk = true
            if n then data = { expirationTime = exp } end
        end
    end
    if not apiOk then return nil end
    if data == nil then return false, nil end
    if type(data) ~= "table" or IsSecret(data) then return nil end
    local exp = data.expirationTime
    if IsSecret(exp) or type(exp) ~= "number" or exp == 0 then return true, nil end
    return true, exp - GetTime()
end

-- ---------------------------------------------------------------------------
-- Range probe for a single spell
-- ---------------------------------------------------------------------------
function S.InRange(id, unit)
    if not C_Spell then return nil end
    unit = unit or "target"
    local r = SafeBool(C_Spell.IsSpellInRange, id, unit)
    if r ~= nil then return r end
    local ok, info = pcall(C_Spell.GetSpellInfo, id)
    if ok and type(info) == "table" and not IsSecret(info) and type(info.name) == "string" and not IsSecret(info.name) then
        return SafeBool(C_Spell.IsSpellInRange, info.name, unit)
    end
    return nil
end

local f = CreateFrame("Frame")
for _, ev in ipairs({ "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_LOGIN", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED" }) do
    pcall(f.RegisterEvent, f, ev)
end
f:SetScript("OnEvent", function() S.Invalidate() end)
