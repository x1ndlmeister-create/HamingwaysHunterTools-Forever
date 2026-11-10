-- Pet macros: creates or updates character macros for pet handling (out of combat only).
local ADDON, HHT = ...
local L, S = HHT.L, HHT.Spells

HHT:AddGerman({
    ["Macros"] = "Makros",
    ["Creates character macros for pet handling, shots, traps, aspects and more."] = "Erstellt Charakter-Makros fuer Begleiter, Schuesse, Fallen, Aspekte und mehr.",
    ["Hunter macros"] = "Jaeger-Makros",
    ["General macros (account-wide, 120 slots). Only ticked macros are created."] = "Allgemeine Makros (fuer alle Charaktere, 120 Plaetze). Nur angehakte Makros werden erstellt.",
    ["Attack: clear dead target, next enemy, Auto Shot"] = "Angriff: totes Ziel loeschen, naechster Gegner, Auto-Schuss",
    ["Pet attack and Hunter's Mark"] = "Begleiter-Angriff und Mal des Jaegers",
    ["Aspect: Cheetah, Ctrl Hawk, Shift Monkey"] = "Aspekt: Gepard, Strg Falke, Umschalt Affe",
    ["Trap: Freezing, Shift Immolation, Ctrl Frost"] = "Falle: Frost, Umschalt Feuer, Strg Eis",
    ["Melee: pet attack, Raptor Strike, Mongoose Bite"] = "Nahkampf: Begleiter-Angriff, Raptor-Stoss, Mungobiss",
    ["Feign Death with pet follow"] = "Totstellen mit Begleiter folgen",
    ["Kite: Concussive Shot, Shift Wing Clip"] = "Kiten: Erschuetternder Schuss, Umschalt Fluegelstutzen",
    ["Toggle pet Growl auto-cast"] = "Knurren des Begleiters Auto-Wirken umschalten",
    ["Tame Beast, Shift Beast Lore"] = "Wildtier zaehmen, Umschalt Wildtierkunde",
    ["Tracking: Beasts, Shift Humanoids, Ctrl Hidden"] = "Spuren: Tiere, Umschalt Humanoide, Strg Verborgene",
    ["Burst: Rapid Fire and both trinkets"] = "Burst: Schnellfeuer und beide Schmuckstuecke",
    ["Ammo vendors: show on map and set waypoint"] = "Munitionshaendler: auf Karte zeigen und Wegpunkt setzen",
    ["Stable masters: show on map and set waypoint"] = "Stallmeister: auf Karte zeigen und Wegpunkt setzen",
    ["Pet macros"] = "Begleiter-Makros",
    ["Creates character macros for call, dismiss, revive, mend and feed."] = "Erstellt Charakter-Makros fuer Rufen, Wegschicken, Wiederbeleben, Heilen und Fuettern.",
    ["Macros are created out of combat. Drag them from the cursor (or the macro window) to an action bar."] = "Makros werden ausserhalb des Kampfes erstellt. Ziehe sie vom Mauszeiger (oder aus dem Makrofenster) auf eine Aktionsleiste.",
    ["One button: revive, call or mend"] = "Ein Knopf: Wiederbeleben, Rufen oder Heilen",
    ["Call or dismiss"] = "Rufen oder Wegschicken",
    ["Mend Pet macro"] = "Tier heilen Makro",
    ["Revive Pet macro"] = "Tier wiederbeleben Makro",
    ["Feed Pet macro"] = "Tier fuettern Makro",
    ["Food item name for Feed Pet"] = "Futter-Gegenstand fuer Tier fuettern (leer: Wahl des Futter-Moduls)",
    ["Create or update macros"] = "Makros erstellen oder aktualisieren",
    ["Macros are not possible in combat."] = "Makros sind im Kampf nicht moeglich.",
    ["Macros created: %d, updated: %d, failed: %d"] = "Makros erstellt: %d, aktualisiert: %d, fehlgeschlagen: %d",
    ["Macro not found. Create the macros first."] = "Makro nicht gefunden. Erstelle zuerst die Makros.",
    ["Failed: "] = "Fehlgeschlagen: ",
    ["general macros"] = "Allgemeine Makros",
    ["Macro on cursor: place it on an action bar."] = "Makro am Mauszeiger: auf eine Aktionsleiste legen.",
    ["To cursor"] = "Auf den Mauszeiger",
})

local M = HHT:NewModule("macros", {
    name = "Macros",
    desc = "Creates character macros for pet handling, shots, traps, aspects and more.",
    noFrame = true,
    enabledByDefault = true,
    defaults = {
        food = "",
        make = {
            smart = true, toggle = true, mend = true, revive = true, feed = true,
            attack = false, mark = false, aspect = false, trap = false, melee = false, feign = false,
            kite = false, growl = false, tame = false, track = false, burst = false, ammo = false, stable = false,
        },
    },
})

