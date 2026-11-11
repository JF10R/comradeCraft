-- Needs: expected reagents to take a profession from its rank to its cap, using known recipes.
-- Pure logic over ns.Recipes; no WoW API calls so it is testable offline.
local _, ns = ...

-- Classic formula: orange 1, yellow/green (grey-rank)/(grey-yellow), grey 0. Unverified on Forever.
function ns.FormulaChance(spell, rank)
  local r = ns.Recipes[spell]
  if not r then return 0 end
  local yellow, grey = r[2], r[3]
  if rank >= grey then return 0 end
  if rank < yellow then return 1 end
  return (grey - rank) / (grey - yellow)
end

-- Formula scaled by the measured factor of the recipe's color (SkillLog), capped at 1.
function ns.SkillUpChance(spell, rank)
  local p = ns.FormulaChance(spell, rank)
  local f = p > 0 and ns.Calibration and ns.Calibration(ns.RecipeColor(spell, rank))
  return f and math.min(1, p * f) or p
end

-- An "action" is one craft of a recipe plus every intermediate the character makes
-- himself (Bolt of Linen for a vest, Copper Bar via smelting). Expands recursively.
-- Returns raw { [itemID] = count } and subs { [spellID] = crafts } per action.
local function Expand(spell, producers, depth, raw, subs, mult)
  local reag = ns.Recipes[spell][7]
  for i = 1, #reag, 2 do
    local item, count = reag[i], reag[i + 1] * mult
    local sub = producers[item]
    if sub and sub ~= spell and depth < 4 then
      local crafts = count / math.max(1, ns.Recipes[sub][6])
      subs[sub] = (subs[sub] or 0) + crafts
      Expand(sub, producers, depth + 1, raw, subs, crafts)
    else
      raw[item] = (raw[item] or 0) + count
    end
  end
end

-- Auction prices from TSM (DBMarket) or Auctionator, when one is loaded. Sets
-- ns.PriceSource(itemID) -> copper|nil and ns.PriceSourceName.
function ns.DetectPriceSource()
  if TSM_API and TSM_API.GetCustomPriceValue then
    ns.PriceSourceName = "TSM"
    ns.PriceSource = function(item)
      local ok, v = pcall(TSM_API.GetCustomPriceValue, "DBMarket", "i:" .. item)
      return ok and v or nil
    end
  elseif Auctionator and Auctionator.API and Auctionator.API.v1
    and Auctionator.API.v1.GetAuctionPriceByItemID then
    ns.PriceSourceName = "Auctionator"
    ns.PriceSource = function(item)
      local ok, v = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, "ComradeCraft", item)
      return ok and v or nil
    end
  end
end
ns.On("PLAYER_LOGIN", function()
  ns.DetectPriceSource()
  ns.RequestRefresh()
end)

-- Cost of buying `n` of an item, in copper, or nil when no real price is known:
-- AH price, or the merchant buy price for vendor reagents. Never the sell-price proxy.
function ns.BuyCost(item, n)
  if ns.IsVendorItem(item) then
    local p = ns.ItemPrices and ns.ItemPrices[item]
    if p and p[2] > 0 then return p[2] * n end
  end
  local v = ns.PriceSource and ns.PriceSource(item)
  return v and v > 0 and v * n or nil
end

-- Value of one item in copper: AH price if a source is plugged in (ns.PriceSource),
-- else the merchant price (buy price for vendor reagents, sell price otherwise). Min 1.
function ns.ItemValue(item)
  local v = ns.PriceSource and ns.PriceSource(item)
  if v and v > 0 then return v end
  local p = ns.ItemPrices and ns.ItemPrices[item]
  if p then
    v = (ns.IsVendorItem(item) and p[2] > 0) and p[2] or p[1]
  end
  return math.max(1, v or 1)
end

local function Total(reag)
  local n = 0
  for item, c in pairs(reag) do n = n + c * ns.ItemValue(item) end
  return n
end

-- Expected skill points of one action at a rank. Only crafts of this profession's
-- skill line count; a smelted bar levels Mining, not Blacksmithing.
local function ActionGain(a, line, rank)
  local r = ns.Recipes[a.spell]
  local g = ns.SkillUpChance(a.spell, rank) * math.max(1, r[4])
  for sub, crafts in pairs(a.subs) do
    local s = ns.Recipes[sub]
    if s[1] == line then g = g + crafts * ns.SkillUpChance(sub, rank) * math.max(1, s[4]) end
  end
  return g
