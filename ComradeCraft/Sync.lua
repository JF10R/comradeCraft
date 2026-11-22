-- Sync: peer-to-peer sharing over addon messages (AceComm), no server.
--   PING:  presence only (account id), once at login on the GUILD channel; can be turned off.
--   HELLO: summaries of the characters the player chose to share; whispered ONLY to players
--          the player added, at login and at most once a minute after a shared change.
--   REQ:   asks for full records that changed. DATA: one full record (shared characters only).
--   DIR:   guild directory entry ("G", Directory.lua): professions and recipes of listed characters.
-- Privacy: nothing about a character leaves the client unless it is marked shared (full record,
-- only to added players) or listed (professions and recipes, only to the guild). Everything
-- received is validated before it is stored.
local _, ns = ...
local L = ns.L

local PREFIX = "ComradeCraft"
local PROTO = 1
local HELLO_DEBOUNCE = 60   -- seconds between a local change and the next HELLO
local REPLY_COOLDOWN = 30   -- seconds between two HELLO replies to the same peer
local MAX_CHARS, MAX_PROFS, MAX_RECIPES, MAX_ITEMS, MAX_FARM = 50, 20, 3000, 2000, 40

local Sync = {}
ns.Sync = Sync
Sync.PROTO = PROTO

-- Encoding --------------------------------------------------------------------------------

local function Libs()
  local LS = LibStub and LibStub("LibSerialize", true)
  local LD = LibStub and LibStub("LibDeflate", true)
  return LS, LD
end

function Sync.Encode(msg)
  local LS, LD = Libs()
  if not (LS and LD) then return nil end
  return LD:EncodeForWoWAddonChannel(LD:CompressDeflate(LS:Serialize(msg)))
end

function Sync.Decode(text)
  local LS, LD = Libs()
  if not (LS and LD and type(text) == "string") then return nil end
  local compressed = LD:DecodeForWoWAddonChannel(text)
  local raw = compressed and LD:DecompressDeflate(compressed)
  if not raw then return nil end
  local ok, msg = LS:Deserialize(raw)
  return ok and type(msg) == "table" and msg or nil
end

-- Validation (everything from the network goes through these) ----------------------------

local function Num(v, lo, hi)
  v = tonumber(v)
  if v and v == v and v >= lo and v <= hi then return math.floor(v) end
end

local function Str(v, maxLen)
  if type(v) == "string" and #v > 0 and #v <= maxLen and not v:find("[%c|]") then return v end
end

local function Class(v)
  v = Str(v, 16)
  return v and v:match("^[A-Z]+$") and v or nil
end
Sync.Num, Sync.Str, Sync.Class = Num, Str, Class

-- Skill-up totals per color ({ [color] = { n, gained, expected } }), for the shared calibration.
local COLORS = { orange = true, yellow = true, green = true, grey = true }
function Sync.CleanSkillups(s)
  if type(s) ~= "table" then return nil end
  local out = {}
  for color, x in pairs(s) do
    if COLORS[color] and type(x) == "table" then
      local n = Num(x[1], 0, 1000000)
      local gained = Num(x[2], 0, n or 0)
      local expected = tonumber(x[3])
      if n and gained and expected and expected == expected and expected >= 0 and expected <= n then
        out[color] = { n = n, gained = gained, expected = expected }
      end
    end
  end
  return out
end

local function SkillupTotals()
  local s = ComradeCraftDB.skillups
  if not (s and s.colors) then return nil end
  local out = {}
  for color, c in pairs(s.colors) do out[color] = { c.n, c.gained, c.expected } end
  return out
end

-- Summary: { u = updated, cl = class, lv = level, ba = bankAlt, p = { [skillLine] = { rank, max, name } } }
function Sync.CleanSummary(s)
  if type(s) ~= "table" then return nil end
  local out = { u = Num(s.u, 0, 2 ^ 31) or 0, cl = Class(s.cl), lv = Num(s.lv, 1, 200),
    sp = Str(s.sp, 40), ba = s.ba and true or nil, p = {} }
  local n = 0
  for line, x in pairs(type(s.p) == "table" and s.p or {}) do
    line = Num(line, 1, 2 ^ 24)
    if line and type(x) == "table" and n < MAX_PROFS then
      out.p[line] = { Num(x[1], 0, 1000) or 0, Num(x[2], 0, 1000) or 0, Str(x[3], 40) }
      n = n + 1
    end
  end
  return out
end

