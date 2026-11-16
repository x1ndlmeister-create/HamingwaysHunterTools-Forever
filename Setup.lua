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
    ["Pet popups"] = "Tier-Hinweise",
    ["Map layers"] = "Kartenebenen",
    ["Extras"] = "Extras",
    ["Drag the frame with the mouse while this page is open."] = "Verschiebe das Fenster mit der Maus, solange diese Seite offen ist.",
    ["Switch it on to place and style it."] = "Schalte es ein, um es zu platzieren und zu gestalten.",
    ["All tools are put aside while you set up, so you can watch each one appear. If you skip or close this, everything returns as it was."] =
        "Während der Einrichtung sind alle Werkzeuge beiseite gelegt, so siehst du jedes einzeln erscheinen. Überspringst oder schließt du, kommt alles so zurück, wie es war.",
    ["Drag the frame with the mouse. It stays visible until the quick install ends."] = "Verschiebe das Fenster mit der Maus. Es bleibt sichtbar, bis die Einrichtung endet.",
    ["Drag the example frame with the mouse while you are on this page."] = "Verschiebe das Beispielfenster mit der Maus, solange du auf dieser Seite bist.",
    ["More options wait in the settings, and you can change everything later."] =
        "Mehr Optionen warten in den Einstellungen, alles lässt sich später ändern.",
    ["All settings are shown. You can change everything later in the settings."] =
        "Alle Einstellungen werden gezeigt. Du kannst alles später in den Einstellungen ändern.",
    ["Show all settings"] = "Alle Einstellungen zeigen",
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
local win, pages = nil, {}

-- ---------------------------------------------------------------------------
-- Option sets and steps
-- ---------------------------------------------------------------------------
-- { kind, key, label, min, max, step }; options a module does not have are left out.
local function Bar(minW, maxW, minH, maxH)
    return {
        { "check", "border", "Show border" },
        { "stepper", "width", "Bar width", minW, maxW, 10 },
        { "stepper", "height", "Bar height", minH, maxH, 1 },
        { "stepper", "spacing", "Spacing", 0, 12, 1 },
        { "stepper", "bgAlpha", "Background opacity", 0, 1, 0.05 },
        { "check", "showTime", "Show remaining time" },
        { "check", "showLabel", "Show bar labels" },
        { "bar", "barTexture" },
    }
end

local GROW = { { "right", "Right" }, { "left", "Left" }, { "up", "Up" }, { "down", "Down" } }

-- When a frame shows: always, in combat, with a target ...
local VIS = { "cycle", "visibility", "Show when", "visibility" }
local MINI = { { "check", "onMinimap", "Also show on the minimap" } }

