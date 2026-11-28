-- Tooltip: "Vez : besoin de 30" on items someone in ComradeCraftDB needs.
local _, ns = ...
local Print = ns.Print

function ns.ClassColored(key, class)
  local name = key:match("^[^-]+") or key
  local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  return color and ("|c%s%s|r"):format(color.colorStr, name) or name
end

-- "(now)" green, "(soon)" yellow, "(later)" grey: when the material is first needed.
local URGENCY_COLOR = { now = "40ff40", soon = "ffd100", later = "9d9d9d" }
function ns.UrgencyText(step)
  local u = ns.Urgency(step)
  return ("|cff%s(%s)|r"):format(URGENCY_COLOR[u], ns.L[u])
end

local function ReasonText(prof, spell, convertsTo)
  local parts = {}
  if prof and prof ~= "" then parts[#parts + 1] = prof end
  if spell and ns.SpellName then
    local sn = ns.SpellName(spell)
    if sn and not sn:find("^spell:") then parts[#parts + 1] = sn end
  end
  local base = table.concat(parts, " - ")
  if convertsTo then
    local tn = ns.ItemName and ns.ItemName(convertsTo) or ("item:" .. convertsTo)
    return base ~= "" and (base .. " -> " .. tn) or ("-> " .. tn)
  end
  return base
end

local function AddNeeds(tooltip, itemID)
  if not (itemID and ComradeCraftDB and ComradeCraftDB.chars) then return end
  local mailTarget = ns.Mail and ns.Mail.CurrentRecipient and ns.Mail.CurrentRecipient() or nil
  local rows, total = {}, 0
  for key, c in pairs(ns.AllChars()) do
    for _, r in ipairs(ns.NeedRows(c, itemID)) do
      rows[#rows + 1] = { key = key, class = c.class, prof = r.prof, spell = r.spell, n = r.n, step = r.step,
        convertsTo = r.convertsTo }
      total = total + r.n
    end
  end
  -- Items in this character's bags that can be sent (spare mats + accepted craft requests).
  local sends, targetSend = {}, nil
  local me = ns.CharKey()
  local myBags = (ComradeCraftDB.chars[me] or {}).bags or {}
  if (myBags[itemID] or 0) > 0 then
    for _, g in ipairs(ns.GiveList(me)) do
      if g.item == itemID then
        local e = { to = g.to, n = g.n, prof = g.prof, spell = g.spell, step = g.step, convertsTo = g.convertsTo }
        sends[#sends + 1] = e
        if mailTarget and g.to == mailTarget and not targetSend then targetSend = e end
      end
    end
    for _, r in pairs(ComradeCraftDB.requests or {}) do
      if (r.status == "accepted" or r.status == "crafting") and ns.Requests and ns.Requests.Role(r) == "crafter" and r.item == itemID then
        local dest = ns.Requests.Recipient and ns.Requests.Recipient(r) or r.from
        local qty = math.min(myBags[itemID], math.max(1, r.qty * math.max(1, (ns.Recipes[r.spell] and ns.Recipes[r.spell][6]) or 1) - (r.sentQty or 0)))
        local e = { to = dest, n = qty, spell = r.spell, request = true }
        sends[#sends + 1] = e
        if mailTarget and dest == mailTarget and not targetSend then targetSend = e end
      end
    end
  end
  local myReserve = ns.Reserve and ns.Reserve.Get and ns.Reserve.Get(itemID) or nil
  local incomingRes = ns.Reserve and ns.Reserve.IncomingFor and ns.Reserve.IncomingFor(me, itemID) or {}
  local _, transitList = ns.InTransitFor and ns.InTransitFor(nil, itemID) or 0, {}
  if #rows == 0 and #sends == 0 and not myReserve and #incomingRes == 0 and #transitList == 0 then return end
  local supply, holders = ns.GroupSupply(itemID)
  -- Active mail recipient first, then most urgent, then biggest quantity.
  table.sort(rows, function(a, b)
    if mailTarget and (a.key == mailTarget) ~= (b.key == mailTarget) then return a.key == mailTarget end
    local ua, ub = ns.UrgencyRank(a.step), ns.UrgencyRank(b.step)
    if ua ~= ub then return ua < ub end
    return a.n > b.n
  end)
  tooltip:AddLine(" ")
  tooltip:AddLine("ComradeCraft", 1, 0.82, 0)
  if myReserve and myReserve.to then
    local who = myReserve.to:match("^[^-]+") or myReserve.to
    tooltip:AddLine(ns.L["Reserved for %s (x%d) - Alt+Right-click to unlock"]:format(who, myReserve.qty or 1),
      0.78, 0.48, 1, true)
  end
  for _, ir in ipairs(incomingRes) do
    tooltip:AddLine(ns.L["Reserved for you by %s (x%d)"]:format(ns.ClassColored(ir.from, ir.class), ir.qty),
      0.35, 1, 0.55, true)
  end
  if targetSend then
    local who = targetSend.to:match("^[^-]+") or targetSend.to
    local why = targetSend.request and ns.L["craft request"] or ReasonText(targetSend.prof, targetSend.spell, targetSend.convertsTo)
    local msg = why ~= "" and ns.L["Send x%d to %s (%s)"]:format(targetSend.n, who, why)
      or ns.L["Send x%d to %s"]:format(targetSend.n, who)
    tooltip:AddLine(msg, 0.3, 1, 0.4, true)
  elseif #sends > 0 then
    local parts = {}
    for i = 1, math.min(#sends, 2) do
      local s = sends[i]
      local who = s.to:match("^[^-]+") or s.to
      local why = s.request and ns.L["craft request"] or ReasonText(s.prof, nil, s.convertsTo)
      parts[#parts + 1] = why ~= "" and ("x%d -> %s (%s)"):format(s.n, who, why) or ("x%d -> %s"):format(s.n, who)
    end
    tooltip:AddLine(ns.L["To send from your bags: %s"]:format(table.concat(parts, ", ")), 0.3, 1, 0.4, true)
  end
  for _, r in ipairs(rows) do
    local why = ReasonText(r.prof, r.spell, r.convertsTo)
    local focus = mailTarget and r.key == mailTarget
    local left = focus and ("|cff40ff40>|r %s |cffcccccc%s|r"):format(ns.ClassColored(r.key, r.class), why)
      or ("%s |cff9d9d9d%s|r"):format(ns.ClassColored(r.key, r.class), why)
    tooltip:AddDoubleLine(left, ns.L["needs %d"]:format(r.n) .. " " .. ns.UrgencyText(r.step),
      1, 1, 1, focus and 0.4 or 1, focus and 1 or 0.82, focus and 0.4 or 0.4)
  end
  if #rows > 1 then
    tooltip:AddDoubleLine(ns.L["Group total"], tostring(total), 0.8, 0.8, 0.8, 1, 0.82, 0)
  end
  -- Spare stock elsewhere in the group: who could give it.
  if supply > 0 then
    local who = {}
    for i = 1, math.min(#holders, 4) do
      who[#who + 1] = ("%s %d"):format(holders[i].key:match("^[^-]+") or holders[i].key, holders[i].n)
    end
    tooltip:AddDoubleLine(ns.L["Spare in the group"], table.concat(who, ", "), 0.5, 0.8, 1, 0.5, 0.8, 1)
  end
  -- Active in-transit mail shipments (1h Classic/Forever delay).
  for i = 1, math.min(#transitList, 3) do
    local tr = transitList[i]
    local mins = math.max(1, math.ceil((tr.left or 0) / 60))
    tooltip:AddDoubleLine(ns.L["In transit"],
      ("%dx %s -> %s (~%dm)"):format(tr.qty, tr.from:match("^[^-]+") or tr.from,
        tr.to:match("^[^-]+") or tr.to, mins),
      0.5, 0.85, 1, 0.75, 0.92, 1)
  end
  -- Farming assignments (group plan).
  for _, f in ipairs(ns.Farmers and ns.Farmers(itemID) or {}) do
    tooltip:AddDoubleLine(ns.L["Farmed by %s"]:format(f.key:match("^[^-]+") or f.key), tostring(f.target),
      0.4, 1, 0.4, 0.4, 1, 0.4)
  end
  tooltip:Show()
end
ns.AddNeeds = AddNeeds

-- Group needs, recipe-item status, then the guild directory's crafters of this item.
local function OnItem(tooltip, id)
  AddNeeds(tooltip, id)
  if ns.Loot then ns.Loot.AddTooltip(tooltip, id) end
  if ns.Directory then ns.Directory.AddTooltip(tooltip, id) end
end
ns.OnItemTooltip = OnItem

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    if data and data.id then OnItem(tooltip, data.id) end
  end)
elseif GameTooltip then
  local function OnSetItem(tooltip)
    local _, link = tooltip:GetItem()
    local id = link and tonumber(link:match("item:(%d+)"))
    OnItem(tooltip, id)
  end
  for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
    if tt then tt:HookScript("OnTooltipSetItem", OnSetItem) end
  end
end

local requestedItems = {}
local function ItemNameCache()
  if not ComradeCraftDB then return nil end
  local loc = GetLocale and GetLocale() or "enUS"
  local c = ComradeCraftDB.itemNames
  if type(c) ~= "table" or c.locale ~= loc or type(c.map) ~= "table" then
    c = { locale = loc, map = {} }
    ComradeCraftDB.itemNames = c
  end
  return c.map
end

function ns.RequestItemData(id)
  if not (type(id) == "number" and id > 0) then return end
  if ns.NoteMissingItem then ns.NoteMissingItem(id) end
  if not requestedItems[id] and C_Item and C_Item.RequestLoadItemDataByID then
    requestedItems[id] = true
    pcall(C_Item.RequestLoadItemDataByID, id)
  end
end

function ns.CachedItemName(id)
  local map = id and ItemNameCache()
  return map and map[id] or nil
end

function ns.RememberItemName(id, name)
  if type(id) == "number" and id > 0 and type(name) == "string" and name ~= "" then
    local map = ItemNameCache()
    if map then map[id] = name end
  end
end

local function ItemName(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name = get and get(id)
  if name then
    ns.RememberItemName(id, name)
    return name
  end
  ns.RequestItemData(id)
  return ns.CachedItemName(id) or ("item:" .. tostring(id))
end

local function SpellName(id)
  local name = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id))
    or (GetSpellInfo and GetSpellInfo(id))
  return name or ("spell:" .. id)
end
ns.ItemName, ns.SpellName = ItemName, SpellName

local function Up(n) return math.ceil(n - 1e-9) end

-- Copper amount as text ("1g 2s 3c"), using the game's coin icons when available.
function ns.Money(copper)
  if GetCoinTextureString then return GetCoinTextureString(copper) end
  local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = g .. "g" end
  if s > 0 then parts[#parts + 1] = s .. "s" end
  if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "c" end
  return table.concat(parts, " ")
end

-- "16 Bolt of Woolen Cloth, 8 Fine Thread (vendor)" for `mult` crafts of a recipe.
function ns.ReagentText(spell, mult)
  local s, list = ns.Recipes[spell], {}
  for i = 1, #s[7], 2 do
    local item, n = s[7][i], Up(s[7][i + 1] * (mult or 1))
    list[#list + 1] = ns.IsVendorItem(item) and ns.L["%d %s (vendor)"]:format(n, ItemName(item))
      or ("%d %s"):format(n, ItemName(item))
  end
  return table.concat(list, ", ")
end

-- Buying cost of the mats of `mult` crafts, skipping items in `skip`. Returns copper and
-- whether every mat had a price. Without a price source, returns nil.
function ns.RecipeCost(spell, mult, skip)
  if not ns.PriceSource then return nil end
  local s, sum, complete = ns.Recipes[spell], 0, true
  for i = 1, #s[7], 2 do
    local item = s[7][i]
    if not (skip and skip[item]) then
      local v = ns.BuyCost(item, s[7][i + 1] * (mult or 1))
      if v then sum = sum + v else complete = false end
    end
  end
  return sum, complete
end

-- "~1s 20c" (all mats priced) or ">1s 20c" (some unpriced); nil without a price source.
function ns.CostText(copper, complete)
  if not copper then return nil end
  return (complete and "~" or ">") .. ns.Money(math.floor(copper))
end

-- Chat link of a recipe's product, or of the recipe itself (enchants have no product).
function ns.RecipeLink(spell, item)
  if item and item ~= 0 then
    local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local _, link = get(item)
    if link then return link end
  end
  local T = C_TradeSkillUI
  local link = T and T.GetRecipeLink and select(2, pcall(T.GetRecipeLink, spell))
  if type(link) == "string" then return link end
  link = (C_Spell and C_Spell.GetSpellLink and C_Spell.GetSpellLink(spell)) or (GetSpellLink and GetSpellLink(spell))
  return link
end

-- Opens the profession window on a recipe the character knows. Tries the modern API first,
-- then the older frames; logs which path worked so it can be checked on Forever.
-- Puts the profession window in front of ours once it is open (it opens a moment later).
local function FrontProfession()
  local function Raise()
    if ComradeCraftFrame and ComradeCraftFrame.Lower then ComradeCraftFrame:Lower() end
    for _, name in ipairs({ "TradeSkillFrame", "ProfessionsFrame", "CraftFrame" }) do
      local f = _G[name]
      if f and f.IsShown and f:IsShown() and f.Raise then f:Raise() end
    end
  end
  if C_Timer then C_Timer.After(0.3, Raise) else Raise() end
end

function ns.OpenRecipe(spell)
  if InCombatLockdown and InCombatLockdown() then return end
  local T = C_TradeSkillUI
  local r = ns.Recipes[spell]
  if not (T and r) then return end
  FrontProfession()
  if T.OpenRecipe and pcall(T.OpenRecipe, spell) then ns.Log("open recipe: OpenRecipe") return end
  if T.OpenTradeSkill then pcall(T.OpenTradeSkill, r[1]) end
  local function Select()
    if TradeSkillFrame and TradeSkillFrame.SelectRecipe and pcall(TradeSkillFrame.SelectRecipe, TradeSkillFrame, spell) then
      ns.Log("open recipe: TradeSkillFrame") return
    end
    ns.Log("open recipe: window opened, recipe not selected")
  end
  if C_Timer then C_Timer.After(0.2, Select) else Select() end
end


-- Next rank of a profession (raises the cap by 75). Covers Expert (150->225) and Artisan (225->300)
-- trainers for all 12 professions (Alliance & Horde), plus books and Artisan quests.
local RANK_NAMES = { [75] = "Journeyman", [150] = "Expert", [225] = "Artisan", [300] = "Master" }
local SECONDARY = { [185] = true, [129] = true, [356] = true }
local CLASSIC_REQ = { [75] = { 50, 10 }, [150] = { 125, 20 }, [225] = { 200, 35 }, [300] = { 275, 50 } }
ns.RANK_REQ = CLASSIC_REQ -- [cap] = { skill, character level } to learn the next rank
ns.RANK_NAMES = RANK_NAMES

-- Classic/Forever Expert (cap 150) and Artisan (cap 225) trainers by [cap][skillLine][faction].
-- Each entry: { npcID, name, zone, faction, fallbackPlace = { uiMap, x, y } }.
-- Faction: "A" Alliance, "H" Horde, "AH" neutral/both. Fallback coords ensure 1-click TomTom even without Questie.
ns.RANK_TRAINERS = {
  [150] = {
    [164] = {
      { 4258, "Bengus Deepforge", "Ironforge", "A", { uiMap = 1455, x = 51.0, y = 43.0 } },
      { 3355, "Saru Steelfury", "Orgrimmar", "H", { uiMap = 1454, x = 82.0, y = 23.0 } },
      { 2836, "Brikk Keencraft", "Booty Bay", "AH", { uiMap = 1434, x = 29.0, y = 75.5 } },
    },
    [165] = {
      { 4212, "Telonis", "Darnassus", "A", { uiMap = 1457, x = 64.5, y = 21.6 } },
      { 3007, "Una", "Thunder Bluff", "H", { uiMap = 1456, x = 41.8, y = 42.6 } },
    },
    [171] = {
      { 4160, "Ainethil", "Darnassus", "A", { uiMap = 1457, x = 55.0, y = 24.0 } },
      { 4611, "Doctor Herbert Halsey", "Undercity", "H", { uiMap = 1458, x = 47.6, y = 73.0 } },
    },
    [182] = {
      { 4204, "Firodren Mooncaller", "Darnassus", "A", { uiMap = 1457, x = 48.0, y = 68.4 } },
      { 4614, "Martha Alliestar", "Undercity", "H", { uiMap = 1458, x = 54.2, y = 49.6 } },
      { 3013, "Komin Winterhoof", "Thunder Bluff", "H", { uiMap = 1456, x = 49.8, y = 39.8 } },
    },
    [186] = {
      { 4254, "Geofram Bouldertoe", "Ironforge", "A", { uiMap = 1455, x = 50.4, y = 26.0 } },
      { 3357, "Makaru", "Orgrimmar", "H", { uiMap = 1454, x = 73.0, y = 26.6 } },
      { 3001, "Brek Stonehoof", "Thunder Bluff", "H", { uiMap = 1456, x = 34.4, y = 57.6 } },
    },
    [197] = {
      { 1346, "Georgio Bolero", "Stormwind", "A", { uiMap = 1453, x = 43.2, y = 73.6 } },
      { 4576, "Josef Gregorian", "Undercity", "H", { uiMap = 1458, x = 70.6, y = 30.6 } },
    },
    [202] = {
      { 5174, "Springspindle Fizzlegear", "Ironforge", "A", { uiMap = 1455, x = 68.4, y = 44.0 } },
      { 11017, "Roxxik", "Orgrimmar", "H", { uiMap = 1454, x = 76.0, y = 25.0 } },
    },
    [333] = {
      { 11072, "Kitta Firewind", "Elwynn Forest", "A", { uiMap = 1429, x = 64.9, y = 70.6 } },
      { 11074, "Hgarth", "Stonetalon Mountains", "H", { uiMap = 1442, x = 49.2, y = 57.2 } },
    },
    [393] = {
      { 6292, "Eladriel", "Darnassus", "A", { uiMap = 1457, x = 64.2, y = 21.0 } },
      { 7088, "Thuwd", "Orgrimmar", "H", { uiMap = 1454, x = 63.2, y = 45.2 } },
      { 3373, "Mooranta", "Thunder Bluff", "H", { uiMap = 1456, x = 44.4, y = 43.0 } },
    },
    [185] = {
      { 3955, "Shandrina", "Ashenvale", "A", { uiMap = 1440, x = 49.5, y = 67.1 } },
      { 12033, "Wulan", "Desolace", "H", { uiMap = 1443, x = 26.2, y = 69.7 } },
    },
    [129] = {
      { 2805, "Deneb Walker", "Arathi Highlands", "A", { uiMap = 1417, x = 27.0, y = 58.8 } },
      { 13529, "Balai Lok'Wein", "Dustwallow Marsh", "H", { uiMap = 1445, x = 36.5, y = 30.4 } },
    },
    [356] = {
      { 2626, "Old Man Heming", "Booty Bay", "AH", { uiMap = 1434, x = 27.4, y = 77.0 } },
    },
  },
  [225] = {
    [164] = {
      { 2836, "Brikk Keencraft", "Booty Bay", "AH", { uiMap = 1434, x = 29.0, y = 75.5 } },
    },
    [165] = {
      { 11097, "Drakk Stonehand", "The Hinterlands", "A", { uiMap = 1425, x = 13.4, y = 43.4 } },
      { 11098, "Hahrana Ironhide", "Feralas", "H", { uiMap = 1444, x = 74.4, y = 43.0 } },
    },
    [171] = {
      { 7948, "Kylanna Windwhisper", "Feralas", "A", { uiMap = 1444, x = 32.6, y = 43.8 } },
      { 1386, "Rogvar", "Swamp of Sorrows", "H", { uiMap = 1435, x = 48.4, y = 55.6 } },
    },
    [182] = {
      { 4204, "Firodren Mooncaller", "Darnassus", "A", { uiMap = 1457, x = 48.0, y = 68.4 } },
      { 4614, "Martha Alliestar", "Undercity", "H", { uiMap = 1458, x = 54.2, y = 49.6 } },
      { 3013, "Komin Winterhoof", "Thunder Bluff", "H", { uiMap = 1456, x = 49.8, y = 39.8 } },
    },
    [186] = {
      { 4254, "Geofram Bouldertoe", "Ironforge", "A", { uiMap = 1455, x = 50.4, y = 26.0 } },
      { 3357, "Makaru", "Orgrimmar", "H", { uiMap = 1454, x = 73.0, y = 26.6 } },
      { 8128, "Pikkle", "Tanaris", "AH", { uiMap = 1446, x = 51.0, y = 28.0 } },
    },
    [197] = {
      { 11052, "Timothy Worthington", "Dustwallow Marsh", "A", { uiMap = 1445, x = 66.2, y = 51.6 } },
      { 2399, "Daryl Stack", "Hillsbrad Foothills", "H", { uiMap = 1424, x = 63.6, y = 20.8 } },
    },
    [202] = {
      { 8736, "Buzzek Bracketswing", "Tanaris", "AH", { uiMap = 1446, x = 52.2, y = 27.6 } },
    },
    [333] = {
      { 11073, "Annora", "Uldaman", "AH", { uiMap = 1418, x = 42.8, y = 13.4 } },
    },
    [393] = {
      { 6291, "Balthus Stoneflayer", "Ironforge", "A", { uiMap = 1455, x = 40.0, y = 32.6 } },
      { 7088, "Thuwd", "Orgrimmar", "H", { uiMap = 1454, x = 63.2, y = 45.2 } },
    },
    [185] = {
      { 8125, "Dirge Quikcleave", "Tanaris", "AH", { uiMap = 1446, x = 52.6, y = 28.0 } },
    },
    [129] = {
      { 12340, "Doctor Gustaf VanHowzen", "Dustwallow Marsh", "A", { uiMap = 1445, x = 67.8, y = 49.0 } },
      { 12920, "Doctor Gregory Victor", "Arathi Highlands", "H", { uiMap = 1417, x = 73.4, y = 36.8 } },
    },
    [356] = {
      { 12919, "Nat Pagle", "Dustwallow Marsh", "AH", { uiMap = 1445, x = 58.6, y = 60.2 } },
    },
  },
}

local function RankTrainersFor(line, max)
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  if not faction then return {} end
  local fcode = faction == "Alliance" and "A" or "H"
  local list = ns.RANK_TRAINERS[max] and ns.RANK_TRAINERS[max][line] or {}
  local out = {}
  for _, t in ipairs(list) do
    if t[4] == "AH" or t[4] == fcode then out[#out + 1] = t end
  end
  return out
end

function ns.RankAdvice(p)
  local line, max = p.skillLine, p.max
  if not (line and max and RANK_NAMES[max]) then return nil end
  local out = { title = ns.L["Next rank: %s (%d to %d)"]:format(ns.L[RANK_NAMES[max]], max, max + 75),
    entries = {}, notes = {} }
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  local book, bookData
  for spell, e in pairs(lib and lib.GetRecipes and lib:GetRecipes(line) or {}) do
    if lib.skillRankBooks and lib.skillRankBooks[spell] and e.requiredSkill
      and e.requiredSkill < max and e.requiredSkill >= max - 75 then
      book, bookData = spell, e
    end
  end
  if book then
    local item = bookData.itemId
    local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local name, _, _, _, reqLevel = get(item)
    local parts = { ns.L["skill %d"]:format(bookData.requiredSkill) }
    if reqLevel and reqLevel > 1 then parts[#parts + 1] = ns.L["level %d"]:format(reqLevel) end
    local trs = RankTrainersFor(line, max)
    if trs[1] then
      parts[#parts + 1] = ns.L["sold by %s"]:format(trs[1][2] .. " (" .. trs[1][3] .. ")")
    else
      local src = ns.RecipeSources and ns.RecipeSources(book)
      if src and src.vendor then
        local names = {}
        for i = 1, math.min(2, #src.vendor.list) do names[#names + 1] = src.vendor.list[i].name or "?" end
        parts[#parts + 1] = ns.L["sold by %s"]:format(table.concat(names, ", "))
      end
    end
    local ah = ns.PriceSource and ns.PriceSource(item)
    parts[#parts + 1] = ah and ns.L["or at the AH (~%s)"]:format(ns.Money(math.floor(ah))) or ns.L["or at the AH"]
    out.entries[1] = { kind = "learn", spell = book, item = item, label = name or ItemName(item),
      npc = trs[1] and trs[1][1] or nil, npcName = trs[1] and trs[1][2] or nil,
      zone = trs[1] and trs[1][3] or nil, fallbackPlace = trs[1] and trs[1][5] or nil,
      text = ns.L["Learn %s"]:format(name or ItemName(item)), detail = table.concat(parts, " - ") }
  elseif SECONDARY[line] and max >= 225 then
    -- Artisan comes from a quest that requires the current cap in the skill (QuestieDB).
    local quests = ns.SkillQuests and ns.SkillQuests(line, max)
    if quests == nil then
      out.notes[1] = ns.L["Looking for the quest in Questie..."]
    elseif #quests == 0 then
      local trs = RankTrainersFor(line, max)
      for _, t in ipairs(trs) do
        out.entries[#out.entries + 1] = { kind = "trainer", npc = t[1], zone = t[3], label = t[2], fallbackPlace = t[5],
          text = t[2] .. " (" .. t[3] .. ")", detail = t[3] .. " - " .. ns.L["skill %d"]:format(CLASSIC_REQ[max][1]) }
      end
      out.notes[1] = ns.L["This rank comes from a quest (install Questie to find it)."]
    else
      for i = 1, math.min(3, #quests) do
        local q = quests[i]
        local parts = {}
        if q.level and q.level > 1 then parts[#parts + 1] = ns.L["level %d"]:format(q.level) end
        if q.npcName then parts[#parts + 1] = ns.L["starts at %s"]:format(ns.SourcePlaceText({ id = q.npc, name = q.npcName, place = q.place })) end
        out.entries[#out.entries + 1] = { kind = "quest", quest = q, label = q.name,
          text = ns.L["Quest: %s"]:format(q.name), detail = table.concat(parts, " - ") }
      end
      if #quests > 1 then out.notes[1] = ns.L["Quests that need %d in this skill; the rank quest is among them."]:format(max) end
    end
  else
    local req = CLASSIC_REQ[max]
    for _, t in ipairs(RankTrainersFor(line, max)) do
      local place = ns.NpcPlace and ns.NpcPlace(t[1])
      local where = place and ns.SourcePlaceText and ns.SourcePlaceText({ id = t[1], name = t[2], place = place }) or (t[2] .. " (" .. t[3] .. ")")
      out.entries[#out.entries + 1] = { kind = "trainer", npc = t[1], zone = t[3], label = t[2], fallbackPlace = t[5],
        text = where, detail = ("%s - %s, %s"):format(t[3], ns.L["skill %d"]:format(req[1]), ns.L["level %d"]:format(req[2])) }
    end
    out.notes[1] = ns.L["Learn from a trainer of this profession (requires skill %d, level %d)."]
      :format(req[1], req[2])
  end
  return out
end

-- Human-readable text for one profession's need, shared by the window and /comrade needs.
-- Returns { status, plan = {lines}, used, vendor, blocked } (missing parts are nil).
function ns.DescribeNeed(p, c)
  local line = p.skillLine
  if ns.GATHERING[line] then
    local nearCap = p.rank and p.max and p.rank >= p.max - 25
    return { status = ns.L["Gathering profession: levels by gathering, not crafting."],
      rank = nearCap and ns.RankAdvice(p) or nil }
  end
  local known = line and c.known and c.known[line]
  local need = line and c.needs and c.needs[line]
  if not known then
    return { status = ns.L["Open this profession's window once so your recipes can be read."] }
  end
  if p.rank >= (ns.TargetFor(c, p) or p.max) then
    return { status = ns.L["At the cap (%d)."]:format(p.max), rank = ns.RankAdvice(p) }
  end
  if not need then return { status = ns.L["No data."] } end

  -- Each step spells out the chain, as clickable entries: recipes to learn first (with the
  -- trainer cost), intermediates to craft (raw mats; owned ones spent in step order), then
  -- the main craft. out.steps = { { range, entries = { { kind, spell, item, text } } } };
  -- out.plan is the same as flat text lines (for /comrade needs).
  local out = { plan = {}, steps = {} }
  local ReagentList = ns.ReagentText
  -- Costs exist only with a real price source; `skip` = items made by another entry of
  -- the same step. Returns copper (0 without prices) and whether every mat had a price.
  local priced = ns.PriceSource ~= nil
  local function MatsCost(spell, mult, skip)
    local v, ok = ns.RecipeCost(spell, mult, skip)
    return v or 0, ok or false
  end
  local stock = {}
  for item, n in pairs(need.used or {}) do stock[item] = n end
  local allKnown = {}
  for _, set in pairs(c.known or {}) do for s in pairs(set) do allKnown[s] = true end end
  local learned = {}
  local function LearnEntry(spell)
    if allKnown[spell] or learned[spell] then return nil end
    learned[spell] = true
    local seen = ns.TrainerSeen(spell)
    local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
    local req = seen and seen.req or (lib and lib.GetRequiredSkill and lib:GetRequiredSkill(line, spell))
    local guessed = not (seen and seen.req) and lib and lib.IsBorrowed and lib:IsBorrowed(spell, "requiredSkill")
    local cost = seen and seen.cost and ns.Money(seen.cost) or ns.L["cost unknown until you visit the trainer"]
    return { kind = "learn", spell = spell, item = ns.Recipes[spell][5], copper = seen and seen.cost,
      text = ns.L["Learn %s at the trainer (skill %s, %s)"]:format(SpellName(spell),
        (guessed and "~" or "") .. tostring(req or "?"), cost),
      label = SpellName(spell),
      detail = ns.L["At the trainer - skill %s - %s"]:format((guessed and "~" or "") .. tostring(req or "?"), cost) }
  end
  -- Rank caps the target crosses: a "learn the next rank" step before the first step past
  -- each one, with a warning when the character is below the level it needs (the plan and
  -- the shopping list still go on). rankCost: known book prices only.
  local caps, capIdx, rankCost, rankComplete = need.rankCaps or {}, 1, 0, true
  local function AddRankStep(cap)
    local adv = ns.RankAdvice({ skillLine = line, max = cap })
    if not adv then return end
    local req = CLASSIC_REQ[cap]
    local warn = req and c.level and c.level < req[2]
      and ns.L["Level %d needed to learn this rank (now %d)."]:format(req[2], c.level) or nil
    local first = adv.entries[1]
    local book = first and first.kind == "learn" and first.item
    local v = book and ns.BuyCost(book, 1)
    if v then rankCost = rankCost + v else rankComplete = false end
    out.steps[#out.steps + 1] = { rankCap = cap, header = adv.title, entries = adv.entries,
      notes = adv.notes, warn = warn, from = cap, to = cap,
      cost = priced and v and ("~" .. ns.Money(math.floor(v))) or nil }
    out.plan[#out.plan + 1] = adv.title .. " :"
    if warn then out.plan[#out.plan + 1] = "  " .. warn end
    for _, e in ipairs(adv.entries) do out.plan[#out.plan + 1] = "  " .. e.text end
    for _, n in ipairs(adv.notes) do out.plan[#out.plan + 1] = "  " .. n end
  end
  for _, step in ipairs(need.plan or {}) do
    while caps[capIdx] and step.from >= caps[capIdx] do
      AddRankStep(caps[capIdx])
      capIdx = capIdx + 1
    end
    local entries = {}
    local subSpells = {}
    for sub in pairs(step.subs or {}) do subSpells[#subSpells + 1] = sub end
    table.sort(subSpells)
    for _, sub in ipairs(subSpells) do entries[#entries + 1] = LearnEntry(sub) end
    entries[#entries + 1] = LearnEntry(step.spell)
    local stepCost, stepComplete, made = 0, true, {}
    for _, e in ipairs(entries) do
      if e.copper then stepCost = stepCost + e.copper else stepComplete = false end
    end
    for _, sub in ipairs(subSpells) do
      local s = ns.Recipes[sub]
      local item, qty = s[5], math.max(1, s[6])
      -- Scaled to the rounded-up main craft count, so "37x Gloves (148 Bolts)" matches.
      local scale = step.crafts > 0 and Up(step.crafts) / step.crafts or 1
      local wanted = Up(step.subs[sub] * scale * qty)
      local fromStock = math.min(stock[item] or 0, wanted)
      stock[item] = (stock[item] or 0) - fromStock
      local toMake = wanted - fromStock
      local text, detail
      made[item] = true
      if toMake > 0 then
        detail = ReagentList(sub, toMake / qty)
        text = ns.L["Craft %d %s (%s)"]:format(toMake, ItemName(item), detail)
        if fromStock > 0 then
          text = text .. ns.L[" + %d from stock"]:format(fromStock)
          detail = detail .. ns.L[" + %d from stock"]:format(fromStock)
        end
        local v, ok = MatsCost(sub, toMake / qty)
        stepCost, stepComplete = stepCost + v, stepComplete and ok
      else
        text = ns.L["%d %s from stock"]:format(fromStock, ItemName(item))
        detail = ns.L["already in your bags"]
      end
      entries[#entries + 1] = { kind = "craft", spell = sub, item = item, text = text, stock = toMake == 0,
        n = toMake > 0 and toMake or fromStock, label = ItemName(item), detail = detail }
    end
    entries[#entries + 1] = { kind = "craft", spell = step.spell, item = ns.Recipes[step.spell][5],
      text = ns.L["Craft %dx %s (%s)"]:format(Up(step.crafts), SpellName(step.spell),
        ReagentList(step.spell, Up(step.crafts))),
      n = Up(step.crafts), label = SpellName(step.spell), detail = ReagentList(step.spell, Up(step.crafts)) }
    local v, ok = MatsCost(step.spell, Up(step.crafts), made)
    stepCost, stepComplete = stepCost + v, stepComplete and ok
    local range = ("%d-%d"):format(step.from, step.to)
    if priced then
      range = range .. "  |cffb0b0b0" .. (stepComplete and "~" or ">") .. ns.Money(math.floor(stepCost)) .. "|r"
    end
    out.steps[#out.steps + 1] = { range = range, entries = entries, from = step.from, to = step.to,
      cost = priced and ((stepComplete and "~" or ">") .. ns.Money(math.floor(stepCost))) or nil }
    out.plan[#out.plan + 1] = range .. " :"
    for _, e in ipairs(entries) do out.plan[#out.plan + 1] = "  " .. e.text end
  end
  while caps[capIdx] and (need.reached or 0) >= caps[capIdx] do
    AddRankStep(caps[capIdx])
    capIdx = capIdx + 1
  end
  local k = need.knownOnly
  if k and k.reached < need.reached then
    out.knownOnly = ns.L["With only your current recipes, you would be stuck at %d."]:format(k.reached)
  end

  -- Totals of the route to the target, both route types (ns.TargetTotals).
  if priced then
    local trainer, trainerOk = rankCost, rankComplete
    for _, step in ipairs(out.steps) do
      if not step.rankCap then
        for _, e in ipairs(step.entries) do
          if e.kind == "learn" then
            if e.copper then trainer = trainer + e.copper else trainerOk = false end
          end
        end
      end
    end
    out.totals = ns.TargetTotals(need, trainer, trainerOk)
    local t = out.totals.routes[1]
    out.cost = ns.L["Total %d to %d: gross %s, to buy %s, resale %s, trainer %s, net %s (%s prices)."]:format(
      p.rank, need.reached, ns.TotalMoney(t.brut, t.brutOk), ns.TotalMoney(t.buy, t.buyOk),
      ns.Money(math.floor(t.resale)), ns.TotalMoney(trainer, trainerOk), ns.TotalMoney(t.net, t.netOk),
      ns.PriceSourceName)
  end

  local used = {}
  for item, n in pairs(need.used or {}) do used[#used + 1] = ("%d %s"):format(n, ItemName(item)) end
  if #used > 0 then out.used = ns.L["Uses what you already have: %s."]:format(table.concat(used, ", ")) end

  local vendor = {}
  for item, n in pairs(need.vendor or {}) do vendor[#vendor + 1] = ("%s x%d"):format(ItemName(item), n) end
  table.sort(vendor)
  if #vendor > 0 then out.vendor = ns.L["Buy from a vendor: %s."]:format(table.concat(vendor, ", ")) end

  if need.reason then
    local why = need.reason == "grey"
      and ns.L["Stuck at %d: all your known recipes are grey (no more points)."]:format(need.reached)
      or ns.L["Stuck at %d: your known recipes barely give points anymore (%d%% chance per craft at best, %d%% needed)."]:format(
        need.reached, math.floor((need.bestGain or 0) * 100 + 0.5), ns.MIN_GAIN * 100)
    local learn = {}
    for _, x in ipairs(ns.NextRecipes(line, need.reached, known)) do
      local kinds = {}
      for k in pairs(x.kinds) do kinds[#kinds + 1] = ns.L[k] end
      table.sort(kinds)
      learn[#learn + 1] = ("%s (%sskill %s%d)"):format(SpellName(x.spell),
        #kinds > 0 and (table.concat(kinds, "/") .. ", ") or "", x.borrowed and "~" or "", x.req)
    end
    out.blocked = why .. (#learn > 0 and ns.L[" To learn: %s."]:format(table.concat(learn, ", "))
      or ns.L[" No recipe to learn found within the next 25 points."])
  end
  -- The plan reaches a rank cap: what comes next.
  local goal = need.target or p.max
  if (need.reached or 0) >= goal and RANK_NAMES[goal] then
    out.rank = ns.RankAdvice({ skillLine = line, max = goal })
  end
  return out
end

-- Copper as text, ">" in front when some prices were missing (the sum is a minimum).
function ns.TotalMoney(v, complete)
  if not complete and (v or 0) == 0 then return "?" end -- nothing known at all
  local s = ns.Money(math.floor(math.abs(v or 0)))
  if (v or 0) < 0 then s = "-" .. s end
  return (complete and "" or ">") .. s
end

-- Pure: totals of a need's route to its target, active route first. Per route: brut (every
-- mat), buy (missing mats, AH + merchant), resale (best per product, the milestone values),
-- net = buy - resale + trainer. The other route has no trainer cost (its recipes differ).
function ns.TargetTotals(need, trainer, trainerOk)
  local function Buy(list)
    local t, ok = 0, true
    for item, n in pairs(list or {}) do
      local v = ns.BuyCost(item, n)
      if v then t = t + v else ok = false end
    end
    return t, ok
  end
  local function Resale(ms)
    local t = 0
    for _, m in pairs(ms or {}) do t = t + (m.best or 0) end
    return t
  end
  local routes = {}
  local brut, brutOk = Buy(need.gross)
  local b1, ok1 = Buy(need.items)
  local b2, ok2 = Buy(need.vendor)
  local resale = Resale(need.milestones)
  routes[1] = { mode = need.mode, active = true, reached = need.reached, brut = brut, brutOk = brutOk,
    buy = b1 + b2, buyOk = ok1 and ok2, resale = resale, trainer = trainer or 0,
    net = b1 + b2 - resale + (trainer or 0), netOk = ok1 and ok2 and (trainerOk ~= false) }
  local alt = need.alt
  if alt and alt.gross then
    local ab, abOk = Buy(alt.gross)
    local ob, obOk = Buy(alt.items)
    local ar = Resale(alt.milestones)
    routes[2] = { mode = alt.mode, reached = alt.reached, brut = ab, brutOk = abOk, buy = ob, buyOk = obOk,
      resale = ar, net = ob - ar, netOk = obOk, noTrainer = true }
  end
  return { routes = routes, trainer = trainer or 0, trainerOk = trainerOk ~= false }
end

-- Cost per bracket of both route types, for the Plan tab's table. Per route: copper spent on
-- mats, best resale (per item: merchant, disenchant or AH), net = mats - best, plus each way
-- of selling for the tooltip. { header, rows = { { from, to, routes = { {..}, {..} } } } }.
function ns.MilestoneRows(need)
  if not (need and need.milestones and need.alt) then return nil end
  local byMode = { [need.mode] = need.milestones, [need.alt.mode] = need.alt.milestones }
  local starts, seen = {}, {}
  for _, ms in pairs(byMode) do
    for b in pairs(ms) do
      if not seen[b] then seen[b] = true starts[#starts + 1] = b end
    end
  end
  table.sort(starts)
  if #starts == 0 then return nil end
  local rows = {}
  for _, b in ipairs(starts) do
    local row = { from = math.max(1, b), to = b + ns.MILESTONE, routes = {} }
    for _, mode in ipairs(ns.ROUTES) do
      local m = byMode[mode][b]
      row.routes[#row.routes + 1] = { mode = mode, active = mode == need.mode, m = m,
        net = m and (m.mats - (m.best or 0)) }
    end
    rows[#rows + 1] = row
  end
  local header = ns.PriceSource and ns.L["Cost by milestone (%s prices)"]:format(ns.PriceSourceName)
    or ns.L["Cost by milestone (merchant prices; TSM or Auctionator give AH prices)"]
  return { header = header, rows = rows }
end

-- /comrade needs: same text as the window, for the current character.
ns.commands.needs = function()
  local c = ns.CharData()
  ns.UpdateNeeds(c)
  for name, p in pairs(c.professions or {}) do
    local d = ns.DescribeNeed(p, c)
    Print(("%s %d/%d"):format(name, p.rank or 0, p.max or 0))
    if d.status then Print("  " .. d.status) end
    for _, l in ipairs(d.plan or {}) do Print("  " .. l) end
    if d.used then Print("  " .. d.used) end
    if d.knownOnly then Print("  " .. d.knownOnly) end
    if d.cost then Print("  " .. d.cost) end
    local need = c.needs and c.needs[p.skillLine]
    for item, n in pairs(need and need.items or {}) do
      Print(ns.L["  missing %s x%d"]:format(ItemName(item), n))
    end
    if d.vendor then Print("  " .. d.vendor) end
    if d.blocked then Print("  " .. d.blocked) end
    if d.rank then
      Print("  " .. d.rank.title)
      for _, e in ipairs(d.rank.entries) do Print("    " .. e.text .. " (" .. e.detail .. ")") end
      for _, n in ipairs(d.rank.notes) do Print("    " .. n) end
    end
  end
end