-- Feed stays at index 5 (UpdateFeed). Macros are account-wide (limit 120).
local DEFS = {
    { key = "smart", name = "HHT Pet", label = "One button: revive, call or mend", icon = "callPet", group = "pet" },
    { key = "toggle", name = "HHT Call", label = "Call or dismiss", icon = "callPet", group = "pet" },
    { key = "mend", name = "HHT Mend", label = "Mend Pet macro", icon = "mendPet", group = "pet" },
    { key = "revive", name = "HHT Revive", label = "Revive Pet macro", icon = "revivePet", group = "pet" },
    { key = "feed", name = "HHT Feed", label = "Feed Pet macro", icon = "feedPet", group = "pet" },
    { key = "attack", name = "HHT Attack", label = "Attack: clear dead target, next enemy, Auto Shot", icon = "autoShot", group = "hunter" },
    { key = "mark", name = "HHT Mark", label = "Pet attack and Hunter's Mark", icon = "hunterMark", group = "hunter" },
    { key = "aspect", name = "HHT Aspect", label = "Aspect: Cheetah, Ctrl Hawk, Shift Monkey", icon = "aspectCheetah", group = "hunter" },
    { key = "trap", name = "HHT Trap", label = "Trap: Freezing, Shift Immolation, Ctrl Frost", icon = "freezingTrap", group = "hunter" },
    { key = "melee", name = "HHT Melee", label = "Melee: pet attack, Raptor Strike, Mongoose Bite", icon = "raptorStrike", group = "hunter" },
    { key = "feign", name = "HHT Feign", label = "Feign Death with pet follow", icon = "feignDeath", group = "hunter" },
    { key = "kite", name = "HHT Kite", label = "Kite: Concussive Shot, Shift Wing Clip", icon = "concussive", group = "hunter" },
    { key = "growl", name = "HHT Growl", label = "Toggle pet Growl auto-cast", icon = "growl", group = "hunter" },
    { key = "tame", name = "HHT Tame", label = "Tame Beast, Shift Beast Lore", icon = "tameBeast", group = "hunter" },
    { key = "track", name = "HHT Track", label = "Tracking: Beasts, Shift Humanoids, Ctrl Hidden", icon = "trackBeasts", group = "hunter" },
    { key = "burst", name = "HHT Burst", label = "Burst: Rapid Fire and both trinkets", icon = "rapidFire", group = "hunter" },
    { key = "ammo", name = "HHT Ammo", label = "Ammo vendors: show on map and set waypoint", icon = "autoShot", iconItem = 2512, group = "hunter" },
    { key = "stable", name = "HHT Stable", label = "Stable masters: show on map and set waypoint", icon = "callPet", group = "hunter" },
}

local function N(key) return S.CatalogName(key) end

-- Body builders for the hunter macros: format string plus the spell keys filled in order.
local HUNTER_BODY = {
    attack = { "#showtooltip %s\n/cleartarget [dead]\n/targetenemy [noharm]\n/cast !%s", "autoShot", "autoShot" },
    mark = { "#showtooltip %s\n/petattack\n/cast %s", "hunterMark", "hunterMark" },
    aspect = { "#showtooltip\n/cast [mod:ctrl] %s; [mod:shift] %s; %s", "aspectHawk", "aspectMonkey", "aspectCheetah" },
    trap = { "#showtooltip\n/cast [mod:shift] %s; [mod:ctrl] %s; %s", "immolationTrap", "frostTrap", "freezingTrap" },
    melee = { "#showtooltip %s\n/petattack\n/cast %s\n/cast %s", "raptorStrike", "raptorStrike", "mongoose" },
    feign = { "#showtooltip %s\n/petfollow\n/cast %s", "feignDeath", "feignDeath" },
    kite = { "#showtooltip\n/cast [mod:shift] %s; %s", "wingClip", "concussive" },
    growl = { "#showtooltip %s\n/petautocasttoggle %s", "growl", "growl" },
    tame = { "#showtooltip\n/cast [mod:shift] %s; %s", "beastLore", "tameBeast" },
    track = { "#showtooltip\n/cast [mod:shift] %s; [mod:ctrl] %s; %s", "trackHumanoids", "trackHidden", "trackBeasts" },
    burst = { "#showtooltip %s\n/cast %s\n/use 13\n/use 14", "rapidFire", "rapidFire" },
    ammo = { "/hht ammo\n/hht ammo go" },
    stable = { "/hht stable\n/hht stable go" },
}

