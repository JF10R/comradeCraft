-- ruRU translations. Keys: the English text (see Locale.lua); loaded only on a ruRU client.
local _, ns = ...
local loc = GetLocale and GetLocale()
if loc ~= "ruRU" then return end
ns.Translations = ns.Translations or {}
ns.Translations[loc] = {
    -- Core
    ["commands: /comrade (window) | share [off] | list [off] | directory [text] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"] =
      "команды: /comrade (окно) | share [off] | list [off] | directory [текст] | add ИМЯ | remove ИМЯ | peers | sync | guildping [off] | shop [профессия] | tracker [reset] | mail ИМЯ | scan | needs | stats | api | audit | log clear",
    ["log cleared"] = "журнал очищен",
    ["%d lines in the log (written to disk on /reload or logout)"] =
      "строк в журнале: %d (записываются на диск при /reload или выходе)",
    -- Scan
    ["scan ok: %d distinct items in bags"] = "скан завершён: разных предметов в сумках: %d",
    ["DevTools_Dump missing; see WTF\\...\\SavedVariables\\ComradeCraft.lua after /reload"] =
      "DevTools_Dump отсутствует; смотри WTF\\...\\SavedVariables\\ComradeCraft.lua после /reload",
    ["audit: C_TradeSkillUI.GetAllRecipeIDs missing on this client"] =
      "аудит: C_TradeSkillUI.GetAllRecipeIDs отсутствует в этом клиенте",
    ["audit: open a profession window first"] = "аудит: сначала открой окно профессии",
    ["  %s (%d): game=%s table=%s [%d/%d]"] = "  %s (%d): игра=%s таблица=%s [%d/%d]",
    ["audit rank %d: %d ok, %d mismatches, %d missing from the table"] =
      "аудит, ранг %d: %d ок, %d расхождений, %d нет в таблице",
    ["LibProfessionDB: %d ok, %d mismatches"] = "LibProfessionDB: %d ок, %d расхождений",
    ["maxTrivialLevel == grey: %d yes, %d no"] = "maxTrivialLevel == серый: %d да, %d нет",
    ["yes"] = "да",
    ["no"] = "нет",
    -- SkillLog
    ["%d crafts recorded (calibration from %d per color)"] =
      "записано созданий: %d (калибровка от %d на цвет)",
    ["orange"] = "оранжевый",
    ["yellow"] = "жёлтый",
    ["green"] = "зелёный",
    ["grey"] = "серый",
    ["  %s: %d crafts, %d points, Classic formula %.1f%s"] =
      "  %s: созданий %d, очков %d, формула Classic %.1f%s",
    [" -> factor %.2f applied"] = " -> применён коэффициент %.2f",
    ["  game color known on %d crafts: our table %d right, LibProfessionDB %d right"] =
      "  цвет в игре известен для %d созданий: наша таблица верна %d, LibProfessionDB верна %d",
    -- Tooltip / needs text
    ["needs %d"] = "нужно: %d",
    ["Group total"] = "Всего в группе",
    ["Spare in the group"] = "Лишнее в группе",
    ["You can give"] = "Можешь отдать",
    ["Spare items in your bags that others need. With a mailbox open, click one to prepare the mail."] =
      "Лишние предметы в твоих сумках, которые нужны другим. У открытого почтового ящика нажми на предмет, чтобы подготовить письмо.",
    ["Mail full (%d attachments): send it, then click again for the rest."] =
      "Письмо заполнено (вложений: %d): отправь его и нажми ещё раз для остального.",
    ["Open a mailbox first."] = "Сначала открой почтовый ящик.",
    ["Nothing to give to %s."] = "Нечего отдать игроку %s.",
    ["Attach what they need"] = "Вложить нужное",
    ["Type the name of a group member."] = "Введи имя участника группы.",
    ["You need"] = "Тебе нужно",
    ["Disenchant or keep?"] = "Распылить или оставить?",
    ["Green and better items in your bags. Yields are estimates until your disenchants are logged."] =
      "Предметы зелёного качества и выше в твоих сумках. Выход приблизительный, пока не записаны твои распыления.",
    ["Keep: enchanting target (%s)"] = "Оставить: цель для наложения чар (%s)",
    ["Keep: gear for %s"] = "Оставить: экипировка для %s",
    ["Sell: AH %s vs disenchant %s"] = "Продать: аукцион %s против распыления %s",
    ["Disenchant: %s"] = "Распылить: %s",
    ["the group needs these"] = "нужно группе",
    ["give to %s"] = "отдать: %s",
    ["group: %d"] = "группа: %d",
    ["now"] = "сейчас",
    ["soon"] = "скоро",
    ["later"] = "позже",
    ["trainer"] = "учитель",
    ["vendor"] = "торговец",
    ["quest"] = "задание",
    ["drop"] = "добыча",
    ["container"] = "контейнер",
    ["Gathering profession: levels by gathering, not crafting."] =
      "Сбор ресурсов: навык растёт от сбора, а не от создания.",
    ["Open this profession's window once so your recipes can be read."] =
      "Открой окно этой профессии один раз, чтобы прочитать твои рецепты.",
    ["No data."] = "Нет данных.",
    ["Learn %s at the trainer (skill %s, %s)"] = "Изучи %s у учителя (навык %s, %s)",
    ["cost unknown until you visit the trainer"] = "цена неизвестна, пока не зайдёшь к учителю",
    ["Craft %d %s (%s)"] = "Создать %d %s (%s)",
    ["Craft %dx %s (%s)"] = "Создать %dx %s (%s)",
    ["%d %s (vendor)"] = "%d %s (торговец)",
    ["Estimated cost: %s (%s prices)."] = "Примерная цена: %s (цены: %s).",
    ["Estimated cost: at least %s (%s prices, some items have no price)."] =
      "Примерная цена: не менее %s (цены: %s, у некоторых предметов нет цены).",
    [" + %d from stock"] = " + %d из запасов",
    ["%d %s from stock"] = "%d %s из запасов",
    ["With only your current recipes, you would be stuck at %d."] =
      "С текущими рецептами ты застрянешь на %d.",
    ["Uses what you already have: %s."] = "Использует то, что уже есть: %s.",
    ["Buy from a vendor: %s."] = "Купить у торговца: %s.",
    ["Stuck at %d: all your known recipes are grey (no more points)."] =
      "Застрял на %d: все твои рецепты серые (очков больше нет).",
    ["Stuck at %d: your known recipes barely give points anymore (%d%% chance per craft at best, %d%% needed)."] =
      "Застрял на %d: твои рецепты почти не дают очков (в лучшем случае шанс за создание: %d%%, нужно: %d%%).",
    [" To learn: %s."] = " Изучить: %s.",
    [" No recipe to learn found within the next 25 points."] =
      " Нет рецептов для изучения в пределах следующих 25 очков.",
    ["  missing %s x%d"] = "  не хватает: %s x%d",
    -- UI
    ["just now"] = "только что",
    ["%d min ago"] = "%d мин назад",
    ["%d h ago"] = "%d ч назад",
    ["What to craft:"] = "Что создать:",
    ["Owned: %d / %d"] = "Есть: %d / %d",
    ["%d profession"] = "профессий: %d",
    ["%d professions"] = "профессий: %d",
    ["%d member"] = "участников: %d",
    ["%d members"] = "участников: %d",
    ["Group"] = "Группа",
    ["Plan"] = "План",
    ["Can craft"] = "Может создать",
    ["Lvl %d"] = "Ур. %d",
    ["updated %s"] = "обновлено %s",
    ["Skill levels and the materials the group still needs. Type to find who can craft something."] =
      "Уровни навыков и материалы, которых группе ещё не хватает. Введи название, чтобы найти, кто может это создать.",
    ["Skill levels"] = "Уровни навыков",
    ["Most wanted materials"] = "Самые нужные материалы",
    ["Nothing missing yet."] = "Пока всего хватает.",
    ["Who can craft \"%s\""] = "Кто может создать «%s»",
    ["No recipe matches."] = "Нет подходящих рецептов.",
    ["No profession data. Open your profession windows."] =
      "Нет данных о профессиях. Открой окна своих профессий.",
    ["%d recipe"] = "рецептов: %d",
    ["%d recipes"] = "рецептов: %d",
    ["gear for %s"] = "экипировка для %s",
    ["upgrade for %s (+%d)"] = "улучшение для %s (+%d)",
    ["Enchant"] = "Чары",
    ["Consumable"] = "Расходуемое",
    ["Bag"] = "Сумка",
    ["Weapon"] = "Оружие",
    ["Armor"] = "Доспехи",
    ["Reagent"] = "Реагент",
    ["Other"] = "Прочее",
    ["Sync: %d players in the group, %d suggested. skill ~N: value taken from Classic, unconfirmed."] =
      "Синхронизация: игроков в группе: %d, предложено: %d. навык ~N: значение из Classic, не подтверждено.",
    ["via %s"] = "через %s",
    ["Manage group"] = "Управление группой",
    ["Choose what you share, and with whom."] = "Выбери, чем делиться и с кем.",
    ["%d player"] = "игроков: %d",
    ["%d players"] = "игроков: %d",
    ["%d request"] = "запросов: %d",
    ["%d requests"] = "запросов: %d",
    ["Your characters"] = "Твои персонажи",
    ["Only checked characters are shared, and only with the players in your group."] =
      "Делятся только отмеченные персонажи и только с игроками твоей группы.",
    ["Players in your group"] = "Игроки твоей группы",
    ["They receive your shared characters and you see theirs."] =
      "Они получают твоих персонажей, а ты видишь их.",
    ["Nobody yet."] = "Пока никого.",
    ["seen %s"] = "виден %s",
    ["Remove"] = "Убрать",
    ["Requests and suggestions"] = "Запросы и предложения",
    ["Players with ComradeCraft in your guild, or who added you. Add them to share both ways."] =
      "Игроки твоей гильдии с ComradeCraft или те, кто добавил тебя. Добавь их, чтобы делиться в обе стороны.",
    ["Add"] = "Добавить",
    ["Add a player by name"] = "Добавить игрока по имени",
    ["For friends outside your guild. They must add you back."] =
      "Для друзей вне гильдии. Они должны добавить тебя в ответ.",
    ["Options"] = "Настройки",
    ["Send a presence signal to the guild at login (no character data)."] =
      "Отправлять гильдии сигнал присутствия при входе (без данных персонажа).",
    ["All"] = "Все",
    ["Hide gathering"] = "Скрыть сбор",
    ["No profession matches the filter."] = "Нет профессий по этому фильтру.",
    ["%d character"] = "персонажей: %d",
    ["%d characters"] = "персонажей: %d",
    ["Remove from group"] = "Убрать из группы",
    -- Sync
    ["sync: sent to the players in your group"] = "синхронизация: отправлено игрокам твоей группы",
    ["%s is shared with your group"] = "%s доступен твоей группе",
    ["%s is no longer shared"] = "%s больше не доступен группе",
    ["guild presence signal: on"] = "сигнал присутствия гильдии: вкл.",
    ["guild presence signal: off"] = "сигнал присутствия гильдии: выкл.",
    ["Share this character with the group"] = "Поделиться этим персонажем с группой",
    ["not shared"] = "не доступен",
    ["  %s: %d characters, %s"] = "  %s: персонажей: %d, %s",
    ["in the group"] = "в группе",
    ["wants to join"] = "хочет вступить",
    ["suggested"] = "предложен",
    ["no peer seen yet (they need ComradeCraft)"] = "пока никого не видно (нужен ComradeCraft)",
    ["%s added to the group"] = "%s добавлен в группу",
    ["%s contacted; added as soon as they answer"] = "%s уведомлён; будет добавлен после ответа",
    ["%s removed from the group"] = "%s убран из группы",
    -- Shopping, Tracker
    ["Could not create the Auctionator list (see /comrade log)."] =
      "Не удалось создать список Auctionator (см. /comrade log).",
    ["Nothing to buy for %s."] =
      "Нечего покупать для %s.",
    ["Auctionator list \"ComradeCraft: %s\" created: %d items. Open the Shopping tab at the auction house."] =
      "Список Auctionator «ComradeCraft: %s» создан: предметов: %d. Открой вкладку Shopping на аукционе.",
    ["%d not cached yet; try again in a moment."] =
      "%d ещё не в кеше; повтори через минуту.",
    ["Nothing to buy."] =
      "Нечего покупать.",
    ["Step panel hidden. /comrade tracker shows it again."] =
      "Панель шага скрыта. /comrade tracker покажет её снова.",
    ["TSM shopping (Ctrl+C to copy)"] = "Покупки TSM (Ctrl+C для копирования)",
    ["Search: paste in the search box of TSM's Shopping tab."] =
      "Поиск: вставь в строку поиска на вкладке Shopping в TSM.",
    ["Group: TSM, Groups, Import. Quantities are in the search above (recomputed on each click)."] =
      "Группа: TSM, Groups, Import. Количества указаны в поиске выше (пересчитываются при каждом нажатии).",
    ["TSM group \"%s\": everything bought, delete it in TSM (Groups, right-click)."] =
      "Группа TSM «%s»: всё куплено, удали её в TSM (Groups, правый клик).",
    ["TSM group \"%s\": replaced by a newer one, delete it in TSM (Groups, right-click)."] =
      "Группа TSM «%s»: заменена новой, удали её в TSM (Groups, правый клик).",
    ["Send now"] = "Отправить",
    ["Show the step panel next to the profession window."] =
      "Показывать панель шага рядом с окном профессии.",
    ["Re-dock"] = "Прикрепить",
    ["Measured skill-up chances"] = "Измеренные шансы повышения навыка",
    ["Crafts logged by you and your group correct the Classic formula once a color has enough of them."] =
      "Создания, записанные тобой и твоей группой, исправляют формулу Classic, когда для цвета набирается достаточно данных.",
    ["The window"] =
      "Окно",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "Слева: группа, затем каждый персонаж. План = как прокачать профессию; Может создать = что персонаж может сделать для группы. Метки фильтруют по профессии.",
    ["Plans"] =
      "Планы",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never. ~ marks a value taken from Classic."] =
      "Каждый шаг говорит, что изучить у учителя, что создать сначала (болты, слитки...) и сколько. Клик по строке открывает рецепт, Shift+клик вставляет ссылку. Цвета: оранжевый всегда даёт очко, жёлтый обычно, зелёный редко, серый никогда. ~ отмечает значение из Classic.",
    ["Tooltips"] =
      "Подсказки",
    ["On any material: who in the group needs it, how many, and how soon (now, soon, later). Spare stock in the group is shown too."] =
      "У любого материала: кому в группе он нужен, сколько и когда (сейчас, скоро, позже). Лишние запасы группы тоже показаны.",
    ["Step panel"] =
      "Панель шага",
    ["Next to your profession window: the current step, the chance per craft, how many crafts your bags allow, and what comes next."] =
      "Рядом с окном профессии: текущий шаг, шанс за создание, сколько созданий позволяют твои сумки и что дальше.",
    ["Giving and mail"] =
      "Передача и почта",
    ["You can give lists what you hold that others need. At a mailbox, the button beside the send frame attaches it. Nothing is ever sent for you."] =
      "Список «Можешь отдать» показывает то, что есть у тебя и нужно другим. У почтового ящика кнопка рядом с окном отправки вкладывает это в письмо. За тебя ничего не отправляется.",
    ["Disenchant or keep"] =
      "Распылить или оставить",
    ["Your green items: keep one per slot your enchanting plan needs, keep upgrades for group members, sell what is worth more than its mats, disenchant the rest."] =
      "Твои зелёные предметы: оставь по одному на ячейку для плана чар, оставь улучшения для группы, продай то, что стоит дороже материалов, остальное распыли.",
    ["Shopping"] =
      "Покупки",
    ["The Shopping list button makes an Auctionator list, or a TSM search and group to paste. TSM groups that are done are pointed out."] =
      "Кнопка «Список покупок» создаёт список Auctionator или поиск и группу TSM для вставки. Завершённые группы TSM помечаются.",
    ["Sharing"] =
      "Обмен данными",
    ["Nothing is shared until you check a character in Manage group, and only with players you added who added you back."] =
      "Ничего не передаётся, пока ты не отметишь персонажа в «Управлении группой», и только игрокам, которых ты добавил и которые добавили тебя.",
    ["Better with"] =
      "Лучше с",
    ["Replay the tour"] =
      "Пройти обзор снова",
    ["Welcome to ComradeCraft"] =
      "Добро пожаловать в ComradeCraft",
    ["It answers one question: what should I do with what I have, for the group? 30 seconds to see the main parts."] =
      "Он отвечает на один вопрос: что мне сделать с тем, что у меня есть, для группы? 30 секунд, чтобы увидеть главное.",
    ["Your group"] =
      "Твоя группа",
    ["Left: the group overview, the group management, then every character you share or receive."] =
      "Слева: обзор группы, управление группой, затем все персонажи, которыми ты делишься или которых получаешь.",
    ["Plan and Can craft"] =
      "План и Может создать",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Выбери персонажа: План показывает, как шаг за шагом прокачать каждую профессию; Может создать показывает, что он может сделать для других.",
    ["While you play"] =
      "Пока ты играешь",
    ["Item tooltips show who needs a material. A step panel opens next to your profession window."] =
      "Подсказки предметов показывают, кому нужен материал. Рядом с окном профессии открывается панель шага.",
    ["Sharing is off until you check a box"] = "Обмен выключен, пока ты не поставишь галочку",
    ["Nothing is shared yet. Here, in Manage group, check the box next to each character you want to share under Your characters (on the left of this card). Unchecked characters never leave your computer. Then add your friends below, or accept guildmates who appear there. The ? button explains the rest."] =
      "Пока ничего не передаётся. Здесь, в «Управлении группой», поставь галочку у каждого персонажа, которым хочешь поделиться, в разделе «Твои персонажи» (слева на этой карточке). Персонажи без галочки никогда не покидают твой компьютер. Затем добавь друзей ниже или прими согильдийцев, которые там появятся. Остальное объясняет кнопка ?.",
    ["Do not show again"] =
      "Больше не показывать",
    ["Skip"] =
      "Пропустить",
    ["Done"] =
      "Готово",
    ["Next"] =
      "Далее",
    ["Help"] =
      "Справка",
    ["How ComradeCraft works, in short."] =
      "Как работает ComradeCraft, кратко.",
    ["Cheapest"] =
      "Дешевле",
    ["Profitable"] =
      "Выгоднее",
    ["Route:"] =
      "Маршрут:",
    ["Picks recipes whose products sell back well. More crafts, so more mats: tooltips, the give list, mail and shopping all follow this route."] =
      "Выбирает рецепты, продукты которых хорошо продаются. Больше созданий, значит больше материалов: подсказки, список передачи, почта и покупки следуют этому маршруту.",
    ["Chosen by its owner."] = "Выбрано владельцем.",
    ["Spends the least on mats."] =
      "Тратит на материалы меньше всего.",
    ["Where to get it: unknown."] =
      "Где получить: неизвестно.",
    ["Where to get it:"] =
      "Где получить:",
    ["and %d more"] =
      "и ещё %d",
    ["Sources taken from another game version, unconfirmed on Forever."] =
      "Источники взяты из другой версии игры, на Forever не подтверждены.",
    ["Install Questie for locations; TomTom for waypoints."] =
      "Установи Questie для координат и TomTom для меток.",
    ["Click: waypoint to the nearest one."] =
      "Клик: метка к ближайшему.",
    ["No known location for %s."] =
      "Нет известного места для %s.",
    ["%s: %s. Install TomTom for a waypoint."] =
      "%s: %s. Установи TomTom для метки.",
    ["Waypoint: %s"] =
      "Метка: %s",
    ["Mats per craft:"] = "Материалы на создание:",
    ["+%d more"] = "+ещё %d",
    ["Recipe and mats"] = "Рецепт и материалы",
    ["For the group"] = "Для группы",
    ["Type"] = "Тип",
    ["Mats cost"] = "Цена материалов",
    ["At the trainer - skill %s - %s"] =
      "У учителя - навык %s - %s",
    ["already in your bags"] =
      "уже в твоих сумках",
    ["Cost by milestone (%s prices)"] =
      "Цена по этапам (цены: %s)",
    ["Cost by milestone (merchant prices; TSM or Auctionator give AH prices)"] =
      "Цена по этапам (цены торговцев; TSM или Auctionator дают цены аукциона)",
    ["Skill %d to %d"] =
      "Навык с %d до %d",
    ["Learn %s"] =
      "Изучить %s",
    ["Skill"] =
      "Навык",
    ["Route"] =
      "Маршрут",
    ["Mats"] =
      "Матер.",
    ["Sold back"] =
      "Выручка",
    ["Net cost"] =
      "Итого",
    ["nothing"] =
      "ничего",
    ["unknown"] =
      "неизвестно",
    ["Sold to a merchant"] =
      "Продано торговцу",
    ["Disenchanted"] =
      "Распылено",
    ["At the auction house (-5%, deposit risk)"] =
      "На аукционе (-5%, риск залога)",
    ["Best way per item"] =
      "Лучший способ для предмета",
    ["Net cost = mats minus the best resale of each item. A green + is a profit. Hover a line for the details."] =
      "Итого = материалы минус лучшая перепродажа каждого предмета. Зелёный + означает прибыль. Наведи курсор на строку для подробностей.",
    ["Next: %s"] = "Далее: %s",
    ["Click to expand."] = "Нажми, чтобы развернуть.",
    ["Could not start the craft (see /comrade log)."] =
      "Не удалось начать создание (см. /comrade log).",
    ["Queue:"] =
      "Очередь:",
    ["up to skill %d (click: this step only)"] =
      "до навыка %d (клик: только этот шаг)",
    ["this step (click: up to the milestone)"] =
      "этот шаг (клик: до этапа)",
    ["by hand (needs a target)"] =
      "вручную (нужна цель)",
    ["ready"] =
      "готово",
    ["%d ready"] =
      "готово: %d",
    ["Craft next: %dx %s"] =
      "Создать далее: %dx %s",
    ["Learn %s first"] =
      "Сначала изучи %s",
    ["Missing mats for the queue"] =
      "Не хватает материалов для очереди",
    ["Nothing to craft"] =
      "Нечего создавать",
    ["%s asks %s to craft %dx %s."] =
      "%s просит %s создать %dx %s.",
    ["Request %dx %s: %s."] =
      "Запрос %dx %s: %s.",
    ["Request sent to %s. It is delivered as soon as you are both online."] =
      "Запрос отправлен игроку %s. Он будет доставлен, как только вы оба окажетесь в сети.",
    ["Quantity"] =
      "Количество",
    ["Note (optional)"] =
      "Заметка (необязательно)",
    ["Send request"] =
      "Отправить запрос",
    ["Ask %s to craft %s"] =
      "Попросить %s создать %s",
    ["Craft requests"] =
      "Запросы на создание",
    ["%d to answer"] =
      "ответить: %d",
    ["none open"] =
      "нет открытых",
    ["Ask a group member to craft something, or answer what they asked you."] =
      "Попроси участника группы что-нибудь создать или ответь на его просьбу.",
    ["Click: ask %s to craft it."] =
      "Клик: попросить %s создать это.",
    ["%s for %s"] =
      "%s для %s",
    ["asked to %s"] =
      "просьба к %s",
    ["waiting to reach the other player"] =
      "ждёт доставки другому игроку",
    ["Mats: %s"] =
      "Матер.: %s",
    ["your bags allow %d"] =
      "твои сумки позволяют: %d",
    ["Accept"] =
      "Принять",
    ["Decline"] =
      "Отклонить",
    ["Cancel request"] =
      "Отменить",
    ["For your characters"] =
      "Для твоих персонажей",
    ["Your requests"] =
      "Твои запросы",
    ["Accept, craft, then mark it done; the mail helper attaches the item when you write to them."] =
      "Прими, создай, затем отметь выполненным; помощник почты вложит предмет, когда ты будешь писать письмо.",
    ["Click a recipe in a group member's Can craft tab to ask for it. Delivered the next time you are both online."] =
      "Нажми на рецепт на вкладке «Может создать» участника группы, чтобы попросить его. Доставляется, когда вы оба в следующий раз будете в сети.",
    ["pending"] =
      "ожидает",
    ["accepted"] =
      "принят",
    ["declined"] =
      "отклонён",
    ["done"] =
      "выполнен",
    ["cancelled"] =
      "отменён",
    ["(by mail)"] =
      "(по почте)",
    ["Request mail ready: check it and click Send."] =
      "Письмо с запросом готово: проверь его и нажми «Отправить».",
    ["By mail"] =
      "По почте",
    ["Craft requests by mail too: for players who are never online at the same time (you send the mail yourself, 30c postage)."] =
      "Запросы на создание и по почте: для игроков, которые никогда не бывают в сети одновременно (письмо ты отправляешь сам, пересылка 30 меди).",
    ["other profession"] = "другая профессия",
    ["Routes"] =
      "Маршруты",
    ["Each character picks Cheapest (least spent on mats) or Profitable (products sold back). The milestone table compares both: mats, what the products bring back (merchant, disenchant or AH) and the net cost."] =
      "Каждый персонаж выбирает «Дешевле» (меньше трат на материалы) или «Выгоднее» (продажа продуктов). Таблица этапов сравнивает оба: материалы, выручку с продуктов (торговец, распыление или аукцион) и итог.",
    ["Learning recipes"] =
      "Изучение рецептов",
    ["Hover a Learn line for its trainers, vendors and drops; click it for a TomTom waypoint (with Questie installed for positions)."] =
      "Наведи курсор на строку «Изучить», чтобы увидеть учителей, торговцев и добычу; клик ставит метку TomTom (координаты даёт Questie).",
    ["Craft queue"] =
      "Очередь создания",
    ["In the step panel: the crafts of this step or of the whole milestone, what your bags allow, and Craft next (one batch per click, the game needs a click per craft)."] =
      "В панели шага: создания этого шага или всего этапа, что позволяют твои сумки, и «Создать далее» (одна партия за клик, игре нужен клик на каждое создание).",
    ["Click a recipe in a group member's Can craft tab to ask for it. Answer what you are asked in Craft requests. Requests reach the other player the next time you are both online (or by mail, if turned on in Manage group)."] =
      "Нажми на рецепт на вкладке «Может создать» участника группы, чтобы попросить его. Отвечай на просьбы в «Запросах на создание». Запросы доходят до другого игрока, когда вы оба в следующий раз в сети (или по почте, если включено в «Управлении группой»).",
    ["%s: mats ready"] =
      "%s: материалы готовы",
    ["Your bags hold everything for %dx %s."] =
      "В твоих сумках есть всё для %dx %s.",
    ["Cooldown ready: %s"] =
      "Восстановление завершено: %s",
    ["on %s"] =
      "у %s",
    ["+%d with Pawn"] =
      "+%d по Pawn",
    ["+%d item levels"] =
      "+%d ур. предмета",
    ["%s can craft an upgrade for you"] =
      "%s может создать для тебя улучшение",
    ["Ask for it"] =
      "Попросить",
    ["Not interested"] =
      "Не интересно",
    ["New craft request"] =
      "Новый запрос на создание",
    ["Open"] =
      "Открыть",
    ["Alerts"] =
      "Оповещения",
    ["A chat line and a short notice at the top of the screen."] =
      "Строка в чате и короткое уведомление вверху экрана.",
    ["Your bags hold the mats for your next craft."] =
      "В твоих сумках есть материалы для следующего создания.",
    ["A profession cooldown is ready on one of your characters."] =
      "У одного из твоих персонажей восстановилась способность профессии.",
    ["A craft request arrives or changes."] =
      "Пришёл или изменился запрос на создание.",
    ["A group member can craft an upgrade for you (off by default)."] =
      "Участник группы может создать для тебя улучшение (по умолчанию выключено).",
    ["visited"] = "посещён",
    ["Next rank: %s (%d to %d)"] =
      "Следующий ранг: %s (%d-%d)",
    ["Journeyman"] =
      "Подмастерье",
    ["Expert"] =
      "Эксперт",
    ["Artisan"] =
      "Умелец",
    ["Master"] =
      "Мастер",
    ["skill %d"] =
      "навык %d",
    ["level %d"] =
      "уровень %d",
    ["sold by %s"] =
      "продаёт %s",
    ["or at the AH (~%s)"] =
      "или на аукционе (~%s)",
    ["or at the AH"] =
      "или на аукционе",
    ["Learn it from a trainer of this profession (in Classic: skill %d and character level %d; unconfirmed on Forever)."] =
      "Изучи у учителя этой профессии (в Classic: навык %d и уровень персонажа %d; на Forever не подтверждено).",
    ["At the cap (%d)."] =
      "Максимум (%d).",
    ["Looking for the quest in Questie..."] =
      "Поиск задания в Questie...",
    ["This rank comes from a quest (install Questie to find it)."] =
      "Этот ранг даётся за задание (установи Questie, чтобы найти его).",
    ["starts at %s"] =
      "начинается у %s",
    ["Quest: %s"] =
      "Задание: %s",
    ["Quests that need %d in this skill; the rank quest is among them."] =
      "Задания, требующие %d в этом навыке; задание ранга среди них.",
    ["Click: waypoint to the quest giver."] =
      "Клик: метка к квестодателю.",
    ["Shopping list"] =
      "Список покупок",
    ["Full plan"] =
      "Полный план",
    ["Reading the recipes of this profession..."] =
      "Чтение рецептов этой профессии...",
    ["%d%% chance per craft (%s)"] =
      "шанс за создание: %d%% (%s)",
    ["Step panel: off"] =
      "Панель шага: выкл.",
    ["Step panel: on (shown with the profession window)"] =
      "Панель шага: вкл. (показывается с окном профессии)",
    ["Click: group needs"] = "Клик: нужды группы",
    ["Keep for your group"] =
      "Оставь для группы",
    ["%s: %d for %s"] =
      "%s: %d для %s",
    ["and %d more"] =
      "и ещё %d",
    ["You sold %s"] =
      "Ты продал: %s",
    ["Buy back"] =
      "Выкупить",
    ["you"] =
      "тебя",
    ["At a merchant or the auction house: items in your bags that your group needs."] =
      "У торговца или на аукционе: предметы в сумках, нужные твоей группе.",
    ["Next rank"] =
      "Следующий ранг",
    ["At the skill cap: the Expert book (vendor or AH), the Artisan quest found in Questie (click for a waypoint to its giver), or the trainer."] =
      "На пределе навыка: книга эксперта (торговец или аукцион), задание мастера из Questie (щелчок: точка к тому, кто его выдаёт) или учитель.",
    ["Mats ready, profession cooldowns ready on any of your characters, craft requests, items your group needs when you open a merchant or the AH (with Buy back after a sale), and opt-in upgrades. Each one can be turned off in Manage group."] =
      "Материалы готовы, восстановление профессий на любом твоём персонаже, запросы на создание, предметы, нужные группе, когда открываешь торговца или аукцион (с выкупом после продажи), и улучшения по желанию. Каждое отключается в управлении группой.",
    ["TSM or Auctionator (prices), Questie (positions), TomTom (waypoints), Pawn (upgrades for each class and spec). All optional."] =
      "TSM или Auctionator (цены), Questie (координаты), TomTom (точки маршрута), Pawn (улучшения для каждого класса и специализации). Всё по желанию.",
    -- Group plan
    ["Spare"] =
      "Лишнее",
    ["Group plan"] =
      "План группы",
    ["What the group still needs, what it already holds, and who farms what."] =
      "Чего группе ещё не хватает, что уже есть и кто что добывает.",
    ["Objective:"] =
      "Цель:",
    ["Lowest group cost"] =
      "Мин. затраты группы",
    ["Market value"] =
      "Рыночная цена",
    ["Least gold spent by the group: stock already held in the group counts as free."] =
      "Меньше всего золота на группу: запасы, которые уже есть в группе, считаются бесплатными.",
    ["Every material at its market value, as if each character were alone."] =
      "Каждый материал по рыночной цене, как будто каждый персонаж один.",
    ["Material"] =
      "Материал",
    ["Needed"] =
      "Нужно",
    ["To get"] =
      "Добыть",
    ["Est. cost"] =
      "Цена (оц.)",
    ["Farming"] =
      "Добыча",
    ["Farmed by %s"] =
      "Добывает %s",
    ["Drop"] =
      "Отказаться",
    ["I'll farm it"] =
      "Добуду я",
    ["Estimated cost for the group: %s"] =
      "Оценка стоимости для группы: %s",
    ["Estimated cost for the group: at least %s (some items have no price)."] =
      "Оценка стоимости для группы: не меньше %s (у некоторых предметов нет цены).",
    ["Estimated cost for the group: unknown (TSM or Auctionator give AH prices)."] =
      "Оценка стоимости для группы: неизвестна (цены аукциона дают TSM или Auctionator).",
    ["%d %s needed for %s. Do you want to farm them?"] =
      "%d %s нужно для %s. Хочешь добыть их?",
    ["Farming done: %s"] =
      "Добыча завершена: %s",
    ["Give them from You can give in the Group view, or by mail."] =
      "Отдай их через Можешь отдать в окне Группа или почтой.",
    ["Show the farming tracker (your farming assignments from the Group plan)."] =
      "Показывать трекер добычи (твои задания из Плана группы).",
    ["Plans count stock already held in the group as free (or every mat at market value: Manage group > Options). The Group plan view lists what the group still needs and its cost; take a material with I'll farm it and a small tracker follows your progress."] =
      "Планы считают бесплатными запасы, которые уже есть в группе (или каждый материал по рыночной цене: Управление группой > Настройки). Окно План группы показывает, чего группе ещё не хватает и сколько это стоит; возьми материал кнопкой Добуду я, и небольшой трекер покажет прогресс.",
    ["Guild directory"] =
      "Справочник гильдии",
    ["%d crafter"] =
      "%d ремесленник",
    ["%d crafters"] =
      "%d ремесленников",
    ["Right box: list the character in the guild directory (professions and recipes only, sent to your guild)."] =
      "Правый флажок: внести персонажа в справочник гильдии (только профессии и рецепты, отправляются твоей гильдии).",
    ["List in guild directory"] =
      "Внести в справочник гильдии",
    ["Opt-in, per character: List in guild directory in Manage group (or /comrade list) sends its professions and recipes to guildmates who use ComradeCraft. Search who can craft an item, whisper them, or ask for the craft if they are in your group. Item tooltips name up to 3 guild crafters."] =
      "По желанию, для каждого персонажа: флажок Внести в справочник гильдии в Управлении группой (или /comrade list) отправляет его профессии и рецепты согильдийцам с ComradeCraft. Ищи, кто может создать предмет, шепни ему или попроси создать, если он в твоей группе. Подсказки предметов называют до 3 ремесленников гильдии.",
    ["Whisper"] =
      "Шепнуть",
    ["Nobody is listed yet. The directory is opt-in: each player lists their own characters in Manage group (List in guild directory) or with /comrade list."] =
      "Пока никто не внесён. Справочник добровольный: каждый игрок сам вносит своих персонажей в Управлении группой (Внести в справочник гильдии) или командой /comrade list.",
    ["Type a product or recipe name in the search box."] =
      "Введи название предмета или рецепта в поле поиска.",
    ["No crafter found."] =
      "Ремесленник не найден.",
    ["... and %d more"] =
      "... и ещё %d",
    ["Who in your guild can craft what. Each player lists their own characters (opt-in)."] =
      "Кто в твоей гильдии что умеет создавать. Каждый игрок сам вносит своих персонажей (по желанию).",
    ["Guild crafters: %s"] =
      "Ремесленники гильдии: %s",
    ["%s is listed in the guild directory"] =
      "%s внесён в справочник гильдии",
    ["%s is no longer listed in the guild directory"] =
      "%s больше не внесён в справочник гильдии",
    ["You are not in a guild: the entry is sent once you are."] =
      "Ты не в гильдии: запись отправится, когда вступишь в гильдию.",
    ["directory: %d characters listed. /comrade directory TEXT searches them."] =
      "справочник: внесено персонажей: %d. /comrade directory ТЕКСТ ищет среди них.",
    ["directory: no crafter for %s"] =
      "справочник: нет ремесленника для %s",
    -- UI polish, bags, mail & friends
    ["%d item"] = "%d предмет",
    ["%d items"] = "%d предметов",
    ["Add %s"] = "Добавить %s",
    ["Add target"] = "Добавить цель",
    ["Cancel"] = "Отмена",
    ["Characters"] = "Персонажи",
    ["Click a member to highlight their items."] = "Нажми на участника, чтобы подсветить нужные ему предметы.",
    ["Click to select recipient and highlight needed items in your bags."] =
      "Нажми, чтобы выбрать получателя и подсветить нужные ему предметы в сумках.",
    ["Collapse all"] = "Свернуть всё",
    ["ComradeCraft: Add to group"] = "ComradeCraft: Добавить в группу",
    ["Expand all"] = "Развернуть всё",
    ["Filter recipes..."] = "Фильтр рецептов...",
    ["Find who can craft..."] = "Кто может создать...",
    ["For %s"] = "Для %s",
    ["Friend"] = "Друг",
    ["Guild"] = "Гильдия",
    ["Highlight items for your group in your bags (and focus a recipient's items when mailing)."] =
      "Подсвечивать в сумках предметы для группы (и выделять нужные получателю на почте).",
    ["Highlighted in your bags"] = "Подсвечено в сумках",
    ["Nothing to send from your bags."] = "Нечего отправить из сумок.",
    ["Online in your party, friends or guild:"] = "В сети в твоей группе, друзьях или гильдии:",
    ["Party"] = "Группа",
    ["Ready to send from your bags"] = "Готово к отправке из сумок",
    ["Retry"] = "Повторить",
    ["Search guild crafters..."] = "Поиск ремесленников...",
    ["Send x%d to %s"] = "Отправить x%d для %s",
    ["Send x%d to %s (%s)"] = "Отправить x%d для %s (%s)",
    ["To send from your bags: %s"] = "Отправить из сумок: %s",
    ["You cannot add yourself."] = "Нельзя добавить самого себя.",
    ["craft request"] = "запрос на создание",
    ["waiting for reply"] = "ожидание ответа",
    ["Share all"] = "Поделиться всеми",
    ["Unshare all"] = "Скрыть всех",
    ["Automatically share new characters on this account"] =
      "Автоматически делиться новыми персонажами этого аккаунта",
    ["All characters (%d) are now shared with your group"] =
      "Все персонажи (%d) теперь открыты для твоей группы",
    ["No character is shared anymore"] = "Ни один персонаж больше не открыт",
    ["%s requires higher %s skill; skipped for waypoints until you level up."] =
      "%s требует более высокий навык «%s»; пропущен для меток, пока не повысишь навык.",
    ["Right-click: skip this recipe and recalculate."] =
      "ПКМ: пропустить этот рецепт и пересчитать.",
    ["Reset skipped (%d)"] = "Сбросить пропущенные (%d)",
    -- Trade, Merchant, Wishlist, Cooldowns & UI rework
    ["%d tracked"] = "отслеживается: %d",
    ["%s wants to join your group"] = "%s хочет вступить в твою группу",
    ["Accept to share your checked characters with them."] =
      "Прими, чтобы делиться отмеченными персонажами.",
    ["Add to wishlist"] = "В список желаемого",
    ["All materials are in your bags."] = "Все материалы в твоих сумках.",
    ["Buy plan reagents (%s)"] = "Купить реагенты (%s)",
    ["Click to sync now with your group."] = "Нажми, чтобы синхронизироваться с группой сейчас.",
    ["Compare routes"] = "Сравнить маршруты",
    ["Craft"] = "Создать",
    ["Disenchant"] = "Распыление",
    ["For who:"] = "Для кого:",
    ["Group cooldowns"] = "Восстановления группы",
    ["Hide route comparison"] = "Скрыть сравнение",
    ["Ignore"] = "Игнорировать",
    ["Materials"] = "Материалы",
    ["No craft pinned yet. Right-click any recipe in your Can craft tab to add it here, track its materials and get notified when ready."] =
      "Пока ничего не закреплено. ПКМ по рецепту во вкладке Может создать, чтобы отслеживать материалы и получить уведомление о готовности.",
    ["No disenchantable items in your bags."] = "В сумках нет предметов для распыления.",
    ["Not enough gold (%s needed)."] = "Недостаточно золота (нужно %s).",
    ["Note (optional):"] = "Заметка (необяз.):",
    ["Overview"] = "Обзор",
    ["Pin"] = "Закрепить",
    ["Pin on screen"] = "Закрепить на экране",
    ["Pinned crafts to track materials for yourself or friends."] =
      "Закреплённые предметы для отслеживания материалов для себя или друзей.",
    ["Place needed items"] = "Положить нужное",
    ["Plan reagents"] = "Реагенты плана",
    ["Quantity:"] = "Кол-во:",
    ["Ready"] = "Готово",
    ["Ready (some mats in bank/mail)"] = "Готово (часть в банке/почте)",
    ["Ready to craft!"] = "Можно создавать!",
    ["Right-click: add to Wishlist."] = "ПКМ: добавить в список желаемого.",
    ["Show the wishlist tracker on screen (pinned crafts)."] =
      "Показывать трекер закреплённых рецептов на экране.",
    ["Trade window is full (%d slots)."] = "Окно обмена заполнено (%d ячеек).",
    ["Unpin"] = "Открепить",
    ["Wishlist"] = "Желаемое",
    ["Wishlist ready: %dx %s"] = "Готово к созданию: %dx %s",
    ["none pinned"] = "ничего не закреплено",
    -- Synergies, Audit, Loot, AH Panel, Buy vs Farm
    ["%d small bags (min %d slots) -> %s (%d slots)"] = "%d мал. сумок (мин. %d яч.) -> %s (%d яч.)",
    ["%s can craft %dx %s from group's %s for %s"] = "%s может создать %dx %s из %s группы для %s",
    ["Advice"] = "Совет",
    ["Ask"] = "Попросить",
    ["Back"] = "Спина",
    ["Buy"] = "Купить",
    ["Buy/Farm"] = "Купить/Добыть",
    ["Chest"] = "Грудь",
    ["Click an item to search it."] = "Нажми на предмет для поиска.",
    ["Click: search in Auction House."] = "Клик: искать на аукционе.",
    ["Click: waypoint to farm spot."] = "Клик: метка к месту добычи.",
    ["Cross-profession links between your group's active plans."] =
      "Взаимосвязи между профессиями в активных планах группы.",
    ["Disenchant %dx %s (%s)"] = "Распылить %dx %s (%s)",
    ["Disenchant for your enchanting plan"] = "Распылить для твоего плана наложения чар",
    ["Everyone's bags, enchants and gear are up to date."] =
      "Сумки, чары и экипировка группы актуальны.",
    ["Farm"] = "Добыть",
    ["Farm %s: %s (%s %d, %d)"] = "Добыть %s: %s (%s %d, %d)",
    ["Farm spot"] = "Место добычи",
    ["Feet"] = "Ступни",
    ["Gear"] = "Экипировка",
    ["Gold: %s"] = "Золото: %s",
    ["Group synergies"] = "Синергии группы",
    ["Group upgrades"] = "Улучшения группы",
    ["Hands"] = "Кисти рук",
    ["Known by %s"] = "Знает %s",
    ["Loot roll: %s - needed now by %s"] = "Добыча: %s - нужно сейчас для %s",
    ["Loot roll: %s - unknown by %s"] = "Добыча: %s - не знает %s",
    ["No known farm location for %s."] = "Неизвестное место добычи для %s.",
    ["Send %dx %s to %s to disenchant (%s)"] = "Отправить %dx %s для %s на распыление (%s)",
    ["Send to %s to disenchant"] = "Отправить %s на распыление",
    ["Shield"] = "Щит",
    ["Small bags, unenchanted gear and craftable upgrades your group can make."] =
      "Маленькие сумки, незачарованная экипировка и улучшения, которые может создать группа.",
    ["To buy at the AH"] = "Купить на аукционе",
    ["Total: %s (you have %s)"] = "Итого: %s (у тебя %s)",
    ["Unenchanted %s -> %s"] = "Без чар (%s) -> %s",
    ["Unknown by %s (%s %d/%d)"] = "Не знает %s (%s %d/%d)",
    ["Upgrades"] = "Улучшения",
    ["Vendor"] = "Торговец",
    ["Waypoint: %s (%s %d, %d)"] = "Метка: %s (%s %d, %d)",
    ["Wrist"] = "Запястья",
    ["Your gold: %s"] = "Твоё золото: %s",
    ["by %s"] = "от %s",
    ["can learn now"] = "можно выучить",
    ["needs skill %d"] = "требуется %d",
}
