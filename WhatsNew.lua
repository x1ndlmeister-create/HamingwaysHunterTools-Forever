-- What's new window: after an update it lists the changes since the last seen version.
-- /hht news opens it any time with the full history below.
local ADDON, HHT = ...
local UI = HHT.UI

HHT:AddGerman({
    ["What's new"] = "Was ist neu",
    ["Version %s"] = "Version %s",
    ["Show this window after updates"] = "Dieses Fenster nach Updates zeigen",
    ["Close"] = "Schließen",
    ["No notes for this version."] = "Keine Hinweise zu dieser Version.",
    ["Show what's new after an update"] = "Nach einem Update zeigen, was neu ist",
})

-- Release notes, newest first. Keys: v = version, en / de = one line per change.
local NOTES = {
    {
        v = "1.5.3",
        en = {
            "Restock ammo now also works with BetterBags' vendor window: the button sits at the bottom left of its Buy tab.",
            "Restock ammo: with only one vendor button (e.g. only Sell Junk) the row is now laid out so the new button no longer sits against the buyback slot.",
            "Restock ammo: the button now hides when you switch to the Buyback tab.",
        },
        de = {
            "Munition auffüllen funktioniert jetzt auch mit dem Händlerfenster von BetterBags: Der Knopf sitzt unten links im Kaufen-Tab.",
            "Munition auffüllen: Hat der Händler nur einen eigenen Knopf (z. B. nur 'Müll verkaufen'), wird die Reihe jetzt so angeordnet, dass der neue Knopf nicht mehr am Rückkauf-Slot klebt.",
            "Munition auffüllen: Der Knopf verschwindet jetzt, wenn du auf den Rückkauf-Tab wechselst.",
        },
    },
    {
        v = "1.5.2",
        en = {
            "Ammo vendors: a new Restock ammo icon appears in the vendor window's button row. One click fills your quiver or ammo pouch with the ammo your weapon uses (the equipped kind, otherwise the best the vendor sells). The tooltip shows amount and price, and a prompt asks before buying. Position, spacing and the shifting of the vendor's own buttons can be set under Ammo vendors > Vendor window (Advanced).",
            "Low ammo or low pet food: the matching vendors are now shown on the map automatically while the warning is active, and hidden again when it is fixed. If they were already on, they stay on.",
            "Threat: the old checkbox is now a choice, 'Show bar': always, in a group or with a pet, or only in a group (the pet does not count).",
            "Target debuffs: the border colour is replaced by two colours, 'Active border' (green by default) and 'Missing debuff'. The border glow now works on the debuff icons too.",
            "Target debuffs: the missing icon no longer flashes briefly when you change target or click through the settings.",
            "Proc icons now sit behind the other modules.",
            "Cast bar: the game's 'Opening - No Text' (quest items, chests) now reads 'Looting'.",
        },
        de = {
            "Munitionshändler: Im Händlerfenster gibt es in der Knopfreihe ein neues Symbol 'Munition auffüllen'. Ein Klick füllt Köcher oder Munitionsbeutel mit der Munition, die deine Waffe nutzt (die angelegte Sorte, sonst die beste des Händlers). Der Tooltip zeigt Menge und Preis, und vor dem Kauf fragt ein Fenster nach. Position, Abstand und das Verschieben der Händlerknöpfe stellst du unter Ammo vendors > Händlerfenster ein (Erweitert).",
            "Wenig Munition oder wenig Tierfutter: Die passenden Händler erscheinen jetzt automatisch auf der Karte, solange die Warnung aktiv ist, und verschwinden wieder, sobald sie behoben ist. Waren sie schon eingeschaltet, bleiben sie an.",
            "Bedrohung: Aus der alten Checkbox wurde eine Auswahl 'Anzeige': immer, in Gruppe oder mit Pet, oder nur in Gruppe (das Pet zählt nicht).",
            "Ziel-Debuffs: Die Rahmenfarbe wurde durch zwei Farben ersetzt, 'Aktiver Rahmen' (standardmäßig grün) und 'Debuff fehlt'. Das Rahmen-Glühen funktioniert jetzt auch bei den Debuff-Symbolen.",
            "Ziel-Debuffs: Das Symbol für einen fehlenden Debuff blitzt nicht mehr kurz auf, wenn du das Ziel wechselst oder durch die Einstellungen klickst.",
            "Die Proc-Symbole liegen jetzt hinter den anderen Modulen.",
            "Zauberleiste: Das Spiel-interne 'Opening - No Text' (Questgegenstände, Truhen) heißt jetzt 'Looten'.",
        },
    },
    {
        v = "1.5.1",
        en = {
            "Pet feeder: buff food (for example Tasty Lion Steak) is now reliably recognised and left alone by the automatic pick, even when its tooltip was not fully loaded the first time.",
            "Pet feeder: the low food warning is now also tracked while the settings page is open, so the count turns red as soon as it is below your limit. The Warnings preview shows the 'Low pet food' icon.",
        },
        de = {
            "Begleiter füttern: Buff-Futter (zum Beispiel Tasty Lion Steak) wird jetzt zuverlässig erkannt und von der automatischen Wahl in Ruhe gelassen, auch wenn der Tooltip beim ersten Mal noch nicht ganz geladen war.",
            "Begleiter füttern: Die Warnung bei wenig Futter wird jetzt auch bei geöffneter Einstellungsseite erfasst, die Zahl wird also rot, sobald sie unter deinem Grenzwert liegt. Die Vorschau der Warnungen zeigt das Symbol 'Wenig Futter'.",
        },
    },
    {
        v = "1.5.0",
        en = {
            "Quick install (the in-game installer) now shows the same rows as the settings, so what you set there is what you get later. Modules on one page are separated by a coloured header, and the window can be made taller or shorter by dragging its bottom edge. /hht setup starts it any time.",
            "Settings: every module page was rebuilt. Rows are grouped, and each section has a Simple and an Advanced view, so you only see what you need.",
            "One look for everything: icon shape (round or square), border thickness and colour, border glow and its strength, bar texture and rounded bars are set once, in the general settings or in the quick install, with an animated preview. Every module page can still change its own.",
            "Border glow: a soft glow in the border colour around icons and bars. Rounded bars get a matching pill-shaped glow, and the cast bar flash glows with it. Menu icons, list icons and the icons of the pet popups stay plain.",
            "Cast bar: choose the icon shape, and the space between icon and bar (Advanced).",
            "Show when and Opacity sit in the same place on every module page.",
            "Pet popups: new header with the pet icon, and the pet training hint shows the Beast Training icon.",
            "Map layers always show only your own faction, the 'Only my faction' switch is gone.",
            "Scaling no longer pushes frames out of place, and borders stay sharp at every UI scale.",
            "Fixed: the border glow now appears on the cooldowns, aspect and tracking keys and summons as soon as you switch it on. The macro page of the quick install is tidy again.",
        },
        de = {
            "Die Schnell-Einrichtung (der Ingame-Installer) zeigt jetzt dieselben Zeilen wie die Einstellungen, was du dort einstellst, bekommst du später genauso. Module auf einer Seite sind durch eine farbige Kopfzeile getrennt, und die Fensterhöhe lässt sich am unteren Rand ziehen. /hht setup startet sie jederzeit.",
            "Einstellungen: Jede Modulseite wurde neu aufgebaut. Die Zeilen sind gruppiert, und jeder Abschnitt hat eine Einfach- und eine Erweitert-Ansicht, damit du nur siehst, was du brauchst.",
            "Ein Look für alles: Symbolform (rund oder eckig), Rahmenstärke und -farbe, Rahmen-Glühen mit Stärke, Leistentextur und abgerundete Leisten stellst du einmal ein, in den allgemeinen Einstellungen oder in der Schnell-Einrichtung, mit animierter Vorschau. Jede Modulseite kann es weiterhin einzeln ändern.",
            "Rahmen-Glühen: ein weicher Schein in der Rahmenfarbe um Symbole und Leisten. Abgerundete Leisten bekommen einen passenden pillenförmigen Schein, und beim Aufblitzen der Zauberleiste glüht er mit. Menü-Symbole, Listen-Symbole und die Symbole der Tier-Popups bleiben schlicht.",
            "Zauberleiste: Du kannst die Symbolform und den Abstand zwischen Symbol und Leiste wählen (Erweitert).",
            "Anzeigen wenn und Deckkraft stehen auf jeder Modulseite am selben Platz.",
            "Tier-Popups: neue Kopfzeile mit dem Tier-Symbol, und der Tierausbildungs-Hinweis zeigt das Symbol der Tierausbildung.",
            "Kartenebenen zeigen immer nur deine eigene Fraktion, der Schalter 'Nur meine Fraktion' entfällt.",
            "Beim Skalieren rutschen Fenster nicht mehr weg, und Rahmen bleiben bei jeder UI-Skalierung scharf.",
            "Behoben: Das Rahmen-Glühen erscheint jetzt auch bei den Abklingzeiten, den Aspekt- und Aufspür-Tasten und den Beschwörungen, sobald du es einschaltest. Die Makro-Seite der Schnell-Einrichtung ist wieder ordentlich.",
        },
    },
    {
        v = "1.4.3",
        en = {
            "Rare pet arrow: click it to target the beast. A macro 'HHT Beast' is created and updated for you (it is not placed on any bar), and the chat tells you when it was updated. Clicking a spawn point on the world map now also sets the arrow.",
            "Pet bar: right-click the portrait or the health bar for the pet menu (Rename, Dismiss, Release) when the default pet frame is hidden.",
            "Pet upgrades in this zone: abilities you can already train in Beast Training (for example Dash) are no longer listed.",
            "Beast alert: the 'Family learns' column is no longer cut off.",
            "Fixed 'Interface action failed because of an AddOn' errors from the arrow and from the food window after taming.",
        },
        de = {
            "Seltenen-Pfeil: Ein Klick darauf visiert das Tier an. Das Makro 'HHT Beast' wird automatisch angelegt und aktualisiert (es liegt auf keiner Leiste), und der Chat meldet, wann es aktualisiert wurde. Ein Klick auf einen Spawn-Punkt der Weltkarte setzt jetzt auch den Pfeil.",
            "Tierleiste: Rechtsklick auf Porträt oder Lebensbalken öffnet das Begleiter-Menü (Umbenennen, Wegschicken, Freilassen), wenn das Standard-Begleiterfenster ausgeblendet ist.",
            "Begleiter-Upgrades in dieser Zone: Fähigkeiten, die du in der Tierausbildung schon trainieren kannst (z. B. Spurt), werden nicht mehr aufgelistet.",
            "Tier-Hinweis: Die Spalte 'Familie lernt' ist nicht mehr abgeschnitten.",
            "Fehler 'Interface-Aktion wegen eines AddOns fehlgeschlagen' beim Pfeil und beim Futter-Fenster nach dem Zähmen behoben.",
        },
    },
    {
        v = "1.4.2",
        en = {
            "Cast bar: the default Blizzard cast bar is hidden by default while the HunterTools cast bar is active, including the red 'Interrupted' bar. It can be switched back in the cast bar settings and in the quick install.",
            "Pet bar: the default Blizzard pet frame can be hidden (on by default), or the pet bar can be attached to it. Attached, you keep the Blizzard portrait, health, focus and happiness, and the HunterTools rows (experience, loyalty, abilities) sit underneath, with the level and the upgrade arrow drawn over the portrait and Frenzy to its left. Both options are in the pet settings and the quick install.",
            "Proc overlay: each proc can be shown as an icon instead of the art, with timer, stack count, size and shape. Drag the icons where you want them while the frames are unlocked.",
            "Proc overlay: all proc graphics were rendered at a higher resolution with smoother edges, so they look sharper on 2K and 4K monitors.",
            "Frenzy proc: now sits above the others and fades from right to left by default.",
            "Unlock frames: a cog next to the switch lets you choose which modules can be moved (all by default).",
        },
        de = {
            "Zauberleiste: Die Standard-Zauberleiste von Blizzard ist standardmäßig ausgeblendet, solange die HunterTools-Zauberleiste aktiv ist, auch die rote 'Unterbrochen'-Leiste. In den Einstellungen der Zauberleiste und in der Schnell-Einrichtung lässt sich das wieder ändern.",
            "Tierleiste: Das Standard-Begleiterfenster von Blizzard lässt sich ausblenden (standardmäßig an), oder die Tierleiste wird daran angeheftet. Angeheftet bleiben Porträt, Leben, Fokus und Zufriedenheit von Blizzard, und die HunterTools-Zeilen (Erfahrung, Loyalität, Fähigkeiten) sitzen darunter, mit Level und Upgrade-Pfeil über dem Porträt und Raserei links davon. Beide Optionen gibt es in den Tier-Einstellungen und in der Schnell-Einrichtung.",
            "Proc-Anzeige: Jeder Proc lässt sich statt als Grafik auch als Symbol zeigen, mit Zeit, Stapelzahl, Größe und Form. Die Symbole kannst du bei entsperrten Fenstern an die gewünschte Stelle ziehen.",
            "Proc-Anzeige: Alle Proc-Grafiken wurden in höherer Auflösung und mit glatteren Kanten neu erzeugt und sehen auf 2K- und 4K-Monitoren schärfer aus.",
            "Raserei-Proc: sitzt jetzt standardmäßig über den anderen und verblasst von rechts nach links.",
            "Fenster entsperren: Ein Zahnrad neben dem Schalter lässt dich wählen, welche Module verschoben werden können (standardmäßig alle).",
        },
    },
    {
        v = "1.4.1",
        en = {
            "Fixed 'Interface action failed because of an AddOn' errors: the warnings, cooldowns and other icons with click buttons no longer resize, move or hide in combat (this is done right after the fight), and the pet map no longer loads the world map itself.",
            "Quick install: the pet page now lets you choose which bars are shown (happiness, focus, level, experience, loyalty, abilities), and the Tranq rotation stays off until you switch it on.",
            "/hht blocked lists blocked actions of this addon, /hht trace finds the line that caused one.",
        },
        de = {
            "'Interface-Aktion fehlgeschlagen wegen eines AddOns'-Fehler behoben: Warnungen, Abklingzeiten und andere Icons mit Klickfläche ändern im Kampf nicht mehr Größe oder Position und werden nicht mehr ausgeblendet (das passiert direkt nach dem Kampf). Die Tier-Karte lädt die Weltkarte nicht mehr selbst.",
            "Schnell-Einrichtung: Die Tier-Seite lässt dich wählen, welche Balken angezeigt werden (Zufriedenheit, Fokus, Level, Erfahrung, Loyalität, Fähigkeiten), und die Tranq-Rotation bleibt aus, bis du sie einschaltest.",
            "/hht blocked listet blockierte Aktionen dieses Addons, /hht trace findet die Zeile, die eine ausgelöst hat.",
        },
    },
    {
        v = "1.4.0",
        en = {
            "Quick install: Hamingway the Hambringer guides you through every tool, one page at a time (on or off, position, size, look). It opens for new characters and once for existing ones. /hht setup starts it again any time, and skipping it changes nothing.",
            "Profiles: save your settings under a name, load, rename, copy and delete them, and export or import them as text. Imported text becomes a profile called 'Imported profile #1', '#2' and so on. Profiles are shared by all your characters.",
            "The quick install offers to take over the settings of another character or a profile on its first page.",
            "Swing timer: a mark and an optional colour for the last 0.5 s before the Auto Shot, so you can move until the bar reaches the grey line without delaying the shot.",
            "Swing timer and cast bar: 'Show when' (always, in combat, with a target) replaces 'Show only in combat'.",
            "Hamingway the Hambringer now helps on every settings page. The quick install also has a button to open the pet database.",
            "Minimap button: left or right click opens the settings, Shift + left click the pet database, Shift + right click locks or unlocks all frames.",
        },
        de = {
            "Schnell-Einrichtung: Hamingway der Hambringer führt dich Seite für Seite durch jedes Werkzeug (an oder aus, Position, Größe, Aussehen). Sie öffnet sich bei neuen Charakteren und einmal bei bestehenden. /hht setup startet sie jederzeit neu, und Überspringen ändert nichts.",
            "Profile: Speichere deine Einstellungen unter einem Namen, lade, benenne um, kopiere und lösche sie und exportiere oder importiere sie als Text. Importierter Text wird zu einem Profil namens 'Importiertes Profil #1', '#2' und so weiter. Profile gelten für alle deine Charaktere.",
            "Die Schnell-Einrichtung bietet auf der ersten Seite an, die Einstellungen eines anderen Charakters oder ein Profil zu übernehmen.",
            "Swing-Timer: Eine Markierung und optional eine Färbung für die letzten 0,5 s vor dem Auto-Shot, damit du dich bewegen kannst, bis die Leiste die graue Markierung erreicht, ohne den Schuss zu verzögern.",
            "Swing-Timer und Zauberleiste: 'Anzeigen wenn' (immer, im Kampf, mit Ziel) ersetzt 'Nur im Kampf anzeigen'.",
            "Hamingway der Hambringer hilft jetzt auf jeder Einstellungsseite. Die Schnell-Einrichtung hat außerdem einen Button, der die Tier-Datenbank öffnet.",
            "Minimap-Button: Links- oder Rechtsklick öffnet die Einstellungen, Shift + Linksklick die Tier-Datenbank, Shift + Rechtsklick sperrt oder entsperrt alle Fenster.",
        },
    },
    {
        v = "1.3.1",
        en = {
            "Pet database: removed ability ranks above level 60 (Bite 9, Claw 9, Gore 9, Cower 7, Screech 5, Scorpid Poison 5). They do not exist on WoW Forever, so the highest rank shown is now the real one.",
        },
        de = {
            "Tier-Datenbank: Fähigkeitsränge über Level 60 entfernt (Biss 9, Klaue 9, Aufspießen 9, Ducken 7, Kreischen 5, Skorpidgift 5). Sie existieren auf WoW Forever nicht, der höchste angezeigte Rang ist jetzt der echte.",
        },
    },
    {
        v = "1.3.0",
        en = {
            "New look: rounded windows and popups with themes, a banner header, tabs and a new icon set (Lucide). Popups adapt their width to their content.",
            "Beast popup (Pet watch): rebuilt with cards for stats, food, what the beast teaches and what the family learns. Food types have icons, and the stats and abilities have tooltips (abilities show the spell tooltip, green when you can learn a higher rank).",
            "Cooldowns: new layouts 'Individual icons' and 'One bar'. Icons are clickable and show the key, a tooltip and a tint when the ability is not usable.",
            "Move mode locks itself when combat starts, so frames with clickable buttons cannot get stuck.",
            "Keys with umlauts (for example the key U with umlaut) can now be bound for clicks. Right-click a key button to clear it.",
            "Pet feeder: the hunger warning now also appears when the pet is only content (yellow), not just unhappy. Can be switched off in the Pet feeder options.",
        },
        de = {
            "Neuer Look: Abgerundete Fenster und Popups mit Themes, Banner-Kopfzeile, Tabs und neuem Icon-Set (Lucide). Popups passen ihre Breite an den Inhalt an.",
            "Tier-Popup (Pet watch): Neu gebaut mit Karten für Werte, Futter, was das Tier lehrt und was die Familie lernt. Futterarten haben Icons, Werte und Fähigkeiten haben Tooltips (Fähigkeiten zeigen den Zauber-Tooltip, grün wenn du einen höheren Rang lernen kannst).",
            "Abklingzeiten: Neue Layouts 'Einzelne Icons' und 'Eine Leiste'. Icons sind klickbar und zeigen Taste, Tooltip und eine Färbung, wenn die Fähigkeit nicht nutzbar ist.",
            "Der Verschieben-Modus sperrt sich automatisch, wenn ein Kampf beginnt, damit Frames mit klickbaren Buttons nicht hängen bleiben.",
            "Tasten mit Umlauten (zum Beispiel Ü) lassen sich jetzt für Klicks belegen. Rechtsklick auf einen Tasten-Button löscht die Belegung.",
            "Begleiter-Futter: Die Hunger-Warnung erscheint jetzt auch, wenn der Begleiter nur zufrieden (gelb) ist, nicht erst bei unzufrieden. In den Optionen des Futter-Moduls abschaltbar.",
        },
    },
    {
        v = "1.2.7",
        en = {
            "Pet status: a yellow exclamation mark on the pet portrait shows when beasts in your current zone teach your pet a higher ability rank. Click it to open or close the zone list (greyed out and not clickable in combat). Can be switched off in the Pet status options.",
            "Pet ability alerts: the zone list now also appears after logging in or reloading, not only when you enter a new zone.",
        },
        de = {
            "Begleiter-Status: Ein gelbes Ausrufezeichen am Pet-Portrait zeigt, wenn Tiere in deiner aktuellen Zone deinem Begleiter einen höheren Fähigkeitsrang beibringen. Klick öffnet oder schließt die Zonenliste (im Kampf ausgegraut und nicht klickbar). In den Optionen des Begleiter-Status abschaltbar.",
            "Begleiter-Fähigkeiten-Hinweis: Die Zonenliste erscheint jetzt auch nach dem Einloggen oder /reload, nicht nur beim Betreten einer neuen Zone.",
        },
    },
    {
        v = "1.2.6",
        en = {
            "Pet training hint: Growl is now included, so you are told when your pet can learn a higher Growl rank.",
        },
        de = {
            "Pet-Training-Hinweis: Knurren (Growl) wird jetzt ebenfalls berücksichtigt, du wirst benachrichtigt, wenn dein Tier einen höheren Knurren-Rang lernen kann.",
        },
    },
    {
        v = "1.2.5",
        en = {
            "Cooldowns: the countdown numbers and the cooldown swipe on the icons are back.",
        },
        de = {
            "Abklingzeiten: Die Zahlen und der Cooldown-Kreis auf den Icons werden wieder angezeigt.",
        },
    },
    {
        v = "1.2.4",
        en = {
            "Warnings: fixed a Lua error when hovering the 'pet low health' icon. The icon no longer catches mouse clicks while it is faded out, so you no longer cast Mend Pet by accident.",
        },
        de = {
            "Warnungen: Lua-Fehler beim Überfahren des Icons 'Tier niedrige Gesundheit' behoben. Das ausgeblendete Icon fängt keine Mausklicks mehr ab, damit du nicht versehentlich Tier heilen wirkst.",
        },
    },
    {
        v = "1.2.3",
        en = {
            "Warnings: the 'pet low health' warning works again. The game hides the pet's health from addons, so the icon is now faded in by the game itself when the pet drops below your threshold, in and out of combat.",
            "/hht debug shows what the pet health warning can read.",
        },
        de = {
            "Warnungen: Die Warnung 'Tier niedrige Gesundheit' funktioniert wieder. Das Spiel verbirgt die Gesundheit des Tiers vor Addons, deshalb blendet jetzt das Spiel selbst das Icon ein, sobald das Tier unter deine Schwelle fällt, im und außerhalb des Kampfs.",
            "/hht debug zeigt, was die Tier-Gesundheitswarnung lesen kann.",
        },
    },
    {
        v = "1.2.2",
        en = {
            "Ammo vendors: positions and wares checked against the latest Questie data for Forever. Fixes vendors that were off the mark (for example in Redridge Mountains), vendors that sell only arrows or only bullets, and adds two missing vendors in Loch Modan and Ashenvale.",
        },
        de = {
            "Munitionshändler: Positionen und Waren mit den aktuellen Questie-Daten für Forever abgeglichen. Behebt falsch eingetragene Händler (zum Beispiel im Rotkammgebirge), Händler die nur Pfeile oder nur Kugeln verkaufen, und ergänzt zwei fehlende Händler in Loch Modan und Ashenvale.",
        },
    },
    {
        v = "1.2.1",
        en = {
            "Ammo upgrades: better quivers and ammo pouches are no longer suggested when you already wear or carry a better one, and worn quivers are now detected correctly. Ammo you already carry also hides the worse suggestions.",
            "Ammo upgrades: hovering a suggestion shows the item tooltip and where to get it.",
            "Ammo list: damage of Miniature Cannon Balls and the source of Explosive Arrow corrected.",
            "/hht ammo debug prints what the ammo and quiver detection sees.",
        },
        de = {
            "Munitions-Aufwertungen: Bessere Köcher und Munitionsbeutel werden nicht mehr vorgeschlagen, wenn du schon einen besseren trägst oder dabeihast, getragene Köcher werden jetzt richtig erkannt. Auch Munition, die du schon dabeihast, blendet schlechtere Vorschläge aus.",
            "Munitions-Aufwertungen: Beim Überfahren eines Vorschlags erscheint der Gegenstands-Tooltip samt Bezugsquelle.",
            "Munitionsliste: Schaden der Miniature Cannon Balls und Quelle der Explosive Arrow korrigiert.",
            "/hht ammo debug zeigt, was die Munitions- und Köcher-Erkennung sieht.",
        },
    },
    {
        v = "1.2.0",
        en = {
            "New module Aspect and tracking: one button and key each, toggle between two spells, Shift, Ctrl and Alt variants. A small X on the tracking icon turns tracking off.",
            "Ammo: a green arrow appears when better ammo for your level is in your bags. Click it to see and equip the upgrades. It also suggests better quivers (arrows) and ammo pouches (bullets), and engineer-crafted ammo can be switched on.",
            "Pet feeder: feeding now also works with its own key. New warnings when the pet gets unhappy (optional sound) and when pet food runs low. Buff food is no longer picked automatically. With the Pet feeder on, the Warnings module can also show a hungry pet and low food as icons.",
            "Warnings: pet low health (threshold adjustable), hurt pet out of Mend Pet range, and Growl autocast on. A click on the Growl warning switches the autocast off, right-click hides it until reload.",
            "Warnings: Aspect of the Pack in a dungeon or raid is flagged (can be set to every zone). A click switches to your preferred aspect.",
            "Tracking: Find Herbs, Find Minerals, Find Fish and Find Treasure can now be used on the tracking button.",
            "This window: after an update it shows what is new. /hht news opens it any time.",
        },
        de = {
            "Neues Modul Aspekt und Aufspüren: je ein Knopf und eine Taste, Wechsel zwischen zwei Zaubern, Shift-, Strg- und Alt-Varianten. Ein kleines X am Aufspüren-Symbol schaltet es aus.",
            "Munition: ein grüner Pfeil erscheint, wenn bessere Munition für deine Stufe in den Taschen liegt. Klick zeigt die Aufwertungen und legt sie an. Er schlägt auch bessere Köcher (Pfeile) und Munitionsbeutel (Kugeln) vor, Munition von Ingenieuren lässt sich zuschalten.",
            "Tier füttern: Füttern geht jetzt auch per eigener Taste. Neue Warnungen, wenn der Begleiter unzufrieden wird (Ton optional) und wenn das Futter knapp wird. Buff-Futter wird nicht mehr automatisch gewählt. Bei aktivem Begleiter-Futter zeigt das Warnungen-Modul auch hungrigen Begleiter und knappes Futter als Symbol.",
            "Warnungen: Begleiter verletzt (Schwelle einstellbar), verletzter Begleiter außer Heilreichweite und Knurren auf Autocast. Ein Klick auf die Knurren-Warnung schaltet den Autocast aus, Rechtsklick blendet sie bis zum Neuladen aus.",
            "Warnungen: Aspekt des Rudels in Dungeon oder Schlachtzug wird gemeldet (auf Wunsch überall). Ein Klick wechselt zu deinem bevorzugten Aspekt.",
            "Aufspüren: Kräuter, Erz, Fische und Schätze finden lassen sich jetzt auf dem Aufspüren-Knopf nutzen.",
            "Dieses Fenster: nach einem Update zeigt es, was neu ist. /hht news öffnet es jederzeit.",
        },
    },
    {
        v = "1.1.1",
        en = { "Pet training hint now also works for Great Stamina and Natural Armor." },
        de = { "Der Begleiter-Training-Hinweis greift jetzt auch bei Große Ausdauer und Natürliche Rüstung." },
    },
    {
        v = "1.1.0",
        en = {
            "Pet guide: new Guide tab in the pet database and a one-time hint at level 10.",
            "Zone upgrade list: entering a zone lists all beasts there that teach one of your pets a higher rank.",
            "Rare and wishlist alerts redesigned, with family role, diet, taught abilities and 3D model.",
        },
        de = {
            "Tierratgeber: neuer Ratgeber-Reiter in der Tierdatenbank und ein einmaliger Hinweis auf Stufe 10.",
            "Zonen-Liste: beim Betreten einer Zone werden alle Tiere gelistet, die einem deiner Begleiter einen höheren Rang beibringen.",
            "Hinweise zu seltenen und Wunschlisten-Tieren neu gestaltet, mit Familienrolle, Nahrung, lehrbaren Fähigkeiten und 3D-Modell.",
        },
    },
}

