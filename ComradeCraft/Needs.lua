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
  -- Disenchant value of an item (AH value of its expected mats): TSM "Destroy" source,
  -- else Auctionator's. Used over our own yield table when present.
  ns.DisenchantPrice = nil
  if TSM_API and TSM_API.GetCustomPriceValue then
    local get = TSM_API.GetCustomPriceValue
    ns.DisenchantPrice = function(item)
      local ok, v = pcall(get, "Destroy", "i:" .. item)
      return ok and v and v > 0 and v or nil
    end
  elseif Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetDisenchantPriceByItemID then
    local get = Auctionator.API.v1.GetDisenchantPriceByItemID
    ns.DisenchantPrice = function(item)
      local ok, v = pcall(get, "ComradeCraft", item)
      return ok and v and v > 0 and v or nil
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

-- AH deposit, per item: measured when you post (Shopping.lua), else merchant price x ratio.
-- DEPOSIT_LOSS: share counted as lost; WoW refunds it on sale (unconfirmed on Forever).
ns.DEPOSIT_LOSS = 0.5 -- half of the auctions expire once
-- Forever, 2 h auctions: Lesser (merchant 1s10) and Greater Magic Wand (2s) both cost 1s
-- each, so a flat minimum; the % above it is Retail's 12 h rule, unconfirmed.
ns.DEPOSIT_MIN, ns.DEPOSIT_RATIO = 100, 0.15
ns.AH_MARGIN = 1.1 -- the AH must beat the merchant/disenchant by 10% (time, competition)

function ns.AuctionDeposit(item)
  local db = ComradeCraftDB
  local d = db and db.deposits and db.deposits[item]
  if d then return d end
  local p = ns.ItemPrices and ns.ItemPrices[item]
  local sell = p and p[1]
  if not sell then
    local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    sell = get and select(11, get(item))
  end
  return math.max(ns.DEPOSIT_MIN, math.floor((sell or 0) * ns.DEPOSIT_RATIO))
end

-- What one crafted item brings back, three ways: merchant sell price, disenchant (AH value
-- of its mats; nil if unknown), auction house (price - 5% cut - expected deposit loss; nil
-- without a price source). deposit = the full deposit, for display.
function ns.ResaleOptions(item)
  if not item or item == 0 then return { vendor = 0 } end
  local p = ns.ItemPrices and ns.ItemPrices[item]
  local ah = ns.PriceSource and ns.PriceSource(item)
  local de = ns.DisenchantPrice and ns.DisenchantPrice(item)
  if not de and ns.DisenchantEstimate then de = ns.DisenchantEstimate(item) end
  local o = { vendor = p and p[1] or 0, de = de }
  if ah and ah > 0 then
    o.deposit = ns.AuctionDeposit(item)
    o.ah = ah * 0.95 - o.deposit * ns.DEPOSIT_LOSS
  end
  return o
end

-- The best way to sell (o = ResaleOptions, values may be scaled): the AH only when it beats
-- the merchant and the disenchant by AH_MARGIN.
function ns.BestResale(o)
  local other = math.max(o.vendor or 0, o.de or 0)
  if o.ah and o.ah > other * ns.AH_MARGIN then return o.ah end
  return other
end

-- What the "profitable" route counts on.
function ns.ResaleValue(item)
  return ns.BestResale(ns.ResaleOptions(item))
end

