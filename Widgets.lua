-- Template-free widgets (plain frames, textures and font strings only).
local ADDON, HHT = ...

local UI = {}
HHT.UI = UI

local FONT = "Fonts\\ARIALN.TTF"
UI.FONT = FONT
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Colour themes of the settings window and popups. UI.PAL is filled in place, so references stay valid.
local THEMES = {
    classic = {
        accent = { 0.67, 0.83, 0.45 }, bg = { 0.075, 0.068, 0.055, 0.97 }, panel = { 0.075, 0.068, 0.055, 0.96 },
        inset = { 0.03, 0.028, 0.024, 1 }, side = { 0.05, 0.045, 0.035, 0.9 }, titleBar = { 0.13, 0.105, 0.07, 1 },
        border = { 0.55, 0.42, 0.2, 0.9 }, button = { 0.17, 0.145, 0.105, 1 }, box = { 0.09, 0.08, 0.065, 1 },
        field = { 0.045, 0.04, 0.032, 0.95 }, menu = { 0.07, 0.06, 0.05, 0.99 }, hdrLine = { 0.55, 0.42, 0.2, 0.6 },
    },
    dark = {
        accent = { 0.45, 0.78, 0.95 }, bg = { 0.05, 0.057, 0.075, 0.97 }, panel = { 0.05, 0.057, 0.075, 0.96 },
        inset = { 0.025, 0.03, 0.042, 1 }, side = { 0.035, 0.04, 0.055, 0.9 }, titleBar = { 0.085, 0.1, 0.135, 1 },
        border = { 0.25, 0.31, 0.44, 0.9 }, button = { 0.115, 0.135, 0.18, 1 }, box = { 0.06, 0.07, 0.095, 1 },
        field = { 0.03, 0.035, 0.05, 0.95 }, menu = { 0.045, 0.052, 0.07, 0.99 }, hdrLine = { 0.25, 0.31, 0.44, 0.6 },
    },
    minimal = {
        accent = { 0.67, 0.83, 0.45 }, bg = { 0.04, 0.04, 0.04, 0.97 }, panel = { 0.04, 0.04, 0.04, 0.96 },
        inset = { 0.015, 0.015, 0.015, 1 }, side = { 0.028, 0.028, 0.028, 0.9 }, titleBar = { 0.085, 0.085, 0.085, 1 },
        border = { 0.3, 0.3, 0.3, 0.9 }, button = { 0.135, 0.135, 0.135, 1 }, box = { 0.07, 0.07, 0.07, 1 },
        field = { 0.02, 0.02, 0.02, 0.95 }, menu = { 0.035, 0.035, 0.035, 0.99 }, hdrLine = { 0.3, 0.3, 0.3, 0.6 },
    },
}
UI.ThemeList = { "classic", "dark", "minimal" }

UI.PAL = {}
function UI.ApplyTheme(name)
    local t = THEMES[name] or THEMES.classic
    for k, v in pairs(t) do
        local dst = UI.PAL[k]
        if not dst then dst = {}; UI.PAL[k] = dst end
        for i = 1, #v do dst[i] = v[i] end
    end
end
UI.ApplyTheme("classic")
UI.ACCENT = UI.PAL.accent

local function Tint(tex, c, a)
    tex:SetColorTexture(c[1], c[2], c[3], a or c[4] or 1)
end
UI.Tint = Tint

function UI.Anim()
    local g = HHT.db and HHT.db.general
    return not (g and g.animations == false)
end

-- One-colour alpha gradient. a1 = bottom (or left), a2 = top (or right).
function UI.Gradient(tex, vertical, r, g, b, a1, a2)
    tex:SetTexture(WHITE)
    local o = vertical and "VERTICAL" or "HORIZONTAL"
    if tex.SetGradient and CreateColor then
        if pcall(tex.SetGradient, tex, o, CreateColor(r, g, b, a1), CreateColor(r, g, b, a2)) then return end
    end
    if tex.SetGradientAlpha and pcall(tex.SetGradientAlpha, tex, o, r, g, b, a1, r, g, b, a2) then return end
    tex:SetVertexColor(r, g, b, (a1 + a2) / 2)
end