local WN = {}
HHT.WhatsNew = WN
local D = HHT.Dwarf

local function parse(v)
    if type(v) ~= "string" then return nil end
    local t = {}
    for n in v:gmatch("%d+") do t[#t + 1] = tonumber(n) end
    return #t > 0 and t or nil
end

local function newer(a, b)
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------
local WIDTH, CONTENT_W, MAX_BODY = 470, 442 - 20, 340
local win

-- What the dwarf says on top of the window.
local SAY = {
    latest = {
        en = "Fresh from the forge, hunter! Here be what changed in version %s.",
        de = "Frisch aus der Schmiede, Jäger! Das hat sich in Version %s geändert.",
    },
    since = {
        en = "Ye missed a few forgings, hunter! Here be everything since version %s.",
        de = "Du hast ein paar Schmiedegänge verpasst, Jäger! Das ist alles seit Version %s.",
    },
    all = {
        en = "Ye want the whole ledger? Aye, here be every change since me first hammer swing.",
        de = "Du willst das ganze Hauptbuch? Na gut, hier ist jede Änderung seit meinem ersten Hammerschlag.",
    },
}

local function Window()
    if win then return win end
    local L = HHT.L
    win = UI.Window("HHTWhatsNew", WIDTH, 300, L("What's new") .. " - Hamingway's HunterTools")
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    win:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "HHTWhatsNew") end

    win.dwarf = HHT.Dwarf.New(win, WIDTH - 28)
    win.dwarf:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -40)

    local sf = CreateFrame("ScrollFrame", nil, win)
    sf:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -40)
    sf:SetPoint("TOPRIGHT", win, "TOPRIGHT", -14, -40)
    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(CONTENT_W + 20)
    content:SetHeight(1)
    sf:SetScrollChild(content)
    win.updateBar = UI.ScrollBar(sf, content, 8, 40)
    win.scroll, win.content, win.rows = sf, content, {}

    local chk = UI.Check(win, L("Show this window after updates"),
        function() local g = HHT.db and HHT.db.general; return not (g and g.whatsNew == false) end,
        function(v) if HHT.db then HHT.db.general.whatsNew = v and true or false end end)
    chk:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 12)
    win.chk = chk

    local close = UI.Button(win, 100, 22, L("Close"), function() win:Hide() end)
    close:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 11)
    return win
