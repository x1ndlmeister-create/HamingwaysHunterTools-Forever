-- Pet status: portrait, health bar, state text and happiness icon.
local ADDON, HHT = ...
local L, UI, Icon, Bar = HHT.L, HHT.UI, HHT.Icon, HHT.Bar

HHT:AddGerman({
    ["Pet status"] = "Begleiter-Status",
    ["Pet portrait, health bar and happiness."] = "Begleiter-Portrait, Lebensbalken und Zufriedenheit.",
    ["Show happiness"] = "Zufriedenheit zeigen",
    ["Show health percent"] = "Lebensprozent zeigen",
    ["Show name"] = "Namen zeigen",
    ["Hide when no pet"] = "Ausblenden wenn kein Begleiter",
    ["Portrait size"] = "Portraitgroesse",
    ["Health"] = "Leben",
    ["Dead"] = "Tot",
    ["Unhappy"] = "Unzufrieden",
    ["Content"] = "Zufrieden",
    ["Happy"] = "Gluecklich",
    ["Dead color"] = "Farbe tot",
    ["Unhappy color"] = "Farbe unzufrieden",
    ["Health color"] = "Farbe Leben",
    ["Icon shape"] = "Symbolform",
    ["Show level"] = "Level zeigen",
    ["Show experience bar"] = "Erfahrungsbalken zeigen",
    ["Show loyalty bar"] = "Loyalitaetsbalken zeigen",
    ["Show training points"] = "Trainingspunkte zeigen",
    ["Small bar height"] = "Hoehe der kleinen Balken",
    ["Experience color"] = "Farbe Erfahrung",
    ["Training: %d"] = "Training: %d",
    ["Loyalty"] = "Loyalitaet",
    ["Lv %d"] = "St. %d",
    ["Show pet abilities"] = "Begleiter-Faehigkeiten zeigen",
    ["Ability icon size"] = "Groesse der Faehigkeiten",
    ["Show cooldown numbers"] = "Cooldown-Zahlen zeigen",
    ["Show autocast state"] = "Autocast-Status zeigen",
    ["Autocast color"] = "Farbe Autocast",
    ["Show focus bar"] = "Fokusbalken zeigen",
    ["Show focus name"] = "Fokus-Name zeigen",
    ["Show focus number"] = "Fokus-Zahl zeigen",
    ["Focus color"] = "Farbe Fokus",
    ["Focus"] = "Fokus",
    ["Show ability border"] = "Rahmen der Faehigkeiten zeigen",
    ["Show Frenzy"] = "Raserei zeigen",
    ["Frenzy icon size"] = "Groesse Raserei-Symbol",
})

local M = HHT:NewModule("pet", {
    name = "Pet status",
    desc = "Pet portrait, health bar and happiness.",
    positions = { main = { "CENTER", "CENTER", -260, -170 } },
    defaults = {
        shape = "round", iconSize = 34, width = 150, height = 18, bgAlpha = 0.85,
        barTexture = "blizzard", bevel = 0.6, border = true,
        showLabel = true, showTime = true, showHappiness = true, hideNoPet = true,
        showLevel = true, showXp = true, showLoyalty = true, showTraining = true, subHeight = 10,
        showAbilities = true, showFocus = true, showFocusLabel = true, showFocusValue = true, abilitySize = 18, abilityNumbers = true, abilityBorder = true, showAutocast = true,
        showFrenzy = true, frenzySize = 26,
        colors = {
            health = { 0.67, 0.83, 0.45 },
            xp = { 0.58, 0.40, 0.85 },
            focus = { 1.00, 0.50, 0.25 },
            auto = { 0.35, 0.90, 0.35 },
            dead = { 0.90, 0.20, 0.20 },
            unhappy = { 0.95, 0.55, 0.15 },
            bg = { 0.05, 0.04, 0.03 },
            edge = { 0.55, 0.42, 0.20 },
            text = { 0.95, 0.93, 0.85 },
        },
    },
})

local HAPPY_TEX = "Interface\\PetPaperDollFrame\\UI-PetHappiness"
local NUM_SLOTS = NUM_PET_ACTION_SLOTS or 10
local HAPPY_COORDS = {
    [3] = { 0, 0.1875, 0, 0.359375 },
    [2] = { 0.1875, 0.375, 0, 0.359375 },
    [1] = { 0.375, 0.5625, 0, 0.359375 },
}

