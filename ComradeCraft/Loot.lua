-- Loot: dungeon loot/roll helper & recipe-item tooltips.
-- On any recipe item (Pattern/Formula/Schematic/Plans) in loot rolls, bags, AH or vendors,
-- tells who in the group does not know it yet (and their skill). On START_LOOT_ROLL, prints
-- one concise chat hint if a rolled item is an unknown recipe or urgently needed by a friend.
local _, ns = ...
local L = ns.L

local Loot = {}
ns.Loot = Loot

-- Lazy index: [recipeItemID] = { spell, line, req } built from LibProfessionDB.
local recipeByItem
local function RecipeByItem()
  if recipeByItem then return recipeByItem end
  recipeByItem = {}
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  if not (lib and lib.GetRecipes) then return recipeByItem end
  local lines = {}
  for _, r in pairs(ns.Recipes or {}) do lines[r[1]] = true end
  for line in pairs(lines) do
    for spell, e in pairs(lib:GetRecipes(line) or {}) do
      if type(e) == "table" and e.itemId and e.itemId > 0 and not recipeByItem[e.itemId] then
        recipeByItem[e.itemId] = { spell = spell, line = line, req = e.requiredSkill or 0 }
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
        local has = c.known and c.known[info.line] and c.known[info.line][info.spell]
        local e = { key = key, class = c.class, prof = pname, rank = p.rank or 0, max = p.max or 0, req = info.req }
        if has then known[#known + 1] = e else unknown[#unknown + 1] = e end
      end
    end
  end
  if #unknown == 0 and #known == 0 then return nil end
  table.sort(unknown, function(a, b) return a.rank > b.rank end)
  table.sort(known, function(a, b) return a.key < b.key end)
  return { spell = info.spell, line = info.line, req = info.req, unknown = unknown, known = known }
end

-- Tooltip hook for recipe items (works on loot rolls, bags, vendors, AH, chat links).
function Loot.AddTooltip(tooltip, itemID)
  local st = Loot.RecipeStatus(itemID)
  if not st then return end
  tooltip:AddLine(" ")
  tooltip:AddLine("ComradeCraft", 1, 0.82, 0)
  for _, u in ipairs(st.unknown) do
    local canLearn = u.rank >= u.req
    local right = canLearn and L["can learn now"] or L["needs skill %d"]:format(u.req)
    tooltip:AddDoubleLine(
      L["Unknown by %s (%s %d/%d)"]:format(ns.ClassColored(u.key, u.class), u.prof, u.rank, u.max),
      right, 1, 1, 1, canLearn and 0.3 or 1, canLearn and 1 or 0.82, canLearn and 0.4 or 0.3)
  end
  if #st.known > 0 then
    local names = {}
    for _, k in ipairs(st.known) do names[#names + 1] = k.key:match("^[^-]+") or k.key end
    tooltip:AddLine(L["Known by %s"]:format(table.concat(names, ", ")), 0.6, 0.6, 0.6, true)
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
