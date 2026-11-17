-- Pet guide: family recommendations by play style, basics, and a one-time hint at level 10 that points to the hunter trainer.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Pet guide"] = "Begleiter-Guide",
    ["Beginner guide for pets: family recommendations by play style and a one-time hint at level 10."] = "Einsteiger-Guide für Begleiter: Familien-Empfehlungen nach Spielstil und ein einmaliger Hinweis bei Level 10.",
    ["Guide"] = "Guide",
    ["Tip"] = "Tipp",
    ["Maximum damage"] = "Maximaler Schaden",
    ["Solo survival"] = "Solo-Überleben",
    ["Balanced"] = "Ausgewogen",
    ["Best families for: %s"] = "Beste Familien für: %s",
    ["How pets work"] = "So funktionieren Begleiter",
    ["First pet"] = "Dein erster Begleiter",
    ["Show hunter trainers on the map"] = "Jägerlehrer auf der Karte zeigen",
    ["Waypoint to the nearest hunter trainer"] = "Wegpunkt zum nächsten Jägerlehrer",
    ["Click a family to see its beasts. Pick the goal above."] = "Klicke eine Familie, um ihre Tiere zu sehen. Wähle oben dein Ziel.",
    ["Hunter trainer: %s, %s"] = "Jägerlehrer: %s, %s",
    ["Hunter trainer: see the map"] = "Jägerlehrer: siehe Karte",
    ["LEVEL 10 REACHED"] = "LEVEL 10 ERREICHT",
    ["Time for your first pet"] = "Zeit für deinen ersten Begleiter",
    ["Take the pet quest from your hunter trainer. Finish both parts before you tame, the second one teaches feeding."] = "Hol dir beim Jägerlehrer die Begleiter-Quest. Schließe beide Teile ab, bevor du zähmst. Der zweite lehrt das Füttern.",
    ["Show a hint when I reach level 10"] = "Hinweis zeigen, wenn ich Level 10 erreiche",
    ["Shown once per character, when you reach level 10."] = "Wird einmal pro Charakter gezeigt, wenn du Level 10 erreichst.",
    ["Show test hint"] = "Test-Hinweis zeigen",
    ["Open pet guide"] = "Begleiter-Guide öffnen",
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
    ["Cat"] = { "Top damage, little health", "Höchster Schaden, wenig Leben" },
    ["Raptor"] = { "Top damage, a bit fragile", "Hoher Schaden, etwas empfindlich" },
    ["Bird of Prey"] = { "Strong damage, Screech weakens enemies", "Starker Schaden, Screech schwächt Gegner" },
    ["Bat"] = { "Good damage, eats fruit and fungus", "Guter Schaden, frisst Obst und Pilze" },
    ["Spider"] = { "Good damage, Web holds enemies", "Guter Schaden, Web hält Gegner fest" },
    ["Wind Serpent"] = { "Good damage, eats bread and cheese", "Guter Schaden, frisst Brot und Käse" },
    ["Carrion Bird"] = { "All-rounder with extra armor", "Allrounder mit etwas mehr Rüstung" },
    ["Wolf"] = { "Solid all-rounder with extra armor", "Solider Allrounder mit mehr Rüstung" },
    ["Hyena"] = { "All-rounder, also eats fruit", "Allrounder, frisst auch Obst" },
    ["Bear"] = { "Most health, high armor, eats almost anything", "Meiste Gesundheit, viel Rüstung, frisst fast alles" },
    ["Boar"] = { "High armor, eats almost anything", "Viel Rüstung, frisst fast alles" },
    ["Crab"] = { "Top armor, low health", "Höchste Rüstung, wenig Leben" },
    ["Crocolisk"] = { "High armor, normal damage", "Viel Rüstung, normaler Schaden" },
    ["Gorilla"] = { "More health, Thunderstomp", "Mehr Leben, Thunderstomp" },
    ["Scorpid"] = { "High armor, poison hurts enemies", "Viel Rüstung, Gift schadet Gegnern" },
    ["Turtle"] = { "Top armor, Shell Shield protects", "Höchste Rüstung, Shell Shield schützt" },
    ["Tallstrider"] = { "More health, eats cheese and fruit", "Mehr Leben, frisst Käse und Obst" },
}

