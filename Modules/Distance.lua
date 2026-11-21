-- Distance: shows how far the target is (bands up to 35 yd), melee and dead zone, as segments, an arc, a badge or text.
local ADDON, HHT = ...
local L, UI, Icon, Range, S = HHT.L, HHT.UI, HHT.Icon, HHT.Range, HHT.Spells

HHT:AddGerman({
    ["Distance"] = "Entfernung",
    ["Target distance in bands, melee and dead zone."] = "Zielentfernung in Stufen, Nahkampf und toter Winkel.",
    ["Layout"] = "Darstellung",
    ["Segments"] = "Segmente",
    ["Text only"] = "Nur Text",
    ["Badge"] = "Symbol",
    ["Arc (narrow)"] = "Bogen (schmal)",
    ["Arc (wide)"] = "Bogen (breit)",
    ["Direction"] = "Richtung",
    ["Left to right"] = "Links nach rechts",
    ["Right to left"] = "Rechts nach links",
    ["Bottom to top"] = "Unten nach oben",
    ["Top to bottom"] = "Oben nach unten",
    ["Distance shown as segments"] = "Entfernung als Segmente",
    ["Size"] = "Größe",
    ["Show text"] = "Text zeigen",
    ["Pulse in the dead zone"] = "Pulsieren im toten Winkel",
    ["Sound when entering the dead zone"] = "Ton beim Eintritt in den toten Winkel",
    ["Melee"] = "Nahkampf",
    ["Dead zone"] = "Toter Winkel",
    ["Max range"] = "Maximale Reichweite",
    ["Too far"] = "Zu weit",
    ["Melee color"] = "Farbe Nahkampf",
    ["Dead zone color"] = "Farbe toter Winkel",
    ["Near color (up to 15 yd)"] = "Farbe nah (bis 15 m)",
    ["Middle color (up to 25 yd)"] = "Farbe mittel (bis 25 m)",
    ["Far color (up to 35 yd)"] = "Farbe weit (bis 35 m)",
    ["Max range color"] = "Farbe maximale Reichweite",
    ["Out of range color"] = "Farbe außer Reichweite",
})

local M = HHT:NewModule("distance", {
    name = "Distance",
    desc = "Target distance in bands, melee and dead zone.",
    positions = { main = { "CENTER", "CENTER", 0, -60 } },
    defaults = {
        layout = "segments", direction = "ltr", size = 48, shape = "round", visibility = "target",
        showText = true, pulse = true, sound = false,
        colors = {
            melee = { 0.95, 0.35, 0.30 },
            dead = { 0.90, 0.15, 0.15 },
            near = { 0.95, 0.55, 0.15 },
            mid = { 0.95, 0.80, 0.20 },
            far = { 0.67, 0.83, 0.45 },
            max = { 0.30, 0.80, 0.90 },
            oor = { 0.60, 0.40, 0.80 },
        },
    },
})

local WHITE = "Interface\\Buttons\\WHITE8X8"
local SKULL = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
local ARC_DIR = "Interface\\AddOns\\" .. ADDON .. "\\Media\\DistArc"
local SEGMENTS = 7
-- width / height of each arc texture, and its height relative to the size setting
local ARCS = { arcn = { "N", 1, 2.5 }, arcw = { "W", 2, 1.5 } }

local COLOR_OF = {
    MELEE = "melee", DEAD = "dead", Y10 = "near", Y15 = "near", Y20 = "mid", Y25 = "mid",
    Y30 = "far", Y35 = "far", MAX = "max", FAR = "oor",
}
local LIT_OF = { MELEE = 0, DEAD = 0, Y10 = 1, Y15 = 2, Y20 = 3, Y25 = 4, Y30 = 5, Y35 = 6, MAX = 7, FAR = 0 }

local function Label(band)
    if band == "MELEE" then return L("Melee") end
    if band == "DEAD" then return L("Dead zone") end
    if band == "MAX" then return L("Max range") end
    if band == "FAR" then return L("Too far") end
    return "< " .. band:sub(2) .. " yd"
