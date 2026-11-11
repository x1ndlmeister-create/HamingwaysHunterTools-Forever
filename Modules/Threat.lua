-- Threat: bar with your threat on the target, warning before you pull aggro.
local ADDON, HHT = ...
local L, UI, Bar = HHT.L, HHT.UI, HHT.Bar

HHT:AddGerman({
    ["Threat"] = "Bedrohung",
    ["Threat meter and aggro warning."] = "Bedrohungsanzeige und Aggro-Warnung.",
    ["Aggro!"] = "Aggro!",
    ["Only in a group or with pet"] = "Nur in Gruppe oder mit Pet",
    ["Hide when no threat"] = "Ausblenden ohne Bedrohung",
    ["Warn at threat percent"] = "Warnen ab Bedrohung in Prozent",
    ["Warn when gaining aggro"] = "Warnen bei Aggro",
    ["Play a sound for warnings"] = "Ton bei Warnungen",
    ["Blink at high threat"] = "Blinken bei hoher Bedrohung",
    ["Show label"] = "Beschriftung zeigen",
    ["Show percent"] = "Prozent zeigen",
    ["Low threat"] = "Wenig Bedrohung",
    ["Rising threat"] = "Steigende Bedrohung",
    ["High threat"] = "Hohe Bedrohung",
    ["Aggro color"] = "Farbe Aggro",
})

local M = HHT:NewModule("threat", {
    name = "Threat",
    desc = "Threat meter and aggro warning.",
    positions = { main = { "CENTER", "CENTER", 0, -98 } },
    defaults = {
        width = 180, height = 16, bgAlpha = 0.85, barTexture = "blizzard", bevel = 0.6, border = true,
        showLabel = true, showTime = true,
        onlyGroup = true, hideNoThreat = true, warnAt = 80, alertAggro = true, sound = true, blink = true,
        colors = {
            low = { 0.67, 0.83, 0.45 },
            mid = { 0.95, 0.80, 0.20 },
            high = { 0.95, 0.55, 0.15 },
            aggro = { 0.90, 0.20, 0.20 },
            bg = { 0.05, 0.04, 0.03 },
            edge = { 0.55, 0.42, 0.20 },
            text = { 0.95, 0.93, 0.85 },
        },
    },
})

function M:OnInit()
    self.warned = false
    self.hadAggro = false
    self.flip = false
    HHT:Listen(self, "PLAYER_TARGET_CHANGED", "ResetAlerts")
    HHT:Listen(self, "PLAYER_REGEN_ENABLED", "ResetAlerts")
    HHT:Listen(self, "UNIT_THREAT_LIST_UPDATE", "Tick")
    HHT:Listen(self, "UNIT_THREAT_SITUATION_UPDATE", "Tick")
    HHT:Every(self, 0.1, M.Tick)
end

function M:ResetAlerts()
    self.warned = false
    self.hadAggro = false
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsThreat", UIParent)
    f:SetSize(180, 16)
    self.frame = f
    f.bar = Bar.New(f)
    f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    HHT:MakeMovable(f, self, "main", L("Threat"))
    self:Layout()
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self.db
    Bar.Apply(f.bar, db, "low")
    f:SetSize(db.width, db.height)
    HHT:ApplyGlobalLook(f)
end

function M:OnEnable()
    self:Build()
    self:Layout()
    self:ResetAlerts()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
end

function M:Refresh()
    self:Layout()
end

local function InGroup()
    if UnitExists and UnitExists("pet") then return true end
    if IsInGroup and IsInGroup() then return true end
    return GetNumGroupMembers ~= nil and (GetNumGroupMembers() or 0) > 1
end

-- Returns percent (0-100), tanking; nil when unreadable.
local function ReadThreat()
    local ok, tanking, _, scaled = pcall(UnitDetailedThreatSituation, "player", "target")
    if not ok then return nil end
    if HHT.IsSecret(tanking) or HHT.IsSecret(scaled) then return nil end
    local pct = HHT.SafeNumber(scaled)
    local isTank = tanking == true or tanking == 1
    if not pct and tanking == nil then
        local tt = HHT.SafeBool(UnitIsUnit, "targettarget", "player")
        if tt then return 100, true end
    end
    if isTank then return 100, true end
    return math.max(0, math.min(pct or 0, 100)), false
end

function M:Alert()
    if self.db.sound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959) end
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    local bar = f.bar

    if HHT:IsUnlocked() then
        if not f:IsShown() then f:Show() end
        bar:SetAlpha(1)
        bar.bar:SetMinMaxValues(0, 100)
        bar.bar:SetValue(75)
        bar.bar:SetStatusBarColor(HHT.Col(db, "high"))
        bar.label:SetText(L("Threat"))
        bar.time:SetText("75%")
        return
    end

    local pct, tanking
    if HHT.HasAttackableTarget() and (not db.onlyGroup or InGroup()) then
        pct, tanking = ReadThreat()
    end
    if not pct or (db.hideNoThreat and pct <= 0 and not tanking) then
        if f:IsShown() then f:Hide() end
        self:ResetAlerts()
        return
    end
    if not f:IsShown() then f:Show() end

    local warnAt = db.warnAt
    local key = (tanking and "aggro") or (pct >= warnAt and "high") or (pct >= warnAt - 25 and "mid") or "low"
    bar.bar:SetMinMaxValues(0, 100)
    bar.bar:SetValue(pct)
    bar.bar:SetStatusBarColor(HHT.Col(db, key))
    bar.label:SetText(tanking and L("Aggro!") or L("Threat"))
    bar.time:SetText(string.format("%d%%", math.floor(pct + 0.5)))

    if tanking then
        if db.alertAggro and not self.hadAggro then self:Alert() end
        self.hadAggro = true
    else
        self.hadAggro = false
        if pct >= warnAt then
            if not self.warned then self:Alert() end
            self.warned = true
        elseif pct < warnAt - 10 then
            self.warned = false
        end
    end

    if db.blink and (tanking or pct >= warnAt) then
        bar:SetAlpha((math.floor(GetTime() * 5) % 2 == 0) and 1 or 0.55)
    else
        bar:SetAlpha(1)
    end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Stepper(L("Bar width"), db, "width", 60, 400, 10)
    form:Stepper(L("Bar height"), db, "height", 8, 40, 1)
    form:Stepper(L("Background opacity"), db, "bgAlpha", 0, 1, 0.05)
    form:Check(L("Show label"), db, "showLabel")
    form:Check(L("Show percent"), db, "showTime")
    form:Check(L("Show border"), db, "border")
    Bar.AddOptions(form, db)
    form:Header(L("Behavior"))
    form:Check(L("Only in a group or with pet"), db, "onlyGroup")
    form:Check(L("Hide when no threat"), db, "hideNoThreat")
    form:Stepper(L("Warn at threat percent"), db, "warnAt", 40, 95, 5)
    form:Check(L("Warn when gaining aggro"), db, "alertAggro")
    form:Check(L("Play a sound for warnings"), db, "sound")
    form:Check(L("Blink at high threat"), db, "blink")
    form:Header(L("Colors"))
    form:Color(L("Low threat"), db.colors, "low")
    form:Color(L("Rising threat"), db.colors, "mid")
    form:Color(L("High threat"), db.colors, "high")
    form:Color(L("Aggro color"), db.colors, "aggro")
    form:Color(L("Background color"), db.colors, "bg")
    form:Color(L("Border color"), db.colors, "edge")
    form:Color(L("Text color"), db.colors, "text")
end
