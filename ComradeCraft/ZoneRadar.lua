-- ZoneRadar: answers "What is useful for my group in THIS zone or dungeon right now?"
-- Surfaces local vendors/rank books, rare mob drops & unlearned BiS patterns, and farmable
-- group materials in your current map, with drop rates and 1-click TomTom waypoints.
local _, ns = ...
local L = ns.L

local Radar = {}
ns.ZoneRadar = Radar

local ALERT_COOLDOWN = 600 -- seconds per zone before re-toasting on entry
local lastZoneAlert = {}

local function NpcDB() return LibQuestieDB and LibQuestieDB.Npc end
local function ItemDB() return LibQuestieDB and LibQuestieDB.Item end
local function ZoneDB()
  local ok, z = pcall(function() return QuestieLoader and QuestieLoader:ImportModule("ZoneDB") end)
  return ok and z and z.GetUiMapIdByAreaId and z or nil
end

local function MapName(uiMap)
  if uiMap and C_Map and C_Map.GetMapInfo then
    local info = C_Map.GetMapInfo(uiMap)
    if info and info.name then return info.name end
  end
  return GetZoneText and GetZoneText() or ("Zone " .. tostring(uiMap or "?"))
end

-- Returns { x, y } for `npcID` inside `uiMap` (or nil if this NPC does not spawn in `uiMap`),
-- plus `isRare` (true when QuestieDB marks the mob as Rare=2 or Rare-Elite=4).
local function SpawnInMap(npcID, uiMap)
  local ndb, zdb = NpcDB(), ZoneDB()
  if not (ndb and ndb.spawns and zdb) then return nil end
  local spawns = ndb.spawns(npcID)
  if type(spawns) ~= "table" then return nil end
  for areaId, pts in pairs(spawns) do
    local ui = zdb:GetUiMapIdByAreaId(areaId)
    if ui == uiMap and type(pts) == "table" and pts[1] and pts[1][1] and pts[1][1] >= 0 then
      local rank = ndb.rank and ndb.rank(npcID)
      local isRare = (rank == 2 or rank == 4) and true or false
      local name = ndb.name and ndb.name(npcID) or ("#" .. tostring(npcID))
      return { x = pts[1][1], y = pts[1][2], name = name, rare = isRare }
    end
  end
end

local function FriendlyNpc(npcID)
  local ndb = NpcDB()
  if not (ndb and ndb.friendlyToFaction) then return true end
  local f = ndb.friendlyToFaction(npcID)
  if not f then return true end
  local mine = UnitFactionGroup and UnitFactionGroup("player")
  return f == "AH" or (f == "A" and mine == "Alliance") or (f == "H" and mine == "Horde")
end

