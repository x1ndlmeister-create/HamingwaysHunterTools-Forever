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
    ["Your pet knows %s. For: %s."] = "Dein Begleiter kennt %s. Fuer: %s.",
    ["Also alert for abilities my active pet does not have yet"] = "Auch bei Faehigkeiten hinweisen, die mein aktiver Begleiter noch nicht hat",
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
    ["List of upgrade beasts when entering a zone"] = "Liste mit Upgrade-Tieren beim Betreten einer Zone",
    ["Pet upgrade list"] = "Upgrade-Liste",
    ["PET UPGRADES IN THIS ZONE"] = "BEGLEITER-UPGRADES IN DIESER ZONE",
    ["Beasts here with abilities for your pet: %d"] = "Tiere hier mit Faehigkeiten fuer deinen Begleiter: %d",
    ["+%d more (see the pet database)"] = "+%d weitere (siehe Begleiter-Datenbank)",
    ["All on map"] = "Alle auf Karte",
    ["For: %s"] = "Fuer: %s",
    ["Click: show on map"] = "Klick: auf Karte zeigen",
    ["Right-click: arrow"] = "Rechtsklick: Pfeil",
    ["Shift-click: waypoint"] = "Shift-Klick: Wegpunkt",
})

local alertFor = {}
for _, a in ipairs(Data.abilities) do alertFor[a.key] = (a.key ~= "cower") end

local M = HHT:NewModule("petnearby", {
    name = "Pet ability alerts",
    desc = "Popup when a beast nearby teaches a higher ability rank your pet can learn.",
    positions = { main = { "TOP", "TOP", 0, -170 }, zone = { "TOP", "TOP", 0, -300 } },
    defaults = {
        showFor = "all", petGap = true, duration = 15, repeatMinutes = 10, sound = true, inInstances = false, zoneList = true,
        alertFor = alertFor,
        colors = { border = { 0.67, 0.83, 0.45 } },
    },
})

local W, H = 370, 112
local ZW, ZROWS, ROW_H, ROW_TOP = 400, 6, 22, 63
local RARE_COLOR = { rare = { 0.45, 0.75, 1 }, rareelite = { 0.75, 0.55, 1 }, elite = { 1, 0.82, 0.3 } }
local snoozeUntil, alerted, tamedNpc = 0, {}, nil
local zoneSeen = {}

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
    UI.Tint(bg, UI.PAL.button)
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
    f.border = UI.Panel(f, 0.67, 0.83, 0.45)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(44, 44)
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -12)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    HHT.Icon.Attach(f.icon)
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

    local close = UI.Button(f, 18, 18, "x", function() HHT.HideSecure(f) end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    f.target = CreateFrame("Button", nil, f, "SecureActionButtonTemplate")
    f.target:SetSize(78, 20)
    f.target:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 8)
    f.target:RegisterForClicks("AnyDown", "AnyUp")
    StyleButton(f.target, L("Target"))

    f.map = UI.Button(f, 56, 20, L("Map"), function()
        if f.beast and HHT.PetMap then HHT.PetMap:ShowBeasts({ f.beast }, true) end
    end)
    f.map:SetPoint("LEFT", f.target, "RIGHT", 6, 0)

    f.snooze = UI.Button(f, 96, 20, L("Snooze 15 min"), function()
        snoozeUntil = GetTime() + 900
        HHT.Print(L("Pet ability alerts paused for 15 minutes."))
        HHT.HideSecure(f)
    end)
    f.snooze:SetPoint("LEFT", f.map, "RIGHT", 6, 0)

    f.ignore = UI.Button(f, 108, 20, "", function()
        local key = f.abilityKey
        if key then
            M.db.alertFor[key] = false
            HHT.Print(string.format(L("%s no longer triggers alerts. Re-enable it in the options."), f.abilityName or key))
        end
        HHT.HideSecure(f)
    end)
    f.ignore:SetPoint("LEFT", f.snooze, "RIGHT", 6, 0)

    f:Hide()
    HHT:MakeMovable(f, self, "main", L("Pet ability alerts"))
    self:BuildZone()
end

