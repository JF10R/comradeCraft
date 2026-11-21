-- Core: events, SavedVariables, slash command.
local ADDON, ns = ...
ns.name = ADDON
ns.LOGO = "Interface\\AddOns\\ComradeCraft\\Media\\Logo" -- 64x64 TGA (minimap, window, addon list)

local frame = CreateFrame("Frame")
ns.frame = frame

local LOG_MAX = 2000 -- lines kept in ComradeCraftDB.log (oldest dropped)

-- Appends a plain-text line to the SavedVariables log (written to disk on /reload or logout).
local function Log(line)
  if not ComradeCraftDB then return end
  local log = ComradeCraftDB.log
  if not log then
    log = {}
    ComradeCraftDB.log = log
  end
  local plain = tostring(line):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  log[#log + 1] = date("%Y-%m-%d %H:%M:%S") .. " " .. plain
  if #log > LOG_MAX then table.remove(log, 1) end
end
ns.Log = Log

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37ComradeCraft|r " .. tostring(msg))
  Log(msg)
end
ns.Print = Print

local function NormRealm(r)
  return type(r) == "string" and r:gsub("[%s%-']", ""):lower() or ""
end

local cachedRealm
local function RealmName()
  local r = GetRealmName and GetRealmName()
  if type(r) == "string" and r ~= "" then
    cachedRealm = r
    return r
  end
  if cachedRealm then return cachedRealm end
  if GetCVar then
    local cr = GetCVar("realmName")
    if type(cr) == "string" and cr ~= "" then
      cachedRealm = cr
      return cr
    end
  end
  local name = UnitName and UnitName("player")
  if name and name ~= "" and ComradeCraftDB and ComradeCraftDB.chars then
    local prefix = name .. "-"
    for k in pairs(ComradeCraftDB.chars) do
      if k:sub(1, #prefix) == prefix and #k > #prefix then
        cachedRealm = k:sub(#prefix + 1)
        return cachedRealm
      end
    end
  end
  if UnitFullName then
    local _, ur = UnitFullName("player")
    if type(ur) == "string" and ur ~= "" then
      cachedRealm = ur
      return ur
    end
  end
  r = GetNormalizedRealmName and GetNormalizedRealmName()
  if type(r) == "string" and r ~= "" then
    cachedRealm = r
    return r
  end
  return nil
end

function ns.CharKey()
  local name = UnitName and UnitName("player") or ""
  local realm = RealmName()
  return realm and (name .. "-" .. realm) or name
end

-- Merges broken "Name-" keys and realm-alias duplicates (e.g. GetRealmName vs
-- GetNormalizedRealmName on Forever), keeping newest stats + known recipes + share flags.
local function CleanBrokenCharKeys()
  local chars = ComradeCraftDB and ComradeCraftDB.chars
  if not chars then return end
  local realm = RealmName()
  local aliases = {}
  local function AddAlias(v)
    local nr = NormRealm(v)
    if nr ~= "" then aliases[nr] = true end
  end
  AddAlias(realm)
  if GetRealmName then AddAlias(GetRealmName()) end
  if GetNormalizedRealmName then AddAlias(GetNormalizedRealmName()) end
  if GetCVar then AddAlias(GetCVar("realmName")) end
  if UnitFullName then local _, ur = UnitFullName("player") AddAlias(ur) end
  local normCur = NormRealm(realm)
  local groups = {}
  for key in pairs(chars) do
    local bare, r = key:match("^([^-]+)-(.*)$")
    if not bare then bare, r = key, "" end
    local nr = NormRealm(r)
    if (nr == "" or aliases[nr]) and normCur ~= "" then nr = normCur end
    if nr ~= "" then
      local gkey = bare:lower() .. "|" .. nr
      groups[gkey] = groups[gkey] or {}
      table.insert(groups[gkey], key)
    end
  end
  for _, list in pairs(groups) do
    if #list > 1 or list[1]:match("-$") or not list[1]:find("-", 1, true) then
      local canonical
      for _, k in ipairs(list) do
        if realm and k:sub(-#realm - 1) == "-" .. realm then canonical = k break end
      end
      if not canonical then
        for _, k in ipairs(list) do
          if k:find("-", 1, true) and not k:match("-$") and (not canonical or #k > #canonical) then canonical = k end
        end
      end
      if not canonical and realm then
        canonical = (list[1]:match("^([^-]+)") or list[1]) .. "-" .. realm
      end
      if canonical then
        local best, bestU, shared, listed, mergedKnown = nil, -1, nil, nil, {}
        for _, k in ipairs(list) do
          local v = chars[k]
          if v then
            if v.shared then shared = true end
            if v.listed then listed = true end
            for line, set in pairs(v.known or {}) do
              if not mergedKnown[line] then mergedKnown[line] = set end
            end
            if (v.updated or 0) > bestU then best, bestU = v, (v.updated or 0) end
          end
        end
        if best then
          if shared then best.shared = true end
          if listed then best.listed = true end
          best.known = best.known or {}
          for line, set in pairs(mergedKnown) do
            if not best.known[line] then best.known[line] = set end
          end
          chars[canonical] = best
          for _, k in ipairs(list) do
            if k ~= canonical then
              chars[k] = nil
              if ComradeCraftDB.ui and ComradeCraftDB.ui.sel == k then ComradeCraftDB.ui.sel = canonical end
            end
          end
        end
      end
    end
  end
end

-- Returns (and creates) the SavedVariables entry for the current character.
local scratchChar = {}
function ns.CharData()
  local realm = RealmName()
  if not realm then return scratchChar end
  local key = (UnitName and UnitName("player") or "") .. "-" .. realm
  local c = ComradeCraftDB.chars[key]
  if not c then
    c = {}
    if ComradeCraftDB.settings and ComradeCraftDB.settings.autoShareNew then c.shared = true end
    ComradeCraftDB.chars[key] = c
  end
  local _, class = UnitClass("player")
  c.class = class
  c.level = UnitLevel and UnitLevel("player") or c.level
  return c
end

-- Every character the group views show: this account's characters plus the ones received
-- from peers the player included (Sync.lua). Local characters always win on a key clash.
function ns.AllChars()
  local all = {}
  local db = ComradeCraftDB
  if not db then return all end
  for key, rec in pairs(db.remote or {}) do
    local peer = db.peers and db.peers[rec.peer]
    if peer and peer.included then all[key] = rec end
  end
  for key, c in pairs(db.chars or {}) do all[key] = c end
  return all
end

local handlers = {}
ns.handlers = handlers

function handlers.ADDON_LOADED(name)
  if name ~= ADDON then return end
  ComradeCraftDB = ComradeCraftDB or {}
  ComradeCraftDB.version = 1
  ComradeCraftDB.chars = ComradeCraftDB.chars or {}
  CleanBrokenCharKeys()
  frame:UnregisterEvent("ADDON_LOADED")
end

frame:SetScript("OnEvent", function(_, event, ...)
  local h = handlers[event]
  if h then h(...) end
end)
frame:RegisterEvent("ADDON_LOADED")

-- Lets other files register events: ns.On("EVENT", fn)
-- Events missing on this client are skipped (RegisterEvent errors on unknown events).
function ns.On(event, fn)
  local prev = handlers[event]
  handlers[event] = prev and function(...) prev(...) fn(...) end or fn
  pcall(frame.RegisterEvent, frame, event)
end

ns.On("PLAYER_LOGIN", CleanBrokenCharKeys)
ns.On("PLAYER_ENTERING_WORLD", CleanBrokenCharKeys)

-- Recomputes the current character's needs and redraws the window, coalesced: a burst
-- of events (Create All, looting) triggers one recompute 0.3 s after the last one.
local refreshPending = false
function ns.RequestRefresh()
  if refreshPending then return end
  local function run()
    refreshPending = false
    if ComradeCraftDB and ComradeCraftDB.chars then ns.UpdateNeeds(ns.CharData()) end
    if ns.Alerts then ns.Alerts.CheckMats() end
    if ns.Wishlist then ns.Wishlist.CheckReady() ns.Wishlist.RefreshTracker() end
    if ns.RefreshFarm then ns.RefreshFarm() end -- farming tracker + completed assignments
    if ns.RefreshWindow then ns.RefreshWindow() end
    if ns.RefreshTracker then ns.RefreshTracker() end
    if ns.Bags and ns.Bags.Refresh then ns.Bags.Refresh() end
    if ns.Sync then ns.Sync.MarkDirty() end -- peers hear about the change (debounced)
    if ns.Directory then ns.Directory.MarkDirty() end -- guild directory: ranks and recipes only
  end
  if C_Timer and C_Timer.After then
    refreshPending = true
    C_Timer.After(0.3, run)
  else
    run()
  end
end

local commands = {}
ns.commands = commands

SLASH_COMRADECRAFT1 = "/comrade"
SlashCmdList.COMRADECRAFT = function(msg)
  local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  cmd = cmd:lower()
  local fn = commands[cmd == "" and "show" or cmd]
  if fn then
    Log("> /comrade " .. (msg or ""))
    -- Errors are logged with their stack, then re-raised so BugSack still shows them.
    local ok, err = xpcall(function() fn(rest) end, function(e)
      return tostring(e) .. "\n" .. (debugstack and debugstack(2) or "")
    end)
    if not ok then
      Log("ERROR " .. err)
      error(err, 0)
    end
  else
    Print(ns.L["commands: /comrade (window) | share [off] | list [off] | directory [text] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"])
  end
end

commands.log = function(rest)
  if rest == "clear" then
    ComradeCraftDB.log = {}
    Print(ns.L["log cleared"])
  else
    Print(ns.L["%d lines in the log (written to disk on /reload or logout)"]:format(
      #(ComradeCraftDB.log or {})))
  end
end
