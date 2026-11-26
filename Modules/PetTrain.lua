-- Pet training hint: lists ability ranks you know that your pet can learn now, and trains them per click.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Pet training hint"] = "Begleiter-Training-Hinweis",
    ["Popup when your pet can learn ability ranks you already know, with a button to train each one."] = "Hinweis, wenn dein Begleiter Fähigkeitsränge lernen kann, die du schon kennst, mit Knopf zum Trainieren.",
    ["PET TRAINING"] = "BEGLEITER-TRAINING",
    ["%s can learn new abilities"] = "Neue Fähigkeiten verfügbar",
    ["Your pet"] = "Dein Begleiter",
    ["Learn"] = "Lernen",
    ["(now rank %d)"] = "(jetzt Rang %d)",
    ["(new)"] = "(neu)",
    ["Needs pet level %d and %d training points."] = "Braucht Begleiter-Level %d und %d Trainingspunkte.",
    ["Needs pet level %d."] = "Braucht Begleiter-Level %d.",
    ["Free training points: %s"] = "Freie Trainingspunkte: %s",
    ["%s is not offered in Beast Training right now."] = "%s wird in der Tierausbildung gerade nicht angeboten.",
    ["Your pet needs level %d for %s."] = "Dein Begleiter braucht Stufe %d für %s.",
    ["Not enough training points for %s (%d needed)."] = "Nicht genug Trainingspunkte für %s (%d nötig).",
    ["Training %s failed."] = "Training von %s fehlgeschlagen.",
    ["Show for (seconds, 0 = until closed)"] = "Anzeigedauer (Sekunden, 0 = bis geschlossen)",
    ["Play a sound"] = "Ton abspielen",
    ["Show test hint"] = "Test-Hinweis zeigen",
    ["Hint border"] = "Rahmen Hinweis",
    ["Abilities switched off in the pet ability alerts are skipped here too."] = "Fähigkeiten, die bei den Fähigkeiten-Hinweisen aus sind, werden hier ebenfalls übersprungen.",
    ["Ignore"] = "Ignorieren",
    ["Abilities that trigger a hint"] = "Fähigkeiten, die einen Hinweis auslösen",
    ["%s no longer triggers a training hint. Re-enable it in the options."] = "%s löst keinen Training-Hinweis mehr aus. Du kannst es in den Optionen wieder aktivieren.",
})

local alertFor = {}
for _, a in ipairs((HHT.PetData or { abilities = {} }).abilities) do alertFor[a.key] = (a.key ~= "cower") end

local M = HHT:NewModule("pettrain", {
    name = "Pet training hint",
    desc = "Popup when your pet can learn ability ranks you already know, with a button to train each one.",
    positions = { main = { "TOP", "TOP", 0, -300 } },
    defaults = { duration = 0, sound = true, alertFor = alertFor, costs = {}, colors = { border = { 0.67, 0.83, 0.45 } } },
})

-- Costs in the data are the total points of a rank; costs read from Beast Training are a fallback.
local function CostOf(a, rank, d)
    if d and d.cost then return d.cost end
    local db = M.db
    return db and db.costs and db.costs[a.key] and db.costs[a.key][rank]
end

-- Beast Training only charges the difference to the rank the pet already has (rank 7 at 21 over rank 6 at 17 = 4).
local function NetCost(a, rank, d, have)
    local c = CostOf(a, rank, d)
    if c and d and d.cost and (have or 0) > 0 and have < rank then
        local h = a.byRank[have]
        if h and h.cost then c = math.max(c - h.cost, 0) end
    end
    return c
end

function M:LearnCosts()
    local PD = HHT.PetDex
    if not PD or not PD.CraftIsBeast() then return end
    local keys = PD.NameKeys()
    self.db.costs = self.db.costs or {}
    for i = 1, (GetNumCrafts() or 0) do
        local name, sub, kind, _, _, cost = GetCraftInfo(i)
        local key = type(name) == "string" and kind ~= "header" and keys[PD.Fold(name)]
        cost = tonumber(cost)
        if key and cost and cost > 0 then
            local t = self.db.costs[key] or {}
            self.db.costs[key] = t
            t[PD.RankFrom(sub) or 1] = cost
        end
    end
end

local W, ROW_H, MAXROWS = 440, 30, 5
local ROW_TOP = 82
local lastSig, tries, dueAt
local lastClick = 0
local craftOpen, pending = false, nil

