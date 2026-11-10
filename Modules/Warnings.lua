-- Warnings: missing aspect / Trueshot Aura / Hunter's Mark / pet. Aura checks only run when aura data is readable.
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Warnings"] = "Warnungen",
    ["Icon warnings for missing aspect, Trueshot Aura, Hunter's Mark and pet."] = "Symbol-Warnungen fuer fehlenden Aspekt, Aura des Scharfschuetzen, Mal des Jaegers und Begleiter.",
    ["Warn when no aspect is active"] = "Warnen wenn kein Aspekt aktiv ist",
    ["Show the active aspect"] = "Aktiven Aspekt anzeigen",
    ["Preferred aspect"] = "Bevorzugter Aspekt",
    ["Warn when Trueshot Aura is missing"] = "Warnen wenn Trueshot-Aura fehlt",
    ["Warn when Hunter's Mark is missing"] = "Warnen wenn Mal des Jaegers fehlt",
    ["Hunter's Mark targets"] = "Mal-des-Jaegers Ziele",
    ["Elites and bosses only"] = "Nur Elite und Bosse",
    ["Every enemy"] = "Jeder Gegner",
    ["Warn when the pet is missing or dead"] = "Warnen wenn Begleiter fehlt oder tot ist",
    ["Blink warnings"] = "Warnungen blinken lassen",
    ["Play a sound for new warnings"] = "Ton bei neuen Warnungen",
    ["Show text under icons"] = "Text unter Symbolen zeigen",
    ["Warning border"] = "Rahmen Warnung",
    ["Active border"] = "Rahmen aktiv",
    ["Hide warnings in combat"] = "Warnungen im Kampf ausblenden",
    ["No aspect"] = "Kein Aspekt",
    ["Warn when another aspect than the preferred one is active"] = "Warnen wenn ein anderer als der bevorzugte Aspekt aktiv ist",
    ["Wrong aspect"] = "Falscher Aspekt",
    ["No Trueshot Aura"] = "Keine Trueshot-Aura",
    ["No Hunter's Mark"] = "Kein Jaegermal",
    ["No pet"] = "Kein Begleiter",
    ["Pet dead"] = "Begleiter tot",
    ["Aspect"] = "Aspekt",
    ["Trueshot Aura"] = "Aura des Scharfschuetzen",
    ["Hunter's Mark"] = "Mal des Jaegers",
    ["Pet"] = "Begleiter",
})

local M = HHT:NewModule("warnings", {
    name = "Warnings",
    desc = "Icon warnings for missing aspect, Trueshot Aura, Hunter's Mark and pet.",
    positions = { main = { "CENTER", "CENTER", 0, 120 } },
    defaults = {
        size = 48, shape = "round", borderSize = 2, borderAlpha = 1, spacing = 10, grow = "right",
        blink = true, sound = false, showText = true, hideInCombat = false,
        aspectWarn = true, aspectWrong = true, aspectShow = false, aspectMain = "aspectHawk",
        trueshotWarn = true,
        markWarn = true, markTargets = "elite",
        petWarn = true,
        showKeys = true, keySize = 14, keyPos = "TOPRIGHT",
        colors = {
            warn = { 0.95, 0.25, 0.20 },
            ok = { 0.67, 0.83, 0.45 },
            key = { 1, 1, 0.4 },
        },
    },
})

local PREFERRED = { "aspectHawk", "aspectMonkey", "aspectCheetah", "aspectPack", "aspectWild", "aspectBeast", "aspectViper", "aspectDragonhawk" }

function M:OnInit()
    self.icons = {}
    self.sig = false
    self.currentAspect = false
    self.lastWarnCount = 0
    HHT:Every(self, 0.25, M.Tick)
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsWarnings", UIParent)
    f:SetSize(48, 48)
    self.frame = f
    HHT:MakeMovable(f, self, "main", L("Warnings"))
end

function M:OnEnable()
    self:Build()
    self.frame:Show()
    self.sig = false
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
    for _, ic in ipairs(self.icons) do ic:SetBlink(false) end
end

function M:Refresh()
    self.sig = false
    if self.frame then
        self.frame:SetSize(self.db.size, self.db.size)
        HHT:ApplyGlobalLook(self.frame)
    end
