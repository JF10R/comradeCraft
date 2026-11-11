-- Sync: peer-to-peer sharing over addon messages (AceComm), no server.
--   PING:  presence only (account id), once at login on the GUILD channel; can be turned off.
--   HELLO: summaries of the characters the player chose to share; whispered ONLY to players
--          the player added, at login and at most once a minute after a shared change.
--   REQ:   asks for full records that changed. DATA: one full record (shared characters only).
-- Privacy: nothing about a character leaves the client unless it is marked shared, and only
-- added players receive it. Everything received is validated before it is stored.
local _, ns = ...
local L = ns.L

local PREFIX = "ComradeCraft"
local PROTO = 1
local HELLO_DEBOUNCE = 60   -- seconds between a local change and the next HELLO
local REPLY_COOLDOWN = 30   -- seconds between two HELLO replies to the same peer
local MAX_CHARS, MAX_PROFS, MAX_RECIPES, MAX_ITEMS = 50, 20, 3000, 2000

local Sync = {}
ns.Sync = Sync

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

-- Summary: { u = updated, cl = class, lv = level, p = { [skillLine] = { rank, max, name } } }
function Sync.CleanSummary(s)
  if type(s) ~= "table" then return nil end
  local out = { u = Num(s.u, 0, 2 ^ 31) or 0, cl = Class(s.cl), lv = Num(s.lv, 1, 200), p = {} }
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

-- Full record, wire shape: { class, level, updated, professions = { [name] = { rank, max,
-- skillLine, icon } }, known = { [skillLine] = { spellID, ... } }, owned = { [itemID] = n } }.
-- Only spells in our recipe table and items in our price table are kept.
function Sync.CleanRecord(r)
  if type(r) ~= "table" then return nil end
  local out = { class = Class(r.class), level = Num(r.level, 1, 200), updated = Num(r.updated, 0, 2 ^ 31) or 0,
    professions = {}, known = {}, bags = {} }
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
  return out
end

-- Local data -> wire ----------------------------------------------------------------------

local function Summary(c)
  local p = {}
  for name, x in pairs(c.professions or {}) do
    if x.skillLine then p[x.skillLine] = { x.rank, x.max, name } end
  end
  return { u = c.updated or 0, cl = c.class, lv = c.level, p = p }
end

