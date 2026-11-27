-- Quick install: Hamingway the Hambringer walks the player through every tool, one page at a time.
-- Only what is visible is offered here (on/off, position, size, border, icon style); the rest stays in /hht.
local ADDON, HHT = ...
local UI = HHT.UI
local D = HHT.Dwarf
local L = HHT.L

HHT:AddGerman({
    ["Quick install"] = "Schnell-Einrichtung",
    ["Start quick install"] = "Schnell-Einrichtung starten",
    ["Step %d of %d"] = "Schritt %d von %d",
    ["Welcome"] = "Willkommen",
    ["Look"] = "Aussehen",
    ["These change every module at once. Each module can still be set on its own page."] = "Diese ändern alle Module auf einmal. Jedes Modul lässt sich weiterhin auf seiner eigenen Seite einstellen.",
    ["All icons: shape"] = "Alle Symbole: Form",
    ["All borders: size (0 = none)"] = "Alle Rahmen: Stärke (0 = keiner)",
    ["All bars: texture"] = "Alle Leisten: Textur",
    ["All bars: corners"] = "Alle Leisten: Ecken",
    ["All borders: color"] = "Alle Rahmen: Farbe",
    ["Border glow"] = "Rahmen-Glühen",
    ["Glow strength"] = "Glüh-Stärke",
    ["Aimed Shot"] = "Gezielter Schuss",
    ["Done"] = "Fertig",
    ["How it works"] = "So funktioniert's",
    ["Good to know"] = "Gut zu wissen",
    ["Back"] = "Zurück",
    ["Next"] = "Weiter",
    ["Finish"] = "Fertig",
    ["Not now"] = "Später",
    ["Don't ask again"] = "Nicht mehr fragen",
    ["Let's go"] = "Los geht's",
    ["Skip all"] = "Alles überspringen",
    ["Show example"] = "Beispiel zeigen",
    ["Open pet database"] = "Tierdatenbank öffnen",
    ["Arrange examples"] = "Beispiele anordnen",
    ["Threat and distance"] = "Bedrohung und Entfernung",
    ["Pet and feeding"] = "Begleiter und Fütterung",
    ["Aspect, tracking and pet stance"] = "Aspekt, Aufspüren und Begleiter-Haltung",
    ["Pet popups"] = "Tier-Hinweise",
    ["Map layers"] = "Kartenebenen",
    ["Extras"] = "Extras",
    ["Drag the frame with the mouse while this page is open."] = "Verschiebe das Fenster mit der Maus, solange diese Seite offen ist.",
    ["Switch it on to place and style it."] = "Schalte es ein, um es zu platzieren und zu gestalten.",
    ["All tools are put aside while you set up, so you can watch each one appear. If you skip or close this, everything returns as it was."] =
        "Während der Einrichtung sind alle Werkzeuge beiseite gelegt, so siehst du jedes einzeln erscheinen. Überspringst oder schließt du, kommt alles so zurück, wie es war.",
    ["Drag the frame with the mouse. It stays visible until the quick install ends."] = "Verschiebe das Fenster mit der Maus. Es bleibt sichtbar, bis die Einrichtung endet.",
    ["Drag the example frame with the mouse while you are on this page."] = "Verschiebe das Beispielfenster mit der Maus, solange du auf dieser Seite bist.",
    ["Quick install is not available in combat."] = "Die Schnell-Einrichtung ist im Kampf nicht verfügbar.",
    ["Quick install closed because combat started."] = "Schnell-Einrichtung geschlossen, weil ein Kampf begonnen hat.",
    ["Only the most important settings are shown here."] = "Hier siehst du nur die wichtigsten Einstellungen.",
    ["Colours, sounds, filters and more wait for you in the settings."] =
        "Farben, Töne, Filter und mehr warten in den Einstellungen auf dich.",
    ["For every tool you decide if you want it, where it sits, how big it is and how it looks."] =
        "Bei jedem Werkzeug entscheidest du, ob du es willst, wo es sitzt, wie groß es ist und wie es aussieht.",
    ["You can leave at any time and start again with /hht setup or from the general settings."] =
        "Du kannst jederzeit aufhören und mit /hht setup oder in den allgemeinen Einstellungen neu starten.",
    ["%d tools are on, %d are off."] = "%d Werkzeuge sind an, %d sind aus.",
    ["Everything else can be changed in the settings: left click the minimap button or type /hht. News are in /hht news, and /hht setup starts this again."] =
        "Alles andere änderst du in den Einstellungen: Linksklick auf den Minimap-Knopf oder /hht. Neuigkeiten gibt es mit /hht news, und /hht setup startet das hier erneut.",
    ["Left click this button on the minimap to open the settings at any time."] =
        "Mit einem Linksklick auf diesen Knopf an der Minimap öffnest du jederzeit die Einstellungen.",
    ["Settings from another character"] = "Einstellungen eines anderen Charakters",
    ["You already have settings saved from other characters or profiles. Take them over, then go through the steps and adjust what you like."] =
        "Du hast schon gespeicherte Einstellungen von anderen Charakteren oder Profilen. Übernimm sie und geh dann die Schritte durch, um anzupassen, was du willst.",
    ["Take over these settings"] = "Diese Einstellungen übernehmen",
    ["Settings taken over from %s."] = "Einstellungen von %s übernommen.",
})

local S = {}
HHT.Setup = S

local W, BODY_H, TOP = 540, 252, 68
local MIN_BODY = 160
local win, pages = nil, {}