end

-- known: recipes of this profession { [spellID] = true }. allKnown (optional): every
-- recipe the character knows, any profession, used to expand intermediates.
-- Below this many expected points per craft, a recipe is not worth grinding: the
-- route stops and tells the player to learn a new recipe (0.25 = 1 point per 4 crafts).
ns.MIN_GAIN = 0.25

-- owned (optional): { [itemID] = count } the character has; owned intermediates
-- (e.g. 27 Bolts of Woolen Cloth) replace the raw mats that would have made them.
-- Returns needs { [itemID] = count }, the rank reached, the plan
-- { { spell, from, to, crafts, subs = { [spellID] = crafts } } } (expected values), and
-- info { reason = nil | "grey" | "lowgain", bestGain, used = { [itemID] = count } }.
-- learnable (optional): { [spellID] = requiredSkill } recipes not known yet but buyable at
-- a trainer; each becomes an option from its required skill on (plan steps get .learn = true).
function ns.ComputeNeeds(rank, target, known, allKnown, owned, learnable)
  -- A recipe makes an intermediate only when its mats are worth no more than the item
  -- (Bolt of Woolen Cloth 100c <= 3 Wool 99c: craft it; Light Leather 15c < 3 Ruined
  -- Leather Scraps 21c: gather or buy it instead). Values: ns.ItemValue.
  local producers = {}
  local function AddProducers(set)
    for spell in pairs(set) do
      local r = ns.Recipes[spell]
      if r and r[5] ~= 0 and not producers[r[5]] then
        local mats = 0
        for i = 1, #r[7], 2 do mats = mats + r[7][i + 1] * ns.ItemValue(r[7][i]) end
        if mats / math.max(1, r[6]) <= ns.ItemValue(r[5]) then producers[r[5]] = spell end
      end
    end
  end
  AddProducers(allKnown or known)
  -- Learnable recipes can make intermediates too (Bolt of Silk Cloth), but only for items
  -- no known recipe makes; an action using one is available from its required skill on.
  AddProducers(learnable or {})
  local line
  local actions = {}
  local function AddAction(spell, minRank)
    local r = ns.Recipes[spell]
    if not r then return end
    line = line or r[1]
    local a = { spell = spell, raw = {}, subs = {}, minRank = minRank or 0, learn = minRank ~= nil }
    Expand(spell, producers, 0, a.raw, a.subs, 1)
    for sub in pairs(a.subs) do
      local req = learnable and learnable[sub]
      if req and not (allKnown or known)[sub] then a.minRank = math.max(a.minRank, req) end
    end
    a.cost = Total(a.raw)
    actions[#actions + 1] = a
  end
  for spell in pairs(known) do AddAction(spell) end
  for spell, req in pairs(learnable or {}) do
    if not known[spell] then AddAction(spell, req) end
  end

  local acc, plan = {}, {}
  local info = { used = {} }
  local cur = rank
  while cur < target do
    local best, bestCost, bestN, topGain = nil, nil, nil, 0
    for _, a in ipairs(actions) do
      local gain = cur >= a.minRank and ActionGain(a, line, cur) or 0
      if gain > topGain then topGain = gain end
      if gain >= ns.MIN_GAIN then
        local n = 1 / gain -- actions for one expected point
        local cost = a.cost * n
        if not best or cost < bestCost or (cost == bestCost and a.spell < best.spell) then
          best, bestCost, bestN = a, cost, n
        end
      end
    end
    if not best then
      info.reason = topGain > 0 and "lowgain" or "grey"
      info.bestGain = topGain
      break
    end
    for item, c in pairs(best.raw) do acc[item] = (acc[item] or 0) + c * bestN end
    local last = plan[#plan]
    if not (last and last.spell == best.spell) then
      last = { spell = best.spell, from = cur, crafts = 0, subs = {},
        learn = best.learn or nil, req = best.learn and best.minRank or nil }
      plan[#plan + 1] = last
    end
    last.to, last.crafts = cur + 1, last.crafts + bestN
    for sub, crafts in pairs(best.subs) do last.subs[sub] = (last.subs[sub] or 0) + crafts * bestN end
    cur = cur + 1
  end

  -- Owned intermediates: each one used removes the raw mats of its own craft.
  if owned then
    local inter = {}
    for _, step in ipairs(plan) do
      for sub, crafts in pairs(step.subs) do
        local s = ns.Recipes[sub]
        inter[s[5]] = (inter[s[5]] or 0) + crafts * math.max(1, s[6])
      end
    end
    for item, n in pairs(inter) do
      local use = math.min(owned[item] or 0, math.floor(n + 1e-9))
      if use > 0 then
        info.used[item] = use
        local raw, subs = {}, {}
        local sub = producers[item]
        Expand(sub, producers, 1, raw, subs, use / math.max(1, ns.Recipes[sub][6]))
        for r, c in pairs(raw) do acc[r] = math.max(0, (acc[r] or 0) - c) end
      end
    end
  end

  local needs = {}
  for item, c in pairs(acc) do
    local n = math.ceil(c - 1e-9)
    if n > 0 then needs[item] = n end
  end
  return needs, cur, plan, info
end

-- Reagents sold by vendors (checked against ItemSparse names, build 1.60.1.70888), plus
-- whatever the addon has seen on merchants (ComradeCraftDB.vendorSeen). Not group needs.
ns.VENDOR_ITEMS = {
  [2320] = true, [2321] = true, [4291] = true, [8343] = true, [14341] = true, -- threads
  [4340] = true, [6260] = true, [2604] = true, [4341] = true, [2605] = true, -- dyes
  [2325] = true, [6261] = true, [4342] = true, [10290] = true, [2324] = true, -- dyes, bleach
  [2678] = true, [2692] = true, [3713] = true, [159] = true, [1179] = true,   -- cooking
  [3371] = true, [3372] = true, [8925] = true, [18256] = true,                -- vials
  [2880] = true, [3466] = true, [3857] = true, [4289] = true, [4470] = true,  -- flux, coal, salt, wood
  [6217] = true, [814] = true, [4399] = true, [4400] = true,                  -- rod, oil, stocks
  [2928] = true, [2930] = true, [8923] = true, [8924] = true, [5173] = true,  -- poison reagents
}

function ns.IsVendorItem(id)
  return ns.VENDOR_ITEMS[id] or (ComradeCraftDB and ComradeCraftDB.vendorSeen
    and ComradeCraftDB.vendorSeen[id]) or false
end

-- Item info fields used by the catalog (nil until the client has the item cached).
local function ItemFacts(item)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not (get and item and item ~= 0) then return nil end
  local name, _, _, _, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID = get(item)
  if not name then return nil end
  return { name = name, reqLevel = reqLevel or 0, equipLoc = equipLoc or "", classID = classID,
    subclassID = subclassID }
end

-- Main armor type of a class at a level: 1 cloth, 2 leather, 3 mail, 4 plate.
local ARMOR = { MAGE = 1, PRIEST = 1, WARLOCK = 1, DRUID = 2, ROGUE = 2 }
local function MainArmor(class, level)
  if ARMOR[class] then return ARMOR[class] end
  local high = (level or 0) >= 40
  if class == "HUNTER" or class == "SHAMAN" then return high and 3 or 2 end
  if class == "WARRIOR" or class == "PALADIN" then return high and 4 or 3 end
  return nil
end

-- Does a crafted item suit a character: its main armor type (cloaks, necks, rings and
-- trinkets suit everyone), required level between level-10 and level. Weapons: not judged.
function ns.ItemFits(item, c)
  local f = ItemFacts(item)
  if not (f and c.level and f.classID == 4 and f.equipLoc ~= "") then return false end
  if f.reqLevel > c.level or f.reqLevel < c.level - 10 then return false end
  local anyone = f.subclassID == 0 or f.equipLoc == "INVTYPE_CLOAK"
  return anyone or f.subclassID == MainArmor(c.class, c.level)
end

-- Category label key of a recipe's product (Locale keys).
function ns.ItemCategory(item)
  if not item or item == 0 then return "Enchant" end
  local f = ItemFacts(item)
  if not f then return "Other" end
  return ({ [0] = "Consumable", [1] = "Bag", [2] = "Weapon", [4] = "Armor", [7] = "Reagent" })[f.classID]
    or "Other"
end

-- Recipes a character knows, annotated for the "can craft" view:
-- { spell, line, item, color, category, needers = { {key, n} }, fits = { key } }.
-- Sorted: helps someone first, then fits someone, then by name.
function ns.CraftCatalog(key)
  local chars = ComradeCraftDB.chars
  local c = chars[key]
  local rankOf = {}
  for _, p in pairs(c.professions or {}) do
    if p.skillLine then rankOf[p.skillLine] = p.rank end
  end
  local out = {}
  for line, set in pairs(c.known or {}) do
    for spell in pairs(set) do
      local r = ns.Recipes[spell]
      if r then
        local e = { spell = spell, line = line, item = r[5], needers = {}, fits = {},
          color = rankOf[line] and ns.RecipeColor(spell, rankOf[line]) or "grey",
          category = ns.ItemCategory(r[5]) }
        for other, oc in pairs(chars) do
          if other ~= key then
            local n = r[5] ~= 0 and ns.NeedOf(oc, r[5]) or 0
            if n > 0 then e.needers[#e.needers + 1] = { key = other, n = n } end
            if r[5] ~= 0 and ns.ItemFits(r[5], oc) then e.fits[#e.fits + 1] = other end
          end
        end
        e.name = ns.SpellName and ns.SpellName(spell) or tostring(spell)
        out[#out + 1] = e
      end
    end
  end
  table.sort(out, function(a, b)
    local ra = #a.needers > 0 and 1 or #a.fits > 0 and 2 or 3
    local rb = #b.needers > 0 and 1 or #b.fits > 0 and 2 or 3
    if ra ~= rb then return ra < rb end
    return a.name < b.name
  end)
  return out
end

-- Group-wide missing materials: { { item, total, by = { {key, n} } } }, most needed first.
function ns.GroupMaterials()
  local acc = {}
  for key, c in pairs(ComradeCraftDB.chars) do
    for _, need in pairs(c.needs or {}) do
      for item, n in pairs(need.items or {}) do
        local a = acc[item] or { item = item, total = 0, by = {} }
        acc[item] = a
        a.total = a.total + n
        a.by[#a.by + 1] = { key = key, n = n }
      end
    end
  end
  local list = {}
  for _, a in pairs(acc) do list[#list + 1] = a end
  table.sort(list, function(a, b) return a.total > b.total or (a.total == b.total and a.item < b.item) end)
  return list
end

-- Gathering professions level by gathering, not crafting: no needs computed.
ns.GATHERING = { [356] = "Fishing", [182] = "Herbalism", [393] = "Skinning", [186] = "Mining" }

-- What a trainer window showed for a recipe ({ cost, req, t }), recorded by Scan.lua.
function ns.TrainerSeen(spell)
  return ComradeCraftDB and ComradeCraftDB.trainer and ComradeCraftDB.trainer[spell]
end

-- Trainer recipes of a skill line not known yet: { [spellID] = requiredSkill } up to maxRank.
-- Recipes seen at a real trainer win over LibProfessionDB (whose values are partly Classic's).
function ns.TrainerRecipes(line, maxRank, known)
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  local all = lib and lib.GetRecipes and lib:GetRecipes(line)
  local out = {}
  for spell, e in pairs(all or {}) do
    local req = e.requiredSkill
    if req and not known[spell] and ns.Recipes[spell]
      and not (lib.IsHiddenRecipe and lib:IsHiddenRecipe(spell)) then
      local kinds = lib.GetRecipeSourceKinds and lib:GetRecipeSourceKinds(spell)
      if kinds and kinds.trainer then out[spell] = req end
    end
  end
  for spell, seen in pairs(ComradeCraftDB and ComradeCraftDB.trainer or {}) do
    local r = ns.Recipes[spell]
    if r and r[1] == line and not known[spell] and seen.req then out[spell] = seen.req end
  end
  for spell, req in pairs(out) do
    if req > maxRank then out[spell] = nil end
  end
  return out
end

-- Up to 3 recipes to learn next, from LibProfessionDB: not known, not hidden, with a
-- required skill, sorted learnable-now first (by grey rank, desc), then soonest.
function ns.NextRecipes(line, rank, known)
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  local all = lib and lib.GetRecipes and lib:GetRecipes(line)
  if not all then return {} end
  local now, soon = {}, {}
  for spell, e in pairs(all) do
    local req = e.requiredSkill
    local r = ns.Recipes[spell]
    local hidden = lib.IsHiddenRecipe and lib:IsHiddenRecipe(spell)
    if r and req and not known[spell] and not hidden and rank < r[3] then
      local kinds = lib.GetRecipeSourceKinds and lib:GetRecipeSourceKinds(spell) or {}
      local x = { spell = spell, req = req, grey = r[3], kinds = kinds,
        borrowed = lib.IsBorrowed and lib:IsBorrowed(spell, "requiredSkill") }
      if req <= rank then
        if ns.FormulaChance(spell, rank) >= 0.5 then now[#now + 1] = x end
      elseif req <= rank + 25 then
        soon[#soon + 1] = x
      end
    end
  end
  -- Reliable sources first: trainer, vendor, quest, then drops/containers.
  local function rank_(x)
    local k = x.kinds
    return k.trainer and 1 or k.vendor and 2 or k.quest and 3 or 4
  end
  table.sort(now, function(a, b)
    if rank_(a) ~= rank_(b) then return rank_(a) < rank_(b) end
    return a.grey > b.grey or (a.grey == b.grey and a.spell < b.spell)
  end)
  table.sort(soon, function(a, b)
    if rank_(a) ~= rank_(b) then return rank_(a) < rank_(b) end
    return a.req < b.req or (a.req == b.req and a.spell < b.spell)
  end)
  local out = {}
  for _, list in ipairs({ now, soon }) do
    for _, x in ipairs(list) do
      if #out < 3 then out[#out + 1] = x end
    end
  end
  return out
end

-- Recomputes c.needs[skillLine] for one character record (rank -> cap, minus owned).
function ns.UpdateNeeds(c)
  c.needs = {}
  if not (c.professions and c.known) then return end
  local all = {}
  for _, set in pairs(c.known) do
    for spell in pairs(set) do all[spell] = true end
  end
  local owned = {}
  for _, src in ipairs({ c.bags or {}, c.bank or {} }) do
    for item, n in pairs(src) do owned[item] = (owned[item] or 0) + n end
  end
  for name, p in pairs(c.professions) do
    local known = p.skillLine and c.known[p.skillLine]
    if known and p.rank and p.max and p.rank < p.max and not ns.GATHERING[p.skillLine] then
      -- Route "with what you know" (kept as a summary) and route "optimal" (also learns
      -- trainer recipes on the way, like leveling guides do). Needs follow the optimal one.
      local learnable = ns.TrainerRecipes(p.skillLine, p.max, known)
      local _, kReached, _, kInfo = ns.ComputeNeeds(p.rank, p.max, known, all, owned)
      local gross, reached, plan, info = ns.ComputeNeeds(p.rank, p.max, known, all, owned, learnable)
      local net, vendor, have = {}, {}, {}
      for item, n in pairs(gross) do
        have[item] = owned[item] or 0
        if n > have[item] then
          if ns.IsVendorItem(item) then vendor[item] = n - have[item] else net[item] = n - have[item] end
        end
      end
      c.needs[p.skillLine] = { name = name, items = net, vendor = vendor, gross = gross, have = have,
        reached = reached, target = p.max, plan = plan, reason = info.reason,
        bestGain = info.bestGain, used = info.used,
        knownOnly = { reached = kReached, reason = kInfo.reason } }
    end
  end
end

-- Total need of one item for a character, across professions.
function ns.NeedOf(c, itemID)
  local n = 0
  for _, need in pairs(c.needs or {}) do n = n + (need.items[itemID] or 0) end
  return n
end

-- Per-profession needs of one item: { { prof = name, n = count }, ... }.
function ns.NeedRows(c, itemID)
  local rows = {}
  for _, need in pairs(c.needs or {}) do
    local n = need.items[itemID]
    if n and n > 0 then rows[#rows + 1] = { prof = need.name, n = n } end
  end
  return rows
end
