-- Hamingway the Hambringer: a retired dwarf who hands his tools to the player.
-- A portrait with a speech bubble that What's new and the quick install use to talk to the player.
local ADDON, HHT = ...
local UI = HHT.UI

local TEX = "Interface\\AddOns\\" .. ADDON .. "\\Media\\UI\\Hamingway"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PORTRAIT, GAP, SPEED = 104, 14, 80

local D = {}
HHT.Dwarf = D
D.NAME = "Hamingway the Hambringer"
D.PORTRAIT = PORTRAIT

-- t = { en = "...", de = "..." } -> the line in the current language, formatted with ...
function D.Pick(t, ...)
    local s = t[HHT.CurrentLang()] or t.en
    if select("#", ...) > 0 then s = string.format(s, ...) end
    return s
end

-- Portrait plus speech bubble. The frame is `width` wide, its height follows the spoken text
-- (onSize(height) is called when it changes). Anchor the returned frame yourself.
-- (size is an optional portrait size for compact uses such as the settings pages.)
function D.New(parent, width, onSize, size)
    local P = UI.PAL
    local ps = size or PORTRAIT
    local d = CreateFrame("Frame", nil, parent)
    d:SetSize(width, ps)

    local pic = d:CreateTexture(nil, "ARTWORK")
    pic:SetTexture(TEX)
    pic:SetSize(ps, ps)
    pic:SetPoint("TOPLEFT", d, "TOPLEFT", 0, 0)

    local bub = CreateFrame("Button", nil, d)
    bub:SetPoint("TOPLEFT", d, "TOPLEFT", ps + GAP, 0)
    bub:SetPoint("TOPRIGHT", d, "TOPRIGHT", 0, 0)
    bub:SetHeight(ps)
    UI.Round(bub, 8, P.inset[1], P.inset[2], P.inset[3], 0.55, "BACKGROUND")

    -- tail pointing at the dwarf: the left half of a turned square, clipped so it does not overlap the translucent bubble
    local clip = CreateFrame("Frame", nil, bub)
    clip:SetSize(9, 18)
    clip:SetPoint("TOPRIGHT", bub, "TOPLEFT", 0, -23)
    local tail = clip:CreateTexture(nil, "ARTWORK")
    tail:SetTexture(WHITE)
    tail:SetSize(12, 12)
    tail:SetPoint("CENTER", clip, "RIGHT", 0, 0)
    tail:SetVertexColor(P.inset[1], P.inset[2], P.inset[3], 0.55)
    local ok = pcall(clip.SetClipsChildren, clip, true) and pcall(tail.SetRotation, tail, math.rad(45))
    clip:SetShown(ok)

    local name = UI.Text(bub, D.NAME, 11, UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3])
    name:SetPoint("TOPLEFT", bub, "TOPLEFT", 12, -9)
    local text = UI.Text(bub, "", 12)
    text:SetPoint("TOPLEFT", bub, "TOPLEFT", 12, -26)
    text:SetWidth(width - ps - GAP - 24)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")

    d.bubble, d.text = bub, text

    local function Stop()
        bub:SetScript("OnUpdate", nil)
        text:SetText(d.full or "")
    end

    -- Says a line: the bubble sizes itself to the whole line, then the text is typed out (a click shows it all).
    function d:Say(line)
        self.full = line
        text:SetText(line)
        local bh = math.max(64, math.ceil(text:GetStringHeight()) + 38)
        bub:SetHeight(bh)
        self:SetHeight(math.max(bh, ps))
        if onSize then onSize(self:GetHeight()) end
        if UI.Anim() and #line > 0 then
            local shown, acc = 0, 0
            text:SetText("")
            bub:SetScript("OnUpdate", function(_, dt)
                acc = acc + dt * SPEED
                local n = math.floor(acc)
                if n <= shown then return end
                shown = n
                if shown >= #line then Stop() else text:SetText(line:sub(1, shown)) end
            end)
        else
            Stop()
        end
    end
    bub:SetScript("OnClick", Stop)
    bub:SetScript("OnHide", Stop)
    return d
end

