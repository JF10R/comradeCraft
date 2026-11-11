-- Disenchant: records what each disenchant really yields on Forever (item level, quality,
-- armor/weapon -> mats), to replace the Classic yield table with measurements over time.
-- The source item is found by diffing the bags around the cast (no API names it reliably).
local _, ns = ...

local DISENCHANT = 13262
local MAX_RAW = 1000
local WINDOW = 15 -- seconds from the cast to the loot
local SELL_RATIO = 1.5 -- suggest selling when the AH value beats the disenchant value by this much

-- Expected yields by REQUIRED level (Forever is keyed that way; source: wow-professions.com
-- Forever disenchanting guide, cross-checked with warcraft.wiki.gg Disenchanting_tables).
-- Uncommon armor ~75% dust / 20% essence, weapons the reverse, plus a small shard chance;
-- rare = 1 shard; epic = shards (or a Nexus Crystal from level 51). Unverified on Forever:
-- the logged disenchants above are there to check it.
-- { maxReqLevel, dust, dustMin, dustMax, essence, essMin, essMax, shard, uncommonShardChance }
local BANDS = {
  { 10, 10940, 1, 2, 10938, 1, 2, 10978, 0 },
  { 15, 10940, 2, 3, 10939, 1, 2, 10978, 0.05 },
  { 20, 10940, 4, 6, 10998, 1, 2, 10978, 0.10 },
  { 25, 11083, 1, 2, 11082, 1, 2, 11084, 0.05 },
  { 30, 11083, 2, 5, 11134, 1, 2, 11138, 0.05 },
  { 35, 11137, 1, 2, 11135, 1, 2, 11139, 0.05 },
  { 40, 11137, 2, 5, 11174, 1, 2, 11177, 0.05 },
  { 45, 11176, 1, 2, 11175, 1, 2, 11178, 0.05 },
  { 50, 11176, 2, 5, 16202, 1, 2, 14343, 0.05 },
  { 55, 16204, 1, 2, 16203, 1, 2, 14344, 0.05 },
  { 60, 16204, 2, 5, 16203, 1, 3, 14344, 0.05 },
}
local NEXUS = 20725
ns.ENCHANTING = 333

-- Facts needed to judge an item; nil until the client has it cached.
local function Facts(item)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, _, quality, _, reqLevel, _, _, _, equipLoc, _, sellPrice, classID = get(item)
  if not name then return nil end
  return { name = name, quality = quality or 0, reqLevel = reqLevel or 0, equipLoc = equipLoc or "",
    sellPrice = sellPrice or 0, classID = classID }
end

