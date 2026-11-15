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
    ["TEACHES"] = "LEHRT",
    ["FOOD"] = "FUTTER",
    ["FAMILY LEARNS"] = "FAMILIE LERNT",
    ["Rank %d"] = "Rang %d",
    ["Pet health compared with the base value."] = "Leben des Begleiters im Vergleich zum Basiswert.",
    ["Pet armor compared with the base value."] = "Ruestung des Begleiters im Vergleich zum Basiswert.",
    ["Pet damage compared with the base value."] = "Schaden des Begleiters im Vergleich zum Basiswert.",
    ["Attack speed"] = "Angriffstempo",
    ["Seconds between two attacks."] = "Sekunden zwischen zwei Angriffen.",
    ["Food type your pet eats."] = "Nahrung, die dein Begleiter frisst.",
    ["You can learn a higher rank"] = "Du kannst einen hoeheren Rang lernen",
    ["Show a 3D model of the beast"] = "3D-Modell des Tiers zeigen",
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
        sound = true, duration = 20, repeatMinutes = 10, inInstances = false, showModel = false,
        arrow = true, arrowAuto = false, arrowSize = 64,
        colors = { border = { 0.75, 0.55, 1 } },
    },
})

local PW = {}
HHT.PetWatch = PW

local W, H = 440, 150
local BODY, FOOT = 90, 52
local MODEL_W = 150
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
local StyleButton = UI.StyleButton

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
    f.border = UI.Panel(f, 0.75, 0.55, 1)
    UI.PopupHead(f, W, { icon = true, onClose = CloseAlert })
    HHT.Icon.Attach(f.icon)
    -- Body columns: the rows are created on demand in Body().
    f.cells, f.arows, f.foods, f.heads, f.hits, f.cards = {}, {}, {}, {}, {}, {}
    f.cardLayer = CreateFrame("Frame", nil, f)
    f.cardLayer:SetAllPoints(f)
    f.body = CreateFrame("Frame", nil, f)
    f.body:SetAllPoints(f)
    f.body:SetFrameLevel(f.cardLayer:GetFrameLevel() + 2)

    -- The 3D view is a second card docked to the left edge, outside the popup itself.
    f.modelBg = CreateFrame("Frame", nil, f)
    f.modelEdge = UI.Panel(f.modelBg, 0.75, 0.55, 1)
    f.modelBg:SetWidth(MODEL_W)
    f.modelBg:SetPoint("TOPRIGHT", f, "TOPLEFT", -8, 0)
    f.modelBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", -8, 0)
    f.model = CreateFrame("PlayerModel", nil, f.modelBg)
    f.model:SetPoint("TOPLEFT", f.modelBg, "TOPLEFT", 8, -8)
    f.model:SetPoint("BOTTOMRIGHT", f.modelBg, "BOTTOMRIGHT", -8, 8)
    f.model:EnableMouse(false)
    f.modelBg:Hide()

    f.target = CreateFrame("Button", nil, f, "SecureActionButtonTemplate")
    f.target:SetSize(78, 24)
    f.target:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 14)
    f.target:RegisterForClicks("AnyUp")
    StyleButton(f.target, L("Target"))

    f.map = UI.Button(f, 54, 24, L("Map"), function()
        if f.beast and PM() then PM():ShowBeasts({ f.beast }, true) end
    end)
    f.map:SetPoint("LEFT", f.target, "RIGHT", 8, 0)

    f.arrowBtn = UI.Button(f, 70, 24, L("Arrow"), function()
        local b = f.beast
        if not b then return end
        if M.track == b then PW.Track(nil) else PW.Track(b) end
    end)
    f.arrowBtn:SetPoint("LEFT", f.map, "RIGHT", 8, 0)

    f.wishBtn = UI.Button(f, 96, 24, L("Wishlist"), function()
        local b, pd = f.beast, PD()
        if not b or not pd then return end
        local on = not pd.IsWish(b.id)
        pd.SetWish(b.id, on)
        HHT.Print(string.format(L(on and "%s added to your wishlist." or "%s removed from your wishlist."), b.n))
        UpdateButtons()
    end)
    f.wishBtn:SetPoint("LEFT", f.arrowBtn, "RIGHT", 8, 0)

    f.snooze = UI.Button(f, 40, 24, "zZ", function()
        snoozeUntil = GetTime() + 900
        HHT.Print(L("Beast alerts paused for 15 minutes."))
        CloseAlert()
    end)
    f.snooze:SetPoint("LEFT", f.wishBtn, "RIGHT", 8, 0)

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
    if HHT:IsUnlocked(self) then self:Preview() elseif f.preview then HHT.HideSecure(f); f.preview = nil end
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