G.basics = {
    { "Offense: most damage. Defense: most health and armor. General: in between.",
      "Angriff: meister Schaden. Verteidigung: meiste Gesundheit und Rüstung. Allgemein: dazwischen." },
    { "Feed your pet often with food of its diet. A hungry pet gets unhappy and finally runs away.",
      "Füttere deinen Begleiter oft mit Nahrung seiner Art. Hunger macht ihn unzufrieden, am Ende läuft er weg." },
    { "A tamed pet keeps its level and has to level up in combat with you.",
      "Ein gezähmter Begleiter behält sein Level und muss mit dir im Kampf aufsteigen." },
    { "You must know an ability yourself before your pet can learn it. Some come only from wild beasts.",
      "Du musst eine Fähigkeit selbst kennen, bevor dein Begleiter sie lernt. Manche gibt es nur von wilden Tieren." },
    { "Training points depend on level and loyalty, so choose abilities with care.",
      "Trainingspunkte hängen von Level und Loyalität ab, wähle Fähigkeiten mit Bedacht." },
}

G.firstPet = {
    { "At level 10 your hunter trainer gives you the pet quest.",
      "Mit Level 10 gibt dir dein Jägerlehrer die Begleiter-Quest." },
    { "Finish both parts before you tame. The second one teaches feeding.",
      "Schließe beide Teile ab, bevor du zähmst. Der zweite lehrt das Füttern." },
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
local W, H = 440, 156

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsPetGuide", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("DIALOG")
    self.frame = f
    f.border = UI.Panel(f, 0.67, 0.83, 0.45)
    UI.PopupHead(f, W, { icon = true, divY = 70, onClose = function() f:Hide() end })
    f.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
    HHT.Icon.Attach(f.icon, true)
    f.eyebrow:SetText(L("LEVEL 10 REACHED"))
    f.eyebrow:SetTextColor(0.67, 0.83, 0.45)
    f.title:SetText(L("Time for your first pet"))
    f.body = UI.Text(f, L("Take the pet quest from your hunter trainer. Finish both parts before you tame, the second one teaches feeding."), 12, 0.92, 0.94, 0.97)
    f.body:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -82)
    f.body:SetWidth(W - 32)
    f.body:SetHeight(32)
    f.body:SetJustifyH("LEFT")
    f.body:SetJustifyV("TOP")

    f.map = UI.Button(f, 70, 24, L("Map"), G.ShowTrainers)
    f.map:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 14)
    f.way = UI.Button(f, 90, 24, L("Waypoint"), G.TrainerWaypoint)
    f.way:SetPoint("LEFT", f.map, "RIGHT", 8, 0)
    f.guide = UI.Button(f, 110, 24, L("Pet guide"), function()
        if HHT.PetDex then HHT.PetDex:Open("guide") end
    end)
    f.guide:SetPoint("LEFT", f.way, "RIGHT", 8, 0)
    UI.SetPrimary(f.guide, 0.67, 0.83, 0.45)

    f:Hide()
    HHT:MakeMovable(f, self, "main", L("Pet guide"))
end

function M:Show(preview)
    local f = self.frame
    if not f then return end
    local t = G.NearestTrainer()
    f.sub:SetText(t and string.format(L("Hunter trainer: %s, %s"), t[4] or "?", ZoneName(t[1])) or L("Hunter trainer: see the map"))
    f.body:SetWidth(2000)
    local w = UI.PopupFit(f, math.max(70 + 8 + 90 + 8 + 110, f.body:GetStringWidth()), 340, 440)
    f.body:SetWidth(w - 32)
    local bodyH = math.ceil(f.body:GetStringHeight())
    f.body:SetHeight(bodyH)
    f:SetHeight(82 + bodyH + 4 + 24 + 14)
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
