# Hamingway's HunterTools

![Hamingway's HunterTools](images/hero.png)

**The hunter's Swiss army knife.** Swing timer, warnings, ammo, pets, macros and map in one addon for WoW Forever. 25 modules, 18 ready-made macros, English and German. Every module can be switched off, shown only in combat or with a target, and adjusted. No screen clutter. Type `/hht` to open the settings.

**Version 1.2.0:** aspect and tracking buttons, pet warnings with a click (feed, Mend Pet, Revive Pet), smarter feeding, Aspect of the Pack warning, ammo, quiver and ammo pouch upgrades, and a What's New window. Download on [CurseForge](https://www.curseforge.com/wow/addons/hamingways-hunter-tools).

A richer overview with all pictures is in [Overview.html](Overview.html). The screenshots use sample data from the test mode (`/hht shot`, `/hht test`), such as test beasts and frozen values.

**Contents:** [English](#english) | [Deutsch](#deutsch) | [Install](#install) | [Credits](#credits)

## English

### Modules at a glance

| Group | Modules |
| --- | --- |
| Combat | Swing timer, Distance, Cast bar, Threat, Warnings, Aspect and tracking, Cooldowns, Target debuffs, Proc overlay, Summons |
| Gear and tools | Ammo, Pet feeder, Macros, Tranq rotation |
| Pets | Pet status, Pet database, Beast watch, Pet ability alerts, Pet training hint, Pet guide |
| Map | Stable masters, Ammo vendors, Food vendors, Trainers, Map button |

### Combat

![Swing timer and distance](images/swing_distance.gif)

**Swing timer**
- Auto Shot and main hand bars with label and remaining time
- Range state text: Melee, Ranged, Dead zone, Too far, each with its own colour
- Ranged bar turns red in the dead zone
- Fill or drain mode, spark, border, background opacity
- Width, height, spacing and every colour adjustable

**Distance**
- Target distance in bands: melee, dead zone, near, middle, far, max range, out of range
- Three layouts: segments, badge or text only
- Pulse and sound when entering the dead zone
- Square or round icon, size, a colour for every band

![Cast bar and threat](images/cast_threat.gif)

**Cast bar**
- Spell icon, name, remaining time and spark
- Tells casts and channels apart
- Can hide the default cast bar
- Width, height, border and background adjustable

**Threat**
- Threat bar with label and percent
- Warns at a percentage you choose, before you pull aggro
- Alert when you gain aggro, sound and blink at high threat
- Only in a group or with pet; hide when there is no threat

![Warnings and cooldowns](images/warnings.png)

**Warnings**
- No aspect active, or not your preferred aspect
- Trueshot Aura missing
- Hunter's Mark missing: elites and bosses only, or every enemy
- Pet missing or dead, with the matching spell as icon; click to revive, the key shows on the icon
- Pet hurt (threshold adjustable): click casts Mend Pet; own warning when out of Mend Pet range
- Pet hungry: click feeds. Food low: tooltip with the count, right-click hides it, it returns when food drops below the limit again
- Growl on autocast: click switches it off. Aspect of the Pack in a dungeon or raid: click switches to your preferred aspect
- Show the active aspect, blink, sound, hide in combat

**Aspect and tracking**
- One button and one key each for aspect and tracking
- Toggles between two spells you choose
- Shift, Ctrl and Alt pick other variants, for both the click and the key
- Right-click opens a list of every aspect or tracking type you know
- Tracking also covers Find Herbs, Find Minerals, Find Fish and Find Treasure; a small X turns it off

**Cooldowns**
- Default: Rapid Fire, Bestial Wrath, Intimidation, Scatter Shot, traps, Feign Death, Deterrence and more; the list is freely editable
- All, only on cooldown or only ready; numbers, grey-out, spell names
- Action bar key shown on the icon
- Grow direction, icons per row, border and icon size

![Target debuffs](images/debuffs.png)

**Target debuffs**
- Serpent Sting and your other debuffs on the target with icon, timer and stacks, also in combat
- Tracked debuffs get a fixed slot and a red placeholder while they are missing
- Placeholder on all targets, elites and bosses, or bosses only; optionally blinking
- Only your debuffs or all, count, size and border adjustable

![Proc overlay](images/procs.gif)

**Proc overlay**
- Big art around your character while a proc or buff is active, also in combat
- Over 150 graphics to choose from in a paged gallery
- Remaining time as a fade: from the top, bottom, left or right
- Per proc: graphic, scale, offset X and Y, preview
- Quick Shots is pre-set; add any buff by spell ID, up to 6
- Sound when it appears; read the ID with `/hht auras`
- Scan for new procs: short buffs you gain out of combat are added to the list switched off; switch on the ones you want
- Each proc has its own On/Off switch

![Summons](images/summons.png)

**Summons**
- Active summons such as Summon Hawk with icon and remaining time, also in combat
- The default UI shows them under the player frame; they are not buffs, so this module lists them
- Icons close up without gaps and keep their order of arrival
- Shape, size, border, spacing, names, grow direction, visibility; `/hht totems` shows the slots

![Ammo and pet feeder](images/ammo_feeder.png)

**Ammo**
- Counts bags, quiver and the ammo slot, arrows and bullets separately
- Show the ammo your weapon needs, or all of it
- Low warning below a limit: red, blink, sound
- Reminder when entering a dungeon and on ready check
- Click: choose and equip other ammo; list of all ammunition
- Green arrow when better ammo for your level is in your bags; click to see and equip the upgrades
- Also suggests better quivers (arrows) and ammo pouches (bullets) that match your equipped ammo, with the source: crafted, quest, drop or PvP reputation
- Engineer-crafted ammo can be switched on
- Show ammo vendors on the map, waypoint to the nearest

**Pet feeder**
- Click feeds, right-click picks the food, Shift-click blacklists; also works with its own key
- Warns when the pet gets unhappy (optional sound) and when food runs low
- Buff food is never picked automatically
- Food choice and blacklist per pet
- Always show, or only when the pet is not happy
- Keeps the HHT Feed macro up to date

### Pets

![Pet status](images/petstatus.png)

**Pet status**
- Portrait with level, health bar with name
- Focus, experience and training points, loyalty
- Happiness indicator: happy, content, unhappy
- Pet abilities with cooldown and auto-cast ring
- Click the portrait to open the pet database
- Round or square, size and every bar adjustable
- Level on the portrait; experience, training points and loyalty switch on and off independently, loyalty can hide at max, bar spacing adjustable
- Frenzy indicator with adjustable icon size

![Pet database](images/petdex.png)

**Pet database**
- Six tabs: Beasts, Families, Abilities, My pet, Stable, Guide
- Guide tab: pick a goal (maximum damage, solo survival, balanced) and get the best families with the beast to tame, a first-pet section with the hunter trainer on the map and a waypoint, and the basics of training and feeding
- Families tab: diet, damage/health/armor modifier, family abilities and speed per pet family
- Family, level, attack speed, zone and taught abilities per beast
- Search by name, family, zone or ability, plus filters
- Marks: tamed (`+`), wishlist (`*`), seen
- Attack speed is measured when you tame; a `~` marks the Classic base value
- 3D model preview
- Show on the map and set a waypoint
- Export and import beast data to share it

![Beast watch and alerts](images/watch.png)

**Beast watch**
- Tooltip shows tameable info, family, level, speed and taught abilities
- Marks beasts as seen and, after taming, as tamed
- Popup for rare and wishlist beasts; also close to known spawns
- Buttons: target, map, arrow, wishlist, pause
- Direction arrow to the rare beast, adjustable size
- The popup shows family, level and zone, the family role with health, armor and damage modifiers, attack speed, diet, the abilities the beast teaches (ranks you can still learn in green) and the family abilities
- Optional 3D model of the beast in the popup
- Only beasts up to your level, sound, inside dungeons, repeat delay

**Pet ability alerts**
- Popup when a nearby beast teaches a higher rank your pet can learn
- For the active pet only, or every pet you have used
- On entering a zone: a list of all beasts there that give a pet of yours an upgrade; click shows the beast on the map, right-click sets the arrow, Shift-click a waypoint, one button shows all on the map

![Pet training hint](images/pettrain.png)

**Pet training hint**
- Popup when your pet can learn ability ranks you already know
- A Learn button per ability trains the rank right away
- Abilities can be ignored; display time, sound, test hint and border colour adjustable

![Pet guide](images/guide.png)

**Pet guide**
- One-time popup when a character reaches level 10, with buttons for the trainer on the map, a waypoint and the Guide tab
- Test with `/hht test guide`, open the tab with `/hht guide`

### Map

![World map](images/map.png)

![Minimap](images/minimap.png)

**Map button, Ammo vendors, Stable masters, Food vendors, Trainers**
- Map button at the top left with switches for the layers
- Ammo vendor layer, by ammo kind and own faction only
- Stable master layer from a built-in list; missing ones are learned when you visit them
- Food vendor layer for your current pet's diet; missing vendors are learned when you open their merchant window
- Trainer layer with hunter trainers and pet trainers together in one category (`/hht trainer`, `/hht trainer go`)
- Waypoint to the nearest vendor, stable master, food vendor or trainer (`/hht food`, `/hht food go`)
- Active layers, beasts from the pet database and the rare the arrow points to also show on the minimap (on by default, one switch per layer)
- Show beasts from the pet database on the map
- Every layer can be switched off on its own

### Tools

![Macros](images/macros.png)

**Macros** - 18 ready-made macros, drag them onto your bar.
- 5 pet macros: one-button (revive, call or mend), call or dismiss, mend, revive, feed
- 13 hunter macros: attack, mark, aspect, trap, melee, feign, kite, growl, tame, track, burst, ammo, stable
- Shift and Ctrl pick variants, for example other aspects or traps

**Tranq rotation** - lists the hunters of your group with their Tranquilizing Shot cooldown. The raid leader or an assistant sets the order and a backup list and sends it to everyone who runs the addon; the raid chat shows who changed it. After a shot the hunter moves to the end, a missed shot marks him red until his cooldown is over, and the next free hunter is always on top. When it is your turn a "you are next to tranq" notice appears. Hunters without the addon are tracked by their visible casts. Optionally only hunters who know the spell are listed. Includes a test mode with fake hunters, plus an announcer that tells a chat channel of your choice about your own shot (own text, test button). `/hht tranq` shows or hides the window.

### Customise and learn

Enter it yourself:
- Procs: add any buff by spell ID, even several IDs for one entry; read the ID with `/hht auras` while the proc is active
- Target debuffs: add your own debuffs by spell ID, several ranks separated by commas
- Cooldowns: add spells from your spellbook, unknown spells stay hidden, the default list can be restored
- Aspect and tracking keys: your own spells per key, plus Shift, Ctrl and Alt variants
- Feed key: Shift-click blacklists or allows a food per pet

Learned automatically:
- Procs: "Scan for new procs" adds short buffs you gain out of combat to the list switched off, then you switch them on
- Stable masters and food vendors: missing ones are learned when you open their window; the built-in list stays the base
- Pet database: known ranks are read from Beast Training and the pet spellbook, "Scan now" starts it by hand; seen and tamed beasts are counted
- Everything learned can be forgotten again per module

### Settings

![Settings](images/settings.png)

- Every module has its own switch and its own page
- Own scale and opacity per module, plus global values for all
- Show always, in combat, with a target, or both
- All bar colours adjustable
- Icons per row for cooldowns, target debuffs, warnings and summons, so icons can wrap into several rows
- Colour themes (Bronze, Blue, Graphite), look of icons and bars (Flat, 3D frame, Glass), soft fade-in of windows and popups, optional animations
- Collapsible sections, icons in the module list, text style per module (outline, thick, plain)
- Live preview: opening a module's page shows that module with demo data, so changes are visible at once (can be switched off)
- The settings window remembers its position and reopens after a reload
- Glass bar texture and smooth bar movement, flash when a cooldown is ready or a warning appears
- Flash glow strength and size, position of label and time per bar, ammo count and key binding position adjustable
- Unlock a single module right on its page; frames snap to each other while you move them (Shift = off)
- Unlock frames, move them with the mouse, lock again
- Reset positions or single modules
- Language: automatic, English or German
- Export and import all settings as one line of text
- Minimap button
- The module list on the left scrolls with the mouse wheel

## Deutsch

### Module im Überblick

| Gruppe | Module |
| --- | --- |
| Kampf | Schlag-Timer, Distanz, Zauberleiste, Bedrohung, Warnungen, Aspekt und Aufspüren, Abklingzeiten, Ziel-Debuffs, Proc-Anzeige, Beschwörungen |
| Ausrüstung und Werkzeuge | Munition, Tier füttern, Makros, Tranq-Rotation |
| Tiere | Tierstatus, Tierdatenbank, Tierbeobachtung, Fähigkeits-Hinweise, Begleiter-Training-Hinweis, Tierratgeber |
| Karte | Stallmeister, Munitionshändler, Futterhändler, Lehrer, Kartenknopf |

### Kampf

**Schlag-Timer**
- Balken für Automatischen Schuss und Waffenhand, mit Bezeichnung und Restzeit
- Reichweitentext: Nahkampf, Fernkampf, Tote Zone, Zu weit, jeweils mit eigener Farbe
- Fernkampfbalken wird in der toten Zone rot
- Füllen oder Leeren, Funke, Rand, Hintergrundtransparenz
- Breite, Höhe, Abstand und jede Farbe einstellbar

**Distanz**
- Zieldistanz in Stufen: Nahkampf, tote Zone, nah, mittel, fern, maximale Reichweite, außer Reichweite
- Drei Darstellungen: Segmente, Symbol-Abzeichen oder nur Text
- Pulsieren und Ton beim Betreten der toten Zone
- Quadratisches oder rundes Symbol, Größe, Farben je Stufe

**Zauberleiste**
- Symbol, Zaubername, Restzeit und Funke
- Unterscheidet Zauber und Kanalisierung
- Blizzards Standard-Zauberleiste lässt sich ausblenden
- Breite, Höhe, Rand und Hintergrund einstellbar

**Bedrohung**
- Bedrohungsbalken mit Beschriftung und Prozentwert
- Warnt ab einem Prozentwert deiner Wahl, bevor du Aggro ziehst
- Meldung beim Aggro-Gewinn, Ton und Blinken bei hoher Bedrohung
- Nur in Gruppe oder mit Tier; ausblendbar ohne Bedrohung

**Warnungen**
- Kein Aspekt aktiv oder nicht der bevorzugte Aspekt
- Aura des Volltreffers fehlt
- Mal des Jägers fehlt: nur bei Elite und Bossen oder bei jedem Gegner
- Tier fehlt oder ist tot, mit dem passenden Zauber als Symbol; Klick belebt wieder, die Taste steht auf dem Symbol
- Tier verletzt (Schwelle einstellbar): Klick wirkt Tier heilen; außerhalb der Heilreichweite eigene Warnung
- Tier hungrig: Klick füttert. Futter knapp: Tooltip mit Anzahl, Rechtsklick blendet aus, kommt wieder, wenn das Futter erneut unter die Schwelle fällt
- Knurren auf Autocast: Klick schaltet es aus. Aspekt des Rudels im Dungeon oder Schlachtzug: Klick wechselt zum bevorzugten Aspekt
- Aktiven Aspekt anzeigen, Blinken, Ton, im Kampf ausblendbar

**Aspekt und Aufspüren**
- Je ein Knopf und eine Taste für Aspekt und Aufspüren
- Wechselt zwischen zwei Zaubern, die du festlegst
- Shift, Strg und Alt wählen andere Varianten, sowohl beim Klick als auch bei der Taste
- Rechtsklick öffnet eine Liste aller Aspekte oder Aufspüren-Arten, die du kennst
- Aufspüren kennt auch Kräuter, Erz, Fische und Schätze finden; ein kleines X schaltet es aus

**Abklingzeiten**
- Vorgabe: Schnellfeuer, Zorn des Wilden, Einschüchterung, Streuschuss, Fallen, Totstellen, Abschreckung und mehr; Liste frei änderbar
- Alle, nur auf Abklingzeit oder nur bereit; Zahlen, Ausgrauen, Namen
- Tastenbelegung deiner Leisten auf dem Symbol
- Richtung, Symbole pro Zeile, Rand- und Symbolgröße

**Ziel-Debuffs**
- Schlangenbiss und deine anderen Debuffs auf dem Ziel mit Symbol, Zeit und Stapeln, auch im Kampf
- Überwachte Debuffs bekommen einen festen Platz und einen roten Platzhalter, solange sie fehlen
- Platzhalter bei allen Zielen, bei Elite und Bossen oder nur bei Bossen; wahlweise blinkend
- Nur deine Debuffs oder alle, Anzahl, Größe und Rand einstellbar

**Proc-Anzeige**
- Große Grafik um deinen Charakter, solange ein Proc oder Buff aktiv ist, auch im Kampf
- Über 150 Grafiken zur Auswahl in einer geblätterten Galerie
- Restzeit als Verblassen: von oben, unten, links oder rechts
- Je Proc: Grafik, Skalierung, Versatz X und Y, Vorschau
- Quick Shots ist voreingestellt; jeder Buff lässt sich per Zauber-ID ergänzen, bis zu 6
- Ton beim Erscheinen; die ID liest du mit `/hht auras` aus
- Nach neuen Procs suchen: kurze Buffs, die du außerhalb des Kampfes bekommst, kommen ausgeschaltet in die Liste; schalte die gewünschten ein
- Jeder Proc hat einen eigenen An/Aus-Schalter

**Beschwörungen**
- Aktive Beschwörungen wie Habicht beschwören mit Symbol und Restzeit, auch im Kampf
- Das Standard-UI zeigt sie unter dem Spielerrahmen; sie sind keine Buffs, deshalb listet sie dieses Modul
- Die Symbole rücken lückenlos zusammen und behalten ihre Reihenfolge
- Form, Größe, Rand, Abstand, Namen, Wachstumsrichtung, Sichtbarkeit; `/hht totems` zeigt die Slots

**Munition**
- Zählt Taschen, Köcher und Munitionsplatz, Pfeile und Kugeln getrennt
- Anzeige für die benötigte Munition oder für alle
- Warnung unter einer Grenze: rot, Blinken, Ton
- Erinnerung beim Betreten eines Dungeons und beim Bereitschaftscheck
- Klick: andere Munition wählen und anlegen; Liste aller Munition
- Grüner Pfeil, wenn bessere Munition für deine Stufe in den Taschen liegt; Klick zeigt die Aufwertungen und legt sie an
- Schlägt auch bessere Köcher (Pfeile) und Munitionsbeutel (Kugeln) vor, passend zur angelegten Munition, mit Quelle: Handwerk, Quest, Drop oder PvP-Ruf
- Von Ingenieuren hergestellte Munition lässt sich zuschalten
- Munitionshändler auf der Karte zeigen, Wegpunkt zum nächsten

**Tier füttern**
- Klick füttert, Rechtsklick wählt das Futter, Umschalt-Klick sperrt; auch per eigener Taste
- Warnt, wenn das Tier unzufrieden wird (Ton optional) und wenn das Futter knapp wird
- Buff-Futter wird nicht automatisch gewählt
- Futterwahl und Sperrliste pro Tier
- Immer anzeigen oder nur wenn das Tier nicht zufrieden ist
- Hält das Makro HHT Feed aktuell

### Tiere

**Tierstatus**
- Porträt mit Stufe, Lebensbalken mit Name
- Fokus, Erfahrung und Trainingspunkte, Loyalität
- Zufriedenheitsanzeige: zufrieden, neutral, unzufrieden
- Tierfähigkeiten mit Abklingzeit und Automatik-Ring
- Ein Klick auf das Porträt öffnet die Tierdatenbank
- Rund oder eckig, Größe und jede Leiste einstellbar
- Stufe am Porträt; Erfahrung, Trainingspunkte und Loyalität einzeln schaltbar, Loyalität bei Maximum ausblendbar, Balkenabstand einstellbar
- Raserei-Anzeige mit einstellbarer Symbolgröße

**Tierdatenbank**
- Sechs Reiter: Tiere, Familien, Fähigkeiten, Mein Begleiter, Stall, Ratgeber
- Ratgeber-Reiter: Ziel wählen (maximaler Schaden, Solo-Überleben, ausgewogen) und die besten Familien mit dem passenden Tier bekommen, dazu ein Bereich für das erste Tier mit Jäger-Lehrer auf der Karte und Wegpunkt sowie die Grundlagen zu Training und Füttern
- Familien-Reiter: Nahrung, Schaden-, Lebens- und Rüstungsmodifikator, Familienfähigkeiten und Tempo je Tierfamilie
- Familie, Stufe, Angriffstempo, Zone und gelehrte Fähigkeiten je Tier
- Suche nach Name, Familie, Zone oder Fähigkeit, dazu Filter
- Markierungen: gezähmt (`+`), Wunschliste (`*`), gesehen
- Angriffstempo wird beim Zähmen gemessen; ein `~` bedeutet Classic-Basiswert
- 3D-Modell-Vorschau
- Auf der Karte zeigen und Wegpunkt setzen
- Tierdaten exportieren und importieren, um sie zu teilen

**Tierbeobachtung**
- Tooltip zeigt Zähmbarkeit, Familie, Stufe, Tempo und gelehrte Fähigkeiten
- Markiert Tiere als gesehen und, nach dem Zähmen, als gezähmt
- Popup bei seltenen Tieren und Wunschlisten-Tieren; auch in der Nähe bekannter Spawns
- Knöpfe: anvisieren, Karte, Pfeil, Wunschliste, Pause
- Richtungspfeil zum seltenen Tier, Größe einstellbar
- Das Popup zeigt Familie, Stufe und Zone, die Familienrolle mit Leben-, Rüstungs- und Schadensmodifikator, Angriffstempo, Nahrung, die gelehrten Fähigkeiten (lernbare neue Ränge grün) und die Familienfähigkeiten
- Optional: 3D-Modell des Tiers im Popup
- Nur Tiere bis zu deiner Stufe, Ton, auch in Dungeons, Wiederholungs-Pause

**Fähigkeits-Hinweise**
- Popup, wenn ein Tier in der Nähe einen höheren Rang lehrt, den dein Tier lernen kann
- Nur für das aktive Tier oder für jedes Tier, das du benutzt hast
- Beim Betreten einer Zone: Liste aller Tiere dort, die einem deiner Tiere ein Upgrade geben; Klick zeigt das Tier auf der Karte, Rechtsklick setzt den Pfeil, Shift-Klick einen Wegpunkt, ein Knopf zeigt alle auf der Karte

**Begleiter-Training-Hinweis**
- Popup, wenn dein Tier Fähigkeitsränge lernen kann, die du schon kennst
- Ein Lernen-Knopf je Fähigkeit trainiert den Rang direkt
- Fähigkeiten lassen sich ignorieren; Anzeigedauer, Ton, Testhinweis und Rahmenfarbe einstellbar

**Tierratgeber**
- Einmaliges Popup, wenn ein Charakter Stufe 10 erreicht, mit Knöpfen für den Lehrer auf der Karte, einen Wegpunkt und den Ratgeber-Reiter
- Testen mit `/hht test guide`, Reiter öffnen mit `/hht guide`

### Karte

**Kartenknopf, Munitionshändler, Stallmeister, Futterhändler, Lehrer**
- Kartenknopf oben links mit Schaltern für die Ebenen
- Ebene Munitionshändler, wahlweise nach Munitionsart und nur eigene Fraktion
- Ebene Stallmeister aus einer eingebauten Liste; fehlende werden beim Besuch gelernt
- Ebene Futterhändler: nur Händler, die Futter für die Nahrung deines aktuellen Tiers verkaufen; fehlende werden beim Öffnen des Händlerfensters gelernt
- Ebene Lehrer: Jägerlehrer und Tierausbilder zusammen in einer Kategorie
- Wegpunkt zum nächsten Händler, Stallmeister, Futterhändler oder Lehrer (`/hht food`, `/hht food go`, `/hht trainer`, `/hht trainer go`)
- Aktive Ebenen, Tiere aus der Tierdatenbank und das Seltene, auf das der Pfeil zeigt, erscheinen auch auf der Minimap (standardmäßig an, ein Schalter pro Ebene)
- Tiere aus der Tierdatenbank auf der Karte zeigen
- Jede Ebene einzeln abschaltbar

### Werkzeuge

**Makros** - 18 fertige Makros, einfach auf die Leiste ziehen.
- 5 Tier-Makros: Ein-Tasten-Makro (wiederbeleben, rufen oder heilen), Rufen/Wegschicken, Heilen, Wiederbeleben, Füttern
- 13 Jäger-Makros: Angriff, Mal, Aspekt, Falle, Nahkampf, Totstellen, Kiten, Knurren, Zähmen, Spurensuche, Burst, Munition, Stall
- Umschalt und Strg wählen Varianten, zum Beispiel andere Aspekte oder Fallen

**Tranq-Rotation** - listet die Jäger deiner Gruppe mit ihrer Abklingzeit des Einlullenden Schusses. Schlachtzugsleiter oder Assistenten legen Reihenfolge und Backup fest und senden sie an alle mit dem Addon; der Raid-Chat zeigt, wer sie geändert hat. Nach einem Schuss rückt der Jäger ans Ende, ein Fehlschuss markiert ihn rot bis zum Ende der Abklingzeit, und der nächste freie Jäger steht immer oben. Bist du dran, erscheint der Hinweis "Du bist mit Tranq dran". Jäger ohne Addon werden über ihre sichtbaren Zauber erkannt. Auf Wunsch werden nur Jäger gelistet, die den Zauber kennen. Mit Testmodus (falsche Jäger) und einem Ansager, der deinen eigenen Schuss in einen Chatkanal deiner Wahl meldet (eigener Text, Testknopf). `/hht tranq` blendet das Fenster ein oder aus.

### Anpassen und Lernen

Selbst eintragen:
- Procs: beliebige Buffs per Zauber-ID hinzufügen, auch mehrere IDs für einen Eintrag; die ID liest du mit `/hht auras` aus, solange der Proc aktiv ist
- Ziel-Debuffs: eigene Debuffs per Zauber-ID ergänzen, mehrere Ränge durch Komma getrennt
- Abklingzeiten: Zauber aus deinem Zauberbuch hinzufügen, unbekannte Zauber bleiben ausgeblendet, die Standardliste lässt sich wiederherstellen
- Aspekt- und Aufspüren-Tasten: eigene Zauber je Taste, dazu Umschalt-, Strg- und Alt-Varianten
- Futter-Taste: Umschalt-Klick sperrt oder erlaubt ein Futter pro Tier

Automatisch gelernt:
- Procs: "Nach neuen Procs suchen" nimmt kurze Buffs, die du außerhalb des Kampfes bekommst, ausgeschaltet in die Liste auf, du schaltest sie dann ein
- Stallmeister und Futterhändler: fehlende werden gelernt, sobald du ihr Fenster öffnest; die eingebaute Liste bleibt die Basis
- Tierdatenbank: bekannte Ränge werden aus der Tierausbildung und dem Begleiter-Zauberbuch gelesen, "Jetzt einlesen" startet es von Hand; gesehene und gezähmte Tiere werden mitgezählt
- Alles Gelernte lässt sich je Modul wieder vergessen

### Einstellungen

- Jedes Modul hat einen eigenen Schalter und eine eigene Seite
- Eigene Größe und Transparenz je Modul, dazu global für alle
- Anzeige immer, im Kampf, mit Ziel oder beides
- Alle Farben der Balken wählbar
- Symbole pro Reihe für Abklingzeiten, Ziel-Debuffs, Warnungen und Beschwörungen, damit Symbole in mehrere Reihen umbrechen
- Rahmen entsperren, mit der Maus verschieben, wieder sperren
- Einzelne Module direkt auf ihrer Seite entsperren; Rahmen rasten beim Verschieben aneinander ein (Shift = aus)
- Stärke und Größe des Aufblitzens sowie Position von Beschriftung, Restzeit, Munitionsanzahl und Tastenbelegung einstellbar
- Position oder einzelne Module zurücksetzen
- Sprache: automatisch, Englisch oder Deutsch
- Einstellungen als eine Textzeile exportieren und importieren
- Minimap-Knopf
- Die Modulliste links lässt sich mit dem Mausrad scrollen

## Install

1. Copy the `HamingwaysHunterTools` folder to `Interface\AddOns`.
2. Type `/reload` or start the game.
3. Type `/hht` to open the settings.

| Command | Effect |
| --- | --- |
| `/hht` | Open the settings |
| `/hht unlock` / `/hht lock` | Unlock or lock the frames |
| `/hht reset` | Reset the positions |
| `/hht petinfo` | Print the active pet's abilities |
| `/hht pets` / `/hht pets name` | Open the pet database or search it |
| `/hht guide` | Open the pet guide |
| `/hht ammo` / `/hht ammo go` | Show ammo vendors on the map or set a waypoint to the nearest |
| `/hht stable` / `/hht stable go` | Show stable masters on the map or set a waypoint to the nearest |
| `/hht food` / `/hht food go` | Show food vendors for your pet on the map or set a waypoint to the nearest |
| `/hht trainer` / `/hht trainer go` | Show hunter and pet trainers on the map or set a waypoint to the nearest |
| `/hht news` | Show what's new in recent updates |
| `/hht auras` | Print the IDs of your active buffs, for the proc overlay |
| `/hht test` / `/hht test zone` | Show demo output, or the beast list of the current zone for 30 seconds |
| `/hht shot` | Screenshot scenes with sample data (`/hht shot off` ends them) |

## Credits

Like the addon? Buy me a coffee: https://buymeacoffee.com/x1ndlmeister

Gefällt dir das Addon? Spendier mir einen Kaffee: https://buymeacoffee.com/x1ndlmeister

Licensed under GPL-3.0-or-later (see `LICENSE`). Pet and ammo vendor data from Huntmaster (MIT), beast lists extended from OneForAll (GPL-3) with spawns from Questie. Stable master, food vendor and trainer positions are partly from Questie, pet family stats from wow-petopia.com (via OneForAll). See `Data\NOTICE.txt`.
