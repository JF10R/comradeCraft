-- ForeverDB: peer-to-peer crowd-calibrated WoW Forever 1.60.1 database (100% in-game, zero servers).
-- Automatically observes and shares verified Forever recipe skill bounds, live mob/rare drop rates,
-- and vendor recipe locations across group peers & guildmates.
local _, ns = ...
local L = ns.L

local FDB = {}
ns.ForeverDB = FDB

local MAX_BOUNDS, MAX_DROPS, MAX_VENDORS, MAX_CUSTOM, MAX_DE = 60, 40, 40, 40, 30
local PEER_COOLDOWN = 300 -- seconds between P2P ForeverDB syncs to the same peer
local lastSentPeer, guildSent = {}, false

local function DB()
  ComradeCraftDB.foreverDrops = ComradeCraftDB.foreverDrops or {}
  ComradeCraftDB.foreverVendors = ComradeCraftDB.foreverVendors or {}
  ComradeCraftDB.foreverPeers = ComradeCraftDB.foreverPeers or {}
  ComradeCraftDB.recipeBounds = ComradeCraftDB.recipeBounds or {}
  ComradeCraftDB.customRecipes = ComradeCraftDB.customRecipes or {}
  return ComradeCraftDB
end

local function PlayerPos()
  local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
  local x, y
  if pos then
    if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
  end
  return map, x and math.floor(x * 100 + 0.5), y and math.floor(y * 100 + 0.5)
end

local function Safe(v)
  if v == nil or (issecretvalue and issecretvalue(v)) then return nil end
  return v
end

local function NpcIDFromGUID(guid)
  guid = Safe(guid)
  if type(guid) ~= "string" then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
end

local function RecipeItemSet()
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  return lib
end

-- Local observation: merchant selling a recipe scroll or skill rank book on WoW Forever.
function FDB.ObserveMerchant()
  if not (ComradeCraftDB and GetMerchantNumItems and GetMerchantItemLink) then return end
  local guid = Safe(UnitGUID and UnitGUID("npc"))
  local npcID = NpcIDFromGUID(guid)
  local npcName = Safe(UnitName and UnitName("npc"))
  local map, x, y = PlayerPos()
  if not (npcID and npcName and map and x and y) then return end
  local db = DB()
  local lib = RecipeItemSet()
  local changed = false
  for i = 1, (GetMerchantNumItems() or 0) do
    local link = Safe(GetMerchantItemLink(i))
    local itemID = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if itemID then
      local isRec = (lib and lib.GetSpellForRecipeItem and lib:GetSpellForRecipeItem(itemID))
        or (ns.Loot and ns.Loot.RankBookInfo and ns.Loot.RankBookInfo(itemID))
      if isRec then
        local _, _, price = GetMerchantItemInfo(i)
        db.foreverVendors[itemID] = {
          npc = npcID, name = npcName, map = map, x = x, y = y,
          cost = tonumber(Safe(price)) or 0, t = time(),
        }
        changed = true
      end
    end
  end
  if changed then ns.Log(("foreverdb: recorded vendor %s (%d)"):format(npcName, npcID)) end
end

