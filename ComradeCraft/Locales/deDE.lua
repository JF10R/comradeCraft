-- deDE translations. Keys: the English text (see Locale.lua); loaded only on a deDE client.
local _, ns = ...
local loc = GetLocale and GetLocale()
if loc ~= "deDE" then return end
ns.Translations = ns.Translations or {}
ns.Translations[loc] = {
    ["commands: /comrade (window) | share [off] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"] =
      "Befehle: /comrade (Fenster) | share [off] | add NAME | remove NAME | peers | sync | guildping [off] | shop [Beruf] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear",
    ["log cleared"] =
      "Log geleert",
    ["%d lines in the log (written to disk on /reload or logout)"] =
      "%d Zeilen im Log (wird bei /reload oder Abmeldung auf die Festplatte geschrieben)",
    ["scan ok: %d distinct items in bags"] =
      "Scan ok: %d verschiedene Gegenstände in den Taschen",
    ["DevTools_Dump missing; see WTF\\...\\SavedVariables\\ComradeCraft.lua after /reload"] =
      "DevTools_Dump fehlt; siehe WTF\\...\\SavedVariables\\ComradeCraft.lua nach /reload",
    ["audit: C_TradeSkillUI.GetAllRecipeIDs missing on this client"] =
      "Audit: C_TradeSkillUI.GetAllRecipeIDs fehlt in diesem Client",
    ["audit: open a profession window first"] =
      "Audit: öffne zuerst ein Berufsfenster",
    ["  %s (%d): game=%s table=%s [%d/%d]"] =
      "  %s (%d): Spiel=%s Tabelle=%s [%d/%d]",
    ["audit rank %d: %d ok, %d mismatches, %d missing from the table"] =
      "Audit Rang %d: %d ok, %d Abweichungen, %d fehlen in der Tabelle",
    ["LibProfessionDB: %d ok, %d mismatches"] =
      "LibProfessionDB: %d ok, %d Abweichungen",
    ["maxTrivialLevel == grey: %d yes, %d no"] =
      "maxTrivialLevel == grau: %d ja, %d nein",
    ["yes"] =
      "ja",
    ["no"] =
      "nein",
    ["%d crafts recorded (calibration from %d per color)"] =
      "%d Herstellungen erfasst (Kalibrierung ab %d pro Farbe)",
    ["orange"] =
      "orange",
    ["yellow"] =
      "gelb",
    ["green"] =
      "grün",
    ["grey"] =
      "grau",
    ["  %s: %d crafts, %d points, Classic formula %.1f%s"] =
      "  %s: %d Herstellungen, %d Punkte, Classic-Formel %.1f%s",
    [" -> factor %.2f applied"] =
      " -> Faktor %.2f angewendet",
    ["  game color known on %d crafts: our table %d right, LibProfessionDB %d right"] =
      "  Spielfarbe bekannt bei %d Herstellungen: unsere Tabelle %d richtig, LibProfessionDB %d richtig",
    ["needs %d"] =
      "braucht %d",
    ["Group total"] =
      "Gruppe gesamt",
    ["Spare in the group"] =
      "Überschuss in der Gruppe",
    ["You can give"] =
      "Du kannst geben",
    ["Spare items in your bags that others need. With a mailbox open, click one to prepare the mail."] =
      "Überschüssige Gegenstände in deinen Taschen, die andere brauchen. Bei offenem Briefkasten: anklicken, um den Brief vorzubereiten.",
    ["Mail full (%d attachments): send it, then click again for the rest."] =
      "Brief voll (%d Anhänge): abschicken, dann erneut klicken für den Rest.",
    ["Open a mailbox first."] =
      "Öffne zuerst einen Briefkasten.",
    ["Nothing to give to %s."] =
      "Nichts zu geben an %s.",
    ["Attach what they need"] =
      "Benötigtes anhängen",
    ["Type the name of a group member."] =
      "Gib den Namen eines Gruppenmitglieds ein.",
    ["You need"] =
      "Du brauchst",
    ["Disenchant or keep?"] =
      "Entzaubern oder behalten?",
    ["Green and better items in your bags. Yields are estimates until your disenchants are logged."] =
      "Grüne und bessere Gegenstände in deinen Taschen. Erträge sind Schätzungen, bis deine Entzauberungen erfasst sind.",
    ["Keep: enchanting target (%s)"] =
      "Behalten: Verzauberungsziel (%s)",
    ["Keep: gear for %s"] =
      "Behalten: Ausrüstung für %s",
    ["Sell: AH %s vs disenchant %s"] =
      "Verkaufen: AH %s statt Entzaubern %s",
    ["Disenchant: %s"] =
      "Entzaubern: %s",
    ["the group needs these"] =
      "die Gruppe braucht diese",
    ["give to %s"] =
      "gib an %s",
    ["group: %d"] =
      "Gruppe: %d",
    ["now"] =
      "jetzt",
    ["soon"] =
      "bald",
    ["later"] =
      "später",
    ["trainer"] =
      "Lehrer",
    ["vendor"] =
      "Händler",
    ["quest"] =
      "Quest",
    ["drop"] =
      "Beute",
    ["container"] =
      "Behälter",
    ["Gathering profession: levels by gathering, not crafting."] =
      "Sammelberuf: Aufstieg durchs Sammeln, nicht durchs Herstellen.",
    ["Open this profession's window once so your recipes can be read."] =
      "Öffne das Fenster dieses Berufs einmal, damit deine Rezepte gelesen werden können.",
    ["No data."] =
      "Keine Daten.",
    ["Learn %s at the trainer (skill %s, %s)"] =
      "Lerne %s beim Lehrer (Fertigkeit %s, %s)",
    ["cost unknown until you visit the trainer"] =
      "Kosten unbekannt, bis du den Lehrer besucht hast",
    ["Craft %d %s (%s)"] =
      "Stelle %d %s her (%s)",
    ["Craft %dx %s (%s)"] =
      "Stelle %dx %s her (%s)",
    ["%d %s (vendor)"] =
      "%d %s (Händler)",
    ["Estimated cost: %s (%s prices)."] =
      "Geschätzte Kosten: %s (%s-Preise).",
    ["Estimated cost: at least %s (%s prices, some items have no price)."] =
      "Geschätzte Kosten: mindestens %s (%s-Preise, manche Gegenstände ohne Preis).",
    [" + %d from stock"] =
      " + %d aus dem Vorrat",
    ["%d %s from stock"] =
      "%d %s aus dem Vorrat",
    ["With only your current recipes, you would be stuck at %d."] =
      "Mit deinen aktuellen Rezepten würdest du bei %d steckenbleiben.",
    ["Uses what you already have: %s."] =
      "Nutzt, was du schon hast: %s.",
    ["Buy from a vendor: %s."] =
      "Beim Händler kaufen: %s.",
    ["Stuck at %d: all your known recipes are grey (no more points)."] =
      "Bei %d festgefahren: alle deine bekannten Rezepte sind grau (keine Punkte mehr).",
    ["Stuck at %d: your known recipes barely give points anymore (%d%% chance per craft at best, %d%% needed)."] =
      "Bei %d festgefahren: deine bekannten Rezepte bringen kaum noch Punkte (%d%% Chance pro Herstellung höchstens, %d%% nötig).",
    [" To learn: %s."] =
      " Zu lernen: %s.",
    [" No recipe to learn found within the next 25 points."] =
      " Kein erlernbares Rezept in den nächsten 25 Punkten gefunden.",
    ["  missing %s x%d"] =
      "  fehlt: %s x%d",
    ["just now"] =
      "gerade eben",
    ["%d min ago"] =
      "vor %d Min.",
    ["%d h ago"] =
      "vor %d Std.",
    ["What to craft:"] =
      "Was herstellen:",
    ["Owned: %d / %d"] =
      "Vorhanden: %d / %d",
    ["%d profession"] =
      "%d Beruf",
    ["%d professions"] =
      "%d Berufe",
    ["%d member"] =
      "%d Mitglied",
    ["%d members"] =
      "%d Mitglieder",
    ["Group"] =
      "Gruppe",
    ["Plan"] =
      "Plan",
    ["Can craft"] =
      "Herstellbar",
    ["Lvl %d"] =
      "St. %d",
    ["updated %s"] =
      "aktualisiert %s",
    ["Skill levels and the materials the group still needs. Type to find who can craft something."] =
      "Fertigkeitsstufen und die Materialien, die der Gruppe noch fehlen. Tippe einen Namen, um zu finden, wer etwas herstellen kann.",
    ["Skill levels"] =
      "Fertigkeitsstufen",
    ["Most wanted materials"] =
      "Meistgesuchte Materialien",
    ["Nothing missing yet."] =
      "Noch nichts fehlt.",
    ["Who can craft \"%s\""] =
      "Wer kann „%s“ herstellen",
    ["No recipe matches."] =
      "Kein Rezept passt.",
    ["No profession data. Open your profession windows."] =
      "Keine Berufsdaten. Öffne deine Berufsfenster.",
    ["%d recipe"] =
      "%d Rezept",
    ["%d recipes"] =
      "%d Rezepte",
    ["gear for %s"] =
      "Ausrüstung für %s",
    ["upgrade for %s (+%d)"] =
      "Verbesserung für %s (+%d)",
    ["Enchant"] =
      "Verzauberung",
    ["Consumable"] =
      "Verbrauchsgut",
    ["Bag"] =
      "Tasche",
    ["Weapon"] =
      "Waffe",
    ["Armor"] =
      "Rüstung",
    ["Reagent"] =
      "Material",
    ["Other"] =
      "Sonstiges",
    ["Sync: %d players in the group, %d suggested. skill ~N: value taken from Classic, unconfirmed."] =
      "Sync: %d Spieler in der Gruppe, %d vorgeschlagen. skill ~N: aus Classic übernommener Wert, unbestätigt.",
    ["via %s"] =
      "über %s",
    ["Manage group"] =
      "Gruppe verwalten",
    ["Choose what you share, and with whom."] =
      "Wähle, was du teilst und mit wem.",
    ["%d player"] =
      "%d Spieler",
    ["%d players"] =
      "%d Spieler",
    ["%d request"] =
      "%d Anfrage",
    ["%d requests"] =
      "%d Anfragen",
    ["Your characters"] =
      "Deine Charaktere",
    ["Only checked characters are shared, and only with the players in your group."] =
      "Nur markierte Charaktere werden geteilt, und nur mit den Spielern deiner Gruppe.",
    ["Players in your group"] =
      "Spieler in deiner Gruppe",
    ["They receive your shared characters and you see theirs."] =
      "Sie erhalten deine geteilten Charaktere und du siehst ihre.",
    ["Nobody yet."] =
      "Noch niemand.",
    ["seen %s"] =
      "gesehen %s",
    ["Remove"] =
      "Entfernen",
    ["Requests and suggestions"] =
      "Anfragen und Vorschläge",
    ["Players with ComradeCraft in your guild, or who added you. Add them to share both ways."] =
      "Spieler mit ComradeCraft in deiner Gilde oder die dich hinzugefügt haben. Füge sie hinzu, um in beide Richtungen zu teilen.",
    ["Add"] =
      "Hinzufügen",
    ["Add a player by name"] =
      "Spieler per Name hinzufügen",
    ["For friends outside your guild. They must add you back."] =
      "Für Freunde außerhalb deiner Gilde. Sie müssen dich ebenfalls hinzufügen.",
    ["Options"] =
      "Optionen",
    ["Send a presence signal to the guild at login (no character data)."] =
      "Beim Einloggen ein Anwesenheitssignal an die Gilde senden (keine Charakterdaten).",
    ["All"] =
      "Alle",
    ["Hide gathering"] =
      "Sammelberufe ausblenden",
    ["No profession matches the filter."] =
      "Kein Beruf passt zum Filter.",
    ["%d character"] =
      "%d Charakter",
    ["%d characters"] =
      "%d Charaktere",
    ["Remove from group"] =
      "Aus der Gruppe entfernen",
    ["sync: sent to the players in your group"] =
      "Sync: an die Spieler deiner Gruppe gesendet",
    ["%s is shared with your group"] =
      "%s wird mit deiner Gruppe geteilt",
    ["%s is no longer shared"] =
      "%s wird nicht mehr geteilt",
    ["guild presence signal: on"] =
      "Gildensignal: an",
    ["guild presence signal: off"] =
      "Gildensignal: aus",
    ["Share this character with the group"] =
      "Diesen Charakter mit der Gruppe teilen",
    ["not shared"] =
      "nicht geteilt",
    ["  %s: %d characters, %s"] =
      "  %s: %d Charaktere, %s",
    ["in the group"] =
      "in der Gruppe",
    ["wants to join"] =
      "will beitreten",
    ["suggested"] =
      "vorgeschlagen",
    ["no peer seen yet (they need ComradeCraft)"] =
      "noch kein Spieler gesehen (er braucht ComradeCraft)",
    ["%s added to the group"] =
      "%s zur Gruppe hinzugefügt",
    ["%s contacted; added as soon as they answer"] =
      "%s kontaktiert; wird hinzugefügt, sobald er antwortet",
    ["%s removed from the group"] =
      "%s aus der Gruppe entfernt",
    ["Could not create the Auctionator list (see /comrade log)."] =
      "Auctionator-Liste konnte nicht erstellt werden (siehe /comrade log).",
    ["Nothing to buy for %s."] =
      "Nichts zu kaufen für %s.",
    ["Auctionator list \"ComradeCraft: %s\" created: %d items. Open the Shopping tab at the auction house."] =
      "Auctionator-Liste „ComradeCraft: %s“ erstellt: %d Gegenstände. Öffne den Tab „Shopping“ im Auktionshaus.",
    ["%d not cached yet; try again in a moment."] =
      "%d noch nicht im Cache; versuche es gleich noch einmal.",
    ["Nothing to buy."] =
      "Nichts zu kaufen.",
    ["Step panel hidden. /comrade tracker shows it again."] =
      "Schrittfenster ausgeblendet. /comrade tracker zeigt es wieder an.",
    ["TSM shopping (Ctrl+C to copy)"] =
      "TSM-Einkauf (Strg+C zum Kopieren)",
    ["Search: paste in the search box of TSM's Shopping tab."] =
      "Suche: in das Suchfeld des TSM-Tabs „Shopping“ einfügen.",
    ["Group: TSM, Groups, Import. Quantities are in the search above (recomputed on each click)."] =
      "Gruppe: TSM, Groups, Import. Die Mengen stehen in der Suche oben (bei jedem Klick neu berechnet).",
    ["TSM group \"%s\": everything bought, delete it in TSM (Groups, right-click)."] =
      "TSM-Gruppe „%s“: alles gekauft, lösche sie in TSM (Groups, Rechtsklick).",
    ["TSM group \"%s\": replaced by a newer one, delete it in TSM (Groups, right-click)."] =
      "TSM-Gruppe „%s“: durch eine neuere ersetzt, lösche sie in TSM (Groups, Rechtsklick).",
    ["Send now"] =
      "Jetzt senden",
    ["Show the step panel next to the profession window."] =
      "Das Schrittfenster neben dem Berufsfenster anzeigen.",
    ["Re-dock"] =
      "Andocken",
    ["Measured skill-up chances"] =
      "Gemessene Skill-up-Chancen",
    ["Crafts logged by you and your group correct the Classic formula once a color has enough of them."] =
      "Von dir und deiner Gruppe erfasste Herstellungen korrigieren die Classic-Formel, sobald eine Farbe genug davon hat.",
    ["The window"] =
      "Das Fenster",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "Links: die Gruppe, dann jeder Charakter. Plan = wie man einen Beruf levelt; Herstellbar = was dieser Charakter für die Gruppe herstellen kann. Die Chips filtern nach Beruf.",
    ["Plans"] =
      "Pläne",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never. ~ marks a value taken from Classic."] =
      "Jeder Schritt sagt, was beim Lehrer zu lernen ist, was zuerst herzustellen ist (Stoffbolzen, Barren ...) und wie viel. Klick auf eine Zeile öffnet das Rezept, Umschalt+Klick verlinkt es. Farben: orange gibt immer einen Punkt, gelb meistens, grün selten, grau nie. ~ markiert einen aus Classic übernommenen Wert.",
    ["Tooltips"] =
      "Tooltips",
    ["On any material: who in the group needs it, how many, and how soon (now, soon, later). Spare stock in the group is shown too."] =
      "Bei jedem Material: wer in der Gruppe es braucht, wie viele und wie bald (jetzt, bald, später). Überschüsse in der Gruppe werden ebenfalls angezeigt.",
    ["Step panel"] =
      "Schrittfenster",
    ["Next to your profession window: the current step, the chance per craft, how many crafts your bags allow, and what comes next."] =
      "Neben deinem Berufsfenster: der aktuelle Schritt, die Chance pro Herstellung, wie viele Herstellungen deine Taschen erlauben und was als Nächstes kommt.",
    ["Giving and mail"] =
      "Geben und Post",
    ["You can give lists what you hold that others need. At a mailbox, the button beside the send frame attaches it. Nothing is ever sent for you."] =
      "„Du kannst geben“ listet auf, was du hast und andere brauchen. Am Briefkasten hängt der Knopf neben dem Versandfenster es an. Es wird nie etwas für dich verschickt.",
    ["Disenchant or keep"] =
      "Entzaubern oder behalten",
    ["Your green items: keep one per slot your enchanting plan needs, keep upgrades for group members, sell what is worth more than its mats, disenchant the rest."] =
      "Deine grünen Gegenstände: pro Platz, den dein Verzauberungsplan braucht, einen behalten, Verbesserungen für Gruppenmitglieder behalten, verkaufen, was mehr wert ist als seine Mats, den Rest entzaubern.",
    ["Shopping"] =
      "Einkauf",
    ["The Shopping list button makes an Auctionator list, or a TSM search and group to paste. TSM groups that are done are pointed out."] =
      "Der Knopf Einkaufsliste erstellt eine Auctionator-Liste oder eine TSM-Suche samt Gruppe zum Einfügen. Fertige TSM-Gruppen werden markiert.",
    ["Sharing"] =
      "Teilen",
    ["Nothing is shared until you check a character in Manage group, and only with players you added who added you back."] =
      "Nichts wird geteilt, bis du in Gruppe verwalten einen Charakter markierst, und nur mit Spielern, die du hinzugefügt hast und die dich ebenfalls hinzugefügt haben.",
    ["Better with"] =
      "Noch besser mit",
    ["TSM or Auctionator (prices), Pawn (upgrades for each class and spec). All optional."] =
      "TSM oder Auctionator (Preise), Pawn (Verbesserungen je Klasse und Spezialisierung). Alles optional.",
    ["Replay the tour"] =
      "Tour wiederholen",
    ["Welcome to ComradeCraft"] =
      "Willkommen bei ComradeCraft",
    ["It answers one question: what should I do with what I have, for the group? 30 seconds to see the main parts."] =
      "Es beantwortet eine Frage: Was mache ich mit dem, was ich habe, für die Gruppe? 30 Sekunden für die wichtigsten Teile.",
    ["Your group"] =
      "Deine Gruppe",
    ["Left: the group overview, the group management, then every character you share or receive."] =
      "Links: die Gruppenübersicht, die Gruppenverwaltung, dann jeder Charakter, den du teilst oder empfängst.",
    ["Plan and Can craft"] =
      "Plan und Herstellbar",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Wähle einen Charakter: Plan zeigt Schritt für Schritt, wie man jeden Beruf levelt; Herstellbar zeigt, was er für andere herstellen kann.",
    ["While you play"] =
      "Während du spielst",
    ["Item tooltips show who needs a material. A step panel opens next to your profession window."] =
      "Gegenstands-Tooltips zeigen, wer ein Material braucht. Neben deinem Berufsfenster öffnet sich ein Schrittfenster.",
    ["Sharing is off until you check a box"] =
      "Teilen ist aus, bis du ein Kästchen markierst",
    ["Nothing is shared yet. Here, in Manage group, check the box next to each character you want to share under Your characters (on the left of this card). Unchecked characters never leave your computer. Then add your friends below, or accept guildmates who appear there. The ? button explains the rest."] =
      "Noch wird nichts geteilt. Markiere hier in Gruppe verwalten das Kästchen neben jedem Charakter, den du teilen willst, unter Deine Charaktere (links auf dieser Karte). Nicht markierte Charaktere verlassen nie deinen Computer. Füge danach unten deine Freunde hinzu oder akzeptiere Gildenmitglieder, die dort erscheinen. Der ?-Knopf erklärt den Rest.",
    ["Do not show again"] =
      "Nicht mehr anzeigen",
    ["Skip"] =
      "Überspringen",
    ["Done"] =
      "Fertig",
    ["Next"] =
      "Weiter",
    ["Help"] =
      "Hilfe",
    ["How ComradeCraft works, in short."] =
      "Wie ComradeCraft funktioniert, kurz gefasst.",
    ["Cheapest"] =
      "Günstigste",
    ["Profitable"] =
      "Rentabelste",
    ["Route:"] =
      "Route:",
    ["Picks recipes whose products sell back well. More crafts, so more mats: tooltips, the give list, mail and shopping all follow this route."] =
      "Wählt Rezepte, deren Produkte sich gut weiterverkaufen. Mehr Herstellungen, also mehr Mats: Tooltips, die Gebenliste, Post und Einkauf folgen dieser Route.",
    ["Chosen by its owner."] =
      "Vom Besitzer gewählt.",
    ["Spends the least on mats."] =
      "Gibt am wenigsten für Mats aus.",
    ["Where to get it: unknown."] =
      "Wo man es bekommt: unbekannt.",
    ["Where to get it:"] =
      "Wo man es bekommt:",
    ["and %d more"] =
      "und %d weitere",
    ["Sources taken from another game version, unconfirmed on Forever."] =
      "Quellen aus einer anderen Spielversion, auf Forever unbestätigt.",
    ["Install Questie for locations; TomTom for waypoints."] =
      "Installiere Questie für Positionen, TomTom für Wegpunkte.",
    ["Click: waypoint to the nearest one."] =
      "Klick: Wegpunkt zum nächsten.",
    ["No known location for %s."] =
      "Keine bekannte Position für %s.",
    ["%s: %s. Install TomTom for a waypoint."] =
      "%s: %s. Installiere TomTom für einen Wegpunkt.",
    ["Waypoint: %s"] =
      "Wegpunkt: %s",
    ["Mats per craft:"] =
      "Mats pro Herstellung:",
    ["+%d more"] =
      "+%d weitere",
    ["Recipe and mats"] =
      "Rezept und Mats",
    ["For the group"] =
      "Für die Gruppe",
    ["Type"] =
      "Typ",
    ["Mats cost"] =
      "Mat-Kosten",
    ["At the trainer - skill %s - %s"] =
      "Beim Lehrer - Fertigkeit %s - %s",
    ["already in your bags"] =
      "schon in deinen Taschen",
    ["Cost by milestone (%s prices)"] =
      "Kosten pro Etappe (%s-Preise)",
    ["Cost by milestone (merchant prices; TSM or Auctionator give AH prices)"] =
      "Kosten pro Etappe (Händlerpreise; TSM oder Auctionator liefern AH-Preise)",
    ["Skill %d to %d"] =
      "Fertigkeit %d bis %d",
    ["Learn %s"] =
      "%s lernen",
    ["Skill"] =
      "Stufe",
    ["Route"] =
      "Route",
    ["Mats"] =
      "Mats",
    ["Sold back"] =
      "Weiterverkauf",
    ["Net cost"] =
      "Nettokosten",
    ["nothing"] =
      "nichts",
    ["unknown"] =
      "unbekannt",
    ["Sold to a merchant"] =
      "An Händler verkauft",
    ["Disenchanted"] =
      "Entzaubert",
    ["At the auction house (-5%, deposit risk)"] =
      "Im Auktionshaus (-5 %, Einstellgebühr riskiert)",
    ["Best way per item"] =
      "Beste Option pro Gegenstand",
    ["Net cost = mats minus the best resale of each item. A green + is a profit. Hover a line for the details."] =
      "Nettokosten = Mats minus der beste Weiterverkauf jedes Gegenstands. Ein grünes + ist ein Gewinn. Fahre über eine Zeile für Details.",
    ["Next: %s"] =
      "Weiter: %s",
    ["Click to expand."] =
      "Klicken zum Aufklappen.",
    ["Could not start the craft (see /comrade log)."] =
      "Herstellung konnte nicht gestartet werden (siehe /comrade log).",
    ["Queue:"] =
      "Warteschlange:",
    ["up to skill %d (click: this step only)"] =
      "bis Fertigkeit %d (Klick: nur dieser Schritt)",
    ["this step (click: up to the milestone)"] =
      "dieser Schritt (Klick: bis zur Etappe)",
    ["by hand (needs a target)"] =
      "von Hand (Ziel nötig)",
    ["ready"] =
      "bereit",
    ["%d ready"] =
      "%d bereit",
    ["Craft next: %dx %s"] =
      "Als Nächstes herstellen: %dx %s",
    ["Learn %s first"] =
      "Lerne zuerst %s",
    ["Missing mats for the queue"] =
      "Mats für die Warteschlange fehlen",
    ["Nothing to craft"] =
      "Nichts herzustellen",
    ["%s asks %s to craft %dx %s."] =
      "%s bittet %s, %dx %s herzustellen.",
    ["Request %dx %s: %s."] =
      "Anfrage %dx %s: %s.",
    ["Request sent to %s. It is delivered as soon as you are both online."] =
      "Anfrage an %s gesendet. Sie wird zugestellt, sobald ihr beide online seid.",
    ["Quantity"] =
      "Menge",
    ["Note (optional)"] =
      "Notiz (optional)",
    ["Send request"] =
      "Anfrage senden",
    ["Ask %s to craft %s"] =
      "%s bitten, %s herzustellen",
    ["Craft requests"] =
      "Herstellungsanfragen",
    ["%d to answer"] =
      "%d zu beantworten",
    ["none open"] =
      "keine offen",
    ["Ask a group member to craft something, or answer what they asked you."] =
      "Bitte ein Gruppenmitglied, etwas herzustellen, oder beantworte, worum man dich gebeten hat.",
    ["Click: ask %s to craft it."] =
      "Klick: %s bitten, es herzustellen.",
    ["%s for %s"] =
      "%s für %s",
    ["asked to %s"] =
      "%s gefragt",
    ["waiting to reach the other player"] =
      "wartet auf den anderen Spieler",
    ["Mats: %s"] =
      "Mats: %s",
    ["your bags allow %d"] =
      "deine Taschen erlauben %d",
    ["Accept"] =
      "Annehmen",
    ["Decline"] =
      "Ablehnen",
    ["Cancel request"] =
      "Abbrechen",
    ["For your characters"] =
      "Für deine Charaktere",
    ["Your requests"] =
      "Deine Anfragen",
    ["Accept, craft, then mark it done; the mail helper attaches the item when you write to them."] =
      "Annehmen, herstellen, dann als erledigt markieren; die Posthilfe hängt den Gegenstand an, wenn du ihm schreibst.",
    ["Click a recipe in a group member's Can craft tab to ask for it. Delivered the next time you are both online."] =
      "Klicke im Tab Herstellbar eines Mitglieds auf ein Rezept, um es anzufragen. Zugestellt, sobald ihr beide online seid.",
    ["pending"] =
      "offen",
    ["accepted"] =
      "angenommen",
    ["declined"] =
      "abgelehnt",
    ["done"] =
      "erledigt",
    ["cancelled"] =
      "abgebrochen",
    ["(by mail)"] =
      "(per Post)",
    ["Request mail ready: check it and click Send."] =
      "Anfragebrief bereit: prüfen und auf Senden klicken.",
    ["By mail"] =
      "Per Post",
    ["Craft requests by mail too: for players who are never online at the same time (you send the mail yourself, 30c postage)."] =
      "Herstellungsanfragen auch per Post: für Spieler, die nie gleichzeitig online sind (du schickst den Brief selbst, 30 K Porto).",
    ["other profession"] =
      "anderer Beruf",
    ["Routes"] =
      "Routen",
    ["Each character picks Cheapest (least spent on mats) or Profitable (products sold back). The milestone table compares both: mats, what the products bring back (merchant, disenchant or AH) and the net cost."] =
      "Jeder Charakter wählt Günstigste (am wenigsten für Mats) oder Rentabelste (Produkte weiterverkauft). Die Etappentabelle vergleicht beide: Mats, was die Produkte einbringen (Händler, Entzauberung oder AH) und die Nettokosten.",
    ["Learning recipes"] =
      "Rezepte lernen",
    ["Hover a Learn line for its trainers, vendors and drops; click it for a TomTom waypoint (with Questie installed for positions)."] =
      "Fahre über eine Zeile Lernen für Lehrer, Händler und Beute; klicke darauf für einen TomTom-Wegpunkt (mit Questie für Positionen).",
    ["Craft queue"] =
      "Herstellungswarteschlange",
    ["In the step panel: the crafts of this step or of the whole milestone, what your bags allow, and Craft next (one batch per click, the game needs a click per craft)."] =
      "Im Schrittfenster: die Herstellungen dieses Schritts oder der ganzen Etappe, was deine Taschen erlauben, und Als Nächstes herstellen (ein Stapel pro Klick, das Spiel braucht einen Klick pro Herstellung).",
    ["Click a recipe in a group member's Can craft tab to ask for it. Answer what you are asked in Craft requests. Requests reach the other player the next time you are both online (or by mail, if turned on in Manage group)."] =
      "Klicke im Tab Herstellbar eines Mitglieds auf ein Rezept, um es anzufragen. Beantworte Anfragen unter Herstellungsanfragen. Anfragen erreichen den anderen Spieler, sobald ihr beide online seid (oder per Post, wenn in Gruppe verwalten aktiviert).",
    ["%s: mats ready"] =
      "%s: Mats bereit",
    ["Your bags hold everything for %dx %s."] =
      "Deine Taschen enthalten alles für %dx %s.",
    ["Cooldown ready: %s"] =
      "Abklingzeit bereit: %s",
    ["on %s"] =
      "auf %s",
    ["+%d with Pawn"] =
      "+%d mit Pawn",
    ["+%d item levels"] =
      "+%d Gegenstandsstufen",
    ["%s can craft an upgrade for you"] =
      "%s kann eine Verbesserung für dich herstellen",
    ["Ask for it"] =
      "Anfragen",
    ["Not interested"] =
      "Kein Interesse",
    ["New craft request"] =
      "Neue Herstellungsanfrage",
    ["Open"] =
      "Öffnen",
    ["Alerts"] =
      "Hinweise",
    ["A chat line and a short notice at the top of the screen."] =
      "Eine Chatzeile und eine kurze Meldung oben auf dem Bildschirm.",
    ["Your bags hold the mats for your next craft."] =
      "Deine Taschen enthalten die Mats für deine nächste Herstellung.",
    ["A profession cooldown is ready on one of your characters."] =
      "Eine Berufs-Abklingzeit ist bei einem deiner Charaktere bereit.",
    ["A craft request arrives or changes."] =
      "Eine Herstellungsanfrage trifft ein oder ändert sich.",
    ["A group member can craft an upgrade for you (off by default)."] =
      "Ein Gruppenmitglied kann eine Verbesserung für dich herstellen (standardmäßig aus).",
    ["visited"] =
      "besucht",
    ["Next rank: %s (%d to %d)"] =
      "Nächster Rang: %s (%d bis %d)",
    ["Journeyman"] =
      "Geselle",
    ["Expert"] =
      "Experte",
    ["Artisan"] =
      "Fachmann",
    ["Master"] =
      "Meister",
    ["skill %d"] =
      "Fertigkeit %d",
    ["level %d"] =
      "Stufe %d",
    ["sold by %s"] =
      "verkauft von %s",
    ["or at the AH (~%s)"] =
      "oder im AH (~%s)",
    ["or at the AH"] =
      "oder im AH",
    ["Learn it from a trainer of this profession (in Classic: skill %d and character level %d; unconfirmed on Forever)."] =
      "Lerne es bei einem Lehrer dieses Berufs (in Classic: Fertigkeit %d und Charakterstufe %d; auf Forever unbestätigt).",
    ["At the cap (%d)."] =
      "Am Maximum (%d).",
    ["Looking for the quest in Questie..."] =
      "Suche die Quest in Questie ...",
    ["This rank comes from a quest (install Questie to find it)."] =
      "Dieser Rang kommt von einer Quest (installiere Questie, um sie zu finden).",
    ["starts at %s"] =
      "beginnt bei %s",
    ["Quest: %s"] =
      "Quest: %s",
    ["Quests that need %d in this skill; the rank quest is among them."] =
      "Quests, die %d in dieser Fertigkeit verlangen; die Rangquest ist darunter.",
    ["Click: waypoint to the quest giver."] =
      "Klick: Wegpunkt zum Questgeber.",
    ["Shopping list"] =
      "Einkaufsliste",
    ["Full plan"] =
      "Gesamtplan",
    ["Reading the recipes of this profession..."] =
      "Lese die Rezepte dieses Berufs ...",
    ["%d%% chance per craft (%s)"] =
      "%d%% Chance pro Herstellung (%s)",
    ["Step panel: off"] =
      "Schrittfenster: aus",
    ["Step panel: on (shown with the profession window)"] =
      "Schrittfenster: an (mit dem Berufsfenster angezeigt)",
    ["Click: group needs"] =
      "Klick: Gruppenbedarf",
}
