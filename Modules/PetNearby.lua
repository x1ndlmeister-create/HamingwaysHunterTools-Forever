-- Pet ability alerts: popup when a beast nearby teaches a higher ability rank than you know and a pet of yours can use it.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI
local Data = HHT.PetData or { abilities = {} }

HHT:AddGerman({
    ["Pet ability alerts"] = "Begleiter-Faehigkeiten-Hinweis",
    ["Popup when a beast nearby teaches a higher ability rank your pet can learn."] = "Hinweis, wenn ein Tier in der Naehe einen hoeheren Faehigkeitsrang lehrt, den dein Begleiter lernen kann.",
    ["PET ABILITY NEARBY"] = "FAEHIGKEIT IN DER NAEHE",
    ["%s teaches %s %d"] = "%s lehrt %s %d",
    ["You know %s. For: %s."] = "Du kennst %s. Fuer: %s.",
    ["rank %d"] = "Rang %d",
    ["no rank yet"] = "noch keinen Rang",
    ["Target"] = "Anvisieren",
    ["Map"] = "Karte",
    ["Snooze 15 min"] = "15 Min. Pause",
    ["Ignore %s"] = "%s ignorieren",
    ["%s no longer triggers alerts. Re-enable it in the options."] = "%s loest keinen Hinweis mehr aus. Du kannst es in den Optionen wieder aktivieren.",
    ["Pet ability alerts paused for 15 minutes."] = "Hinweise fuer 15 Minuten pausiert.",
    ["Alert for"] = "Hinweis fuer",
    ["Active pet only"] = "Nur aktiver Begleiter",
    ["Every pet I have used"] = "Jeden Begleiter, den ich benutzt habe",
    ["Show for (seconds, 0 = until closed)"] = "Anzeigedauer (Sekunden, 0 = bis geschlossen)",
    ["Repeat for the same beast after (minutes)"] = "Wiederholung fuer dasselbe Tier nach (Minuten)",
    ["Play a sound"] = "Ton abspielen",
    ["Also inside dungeons"] = "Auch in Instanzen",
    ["Abilities that trigger an alert"] = "Faehigkeiten, die einen Hinweis ausloesen",
    ["Show test alert"] = "Test-Hinweis zeigen",
    ["Example Beast"] = "Beispiel-Tier",
    ["Alert border"] = "Rahmen Hinweis",
    ["Cower is rarely trained and is off by default."] = "Geduckt wird selten trainiert und ist standardmaessig aus.",
})

local alertFor = {}
for _, a in ipairs(Data.abilities) do alertFor[a.key] = (a.key ~= "cower") end

local M = HHT:NewModule("petnearby", {
    name = "Pet ability alerts",
    desc = "Popup when a beast nearby teaches a higher ability rank your pet can learn.",
    positions = { main = { "TOP", "TOP", 0, -170 } },
    defaults = {
        showFor = "all", duration = 15, repeatMinutes = 10, sound = true, inInstances = false,
        alertFor = alertFor,
        colors = { border = { 0.67, 0.83, 0.45 } },
    },
})

local W, H = 370, 112
local snoozeUntil, alerted, tamedNpc = 0, {}, nil

