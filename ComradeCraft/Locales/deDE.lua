-- deDE translations. Keys: the English text (see Locale.lua); loaded only on a deDE client.
local _, ns = ...
local loc = GetLocale and GetLocale()
if loc ~= "deDE" then return end
ns.Translations = ns.Translations or {}
ns.Translations[loc] = {
    ["commands: /comrade (window) | share [off] | list [off] | directory [text] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"] =
      "Befehle: /comrade (Fenster) | share [off] | list [off] | directory [Text] | add NAME | remove NAME | peers | sync | guildping [off] | shop [Beruf] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear",
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
    ["The window"] =
      "Das Fenster",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "Links: die Gruppe, dann jeder Charakter. Plan = wie man einen Beruf levelt; Herstellbar = was dieser Charakter für die Gruppe herstellen kann. Die Chips filtern nach Beruf.",
    ["Plans"] =
      "Pläne",
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
    ["Replay the tour"] =
      "Tour wiederholen",
    ["Welcome to ComradeCraft"] =
      "Willkommen bei ComradeCraft",
    ["It answers one question: what should I do with what I have, for the group? 30 seconds to see the main parts."] =
      "Es beantwortet eine Frage: Was mache ich mit dem, was ich habe, für die Gruppe? 30 Sekunden für die wichtigsten Teile.",
    ["Your group"] =
      "Deine Gruppe",
    ["Plan and Can craft"] =
      "Plan und Herstellbar",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Wähle einen Charakter: Plan zeigt Schritt für Schritt, wie man jeden Beruf levelt; Herstellbar zeigt, was er für andere herstellen kann.",
    ["While you play"] =
      "Während du spielst",
    ["Sharing is off until you check a box"] =
      "Teilen ist aus, bis du ein Kästchen markierst",
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
    ["Keep for your group"] =
      "Für deine Gruppe behalten",
    ["%s: %d for %s"] =
      "%s: %d für %s",
    ["and %d more"] =
      "und %d weitere",
    ["You sold %s"] =
      "Du hast %s verkauft",
    ["Buy back"] =
      "Zurückkaufen",
    ["you"] =
      "dich",
    ["At a merchant or the auction house: items in your bags that your group needs."] =
      "Beim Händler oder im Auktionshaus: Gegenstände in deinen Taschen, die deine Gruppe braucht.",
    ["Next rank"] =
      "Nächster Rang",
    ["At the skill cap: the Expert book (vendor or AH), the Artisan quest found in Questie (click for a waypoint to its giver), or the trainer."] =
      "Am Fertigkeitsmaximum: das Expertenbuch (Händler oder AH), die Handwerksmeister-Quest aus Questie (Klick: Wegpunkt zum Questgeber) oder der Lehrer.",
    ["Mats ready, profession cooldowns ready on any of your characters, craft requests, items your group needs when you open a merchant or the AH (with Buy back after a sale), and opt-in upgrades. Each one can be turned off in Manage group."] =
      "Material bereit, Berufsabklingzeiten auf einem deiner Charaktere bereit, Herstellungsanfragen, Gegenstände, die deine Gruppe braucht, wenn du einen Händler oder das AH öffnest (mit Zurückkaufen nach einem Verkauf), und optionale Verbesserungen. Jede lässt sich in Gruppe verwalten abschalten.",
    ["TSM or Auctionator (prices), Questie (positions), TomTom (waypoints), Pawn (upgrades for each class and spec). All optional."] =
      "TSM oder Auctionator (Preise), Questie (Positionen), TomTom (Wegpunkte), Pawn (Verbesserungen für jede Klasse und Spezialisierung). Alles optional.",
    -- Group plan
    ["Spare"] =
      "Überschuss",
    ["Group plan"] =
      "Gruppenplan",
    ["What the group still needs, what it already holds, and who farms what."] =
      "Was der Gruppe noch fehlt, was sie schon hat und wer was farmt.",
    ["Objective:"] =
      "Ziel:",
    ["Lowest group cost"] =
      "Niedrigste Gruppenkosten",
    ["Market value"] =
      "Marktwert",
    ["Least gold spent by the group: stock already held in the group counts as free."] =
      "Am wenigsten Gold für die Gruppe: Vorrat, den die Gruppe schon hat, zählt als kostenlos.",
    ["Every material at its market value, as if each character were alone."] =
      "Jedes Material zum Marktwert, als wäre jeder Charakter allein.",
    ["Material"] =
      "Material",
    ["Needed"] =
      "Benötigt",
    ["To get"] =
      "Zu besorgen",
    ["Est. cost"] =
      "Gesch. Kosten",
    ["Farming"] =
      "Farmen",
    ["Farmed by %s"] =
      "Gefarmt von %s",
    ["Drop"] =
      "Aufgeben",
    ["I'll farm it"] =
      "Ich farme es",
    ["Estimated cost for the group: %s"] =
      "Geschätzte Kosten für die Gruppe: %s",
    ["Estimated cost for the group: at least %s (some items have no price)."] =
      "Geschätzte Kosten für die Gruppe: mindestens %s (manche Gegenstände haben keinen Preis).",
    ["Estimated cost for the group: unknown (TSM or Auctionator give AH prices)."] =
      "Geschätzte Kosten für die Gruppe: unbekannt (TSM oder Auctionator liefern AH-Preise).",
    ["%d %s needed for %s. Do you want to farm them?"] =
      "%d %s für %s benötigt. Möchtest du sie farmen?",
    ["Farming done: %s"] =
      "Farmen fertig: %s",
    ["Give them from You can give in the Group view, or by mail."] =
      "Gib sie über Du kannst geben in der Gruppenansicht oder per Post.",
    ["Show the farming tracker (your farming assignments from the Group plan)."] =
      "Farm-Tracker anzeigen (deine Farm-Aufgaben aus dem Gruppenplan).",
    ["Plans count stock already held in the group as free (or every mat at market value: Manage group > Options). The Group plan view lists what the group still needs and its cost; take a material with I'll farm it and a small tracker follows your progress."] =
      "Pläne zählen Vorrat, den die Gruppe schon hat, als kostenlos (oder jedes Material zum Marktwert: Gruppe verwalten > Optionen). Die Ansicht Gruppenplan listet, was der Gruppe noch fehlt und was es kostet; übernimm ein Material mit Ich farme es, und ein kleiner Tracker zeigt deinen Fortschritt.",
    ["Guild directory"] =
      "Gildenverzeichnis",
    ["%d crafter"] =
      "%d Handwerker",
    ["%d crafters"] =
      "%d Handwerker",
    ["Right box: list the character in the guild directory (professions and recipes only, sent to your guild)."] =
      "Rechtes Kästchen: den Charakter ins Gildenverzeichnis eintragen (nur Berufe und Rezepte, an deine Gilde gesendet).",
    ["List in guild directory"] =
      "Im Gildenverzeichnis eintragen",
    ["Opt-in, per character: List in guild directory in Manage group (or /comrade list) sends its professions and recipes to guildmates who use ComradeCraft. Search who can craft an item, whisper them, or ask for the craft if they are in your group. Item tooltips name up to 3 guild crafters."] =
      "Freiwillig, pro Charakter: Im Gildenverzeichnis eintragen unter Gruppe verwalten (oder /comrade list) sendet seine Berufe und Rezepte an Gildenmitglieder mit ComradeCraft. Suche, wer einen Gegenstand herstellen kann, flüstere ihn an oder bitte um die Herstellung, wenn er in deiner Gruppe ist. Gegenstands-Tooltips nennen bis zu 3 Handwerker der Gilde.",
    ["Whisper"] =
      "Flüstern",
    ["Nobody is listed yet. The directory is opt-in: each player lists their own characters in Manage group (List in guild directory) or with /comrade list."] =
      "Noch niemand eingetragen. Das Verzeichnis ist freiwillig: Jeder Spieler trägt seine eigenen Charaktere unter Gruppe verwalten (Im Gildenverzeichnis eintragen) oder mit /comrade list ein.",
    ["Type a product or recipe name in the search box."] =
      "Gib den Namen eines Gegenstands oder Rezepts in das Suchfeld ein.",
    ["No crafter found."] =
      "Kein Handwerker gefunden.",
    ["... and %d more"] =
      "... und %d weitere",
    ["Who in your guild can craft what. Each player lists their own characters (opt-in)."] =
      "Wer in deiner Gilde was herstellen kann. Jeder Spieler trägt seine eigenen Charaktere ein (freiwillig).",
    ["Guild crafters: %s"] =
      "Handwerker der Gilde: %s",
    ["%s is listed in the guild directory"] =
      "%s ist im Gildenverzeichnis eingetragen",
    ["%s is no longer listed in the guild directory"] =
      "%s ist nicht mehr im Gildenverzeichnis eingetragen",
    ["You are not in a guild: the entry is sent once you are."] =
      "Du bist in keiner Gilde: Der Eintrag wird gesendet, sobald du in einer bist.",
    ["directory: %d characters listed. /comrade directory TEXT searches them."] =
      "Verzeichnis: %d Charaktere eingetragen. /comrade directory TEXT durchsucht sie.",
    ["directory: no crafter for %s"] =
      "Verzeichnis: kein Handwerker für %s",
    -- UI polish, bags, mail & friends
    ["%d item"] = "%d Gegenstand",
    ["%d items"] = "%d Gegenstände",
    ["Add %s"] = "%s hinzufügen",
    ["Add target"] = "Ziel hinzufügen",
    ["Cancel"] = "Abbrechen",
    ["Click a member to highlight their items."] = "Klicke ein Mitglied an, um seine Gegenstände hervorzuheben.",
    ["Click to select recipient and highlight needed items in your bags."] =
      "Klicken, um den Empfänger zu wählen und benötigte Gegenstände in deinen Taschen hervorzuheben.",
    ["Collapse all"] = "Alle einklappen",
    ["ComradeCraft: Add to group"] = "ComradeCraft: Zur Gruppe hinzufügen",
    ["Expand all"] = "Alle ausklappen",
    ["Filter recipes..."] = "Rezepte filtern...",
    ["Search stock or crafters..."] = "Vorrat oder Handwerker suchen...",
    ["For %s"] = "Für %s",
    ["Friend"] = "Freund",
    ["Guild"] = "Gilde",
    ["Highlight items for your group in your bags (and focus a recipient's items when mailing)."] =
      "Gegenstände für deine Gruppe in deinen Taschen hervorheben (und beim Postversand auf den Empfänger fokussieren).",
    ["Highlighted in your bags"] = "In deinen Taschen hervorgehoben",
    ["Nothing to send from your bags."] = "Nichts aus deinen Taschen zu senden.",
    ["Online in your party, friends or guild:"] = "Online in deiner Gruppe, Freundesliste oder Gilde:",
    ["Party"] = "Gruppe",
    ["Ready to send from your bags"] = "Versandbereit aus deinen Taschen",
    ["Retry"] = "Erneut",
    ["Search guild crafters..."] = "Gildenhandwerker suchen...",
    ["Send x%d to %s"] = "x%d an %s senden",
    ["Send x%d to %s (%s)"] = "x%d an %s senden (%s)",
    ["To send from your bags: %s"] = "Aus deinen Taschen senden: %s",
    ["You cannot add yourself."] = "Du kannst dich nicht selbst hinzufügen.",
    ["craft request"] = "Herstellungsanfrage",
    ["waiting for reply"] = "wartet auf Antwort",
    ["Share all"] = "Alle teilen",
    ["Unshare all"] = "Keine teilen",
    ["Automatically share new characters on this account"] =
      "Neue Charaktere dieses Accounts automatisch teilen",
    ["All characters (%d) are now shared with your group"] =
      "Alle Charaktere (%d) werden jetzt mit deiner Gruppe geteilt",
    ["No character is shared anymore"] = "Kein Charakter wird mehr geteilt",
    ["%s requires higher %s skill; skipped for waypoints until you level up."] =
      "%s erfordert eine höhere Fertigkeit in %s; für Wegpunkte übersprungen, bis du aufsteigst.",
    ["Right-click: skip this recipe and recalculate."] =
      "Rechtsklick: dieses Rezept überspringen und neu berechnen.",
    ["Reset skipped (%d)"] = "Übersprungene zurücksetzen (%d)",
    -- Trade, Merchant, Wishlist, Cooldowns & UI rework
    ["%d tracked"] = "%d verfolgt",
    ["%s wants to join your group"] = "%s möchte deiner Gruppe beitreten",
    ["Accept to share your checked characters with them."] =
      "Akzeptieren, um deine ausgewählten Charaktere zu teilen.",
    ["Add to wishlist"] = "Zur Wunschliste hinzufügen",
    ["All materials are in your bags."] = "Alle Materialien sind in deinen Taschen.",
    ["Buy plan reagents (%s)"] = "Plan-Reagenzien kaufen (%s)",
    ["Click to sync now with your group."] = "Klicken, um jetzt mit deiner Gruppe zu synchronisieren.",
    ["Compare routes"] = "Routen vergleichen",
    ["Craft"] = "Herstellen",
    ["Disenchant"] = "Entzaubern",
    ["For who:"] = "Für wen:",
    ["Group cooldowns"] = "Gruppen-Abklingzeiten",
    ["Hide route comparison"] = "Vergleich ausblenden",
    ["Ignore"] = "Ignorieren",
    ["Materials"] = "Materialien",
    ["No craft pinned yet. Right-click any recipe in your Can craft tab to add it here, track its materials and get notified when ready."] =
      "Noch nichts angeheftet. Rechtsklicke ein Rezept unter Herstellbar, um es hier hinzuzufügen, Materialien zu verfolgen und benachrichtigt zu werden.",
    ["No disenchantable items in your bags."] = "Keine entzauberbaren Gegenstände in deinen Taschen.",
    ["Not enough gold (%s needed)."] = "Nicht genug Gold (%s benötigt).",
    ["Note (optional):"] = "Notiz (optional):",
    ["Overview"] = "Übersicht",
    ["Pin"] = "Anheften",
    ["Pin on screen"] = "Auf dem Bildschirm anheften",
    ["Pinned crafts to track materials for yourself or friends."] =
      "Angeheftete Herstellungen, um Materialien für dich oder Freunde zu verfolgen.",
    ["Place needed items"] = "Benötigtes ablegen",
    ["Plan reagents"] = "Plan-Reagenzien",
    ["Quantity:"] = "Menge:",
    ["Ready"] = "Bereit",
    ["Ready (some mats in bank/mail)"] = "Bereit (Mats in Bank/Post)",
    ["Ready to craft!"] = "Bereit zum Herstellen!",
    ["Right-click: add to Wishlist."] = "Rechtsklick: zur Wunschliste hinzufügen.",
    ["Show the wishlist tracker on screen (pinned crafts)."] =
      "Wunschlisten-Tracker auf dem Bildschirm anzeigen (angeheftete Herstellungen).",
    ["Trade window is full (%d slots)."] = "Handelsfenster ist voll (%d Plätze).",
    ["Unpin"] = "Lösen",
    ["Wishlist"] = "Wunschliste",
    ["Wishlist ready: %dx %s"] = "Wunschliste bereit: %dx %s",
    ["none pinned"] = "nichts angeheftet",
    -- Synergies, Audit, Loot, AH Panel, Buy vs Farm
    ["%d small bags (min %d slots) -> %s (%d slots)"] = "%d kleine Taschen (min. %d Pl.) -> %s (%d Pl.)",
    ["%s can craft %dx %s from group's %s for %s"] = "%s kann %dx %s aus %s der Gruppe für %s herstellen",
    ["Advice"] = "Empfehlung",
    ["Back"] = "Rücken",
    ["Buy"] = "Kaufen",
    ["Buy/Farm"] = "Kauf/Farm",
    ["Chest"] = "Brust",
    ["Click an item to search it."] = "Klicke einen Gegenstand zum Suchen.",
    ["Click: search in Auction House."] = "Klick: im Auktionshaus suchen.",
    ["Click: waypoint to farm spot."] = "Klick: Wegpunkt zum Farmgebiet.",
    ["Cross-profession links between your group's active plans."] =
      "Berufsübergreifende Synergien zwischen den Plänen deiner Gruppe.",
    ["Disenchant %dx %s (%s)"] = "%dx %s entzaubern (%s)",
    ["Disenchant for your enchanting plan"] = "Für deinen Verzauberungsplan entzaubern",
    ["Everyone's bags, enchants and gear are up to date."] =
      "Taschen, Verzauberungen und Ausrüstung der Gruppe sind aktuell.",
    ["Farm"] = "Farmen",
    ["Farm %s: %s (%s %d, %d)"] = "%s farmen: %s (%s %d, %d)",
    ["Farm spot"] = "Farmgebiet",
    ["Feet"] = "Füße",
    ["Gear"] = "Ausrüstung",
    ["Gold: %s"] = "Gold: %s",
    ["Group synergies"] = "Gruppen-Synergien",
    ["Group upgrades"] = "Gruppen-Verbesserungen",
    ["Hands"] = "Hände",
    ["Known by %s"] = "Bekannt bei %s",
    ["Loot roll: %s - needed now by %s"] = "Beutewurf: %s - jetzt benötigt von %s",
    ["Loot roll: %s - unknown by %s"] = "Beutewurf: %s - unbekannt bei %s",
    ["No known farm location for %s."] = "Kein bekanntes Farmgebiet für %s.",
    ["Send %dx %s to %s to disenchant (%s)"] = "%dx %s an %s zum Entzaubern senden (%s)",
    ["Send to %s to disenchant"] = "An %s zum Entzaubern senden",
    ["Shield"] = "Schild",
    ["Small bags, unenchanted gear and craftable upgrades your group can make."] =
      "Kleine Taschen, unverzauberte Ausrüstung und herstellbare Verbesserungen deiner Gruppe.",
    ["To buy at the AH"] = "Im AH zu kaufen",
    ["Total: %s (you have %s)"] = "Gesamt: %s (du hast %s)",
    ["Unenchanted %s -> %s"] = "Unverzauberte(r) %s -> %s",
    ["Unknown by %s (%s %d/%d)"] = "Unbekannt bei %s (%s %d/%d)",
    ["Upgrades"] = "Verbesserungen",
    ["Vendor"] = "Händler",
    ["Waypoint: %s (%s %d, %d)"] = "Wegpunkt: %s (%s %d, %d)",
    ["Wrist"] = "Handgelenke",
    ["Your gold: %s"] = "Dein Gold: %s",
    ["by %s"] = "von %s",
    ["by %s (guild)"] = "von %s (Gilde)",
    ["can learn now"] = "jetzt erlernbar",
    ["needs skill %d"] = "benötigt %d",
    ["+%d score"] = "+%d Wertung",
    ["Head"] = "Kopf",
    ["Neck"] = "Hals",
    ["Shoulder"] = "Schultern",
    ["Waist"] = "Taille",
    ["Legs"] = "Beine",
    ["Finger"] = "Finger",
    ["Trinket"] = "Schmuck",
    ["Off-Hand"] = "Nebenhand",
    ["Ranged"] = "Distanz",
    ["Spec: %s"] = "Spez: %s",
    ["Spec set to %s."] = "Spezialisierung gesetzt: %s.",
    ["Unknown spec. Available: %s"] = "Unbekannte Spezialisierung. Verfügbar: %s",
    ["Crafts upgrade for: %s"] = "Verbesserung für: %s",
    ["Useful enchant for: %s"] = "Nützliche Verzauberung für: %s",
    ["Leveling plan"] = "Leveling-Plan",
    ["Upgrade for %s (%s)"] = "Verbesserung für %s (%s)",
    ["Good enchant for %s"] = "Gute Verzauberung für %s",
    ["Click to train."] = "Klick zum Erlernen.",
    ["Recommended recipes"] = "Empfohlene Rezepte",
    ["mats ready"] = "Mats bereit",
    ["Soon (+1-4 lvl)"] = "Bald (+1-4 St.)",
    ["Consumables"] = "Verbrauchsgüter",
    ["Patterns to hunt"] = "Muster zum Farmen",
    ["Waypoint"] = "Wegpunkt",
    ["Group materials:"] = "Gruppenmaterialien:",
    ["%d mobs"] = "%d Gegner",
    ["1 mob"] = "1 Gegner",
    ["in bank"] = "auf der Bank",
    ["In bank (retrieve first)"] = "Auf der Bank (zuerst abholen)",
    ["Full name (First Last) required for %s: log them in once or type their full name first."] =
      "Vollständiger Name (Vorname Nachname) für %s erforderlich: einmal einloggen oder zuerst vollständig eingeben.",
    ["Withdraw from bank"] = "Aus der Bank holen",
    ["Withdraw needed"] = "Benötigtes abholen",
    ["Click an item to withdraw it."] = "Gegenstand anklicken zum Abholen.",
    ["Your bags are full."] = "Deine Taschen sind voll.",
    ["For your plan"] = "Für deinen Plan",
    ["To send to %s"] = "An %s senden",
    ["Right-click: %dx %s -> %dx %s"] = "Rechtsklick: %dx %s -> %dx %s",
    ["BoE patterns"] = "BoE-Muster",
    ["Share in chat"] = "Im Chat teilen",
    ["Shared bank alt"] = "Geteilter Bank-Twink",
    ["Shared bank alt: all items on this character (bags, bank, mail) appear as available to your group, and members can request them via the addon."] = "Geteilter Bank-Twink: Alle Gegenstände dieses Charakters (Taschen, Bank, Post) werden als für die Gruppe verfügbar angezeigt und können über das Addon angefragt werden.",
    ["Bank"] = "Bank",
    ["Ask %s for %s"] = "%s nach %s fragen",
    ["%s asks %s for %dx %s."] = "%s bittet %s um %dx %s.",
    ["Request"] = "Anfragen",
    ["No items stored yet."] = "Noch keine Gegenstände gelagert.",
    ["Filter items..."] = "Gegenstände filtern...",
    ["Your group's skill levels, synergies, items you can give, and active cooldowns."] = "Berufsstufen der Gruppe, Synergien, abgebbare Gegenstände und aktive Abklingzeiten.",
    ["All materials your group still needs, sorted by urgency. Type to find who can craft something."] = "Alle Materialien, die deine Gruppe noch braucht, nach Dringlichkeit sortiert. Tippe, um Handwerker zu suchen.",
    ["Craftable BiS gear, enchants, consumables, small bags, and patterns to hunt for each member."] = "Herstellbare BiS-Ausrüstung, Verzauberungen, Verbrauchsgüter, kleine Taschen und gesuchte Muster pro Mitglied.",
    ["Green items in your bags: keep for enchants or upgrades, sell on the AH, or disenchant."] = "Grüne Gegenstände in deinen Taschen: behalten für Verzauberungen/Upgrades, im AH verkaufen oder entzaubern.",
    ["Left: Group overview, Materials, Craftable BiS Upgrades, Wishlist, Requests, and every character in your group."] = "Links: Gruppenübersicht, Materialien, herstellbare BiS-Upgrades, Wunschliste, Anfragen und alle Charaktere.",
    ["Bags highlight items your group needs; helper panels dock at Mail, Bank, Trade, Merchant, AH, and Trainers."] = "Taschen markieren Gruppenbedarf; Hilfsfenster docken an Post, Bank, Handel, Händler, AH und Lehrer an.",
    ["Nothing is shared yet. Here, in Manage group, check characters to share (or flag a Shared bank alt), then add friends below. Mutually added peers relay updates automatically."] = "Noch wird nichts geteilt. Markiere hier Charaktere zum Teilen (oder einen Geteilten Bank-Twink) und füge Freunde hinzu. Gegenseitige Kontakte leiten Updates automatisch weiter.",
    ["Reserved %dx %s for %s."] = "%dx %s für %s reserviert.",
    ["Reservation removed for %s."] = "Reservierung für %s entfernt.",
    ["Reserve for..."] = "Reservieren für...",
    ["Unlock reservation"] = "Reservierung aufheben",
    ["Usage: /comrade reserve [Item] Name [qty]"] = "Verwendung: /comrade reserve [Item] Name [Menge]",
    ["Usage: /comrade unreserve [Item]"] = "Verwendung: /comrade unreserve [Item]",
    ["Reserved for %s"] = "Reserviert für %s",
    ["Reserved for %s (x%d) - Alt+Right-click to unlock"] = "Reserviert für %s (x%d) - Alt+Rechtsklick zum Freigeben",
    ["Reserved for you by %s (x%d)"] = "Für dich reserviert von %s (x%d)",
    ["Reserved"] = "Reserviert",
    ["Favorite"] = "Favorit",
    ["Unstar"] = "Entfernen",
    ["Farming for you"] = "Farmt für dich",
    ["Filter characters..."] = "Charaktere filtern...",
    ["by %s (you)"] = "von %s (du)",
    ["crafting"] = "in Arbeit",
    ["shipped"] = "versendet",
    ["Crafting"] = "In Arbeit",
    ["Shipped"] = "Versendet",
    ["Ready to craft"] = "Bereit zum Herstellen",
    ["Ready to ship"] = "Versandbereit",
    ["Missing %s"] = "Fehlt: %s",
    ["Missing %d"] = "Fehlt: %d",
    ["Reserved for you"] = "Für dich reserviert",
    ["Your reserved items"] = "Deine reservierten Gegenstände",
    ["Unlock"] = "Freigeben",
    ["reserved"] = "reserviert",
    ["Click: reserve for %s."] = "Klick: für %s reservieren.",
    ["Click: request from %s [Bank]."] = "Klick: bei %s [Bank] anfragen.",
    ["Favorites"] = "Favoriten",
    ["My characters"] = "Meine Charaktere",
    ["Group members"] = "Gruppenmitglieder",
    ["%d farming"] = "%d beim Farmen",
    ["Auto-marked request %dx %s as shipped."] = "Anfrage %dx %s automatisch als versendet markiert.",
    ["Alt+Right-click any bag item to reserve/lock it for a friend before mailing."] = "Alt+Rechtsklick auf einen Taschengegenstand, um ihn vor dem Versand für einen Freund zu reservieren.",
    ["Item reservations"] = "Gegenstandsreservierungen",
    ["  %s: %d crafts, %d points (expected %.1f)%s"] = "  %s: %d Herstellungen, %d Punkte (erwartet %.1f)%s",
    ["Add friends"] = "Freunde hinzufügen",
    ["All window and tracker positions reset."] = "Alle Fenster- und Tracker-Positionen zurückgesetzt.",
    ["Auction House panel"] = "Auktionshaus-Fenster",
    ["Bank panel"] = "Bank-Fenster",
    ["Browse Can craft"] = "Herstellbar ansehen",
    ["Browse Upgrades"] = "Verbesserungen ansehen",
    ["Companion panels"] = "Begleitfenster",
    ["Configure companion panels, UI scale, sounds, and window positions."] = "Begleitfenster, UI-Skalierung, Töne und Fensterpositionen einstellen.",
    ["Crafts logged by you and your group automatically calibrate skill-up chances for WoW Forever."] = "Von dir und deiner Gruppe erfasste Herstellungen kalibrieren automatisch die Fertigkeits-Chancen für WoW Forever.",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never."] = "Jeder Schritt zeigt, was du beim Lehrer lernst, was zuerst hergestellt wird (Ballen, Barren...) und wie oft. Klick öffnet das Rezept, Umschalt+Klick verlinkt es. Farben: Orange gibt immer einen Punkt, Gelb meist, Grün selten, Grau nie.",
    ["Interface"] = "Oberfläche",
    ["Known recipes. Right-click to pin to Wishlist, or click a friend's recipe to request it."] = "Bekannte Rezepte. Rechtsklick heftet an die Wunschliste an, Klick auf das Rezept eines Freundes fragt es an.",
    ["Learn from a trainer of this profession (requires skill %d, level %d)."] = "Bei einem Lehrer dieses Berufs lernen (erfordert Fertigkeit %d, Stufe %d).",
    ["Left-click: open window  |  Right-click: options"] = "Linksklick: Fenster öffnen  |  Rechtsklick: Optionen",
    ["List my character"] = "Meinen Charakter eintragen",
    ["Mailbox panel"] = "Briefkasten-Fenster",
    ["Merchant panel"] = "Händler-Fenster",
    ["No friends in your group yet. Add guildmates or friends to share mats and upgrades."] = "Noch keine Freunde in deiner Gruppe. Füge Freunde oder Gildenmitglieder hinzu, um Mats und Verbesserungen zu teilen.",
    ["Open ComradeCraft"] = "ComradeCraft öffnen",
    ["Play sound notifications"] = "Tonbenachrichtigungen abspielen",
    ["Reset window positions"] = "Positionen zurücksetzen",
    ["Show minimap button"] = "Minikarten-Symbol anzeigen",
    ["Step-by-step profession leveling route, cost comparison, and trainer guide."] = "Schritt-für-Schritt-Levelroute, Kostenvergleich und Lehrer-Übersicht.",
    ["Sync: %d players in the group, %d suggested."] = "Sync: %d Spieler in der Gruppe, %d vorgeschlagen.",
    ["Toggle ComradeCraft"] = "ComradeCraft umschalten",
    ["Trade panel"] = "Handels-Fenster",
    ["Trainer panel"] = "Lehrer-Fenster",
    ["Window scale"] = "Fensterskalierung",
    ["AH ~%s"] = "AH ~%s",
    ["For"] = "Für",
    ["Important unlearned patterns to buy or farm for yourself and your group (with drop rate and waypoints)."] = "Wichtige ungelernte Muster zum Kaufen oder Farmen für dich und deine Gruppe (mit Droprate und Wegpunkten).",
    ["No unlearned upgrade patterns found for this character right now."] = "Derzeit keine ungelernten Upgrade-Muster für diesen Charakter gefunden.",
    ["Patterns"] = "Muster",
    ["Valuable unlearned patterns for yourself and your group: where to buy or farm them, drop rate when known, and 1-click waypoints."] = "Wichtige ungelernte Muster für dich und deine Gruppe: Kauf-/Farmorte, Droprate wenn bekannt und 1-Klick-Wegpunkte.",
  ["Bargains"] = "Schnäppchen",
  ["Deals"] = "Deals",
  ["Group needs spotted below market price."] = "Gruppenbedarf unter Marktpreis entdeckt.",
  ["Character"] = "Charakter",
  ["Slot"] = "Platz",
  ["Group by:"] = "Gruppieren:",
  ["Enchants"] = "Verzauberungen",
  ["Bags"] = "Taschen",
  ["Claim CD"] = "CD anfragen",
  ["Estimated net profit and 1-click Claim CD for your group's long cooldowns."] = "Geschätzter Nettogewinn und 1-Klick-Anfrage für lange Gruppen-Abklingzeiten.",
  ["Craft chain planned (%d steps for %s)."] = "Herstellungskette geplant (%d Schritte für %s).",
  ["Multi-profession craft chain"] = "Berufsübergreifende Herstellungskette",
  ["Plan chain (%d)"] = "Kette (%d)",
  ["Forever P2P DB: %d recipe bounds, %d vendors, %d drops (from %d peers)."] = "Forever P2P-DB: %d Rezeptgrenzen, %d Händler, %d Drops (von %d Peers).",
  ["In %s (%d finds):"] = "In %s (%d Funde):",
  ["In %s: %s"] = "In %s: %s",
  ["In your zone: %s"] = "In deiner Zone: %s",
  ["Nothing specific for your group found in %s."] = "Nichts Spezielles für deine Gruppe in %s gefunden.",
  ["Rare drops, vendors, patterns and materials useful to your group right here."] = "Seltene Drops, Händler, Muster und Materialien für deine Gruppe genau hier.",
  ["world drop"] = "Weltdrop",
  ["world drop - here (%s)"] = "Weltdrop - hier (%s)",
  ["world drop - near %s"] = "Weltdrop - nahe %s",
  ["%d bounds  |  %d custom recipes  |  %d disenchants  |  %d vendors  |  %d drops  (%d peers)"] = "%d Schwellen  |  %d eigene Rezepte  |  %d Entzauberungen  |  %d Händler  |  %d Drops  (%d Kontakte)",
  ["%d in transit"] = "%d unterwegs",
  ["Accepted craft requests & pinned wishlist for this profession."] = "Angenommene Anfragen und angeheftete Wunschliste für diesen Beruf.",
  ["Already mailed between group accounts — counted as on the way so nobody double-sends."] = "Bereits zwischen Gruppenkonten verschickt — als unterwegs gezählt gegen Doppelversand.",
  ["Applied craft kit \"%s\" (x%d)."] = "Craft-Set \"%s\" angewendet (x%d).",
  ["Apply x1"] = "Anwenden x1",
  ["Apply x5"] = "Anwenden x5",
  ["Click to open recipe (trade slot 7)"] = "Klick: Rezept öffnen (Handelsplatz 7)",
  ["Click to open this enchant for the trade slot."] = "Klicke, um diese Verzauberung für das Handelsfenster zu öffnen.",
  ["Craft kits"] = "Craft-Sets",
  ["Craft request (%s)"] = "Herstellungsanfrage (%s)",
  ["Deliver to %s"] = "Liefern an %s",
  ["Enchant auto-completes request on trade"] = "Verzauberung schließt Anfrage beim Handel ab",
  ["Forever P2P database"] = "Forever P2P-Datenbank",
  ["In group stock: \"%s\""] = "Im Gruppenvorrat: \"%s\"",
  ["In transit"] = "Unterwegs",
  ["In transit (1h mail)"] = "Unterwegs (1 Std. Post)",
  ["Next: %s (%d left)"] = "Nächster: %s (%d übrig)",
  ["Observed WoW Forever recipe bounds, custom recipes, disenchants, vendors and drops shared automatically."] = "Beobachtete Forever-Rezeptschwellen, eigene Rezepte, Entzauberungen, Händler und Drops automatisch geteilt.",
  ["Orders (%d)"] = "Aufträge (%d)",
  ["Reserved by %s"] = "Reserviert von %s",
  ["Reusable craft bundles (raid, dungeon, reroll) — apply in 1 click."] = "Wiederverwendbare Craft-Pakete (Raid, Dungeon, Twink) — mit 1 Klick anwenden.",
  ["Save as kit"] = "Als Set sichern",
  ["Save current wishlist as a reusable kit"] = "Aktuelle Wunschliste als wiederverwendbares Set speichern",
  ["Save kit"] = "Set sichern",
  ["Saved craft kit \"%s\" (%d recipes)."] = "Craft-Set \"%s\" gespeichert (%d Rezepte).",
  ["Sent %d/%d"] = "Gesendet %d/%d",
  ["Sent %d/%d %s."] = "%d/%d %s gesendet.",
  ["Share now"] = "Jetzt teilen",
  ["Step %d/%d"] = "Schritt %d/%d",
  ["Waiting previous step"] = "Wartet auf vorherigen Schritt",
  ["Wishlist completed: %s"] = "Wunschliste abgeschlossen: %s",
  ["measured"] = "gemessen",
    -- Target skill (Plan tab)
    ["auction house"] = "Auktionshaus",
    ["Queued %dx %s: open the profession window and click Craft next."] = "%dx %s eingereiht: öffne das Berufsfenster und klicke auf Nächstes herstellen.",
    ["Restock: %s"] = "Auffüllen: %s",
    ["Restock"] = "Auffüllen",
    ["Queue"] = "Einreihen",
    ["No risk: sell to a merchant"] = "Ohne Risiko: an einen Händler verkaufen",
    ["net %s per craft at a merchant"] = "netto %s pro Herstellung beim Händler",
    ["Auctionator shopping list ready: %s (%d items)."] = "Auctionator-Einkaufsliste bereit: %s (%d Gegenstände).",
    ["once per cooldown"] = "einmal pro Abklingzeit",
    ["Cooldown goldmakers"] = "Goldbringer mit Abklingzeit",
    ["ready in %s"] = "bereit in %s",
    ["Goldmaking"] = "Goldverdienen",
    ["net %s per craft"] = "netto %s pro Herstellung",
    ["~%d sold per day"] = "~%d verkauft pro Tag",
    ["~%s per day"] = "~%s pro Tag",
    ["sales volume unknown"] = "Verkaufsmenge unbekannt",
    ["craft the %s yourself"] = "stelle %s selbst her",
    ["craft the %s yourself (recipe to learn)"] = "stelle %s selbst her (Rezept lernen)",
    ["Crafts that earn the most at the auction house, at the pace it buys them (mats bought or crafted, whichever is cheaper; after the cut and deposit)."] = "Herstellungen, die im Auktionshaus am meisten bringen, in dem Tempo, in dem es sie kauft (Materialien gekauft oder hergestellt, je nachdem was günstiger ist; nach Gebühr und Anzahlung).",
    ["No auction prices yet: scan the auction house or install TSM or Auctionator."] = "Noch keine Auktionspreise: scanne das Auktionshaus oder installiere TSM oder Auctionator.",
    ["stackable"] = "stapelbar",
    ["one by one"] = "einzeln",
    ["Repeat goldmakers"] = "Wiederholbare Goldbringer",
    ["No known recipe makes money at current prices."] = "Kein bekanntes Rezept bringt bei aktuellen Preisen Gewinn.",
    ["Recipes worth buying"] = "Rezepte, die sich lohnen",
    ["recipe %s, paid back in %d crafts"] = "Rezept %s, nach %d Herstellungen bezahlt",
    ["What if I learned:"] = "Was, wenn ich lerne:",
    ["Alternative: %s from the quest %s would save about %s."] = "Alternative: %s aus der Quest %s würde etwa %s sparen.",
    ["Get a %s"] = "Besorge: %s",
    ["Craft it first: %s."] = "Stelle es zuerst her: %s.",
    ["Sold by trade supplies vendors (%s)."] = "Bei Handwerkswarenhändlern erhältlich (%s).",
    ["Sold by trade supplies vendors."] = "Bei Handwerkswarenhändlern erhältlich.",
    ["Craft at: %s"] = "Herstellen an: %s",
    ["Nearest: %s"] = "Am nächsten: %s",
    ["Location not known yet: saved the first time someone crafts there."] = "Ort noch unbekannt: wird gespeichert, sobald jemand dort herstellt.",
    ["Anvil"] = "Amboss",
    ["Forge"] = "Schmiede",
    ["Loom"] = "Webstuhl",
    ["Cooking Fire"] = "Kochfeuer",
    ["Tanning Rack"] = "Gerbgestell",
    ["Spinning Wheel"] = "Spinnrad",
    ["Sewing Machine"] = "Nähmaschine",
    ["Master Forge"] = "Meisterschmiede",
    ["Alchemy Lab"] = "Alchemielabor",
    ["Iron Oven"] = "Eisenofen",
    ["Fermenter"] = "Gärbottich",
    ["Black Anvil"] = "Schwarzer Amboss",
    ["Black Forge"] = "Schwarze Schmiede",
    ["With your budget you can reach %d (target %d)."] = "Mit deinem Budget erreichst du %d (Ziel %d).",
    ["Filtered by the budget: the greyed steps need about %s more."] = "Nach Budget gefiltert: die ausgegrauten Schritte brauchen etwa %s mehr.",
    ["Remove budget"] = "Budget entfernen",
    ["Budget (g):"] = "Budget (G):",
    ["Budget"] = "Budget",
    ["Gold you put into leveling, Enter to apply; empty = no limit. Sales of earlier crafts are reinvested."] = "Gold, das du ins Leveln steckst, Enter zum Übernehmen; leer = kein Limit. Verkäufe früherer Herstellungen werden reinvestiert.",
    ["Enter to apply"] = "Enter zum Übernehmen",
    ["no limit - type gold, Enter to apply"] = "kein Limit - Gold eingeben, Enter zum Übernehmen",
    ["Gold needed at the worst moment: %s (sales of earlier crafts reinvested)."] = "Gold im ungünstigsten Moment nötig: %s (Verkäufe früherer Herstellungen reinvestiert).",
    ["Sell the crafts:"] = "Was tun mit den Herstellungen:",
    ["%s: %s"] = "%s: %s",
    ["%d at the AH"] = "%d im AH",
    ["disenchant %d with %s"] = "%d mit %s entzaubern",
    ["%d to a merchant"] = "%d beim Händler",
    ["Buy %s at the auction house (skill %s, %s)"] = "%s im Auktionshaus kaufen (Fertigkeit %s, %s)",
    ["Auction house - skill %s - %s"] = "Auktionshaus - Fertigkeit %s - %s",
    ["Buy recipe: %s"] = "Rezept kaufen: %s",
    ["Buy %s from %s (skill %s, %s)"] = "%s bei %s kaufen (Fertigkeit %s, %s)",
    ["Vendor: %s - skill %s - %s"] = "Händler: %s - Fertigkeit %s - %s",
    ["price unknown until you visit the vendor"] = "Preis unbekannt, bis du den Händler besuchst",
    ["a vendor"] = "einem Händler",
    ["Trainer & recipes"] = "Lehrer & Rezepte",
    ["+ Trainer & recipes: %s (in the net). To buy = missing mats (AH + merchant); net = to buy - resale + trainer & recipes."] = "+ Lehrer & Rezepte: %s (im Netto). Zu kaufen = fehlende Mats (AH + Händler); netto = zu kaufen - Wiederverkauf + Lehrer & Rezepte.",
    ["(your side only)"] = "(nur bei dir)",
    ["Target:"] = "Ziel:",
    ["Target skill"] = "Zielfertigkeit",
    ["Type a skill (up to 300) and press Enter. Mouse wheel: +/-5 (Shift: 25)."] = "Fertigkeit eingeben (max. 300) und Enter drücken. Mausrad: +/-5 (Umschalt: 25).",
    ["(cap) - click to change, Enter to apply"] = "(Max.) - klicken zum Ändern, Enter zum Übernehmen",
    ["click to change, Enter to apply"] = "klicken zum Ändern, Enter zum Übernehmen",
    ["Target %d"] = "Ziel %d",
    ["Cap"] = "Max.",
    ["Level %d needed to learn this rank (now %d)."] = "Stufe %d nötig, um diesen Rang zu lernen (jetzt %d).",
    ["Total %d to %d (%s prices)"] = "Gesamt %d bis %d (%s-Preise)",
    ["Total %d to %d: gross %s, to buy %s, resale %s, trainer %s, net %s (%s prices)."] = "Gesamt %d bis %d: brutto %s, zu kaufen %s, Wiederverkauf %s, Lehrer %s, netto %s (%s-Preise).",
    ["Gross"] = "Brutto",
    ["To buy"] = "Zu kaufen",
    ["Resale"] = "Wiederverkauf",
    ["Net"] = "Netto",
    ["not counted"] = "nicht gezählt",
    ["Stops at"] = "Endet bei",
    ["Other route: trainer not counted."] = "Andere Route: Lehrer nicht gezählt.",
    ["> = some prices are unknown: a cost is a minimum, a profit (+<) a maximum."] = "> = manche Preise sind unbekannt: Kosten sind ein Minimum, ein Gewinn (+<) ein Maximum.",
}
