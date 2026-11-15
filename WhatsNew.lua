-- What's new window: after an update it lists the changes since the last seen version.
-- /hht news opens it any time with the full history below.
local ADDON, HHT = ...
local UI = HHT.UI

HHT:AddGerman({
    ["What's new"] = "Was ist neu",
    ["Version %s"] = "Version %s",
    ["Show this window after updates"] = "Dieses Fenster nach Updates zeigen",
    ["Close"] = "Schliessen",
    ["No notes for this version."] = "Keine Hinweise zu dieser Version.",
    ["Show what's new after an update"] = "Nach einem Update zeigen, was neu ist",
})

-- Release notes, newest first. Keys: v = version, en / de = one line per change.
local NOTES = {
    {
        v = "1.3.0",
        en = {
            "New look: rounded windows and popups with themes, a banner header, tabs and a new icon set (Lucide). Popups adapt their width to their content.",
            "Beast popup (Pet watch): rebuilt with cards for stats, food, what the beast teaches and what the family learns. Food types have icons, and the stats and abilities have tooltips (abilities show the spell tooltip, green when you can learn a higher rank).",
            "Cooldowns: new layouts 'Individual icons' and 'One bar'. Icons are clickable and show the key, a tooltip and a tint when the ability is not usable.",
            "Move mode locks itself when combat starts, so frames with clickable buttons cannot get stuck.",
            "Keys with umlauts (for example the key U with umlaut) can now be bound for clicks. Right-click a key button to clear it.",
            "Pet feeder: the hunger warning now also appears when the pet is only content (yellow), not just unhappy. Can be switched off in the Pet feeder options.",
        },
        de = {
            "Neuer Look: Abgerundete Fenster und Popups mit Themes, Banner-Kopfzeile, Tabs und neuem Icon-Set (Lucide). Popups passen ihre Breite an den Inhalt an.",
            "Tier-Popup (Pet watch): Neu gebaut mit Karten fuer Werte, Futter, was das Tier lehrt und was die Familie lernt. Futterarten haben Icons, Werte und Faehigkeiten haben Tooltips (Faehigkeiten zeigen den Zauber-Tooltip, gruen wenn du einen hoeheren Rang lernen kannst).",
            "Abklingzeiten: Neue Layouts 'Einzelne Icons' und 'Eine Leiste'. Icons sind klickbar und zeigen Taste, Tooltip und eine Faerbung, wenn die Faehigkeit nicht nutzbar ist.",
            "Der Verschieben-Modus sperrt sich automatisch, wenn ein Kampf beginnt, damit Frames mit klickbaren Buttons nicht haengen bleiben.",
            "Tasten mit Umlauten (zum Beispiel Ue) lassen sich jetzt fuer Klicks belegen. Rechtsklick auf einen Tasten-Button loescht die Belegung.",
            "Begleiter-Futter: Die Hunger-Warnung erscheint jetzt auch, wenn der Begleiter nur zufrieden (gelb) ist, nicht erst bei unzufrieden. In den Optionen des Futter-Moduls abschaltbar.",
        },
    },
    {
        v = "1.2.7",
        en = {
            "Pet status: a yellow exclamation mark on the pet portrait shows when beasts in your current zone teach your pet a higher ability rank. Click it to open or close the zone list (greyed out and not clickable in combat). Can be switched off in the Pet status options.",
            "Pet ability alerts: the zone list now also appears after logging in or reloading, not only when you enter a new zone.",
        },
        de = {
            "Begleiter-Status: Ein gelbes Ausrufezeichen am Pet-Portrait zeigt, wenn Tiere in deiner aktuellen Zone deinem Begleiter einen hoeheren Faehigkeitsrang beibringen. Klick oeffnet oder schliesst die Zonenliste (im Kampf ausgegraut und nicht klickbar). In den Optionen des Begleiter-Status abschaltbar.",
            "Begleiter-Faehigkeiten-Hinweis: Die Zonenliste erscheint jetzt auch nach dem Einloggen oder /reload, nicht nur beim Betreten einer neuen Zone.",
        },
    },
    {
        v = "1.2.6",
        en = {
            "Pet training hint: Growl is now included, so you are told when your pet can learn a higher Growl rank.",
        },
        de = {
            "Pet-Training-Hinweis: Knurren (Growl) wird jetzt ebenfalls beruecksichtigt, du wirst benachrichtigt, wenn dein Tier einen hoeheren Knurren-Rang lernen kann.",
        },
    },
    {
        v = "1.2.5",
        en = {
            "Cooldowns: the countdown numbers and the cooldown swipe on the icons are back.",
        },
        de = {
            "Abklingzeiten: Die Zahlen und der Cooldown-Kreis auf den Icons werden wieder angezeigt.",
        },
    },
    {
        v = "1.2.4",
        en = {
            "Warnings: fixed a Lua error when hovering the 'pet low health' icon. The icon no longer catches mouse clicks while it is faded out, so you no longer cast Mend Pet by accident.",
        },
        de = {
            "Warnungen: Lua-Fehler beim Ueberfahren des Icons 'Tier niedrige Gesundheit' behoben. Das ausgeblendete Icon faengt keine Mausklicks mehr ab, damit du nicht versehentlich Tier heilen wirkst.",
        },
    },
    {
        v = "1.2.3",
        en = {
            "Warnings: the 'pet low health' warning works again. The game hides the pet's health from addons, so the icon is now faded in by the game itself when the pet drops below your threshold, in and out of combat.",
            "/hht debug shows what the pet health warning can read.",
        },
        de = {
            "Warnungen: Die Warnung 'Tier niedrige Gesundheit' funktioniert wieder. Das Spiel verbirgt die Gesundheit des Tiers vor Addons, deshalb blendet jetzt das Spiel selbst das Icon ein, sobald das Tier unter deine Schwelle faellt, im und ausserhalb des Kampfs.",
            "/hht debug zeigt, was die Tier-Gesundheitswarnung lesen kann.",
        },
    },
    {
        v = "1.2.2",
        en = {
            "Ammo vendors: positions and wares checked against the latest Questie data for Forever. Fixes vendors that were off the mark (for example in Redridge Mountains), vendors that sell only arrows or only bullets, and adds two missing vendors in Loch Modan and Ashenvale.",
        },
        de = {
            "Munitionshaendler: Positionen und Waren mit den aktuellen Questie-Daten fuer Forever abgeglichen. Behebt falsch eingetragene Haendler (zum Beispiel im Rotkammgebirge), Haendler die nur Pfeile oder nur Kugeln verkaufen, und ergaenzt zwei fehlende Haendler in Loch Modan und Ashenvale.",
        },
    },
    {
        v = "1.2.1",
        en = {
            "Ammo upgrades: better quivers and ammo pouches are no longer suggested when you already wear or carry a better one, and worn quivers are now detected correctly. Ammo you already carry also hides the worse suggestions.",
            "Ammo upgrades: hovering a suggestion shows the item tooltip and where to get it.",
            "Ammo list: damage of Miniature Cannon Balls and the source of Explosive Arrow corrected.",
            "/hht ammo debug prints what the ammo and quiver detection sees.",
        },
        de = {
            "Munitions-Aufwertungen: Bessere Koecher und Munitionsbeutel werden nicht mehr vorgeschlagen, wenn du schon einen besseren traegst oder dabeihast, getragene Koecher werden jetzt richtig erkannt. Auch Munition, die du schon dabeihast, blendet schlechtere Vorschlaege aus.",
            "Munitions-Aufwertungen: Beim Ueberfahren eines Vorschlags erscheint der Gegenstands-Tooltip samt Bezugsquelle.",
            "Munitionsliste: Schaden der Miniature Cannon Balls und Quelle der Explosive Arrow korrigiert.",
            "/hht ammo debug zeigt, was die Munitions- und Koecher-Erkennung sieht.",
        },
    },
    {
        v = "1.2.0",
        en = {
            "New module Aspect and tracking: one button and key each, toggle between two spells, Shift, Ctrl and Alt variants. A small X on the tracking icon turns tracking off.",
            "Ammo: a green arrow appears when better ammo for your level is in your bags. Click it to see and equip the upgrades. It also suggests better quivers (arrows) and ammo pouches (bullets), and engineer-crafted ammo can be switched on.",
            "Pet feeder: feeding now also works with its own key. New warnings when the pet gets unhappy (optional sound) and when pet food runs low. Buff food is no longer picked automatically. With the Pet feeder on, the Warnings module can also show a hungry pet and low food as icons.",
            "Warnings: pet low health (threshold adjustable), hurt pet out of Mend Pet range, and Growl autocast on. A click on the Growl warning switches the autocast off, right-click hides it until reload.",
            "Warnings: Aspect of the Pack in a dungeon or raid is flagged (can be set to every zone). A click switches to your preferred aspect.",
            "Tracking: Find Herbs, Find Minerals, Find Fish and Find Treasure can now be used on the tracking button.",
            "This window: after an update it shows what is new. /hht news opens it any time.",
        },
        de = {
            "Neues Modul Aspekt und Aufspueren: je ein Knopf und eine Taste, Wechsel zwischen zwei Zaubern, Shift-, Strg- und Alt-Varianten. Ein kleines X am Aufspueren-Symbol schaltet es aus.",
            "Munition: ein gruener Pfeil erscheint, wenn bessere Munition fuer deine Stufe in den Taschen liegt. Klick zeigt die Aufwertungen und legt sie an. Er schlaegt auch bessere Koecher (Pfeile) und Munitionsbeutel (Kugeln) vor, Munition von Ingenieuren laesst sich zuschalten.",
            "Tier fuettern: Fuettern geht jetzt auch per eigener Taste. Neue Warnungen, wenn der Begleiter unzufrieden wird (Ton optional) und wenn das Futter knapp wird. Buff-Futter wird nicht mehr automatisch gewaehlt. Bei aktivem Begleiter-Futter zeigt das Warnungen-Modul auch hungrigen Begleiter und knappes Futter als Symbol.",
            "Warnungen: Begleiter verletzt (Schwelle einstellbar), verletzter Begleiter ausser Heilreichweite und Knurren auf Autocast. Ein Klick auf die Knurren-Warnung schaltet den Autocast aus, Rechtsklick blendet sie bis zum Neuladen aus.",
            "Warnungen: Aspekt des Rudels in Dungeon oder Schlachtzug wird gemeldet (auf Wunsch ueberall). Ein Klick wechselt zu deinem bevorzugten Aspekt.",
            "Aufspueren: Kraeuter, Erz, Fische und Schaetze finden lassen sich jetzt auf dem Aufspueren-Knopf nutzen.",
            "Dieses Fenster: nach einem Update zeigt es, was neu ist. /hht news oeffnet es jederzeit.",
        },
    },
    {
        v = "1.1.1",
        en = { "Pet training hint now also works for Great Stamina and Natural Armor." },
        de = { "Der Begleiter-Training-Hinweis greift jetzt auch bei Grosse Ausdauer und Natuerliche Ruestung." },
    },
    {
        v = "1.1.0",
        en = {
            "Pet guide: new Guide tab in the pet database and a one-time hint at level 10.",
            "Zone upgrade list: entering a zone lists all beasts there that teach one of your pets a higher rank.",
            "Rare and wishlist alerts redesigned, with family role, diet, taught abilities and 3D model.",
        },
        de = {
            "Tierratgeber: neuer Ratgeber-Reiter in der Tierdatenbank und ein einmaliger Hinweis auf Stufe 10.",
            "Zonen-Liste: beim Betreten einer Zone werden alle Tiere gelistet, die einem deiner Begleiter einen hoeheren Rang beibringen.",
            "Hinweise zu seltenen und Wunschlisten-Tieren neu gestaltet, mit Familienrolle, Nahrung, lehrbaren Faehigkeiten und 3D-Modell.",
        },
    },
}

