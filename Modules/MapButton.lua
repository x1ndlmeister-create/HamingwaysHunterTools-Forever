-- Map button: a small button on the world map that opens a list of the hunter map layers.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Map button"] = "Kartenknopf",
    ["A button at the top left of the world map with switches for ammo vendors, stable masters and more."] = "Ein Knopf links oben an der Weltkarte mit Schaltern fuer Munitionshaendler, Stallmeister und mehr.",
    ["Hunter map"] = "Jaeger-Karte",
    ["Click to show or hide hunter things on the map."] = "Klick: Jaeger-Dinge auf der Karte ein- oder ausblenden.",
})

local M = HHT:NewModule("mapbutton", {
    name = "Map button",
    desc = "A button at the top left of the world map with switches for ammo vendors, stable masters and more.",
    noFrame = true,
})

local LOGO = "Interface\\AddOns\\" .. ADDON .. "\\Media\\HHT_Logo"
local MASK = "Interface\\AddOns\\" .. ADDON .. "\\Media\\RoundMask"
local ROW_H = 22
local btn, menu

local function PM() return HHT.PetMap end

-- Sit right under the lowest button other addons put in the top left corner of the map.
local function Place()
    local wm = WorldMapFrame
    local canvas = type(wm.ScrollContainer) == "table" and wm.ScrollContainer or wm
    local cl, ct = canvas:GetLeft(), canvas:GetTop()
    btn:ClearAllPoints()
    local best
    if cl and ct then
        local function check(f)
            if f == btn or type(f) ~= "table" or not (f.IsShown and f:IsShown() and f.GetLeft and f.GetTop) then return end
            local l, t = f:GetLeft(), f:GetTop()
            local w, h = f:GetWidth() or 0, f:GetHeight() or 0
            if not (l and t) or w < 12 or w > 60 or h < 12 or h > 60 then return end
            if math.abs(l - cl) < 50 and ct - t > -12 and ct - t < 260 and (not best or f:GetBottom() < best:GetBottom()) then best = f end
        end
        for _, f in ipairs(wm.overlayFrames or {}) do check(f) end
        for _, f in ipairs({ wm:GetChildren() }) do check(f) end
        if canvas ~= wm then for _, f in ipairs({ canvas:GetChildren() }) do check(f) end end
    end
    if best then
        local size = math.floor(math.min(best:GetWidth(), best:GetHeight()) * 0.9 + 0.5)
        btn:SetSize(size, size)
        btn:SetPoint("TOP", best, "BOTTOM", 2, -3)
    else
        btn:SetSize(28, 28)
        btn:SetPoint("TOPLEFT", canvas, "TOPLEFT", 8, -8)
    end
end

local function PaintMenu()
    for _, row in ipairs(menu.rows) do row:Refresh() end
end

local function BuildMenu()
    menu = CreateFrame("Frame", "HamingwaysHunterToolsMapMenu", UIParent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(20)
    menu:EnableMouse(true)
    menu:Hide()
    local bg = menu:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.09, 0.07, 0.94)
    UI.Border(menu, 1, 1, 1, 0.15)
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(1)
    catcher:RegisterForClicks("AnyUp")
    catcher:Hide()
    catcher:SetScript("OnClick", function() menu:Hide() end)
    menu:SetScript("OnShow", function() catcher:Show() end)
    menu:SetScript("OnHide", function() catcher:Hide() end)
    if UISpecialFrames then table.insert(UISpecialFrames, "HamingwaysHunterToolsMapMenu") end
    local title = UI.Header(menu, L("Hunter map"))
    title:SetPoint("TOPLEFT", 10, -8)
    menu.rows = {}
    local y, w = -28, math.max(170, title:GetStringWidth() + 20)
    for _, def in ipairs(PM().layerDefs) do
        local row = UI.Check(menu, L(def.label), function() return def.get() end, function(v)
            def.set(v)
            local ok, err = pcall(PM().Update, PM())
            if not ok then HHT.Print("map layer: " .. tostring(err)) end
        end)
        row:SetFrameLevel(menu:GetFrameLevel() + 5)
        row:EnableMouse(true)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, y)
        row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -10, y)
        y = y - ROW_H
        menu.rows[#menu.rows + 1] = row
    end
    menu:SetSize(w, -y + 8)
end

local function OpenMenu(anchor)
    if not menu then BuildMenu() end
    if menu:IsShown() then menu:Hide(); return end
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, 0)
    PaintMenu()
    menu:Show()
end

local function Build()
    if btn or not WorldMapFrame then return end
    local parent = type(WorldMapFrame.ScrollContainer) == "table" and WorldMapFrame.ScrollContainer or WorldMapFrame
    btn = CreateFrame("Button", nil, parent)
    btn:SetSize(28, 28)
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(510)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexture(LOGO)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture(MASK)
    hl:SetBlendMode("ADD")
    hl:SetVertexColor(1, 1, 1, 0.25)
    btn:SetScript("OnClick", OpenMenu)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Hamingway's HunterTools", 0.67, 0.83, 0.45)
        GameTooltip:AddLine(L("Click to show or hide hunter things on the map."), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pcall(WorldMapFrame.HookScript, WorldMapFrame, "OnShow", function()
        if btn and btn:IsShown() then
            Place()
            if C_Timer and C_Timer.After then C_Timer.After(0.3, function() if btn:IsShown() then Place() end end) end
        end
    end)
    if WorldMapFrame:IsShown() then Place() end
    M.btn = btn
end

function M:TryBuild()
    if btn then return end
    if PM() and PM().Install() then Build() end
end

function M:OnInit()
    HHT:Listen(self, "PLAYER_ENTERING_WORLD", "TryBuild")
end

function M:OnEnable()
    self:TryBuild()
    if btn then btn:Show(); Place() end
end

function M:OnDisable()
    if btn then btn:Hide() end
    if menu then menu:Hide() end
end
