-- Tooltip: "Vez : besoin de 30" on items someone in ComradeCraftDB needs.
local _, ns = ...
local Print = ns.Print

function ns.ClassColored(key, class)
  local name = key:match("^[^-]+") or key
  local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  return color and ("|c%s%s|r"):format(color.colorStr, name) or name
end

local function AddNeeds(tooltip, itemID)
  if not (itemID and ComradeCraftDB and ComradeCraftDB.chars) then return end
  local rows, total = {}, 0
  for key, c in pairs(ns.AllChars()) do
    for _, r in ipairs(ns.NeedRows(c, itemID)) do
      rows[#rows + 1] = { key = key, class = c.class, prof = r.prof, n = r.n }
      total = total + r.n
    end
  end
  if #rows == 0 then return end
  table.sort(rows, function(a, b) return a.n > b.n end)
  tooltip:AddLine(" ")
  tooltip:AddLine("ComradeCraft", 1, 0.82, 0)
  for _, r in ipairs(rows) do
    tooltip:AddDoubleLine(("%s |cff9d9d9d%s|r"):format(ns.ClassColored(r.key, r.class), r.prof or ""),
      ns.L["needs %d"]:format(r.n), 1, 1, 1, 1, 0.82, 0.4)
  end
  if #rows > 1 then
    tooltip:AddDoubleLine(ns.L["Group total"], tostring(total), 0.8, 0.8, 0.8, 1, 0.82, 0)
  end
  tooltip:Show()
end
ns.AddNeeds = AddNeeds

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    if data and data.id then AddNeeds(tooltip, data.id) end
  end)
elseif GameTooltip then
  local function OnSetItem(tooltip)
    local _, link = tooltip:GetItem()
    local id = link and tonumber(link:match("item:(%d+)"))
    AddNeeds(tooltip, id)
  end
  for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
    if tt then tt:HookScript("OnTooltipSetItem", OnSetItem) end
  end
end

local function ItemName(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name = get and get(id)
  return name or ("item:" .. id)
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
function ns.OpenRecipe(spell)
  if InCombatLockdown and InCombatLockdown() then return end
  local T = C_TradeSkillUI
  local r = ns.Recipes[spell]
  if not (T and r) then return end
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


-- Human-readable text for one profession's need, shared by the window and /comrade needs.
-- Returns { status, plan = {lines}, used, vendor, blocked } (missing parts are nil).
function ns.DescribeNeed(p, c)
  local line = p.skillLine
  if ns.GATHERING[line] then
    return { status = ns.L["Gathering profession: levels by gathering, not crafting."] }
  end
  local known = line and c.known and c.known[line]
  local need = line and c.needs and c.needs[line]
  if not known then
    return { status = ns.L["Open this profession's window once so your recipes can be read."] }
  end
  if p.rank >= p.max then
    return { status = ns.L["At the cap (%d). Visit the trainer for the next rank."]:format(p.max) }
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
        (guessed and "~" or "") .. tostring(req or "?"), cost) }
  end
  for _, step in ipairs(need.plan or {}) do
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
      local text
      made[item] = true
      if toMake > 0 then
        text = ns.L["Craft %d %s (%s)"]:format(toMake, ItemName(item), ReagentList(sub, toMake / qty))
        if fromStock > 0 then text = text .. ns.L[" + %d from stock"]:format(fromStock) end
        local v, ok = MatsCost(sub, toMake / qty)
        stepCost, stepComplete = stepCost + v, stepComplete and ok
      else
        text = ns.L["%d %s from stock"]:format(fromStock, ItemName(item))
      end
      entries[#entries + 1] = { kind = "craft", spell = sub, item = item, text = text }
    end
    entries[#entries + 1] = { kind = "craft", spell = step.spell, item = ns.Recipes[step.spell][5],
      text = ns.L["Craft %dx %s (%s)"]:format(Up(step.crafts), SpellName(step.spell),
        ReagentList(step.spell, Up(step.crafts))) }
    local v, ok = MatsCost(step.spell, Up(step.crafts), made)
    stepCost, stepComplete = stepCost + v, stepComplete and ok
    local range = ("%d-%d"):format(step.from, step.to)
    if priced then
      range = range .. "  |cffb0b0b0" .. (stepComplete and "~" or ">") .. ns.Money(math.floor(stepCost)) .. "|r"
    end
    out.steps[#out.steps + 1] = { range = range, entries = entries }
    out.plan[#out.plan + 1] = range .. " :"
    for _, e in ipairs(entries) do out.plan[#out.plan + 1] = "  " .. e.text end
  end
  local k = need.knownOnly
  if k and k.reached < need.reached then
    out.knownOnly = ns.L["With only your current recipes, you would be stuck at %d."]:format(k.reached)
  end

  -- Total still to spend: missing mats (net of stock) + vendor reagents + known trainer costs.
  if priced then
    local total, complete = 0, true
    for _, list in ipairs({ need.items or {}, need.vendor or {} }) do
      for item, n in pairs(list) do
        local v = ns.BuyCost(item, n)
        if v then total = total + v else complete = false end
      end
    end
    for _, step in ipairs(out.steps) do
      for _, e in ipairs(step.entries) do
        if e.kind == "learn" then
          if e.copper then total = total + e.copper else complete = false end
        end
      end
    end
    out.cost = (complete and ns.L["Estimated cost: %s (%s prices)."]
      or ns.L["Estimated cost: at least %s (%s prices, some items have no price)."])
      :format(ns.Money(math.floor(total)), ns.PriceSourceName)
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
  return out
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
  end
end
