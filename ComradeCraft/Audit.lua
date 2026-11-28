-- Audit: craftable BiS upgrades (now + soon + consumables + unlearned patterns to hunt),
-- spec-matched missing enchants, and small bags across self, alts, group peers & guild directory.
-- Every row includes mats feasibility (group stock + estimated cost) and one obvious action.
local _, ns = ...
local L = ns.L

local Audit = {}
ns.Audit = Audit

local MAX_GEAR_UPGRADES = 5
local MAX_SOON = 3
local MAX_ENCHANTS = 3
local MAX_CONSUMABLES = 3
local MAX_PATTERNS = 3
local SOON_LOOKAHEAD = 4

local SLOT_LABELS = {
  [1] = L["Head"], [2] = L["Neck"], [3] = L["Shoulder"], [5] = L["Chest"], [6] = L["Waist"],
  [7] = L["Legs"], [8] = L["Feet"], [9] = L["Wrist"], [10] = L["Hands"],
  [11] = L["Finger"], [12] = L["Finger"], [13] = L["Trinket"], [14] = L["Trinket"],
  [15] = L["Back"], [16] = L["Weapon"], [17] = L["Off-Hand"], [18] = L["Ranged"],
}

local function SlotLabel(slot, isShield)
  if slot == 17 and isShield then return L["Shield"] end
  return SLOT_LABELS[slot] or L["Gear"]
end

-- Known crafted bags (itemID -> slot count) in Classic/Forever (fallback if GetContainerNumSlots N/A).
-- Slot counts from ItemSparse 1.60.1.71139 (ContainerSlots); false = reagent bag (reagent slot only).
local BAG_SLOTS = {
  [4238] = 6, [4240] = 8, [4241] = 10, [4245] = 10, [4957] = 6, [5081] = 6, [5762] = 8, [5763] = 10,
  [5764] = 12, [5765] = 12, [10050] = 12, [10051] = 14, [14046] = 14, [14155] = 18, [14156] = 20,
  [21841] = 16, [227844] = 18, [239147] = 24, [239148] = 30,
  [253664] = false, [253667] = false, [253973] = false, [254035] = false, [254079] = false,
  [254133] = false, [254139] = false, [277715] = false,
}

local function BagSize(item)
  local known = BAG_SLOTS[item]
  if known ~= nil then return known or nil end
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not get then return nil end
  local _, _, _, ilvl, _, _, _, _, _, _, _, classID, subClassID = get(item)
  if classID == 1 and subClassID == 0 and ilvl and ilvl >= 10 then
    return math.min(18, math.max(6, math.floor(ilvl / 3.5) * 2))
  end
end
Audit.BagSize = BagSize

-- Async pre-caching for uncached known-crafter items (capped per session to avoid event floods).
local requestedItems, requestedCount = {}, 0
local MAX_PRECACHE = 40
local function EnsureCached(id)
  if not (id and id ~= 0 and not requestedItems[id] and requestedCount < MAX_PRECACHE) then return end
  if C_Item and C_Item.IsItemDataCachedByID and C_Item.IsItemDataCachedByID(id) then return end
  if C_Item and C_Item.RequestLoadItemDataByID then
    requestedItems[id] = true
    requestedCount = requestedCount + 1
    if ns.NoteMissingItem then ns.NoteMissingItem(id) end
    pcall(C_Item.RequestLoadItemDataByID, id)
  end
end

local auditCache, auditCacheSig
function Audit.Invalidate()
  auditCache, auditCacheSig = nil, nil
end