-- ---------------------------------------------------------------------------
-- Steps
-- ---------------------------------------------------------------------------
-- Pages. mods: key, test (shows an example popup), popup (frame is only shown and movable on its own page).
-- The options of a module are the ones of its settings page (BuildOptions and the layout of Layout.lua).
local STEPS = {
    { id = "welcome", title = "Welcome", fresh = true },
    { id = "look", title = "Look",
      say = { en = "First, how should the workshop look? Pick the style and the shape of yer icons, borders and bars. What ye pick here counts for every tool at once, and ye can still tweak each one on its own page. I've put all me tools aside for now, so ye can watch each one come back. Skip, and everything returns as it was.",
              de = "Zuerst: wie soll die Werkstatt aussehen? Wähle Stil und Form deiner Symbole, Rahmen und Leisten. Was du hier wählst, gilt sofort für jedes Werkzeug, und auf den einzelnen Seiten kannst du es noch feinjustieren. Ich habe mein ganzes Werkzeug beiseite gelegt, so siehst du jedes Stück zurückkehren. Überspringst du, kommt alles so zurück, wie es war." } },
    { id = "swing", mods = { { key = "swing" } },
          say = { en = "Yer swing timer. Keep it close to yer crosshair. The shot only fires 0.5 seconds after ye stand still, so ye can move until the bar hits the grey line!",
                  de = "Dein Swing-Timer. Halte ihn nah am Fadenkreuz. Der Schuss geht erst 0,5 Sekunden nach dem Stehenbleiben raus, du kannst dich also bewegen, bis die Leiste die graue Markierung erreicht!" } },
    { id = "castbar", mods = { { key = "castbar" } },
      say = { en = "The cast bar shows yer shots and spells. Tick the box to hide the default one. If another addon already has a cast bar, switch this off.",
              de = "Die Zauberleiste zeigt Schüsse und Zauber. Setze den Haken, um die Standard-Leiste auszublenden. Hat schon ein anderes Addon eine Zauberleiste, schalte diese aus." } },
    { id = "cooldowns", mods = { { key = "cooldowns" } },
      say = { en = "Yer cooldowns, in plain sight. Click the icons, or give 'em yer own keys in the settings. That keeps yer action bar tidy as a dwarven vault.",
              de = "Deine Abklingzeiten, gut sichtbar. Klicke die Symbole oder gib ihnen in den Einstellungen eigene Tasten. So bleibt deine Aktionsleiste aufgeräumt wie ein Zwergentresor." } },
    { id = "warnings", mods = { { key = "warnings" } },
      say = { en = "Warnings for what a hunter forgets: aspect, mark, pet. Show 'em always or only in combat, as ye please.",
              de = "Warnungen für das, was ein Jäger gern vergisst: Aspekt, Mal, Begleiter. Zeige sie immer oder nur im Kampf, ganz wie du magst." } },
    { id = "aspects", title = "Aspect, tracking and pet stance", mods = { { key = "aspects" }, { key = "petstance" } },
      say = { en = "One button for yer aspect, one for tracking and one for yer pet's stance. Click it or bind a key. A right-click lists everything ye know.",
              de = "Ein Knopf für deinen Aspekt, einer für das Aufspüren und einer für die Haltung deines Begleiters. Klicke ihn oder binde eine Taste. Ein Rechtsklick zeigt alles, was du kennst." } },
    { id = "debuffs", mods = { { key = "debuffs" } },
      say = { en = "What ye put on the target: stings, marks and the like. Set it where it does not block yer view.",
              de = "Was du auf das Ziel legst: Stiche, Male und dergleichen. Setze es dorthin, wo es dir nicht die Sicht nimmt." } },
    { id = "procs", mods = { { key = "procs" } },
      say = { en = "Procs light up the screen when something good happens. Make 'em as big or as small as ye please.",
              de = "Procs lassen den Bildschirm aufleuchten, wenn etwas Gutes passiert. Mach sie so groß oder klein, wie du willst." } },
    { id = "summons", mods = { { key = "summons" } },
      say = { en = "Summoned helpers, such as yer hawks, with their timers.",
              de = "Beschworene Helfer, zum Beispiel deine Falken, mit ihren Zeitanzeigen." } },
    { id = "threat", title = "Threat and distance",
      mods = { { key = "threat" }, { key = "distance" } },
      say = { en = "Threat shows how close ye be to pullin' the beast off the tank. Distance tells ye if the target be in melee, in shootin' range or in the dead zone.",
              de = "Bedrohung zeigt, wie nah du daran bist, dem Tank das Biest abzunehmen. Entfernung sagt dir, ob das Ziel im Nahkampf, in Schussweite oder in der toten Zone steht." } },
    { id = "tranq", mods = { { key = "tranq" } },
      say = { en = "For tranquilizing shot rotations in raids. Most hunters leave this off until they need it.",
              de = "Für Einlullender-Schuss-Rotationen in Raids. Die meisten Jäger lassen das aus, bis sie es brauchen." } },
    { id = "pet", title = "Pet and feeding",
      mods = { { key = "pet" }, { key = "feeder" } },
      say = { en = "Yer companion: health, happiness and food. A fed pet be a happy pet, and a happy pet bites harder. Simple dwarven math. I can hide the default pet frame, or dock me bars onto it.",
              de = "Dein Begleiter: Gesundheit, Zufriedenheit und Futter. Ein gefütterter Begleiter ist ein froher Begleiter, und ein froher Begleiter beißt härter. Einfache Zwergenrechnung. Ich kann das Standard-Begleiterfenster ausblenden oder meine Leisten daran anheften." } },
    { id = "easytame", mods = { { key = "easytame" } },
      say = { en = "Easy tame: when a beast ye can tame stands in range and ye have no pet out, a button shows up. First click lays the Freezing Trap, the next one tames. Drag it where it does not cover the other warnings.",
              de = "Einfach zähmen: Steht ein zähmbares Tier in Reichweite und du hast keinen Begleiter draußen, erscheint ein Knopf. Der erste Klick legt die Eisfalle, der nächste zähmt. Ziehe ihn dorthin, wo er die anderen Warnungen nicht verdeckt." } },
    { id = "ammo", mods = { { key = "ammo" } },
      say = { en = "Yer ammo. Never run dry in the middle of a fight! I'll also tell ye when there be better ammo or a better quiver to be had.",
              de = "Deine Munition. Geh niemals mitten im Kampf leer aus! Ich sage dir auch Bescheid, wenn es bessere Munition oder einen besseren Köcher gibt." } },
    { id = "popups", title = "Pet popups",
      mods = { { key = "petwatch", popup = true },
               { key = "petnearby", popup = true },
               { key = "pettrain", popup = true }, { key = "petguide", popup = true } },
      say = { en = "These popups tell ye about rare beasts, new ranks yer pet can learn and where to train. The frames ye see be examples: drag 'em where ye want 'em and pick the size.",
              de = "Diese Hinweise melden seltene Tiere, neue Ränge, die dein Begleiter lernen kann, und wo du trainieren kannst. Die Fenster, die du siehst, sind Beispiele: Ziehe sie dorthin, wo du sie haben willst, und wähle die Größe." } },
    { id = "layers", title = "Map layers",
      mods = { { key = "ammovendors" }, { key = "foodvendors" },
               { key = "stablemasters" }, { key = "trainers" } },
      say = { en = "Marks for ammo, food, stable masters and trainers, on the world map and on the minimap too. Nothin' else on yer screen.",
              de = "Markierungen für Munition, Futter, Stallmeister und Lehrer, auf der Weltkarte und auch auf der Minimap. Sonst nichts auf dem Bildschirm." } },
    { id = "extras", title = "Extras",
      mods = { { key = "petdex", dex = true }, { key = "macros" }, { key = "mapbutton" } },
      say = { en = "A few extras: the beast database, ready-made macros and a map button.",
              de = "Ein paar Extras: die Tierdatenbank, fertige Makros und ein Kartenknopf." } },
    { id = "done", title = "Done", fresh = true,
      say = { en = "That be all! Anythin' else ye can fiddle with in the settings: left click the glowin' button on yer minimap. Now go, and may yer arrows fly true. I'll be by the fire!",
              de = "Das war's! Alles Weitere stellst du in den Einstellungen ein: Linksklick auf den leuchtenden Knopf an deiner Minimap. Und nun geh, mögen deine Pfeile treffen. Ich sitze am Kamin!" } },
}

