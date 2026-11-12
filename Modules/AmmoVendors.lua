-- Ammo vendors: world map pins and a waypoint to the nearest vendor.
local ADDON, HHT = ...
local L = HHT.L

HHT:AddGerman({
    ["Ammo vendors"] = "Munitionshaendler",
    ["Shows ammo vendors on the world map and sets a waypoint to the nearest one."] = "Zeigt Munitionshaendler auf der Weltkarte und setzt einen Wegpunkt zum naechsten.",
    ["Ammo vendors on map"] = "Munitionshaendler auf Karte",
    ["Waypoint to nearest vendor"] = "Wegpunkt zum naechsten Haendler",
    ["Sells"] = "Verkauft",
    ["Arrows"] = "Pfeile",
    ["Bullets"] = "Kugeln",
    ["Arrows and bullets"] = "Pfeile und Kugeln",
    ["Show vendors for"] = "Haendler zeigen fuer",
    ["Ammo your weapon uses"] = "Munition deiner Waffe",
    ["Only my faction"] = "Nur meine Fraktion",
    ["Pins appear on the world map. Click a pin to set a waypoint."] = "Die Punkte erscheinen auf der Weltkarte. Klick auf einen Punkt setzt einen Wegpunkt. Ein- und ausschalten geht auch ueber den Knopf oben links an der Karte.",
    ["Show on the world map"] = "Auf der Weltkarte zeigen",
    ["Also show on the minimap"] = "Auch auf der Minimap zeigen",
    ["No ammo vendors known here."] = "Hier sind keine Munitionshaendler bekannt.",
    ["Nearest ammo vendor: %s"] = "Naechster Munitionshaendler: %s",
})

local M = HHT:NewModule("ammovendors", {
    name = "Ammo vendors",
    desc = "Shows ammo vendors on the world map and sets a waypoint to the nearest one.",
    noFrame = true,
    defaults = { kind = "auto", ownFaction = true, onMap = false, onMinimap = true },
})

local AV = {}
HHT.AmmoVendors = AV

local ICON = {
    a = "Interface\\Icons\\INV_Ammo_Arrow_02",
    b = "Interface\\Icons\\INV_Ammo_Bullet_02",
    ab = "Interface\\Icons\\INV_Ammo_Arrow_02",
}
local COLOR = { A = { 0.3, 0.55, 1 }, H = { 0.9, 0.25, 0.25 }, N = { 0.9, 0.8, 0.3 } }

local function Sells(t)
    if t == "a" then return L("Arrows") end
    if t == "b" then return L("Bullets") end
    return L("Arrows and bullets")
end

-- Same shape as a pet database beast, so PetMap can draw it.
local function Entry(v)
    local e = v.entry
    if not e then
        local pts = {}
        for _, p in ipairs(v.p) do pts[#pts + 1] = string.format("%d,%d", p[1], p[2]) end
        e = {
            n = v.n, sp = { [v.m] = table.concat(pts, ";") },
            icon = ICON[v.t], color = COLOR[v.fa],
            lines = { L("Sells") .. ": " .. Sells(v.t), v.z },
            vendor = v,
        }
        v.entry = e
    end
    return e
end

function AV.List()
    local data = HHT.AmmoVendorData or {}
    local db = M.db
    local want = db.kind
    if want == "auto" then
        local am = HHT.modules.ammo
        want = (am and am.needs == "bullet" and "b") or (am and am.needs == "arrow" and "a") or "all"
    end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local out = {}
    for _, v in ipairs(data) do
        local factionOk = v.fa == "N" or not db.ownFaction or (v.fa == "A" and faction == "Alliance") or (v.fa == "H" and faction == "Horde")
        local typeOk = want == "all" or v.t == "ab" or v.t == want
        if factionOk and typeOk then out[#out + 1] = Entry(v) end
    end
    return out
end

function AV.Show()
    if not M.enabled then return end
    local list = AV.List()
    if #list == 0 then HHT.Print(L("No ammo vendors known here.")); return end
    M.db.onMap = true
    if HHT.PetMap then HHT.PetMap:OpenFor(list) end
end

if HHT.PetMap then
    HHT.PetMap.AddLayer("ammo", "Ammo vendors",
        function() if M.enabled and M.db and M.db.onMap then return AV.List() end end,
        function() return M.db and M.db.onMap end,
        function(v) if M.db then M.db.onMap = v and true or false end end,
        function() return M.db and M.db.onMinimap ~= false end)
end

function AV.Nearest()
    if not (M.enabled and HHT.PetMap) then return end
    local best = HHT.PetMap:Nearest(AV.List())
    if not best then HHT.Print(L("No ammo vendors known here.")); return end
    HHT.PetMap:SetWaypointAt(best[1], best[2], best[3], best[4])
end

function M:Refresh()
    if HHT.PetMap then HHT.PetMap:Update() end
end

function M:OnDisable()
    if HHT.PetMap then HHT.PetMap:ClearWaypoint(); HHT.PetMap:Update() end
end

function M:BuildOptions(form)
    local db = self.db
    form:Check(L("Show on the world map"), db, "onMap")
    form:Check(L("Also show on the minimap"), db, "onMinimap")
    form:Button(L("Ammo vendors on map"), AV.Show, 240)
    form:Button(L("Waypoint to nearest vendor"), AV.Nearest, 240)
    form:Note(L("Pins appear on the world map. Click a pin to set a waypoint."))
    form:Header(L("Behavior"))
    form:Cycle(L("Show vendors for"), db, "kind", {
        { "auto", L("Ammo your weapon uses") }, { "a", L("Arrows") }, { "b", L("Bullets") }, { "all", L("Arrows and bullets") } })
    form:Check(L("Only my faction"), db, "ownFaction")
end
