-- Swing timer: Auto Shot / melee swing bars plus hunter range state.
local ADDON, HHT = ...
local L, UI, Range = HHT.L, HHT.UI, HHT.Range

HHT:AddGerman({
    ["Swing timer"] = "Schlag-Timer",
    ["Auto Shot and melee swing bars with range state."] = "Auto-Shot- und Nahkampf-Balken mit Reichweitenanzeige.",
    ["Show ranged bar"] = "Fernkampf-Balken zeigen",
    ["Show melee bar"] = "Nahkampf-Balken zeigen",
    ["Show range state text"] = "Reichweiten-Text zeigen",
    ["Show remaining time"] = "Restzeit zeigen",
    ["Show bar labels"] = "Balken-Beschriftung zeigen",
    ["Show spark"] = "Funken zeigen",
    ["Ranged bar turns red in the dead zone"] = "Fernkampf-Balken rot in der Totzone",
    ["Show border"] = "Rahmen zeigen",
    ["Bar width"] = "Balkenbreite",
    ["Bar height"] = "Balkenhoehe",
    ["Background opacity"] = "Hintergrund-Deckkraft",
    ["Bar mode"] = "Balkenmodus",
    ["Ranged bar"] = "Fernkampf-Balken",
    ["Melee bar"] = "Nahkampf-Balken",
    ["Dead zone"] = "Totzone",
    ["Border color"] = "Rahmenfarbe",
    ["Text color"] = "Textfarbe",
    ["Background color"] = "Hintergrundfarbe",
    ["Range: melee"] = "Reichweite: Nahkampf",
    ["Range: ranged"] = "Reichweite: Fernkampf",
    ["Range: dead zone"] = "Reichweite: Totzone",
    ["Range: too far"] = "Reichweite: zu weit",
    ["RANGED"] = "FERNKAMPF",
    ["MELEE"] = "NAHKAMPF",
    ["DEAD ZONE"] = "TOTZONE",
    ["TOO FAR"] = "ZU WEIT",
    ["Auto Shot"] = "Auto-Shot",
    ["Main hand"] = "Haupthand",
    ["Mark 0.5 s before the shot"] = "Markierung 0,5 s vor dem Schuss",
})

local M = HHT:NewModule("swing", {
    name = "Swing timer",
    desc = "Auto Shot and melee swing bars with range state.",
    positions = { main = { "CENTER", "CENTER", 0, -170 } },
    defaults = {
        showRanged = true, showMelee = true, showRange = true,
        showTime = true, showLabel = true, showSpark = true, colorByRange = true,
        border = true, barTexture = "blizzard", bevel = 0.6, flash = true, flashGlow = 1, flashGlowSize = 8,
        showMark = true,
        width = 220, height = 16, spacing = 3, bgAlpha = 0.85,
        visibility = "combattarget", fillMode = "fill",
        colors = {
            ranged = { 0.67, 0.83, 0.45 },
            melee = { 0.88, 0.58, 0.24 },
            dead = { 0.90, 0.20, 0.20 },
            bg = { 0.05, 0.04, 0.03 },
            edge = { 0.55, 0.42, 0.20 },
            text = { 0.95, 0.93, 0.85 },
            rMelee = { 0.88, 0.58, 0.24 },
            rRanged = { 0.67, 0.83, 0.45 },
            rDead = { 0.90, 0.20, 0.20 },
            rFar = { 0.60, 0.60, 0.60 },
        },
    },
})

local max, min, floor = math.max, math.min, math.floor

local function SafeDuration(v)
    if HHT.IsSecret(v) then return nil end
    if type(v) ~= "number" or v <= 0 or v ~= v or v == math.huge then return nil end
    return v
end

