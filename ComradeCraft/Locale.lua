-- Locale: English is the key and the default; other client languages override below.
-- tools/check_lua.py fails if a key used in the code has no frFR translation.
local _, ns = ...

local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L

local translations = {
  frFR = {
    -- Core
    ["commands: /comrade (window) | share [off] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"] =
      "commandes : /comrade (fenêtre) | share [off] | add NOM | remove NOM | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NOM | scan | needs | stats | api | audit | log clear",
    ["log cleared"] = "log vidé",
    ["%d lines in the log (written to disk on /reload or logout)"] =
      "%d lignes dans le log (écrit sur disque au /reload ou à la déconnexion)",
    -- Scan
    ["scan ok: %d distinct items in bags"] = "scan ok : %d objets distincts dans les sacs",
    ["DevTools_Dump missing; see WTF\\...\\SavedVariables\\ComradeCraft.lua after /reload"] =
      "DevTools_Dump absent; voir WTF\\...\\SavedVariables\\ComradeCraft.lua après /reload",
    ["audit: C_TradeSkillUI.GetAllRecipeIDs missing on this client"] =
      "audit : C_TradeSkillUI.GetAllRecipeIDs absent sur ce client",
    ["audit: open a profession window first"] = "audit : ouvre une fenêtre de profession d'abord",
    ["  %s (%d): game=%s table=%s [%d/%d]"] = "  %s (%d) : jeu=%s table=%s [%d/%d]",
    ["audit rank %d: %d ok, %d mismatches, %d missing from the table"] =
      "audit rang %d : %d ok, %d écarts, %d absentes de la table",
    ["LibProfessionDB: %d ok, %d mismatches"] = "LibProfessionDB : %d ok, %d écarts",
    ["maxTrivialLevel == grey: %d yes, %d no"] = "maxTrivialLevel == gris : %d oui, %d non",
    ["yes"] = "oui",
    ["no"] = "non",
    -- SkillLog
    ["%d crafts recorded (calibration from %d per color)"] =
      "%d crafts enregistrés (calibrage à partir de %d par couleur)",
    ["orange"] = "orange",
    ["yellow"] = "jaune",
    ["green"] = "vert",
    ["grey"] = "gris",
    ["  %s: %d crafts, %d points, Classic formula %.1f%s"] =
      "  %s : %d crafts, %d points, formule Classic %.1f%s",
    [" -> factor %.2f applied"] = " -> facteur %.2f appliqué",
    ["  game color known on %d crafts: our table %d right, LibProfessionDB %d right"] =
      "  couleur du jeu connue sur %d crafts : notre table %d bonnes, LibProfessionDB %d bonnes",
    -- Tooltip / needs text
    ["needs %d"] = "besoin de %d",
    ["Group total"] = "Total du groupe",
    ["Spare in the group"] = "En surplus dans le groupe",
    ["You can give"] = "Tu peux donner",
    ["Spare items in your bags that others need. With a mailbox open, click one to prepare the mail."] =
      "Objets en surplus dans tes sacs dont d'autres ont besoin. Boîte aux lettres ouverte : clique pour préparer le courrier.",
    ["Mail full (%d attachments): send it, then click again for the rest."] =
      "Courrier plein (%d pièces jointes) : envoie-le, puis reclique pour le reste.",
    ["Open a mailbox first."] = "Ouvre d'abord une boîte aux lettres.",
    ["Nothing to give to %s."] = "Rien à donner à %s.",
    ["Attach what they need"] = "Joindre ses besoins",
    ["Type the name of a group member."] = "Tape le nom d'un membre du groupe.",
    ["You need"] = "Il te faut",
    ["Disenchant or keep?"] = "Désenchanter ou garder ?",
    ["Green and better items in your bags. Yields are estimates until your disenchants are logged."] =
      "Objets verts et mieux dans tes sacs. Rendements estimés tant que tes désenchantements ne sont pas mesurés.",
    ["Keep: enchanting target (%s)"] = "Garder : cible d'enchantement (%s)",
    ["Keep: gear for %s"] = "Garder : équipement pour %s",
    ["Sell: AH %s vs disenchant %s"] = "Vendre : HV %s contre désenchantement %s",
    ["Disenchant: %s"] = "Désenchanter : %s",
    ["the group needs these"] = "le groupe en a besoin",
    ["give to %s"] = "donner à %s",
    ["group: %d"] = "groupe : %d",
    ["now"] = "maintenant",
    ["soon"] = "bientôt",
    ["later"] = "plus tard",
    ["trainer"] = "formateur",
    ["vendor"] = "vendeur",
    ["quest"] = "quête",
    ["drop"] = "drop",
    ["container"] = "coffre",
    ["Gathering profession: levels by gathering, not crafting."] =
      "Profession de récolte : monte en récoltant, pas en craftant.",
    ["Open this profession's window once so your recipes can be read."] =
      "Ouvre la fenêtre de cette profession une fois pour lire tes recettes.",
    ["At the cap (%d). Visit the trainer for the next rank."] =
      "Au maximum du palier (%d). Va voir le formateur pour le palier suivant.",
    ["No data."] = "Aucune donnée.",
    ["Learn %s at the trainer (skill %s, %s)"] = "Aller apprendre %s au formateur (skill %s, %s)",
    ["cost unknown until you visit the trainer"] = "coût inconnu tant que tu n'as pas ouvert le formateur",
    ["Craft %d %s (%s)"] = "Crafte %d %s (%s)",
    ["Craft %dx %s (%s)"] = "Crafte %dx %s (%s)",
    ["%d %s (vendor)"] = "%d %s (vendeur)",
    ["Estimated cost: %s (%s prices)."] = "Coût estimé : %s (prix %s).",
    ["Estimated cost: at least %s (%s prices, some items have no price)."] =
      "Coût estimé : au moins %s (prix %s, certains objets sans prix).",
    [" + %d from stock"] = " + %d déjà en stock",
    ["%d %s from stock"] = "%d %s déjà en stock",
    ["With only your current recipes, you would be stuck at %d."] =
      "Avec seulement tes recettes actuelles, tu bloquerais à %d.",
    ["Uses what you already have: %s."] = "Utilise ce que tu as déjà : %s.",
    ["Buy from a vendor: %s."] = "À acheter chez un vendeur : %s.",
    ["Stuck at %d: all your known recipes are grey (no more points)."] =
      "Bloqué à %d : toutes tes recettes connues sont grises (plus aucun point).",
    ["Stuck at %d: your known recipes barely give points anymore (%d%% chance per craft at best, %d%% needed)."] =
      "Bloqué à %d : tes recettes connues ne donnent presque plus de points (%d%% de chance par craft au mieux, il en faut %d%%).",
    [" To learn: %s."] = " À apprendre : %s.",
    [" No recipe to learn found within the next 25 points."] =
      " Aucune recette à apprendre trouvée dans les 25 prochains points.",
    ["  missing %s x%d"] = "  manque %s x%d",
    -- UI
    ["just now"] = "à l'instant",
    ["%d min ago"] = "il y a %d min",
    ["%d h ago"] = "il y a %d h",
    ["What to craft:"] = "Quoi crafter :",
    ["Owned: %d / %d"] = "Possédé : %d / %d",
    ["%d profession"] = "%d profession",
    ["%d professions"] = "%d professions",
    ["%d member"] = "%d membre",
    ["%d members"] = "%d membres",
    ["Group"] = "Groupe",
    ["Plan"] = "Plan",
    ["Can craft"] = "Peut crafter",
    ["Lvl %d"] = "Niv. %d",
    ["updated %s"] = "mis à jour %s",
    ["Skill levels and the materials the group still needs. Type to find who can craft something."] =
      "Niveaux de profession et matériaux qui manquent au groupe. Tape un nom pour trouver qui peut le crafter.",
    ["Skill levels"] = "Niveaux de profession",
    ["Most wanted materials"] = "Matériaux les plus demandés",
    ["Nothing missing yet."] = "Rien ne manque pour l'instant.",
    ["Who can craft \"%s\""] = "Qui peut crafter « %s »",
    ["No recipe matches."] = "Aucune recette ne correspond.",
    ["No profession data. Open your profession windows."] =
      "Pas de données de profession. Ouvre tes fenêtres de profession.",
    ["%d recipe"] = "%d recette",
    ["%d recipes"] = "%d recettes",
    ["gear for %s"] = "équipement pour %s",
    ["upgrade for %s (+%d)"] = "upgrade pour %s (+%d)",
    ["Enchant"] = "Enchantement",
    ["Consumable"] = "Consommable",
    ["Bag"] = "Sac",
    ["Weapon"] = "Arme",
    ["Armor"] = "Armure",
    ["Reagent"] = "Composant",
    ["Other"] = "Autre",
    ["Sync: %d players in the group, %d suggested. skill ~N: value taken from Classic, unconfirmed."] =
      "Sync : %d joueurs dans le groupe, %d suggérés. skill ~N : valeur reprise de Classic, non confirmée.",
    ["via %s"] = "via %s",
    ["Manage group"] = "Gérer le groupe",
    ["Choose what you share, and with whom."] = "Choisis ce que tu partages, et avec qui.",
    ["%d player"] = "%d joueur",
    ["%d players"] = "%d joueurs",
    ["%d request"] = "%d demande",
    ["%d requests"] = "%d demandes",
    ["Your characters"] = "Tes persos",
    ["Only checked characters are shared, and only with the players in your group."] =
      "Seuls les persos cochés sont partagés, et seulement avec les joueurs de ton groupe.",
    ["Players in your group"] = "Joueurs de ton groupe",
    ["They receive your shared characters and you see theirs."] =
      "Ils reçoivent tes persos partagés et tu vois les leurs.",
    ["Nobody yet."] = "Personne pour l'instant.",
    ["seen %s"] = "vu %s",
    ["Remove"] = "Retirer",
    ["Requests and suggestions"] = "Demandes et suggestions",
    ["Players with ComradeCraft in your guild, or who added you. Add them to share both ways."] =
      "Joueurs de ta guilde qui ont ComradeCraft, ou qui t'ont ajouté. Ajoute-les pour partager dans les deux sens.",
    ["Add"] = "Ajouter",
    ["Add a player by name"] = "Ajouter un joueur par son nom",
    ["For friends outside your guild. They must add you back."] =
      "Pour les amis hors guilde. Ils doivent t'ajouter aussi.",
    ["Options"] = "Options",
    ["Send a presence signal to the guild at login (no character data)."] =
      "Envoyer un signal de présence à la guilde à la connexion (aucune donnée de perso).",
    ["All"] = "Toutes",
    ["Hide gathering"] = "Cacher la récolte",
    ["No profession matches the filter."] = "Aucune profession ne correspond au filtre.",
    ["%d character"] = "%d perso",
    ["%d characters"] = "%d persos",
    ["Remove from group"] = "Retirer du groupe",
    -- Sync
    ["sync: sent to the players in your group"] = "sync : envoyé aux joueurs de ton groupe",
    ["%s is shared with your group"] = "%s est partagé avec ton groupe",
    ["%s is no longer shared"] = "%s n'est plus partagé",
    ["guild presence signal: on"] = "signal de présence à la guilde : activé",
    ["guild presence signal: off"] = "signal de présence à la guilde : désactivé",
    ["Share this character with the group"] = "Partager ce perso avec le groupe",
    ["not shared"] = "non partagé",
    ["  %s: %d characters, %s"] = "  %s : %d persos, %s",
    ["in the group"] = "dans le groupe",
    ["wants to join"] = "veut se joindre",
    ["suggested"] = "suggéré",
    ["no peer seen yet (they need ComradeCraft)"] = "aucun joueur vu pour l'instant (il faut ComradeCraft)",
    ["%s added to the group"] = "%s ajouté au groupe",
    ["%s contacted; added as soon as they answer"] = "%s contacté; ajouté dès qu'il répond",
    ["%s removed from the group"] = "%s retiré du groupe",
    -- Shopping, Tracker
    ["Could not create the Auctionator list (see /comrade log)."] =
      "Impossible de créer la liste Auctionator (voir /comrade log).",
    ["Nothing to buy for %s."] =
      "Rien à acheter pour %s.",
    ["Auctionator list \"ComradeCraft: %s\" created: %d items. Open the Shopping tab at the auction house."] =
      "Liste Auctionator \"ComradeCraft: %s\" créée : %d objets. Ouvre l'onglet Shopping à l'hôtel des ventes.",
    ["%d not cached yet; try again in a moment."] =
      "%d pas encore en cache; réessaie dans un instant.",
    ["Nothing to buy."] =
      "Rien à acheter.",
    ["Step panel hidden. /comrade tracker shows it again."] =
      "Panneau d'étape masqué. /comrade tracker le réaffiche.",
    ["TSM shopping (Ctrl+C to copy)"] = "Achats TSM (Ctrl+C pour copier)",
    ["Search: paste in the search box of TSM's Shopping tab."] =
      "Recherche : colle dans la barre de recherche de l'onglet Shopping de TSM.",
    ["Group: TSM, Groups, Import. Quantities are in the search above (recomputed on each click)."] =
      "Groupe : TSM, Groups, Import. Les quantités sont dans la recherche ci-dessus (recalculée à chaque clic).",
    ["TSM group \"%s\": everything bought, delete it in TSM (Groups, right-click)."] =
      "Groupe TSM \"%s\" : tout est acheté, supprime-le dans TSM (Groups, clic droit).",
    ["TSM group \"%s\": replaced by a newer one, delete it in TSM (Groups, right-click)."] =
      "Groupe TSM \"%s\" : remplacé par un plus récent, supprime-le dans TSM (Groups, clic droit).",
    ["Send now"] = "Envoyer maintenant",
    ["Show the step panel next to the profession window."] =
      "Afficher le panneau d'étape à côté de la fenêtre de profession.",
    ["Re-dock"] = "Recoller",
    ["Measured skill-up chances"] = "Chances de skill-up mesurées",
    ["Crafts logged by you and your group correct the Classic formula once a color has enough of them."] =
      "Les crafts enregistrés par toi et ton groupe corrigent la formule Classic dès qu'une couleur en a assez.",
    ["The window"] =
      "La fenêtre",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "À gauche : le groupe, puis chaque perso. Plan = comment monter une profession; Peut crafter = ce que ce perso peut faire pour le groupe. Les puces filtrent par profession.",
    ["Plans"] =
      "Plans",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never. ~ marks a value taken from Classic."] =
      "Chaque étape dit quoi apprendre au maître, quoi crafter d'abord (bolts, barres...) et combien. Clic sur une ligne pour ouvrir la recette, Maj+clic pour la lier. Couleurs : orange donne toujours un point, jaune souvent, vert rarement, gris jamais. ~ marque une valeur reprise de Classic.",
    ["Tooltips"] =
      "Infobulles",
    ["On any material: who in the group needs it, how many, and how soon (now, soon, later). Spare stock in the group is shown too."] =
      "Sur chaque matériau : qui en a besoin dans le groupe, combien, et quand (maintenant, bientôt, plus tard). Le surplus du groupe est affiché aussi.",
    ["Step panel"] =
      "Panneau d'étape",
    ["Next to your profession window: the current step, the chance per craft, how many crafts your bags allow, and what comes next."] =
      "À côté de ta fenêtre de profession : l'étape en cours, la chance par craft, combien de crafts tes sacs permettent, et la suite.",
    ["Giving and mail"] =
      "Donner et courrier",
    ["You can give lists what you hold that others need. At a mailbox, the button beside the send frame attaches it. Nothing is ever sent for you."] =
      "Tu peux donner liste ce que tu as et dont d'autres ont besoin. À la boîte aux lettres, le bouton à côté de l'envoi l'attache. Rien n'est jamais envoyé à ta place.",
    ["Disenchant or keep"] =
      "Désenchanter ou garder",
    ["Your green items: keep one per slot your enchanting plan needs, keep upgrades for group members, sell what is worth more than its mats, disenchant the rest."] =
      "Tes objets verts : garder un par emplacement utile à ton plan d'enchantement, garder les upgrades pour le groupe, vendre ce qui vaut plus que ses mats, désenchanter le reste.",
    ["Shopping"] =
      "Achats",
    ["The Shopping list button makes an Auctionator list, or a TSM search and group to paste. TSM groups that are done are pointed out."] =
      "Le bouton Liste d'achat crée une liste Auctionator, ou une recherche et un groupe TSM à coller. Les groupes TSM terminés sont signalés.",
    ["Sharing"] =
      "Partage",
    ["Nothing is shared until you check a character in Manage group, and only with players you added who added you back."] =
      "Rien n'est partagé tant que tu ne coches pas un perso dans Gérer le groupe, et seulement avec les joueurs que tu as ajoutés et qui t'ont ajouté.",
    ["Better with"] =
      "Encore mieux avec",
    ["TSM or Auctionator (prices), Pawn (upgrades for each class and spec). All optional."] =
      "TSM ou Auctionator (prix), Pawn (upgrades par classe et spé). Tous optionnels.",
    ["Replay the tour"] =
      "Revoir la visite",
    ["Welcome to ComradeCraft"] =
      "Bienvenue dans ComradeCraft",
    ["It answers one question: what should I do with what I have, for the group? 30 seconds to see the main parts."] =
      "Il répond à une question : que faire avec ce que j'ai, pour le groupe? 30 secondes pour voir l'essentiel.",
    ["Your group"] =
      "Ton groupe",
    ["Left: the group overview, the group management, then every character you share or receive."] =
      "À gauche : la vue du groupe, la gestion du groupe, puis chaque perso que tu partages ou reçois.",
    ["Plan and Can craft"] =
      "Plan et Peut crafter",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Choisis un perso : Plan montre comment monter chaque profession étape par étape; Peut crafter montre ce qu'il peut faire pour les autres.",
    ["While you play"] =
      "Pendant que tu joues",
    ["Item tooltips show who needs a material. A step panel opens next to your profession window."] =
      "Les infobulles montrent qui a besoin d'un matériau. Un panneau d'étape s'ouvre à côté de ta fenêtre de profession.",
    ["Sharing is off until you check a box"] = "Le partage est désactivé tant que tu ne coches rien",
    ["Nothing is shared yet. Here, in Manage group, check the box next to each character you want to share under Your characters (on the left of this card). Unchecked characters never leave your computer. Then add your friends below, or accept guildmates who appear there. The ? button explains the rest."] =
      "Rien n'est partagé pour l'instant. Ici, dans Gérer le groupe, coche la case à côté de chaque perso à partager sous Tes persos (à gauche de cette carte). Un perso non coché ne quitte jamais ton ordinateur. Ajoute ensuite tes amis plus bas, ou accepte les guildmates qui y apparaissent. Le bouton ? explique le reste.",
    ["Do not show again"] =
      "Ne plus afficher",
    ["Skip"] =
      "Passer",
    ["Done"] =
      "Terminé",
    ["Next"] =
      "Suivant",
    ["Help"] =
      "Aide",
    ["How ComradeCraft works, in short."] =
      "Comment fonctionne ComradeCraft, en bref.",
    ["Cheapest"] =
      "Moins chère",
    ["Profitable"] =
      "Rentable",
    ["Route:"] =
      "Route :",
    ["Picks recipes whose products sell back well. More crafts, so more mats: tooltips, the give list, mail and shopping all follow this route."] =
      "Choisit les recettes dont les produits se revendent bien. Plus de crafts, donc plus de mats : infobulles, Tu peux donner, courrier et achats suivent cette route.",
    ["Chosen by its owner."] = "Choisi par son propriétaire.",
    ["Spends the least on mats."] =
      "Dépense le moins possible en mats.",
    ["Where to get it: unknown."] =
      "Où l'obtenir : inconnu.",
    ["Where to get it:"] =
      "Où l'obtenir :",
    ["and %d more"] =
      "et %d autres",
    ["Sources taken from another game version, unconfirmed on Forever."] =
      "Sources reprises d'une autre version du jeu, non confirmées sur Forever.",
    ["Install Questie for locations; TomTom for waypoints."] =
      "Installe Questie pour les positions, TomTom pour les points de passage.",
    ["Click: waypoint to the nearest one."] =
      "Clic : point de passage vers le plus proche.",
    ["No known location for %s."] =
      "Aucune position connue pour %s.",
    ["%s: %s. Install TomTom for a waypoint."] =
      "%s : %s. Installe TomTom pour un point de passage.",
    ["Waypoint: %s"] =
      "Point de passage : %s",
    ["Mats per craft:"] = "Mats par craft :",
    ["+%d more"] = "+%d autres",
    ["Recipe and mats"] = "Recette et mats",
    ["For the group"] = "Pour le groupe",
    ["Type"] = "Type",
    ["Mats cost"] = "Coût des mats",
    ["At the trainer - skill %s - %s"] =
      "Chez le maître - compétence %s - %s",
    ["already in your bags"] =
      "déjà dans tes sacs",
    ["Cost by milestone (%s prices)"] =
      "Coût par palier (prix %s)",
    ["Cost by milestone (merchant prices; TSM or Auctionator give AH prices)"] =
      "Coût par palier (prix marchand; TSM ou Auctionator donnent les prix de l'HV)",
    ["Skill %d to %d"] =
      "Compétence %d à %d",
    ["Learn %s"] =
      "Apprendre %s",
    ["Skill"] =
      "Palier",
    ["Route"] =
      "Route",
    ["Mats"] =
      "Mats",
    ["Sold back"] =
      "Revendu",
    ["Net cost"] =
      "Coût net",
    ["nothing"] =
      "rien",
    ["unknown"] =
      "inconnu",
    ["Sold to a merchant"] =
      "Vendu au marchand",
    ["Disenchanted"] =
      "Désenchanté",
    ["At the auction house (-5%)"] =
      "À l'hôtel des ventes (-5 %)",
    ["Best way per item"] =
      "Meilleure option par objet",
    ["Net cost = mats minus the best resale of each item. A green + is a profit. Hover a line for the details."] =
      "Coût net = mats moins la meilleure revente de chaque objet. Un + vert est un profit. Survole une ligne pour le détail.",
    ["Next: %s"] = "Ensuite : %s",
    ["Click to expand."] = "Clique pour déplier.",
    ["Could not start the craft (see /comrade log)."] =
      "Impossible de lancer le craft (voir /comrade log).",
    ["Queue:"] =
      "File :",
    ["up to skill %d (click: this step only)"] =
      "jusqu'à la compétence %d (clic : cette étape seulement)",
    ["this step (click: up to the milestone)"] =
      "cette étape (clic : jusqu'au palier)",
    ["by hand (needs a target)"] =
      "à la main (il faut une cible)",
    ["ready"] =
      "prêt",
    ["%d ready"] =
      "%d prêts",
    ["Craft next: %dx %s"] =
      "Crafter le suivant : %dx %s",
    ["Learn %s first"] =
      "Apprends d'abord %s",
    ["Missing mats for the queue"] =
      "Il manque des mats pour la file",
    ["Nothing to craft"] =
      "Rien à crafter",
    ["%s asks %s to craft %dx %s."] =
      "%s demande à %s de crafter %dx %s.",
    ["Request %dx %s: %s."] =
      "Demande %dx %s : %s.",
    ["Request sent to %s. It is delivered as soon as you are both online."] =
      "Demande envoyée à %s. Elle arrive dès que vous êtes tous les deux en ligne.",
    ["Quantity"] =
      "Quantité",
    ["Note (optional)"] =
      "Note (facultatif)",
    ["Send request"] =
      "Envoyer la demande",
    ["Ask %s to craft %s"] =
      "Demander à %s de crafter %s",
    ["Craft requests"] =
      "Demandes de craft",
    ["%d to answer"] =
      "%d à répondre",
    ["none open"] =
      "aucune en cours",
    ["Ask a group member to craft something, or answer what they asked you."] =
      "Demande un craft à un membre du groupe, ou réponds à ce qu'on t'a demandé.",
    ["Click: ask %s to craft it."] =
      "Clic : demander à %s de le crafter.",
    ["%s for %s"] =
      "%s pour %s",
    ["asked to %s"] =
      "demandé à %s",
    ["waiting to reach the other player"] =
      "en attente de l'autre joueur",
    ["Mats: %s"] =
      "Mats : %s",
    ["your bags allow %d"] =
      "tes sacs en permettent %d",
    ["Accept"] =
      "Accepter",
    ["Decline"] =
      "Refuser",
    ["Cancel request"] =
      "Annuler",
    ["For your characters"] =
      "Pour tes persos",
    ["Your requests"] =
      "Tes demandes",
    ["Accept, craft, then mark it done; the mail helper attaches the item when you write to them."] =
      "Accepte, crafte, puis marque Terminé; l'aide au courrier attache l'objet quand tu lui écris.",
    ["Click a recipe in a group member's Can craft tab to ask for it. Delivered the next time you are both online."] =
      "Clique une recette dans l'onglet Peut crafter d'un membre pour la demander. Livrée la prochaine fois que vous êtes en ligne ensemble.",
    ["pending"] =
      "en attente",
    ["accepted"] =
      "acceptée",
    ["declined"] =
      "refusée",
    ["done"] =
      "terminée",
    ["cancelled"] =
      "annulée",
    ["Shopping list"] =
      "Liste d'achat",
    ["Full plan"] =
      "Plan complet",
    ["Reading the recipes of this profession..."] =
      "Lecture des recettes de cette profession...",
    ["%d%% chance per craft (%s)"] =
      "%d%% de chance par craft (%s)",
    ["Step panel: off"] =
      "Panneau d'étape : désactivé",
    ["Step panel: on (shown with the profession window)"] =
      "Panneau d'étape : activé (affiché avec la fenêtre de profession)",
    ["Click: group needs"] = "Clic : besoins du groupe",
  },
}
ns.Translations = translations

local t = translations[GetLocale and GetLocale() or "enUS"]
if t then
  for k, v in pairs(t) do rawset(L, k, v) end
end

-- "%d member(s)": picks the singular or plural key.
function ns.Plural(n, one, many)
  return (n == 1 and L[one] or L[many]):format(n)
end
