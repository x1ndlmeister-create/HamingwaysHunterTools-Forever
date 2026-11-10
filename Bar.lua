-- Shared status bar look: texture choice, 3D bevel, border, spark, label/time texts.
local ADDON, HHT = ...
local UI = HHT.UI
local L = HHT.L

local Bar = {}
HHT.Bar = Bar

local WHITE = "Interface\\Buttons\\WHITE8X8"
local SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark"

Bar.TEXTURES = {
    flat = WHITE,
    blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
    raid = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    smooth = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
}

HHT:AddGerman({
    ["Bar texture"] = "Balkentextur",
    ["Flat"] = "Flach",
    ["Smooth"] = "Weich",
    ["3D effect strength"] = "3D-Effekt Staerke",
})

function Bar.TextureChoices()
    return {
        { "flat", L("Flat") }, { "blizzard", "Blizzard" }, { "raid", "Raid" }, { "smooth", L("Smooth") },
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

    row.label = UI.Text(row.fx, "", 11)
    row.label:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.label:SetJustifyH("LEFT")
    row.time = UI.Text(row.fx, "", 11)
    row.time:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    return row
end

-- db: width, height, bgAlpha, border, barTexture, bevel, showLabel, showTime, colors{bg,edge,text,<fillKey>}
function Bar.Apply(row, db, fillKey)
    local h = db.height
    row:SetSize(db.width, h)
    row.bg:SetVertexColor(HHT.Col(db, "bg"))
    row.bg:SetAlpha(db.bgAlpha)
    row.edge:SetColor(HHT.Col(db, "edge"))
    for i = 1, 4 do row.edge[i]:SetShown(db.border) end
    row.bar:SetStatusBarTexture(Bar.TEXTURES[db.barTexture or "blizzard"] or WHITE)
    if fillKey then row.bar:SetStatusBarColor(HHT.Col(db, fillKey)) end

    local bevel = db.bevel or 0
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
    row.label:SetTextColor(HHT.Col(db, "text"))
    row.time:SetTextColor(HHT.Col(db, "text"))
    local fs = math.max(8, math.min(14, h - 4))
    row.label:SetFont(UI.FONT, fs, "OUTLINE")
    row.time:SetFont(UI.FONT, fs, "OUTLINE")
    row.spark:SetHeight(h * 2)
end

-- Shared option rows for bar look.
function Bar.AddOptions(form, db)
    form:Cycle(L("Bar texture"), db, "barTexture", Bar.TextureChoices())
    form:Stepper(L("3D effect strength"), db, "bevel", 0, 1, 0.1)
end