local function NpcId(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or type(guid) ~= "string" or HHT.IsSecret(guid) then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind ~= "Creature" then return nil end
    return tonumber(id)
end

local function StyleButton(b, text)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.17, 0.145, 0.105, 1)
    UI.Border(b, 1, 1, 1, 0.08)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.25)
    b.label = UI.Text(b, text, 11)
    b.label:SetPoint("CENTER")
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsPetNearby", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("DIALOG")
    self.frame = f
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.075, 0.068, 0.055, 0.96)
    f.border = UI.Border(f, 0.67, 0.83, 0.45, 0.9)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(44, 44)
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -12)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.eyebrow = UI.Text(f, "", 10, 0.67, 0.83, 0.45)
    f.eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", 64, -8)
    f.title = UI.Text(f, "", 13, 1, 1, 1)
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 64, -22)
    f.title:SetWidth(W - 100)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    f.sub = UI.Text(f, "", 11, 0.8, 0.8, 0.8)
    f.sub:SetPoint("TOPLEFT", f, "TOPLEFT", 64, -40)
    f.sub:SetWidth(W - 76)
    f.sub:SetJustifyH("LEFT")
    f.sub:SetJustifyV("TOP")
    f.sub:SetHeight(30)

    local close = UI.Button(f, 18, 18, "x", function() f:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    f.target = CreateFrame("Button", nil, f, "SecureActionButtonTemplate")
    f.target:SetSize(78, 20)
    f.target:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 8)
    f.target:RegisterForClicks("AnyUp")
    StyleButton(f.target, L("Target"))

    f.map = UI.Button(f, 56, 20, L("Map"), function()
        if f.beast and HHT.PetMap then HHT.PetMap:ShowBeasts({ f.beast }, true) end
    end)
    f.map:SetPoint("LEFT", f.target, "RIGHT", 6, 0)

    f.snooze = UI.Button(f, 96, 20, L("Snooze 15 min"), function()
        snoozeUntil = GetTime() + 900
        HHT.Print(L("Pet ability alerts paused for 15 minutes."))
        f:Hide()
    end)
    f.snooze:SetPoint("LEFT", f.map, "RIGHT", 6, 0)

    f.ignore = UI.Button(f, 108, 20, "", function()
        local key = f.abilityKey
        if key then
            M.db.alertFor[key] = false
            HHT.Print(string.format(L("%s no longer triggers alerts. Re-enable it in the options."), f.abilityName or key))
        end
        f:Hide()
    end)
    f.ignore:SetPoint("LEFT", f.snooze, "RIGHT", 6, 0)

    f:Hide()
    HHT:MakeMovable(f, self, "main", L("Pet ability alerts"))
end

function M:OnInit()
    for _, ev in ipairs({ "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT" }) do
        HHT:Listen(self, ev, "OnUnit")
    end
    HHT:Listen(self, "PLAYER_REGEN_DISABLED", "OnCombat")
    HHT:Listen(self, "UNIT_SPELLCAST_START", "OnCast")
    HHT:Every(self, 0.5, M.Tick)
end

function M:OnEnable()
    self:Build()
    self:Refresh()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
end

function M:Refresh()
    local f = self.frame
    if not f then return end
    local c = self.db.colors.border
    f.border:SetColor(c[1], c[2], c[3], 0.9)
    HHT:ApplyGlobalLook(f)
    if HHT:IsUnlocked() then self:Preview() elseif f.preview then f:Hide(); f.preview = nil end
end

function M:OnLockChanged() self:Refresh() end

function M:OnCombat()
    local f = self.frame
    if f and f:IsShown() and not f.preview then f:Hide() end
end

function M:OnCast(_, unit, _, spellId)
    if unit ~= "player" or HHT.IsSecret(spellId) then return end
    if spellId == 1515 then tamedNpc = NpcId("target") end
end

function M:Tick()
    local f = self.frame
    if f and f:IsShown() and f.hideAt and not f.preview and GetTime() > f.hideAt then f:Hide() end
end

-- data: icon, title, sub, beast, abilityKey, abilityName
function M:Show(data, preview)
    local f = self.frame
    if not f then return end
    local db = self.db
    f.icon:SetTexture(data.icon)
    f.eyebrow:SetText(L("PET ABILITY NEARBY"))
    f.title:SetText(data.title)
    f.sub:SetText(data.sub)
    f.beast, f.abilityKey, f.abilityName, f.preview = data.beast, data.abilityKey, data.abilityName, preview
    f.ignore.label:SetText(string.format(L("Ignore %s"), data.abilityName or ""))
    f.hideAt = (not preview and db.duration > 0) and (GetTime() + db.duration) or nil
    if not InCombatLockdown() then
        f.target:SetAttribute("type", "macro")
        f.target:SetAttribute("macrotext", "/targetexact " .. (data.beastName or ""))
    end
    f:Show()
end