-- Soft dark fade around a frame, drawn outside its edges.
function UI.Glow(f, size, a)
    -- Nested 1px rings keep the corners filled; four gradient strips would leave them cut off.
    for i = 1, size do
        local k = 1 - (i - 0.5) / size
        local al = a * k * k
        local d = i - 1
        local function Ring(p1, r1, x1, y1, p2, r2, x2, y2, horizontal)
            local t = f:CreateTexture(nil, "BACKGROUND")
            t:SetPoint(p1, f, r1, x1, y1)
            t:SetPoint(p2, f, r2, x2, y2)
            if horizontal then t:SetHeight(1) else t:SetWidth(1) end
            t:SetColorTexture(0, 0, 0, al)
        end
        Ring("BOTTOMLEFT", "TOPLEFT", -i, d, "BOTTOMRIGHT", "TOPRIGHT", i, d, true)
        Ring("TOPLEFT", "BOTTOMLEFT", -i, -d, "TOPRIGHT", "BOTTOMRIGHT", i, -d, true)
        Ring("TOPRIGHT", "TOPLEFT", -d, d, "BOTTOMRIGHT", "BOTTOMLEFT", -d, -d, false)
        Ring("TOPLEFT", "TOPRIGHT", d, d, "BOTTOMLEFT", "BOTTOMRIGHT", d, -d, false)
    end
end

-- Content fades in when the frame is shown. A cover texture fades out, so the frame's own alpha stays untouched.
function UI.Reveal(f, dur, color)
    dur = dur or 0.16
    local cover = CreateFrame("Frame", nil, f)
    cover:SetAllPoints(f)
    cover:SetFrameLevel(f:GetFrameLevel() + 60)
    local tex = cover:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    Tint(tex, color or UI.PAL.bg, 1)
    cover:Hide()
    local t = 0
    cover:SetScript("OnUpdate", function(self, dt)
        t = t + dt
        if t >= dur then self:Hide(); return end
        local k = 1 - t / dur
        tex:SetAlpha(k * k)
    end)
    f:HookScript("OnShow", function()
        if not UI.Anim() then return end
        t = 0
        tex:SetAlpha(1)
        cover:Show()
    end)
end

-- Popup look: dark panel, accent top stripe, soft shadow. Returns the border (SetColor recolours border and stripe).
function UI.Panel(f, r, g, b)
    local P = UI.PAL
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Tint(bg, P.panel)
    local sheen = f:CreateTexture(nil, "BORDER")
    sheen:SetPoint("TOPLEFT", 1, -1)
    sheen:SetPoint("TOPRIGHT", -1, -1)
    sheen:SetHeight(46)
    UI.Gradient(sheen, true, 1, 1, 1, 0, 0.05)
    UI.Glow(f, 7, 0.4)
    local edge = UI.Border(f, 1, 1, 1, 0.9)
    local top = f:CreateTexture(nil, "ARTWORK")
    top:SetPoint("TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", -1, -1)
    top:SetHeight(2)
    local setc = edge.SetColor
    function edge:SetColor(cr, cg, cb, ca)
        setc(self, cr, cg, cb, ca)
        top:SetColorTexture(cr, cg, cb, 1)
    end
    edge:SetColor(r or UI.ACCENT[1], g or UI.ACCENT[2], b or UI.ACCENT[3], 0.9)
    UI.Reveal(f, 0.2, P.panel)
    return edge
end

-- 1px outline made of four edge textures
function UI.Border(f, r, g, b, a)
    local e = {}
    for i = 1, 4 do e[i] = f:CreateTexture(nil, "BORDER") end
    e[1]:SetPoint("TOPLEFT"); e[1]:SetPoint("TOPRIGHT"); e[1]:SetHeight(1)
    e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(1)
    e[3]:SetPoint("TOPLEFT"); e[3]:SetPoint("BOTTOMLEFT"); e[3]:SetWidth(1)
    e[4]:SetPoint("TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT"); e[4]:SetWidth(1)
    function e:SetColor(cr, cg, cb, ca)
        for i = 1, 4 do self[i]:SetColorTexture(cr, cg, cb, ca or 1) end
    end
    e:SetColor(r or 1, g or 1, b or 1, a or 0.1)
    return e
end

