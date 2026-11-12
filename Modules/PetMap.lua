-- Pet map: pins and waypoints for tameable beasts on the world map.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

local PM = {}
HHT.PetMap = PM
PM.list = {}

local MAX_PINS = 400
local pins, hooked = {}, false
local conv = {}

local function Dex() return HHT.PetDex end
local function Db() return HHT.modules.petdex and HHT.modules.petdex.db end

-- spawn string "x,y;x,y" (tenths of a percent) -> { {x, y}, ... } in 0..1
local function Points(b, map)
    b.pts = b.pts or {}
    local t = b.pts[map]
    if not t then
        t = {}
        local s = b.sp and b.sp[map]
        if s then
            for x, y in s:gmatch("(%d+),(%d+)") do t[#t + 1] = { tonumber(x) / 1000, tonumber(y) / 1000 } end
        end
        b.pts[map] = t
    end
    return t
end
PM.Points = Points

local function SortedMaps(b)
    local maps = {}
    for map in pairs(b.sp or {}) do maps[#maps + 1] = map end
    table.sort(maps)
    return maps
end

-- Point on map src -> point on the shown map dst (nil when it does not lie on it).
local function Convert(src, x, y, dst)
    if src == dst then return x, y end
    if not (C_Map and C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return nil end
    local key = src .. ":" .. dst .. ":" .. x .. ":" .. y
    local c = conv[key]
    if c ~= nil then
        if c == false then return nil end
        return c[1], c[2]
    end
    local ok, cont, world = pcall(C_Map.GetWorldPosFromMapPos, src, CreateVector2D(x, y))
    if ok and cont and world then
        -- Returns uiMapID, position (the position is the second value).
        local ok2, rid, pos = pcall(C_Map.GetMapPosFromWorldPos, cont, world, dst)
        if ok2 and type(pos) == "table" and pos.GetXY then
            local px, py = pos:GetXY()
            if px and py and px >= 0 and px <= 1 and py >= 0 and py <= 1 then
                conv[key] = { px, py }
                return px, py
            end
        end
    end
    conv[key] = false
    return nil
end

local function Canvas()
    local wm = WorldMapFrame
    if not wm then return nil end
    if wm.GetCanvas then
        local ok, c = pcall(wm.GetCanvas, wm)
        if ok and c then return c end
    end
    return wm.ScrollContainer and wm.ScrollContainer.Child
end

local function PinTip(pin)
    local b = pin.beast
    if not b or not GameTooltip then return end
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:AddLine(b.n, 0.67, 0.83, 0.45)
    if b.lines then
        for _, line in ipairs(b.lines) do GameTooltip:AddLine(line, 0.9, 0.9, 0.9) end
    else
        GameTooltip:AddLine(L(b.f) .. ", " .. L("Level") .. " " .. b.l, 0.9, 0.9, 0.9)
        for _, e in ipairs(Dex().BeastAbilities(b)) do
            local line = Dex().AbilityName(e.a)
            if e.rank > 0 then line = line .. " " .. e.rank end
            GameTooltip:AddLine(line, 0.7, 0.7, 0.7)
        end
    end
    GameTooltip:AddLine(L("Click: set waypoint"), 0.5, 0.8, 1)
    GameTooltip:Show()
end

local function NewPin(canvas)
    local p = CreateFrame("Button", nil, canvas)
    p:SetFrameStrata("FULLSCREEN_DIALOG")
    p:RegisterForClicks("LeftButtonUp")
    p.back = p:CreateTexture(nil, "BACKGROUND")
    p.back:SetAllPoints()
    p.back:SetColorTexture(0.05, 0.05, 0.05, 0.9)
    p.tex = p:CreateTexture(nil, "ARTWORK")
    p.tex:SetPoint("TOPLEFT", 1, -1)
    p.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    p.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    p.border = UI.Border(p, 0.1, 0.1, 0.1, 1)
    p:SetScript("OnEnter", PinTip)
    p:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    p:SetScript("OnClick", function(self)
        if self.beast then PM:SetWaypointAt(self.map, self.x, self.y, self.beast.n) end
    end)
    return p
end

local RARITY = { rare = { 0.45, 0.75, 1 }, elite = { 1, 0.82, 0.3 }, rareelite = { 0.75, 0.55, 1 } }

function PM:HidePins()
    for _, p in ipairs(pins) do p:Hide(); p.beast = nil end
end

-- Map layers: toggles in the map button menu. listFn returns entries (same shape as a beast) or nil while off.
PM.layers, PM.layerDefs = {}, {}
-- mini (optional) returns true when the layer may also be drawn on the minimap.
function PM.AddLayer(key, label, listFn, get, set, mini)
    PM.layers[key] = listFn
    PM.layerDefs[#PM.layerDefs + 1] = { key = key, label = label, get = get, set = set, mini = mini }
end

function PM:Update()
    self:HidePins()
    local db = Db()
    local pm = HHT.modules.petdex
    local sources = {}
    if #self.list > 0 and pm and pm.enabled and db and db.pins then sources[#sources + 1] = { self.list, true } end
    for _, def in ipairs(PM.layerDefs) do
        local l = PM.layers[def.key]()
        if l and #l > 0 then sources[#sources + 1] = { l, false } end
    end
    if #sources == 0 then self.why = "no active layer or list"; return end
    local wm = WorldMapFrame
    if not (wm and wm:IsShown()) then self.why = "map hidden"; return end
    local canvas = Canvas()
    if not canvas then self.why = "no canvas"; return end
    local ok, cur = pcall(wm.GetMapID, wm)
    if not ok or not cur then self.why = "no map id"; return end
    local cs = 1
    if wm.GetCanvasScale then
        local ok2, s = pcall(wm.GetCanvasScale, wm)
        if ok2 and type(s) == "number" and s > 0 then cs = s end
    end
    local w, h = canvas:GetWidth(), canvas:GetHeight()
    if not w or w <= 0 then self.why = "canvas size 0"; return end
    local ps = 1 / cs
    local size = (db and db.pinSize) or 20
    local n = 0
    for _, src in ipairs(sources) do
    local list = src[1]
    local perBeast = (src[2] and #list > 1) and 5 or 99
    for _, b in ipairs(list) do
        local found = {}
        for _, map in ipairs(SortedMaps(b)) do
            for _, pt in ipairs(Points(b, map)) do
                local x, y = Convert(map, pt[1], pt[2], cur)
                if x then found[#found + 1] = { map, pt[1], pt[2], x, y } end
            end
        end
        local step = math.max(1, math.ceil(#found / perBeast))
        for i = 1, #found, step do
            if n >= MAX_PINS then break end
            n = n + 1
            local p = pins[n]
            if not p then p = NewPin(canvas); pins[n] = p end
            local f = found[i]
            p:SetParent(canvas)
            p:SetFrameLevel(100)
            p:SetSize(size, size)
            p:SetScale(ps)
            p:ClearAllPoints()
            p:SetPoint("CENTER", canvas, "TOPLEFT", f[4] * w / ps, -f[5] * h / ps)
            p.tex:SetTexture(b.icon or Dex().FamilyIcon(b.f))
            local c = b.color or RARITY[b.r] or { 0.1, 0.1, 0.1 }
            p.border:SetColor(c[1], c[2], c[3], 1)
            p.beast, p.map, p.x, p.y = b, f[1], f[2], f[3]
            p:Show()
        end
    end
    end
    self.why = "drew " .. n .. " pins on map " .. tostring(cur)
end

function PM.Install()
    if hooked then return true end
    if not WorldMapFrame and UIParentLoadAddOn then pcall(UIParentLoadAddOn, "Blizzard_WorldMap") end
    local wm = WorldMapFrame
    if not wm then return false end
    hooked = true
    local function upd() PM:Update() end
    pcall(hooksecurefunc, wm, "OnMapChanged", upd)
    pcall(hooksecurefunc, wm, "OnCanvasScaleChanged", upd)
    pcall(wm.HookScript, wm, "OnShow", upd)
    -- Fallback when the map frame does not call OnMapChanged for every navigation.
    local poll, acc, lastMap, lastScale = CreateFrame("Frame"), 0, nil, nil
    poll:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 0.25 then return end
        acc = 0
        if not wm:IsShown() then lastMap = nil; return end
        local ok, cur = pcall(wm.GetMapID, wm)
        local scale = wm.GetCanvasScale and select(2, pcall(wm.GetCanvasScale, wm))
        if ok and cur and (cur ~= lastMap or scale ~= lastScale) then
            lastMap, lastScale = cur, scale
            PM:Update()
        end
    end)
    return true
end

function PM:Clear()
    self.list = {}
    self:HidePins()
    self:ClearWaypoint()
end

-- Only removes a waypoint this module set.
function PM:ClearWaypoint()
    if not self.waypointSet then return end
    self.waypointSet = nil
    if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
    if TomTom and self.tomtomUid and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, self.tomtomUid) end
    self.tomtomUid = nil
end

-- Player position as map, x, y (0..1); nil when unknown.
function PM.PlayerPos()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
    local ok, map = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or not map then return nil end
    local ok2, pos = pcall(C_Map.GetPlayerMapPosition, map, "player")
    if not ok2 or not pos or not pos.GetXY then return nil end
    local x, y = pos:GetXY()
    if not x or not y or (x == 0 and y == 0) then return nil end
    return map, x, y
end

-- Offset in yards between two points of the same map: dx (east), dy (south).
function PM.Offset(map, x1, y1, x2, y2)
    local w, h = 1000, 1000
    if C_Map and C_Map.GetMapWorldSize then
        local ok, ww, hh = pcall(C_Map.GetMapWorldSize, map)
        if ok and type(ww) == "number" and ww > 0 and type(hh) == "number" and hh > 0 then w, h = ww, hh end
    end
    return (x2 - x1) * w, (y2 - y1) * h
end

local function World(map, x, y)
    if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(x, y))
    if not ok or not cont or not pos or not pos.GetXY then return nil end
    local wx, wy = pos:GetXY()
    if not wx or not wy then return nil end
    return cont, wx, wy
end

-- Closest spawn of a list on the player's continent: { map, x, y, name } or nil.
function PM:Nearest(list)
    local pmap, px, py = PM.PlayerPos()
    if not pmap then return nil end
    local cont, wx, wy = World(pmap, px, py)
    local best, bestD
    for _, e in ipairs(list) do
        for _, map in ipairs(SortedMaps(e)) do
            for _, pt in ipairs(Points(e, map)) do
                local d
                if map == pmap then
                    local dx, dy = PM.Offset(pmap, px, py, pt[1], pt[2])
                    d = dx * dx + dy * dy
                elseif cont then
                    local c2, ox, oy = World(map, pt[1], pt[2])
                    if c2 == cont then d = (ox - wx) ^ 2 + (oy - wy) ^ 2 end
                end
                if d and (not bestD or d < bestD) then best, bestD = { map, pt[1], pt[2], e.n }, d end
            end
        end
    end
    return best
end

-- Minimap pins: the same sources as the world map, placed by yard offset from the player.
-- Diameter of the minimap in yards per zoom level.
local MINI_OUT = { [0] = 466.67, 400, 333.33, 266.67, 200, 133.33 }
local MINI_IN = { [0] = 300, 240, 180, 120, 80, 50 }
local MINI_MAX, MINI_SIZE = 80, 16
local mini = { pins = {}, pts = {}, map = nil, built = 0, acc = 0 }

local function MiniSources()
    local out = {}
    local db, pm = Db(), HHT.modules.petdex
    if #PM.list > 0 and pm and pm.enabled and db and db.pins and db.minimap ~= false then out[#out + 1] = PM.list end
    local wm = HHT.modules.petwatch
    if wm and wm.enabled and wm.track and wm.track.sp and db and db.minimap ~= false then out[#out + 1] = { wm.track } end
    for _, def in ipairs(PM.layerDefs) do
        if not def.mini or def.mini() then
            local l = PM.layers[def.key]()
            if l and #l > 0 then out[#out + 1] = l end
        end
    end
    return out
end

local function MiniBuild(map)
    local pts = {}
    for _, list in ipairs(MiniSources()) do
        for _, b in ipairs(list) do
            for _, m in ipairs(SortedMaps(b)) do
                for _, pt in ipairs(Points(b, m)) do
                    local x, y = Convert(m, pt[1], pt[2], map)
                    if x then pts[#pts + 1] = { b, m, pt[1], pt[2], x, y } end
                end
            end
        end
    end
    mini.pts, mini.map = pts, map
end

local function MiniHide(from)
    for i = from or 1, #mini.pins do
        local p = mini.pins[i]
        if p:IsShown() then p:Hide() end
        p.beast = nil
    end
end

local function MiniPin(i)
    local p = mini.pins[i]
    if p then return p end
    p = NewPin(Minimap)
    p:SetFrameStrata(Minimap:GetFrameStrata())
    p:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    p:SetSize(MINI_SIZE, MINI_SIZE)
    mini.pins[i] = p
    return p
end

local function MiniTick()
    if not (Minimap and Minimap:IsVisible()) then MiniHide(); return end
    local map, px, py = PM.PlayerPos()
    if not map then MiniHide(); return end
    local now = GetTime()
    if map ~= mini.map or now - mini.built > 1 then
        mini.built = now
        MiniBuild(map)
    end
    local pts = mini.pts
    if #pts == 0 then MiniHide(); return end
    local zoom = Minimap:GetZoom() or 0
    local diameter = ((IsIndoors and IsIndoors()) and MINI_IN or MINI_OUT)[zoom] or MINI_OUT[0]
    local half = (Minimap:GetWidth() or 140) / 2
    local scale = half * 2 / diameter
    local cs, sn
    if GetCVar and GetCVar("rotateMinimap") == "1" and GetPlayerFacing then
        local f = GetPlayerFacing()
        if f then cs, sn = math.cos(f), math.sin(f) end
    end
    local limit = (half - 2) ^ 2
    local n = 0
    for _, e in ipairs(pts) do
        local dx, dy = PM.Offset(map, px, py, e[5], e[6])
        local ex, ny = dx, -dy
        if cs then ex, ny = dx * cs + (-dy) * sn, -dx * sn + (-dy) * cs end
        local sx, sy = ex * scale, ny * scale
        if sx * sx + sy * sy <= limit and n < MINI_MAX then
            n = n + 1
            local p = MiniPin(n)
            local b = e[1]
            if p.beast ~= b then
                p.tex:SetTexture(b.icon or (Dex() and Dex().FamilyIcon(b.f)))
                local c = b.color or RARITY[b.r] or { 0.1, 0.1, 0.1 }
                p.border:SetColor(c[1], c[2], c[3], 1)
                p.beast = b
            end
            p.map, p.x, p.y = e[2], e[3], e[4]
            p:ClearAllPoints()
            p:SetPoint("CENTER", Minimap, "CENTER", sx, sy)
            if not p:IsShown() then p:Show() end
        end
    end
    MiniHide(n + 1)
end

if Minimap and CreateFrame then
    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function(_, dt)
        mini.acc = mini.acc + dt
        if mini.acc < 0.05 then return end
        mini.acc = 0
        local ok, err = pcall(MiniTick)
        if not ok and not mini.warned then mini.warned = true; HHT.Print("minimap pins: " .. tostring(err)) end
    end)
end

function PM:Debug()
    local wm, canvas = WorldMapFrame, Canvas()
    local ok, cur = false, nil
    if wm then ok, cur = pcall(wm.GetMapID, wm) end
    local shown = 0
    for _, p in ipairs(pins) do if p:IsShown() then shown = shown + 1 end end
    HHT.Print(string.format("petmap: list=%d map=%s mapShown=%s canvas=%s size=%sx%s pins=%d shown=%d hooked=%s",
        #self.list, tostring(cur), tostring(wm and wm:IsShown()), tostring(canvas ~= nil),
        tostring(canvas and canvas:GetWidth()), tostring(canvas and canvas:GetHeight()), #pins, shown, tostring(hooked)))
    local b = self.list[1]
    local lt = {}
    for _, def in ipairs(PM.layerDefs) do
        local l = PM.layers[def.key]()
        lt[#lt + 1] = def.key .. "=" .. (l and #l or "off")
    end
    HHT.Print("layers: " .. table.concat(lt, " ") .. " | last update: " .. tostring(self.why))
    if b and b.sp then
        local t = {}
        for map, s in pairs(b.sp) do t[#t + 1] = map .. ":" .. #Points(b, map) end
        HHT.Print(b.n .. " maps " .. table.concat(t, ", "))
    end
end

local function OpenMap(map)
    if not PM.Install() then return end
    local opened = false
    if OpenWorldMap then opened = pcall(OpenWorldMap, map) end
    if not opened then
        if not WorldMapFrame:IsShown() then pcall(WorldMapFrame.Show, WorldMapFrame) end
        pcall(WorldMapFrame.SetMapID, WorldMapFrame, map)
    end
end

-- Map a list should be shown on: the player's map if any entry is there, else the most common first map.
local function BestMap(list)
    local count, best, bestN = {}, nil, 0
    local player = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if player then
        for _, b in ipairs(list) do
            for _, m in ipairs(SortedMaps(b)) do
                if m == player then return player end
            end
        end
    end
    for _, b in ipairs(list) do
        local maps = SortedMaps(b)
        local pick = maps[1]
        for _, m in ipairs(maps) do if m == player then pick = m end end
        if pick then
            count[pick] = (count[pick] or 0) + 1
            if count[pick] > bestN then best, bestN = pick, count[pick] end
        end
    end
    return best
end

function PM:OpenFor(list)
    PM.Install()
    local map = BestMap(list)
    if map then OpenMap(map) end
    self:Update()
end

function PM:ShowBeasts(list, openMap)
    local use = {}
    for _, b in ipairs(list) do
        if b.sp and next(b.sp) then use[#use + 1] = b end
    end
    if #use == 0 then
        HHT.Print(#list == 1 and string.format(L("No coordinates known for %s."), list[1].n) or L("Nothing to show."))
        return
    end
    self.list = use
    PM.Install()
    if openMap then OpenMap(BestMap(use)) end
    self:Update()
    if C_Timer and C_Timer.After then C_Timer.After(0.2, function() PM:Update() end) end
end

function PM:SetWaypointAt(map, x, y, name)
    self:ClearWaypoint()
    if TomTom and TomTom.AddWaypoint then
        local ok, uid = pcall(TomTom.AddWaypoint, TomTom, map, x, y, { title = name })
        if ok then self.tomtomUid, self.waypointSet = uid, true end
    end
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local ok = pcall(function()
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        end)
        if not ok then HHT.Print(L("Waypoints are not available on this client.")) return end
        self.waypointSet = true
    end
    HHT.Print(string.format(L("Waypoint set: %s"), string.format("%s (%.1f, %.1f)", name or "?", x * 100, y * 100)))
end

-- Nearest spawn on the player's map, otherwise the first known spawn.
function PM:Waypoint(b)
    local maps = SortedMaps(b)
    if #maps == 0 then
        HHT.Print(string.format(L("No coordinates known for %s."), b.n))
        return
    end
    local player = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local map = maps[1]
    for _, m in ipairs(maps) do if m == player then map = m end end
    local pts = Points(b, map)
    local pick = pts[1]
    if map == player and C_Map.GetPlayerMapPosition then
        local ok, pos = pcall(C_Map.GetPlayerMapPosition, map, "player")
        if ok and pos and pos.GetXY then
            local px, py = pos:GetXY()
            if px and py then
                local bestD
                for _, pt in ipairs(pts) do
                    local d = (pt[1] - px) ^ 2 + (pt[2] - py) ^ 2
                    if not bestD or d < bestD then bestD, pick = d, pt end
                end
            end
        end
    end
    if not pick then
        HHT.Print(string.format(L("No coordinates known for %s."), b.n))
        return
    end
    self:SetWaypointAt(map, pick[1], pick[2], b.n)
end

HHT:AddGerman({
    ["Click: set waypoint"] = "Klick: Wegpunkt setzen",
    ["Waypoints are not available on this client."] = "Wegpunkte sind auf diesem Client nicht verfuegbar.",
})
