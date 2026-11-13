-- Shared status bar look: texture choice, 3D bevel, border, spark, label/time texts.
local ADDON, HHT = ...
local UI = HHT.UI
local L = HHT.L

local Bar = {}
HHT.Bar = Bar

Bar.FLASH_TIME = 0.5

local WHITE = "Interface\\Buttons\\WHITE8X8"
local SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark"

Bar.TEXTURES = {
    flat = WHITE,
    glass = WHITE,
    blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
    raid = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    smooth = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
}

HHT:AddGerman({
    ["Bar texture"] = "Balkentextur",
    ["Flat"] = "Flach",
    ["Smooth"] = "Weich",
    ["Glass"] = "Glas",
    ["3D effect strength"] = "3D-Effekt Staerke",
    ["Smooth bar movement"] = "Weiche Balkenbewegung",
    ["Center"] = "Mitte",
    ["Label position"] = "Position der Beschriftung",
    ["Time position"] = "Position der Restzeit",
    ["Flash when full"] = "Aufblinken bei 100 %",
    ["Flash glow strength"] = "Staerke des Flash-Leuchtens",
    ["Flash glow size"] = "Groesse des Flash-Leuchtens",
})

function Bar.TextureChoices()
    return {
        { "flat", L("Flat") }, { "glass", L("Glass") }, { "blizzard", "Blizzard" }, { "raid", "Raid" }, { "smooth", L("Smooth") },
    }
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

function Bar.New(parent)
    local row = CreateFrame("Frame", nil, parent)
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

local function PlaceText(fs, pos, row)
    local t = TEXT_POINT[pos] or TEXT_POINT.left
    fs:ClearAllPoints()
    fs:SetPoint(t[1], row, t[1], t[2], 0)
    fs:SetJustifyH(t[1])
end
function Bar.Apply(row, db, fillKey)
    row.db = db
    local h = db.height
    row:SetSize(db.width, h)
    row.bg:SetVertexColor(HHT.Col(db, "bg"))
    row.bg:SetAlpha(db.bgAlpha)
    row.edge:SetColor(HHT.Col(db, "edge"))
    for i = 1, 4 do row.edge[i]:SetShown(db.border) end
    row.bar:SetStatusBarTexture(Bar.TEXTURES[db.barTexture or "blizzard"] or WHITE)
    row.bar.hhtSmooth = db.smooth and true or false
    if fillKey then row.bar:SetStatusBarColor(HHT.Col(db, fillKey)) end

    local bevel = db.bevel or 0
    local g = HHT.db and HHT.db.general
    local level = ({ bevel = 0.5, glass = 0.9 })[g and g.style or "flat"] or 0
    bevel = math.max(bevel, level)
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
    PlaceText(row.label, db.labelPos or "left", row)
    PlaceText(row.time, db.timePos or "right", row)
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
    form:Stepper(L("3D effect strength"), db, "bevel", 0, 1, 0.1)
    db.labelPos = db.labelPos or "left"
    db.timePos = db.timePos or "right"
    local pos = { { "left", L("Left") }, { "center", L("Center") }, { "right", L("Right") } }
    form:Cycle(L("Label position"), db, "labelPos", pos)
    form:Cycle(L("Time position"), db, "timePos", pos)
end

function Bar.AddSmooth(form, db)
    form:Check(L("Smooth bar movement"), db, "smooth")
end

-- Short pulse in a brightened bar colour plus an outer glow, e.g. when a bar reaches 100 %.
function Bar.Flash(row)
    if not UI.Anim() then return end
    local r, g, b = row.bar:GetStatusBarColor()
    r, g, b = tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1
    local s = 1 / math.max(r, g, b, 0.1)
    r, g, b = math.min(1, r * s * 0.8 + 0.2), math.min(1, g * s * 0.8 + 0.2), math.min(1, b * s * 0.8 + 0.2)
    row.flashTex:SetVertexColor(r, g, b)
    local db = row.db or {}
    local gStr, gSize = db.flashGlow or 1, db.flashGlowSize or 8
    for _, t in ipairs(row.glow) do
        local k = 1 - (t.ring - 0.5) / math.max(gSize, 1)
        if gStr <= 0 or t.ring > gSize or k <= 0 then
            t:Hide()
        else
            t:SetVertexColor(r, g, b, math.min(1, 0.9 * gStr * k * k))
            t:Show()
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
