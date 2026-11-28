-- Pet feeder: click to feed your pet with a chosen food. Per-pet food choice and blacklist, optional macro sync.
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Pet feeder"] = "Begleiter-Futter",
    ["Click to feed your pet. Per-pet food choice and blacklist."] = "Klick zum Füttern. Futterwahl und Blacklist pro Begleiter.",
    ["Choose food"] = "Futter wählen",
    ["Clear blacklist (this pet)"] = "Blacklist leeren (dieser Begleiter)",
    ["Clear all blacklists"] = "Alle Blacklists leeren",
    ["Keep the HHT Feed macro up to date"] = "HHT-Feed-Makro aktuell halten",
    ["Click: feed. Right-click: choose food. Shift+click in the menu: blacklist or allow a food."] = "Klick: füttern. Rechtsklick: Futter wählen. Umschalt+Klick im Menü: Futter sperren oder erlauben.",
    ["Show food icons"] = "Futter-Symbole zeigen",
    ["Always (with pet)"] = "Immer (mit Begleiter)",
    ["Only when not happy"] = "Nur wenn nicht glücklich",
    ["Show food name"] = "Futternamen zeigen",
    ["No food"] = "Kein Futter",
    ["Feed"] = "Füttern",
    ["Choose food (Shift+click: blacklist)"] = "Futter wählen (Umschalt+Klick: sperren)",
    ["Blacklisted"] = "Gesperrt",
    ["Blacklisted food:"] = "Gesperrtes Futter:",
    ["Happy color"] = "Farbe glücklich",
    ["Content color"] = "Farbe zufrieden",
    ["Unhappy color"] = "Farbe unzufrieden",
    ["Neutral color"] = "Farbe neutral",
    ["Blacklist cleared."] = "Blacklist geleert.",
    ["Selected food: %s"] = "Gewähltes Futter: %s",
    ["Food blacklisted: %s"] = "Futter gesperrt: %s",
    ["Food allowed: %s"] = "Futter erlaubt: %s",
    ["Food is blacklisted (Shift+click to allow): %s"] = "Futter ist gesperrt (Umschalt+Klick zum Erlauben): %s",
    ["Feed key: %s"] = "Fütter-Taste: %s",
    ["not set"] = "nicht gesetzt",
    ["Clear key"] = "Taste entfernen",
    ["The key replaces its normal function while it is set. Changes apply after combat."] = "Die Taste ersetzt ihre normale Funktion, solange sie gesetzt ist. Änderungen gelten nach dem Kampf.",
    ["Warn when the pet gets unhappy"] = "Warnen wenn der Begleiter unzufrieden wird",
    ["Play a sound when the pet gets unhappy"] = "Ton wenn der Begleiter unzufrieden wird",
    ["Warn when pet food runs low"] = "Warnen wenn das Begleiter-Futter knapp wird",
    ["Low food below"] = "Wenig Futter unter",
    ["Never pick buff food automatically"] = "Buff-Futter nie automatisch wählen",
    ["Your pet is unhappy: time to feed it."] = "Dein Begleiter ist unzufrieden: Zeit zum Füttern.",
    ["Your pet is only content: feed it for full damage."] = "Dein Begleiter ist nur zufrieden: füttere ihn für vollen Schaden.",
    ["Also warn when the pet is only content (not green)"] = "Auch warnen wenn der Begleiter nur zufrieden ist (nicht grün)",
    ["Low on pet food: %d left."] = "Wenig Begleiter-Futter: noch %d.",
    ["Buff food"] = "Buff-Futter",
    ["Learned pet food: %s"] = "Neues Begleiter-Futter gelernt: %s",
    ["Shift+click the icon: scan your bags for food your pet accepts."] = "Umschalt+Klick auf das Symbol: Taschen nach Futter durchsuchen, das dein Begleiter frisst.",
    ["Could not start Feed Pet. Is your pet out and not busy?"] = "Füttern konnte nicht gestartet werden. Ist dein Begleiter draußen und nicht beschäftigt?",
    ["Food scan needs the default bags (bag addons like Baganator cannot be read)."] = "Der Futter-Scan braucht die Standard-Taschen (Taschen-Addons wie Baganator sind nicht lesbar).",
    ["Food scan: nothing new found."] = "Futter-Scan: nichts Neues gefunden.",
    ["Press Esc to cancel the Feed Pet cursor."] = "Esc drücken, um den Füttern-Cursor abzubrechen.",
    ["Food scan does not work in combat."] = "Der Futter-Scan geht nicht im Kampf.",
})

local M = HHT:NewModule("feeder", {
    name = "Pet feeder",
    desc = "Click to feed your pet. Per-pet food choice and blacklist.",
    positions = { main = { "CENTER", "CENTER", -260, -205 } },
    defaults = {
        size = 36, shape = "round", borderSize = 2, borderAlpha = 1,
        showText = true, showName = false, mode = "always", key = "",
        hungerWarn = true, hungerContent = true, hungerSound = false, supplyWarn = true, supplyBelow = 10, protectBuff = true,
        selected = {}, blacklist = {},
        learned = {}, learnedSet = {},
        colors = {
            happy = { 0.40, 0.80, 0.30 },
            content = { 0.95, 0.60, 0.15 },
            unhappy = { 0.90, 0.20, 0.20 },
            neutral = { 0.55, 0.42, 0.20 },
        },
    },
})