-- Route types: "cheap" = least spent on mats; "profit" = least spent once the products are
-- sold back (mats - resale), so recipes whose products sell well win.
ns.ROUTES = { "cheap", "profit" }
ns.MILESTONE = 75 -- cost comparison per bracket of 75 points (1-75, 75-150, ...)
ns.PROFIT_SPEED = 0.5 -- profit route: only recipes at least this fraction as fast as the best

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
function ns.ComputeNeeds(rank, target, known, allKnown, owned, learnable, mode)
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
    a.mats = Total(a.raw)
    local q = math.max(1, r[6])
    local o = ns.ResaleOptions(r[5])
    a.back = { vendor = o.vendor * q, de = o.de and o.de * q, ah = o.ah and o.ah * q }
    a.resale = ns.BestResale(a.back)
    a.cost = mode == "profit" and (a.mats - a.resale) or a.mats
    actions[#actions + 1] = a
  end
  for spell in pairs(known) do AddAction(spell) end
  for spell, req in pairs(learnable or {}) do
    if not known[spell] then AddAction(spell, req) end
  end

  local acc, plan = {}, {}
  -- milestones[start] = { mats, points, vendor, de, ah, deMissing, ahMissing }: expected copper
  -- per bracket of the route; *Missing = some products had no such value (sum is partial).
  local info = { used = {}, milestones = {} }
  local cur = rank
  while cur < target do
    local best, bestCost, bestN, topGain = nil, nil, nil, 0
    local gains = {}
    for i, a in ipairs(actions) do
      gains[i] = cur >= a.minRank and ActionGain(a, line, cur) or 0
      if gains[i] > topGain then topGain = gains[i] end
    end
    -- "profit" only keeps recipes at least half as fast as the fastest one: a slow recipe
    -- that sells well would otherwise win and multiply the crafts (and the mats).
    local floor = mode == "profit" and math.max(ns.MIN_GAIN, topGain * ns.PROFIT_SPEED) or ns.MIN_GAIN
    for i, a in ipairs(actions) do
      local gain = gains[i]
      if gain >= floor then
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
    local b = math.floor(cur / ns.MILESTONE) * ns.MILESTONE
    local m = info.milestones[b] or { mats = 0, points = 0, vendor = 0, de = 0, ah = 0, best = 0 }
    info.milestones[b] = m
    m.mats, m.points, m.best = m.mats + best.mats * bestN, m.points + 1, m.best + best.resale * bestN
    m.vendor = m.vendor + best.back.vendor * bestN
    for _, k in ipairs({ "de", "ah" }) do
      if best.back[k] then m[k] = m[k] + best.back[k] * bestN else m[k .. "Missing"] = true end
    end
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

-- Equipment slots an inventory type can go to (armor and jewelry; weapons not judged).
local SLOTS_OF = { INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 },
  INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
  INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
  INVTYPE_CLOAK = { 15 } }
local CLASS_ID = { WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5, SHAMAN = 7, MAGE = 8,
  WARLOCK = 9, DRUID = 11 }

-- Optional Pawn bridge (Pawn is CC BY-NC-ND: we call it at runtime, we never copy its weights).
-- Finds a Pawn scale for the character's class (and spec name when Pawn's name contains it).
-- Pawn's scale fields are not documented: every access is guarded, nil means "use item level".
local pawnScaleCache = {}
function ns.PawnScaleFor(c)
  if not (PawnCommon and type(PawnCommon.Scales) == "table" and c.class) then return nil end
  local cacheKey = c.class .. "/" .. tostring(c.spec)
  if pawnScaleCache[cacheKey] ~= nil then return pawnScaleCache[cacheKey] or nil end
  local classID, best = CLASS_ID[c.class], nil
  for name, scale in pairs(PawnCommon.Scales) do
    if type(scale) == "table" and scale.ClassID == classID then
      local label = tostring(scale.LocalizedName or name)
      if c.spec and label:find(c.spec, 1, true) then
        best = name
        break
      end
      best = best or name
    end
  end
  pawnScaleCache[cacheKey] = best or false
  if best and ns.Log then ns.Log(("pawn: %s -> %s"):format(cacheKey, best)) end
  return best
end

-- Value of an item for a character: Pawn's score for its class scale when available,
-- else the item level. Returns value, "pawn"|"ilvl".
function ns.ItemScore(item, c)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local _, link, _, ilvl = get(item)
  local scale = ns.PawnScaleFor(c)
  if scale and link and PawnGetItemData and PawnGetSingleValueFromItem then
    local ok, data = pcall(PawnGetItemData, link)
    if ok and data then
      local ok2, v = pcall(PawnGetSingleValueFromItem, data, scale)
      if ok2 and type(v) == "number" then return v, "pawn" end
    end
  end
  return ilvl or 0, "ilvl"