local StyleButton = UI.StyleButton

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsPetTrain", UIParent)
    f:SetSize(W, 80)
    f:SetFrameStrata("DIALOG")
    self.frame = f
    f.border = UI.Panel(f, 0.67, 0.83, 0.45)
    UI.PopupHead(f, W, { icon = true, divY = 70, subLines = 1, onClose = function() HHT.HideSecure(f) end })
    HHT.Icon.Attach(f.icon, true)
    f.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTraining")
    f.sub:Hide()
    f.eyebrow:SetTextColor(0.67, 0.83, 0.45)

    f.rows = {}
    for i = 1, MAXROWS do
        local r = CreateFrame("Frame", nil, f)
        r:SetSize(W - 32, ROW_H)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -(ROW_TOP + (i - 1) * ROW_H))
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(22, 22)
        r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        HHT.Icon.Attach(r.icon, "shape")
        r.text = UI.Text(r, "", 12, 1, 1, 1)
        r.text:SetPoint("LEFT", r.icon, "RIGHT", 10, 0)
        r.text:SetJustifyH("LEFT")
        r.text:SetWordWrap(false)
        r:EnableMouse(true)
        r:SetScript("OnEnter", function(self) M:RowTip(self) end)
        r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        r.ignore = UI.Button(r, 60, 24, L("Ignore"), function()
            local it = r.item
            if not it or f.preview then return end
            M.db.alertFor[it.a.key] = false
            HHT.Print(string.format(L("%s no longer triggers a training hint. Re-enable it in the options."), HHT.PetDex.AbilityName(it.a)))
            M:Check()
        end)
        r.ignore:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        r.btn = CreateFrame("Button", nil, r, "SecureActionButtonTemplate")
        r.btn:SetSize(74, 24)
        r.btn:SetPoint("RIGHT", r.ignore, "LEFT", -8, 0)
        r.btn:RegisterForClicks("AnyDown", "AnyUp")
        StyleButton(r.btn, L("Learn"))
        UI.SetPrimary(r.btn, 0.67, 0.83, 0.45)
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

