-- itIT translations. Keys: the English text (see Locale.lua); loaded only on a itIT client.
local _, ns = ...
local loc = GetLocale and GetLocale()
if loc ~= "itIT" then return end
ns.Translations = ns.Translations or {}
ns.Translations[loc] = {
    -- Core
    ["commands: /comrade (window) | share [off] | list [off] | directory [text] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"] =
      "comandi: /comrade (finestra) | share [off] | list [off] | directory [testo] | add NOME | remove NOME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NOME | scan | needs | stats | api | audit | log clear",
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
    ["The window"] =
      "La finestra",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "A sinistra: il gruppo, poi ogni personaggio. Piano = come salire in una professione; Può creare = cosa può fare quel personaggio per il gruppo. I chip filtrano per professione.",
    ["Plans"] =
      "Piani",
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
    ["Plan and Can craft"] =
      "Piano e Può creare",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Scegli un personaggio: Piano mostra come salire in ogni professione passo dopo passo; Può creare mostra cosa può fare per gli altri.",
    ["While you play"] =
      "Mentre giochi",
    ["Sharing is off until you check a box"] = "La condivisione è disattivata finché non spunti una casella",
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
    ["Objective:"] =
      "Obiettivo:",
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
    ["Guild directory"] =
      "Elenco della gilda",
    ["%d crafter"] =
      "%d artigiano",
    ["%d crafters"] =
      "%d artigiani",
    ["Right box: list the character in the guild directory (professions and recipes only, sent to your guild)."] =
      "Casella a destra: iscrivi il personaggio all'elenco della gilda (solo professioni e ricette, inviate alla tua gilda).",
    ["List in guild directory"] =
      "Iscrivi all'elenco della gilda",
    ["Opt-in, per character: List in guild directory in Manage group (or /comrade list) sends its professions and recipes to guildmates who use ComradeCraft. Search who can craft an item, whisper them, or ask for the craft if they are in your group. Item tooltips name up to 3 guild crafters."] =
      "Facoltativo, per personaggio: Iscrivi all'elenco della gilda, in Gestisci gruppo (o /comrade list), invia le sue professioni e ricette ai membri della gilda che usano ComradeCraft. Cerca chi può creare un oggetto, sussurragli o chiedigli di crearlo se è nel tuo gruppo. I tooltip degli oggetti indicano fino a 3 artigiani della gilda.",
    ["Whisper"] =
      "Sussurra",
    ["Nobody is listed yet. The directory is opt-in: each player lists their own characters in Manage group (List in guild directory) or with /comrade list."] =
      "Nessuno è ancora iscritto. L'elenco è facoltativo: ogni giocatore iscrive i propri personaggi in Gestisci gruppo (Iscrivi all'elenco della gilda) o con /comrade list.",
    ["Type a product or recipe name in the search box."] =
      "Scrivi il nome di un oggetto o di una ricetta nella casella di ricerca.",
    ["No crafter found."] =
      "Nessun artigiano trovato.",
    ["... and %d more"] =
      "... e altri %d",
    ["Who in your guild can craft what. Each player lists their own characters (opt-in)."] =
      "Chi nella tua gilda sa creare cosa. Ogni giocatore iscrive i propri personaggi (facoltativo).",
    ["Guild crafters: %s"] =
      "Artigiani della gilda: %s",
    ["%s is listed in the guild directory"] =
      "%s è iscritto all'elenco della gilda",
    ["%s is no longer listed in the guild directory"] =
      "%s non è più iscritto all'elenco della gilda",
    ["You are not in a guild: the entry is sent once you are."] =
      "Non sei in una gilda: l'iscrizione verrà inviata quando ne avrai una.",
    ["directory: %d characters listed. /comrade directory TEXT searches them."] =
      "elenco: %d personaggi iscritti. /comrade directory TESTO per cercare.",
    ["directory: no crafter for %s"] =
      "elenco: nessun artigiano per %s",
    -- UI polish, bags, mail & friends
    ["%d item"] = "%d oggetto",
    ["%d items"] = "%d oggetti",
    ["Add %s"] = "Aggiungi %s",
    ["Add target"] = "Aggiungi bersaglio",
    ["Cancel"] = "Annulla",
    ["Click a member to highlight their items."] = "Clicca un membro per evidenziare i suoi oggetti.",
    ["Click to select recipient and highlight needed items in your bags."] =
      "Clicca per scegliere il destinatario ed evidenziare ciò che gli serve nelle borse.",
    ["Collapse all"] = "Comprimi tutto",
    ["ComradeCraft: Add to group"] = "ComradeCraft: Aggiungi al gruppo",
    ["Expand all"] = "Espandi tutto",
    ["Filter recipes..."] = "Filtra ricette...",
    ["Search stock or crafters..."] = "Cerca scorte o artigiani...",
    ["For %s"] = "Per %s",
    ["Friend"] = "Amico",
    ["Guild"] = "Gilda",
    ["Highlight items for your group in your bags (and focus a recipient's items when mailing)."] =
      "Evidenzia nelle borse gli oggetti per il gruppo (e focalizza quelli del destinatario nella posta).",
    ["Highlighted in your bags"] = "Evidenziato nelle borse",
    ["Nothing to send from your bags."] = "Nulla da inviare dalle tue borse.",
    ["Online in your party, friends or guild:"] = "Online nel tuo gruppo, amici o gilda:",
    ["Party"] = "Gruppo",
    ["Ready to send from your bags"] = "Pronto da inviare dalle borse",
    ["Retry"] = "Riprova",
    ["Search guild crafters..."] = "Cerca artigiani...",
    ["Send x%d to %s"] = "Invia x%d a %s",
    ["Send x%d to %s (%s)"] = "Invia x%d a %s (%s)",
    ["To send from your bags: %s"] = "Da inviare dalle borse: %s",
    ["You cannot add yourself."] = "Non puoi aggiungere te stesso.",
    ["craft request"] = "richiesta di creazione",
    ["waiting for reply"] = "in attesa di risposta",
    ["Share all"] = "Condividi tutti",
    ["Unshare all"] = "Rimuovi tutti",
    ["Automatically share new characters on this account"] =
      "Condividi automaticamente i nuovi personaggi di questo account",
    ["All characters (%d) are now shared with your group"] =
      "Tutti i personaggi (%d) sono ora condivisi con il tuo gruppo",
    ["No character is shared anymore"] = "Nessun personaggio è più condiviso",
    ["%s requires higher %s skill; skipped for waypoints until you level up."] =
      "%s richiede un livello più alto in %s; saltato per i waypoint finché non sali di livello.",
    ["Right-click: skip this recipe and recalculate."] =
      "Tasto destro: salta questa ricetta e ricalcola.",
    ["Reset skipped (%d)"] = "Ripristina saltate (%d)",
    -- Trade, Merchant, Wishlist, Cooldowns & UI rework
    ["%d tracked"] = "%d seguiti",
    ["%s wants to join your group"] = "%s vuole unirsi al tuo gruppo",
    ["Accept to share your checked characters with them."] =
      "Accetta per condividere i personaggi selezionati.",
    ["Add to wishlist"] = "Aggiungi alla lista",
    ["All materials are in your bags."] = "Tutti i materiali sono nelle borse.",
    ["Buy plan reagents (%s)"] = "Compra reagenti (%s)",
    ["Click to sync now with your group."] = "Clicca per sincronizzare ora con il gruppo.",
    ["Compare routes"] = "Confronta percorsi",
    ["Craft"] = "Crea",
    ["Disenchant"] = "Disincanta",
    ["For who:"] = "Per chi:",
    ["Group cooldowns"] = "Tempi di recupero del gruppo",
    ["Hide route comparison"] = "Nascondi confronto",
    ["Ignore"] = "Ignora",
    ["Materials"] = "Materiali",
    ["No craft pinned yet. Right-click any recipe in your Can craft tab to add it here, track its materials and get notified when ready."] =
      "Nessuna creazione fissata. Tasto destro su una ricetta in Può creare per aggiungerla qui, seguire i materiali e ricevere avviso quando è pronta.",
    ["No disenchantable items in your bags."] = "Nessun oggetto disincantabile nelle borse.",
    ["Not enough gold (%s needed)."] = "Oro insufficiente (servono %s).",
    ["Note (optional):"] = "Nota (opzionale):",
    ["Overview"] = "Riepilogo",
    ["Pin"] = "Fissa",
    ["Pin on screen"] = "Fissa sullo schermo",
    ["Pinned crafts to track materials for yourself or friends."] =
      "Creazioni fissate per tracciare i materiali per te o gli amici.",
    ["Place needed items"] = "Inserisci il necessario",
    ["Plan reagents"] = "Reagenti del piano",
    ["Quantity:"] = "Quantità:",
    ["Ready"] = "Pronto",
    ["Ready (some mats in bank/mail)"] = "Pronto (materiali in banca/posta)",
    ["Ready to craft!"] = "Pronto da creare!",
    ["Right-click: add to Wishlist."] = "Tasto destro: aggiungi alla lista desideri.",
    ["Show the wishlist tracker on screen (pinned crafts)."] =
      "Mostra il tracker delle creazioni fissate sullo schermo.",
    ["Trade window is full (%d slots)."] = "Finestra di scambio piena (%d slot).",
    ["Unpin"] = "Rimuovi",
    ["Wishlist"] = "Da creare",
    ["Wishlist ready: %dx %s"] = "Pronto da creare: %dx %s",
    ["none pinned"] = "nessuno fissato",
    -- Synergies, Audit, Loot, AH Panel, Buy vs Farm
    ["%d small bags (min %d slots) -> %s (%d slots)"] = "%d borse piccole (min %d slot) -> %s (%d slot)",
    ["%s can craft %dx %s from group's %s for %s"] = "%s può creare %dx %s da %s del gruppo per %s",
    ["Advice"] = "Consiglio",
    ["Back"] = "Schiena",
    ["Buy"] = "Compra",
    ["Buy/Farm"] = "Compra/Farm",
    ["Chest"] = "Torso",
    ["Click an item to search it."] = "Clicca un oggetto per cercarlo.",
    ["Click: search in Auction House."] = "Clic: cerca nella Casa d'Aste.",
    ["Click: waypoint to farm spot."] = "Clic: waypoint per la zona di farm.",
    ["Cross-profession links between your group's active plans."] =
      "Sinergie tra professioni nei piani attivi del gruppo.",
    ["Disenchant %dx %s (%s)"] = "Disincanta %dx %s (%s)",
    ["Disenchant for your enchanting plan"] = "Disincanta per il tuo piano d'incantamento",
    ["Everyone's bags, enchants and gear are up to date."] =
      "Borse, incantamenti ed equipaggiamento del gruppo sono aggiornati.",
    ["Farm"] = "Farma",
    ["Farm %s: %s (%s %d, %d)"] = "Farma %s: %s (%s %d, %d)",
    ["Farm spot"] = "Zona di farm",
    ["Feet"] = "Piedi",
    ["Gear"] = "Equipaggiamento",
    ["Gold: %s"] = "Oro: %s",
    ["Group synergies"] = "Sinergie del gruppo",
    ["Group upgrades"] = "Miglioramenti del gruppo",
    ["Hands"] = "Mani",
    ["Known by %s"] = "Conosciuto da %s",
    ["Loot roll: %s - needed now by %s"] = "Bottino: %s - serve ora a %s",
    ["Loot roll: %s - unknown by %s"] = "Bottino: %s - sconosciuto a %s",
    ["No known farm location for %s."] = "Nessuna zona di farm nota per %s.",
    ["Send %dx %s to %s to disenchant (%s)"] = "Invia %dx %s a %s da disincantare (%s)",
    ["Send to %s to disenchant"] = "Invia a %s da disincantare",
    ["Shield"] = "Scudo",
    ["Small bags, unenchanted gear and craftable upgrades your group can make."] =
      "Borse piccole, pezzi non incantati e miglioramenti creabili dal gruppo.",
    ["To buy at the AH"] = "Da comprare all'asta",
    ["Total: %s (you have %s)"] = "Totale: %s (hai %s)",
    ["Unenchanted %s -> %s"] = "%s non incantato -> %s",
    ["Unknown by %s (%s %d/%d)"] = "Sconosciuto a %s (%s %d/%d)",
    ["Upgrades"] = "Miglioramenti",
    ["Vendor"] = "Venditore",
    ["Waypoint: %s (%s %d, %d)"] = "Waypoint: %s (%s %d, %d)",
    ["Wrist"] = "Polsi",
    ["Your gold: %s"] = "Il tuo oro: %s",
    ["by %s"] = "da %s",
    ["by %s (guild)"] = "da %s (gilda)",
    ["can learn now"] = "apprendibile ora",
    ["needs skill %d"] = "richiede %d",
    ["+%d score"] = "+%d punteggio",
    ["Head"] = "Testa",
    ["Neck"] = "Collo",
    ["Shoulder"] = "Spalle",
    ["Waist"] = "Vita",
    ["Legs"] = "Gambe",
    ["Finger"] = "Dito",
    ["Trinket"] = "Monile",
    ["Off-Hand"] = "Mano secondaria",
    ["Ranged"] = "A distanza",
    ["Spec: %s"] = "Spec: %s",
    ["Spec set to %s."] = "Specializzazione impostata su %s.",
    ["Unknown spec. Available: %s"] = "Specializzazione sconosciuta. Disponibili: %s",
    ["Crafts upgrade for: %s"] = "Crea miglioramento per: %s",
    ["Useful enchant for: %s"] = "Incantamento utile per: %s",
    ["Leveling plan"] = "Piano di livellamento",
    ["Upgrade for %s (%s)"] = "Miglioramento per %s (%s)",
    ["Good enchant for %s"] = "Buon incantamento per %s",
    ["Click to train."] = "Clicca per imparare.",
    ["Recommended recipes"] = "Ricette consigliate",
    ["mats ready"] = "mat. pronti",
    ["Soon (+1-4 lvl)"] = "Presto (+1-4 liv.)",
    ["Consumables"] = "Consumabili",
    ["Patterns to hunt"] = "Schemi da cercare",
    ["Waypoint"] = "Waypoint",
    ["Group materials:"] = "Materiali del gruppo:",
    ["%d mobs"] = "%d nemici",
    ["1 mob"] = "1 nemico",
    ["in bank"] = "in banca",
    ["In bank (retrieve first)"] = "In banca (ritira prima)",
    ["Full name (First Last) required for %s: log them in once or type their full name first."] =
      "Nome completo (Nome Cognome) richiesto per %s: effettua l'accesso una volta o inserisci prima il nome completo.",
    ["Withdraw from bank"] = "Ritira dalla banca",
    ["Withdraw needed"] = "Ritira il necessario",
    ["Click an item to withdraw it."] = "Clicca un oggetto per ritirarlo.",
    ["Your bags are full."] = "Le tue borse sono piene.",
    ["For your plan"] = "Per il tuo piano",
    ["To send to %s"] = "Da inviare a %s",
    ["Right-click: %dx %s -> %dx %s"] = "Tasto destro: %dx %s -> %dx %s",
    ["BoE patterns"] = "Modelli BoE",
    ["Share in chat"] = "Condividi in chat",
    ["Shared bank alt"] = "Alt banca condivisa",
    ["Shared bank alt: all items on this character (bags, bank, mail) appear as available to your group, and members can request them via the addon."] = "Alt banca condivisa: tutti gli oggetti di questo personaggio (borse, banca, posta) appaiono disponibili per il gruppo e chiunque può richiederli tramite l'addon.",
    ["Bank"] = "Banca",
    ["Ask %s for %s"] = "Chiedi a %s: %s",
    ["%s asks %s for %dx %s."] = "%s chiede a %s: %dx %s.",
    ["Request"] = "Richiedi",
    ["No items stored yet."] = "Nessun oggetto conservato.",
    ["Filter items..."] = "Filtra oggetti...",
    ["Your group's skill levels, synergies, items you can give, and active cooldowns."] = "Livelli delle professioni del gruppo, sinergie, oggetti che puoi dare e tempi di recupero attivi.",
    ["All materials your group still needs, sorted by urgency. Type to find who can craft something."] = "Tutti i materiali che servono ancora al gruppo, ordinati per urgenza. Scrivi per trovare chi può creare qualcosa.",
    ["Craftable BiS gear, enchants, consumables, small bags, and patterns to hunt for each member."] = "Equipaggiamento BiS creabile, incantamenti, consumabili, borse piccole e modelli da cercare per ogni membro.",
    ["Green items in your bags: keep for enchants or upgrades, sell on the AH, or disenchant."] = "Oggetti verdi nelle borse: tieni per incantamenti o miglioramenti, vendi all'asta o disincanta.",
    ["Left: Group overview, Materials, Craftable BiS Upgrades, Wishlist, Requests, and every character in your group."] = "A sinistra: Panoramica, Materiali, Miglioramenti BiS, Lista desideri, Richieste e ogni personaggio del gruppo.",
    ["Bags highlight items your group needs; helper panels dock at Mail, Bank, Trade, Merchant, AH, and Trainers."] = "Le borse evidenziano ciò che serve al gruppo; pannelli di aiuto si agganciano a Posta, Banca, Scambio, Mercante, Asta e Istruttori.",
    ["Nothing is shared yet. Here, in Manage group, check characters to share (or flag a Shared bank alt), then add friends below. Mutually added peers relay updates automatically."] = "Nulla è ancora condiviso. Spunta i personaggi da condividere (o un Alt banca condivisa) e aggiungi amici qui sotto. I contatti reciproci inoltrano gli aggiornamenti automaticamente.",
    ["Reserved %dx %s for %s."] = "Riservato %dx %s per %s.",
    ["Reservation removed for %s."] = "Riserva rimossa per %s.",
    ["Reserve for..."] = "Riserva per...",
    ["Unlock reservation"] = "Sblocca riserva",
    ["Usage: /comrade reserve [Item] Name [qty]"] = "Uso: /comrade reserve [Oggetto] Nome [qtà]",
    ["Usage: /comrade unreserve [Item]"] = "Uso: /comrade unreserve [Oggetto]",
    ["Reserved for %s"] = "Riservato per %s",
    ["Reserved for %s (x%d) - Alt+Right-click to unlock"] = "Riservato per %s (x%d) - Alt+Clic destro per liberare",
    ["Reserved for you by %s (x%d)"] = "Riservato per te da %s (x%d)",
    ["Reserved"] = "Riservato",
    ["Favorite"] = "Preferito",
    ["Unstar"] = "Rimuovi",
    ["Farming for you"] = "In farm per te",
    ["Filter characters..."] = "Filtra personaggi...",
    ["by %s (you)"] = "da %s (tu)",
    ["crafting"] = "in corso",
    ["shipped"] = "spedito",
    ["Crafting"] = "In corso",
    ["Shipped"] = "Spedito",
    ["Ready to craft"] = "Pronto da creare",
    ["Ready to ship"] = "Pronto da spedire",
    ["Missing %s"] = "Manca %s",
    ["Missing %d"] = "Mancano %d",
    ["Reserved for you"] = "Riservato per te",
    ["Your reserved items"] = "I tuoi oggetti riservati",
    ["Unlock"] = "Libera",
    ["reserved"] = "riservato",
    ["Click: reserve for %s."] = "Clic: riserva per %s.",
    ["Click: request from %s [Bank]."] = "Clic: richiedi a %s [Banca].",
    ["Favorites"] = "Preferiti",
    ["My characters"] = "I miei personaggi",
    ["Group members"] = "Membri del gruppo",
    ["%d farming"] = "%d in farm",
    ["Auto-marked request %dx %s as shipped."] = "Richiesta %dx %s segnata automaticamente come spedita.",
    ["Alt+Right-click any bag item to reserve/lock it for a friend before mailing."] = "Alt+Clic destro su un oggetto nelle borse per riservarlo a un amico prima dell'invio.",
    ["Item reservations"] = "Riserve oggetti",
    ["  %s: %d crafts, %d points (expected %.1f)%s"] = "  %s: %d creazioni, %d punti (attesi %.1f)%s",
    ["Add friends"] = "Aggiungi amici",
    ["All window and tracker positions reset."] = "Tutte le posizioni di finestre e tracker ripristinate.",
    ["Auction House panel"] = "Pannello Casa d'Aste",
    ["Bank panel"] = "Pannello Banca",
    ["Browse Can craft"] = "Vedi Può creare",
    ["Browse Upgrades"] = "Vedi Miglioramenti",
    ["Companion panels"] = "Pannelli laterali",
    ["Configure companion panels, UI scale, sounds, and window positions."] = "Configura pannelli laterali, scala interfaccia, suoni e posizioni.",
    ["Crafts logged by you and your group automatically calibrate skill-up chances for WoW Forever."] = "Le creazioni registrate da te e dal tuo gruppo calibrano automaticamente le probabilità per WoW Forever.",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never."] = "Ogni passo mostra cosa imparare dall'istruttore, cosa creare prima (rotoli, lingotti...) e quanti. Clic apre la ricetta, Maiusc+clic la collega. Colori: arancione sempre, giallo spesso, verde raramente, grigio mai.",
    ["Interface"] = "Interfaccia",
    ["Known recipes. Right-click to pin to Wishlist, or click a friend's recipe to request it."] = "Ricette conosciute. Clic destro per fissare nella Lista desideri, o clic sulla ricetta di un amico per richiederla.",
    ["Learn from a trainer of this profession (requires skill %d, level %d)."] = "Impara da un istruttore di questa professione (richiede abilità %d, livello %d).",
    ["Left-click: open window  |  Right-click: options"] = "Clic sinistro: apri finestra  |  Clic destro: opzioni",
    ["List my character"] = "Registra il mio personaggio",
    ["Mailbox panel"] = "Pannello Posta",
    ["Merchant panel"] = "Pannello Mercante",
    ["No friends in your group yet. Add guildmates or friends to share mats and upgrades."] = "Nessun amico nel gruppo ancora. Aggiungi amici o compagni di gilda per condividere materiali e miglioramenti.",
    ["Open ComradeCraft"] = "Apri ComradeCraft",
    ["Play sound notifications"] = "Riproduci notifiche sonore",
    ["Reset window positions"] = "Ripristina posizioni",
    ["Show minimap button"] = "Mostra pulsante minimappa",
    ["Step-by-step profession leveling route, cost comparison, and trainer guide."] = "Percorso passo passo, confronto costi e guida agli istruttori.",
    ["Sync: %d players in the group, %d suggested."] = "Sync: %d giocatori nel gruppo, %d suggeriti.",
    ["Toggle ComradeCraft"] = "Mostra / nascondi ComradeCraft",
    ["Trade panel"] = "Pannello Scambio",
    ["Trainer panel"] = "Pannello Istruttore",
    ["Window scale"] = "Scala finestra",
    ["AH ~%s"] = "Asta ~%s",
    ["For"] = "Per",
    ["Important unlearned patterns to buy or farm for yourself and your group (with drop rate and waypoints)."] = "Modelli importanti non appresi da comprare o farmare per te e il tuo gruppo (con drop rate e waypoint).",
    ["No unlearned upgrade patterns found for this character right now."] = "Nessun modello di miglioramento non appreso trovato per questo personaggio al momento.",
    ["Patterns"] = "Modelli",
    ["Valuable unlearned patterns for yourself and your group: where to buy or farm them, drop rate when known, and 1-click waypoints."] = "Modelli importanti non appresi per te e il tuo gruppo: dove comprarli o farmarli, percentuale di drop quando nota e waypoint in 1 clic.",
  ["Bargains"] = "Affari",
  ["Deals"] = "Affari",
  ["Group needs spotted below market price."] = "Bisogni del gruppo trovati sotto il prezzo di mercato.",
  ["Character"] = "Personaggio",
  ["Slot"] = "Slot",
  ["Group by:"] = "Raggruppa per:",
  ["Enchants"] = "Incantamenti",
  ["Bags"] = "Borse",
  ["Claim CD"] = "Richiedi CD",
  ["Estimated net profit and 1-click Claim CD for your group's long cooldowns."] = "Profitto netto stimato e richiesta in 1 clic per i tempi di recupero lunghi del gruppo.",
  ["Craft chain planned (%d steps for %s)."] = "Catena di creazione pianificata (%d passaggi per %s).",
  ["Multi-profession craft chain"] = "Catena di creazione multi-professione",
  ["Plan chain (%d)"] = "Catena (%d)",
  ["Forever P2P DB: %d recipe bounds, %d vendors, %d drops (from %d peers)."] = "DB Forever P2P: %d soglie, %d mercanti, %d drop (da %d peer).",
  ["In %s (%d finds):"] = "In %s (%d risultati):",
  ["In %s: %s"] = "In %s: %s",
  ["In your zone: %s"] = "Nella tua zona: %s",
  ["Nothing specific for your group found in %s."] = "Nulla di specifico per il gruppo trovato in %s.",
  ["Rare drops, vendors, patterns and materials useful to your group right here."] = "Mob rari, mercanti, schemi e materiali utili al gruppo proprio qui.",
  ["world drop"] = "drop mondiale",
  ["world drop - here (%s)"] = "drop mondiale - qui (%s)",
  ["world drop - near %s"] = "drop mondiale - vicino a %s",
  ["%d bounds  |  %d custom recipes  |  %d disenchants  |  %d vendors  |  %d drops  (%d peers)"] = "%d soglie  |  %d ricette custom  |  %d disincantamenti  |  %d mercanti  |  %d drop  (%d pari)",
  ["%d in transit"] = "%d in transito",
  ["Accepted craft requests & pinned wishlist for this profession."] = "Richieste accettate e lista desideri fissata per questa professione.",
  ["Already mailed between group accounts — counted as on the way so nobody double-sends."] = "Già spedito tra account del gruppo — contato in arrivo per evitare doppi invii.",
  ["Applied craft kit \"%s\" (x%d)."] = "Kit \"%s\" applicato (x%d).",
  ["Apply x1"] = "Applica x1",
  ["Apply x5"] = "Applica x5",
  ["Click to open recipe (trade slot 7)"] = "Clic: apri ricetta (slot scambio 7)",
  ["Click to open this enchant for the trade slot."] = "Clicca per aprire questo incantamento per lo slot scambio.",
  ["Craft kits"] = "Kit di creazione",
  ["Craft request (%s)"] = "Richiesta (%s)",
  ["Deliver to %s"] = "Consegna a %s",
  ["Enchant auto-completes request on trade"] = "L'incantamento completa la richiesta allo scambio",
  ["Forever P2P database"] = "Database P2P Forever",
  ["In group stock: \"%s\""] = "In scorta nel gruppo: \"%s\"",
  ["In transit"] = "In transito",
  ["In transit (1h mail)"] = "In transito (posta 1h)",
  ["Next: %s (%d left)"] = "Prossimo: %s (%d rim.)",
  ["Observed WoW Forever recipe bounds, custom recipes, disenchants, vendors and drops shared automatically."] = "Soglie Forever, ricette custom, disincantamenti, mercanti e drop condivisi automaticamente.",
  ["Orders (%d)"] = "Ordini (%d)",
  ["Reserved by %s"] = "Riservato da %s",
  ["Reusable craft bundles (raid, dungeon, reroll) — apply in 1 click."] = "Pacchetti riutilizzabili (incursione, spedizione, alt) — applica in 1 clic.",
  ["Save as kit"] = "Salva kit",
  ["Save current wishlist as a reusable kit"] = "Salva la lista attuale come kit riutilizzabile",
  ["Save kit"] = "Salva",
  ["Saved craft kit \"%s\" (%d recipes)."] = "Kit \"%s\" salvato (%d ricette).",
  ["Sent %d/%d"] = "Inviati %d/%d",
  ["Sent %d/%d %s."] = "Inviati %d/%d %s.",
  ["Share now"] = "Condividi",
  ["Step %d/%d"] = "Fase %d/%d",
  ["Waiting previous step"] = "In attesa fase precedente",
  ["Wishlist completed: %s"] = "Lista completata: %s",
  ["measured"] = "misurato",
    -- Target skill (Plan tab)
    ["Price mats (%d/%d)"] = "Prezzi materiali (%d/%d)",
    ["Mats priced (%d/%d)"] = "Materiali con prezzo (%d/%d)",
    ["Each click searches the next material without a price."] = "Ogni clic cerca il prossimo materiale senza prezzo.",
    ["Deposit later mats"] = "Deposita i materiali per dopo",
    ["Needed at skill %d"] = "Serve all'abilità %d",
    ["Needed later"] = "Serve più avanti",
    ["Your bank is full."] = "La tua banca è piena.",
    ["cost %s"] = "costo %s",
    ["resale %s"] = "rivendita %s",
    ["%s says it is a character of %s: accept or refuse it in Manage group."] = "%s dice di essere un personaggio di %s: accettalo o rifiutalo in Gestisci gruppo.",
    ["Forget"] = "Dimentica",
    ["%s says it is one of their characters."] = "%s dice di essere uno dei suoi personaggi.",
    ["Refuse"] = "Rifiuta",
    ["auction house"] = "casa d'aste",
    ["Queued %dx %s: open the profession window and click Craft next."] = "%dx %s in coda: apri la finestra della professione e clicca Crea il prossimo.",
    ["Restock: %s"] = "Rifornisci: %s",
    ["Restock"] = "Rifornisci",
    ["Queue"] = "Coda",
    ["No risk: sell to a merchant"] = "Senza rischio: vendi a un mercante",
    ["net %s per craft at a merchant"] = "netto %s per creazione da un mercante",
    ["Auctionator shopping list ready: %s (%d items)."] = "Lista acquisti di Auctionator pronta: %s (%d oggetti).",
    ["once per cooldown"] = "una volta per ricarica",
    ["Cooldown goldmakers"] = "Creazioni redditizie con ricarica",
    ["ready in %s"] = "pronto tra %s",
    ["Goldmaking"] = "Fare oro",
    ["net %s per craft"] = "netto %s per creazione",
    ["~%d sold per day"] = "~%d venduti al giorno",
    ["~%s per day"] = "~%s al giorno",
    ["sales volume unknown"] = "volume di vendita sconosciuto",
    ["craft the %s yourself"] = "crea tu stesso: %s",
    ["craft the %s yourself (recipe to learn)"] = "crea tu stesso: %s (ricetta da imparare)",
    ["Crafts that earn the most at the auction house, at the pace it buys them (mats bought or crafted, whichever is cheaper; after the cut and deposit)."] = "Le creazioni che rendono di più alla casa d'aste, al ritmo con cui le compra (materiali comprati o creati, il più economico; dopo commissione e deposito).",
    ["No auction prices yet: scan the auction house or install TSM or Auctionator."] = "Ancora nessun prezzo d'asta: scansiona la casa d'aste o installa TSM o Auctionator.",
    ["stackable"] = "impilabile",
    ["one by one"] = "una alla volta",
    ["Repeat goldmakers"] = "Creazioni redditizie ripetibili",
    ["No known recipe makes money at current prices."] = "Nessuna ricetta conosciuta rende ai prezzi attuali.",
    ["Recipes worth buying"] = "Ricette da comprare",
    ["recipe %s, paid back in %d crafts"] = "ricetta %s, ripagata in %d creazioni",
    ["What if I learned:"] = "E se imparassi:",
    ["Alternative: %s from the quest %s would save about %s."] = "Alternativa: %s dalla missione %s farebbe risparmiare circa %s.",
    ["Get a %s"] = "Procurati: %s",
    ["Craft it first: %s."] = "Crealo prima: %s.",
    ["Sold by trade supplies vendors (%s)."] = "Venduto dai fornitori di articoli commerciali (%s).",
    ["Sold by trade supplies vendors."] = "Venduto dai fornitori di articoli commerciali.",
    ["Craft at: %s"] = "Crea presso: %s",
    ["Nearest: %s"] = "Il più vicino: %s",
    ["Location not known yet: saved the first time someone crafts there."] = "Posizione ancora sconosciuta: viene salvata la prima volta che qualcuno crea lì.",
    ["Anvil"] = "Incudine",
    ["Forge"] = "Forgia",
    ["Loom"] = "Telaio",
    ["Cooking Fire"] = "Fuoco da cucina",
    ["Tanning Rack"] = "Rastrelliera per conciatura",
    ["Spinning Wheel"] = "Arcolaio",
    ["Sewing Machine"] = "Macchina da cucire",
    ["Master Forge"] = "Forgia maestra",
    ["Alchemy Lab"] = "Laboratorio alchemico",
    ["Iron Oven"] = "Forno di ferro",
    ["Fermenter"] = "Fermentatore",
    ["Black Anvil"] = "Incudine Nera",
    ["Black Forge"] = "Forgia Nera",
    ["With your budget you can reach %d (target %d)."] = "Con il tuo budget puoi arrivare a %d (obiettivo %d).",
    ["Filtered by the budget: the greyed steps need about %s more."] = "Filtrato dal budget: i passi in grigio richiedono circa %s in più.",
    ["Remove budget"] = "Rimuovi budget",
    ["Budget (g):"] = "Budget (o):",
    ["Budget"] = "Budget",
    ["Gold you put into leveling, Enter to apply; empty = no limit. Sales of earlier crafts are reinvested."] = "Oro che metti nel livellamento, Invio per applicare; vuoto = nessun limite. Le vendite dei manufatti precedenti vengono reinvestite.",
    ["Enter to apply"] = "Invio per applicare",
    ["no limit - type gold, Enter to apply"] = "nessun limite - scrivi l'oro, Invio per applicare",
    ["Gold needed at the worst moment: %s (sales of earlier crafts reinvested)."] = "Oro necessario nel momento peggiore: %s (vendite dei manufatti precedenti reinvestite).",
    ["Sell the crafts:"] = "Cosa fare con i manufatti:",
    ["%s: %s"] = "%s: %s",
    ["%d at the AH"] = "%d all'asta",
    ["disenchant %d with %s"] = "disincantare %d con %s",
    ["%d to a merchant"] = "%d al mercante",
    ["Buy %s at the auction house (skill %s, %s)"] = "Compra %s alla casa d'aste (abilità %s, %s)",
    ["Auction house - skill %s - %s"] = "Casa d'aste - abilità %s - %s",
    ["Buy recipe: %s"] = "Compra ricetta: %s",
    ["Buy %s from %s (skill %s, %s)"] = "Compra %s da %s (abilità %s, %s)",
    ["Vendor: %s - skill %s - %s"] = "Mercante: %s - abilità %s - %s",
    ["price unknown until you visit the vendor"] = "prezzo ignoto finché non visiti il mercante",
    ["a vendor"] = "un mercante",
    ["Trainer & recipes"] = "Istruttore e ricette",
    ["+ Trainer & recipes: %s (in the net). To buy = missing mats (AH + merchant); net = to buy - resale + trainer & recipes."] = "+ Istruttore e ricette: %s (incluso nel netto). Da comprare = materiali mancanti (asta + mercante); netto = da comprare - rivendita + istruttore e ricette.",
    ["(your side only)"] = "(solo dalla tua parte)",
    ["Target:"] = "Obiettivo:",
    ["Target skill"] = "Abilità obiettivo",
    ["Type a skill (up to 300) and press Enter. Mouse wheel: +/-5 (Shift: 25)."] = "Scrivi un'abilità (max 300) e premi Invio. Rotellina: +/-5 (Maiusc: 25).",
    ["(cap) - click to change, Enter to apply"] = "(max) - clicca per cambiare, Invio per applicare",
    ["click to change, Enter to apply"] = "clicca per cambiare, Invio per applicare",
    ["Target %d"] = "Punta a %d",
    ["Cap"] = "Max",
    ["Level %d needed to learn this rank (now %d)."] = "Serve il livello %d per imparare questo rango (ora %d).",
    ["Total %d to %d (%s prices)"] = "Totale da %d a %d (prezzi %s)",
    ["Total %d to %d: gross %s, to buy %s, resale %s, trainer %s, net %s (%s prices)."] = "Totale da %d a %d: lordo %s, da comprare %s, rivendita %s, istruttore %s, netto %s (prezzi %s).",
    ["Gross"] = "Lordo",
    ["To buy"] = "Da comprare",
    ["Resale"] = "Rivendita",
    ["Net"] = "Netto",
    ["not counted"] = "non contato",
    ["Stops at"] = "Si ferma a",
    ["Other route: trainer not counted."] = "Altro percorso: istruttore non contato.",
    ["> = some prices are unknown: a cost is a minimum, a profit (+<) a maximum."] = "> = alcuni prezzi sono sconosciuti: un costo è un minimo, un guadagno (+<) un massimo.",
}
