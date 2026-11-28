-- Goldmaking: what a craft really costs (buy each mat or craft it yourself, recursively), which
-- known recipes earn the most per day at the AH's pace, and unlearned recipes worth buying.
-- Prices: ns.PriceSource (live scans, TSM, Auctionator, ComradeCraftDB.ahPrices); sales per day:
-- ComradeCraftDB.saleRates (open slot any addon may fill) or TSM.
local _, ns = ...

ns.GOLD_SHARE = 0.30 -- share of an item's daily AH sales you can expect to take
ns.GOLD_BATCH = 20   -- crafts per day at most, for one recipe
ns.GOLD_TOP = 5

local producersOf, producersN
local function ProducersOf(item)
  local n = 0
  for _ in pairs(ns.Recipes) do n = n + 1 end
  if not producersOf or n ~= producersN then -- custom recipes can join ns.Recipes later
    producersOf, producersN = {}, n
    for spell, r in pairs(ns.Recipes) do
      if r[5] and r[5] ~= 0 then
        producersOf[r[5]] = producersOf[r[5]] or {}
        table.insert(producersOf[r[5]], spell)
      end
    end
  end
  return producersOf[item]
end

-- Cheapest way to get one item: buy it (AH, or merchant for vendor mats) or craft it with a
-- recipe in `can` ({ [spell] = true }), recursively. Returns copper (nil: no price anywhere)
-- and the recipe used (nil = bought). `memo` is shared across calls of one computation.
function ns.UnitCost(item, can, memo, depth)
  memo = memo or {}
  local m = memo[item]
  if m then return m[1], m[2] end
  memo[item] = {} -- cycle guard
  local best, via = ns.BuyCost(item, 1), nil
  if (depth or 0) < 4 then
    for _, spell in ipairs(ProducersOf(item) or {}) do
      if can[spell] and not (ns.IsCooldownRecipe and ns.IsCooldownRecipe(spell)) then
        local c = ns.RecipeMatsCost(spell, can, memo, (depth or 0) + 1)
        c = c and c / math.max(1, ns.Recipes[spell][6])
        if c and (not best or c < best) then best, via = c, spell end
      end
    end
  end
  memo[item] = { best, via }
  return best, via
end

-- Mats of one craft at their cheapest (ns.UnitCost); nil when one has no price.
function ns.RecipeMatsCost(spell, can, memo, depth)
  local r = ns.Recipes[spell]
  if not r then return nil end
  local v = 0
  for i = 1, #r[7], 2 do
    local u = ns.UnitCost(r[7][i], can, memo, depth)
    if not u then return nil end
    v = v + u * r[7][i + 1]
  end
  return v
end

-- Items sold per day at the AH: saleRates (fresh), else TSM; nil when unknown.
function ns.SalesPerDay(item)
  local r = ComradeCraftDB and ComradeCraftDB.saleRates and ComradeCraftDB.saleRates[item]
  if type(r) == "table" and type(r.perDay) == "number" and (time() - (r.t or 0)) <= ns.SALE_RATE_TTL then
    return r.perDay
  end
  if TSM_API and TSM_API.GetCustomPriceValue then
    local ok, v = pcall(TSM_API.GetCustomPriceValue, "DBRegionSoldPerDay*1000", "i:" .. item)
    if ok and type(v) == "number" then return v / 1000 end
  end
end

local function Stackable(item)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local stack = get and select(8, get(item))
  if stack == nil then
    if ns.RequestItemData then ns.RequestItemData(item) end -- not cached yet: shown on the next refresh
    return nil
  end
  return stack > 1
end

-- Crafts per day of a cooldown recipe: from its length seen in game; nil until seen.
function ns.CooldownCraftsPerDay(spell)
  local len = ComradeCraftDB and ComradeCraftDB.cooldownLength and ComradeCraftDB.cooldownLength[spell]
  return len and len > 0 and 86400 / len or nil
end

