-- Pet database: abilities, ranks, teaching beasts, search and the "my pet" overview.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI
local Data = HHT.PetData or { abilities = {}, beasts = {} }

HHT:AddGerman({
    ["Pet database"] = "Begleiter-Datenbank",
    ["Pet abilities, ranks, teaching beasts and map pins."] = "Begleiter-Faehigkeiten, Raenge, lehrende Tiere und Kartenpunkte.",
    ["Open pet database"] = "Begleiter-Datenbank oeffnen",
    ["Also opens with /hht pets, Shift+click on the minimap button or a click on the pet portrait."] = "Oeffnet auch mit /hht pets, Shift+Klick auf den Minimap-Button oder Klick auf das Begleiter-Portrait.",
    ["Click the pet portrait to open the database"] = "Klick auf das Begleiter-Portrait oeffnet die Datenbank",
    ["World map"] = "Weltkarte",
    ["Show pins on the world map"] = "Punkte auf der Weltkarte zeigen",
    ["Also show them on the minimap"] = "Auch auf der Minimap zeigen",
    ["Pin size"] = "Punktgroesse",
    ["Remove all pins"] = "Alle Punkte entfernen",
    ["Known ranks"] = "Bekannte Raenge",
    ["Ranks you have learned are read from the Beast Training window and the pet spellbook. Open Beast Training once so they are detected."] = "Gelernte Raenge werden aus dem Fenster Tierausbildung und dem Begleiter-Zauberbuch gelesen. Oeffne die Tierausbildung einmal, damit sie erkannt werden.",
    ["Scan now"] = "Jetzt einlesen",
    ["Forget known ranks"] = "Bekannte Raenge vergessen",
    ["Pet database is disabled."] = "Begleiter-Datenbank ist deaktiviert.",
    -- window
    ["Beasts"] = "Tiere",
    ["Abilities"] = "Faehigkeiten",
    ["My pet"] = "Mein Begleiter",
    ["Search name, family, zone, ability"] = "Suche Name, Familie, Zone, Faehigkeit",
    ["All families"] = "Alle Familien",
    ["All abilities"] = "Alle Faehigkeiten",
    ["Family: %s"] = "Familie: %s",
    ["Ability: %s"] = "Faehigkeit: %s",
    ["Up to my level"] = "Bis zu meinem Level",
    ["New ranks"] = "Neue Raenge",
    ["Rare and elite only"] = "Nur Seltene und Elite",
    ["Reset"] = "Zuruecksetzen",
    ["Name"] = "Name",
    ["Family"] = "Familie",
    ["Level"] = "Level",
    ["Zone"] = "Zone",
    ["Abilities taught"] = "Gelehrte Faehigkeiten",
    ["Known"] = "Bekannt",
    ["Ranks"] = "Raenge",
    ["Levels"] = "Level",
    ["Teachers"] = "Lehrer",
    ["Families"] = "Familien",
    ["Hunter"] = "Jaeger",
    ["Pet"] = "Begleiter",
    ["Next rank"] = "Naechster Rang",
    ["Status"] = "Status",
    ["Show on map"] = "Auf Karte zeigen",
    ["Waypoint"] = "Wegpunkt",
    ["All results on map"] = "Alle Treffer auf Karte",
    ["Clear pins"] = "Punkte entfernen",
    ["3D view"] = "3D-Ansicht",
    ["Show 3D view"] = "3D-Ansicht zeigen",
    ["No 3D model available."] = "Kein 3D-Modell verfuegbar.",
    ["Drag to rotate, mouse wheel to zoom."] = "Ziehen: drehen, Mausrad: zoomen.",
    ["Select a beast first."] = "Waehle zuerst ein Tier.",
    ["No coordinates known for %s."] = "Keine Koordinaten fuer %s bekannt.",
    ["Waypoint set: %s"] = "Wegpunkt gesetzt: %s",
    ["Nothing to show."] = "Nichts anzuzeigen.",
    ["%d of %d"] = "%d von %d",
    ["Click: select.  Mouse wheel: scroll.  Green: teaches a rank you do not know yet."] = "Klick: waehlen.  Mausrad: scrollen.  Gruen: lehrt einen Rang, den du noch nicht kennst.",
    ["Left click: show teachers.  Right click: set the rank you know."] = "Linksklick: Lehrer zeigen.  Rechtsklick: bekannten Rang setzen.",
    ["Click an ability to find beasts that teach it."] = "Klicke eine Faehigkeit, um lehrende Tiere zu finden.",
    ["No pet out. Call your pet to see its abilities."] = "Kein Begleiter da. Rufe deinen Begleiter, um seine Faehigkeiten zu sehen.",
    ["%s (%s), level %s"] = "%s (%s), Level %s",
    ["Free training points: %s"] = "Freie Trainingspunkte: %s",
    ["Speed"] = "Tempo",
    ["Attack speed: %s"] = "Angriffstempo: %s",
    ["Show attack speed"] = "Angriffstempo zeigen",
    ["Color for attack speed under 2 seconds"] = "Farbe fuer Angriffstempo unter 2 Sekunden",
    ["Attack speed is read from the game when you target or point at a beast, so it fills in as you meet them. A value with ~ is the Classic base value and gets replaced once you meet the beast."] = "Das Angriffstempo wird aus dem Spiel gelesen, wenn du ein Tier anvisierst oder darauf zeigst. Die Liste fuellt sich also mit der Zeit. Ein Wert mit ~ ist der Classic-Basiswert und wird ersetzt, sobald du das Tier triffst.",
    ["Maxed"] = "Maximal",
    ["Ready to train"] = "Bereit zum Trainieren",
    ["Needs pet level %d"] = "Braucht Begleiter-Level %d",
    ["Needs %d training points"] = "Braucht %d Trainingspunkte",
    ["Learn rank %d from a beast"] = "Rang %d bei einem Tier lernen",
    ["Not learned"] = "Nicht gelernt",
    ["Rank %d"] = "Rang %d",
    ["Rank %d: pet level %d, %d training points, %d teachers"] = "Rang %d: Begleiter-Level %d, %d Trainingspunkte, %d Lehrer",
    ["Teaches: %s"] = "Lehrt: %s",
    ["You know up to rank %d"] = "Du kennst bis Rang %d",
    ["Diet: %s"] = "Nahrung: %s",
    ["Rare"] = "Selten",
    ["Elite"] = "Elite",
    ["Rare elite"] = "Seltene Elite",
    ["your pet"] = "dein Begleiter",
    ["stable"] = "Stall",
    ["Stable"] = "Stall",
    ["Active"] = "Aktiv",
    ["Last active"] = "Zuletzt aktiv",
    ["In the stable"] = "Im Stall",
    ["Seen out before"] = "Schon benutzt",
    ["Location"] = "Ort",
    ["Open a stable master once to update the list."] = "Oeffne einmal einen Stallmeister, um die Liste zu aktualisieren.",
    ["Click: show beasts of that family."] = "Klick: Tiere dieser Familie zeigen.",
    ["Wishlist"] = "Wunschliste",
    ["Not seen yet"] = "Noch nicht gesehen",
    ["Add to wishlist"] = "Auf die Wunschliste",
    ["Remove from wishlist"] = "Von der Wunschliste",
    ["On wishlist"] = "Auf der Wunschliste",
    ["Seen"] = "Gesehen",
    ["Tamed"] = "Gezaehmt",
    ["Seen %d/%d, tamed %d"] = "Gesehen %d/%d, gezaehmt %d",
    ["Click: select.  Green: new rank.  Gray icon: not seen.  + tamed  * wishlist"] = "Klick: waehlen.  Gruen: neuer Rang.  Graues Symbol: nicht gesehen.  + gezaehmt  * Wunschliste",
    ["Discovery"] = "Entdeckungsstand",
    ["Beasts are marked as seen when you target them or point at them, and as tamed after you tame them. Wishlist entries alert you when you see them."] = "Tiere gelten als gesehen, wenn du sie anvisierst oder mit der Maus darauf zeigst, und als gezaehmt, nachdem du sie gezaehmt hast. Tiere auf der Wunschliste loesen einen Hinweis aus, sobald du sie siehst.",
    ["Forget seen and tamed beasts"] = "Gesehene und gezaehmte Tiere vergessen",
    ["Clear wishlist"] = "Wunschliste leeren",
    ["All"] = "Alle",
    -- families
    ["Bat"] = "Fledermaus",
    ["Bear"] = "Baer",
    ["Boar"] = "Eber",
    ["Carrion Bird"] = "Aasvogel",
    ["Cat"] = "Katze",
    ["Crab"] = "Krebs",
    ["Crocolisk"] = "Krokilisk",
    ["Dragonhawk"] = "Drachenfalke",
    ["Fox"] = "Fuchs",
    ["Gorilla"] = "Gorilla",
    ["Hyena"] = "Hyaene",
    ["Nether Ray"] = "Netherrochen",
    ["Raptor"] = "Raptor",
    ["Ravager"] = "Zerstoerer",
    ["Scorpid"] = "Skorpid",
    ["Serpent"] = "Schlange",
    ["Spider"] = "Spinne",
    ["Tallstrider"] = "Weitschreiter",
    ["Turtle"] = "Schildkroete",
    ["Warp Stalker"] = "Warpwandler",
    ["Wind Serpent"] = "Windnatter",
    ["Wolf"] = "Wolf",
    ["Bird of Prey"] = "Raubvogel",
})

