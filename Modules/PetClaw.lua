-- Pet Claw: a button that shows when the pet has enough focus for Claw, and a easy mode that adds Claw to your other attacks.
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Pet Claw"] = "Begleiter-Klaue",
    ["A button that shows when your pet has enough focus for Claw, plus a easy mode that adds Claw to your other attacks."] = "Ein Knopf, der zeigt, wann dein Begleiter genug Fokus für Klaue hat, plus ein Easy-Modus, der Klaue an deine anderen Angriffe hängt.",
    ["Claw button"] = "Klauen-Knopf",
    ["Easy mode"] = "Easy-Modus",
    ["Show the Claw button"] = "Klauen-Knopf zeigen",
    ["Hide when focus is low"] = "Bei zu wenig Fokus ausblenden",
    ["Show the global cooldown"] = "Globalen Cooldown zeigen",
    ["Dimmed opacity"] = "Deckkraft abgedunkelt",
    ["Focus needed for Claw"] = "Fokus für Klaue nötig",
    ["Claw key: %s"] = "Klauen-Taste: %s",
    ["Clear Claw key"] = "Klauen-Taste entfernen",
    ["Add Claw to other attacks"] = "Klaue an andere Angriffe hängen",
    ["Replace the keys of these attacks"] = "Tasten dieser Angriffe ersetzen",
    ["Attacks with Claw"] = "Angriffe mit Klaue",
    ["Add attack"] = "Angriff hinzufügen",
    ["Ready border"] = "Rand bereit",
    ["Show a ring with the pet focus"] = "Ring mit dem Fokus des Begleiters zeigen",
    ["Ring width"] = "Ringbreite",
    ["Focus ring color"] = "Farbe Fokus-Ring",
    ["A ring around the button that fills up with the focus of your pet."] = "Ein Ring um den Knopf, der sich mit dem Fokus deines Begleiters füllt.",
    ["Thickness of the focus ring"] = "Dicke des Fokus-Rings",
    ["not set"] = "nicht gesetzt",
    ["Left-click or key: Claw"] = "Linksklick oder Taste: Klaue",
    ["Pet focus: %d"] = "Fokus des Begleiters: %d",
    ["Your pet has no Claw on its pet bar."] = "Dein Begleiter hat keine Klaue auf der Begleiterleiste.",
    ["Changes apply after combat."] = "Änderungen gelten nach dem Kampf.",
    ["The Claw button only works while your pet has Claw on its pet bar. The key replaces its normal function while it is set."] = "Der Klauen-Knopf geht nur, solange dein Begleiter Klaue auf seiner Leiste hat. Die Taste ersetzt ihre normale Funktion, solange sie gesetzt ist.",
    ["Claw has no cooldown, so it eats your pet's focus and delays Growl and other abilities. Pick up to 10 attacks: their keys then also fire Claw, so you do not have to think about it."] = "Klaue hat keine Abklingzeit und frisst den Fokus deines Begleiters, wodurch Knurren und andere Fähigkeiten später kommen. Wähle bis zu 10 Angriffe: ihre Tasten lösen dann auch Klaue aus, du musst nicht daran denken.",
    ["Replaces the keys of the chosen attacks on your action bars with a macro that also uses Claw. Mouse clicks on the bar buttons are not changed. Switch it off to get your own keys back."] = "Ersetzt die Tasten der gewählten Angriffe auf deinen Aktionsleisten durch ein Makro, das auch Klaue nutzt. Mausklicks auf die Leistenknöpfe bleiben unverändert. Ausschalten gibt deine eigenen Tasten zurück.",
    ["The game hides the pet focus from macros, so the focus limit does not apply here: Claw is added to every press of these attacks."] = "Das Spiel verbirgt den Fokus des Begleiters vor Makros. Die Fokus-Grenze gilt hier deshalb nicht: Klaue wird bei jedem Druck dieser Angriffe angehängt.",
})

local MAX_SPELLS = 10
local PROXY = "HamingwaysHunterToolsClawProxy"
local MACRO = "HamingwaysHunterToolsClawMacro"
local CLAW_IDS = { [16827] = true, [16828] = true, [16829] = true, [16830] = true, [16831] = true, [16832] = true, [3010] = true, [3009] = true }
local FALLBACK_ICON = "Interface\\Icons\\Ability_Druid_Rake"