function M:OnInit()
    self.exists = nil
    HHT:Listen(self, "UNIT_PET", "OnPetChanged")
    HHT:Listen(self, "UNIT_PORTRAIT_UPDATE", "OnPetChanged")
    HHT:Listen(self, "PLAYER_ENTERING_WORLD", "OnPetChanged")
    HHT:Every(self, 0.2, M.Tick)
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsPet", UIParent)
    f:SetSize(220, 34)
    self.frame = f
    f.portrait = Icon.New(f)
    f.bar = Bar.New(f)
    f.xp = Bar.New(f)
    f.focus = Bar.New(f)
    f.loy = Bar.New(f)
    f.happy = CreateFrame("Frame", nil, f)
    f.happy.tex = f.happy:CreateTexture(nil, "ARTWORK")
    f.happy.tex:SetAllPoints()
    f.happy.tex:SetTexture(HAPPY_TEX)
    f.abil = CreateFrame("Frame", nil, f)
    f.icons = {}
    for k = 1, NUM_SLOTS do
        local ic = Icon.New(f.abil)
        ic:EnableMouse(true)
        ic:Hide()
        ic:SetScript("OnEnter", function(self)
            if not self.slot then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetPetAction, GameTooltip, self.slot)
            GameTooltip:Show()
        end)
        ic:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f.icons[k] = ic
    end
    -- Frenzy (pet buff) via the client aura container, so it also works in combat.
    f.buffs = HHT.AuraBar.New(f, function()
        local r, g, b = HHT.Col(self.db, "edge")
        return { size = self.db.frenzySize, spacing = 0, shape = self.db.shape, borderSize = 1, borderAlpha = 1, color = { r, g, b } }
    end)
    HHT:MakeMovable(f, self, "main", L("Pet status"))
    self:Layout()
end

function M:OnEnable()
    self:Build()
    self:Layout()
    self.exists = nil
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
end

function M:Refresh()
    self:Layout()
    self.exists = nil
end

function M:OnLockChanged()
    self.exists = nil
    self:Layout()
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self.db
    local s = db.iconSize
    f.portrait:Style(s, db.shape, 2, 1, false)
    f.portrait:ClearAllPoints()
    f.portrait:SetBorderColor(HHT.Col(db, "edge"))
    local pdx = HHT.modules.petdex
    local click = not HHT:IsUnlocked() and pdx and pdx.enabled and pdx.db and pdx.db.openOnClick and true or false
    f.portrait:EnableMouse(click)
    if not f.portrait.petdexHooked then
        f.portrait.petdexHooked = true
        f.portrait:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and HHT.PetDex then HHT.PetDex:Toggle() end
        end)
    end
    Bar.Apply(f.bar, db, "health")
    local gap = 2
    local totalH = db.height
    if db.showFocus then totalH = totalH + gap + db.subHeight end
    if db.showXp then totalH = totalH + gap + db.subHeight end
    if db.showLoyalty then totalH = totalH + gap + db.subHeight end
    local fh = math.max(s, totalH)
    f.portrait:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(fh - s) / 2)
    f.bar:ClearAllPoints()
    f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", s + 6, -(fh - totalH) / 2)
    local prev = f.bar
    local subXp = setmetatable({ height = db.subHeight, showLabel = db.showTraining, showTime = true }, { __index = db })
    local subLoy = setmetatable({ height = db.subHeight, showLabel = true, showTime = true }, { __index = db })
    Bar.Apply(f.xp, subXp, "xp")
    Bar.Apply(f.loy, subLoy, nil)
    f.focus:ClearAllPoints()
    Bar.Apply(f.focus, setmetatable({ height = db.subHeight, showLabel = db.showFocusLabel, showTime = db.showFocusValue }, { __index = db }), "focus")
    if db.showFocus then
        f.focus:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -gap)
        f.focus:Show()
        prev = f.focus
    else
        f.focus:Hide()
    end
    f.xp:ClearAllPoints()
    f.loy:ClearAllPoints()
    if db.showXp then
        f.xp:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -gap)
        f.xp:Show()
        prev = f.xp
    else
        f.xp:Hide()
    end
    if db.showLoyalty then
        f.loy:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -gap)
        f.loy:Show()
        prev = f.loy
    else
        f.loy:Hide()
    end
    f.happy:SetSize(db.height + 6, db.height + 6)
    f.happy:ClearAllPoints()
    f.happy:SetPoint("LEFT", f.bar, "RIGHT", 4, 0)
    f.happy:SetShown(db.showHappiness)
    local w = s + 6 + db.width + (db.showHappiness and (db.height + 10) or 0)
    local fullH = fh
    f.abil:ClearAllPoints()
    f.abil:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -gap)
    f.abil:SetSize(w, db.abilitySize)
    f.abil:SetShown(db.showAbilities)
    if db.showAbilities then fullH = math.max(fh, (fh - totalH) / 2 + totalH + gap + db.abilitySize) end
    for k, ic in ipairs(f.icons) do
        ic:Style(db.abilitySize, db.shape, db.abilityBorder and 1 or 0, 1, db.abilityNumbers)
        ic:ClearAllPoints()
        ic:SetPoint("TOPLEFT", f.abil, "TOPLEFT", (k - 1) * (db.abilitySize + 2), 0)
    end
    if f.buffs then
        if db.showFrenzy and f.buffs.engine then
            f.buffs:Setup("hht_frenzy", "pet", "HELPFUL", { includeSpellIDs = { [19615] = true } }, 1, "left", 0, 0)
            local c = f.buffs.conts["hht_frenzy"]
            if c then
                c:ClearAllPoints()
                c:SetPoint("BOTTOMRIGHT", f.portrait, "BOTTOMLEFT", -4, (s - db.frenzySize) / 2)
            end
            f.buffs:StyleAll()
        else
            f.buffs:Hide("hht_frenzy")
        end
    end
    f:SetSize(w, fullH)
    HHT:ApplyGlobalLook(f)
