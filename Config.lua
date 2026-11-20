-- Settings window: banner, category tabs on top, module list on the left and a scrolling option page.
local ADDON, HHT = ...
local UI = HHT.UI
local L = HHT.L

local C = {}
HHT.Config = C

C.pages = {}
local W, H = 760, 640
local MIN_H = 440
local BANNER, TABS, SIDE_W = 62, 36, 184
local TOP = BANNER + TABS + 12

-- Extra pages besides the modules (shown in the "General" category).
local SPECIAL = {
    general = { name = "General", desc = "Language, colours, look and behaviour of all modules." },
    modules = { name = "Modules", desc = "Switch single modules on or off." },
    support = { name = "Settings & support", desc = "Reset, reload, export your settings and support the addon." },
}

-- Categories: tab label, glyph and the pages listed on the left. Modules not listed here end up in the last one.
local CATS = {
    { id = "general", name = "General", icon = "settings", keys = { "general", "modules", "support" } },
    { id = "combat", name = "Combat", icon = "swords",
      keys = { "swing", "castbar", "cooldowns", "threat", "distance", "procs", "debuffs", "tranq" } },
    { id = "alerts", name = "Alerts & buffs", icon = "bell-ring",
      keys = { "warnings", "aspects", "summons", "raidbuffs", "consumables" } },
    { id = "pets", name = "Pets", icon = "paw-print",
      keys = { "pet", "feeder", "petdex", "petnearby", "easytame", "pettrain", "petwatch", "petguide" } },
    { id = "ammo", name = "Ammo & map", icon = "map",
      keys = { "ammo", "ammovendors", "foodvendors", "stablemasters", "trainers", "mapbutton" } },
    { id = "tools", name = "Tools", icon = "wrench", keys = { "macros" } },
}

-- Glyphs per page: white line icons in Media\Icons (Lucide), tinted at runtime.
local ICONS = {
    general = "sliders-horizontal", modules = "layout-grid", support = "heart",
    swing = "gauge", castbar = "hourglass", cooldowns = "timer-reset", warnings = "triangle-alert", aspects = "bird",
    debuffs = "skull", procs = "zap", summons = "megaphone", raidbuffs = "users", consumables = "flask-round",
    threat = "shield-alert", distance = "ruler", pet = "heart-pulse", feeder = "drumstick", ammo = "crosshair",
    tranq = "moon", macros = "scroll-text", petdex = "book-open", petwatch = "binoculars", petnearby = "radar",
    pettrain = "graduation-cap", ammovendors = "store", stablemasters = "house", foodvendors = "utensils",
    easytame = "crosshair",
    trainers = "book-open-check", mapbutton = "map-pin", petguide = "compass",
}

local function Glyph(tex, name)
    tex:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\Icons\\" .. (name or "settings"))
end

-- Modules shown in demo mode while their settings page is open.
local PREVIEW = {
    swing = true, castbar = true, distance = true, threat = true, warnings = true, debuffs = true, procs = true,
    summons = true, ammo = true, pet = true, feeder = true, petnearby = true, petwatch = true, pettrain = true,
    cooldowns = true, tranq = true, petguide = true, aspects = true, easytame = true,
}

function HHT.CommonOptions(m, form)
    if m.noFrame then
        form:Button(L("Reset this module"), function()
            HHT:ResetModule(m)
            C:InvalidatePage(m.key)
            C:Select(m.key)
        end, 170)
        return
    end
    form:Cycle(L("Show when"), m.db, m.db.visibility ~= nil and "visibility" or "showWhen", HHT.VisibilityChoices(),
        function() HHT:ApplyAllLooks() end)
    form:Check(L("Unlock frame"), m, "moveUnlock", function() HHT:ApplyLock() end)
    form:Button(L("Reset position"), function()
        m.db.pos = nil
        HHT:ApplyAllPositions()
    end, 140)
    form:Inline(300)
    form:Stepper(L("Scale"), m.db, "scale", 0.5, 2, 0.05)
    form:Stepper(L("Opacity"), m.db, "alpha", 0.1, 1, 0.05)
    form:Cycle(L("Text style"), m.db, "textStyle", {
        { "outline", L("Outline") }, { "thick", L("Thick outline") }, { "plain", L("Plain") } })
    form:Button(L("Reset this module"), function()
        HHT:ResetModule(m)
        C:InvalidatePage(m.key)
        C:Select(m.key)
    end, 170)
