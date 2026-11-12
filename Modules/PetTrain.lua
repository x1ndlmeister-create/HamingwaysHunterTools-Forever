-- Pet training hint: lists ability ranks you know that your pet can learn now, and trains them per click.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Pet training hint"] = "Begleiter-Training-Hinweis",
    ["Popup when your pet can learn ability ranks you already know, with a button to train each one."] = "Hinweis, wenn dein Begleiter Faehigkeitsraenge lernen kann, die du schon kennst, mit Knopf zum Trainieren.",
    ["PET TRAINING"] = "BEGLEITER-TRAINING",
    ["%s can learn new abilities"] = "%s kann neue Faehigkeiten lernen",
    ["Your pet"] = "Dein Begleiter",
    ["Learn"] = "Lernen",
    ["(now rank %d)"] = "(jetzt Rang %d)",
    ["(new)"] = "(neu)",
    ["%s is not offered in Beast Training right now."] = "%s wird in der Tierausbildung gerade nicht angeboten.",
    ["Your pet needs level %d for %s."] = "Dein Begleiter braucht Stufe %d fuer %s.",
    ["Not enough training points for %s (%d needed)."] = "Nicht genug Trainingspunkte fuer %s (%d noetig).",
    ["Training %s failed."] = "Training von %s fehlgeschlagen.",
    ["Show for (seconds, 0 = until closed)"] = "Anzeigedauer (Sekunden, 0 = bis geschlossen)",
    ["Play a sound"] = "Ton abspielen",
    ["Show test hint"] = "Test-Hinweis zeigen",
    ["Hint border"] = "Rahmen Hinweis",
    ["Abilities switched off in the pet ability alerts are skipped here too."] = "Faehigkeiten, die bei den Faehigkeiten-Hinweisen aus sind, werden hier ebenfalls uebersprungen.",
    ["Ignore"] = "Ignorieren",
    ["Abilities that trigger a hint"] = "Faehigkeiten, die einen Hinweis ausloesen",
    ["%s no longer triggers a training hint. Re-enable it in the options."] = "%s loest keinen Training-Hinweis mehr aus. Du kannst es in den Optionen wieder aktivieren.",
})

local alertFor = {}
for _, a in ipairs((HHT.PetData or { abilities = {} }).abilities) do alertFor[a.key] = (a.key ~= "cower") end

local M = HHT:NewModule("pettrain", {
    name = "Pet training hint",
    desc = "Popup when your pet can learn ability ranks you already know, with a button to train each one.",
    positions = { main = { "TOP", "TOP", 0, -300 } },
    defaults = { duration = 0, sound = true, alertFor = alertFor, colors = { border = { 0.67, 0.83, 0.45 } } },
})

local W, ROW_H, MAXROWS = 380, 26, 5
local lastSig, tries, dueAt
local lastClick = 0
local craftOpen, pending = false, nil

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
    local f = CreateFrame("Frame", "HamingwaysHunterToolsPetTrain", UIParent)
    f:SetSize(W, 80)
    f:SetFrameStrata("DIALOG")
    self.frame = f
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.075, 0.068, 0.055, 0.96)
    f.border = UI.Border(f, 0.67, 0.83, 0.45, 0.9)

    f.eyebrow = UI.Text(f, "", 10, 0.67, 0.83, 0.45)
    f.eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
    f.title = UI.Text(f, "", 13, 1, 1, 1)
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -22)
    f.title:SetWidth(W - 40)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)

    local close = UI.Button(f, 18, 18, "x", function() HHT.HideSecure(f) end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    f.rows = {}
    for i = 1, MAXROWS do
        local r = CreateFrame("Frame", nil, f)
        r:SetSize(W - 20, ROW_H)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -(44 + (i - 1) * ROW_H))
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(20, 20)
        r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        r.text = UI.Text(r, "", 11, 1, 1, 1)
        r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.text:SetWidth(W - 190)
        r.text:SetJustifyH("LEFT")
        r.text:SetWordWrap(false)
        r.ignore = UI.Button(r, 56, 20, L("Ignore"), function()
            local it = r.item
            if not it or f.preview then return end
            M.db.alertFor[it.a.key] = false
            HHT.Print(string.format(L("%s no longer triggers a training hint. Re-enable it in the options."), HHT.PetDex.AbilityName(it.a)))
            M:Check()
        end)
        r.ignore:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        r.btn = CreateFrame("Button", nil, r, "SecureActionButtonTemplate")
        r.btn:SetSize(70, 20)
        r.btn:SetPoint("RIGHT", r.ignore, "LEFT", -4, 0)
        r.btn:RegisterForClicks("AnyDown", "AnyUp")
        StyleButton(r.btn, L("Learn"))
        r.btn:HookScript("PostClick", function()
            local now = GetTime()
            if now - lastClick < 0.4 then return end
            lastClick = now
            M:OnLearn(r)
        end)
        r:Hide()
        f.rows[i] = r
    end

    f:Hide()
    HHT:MakeMovable(f, self, "main", L("Pet training hint"))
end

