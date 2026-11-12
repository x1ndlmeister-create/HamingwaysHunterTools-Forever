-- Beast watch: discovery tracking, unit tooltip info, rare/wishlist alerts and a direction arrow.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Beast watch"] = "Tierbeobachtung",
    ["Tooltip info, rare and wishlist alerts, discovery tracking and a direction arrow to rare beasts."] = "Tooltip-Info, Hinweise bei Seltenen und Wunschlisten-Tieren, Entdeckungsstand und ein Richtungspfeil zu Seltenen.",
    ["Tooltip"] = "Tooltip",
    ["Show taming info in the unit tooltip"] = "Zaehm-Infos im Einheiten-Tooltip zeigen",
    ["Discovery"] = "Entdeckungsstand",
    ["Mark beasts as seen"] = "Tiere als gesehen markieren",
    ["Alerts"] = "Hinweise",
    ["Alert for rare beasts"] = "Hinweis bei seltenen Tieren",
    ["Alert for wishlist beasts"] = "Hinweis bei Wunschlisten-Tieren",
    ["Alert when close to a known spawn"] = "Hinweis nahe bekannter Spawnpunkte",
    ["Spawn distance (yards)"] = "Spawn-Entfernung (Meter)",
    ["Only beasts up to my level"] = "Nur Tiere bis zu meinem Level",
    ["Direction arrow"] = "Richtungspfeil",
    ["Show the direction arrow"] = "Richtungspfeil anzeigen",
    ["Point at a rare automatically when it is close"] = "Automatisch auf ein nahes Seltenes zeigen",
    ["Arrow size"] = "Pfeilgroesse",
    ["Rare arrow"] = "Seltenen-Pfeil",
    ["Beast alert"] = "Tier-Hinweis",
    ["RARE BEAST"] = "SELTENES TIER",
    ["WISHLIST BEAST"] = "WUNSCHLISTEN-TIER",
    ["POSSIBLE RARE NEARBY"] = "SELTENES TIER MOEGLICH",
    ["POSSIBLE WISHLIST BEAST NEARBY"] = "WUNSCHLISTEN-TIER MOEGLICH",
    ["Arrow"] = "Pfeil",
    ["Arrow off"] = "Pfeil aus",
    ["Wishlist"] = "Wunschliste",
    ["* Wishlist"] = "* Wunschliste",
    ["Teaches: %s"] = "Lehrt: %s",
    ["Tameable"] = "Zaehmbar",
    ["Teaches %s (new for %s)"] = "Lehrt %s (neu fuer %s)",
    ["Teaches %s"] = "Lehrt %s",
    ["Teaches no ability"] = "Lehrt keine Faehigkeit",
    ["%d yd"] = "%d m",
    ["Other zone: %s"] = "Andere Zone: %s",
    ["Show test alert"] = "Test-Hinweis zeigen",
    ["Also inside dungeons"] = "Auch in Instanzen",
    ["Play a sound"] = "Ton abspielen",
    ["Show for (seconds, 0 = until closed)"] = "Anzeigedauer (Sekunden, 0 = bis geschlossen)",
    ["Repeat for the same beast after (minutes)"] = "Wiederholung fuer dasselbe Tier nach (Minuten)",
    ["Alert border"] = "Rahmen Hinweis",
    ["Example Beast"] = "Beispiel-Tier",
    ["Show the test arrow"] = "Test-Pfeil zeigen",
    ["Beast alerts paused for 15 minutes."] = "Hinweise fuer 15 Minuten pausiert.",
    ["Snooze 15 min"] = "15 Min. Pause",
    ["Target"] = "Anvisieren",
    ["Map"] = "Karte",
    ["The arrow uses the spawn points of the pet database. Drag it while the frames are unlocked."] = "Der Pfeil nutzt die Spawnpunkte der Begleiter-Datenbank. Ziehe ihn, solange die Fenster entsperrt sind.",
    ["%s added to your wishlist."] = "%s wurde zur Wunschliste hinzugefuegt.",
    ["%s removed from your wishlist."] = "%s wurde von der Wunschliste entfernt.",
    ["Arrow points to %s."] = "Der Pfeil zeigt auf %s.",
})

