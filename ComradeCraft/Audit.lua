-- Audit: clean, clutter-free Group Upgrades check (small bags, missing enchants, craftable gear).
-- Pure over ComradeCraftDB + ns.Recipes + ns.EnchantSlots; every row offers one obvious action
-- (Pin to Wishlist if you craft it, or Ask if a group member crafts it).
local _, ns = ...
local L = ns.L

local Audit = {}
ns.Audit = Audit

local INVTYPE = { INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4, INVTYPE_CHEST = 5,
  INVTYPE_WAIST = 6, INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10, INVTYPE_FINGER = 11,
  INVTYPE_TRINKET = 12, INVTYPE_WEAPON = 13, INVTYPE_SHIELD = 14, INVTYPE_RANGED = 15, INVTYPE_CLOAK = 16,
  INVTYPE_2HWEAPON = 17, INVTYPE_ROBE = 20, INVTYPE_WEAPONMAINHAND = 21, INVTYPE_WEAPONOFFHAND = 22,
  INVTYPE_HOLDABLE = 23, INVTYPE_THROWN = 25, INVTYPE_RANGEDRIGHT = 26 }

local function SlotLabel(slot)
  if slot == 5 then return L["Chest"]
  elseif slot == 8 then return L["Feet"]
  elseif slot == 9 then return L["Wrist"]
  elseif slot == 10 then return L["Hands"]
  elseif slot == 15 then return L["Back"]
  elseif slot == 16 then return L["Weapon"]
  elseif slot == 17 then return L["Shield"]
  end
  return L["Gear"]
end

local function Bit(mask, n) return math.floor(mask / 2 ^ n) % 2 == 1 end

-- Known crafted bags (itemID -> slot count) in Classic/Forever (fallback if GetContainerNumSlots N/A).
local BAG_SLOTS = {
  [4238] = 6,   -- Linen Bag
  [4240] = 8,   -- Woolen Bag
  [4241] = 8,   -- Green Woolen Bag
  [4245] = 10,  -- Small Silk Pack
  [4957] = 10,  -- Red Woolen Bag (Classic/Forever 8-10)
  [10050] = 12, -- Mageweave Bag
  [10051] = 12, -- Red Mageweave Bag
  [14046] = 14, -- Runecloth Bag
  [14155] = 16, -- Mooncloth Bag
  [14156] = 18, -- Bottomless Bag
  [21841] = 16, -- Netherweave Bag
}

local function BagSize(item)
  if BAG_SLOTS[item] then return BAG_SLOTS[item] end
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not get then return nil end
  local _, _, _, _, _, _, _, _, _, _, _, classID, subClassID = get(item)
  if classID == 1 and subClassID == 0 then
    -- Unknown custom bag: estimate from itemLevel if present.
    local _, _, _, ilvl = get(item)
    if ilvl and ilvl >= 10 then return math.min(18, math.max(6, math.floor(ilvl / 3.5) * 2)) end
  end
end

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, _, _, ilvl, _, _, _, _, equipLoc, icon, _, classID = get(id)
  return name, ilvl, equipLoc, icon, classID
end

