-- Loot: dungeon loot/roll helper & recipe-item tooltips.
-- On any recipe item (Pattern/Formula/Schematic/Plans) in loot rolls, bags, AH or vendors,
-- tells who in the group does not know it yet (and their skill). On START_LOOT_ROLL, prints
-- one concise chat hint if a rolled item is an unknown recipe or urgently needed by a friend.
local _, ns = ...
local L = ns.L

local Loot = {}
ns.Loot = Loot

-- Lazy index: [recipeItemID] = { spell, line, req, isRankBook, targetCap } built from LibProfessionDB.
local recipeByItem
local function RecipeByItem()
  if recipeByItem then return recipeByItem end
  recipeByItem = {}
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  if not (lib and lib.GetRecipes) then return recipeByItem end
  local lines = { [185] = true, [129] = true, [356] = true }
  for _, r in pairs(ns.Recipes or {}) do lines[r[1]] = true end
  for line in pairs(lines) do
    for spell, e in pairs(lib:GetRecipes(line) or {}) do
      if type(e) == "table" and e.itemId and e.itemId > 0 and not recipeByItem[e.itemId] then
        local isBook = lib.skillRankBooks and lib.skillRankBooks[spell] and true or false
        local req = e.requiredSkill or 0
        recipeByItem[e.itemId] = { spell = spell, line = line, req = req,
          isRankBook = isBook, targetCap = isBook and (req + 100) or nil }
      end
    end
  end
  return recipeByItem
end

-- Pure: who in the group has the recipe's profession and does (or doesn't) know it.
function Loot.RecipeStatus(itemID)
  local info = itemID and RecipeByItem()[itemID]
  if not info then return nil end
  local unknown, known = {}, {}
  for key, c in pairs(ns.AllChars()) do
    for pname, p in pairs(c.professions or {}) do
      if p.skillLine == info.line then
        local has
        if info.isRankBook then
          has = (p.max or 0) >= (info.targetCap or 225)
        else
          has = c.known and c.known[info.line] and c.known[info.line][info.spell]
        end
        local locProf = ns.ProfName and ns.ProfName(info.line, pname) or pname
        local e = { key = key, class = c.class, prof = locProf, rank = p.rank or 0, max = p.max or 0, req = info.req }
        if has then known[#known + 1] = e else unknown[#unknown + 1] = e end
      end
    end
  end
  if #unknown == 0 and #known == 0 then return nil end
  table.sort(unknown, function(a, b) return a.rank > b.rank end)
  table.sort(known, function(a, b) return a.key < b.key end)
  return { spell = info.spell, line = info.line, req = info.req, isRankBook = info.isRankBook,
    unknown = unknown, known = known }
end

-- Tooltip hook for recipe items (works on loot rolls, bags, vendors, AH, chat links).
function Loot.AddTooltip(tooltip, itemID)
  local st = Loot.RecipeStatus(itemID)
  if not st then return end
  tooltip:AddLine(" ")
  tooltip:AddLine("ComradeCraft", 1, 0.82, 0)
  for _, u in ipairs(st.unknown) do
    local canLearn = u.rank >= u.req
    local right = canLearn and ("|cff40ff40* " .. L["can learn now"] .. "|r") or L["needs skill %d"]:format(u.req)
    tooltip:AddDoubleLine(
      L["Unknown by %s (%s %d/%d)"]:format(ns.ClassColored(u.key, u.class), u.prof, u.rank, u.max),
      right, canLearn and 0.85 or 1, 1, canLearn and 0.85 or 1,
      canLearn and 0.25 or 1, canLearn and 1 or 0.82, canLearn and 0.35 or 0.3)
  end
  if #st.known > 0 then
    local names = {}
    for _, k in ipairs(st.known) do names[#names + 1] = k.key:match("^[^-]+") or k.key end
    tooltip:AddLine(L["Known by %s"]:format(table.concat(names, ", ")), 0.6, 0.6, 0.6, true)
  end
  -- Show if the recipe crafts a BiS gear upgrade or spec-matched enchant for anyone in the group.
  local rec = ns.Recipes and ns.Recipes[st.spell]
  local prod = rec and rec[5]
  if prod and prod ~= 0 and ns.UpgradeFor then
    local ups = {}
    local bop = ns.IsBoP and ns.IsBoP(prod)
    for key, c in pairs(ns.AllChars()) do
      local okTarget = not bop or (c.professions and (function()
        for _, p in pairs(c.professions) do if p.skillLine == st.line then return true end end
      end)())
      if okTarget then
        local up, gain, how = ns.UpgradeFor(prod, c)
        if up and gain and gain > 0 then
          local tag = how == "pawn" and L["+%d with Pawn"]:format(math.floor(gain + 0.5))
            or how == "stats" and L["+%d score"]:format(math.floor(gain + 0.5))
            or L["+%d item levels"]:format(math.floor(gain + 0.5))
          ups[#ups + 1] = ("%s (%s)"):format(ns.ClassColored(key, c.class), tag)
        end
      end
    end
    if #ups > 0 then
      tooltip:AddLine(L["Crafts upgrade for: %s"]:format(table.concat(ups, ", ")), 0.4, 0.9, 1, true)
    end
  elseif rec and rec[1] == ns.ENCHANTING and ns.GearScore and ns.GearScore.ScoreEnchant then
    local who = {}
    for key, c in pairs(ns.AllChars()) do
      if ns.GearScore.ScoreEnchant(st.spell, c) > 0 then who[#who + 1] = ns.ClassColored(key, c.class) end
    end
    if #who > 0 then
      tooltip:AddLine(L["Useful enchant for: %s"]:format(table.concat(who, ", ")), 0.4, 0.9, 1, true)
    end
  end
  tooltip:Show()
end

-- Concise chat hint when a dungeon loot roll starts on a recipe or urgent material.
function Loot.OnRoll(rollID)
  local link = GetLootRollItemLink and GetLootRollItemLink(rollID)
  local id = link and tonumber(link:match("item:(%d+)"))
  if not id then return end
  local st = Loot.RecipeStatus(id)
  if st and #st.unknown > 0 then
    local who = {}
    for _, u in ipairs(st.unknown) do
      who[#who + 1] = ("%s (%s %d)"):format(u.key:match("^[^-]+") or u.key, u.prof, u.rank)
    end
    ns.Print(L["Loot roll: %s - unknown by %s"]:format(link, table.concat(who, ", ")))
    return
  end
  -- Urgent ("now") material needed by someone in the group.
  local urgent = {}
  for key, c in pairs(ns.AllChars()) do
    for _, r in ipairs(ns.NeedRows(c, id)) do
      if ns.Urgency(r.step) == "now" then
        urgent[#urgent + 1] = ("%s x%d"):format(key:match("^[^-]+") or key, r.n)
      end
    end
  end
  if #urgent > 0 then
    ns.Print(L["Loot roll: %s - needed now by %s"]:format(link, table.concat(urgent, ", ")))
  end
end

ns.On("START_LOOT_ROLL", function(rollID) Loot.OnRoll(rollID) end)
