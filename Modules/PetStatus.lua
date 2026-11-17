-- Pet status: portrait, health bar, state text and happiness icon.
local ADDON, HHT = ...
local L, UI, Icon, Bar = HHT.L, HHT.UI, HHT.Icon, HHT.Bar

HHT:AddGerman({
    ["Rename"] = "Umbenennen",
    ["Dismiss"] = "Wegschicken",
    ["Release"] = "Freilassen",
    ["This pet cannot be renamed."] = "Dieser Begleiter kann nicht umbenannt werden.",
    ["Pet status"] = "Begleiter-Status",
    ["Pet portrait, health bar and happiness."] = "Begleiter-Portrait, Lebensbalken und Zufriedenheit.",
    ["Show happiness"] = "Zufriedenheit zeigen",
    ["Show health percent"] = "Lebensprozent zeigen",
    ["Show name"] = "Namen zeigen",
    ["Hide when no pet"] = "Ausblenden wenn kein Begleiter",
    ["Portrait size"] = "Porträtgröße",
    ["Health"] = "Leben",
    ["Dead"] = "Tot",
    ["Unhappy"] = "Unzufrieden",
    ["Content"] = "Zufrieden",
    ["Happy"] = "Glücklich",
    ["Dead color"] = "Farbe tot",
    ["Unhappy color"] = "Farbe unzufrieden",
    ["Health color"] = "Farbe Leben",
    ["Icon shape"] = "Symbolform",
    ["Show level"] = "Level zeigen",
    ["Show experience bar"] = "Erfahrungsbalken zeigen",
    ["Show loyalty bar"] = "Loyalitätsbalken zeigen",
    ["Hide loyalty at max"] = "Loyalität bei Maximum ausblenden",
    ["Show training points"] = "Trainingspunkte zeigen",
    ["Small bar height"] = "Höhe der kleinen Balken",
    ["Bar spacing"] = "Balkenabstand",
    ["Experience color"] = "Farbe Erfahrung",
    ["Training: %d"] = "Training: %d",
    ["Loyalty"] = "Loyalität",
    ["Lv %d"] = "St. %d",
    ["Show pet abilities"] = "Begleiter-Fähigkeiten zeigen",
    ["Ability icon size"] = "Größe der Fähigkeiten",
    ["Show cooldown numbers"] = "Cooldown-Zahlen zeigen",
    ["Show autocast state"] = "Autocast-Status zeigen",
    ["Autocast color"] = "Farbe Autocast",
    ["Show focus bar"] = "Fokusbalken zeigen",
    ["Show focus name"] = "Fokus-Name zeigen",
    ["Show focus number"] = "Fokus-Zahl zeigen",
    ["Focus color"] = "Farbe Fokus",
    ["Focus"] = "Fokus",
    ["Show ability border"] = "Rahmen der Fähigkeiten zeigen",
    ["Show Frenzy"] = "Raserei zeigen",
    ["Frenzy icon size"] = "Größe Raserei-Symbol",
    ["Show upgrade arrow"] = "Upgrade-Pfeil zeigen",
    ["Pet upgrades in this zone: %d"] = "Begleiter-Upgrades in dieser Zone: %d",
    ["Click to show the list."] = "Klick zeigt die Liste.",
    ["Hide the default pet frame"] = "Standard-Begleiterfenster ausblenden",
    ["Attach to the default pet frame"] = "Unter das Standard-Begleiterfenster setzen (behält dessen Porträt, Leben, Fokus, Zufriedenheit)",
    ["Attach offset X"] = "Anheften Abstand X",
    ["Attach offset Y"] = "Anheften Abstand Y",
})

