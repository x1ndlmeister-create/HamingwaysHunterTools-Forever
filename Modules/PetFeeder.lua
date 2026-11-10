-- Pet feeder: click to feed your pet with a chosen food. Per-pet food choice and blacklist, optional macro sync.
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Pet feeder"] = "Begleiter-Futter",
    ["Click to feed your pet. Per-pet food choice and blacklist."] = "Klick zum Fuettern. Futterwahl und Blacklist pro Begleiter.",
    ["Choose food"] = "Futter waehlen",
    ["Clear blacklist (this pet)"] = "Blacklist leeren (dieser Begleiter)",
    ["Clear all blacklists"] = "Alle Blacklists leeren",
    ["Keep the HHT Feed macro up to date"] = "HHT-Feed-Makro aktuell halten",
    ["Click: feed. Right-click: choose food. Shift+click in the menu: blacklist or allow a food."] = "Klick: fuettern. Rechtsklick: Futter waehlen. Umschalt+Klick im Menue: Futter sperren oder erlauben.",
    ["Show when"] = "Anzeigen wenn",
    ["Always (with pet)"] = "Immer (mit Begleiter)",
    ["Only when not happy"] = "Nur wenn nicht gluecklich",
    ["Show food name"] = "Futternamen zeigen",
    ["No food"] = "Kein Futter",
    ["Feed"] = "Fuettern",
    ["Choose food (Shift+click: blacklist)"] = "Futter waehlen (Umschalt+Klick: sperren)",
    ["Blacklisted"] = "Gesperrt",
    ["Blacklisted food:"] = "Gesperrtes Futter:",
    ["Happy color"] = "Farbe gluecklich",
    ["Content color"] = "Farbe zufrieden",
    ["Unhappy color"] = "Farbe unzufrieden",
    ["Neutral color"] = "Farbe neutral",
    ["Blacklist cleared."] = "Blacklist geleert.",
    ["Selected food: %s"] = "Gewaehltes Futter: %s",
    ["Food blacklisted: %s"] = "Futter gesperrt: %s",
    ["Food allowed: %s"] = "Futter erlaubt: %s",
    ["Food is blacklisted (Shift+click to allow): %s"] = "Futter ist gesperrt (Umschalt+Klick zum Erlauben): %s",
})

local M = HHT:NewModule("feeder", {
    name = "Pet feeder",
    desc = "Click to feed your pet. Per-pet food choice and blacklist.",
    positions = { main = { "CENTER", "CENTER", -260, -215 } },
    defaults = {
        size = 36, shape = "round", borderSize = 2, borderAlpha = 1,
        showText = true, showName = false, mode = "always", syncMacro = true,
        selected = {}, blacklist = {},
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
    fish = { 13889, 19996, 13933, 13888, 13935, 13546, 6290, 4593, 5503, 16971, 2682, 13927, 2675, 13930, 5476, 4655, 6038, 13928, 13929, 13893, 4592, 8364, 13932, 5095, 6291, 6308, 13754, 6317, 6289, 8365, 6361, 13758, 6362, 6303, 8959, 4603, 13756, 13760, 4594, 787, 5468, 15924, 12216, 8957, 6887, 5504, 12206, 13755, 7974 },
    meat = { 21235, 19995, 4457, 3173, 2888, 3730, 3726, 3220, 2677, 3404, 12213, 2679, 769, 2673, 2684, 1081, 12224, 5479, 2924, 3662, 4599, 17119, 5478, 5051, 12217, 2687, 9681, 2287, 12204, 3727, 13851, 12212, 5472, 5467, 5480, 1015, 12209, 3731, 12223, 3770, 12037, 4739, 12184, 13759, 12203, 12210, 2681, 5474, 8952, 1017, 5465, 6890, 3712, 3729, 2680, 17222, 5471, 5469, 5477, 2672, 2685, 3728, 3667, 12208, 18045, 5470, 12202, 117, 12205, 3771 },
    bread = { 1113, 5349, 1487, 1114, 8075, 8076, 22895, 19696, 21254, 2683, 4541, 17197, 3666, 8950, 4542, 4544, 4601, 4540, 16169 },
    cheese = { 8932, 414, 2070, 422, 3927, 1707 },
    fruit = { 19994, 8953, 4539, 16168, 4602, 4536, 4538, 4537, 11950 },
}

local ITEM_DIET = {}
for diet, ids in pairs(FOODS) do
    for _, id in ipairs(ids) do ITEM_DIET[id] = diet end
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

local function PetDiets()
    local set = {}
    if GetPetFoodTypes then pcall(function() AddDiets(set, GetPetFoodTypes()) end) end
    if not next(set) and C_PetInfo and C_PetInfo.GetPetFoodTypes then
        pcall(function() AddDiets(set, C_PetInfo.GetPetFoodTypes()) end)
    end
    return set
end

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
    HHT:Listen(self, "BAG_UPDATE_DELAYED", "MarkDirty")
    HHT:Listen(self, "UNIT_PET", "MarkDirty")
    HHT:Listen(self, "PLAYER_ENTERING_WORLD", "MarkDirty")
    HHT:Listen(self, "SPELLS_CHANGED", "MarkDirty")
    HHT:Listen(self, "PLAYER_REGEN_ENABLED", "MarkDirty")
    HHT:Every(self, 0.25, M.Tick)
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
        if button == "RightButton" then M:OpenMenu(b) end
    end)
    b:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L("Pet feeder"))
        local cur = M.current
        GameTooltip:AddLine(cur and cur.name or L("No food"), 1, 1, 1)
        GameTooltip:AddLine(L("Click: feed. Right-click: choose food. Shift+click in the menu: blacklist or allow a food."), 0.7, 0.7, 0.7, true)
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
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
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
        self.button:EnableMouse(not HHT:IsUnlocked())
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
    if next(diets) and C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo then
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            local okN, n = pcall(C_Container.GetContainerNumSlots, bag)
            n = okN and HHT.SafeNumber(n) or 0
            for slot = 1, n do
                local okI, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
                if okI and type(info) == "table" and not HHT.IsSecret(info) then
                    local id, c = HHT.SafeNumber(info.itemID), HHT.SafeNumber(info.stackCount)
                    local diet = id and ITEM_DIET[id]
                    if diet and diets[diet] and c then
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

