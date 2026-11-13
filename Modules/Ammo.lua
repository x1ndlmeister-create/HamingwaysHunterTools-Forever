-- Ammo counter: arrows and bullets counted separately (bags and ammo slot), works in combat, low-ammo and pre-dungeon warnings.
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Ammo"] = "Munition",
    ["Arrow and bullet counter with low ammo warning and dungeon reminder."] = "Pfeil- und Kugelzaehler mit Warnung bei wenig Munition und Dungeon-Erinnerung.",
    ["Show"] = "Anzeige",
    ["Visibility"] = "Sichtbarkeit",
    ["Only the ammo your weapon uses"] = "Nur Munition der Waffe",
    ["All ammo you carry"] = "Alle mitgefuehrte Munition",
    ["Count"] = "Anzahl",
    ["Equipped ammo only"] = "Nur angelegte Munition",
    ["All ammo of the type"] = "Alle Munition der Art",
    ["Warn below (red, blink, sound)"] = "Warnung unter (rot, Blinken, Ton)",
    ["Only show when ammo is low"] = "Nur bei wenig Munition anzeigen",
    ["Warn when entering a dungeon or on ready check"] = "Warnen beim Betreten eines Dungeons und bei Bereitschaftscheck",
    ["Dungeon reminder below"] = "Dungeon-Erinnerung unter",
    ["Play a sound when ammo gets low"] = "Ton wenn Munition knapp wird",
    ["Low on ammo: %d (recommended: %d)"] = "Wenig Munition: %d (empfohlen: %d)",
    ["Low ammo"] = "Wenig Munition",
    ["Low color"] = "Farbe wenig",
    ["Normal color"] = "Farbe normal",
    ["Show count text"] = "Anzahl zeigen",
    ["Count position"] = "Position der Anzahl",
    ["Below the icon"] = "Unter dem Icon",
    ["In the icon"] = "Im Icon",
    ["Click an ammo icon to choose and equip other ammo."] = "Klick auf ein Munitionssymbol: andere Munition waehlen und anlegen.",
    ["Equipped"] = "Angelegt",
    ["No ammo of this type"] = "Keine Munition dieser Art",
    ["Ammo equipped: %s"] = "Munition angelegt: %s",
    ["Could not equip: %s"] = "Anlegen nicht moeglich: %s",
})

local M = HHT:NewModule("ammo", {
    name = "Ammo",
    desc = "Arrow and bullet counter with low ammo warning and dungeon reminder.",
    positions = { main = { "CENTER", "CENTER", 150, -170 } },
    defaults = {
        size = 36, shape = "round", borderSize = 2, borderAlpha = 1, spacing = 8, grow = "right",
        visibility = "always", mode = "needed", countMode = "equipped", countPos = "below", showText = true, blink = true, sound = false,
        low = 200, reminder = true, reminderBelow = 400, onlyLow = false,
        colors = {
            normal = { 0.67, 0.83, 0.45 },
            low = { 0.95, 0.25, 0.20 },
        },
    },
})

local PROJECTILE, ARROW, BULLET = 6, 2, 3
local ICONS = {
    arrow = "Interface\\Icons\\INV_Ammo_Arrow_02",
    bullet = "Interface\\Icons\\INV_Ammo_Bullet_02",
}
local KINDS = { "arrow", "bullet" }
local kindCache = {}

local function ItemInfo(id)
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not fn then return end
    local ok, _, _, _, _, _, classID, subID = pcall(fn, id)
    if ok then return classID, subID end
end

local function Kind(id)
    local k = kindCache[id]
    if k ~= nil then return k or nil end
    local class, sub = ItemInfo(id)
    k = false
    if class == PROJECTILE then
        if sub == ARROW then k = "arrow" elseif sub == BULLET then k = "bullet" end
    end
    kindCache[id] = k
    return k or nil
end