local SAY_WELCOME = {
    en = "Well met, hunter! Name's Hamingway, Hamingway the Hambringer. Many a beast have I tracked, and many a boar have I... eaten. But me knees be achin' and the hearth be callin'. So I'm handin' ye me tools, forged over many a winter. Let me show ye 'round the workshop, one tool at a time. Take what ye need, leave the rest on the shelf!",
    de = "Seid gegrüßt, Jäger! Ich bin Hamingway, Hamingway der Hambringer. Manch Biest hab ich gejagt und manchen Eber... verspeist. Doch die Knie schmerzen und der Kamin ruft. Darum übergebe ich dir nun mein Werkzeug, geschmiedet über viele Winter. Ich zeig dir die Werkstatt, Stück für Stück. Nimm, was du brauchst, der Rest bleibt im Regal!",
}
local SAY_AGAIN = {
    en = "Back in the workshop already? Aye, let's tidy up. Same tools, new arrangement!",
    de = "Schon wieder in der Werkstatt? Na gut, räumen wir auf. Gleiches Werkzeug, neue Ordnung!",
}

-- ---------------------------------------------------------------------------
-- Pages
-- ---------------------------------------------------------------------------
local function IsFrame(m, e)
    return not m.noFrame
end

-- Rows the quick install hides, or places on their own row because the row they sit next to is hidden.
local SETUP_SKIP = { ["Unlock frame"] = true }
local SETUP_SKIP_POPUP = { ["Unlock frame"] = true, ["Show when"] = true }
local SETUP_SOLO = { ["Reset position"] = true }

-- The database window sits above the quick install. Escape would close both and undo the setup, so the setup leaves the Escape list while the database is open.
local function OpenDex()
    local dex = HHT.PetDex
    if not dex then return end
    dex:Open("beasts")
    local w = _G.HamingwaysHunterToolsPetDex
    if not w then return end
    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == "HHTSetup" then table.remove(UISpecialFrames, i) end
    end
    if not w.hhtSetupHook then
        w.hhtSetupHook = true
        w:HookScript("OnHide", function()
            for _, n in ipairs(UISpecialFrames) do if n == "HHTSetup" then return end end
            table.insert(UISpecialFrames, "HHTSetup")
        end)
    end
end

