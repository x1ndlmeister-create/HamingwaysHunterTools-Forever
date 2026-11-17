-- Shared status bar look: texture choice, 3D bevel, border, spark, label/time texts.
local ADDON, HHT = ...
local UI = HHT.UI
local L = HHT.L

local Bar = {}
HHT.Bar = Bar

Bar.FLASH_TIME = 0.5

local WHITE = "Interface\\Buttons\\WHITE8X8"
local SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark"
local MASK = "Interface\\AddOns\\" .. ADDON .. "\\Media\\BarMask"
local MASK_RATIOS = { 2, 4, 8, 16, 32 }

-- The rounded-bar masks come in a few width-to-height ratios; the closest one keeps the end caps nearly round.
local function MaskFile(w, h)
    local r = w / math.max(h, 1)
    local best, bd = MASK_RATIOS[1], math.huge
    for _, v in ipairs(MASK_RATIOS) do
        local d = math.abs(math.log(r / v))
        if d < bd then best, bd = v, d end
    end
    return MASK .. best
end

-- Clips a texture to a rounded bar shape that follows region (nil turns the clipping off).
local function Clip(tex, region, w, h)
    local owner = tex:GetParent()
    if not (tex.AddMaskTexture and owner and owner.CreateMaskTexture) then return end
    if region then
        local m = tex.hhtMask
        if not m then
            m = owner:CreateMaskTexture()
            tex.hhtMask = m
        end
        m:SetTexture(MaskFile(w, h), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        m:ClearAllPoints()
        m:SetAllPoints(region)
        if not tex.hhtOn then tex:AddMaskTexture(m); tex.hhtOn = true end
    elseif tex.hhtOn then
        tex:RemoveMaskTexture(tex.hhtMask)
        tex.hhtOn = false
    end
end

Bar.TEXTURES = {
    flat = WHITE,
    glass = WHITE,
    blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
    raid = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    smooth = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
}

HHT:AddGerman({
    ["Bar texture"] = "Balkentextur",
    ["Bar corners"] = "Leistenecken",
    ["Rounded"] = "Abgerundet",
    ["Flat"] = "Flach",
    ["Smooth"] = "Weich",
    ["Glass"] = "Glas",
    ["3D effect strength"] = "3D-Effekt Stärke",
    ["Smooth bar movement"] = "Weiche Balkenbewegung",
    ["Center"] = "Mitte",
    ["Label position"] = "Position der Beschriftung",
    ["Time position"] = "Position der Restzeit",
    ["Flash when full"] = "Aufblinken bei 100 %",
    ["Flash glow strength"] = "Stärke des Flash-Leuchtens",
    ["Flash glow size"] = "Größe des Flash-Leuchtens",
})

function Bar.TextureChoices()
    return {
        { "flat", L("Flat") }, { "glass", L("Glass") }, { "blizzard", "Blizzard" }, { "raid", "Raid" }, { "smooth", L("Smooth") },
    }
end

function Bar.ShapeChoices()
    return { { "square", L("Square") }, { "round", L("Rounded") } }
end

local CIRCLE = "Interface\\AddOns\\" .. ADDON .. "\\Media\\RoundRing"

-- A ring (or rectangular frame) around a bar, `a` pixels away from it and `th` pixels thick: the middle is empty,
-- so it never shows through a transparent bar. Rounded bars use two half rings (a ring texture is chosen by the
-- ratio of inner to outer radius, 0.70 - 0.98) plus strips on top and bottom. Pieces: 1/3 end caps, 2/4 top and
-- bottom strips, 5/6 side strips (square bars only).
local function NewRing(row, layer, sub)
    local p = {}
    for k = 1, 6 do
        local t = row:CreateTexture(nil, layer, nil, sub)
        t:SetTexture(WHITE)
        t:Hide()
        p[k] = t
    end
    p[1]:SetTexCoord(0, 0.5, 0, 1)
    p[3]:SetTexCoord(0.5, 1, 0, 1)
    return p
end

local function PlaceRing(p, row, a, th, h, rounded)
    local o = a + th
    local r = h / 2
    local function Put(t, p1, r1, x1, y1, p2, r2, x2, y2)
        t:ClearAllPoints()
        t:SetPoint(p1, row, r1, x1, y1)
        t:SetPoint(p2, row, r2, x2, y2)
    end
    if rounded then
        local q = math.max(0.70, math.min(0.98, math.floor((r + a) / (r + o) * 50 + 0.5) / 50))
        local file = CIRCLE .. math.floor(q * 100 + 0.5)
        p[1]:SetTexture(file); p[3]:SetTexture(file)
        Put(p[1], "TOPLEFT", "TOPLEFT", -o, o, "BOTTOMRIGHT", "BOTTOMLEFT", r, -o)
        Put(p[3], "TOPLEFT", "TOPRIGHT", -r, o, "BOTTOMRIGHT", "BOTTOMRIGHT", o, -o)
        Put(p[2], "TOPLEFT", "TOPLEFT", r, o, "BOTTOMRIGHT", "TOPRIGHT", -r, a)
        Put(p[4], "TOPLEFT", "BOTTOMLEFT", r, -a, "BOTTOMRIGHT", "BOTTOMRIGHT", -r, -o)
    else
        Put(p[2], "TOPLEFT", "TOPLEFT", -o, o, "BOTTOMRIGHT", "TOPRIGHT", o, a)
        Put(p[4], "TOPLEFT", "BOTTOMLEFT", -o, -a, "BOTTOMRIGHT", "BOTTOMRIGHT", o, -o)
        Put(p[5], "TOPLEFT", "TOPLEFT", -o, a, "BOTTOMRIGHT", "BOTTOMLEFT", -a, -a)
        Put(p[6], "TOPLEFT", "TOPRIGHT", a, a, "BOTTOMRIGHT", "BOTTOMRIGHT", o, -a)
    end
end

local function ShowRing(p, rounded, on, r, g, b, a)
    for k = 1, 6 do
        p[k]:SetVertexColor(r, g, b, a)
        local used = (k == 2 or k == 4) or (rounded and (k == 1 or k == 3)) or (not rounded and (k == 5 or k == 6))
        p[k]:SetShown(on and used and true or false)
    end
end

-- Vertical alpha gradient of one colour (bottom alpha -> top alpha).
local function Grad(tex, r, g, b, aBottom, aTop)
    tex:SetTexture(WHITE)
    if tex.SetGradient and CreateColor then
        pcall(tex.SetGradient, tex, "VERTICAL", CreateColor(r, g, b, aBottom), CreateColor(r, g, b, aTop))
    elseif tex.SetGradientAlpha then
        tex:SetGradientAlpha("VERTICAL", r, g, b, aBottom, r, g, b, aTop)
    else
        tex:SetVertexColor(r, g, b, (aBottom + aTop) / 2)
    end
end

local bars = setmetatable({}, { __mode = "k" })

function Bar.New(parent)
    local row = CreateFrame("Frame", nil, parent)
    bars[row] = true
    row.rim = NewRing(row, "BACKGROUND", -1)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(WHITE)
    row.edge = UI.Border(row, 1, 1, 1, 1)

    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetPoint("TOPLEFT", 1, -1)
    row.bar:SetPoint("BOTTOMRIGHT", -1, 1)
    row.bar:SetStatusBarTexture(WHITE)
    row.bar:SetMinMaxValues(0, 1)
    row.bar:SetValue(1)

    -- Optional eased fill: SetValue moves toward the target; secret or non-number values are set directly.
    local sb = row.bar
    local rawSet = sb.SetValue
    local function Ease(self, dt)
        local cur, tgt = self.hhtCur, self.hhtTarget
        if not (cur and tgt) then self:SetScript("OnUpdate", nil); return end
        local lo, hi = self:GetMinMaxValues()
        local span = HHT.SafeNumber(hi) and HHT.SafeNumber(lo) and (hi - lo) or 1
        local d = tgt - cur
        if math.abs(d) <= span * 0.004 then
            cur = tgt
            self.hhtCur, self.hhtTarget = nil, nil
            self:SetScript("OnUpdate", nil)
        else
            cur = cur + d * math.min(1, dt * 12)
            self.hhtCur = cur
        end
        rawSet(self, cur)
    end
    function sb:SetValue(v)
        local n = self.hhtSmooth and HHT.SafeNumber(v)
        if not n then
            self.hhtCur, self.hhtTarget = nil, nil
            if self:GetScript("OnUpdate") == Ease then self:SetScript("OnUpdate", nil) end
            return rawSet(self, v)
        end
        if not self.hhtCur then
            local ok, now = pcall(self.GetValue, self)
            now = ok and HHT.SafeNumber(now) or n
            self.hhtCur = now
        end
        self.hhtTarget = n
        self:SetScript("OnUpdate", Ease)
    end

    -- effects sit above the fill
    row.fx = CreateFrame("Frame", nil, row.bar)
    row.fx:SetAllPoints(row.bar)
    row.fx:SetFrameLevel(row.bar:GetFrameLevel() + 1)
    row.shine = row.fx:CreateTexture(nil, "ARTWORK")
    row.shine:SetPoint("TOPLEFT")
    row.shine:SetPoint("TOPRIGHT")
    row.shade = row.fx:CreateTexture(nil, "ARTWORK")
    row.shade:SetPoint("BOTTOMLEFT")
    row.shade:SetPoint("BOTTOMRIGHT")
    row.lit = row.fx:CreateTexture(nil, "OVERLAY")
    row.lit:SetPoint("TOPLEFT")
    row.lit:SetPoint("TOPRIGHT")
    row.lit:SetHeight(1)
    row.lit:SetTexture(WHITE)

    row.spark = row.fx:CreateTexture(nil, "OVERLAY")
    row.spark:SetTexture(SPARK)
    row.spark:SetBlendMode("ADD")
    row.spark:SetWidth(14)

    row.flashTex = row.fx:CreateTexture(nil, "OVERLAY", nil, 2)
    row.flashTex:SetAllPoints()
    row.flashTex:SetTexture(WHITE)
    row.flashTex:SetBlendMode("ADD")
    row.flashTex:Hide()
    row.flashT = 0
    row.flashF = CreateFrame("Frame", nil, row)
    row.flashF:Hide()
    -- Coloured glow outside the bar: nested 1px rings fade outwards and keep the corners filled.
    row.glow = {}
    local GLOW = 12
    for i = 1, GLOW do
        local d = i - 1
        local function Ring(p1, r1, x1, y1, p2, r2, x2, y2, horizontal)
            local t = row.flashF:CreateTexture(nil, "OVERLAY")
            t:SetPoint(p1, row, r1, x1, y1)
            t:SetPoint(p2, row, r2, x2, y2)
            if horizontal then t:SetHeight(1) else t:SetWidth(1) end
            t:SetTexture(WHITE)
            t:SetBlendMode("ADD")
            t.ring = i
            row.glow[#row.glow + 1] = t
        end
        Ring("BOTTOMLEFT", "TOPLEFT", -i, d, "BOTTOMRIGHT", "TOPRIGHT", i, d, true)
        Ring("TOPLEFT", "BOTTOMLEFT", -i, -d, "TOPRIGHT", "BOTTOMRIGHT", i, -d, true)
        Ring("TOPRIGHT", "TOPLEFT", -d, d, "BOTTOMRIGHT", "BOTTOMLEFT", -d, -d, false)
        Ring("TOPLEFT", "TOPRIGHT", d, d, "BOTTOMLEFT", "BOTTOMRIGHT", d, -d, false)
    end
    row.flashF:SetScript("OnUpdate", function(self, dt)
        row.flashT = row.flashT + dt
        local k = row.flashT / Bar.FLASH_TIME
        if k >= 1 then
            row.flashTex:Hide()
            self:Hide()
            return
        end
        local a = k < 0.2 and k / 0.2 or (1 - k) / 0.8
        row.flashTex:SetAlpha(0.8 * a)
        self:SetAlpha(a)
    end)

    row.label = UI.Text(row.fx, "", 11)
    row.label:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.label:SetJustifyH("LEFT")
    row.time = UI.Text(row.fx, "", 11)
    row.time:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    return row
end

-- db: width, height, bgAlpha, border, barTexture, bevel, showLabel, showTime, colors{bg,edge,text,<fillKey>}
local TEXT_POINT = { left = { "LEFT", 5 }, center = { "CENTER", 0 }, right = { "RIGHT", -5 } }

local function PlaceText(fs, pos, row, pad)
    local t = TEXT_POINT[pos] or TEXT_POINT.left
    local off = t[2]
    if pad and off ~= 0 then off = off < 0 and -pad or pad end
    fs:ClearAllPoints()
    fs:SetPoint(t[1], row, t[1], off, 0)
    fs:SetJustifyH(t[1])
end

local FX_TEXTURES = { "shine", "shade", "lit", "spark", "flashTex" }

-- Border thickness in pixels: the border switch turns it off, otherwise borderSize (older settings: 1 px).
local function BorderSize(db)
    if db.border == false then return 0 end
    return math.max(0, math.min(4, db.borderSize or 1))
end

-- Rounds a thickness to whole screen pixels. A border of fractional pixels would come out 1 or 2 pixels thick
-- depending on where on the screen the bar sits, so two identical bars could look different.
local function ScreenHeight()
    if GetPhysicalScreenSize then return select(2, GetPhysicalScreenSize()) end
    local res = GetCVar and GetCVar("gxWindowedResolution") or GetCVar("gxResolution")
    return res and tonumber(res:match("x(%d+)"))
end

local function SnapPx(row, v)
    if v <= 0 then return 0 end
    local ph = ScreenHeight()
    local es = row:GetEffectiveScale()
    if not (ph and ph > 0 and es and es > 0) then return v end
    local px = 768 / ph / es
    return math.max(1, math.floor(v / px + 0.5)) * px
end

-- Soft glow around the border: a soft-edged texture in the border colour, fading outwards.
-- Its reach is the general setting borderGlowSize (see HHT.GlowLayers).
local function ApplyHalo(row, db, on, rounded, bs)
    if not (on or row.haloBox) then return end
    row.haloBox = row.haloBox or HHT.NewGlowBox(row)
    row.haloPill = row.haloPill or HHT.NewGlowPill(row)
    local r, g, b = HHT.Col(db, "edge")
    local layers = HHT.GlowLayers()
    if on and rounded then
        HHT.PlaceGlowPill(row.haloPill, row, bs, layers, db.height)
    elseif on then
        HHT.PlaceGlowBox(row.haloBox, row, bs, layers)
    end
    HHT.ShowGlowBox(row.haloBox, on and not rounded, r, g, b)
    HHT.ShowGlowPill(row.haloPill, on and rounded, r, g, b)
end

-- Square or rounded bar: the border is a ring around the bar. Rounded bars clip the background, fill and
-- effects to a pill shape.
local function ApplyShape(row, db, rounded)
    local w, h = db.width, db.height
    local bs = SnapPx(row, BorderSize(db))
    row.rounded = rounded
    row.lit:SetHeight(SnapPx(row, 1))
    for i = 1, 4 do row.edge[i]:Hide() end
    -- the border grows outwards, so the bar keeps its width and height
    local er, eg, eb = HHT.Col(db, "edge")
    if bs > 0 then PlaceRing(row.rim, row, 0, bs, h, rounded) end
    ShowRing(row.rim, rounded, bs > 0, er, eg, eb, 1)
    row.bg:ClearAllPoints()
    row.bg:SetAllPoints(row)
    row.bar:ClearAllPoints()
    row.bar:SetAllPoints(row)
    if rounded then
        Clip(row.bg, row.bg, w, h)
        Clip(row.bar:GetStatusBarTexture(), row.bar, w, h)
        for _, k in ipairs(FX_TEXTURES) do Clip(row[k], row.fx, w, h) end
    else
        Clip(row.bg)
        Clip(row.bar:GetStatusBarTexture())
        for _, k in ipairs(FX_TEXTURES) do Clip(row[k]) end
    end
    local g = HHT.db and HHT.db.general
    ApplyHalo(row, db, g and g.borderGlow, rounded, bs)
end

-- Borders are snapped to whole screen pixels, which depends on the scale: redo it after a scale change.
function Bar.ResnapAll()
    for row in pairs(bars) do
        if row.db then pcall(ApplyShape, row, row.db, row.rounded) end
    end
end

function Bar.Apply(row, db, fillKey)
    row.db = db
    local h = db.height
    row:SetSize(db.width, h)
    row.bg:SetVertexColor(HHT.Col(db, "bg"))
    row.bg:SetAlpha(db.bgAlpha)
    row.bar:SetStatusBarTexture(Bar.TEXTURES[db.barTexture or "blizzard"] or WHITE)
    row.bar.hhtSmooth = db.smooth and true or false
    if fillKey then row.bar:SetStatusBarColor(HHT.Col(db, fillKey)) end
    ApplyShape(row, db, db.barShape == "round")

    -- The general style sets the strength of the 3D effect; a module's own setting scales it (0.6 is the default).
    local g = HHT.db and HHT.db.general
    local level = ({ bevel = 0.6, glass = 1 })[g and g.style or "flat"] or 0
    local bevel = math.min(1, level * (db.bevel or 0.6) / 0.6)
    if db.barTexture == "glass" then bevel = math.max(bevel, 0.9) end
    local inner = math.max(2, h - 2)
    row.fx:SetShown(true)
    if bevel > 0 then
        row.shine:SetHeight(inner * 0.5)
        row.shade:SetHeight(inner * 0.5)
        Grad(row.shine, 1, 1, 1, 0, 0.30 * bevel)
        Grad(row.shade, 0, 0, 0, 0.38 * bevel, 0)
        row.lit:SetVertexColor(1, 1, 1, 0.35 * bevel)
        row.shine:Show(); row.shade:Show(); row.lit:Show()
    else
        row.shine:Hide(); row.shade:Hide(); row.lit:Hide()
    end

    row.label:SetShown(db.showLabel)
    row.time:SetShown(db.showTime)
    local pad = row.rounded and (math.floor(h / 3) + 4) or nil
    PlaceText(row.label, db.labelPos or "left", row, pad)
    PlaceText(row.time, db.timePos or "right", row, pad)
    row.label:SetTextColor(HHT.Col(db, "text"))
    row.time:SetTextColor(HHT.Col(db, "text"))
    local fs = math.max(8, math.min(14, h - 4))
    HHT.StyleFont(row.label, fs, row)
    HHT.StyleFont(row.time, fs, row)
    row.spark:SetHeight(h * 2)
end

-- Shared option rows for bar look.
function Bar.AddOptions(form, db)
    form:Cycle(L("Bar texture"), db, "barTexture", Bar.TextureChoices())
    form:Cycle(L("Bar corners"), db, "barShape", Bar.ShapeChoices())
    form:Stepper(L("3D effect strength"), db, "bevel", 0, 1, 0.1)
    db.labelPos = db.labelPos or "left"
    db.timePos = db.timePos or "right"
    local pos = { { "left", L("Left") }, { "center", L("Center") }, { "right", L("Right") } }
    form:Cycle(L("Label position"), db, "labelPos", pos)
    form:Cycle(L("Time position"), db, "timePos", pos)
end

-- Border thickness slider (0 = no border); keeps the older on/off switch in step.
function Bar.AddBorder(form, db)
    local proxy = setmetatable({}, {
        __index = function() return BorderSize(db) end,
        __newindex = function(_, _, v) db.borderSize = v; db.border = v > 0 end,
    })
    form:Stepper(L("Border size"), proxy, "size", 0, 4, 1)
end

-- Short pulse in a brightened bar colour plus an outer glow, e.g. when a bar reaches 100 %.
function Bar.Flash(row)
    local r, g, b = row.bar:GetStatusBarColor()
    r, g, b = tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1
    local s = 1 / math.max(r, g, b, 0.1)
    r, g, b = math.min(1, r * s * 0.8 + 0.2), math.min(1, g * s * 0.8 + 0.2), math.min(1, b * s * 0.8 + 0.2)
    row.flashTex:SetVertexColor(r, g, b)
    local db = row.db or {}
    local gStr, gSize = db.flashGlow or 1, db.flashGlowSize or 8
    for _, t in ipairs(row.glow) do
        local k = 1 - (t.ring - 0.5) / math.max(gSize, 1)
        if gStr <= 0 or t.ring > gSize or k <= 0 or row.rounded then
            t:Hide()
        else
            t:SetVertexColor(r, g, b, math.min(1, 0.9 * gStr * k * k))
            t:Show()
        end
    end
    -- Rounded bars glow with soft pill pieces instead of the square rings.
    local pillOn = row.rounded and gStr > 0 and gSize > 0
    if pillOn or row.flashPill then
        row.flashPill = row.flashPill or HHT.NewGlowPill(row.flashF, "OVERLAY")
        if pillOn then HHT.PlaceGlowPill(row.flashPill, row, 0, gSize, db.height or row:GetHeight()) end
        HHT.ShowGlowPill(row.flashPill, pillOn, r, g, b)
        if pillOn then
            local a = math.min(1, 0.9 * gStr)
            for _, t in ipairs(row.flashPill) do t:SetVertexColor(r, g, b, a) end
        end
    end
    row.flashT = 0
    row.flashF:SetAlpha(0)
    row.flashTex:SetAlpha(0)
    row.flashTex:Show()
    row.flashF:Show()
end

function Bar.AddFlash(form, db)
    form:Check(L("Flash when full"), db, "flash")
    form:Stepper(L("Flash glow strength"), db, "flashGlow", 0, 2, 0.25)
    form:Stepper(L("Flash glow size"), db, "flashGlowSize", 0, 12, 1)
end