end

-- ---------------------------------------------------------------------------
-- Pages
-- ---------------------------------------------------------------------------
-- Small popup next to the unlock switch: which modules take part when all frames are unlocked (all by default).
function C:OpenMoveSet(anchor)
    local g = HHT.db.general
    local mods, seen = {}, {}
    for _, f in ipairs(HHT.movables) do
        local m = f.hht and f.hht.module
        if m and m.enabled and not seen[m.key] then
            seen[m.key] = true
            mods[#mods + 1] = m
        end
    end
    local w = self.moveSet
    if not w then
        w = UI.Window("HamingwaysHunterToolsMoveSet", 300, 120, L("Movable modules"))
        w:SetFrameStrata("FULLSCREEN_DIALOG")
        if UISpecialFrames then table.insert(UISpecialFrames, "HamingwaysHunterToolsMoveSet") end
        w.checks = {}
        local function All(on)
            g.moveSkip = {}
            if not on then
                for _, m in ipairs(w.mods) do g.moveSkip[m.key] = true end
            end
            HHT:ApplyLock()
            for _, c in pairs(w.checks) do c:Refresh() end
        end
        w.all = UI.Button(w, 80, 22, L("All"), function() All(true) end)
        w.none = UI.Button(w, 80, 22, L("None"), function() All(false) end)
        self.moveSet = w
    end
    w.mods = mods
    for _, c in pairs(w.checks) do c:Hide() end
    local y = -40
    for _, m in ipairs(mods) do
        local c = w.checks[m.key]
        if not c then
            c = UI.Check(w, L(m.name),
                function() return HHT:InMoveSet(m) end,
                function(v)
                    g.moveSkip = g.moveSkip or {}
                    g.moveSkip[m.key] = (not v) or nil
                    HHT:ApplyLock()
                end)
            w.checks[m.key] = c
        end
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", w, "TOPLEFT", 16, y)
        c:Refresh()
        c:Show()
        y = y - 24
    end
    w.all:ClearAllPoints()
    w.all:SetPoint("TOPLEFT", w, "TOPLEFT", 16, y - 6)
    w.none:ClearAllPoints()
    w.none:SetPoint("LEFT", w.all, "RIGHT", 6, 0)
    w:SetHeight(-y + 40)
    w:ClearAllPoints()
    w:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
    w:Show()
    w:Raise()
end

function C:BuildGeneral(form)
    local g = HHT.db.general
    form:Header(L("Appearance"))
    form:Cycle(L("Language"), g, "lang", {
        { "auto", L("Automatic") }, { "en", "English" }, { "de", "Deutsch" } },
        function() C:Relang() end)
    local themeRow = form:Cycle(L("Colour theme"), g, "theme", {
        { "classic", L("Bronze") }, { "dark", L("Blue") }, { "minimal", L("Graphite") } },
        function() HHT.Print(L("The colour theme applies after /reload.")) end)
    local reload = UI.Button(themeRow, 24, 20, "", function() ReloadUI() end)
    reload:SetPoint("LEFT", themeRow, "LEFT", 366, 0)
    local ricon = reload:CreateTexture(nil, "ARTWORK")
    ricon:SetSize(14, 14)
    ricon:SetPoint("CENTER")
    ricon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    reload:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("Reload UI"))
        GameTooltip:Show()
    end)
    reload:HookScript("OnLeave", function() GameTooltip:Hide() end)
    form:Cycle(L("Style of icons and bars"), g, "style", {
        { "flat", L("Flat") }, { "bevel", L("3D frame") }, { "glass", L("Glass") } },
        function() HHT:RefreshAll(); HHT.Icon.RefreshFinish() end)
    form:Cycle(L("All icons: shape"), HHT.Look, "shape", HHT.ShapeChoices())
    form:Stepper(L("All borders: size (0 = none)"), HHT.Look, "borderSize", 0, 4, 1)
    form:Color(L("All borders: color"), HHT.Look, "borderColor")
    form:Stepper(L("All borders: alpha"), HHT.Look, "borderAlpha", 0, 1, 0.1)
    form:Check(L("Border glow"), g, "borderGlow", function() HHT:RefreshAll(); HHT.Icon.RefreshFinish() end)
    form:Stepper(L("Glow strength"), g, "borderGlowSize", 1, 8, 1, function() HHT:RefreshAll(); HHT.Icon.RefreshFinish() end)
    form:Cycle(L("All bars: texture"), HHT.Look, "barTexture", HHT.Bar.TextureChoices())
    form:Cycle(L("All bars: corners"), HHT.Look, "barShape", HHT.Bar.ShapeChoices())
    form:Stepper(L("3D effect strength"), HHT.Look, "bevel", 0, 1, 0.1)
    form:Stepper(L("Global scale"), g, "scale", 0.5, 2, 0.05, function() HHT:ApplyAllLooks() end)
    form:Stepper(L("Global opacity"), g, "alpha", 0.1, 1, 0.05, function() HHT:ApplyAllLooks() end)
    form:Check(L("Live preview"), g, "preview", function() C:Select(C.current or "general") end)
    form:Button(L("Start quick install"), function() if HHT.Setup then HHT.Setup.Open() end end, 200)

    local unlock = UI.Check(form.content, L("Unlock frames (move with mouse)"),
        function() return g.locked == false end,
        function(v) HHT:SetLocked(not v) end)
    form:Place(unlock, 20, 4, 4)
    form:Name("Unlock frames (move with mouse)")
    local gear = UI.Button(form.content, 24, 20, "", function() C:OpenMoveSet(unlock) end)
    gear:SetPoint("LEFT", unlock, "RIGHT", 8, 0)
    local gicon = gear:CreateTexture(nil, "ARTWORK")
    gicon:SetSize(14, 14)
    gicon:SetPoint("CENTER")
    gicon:SetTexture(UI.ICON_DIR .. "settings")
    gear:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("Choose which modules can be moved"))
        GameTooltip:Show()
    end)
    gear:HookScript("OnLeave", function() GameTooltip:Hide() end)
    form:Check(L("Snap frames to each other while moving"), g, "snap")
    form:Check(L("Show outline on unlocked frames"), g, "outline", function() HHT:ApplyLock() end)
    form:Check(L("Minimap button"), g, "minimap", function() C:UpdateMinimap() end)
    form:Check(L("Tell me about new versions"), g, "versionNotice")
    form:Check(L("Show what's new after an update"), g, "whatsNew")