-- Tooltip of a row: the game's spell text (when it can show it) plus level, cost and the pet's free training points.
function M:RowTip(row)
    local it = row.item
    if not it or not GameTooltip then return end
    local PD = HHT.PetDex
    local d = it.a.byRank[it.rank]
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    local shown = false
    if d and d.spell and GameTooltip.SetSpellByID then shown = pcall(GameTooltip.SetSpellByID, GameTooltip, d.spell) end
    if not shown then
        GameTooltip:ClearLines()
        GameTooltip:AddLine(string.format("%s %d", PD.AbilityName(it.a), it.rank), 0.67, 0.83, 0.45)
    end
    if d then
        GameTooltip:AddLine(" ")
        local cost = NetCost(it.a, it.rank, d, it.have)
        -- Pet trainer abilities have no cost in the data until Beast Training has been opened once.
        if cost then
            GameTooltip:AddLine(string.format(L("Needs pet level %d and %d training points."), d.level or 0, cost), 1, 1, 1)
        else
            GameTooltip:AddLine(string.format(L("Needs pet level %d."), d.level or 0), 1, 1, 1)
        end
    end
    local info = PD.PetInfo()
    if info and info.points then
        local enough = not d or (NetCost(it.a, it.rank, d, it.have) or 0) <= info.points
        GameTooltip:AddLine(string.format(L("Free training points: %s"), tostring(info.points)), enough and 0.45 or 0.95, enough and 0.9 or 0.85, enough and 0.45 or 0.3)
    end
    GameTooltip:Show()
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
            r.textW = r.text:GetStringWidth()
            r:Show()
        else
            r.item = nil
            r:Hide()
        end
    end
    -- Width follows the widest row (icon + text + two buttons) or the title, whichever is wider.
    f.title:SetWidth(2000)
    local w = f.title:GetStringWidth() + f.x0 + 44
    for i = 1, n do w = math.max(w, 32 + 22 + 10 + f.rows[i].textW + 16 + 74 + 8 + 60) end
    w = math.max(300, math.ceil(w))
    f:SetWidth(w)
    f.title:SetWidth(w - f.x0 - 40)
    for i = 1, n do
        local r = f.rows[i]
        r:SetWidth(w - 32)
        r.text:SetWidth(r.textW + 2)
    end
    f:SetHeight(ROW_TOP + n * ROW_H + 12)
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
    local points = info.points
    local cand = PD.FamilyAbilities(info.family)
    for _, a in ipairs(PD.trainerAbilities) do cand[#cand + 1] = a end
    for _, a in ipairs(cand) do
        local have, want = book[a.key] or 0, nil
        if off[a.key] ~= false then
            for r = PD.KnownRank(a.key), 1, -1 do
                local d = a.byRank[r]
                -- a rank the pet cannot pay for with its free training points is not offered
                -- unknown cost (trainer ability, Beast Training not opened yet) cannot be proven affordable
                local c = NetCost(a, r, d, have)
                if d and (d.level or 0) <= info.level and (not points or (c and c <= points)) then want = r; break end
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
    if not f or HHT:IsUnlocked(self) or InCombatLockdown() or HHT.InCombat() then return end
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
    if self.db.sound then HHT.PlayAlert() end
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
    if craftOpen then
        self:LearnCosts()
        C_Timer.After(0.6, function() if craftOpen then M:LearnCosts() end end)
        self:Queue(0.5)
    end
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
    if unit == "player" or unit == "pet" then loyMax, lastState = false, nil; self:Queue(1.5) end
end

function M:OnSpells()
    loyMax, lastState = false, nil
    HHT.FlushHidden(self.frame)
    self:Queue(1.5)
end

function M:OnCombat()
    local f = self.frame
    if f and f:IsShown() and not f.preview then HHT.HideSecure(f); lastSig = nil end
end

-- Free training points or loyalty changed: look again (level-ups are covered by UNIT_LEVEL).
-- At max loyalty (6) only a level-up can change the points, so the polling stops until the pet changes.
local lastState, stateAt, loyMax = nil, 0, false
local function StateSig()
    local PD = HHT.PetDex
    local info = PD and PD.PetInfo()
    if not info then return nil end
    local loy = HHT.PetCall and HHT.PetCall("GetPetLoyalty")
    local level
    if type(loy) == "string" and not HHT.IsSecret(loy) then level = tonumber(loy:match("(%d+)")) end
    return tostring(info.points) .. ":" .. tostring(level or "?"), level and level >= 6
end

function M:Tick()
    local f = self.frame
    if dueAt and GetTime() >= dueAt then self:Check() end
    if not loyMax and GetTime() - stateAt > 2 then
        stateAt = GetTime()
        local sig, atMax = StateSig()
        if sig and lastState and sig ~= lastState then self:Queue(0.5) end
        lastState, loyMax = sig, atMax or false
    end
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
    if HHT:IsUnlocked(self) then self:Preview() elseif f.preview then f.preview = nil; HHT.HideSecure(f) end
end

function M:OnLockChanged() self:Refresh() end

-- /hht trainpoints [N|off]: shows the pet's training points; with a number it pretends the pet has that many (until /reload).
function M:TestPoints(arg)
    local PD = HHT.PetDex
    if not PD then return end
    if arg == "off" or arg == "reset" then
        PD.testPoints = nil
    elseif arg ~= "" then
        local n = tonumber(arg)
        if not n then HHT.Print("PetTrain: use /hht trainpoints, /hht trainpoints <number> or /hht trainpoints off"); return end
        PD.testPoints = math.floor(n)
    end
    local info = PD.PetInfo()
    if not info then HHT.Print("PetTrain: no pet out."); return end
    HHT.Print(string.format("PetTrain: %s level %s, real free points: %s%s", tostring(info.name), tostring(info.level),
        tostring(info.realPoints), PD.testPoints and (", TEST value: " .. PD.testPoints .. " (/hht trainpoints off to end)") or ""))
    lastSig, lastState = nil, nil
    self:Queue(0)
end

-- /hht train: forget what was shown and look again.
function M:Recheck()
    lastSig = nil
    self:Queue(0)
    local PD = HHT.PetDex
    if not PD then return end
    local info = PD.PetInfo()
    HHT.Print(string.format("PetTrain: pet=%s family=%s level=%s points=%s bookEntries=%d", tostring(info and info.name),
        tostring(info and info.family), tostring(info and info.level), tostring(info and info.points), PD.PetBookCount()))
    HHT.Print("PetTrain: craft " .. CraftInfo() .. " isBeast=" .. tostring(PD.CraftIsBeast()) .. " scan=" .. tostring(PD.ScanCraft()))
    for i = 1, math.min(GetNumCrafts and GetNumCrafts() or 0, 8) do
        local name, sub, kind, _, _, cost, req = GetCraftInfo(i)
        HHT.Print(string.format("  craft %d: %s | %s | %s | cost=%s req=%s", i, tostring(name), tostring(sub), tostring(kind), tostring(cost), tostring(req)))
    end
    PD.ScanSpells()
    local book = PD.ScanBook()
    for _, a in ipairs(PD.trainerAbilities) do
        local known = HHT.PetDex.KnownRank(a.key)
        HHT.Print(string.format("PetTrain: %s known=%d petRank=%d alert=%s", a.name, known, book[a.key] or 0, tostring(self.db.alertFor[a.key])))
    end
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
        for _, a in ipairs(PD.abilities) do
            form:Check(PD.AbilityName(a), db.alertFor, a.key)
            form:Group("Ability list")
        end
        for _, a in ipairs(PD.trainerAbilities) do
            if db.alertFor[a.key] == nil then db.alertFor[a.key] = true end
            form:Check(PD.AbilityName(a), db.alertFor, a.key)
            form:Group("Ability list")
        end
    end
end