-- What Hamingway says on each module's settings page.
D.LINES = {
    swing = { en = "Yer swing timer. The shot only fires 0.5 seconds after ye stand still, so ye can move until the bar hits the grey line!",
              de = "Dein Swing-Timer. Der Schuss geht erst 0,5 Sekunden nach dem Stehenbleiben raus, du kannst dich also bewegen, bis die Leiste die graue Markierung erreicht!" },
    castbar = { en = "The cast bar shows yer shots and spells. If another addon already has one, switch this off.",
                de = "Die Zauberleiste zeigt Schüsse und Zauber. Hat schon ein anderes Addon eine, schalte diese aus." },
    cooldowns = { en = "Yer cooldowns, in plain sight. Click the icons, or give 'em yer own keys further down.",
                  de = "Deine Abklingzeiten, gut sichtbar. Klicke die Symbole oder gib ihnen weiter unten eigene Tasten." },
    warnings = { en = "Warnings for what a hunter forgets: aspect, mark, pet. Pick the sounds and colours below.",
                 de = "Warnungen für das, was ein Jäger gern vergisst: Aspekt, Mal, Begleiter. Töne und Farben wählst du unten." },
    aspects = { en = "One button for yer aspect and one for tracking. Click it or bind a key. A right-click lists everything ye know.",
                de = "Ein Knopf für deinen Aspekt und einer für das Aufspüren. Klicke ihn oder binde eine Taste. Ein Rechtsklick zeigt alles, was du kennst." },
    debuffs = { en = "What ye put on the target: stings, marks and the like. Ye can pick which ones count and on which targets.",
                de = "Was du auf das Ziel legst: Stiche, Male und dergleichen. Du wählst, welche zählen und auf welchen Zielen." },
    procs = { en = "Procs light up the screen when something good happens. Make 'em as big or as small as ye please.",
              de = "Procs lassen den Bildschirm aufleuchten, wenn etwas Gutes passiert. Mach sie so groß oder klein, wie du willst." },
    summons = { en = "Summoned helpers, such as yer hawks, with their timers.",
                de = "Beschworene Helfer, zum Beispiel deine Falken, mit ihren Zeitanzeigen." },
    threat = { en = "Threat shows how close ye be to pullin' the beast off the tank. Keep an eye on it in a group.",
               de = "Bedrohung zeigt, wie nah du daran bist, dem Tank das Biest abzunehmen. Behalte sie in der Gruppe im Auge." },
    distance = { en = "Tells ye if the target be in melee, in shootin' range or in the dead zone.",
                 de = "Sagt dir, ob das Ziel im Nahkampf, in Schussweite oder in der toten Zone steht." },
    tranq = { en = "For tranquilizing shot rotations in raids. Most hunters leave this off until they need it.",
              de = "Für Einlullender-Schuss-Rotationen in Raids. Die meisten Jäger lassen das aus, bis sie es brauchen." },
    pet = { en = "Yer companion: health and happiness at a glance. A happy pet bites harder. Simple dwarven math.",
            de = "Dein Begleiter: Gesundheit und Zufriedenheit auf einen Blick. Ein froher Begleiter beißt härter. Einfache Zwergenrechnung." },
    feeder = { en = "One click and the beast be fed. Ye choose the food for each pet, and bad food goes on the blacklist.",
               de = "Ein Klick und das Tier ist satt. Du wählst das Futter für jeden Begleiter, schlechtes kommt auf die schwarze Liste." },
    ammo = { en = "Yer ammo. Never run dry in the middle of a fight! I'll also tell ye when there be better ammo or a better quiver to be had.",
             de = "Deine Munition. Geh niemals mitten im Kampf leer aus! Ich sage dir auch Bescheid, wenn es bessere Munition oder einen besseren Köcher gibt." },
    petwatch = { en = "I keep an eye out for rare beasts and the ones on yer wishlist, and point the way with an arrow.",
                 de = "Ich halte Ausschau nach seltenen Tieren und denen auf deiner Wunschliste und zeige dir den Weg mit einem Pfeil." },
    petnearby = { en = "A beast nearby that teaches yer pet a higher rank? I'll let ye know.",
                  de = "Ein Tier in der Nähe, das deinem Begleiter einen höheren Rang beibringt? Ich sage dir Bescheid." },
    pettrain = { en = "When yer pet can learn ranks ye already know, I pop up with a button for each one.",
                 de = "Kann dein Begleiter Ränge lernen, die du schon kennst, melde ich mich mit einem Knopf für jeden." },
    petguide = { en = "A little guide for new beast masters: which family fits yer play style.",
                 de = "Ein kleiner Ratgeber für neue Tiermeister: Welche Familie passt zu deinem Spielstil." },
    ammovendors = { en = "Ammo vendors on the world map and the minimap, with a waypoint to the nearest one.",
                    de = "Munitionshändler auf der Weltkarte und der Minimap, mit einem Wegpunkt zum nächsten." },
    foodvendors = { en = "Vendors with food for yer pet, on the world map and the minimap. I learn the missing ones as ye go.",
                    de = "Händler mit Futter für deinen Begleiter, auf der Weltkarte und der Minimap. Fehlende lerne ich unterwegs." },
    stablemasters = { en = "Stable masters on the world map and the minimap. I learn the missing ones as ye go.",
                      de = "Stallmeister auf der Weltkarte und der Minimap. Fehlende lerne ich unterwegs." },
    trainers = { en = "Hunter trainers and pet trainers on the world map and the minimap.",
                 de = "Jägerlehrer und Tierlehrer auf der Weltkarte und der Minimap." },
    petdex = { en = "The beast database: abilities, ranks, who teaches what, and where to find 'em.",
               de = "Die Tierdatenbank: Fähigkeiten, Ränge, wer was lehrt und wo du sie findest." },
    macros = { en = "Ready-made macros for pet, shots, traps and aspects. Drag 'em to yer bar, or add yer own.",
               de = "Fertige Makros für Begleiter, Schüsse, Fallen und Aspekte. Zieh sie auf deine Leiste oder füge eigene hinzu." },
    mapbutton = { en = "A button on the world map to switch the layers on and off.",
                  de = "Ein Knopf auf der Weltkarte, um die Ebenen ein- und auszuschalten." },
    support = { en = "Me knees be done, so I'm retirin' by the fire. A hot coffee would suit this old dwarf fine! And I promise, it won't go on ale. Well... not all of it.",
                de = "Meine Knie sind durch, ich setze mich am Kamin zur Ruhe. Ein heißer Kaffee wäre genau das Richtige für einen alten Zwerg! Und ich verspreche: Er geht nicht für Bier drauf. Na ja... nicht alles." },
}