end

function C:BuildModulesPage(form)
    for _, cat in ipairs(self.cats) do
        local any = false
        for _, key in ipairs(cat.keys) do
            local m = HHT.modules[key]
            if m then
                if not any then form:Header(L(cat.name)); any = true end
                if m.wip then
                    form:Note(L(m.name) .. ": " .. L("WIP - coming soon"), 0.55, 0.52, 0.45)
                else
                    form:Check(L(m.name), m.db, "enabled", function()
                        HHT:SetEnabled(m, m.db.enabled)
                        C:UpdateSidebar()
                    end)
                end
            end
        end
    end
end

function C:BuildSupport(form)
    form:Header(L("Settings"))
    form:Button(L("Reset all positions"), function()
        HHT:EachModule(function(m) m.db.pos = nil end)
        HHT:ApplyAllPositions()
        HHT.Print(L("Positions reset."))
    end, 220)
    form:Button(L("Reload UI"), function() ReloadUI() end, 220)
    form:Button(L("Profiles, export and import"), function() if HHT.Profile then HHT.Profile.Open() end end, 220)

    form:Header(L("Support"))
    form:Note(L("Like the addon? Buy me a coffee. Click the field, press Ctrl+C and paste the link into your browser."))
    local url = "https://buymeacoffee.com/x1ndlmeister"
    local box = UI.EditBox(form.content, 300, nil)
    box:SetText(url)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnTextChanged", function(self, user) if user then self:SetText(url); self:HighlightText() end end)
    form:Place(box, 20, 4, 6)

    form:Header(L("Bug report"))
    form:Note(L("Something not working? Create a report and paste the line into your bug report. It holds settings and debug data, no character name."))
    form:Button(L("Create bug report"), function() if HHT.Report then HHT.Report.Open() end end, 220)

    form:Note("v" .. HHT.version .. "  |  /hht  |  /hht unlock  |  /hht lock  |  /hht reset  |  /hht report", 0.55, 0.52, 0.45)
end

local function PageName(key)
    local sp, m = SPECIAL[key], HHT.modules[key]
    local name = sp and L(sp.name) or L(m.name)
    if m and m.wip then name = name .. " (WIP)" end
    return name
end

