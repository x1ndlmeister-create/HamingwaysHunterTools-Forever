-- Range detector for hunters (probes validated on WoW Forever):
-- Wing Clip = melee, Auto Shot = ranged, 28 yd interact distance = "still near" -> dead zone.
local ADDON, HHT = ...

local S = HHT.Spells
local SafeBool = HHT.SafeBool
local GetTime = GetTime

local Range = {}
HHT.Range = Range

local WING_CLIP_IDS = { 2974, 14267, 14268 }
local requested = false
local st = {}

function Range.Probe()
    if not requested and C_Spell and C_Spell.RequestLoadSpellData then
        requested = true
        pcall(C_Spell.RequestLoadSpellData, 75)
        for _, id in ipairs(WING_CLIP_IDS) do pcall(C_Spell.RequestLoadSpellData, id) end
    end
    local shot = S.InRange(S.Resolve("@autoShot").id or 75)
    local wing
    for _, id in ipairs(WING_CLIP_IDS) do
        wing = S.InRange(id)
        if wing ~= nil then break end
    end
    local close = SafeBool(CheckInteractDistance, "target", 4)
    return shot ~= true and wing == true, shot, close, wing
end

-- "melee" | "ranged" | "dead" (too close to shoot, too far to hit) | "far" | nil (unknown / no target)
function Range.State()
    if not HHT.HasAttackableTarget() then
        st.cur, st.cand = nil, nil
        return nil
    end
    local melee, shot, close = Range.Probe()
    local raw
    if shot == true then raw = "ranged"
    elseif melee then raw = "melee"
    elseif shot == false then
        if close == true then raw = "dead"
        elseif close == false then raw = "far" end
    end
    if raw == nil then return st.cur end
    local now = GetTime()
    if raw == st.cur then st.cand = nil; return raw end
    if raw ~= st.cand then st.cand, st.since = raw, now; return st.cur or raw end
    if now - st.since >= 0.18 then st.cur, st.cand = raw, nil end
    return st.cur or raw
end

-- Items with a known use distance (same ladder the other Forever range addons use); first rung in range = band.
Range.BANDS = { "Y10", "Y15", "Y20", "Y25", "Y30", "Y35" }
local LADDER = {
    { "Y10", 17626, 10699, 17689 },
    { "Y15", 4559 },
    { "Y20", 10645, 1191, 4388 },
    { "Y25", 13289 },
    { "Y30", 7734, 17202, 835, 2091 },
    { "Y35", 18904 },
}

local function ItemInRange(id)
    if not (C_Item and C_Item.IsItemInRange) then return nil end
    local ok, v = pcall(C_Item.IsItemInRange, id, "target")
    if not ok or HHT.IsSecret(v) then return nil end
    if v == true or v == 1 then return true end
    if v == false or v == 0 then return false end
    return nil
end

local function RungInRange(rung)
    local sawFalse = false
    for i = 2, #rung do
        local v = ItemInRange(rung[i])
        if v == true then return true end
        if v == false then sawFalse = true end
    end
    if sawFalse then return false end
    return nil
end

-- "MELEE" | "DEAD" | "Y10".."Y35" | "MAX" (beyond 35 yd, still in Auto Shot range) | "FAR" | nil (no target)
function Range.Band()
    local state = Range.State()
    if state == nil then return nil end
    if state == "melee" then return "MELEE" end
    if state == "dead" then return "DEAD" end
    local thirtyFive
    for i, rung in ipairs(LADDER) do
        local r = RungInRange(rung)
        if i == #LADDER then thirtyFive = r end
        if r == true then return rung[1] end
    end
    if state == "ranged" then return thirtyFive == false and "MAX" or "Y35" end
    return "FAR"
end

function Range.Debug()
    local melee, shot, close, wing = Range.Probe()
    HHT.Print(string.format("range=%s melee=%s autoShot=%s wingClip=%s within28yd=%s band=%s",
        tostring(Range.State()), tostring(melee), tostring(shot), tostring(wing), tostring(close), tostring(Range.Band())))
end