local M = HHT:NewModule("petwatch", {
    name = "Beast watch",
    desc = "Tooltip info, rare and wishlist alerts, discovery tracking and a direction arrow to rare beasts.",
    positions = { main = { "TOP", "TOP", 0, -250 }, arrow = { "CENTER", "CENTER", 0, 160 } },
    defaults = {
        tooltip = true, markSeen = true,
        rareAlert = true, wishAlert = true, nearAlert = true, nearYards = 150, onlyMyLevel = true,
        sound = true, duration = 20, repeatMinutes = 10, inInstances = false,
        arrow = true, arrowAuto = false, arrowSize = 64,
        colors = { border = { 0.75, 0.55, 1 } },
    },
})

local PW = {}
HHT.PetWatch = PW

local W, H = 370, 112
local ARROW_TEX = "Interface\\Minimap\\ROTATING-MINIMAPARROW"
local snoozeUntil, alerted = 0, {}
local tameId, tameAt
local mapBeasts = {}
local RARE_COLOR = { rare = { 0.45, 0.75, 1 }, rareelite = { 0.75, 0.55, 1 }, elite = { 1, 0.82, 0.3 } }

local function PD() return HHT.PetDex end
local function PM() return HHT.PetMap end

local function NpcId(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or type(guid) ~= "string" or HHT.IsSecret(guid) then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind ~= "Creature" then return nil end
    return tonumber(id)
end

local function PlayerLevel() return tonumber(UnitLevel("player")) or 0 end

-- ---------------------------------------------------------------------------
-- Tooltip
-- ---------------------------------------------------------------------------
local function HasLine(tt, text)
    local name = tt:GetName()
    for i = 1, tt:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local t = fs and fs:GetText()
        if type(t) == "string" and not HHT.IsSecret(t) and t == text then return true end
    end
    return false
end

local function AddTooltip(tt)
    PW.tipCalls = (PW.tipCalls or 0) + 1
    if not M.enabled or not M.db.tooltip or tt ~= GameTooltip then return end
    local pd = PD()
    if not pd then return end
    local ok, _, unit = pcall(tt.GetUnit, tt)
    if not ok or type(unit) ~= "string" or HHT.IsSecret(unit) then unit = "mouseover" end
    local id = NpcId(unit)
    local b = id and pd.byId[id]
    if not id then return end
    local fam, lvl
    if not b then
        local okF, f = pcall(UnitCreatureFamily, unit)
        if not okF or type(f) ~= "string" or HHT.IsSecret(f) or f == "" then return end
        if HHT.SafeBool(UnitPlayerControlled, unit) == true then return end
        local l = HHT.SafeNumber(UnitLevel(unit))
        fam, lvl = f, (l and l > 0) and tostring(l) or "??"
    end
    local rl = b and pd.RarityLabel(b)
    pd.RecordSpeed(id, unit)
    local head = L("Tameable") .. ": " .. (b and L(b.f) or fam) .. ", " .. L("Level") .. " " .. (b and b.l or lvl) .. (rl and (", " .. rl) or "")
    local okHas, has = pcall(HasLine, tt, head)
    if okHas and has then return end
    local okN, n0 = pcall(tt.NumLines, tt)
    if okN and type(n0) == "number" and tt.hhtStamp == id .. ":" .. n0 then return end
    tt:AddLine(head, 0.67, 0.83, 0.45)
    if pd.module.db.showSpeed and pd.Speed(id) then
        tt:AddLine(string.format(L("Attack speed: %s"), pd.SpeedText(id)), 0.9, 0.9, 0.9)
    end
    if not b then
        tt:AddLine(L("Teaches no ability"), 0.6, 0.6, 0.6)
        PW.tipAdded = (PW.tipAdded or 0) + 1
        pcall(tt.Show, tt)
        local okU, n2 = pcall(tt.NumLines, tt)
        tt.hhtStamp = (okU and type(n2) == "number") and (id .. ":" .. n2) or nil
        return
    end
    local fams = pd.MyFamilies(true)
    for _, e in ipairs(pd.BeastAbilities(b)) do
        local name = pd.AbilityName(e.a)
        if e.rank > 0 then name = name .. " " .. e.rank end
        if e.rank > 0 and e.rank > pd.KnownRank(e.a.key) and pd.Applies(e.a, fams) then
            local who = {}
            for fam, pet in pairs(fams) do
                if e.a.all or e.a.famSet[fam] then who[#who + 1] = pet end
            end
            table.sort(who)
            tt:AddLine(string.format(L("Teaches %s (new for %s)"), name, table.concat(who, ", ")), 0.4, 0.95, 0.4)
        else
            tt:AddLine(string.format(L("Teaches %s"), name), 0.6, 0.6, 0.6)
        end
    end
    tt:AddLine(pd.StatusText(b), 1, 0.82, 0.3)
    PW.tipAdded = (PW.tipAdded or 0) + 1
    pcall(tt.Show, tt)
    local okM, n1 = pcall(tt.NumLines, tt)
    tt.hhtStamp = (okM and type(n1) == "number") and (id .. ":" .. n1) or nil
end

local tipHooked
local function HookTooltip()
    if tipHooked then return end
    tipHooked = true
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Unit, function(tt) AddTooltip(tt) end)
    end
    if GameTooltip and GameTooltip.HookScript then
        pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", function(tt) AddTooltip(tt) end)
        pcall(GameTooltip.HookScript, GameTooltip, "OnShow", function(tt) AddTooltip(tt) end)
    end
end

function M:TipTick()
    if GameTooltip and GameTooltip:IsShown() and HHT.SafeBool(UnitExists, "mouseover") == true then AddTooltip(GameTooltip) end
end

-- ---------------------------------------------------------------------------
-- Alert bar
-- ---------------------------------------------------------------------------
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

local function UpdateButtons()
    local f = M.frame
    if not f then return end
    local b = f.beast
    local tracking = b and M.track == b
    f.arrowBtn.label:SetText(tracking and L("Arrow off") or L("Arrow"))
    f.wishBtn.label:SetText((b and PD() and PD().IsWish(b.id)) and L("* Wishlist") or L("Wishlist"))
end

-- An arrow that started by itself goes away together with its alert.
local function CloseAlert()
    if M.frame then HHT.HideSecure(M.frame); M.frame.hideAt = nil end
    if M.trackAuto then PW.Track(nil) end
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsPetWatch", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("DIALOG")
    self.frame = f
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.075, 0.068, 0.055, 0.96)
    f.border = UI.Border(f, 0.75, 0.55, 1, 0.9)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(44, 44)
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -12)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.eyebrow = UI.Text(f, "", 10, 0.75, 0.55, 1)
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

    local close = UI.Button(f, 18, 18, "x", CloseAlert)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    f.target = CreateFrame("Button", nil, f, "SecureActionButtonTemplate")
    f.target:SetSize(70, 20)
    f.target:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 8)
    f.target:RegisterForClicks("AnyUp")
    StyleButton(f.target, L("Target"))

    f.map = UI.Button(f, 48, 20, L("Map"), function()
        if f.beast and PM() then PM():ShowBeasts({ f.beast }, true) end
    end)
    f.map:SetPoint("LEFT", f.target, "RIGHT", 6, 0)

    f.arrowBtn = UI.Button(f, 66, 20, L("Arrow"), function()
        local b = f.beast
        if not b then return end
        if M.track == b then PW.Track(nil) else PW.Track(b) end
    end)
    f.arrowBtn:SetPoint("LEFT", f.map, "RIGHT", 6, 0)

    f.wishBtn = UI.Button(f, 90, 20, L("Wishlist"), function()
        local b, pd = f.beast, PD()
        if not b or not pd then return end
        local on = not pd.IsWish(b.id)
        pd.SetWish(b.id, on)
        HHT.Print(string.format(L(on and "%s added to your wishlist." or "%s removed from your wishlist."), b.n))
        UpdateButtons()
    end)
    f.wishBtn:SetPoint("LEFT", f.arrowBtn, "RIGHT", 6, 0)

    f.snooze = UI.Button(f, 36, 20, "zZ", function()
        snoozeUntil = GetTime() + 900
        HHT.Print(L("Beast alerts paused for 15 minutes."))
        CloseAlert()
    end)
    f.snooze:SetPoint("LEFT", f.wishBtn, "RIGHT", 6, 0)

    f:Hide()
    HHT:MakeMovable(f, self, "main", L("Beast alert"))