-- Returns grouped upgrade opportunities: { { targetKey, targetClass, items = { { kind, spell, item,
-- crafter, crafterClass, ownCrafter, summary, detail } } }, ... }.
function Audit.Run()
  local chars = ns.AllChars()
  local me = ns.CharKey()
  -- Index group crafters' known bags & enchants.
  local knownBags, knownEnchants = {}, {}
  for ckey, c in pairs(chars) do
    for _, set in pairs(c.known or {}) do
      for spell in pairs(set) do
        local r = ns.Recipes[spell]
        if r then
          local item = r[5]
          if item and item ~= 0 then
            local sz = BagSize(item)
            if sz and sz >= 8 then
              knownBags[#knownBags + 1] = { spell = spell, item = item, slots = sz, crafter = ckey, class = c.class, own = not c.peer }
            end
          elseif r[1] == ns.ENCHANTING and ns.EnchantSlots and ns.EnchantSlots[spell] then
            local es = ns.EnchantSlots[spell]
            knownEnchants[#knownEnchants + 1] = { spell = spell, classID = es[1], mask = es[2],
              rank = r[2] or 0, crafter = ckey, class = c.class, own = not c.peer }
          end
        end
      end
    end
  end
  table.sort(knownBags, function(a, b) return a.slots > b.slots end)
  table.sort(knownEnchants, function(a, b) return a.rank > b.rank end)

  local results = {}
  for tkey, tc in pairs(chars) do
    local list = {}
    -- 1. Small bags: check smallest equipped bag against best bag the group can craft.
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
          crafter = bestBag.crafter, crafterClass = bestBag.class, ownCrafter = bestBag.own,
          qty = smallCount,
          summary = L["%d small bags (min %d slots) -> %s (%d slots)"]:format(smallCount, smallest, bname, bestBag.slots),
        }
      end
    end

    -- 2. Missing enchants on equipped slots (max 3 highest-impact slots per character to stay clean).
    if tc.enchants and tc.equipped and #knownEnchants > 0 then
      local enchCount = 0
      for _, slot in ipairs({ 16, 5, 9, 10, 8, 15, 17 }) do
        if enchCount >= 3 then break end
        if tc.enchants[slot] == 0 and tc.equipped[slot] then
          local _, _, eqLoc, _, classID = ItemInfo(tc.equipped[slot])
          local inv = eqLoc and INVTYPE[eqLoc]
          if classID then
            for _, en in ipairs(knownEnchants) do
              local match = en.classID == classID and (en.mask == 0 or (inv and Bit(en.mask, inv)))
              if match then
                enchCount = enchCount + 1
                list[#list + 1] = {
                  kind = "enchant", spell = en.spell, item = 0,
                  crafter = en.crafter, crafterClass = en.class, ownCrafter = en.own,
                  qty = 1,
                  summary = L["Unenchanted %s -> %s"]:format(SlotLabel(slot), ns.SpellName(en.spell)),
                }
                break
              end
            end
          end
        end
      end
    end

    -- 3. Top craftable gear upgrades (max 2 per character to keep UI crisp).
    local gearUps = {}
    for ckey, cc in pairs(chars) do
      if ckey ~= tkey then
        for _, set in pairs(cc.known or {}) do
          for spell in pairs(set) do
            local r = ns.Recipes[spell]
            local item = r and r[5]
            if item and item ~= 0 and not BAG_SLOTS[item] and not (ns.IsBoP and ns.IsBoP(item)) then
              local up, gain, how = ns.UpgradeFor(item, tc)
              if up and gain and gain > 0 then
                gearUps[#gearUps + 1] = { spell = spell, item = item, gain = gain, how = how,
                  crafter = ckey, class = cc.class, own = not cc.peer }
              end
            end
          end
        end
      end
    end
    table.sort(gearUps, function(a, b) return a.gain > b.gain end)
    local seenGear = {}
    local gn = 0
    for _, g in ipairs(gearUps) do
      if gn >= 2 then break end
      if not seenGear[g.item] then
        seenGear[g.item] = true
        gn = gn + 1
        local gname = ItemInfo(g.item) or ns.SpellName(g.spell)
        local badge = g.how == "pawn" and L["+%d with Pawn"]:format(math.floor(g.gain + 0.5))
          or L["+%d item levels"]:format(math.floor(g.gain + 0.5))
        list[#list + 1] = {
          kind = "gear", spell = g.spell, item = g.item,
          crafter = g.crafter, crafterClass = g.class, ownCrafter = g.own,
          qty = 1,
          summary = ("%s (%s)"):format(gname, badge),
        }
      end
    end

    if #list > 0 then
      results[#results + 1] = { targetKey = tkey, targetClass = tc.class, isMe = tkey == me, items = list }
    end
  end
  table.sort(results, function(a, b)
    if a.isMe ~= b.isMe then return a.isMe end
    return a.targetKey < b.targetKey
  end)
  return results
end
