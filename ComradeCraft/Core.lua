-- Core: events, SavedVariables, slash command.
local ADDON, ns = ...
ns.name = ADDON

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

function ns.CharKey()
  return UnitName("player") .. "-" .. GetRealmName()
end

-- Returns (and creates) the SavedVariables entry for the current character.
function ns.CharData()
  local key = ns.CharKey()
  local c = ComradeCraftDB.chars[key]
  if not c then
    c = {}
    ComradeCraftDB.chars[key] = c
  end
  local _, class = UnitClass("player")
  c.class = class
  c.level = UnitLevel and UnitLevel("player") or c.level
  return c
end

local handlers = {}
ns.handlers = handlers

function handlers.ADDON_LOADED(name)
  if name ~= ADDON then return end
  ComradeCraftDB = ComradeCraftDB or {}
  ComradeCraftDB.version = 1
  ComradeCraftDB.chars = ComradeCraftDB.chars or {}
  frame:UnregisterEvent("ADDON_LOADED")
end

frame:SetScript("OnEvent", function(_, event, ...)
  local h = handlers[event]
  if h then h(...) end
end)
frame:RegisterEvent("ADDON_LOADED")

-- Lets other files register events: ns.On("EVENT", fn)
function ns.On(event, fn)
  local prev = handlers[event]
  handlers[event] = prev and function(...) prev(...) fn(...) end or fn
  frame:RegisterEvent(event)
end

-- Recomputes the current character's needs and redraws the window, coalesced: a burst
-- of events (Create All, looting) triggers one recompute 0.3 s after the last one.
local refreshPending = false
function ns.RequestRefresh()
  if refreshPending then return end
  local function run()
    refreshPending = false
    if ComradeCraftDB and ComradeCraftDB.chars then ns.UpdateNeeds(ns.CharData()) end
    if ns.RefreshWindow then ns.RefreshWindow() end
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
    Print(ns.L["commands: /comrade (window) | scan | needs | stats | dump | api | audit | log clear"])
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