function C:BuildPage(key)
    local parent = CreateFrame("Frame", nil, self.content)
    parent:SetAllPoints(self.content)
    local sp, m = SPECIAL[key], HHT.modules[key]
    local P = UI.PAL

    local D = HHT.Dwarf
    local line = (key == "support" or (m and not m.wip)) and D and D.LINES[key]
    local headH, switch
    if line then
        -- The dwarf introduces the page instead of a title; a module's on/off switch sits beside him.
        local dw = D.New(parent, m and 408 or 532 - 8, nil, 72)
        dw:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -2)
        dw:Say(D.Pick(line))
        headH = math.ceil(dw:GetHeight()) + 6
        if m then
            switch = UI.Switch(parent, function() return m.db.enabled end, function(v)
                m.db.enabled = v and true or false
                HHT:SetEnabled(m, m.db.enabled)
                C:UpdateSidebar()
            end)
            switch:SetPoint("CENTER", parent, "TOPRIGHT", -66, -(headH / 2) - 9)
            local sl = UI.Text(parent, L("Module enabled"), 12, 0.85, 0.85, 0.85)
            sl:SetPoint("BOTTOM", switch, "TOP", 0, 5)
        end
    else
        local tile = CreateFrame("Frame", nil, parent)
        tile:SetSize(40, 40)
        tile:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
        UI.Round(tile, 10, P.head[1], P.head[2], P.head[3], 0.16, "BACKGROUND")
        UI.RoundBorder(tile, 10, P.head[1], P.head[2], P.head[3], 0.4)
        local icon = tile:CreateTexture(nil, "ARTWORK")
        icon:SetSize(26, 26)
        icon:SetPoint("CENTER", tile, "CENTER", 0, 0)
        Glyph(icon, ICONS[key])
        icon:SetVertexColor(P.head[1], P.head[2], P.head[3])
        local title = UI.Text(parent, PageName(key), 18, 1, 1, 1)
        title:SetPoint("TOPLEFT", parent, "TOPLEFT", 54, -4)
        local desc = UI.Text(parent, sp and L(sp.desc) or L(m.desc), 11, 0.68, 0.65, 0.58)
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        desc:SetWidth(m and not m.wip and 300 or 450)
        desc:SetJustifyH("LEFT")
        desc:SetWordWrap(true)
        headH = math.max(50, 32 + desc:GetStringHeight() + 8)
        if m and not m.wip then
            switch = UI.Switch(parent, function() return m.db.enabled end, function(v)
                m.db.enabled = v and true or false
                HHT:SetEnabled(m, m.db.enabled)
                C:UpdateSidebar()
            end)
            switch:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, -10)
            local sl = UI.Text(parent, L("Module enabled"), 12, 0.85, 0.85, 0.85)
            sl:SetPoint("RIGHT", switch, "LEFT", -8, 0)
        end
    end
    local rule = UI.FadeLine(parent, P.head[1], P.head[2], P.head[3], 0.5)
    rule:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -headH)
    rule:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -headH)

    local body = CreateFrame("Frame", nil, parent)
    body:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(headH + 6))
    body:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    local form
    if key == "general" or key == "modules" or key == "support" then
        form = UI.NewForm(body, nil, key)
        if key == "general" then
            self:BuildGeneral(form)
            form:ApplyLayout(HHT.Layout and HHT.Layout.general, HHT.Tips)
        elseif key == "modules" then self:BuildModulesPage(form)
        else self:BuildSupport(form) end
    else
        form = UI.NewForm(body, function() HHT:RefreshModule(m) end, key)
        if m.wip then
            form:Header(L("WIP - coming soon"))
            form:Note(L("This module is not available yet and cannot be enabled."))
        else
            HHT.CommonOptions(m, form)
            if m.BuildOptions then m:BuildOptions(form) end
            form:ApplyLayout(HHT.Layout and HHT.Layout[key], HHT.Tips)
        end
    end
    local page = { frame = parent, form = form }
    function page.Refresh()
        form:Refresh()
        if switch then switch:Refresh() end
    end
    self.pages[key] = page
    return page
end

function C:InvalidatePage(key)
    local p = self.pages[key]
    if p then p.frame:Hide(); self.pages[key] = nil end
end