local M = HHT:NewModule("petdex", {
    name = "Pet database",
    desc = "Pet abilities, ranks, teaching beasts and map pins.",
    noFrame = true,
    defaults = {
        openOnClick = true, pins = true, minimap = true, pinSize = 20, showModel = true,
        showSpeed = true, speedColor = { 0.3, 0.9, 1 }, speed = {},
        sort = "name", sortDesc = false,
        known = {}, pets = {}, seen = {}, tamed = {}, wish = {}, stable = {},
    },
})

local PD = {}
HHT.PetDex = PD
PD.module = M

local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local FAMILY_ICON = {
    ["Bat"] = "Ability_Hunter_Pet_Bat", ["Bear"] = "Ability_Hunter_Pet_Bear", ["Boar"] = "Ability_Hunter_Pet_Boar",
    ["Bird of Prey"] = "Ability_Hunter_Pet_Owl", ["Carrion Bird"] = "Ability_Hunter_Pet_Vulture",
    ["Cat"] = "Ability_Hunter_Pet_Cat", ["Crab"] = "Ability_Hunter_Pet_Crab", ["Crocolisk"] = "Ability_Hunter_Pet_Crocolisk",
    ["Dragonhawk"] = "Ability_Hunter_Pet_DragonHawk", ["Fox"] = "Ability_Hunter_Pet_Fox",
    ["Gorilla"] = "Ability_Hunter_Pet_Gorilla", ["Hyena"] = "Ability_Hunter_Pet_Hyena",
    ["Nether Ray"] = "Ability_Hunter_Pet_NetherRay", ["Raptor"] = "Ability_Hunter_Pet_Raptor",
    ["Ravager"] = "Ability_Hunter_Pet_Ravager", ["Scorpid"] = "Ability_Hunter_Pet_Scorpid",
    ["Serpent"] = "Spell_Nature_GuardianWard", ["Spider"] = "Ability_Hunter_Pet_Spider",
    ["Tallstrider"] = "Ability_Hunter_Pet_Tallstrider", ["Turtle"] = "Ability_Hunter_Pet_Turtle",
    ["Warp Stalker"] = "Ability_Hunter_Pet_WarpStalker", ["Wind Serpent"] = "Ability_Hunter_Pet_WindSerpent",
    ["Wolf"] = "Ability_Hunter_Pet_Wolf",
}
local FAMILY_DE = {
    fledermaus = "Bat", baer = "Bear", eber = "Boar", aasvogel = "Carrion Bird", katze = "Cat", krebs = "Crab",
    krokilisk = "Crocolisk", drachenfalke = "Dragonhawk", fuchs = "Fox", gorilla = "Gorilla", hyaene = "Hyena",
    netherrochen = "Nether Ray", raptor = "Raptor", zerstoerer = "Ravager", skorpid = "Scorpid", schlange = "Serpent",
    spinne = "Spider", weitschreiter = "Tallstrider", schildkroete = "Turtle", warpwandler = "Warp Stalker",
    windnatter = "Wind Serpent", wolf = "Wolf", raubvogel = "Bird of Prey",
}

-- Lower case, umlauts to ae/oe/ue/ss, so typed text and client names compare in plain ASCII.
local function Fold(s)
    s = tostring(s or ""):lower()
    s = s:gsub("\195\164", "ae"):gsub("\195\182", "oe"):gsub("\195\188", "ue"):gsub("\195\159", "ss")
    s = s:gsub("\195\132", "ae"):gsub("\195\150", "oe"):gsub("\195\156", "ue")
    return s
end
PD.Fold = Fold

-- ---------------------------------------------------------------------------
-- Index
-- ---------------------------------------------------------------------------
local abilities, byKey, beasts, byId, rankSpell, families = {}, {}, {}, {}, {}, {}
local famEn = { ["birds of prey"] = "Bird of Prey" }
PD.abilities, PD.byKey, PD.beasts, PD.byId, PD.families = abilities, byKey, beasts, byId, families

