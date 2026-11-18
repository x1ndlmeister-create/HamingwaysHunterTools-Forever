-- Reusable icon widget: square or round, solid border, cooldown swipe, texts, blink.
local ADDON, HHT = ...
local UI = HHT.UI

local Icon = {}
HHT.Icon = Icon

local MASK = "Interface\\AddOns\\" .. ADDON .. "\\Media\\RoundMask"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = UI.FONT

local floor, max, min, sin = math.floor, math.max, math.min, math.sin

local function SetRound(tex, owner, on)
    if not (owner.CreateMaskTexture and tex.AddMaskTexture) then return end
    if on then
        if not tex.hhtMask then
            local m = owner:CreateMaskTexture()
            m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            m:SetAllPoints(tex)
            tex.hhtMask = m
        end
        if not tex.hhtOn then tex:AddMaskTexture(tex.hhtMask); tex.hhtOn = true end
    elseif tex.hhtOn then
        tex:RemoveMaskTexture(tex.hhtMask)
        tex.hhtOn = false
    end
end

local function SetSwipeRound(cool, on)
    if on then
        pcall(cool.SetSwipeTexture, cool, MASK)
        cool.hhtRound = true
    elseif cool.hhtRound then
        pcall(cool.SetSwipeTexture, cool, WHITE)
        cool.hhtRound = false
    end
end

local function SetFont(fs, size, owner)
    if HHT.StyleFont then HHT.StyleFont(fs, size, owner); return end
    if fs:SetFont(FONT, size, "OUTLINE") == false then fs:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE") end
end

-- Two-colour vertical gradient, bottom -> top, each { r, g, b, a }.
local function Grad(tex, b, t)
    tex:SetTexture(WHITE)
    if tex.SetGradient and CreateColor then
        if pcall(tex.SetGradient, tex, "VERTICAL", CreateColor(b[1], b[2], b[3], b[4]), CreateColor(t[1], t[2], t[3], t[4])) then return end
    end
    if tex.SetGradientAlpha and pcall(tex.SetGradientAlpha, tex, "VERTICAL", b[1], b[2], b[3], b[4], t[1], t[2], t[3], t[4]) then return end
    tex:SetVertexColor(t[1], t[2], t[3], (b[4] + t[4]) / 2)
end

-- 3D / glass finish on top of an icon: bevelled rim, inner shade, gloss and (square icons) lit edges.
-- Style comes from the general setting "style" (flat, bevel, glass). host may be any frame with a border texture.
local finishes = setmetatable({}, { __mode = "k" })

function Icon.NewFinish(host, border)
    local fx = CreateFrame("Frame", nil, host)
    fx:SetAllPoints(host)
    fx:SetFrameLevel(host:GetFrameLevel() + 2)
    fx:Hide()
    local fin = { host = host, fx = fx, border = border, edge = {} }
    fin.rim = host:CreateTexture(nil, "BACKGROUND", nil, 1)
    fin.rim:Hide()
    fin.shade = fx:CreateTexture(nil, "ARTWORK", nil, 1)
    fin.shine = fx:CreateTexture(nil, "ARTWORK", nil, 2)
    for i = 1, 4 do fin.edge[i] = fx:CreateTexture(nil, "ARTWORK", nil, 3) end
    finishes[fin] = true
    return fin
end