end

function M:OnInit()
    self.band = nil
    self.flip = false
    HHT:Every(self, 0.15, M.Tick)
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsDistance", UIParent)
    f:SetSize(120, 60)
    self.frame = f
    local body = CreateFrame("Frame", nil, f)
    body:SetAllPoints()
    f.body = body
    f.segs = {}
    for i = 1, SEGMENTS do
        local t = body:CreateTexture(nil, "ARTWORK")
        t:SetTexture(WHITE)
        f.segs[i] = t
    end
    -- the arcs are rings of a fan standing on its tip, one texture per range band (inner ring = closest)
    for key, a in pairs(ARCS) do
        f[key] = {}
        for i = 1, SEGMENTS do
            local t = body:CreateTexture(nil, "ARTWORK")
            t:SetTexture(ARC_DIR .. a[1] .. i)
            f[key][i] = t
        end
    end
    f.badge = Icon.New(body)
    f.text = UI.Text(body, "", 14)
    HHT:MakeMovable(f, self, "main", L("Distance"))
    self:Layout()
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self.db
    local size = db.size
    local textSize = math.max(10, math.floor(size / 3))
    f.text:SetFont(UI.FONT, textSize, "OUTLINE")
    f.text:ClearAllPoints()
    local showText = db.showText or db.layout == "text"
    f.text:SetShown(showText)
    local textH = textSize + 4

    for _, t in ipairs(f.segs) do t:Hide() end
    for key in pairs(ARCS) do
        for _, t in ipairs(f[key]) do t:Hide() end
    end
    f.badge:Hide()
    f.active = nil

    if db.layout == "text" then
        f:SetSize(math.max(120, size * 3), textH)
        f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
    elseif db.layout == "badge" then
        f.badge:Style(size, db.shape, 2, 1, false)
        f.badge:ClearAllPoints()
        f.badge:SetPoint("TOP", f, "TOP", 0, 0)
        f.badge:Show()
        f:SetSize(math.max(size, 110), size + (showText and textH + 2 or 0))
        f.text:SetPoint("TOP", f.badge, "BOTTOM", 0, -4)
    elseif ARCS[db.layout] then
        local a = ARCS[db.layout]
        local h = math.floor(size * a[3])
        local w = h * a[2]
        local set = f[db.layout]
        for _, t in ipairs(set) do
            t:SetSize(w, h)
            t:ClearAllPoints()
            t:SetPoint("TOP", f, "TOP", 0, 0)
            t:Show()
        end
        f.active = set
        f:SetSize(w, h + (showText and textH + 2 or 0))
        f.text:SetPoint("TOP", f, "TOP", 0, -(h + 2))
    else
        local w, h, gap = math.max(8, math.floor(size / 3)), math.max(6, math.floor(size / 4)), 2
        local dir = db.direction
        local vertical = dir == "btt" or dir == "ttb"
        for i, t in ipairs(f.segs) do
            t:SetSize(w, h)
            t:ClearAllPoints()
            local step = i - 1
            if dir == "rtl" then
                t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -step * (w + gap), 0)
            elseif dir == "btt" then
                t:SetPoint("TOP", f, "TOP", 0, -(SEGMENTS - 1 - step) * (h + gap))
            elseif dir == "ttb" then
                t:SetPoint("TOP", f, "TOP", 0, -step * (h + gap))
            else
                t:SetPoint("TOPLEFT", f, "TOPLEFT", step * (w + gap), 0)
            end
            t:Show()
        end
        f.active = f.segs
        local rowW, colH = SEGMENTS * w + (SEGMENTS - 1) * gap, SEGMENTS * h + (SEGMENTS - 1) * gap
        if vertical then
            f:SetSize(math.max(w, showText and 60 or 0), colH + (showText and textH + 2 or 0))
            f.text:SetPoint("TOP", f, "TOP", 0, -(colH + 4))
        else
            f:SetSize(rowW, h + (showText and textH + 2 or 0))
            f.text:SetPoint("TOP", f, "TOP", 0, -(h + 4))
        end
    end
    HHT:ApplyGlobalLook(f)
    self.band = nil