-- Full record, wire shape: { class, level, updated, bankAlt, professions = { [name] = { rank, max,
-- skillLine, icon } }, known = { [skillLine] = { spellID, ... } }, owned = { [itemID] = n },
-- farm = { [itemID] = target } }.
-- Only spells in our recipe table and items in our price table are kept.
function Sync.CleanRecord(r)
  if type(r) ~= "table" then return nil end
  local out = { class = Class(r.class), level = Num(r.level, 1, 200), updated = Num(r.updated, 0, 2 ^ 31) or 0,
    spec = Str(r.spec, 40), specIcon = Num(r.specIcon, 1, 2 ^ 31) or Str(r.specIcon, 120),
    specOverride = Str(r.specOverride, 24), bankAlt = r.bankAlt and true or nil,
    route = r.route == "profit" and "profit" or nil,
    professions = {}, known = {}, bags = {}, equipped = {} }
  for slot, item in pairs(type(r.equipped) == "table" and r.equipped or {}) do
    slot, item = Num(slot, 1, 19), Num(item, 1, 2 ^ 31)
    if slot and item then out.equipped[slot] = item end
  end
  local n = 0
  for name, p in pairs(type(r.professions) == "table" and r.professions or {}) do
    name = Str(name, 40)
    if name and type(p) == "table" and n < MAX_PROFS then
      out.professions[name] = { rank = Num(p.rank, 0, 1000) or 0, max = Num(p.max, 0, 1000) or 0,
        skillLine = Num(p.skillLine, 1, 2 ^ 24), icon = Num(p.icon, 1, 2 ^ 31) }
      n = n + 1
    end
  end
  local spells = 0
  for line, list in pairs(type(r.known) == "table" and r.known or {}) do
    line = Num(line, 1, 2 ^ 24)
    if line and type(list) == "table" then
      local set = {}
      for _, spell in ipairs(list) do
        spell = Num(spell, 1, 2 ^ 31)
        local rec = spell and ns.Recipes[spell]
        if rec and rec[1] == line and spells < MAX_RECIPES then
          set[spell] = true
          spells = spells + 1
        end
      end
      out.known[line] = set
    end
  end
  local items = 0
  for item, count in pairs(type(r.owned) == "table" and r.owned or {}) do
    item, count = Num(item, 1, 2 ^ 31), Num(count, 1, 1000000)
    if item and count and ns.ItemPrices[item] and items < MAX_ITEMS then
      out.bags[item] = count
      items = items + 1
    end
  end
  -- Farming assignments (group plan): positive counts, MAX_FARM at most.
  local farm, nf = {}, 0
  for item, target in pairs(type(r.farm) == "table" and r.farm or {}) do
    item, target = Num(item, 1, 2 ^ 31), Num(target, 1, 1000000)
    if item and target and nf < MAX_FARM then
      farm[item] = target
      nf = nf + 1
    end
  end
  out.farm = nf > 0 and farm or nil
  -- Profession cooldowns: { [spellID] = readyAt }, up to 20 entries.
  local cds, nc = {}, 0
  for spell, readyAt in pairs(type(r.cooldowns) == "table" and r.cooldowns or {}) do
    spell, readyAt = Num(spell, 1, 2 ^ 31), Num(readyAt, 0, 2 ^ 31)
    if spell and readyAt and ns.Recipes[spell] and nc < 20 then
      cds[spell] = readyAt
      nc = nc + 1
    end
  end
  out.cooldowns = nc > 0 and cds or nil
  -- Equipped enchant IDs & bag sizes (for Group Upgrades audit).
  local ench, ne = {}, 0
  for slot, eid in pairs(type(r.enchants) == "table" and r.enchants or {}) do
    slot, eid = Num(slot, 1, 19), Num(eid, 0, 2 ^ 24)
    if slot and eid and ne < 12 then ench[slot] = eid ne = ne + 1 end
  end
  out.enchants = ne > 0 and ench or nil
  local bs = {}
  for i = 1, 4 do
    local sz = type(r.bagSizes) == "table" and Num(r.bagSizes[i], 0, 64)
    if sz then bs[i] = sz end
  end
  out.bagSizes = #bs > 0 and bs or nil
  -- Shared wishlist items pinned by this peer character (max 15).
  local wl = {}
  for _, e in ipairs(type(r.wishlist) == "table" and r.wishlist or {}) do
    if type(e) == "table" and #wl < 15 then
      local sp, qty = Num(e.s, 1, 2 ^ 31), Num(e.q, 1, 999)
      local rec = sp and ns.Recipes[sp]
      if rec and qty then
        wl[#wl + 1] = { id = Str(e.id, 32) or tostring(sp), spell = sp, item = rec[5] or 0,
          qty = qty, forWho = Str(e.w, 40), note = Str(e.n, 80) }
      end
    end
  end
  out.wishlist = #wl > 0 and wl or nil
  -- Reserved items tagged by this character for a specific group member (max 40).
  local res, nr = {}, 0
  for item, rv in pairs(type(r.reserved) == "table" and r.reserved or {}) do
    item = Num(item, 1, 2 ^ 31)
    if item and type(rv) == "table" and nr < MAX_FARM then
      local to, qty = Str(rv.t or rv.to, 80), Num(rv.q or rv.qty, 1, 1000000)
      if to and qty then
        res[item] = { to = to, qty = qty }
        nr = nr + 1
      end
    end
  end
  out.reserved = nr > 0 and res or nil
  return out
