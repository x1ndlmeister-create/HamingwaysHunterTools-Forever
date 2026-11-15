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
        head = { 0.9, 0.72, 0.28 }, banner = { 0.5, 0.34, 0.12 },
    },
    dark = {
        accent = { 0.45, 0.78, 0.95 }, bg = { 0.05, 0.057, 0.075, 0.97 }, panel = { 0.05, 0.057, 0.075, 0.96 },
        inset = { 0.025, 0.03, 0.042, 1 }, side = { 0.035, 0.04, 0.055, 0.9 }, titleBar = { 0.085, 0.1, 0.135, 1 },
        border = { 0.25, 0.31, 0.44, 0.9 }, button = { 0.115, 0.135, 0.18, 1 }, box = { 0.06, 0.07, 0.095, 1 },
        field = { 0.03, 0.035, 0.05, 0.95 }, menu = { 0.045, 0.052, 0.07, 0.99 }, hdrLine = { 0.25, 0.31, 0.44, 0.6 },
        head = { 0.62, 0.82, 1 }, banner = { 0.16, 0.3, 0.52 },
    },
    minimal = {
        accent = { 0.67, 0.83, 0.45 }, bg = { 0.04, 0.04, 0.04, 0.97 }, panel = { 0.04, 0.04, 0.04, 0.96 },
        inset = { 0.015, 0.015, 0.015, 1 }, side = { 0.028, 0.028, 0.028, 0.9 }, titleBar = { 0.085, 0.085, 0.085, 1 },
        border = { 0.3, 0.3, 0.3, 0.9 }, button = { 0.135, 0.135, 0.135, 1 }, box = { 0.07, 0.07, 0.07, 1 },
        field = { 0.02, 0.02, 0.02, 0.95 }, menu = { 0.035, 0.035, 0.035, 0.99 }, hdrLine = { 0.3, 0.3, 0.3, 0.6 },
        head = { 0.86, 0.88, 0.84 }, banner = { 0.3, 0.3, 0.3 },
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
function UI.Gradient(tex, vertical, r, g, b, a1, a2, file)
    tex:SetTexture(file or WHITE)
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

-- Rounded shapes: one small texture cut into nine pieces, so any frame size keeps the same corner radius.
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\UI\\"
UI.TEX_ROUND, UI.TEX_CIRCLE = MEDIA .. "round", MEDIA .. "circle"
local ICONS = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Icons\\"
UI.ICON_DIR = ICONS

-- Inline icon for font strings: UI.IconTag("heart", 13) .. " 98%"
function UI.IconTag(name, size)
    size = size or 13
    return "|T" .. ICONS .. name .. ":" .. size .. ":" .. size .. ":0:0|t"
end

local SLICE = { round = 10 / 32, round_edge = 10 / 32, shadow = 28 / 64 }

-- c = corner size on screen, o = how far the shape reaches past the frame edge. Returns an object with SetColor.
local function NineSlice(f, name, c, o, layer, sub, noCenter)
    local file, s = MEDIA .. name, SLICE[name]
    local t = {}
    local function Piece(i, l, r, tp, b)
        local x
        if sub then x = f:CreateTexture(nil, layer, nil, sub) else x = f:CreateTexture(nil, layer) end
        x:SetTexture(file)
        x:SetTexCoord(l, r, tp, b)
        t[i] = x
        return x
    end
    local TL, TR = Piece(1, 0, s, 0, s), Piece(2, 1 - s, 1, 0, s)
    local BL, BR = Piece(3, 0, s, 1 - s, 1), Piece(4, 1 - s, 1, 1 - s, 1)
    TL:SetSize(c, c); TL:SetPoint("TOPLEFT", f, "TOPLEFT", -o, o)
    TR:SetSize(c, c); TR:SetPoint("TOPRIGHT", f, "TOPRIGHT", o, o)
    BL:SetSize(c, c); BL:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -o, -o)
    BR:SetSize(c, c); BR:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", o, -o)
    local T = Piece(5, s, 1 - s, 0, s)
    T:SetPoint("TOPLEFT", TL, "TOPRIGHT"); T:SetPoint("BOTTOMRIGHT", TR, "BOTTOMLEFT")
    local B = Piece(6, s, 1 - s, 1 - s, 1)
    B:SetPoint("TOPLEFT", BL, "TOPRIGHT"); B:SetPoint("BOTTOMRIGHT", BR, "BOTTOMLEFT")
    local L = Piece(7, 0, s, s, 1 - s)
    L:SetPoint("TOPLEFT", TL, "BOTTOMLEFT"); L:SetPoint("BOTTOMRIGHT", BL, "TOPRIGHT")
    local R = Piece(8, 1 - s, 1, s, 1 - s)
    R:SetPoint("TOPLEFT", TR, "BOTTOMLEFT"); R:SetPoint("BOTTOMRIGHT", BR, "TOPRIGHT")
    if not noCenter then
        local C = Piece(9, s, 1 - s, s, 1 - s)
        C:SetPoint("TOPLEFT", TL, "BOTTOMRIGHT"); C:SetPoint("BOTTOMRIGHT", BR, "TOPLEFT")
    end
    local o9 = {}
    function o9:SetColor(r, g, b, a)
        for _, x in ipairs(t) do x:SetVertexColor(r, g, b, a or 1) end
    end
    function o9:SetAlpha(a)
        for _, x in ipairs(t) do x:SetAlpha(a) end
    end
    function o9:SetShown(on)
        for _, x in ipairs(t) do x:SetShown(on) end
    end
    return o9