local function StatColored(v)
    if not v then return "-" end
    local c = v > 1 and "66e066" or (v < 1 and "f07368" or "ffffff")
    return string.format("|cff%s%d%%|r", c, math.floor(v * 100 + 0.5))
end

local function FamilyEntry(fam)
    for _, e in ipairs(HHT.PetFamilyData or {}) do
        if e.n == fam then return e end
    end
end

local function StatCell(f, i)
    local c = f.cells[i]
    if not c then
        c = { icon = f.body:CreateTexture(nil, "ARTWORK"), val = UI.Text(f.body, "", 15, 1, 1, 1) }
        c.icon:SetSize(20, 20)
        c.icon:SetVertexColor(0.75, 0.77, 0.82)
        f.cells[i] = c
    end
    return c
end

local function AbilityRow(f, i)
    local r = f.arows[i]
    if not r then
        r = { icon = f.body:CreateTexture(nil, "ARTWORK"), name = UI.Text(f.body, "", 12, 0.92, 0.94, 0.97), rank = UI.Text(f.body, "", 11, 0.62, 0.64, 0.68) }
        r.icon:SetSize(20, 20)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        f.arows[i] = r
    end
    return r
end

local function FoodRow(f, i)
    local r = f.foods[i]
    if not r then
        r = { icon = f.body:CreateTexture(nil, "ARTWORK"), name = UI.Text(f.body, "", 12, 0.9, 0.9, 0.92) }
        r.icon:SetSize(20, 20)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        f.foods[i] = r
    end
    return r
end

-- Invisible hover area with a tooltip.
local function Hit(f, i)
    local h = f.hits[i]
    if not h then
        h = CreateFrame("Frame", nil, f.body)
        h:EnableMouse(true)
        h:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            -- Falls back to plain text if the client returns nothing for the spell.
            for _, id in ipairs(self.spellIds or {}) do
                GameTooltip:ClearLines()
                local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, id)
                local line = _G.GameTooltipTextLeft1
                local txt = line and line:GetText()
                if ok and GameTooltip:NumLines() > 0 and txt and txt ~= "" then
                    if self.tipText then GameTooltip:AddLine(self.tipText, 0.4, 0.93, 0.4, true) end
                    GameTooltip:Show()
                    return
                end
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.tipTitle, 1, 1, 1)
            if self.tipText then GameTooltip:AddLine(self.tipText, 0.8, 0.8, 0.82, true) end
            GameTooltip:Show()
        end)
        h:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f.hits[i] = h
    end
    return h
end

-- One representative item per food type; its icon stands for the type.
local DIET_ITEM = { Meat = 117, Fish = 787, Bread = 4540, Cheese = 414, Fungus = 4604, Fruit = 4536 }
local function DietIcon(d)
    local id = DIET_ITEM[d]
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if id and fn then
        local ok, _, _, _, _, icon = pcall(fn, id)
        if ok and icon then return icon end
    end
    return UI.ICON_DIR .. "utensils"
end

local function Head(f, i)
    local h = f.heads[i]
    if not h then
        h = UI.Text(f.body, "", 10, 0.62, 0.64, 0.68)
        f.heads[i] = h
    end
    return h
end

-- Soft rounded panel behind one column; it sits on its own layer below the body content.
local function Card(f, i)
    local c = f.cards[i]
    if not c then
        c = CreateFrame("Frame", nil, f.cardLayer)
        local p = UI.PAL.inset
        UI.Round(c, 9, p[1], p[2], p[3], 0.7, "BACKGROUND")
        UI.RoundBorder(c, 9, 1, 1, 1, 0.07, "BORDER")
        f.cards[i] = c
    end
    return c
end

local ROW_H, HEAD_H, COL_GAP, COL_ROWS = 22, 16, 8, 4
local CARD_PAD, CARD_TOP, CARD_BOTTOM = 14, 12, 10

-- Pool entries are either a region or a table of regions (icon, val, name, rank); hides them all before a new fill.
local function HideAll(pool)
    for _, o in ipairs(pool) do
        if o.Hide then
            o:Hide()
        else
            for _, k in ipairs({ "icon", "val", "name", "rank" }) do
                if o[k] then o[k]:Hide() end
            end
        end
    end
end