function C:Select(key)
    local cat = self.catOf and self.catOf[key]
    if cat and self.cat ~= cat then self:ShowCategory(cat) end
    if cat then self.lastKey[cat] = key end
    self.current = key
    for k, p in pairs(self.pages) do
        if k ~= key then p.frame:Hide() end
    end
    local page = self.pages[key] or self:BuildPage(key)
    page.frame:Show()
    page.Refresh()
    self:UpdateSidebar()
    local open = self.window and self.window:IsShown()
    HHT:SetPreview(open and PREVIEW[key] and HHT.db.general.preview ~= false and HHT.modules[key] or nil)
end

function C:UpdateSidebar()
    if not self.side then return end
    local a = UI.ACCENT
    for key, b in pairs(self.side) do
        local m = HHT.modules[key]
        local on = true
        if m then on = m.db.enabled and not m.wip end
        b:SetLabel(PageName(key))
        if key == self.current then
            b.label:SetTextColor(1, 1, 1)
        elseif on then
            b.label:SetTextColor(0.82, 0.84, 0.88)
        else
            b.label:SetTextColor(0.45, 0.43, 0.40)
        end
        b.icon:SetVertexColor(on and a[1] or 0.4, on and a[2] or 0.4, on and a[3] or 0.4)
        b.icon:SetAlpha(on and 1 or 0.6)
        b.dot:SetShown(m ~= nil)
        b.dot:SetVertexColor(on and a[1] or 0.35, on and a[2] or 0.33, on and a[3] or 0.3, on and 0.9 or 0.8)
        b:SetSelected(key == self.current)
    end
    for id, t in pairs(self.tabs) do
        local sel = id == self.cat
        t.label:SetTextColor(sel and 1 or 0.72, sel and 1 or 0.72, sel and 1 or 0.72)
        t.icon:SetVertexColor(sel and a[1] or 0.7, sel and a[2] or 0.7, sel and a[3] or 0.7)
        t.icon:SetAlpha(sel and 1 or 0.8)
        t.glow:SetShown(sel)
        t.line:SetShown(sel)
    end
end

function C:Relang()
    for k, p in pairs(self.pages) do p.frame:Hide(); self.pages[k] = nil end
    HHT:RefreshAll()
    if self.window then
        self:LayoutTabs()
        self:Select(self.current or "general")
    end
end

-- Places the category tabs left to right; widths follow the (translated) labels.
function C:LayoutTabs()
    local x = 12
    for _, cat in ipairs(self.cats) do
        local t = self.tabs[cat.id]
        t.label:SetText(L(cat.name))
        t:SetWidth(12 + 18 + 7 + t.label:GetStringWidth() + 16)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", self.tabBar, "TOPLEFT", x, 0)
        x = x + t:GetWidth() + 2
    end
end