end

local function Row(i, size)
    local fs = win.rows[i]
    if not fs then
        fs = UI.Text(win.content, "", size)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        win.rows[i] = fs
    end
    if fs:SetFont(UI.FONT, size, "") == false then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
    fs:Show()
    return fs
end

-- entries: list of NOTES entries to show, newest first.
local function Fill(entries)
    local L = HHT.L
    local lang = HHT.CurrentLang()
    local a = UI.ACCENT
    local n, y = 0, 2
    for _, e in ipairs(entries) do
        if y > 2 then y = y + 10 end
        n = n + 1
        local head = Row(n, 13)
        head:SetTextColor(a[1], a[2], a[3])
        head:SetWidth(CONTENT_W)
        head:ClearAllPoints()
        head:SetPoint("TOPLEFT", win.content, "TOPLEFT", 0, -y)
        head:SetText(string.format(L("Version %s"), e.v))
        y = y + head:GetStringHeight() + 5
        local items = e[lang] or e.en or {}
        if #items == 0 then items = { L("No notes for this version.") } end
        for _, line in ipairs(items) do
            n = n + 1
            local fs = Row(n, 12)
            fs:SetTextColor(0.92, 0.94, 0.97)
            fs:SetWidth(CONTENT_W - 14)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", win.content, "TOPLEFT", 14, -y)
            fs:SetText("- " .. line)
            y = y + fs:GetStringHeight() + 4
        end
    end
    for i = n + 1, #win.rows do win.rows[i]:Hide() end
    local top = 40 + win.dwarf:GetHeight() + 10
    win.scroll:ClearAllPoints()
    win.scroll:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -top)
    win.scroll:SetPoint("TOPRIGHT", win, "TOPRIGHT", -14, -top)
    win.content:SetHeight(y + 4)
    local body = math.min(y + 4, MAX_BODY)
    win.scroll:SetHeight(body)
    win:SetHeight(top + body + 12 + 44)
    win.scroll:SetVerticalScroll(0)
    win.updateBar()