end

local function BuildArrow()
    if M.arrowFrame then return end
    local a = CreateFrame("Frame", "HamingwaysHunterToolsPetArrow", UIParent)
    a:SetFrameStrata("HIGH")
    M.arrowFrame = a
    a.tex = a:CreateTexture(nil, "ARTWORK")
    a.tex:SetPoint("TOP", a, "TOP", 0, 0)
    a.tex:SetTexture(ARROW_TEX)
    a.name = UI.Text(a, "", 12, 1, 1, 1)
    a.name:SetPoint("TOP", a.tex, "BOTTOM", 0, -2)
    a.name:SetWidth(200)
    a.dist = UI.Text(a, "", 12, 0.75, 0.55, 1)
    a.dist:SetPoint("TOP", a.name, "BOTTOM", 0, -2)
    a.stop = UI.Button(a, 16, 16, "x", function() PW.Track(nil) end)
    a.stop:SetPoint("TOPRIGHT", a, "TOPRIGHT", 14, 0)
    a:Hide()
    HHT:MakeMovable(a, M, "arrow", L("Rare arrow"))
end

local function LayoutArrow()
    local a = M.arrowFrame
    if not a then return end
    local s = M.db.arrowSize
    a:SetSize(math.max(s, 90), s + 36)
    a.tex:SetSize(s, s)
    local c = M.db.colors.border
    a.tex:SetVertexColor(c[1], c[2], c[3])
    a.dist:SetTextColor(c[1], c[2], c[3])