local function AddModule(form, e, first)
    local m = HHT.modules[e.key]
    if not m or m.wip then return end
    if not first then
        local gap = CreateFrame("Frame", nil, form.content)
        gap:SetSize(440, 16)
        form:Place(gap, 16, 4, 0)
    end
    -- Header row on a colour band: name on the left, on/off switch on the right.
    local row = CreateFrame("Frame", nil, form.content)
    row:SetSize(470, 30)
    local c = UI.PAL.head
    local band = row:CreateTexture(nil, "BACKGROUND")
    band:SetAllPoints(row)
    UI.Gradient(band, false, c[1], c[2], c[3], 0.34, 0.04)
    local edge = row:CreateTexture(nil, "ARTWORK")
    edge:SetColorTexture(c[1], c[2], c[3], 0.95)
    edge:SetWidth(3)
    edge:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    edge:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    local head = UI.Header(row, L(m.name))
    head:SetPoint("LEFT", row, "LEFT", 12, 0)
    local sw = UI.Switch(row, function() return m.db.enabled end, function(v)
        m.db.enabled = v and true or false
        HHT:SetEnabled(m, m.db.enabled)
        S:Rebuild()
    end)
    sw:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    local sl = UI.Text(row, L("Module enabled"), 12, 0.85, 0.85, 0.85)
    sl:SetPoint("RIGHT", sw, "LEFT", -8, 0)
    form:Place(row, 30, 4, 6)
    form:Note(L(m.desc))
    if not m.db.enabled then
        form:Note(L("Switch it on to place and style it."), 0.67, 0.83, 0.45)
        return
    end
    local frame = IsFrame(m, e)
    if frame then
        form:Note(L(e.popup and "Drag the example frame with the mouse while you are on this page."
            or "Drag the frame with the mouse. It stays visible until the quick install ends."), 0.67, 0.83, 0.45)
    end
    -- The same rows as on the settings page. The frames are unlocked by the quick install itself.
    local from = #form.entries + 1
    HHT.CommonOptions(m, form)
    if m.BuildOptions then
        local ok, err = pcall(m.BuildOptions, m, form)
        if not ok then HHT.Print("Quick install: " .. m.key .. ": " .. tostring(err)) end
    end
    form:ApplyLayout(HHT.Layout and HHT.Layout[e.key], HHT.Tips, {
        from = from, secId = e.key, solo = SETUP_SOLO, skip = e.popup and SETUP_SKIP_POPUP or SETUP_SKIP })
    if e.test then form:Button(L("Show example"), function() HHT.RunTest(e.test) end, 170) end
    if e.dex then form:Button(L("Open pet database"), OpenDex, 170) end
end

local PREVIEW_ICONS = {
    { "Ability_Hunter_RunningShot", "T" },
    { "Spell_Frost_FreezingBreath", "G" },
}

-- Sample icons and a cast bar that fills over and over, in the current look, so every choice can be judged right away.
-- The group is centred with room on every side for the border glow.
local function StylePreview(page)
    local row = CreateFrame("Frame", nil, page)
    row:SetPoint("TOP", page, "TOP", 0, -4)
    row:SetSize(460, 64)
    local size, gap, barW, space = 40, 14, 230, 36
    local start = (460 - (#PREVIEW_ICONS * size + (#PREVIEW_ICONS - 1) * gap + space + barW)) / 2
    row.icons = {}
    for i, p in ipairs(PREVIEW_ICONS) do
        local ic = HHT.Icon.New(row)
        ic:SetPoint("LEFT", row, "LEFT", start + (i - 1) * (size + gap), 0)
        ic:SetIcon("Interface\\Icons\\" .. p[1])
        ic:SetKey(p[2], 12, "TOPRIGHT")
        row.icons[i] = ic
    end

    local cb = HHT.modules.castbar
    local bdb = {
        width = barW, height = 20, bgAlpha = 0.85, bevel = 0.6, showLabel = true, showTime = true,
        flashGlow = 1, flashGlowSize = 8,
        colors = setmetatable({}, { __index = cb and cb.db.colors or { cast = { 0.67, 0.83, 0.45 }, bg = { 0.05, 0.04, 0.03 },
            edge = { 0.55, 0.42, 0.2 }, text = { 0.95, 0.93, 0.85 } } }),
    }
    local bar = HHT.Bar.New(row)
    bar:SetPoint("RIGHT", row, "RIGHT", -start, 0)
    bar.label:SetText(L("Aimed Shot"))
    row.bar = bar

    function row:Update()
        local c = HHT.Look.borderColor
        for _, ic in ipairs(self.icons) do
            ic:SetBorderColor(c[1], c[2], c[3])
            ic:Style(size, HHT.Look.shape, HHT.Look.borderSize, 1, false)
        end
        bdb.border = HHT.Look.borderSize > 0
        bdb.borderSize = HHT.Look.borderSize
        bdb.colors.edge = HHT.Look.borderColor
        bdb.barTexture = HHT.Look.barTexture
        bdb.barShape = HHT.Look.barShape
        HHT.Bar.Apply(bar, bdb, "cast")
    end

    -- 2.4 s of casting, a flash when full, a short pause, then again.
    local t, flashed = 0, false
    row:SetScript("OnUpdate", function(_, dt)
        t = t + dt
        if t > 3.4 then t, flashed = 0, false end
        local p = math.min(1, t / 2.4)
        bar.bar:SetMinMaxValues(0, 1)
        bar.bar:SetValue(p)
        bar.time:SetText(string.format("%.1f", 2.4 * (1 - p)))
        bar.spark:ClearAllPoints()
        bar.spark:SetPoint("CENTER", bar.bar, "LEFT", (bar:GetWidth() - 2) * p, 0)
        bar.spark:SetShown(p < 1)
        if p >= 1 and not flashed then
            flashed = true
            HHT.Bar.Flash(bar)
        end
    end)
    row:Update()
    return row
end

-- The preview stays above the scrolling options, so it is always in view.
local function BuildLook(form, page)
    local g = HHT.db.general
    local preview = StylePreview(page)
    local function Changed() preview:Update() end
    form:Cycle(L("Style of icons and bars"), g, "style", {
        { "flat", L("Flat") }, { "bevel", L("3D frame") }, { "glass", L("Glass") } },
        function()
            HHT:RefreshAll()
            HHT.Icon.RefreshFinish()
            Changed()
        end)
    -- These apply to every module at once, whatever each one was set to before.
    form:Cycle(L("All icons: shape"), HHT.Look, "shape", HHT.ShapeChoices(), Changed)
    form:Stepper(L("All borders: size (0 = none)"), HHT.Look, "borderSize", 0, 4, 1, Changed)
    form:Color(L("All borders: color"), HHT.Look, "borderColor", Changed)
    form:Check(L("Border glow"), g, "borderGlow", function()
        HHT:RefreshAll()
        HHT.Icon.RefreshFinish()
        Changed()
        S:Rebuild()
    end)
    if g.borderGlow then
        form:Stepper(L("Glow strength"), g, "borderGlowSize", 1, 8, 1, function()
            HHT:RefreshAll()
            HHT.Icon.RefreshFinish()
            Changed()
        end)
    end
    form:Cycle(L("All bars: texture"), HHT.Look, "barTexture", HHT.Bar.TextureChoices(), Changed)
    form:Cycle(L("All bars: corners"), HHT.Look, "barShape", HHT.Bar.ShapeChoices(), Changed)
end

-- Row with the minimap button's logo next to a note.
local function LogoRow(form, text)
    local row = CreateFrame("Frame", nil, form.content)
    row:SetSize(460, 36)
    local logo = row:CreateTexture(nil, "ARTWORK")
    logo:SetSize(32, 32)
    logo:SetPoint("LEFT", row, "LEFT", 0, 0)
    logo:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\HHT_Logo")
    local fs = UI.Text(row, text, 11, 0.67, 0.83, 0.45)
    fs:SetPoint("LEFT", logo, "RIGHT", 10, 0)
    fs:SetWidth(410)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(true)
    form:Place(row, 36, 4, 8)
end

local function Count()
    local on, off = 0, 0
    HHT:EachModule(function(m)
        if not m.wip then
            if m.db.enabled then on = on + 1 else off = off + 1 end
        end
    end)
    return on, off
end

local function BuildPage(i)
    local step = STEPS[i]
    local frame = CreateFrame("Frame", nil, win.body)
    frame:SetAllPoints(win.body)
    local list = frame
    if step.id == "look" then
        list = CreateFrame("Frame", nil, frame)
        list:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -74)
        list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    end
    local form = UI.NewForm(list, function()
        -- A scale change moves a frame's corner; each popup keeps the spot it was dragged to.
        local corners = step.id == "popups" and S:PopupCorners()
        for _, e in ipairs(step.mods or {}) do
            local m = HHT.modules[e.key]
            if m then HHT:RefreshModule(m) end
        end
        HHT:ApplyAllLooks()
        if corners then S:RestoreCorners(corners) end
    end, "setup" .. step.id)

    if step.id == "welcome" then
        local function Head(t) form:Place(UI.Header(form.content, L(t)), 16, 4, 6) end
        local function Bullet(t) form:Note("-  " .. L(t), 0.82, 0.82, 0.82) end
        form:Cycle(L("Language"), HHT.db.general, "lang", {
            { "auto", L("Automatic") }, { "en", "English" }, { "de", "Deutsch" }, { "es", "Español" } },
            function() S:Relang() end)
        Head("How it works")
        Bullet("For every tool you decide if you want it, where it sits, how big it is and how it looks.")
        Bullet("Only the most important settings are shown here.")
        Bullet("Colours, sounds, filters and more wait for you in the settings.")
        Bullet("You can leave at any time and start again with /hht setup or from the general settings.")
        Head("Good to know")
        LogoRow(form, L("Left click this button on the minimap to open the settings at any time."))
        form:Note(L("All tools are put aside while you set up, so you can watch each one appear. If you skip or close this, everything returns as it was."), 0.67, 0.83, 0.45)
    elseif step.id == "look" then
        BuildLook(form, frame)
    elseif step.id == "done" then
        local on, off = Count()
        form:Note(string.format(L("%d tools are on, %d are off."), on, off))
        form:Note(L("Everything else can be changed in the settings: left click the minimap button or type /hht. News are in /hht news, and /hht setup starts this again."))
        LogoRow(form, L("Left click this button on the minimap to open the settings at any time."))
    else
        local first = true
        for _, e in ipairs(step.mods or {}) do
            local m = HHT.modules[e.key]
            if m and not m.wip then
                AddModule(form, e, first)
                first = false
            end
        end
        if step.id == "popups" then
            form:Button(L("Arrange examples"), function() S:ArrangePopups(true) end, 170)
        end
    end
    frame.form = form
    return frame
end

-- ---------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------
function S:Layout(dwarfH)
    if not win then return end
    local region = math.max(dwarfH or D.PORTRAIT, 112)
    self.region = region
    win.body:ClearAllPoints()
    win.body:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -(TOP + region + 8))
    win.body:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 46)
    win:SetHeight(TOP + region + 8 + (tonumber(HHT.db.general.setupBodyH) or BODY_H) + 46)