local WN = {}
HHT.WhatsNew = WN

local function parse(v)
    if type(v) ~= "string" then return nil end
    local t = {}
    for n in v:gmatch("%d+") do t[#t + 1] = tonumber(n) end
    return #t > 0 and t or nil
end

local function newer(a, b)
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------
local WIDTH, CONTENT_W, MAX_BODY = 470, 442 - 20, 360
local win

local function Window()
    if win then return win end
    local L = HHT.L
    win = UI.Window("HHTWhatsNew", WIDTH, 300, L("What's new") .. " - Hamingway's HunterTools")
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    win:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "HHTWhatsNew") end

    local sf = CreateFrame("ScrollFrame", nil, win)
    sf:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -40)
    sf:SetPoint("TOPRIGHT", win, "TOPRIGHT", -14, -40)
    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(CONTENT_W + 20)
    content:SetHeight(1)
    sf:SetScrollChild(content)
    win.updateBar = UI.ScrollBar(sf, content, 8, 40)
    win.scroll, win.content, win.rows = sf, content, {}

    local chk = UI.Check(win, L("Show this window after updates"),
        function() local g = HHT.db and HHT.db.general; return not (g and g.whatsNew == false) end,
        function(v) if HHT.db then HHT.db.general.whatsNew = v and true or false end end)
    chk:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 12)
    win.chk = chk

    local close = UI.Button(win, 100, 22, L("Close"), function() win:Hide() end)
    close:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 11)
    return win