-- Columns side by side: stats (icon + number), food, what the beast teaches, what the family learns.
-- Returns the width the content needs and place(w), which lays the columns out and returns the next free y.
local function Body(f, b)
    local pd, fe = PD(), FamilyEntry(b.f)
    HideAll(f.cells); HideAll(f.arows); HideAll(f.foods); HideAll(f.heads); HideAll(f.hits)
    local cols = {}

    local defs = {}
    if fe and fe.h then
        defs[1] = { "heart", StatColored(fe.h), L("Health"), L("Pet health compared with the base value.") }
        defs[2] = { "shield", StatColored(fe.a), L("Armor"), L("Pet armor compared with the base value.") }
        defs[3] = { "sword", StatColored(fe.d), L("Damage"), L("Pet damage compared with the base value.") }
    end
    if pd.module.db.showSpeed and pd.Speed(b.id) then
        defs[#defs + 1] = { "timer", pd.SpeedText(b.id), L("Attack speed"), L("Seconds between two attacks.") }
    end
    if #defs > 0 or fe then
        local w = 0
        for i, def in ipairs(defs) do
            local c = StatCell(f, i)
            c.icon:SetTexture(UI.ICON_DIR .. def[1])
            c.val:SetText(def[2])
            w = math.max(w, 26 + math.ceil(c.val:GetStringWidth()))
        end
        cols[#cols + 1] = {
            head = fe and L(fe.role) or "", headColor = { 1, 0.82, 0.3 }, w = w, n = #defs,
            put = function(x, y, At, Tip)
                for i = 1, #defs do
                    local c = f.cells[i]
                    At(c.icon, x, y + (i - 1) * ROW_H + 2)
                    c.val:ClearAllPoints()
                    c.val:SetPoint("LEFT", c.icon, "RIGHT", 6, 0)
                    c.val:Show()
                    Tip(x, y + (i - 1) * ROW_H, w, defs[i][3], defs[i][4])
                end
            end,
        }
    end

    local diet = {}
    if fe and fe.diet then
        for _, d in ipairs(fe.diet) do diet[#diet + 1] = d end
    elseif b.d then
        for d in string.gmatch(b.d, "[^,]+") do diet[#diet + 1] = (string.gsub(d, "^%s+", "")) end
    end
    local fi = 0
    for first = 1, #diet, COL_ROWS do
        local last = math.min(#diet, first + COL_ROWS - 1)
        local w, base = 0, fi
        for i = first, last do
            fi = fi + 1
            local r = FoodRow(f, fi)
            r.icon:SetTexture(DietIcon(diet[i]))
            r.name:SetText(L(diet[i]))
            w = math.max(w, 26 + math.ceil(r.name:GetStringWidth()))
        end
        cols[#cols + 1] = {
            head = first == 1 and L("FOOD") or "", w = w, n = last - first + 1,
            put = function(x, y, At, Tip)
                for i = 1, last - first + 1 do
                    local r = f.foods[base + i]
                    At(r.icon, x, y + (i - 1) * ROW_H + 2)
                    r.name:ClearAllPoints()
                    r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
                    r.name:Show()
                    Tip(x, y + (i - 1) * ROW_H, w, L(diet[first + i - 1]), L("Food type your pet eats."))
                end
            end,
        }
    end

    -- Abilities: the beast teaches (green = a higher rank than you know that one of your pets can learn), then the family.
    local fams = pd.MyFamilies(true)
    local teach, learn = {}, {}
    for _, e in ipairs(pd.BeastAbilities(b)) do
        local new = e.rank > 0 and e.rank > pd.KnownRank(e.a.key) and pd.Applies(e.a, fams)
        teach[#teach + 1] = { a = e.a, rank = e.rank, new = new }
    end
    for _, a in ipairs(pd.FamilyAbilities(b.f)) do
        if not a.all then learn[#learn + 1] = { a = a, rank = 0 } end
    end
    local ai = 0
    local function AbilityCols(list, title)
        for first = 1, #list, COL_ROWS do
            local last = math.min(#list, first + COL_ROWS - 1)
            local w, base = 0, ai
            for i = first, last do
                ai = ai + 1
                local it, r = list[i], AbilityRow(f, ai)
                r.icon:SetTexture(pd.AbilityIcon(it.a))
                r.name:SetText(pd.AbilityName(it.a))
                r.hasRank = it.rank > 0
                if it.new then r.name:SetTextColor(0.4, 0.93, 0.4) else r.name:SetTextColor(0.92, 0.94, 0.97) end
                local rw = 28 + math.ceil(r.name:GetStringWidth())
                if r.hasRank then
                    r.rank:SetText(string.format(L("Rank %d"), it.rank))
                    if it.new then r.rank:SetTextColor(0.4, 0.93, 0.4) else r.rank:SetTextColor(0.62, 0.64, 0.68) end
                    rw = rw + 8 + math.ceil(r.rank:GetStringWidth())
                end
                w = math.max(w, rw)
            end
            cols[#cols + 1] = {
                head = first == 1 and title or "", w = w, n = last - first + 1,
                put = function(x, y, At, Tip)
                    for i = 1, last - first + 1 do
                        local r = f.arows[base + i]
                        local it = list[first + i - 1]
                        local ids = it.a.ranks[1] and { it.a.ranks[1].spell } or {}
                        Tip(x, y + (i - 1) * ROW_H, w, pd.AbilityName(it.a), it.new and L("You can learn a higher rank") or nil, ids)
                        At(r.icon, x, y + (i - 1) * ROW_H + 2)
                        r.name:ClearAllPoints()
                        r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
                        r.name:Show()
                        if r.hasRank then
                            r.rank:ClearAllPoints()
                            r.rank:SetPoint("LEFT", r.name, "RIGHT", 8, 0)
                            r.rank:Show()
                        end
                    end
                end,
            }
        end
    end
    AbilityCols(teach, L("TEACHES"))
    AbilityCols(learn, L("FAMILY LEARNS"))

    local need, sum = -COL_GAP, 0
    for _, col in ipairs(cols) do
        col.cw = col.w + 2 * CARD_PAD
        need = need + col.cw + COL_GAP
        sum = sum + col.cw
    end

    for i = #cols + 1, #f.cards do f.cards[i]:Hide() end

    return need, function(w)
        local function At(obj, ox, oy)
            obj:ClearAllPoints()
            obj:SetPoint("TOPLEFT", f, "TOPLEFT", ox, -oy)
            obj:Show()
        end
        local hits = 0
        local function Tip(x, y, tw, title, text, spellIds)
            hits = hits + 1
            local h = Hit(f, hits)
            h.tipTitle, h.tipText, h.spellIds = title, text, spellIds
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", f, "TOPLEFT", x - 4, -y)
            h:SetSize(tw + 8, ROW_H)
            h:Show()
        end
        local rows = 0
        for _, col in ipairs(cols) do rows = math.max(rows, col.n) end
        local top = BODY - 4
        local cardH = CARD_TOP + HEAD_H + rows * ROW_H + CARD_BOTTOM
        -- Every column gets an equal share of the spare width.
        local extra = math.max(0, (w - 32 - (#cols - 1) * COL_GAP - sum) / #cols)
        local x = 16
        for i, col in ipairs(cols) do
            local cw = col.cw + extra
            local card = Card(f, i)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", f, "TOPLEFT", x, -top)
            card:SetSize(math.floor(cw), cardH)
            card:Show()
            if col.head ~= "" then
                local h = Head(f, i)
                h:SetText(col.head)
                local hc = col.headColor or { 0.62, 0.64, 0.68 }
                h:SetTextColor(hc[1], hc[2], hc[3])
                At(h, x + CARD_PAD, top + CARD_TOP)
            end
            col.put(x + CARD_PAD, top + CARD_TOP + HEAD_H, At, Tip)
            x = x + math.floor(cw) + COL_GAP
        end
        return top + cardH + 4
    end
end

-- The client loads an unseen creature late, so the model is set again until it reports a file.
local function LoadModel(f, b)
    local m = f.model
    f.modelKey = b.id
    local tries = 0
    local function Load()
        pcall(m.ClearModel, m)
        local ok = pcall(m.SetCreature, m, b.id)
        pcall(m.SetFacing, m, 0)
        local okF, file = pcall(m.GetModelFileID, m)
        if ok and okF and not file and tries < 12 and C_Timer and C_Timer.After then
            tries = tries + 1
            C_Timer.After(0.4, function() if f.modelKey == b.id and f:IsShown() then Load() end end)
        end
    end
    Load()
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
    UI.SetPrimary(f.target, c[1], c[2], c[3])
    f.eyebrow:SetText(L(eyebrow))
    f.eyebrow:SetTextColor(c[1], c[2], c[3])
    f.icon:SetTexture(pd.FamilyIcon(b.f))
    f.title:SetText(data.name or b.n)
    f.sub:SetText(L(b.f) .. ", " .. L("Level") .. " " .. b.l .. " - " .. pd.ZoneName(b))
    local withModel = db.showModel and true or false
    f.modelEdge:SetColor(c[1], c[2], c[3], 0.9)
    local bodyNeed, place = Body(f, b)
    -- The width follows the widest row (or the buttons); the diet line wraps at the maximum.
    local need = math.max(bodyNeed, 78 + 8 + 54 + 8 + 70 + 8 + 96 + 8 + 40)
    local w = W
    if not InCombatLockdown() then w = UI.PopupFit(f, need, 400, 600) else w = f:GetWidth() end
    local y = place(w)
    f.modelBg:SetShown(withModel)
    f.model:SetShown(withModel)
    if withModel then
        LoadModel(f, b)
    else
        f.modelKey = nil
    end
    if not InCombatLockdown() then f:SetHeight(math.max(H, y + FOOT - 4)) end
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
    for _, x in ipairs(pd.beasts) do
        if x.n == "Humar the Pridelord" then b = x; break end
        if x.r and not b then b = x end
    end
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
    if HHT:IsUnlocked(M) then return false end
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
        if not HHT:IsUnlocked(self) then a:Hide() end
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
    form:Check(L("Show a 3D model of the beast"), db, "showModel")
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
