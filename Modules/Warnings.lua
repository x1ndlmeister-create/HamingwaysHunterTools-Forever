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
    ["Click a warning to cast the spell"] = "Auf eine Warnung klicken, um den Zauber zu wirken",
    ["Click: cast %s"] = "Klick: %s wirken",
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
    ["Warn when the pet's health is low"] = "Warnen wenn die Gesundheit des Begleiters niedrig ist",
    ["Low health below (%)"] = "Niedrige Gesundheit unter (%)",
    ["Warn when the hurt pet is out of Mend Pet range"] = "Warnen wenn der verletzte Begleiter ausserhalb der Reichweite von Tier heilen ist",
    ["Pet low health"] = "Begleiter verletzt",
    ["Pet out of heal range"] = "Begleiter ausser Heilreichweite",
    ["Growl"] = "Knurren",
    ["Warn when the pet's Growl autocast is on"] = "Warnen wenn Knurren des Begleiters auf Autocast steht",
    ["Only in dungeons and raids"] = "Nur in Dungeons und Schlachtzuegen",
    ["Growl on"] = "Knurren an",
    ["Click: switch off %s autocast"] = "Klick: Autocast von %s ausschalten",
    ["Right-click: hide this warning until reload"] = "Rechtsklick: Warnung bis zum Neuladen ausblenden",
    ["Warn when Aspect of the Pack is active"] = "Warnen wenn Aspekt des Rudels aktiv ist",
    ["Pack in dungeon"] = "Rudel im Dungeon",
    ["Click: switch to %s"] = "Klick: zu %s wechseln",
    ["Warn when the pet is hungry or pet food runs low (needs Pet feeder)"] = "Warnen wenn der Begleiter hungrig ist oder das Futter knapp wird (braucht Begleiter-Futter)",
    ["Pet hungry"] = "Begleiter hungrig",
    ["Low pet food"] = "Wenig Futter",
    ["Click: feed the pet"] = "Klick: Begleiter fuettern",
    ["Pet food"] = "Begleiter-Futter",
})