-- Expected mats of one disenchant: { [itemID] = expected count }, or nil if not disenchantable.
function ns.DisenchantYield(item)
  local f = Facts(item)
  if not (f and (f.classID == 2 or f.classID == 4) and f.quality >= 2 and f.quality <= 4) then return nil end
  local band = BANDS[#BANDS]
  for _, b in ipairs(BANDS) do
    if f.reqLevel <= b[1] then
      band = b
      break
    end
  end
  local out = {}
  if f.quality == 2 then
    local weapon = f.classID == 2
    local pDust, pEss = weapon and 0.20 or 0.75, weapon and 0.75 or 0.20
    out[band[2]] = pDust * (band[3] + band[4]) / 2
    out[band[5]] = pEss * (band[6] + band[7]) / 2
    if band[9] > 0 then out[band[8]] = band[9] end
  elseif f.quality == 3 then
    out[band[8]] = 1
  else
    if band[1] > 50 then out[NEXUS] = 1 else out[band[8]] = 3 end
  end
  return out
end

-- Inventory type number of an item (9 = wrist, 5 = chest, ...), for enchant targets.
local INVTYPE = { INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4, INVTYPE_CHEST = 5,
  INVTYPE_WAIST = 6, INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10, INVTYPE_FINGER = 11,
  INVTYPE_TRINKET = 12, INVTYPE_WEAPON = 13, INVTYPE_SHIELD = 14, INVTYPE_RANGED = 15, INVTYPE_CLOAK = 16,
  INVTYPE_2HWEAPON = 17, INVTYPE_ROBE = 20, INVTYPE_WEAPONMAINHAND = 21, INVTYPE_WEAPONOFFHAND = 22,
  INVTYPE_HOLDABLE = 23, INVTYPE_THROWN = 25, INVTYPE_RANGEDRIGHT = 26 }

local function Bit(mask, n) return math.floor(mask / 2 ^ n) % 2 == 1 end

-- Advice for each disenchantable item in a character's bags:
-- { item, verdict = "target"|"gear"|"sell"|"disenchant", to = key, yield = {..}, useful = bool,
--   enchanter = key }. A recipe can be cast on the same item again and again, so ONE item per
-- slot the remaining enchanting plan needs is kept, the cheapest.
function ns.BagAdvice(key)
  local chars = ns.AllChars()
  local c = chars[key]
  if not c then return {} end
  local out, candidates = {}, {}
  for item in pairs(c.bags or {}) do
    local y = ns.DisenchantYield(item)
    if y then candidates[#candidates + 1] = { item = item, yield = y, facts = Facts(item) } end
  end
  table.sort(candidates, function(a, b) return a.facts.sellPrice < b.facts.sellPrice end)

  -- Slots the enchanting plan still targets: { { class, mask } }.
  local slots = {}
  local need = c.needs and c.needs[ns.ENCHANTING]
  for _, step in ipairs(need and need.plan or {}) do
    local s = ns.EnchantSlots and ns.EnchantSlots[step.spell]
    if s then slots[#slots + 1] = { class = s[1], mask = s[2], spell = step.spell } end
  end

  -- An enchanter in the group, for characters without Enchanting.
  local enchanter
  for k, oc in pairs(chars) do
    for _, p in pairs(oc.professions or {}) do
      if p.skillLine == ns.ENCHANTING and (k == key or not enchanter) then enchanter = k end
    end
  end

  local function DisenchantValue(y)
    local v, ok = 0, true
    for mat, n in pairs(y) do
      local cost = ns.BuyCost(mat, n)
      if cost then v = v + cost else ok = false end
    end
    return ok and v or nil
  end

  for _, cand in ipairs(candidates) do
    local item, f = cand.item, cand.facts
    local entry = { item = item, yield = cand.yield }
    local inv = INVTYPE[f.equipLoc]
    for i, s in ipairs(slots) do
      if inv and f.classID == s.class and Bit(s.mask, inv) then
        entry.verdict, entry.spell = "target", s.spell
        table.remove(slots, i)
        break
      end
    end
    if not entry.verdict then
      for other, oc in pairs(chars) do
        if other ~= key and ns.UpgradeFor(item, oc) then
          entry.verdict, entry.to = "gear", other
          break
        end
      end
    end
    if not entry.verdict then
      local de = (ns.DisenchantPrice and ns.DisenchantPrice(item)) or DisenchantValue(cand.yield)
      local ah = ns.PriceSource and ns.PriceSource(item)
      if de and ah and ah > de * SELL_RATIO then
        entry.verdict, entry.ah, entry.de = "sell", ah, de
      else
        entry.verdict, entry.de = "disenchant", de
        for mat in pairs(cand.yield) do
          for _, oc in pairs(chars) do
            if ns.NeedOf(oc, mat) > 0 then entry.useful = true end
          end
        end
        if enchanter ~= key then entry.enchanter = enchanter end
      end
    end
    out[#out + 1] = entry
  end
  local order = { target = 1, gear = 2, disenchant = 3, sell = 4 }
  table.sort(out, function(a, b)
    if order[a.verdict] ~= order[b.verdict] then return order[a.verdict] < order[b.verdict] end
    return (a.useful and 1 or 0) > (b.useful and 1 or 0)
  end)
  return out
end

local pending -- { t, before = bag snapshot, loot = { [itemID] = n } }

local function DB()
  ComradeCraftDB.disenchants = ComradeCraftDB.disenchants or { raw = {} }
  return ComradeCraftDB.disenchants
end

local function ItemFacts(item)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, _, quality, ilvl, _, _, _, _, _, _, _, classID = get(item)
  return name and { quality = quality, ilvl = ilvl, classID = classID } or nil
end

-- Pure: the item that went missing between two snapshots (count dropped), ignoring loot.
function ns.DisenchantedItem(before, after, loot)
  for item, n in pairs(before) do
    if (after[item] or 0) < n and not (loot and loot[item]) then return item end
  end
end

local function Finish()
  local p = pending
  pending = nil
  if not (p and p.loot and next(p.loot)) then return end
  local source = ns.DisenchantedItem(p.before, ns.ScanBagContents(), p.loot)
  if not source then return end
  local facts = ItemFacts(source) or {}
  local raw = DB().raw
  raw[#raw + 1] = { item = source, ilvl = facts.ilvl, quality = facts.quality, classID = facts.classID,
    loot = p.loot, t = time() }
  if #raw > MAX_RAW then table.remove(raw, 1) end
  ns.Log(("disenchant: item %d -> %d result types"):format(source, (function()
    local n = 0
    for _ in pairs(p.loot) do n = n + 1 end
    return n
  end)()))
end

ns.On("UNIT_SPELLCAST_START", function(unit, _, spell)
  if unit == "player" and spell == DISENCHANT and ComradeCraftDB then
    pending = { t = time(), before = ns.ScanBagContents() }
  end
end)

ns.On("LOOT_OPENED", function()
  if not pending or time() - pending.t > WINDOW then return end
  local loot = {}
  for i = 1, (GetNumLootItems and GetNumLootItems()) or 0 do
    local link = GetLootSlotLink and GetLootSlotLink(i)
    local id = link and tonumber(link:match("item:(%d+)"))
    local _, _, qty = GetLootSlotInfo(i)
    if id then loot[id] = (loot[id] or 0) + (qty or 1) end
  end
  pending.loot = loot
end)

-- The source item leaves the bags when the loot window closes (auto-loot included).
ns.On("LOOT_CLOSED", function()
  if pending and pending.loot and C_Timer then C_Timer.After(0.5, Finish) end
end)