local function ItemName(id)
    if C_Item and C_Item.GetItemNameByID then
        local ok, n = pcall(C_Item.GetItemNameByID, id)
        if ok and type(n) == "string" then return n end
    end
    if GetItemInfo then
        local ok, n = pcall(GetItemInfo, id)
        if ok and type(n) == "string" then return n end
    end
    return tostring(id)
end

local function ItemIcon(id, fallback)
    if C_Item and C_Item.GetItemIconByID then
        local ok, t = pcall(C_Item.GetItemIconByID, id)
        if ok and t then return t end
    end
    return fallback
end

function M:OnInit()
    self.icons = {}
    self.stacks = { arrow = {}, bullet = {} }
    self.counts = { arrow = 0, bullet = 0 }
    self.dirty = true
    self.signature = false
    self.wasLow = false
    for _, ev in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "ITEM_COUNT_CHANGED" }) do
        HHT:Listen(self, ev, "MarkDirty")
    end
    HHT:Listen(self, "PLAYER_ENTERING_WORLD", "OnEnterWorld")
    HHT:Listen(self, "READY_CHECK", "OnReadyCheck")
    HHT:Every(self, 0.3, M.Tick)
end

function M:MarkDirty()
    self.dirty = true
end

-- Count and icon the counter shows for a kind: the equipped ammo, or everything of that type.
function M:Shown(kind)
    if self.db.countMode == "equipped" then
        for _, e in ipairs(self.stacks[kind] or {}) do
            if e.equipped then return e.count, e.icon end
        end
    end
    return self.counts[kind] or 0, nil
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsAmmo", UIParent)
    f:SetSize(36, 36)
    self.frame = f
    HHT:MakeMovable(f, self, "main", L("Ammo"))
end

function M:OnEnable()
    self:Build()
    self.frame:Show()
    self.dirty = true
    self.signature = false
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
    for _, ic in pairs(self.icons) do ic:SetBlink(false) end
end

function M:Refresh()
    self.signature = false
    if self.frame then HHT:ApplyGlobalLook(self.frame) end
end

function M:OnLockChanged()
    self.signature = false
end

