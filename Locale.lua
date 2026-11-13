-- Minimal localisation: English strings are the keys, German overrides live in tables.
local ADDON, HHT = ...

local de = {}
HHT.German = de

function HHT:AddGerman(tbl)
    for k, v in pairs(tbl) do de[k] = v end
end

function HHT.CurrentLang()
    local g = HHT.db and HHT.db.general
    local lang = g and g.lang or "auto"
    if lang == "auto" then
        lang = (GetLocale and GetLocale() == "deDE") and "de" or "en"
    end
    return lang
end

function HHT.L(s)
    if HHT.CurrentLang() == "de" then return de[s] or s end
    return s
end

HHT:AddGerman({
    -- general
    ["General"] = "Allgemein",
    ["Language"] = "Sprache",
    ["Automatic"] = "Automatisch",
    ["Enabled"] = "Aktiv",
    ["Unlock frames (move with mouse)"] = "Fenster entsperren (mit Maus verschieben)",
    ["Show outline on unlocked frames"] = "Rahmen bei entsperrten Fenstern zeigen",
    ["Minimap button"] = "Minimap-Button",
    ["Tell me about new versions"] = "Auf neue Versionen hinweisen",
    ["A newer version (%s) is available on CurseForge. You are using %s."] = "Eine neuere Version (%s) gibt es auf CurseForge. Du nutzt %s.",
    ["Global scale"] = "Globale Groesse",
    ["Global opacity"] = "Globale Deckkraft",
    ["Reset all positions"] = "Alle Positionen zuruecksetzen",
    ["Reset this module"] = "Dieses Modul zuruecksetzen",
    ["Reset position"] = "Position zuruecksetzen",
    ["Reload UI"] = "UI neu laden",
    ["Modules"] = "Module",
    ["Module enabled"] = "Modul aktiv",
    ["Appearance"] = "Aussehen",
    ["Behavior"] = "Verhalten",
    ["Colors"] = "Farben",
    ["Position"] = "Position",
    ["Size"] = "Groesse",
    ["Scale"] = "Groesse",
    ["Opacity"] = "Deckkraft",
    ["Show only in combat"] = "Nur im Kampf zeigen",
    ["Frames are unlocked. Drag them with the left mouse button."] = "Fenster sind entsperrt. Mit linker Maustaste ziehen.",
    ["Frames locked."] = "Fenster gesperrt.",
    ["Positions reset."] = "Positionen zurueckgesetzt.",
    ["Hunter only. Addon is inactive on this character."] = "Nur fuer Jaeger. Addon ist bei diesem Charakter inaktiv.",
    ["Open the settings"] = "Einstellungen oeffnen",
    ["Left click: settings. Right click: lock/unlock frames."] = "Linksklick: Einstellungen. Rechtsklick: Fenster sperren/entsperren.",
    ["Shift + left click: pet database."] = "Shift + Linksklick: Begleiter-Datenbank.",
    ["Language changes fully apply after /reload."] = "Sprachwechsel greift vollstaendig nach /reload.",
    ["Settings"] = "Einstellungen",
    ["Support"] = "Unterstuetzen",
    ["Like the addon? Buy me a coffee. Click the field, press Ctrl+C and paste the link into your browser."] = "Gefaellt dir das Addon? Spendier mir einen Kaffee. Feld anklicken, Strg+C druecken und den Link im Browser einfuegen.",
    -- shapes / generic choices
    ["Square"] = "Quadrat",
    ["Round"] = "Rund",
    ["Icon shape"] = "Symbolform",
    ["Icon size"] = "Symbolgroesse",
    ["Border size"] = "Rahmenstaerke",
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
    ["Fill"] = "Fuellen",
    ["Drain"] = "Leeren",
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
    ["Animations"] = "Animationen",
    ["Snap frames to each other while moving (Shift = off)"] = "Frames beim Verschieben aneinander einrasten (Shift = aus)",
    ["Live preview"] = "Live-Vorschau",
    ["Unlock this module (move with mouse)"] = "Dieses Modul entsperren (mit Maus verschieben)",
    ["The colour theme applies after /reload."] = "Das Farbthema gilt nach /reload.",
})
