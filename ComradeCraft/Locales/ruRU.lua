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
    ["The window"] =
      "Окно",
    ["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] =
      "Слева: группа, затем каждый персонаж. План = как прокачать профессию; Может создать = что персонаж может сделать для группы. Метки фильтруют по профессии.",
    ["Plans"] =
      "Планы",
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
    ["Plan and Can craft"] =
      "План и Может создать",
    ["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."] =
      "Выбери персонажа: План показывает, как шаг за шагом прокачать каждую профессию; Может создать показывает, что он может сделать для других.",
    ["While you play"] =
      "Пока ты играешь",
    ["Sharing is off until you check a box"] = "Обмен выключен, пока ты не поставишь галочку",
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
    ["Click a member to highlight their items."] = "Нажми на участника, чтобы подсветить нужные ему предметы.",
    ["Click to select recipient and highlight needed items in your bags."] =
      "Нажми, чтобы выбрать получателя и подсветить нужные ему предметы в сумках.",
    ["Collapse all"] = "Свернуть всё",
    ["ComradeCraft: Add to group"] = "ComradeCraft: Добавить в группу",
    ["Expand all"] = "Развернуть всё",
    ["Filter recipes..."] = "Фильтр рецептов...",
    ["Search stock or crafters..."] = "Поиск запасов или ремесленников...",
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
    ["by %s (guild)"] = "от %s (гильдия)",
    ["can learn now"] = "можно выучить",
    ["needs skill %d"] = "требуется %d",
    ["+%d score"] = "+%d очк.",
    ["Head"] = "Голова",
    ["Neck"] = "Шея",
    ["Shoulder"] = "Плечи",
    ["Waist"] = "Пояс",
    ["Legs"] = "Ноги",
    ["Finger"] = "Палец",
    ["Trinket"] = "Аксессуар",
    ["Off-Hand"] = "Левая рука",
    ["Ranged"] = "Дальний бой",
    ["Spec: %s"] = "Спек: %s",
    ["Spec set to %s."] = "Специализация: %s.",
    ["Unknown spec. Available: %s"] = "Неизвестный спек. Доступны: %s",
    ["Crafts upgrade for: %s"] = "Создаёт улучшение для: %s",
    ["Useful enchant for: %s"] = "Полезные чары для: %s",
    ["Leveling plan"] = "План прокачки",
    ["Upgrade for %s (%s)"] = "Улучшение для %s (%s)",
    ["Good enchant for %s"] = "Хорошие чары для %s",
    ["Click to train."] = "Клик: изучить.",
    ["Recommended recipes"] = "Рекомендуемые рецепты",
    ["mats ready"] = "рег. готовы",
    ["Soon (+1-4 lvl)"] = "Скоро (+1-4 ур.)",
    ["Consumables"] = "Расходники",
    ["Patterns to hunt"] = "Рецепты для фарма",
    ["Waypoint"] = "Метка",
    ["Group materials:"] = "Материалы группы:",
    ["%d mobs"] = "%d мобов",
    ["1 mob"] = "1 моб",
    ["in bank"] = "в банке",
    ["In bank (retrieve first)"] = "В банке (сначала забери)",
    ["Full name (First Last) required for %s: log them in once or type their full name first."] =
      "Для %s нужно полное имя (Имя Фамилия): войди этим персонажем или введи полное имя вручную.",
    ["Withdraw from bank"] = "Взять из банка",
    ["Withdraw needed"] = "Взять нужное",
    ["Click an item to withdraw it."] = "Нажми на предмет, чтобы забрать.",
    ["Your bags are full."] = "Сумки заполнены.",
    ["For your plan"] = "Для твоего плана",
    ["To send to %s"] = "Отправить %s",
    ["Right-click: %dx %s -> %dx %s"] = "ПКМ: %dx %s -> %dx %s",
    ["BoE patterns"] = "BoE-рецепты",
    ["Share in chat"] = "Поделиться в чате",
    ["Shared bank alt"] = "Общий банк-альт",
    ["Shared bank alt: all items on this character (bags, bank, mail) appear as available to your group, and members can request them via the addon."] = "Общий банк-альт: все предметы этого персонажа (сумки, банк, почта) отображаются доступными для группы, и участники могут запрашивать их через аддон.",
    ["Bank"] = "Банк",
    ["Ask %s for %s"] = "Попросить у %s: %s",
    ["%s asks %s for %dx %s."] = "%s просит у %s: %dx %s.",
    ["Request"] = "Запросить",
    ["No items stored yet."] = "Пока нет хранимых предметов.",
    ["Filter items..."] = "Фильтр предметов...",
    ["Your group's skill levels, synergies, items you can give, and active cooldowns."] = "Уровни профессий группы, синергии, лишние предметы для передачи и активные кулдауны.",
    ["All materials your group still needs, sorted by urgency. Type to find who can craft something."] = "Все материалы, которые ещё нужны группе, по срочности. Введи текст, чтобы найти крафтера.",
    ["Craftable BiS gear, enchants, consumables, small bags, and patterns to hunt for each member."] = "Крафтовая BiS-экипировка, чары, расходники, маленькие сумки и редкие рецепты для каждого участника.",
    ["Green items in your bags: keep for enchants or upgrades, sell on the AH, or disenchant."] = "Зелёные вещи в сумках: оставить для чар или апгрейдов, продать на аукционе или распылить.",
    ["Left: Group overview, Materials, Craftable BiS Upgrades, Wishlist, Requests, and every character in your group."] = "Слева: Обзор группы, Материалы, Крафтовые BiS-апгрейды, Список желаний, Запросы и все персонажи.",
    ["Bags highlight items your group needs; helper panels dock at Mail, Bank, Trade, Merchant, AH, and Trainers."] = "Сумки подсвечивают нужное группе; панели-помощники крепятся к Почте, Банку, Обмену, Торговцу, Аукциону и Тренерам.",
    ["Nothing is shared yet. Here, in Manage group, check characters to share (or flag a Shared bank alt), then add friends below. Mutually added peers relay updates automatically."] = "Пока ничего не передаётся. Отметь персонажей для обмена (или Общий банк-альт) и добавь друзей ниже. Взаимные контакты автоматически ретранслируют обновления.",
    ["Reserved %dx %s for %s."] = "Зарезервировано %dx %s для %s.",
    ["Reservation removed for %s."] = "Резерв снят с %s.",
    ["Reserve for..."] = "Зарезервировать для...",
    ["Unlock reservation"] = "Снять резерв",
    ["Usage: /comrade reserve [Item] Name [qty]"] = "Использование: /comrade reserve [Предмет] Имя [кол-во]",
    ["Usage: /comrade unreserve [Item]"] = "Использование: /comrade unreserve [Предмет]",
    ["Reserved for %s"] = "Резерв для %s",
    ["Reserved for %s (x%d) - Alt+Right-click to unlock"] = "Резерв для %s (x%d) - Alt+ПКМ для снятия",
    ["Reserved for you by %s (x%d)"] = "Зарезервировано для тебя игроком %s (x%d)",
    ["Reserved"] = "Резерв",
    ["Favorite"] = "Избранный",
    ["Unstar"] = "Убрать",
    ["Farming for you"] = "Фармят для тебя",
    ["Filter characters..."] = "Фильтр персонажей...",
    ["by %s (you)"] = "от %s (ты)",
    ["crafting"] = "создаётся",
    ["shipped"] = "отправлено",
    ["Crafting"] = "Создаётся",
    ["Shipped"] = "Отправлено",
    ["Ready to craft"] = "Готово к крафту",
    ["Ready to ship"] = "Готово к отправке",
    ["Missing %s"] = "Не хватает %s",
    ["Missing %d"] = "Не хватает %d",
    ["Reserved for you"] = "Зарезервировано для тебя",
    ["Your reserved items"] = "Твои резервы",
    ["Unlock"] = "Снять",
    ["reserved"] = "резерв",
    ["Click: reserve for %s."] = "Клик: зарезервировать для %s.",
    ["Click: request from %s [Bank]."] = "Клик: запросить у %s [Банк].",
    ["Favorites"] = "Избранное",
    ["My characters"] = "Мои персонажи",
    ["Group members"] = "Участники группы",
    ["%d farming"] = "%d фармят",
    ["Auto-marked request %dx %s as shipped."] = "Запрос %dx %s автоматически отмечен как отправленный.",
    ["Alt+Right-click any bag item to reserve/lock it for a friend before mailing."] = "Alt+ПКМ по предмету в сумке, чтобы зарезервировать его для друга до отправки.",
    ["Item reservations"] = "Резервирование предметов",
    ["  %s: %d crafts, %d points (expected %.1f)%s"] = "  %s: %d крафтов, %d очков (ожидалось %.1f)%s",
    ["Add friends"] = "Добавить друзей",
    ["All window and tracker positions reset."] = "Позиции всех окон и трекеров сброшены.",
    ["Auction House panel"] = "Панель аукциона",
    ["Bank panel"] = "Панель банка",
    ["Browse Can craft"] = "Открыть Может создать",
    ["Browse Upgrades"] = "Открыть Улучшения",
    ["Companion panels"] = "Боковые панели",
    ["Configure companion panels, UI scale, sounds, and window positions."] = "Настройка боковых панелей, масштаба интерфейса, звуков и позиций окон.",
    ["Crafts logged by you and your group automatically calibrate skill-up chances for WoW Forever."] = "Крафты тебя и твоей группы автоматически калибруют шансы повышения навыка для WoW Forever.",
    ["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never."] = "Каждый шаг показывает, что изучить у учителя, что скрафтить сначала (рулоны, слитки...) и сколько. Клик открывает рецепт, Shift+клик — ссылка в чат. Цвета: оранжевый всегда даёт очко, жёлтый обычно, зелёный редко, серый никогда.",
    ["Interface"] = "Интерфейс",
    ["Known recipes. Right-click to pin to Wishlist, or click a friend's recipe to request it."] = "Известные рецепты. ПКМ — закрепить в Списке желаемого, клик по рецепту друга — запросить крафт.",
    ["Learn from a trainer of this profession (requires skill %d, level %d)."] = "Изучается у учителя этой профессии (требуется навык %d, уровень %d).",
    ["Left-click: open window  |  Right-click: options"] = "ЛКМ: открыть окно  |  ПКМ: настройки",
    ["List my character"] = "Добавить персонажа",
    ["Mailbox panel"] = "Панель почты",
    ["Merchant panel"] = "Панель торговца",
    ["No friends in your group yet. Add guildmates or friends to share mats and upgrades."] = "В твоей группе пока нет друзей. Добавь друзей или согильдийцев, чтобы делиться материалами и улучшениями.",
    ["Open ComradeCraft"] = "Открыть ComradeCraft",
    ["Play sound notifications"] = "Звуковые уведомления",
    ["Reset window positions"] = "Сбросить позиции окон",
    ["Show minimap button"] = "Кнопка у миникарты",
    ["Step-by-step profession leveling route, cost comparison, and trainer guide."] = "Пошаговый маршрут прокачки, сравнение стоимости и гид по учителям.",
    ["Sync: %d players in the group, %d suggested."] = "Синхр.: %d игроков в группе, %d предложено.",
    ["Toggle ComradeCraft"] = "Открыть / скрыть ComradeCraft",
    ["Trade panel"] = "Панель обмена",
    ["Trainer panel"] = "Панель учителя",
    ["Window scale"] = "Масштаб окна",
    ["AH ~%s"] = "Аукцион ~%s",
    ["For"] = "Для",
    ["Important unlearned patterns to buy or farm for yourself and your group (with drop rate and waypoints)."] = "Важные неизученные рецепты, которые стоит купить или выбить для тебя и группы (шанс дропа и метки).",
    ["No unlearned upgrade patterns found for this character right now."] = "Сейчас не найдено неизученных рецептов улучшений для этого персонажа.",
    ["Patterns"] = "Рецепты",
    ["Valuable unlearned patterns for yourself and your group: where to buy or farm them, drop rate when known, and 1-click waypoints."] = "Полезные неизученные рецепты для тебя и группы: где купить или выбить, шанс дропа (если известен) и метки в 1 клик.",
  ["Bargains"] = "Скидки",
  ["Deals"] = "Скидки",
  ["Group needs spotted below market price."] = "Нужные группе товары ниже рыночной цены.",
  ["Character"] = "Персонаж",
  ["Slot"] = "Слот",
  ["Group by:"] = "Группировка:",
  ["Enchants"] = "Чары",
  ["Bags"] = "Сумки",
  ["Claim CD"] = "Занять КД",
  ["Estimated net profit and 1-click Claim CD for your group's long cooldowns."] = "Оценка чистой прибыли и запрос в 1 клик для долгих КД группы.",
  ["Craft chain planned (%d steps for %s)."] = "Цепочка крафта запланирована (%d шагов для %s).",
  ["Multi-profession craft chain"] = "Межпрофессиональная цепочка крафта",
  ["Plan chain (%d)"] = "Цепочка (%d)",
  ["Forever P2P DB: %d recipe bounds, %d vendors, %d drops (from %d peers)."] = "База Forever P2P: %d порогов, %d торговцев, %d дропов (от %d участников).",
  ["In %s (%d finds):"] = "В %s (%d находок):",
  ["In %s: %s"] = "В %s: %s",
  ["In your zone: %s"] = "В вашей зоне: %s",
  ["Nothing specific for your group found in %s."] = "Ничего особенного для группы в %s не найдено.",
  ["Rare drops, vendors, patterns and materials useful to your group right here."] = "Редкие мобы, торговцы, рецепты и материалы для группы прямо здесь.",
  ["world drop"] = "мировой дроп",
  ["world drop - here (%s)"] = "мировой дроп - здесь (%s)",
  ["world drop - near %s"] = "мировой дроп - рядом с %s",
  ["%d bounds  |  %d custom recipes  |  %d disenchants  |  %d vendors  |  %d drops  (%d peers)"] = "%d порогов  |  %d новых рецептов  |  %d распылений  |  %d торговцев  |  %d дропов  (%d пиров)",
  ["%d in transit"] = "%d в пути",
  ["Accepted craft requests & pinned wishlist for this profession."] = "Принятые заказы и закреплённый список желаний для этой профессии.",
  ["Already mailed between group accounts — counted as on the way so nobody double-sends."] = "Уже отправлено между аккаунтами группы — учитывается в пути, чтобы не слать дважды.",
  ["Applied craft kit \"%s\" (x%d)."] = "Набор \"%s\" применён (x%d).",
  ["Apply x1"] = "Применить x1",
  ["Apply x5"] = "Применить x5",
  ["Click to open recipe (trade slot 7)"] = "Клик: открыть рецепт (ячейка обмена 7)",
  ["Click to open this enchant for the trade slot."] = "Нажми, чтобы открыть чары для окна обмена.",
  ["Craft kits"] = "Наборы крафта",
  ["Craft request (%s)"] = "Заказ (%s)",
  ["Deliver to %s"] = "Доставить %s",
  ["Enchant auto-completes request on trade"] = "Чары автоматически завершают заказ при обмене",
  ["Forever P2P database"] = "База P2P WoW Forever",
  ["In group stock: \"%s\""] = "В запасах группы: \"%s\"",
  ["In transit"] = "В пути",
  ["In transit (1h mail)"] = "В пути (почта 1 ч)",
  ["Next: %s (%d left)"] = "Далее: %s (ост. %d)",
  ["Observed WoW Forever recipe bounds, custom recipes, disenchants, vendors and drops shared automatically."] = "Пороги Forever, новые рецепты, распыления, торговцы и дроп синхронизируются автоматически.",
  ["Orders (%d)"] = "Заказы (%d)",
  ["Reserved by %s"] = "Забронировал %s",
  ["Reusable craft bundles (raid, dungeon, reroll) — apply in 1 click."] = "Повторяемые наборы (рейд, подземелье, альт) — применяются в 1 клик.",
  ["Save as kit"] = "Сохранить набор",
  ["Save current wishlist as a reusable kit"] = "Сохранить текущий список как набор",
  ["Save kit"] = "Сохранить",
  ["Saved craft kit \"%s\" (%d recipes)."] = "Набор \"%s\" сохранён (%d рецептов).",
  ["Sent %d/%d"] = "Отправлено %d/%d",
  ["Sent %d/%d %s."] = "Отправлено %d/%d %s.",
  ["Share now"] = "Поделиться",
  ["Step %d/%d"] = "Шаг %d/%d",
  ["Waiting previous step"] = "Ждёт предыдущий шаг",
  ["Wishlist completed: %s"] = "Список выполнен: %s",
  ["measured"] = "измерено",
    -- Target skill (Plan tab)
    ["Buy %s at the auction house (skill %s, %s)"] = "Купить %s на аукционе (навык %s, %s)",
    ["Auction house - skill %s - %s"] = "Аукцион - навык %s - %s",
    ["Buy recipe: %s"] = "Купить рецепт: %s",
    ["Buy %s from %s (skill %s, %s)"] = "Купить %s у %s (навык %s, %s)",
    ["Vendor: %s - skill %s - %s"] = "Торговец: %s - навык %s - %s",
    ["price unknown until you visit the vendor"] = "цена неизвестна, пока не зайдёшь к торговцу",
    ["a vendor"] = "торговец",
    ["Trainer & recipes"] = "Учитель и рецепты",
    ["+ Trainer & recipes: %s (in the net). To buy = missing mats (AH + merchant); net = to buy - resale + trainer & recipes."] = "+ Учитель и рецепты: %s (входит в чистые). Купить = недостающие материалы (аукцион + торговец); чистыми = купить - перепродажа + учитель и рецепты.",
    ["(your side only)"] = "(только у вас)",
    ["Target:"] = "Цель:",
    ["Target skill"] = "Целевой навык",
    ["Type a skill (up to 300) and press Enter. Mouse wheel: +/-5 (Shift: 25)."] = "Введите навык (до 300) и нажмите Enter. Колесо мыши: +/-5 (Shift: 25).",
    ["(cap) - click to change, Enter to apply"] = "(макс.) - нажмите, чтобы изменить, Enter - применить",
    ["click to change, Enter to apply"] = "нажмите, чтобы изменить, Enter - применить",
    ["Target %d"] = "Цель %d",
    ["Cap"] = "Макс.",
    ["Level %d needed to learn this rank (now %d)."] = "Нужен уровень %d, чтобы выучить этот ранг (сейчас %d).",
    ["Total %d to %d (%s prices)"] = "Итого с %d до %d (цены: %s)",
    ["Total %d to %d: gross %s, to buy %s, resale %s, trainer %s, net %s (%s prices)."] = "Итого с %d до %d: всего %s, купить %s, перепродажа %s, учитель %s, чистыми %s (цены: %s).",
    ["Gross"] = "Всего",
    ["To buy"] = "Купить",
    ["Resale"] = "Перепродажа",
    ["Net"] = "Чистыми",
    ["not counted"] = "не учтено",
    ["Stops at"] = "Остановится на",
    ["Other route: trainer not counted."] = "Другой путь: учитель не учтён.",
    ["> = some prices are unknown: a cost is a minimum, a profit (+<) a maximum."] = "> = некоторые цены неизвестны: расход - это минимум, прибыль (+<) - максимум.",
}
