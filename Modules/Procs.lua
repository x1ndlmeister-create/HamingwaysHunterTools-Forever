-- Proc overlay: big art around the character, drawn by the client's aura container so it also works in combat.
local ADDON, HHT = ...
local L, S, UI = HHT.L, HHT.Spells, HHT.UI

HHT:AddGerman({
    ["Proc Overlay"] = "Proc-Anzeige",
    ["Big art around your character while a proc or buff is active, also in combat."] = "Grosse Grafik um deinen Charakter, solange ein Proc oder Buff aktiv ist, auch im Kampf.",
    ["Art size"] = "Groesse der Grafik",
    ["Play a sound when it appears"] = "Ton abspielen, wenn sie erscheint",
    ["Tracked procs"] = "Ueberwachte Procs",
    ["Aura spell ID (the buff, not the talent)"] = "Aura-Zauber-ID (der Buff, nicht das Talent)",
    ["Add"] = "Hinzufuegen",
    ["Spell ID"] = "Zauber-ID",
    ["Browse graphics"] = "Grafiken ansehen",
    ["Proc graphics"] = "Proc-Grafiken",
    ["Choose graphic"] = "Grafik waehlen",
    ["Page"] = "Seite",
    ["Show remaining time as fading art"] = "Restzeit als verblassende Grafik zeigen",
    ["Reverse the fading (art fills up instead of draining)"] = "Verblassen umkehren (Grafik fuellt sich statt zu leeren)",
    ["Preview"] = "Vorschau",
    ["Fades from"] = "Verblasst von",
    ["Top"] = "Oben",
    ["Bottom"] = "Unten",
    ["Left"] = "Links",
    ["Right"] = "Rechts",
    ["Offset X"] = "Versatz X",
    ["Offset Y"] = "Versatz Y",
    ["Scan for new procs"] = "Nach neuen Procs suchen",
    ["While on, short buffs you gain out of combat are added to the list switched off. Switch the ones you want on."] =
        "Solange aktiv, werden kurze Buffs, die du ausserhalb des Kampfes bekommst, ausgeschaltet zur Liste hinzugefuegt. Schalte die gewuenschten ein.",
    ["On"] = "An",
    ["Off"] = "Aus",
    ["New proc detected: %s (id %d), switched off in the list."] = "Neuer Proc erkannt: %s (ID %d), in der Liste ausgeschaltet.",
    ["Use /hht auras while the proc is active to read its ID. The game draws the art itself, so nothing can be hidden or checked by the addon in combat."] =
        "Mit /hht auras waehrend der Proc aktiv ist liest du seine ID aus. Das Spiel zeichnet die Grafik selbst, das Addon kann im Kampf nichts pruefen oder verstecken.",
})

local floor = math.floor

local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
-- { label, path, kind }: S square, W wide (half as tall as it is wide)
local ARTS = {
    { "Soft glow", MEDIA .. "Proc_Glow", "S" },
    { "Ring", MEDIA .. "Proc_Ring", "S" },
    { "Edges", MEDIA .. "Proc_Edges", "S" },
    { "Burst", MEDIA .. "Proc_Burst", "S" },
    { "Arc", MEDIA .. "Proc_Arc", "S" },
    { "Star", "Interface\\Cooldown\\star4", "S" },
    { "Square", "Interface\\Buttons\\UI-ActionButton-Border", "S" },
}