-- Local observation: loot from a mob (records recipe/rare drops + per-NPC kill counts for drop rates).
local seenLootGUID, seenLootN = {}, 0
function FDB.ObserveLoot()
  if not (ComradeCraftDB and GetNumLootItems and GetLootSlotLink) then return end
  local srcGuid = GetLootSourceInfo and Safe(select(1, GetLootSourceInfo(1)))
  local guid = srcGuid or Safe(UnitGUID and UnitGUID("target"))
  if type(guid) ~= "string" or seenLootGUID[guid] then return end
  local npcID = NpcIDFromGUID(guid)
  if not npcID then return end
  if seenLootN >= 500 then seenLootGUID, seenLootN = {}, 0 end
  seenLootGUID[guid] = true
  seenLootN = seenLootN + 1
  local db = DB()
  local map, x, y = PlayerPos()
  local npcName = Safe(UnitName and UnitName("target"))
  local cls = Safe(UnitClassification and UnitClassification("target"))
  local isRare = (cls == "rare" or cls == "rareelite") and true or nil
  local lib = RecipeItemSet()
  -- Increment kill count for any tracked recipe item known to come from this NPC.
  for itemID, d in pairs(db.foreverDrops) do
    if d.npc == npcID then d.k = (d.k or 0) + 1 end
  end
  local nSlots = Safe(GetNumLootItems()) or 0
  for slot = 1, nSlots do
    local link = Safe(GetLootSlotLink(slot))
    local itemID = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if itemID then
      local isRec = (lib and lib.GetSpellForRecipeItem and lib:GetSpellForRecipeItem(itemID)) ~= nil
      local qual = (C_Item and C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(itemID)) or 0
      if isRec or (isRare and qual >= 2) then
        local d = db.foreverDrops[itemID]
        if not d then
          d = { d = 0, k = 0, npc = npcID, name = npcName, map = map, x = x, y = y, rare = isRare }
          db.foreverDrops[itemID] = d
        end
        d.d = (d.d or 0) + 1
        d.k = math.max(d.d, (d.k or 0) + (d.npc == npcID and 0 or 1))
        d.npc, d.name = npcID, npcName or d.name
        if map and x and y then d.map, d.x, d.y = map, x, y end
        if isRare then d.rare = true end
      end
    end
  end
end

-- Merged peer + local Forever drop rate for `itemID` (requires >= 10 kills and >= 1 drop).
-- Returns percentage (number, e.g. 4.5) and total kills, or nil when sample is too small.
function FDB.DropRate(itemID)
  if not (ComradeCraftDB and itemID and itemID > 0) then return nil end
  local drops, kills = 0, 0
  local mine = ComradeCraftDB.foreverDrops and ComradeCraftDB.foreverDrops[itemID]
  if mine then drops, kills = drops + (mine.d or 0), kills + (mine.k or 0) end
  for _, p in pairs(ComradeCraftDB.foreverPeers or {}) do
    local pd = p.drops and p.drops[itemID]
    if pd then drops, kills = drops + (pd.d or 0), kills + (pd.k or 0) end
  end
  if kills >= 10 and drops >= 1 then
    return math.min(100, (drops / kills) * 100), kills
  end
end

-- Merged verified Forever vendor location for `itemID` (local first, else peer-observed).
function FDB.Vendor(itemID)
  if not (ComradeCraftDB and itemID and itemID > 0) then return nil end
  local mine = ComradeCraftDB.foreverVendors and ComradeCraftDB.foreverVendors[itemID]
  if mine and mine.map then return mine end
  for _, p in pairs(ComradeCraftDB.foreverPeers or {}) do
    local pv = p.vendors and p.vendors[itemID]
    if pv and pv.map then return pv end
  end
end

-- All verified Forever vendors merged (itemID -> { npc, name, map, x, y, cost }).
function FDB.AllVendors()
  local out = {}
  if not ComradeCraftDB then return out end
  for _, p in pairs(ComradeCraftDB.foreverPeers or {}) do
    for itemID, pv in pairs(p.vendors or {}) do
      if pv and pv.map and not out[itemID] then out[itemID] = pv end
    end
  end
  for itemID, mv in pairs(ComradeCraftDB.foreverVendors or {}) do
    if mv and mv.map then out[itemID] = mv end
  end
  return out
end