local M = HHT:NewModule("pet", {
    name = "Pet status",
    desc = "Pet portrait, health bar and happiness.",
    positions = { main = { "CENTER", "CENTER", -260, -120 } },
    defaults = {
        shape = "round", iconSize = 34, width = 150, height = 18, bgAlpha = 0.85,
        barTexture = "blizzard", barShape = "square", bevel = 0.6, border = true, borderSize = 1, smooth = true,
        showLabel = true, showTime = true, showHappiness = true, hideNoPet = true,
        showLevel = true, showXp = true, showLoyalty = true, showTraining = true, subHeight = 10, barSpacing = 2,
        showAbilities = true, showFocus = true, showFocusLabel = true, showFocusValue = true, abilitySize = 18, abilityNumbers = true, abilityBorder = true, showAutocast = true,
        showFrenzy = true, frenzySize = 26, showUpgrades = true,
        hideDefault = true, attachDefault = false, attachX = 0, attachY = 0,
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

-- Right-click menu on the pet bar (Rename, Dismiss, Release), like the default pet frame has.
local function PetMenu()
    if M.menu then return M.menu end
    local m = CreateFrame("Frame", "HamingwaysHunterToolsPetMenu", UIParent)
    m:SetFrameStrata("TOOLTIP")
    m:SetFrameLevel(20)
    m:SetSize(132, 3 * 22 + 8)
    m:SetClampedToScreen(true)
    m:EnableMouse(true)
    m:Hide()
    local pal = UI.PAL.menu
    UI.Round(m, 6, pal[1], pal[2], pal[3], pal[4], "BACKGROUND")
    UI.Shadow(m, 0.4)
    UI.RoundBorder(m, 6, 1, 1, 1, 0.14)
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetFrameStrata("TOOLTIP")
    catcher:SetFrameLevel(1)
    catcher:SetAllPoints(UIParent)
    catcher:RegisterForClicks("AnyUp")
    catcher:Hide()
    m.catcher = catcher
    function m.Close()
        catcher:Hide()
        HHT.HideSecure(m)
    end
    catcher:SetScript("OnClick", m.Close)

    local function Row(i, label, secure, onClick)
        local b = CreateFrame("Button", nil, m, secure and "SecureActionButtonTemplate" or nil)
        b:SetSize(126, 22)
        b:SetPoint("TOPLEFT", m, "TOPLEFT", 3, -4 - (i - 1) * 22)
        b:RegisterForClicks("AnyDown", "AnyUp")
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.22)
        b.text = UI.Text(b, label, 12)
        b.text:SetPoint("LEFT", b, "LEFT", 8, 0)
        if onClick then b:SetScript("OnClick", function(_, _, down) if not down then m.Close(); onClick() end end) end
        return b
    end
    Row(1, L("Rename"), false, function()
        if PetCanBeRenamed and not PetCanBeRenamed() then HHT.Print(L("This pet cannot be renamed.")) return end
        pcall(StaticPopup_Show, "RENAME_PET")
    end)
    local dismiss = Row(2, L("Dismiss"), true)
    dismiss:SetAttribute("type", "macro")
    dismiss:SetAttribute("macrotext", "/cast " .. HHT.Spells.CatalogName("dismissPet"))
    dismiss:HookScript("PostClick", function(_, _, down) if not down then m.Close() end end)
    Row(3, L("Release"), false, function()
        local ok, name = pcall(UnitName, "pet")
        pcall(StaticPopup_Show, "RELEASE_PET", ok and name or "")
    end)
    M.menu = m
    return m
end

function M:OpenPetMenu()
    if InCombatLockdown() or not HHT.SafeBool(UnitExists, "pet") then return end
    local m = PetMenu()
    local x, y = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    m:ClearAllPoints()
    m:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
    m.catcher:Show()
    HHT.ShowSecure(m)
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
        local v = self.view or self.db
        local r, g, b = HHT.Col(v, "edge")
        return { size = v.frenzySize, spacing = 0, shape = v.shape, borderSize = 1, borderAlpha = 1, color = { r, g, b } }
    end)
    f.frenzyDemo = Icon.New(f)
    f.frenzyDemo:Hide()
    f.up = CreateFrame("Button", nil, f)
    f.up:SetSize(24, 24)
    f.up:SetFrameLevel(f.portrait:GetFrameLevel() + 3)
    f.up:SetPoint("TOPLEFT", f.portrait, "TOPLEFT", -8, 8)
    f.up:RegisterForClicks("AnyUp")
    f.up:SetNormalTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    f.up:SetPushedTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    f.up:SetHighlightTexture("Interface\\GossipFrame\\AvailableQuestIcon", "ADD")
    f.up:GetPushedTexture():SetVertexColor(0.7, 0.7, 0.7)
    f.up:SetScript("OnClick", function()
        local pn = HHT.modules.petnearby
        if pn and pn.ToggleZone then pn:ToggleZone() end
    end)
    f.up:SetScript("OnEnter", function(btn)
        if not GameTooltip then return end
        local pn = HHT.modules.petnearby
        local list = pn and pn.enabled and pn:ZoneUpgrades()
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:AddLine(string.format(L("Pet upgrades in this zone: %d"), list and #list or 0), 1, 0.82, 0)
        GameTooltip:AddLine(L("Click to show the list."), 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    f.up:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    f.up:Hide()
    -- level badge drawn over the Blizzard portrait while docked
    f.badge = Icon.New(f)
    f.badge:Style(20, "round", 1, 1, false)
    f.badge:SetIcon("Interface\\Buttons\\WHITE8X8")
    f.badge.tex:SetVertexColor(0.05, 0.04, 0.03)
    f.badge:SetBorderColor(0.78, 0.60, 0.20)
    f.badge:Hide()
    HHT:MakeMovable(f, self, "main", L("Pet status"))
    self:Layout()
end

function M:OnEnable()
    self:Build()
    self:Layout()
    self:SetDefaultFrame(self.db.hideDefault and not (self.db.attachDefault and _G.PetFrame))
    self.exists = nil
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
    self:SetDefaultFrame(false)
end

function M:Refresh()
    self:Layout()
    self:SetDefaultFrame(self.db.hideDefault and not (self.db.attachDefault and _G.PetFrame))
    self.exists = nil
end

-- Blizzard shows the pet frame again through its unit watch, so the hidden state is enforced on every alpha or show call.
function M:SetDefaultFrame(hidden)
    local b = _G.PetFrame
    if not b then return end
    M.defaultHidden = hidden and true or false
    b:SetAlpha(hidden and 0 or 1)
    if M.defaultHooked then return end
    M.defaultHooked = true
    local busy = false
    local function Enforce(f)
        if not M.defaultHidden or busy then return end
        busy = true
        f:SetAlpha(0)
        busy = false
    end
    for _, fn in ipairs({ "SetAlpha", "SetAlphaFromBoolean", "Show", "SetShown" }) do
        if b[fn] then pcall(hooksecurefunc, b, fn, Enforce) end
    end
    pcall(b.HookScript, b, "OnShow", Enforce)
end

local DOCK_INSET = 6
local DOCK_GAP = -2

-- Docked to the default pet frame, Blizzard keeps portrait, health, focus and happiness; only the extra rows are ours.
function M:BuildView()
    local db = self.db
    self.view = nil
    if not (db.attachDefault and _G.PetFrame) then return db end
    local hb = _G.PetFrameHealthBar
    local w = hb and HHT.SafeNumber(hb:GetWidth())
    local v = setmetatable({
        docked = true, showFocus = false, showHappiness = false, height = 1, iconSize = 1,
        width = (w and w > 20 and w or db.width) - DOCK_INSET,
    }, { __index = db })
    self.view = v
    return v
end

-- Docks the frame under the default pet frame; it then follows that frame instead of its own saved position.
function M:ApplyAnchor()
    local f = self.frame
    local pf = _G.PetFrame
    local db = self.db
    local want = db.attachDefault and pf and true or false
    local was = f.hhtFollow and true or false
    if want then
        f.hhtFollow = true
        f:ClearAllPoints()
        -- aligned with the bars of the Blizzard frame, so the rows line up under its focus bar
        local anchor = _G.PetFrameManaBar or _G.PetFrameHealthBar or pf
        f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", DOCK_INSET + (db.attachX or 0), DOCK_GAP + (db.attachY or 0))
    end
    if want ~= was then
        if not want then
            f.hhtFollow = nil
            HHT:ApplyPosition(f)
        end
        HHT:ApplyLock()
    end
end

function M:OnLockChanged()
    self.exists = nil
    self:Layout()
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self:BuildView()
    local docked = db.docked and true or false
    local s = db.iconSize
    local xoff = docked and 0 or s + 6
    f.portrait:SetShown(not docked)
    f.bar:SetShown(not docked)
    -- docked: level and upgrade arrow are drawn over the Blizzard portrait
    local pp = _G.PetPortrait or (_G.PetFrame and _G.PetFrame.portrait) or f.portrait
    local cnt = f.portrait.count
    f.badge:ClearAllPoints()
    f.up:ClearAllPoints()
    cnt:ClearAllPoints()
    if docked then
        f.badge:SetPoint("CENTER", pp, "BOTTOMLEFT", 5, 5)
        f.up:SetPoint("TOPLEFT", pp, "TOPLEFT", -8, 8)
        cnt:SetParent(f.badge)
        cnt:SetPoint("CENTER", f.badge, "CENTER", 0, 0)
        cnt:SetFont(cnt:GetFont(), 10, "OUTLINE")
    else
        f.badge:Hide()
        f.up:SetPoint("TOPLEFT", f.portrait, "TOPLEFT", -8, 8)
        cnt:SetParent(f.portrait.over)
        cnt:SetPoint("BOTTOMRIGHT", f.portrait, "BOTTOMRIGHT", -1, 2)
    end
    if not docked then
        f.portrait:Style(s, db.shape, 2, 1, false)
        f.portrait:SetBorderColor(HHT.Col(db, "edge"))
    end
    f.portrait:ClearAllPoints()
    local pdx = HHT.modules.petdex
    local menuOn = not docked and not HHT:IsUnlocked(self)
    f.portrait:EnableMouse(menuOn)
    f.bar:EnableMouse(menuOn)
    if not f.petdexHooked then
        f.petdexHooked = true
        local function OnPetClick(_, button)
            if button == "RightButton" then
                M:OpenPetMenu()
            elseif button == "LeftButton" and HHT.PetDex and pdx and pdx.enabled and pdx.db and pdx.db.openOnClick then
                HHT.PetDex:Toggle()
            end
        end
        f.portrait:SetScript("OnMouseUp", OnPetClick)
        f.bar:SetScript("OnMouseUp", OnPetClick)
    end
    Bar.Apply(f.bar, db, "health")
    local gap = db.barSpacing or 2
    local totalH = db.height
    if db.showFocus then totalH = totalH + gap + db.subHeight end
    if db.showXp or db.showTraining then totalH = totalH + gap + db.subHeight end
    local showLoy = db.showLoyalty and not self.loyHidden
    if showLoy then totalH = totalH + gap + db.subHeight end
    local fh = math.max(s, totalH)
    f.portrait:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(fh - s) / 2)
    f.bar:ClearAllPoints()
    f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", xoff, -(fh - totalH) / 2)
    local prev = f.bar
    local xpOnly = not db.showXp
    local subXp = setmetatable({ height = db.subHeight, showLabel = db.showTraining, showTime = true,
        bgAlpha = xpOnly and 0 or db.bgAlpha, border = (not xpOnly) and db.border }, { __index = db })
    local subLoy = setmetatable({ height = db.subHeight, showLabel = true, showTime = true }, { __index = db })
    Bar.Apply(f.xp, subXp, "xp")
    if xpOnly then f.xp.shine:Hide(); f.xp.shade:Hide(); f.xp.lit:Hide() end
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
    if db.showXp or db.showTraining then
        f.xp:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -gap)
        f.xp:Show()
        prev = f.xp
    else
        f.xp:Hide()
    end
    if showLoy then
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
    local w = docked and db.width or (s + 6 + db.width + (db.showHappiness and (db.height + 10) or 0))
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
                if docked then
                    c:SetPoint("RIGHT", pp, "LEFT", -4, 0)
                else
                    c:SetPoint("BOTTOMRIGHT", f.portrait, "BOTTOMLEFT", -4, (s - db.frenzySize) / 2)
                end
            end
            f.buffs:StyleAll()
        else
            f.buffs:Hide("hht_frenzy")
        end
    end
    f:SetSize(w, fullH)
    self:ApplyAnchor()
    local d = f.frenzyDemo
    d:Style(db.frenzySize, db.shape, 1, 1, false)
    d:SetBorderColor(HHT.Col(db, "edge"))
    d:ClearAllPoints()
    if docked then
        d:SetPoint("RIGHT", pp, "LEFT", -4, 0)
    else
        d:SetPoint("BOTTOMRIGHT", f.portrait, "BOTTOMLEFT", -4, (s - db.frenzySize) / 2)
    end
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

function M:UpdateUpgrade(unlocked)
    local up = self.frame.up
    local pn = HHT.modules.petnearby
    local list = (self.db.showUpgrades and not unlocked and pn and pn.enabled) and pn:ZoneUpgrades() or nil
    local show = list and #list > 0 and true or false
    if up:IsShown() ~= show then up:SetShown(show) end
    if show then
        local combat = InCombatLockdown() and true or false
        up:EnableMouse(not combat)
        up:SetAlpha(combat and 0.5 or 1)
    end
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.view or self.db
    local unlocked = HHT:IsUnlocked(self)
    local bar = f.bar
    self:UpdateUpgrade(unlocked)
    if M.defaultHidden and _G.PetFrame and _G.PetFrame:GetAlpha() ~= 0 then _G.PetFrame:SetAlpha(0) end

    local ok, ex = pcall(UnitExists, "pet")
    local exists = ok and not HHT.IsSecret(ex) and ex and true or false

    -- Frenzy comes from the real pet buff, so the preview shows a stand-in icon.
    local demo = f.frenzyDemo
    local showDemo = unlocked and db.showFrenzy and true or false
    if demo:IsShown() ~= showDemo then
        if showDemo then
            local tex = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(19615))
                or (GetSpellTexture and GetSpellTexture(19615)) or "Interface\\Icons\\INV_Misc_QuestionMark"
            demo:SetIcon(tex)
        end
        demo:SetShown(showDemo)
    end
    if unlocked and not exists then
        if not f:IsShown() then f:Show() end
        bar.bar:SetMinMaxValues(0, 1)
        bar.bar:SetValue(0.7)
        bar.bar:SetStatusBarColor(HHT.Col(db, "health"))
        local okP, pl = pcall(UnitLevel, "pet")
        pl = okP and HHT.SafeNumber(pl) or nil
        if not (pl and pl > 0) then pl = 60 end
        bar.label:SetText(L("Pet"))
        f.portrait.count:SetText(db.showLevel and tostring(pl) or "")
        f.badge:SetShown(db.docked and db.showLevel and true or false)
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
        f.portrait.count:SetText("")
        f.badge:Hide()
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
        local num = okL and HHT.SafeNumber(lv) or nil
        if num and num > 0 then
            f.portrait.count:SetText(tostring(num))
        elseif okL and lv ~= nil then
            -- a secret level cannot be compared, but it may still be formatted
            if not pcall(f.portrait.count.SetFormattedText, f.portrait.count, "%d", lv) then f.portrait.count:SetText("") end
        else
            f.portrait.count:SetText("")
        end
    else
        f.portrait.count:SetText("")
    end
    f.badge:SetShown(db.docked and db.showLevel and true or false)

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
    local f, db = self.frame, self.view or self.db
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

local LOYALTY_NAMES = {
    rebellious = 1, unruly = 2, submissive = 3, dependable = 4, faithful = 5, ["best friend"] = 6,
}

local LOYALTY_COLORS = {
    { 0.85, 0.08, 0.08 }, { 1.00, 0.30, 0.22 }, { 1.00, 0.50, 0.08 },
    { 1.00, 0.82, 0.08 }, { 0.55, 0.85, 0.18 }, { 0.12, 0.72, 0.20 },
}

-- Experience, training points and loyalty rows; each one hides itself when its API gives nothing.
function M:Extras(preview)
    local f, db = self.frame, self.view or self.db
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
                if rc then
                    f.focus.time:SetText(tostring(rc))
                elseif not pcall(f.focus.time.SetFormattedText, f.focus.time, "%d", cur) then
                    f.focus.time:SetText("")
                end
            else
                f.focus:Hide()
            end
        end
    end
    if db.showXp or db.showTraining then
        local cur, mx, tp
        if preview then cur, mx, tp = 60, 100, 4 else
            local a, b = PetCall("GetPetExperience")
            cur, mx = HHT.SafeNumber(a), HHT.SafeNumber(b)
            local total, spent = PetCall("GetPetTrainingPoints")
            total, spent = HHT.SafeNumber(total), HHT.SafeNumber(spent)
            if total then tp = total - (spent or 0) end
        end
        if not db.showXp then cur, mx = nil, nil end
        if not db.showTraining then tp = nil end
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
        local level, rawText
        if preview then level = 4 else
            local s = PetCall("GetPetLoyalty")
            if type(s) == "string" and s ~= "" and not HHT.IsSecret(s) then
                rawText = s
                level = tonumber(s:match("(%d+)"))
                if not level then
                    local low = s:lower()
                    for name, n in pairs(LOYALTY_NAMES) do
                        if low:find(name, 1, true) then level = n break end
                    end
                end
            end
        end
        local hideMax = db.hideLoyaltyMax and (preview or (level and level >= 6)) and true or false
        if (self.loyHidden or false) ~= hideMax then
            self.loyHidden = hideMax
            self:Layout()
        end
        if hideMax then
            f.loy:Hide()
        elseif level and level > 0 and LOYALTY_COLORS[level] then
            f.loy:Show()
            f.loy.bar:SetMinMaxValues(0, 6)
            f.loy.bar:SetValue(level)
            f.loy.bar:SetStatusBarColor(unpack(LOYALTY_COLORS[level]))
            f.loy.label:SetText(L("Loyalty"))
            f.loy.time:SetText(level .. "/6")
        elseif rawText then
            -- text without a readable level: show it instead of hiding the row
            f.loy:Show()
            f.loy.bar:SetMinMaxValues(0, 6)
            f.loy.bar:SetValue(0)
            f.loy.label:SetText(L("Loyalty"))
            f.loy.time:SetText(rawText)
        else
            f.loy:Hide()
        end
    end
end

-- /hht debug: raw pet values, to see what this client returns.
function M:DebugExtras()
    local function S(...)
        local t = {}
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            t[#t + 1] = HHT.IsSecret(v) and "secret" or tostring(v)
        end
        return table.concat(t, "/")
    end
    HHT.Print("pet level=" .. S(pcall(UnitLevel, "pet")))
    for _, name in ipairs({ "GetPetExperience", "GetPetTrainingPoints", "GetPetLoyalty" }) do
        local c, g = C_PetInfo and C_PetInfo[name], _G[name]
        HHT.Print(name .. ": C_PetInfo=" .. (type(c) == "function" and S(pcall(c)) or "-")
            .. " global=" .. (type(g) == "function" and S(pcall(g)) or "-"))
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
    form:Check(L("Show upgrade arrow"), db, "showUpgrades")
    form:Stepper(L("Frenzy icon size"), db, "frenzySize", 14, 48, 2)
    form:Check(L("Show focus bar"), db, "showFocus")
    form:Check(L("Show focus name"), db, "showFocusLabel")
    form:Check(L("Show focus number"), db, "showFocusValue")
    form:Check(L("Show level"), db, "showLevel")
    form:Check(L("Show experience bar"), db, "showXp")
    form:Check(L("Show training points"), db, "showTraining")
    form:Check(L("Show loyalty bar"), db, "showLoyalty")
    form:Check(L("Hide loyalty at max"), db, "hideLoyaltyMax")
    form:Stepper(L("Small bar height"), db, "subHeight", 6, 20, 1)
    form:Stepper(L("Bar spacing"), db, "barSpacing", 0, 12, 1)
    form:Check(L("Show pet abilities"), db, "showAbilities")
    form:Stepper(L("Ability icon size"), db, "abilitySize", 10, 48, 2)
    form:Check(L("Show cooldown numbers"), db, "abilityNumbers")
    form:Check(L("Show ability border"), db, "abilityBorder")
    form:Check(L("Show autocast state"), db, "showAutocast")
    Bar.AddBorder(form, db)
    Bar.AddOptions(form, db)
    form:Header(L("Behavior"))
    form:Check(L("Hide when no pet"), db, "hideNoPet")
    form:Check(L("Hide the default pet frame"), db, "hideDefault")
    form:Check(L("Attach to the default pet frame"), db, "attachDefault")
    form:Stepper(L("Attach offset X"), db, "attachX", -400, 400, 1)
    form:Stepper(L("Attach offset Y"), db, "attachY", -400, 400, 1)
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
