-- Minimal localisation: English strings are the keys, German overrides live in tables.
local ADDON, HHT = ...

local de = {}
HHT.German = de

function HHT:AddGerman(tbl)
    for k, v in pairs(tbl) do de[k] = v end
end

local es = {}
HHT.Spanish = es

function HHT:AddSpanish(tbl)
    for k, v in pairs(tbl) do es[k] = v end
end

function HHT.CurrentLang()
    local g = HHT.db and HHT.db.general
    local lang = g and g.lang or "auto"
    if lang == "auto" then
        local loc = GetLocale and GetLocale()
        if loc == "deDE" then lang = "de"
        elseif loc == "esES" or loc == "esMX" then lang = "es"
        else lang = "en" end
    end
    return lang
end

-- A translation may hold {spell:ID:fallback}: it becomes the client's own spell name, so the text always matches
-- the spellbook (the Spanish Forever client uses the modern names). The fallback is used if the game gives no name.
local function ClientSpellName(id)
    local n
    if C_Spell and C_Spell.GetSpellName then
        local ok, r = pcall(C_Spell.GetSpellName, id)
        if ok then n = r end
    end
    if (type(n) ~= "string" or n == "") and GetSpellInfo then
        local ok, r = pcall(GetSpellInfo, id)
        if ok then n = r end
    end
    if type(n) == "string" and n ~= "" and not (HHT.IsSecret and HHT.IsSecret(n)) then return n end
end

local expanded = {}
function HHT.ExpandSpells(s)
    if type(s) ~= "string" or not s:find("{spell:", 1, true) then return s end
    local done = expanded[s]
    if done then return done end
    local complete = true
    local result = s:gsub("{spell:(%d+):([^}]*)}", function(id, fallback)
        local n = ClientSpellName(tonumber(id))
        if not n then complete = false; return fallback end
        return n
    end)
    if complete then expanded[s] = result end
    return result
end

-- Hunter pet families by creature family ID. Used to show the client's own family names and, in PetDex,
-- as a last resort to recognise the pet's family in any client language.
HHT.FAMILY_ID = {
    [1] = "Wolf", [2] = "Cat", [3] = "Spider", [4] = "Bear", [5] = "Boar", [6] = "Crocolisk", [7] = "Carrion Bird",
    [8] = "Crab", [9] = "Gorilla", [11] = "Raptor", [12] = "Tallstrider", [20] = "Scorpid", [21] = "Turtle",
    [24] = "Bat", [25] = "Hyena", [26] = "Bird of Prey", [27] = "Wind Serpent", [30] = "Dragonhawk", [31] = "Ravager",
    [32] = "Warp Stalker", [34] = "Nether Ray", [35] = "Serpent", [45] = "Core Hound", [50] = "Fox",
}

function HHT.ClientFamilyName(id)
    local get = C_CreatureInfo and C_CreatureInfo.GetCreatureFamilyInfo
    if not get then return nil end
    local ok, info = pcall(get, id)
    local n = ok and type(info) == "table" and info.name
    if type(n) == "string" and n ~= "" and not (HHT.IsSecret and HHT.IsSecret(n)) then return n end
end

local familyEn, familyShown = {}, nil
for _, en in pairs(HHT.FAMILY_ID) do familyEn[en] = true end
local function FamilyShown(s)
    if not familyShown then
        local map = {}
        for id, en in pairs(HHT.FAMILY_ID) do
            local n = HHT.ClientFamilyName(id)
            if n then map[en] = n end
        end
        -- keep an empty answer only when the API does not exist; otherwise ask again next time
        if next(map) or not (C_CreatureInfo and C_CreatureInfo.GetCreatureFamilyInfo) then familyShown = map else return nil end
    end
    return familyShown[s]
end

function HHT.L(s)
    local lang = HHT.CurrentLang()
    if lang == "de" then return de[s] or s end
    if lang == "es" then
        local t = es[s]
        if not t then return s end
        if familyEn[s] then
            local f = FamilyShown(s)
            if f then return f end
        end
        return HHT.ExpandSpells(t)
    end
    return s
end