-- The color of the focus bar in the game UI, the default of the focus ring.
local FOCUS_COLOR = { 1, 0.5, 0.25 }
do
    local c = PowerBarColor and PowerBarColor["FOCUS"]
    if type(c) == "table" and c.r then FOCUS_COLOR = { c.r, c.g, c.b } end
end

local M = HHT:NewModule("petclaw", {
    name = "Pet Claw",
    desc = "A button that shows when your pet has enough focus for Claw, plus a easy mode that adds Claw to your other attacks.",
    positions = { main = { "CENTER", "CENTER", 340, -110 } },
    defaults = {
        size = 44, shape = "round", borderSize = 2, borderAlpha = 1,
        showButton = true, showGcd = true, showRing = false, ringWidth = 4, showKeys = true, keySize = 14, keyPos = "TOPRIGHT", hideLow = true, dimAlpha = 0.4, showWhen = "combat", key = "", threshold = 50,
        lazy = false, override = false, spells = {},
        colors = { ready = { 0.67, 0.83, 0.45 }, key = { 1, 1, 0.4 }, ring = { FOCUS_COLOR[1], FOCUS_COLOR[2], FOCUS_COLOR[3] } },
    },
})

-- Hidden without a pet. The driver works in combat too, where the frame cannot be hidden by code.
local DRIVER = "[nopet] hide; show"

-- Runs in the secure environment when a key fires a lazy button: below the focus threshold the macro leaves Claw out.
-- Without the focus API in that environment the snippet changes nothing and Claw is always added.
local SNIPPET = [[
    local th = self:GetAttribute("threshold") or 0
    local text = self:GetAttribute("fullmacro")
    if th > 0 and UnitPower then
        local p = UnitPower("pet")
        if p and p < th then text = self:GetAttribute("plainmacro") end
    end
    self:SetAttribute("macrotext1", text)
]]

local clawNames
local function IsClaw(name, spellId)
    if not clawNames then
        clawNames = { Claw = true }
        local n = S.Name(16827)
        if n then clawNames[n] = true end
    end
    if type(spellId) == "number" and not HHT.IsSecret(spellId) and CLAW_IDS[spellId] then return true end
    return type(name) == "string" and not HHT.IsSecret(name) and clawNames[name] == true
end

-- The focus of the pet, nil when it cannot be read (it can be a secret value in combat).
local function ReadFocus()
    local ok, cur = pcall(UnitPower, "pet")
    if not ok then return nil end
    return HHT.SafeNumber(cur)
end

-- The focus is a secret value in this client, so Lua cannot compare it. A curve turns the focus fraction into the icon alpha
-- inside the client: 1 from the threshold up, otherwise lowAlpha (0 or a dimmed value).
local curve, curveKey
local function AlphaCurve(threshold, lowAlpha)
    local key = threshold .. ":" .. lowAlpha
    if curve and curveKey == key then return curve end
    curve, curveKey = nil, nil
    if not (C_CurveUtil and C_CurveUtil.CreateCurve) then return nil end
    local okM, mx = pcall(UnitPowerMax, "pet")
    mx = okM and HHT.SafeNumber(mx) or nil
    if not mx or mx <= 0 then mx = 100 end
    local x = math.min(1, math.max(0, threshold / mx))
    local ok, c = pcall(C_CurveUtil.CreateCurve)
    if not (ok and c) then return nil end
    local okA = pcall(function()
        c:AddPoint(0, x <= 0 and 1 or lowAlpha)
        if x > 0.004 then c:AddPoint(x - 0.002, lowAlpha) end
        if x > 0 then c:AddPoint(x, 1) end
        if x < 1 then c:AddPoint(1, 1) end
    end)
    if not okA then return nil end
    local okL, lo = pcall(c.Evaluate, c, math.max(0, x - 0.05))
    local okH, hi = pcall(c.Evaluate, c, math.min(1, x + 0.05))
    lo, hi = okL and HHT.SafeNumber(lo), okH and HHT.SafeNumber(hi)
    if not (hi and hi > 0.99 and (x <= 0.05 or (lo and lo < 0.99 and x > 0))) then return nil end
    curve, curveKey = c, key
    return c