-- The first click opens Beast Training through the secure button; once it is open the click trains.
function M:SetButtons()
    local f = self.frame
    if not f or InCombatLockdown() then return end
    local PD = HHT.PetDex
    local spell = (PD and PD.SpellName(5149)) or "Beast Training"
    for _, r in ipairs(f.rows) do
        if craftOpen or f.preview then
            r.btn:SetAttribute("type", nil)
        else
            r.btn:SetAttribute("type", "macro")
            r.btn:SetAttribute("macrotext", "/cast " .. spell)
        end
    end
end

function M:Fill(list, preview)
    local f = self.frame
    local PD = HHT.PetDex
    f.preview = preview
    f.eyebrow:SetText(L("PET TRAINING"))
    f.title:SetText(string.format(L("%s can learn new abilities"), list.petName or L("Your pet")))
    local n = math.min(#list, MAXROWS)
    for i = 1, MAXROWS do
        local r, it = f.rows[i], list[i]
        if it and i <= n then
            r.item = it
            r.icon:SetTexture(PD.AbilityIcon(it.a))
            local suffix = it.have > 0 and string.format(L("(now rank %d)"), it.have) or L("(new)")
            r.text:SetText(string.format("%s %d  |cff999999%s|r", PD.AbilityName(it.a), it.rank, suffix))
            r:Show()
        else
            r.item = nil
            r:Hide()
        end
    end
    f:SetHeight(44 + n * ROW_H + 8)
end

function M:ShowList(list, preview)
    local f = self.frame
    if not f or InCombatLockdown() then return end
    self:Fill(list, preview)
    self:SetButtons()
    f.hideAt = (not preview and self.db.duration > 0) and (GetTime() + self.db.duration) or nil
    HHT.ShowSecure(f)
end

-- Returns list, wait. wait = the pet is out but its spellbook is not readable yet.
function M:Missing()
    local PD = HHT.PetDex
    if not PD or not PD.module.enabled then return nil end
    local info = PD.PetInfo()
    if not (info and info.family and info.level) then return nil end
    if PD.PetBookCount() == 0 then return nil, true end
    PD.ScanSpells()
    local book = PD.ScanBook()
    local off = self.db.alertFor
    local list = { petName = info.name }
    for _, a in ipairs(PD.FamilyAbilities(info.family)) do
        local have, want = book[a.key] or 0, nil
        if off[a.key] ~= false then
            for r = PD.KnownRank(a.key), 1, -1 do
                local d = a.byRank[r]
                if d and (d.level or 0) <= info.level then want = r; break end
            end
            if want and want > have then list[#list + 1] = { a = a, rank = want, have = have } end
        end
    end
    return list
end

function M:Queue(delay)
    dueAt = GetTime() + (delay or 1)
    tries = 0
end

function M:Check()
    dueAt = nil
    local f = self.frame
    if not f or HHT:IsUnlocked() or InCombatLockdown() or HHT.InCombat() then return end
    local list, wait = self:Missing()
    if wait then
        if (tries or 0) < 6 then tries = (tries or 0) + 1; dueAt = GetTime() + 1.5 end
        return
    end
    if not list or #list == 0 then
        lastSig = nil
        if f:IsShown() and not f.preview then f:Hide() end
        return
    end
    local parts = { list.petName or "?" }
    for _, it in ipairs(list) do parts[#parts + 1] = it.a.key .. it.rank end
    local sig = table.concat(parts, ",")
    if sig == lastSig then
        if f:IsShown() then self:ShowList(list) end
        return
    end
    lastSig = sig
    self:ShowList(list)
    if self.db.sound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959) end
end

local function CraftInfo()
    local line = GetCraftDisplaySkillLine and GetCraftDisplaySkillLine()
    if HHT.IsSecret(line) then line = "?" end
    return string.format("skillLine=%s crafts=%s frame=%s", tostring(line), tostring(GetNumCrafts and GetNumCrafts()),
        tostring(CraftFrame and CraftFrame:IsShown()))
end

function M:Train(it)
    local PD = HHT.PetDex
    if not it or not PD then return end
    if InCombatLockdown() then HHT.Print("PetTrain: in combat"); return end
    if not PD.CraftIsBeast() then HHT.Print("PetTrain: the open window is not Beast Training (" .. CraftInfo() .. ")"); return end
    local keys = PD.NameKeys()
    local best
    for i = 1, (GetNumCrafts() or 0) do
        local name, sub, kind, _, _, cost, req = GetCraftInfo(i)
        if type(name) == "string" and kind ~= "header" and keys[PD.Fold(name)] == it.a.key then
            local rank = PD.RankFrom(sub) or 1
            if rank <= it.rank and rank > it.have and (not best or rank > best.rank) then
                best = { i = i, rank = rank, cost = tonumber(cost) or 0, req = tonumber(req) or 0 }
            end
        end
    end
    local name = PD.AbilityName(it.a)
    if not best then
        HHT.Print(string.format(L("%s is not offered in Beast Training right now."), name) .. " (" .. CraftInfo() .. ")")
        return
    end
    local info = PD.PetInfo()
    if info and info.level and best.req > info.level then
        HHT.Print(string.format(L("Your pet needs level %d for %s."), best.req, name))
        return
    end
    if info and info.points and best.cost > info.points then
        HHT.Print(string.format(L("Not enough training points for %s (%d needed)."), name, best.cost))
        return
    end
    local ok = pcall(DoCraft, best.i)
    if not ok then HHT.Print(string.format(L("Training %s failed."), name)) end
    self:Queue(2)
end

function M:OnLearn(r)
    local f = self.frame
    if not r.item or (f and f.preview) or InCombatLockdown() then return end
    if craftOpen or (CraftFrame and CraftFrame:IsShown() and HHT.PetDex and HHT.PetDex.CraftIsBeast()) then
        craftOpen = true
        self:Train(r.item)
    else
        local p = { item = r.item, t = GetTime() }
        pending = p
        C_Timer.After(3, function()
            if pending == p then
                pending = nil
                HHT.Print("PetTrain: Beast Training did not open. Open it by hand (spellbook), then click Learn.")
            end
        end)
    end
end

function M:OnCraftShow()
    local PD = HHT.PetDex
    craftOpen = PD and PD.CraftIsBeast() or false
    self:SetButtons()
    if not craftOpen and pending then HHT.Print("PetTrain: craft window opened but is not Beast Training (" .. CraftInfo() .. ")") end
    if craftOpen and pending and GetTime() - pending.t < 5 then
        local p = pending
        pending = nil
        C_Timer.After(0.2, function() M:Train(p.item) end)
    end
end

function M:OnCraftClose()
    craftOpen, pending = false, nil
    self:SetButtons()
end

function M:OnPetEvent(_, unit)
    if unit == "player" or unit == "pet" then self:Queue(1.5) end
end

function M:OnSpells()
    HHT.FlushHidden(self.frame)
    self:Queue(1.5)
end

function M:OnCombat()
    local f = self.frame
    if f and f:IsShown() and not f.preview then HHT.HideSecure(f); lastSig = nil end
end

function M:Tick()
    local f = self.frame
    if dueAt and GetTime() >= dueAt then self:Check() end
    if f and f:IsShown() and f.hideAt and not f.preview and GetTime() > f.hideAt then HHT.HideSecure(f); f.hideAt = nil end
end

function M:Preview()
    local PD = HHT.PetDex
    local a = PD and (PD.byKey.bite or PD.abilities[1])
    if not a then return end
    self:ShowList({ petName = L("Your pet"), { a = a, rank = a.maxRank, have = math.max(0, a.maxRank - 1) } }, true)
end

function M:Test()
    if not self.frame then return false end
    self:Preview()
    self.frame.preview = nil
    self:SetButtons()
    self.frame.hideAt = GetTime() + 8
    return true
end

function M:OnInit()
    HHT:Listen(self, "UNIT_PET", "OnPetEvent")
    HHT:Listen(self, "UNIT_LEVEL", "OnPetEvent")
    HHT:Listen(self, "SPELLS_CHANGED", "OnSpells")
    HHT:Listen(self, "LEARNED_SPELL_IN_TAB", "OnSpells")
    HHT:Listen(self, "PLAYER_ENTERING_WORLD", "OnSpells")
    HHT:Listen(self, "PLAYER_REGEN_ENABLED", "OnSpells")
    HHT:Listen(self, "PLAYER_REGEN_DISABLED", "OnCombat")
    HHT:Listen(self, "CRAFT_SHOW", "OnCraftShow")
    HHT:Listen(self, "CRAFT_CLOSE", "OnCraftClose")
    HHT:Every(self, 0.5, M.Tick)
end

function M:OnEnable()
    self:Build()
    self:Refresh()
    self:Queue(3)
end

function M:OnDisable()
    if self.frame and not InCombatLockdown() then self.frame:Hide() end
end

function M:Refresh()
    local f = self.frame
    if not f then return end
    local c = self.db.colors.border
    f.border:SetColor(c[1], c[2], c[3], 0.9)
    HHT:ApplyGlobalLook(f)
    if HHT:IsUnlocked() then self:Preview() elseif f.preview then f.preview = nil; if not InCombatLockdown() then f:Hide() end end
end

function M:OnLockChanged() self:Refresh() end

-- /hht train: forget what was shown and look again.
function M:Recheck()
    lastSig = nil
    self:Queue(0)
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Behavior"))
    form:Stepper(L("Show for (seconds, 0 = until closed)"), db, "duration", 0, 120, 5)
    form:Check(L("Play a sound"), db, "sound")
    form:Button(L("Show test hint"), function()
        if M.frame then M:Preview(); M.frame.preview = nil; M:SetButtons(); M.frame.hideAt = GetTime() + 8 end
    end, 220)
    form:Header(L("Colors"))
    form:Color(L("Hint border"), db.colors, "border", function() M:Refresh() end)
    form:Header(L("Abilities that trigger a hint"))
    local PD = HHT.PetDex
    if PD then
        for _, a in ipairs(PD.abilities) do form:Check(PD.AbilityName(a), db.alertFor, a.key) end
    end
end
