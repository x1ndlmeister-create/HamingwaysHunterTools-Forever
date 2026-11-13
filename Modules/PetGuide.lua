-- Pet guide: family recommendations by play style, basics, and a one-time hint at level 10 that points to the hunter trainer.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Pet guide"] = "Begleiter-Guide",
    ["Beginner guide for pets: family recommendations by play style and a one-time hint at level 10."] = "Einsteiger-Guide fuer Begleiter: Familien-Empfehlungen nach Spielstil und ein einmaliger Hinweis bei Level 10.",
    ["Guide"] = "Guide",
    ["Tip"] = "Tipp",
    ["Maximum damage"] = "Maximaler Schaden",
    ["Solo survival"] = "Solo-Ueberleben",
    ["Balanced"] = "Ausgewogen",
    ["Best families for: %s"] = "Beste Familien fuer: %s",
    ["How pets work"] = "So funktionieren Begleiter",
    ["First pet"] = "Dein erster Begleiter",
    ["Show hunter trainers on the map"] = "Jaegerlehrer auf der Karte zeigen",
    ["Waypoint to the nearest hunter trainer"] = "Wegpunkt zum naechsten Jaegerlehrer",
    ["Click a family to see its beasts. Pick the goal above."] = "Klicke eine Familie, um ihre Tiere zu sehen. Waehle oben dein Ziel.",
    ["Hunter trainer: %s, %s"] = "Jaegerlehrer: %s, %s",
    ["Hunter trainer: see the map"] = "Jaegerlehrer: siehe Karte",
    ["LEVEL 10 REACHED"] = "LEVEL 10 ERREICHT",
    ["Time for your first pet"] = "Zeit fuer deinen ersten Begleiter",
    ["Take the pet quest from your hunter trainer. Finish both parts before you tame, the second one teaches feeding."] = "Hol dir beim Jaegerlehrer die Begleiter-Quest. Schliesse beide Teile ab, bevor du zaehmst. Der zweite lehrt das Fuettern.",
    ["Show a hint when I reach level 10"] = "Hinweis zeigen, wenn ich Level 10 erreiche",
    ["Shown once per character, when you reach level 10."] = "Wird einmal pro Charakter gezeigt, wenn du Level 10 erreichst.",
    ["Show test hint"] = "Test-Hinweis zeigen",
    ["Open pet guide"] = "Begleiter-Guide oeffnen",
    ["Hint border"] = "Rahmen Hinweis",
})

local M = HHT:NewModule("petguide", {
    name = "Pet guide",
    desc = "Beginner guide for pets: family recommendations by play style and a one-time hint at level 10.",
    positions = { main = { "TOP", "TOP", 0, -170 } },
    defaults = {
        levelHint = true, sound = true, duration = 0, shown = false, goal = "dmg",
        colors = { border = { 0.67, 0.83, 0.45 } },
    },
})

local G = {}
HHT.PetGuide = G

-- ---------------------------------------------------------------------------
-- Guide data
-- ---------------------------------------------------------------------------
G.goals = {
    { key = "dmg", label = "Maximum damage" },
    { key = "solo", label = "Solo survival" },
    { key = "bal", label = "Balanced" },
}

local SCORE = {
    dmg = function(e) return e.d * 2 + (e.h + e.a) * 0.1 end,
    solo = function(e) return (e.h + e.a) * 0.55 + e.d * 0.1 end,
    bal = function(e) return math.min(e.h, e.a, e.d) * 1.5 + (e.h + e.a + e.d) / 3 end,
}

-- Short family tips, English and German side by side (about 55 characters fit the column).
local TIPS = {
    ["Cat"] = { "Top damage, little health", "Hoechster Schaden, wenig Leben" },
    ["Raptor"] = { "Top damage, a bit fragile", "Hoher Schaden, etwas empfindlich" },
    ["Bird of Prey"] = { "Strong damage, Screech weakens enemies", "Starker Schaden, Screech schwaecht Gegner" },
    ["Bat"] = { "Good damage, eats fruit and fungus", "Guter Schaden, frisst Obst und Pilze" },
    ["Spider"] = { "Good damage, Web holds enemies", "Guter Schaden, Web haelt Gegner fest" },
    ["Wind Serpent"] = { "Good damage, eats bread and cheese", "Guter Schaden, frisst Brot und Kaese" },
    ["Carrion Bird"] = { "All-rounder with extra armor", "Allrounder mit etwas mehr Ruestung" },
    ["Wolf"] = { "Solid all-rounder with extra armor", "Solider Allrounder mit mehr Ruestung" },
    ["Hyena"] = { "All-rounder, also eats fruit", "Allrounder, frisst auch Obst" },
    ["Bear"] = { "Most health, high armor, eats almost anything", "Meiste Gesundheit, viel Ruestung, frisst fast alles" },
    ["Boar"] = { "High armor, eats almost anything", "Viel Ruestung, frisst fast alles" },
    ["Crab"] = { "Top armor, low health", "Hoechste Ruestung, wenig Leben" },
    ["Crocolisk"] = { "High armor, normal damage", "Viel Ruestung, normaler Schaden" },
    ["Gorilla"] = { "More health, Thunderstomp", "Mehr Leben, Thunderstomp" },
    ["Scorpid"] = { "High armor, poison hurts enemies", "Viel Ruestung, Gift schadet Gegnern" },
    ["Turtle"] = { "Top armor, Shell Shield protects", "Hoechste Ruestung, Shell Shield schuetzt" },
    ["Tallstrider"] = { "More health, eats cheese and fruit", "Mehr Leben, frisst Kaese und Obst" },
}

