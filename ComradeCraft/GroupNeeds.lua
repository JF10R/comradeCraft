-- GroupNeeds: cross-character material needs, surplus, give list (with per-frame cache),
-- urgency helpers, item scoring bridge (GearScore / Pawn / ilvl), and craft catalog.
local _, ns = ...

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

-- Does a crafted item suit a character (class armor/weapon proficiencies, spec & level).
function ns.ItemFits(item, c)
  if ns.GearScore and ns.GearScore.ItemFits then return ns.GearScore.ItemFits(item, c, true) end
  local f = ItemFacts(item)
  if not (f and c.level and f.classID == 4 and f.equipLoc ~= "") then return false end
  if f.reqLevel > c.level or f.reqLevel < c.level - 10 then return false end
  local anyone = f.subclassID == 0 or f.equipLoc == "INVTYPE_CLOAK"
  return anyone or f.subclassID == MainArmor(c.class, c.level)
end

-- Equipment slots an inventory type can go to (fallback when GearScore not loaded).
local SLOTS_OF = { INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 },
  INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
  INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
  INVTYPE_CLOAK = { 15 } }
local CLASS_ID = { WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5, SHAMAN = 7, MAGE = 8,
  WARLOCK = 9, DRUID = 11 }

-- Optional Pawn bridge (Pawn is CC BY-NC-ND: we call it at runtime, we never copy its weights).
-- Finds a Pawn scale for the character's class (and spec name when Pawn's name contains it).
-- Pawn's scale fields are not documented: every access is guarded, nil means "use standalone stats".
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

-- Value of an item for a character: standalone C_Item.GetItemStats score (fast, zero tooltip
-- scrape), else Pawn scale when installed (optional runtime bridge), else item level.
-- Memoized per (item, class, spec, offHand) so UI opens never stall on repeated scoring.
local scoreCache, scoreCacheN = {}, 0
function ns.ClearScoreCache()
  scoreCache, scoreCacheN = {}, 0
end

function ns.ItemScore(item, c, offHand)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link, _, ilvl = get(item)
  if type(item) == "string" then link = item end
  if not (name or link) then return 0, "ilvl" end
  local spec = (ns.GearScore and ns.GearScore.GetSpec and ns.GearScore.GetSpec(c)) or (c and c.spec) or ""
  local key = tostring(item) .. "|" .. tostring(c and c.class or "") .. "|" .. tostring(spec)
    .. (offHand and "|oh" or "") .. (PawnCommon and "|p" or "")
  local cached = scoreCache[key]
  if cached then return cached[1], cached[2] end
  local val, how
  if ns.GearScore and ns.GearScore.ScoreItem then
    local s, h = ns.GearScore.ScoreItem(item, c, offHand)
    if s then val, how = s, h end
  end
  if not val then
    local scale = ns.PawnScaleFor(c)
    if scale and link and PawnGetItemData and PawnGetSingleValueFromItem then
      local ok, data = pcall(PawnGetItemData, link)
      if ok and data then
        local ok2, v = pcall(PawnGetSingleValueFromItem, data, scale)
        if ok2 and type(v) == "number" then val, how = v, "pawn" end
      end
    end
  end
  if not val then val, how = ilvl or 0, "ilvl" end
  -- Only cache once the item is actually loaded (ilvl > 0 or real score) to avoid locking in 0.
  if val > 0 or how ~= "ilvl" then
    if scoreCacheN >= 2500 then scoreCache, scoreCacheN = {}, 0 end
    scoreCache[key] = { val, how }
    scoreCacheN = scoreCacheN + 1
  end
  return val, how
end

