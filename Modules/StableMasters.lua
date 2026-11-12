-- Stable masters: learned when you open their stable window, shown as a world map layer.
local ADDON, HHT = ...
local L = HHT.L

HHT:AddGerman({
    ["Stable masters"] = "Stallmeister",
    ["Shows stable masters on the world map from a built-in list and learns missing ones."] = "Zeigt Stallmeister aus einer eingebauten Liste auf der Weltkarte und lernt fehlende dazu.",
    ["Show on the world map"] = "Auf der Weltkarte zeigen",
    ["Also show on the minimap"] = "Auch auf der Minimap zeigen",
    ["Stable masters are learned when you open their stable window. Visit one to add it."] = "Fehlt ein Stallmeister in der Liste, wird er gelernt, sobald du sein Stallfenster oeffnest.",
    ["Built-in list: %d stable masters. Learned by visiting: %d."] = "Eingebaute Liste: %d Stallmeister. Durch Besuch gelernt: %d.",
    ["Forget learned stable masters"] = "Gelernte Stallmeister vergessen",
    ["Stable master learned: %s"] = "Stallmeister gelernt: %s",
    ["Stable master"] = "Stallmeister",
    ["Only my faction"] = "Nur meine Fraktion",
    ["No stable masters known here."] = "Keine Stallmeister bekannt.",
    ["Stable masters on map"] = "Stallmeister auf der Karte",
    ["Waypoint to nearest stable master"] = "Wegpunkt zum naechsten Stallmeister",
})

local M = HHT:NewModule("stablemasters", {
    name = "Stable masters",
    desc = "Shows stable masters on the world map from a built-in list and learns missing ones.",
    noFrame = true,
    defaults = { onMap = false, onMinimap = true, ownFaction = true, learned = {} },
})

local SM = {}
HHT.StableMasters = SM

local ICON = "Interface\\MINIMAP\\TRACKING\\StableMaster"
local COLOR = { 0.9, 0.8, 0.3 }

local function ZoneName(map)
    if C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, map)
        if ok and type(info) == "table" and type(info.name) == "string" then return info.name end
    end
    return "?"
end

function SM.List()
    local learned = M.db and M.db.learned or {}
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local key = #learned .. (M.db.ownFaction and faction or "")
    if M.cache and M.cacheKey == key then return M.cache end
    local out, seen = {}, {}
    local function add(e)
        local id = e.n .. ":" .. e.m
        if seen[id] then return end
        seen[id] = true
        out[#out + 1] = {
            n = e.n, sp = { [e.m] = string.format("%d,%d", e.x, e.y) },
            icon = ICON, color = COLOR, lines = { L("Stable master"), ZoneName(e.m) },
        }
    end
    for _, e in ipairs(HHT.StableMasterData or {}) do
        local ok = e.fa == "N" or not M.db.ownFaction or (e.fa == "A" and faction == "Alliance") or (e.fa == "H" and faction == "Horde")
        if ok then add(e) end
    end
    for _, e in ipairs(learned) do add(e) end
    M.cache, M.cacheKey = out, key
    return out
end

function SM.Show()
    if not (M.enabled and HHT.PetMap) then return end
    local list = SM.List()
    if #list == 0 then HHT.Print(L("No stable masters known here.")); return end
    M.db.onMap = true
    HHT.PetMap:OpenFor(list)
end

function SM.Nearest()
    if not (M.enabled and HHT.PetMap) then return end
    local best = HHT.PetMap:Nearest(SM.List())
    if not best then HHT.Print(L("No stable masters known here.")); return end
    HHT.PetMap:SetWaypointAt(best[1], best[2], best[3], best[4])
end

function M:OnStable()
    if not (HHT.PetMap and self.db) then return end
    local map, x, y = HHT.PetMap.PlayerPos()
    if not map then return end
    local ok, name = pcall(UnitName, "npc")
    if not ok or type(name) ~= "string" or name == "" or HHT.IsSecret(name) then return end
    local px, py = math.floor(x * 1000 + 0.5), math.floor(y * 1000 + 0.5)
    for _, e in ipairs(self.db.learned) do
        if e.n == name and e.m == map then return end
    end
    for _, e in ipairs(HHT.StableMasterData or {}) do
        if e.n == name and e.m == map then return end
    end
    self.db.learned[#self.db.learned + 1] = { n = name, m = map, x = px, y = py }
    HHT.Print(string.format(L("Stable master learned: %s"), name))
    HHT.PetMap:Update()
end

function M:OnInit()
    HHT:Listen(self, "PET_STABLE_SHOW", "OnStable")
end

function M:Refresh()
    if HHT.PetMap then HHT.PetMap:Update() end
end

function M:OnDisable()
    if HHT.PetMap then HHT.PetMap:Update() end
end

if HHT.PetMap then
    HHT.PetMap.AddLayer("stable", "Stable masters",
        function() if M.enabled and M.db and M.db.onMap then return SM.List() end end,
        function() return M.db and M.db.onMap end,
        function(v) if M.db then M.db.onMap = v and true or false end end,
        function() return M.db and M.db.onMinimap ~= false end)
end

function M:BuildOptions(form)
    local db = self.db
    form:Check(L("Show on the world map"), db, "onMap")
    form:Check(L("Also show on the minimap"), db, "onMinimap")
    form:Button(L("Stable masters on map"), SM.Show, 240)
    form:Button(L("Waypoint to nearest stable master"), SM.Nearest, 240)
    form:Check(L("Only my faction"), db, "ownFaction")
    form:Note(string.format(L("Built-in list: %d stable masters. Learned by visiting: %d."), #(HHT.StableMasterData or {}), #db.learned))
    form:Note(L("Stable masters are learned when you open their stable window. Visit one to add it."))
    form:Button(L("Forget learned stable masters"), function()
        for i = #db.learned, 1, -1 do db.learned[i] = nil end
        M.cache = nil
        HHT.PetMap:Update()
    end, 220)
end
