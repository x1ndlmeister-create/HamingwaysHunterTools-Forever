-- Hunter class trainers and pet trainers, shown together as one world map layer.
local ADDON, HHT = ...
local L = HHT.L

HHT:AddGerman({
    ["Trainers"] = "Lehrer",
    ["Shows hunter trainers and pet trainers on the world map from a built-in list."] = "Zeigt Jaegerlehrer und Tierausbilder aus einer eingebauten Liste auf der Weltkarte.",
    ["Built-in list: %d trainers (hunter and pet)."] = "Eingebaute Liste: %d Lehrer (Jaeger und Tierausbilder).",
    ["Hunter trainer"] = "Jaegerlehrer",
    ["Pet trainer"] = "Tierausbilder",
    ["No trainers known here."] = "Keine Lehrer bekannt.",
    ["Trainers on map"] = "Lehrer auf der Karte",
    ["Waypoint to nearest trainer"] = "Wegpunkt zum naechsten Lehrer",
})

local M = HHT:NewModule("trainers", {
    name = "Trainers",
    desc = "Shows hunter trainers and pet trainers on the world map from a built-in list.",
    noFrame = true,
    defaults = { onMap = false, onMinimap = true, ownFaction = true },
})

local TR = {}
HHT.Trainers = TR

local ICON_HUNTER = "Interface\\Icons\\Ability_Marksmanship"
local ICON_PET = "Interface\\Icons\\Ability_Hunter_BeastTraining"
local COLOR = { 0.5, 0.85, 0.6 }

local function ZoneName(map)
    if C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, map)
        if ok and type(info) == "table" and type(info.name) == "string" then return info.name end
    end
    return "?"
end

function TR.List()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local key = M.db.ownFaction and faction or ""
    if M.cache and M.cacheKey == key then return M.cache end
    local out = {}
    for _, e in ipairs(HHT.TrainerData or {}) do
        local ok = e.fa == "N" or not M.db.ownFaction or (e.fa == "A" and faction == "Alliance") or (e.fa == "H" and faction == "Horde")
        if ok then
            local pet = e.k == "P"
            out[#out + 1] = {
                n = e.n, sp = { [e.m] = string.format("%d,%d", e.x, e.y) },
                icon = pet and ICON_PET or ICON_HUNTER, color = COLOR,
                lines = { pet and L("Pet trainer") or L("Hunter trainer"), ZoneName(e.m) },
            }
        end
    end
    M.cache, M.cacheKey = out, key
    return out
end

function TR.Show()
    if not (M.enabled and HHT.PetMap) then return end
    local list = TR.List()
    if #list == 0 then HHT.Print(L("No trainers known here.")); return end
    M.db.onMap = true
    HHT.PetMap:OpenFor(list)
end

function TR.Nearest()
    if not (M.enabled and HHT.PetMap) then return end
    local best = HHT.PetMap:Nearest(TR.List())
    if not best then HHT.Print(L("No trainers known here.")); return end
    HHT.PetMap:SetWaypointAt(best[1], best[2], best[3], best[4])
end

function M:Refresh()
    M.cache = nil
    if HHT.PetMap then HHT.PetMap:Update() end
end

function M:OnDisable()
    if HHT.PetMap then HHT.PetMap:Update() end
end

if HHT.PetMap then
    HHT.PetMap.AddLayer("trainers", "Trainers",
        function() if M.enabled and M.db and M.db.onMap then return TR.List() end end,
        function() return M.db and M.db.onMap end,
        function(v) if M.db then M.db.onMap = v and true or false end end,
        function() return M.db and M.db.onMinimap ~= false end)
end

function M:BuildOptions(form)
    local db = self.db
    form:Check(L("Show on the world map"), db, "onMap")
    form:Check(L("Also show on the minimap"), db, "onMinimap")
    form:Button(L("Trainers on map"), TR.Show, 240)
    form:Button(L("Waypoint to nearest trainer"), TR.Nearest, 240)
    form:Check(L("Only my faction"), db, "ownFaction")
    form:Note(string.format(L("Built-in list: %d trainers (hunter and pet)."), #(HHT.TrainerData or {})))
end
