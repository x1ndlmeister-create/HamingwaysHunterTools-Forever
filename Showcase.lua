-- /hht shot: sets up screenshot scenes (fake warnings, ammo upgrades, demo bars) without needing combat. Nothing is saved.
local ADDON, HHT = ...
local L = HHT.L

HHT:AddGerman({
    ["/hht shot demo [modules]: demo bars without outlines (default: %s)"] = "/hht shot demo [Module]: Demo-Anzeigen ohne Rahmen (Standard: %s)",
    ["/hht shot warnings [keys]: warning row with tooltips (default: %s; more: %s)"] = "/hht shot warnings [Schlüssel]: Warnungsreihe mit Tooltips (Standard: %s; weitere: %s)",
    ["/hht shot ammo [level]: ammo counters with upgrade arrow, click the arrow for the menu (default level 40)"] = "/hht shot ammo [Stufe]: Munitionsanzeige mit Upgrade-Pfeil, Pfeil anklicken für das Menü (Standard Stufe 40)",
    ["/hht shot off: end every scene"] = "/hht shot off: alle Szenen beenden",
    ["Give a value from 0 to 100."] = "Gib einen Wert von 0 bis 100 an.",
    ["Bands: melee dead 10 15 20 25 30 35 max far"] = "Bänder: melee dead 10 15 20 25 30 35 max far",
    ["Give a value from 0 to 100, or melee ranged dead far."] = "Gib einen Wert von 0 bis 100 an, oder melee ranged dead far.",
    ["/hht shot threat|castbar|proc|swing <0-100>, swing melee|ranged|dead|far, distance melee|dead|10..35|max|far: freeze a bar at a value"] = "/hht shot threat|castbar|proc|swing <0-100>, swing melee|ranged|dead|far, distance melee|dead|10..35|max|far: Leiste auf einen Wert festsetzen",
    ["Scene on. /hht shot off ends it."] = "Szene an. /hht shot off beendet sie.",
    ["Scenes ended."] = "Szenen beendet.",
    ["Unknown or disabled module: %s"] = "Unbekanntes oder ausgeschaltetes Modul: %s",
})

local DEMO = { "swing", "castbar", "distance", "threat", "cooldowns", "debuffs", "procs", "summons", "pet", "feeder" }
local WARN_DEFAULT = { "hungry", "foodlow", "pet", "growl", "pack" }
local WARN_KEYS = { "aspect", "trueshot", "mark", "pet", "nopet", "petlow", "petfar", "growl", "pack", "hungry", "foodlow" }

local function Words(text)
    local out = {}
    for w in (text or ""):gmatch("%S+") do out[#out + 1] = w end
    return out
end

local function Refresh()
    HHT:ApplyLock()
    local w, a = HHT.modules.warnings, HHT.modules.ammo
    if w then w.sig = false end
    if a then a.signature = false; a.dirty = true end
end

local function Off()
    HHT.showcase = nil
    HHT.shotValues = nil
    local w, a = HHT.modules.warnings, HHT.modules.ammo
    if w then w.shot = nil end
    if a then a.shot = nil end
    if HHT.AmmoList then HHT.AmmoList.shotLevel = nil end
    Refresh()
end

local BANDS = { melee = "MELEE", dead = "DEAD", max = "MAX", far = "FAR" }
for _, n in ipairs({ 10, 15, 20, 25, 30, 35 }) do BANDS[tostring(n)] = "Y" .. n end
local SWING_STATES = { melee = true, ranged = true, dead = true, far = true }

-- Value scenes: freeze one module at a chosen value so a series of screenshots can become an animation.
local function Value(moduleKey, what, arg)
    local m = HHT.modules[moduleKey]
    if not (m and m.enabled) then HHT.Print(string.format(L("Unknown or disabled module: %s"), moduleKey)) return end
    local pct = tonumber(arg)
    local vals = HHT.shotValues or {}
    if what == "threat" or what == "castbar" or what == "proc" then
        if not pct then HHT.Print(L("Give a value from 0 to 100.")) return end
        vals[what == "castbar" and "cast" or what] = math.max(0, math.min(100, math.floor(pct)))
    elseif what == "distance" then
        if not BANDS[arg or ""] then HHT.Print(L("Bands: melee dead 10 15 20 25 30 35 max far")) return end
        vals.distance = BANDS[arg]
    elseif what == "swing" then
        if pct then
            vals.swingPct = math.max(0, math.min(100, math.floor(pct)))
        elseif SWING_STATES[arg or ""] then
            vals.swing = arg
        else
            HHT.Print(L("Give a value from 0 to 100, or melee ranged dead far.")) return
        end
    end
    HHT.shotValues = vals
    HHT.showcase = HHT.showcase or {}
    HHT.showcase[moduleKey] = true
    Refresh()
end

function HHT.RunShot(what)
    local args = Words(what)
    local cmd = table.remove(args, 1)
    local P = HHT.Print

    if cmd == "off" then
        Off()
        P(L("Scenes ended."))
    elseif cmd == "demo" then
        local keys = #args > 0 and args or DEMO
        HHT.showcase = HHT.showcase or {}
        for _, k in ipairs(keys) do
            local m = HHT.modules[k]
            if m and m.enabled then HHT.showcase[k] = true else P(string.format(L("Unknown or disabled module: %s"), k)) end
        end
        Refresh()
        P(L("Scene on. /hht shot off ends it."))
    elseif cmd == "warnings" then
        local w = HHT.modules.warnings
        if not (w and w.enabled) then P(string.format(L("Unknown or disabled module: %s"), "warnings")) return end
        w.shot = #args > 0 and args or WARN_DEFAULT
        Refresh()
        P(L("Scene on. /hht shot off ends it."))
    elseif cmd == "ammo" then
        local a = HHT.modules.ammo
        if not (a and a.enabled and HHT.AmmoList) then P(string.format(L("Unknown or disabled module: %s"), "ammo")) return end
        HHT.AmmoList.shotLevel = tonumber(args[1]) or 40
        a.shot = { arrow = 1240, bullet = 86 }
        Refresh()
        P(L("Scene on. /hht shot off ends it."))
    elseif cmd == "threat" or cmd == "castbar" or cmd == "distance" or cmd == "swing" or cmd == "proc" then
        Value(cmd == "proc" and "procs" or cmd, cmd, args[1])
    else
        P(string.format(L("/hht shot demo [modules]: demo bars without outlines (default: %s)"), table.concat(DEMO, " ")))
        P(L("/hht shot threat|castbar|proc|swing <0-100>, swing melee|ranged|dead|far, distance melee|dead|10..35|max|far: freeze a bar at a value"))
        P(string.format(L("/hht shot warnings [keys]: warning row with tooltips (default: %s; more: %s)"),
            table.concat(WARN_DEFAULT, " "), table.concat(WARN_KEYS, " ")))
        P(L("/hht shot ammo [level]: ammo counters with upgrade arrow, click the arrow for the menu (default level 40)"))
        P(L("/hht shot off: end every scene"))
    end
end