end

-- Local data -> wire ----------------------------------------------------------------------

local function Summary(c)
  local p = {}
  for name, x in pairs(c.professions or {}) do
    if x.skillLine then p[x.skillLine] = { x.rank, x.max, name } end
  end
  return { u = c.updated or 0, cl = c.class, lv = c.level, sp = c.spec, ba = c.bankAlt or nil, p = p }
end

local function Record(c, key)
  local known = {}
  for line, set in pairs(c.known or {}) do
    local list = {}
    for spell in pairs(set) do list[#list + 1] = spell end
    known[line] = list
  end
  local owned = {}
  for _, src in ipairs({ c.bags or {}, c.bank or {}, c.mail or {} }) do
    for item, n in pairs(src) do
      if ns.ItemPrices[item] then owned[item] = (owned[item] or 0) + n end
    end
  end
  local profs = {}
  for name, p in pairs(c.professions or {}) do
    profs[name] = { rank = p.rank, max = p.max, skillLine = p.skillLine, icon = p.icon }
  end
  local farm, nf = {}, 0
  for item, a in pairs(ComradeCraftDB.farm or {}) do
    if a.char == key and nf < MAX_FARM then
      farm[item] = a.target
      nf = nf + 1
    end
  end
  local cds, nc = {}, 0
  for spell, readyAt in pairs(c.cooldowns or {}) do
    if nc < 20 then cds[spell] = readyAt nc = nc + 1 end
  end
  local wl = {}
  for _, e in ipairs(ComradeCraftDB.wishlist or {}) do
    if e.char == key and #wl < 15 then
      wl[#wl + 1] = { id = e.id, s = e.spell, q = e.qty, w = e.forWho, n = e.note }
    end
  end
  local res, nr = {}, 0
  for item, rv in pairs(c.reserved or {}) do
    if nr < MAX_FARM and rv and rv.to and (rv.qty or 0) > 0 then
      res[item] = { t = rv.to, q = rv.qty }
      nr = nr + 1
    end
  end
  return { class = c.class, level = c.level, spec = c.spec, specIcon = c.specIcon,
    specOverride = c.specOverride, bankAlt = c.bankAlt or nil, route = c.route, updated = c.updated,
    professions = profs, known = known, owned = owned, equipped = c.equipped, enchants = c.enchants,
    bagSizes = c.bagSizes, farm = nf > 0 and farm or nil, cooldowns = nc > 0 and cds or nil,
    wishlist = #wl > 0 and wl or nil, reserved = nr > 0 and res or nil }
end

-- Converts a validated remote record back into wire shape for Mesh Sync relay.
local function RemoteToWire(rec)
  local known = {}
  for line, set in pairs(rec.known or {}) do
    local list = {}
    for spell in pairs(set) do list[#list + 1] = spell end
    known[line] = list
  end
  local wl
  if rec.wishlist and #rec.wishlist > 0 then
    wl = {}
    for _, e in ipairs(rec.wishlist) do
      wl[#wl + 1] = { id = e.id, s = e.spell, q = e.qty, w = e.forWho, n = e.note }
    end
  end
  local res
  if rec.reserved and next(rec.reserved) then
    res = {}
    for item, rv in pairs(rec.reserved) do res[item] = { t = rv.to, q = rv.qty } end
  end
  return { class = rec.class, level = rec.level, spec = rec.spec, specIcon = rec.specIcon,
    specOverride = rec.specOverride, bankAlt = rec.bankAlt or nil, route = rec.route, updated = rec.updated,
    professions = rec.professions, known = known, owned = rec.bags, equipped = rec.equipped,
    enchants = rec.enchants, bagSizes = rec.bagSizes, farm = rec.farm, cooldowns = rec.cooldowns,
    wishlist = wl, reserved = res }
end

local function DB()
  local db = ComradeCraftDB
  db.peers = db.peers or {}
  db.remote = db.remote or {}
  db.pendingAdd = db.pendingAdd or {}
  if not db.accountId then
    db.accountId = ("%08x%06x"):format(math.random(0, 0x7fffffff), (time() or 0) % 0x1000000)
  end
  return db
end

-- Transport -------------------------------------------------------------------------------

local queue = {}       -- messages waiting for the player to leave an instance
local whispered = {}   -- [name] = time, to hide "No player named X" after our whispers

local function Blocked()
  return IsInInstance and (IsInInstance()) and true or false
end

-- Overridable for tests: sends an encoded string.
function Sync.transport(text, dist, target)
  local comm = LibStub and LibStub("AceComm-3.0", true)
  if comm then comm:SendCommMessage(PREFIX, text, dist, target, "BULK") end
end

function Sync.Send(msg, dist, target)
  if Blocked() then
    queue[#queue + 1] = { msg = msg, dist = dist, target = target }
    return
  end
  local text = Sync.Encode(msg)
  if not text then return end
  if dist == "WHISPER" and target then whispered[target] = time() end
  Sync.transport(text, dist, target)
end

function Sync.Flush()
  if Blocked() or #queue == 0 then return end
  local pending = queue
  queue = {}
  for _, q in ipairs(pending) do Sync.Send(q.msg, q.dist, q.target) end
end
Sync.QueueSize = function() return #queue end

-- Messages --------------------------------------------------------------------------------

-- Mesh Sync index: { [originPeerId] = { [charKey] = updated } } for mutually included peers.
-- Carries ONLY timestamps (no character data); receivers fetch newer records on demand.
local function MeshIndex()
  local db = DB()
  local out, n = {}, 0
  for key, rec in pairs(db.remote or {}) do
    local pid = rec and rec.peer
    local peer = pid and db.peers[pid]
    if peer and peer.included and (rec.updated or 0) > 0 and n < MAX_CHARS then
      out[pid] = out[pid] or {}
      out[pid][key] = rec.updated
      n = n + 1
    end
  end
  return n > 0 and out or nil
end

local function MaxSharedUpdated()
  local best = 0
  for _, c in pairs(ComradeCraftDB.chars or {}) do
    if c.shared and (c.updated or 0) > best then best = c.updated end
  end
  return best
end

-- Only characters the player marked shared (c.shared) are ever sent.
function Sync.Hello(reply)
  local chars, n = {}, 0
  for key, c in pairs(ComradeCraftDB.chars or {}) do
    if c.shared and n < MAX_CHARS then
      chars[key] = Summary(c)
      n = n + 1
    end
  end
  return { t = "H", v = PROTO, id = DB().accountId, r = reply or nil, c = chars,
    m = MeshIndex(), sk = SkillupTotals() }
end

local function RequestChanged(id, meshTable)
  local db = DB()
  local peer = db.peers[id]
  if not (peer and peer.included and peer.name) then return end
  local keys = {}
  for key, s in pairs(peer.chars or {}) do
    local have = db.remote[key]
    if not db.chars[key] and (not have or (have.updated or 0) < (s.u or 0)) then keys[#keys + 1] = key end
  end
  local rkeys = {}
  if type(meshTable) == "table" then
    for origId, cmap in pairs(meshTable) do
      origId = Str(origId, 32)
      local origPeer = origId and origId ~= db.accountId and origId ~= id and db.peers[origId]
      if origPeer and origPeer.included and type(cmap) == "table" then
        for key, ts in pairs(cmap) do
          key = Str(key, 80)
          ts = Num(ts, 1, 2 ^ 31)
          local have = key and db.remote[key]
          if key and ts and not db.chars[key] and (not have or (have.updated or 0) < ts) and #rkeys < MAX_CHARS then
            rkeys[#rkeys + 1] = { p = origId, k = key }
          end
        end
      end
    end
  end
  if #keys > 0 or #rkeys > 0 then
    Sync.Send({ t = "R", v = PROTO, id = db.accountId, k = keys, rk = #rkeys > 0 and rkeys or nil }, "WHISPER", peer.name)
  end
end

-- Shared summaries, whispered to the players the player added (never to the guild).
-- Also sends a zero-data guild presence pulse (accountId + timestamp) so guildmates who
-- switched to another alt sync immediately without needing to know their new alt name.
function Sync.AnnounceToGroup(skipGuildPulse)
  if not ComradeCraftDB then return end
  local db = DB()
  local hello = Sync.Hello()
  local anyIncluded = false
  for _, peer in pairs(db.peers) do
    if peer.included and peer.name then
      anyIncluded = true
      Sync.Send(hello, "WHISPER", peer.name)
    end
  end
  for _, p in pairs(db.pendingAdd) do
    if p and p.name then Sync.Send(hello, "WHISPER", p.name) end
  end
  db.settings = db.settings or {}
  local maxU = MaxSharedUpdated()
  if not skipGuildPulse and anyIncluded and maxU > 0 and db.settings.guildPing ~= false and IsInGuild and IsInGuild() then
    Sync.Send({ t = "P", v = PROTO, id = db.accountId, u = maxU }, "GUILD")
  end
end

-- Login: presence ping on the guild channel (unless turned off), then the group update.
function Sync.Announce()
  if not ComradeCraftDB then return end
  local db = DB()
  db.settings = db.settings or {}
  if db.settings.guildPing ~= false and IsInGuild and IsInGuild() then
    Sync.Send({ t = "P", v = PROTO, id = db.accountId, u = MaxSharedUpdated() }, "GUILD")
    if ns.Directory then ns.Directory.NotePing() end
  end
  Sync.AnnounceToGroup(true)
end

-- "key=updated;..." of the shared characters: announce only when it changes.
local function Signature()
  local parts = {}
  for key, c in pairs(ComradeCraftDB.chars or {}) do
    if c.shared then parts[#parts + 1] = key .. "=" .. tostring(c.updated) .. (c.bankAlt and ":b" or "") end
  end
  table.sort(parts)
  return table.concat(parts, ";")
end

local dirtyPending, lastSignature = false, nil
function Sync.MarkDirty()
  if dirtyPending or not C_Timer then return end
  dirtyPending = true
  C_Timer.After(HELLO_DEBOUNCE, function()
    dirtyPending = false
    local sig = Signature()
    if sig ~= lastSignature then
      lastSignature = sig
      Sync.AnnounceToGroup()
    end
  end)
end

-- Marks a local character shared or not; unsharing tells the group right away.
function Sync.SetShared(key, on)
  local c = ComradeCraftDB.chars[key]
  if not c then return end
  c.shared = on or nil
  if not on then c.bankAlt = nil end
  Sync.AnnounceToGroup()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- Marks a local character as a Shared bank alt: all its stock (bags, bank, mail) appears as
-- available surplus to the group, and group members can request items from it via the addon.
function Sync.SetBankAlt(key, on)
  local c = ComradeCraftDB.chars[key]
  if not c then return end
  c.bankAlt = on and true or nil
  if on then c.shared = true end
  c.updated = time()
  if ns.UpdateNeeds then ns.UpdateNeeds(c) end
  Sync.AnnounceToGroup()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- Marks every local character on this account shared or not (one announce).
function Sync.SetAllShared(on)
  local n = 0
  for _, c in pairs(ComradeCraftDB.chars or {}) do
    c.shared = on or nil
    if not on then c.bankAlt = nil end
    n = n + 1
  end
  Sync.AnnounceToGroup()
  if ns.RefreshWindow then ns.RefreshWindow() end
  return n
end

-- Receiving -------------------------------------------------------------------------------

local function Self() return ns.UnitFullName and ns.UnitFullName("player") or (UnitName and UnitName("player")) end

function Sync.OnMessage(text, dist, sender)
  if not ComradeCraftDB then return end
  sender = Ambiguate and Ambiguate(sender or "", "none") or sender
  if not Str(sender, 64) or sender == Self() then return end
  local msg = Sync.Decode(text)
  if not msg or msg.v ~= PROTO then return end
  local db = DB()
  local id = Str(msg.id, 32)
  if not id or id == db.accountId then return end
  local peer = db.peers[id]
  if not peer then
    peer = { included = false, chars = {} }
    db.peers[id] = peer
  end
  peer.name, peer.seen = sender, time()
  -- Craft requests: whatever they have not acknowledged yet goes out now that they are online.
  if peer.included and ns.Requests then ns.Requests.OnPeerSeen(id) end

  if msg.t == "P" then
    -- Presence / guild channel pulse. An added player who logged in or updated on any alt
    -- gets our shared summaries right away (works even after alt-switching in guild).
    local pulseU = Num(msg.u, 0, 2 ^ 31) or 0
    local newerPulse = pulseU > (peer.lastPulseU or 0)
    if newerPulse then peer.lastPulseU = pulseU end
    if peer.included and (newerPulse or (time() - (peer.replied or 0)) >= REPLY_COOLDOWN) then
      peer.replied = time()
      Sync.Send(Sync.Hello(not newerPulse), "WHISPER", sender)
    end
    if ns.Directory then ns.Directory.OnPing(sender, dist) end
  elseif msg.t == "G" then
    if ns.Directory then ns.Directory.OnEntry(id, msg, dist, sender) end
  elseif msg.t == "H" then
    local chars, n = {}, 0
    for key, s in pairs(type(msg.c) == "table" and msg.c or {}) do
      key = Str(key, 80)
      local clean = key and n < MAX_CHARS and Sync.CleanSummary(s)
      if clean then
        chars[key] = clean
        n = n + 1
      end
    end
    peer.chars = chars
    peer.skillups = Sync.CleanSkillups(msg.sk)
    local low, shortLow = sender:lower(), (sender:match("^[^-]+") or sender):lower()
    if db.pendingAdd[low] or db.pendingAdd[shortLow] or (Sync.pendingAdd and (Sync.pendingAdd[low] or Sync.pendingAdd[shortLow])) then
      db.pendingAdd[low], db.pendingAdd[shortLow] = nil, nil
      if Sync.pendingAdd then Sync.pendingAdd[low], Sync.pendingAdd[shortLow] = nil, nil end
      peer.included = true
    end
    -- They added us (only added players get HELLOs). Not added back: shown as "wants to
    -- join" + toast so you can accept on the spot. Added: answer once, then fetch changes.
    if not peer.included then
      local firstAsk = not peer.asked
      peer.asked = true
      if firstAsk and ns.Alerts and ns.Alerts.Notify then
        local peerId, who = id, sender
        ns.Alerts.Notify({
          title = L["%s wants to join your group"]:format(who),
          text = L["Accept to share your checked characters with them."],
          icon = ns.LOGO,
          sticky = true,
          buttons = {
            { L["Accept"], function() Sync.Include(peerId) end },
            { L["Ignore"], function() end },
          },
        })
      end
    elseif not msg.r and (time() - (peer.replied or 0)) >= REPLY_COOLDOWN then
      peer.replied = time()
      Sync.Send(Sync.Hello(true), "WHISPER", sender)
    end
    RequestChanged(id, msg.m)
    -- Characters they stopped sharing disappear.
    for key, rec in pairs(db.remote) do
      if rec.peer == id and not chars[key] then db.remote[key] = nil end
    end
  elseif msg.t == "R" then
    if not peer.included then
      peer.asked = true -- shown as "wants to join" in the suggestions
    else
      for _, key in ipairs(type(msg.k) == "table" and msg.k or {}) do
        local c = Str(key, 80) and db.chars[key]
        if c and c.shared then Sync.Send({ t = "D", v = PROTO, id = db.accountId, key = key, rec = Record(c, key) }, "WHISPER", sender) end
      end
      -- Mesh Sync relay: forward mutually-trusted peers' latest records when asked.
      for _, rk in ipairs(type(msg.rk) == "table" and msg.rk or {}) do
        if type(rk) == "table" then
          local origId, key = Str(rk.p, 32), Str(rk.k, 80)
          local origPeer = origId and db.peers[origId]
          local rec = key and db.remote[key]
          if origPeer and origPeer.included and rec and rec.peer == origId then
            Sync.Send({ t = "D", v = PROTO, id = db.accountId, orig = origId, key = key, rec = RemoteToWire(rec) },
              "WHISPER", sender)
          end
        end
      end
    end
  elseif msg.t == "Q" then
    if peer.included and ns.Requests then ns.Requests.OnRemote(id, msg.q, sender) end
  elseif msg.t == "A" then
    if peer.included and ns.Requests then ns.Requests.OnAck(id, msg.rid, msg.u) end
  elseif msg.t == "D" then
    local key = Str(msg.key, 80)
    local origId = msg.orig and Str(msg.orig, 32) or nil
    local ownerId = origId or id
    local ownerPeer = db.peers[ownerId]
    if peer.included and ownerPeer and ownerPeer.included and key and not db.chars[key] then
      local rec = Sync.CleanRecord(msg.rec)
      local have = db.remote[key]
      if rec and (not origId or not have or (have.updated or 0) < (rec.updated or 0)) then
        rec.peer = ownerId
        if origId then rec.relayedBy = id end
        db.remote[key] = rec
        ns.UpdateNeeds(rec)
        if ns.Alerts then ns.Alerts.CheckUpgrades() end
        if ns.Bags and ns.Bags.Refresh then ns.Bags.Refresh() end
      end
    end
  end
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- Group membership ------------------------------------------------------------------------

function Sync.Include(id)
  local peer = DB().peers[id]
  if not peer then return end
  peer.included, peer.asked = true, nil
  if peer.name then Sync.Send(Sync.Hello(), "WHISPER", peer.name) end
  RequestChanged(id)
  if ns.RefreshWindow then ns.RefreshWindow() end
end

function Sync.Exclude(id)
  local db = DB()
  local peer = db.peers[id]
  if not peer then return end
  peer.included = false
  for key, rec in pairs(db.remote) do
    if rec.peer == id then db.remote[key] = nil end
  end
  if ns.RefreshWindow then ns.RefreshWindow() end
end

local function PeerByName(name)
  name = name and name:lower()
  if not name then return nil end
  local short = name:match("^[^-]+") or name
  for id, peer in pairs(DB().peers) do
    if peer.name then
      local pn = peer.name:lower()
      if pn == name or (pn:match("^[^-]+") or pn) == short then return id, peer end
    end
  end
end
Sync.PeerByName = PeerByName

-- Adds a player by name: includes immediately if already seen, else stores a pending invite
-- and whispers HELLO (retried automatically on login / sync).
function Sync.AddByName(name)
  name = type(name) == "string" and name:match("^%s*(.-)%s*$") or ""
  if name == "" then return false end
  local short = name:match("^[^-]+") or name
  if Self() and short:lower() == Self():lower() then
    ns.Print(L["You cannot add yourself."])
    return false
  end
  local id = PeerByName(name)
  if id then
    local db = DB()
    db.pendingAdd[name:lower()], db.pendingAdd[short:lower()] = nil, nil
    Sync.Include(id)
    ns.Print(L["%s added to the group"]:format(name))
    return true
  end
  local db = DB()
  db.pendingAdd[short:lower()] = { name = name, t = time() }
  Sync.Send(Sync.Hello(), "WHISPER", name)
  ns.Print(L["%s contacted; added as soon as they answer"]:format(name))
  if ns.RefreshWindow then ns.RefreshWindow() end
  return true
end

function Sync.PendingAdds()
  local out = {}
  for k, p in pairs(DB().pendingAdd) do
    if p and p.name then out[#out + 1] = { key = k, name = p.name, t = p.t } end
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

function Sync.CancelAdd(key)
  local db = DB()
  if key then db.pendingAdd[key] = nil end
  if ns.RefreshWindow then ns.RefreshWindow() end
end

function Sync.RetryAdd(key)
  local p = key and DB().pendingAdd[key]
  if not (p and p.name) then return end
  p.t = time()
  Sync.Send(Sync.Hello(), "WHISPER", p.name)
  ns.Print(L["%s contacted; added as soon as they answer"]:format(p.name))
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- Friendly player currently targeted (nil if none or self).
function Sync.TargetPlayerName()
  if not (UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target")) then return nil end
  if UnitIsFriend and not UnitIsFriend("player", "target") then return nil end
  if UnitIsUnit and UnitIsUnit("player", "target") then return nil end
  local name = ns.UnitFullName and ns.UnitFullName("target") or (UnitName and UnitName("target"))
  if not name or (issecretvalue and issecretvalue(name)) then return nil end
  return name
end

-- Online candidates from party/raid, friends list and guild not yet in peers or pending.
-- Returns { { name, class, source = "party"|"friend"|"guild" }, ... }.
function Sync.QuickAddCandidates()
  local db = DB()
  local skip, out = {}, {}
  local me = Self()
  if me then skip[me:lower()] = true end
  for _, peer in pairs(db.peers) do
    if peer.name then
      local s = (peer.name:match("^[^-]+") or peer.name):lower()
      skip[s] = true
    end
  end
  for k in pairs(db.pendingAdd) do skip[k] = true end
  local function Push(name, class, source)
    if not name or name == "" or (issecretvalue and issecretvalue(name)) then return end
    local short = name:match("^[^-]+") or name
    local low = short:lower()
    if skip[low] then return end
    skip[low] = true
    out[#out + 1] = { name = short, class = class, source = source }
  end
  -- Party / raid
  local nGroup = GetNumGroupMembers and GetNumGroupMembers() or 0
  if nGroup > 0 then
    local prefix = IsInRaid and IsInRaid() and "raid" or "party"
    for i = 1, nGroup do
      local unit = prefix .. i
      if UnitExists and UnitExists(unit) and (not UnitIsConnected or UnitIsConnected(unit))
        and (not UnitIsUnit or not UnitIsUnit(unit, "player")) then
        local _, cls = UnitClass and UnitClass(unit)
        Push(ns.UnitFullName and ns.UnitFullName(unit) or (UnitName and UnitName(unit)), cls, "party")
      end
    end
  end
  -- Online friends
  if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
    for i = 1, C_FriendList.GetNumFriends() do
      local info = C_FriendList.GetFriendInfoByIndex(i)
      if info and info.connected and info.name then
        Push(info.name, nil, "friend")
      end
    end
  end
  -- Online guildmates
  if IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo then
    for i = 1, GetNumGuildMembers() do
      local gname, _, _, _, _, _, _, _, online, _, cls = GetGuildRosterInfo(i)
      if online and gname then Push(gname, cls, "guild") end
    end
  end
  local order = { party = 1, friend = 2, guild = 3 }
  table.sort(out, function(a, b)
    if order[a.source] ~= order[b.source] then return order[a.source] < order[b.source] end
    return a.name < b.name
  end)
  return out
end

-- Wiring ----------------------------------------------------------------------------------

ns.On("PLAYER_LOGIN", function()
  DB()
  local comm = LibStub and LibStub("AceComm-3.0", true)
  if comm then
    comm:Embed(Sync)
    Sync:RegisterComm(PREFIX, function(_, text, dist, sender) Sync.OnMessage(text, dist, sender) end)
  end
  if ChatFrame_AddMessageEventFilter and ERR_CHAT_PLAYER_NOT_FOUND_S then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, text)
      for name, t in pairs(whispered) do
        if time() - t < 10 and text == ERR_CHAT_PLAYER_NOT_FOUND_S:format(name) then return true end
      end
    end)
  end
  if C_Timer then C_Timer.After(10, Sync.Announce) end
  if Menu and Menu.ModifyMenu then
    local tags = { "MENU_UNIT_PLAYER", "MENU_UNIT_PARTY", "MENU_UNIT_RAID_PLAYER", "MENU_UNIT_FRIEND", "MENU_UNIT_COMMUNITIES_GUILD_MEMBER" }
    for _, tag in ipairs(tags) do
      pcall(Menu.ModifyMenu, tag, function(_, root, ctx)
        local name = ctx and ctx.name
        if not name and ctx and ctx.unit and UnitIsPlayer and UnitIsPlayer(ctx.unit)
          and (not UnitIsFriend or UnitIsFriend("player", ctx.unit)) then
          name = ns.UnitFullName and ns.UnitFullName(ctx.unit) or (UnitName and UnitName(ctx.unit))
        end
        if not name or name == "" or (issecretvalue and issecretvalue(name)) then return end
        local short = name:match("^[^-]+") or name
        if Self() and short:lower() == Self():lower() then return end
        local _, peer = PeerByName(short)
        if peer and peer.included then return end
        root:CreateDivider()
        root:CreateButton(L["ComradeCraft: Add to group"], function() Sync.AddByName(short) end)
      end)
    end
  end
end)
ns.On("PLAYER_ENTERING_WORLD", function() Sync.Flush() end)
ns.On("ZONE_CHANGED_NEW_AREA", function() Sync.Flush() end)

-- Commands --------------------------------------------------------------------------------

ns.commands.sync = function()
  Sync.Announce()
  ns.Print(L["sync: sent to the players in your group"])
end

-- /comrade share [on|off|all|none]: share the current character or every character on this account.
ns.commands.share = function(arg)
  if arg == "all" then
    local n = Sync.SetAllShared(true)
    ns.Print(L["All characters (%d) are now shared with your group"]:format(n))
    return
  elseif arg == "none" then
    Sync.SetAllShared(false)
    ns.Print(L["No character is shared anymore"])
    return
  end
  local on = arg ~= "off"
  Sync.SetShared(ns.CharKey(), on)
  ns.Print((on and L["%s is shared with your group"] or L["%s is no longer shared"]):format(ns.CharKey()))
end

-- /comrade guildping [on|off]: the login presence signal on the guild channel.
ns.commands.guildping = function(arg)
  local db = DB()
  db.settings = db.settings or {}
  db.settings.guildPing = arg ~= "off"
  ns.Print(db.settings.guildPing and L["guild presence signal: on"] or L["guild presence signal: off"])
end

ns.commands.peers = function()
  local any = false
  for _, peer in pairs(DB().peers) do
    any = true
    local n = 0
    for _ in pairs(peer.chars or {}) do n = n + 1 end
    ns.Print(L["  %s: %d characters, %s"]:format(peer.name or "?", n,
      peer.included and L["in the group"] or (peer.asked and L["wants to join"] or L["suggested"])))
  end
  if not any then ns.Print(L["no peer seen yet (they need ComradeCraft)"]) end
end

ns.commands.add = function(name)
  Sync.AddByName(name)
end

ns.commands.remove = function(name)
  local id = PeerByName(name)
  if id then
    Sync.Exclude(id)
    ns.Print(L["%s removed from the group"]:format(name))
  end
end
