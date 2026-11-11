-- Sources: where to get a recipe. LibProfessionDB gives the kinds and npc ids (trainer,
-- vendor, drop; from emulator databases, unconfirmed on Forever). With QuestieDB + Questie
-- loaded, npc positions are known; TomTom then places a waypoint on the nearest one.
local _, ns = ...
local L = ns.L

local KINDS = { "trainer", "vendor", "drop", "quest" }
local MAX_LIST = 3

local function Lib() return LibStub and LibStub("LibProfessionDB-1.0", true) end
local function NpcDB() return LibQuestieDB and LibQuestieDB.Npc end

local function ZoneDB()
  local ok, z = pcall(function() return QuestieLoader and QuestieLoader:ImportModule("ZoneDB") end)
  return ok and z and z.GetUiMapIdByAreaId and z or nil
end

local function ZoneName(areaId)
  local info = C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(areaId)
  return type(info) == "string" and info or nil
end

-- Trainers and vendors must be friendly to the player; nil = unknown (kept).
local function Friendly(npc)
  local db = NpcDB()
  if not (db and db.friendlyToFaction) then return true end
  if db.name and not db.name(npc) then return true end -- not in Questie: keep, unknown
  local f = db.friendlyToFaction(npc)
  if not f then return false end
  local mine = UnitFactionGroup and UnitFactionGroup("player")
  return f == "AH" or (f == "A" and mine == "Alliance") or (f == "H" and mine == "Horde")
end

local function PlayerPos()
  local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
  local x, y
  if pos then
    if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
  end
  return map, x and x * 100, y and y * 100
end

-- Distance in yards between the player and a place (uiMap, x, y in 0-100) through
-- HereBeDragons (embedded by TomTom): works across zones of a continent; nil if unknown.
local function HBD() return LibStub and LibStub("HereBeDragons-2.0", true) end
local function Distance(place, map, px, py)
  local hbd = HBD()
  if hbd and place.uiMap then
    local ok, wx, wy, inst = pcall(hbd.GetWorldCoordinatesFromZone, hbd, place.x / 100, place.y / 100, place.uiMap)
    local ok2, ox, oy, pinst = pcall(hbd.GetPlayerWorldPosition, hbd)
    if ok and ok2 and wx and ox and inst == pinst then return ((wx - ox) ^ 2 + (wy - oy) ^ 2) ^ 0.5 end
    if ok and ok2 and wx and ox then return 1e8 end -- other continent
  end
  if place.uiMap == map and px then return ((place.x - px) ^ 2 + (place.y - py) ^ 2) ^ 0.5 end
  return 1e9
end