G.basics = {
    { "Offense: most damage. Defense: most health and armor. General: in between.",
      "Angriff: meister Schaden. Verteidigung: meiste Gesundheit und Ruestung. Allgemein: dazwischen." },
    { "Feed your pet often with food of its diet. A hungry pet gets unhappy and finally runs away.",
      "Fuettere deinen Begleiter oft mit Nahrung seiner Art. Hunger macht ihn unzufrieden, am Ende laeuft er weg." },
    { "A tamed pet keeps its level and has to level up in combat with you.",
      "Ein gezaehmter Begleiter behaelt sein Level und muss mit dir im Kampf aufsteigen." },
    { "You must know an ability yourself before your pet can learn it. Some come only from wild beasts.",
      "Du musst eine Faehigkeit selbst kennen, bevor dein Begleiter sie lernt. Manche gibt es nur von wilden Tieren." },
    { "Training points depend on level and loyalty, so choose abilities with care.",
      "Trainingspunkte haengen von Level und Loyalitaet ab, waehle Faehigkeiten mit Bedacht." },
}

G.firstPet = {
    { "At level 10 your hunter trainer gives you the pet quest.",
      "Mit Level 10 gibt dir dein Jaegerlehrer die Begleiter-Quest." },
    { "Finish both parts before you tame. The second one teaches feeding.",
      "Schliesse beide Teile ab, bevor du zaehmst. Der zweite lehrt das Fuettern." },
}

do
    local de = {}
    for _, t in pairs(TIPS) do de[t[1]] = t[2] end
    for _, t in ipairs(G.basics) do de[t[1]] = t[2] end
    for _, t in ipairs(G.firstPet) do de[t[1]] = t[2] end
    HHT:AddGerman(de)
end

function G.Tip(name)
    local t = TIPS[name]
    return t and L(t[1]) or ""
end

function G.Goal()
    local g = M.db and M.db.goal
    return SCORE[g] and g or "dmg"
end

function G.SetGoal(key)
    if M.db and SCORE[key] then M.db.goal = key end
end

function G.GoalLabel(key)
    for _, g in ipairs(G.goals) do
        if g.key == key then return L(g.label) end
    end
    return ""
end