end

function M:OnPetChanged(event, unit)
    if unit and unit ~= "player" and unit ~= "pet" then return end
    self.exists = nil
end

local function ReadName()
    local ok, n = pcall(UnitName, "pet")
    if ok and type(n) == "string" and not HHT.IsSecret(n) then return n end
    return ""
end

-- 1 unhappy, 2 content, 3 happy; nil when unavailable
local function ReadHappiness()
    local level
    if C_PetInfo and C_PetInfo.GetPetHappiness then
        local ok, h = pcall(C_PetInfo.GetPetHappiness)
        level = ok and HHT.SafeNumber(h) or nil
    end
    if not level and GetPetHappiness then
        local ok, h, damage = pcall(GetPetHappiness)
        if ok then
            level = HHT.SafeNumber(h)
            damage = HHT.SafeNumber(damage)
            if not (level and HAPPY_COORDS[level]) and damage and damage > 0 then
                level = (damage >= 115 and 3) or (damage >= 90 and 2) or 1
            end
        end
    end
    if level and HAPPY_COORDS[level] then return level end
end
M.ReadHappiness = ReadHappiness

function M:SetHealth(bar)
    local okH, hp = pcall(UnitHealth, "pet")
    local okM, mx = pcall(UnitHealthMax, "pet")
    if not (okH and okM) then return end
    pcall(bar.bar.SetMinMaxValues, bar.bar, 0, mx)
    pcall(bar.bar.SetValue, bar.bar, hp)
    local rh, rm = HHT.SafeNumber(hp), HHT.SafeNumber(mx)
    if not self.db.showTime then return end
    if rh and rm and rm > 0 then
        bar.time:SetText(string.format("%d%%", math.floor(rh / rm * 100 + 0.5)))
    elseif UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
        local okP, pct = pcall(UnitHealthPercent, "pet", true, CurveConstants.ScaleTo100)
        if not (okP and pcall(bar.time.SetFormattedText, bar.time, "%d%%", pct)) then bar.time:SetText("") end
    else
        bar.time:SetText("")
    end
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    local unlocked = HHT:IsUnlocked()
    local bar = f.bar

    local ok, ex = pcall(UnitExists, "pet")
    local exists = ok and not HHT.IsSecret(ex) and ex and true or false

    if unlocked and not exists then
        if not f:IsShown() then f:Show() end
        bar.bar:SetMinMaxValues(0, 1)
        bar.bar:SetValue(0.7)
        bar.bar:SetStatusBarColor(HHT.Col(db, "health"))
        bar.label:SetText(L("Pet"))
        bar.time:SetText("70%")
        f.portrait:SetIcon(HHT.Spells.Resolve("@callPet").icon)
        f.happy.tex:SetTexCoord(unpack(HAPPY_COORDS[3]))
        self:Extras(true)
        self:Abilities(true)
        return
    end

    if not exists then
        if db.hideNoPet then
            if f:IsShown() then f:Hide() end
            return
        end
        if not f:IsShown() then f:Show() end
        bar.bar:SetMinMaxValues(0, 1)
        bar.bar:SetValue(0)
        bar.label:SetText(L("No pet"))
        bar.time:SetText("")
        f.happy:Hide()
        f.xp:Hide()
        f.loy:Hide()
        f.focus:Hide()
        for _, ic in ipairs(f.icons) do ic:Hide() end
        f.portrait:SetIcon(HHT.Spells.Resolve("@callPet").icon)
        self.exists = false
        return
    end

    if not f:IsShown() then f:Show() end
    if self.exists ~= true then
        self.exists = true
        pcall(SetPortraitTexture, f.portrait.tex, "pet")
        f.portrait.tex:SetTexCoord(0, 1, 0, 1)
    end

    local dead = HHT.SafeBool(UnitIsDead, "pet") == true
    local happy = db.showHappiness and ReadHappiness() or nil
    bar.label:SetText(ReadName())
    if db.showLevel then
        local okL, lv = pcall(UnitLevel, "pet")
        lv = okL and HHT.SafeNumber(lv) or nil
        if lv and lv > 0 then bar.label:SetText(ReadName() .. "  " .. string.format(L("Lv %d"), lv)) end
    end

    if dead then
        bar.bar:SetMinMaxValues(0, 1)
        bar.bar:SetValue(0)
        bar.time:SetText(L("Dead"))
        bar.time:SetTextColor(HHT.Col(db, "dead"))
        bar.label:SetTextColor(HHT.Col(db, "dead"))
    else
        bar.bar:SetStatusBarColor(HHT.Col(db, "health"))
        self:SetHealth(bar)
        if happy == 1 then
            bar.label:SetTextColor(HHT.Col(db, "unhappy"))
        else
            bar.label:SetTextColor(HHT.Col(db, "text"))
        end
        bar.time:SetTextColor(HHT.Col(db, "text"))
    end
    f.portrait.tex:SetDesaturated(dead)

    if happy then
        f.happy.tex:SetTexCoord(unpack(HAPPY_COORDS[happy]))
        f.happy:Show()
    else
        f.happy:Hide()
    end
    self:Extras(false)
    self:Abilities(false)