local function AuditSignature(chars)
  local parts = {}
  for k, c in pairs(chars) do
    local sp = c.specOverride or c.spec or ""
    local kn = 0
    for _, set in pairs(c.known or {}) do
      for _ in pairs(set) do kn = kn + 1 end
    end
    parts[#parts + 1] = ("%s:%d:%s:%d:%d"):format(k, c.updated or 0, sp, c.level or 0, kn)
  end
  table.sort(parts)
  local dn = 0
  if ComradeCraftDB and ComradeCraftDB.directory then
    for _ in pairs(ComradeCraftDB.directory) do dn = dn + 1 end
  end
  parts[#parts + 1] = "d=" .. dn .. "|p=" .. (PawnCommon and "1" or "0")
  return table.concat(parts, ";")
end

local function IsEquipInstant(item)
  local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not instant then return true end
  local _, _, _, eqLoc, _, cls = instant(item)
  return (cls == 2 or cls == 4) and eqLoc ~= nil and eqLoc ~= ""
end

local function ItemInfo(id, allowPrecache)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, _, _, ilvl, reqLevel, _, _, _, equipLoc, icon, _, classID, subClassID = get(id)
  if not name and allowPrecache then EnsureCached(id) end
  return name, ilvl, equipLoc, icon, classID, subClassID, reqLevel
end

-- Total group-held inventory (bags + bank + mail across all chars in AllChars) for mats feasibility.
local function GroupInventory(chars)
  local stock = {}
  for _, c in pairs(chars) do
    for _, src in ipairs({ c.bags or {}, c.bank or {}, c.mail or {} }) do
      for item, n in pairs(src) do stock[item] = (stock[item] or 0) + n end
    end
  end
  return stock
end

-- Evaluates reagent availability across the group + estimated missing buy cost for `qty` crafts.
function Audit.MatsStatus(spell, qty, inv)
  local r = ns.Recipes and ns.Recipes[spell]
  local reag = r and r[7]
  if not (reag and #reag > 0) then return nil end
  qty = math.max(1, qty or 1)
  inv = inv or GroupInventory(ns.AllChars())
  local reqByItem, order = {}, {}
  for i = 1, #reag, 2 do
    local item, need = reag[i], reag[i + 1] * qty
    if not reqByItem[item] then order[#order + 1] = item end
    reqByItem[item] = (reqByItem[item] or 0) + need
  end
  local haveByItem = {}
  local handled = {}
  for _, item in ipairs(order) do
    if not handled[item] then
      local t = ns.ITEM_TRANSFORMS and ns.ITEM_TRANSFORMS[item]
      if t and ns.PairBalance then
        local small = t.isSmall and item or t.other
        local big = t.isSmall and t.other or item
        handled[small], handled[big] = true, true
        local hS, _, _, hB = ns.PairBalance(inv[small] or 0, inv[big] or 0, reqByItem[small] or 0, reqByItem[big] or 0, t.ratio)
        haveByItem[small], haveByItem[big] = hS, hB
      else
        haveByItem[item] = inv[item] or 0
      end
    end
  end
  local mats, ready, missingCost, complete = {}, true, 0, true
  for _, item in ipairs(order) do
    local need = reqByItem[item]
    local have = haveByItem[item] or 0
    local miss = math.max(0, need - have)
    if miss > 0 then
      ready = false
      local c = ns.BuyCost and ns.BuyCost(item, miss)
      if c then missingCost = missingCost + c else complete = false end
    end
    mats[#mats + 1] = { item = item, need = need, have = math.min(have, need), missing = miss }
  end
  return {
    ready = ready,
    mats = mats,
    cost = (not ready and missingCost > 0) and missingCost or nil,
    complete = complete,
  }
end

-- Collects all known crafter pools: own characters, synced group peers, and guild directory.
-- Priority (tie-break): 1 = own, 2 = group peer, 3 = guild directory.
local function AllCrafters(chars)
  local list, seen = {}, {}
  for ckey, c in pairs(chars) do
    seen[ckey] = true
    local spells = {}
    for _, set in pairs(c.known or {}) do
      for spell in pairs(set) do spells[spell] = true end
    end
    local fav = ns.IsFavorite and ns.IsFavorite(ckey)
    local prio = not c.peer and 1 or (fav and 1.5 or 2)
    list[#list + 1] = { key = ckey, class = c.class, own = not c.peer, peer = c.peer and true or false,
      guild = false, prio = prio, spells = spells }
  end
  if ns.Directory and ns.Directory.Index then
    local idx = ns.Directory.Index()
    for ckey, e in pairs(idx and idx.chars or {}) do
      if not seen[ckey] and not e.own and e.r then
        local fav = ns.IsFavorite and ns.IsFavorite(ckey)
        list[#list + 1] = { key = ckey, class = e.cl, own = false, peer = false,
          guild = true, prio = fav and 2.5 or 3, spells = e.r }
      end
    end
  end
  return list
end

local function ScoreBadge(gain, how)
  local g = math.floor((gain or 0) + 0.5)
  if how == "pawn" then return L["+%d with Pawn"]:format(g) end
  if how == "stats" then return L["+%d score"]:format(g) end
  return L["+%d item levels"]:format(g)
end

-- Curated verified Classic/Forever drop rates for iconic farmable patterns (by craft spell ID).
-- Shown honestly when known; other drops report exact mob count (1 mob / N mobs / world drop).
local KNOWN_DROP_RATES = {
  [20034] = "0.5%",  -- Enchant Weapon - Crusader (Scarlet Spellbinder)
  [13898] = "100%",  -- Enchant Weapon - Fiery Weapon (Pyromancer Loregrain)
  [20032] = "6%",    -- Enchant Weapon - Lifestealing (Spectral Researcher)
  [20029] = "5%",    -- Enchant Weapon - Icy Chill (Anguished Highborne)
  [22749] = "2%",    -- Enchant Weapon - Spell Power (MC bosses)
  [22750] = "2%",    -- Enchant Weapon - Healing Power (MC bosses)
  [20025] = "0.5%",  -- Enchant Chest - Greater Stats (World drop)
  [20010] = "10%",   -- Enchant Bracer - Superior Strength (Deadwind Warlock)
  [20011] = "1%",    -- Enchant Bracer - Superior Stamina (World drop)
  [20008] = "5%",    -- Enchant Bracer - Greater Intellect (World drop)
  [13943] = "8%",    -- Enchant Boots - Minor Speed (World drop)
  [18457] = "4%",    -- Robe of the Archmage (Firebrand Pyromancer)
  [18458] = "5%",    -- Robe of the Void (Darkmaster Gandling)
  [18456] = "4%",    -- Truefaith Vestments (Balnazzar)
  [18453] = "2%",    -- Felcloth Gloves (Shadowsworn / World drop)
  [18445] = "2%",    -- Mooncloth Bag (World drop)
  [19084] = "4%",    -- Devilsaur Gauntlets (Hakkari / Un'Goro)
  [19097] = "4%",    -- Devilsaur Leggings (Cloned Ooze)
  [22927] = "4%",    -- Hide of the Wild (Knot Thimblejack's Cache)
  [17556] = "2%",    -- Elixir of the Mongoose (Jadefire Rogue / Satyr)
  [17573] = "4%",    -- Greater Fire Protection Potion (LBRS Firebrand Invoker)
  [17575] = "5%",    -- Greater Shadow Protection Potion (Dark Adepts / Scholo)
  [17574] = "5%",    -- Greater Frost Protection Potion (Frostmaul Giant)
  [17637] = "4%",    -- Flask of Supreme Power (Ras Frostwhisper)
  [17634] = "4%",    -- Flask of the Titans (General Drakkisath)
  [17635] = "4%",    -- Flask of Distilled Wisdom (Balnazzar)
  [16729] = "0.2%",  -- Lionheart Helm (World drop / Raid bosses)
  [27829] = "0.5%",  -- Titanic Leggings (World drop)
}

-- Returns formatted drop chance ("~4%", "~0.5%", etc.) for a recipe scroll itemID / spellID:
-- 1. Optional runtime connector if a Forever drop-rate addon exposes a public GetDropRate API.
-- 2. Peer-verified live ForeverDB observations (>= 10 kills, >= 1 drop).
-- 3. Embedded Classic 1.12 reference table (ns.DropRates, 358 dropable recipes from CMaNGOS).
-- 4. Fallback curated table for iconic spells when itemID is omitted.
function ns.DropRateText(recipeItem, spell)
  if recipeItem and recipeItem > 0 then
    for _, gname in ipairs({ "ForeverDrops", "Lootified" }) do
      local api = _G[gname]
      if type(api) == "table" and type(api.GetDropRate) == "function" then
        local ok, v = pcall(api.GetDropRate, recipeItem)
        if ok and type(v) == "number" and v > 0 then
          return ("%.2f"):format(v):gsub("%.?0+$", "") .. "%"
        end
      end
    end
    if ns.ForeverDB and ns.ForeverDB.DropRate then
      local pct = ns.ForeverDB.DropRate(recipeItem)
      if pct and pct > 0 then
        return ("%.2f"):format(pct):gsub("%.?0+$", "") .. "%"
      end
    end
    local r = ns.DropRates and ns.DropRates[recipeItem]
    if r and r > 0 then
      return ("%.2f"):format(r):gsub("%.?0+$", "") .. "%"
    end
  end
  return spell and KNOWN_DROP_RATES[spell] or nil
end

local function PlaceZoneName(place)
  if not place then return nil end
  if place.areaId and C_Map and C_Map.GetAreaInfo then
    local z = C_Map.GetAreaInfo(place.areaId)
    if type(z) == "string" and z ~= "" then return z end
  end
  if place.uiMap and C_Map and C_Map.GetMapInfo then
    local info = C_Map.GetMapInfo(place.uiMap)
    if info and info.name and info.name ~= "" then return info.name end
  end
end

-- Compact source summary for an unlearned pattern (trainer / vendor / quest / drop + drop rate / AH).
local function PatternSourceText(spell, recipeItem)
  local src = ns.RecipeSources and ns.RecipeSources(spell)
  if not src then return nil, nil end
  local ahTxt = ""
  if recipeItem and recipeItem > 0 and not (ns.IsBoP and ns.IsBoP(recipeItem)) and ns.PriceSource then
    local p = ns.PriceSource(recipeItem)
    if p and p > 0 then ahTxt = " | " .. L["AH ~%s"]:format(ns.Money(math.floor(p))) end
  end
  local myMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  for _, kind in ipairs({ "trainer", "vendor", "quest", "drop" }) do
    local s = src[kind]
    if s and s.list and s.list[1] then
      local first = s.list[1]
      local who = first.name or ("#" .. tostring(first.id))
      if kind == "drop" then
        local rate = ns.DropRateText(recipeItem, spell)
        local base
        if (s.total or 0) > 50 then
          local z = PlaceZoneName(first.place)
          local where
          if z and myMap and first.place and first.place.uiMap == myMap then
            where = L["world drop - here (%s)"]:format(z)
          elseif z then
            where = L["world drop - near %s"]:format(z)
          else
            where = L["world drop"]
          end
          base = rate and ("%s (~%s)"):format(where, rate) or where
        elseif rate then
          base = ("%s: %s (~%s)"):format(L["drop"], who, rate)
        elseif (s.total or 1) == 1 then
          base = ("%s: %s (%s)"):format(L["drop"], who, L["1 mob"])
        else
          base = ("%s: %s (%s)"):format(L["drop"], who, L["%d mobs"]:format(s.total))
        end
        return base .. ahTxt, kind
      end
      return ("%s: %s"):format(L[kind], who) .. ahTxt, kind
    end
  end
end

-- Unlearned BiS patterns (trainer/vendor/drop/quest) that a group member's profession can learn soon.
local function FindUnlearnedPatterns(tc, tkey, chars, knownSet, bestKnownBySlot, inv)
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  if not (lib and lib.GetRecipes and ns.UpgradeFor) then return {} end
  -- Highest rank per crafting profession in the group.
  local profBest = {}
  for ckey, c in pairs(chars) do
    for pname, p in pairs(c.professions or {}) do
      local line = p.skillLine
      if line and not ns.GATHERING[line] and line ~= ns.ENCHANTING then
        local cur = profBest[line]
        if not cur or (p.rank or 0) > cur.rank then
          profBest[line] = { key = ckey, class = c.class, prof = pname, rank = p.rank or 0, own = not c.peer }
        end
      end
    end
  end
  local bestBySlot = {}
  for line, pb in pairs(profBest) do
    for spell, e in pairs(lib:GetRecipes(line) or {}) do
      local r = ns.Recipes[spell]
      local item = r and r[5]
      local req = type(e) == "table" and e.requiredSkill or 0
      if item and item ~= 0 and not knownSet[spell] and not BAG_SLOTS[item] and IsEquipInstant(item)
        and not (lib.IsHiddenRecipe and lib:IsHiddenRecipe(spell))
        and req <= pb.rank + 25 then
        local bop = ns.IsBoP and ns.IsBoP(item)
        if not bop or pb.key == tkey then
          -- Fast path: only score cached items with a known source kind (O(1)); defer heavy
          -- Questie/HereBeDragons RecipeSources lookup to the final top-3 winners only!
          local name, _, eqLoc, _, _, subClassID = ItemInfo(item, false)
          local kinds = name and lib.GetRecipeSourceKinds and lib:GetRecipeSourceKinds(spell)
          if name and kinds and (kinds.trainer or kinds.vendor or kinds.quest or kinds.drop) then
            local up, gain, how, slotID = ns.UpgradeFor(item, tc)
            local knownGain = slotID and bestKnownBySlot[slotID] and bestKnownBySlot[slotID].gain or 0
            if up and gain and gain > knownGain + 1e-6 then
              local sk = slotID or 0
              local prev = bestBySlot[sk]
              if not prev or gain > prev.gain then
                bestBySlot[sk] = {
                  kind = "pattern", spell = spell, item = item, recipeItem = type(e) == "table" and e.itemId or nil,
                  gain = gain, how = how, slot = sk,
                  isShield = (eqLoc == "INVTYPE_SHIELD" or subClassID == 6),
                  crafter = pb.key, crafterClass = pb.class, ownCrafter = pb.own,
                  req = req, rank = pb.rank,
                  mats = Audit.MatsStatus(spell, 1, inv),
                }
              end
            end
          end
        end
      end
    end
  end
  local out = {}
  for _, p in pairs(bestBySlot) do out[#out + 1] = p end
  table.sort(out, function(a, b) return a.gain > b.gain end)
  local trimmed = {}
  for i = 1, #out do
    if #trimmed >= MAX_PATTERNS then break end
    local p = out[i]
    local srcTxt = PatternSourceText(p.spell, p.recipeItem)
    if srcTxt then
      p.sourceText = srcTxt
      local gname = ItemInfo(p.item, false) or ns.SpellName(p.spell)
      local slotTag = p.slot > 0 and ("[" .. SlotLabel(p.slot, p.isShield) .. "] ") or ""
      p.summary = ("%s%s (%s) - %s"):format(slotTag, gname, ScoreBadge(p.gain, p.how), srcTxt)
      trimmed[#trimmed + 1] = p
    end
  end
  return trimmed
end

-- Returns grouped upgrade opportunities per character (memoized until group state changes).
function Audit.Run()
  local chars = ns.AllChars()
  local sig = AuditSignature(chars)
  if auditCache and auditCacheSig == sig then return auditCache end
  local me = ns.CharKey()
  local GS = ns.GearScore
  local crafters = AllCrafters(chars)
  local inv = GroupInventory(chars)

  -- Index known bags, enchants, consumables & full known spell set across all crafters.
  local knownBags, knownEnchants, knownConsumables, knownSet = {}, {}, {}, {}
  for _, cr in ipairs(crafters) do
    for spell in pairs(cr.spells) do
      knownSet[spell] = true
      local r = ns.Recipes[spell]
      if r then
        local item = r[5]
        if item and item ~= 0 then
          local sz = BagSize(item)
          if sz and sz >= 8 then
            knownBags[#knownBags + 1] = { spell = spell, item = item, slots = sz,
              crafter = cr.key, class = cr.class, own = cr.own, guild = cr.guild, prio = cr.prio }
          elseif GS and GS.CONSUMABLES and GS.CONSUMABLES[spell] then
            knownConsumables[#knownConsumables + 1] = { spell = spell, item = item,
              crafter = cr.key, class = cr.class, own = cr.own, guild = cr.guild, prio = cr.prio }
          end
        elseif r[1] == ns.ENCHANTING and ns.EnchantSlots and ns.EnchantSlots[spell] then
          knownEnchants[#knownEnchants + 1] = { spell = spell, rank = r[2] or 0,
            crafter = cr.key, class = cr.class, own = cr.own, guild = cr.guild, prio = cr.prio }
        end
      end
    end
  end
  table.sort(knownBags, function(a, b)
    if a.slots ~= b.slots then return a.slots > b.slots end
    return a.prio < b.prio
  end)

  local results = {}
  for tkey, tc in pairs(chars) do
    local list = {}
    local specKey = GS and GS.GetSpec(tc)
    local specLabel = specKey and GS.SpecLabel(specKey) or tc.spec

    -- 1. Small bags: smallest equipped bag vs best craftable bag.
    if tc.bagSizes and #knownBags > 0 then
      local smallest, smallCount = 99, 0
      for i = 1, 4 do
        local sz = tc.bagSizes[i]
        if sz and sz < smallest then smallest = sz end
      end
      local bestBag = knownBags[1]
      if smallest < bestBag.slots then
        for i = 1, 4 do
          local sz = tc.bagSizes[i]
          if sz and sz < bestBag.slots then smallCount = smallCount + 1 end
        end
        local bname = ItemInfo(bestBag.item) or ("item:" .. bestBag.item)
        list[#list + 1] = {
          kind = "bag", spell = bestBag.spell, item = bestBag.item,
          crafter = bestBag.crafter, crafterClass = bestBag.class,
          ownCrafter = bestBag.own, guildCrafter = bestBag.guild,
          qty = smallCount, mats = Audit.MatsStatus(bestBag.spell, smallCount, inv),
          summary = L["%d small bags (min %d slots) -> %s (%d slots)"]:format(smallCount, smallest, bname, bestBag.slots),
        }
      end
    end

    -- 2. Missing enchants on equipped slots (exact class/inv/subclass match + best spec score).
    if tc.enchants and tc.equipped and #knownEnchants > 0 and GS then
      local enchCands = {}
      for _, slot in ipairs({ 16, 17, 5, 9, 10, 8, 15, 2 }) do
        if tc.enchants[slot] == 0 and tc.equipped[slot] then
          local _, _, eqLoc, _, classID, subClassID = ItemInfo(tc.equipped[slot])
          local invType = eqLoc and GS.INVTYPE[eqLoc]
          if classID then
            local bestEn, bestScore
            for _, en in ipairs(knownEnchants) do
              if GS.EnchantMatchesItem(en.spell, classID, invType, subClassID) then
                local sc = GS.ScoreEnchant(en.spell, tc)
                if sc > 0 and (not bestEn or sc > bestScore
                  or (sc == bestScore and (en.prio < bestEn.prio or (en.prio == bestEn.prio and en.rank > bestEn.rank)))) then
                  bestEn, bestScore = en, sc
                end
              end
            end
            if bestEn then
              enchCands[#enchCands + 1] = {
                slot = slot, isShield = (eqLoc == "INVTYPE_SHIELD" or subClassID == 6),
                en = bestEn, score = bestScore,
              }
            end
          end
        end
      end
      table.sort(enchCands, function(a, b) return a.score > b.score end)
      for i = 1, math.min(MAX_ENCHANTS, #enchCands) do
        local ec = enchCands[i]
        local en = ec.en
        list[#list + 1] = {
          kind = "enchant", spell = en.spell, item = 0,
          crafter = en.crafter, crafterClass = en.class,
          ownCrafter = en.own, guildCrafter = en.guild,
          qty = 1, score = ec.score, mats = Audit.MatsStatus(en.spell, 1, inv),
          summary = L["Unenchanted %s -> %s"]:format(SlotLabel(ec.slot, ec.isShield), ns.SpellName(en.spell)),
        }
      end
    end

    -- 3. Top 5 craftable BiS gear upgrades (now) + Top 3 upcoming (+1..+4 levels).
    local bestBySlot, soonBySlot = {}, {}
    for _, cr in ipairs(crafters) do
      local isSelf = cr.key == tkey
      for spell in pairs(cr.spells) do
        local r = ns.Recipes[spell]
        local item = r and r[5]
        if item and item ~= 0 and not BAG_SLOTS[item] and not (GS and GS.CONSUMABLES and GS.CONSUMABLES[spell])
          and IsEquipInstant(item) then
          local bop = ns.IsBoP and ns.IsBoP(item)
          if not bop or isSelf then
            local name, _, eqLoc, _, _, subClassID, reqLvl = ItemInfo(item, true)
            if name then
              local up, gain, how, slotID = ns.UpgradeFor(item, tc)
              if up and gain and gain > 0 then
                local sk = slotID or 0
                local prev = bestBySlot[sk]
                if not prev or gain > prev.gain + 1e-6
                  or (math.abs(gain - prev.gain) <= 1e-6 and cr.prio < prev.prio) then
                  bestBySlot[sk] = {
                    spell = spell, item = item, gain = gain, how = how, slot = sk,
                    isShield = (eqLoc == "INVTYPE_SHIELD" or subClassID == 6),
                    crafter = cr.key, class = cr.class, own = cr.own, guild = cr.guild, prio = cr.prio,
                  }
                end
              elseif GS and tc.level and reqLvl and reqLvl > tc.level and reqLvl <= tc.level + SOON_LOOKAHEAD then
                local sup, sgain, show, sslot = GS.UpgradeFor(item, tc, ns.ItemScore, SOON_LOOKAHEAD)
                if sup and sgain and sgain > 0 then
                  local sk = sslot or 0
                  local prev = soonBySlot[sk]
                  if not prev or sgain > prev.gain + 1e-6
                    or (math.abs(sgain - prev.gain) <= 1e-6 and cr.prio < prev.prio) then
                    soonBySlot[sk] = {
                      spell = spell, item = item, gain = sgain, how = show, slot = sk, reqLevel = reqLvl,
                      isShield = (eqLoc == "INVTYPE_SHIELD" or subClassID == 6),
                      crafter = cr.key, class = cr.class, own = cr.own, guild = cr.guild, prio = cr.prio,
                    }
                  end
                end
              end
            end
          end
        end
      end
    end
    local gearUps = {}
    for _, g in pairs(bestBySlot) do gearUps[#gearUps + 1] = g end
    table.sort(gearUps, function(a, b)
      if a.gain ~= b.gain then return a.gain > b.gain end
      return a.item < b.item
    end)
    local topGear = {}
    for i = 1, math.min(MAX_GEAR_UPGRADES, #gearUps) do topGear[#topGear + 1] = gearUps[i] end
    local SLOT_ORDER = { [1] = 1, [2] = 2, [3] = 3, [15] = 4, [5] = 5, [9] = 6, [10] = 7, [6] = 8,
      [7] = 9, [8] = 10, [11] = 11, [12] = 12, [13] = 13, [14] = 14, [16] = 15, [17] = 16, [18] = 17 }
    table.sort(topGear, function(a, b)
      local oa, ob = SLOT_ORDER[a.slot or 0] or 99, SLOT_ORDER[b.slot or 0] or 99
      if oa ~= ob then return oa < ob end
      return a.gain > b.gain
    end)
    for _, g in ipairs(topGear) do
      local gname = ItemInfo(g.item) or ns.SpellName(g.spell)
      local slotTag = g.slot and g.slot > 0 and ("[" .. SlotLabel(g.slot, g.isShield) .. "] ") or ""
      list[#list + 1] = {
        kind = "gear", spell = g.spell, item = g.item, slot = g.slot, gain = g.gain, how = g.how,
        crafter = g.crafter, crafterClass = g.class, ownCrafter = g.own, guildCrafter = g.guild,
        qty = 1, mats = Audit.MatsStatus(g.spell, 1, inv),
        summary = ("%s%s (%s)"):format(slotTag, gname, ScoreBadge(g.gain, g.how)),
      }
    end

    -- 4. Upcoming (+1..+4 levels) BiS gear (only if better than current craftable BiS for that slot).
    local soonUps = {}
    for sk, g in pairs(soonBySlot) do
      local cur = bestBySlot[sk]
      if not cur or g.gain > cur.gain + 1e-6 then soonUps[#soonUps + 1] = g end
    end
    table.sort(soonUps, function(a, b)
      if a.reqLevel ~= b.reqLevel then return a.reqLevel < b.reqLevel end
      return a.gain > b.gain
    end)
    local soon = {}
    for i = 1, math.min(MAX_SOON, #soonUps) do
      local g = soonUps[i]
      local gname = ItemInfo(g.item) or ns.SpellName(g.spell)
      local slotTag = g.slot and g.slot > 0 and ("[" .. SlotLabel(g.slot, g.isShield) .. "] ") or ""
      soon[#soon + 1] = {
        kind = "soon", spell = g.spell, item = g.item, slot = g.slot, gain = g.gain, how = g.how,
        reqLevel = g.reqLevel, crafter = g.crafter, crafterClass = g.class,
        ownCrafter = g.own, guildCrafter = g.guild, qty = 1,
        mats = Audit.MatsStatus(g.spell, 1, inv),
        summary = ("%s%s (%s, %s)"):format(slotTag, gname, L["Lvl %d"]:format(g.reqLevel), ScoreBadge(g.gain, g.how)),
      }
    end

    -- 5. Spec-matched Consumables (best 1 per category: elixir, weapon oil/stone, potion/food).
    local consByCat = {}
    if GS and GS.ScoreConsumable and #knownConsumables > 0 then
      for _, cn in ipairs(knownConsumables) do
        local sc, cat = GS.ScoreConsumable(cn.spell, tc)
        if sc > 0 and cat then
          local prev = consByCat[cat]
          if not prev or sc > prev.score or (sc == prev.score and cn.prio < prev.cn.prio) then
            consByCat[cat] = { cn = cn, score = sc, cat = cat }
          end
        end
      end
    end
    local consumables = {}
    for _, cat in ipairs({ "elixir", "weapon", "potion" }) do
      local hit = consByCat[cat]
      if hit and #consumables < MAX_CONSUMABLES then
        local cn = hit.cn
        local cname = ItemInfo(cn.item) or ns.SpellName(cn.spell)
        consumables[#consumables + 1] = {
          kind = "consumable", spell = cn.spell, item = cn.item,
          crafter = cn.crafter, crafterClass = cn.class, ownCrafter = cn.own, guildCrafter = cn.guild,
          qty = 5, mats = Audit.MatsStatus(cn.spell, 5, inv),
          summary = ("5x %s"):format(cname),
        }
      end
    end

    -- 6. Potential unlearned BiS patterns (for own characters with equipment data).
    local patterns = (not tc.peer and tc.equipped) and FindUnlearnedPatterns(tc, tkey, chars, knownSet, bestBySlot, inv) or {}

    if #list > 0 or #soon > 0 or #consumables > 0 or #patterns > 0 then
      results[#results + 1] = {
        targetKey = tkey, targetClass = tc.class, targetSpec = specKey, targetSpecLabel = specLabel,
        isMe = tkey == me, ownTarget = not tc.peer,
        items = list, soon = soon, consumables = consumables, patterns = patterns,
      }
    end
  end
  table.sort(results, function(a, b)
    if a.isMe ~= b.isMe then return a.isMe end
    return a.targetKey < b.targetKey
  end)
  auditCache, auditCacheSig = results, sig
  return results
end

-- Unlearned high-value patterns for a specific crafter (gear BiS, enchanting formulas, bigger bags,
-- and spec consumables) that help themselves OR any friend/alt in the group.
-- Returns { { spell, item, recipeItem, line, prof, req, rank, canLearn, category, forList, helpsSelf,
--   score, sourceText, sourceKind, ahPrice } }.
function Audit.PatternsForCrafter(crafterKey)
  local chars = ns.AllChars()
  local cr = chars[crafterKey]
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  if not (cr and lib and lib.GetRecipes) then return {} end
  local GS = ns.GearScore
  local meKey = ns.CharKey()
  local knownAll = {}
  for _, set in pairs(cr.known or {}) do
    for sp in pairs(set) do knownAll[sp] = true end
  end
  -- Build each group member's min bag size once for fast bag-pattern checks.
  local minBagOf = {}
  for tkey, tc in pairs(chars) do
    local mb
    for i = 1, 4 do -- special bags (quiver, soul bag) are nil holes
      local sz = (tc.bagSizes or {})[i]
      if type(sz) == "number" and sz > 0 and (not mb or sz < mb) then mb = sz end
    end
    minBagOf[tkey] = mb
  end
  local candidates = {}
  for pname, p in pairs(cr.professions or {}) do
    local line = p.skillLine
    local rank = p.rank or 0
    if line and not ns.GATHERING[line] then
      for spell, e in pairs(lib:GetRecipes(line) or {}) do
        local r = ns.Recipes[spell]
        local req = type(e) == "table" and e.requiredSkill or 0
        if r and not knownAll[spell] and req <= rank + 40
          and not (lib.IsHiddenRecipe and lib:IsHiddenRecipe(spell)) then
          local kinds = lib.GetRecipeSourceKinds and lib:GetRecipeSourceKinds(spell)
          if kinds and (kinds.trainer or kinds.vendor or kinds.quest or kinds.drop) then
            local item = r[5] or 0
            local recipeItem = type(e) == "table" and e.itemId or nil
            local forList, helpsSelf, bestScore, cat, slotGroup = {}, false, 0, nil, "Other"
            local bagSz = item ~= 0 and BAG_SLOTS[item]
            if bagSz and bagSz >= 12 then
              for tkey, tc in pairs(chars) do
                local mb = minBagOf[tkey]
                if mb and mb < bagSz then
                  forList[#forList + 1] = { key = tkey, class = tc.class, level = tc.level or 1, gain = bagSz - mb, isSelf = (tkey == meKey or tkey == crafterKey) }
                  if tkey == meKey or tkey == crafterKey then helpsSelf = true end
                  bestScore = math.max(bestScore, (bagSz - mb) * 8)
                end
              end
              cat, slotGroup = "bag", "Bags"
            elseif line == ns.ENCHANTING and GS and GS.ScoreEnchant and ns.EnchantSlots and ns.EnchantSlots[spell] then
              for tkey, tc in pairs(chars) do
                local sc = GS.ScoreEnchant(spell, tc)
                if sc and sc >= 8 then
                  forList[#forList + 1] = { key = tkey, class = tc.class, level = tc.level or 1, gain = sc, isSelf = (tkey == meKey or tkey == crafterKey) }
                  if tkey == meKey or tkey == crafterKey then helpsSelf = true end
                  bestScore = math.max(bestScore, sc)
                end
              end
              cat, slotGroup = "enchant", "Enchants"
            elseif item ~= 0 and GS and GS.CONSUMABLES and GS.CONSUMABLES[spell] and GS.ScoreConsumable then
              for tkey, tc in pairs(chars) do
                local sc = GS.ScoreConsumable(spell, tc)
                if sc and sc >= 6 then
                  forList[#forList + 1] = { key = tkey, class = tc.class, level = tc.level or 1, gain = sc, isSelf = (tkey == meKey or tkey == crafterKey) }
                  if tkey == meKey or tkey == crafterKey then helpsSelf = true end
                  bestScore = math.max(bestScore, sc)
                end
              end
              cat, slotGroup = "consumable", "Consumables"
            elseif item ~= 0 and IsEquipInstant(item) and ns.UpgradeFor then
              local name, _, eqLoc = ItemInfo(item, false)
              if name then
                local bop = ns.IsBoP and ns.IsBoP(item)
                for tkey, tc in pairs(chars) do
                  if (not bop or tkey == crafterKey) and tc.equipped then
                    local up, gain, how = ns.UpgradeFor(item, tc)
                    if up and gain and gain > 0 then
                      forList[#forList + 1] = { key = tkey, class = tc.class, level = tc.level or 1, gain = gain, how = how, isSelf = (tkey == meKey or tkey == crafterKey) }
                      if tkey == meKey or tkey == crafterKey then helpsSelf = true end
                      bestScore = math.max(bestScore, gain)
                    end
                  end
                end
                cat = "gear"
                local isWep = eqLoc == "INVTYPE_WEAPON" or eqLoc == "INVTYPE_2HWEAPON"
                  or eqLoc == "INVTYPE_WEAPONMAINHAND" or eqLoc == "INVTYPE_WEAPONOFFHAND"
                  or eqLoc == "INVTYPE_RANGED" or eqLoc == "INVTYPE_RANGEDRIGHT" or eqLoc == "INVTYPE_THROWN"
                slotGroup = isWep and "Weapon" or "Armor"
              end
            end
            if #forList > 0 then
              table.sort(forList, function(a, b)
                if a.isSelf ~= b.isSelf then return a.isSelf end
                if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) > (b.level or 0) end
                return (a.gain or 0) > (b.gain or 0)
              end)
              candidates[#candidates + 1] = {
                spell = spell, item = item, recipeItem = recipeItem, line = line,
                prof = ns.ProfName and ns.ProfName(line, pname) or pname,
                req = req, rank = rank, canLearn = rank >= req, category = cat, slotGroup = slotGroup,
                forList = forList, helpsSelf = helpsSelf,
                score = bestScore + #forList * 4 + (helpsSelf and 12 or 0) + (rank >= req and 6 or 0),
              }
            end
          end
        end
      end
    end
  end
  table.sort(candidates, function(a, b)
    if a.score ~= b.score then return a.score > b.score end
    return a.req < b.req
  end)
  local out = {}
  for i = 1, math.min(#candidates, 36) do
    local p = candidates[i]
    local srcTxt, srcKind = PatternSourceText(p.spell, p.recipeItem)
    if srcTxt then
      p.sourceText, p.sourceKind = srcTxt, srcKind
      out[#out + 1] = p
    end
  end
  return out
end