end

-- Every enabled frame stays visible and movable until the quick install ends, so the whole layout can be built.
function S:SyncMove()
    local want = {}
    if self.open and self.snap then
        for _, step in ipairs(STEPS) do
            for _, e in ipairs(step.mods or {}) do
                local m = HHT.modules[e.key]
                if m and m.enabled and IsFrame(m, e) and (not e.popup or STEPS[self.step] == step) then want[m.key] = true end
            end
        end
    end
    HHT:EachModule(function(m) m.moveUnlock = want[m.key] and true or nil end)
    local procs = HHT.modules.procs
    if procs then procs.previewSolo = want.procs and true or nil end -- only the first graphic (Quick Shots) in the preview
    HHT:ApplyLock()
end

local function PopupFrames()
    local step = STEPS[S.step]
    local list = {}
    if not step or step.id ~= "popups" then return list end
    for _, e in ipairs(step.mods) do
        local m = HHT.modules[e.key]
        if m and m.enabled then
            for _, f in ipairs({ m.frame, m.zone }) do
                if f and f:IsShown() then list[#list + 1] = f end
            end
        end
    end
    return list
end

-- Top left corner of every shown popup in screen units, so it can be put back after a scale change.
function S:PopupCorners()
    local t = {}
    for _, f in ipairs(PopupFrames()) do
        local l, tp, s = f:GetLeft(), f:GetTop(), f:GetScale()
        if l and tp then t[#t + 1] = { f = f, x = l * s, y = (tp - UIParent:GetHeight() / s) * s } end
    end
    return t
end

function S:RestoreCorners(t)
    if InCombatLockdown() then return end
    for _, c in ipairs(t) do
        local s = c.f:GetScale()
        c.f:ClearAllPoints()
        c.f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", c.x / s, c.y / s)
    end
end

-- True while a popup still sits at its default spot, so the player never moved it.
local function AtDefault(f)
    local info = f.hht
    local m = info and info.module
    local pos = m and m.db.pos and m.db.pos[info.key]
    if not pos then return true end
    local d = m.positions and m.positions[info.key] or { "CENTER", "CENTER", 0, 0 }
    for i = 1, 4 do
        if pos[i] ~= d[i] then return false end
    end
    return true
end

-- Lines the example popups up side by side at the top of the screen, centred, so none covers another.
-- Popups the player has moved keep their place unless force is set (the "Arrange examples" button).
-- Only the frames' current anchors change; the saved positions stay as they are until a frame is dragged.
function S:ArrangePopups(force)
    if not self.open or InCombatLockdown() then return end
    local items = {}
    for _, f in ipairs(PopupFrames()) do
        if force or AtDefault(f) then
            local s = f:GetScale()
            -- the 3D view of a rare beast hangs off the left edge, outside the frame
            local side = (f.modelBg and f.modelBg:IsShown()) and (f.modelBg:GetWidth() + 8) * s or 0
            items[#items + 1] = { f = f, s = s, side = side, w = f:GetWidth() * s + side, h = f:GetHeight() * s }
        end
    end
    if #items == 0 then return end
    local maxW, gap, y = UIParent:GetWidth() - 40, 12, 14
    local i = 1
    while i <= #items do
        local row, rowW, rowH = {}, 0, 0
        while i <= #items and (#row == 0 or rowW + gap + items[i].w <= maxW) do
            local it = items[i]
            rowW = rowW + (#row > 0 and gap or 0) + it.w
            rowH = math.max(rowH, it.h)
            row[#row + 1] = it
            i = i + 1
        end
        local x = (UIParent:GetWidth() - rowW) / 2
        for _, it in ipairs(row) do
            it.f:ClearAllPoints()
            it.f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (x + it.side) / it.s, -y / it.s)
            x = x + it.w + gap
        end
        y = y + rowH + gap
    end
end

-- The popups size themselves a moment after they appear, so the layout runs again shortly after.
function S:ArrangeLater()
    for _, d in ipairs({ 0.3, 1 }) do
        C_Timer.After(d, function() S:ArrangePopups() end)
    end
end

local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = DeepCopy(x) end
    return t
end

local SAVED_GENERAL = { "lang", "style", "borderGlow", "borderGlowSize" }
-- Taking over settings changes more of the general options; these keep their value when the quick install is cancelled.
local KEEP_GENERAL = { setupDone = true, setupAsk = true, seenVersion = true, origin = true, fold = true }

-- A module that fails while switching must not stop the others; its frame is hidden by hand.
local function Switch(m, on)
    local ok, err = pcall(HHT.SetEnabled, HHT, m, on)
    if ok then return end
    HHT.Print("Quick install: " .. m.key .. ": " .. tostring(err))
    if not on and m.frame then pcall(m.frame.Hide, m.frame) end
end

-- All tools are put aside as soon as the installer opens; the old settings are kept to bring them back on skip.
function S:Begin()
    if self.snap then return end
    local g = HHT.db.general
    local snap = { mods = {}, general = {} }
    for _, k in ipairs(SAVED_GENERAL) do snap.general[k] = g[k] end
    self.snap = snap
    self.visited = {}
    HHT:EachModule(function(m)
        if not m.wip then
            snap.mods[m.key] = DeepCopy(m.db)
            Switch(m, false)
        end
    end)
end

-- Takes over the settings of another character or a profile. The quick install keeps working on top of them, and cancelling still restores the old state.
function S:Adopt(src)
    if not src or not HHT.Profile then return end
    local snap = self.snap
    if snap and not snap.generalFull then snap.generalFull = DeepCopy(HHT.db.general) end
    local n = HHT.Profile.Load(src.text)
    if not n then
        HHT.Print(L("This text is not a valid settings export."))
        return
    end
    -- the source already decided which tools are on, so no page switches one on later
    if self.visited then
        for i = 1, #STEPS do self.visited[i] = true end
    end
    self.adopted = src.label
    self:Relang()
    if win then
        win.dwarf:Say(D.Pick({
            en = "Ha! Ye got a workshop set up elsewhere already. I fetched yer settings over. Go through the steps and change whatever ye fancy!",
            de = "Ha! Du hast ja schon anderswo eine Werkstatt eingerichtet. Ich hab deine Einstellungen herübergeholt. Geh die Schritte durch und ändere, was dir gefällt!",
        }))
    end
end

-- dataOnly: only write the saved values back (logout), without switching anything on.
function S:Restore(dataOnly)
    local snap = self.snap
    if not snap then return end
    self.snap = nil
    local g = HHT.db.general
    local langChanged = g.lang ~= snap.general.lang
    for k, v in pairs(snap.general) do g[k] = v end
    if snap.generalFull then
        for k, v in pairs(snap.generalFull) do
            if not KEEP_GENERAL[k] then g[k] = v end
        end
        langChanged = true
    end
    HHT:EachModule(function(m)
        local old = snap.mods[m.key]
        if not old then return end
        if not dataOnly then Switch(m, false) end
        for k in pairs(m.db) do m.db[k] = nil end
        for k, v in pairs(old) do m.db[k] = v end
        if not dataOnly and old.enabled then Switch(m, true) end
    end)
    if dataOnly then return end
    if langChanged and HHT.Config and HHT.Config.Relang then HHT.Config:Relang() end
    HHT:ApplyAllPositions()
    HHT:ApplyAllLooks()
    HHT.Icon.RefreshFinish()
end

function S:Complete()
    local g = HHT.db.general
    g.setupDone = HHT.version
    self.snap = nil
    win:Hide()
end

local function Window()
    if win then return win end
    win = UI.Window("HHTSetup", W, 500, L("Quick install") .. " - Hamingway's HunterTools")
    local saved = tonumber(HHT.db.general.setupScale)
    if saved then win:SetScale(math.min(1.6, math.max(0.6, saved))) end
    win:SetPoint("TOP", UIParent, "TOP", 0, -90)
    local grip = UI.ScaleGrip(win, function() HHT.db.general.setupScale = win:GetScale() end)
    -- smaller than in the settings window so it stays clear of the Next button
    grip:SetSize(12, 12)
    grip:ClearAllPoints()
    grip:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -2, 2)
    UI.HeightGrip(win, function() return (S.region or 112) + TOP + 8 + MIN_BODY + 46 end, function(h)
        HHT.db.general.setupBodyH = math.floor(h - TOP - (S.region or 112) - 8 - 46 + 0.5)
    end)
    win:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "HHTSetup") end

    win.progress = UI.Text(win, "", 11, 0.72, 0.74, 0.78)
    win.progress:SetPoint("LEFT", win, "TOPLEFT", 14, -42)
    local track = CreateFrame("Frame", nil, win)
    track:SetSize(W - 28, 6)
    track:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -54)
    UI.Round(track, 3, 1, 1, 1, 0.1)
    win.fill = CreateFrame("Frame", nil, track)
    win.fill:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
    win.fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 0, 0)
    local a = UI.ACCENT
    UI.Round(win.fill, 3, a[1], a[2], a[3], 0.9, "ARTWORK")

    win.body = CreateFrame("Frame", nil, win)
    win.body:SetSize(W - 28, BODY_H)
    win.dwarf = D.New(win, W - 28, function(h) S:Layout(h) end)
    win.dwarf:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -TOP)

    win.b1 = UI.Button(win, 100, 22, "", function() S:Left() end)
    win.b1:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 12)
    win.b3 = UI.Button(win, 120, 22, "", function() S:Right() end)
    win.b3:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 12)
    UI.SetPrimary(win.b3, a[1], a[2], a[3])
    win.b2 = UI.Button(win, 140, 22, "", function() S:Middle() end)
    win.b2:SetPoint("RIGHT", win.b3, "LEFT", -8, 0)

    win:SetScript("OnShow", function() S.open = true end)
    win:SetScript("OnHide", function()
        S.open = false
        if HHT.Config then HHT.Config:FlashMinimap(false) end
        if S.snap then
            if InCombatLockdown() then S.restoreLater = true else S:Restore() end
        end
        S:SyncMove()
    end)
    S:Layout(D.PORTRAIT)
    return win