function M:OnInit()
    for _, ev in ipairs({ "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT" }) do
        HHT:Listen(self, ev, "OnUnit")
    end
    HHT:Listen(self, "PLAYER_REGEN_DISABLED", "OnCombat")
    HHT:Listen(self, "PLAYER_REGEN_ENABLED", function(m)
        HHT.FlushHidden(m.frame)
        if m.zonePending then m.zonePending = nil; m:CheckZone() end
    end)
    HHT:Listen(self, "ZONE_CHANGED_NEW_AREA", "OnZone")
    HHT:Listen(self, "UNIT_SPELLCAST_START", "OnCast")
    HHT:Every(self, 0.5, M.Tick)
end

function M:OnEnable()
    self:Build()
    self:Refresh()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
    if self.zone then self.zone:Hide() end
end

function M:Refresh()
    local f = self.frame
    if not f then return end
    local c = self.db.colors.border
    f.border:SetColor(c[1], c[2], c[3], 0.9)
    HHT:ApplyGlobalLook(f)
    local z = self.zone
    if z then
        z.border:SetColor(c[1], c[2], c[3], 0.9)
        HHT:ApplyGlobalLook(z)
    end
    if HHT:IsUnlocked(self) then
        self:Preview()
        self:PreviewZone()
    else
        if f.preview then f:Hide(); f.preview = nil end
        if z and z.preview then z:Hide(); z.preview = nil end
    end
end

function M:OnLockChanged() self:Refresh() end

function M:OnCombat()
    local f = self.frame
    if f and f:IsShown() and not f.preview then HHT.HideSecure(f) end
    local z = self.zone
    if z and z:IsShown() and not z.preview then z:Hide() end
end

function M:OnCast(_, unit, _, spellId)
    if unit ~= "player" or HHT.IsSecret(spellId) then return end
    if spellId == 1515 then tamedNpc = NpcId("target") end
end

function M:Tick()
    local f = self.frame
    if f and f:IsShown() and f.hideAt and not f.preview and GetTime() > f.hideAt then HHT.HideSecure(f); f.hideAt = nil end
    local z = self.zone
    if z and z:IsShown() and z.hideAt and not z.preview and GetTime() > z.hideAt and not z:IsMouseOver() then z:Hide(); z.hideAt = nil end
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
    HHT.ShowSecure(f)
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

function M:Test()
    if not self.frame then return false end
    self:Preview()
    self.frame.preview = nil
    self.frame.hideAt = GetTime() + math.max(8, self.db.duration)
    return true
end

local function Ignored(db)
    local t = {}
    for k, v in pairs(db.alertFor) do if not v then t[k] = true end end
    return t
end