end

-- Filled rounded rectangle covering the frame.
function UI.Round(f, radius, r, g, b, a, layer, sub)
    local o = NineSlice(f, "round", radius, 0, layer or "BACKGROUND", sub)
    o:SetColor(r, g, b, a)
    return o
end

-- Thin rounded outline around the frame. SetColor works like on UI.Border.
function UI.RoundBorder(f, radius, r, g, b, a, layer, sub)
    local o = NineSlice(f, "round_edge", radius, 0, layer or "BORDER", sub, true)
    o:SetColor(r or 1, g or 1, b or 1, a or 0.1)
    return o
end

-- Soft rounded shadow that reaches 20 px past the frame.
function UI.Shadow(f, a)
    local o = NineSlice(f, "shadow", 28, 20, "BACKGROUND", -8)
    o:SetColor(0, 0, 0, a or 0.5)
    return o
end

-- Gradient band along the top edge of a rounded frame; the corner pieces follow the curve.
-- vertical: a2 = alpha at the top, a1 = at the bottom of the band. horizontal: a1 = left, a2 = right.
function UI.Band(f, h, radius, horizontal, r, g, b, a1, a2, layer, sub)
    local file, s = MEDIA .. "round", SLICE.round
    local parts = {}
    local function Part(side, y0, y1, corner)
        local t
        if sub then t = f:CreateTexture(nil, layer, nil, sub) else t = f:CreateTexture(nil, layer) end
        local p = { tex = t, side = side, y0 = y0, y1 = y1, corner = corner }
        if not side then
            t:SetPoint("TOPLEFT", f, "TOPLEFT", radius, 0)
            t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -radius, 0)
            t:SetHeight(h)
        else
            local pt = side == "L" and "TOPLEFT" or "TOPRIGHT"
            t:SetSize(radius, y1 - y0)
            t:SetPoint(pt, f, pt, 0, -y0)
            if corner then
                local v = (y1 - y0) / radius * s
                p.coords = side == "L" and { 0, s, 0, v } or { 1 - s, 1, 0, v }
            end
        end
        parts[#parts + 1] = p
    end
    local cap = math.min(h, radius)
    Part("L", 0, cap, true)
    Part("R", 0, cap, true)
    if h > radius then
        Part("L", radius, h)
        Part("R", radius, h)
    end
    Part(nil, 0, h)
    local obj = {}
    function obj:SetColor(cr, cg, cb)
        for _, p in ipairs(parts) do
            local t, tex = p.tex, p.corner and file or nil
            if horizontal then
                if p.side then
                    t:SetTexture(tex or WHITE)
                    t:SetVertexColor(cr, cg, cb, p.side == "L" and a1 or a2)
                else
                    UI.Gradient(t, false, cr, cg, cb, a1, a2)
                end
            else
                local function At(y) return a2 + (a1 - a2) * y / h end
                UI.Gradient(t, true, cr, cg, cb, At(p.y1), At(p.y0), tex)
            end
            if p.coords then t:SetTexCoord(p.coords[1], p.coords[2], p.coords[3], p.coords[4]) end
        end
    end
    obj:SetColor(r, g, b)
    return obj
end

-- Content fades in when the frame is shown. A cover texture fades out, so the frame's own alpha stays untouched.
-- With a radius the cover is rounded like the frame.
function UI.Reveal(f, dur, color, radius)
    dur = dur or 0.16
    local cover = CreateFrame("Frame", nil, f)
    cover:SetAllPoints(f)
    cover:SetFrameLevel(f:GetFrameLevel() + 60)
    local c = color or UI.PAL.bg
    local tex
    if radius then
        tex = UI.Round(cover, radius, c[1], c[2], c[3], 1, "OVERLAY")
    else
        tex = cover:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        Tint(tex, c, 1)
    end
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
    local R = 7
    UI.Round(f, R, P.panel[1], P.panel[2], P.panel[3], P.panel[4], "BACKGROUND", -7)
    UI.Band(f, 46, R, false, 1, 1, 1, 0, 0.05, "BORDER")
    UI.Shadow(f, 0.4)
    local edge = UI.RoundBorder(f, R, 1, 1, 1, 0.9, "ARTWORK", 7)
    local top = UI.Band(f, 2, R, false, 1, 1, 1, 1, 1, "ARTWORK", 6)
    local setc = edge.SetColor
    function edge:SetColor(cr, cg, cb, ca)
        setc(self, cr, cg, cb, ca)
        top:SetColor(cr, cg, cb)
    end
    edge:SetColor(r or UI.ACCENT[1], g or UI.ACCENT[2], b or UI.ACCENT[3], 0.9)
    UI.Reveal(f, 0.2, P.panel, R)
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
    local a = UI.PAL.head
    return UI.Text(parent, text, 14, a[1], a[2], a[3])
end

-- Hairline that fades out towards the right.
function UI.FadeLine(parent, r, g, b, a, layer)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetHeight(1)
    UI.Gradient(t, false, r, g, b, a, 0)
    return t
end

-- List row look: soft hover, selection with fading accent gradient and a bar on the left. Adds b:SetSelected(on).
function UI.Selectable(b)
    local a = UI.ACCENT
    UI.Round(b, 6, 1, 1, 1, 0.06, "HIGHLIGHT")
    local sel = b:CreateTexture(nil, "BORDER")
    sel:SetAllPoints()
    UI.Gradient(sel, false, a[1], a[2], a[3], 0.3, 0)
    sel:Hide()
    local bar = CreateFrame("Frame", nil, b)
    bar:SetWidth(3)
    bar:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -6)
    bar:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 6)
    UI.Round(bar, 1.5, a[1], a[2], a[3], 1, "ARTWORK")
    bar:Hide()
    function b:SetSelected(on)
        sel:SetShown(on and true or false)
        bar:SetShown(on and true or false)
    end