end

-- Offer to take over settings from another character: a small panel beside the window, shown on the first page only.
local ADOPT_W = 250

local function AdoptPanel()
    if S.adopt then return S.adopt end
    local p = UI.Window("HHTSetupAdopt", ADOPT_W, 160, L("Settings from another character"))
    p:SetParent(win)
    p:SetFrameStrata("DIALOG")
    p.close:Hide()
    p:SetScript("OnDragStart", nil)
    p.title:SetWidth(ADOPT_W - 24)
    p.title:SetJustifyH("LEFT")
    p.note = UI.Text(p, "", 11, 0.67, 0.83, 0.45)
    p.note:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -40)
    p.note:SetWidth(ADOPT_W - 24)
    p.note:SetJustifyH("LEFT")
    p.note:SetWordWrap(true)
    p.pick = UI.Button(p, ADOPT_W - 24, 22, "", function(btn)
        local items = {}
        for n, s in ipairs(p.sources) do items[n] = { label = s.label, value = n } end
        UI.ShowMenu(btn, items, function(item)
            S.adoptIndex = item.value
            btn:SetLabel(item.label)
        end)
    end)
    p.take = UI.Button(p, ADOPT_W - 24, 22, "", function() S:Adopt(p.sources[S.adoptIndex]) end)
    p.done = UI.Text(p, "", 11, 0.85, 0.85, 0.85)
    p.done:SetWidth(ADOPT_W - 24)
    p.done:SetJustifyH("LEFT")
    p.done:SetWordWrap(true)
    S.adopt = p
    return p
