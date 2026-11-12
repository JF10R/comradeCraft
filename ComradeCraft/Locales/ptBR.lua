-- ptBR translations. Keys: the English text (see Locale.lua); loaded only on a ptBR client.
local _, ns = ...
local loc = GetLocale and GetLocale()
if loc ~= "ptBR" then return end
ns.Translations = ns.Translations or {}
ns.Translations[loc] = {
    ["commands: /comrade (window) | share [off] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"] =
      "comandos: /comrade (janela) | share [off] | add NOME | remove NOME | peers | sync | guildping [off] | shop [profissão] | tracker [reset] | mail NOME | scan | needs | stats | api | audit | log clear",
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
    ["  %s: %d crafts, %d points, Classic formula %.1f%s"] =
      "  %s: %d criações, %d pontos, fórmula Classic %.1f%s",
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
    ["Estimated cost: %s (%s prices)."] =
      "Custo estimado: %s (preços de %s).",
    ["Estimated cost: at least %s (%s prices, some items have no price)."] =
      "Custo estimado: pelo menos %s (preços de %s, alguns itens não têm preço).",
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
    ["Sync: %d players in the group, %d suggested. skill ~N: value taken from Classic, unconfirmed."] =
      "Sync: %d jogadores no grupo, %d sugeridos. skill ~N: valor tirado do Classic, não confirmado.",
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
    ["Crafts logged by you and your group correct the Classic formula once a color has enough of them."] =
      "As criações registradas por você e seu grupo corrigem a fórmula Classic quando uma cor tem o suficiente.",
    ["The window"] =
      "A janela",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "À esquerda: o grupo e depois cada personagem. Plano = como subir uma profissão; Pode criar = o que esse personagem pode fazer para o grupo. Os chips filtram por profissão.",
    ["Plans"] =
      "Planos",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never. ~ marks a value taken from Classic."] =
      "Cada etapa diz o que aprender com o instrutor, o que criar primeiro (parafusos, barras...) e quantos. Clique em uma linha para abrir a receita, Shift+clique para linká-la. Cores: laranja sempre dá um ponto, amarelo geralmente, verde raramente, cinza nunca. ~ marca um valor tirado do Classic.",
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
    ["Left: the group overview, the group management, then every character you share or receive."] =
      "À esquerda: a visão do grupo, o gerenciamento do grupo e cada personagem que você compartilha ou recebe.",
    ["Plan and Can craft"] =
      "Plano e Pode criar",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Escolha um personagem: Plano mostra como subir cada profissão passo a passo; Pode criar mostra o que ele pode fazer para os outros.",
    ["While you play"] =
      "Enquanto você joga",
    ["Item tooltips show who needs a material. A step panel opens next to your profession window."] =
      "As dicas dos itens mostram quem precisa de um material. Um painel de etapa abre ao lado da sua janela de profissão.",
    ["Sharing is off until you check a box"] =
      "O compartilhamento fica desativado até você marcar uma caixa",
    ["Nothing is shared yet. Here, in Manage group, check the box next to each character you want to share under Your characters (on the left of this card). Unchecked characters never leave your computer. Then add your friends below, or accept guildmates who appear there. The ? button explains the rest."] =
      "Nada é compartilhado ainda. Aqui, em Gerenciar grupo, marque a caixa ao lado de cada personagem que quer compartilhar em Seus personagens (à esquerda deste cartão). Personagens desmarcados nunca saem do seu computador. Depois adicione seus amigos abaixo, ou aceite colegas de guilda que aparecerem lá. O botão ? explica o resto.",
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
    ["Sources taken from another game version, unconfirmed on Forever."] =
      "Fontes tiradas de outra versão do jogo, não confirmadas no Forever.",
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
    ["Learn it from a trainer of this profession (in Classic: skill %d and character level %d; unconfirmed on Forever)."] =
      "Aprenda com um instrutor desta profissão (no Classic: perícia %d e nível de personagem %d; não confirmado no Forever).",
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
    ["Click: group needs"] =
      "Clique: necessidades do grupo",
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
}
