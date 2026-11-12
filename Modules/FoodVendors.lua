-- Food vendors: vendors that sell food for your current pet, shown as a world map layer. Learns missing ones at merchants.
local ADDON, HHT = ...
local L = HHT.L

HHT:AddGerman({
    ["Food vendors"] = "Futterhaendler",
    ["Shows vendors that sell food for your current pet on the world map and learns missing ones."] = "Zeigt Haendler, die Futter fuer deinen aktuellen Begleiter verkaufen, auf der Weltkarte und lernt fehlende dazu.",
    ["Food vendor"] = "Futterhaendler",
    ["Show all diets (ignore my pet)"] = "Alle Nahrungsarten zeigen (Begleiter ignorieren)",
    ["Food vendors on map"] = "Futterhaendler auf der Karte",
    ["Waypoint to nearest food vendor"] = "Wegpunkt zum naechsten Futterhaendler",
    ["Forget learned food vendors"] = "Gelernte Futterhaendler vergessen",
    ["Built-in list: %d food vendors. Learned by visiting: %d."] = "Eingebaute Liste: %d Futterhaendler. Durch Besuch gelernt: %d.",
    ["Food vendors are learned when you open their merchant window. Visit one to add it."] = "Fehlt ein Haendler in der Liste, wird er gelernt, sobald du sein Haendlerfenster oeffnest und er Futter verkauft.",
    ["Food vendor learned: %s"] = "Futterhaendler gelernt: %s",
    ["No food vendors known here."] = "Keine Futterhaendler bekannt.",
    ["Sells"] = "Verkauft",
})

local M = HHT:NewModule("foodvendors", {
    name = "Food vendors",
    desc = "Shows vendors that sell food for your current pet on the world map and learns missing ones.",
    noFrame = true,
    defaults = { onMap = false, onMinimap = true, ownFaction = true, allDiets = false, learned = {} },
})

local FV = {}
HHT.FoodVendors = FV

local ICON = "Interface\\Icons\\INV_Misc_Food_19"
local COLOR = { 0.45, 0.85, 0.35 }
local ORDER = { "m", "f", "u", "b", "c", "r" }
local CODE = { meat = "m", fish = "f", fungus = "u", bread = "b", cheese = "c", fruit = "r" }
local NAME = { m = "Meat", f = "Fish", u = "Fungus", b = "Bread", c = "Cheese", r = "Fruit" }

local function ZoneName(map)
    if C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, map)
        if ok and type(info) == "table" and type(info.name) == "string" then return info.name end
    end
    return "?"
end

-- Diet codes of the current pet as a string like "mf", or "" when unknown.
local function PetCodes()
    local pf = HHT.PetFood
    if not (pf and pf.PetDiets and UnitExists and UnitExists("pet")) then return "" end
    local out = ""
    local set = pf.PetDiets()
    for _, c in ipairs(ORDER) do
        for diet, code in pairs(CODE) do
            if code == c and set[diet] then out = out .. c end
        end
    end
    return out
end

local function Overlap(a, b)
    for c in a:gmatch(".") do
        if b:find(c, 1, true) then return true end
    end
    return false
end