-- Item ids by diet (classic food database).
local FOODS = {
    fungus = { 4607, 8948, 4604, 4608, 4605, 3448, 4606 },
    fish = { 13889, 19996, 13933, 13888, 13935, 13546, 6290, 4593, 5503, 16971, 2682, 13927, 2675, 13930, 5476, 4655, 6038, 13928, 13929, 13893, 4592, 8364, 13932, 5095, 6291, 6308, 13754, 6317, 6289, 8365, 6361, 13758, 6362, 6303, 8959, 4603, 13756, 13760, 4594, 787, 5468, 15924, 12216, 8957, 6887, 5504, 12206, 13755, 7974, 6299 },
    meat = { 21235, 19995, 4457, 3173, 2888, 3730, 3726, 3220, 2677, 3404, 12213, 2679, 769, 2673, 2684, 1081, 12224, 5479, 2924, 3662, 4599, 17119, 5478, 5051, 12217, 2687, 9681, 2287, 12204, 3727, 13851, 12212, 5472, 5467, 5480, 1015, 12209, 3731, 12223, 3770, 12037, 4739, 12184, 13759, 12203, 12210, 2681, 5474, 8952, 1017, 5465, 6890, 3712, 3729, 2680, 17222, 5471, 5469, 5477, 2672, 2685, 3728, 3667, 12208, 18045, 5470, 12202, 117, 12205, 3771, 252022 },
    bread = { 1113, 5349, 1487, 1114, 8075, 8076, 22895, 19696, 21254, 2683, 4541, 17197, 3666, 8950, 4542, 4544, 4601, 4540, 16169 },
    cheese = { 8932, 414, 2070, 422, 3927, 1707 },
    fruit = { 19994, 8953, 4539, 16168, 4602, 4536, 4538, 4537, 11950 },
}

local ITEM_DIET = {}
for diet, ids in pairs(FOODS) do
    for _, id in ipairs(ids) do ITEM_DIET[id] = diet end
end

-- Fallback list of cooked dishes with a Well Fed style buff, used while an item tooltip is not loaded yet.
local BUFF_FOOD = {}
for _, id in ipairs({ 6887, 8953, 12209, 12210, 12212, 12213, 12215, 12216, 12217, 12218, 13851, 13927, 13928, 13929, 13930, 13932, 13933, 13935, 18045 }) do
    BUFF_FOOD[id] = true
end

-- English and German diet names as returned by the client.
local ALIAS = {
    meat = "meat", fish = "fish", fungus = "fungus", mushroom = "fungus", bread = "bread", cheese = "cheese", fruit = "fruit",
    fleisch = "meat", fisch = "fish", pilz = "fungus", pilze = "fungus", brot = "bread", obst = "fruit",
    kaese = "cheese", ["k\195\164se"] = "cheese",
}

local function NormDiet(name)
    name = name:lower():gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("^raw ", ""):gsub("^roh%a* ", "")
    return ALIAS[name]
end

local function AddDiets(set, ...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) == "table" then
            for _, x in pairs(v) do
                if type(x) == "string" and not HHT.IsSecret(x) then
                    local d = NormDiet(x)
                    if d then set[d] = true end
                end
            end
        elseif type(v) == "string" and not HHT.IsSecret(v) then
            local d = NormDiet(v)
            if d then set[d] = true end
        end
    end
end

-- Last resort when the client reports no diet: the family table of the addon.
local function FamilyDiets(set)
    local pd = HHT.PetDex
    local okF, raw = pcall(UnitCreatureFamily, "pet")
    if not (pd and pd.EnglishFamily and okF and type(raw) == "string" and not HHT.IsSecret(raw)) then return end
    local fam = pd.EnglishFamily(raw)
    for _, e in ipairs(HHT.PetFamilyData or {}) do
        if e.n == fam then AddDiets(set, e.diet) return end
    end
end

local function PetDiets()
    local set = {}
    if GetPetFoodTypes then pcall(function() AddDiets(set, GetPetFoodTypes()) end) end
    if not next(set) and C_PetInfo and C_PetInfo.GetPetFoodTypes then
        pcall(function() AddDiets(set, C_PetInfo.GetPetFoodTypes()) end)
    end
    if not next(set) then pcall(FamilyDiets, set) end
    return set
end