end

function M:OnEnable()
    self:Build()
    self:Layout()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
end

function M:Refresh()
    self:Layout()
end

function M:OnLockChanged()
    self.band = nil
end

function M:Paint(band)
    local f, db = self.frame, self.db
    local r, g, b = HHT.Col(db, COLOR_OF[band])
    f.text:SetTextColor(r, g, b)
    f.text:SetText(Label(band))
    if db.layout == "badge" then
        local ic = f.badge
        if band == "DEAD" then
            ic.tex:SetTexture(SKULL)
            ic.tex:SetTexCoord(0.75, 1, 0.25, 0.5)
        else
            local spell = band == "MELEE" and S.Resolve("@wingClip") or S.Resolve("@autoShot")
            ic.tex:SetTexture(spell.icon)
            ic.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end
        ic:SetBorderColor(r, g, b)
    elseif f.active then
        local lit = LIT_OF[band] or 0
        for i, t in ipairs(f.active) do
            t:SetVertexColor(r, g, b, i <= lit and 1 or 0.22)
        end
        -- melee and dead zone have no range ladder: light the whole row
        if band == "MELEE" or band == "DEAD" or band == "FAR" then
            for _, t in ipairs(f.active) do t:SetVertexColor(r, g, b, 0.9) end
        end
    end
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db

    if HHT:IsUnlocked(self) then
        if not f:IsShown() then f:Show() end
        f.body:SetAlpha(1)
        local demo = HHT.shotValues and HHT.shotValues.distance or "Y25"
        if self.band ~= demo then self.band = demo; self:Paint(demo) end
        return
    end

    local band
    if HHT:ShouldShow(db.visibility, self) then band = Range.Band() end
    if not band then
        if f:IsShown() then f:Hide() end
        self.band = nil
        f.body:SetAlpha(1)
        return
    end
    if not f:IsShown() then f:Show() end

    if band ~= self.band then
        if band == "DEAD" and self.band ~= "DEAD" and db.sound then
            HHT.PlayAlert()
        end
        self.band = band
        self:Paint(band)
    end

    if db.pulse and band == "DEAD" then
        self.flip = not self.flip
        f.body:SetAlpha(self.flip and 1 or 0.45)
    else
        f.body:SetAlpha(1)
    end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Layout"), db, "layout", {
        { "segments", L("Segments") }, { "arcn", L("Arc (narrow)") }, { "arcw", L("Arc (wide)") },
        { "badge", L("Badge") }, { "text", L("Text only") } })
    form:Cond("Distance shown as segments", function() return db.layout == "segments" end)
    form:Cycle(L("Direction"), db, "direction", {
        { "ltr", L("Left to right") }, { "rtl", L("Right to left") },
        { "btt", L("Bottom to top") }, { "ttb", L("Top to bottom") } })
    form:Stepper(L("Size"), db, "size", 20, 120, 2)
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Check(L("Show text"), db, "showText")
    form:Header(L("Behavior"))
    form:Check(L("Pulse in the dead zone"), db, "pulse")
    form:Check(L("Sound when entering the dead zone"), db, "sound")
    form:Header(L("Colors"))
    form:Color(L("Melee color"), db.colors, "melee")
    form:Color(L("Dead zone color"), db.colors, "dead")
    form:Color(L("Near color (up to 15 yd)"), db.colors, "near")
    form:Color(L("Middle color (up to 25 yd)"), db.colors, "mid")
    form:Color(L("Far color (up to 35 yd)"), db.colors, "far")
    form:Color(L("Max range color"), db.colors, "max")
    form:Color(L("Out of range color"), db.colors, "oor")
end
