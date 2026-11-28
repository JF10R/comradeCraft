-- esES translations. Keys: the English text (see Locale.lua); loaded only on a esES client.
local _, ns = ...
local loc = GetLocale and GetLocale()
if loc ~= "esES" and loc ~= "esMX" then return end
ns.Translations = ns.Translations or {}
ns.Translations[loc] = {
    ["commands: /comrade (window) | share [off] | list [off] | directory [text] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"] =
      "comandos: /comrade (ventana) | share [off] | list [off] | directory [texto] | add NOMBRE | remove NOMBRE | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NOMBRE | scan | needs | stats | api | audit | log clear",
    ["log cleared"] =
      "registro borrado",
    ["%d lines in the log (written to disk on /reload or logout)"] =
      "%d líneas en el registro (se guarda en disco con /reload o al desconectarte)",
    ["scan ok: %d distinct items in bags"] =
      "escaneo correcto: %d objetos distintos en las bolsas",
    ["DevTools_Dump missing; see WTF\\...\\SavedVariables\\ComradeCraft.lua after /reload"] =
      "falta DevTools_Dump; consulta WTF\\...\\SavedVariables\\ComradeCraft.lua tras /reload",
    ["audit: C_TradeSkillUI.GetAllRecipeIDs missing on this client"] =
      "auditoría: falta C_TradeSkillUI.GetAllRecipeIDs en este cliente",
    ["audit: open a profession window first"] =
      "auditoría: abre primero una ventana de profesión",
    ["  %s (%d): game=%s table=%s [%d/%d]"] =
      "  %s (%d): juego=%s tabla=%s [%d/%d]",
    ["audit rank %d: %d ok, %d mismatches, %d missing from the table"] =
      "auditoría rango %d: %d correctas, %d discrepancias, %d ausentes de la tabla",
    ["LibProfessionDB: %d ok, %d mismatches"] =
      "LibProfessionDB: %d correctas, %d discrepancias",
    ["maxTrivialLevel == grey: %d yes, %d no"] =
      "maxTrivialLevel == gris: %d sí, %d no",
    ["yes"] =
      "sí",
    ["no"] =
      "no",
    ["%d crafts recorded (calibration from %d per color)"] =
      "%d fabricaciones registradas (calibración a partir de %d por color)",
    ["orange"] =
      "naranja",
    ["yellow"] =
      "amarillo",
    ["green"] =
      "verde",
    ["grey"] =
      "gris",
    [" -> factor %.2f applied"] =
      " -> factor %.2f aplicado",
    ["  game color known on %d crafts: our table %d right, LibProfessionDB %d right"] =
      "  color del juego conocido en %d fabricaciones: nuestra tabla acierta %d, LibProfessionDB acierta %d",
    ["needs %d"] =
      "necesita %d",
    ["Group total"] =
      "Total del grupo",
    ["Spare in the group"] =
      "Sobrante en el grupo",
    ["You can give"] =
      "Puedes dar",
    ["Spare items in your bags that others need. With a mailbox open, click one to prepare the mail."] =
      "Objetos sobrantes en tus bolsas que otros necesitan. Con un buzón abierto, haz clic en uno para preparar el correo.",
    ["Mail full (%d attachments): send it, then click again for the rest."] =
      "Correo lleno (%d adjuntos): envíalo y haz clic otra vez para el resto.",
    ["Open a mailbox first."] =
      "Abre primero un buzón.",
    ["Nothing to give to %s."] =
      "Nada que dar a %s.",
    ["Attach what they need"] =
      "Adjuntar lo que necesita",
    ["Type the name of a group member."] =
      "Escribe el nombre de un miembro del grupo.",
    ["You need"] =
      "Necesitas",
    ["Disenchant or keep?"] =
      "¿Desencantar o guardar?",
    ["Green and better items in your bags. Yields are estimates until your disenchants are logged."] =
      "Objetos verdes o mejores en tus bolsas. Los rendimientos son estimados hasta que se registren tus desencantamientos.",
    ["Keep: enchanting target (%s)"] =
      "Guardar: objetivo de encantamiento (%s)",
    ["Keep: gear for %s"] =
      "Guardar: equipo para %s",
    ["Sell: AH %s vs disenchant %s"] =
      "Vender: casa de subastas %s frente a desencantar %s",
    ["Disenchant: %s"] =
      "Desencantar: %s",
    ["the group needs these"] =
      "el grupo lo necesita",
    ["give to %s"] =
      "dar a %s",
    ["group: %d"] =
      "grupo: %d",
    ["now"] =
      "ahora",
    ["soon"] =
      "pronto",
    ["later"] =
      "más tarde",
    ["trainer"] =
      "instructor",
    ["vendor"] =
      "vendedor",
    ["quest"] =
      "misión",
    ["drop"] =
      "botín",
    ["container"] =
      "contenedor",
    ["Gathering profession: levels by gathering, not crafting."] =
      "Profesión de recolección: se sube recolectando, no fabricando.",
    ["Open this profession's window once so your recipes can be read."] =
      "Abre una vez la ventana de esta profesión para poder leer tus recetas.",
    ["No data."] =
      "Sin datos.",
    ["Learn %s at the trainer (skill %s, %s)"] =
      "Aprende %s con el instructor (habilidad %s, %s)",
    ["cost unknown until you visit the trainer"] =
      "coste desconocido hasta que visites al instructor",
    ["Craft %d %s (%s)"] =
      "Fabrica %d %s (%s)",
    ["Craft %dx %s (%s)"] =
      "Fabrica %dx %s (%s)",
    ["%d %s (vendor)"] =
      "%d %s (vendedor)",
    [" + %d from stock"] =
      " + %d ya en reserva",
    ["%d %s from stock"] =
      "%d %s ya en reserva",
    ["With only your current recipes, you would be stuck at %d."] =
      "Solo con tus recetas actuales, te quedarías atascado en %d.",
    ["Uses what you already have: %s."] =
      "Usa lo que ya tienes: %s.",
    ["Buy from a vendor: %s."] =
      "Cómpralo a un vendedor: %s.",
    ["Stuck at %d: all your known recipes are grey (no more points)."] =
      "Atascado en %d: todas tus recetas conocidas son grises (ya no dan puntos).",
    ["Stuck at %d: your known recipes barely give points anymore (%d%% chance per craft at best, %d%% needed)."] =
      "Atascado en %d: tus recetas conocidas casi ya no dan puntos (%d%% de probabilidad por fabricación como máximo, se necesita %d%%).",
    [" To learn: %s."] =
      "Por aprender: %s.",
    [" No recipe to learn found within the next 25 points."] =
      "No se encontró ninguna receta por aprender en los próximos 25 puntos.",
    ["  missing %s x%d"] =
      "  falta %s x%d",
    ["just now"] =
      "ahora mismo",
    ["%d min ago"] =
      "hace %d min",
    ["%d h ago"] =
      "hace %d h",
    ["What to craft:"] =
      "Qué fabricar:",
    ["Owned: %d / %d"] =
      "Tienes: %d / %d",
    ["%d profession"] =
      "%d profesión",
    ["%d professions"] =
      "%d profesiones",
    ["%d member"] =
      "%d miembro",
    ["%d members"] =
      "%d miembros",
    ["Group"] =
      "Grupo",
    ["Plan"] =
      "Plan",
    ["Can craft"] =
      "Puede fabricar",
    ["Lvl %d"] =
      "Niv. %d",
    ["updated %s"] =
      "actualizado %s",
    ["Skill levels and the materials the group still needs. Type to find who can craft something."] =
      "Niveles de habilidad y materiales que aún necesita el grupo. Escribe para buscar quién puede fabricar algo.",
    ["Skill levels"] =
      "Niveles de habilidad",
    ["Most wanted materials"] =
      "Materiales más buscados",
    ["Nothing missing yet."] =
      "Aún no falta nada.",
    ["Who can craft \"%s\""] =
      "Quién puede fabricar \"%s\"",
    ["No recipe matches."] =
      "Ninguna receta coincide.",
    ["No profession data. Open your profession windows."] =
      "Sin datos de profesión. Abre tus ventanas de profesión.",
    ["%d recipe"] =
      "%d receta",
    ["%d recipes"] =
      "%d recetas",
    ["gear for %s"] =
      "equipo para %s",
    ["upgrade for %s (+%d)"] =
      "mejora para %s (+%d)",
    ["Enchant"] =
      "Encantamiento",
    ["Consumable"] =
      "Consumible",
    ["Bag"] =
      "Bolsa",
    ["Weapon"] =
      "Arma",
    ["Armor"] =
      "Armadura",
    ["Reagent"] =
      "Componente",
    ["Other"] =
      "Otro",
    ["via %s"] =
      "vía %s",
    ["Manage group"] =
      "Gestionar grupo",
    ["Choose what you share, and with whom."] =
      "Elige qué compartes y con quién.",
    ["%d player"] =
      "%d jugador",
    ["%d players"] =
      "%d jugadores",
    ["%d request"] =
      "%d solicitud",
    ["%d requests"] =
      "%d solicitudes",
    ["Your characters"] =
      "Tus personajes",
    ["Only checked characters are shared, and only with the players in your group."] =
      "Solo se comparten los personajes marcados, y únicamente con los jugadores de tu grupo.",
    ["Players in your group"] =
      "Jugadores de tu grupo",
    ["They receive your shared characters and you see theirs."] =
      "Reciben tus personajes compartidos y tú ves los suyos.",
    ["Nobody yet."] =
      "Nadie todavía.",
    ["seen %s"] =
      "visto %s",
    ["Remove"] =
      "Quitar",
    ["Requests and suggestions"] =
      "Solicitudes y sugerencias",
    ["Players with ComradeCraft in your guild, or who added you. Add them to share both ways."] =
      "Jugadores de tu hermandad que tienen ComradeCraft, o que te han añadido. Añádelos para compartir en ambos sentidos.",
    ["Add"] =
      "Añadir",
    ["Add a player by name"] =
      "Añadir un jugador por nombre",
    ["For friends outside your guild. They must add you back."] =
      "Para amigos fuera de tu hermandad. Ellos también deben añadirte.",
    ["Options"] =
      "Opciones",
    ["Send a presence signal to the guild at login (no character data)."] =
      "Enviar una señal de presencia a la hermandad al iniciar sesión (sin datos de personajes).",
    ["All"] =
      "Todas",
    ["Hide gathering"] =
      "Ocultar recolección",
    ["No profession matches the filter."] =
      "Ninguna profesión coincide con el filtro.",
    ["%d character"] =
      "%d personaje",
    ["%d characters"] =
      "%d personajes",
    ["Remove from group"] =
      "Quitar del grupo",
    ["sync: sent to the players in your group"] =
      "sinc.: enviado a los jugadores de tu grupo",
    ["%s is shared with your group"] =
      "%s se comparte con tu grupo",
    ["%s is no longer shared"] =
      "%s ya no se comparte",
    ["guild presence signal: on"] =
      "señal de presencia a la hermandad: activada",
    ["guild presence signal: off"] =
      "señal de presencia a la hermandad: desactivada",
    ["Share this character with the group"] =
      "Compartir este personaje con el grupo",
    ["not shared"] =
      "no compartido",
    ["  %s: %d characters, %s"] =
      "  %s: %d personajes, %s",
    ["in the group"] =
      "en el grupo",
    ["wants to join"] =
      "quiere unirse",
    ["suggested"] =
      "sugerido",
    ["no peer seen yet (they need ComradeCraft)"] =
      "aún no se ha visto a nadie (necesita ComradeCraft)",
    ["%s added to the group"] =
      "%s añadido al grupo",
    ["%s contacted; added as soon as they answer"] =
      "%s contactado; se añadirá en cuanto responda",
    ["%s removed from the group"] =
      "%s quitado del grupo",
    ["Could not create the Auctionator list (see /comrade log)."] =
      "No se pudo crear la lista de Auctionator (consulta /comrade log).",
    ["Nothing to buy for %s."] =
      "Nada que comprar para %s.",
    ["Auctionator list \"ComradeCraft: %s\" created: %d items. Open the Shopping tab at the auction house."] =
      "Lista de Auctionator \"ComradeCraft: %s\" creada: %d objetos. Abre la pestaña Shopping en la casa de subastas.",
    ["%d not cached yet; try again in a moment."] =
      "%d aún no están en caché; inténtalo de nuevo en un momento.",
    ["Nothing to buy."] =
      "Nada que comprar.",
    ["Step panel hidden. /comrade tracker shows it again."] =
      "Panel de pasos oculto. /comrade tracker lo vuelve a mostrar.",
    ["TSM shopping (Ctrl+C to copy)"] =
      "Compras de TSM (Ctrl+C para copiar)",
    ["Search: paste in the search box of TSM's Shopping tab."] =
      "Búsqueda: pégala en el cuadro de búsqueda de la pestaña Shopping de TSM.",
    ["Group: TSM, Groups, Import. Quantities are in the search above (recomputed on each click)."] =
      "Grupo: TSM, Groups, Import. Las cantidades están en la búsqueda de arriba (se recalculan en cada clic).",
    ["TSM group \"%s\": everything bought, delete it in TSM (Groups, right-click)."] =
      "Grupo de TSM \"%s\": todo comprado, bórralo en TSM (Groups, clic derecho).",
    ["TSM group \"%s\": replaced by a newer one, delete it in TSM (Groups, right-click)."] =
      "Grupo de TSM \"%s\": sustituido por uno más reciente, bórralo en TSM (Groups, clic derecho).",
    ["Send now"] =
      "Enviar ahora",
    ["Show the step panel next to the profession window."] =
      "Mostrar el panel de pasos junto a la ventana de profesión.",
    ["Re-dock"] =
      "Reanclar",
    ["Measured skill-up chances"] =
      "Probabilidades de subida medidas",
    ["The window"] =
      "La ventana",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "A la izquierda: el grupo y luego cada personaje. Plan = cómo subir una profesión; Puede fabricar = lo que ese personaje puede hacer para el grupo. Los filtros separan por profesión.",
    ["Plans"] =
      "Planes",
    ["Tooltips"] =
      "Descripciones emergentes",
    ["On any material: who in the group needs it, how many, and how soon (now, soon, later). Spare stock in the group is shown too."] =
      "En cualquier material: quién del grupo lo necesita, cuántos y para cuándo (ahora, pronto, más tarde). También se muestra el sobrante del grupo.",
    ["Step panel"] =
      "Panel de pasos",
    ["Next to your profession window: the current step, the chance per craft, how many crafts your bags allow, and what comes next."] =
      "Junto a tu ventana de profesión: el paso actual, la probabilidad por fabricación, cuántas fabricaciones permiten tus bolsas y lo que viene después.",
    ["Giving and mail"] =
      "Dar y correo",
    ["You can give lists what you hold that others need. At a mailbox, the button beside the send frame attaches it. Nothing is ever sent for you."] =
      "«Puedes dar» enumera lo que tienes y otros necesitan. En un buzón, el botón junto al envío lo adjunta. Nunca se envía nada por ti.",
    ["Disenchant or keep"] =
      "Desencantar o guardar",
    ["Your green items: keep one per slot your enchanting plan needs, keep upgrades for group members, sell what is worth more than its mats, disenchant the rest."] =
      "Tus objetos verdes: guarda uno por ranura que necesite tu plan de encantamiento, guarda las mejoras para el grupo, vende lo que valga más que sus materiales y desencanta el resto.",
    ["Shopping"] =
      "Compras",
    ["The Shopping list button makes an Auctionator list, or a TSM search and group to paste. TSM groups that are done are pointed out."] =
      "El botón Lista de compras crea una lista de Auctionator, o una búsqueda y un grupo de TSM para pegar. Se señalan los grupos de TSM ya completados.",
    ["Sharing"] =
      "Compartir",
    ["Nothing is shared until you check a character in Manage group, and only with players you added who added you back."] =
      "No se comparte nada hasta que marques un personaje en Gestionar grupo, y solo con jugadores que hayas añadido y que te hayan añadido a ti.",
    ["Better with"] =
      "Mejor con",
    ["Replay the tour"] =
      "Repetir el tutorial",
    ["Welcome to ComradeCraft"] =
      "Bienvenido a ComradeCraft",
    ["It answers one question: what should I do with what I have, for the group? 30 seconds to see the main parts."] =
      "Responde a una pregunta: ¿qué hago con lo que tengo, por el grupo? 30 segundos para ver lo principal.",
    ["Your group"] =
      "Tu grupo",
    ["Plan and Can craft"] =
      "Plan y Puede fabricar",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Elige un personaje: Plan muestra cómo subir cada profesión paso a paso; Puede fabricar muestra lo que puede hacer para otros.",
    ["While you play"] =
      "Mientras juegas",
    ["Sharing is off until you check a box"] =
      "No se comparte nada hasta que marques una casilla",
    ["Do not show again"] =
      "No volver a mostrar",
    ["Skip"] =
      "Omitir",
    ["Done"] =
      "Hecho",
    ["Next"] =
      "Siguiente",
    ["Help"] =
      "Ayuda",
    ["How ComradeCraft works, in short."] =
      "Cómo funciona ComradeCraft, en breve.",
    ["Cheapest"] =
      "Más barata",
    ["Profitable"] =
      "Rentable",
    ["Route:"] =
      "Ruta:",
    ["Picks recipes whose products sell back well. More crafts, so more mats: tooltips, the give list, mail and shopping all follow this route."] =
      "Elige recetas cuyos productos se revenden bien. Más fabricaciones, y por tanto más materiales: las descripciones, la lista de Puedes dar, el correo y las compras siguen esta ruta.",
    ["Chosen by its owner."] =
      "Elegida por su dueño.",
    ["Spends the least on mats."] =
      "Gasta lo mínimo en materiales.",
    ["Where to get it: unknown."] =
      "Dónde conseguirla: desconocido.",
    ["Where to get it:"] =
      "Dónde conseguirla:",
    ["and %d more"] =
      "y %d más",
    ["Install Questie for locations; TomTom for waypoints."] =
      "Instala Questie para las ubicaciones y TomTom para los puntos de ruta.",
    ["Click: waypoint to the nearest one."] =
      "Clic: punto de ruta al más cercano.",
    ["No known location for %s."] =
      "Ninguna ubicación conocida para %s.",
    ["%s: %s. Install TomTom for a waypoint."] =
      "%s: %s. Instala TomTom para un punto de ruta.",
    ["Waypoint: %s"] =
      "Punto de ruta: %s",
    ["Mats per craft:"] =
      "Materiales por fabricación:",
    ["+%d more"] =
      "+%d más",
    ["Recipe and mats"] =
      "Receta y materiales",
    ["For the group"] =
      "Para el grupo",
    ["Type"] =
      "Tipo",
    ["Mats cost"] =
      "Coste de mats",
    ["At the trainer - skill %s - %s"] =
      "Con el instructor - habilidad %s - %s",
    ["already in your bags"] =
      "ya en tus bolsas",
    ["Cost by milestone (%s prices)"] =
      "Coste por hito (precios de %s)",
    ["Cost by milestone (merchant prices; TSM or Auctionator give AH prices)"] =
      "Coste por hito (precios de vendedor; TSM o Auctionator dan los de la casa de subastas)",
    ["Skill %d to %d"] =
      "Habilidad %d a %d",
    ["Learn %s"] =
      "Aprender %s",
    ["Skill"] =
      "Habilidad",
    ["Route"] =
      "Ruta",
    ["Mats"] =
      "Mats",
    ["Sold back"] =
      "Reventa",
    ["Net cost"] =
      "Coste neto",
    ["nothing"] =
      "nada",
    ["unknown"] =
      "desconocido",
    ["Sold to a merchant"] =
      "Vendido a un vendedor",
    ["Disenchanted"] =
      "Desencantado",
    ["At the auction house (-5%, deposit risk)"] =
      "En la casa de subastas (-5 %, riesgo de depósito)",
    ["Best way per item"] =
      "Mejor opción por objeto",
    ["Net cost = mats minus the best resale of each item. A green + is a profit. Hover a line for the details."] =
      "Coste neto = materiales menos la mejor reventa de cada objeto. Un + verde es ganancia. Pasa el cursor por una línea para ver el detalle.",
    ["Next: %s"] =
      "Siguiente: %s",
    ["Click to expand."] =
      "Haz clic para expandir.",
    ["Could not start the craft (see /comrade log)."] =
      "No se pudo iniciar la fabricación (consulta /comrade log).",
    ["Queue:"] =
      "Cola:",
    ["up to skill %d (click: this step only)"] =
      "hasta habilidad %d (clic: solo este paso)",
    ["this step (click: up to the milestone)"] =
      "este paso (clic: hasta el hito)",
    ["by hand (needs a target)"] =
      "a mano (necesita un objetivo)",
    ["ready"] =
      "listo",
    ["%d ready"] =
      "%d listos",
    ["Craft next: %dx %s"] =
      "Fabricar siguiente: %dx %s",
    ["Learn %s first"] =
      "Aprende %s primero",
    ["Missing mats for the queue"] =
      "Faltan materiales para la cola",
    ["Nothing to craft"] =
      "Nada que fabricar",
    ["%s asks %s to craft %dx %s."] =
      "%s pide a %s que fabrique %dx %s.",
    ["Request %dx %s: %s."] =
      "Solicitar %dx %s: %s.",
    ["Request sent to %s. It is delivered as soon as you are both online."] =
      "Solicitud enviada a %s. Se entregará en cuanto los dos estéis conectados.",
    ["Quantity"] =
      "Cantidad",
    ["Note (optional)"] =
      "Nota (opcional)",
    ["Send request"] =
      "Enviar solicitud",
    ["Ask %s to craft %s"] =
      "Pedir a %s que fabrique %s",
    ["Craft requests"] =
      "Solicitudes de fabricación",
    ["%d to answer"] =
      "%d por responder",
    ["none open"] =
      "ninguna abierta",
    ["Ask a group member to craft something, or answer what they asked you."] =
      "Pide a un miembro del grupo que fabrique algo, o responde a lo que te hayan pedido.",
    ["Click: ask %s to craft it."] =
      "Clic: pedir a %s que lo fabrique.",
    ["%s for %s"] =
      "%s para %s",
    ["asked to %s"] =
      "pedido a %s",
    ["waiting to reach the other player"] =
      "esperando al otro jugador",
    ["Mats: %s"] =
      "Mats: %s",
    ["your bags allow %d"] =
      "tus bolsas permiten %d",
    ["Accept"] =
      "Aceptar",
    ["Decline"] =
      "Rechazar",
    ["Cancel request"] =
      "Cancelar",
    ["For your characters"] =
      "Para tus personajes",
    ["Your requests"] =
      "Tus solicitudes",
    ["Accept, craft, then mark it done; the mail helper attaches the item when you write to them."] =
      "Acepta, fabrica y luego márcala como hecha; el ayudante de correo adjunta el objeto cuando les escribes.",
    ["Click a recipe in a group member's Can craft tab to ask for it. Delivered the next time you are both online."] =
      "Haz clic en una receta en la pestaña Puede fabricar de un miembro para pedirla. Se entrega la próxima vez que los dos estéis conectados.",
    ["pending"] =
      "pendiente",
    ["accepted"] =
      "aceptada",
    ["declined"] =
      "rechazada",
    ["done"] =
      "hecha",
    ["cancelled"] =
      "cancelada",
    ["(by mail)"] =
      "(por correo)",
    ["Request mail ready: check it and click Send."] =
      "Correo de solicitud listo: revísalo y haz clic en Enviar.",
    ["By mail"] =
      "Por correo",
    ["Craft requests by mail too: for players who are never online at the same time (you send the mail yourself, 30c postage)."] =
      "También solicitudes de fabricación por correo: para jugadores que nunca coinciden conectados (tú envías el correo, 30 de cobre de franqueo).",
    ["other profession"] =
      "otra profesión",
    ["Routes"] =
      "Rutas",
    ["Each character picks Cheapest (least spent on mats) or Profitable (products sold back). The milestone table compares both: mats, what the products bring back (merchant, disenchant or AH) and the net cost."] =
      "Cada personaje elige Más barata (lo mínimo en materiales) o Rentable (productos revendidos). La tabla por hito compara ambas: materiales, lo que devuelven los productos (vendedor, desencantado o casa de subastas) y el coste neto.",
    ["Learning recipes"] =
      "Aprender recetas",
    ["Hover a Learn line for its trainers, vendors and drops; click it for a TomTom waypoint (with Questie installed for positions)."] =
      "Pasa el cursor por una línea Aprender para ver sus instructores, vendedores y botines; haz clic para un punto de TomTom (con Questie instalado para las posiciones).",
    ["Craft queue"] =
      "Cola de fabricación",
    ["In the step panel: the crafts of this step or of the whole milestone, what your bags allow, and Craft next (one batch per click, the game needs a click per craft)."] =
      "En el panel de pasos: las fabricaciones de este paso o de todo el hito, lo que permiten tus bolsas y Fabricar siguiente (un lote por clic; el juego exige un clic por fabricación).",
    ["Click a recipe in a group member's Can craft tab to ask for it. Answer what you are asked in Craft requests. Requests reach the other player the next time you are both online (or by mail, if turned on in Manage group)."] =
      "Haz clic en una receta en la pestaña Puede fabricar de un miembro para pedirla. Responde a lo que te pidan en Solicitudes de fabricación. Las solicitudes llegan al otro jugador la próxima vez que los dos estéis conectados (o por correo, si se activa en Gestionar grupo).",
    ["%s: mats ready"] =
      "%s: materiales listos",
    ["Your bags hold everything for %dx %s."] =
      "Tus bolsas contienen todo para %dx %s.",
    ["Cooldown ready: %s"] =
      "Reutilización lista: %s",
    ["on %s"] =
      "en %s",
    ["+%d with Pawn"] =
      "+%d con Pawn",
    ["+%d item levels"] =
      "+%d niveles de objeto",
    ["%s can craft an upgrade for you"] =
      "%s puede fabricarte una mejora",
    ["Ask for it"] =
      "Pedirlo",
    ["Not interested"] =
      "No me interesa",
    ["New craft request"] =
      "Nueva solicitud de fabricación",
    ["Open"] =
      "Abrir",
    ["Alerts"] =
      "Alertas",
    ["A chat line and a short notice at the top of the screen."] =
      "Una línea en el chat y un breve aviso en la parte superior de la pantalla.",
    ["Your bags hold the mats for your next craft."] =
      "Tus bolsas tienen los materiales para tu próxima fabricación.",
    ["A profession cooldown is ready on one of your characters."] =
      "Una reutilización de profesión está lista en uno de tus personajes.",
    ["A craft request arrives or changes."] =
      "Llega o cambia una solicitud de fabricación.",
    ["A group member can craft an upgrade for you (off by default)."] =
      "Un miembro del grupo puede fabricarte una mejora (desactivado por defecto).",
    ["visited"] =
      "visitado",
    ["Next rank: %s (%d to %d)"] =
      "Siguiente rango: %s (%d a %d)",
    ["Journeyman"] =
      "Oficial",
    ["Expert"] =
      "Experto",
    ["Artisan"] =
      "Artesano",
    ["Master"] =
      "Maestro",
    ["skill %d"] =
      "habilidad %d",
    ["level %d"] =
      "nivel %d",
    ["sold by %s"] =
      "vendido por %s",
    ["or at the AH (~%s)"] =
      "o en la casa de subastas (~%s)",
    ["or at the AH"] =
      "o en la casa de subastas",
    ["At the cap (%d)."] =
      "En el máximo (%d).",
    ["Looking for the quest in Questie..."] =
      "Buscando la misión en Questie...",
    ["This rank comes from a quest (install Questie to find it)."] =
      "Este rango se obtiene con una misión (instala Questie para encontrarla).",
    ["starts at %s"] =
      "empieza en %s",
    ["Quest: %s"] =
      "Misión: %s",
    ["Quests that need %d in this skill; the rank quest is among them."] =
      "Misiones que requieren %d en esta habilidad; la misión de rango es una de ellas.",
    ["Click: waypoint to the quest giver."] =
      "Clic: punto de ruta al dador de la misión.",
    ["Shopping list"] =
      "Lista de compras",
    ["Full plan"] =
      "Plan completo",
    ["Reading the recipes of this profession..."] =
      "Leyendo las recetas de esta profesión...",
    ["%d%% chance per craft (%s)"] =
      "%d%% de probabilidad por fabricación (%s)",
    ["Step panel: off"] =
      "Panel de pasos: desactivado",
    ["Step panel: on (shown with the profession window)"] =
      "Panel de pasos: activado (se muestra con la ventana de profesión)",
    ["Keep for your group"] =
      "Guárdalo para tu grupo",
    ["%s: %d for %s"] =
      "%s: %d para %s",
    ["and %d more"] =
      "y %d más",
    ["You sold %s"] =
      "Has vendido %s",
    ["Buy back"] =
      "Recomprar",
    ["you"] =
      "ti",
    ["At a merchant or the auction house: items in your bags that your group needs."] =
      "En un vendedor o la casa de subastas: objetos de tus bolsas que tu grupo necesita.",
    ["Next rank"] =
      "Siguiente rango",
    ["At the skill cap: the Expert book (vendor or AH), the Artisan quest found in Questie (click for a waypoint to its giver), or the trainer."] =
      "En el máximo de habilidad: el libro de Experto (vendedor o subasta), la misión de Artesano de Questie (clic: punto de ruta a quien la da) o el instructor.",
    ["Mats ready, profession cooldowns ready on any of your characters, craft requests, items your group needs when you open a merchant or the AH (with Buy back after a sale), and opt-in upgrades. Each one can be turned off in Manage group."] =
      "Materiales listos, reutilizaciones de profesión listas en cualquiera de tus personajes, solicitudes de fabricación, objetos que tu grupo necesita al abrir un vendedor o la subasta (con Recomprar tras una venta) y mejoras opcionales. Cada una se desactiva en Gestionar grupo.",
    ["TSM or Auctionator (prices), Questie (positions), TomTom (waypoints), Pawn (upgrades for each class and spec). All optional."] =
      "TSM o Auctionator (precios), Questie (posiciones), TomTom (puntos de ruta), Pawn (mejoras para cada clase y especialización). Todos opcionales.",
    -- Group plan
    ["Spare"] =
      "Sobrante",
    ["Group plan"] =
      "Plan de grupo",
    ["What the group still needs, what it already holds, and who farms what."] =
      "Lo que aún le falta al grupo, lo que ya tiene y quién farmea qué.",
    ["Objective:"] =
      "Objetivo:",
    ["Lowest group cost"] =
      "Menor coste de grupo",
    ["Market value"] =
      "Valor de mercado",
    ["Least gold spent by the group: stock already held in the group counts as free."] =
      "El menor oro gastado por el grupo: el stock que ya tiene el grupo cuenta como gratis.",
    ["Every material at its market value, as if each character were alone."] =
      "Cada material a su valor de mercado, como si cada personaje estuviera solo.",
    ["Material"] =
      "Material",
    ["Needed"] =
      "Necesario",
    ["To get"] =
      "Por conseguir",
    ["Est. cost"] =
      "Coste est.",
    ["Farming"] =
      "Farmeo",
    ["Farmed by %s"] =
      "Farmeado por %s",
    ["Drop"] =
      "Abandonar",
    ["I'll farm it"] =
      "Yo lo farmeo",
    ["Estimated cost for the group: %s"] =
      "Coste estimado para el grupo: %s",
    ["Estimated cost for the group: at least %s (some items have no price)."] =
      "Coste estimado para el grupo: al menos %s (algunos objetos no tienen precio).",
    ["Estimated cost for the group: unknown (TSM or Auctionator give AH prices)."] =
      "Coste estimado para el grupo: desconocido (TSM o Auctionator dan precios de subasta).",
    ["%d %s needed for %s. Do you want to farm them?"] =
      "%d %s necesarios para %s. ¿Quieres farmearlos?",
    ["Farming done: %s"] =
      "Farmeo terminado: %s",
    ["Give them from You can give in the Group view, or by mail."] =
      "Dalos desde Puedes dar en la vista Grupo, o por correo.",
    ["Show the farming tracker (your farming assignments from the Group plan)."] =
      "Mostrar el seguimiento de farmeo (tus tareas de farmeo del Plan de grupo).",
    ["Plans count stock already held in the group as free (or every mat at market value: Manage group > Options). The Group plan view lists what the group still needs and its cost; take a material with I'll farm it and a small tracker follows your progress."] =
      "Los planes cuentan como gratis el stock que ya tiene el grupo (o cada material a su valor de mercado: Gestionar grupo > Opciones). La vista Plan de grupo lista lo que aún le falta al grupo y su coste; toma un material con Yo lo farmeo y un pequeño seguimiento muestra tu progreso.",
    ["Guild directory"] =
      "Directorio de hermandad",
    ["%d crafter"] =
      "%d artesano",
    ["%d crafters"] =
      "%d artesanos",
    ["Right box: list the character in the guild directory (professions and recipes only, sent to your guild)."] =
      "Casilla derecha: inscribir al personaje en el directorio de hermandad (solo profesiones y recetas, enviadas a tu hermandad).",
    ["List in guild directory"] =
      "Inscribir en el directorio de hermandad",
    ["Opt-in, per character: List in guild directory in Manage group (or /comrade list) sends its professions and recipes to guildmates who use ComradeCraft. Search who can craft an item, whisper them, or ask for the craft if they are in your group. Item tooltips name up to 3 guild crafters."] =
      "Opcional, por personaje: Inscribir en el directorio de hermandad, en Gestionar grupo (o /comrade list), envía sus profesiones y recetas a los miembros de tu hermandad que usan ComradeCraft. Busca quién puede fabricar un objeto, susúrrale o pídele que lo fabrique si está en tu grupo. Las descripciones de objetos muestran hasta 3 artesanos de la hermandad.",
    ["Whisper"] =
      "Susurrar",
    ["Nobody is listed yet. The directory is opt-in: each player lists their own characters in Manage group (List in guild directory) or with /comrade list."] =
      "Todavía no hay nadie inscrito. El directorio es opcional: cada jugador inscribe sus propios personajes en Gestionar grupo (Inscribir en el directorio de hermandad) o con /comrade list.",
    ["Type a product or recipe name in the search box."] =
      "Escribe el nombre de un objeto o una receta en el cuadro de búsqueda.",
    ["No crafter found."] =
      "No se encontró ningún artesano.",
    ["... and %d more"] =
      "... y %d más",
    ["Who in your guild can craft what. Each player lists their own characters (opt-in)."] =
      "Quién de tu hermandad puede fabricar qué. Cada jugador inscribe sus propios personajes (opcional).",
    ["Guild crafters: %s"] =
      "Artesanos de la hermandad: %s",
    ["%s is listed in the guild directory"] =
      "%s está inscrito en el directorio de hermandad",
    ["%s is no longer listed in the guild directory"] =
      "%s ya no está inscrito en el directorio de hermandad",
    ["You are not in a guild: the entry is sent once you are."] =
      "No estás en una hermandad: la inscripción se enviará cuando estés en una.",
    ["directory: %d characters listed. /comrade directory TEXT searches them."] =
      "directorio: %d personajes inscritos. /comrade directory TEXTO busca entre ellos.",
    ["directory: no crafter for %s"] =
      "directorio: ningún artesano para %s",
    -- UI polish, bags, mail & friends
    ["%d item"] = "%d objeto",
    ["%d items"] = "%d objetos",
    ["Add %s"] = "Añadir a %s",
    ["Add target"] = "Añadir objetivo",
    ["Cancel"] = "Cancelar",
    ["Click a member to highlight their items."] = "Haz clic en un miembro para resaltar sus objetos.",
    ["Click to select recipient and highlight needed items in your bags."] =
      "Haz clic para elegir destinatario y resaltar en tus bolsas lo que necesita.",
    ["Collapse all"] = "Contraer todo",
    ["ComradeCraft: Add to group"] = "ComradeCraft: Añadir al grupo",
    ["Expand all"] = "Expandir todo",
    ["Filter recipes..."] = "Filtrar recetas...",
    ["Search stock or crafters..."] = "Buscar stock o artesanos...",
    ["For %s"] = "Para %s",
    ["Friend"] = "Amigo",
    ["Guild"] = "Hermandad",
    ["Highlight items for your group in your bags (and focus a recipient's items when mailing)."] =
      "Resaltar en tus bolsas los objetos para tu grupo (y enfocar los del destinatario al enviar correo).",
    ["Highlighted in your bags"] = "Resaltado en tus bolsas",
    ["Nothing to send from your bags."] = "Nada que enviar desde tus bolsas.",
    ["Online in your party, friends or guild:"] = "Conectados en tu grupo, amigos o hermandad:",
    ["Party"] = "Grupo",
    ["Ready to send from your bags"] = "Listo para enviar desde tus bolsas",
    ["Retry"] = "Reintentar",
    ["Search guild crafters..."] = "Buscar artesanos...",
    ["Send x%d to %s"] = "Enviar x%d a %s",
    ["Send x%d to %s (%s)"] = "Enviar x%d a %s (%s)",
    ["To send from your bags: %s"] = "Para enviar de tus bolsas: %s",
    ["You cannot add yourself."] = "No puedes añadirte a ti mismo.",
    ["craft request"] = "solicitud de fabricación",
    ["waiting for reply"] = "esperando respuesta",
    ["Share all"] = "Compartir todos",
    ["Unshare all"] = "Dejar de compartir",
    ["Automatically share new characters on this account"] =
      "Compartir automáticamente los nuevos personajes de esta cuenta",
    ["All characters (%d) are now shared with your group"] =
      "Todos los personajes (%d) ahora se comparten con tu grupo",
    ["No character is shared anymore"] = "Ya no se comparte ningún personaje",
    ["%s requires higher %s skill; skipped for waypoints until you level up."] =
      "%s requiere mayor habilidad en %s; omitido para los puntos de ruta hasta que subas.",
    ["Right-click: skip this recipe and recalculate."] =
      "Clic derecho: omitir esta receta y recalcular.",
    ["Reset skipped (%d)"] = "Restablecer omitidas (%d)",
    -- Trade, Merchant, Wishlist, Cooldowns & UI rework
    ["%d tracked"] = "%d en seguimiento",
    ["%s wants to join your group"] = "%s quiere unirse a tu grupo",
    ["Accept to share your checked characters with them."] =
      "Acepta para compartir tus personajes marcados con ellos.",
    ["Add to wishlist"] = "Añadir a la lista",
    ["All materials are in your bags."] = "Todos los materiales están en tus bolsas.",
    ["Buy plan reagents (%s)"] = "Comprar componentes (%s)",
    ["Click to sync now with your group."] = "Haz clic para sincronizar ahora con tu grupo.",
    ["Compare routes"] = "Comparar rutas",
    ["Craft"] = "Fabricar",
    ["Disenchant"] = "Desencantar",
    ["For who:"] = "Para quién:",
    ["Group cooldowns"] = "Reutilizaciones del grupo",
    ["Hide route comparison"] = "Ocultar comparación",
    ["Ignore"] = "Ignorar",
    ["Materials"] = "Materiales",
    ["No craft pinned yet. Right-click any recipe in your Can craft tab to add it here, track its materials and get notified when ready."] =
      "Ninguna fabricación fijada. Haz clic derecho en una receta en Puede fabricar para añadirla aquí, seguir sus materiales y recibir aviso cuando esté lista.",
    ["No disenchantable items in your bags."] = "No hay objetos desencantables en tus bolsas.",
    ["Not enough gold (%s needed)."] = "No hay suficiente oro (hacen falta %s).",
    ["Note (optional):"] = "Nota (opcional):",
    ["Overview"] = "Resumen",
    ["Pin"] = "Fijar",
    ["Pin on screen"] = "Fijar en pantalla",
    ["Pinned crafts to track materials for yourself or friends."] =
      "Fabricaciones fijadas para seguir los materiales para ti o tus amigos.",
    ["Place needed items"] = "Colocar lo necesario",
    ["Plan reagents"] = "Componentes del plan",
    ["Quantity:"] = "Cantidad:",
    ["Ready"] = "Listo",
    ["Ready (some mats in bank/mail)"] = "Listo (mats en banco/correo)",
    ["Ready to craft!"] = "¡Listo para fabricar!",
    ["Right-click: add to Wishlist."] = "Clic derecho: añadir a la lista de deseos.",
    ["Show the wishlist tracker on screen (pinned crafts)."] =
      "Mostrar el seguimiento de la lista de deseos en pantalla.",
    ["Trade window is full (%d slots)."] = "La ventana de comercio está llena (%d espacios).",
    ["Unpin"] = "Desfijar",
    ["Wishlist"] = "Lista de deseos",
    ["Wishlist ready: %dx %s"] = "Listo para fabricar: %dx %s",
    ["none pinned"] = "ninguno fijado",
    -- Synergies, Audit, Loot, AH Panel, Buy vs Farm
    ["%d small bags (min %d slots) -> %s (%d slots)"] = "%d bolsas pequeñas (mín. %d cas.) -> %s (%d cas.)",
    ["%s can craft %dx %s from group's %s for %s"] = "%s puede fabricar %dx %s con %s del grupo para %s",
    ["Advice"] = "Consejo",
    ["Back"] = "Espalda",
    ["Buy"] = "Comprar",
    ["Buy/Farm"] = "Compra/Farm",
    ["Chest"] = "Pecho",
    ["Click an item to search it."] = "Haz clic en un objeto para buscarlo.",
    ["Click: search in Auction House."] = "Clic: buscar en la Casa de Subastas.",
    ["Click: waypoint to farm spot."] = "Clic: punto de ruta a la zona de farmeo.",
    ["Cross-profession links between your group's active plans."] =
      "Sinergias entre profesiones en los planes activos del grupo.",
    ["Disenchant %dx %s (%s)"] = "Desencantar %dx %s (%s)",
    ["Disenchant for your enchanting plan"] = "Desencantar para tu plan de encantamiento",
    ["Everyone's bags, enchants and gear are up to date."] =
      "Las bolsas, encantamientos y equipo del grupo están al día.",
    ["Farm"] = "Farmear",
    ["Farm %s: %s (%s %d, %d)"] = "Farmear %s: %s (%s %d, %d)",
    ["Farm spot"] = "Zona de farmeo",
    ["Feet"] = "Pies",
    ["Gear"] = "Equipo",
    ["Gold: %s"] = "Oro: %s",
    ["Group synergies"] = "Sinergias del grupo",
    ["Group upgrades"] = "Mejoras del grupo",
    ["Hands"] = "Manos",
    ["Known by %s"] = "Conocido por %s",
    ["Loot roll: %s - needed now by %s"] = "Botín: %s - necesario ahora para %s",
    ["Loot roll: %s - unknown by %s"] = "Botín: %s - desconocido por %s",
    ["No known farm location for %s."] = "No se conoce zona de farmeo para %s.",
    ["Send %dx %s to %s to disenchant (%s)"] = "Enviar %dx %s a %s para desencantar (%s)",
    ["Send to %s to disenchant"] = "Enviar a %s para desencantar",
    ["Shield"] = "Escudo",
    ["Small bags, unenchanted gear and craftable upgrades your group can make."] =
      "Bolsas pequeñas, equipo sin encantar y mejoras que tu grupo puede fabricar.",
    ["To buy at the AH"] = "Para comprar en subasta",
    ["Total: %s (you have %s)"] = "Total: %s (tienes %s)",
    ["Unenchanted %s -> %s"] = "%s sin encantar -> %s",
    ["Unknown by %s (%s %d/%d)"] = "Desconocido por %s (%s %d/%d)",
    ["Upgrades"] = "Mejoras",
    ["Vendor"] = "Vendedor",
    ["Waypoint: %s (%s %d, %d)"] = "Punto de ruta: %s (%s %d, %d)",
    ["Wrist"] = "Muñecas",
    ["Your gold: %s"] = "Tu oro: %s",
    ["by %s"] = "por %s",
    ["by %s (guild)"] = "por %s (hermandad)",
    ["can learn now"] = "aprendible ahora",
    ["needs skill %d"] = "requiere %d",
    ["+%d score"] = "+%d puntuación",
    ["Head"] = "Cabeza",
    ["Neck"] = "Cuello",
    ["Shoulder"] = "Hombros",
    ["Waist"] = "Cintura",
    ["Legs"] = "Piernas",
    ["Finger"] = "Dedo",
    ["Trinket"] = "Abalorio",
    ["Off-Hand"] = "Mano izq.",
    ["Ranged"] = "A distancia",
    ["Spec: %s"] = "Esp: %s",
    ["Spec set to %s."] = "Especialización ajustada a %s.",
    ["Unknown spec. Available: %s"] = "Especialización desconocida. Disponibles: %s",
    ["Crafts upgrade for: %s"] = "Fabrica mejora para: %s",
    ["Useful enchant for: %s"] = "Encantamiento útil para: %s",
    ["Leveling plan"] = "Plan de subida",
    ["Upgrade for %s (%s)"] = "Mejora para %s (%s)",
    ["Good enchant for %s"] = "Buen encantamiento para %s",
    ["Click to train."] = "Clic para aprender.",
    ["Recommended recipes"] = "Recetas recomendadas",
    ["mats ready"] = "mats listos",
    ["Soon (+1-4 lvl)"] = "Pronto (+1-4 nv.)",
    ["Consumables"] = "Consumibles",
    ["Patterns to hunt"] = "Patrones a buscar",
    ["Waypoint"] = "Ruta",
    ["Group materials:"] = "Materiales del grupo:",
    ["%d mobs"] = "%d enemigos",
    ["1 mob"] = "1 enemigo",
    ["in bank"] = "en el banco",
    ["In bank (retrieve first)"] = "En el banco (retíralo primero)",
    ["Full name (First Last) required for %s: log them in once or type their full name first."] =
      "Se requiere nombre completo (Nombre Apellido) para %s: conéctalo una vez o escribe su nombre completo primero.",
    ["Withdraw from bank"] = "Retirar del banco",
    ["Withdraw needed"] = "Retirar lo necesario",
    ["Click an item to withdraw it."] = "Haz clic en un objeto para retirarlo.",
    ["Your bags are full."] = "Tus bolsas están llenas.",
    ["For your plan"] = "Para tu plan",
    ["To send to %s"] = "Para enviar a %s",
    ["Right-click: %dx %s -> %dx %s"] = "Clic derecho: %dx %s -> %dx %s",
    ["BoE patterns"] = "Patrones BoE",
    ["Share in chat"] = "Compartir en chat",
    ["Shared bank alt"] = "Alter banco compartido",
    ["Shared bank alt: all items on this character (bags, bank, mail) appear as available to your group, and members can request them via the addon."] = "Alter banco compartido: todos los objetos de este personaje (bolsas, banco, correo) aparecen disponibles para tu grupo y todos pueden pedirlos desde el addon.",
    ["Bank"] = "Banco",
    ["Ask %s for %s"] = "Pedir a %s: %s",
    ["%s asks %s for %dx %s."] = "%s pide a %s: %dx %s.",
    ["Request"] = "Pedir",
    ["No items stored yet."] = "Aún no hay objetos guardados.",
    ["Filter items..."] = "Filtrar objetos...",
    ["Your group's skill levels, synergies, items you can give, and active cooldowns."] = "Niveles de profesión del grupo, sinergias, objetos que puedes dar y tiempos de reutilización activos.",
    ["All materials your group still needs, sorted by urgency. Type to find who can craft something."] = "Todos los materiales que tu grupo aún necesita, ordenados por urgencia. Escribe para buscar quién puede fabricar algo.",
    ["Craftable BiS gear, enchants, consumables, small bags, and patterns to hunt for each member."] = "Equipo BiS fabricable, encantamientos, consumibles, bolsas pequeñas y patrones por conseguir para cada miembro.",
    ["Green items in your bags: keep for enchants or upgrades, sell on the AH, or disenchant."] = "Objetos verdes en tus bolsas: guardar para encantamientos o mejoras, vender en subasta o desencantar.",
    ["Left: Group overview, Materials, Craftable BiS Upgrades, Wishlist, Requests, and every character in your group."] = "Izquierda: Resumen, Materiales, Mejoras BiS, Lista de deseos, Peticiones y cada personaje de tu grupo.",
    ["Bags highlight items your group needs; helper panels dock at Mail, Bank, Trade, Merchant, AH, and Trainers."] = "Las bolsas resaltan lo que necesita el grupo; paneles de ayuda se acoplan en Correo, Banco, Comercio, Mercader, Subasta e Instructores.",
    ["Nothing is shared yet. Here, in Manage group, check characters to share (or flag a Shared bank alt), then add friends below. Mutually added peers relay updates automatically."] = "Aún no se comparte nada. Marca los personajes a compartir (o un Alter banco compartido) y añade amigos abajo. Los contactos mutuos retransmiten actualizaciones automáticamente.",
    ["Reserved %dx %s for %s."] = "Reservado %dx %s para %s.",
    ["Reservation removed for %s."] = "Reserva eliminada para %s.",
    ["Reserve for..."] = "Reservar para...",
    ["Unlock reservation"] = "Desbloquear reserva",
    ["Usage: /comrade reserve [Item] Name [qty]"] = "Uso: /comrade reserve [Objeto] Nombre [cant]",
    ["Usage: /comrade unreserve [Item]"] = "Uso: /comrade unreserve [Objeto]",
    ["Reserved for %s"] = "Reservado para %s",
    ["Reserved for %s (x%d) - Alt+Right-click to unlock"] = "Reservado para %s (x%d) - Alt+Clic derecho para liberar",
    ["Reserved for you by %s (x%d)"] = "Reservado para ti por %s (x%d)",
    ["Reserved"] = "Reservado",
    ["Favorite"] = "Favorito",
    ["Unstar"] = "Quitar",
    ["Farming for you"] = "Farmeando para ti",
    ["Filter characters..."] = "Filtrar personajes...",
    ["by %s (you)"] = "por %s (tú)",
    ["crafting"] = "fabricando",
    ["shipped"] = "enviado",
    ["Crafting"] = "Fabricando",
    ["Shipped"] = "Enviado",
    ["Ready to craft"] = "Listo para fabricar",
    ["Ready to ship"] = "Listo para enviar",
    ["Missing %s"] = "Falta %s",
    ["Missing %d"] = "Faltan %d",
    ["Reserved for you"] = "Reservado para ti",
    ["Your reserved items"] = "Tus objetos reservados",
    ["Unlock"] = "Liberar",
    ["reserved"] = "reservado",
    ["Click: reserve for %s."] = "Clic: reservar para %s.",
    ["Click: request from %s [Bank]."] = "Clic: pedir a %s [Banco].",
    ["Favorites"] = "Favoritos",
    ["My characters"] = "Mis personajes",
    ["Group members"] = "Miembros del grupo",
    ["%d farming"] = "%d farmeando",
    ["Auto-marked request %dx %s as shipped."] = "Petición %dx %s marcada automáticamente como enviada.",
    ["Alt+Right-click any bag item to reserve/lock it for a friend before mailing."] = "Alt+Clic derecho en cualquier objeto de tus bolsas para reservarlo para un amigo antes de enviarlo.",
    ["Item reservations"] = "Reservas de objetos",
    ["  %s: %d crafts, %d points (expected %.1f)%s"] = "  %s: %d fabricaciones, %d puntos (esperado %.1f)%s",
    ["Add friends"] = "Añadir amigos",
    ["All window and tracker positions reset."] = "Todas las posiciones de ventanas y rastreadores restablecidas.",
    ["Auction House panel"] = "Panel de Subasta",
    ["Bank panel"] = "Panel de Banco",
    ["Browse Can craft"] = "Ver Puede fabricar",
    ["Browse Upgrades"] = "Ver Mejoras",
    ["Companion panels"] = "Paneles auxiliares",
    ["Configure companion panels, UI scale, sounds, and window positions."] = "Configura paneles auxiliares, escala de interfaz, sonidos y posiciones.",
    ["Crafts logged by you and your group automatically calibrate skill-up chances for WoW Forever."] = "Las fabricaciones registradas por ti y tu grupo calibran automáticamente las probabilidades para WoW Forever.",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never."] = "Cada paso indica qué aprender en el instructor, qué fabricar primero (rollos, barras...) y cuántos. Clic abre la receta, Mayús+clic la enlaza. Colores: naranja siempre sube, amarillo suele, verde rara vez, gris nunca.",
    ["Interface"] = "Interfaz",
    ["Known recipes. Right-click to pin to Wishlist, or click a friend's recipe to request it."] = "Recetas conocidas. Clic derecho para fijar en Lista de deseos, o clic en la receta de un amigo para pedirla.",
    ["Learn from a trainer of this profession (requires skill %d, level %d)."] = "Aprender en un instructor de esta profesión (requiere habilidad %d, nivel %d).",
    ["Left-click: open window  |  Right-click: options"] = "Clic izquierdo: abrir ventana  |  Clic derecho: opciones",
    ["List my character"] = "Registrar mi personaje",
    ["Mailbox panel"] = "Panel de Correo",
    ["Merchant panel"] = "Panel de Mercader",
    ["No friends in your group yet. Add guildmates or friends to share mats and upgrades."] = "Aún no hay amigos en tu grupo. Añade amigos o compañeros de hermandad para compartir materiales y mejoras.",
    ["Open ComradeCraft"] = "Abrir ComradeCraft",
    ["Play sound notifications"] = "Reproducir notificaciones sonoras",
    ["Reset window positions"] = "Restablecer posiciones",
    ["Show minimap button"] = "Mostrar botón del minimapa",
    ["Step-by-step profession leveling route, cost comparison, and trainer guide."] = "Ruta paso a paso, comparación de costes y guía de instructores.",
    ["Sync: %d players in the group, %d suggested."] = "Sync: %d jugadores en el grupo, %d sugeridos.",
    ["Toggle ComradeCraft"] = "Mostrar / ocultar ComradeCraft",
    ["Trade panel"] = "Panel de Comercio",
    ["Trainer panel"] = "Panel de Instructor",
    ["Window scale"] = "Escala de ventana",
    ["AH ~%s"] = "Subasta ~%s",
    ["For"] = "Para",
    ["Important unlearned patterns to buy or farm for yourself and your group (with drop rate and waypoints)."] = "Patrones importantes sin aprender para comprar o farmear para ti y tu grupo (con tasa de caída y puntos de ruta).",
    ["No unlearned upgrade patterns found for this character right now."] = "No se encontraron patrones de mejora sin aprender para este personaje ahora mismo.",
    ["Patterns"] = "Patrones",
    ["Valuable unlearned patterns for yourself and your group: where to buy or farm them, drop rate when known, and 1-click waypoints."] = "Patrones valiosos sin aprender para ti y tu grupo: dónde comprarlos o farmearlos, tasa de caída si se conoce y puntos de ruta en 1 clic.",
  ["Bargains"] = "Gangas",
  ["Deals"] = "Ofertas",
  ["Group needs spotted below market price."] = "Necesidades del grupo vistas por debajo del mercado.",
  ["Character"] = "Personaje",
  ["Slot"] = "Ranura",
  ["Group by:"] = "Agrupar por:",
  ["Enchants"] = "Encantamientos",
  ["Bags"] = "Bolsas",
  ["Claim CD"] = "Pedir CD",
  ["Estimated net profit and 1-click Claim CD for your group's long cooldowns."] = "Beneficio neto estimado y solicitud en 1 clic para tiempos de reutilización largos del grupo.",
  ["Craft chain planned (%d steps for %s)."] = "Cadena de fabricación planificada (%d pasos para %s).",
  ["Multi-profession craft chain"] = "Cadena de fabricación multiprofesión",
  ["Plan chain (%d)"] = "Cadena (%d)",
  ["Forever P2P DB: %d recipe bounds, %d vendors, %d drops (from %d peers)."] = "Base Forever P2P: %d rangos, %d vendedores, %d botines (de %d pares).",
  ["In %s (%d finds):"] = "En %s (%d hallazgos):",
  ["In %s: %s"] = "En %s: %s",
  ["In your zone: %s"] = "En tu zona: %s",
  ["Nothing specific for your group found in %s."] = "No se encontró nada específico para tu grupo en %s.",
  ["Rare drops, vendors, patterns and materials useful to your group right here."] = "Raros, vendedores, patrones y materiales útiles para tu grupo justo aquí.",
  ["world drop"] = "botín mundial",
  ["world drop - here (%s)"] = "botín mundial - aquí (%s)",
  ["world drop - near %s"] = "botín mundial - cerca de %s",
  ["%d bounds  |  %d custom recipes  |  %d disenchants  |  %d vendors  |  %d drops  (%d peers)"] = "%d rangos  |  %d recetas custom  |  %d desencantamientos  |  %d vendedores  |  %d botines  (%d pares)",
  ["%d in transit"] = "%d en tránsito",
  ["Accepted craft requests & pinned wishlist for this profession."] = "Pedidos aceptados y lista de deseos fijada para esta profesión.",
  ["Already mailed between group accounts — counted as on the way so nobody double-sends."] = "Ya enviado entre cuentas del grupo — contado en camino para evitar duplicados.",
  ["Applied craft kit \"%s\" (x%d)."] = "Kit de fabricación \"%s\" aplicado (x%d).",
  ["Apply x1"] = "Aplicar x1",
  ["Apply x5"] = "Aplicar x5",
  ["Click to open recipe (trade slot 7)"] = "Clic: abrir receta (ranura comercio 7)",
  ["Click to open this enchant for the trade slot."] = "Haz clic para abrir este encantamiento para la ranura de comercio.",
  ["Craft kits"] = "Kits de fabricación",
  ["Craft request (%s)"] = "Pedido (%s)",
  ["Deliver to %s"] = "Entregar a %s",
  ["Enchant auto-completes request on trade"] = "El encantamiento completa el pedido al comerciar",
  ["Forever P2P database"] = "Base de datos P2P Forever",
  ["In group stock: \"%s\""] = "En stock del grupo: \"%s\"",
  ["In transit"] = "En tránsito",
  ["In transit (1h mail)"] = "En tránsito (correo 1h)",
  ["Next: %s (%d left)"] = "Siguiente: %s (%d rest.)",
  ["Observed WoW Forever recipe bounds, custom recipes, disenchants, vendors and drops shared automatically."] = "Rangos Forever, recetas custom, desencantamientos, vendedores y botines compartidos automáticamente.",
  ["Orders (%d)"] = "Pedidos (%d)",
  ["Reserved by %s"] = "Reservado por %s",
  ["Reusable craft bundles (raid, dungeon, reroll) — apply in 1 click."] = "Paquetes reutilizables (banda, mazmorra, alter) — aplicar en 1 clic.",
  ["Save as kit"] = "Guardar kit",
  ["Save current wishlist as a reusable kit"] = "Guardar la lista actual como kit reutilizable",
  ["Save kit"] = "Guardar",
  ["Saved craft kit \"%s\" (%d recipes)."] = "Kit \"%s\" guardado (%d recetas).",
  ["Sent %d/%d"] = "Enviado %d/%d",
  ["Sent %d/%d %s."] = "Enviado %d/%d %s.",
  ["Share now"] = "Compartir",
  ["Step %d/%d"] = "Paso %d/%d",
  ["Waiting previous step"] = "Esperando paso anterior",
  ["Wishlist completed: %s"] = "Lista completada: %s",
  ["measured"] = "medido",
    -- Target skill (Plan tab)
    ["auction house"] = "casa de subastas",
    ["Queued %dx %s: open the profession window and click Craft next."] = "%dx %s en cola: abre la ventana de profesión y pulsa Fabricar siguiente.",
    ["Restock: %s"] = "Reponer: %s",
    ["Restock"] = "Reponer",
    ["Queue"] = "Cola",
    ["No risk: sell to a merchant"] = "Sin riesgo: vender a un comerciante",
    ["net %s per craft at a merchant"] = "neto %s por creación en un comerciante",
    ["Auctionator shopping list ready: %s (%d items)."] = "Lista de compra de Auctionator lista: %s (%d objetos).",
    ["once per cooldown"] = "una vez por reutilización",
    ["Cooldown goldmakers"] = "Creaciones rentables con reutilización",
    ["ready in %s"] = "listo en %s",
    ["Goldmaking"] = "Ganar oro",
    ["net %s per craft"] = "neto %s por creación",
    ["~%d sold per day"] = "~%d vendidos al día",
    ["~%s per day"] = "~%s al día",
    ["sales volume unknown"] = "volumen de ventas desconocido",
    ["craft the %s yourself"] = "fabrica tú mismo: %s",
    ["craft the %s yourself (recipe to learn)"] = "fabrica tú mismo: %s (receta por aprender)",
    ["Crafts that earn the most at the auction house, at the pace it buys them (mats bought or crafted, whichever is cheaper; after the cut and deposit)."] = "Las creaciones que más rinden en la casa de subastas, al ritmo al que las compra (materiales comprados o fabricados, lo más barato; tras la comisión y el depósito).",
    ["No auction prices yet: scan the auction house or install TSM or Auctionator."] = "Aún no hay precios de subasta: escanea la casa de subastas o instala TSM o Auctionator.",
    ["stackable"] = "apilable",
    ["one by one"] = "de una en una",
    ["Repeat goldmakers"] = "Creaciones rentables repetibles",
    ["No known recipe makes money at current prices."] = "Ninguna receta conocida da beneficio a los precios actuales.",
    ["Recipes worth buying"] = "Recetas que vale la pena comprar",
    ["recipe %s, paid back in %d crafts"] = "receta %s, amortizada en %d creaciones",
    ["What if I learned:"] = "Y si aprendiera:",
    ["Alternative: %s from the quest %s would save about %s."] = "Alternativa: %s de la misión %s ahorraría unos %s.",
    ["Get a %s"] = "Consigue: %s",
    ["Craft it first: %s."] = "Fabrícalo primero: %s.",
    ["Sold by trade supplies vendors (%s)."] = "Lo venden los proveedores de suministros comerciales (%s).",
    ["Sold by trade supplies vendors."] = "Lo venden los proveedores de suministros comerciales.",
    ["Craft at: %s"] = "Fabricar junto a: %s",
    ["Nearest: %s"] = "Más cercano: %s",
    ["Location not known yet: saved the first time someone crafts there."] = "Ubicación aún desconocida: se guarda la primera vez que alguien fabrica allí.",
    ["Anvil"] = "Yunque",
    ["Forge"] = "Forja",
    ["Loom"] = "Telar",
    ["Cooking Fire"] = "Fuego de cocina",
    ["Tanning Rack"] = "Bastidor de curtido",
    ["Spinning Wheel"] = "Rueca",
    ["Sewing Machine"] = "Máquina de coser",
    ["Master Forge"] = "Forja maestra",
    ["Alchemy Lab"] = "Laboratorio de alquimia",
    ["Iron Oven"] = "Horno de hierro",
    ["Fermenter"] = "Fermentador",
    ["Black Anvil"] = "Yunque negro",
    ["Black Forge"] = "Forja negra",
    ["With your budget you can reach %d (target %d)."] = "Con tu presupuesto puedes llegar a %d (objetivo %d).",
    ["Filtered by the budget: the greyed steps need about %s more."] = "Filtrado por el presupuesto: los pasos en gris necesitan unos %s más.",
    ["Remove budget"] = "Quitar presupuesto",
    ["Budget (g):"] = "Presupuesto (o):",
    ["Budget"] = "Presupuesto",
    ["Gold you put into leveling, Enter to apply; empty = no limit. Sales of earlier crafts are reinvested."] = "Oro que inviertes en subir, Intro para aplicar; vacío = sin límite. Las ventas de lo fabricado antes se reinvierten.",
    ["Enter to apply"] = "Intro para aplicar",
    ["no limit - type gold, Enter to apply"] = "sin límite - escribe oro, Intro para aplicar",
    ["Gold needed at the worst moment: %s (sales of earlier crafts reinvested)."] = "Oro necesario en el peor momento: %s (ventas de lo fabricado antes reinvertidas).",
    ["Sell the crafts:"] = "Qué hacer con lo fabricado:",
    ["%s: %s"] = "%s: %s",
    ["%d at the AH"] = "%d en la subasta",
    ["disenchant %d with %s"] = "desencantar %d con %s",
    ["%d to a merchant"] = "%d al vendedor",
    ["Buy %s at the auction house (skill %s, %s)"] = "Comprar %s en la casa de subastas (habilidad %s, %s)",
    ["Auction house - skill %s - %s"] = "Casa de subastas - habilidad %s - %s",
    ["Buy recipe: %s"] = "Comprar receta: %s",
    ["Buy %s from %s (skill %s, %s)"] = "Comprar %s a %s (habilidad %s, %s)",
    ["Vendor: %s - skill %s - %s"] = "Vendedor: %s - habilidad %s - %s",
    ["price unknown until you visit the vendor"] = "precio desconocido hasta que visites al vendedor",
    ["a vendor"] = "un vendedor",
    ["Trainer & recipes"] = "Instructor y recetas",
    ["+ Trainer & recipes: %s (in the net). To buy = missing mats (AH + merchant); net = to buy - resale + trainer & recipes."] = "+ Instructor y recetas: %s (incluido en el neto). A comprar = materiales que faltan (subasta + vendedor); neto = a comprar - reventa + instructor y recetas.",
    ["(your side only)"] = "(solo en tu lado)",
    ["Target:"] = "Objetivo:",
    ["Target skill"] = "Habilidad objetivo",
    ["Type a skill (up to 300) and press Enter. Mouse wheel: +/-5 (Shift: 25)."] = "Escribe una habilidad (máx. 300) y pulsa Intro. Rueda: +/-5 (Mayús: 25).",
    ["(cap) - click to change, Enter to apply"] = "(máx.) - clic para cambiar, Intro para aplicar",
    ["click to change, Enter to apply"] = "clic para cambiar, Intro para aplicar",
    ["Target %d"] = "Apuntar a %d",
    ["Cap"] = "Máx.",
    ["Level %d needed to learn this rank (now %d)."] = "Se necesita nivel %d para aprender este rango (ahora %d).",
    ["Total %d to %d (%s prices)"] = "Total de %d a %d (precios %s)",
    ["Total %d to %d: gross %s, to buy %s, resale %s, trainer %s, net %s (%s prices)."] = "Total de %d a %d: bruto %s, a comprar %s, reventa %s, instructor %s, neto %s (precios %s).",
    ["Gross"] = "Bruto",
    ["To buy"] = "A comprar",
    ["Resale"] = "Reventa",
    ["Net"] = "Neto",
    ["not counted"] = "no contado",
    ["Stops at"] = "Se detiene en",
    ["Other route: trainer not counted."] = "Otra ruta: instructor no contado.",
    ["> = some prices are unknown: a cost is a minimum, a profit (+<) a maximum."] = "> = algunos precios son desconocidos: un coste es un mínimo, una ganancia (+<) un máximo.",
}
