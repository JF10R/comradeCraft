-- ptBR translations. Keys: the English text (see Locale.lua); loaded only on a ptBR client.
local _, ns = ...
local loc = GetLocale and GetLocale()
if loc ~= "ptBR" then return end
ns.Translations = ns.Translations or {}
ns.Translations[loc] = {
    ["commands: /comrade (window) | share [off] | list [off] | directory [text] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"] =
      "comandos: /comrade (janela) | share [off] | list [off] | directory [texto] | add NOME | remove NOME | peers | sync | guildping [off] | shop [profissão] | tracker [reset] | mail NOME | scan | needs | stats | api | audit | log clear",
    ["log cleared"] =
      "log limpo",
    ["%d lines in the log (written to disk on /reload or logout)"] =
      "%d linhas no log (gravado no disco com /reload ou ao sair)",
    ["scan ok: %d distinct items in bags"] =
      "scan ok: %d itens distintos nas bolsas",
    ["DevTools_Dump missing; see WTF\\...\\SavedVariables\\ComradeCraft.lua after /reload"] =
      "DevTools_Dump ausente; veja WTF\\...\\SavedVariables\\ComradeCraft.lua após o /reload",
    ["audit: C_TradeSkillUI.GetAllRecipeIDs missing on this client"] =
      "audit: C_TradeSkillUI.GetAllRecipeIDs ausente neste cliente",
    ["audit: open a profession window first"] =
      "audit: abra primeiro uma janela de profissão",
    ["  %s (%d): game=%s table=%s [%d/%d]"] =
      "  %s (%d): jogo=%s tabela=%s [%d/%d]",
    ["audit rank %d: %d ok, %d mismatches, %d missing from the table"] =
      "audit nível %d: %d ok, %d divergências, %d ausentes da tabela",
    ["LibProfessionDB: %d ok, %d mismatches"] =
      "LibProfessionDB: %d ok, %d divergências",
    ["maxTrivialLevel == grey: %d yes, %d no"] =
      "maxTrivialLevel == cinza: %d sim, %d não",
    ["yes"] =
      "sim",
    ["no"] =
      "não",
    ["%d crafts recorded (calibration from %d per color)"] =
      "%d criações registradas (calibragem a partir de %d por cor)",
    ["orange"] =
      "laranja",
    ["yellow"] =
      "amarelo",
    ["green"] =
      "verde",
    ["grey"] =
      "cinza",
    [" -> factor %.2f applied"] =
      " -> fator %.2f aplicado",
    ["  game color known on %d crafts: our table %d right, LibProfessionDB %d right"] =
      "  cor do jogo conhecida em %d criações: nossa tabela acertou %d, LibProfessionDB acertou %d",
    ["needs %d"] =
      "precisa de %d",
    ["Group total"] =
      "Total do grupo",
    ["Spare in the group"] =
      "Sobrando no grupo",
    ["You can give"] =
      "Você pode dar",
    ["Spare items in your bags that others need. With a mailbox open, click one to prepare the mail."] =
      "Itens sobrando nas suas bolsas que outros precisam. Com a caixa de correio aberta, clique em um para preparar a carta.",
    ["Mail full (%d attachments): send it, then click again for the rest."] =
      "Carta cheia (%d anexos): envie-a e clique de novo para o resto.",
    ["Open a mailbox first."] =
      "Abra primeiro uma caixa de correio.",
    ["Nothing to give to %s."] =
      "Nada para dar a %s.",
    ["Attach what they need"] =
      "Anexar o que precisam",
    ["Type the name of a group member."] =
      "Digite o nome de um membro do grupo.",
    ["You need"] =
      "Você precisa",
    ["Disenchant or keep?"] =
      "Desencantar ou guardar?",
    ["Green and better items in your bags. Yields are estimates until your disenchants are logged."] =
      "Itens verdes ou melhores nas suas bolsas. Os rendimentos são estimativas até seus desencantamentos serem registrados.",
    ["Keep: enchanting target (%s)"] =
      "Guardar: alvo de encantamento (%s)",
    ["Keep: gear for %s"] =
      "Guardar: equipamento para %s",
    ["Sell: AH %s vs disenchant %s"] =
      "Vender: CL %s contra desencantamento %s",
    ["Disenchant: %s"] =
      "Desencantar: %s",
    ["the group needs these"] =
      "o grupo precisa disto",
    ["give to %s"] =
      "dar para %s",
    ["group: %d"] =
      "grupo: %d",
    ["now"] =
      "agora",
    ["soon"] =
      "em breve",
    ["later"] =
      "depois",
    ["trainer"] =
      "instrutor",
    ["vendor"] =
      "vendedor",
    ["quest"] =
      "missão",
    ["drop"] =
      "drop",
    ["container"] =
      "recipiente",
    ["Gathering profession: levels by gathering, not crafting."] =
      "Profissão de coleta: o nível sobe coletando, não criando.",
    ["Open this profession's window once so your recipes can be read."] =
      "Abra a janela desta profissão uma vez para que suas receitas possam ser lidas.",
    ["No data."] =
      "Sem dados.",
    ["Learn %s at the trainer (skill %s, %s)"] =
      "Aprenda %s com o instrutor (perícia %s, %s)",
    ["cost unknown until you visit the trainer"] =
      "custo desconhecido até você visitar o instrutor",
    ["Craft %d %s (%s)"] =
      "Crie %d %s (%s)",
    ["Craft %dx %s (%s)"] =
      "Crie %dx %s (%s)",
    ["%d %s (vendor)"] =
      "%d %s (vendedor)",
    [" + %d from stock"] =
      " + %d do estoque",
    ["%d %s from stock"] =
      "%d %s do estoque",
    ["With only your current recipes, you would be stuck at %d."] =
      "Só com suas receitas atuais, você ficaria travado em %d.",
    ["Uses what you already have: %s."] =
      "Usa o que você já tem: %s.",
    ["Buy from a vendor: %s."] =
      "Comprar de um vendedor: %s.",
    ["Stuck at %d: all your known recipes are grey (no more points)."] =
      "Travado em %d: todas as suas receitas conhecidas estão cinza (sem mais pontos).",
    ["Stuck at %d: your known recipes barely give points anymore (%d%% chance per craft at best, %d%% needed)."] =
      "Travado em %d: suas receitas conhecidas quase não dão mais pontos (%d%% de chance por criação no máximo, %d%% necessário).",
    [" To learn: %s."] =
      " A aprender: %s.",
    [" No recipe to learn found within the next 25 points."] =
      " Nenhuma receita a aprender encontrada nos próximos 25 pontos.",
    ["  missing %s x%d"] =
      "  falta %s x%d",
    ["just now"] =
      "agora há pouco",
    ["%d min ago"] =
      "há %d min",
    ["%d h ago"] =
      "há %d h",
    ["What to craft:"] =
      "O que criar:",
    ["Owned: %d / %d"] =
      "Possuído: %d / %d",
    ["%d profession"] =
      "%d profissão",
    ["%d professions"] =
      "%d profissões",
    ["%d member"] =
      "%d membro",
    ["%d members"] =
      "%d membros",
    ["Group"] =
      "Grupo",
    ["Plan"] =
      "Plano",
    ["Can craft"] =
      "Pode criar",
    ["Lvl %d"] =
      "Nív. %d",
    ["updated %s"] =
      "atualizado %s",
    ["Skill levels and the materials the group still needs. Type to find who can craft something."] =
      "Níveis de perícia e os materiais que o grupo ainda precisa. Digite para achar quem pode criar algo.",
    ["Skill levels"] =
      "Níveis de perícia",
    ["Most wanted materials"] =
      "Materiais mais procurados",
    ["Nothing missing yet."] =
      "Nada falta ainda.",
    ["Who can craft \"%s\""] =
      "Quem pode criar \"%s\"",
    ["No recipe matches."] =
      "Nenhuma receita corresponde.",
    ["No profession data. Open your profession windows."] =
      "Sem dados de profissão. Abra suas janelas de profissão.",
    ["%d recipe"] =
      "%d receita",
    ["%d recipes"] =
      "%d receitas",
    ["gear for %s"] =
      "equipamento para %s",
    ["upgrade for %s (+%d)"] =
      "melhoria para %s (+%d)",
    ["Enchant"] =
      "Encantamento",
    ["Consumable"] =
      "Consumível",
    ["Bag"] =
      "Bolsa",
    ["Weapon"] =
      "Arma",
    ["Armor"] =
      "Armadura",
    ["Reagent"] =
      "Reagente",
    ["Other"] =
      "Outro",
    ["via %s"] =
      "via %s",
    ["Manage group"] =
      "Gerenciar grupo",
    ["Choose what you share, and with whom."] =
      "Escolha o que compartilhar e com quem.",
    ["%d player"] =
      "%d jogador",
    ["%d players"] =
      "%d jogadores",
    ["%d request"] =
      "%d pedido",
    ["%d requests"] =
      "%d pedidos",
    ["Your characters"] =
      "Seus personagens",
    ["Only checked characters are shared, and only with the players in your group."] =
      "Só os personagens marcados são compartilhados, e só com os jogadores do seu grupo.",
    ["Players in your group"] =
      "Jogadores do seu grupo",
    ["They receive your shared characters and you see theirs."] =
      "Eles recebem seus personagens compartilhados e você vê os deles.",
    ["Nobody yet."] =
      "Ninguém ainda.",
    ["seen %s"] =
      "visto %s",
    ["Remove"] =
      "Remover",
    ["Requests and suggestions"] =
      "Pedidos e sugestões",
    ["Players with ComradeCraft in your guild, or who added you. Add them to share both ways."] =
      "Jogadores da sua guilda com o ComradeCraft, ou que adicionaram você. Adicione-os para compartilhar nos dois sentidos.",
    ["Add"] =
      "Adicionar",
    ["Add a player by name"] =
      "Adicionar jogador pelo nome",
    ["For friends outside your guild. They must add you back."] =
      "Para amigos fora da guilda. Eles precisam adicionar você também.",
    ["Options"] =
      "Opções",
    ["Send a presence signal to the guild at login (no character data)."] =
      "Enviar à guilda um sinal de presença ao entrar (sem dados de personagem).",
    ["All"] =
      "Todas",
    ["Hide gathering"] =
      "Ocultar coleta",
    ["No profession matches the filter."] =
      "Nenhuma profissão corresponde ao filtro.",
    ["%d character"] =
      "%d personagem",
    ["%d characters"] =
      "%d personagens",
    ["Remove from group"] =
      "Remover do grupo",
    ["sync: sent to the players in your group"] =
      "sync: enviado aos jogadores do seu grupo",
    ["%s is shared with your group"] =
      "%s está compartilhado com seu grupo",
    ["%s is no longer shared"] =
      "%s não está mais compartilhado",
    ["guild presence signal: on"] =
      "sinal de presença na guilda: ativado",
    ["guild presence signal: off"] =
      "sinal de presença na guilda: desativado",
    ["Share this character with the group"] =
      "Compartilhar este personagem com o grupo",
    ["not shared"] =
      "não compartilhado",
    ["  %s: %d characters, %s"] =
      "  %s: %d personagens, %s",
    ["in the group"] =
      "no grupo",
    ["wants to join"] =
      "quer entrar",
    ["suggested"] =
      "sugerido",
    ["no peer seen yet (they need ComradeCraft)"] =
      "nenhum jogador visto ainda (precisam do ComradeCraft)",
    ["%s added to the group"] =
      "%s adicionado ao grupo",
    ["%s contacted; added as soon as they answer"] =
      "%s contatado; adicionado assim que responder",
    ["%s removed from the group"] =
      "%s removido do grupo",
    ["Could not create the Auctionator list (see /comrade log)."] =
      "Não foi possível criar a lista do Auctionator (veja /comrade log).",
    ["Nothing to buy for %s."] =
      "Nada para comprar para %s.",
    ["Auctionator list \"ComradeCraft: %s\" created: %d items. Open the Shopping tab at the auction house."] =
      "Lista do Auctionator \"ComradeCraft: %s\" criada: %d itens. Abra a aba Shopping na Casa de Leilões.",
    ["%d not cached yet; try again in a moment."] =
      "%d ainda não em cache; tente de novo daqui a pouco.",
    ["Nothing to buy."] =
      "Nada para comprar.",
    ["Step panel hidden. /comrade tracker shows it again."] =
      "Painel de etapa oculto. /comrade tracker o mostra de novo.",
    ["TSM shopping (Ctrl+C to copy)"] =
      "Compras TSM (Ctrl+C para copiar)",
    ["Search: paste in the search box of TSM's Shopping tab."] =
      "Busca: cole na caixa de busca da aba Shopping do TSM.",
    ["Group: TSM, Groups, Import. Quantities are in the search above (recomputed on each click)."] =
      "Grupo: TSM, Groups, Import. As quantidades estão na busca acima (recalculadas a cada clique).",
    ["TSM group \"%s\": everything bought, delete it in TSM (Groups, right-click)."] =
      "Grupo TSM \"%s\": tudo comprado, apague-o no TSM (Groups, clique direito).",
    ["TSM group \"%s\": replaced by a newer one, delete it in TSM (Groups, right-click)."] =
      "Grupo TSM \"%s\": substituído por um mais novo, apague-o no TSM (Groups, clique direito).",
    ["Send now"] =
      "Enviar agora",
    ["Show the step panel next to the profession window."] =
      "Mostrar o painel de etapa ao lado da janela de profissão.",
    ["Re-dock"] =
      "Reencaixar",
    ["Measured skill-up chances"] =
      "Chances de subir perícia medidas",
    ["The window"] =
      "A janela",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "À esquerda: o grupo e depois cada personagem. Plano = como subir uma profissão; Pode criar = o que esse personagem pode fazer para o grupo. Os chips filtram por profissão.",
    ["Plans"] =
      "Planos",
    ["Tooltips"] =
      "Dicas",
    ["On any material: who in the group needs it, how many, and how soon (now, soon, later). Spare stock in the group is shown too."] =
      "Em qualquer material: quem no grupo precisa dele, quantos, e quando (agora, em breve, depois). O estoque sobrando no grupo também aparece.",
    ["Step panel"] =
      "Painel de etapa",
    ["Next to your profession window: the current step, the chance per craft, how many crafts your bags allow, and what comes next."] =
      "Ao lado da sua janela de profissão: a etapa atual, a chance por criação, quantas criações suas bolsas permitem e o que vem a seguir.",
    ["Giving and mail"] =
      "Dar e correio",
    ["You can give lists what you hold that others need. At a mailbox, the button beside the send frame attaches it. Nothing is ever sent for you."] =
      "«Você pode dar» lista o que você tem e outros precisam. Na caixa de correio, o botão ao lado do envio anexa isso. Nada é enviado sem você.",
    ["Disenchant or keep"] =
      "Desencantar ou guardar",
    ["Your green items: keep one per slot your enchanting plan needs, keep upgrades for group members, sell what is worth more than its mats, disenchant the rest."] =
      "Seus itens verdes: guarde um por espaço que seu plano de encantamento precisa, guarde melhorias para o grupo, venda o que vale mais que os materiais, desencante o resto.",
    ["Shopping"] =
      "Compras",
    ["The Shopping list button makes an Auctionator list, or a TSM search and group to paste. TSM groups that are done are pointed out."] =
      "O botão Lista de compras cria uma lista do Auctionator, ou uma busca e um grupo TSM para colar. Os grupos TSM concluídos são indicados.",
    ["Sharing"] =
      "Compartilhamento",
    ["Nothing is shared until you check a character in Manage group, and only with players you added who added you back."] =
      "Nada é compartilhado até você marcar um personagem em Gerenciar grupo, e só com jogadores que você adicionou e que adicionaram você.",
    ["Better with"] =
      "Melhor com",
    ["Replay the tour"] =
      "Rever o tour",
    ["Welcome to ComradeCraft"] =
      "Bem-vindo ao ComradeCraft",
    ["It answers one question: what should I do with what I have, for the group? 30 seconds to see the main parts."] =
      "Ele responde a uma pergunta: o que fazer com o que tenho, pelo grupo? 30 segundos para ver o essencial.",
    ["Your group"] =
      "Seu grupo",
    ["Plan and Can craft"] =
      "Plano e Pode criar",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Escolha um personagem: Plano mostra como subir cada profissão passo a passo; Pode criar mostra o que ele pode fazer para os outros.",
    ["While you play"] =
      "Enquanto você joga",
    ["Sharing is off until you check a box"] =
      "O compartilhamento fica desativado até você marcar uma caixa",
    ["Do not show again"] =
      "Não mostrar de novo",
    ["Skip"] =
      "Pular",
    ["Done"] =
      "Concluir",
    ["Next"] =
      "Próximo",
    ["Help"] =
      "Ajuda",
    ["How ComradeCraft works, in short."] =
      "Como o ComradeCraft funciona, em resumo.",
    ["Cheapest"] =
      "Mais barata",
    ["Profitable"] =
      "Lucrativa",
    ["Route:"] =
      "Rota:",
    ["Picks recipes whose products sell back well. More crafts, so more mats: tooltips, the give list, mail and shopping all follow this route."] =
      "Escolhe receitas cujos produtos se revendem bem. Mais criações, logo mais materiais: dicas, lista de doação, correio e compras seguem esta rota.",
    ["Chosen by its owner."] =
      "Escolhida pelo dono.",
    ["Spends the least on mats."] =
      "Gasta o mínimo em materiais.",
    ["Where to get it: unknown."] =
      "Onde obter: desconhecido.",
    ["Where to get it:"] =
      "Onde obter:",
    ["and %d more"] =
      "e mais %d",
    ["Install Questie for locations; TomTom for waypoints."] =
      "Instale o Questie para os locais e o TomTom para os pontos de rota.",
    ["Click: waypoint to the nearest one."] =
      "Clique: ponto de rota para o mais próximo.",
    ["No known location for %s."] =
      "Nenhum local conhecido para %s.",
    ["%s: %s. Install TomTom for a waypoint."] =
      "%s: %s. Instale o TomTom para um ponto de rota.",
    ["Waypoint: %s"] =
      "Ponto de rota: %s",
    ["Mats per craft:"] =
      "Materiais por criação:",
    ["+%d more"] =
      "+%d mais",
    ["Recipe and mats"] =
      "Receita e materiais",
    ["For the group"] =
      "Para o grupo",
    ["Type"] =
      "Tipo",
    ["Mats cost"] =
      "Custo dos materiais",
    ["At the trainer - skill %s - %s"] =
      "No instrutor - perícia %s - %s",
    ["already in your bags"] =
      "já nas suas bolsas",
    ["Cost by milestone (%s prices)"] =
      "Custo por marco (preços de %s)",
    ["Cost by milestone (merchant prices; TSM or Auctionator give AH prices)"] =
      "Custo por marco (preços de vendedor; TSM ou Auctionator dão os preços da CL)",
    ["Skill %d to %d"] =
      "Perícia %d a %d",
    ["Learn %s"] =
      "Aprender %s",
    ["Skill"] =
      "Perícia",
    ["Route"] =
      "Rota",
    ["Mats"] =
      "Materiais",
    ["Sold back"] =
      "Revendido",
    ["Net cost"] =
      "Custo líquido",
    ["nothing"] =
      "nada",
    ["unknown"] =
      "desconhecido",
    ["Sold to a merchant"] =
      "Vendido a um vendedor",
    ["Disenchanted"] =
      "Desencantado",
    ["At the auction house (-5%, deposit risk)"] =
      "Na Casa de Leilões (-5%, risco de depósito)",
    ["Best way per item"] =
      "Melhor opção por item",
    ["Net cost = mats minus the best resale of each item. A green + is a profit. Hover a line for the details."] =
      "Custo líquido = materiais menos a melhor revenda de cada item. Um + verde é lucro. Passe o mouse sobre uma linha para ver os detalhes.",
    ["Next: %s"] =
      "Próximo: %s",
    ["Click to expand."] =
      "Clique para expandir.",
    ["Could not start the craft (see /comrade log)."] =
      "Não foi possível iniciar a criação (veja /comrade log).",
    ["Queue:"] =
      "Fila:",
    ["up to skill %d (click: this step only)"] =
      "até a perícia %d (clique: só esta etapa)",
    ["this step (click: up to the milestone)"] =
      "esta etapa (clique: até o marco)",
    ["by hand (needs a target)"] =
      "à mão (precisa de um alvo)",
    ["ready"] =
      "pronto",
    ["%d ready"] =
      "%d prontos",
    ["Craft next: %dx %s"] =
      "Criar o próximo: %dx %s",
    ["Learn %s first"] =
      "Aprenda %s primeiro",
    ["Missing mats for the queue"] =
      "Faltam materiais para a fila",
    ["Nothing to craft"] =
      "Nada para criar",
    ["%s asks %s to craft %dx %s."] =
      "%s pede a %s para criar %dx %s.",
    ["Request %dx %s: %s."] =
      "Pedido de %dx %s: %s.",
    ["Request sent to %s. It is delivered as soon as you are both online."] =
      "Pedido enviado a %s. Ele é entregue assim que vocês dois estiverem online.",
    ["Quantity"] =
      "Quantidade",
    ["Note (optional)"] =
      "Nota (opcional)",
    ["Send request"] =
      "Enviar pedido",
    ["Ask %s to craft %s"] =
      "Pedir a %s para criar %s",
    ["Craft requests"] =
      "Pedidos de criação",
    ["%d to answer"] =
      "%d para responder",
    ["none open"] =
      "nenhum aberto",
    ["Ask a group member to craft something, or answer what they asked you."] =
      "Peça a um membro do grupo para criar algo, ou responda ao que pediram a você.",
    ["Click: ask %s to craft it."] =
      "Clique: pedir a %s para criar.",
    ["%s for %s"] =
      "%s para %s",
    ["asked to %s"] =
      "pedido a %s",
    ["waiting to reach the other player"] =
      "aguardando alcançar o outro jogador",
    ["Mats: %s"] =
      "Materiais: %s",
    ["your bags allow %d"] =
      "suas bolsas permitem %d",
    ["Accept"] =
      "Aceitar",
    ["Decline"] =
      "Recusar",
    ["Cancel request"] =
      "Cancelar pedido",
    ["For your characters"] =
      "Para seus personagens",
    ["Your requests"] =
      "Seus pedidos",
    ["Accept, craft, then mark it done; the mail helper attaches the item when you write to them."] =
      "Aceite, crie e marque como concluído; o auxiliar de correio anexa o item quando você escrever para a pessoa.",
    ["Click a recipe in a group member's Can craft tab to ask for it. Delivered the next time you are both online."] =
      "Clique em uma receita na aba Pode criar de um membro do grupo para pedi-la. Entregue na próxima vez que vocês estiverem online juntos.",
    ["pending"] =
      "pendente",
    ["accepted"] =
      "aceito",
    ["declined"] =
      "recusado",
    ["done"] =
      "concluído",
    ["cancelled"] =
      "cancelado",
    ["(by mail)"] =
      "(por correio)",
    ["Request mail ready: check it and click Send."] =
      "Carta do pedido pronta: confira e clique em Enviar.",
    ["By mail"] =
      "Por correio",
    ["Craft requests by mail too: for players who are never online at the same time (you send the mail yourself, 30c postage)."] =
      "Pedidos de criação também por correio: para jogadores que nunca ficam online ao mesmo tempo (você envia a carta, 30c de postagem).",
    ["other profession"] =
      "outra profissão",
    ["Routes"] =
      "Rotas",
    ["Each character picks Cheapest (least spent on mats) or Profitable (products sold back). The milestone table compares both: mats, what the products bring back (merchant, disenchant or AH) and the net cost."] =
      "Cada personagem escolhe Mais barata (menos gasto em materiais) ou Lucrativa (produtos revendidos). A tabela por marco compara as duas: materiais, o que os produtos rendem (vendedor, desencanto ou CL) e o custo líquido.",
    ["Learning recipes"] =
      "Aprender receitas",
    ["Hover a Learn line for its trainers, vendors and drops; click it for a TomTom waypoint (with Questie installed for positions)."] =
      "Passe o mouse sobre uma linha Aprender para ver seus instrutores, vendedores e drops; clique nela para um ponto de rota do TomTom (com o Questie instalado para as posições).",
    ["Craft queue"] =
      "Fila de criação",
    ["In the step panel: the crafts of this step or of the whole milestone, what your bags allow, and Craft next (one batch per click, the game needs a click per craft)."] =
      "No painel de etapa: as criações desta etapa ou do marco inteiro, o que suas bolsas permitem e Criar o próximo (um lote por clique, o jogo exige um clique por criação).",
    ["Click a recipe in a group member's Can craft tab to ask for it. Answer what you are asked in Craft requests. Requests reach the other player the next time you are both online (or by mail, if turned on in Manage group)."] =
      "Clique em uma receita na aba Pode criar de um membro do grupo para pedi-la. Responda ao que pedirem em Pedidos de criação. Os pedidos chegam ao outro jogador na próxima vez que vocês estiverem online juntos (ou por correio, se ativado em Gerenciar grupo).",
    ["%s: mats ready"] =
      "%s: materiais prontos",
    ["Your bags hold everything for %dx %s."] =
      "Suas bolsas têm tudo para %dx %s.",
    ["Cooldown ready: %s"] =
      "Recarga pronta: %s",
    ["on %s"] =
      "em %s",
    ["+%d with Pawn"] =
      "+%d com o Pawn",
    ["+%d item levels"] =
      "+%d níveis de item",
    ["%s can craft an upgrade for you"] =
      "%s pode criar uma melhoria para você",
    ["Ask for it"] =
      "Pedir",
    ["Not interested"] =
      "Sem interesse",
    ["New craft request"] =
      "Novo pedido de criação",
    ["Open"] =
      "Abrir",
    ["Alerts"] =
      "Alertas",
    ["A chat line and a short notice at the top of the screen."] =
      "Uma linha no chat e um aviso curto no topo da tela.",
    ["Your bags hold the mats for your next craft."] =
      "Suas bolsas têm os materiais para sua próxima criação.",
    ["A profession cooldown is ready on one of your characters."] =
      "Uma recarga de profissão está pronta em um dos seus personagens.",
    ["A craft request arrives or changes."] =
      "Um pedido de criação chega ou muda.",
    ["A group member can craft an upgrade for you (off by default)."] =
      "Um membro do grupo pode criar uma melhoria para você (desativado por padrão).",
    ["visited"] =
      "visitado",
    ["Next rank: %s (%d to %d)"] =
      "Próximo nível: %s (%d a %d)",
    ["Journeyman"] =
      "Artesão",
    ["Expert"] =
      "Especialista",
    ["Artisan"] =
      "Artífice",
    ["Master"] =
      "Mestre",
    ["skill %d"] =
      "perícia %d",
    ["level %d"] =
      "nível %d",
    ["sold by %s"] =
      "vendido por %s",
    ["or at the AH (~%s)"] =
      "ou na CL (~%s)",
    ["or at the AH"] =
      "ou na CL",
    ["At the cap (%d)."] =
      "No limite (%d).",
    ["Looking for the quest in Questie..."] =
      "Procurando a missão no Questie...",
    ["This rank comes from a quest (install Questie to find it)."] =
      "Este nível vem de uma missão (instale o Questie para encontrá-la).",
    ["starts at %s"] =
      "começa em %s",
    ["Quest: %s"] =
      "Missão: %s",
    ["Quests that need %d in this skill; the rank quest is among them."] =
      "Missões que exigem %d nesta perícia; a missão do nível está entre elas.",
    ["Click: waypoint to the quest giver."] =
      "Clique: ponto de rota para quem dá a missão.",
    ["Shopping list"] =
      "Lista de compras",
    ["Full plan"] =
      "Plano completo",
    ["Reading the recipes of this profession..."] =
      "Lendo as receitas desta profissão...",
    ["%d%% chance per craft (%s)"] =
      "%d%% de chance por criação (%s)",
    ["Step panel: off"] =
      "Painel de etapa: desativado",
    ["Step panel: on (shown with the profession window)"] =
      "Painel de etapa: ativado (exibido com a janela de profissão)",
    ["Keep for your group"] =
      "Guarde para seu grupo",
    ["%s: %d for %s"] =
      "%s: %d para %s",
    ["and %d more"] =
      "e mais %d",
    ["You sold %s"] =
      "Você vendeu %s",
    ["Buy back"] =
      "Recomprar",
    ["you"] =
      "você",
    ["At a merchant or the auction house: items in your bags that your group needs."] =
      "Num vendedor ou na casa de leilões: itens nas suas bolsas que seu grupo precisa.",
    ["Next rank"] =
      "Próximo nível",
    ["At the skill cap: the Expert book (vendor or AH), the Artisan quest found in Questie (click for a waypoint to its giver), or the trainer."] =
      "No máximo da perícia: o livro de Especialista (vendedor ou leilão), a missão de Artífice achada no Questie (clique: ponto até quem a dá) ou o instrutor.",
    ["Mats ready, profession cooldowns ready on any of your characters, craft requests, items your group needs when you open a merchant or the AH (with Buy back after a sale), and opt-in upgrades. Each one can be turned off in Manage group."] =
      "Materiais prontos, recargas de profissão prontas em qualquer personagem seu, pedidos de criação, itens que seu grupo precisa ao abrir um vendedor ou o leilão (com Recomprar após uma venda) e melhorias opcionais. Cada um pode ser desligado em Gerenciar grupo.",
    ["TSM or Auctionator (prices), Questie (positions), TomTom (waypoints), Pawn (upgrades for each class and spec). All optional."] =
      "TSM ou Auctionator (preços), Questie (posições), TomTom (pontos de rota), Pawn (melhorias para cada classe e especialização). Todos opcionais.",
    -- Group plan
    ["Spare"] =
      "Sobra",
    ["Group plan"] =
      "Plano do grupo",
    ["What the group still needs, what it already holds, and who farms what."] =
      "O que ainda falta ao grupo, o que ele já tem e quem farma o quê.",
    ["Objective:"] =
      "Objetivo:",
    ["Lowest group cost"] =
      "Menor custo do grupo",
    ["Market value"] =
      "Valor de mercado",
    ["Least gold spent by the group: stock already held in the group counts as free."] =
      "Menos ouro gasto pelo grupo: o estoque que o grupo já tem conta como grátis.",
    ["Every material at its market value, as if each character were alone."] =
      "Cada material pelo valor de mercado, como se cada personagem estivesse sozinho.",
    ["Material"] =
      "Material",
    ["Needed"] =
      "Necessário",
    ["To get"] =
      "A obter",
    ["Est. cost"] =
      "Custo est.",
    ["Farming"] =
      "Farm",
    ["Farmed by %s"] =
      "Farmado por %s",
    ["Drop"] =
      "Desistir",
    ["I'll farm it"] =
      "Eu farmo",
    ["Estimated cost for the group: %s"] =
      "Custo estimado para o grupo: %s",
    ["Estimated cost for the group: at least %s (some items have no price)."] =
      "Custo estimado para o grupo: pelo menos %s (alguns itens não têm preço).",
    ["Estimated cost for the group: unknown (TSM or Auctionator give AH prices)."] =
      "Custo estimado para o grupo: desconhecido (TSM ou Auctionator dão preços do leilão).",
    ["%d %s needed for %s. Do you want to farm them?"] =
      "%d %s necessários para %s. Quer farmá-los?",
    ["Farming done: %s"] =
      "Farm concluído: %s",
    ["Give them from You can give in the Group view, or by mail."] =
      "Entregue pelo Você pode dar na visão Grupo, ou por correio.",
    ["Show the farming tracker (your farming assignments from the Group plan)."] =
      "Mostrar o rastreador de farm (suas tarefas de farm do Plano do grupo).",
    ["Plans count stock already held in the group as free (or every mat at market value: Manage group > Options). The Group plan view lists what the group still needs and its cost; take a material with I'll farm it and a small tracker follows your progress."] =
      "Os planos contam como grátis o estoque que o grupo já tem (ou cada material pelo valor de mercado: Gerenciar grupo > Opções). A visão Plano do grupo lista o que ainda falta ao grupo e quanto custa; pegue um material com Eu farmo e um pequeno rastreador mostra seu progresso.",
    ["Guild directory"] =
      "Diretório da guilda",
    ["%d crafter"] =
      "%d artesão",
    ["%d crafters"] =
      "%d artesãos",
    ["Right box: list the character in the guild directory (professions and recipes only, sent to your guild)."] =
      "Caixa da direita: listar o personagem no diretório da guilda (só profissões e receitas, enviadas à sua guilda).",
    ["List in guild directory"] =
      "Listar no diretório da guilda",
    ["Opt-in, per character: List in guild directory in Manage group (or /comrade list) sends its professions and recipes to guildmates who use ComradeCraft. Search who can craft an item, whisper them, or ask for the craft if they are in your group. Item tooltips name up to 3 guild crafters."] =
      "Opcional, por personagem: Listar no diretório da guilda, em Gerenciar grupo (ou /comrade list), envia as profissões e receitas dele aos membros da guilda que usam ComradeCraft. Procure quem pode criar um item, sussurre para ele ou peça a criação se ele estiver no seu grupo. As dicas de itens mostram até 3 artesãos da guilda.",
    ["Whisper"] =
      "Sussurrar",
    ["Nobody is listed yet. The directory is opt-in: each player lists their own characters in Manage group (List in guild directory) or with /comrade list."] =
      "Ninguém está listado ainda. O diretório é opcional: cada jogador lista os próprios personagens em Gerenciar grupo (Listar no diretório da guilda) ou com /comrade list.",
    ["Type a product or recipe name in the search box."] =
      "Digite o nome de um item ou de uma receita na caixa de busca.",
    ["No crafter found."] =
      "Nenhum artesão encontrado.",
    ["... and %d more"] =
      "... e mais %d",
    ["Who in your guild can craft what. Each player lists their own characters (opt-in)."] =
      "Quem na sua guilda pode criar o quê. Cada jogador lista os próprios personagens (opcional).",
    ["Guild crafters: %s"] =
      "Artesãos da guilda: %s",
    ["%s is listed in the guild directory"] =
      "%s está listado no diretório da guilda",
    ["%s is no longer listed in the guild directory"] =
      "%s não está mais listado no diretório da guilda",
    ["You are not in a guild: the entry is sent once you are."] =
      "Você não está em uma guilda: a entrada será enviada quando estiver em uma.",
    ["directory: %d characters listed. /comrade directory TEXT searches them."] =
      "diretório: %d personagens listados. /comrade directory TEXTO busca entre eles.",
    ["directory: no crafter for %s"] =
      "diretório: nenhum artesão para %s",
    -- UI polish, bags, mail & friends
    ["%d item"] = "%d item",
    ["%d items"] = "%d itens",
    ["Add %s"] = "Adicionar %s",
    ["Add target"] = "Adicionar alvo",
    ["Cancel"] = "Cancelar",
    ["Click a member to highlight their items."] = "Clique em um membro para destacar os itens dele.",
    ["Click to select recipient and highlight needed items in your bags."] =
      "Clique para selecionar o destinatário e destacar os itens necessários nas suas bolsas.",
    ["Collapse all"] = "Recolher tudo",
    ["ComradeCraft: Add to group"] = "ComradeCraft: Adicionar ao grupo",
    ["Expand all"] = "Expandir tudo",
    ["Filter recipes..."] = "Filtrar receitas...",
    ["Search stock or crafters..."] = "Buscar estoque ou artesãos...",
    ["For %s"] = "Para %s",
    ["Friend"] = "Amigo",
    ["Guild"] = "Guilda",
    ["Highlight items for your group in your bags (and focus a recipient's items when mailing)."] =
      "Destacar nas bolsas os itens úteis ao grupo (e focar nos do destinatário ao enviar correio).",
    ["Highlighted in your bags"] = "Destacado nas suas bolsas",
    ["Nothing to send from your bags."] = "Nada para enviar das suas bolsas.",
    ["Online in your party, friends or guild:"] = "Online no seu grupo, amigos ou guilda:",
    ["Party"] = "Grupo",
    ["Ready to send from your bags"] = "Pronto para enviar das bolsas",
    ["Retry"] = "Tentar de novo",
    ["Search guild crafters..."] = "Buscar artesãos...",
    ["Send x%d to %s"] = "Enviar x%d para %s",
    ["Send x%d to %s (%s)"] = "Enviar x%d para %s (%s)",
    ["To send from your bags: %s"] = "Para enviar das bolsas: %s",
    ["You cannot add yourself."] = "Você não pode adicionar a si mesmo.",
    ["craft request"] = "pedido de criação",
    ["waiting for reply"] = "aguardando resposta",
    ["Share all"] = "Compartilhar todos",
    ["Unshare all"] = "Parar todos",
    ["Automatically share new characters on this account"] =
      "Compartilhar automaticamente novos personagens desta conta",
    ["All characters (%d) are now shared with your group"] =
      "Todos os personagens (%d) agora estão compartilhados com seu grupo",
    ["No character is shared anymore"] = "Nenhum personagem está mais compartilhado",
    ["%s requires higher %s skill; skipped for waypoints until you level up."] =
      "%s exige mais perícia em %s; ignorado nos pontos de rota até você subir.",
    ["Right-click: skip this recipe and recalculate."] =
      "Clique direito: ignorar esta receita e recalcular.",
    ["Reset skipped (%d)"] = "Restaurar ignoradas (%d)",
    -- Trade, Merchant, Wishlist, Cooldowns & UI rework
    ["%d tracked"] = "%d acompanhado(s)",
    ["%s wants to join your group"] = "%s quer entrar no seu grupo",
    ["Accept to share your checked characters with them."] =
      "Aceite para compartilhar seus personagens marcados com ele.",
    ["Add to wishlist"] = "Adicionar à lista",
    ["All materials are in your bags."] = "Todos os materiais estão nas suas bolsas.",
    ["Buy plan reagents (%s)"] = "Comprar reagentes (%s)",
    ["Click to sync now with your group."] = "Clique para sincronizar agora com seu grupo.",
    ["Compare routes"] = "Comparar rotas",
    ["Craft"] = "Criar",
    ["Disenchant"] = "Desencantar",
    ["For who:"] = "Para quem:",
    ["Group cooldowns"] = "Recargas do grupo",
    ["Hide route comparison"] = "Ocultar comparação",
    ["Ignore"] = "Ignorar",
    ["Materials"] = "Materiais",
    ["No craft pinned yet. Right-click any recipe in your Can craft tab to add it here, track its materials and get notified when ready."] =
      "Nenhuma criação fixada. Clique com o botão direito em uma receita em Pode criar para adicionar aqui, acompanhar os materiais e ser avisado quando estiver pronto.",
    ["No disenchantable items in your bags."] = "Nenhum item desencantável nas suas bolsas.",
    ["Not enough gold (%s needed)."] = "Ouro insuficiente (%s necessários).",
    ["Note (optional):"] = "Nota (opcional):",
    ["Overview"] = "Resumo",
    ["Pin"] = "Fixar",
    ["Pin on screen"] = "Fixar na tela",
    ["Pinned crafts to track materials for yourself or friends."] =
      "Criações fixadas para acompanhar materiais para você ou amigos.",
    ["Place needed items"] = "Colocar necessários",
    ["Plan reagents"] = "Reagentes do plano",
    ["Quantity:"] = "Quantidade:",
    ["Ready"] = "Pronto",
    ["Ready (some mats in bank/mail)"] = "Pronto (materiais no banco/correio)",
    ["Ready to craft!"] = "Pronto para criar!",
    ["Right-click: add to Wishlist."] = "Clique direito: adicionar à lista de desejos.",
    ["Show the wishlist tracker on screen (pinned crafts)."] =
      "Mostrar o rastreador da lista de desejos na tela.",
    ["Trade window is full (%d slots)."] = "Janela de troca cheia (%d espaços).",
    ["Unpin"] = "Desafixar",
    ["Wishlist"] = "Lista de desejos",
    ["Wishlist ready: %dx %s"] = "Pronto para criar: %dx %s",
    ["none pinned"] = "nenhum fixado",
    -- Synergies, Audit, Loot, AH Panel, Buy vs Farm
    ["%d small bags (min %d slots) -> %s (%d slots)"] = "%d bolsas pequenas (mín. %d esp.) -> %s (%d esp.)",
    ["%s can craft %dx %s from group's %s for %s"] = "%s pode criar %dx %s com %s do grupo para %s",
    ["Advice"] = "Conselho",
    ["Back"] = "Costas",
    ["Buy"] = "Comprar",
    ["Buy/Farm"] = "Compra/Farm",
    ["Chest"] = "Torso",
    ["Click an item to search it."] = "Clique em um item para buscar.",
    ["Click: search in Auction House."] = "Clique: buscar na Casa de Leilões.",
    ["Click: waypoint to farm spot."] = "Clique: ponto de rota para o local de farm.",
    ["Cross-profession links between your group's active plans."] =
      "Sinergias entre profissões nos planos ativos do grupo.",
    ["Disenchant %dx %s (%s)"] = "Desencantar %dx %s (%s)",
    ["Disenchant for your enchanting plan"] = "Desencantar para seu plano de encantamento",
    ["Everyone's bags, enchants and gear are up to date."] =
      "Bolsas, encantamentos e equipamentos do grupo estão em dia.",
    ["Farm"] = "Farmar",
    ["Farm %s: %s (%s %d, %d)"] = "Farmar %s: %s (%s %d, %d)",
    ["Farm spot"] = "Local de farm",
    ["Feet"] = "Pés",
    ["Gear"] = "Equipamento",
    ["Gold: %s"] = "Ouro: %s",
    ["Group synergies"] = "Sinergias do grupo",
    ["Group upgrades"] = "Melhorias do grupo",
    ["Hands"] = "Mãos",
    ["Known by %s"] = "Conhecido por %s",
    ["Loot roll: %s - needed now by %s"] = "Saque: %s - necessário agora para %s",
    ["Loot roll: %s - unknown by %s"] = "Saque: %s - desconhecido por %s",
    ["No known farm location for %s."] = "Nenhum local de farm conhecido para %s.",
    ["Send %dx %s to %s to disenchant (%s)"] = "Enviar %dx %s para %s desencantar (%s)",
    ["Send to %s to disenchant"] = "Enviar para %s desencantar",
    ["Shield"] = "Escudo",
    ["Small bags, unenchanted gear and craftable upgrades your group can make."] =
      "Bolsas pequenas, itens sem encantamento e melhorias criáveis pelo grupo.",
    ["To buy at the AH"] = "Comprar no leilão",
    ["Total: %s (you have %s)"] = "Total: %s (você tem %s)",
    ["Unenchanted %s -> %s"] = "%s sem encantamento -> %s",
    ["Unknown by %s (%s %d/%d)"] = "Desconhecido por %s (%s %d/%d)",
    ["Upgrades"] = "Melhorias",
    ["Vendor"] = "Vendedor",
    ["Waypoint: %s (%s %d, %d)"] = "Ponto de rota: %s (%s %d, %d)",
    ["Wrist"] = "Pulsos",
    ["Your gold: %s"] = "Seu ouro: %s",
    ["by %s"] = "por %s",
    ["by %s (guild)"] = "por %s (guilda)",
    ["can learn now"] = "pode aprender agora",
    ["needs skill %d"] = "exige %d",
    ["+%d score"] = "+%d pontos",
    ["Head"] = "Cabeça",
    ["Neck"] = "Pescoço",
    ["Shoulder"] = "Ombros",
    ["Waist"] = "Cintura",
    ["Legs"] = "Pernas",
    ["Finger"] = "Dedo",
    ["Trinket"] = "Berloque",
    ["Off-Hand"] = "Mão secundária",
    ["Ranged"] = "Longo alcance",
    ["Spec: %s"] = "Espec: %s",
    ["Spec set to %s."] = "Especialização definida para %s.",
    ["Unknown spec. Available: %s"] = "Especialização desconhecida. Disponíveis: %s",
    ["Crafts upgrade for: %s"] = "Cria melhoria para: %s",
    ["Useful enchant for: %s"] = "Encantamento útil para: %s",
    ["Leveling plan"] = "Plano de nivelamento",
    ["Upgrade for %s (%s)"] = "Melhoria para %s (%s)",
    ["Good enchant for %s"] = "Bom encantamento para %s",
    ["Click to train."] = "Clique para aprender.",
    ["Recommended recipes"] = "Receitas recomendadas",
    ["mats ready"] = "mats prontos",
    ["Soon (+1-4 lvl)"] = "Em breve (+1-4 nv.)",
    ["Consumables"] = "Consumíveis",
    ["Patterns to hunt"] = "Receitas para farmar",
    ["Waypoint"] = "Rota",
    ["Group materials:"] = "Materiais do grupo:",
    ["%d mobs"] = "%d inimigos",
    ["1 mob"] = "1 inimigo",
    ["in bank"] = "no banco",
    ["In bank (retrieve first)"] = "No banco (retire primeiro)",
    ["Full name (First Last) required for %s: log them in once or type their full name first."] =
      "Nome completo (Nome Sobrenome) obrigatório para %s: conecte-o uma vez ou digite o nome completo primeiro.",
    ["Withdraw from bank"] = "Retirar do banco",
    ["Withdraw needed"] = "Retirar o necessário",
    ["Click an item to withdraw it."] = "Clique em um item para retirá-lo.",
    ["Your bags are full."] = "Suas bolsas estão cheias.",
    ["For your plan"] = "Para seu plano",
    ["To send to %s"] = "Para enviar a %s",
    ["Right-click: %dx %s -> %dx %s"] = "Clique direito: %dx %s -> %dx %s",
    ["BoE patterns"] = "Moldes BoE",
    ["Share in chat"] = "Compartilhar no chat",
    ["Shared bank alt"] = "Alt banco compartilhado",
    ["Shared bank alt: all items on this character (bags, bank, mail) appear as available to your group, and members can request them via the addon."] = "Alt banco compartilhado: todos os itens deste personagem (bolsas, banco, correio) aparecem disponíveis para o grupo e todos podem solicitá-los pelo addon.",
    ["Bank"] = "Banco",
    ["Ask %s for %s"] = "Pedir a %s: %s",
    ["%s asks %s for %dx %s."] = "%s pede a %s: %dx %s.",
    ["Request"] = "Pedir",
    ["No items stored yet."] = "Nenhum item armazenado ainda.",
    ["Filter items..."] = "Filtrar itens...",
    ["Your group's skill levels, synergies, items you can give, and active cooldowns."] = "Níveis de profissão do grupo, sinergias, itens que você pode doar e recargas ativas.",
    ["All materials your group still needs, sorted by urgency. Type to find who can craft something."] = "Todos os materiais que o grupo ainda precisa, ordenados por urgência. Digite para encontrar quem pode criar algo.",
    ["Craftable BiS gear, enchants, consumables, small bags, and patterns to hunt for each member."] = "Equipamento BiS criável, encantamentos, consumíveis, bolsas pequenas e moldes para caçar por membro.",
    ["Green items in your bags: keep for enchants or upgrades, sell on the AH, or disenchant."] = "Itens verdes nas suas bolsas: guardar para encantamentos ou melhorias, vender no leilão ou desencantar.",
    ["Left: Group overview, Materials, Craftable BiS Upgrades, Wishlist, Requests, and every character in your group."] = "À esquerda: Visão geral, Materiais, Melhorias BiS, Lista de desejos, Pedidos e cada personagem do grupo.",
    ["Bags highlight items your group needs; helper panels dock at Mail, Bank, Trade, Merchant, AH, and Trainers."] = "As bolsas destacam o que o grupo precisa; painéis auxiliares se acoplam em Correio, Banco, Troca, Mercador, Leilão e Treinadores.",
    ["Nothing is shared yet. Here, in Manage group, check characters to share (or flag a Shared bank alt), then add friends below. Mutually added peers relay updates automatically."] = "Nada está compartilhado ainda. Marque os personagens para compartilhar (ou um Alt banco compartilhado) e adicione amigos abaixo. Contatos mútuos retransmitem atualizações automaticamente.",
    ["Reserved %dx %s for %s."] = "Reservado %dx %s para %s.",
    ["Reservation removed for %s."] = "Reserva removida para %s.",
    ["Reserve for..."] = "Reservar para...",
    ["Unlock reservation"] = "Desbloquear reserva",
    ["Usage: /comrade reserve [Item] Name [qty]"] = "Uso: /comrade reserve [Item] Nome [qtd]",
    ["Usage: /comrade unreserve [Item]"] = "Uso: /comrade unreserve [Item]",
    ["Reserved for %s"] = "Reservado para %s",
    ["Reserved for %s (x%d) - Alt+Right-click to unlock"] = "Reservado para %s (x%d) - Alt+Clique direito para liberar",
    ["Reserved for you by %s (x%d)"] = "Reservado para você por %s (x%d)",
    ["Reserved"] = "Reservado",
    ["Favorite"] = "Favorito",
    ["Unstar"] = "Remover",
    ["Farming for you"] = "Farmando para você",
    ["Filter characters..."] = "Filtrar personagens...",
    ["by %s (you)"] = "por %s (você)",
    ["crafting"] = "criando",
    ["shipped"] = "enviado",
    ["Crafting"] = "Criando",
    ["Shipped"] = "Enviado",
    ["Ready to craft"] = "Pronto para criar",
    ["Ready to ship"] = "Pronto para enviar",
    ["Missing %s"] = "Falta %s",
    ["Missing %d"] = "Faltam %d",
    ["Reserved for you"] = "Reservado para você",
    ["Your reserved items"] = "Seus itens reservados",
    ["Unlock"] = "Liberar",
    ["reserved"] = "reservado",
    ["Click: reserve for %s."] = "Clique: reservar para %s.",
    ["Click: request from %s [Bank]."] = "Clique: pedir para %s [Banco].",
    ["Favorites"] = "Favoritos",
    ["My characters"] = "Meus personagens",
    ["Group members"] = "Membros do grupo",
    ["%d farming"] = "%d farmando",
    ["Auto-marked request %dx %s as shipped."] = "Pedido %dx %s marcado automaticamente como enviado.",
    ["Alt+Right-click any bag item to reserve/lock it for a friend before mailing."] = "Alt+Clique direito em qualquer item das bolsas para reservá-lo para um amigo antes de enviar.",
    ["Item reservations"] = "Reservas de itens",
    ["  %s: %d crafts, %d points (expected %.1f)%s"] = "  %s: %d criações, %d pontos (esperado %.1f)%s",
    ["Add friends"] = "Adicionar amigos",
    ["All window and tracker positions reset."] = "Todas as posições de janelas e rastreadores redefinidas.",
    ["Auction House panel"] = "Painel de Casa de Leilões",
    ["Bank panel"] = "Painel de Banco",
    ["Browse Can craft"] = "Ver Pode criar",
    ["Browse Upgrades"] = "Ver Melhorias",
    ["Companion panels"] = "Painéis auxiliares",
    ["Configure companion panels, UI scale, sounds, and window positions."] = "Configure painéis auxiliares, escala da interface, sons e posições.",
    ["Crafts logged by you and your group automatically calibrate skill-up chances for WoW Forever."] = "Criações registradas por você e seu grupo calibram automaticamente as chances no WoW Forever.",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never."] = "Cada passo mostra o que aprender no treinador, o que criar primeiro (rolos, barras...) e quantos. Clique abre a receita, Shift+clique envia no chat. Cores: laranja sempre sobe, amarelo geralmente, verde raramente, cinza nunca.",
    ["Interface"] = "Interface",
    ["Known recipes. Right-click to pin to Wishlist, or click a friend's recipe to request it."] = "Receitas conhecidas. Clique direito para fixar na Lista de desejos, ou clique na receita de um amigo para pedir.",
    ["Learn from a trainer of this profession (requires skill %d, level %d)."] = "Aprenda com um treinador desta profissão (requer perícia %d, nível %d).",
    ["Left-click: open window  |  Right-click: options"] = "Clique esquerdo: abrir janela  |  Clique direito: opções",
    ["List my character"] = "Listar meu personagem",
    ["Mailbox panel"] = "Painel de Correio",
    ["Merchant panel"] = "Painel de Mercador",
    ["No friends in your group yet. Add guildmates or friends to share mats and upgrades."] = "Nenhum amigo no seu grupo ainda. Adicione amigos ou membros da guilda para compartilhar materiais e melhorias.",
    ["Open ComradeCraft"] = "Abrir ComradeCraft",
    ["Play sound notifications"] = "Tocar notificações sonoras",
    ["Reset window positions"] = "Redefinir posições",
    ["Show minimap button"] = "Mostrar botão no minimapa",
    ["Step-by-step profession leveling route, cost comparison, and trainer guide."] = "Rota passo a passo, comparação de custos e guia de treinadores.",
    ["Sync: %d players in the group, %d suggested."] = "Sync: %d jogadores no grupo, %d sugeridos.",
    ["Toggle ComradeCraft"] = "Mostrar / ocultar ComradeCraft",
    ["Trade panel"] = "Painel de Troca",
    ["Trainer panel"] = "Painel de Treinador",
    ["Window scale"] = "Escala da janela",
    ["AH ~%s"] = "Leilão ~%s",
    ["For"] = "Para",
    ["Important unlearned patterns to buy or farm for yourself and your group (with drop rate and waypoints)."] = "Moldes importantes não aprendidos para comprar ou farmar para você e seu grupo (com taxa de drop e pontos de rota).",
    ["No unlearned upgrade patterns found for this character right now."] = "Nenhum molde de melhoria não aprendido encontrado para este personagem no momento.",
    ["Patterns"] = "Moldes",
    ["Valuable unlearned patterns for yourself and your group: where to buy or farm them, drop rate when known, and 1-click waypoints."] = "Moldes valiosos não aprendidos para você e seu grupo: onde comprar ou farmar, taxa de drop quando conhecida e pontos de rota em 1 clique.",
  ["Bargains"] = "Ofertas",
  ["Deals"] = "Ofertas",
  ["Group needs spotted below market price."] = "Necessidades do grupo vistas abaixo do mercado.",
  ["Character"] = "Personagem",
  ["Slot"] = "Espaço",
  ["Group by:"] = "Agrupar por:",
  ["Enchants"] = "Encantamentos",
  ["Bags"] = "Bolsas",
  ["Claim CD"] = "Pedir CD",
  ["Estimated net profit and 1-click Claim CD for your group's long cooldowns."] = "Lucro líquido estimado e pedido em 1 clique para recargas longas do grupo.",
  ["Craft chain planned (%d steps for %s)."] = "Cadeia de criação planejada (%d etapas para %s).",
  ["Multi-profession craft chain"] = "Cadeia de criação multiprossões",
  ["Plan chain (%d)"] = "Cadeia (%d)",
  ["Forever P2P DB: %d recipe bounds, %d vendors, %d drops (from %d peers)."] = "Base Forever P2P: %d limites, %d vendedores, %d drops (de %d pares).",
  ["In %s (%d finds):"] = "Em %s (%d achados):",
  ["In %s: %s"] = "Em %s: %s",
  ["In your zone: %s"] = "Na sua zona: %s",
  ["Nothing specific for your group found in %s."] = "Nada específico para o grupo encontrado em %s.",
  ["Rare drops, vendors, patterns and materials useful to your group right here."] = "Mobs raros, vendedores, receitas e materiais úteis ao grupo bem aqui.",
  ["world drop"] = "saque mundial",
  ["world drop - here (%s)"] = "saque mundial - aqui (%s)",
  ["world drop - near %s"] = "saque mundial - perto de %s",
  ["%d bounds  |  %d custom recipes  |  %d disenchants  |  %d vendors  |  %d drops  (%d peers)"] = "%d limites  |  %d receitas custom  |  %d desencantamentos  |  %d mercadores  |  %d saques  (%d pares)",
  ["%d in transit"] = "%d em trânsito",
  ["Accepted craft requests & pinned wishlist for this profession."] = "Pedidos aceitos e lista de desejos fixada para esta profissão.",
  ["Already mailed between group accounts — counted as on the way so nobody double-sends."] = "Já enviado entre contas do grupo — contado a caminho para evitar envios duplicados.",
  ["Applied craft kit \"%s\" (x%d)."] = "Kit \"%s\" aplicado (x%d).",
  ["Apply x1"] = "Aplicar x1",
  ["Apply x5"] = "Aplicar x5",
  ["Click to open recipe (trade slot 7)"] = "Clique: abrir receita (espaço troca 7)",
  ["Click to open this enchant for the trade slot."] = "Clique para abrir este encantamento para o espaço de troca.",
  ["Craft kits"] = "Kits de criação",
  ["Craft request (%s)"] = "Pedido (%s)",
  ["Deliver to %s"] = "Entregar para %s",
  ["Enchant auto-completes request on trade"] = "Encantamento conclui o pedido na troca",
  ["Forever P2P database"] = "Banco P2P Forever",
  ["In group stock: \"%s\""] = "No estoque do grupo: \"%s\"",
  ["In transit"] = "Em trânsito",
  ["In transit (1h mail)"] = "Em trânsito (correio 1h)",
  ["Next: %s (%d left)"] = "Próximo: %s (%d rest.)",
  ["Observed WoW Forever recipe bounds, custom recipes, disenchants, vendors and drops shared automatically."] = "Limites Forever, receitas custom, desencantamentos, mercadores e saques compartilhados automaticamente.",
  ["Orders (%d)"] = "Pedidos (%d)",
  ["Reserved by %s"] = "Reservado por %s",
  ["Reusable craft bundles (raid, dungeon, reroll) — apply in 1 click."] = "Pacotes reutilizáveis (raide, masmorra, alt) — aplique em 1 clique.",
  ["Save as kit"] = "Salvar kit",
  ["Save current wishlist as a reusable kit"] = "Salvar lista atual como kit reutilizável",
  ["Save kit"] = "Salvar",
  ["Saved craft kit \"%s\" (%d recipes)."] = "Kit \"%s\" salvo (%d receitas).",
  ["Sent %d/%d"] = "Enviado %d/%d",
  ["Sent %d/%d %s."] = "Enviado %d/%d %s.",
  ["Share now"] = "Compartilhar",
  ["Step %d/%d"] = "Etapa %d/%d",
  ["Waiting previous step"] = "Aguardando etapa anterior",
  ["Wishlist completed: %s"] = "Lista concluída: %s",
  ["measured"] = "medido",
    -- Target skill (Plan tab)
    ["Queued %dx %s: open the profession window and click Craft next."] = "%dx %s na fila: abra a janela da profissão e clique em Criar próximo.",
    ["Restock: %s"] = "Reabastecer: %s",
    ["Restock"] = "Reabastecer",
    ["Queue"] = "Fila",
    ["No risk: sell to a merchant"] = "Sem risco: vender a um mercador",
    ["net %s per craft at a merchant"] = "líquido %s por criação num mercador",
    ["Auctionator shopping list ready: %s (%d items)."] = "Lista de compras do Auctionator pronta: %s (%d itens).",
    ["once per cooldown"] = "uma vez por recarga",
    ["Cooldown goldmakers"] = "Criações lucrativas com recarga",
    ["ready in %s"] = "pronto em %s",
    ["Goldmaking"] = "Ganhar ouro",
    ["net %s per craft"] = "líquido %s por criação",
    ["~%d sold per day"] = "~%d vendidos por dia",
    ["~%s per day"] = "~%s por dia",
    ["sales volume unknown"] = "volume de vendas desconhecido",
    ["craft the %s yourself"] = "crie você mesmo: %s",
    ["craft the %s yourself (recipe to learn)"] = "crie você mesmo: %s (receita a aprender)",
    ["Crafts that earn the most at the auction house, at the pace it buys them (mats bought or crafted, whichever is cheaper; after the cut and deposit)."] = "As criações que mais rendem na casa de leilões, no ritmo em que ela as compra (materiais comprados ou criados, o mais barato; após a taxa e o depósito).",
    ["No auction prices yet: scan the auction house or install TSM or Auctionator."] = "Ainda sem preços de leilão: escaneie a casa de leilões ou instale TSM ou Auctionator.",
    ["stackable"] = "empilhável",
    ["one by one"] = "uma a uma",
    ["Repeat goldmakers"] = "Criações lucrativas repetíveis",
    ["No known recipe makes money at current prices."] = "Nenhuma receita conhecida dá lucro aos preços atuais.",
    ["Recipes worth buying"] = "Receitas que valem a compra",
    ["recipe %s, paid back in %d crafts"] = "receita %s, paga em %d criações",
    ["What if I learned:"] = "E se eu aprendesse:",
    ["Alternative: %s from the quest %s would save about %s."] = "Alternativa: %s da missão %s economizaria cerca de %s.",
    ["Get a %s"] = "Obtenha: %s",
    ["Craft it first: %s."] = "Crie primeiro: %s.",
    ["Sold by trade supplies vendors (%s)."] = "Vendido pelos fornecedores de suprimentos comerciais (%s).",
    ["Sold by trade supplies vendors."] = "Vendido pelos fornecedores de suprimentos comerciais.",
    ["Craft at: %s"] = "Criar junto a: %s",
    ["Nearest: %s"] = "Mais próximo: %s",
    ["Location not known yet: saved the first time someone crafts there."] = "Local ainda desconhecido: é salvo na primeira vez que alguém cria lá.",
    ["Anvil"] = "Bigorna",
    ["Forge"] = "Forja",
    ["Loom"] = "Tear",
    ["Cooking Fire"] = "Fogueira de cozinha",
    ["Tanning Rack"] = "Varal de curtimento",
    ["Spinning Wheel"] = "Roca",
    ["Sewing Machine"] = "Máquina de costura",
    ["Master Forge"] = "Forja mestra",
    ["Alchemy Lab"] = "Laboratório de alquimia",
    ["Iron Oven"] = "Forno de ferro",
    ["Fermenter"] = "Fermentador",
    ["Black Anvil"] = "Bigorna Negra",
    ["Black Forge"] = "Forja Negra",
    ["With your budget you can reach %d (target %d)."] = "Com o seu orçamento você chega a %d (meta %d).",
    ["Filtered by the budget: the greyed steps need about %s more."] = "Filtrado pelo orçamento: os passos em cinza precisam de cerca de %s a mais.",
    ["Remove budget"] = "Remover orçamento",
    ["Budget (g):"] = "Orçamento (o):",
    ["Budget"] = "Orçamento",
    ["Gold you put into leveling, Enter to apply; empty = no limit. Sales of earlier crafts are reinvested."] = "Ouro que você investe para subir, Enter para aplicar; vazio = sem limite. As vendas do que fabricou antes são reinvestidas.",
    ["Enter to apply"] = "Enter para aplicar",
    ["no limit - type gold, Enter to apply"] = "sem limite - digite o ouro, Enter para aplicar",
    ["Gold needed at the worst moment: %s (sales of earlier crafts reinvested)."] = "Ouro necessário no pior momento: %s (vendas do que fabricou antes reinvestidas).",
    ["Sell the crafts:"] = "O que fazer com o que fabricou:",
    ["%s: %s"] = "%s: %s",
    ["%d at the AH"] = "%d no leilão",
    ["disenchant %d with %s"] = "desencantar %d com %s",
    ["%d to a merchant"] = "%d ao vendedor",
    ["Buy %s at the auction house (skill %s, %s)"] = "Comprar %s na casa de leilões (perícia %s, %s)",
    ["Auction house - skill %s - %s"] = "Casa de leilões - perícia %s - %s",
    ["Buy recipe: %s"] = "Comprar receita: %s",
    ["Buy %s from %s (skill %s, %s)"] = "Comprar %s de %s (perícia %s, %s)",
    ["Vendor: %s - skill %s - %s"] = "Vendedor: %s - perícia %s - %s",
    ["price unknown until you visit the vendor"] = "preço desconhecido até visitar o vendedor",
    ["a vendor"] = "um vendedor",
    ["Trainer & recipes"] = "Instrutor e receitas",
    ["+ Trainer & recipes: %s (in the net). To buy = missing mats (AH + merchant); net = to buy - resale + trainer & recipes."] = "+ Instrutor e receitas: %s (no líquido). A comprar = materiais em falta (leilão + vendedor); líquido = a comprar - revenda + instrutor e receitas.",
    ["(your side only)"] = "(só do seu lado)",
    ["Target:"] = "Meta:",
    ["Target skill"] = "Perícia-alvo",
    ["Type a skill (up to 300) and press Enter. Mouse wheel: +/-5 (Shift: 25)."] = "Digite uma perícia (máx. 300) e tecle Enter. Roda do mouse: +/-5 (Shift: 25).",
    ["(cap) - click to change, Enter to apply"] = "(máx.) - clique para mudar, Enter para aplicar",
    ["click to change, Enter to apply"] = "clique para mudar, Enter para aplicar",
    ["Target %d"] = "Mirar %d",
    ["Cap"] = "Máx.",
    ["Level %d needed to learn this rank (now %d)."] = "Nível %d necessário para aprender este grau (agora %d).",
    ["Total %d to %d (%s prices)"] = "Total de %d a %d (preços %s)",
    ["Total %d to %d: gross %s, to buy %s, resale %s, trainer %s, net %s (%s prices)."] = "Total de %d a %d: bruto %s, a comprar %s, revenda %s, instrutor %s, líquido %s (preços %s).",
    ["Gross"] = "Bruto",
    ["To buy"] = "A comprar",
    ["Resale"] = "Revenda",
    ["Net"] = "Líquido",
    ["not counted"] = "não contado",
    ["Stops at"] = "Para em",
    ["Other route: trainer not counted."] = "Outra rota: instrutor não contado.",
    ["> = some prices are unknown: a cost is a minimum, a profit (+<) a maximum."] = "> = alguns preços são desconhecidos: um custo é um mínimo, um lucro (+<) um máximo.",
}