end

-- On/off switch. get() -> boolean ; set(boolean)
function UI.Switch(parent, get, set)
    local s = CreateFrame("Button", nil, parent)
    s:SetSize(38, 18)
    local track = UI.Round(s, 9, 0.05, 0.05, 0.05, 0.9, "BACKGROUND")
    local edge = UI.RoundBorder(s, 9, 1, 1, 1, 0.14, "BORDER")
    local knob = s:CreateTexture(nil, "ARTWORK")
    knob:SetSize(12, 12)
    knob:SetTexture(UI.TEX_CIRCLE)
    function s:Refresh()
        local on = get() and true or false
        local a = UI.ACCENT
        knob:ClearAllPoints()
        if on then
            knob:SetPoint("RIGHT", s, "RIGHT", -3, 0)
            track:SetColor(a[1], a[2], a[3], 0.55)
            knob:SetVertexColor(1, 1, 1, 1)
        else
            knob:SetPoint("LEFT", s, "LEFT", 3, 0)
            track:SetColor(0.05, 0.05, 0.05, 0.9)
            knob:SetVertexColor(0.55, 0.55, 0.55, 1)
        end
    end
    s:SetScript("OnEnter", function() edge:SetColor(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.8) end)
    s:SetScript("OnLeave", function() edge:SetColor(1, 1, 1, 0.14) end)
    s:SetScript("OnClick", function() set(not get()); s:Refresh() end)
    s:Refresh()
    return s
