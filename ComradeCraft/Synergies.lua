-- Synergies: cross-profession group recommendations.
--   1. Craft -> Disenchant: when a character's leveling plan crafts BoE green+ items whose
--      disenchant mats (dust/essence/shards) are needed by an enchanter/member in the group.
--   2. Raw -> Intermediate: when a character holds spare raw mats (e.g. Ore, Cloth) that a
--      crafter in the group can turn into an intermediate (Bars, Bolts) another member needs.
local _, ns = ...
local L = ns.L

local Synergies = {}
ns.Synergies = Synergies

local function ShortName(key) return key:match("^[^-]+") or key end

local function ItemName(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  return get and get(id) or ("item:" .. id)
end

-- Finds all active cross-profession synergies across the group (top useful first).
-- Returns { { kind = "de"|"craft", from, to, crafter, item, qty, spell, detail, score }, ... }.
function Synergies.Find()
  local chars = ns.AllChars()
  local out = {}
  -- Who in the group is an enchanter, and total group need per enchanting material.
  local enchanters = {}
  for key, c in pairs(chars) do
    for _, p in pairs(c.professions or {}) do
      if p.skillLine == ns.ENCHANTING then
        enchanters[#enchanters + 1] = { key = key, class = c.class, rank = p.rank or 0 }
      end
    end
  end
  table.sort(enchanters, function(a, b) return a.rank > b.rank end)

  -- 1. Craft -> Disenchant synergies from active leveling plans.
  if #enchanters > 0 and ns.DisenchantYield then
    local seen = {}
    for key, c in pairs(chars) do
      for _, need in pairs(c.needs or {}) do
        for _, step in ipairs(need.plan or {}) do
          local r = ns.Recipes[step.spell]
          local item = r and r[5]
          if item and item ~= 0 and not seen[key .. "|" .. item] and not (ns.IsBoP and ns.IsBoP(item)) then
            local yield = ns.DisenchantYield(item)
            if yield then
              local qty = math.max(1, math.ceil((step.crafts or 1) * math.max(1, r[6] or 1) - 1e-9))
              -- Check if any group member actually needs the yielded mats.
              local bestTo, matParts, score = nil, {}, 0
              for mat, perItem in pairs(yield) do
                for okey, oc in pairs(chars) do
                  local want = ns.NeedOf(oc, mat)
                  if want > 0 then
                    local est = math.floor(perItem * qty + 0.5)
                    if est > 0 then
                      score = score + math.min(est, want)
                      if not bestTo then bestTo = okey end
                      matParts[#matParts + 1] = ("~%d %s"):format(est, ItemName(mat))
                    end
                    break
                  end
                end
              end
              if score > 0 then
                seen[key .. "|" .. item] = true
                -- Prefer an enchanter who is not the crafter, else highest-rank enchanter.
                local target = enchanters[1].key
                for _, en in ipairs(enchanters) do
                  if en.key == bestTo then target = en.key break end
                end
                local tClass = chars[target] and chars[target].class
                local verb = target == key and L["Disenchant %dx %s (%s)"]
                  or L["Send %dx %s to %s to disenchant (%s)"]
                local detail = target == key
                  and verb:format(qty, ItemName(item), table.concat(matParts, ", "))
                  or verb:format(qty, ItemName(item), ShortName(target), table.concat(matParts, ", "))
                out[#out + 1] = {
                  kind = "de", from = key, fromClass = c.class, to = target, toClass = tClass,
                  item = item, qty = qty, spell = step.spell, detail = detail, score = score,
                }
              end
            end
          end
        end
      end
    end
  end

  -- 2. Raw -> Intermediate cross-player synergies (e.g. spare Ore -> Smelter -> Bar needed by Blacksmith).
  local producers = {} -- [outItem] = { { key, spell, rawItem, rawPer, outQty } }
  for key, c in pairs(chars) do
    for _, set in pairs(c.known or {}) do
      for spell in pairs(set) do
        local r = ns.Recipes[spell]
        if r and r[5] and r[5] ~= 0 and r[7] and #r[7] == 2 then -- single-reagent conversion (Ore->Bar, Cloth->Bolt, Leather)
          local outItem = r[5]
          producers[outItem] = producers[outItem] or {}
          producers[outItem][#producers[outItem] + 1] = {
            key = key, spell = spell, rawItem = r[7][1], rawPer = r[7][2], outQty = math.max(1, r[6] or 1),
          }
        end
      end
    end
  end
  local seenConv = {}
  for needKey, nc in pairs(chars) do
    for _, need in pairs(nc.needs or {}) do
      for outItem, want in pairs(need.items or {}) do
        if want > 0 and producers[outItem] then
          for _, p in ipairs(producers[outItem]) do
            if p.key ~= needKey and not seenConv[p.key .. "|" .. outItem .. "|" .. needKey] then
              local rawSupply = ns.GroupSupply(p.rawItem)
              local canMake = math.floor(rawSupply / p.rawPer) * p.outQty
              if canMake > 0 then
                local n = math.min(want, canMake)
                seenConv[p.key .. "|" .. outItem .. "|" .. needKey] = true
                out[#out + 1] = {
                  kind = "craft", from = p.key, fromClass = chars[p.key] and chars[p.key].class,
                  to = needKey, toClass = nc.class, item = outItem, qty = n, spell = p.spell,
                  detail = L["%s can craft %dx %s from group's %s for %s"]:format(
                    ShortName(p.key), n, ItemName(outItem), ItemName(p.rawItem), ShortName(needKey)),
                  score = n,
                }
                break
              end
            end
          end
        end
      end
    end
  end

  table.sort(out, function(a, b)
    if a.score ~= b.score then return a.score > b.score end
    return a.item < b.item
  end)
  return out
end

-- Helper for Plan step hints: returns an enchanter short name if this crafted item should be
-- sent to a group enchanter to disenchant instead of vendored.
function Synergies.DisenchantTarget(crafterKey, item)
  if not (item and item ~= 0 and ns.DisenchantYield) or (ns.IsBoP and ns.IsBoP(item)) then return nil end
  local yield = ns.DisenchantYield(item)
  if not yield then return nil end
  local chars = ns.AllChars()
  local enchanter, needed = nil, false
  for key, c in pairs(chars) do
    for _, p in pairs(c.professions or {}) do
      if p.skillLine == ns.ENCHANTING and (key ~= crafterKey or not enchanter) then enchanter = key end
    end
    for mat in pairs(yield) do
      if ns.NeedOf(c, mat) > 0 then needed = true end
    end
  end
  if needed and enchanter then return enchanter end
end