end

function S:UpdateAdopt()
    local sources = (self.step == 1 and HHT.Profile and HHT.Profile.Sources()) or {}
    if #sources == 0 then
        if self.adopt then self.adopt:Hide() end
        return
    end
    local p = AdoptPanel()
    p.sources = sources
    self.adoptIndex = math.min(self.adoptIndex or 1, #sources)
    p.title:SetText(L("Settings from another character"))
    p.note:SetText(L("You already have settings saved from other characters or profiles. Take them over, then go through the steps and adjust what you like."))
    p.pick:SetLabel(sources[self.adoptIndex].label)
    p.take:SetLabel(L("Take over these settings"))
    p.pick:ClearAllPoints()
    p.pick:SetPoint("TOPLEFT", p.note, "BOTTOMLEFT", 0, -10)
    p.take:ClearAllPoints()
    p.take:SetPoint("TOPLEFT", p.pick, "BOTTOMLEFT", 0, -8)
    local h = 40 + p.note:GetStringHeight() + 10 + 22 + 8 + 22 + 14
    p.done:ClearAllPoints()
    if self.adopted then
        p.done:SetText(string.format(L("Settings taken over from %s."), self.adopted))
        p.done:SetPoint("TOPLEFT", p.take, "BOTTOMLEFT", 0, -8)
        p.done:Show()
        h = h + p.done:GetStringHeight() + 8
    else
        p.done:Hide()
    end
    p:SetHeight(h)
    p:ClearAllPoints()
    if (UIParent:GetRight() or 0) - (win:GetRight() or 0) >= ADOPT_W + 8 then
        p:SetPoint("TOPLEFT", win, "TOPRIGHT", 8, 0)
    else
        p:SetPoint("TOPRIGHT", win, "TOPLEFT", -8, 0)
    end
    p:Show()
end

function S:Left()
    if self.step == 1 then win:Hide() else self:Show(self.step - 1) end
end

function S:Middle()
    if self.step == 1 then HHT.db.general.setupAsk = false end
    win:Hide()
end

function S:Right()
    if self.step >= #STEPS then
        self:Complete()
        return
    end
    self:Show(self.step + 1)
end

function S:Show(i, quiet)
    local w = Window()
    local g = HHT.db.general
    i = math.max(1, math.min(#STEPS, i))
    self.step = i
    local step = STEPS[i]

    -- A tool starts switched on the first time its page is reached; later the choice stays as set.
    if self.snap and self.visited and not self.visited[i] then
        self.visited[i] = true
        for _, e in ipairs(step.mods or {}) do
            local m = HHT.modules[e.key]
            if m and not m.wip and not m.db.enabled and (m.enabledByDefault ~= false or (self.snap.mods[m.key] and self.snap.mods[m.key].enabled)) then Switch(m, true) end
        end
    end

    for k, p in pairs(pages) do
        if k ~= i or step.fresh then
            p:Hide()
            if k == i then pages[k] = nil end
        end
    end
    local page = pages[i]
    if not page then
        page = BuildPage(i)
        pages[i] = page
    end
    page:Show()
    -- a page built earlier may show values that another page changed since (the look settings apply to every tool)
    if page.form and page.form.Refresh then page.form:Refresh() end
    if not title then
        local m = step.mods and HHT.modules[step.mods[1].key]
        title = m and L(m.name) or ""
    end
    w.progress:SetText(string.format(L("Step %d of %d"), i, #STEPS) .. ": " .. title)
    w.fill:SetWidth(math.max(6, (W - 28) * i / #STEPS))

    local say = step.say
    if step.id == "welcome" then say = g.setupDone and SAY_AGAIN or SAY_WELCOME end
    if not quiet then w.dwarf:Say(D.Pick(say)) end
    if HHT.Config then HHT.Config:FlashMinimap(i == 1 or i == #STEPS) end

    if i == 1 then
        w.b1:SetLabel(L("Not now")); w.b2:SetLabel(L("Don't ask again")); w.b3:SetLabel(L("Let's go"))
        w.b2:Show()
    elseif i == #STEPS then
        w.b1:SetLabel(L("Back")); w.b3:SetLabel(L("Finish"))
        w.b2:Hide()
    else
        w.b1:SetLabel(L("Back")); w.b2:SetLabel(L("Skip all")); w.b3:SetLabel(L("Next"))
        w.b2:Show()
    end
    self:SyncMove()
    self:UpdateAdopt()
    if HHT.WhatsNew and HHT.WhatsNew.Dock then HHT.WhatsNew.Dock() end
    if step.id == "popups" and not quiet then self:ArrangeLater() end
end

-- Rebuilds the current page, for example after a module was switched on or off; the scroll position stays.
function S:Rebuild()
    local p = pages[self.step]
    local pos = p and p.form and p.form.sf:GetVerticalScroll()
    if p then p:Hide(); pages[self.step] = nil end
    self:Show(self.step, true)
    self:KeepScroll(pos)
end

function S:KeepScroll(pos)
    local np = pages[self.step]
    local sf = np and np.form and np.form.sf
    if not pos or pos <= 0 or not sf then return end
    sf:SetVerticalScroll(pos)
    C_Timer.After(0.05, function()
        if sf:IsVisible() then sf:SetVerticalScroll(math.min(pos, sf:GetVerticalScrollRange())) end
    end)
end

function S:RebuildAll()
    local cur = pages[self.step]
    local pos = cur and cur.form and cur.form.sf:GetVerticalScroll()
    for k, p in pairs(pages) do p:Hide(); pages[k] = nil end
    self:Show(self.step, true)
    self:KeepScroll(pos)
end

function S:Relang()
    local cur = pages[self.step]
    local pos = cur and cur.form and cur.form.sf:GetVerticalScroll()
    for k, p in pairs(pages) do p:Hide(); pages[k] = nil end
    if HHT.Config and HHT.Config.Relang then HHT.Config:Relang() end
    if win then
        win.title:SetText(L("Quick install") .. " - Hamingway's HunterTools")
    end
    self:Show(self.step or 1)
    self:KeepScroll(pos)
end

function S.Open(step)
    if not HHT.db then return end
    if InCombatLockdown() then
        HHT.Print(L("Quick install is not available in combat."))
        return
    end
    local cfg = HHT.Config
    if cfg and cfg.window and cfg.window:IsShown() then cfg.window:Hide() end
    local w = Window()
    S.restoreLater = false
    S.adopted, S.adoptIndex = nil, 1
    w:Show()
    S:Begin()
    S:Show(step or 1)
    if HHT.WhatsNew and HHT.WhatsNew.Dock then HHT.WhatsNew.Dock() end
end

-- ---------------------------------------------------------------------------
-- Start: once for a new character, closes when combat starts
-- ---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:SetScript("OnEvent", function(_, event)
    if not HHT.db then return end
    local g = HHT.db.general
    if event == "PLAYER_LOGOUT" then
        S:Restore(true)
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if S.restoreLater then
            S.restoreLater = false
            S:Restore()
        end
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        if win and win:IsShown() then
            win:Hide()
            HHT.Print(L("Quick install closed because combat started."))
        end
        return
    end
    -- Offered at every login until it was finished or "Don't ask again" was chosen (also for characters that existed before).
    if g.setupDone == nil and g.setupAsk ~= false then
        C_Timer.After(5, function()
            if HHT.db and not InCombatLockdown() then S.Open() end
        end)
    end
end)