for _, a in ipairs(Data.abilities) do
    abilities[#abilities + 1] = a
    byKey[a.key] = a
    a.famSet, a.byRank = {}, {}
    for _, f in ipairs(a.families) do a.famSet[f] = true; famEn[Fold(f)] = f end
    a.all = (#a.families == 0)
    a.maxRank = 0
    for _, r in ipairs(a.ranks) do
        a.byRank[r.rank] = r
        if r.rank > a.maxRank then a.maxRank = r.rank end
        rankSpell[r.spell] = { a, r.rank }
    end
end
table.sort(abilities, function(x, y) return x.name < y.name end)

do
    local seen = {}
    for id, b in pairs(Data.beasts) do
        b.id = id
        local lo, hi = tostring(b.l):match("(%d+)%-?(%d*)")
        b.lo = tonumber(lo) or 0
        b.hi = tonumber(hi) or b.lo
        beasts[#beasts + 1] = b
        byId[id] = b
        if not seen[b.f] then seen[b.f] = true; families[#families + 1] = b.f; famEn[Fold(b.f)] = b.f end
    end
    table.sort(beasts, function(x, y)
        if x.n ~= y.n then return x.n < y.n end
        return x.id < y.id
    end)
    table.sort(families)
end

function PD.EnglishFamily(name)
    if type(name) ~= "string" or HHT.IsSecret(name) then return nil end
    local f = Fold(name)
    return famEn[f] or FAMILY_DE[f]
end

function PD.FamilyIcon(f)
    return "Interface\\Icons\\" .. (FAMILY_ICON[f] or "Ability_Hunter_BeastTaming")
end

local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then
        local ok, n = pcall(C_Spell.GetSpellName, id)
        if ok and type(n) == "string" and not HHT.IsSecret(n) then return n end
    end
    if GetSpellInfo then
        local ok, n = pcall(GetSpellInfo, id)
        if ok and type(n) == "string" and not HHT.IsSecret(n) then return n end
    end
end

local function SpellTexture(id)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, t = pcall(C_Spell.GetSpellTexture, id)
        if ok and t then return t end
    end
    if GetSpellTexture then
        local ok, t = pcall(GetSpellTexture, id)
        if ok and t then return t end
    end
end

local nameCache, iconCache = {}, {}
function PD.AbilityName(a)
    if nameCache[a.key] then return nameCache[a.key] end
    local n = a.ranks[1] and SpellName(a.ranks[1].spell)
    if n then nameCache[a.key] = n; return n end
    return a.name
end

function PD.AbilityIcon(a)
    if iconCache[a.key] then return iconCache[a.key] end
    for _, r in ipairs(a.ranks) do
        local t = SpellTexture(r.spell)
        if t then iconCache[a.key] = t; return t end
    end
    return FALLBACK_ICON
end

function PD.FamilyAbilities(fam)
    local out = {}
    for _, a in ipairs(abilities) do
        if a.all or a.famSet[fam] then out[#out + 1] = a end
    end
    return out
end

function PD.Applies(a, fams)
    for fam in pairs(fams) do
        if a.all or a.famSet[fam] then return true end
    end
    return false
end

function PD.BeastAbilities(b)
    if not b.abl then
        local t = {}
        for key, rank in pairs(b.ab or {}) do
            local a = byKey[key]
            if a then t[#t + 1] = { a = a, rank = rank } end
        end
        table.sort(t, function(x, y) return x.a.name < y.a.name end)
        b.abl = t
    end
    return b.abl
end

function PD.ZoneName(b)
    if b.zn then return b.zn end
    local name
    if b.a and C_Map and C_Map.GetAreaInfo then
        local ok, n = pcall(C_Map.GetAreaInfo, b.a)
        if ok and type(n) == "string" and n ~= "" then name = n end
    end
    if not name and b.sp and C_Map and C_Map.GetMapInfo then
        local map = next(b.sp)
        local ok, info = pcall(C_Map.GetMapInfo, map)
        if ok and type(info) == "table" and type(info.name) == "string" then name = info.name end
    end
    name = name or b.z
    if name then b.zn = name; return name end
    return "?"
end

function PD.RarityLabel(b)
    if b.r == "rare" then return L("Rare") end
    if b.r == "rareelite" then return L("Rare elite") end
    if b.r == "elite" then return L("Elite") end
end

local RARITY_COLOR = { rare = { 0.45, 0.75, 1 }, elite = { 1, 0.82, 0.3 }, rareelite = { 0.75, 0.55, 1 } }

-- ---------------------------------------------------------------------------
-- Known ranks (per character)
-- ---------------------------------------------------------------------------
local function Note(key, rank)
    local k = M.db and M.db.known
    if not k or not key or not rank then return false end
    if (k[key] or 0) < rank then k[key] = rank; return true end
    return false
end

function PD.KnownRank(key)
    return (M.db and M.db.known[key]) or 0
end

function PD.SetKnownRank(key, rank)
    if M.db then M.db.known[key] = (rank and rank > 0) and rank or nil end
end

local function SpellKnown(id)
    if IsPlayerSpell and HHT.SafeBool(IsPlayerSpell, id) then return true end
    if IsSpellKnown then
        if HHT.SafeBool(IsSpellKnown, id) then return true end
        if HHT.SafeBool(IsSpellKnown, id, true) then return true end
    end
    return false
end

local function RankFrom(sub)
    return tonumber(type(sub) == "string" and sub:match("(%d+)") or nil)
end

local function NameKeys()
    local map = {}
    for _, a in ipairs(abilities) do
        map[Fold(a.name)] = a.key
        map[Fold(PD.AbilityName(a))] = a.key
    end
    return map
end

function PD.ScanSpells()
    local changed = false
    for id, hit in pairs(rankSpell) do
        if SpellKnown(id) and Note(hit[1].key, hit[2]) then changed = true end
    end
    return changed
end

local function PetBook()
    local out = {}
    local count
    if C_SpellBook and C_SpellBook.HasPetSpells then
        local ok, n = pcall(C_SpellBook.HasPetSpells)
        if ok and type(n) == "number" then count = n end
    end
    if not count and HasPetSpells then
        local ok, n = pcall(HasPetSpells)
        if ok and type(n) == "number" then count = n end
    end
    if not count or count == 0 then return out end
    local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) or "pet"
    for i = 1, count do
        local name, sub, id
        if C_SpellBook and C_SpellBook.GetSpellBookItemName then
            local ok, n, s = pcall(C_SpellBook.GetSpellBookItemName, i, bank)
            if ok then name, sub = n, s end
        end
        if not name and GetSpellBookItemName then
            local ok, n, s = pcall(GetSpellBookItemName, i, "pet")
            if ok then name, sub = n, s end
        end
        if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
            local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, i, bank)
            if ok and type(info) == "table" then id = info.spellID or info.actionID end
        end
        if type(name) == "string" and not HHT.IsSecret(name) then
            out[#out + 1] = { name = name, sub = sub, id = type(id) == "number" and id or nil }
        end
    end
    return out
end

-- /hht petinfo: shows what the game exposes about the pet and the target (spellbook, auras, speed).
function PD.Inspect()
    local P = HHT.Print
    for _, unit in ipairs({ "pet", "target" }) do
        if HHT.SafeBool(UnitExists, unit) == true then
            local n = UnitName(unit)
            local sp = UnitAttackSpeed and HHT.SafeNumber(UnitAttackSpeed(unit))
            P(string.format("[%s] %s speed=%s", unit, HHT.IsSecret(n) and "?" or tostring(n), tostring(sp)))
            local auras = 0
            for i = 1, 40 do
                local name, id
                if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                    local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
                    if ok and type(a) == "table" then name, id = a.name, a.spellId end
                elseif UnitAura then
                    local ok, n2, _, _, _, _, _, _, _, _, sid = pcall(UnitAura, unit, i, "HELPFUL")
                    if ok then name, id = n2, sid end
                end
                if not name then break end
                if not HHT.IsSecret(name) then P("  aura " .. tostring(name) .. " id=" .. tostring(id)) end
                auras = auras + 1
            end
            if auras == 0 then P("  no buffs") end
        end
    end
    if HHT.SafeBool(UnitExists, "pet") ~= true then P("No pet out: spellbook not readable."); return end
    local book = PetBook()
    P("Pet spellbook: " .. #book .. " entries")
    for i, e in ipairs(book) do
        local passive
        if IsPassiveSpell then
            local ok, v = pcall(IsPassiveSpell, i, "pet")
            if ok then passive = v and true or false end
        end
        P(string.format("  %d %s (%s) id=%s passive=%s", i, e.name, tostring(e.sub or ""), tostring(e.id), tostring(passive)))
    end
end

-- Reads the active pet's spellbook; remembers the highest ranks and returns key -> rank.
function PD.ScanBook()
    local keys = NameKeys()
    local ranks = {}
    for _, e in ipairs(PetBook()) do
        local hit = e.id and rankSpell[e.id]
        local key, rank
        if hit then
            key, rank = hit[1].key, hit[2]
        else
            key = keys[Fold(e.name)]
            rank = RankFrom(e.sub) or 1
        end
        if key and rank then
            if (ranks[key] or 0) < rank then ranks[key] = rank end
        end
    end
    PD.petRanks = ranks
    return ranks
end

PD.SpellName, PD.NameKeys, PD.RankFrom = SpellName, NameKeys, RankFrom

function PD.PetBookCount() return #PetBook() end

-- True while the open craft window is the Beast Training window.
function PD.CraftIsBeast()
    if not (GetNumCrafts and GetCraftInfo) then return false end
    local line = GetCraftDisplaySkillLine and GetCraftDisplaySkillLine()
    if type(line) == "string" and not HHT.IsSecret(line) then
        local own = SpellName(5149)
        if line ~= "Beast Training" and line ~= own and line ~= BEAST_TRAINING then return false end
    end
    return true
end

function PD.ScanCraft()
    if not PD.CraftIsBeast() then return false end
    local keys = NameKeys()
    local changed = false
    for i = 1, (GetNumCrafts() or 0) do
        local name, sub, kind = GetCraftInfo(i)
        if type(name) == "string" and kind ~= "header" then
            local key = keys[Fold(name)]
            if key and Note(key, RankFrom(sub) or 1) then changed = true end
        end
    end
    return changed
end

-- ---------------------------------------------------------------------------
-- The player's pets
-- ---------------------------------------------------------------------------
function PD.PetInfo()
    local ok, ex = pcall(UnitExists, "pet")
    if not ok or HHT.IsSecret(ex) or not ex then return nil end
    local name = UnitName("pet")
    if HHT.IsSecret(name) then name = nil end
    local raw = UnitCreatureFamily and UnitCreatureFamily("pet")
    local info = {
        name = name, family = PD.EnglishFamily(raw), familyName = (type(raw) == "string" and not HHT.IsSecret(raw)) and raw or nil,
        level = HHT.SafeNumber(UnitLevel("pet")),
    }
    if HHT.PetCall then
        local total, spent = HHT.PetCall("GetPetTrainingPoints")
        total, spent = HHT.SafeNumber(total), HHT.SafeNumber(spent)
        if total then info.points = total - (spent or 0) end
    end
    return info
end

function PD.Remember()
    local info = PD.PetInfo()
    if info and info.family and M.db then M.db.pets[info.family] = info.name or "?" end
end

-- family -> pet name. Remembered pets are the ones seen out before or read at a stable master.
function PD.MyFamilies(includeRemembered)
    local fams = {}
    local info = PD.PetInfo()
    if info and info.family then fams[info.family] = info.name or L("your pet") end
    if includeRemembered and M.db then
        for _, e in ipairs(M.db.stable) do
            if e.fam and not fams[e.fam] then fams[e.fam] = e.name .. ", " .. L("stable") end
        end
        for fam, name in pairs(M.db.pets) do
            if not fams[fam] then fams[fam] = tostring(name) .. ", " .. L("stable") end
        end
    end
    return fams
end

-- ---------------------------------------------------------------------------
-- Discovery and wishlist (per character, keyed by NPC id)
-- ---------------------------------------------------------------------------
function PD.IsSeen(id) return M.db ~= nil and M.db.seen[id] ~= nil end
function PD.IsTamed(id) return M.db ~= nil and M.db.tamed[id] ~= nil end
function PD.IsWish(id) return M.db ~= nil and M.db.wish[id] ~= nil end

-- Attack speed per NPC id, read from the unit while it is out of combat (buffs and slows would skew it).
function PD.RecordSpeed(id, unit)
    if not (M.db and id and UnitAttackSpeed) then return end
    if HHT.SafeBool(UnitAffectingCombat, unit) ~= false then return end
    local ok, v = pcall(UnitAttackSpeed, unit)
    v = ok and HHT.SafeNumber(v)
    if v and v >= 0.5 and v <= 5 then M.db.speed[id] = math.floor(v * 100 + 0.5) / 100 end
end

-- Measured value first, then the Classic base table; the second return is true when it is only the base value.
function PD.Speed(id)
    local v = M.db and M.db.speed[id]
    if v then return v, false end
    v = HHT.PetSpeedBase and HHT.PetSpeedBase[id]
    if v then return v, true end
end

function PD.SpeedText(id)
    local v, base = PD.Speed(id)
    if not v then return "|cff808080?|r" end
    local s = string.format("%.2f", v)
    if s:sub(-1) == "0" then s = s:sub(1, -2) end
    if base then s = "~" .. s end
    if v < 1.995 then
        local c = M.db.speedColor
        return string.format("|cff%02x%02x%02x%s|r", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5), s)
    end
    return s
end

-- Returns true when the beast was not known as seen before.
function PD.MarkSeen(id)
    if not M.db or not byId[id] or M.db.seen[id] then return false end
    M.db.seen[id] = true
    PD.Dirty()
    return true
end

function PD.MarkTamed(id)
    if not M.db or not byId[id] or M.db.tamed[id] then return false end
    M.db.tamed[id], M.db.seen[id] = true, true
    PD.Dirty()
    return true
end

function PD.SetWish(id, on)
    if not M.db or not byId[id] then return end
    M.db.wish[id] = on and true or nil
    PD.Dirty()
end

-- seen, tamed, total
function PD.Progress()
    local s, t = 0, 0
    if M.db then
        for id in pairs(M.db.seen) do if byId[id] then s = s + 1 end end
        for id in pairs(M.db.tamed) do if byId[id] then t = t + 1 end end
    end
    return s, t, #beasts
end

function PD.StatusText(b)
    local parts = {}
    if PD.IsTamed(b.id) then parts[1] = L("Tamed") elseif PD.IsSeen(b.id) then parts[1] = L("Seen") else parts[1] = L("Not seen yet") end
    if PD.IsWish(b.id) then parts[#parts + 1] = L("On wishlist") end
    return table.concat(parts, ", ")
end

-- ---------------------------------------------------------------------------
-- Stable (readable only while a stable master is open, so it is remembered)
-- ---------------------------------------------------------------------------
local function StableSlot(i)
    if C_StableInfo and C_StableInfo.GetStablePetInfo then
        local ok, t = pcall(C_StableInfo.GetStablePetInfo, i)
        if ok and type(t) == "table" then return t.name, t.familyName, t.level end
    end
    if GetStablePetInfo then
        local ok, _, name, level, family = pcall(GetStablePetInfo, i)
        if ok then return name, family, level end
    end
end

function PD.ScanStable()
    if not M.db then return false end
    local out = {}
    for i = 0, 19 do
        local name, family, level = StableSlot(i)
        if type(name) == "string" and name ~= "" and not HHT.IsSecret(name) then
            out[#out + 1] = { name = name, fam = PD.EnglishFamily(family), level = HHT.SafeNumber(level), slot0 = (i == 0) or nil }
        end
    end
    if #out == 0 then return false end
    M.db.stable = out
    -- The stable master's list is authoritative: forget remembered pets that are gone (released).
    local names = {}
    for _, e in ipairs(out) do names[e.name] = true end
    for fam, name in pairs(M.db.pets) do
        if not names[name] then M.db.pets[fam] = nil end
    end
    PD.Dirty()
    return true
end

-- Best rank this beast teaches that the hunter does not know yet and one of the pets can use.
function PD.NewRank(b, fams, ignored)
    local best
    for _, e in ipairs(PD.BeastAbilities(b)) do
        local known = PD.KnownRank(e.a.key)
        if e.rank > 0 and e.rank > known and not (ignored and ignored[e.a.key]) then
            local fits
            for fam, who in pairs(fams) do
                if e.a.all or e.a.famSet[fam] then
                    fits = fits or {}
                    fits[#fits + 1] = L(fam) .. " (" .. who .. ")"
                end
            end
            if fits and (not best or e.rank > best.rank) then
                table.sort(fits)
                best = { a = e.a, rank = e.rank, known = known, fits = fits }
            end
        end
    end
    return best
end

-- Best rank this beast teaches that the active pet does not have yet (whatever the hunter already knows).
function PD.PetGap(b, ignored)
    local info = PD.PetInfo()
    if not info or not info.family then return nil end
    local ranks = PD.petRanks or PD.ScanBook()
    local best
    for _, e in ipairs(PD.BeastAbilities(b)) do
        local pet = ranks[e.a.key] or 0
        if e.rank > 0 and e.rank > pet and (e.a.all or e.a.famSet[info.family]) and not (ignored and ignored[e.a.key]) then
            if not best or e.rank > best.rank then
                best = { a = e.a, rank = e.rank, known = pet, petGap = true, fits = { L(info.family) .. " (" .. (info.name or L("your pet")) .. ")" } }
            end
        end
    end
    return best
end

-- ---------------------------------------------------------------------------
-- Search
-- ---------------------------------------------------------------------------
local function Hay(b)
    if not b.hay then
        local parts = { b.n, b.f, L(b.f), PD.ZoneName(b), b.z or "" }
        for _, e in ipairs(PD.BeastAbilities(b)) do
            parts[#parts + 1] = e.a.name
            parts[#parts + 1] = PD.AbilityName(e.a)
        end
        b.hay = Fold(table.concat(parts, " "))
    end
    return b.hay
end

-- filter: text, family, ability (key), myLevel, newRanks, rare
function PD.Query(filter)
    local out, tokens = {}, {}
    for w in Fold(filter.text or ""):gmatch("%S+") do tokens[#tokens + 1] = w end
    local plevel = tonumber(UnitLevel("player")) or 60
    local fams = filter.newRanks and PD.MyFamilies(true)
    for _, b in ipairs(beasts) do
        local ok = true
        if filter.family and b.f ~= filter.family then ok = false end
        if ok and filter.ability and not (b.ab and b.ab[filter.ability]) then ok = false end
        if ok and filter.myLevel and b.lo > plevel then ok = false end
        if ok and filter.rare and not b.r then ok = false end
        if ok and filter.wish and not PD.IsWish(b.id) then ok = false end
        if ok and filter.unseen and PD.IsSeen(b.id) then ok = false end
        if ok and fams and not PD.NewRank(b, fams) then ok = false end
        if ok and #tokens > 0 then
            local h = Hay(b)
            for _, w in ipairs(tokens) do
                if not h:find(w, 1, true) then ok = false; break end
            end
        end
        if ok then out[#out + 1] = b end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------
local ROWS, ROW_H = 14, 24
local W, H = 800, 530
local win
local filter = {}

local function AbilityText(b, fams)
    local parts = {}
    for _, e in ipairs(PD.BeastAbilities(b)) do
        local s = PD.AbilityName(e.a)
        if e.rank > 0 then s = s .. " " .. e.rank end
        if e.rank > 0 then
            if e.rank > PD.KnownRank(e.a.key) and PD.Applies(e.a, fams) then s = "|cff66ee66" .. s .. "|r"
            elseif e.rank <= PD.KnownRank(e.a.key) then s = "|cff8a8a8a" .. s .. "|r" end
        end
        parts[#parts + 1] = s
    end
    return table.concat(parts, ", ")
end

local function BeastTip(row, b)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    local c = RARITY_COLOR[b.r] or { 1, 1, 1 }
    GameTooltip:AddLine(b.n, c[1], c[2], c[3])
    local rl = PD.RarityLabel(b)
    GameTooltip:AddLine(L(b.f) .. ", " .. L("Level") .. " " .. b.l .. (rl and (", " .. rl) or ""), 0.9, 0.9, 0.9)
    GameTooltip:AddLine(PD.ZoneName(b), 0.7, 0.7, 0.7)
    if M.db.showSpeed then GameTooltip:AddLine(string.format(L("Attack speed: %s"), PD.SpeedText(b.id)), 0.9, 0.9, 0.9) end
    GameTooltip:AddLine(PD.StatusText(b), 1, 0.82, 0.3)
    if b.d and b.d ~= "" then GameTooltip:AddLine(string.format(L("Diet: %s"), b.d), 0.7, 0.7, 0.7) end
    for _, e in ipairs(PD.BeastAbilities(b)) do
        local line = PD.AbilityName(e.a)
        if e.rank > 0 then
            local r = e.a.byRank[e.rank]
            line = line .. " " .. string.format(L("Rank %d"), e.rank)
            if r then line = line .. " (" .. L("Level") .. " " .. r.level .. ")" end
            local known = PD.KnownRank(e.a.key)
            if known > 0 then line = line .. "  -  " .. string.format(L("You know up to rank %d"), known) end
        end
        GameTooltip:AddLine(line, 0.67, 0.83, 0.45)
    end
    GameTooltip:Show()
end

local function AbilityTip(row, a)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:AddLine(PD.AbilityName(a), 0.67, 0.83, 0.45)
    local known = PD.KnownRank(a.key)
    for _, r in ipairs(a.ranks) do
        local g = (r.rank <= known) and 0.45 or 0.9
        GameTooltip:AddLine(string.format(L("Rank %d: pet level %d, %d training points, %d teachers"), r.rank, r.level, r.cost, #r.npcs), g + 0.2, 0.9, g)
    end
    local fl = {}
    for _, f in ipairs(a.families) do fl[#fl + 1] = L(f) end
    GameTooltip:AddLine(a.all and L("All") or table.concat(fl, ", "), 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end

local TABS = {}
local TAB_ORDER = { "beasts", "abilities", "pet", "stable" }

-- 3D preview panel on the right side of the window
local function BuildView()
    local p = CreateFrame("Frame", nil, win)
    p:SetSize(250, H)
    p:SetPoint("TOPLEFT", win, "TOPRIGHT", 4, 0)
    local bg = p:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.075, 0.068, 0.055, 0.96)
    UI.Border(p, 0.67, 0.83, 0.45, 0.9)
    p.name = UI.Header(p, "")
    p.name:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -12)
    p.name:SetWidth(226)
    p.name:SetJustifyH("LEFT")
    p.name:SetWordWrap(false)
    local inset = p:CreateTexture(nil, "BORDER")
    inset:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -34)
    inset:SetSize(230, 300)
    inset:SetColorTexture(0.03, 0.028, 0.024, 1)
    local m = CreateFrame("PlayerModel", nil, p)
    m:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -34)
    m:SetSize(230, 300)
    m.zoom, m.facing = 1, 0
    m:EnableMouse(true)
    m:EnableMouseWheel(true)
    m:SetScript("OnMouseDown", function(self) self.dragX, self.dragF = GetCursorPosition(), self.facing end)
    m:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    m:SetScript("OnUpdate", function(self)
        if not self.dragX then return end
        self.facing = self.dragF + (GetCursorPosition() - self.dragX) / 80
        pcall(self.SetFacing, self, self.facing)
    end)
    m:SetScript("OnMouseWheel", function(self, delta)
        self.zoom = math.max(0.4, math.min(2.5, self.zoom - delta * 0.15))
        pcall(self.SetCamDistanceScale, self, self.zoom)
    end)
    p.model = m
    p.msg = UI.Text(p, "", 12, 0.7, 0.7, 0.7)
    p.msg:SetPoint("CENTER", inset, "CENTER", 0, 0)
    p.msg:SetWidth(200)
    p.line1 = UI.Text(p, "", 12, 0.92, 0.94, 0.97)
    p.line1:SetPoint("TOPLEFT", inset, "BOTTOMLEFT", 2, -8)
    p.line2 = UI.Text(p, "", 12, 0.7, 0.7, 0.7)
    p.line2:SetPoint("TOPLEFT", p.line1, "BOTTOMLEFT", 0, -4)
    p.abil = UI.Text(p, "", 11, 0.92, 0.94, 0.97)
    p.abil:SetPoint("TOPLEFT", p.line2, "BOTTOMLEFT", 0, -8)
    p.abil:SetWidth(226)
    p.abil:SetJustifyH("LEFT")
    p.abil:SetWordWrap(true)
    local hint = UI.Text(p, L("Drag to rotate, mouse wheel to zoom."), 10, 0.5, 0.5, 0.5)
    hint:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 12, 10)
    win.view = p
end

local function SetModel(p, key, apply)
    if p.key == key then return end
    p.key = key
    local m = p.model
    m.facing, m.zoom = 0, 1
    local tries = 0
    local function Load()
        pcall(m.ClearModel, m)
        local ok = pcall(apply, m)
        pcall(m.SetFacing, m, m.facing)
        pcall(m.SetCamDistanceScale, m, m.zoom)
        if not ok then p.msg:SetText(L("No 3D model available.")); return end
        -- the client loads an unseen creature late; setting it again once it is cached shows it
        local okF, file = pcall(m.GetModelFileID, m)
        if okF and not file and tries < 12 and C_Timer and C_Timer.After then
            tries = tries + 1
            p.msg:SetText("...")
            C_Timer.After(0.4, function() if p.key == key and p:IsShown() then Load() end end)
        else
            p.msg:SetText((okF and not file) and L("No 3D model available.") or "")
        end
    end
    Load()
end

local function UpdateModel()
    local p = win and win.view
    if not p then return end
    local show = M.db.showModel and win.tab ~= "abilities" and win.tab ~= "stable"
    p:SetShown(show and true or false)
    if not show then return end
    local m = p.model
    if win.tab == "pet" then
        local info = PD.PetInfo()
        m:SetShown(info and true or false)
        p.abil:SetText("")
        p.line2:SetText("")
        if not info then
            p.key = nil
            p.name:SetText("")
            p.line1:SetText("")
            p.msg:SetText(L("No pet out. Call your pet to see its abilities."))
            return
        end
        SetModel(p, "pet:" .. tostring(info.name) .. tostring(info.family), function(mod) mod:SetUnit("pet") end)
        p.name:SetText(info.name or L("your pet"))
        p.line1:SetText(L(info.family or "?") .. ", " .. L("Level") .. " " .. tostring(info.level or "?"))
        return
    end
    local b = (win.sel and byId[win.sel]) or (win.items and win.items[1])
    m:SetShown(b and true or false)
    if not b then
        p.key = nil
        p.name:SetText("")
        p.line1:SetText("")
        p.line2:SetText("")
        p.abil:SetText("")
        p.msg:SetText(L("Select a beast first."))
        return
    end
    SetModel(p, "npc:" .. b.id, function(mod) mod:SetCreature(b.id) end)
    local c = RARITY_COLOR[b.r] or { 0.67, 0.83, 0.45 }
    p.name:SetText(b.n)
    p.name:SetTextColor(c[1], c[2], c[3])
    p.line1:SetText(L(b.f) .. ", " .. L("Level") .. " " .. b.l)
    p.line2:SetText(PD.ZoneName(b))
    p.abil:SetText(AbilityText(b, win.ctx and win.ctx.fams or {}))
end

local function SortBeasts(list)
    local key, desc = M.db.sort or "name", M.db.sortDesc
    if key == "spd" and not M.db.showSpeed then key = "name" end
    local ab = filter.ability
    local function value(b)
        if key == "spd" then return PD.Speed(b.id) or 99 end
        if key == "f" then return L(b.f) end
        if key == "lo" then return b.lo end
        if key == "zone" then return PD.ZoneName(b) end
        if key == "rank" then return (ab and b.ab and b.ab[ab]) or 0 end
        return b.n
    end
    table.sort(list, function(x, y)
        local vx, vy = value(x), value(y)
        if vx ~= vy then
            if desc then return vx > vy end
            return vx < vy
        end
        if x.n ~= y.n then return x.n < y.n end
        return x.id < y.id
    end)
end

local COLS_PLAIN = {
    { "Name", 32, 170, "name" }, { "Family", 206, 100, "f" }, { "Level", 310, 50, "lo" },
    { "Zone", 364, 160, "zone" }, { "Abilities taught", 528, 246 },
}
local COLS_SPEED = {
    { "Name", 32, 160, "name" }, { "Family", 196, 86, "f" }, { "Level", 286, 44, "lo" }, { "Speed", 334, 44, "spd" },
    { "Zone", 382, 130, "zone" }, { "Abilities taught", 516, 258 },
}

TABS.beasts = {
    label = "Beasts",
    cols = COLS_SPEED,
    selectable = true,
    hint = "Click: select.  Green: new rank.  Gray icon: not seen.  + tamed  * wishlist",
    items = function()
        local list = PD.Query(filter)
        SortBeasts(list)
        return list
    end,
    paint = function(row, b, ctx)
        row.icon:SetTexture(PD.FamilyIcon(b.f))
        row.icon:SetDesaturated(not PD.IsSeen(b.id))
        local c = RARITY_COLOR[b.r] or { 0.92, 0.94, 0.97 }
        local mark = (PD.IsWish(b.id) and "|cffffd100*|r " or "") .. (PD.IsTamed(b.id) and "|cff66ee66+|r " or "")
        row.cells[1]:SetText(mark .. b.n)
        row.cells[1]:SetTextColor(c[1], c[2], c[3])
        row.cells[2]:SetText(L(b.f))
        row.cells[3]:SetText(b.l)
        local zi = 4
        if M.db.showSpeed then row.cells[4]:SetText(PD.SpeedText(b.id)); zi = 5 end
        row.cells[zi]:SetText(PD.ZoneName(b))
        row.cells[zi + 1]:SetText(AbilityText(b, ctx.fams))
        local pl = tonumber(UnitLevel("player")) or 0
        if b.lo > pl then row.cells[3]:SetTextColor(0.95, 0.35, 0.3) else row.cells[3]:SetTextColor(0.92, 0.94, 0.97) end
    end,
    tip = BeastTip,
    click = function(row, b) win.sel = b.id end,
}

TABS.abilities = {
    label = "Abilities",
    cols = {
        { "Name", 32, 150 }, { "Known", 186, 60 }, { "Ranks", 250, 50 }, { "Levels", 304, 70 },
        { "Teachers", 378, 70 }, { "Families", 452, 322 },
    },
    hint = "Left click: show teachers.  Right click: set the rank you know.",
    items = function() return abilities end,
    paint = function(row, a)
        row.icon:SetTexture(PD.AbilityIcon(a))
        local known = PD.KnownRank(a.key)
        row.cells[1]:SetText(PD.AbilityName(a))
        row.cells[2]:SetText(known > 0 and (known .. " / " .. a.maxRank) or "-")
        row.cells[2]:SetTextColor(known >= a.maxRank and 0.45 or 0.92, known > 0 and 0.9 or 0.6, known >= a.maxRank and 0.35 or 0.6)
        row.cells[3]:SetText(tostring(a.maxRank))
        local first, last = a.ranks[1], a.ranks[#a.ranks]
        row.cells[4]:SetText(first.level .. " - " .. last.level)
        local n = 0
        for _, b in ipairs(beasts) do if b.ab and b.ab[a.key] then n = n + 1 end end
        row.cells[5]:SetText(tostring(n))
        local fl = {}
        for _, f in ipairs(a.families) do fl[#fl + 1] = L(f) end
        row.cells[6]:SetText(a.all and L("All") or table.concat(fl, ", "))
    end,
    tip = AbilityTip,
    click = function(row, a, button)
        if button == "RightButton" then
            local k = PD.KnownRank(a.key) + 1
            if k > a.maxRank then k = 0 end
            PD.SetKnownRank(a.key, k)
            return true
        end
        PD:Open("beasts", { ability = a.key, reset = true })
    end,
}

local function PetStatus(a, info, petRanks)
    local pet = petRanks[a.key] or 0
    local known = PD.KnownRank(a.key)
    if pet >= a.maxRank then return L("Maxed"), 0.45, 0.75, 0.95 end
    local nxt = a.byRank[pet + 1]
    if not nxt then return L("Maxed"), 0.45, 0.75, 0.95 end
    if known < pet + 1 then
        if pet == 0 and known == 0 then return L("Not learned"), 0.7, 0.7, 0.7 end
        return string.format(L("Learn rank %d from a beast"), pet + 1), 0.95, 0.45, 0.4
    end
    if info.level and nxt.level > info.level then
        return string.format(L("Needs pet level %d"), nxt.level), 0.95, 0.6, 0.2
    end
    if info.points and nxt.cost > info.points then
        return string.format(L("Needs %d training points"), nxt.cost), 0.95, 0.85, 0.3
    end
    return L("Ready to train"), 0.4, 0.95, 0.4
end

TABS.pet = {
    label = "My pet",
    cols = {
        { "Name", 32, 160 }, { "Hunter", 196, 70 }, { "Pet", 270, 70 }, { "Next rank", 344, 150 }, { "Status", 498, 276 },
    },
    hint = "Click an ability to find beasts that teach it.",
    items = function(ctx)
        local info = PD.PetInfo()
        ctx.info = info
        if not info or not info.family then return {} end
        PD.ScanBook()
        return PD.FamilyAbilities(info.family)
    end,
    paint = function(row, a, ctx)
        local info, petRanks = ctx.info, PD.petRanks or {}
        row.icon:SetTexture(PD.AbilityIcon(a))
        local known, pet = PD.KnownRank(a.key), petRanks[a.key] or 0
        row.cells[1]:SetText(PD.AbilityName(a))
        row.cells[2]:SetText(known > 0 and (known .. " / " .. a.maxRank) or "-")
        row.cells[3]:SetText(pet > 0 and (pet .. " / " .. a.maxRank) or "-")
        local nxt = a.byRank[pet + 1]
        row.cells[4]:SetText(nxt and (L("Level") .. " " .. nxt.level .. ", " .. nxt.cost .. " TP") or "-")
        local text, r, g, b = PetStatus(a, info, petRanks)
        row.cells[5]:SetText(text)
        row.cells[5]:SetTextColor(r, g, b)
    end,
    tip = AbilityTip,
    click = function(row, a)
        local info = PD.PetInfo()
        PD:Open("beasts", { ability = a.key, family = info and info.family, reset = true })
    end,
}

local function FamilyAbilityText(fam)
    local t = {}
    for _, a in ipairs(PD.FamilyAbilities(fam)) do t[#t + 1] = PD.AbilityName(a) end
    return table.concat(t, ", ")
end

TABS.stable = {
    label = "Stable",
    cols = {
        { "Name", 32, 170 }, { "Family", 206, 110 }, { "Level", 320, 50 }, { "Location", 374, 110 }, { "Abilities", 488, 286 },
    },
    hint = "Click: show beasts of that family.",
    items = function()
        local out, names = {}, {}
        local info = PD.PetInfo()
        if info and info.family then
            out[1] = { name = info.name or L("your pet"), fam = info.family, level = info.level, where = L("Active") }
            names[info.name or ""] = true
        end
        for _, e in ipairs(M.db.stable) do
            if not (e.slot0 and info) and not names[e.name] then
                names[e.name] = true
                out[#out + 1] = { name = e.name, fam = e.fam, level = e.level, where = e.slot0 and L("Last active") or L("In the stable") }
            end
        end
        for fam, name in pairs(M.db.pets) do
            if not names[name] then
                names[name] = true
                out[#out + 1] = { name = tostring(name), fam = fam, where = L("Seen out before") }
            end
        end
        return out
    end,
    paint = function(row, e)
        row.icon:SetTexture(PD.FamilyIcon(e.fam))
        row.cells[1]:SetText(e.name)
        row.cells[2]:SetText(e.fam and L(e.fam) or "?")
        row.cells[3]:SetText(e.level and tostring(e.level) or "-")
        row.cells[4]:SetText(e.where)
        row.cells[5]:SetText(e.fam and FamilyAbilityText(e.fam) or "")
    end,
    tip = function(row, e)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:AddLine(e.name, 0.67, 0.83, 0.45)
        GameTooltip:AddLine((e.fam and L(e.fam) or "?") .. (e.level and (", " .. L("Level") .. " " .. e.level) or "") .. ", " .. e.where, 0.9, 0.9, 0.9)
        if e.fam then GameTooltip:AddLine(FamilyAbilityText(e.fam), 0.7, 0.7, 0.7, true) end
        GameTooltip:Show()
    end,
    click = function(row, e)
        if e.fam then PD:Open("beasts", { family = e.fam, reset = true }) end
    end,
}

local function FilterActive()
    return filter.text ~= nil and filter.text ~= "" or filter.family or filter.ability or filter.myLevel or filter.newRanks or filter.rare
        or filter.wish or filter.unseen
end

local function Rebuild()
    if not win or not win:IsShown() then return end
    local tab = TABS[win.tab]
    win.ctx = { fams = PD.MyFamilies(true) }
    win.items = tab.items(win.ctx)
    local maxOff = math.max(0, #win.items - ROWS)
    win.offset = math.min(maxOff, math.max(0, win.offset or 0))
    PD.Paint()
end

function PD.Dirty()
    if not win or not win:IsShown() or win.dirty then return end
    win.dirty = true
    local function run() win.dirty = false; Rebuild() end
    if C_Timer and C_Timer.After then C_Timer.After(0.3, run) else run() end
end

function PD.Paint()
    if not win or not win:IsShown() then return end
    local tab = TABS[win.tab]
    local items, ctx = win.items or {}, win.ctx or { fams = {} }
    for i = 1, ROWS do
        local row = win.rows[i]
        local it = items[(win.offset or 0) + i]
        row.item = it
        if not it then
            row:Hide()
        else
            row:Show()
            for _, c in ipairs(row.cells) do c:SetTextColor(0.92, 0.94, 0.97) end
            row.icon:SetDesaturated(false)
            tab.paint(row, it, ctx)
            row.sel:SetShown(tab.selectable and win.sel == it.id)
        end
    end
    local n = #items
    win.range:SetText(n > 0 and string.format(L("%d of %d"), math.min(n, (win.offset or 0) + ROWS), n) or "0")
    if win.scroll then win.scroll:Update() end
    if win.tab == "beasts" then
        local s, t, total = PD.Progress()
        win.progress:SetText(string.format(L("Seen %d/%d, tamed %d"), s, total, t))
    else
        win.progress:SetText("")
    end
    for k, t in pairs(win.tabs) do
        local on = (k == win.tab)
        t.label:SetTextColor(on and UI.ACCENT[1] or 0.7, on and UI.ACCENT[2] or 0.7, on and UI.ACCENT[3] or 0.7)
    end
    if win.tab == "pet" then
        local info = ctx.info
        if info and info.family then
            win.info:SetText(string.format(L("%s (%s), level %s"), info.name or L("your pet"), L(info.family), tostring(info.level or "?"))
                .. "     " .. string.format(L("Free training points: %s"), tostring(info.points or "?")))
        else
            win.info:SetText(L("No pet out. Call your pet to see its abilities."))
        end
    else
        win.info:SetText(win.tab == "stable" and L("Open a stable master once to update the list.") or "")
    end
    -- header sort arrows
    for i, h in ipairs(win.heads) do
        local c = tab.cols[i]
        if c then
            local arrow = ""
            if c[4] and win.tab == "beasts" and M.db.sort == c[4] then arrow = M.db.sortDesc and " v" or " ^" end
            h.text:SetText(L(c[1]) .. arrow)
        end
    end
    local sel = win.sel and byId[win.sel]
    win.btnMap:SetShown(win.tab == "beasts")
    win.btnWay:SetShown(win.tab == "beasts")
    win.btnAll:SetShown(win.tab == "beasts")
    win.btnClear:SetShown(win.tab == "beasts")
    win.btnWish:SetShown(win.tab == "beasts")
    win.btnWish:SetLabel(sel and PD.IsWish(sel.id) and L("Remove from wishlist") or L("Add to wishlist"))
    win.filterBar:SetShown(win.tab == "beasts")
    win.hint:SetText(L(tab.hint))
    win.famBtn:SetLabel(filter.family and string.format(L("Family: %s"), L(filter.family)) or L("All families"))
    win.abBtn:SetLabel(filter.ability and string.format(L("Ability: %s"), PD.AbilityName(byKey[filter.ability])) or L("All abilities"))
    for _, c in ipairs(win.checks) do c:Refresh() end
    win.btnMap:SetAlpha(sel and 1 or 0.5)
    win.btnWay:SetAlpha(sel and 1 or 0.5)
    UpdateModel()
end

local function SetTab(name)
    win.tab = name
    win.offset = 0
    TABS.beasts.cols = M.db.showSpeed and COLS_SPEED or COLS_PLAIN
    local tab = TABS[name]
    for i, h in ipairs(win.heads) do
        local c = tab.cols[i]
        if c then
            h:Show()
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", win, "TOPLEFT", 12 + c[2], -118)
            h:SetSize(c[3], 16)
            h.sortKey = (name == "beasts") and c[4] or nil
        else
            h:Hide()
        end
    end
    for _, row in ipairs(win.rows) do
        for i, cell in ipairs(row.cells) do
            local c = tab.cols[i]
            if c then
                cell:Show()
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", row, "LEFT", c[2], 0)
                cell:SetWidth(c[3])
            else
                cell:Hide()
            end
        end
    end
    Rebuild()
end

function PD.Relayout()
    if win and win:IsShown() then SetTab(win.tab) end
end

local function ChangeSort(key)
    if M.db.sort == key then M.db.sortDesc = not M.db.sortDesc else M.db.sort, M.db.sortDesc = key, false end
    Rebuild()
end

local function ClearFilter()
    filter.text, filter.family, filter.ability, filter.myLevel, filter.newRanks, filter.rare = nil, nil, nil, nil, nil, nil
    filter.wish, filter.unseen = nil, nil
    if win then win.search:SetText("") end
end

local function PickFamily(anchor)
    local items = { { label = L("All families"), value = false } }
    for _, f in ipairs(families) do
        items[#items + 1] = { label = L(f), value = f, icon = PD.FamilyIcon(f) }
    end
    UI.ShowMenu(anchor, items, function(it)
        filter.family = it.value or nil
        win.offset = 0
        Rebuild()
    end)
end

local function PickAbility(anchor)
    local items = { { label = L("All abilities"), value = false } }
    for _, a in ipairs(abilities) do
        items[#items + 1] = { label = PD.AbilityName(a), value = a.key, icon = PD.AbilityIcon(a) }
    end
    UI.ShowMenu(anchor, items, function(it)
        filter.ability = it.value or nil
        if filter.ability then M.db.sort, M.db.sortDesc = "rank", true elseif M.db.sort == "rank" then M.db.sort, M.db.sortDesc = "name", false end
        win.offset = 0
        Rebuild()
    end)
end

local function Selected()
    local b = win and win.sel and byId[win.sel]
    if not b then HHT.Print(L("Select a beast first.")) end
    return b
end

local function Build()
    win = UI.Window("HamingwaysHunterToolsPetDex", W, H, L("Pet database"))
    win:SetFrameStrata("FULLSCREEN_DIALOG")
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    win:Hide()
    win.tab, win.offset, win.rows, win.tabs, win.heads, win.checks = "beasts", 0, {}, {}, {}, {}
    if UISpecialFrames then tinsert(UISpecialFrames, "HamingwaysHunterToolsPetDex") end

    local prev
    for _, k in ipairs(TAB_ORDER) do
        local t = UI.Button(win, 130, 22, L(TABS[k].label), function() SetTab(k) end)
        if prev then t:SetPoint("LEFT", prev, "RIGHT", 6, 0) else t:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -38) end
        win.tabs[k] = t
        prev = t
    end
    win.info = UI.Text(win, "", 12, 0.9, 0.9, 0.9)
    win.info:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -70)
    win.btnView = UI.Button(win, 100, 22, L("3D view"), function()
        M.db.showModel = not M.db.showModel
        UpdateModel()
    end)
    win.btnView:SetPoint("TOPRIGHT", win, "TOPRIGHT", -12, -38)
    BuildView()

    -- search, family, ability, toggles (beasts tab)
    local bar = CreateFrame("Frame", nil, win)
    bar:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -64)
    bar:SetSize(W, 48)
    win.filterBar = bar
    win.search = UI.EditBox(bar, 210, function(t) filter.text = t; win.offset = 0; Rebuild() end)
    win.search:SetPoint("TOPLEFT", bar, "TOPLEFT", 12, -2)
    local hintText = UI.Text(win.search, L("Search name, family, zone, ability"), 11, 0.5, 0.5, 0.5)
    hintText:SetPoint("LEFT", win.search, "LEFT", 6, 0)
    win.search:HookScript("OnTextChanged", function(self) hintText:SetShown(self:GetText() == "") end)
    win.famBtn = UI.Button(bar, 150, 20, "", function(self) PickFamily(self) end)
    win.famBtn:SetPoint("LEFT", win.search, "RIGHT", 8, 0)
    win.abBtn = UI.Button(bar, 190, 20, "", function(self) PickAbility(self) end)
    win.abBtn:SetPoint("LEFT", win.famBtn, "RIGHT", 6, 0)
    local reset = UI.Button(bar, 80, 20, L("Reset"), function() ClearFilter(); Rebuild() end)
    reset:SetPoint("LEFT", win.abBtn, "RIGHT", 6, 0)
    local function Toggle(label, key, x)
        local c = UI.Check(bar, L(label), function() return filter[key] end, function(v) filter[key] = v or nil; win.offset = 0; Rebuild() end)
        c:SetPoint("TOPLEFT", bar, "TOPLEFT", x, -26)
        win.checks[#win.checks + 1] = c
    end
    Toggle("Up to my level", "myLevel", 12)
    Toggle("New ranks", "newRanks", 190)
    Toggle("Rare and elite only", "rare", 330)
    Toggle("Wishlist", "wish", 500)
    Toggle("Not seen yet", "unseen", 600)

    for i = 1, 6 do
        local h = CreateFrame("Button", nil, win)
        h.text = UI.Header(h, "")
        h.text:SetPoint("LEFT", h, "LEFT", 0, 0)
        h:SetScript("OnClick", function(self) if self.sortKey then ChangeSort(self.sortKey) end end)
        win.heads[i] = h
    end

    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, win)
        row:SetSize(W - 24 - 14, ROW_H)
        row:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -136 - (i - 1) * ROW_H)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.15)
        row.sel = row:CreateTexture(nil, "BACKGROUND")
        row.sel:SetAllPoints()
        row.sel:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.28)
        row.sel:Hide()
        if i % 2 == 0 then
            local stripe = row:CreateTexture(nil, "BACKGROUND", nil, -1)
            stripe:SetAllPoints()
            stripe:SetColorTexture(1, 1, 1, 0.03)
        end
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.cells = {}
        for k = 1, 6 do
            local fs = UI.Text(row, "", 12)
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(false)
            row.cells[k] = fs
        end
        row:SetScript("OnClick", function(self, button)
            local it = self.item
            if not it then return end
            local tab = TABS[win.tab]
            local handled = tab.click and tab.click(self, it, button)
            if handled == true or win.tab == "beasts" then PD.Paint() end
        end)
        row:SetScript("OnEnter", function(self)
            local it = self.item
            if it and GameTooltip then TABS[win.tab].tip(self, it) end
        end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        win.rows[i] = row
    end

    local function Wheel(_, delta)
        win.offset = math.max(0, math.min(math.max(0, #(win.items or {}) - ROWS), (win.offset or 0) - delta * 3))
        PD.Paint()
    end
    win:EnableMouseWheel(true)
    win:SetScript("OnMouseWheel", Wheel)
    for _, row in ipairs(win.rows) do
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", Wheel)
    end

    local sb = CreateFrame("Button", nil, win)
    sb:SetSize(10, ROWS * ROW_H)
    sb:SetPoint("TOPLEFT", win, "TOPLEFT", W - 22, -136)
    local track = sb:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(1, 1, 1, 0.06)
    local thumb = sb:CreateTexture(nil, "ARTWORK")
    thumb:SetWidth(10)
    thumb:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.55)
    local THUMB_MIN = 24
    sb:EnableMouseWheel(true)
    sb:SetScript("OnMouseWheel", Wheel)
    function sb:Update()
        local total = #(win.items or {})
        if total <= ROWS then self:Hide() return end
        self:Show()
        local h = self:GetHeight()
        local th = math.max(THUMB_MIN, h * ROWS / total)
        local frac = (win.offset or 0) / (total - ROWS)
        thumb:SetHeight(th)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", self, "TOP", 0, -(h - th) * frac)
    end
    -- the thumb follows the cursor while the button is held
    local function Drag(self)
        local total = #(win.items or {})
        if total <= ROWS then return end
        local scale = self:GetEffectiveScale()
        local _, cy = GetCursorPosition()
        local h, th = self:GetHeight(), thumb:GetHeight()
        local frac = ((self:GetTop() - cy / scale) - th / 2) / math.max(1, h - th)
        win.offset = math.floor(math.max(0, math.min(1, frac)) * (total - ROWS) + 0.5)
        PD.Paint()
    end
    sb:SetScript("OnMouseDown", function(self)
        Drag(self)
        self:SetScript("OnUpdate", Drag)
    end)
    sb:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
    sb:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    win.scroll = sb

    win.btnMap = UI.Button(win, 140, 22, L("Show on map"), function()
        local b = Selected()
        if b and HHT.PetMap then HHT.PetMap:ShowBeasts({ b }, true) end
    end)
    win.btnMap:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 34)
    win.btnWay = UI.Button(win, 110, 22, L("Waypoint"), function()
        local b = Selected()
        if b and HHT.PetMap then
            HHT.PetMap:Waypoint(b)
            if HHT.PetWatch then HHT.PetWatch.Track(b) end
        end
    end)
    win.btnWay:SetPoint("LEFT", win.btnMap, "RIGHT", 6, 0)
    win.btnAll = UI.Button(win, 170, 22, L("All results on map"), function()
        if HHT.PetMap then HHT.PetMap:ShowBeasts(win.items or {}, true) end
    end)
    win.btnAll:SetPoint("LEFT", win.btnWay, "RIGHT", 6, 0)
    win.btnClear = UI.Button(win, 130, 22, L("Clear pins"), function()
        if HHT.PetMap then HHT.PetMap:Clear() end
        if HHT.PetWatch then HHT.PetWatch.Track(nil) end
    end)
    win.btnClear:SetPoint("LEFT", win.btnAll, "RIGHT", 6, 0)
    win.btnWish = UI.Button(win, 170, 22, "", function()
        local b = Selected()
        if b then PD.SetWish(b.id, not PD.IsWish(b.id)); Rebuild() end
    end)
    win.btnWish:SetPoint("LEFT", win.btnClear, "RIGHT", 6, 0)

    win.range = UI.Text(win, "", 12, 0.7, 0.7, 0.7)
    win.range:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 10)
    win.progress = UI.Text(win, "", 12, 0.67, 0.83, 0.45)
    win.progress:SetPoint("RIGHT", win.range, "LEFT", -16, 0)
    win.hint = UI.Text(win, "", 11, 0.7, 0.7, 0.7)
    win.hint:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 10)
    win:SetScript("OnShow", function()
        PD.ScanSpells()
        PD.ScanBook()
        Rebuild()
    end)
end

-- opts: ability, family, text, reset (clear the other filters first)
function PD:Open(tab, opts)
    if not M.enabled then HHT.Print(L("Pet database is disabled.")); return end
    if not win then Build() end
    opts = opts or {}
    if opts.reset then ClearFilter() end
    if opts.ability ~= nil then
        filter.ability = opts.ability or nil
        if opts.ability then M.db.sort, M.db.sortDesc = "rank", true end
    end
    if opts.family ~= nil then filter.family = opts.family or nil end
    if opts.text ~= nil then
        filter.text = opts.text ~= "" and opts.text or nil
        win.search:SetText(opts.text)
    end
    if not win:IsShown() then win:Show() end
    SetTab(tab or win.tab)
end

function PD:Toggle(text)
    if not M.enabled then HHT.Print(L("Pet database is disabled.")); return end
    if not win then Build() end
    if text and text ~= "" then
        self:Open("beasts", { text = text, reset = true })
    elseif win:IsShown() then
        win:Hide()
    else
        self:Open()
    end
end

function PD:Hide()
    if win then win:Hide() end
end

-- ---------------------------------------------------------------------------
-- Module
-- ---------------------------------------------------------------------------
function M:OnInit()
    -- Older versions counted the pet's own spellbook as learned ranks; rebuild once from the spellbook and Beast Training.
    if (self.db.knownVer or 0) < 2 then
        self.db.known = {}
        self.db.knownVer = 2
    end
    for _, ev in ipairs({ "UNIT_PET", "PET_BAR_UPDATE", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_ENTERING_WORLD" }) do
        HHT:Listen(self, ev, "OnChange")
    end
    HHT:Listen(self, "CRAFT_SHOW", "OnCraft")
    HHT:Listen(self, "CRAFT_UPDATE", "OnCraft")
    HHT:Listen(self, "PET_STABLE_SHOW", "OnStable")
    HHT:Listen(self, "PET_STABLE_UPDATE", "OnStable")
end

function M:OnStable()
    -- the slots load a moment after the window opens
    if C_Timer and C_Timer.After then C_Timer.After(0.5, function() if M.enabled then PD.ScanStable() end end)
    else PD.ScanStable() end
end

function M:OnChange()
    PD.ScanSpells()
    PD.ScanBook()
    PD.Remember()
    PD.Dirty()
end

function M:OnCraft()
    PD.ScanCraft()
    PD.Dirty()
end

function M:OnEnable()
    local function first() if M.enabled then M:OnChange() end end
    if C_Timer and C_Timer.After then C_Timer.After(3, first) else first() end
    local pm = HHT.modules.pet
    if pm and pm.enabled and pm.Layout then pm:Layout() end
end

function M:OnDisable()
    PD:Hide()
    if HHT.PetMap then HHT.PetMap:Clear() end
    local pm = HHT.modules.pet
    if pm and pm.enabled and pm.Layout then pm:Layout() end
end

function M:Refresh()
    if HHT.PetMap then HHT.PetMap:Update() end
    PD.Dirty()
end

function M:BuildOptions(form)
    local db = self.db
    form:Button(L("Open pet database"), function() PD:Open() end, 240)
    form:Note(L("Also opens with /hht pets, Shift+click on the minimap button or a click on the pet portrait."))
    form:Header(L("Behavior"))
    form:Check(L("Click the pet portrait to open the database"), db, "openOnClick", function()
        local pm = HHT.modules.pet
        if pm and pm.enabled and pm.Layout then pm:Layout() end
    end)
    form:Check(L("Show attack speed"), db, "showSpeed", function() PD.Relayout() end)
    form:Color(L("Color for attack speed under 2 seconds"), db, "speedColor", function() PD.Dirty() end)
    form:Note(L("Attack speed is read from the game when you target or point at a beast, so it fills in as you meet them. A value with ~ is the Classic base value and gets replaced once you meet the beast."))
    form:Button(L("Export / import beast data"), function() if HHT.PetShare then HHT.PetShare.Open() end end, 240)
    form:Header(L("World map"))
    form:Check(L("Show pins on the world map"), db, "pins", function() if HHT.PetMap then HHT.PetMap:Update() end end)
    form:Check(L("Also show them on the minimap"), db, "minimap")
    form:Check(L("Show 3D view"), db, "showModel", function() PD.Dirty() end)
    form:Stepper(L("Pin size"), db, "pinSize", 10, 40, 2, function() if HHT.PetMap then HHT.PetMap:Update() end end)
    form:Button(L("Remove all pins"), function() if HHT.PetMap then HHT.PetMap:Clear() end end, 240)
    form:Header(L("Known ranks"))
    form:Note(L("Ranks you have learned are read from the Beast Training window and the pet spellbook. Open Beast Training once so they are detected."))
    form:Button(L("Scan now"), function() M:OnChange(); M:OnCraft() end, 240)
    form:Button(L("Forget known ranks"), function()
        for k in pairs(db.known) do db.known[k] = nil end
        for k in pairs(db.pets) do db.pets[k] = nil end
        for k in pairs(db.stable) do db.stable[k] = nil end
        PD.Dirty()
    end, 240)
    form:Header(L("Discovery"))
    form:Note(L("Beasts are marked as seen when you target them or point at them, and as tamed after you tame them. Wishlist entries alert you when you see them."))
    form:Button(L("Forget seen and tamed beasts"), function()
        for k in pairs(db.seen) do db.seen[k] = nil end
        for k in pairs(db.tamed) do db.tamed[k] = nil end
        PD.Dirty()
    end, 240)
    form:Button(L("Clear wishlist"), function()
        for k in pairs(db.wish) do db.wish[k] = nil end
        PD.Dirty()
    end, 240)
end