local function DietLine(codes)
    local parts = {}
    for _, c in ipairs(ORDER) do
        if codes:find(c, 1, true) then parts[#parts + 1] = L(NAME[c]) end
    end
    return L("Sells") .. ": " .. table.concat(parts, ", ")
end

function FV.List()
    local db = M.db
    if not db then return {} end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local want = db.allDiets and "" or PetCodes()
    local key = want .. (db.ownFaction and faction or "") .. (M.ver or 0) .. #db.learned
    if M.cache and M.cacheKey == key then return M.cache end
    local out, seen = {}, {}
    local function add(e)
        local id = e.n .. ":" .. e.m
        if seen[id] then return end
        if want ~= "" and not Overlap(want, e.d) then return end
        seen[id] = true
        out[#out + 1] = {
            n = e.n, sp = { [e.m] = string.format("%d,%d", e.x, e.y) },
            icon = ICON, color = COLOR, lines = { DietLine(e.d), ZoneName(e.m) },
        }
    end
    for _, e in ipairs(HHT.FoodVendorData or {}) do
        local ok = e.fa == "N" or not db.ownFaction or (e.fa == "A" and faction == "Alliance") or (e.fa == "H" and faction == "Horde")
        if ok then add(e) end
    end
    for _, e in ipairs(db.learned) do add(e) end
    M.cache, M.cacheKey = out, key
    return out
end

function FV.Show()
    if not (M.enabled and HHT.PetMap) then return end
    local list = FV.List()
    if #list == 0 then HHT.Print(L("No food vendors known here.")); return end
    M.db.onMap = true
    HHT.PetMap:OpenFor(list)
end

function FV.Nearest()
    if not (M.enabled and HHT.PetMap) then return end
    local best = HHT.PetMap:Nearest(FV.List())
    if not best then HHT.Print(L("No food vendors known here.")); return end
    HHT.PetMap:SetWaypointAt(best[1], best[2], best[3], best[4])
end

local function MerchantCodes()
    local pf = HHT.PetFood
    if not (pf and pf.ItemDiet and GetMerchantNumItems and GetMerchantItemLink) then return "" end
    local have = {}
    for i = 1, GetMerchantNumItems() do
        local ok, link = pcall(GetMerchantItemLink, i)
        local id = ok and type(link) == "string" and not HHT.IsSecret(link) and tonumber(link:match("item:(%d+)"))
        local diet = id and pf.ItemDiet[id]
        if diet and CODE[diet] then have[CODE[diet]] = true end
    end
    local out = ""
    for _, c in ipairs(ORDER) do if have[c] then out = out .. c end end
    return out
end

function M:OnMerchant()
    if not (HHT.PetMap and self.db) then return end
    local codes = MerchantCodes()
    if codes == "" then return end
    local map, x, y = HHT.PetMap.PlayerPos()
    if not map then return end
    local ok, name = pcall(UnitName, "npc")
    if not ok or type(name) ~= "string" or name == "" or HHT.IsSecret(name) then return end
    for _, e in ipairs(HHT.FoodVendorData or {}) do
        if e.n == name and e.m == map then return end
    end
    for _, e in ipairs(self.db.learned) do
        if e.n == name and e.m == map then
            local merged = ""
            for _, c in ipairs(ORDER) do
                if e.d:find(c, 1, true) or codes:find(c, 1, true) then merged = merged .. c end
            end
            if merged ~= e.d then
                e.d = merged
                self.ver = (self.ver or 0) + 1
                HHT.PetMap:Update()
            end
            return
        end
    end
    local px, py = math.floor(x * 1000 + 0.5), math.floor(y * 1000 + 0.5)
    self.db.learned[#self.db.learned + 1] = { n = name, m = map, x = px, y = py, d = codes }
    HHT.Print(string.format(L("Food vendor learned: %s"), name))
    HHT.PetMap:Update()
end

function M:OnPet(_, unit)
    if unit and unit ~= "player" then return end
    if HHT.PetMap and self.db and self.db.onMap and not self.db.allDiets then HHT.PetMap:Update() end
end

function M:OnInit()
    HHT:Listen(self, "MERCHANT_SHOW", "OnMerchant")
    HHT:Listen(self, "UNIT_PET", "OnPet")
end

function M:Refresh()
    if HHT.PetMap then HHT.PetMap:Update() end
end

function M:OnDisable()
    if HHT.PetMap then HHT.PetMap:Update() end
end

if HHT.PetMap then
    HHT.PetMap.AddLayer("food", "Food vendors",
        function() if M.enabled and M.db and M.db.onMap then return FV.List() end end,
        function() return M.db and M.db.onMap end,
        function(v) if M.db then M.db.onMap = v and true or false end end,
        function() return M.db and M.db.onMinimap ~= false end)
end

function M:BuildOptions(form)
    local db = self.db
    form:Check(L("Show on the world map"), db, "onMap")
    form:Check(L("Also show on the minimap"), db, "onMinimap")
    form:Check(L("Only my faction"), db, "ownFaction")
    form:Check(L("Show all diets (ignore my pet)"), db, "allDiets")
    form:Button(L("Food vendors on map"), FV.Show, 240)
    form:Button(L("Waypoint to nearest food vendor"), FV.Nearest, 240)
    form:Note(string.format(L("Built-in list: %d food vendors. Learned by visiting: %d."), #(HHT.FoodVendorData or {}), #db.learned))
    form:Note(L("Food vendors are learned when you open their merchant window. Visit one to add it."))
    form:Button(L("Forget learned food vendors"), function()
        for i = #db.learned, 1, -1 do db.learned[i] = nil end
        M.cache = nil
        HHT.PetMap:Update()
    end, 220)
end