-- Families with known modifiers, best first for the goal.
function G.Rank(goal)
    local f = SCORE[goal] or SCORE.dmg
    local list = {}
    for _, e in ipairs(HHT.PetFamilyData or {}) do
        if e.h and e.a and e.d then list[#list + 1] = e end
    end
    table.sort(list, function(x, y)
        local sx, sy = f(x), f(y)
        if sx ~= sy then return sx > sy end
        return x.n < y.n
    end)
    return list
end

-- ---------------------------------------------------------------------------
-- Hunter trainers
-- ---------------------------------------------------------------------------
local function HunterTrainers()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local out = {}
    for _, e in ipairs(HHT.TrainerData or {}) do
        if e.k == "H" and (e.fa == "N" or (e.fa == "A" and faction == "Alliance") or (e.fa == "H" and faction == "Horde")) then
            out[#out + 1] = { n = e.n, sp = { [e.m] = string.format("%d,%d", e.x, e.y) } }
        end
    end
    return out
end

-- { map, x, y, name } of the closest hunter trainer, or nil when the position is unknown.
function G.NearestTrainer()
    local pm = HHT.PetMap
    if not pm then return nil end
    return pm:Nearest(HunterTrainers())
end

function G.ShowTrainers()
    if HHT.Trainers then HHT.Trainers.Show() end
end

function G.TrainerWaypoint()
    local pm, t = HHT.PetMap, G.NearestTrainer()
    if not (pm and t) then HHT.Print(L("No trainers known here.")); return end
    pm:SetWaypointAt(t[1], t[2], t[3], t[4])
end

local function ZoneName(map)
    if C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, map)
        if ok and type(info) == "table" and type(info.name) == "string" then return info.name end
    end
    return "?"
end

-- ---------------------------------------------------------------------------
-- Level 10 popup
-- ---------------------------------------------------------------------------
local W, H = 400, 130

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsPetGuide", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("DIALOG")
    self.frame = f
    f.border = UI.Panel(f, 0.67, 0.83, 0.45)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(44, 44)
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -12)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
    HHT.Icon.Attach(f.icon)
    f.eyebrow = UI.Text(f, L("LEVEL 10 REACHED"), 10, 0.67, 0.83, 0.45)
    f.eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", 64, -8)
    f.title = UI.Text(f, L("Time for your first pet"), 13, 1, 1, 1)
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 64, -22)
    f.title:SetWidth(W - 100)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    f.sub = UI.Text(f, "", 11, 0.8, 0.8, 0.8)
    f.sub:SetPoint("TOPLEFT", f, "TOPLEFT", 64, -40)
    f.sub:SetWidth(W - 76)
    f.sub:SetJustifyH("LEFT")
    f.sub:SetWordWrap(false)
    f.div = f:CreateTexture(nil, "ARTWORK")
    f.div:SetColorTexture(1, 1, 1, 0.08)
    f.div:SetHeight(1)
    f.div:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -57)
    f.div:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -57)
    f.body = UI.Text(f, L("Take the pet quest from your hunter trainer. Finish both parts before you tame, the second one teaches feeding."), 11, 0.92, 0.94, 0.97)
    f.body:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -63)
    f.body:SetWidth(W - 24)
    f.body:SetHeight(32)
    f.body:SetJustifyH("LEFT")
    f.body:SetJustifyV("TOP")

    local close = UI.Button(f, 18, 18, "x", function() f:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    f.map = UI.Button(f, 70, 20, L("Map"), G.ShowTrainers)
    f.map:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 8)
    f.way = UI.Button(f, 90, 20, L("Waypoint"), G.TrainerWaypoint)
    f.way:SetPoint("LEFT", f.map, "RIGHT", 6, 0)
    f.guide = UI.Button(f, 110, 20, L("Pet guide"), function()
        if HHT.PetDex then HHT.PetDex:Open("guide") end
    end)
    f.guide:SetPoint("LEFT", f.way, "RIGHT", 6, 0)

    f:Hide()
    HHT:MakeMovable(f, self, "main", L("Pet guide"))
end

function M:Show(preview)
    local f = self.frame
    if not f then return end
    local t = G.NearestTrainer()
    f.sub:SetText(t and string.format(L("Hunter trainer: %s, %s"), t[4] or "?", ZoneName(t[1])) or L("Hunter trainer: see the map"))
    f.preview = preview
    f.hideAt = (not preview and self.db.duration > 0) and (GetTime() + self.db.duration) or nil
    f:Show()
end

function M:OnInit()
    HHT:Listen(self, "PLAYER_LEVEL_UP", "OnLevel")
    HHT:Every(self, 0.5, M.Tick)
end

function M:OnEnable()
    self:Build()
    self:Refresh()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
end

function M:Refresh()
    local f = self.frame
    if not f then return end
    local c = self.db.colors.border
    f.border:SetColor(c[1], c[2], c[3], 0.9)
    HHT:ApplyGlobalLook(f)
    if HHT:IsUnlocked(self) then
        self:Show(true)
    elseif f.preview then
        f:Hide()
        f.preview = nil
    end
end

function M:OnLockChanged() self:Refresh() end

function M:Tick()
    local f = self.frame
    if f and f:IsShown() and f.hideAt and not f.preview and GetTime() > f.hideAt then
        f:Hide()
        f.hideAt = nil
    end
end

function M:OnLevel(_, level)
    local db = self.db
    if tonumber(level) ~= 10 or not db.levelHint or db.shown then return end
    db.shown = true
    self:Show(false)
    if db.sound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959) end
end

function M:Test()
    if not self.frame then return false end
    self:Show(false)
    self.frame.hideAt = GetTime() + 15
    return true
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Behavior"))
    form:Check(L("Show a hint when I reach level 10"), db, "levelHint")
    form:Note(L("Shown once per character, when you reach level 10."))
    form:Stepper(L("Show for (seconds, 0 = until closed)"), db, "duration", 0, 120, 5)
    form:Check(L("Play a sound"), db, "sound")
    form:Button(L("Show test hint"), function() M:Test() end, 220)
    form:Button(L("Open pet guide"), function() if HHT.PetDex then HHT.PetDex:Open("guide") end end, 220)
    form:Header(L("Colors"))
    form:Color(L("Hint border"), db.colors, "border", function() M:Refresh() end)
end