end

function M:OnInit()
    for _, ev in ipairs({ "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT" }) do
        HHT:Listen(self, ev, "OnUnit")
    end
    HHT:Listen(self, "PLAYER_REGEN_DISABLED", "OnCombat")
    HHT:Listen(self, "PLAYER_REGEN_ENABLED", "OnCombatEnd")
    HHT:Listen(self, "UNIT_SPELLCAST_START", "OnCast")
    HHT:Listen(self, "UNIT_SPELLCAST_CHANNEL_START", "OnCast")
    HHT:Listen(self, "UNIT_PET", "OnPet")
    HHT:Every(self, 0.5, M.Tick)
    HHT:Every(self, 0.2, M.TipTick)
    HHT:Every(self, 2, M.NearTick)
    HHT:Every(self, 0.05, M.ArrowTick)
    HookTooltip()
end

function M:OnEnable()
    self:Build()
    BuildArrow()
    LayoutArrow()
    self:Refresh()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
    if self.arrowFrame then self.arrowFrame:Hide() end
    self.track = nil
end

function M:Refresh()
    local f = self.frame
    if not f then return end
    local c = self.db.colors.border
    f.border:SetColor(c[1], c[2], c[3], 0.9)
    HHT:ApplyGlobalLook(f)
    if self.arrowFrame then HHT:ApplyGlobalLook(self.arrowFrame) end
    LayoutArrow()
    if HHT:IsUnlocked() then self:Preview() elseif f.preview then f:Hide(); f.preview = nil end
end

function M:OnLockChanged() self:Refresh() end

function M:OnCombat()
    local f = self.frame
    if f and f:IsShown() and not f.preview then HHT.HideSecure(f) end
end

function M:OnCombatEnd()
    HHT.FlushHidden(self.frame)
    local p = self.pending
    self.pending = nil
    if p and GetTime() - p.at < 30 then self:Show(p) end
end