function Icon.ApplyFinish(fin, size, round, bs)
    fin.size, fin.round, fin.bs = size, round, bs
    local g = HHT.db and HHT.db.general
    local style = g and g.style or "flat"
    local host, fx, rim = fin.host, fin.fx, fin.rim
    if style ~= "bevel" and style ~= "glass" then
        fx:Hide(); rim:Hide()
        return
    end
    local glass = style == "glass"
    fx:Show()

    if bs > 0 then
        rim:ClearAllPoints()
        rim:SetPoint("TOPLEFT", host, "TOPLEFT", -bs, bs)
        rim:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", bs, -bs)
        Grad(rim, { 0, 0, 0, glass and 0.6 or 0.5 }, { 1, 1, 1, glass and 0.5 or 0.4 })
        SetRound(rim, host, round)
        rim:Show()
    else
        rim:Hide()
    end

    local shade = fin.shade
    shade:ClearAllPoints()
    shade:SetAllPoints(host)
    Grad(shade, { 0, 0, 0, glass and 0.5 or 0.35 }, { 0, 0, 0, 0 })
    SetRound(shade, host, round)

    -- round icons get an elliptical highlight: the round mask is stretched over the short, wide texture
    local shine = fin.shine
    shine:ClearAllPoints()
    if round then
        shine:SetPoint("TOPLEFT", host, "TOPLEFT", size * 0.14, -size * 0.05)
        shine:SetSize(size * 0.72, size * (glass and 0.42 or 0.32))
    else
        shine:SetPoint("TOPLEFT", host, "TOPLEFT", 1, -1)
        shine:SetPoint("TOPRIGHT", host, "TOPRIGHT", -1, -1)
        shine:SetHeight(size * (glass and 0.5 or 0.38))
    end
    Grad(shine, { 1, 1, 1, 0.02 }, { 1, 1, 1, glass and 0.55 or 0.22 })
    SetRound(shine, host, round)

    local e = fin.edge
    if round then
        for i = 1, 4 do e[i]:Hide() end
    else
        local t = size >= 40 and 2 or 1
        for i = 1, 4 do e[i]:ClearAllPoints() end
        e[1]:SetPoint("TOPLEFT", host, "TOPLEFT"); e[1]:SetPoint("TOPRIGHT", host, "TOPRIGHT"); e[1]:SetHeight(t)
        e[2]:SetPoint("TOPLEFT", host, "TOPLEFT"); e[2]:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT"); e[2]:SetWidth(t)
        e[3]:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT"); e[3]:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT"); e[3]:SetHeight(t)
        e[4]:SetPoint("TOPRIGHT", host, "TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT"); e[4]:SetWidth(t)
        e[1]:SetColorTexture(1, 1, 1, 0.4); e[2]:SetColorTexture(1, 1, 1, 0.3)
        e[3]:SetColorTexture(0, 0, 0, 0.5); e[4]:SetColorTexture(0, 0, 0, 0.4)
        for i = 1, 4 do e[i]:Show() end
    end
end

-- Shape, border and colour that the general settings give most modules.
local function CurrentLook()
    local ok, look = pcall(function()
        local c = HHT:GetBorderColor()
        return { round = HHT:GetLook("shape") == "round", bs = HHT:GetLook("borderSize") or 1, r = c[1], g = c[2], b = c[3] }
    end)
    if ok then return look end
    return { round = false, bs = 1, r = 0.55, g = 0.42, b = 0.2 }
end

-- Border and glow of an attached icon. They live in the BORDER layer of the icon's parent, between the
-- background and the icon, so they never cover it.
local function SyncPlate(fin)
    local p = fin.plate
    if not p then return end
    for _, t in ipairs(p.all) do
        t:SetShown(fin.shown and t.want and true or false)
        t:SetAlpha(fin.alpha)
    end
end