-- Places of one npc: { { areaId, uiMap, x, y } } (x, y in 0-100), or {} without QuestieDB.
local function Places(npc)
  local db, zdb = NpcDB(), ZoneDB()
  local spawns = db and db.spawns and db.spawns(npc)
  local out = {}
  for areaId, list in pairs(type(spawns) == "table" and spawns or {}) do
    local ui = zdb and zdb:GetUiMapIdByAreaId(areaId)
    for _, p in ipairs(list) do
      if p[1] and p[1] >= 0 then out[#out + 1] = { areaId = areaId, uiMap = ui, x = p[1], y = p[2] } end
    end
  end
  return out
end

-- Where a recipe comes from: { kind = { total, list = { { npc, name, place } } } }, each list
-- sorted nearest first (same map as the player, by distance). nil when nothing is known.
function ns.RecipeSources(spell)
  local lib = Lib()
  local src = lib and lib.GetRecipeSources and lib:GetRecipeSources(spell)
  local r = ns.Recipes[spell]
  -- Trainers you visited of this profession (exact Forever positions) join the trainer list.
  local visited = {}
  if r and (src and src.trainer or ns.TrainerSeen(spell)) then
    for npc, t in pairs(ComradeCraftDB and ComradeCraftDB.trainerSpots or {}) do
      if t.line == r[1] then visited[#visited + 1] = { id = npc, name = t.name, visited = true,
        place = { uiMap = t.map, x = t.x, y = t.y } } end
    end
  end
  if not src and #visited == 0 then return nil end
  src = src or {}
  local map, px, py = PlayerPos()
  local out = {}
  for _, kind in ipairs(KINDS) do
    local list = src[kind] or (kind == "trainer" and #visited > 0 and {} or nil)
    if list then
      local entries = {}
      for _, e in ipairs(list) do
        local x = { id = e.id, name = e.name }
        if kind ~= "quest" then
          if (kind == "trainer" or kind == "vendor") and not Friendly(e.id) then x = nil end
          if x then
            local best, bestD
            for _, p in ipairs(Places(e.id)) do
              local d = Distance(p, map, px, py)
              if not best or d < bestD then best, bestD = p, d end
            end
            x.place, x.dist = best, bestD or 2e9
          end
        else
          local q = LibQuestieDB and LibQuestieDB.Quest and LibQuestieDB.Quest.name
          x.name = q and q(e.id) or x.name
        end
        if x then entries[#entries + 1] = x end
      end
      if kind == "trainer" then
        local seen = {}
        for _, e in ipairs(entries) do seen[e.id] = e end
        for _, v in ipairs(visited) do
          v.dist = Distance(v.place, map, px, py)
          if seen[v.id] then seen[v.id].visited, seen[v.id].place, seen[v.id].dist = true, v.place, v.dist
          else entries[#entries + 1] = v end
        end
      end
      table.sort(entries, function(a, b) return (a.dist or 0) < (b.dist or 0) end)
      if #entries > 0 then out[kind] = { total = math.max(list.total or 0, #entries), list = entries } end
    end
  end
  return next(out) and out or nil
end

local function PlaceText(x)
  if not (x.place) then return x.name or ("#" .. x.id) end
  local zone = x.place.areaId and ZoneName(x.place.areaId)
  if not zone and x.place.uiMap and C_Map and C_Map.GetMapInfo then
    local info = C_Map.GetMapInfo(x.place.uiMap)
    zone = info and info.name
  end
  if x.visited then zone = (zone or "?") .. ", " .. L["visited"] end
  return ("%s (%s %d, %d)"):format(x.name or ("#" .. x.id), zone or "?", x.place.x, x.place.y)
end

-- Tooltip lines for a recipe's sources (nearest first, "and N more").
function ns.AddSourceLines(tooltip, spell)
  local src = ns.RecipeSources(spell)
  tooltip:AddLine(" ")
  if not src then
    tooltip:AddLine(L["Where to get it: unknown."], 0.6, 0.6, 0.6)
    return
  end
  tooltip:AddLine(L["Where to get it:"], 1, 0.82, 0)
  for _, kind in ipairs(KINDS) do
    local s = src[kind]
    if s then
      local names = {}
      for i = 1, math.min(MAX_LIST, #s.list) do names[#names + 1] = PlaceText(s.list[i]) end
      local more = s.total - #names
      tooltip:AddDoubleLine(L[kind], table.concat(names, ", ") .. (more > 0 and (" " .. L["and %d more"]:format(more)) or ""),
        0.8, 0.8, 0.8, 1, 1, 1)
    end
  end
  local lib = Lib()
  if lib and lib.IsBorrowed and lib:IsBorrowed(spell, "sources") then
    tooltip:AddLine(L["Sources taken from another game version, unconfirmed on Forever."], 0.6, 0.6, 0.6, true)
  end
  if not NpcDB() then
    tooltip:AddLine(L["Install Questie for locations; TomTom for waypoints."], 0.6, 0.6, 0.6, true)
  elseif TomTom then
    tooltip:AddLine(L["Click: waypoint to the nearest one."], 0.5, 0.8, 1)
  end
end

-- Waypoint to the nearest known trainer/vendor/drop of a recipe (TomTom). Returns true if set.
function ns.WaypointRecipe(spell)
  local src = ns.RecipeSources(spell)
  local pick
  for _, kind in ipairs(KINDS) do
    local s = src and src[kind]
    for _, x in ipairs(s and s.list or {}) do
      if x.place and x.place.uiMap and (not pick or x.dist < pick.dist) then pick = x end
    end
    if pick then break end -- trainer first, then vendor, then drop
  end
  if not pick then
    ns.Print(L["No known location for %s."]:format(ns.SpellName(spell)))
    return false
  end
  if not (TomTom and TomTom.AddWaypoint) then
    ns.Print(L["%s: %s. Install TomTom for a waypoint."]:format(ns.SpellName(spell), PlaceText(pick)))
    return false
  end
  local ok = pcall(TomTom.AddWaypoint, TomTom, pick.place.uiMap, pick.place.x / 100, pick.place.y / 100,
    { title = ("%s: %s"):format(ns.SpellName(spell), pick.name or ""), persistent = false, from = "ComradeCraft" })
  ns.Log(("waypoint: spell %d npc %d map %s -> %s"):format(spell, pick.id, tostring(pick.place.uiMap), ok and "ok" or "error"))
  if ok then ns.Print(L["Waypoint: %s"]:format(PlaceText(pick))) end
  return ok
end