end

function M:OnLockChanged()
    self.sig = false
end

local function Quiet()
    if IsMounted and IsMounted() then return true end
    if UnitOnTaxi and UnitOnTaxi("player") then return true end
    if UnitIsDeadOrGhost("player") then return true end
    if UnitInVehicle and UnitInVehicle("player") then return true end
    return false
end
M.Quiet = Quiet

function M:PollAspect()
    local result = false
    for _, key in ipairs(S.Aspects) do
        local rs = S.Resolve("@" .. key)
        if rs.known then
            local found = S.AuraByName("player", rs.name, "HELPFUL")
            if found == nil then return end -- unreadable (combat): keep the last known aspect
            if found then result = key; break end
        end
    end
    self.currentAspect = result
end

local function Add(list, key, icon, text, warn, spell)
    list[#list + 1] = { key = key, icon = icon, text = text, warn = warn, spell = spell }
end

function M:Collect()
    local db = self.db
    local list = {}
    local unlocked = HHT:IsUnlocked()

    if unlocked then
        Add(list, "aspect", S.Resolve("@" .. db.aspectMain).icon, L("No aspect"), true, S.Resolve("@" .. db.aspectMain).name)
        Add(list, "trueshot", S.Resolve("@trueshotAura").icon, L("No Trueshot Aura"), true, S.Resolve("@trueshotAura").name)
        Add(list, "mark", S.Resolve("@hunterMark").icon, L("No Hunter's Mark"), true, S.Resolve("@hunterMark").name)
        Add(list, "pet", S.Resolve("@callPet").icon, L("No pet"), true, S.Resolve("@callPet").name)
        return list
    end

    if Quiet() then return list end
    if db.hideInCombat and HHT.InCombat() then return list end

    if db.aspectWarn or db.aspectShow then
        self:PollAspect()
        local cur = self.currentAspect
        if cur then
            local pref = S.Resolve("@" .. db.aspectMain)
            if db.aspectWarn and db.aspectWrong and cur ~= db.aspectMain and pref.known then
                Add(list, "aspect", pref.icon, L("Wrong aspect"), true, pref.name)
            elseif db.aspectShow then
                local act = S.Resolve("@" .. cur)
                Add(list, "aspect", act.icon, "", false, act.name)
            end
        elseif db.aspectWarn then
            local pref = S.Resolve("@" .. db.aspectMain)
            if not pref.known then
                for _, key in ipairs(S.Aspects) do
                    local rs = S.Resolve("@" .. key)
                    if rs.known then pref = rs; break end
                end
            end
            if pref.known then Add(list, "aspect", pref.icon, L("No aspect"), true, pref.name) end
        end
    end

    if db.trueshotWarn then
        local rs = S.Resolve("@trueshotAura")
        if rs.known then
            local found = S.AuraByName("player", rs.name, "HELPFUL")
            if found == false then Add(list, "trueshot", rs.icon, L("No Trueshot Aura"), true, rs.name) end
        end
    end

    if db.markWarn and HHT.HasAttackableTarget() then
        local rs = S.Resolve("@hunterMark")
        if rs.known then
            local worth = true
            if db.markTargets == "elite" then
                local ok, c = pcall(UnitClassification, "target")
                worth = ok and not HHT.IsSecret(c) and c ~= "normal" and c ~= "trivial" and c ~= "minus"
            end
            if worth then
                local found = S.AuraByName("target", rs.name, "HARMFUL|PLAYER")
                if found == false then Add(list, "mark", rs.icon, L("No Hunter's Mark"), true, rs.name) end
            end
        end
    end

    if db.petWarn and (UnitLevel("player") or 1) >= 10 then
        local callPet = S.Resolve("@callPet")
        if callPet.known then
            local ok, ex = pcall(UnitExists, "pet")
            local exists
            if ok and not HHT.IsSecret(ex) then exists = ex and true or false end
            if exists == false then
                Add(list, "pet", callPet.icon, L("No pet"), true, callPet.name)
            elseif exists == true and HHT.SafeBool(UnitIsDead, "pet") == true then
                local rev = S.Resolve("@revivePet")
                Add(list, "pet", rev.icon, L("Pet dead"), true, rev.name)
            end
        end
    end
    return list
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    local list = self:Collect()

    local sig = {}
    for _, e in ipairs(list) do sig[#sig + 1] = e.key .. (e.warn and "!" or "") .. tostring(e.icon) end
    local signature = table.concat(sig, ",")
    if signature == self.sig then
        for i, e in ipairs(list) do
            if self.icons[i] then HHT.Keys.Apply(self.icons[i], db, e.spell) end
        end
        return
    end
    self.sig = signature

    local s, sp = db.size, db.spacing
    f:SetSize(s, s)
    local used = 0
    for i, e in ipairs(list) do
        local ic = self.icons[i]
        if not ic then ic = Icon.New(f); self.icons[i] = ic end
        ic:Style(s, db.shape, db.borderSize, db.borderAlpha, true)
        ic:SetIcon(e.icon)
        ic:SetBorderColor(HHT.Col(db, e.warn and "warn" or "ok"))
        ic:ClearCooldown()
        ic.label:SetWidth(s + sp)
        ic.label:SetWordWrap(true)
        ic.label:SetText(db.showText and e.text or "")
        ic.label:SetTextColor(HHT.Col(db, e.warn and "warn" or "ok"))
        ic:SetBlink(e.warn and db.blink)
        HHT.Keys.Apply(ic, db, e.spell)
        local step = (s + sp) * (i - 1)
        ic:ClearAllPoints()
        if db.grow == "right" then ic:SetPoint("TOPLEFT", f, "TOPLEFT", step, 0)
        elseif db.grow == "left" then ic:SetPoint("TOPRIGHT", f, "TOPRIGHT", -step, 0)
        elseif db.grow == "down" then ic:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -step)
        else ic:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, step) end
        ic:Show()
        used = i
    end
    for i = used + 1, #self.icons do
        self.icons[i]:SetBlink(false)
        self.icons[i]:Hide()
    end

    local warns = 0
    for _, e in ipairs(list) do if e.warn then warns = warns + 1 end end
    if db.sound and warns > self.lastWarnCount and not HHT:IsUnlocked() then
        pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959)
    end
    self.lastWarnCount = warns
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 24, 128, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Stepper(L("Border alpha"), db, "borderAlpha", 0, 1, 0.1)
    form:Stepper(L("Spacing"), db, "spacing", 0, 40, 1)
    form:Cycle(L("Grow direction"), db, "grow", {
        { "right", L("Right") }, { "left", L("Left") }, { "up", L("Up") }, { "down", L("Down") } })
    form:Check(L("Show text under icons"), db, "showText")
    form:Check(L("Blink warnings"), db, "blink")
    form:Check(L("Play a sound for new warnings"), db, "sound")
    form:Check(L("Hide warnings in combat"), db, "hideInCombat")
    HHT.Keys.AddOptions(form, db)
    form:Header(L("Aspect"))
    form:Check(L("Warn when no aspect is active"), db, "aspectWarn")
    form:Check(L("Warn when another aspect than the preferred one is active"), db, "aspectWrong")
    form:Check(L("Show the active aspect"), db, "aspectShow")
    local choices = {}
    for _, key in ipairs(PREFERRED) do
        choices[#choices + 1] = { key, S.CatalogName(key) }
    end
    form:Cycle(L("Preferred aspect"), db, "aspectMain", choices)
    form:Header(L("Trueshot Aura"))
    form:Check(L("Warn when Trueshot Aura is missing"), db, "trueshotWarn")
    form:Header(L("Hunter's Mark"))
    form:Check(L("Warn when Hunter's Mark is missing"), db, "markWarn")
    form:Cycle(L("Hunter's Mark targets"), db, "markTargets", {
        { "elite", L("Elites and bosses only") }, { "all", L("Every enemy") } })
    form:Header(L("Pet"))
    form:Check(L("Warn when the pet is missing or dead"), db, "petWarn")
    form:Header(L("Colors"))
    form:Color(L("Warning border"), db.colors, "warn")
    form:Color(L("Active border"), db.colors, "ok")
end