end

-- Runs a curve on the focus fraction of the pet; the result can be a secret value.
local function PetPercent(c)
    if not UnitPowerPercent then return nil end
    local pt = Enum and Enum.PowerType and Enum.PowerType.Focus or 2
    local ok, v = pcall(UnitPowerPercent, "pet", pt, false, c)
    if ok and v ~= nil then return v end
    ok, v = pcall(UnitPowerPercent, "pet", pt, c)
    if ok and v ~= nil then return v end
end

-- The alpha for the current focus (secret in combat), nil when the client cannot be asked.
local function FocusAlpha(db, lowAlpha)
    local c = AlphaCurve(db.threshold, lowAlpha)
    if not (c and UnitPowerPercent) then return nil end
    return PetPercent(c)
end

-- In combat the focus can be hidden from addons; then the usability of the pet bar button (enough focus for Claw) stands in for it.
local function ReadUsable(slot)
    if not slot or type(GetPetActionSlotUsable) ~= "function" then return nil end
    local ok, usable = pcall(GetPetActionSlotUsable, slot)
    if not ok or HHT.IsSecret(usable) or type(usable) ~= "boolean" then return nil end
    return usable
end

-- The key bound to Claw's pet bar button.
local function BarKey(slot)
    local k = slot and GetBindingKey("BONUSACTIONBUTTON" .. slot)
    if not k then return nil end
    return GetBindingText and GetBindingText(k, "KEY_") or k
end

-- Pet bar slot and icon of Claw; nil when the bar cannot be read, false when Claw is not on it.
local function ReadBar()
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local ok, name, tex, _, _, _, _, spellId = pcall(GetPetActionInfo, slot)
        if not ok or HHT.IsSecret(name) then return nil end
        if IsClaw(name, spellId) then
            if type(tex) == "string" and type(_G[tex]) == "string" then tex = _G[tex] end
            return slot, (type(tex) == "string" or type(tex) == "number") and tex or nil
        end
    end
    return false
end

