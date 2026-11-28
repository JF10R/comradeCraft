-- Needs: leveling planner (expected reagents to reach a profession cap) and
-- free bidirectional item conversions (3x Lesser <-> 1x Greater Essences).
-- Pure logic over ns.Recipes; no WoW API calls so it is testable offline.
local _, ns = ...

-- Free bidirectional right-click conversions (no profession required):
-- { smallID, bigID, ratio } means ratio x smallID <-> 1 x bigID.
local TRANSFORM_PAIRS = {
  { 10938, 10939, 3 }, -- Lesser <-> Greater Magic Essence
  { 10998, 11082, 3 }, -- Lesser <-> Greater Astral Essence
  { 11134, 11135, 3 }, -- Lesser <-> Greater Mystic Essence
  { 11174, 11175, 3 }, -- Lesser <-> Greater Nether Essence
  { 16202, 16203, 3 }, -- Lesser <-> Greater Eternal Essence
}
ns.ITEM_TRANSFORMS = {}
for _, p in ipairs(TRANSFORM_PAIRS) do
  ns.ITEM_TRANSFORMS[p[1]] = { other = p[2], ratio = p[3], isSmall = true }
  ns.ITEM_TRANSFORMS[p[2]] = { other = p[1], ratio = p[3], isSmall = false }
end

function ns.TransformPartner(itemID)
  local t = itemID and ns.ITEM_TRANSFORMS[itemID]
  if t then return t.other, t.ratio, t.isSmall end
end

-- Exact allocation of a convertible pair (ratio x small <-> 1 x big) with zero double-counting.
-- Direct matches are filled first; spare on either side covers deficits on the other.
-- Returns haveS, missS, spareS, haveB, missB, spareB.
function ns.PairBalance(ownS, ownB, needS, needB, ratio)
  local dS = math.min(ownS, needS)
  local remS, defS = ownS - dS, needS - dS
  local dB = math.min(ownB, needB)
  local remB, defB = ownB - dB, needB - dB
  if defB > 0 and remS >= ratio then
    local conv = math.min(defB, math.floor(remS / ratio))
    remS = remS - conv * ratio
    defB = defB - conv
  elseif defS > 0 and remB > 0 then
    local conv = math.min(remB, math.ceil(defS / ratio))
    remB = remB - conv
    defS = math.max(0, defS - conv * ratio)
  end
  local reserveS = defB > 0 and math.min(remS, defB * ratio) or 0
  return needS - defS, defS, remS - reserveS, needB - defB, defB, remB
end