function M:OnInit()
    self.timers = { ranged = {}, melee = {} }
    self.rangeState = nil
    self.rangeAcc = 0
    HHT:Listen(self, "PLAYER_SWING", "OnSwing")
    HHT:Every(self, 0.02, M.Tick)
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsSwing", UIParent)
    f:SetSize(220, 40)
    self.frame = f
    f.range = UI.Text(f, "", 11)
    f.range:SetPoint("TOP", f, "TOP", 0, 0)
    f.ranged = HHT.Bar.New(f)
    -- Auto Shot needs 0.5 s to fire, so moving is safe until the bar reaches this line.
    f.ranged.mark = f.ranged.fx:CreateTexture(nil, "OVERLAY", nil, 1)
    f.ranged.mark:SetColorTexture(0.6, 0.6, 0.6, 0.5)
    f.ranged.mark:SetWidth(1)
    f.melee = HHT.Bar.New(f)
    HHT:MakeMovable(f, self, "main", L("Swing timer"))
    self:Layout()
end

function M:OnEnable()
    self:Build()
    self.frame:Show()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
end

function M:OnLockChanged()
    self:Layout()
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self.db
    local y = 0
    if db.showRange then
        f.range:Show()
        f.range:SetFont(UI.FONT, 11, "OUTLINE")
        y = 14
    else
        f.range:Hide()
    end
    HHT.Bar.Apply(f.ranged, db, "ranged")
    HHT.Bar.Apply(f.melee, db, "melee")
    f.ranged.label:SetText(L("Auto Shot"))
    f.melee.label:SetText(L("Main hand"))
    f.ranged:ClearAllPoints()
    f.melee:ClearAllPoints()
    f.ranged:SetShown(db.showRanged)
    f.melee:SetShown(db.showMelee)
    if db.showRanged then
        f.ranged:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y)
        y = y + db.height + db.spacing
    end
    if db.showMelee then
        f.melee:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y)
        y = y + db.height + db.spacing
    end
    f:SetSize(db.width, max(db.height, y - db.spacing))
    HHT:ApplyGlobalLook(f)
end

function M:Refresh()
    self:Layout()
end

function M:OnSwing(_, duration, swingType)
    duration = SafeDuration(duration)
    if not duration or HHT.IsSecret(swingType) then return end
    local t
    if swingType == 0 then t = self.timers.melee
    elseif swingType == 2 then t = self.timers.ranged
    else return end
    -- the next swing starts right as the bar fills, so the flash has to fire here before the timer resets
    local f = self.frame
    if f and self.db.flash and t.start and t.duration and not t.flashed
        and GetTime() - t.start >= t.duration - 0.08 then
        HHT.Bar.Flash(swingType == 0 and f.melee or f.ranged)
    end
    t.flashed = false
    t.duration = duration
    t.start = GetTime()
end

local function UpdateRow(self, row, t, now, demoPhase)
    local db = self.db
    local duration, elapsed = t.duration, nil
    local demo = false
    if duration and t.start then elapsed = now - t.start end
    if (not elapsed or elapsed >= duration) and demoPhase then
        demo = true
        duration = 2.2
        local frozen = HHT.shotValues and HHT.shotValues.swingPct
        elapsed = frozen and duration * frozen / 100 or (now + demoPhase) % duration
    end
    local progress, remain
    if elapsed and duration and elapsed < duration then
        progress = elapsed / duration
        remain = duration - elapsed
    else
        progress = 1
        remain = nil
    end
    if db.flash then
        if demo then
            if row.demoProg and progress < row.demoProg then HHT.Bar.Flash(row) end
            row.demoProg = progress
        else
            row.demoProg = nil
            if not remain and t.start and not t.flashed and elapsed - duration < 0.5 then
                t.flashed = true
                HHT.Bar.Flash(row)
            end
        end
    end
    row.bar:SetMinMaxValues(0, 1)
    if db.fillMode == "drain" then
        row.bar:SetValue(remain and (1 - progress) or 1)
    else
        row.bar:SetValue(progress)
    end
    row.time:SetText(remain and string.format("%.1f", remain) or "")
    if db.showSpark and remain then
        local w = row:GetWidth() - 2
        local pos = (db.fillMode == "drain") and (1 - progress) or progress
        row.spark:ClearAllPoints()
        row.spark:SetPoint("CENTER", row.bar, "LEFT", w * pos, 0)
        row.spark:Show()
    else
        row.spark:Hide()
    end
end