function M:Body(key)
    local hb = HUNTER_BODY[key]
    if hb then
        local args = {}
        for i = 2, #hb do args[#args + 1] = N(hb[i]) end
        return string.format(hb[1], unpack(args))
    end
    local call, dismiss, mend = S.CatalogName("callPet"), S.CatalogName("dismissPet"), S.CatalogName("mendPet")
    local revive, feed = S.CatalogName("revivePet"), S.CatalogName("feedPet")
    if key == "smart" then
        return string.format("#showtooltip\n/cast [@pet,dead] %s; [nopet] %s; [@pet,exists,nodead] %s", revive, call, mend)
    elseif key == "toggle" then
        return string.format("#showtooltip\n/cast [nopet] %s; [pet] %s", call, dismiss)
    elseif key == "mend" then
        return string.format("#showtooltip\n/cast %s", mend)
    elseif key == "revive" then
        return string.format("#showtooltip\n/cast %s", revive)
    elseif key == "feed" then
        local food = (self.db.food or ""):match("^%s*(.-)%s*$")
        if food == "" then
            local fm = HHT.modules.feeder
            food = fm and fm.enabled and fm:CurrentFoodName() or ""
        end
        local body = string.format("#showtooltip %s\n/cast %s", feed, feed)
        if food ~= "" then body = body .. "\n/use " .. food end
        return body
    end
end

local function IconOf(def)
    if def.iconItem then
        local ic = (GetItemIcon and GetItemIcon(def.iconItem)) or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(def.iconItem))
        if ic then return ic end
    end
    return S.Resolve("@" .. def.icon).icon or 134400
end

function M:Apply()
    if InCombatLockdown and InCombatLockdown() then
        HHT.Print(L("Macros are not possible in combat."))
        return
    end
    local created, updated, failed = 0, 0, 0
    local failedNames = {}
    for _, def in ipairs(DEFS) do
        if self.db.make[def.key] then
            local body, icon = self:Body(def.key), IconOf(def)
            local idx = GetMacroIndexByName and GetMacroIndexByName(def.name) or 0
            local okAll
            if idx and idx > 0 then
                okAll = pcall(EditMacro, idx, def.name, icon, body) or (type(icon) == "string" and pcall(EditMacro, idx, def.name, 134400, body))
                if okAll then updated = updated + 1 end
            else
                local ok, id = pcall(CreateMacro, def.name, icon, body, false)
                if not (ok and id) and type(icon) == "string" then ok, id = pcall(CreateMacro, def.name, 134400, body, false) end
                okAll = ok and id
                if okAll then created = created + 1 end
            end
            if not okAll then failed = failed + 1; failedNames[#failedNames + 1] = def.name end
        end
    end
    HHT.Print(string.format(L("Macros created: %d, updated: %d, failed: %d"), created, updated, failed))
    if failed > 0 then
        local acct, char = 0, 0
        if GetNumMacros then acct, char = GetNumMacros() end
        HHT.Print(L("Failed: ") .. table.concat(failedNames, ", ") .. "  (" .. L("general macros") .. ": " .. tostring(acct) .. "/120)")
    end
end

-- Refreshes only the existing feed macro; returns false while the update has to wait (combat).
function M:UpdateFeed()
    if InCombatLockdown and InCombatLockdown() then return false end
    if not self.db.make.feed then return true end
    local def = DEFS[5]
    local idx = GetMacroIndexByName and GetMacroIndexByName(def.name) or 0
    if idx and idx > 0 then pcall(EditMacro, idx, def.name, IconOf(def), self:Body("feed")) end
    return true
end

function M:Pickup(def)
    local idx = GetMacroIndexByName and GetMacroIndexByName(def.name) or 0
    if not idx or idx == 0 then
        HHT.Print(L("Macro not found. Create the macros first."))
        return
    end
    if pcall(PickupMacro, idx) then HHT.Print(L("Macro on cursor: place it on an action bar.")) end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Pet macros"))
    form:Note(L("Macros are created out of combat. Drag them from the cursor (or the macro window) to an action bar."))
    form:Note(L("General macros (account-wide, 120 slots). Only ticked macros are created."))
    local group
    for _, def in ipairs(DEFS) do
        if def.group ~= group then
            group = def.group
            if group == "hunter" then form:Header(L("Hunter macros")) end
        end
        form:Check(L(def.label) .. "  (" .. def.name .. ")", db.make, def.key)
    end
    form:Text(L("Food item name for Feed Pet"), db, "food")
    form:Button(L("Create or update macros"), function() self:Apply() end, 220)
    form:Header(L("To cursor"))
    for _, def in ipairs(DEFS) do
        form:Button(def.name, function() self:Pickup(def) end, 170)
    end
end
