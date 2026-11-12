-- Settings window: sidebar (General + one entry per module) and a scrolling option page.
local ADDON, HHT = ...
local UI = HHT.UI
local L = HHT.L

local C = {}
HHT.Config = C

C.pages = {}
local W, H = 610, 620

function HHT.CommonOptions(m, form)
    if m.noFrame then
        form:Button(L("Reset this module"), function()
            HHT:ResetModule(m)
            C:InvalidatePage(m.key)
            C:Select(m.key)
        end, 170)
        return
    end
    form:Header(L("Position"))
    form:Stepper(L("Scale"), m.db, "scale", 0.5, 2, 0.05)
    form:Stepper(L("Opacity"), m.db, "alpha", 0.1, 1, 0.05)
    form:Check(L("Show only in combat"), m.db, "onlyCombat", function() HHT:ApplyAllLooks() end)
    form:Button(L("Reset position"), function()
        m.db.pos = nil
        HHT:ApplyAllPositions()
    end, 170)
    form:Button(L("Reset this module"), function()
        HHT:ResetModule(m)
        C:InvalidatePage(m.key)
        C:Select(m.key)
    end, 170)
end

-- ---------------------------------------------------------------------------
-- Pages
-- ---------------------------------------------------------------------------
function C:BuildGeneral(form)
    local g = HHT.db.general
    form:Header(L("General"))
    form:Cycle(L("Language"), g, "lang", {
        { "auto", L("Automatic") }, { "en", "English" }, { "de", "Deutsch" } },
        function() C:Relang() end)

    local unlock = UI.Check(form.content, L("Unlock frames (move with mouse)"),
        function() return g.locked == false end,
        function(v) HHT:SetLocked(not v) end)
    form:Place(unlock, 20, 4, 4)
    form:Check(L("Show outline on unlocked frames"), g, "outline", function() HHT:ApplyLock() end)
    form:Check(L("Minimap button"), g, "minimap", function() C:UpdateMinimap() end)
    form:Stepper(L("Global scale"), g, "scale", 0.5, 2, 0.05, function() HHT:ApplyAllLooks() end)
    form:Stepper(L("Global opacity"), g, "alpha", 0.1, 1, 0.05, function() HHT:ApplyAllLooks() end)

    form:Header(L("Modules"))
    HHT:EachModule(function(m)
        form:Check(L(m.name), m.db, "enabled", function()
            HHT:SetEnabled(m, m.db.enabled)
            C:UpdateSidebar()
        end)
    end)

    form:Header(L("Settings"))
    form:Button(L("Reset all positions"), function()
        HHT:EachModule(function(m) m.db.pos = nil end)
        HHT:ApplyAllPositions()
        HHT.Print(L("Positions reset."))
    end, 220)
    form:Button(L("Reload UI"), function() ReloadUI() end, 220)
    form:Button(L("Export / import settings"), function() if HHT.Profile then HHT.Profile.Open() end end, 220)

    form:Header(L("Support"))
    form:Note(L("Like the addon? Buy me a coffee. Click the field, press Ctrl+C and paste the link into your browser."))
    local url = "https://buymeacoffee.com/x1ndlmeister"
    local box = UI.EditBox(form.content, 300, nil)
    box:SetText(url)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnTextChanged", function(self, user) if user then self:SetText(url); self:HighlightText() end end)
    form:Place(box, 20, 4, 6)

    form:Note("v" .. HHT.version .. "  |  /hht  |  /hht unlock  |  /hht lock  |  /hht reset", 0.55, 0.52, 0.45)
end

function C:BuildPage(key)
    local parent = CreateFrame("Frame", nil, self.content)
    parent:SetAllPoints(self.content)
    local form
    if key == "general" then
        form = UI.NewForm(parent)
        self:BuildGeneral(form)
    else
        local m = HHT.modules[key]
        form = UI.NewForm(parent, function() HHT:RefreshModule(m) end)
        form:Header(L(m.name))
        form:Note(L(m.desc))
        form:Check(L("Module enabled"), m.db, "enabled", function()
            HHT:SetEnabled(m, m.db.enabled)
            C:UpdateSidebar()
        end)
        HHT.CommonOptions(m, form)
        if m.BuildOptions then m:BuildOptions(form) end
    end
    local page = { frame = parent, form = form }
    self.pages[key] = page
    return page
end

function C:InvalidatePage(key)
    local p = self.pages[key]
    if p then p.frame:Hide(); self.pages[key] = nil end
end

function C:Select(key)
    self.current = key
    for k, p in pairs(self.pages) do
        if k ~= key then p.frame:Hide() end
    end
    local page = self.pages[key] or self:BuildPage(key)
    page.frame:Show()
    page.form:Refresh()
    self:UpdateSidebar()
end