-- All peer/local observed rare drops in `uiMap`.
function FDB.ObservedDropsInMap(uiMap)
  local out, seen = {}, {}
  if not (ComradeCraftDB and uiMap) then return out end
  local function Push(itemID, d)
    if not (d and d.map == uiMap and d.d and d.d > 0) then return end
    local cur = seen[itemID]
    if not cur then
      cur = { item = itemID, npc = d.npc, name = d.name, map = d.map, x = d.x, y = d.y, rare = d.rare, d = 0, k = 0 }
      seen[itemID] = cur
      out[#out + 1] = cur
    end
    cur.d = cur.d + (d.d or 0)
    cur.k = cur.k + (d.k or 0)
    if d.rare then cur.rare = true end
  end
  for itemID, d in pairs(ComradeCraftDB.foreverDrops or {}) do Push(itemID, d) end
  for _, p in pairs(ComradeCraftDB.foreverPeers or {}) do
    for itemID, d in pairs(p.drops or {}) do Push(itemID, d) end
  end
  return out
end

-- Compact validated payload for P2P ForeverDB sync (`t = "F"`).
function FDB.Payload()
  local db = DB()
  local b, d, v, cr, de = {}, {}, {}, {}, {}
  local nb, nd, nv, ncr, nde = 0, 0, 0, 0, 0
  for spell, rec in pairs(db.recipeBounds or {}) do
    if nb < MAX_BOUNDS and type(rec) == "table" then
      local yv, gv = rec.y or rec[1], rec.g or rec[2]
      if (yv and yv > 0) or (gv and gv > 0) then
        b[spell] = { yv or 0, gv or 0 }
        nb = nb + 1
      end
    end
  end
  for itemID, rec in pairs(db.foreverDrops or {}) do
    if nd < MAX_DROPS and type(rec) == "table" and (rec.d or 0) > 0 then
      d[itemID] = { rec.d, rec.k or rec.d, rec.npc or 0, rec.name or "", rec.map or 0, rec.x or 0, rec.y or 0, rec.rare and 1 or 0 }
      nd = nd + 1
    end
  end
  for itemID, rec in pairs(db.foreverVendors or {}) do
    if nv < MAX_VENDORS and type(rec) == "table" and rec.map then
      v[itemID] = { rec.npc or 0, rec.name or "", rec.map, rec.x or 0, rec.y or 0, rec.cost or 0 }
      nv = nv + 1
    end
  end
  for spell, r in pairs(db.customRecipes or {}) do
    if ncr < MAX_CUSTOM and type(r) == "table" and r[1] and type(r[7]) == "table" and #r[7] >= 2 and #r[7] <= 16 then
      cr[spell] = { r[1], r[2] or 1, r[3] or 1, r[4] or 1, r[5] or 0, r[6] or 1, r[7] }
      ncr = ncr + 1
    end
  end
  if ns.DisenchantBucketStats then
    for bkey, st in pairs(ns.DisenchantBucketStats(true) or {}) do
      if nde < MAX_DE and st.n and st.n > 0 then
        de[bkey] = { st.n, st.mats }
        nde = nde + 1
      end
    end
  end
  if nb == 0 and nd == 0 and nv == 0 and ncr == 0 and nde == 0 then return nil end
  return { t = "F", v = ns.Sync and ns.Sync.PROTO or 1, id = db.accountId,
    b = nb > 0 and b or nil, d = nd > 0 and d or nil, ve = nv > 0 and v or nil,
    cr = ncr > 0 and cr or nil, de = nde > 0 and de or nil }
end

-- Strict validation & merge of an incoming P2P ForeverDB packet.
function FDB.OnRemote(peerID, msg)
  if not (ComradeCraftDB and peerID and type(msg) == "table" and ns.Sync) then return false end
  local Num, Str = ns.Sync.Num, ns.Sync.Str
  local db = DB()
  local store = db.foreverPeers[peerID] or { bounds = {}, drops = {}, vendors = {}, de = {} }
  store.de = store.de or {}
  store.seen = time()
  local added, boundsAdded, customAdded = 0, false, false
  -- 0. Custom WoW Forever recipes (merge into customRecipes + ns.Recipes BEFORE bounds so bounds apply too).
  local ncr = 0
  for spell, x in pairs(type(msg.cr) == "table" and msg.cr or {}) do
    spell = Num(spell, 1, 2 ^ 24)
    if spell and type(x) == "table" and ncr < MAX_CUSTOM then
      local line = Num(x[1], 1, 2 ^ 24)
      local yv = Num(x[2], 1, 500)
      local gv = Num(x[3], 1, 500)
      local gain = Num(x[4], 1, 10) or 1
      local outItem = Num(x[5], 0, 2 ^ 24) or 0
      local yield = Num(x[6], 1, 100) or 1
      local rawR = type(x[7]) == "table" and x[7] or nil
      if line and yv and gv and rawR and #rawR >= 2 and #rawR <= 16 and (#rawR % 2 == 0) then
        local reag, okR = {}, true
        for i = 1, #rawR, 2 do
          local rid, rq = Num(rawR[i], 1, 2 ^ 24), Num(rawR[i + 1], 1, 1000)
          if not (rid and rq) then okR = false break end
          reag[#reag + 1] = rid
          reag[#reag + 1] = rq
        end
        if okR and #reag >= 2 then
          local row = { line, yv, gv, gain, outItem, yield, reag }
          if not db.customRecipes[spell] then
            db.customRecipes[spell] = row
            customAdded = true
            added = added + 1
          end
          if ns.Recipes and not ns.Recipes[spell] then ns.Recipes[spell] = row end
          ncr = ncr + 1
        end
      end
    end
  end
  -- 1. Verified Forever skill bounds (merged conservatively into recipeBounds when missing locally).
  local nb = 0
  for spell, x in pairs(type(msg.b) == "table" and msg.b or {}) do
    spell = Num(spell, 1, 2 ^ 24)
    if spell and ns.Recipes and ns.Recipes[spell] and type(x) == "table" and nb < MAX_BOUNDS then
      local yv, gv = Num(x[1], 0, 500), Num(x[2], 0, 500)
      if (yv and yv > 0) or (gv and gv > 0) then
        store.bounds[spell] = { y = yv and yv > 0 and yv or nil, g = gv and gv > 0 and gv or nil }
        local loc = db.recipeBounds[spell]
        if not loc then
          db.recipeBounds[spell] = { y = store.bounds[spell].y, g = store.bounds[spell].g, peer = true }
          boundsAdded = true
          added = added + 1
        else
          local ly, lg = loc.y or loc[1], loc.g or loc[2]
          if not ly and store.bounds[spell].y then loc.y = store.bounds[spell].y boundsAdded = true added = added + 1 end
          if not lg and store.bounds[spell].g then loc.g = store.bounds[spell].g boundsAdded = true added = added + 1 end
        end
        nb = nb + 1
      end
    end
  end
  -- 2. Observed Forever mob/rare drops.
  local nd = 0
  for itemID, x in pairs(type(msg.d) == "table" and msg.d or {}) do
    itemID = Num(itemID, 1, 2 ^ 24)
    if itemID and type(x) == "table" and nd < MAX_DROPS then
      local dc = Num(x[1], 1, 10000)
      local kc = Num(x[2], 1, 1000000)
      if dc and kc and kc >= dc then
        store.drops[itemID] = {
          d = dc, k = kc, npc = Num(x[3], 0, 2 ^ 24) or 0,
          name = Str(x[4], 64) or nil, map = Num(x[5], 0, 10000) or 0,
          x = Num(x[6], 0, 100) or 0, y = Num(x[7], 0, 100) or 0,
          rare = x[8] == 1 and true or nil,
        }
        nd = nd + 1
        added = added + 1
      end
    end
  end
  -- 3. Verified Forever vendor recipe spots.
  local nv = 0
  for itemID, x in pairs(type(msg.ve) == "table" and msg.ve or {}) do
    itemID = Num(itemID, 1, 2 ^ 24)
    if itemID and type(x) == "table" and nv < MAX_VENDORS then
      local map = Num(x[3], 1, 10000)
      local name = Str(x[2], 64)
      if map and name then
        store.vendors[itemID] = {
          npc = Num(x[1], 0, 2 ^ 24) or 0, name = name, map = map,
          x = Num(x[4], 0, 100) or 0, y = Num(x[5], 0, 100) or 0,
          cost = Num(x[6], 0, 1e9) or 0,
        }
        nv = nv + 1
        added = added + 1
      end
    end
  end
  -- 4. Calibrated Forever disenchant bucket aggregates ({ [bucketKey] = { count, { [matID] = totalQty } } }).
  local nde = 0
  for bkey, x in pairs(type(msg.de) == "table" and msg.de or {}) do
    bkey = Str(bkey, 24)
    if bkey and bkey:match("^%d+:%d+:%d+$") and type(x) == "table" and nde < MAX_DE then
      local cnt = Num(x[1], 1, 100000)
      if cnt and type(x[2]) == "table" then
        local mats, nm = {}, 0
        for mid, mq in pairs(x[2]) do
          mid, mq = Num(mid, 1, 2 ^ 24), Num(mq, 1, 1000000)
          if mid and mq and nm < 10 then mats[mid] = mq nm = nm + 1 end
        end
        if nm > 0 then
          store.de[bkey] = { n = cnt, mats = mats }
          nde = nde + 1
          added = added + 1
        end
      end
    end
  end
  db.foreverPeers[peerID] = store
  if customAdded and ns.LoadCustomRecipes then ns.LoadCustomRecipes() end
  if boundsAdded and ns.ApplyRecipeBounds then ns.ApplyRecipeBounds() end
  if nde > 0 and ns.InvalidateDECache then ns.InvalidateDECache() end
  return added > 0
end

-- Sends local Forever observations to one peer (cooldown-gated) or to GUILD once per session.
function FDB.SendToPeer(peerID, targetName)
  if not (ns.Sync and peerID and targetName) then return end
  local now = time()
  if now - (lastSentPeer[peerID] or 0) < PEER_COOLDOWN then return end
  local payload = FDB.Payload()
  if not payload then return end
  lastSentPeer[peerID] = now
  ns.Sync.Send(payload, "WHISPER", targetName)
end

function FDB.BroadcastGuild()
  if guildSent or not (ns.Sync and IsInGuild and IsInGuild()) then return end
  if ComradeCraftDB and ComradeCraftDB.settings and ComradeCraftDB.settings.guildPing == false then return end
  local payload = FDB.Payload()
  if not payload then return end
  guildSent = true
  ns.Sync.Send(payload, "GUILD")
end

-- Summary counts for UI (Manage group) and /comrade forever.
function FDB.Stats()
  local nb, nd, nv, np, ncr, nde = 0, 0, 0, 0, 0, 0
  if not ComradeCraftDB then return 0, 0, 0, 0, 0, 0 end
  for _ in pairs(ComradeCraftDB.recipeBounds or {}) do nb = nb + 1 end
  for _ in pairs(ComradeCraftDB.customRecipes or {}) do ncr = ncr + 1 end
  local dSeen, vSeen = {}, {}
  for id in pairs(ComradeCraftDB.foreverDrops or {}) do dSeen[id] = true end
  for id in pairs(ComradeCraftDB.foreverVendors or {}) do vSeen[id] = true end
  if ComradeCraftDB.disenchants and ComradeCraftDB.disenchants.raw then
    nde = #ComradeCraftDB.disenchants.raw
  end
  for _, p in pairs(ComradeCraftDB.foreverPeers or {}) do
    np = np + 1
    for id in pairs(p.drops or {}) do dSeen[id] = true end
    for id in pairs(p.vendors or {}) do vSeen[id] = true end
    for _, st in pairs(p.de or {}) do nde = nde + (st.n or 0) end
  end
  for _ in pairs(dSeen) do nd = nd + 1 end
  for _ in pairs(vSeen) do nv = nv + 1 end
  return nb, nv, nd, np, ncr, nde
end

ns.On("MERCHANT_SHOW", function() FDB.ObserveMerchant() end)
ns.On("LOOT_READY", function() FDB.ObserveLoot() end)
ns.On("PLAYER_LOGIN", function()
  if C_Timer and C_Timer.After then C_Timer.After(25, FDB.BroadcastGuild) end
end)

ns.commands.forever = function()
  local nb, nv, nd, np = FDB.Stats()
  ns.Print(L["Forever P2P DB: %d recipe bounds, %d vendors, %d drops (from %d peers)."]:format(nb, nv, nd, np))
end