end

-- C_PetInfo first (retail client), then the classic global.
local function PetCall(name)
    local fn = C_PetInfo and C_PetInfo[name]
    if type(fn) == "function" then
        local r = { pcall(fn) }
        if r[1] and r[2] ~= nil then return unpack(r, 2) end
    end
    local g = _G[name]
    if type(g) == "function" then
        local r = { pcall(g) }
        if r[1] then return unpack(r, 2) end
    end
end

HHT.PetCall = PetCall

local function PaintAuto(db, ic, on)
    if db.showAutocast and on then
        ic:SetBorderColor(HHT.Col(db, "auto"))
        ic.count:SetText("A")
    else
        ic:SetBorderColor(HHT.Col(db, "edge"))
        ic.count:SetText("")
    end
end

-- Pet bar spells with cooldown swipe and autocast state; commands (attack, follow...) are skipped.
function M:Abilities(preview)
    local f, db = self.frame, self.db
    if not db.showAbilities then return end
    local icons = f.icons
    local j = 0
    if preview then
        local tex = HHT.Spells.Resolve("@callPet").icon
        for k = 1, 4 do
            j = j + 1
            local ic = icons[j]
            ic.slot, ic.allowed = nil, nil
            ic:SetIcon(tex)
            ic:ClearCooldown()
            PaintAuto(db, ic, k == 1)
            ic:Show()
        end
    else
        for i = 1, NUM_SLOTS do
            local ok, name, tex, isToken, _, allowed, enabled = pcall(GetPetActionInfo, i)
            if not ok or HHT.IsSecret(name) or HHT.IsSecret(isToken) then return end
            if name and not isToken then
                j = j + 1
                local ic = icons[j]
                ic.slot = i
                ic.allowed = (not HHT.IsSecret(allowed)) and allowed and true or false
                ic:SetIcon(tex)
                local okC, start, dur = pcall(GetPetActionCooldown, i)
                if okC and start then pcall(ic.SetTimer, ic, start, dur or 0) else ic:ClearCooldown() end
                PaintAuto(db, ic, (not HHT.IsSecret(enabled)) and enabled and true or false)
                ic:Show()
            end
        end
    end
    for k = j + 1, #icons do
        icons[k].slot = nil
        icons[k]:Hide()
    end
end

local LOYALTY_COLORS = {
    { 0.85, 0.08, 0.08 }, { 1.00, 0.30, 0.22 }, { 1.00, 0.50, 0.08 },
    { 1.00, 0.82, 0.08 }, { 0.55, 0.85, 0.18 }, { 0.12, 0.72, 0.20 },
}