function M:Scan()
    self.dirty = false
    self.lastScan = GetTime()
    local counts = { arrow = 0, bullet = 0 }
    local stacks = { arrow = {}, bullet = {} }
    local function Add(id, n, bag, slot, equipped)
        local kind = id and n and Kind(id)
        if not kind then return end
        counts[kind] = counts[kind] + n
        local list = stacks[kind]
        local e
        for _, x in ipairs(list) do if x.id == id then e = x break end end
        if not e then
            e = { id = id, count = 0, name = ItemName(id), icon = ItemIcon(id, ICONS[kind]) }
            list[#list + 1] = e
        end
        e.count = e.count + n
        if equipped then e.equipped = true elseif not e.slot then e.bag, e.slot = bag, slot end
    end

    if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo then
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            local okN, n = pcall(C_Container.GetContainerNumSlots, bag)
            n = okN and HHT.SafeNumber(n) or 0
            for slot = 1, n do
                local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
                if ok and type(info) == "table" and not HHT.IsSecret(info) then
                    Add(HHT.SafeNumber(info.itemID), HHT.SafeNumber(info.stackCount), bag, slot)
                end
            end
        end
    end

    local okI, ammoId = pcall(GetInventoryItemID, "player", 0)
    ammoId = okI and HHT.SafeNumber(ammoId) or nil
    if ammoId then
        -- The ammo slot count can already include the bags; GetItemCount is the true total, so only add what the bags lack.
        local inBags = 0
        for _, kind in ipairs({ "arrow", "bullet" }) do
            for _, e in ipairs(stacks[kind]) do if e.id == ammoId then inBags = e.count end end
        end
        local total
        if GetItemCount then
            local okT, t = pcall(GetItemCount, ammoId)
            total = okT and HHT.SafeNumber(t) or nil
        end
        if not total and GetInventoryItemCount then
            local okC, c = pcall(GetInventoryItemCount, "player", 0)
            total = okC and HHT.SafeNumber(c) or nil
        end
        if total then Add(ammoId, math.max(0, total - inBags), nil, nil, true) end
    end

    for _, list in pairs(stacks) do
        table.sort(list, function(a, b)
            if a.count ~= b.count then return a.count > b.count end
            return a.name < b.name
        end)
    end
    self.stacks = stacks
    self.counts = counts

    local okW, wid = pcall(GetInventoryItemID, "player", 18)
    wid = okW and HHT.SafeNumber(wid) or nil
    self.needs = nil
    if wid then
        local _, sub = ItemInfo(wid)
        if sub == 3 then self.needs = "bullet"
        elseif sub == 2 or sub == 18 then self.needs = "arrow" end
    end
end

function M:Equip(e)
    if e.equipped or not e.slot then return end
    local fn = (C_Container and C_Container.UseContainerItem) or UseContainerItem
    local ok = fn and pcall(fn, e.bag, e.slot)
    HHT.Print(string.format(L(ok and "Ammo equipped: %s" or "Could not equip: %s"), e.name))
    self.dirty = true
end

function M:OpenMenu(anchor, kind)
    if self.dirty then self:Scan() end
    local items = {}
    for _, e in ipairs(self.stacks[kind] or {}) do
        local label = e.name .. "  x" .. e.count
        if e.equipped then label = "|cffabd473> |r" .. label .. "  (" .. L("Equipped") .. ")" end
        items[#items + 1] = { label = label, icon = e.icon, value = e }
    end
    if #items == 0 then items[1] = { label = L("No ammo of this type"), value = false } end
    UI.ShowMenu(anchor, items, function(item)
        if item.value then self:Equip(item.value) end
    end)
end

function M:Remind()
    local db = self.db
    if not db.reminder or not self.needs then return end
    local now = GetTime()
    if self.lastReminder and now - self.lastReminder < 60 then return end
    local n = self:Shown(self.needs)
    if n >= db.reminderBelow then return end
    self.lastReminder = now
    local text = string.format(L("Low on ammo: %d (recommended: %d)"), n, db.reminderBelow)
    HHT.Print(text)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, text, 1, 0.3, 0.3) end
end

function M:OnEnterWorld()
    local ok, inInstance, kind = pcall(IsInInstance)
    if ok and inInstance and (kind == "party" or kind == "raid") then
        self.reminderAt = GetTime() + 3
    end
end

function M:OnReadyCheck()
    self.reminderAt = GetTime() + 0.5
end

function M:Visible(kind, n)
    local db = self.db
    if db.mode == "needed" and self.needs then return kind == self.needs end
    return n > 0 or kind == self.needs
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    local now = GetTime()
    if self.dirty or now - (self.lastScan or 0) > 5 then self:Scan() end
    if self.reminderAt and now >= self.reminderAt then
        self.reminderAt = nil
        self:Scan()
        self:Remind()
    end

    local unlocked = HHT:IsUnlocked(self)
    local show = HHT:ShouldShow(db.visibility, self)
    local list = {}
    if show then
        for _, kind in ipairs(KINDS) do
            local n, icon = self:Shown(kind)
            if unlocked then
                list[#list + 1] = { kind = kind, n = (n > 0) and n or 200, icon = icon }
            elseif self:Visible(kind, n) and not (db.onlyLow and n >= db.low) then
                list[#list + 1] = { kind = kind, n = n, icon = icon }
            end
        end
    end
    if f:IsShown() ~= (#list > 0) then f:SetShown(#list > 0) end

    local isLow = false
    local sig = { tostring(db.low), tostring(db.onlyLow), tostring(db.countPos) }
    for _, e in ipairs(list) do
        sig[#sig + 1] = e.kind .. e.n .. tostring(e.icon)
        if e.n < db.low and (e.kind == self.needs or not self.needs) then isLow = true end
    end
    local signature = table.concat(sig, ",")
    if isLow and not self.wasLow and db.sound and not unlocked then
        pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959)
    end
    self.wasLow = isLow
    if signature == self.signature then return end
    self.signature = signature

    local s, sp = db.size, db.spacing
    f:SetSize(s, s)
    for i = 1, #KINDS do
        local ic = self.icons[KINDS[i]]
        if ic then ic:Hide(); ic:SetBlink(false) end
    end
    for i, e in ipairs(list) do
        local ic = self.icons[e.kind]
        if not ic then
            ic = Icon.New(f)
            self.icons[e.kind] = ic
            local kind = e.kind
            ic.click = CreateFrame("Button", nil, ic)
            ic.click:SetAllPoints(ic)
            ic.click:RegisterForClicks("AnyUp")
            ic.click:SetScript("OnClick", function(btn) M:OpenMenu(btn, kind) end)
        end
        ic.click:EnableMouse(not unlocked)
        local low = e.n < db.low
        ic:Style(s, db.shape, db.borderSize, db.borderAlpha, false)
        ic:SetIcon(e.icon or ICONS[e.kind])
        ic:SetBorderColor(HHT.Col(db, low and "low" or "normal"))
        ic:SetDesaturated(e.n == 0)
        ic.label:SetWidth(s + sp)
        local inside = db.countPos == "icon"
        local txt = db.showText and tostring(e.n) or ""
        local cr, cg, cb = HHT.Col(db, low and "low" or "normal")
        ic.label:SetText(inside and "" or txt)
        ic.count:SetText(inside and txt or "")
        ic.label:SetTextColor(cr, cg, cb)
        ic.count:SetTextColor(cr, cg, cb)
        ic:SetBlink(low and db.blink and not unlocked)
        local step = (s + sp) * (i - 1)
        ic:ClearAllPoints()
        if db.grow == "right" then ic:SetPoint("TOPLEFT", f, "TOPLEFT", step, 0)
        elseif db.grow == "left" then ic:SetPoint("TOPRIGHT", f, "TOPRIGHT", -step, 0)
        elseif db.grow == "down" then ic:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -step)
        else ic:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, step) end
        ic:Show()
    end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 20, 100, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Stepper(L("Spacing"), db, "spacing", 0, 40, 1)
    form:Cycle(L("Grow direction"), db, "grow", {
        { "right", L("Right") }, { "left", L("Left") }, { "up", L("Up") }, { "down", L("Down") } })
    form:Check(L("Show count text"), db, "showText")
    form:Cycle(L("Count position"), db, "countPos", { { "below", L("Below the icon") }, { "icon", L("In the icon") } })
    form:Note(L("Click an ammo icon to choose and equip other ammo."))
    form:Button(L("Show all ammunition"), function() HHT.AmmoList:Open() end, 220)
    form:Button(L("Ammo vendors on map"), function() if HHT.AmmoVendors then HHT.AmmoVendors.Show() end end, 220)
    form:Button(L("Waypoint to nearest vendor"), function() if HHT.AmmoVendors then HHT.AmmoVendors.Nearest() end end, 220)
    form:Header(L("Behavior"))
    form:Cycle(L("Show"), db, "mode", {
        { "needed", L("Only the ammo your weapon uses") }, { "all", L("All ammo you carry") } })
    form:Cycle(L("Visibility"), db, "visibility", HHT.VisibilityChoices())
    form:Cycle(L("Count"), db, "countMode", {
        { "equipped", L("Equipped ammo only") }, { "all", L("All ammo of the type") } })
    form:Stepper(L("Warn below (red, blink, sound)"), db, "low", 0, 2000, 50)
    form:Check(L("Only show when ammo is low"), db, "onlyLow")
    form:Check(L("Blink warnings"), db, "blink")
    form:Check(L("Play a sound when ammo gets low"), db, "sound")
    form:Check(L("Warn when entering a dungeon or on ready check"), db, "reminder")
    form:Stepper(L("Dungeon reminder below"), db, "reminderBelow", 0, 3000, 50)
    form:Header(L("Colors"))
    form:Color(L("Normal color"), db.colors, "normal")
    form:Color(L("Low color"), db.colors, "low")
end