-- Taming: remember the target when the cast starts, confirm with the new pet.
function M:OnCast(_, unit, _, spellId)
    if unit ~= "player" or HHT.IsSecret(spellId) or spellId ~= 1515 then return end
    tameId, tameAt = NpcId("target"), GetTime()
end

function M:OnPet(_, unit)
    if unit ~= "player" or not tameId then return end
    if GetTime() - (tameAt or 0) > 60 then tameId = nil; return end
    if HHT.SafeBool(UnitExists, "pet") == true and PD() then
        PD().MarkTamed(tameId)
        PD().RecordSpeed(tameId, "pet")
        tameId = nil
    end
end

function M:Tick()
    local f = self.frame
    if f and f:IsShown() and f.hideAt and not f.preview and GetTime() > f.hideAt then CloseAlert() end
end

-- data: kind (rare, wish, near), beast, name
function M:Show(data, preview)
    local f = self.frame
    local pd = PD()
    if not f or not pd then return end
    local b, db = data.beast, self.db
    local eyebrow = ({
        rare = "RARE BEAST", wish = "WISHLIST BEAST",
        nearrare = "POSSIBLE RARE NEARBY", nearwish = "POSSIBLE WISHLIST BEAST NEARBY",
    })[data.kind] or "RARE BEAST"
    local c = RARE_COLOR[b.r] or db.colors.border
    f.border:SetColor(c[1], c[2], c[3], 0.9)
    f.eyebrow:SetText(L(eyebrow))
    f.eyebrow:SetTextColor(c[1], c[2], c[3])
    f.icon:SetTexture(pd.FamilyIcon(b.f))
    f.title:SetText(data.name or b.n)
    local abil = {}
    for _, e in ipairs(pd.BeastAbilities(b)) do
        abil[#abil + 1] = pd.AbilityName(e.a) .. (e.rank > 0 and (" " .. e.rank) or "")
    end
    local line2 = #abil > 0 and string.format(L("Teaches: %s"), table.concat(abil, ", ")) or ""
    local line1 = L(b.f) .. ", " .. L("Level") .. " " .. b.l .. " - " .. pd.ZoneName(b)
    f.sub:SetText(line1 .. "\n" .. line2)
    f.beast, f.preview = b, preview
    f.hideAt = (not preview and db.duration > 0) and (GetTime() + db.duration) or nil
    if not InCombatLockdown() then
        f.target:SetAttribute("type", "macro")
        f.target:SetAttribute("macrotext", "/targetexact " .. b.n)
    end
    UpdateButtons()
    HHT.ShowSecure(f)
end

function M:Preview()
    local pd = PD()
    if not pd or not self.frame then return end
    local b
    for _, x in ipairs(pd.beasts) do if x.r then b = x; break end end
    if b then self:Show({ kind = "rare", beast = b }, true) end
    local a = self.arrowFrame
    if a then
        a:Show()
        a.name:SetText(L("Rare arrow"))
        a.dist:SetText(string.format(L("%d yd"), 123))
        a.tex:SetRotation(0)
    end
end

-- ---------------------------------------------------------------------------
-- Sightings
-- ---------------------------------------------------------------------------
function M:Test()
    if not self.frame then return false end
    self:Preview()
    self.frame.preview = nil
    self.frame.hideAt = GetTime() + math.max(8, self.db.duration)
    return true
end
local function Allowed(db)
    if HHT:IsUnlocked() then return false end
    if GetTime() < snoozeUntil then return false end
    if not db.inInstances and IsInInstance and IsInInstance() then return false end
    return true
end

function M:OnUnit(event, unit)
    if event == "PLAYER_TARGET_CHANGED" then unit = "target" elseif event == "UPDATE_MOUSEOVER_UNIT" then unit = "mouseover" end
    if not unit or HHT.IsSecret(unit) then return end
    if unit == "mouseover" and GameTooltip and GameTooltip:IsShown() then AddTooltip(GameTooltip) end
    local pd = PD()
    if not pd or not pd.module.enabled then return end
    local id = NpcId(unit)
    local b = id and pd.byId[id]
    if not b then return end
    if HHT.SafeBool(UnitExists, unit) ~= true or HHT.SafeBool(UnitPlayerControlled, unit) == true then return end
    pd.RecordSpeed(id, unit)
    local db = self.db
    if db.markSeen then pd.MarkSeen(id) end
    local kind
    if b.r and db.rareAlert then kind = "rare" end
    if pd.IsWish(id) and db.wishAlert then kind = "wish" end
    if not kind or not Allowed(db) or HHT.SafeBool(UnitIsDead, unit) == true then return end
    local now = GetTime()
    if alerted[id] and now - alerted[id] < db.repeatMinutes * 60 then return end
    local name = UnitName(unit)
    if HHT.IsSecret(name) or type(name) ~= "string" then name = b.n end
    local data = { kind = kind, beast = b, name = name, at = now }
    if HHT.InCombat() or InCombatLockdown() then
        self.pending = data
        return
    end
    alerted[id] = now
    self:Show(data)
    if db.sound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959) end