end

-- entries: NOTES entries to show (newest first) or "all".
function WN.Open(entries)
    local w = Window()
    local line
    if entries == "all" then
        entries = NOTES
        line = D.Pick(SAY.all)
    elseif entries and #entries > 1 then
        line = D.Pick(SAY.since, entries[#entries].v)
    end
    if not entries or #entries == 0 then entries = { NOTES[1] } end
    line = line or D.Pick(SAY.latest, entries[1].v)
    w:Show()
    w.dwarf:Say(line)
    Fill(entries)
    w.chk:Refresh()
    WN.Dock()
end

-- Sits beside the quick install while that is open, so both can be read together.
function WN.Dock()
    if not (win and win:IsShown()) then return end
    local setup = _G.HHTSetup
    if setup and setup:IsShown() then
        win:ClearAllPoints()
        local adopt = _G.HHTSetupAdopt
        if adopt and adopt:IsShown() and adopt:GetLeft() and setup:GetRight() then
            -- stacked under the settings-takeover panel on the same side
            if adopt:GetLeft() >= setup:GetRight() then
                win:SetPoint("TOPLEFT", adopt, "BOTTOMLEFT", 0, -8)
            else
                win:SetPoint("TOPRIGHT", adopt, "BOTTOMRIGHT", 0, -8)
            end
        elseif (UIParent:GetRight() or 0) - (setup:GetRight() or 0) >= WIDTH + 8 then
            win:SetPoint("TOPLEFT", setup, "TOPRIGHT", 8, 0)
        else
            win:SetPoint("TOPRIGHT", setup, "TOPLEFT", -8, 0)
        end
        win.docked = true
    elseif win.docked then
        win.docked = nil
        win:ClearAllPoints()
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    end
end

-- Notes of versions newer than `old` up to the installed version (only the installed one when old is unknown).
local function Pending(old)
    local cur, op = parse(HHT.version), old and parse(old)
    local list = {}
    if not cur then return list end
    for _, e in ipairs(NOTES) do
        local p = parse(e.v)
        if p and not newer(p, cur) and (op and newer(p, op) or (not op and not newer(cur, p))) then
            list[#list + 1] = e
        end
    end
    return list
end

-- ---------------------------------------------------------------------------
-- Login check: opens once per character when the installed version changes.
-- ---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    if not HHT.db then return end
    local g = HHT.db.general
    local old = g.seenVersion
    if old == HHT.version then return end
    g.seenVersion = HHT.version
    if HHT.firstRun or g.whatsNew == false then return end
    local list = Pending(old)
    if #list == 0 then return end
    C_Timer.After(6, function()
        if HHT.db then WN.Open(list) end
    end)
end)