function UI.Text(parent, text, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    if fs:SetFont(FONT, size or 12, "") == false then fs:SetFont(STANDARD_TEXT_FONT, size or 12, "") end
    fs:SetTextColor(r or 0.92, g or 0.94, b or 0.97)
    fs:SetText(text or "")
    return fs
end

function UI.Header(parent, text)
    local a = UI.ACCENT
    return UI.Text(parent, text, 13, a[1], a[2], a[3])
end

function UI.Button(parent, w, h, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Tint(bg, UI.PAL.button)
    local gloss = b:CreateTexture(nil, "BORDER")
    gloss:SetPoint("TOPLEFT", 1, -1)
    gloss:SetPoint("TOPRIGHT", -1, -1)
    gloss:SetHeight(math.max(2, math.floor(h / 2)))
    UI.Gradient(gloss, true, 1, 1, 1, 0, 0.08)
    b.edge = UI.Border(b, 1, 1, 1, 0.08)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.25)
    b.label = UI.Text(b, text, 12)
    b.label:SetPoint("CENTER")
    b:SetScript("OnEnter", function(self) self.edge:SetColor(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.7) end)
    b:SetScript("OnLeave", function(self) self.edge:SetColor(1, 1, 1, 0.08) end)
    b:SetScript("OnMouseDown", function(self)
        if not self.noPress then self.label:SetPoint("CENTER", self, "CENTER", 0, -1) end
    end)
    b:SetScript("OnMouseUp", function(self)
        if not self.noPress then self.label:SetPoint("CENTER", self, "CENTER", 0, 0) end
    end)
    b:SetScript("OnClick", function(self) if onClick then onClick(self) end end)
    function b:SetLabel(t) self.label:SetText(t) end
    return b
end

function UI.Check(parent, label, get, set)
    local c = CreateFrame("Button", nil, parent)
    c:SetHeight(20)
    local box = c:CreateTexture(nil, "BACKGROUND")
    box:SetSize(14, 14)
    box:SetPoint("LEFT", c, "LEFT", 0, 0)
    Tint(box, UI.PAL.box)
    local frame = CreateFrame("Frame", nil, c)
    frame:SetAllPoints(box)
    local boxEdge = UI.Border(frame, 1, 1, 1, 0.18)
    c:SetScript("OnEnter", function() boxEdge:SetColor(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.8) end)
    c:SetScript("OnLeave", function() boxEdge:SetColor(1, 1, 1, 0.18) end)
    local mark = c:CreateTexture(nil, "ARTWORK")
    mark:SetSize(8, 8)
    mark:SetPoint("CENTER", box, "CENTER", 0, 0)
    mark:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 1)
    c.text = UI.Text(c, label, 12)
    c.text:SetPoint("LEFT", box, "RIGHT", 7, 0)
    function c:SetLabel(t)
        self.text:SetText(t)
        self:SetWidth(self.text:GetStringWidth() + 30)
    end
    function c:Refresh() mark:SetShown(get() and true or false) end
    c:SetScript("OnClick", function(self) set(not get()); self:Refresh() end)
    c:SetLabel(label)
    c:Refresh()
    return c
end

-- [-] value [+] row
function UI.Stepper(parent, label, get, set, minv, maxv, step)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(380, 20)
    local text = UI.Text(f, label, 12)
    text:SetPoint("LEFT", f, "LEFT", 0, 0)
    local minus = UI.Button(f, 20, 20, "-", function()
        set(math.max(minv, (get() or minv) - step)); f:Refresh()
    end)
    minus:SetPoint("LEFT", f, "LEFT", 250, 0)
    local value = UI.Text(f, "", 12)
    value:SetPoint("LEFT", minus, "RIGHT", 0, 0)
    value:SetWidth(40)
    local plus = UI.Button(f, 20, 20, "+", function()
        set(math.min(maxv, (get() or minv) + step)); f:Refresh()
    end)
    plus:SetPoint("LEFT", value, "RIGHT", 0, 0)
    function f:Refresh() value:SetText(tostring(get() or "")) end
    f:Refresh()
    return f
end