local PROC_FILES = "ArcaneRunes:W ArcaneSealStage1:T ArcaneSealStage2:T ArcaneSealStage3:T Arcane_Missiles:T ArrowStage1:T ArrowStage2:T ArrowStage3:T ArrowVolleyArc:W Art_of_War:T AutumnVines:T Backlash:W Berserk:W BlazingStormArc:W BloodOrbs:T Blood_Boil:T Blood_Surge:T BlueLightningStreak:T Brain_Freeze:T BrightGoldBlade:T CrescentMoon:S CrescentMoonGlow:T CrimsonClaws:T CrimsonStreakArc:T DarkRedStreaks:T Dark_Transformation:W Daybreak:T DemonEmberBand:W DemonFireArc:W Denounce:W DivineRays:W ElementalArc:T EmberArc:T EmberCrown:W FelCrescent:T FelFlame:T FelFlameStreaks:T FelOoze:T FelStormArc:W Feral_OmenOfClarity:T FireBand:W FireBurst:W FireSwoosh:W FlameStreaks:T FlamingDagger:T Focus_Fire:T FrostBand:W FrostFireArc:T FrostShards:T Frozen_Fingers:W Fulmintaion:W Fury_of_Stormrage:W GenericArc_01:T GenericArc_02:T GenericArc_03:T GenericArc_04:T GenericArc_05:T GenericArc_06:T GenericTop_01:W GenericTop_02:W GlowingEyes:W GoldenArrows:T GoldenBubbleStream:T GoldenCrosshair:W GoldenFlameCrescent:T GoldenLightningArc:T GoldenLightningStreak:T GoldenRunes:W GoldenShield:T GoldenSunArc:T GoldenSword:T GoldenWingedEmblem:W Grand_Crusader:T GreenFelBand:W GreenGlowArch:W GreenMist:T GreenVines:T Hand_of_Light:W HolyFlameArc:W Hot_Streak:T IceWallArc:T IcyBlueArc:T Impact:W Imp_Empowerment:T JadeMist:T JadeSwirlCrescent:T Killing_Machine:T LightningStage1:W LightningStage2:W LightningStage3:W LightningStage4:W LightningWings:W Lock_and_Load:W Maelstrom_Weapon:W maelstrom_weapon_1:W maelstrom_weapon_2:W maelstrom_weapon_3:W maelstrom_weapon_4:W Master_Marksman:W Molten_Core:T Natures_Grace:T Necropolis:W Nightfall:T OLDEclipse_Moon:S OLDEclipse_Sun:S OrangeStreakArc:T PaleGoldBlade:T PinkRuneArc:T PurpleComet:W PurpleFlameBand:W PurpleThornBand:W RadiantFeathers:W RedBoltSlash:W RedFlameCrescent:T RedShield:T RedSlash:W Rime:W RunePlate:W Serendipity:W ShadowNova:W ShadowStar:T ShadowWisps:T Shooting_Stars:W SilverEmblem:S SilverWispArc:T Slice_and_Dice:W SmallRedSlash:T StarfallCrescent:T StormArc:W StormStones:W StormVortexArc:W Sudden_Death:T sudden_death_red:T Sudden_Doom:T SunOrb:S Surge_of_Light:T Sword_and_Board:T TidalArc:W VenomDrip:T VioletSwirls:T VoidCrescent:T WhiteArch:W WhiteArcSoft:T WhiteCrescent:T WhiteDoubleArch:W WhiteDoubleCrescent:T WhiteFlareArc:T WhiteRuneArc:T WhiteSparkArc:T WhiteStarburst:W"
for name, kind in PROC_FILES:gmatch("([%w_]+):(%u)") do
    local label = (name:gsub("_", " "):gsub("(%l)(%u)", "%1 %2"))
    -- the former half-width files were merged into full-width (mirrored) textures
    ARTS[#ARTS + 1] = { label, MEDIA .. "Procs\\" .. name, kind == "W" and "W" or "S" }
end

local function LayoutArt(t1, parent, a, size, x, y)
    t1:ClearAllPoints()
    t1:SetTexture(a[2])
    t1:SetSize(size, a[3] == "W" and size / 2 or size)
    t1:SetPoint("CENTER", parent, "CENTER", x or 0, y or 0)
    t1:SetTexCoord(0, 1, 0, 1)
end

local MAXP = 12

local function ArtIndex(path)
    for i, a in ipairs(ARTS) do
        if a[2] == path then return i end
    end
    return 1
end

local M = HHT:NewModule("procs", {
    name = "Proc Overlay",
    desc = "Big art around your character while a proc or buff is active, also in combat.",
    positions = { main = { "CENTER", "CENTER", 0, 0 } },
    defaults = {
        size = 200, sound = true, drain = true, rising = false, scan = false,
        entries = { { ids = { 6150 }, art = ArtIndex(MEDIA .. "Procs\\ArrowStage1") } }, -- Quick Shots
    },
})
HHT.Procs = M

local function IdSet(ids)
    local set = {}
    for _, id in ipairs(ids) do set[id] = true end
    return set
end

local function ArtOf(e)
    return ARTS[e and e.art or 1] or ARTS[1]
end

function M:OnInit()
    self.arts = {}
    self.shows = 0
    self.lastSound = 0
    self.watch = false
    HHT:Listen(self, "PLAYER_REGEN_ENABLED", function(m)
        if m.watch then C_Timer.After(0.3, function() m:ListAuras(true) end) end
        m:QueueScan()
    end)
    HHT:Listen(self, "UNIT_AURA", function(m, _, unit)
        if unit == "player" then m:QueueScan() end
    end)
end

function M:QueueScan()
    if not (self.db and self.db.scan) or self.scanPending then return end
    self.scanPending = true
    C_Timer.After(0.5, function()
        self.scanPending = false
        if self.enabled then self:ScanNew() end
    end)
end

-- Unknown short buffs of the player are added switched off; only readable out of combat.
function M:ScanNew()
    local db = self.db
    if not db.scan or HHT.InCombat() or S.AurasSecret() then return end
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
    db.seen = db.seen or {}
    for _, e in ipairs(db.entries) do
        for _, id in ipairs(e.ids) do db.seen[id] = true end
    end
    local added
    for i = 1, 40 do
        local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL|PLAYER")
        if not ok or not a then break end
        pcall(function()
            local id, dur = a.spellId, a.duration
            if type(id) == "number" and type(dur) == "number" and dur > 0 and dur <= 30
                and not db.seen[id] and #db.entries < MAXP then
                db.seen[id] = true
                db.entries[#db.entries + 1] = { ids = { id }, art = 1, off = true, name = a.name }
                added = true
                HHT.Print(string.format(L("New proc detected: %s (id %d), switched off in the list."), tostring(a.name), id))
            end
        end)
    end
    if added then
        self:Layout()
        if self.procList then pcall(self.procList.Refresh) end
    end
end

-- Runs once per engine-made button; the art only exists while the aura does.
function M:InitArt(button, key)
    local idx = tonumber(key:match("%d+$"))
    button:EnableMouse(false)
    button:SetSize(self.db.size, self.db.size)
    local holder = CreateFrame("Frame", nil, button)
    holder:SetAllPoints(button)
    local art = holder:CreateTexture(nil, "ARTWORK")
    art:SetBlendMode("ADD")
    -- the client fills this bar with the remaining time of the aura, also in combat
    local bar = CreateFrame("StatusBar", nil, holder)
    bar:SetOrientation("VERTICAL")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetFrameLevel(holder:GetFrameLevel() + 1)
    local ok, err = pcall(button.SetDurationBar, button, bar)
    if not ok then M.barErr = tostring(err) end
    local ico = button:CreateTexture(nil, "OVERLAY")
    ico:SetSize(1, 1)
    ico:SetPoint("CENTER")
    ico:SetAlpha(0)
    button:SetIcon(ico)

    local function Pulse(frame)
        local ag = frame:CreateAnimationGroup()
        pcall(function()
            ag:SetLooping("BOUNCE")
            local a = ag:CreateAnimation("Alpha")
            a:SetDuration(0.6)
            if a.SetFromAlpha then a:SetFromAlpha(1); a:SetToAlpha(0.55) else a:SetChange(-0.45) end
        end)
        return ag
    end
    local ag = Pulse(holder)
    pcall(button.SetScript, button, "OnShow", function()
        M.shows = M.shows + 1
        pcall(ag.Play, ag)
        if M.db.sound and GetTime() - M.lastSound > 1 then
            M.lastSound = GetTime()
            pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959)
        end
    end)

    self.arts[idx] = self.arts[idx] or {}
    local r = { art = art, bar = bar, button = button, idx = idx }
    self:SetDirection(r)
    table.insert(self.arts[idx], r)
    self:StyleArt(r, ArtOf(self.db.entries[idx]))
end

-- The bright part is what is left of the aura, the rest stays dim. rising: fills up with elapsed time instead.
function M:SetDirection(r)
    local want = self.db.rising and 0 or 1
    if r.dir == want then return end
    local E = Enum and Enum.StatusBarTimerDirection
    local dir = E and ((want == 1) and E.RemainingTime or E.ElapsedTime) or want
    local ok, err = pcall(r.button.SetDurationBar, r.button, r.bar, { direction = dir })
    if ok then r.dir = want else M.barErr = tostring(err) end
end

function M:StyleArt(r, a)
    local db = self.db
    local e = db.entries[r.idx] or {}
    local size, x, y = db.size * (e.scale or 1), e.x or 0, e.y or 0
    local h = a[3] == "W" and size / 2 or size
    LayoutArt(r.art, r.button, a, size, x, y)
    r.button:SetSize(db.size, db.size)
    local bar = r.bar
    bar:ClearAllPoints()
    bar:SetPoint("CENTER", r.button, "CENTER", x, y)
    bar:SetSize(size, h)
    bar:SetStatusBarTexture(a[2])
    local tex = bar:GetStatusBarTexture()
    if tex then tex:SetBlendMode("ADD") end
    bar:SetStatusBarColor(1, 1, 1, 1)
    local from = e.from or "top"
    bar:SetOrientation((from == "top" or from == "bottom") and "VERTICAL" or "HORIZONTAL")
    bar:SetReverseFill(from == "bottom" or from == "left")
    self:SetDirection(r)
    if db.drain then
        r.art:SetAlpha(0.3)
        bar:Show()
    else
        r.art:SetAlpha(1)
        bar:Hide()
    end
end

function M:ApplyArts()
    for idx, list in pairs(self.arts) do
        local a = ArtOf(self.db.entries[idx])
        for _, r in ipairs(list) do
            if not r.button.CanBeAccessedInContext or r.button:CanBeAccessedInContext() then
                self:StyleArt(r, a)
            end
        end
    end
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsProcs", UIParent)
    f:SetSize(200, 200)
    self.frame = f
    self.pvs = {}
    for i = 1, MAXP do
        local t = f:CreateTexture(nil, "BACKGROUND")
        t:SetBlendMode("ADD")
        t:Hide()
        self.pvs[i] = t
    end
    HHT:MakeMovable(f, self, "main", L("Proc Overlay"))
    self.bar = HHT.AuraBar.New(f, function() return { size = self.db.size, spacing = 0 } end)
    self.bar.initFn = function(_, button, key) M:InitArt(button, key) end
end

function M:Layout()
    local f, db, bar = self.frame, self.db, self.bar
    if not f then return end
    f:SetSize(db.size, db.size)
    for i = 1, MAXP do
        local e = db.entries[i]
        if e and not e.off and bar.engine then
            bar:Setup("hht_proc" .. i, "player", "HELPFUL|PLAYER", { includeSpellIDs = IdSet(e.ids) }, 1, "right", 0, 0)
        else
            bar:Hide("hht_proc" .. i)
        end
    end
    self:ApplyArts()
    local unlocked = HHT:IsUnlocked()
    for i = 1, MAXP do
        local e, t = db.entries[i], self.pvs[i]
        if (e and not e.off and (e.preview or unlocked)) or (i == 1 and unlocked) then
            LayoutArt(t, f, ArtOf(e), db.size * ((e and e.scale) or 1), e and e.x, e and e.y)
            t:SetAlpha(e and e.preview and 0.9 or 0.5)
            t:Show()
        else
            t:Hide()
        end
    end
    HHT:ApplyGlobalLook(f)
end

function M:OnEnable()
    self:Build()
    self.frame:Show()
    self:Layout()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
end

function M:Refresh()
    self:Layout()
    self:QueueScan()
end
function M:OnLockChanged() self:Layout() end

-- ---------------------------------------------------------------------------
-- Diagnostics: /hht procs, /hht auras, /hht proctex
-- ---------------------------------------------------------------------------
function M:Debug()
    local bar = self.bar
    if not bar then HHT.Print("procs: not enabled"); return end
    HHT.Print(string.format("procs: engine=%s combat=%s entries=%d onshow=%d", tostring(bar.engine), tostring(HHT.InCombat()), #self.db.entries, self.shows))
    for i = 1, MAXP do
        local e = self.db.entries[i]
        if e then
            HHT.Print(string.format("proc %d: ids=%s container=%s group=%s buttons=%d", i, table.concat(e.ids, ","), tostring(bar.conts["hht_proc" .. i] ~= nil), tostring(bar.groups["hht_proc" .. i]), self.arts[i] and #self.arts[i] or 0))
            local c = bar.conts["hht_proc" .. i]
            if c then
                local ok, info = pcall(function()
                    local x, y = c:GetCenter()
                    return string.format("container shown=%s visible=%s size=%.0fx%.0f center=%.0f,%.0f alpha=%.2f", tostring(c:IsShown()), tostring(c:IsVisible()), c:GetWidth(), c:GetHeight(), x or -1, y or -1, c:GetEffectiveAlpha())
                end)
                HHT.Print(ok and info or ("container info failed: " .. tostring(info)))
            end
            local shown, hidden, secret, w = 0, 0, 0, 0
            for _, r in ipairs(self.arts[i] or {}) do
                local vis = HHT.SafeBool(r.button.IsShown, r.button)
                if vis == true then shown = shown + 1 elseif vis == false then hidden = hidden + 1 else secret = secret + 1 end
                w = HHT.SafeNumber(r.button:GetWidth()) or w
            end
            HHT.Print(string.format("  buttons shown=%d hidden=%d unreadable=%d, width=%.0f", shown, hidden, secret, w))
        end
    end
    local any
    for label, err in pairs(bar.errors) do
        any = true
        HHT.Print("error " .. label .. ": " .. err)
    end
    if not any then HHT.Print("no errors recorded") end
    HHT.Print("duration bar: " .. (self.barErr and ("SetDurationBar failed: " .. self.barErr) or "attached"))
end

-- shortOnly: only buffs with a duration of 30s or less (procs), used by the auto capture after combat.
function M:ListAuras(shortOnly)
    if HHT.InCombat() or S.AurasSecret() then
        HHT.Print("Auras are unreadable now. Use this out of combat while the buff is active.")
        return
    end
    local n = 0
    for i = 1, 40 do
        local name, id, dur, exp
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or not a then break end
            name, id, dur, exp = a.name, a.spellId, a.duration, a.expirationTime
        else
            local nm, _, _, _, d, e, _, _, _, sid = UnitBuff("player", i)
            if not nm then break end
            name, id, dur, exp = nm, sid, d, e
        end
        if not shortOnly or (type(dur) == "number" and dur > 0 and dur <= 30) then
            n = n + 1
            local left = (type(exp) == "number" and exp > 0) and string.format("%.0fs left", exp - GetTime()) or "no timer"
            HHT.Print(string.format("%s  id=%s  (%s)", tostring(name), tostring(id), left))
        end
    end
    if n == 0 then HHT.Print(shortOnly and "No short buffs after combat." or "No buffs found.") end
end

local COLS, PER = 6, 24

-- onPick(index) is optional; without it the window is just a gallery.
function M:OpenPicker(current, onPick)
    local w = self.picker
    if not w then
        w = UI.Window("HamingwaysHunterToolsProcPicker", 668, 540, "")
        w:SetPoint("CENTER")
        w:SetFrameStrata("FULLSCREEN_DIALOG")
        w:SetToplevel(true)
        if UISpecialFrames then table.insert(UISpecialFrames, "HamingwaysHunterToolsProcPicker") end
        w.cells = {}
        for i = 1, PER do
            local c = CreateFrame("Button", nil, w)
            c:SetSize(104, 108)
            c:SetPoint("TOPLEFT", w, "TOPLEFT", 10 + ((i - 1) % COLS) * 108, -38 - floor((i - 1) / COLS) * 112)
            local bg = c:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0, 0, 0, 0.7)
            c.border = UI.Border(c, 1, 1, 1, 0.08)
            local hl = c:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.2)
            c.box = CreateFrame("Frame", nil, c)
            c.box:SetSize(84, 84)
            c.box:SetPoint("TOP", c, "TOP", 0, -4)
            c.t1 = c.box:CreateTexture(nil, "ARTWORK")
            c.t1:SetBlendMode("ADD")
            c.name = UI.Text(c, "", 10)
            c.name:SetPoint("BOTTOM", c, "BOTTOM", 0, 5)
            c.name:SetWidth(100)
            c.name:SetWordWrap(false)
            c:SetScript("OnClick", function(self)
                if self.idx and w.onPick then
                    w.onPick(self.idx)
                    w:Hide()
                end
            end)
            w.cells[i] = c
        end
        local pages = math.ceil(#ARTS / PER)
        function w:Refresh()
            for i, c in ipairs(self.cells) do
                local idx = (self.page - 1) * PER + i
                local a = ARTS[idx]
                c.idx = a and idx or nil
                if a then
                    LayoutArt(c.t1, c.box, a, 84)
                    c.name:SetText(a[1])
                    if idx == self.current then c.border:SetColor(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 1) else c.border:SetColor(1, 1, 1, 0.08) end
                    c:Show()
                else
                    c:Hide()
                end
            end
            self.pageText:SetText(L("Page") .. " " .. self.page .. " / " .. pages)
            self.prev:SetShown(self.page > 1)
            self.next:SetShown(self.page < pages)
        end
        function w:Turn(d)
            self.page = math.max(1, math.min(pages, self.page + d))
            self:Refresh()
        end
        w.prev = UI.Button(w, 70, 22, "<", function() w:Turn(-1) end)
        w.prev:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 10, 10)
        w.next = UI.Button(w, 70, 22, ">", function() w:Turn(1) end)
        w.next:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -10, 10)
        w.pageText = UI.Text(w, "", 12)
        w.pageText:SetPoint("BOTTOM", w, "BOTTOM", 0, 14)
        w:EnableMouseWheel(true)
        w:SetScript("OnMouseWheel", function(self, delta) self:Turn(-delta) end)
        self.picker = w
    end
    w.onPick = onPick
    w.current = current
    w.page = current and floor((current - 1) / PER) + 1 or 1
    w.title:SetText(onPick and L("Choose graphic") or L("Proc graphics"))
    w:Refresh()
    w:Show()
    w:Raise()
end

function M:TexPreview() self:OpenPicker(nil, nil) end

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
local ROW_H = 24

local function EntryName(e)
    for _, id in ipairs(e.ids) do
        local name = S.Name(id)
        if name then return name end
    end
    return e.name or (L("Spell ID") .. " " .. tostring(e.ids[1]))
end

local function BuildProcList(m, form)
    local db = m.db
    local list = CreateFrame("Frame", nil, form.content)
    list:SetSize(380, 10)
    list.rows = {}

    local function Changed() HHT:RefreshModule(m) end
    list.sel = 1

    local function NewRow(i)
        local row = CreateFrame("Frame", nil, list)
        row:SetSize(380, ROW_H)
        row.text = UI.Button(row, 140, 20, "", function()
            list.sel = i
            list:Refresh()
        end)
        row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.art = UI.Button(row, 110, 20, "", function()
            local e = db.entries[i]
            if not e then return end
            M:OpenPicker(e.art or 1, function(idx)
                e.art = idx
                row.art:SetLabel(ARTS[idx][1])
                Changed()
            end)
        end)
        row.art:SetPoint("LEFT", row.text, "RIGHT", 6, 0)
        row.on = UI.Button(row, 40, 20, "", function()
            local e = db.entries[i]
            if not e then return end
            if e.off then e.off = nil else e.off = true end
            Changed()
            list:Refresh()
        end)
        row.on:SetPoint("LEFT", row.art, "RIGHT", 6, 0)
        row.del = UI.Button(row, 20, 20, "x", function()
            table.remove(db.entries, i)
            Changed()
            list:Refresh()
        end)
        row.del:SetPoint("LEFT", row.on, "RIGHT", 6, 0)
        list.rows[i] = row
        return row
    end

    local addLabel, addBox, addBtn
    local detail = {}

    local function Cur() return db.entries[list.sel] end
    local function Num(key, def, step)
        return function() return (Cur() and Cur()[key]) or def end,
            function(v)
                local e = Cur()
                if e then e[key] = floor(floor(v / step + 0.5) * step * 100 + 0.5) / 100; Changed() end
            end
    end
    detail.preview = UI.Check(list, L("Preview"),
        function() return Cur() and Cur().preview end,
        function(v) if Cur() then Cur().preview = v and true or false; Changed() end end)
    local g, s = Num("scale", 1, 0.05)
    detail.from = UI.Cycle(list, L("Fades from"), {
        { "top", L("Top") }, { "bottom", L("Bottom") }, { "left", L("Left") }, { "right", L("Right") } },
        function() return (Cur() and Cur().from) or "top" end,
        function(v) if Cur() then Cur().from = v; Changed() end end)
    detail.scale = UI.Stepper(list, L("Scale"), g, s, 0.25, 3, 0.05)
    g, s = Num("x", 0, 10)
    detail.x = UI.Stepper(list, L("Offset X"), g, s, -800, 800, 10)
    g, s = Num("y", 0, 10)
    detail.y = UI.Stepper(list, L("Offset Y"), g, s, -800, 800, 10)
    local DETAIL_ORDER = { "preview", "from", "scale", "x", "y" }

    local function Rebuild()
        local n = #db.entries
        if list.sel > n then list.sel = n end
        if list.sel < 1 then list.sel = 1 end
        local A = UI.ACCENT
        for i = 1, n do
            local row = list.rows[i] or NewRow(i)
            local e = db.entries[i]
            row.text:SetLabel(EntryName(e))
            if i == list.sel then row.text.label:SetTextColor(A[1], A[2], A[3])
            elseif e.off then row.text.label:SetTextColor(0.5, 0.52, 0.57)
            else row.text.label:SetTextColor(0.92, 0.94, 0.97) end
            row.on:SetLabel(e.off and L("Off") or L("On"))
            if e.off then row.on.label:SetTextColor(0.5, 0.52, 0.57) else row.on.label:SetTextColor(A[1], A[2], A[3]) end
            row.art:SetLabel(ArtOf(e)[1])
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(i - 1) * ROW_H)
            row:Show()
        end
        for i = n + 1, #list.rows do list.rows[i]:Hide() end
        local y = n * ROW_H + 8
        for _, k in ipairs(DETAIL_ORDER) do
            local w = detail[k]
            w:ClearAllPoints()
            if n > 0 then
                w:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -y)
                w:Show()
                w:Refresh()
                y = y + 26
            else
                w:Hide()
            end
        end
        y = y + 8
        addLabel:ClearAllPoints()
        addLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -y)
        addBox:ClearAllPoints()
        addBox:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(y + 18))
        addBtn:ClearAllPoints()
        addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
        local h = y + 18 + 28
        list:SetHeight(h)
        form:SetTail(h)
    end

    addLabel = UI.Text(list, L("Aura spell ID (the buff, not the talent)"), 11, 0.68, 0.65, 0.58)
    addBox = UI.EditBox(list, 250, nil)
    addBox:SetMaxLetters(60)
    addBtn = UI.Button(list, 110, 20, L("Add"), function()
        if #db.entries >= MAXP then return end
        local ids = {}
        for token in addBox:GetText():gmatch("%d+") do ids[#ids + 1] = tonumber(token) end
        if #ids == 0 then return end
        db.entries[#db.entries + 1] = { ids = ids, art = 1 }
        list.sel = #db.entries
        addBox:SetText("")
        Changed()
        list:Refresh()
    end)

    list.Refresh = Rebuild
    m.procList = list
    form:PlaceTail(list)
    Rebuild()
    return list
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Stepper(L("Art size"), db, "size", 64, 400, 16)
    form:Check(L("Play a sound when it appears"), db, "sound")
    form:Check(L("Show remaining time as fading art"), db, "drain")
    form:Check(L("Reverse the fading (art fills up instead of draining)"), db, "rising")
    form:Button(L("Browse graphics"), function() M:TexPreview() end)
    form:Header(L("Tracked procs"))
    form:Check(L("Scan for new procs"), db, "scan")
    form:Note(L("While on, short buffs you gain out of combat are added to the list switched off. Switch the ones you want on."))
    form:Note(L("Use /hht auras while the proc is active to read its ID. The game draws the art itself, so nothing can be hidden or checked by the addon in combat."))
    BuildProcList(self, form)
end
