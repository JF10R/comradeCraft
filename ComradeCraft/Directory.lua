-- Directory: opt-in guild crafter directory. A character marked listed (c.listed, per character,
-- separate from c.shared) sends its professions and known recipes to the guild ("G" message):
-- on GUILD at login and after a rank or recipe change (5 min debounce), by whisper in answer to
-- a guildmate's login ping. Received entries live in ComradeCraftDB.directory only; they never
-- reach db.remote, ns.AllChars() or anything computed from it (needs, plans, alerts).
local _, ns = ...
local L = ns.L

local Directory = {}
ns.Directory = Directory

local DEBOUNCE = 300           -- seconds between a local change and the next guild broadcast
local REPLY_COOLDOWN = 300     -- seconds between two whispered answers to the same player
local PING_WINDOW = 60         -- whispered entries accepted this long after our own guild ping
local EXPIRE = 30 * 86400      -- entries not seen for 30 days are dropped
local MAX_TOTAL, MAX_PER_ACCOUNT, MAX_RECIPES, MAX_PROFS = 300, 50, 1500, 20
local MAX_ROWS = 50            -- search results shown in the window

local function ShortName(key) return key:match("^[^-]+") or key end

local function DB()
  ComradeCraftDB.directory = ComradeCraftDB.directory or {}
  return ComradeCraftDB.directory
end

local function InGuild() return IsInGuild and IsInGuild() and true or false end

-- Current guild name (nil if unknown). SavedVariables are account-wide: entries and listed
-- characters are kept per guild so alts in another guild never mix in.
local function Guild()
  local g = InGuild() and GetGuildInfo and GetGuildInfo("player")
  if g and ComradeCraftDB and ComradeCraftDB.chars then
    local c = ComradeCraftDB.chars[ns.CharKey()]
    if c then c.guild = g end
  end
  return g or nil
end
Directory.Guild = Guild

-- Local data -> wire ----------------------------------------------------------------------