HHT:AddGerman({
    -- general
    ["General"] = "Allgemein",
    ["Language"] = "Sprache",
    ["Automatic"] = "Automatisch",
    ["Enabled"] = "Aktiv",
    ["Unlock frames (move with mouse)"] = "Fenster entsperren (mit Maus verschieben)",
    ["Choose which modules can be moved"] = "Wählen, welche Module verschoben werden können",
    ["Movable modules"] = "Verschiebbare Module",
    ["All"] = "Alle",
    ["None"] = "Keine",
    ["Show outline on unlocked frames"] = "Rahmen bei entsperrten Fenstern zeigen",
    ["Minimap button"] = "Minimap-Button",
    ["Tell me about new versions"] = "Auf neue Versionen hinweisen",
    ["Mute all sounds (all modules)"] = "Alle Töne stummschalten (alle Module)",
    ["A newer version (%s) is available on CurseForge. You are using %s."] = "Eine neuere Version (%s) gibt es auf CurseForge. Du nutzt %s.",
    ["Global scale"] = "Globale Größe",
    ["Global opacity"] = "Globale Deckkraft",
    ["Reset all positions"] = "Alle Positionen zurücksetzen",
    ["Reset this module"] = "Dieses Modul zurücksetzen",
    ["Reset position"] = "Position zurücksetzen",
    ["Reload UI"] = "UI neu laden",
    ["Drag to scale, right-click to reset"] = "Ziehen zum Skalieren, Rechtsklick setzt zurück",
    ["Drag to change the height"] = "Ziehen, um die Höhe zu ändern",
    ["Modules"] = "Module",
    ["Combat"] = "Kampf",
    ["Alerts & buffs"] = "Warnungen & Buffs",
    ["Ammo & map"] = "Munition & Karte",
    ["Tools"] = "Werkzeuge",
    ["Settings & support"] = "Einstellungen & Support",
    ["Your toolbox for WoW Forever hunters"] = "Deine Werkzeugkiste für WoW-Forever-Jäger",
    ["Language, colours, look and behaviour of all modules."] = "Sprache, Farben, Aussehen und Verhalten aller Module.",
    ["Switch single modules on or off."] = "Einzelne Module ein- oder ausschalten.",
    ["Reset, reload, export your settings and support the addon."] = "Zurücksetzen, neu laden, Einstellungen exportieren und das Addon unterstützen.",
    ["Module enabled"] = "Modul aktiv",
    ["Appearance"] = "Aussehen",
    ["Behavior"] = "Verhalten",
    ["Colors"] = "Farben",
    ["Position"] = "Position",
    ["Size"] = "Größe",
    ["Scale"] = "Größe",
    ["Opacity"] = "Deckkraft",
    ["Show only in combat"] = "Nur im Kampf zeigen",
    ["Frames are unlocked. Drag them with the left mouse button."] = "Fenster sind entsperrt. Mit linker Maustaste ziehen.",
    ["Frames locked."] = "Fenster gesperrt.",
    ["Frames locked because combat started."] = "Fenster gesperrt, weil der Kampf begonnen hat.",
    ["Positions reset."] = "Positionen zurückgesetzt.",
    ["Hunter only. Addon is inactive on this character."] = "Nur für Jäger. Addon ist bei diesem Charakter inaktiv.",
    ["Open the settings"] = "Einstellungen öffnen",
    ["Left or right click: settings."] = "Links- oder Rechtsklick: Einstellungen.",
    ["Shift + right click: lock/unlock all frames."] = "Shift + Rechtsklick: alle Fenster sperren/entsperren.",
    ["Shift + left click: pet database."] = "Shift + Linksklick: Begleiter-Datenbank.",
    ["Language changes fully apply after /reload."] = "Sprachwechsel greift vollständig nach /reload.",
    ["Settings"] = "Einstellungen",
    ["Support"] = "Unterstützen",
    ["Like the addon? Buy me a coffee. Click the field, press Ctrl+C and paste the link into your browser."] = "Gefällt dir das Addon? Spendier mir einen Kaffee. Feld anklicken, Strg+C drücken und den Link im Browser einfügen.",
    -- shapes / generic choices
    ["Square"] = "Quadrat",
    ["Round"] = "Rund",
    ["Icon shape"] = "Symbolform",
    ["Icon size"] = "Symbolgröße",
    ["Border size"] = "Rahmenstärke",
    ["Border"] = "Rahmen",
    ["Always"] = "Immer",
    ["In combat"] = "Im Kampf",
    ["With target"] = "Mit Ziel",
    ["Combat or target"] = "Kampf oder Ziel",
    ["Show when"] = "Anzeigen wenn",
    ["Right"] = "Rechts",
    ["Left"] = "Links",
    ["Up"] = "Hoch",
    ["Down"] = "Runter",
    ["Grow direction"] = "Wachstumsrichtung",
    ["Spacing"] = "Abstand",
    ["Icons per row"] = "Symbole pro Reihe",
    ["On"] = "An",
    ["Off"] = "Aus",
    ["Background"] = "Hintergrund",
    ["Text"] = "Text",
    ["Text style"] = "Textstil",
    ["Outline"] = "Kontur",
    ["Thick outline"] = "Dicke Kontur",
    ["Plain"] = "Schlicht",
    ["Colour theme"] = "Farbthema",
    ["Bronze"] = "Bronze",
    ["Blue"] = "Blau",
    ["Graphite"] = "Graphit",
    ["Style of icons and bars"] = "Stil von Icons und Balken",
    ["3D frame"] = "3D-Rahmen",
    ["Unlock frame"] = "Fenster entsperren",
    ["All borders: alpha"] = "Alle Rahmen: Deckkraft",
    ["Set key"] = "Taste setzen",
    ["Advanced"] = "Erweitert",
    ["Shows the advanced settings of this section."] = "Zeigt die erweiterten Einstellungen dieses Abschnitts.",
    ["Raid: show or hide for everyone"] = "Raid: für alle ein- oder ausblenden",
    ["Show for everyone"] = "Für alle einblenden",
    ["Hide for everyone"] = "Für alle ausblenden",
    ["You are raid leader or assist"] = "Du bist Raidleiter oder Assistent",
    ["Snap frames to each other while moving"] = "Frames beim Verschieben aneinander einrasten",
    ["Live preview"] = "Live-Vorschau",
    ["Unlock this module (move with mouse)"] = "Dieses Modul entsperren (mit Maus verschieben)",
    ["The colour theme applies after /reload."] = "Das Farbthema gilt nach /reload.",
})