-- Pure: scans `uiMap` (defaults to current player map) for everything useful to the group:
--   kind = "rare" | "vendor" | "pattern" | "mat"
-- Returns list sorted by priority (rare -> vendor -> pattern -> mat), and zone name.
function Radar.Scan(uiMap)
  uiMap = uiMap or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
  if not uiMap then return {}, nil end
  local zoneName = MapName(uiMap)
  local out, seen = {}, {}
  local chars = ns.AllChars and ns.AllChars() or {}
  local mineFaction = UnitFactionGroup and UnitFactionGroup("player")

  local function Push(key, entry)
    if seen[key] then return end
    seen[key] = true
    entry.uiMap = uiMap
    entry.zone = zoneName
    out[#out + 1] = entry
  end

  -- 1. Expert/Artisan rank book vendors & trainers in this zone needed by someone in the group.
  if type(ns.RANK_TRAINERS) == "table" then
    local fcode = mineFaction == "Alliance" and "A" or (mineFaction == "Horde" and "H" or nil)
    for cap, byLine in pairs(ns.RANK_TRAINERS) do
      local nextCap = cap + 75
      for line, npcs in pairs(byLine) do
        local who = {}
        for ckey, c in pairs(chars) do
          for _, p in pairs(c.professions or {}) do
            if p.skillLine == line and (p.max or 0) <= cap and (p.rank or 0) >= cap - 50 then
              who[#who + 1] = ckey:match("^[^-]+") or ckey
            end
          end
        end
        if #who > 0 then
          for _, t in ipairs(npcs) do
            local place = t[5]
            if place and place.uiMap == uiMap and (t[4] == "AH" or not fcode or t[4] == fcode) then
              local label = (ns.ProfName and ns.ProfName(line) or tostring(line)) .. " (" .. nextCap .. ")"
              Push("rt:" .. tostring(t[1] or t[2]) .. ":" .. line .. ":" .. nextCap, {
                kind = "vendor", prio = 2, item = 0, npc = t[1], npcName = t[2],
                x = place.x, y = place.y, label = label, who = table.concat(who, ", "),
              })
            end
          end
        end
      end
    end
  end

  -- 2. Verified ForeverDB vendors in this zone selling recipes unknown by someone in the group.
  if ns.ForeverDB and ns.ForeverDB.AllVendors and ns.Loot and ns.Loot.RecipeStatus then
    for itemID, v in pairs(ns.ForeverDB.AllVendors()) do
      if v.map == uiMap then
        local st = ns.Loot.RecipeStatus(itemID)
        if st and st.unknown and #st.unknown > 0 then
          local who = {}
          for i = 1, math.min(3, #st.unknown) do who[#who + 1] = st.unknown[i].key:match("^[^-]+") or st.unknown[i].key end
          Push("fv:" .. itemID, {
            kind = "vendor", prio = 2, item = itemID, npc = v.npc, npcName = v.name,
            x = v.x, y = v.y, label = ns.ItemName and ns.ItemName(itemID) or ("item:" .. itemID),
            who = table.concat(who, ", "),
          })
        end
      end
    end
  end

  -- 3. Unlearned BiS patterns (for self or group) whose vendor, rare mob, or targeted drop is in `uiMap`.
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  local patSpells = {}
  local meKey = ns.CharKey and ns.CharKey()
  if meKey and ns.Audit and ns.Audit.PatternsForCrafter then
    for _, p in ipairs(ns.Audit.PatternsForCrafter(meKey)) do
      patSpells[p.spell] = p
    end
  end
  if ns.Audit and ns.Audit.Run then
    for _, grp in ipairs(ns.Audit.Run()) do
      for _, p in ipairs(grp.patterns or {}) do
        if not patSpells[p.spell] then
          patSpells[p.spell] = {
            spell = p.spell, item = p.item, recipeItem = p.recipeItem,
            forList = { { key = grp.targetKey } },
          }
        end
      end
    end
  end
  for spell, p in pairs(patSpells) do
    local src = lib and lib.GetRecipeSources and lib:GetRecipeSources(spell)
    if src then
      local who = {}
      for i = 1, math.min(3, #(p.forList or {})) do
        who[#who + 1] = p.forList[i].key:match("^[^-]+") or p.forList[i].key
      end
      local whoTxt = table.concat(who, ", ")
      local patLabel = (p.item and p.item ~= 0 and ns.ItemName and ns.ItemName(p.item)) or ns.SpellName(spell)
      -- Vendors in this zone
      for _, e in ipairs(src.vendor or {}) do
        if FriendlyNpc(e.id) then
          local sp = SpawnInMap(e.id, uiMap)
          if sp then
            Push("pv:" .. spell .. ":" .. e.id, {
              kind = "vendor", prio = 2, spell = spell, item = p.recipeItem or p.item or 0,
              npc = e.id, npcName = sp.name, x = sp.x, y = sp.y, label = patLabel, who = whoTxt,
            })
          end
        end
      end
      -- Rare mobs or targeted drops (<= 30 mobs) in this zone
      local drops = src.drop
      if drops and #drops > 0 and (drops.total or #drops) <= 30 then
        local rate = ns.DropRateText and ns.DropRateText(p.recipeItem, spell)
        for _, e in ipairs(drops) do
          local sp = SpawnInMap(e.id, uiMap)
          if sp then
            Push("pd:" .. spell .. ":" .. e.id, {
              kind = sp.rare and "rare" or "pattern", prio = sp.rare and 1 or 3,
              spell = spell, item = p.recipeItem or p.item or 0,
              npc = e.id, npcName = sp.name, rare = sp.rare,
              x = sp.x, y = sp.y, rate = rate, label = patLabel, who = whoTxt,
            })
            break -- one representative spawn per pattern in this zone
          end
        end
      end
    end
  end

  -- 4. Peer/local observed Forever rare drops in this zone.
  if ns.ForeverDB and ns.ForeverDB.ObservedDropsInMap then
    for _, d in ipairs(ns.ForeverDB.ObservedDropsInMap(uiMap)) do
      if d.rare then
        local rate = d.k >= 10 and (("%.1f%%"):format(math.min(100, d.d * 100 / d.k))) or nil
        Push("fd:" .. d.item .. ":" .. (d.npc or 0), {
          kind = "rare", prio = 1, item = d.item, npc = d.npc, npcName = d.name or "Rare",
          rare = true, x = d.x, y = d.y, rate = rate,
          label = ns.ItemName and ns.ItemName(d.item) or ("item:" .. d.item),
          who = L["Group"],
        })
      end
    end
  end

  -- 5. Group-needed non-vendor materials dropped by mobs in this zone (including Rare bonus drops).
  local idb = ItemDB()
  if idb and idb.npcDrops and ns.GroupPlan then
    local plan = ns.GroupPlan()
    local matHits = 0
    for _, row in ipairs(plan) do
      if matHits >= 6 then break end
      if (row.toGet or 0) > 0 and not (ns.IsVendorItem and ns.IsVendorItem(row.item)) then
        local npcs = idb.npcDrops(row.item)
        if type(npcs) == "table" then
          local best
          for i = 1, math.min(#npcs, 40) do
            local sp = SpawnInMap(npcs[i], uiMap)
            if sp then
              if not best or (sp.rare and not best.rare) then best = { id = npcs[i], sp = sp } end
              if sp.rare then break end
            end
          end
          if best then
            local who = {}
            for i = 1, math.min(2, #(row.by or {})) do
              who[#who + 1] = row.by[i].key:match("^[^-]+") or row.by[i].key
            end
            Push("mat:" .. row.item, {
              kind = best.sp.rare and "rare" or "mat", prio = best.sp.rare and 1 or 4,
              item = row.item, n = row.toGet, npc = best.id, npcName = best.sp.name,
              rare = best.sp.rare, x = best.sp.x, y = best.sp.y,
              label = ("%dx %s"):format(row.toGet, ns.ItemName and ns.ItemName(row.item) or ("item:" .. row.item)),
              who = table.concat(who, ", "),
            })
            matHits = matHits + 1
          end
        end
      end
    end
  end

  table.sort(out, function(a, b)
    if a.prio ~= b.prio then return a.prio < b.prio end
    return (a.label or "") < (b.label or "")
  end)
  return out, zoneName
end

-- Places a TomTom waypoint on a ZoneRadar entry.
function Radar.Waypoint(e)
  if not (e and e.uiMap and e.x and e.y) then return false end
  local title = ("%s (%s)"):format(e.npcName or "?", e.label or "ComradeCraft")
  if TomTom and TomTom.AddWaypoint then
    local ok = pcall(TomTom.AddWaypoint, TomTom, e.uiMap, e.x / 100, e.y / 100,
      { title = title, persistent = false, from = "ComradeCraft" })
    if ok then
      ns.Print(L["Waypoint: %s"]:format(("%s (%s %d, %d)"):format(e.npcName or "?", e.zone or "?", e.x, e.y)))
      return true
    end
  end
  ns.Print(L["%s: %s. Install TomTom for a waypoint."]:format(
    e.label or "ComradeCraft", ("%s (%s %d, %d)"):format(e.npcName or "?", e.zone or "?", e.x, e.y)))
  return false
end

local function OnZoneChanged()
  if not ComradeCraftDB then return end
  if ns.Alerts and ns.Alerts.On and not ns.Alerts.On("zone") then return end
  local uiMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  if not uiMap then return end
  local now = time()
  if now - (lastZoneAlert[uiMap] or 0) < ALERT_COOLDOWN then return end
  local hits, zoneName = Radar.Scan(uiMap)
  -- Only toast automatically for high-value hits (rare mob, vendor/rank book, or BiS pattern).
  local top
  for _, h in ipairs(hits) do
    if h.kind == "rare" or h.kind == "vendor" or h.kind == "pattern" then top = h break end
  end
  if not top then return end
  lastZoneAlert[uiMap] = now
  if ns.Alerts and ns.Alerts.Notify then
    local tag = top.rare and "[Rare] " or ""
    local rate = top.rate and (" (~" .. top.rate .. ")") or ""
    ns.Alerts.Notify({
      title = L["In %s: %s"]:format(zoneName or "?", top.label or ""),
      text = ("%s%s (%d, %d)%s - %s"):format(tag, top.npcName or "?", top.x or 0, top.y or 0, rate, top.who or ""),
      item = top.item and top.item > 0 and top.item or nil,
      buttons = { { L["Waypoint"], function() Radar.Waypoint(top) end } },
    })
  end
end

ns.On("ZONE_CHANGED_NEW_AREA", function()
  if C_Timer and C_Timer.After then C_Timer.After(2, OnZoneChanged) else OnZoneChanged() end
end)

ns.commands.zone = function()
  local hits, zoneName = Radar.Scan()
  if #hits == 0 then
    ns.Print(L["Nothing specific for your group found in %s."]:format(zoneName or "?"))
    return
  end
  ns.Print(L["In %s (%d finds):"]:format(zoneName or "?", #hits))
  for i = 1, math.min(8, #hits) do
    local h = hits[i]
    local tag = h.rare and "[Rare] " or ""
    local rate = h.rate and (" (~" .. h.rate .. ")") or ""
    ns.Print(("  %s%s: %s (%d, %d)%s -> %s"):format(tag, h.label or "", h.npcName or "?", h.x or 0, h.y or 0, rate, h.who or ""))
  end
end
