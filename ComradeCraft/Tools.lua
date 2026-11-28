-- Tools (Blacksmith Hammer, Runed Rods) and stations (Anvil, Loom) recipes need, from the
-- client tables in Data/Recipes.lua; station spots from Data/Npcs.lua plus in-game sightings.
local _, ns = ...

local function Band(a, b) -- bitwise AND of two 32-bit masks (no bit library in tests)
  a, b = a % 4294967296, b % 4294967296
  local r, p = 0, 1
  while a > 0 and b > 0 do
    if a % 2 == 1 and b % 2 == 1 then r = r + p end
    a, b, p = math.floor(a / 2), math.floor(b / 2), p * 2
  end
  return r
end

-- Does a tool of category `have` do the job of `need`? Same type, and its mask covers need's
-- (a Gnomish Army Knife counts as a hammer; an Arcanite Rod as a Golden Rod).
function ns.ToolFits(have, need)
  if have == need then return true end
  local h, n = ns.ToolCategories and ns.ToolCategories[have], ns.ToolCategories and ns.ToolCategories[need]
  if not (h and n) or h[2] ~= n[2] then return false end
  local nm = n[3] % 4294967296
  return Band(h[3], n[3]) == nm
end

-- Does the character hold a tool for `req` (category id, or -itemID for an exact item)?
-- Bags, bank and mail count.
function ns.HasTool(c, req)
  for _, src in ipairs({ c and c.bags or {}, c and c.bank or {}, c and c.mail or {} }) do
    for item, n in pairs(src) do
      if n > 0 then
        if req < 0 and item == -req then return true end
        local cat = req > 0 and ns.ToolItems and ns.ToolItems[item]
        if cat and ns.ToolFits(cat, req) then return true end
      end
    end
  end
  return false
end

-- The basic item for a tool requirement and how to get it:
-- item, "craft", spell (a recipe makes it) or item, "vendor", price (copper or nil).
function ns.ToolSource(req)
  local item = req < 0 and -req or nil
  if not item then
    for id, cat in pairs(ns.ToolItems or {}) do
      if cat == req and (not item or id < item) then item = id end
    end
  end
  if not item then return nil end
  for spell, r in pairs(ns.Recipes or {}) do
    if r[5] == item then return item, "craft", spell end
  end
  local p = ns.ItemPrices and ns.ItemPrices[item]
  return item, "vendor", p and p[2] > 0 and p[2] or nil
end

-- Tools a recipe needs that the character lacks (requirements, in order).
function ns.MissingTools(c, spell, had)
  local out = {}
  for _, req in ipairs(ns.RecipeTools and ns.RecipeTools[spell] or {}) do
    if not (had and had[req]) and not ns.HasTool(c, req) then out[#out + 1] = req end
  end
  return out
end

-- Station name in the player's language (common ones translated; others in English).
local L = ns.L
local STATION_L = {
  ["Anvil"] = L["Anvil"], ["Forge"] = L["Forge"], ["Loom"] = L["Loom"], ["Cooking Fire"] = L["Cooking Fire"],
  ["Tanning Rack"] = L["Tanning Rack"], ["Spinning Wheel"] = L["Spinning Wheel"],
  ["Sewing Machine"] = L["Sewing Machine"], ["Master Forge"] = L["Master Forge"],
  ["Alchemy Lab"] = L["Alchemy Lab"], ["Iron Oven"] = L["Iron Oven"], ["Fermenter"] = L["Fermenter"],
  ["Black Anvil"] = L["Black Anvil"], ["Black Forge"] = L["Black Forge"],
}
function ns.StationName(focus)
  local en = ns.FocusNames and ns.FocusNames[focus]
  return en and (STATION_L[en] or en) or ("#" .. tostring(focus))
end

-- Known spots of a station: Data/Npcs.lua, then this account's and peers' sightings.
-- { { uiMap, x, y } } with x, y in 0-100.
function ns.StationSpots(focus)
  local out, seen = {}, {}
  local function Add(m, x, y)
    if not (m and x and y) then return end
    for _, s in ipairs(out) do
      if s.uiMap == m and math.abs(s.x - x) < 3 and math.abs(s.y - y) < 3 then return end
    end
    out[#out + 1] = { uiMap = m, x = x, y = y }
  end
  for _, s in ipairs(ns.StationData and ns.StationData[focus] or {}) do Add(s[1], s[2], s[3]) end
  local db = ComradeCraftDB
  for _, s in ipairs(db and db.stations and db.stations[focus] or {}) do Add(s[1], s[2], s[3]) end
  for _, p in pairs(db and db.foreverPeers or {}) do
    for _, s in ipairs(p.stations and p.stations[focus] or {}) do Add(s[1], s[2], s[3]) end
  end
  return out
end

-- A craft needing a station just succeeded: the player stands next to one. Saved once per spot.
local MAX_SPOTS = 40
function ns.ObserveStation(spell)
  local focus = ns.RecipeFocus and ns.RecipeFocus[spell]
  if not (focus and ComradeCraftDB and C_Map and C_Map.GetBestMapForUnit) then return end
  local map = C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return end
  local x, y
  if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
  if not (x and y) then return end
  x, y = math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10
  ComradeCraftDB.stations = ComradeCraftDB.stations or {}
  local list = ComradeCraftDB.stations[focus] or {}
  ComradeCraftDB.stations[focus] = list
  for _, s in ipairs(list) do
    if s[1] == map and math.abs(s[2] - x) < 3 and math.abs(s[3] - y) < 3 then return end
  end
  if #list < MAX_SPOTS then list[#list + 1] = { map, x, y } end
end

if ns.On then
  ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spell)
    if unit == "player" then ns.ObserveStation(spell) end
  end)
end