local function UpdateMark(self, row, t, unlocked)
    local mark = row.mark
    local duration = t.duration or (unlocked and 2.2) or nil
    if not (self.db.showMark and duration and duration > 0.5) then mark:Hide(); return end
    local frac = 0.5 / duration
    local pos = (self.db.fillMode == "drain") and frac or (1 - frac)
    mark:ClearAllPoints()
    mark:SetPoint("CENTER", row.bar, "LEFT", (row:GetWidth() - 2) * pos, 0)
    mark:SetHeight(row:GetHeight() - 2)
    mark:Show()
end

local RANGE_TEXT = {
    melee = { "MELEE", "rMelee" },
    ranged = { "RANGED", "rRanged" },
    dead = { "DEAD ZONE", "rDead" },
    far = { "TOO FAR", "rFar" },
}

function M:Tick(dt)
    local f = self.frame
    if not f then return end
    local db = self.db
    local show = HHT:ShouldShow(db.visibility, self)
    if f:IsShown() ~= show then f:SetShown(show) end
    if not show then return end

    self.rangeAcc = self.rangeAcc + (dt or 0)
    if self.rangeAcc >= 0.08 then
        self.rangeAcc = 0
        self.rangeState = Range.State()
    end

    local unlocked = HHT:IsUnlocked(self)
    local state = self.rangeState
    if unlocked and HHT.shotValues and HHT.shotValues.swing then
        state = HHT.shotValues.swing
    elseif unlocked and not state then
        state = "ranged"
    end
    if db.showRange then
        local info = state and RANGE_TEXT[state]
        if info then
            f.range:SetText(L(info[1]))
            f.range:SetTextColor(HHT.Col(db, info[2]))
        else
            f.range:SetText("")
        end
    end
    if db.colorByRange then
        if state == "dead" then
            f.ranged.bar:SetStatusBarColor(HHT.Col(db, "dead"))
        else
            f.ranged.bar:SetStatusBarColor(HHT.Col(db, "ranged"))
        end
    end

    local now = GetTime()
    if db.showRanged then
        UpdateRow(self, f.ranged, self.timers.ranged, now, unlocked and 0 or nil)
        UpdateMark(self, f.ranged, self.timers.ranged, unlocked)
    end
    if db.showMelee then UpdateRow(self, f.melee, self.timers.melee, now, unlocked and 1.1 or nil) end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Check(L("Show ranged bar"), db, "showRanged")
    form:Check(L("Show melee bar"), db, "showMelee")
    form:Check(L("Show range state text"), db, "showRange")
    form:Check(L("Show remaining time"), db, "showTime")
    form:Check(L("Show bar labels"), db, "showLabel")
    form:Check(L("Show spark"), db, "showSpark")
    form:Check(L("Mark 0.5 s before the shot"), db, "showMark")
    form:Check(L("Show border"), db, "border")
    form:Check(L("Ranged bar turns red in the dead zone"), db, "colorByRange")
    form:Stepper(L("Bar width"), db, "width", 80, 600, 10)
    form:Stepper(L("Bar height"), db, "height", 6, 40, 1)
    form:Stepper(L("Spacing"), db, "spacing", 0, 12, 1)
    form:Stepper(L("Background opacity"), db, "bgAlpha", 0, 1, 0.05)
    HHT.Bar.AddOptions(form, db)
    HHT.Bar.AddFlash(form, db)
    form:Cycle(L("Bar mode"), db, "fillMode", { { "fill", L("Fill") }, { "drain", L("Drain") } })
    form:Header(L("Behavior"))
    form:Cycle(L("Show when"), db, "visibility", HHT.VisibilityChoices())
    form:Header(L("Colors"))
    form:Color(L("Ranged bar"), db.colors, "ranged")
    form:Color(L("Melee bar"), db.colors, "melee")
    form:Color(L("Dead zone"), db.colors, "dead")
    form:Color(L("Range: melee"), db.colors, "rMelee")
    form:Color(L("Range: ranged"), db.colors, "rRanged")
    form:Color(L("Range: dead zone"), db.colors, "rDead")
    form:Color(L("Range: too far"), db.colors, "rFar")
    form:Color(L("Background color"), db.colors, "bg")
    form:Color(L("Border color"), db.colors, "edge")
    form:Color(L("Text color"), db.colors, "text")
end