-- Wire shape: { [charKey] = { cl, lv, p = { [skillLine] = { rank, max, name } }, r = { [skillLine] = { spellID, ... } } } }
local function Entry(c)
  local p, r = {}, {}
  for name, x in pairs(c.professions or {}) do
    local line = x.skillLine
    if line then
      p[line] = { x.rank or 0, x.max or 0, name }
      local list = {}
      for spell in pairs((c.known or {})[line] or {}) do list[#list + 1] = spell end
      if #list > 0 then r[line] = list end
    end
  end
  return { cl = c.class, lv = c.level, p = p, r = r }
end

local function ListedChars()
  local out, n, g = {}, 0, Guild()
  for key, c in pairs(ComradeCraftDB and ComradeCraftDB.chars or {}) do
    if c.listed and (not g or c.guild == g) and n < MAX_PER_ACCOUNT then
      out[key] = c
      n = n + 1
    end
  end
  return out, n
end

function Directory.HasListed()
  local _, n = ListedChars()
  return n > 0
end

function Directory.Message()
  local chars = {}
  for key, c in pairs(ListedChars()) do chars[key] = Entry(c) end
  return { t = "G", v = ns.Sync.PROTO, id = ComradeCraftDB.accountId, c = chars }
end

-- Ranks and recipe sets of the listed characters (not c.updated, which moves on every bag change).
function Directory.Signature()
  local parts = {}
  for key, c in pairs(ListedChars()) do
    for _, x in pairs(c.professions or {}) do
      if x.skillLine then
        local n, sum = 0, 0
        for spell in pairs((c.known or {})[x.skillLine] or {}) do n, sum = n + 1, sum + spell end
        parts[#parts + 1] = ("%s:%d:%d/%d:%d:%d"):format(key, x.skillLine, x.rank or 0, x.max or 0, n, sum)
      end
    end
    if not next(c.professions or {}) then parts[#parts + 1] = key end
  end
  table.sort(parts)
  return table.concat(parts, ";")
end

-- Receiving -------------------------------------------------------------------------------

-- Pure: one received character entry, validated (nil if malformed).
function Directory.Clean(e)
  if type(e) ~= "table" then return nil end
  local S = ns.Sync
  local out = { cl = S.Class(e.cl), lv = S.Num(e.lv, 1, 200), p = {}, r = {} }
  local np = 0
  for line, x in pairs(type(e.p) == "table" and e.p or {}) do
    line = S.Num(line, 1, 2 ^ 24)
    if line and type(x) == "table" and np < MAX_PROFS then
      out.p[line] = { S.Num(x[1], 0, 1000) or 0, S.Num(x[2], 0, 1000) or 0, S.Str(x[3], 40) }
      np = np + 1
    end
  end
  local nr = 0
  for line, list in pairs(type(e.r) == "table" and e.r or {}) do
    line = S.Num(line, 1, 2 ^ 24)
    if line and out.p[line] and type(list) == "table" then
      for _, spell in ipairs(list) do
        spell = S.Num(spell, 1, 2 ^ 31)
        local rec = spell and ns.Recipes[spell]
        if rec and rec[1] == line and nr < MAX_RECIPES and not out.r[spell] then
          out.r[spell] = true
          nr = nr + 1
        end
      end
    end
  end
  return out
end

local indexStale = true
local lastPing = 0     -- time of our own guild ping (whispered entries are accepted shortly after)
local replied = {}     -- [sender] = time of our last whispered answer

function Directory.NotePing() lastPing = time() end

-- Keeps MAX_TOTAL entries at most (oldest seen dropped first) and forgets those 30 days old.
local function Prune()
  local db, keys, now = DB(), {}, time()
  for key, e in pairs(db) do
    if type(e) ~= "table" or now - (e.seen or 0) > EXPIRE then db[key] = nil else keys[#keys + 1] = key end
  end
  if #keys > MAX_TOTAL then
    table.sort(keys, function(a, b) return (db[a].seen or 0) < (db[b].seen or 0) end)
    for i = 1, #keys - MAX_TOTAL do db[keys[i]] = nil end
  end
  indexStale = true
end

-- A "G" from account `id`: replaces every entry of that account (an empty one removes them).
function Directory.OnEntry(id, msg, dist, sender)
  if dist == "WHISPER" then
    if time() - lastPing > PING_WINDOW then return end
  elseif dist ~= "GUILD" then
    return
  end
  if type(msg.c) ~= "table" then return end
  local db, own = DB(), ComradeCraftDB.chars or {}
  local fresh, n, g = {}, 0, Guild()
  for key, e in pairs(msg.c) do
    key = ns.Sync.Str(key, 80)
    local clean = key and not own[key] and n < MAX_PER_ACCOUNT and Directory.Clean(e)
    if clean then
      clean.peer, clean.name, clean.seen, clean.guild = id, sender, time(), g
      fresh[key] = clean
      n = n + 1
    end
  end
  for key, e in pairs(db) do
    if e.peer == id then db[key] = nil end
  end
  for key, e in pairs(fresh) do db[key] = e end
  Prune()
end

-- A guildmate logged in (their ping on GUILD): whisper our entry after a short random delay.
function Directory.OnPing(sender, dist)
  if dist ~= "GUILD" or not (InGuild() and Directory.HasListed()) then return end
  if time() - (replied[sender] or 0) < REPLY_COOLDOWN then return end
  replied[sender] = time()
  local function Reply()
    if InGuild() and Directory.HasListed() then ns.Sync.Send(Directory.Message(), "WHISPER", sender) end
  end
  if C_Timer then C_Timer.After(math.random(2, 10), Reply) else Reply() end
end

-- Sending ---------------------------------------------------------------------------------

local lastSignature, dirtyPending = nil, false

-- Broadcast on GUILD when something is listed, or once (empty) after the last character is unlisted.
function Directory.Broadcast()
  if not (ComradeCraftDB and InGuild()) then return false end
  local db = ComradeCraftDB
  if not (Directory.HasListed() or db.directoryAnnounced) then return false end
  ns.Sync.Send(Directory.Message(), "GUILD")
  db.directoryAnnounced = Directory.HasListed() or nil
  lastSignature = Directory.Signature()
  return true
end

-- Debounced check: rebroadcast only when ranks or recipe sets of listed characters changed.
function Directory.Flush()
  dirtyPending = false
  if not Directory.HasListed() then return end
  local sig = Directory.Signature()
  if sig == lastSignature then return end
  indexStale = true
  Directory.Broadcast()
end

function Directory.MarkDirty()
  if dirtyPending or not C_Timer or not Directory.HasListed() then return end
  dirtyPending = true
  C_Timer.After(DEBOUNCE, Directory.Flush)
end

function Directory.SetListed(key, on)
  local c = ComradeCraftDB.chars[key]
  if not c then return end
  c.listed = on or nil
  indexStale = true
  Directory.Broadcast()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- Index and search ------------------------------------------------------------------------

-- Every directory character: received entries plus this account's listed characters.
-- Each: { key, cl, lv, p, r, peer, name, seen, own }.
local index
function Directory.Invalidate()
  indexStale = true
end

local function SortFavKeys(list)
  table.sort(list, function(a, b)
    local fa = ns.IsFavorite and ns.IsFavorite(a) or false
    local fb = ns.IsFavorite and ns.IsFavorite(b) or false
    if fa ~= fb then return fa end
    return a < b
  end)
end

local function Rebuild()
  local chars, bySpell, byItem = {}, {}, {}
  local g = Guild()
  for key, e in pairs(DB()) do
    if not (g and e.guild and e.guild ~= g) then chars[key] = { key = key, cl = e.cl, lv = e.lv, p = e.p, r = e.r, peer = e.peer, name = e.name, seen = e.seen } end
  end
  for key, c in pairs(ListedChars()) do
    local e = Entry(c)
    local r = {}
    for _, list in pairs(e.r) do for _, spell in ipairs(list) do r[spell] = true end end
    chars[key] = { key = key, cl = c.class, lv = c.level, p = e.p, r = r, own = true }
  end
  for key, e in pairs(chars) do
    for spell in pairs(e.r or {}) do
      bySpell[spell] = bySpell[spell] or {}
      table.insert(bySpell[spell], key)
      local item = ns.Recipes[spell] and ns.Recipes[spell][5]
      if item and item ~= 0 then
        byItem[item] = byItem[item] or {}
        if not byItem[item][key] then
          byItem[item][key] = true
          table.insert(byItem[item], key)
        end
      end
    end
  end
  for _, list in pairs(byItem) do SortFavKeys(list) end
  for _, list in pairs(bySpell) do SortFavKeys(list) end
  index = { chars = chars, bySpell = bySpell, byItem = byItem }
  indexStale = false
end

function Directory.Index()
  if indexStale or not index then Rebuild() end
  return index
end

local function GetName(spell)
  local item = ns.Recipes[spell] and ns.Recipes[spell][5]
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local iname = item and item ~= 0 and get and get(item)
  return iname, ns.SpellName(spell), item
end

-- Recipes whose product or spell name contains `text` (case-insensitive):
-- { { spell, item, name, crafters = { key, ... } } }, sorted by name.
function Directory.Search(text)
  text = (text or ""):lower()
  local out = {}
  if text == "" then return out end
  for spell, keys in pairs(Directory.Index().bySpell) do
    local iname, sname, item = GetName(spell)
    if (iname and iname:lower():find(text, 1, true)) or (sname and sname:lower():find(text, 1, true)) then
      out[#out + 1] = { spell = spell, item = item, name = iname or sname, crafters = keys }
    end
  end
  table.sort(out, function(a, b) return a.name < b.name or (a.name == b.name and a.spell < b.spell) end)
  return out
end

-- "A, B, C +2", class colored.
function Directory.Names(keys, max)
  local chars, names = Directory.Index().chars, {}
  for i = 1, math.min(#keys, max) do
    local e = chars[keys[i]]
    names[i] = ns.ClassColored(keys[i], e and e.cl)
  end
  local text = table.concat(names, ", ")
  if #keys > max then text = text .. (" +%d"):format(#keys - max) end
  return text
end

-- Item tooltip: one line when a directory crafter makes this item.
function Directory.AddTooltip(tooltip, itemID)
  if not (itemID and ComradeCraftDB) then return end
  local keys = Directory.Index().byItem[itemID]
  if not keys or #keys == 0 then return end
  tooltip:AddLine(L["Guild crafters: %s"]:format(Directory.Names(keys, 3)), 0.5, 0.8, 1)
  tooltip:Show()
end

-- Contact: whisper the account's last seen character (or the crafter itself).
function Directory.WhisperTarget(key)
  local e = Directory.Index().chars[key]
  if not e or e.own then return nil end
  local peer = e.peer and ComradeCraftDB.peers and ComradeCraftDB.peers[e.peer]
  return (peer and peer.name) or e.name or ShortName(key)
end

function Directory.Whisper(key)
  local target = Directory.WhisperTarget(key)
  if not target then return end
  if ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. target .. " ")
  elseif ChatFrame_SendTell then ChatFrame_SendTell(target) end
end

-- "Request craft" only works for characters received from an included group member.
function Directory.CanRequest(key)
  local c = ns.AllChars()[key]
  return c and c.peer and true or false
end

-- Wiring ----------------------------------------------------------------------------------

ns.On("PLAYER_LOGIN", function()
  if not ComradeCraftDB then return end
  Prune()
  if C_Timer then C_Timer.After(12, Directory.Broadcast) end
end)
-- Joining, leaving or switching guild: the index shows the current guild's entries only.
ns.On("PLAYER_GUILD_UPDATE", function() indexStale = true end)

-- /comrade list [off]: lists the current character in the guild directory (or stops).
ns.commands.list = function(arg)
  local on = arg ~= "off"
  Directory.SetListed(ns.CharKey(), on)
  ns.Print((on and L["%s is listed in the guild directory"] or L["%s is no longer listed in the guild directory"])
    :format(ns.CharKey()))
  if on and not InGuild() then ns.Print(L["You are not in a guild: the entry is sent once you are."]) end
end

-- /comrade directory [text]: who in the guild crafts it.
ns.commands.directory = function(text)
  local idx = Directory.Index()
  if not text or text == "" then
    local n = 0
    for _ in pairs(idx.chars) do n = n + 1 end
    ns.Print(L["directory: %d characters listed. /comrade directory TEXT searches them."]:format(n))
    return
  end
  local found = Directory.Search(text)
  if #found == 0 then
    ns.Print(L["directory: no crafter for %s"]:format(text))
    return
  end
  for i = 1, math.min(#found, 10) do
    ns.Print(("%s: %s"):format(found[i].name, Directory.Names(found[i].crafters, 5)))
  end
  if #found > 10 then ns.Print(L["... and %d more"]:format(#found - 10)) end
end

Directory.MAX_ROWS = MAX_ROWS