end

-- Is `item` an upgrade for character c? It must fit (ItemFits) and score above the weakest
-- piece worn in a slot it goes to (an empty slot counts as 0). Without equipment data, a
-- fitting item counts as an upgrade with unknown gain. Returns isUpgrade, gain, how.
function ns.UpgradeFor(item, c)
  if not ns.ItemFits(item, c) then return false end
  local f = ItemFacts(item)
  local slots = f and SLOTS_OF[f.equipLoc]
  if not (slots and c.equipped) then return true, nil, nil end
  local score, how = ns.ItemScore(item, c)
  local worst
  for _, slot in ipairs(slots) do
    local worn = c.equipped[slot]
    local s = worn and ns.ItemScore(worn, c) or 0
    if not worst or s < worst then worst = s end
  end
  if score > worst then return true, score - worst, how end
  return false
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
  local chars = ns.AllChars()
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
            if r[5] ~= 0 then
              local up, gain = ns.UpgradeFor(r[5], oc)
              if up then e.fits[#e.fits + 1] = { key = other, gain = gain } end
            end
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
-- lineOK (optional): function(skillLine) -> bool, to follow the profession filter.
function ns.GroupMaterials(lineOK)
  local acc = {}
  for key, c in pairs(ns.AllChars()) do
    for line, need in pairs(c.needs or {}) do
      for item, n in pairs((not lineOK or lineOK(line)) and need.items or {}) do
        local a = acc[item] or { item = item, total = 0, by = {} }
        acc[item] = a
        a.total = a.total + n
        local step = need.when and need.when[item]
        a.by[#a.by + 1] = { key = key, n = n, step = step }
        if step and (not a.step or step < a.step) then a.step = step end
      end
    end
  end
  local list = {}
  for _, a in pairs(acc) do
    table.sort(a.by, function(x, y) return (x.step or 99) < (y.step or 99) end)
    list[#list + 1] = a
  end
  -- Most urgent first (now, soon, later), then the biggest quantity.
  table.sort(list, function(a, b)
    local ua, ub = ns.UrgencyRank(a.step), ns.UrgencyRank(b.step)
    if ua ~= ub then return ua < ub end
    return a.total > b.total or (a.total == b.total and a.item < b.item)
  end)
  return list
end

-- What a character can give away: owned (bags + bank) minus what its own plans use.
function ns.Surplus(c, item)
  local owned = ((c.bags or {})[item] or 0) + ((c.bank or {})[item] or 0)
  if owned == 0 then return 0 end
  local used = 0
  for _, need in pairs(c.needs or {}) do used = used + ((need.gross or {})[item] or 0) end
  return math.max(0, owned - used)
end

-- Who in the group has spare `item`: total and { {key, n} } (largest first), `except` left out.
function ns.GroupSupply(item, except)
  local total, list = 0, {}
  for key, c in pairs(ns.AllChars()) do
    if key ~= except then
      local n = ns.Surplus(c, item)
      if n > 0 then
        total = total + n
        list[#list + 1] = { key = key, n = n }
      end
    end
  end
  table.sort(list, function(a, b) return a.n > b.n end)
  return total, list
end

-- What `key` can give: its spare items that other characters need, one entry per
-- (item, receiver): { item, to, n = min(spare left, need), step }. Most urgent first.
function ns.GiveList(key)
  local chars = ns.AllChars()
  local c = chars[key]
  local out = {}
  if not c then return out end
  local items = {}
  for _, src in ipairs({ c.bags or {}, c.bank or {} }) do
    for item in pairs(src) do items[item] = true end
  end
  for item in pairs(items) do
    local spare = ns.Surplus(c, item)
    if spare > 0 then
      local wants = {}
      for other, oc in pairs(chars) do
        if other ~= key then
          for _, r in ipairs(ns.NeedRows(oc, item)) do
            wants[#wants + 1] = { to = other, n = r.n, step = r.step }
          end
        end
      end
      table.sort(wants, function(a, b) return (a.step or 99) < (b.step or 99) end)
      for _, w in ipairs(wants) do
        if spare <= 0 then break end
        local n = math.min(spare, w.n)
        spare = spare - n
        out[#out + 1] = { item = item, to = w.to, n = n, step = w.step }
      end
    end
  end
  table.sort(out, function(a, b)
    local ua, ub = ns.UrgencyRank(a.step), ns.UrgencyRank(b.step)
    if ua ~= ub then return ua < ub end
    return a.n > b.n
  end)
  return out
end

-- When a material is needed, from the first plan step using it: step 1 = "now",
-- steps 2-4 = "soon", 5+ (or unknown) = "later". Locale keys.
function ns.Urgency(step)
  if step == 1 then return "now" end
  if step and step <= 4 then return "soon" end
  return "later"
end
function ns.UrgencyRank(step)
  return ({ now = 1, soon = 2, later = 3 })[ns.Urgency(step)]
end

-- [itemID] = index of the first plan step whose crafts (main recipe or intermediates) use it.
local function FirstStepOf(plan)
  local when = {}
  for i, step in ipairs(plan or {}) do
    local spells = { step.spell }
    for sub in pairs(step.subs or {}) do spells[#spells + 1] = sub end
    for _, spell in ipairs(spells) do
      local reag = ns.Recipes[spell] and ns.Recipes[spell][7] or {}
      for j = 1, #reag, 2 do
        if not when[reag[j]] then when[reag[j]] = i end
      end
    end
  end
  return when
end
ns.FirstStepOf = FirstStepOf

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

-- Route type of a character, chosen by its owner in the Plan tab and synced with its record,
-- so every viewer (tooltips, give list, mail, shopping) follows the same choice.
function ns.RouteMode(c)
  return c and c.route == "profit" and "profit" or "cheap"
end

-- Sets the route of one of this account's characters and recomputes it.
function ns.SetRouteMode(key, mode)
  local c = ComradeCraftDB.chars and ComradeCraftDB.chars[key]
  if not c then return end
  c.route = mode == "profit" and "profit" or nil
  c.updated = time() -- peers pick up the change with the next sync
  ns.UpdateNeeds(c)
  ns.RequestRefresh()
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
      local mode = ns.RouteMode(c)
      local other = mode == "profit" and "cheap" or "profit"
      local _, kReached, _, kInfo = ns.ComputeNeeds(p.rank, p.max, known, all, owned, nil, mode)
      local gross, reached, plan, info = ns.ComputeNeeds(p.rank, p.max, known, all, owned, learnable, mode)
      local _, oReached, _, oInfo = ns.ComputeNeeds(p.rank, p.max, known, all, owned, learnable, other)
      local net, vendor, have = {}, {}, {}
      for item, n in pairs(gross) do
        have[item] = owned[item] or 0
        if n > have[item] then
          if ns.IsVendorItem(item) then vendor[item] = n - have[item] else net[item] = n - have[item] end
        end
      end
      c.needs[p.skillLine] = { name = name, items = net, vendor = vendor, gross = gross, have = have,
        reached = reached, target = p.max, plan = plan, reason = info.reason,
        bestGain = info.bestGain, used = info.used, when = FirstStepOf(plan),
        knownOnly = { reached = kReached, reason = kInfo.reason },
        mode = mode, milestones = info.milestones,
        alt = { mode = other, reached = oReached, milestones = oInfo.milestones } }
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
    if n and n > 0 then
      rows[#rows + 1] = { prof = need.name, n = n, step = need.when and need.when[itemID] }
    end
  end
  return rows
end