end

-- Gives an existing button (also a secure one) the rounded button look and a label. A lone "x" becomes a close glyph.
function UI.StyleButton(b, text, size)
    local w, h = b:GetWidth(), b:GetHeight()
    local rad = math.min(5, math.floor((h or 20) / 2))
    local P = UI.PAL
    b.fill = UI.Round(b, rad, P.button[1], P.button[2], P.button[3], P.button[4], "BACKGROUND")
    b.edge = UI.RoundBorder(b, rad, 1, 1, 1, 0.07, "BORDER")
    UI.Round(b, rad, UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.25, "HIGHLIGHT")
    b.label = UI.Text(b, text, size or 12)
    b.label:SetPoint("CENTER")
    if text == "x" then
        b.label:SetText("")
        local g = b:CreateTexture(nil, "OVERLAY")
        g:SetSize(math.max(8, math.min(w, h) - 8), math.max(8, math.min(w, h) - 8))
        g:SetPoint("CENTER")
        g:SetTexture(ICONS .. "x")
        g:SetVertexColor(0.85, 0.87, 0.9, 1)
    end
    b:SetScript("OnEnter", function(self) self.edge:SetColor(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.7) end)
    b:SetScript("OnLeave", function(self)
        local e = self.edgeRest
        if e then self.edge:SetColor(e[1], e[2], e[3], e[4]) else self.edge:SetColor(1, 1, 1, 0.07) end
    end)
    b:SetScript("OnMouseDown", function(self)
        if not self.noPress then self.label:SetPoint("CENTER", self, "CENTER", 0, -1) end
    end)
    b:SetScript("OnMouseUp", function(self)
        if not self.noPress then self.label:SetPoint("CENTER", self, "CENTER", 0, 0) end
    end)
    function b:SetLabel(t) self.label:SetText(t) end
end

-- Highlighted main action of a popup: tinted fill and outline in the popup colour.
function UI.SetPrimary(b, r, g, bl)
    b.fill:SetColor(r * 0.45, g * 0.45, bl * 0.45, 0.95)
    b.edgeRest = { r, g, bl, 0.6 }
    b.edge:SetColor(r, g, bl, 0.6)
    b.label:SetTextColor(1, 1, 1)
end

function UI.Button(parent, w, h, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)
    UI.StyleButton(b, text)
    b:SetScript("OnClick", function(self) if onClick then onClick(self) end end)
    return b
end