-- Stable key of a diet set, e.g. "fish,meat".
local function DietKey(diets)
    local t = {}
    for d in pairs(diets) do t[#t + 1] = d end
    table.sort(t)
    return table.concat(t, ",")
end

-- Shared with the food vendor module.
HHT.PetFood = { ItemDiet = ITEM_DIET, PetDiets = PetDiets }

local function ItemName(id, link)
    if C_Item and C_Item.GetItemNameByID then
        local ok, n = pcall(C_Item.GetItemNameByID, id)
        if ok and type(n) == "string" then return n end
    end
    if GetItemInfo then
        local ok, n = pcall(GetItemInfo, id)
        if ok and type(n) == "string" then return n end
    end
    if type(link) == "string" then return link:match("%[(.-)%]") end
end

local function ItemIcon(id, fallback)
    if C_Item and C_Item.GetItemIconByID then
        local ok, t = pcall(C_Item.GetItemIconByID, id)
        if ok and t then return t end
    end
    return fallback
end

function M:OnInit()
    self.foods = {}
    self.dirty = true
    self.signature = false
    self.attrText = false
    self.macroId = false
    self.petKey = "default"
    self.startAt = GetTime()
    for id, diet in pairs(self.db.learned) do ITEM_DIET[id] = diet end
    HHT:Every(self, 0.25, M.LearnTick)
    HHT:Listen(self, "BAG_UPDATE_DELAYED", "MarkDirty")
    HHT:Listen(self, "UNIT_PET", "MarkDirty")
    HHT:Listen(self, "PLAYER_ENTERING_WORLD", "MarkDirty")
    HHT:Listen(self, "SPELLS_CHANGED", "MarkDirty")
    HHT:Listen(self, "PLAYER_REGEN_ENABLED", "MarkDirty")
    HHT:Every(self, 0.25, M.Tick)
    self.owner = CreateFrame("Frame")
    self.bindDirty = true
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:SetScript("OnEvent", function() if M.bindDirty then M:ApplyBinding() end end)
end

function M:ApplyBinding()
    if InCombatLockdown() then self.bindDirty = true; return end
    if not (ClearOverrideBindings and SetOverrideBindingClick) then return end
    self.bindDirty = false
    ClearOverrideBindings(self.owner)
    if self.enabled and self.db.key ~= "" then
        HHT.BindClick(self.owner, self.db.key, "HamingwaysHunterToolsFeederButton")
    end
end

function M:MarkDirty()
    self.dirty = true
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsFeeder", UIParent)
    f:SetSize(36, 36)
    self.frame = f
    f.icon = Icon.New(f)
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    local b = CreateFrame("Button", "HamingwaysHunterToolsFeederButton", f, "SecureActionButtonTemplate")
    b:SetAllPoints(f.icon)
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("useOnKeyDown", false)
    b:SetAttribute("type1", "macro")
    b:SetAttribute("macrotext1", "")
    b:HookScript("PostClick", function(_, button)
        if button == "RightButton" then M:OpenMenu(b)
        elseif button == "LeftButton" and IsShiftKeyDown() then M:ScanBags() end
    end)
    b:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L("Pet feeder"))
        local cur = M.current
        GameTooltip:AddLine(cur and cur.name or L("No food"), 1, 1, 1)
        GameTooltip:AddLine(L("Click: feed. Right-click: choose food. Shift+click in the menu: blacklist or allow a food."), 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine(L("Shift+click the icon: scan your bags for food your pet accepts."), 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.button = b

    HHT:MakeMovable(f, self, "main", L("Pet feeder"))
    self:Layout()
end

function M:OnEnable()
    self:Build()
    self:Layout()
    self.dirty = true
    self.signature = false
    self.bindDirty = true
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
    self.bindDirty = true
    self:ApplyBinding()
end

function M:Refresh()
    self:Layout()
    self.signature = false
end

function M:OnLockChanged(unlocked)
    -- the secure button would swallow the drag, so it only takes the mouse while locked
    if self.button and not (InCombatLockdown and InCombatLockdown()) then
        self.button:EnableMouse(not unlocked)
    end
    self.signature = false
end

function M:Layout()
    local f = self.frame
    if not f then return end
    local db = self.db
    f.icon:Style(db.size, db.shape, db.borderSize, db.borderAlpha, false)
    f:SetSize(db.size, db.size)
    f.icon.label:SetWidth(db.size + 40)
    if not (InCombatLockdown and InCombatLockdown()) then
        self.button:EnableMouse(not HHT:IsUnlocked(self))
    end
    HHT:ApplyGlobalLook(f)
end

-- ---------------------------------------------------------------------------
-- Food data
-- ---------------------------------------------------------------------------
function M:Blacklist(petKey)
    local bl = self.db.blacklist
    bl[petKey] = bl[petKey] or {}
    return bl[petKey]
end

function M:IsBlacklisted(id)
    local list = self.db.blacklist[self.petKey]
    return list and list[id] and true or false
end

function M:Scan()
    self.dirty = false
    self.lastScan = GetTime()

    local ok, name = pcall(UnitName, "pet")
    if ok and type(name) == "string" and not HHT.IsSecret(name) and name ~= "" then self.petKey = name end

    local diets = PetDiets()
    self.diets = diets
    local byId, list = {}, {}
    local learnedSet = self.db.learnedSet[DietKey(diets)]
    if next(diets) and C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo then
        for bag = 0, HHT.LastBag() do
            local okN, n = pcall(C_Container.GetContainerNumSlots, bag)
            n = okN and HHT.SafeNumber(n) or 0
            for slot = 1, n do
                local okI, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
                if okI and type(info) == "table" and not HHT.IsSecret(info) then
                    local id, c = HHT.SafeNumber(info.itemID), HHT.SafeNumber(info.stackCount)
                    local diet = id and ITEM_DIET[id]
                    if c and ((diet and diets[diet]) or (id and learnedSet and learnedSet[id])) then
                        local e = byId[id]
                        if not e then
                            e = { id = id, count = 0, name = ItemName(id, info.hyperlink) or tostring(id),
                                  icon = ItemIcon(id, info.iconFileID) }
                            byId[id] = e
                            list[#list + 1] = e
                        end
                        e.count = e.count + c
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name < b.name
    end)
    self.foods = list
end

-- Plain food reads "Use: Restores X health over Y sec. Must remain seated while eating." (two numbers).
-- Buff food adds the buff text with its own duration and values, so its Use line holds more numbers.
-- Counting numbers works in every language; the fixed BUFF_FOOD list is only the fallback for unloaded tooltips.
local buffCache, buffTried = {}, {}
local scanTip

local function TooltipLines(id)
    if C_TooltipInfo and C_TooltipInfo.GetItemByID then
        local ok, data = pcall(C_TooltipInfo.GetItemByID, id)
        if ok and type(data) == "table" and type(data.lines) == "table" then
            local out = {}
            for _, ln in ipairs(data.lines) do
                local t = type(ln) == "table" and ln.leftText
                if type(t) == "string" and not HHT.IsSecret(t) then out[#out + 1] = t end
            end
            return out
        end
    end
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "HHTFeedScanTip", UIParent, "GameTooltipTemplate")
    end
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    if not pcall(scanTip.SetHyperlink, scanTip, "item:" .. id) then return nil end
    local out = {}
    for i = 1, scanTip:NumLines() do
        local fs = _G["HHTFeedScanTipTextLeft" .. i]
        local t = fs and fs:GetText()
        if type(t) == "string" and not HHT.IsSecret(t) then out[#out + 1] = t end
    end
    return out
end

local function UseLineNumbers(lines)
    local trigger = ITEM_SPELL_TRIGGER_ONUSE or "Use:"
    for _, t in ipairs(lines) do
        if t:sub(1, #trigger) == trigger then
            t = t:gsub("(%d)[%.,'](%d%d%d)", "%1%2")
            local n = 0
            for _ in t:gmatch("%d+") do n = n + 1 end
            return n
        end
    end
    -- no Use line: the spell text is probably not loaded yet
    return nil
end

local function IsBuffFood(id)
    local c = buffCache[id]
    if c ~= nil then return c end
    local now = GetTime()
    if buffTried[id] and now - buffTried[id] < 5 then return BUFF_FOOD[id] and true or false end
    buffTried[id] = now
    local ok, lines = pcall(TooltipLines, id)
    local n = ok and lines and UseLineNumbers(lines)
    if n then
        c = n >= 4
        buffCache[id] = c
        return c
    end
    return BUFF_FOOD[id] and true or false
end

function M:IsProtected(id)
    return self.db.protectBuff and IsBuffFood(id) or false
end

-- Food the automatic pick may use: not blacklisted, and no protected buff food unless it is the chosen one.
function M:Usable(e)
    if self:IsBlacklisted(e.id) then return false end
    return e.id == self.db.selected[self.petKey] or not self:IsProtected(e.id)
end

function M:Supply()
    local n = 0
    for _, e in ipairs(self.foods) do
        if self:Usable(e) then n = n + e.count end
    end
    return n
end

function M:Pick()
    local sel = self.db.selected[self.petKey]
    for _, e in ipairs(self.foods) do
        if e.id == sel and not self:IsBlacklisted(e.id) then return e end
    end
    for _, e in ipairs(self.foods) do
        if self:Usable(e) then return e end
    end
end

function M:CurrentFoodName()
    return self.current and self.current.name or nil
end

-- ---------------------------------------------------------------------------
-- Menu
-- ---------------------------------------------------------------------------
function M:OpenMenu(anchor)
    if self.dirty then self:Scan() end
    local items = {}
    local sel = self.db.selected[self.petKey]
    for _, e in ipairs(self.foods) do
        local label = e.name .. "  x" .. e.count
        if self:IsBlacklisted(e.id) then
            label = "|cffff5050[" .. L("Blacklisted") .. "]|r " .. label
        elseif e.id == sel then
            label = "|cffabd473> |r" .. label
        elseif self:IsProtected(e.id) then
            label = "|cffffd100[" .. L("Buff food") .. "]|r " .. label
        end
        local id = e.id
        items[#items + 1] = { label = label, icon = e.icon, value = id, name = e.name,
            tip = function(tt)
                tt:SetHyperlink("item:" .. id)
                if self:IsBlacklisted(id) then
                    tt:AddLine(L("Blacklisted"), 1, 0.3, 0.3)
                elseif self:IsProtected(id) then
                    tt:AddLine(L("Buff food"), 1, 0.82, 0)
                end
            end }
    end
    UI.ShowMenu(anchor, items, function(item)
        if IsShiftKeyDown and IsShiftKeyDown() then
            local list = self:Blacklist(self.petKey)
            if list[item.value] then
                list[item.value] = nil
                HHT.Print(string.format(L("Food allowed: %s"), item.name))
            else
                list[item.value] = true
                HHT.Print(string.format(L("Food blacklisted: %s"), item.name))
            end
        elseif self:IsBlacklisted(item.value) then
            HHT.Print(string.format(L("Food is blacklisted (Shift+click to allow): %s"), item.name))
            return
        else
            self.db.selected[self.petKey] = item.value
            HHT.Print(string.format(L("Selected food: %s"), item.name))
        end
        self.signature = false
        self:Tick()
    end)
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function M:SyncSecure()
    if not self.shiftSet and not (InCombatLockdown and InCombatLockdown()) then
        self.button:SetAttribute("shift-type1", "macro")
        self.button:SetAttribute("shift-macrotext1", "/cast " .. S.CatalogName("feedPet"))
        self.shiftSet = true
    end
    local cur = self.current
    local text = ""
    if cur then text = string.format("/cast %s\n/use %s", S.CatalogName("feedPet"), cur.name) end
    if text ~= self.attrText then
        if InCombatLockdown and InCombatLockdown() then return end
        self.button:SetAttribute("type1", "macro")
        self.button:SetAttribute("macrotext1", text)
        self.attrText = text
    end
end

function M:Alert(text)
    HHT.Print(text)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, text, 1, 0.3, 0.3) end
end

-- Hunger and supply warnings run even while the icon is hidden.
function M:CheckAlerts(exists, dead, happy, unlocked)
    local db = self.db
    if not exists or dead then
        self.lastHappy, self.hungry, self.supplyLow = nil, false, false
        return false
    end
    -- While the module is unlocked or its settings page is open, the state is tracked but nothing is announced.
    if happy then
        local limit = db.hungerContent and 2 or 1
        local hungry = happy <= limit
        if hungry and db.hungerWarn and not unlocked and (not self.hungry or happy < (self.lastHappy or 3)) then
            self:Alert(happy == 1 and L("Your pet is unhappy: time to feed it.") or L("Your pet is only content: feed it for full damage."))
            if db.hungerSound then HHT.PlayAlert() end
        end
        self.hungry, self.lastHappy = hungry, happy
    end
    -- bags are not fully loaded right after login, so the supply check waits a little
    if not db.supplyWarn or GetTime() - (self.startAt or 0) < 15 or not next(self.diets or {}) then
        self.supplyLow = false
        return false
    end
    local supply = self:Supply()
    self.supplyCount = supply
    local low = supply < db.supplyBelow
    -- the chat message comes once per drop below the threshold, not again when the pet is called anew
    if low and not self.supplyWarned and not unlocked then self:Alert(string.format(L("Low on pet food: %d left."), supply)) end
    if not unlocked then self.supplyWarned = low end
    self.supplyLow = low
    return low
end

-- State for the Warnings module: unhappy pet, low supply, the picked food and the feed macro text.
function M:Status()
    return self.hungry and true or false, self.supplyLow and true or false, self.current, self.attrText or "", self.db.key ~= "" and self.db.key:upper() or nil, self.supplyCount
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    if self.dirty or GetTime() - (self.lastScan or 0) > 3 then self:Scan() end
    self.current = self:Pick()
    self:SyncSecure()
    if self.bindDirty and not InCombatLockdown() then self:ApplyBinding() end

    local unlocked = HHT:IsUnlocked(self)
    local okE, ex = pcall(UnitExists, "pet")
    local exists = okE and not HHT.IsSecret(ex) and ex and true or false
    local dead = exists and HHT.SafeBool(UnitIsDead, "pet") == true
    local pm = HHT.modules.pet
    local happy = pm and pm.ReadHappiness and pm.ReadHappiness() or nil
    local supplyLow = self:CheckAlerts(exists, dead, happy, unlocked)
    -- the food vendors appear on the map while the supply is low
    if supplyLow ~= self.lastSupplyLow then
        self.lastSupplyLow = supplyLow
        if HHT.PetMap then HHT.PetMap:Update() end
    end
    local show = exists and not dead
    if show and db.mode == "hungry" and happy == 3 then show = false end
    if unlocked then show = true end
    -- The frame holds a secure button: in combat it is only faded, and shown or hidden once combat ends.
    local combat = InCombatLockdown()
    if show then
        if f.hhtFaded then
            f.hhtFaded = nil
            HHT:ApplyGlobalLook(f)
        end
        if not f:IsShown() then
            if combat then return end
            f:Show()
        end
    else
        if combat then
            if f:IsShown() and not f.hhtFaded then HHT.HideSecure(f) end
        elseif f.hhtFaded then
            HHT.FlushHidden(f)
        elseif f:IsShown() then
            f:Hide()
        end
        return
    end

    local cur = self.current
    local total = cur and cur.count or 0
    local sig = table.concat({ cur and cur.id or 0, total, tostring(happy), tostring(db.showText), tostring(db.showName), db.key, tostring(supplyLow) }, ",")
    if sig == self.signature then return end
    self.signature = sig

    local ic = f.icon
    ic:SetKey(db.key ~= "" and db.key:upper() or "", 12, "TOPRIGHT", 1, 1, 0.4)
    if cur then
        ic:SetIcon(cur.icon or S.FALLBACK_ICON)
        ic:SetDesaturated(false)
    else
        ic:SetIcon(S.Resolve("@feedPet").icon)
        ic:SetDesaturated(true)
    end
    ic.count:SetText(db.showText and cur and tostring(total) or "")
    if supplyLow then ic.count:SetTextColor(1, 0.3, 0.3) else ic.count:SetTextColor(1, 1, 1) end
    ic.label:SetText(db.showName and (cur and cur.name or L("No food")) or "")
    local key = (happy == 3 and "happy") or (happy == 2 and "content") or (happy == 1 and "unhappy") or "neutral"
    ic:SetBorderColor(HHT.Col(db, key))
end

function M:Debug()
    local d = {}
    for k in pairs(self.diets or {}) do d[#d + 1] = k end
    local raw = {}
    if GetPetFoodTypes then pcall(function() for _, v in ipairs({ GetPetFoodTypes() }) do raw[#raw + 1] = tostring(v) end end) end
    HHT.Print(string.format("feeder: pet=%s rawDiet=%s diets=%s foods=%d current=%s",
        tostring(self.petKey), table.concat(raw, "/"), table.concat(d, ","), #(self.foods or {}), tostring(self:CurrentFoodName())))
    local buff = {}
    for _, e in ipairs(self.foods or {}) do
        if IsBuffFood(e.id) then buff[#buff + 1] = e.name end
    end
    HHT.Print("feeder: buff food = " .. (#buff > 0 and table.concat(buff, ", ") or "none"))
    local unknown = {}
    for _, id in ipairs(self:UnknownFoods()) do
        local lines = TooltipLines(id)
        unknown[#unknown + 1] = string.format("%d %s [%s]", id, tostring(ItemName(id) or "?"), lines and table.concat(lines, "/") or "no tooltip")
    end
    HHT.Print("feeder: unknown food = " .. (#unknown > 0 and table.concat(unknown, "; ") or "none"))
    local single, sets = 0, 0
    for _ in pairs(self.db.learned) do single = single + 1 end
    for _, s in pairs(self.db.learnedSet) do for _ in pairs(s) do sets = sets + 1 end end
    HHT.Print(string.format("feeder: learned = %d single-diet, %d multi-diet", single, sets))
end

-- Bag items the game files under Food & Drink that our id list does not know.
function M:UnknownFoods()
    local out, seen = {}, {}
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then return out end
    local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    for bag = 0, HHT.LastBag() do
        local okN, n = pcall(C_Container.GetContainerNumSlots, bag)
        n = okN and HHT.SafeNumber(n) or 0
        for slot = 1, n do
            local okI, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
            local id = okI and type(info) == "table" and not HHT.IsSecret(info) and HHT.SafeNumber(info.itemID)
            if id and not seen[id] and not ITEM_DIET[id] and instant then
                seen[id] = true
                local okF, _, _, _, _, _, classID, subClassID = pcall(instant, id)
                if okF and classID == 0 and subClassID == 5 then out[#out + 1] = id end
            end
        end
    end
    return out
end

-- /hht feedforget: test helper. Drops learned food and the built-in list until /reload, so Shift+click has something to learn.
function M:Forget()
    wipe(self.db.learned)
    wipe(self.db.learnedSet)
    wipe(ITEM_DIET)
    self.dirty = true
    HHT.Print("feeder: all known food forgotten until /reload. Shift+click the icon to learn it again.")
end

-- /hht feedprobe: asks the game which bag items Feed Pet accepts, while the spell waits for a target.
function M:Probe()
    local api = string.format("SpellIsTargeting=%s SpellCanTargetItemID=%s SpellCanTargetItem=%s",
        tostring(SpellIsTargeting ~= nil), tostring(SpellCanTargetItemID ~= nil), tostring(SpellCanTargetItem ~= nil))
    HHT.Print("feedprobe: " .. api)
    if not (SpellIsTargeting and SpellCanTargetItemID and C_Container) then return end
    HHT.Print("feedprobe: click Feed Pet now (30 s), the bags are read as soon as it waits for a target.")
    local f = self.probeFrame
    if not f then
        f = CreateFrame("Frame")
        self.probeFrame = f
    end
    local stopAt, acc = GetTime() + 30, 0
    f:SetScript("OnUpdate", function(frame, dt)
        acc = acc + dt
        if acc < 0.1 then return end
        acc = 0
        if GetTime() > stopAt then
            frame:SetScript("OnUpdate", nil)
            HHT.Print("feedprobe: timed out, Feed Pet was not clicked.")
        elseif SpellIsTargeting() then
            frame:SetScript("OnUpdate", nil)
            if C_Timer and C_Timer.After then
                C_Timer.After(0.4, function() M:ProbeScan(api) end)
            else
                M:ProbeScan(api)
            end
        end
    end)
end

-- Visible state of a Blizzard bag button (dimmed or bright), for items the game highlights while Feed Pet waits.
local function ButtonState(b)
    local icon = b.icon or b.Icon or (b.GetName and b:GetName() and _G[b:GetName() .. "IconTexture"])
    local p = {}
    if icon then
        p[#p + 1] = "desat=" .. tostring(icon:IsDesaturated())
        local r, g, bl = icon:GetVertexColor()
        p[#p + 1] = string.format("rgb=%.1f/%.1f/%.1f", r or 0, g or 0, bl or 0)
        p[#p + 1] = string.format("a=%.1f", icon:GetAlpha() or 0)
    end
    for _, k in ipairs({ "ItemContextOverlay", "searchOverlay", "SearchOverlay" }) do
        if b[k] and b[k].IsShown then p[#p + 1] = k .. "=" .. tostring(b[k]:IsShown()) end
    end
    return table.concat(p, " ")
end

local function BagButtons()
    local list = {}
    for i = 1, 13 do
        for j = 1, 40 do
            local b = _G["ContainerFrame" .. i .. "Item" .. j]
            if b then list[#list + 1] = b end
        end
    end
    local cb = _G.ContainerFrameCombinedBags
    if cb then
        if cb.EnumerateValidItems then
            for _, b in cb:EnumerateValidItems() do list[#list + 1] = b end
        else
            for _, b in ipairs({ cb:GetChildren() }) do
                if b.GetBagID then list[#list + 1] = b end
            end
        end
    end
    return list
end

local function ButtonItemId(b)
    local okB, bag = pcall(b.GetBagID, b)
    if not okB or not bag then
        local par = b.GetParent and b:GetParent()
        okB, bag = par ~= nil, par and par.GetID and par:GetID()
    end
    local okS, slot = pcall(b.GetID, b)
    return okB and okS and bag and slot and C_Container.GetContainerItemID and C_Container.GetContainerItemID(bag, slot) or nil
end

-- While Feed Pet waits for a target, the game dims every bag item the spell cannot take (ItemContextOverlay shown).
-- Returns the ids of the items left bright, or nil when no Blizzard bag buttons can be read.
local function FeedableIds()
    local ids, dimmed, n = {}, 0, 0
    for _, b in ipairs(BagButtons()) do
        local id = ButtonItemId(b)
        local ov = b.ItemContextOverlay
        if id and ov and ov.IsShown then
            n = n + 1
            if ov:IsShown() then dimmed = dimmed + 1 else ids[id] = true end
        end
    end
    if n == 0 or dimmed == 0 then return nil end
    return ids
end

-- Remembers which items Feed Pet accepted for the current pet's diet, so the menu also lists items missing from the built-in list.
function M:Learn()
    local ids = FeedableIds()
    if not ids then return end
    local diets = PetDiets()
    local key = DietKey(diets)
    if key == "" then return end
    local single = next(diets) and not next(diets, next(diets)) and next(diets)
    local set = self.db.learnedSet[key]
    local added = {}
    for id in pairs(ids) do
        local known = ITEM_DIET[id] or (set and set[id])
        if not known then
            if single then
                self.db.learned[id] = single
                ITEM_DIET[id] = single
            else
                set = set or {}
                set[id] = true
                self.db.learnedSet[key] = set
            end
            added[#added + 1] = tostring(ItemName(id) or id)
        end
    end
    if #added > 0 then
        self.dirty = true
        HHT.Print(string.format(L("Learned pet food: %s"), table.concat(added, ", ")))
    end
    return #added
end

-- Shift+click on the icon: Feed Pet starts waiting for a target (secure macro) and the bags are read.
function M:ScanBags()
    -- Opening and closing the bags and reading their buttons is not allowed in combat, and Feed Pet does not work there anyway.
    if InCombatLockdown() or HHT.InCombat() then
        HHT.Print(L("Food scan does not work in combat."))
        return
    end
    self.scanning, self.scanStart, self.openedBags = true, GetTime(), false
    local cb = _G.ContainerFrameCombinedBags
    local open = (cb and cb:IsShown()) or (_G.ContainerFrame1 and _G.ContainerFrame1:IsShown())
    if not open and OpenAllBags then
        pcall(OpenAllBags)
        self.openedBags = true
    end
end

function M:EndScan(text)
    self.scanning = false
    if self.openedBags and CloseAllBags and not InCombatLockdown() then pcall(CloseAllBags) end
    self.openedBags = false
    if text then HHT.Print(text) end
    -- SpellStopTargeting is protected, so the cursor is left for the player to cancel
    if SpellIsTargeting and SpellIsTargeting() then HHT.Print(L("Press Esc to cancel the Feed Pet cursor.")) end
end

-- Reads the bags once per Feed Pet targeting, after the game has updated the dimming.
function M:LearnTick()
    local now = GetTime()
    if InCombatLockdown() or HHT.InCombat() then
        if self.scanning then self:EndScan() end
        self.targetSince, self.learnedNow = nil, nil
        return
    end
    if not (SpellIsTargeting and SpellIsTargeting() and C_Spell and C_Spell.GetTargetSpellID) then
        self.targetSince, self.learnedNow = nil, nil
        if self.scanning and now - (self.scanStart or 0) > 2 then
            self:EndScan(L("Could not start Feed Pet. Is your pet out and not busy?"))
        end
        return
    end
    local okS, spell = pcall(C_Spell.GetTargetSpellID)
    if not okS or spell ~= 6991 then return end
    if not self.targetSince then self.targetSince = now end
    if not self.learnedNow and now - self.targetSince > (self.scanning and 0.8 or 0.4) then
        self.learnedNow = true
        local ok, n = pcall(self.Learn, self)
        if self.scanning then
            if not ok or n == nil then
                self:EndScan(L("Food scan needs the default bags (bag addons like Baganator cannot be read)."))
            elseif n == 0 then
                self:EndScan(L("Food scan: nothing new found."))
            else
                self:EndScan()
            end
        end
    end
end

function M:ProbeScan(api)
    local diets = self.diets or PetDiets()
    local items = {}
    local seen = {}
    for bag = 0, HHT.LastBag() do
        local okN, n = pcall(C_Container.GetContainerNumSlots, bag)
        n = okN and HHT.SafeNumber(n) or 0
        for slot = 1, n do
            local okI, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
            local id = okI and type(info) == "table" and not HHT.IsSecret(info) and HHT.SafeNumber(info.itemID)
            if id and not seen[id] then
                seen[id] = true
                items[#items + 1] = { id = id, bag = bag, slot = slot, link = info.hyperlink,
                                      label = id .. " " .. tostring(ItemName(id, info.hyperlink) or "?"),
                                      ours = ITEM_DIET[id] and diets[ITEM_DIET[id]] and true or false }
            end
        end
    end

    local lines = { api }
    local function Hover(tip, e)
        tip:SetOwner(UIParent, "ANCHOR_NONE")
        tip:SetBagItem(e.bag, e.slot)
        return SpellCanTargetItem()
    end
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "HHTFeedScanTip", UIParent, "GameTooltipTemplate")
    end
    local forms = {
        { "CanItemID(id)", function(e) return SpellCanTargetItemID(e.id) end },
        { "CanItem() after GameTooltip:SetBagItem", function(e) return Hover(GameTooltip, e) end },
        { "CanItem() after own tooltip SetBagItem", function(e) return Hover(scanTip, e) end },
    }
    for _, form in ipairs(forms) do
        local yes = {}
        local errs = 0
        for _, e in ipairs(items) do
            local ok, r = pcall(form[2], e)
            if not ok then errs = errs + 1 elseif r then yes[#yes + 1] = e.label end
        end
        lines[#lines + 1] = string.format("%s: yes=%d/%d err=%d %s", form[1], #yes, #items, errs, table.concat(yes, "; ", 1, math.min(#yes, 6)))
    end

    GameTooltip:Hide()
    local function Try(label, fn, ...)
        local ok, a, b = pcall(fn, ...)
        lines[#lines + 1] = label .. " -> " .. (ok and (tostring(a) .. (b ~= nil and (", " .. tostring(b)) or "")) or ("error " .. tostring(a)))
    end
    if C_Spell and C_Spell.GetTargetSpellID then Try("C_Spell.GetTargetSpellID()", C_Spell.GetTargetSpellID) end
    if C_Spell and C_Spell.TargetSpellChecksItemCondition then
        Try("C_Spell.TargetSpellChecksItemCondition()", C_Spell.TargetSpellChecksItemCondition)
        if items[1] then Try("C_Spell.TargetSpellChecksItemCondition(link)", C_Spell.TargetSpellChecksItemCondition, items[1].link) end
    end
    local cb = _G.ContainerFrameCombinedBags
    lines[#lines + 1] = "combined bags: exists=" .. tostring(cb ~= nil) .. " shown=" .. tostring(cb and cb:IsShown())

    local byState = {}
    local order = {}
    for _, b in ipairs(BagButtons()) do
        local id = ButtonItemId(b)
        if id then
            local st = ButtonState(b)
            if not byState[st] then byState[st] = {}; order[#order + 1] = st end
            local t = byState[st]
            t[#t + 1] = tostring(id)
        end
    end
    if #order == 0 then lines[#lines + 1] = "bag buttons: none found" end
    for _, st in ipairs(order) do
        local t = byState[st]
        lines[#lines + 1] = string.format("bag buttons [%s]: %d items, e.g. %s", st, #t, table.concat(t, ",", 1, math.min(#t, 8)))
    end

    local names = {}
    for k, v in pairs(_G) do
        if type(v) == "function" and type(k) == "string" and (k:find("TargetItem") or k:find("^SpellCan") or k:find("ItemTarget")) then names[#names + 1] = k end
    end
    for _, tn in ipairs({ "C_Item", "C_Spell", "C_Container", "C_PetInfo" }) do
        for k, v in pairs(_G[tn] or {}) do
            if type(v) == "function" and (k:find("Target") or k:find("Feed")) then names[#names + 1] = tn .. "." .. k end
        end
    end
    table.sort(names)
    lines[#lines + 1] = "api names: " .. table.concat(names, ",")

    self.lastProbe = table.concat(lines, "\n")
    for _, ln in ipairs(lines) do HHT.Print("feedprobe: " .. ln) end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 20, 100, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Stepper(L("Border alpha"), db, "borderAlpha", 0, 1, 0.1)
    form:Check(L("Show count text"), db, "showText")
    form:Check(L("Show food name"), db, "showName")
    form:Cycle(L("Show food icons"), db, "mode", {
        { "always", L("Always (with pet)") }, { "hungry", L("Only when not happy") } })
    form:Header(L("Pet feeder"))
    form:Note(L("Click: feed. Right-click: choose food. Shift+click in the menu: blacklist or allow a food."))
    local choose = UI.Button(form.content, 220, 22, L("Choose food (Shift+click: blacklist)"), function(btn) self:OpenMenu(btn) end)
    form:Place(choose, 22, 4, 6)
    form:Name("Choose food")
    form:Button(L("Clear blacklist (this pet)"), function()
        db.blacklist[self.petKey] = nil
        self.signature = false
        HHT.Print(L("Blacklist cleared."))
    end, 220)
    form:Button(L("Clear all blacklists"), function()
        db.blacklist = {}
        self.signature = false
        HHT.Print(L("Blacklist cleared."))
    end, 220)
    local keyBtn = form:Button("", function()
        if HHT.CaptureKey then
            HHT.CaptureKey(function(key)
                db.key = key
                self.bindDirty = true
                self.signature = false
                form:Refresh()
            end)
        end
    end, 220)
    form:Name("Set key")
    function keyBtn:Refresh()
        self:SetLabel(string.format(L("Feed key: %s"), db.key ~= "" and db.key:upper() or L("not set")))
    end
    keyBtn:Refresh()
    form:Button(L("Clear key"), function()
        db.key = ""
        self.bindDirty = true
        self.signature = false
    end, 220)
    form:Note(L("The key replaces its normal function while it is set. Changes apply after combat."))
    form:Header(L("Warnings"))
    form:Check(L("Warn when the pet gets unhappy"), db, "hungerWarn")
    form:Check(L("Also warn when the pet is only content (not green)"), db, "hungerContent")
    form:Check(L("Play a sound when the pet gets unhappy"), db, "hungerSound")
    form:Check(L("Warn when pet food runs low"), db, "supplyWarn")
    form:Stepper(L("Low food below"), db, "supplyBelow", 1, 100, 1)
    form:Check(L("Never pick buff food automatically"), db, "protectBuff")
    form:Header(L("Colors"))
    form:Color(L("Happy color"), db.colors, "happy")
    form:Color(L("Content color"), db.colors, "content")
    form:Color(L("Unhappy color"), db.colors, "unhappy")
    form:Color(L("Neutral color"), db.colors, "neutral")
end
