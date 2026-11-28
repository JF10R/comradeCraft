-- FarmAdvice: gold-aware Buy vs Farm arbitrage + QuestieDB farm spots & TomTom waypoints.
-- Uses the player's current gold balance (GetMoney) and live/AH prices to tell at a glance
-- whether a material is cheap enough to buy or worth farming, with 1-click farm waypoints.
local _, ns = ...
local L = ns.L

local FarmAdvice = {}
ns.FarmAdvice = FarmAdvice

local function ZoneDB()
  local ok, z = pcall(function() return QuestieLoader and QuestieLoader:ImportModule("ZoneDB") end)
  return ok and z and z.GetUiMapIdByAreaId and z or nil
end

local function AreaName(areaId, uiMap)
  if areaId and C_Map and C_Map.GetAreaInfo then
    local n = C_Map.GetAreaInfo(areaId)
    if type(n) == "string" and n ~= "" then return n end
  end
  if uiMap and C_Map and C_Map.GetMapInfo then
    local info = C_Map.GetMapInfo(uiMap)
    if info and info.name then return info.name end
  end
end

-- Starting zones and capitals by areaId and uiMap: never sent to the other faction's.
local HORDE_START = { area = { [14] = true, [215] = true, [85] = true, [1637] = true, [1638] = true, [1497] = true },
  map = { [1411] = true, [1412] = true, [1420] = true, [1454] = true, [1456] = true, [1458] = true } }
local ALLIANCE_START = { area = { [12] = true, [1] = true, [141] = true, [1519] = true, [1537] = true, [1657] = true },
  map = { [1429] = true, [1426] = true, [1438] = true, [1453] = true, [1455] = true, [1457] = true } }

-- Finds the best QuestieDB farm spot (gathering node or mob drop) for `itemID`.
-- Returns { name, zone, uiMap, x, y, kind = "node"|"drop" } or nil without QuestieDB.
function FarmAdvice.Spot(itemID)
  local Q = LibQuestieDB
  if not (Q and Q.Item and itemID) then return nil end
  local zdb = ZoneDB()
  local myLvl = (UnitLevel and UnitLevel("player")) or 60
  local best, bestScore
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  local enemy = faction == "Alliance" and HORDE_START or faction == "Horde" and ALLIANCE_START
    or { area = {}, map = {} }
  local areas, nAreas, worst = {}, 0, nil

  local function TrySpawns(spawns, name, kind, lvl)
    if type(spawns) ~= "table" then return end
    for areaId, pts in pairs(spawns) do
      local p = type(pts) == "table" and pts[1]
      local uiMap = p and zdb and zdb:GetUiMapIdByAreaId(areaId)
      if p and p[1] and p[1] >= 0 and not (enemy.area[areaId] or enemy.map[uiMap or 0]) then
        -- Prefer nodes, level-appropriate mobs, then the zone with the most spawn points.
        local lvlPenalty = (lvl and lvl > myLvl + 3) and (lvl - myLvl) * 20 or 0
        local score = (kind == "node" and 0 or 50) + lvlPenalty + (uiMap and 0 or 500) - math.min(#pts, 40) * 0.5
        if not areas[areaId] then nAreas = nAreas + 1 end
        areas[areaId], worst = true, math.max(worst or score, score)
        if not best or score < bestScore then
          bestScore = score
          best = { name = name or "?", zone = AreaName(areaId, uiMap), uiMap = uiMap, x = p[1], y = p[2], kind = kind }
        end
      end
    end
  end

  if Q.Item.objectDrops and Q.Object then
    local objs = Q.Item.objectDrops(itemID)
    for i = 1, math.min(#(type(objs) == "table" and objs or {}), 8) do
      local oid = objs[i]
      local name = Q.Object.name and Q.Object.name(oid)
      TrySpawns(Q.Object.spawns and Q.Object.spawns(oid), name, "node", nil)
    end
  end
  if not best and Q.Item.npcDrops and Q.Npc then
    local npcs = Q.Item.npcDrops(itemID)
    for i = 1, math.min(#(type(npcs) == "table" and npcs or {}), 10) do
      local nid = npcs[i]
      local name = Q.Npc.name and Q.Npc.name(nid)
      local lvl = Q.Npc.minLevel and Q.Npc.minLevel(nid)
      TrySpawns(Q.Npc.spawns and Q.Npc.spawns(nid), name, "drop", lvl)
    end
  end
  if nAreas > 1 and worst == bestScore then return nil end -- every zone ties: no real pick
  return best
end

-- Gold-aware verdict for buying vs farming `qty` of `itemID`.
-- Returns { action = "buy"|"farm"|"either", cost, spot, label }.
function FarmAdvice.Evaluate(itemID, qty, playerGold)
  qty = math.max(1, qty or 1)
  local gold = playerGold or (GetMoney and GetMoney()) or 0
  local cost = ns.BuyCost and ns.BuyCost(itemID, qty) or nil
  local spot = FarmAdvice.Spot(itemID)
  if ns.IsVendorItem and ns.IsVendorItem(itemID) then
    return { action = "buy", cost = cost, label = "|cff40ff40" .. L["Vendor"] .. "|r" }
  end
  if not cost then
    return { action = spot and "farm" or "either", spot = spot,
      label = spot and ("|cff66ccff" .. L["Farm"] .. "|r") or "|cff9d9d9d?|r" }
  end
  -- Cheap if <= 5% of current gold (or under 25s and affordable): buying saves time.
  -- Expensive if > 15% of current gold or over current balance: farming recommended.
  if cost <= gold and (cost <= 2500 or (gold > 0 and cost <= gold * 0.05)) then
    return { action = "buy", cost = cost, spot = spot, label = "|cff40ff40" .. L["Buy"] .. "|r" }
  elseif cost > gold or (gold > 0 and cost > gold * 0.15) then
    local z = spot and spot.zone and (" (" .. spot.zone .. ")") or ""
    return { action = "farm", cost = cost, spot = spot,
      label = "|cffffa040" .. L["Farm"] .. "|r" .. (z ~= "" and ("|cff9d9d9d" .. z .. "|r") or "") }
  end
  return { action = "either", cost = cost, spot = spot, label = "|cffffd100" .. L["Buy/Farm"] .. "|r" }
end

-- Places a TomTom waypoint to the best farm spot for `itemID` (returns true if set).
function FarmAdvice.Waypoint(itemID)
  local spot = FarmAdvice.Spot(itemID)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local itemName = (get and get(itemID)) or ("item:" .. itemID)
  if not (spot and spot.uiMap) then
    ns.Print(L["No known farm location for %s."]:format(itemName))
    return false
  end
  if not (TomTom and TomTom.AddWaypoint) then
    ns.Print(L["Farm %s: %s (%s %d, %d)"]:format(itemName, spot.name, spot.zone or "?", spot.x, spot.y))
    return false
  end
  local ok = pcall(TomTom.AddWaypoint, TomTom, spot.uiMap, spot.x / 100, spot.y / 100,
    { title = ("%s (%s)"):format(itemName, spot.name), persistent = false, from = "ComradeCraft" })
  if ok then
    ns.Print(L["Waypoint: %s (%s %d, %d)"]:format(spot.name, spot.zone or "?", spot.x, spot.y))
  end
  return ok
end