local function Plus(list, ...)
    for _, o in ipairs({ ... }) do list[#list + 1] = o end
    return list
end

local function Icons(minS, maxS)
    return {
        { "cycle", "shape", "Icon shape" },
        { "stepper", "size", "Icon size", minS, maxS, 2 },
        { "stepper", "borderSize", "Border size", 0, 4, 1 },
        { "stepper", "borderAlpha", "Border alpha", 0, 1, 0.1 },
        { "stepper", "spacing", "Spacing", 0, 30, 1 },
        { "cycle", "grow", "Grow direction", GROW },
        { "stepper", "perRow", "Icons per row", 1, 20, 1 },
        { "check", "numbers", "Show cooldown numbers" },
    }
end

-- Pages. mods: key, opts, test (shows an example popup), popup (frame is only shown and movable on its own page).
local STEPS = {
    { id = "welcome", title = "Welcome", fresh = true },
    { id = "look", title = "Look",
      say = { en = "First, how should the workshop look? Pick yer language and the style of yer icons. I've put all me tools aside for now, so ye can watch each one come back. Skip, and everything returns as it was.",
              de = "Zuerst: wie soll die Werkstatt aussehen? Wähle deine Sprache und den Stil deiner Symbole. Ich habe mein ganzes Werkzeug beiseite gelegt, so siehst du jedes Stück zurückkehren. Überspringst du, kommt alles so zurück, wie es war." } },
    { id = "swing", mods = { { key = "swing",     opts = Plus(Bar(80, 600, 6, 40), VIS, { "check", "showMark", "Mark 0.5 s before the shot" }, { "check", "colorMark", "Color the bar for the last 0.5 s" }) } },
          say = { en = "Yer swing timer. Keep it close to yer crosshair. The shot only fires 0.5 seconds after ye stand still, so ye can move until the bar hits the grey line!",
                  de = "Dein Swing-Timer. Halte ihn nah am Fadenkreuz. Der Schuss geht erst 0,5 Sekunden nach dem Stehenbleiben raus, du kannst dich also bewegen, bis die Leiste die graue Markierung erreicht!" } },
    { id = "castbar", mods = { { key = "castbar", opts = Plus(Bar(100, 600, 8, 48), VIS) } },
      say = { en = "The cast bar shows yer shots and spells. If another addon already has one, switch this off.",
              de = "Die Zauberleiste zeigt Schüsse und Zauber. Hat schon ein anderes Addon eine, schalte diese aus." } },
    { id = "cooldowns", mods = { { key = "cooldowns",     opts = Plus(Icons(20, 96), VIS) } },
      say = { en = "Yer cooldowns, in plain sight. Click the icons, or give 'em yer own keys in the settings. That keeps yer action bar tidy as a dwarven vault.",
              de = "Deine Abklingzeiten, gut sichtbar. Klicke die Symbole oder gib ihnen in den Einstellungen eigene Tasten. So bleibt deine Aktionsleiste aufgeräumt wie ein Zwergentresor." } },
    { id = "warnings", mods = { { key = "warnings", opts = Plus(Icons(24, 128),
        { "check", "hideInCombat", "Hide warnings in combat" },
        { "cycle", "markTargets", "Hunter's Mark targets", { { "elite", "Elites and bosses only" }, { "all", "Every enemy" } } }) } },
      say = { en = "Warnings for what a hunter forgets: aspect, mark, pet. Show 'em always or only in combat, as ye please.",
              de = "Warnungen für das, was ein Jäger gern vergisst: Aspekt, Mal, Begleiter. Zeige sie immer oder nur im Kampf, ganz wie du magst." } },
    { id = "aspects", mods = { { key = "aspects", opts = Icons(24, 96) } },
      say = { en = "One button for yer aspect and one for tracking. Click it or bind a key. A right-click lists everything ye know.",
              de = "Ein Knopf für deinen Aspekt und einer für das Aufspüren. Klicke ihn oder binde eine Taste. Ein Rechtsklick zeigt alles, was du kennst." } },
    { id = "debuffs", mods = { { key = "debuffs", opts = Plus(Icons(16, 80), VIS,
        { "cycle", "filter", "Which debuffs", { { "mine", "Only my debuffs" }, { "all", "All debuffs" } } }) } },
      say = { en = "What ye put on the target: stings, marks and the like. Set it where it does not block yer view.",
              de = "Was du auf das Ziel legst: Stiche, Male und dergleichen. Setze es dorthin, wo es dir nicht die Sicht nimmt." } },
    { id = "procs", mods = { { key = "procs", opts = { { "stepper", "size", "Art size", 64, 400, 16 } } } },
      say = { en = "Procs light up the screen when something good happens. Make 'em as big or as small as ye please.",
              de = "Procs lassen den Bildschirm aufleuchten, wenn etwas Gutes passiert. Mach sie so groß oder klein, wie du willst." } },
    { id = "summons", mods = { { key = "summons", opts = Plus(Icons(20, 96), VIS) } },
      say = { en = "Summoned helpers, such as yer hawks, with their timers.",
              de = "Beschworene Helfer, zum Beispiel deine Falken, mit ihren Zeitanzeigen." } },
    { id = "threat", title = "Threat and distance",
      mods = { { key = "threat", opts = Plus(Bar(60, 400, 8, 40),
                   { "check", "onlyGroup", "Only in a group or with pet" },
                   { "check", "hideNoThreat", "Hide when no threat" }) },
               { key = "distance", opts = {
                   { "cycle", "layout", "Layout", { { "segments", "Segments" }, { "badge", "Badge" }, { "text", "Text only" } }, rebuild = true },
                   { "stepper", "size", "Size", 20, 120, 2 },
                   { "cycle", "shape", "Icon shape", only = { "layout", "badge" } },
                   { "check", "showText", "Show text" },
                   VIS } } },
      say = { en = "Threat shows how close ye be to pullin' the beast off the tank. Distance tells ye if the target be in melee, in shootin' range or in the dead zone.",
              de = "Bedrohung zeigt, wie nah du daran bist, dem Tank das Biest abzunehmen. Entfernung sagt dir, ob das Ziel im Nahkampf, in Schussweite oder in der toten Zone steht." } },
    { id = "tranq", mods = { { key = "tranq" } },
      say = { en = "For tranquilizing shot rotations in raids. Most hunters leave this off until they need it.",
              de = "Für Einlullender-Schuss-Rotationen in Raids. Die meisten Jäger lassen das aus, bis sie es brauchen." } },
    { id = "pet", title = "Pet and feeding",
      mods = { { key = "pet", opts = {
                  { "cycle", "shape", "Icon shape" },
                  { "stepper", "iconSize", "Portrait size", 20, 80, 2 },
                  { "stepper", "width", "Bar width", 60, 400, 10 },
                  { "stepper", "height", "Bar height", 8, 40, 1 },
                  { "check", "border", "Show border" },
                  { "check", "hideNoPet", "Hide when no pet" },
                  { "check", "showHappiness", "Show happiness" },
                  { "check", "showFocus", "Show focus bar" },
                  { "check", "showLevel", "Show level" },
                  { "check", "showXp", "Show experience bar" },
                  { "check", "showLoyalty", "Show loyalty bar" },
                  { "check", "showAbilities", "Show pet abilities" },
                  { "bar", "barTexture" } } },
               { key = "feeder", opts = Plus(Icons(20, 100),
                  { "cycle", "mode", "Show when", { { "always", "Always (with pet)" }, { "hungry", "Only when not happy" } } }) } },
      say = { en = "Yer companion: health, happiness and food. A fed pet be a happy pet, and a happy pet bites harder. Simple dwarven math.",
              de = "Dein Begleiter: Gesundheit, Zufriedenheit und Futter. Ein gefütterter Begleiter ist ein froher Begleiter, und ein froher Begleiter beißt härter. Einfache Zwergenrechnung." } },
    { id = "ammo", mods = { { key = "ammo", opts = Plus(Icons(20, 100), VIS,
        { "check", "onlyLow", "Only show when ammo is low" }) } },
      say = { en = "Yer ammo. Never run dry in the middle of a fight! I'll also tell ye when there be better ammo or a better quiver to be had.",
              de = "Deine Munition. Geh niemals mitten im Kampf leer aus! Ich sage dir auch Bescheid, wenn es bessere Munition oder einen besseren Köcher gibt." } },
    { id = "popups", title = "Pet popups",
      mods = { { key = "petwatch", popup = true,
                 opts = { { "check", "onlyMyLevel", "Only beasts up to my level" } } },
               { key = "petnearby", popup = true },
               { key = "pettrain", popup = true }, { key = "petguide", popup = true } },
      say = { en = "These popups tell ye about rare beasts, new ranks yer pet can learn and where to train. The frames ye see be examples: drag 'em where ye want 'em and pick the size.",
              de = "Diese Hinweise melden seltene Tiere, neue Ränge, die dein Begleiter lernen kann, und wo du trainieren kannst. Die Fenster, die du siehst, sind Beispiele: Ziehe sie dorthin, wo du sie haben willst, und wähle die Größe." } },
    { id = "layers", title = "Map layers",
      mods = { { key = "ammovendors", opts = MINI }, { key = "foodvendors", opts = MINI },
               { key = "stablemasters", opts = MINI }, { key = "trainers", opts = MINI } },
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

local function AddOption(form, m, o)
    local kind, key = o[1], o[2]
    if m.db[key] == nil then return end
    if o.only and m.db[o.only[1]] ~= o.only[2] then return end
    local extra = o.rebuild and function() S:Rebuild() end or nil
    if kind == "bar" then
        HHT.Bar.AddOptions(form, m.db)
        return
    end
    local label = L(o[3])
    if kind == "check" then
        form:Check(label, m.db, key)
    elseif kind == "stepper" then
        form:Stepper(label, m.db, key, o[4], o[5], o[6])
    elseif kind == "cycle" then
        local choices = HHT.ShapeChoices()
        if o[4] == "visibility" then
            choices = HHT.VisibilityChoices()
        elseif o[4] then
            choices = {}
            for i, c in ipairs(o[4]) do choices[i] = { c[1], L(c[2]) } end
        end
        form:Cycle(label, m.db, key, choices, extra)
    end
end

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

local function AddModule(form, e)
    local m = HHT.modules[e.key]
    if not m or m.wip then return end
    -- Header row: name on the left, on/off switch on the right.
    local row = CreateFrame("Frame", nil, form.content)
    row:SetSize(440, 22)
    local head = UI.Header(row, L(m.name))
    head:SetPoint("LEFT", row, "LEFT", 0, 0)
    local sw = UI.Switch(row, function() return m.db.enabled end, function(v)
        m.db.enabled = v and true or false
        HHT:SetEnabled(m, m.db.enabled)
        S:Rebuild()
    end)
    sw:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    local sl = UI.Text(row, L("Module enabled"), 12, 0.85, 0.85, 0.85)
    sl:SetPoint("RIGHT", sw, "LEFT", -8, 0)
    form:Place(row, 22, 4, 4)
    form:Note(L(m.desc))
    if not m.db.enabled then
        form:Note(L("Switch it on to place and style it."), 0.67, 0.83, 0.45)
        return
    end
    local frame = IsFrame(m, e)
    local all = S.showAll
    if frame then
        form:Note(L(e.popup and "Drag the example frame with the mouse while you are on this page."
            or "Drag the frame with the mouse. It stays visible until the quick install ends."), 0.67, 0.83, 0.45)
    end
    form:Note(L(all and "All settings are shown. You can change everything later in the settings."
        or "More options wait in the settings, and you can change everything later."), 0.67, 0.83, 0.45)
    if all then
        if frame then
            form:Stepper(L("Scale"), m.db, "scale", 0.5, 2, 0.05)
            form:Stepper(L("Opacity"), m.db, "alpha", 0.1, 1, 0.05)
        end
    else
        for _, o in ipairs(e.opts or {}) do AddOption(form, m, o) end
        if e.popup then form:Stepper(L("Scale"), m.db, "scale", 0.5, 2, 0.05) end
    end
    if frame then
        if not e.popup and m.db.visibility == nil then form:Check(L("Show only in combat"), m.db, "onlyCombat", function() HHT:ApplyAllLooks() end) end
        form:Button(L("Reset position"), function()
            m.db.pos = nil
            HHT:ApplyAllPositions()
        end, 170)
    end
    if all and m.BuildOptions then
        local ok, err = pcall(m.BuildOptions, m, form)
        if not ok then HHT.Print("Quick install: " .. m.key .. ": " .. tostring(err)) end
    end
    if e.test then form:Button(L("Show example"), function() HHT.RunTest(e.test) end, 170) end
    if e.dex then form:Button(L("Open pet database"), OpenDex, 170) end
end

local PREVIEW_ICONS = {
    { "Ability_Hunter_RunningShot", "T" },
    { "Ability_Rogue_FeignDeath", "SG" },
    { "Spell_Frost_FreezingBreath", "G" },
    { "Ability_Hunter_BeastCall", "M5" },
}

-- Four sample icons in the current style, so the style choice can be judged right away.
local function StylePreview(form)
    local row = CreateFrame("Frame", nil, form.content)
    row:SetSize(460, 64)
    local cd = HHT.modules.cooldowns
    local shape = (cd and cd.db.shape) or "round"
    local size, gap = 44, 12
    local x = (460 - (#PREVIEW_ICONS * size + (#PREVIEW_ICONS - 1) * gap)) / 2
    for i, p in ipairs(PREVIEW_ICONS) do
        local ic = HHT.Icon.New(row)
        ic:SetPoint("LEFT", row, "LEFT", x + (i - 1) * (size + gap), 0)
        ic:Style(size, shape, 2, 1, false)
        ic:SetIcon("Interface\\Icons\\" .. p[1])
        ic:SetKey(p[2], 12, "TOPRIGHT")
    end
    form:Place(row, 64, 4, 10)
end

local function BuildLook(form)
    local g = HHT.db.general
    StylePreview(form)
    form:Cycle(L("Language"), g, "lang", {
        { "auto", L("Automatic") }, { "en", "English" }, { "de", "Deutsch" } },
        function() S:Relang() end)
    form:Cycle(L("Style of icons and bars"), g, "style", {
        { "flat", L("Flat") }, { "bevel", L("3D frame") }, { "glass", L("Glass") } },
        function()
            HHT:RefreshAll()
            HHT.Icon.RefreshFinish()
        end)
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
    local form = UI.NewForm(frame, function()
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
        local sources = HHT.Profile and HHT.Profile.Sources() or {}
        if #sources > 0 then
            S.adoptIndex = math.min(S.adoptIndex or 1, #sources)
            Head("Settings from another character")
            form:Note(L("You already have settings saved from other characters or profiles. Take them over, then go through the steps and adjust what you like."), 0.67, 0.83, 0.45)
            local pick = UI.Button(form.content, 290, 22, sources[S.adoptIndex].label, function(btn)
                local items = {}
                for n, s in ipairs(sources) do items[n] = { label = s.label, value = n } end
                UI.ShowMenu(btn, items, function(item)
                    S.adoptIndex = item.value
                    btn:SetLabel(item.label)
                end)
            end)
            form:Place(pick, 22, 4, 6)
            form:Button(L("Take over these settings"), function() S:Adopt(sources[S.adoptIndex]) end, 220)
            if S.adopted then form:Note(string.format(L("Settings taken over from %s."), S.adopted)) end
        end
        Head("How it works")
        Bullet("For every tool you decide if you want it, where it sits, how big it is and how it looks.")
        Bullet("Only the most important settings are shown here.")
        Bullet("Colours, sounds, filters and more wait for you in the settings.")
        Bullet("You can leave at any time and start again with /hht setup or from the general settings.")
        Head("Good to know")
        LogoRow(form, L("Left click this button on the minimap to open the settings at any time."))
        form:Note(L("All tools are put aside while you set up, so you can watch each one appear. If you skip or close this, everything returns as it was."), 0.67, 0.83, 0.45)
    elseif step.id == "look" then
        BuildLook(form)
    elseif step.id == "done" then
        local on, off = Count()
        form:Note(string.format(L("%d tools are on, %d are off."), on, off))
        form:Note(L("Everything else can be changed in the settings: left click the minimap button or type /hht. News are in /hht news, and /hht setup starts this again."))
        LogoRow(form, L("Left click this button on the minimap to open the settings at any time."))
    else
        for _, e in ipairs(step.mods or {}) do AddModule(form, e) end
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
    win.body:ClearAllPoints()
    win.body:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -(TOP + region + 8))
    win:SetHeight(TOP + region + 8 + BODY_H + 46)
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

local SAVED_GENERAL = { "lang", "style" }
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
    win:SetPoint("TOP", UIParent, "TOP", 0, -90)
    win:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "HHTSetup") end

    win.progress = UI.Text(win, "", 11, 0.72, 0.74, 0.78)
    win.progress:SetPoint("LEFT", win, "TOPLEFT", 14, -42)
    win.allSwitch = UI.Switch(win, function() return S.showAll end, function(v)
        S.showAll = v and true or false
        S:RebuildAll()
    end)
    win.allSwitch:SetPoint("RIGHT", win, "TOPRIGHT", -14, -42)
    win.allLabel = UI.Text(win, L("Show all settings"), 11, 0.85, 0.85, 0.85)
    win.allLabel:SetPoint("RIGHT", win.allSwitch, "LEFT", -8, 0)
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

    local title = step.title and L(step.title)
    if not title then
        local m = step.mods and HHT.modules[step.mods[1].key]
        title = m and L(m.name) or ""
    end
    w.progress:SetText(string.format(L("Step %d of %d"), i, #STEPS) .. ": " .. title)
    w.fill:SetWidth(math.max(6, (W - 28) * i / #STEPS))
    local hasMods = step.mods ~= nil
    w.allSwitch:SetShown(hasMods)
    w.allLabel:SetShown(hasMods)

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
        win.allLabel:SetText(L("Show all settings"))
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
    S.showAll = false
    S.adopted, S.adoptIndex = nil, 1
    w.allSwitch:Refresh()
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