-- ---------------------------------------------------------------------------
-- Zone list: all beasts of the current zone that teach something a pet of yours can learn
-- ---------------------------------------------------------------------------
function M:BuildZone()
    if self.zone then return end
    local z = CreateFrame("Frame", "HamingwaysHunterToolsPetZone", UIParent)
    z:SetSize(ZW, 120)
    z:SetFrameStrata("DIALOG")
    self.zone = z
    z.border = UI.Panel(z, 0.67, 0.83, 0.45)

    z.icon = z:CreateTexture(nil, "ARTWORK")
    z.icon:SetSize(44, 44)
    z.icon:SetPoint("TOPLEFT", z, "TOPLEFT", 10, -12)
    z.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    HHT.Icon.Attach(z.icon)
    z.eyebrow = UI.Text(z, "", 10, 0.67, 0.83, 0.45)
    z.eyebrow:SetPoint("TOPLEFT", z, "TOPLEFT", 64, -8)
    z.title = UI.Text(z, "", 13, 1, 1, 1)
    z.title:SetPoint("TOPLEFT", z, "TOPLEFT", 64, -22)
    z.title:SetWidth(ZW - 100)
    z.title:SetJustifyH("LEFT")
    z.title:SetWordWrap(false)
    z.sub = UI.Text(z, "", 11, 0.8, 0.8, 0.8)
    z.sub:SetPoint("TOPLEFT", z, "TOPLEFT", 64, -40)
    z.sub:SetWidth(ZW - 76)
    z.sub:SetJustifyH("LEFT")
    z.sub:SetWordWrap(false)
    z.div = z:CreateTexture(nil, "ARTWORK")
    z.div:SetColorTexture(1, 1, 1, 0.08)
    z.div:SetHeight(1)
    z.div:SetPoint("TOPLEFT", z, "TOPLEFT", 10, -57)
    z.div:SetPoint("TOPRIGHT", z, "TOPRIGHT", -10, -57)

    local close = UI.Button(z, 18, 18, "x", function() z:Hide() end)
    close:SetPoint("TOPRIGHT", z, "TOPRIGHT", -4, -4)

    z.rows = {}
    for i = 1, ZROWS do
        local r = CreateFrame("Button", nil, z)
        r:SetSize(ZW - 20, ROW_H)
        r:SetPoint("TOPLEFT", z, "TOPLEFT", 10, -(ROW_TOP + (i - 1) * (ROW_H + 2)))
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local bg = r:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, 0.04)
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.2)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(16, 16)
        r.icon:SetPoint("LEFT", r, "LEFT", 4, 0)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        HHT.Icon.Attach(r.icon)
        r.name = UI.Text(r, "", 11, 1, 1, 1)
        r.name:SetPoint("LEFT", r, "LEFT", 28, 0)
        r.name:SetWidth(150)
        r.name:SetJustifyH("LEFT")
        r.name:SetWordWrap(false)
        r.lvl = UI.Text(r, "", 11, 0.65, 0.65, 0.65)
        r.lvl:SetPoint("LEFT", r, "LEFT", 182, 0)
        r.lvl:SetWidth(44)
        r.lvl:SetJustifyH("LEFT")
        r.ab = UI.Text(r, "", 11, 0.4, 0.93, 0.4)
        r.ab:SetPoint("LEFT", r, "LEFT", 228, 0)
        r.ab:SetWidth(ZW - 20 - 228 - 4)
        r.ab:SetJustifyH("LEFT")
        r.ab:SetWordWrap(false)
        r:SetScript("OnEnter", function(self)
            local b, best = self.beast, self.best
            if not b then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(b.n, 1, 1, 1)
            GameTooltip:AddLine(L(b.f) .. ", " .. L("Level") .. " " .. b.l, 0.7, 0.7, 0.7)
            if best then
                GameTooltip:AddLine(HHT.PetDex.AbilityName(best.a) .. " " .. best.rank, 0.4, 0.93, 0.4)
                GameTooltip:AddLine(string.format(L("For: %s"), table.concat(best.fits or {}, ", ")), 0.8, 0.8, 0.8, true)
            end
            GameTooltip:AddLine(L("Click: show on map"), 0.5, 0.8, 1)
            GameTooltip:AddLine(L("Right-click: arrow"), 0.5, 0.8, 1)
            GameTooltip:AddLine(L("Shift-click: waypoint"), 0.5, 0.8, 1)
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        r:SetScript("OnClick", function(self, button)
            local b, pm = self.beast, HHT.PetMap
            if not b or not pm then return end
            if IsShiftKeyDown() then
                pm:Waypoint(b)
            elseif button == "RightButton" then
                local pw = HHT.PetWatch
                if pw and pw.Track then pw.Track(b) end
            else
                pm:ShowBeasts({ b }, true)
            end
        end)
        r:Hide()
        z.rows[i] = r
    end

    z.more = UI.Text(z, "", 10, 0.6, 0.6, 0.6)
    z.mapAll = UI.Button(z, 100, 20, L("All on map"), function()
        local pm = HHT.PetMap
        if not (pm and z.list) then return end
        local t = {}
        for _, e in ipairs(z.list) do t[#t + 1] = e.beast end
        pm:ShowBeasts(t, true)
    end)
    z.mapAll:SetPoint("BOTTOMLEFT", z, "BOTTOMLEFT", 10, 8)
    z.snooze = UI.Button(z, 96, 20, L("Snooze 15 min"), function()
        snoozeUntil = GetTime() + 900
        HHT.Print(L("Pet ability alerts paused for 15 minutes."))
        z:Hide()
    end)
    z.snooze:SetPoint("LEFT", z.mapAll, "RIGHT", 6, 0)

    z:Hide()
    HHT:MakeMovable(z, self, "zone", L("Pet upgrade list"))
end

-- entries: { beast, best }; best = { a, rank, fits, petGap }
function M:ShowZone(entries, zoneName, preview)
    local z, PD = self.zone, HHT.PetDex
    if not (z and PD and #entries > 0) then return end
    local n = math.min(#entries, ZROWS)
    z.list, z.preview = entries, preview
    z.icon:SetTexture(PD.AbilityIcon(entries[1].best.a))
    z.eyebrow:SetText(L("PET UPGRADES IN THIS ZONE"))
    z.title:SetText(zoneName)
    z.sub:SetText(string.format(L("Beasts here with abilities for your pet: %d"), #entries))
    for i, r in ipairs(z.rows) do
        local e = entries[i]
        if i <= n then
            local b, best = e.beast, e.best
            local c = RARE_COLOR[b.r] or { 1, 1, 1 }
            r.beast, r.best = b, best
            r.icon:SetTexture(PD.AbilityIcon(best.a))
            r.name:SetText(b.n)
            r.name:SetTextColor(c[1], c[2], c[3])
            r.lvl:SetText(tostring(b.l))
            r.ab:SetText(PD.AbilityName(best.a) .. " " .. best.rank)
            if best.petGap then r.ab:SetTextColor(0.9, 0.9, 0.9) else r.ab:SetTextColor(0.4, 0.93, 0.4) end
            r:Show()
        else
            r.beast, r.best = nil, nil
            r:Hide()
        end
    end
    local y = ROW_TOP + n * (ROW_H + 2)
    z.more:ClearAllPoints()
    if #entries > n then
        z.more:SetText(string.format(L("+%d more (see the pet database)"), #entries - n))
        z.more:SetPoint("TOPLEFT", z, "TOPLEFT", 12, -(y + 1))
        z.more:Show()
        y = y + 15
    else
        z.more:Hide()
    end
    z:SetHeight(y + 3 + 20 + 8)
    z.hideAt = (not preview and self.db.duration > 0) and (GetTime() + math.max(self.db.duration, 20)) or nil
    z:Show()
end

function M:PreviewZone()
    local PD = HHT.PetDex
    if not (PD and self.zone) then return end
    local list = {}
    for _, b in ipairs(PD.beasts) do
        local e = PD.BeastAbilities(b)[1]
        if e and e.rank > 0 then
            list[#list + 1] = { beast = b, best = { a = e.a, rank = e.rank, known = 0, fits = { L("your pet") } } }
            if #list >= 3 then break end
        end
    end
    self:ShowZone(list, GetZoneText() or "?", true)
end

function M:TestZone()
    if not (HHT.PetDex and self.zone) then return false end
    self:PreviewZone()
    self.zone.preview = nil
    self.zone.hideAt = GetTime() + 30
    return true
end

function M:OnZone()
    if not self.db.zoneList or not (C_Timer and C_Timer.After) then return end
    C_Timer.After(2, function() if self.enabled then self:CheckZone() end end)
end

function M:CheckZone()
    local db, PD = self.db, HHT.PetDex
    if not (db.zoneList and PD and PD.module.enabled and HHT.PetMap and C_Map and C_Map.GetBestMapForUnit) then return end
    if HHT:IsUnlocked(self) or GetTime() < snoozeUntil then return end
    local pl = tonumber(UnitLevel("player")) or 0
    if pl < 10 then return end
    if not db.inInstances and IsInInstance and IsInInstance() then return end
    if HHT.InCombat() or InCombatLockdown() then self.zonePending = true; return end
    local okM, map = pcall(C_Map.GetBestMapForUnit, "player")
    if not okM or not map then return end
    local now = GetTime()
    if zoneSeen[map] and now - zoneSeen[map] < db.repeatMinutes * 60 then return end
    local fams = PD.MyFamilies(db.showFor == "all")
    if not next(fams) then return end
    local ign, list = Ignored(db), {}
    for _, b in ipairs(PD.beasts) do
        if b.sp and b.sp[map] and b.lo <= pl then
            local best = PD.NewRank(b, fams, ign)
            if not best and db.petGap then best = PD.PetGap(b, ign) end
            if best then list[#list + 1] = { beast = b, best = best } end
        end
    end
    if #list == 0 then return end
    zoneSeen[map] = now
    table.sort(list, function(x, y)
        local gx, gy = x.best.rank - x.best.known, y.best.rank - y.best.known
        if gx ~= gy then return gx > gy end
        if x.beast.lo ~= y.beast.lo then return x.beast.lo < y.beast.lo end
        return x.beast.n < y.beast.n
    end)
    local zoneName
    local okI, info = pcall(C_Map.GetMapInfo, map)
    if okI and type(info) == "table" and type(info.name) == "string" then zoneName = info.name end
    self:ShowZone(list, zoneName or GetZoneText() or "?")
    if db.sound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959) end
end

function M:OnUnit(event, unit)
    if event == "PLAYER_TARGET_CHANGED" then unit = "target" elseif event == "UPDATE_MOUSEOVER_UNIT" then unit = "mouseover" end
    if not unit or HHT:IsUnlocked(self) then return end
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
    if not best and db.petGap then best = PD.PetGap(beast, Ignored(db)) end
    if not best then return end
    alerted[id] = now
    local name = (HHT.SafeBool(UnitExists, unit) and UnitName(unit)) or beast.n
    if HHT.IsSecret(name) or type(name) ~= "string" then name = beast.n end
    local abName = PD.AbilityName(best.a)
    local r = best.a.byRank[best.rank]
    local sub = string.format(L(best.petGap and "Your pet knows %s. For: %s." or "You know %s. For: %s."),
        best.known > 0 and string.format(L("rank %d"), best.known) or L("no rank yet"), table.concat(best.fits, ", "))
    if r then sub = sub .. " " .. string.format(L("Needs pet level %d"), r.level) .. "." end
    self:Show({
        icon = PD.AbilityIcon(best.a),
        title = string.format(L("%s teaches %s %d"), name, abName, best.rank),
        sub = sub, beast = beast, abilityKey = best.a.key, abilityName = abName, beastName = name,
    })
    if db.sound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959) end
end

function M:Why()
    local P = HHT.Print
    local PD = HHT.PetDex
    local unit = UnitExists("target") and "target" or "mouseover"
    local id = NpcId(unit)
    P(string.format("nearby: unit=%s npc=%s petdex=%s snooze=%s alerted=%s", unit, tostring(id), tostring(PD and PD.module.enabled), tostring(GetTime() < snoozeUntil), tostring(id and alerted[id] ~= nil)))
    local beast = id and PD and PD.byId[id]
    P("beast in data: " .. tostring(beast and beast.n))
    P(string.format("combat=%s instance=%s unlocked=%s tamedNpc=%s", tostring(HHT.InCombat()), tostring(IsInInstance and IsInInstance()), tostring(HHT:IsUnlocked(self)), tostring(tamedNpc)))
    P(string.format("levels: player=%s unit=%s", tostring(UnitLevel("player")), tostring(HHT.SafeNumber(UnitLevel(unit)))))
    if not (PD and beast) then return end
    local fams = PD.MyFamilies(self.db.showFor == "all")
    local list = {}
    for fam, who in pairs(fams) do list[#list + 1] = fam .. "=" .. who end
    P("families: " .. (#list > 0 and table.concat(list, "; ") or "none"))
    for _, e in ipairs(PD.BeastAbilities(beast)) do
        P(string.format("teaches %s rank %d, known rank %d, ignored=%s", e.a.key, e.rank, PD.KnownRank(e.a.key), tostring(self.db.alertFor[e.a.key] == false)))
    end
    local best = PD.NewRank(beast, fams, Ignored(self.db))
    P("result: " .. (best and (best.a.key .. " " .. best.rank) or "no alert"))
end

function M:BuildOptions(form)
    local db = self.db
    local PD = HHT.PetDex
    form:Header(L("Behavior"))
    form:Cycle(L("Alert for"), db, "showFor", { { "active", L("Active pet only") }, { "all", L("Every pet I have used") } })
    form:Check(L("Also alert for abilities my active pet does not have yet"), db, "petGap")
    form:Check(L("List of upgrade beasts when entering a zone"), db, "zoneList")
    form:Stepper(L("Show for (seconds, 0 = until closed)"), db, "duration", 0, 60, 1)
    form:Stepper(L("Repeat for the same beast after (minutes)"), db, "repeatMinutes", 1, 60, 1)
    form:Check(L("Play a sound"), db, "sound")
    form:Check(L("Also inside dungeons"), db, "inInstances")
    form:Button(L("Show test alert"), function()
        if M.frame then M:Preview(); M.frame.preview = nil; M.frame.hideAt = GetTime() + math.max(5, db.duration) end
        if M.zone then M:PreviewZone(); M.zone.preview = nil; M.zone.hideAt = GetTime() + math.max(8, db.duration) end
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