-- One recipe as a money maker: { spell, item, cost, net (per craft, after the AH cut and the
-- expected deposit loss), perDay, daily, stackable, subs = { { item, spell, known } } } or nil.
function ns.CraftEconomics(spell, can, mine, memo)
  local r = ns.Recipes[spell]
  if not (r and r[5] and r[5] ~= 0 and ns.PriceSource) or (ns.IsBoP and ns.IsBoP(r[5])) then return nil end
  local price = ns.PriceSource(r[5])
  if not price then return nil end
  local cost = ns.RecipeMatsCost(spell, can, memo)
  if not cost then return nil end
  local q = math.max(1, r[6])
  local unit = price * 0.95 - ns.AuctionDeposit(r[5]) * ns.DEPOSIT_LOSS
  local e = { spell = spell, item = r[5], cost = cost, net = unit * q - cost, subs = {} }
  for i = 1, #r[7], 2 do
    local _, via = ns.UnitCost(r[7][i], can, memo)
    if via then e.subs[#e.subs + 1] = { item = r[7][i], spell = via, known = mine[via] or false } end
  end
  e.perDay = ns.SalesPerDay(r[5])
  local crafts = e.perDay and math.min(e.perDay * ns.GOLD_SHARE / q, ns.GOLD_BATCH) or nil
  e.cooldown = ns.IsCooldownRecipe and ns.IsCooldownRecipe(spell) or nil
  if e.cooldown then -- one craft per cooldown, whatever the market takes
    local cd = ns.CooldownCraftsPerDay(spell)
    crafts = cd and (crafts and math.min(crafts, cd) or cd) or nil
  end
  e.daily = crafts and e.net * crafts or nil
  e.stackable = Stackable(r[5])
  return e
end

local function Better(a, b)
  if (a.daily ~= nil) ~= (b.daily ~= nil) then return a.daily ~= nil end -- known volume first
  if a.daily and a.daily ~= b.daily then return a.daily > b.daily end
  return a.net > b.net
end

-- Best repeatable crafts of one profession: known recipes (or, for a profession the character
-- does not have, what a trainer, merchant or the AH teaches: `whatIf`), net > 0, best first.
-- Sub-components can be crafted with any recipe the character knows, or would learn.
-- cooldowns = true: only recipes with a cooldown (transmutes, Mooncloth); else only the others.
function ns.Goldmakers(c, line, whatIf, cooldowns)
  local known, can, mine = {}, {}, {}
  for _, set in pairs(c and c.known or {}) do for s in pairs(set) do can[s], mine[s] = true, true end end
  if whatIf then
    -- known[spell] = required skill (what the trainer, merchant or AH lists say)
    for _, list in ipairs({ ns.TrainerRecipes(line, ns.MAX_SKILL, {}), ns.VendorRecipes(line, ns.MAX_SKILL, {}, c),
      ns.AuctionRecipes(line, ns.MAX_SKILL, {}) }) do
      for s, req in pairs(list) do if known[s] == nil then known[s] = req end end
    end
  else
    for s in pairs(c and c.known and c.known[line] or {}) do known[s] = true end
  end
  for s in pairs(known) do can[s] = true end
  local memo, out = {}, {}
  for spell in pairs(known) do
    local e = ns.Recipes[spell] and ns.Recipes[spell][1] == line and ns.CraftEconomics(spell, can, mine, memo)
    if e and e.net > 0 and (e.cooldown or false) == (cooldowns or false) then
      if whatIf then e.req = type(known[spell]) == "number" and known[spell] or nil end
      out[#out + 1] = e
    end
  end
  table.sort(out, Better)
  while #out > ns.GOLD_TOP do out[#out] = nil end
  return out
end

-- Unlearned recipes of a profession the character has, bought from a merchant or the AH, whose
-- crafts make money: each with its price and payback (crafts to earn it back), best first.
function ns.ProfitableRecipes(c, line, rank)
  local can, mine, known = {}, {}, c and c.known and c.known[line] or {}
  for _, set in pairs(c and c.known or {}) do for s in pairs(set) do can[s], mine[s] = true, true end end
  local cands = {}
  for s, req in pairs(ns.VendorRecipes(line, ns.MAX_SKILL, known, c)) do cands[s] = req end
  for s, req in pairs(ns.AuctionRecipes(line, ns.MAX_SKILL, known)) do cands[s] = cands[s] or req end
  for s in pairs(cands) do can[s] = true end
  local memo, out = {}, {}
  for spell, req in pairs(cands) do
    local price = ns.RecipeLearnCost and ns.RecipeLearnCost(spell)
    local e = price and price > 0 and ns.CraftEconomics(spell, can, mine, memo)
    if e and e.net > 0 then
      e.price, e.req, e.canLearn = price, req, (rank or 0) >= (req or 0)
      e.payback = math.ceil(price / e.net)
      out[#out + 1] = e
    end
  end
  table.sort(out, function(a, b)
    if a.canLearn ~= b.canLearn then return a.canLearn end
    return Better(a, b)
  end)
  while #out > ns.GOLD_TOP do out[#out] = nil end
  return out
end

local function AllKnown(c)
  local can = {}
  for _, set in pairs(c and c.known or {}) do for s in pairs(set) do can[s] = true end end
  return can
end

-- No-risk crafts: mats cost less than what a merchant pays for the product (no AH cut, no
-- deposit, no market limit). Works without AH prices (merchant mats only then). Best first.
function ns.VendorShuffles(c, line)
  local can, memo, out = AllKnown(c), {}, {}
  for spell in pairs(c and c.known and c.known[line] or {}) do
    local r = ns.Recipes[spell]
    local p = r and r[5] ~= 0 and ns.ItemPrices and ns.ItemPrices[r[5]]
    if p and p[1] > 0 and not (ns.IsCooldownRecipe and ns.IsCooldownRecipe(spell)) then
      local cost = ns.RecipeMatsCost(spell, can, memo)
      local back = p[1] * math.max(1, r[6])
      if cost and back > cost then
        local e = { spell = spell, item = r[5], cost = cost, net = back - cost, vendor = true, subs = {} }
        for i = 1, #r[7], 2 do
          local _, via = ns.UnitCost(r[7][i], can, memo)
          if via then e.subs[#e.subs + 1] = { item = r[7][i], spell = via, known = true } end
        end
        out[#out + 1] = e
      end
    end
  end
  table.sort(out, function(a, b) return a.net > b.net end)
  while #out > ns.GOLD_TOP do out[#out] = nil end
  return out
end

-- Raw mats to buy for `crafts` crafts of a recipe (sub-components crafted when cheaper), minus
-- what the group already holds (ns.GroupStock); merchant mats left out. { { item, n } }, biggest first.
function ns.RestockItems(c, spell, crafts)
  local can, memo, raw = AllKnown(c), {}, {}
  local function Walk(sp, mult, depth)
    local r = ns.Recipes[sp]
    for i = 1, #r[7], 2 do
      local item, n = r[7][i], r[7][i + 1] * mult
      local _, via = ns.UnitCost(item, can, memo)
      if via and depth < 4 then Walk(via, n / math.max(1, ns.Recipes[via][6]), depth + 1)
      else raw[item] = (raw[item] or 0) + n end
    end
  end
  if not ns.Recipes[spell] then return {} end
  Walk(spell, crafts, 0)
  local stock = ns.GroupStock and ns.GroupStock(c) or {}
  local out = {}
  for item, n in pairs(raw) do
    local miss = math.ceil(n - 1e-9) - (stock[item] or 0)
    if miss > 0 and not ns.IsVendorItem(item) then out[#out + 1] = { item = item, n = miss } end
  end
  table.sort(out, function(a, b) return a.n ~= b.n and a.n > b.n or a.item < b.item end)
  return out
end

-- Crafts per click of the Queue and Restock buttons: 20 for a stackable product, else 5.
function ns.GoldBatch(e)
  return e.stackable and 20 or 5
end

-- Queue button: the craft goes to the Wishlist; the step panel's Orders mode (beside the
-- profession window) then crafts the sub-components first, one click per batch.
function ns.QueueGoldCraft(e)
  if not (ns.Wishlist and ns.Wishlist.Add) then return end
  local n = ns.GoldBatch(e)
  ns.Wishlist.Add(e.spell, n)
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  ComradeCraftDB.settings.trackerMode = "orders"
  if ns.RefreshTracker then ns.RefreshTracker() end
  ns.Print(ns.L["Queued %dx %s: open the profession window and click Craft next."]:format(n, ns.SpellName(e.spell)))
end

-- Restock button: what is missing for a batch, as a shopping list (Auctionator, TSM, or chat).
function ns.RestockGoldCraft(key, e)
  local c = ns.AllChars()[key]
  if not c then return end
  local items = ns.RestockItems(c, e.spell, ns.GoldBatch(e))
  if #items == 0 then
    ns.Print(ns.L["Nothing to buy."])
    return
  end
  ns.ShopItems(ns.L["Restock: %s"]:format(ns.SpellName(e.spell)), items)
end