-- Cycles through a static list of {value, label}.
function UI.Cycle(parent, label, choices, get, set)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(380, 22)
    local text = UI.Text(f, label, 12)
    text:SetPoint("LEFT", f, "LEFT", 0, 0)
    local function labelOf(v)
        for _, c in ipairs(choices) do if c[1] == v then return c[2] end end
        return tostring(v)
    end
    local btn = UI.Button(f, 110, 20, "", function()
        local cur, idx = get(), 1
        for i, c in ipairs(choices) do if c[1] == cur then idx = i end end
        idx = idx + 1
        if idx > #choices then idx = 1 end
        set(choices[idx][1]); f:Refresh()
    end)
    btn:SetPoint("LEFT", f, "LEFT", 250, 0)
    function f:Refresh() btn:SetLabel(labelOf(get())) end
    f:Refresh()
    return f
end

local function ToHex(r, g, b)
    return string.format("%02X%02X%02X", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- label + color swatch (opens the color picker) + hex box. get() -> r,g,b ; set(r,g,b)
function UI.Color(parent, label, get, set)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(380, 22)
    local text = UI.Text(f, label, 12)
    text:SetPoint("LEFT", f, "LEFT", 0, 0)

    local sw = CreateFrame("Button", nil, f)
    sw:SetSize(30, 18)
    sw:SetPoint("LEFT", f, "LEFT", 250, 0)
    UI.Border(sw, 1, 1, 1, 0.3)
    local tex = sw:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 1, -1)
    tex:SetPoint("BOTTOMRIGHT", -1, 1)

    local hex
    local function Apply(r, g, b)
        set(r, g, b)
        f:Refresh()
    end

    sw:SetScript("OnClick", function()
        local r, g, b = get()
        local picker = ColorPickerFrame
        if not picker then return end
        local function Picked() Apply(picker:GetColorRGB()) end
        local function Cancel() Apply(r, g, b) end
        if picker.SetupColorPickerAndShow then
            picker:SetupColorPickerAndShow({
                r = r, g = g, b = b, hasOpacity = false,
                swatchFunc = Picked, cancelFunc = Cancel,
            })
        else
            picker.hasOpacity = false
            picker.func, picker.cancelFunc = Picked, Cancel
            picker.previousValues = { r = r, g = g, b = b }
            picker:SetColorRGB(r, g, b)
            picker:Hide()
            picker:Show()
        end
    end)

    hex = UI.EditBox(f, 66, function(t)
        local h = t:gsub("[^%x]", "")
        if #h == 6 then
            Apply(tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255)
        end
    end)
    hex:SetHeight(18)
    hex:SetMaxLetters(7)
    hex:SetPoint("LEFT", sw, "RIGHT", 8, 0)

    function f:Refresh()
        local r, g, b = get()
        tex:SetColorTexture(r, g, b, 1)
        hex:SetTextSafe(ToHex(r, g, b))
    end
    f:Refresh()
    return f
end

function UI.EditBox(parent, w, onText)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetSize(w, 20)
    e:SetAutoFocus(false)
    e:SetFont(FONT, 12, "")
    e:SetTextInsets(6, 6, 0, 0)
    local bg = e:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Tint(bg, UI.PAL.field)
    local border = UI.Border(e, 1, 1, 1, 0.1)
    e:SetScript("OnEditFocusGained", function() border:SetColor(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.9) end)
    e:SetScript("OnEditFocusLost", function() border:SetColor(1, 1, 1, 0.1) end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:SetScript("OnTextChanged", function(self, user)
        if user and onText then onText(self:GetText()) end
    end)
    -- never overwrite what the user is typing
    function e:SetTextSafe(t)
        if not self:HasFocus() and self:GetText() ~= t then self:SetText(t) end
    end
    return e
end

function UI.Window(name, w, h, title)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(w, h)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    local P = UI.PAL
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Tint(bg, P.bg)
    local sheen = f:CreateTexture(nil, "BACKGROUND")
    sheen:SetPoint("TOPLEFT", 1, -30)
    sheen:SetPoint("TOPRIGHT", -1, -30)
    sheen:SetHeight(160)
    UI.Gradient(sheen, true, 1, 1, 1, 0, 0.035)
    UI.Glow(f, 9, 0.5)
    UI.Border(f, P.border[1], P.border[2], P.border[3], P.border[4])
    local bar = f:CreateTexture(nil, "BORDER")
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(28)
    Tint(bar, P.titleBar)
    local barSheen = f:CreateTexture(nil, "ARTWORK")
    barSheen:SetPoint("TOPLEFT", 1, -1)
    barSheen:SetPoint("TOPRIGHT", -1, -1)
    barSheen:SetHeight(28)
    UI.Gradient(barSheen, true, 1, 1, 1, 0, 0.09)
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -29)
    line:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -29)
    line:SetHeight(1)
    line:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.8)
    f.title = UI.Text(f, title, 13, 1, 1, 1)
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -8)
    local close = UI.Button(f, 22, 20, "x", function() f:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -4)
    UI.Reveal(f, 0.16, P.bg)
    return f