local function ApplyPlate(fin, look)
    local tex, parent = fin.tex, fin.parent
    local w = tex:GetWidth() or 0
    local bs = fin.shapeOnly and 0 or max(0, min(look.bs, w < 26 and 2 or 4))
    local round = look.round
    local g = HHT.db and HHT.db.general
    local glow = not fin.shapeOnly and g and g.borderGlow and true or false
    SetRound(tex, parent, round)
    local p = fin.plate
    if not p then
        if bs == 0 and not glow then return end
        p = { all = {}, halo = {} }
        p.edge = parent:CreateTexture(nil, "BORDER", nil, -7)
        p.all[1] = p.edge
        fin.plate = p
    end
    for _, t in ipairs(p.all) do t.want = false end

    p.edge:ClearAllPoints()
    p.edge:SetPoint("TOPLEFT", tex, "TOPLEFT", -bs, bs)
    p.edge:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", bs, -bs)
    p.edge:SetColorTexture(look.r, look.g, look.b, 1)
    SetRound(p.edge, parent, round)
    p.edge.want = bs > 0

    if glow then
        local layers = HHT.GlowLayers()
        if round then
            for i = 1, layers do
                local t = p.halo[i]
                if not t then
                    t = parent:CreateTexture(nil, "BORDER", nil, -8)
                    t:SetTexture(WHITE)
                    p.halo[i] = t
                    p.all[#p.all + 1] = t
                end
                local d = bs + i
                t:ClearAllPoints()
                t:SetPoint("TOPLEFT", tex, "TOPLEFT", -d, d)
                t:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", d, -d)
                t:SetVertexColor(look.r, look.g, look.b, HHT.GlowAlpha(i, layers))
                SetRound(t, parent, true)
                t.want = true
            end
        else
            if not p.box then
                p.box = HHT.NewGlowBox(parent, "BORDER")
                for _, t in ipairs(p.box) do p.all[#p.all + 1] = t end
            end
            HHT.PlaceGlowBox(p.box, tex, bs, layers)
            HHT.ShowGlowBox(p.box, true, look.r, look.g, look.b)
            for _, t in ipairs(p.box) do t.want = true end
        end
    end
    SyncPlate(fin)
end

local function ApplyAttached(fin, look)
    fin.round = look.round
    Icon.ApplyFinish(fin, fin.size or fin.tex:GetWidth() or 0, look.round, 0)
    ApplyPlate(fin, look)
end

-- Gives an icon texture (popups, lists, menus) the general look: shape, border, border colour, glow and style.
-- plain = true applies only the style (menus and lists keep square icons); plain = "shape" adds the shape but no border
-- or glow (popups). Show, Hide, SetShown and SetAlpha are mirrored to the overlay.
function Icon.Attach(tex, plain)
    if tex.hhtFin then return tex.hhtFin end
    local parent = tex:GetParent()
    local host = CreateFrame("Frame", nil, parent)
    host:SetAllPoints(tex)
    host:SetFrameLevel(parent:GetFrameLevel() + 2)
    local fin = Icon.NewFinish(host, nil)
    fin.tex, fin.parent, fin.plain = tex, parent, plain == true
    fin.shapeOnly = plain == "shape"
    fin.shown, fin.alpha = tex:IsShown() and true or false, tex:GetAlpha() or 1
    local function Apply(w)
        if not (w and w > 0) then return end
        fin.size = w
        if fin.plain then Icon.ApplyFinish(fin, w, false, 0) else ApplyAttached(fin, CurrentLook()) end
    end
    host:SetScript("OnSizeChanged", function(_, w) Apply(w) end)
    Apply(tex:GetWidth())
    local show, hide, setShown, setAlpha = tex.Show, tex.Hide, tex.SetShown, tex.SetAlpha
    local function Visible(v)
        v = v and true or false
        if fin.shown ~= v then fin.shown = v; SyncPlate(fin) end
    end
    tex.Show = function(self, ...) host:Show(); Visible(true); return show(self, ...) end
    tex.Hide = function(self, ...) host:Hide(); Visible(false); return hide(self, ...) end
    tex.SetShown = function(self, v, ...) host:SetShown(v and true or false); Visible(v); return setShown(self, v, ...) end
    tex.SetAlpha = function(self, a, ...)
        host:SetAlpha(a)
        if fin.alpha ~= a then fin.alpha = a; SyncPlate(fin) end
        return setAlpha(self, a, ...)
    end
    tex.hhtFin = fin
    return fin
end

-- Re-applies the finish and the look everywhere after the general style changed.
function Icon.RefreshFinish()
    local look = CurrentLook()
    for fin in pairs(finishes) do
        if fin.tex and not fin.plain then
            pcall(ApplyAttached, fin, look)
        elseif fin.size then
            pcall(Icon.ApplyFinish, fin, fin.size, fin.round, fin.bs)
        end
    end
end

local methods = {}

-- opts: size, shape ("square"/"round"), borderSize (0 = none), borderAlpha (0..1), numbers (bool)
function methods:Style(size, shape, borderSize, borderAlpha, numbers)
    size = size or 36
    local round = (shape == "round")
    local bs = max(0, min(4, borderSize or 1))
    self:SetSize(size, size)
    self.border:ClearAllPoints()
    self.border:SetPoint("TOPLEFT", self, "TOPLEFT", -bs, bs)
    self.border:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", bs, -bs)
    self.border:SetShown(bs > 0)
    self.border:SetAlpha(borderAlpha or 1)
    SetRound(self.tex, self, round)
    SetRound(self.border, self, round)
    SetRound(self.flash, self, round)
    Icon.ApplyFinish(self.fin, size, round, bs)
    SetSwipeRound(self.cool, round)
    self:ApplyHalo(bs, round)
    pcall(self.cool.SetHideCountdownNumbers, self.cool, numbers == false)
    SetFont(self.text, max(8, floor(size * 0.42)), self)
    SetFont(self.count, max(8, floor(size * 0.30)), self)
    SetFont(self.label, max(8, min(12, floor(size * 0.28))), self)
    if self.keySize then SetFont(self.key, self.keySize, self) end
    self.round = round
end

function methods:SetBorderColor(r, g, b)
    self.border:SetColorTexture(r, g, b, 1)
    if self.halo and (self.haloR ~= r or self.haloG ~= g or self.haloB ~= b) then
        for _, t in ipairs(self.halo) do t:SetVertexColor(r, g, b, t.haloA or 0) end
        if self.haloBox and self.haloBox[1]:IsShown() then HHT.ShowGlowBox(self.haloBox, true, r, g, b) end
    end
    self.haloR, self.haloG, self.haloB = r, g, b
end

-- Soft glow around the border in the border colour. Round icons stack outlines that fade outwards,
-- square ones use a soft-edged texture. Its reach is the general setting borderGlowSize (see HHT.GlowLayers).
function methods:ApplyHalo(bs, round)
    local g = HHT.db and HHT.db.general
    local on = g and g.borderGlow
    local halo = self.halo
    if not (on or halo) then return end
    halo = halo or {}
    self.halo = halo
    self.haloBox = self.haloBox or HHT.NewGlowBox(self)
    local r, gr, b = self.haloR or 0.55, self.haloG or 0.42, self.haloB or 0.2
    local layers = HHT.GlowLayers()
    if on and not round then HHT.PlaceGlowBox(self.haloBox, self, bs, layers) end
    HHT.ShowGlowBox(self.haloBox, on and not round, r, gr, b)
    for i = 1, HHT.GLOW_MAX do
        local t = halo[i]
        if not t then
            t = self:CreateTexture(nil, "BACKGROUND", nil, -8)
            t:SetTexture(WHITE)
            halo[i] = t
        end
        if on and round and i <= layers then
            local d = bs + i
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", self, "TOPLEFT", -d, d)
            t:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", d, -d)
            t.haloA = HHT.GlowAlpha(i, layers)
            t:SetVertexColor(r, gr, b, t.haloA)
            SetRound(t, self, round)
            t:Show()
        else
            t:Hide()
        end
    end
end

function methods:SetIcon(tex)
    self.tex:SetTexture(tex)
end

-- Glow for a frame that is not an Icon (e.g. an engine-made aura button), in the colour r, g, b.
function Icon.ApplyHaloTo(frame, bs, round, r, g, b)
    frame.haloR, frame.haloG, frame.haloB = r, g, b
    methods.ApplyHalo(frame, bs, round)
end

function methods:SetDesaturated(on)
    self.tex:SetDesaturated(on and true or false)
end

-- Colours the icon texture (usable hint); 1,1,1 is normal.
function methods:SetTint(r, g, b)
    if self.tintR == r and self.tintG == g and self.tintB == b then return end
    self.tintR, self.tintG, self.tintB = r, g, b
    self.tex:SetVertexColor(r, g, b)
end

function methods:ShowCooldown(durObj)
    if not durObj then self.cool:Clear(); return false end
    if pcall(self.cool.SetCooldownFromDurationObject, self.cool, durObj, true) then return true end
    return false
end

function methods:ClearCooldown()
    self.cool:Clear()
end

-- Reverse swipe: the lit part is the remaining time and the elapsed part greys out (for timed buffs and summons).
function methods:SetReverse(on)
    if self.reverse == on then return end
    self.reverse = on
    self.cool:SetReverse(on and true or false)
end

-- Static timer: start/duration in plain numbers (not secret)
function methods:SetTimer(start, duration)
    self.cool:SetCooldown(start, duration)
end

local KEY_ANCHOR = {
    TOPLEFT = { 2, -2 }, TOPRIGHT = { -2, -2 }, CENTER = { 0, 0 }, BOTTOMLEFT = { 2, 2 }, BOTTOMRIGHT = { -2, 2 },
}

-- Small bind text on the icon; empty text hides it. Only touches the font string when something changed.
function methods:SetKey(text, size, pos, r, g, b)
    local fs = self.key
    if not text or text == "" then
        if self.keyText ~= "" then fs:SetText(""); self.keyText = "" end
        return
    end
    size = size or 12
    pos = KEY_ANCHOR[pos] and pos or "TOPRIGHT"
    if self.keySize ~= size then SetFont(fs, size, self); self.keySize = size end
    if self.keyPos ~= pos then
        local a = KEY_ANCHOR[pos]
        fs:ClearAllPoints()
        fs:SetPoint(pos, self, pos, a[1], a[2])
        self.keyPos = pos
    end
    fs:SetTextColor(r or 1, g or 1, b or 0.4)
    if self.keyText ~= text then fs:SetText(text); self.keyText = text end
end

function methods:Flash()
    self.flashT = 0
    self.flash:SetAlpha(0.75)
    self.flash:Show()
    self.fxf:Show()
end

function methods:SetBlink(on, speed)
    if on then
        self.blinkSpeed = speed or 5
        if not self.blinking then
            self.blinking = true
            self.blinkT = 0
            self.over:SetScript("OnUpdate", function(_, dt)
                self.blinkT = self.blinkT + dt * self.blinkSpeed
                self:SetAlpha(0.45 + 0.55 * (0.5 + 0.5 * sin(self.blinkT)))
            end)
        end
    elseif self.blinking then
        self.blinking = false
        self.over:SetScript("OnUpdate", nil)
        self:SetAlpha(1)
    end
end

function Icon.New(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(36, 36)

    f.border = f:CreateTexture(nil, "BACKGROUND")
    f.border:SetTexture(WHITE)
    f.border:SetVertexColor(1, 1, 1, 1)

    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints(f)
    f.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints(f)
    pcall(f.cool.SetDrawEdge, f.cool, false)
    pcall(f.cool.SetDrawBling, f.cool, false)
    f.fin = Icon.NewFinish(f, f.border)

    f.over = CreateFrame("Frame", nil, f)
    f.over:SetAllPoints(f)
    f.over:SetFrameLevel(f.cool:GetFrameLevel() + 2)

    f.flash = f.over:CreateTexture(nil, "OVERLAY")
    f.flash:SetAllPoints(f)
    f.flash:SetTexture(WHITE)
    f.flash:SetBlendMode("ADD")
    f.flash:Hide()
    f.flashT = 0
    f.fxf = CreateFrame("Frame", nil, f)
    f.fxf:Hide()
    f.fxf:SetScript("OnUpdate", function(self, dt)
        f.flashT = f.flashT + dt
        if f.flashT >= 0.5 then
            f.flash:Hide()
            self:Hide()
            return
        end
        f.flash:SetAlpha(0.75 * (1 - f.flashT / 0.5))
    end)
    f.text = f.over:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.count = f.over:CreateFontString(nil, "OVERLAY")
    f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 2)
    f.label = f.over:CreateFontString(nil, "OVERLAY")
    f.label:SetPoint("TOP", f, "BOTTOM", 0, -2)
    SetFont(f.text, 14); SetFont(f.count, 11); SetFont(f.label, 10)
    f.key = f.over:CreateFontString(nil, "OVERLAY")
    SetFont(f.key, 12)
    f.keyText = ""

    for k, v in pairs(methods) do f[k] = v end
    f:SetBorderColor(0.55, 0.42, 0.2)
    return f
end
