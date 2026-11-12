-- itIT translations. Keys: the English text (see Locale.lua); loaded only on a itIT client.
local _, ns = ...
local loc = GetLocale and GetLocale()
if loc ~= "itIT" then return end
ns.Translations = ns.Translations or {}
ns.Translations[loc] = {
    -- Core
    ["commands: /comrade (window) | share [off] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"] =
      "comandi: /comrade (finestra) | share [off] | add NOME | remove NOME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NOME | scan | needs | stats | api | audit | log clear",
    ["log cleared"] = "log svuotato",
    ["%d lines in the log (written to disk on /reload or logout)"] =
      "%d righe nel log (scritto su disco al /reload o al logout)",
    -- Scan
    ["scan ok: %d distinct items in bags"] = "scansione ok: %d oggetti distinti nelle borse",
    ["DevTools_Dump missing; see WTF\\...\\SavedVariables\\ComradeCraft.lua after /reload"] =
      "DevTools_Dump assente; vedi WTF\\...\\SavedVariables\\ComradeCraft.lua dopo /reload",
    ["audit: C_TradeSkillUI.GetAllRecipeIDs missing on this client"] =
      "audit: C_TradeSkillUI.GetAllRecipeIDs assente su questo client",
    ["audit: open a profession window first"] = "audit: apri prima una finestra di professione",
    ["  %s (%d): game=%s table=%s [%d/%d]"] = "  %s (%d): gioco=%s tabella=%s [%d/%d]",
    ["audit rank %d: %d ok, %d mismatches, %d missing from the table"] =
      "audit grado %d: %d ok, %d discordanze, %d assenti dalla tabella",
    ["LibProfessionDB: %d ok, %d mismatches"] = "LibProfessionDB: %d ok, %d discordanze",
    ["maxTrivialLevel == grey: %d yes, %d no"] = "maxTrivialLevel == grigio: %d sì, %d no",
    ["yes"] = "sì",
    ["no"] = "no",
    -- SkillLog
    ["%d crafts recorded (calibration from %d per color)"] =
      "%d creazioni registrate (calibrazione da %d per colore)",
    ["orange"] = "arancione",
    ["yellow"] = "giallo",
    ["green"] = "verde",
    ["grey"] = "grigio",
    ["  %s: %d crafts, %d points, Classic formula %.1f%s"] =
      "  %s: %d creazioni, %d punti, formula Classic %.1f%s",
    [" -> factor %.2f applied"] = " -> fattore %.2f applicato",
    ["  game color known on %d crafts: our table %d right, LibProfessionDB %d right"] =
      "  colore del gioco noto su %d creazioni: la nostra tabella %d giuste, LibProfessionDB %d giuste",
    -- Tooltip / needs text
    ["needs %d"] = "serve %d",
    ["Group total"] = "Totale del gruppo",
    ["Spare in the group"] = "Avanzo nel gruppo",
    ["You can give"] = "Puoi dare",
    ["Spare items in your bags that others need. With a mailbox open, click one to prepare the mail."] =
      "Oggetti in avanzo nelle tue borse che servono ad altri. Con una cassetta della posta aperta, clicca per preparare la posta.",
    ["Mail full (%d attachments): send it, then click again for the rest."] =
      "Posta piena (%d allegati): invia, poi clicca di nuovo per il resto.",
    ["Open a mailbox first."] = "Apri prima una cassetta della posta.",
    ["Nothing to give to %s."] = "Niente da dare a %s.",
    ["Attach what they need"] = "Allega ciò che serve",
    ["Type the name of a group member."] = "Scrivi il nome di un membro del gruppo.",
    ["You need"] = "Ti serve",
    ["Disenchant or keep?"] = "Disincantare o tenere?",
    ["Green and better items in your bags. Yields are estimates until your disenchants are logged."] =
      "Oggetti verdi o migliori nelle tue borse. Le rese sono stime finché i tuoi disincantamenti non sono registrati.",
    ["Keep: enchanting target (%s)"] = "Tieni: obiettivo di incantamento (%s)",
    ["Keep: gear for %s"] = "Tieni: equipaggiamento per %s",
    ["Sell: AH %s vs disenchant %s"] = "Vendi: CdA %s contro disincantamento %s",
    ["Disenchant: %s"] = "Disincanta: %s",
    ["the group needs these"] = "servono al gruppo",
    ["give to %s"] = "dai a %s",
    ["group: %d"] = "gruppo: %d",
    ["now"] = "ora",
    ["soon"] = "presto",
    ["later"] = "più tardi",
    ["trainer"] = "istruttore",
    ["vendor"] = "venditore",
    ["quest"] = "missione",
    ["drop"] = "bottino",
    ["container"] = "contenitore",
    ["Gathering profession: levels by gathering, not crafting."] =
      "Professione di raccolta: si sale raccogliendo, non creando.",
    ["Open this profession's window once so your recipes can be read."] =
      "Apri una volta la finestra di questa professione per leggere le tue ricette.",
    ["No data."] = "Nessun dato.",
    ["Learn %s at the trainer (skill %s, %s)"] = "Impara %s dall'istruttore (abilità %s, %s)",
    ["cost unknown until you visit the trainer"] = "costo ignoto finché non visiti l'istruttore",
    ["Craft %d %s (%s)"] = "Crea %d %s (%s)",
    ["Craft %dx %s (%s)"] = "Crea %dx %s (%s)",
    ["%d %s (vendor)"] = "%d %s (mercante)",
    ["Estimated cost: %s (%s prices)."] = "Costo stimato: %s (prezzi %s).",
    ["Estimated cost: at least %s (%s prices, some items have no price)."] =
      "Costo stimato: almeno %s (prezzi %s, alcuni oggetti senza prezzo).",
    [" + %d from stock"] = " + %d già in magazzino",
    ["%d %s from stock"] = "%d %s già in magazzino",
    ["With only your current recipes, you would be stuck at %d."] =
      "Con le sole ricette attuali, ti fermeresti a %d.",
    ["Uses what you already have: %s."] = "Usa ciò che hai già: %s.",
    ["Buy from a vendor: %s."] = "Da comprare da un mercante: %s.",
    ["Stuck at %d: all your known recipes are grey (no more points)."] =
      "Fermo a %d: tutte le ricette che conosci sono grigie (niente più punti).",
    ["Stuck at %d: your known recipes barely give points anymore (%d%% chance per craft at best, %d%% needed)."] =
      "Fermo a %d: le ricette che conosci danno quasi più punti (%d%% di probabilità per creazione al massimo, ne serve il %d%%).",
    [" To learn: %s."] = " Da imparare: %s.",
    [" No recipe to learn found within the next 25 points."] =
      " Nessuna ricetta da imparare nei prossimi 25 punti.",
    ["  missing %s x%d"] = "  manca %s x%d",
    -- UI
    ["just now"] = "proprio ora",
    ["%d min ago"] = "%d min fa",
    ["%d h ago"] = "%d h fa",
    ["What to craft:"] = "Cosa creare:",
    ["Owned: %d / %d"] = "Posseduti: %d / %d",
    ["%d profession"] = "%d professione",
    ["%d professions"] = "%d professioni",
    ["%d member"] = "%d membro",
    ["%d members"] = "%d membri",
    ["Group"] = "Gruppo",
    ["Plan"] = "Piano",
    ["Can craft"] = "Può creare",
    ["Lvl %d"] = "Liv. %d",
    ["updated %s"] = "aggiornato %s",
    ["Skill levels and the materials the group still needs. Type to find who can craft something."] =
      "Livelli di abilità e materiali che mancano ancora al gruppo. Scrivi per trovare chi può creare qualcosa.",
    ["Skill levels"] = "Livelli di abilità",
    ["Most wanted materials"] = "Materiali più richiesti",
    ["Nothing missing yet."] = "Per ora non manca nulla.",
    ["Who can craft \"%s\""] = "Chi può creare \"%s\"",
    ["No recipe matches."] = "Nessuna ricetta corrisponde.",
    ["No profession data. Open your profession windows."] =
      "Nessun dato di professione. Apri le finestre delle tue professioni.",
    ["%d recipe"] = "%d ricetta",
    ["%d recipes"] = "%d ricette",
    ["gear for %s"] = "equipaggiamento per %s",
    ["upgrade for %s (+%d)"] = "miglioria per %s (+%d)",
    ["Enchant"] = "Incantamento",
    ["Consumable"] = "Consumabile",
    ["Bag"] = "Borsa",
    ["Weapon"] = "Arma",
    ["Armor"] = "Armatura",
    ["Reagent"] = "Reagente",
    ["Other"] = "Altro",
    ["Sync: %d players in the group, %d suggested. skill ~N: value taken from Classic, unconfirmed."] =
      "Sync: %d giocatori nel gruppo, %d suggeriti. abilità ~N: valore ripreso da Classic, non confermato.",
    ["via %s"] = "via %s",
    ["Manage group"] = "Gestisci gruppo",
    ["Choose what you share, and with whom."] = "Scegli cosa condividi e con chi.",
    ["%d player"] = "%d giocatore",
    ["%d players"] = "%d giocatori",
    ["%d request"] = "%d richiesta",
    ["%d requests"] = "%d richieste",
    ["Your characters"] = "I tuoi personaggi",
    ["Only checked characters are shared, and only with the players in your group."] =
      "Solo i personaggi spuntati vengono condivisi, e solo con i giocatori del tuo gruppo.",
    ["Players in your group"] = "Giocatori del tuo gruppo",
    ["They receive your shared characters and you see theirs."] =
      "Ricevono i tuoi personaggi condivisi e tu vedi i loro.",
    ["Nobody yet."] = "Nessuno per ora.",
    ["seen %s"] = "visto %s",
    ["Remove"] = "Rimuovi",
    ["Requests and suggestions"] = "Richieste e suggerimenti",
    ["Players with ComradeCraft in your guild, or who added you. Add them to share both ways."] =
      "Giocatori della tua gilda con ComradeCraft, o che ti hanno aggiunto. Aggiungili per condividere in entrambe le direzioni.",
    ["Add"] = "Aggiungi",
    ["Add a player by name"] = "Aggiungi un giocatore per nome",
    ["For friends outside your guild. They must add you back."] =
      "Per gli amici fuori dalla gilda. Devono aggiungerti a loro volta.",
    ["Options"] = "Opzioni",
    ["Send a presence signal to the guild at login (no character data)."] =
      "Invia un segnale di presenza alla gilda all'accesso (nessun dato del personaggio).",
    ["All"] = "Tutte",
    ["Hide gathering"] = "Nascondi raccolta",
    ["No profession matches the filter."] = "Nessuna professione corrisponde al filtro.",
    ["%d character"] = "%d personaggio",
    ["%d characters"] = "%d personaggi",
    ["Remove from group"] = "Rimuovi dal gruppo",
    -- Sync
    ["sync: sent to the players in your group"] = "sync: inviato ai giocatori del tuo gruppo",
    ["%s is shared with your group"] = "%s è condiviso con il tuo gruppo",
    ["%s is no longer shared"] = "%s non è più condiviso",
    ["guild presence signal: on"] = "segnale di presenza alla gilda: attivo",
    ["guild presence signal: off"] = "segnale di presenza alla gilda: disattivo",
    ["Share this character with the group"] = "Condividi questo personaggio con il gruppo",
    ["not shared"] = "non condiviso",
    ["  %s: %d characters, %s"] = "  %s: %d personaggi, %s",
    ["in the group"] = "nel gruppo",
    ["wants to join"] = "vuole unirsi",
    ["suggested"] = "suggerito",
    ["no peer seen yet (they need ComradeCraft)"] = "nessun giocatore visto finora (serve ComradeCraft)",
    ["%s added to the group"] = "%s aggiunto al gruppo",
    ["%s contacted; added as soon as they answer"] = "%s contattato; aggiunto appena risponde",
    ["%s removed from the group"] = "%s rimosso dal gruppo",
    -- Shopping, Tracker
    ["Could not create the Auctionator list (see /comrade log)."] =
      "Impossibile creare la lista Auctionator (vedi /comrade log).",
    ["Nothing to buy for %s."] =
      "Niente da comprare per %s.",
    ["Auctionator list \"ComradeCraft: %s\" created: %d items. Open the Shopping tab at the auction house."] =
      "Lista Auctionator \"ComradeCraft: %s\" creata: %d oggetti. Apri la scheda Shopping alla Casa d'Aste.",
    ["%d not cached yet; try again in a moment."] =
      "%d non ancora in cache; riprova tra un attimo.",
    ["Nothing to buy."] =
      "Niente da comprare.",
    ["Step panel hidden. /comrade tracker shows it again."] =
      "Pannello dei passi nascosto. /comrade tracker lo mostra di nuovo.",
    ["TSM shopping (Ctrl+C to copy)"] = "Acquisti TSM (Ctrl+C per copiare)",
    ["Search: paste in the search box of TSM's Shopping tab."] =
      "Ricerca: incolla nella casella di ricerca della scheda Shopping di TSM.",
    ["Group: TSM, Groups, Import. Quantities are in the search above (recomputed on each click)."] =
      "Gruppo: TSM, Groups, Import. Le quantità sono nella ricerca qui sopra (ricalcolata a ogni clic).",
    ["TSM group \"%s\": everything bought, delete it in TSM (Groups, right-click)."] =
      "Gruppo TSM \"%s\": tutto comprato, eliminalo in TSM (Groups, clic destro).",
    ["TSM group \"%s\": replaced by a newer one, delete it in TSM (Groups, right-click)."] =
      "Gruppo TSM \"%s\": sostituito da uno più recente, eliminalo in TSM (Groups, clic destro).",
    ["Send now"] = "Invia ora",
    ["Show the step panel next to the profession window."] =
      "Mostra il pannello dei passi accanto alla finestra di professione.",
    ["Re-dock"] = "Riaggancia",
    ["Measured skill-up chances"] = "Probabilità di aumento abilità misurate",
    ["Crafts logged by you and your group correct the Classic formula once a color has enough of them."] =
      "Le creazioni registrate da te e dal tuo gruppo correggono la formula Classic quando un colore ne ha abbastanza.",
    ["The window"] =
      "La finestra",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "A sinistra: il gruppo, poi ogni personaggio. Piano = come salire in una professione; Può creare = cosa può fare quel personaggio per il gruppo. I chip filtrano per professione.",
    ["Plans"] =
      "Piani",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never. ~ marks a value taken from Classic."] =
      "Ogni passo dice cosa imparare dall'istruttore, cosa creare per primo (bulloni, barre...) e quanti. Clicca una riga per aprire la ricetta, Maiusc+clic per linkarla. Colori: arancione dà sempre un punto, giallo di solito, verde raramente, grigio mai. ~ indica un valore ripreso da Classic.",
    ["Tooltips"] =
      "Descrizioni",
    ["On any material: who in the group needs it, how many, and how soon (now, soon, later). Spare stock in the group is shown too."] =
      "Su ogni materiale: chi nel gruppo ne ha bisogno, quanti, e quanto presto (ora, presto, più tardi). Viene mostrato anche l'avanzo del gruppo.",
    ["Step panel"] =
      "Pannello dei passi",
    ["Next to your profession window: the current step, the chance per craft, how many crafts your bags allow, and what comes next."] =
      "Accanto alla finestra di professione: il passo attuale, la probabilità per creazione, quante creazioni permettono le tue borse, e cosa viene dopo.",
    ["Giving and mail"] =
      "Dare e posta",
    ["You can give lists what you hold that others need. At a mailbox, the button beside the send frame attaches it. Nothing is ever sent for you."] =
      "«Puoi dare» elenca ciò che hai e che serve ad altri. Alla cassetta della posta, il pulsante accanto al riquadro d'invio lo allega. Nulla viene mai inviato al posto tuo.",
    ["Disenchant or keep"] =
      "Disincantare o tenere",
    ["Your green items: keep one per slot your enchanting plan needs, keep upgrades for group members, sell what is worth more than its mats, disenchant the rest."] =
      "I tuoi oggetti verdi: tieni uno per slot che serve al tuo piano di incantamento, tieni le migliorie per il gruppo, vendi ciò che vale più dei suoi materiali, disincanta il resto.",
    ["Shopping"] =
      "Acquisti",
    ["The Shopping list button makes an Auctionator list, or a TSM search and group to paste. TSM groups that are done are pointed out."] =
      "Il pulsante Lista della spesa crea una lista Auctionator, o una ricerca e un gruppo TSM da incollare. I gruppi TSM completati vengono segnalati.",
    ["Sharing"] =
      "Condivisione",
    ["Nothing is shared until you check a character in Manage group, and only with players you added who added you back."] =
      "Nulla viene condiviso finché non spunti un personaggio in Gestisci gruppo, e solo con i giocatori che hai aggiunto e che ti hanno aggiunto a loro volta.",
    ["Better with"] =
      "Ancora meglio con",
    ["Replay the tour"] =
      "Rivedi il tour",
    ["Welcome to ComradeCraft"] =
      "Benvenuto in ComradeCraft",
    ["It answers one question: what should I do with what I have, for the group? 30 seconds to see the main parts."] =
      "Risponde a una domanda: cosa posso fare con ciò che ho, per il gruppo? 30 secondi per vedere le parti principali.",
    ["Your group"] =
      "Il tuo gruppo",
    ["Left: the group overview, the group management, then every character you share or receive."] =
      "A sinistra: la panoramica del gruppo, la gestione del gruppo, poi ogni personaggio che condividi o ricevi.",
    ["Plan and Can craft"] =
      "Piano e Può creare",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Scegli un personaggio: Piano mostra come salire in ogni professione passo dopo passo; Può creare mostra cosa può fare per gli altri.",
    ["While you play"] =
      "Mentre giochi",
    ["Item tooltips show who needs a material. A step panel opens next to your profession window."] =
      "Le descrizioni degli oggetti mostrano a chi serve un materiale. Un pannello dei passi si apre accanto alla finestra di professione.",
    ["Sharing is off until you check a box"] = "La condivisione è disattivata finché non spunti una casella",
    ["Nothing is shared yet. Here, in Manage group, check the box next to each character you want to share under Your characters (on the left of this card). Unchecked characters never leave your computer. Then add your friends below, or accept guildmates who appear there. The ? button explains the rest."] =
      "Per ora nulla è condiviso. Qui, in Gestisci gruppo, spunta la casella accanto a ogni personaggio da condividere sotto I tuoi personaggi (a sinistra di questa scheda). I personaggi non spuntati non lasciano mai il tuo computer. Poi aggiungi i tuoi amici qui sotto, o accetta i compagni di gilda che compaiono lì. Il pulsante ? spiega il resto.",
    ["Do not show again"] =
      "Non mostrare più",
    ["Skip"] =
      "Salta",
    ["Done"] =
      "Fatto",
    ["Next"] =
      "Avanti",
    ["Help"] =
      "Aiuto",
    ["How ComradeCraft works, in short."] =
      "Come funziona ComradeCraft, in breve.",
    ["Cheapest"] =
      "Più economica",
    ["Profitable"] =
      "Redditizia",
    ["Route:"] =
      "Percorso:",
    ["Picks recipes whose products sell back well. More crafts, so more mats: tooltips, the give list, mail and shopping all follow this route."] =
      "Sceglie le ricette i cui prodotti si rivendono bene. Più creazioni, quindi più materiali: descrizioni, lista Puoi dare, posta e acquisti seguono questo percorso.",
    ["Chosen by its owner."] = "Scelto dal proprietario.",
    ["Spends the least on mats."] =
      "Spende il meno possibile in materiali.",
    ["Where to get it: unknown."] =
      "Dove ottenerlo: sconosciuto.",
    ["Where to get it:"] =
      "Dove ottenerlo:",
    ["and %d more"] =
      "e altri %d",
    ["Sources taken from another game version, unconfirmed on Forever."] =
      "Fonti riprese da un'altra versione del gioco, non confermate su Forever.",
    ["Install Questie for locations; TomTom for waypoints."] =
      "Installa Questie per le posizioni, TomTom per i waypoint.",
    ["Click: waypoint to the nearest one."] =
      "Clic: waypoint verso il più vicino.",
    ["No known location for %s."] =
      "Nessuna posizione nota per %s.",
    ["%s: %s. Install TomTom for a waypoint."] =
      "%s: %s. Installa TomTom per un waypoint.",
    ["Waypoint: %s"] =
      "Waypoint: %s",
    ["Mats per craft:"] = "Materiali per creazione:",
    ["+%d more"] = "+%d altri",
    ["Recipe and mats"] = "Ricetta e materiali",
    ["For the group"] = "Per il gruppo",
    ["Type"] = "Tipo",
    ["Mats cost"] = "Costo materiali",
    ["At the trainer - skill %s - %s"] =
      "Dall'istruttore - abilità %s - %s",
    ["already in your bags"] =
      "già nelle tue borse",
    ["Cost by milestone (%s prices)"] =
      "Costo per tappa (prezzi %s)",
    ["Cost by milestone (merchant prices; TSM or Auctionator give AH prices)"] =
      "Costo per tappa (prezzi del mercante; TSM o Auctionator danno i prezzi della CdA)",
    ["Skill %d to %d"] =
      "Abilità da %d a %d",
    ["Learn %s"] =
      "Impara %s",
    ["Skill"] =
      "Tappa",
    ["Route"] =
      "Percorso",
    ["Mats"] =
      "Materiali",
    ["Sold back"] =
      "Rivenduto",
    ["Net cost"] =
      "Costo netto",
    ["nothing"] =
      "niente",
    ["unknown"] =
      "ignoto",
    ["Sold to a merchant"] =
      "Venduto al mercante",
    ["Disenchanted"] =
      "Disincantato",
    ["At the auction house (-5%, deposit risk)"] =
      "Alla Casa d'Aste (-5%, rischio deposito)",
    ["Best way per item"] =
      "Migliore opzione per oggetto",
    ["Net cost = mats minus the best resale of each item. A green + is a profit. Hover a line for the details."] =
      "Costo netto = materiali meno la migliore rivendita di ogni oggetto. Un + verde è un guadagno. Passa il mouse su una riga per i dettagli.",
    ["Next: %s"] = "Poi: %s",
    ["Click to expand."] = "Clicca per espandere.",
    ["Could not start the craft (see /comrade log)."] =
      "Impossibile avviare la creazione (vedi /comrade log).",
    ["Queue:"] =
      "Coda:",
    ["up to skill %d (click: this step only)"] =
      "fino ad abilità %d (clic: solo questo passo)",
    ["this step (click: up to the milestone)"] =
      "questo passo (clic: fino alla tappa)",
    ["by hand (needs a target)"] =
      "a mano (serve un bersaglio)",
    ["ready"] =
      "pronto",
    ["%d ready"] =
      "%d pronti",
    ["Craft next: %dx %s"] =
      "Crea il prossimo: %dx %s",
    ["Learn %s first"] =
      "Impara prima %s",
    ["Missing mats for the queue"] =
      "Mancano materiali per la coda",
    ["Nothing to craft"] =
      "Niente da creare",
    ["%s asks %s to craft %dx %s."] =
      "%s chiede a %s di creare %dx %s.",
    ["Request %dx %s: %s."] =
      "Richiesta %dx %s: %s.",
    ["Request sent to %s. It is delivered as soon as you are both online."] =
      "Richiesta inviata a %s. Viene consegnata appena siete entrambi online.",
    ["Quantity"] =
      "Quantità",
    ["Note (optional)"] =
      "Nota (facoltativa)",
    ["Send request"] =
      "Invia richiesta",
    ["Ask %s to craft %s"] =
      "Chiedi a %s di creare %s",
    ["Craft requests"] =
      "Richieste di creazione",
    ["%d to answer"] =
      "%d da rispondere",
    ["none open"] =
      "nessuna aperta",
    ["Ask a group member to craft something, or answer what they asked you."] =
      "Chiedi a un membro del gruppo di creare qualcosa, o rispondi a ciò che ti hanno chiesto.",
    ["Click: ask %s to craft it."] =
      "Clic: chiedi a %s di crearlo.",
    ["%s for %s"] =
      "%s per %s",
    ["asked to %s"] =
      "chiesto a %s",
    ["waiting to reach the other player"] =
      "in attesa dell'altro giocatore",
    ["Mats: %s"] =
      "Materiali: %s",
    ["your bags allow %d"] =
      "le tue borse ne permettono %d",
    ["Accept"] =
      "Accetta",
    ["Decline"] =
      "Rifiuta",
    ["Cancel request"] =
      "Annulla",
    ["For your characters"] =
      "Per i tuoi personaggi",
    ["Your requests"] =
      "Le tue richieste",
    ["Accept, craft, then mark it done; the mail helper attaches the item when you write to them."] =
      "Accetta, crea, poi segna come fatto; l'assistente posta allega l'oggetto quando gli scrivi.",
    ["Click a recipe in a group member's Can craft tab to ask for it. Delivered the next time you are both online."] =
      "Clicca una ricetta nella scheda Può creare di un membro per richiederla. Consegnata la prossima volta che siete online insieme.",
    ["pending"] =
      "in attesa",
    ["accepted"] =
      "accettata",
    ["declined"] =
      "rifiutata",
    ["done"] =
      "completata",
    ["cancelled"] =
      "annullata",
    ["(by mail)"] =
      "(per posta)",
    ["Request mail ready: check it and click Send."] =
      "Posta della richiesta pronta: controllala e clicca Invia.",
    ["By mail"] =
      "Per posta",
    ["Craft requests by mail too: for players who are never online at the same time (you send the mail yourself, 30c postage)."] =
      "Richieste di creazione anche per posta: per i giocatori mai online insieme (invii tu la posta, 30c di spedizione).",
    ["other profession"] = "altra professione",
    ["Routes"] =
      "Percorsi",
    ["Each character picks Cheapest (least spent on mats) or Profitable (products sold back). The milestone table compares both: mats, what the products bring back (merchant, disenchant or AH) and the net cost."] =
      "Ogni personaggio sceglie Più economica (meno spesa in materiali) o Redditizia (prodotti rivenduti). La tabella delle tappe confronta entrambe: materiali, ricavo dei prodotti (mercante, disincanto o CdA) e costo netto.",
    ["Learning recipes"] =
      "Imparare le ricette",
    ["Hover a Learn line for its trainers, vendors and drops; click it for a TomTom waypoint (with Questie installed for positions)."] =
      "Passa il mouse su una riga Impara per istruttori, mercanti e bottini; cliccala per un waypoint TomTom (con Questie installato per le posizioni).",
    ["Craft queue"] =
      "Coda di creazione",
    ["In the step panel: the crafts of this step or of the whole milestone, what your bags allow, and Craft next (one batch per click, the game needs a click per craft)."] =
      "Nel pannello dei passi: le creazioni di questo passo o dell'intera tappa, ciò che permettono le tue borse, e Crea il prossimo (un lotto per clic, il gioco richiede un clic per creazione).",
    ["Click a recipe in a group member's Can craft tab to ask for it. Answer what you are asked in Craft requests. Requests reach the other player the next time you are both online (or by mail, if turned on in Manage group)."] =
      "Clicca una ricetta nella scheda Può creare di un membro per richiederla. Rispondi alle richieste in Richieste di creazione. Le richieste arrivano all'altro giocatore la prossima volta che siete online insieme (o per posta, se attivato in Gestisci gruppo).",
    ["%s: mats ready"] =
      "%s: materiali pronti",
    ["Your bags hold everything for %dx %s."] =
      "Le tue borse contengono tutto per %dx %s.",
    ["Cooldown ready: %s"] =
      "Tempo di recupero pronto: %s",
    ["on %s"] =
      "su %s",
    ["+%d with Pawn"] =
      "+%d con Pawn",
    ["+%d item levels"] =
      "+%d livelli oggetto",
    ["%s can craft an upgrade for you"] =
      "%s può creare una miglioria per te",
    ["Ask for it"] =
      "Chiedila",
    ["Not interested"] =
      "Non interessa",
    ["New craft request"] =
      "Nuova richiesta di creazione",
    ["Open"] =
      "Apri",
    ["Alerts"] =
      "Avvisi",
    ["A chat line and a short notice at the top of the screen."] =
      "Una riga in chat e un breve avviso in alto sullo schermo.",
    ["Your bags hold the mats for your next craft."] =
      "Le tue borse contengono i materiali per la prossima creazione.",
    ["A profession cooldown is ready on one of your characters."] =
      "Un tempo di recupero di professione è pronto su uno dei tuoi personaggi.",
    ["A craft request arrives or changes."] =
      "Arriva o cambia una richiesta di creazione.",
    ["A group member can craft an upgrade for you (off by default)."] =
      "Un membro del gruppo può creare una miglioria per te (disattivato di default).",
    ["visited"] = "visitato",
    ["Next rank: %s (%d to %d)"] =
      "Grado successivo: %s (%d a %d)",
    ["Journeyman"] =
      "Lavorante",
    ["Expert"] =
      "Esperto",
    ["Artisan"] =
      "Artigiano",
    ["Master"] =
      "Maestro",
    ["skill %d"] =
      "abilità %d",
    ["level %d"] =
      "livello %d",
    ["sold by %s"] =
      "venduto da %s",
    ["or at the AH (~%s)"] =
      "o alla CdA (~%s)",
    ["or at the AH"] =
      "o alla CdA",
    ["Learn it from a trainer of this profession (in Classic: skill %d and character level %d; unconfirmed on Forever)."] =
      "Impara da un istruttore di questa professione (in Classic: abilità %d e livello personaggio %d; non confermato su Forever).",
    ["At the cap (%d)."] =
      "Al massimo (%d).",
    ["Looking for the quest in Questie..."] =
      "Ricerca della missione in Questie...",
    ["This rank comes from a quest (install Questie to find it)."] =
      "Questo grado si ottiene con una missione (installa Questie per trovarla).",
    ["starts at %s"] =
      "inizia da %s",
    ["Quest: %s"] =
      "Missione: %s",
    ["Quests that need %d in this skill; the rank quest is among them."] =
      "Missioni che richiedono %d in questa abilità; la missione di grado è tra queste.",
    ["Click: waypoint to the quest giver."] =
      "Clic: waypoint verso chi dà la missione.",
    ["Shopping list"] =
      "Lista della spesa",
    ["Full plan"] =
      "Piano completo",
    ["Reading the recipes of this profession..."] =
      "Lettura delle ricette di questa professione...",
    ["%d%% chance per craft (%s)"] =
      "%d%% di probabilità per creazione (%s)",
    ["Step panel: off"] =
      "Pannello dei passi: disattivato",
    ["Step panel: on (shown with the profession window)"] =
      "Pannello dei passi: attivato (mostrato con la finestra di professione)",
    ["Click: group needs"] = "Clic: esigenze del gruppo",
    ["Keep for your group"] =
      "Da tenere per il gruppo",
    ["%s: %d for %s"] =
      "%s: %d per %s",
    ["and %d more"] =
      "e altri %d",
    ["You sold %s"] =
      "Hai venduto %s",
    ["Buy back"] =
      "Ricompra",
    ["you"] =
      "te",
    ["At a merchant or the auction house: items in your bags that your group needs."] =
      "Da un mercante o alla casa d'aste: oggetti nelle tue borse che servono al gruppo.",
    ["Next rank"] =
      "Rango successivo",
    ["At the skill cap: the Expert book (vendor or AH), the Artisan quest found in Questie (click for a waypoint to its giver), or the trainer."] =
      "Al massimo dell'abilità: il libro Esperto (mercante o asta), la missione Artigiano trovata in Questie (clic: waypoint verso chi la dà) o l'istruttore.",
    ["Mats ready, profession cooldowns ready on any of your characters, craft requests, items your group needs when you open a merchant or the AH (with Buy back after a sale), and opt-in upgrades. Each one can be turned off in Manage group."] =
      "Materiali pronti, tempi di recupero delle professioni pronti su uno dei tuoi personaggi, richieste di creazione, oggetti che servono al gruppo quando apri un mercante o l'asta (con Ricompra dopo una vendita) e miglioramenti opzionali. Ognuna si disattiva in Gestisci gruppo.",
    ["TSM or Auctionator (prices), Questie (positions), TomTom (waypoints), Pawn (upgrades for each class and spec). All optional."] =
      "TSM o Auctionator (prezzi), Questie (posizioni), TomTom (waypoint), Pawn (miglioramenti per ogni classe e specializzazione). Tutti opzionali.",
    -- Group plan
    ["Spare"] =
      "Avanzo",
    ["Group plan"] =
      "Piano di gruppo",
    ["What the group still needs, what it already holds, and who farms what."] =
      "Cosa manca ancora al gruppo, cosa ha già e chi farma cosa.",
    ["Objective: %s (change it in Manage group > Options)."] =
      "Obiettivo: %s (si cambia in Gestisci gruppo > Opzioni).",
    ["Lowest group cost"] =
      "Costo di gruppo minimo",
    ["Market value"] =
      "Valore di mercato",
    ["Least gold spent by the group: stock already held in the group counts as free."] =
      "Meno oro speso dal gruppo: le scorte già presenti nel gruppo contano come gratis.",
    ["Every material at its market value, as if each character were alone."] =
      "Ogni materiale al suo valore di mercato, come se ogni personaggio fosse solo.",
    ["Material"] =
      "Materiale",
    ["Needed"] =
      "Necessari",
    ["To get"] =
      "Da ottenere",
    ["Est. cost"] =
      "Costo stim.",
    ["Farming"] =
      "Farm",
    ["Farmed by %s"] =
      "Farmato da %s",
    ["Drop"] =
      "Rinuncia",
    ["I'll farm it"] =
      "Lo farmo io",
    ["Estimated cost for the group: %s"] =
      "Costo stimato per il gruppo: %s",
    ["Estimated cost for the group: at least %s (some items have no price)."] =
      "Costo stimato per il gruppo: almeno %s (alcuni oggetti non hanno prezzo).",
    ["Estimated cost for the group: unknown (TSM or Auctionator give AH prices)."] =
      "Costo stimato per il gruppo: sconosciuto (TSM o Auctionator danno i prezzi dell'asta).",
    ["%d %s needed for %s. Do you want to farm them?"] =
      "%d %s necessari per %s. Vuoi farmarli?",
    ["Farming done: %s"] =
      "Farm completato: %s",
    ["Give them from You can give in the Group view, or by mail."] =
      "Dalli da Puoi dare nella vista Gruppo, o per posta.",
    ["Show the farming tracker (your farming assignments from the Group plan)."] =
      "Mostra il tracker del farm (i tuoi incarichi dal Piano di gruppo).",
    ["Plans count stock already held in the group as free (or every mat at market value: Manage group > Options). The Group plan view lists what the group still needs and its cost; take a material with I'll farm it and a small tracker follows your progress."] =
      "I piani contano come gratis le scorte già presenti nel gruppo (oppure ogni materiale al valore di mercato: Gestisci gruppo > Opzioni). La vista Piano di gruppo elenca cosa manca ancora al gruppo e quanto costa; prendi un materiale con Lo farmo io e un piccolo tracker segue i tuoi progressi.",
}