function M:Preview()
    local PD = HHT.PetDex
    local a = PD and (PD.byKey.bite or PD.abilities[1])
    if not a then return end
    self:Show({
        icon = PD.AbilityIcon(a),
        title = string.format(L("%s teaches %s %d"), L("Example Beast"), PD.AbilityName(a), a.maxRank),
        sub = string.format(L("You know %s. For: %s."), string.format(L("rank %d"), math.max(1, a.maxRank - 1)), L("your pet")),
        abilityKey = a.key, abilityName = PD.AbilityName(a), beastName = "",
    }, true)
end

local function Ignored(db)
    local t = {}
    for k, v in pairs(db.alertFor) do if not v then t[k] = true end end
    return t
end

function M:OnUnit(event, unit)
    if event == "PLAYER_TARGET_CHANGED" then unit = "target" elseif event == "UPDATE_MOUSEOVER_UNIT" then unit = "mouseover" end
    if not unit or HHT:IsUnlocked() then return end
    local PD = HHT.PetDex
    if not PD or not PD.module.enabled then return end
    local db = self.db
    local id = NpcId(unit)
    local beast = id and PD.byId[id]
    if not beast then return end
    local now = GetTime()
    if now < snoozeUntil then return end
    if alerted[id] and now - alerted[id] < db.repeatMinutes * 60 then return end
    if HHT.InCombat() or (InCombatLockdown and InCombatLockdown()) then return end
    if (tonumber(UnitLevel("player")) or 0) < 10 then return end
    if not db.inInstances and IsInInstance and IsInInstance() then return end
    if HHT.SafeBool(UnitExists, unit) ~= true or HHT.SafeBool(UnitIsDead, unit) == true then return end
    if HHT.SafeBool(UnitPlayerControlled, unit) == true then return end
    local ul, pl = HHT.SafeNumber(UnitLevel(unit)), tonumber(UnitLevel("player")) or 0
    if ul and ul > 0 and ul > pl then return end
    if tamedNpc == id and UnitExists("pet") then return end
    local fams = PD.MyFamilies(db.showFor == "all")
    if not next(fams) then return end
    local best = PD.NewRank(beast, fams, Ignored(db))
    if not best then return end
    alerted[id] = now
    local name = (HHT.SafeBool(UnitExists, unit) and UnitName(unit)) or beast.n
    if HHT.IsSecret(name) or type(name) ~= "string" then name = beast.n end
    local abName = PD.AbilityName(best.a)
    local r = best.a.byRank[best.rank]
    local sub = string.format(L("You know %s. For: %s."),
        best.known > 0 and string.format(L("rank %d"), best.known) or L("no rank yet"), table.concat(best.fits, ", "))
    if r then sub = sub .. " " .. string.format(L("Needs pet level %d"), r.level) .. "." end
    self:Show({
        icon = PD.AbilityIcon(best.a),
        title = string.format(L("%s teaches %s %d"), name, abName, best.rank),
        sub = sub, beast = beast, abilityKey = best.a.key, abilityName = abName, beastName = name,
    })
    if db.sound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959) end
end

function M:BuildOptions(form)
    local db = self.db
    local PD = HHT.PetDex
    form:Header(L("Behavior"))
    form:Cycle(L("Alert for"), db, "showFor", { { "active", L("Active pet only") }, { "all", L("Every pet I have used") } })
    form:Stepper(L("Show for (seconds, 0 = until closed)"), db, "duration", 0, 60, 1)
    form:Stepper(L("Repeat for the same beast after (minutes)"), db, "repeatMinutes", 1, 60, 1)
    form:Check(L("Play a sound"), db, "sound")
    form:Check(L("Also inside dungeons"), db, "inInstances")
    form:Button(L("Show test alert"), function()
        if M.frame then M:Preview(); M.frame.preview = nil; M.frame.hideAt = GetTime() + math.max(5, db.duration) end
    end, 220)
    form:Header(L("Colors"))
    form:Color(L("Alert border"), db.colors, "border", function() M:Refresh() end)
    form:Header(L("Abilities that trigger an alert"))
    form:Note(L("Cower is rarely trained and is off by default."))
    if PD then
        for _, a in ipairs(PD.abilities) do
            form:Check(PD.AbilityName(a), db.alertFor, a.key)
        end
    end
end