end

-- ---------------------------------------------------------------------------
-- Close to a known spawn
-- ---------------------------------------------------------------------------
local function BeastsOn(map)
    local t = mapBeasts[map]
    if not t then
        t = {}
        for _, b in ipairs(PD().beasts) do
            if b.sp and b.sp[map] then t[#t + 1] = b end
        end
        mapBeasts[map] = t
    end
    return t
end

-- Nearest known spawn of b on map as dist, x, y.
local function NearestSpawn(b, map, px, py)
    local best, bx, by
    for _, pt in ipairs(PM().Points(b, map)) do
        local dx, dy = PM().Offset(map, px, py, pt[1], pt[2])
        local d = math.sqrt(dx * dx + dy * dy)
        if not best or d < best then best, bx, by = d, pt[1], pt[2] end
    end
    return best, bx, by
end

function M:NearTick()
    local db = self.db
    local pd = PD()
    if not db.nearAlert or not pd or not pd.module.enabled or not PM() then return end
    if not (db.rareAlert or db.wishAlert) or not Allowed(db) then return end
    if HHT.InCombat() or InCombatLockdown() then return end
    if self.frame and self.frame:IsShown() then return end
    local map, px, py = PM().PlayerPos()
    if not map then return end
    local now, pl = GetTime(), PlayerLevel()
    local best, bestD, bestKind
    for _, b in ipairs(BeastsOn(map)) do
        local wish = pd.IsWish(b.id) and db.wishAlert
        local rare = b.r and db.rareAlert and not pd.IsTamed(b.id) and (not db.onlyMyLevel or b.lo <= pl)
        local key = "near" .. b.id
        if (wish or rare) and not (alerted[key] and now - alerted[key] < db.repeatMinutes * 60) then
            local d = NearestSpawn(b, map, px, py)
            if d and d <= db.nearYards and (not bestD or d < bestD) then
                best, bestD, bestKind = b, d, wish and "nearwish" or "nearrare"
            end
        end
    end
    if not best then return end
    alerted["near" .. best.id] = now
    self:Show({ kind = bestKind, beast = best, at = now })
    if db.sound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959) end
    if db.arrow and db.arrowAuto and not self.track then PW.Track(best, true, true) end
end

-- ---------------------------------------------------------------------------
-- Arrow
-- ---------------------------------------------------------------------------
function PW.Track(b, quiet, auto)
    if not M.enabled then return end
    if b and not M.db.arrow then return end
    M.track = b
    M.trackAuto = (b and auto) and true or false
    if b and not quiet then HHT.Print(string.format(L("Arrow points to %s."), b.n)) end
    UpdateButtons()
    M:ArrowTick()
end

-- Points the arrow at a rare from the database, preferably one on the player's map.
function PW.TestArrow()
    local pd = PD()
    if not (pd and M.enabled and M.db.arrow) then return false end
    local map = PM() and PM().PlayerPos()
    local pick
    for _, b in ipairs(pd.beasts) do
        if b.r and b.sp and next(b.sp) and (not pick or (map and b.sp[map])) then
            pick = b
            if map and b.sp[map] then break end
        end
    end
    if not pick then return false end
    PW.Track(pick)
    return true