function M:Pick()
    local sel = self.db.selected[self.petKey]
    for _, e in ipairs(self.foods) do
        if e.id == sel and not self:IsBlacklisted(e.id) then return e end
    end
    for _, e in ipairs(self.foods) do
        if not self:IsBlacklisted(e.id) then return e end
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
        end
        items[#items + 1] = { label = label, icon = e.icon, value = e.id, name = e.name }
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
    local cur = self.current
    local text = ""
    if cur then text = string.format("/cast %s\n/use %s", S.CatalogName("feedPet"), cur.name) end
    if text ~= self.attrText then
        if InCombatLockdown and InCombatLockdown() then return end
        self.button:SetAttribute("type1", "macro")
        self.button:SetAttribute("macrotext1", text)
        self.attrText = text
    end
    local id = cur and cur.id or 0
    if self.db.syncMacro and id ~= self.macroId then
        local mm = HHT.modules.macros
        if mm and mm.UpdateFeed and mm:UpdateFeed() then self.macroId = id end
    end
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    if self.dirty or GetTime() - (self.lastScan or 0) > 3 then self:Scan() end
    self.current = self:Pick()
    self:SyncSecure()

    local unlocked = HHT:IsUnlocked()
    local okE, ex = pcall(UnitExists, "pet")
    local exists = okE and not HHT.IsSecret(ex) and ex and true or false
    local dead = exists and HHT.SafeBool(UnitIsDead, "pet") == true
    local pm = HHT.modules.pet
    local happy = pm and pm.ReadHappiness and pm.ReadHappiness() or nil

    local show = exists and not dead
    if show and db.mode == "hungry" and happy == 3 then show = false end
    if unlocked then show = true end
    if f:IsShown() ~= show then f:SetShown(show) end
    if not show then return end

    local cur = self.current
    local total = cur and cur.count or 0
    local sig = table.concat({ cur and cur.id or 0, total, tostring(happy), tostring(db.showText), tostring(db.showName) }, ",")
    if sig == self.signature then return end
    self.signature = sig

    local ic = f.icon
    if cur then
        ic:SetIcon(cur.icon or S.FALLBACK_ICON)
        ic:SetDesaturated(false)
    else
        ic:SetIcon(S.Resolve("@feedPet").icon)
        ic:SetDesaturated(true)
    end
    ic.count:SetText(db.showText and cur and tostring(total) or "")
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
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 20, 100, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Check(L("Show count text"), db, "showText")
    form:Check(L("Show food name"), db, "showName")
    form:Cycle(L("Show when"), db, "mode", {
        { "always", L("Always (with pet)") }, { "hungry", L("Only when not happy") } })
    form:Header(L("Pet feeder"))
    form:Note(L("Click: feed. Right-click: choose food. Shift+click in the menu: blacklist or allow a food."))
    local choose = UI.Button(form.content, 220, 22, L("Choose food (Shift+click: blacklist)"), function(btn) self:OpenMenu(btn) end)
    form:Place(choose, 22, 4, 6)
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
    form:Check(L("Keep the HHT Feed macro up to date"), db, "syncMacro")
    form:Header(L("Colors"))
    form:Color(L("Happy color"), db.colors, "happy")
    form:Color(L("Content color"), db.colors, "content")
    form:Color(L("Unhappy color"), db.colors, "unhappy")
    form:Color(L("Neutral color"), db.colors, "neutral")
end