-- Shared popup header: optional icon tile (f.icon), eyebrow, title, sub line, close button and a fading divider.
-- Returns the x position where the text starts. opts: icon, onClose, subLines, divY, noDiv.
function UI.PopupHead(f, W, opts)
    local P = UI.PAL
    local x0 = 16
    if opts.icon then
        local tile = CreateFrame("Frame", nil, f)
        tile:SetSize(46, 46)
        tile:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -16)
        UI.Round(tile, 9, P.inset[1], P.inset[2], P.inset[3], 1, "BACKGROUND")
        UI.RoundBorder(tile, 9, 1, 1, 1, 0.12, "BORDER")
        f.icon = tile:CreateTexture(nil, "ARTWORK")
        f.icon:SetPoint("TOPLEFT", tile, "TOPLEFT", 4, -4)
        f.icon:SetPoint("BOTTOMRIGHT", tile, "BOTTOMRIGHT", -4, 4)
        f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        f.tile = tile
        x0 = 76
    end
    f.eyebrow = UI.Text(f, "", 10, 1, 1, 1)
    f.eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", x0, -17)
    f.title = UI.Text(f, "", 15, 1, 1, 1)
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", x0, -31)
    f.title:SetWidth(W - x0 - 40)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    f.sub = UI.Text(f, "", 11, 0.72, 0.74, 0.78)
    f.sub:SetPoint("TOPLEFT", f, "TOPLEFT", x0, -53)
    f.sub:SetWidth(W - x0 - 16)
    f.sub:SetJustifyH("LEFT")
    if (opts.subLines or 1) > 1 then
        f.sub:SetJustifyV("TOP")
        f.sub:SetHeight(14 * opts.subLines)
    else
        f.sub:SetWordWrap(false)
    end
    f.close = UI.Button(f, 20, 20, "x", opts.onClose)
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
    f.div = UI.FadeLine(f, 1, 1, 1, 0.16)
    f.div:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -(opts.divY or 76))
    f.div:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -(opts.divY or 76))
    if opts.noDiv then f.div:Hide() end
    f.x0 = x0
    return x0
end

-- Sizes a popup to its content: contentW is the widest body row or button row (without the 16px side padding).
-- The title and sub line may widen it too, within minW..maxW. Returns the final width.
function UI.PopupFit(f, contentW, minW, maxW)
    local x0 = f.x0 or 16
    f.title:SetWidth(2000)
    f.sub:SetWidth(2000)
    local w = math.max(minW, contentW + 32, f.title:GetStringWidth() + x0 + 44)
    if f.sub:IsShown() then w = math.max(w, f.sub:GetStringWidth() + x0 + 16) end
    w = math.ceil(math.min(maxW, w))
    f:SetWidth(w)
    f.title:SetWidth(w - x0 - 44)
    f.sub:SetWidth(w - x0 - 16)
    return w
end

function UI.Check(parent, label, get, set)
    local c = CreateFrame("Button", nil, parent)
    c:SetHeight(20)
    local box = CreateFrame("Frame", nil, c)
    box:SetSize(14, 14)
    box:SetPoint("LEFT", c, "LEFT", 0, 0)
    local P = UI.PAL
    UI.Round(box, 4, P.box[1], P.box[2], P.box[3], 1, "BACKGROUND")
    local boxEdge = UI.RoundBorder(box, 4, 1, 1, 1, 0.22)
    c:SetScript("OnEnter", function() boxEdge:SetColor(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.8) end)
    c:SetScript("OnLeave", function() boxEdge:SetColor(1, 1, 1, 0.22) end)
    local mark = box:CreateTexture(nil, "ARTWORK")
    mark:SetSize(8, 8)
    mark:SetPoint("CENTER", box, "CENTER", 0, 0)
    mark:SetTexture(UI.TEX_ROUND)
    mark:SetVertexColor(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 1)
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
    -- wide enough for the longest choice
    local widest = 0
    for _, c in ipairs(choices) do
        btn.label:SetText(c[2])
        widest = math.max(widest, btn.label:GetStringWidth())
    end
    btn:SetWidth(math.min(226, math.max(110, widest + 24)))
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
    local swFill = UI.Round(sw, 5, 0, 0, 0, 1, "BACKGROUND")
    UI.RoundBorder(sw, 5, 1, 1, 1, 0.3)

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
        swFill:SetColor(r, g, b, 1)
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
    local P = UI.PAL
    UI.Round(e, 5, P.field[1], P.field[2], P.field[3], P.field[4], "BACKGROUND")
    local border = UI.RoundBorder(e, 5, 1, 1, 1, 0.1)
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