function C:UpdateSidebar()
    if not self.side then return end
    local a = UI.ACCENT
    for key, b in pairs(self.side) do
        local on = true
        local label
        if key == "general" then
            label = L("General")
        else
            local m = HHT.modules[key]
            on = m.db.enabled
            label = L(m.name)
        end
        b:SetLabel(label)
        if key == self.current then
            b.label:SetTextColor(a[1], a[2], a[3])
        elseif on then
            b.label:SetTextColor(0.92, 0.94, 0.97)
        else
            b.label:SetTextColor(0.45, 0.43, 0.40)
        end
        b.sel:SetShown(key == self.current)
    end
end

function C:Relang()
    for k, p in pairs(self.pages) do p.frame:Hide(); self.pages[k] = nil end
    HHT:RefreshAll()
    if self.window then
        self.window.title:SetText("Hamingway's HunterTools  v" .. HHT.version)
        self:Select(self.current or "general")
    end
end

function C:Create()
    if self.window then return end
    local w = UI.Window("HamingwaysHunterToolsConfig", W, H, "Hamingway's HunterTools  v" .. HHT.version)
    w:SetPoint("CENTER")
    w:Hide()
    self.window = w
    if UISpecialFrames then table.insert(UISpecialFrames, "HamingwaysHunterToolsConfig") end

    local side = CreateFrame("Frame", nil, w)
    side:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -40)
    side:SetSize(140, H - 52)
    local sbg = side:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints()
    sbg:SetColorTexture(0.05, 0.045, 0.035, 0.9)

    self.content = CreateFrame("Frame", nil, w)
    self.content:SetPoint("TOPLEFT", w, "TOPLEFT", 162, -40)
    self.content:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -12, 12)

    self.side = {}
    local keys = { "general" }
    for _, k in ipairs(HHT.moduleList) do keys[#keys + 1] = k end

    local sf = CreateFrame("ScrollFrame", nil, side)
    sf:SetPoint("TOPLEFT", side, "TOPLEFT", 0, 0)
    sf:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", 0, 0)
    local list = CreateFrame("Frame", nil, sf)
    list:SetSize(140, 10 + #keys * 30)
    sf:SetScrollChild(list)
    sf:EnableMouseWheel(true)
    local thumb = sf:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(3)
    thumb:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.45)
    local function UpdateThumb()
        local viewH, contentH = sf:GetHeight(), list:GetHeight()
        if contentH <= viewH + 1 then thumb:Hide(); return end
        local h = math.max(20, viewH * viewH / contentH)
        thumb:SetHeight(h)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPRIGHT", sf, "TOPRIGHT", -1, -((viewH - h) * (sf:GetVerticalScroll() / (contentH - viewH))))
        thumb:Show()
    end
    sf:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, list:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.min(range, math.max(0, self:GetVerticalScroll() - delta * 60)))
        UpdateThumb()
    end)
    sf:SetScript("OnSizeChanged", UpdateThumb)
    UpdateThumb()

    for i, key in ipairs(keys) do
        local b = UI.Button(list, 130, 26, "", function() C:Select(key) end)
        b:SetPoint("TOPLEFT", list, "TOPLEFT", 5, -5 - (i - 1) * 30)
        b.sel = b:CreateTexture(nil, "ARTWORK")
        b.sel:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
        b.sel:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
        b.sel:SetWidth(3)
        b.sel:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 1)
        b.sel:Hide()
        self.side[key] = b
    end
    self.current = "general"
end

function C:Toggle()
    self:Create()
    if self.window:IsShown() then
        self.window:Hide()
    else
        self.window:Show()
        self:Select(self.current or "general")
    end
end

-- ---------------------------------------------------------------------------
-- Minimap button
-- ---------------------------------------------------------------------------
function C:UpdateMinimap()
    local btn = self.minimap
    if not btn then return end
    local g = HHT.db.general
    btn:SetShown(g.minimap and true or false)
    local rad = math.rad(g.minimapAngle or 215)
    local r = Minimap:GetWidth() / 2 + 5
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * r, math.sin(rad) * r)
end

function C:BuildMinimap()
    if self.minimap or not Minimap then return end
    local b = CreateFrame("Button", "HamingwaysHunterToolsMinimap", Minimap)
    b:SetSize(32, 32)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\HHT_Logo")
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\RoundMask")
    hl:SetBlendMode("ADD")
    hl:SetVertexColor(1, 1, 1, 0.25)
    b:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            HHT:SetLocked(not HHT.db.general.locked)
            C:Refresh()
        elseif IsShiftKeyDown() and HHT.PetDex then
            HHT.PetDex:Toggle()
        else
            C:Toggle()
        end
    end)
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local s = Minimap:GetEffectiveScale()
            HHT.db.general.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
            C:UpdateMinimap()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Hamingway's HunterTools", 0.67, 0.83, 0.45)
        GameTooltip:AddLine(L("Left click: settings. Right click: lock/unlock frames."), 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine(L("Shift + left click: pet database."), 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.minimap = b
    self:UpdateMinimap()
end

function C:Refresh()
    if self.window and self.window:IsShown() and self.pages[self.current] then
        self.pages[self.current].form:Refresh()
    end
end

function C:Init()
    self:BuildMinimap()
end