function C:ShowCategory(id)
    self.cat = id
    local cat = self.catById[id]
    for _, b in pairs(self.side) do b:Hide() end
    for i, key in ipairs(cat.keys) do
        local b = self.side[key]
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", self.sideList, "TOPLEFT", 4, -6 - (i - 1) * 32)
        b:Show()
    end
    self.sideList:SetHeight(12 + #cat.keys * 32)
    self.sideScroll:SetVerticalScroll(0)
    self.sideThumb()
end

function C:BuildCats()
    self.cats, self.catById, self.catOf, self.lastKey = {}, {}, {}, {}
    for _, def in ipairs(CATS) do
        local cat = { id = def.id, name = def.name, icon = def.icon, keys = {} }
        for _, key in ipairs(def.keys) do
            if SPECIAL[key] or HHT.modules[key] then
                cat.keys[#cat.keys + 1] = key
                self.catOf[key] = cat.id
            end
        end
        self.cats[#self.cats + 1] = cat
        self.catById[cat.id] = cat
    end
    local last = self.cats[#self.cats]
    for _, key in ipairs(HHT.moduleList) do
        if not self.catOf[key] then
            last.keys[#last.keys + 1] = key
            self.catOf[key] = last.id
        end
    end
end

function C:Create()
    if self.window then return end
    local w = UI.Window("HamingwaysHunterToolsConfig", W, H, "Hamingway's HunterTools", BANNER)
    local saved = tonumber(HHT.db.general.menuScale)
    if saved then w:SetScale(math.min(1.6, math.max(0.6, saved))) end
    local savedH = tonumber(HHT.db.general.menuH)
    if savedH then w:SetHeight(math.max(MIN_H, savedH)) end
    w:SetPoint("CENTER")
    local pos = HHT.db.general.menuPos
    if pos then
        w:ClearAllPoints()
        w:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    end
    w:HookScript("OnDragStop", function(self)
        local p, _, rp, x, y = self:GetPoint()
        HHT.db.general.menuPos = { p, rp, x, y }
    end)
    w:Hide()
    self.window = w
    w:HookScript("OnShow", function() HHT.db.general.menuOpen = true end)
    w:HookScript("OnHide", function()
        HHT.db.general.menuOpen = false
        HHT:SetPreview(nil)
    end)
    self:BuildCats()
    local logoHolder = CreateFrame("Frame", nil, w)
    logoHolder:SetSize(56, 56)
    logoHolder:SetPoint("TOPLEFT", w, "TOPLEFT", 12, -3)
    logoHolder:SetFrameLevel(w:GetFrameLevel() + 20)
    local logo = logoHolder:CreateTexture(nil, "OVERLAY")
    logo:SetAllPoints()
    logo:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\HHT_Logo")
    w.title:SetFont(UI.FONT, 20, "")
    w.title:ClearAllPoints()
    w.title:SetPoint("TOPLEFT", w, "TOPLEFT", 78, -13)
    local sub = UI.Text(w, L("Your toolbox for WoW Forever hunters"), 11, 1, 1, 1)
    sub:SetAlpha(0.7)
    sub:SetPoint("TOPLEFT", w.title, "BOTTOMLEFT", 1, -4)
    local pill = CreateFrame("Frame", nil, w)
    local ver = UI.Text(pill, "v" .. HHT.version, 11, 1, 1, 1)
    pill:SetSize(ver:GetStringWidth() + 16, 18)
    pill:SetPoint("LEFT", w.title, "RIGHT", 10, -1)
    ver:SetPoint("CENTER", pill, "CENTER", 0, 0)
    UI.Round(pill, 7, 0, 0, 0, 0.35, "BACKGROUND")
    w.close:ClearAllPoints()
    w.close:SetPoint("TOPRIGHT", w, "TOPRIGHT", -10, -10)
    if UISpecialFrames then table.insert(UISpecialFrames, "HamingwaysHunterToolsConfig") end

    -- grip in the bottom-right corner: drag to scale the window, right-click resets
    UI.ScaleGrip(w, function()
        local g = HHT.db.general
        g.menuScale = w:GetScale()
        local p, _, rp, x, y = w:GetPoint()
        g.menuPos = { p, rp, x, y }
    end)
    UI.HeightGrip(w, MIN_H, function(h)
        local g = HHT.db.general
        g.menuH = h
        local p, _, rp, x, y = w:GetPoint()
        g.menuPos = { p, rp, x, y }
    end)

    -- category tabs
    local tabBar = CreateFrame("Frame", nil, w)
    tabBar:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(BANNER + 2))
    tabBar:SetPoint("TOPRIGHT", w, "TOPRIGHT", 0, -(BANNER + 2))
    tabBar:SetHeight(TABS)
    self.tabBar, self.tabs = tabBar, {}
    local a = UI.ACCENT
    for _, cat in ipairs(self.cats) do
        local t = CreateFrame("Button", nil, tabBar)
        t:SetHeight(TABS)
        t.glow = t:CreateTexture(nil, "BACKGROUND")
        t.glow:SetAllPoints()
        UI.Gradient(t.glow, true, a[1], a[2], a[3], 0.22, 0)
        t.glow:Hide()
        local hl = t:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        UI.Gradient(hl, true, 1, 1, 1, 0.07, 0)
        t.line = t:CreateTexture(nil, "ARTWORK")
        t.line:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 6, 0)
        t.line:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -6, 0)
        t.line:SetHeight(2)
        UI.Tint(t.line, a, 1)
        t.line:Hide()
        t.icon = t:CreateTexture(nil, "ARTWORK")
        t.icon:SetSize(18, 18)
        t.icon:SetPoint("LEFT", t, "LEFT", 12, 0)
        Glyph(t.icon, cat.icon)
        t.label = UI.Text(t, "", 13)
        t.label:SetPoint("LEFT", t, "LEFT", 37, 0)
        local id = cat.id
        t:SetScript("OnClick", function() C:Select(C.lastKey[id] or C.catById[id].keys[1]) end)
        self.tabs[cat.id] = t
    end
    local tabRule = UI.FadeLine(w, UI.PAL.head[1], UI.PAL.head[2], UI.PAL.head[3], 0.55)
    tabRule:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -(BANNER + TABS + 2))
    tabRule:SetPoint("TOPRIGHT", w, "TOPRIGHT", -10, -(BANNER + TABS + 2))

    local side = CreateFrame("Frame", nil, w)
    side:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -TOP)
    side:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 10, 12)
    side:SetWidth(SIDE_W)
    local divider = w:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", w, "TOPLEFT", 10 + SIDE_W + 8, -TOP)
    divider:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 10 + SIDE_W + 8, 12)
    UI.Gradient(divider, true, UI.PAL.head[1], UI.PAL.head[2], UI.PAL.head[3], 0, 0.35)

    self.content = CreateFrame("Frame", nil, w)
    self.content:SetPoint("TOPLEFT", w, "TOPLEFT", 10 + SIDE_W + 20, -TOP)
    self.content:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -14, 12)

    self.side = {}
    local sf = CreateFrame("ScrollFrame", nil, side)
    sf:SetPoint("TOPLEFT", side, "TOPLEFT", 0, 0)
    sf:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", 0, 0)
    local list = CreateFrame("Frame", nil, sf)
    list:SetSize(SIDE_W, 100)
    sf:SetScrollChild(list)
    local UpdateThumb = UI.ScrollBar(sf, list, 6, 60)
    self.sideList, self.sideScroll, self.sideThumb = list, sf, UpdateThumb

    for _, cat in ipairs(self.cats) do
        for _, key in ipairs(cat.keys) do
            local b = CreateFrame("Button", nil, list)
            b:SetSize(SIDE_W - 8, 30)
            UI.Selectable(b)
            b.icon = b:CreateTexture(nil, "ARTWORK")
            b.icon:SetSize(18, 18)
            b.icon:SetPoint("LEFT", b, "LEFT", 11, 0)
            Glyph(b.icon, ICONS[key])
            b.label = UI.Text(b, "", 12)
            b.label:SetPoint("LEFT", b, "LEFT", 38, 0)
            b.label:SetWidth(SIDE_W - 8 - 38 - 22)
            b.label:SetJustifyH("LEFT")
            b.label:SetWordWrap(false)
            b.dot = b:CreateTexture(nil, "ARTWORK")
            b.dot:SetTexture(UI.TEX_CIRCLE)
            b.dot:SetSize(7, 7)
            b.dot:SetPoint("RIGHT", b, "RIGHT", -10, 0)
            function b:SetLabel(t) self.label:SetText(t) end
            b:SetScript("OnClick", function() C:Select(key) end)
            b:Hide()
            self.side[key] = b
        end
    end
    self:LayoutTabs()
    self:ShowCategory("general")
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