local function Record(c)
  local known = {}
  for line, set in pairs(c.known or {}) do
    local list = {}
    for spell in pairs(set) do list[#list + 1] = spell end
    known[line] = list
  end
  local owned = {}
  for _, src in ipairs({ c.bags or {}, c.bank or {} }) do
    for item, n in pairs(src) do
      if ns.ItemPrices[item] then owned[item] = (owned[item] or 0) + n end
    end
  end
  local profs = {}
  for name, p in pairs(c.professions or {}) do
    profs[name] = { rank = p.rank, max = p.max, skillLine = p.skillLine, icon = p.icon }
  end
  return { class = c.class, level = c.level, updated = c.updated, professions = profs, known = known, owned = owned }
end

local function DB()
  local db = ComradeCraftDB
  db.peers = db.peers or {}
  db.remote = db.remote or {}
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

-- Only characters the player marked shared (c.shared) are ever sent.
function Sync.Hello(reply)
  local chars, n = {}, 0
  for key, c in pairs(ComradeCraftDB.chars or {}) do
    if c.shared and n < MAX_CHARS then
      chars[key] = Summary(c)
      n = n + 1
    end
  end
  return { t = "H", v = PROTO, id = DB().accountId, r = reply or nil, c = chars }
end

local function RequestChanged(id)
  local db = DB()
  local peer = db.peers[id]
  if not (peer and peer.included and peer.name) then return end
  local keys = {}
  for key, s in pairs(peer.chars or {}) do
    local have = db.remote[key]
    if not db.chars[key] and (not have or (have.updated or 0) < (s.u or 0)) then keys[#keys + 1] = key end
  end
  if #keys > 0 then Sync.Send({ t = "R", v = PROTO, id = db.accountId, k = keys }, "WHISPER", peer.name) end
end

-- Shared summaries, whispered to the players the player added (never to the guild).
function Sync.AnnounceToGroup()
  if not ComradeCraftDB then return end
  local hello = Sync.Hello()
  for _, peer in pairs(DB().peers) do
    if peer.included and peer.name then Sync.Send(hello, "WHISPER", peer.name) end
  end
end

-- Login: presence ping on the guild channel (unless turned off), then the group update.
function Sync.Announce()
  if not ComradeCraftDB then return end
  local db = DB()
  db.settings = db.settings or {}
  if db.settings.guildPing ~= false and IsInGuild and IsInGuild() then
    Sync.Send({ t = "P", v = PROTO, id = db.accountId }, "GUILD")
  end
  Sync.AnnounceToGroup()
end

-- "key=updated;..." of the shared characters: announce only when it changes.
local function Signature()
  local parts = {}
  for key, c in pairs(ComradeCraftDB.chars or {}) do
    if c.shared then parts[#parts + 1] = key .. "=" .. tostring(c.updated) end
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
  Sync.AnnounceToGroup()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- Receiving -------------------------------------------------------------------------------

local function Self() return UnitName and UnitName("player") end

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

  if msg.t == "P" then
    -- Presence only. An added player who just logged in gets our shared summaries.
    if peer.included and (time() - (peer.replied or 0)) >= REPLY_COOLDOWN then
      peer.replied = time()
      Sync.Send(Sync.Hello(true), "WHISPER", sender)
    end
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
    if Sync.pendingAdd and Sync.pendingAdd[sender:lower()] then
      Sync.pendingAdd[sender:lower()] = nil
      peer.included = true
    end
    -- They added us (only added players get HELLOs). Not added back: shown as "wants to
    -- join". Added: answer once with our own summaries, then fetch what changed.
    if not peer.included then
      peer.asked = true
    elseif not msg.r and (time() - (peer.replied or 0)) >= REPLY_COOLDOWN then
      peer.replied = time()
      Sync.Send(Sync.Hello(true), "WHISPER", sender)
    end
    RequestChanged(id)
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
        if c and c.shared then Sync.Send({ t = "D", v = PROTO, id = db.accountId, key = key, rec = Record(c) }, "WHISPER", sender) end
      end
    end
  elseif msg.t == "D" then
    local key = Str(msg.key, 80)
    if peer.included and key and not db.chars[key] then
      local rec = Sync.CleanRecord(msg.rec)
      if rec then
        rec.peer = id
        db.remote[key] = rec
        ns.UpdateNeeds(rec)
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
  for id, peer in pairs(DB().peers) do
    if peer.name and peer.name:lower() == name then return id, peer end
  end
end
Sync.PeerByName = PeerByName

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
end)
ns.On("PLAYER_ENTERING_WORLD", function() Sync.Flush() end)
ns.On("ZONE_CHANGED_NEW_AREA", function() Sync.Flush() end)

-- Commands --------------------------------------------------------------------------------

ns.commands.sync = function()
  Sync.Announce()
  ns.Print(L["sync: sent to the players in your group"])
end

-- /comrade share [on|off]: share the current character (or stop).
ns.commands.share = function(arg)
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
  local id = PeerByName(name)
  if id then
    Sync.Include(id)
    ns.Print(L["%s added to the group"]:format(name))
  elseif name and name ~= "" then
    Sync.pendingAdd = Sync.pendingAdd or {}
    Sync.pendingAdd[name:lower()] = true
    Sync.Send(Sync.Hello(), "WHISPER", name)
    ns.Print(L["%s contacted; added as soon as they answer"]:format(name))
  end
end

ns.commands.remove = function(name)
  local id = PeerByName(name)
  if id then
    Sync.Exclude(id)
    ns.Print(L["%s removed from the group"]:format(name))
  end
end