-- Slim scroll bar for a ScrollFrame: drag the thumb, click the track to jump; the mouse wheel scrolls too.
-- Returns Update(), call it after the content height changed.
function UI.ScrollBar(sf, child, xOff, step)
    local bar = CreateFrame("Button", nil, sf)
    bar:SetWidth(12)
    bar:SetPoint("TOPRIGHT", sf, "TOPRIGHT", xOff or 0, 0)
    bar:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", xOff or 0, 0)
    bar:SetFrameLevel(sf:GetFrameLevel() + 10)
    local track = CreateFrame("Frame", nil, bar)
    track:SetWidth(3)
    track:SetPoint("TOP", bar, "TOP", 0, 0)
    track:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
    UI.Round(track, 1.5, 1, 1, 1, 0.05)
    local thumb = CreateFrame("Frame", nil, bar)
    thumb:SetWidth(4)
    local a = UI.ACCENT
    local fill = UI.Round(thumb, 2, a[1], a[2], a[3], 0.45, "ARTWORK")
    bar:Hide()

    local function Metrics()
        local viewH, contentH = sf:GetHeight(), child:GetHeight()
        local range = math.max(0, contentH - viewH)
        local h = math.max(24, viewH * viewH / math.max(contentH, 1))
        return viewH, range, math.min(h, viewH)
    end
    local function Update()
        local viewH, range, h = Metrics()
        if range <= 1 then bar:Hide(); return end
        bar:Show()
        thumb:SetHeight(h)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", bar, "TOP", 0, -((viewH - h) * (sf:GetVerticalScroll() / range)))
    end
    local function Scroll(v)
        local _, range = Metrics()
        sf:SetVerticalScroll(math.min(range, math.max(0, v)))
        Update()
    end

    local grab
    local function Follow()
        local viewH, range, h = Metrics()
        local _, cy = GetCursorPosition()
        local y = bar:GetTop() - cy / bar:GetEffectiveScale() - grab
        Scroll(y / math.max(1, viewH - h) * range)
    end
    bar:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        local _, _, h = Metrics()
        local cy = select(2, GetCursorPosition()) / self:GetEffectiveScale()
        local top = thumb:GetTop()
        if top and cy <= top and cy >= top - h then grab = top - cy else grab = h / 2 end
        fill:SetColor(a[1], a[2], a[3], 0.9)
        Follow()
        self:SetScript("OnUpdate", Follow)
    end)
    local function Stop(self)
        self:SetScript("OnUpdate", nil)
        fill:SetColor(a[1], a[2], a[3], 0.45)
    end
    bar:SetScript("OnMouseUp", Stop)
    bar:SetScript("OnHide", Stop)
    bar:SetScript("OnEnter", function() thumb:SetWidth(6) end)
    bar:SetScript("OnLeave", function() thumb:SetWidth(4) end)
    bar:EnableMouseWheel(true)
    local function Wheel(_, delta) Scroll(sf:GetVerticalScroll() - delta * (step or 40)) end
    bar:SetScript("OnMouseWheel", Wheel)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", Wheel)
    sf:SetScript("OnSizeChanged", Update)
    return Update
end