-- Pulses a glow ring around the minimap button (used by the quick install to point at it).
function C:FlashMinimap(on)
    local b = self.minimap
    if not b then return end
    if not b.glow then
        local glow = b:CreateTexture(nil, "OVERLAY")
        glow:SetPoint("CENTER")
        glow:SetSize(52, 52)
        glow:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\RoundMask")
        glow:SetBlendMode("ADD")
        glow:SetVertexColor(0.67, 0.83, 0.45)
        glow:Hide()
        b.glow = glow
    end
    if on and b:IsShown() then
        local t = 0
        b.glow:Show()
        b:SetScript("OnUpdate", function(self, dt)
            t = t + dt
            self.glow:SetAlpha(0.25 + 0.55 * (0.5 + 0.5 * math.sin(t * 5)))
        end)
    else
        b.glow:Hide()
        b:SetScript("OnUpdate", nil)
    end
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
        if IsShiftKeyDown() then
            if button == "RightButton" then
                HHT:SetLocked(not HHT.db.general.locked)
                C:Refresh()
            elseif HHT.PetDex then
                HHT.PetDex:Toggle()
            end
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
        GameTooltip:AddLine(L("Left or right click: settings."), 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine(L("Shift + left click: pet database."), 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine(L("Shift + right click: lock/unlock all frames."), 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.minimap = b
    self:UpdateMinimap()
end

function C:Refresh()
    if self.window and self.window:IsShown() and self.pages[self.current] then
        self.pages[self.current].Refresh()
    end
end

function C:Init()
    self:BuildMinimap()
    -- Reopen the settings window after a UI reload if it was open before.
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self, _, _, isReload)
        self:UnregisterAllEvents()
        if isReload and HHT.db.general.menuOpen then C:Toggle() end
    end)
end