-- Returns { { fromItem, fromQty, toItem, toQty }, ... } when crafting `qty` of `spell`
-- relies on right-clicking a convertible essence pair (3x Lesser <-> 1x Greater) in `stock`.
function ns.ConversionHints(spell, qty, stock)
  local r = ns.Recipes and ns.Recipes[spell]
  local reag = r and r[7]
  if not (reag and #reag > 0 and stock) then return {} end
  qty = math.max(1, qty or 1)
  local pairsReq, order = {}, {}
  for i = 1, #reag, 2 do
    local item, req = reag[i], reag[i + 1] * qty
    local t = ns.ITEM_TRANSFORMS[item]
    if t then
      local small = t.isSmall and item or t.other
      local e = pairsReq[small]
      if not e then
        e = { small = small, big = t.isSmall and t.other or item, ratio = t.ratio, reqS = 0, reqB = 0 }
        pairsReq[small] = e
        order[#order + 1] = e
      end
      if t.isSmall then e.reqS = e.reqS + req else e.reqB = e.reqB + req end
    end
  end
  local out = {}
  for _, e in ipairs(order) do
    local ownS, ownB = stock[e.small] or 0, stock[e.big] or 0
    local defB = e.reqB - ownB
    local defS = e.reqS - ownS
    if defB > 0 and (ownS - e.reqS) >= e.ratio then
      local conv = math.min(defB, math.floor((ownS - e.reqS) / e.ratio))
      if conv > 0 then
        out[#out + 1] = { fromItem = e.small, fromQty = conv * e.ratio, toItem = e.big, toQty = conv }
      end
    elseif defS > 0 and (ownB - e.reqB) > 0 then
      local conv = math.min(ownB - e.reqB, math.ceil(defS / e.ratio))
      if conv > 0 then
        out[#out + 1] = { fromItem = e.big, fromQty = conv, toItem = e.small, toQty = conv * e.ratio }
      end
    end
  end
  return out
end

function ns.FormatConversionHints(hints)
  if not (hints and #hints > 0) then return nil end
  local nameOf = ns.ItemName or function(id) return "item:" .. id end
  local parts = {}
  for _, h in ipairs(hints) do
    parts[#parts + 1] = ns.L["Right-click: %dx %s -> %dx %s"]:format(
      h.fromQty, nameOf(h.fromItem), h.toQty, nameOf(h.toItem))
  end
  return table.concat(parts, " | ")
end

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
-- stock (optional, "group" objective): { [itemID] = count } free to use; a step's cost counts
-- only the raw mats beyond what is left of it, and the chosen action uses it up.
-- breaks (optional): { [rank] = true } where a new step starts (rank caps crossed on the way).
function ns.ComputeNeeds(rank, target, known, allKnown, owned, learnable, mode, stock, breaks)
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
    if stock then
      -- Flat arrays for the inner loop: raw item ids, counts and values.
      a.ids, a.cnt, a.val = {}, {}, {}
      for item, c in pairs(a.raw) do
        a.ids[#a.ids + 1], a.cnt[#a.cnt + 1], a.val[#a.val + 1] = item, c, ns.ItemValue(item)
      end
    end
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
  local left -- stock not used yet by earlier points
  if stock then
    left = {}
    for item, n in pairs(stock) do left[item] = n end
  end
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
        if left then
          for j = 1, #a.ids do
            local id = a.ids[j]
            local need = a.cnt[j] * n
            local l = left[id] or 0
            local direct = l > 0 and (need < l and need or l) or 0
            if direct > 0 then cost = cost - direct * a.val[j] end
            local rem = need - direct
            if rem > 0 then
              local t = ns.ITEM_TRANSFORMS[id]
              local ol = t and left[t.other]
              if ol and ol > 0 then
                local avail = t.isSmall and (ol * t.ratio) or (ol / t.ratio)
                local conv = rem < avail and rem or avail
                if conv > 0 then cost = cost - conv * a.val[j] end
              end
            end
          end
        end
        local better
        if left then -- free stock: near-equal costs go to the faster recipe
          better = not best or cost < bestCost - 1e-6
            or (cost <= bestCost + 1e-6 and (n < bestN or (n == bestN and a.spell < best.spell)))
        else
          better = not best or cost < bestCost or (cost == bestCost and a.spell < best.spell)
        end
        if better then
          best, bestCost, bestN = a, cost, n
        end
      end
    end
    if not best then
      info.reason = topGain > 0 and "lowgain" or "grey"
      info.bestGain = topGain
      break
    end
    for item, c in pairs(best.raw) do
      local need = c * bestN
      acc[item] = (acc[item] or 0) + need
      if left then
        local l = left[item] or 0
        local direct = l > 0 and (need < l and need or l) or 0
        if direct > 0 then left[item] = l - direct end
        local rem = need - direct
        if rem > 0 then
          local t = ns.ITEM_TRANSFORMS[item]
          local ol = t and left[t.other]
          if ol and ol > 0 then
            local usedOther = t.isSmall and (rem / t.ratio) or (rem * t.ratio)
            left[t.other] = math.max(0, ol - usedOther)
          end
        end
      end
    end
    local b = math.floor(cur / ns.MILESTONE) * ns.MILESTONE
    local m = info.milestones[b] or { mats = 0, points = 0, vendor = 0, de = 0, ah = 0, best = 0 }
    info.milestones[b] = m
    m.mats, m.points, m.best = m.mats + best.mats * bestN, m.points + 1, m.best + best.resale * bestN
    m.vendor = m.vendor + best.back.vendor * bestN
    for _, k in ipairs({ "de", "ah" }) do
      if best.back[k] then m[k] = m[k] + best.back[k] * bestN else m[k .. "Missing"] = true end
    end
    local last = plan[#plan]
    if not (last and last.spell == best.spell and not (breaks and breaks[cur])) then
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
-- Skips recipes the user skipped, recipes absent from a scanned trainer of that skill tier,
-- or recipes with no eligible friendly trainer left (e.g. refused at current rank).
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
  local skipped = ComradeCraftDB and ComradeCraftDB.skippedLearn or {}
  local spots = ComradeCraftDB and ComradeCraftDB.trainerSpots or {}
  local refused = ComradeCraftDB and ComradeCraftDB.trainerRefused or {}
  -- Highest recipe rank actually seen on a scanned trainer of this profession on Forever.
  local maxScannedReq, seenOnTrainer = 0, {}
  for _, t in pairs(spots) do
    if t.scanned and t.line == line then
      if (t.maxReq or 0) > maxScannedReq then maxScannedReq = t.maxReq end
      for sp in pairs(t.spells or {}) do seenOnTrainer[sp] = true end
    end
  end
  -- If a trainer of this profession refused us ("You'll need more training...") at `refRank`,
  -- unconfirmed recipes with req <= refRank cannot be learned yet: defer them to the next
  -- Classic/Forever trainer tier (50, 125, 200, 275) so the planner levels us there with known crafts!
  local deferUntil = 0
  for _, rf in pairs(refused) do
    if rf.line == line and (rf.rank or 0) > 0 then
      local nextTier = (rf.rank < 50 and 50) or (rf.rank < 125 and 125)
        or (rf.rank < 200 and 200) or (rf.rank < 275 and 275) or (rf.rank + 10)
      if nextTier > deferUntil then deferUntil = nextTier end
    end
  end
  for spell, req in pairs(out) do
    if req > maxRank or skipped[spell] then
      out[spell] = nil
    elseif maxScannedReq >= req and not seenOnTrainer[spell] then
      -- A scanned trainer of this skill tier didn't offer it on Forever.
      out[spell] = nil
    elseif ns.HasEligibleTrainer and ns.HasEligibleTrainer(spell) == false then
      out[spell] = nil
    elseif deferUntil > 0 and not seenOnTrainer[spell] and req < deferUntil then
      if deferUntil <= maxRank then out[spell] = deferUntil else out[spell] = nil end
    end
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

-- Skill to plan for in a profession: your local target for a friend (kit), else the character's
-- own target (synced), while above the current rank; else the current cap. Max ns.MAX_SKILL.
ns.MAX_SKILL = 300
function ns.TargetFor(c, p)
  local line = p and p.skillLine
  local t = c and line and (c.localTargets and c.localTargets[line] or c.targets and c.targets[line])
  if t and p.rank and t > p.rank then return math.min(t, ns.MAX_SKILL) end
  return p and p.max
end

-- Rank caps a plan from `cap` to `target` crosses: { 150, 225 } for 150 -> 260.
function ns.RankCaps(cap, target)
  local out = {}
  if not (cap and target) or cap < 75 then return out end
  local c = cap
  while c < target and c < ns.MAX_SKILL do out[#out + 1] = c c = c + 75 end
  return out
end

-- Sets a target (nil = back to the current cap). A friend's target stays on your side only.
function ns.SetTarget(key, line, value)
  local c = ComradeCraftDB.chars and ComradeCraftDB.chars[key]
  local field = "targets"
  if not c then
    c = ComradeCraftDB.remote and ComradeCraftDB.remote[key]
    field = "localTargets"
  end
  if not (c and line) then return end
  local p
  for _, x in pairs(c.professions or {}) do if x.skillLine == line then p = x end end
  if not p then return end
  value = tonumber(value)
  value = value and math.min(math.floor(value), ns.MAX_SKILL)
  if value and value <= (p.rank or 0) then value = nil end
  c[field] = c[field] or {}
  c[field][line] = value
  if not next(c[field]) then c[field] = nil end
  if field == "targets" then c.updated = time() end -- peers pick up the change with the next sync
  ns.UpdateNeeds(c)
  ns.RequestRefresh()
end

-- Group plan objective, chosen in Manage group > Options: "group" (default) = least gold spent
-- by the group, stock already held in the group is free; "solo" = market value for everything.
function ns.GroupObjective()
  local s = ComradeCraftDB and ComradeCraftDB.settings
  return s and s.groupObjective == "solo" and "solo" or "group"
end

-- Stores the objective and recomputes every character's needs.
function ns.SetGroupObjective(v)
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  ComradeCraftDB.settings.groupObjective = v == "solo" and "solo" or "group"
  for _, c in pairs(ns.AllChars()) do ns.UpdateNeeds(c) end
  ns.RequestRefresh()
end

-- Free stock for c under the "group" objective: its own bags + bank, plus what every other
-- character can spare (ns.Surplus). Vendor items left out. { [itemID] = count }.
function ns.GroupStock(c)
  local stock = {}
  local function Add(item, n)
    if n > 0 and not ns.IsVendorItem(item) then stock[item] = (stock[item] or 0) + n end
  end
  for _, src in ipairs({ c.bags or {}, c.bank or {}, c.mail or {} }) do
    for item, n in pairs(src) do Add(item, n) end
  end
  for _, o in pairs(ns.AllChars()) do
    if o ~= c then
      local seen = {}
      for _, src in ipairs({ o.bags or {}, o.bank or {} }) do
        for item in pairs(src) do
          if not seen[item] then
            seen[item] = true
            if not ns.IsBoP(item) then Add(item, ns.Surplus(o, item)) end
          end
        end
      end
    end
  end
  return stock
end

-- Recomputes c.needs[skillLine] for one character record (rank -> target, minus owned).
-- Shared bank alts never reserve materials for leveling: all of their stock is group surplus.
-- Deducts consumed stock across multiple professions on the same character so shared mats
-- (e.g. Tailoring + First Aid cloth, Blacksmithing + Engineering bars) are never double-counted.
function ns.UpdateNeeds(c)
  c.needs = {}
  if c.bankAlt then
    if ns.ClearGiveCache then ns.ClearGiveCache() end
    return
  end
  if not (c.professions and c.known) then return end
  local foundKey
  for key, ch in pairs(ns.AllChars and ns.AllChars() or {}) do
    if ch == c then foundKey = key break end
  end
  local all = {}
  for _, set in pairs(c.known) do
    for spell in pairs(set) do all[spell] = true end
  end
  local owned = {}
  for _, src in ipairs({ c.bags or {}, c.bank or {}, c.mail or {} }) do
    for item, n in pairs(src) do owned[item] = (owned[item] or 0) + n end
  end
  -- Count active incoming peer mail (1h delay) as owned so nobody double-farms/double-mails.
  if foundKey and ns.InTransitFor then
    local _, tlist = ns.InTransitFor(foundKey)
    for _, tr in ipairs(tlist or {}) do
      owned[tr.item] = (owned[tr.item] or 0) + (tr.qty or 0)
    end
  end
  local baseStock = ns.GroupObjective() == "group" and ns.GroupStock(c) or nil
  local remOwned, remStock = {}, nil
  for item, n in pairs(owned) do remOwned[item] = n end
  if baseStock then
    remStock = {}
    for item, n in pairs(baseStock) do remStock[item] = n end
  end
  local profList = {}
  for name, p in pairs(c.professions) do
    local known = p.skillLine and c.known[p.skillLine]
    -- A target the rank has caught up with goes back to the default (the cap).
    for _, f in ipairs({ "targets", "localTargets" }) do
      local t = c[f]
      if t and p.skillLine and t[p.skillLine] and p.rank and t[p.skillLine] <= p.rank then
        t[p.skillLine] = nil
        if not next(t) then c[f] = nil end
      end
    end
    local target = ns.TargetFor(c, p)
    if known and p.rank and target and p.rank < target and not ns.GATHERING[p.skillLine] then
      profList[#profList + 1] = { name = name, p = p, known = known }
    end
  end
  table.sort(profList, function(a, b) return (a.p.skillLine or 0) < (b.p.skillLine or 0) end)
  for _, entry in ipairs(profList) do
    local name, p, known = entry.name, entry.p, entry.known
    -- Route "with what you know" (kept as a summary) and route "optimal" (also learns
    -- trainer recipes on the way, like leveling guides do). Needs follow the optimal one.
    local target = ns.TargetFor(c, p)
    local caps = ns.RankCaps(p.max, target)
    local breaks
    for _, cap in ipairs(caps) do breaks = breaks or {} breaks[cap] = true end
    local learnable = ns.TrainerRecipes(p.skillLine, target, known)
    local mode = ns.RouteMode(c)
    local other = mode == "profit" and "cheap" or "profit"
    local _, kReached, _, kInfo = ns.ComputeNeeds(p.rank, target, known, all, remOwned, nil, mode, remStock, breaks)
    local gross, reached, plan, info = ns.ComputeNeeds(p.rank, target, known, all, remOwned, learnable, mode, remStock, breaks)
    local oGross, oReached, _, oInfo = ns.ComputeNeeds(p.rank, target, known, all, remOwned, learnable, other, remStock, breaks)
    -- Other route's missing mats, against what is left before this route takes its share
    -- (no Lesser/Greater conversion: close enough for the comparison).
    local oItems = {}
    for item, n in pairs(oGross) do
      local m = n - (remOwned[item] or 0)
      if m > 0 then oItems[item] = m end
    end
    local net, vendor, have, handled = {}, {}, {}, {}
    for item, n in pairs(gross) do
      if not handled[item] then
        local t = ns.ITEM_TRANSFORMS[item]
        if t then
          local small = t.isSmall and item or t.other
          local big = t.isSmall and t.other or item
          handled[small], handled[big] = true, true
          local nS, nB = gross[small] or 0, gross[big] or 0
          local hS, mS, spS, hB, mB, spB = ns.PairBalance(remOwned[small] or 0, remOwned[big] or 0, nS, nB, t.ratio)
          remOwned[small], remOwned[big] = spS, spB
          if remStock then
            local _, _, rsS, _, _, rsB = ns.PairBalance(remStock[small] or 0, remStock[big] or 0, nS, nB, t.ratio)
            remStock[small], remStock[big] = rsS, rsB
          end
          if nS > 0 then
            have[small] = hS
            if mS > 0 then
              if ns.IsVendorItem(small) then vendor[small] = mS else net[small] = mS end
            end
          end
          if nB > 0 then
            have[big] = hB
            if mB > 0 then
              if ns.IsVendorItem(big) then vendor[big] = mB else net[big] = mB end
            end
          end
        else
          local avail = remOwned[item] or 0
          have[item] = avail
          remOwned[item] = math.max(0, avail - n)
          if remStock then remStock[item] = math.max(0, (remStock[item] or 0) - n) end
          if n > avail then
            if ns.IsVendorItem(item) then vendor[item] = n - avail else net[item] = n - avail end
          end
        end
      end
    end
    for item, u in pairs(info.used or {}) do
      remOwned[item] = math.max(0, (remOwned[item] or 0) - u)
      if remStock then remStock[item] = math.max(0, (remStock[item] or 0) - u) end
    end
    c.needs[p.skillLine] = { name = name, items = net, vendor = vendor, gross = gross, have = have,
      reached = reached, target = target, cap = p.max, rankCaps = caps, plan = plan, reason = info.reason,
      bestGain = info.bestGain, used = info.used, when = FirstStepOf(plan),
      knownOnly = { reached = kReached, reason = kInfo.reason },
      mode = mode, milestones = info.milestones,
      alt = { mode = other, reached = oReached, milestones = oInfo.milestones, gross = oGross, items = oItems } }
  end
  if ns.Wishlist and ns.Wishlist.InjectNeeds and foundKey then
    ns.Wishlist.InjectNeeds(c, foundKey)
  end
  if ns.ClearGiveCache then ns.ClearGiveCache() end
end