-- Scroll bar for lists made of a fixed set of rows and an offset (no ScrollFrame). The caller positions the returned bar.
-- getTotal() -> number of entries, get() -> offset, set(offset) must repaint and call bar:Update().
function UI.OffsetBar(parent, h, rows, getTotal, get, set)
    local bar = CreateFrame("Button", nil, parent)
    bar:SetSize(12, h)
    local track = CreateFrame("Frame", nil, bar)
    track:SetWidth(3)
    track:SetPoint("TOP", bar, "TOP", 0, 0)
    track:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
    UI.Round(track, 1.5, 1, 1, 1, 0.05)
    local thumb = CreateFrame("Frame", nil, bar)
    thumb:SetWidth(4)
    local a = UI.ACCENT
    local fill = UI.Round(thumb, 2, a[1], a[2], a[3], 0.45, "ARTWORK")
    local function Max() return math.max(0, getTotal() - rows) end
    function bar:Update()
        local total = getTotal()
        if total <= rows then self:Hide(); return end
        self:Show()
        local th = math.min(h, math.max(24, h * rows / total))
        thumb:SetHeight(th)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", self, "TOP", 0, -(h - th) * (get() / Max()))
    end
    local grab = 12
    local function Follow(self)
        local th = thumb:GetHeight()
        local _, cy = GetCursorPosition()
        local frac = (self:GetTop() - cy / self:GetEffectiveScale() - grab) / math.max(1, h - th)
        set(math.floor(math.max(0, math.min(1, frac)) * Max() + 0.5))
    end
    bar:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        local th = thumb:GetHeight()
        local cy = select(2, GetCursorPosition()) / self:GetEffectiveScale()
        local top = thumb:GetTop()
        if top and cy <= top and cy >= top - th then grab = top - cy else grab = th / 2 end
        fill:SetColor(a[1], a[2], a[3], 0.9)
        Follow(self)
        self:SetScript("OnUpdate", Follow)
    end)
    local function Stop(self)
        self:SetScript("OnUpdate", nil)
        fill:SetColor(a[1], a[2], a[3], 0.45)
    end
    bar:SetScript("OnMouseUp", Stop)
    bar:SetScript("OnHide", Stop)
    bar:SetScript("OnEnter", function() thumb:SetWidth(6) end)
    bar:SetScript("OnLeave", function() thumb:SetWidth(4) end)
    bar:EnableMouseWheel(true)
    bar:SetScript("OnMouseWheel", function(_, d) set(math.max(0, math.min(Max(), get() - d * 3))) end)
    return bar
end

function UI.Window(name, w, h, title, bannerH)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(w, h)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    local P = UI.PAL
    local R = 8
    UI.Round(f, R, P.bg[1], P.bg[2], P.bg[3], P.bg[4], "BACKGROUND", -7)
    local sheen = f:CreateTexture(nil, "BACKGROUND")
    sheen:SetPoint("TOPLEFT", 1, -30)
    sheen:SetPoint("TOPRIGHT", -1, -30)
    sheen:SetHeight(160)
    UI.Gradient(sheen, true, 1, 1, 1, 0, 0.035)
    UI.Shadow(f, 0.5)
    UI.RoundBorder(f, R, P.border[1], P.border[2], P.border[3], P.border[4] * 0.7, "ARTWORK", 7)
    -- title bar: colour fades out to the right instead of a hard block
    local barH = bannerH or 28
    local bc = P.banner
    UI.Band(f, barH, R, true, bc[1], bc[2], bc[3], bannerH and 0.95 or 0.8, bannerH and 0.3 or 0.12, "BORDER")
    UI.Band(f, barH, R, false, 0, 0, 0, bannerH and 0.35 or 0.15, 0, "ARTWORK")
    local line = UI.FadeLine(f, UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.9)
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -(barH + 1))
    line:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(barH + 1))
    f.title = UI.Text(f, title, 13, 1, 1, 1)
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -8)
    local close = UI.Button(f, 22, 20, "x", function() f:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -4)
    f.close = close
    UI.Reveal(f, 0.16, P.bg, R)
    return f
end

-- Paged pick list. items = { {label=, icon=, value=, tip=function(tooltip) end}, ... }; onPick(item)
local PAGE = 14
local menu

local function MenuRefresh()
    if GameTooltip then GameTooltip:Hide() end
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
    menu:SetScript("OnHide", function() catcher:Hide(); if GameTooltip then GameTooltip:Hide() end end)
    local m = UI.PAL.menu
    UI.Round(menu, 6, m[1], m[2], m[3], m[4], "BACKGROUND")
    UI.Shadow(menu, 0.4)
    UI.RoundBorder(menu, 6, 1, 1, 1, 0.14)
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
        b:SetScript("OnEnter", function(self)
            local item = self.item
            if not (item and item.tip and GameTooltip) then return end
            GameTooltip:SetOwner(menu, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOPLEFT", menu, "TOPRIGHT", 4, 0)
            if pcall(item.tip, GameTooltip) then GameTooltip:Show() else GameTooltip:Hide() end
        end)
        b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
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
