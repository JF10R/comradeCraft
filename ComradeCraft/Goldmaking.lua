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
  if stack == nil then return nil end
  return stack > 1
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
function ns.Goldmakers(c, line, whatIf)
  local known, can, mine = {}, {}, {}
  for _, set in pairs(c and c.known or {}) do for s in pairs(set) do can[s], mine[s] = true, true end end
  if whatIf then
    for s in pairs(ns.TrainerRecipes(line, ns.MAX_SKILL, {})) do known[s] = true end
    for s in pairs(ns.VendorRecipes(line, ns.MAX_SKILL, {}, c)) do known[s] = true end
  else
    for s in pairs(c and c.known and c.known[line] or {}) do known[s] = true end
  end
  for s in pairs(known) do can[s] = true end
  local memo, out = {}, {}
  for spell in pairs(known) do
    local e = ns.Recipes[spell] and ns.Recipes[spell][1] == line and ns.CraftEconomics(spell, can, mine, memo)
    if e and e.net > 0 then
      if whatIf then
        local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
        e.req = ns.RequiredSkill(spell, lib and lib.GetRequiredSkill and lib:GetRequiredSkill(line, spell))
      end
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