-- Is `item` an upgrade for character c? Respects class/spec/weapons/2H-vs-1H+OH and scores
-- against worn gear. Returns isUpgrade, gain, how, slotID.
function ns.UpgradeFor(item, c)
  if ns.GearScore and ns.GearScore.UpgradeFor then
    return ns.GearScore.UpgradeFor(item, c, ns.ItemScore)
  end
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
        local bop = r[5] ~= 0 and ns.IsBoP(r[5])
        local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        local isGear = r[5] ~= 0
        if isGear and instant then
          local _, _, _, eqLoc, _, cls = instant(r[5])
          if cls and cls ~= 2 and cls ~= 4 then isGear = false
          elseif eqLoc == "" then isGear = false end
        end
        if not bop then
          for other, oc in pairs(chars) do
            if other ~= key then
              local n = r[5] ~= 0 and ns.NeedOf(oc, r[5]) or 0
              if n > 0 then e.needers[#e.needers + 1] = { key = other, n = n } end
              if isGear then
                local up, gain = ns.UpgradeFor(r[5], oc)
                if up then e.fits[#e.fits + 1] = { key = other, gain = gain } end
              end
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

-- What a character can give away: owned (bags + bank + inbox) minus what its own plans use
-- (both gross raw mats and owned intermediates counted in need.used) and reserved items.
-- Respects bidirectional essence conversions so Lesser needed to form Greater (and vice versa)
-- are never marked as spare.
function ns.Surplus(c, item)
  local function OwnedOf(id)
    local raw = ((c.bags or {})[id] or 0) + ((c.bank or {})[id] or 0) + ((c.mail or {})[id] or 0)
    local res = c.reserved and c.reserved[id] and (c.reserved[id].qty or 0) or 0
    return math.max(0, raw - res)
  end
  local owned = OwnedOf(item)
  if owned == 0 then return 0 end
  if c.bankAlt then return owned end
  local t = ns.ITEM_TRANSFORMS[item]
  if t then
    local small = t.isSmall and item or t.other
    local big = t.isSmall and t.other or item
    local needS, needB = 0, 0
    for _, need in pairs(c.needs or {}) do
      needS = needS + ((need.gross or {})[small] or 0) + ((need.used or {})[small] or 0)
      needB = needB + ((need.gross or {})[big] or 0) + ((need.used or {})[big] or 0)
    end
    local _, _, spareS, _, _, spareB = ns.PairBalance(OwnedOf(small), OwnedOf(big), needS, needB, t.ratio)
    return t.isSmall and spareS or spareB
  end
  local used = 0
  for _, need in pairs(c.needs or {}) do
    used = used + ((need.gross or {})[item] or 0) + ((need.used or {})[item] or 0)
  end
  return math.max(0, owned - used)
end

-- Who in the group has spare `item`: total and { {key, n} } (largest first), `except` left out.
-- Includes convertible partner surplus (e.g. 3x Lesser -> 1x Greater and 1x Greater -> 3x Lesser).
function ns.GroupSupply(item, except)
  local total, list = 0, {}
  if ns.IsBoP(item) then return total, list end
  local t = ns.ITEM_TRANSFORMS[item]
  for key, c in pairs(ns.AllChars()) do
    if not (except and (ns.IsSameChar and ns.IsSameChar(key, except) or key == except)) then
      local n = ns.Surplus(c, item)
      if t and not ns.IsBoP(t.other) then
        local os = ns.Surplus(c, t.other)
        if os > 0 then
          n = n + (t.isSmall and (os * t.ratio) or math.floor(os / t.ratio))
        end
      end
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
-- (item, receiver): { item, to, n = min(spare left, need), inBags, inBank, step, convertsTo }.
-- Two-pass allocation: direct matches first, then free conversions (3x Lesser <-> 1x Greater)
-- for any remaining demand so we never over-send when holding both tiers.
local giveCacheT, giveCache = nil, {}
function ns.ClearGiveCache()
  giveCacheT, giveCache = nil, {}
end

function ns.GiveList(key)
  local now = GetTime and GetTime() or nil
  if now and giveCacheT == now and giveCache[key] then return giveCache[key] end
  if now and giveCacheT ~= now then giveCacheT, giveCache = now, {} end
  local chars = ns.AllChars()
  local c = chars[key]
  local out = {}
  if not c then return out end
  local bags = c.bags or {}
  local spareOf, bagLeftOf, itemOrder = {}, {}, {}
  local seenItem = {}
  for _, src in ipairs({ bags, c.bank or {} }) do
    for item in pairs(src) do
      if not seenItem[item] then
        seenItem[item] = true
        local bound = ns.IsBoP(item) or (c.bound and c.bound[item] and (c.bank and c.bank[item] or 0) == 0)
        local sp = not bound and ns.Surplus(c, item) or 0
        if sp > 0 then
          spareOf[item] = sp
          bagLeftOf[item] = math.min(sp, bags[item] or 0)
          itemOrder[#itemOrder + 1] = item
        end
      end
    end
  end
  table.sort(itemOrder)
  -- Collect direct demand rows per needed item (tracked with mutable `.rem` across both passes).
  local demandByItem = {}
  local function DemandFor(item)
    local list = demandByItem[item]
    if list then return list end
    list = {}
    for other, oc in pairs(chars) do
      if not (ns.IsSameChar and ns.IsSameChar(other, key) or other == key) then
        for _, r in ipairs(ns.NeedRows(oc, item, true)) do
          list[#list + 1] = { to = other, rem = r.n, step = r.step, prof = r.prof, spell = r.spell }
        end
      end
    end
    table.sort(list, function(a, b)
      local sa, sb = a.step or 99, b.step or 99
      if sa ~= sb then return sa < sb end
      return a.to < b.to
    end)
    demandByItem[item] = list
    return list
  end
  -- Pass 1: direct matches.
  for _, item in ipairs(itemOrder) do
    local spare, bagLeft = spareOf[item], bagLeftOf[item]
    for _, w in ipairs(DemandFor(item)) do
      if spare <= 0 then break end
      if w.rem > 0 then
        local n = math.min(spare, w.rem)
        local inBags = math.min(bagLeft, n)
        local inBank = n - inBags
        bagLeft = bagLeft - inBags
        spare = spare - n
        w.rem = w.rem - n
        out[#out + 1] = { item = item, to = w.to, n = n, inBags = inBags, inBank = inBank,
          step = w.step, prof = w.prof, spell = w.spell }
      end
    end
    spareOf[item], bagLeftOf[item] = spare, bagLeft
  end
  -- Pass 2: convertible partner matches for any unsatisfied demand.
  for _, item in ipairs(itemOrder) do
    local t = ns.ITEM_TRANSFORMS[item]
    local spare, bagLeft = spareOf[item], bagLeftOf[item]
    if t and spare > 0 then
      local partner = t.other
      for _, w in ipairs(DemandFor(partner)) do
        if spare <= 0 then break end
        if w.rem > 1e-6 then
          local want = t.isSmall and math.ceil(w.rem * t.ratio - 1e-9) or math.ceil(w.rem / t.ratio)
          local n = math.min(spare, want)
          if n > 0 then
            local inBags = math.min(bagLeft, n)
            local inBank = n - inBags
            bagLeft = bagLeft - inBags
            spare = spare - n
            if t.isSmall then w.rem = math.max(0, w.rem - n / t.ratio)
            else w.rem = math.max(0, w.rem - n * t.ratio) end
            out[#out + 1] = { item = item, to = w.to, n = n, inBags = inBags, inBank = inBank,
              step = w.step, prof = w.prof, spell = w.spell, convertsTo = partner }
          end
        end
      end
      spareOf[item], bagLeftOf[item] = spare, bagLeft
    end
  end
  table.sort(out, function(a, b)
    local ua, ub = ns.UrgencyRank(a.step), ns.UrgencyRank(b.step)
    if ua ~= ub then return ua < ub end
    return a.n > b.n
  end)
  if now then giveCache[key] = out end
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

-- Per-profession needs of one item: { { prof = name, n = count, step = i, spell = id, convertsTo? }, ... }.
-- Unless `directOnly` is true, also includes needs for a convertible partner (3x Lesser <-> 1x Greater).
function ns.NeedRows(c, itemID, directOnly)
  local rows = {}
  local t = not directOnly and ns.ITEM_TRANSFORMS[itemID] or nil
  for _, need in pairs(c.needs or {}) do
    local n = need.items and need.items[itemID]
    if n and n > 0 then
      local step = need.when and need.when[itemID]
      local planStep = step and need.plan and need.plan[step]
      rows[#rows + 1] = { prof = need.name, n = n, step = step, spell = planStep and planStep.spell or nil }
    end
    if t then
      local pn = need.items and need.items[t.other]
      if pn and pn > 0 then
        local convN = t.isSmall and (pn * t.ratio) or math.ceil(pn / t.ratio)
        local step = need.when and need.when[t.other]
        local planStep = step and need.plan and need.plan[step]
        rows[#rows + 1] = { prof = need.name, n = convN, step = step,
          spell = planStep and planStep.spell or nil, convertsTo = t.other }
      end
    end
  end
  return rows
end

-- Total need of one item for a character, across professions (including convertible partners).
function ns.NeedOf(c, itemID, directOnly)
  local n = 0
  local t = not directOnly and ns.ITEM_TRANSFORMS[itemID] or nil
  for _, need in pairs(c.needs or {}) do
    n = n + (need.items and need.items[itemID] or 0)
    if t then
      local pn = need.items and need.items[t.other]
      if pn and pn > 0 then
        n = n + (t.isSmall and (pn * t.ratio) or math.ceil(pn / t.ratio))
      end
    end
  end
  return n
end