end

-- Paged pick list. items = { {label=, icon=, value=}, ... }; onPick(item)
local PAGE = 14
local menu

local function MenuRefresh()
    local first = (menu.page - 1) * PAGE
    local shown = 0
    for i = 1, PAGE do
        local row, item = menu.rows[i], menu.items[first + i]
        row.item = item
        if item then
            shown = i
            row.text:SetText(item.label)
            if item.icon then row.icon:SetTexture(item.icon); row.icon:Show() else row.icon:Hide() end
            row:Show()
        else
            row:Hide()
        end
    end
    local pages = math.max(1, math.ceil(#menu.items / PAGE))
    menu.pageText:SetText(menu.page .. " / " .. pages)
    menu.prev:SetShown(menu.page > 1)
    menu.next:SetShown(menu.page < pages)
    menu:SetHeight(shown * 20 + 36)
    menu.pageText:ClearAllPoints()
    menu.pageText:SetPoint("BOTTOM", menu, "BOTTOM", 0, 8)
end

local function MenuBuild()
    menu = CreateFrame("Frame", "HHTMenu", UIParent)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(20)
    menu:SetWidth(260)
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    menu:Hide()
    -- full-screen catcher below the menu: any click outside closes it
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetFrameStrata("TOOLTIP")
    catcher:SetFrameLevel(1)
    catcher:SetAllPoints(UIParent)
    catcher:EnableMouse(true)
    catcher:RegisterForClicks("AnyUp")
    catcher:SetScript("OnClick", function() menu:Hide() end)
    catcher:Hide()
    menu:SetScript("OnShow", function() catcher:Show() end)
    menu:SetScript("OnHide", function() catcher:Hide() end)
    local bg = menu:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Tint(bg, UI.PAL.menu)
    UI.Glow(menu, 6, 0.4)
    UI.Border(menu, 1, 1, 1, 0.14)
    menu.rows = {}
    for i = 1, PAGE do
        local b = CreateFrame("Button", nil, menu)
        b:SetSize(254, 20)
        b:SetPoint("TOPLEFT", menu, "TOPLEFT", 3, -3 - (i - 1) * 20)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.22)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetSize(16, 16)
        b.icon:SetPoint("LEFT", b, "LEFT", 2, 0)
        b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        HHT.Icon.Attach(b.icon)
        b.text = UI.Text(b, "", 12)
        b.text:SetPoint("LEFT", b, "LEFT", 24, 0)
        b:SetScript("OnClick", function(self)
            local item, cb = self.item, menu.onPick
            menu:Hide()
            if item and cb then cb(item) end
        end)
        menu.rows[i] = b
    end
    menu.pageText = UI.Text(menu, "", 11, 0.7, 0.7, 0.7)
    menu.prev = UI.Button(menu, 24, 18, "<", function() menu.page = menu.page - 1; MenuRefresh() end)
    menu.prev:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 6, 5)
    menu.next = UI.Button(menu, 24, 18, ">", function() menu.page = menu.page + 1; MenuRefresh() end)
    menu.next:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -6, 5)
    if UISpecialFrames then table.insert(UISpecialFrames, "HHTMenu") end
end

function UI.ShowMenu(anchor, items, onPick)
    if not menu then MenuBuild() end
    if #items == 0 then HHT.Print("Nothing to choose from."); return end
    menu.items, menu.page, menu.onPick = items, 1, onPick
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    MenuRefresh()
    menu:Show()
end