end

local function Row(i, size)
    local fs = win.rows[i]
    if not fs then
        fs = UI.Text(win.content, "", size)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        win.rows[i] = fs
    end
    if fs:SetFont(UI.FONT, size, "") == false then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
    fs:Show()
    return fs
end

-- entries: list of NOTES entries to show, newest first.
local function Fill(entries)
    local L = HHT.L
    local lang = HHT.CurrentLang()
    local a = UI.ACCENT
    local n, y = 0, 2
    for _, e in ipairs(entries) do
        if y > 2 then y = y + 10 end
        n = n + 1
        local head = Row(n, 13)
        head:SetTextColor(a[1], a[2], a[3])
        head:SetWidth(CONTENT_W)
        head:ClearAllPoints()
        head:SetPoint("TOPLEFT", win.content, "TOPLEFT", 0, -y)
        head:SetText(string.format(L("Version %s"), e.v))
        y = y + head:GetStringHeight() + 5
        local items = e[lang] or e.en or {}
        if #items == 0 then items = { L("No notes for this version.") } end
        for _, line in ipairs(items) do
            n = n + 1
            local fs = Row(n, 12)
            fs:SetTextColor(0.92, 0.94, 0.97)
            fs:SetWidth(CONTENT_W - 14)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", win.content, "TOPLEFT", 14, -y)
            fs:SetText("- " .. line)
            y = y + fs:GetStringHeight() + 4
        end
    end
    for i = n + 1, #win.rows do win.rows[i]:Hide() end
    win.content:SetHeight(y + 4)
    local body = math.min(y + 4, MAX_BODY)
    win.scroll:SetHeight(body)
    win:SetHeight(40 + body + 12 + 44)
    win.scroll:SetVerticalScroll(0)
    win.updateBar()
end

-- entries: NOTES entries to show (newest first) or "all".
function WN.Open(entries)
    local w = Window()
    if entries == "all" then entries = NOTES end
    if not entries or #entries == 0 then entries = { NOTES[1] } end
    Fill(entries)
    w.chk:Refresh()
    w:Show()
end

-- Notes of versions newer than `old` up to the installed version (only the installed one when old is unknown).
local function Pending(old)
    local cur, op = parse(HHT.version), old and parse(old)
    local list = {}
    if not cur then return list end
    for _, e in ipairs(NOTES) do
        local p = parse(e.v)
        if p and not newer(p, cur) and (op and newer(p, op) or (not op and not newer(cur, p))) then
            list[#list + 1] = e
        end
    end
    return list
end

-- ---------------------------------------------------------------------------
-- Login check: opens once per character when the installed version changes.
-- ---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    if not HHT.db then return end
    local g = HHT.db.general
    local old = g.seenVersion
    if old == HHT.version then return end
    g.seenVersion = HHT.version
    if HHT.firstRun or g.whatsNew == false then return end
    local list = Pending(old)
    if #list == 0 then return end
    C_Timer.After(6, function()
        if HHT.db then WN.Open(list) end
    end)
end)
