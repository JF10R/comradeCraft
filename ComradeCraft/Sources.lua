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

local function CurrentSkillRank(line)
  local c = ComradeCraftDB and ComradeCraftDB.chars and ComradeCraftDB.chars[ns.CharKey()]
  for _, p in pairs(c and c.professions or {}) do
    if p.skillLine == line then return p.rank or 0 end
  end
end

local function TrainerDisqualified(npc, spell, line)
  if not ComradeCraftDB then return false end
  -- Visited trainer whose services were scanned: exclude if they didn't offer this recipe.
  local spot = ComradeCraftDB.trainerSpots and ComradeCraftDB.trainerSpots[npc]
  if spot and spot.scanned and spot.spells and not spot.spells[spell] then return true end
  -- Trainer who refused us ("You'll need more training...") at or above our current rank.
  local ref = ComradeCraftDB.trainerRefused and ComradeCraftDB.trainerRefused[npc]
  if ref and ref.line == line then
    local rank = CurrentSkillRank(line)
    if rank and rank <= (ref.rank or 0) then return true end
  end
  return false
end

-- True if at least one friendly trainer can teach `spell` right now; false if every known
-- friendly trainer was refused at current rank or scanned without offering it; nil if unknown.
function ns.HasEligibleTrainer(spell)
  local r = ns.Recipes[spell]
  if not r then return nil end
  for npc, t in pairs(ComradeCraftDB and ComradeCraftDB.trainerSpots or {}) do
    if t.scanned and t.spells and t.spells[spell] and not TrainerDisqualified(npc, spell, r[1]) then
      return true
    end
  end
  local lib = Lib()
  local src = lib and lib.GetRecipeSources and lib:GetRecipeSources(spell)
  local list = src and src.trainer
  if not (list and #list > 0) then return nil end
  local friendlySeen = 0
  for _, e in ipairs(list) do
    if Friendly(e.id) then
      friendlySeen = friendlySeen + 1
      if not TrainerDisqualified(e.id, spell, r[1]) then return true end
    end
  end
  if friendlySeen > 0 then return false end
  return nil
end

-- Where a recipe comes from: { kind = { total, list = { { npc, name, place } } } }, each list
-- sorted nearest first (same map as the player, by distance). nil when nothing is known.
function ns.RecipeSources(spell)
  local lib = Lib()
  local src = lib and lib.GetRecipeSources and lib:GetRecipeSources(spell)
  local r = ns.Recipes[spell]
  -- Trainers you visited who actually offered this recipe (exact Forever positions) join the list.
  local visited = {}
  if r and (src and src.trainer or ns.TrainerSeen(spell)) then
    for npc, t in pairs(ComradeCraftDB and ComradeCraftDB.trainerSpots or {}) do
      local teaches = t.scanned and (t.spells and t.spells[spell]) or (not t.scanned and t.line == r[1])
      if teaches and t.map and not TrainerDisqualified(npc, spell, r[1]) then
        visited[#visited + 1] = { id = npc, name = t.name, visited = true,
          place = { uiMap = t.map, x = t.x, y = t.y } }
      end
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
          if x and kind == "trainer" and r and TrainerDisqualified(e.id, spell, r[1]) then x = nil end
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
      elseif kind == "vendor" and ns.ForeverDB and ns.ForeverDB.Vendor then
        local rid = lib and lib.GetRecipeItem and lib:GetRecipeItem(spell)
        local fv = rid and ns.ForeverDB.Vendor(rid)
        if fv and fv.map then
          local fp = { uiMap = fv.map, x = fv.x or 50, y = fv.y or 50 }
          local fd = Distance(fp, map, px, py)
          local hit = false
          for _, e in ipairs(entries) do
            if e.id == fv.npc then e.visited, e.place, e.dist = true, fp, fd hit = true break end
          end
          if not hit then
            entries[#entries + 1] = { id = fv.npc or 0, name = fv.name, visited = true, place = fp, dist = fd }
          end
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
  local lib = Lib()
  local recipeItem = lib and lib.GetRecipeItem and lib:GetRecipeItem(spell)
  for _, kind in ipairs(KINDS) do
    local s = src[kind]
    if s then
      local names = {}
      for i = 1, math.min(MAX_LIST, #s.list) do names[#names + 1] = PlaceText(s.list[i]) end
      local more = s.total - #names
      local right = table.concat(names, ", ") .. (more > 0 and (" " .. L["and %d more"]:format(more)) or "")
      if kind == "drop" and ns.DropRateText then
        local rate = ns.DropRateText(recipeItem, spell)
        if rate then right = right .. (" (~%s)"):format(rate) end
      end
      tooltip:AddDoubleLine(L[kind], right, 0.8, 0.8, 0.8, 1, 1, 1)
    end
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

-- Quests that require a profession skill (QuestieDB): the Artisan quest of Cooking, First Aid
-- and Fishing requires 225 in it. One pass over every quest, in small batches across frames
-- (first call returns nil while it runs, then refreshes the window), indexed by "line:value".
local skillIndex, scanning = nil, false
local function ScanSkillQuests()
  local Q = LibQuestieDB and LibQuestieDB.Quest
  if scanning or not (Q and Q.GetAllIds and Q.requiredSkill) then return end
  scanning = true
  local ok, ids = pcall(Q.GetAllIds)
  ids = ok and ids or {}
  local index, i = {}, 1
  local function Step()
    local stop = math.min(#ids, i + 399)
    for k = i, stop do
      local okS, rs = pcall(Q.requiredSkill, ids[k])
      if okS and type(rs) == "table" and rs[1] and rs[2] then
        local key = rs[1] .. ":" .. rs[2]
        index[key] = index[key] or {}
        table.insert(index[key], ids[k])
      end
    end
    i = stop + 1
    if i <= #ids and C_Timer then
      C_Timer.After(0, Step)
    else
      skillIndex, scanning = index, false
      ns.Log(("quests: %d quest ids scanned for skill requirements"):format(#ids))
      ns.RequestRefresh()
    end
  end
  Step()
end

local function Band(a, b)
  if bit and bit.band then return bit.band(a, b) end
  local r, v = 0, 1
  while a > 0 and b > 0 do
    if a % 2 == 1 and b % 2 == 1 then r = r + v end
    a, b, v = math.floor(a / 2), math.floor(b / 2), v * 2
  end
  return r
end

-- Quests for the player's faction that need `value` in skill `line`: { { id, name, level,
-- npc, npcName, place, dist } }, nearest giver first. {} without Questie; nil while scanning.
function ns.SkillQuests(line, value)
  local Q = LibQuestieDB and LibQuestieDB.Quest
  if not (Q and Q.GetAllIds) then return {} end
  if not skillIndex then
    ScanSkillQuests()
    if not skillIndex then return nil end
  end
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  local masks = LibQuestieDB.Enum and LibQuestieDB.Enum.factionRaceMasks
  local mine = masks and faction and masks[faction]
  local map, px, py = PlayerPos()
  local out = {}
  for _, id in ipairs(skillIndex[line .. ":" .. value] or {}) do
    local races = Q.requiredRaces and Q.requiredRaces(id)
    if not (mine and races and races ~= 0 and Band(races, mine) == 0) then
      local q = { id = id, name = Q.name and Q.name(id) or ("#" .. id), level = Q.requiredLevel and Q.requiredLevel(id) }
      local by = Q.startedBy and Q.startedBy(id)
      for _, npc in ipairs(type(by) == "table" and by[1] or {}) do
        if Friendly(npc) then
          for _, p in ipairs(Places(npc)) do
            local d = Distance(p, map, px, py)
            if not q.dist or d < q.dist then
              q.npc, q.place, q.dist = npc, p, d
              q.npcName = NpcDB() and NpcDB().name and NpcDB().name(npc)
            end
          end
        end
      end
      out[#out + 1] = q
    end
  end
  table.sort(out, function(a, b) return (a.dist or 2e9) < (b.dist or 2e9) end)
  return out
end

-- Waypoint to a specific NPC ID (used for Expert/Artisan rank trainers), via QuestieDB + TomTom.
function ns.NpcPlace(npcId)
  if not npcId then return nil end
  local map, px, py = PlayerPos()
  local best, bestD
  for _, p in ipairs(Places(npcId)) do
    local d = Distance(p, map, px, py)
    if not best or d < bestD then best, bestD = p, d end
  end
  return best
end

function ns.WaypointNpc(npcId, label, fallbackZone, fallbackPlace)
  local place = ns.NpcPlace(npcId) or fallbackPlace
  if not (place and place.uiMap) then
    ns.Print(("%s (%s)"):format(label or ("#" .. tostring(npcId)), fallbackZone or "?"))
    return false
  end
  local where = PlaceText({ id = npcId, name = label, place = place })
  if not (TomTom and TomTom.AddWaypoint) then
    ns.Print(L["%s: %s. Install TomTom for a waypoint."]:format(label or "?", where))
    return false
  end
  local ok = pcall(TomTom.AddWaypoint, TomTom, place.uiMap, place.x / 100, place.y / 100,
    { title = label or where, persistent = false, from = "ComradeCraft" })
  if ok then ns.Print(L["Waypoint: %s"]:format(where)) end
  return ok
end

-- Waypoint to a quest giver found by ns.SkillQuests.
function ns.WaypointQuest(q)
  if not (q and q.place and q.place.uiMap) then
    ns.Print(L["No known location for %s."]:format(q and q.name or "?"))
    return false
  end
  local where = PlaceText({ id = q.npc, name = q.npcName, place = q.place })
  if not (TomTom and TomTom.AddWaypoint) then
    ns.Print(L["%s: %s. Install TomTom for a waypoint."]:format(q.name, where))
    return false
  end
  local ok = pcall(TomTom.AddWaypoint, TomTom, q.place.uiMap, q.place.x / 100, q.place.y / 100,
    { title = ("%s: %s"):format(q.name, q.npcName or ""), persistent = false, from = "ComradeCraft" })
  ns.Log(("waypoint: quest %d npc %s -> %s"):format(q.id, tostring(q.npc), ok and "ok" or "error"))
  if ok then ns.Print(L["Waypoint: %s"]:format(where)) end
  return ok
end
ns.SourcePlaceText = PlaceText