end

function M:ArrowTick()
    local a = self.arrowFrame
    if not a then return end
    local b = self.track
    if not b then
        if not HHT:IsUnlocked() then a:Hide() end
        return
    end
    a:Show()
    a.name:SetText(b.n)
    local map, px, py = PM().PlayerPos()
    if map and b.sp and b.sp[map] then
        local _, tx, ty = NearestSpawn(b, map, px, py)
        local dx, dy = PM().Offset(map, px, py, tx, ty)
        local facing = (GetPlayerFacing and GetPlayerFacing()) or 0
        local bearing = math.atan2(dx, -dy)
        a.tex:Show()
        a.tex:SetRotation(-(bearing + facing))
        a.dist:SetText(string.format(L("%d yd"), math.floor(math.sqrt(dx * dx + dy * dy) + 0.5)))
    else
        a.tex:Hide()
        a.dist:SetText(string.format(L("Other zone: %s"), PD().ZoneName(b)))
    end
end

function PW.Debug()
    local pd = PD()
    local s, t, total = pd.Progress()
    local w = 0
    for _ in pairs(PD().module.db.wish) do w = w + 1 end
    HHT.Print(string.format("petwatch: enabled=%s seen=%d tamed=%d total=%d wish=%d track=%s", tostring(M.enabled), s, t, total, w, tostring(M.track and M.track.n)))
    local map, x, y = PM().PlayerPos()
    HHT.Print("pos: map=" .. tostring(map) .. " x=" .. tostring(x) .. " y=" .. tostring(y) .. " facing=" .. tostring(GetPlayerFacing and GetPlayerFacing()))
    local unit = HHT.SafeBool(UnitExists, "mouseover") and "mouseover" or "target"
    local id = NpcId(unit)
    local b = id and pd.byId[id]
    HHT.Print(string.format("tooltip: opt=%s calls=%s added=%s processor=%s unit=%s npc=%s beast=%s abilities=%s", tostring(M.db.tooltip), tostring(PW.tipCalls), tostring(PW.tipAdded),
        tostring(TooltipDataProcessor ~= nil), unit, tostring(id), tostring(b and b.n), tostring(b and #pd.BeastAbilities(b))))
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Tooltip"))
    form:Check(L("Show taming info in the unit tooltip"), db, "tooltip")
    form:Header(L("Discovery"))
    form:Check(L("Mark beasts as seen"), db, "markSeen")
    form:Header(L("Alerts"))
    form:Check(L("Alert for rare beasts"), db, "rareAlert")
    form:Check(L("Alert for wishlist beasts"), db, "wishAlert")
    form:Check(L("Alert when close to a known spawn"), db, "nearAlert")
    form:Stepper(L("Spawn distance (yards)"), db, "nearYards", 50, 500, 25)
    form:Check(L("Only beasts up to my level"), db, "onlyMyLevel")
    form:Check(L("Play a sound"), db, "sound")
    form:Check(L("Also inside dungeons"), db, "inInstances")
    form:Stepper(L("Show for (seconds, 0 = until closed)"), db, "duration", 0, 60, 1)
    form:Stepper(L("Repeat for the same beast after (minutes)"), db, "repeatMinutes", 1, 60, 1)
    form:Button(L("Show test alert"), function()
        if M.frame then
            M:Preview()
            M.frame.preview = nil
            M.frame.hideAt = GetTime() + math.max(5, db.duration)
        end
    end, 220)
    form:Header(L("Direction arrow"))
    form:Note(L("The arrow uses the spawn points of the pet database. Drag it while the frames are unlocked."))
    form:Check(L("Show the direction arrow"), db, "arrow", function()
        if not db.arrow then PW.Track(nil) end
    end)
    form:Check(L("Point at a rare automatically when it is close"), db, "arrowAuto")
    form:Stepper(L("Arrow size"), db, "arrowSize", 32, 128, 8, function() LayoutArrow() end)
    form:Header(L("Colors"))
    form:Color(L("Alert border"), db.colors, "border", function() M:Refresh() end)
end