local M = HHT:NewModule("warnings", {
    name = "Warnings",
    desc = "Icon warnings for missing aspect, Trueshot Aura, Hunter's Mark and pet.",
    positions = { main = { "CENTER", "CENTER", 0, 120 } },
    defaults = {
        size = 48, shape = "round", borderSize = 2, borderAlpha = 1, spacing = 10, grow = "right", perRow = 8,
        blink = true, sound = false, showText = true, hideInCombat = false, clickCast = true,
        aspectWarn = true, aspectWrong = true, aspectShow = false, aspectMain = "aspectHawk",
        trueshotWarn = true,
        markWarn = true, markTargets = "elite",
        petWarn = true,
        petLowWarn = true, petLowPct = 35, petRangeWarn = true,
        growlWarn = true, growlInstanceOnly = true,
        packWarn = true, packInstanceOnly = true,
        foodWarn = true,
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

local function Add(list, key, icon, text, warn, spell, macro, tip, dismiss, keyText)
    list[#list + 1] = { key = key, icon = icon, text = text, warn = warn, spell = spell, macro = macro, tip = tip, dismiss = dismiss, keyText = keyText }
end

-- Shows the key of the spell, or an explicit key text such as the Pet feeder key.
local function ApplyKey(ic, db, e)
    if e.keyText and e.keyText ~= "" then
        ic:SetKey(db.showKeys and e.keyText or nil, db.keySize, db.keyPos, HHT.Col(db, "key"))
    else
        HHT.Keys.Apply(ic, db, e.spell)
    end
end

-- The aspect to switch to when Aspect of the Pack is active: the preferred one, or the first other known aspect.
local function PackReplacement(db)
    local pref = S.Resolve("@" .. db.aspectMain)
    if db.aspectMain ~= "aspectPack" and pref.known then return pref end
    for _, key in ipairs(PREFERRED) do
        if key ~= "aspectPack" then
            local rs = S.Resolve("@" .. key)
            if rs.known then return rs end
        end
    end
end

-- The secure button sits in a plain holder: its spell can only change out of combat, so in combat the holder hides when the icon no longer matches.
local function ClickButton(ic)
    if ic.hhtBtn then return ic.hhtHolder, ic.hhtBtn end
    if InCombatLockdown() then return end
    local h = CreateFrame("Frame", nil, ic)
    h:SetAllPoints(ic)
    h:SetFrameLevel(ic.over:GetFrameLevel() + 1)
    local b = CreateFrame("Button", nil, h, "SecureActionButtonTemplate")
    b:SetAllPoints(h)
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("useOnKeyDown", false)
    b:SetAttribute("type1", "spell")
    b:SetScript("OnEnter", function(self)
        if not (GameTooltip and self.want) or self:GetParent():GetParent():GetAlpha() == 0 then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.tip then
            GameTooltip:AddLine(self.tip, 1, 1, 1)
            GameTooltip:AddLine(L("Right-click: hide this warning until reload"), 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(string.format(L("Click: cast %s"), self.spell), 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    b:SetScript("PostClick", function(self, button)
        if button == "RightButton" and self.dismiss then
            M[self.dismiss] = true
            M.sig = false
        end
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    ic.hhtHolder, ic.hhtBtn = h, b
    return h, b
end

-- An entry clicks either its spell or a macro text.
function M:ApplyClick(ic, e)
    local h, b = ClickButton(ic)
    if not h then return end
    local want = e and (e.macro or e.spell)
    if want and b.want ~= want and not InCombatLockdown() then
        if e.macro then
            b:SetAttribute("type1", "macro")
            b:SetAttribute("macrotext1", e.macro)
        else
            b:SetAttribute("type1", "spell")
            b:SetAttribute("spell1", e.spell)
        end
        b.want, b.spell, b.tip, b.dismiss = want, e.spell, e.tip, e.dismiss
    end
    h:SetShown(self.db.clickCast and not HHT:IsUnlocked(self) and want ~= nil and b.want == want)
end

local function PetHealthPct()
    local okH, hp = pcall(UnitHealth, "pet")
    local okM, mx = pcall(UnitHealthMax, "pet")
    if not (okH and okM) then return nil end
    hp, mx = HHT.SafeNumber(hp), HHT.SafeNumber(mx)
    if hp and mx and mx > 0 then return hp / mx * 100 end
end

-- true / false, nil when the autocast state cannot be read.
local function GrowlAutocastOn(growl)
    local seen = false
    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local ok, name, _, isToken, _, allowed, enabled = pcall(GetPetActionInfo, slot)
        if not ok or HHT.IsSecret(name) or HHT.IsSecret(isToken) or HHT.IsSecret(allowed) or HHT.IsSecret(enabled) then return nil end
        if isToken and type(name) == "string" then name = _G[name] end
        if name == growl and allowed then
            seen = true
            if enabled then return true end
        end
    end
    return seen and false or nil
end

local function InDungeon()
    local ok, inside, kind = pcall(IsInInstance)
    if not ok or HHT.IsSecret(inside) or HHT.IsSecret(kind) then return false end
    return inside and (kind == "party" or kind == "raid") or false
end

-- Screenshot scene (/hht shot warnings): fixed fake entries that still show tooltips and the key, but cast nothing.
function M:ShotList()
    local db = self.db
    local list = {}
    local function R(k) return S.Resolve("@" .. k) end
    local builders = {
        aspect = function() local r = R(db.aspectMain); Add(list, "aspect", r.icon, L("Wrong aspect"), true, r.name, "") end,
        trueshot = function() local r = R("trueshotAura"); Add(list, "trueshot", r.icon, L("No Trueshot Aura"), true, r.name, "") end,
        mark = function() local r = R("hunterMark"); Add(list, "mark", r.icon, L("No Hunter's Mark"), true, r.name, "") end,
        pet = function() local r = R("revivePet"); Add(list, "pet", r.icon, L("Pet dead"), true, r.name, "") end,
        nopet = function() local r = R("callPet"); Add(list, "nopet", r.icon, L("No pet"), true, r.name, "") end,
        petlow = function() local r = R("mendPet"); Add(list, "petlow", r.icon, L("Pet low health"), true, r.name, "") end,
        petfar = function() local r = R("mendPet"); Add(list, "petfar", r.icon, L("Pet out of heal range"), true, r.name, "") end,
        growl = function()
            local r = R("growl")
            Add(list, "growl", r.icon, L("Growl on"), true, nil, "", string.format(L("Click: switch off %s autocast"), r.name), "shotNop")
        end,
        pack = function()
            local r = R("aspectPack")
            Add(list, "pack", r.icon, L("Pack in dungeon"), true, nil, "", string.format(L("Click: switch to %s"), R(db.aspectMain).name), "shotNop")
        end,
        hungry = function()
            Add(list, "hungry", R("feedPet").icon, L("Pet hungry"), true, nil, "", L("Click: feed the pet"), "shotNop", "F")
        end,
        foodlow = function()
            Add(list, "foodlow", R("feedPet").icon, L("Low pet food"), true, nil, "", string.format(L("Low on pet food: %d left."), 7), "shotNop")
        end,
    }
    for _, k in ipairs(self.shot) do
        if builders[k] then builders[k]() end
    end
    -- a distinct harmless macro per entry, so every button keeps its own tooltip
    for _, e in ipairs(list) do e.macro = "/run local _='" .. e.key .. "'" end
    return list
end

function M:Collect()
    local db = self.db
    local list = {}
    if self.shot then return self:ShotList() end
    local unlocked = HHT:IsUnlocked(self)

    if unlocked then
        Add(list, "aspect", S.Resolve("@" .. db.aspectMain).icon, L("No aspect"), true, S.Resolve("@" .. db.aspectMain).name)
        Add(list, "trueshot", S.Resolve("@trueshotAura").icon, L("No Trueshot Aura"), true, S.Resolve("@trueshotAura").name)
        Add(list, "mark", S.Resolve("@hunterMark").icon, L("No Hunter's Mark"), true, S.Resolve("@hunterMark").name)
        Add(list, "pet", S.Resolve("@callPet").icon, L("No pet"), true, S.Resolve("@callPet").name)
        Add(list, "petlow", S.Resolve("@mendPet").icon, L("Pet low health"), true, S.Resolve("@mendPet").name)
        Add(list, "growl", S.Resolve("@growl").icon, L("Growl on"), true)
        Add(list, "pack", S.Resolve("@aspectPack").icon, L("Pack in dungeon"), true)
        Add(list, "hungry", S.Resolve("@feedPet").icon, L("Pet hungry"), true)
        return list
    end

    if Quiet() then return list end
    if db.hideInCombat and HHT.InCombat() then return list end
    local inCombat = HHT.InCombat()

    -- Auras cannot be read in combat: aura based warnings only run out of combat.
    if (db.aspectWarn or db.aspectShow or db.packWarn) and not inCombat then
        self:PollAspect()
        local cur = self.currentAspect
        local packOn = false
        if db.packWarn and cur == "aspectPack" and not self.packDismissed and (not db.packInstanceOnly or InDungeon()) then
            local rep = PackReplacement(db)
            if rep then
                packOn = true
                Add(list, "pack", S.Resolve("@aspectPack").icon, L("Pack in dungeon"), true, nil, "/cast " .. rep.name,
                    string.format(L("Click: switch to %s"), rep.name), "packDismissed")
            end
        end
        if packOn or not (db.aspectWarn or db.aspectShow) then
            -- nothing: the Pack warning replaces the aspect warnings, or they are off
        elseif cur then
            local pref = S.Resolve("@" .. db.aspectMain)
            if db.aspectWarn and db.aspectWrong and cur ~= db.aspectMain and pref.known then
                Add(list, "aspect", pref.icon, L("Wrong aspect"), true, pref.name)
            elseif db.aspectShow then
                local act = S.Resolve("@" .. cur)
                Add(list, "aspect", act.icon, "", false, act.name)
            end
        elseif db.aspectWarn and not inCombat then
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

    if db.trueshotWarn and not inCombat then
        local rs = S.Resolve("@trueshotAura")
        if rs.known then
            local found = S.AuraByName("player", rs.name, "HELPFUL")
            if found == false then Add(list, "trueshot", rs.icon, L("No Trueshot Aura"), true, rs.name) end
        end
    end

    if db.markWarn and not inCombat and HHT.HasAttackableTarget() then
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

    if (db.petWarn or db.petLowWarn or db.petRangeWarn) and (UnitLevel("player") or 1) >= 10 then
        local callPet = S.Resolve("@callPet")
        if callPet.known then
            local ok, ex = pcall(UnitExists, "pet")
            local exists
            if ok and not HHT.IsSecret(ex) then exists = ex and true or false end
            local rev = S.Resolve("@revivePet")
            if exists == true then
                self.petDied = HHT.SafeBool(UnitIsDead, "pet") == true
                if self.petDied then
                    if db.petWarn then Add(list, "pet", rev.icon, L("Pet dead"), true, rev.name) end
                elseif db.petLowWarn or db.petRangeWarn then
                    local mend = S.Resolve("@mendPet")
                    local pct = mend.known and PetHealthPct()
                    if pct and pct < db.petLowPct then
                        if db.petRangeWarn and S.InRange(mend.id, "pet") == false then
                            Add(list, "petfar", mend.icon, L("Pet out of heal range"), true, mend.name)
                        elseif db.petLowWarn then
                            Add(list, "petlow", mend.icon, L("Pet low health"), true, mend.name, "/cast " .. mend.name)
                        end
                    end
                end
            elseif exists == false and db.petWarn then
                -- A dead pet can vanish as a unit: keep offering Revive Pet until a living pet is back.
                if self.petDied and rev.known then
                    Add(list, "pet", rev.icon, L("Pet dead"), true, rev.name)
                else
                    Add(list, "pet", callPet.icon, L("No pet"), true, callPet.name)
                end
            end
        end
    end

    if db.foodWarn then
        local fm = HHT.modules.feeder
        if fm and fm.enabled and fm.Status then
            local hungry, low, cur, macro, key, supply = fm:Status()
            local feedIcon = (cur and cur.icon) or S.Resolve("@feedPet").icon
            if hungry and not self.hungryDismissed then
                Add(list, "hungry", feedIcon, L("Pet hungry"), true, nil, macro ~= "" and macro or nil,
                    macro ~= "" and L("Click: feed the pet") or nil, "hungryDismissed", key)
            elseif hungry == false then
                self.hungryDismissed = false
            end
            if low and not self.foodDismissed then
                -- an empty macro keeps the click button alive for the right-click dismiss only
                Add(list, "foodlow", feedIcon, L("Low pet food"), true, nil, "",
                    string.format(L("Low on pet food: %d left."), supply or 0), "foodDismissed")
            elseif not low and supply and supply >= fm.db.supplyBelow then
                -- back above the threshold: the next drop warns again
                self.foodDismissed = false
            end
        end
    end

    if db.growlWarn and not inCombat and not InCombatLockdown() and not self.growlDismissed
        and (not db.growlInstanceOnly or InDungeon()) and (UnitLevel("player") or 1) >= 10 then
        local ok, ex = pcall(UnitExists, "pet")
        if ok and not HHT.IsSecret(ex) and ex then
            local gr = S.Resolve("@growl")
            if GrowlAutocastOn(gr.name) == true then
                Add(list, "growl", gr.icon, L("Growl on"), true, nil, "/petautocastoff " .. gr.name,
                    string.format(L("Click: switch off %s autocast"), gr.name), "growlDismissed")
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
            if self.icons[i] then
                ApplyKey(self.icons[i], db, e)
                self:ApplyClick(self.icons[i], e)
            end
        end
        return
    end
    self.sig = signature

    local s, sp = db.size, db.spacing
    f:SetSize(s, s)
    local used = 0
    local prevKeys, nowKeys = self.prevKeys, {}
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
        ApplyKey(ic, db, e)
        self:ApplyClick(ic, e)
        local per = math.max(1, db.perRow or 8)
        local along, across = ((i - 1) % per) * (s + sp), math.floor((i - 1) / per) * (s + sp)
        ic:ClearAllPoints()
        if db.grow == "right" then ic:SetPoint("TOPLEFT", f, "TOPLEFT", along, -across)
        elseif db.grow == "left" then ic:SetPoint("TOPRIGHT", f, "TOPRIGHT", -along, -across)
        elseif db.grow == "down" then ic:SetPoint("TOPLEFT", f, "TOPLEFT", across, -along)
        else ic:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", across, along) end
        ic:SetAlpha(1)
        ic:Show()
        nowKeys[e.key] = true
        if prevKeys and not prevKeys[e.key] then ic:Flash() end
        used = i
    end
    self.prevKeys = nowKeys
    for i = used + 1, #self.icons do
        local ic = self.icons[i]
        ic:SetBlink(false)
        -- A frame with a secure click button cannot be hidden in combat, so fade it instead.
        if InCombatLockdown() then ic:SetAlpha(0) else ic:Hide() end
    end

    local warns = 0
    for _, e in ipairs(list) do if e.warn then warns = warns + 1 end end
    if db.sound and warns > self.lastWarnCount and not HHT:IsUnlocked(self) then
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
    form:Stepper(L("Icons per row"), db, "perRow", 1, 8, 1)
    form:Check(L("Show text under icons"), db, "showText")
    form:Check(L("Blink warnings"), db, "blink")
    form:Check(L("Play a sound for new warnings"), db, "sound")
    form:Check(L("Hide warnings in combat"), db, "hideInCombat")
    form:Check(L("Click a warning to cast the spell"), db, "clickCast")
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
    form:Check(L("Warn when Aspect of the Pack is active"), db, "packWarn")
    form:Check(L("Only in dungeons and raids"), db, "packInstanceOnly")
    form:Header(L("Trueshot Aura"))
    form:Check(L("Warn when Trueshot Aura is missing"), db, "trueshotWarn")
    form:Header(L("Hunter's Mark"))
    form:Check(L("Warn when Hunter's Mark is missing"), db, "markWarn")
    form:Cycle(L("Hunter's Mark targets"), db, "markTargets", {
        { "elite", L("Elites and bosses only") }, { "all", L("Every enemy") } })
    form:Header(L("Pet"))
    form:Check(L("Warn when the pet is missing or dead"), db, "petWarn")
    form:Check(L("Warn when the pet's health is low"), db, "petLowWarn")
    form:Stepper(L("Low health below (%)"), db, "petLowPct", 5, 90, 5)
    form:Check(L("Warn when the hurt pet is out of Mend Pet range"), db, "petRangeWarn")
    form:Header(L("Pet food"))
    form:Check(L("Warn when the pet is hungry or pet food runs low (needs Pet feeder)"), db, "foodWarn")
    form:Header(L("Growl"))
    form:Check(L("Warn when the pet's Growl autocast is on"), db, "growlWarn")
    form:Check(L("Only in dungeons and raids"), db, "growlInstanceOnly")
    form:Header(L("Colors"))
    form:Color(L("Warning border"), db.colors, "warn")
    form:Color(L("Active border"), db.colors, "ok")
end