-- Experience, training points and loyalty rows; each one hides itself when its API gives nothing.
function M:Extras(preview)
    local f, db = self.frame, self.db
    if db.showFocus then
        f.focus.label:SetText(L("Focus"))
        if preview then
            f.focus.bar:SetMinMaxValues(0, 100)
            f.focus.bar:SetValue(70)
            f.focus.time:SetText("70")
        else
            local okP, cur = pcall(UnitPower, "pet")
            local okM, mx = pcall(UnitPowerMax, "pet")
            local rm = okM and HHT.SafeNumber(mx)
            if okP and okM and not (rm and rm <= 0) then
                f.focus:Show()
                pcall(f.focus.bar.SetMinMaxValues, f.focus.bar, 0, mx)
                pcall(f.focus.bar.SetValue, f.focus.bar, cur)
                local rc = HHT.SafeNumber(cur)
                f.focus.time:SetText(rc and tostring(rc) or "")
            else
                f.focus:Hide()
            end
        end
    end
    if db.showXp then
        local cur, mx, tp
        if preview then cur, mx, tp = 60, 100, 4 else
            local a, b = PetCall("GetPetExperience")
            cur, mx = HHT.SafeNumber(a), HHT.SafeNumber(b)
            local total, spent = PetCall("GetPetTrainingPoints")
            total, spent = HHT.SafeNumber(total), HHT.SafeNumber(spent)
            if total then tp = total - (spent or 0) end
        end
        if cur or tp then
            f.xp:Show()
            f.xp.bar:SetMinMaxValues(0, math.max(mx or 1, 1))
            f.xp.bar:SetValue((cur and mx and mx > 0) and cur or 0)
            f.xp.time:SetText((cur and mx and mx > 0) and string.format("%d%%", math.floor(cur / mx * 100 + 0.5)) or "")
            f.xp.label:SetText(tp and string.format(L("Training: %d"), tp) or "")
        else
            f.xp:Hide()
        end
    end
    if db.showLoyalty then
        local level
        if preview then level = 4 else
            local s = PetCall("GetPetLoyalty")
            if type(s) == "string" and not HHT.IsSecret(s) then level = tonumber(s:match("(%d+)")) end
        end
        if level and level > 0 and LOYALTY_COLORS[level] then
            f.loy:Show()
            f.loy.bar:SetMinMaxValues(0, 6)
            f.loy.bar:SetValue(level)
            f.loy.bar:SetStatusBarColor(unpack(LOYALTY_COLORS[level]))
            f.loy.label:SetText(L("Loyalty"))
            f.loy.time:SetText(level .. "/6")
        else
            f.loy:Hide()
        end
    end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Portrait size"), db, "iconSize", 20, 80, 2)
    form:Stepper(L("Bar width"), db, "width", 60, 400, 10)
    form:Stepper(L("Bar height"), db, "height", 8, 40, 1)
    form:Stepper(L("Background opacity"), db, "bgAlpha", 0, 1, 0.05)
    form:Check(L("Show name"), db, "showLabel")
    form:Check(L("Show health percent"), db, "showTime")
    form:Check(L("Show happiness"), db, "showHappiness")
    form:Check(L("Show Frenzy"), db, "showFrenzy")
    form:Stepper(L("Frenzy icon size"), db, "frenzySize", 14, 48, 2)
    form:Check(L("Show focus bar"), db, "showFocus")
    form:Check(L("Show focus name"), db, "showFocusLabel")
    form:Check(L("Show focus number"), db, "showFocusValue")
    form:Check(L("Show level"), db, "showLevel")
    form:Check(L("Show experience bar"), db, "showXp")
    form:Check(L("Show training points"), db, "showTraining")
    form:Check(L("Show loyalty bar"), db, "showLoyalty")
    form:Stepper(L("Small bar height"), db, "subHeight", 6, 20, 1)
    form:Check(L("Show pet abilities"), db, "showAbilities")
    form:Stepper(L("Ability icon size"), db, "abilitySize", 10, 48, 2)
    form:Check(L("Show cooldown numbers"), db, "abilityNumbers")
    form:Check(L("Show ability border"), db, "abilityBorder")
    form:Check(L("Show autocast state"), db, "showAutocast")
    form:Check(L("Show border"), db, "border")
    Bar.AddOptions(form, db)
    form:Header(L("Behavior"))
    form:Check(L("Hide when no pet"), db, "hideNoPet")
    form:Header(L("Colors"))
    form:Color(L("Health color"), db.colors, "health")
    form:Color(L("Experience color"), db.colors, "xp")
    form:Color(L("Focus color"), db.colors, "focus")
    form:Color(L("Autocast color"), db.colors, "auto")
    form:Color(L("Dead color"), db.colors, "dead")
    form:Color(L("Unhappy color"), db.colors, "unhappy")
    form:Color(L("Background color"), db.colors, "bg")
    form:Color(L("Border color"), db.colors, "edge")
    form:Color(L("Text color"), db.colors, "text")
end