function M:OnInit()
    -- Test versions saved "always" before the combat default existed; it is set once for them.
    if not self.db.combatDefault then
        self.db.combatDefault = true
        self.db.showWhen = "combat"
    end
    -- Test versions saved an own default color for the ring; it is replaced by the focus bar color once.
    local rc = self.db.colors and self.db.colors.ring
    if rc and not self.db.ringColorDefault then
        self.db.ringColorDefault = true
        if math.abs(rc[1] - 1) < 0.01 and math.abs(rc[2] - 0.65) < 0.01 and math.abs(rc[3] - 0.2) < 0.01 then
            self.db.colors.ring = { FOCUS_COLOR[1], FOCUS_COLOR[2], FOCUS_COLOR[3] }
        end
    end
    self.owner = CreateFrame("Frame")
    self.bindDirty = true
    for _, ev in ipairs({ "PET_BAR_UPDATE", "UNIT_PET", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED",
        "ACTIONBAR_SLOT_CHANGED", "UPDATE_BINDINGS", "ACTIONBAR_PAGE_CHANGED" }) do
        HHT:Listen(self, ev, "OnEvent")
    end
    HHT:Every(self, 0.2, M.Tick)

    -- The key and the lazy macros click this button, which uses Claw from the pet bar.
    local p = CreateFrame("Button", PROXY, UIParent, "SecureActionButtonTemplate")
    p:SetSize(1, 1)
    p:RegisterForClicks("AnyUp")
    p:SetAttribute("useOnKeyDown", false)
    self.proxy = p

    self.macros = {}
    for i = 1, MAX_SPELLS do
        local b = CreateFrame("Button", MACRO .. i, UIParent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
        b:SetSize(1, 1)
        b:RegisterForClicks("AnyDown", "AnyUp")
        b:SetAttribute("type1", "macro")
        SecureHandlerWrapScript(b, "OnClick", b, SNIPPET)
        self.macros[i] = b
    end
end

function M:OnEvent()
    self.bindDirty = true
    self:Tick()
end

-- Focus ring: 60 soft glowing ring wedges around the icon (they blend additively into one smooth ring), each lit by its own step curve once the focus fraction reaches its share.
local RING_DIR = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
local RING_N = 60
local RING_CORE = 0.84 -- share of the wedge texture radius taken by the ring itself; the rest is glow
local RING_STEPS = { 70, 74, 78, 82, 86, 90, 94, 98 }
local ringCurves = {}

local function RingCurve(i)
    if ringCurves[i] then return ringCurves[i] end
    if not (C_CurveUtil and C_CurveUtil.CreateCurve) then return nil end
    local ok, c = pcall(C_CurveUtil.CreateCurve)
    if not (ok and c) then return nil end
    local x = (i - 0.5) / RING_N
    local okA = pcall(function()
        c:AddPoint(0, 0)
        c:AddPoint(x - 0.002, 0)
        c:AddPoint(x, 1)
        c:AddPoint(1, 1)
    end)
    if not okA then return nil end
    ringCurves[i] = c
    return c
end

function M:LayoutRing()
    local f, db = self.frame, self.db
    local ring = self.ring or {}
    self.ring = ring
    if not db.showRing then
        for _, seg in ipairs(ring) do seg:Hide() end
        if self.ringBg then self.ringBg:Hide() end
        self.ringN = 0
        return
    end
    -- The ring textures come in fixed thickness steps; pick the one closest to the wanted width.
    local inner = db.size + 2
    local want = inner / (inner + 2 * db.ringWidth) * 100
    local pct = RING_STEPS[1]
    for _, s in ipairs(RING_STEPS) do
        if math.abs(s - want) < math.abs(pct - want) then pct = s end
    end
    local core = inner / (pct / 100)
    local d = core / RING_CORE
    if not self.ringBg then
        self.ringBg = f:CreateTexture(nil, "BACKGROUND")
        self.ringBg:SetVertexColor(0, 0, 0, 0.45)
    end
    self.ringBg:SetTexture(RING_DIR .. "RoundRing" .. pct)
    self.ringBg:ClearAllPoints()
    self.ringBg:SetPoint("CENTER", f, "CENTER", 0, 0)
    self.ringBg:SetSize(core, core)
    self.ringBg:Show()
    for i = 1, RING_N do
        local seg = ring[i]
        if not seg then
            seg = CreateFrame("Frame", nil, f)
            seg.fill = seg:CreateTexture(nil, "ARTWORK")
            seg.fill:SetAllPoints(seg)
            seg.fill:SetBlendMode("ADD")
            seg.fill:SetRotation(-(i - 0.5) / RING_N * 2 * math.pi)
            ring[i] = seg
        end
        seg.fill:SetTexture(RING_DIR .. "RingGlow" .. pct)
        seg:ClearAllPoints()
        seg:SetPoint("CENTER", f, "CENTER", 0, 0)
        seg:SetSize(d, d)
        seg:Show()
    end
    self.ringN, self.ringSig = RING_N, nil
end

function M:PaintRing(unlocked)
    local n, ring = self.ringN or 0, self.ring
    if n == 0 or not ring then return end
    local r, g, b = HHT.Col(self.db, "ring")
    local csig = table.concat({ r, g, b }, ",")
    if csig ~= self.ringSig then
        self.ringSig = csig
        for i = 1, n do ring[i].fill:SetVertexColor(r, g, b) end
    end
    local frac
    if unlocked then
        frac = 0.65
    elseif self.focus ~= nil then
        local okM, mx = pcall(UnitPowerMax, "pet")
        mx = okM and HHT.SafeNumber(mx) or nil
        if not mx or mx <= 0 then mx = 100 end
        frac = self.focus / mx
    end
    if frac then
        for i = 1, n do ring[i]:SetAlpha((i - 0.5) / n <= frac and 1 or 0) end
        return
    end
    for i = 1, n do
        local seg = ring[i]
        local c = RingCurve(i)
        local v = c and PetPercent(c)
        if v == nil then
            seg:SetAlpha(0)
        elseif HHT.IsSecret(v) then
            if not pcall(seg.SetAlpha, seg, v) then seg:SetAlpha(0) end
        else
            seg:SetAlpha(v)
        end
    end
end
function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsPetClaw", UIParent)
    f:SetSize(44, 44)
    self.frame = f
    f.icon = Icon.New(f)
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    local b = CreateFrame("Button", "HamingwaysHunterToolsPetClawButton", f, "SecureActionButtonTemplate")
    b:SetAllPoints(f.icon)
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("useOnKeyDown", false)
    b:SetScript("OnEnter", function(btn) M:ShowTip(btn) end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.button = b

    HHT:MakeMovable(f, self, "main", L("Pet Claw"))
    self:Layout()
end

function M:ShowTip(anchor)
    if not GameTooltip then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L("Pet Claw"), 1, 1, 1)
    if self.slot then
        GameTooltip:AddLine(L("Left-click or key: Claw"), 0.7, 0.7, 0.7)
        if self.focus then
            GameTooltip:AddLine(string.format(L("Pet focus: %d"), self.focus), 0.67, 0.83, 0.45)
        end
    else
        GameTooltip:AddLine(L("Your pet has no Claw on its pet bar."), 0.9, 0.35, 0.3)
    end
    GameTooltip:Show()
end

function M:ApplyDriver()
    local f = self.frame
    if not f then return end
    if InCombatLockdown() then self.driverDirty = true; return end
    self.driverDirty = false
    if HHT:IsUnlocked(self) or not self.enabled then
        if self.driverOn then UnregisterStateDriver(f, "visibility"); self.driverOn = false end
        if self.enabled then f:Show() end
    elseif not self.driverOn then
        RegisterStateDriver(f, "visibility", DRIVER)
        self.driverOn = true
    end
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self.db
    -- The frame holds a secure button, so it can only be resized out of combat; Tick repeats it after the fight.
    if InCombatLockdown() then self.layoutDirty = true; return end
    self.layoutDirty = false
    f:SetSize(db.size, db.size)
    f.icon:Style(db.size, db.shape, db.borderSize, db.borderAlpha, false)
    self:LayoutRing()
    HHT:ApplyGlobalLook(f)
end

function M:OnEnable()
    self:Build()
    self.attrSig, self.macroSig, self.bindSig = nil, nil, nil
    self.bindDirty = true
    self:ApplyDriver()
    self:Tick()
end

function M:OnDisable()
    self.bindDirty = true
    self:ApplyBindings()
    local f = self.frame
    if not f then return end
    if InCombatLockdown() then
        HHT.HideSecure(f)
        self.driverDirty = true
        return
    end
    if self.driverOn then UnregisterStateDriver(f, "visibility"); self.driverOn = false end
    f:Hide()
end

function M:Refresh()
    self:Layout()
    self:ApplyDriver()
    self.attrSig, self.macroSig = nil, nil
    self.bindDirty = true
    self:Tick()
end

function M:OnLockChanged()
    self.mouse = nil
    self:ApplyDriver()
    self:Tick()
end

-- Puts Claw on the key button, the on-screen button and the lazy macros; only possible out of combat.
function M:ApplyAttributes()
    local db, slot = self.db, self.slot
    local asig = tostring(slot)
    if asig ~= self.attrSig then
        self.attrSig = asig
        for _, b in ipairs({ self.proxy, self.button }) do
            b:SetAttribute("type1", slot and "pet" or nil)
            b:SetAttribute("action1", slot or nil)
        end
        self.bindDirty = true
    end
    local parts = { tostring(slot), tostring(db.threshold), tostring(db.lazy) }
    for i = 1, MAX_SPELLS do parts[#parts + 1] = db.spells[i] or "" end
    local msig = table.concat(parts, "|")
    if msig ~= self.macroSig then
        self.macroSig = msig
        for i, b in ipairs(self.macros) do
            local name = db.lazy and db.spells[i]
            if name and name ~= "" then
                local plain = "/cast " .. name
                local full = slot and (plain .. "\n/click " .. PROXY) or plain
                b:SetAttribute("plainmacro", plain)
                b:SetAttribute("fullmacro", full)
                b:SetAttribute("threshold", slot and db.threshold or 0)
                b:SetAttribute("macrotext1", full)
            else
                b:SetAttribute("plainmacro", nil)
                b:SetAttribute("fullmacro", nil)
                b:SetAttribute("macrotext1", nil)
            end
        end
        self.bindDirty = true
    end
end

function M:ApplyBindings()
    if InCombatLockdown() then self.bindDirty = true; return end
    self.bindDirty = false
    local db = self.db
    local want, seen = {}, {}
    local function Add(key, btn)
        if key and key ~= "" and not seen[key] then
            seen[key] = true
            want[#want + 1] = { key, btn }
        end
    end
    if self.enabled and self.slot then
        Add(db.key, PROXY)
        if db.lazy and db.override then
            local all = HHT.Keys.AllBinds()
            for i = 1, MAX_SPELLS do
                local name = db.spells[i]
                for _, k in ipairs(name and all[name] or {}) do Add(k, MACRO .. i) end
            end
        end
    end
    local parts = {}
    for _, w in ipairs(want) do parts[#parts + 1] = w[1] .. ">" .. w[2] end
    local sig = table.concat(parts, ",")
    if sig == self.bindSig then return end
    self.bindSig = sig
    ClearOverrideBindings(self.owner)
    for _, w in ipairs(want) do HHT.BindClick(self.owner, w[1], w[2], "") end
end

function M:Paint()
    local f, db = self.frame, self.db
    local ic = f.icon
    local slot, tex = ReadBar()
    if slot ~= nil then
        self.slot = slot or nil
        if tex then self.tex = tex end
    end
    local pet = HHT.SafeBool(UnitExists, "pet") == true
    local unlocked = HHT:IsUnlocked(self)
    local focus = ReadFocus()
    self.focus = focus
    local lowAlpha = db.hideLow and 0 or db.dimAlpha
    local ready, curveAlpha = true, nil
    if focus ~= nil then
        ready = focus >= db.threshold
    elseif not unlocked then
        curveAlpha = FocusAlpha(db, lowAlpha)
        if curveAlpha == nil then ready = ReadUsable(self.slot) ~= false end
    end
    local usable = pet and self.slot and db.showButton
    local c = db.colors.ready
    local kr, kg, kb = HHT.Col(db, "key")
    local key = db.key ~= "" and db.key:upper() or (db.showKeys and BarKey(self.slot)) or nil
    local sig = table.concat({ tostring(self.tex), tostring(ready), tostring(usable), tostring(unlocked), tostring(key), db.keySize, db.keyPos, kr, kg, kb, c[1], c[2], c[3] }, ",")
    if sig ~= self.sig then
        self.sig = sig
        ic:SetIcon(self.tex or S.Texture(16827) or FALLBACK_ICON)
        ic:SetBorderColor(c[1], c[2], c[3])
        ic:SetDesaturated(not ready)
        ic:SetKey(key, db.keySize, db.keyPos, kr, kg, kb)
    end
    -- Claw has no cooldown of its own, so the sweep on the icon is the global cooldown of the pet bar.
    local start, dur
    if db.showGcd and self.slot and pet and not unlocked then
        local okC, s, d = pcall(GetPetActionCooldown, self.slot)
        if okC then start, dur = s, d end
    end
    if start == nil then
        if self.gcdOn then ic:ClearCooldown(); self.gcdOn = false; self.gcdStart = nil end
    elseif HHT.IsSecret(start) or HHT.IsSecret(dur) then
        if pcall(ic.SetTimer, ic, start, dur) then self.gcdOn = true end
        self.gcdStart = nil
    elseif type(start) == "number" and type(dur) == "number" and dur > 0 then
        if self.gcdStart ~= start then
            ic:SetTimer(start, dur)
            self.gcdStart, self.gcdOn = start, true
        end
    elseif self.gcdOn then
        ic:ClearCooldown()
        self.gcdOn, self.gcdStart = false, nil
    end
    self:PaintRing(unlocked)
    local alpha = 0
    if usable or unlocked then
        alpha = ready and 1 or ((db.hideLow and not unlocked) and 0 or db.dimAlpha)
    end
    if curveAlpha ~= nil and (usable or unlocked) then
        if HHT.IsSecret(curveAlpha) then
            if not pcall(ic.SetAlpha, ic, curveAlpha) then ic:SetAlpha(1) end
            return
        end
        alpha = curveAlpha
    end
    ic:SetAlpha(alpha)
end

function M:Tick()
    local f = self.frame
    if not f then return end
    HHT.FlushHidden(f)
    self:Paint()
    if InCombatLockdown() then return end
    if self.layoutDirty then self:Layout() end
    if self.driverDirty then self:ApplyDriver() end
    self:ApplyAttributes()
    local mouse = not HHT:IsUnlocked(self) and self.db.showButton and self.slot ~= nil
    if self.mouse ~= mouse then
        self.mouse = mouse
        self.button:EnableMouse(mouse and true or false)
    end
    if self.bindDirty then self:ApplyBindings() end
end

-- /hht claw: two short lines about the focus and the secure environment. Run it in combat as well.
function M:Debug()
    local db = self.db
    local function Val(v) return v == nil and "nil" or (HHT.IsSecret(v) and "secret" or tostring(v)) end
    local okP, cur = pcall(UnitPower, "pet")
    local alphaV = FocusAlpha(db, db.hideLow and 0 or db.dimAlpha)
    local setOk = "n/a"
    if alphaV ~= nil then
        self.dbgFrame = self.dbgFrame or CreateFrame("Frame")
        setOk = tostring((pcall(self.dbgFrame.SetAlpha, self.dbgFrame, alphaV)))
    end
    -- Does the secure environment know UnitPower? If so, the lazy macros can check the focus in combat.
    local probe = self.probe
    if not probe then
        probe = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
        self.probe = probe
    end
    local okE, err = pcall(probe.Execute, probe, [[
        if UnitPower then
            self:SetAttribute("hasPower", "yes")
            self:SetAttribute("power", UnitPower("pet") or -1)
        else
            self:SetAttribute("hasPower", "no")
        end
    ]])
    HHT.Print(string.format("claw: combat=%s slot=%s focus=%s curveAlpha=%s setAlpha=%s",
        tostring(InCombatLockdown()), tostring(self.slot), okP and Val(cur) or "error", Val(alphaV), setOk))
    HHT.Print(string.format("claw secure: run=%s UnitPower=%s power=%s%s",
        tostring(okE), tostring(probe:GetAttribute("hasPower")), tostring(probe:GetAttribute("power")), okE and "" or (" err=" .. tostring(err))))
end
-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
local ROW_H = 24

local function BuildSpellList(m, form)
    local db = m.db
    local list = CreateFrame("Frame", nil, form.content)
    list:SetSize(380, 10)
    list.rows = {}
    local addBtn

    local function Changed()
        m.macroSig, m.bindSig = nil, nil
        m.bindDirty = true
        HHT:RefreshModule(m)
    end

    local function Rebuild()
        local n = #db.spells
        local binds = (n > 0 and not InCombatLockdown()) and HHT.Keys.AllBinds() or {}
        for i = 1, MAX_SPELLS do
            local row = list.rows[i]
            if i <= n then
                if not row then
                    row = CreateFrame("Frame", nil, list)
                    row:SetSize(380, ROW_H)
                    row.icon = row:CreateTexture(nil, "ARTWORK")
                    row.icon:SetSize(18, 18)
                    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
                    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                    row.text = UI.Text(row, "", 12)
                    row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                    row.text:SetWidth(150)
                    row.text:SetJustifyH("LEFT")
                    row.keys = UI.Text(row, "", 11, 0.68, 0.65, 0.58)
                    row.keys:SetPoint("LEFT", row, "LEFT", 180, 0)
                    row.keys:SetWidth(150)
                    row.keys:SetJustifyH("LEFT")
                    row.del = UI.Button(row, 20, 20, "x", function()
                        table.remove(db.spells, row.index)
                        list:Refresh(); Changed()
                    end)
                    row.del:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                    list.rows[i] = row
                end
                row.index = i
                local name = db.spells[i]
                local rs = S.Resolve(name)
                row.icon:SetTexture(rs.icon)
                row.text:SetText(name)
                local keys = binds[name]
                row.keys:SetText(keys and table.concat(keys, ", ") or "")
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(i - 1) * ROW_H)
                row:Show()
            elseif row then
                row:Hide()
            end
        end
        local h = n * ROW_H + 30
        list:SetHeight(h)
        addBtn:ClearAllPoints()
        addBtn:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(n * ROW_H + 6))
        addBtn:SetShown(n < MAX_SPELLS)
        form:SetTail(h)
    end

    addBtn = UI.Button(list, 140, 22, L("Add attack"), function(self)
        local have = {}
        for _, s in ipairs(db.spells) do have[s] = true end
        local items = {}
        for _, it in ipairs(S.ListSpellbook()) do
            if not have[it.value] then items[#items + 1] = it end
        end
        UI.ShowMenu(self, items, function(item)
            if #db.spells >= MAX_SPELLS then return end
            db.spells[#db.spells + 1] = item.value
            list:Refresh(); Changed()
        end)
    end)

    list.Refresh = Rebuild
    form:PlaceTail(list)
    Rebuild()
    return list
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 24, 128, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Stepper(L("Border alpha"), db, "borderAlpha", 0, 1, 0.1)
    form:Header(L("Claw button"))
    form:Check(L("Show the Claw button"), db, "showButton")
    form:Check(L("Hide when focus is low"), db, "hideLow")
    form:Stepper(L("Dimmed opacity"), db, "dimAlpha", 0.05, 0.95, 0.05)
    form:Check(L("Show the global cooldown"), db, "showGcd")
    form:Check(L("Show a ring with the pet focus"), db, "showRing")
    form:Stepper(L("Ring width"), db, "ringWidth", 2, 12, 1)
    form:Stepper(L("Focus needed for Claw"), db, "threshold", 0, 100, 5)
    form:Note(L("The Claw button only works while your pet has Claw on its pet bar. The key replaces its normal function while it is set."))
    form:Group("claw notes")
    local keyBtn = form:Button("", function()
        if HHT.CaptureKey then
            HHT.CaptureKey(function(key)
                db.key = key
                self.bindDirty = true
                self.sig = nil
                form:Refresh()
            end)
        end
    end, 220)
    form:Name("claw: set key")
    function keyBtn:Refresh()
        self:SetLabel(string.format(L("Claw key: %s"), db.key ~= "" and db.key:upper() or L("not set")))
    end
    keyBtn:Refresh()
    form:Button(L("Clear Claw key"), function()
        db.key = ""
        self.bindDirty = true
        self.sig = nil
        keyBtn:Refresh()
    end, 220)
    form:Name("claw: clear key")
    form:Header(L("Easy mode"))
    form:Note(L("Claw has no cooldown, so it eats your pet's focus and delays Growl and other abilities. Pick up to 10 attacks: their keys then also fire Claw, so you do not have to think about it."))
    form:Group("lazy notes")
    form:Check(L("Add Claw to other attacks"), db, "lazy", function()
        self.macroSig, self.bindSig = nil, nil
        self.bindDirty = true
    end)
    form:Check(L("Replace the keys of these attacks"), db, "override", function()
        self.bindSig = nil
        self.bindDirty = true
    end)
    form:Note(L("Replaces the keys of the chosen attacks on your action bars with a macro that also uses Claw. Mouse clicks on the bar buttons are not changed. Switch it off to get your own keys back."))
    form:Group("lazy notes")
    form:Note(L("The game hides the pet focus from macros, so the focus limit does not apply here: Claw is added to every press of these attacks."))
    form:Group("lazy notes")
    form:Note(L("Changes apply after combat."))
    form:Group("lazy notes")
    form.spellList = BuildSpellList(self, form)
    form:Name("Attacks with Claw")
    form:Header(L("Colors"))
    form:Color(L("Ready border"), db.colors, "ready")
    form:Color(L("Focus ring color"), db.colors, "ring")
    HHT.Keys.AddOptions(form, db)
end
