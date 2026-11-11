-- Alerts: short notices (chat line + a toast) for things worth acting on. Each kind can be
-- turned off in Manage group > Options; "a group member can craft your upgrade" is opt-in.
--   mats      your bags now hold everything for the next craft of a profession step
--   cooldown  a profession cooldown (Mooncloth, transmutes...) is ready on one of your characters
--   requests  a craft request arrived or changed (printed by Requests.lua)
--   upgrade   a group member's character can craft an upgrade for you (opt-in)
local _, ns = ...
local L = ns.L

local Alerts = {}
ns.Alerts = Alerts

local DEFAULTS = { mats = true, cooldown = true, requests = true, upgrade = false }
local LONG_CD = 600 -- seconds: shorter cooldowns (the global one) are not profession cooldowns
local TOAST_TIME = 12

local function Now() return (GetServerTime and GetServerTime()) or time() end
local function State()
  ComradeCraftDB.alerts = ComradeCraftDB.alerts or {}
  local a = ComradeCraftDB.alerts
  a.upgradeSeen = a.upgradeSeen or {}
  a.cdAlerted = a.cdAlerted or {}
  return a
end

function Alerts.On(kind)
  local s = ComradeCraftDB and ComradeCraftDB.settings and ComradeCraftDB.settings.alerts
  local v = s and s[kind]
  if v == nil then return DEFAULTS[kind] end
  return v
end
function Alerts.Set(kind, on)
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  ComradeCraftDB.settings.alerts = ComradeCraftDB.settings.alerts or {}
  ComradeCraftDB.settings.alerts[kind] = on
end

-- Toast ------------------------------------------------------------------------------------

local toast, queue = nil, {}
local ShowNext

local function CreateToast()
  toast = CreateFrame("Button", "ComradeCraftToast", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  toast:SetSize(340, 76)
  toast:SetPoint("TOP", 0, -140)
  toast:SetFrameStrata("DIALOG")
  local solid = toast:CreateTexture(nil, "BACKGROUND", nil, -8)
  solid:SetPoint("TOPLEFT", 4, -4)
  solid:SetPoint("BOTTOMRIGHT", -4, 4)
  solid:SetColorTexture(0.06, 0.05, 0.04, 0.95)
  if toast.SetBackdrop then
    toast:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    toast:SetBackdropBorderColor(1, 0.82, 0, 1)
  end
  toast.icon = toast:CreateTexture(nil, "ARTWORK")
  toast.icon:SetSize(36, 36)
  toast.icon:SetPoint("TOPLEFT", 10, -10)
  toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  toast.title:SetPoint("TOPLEFT", 54, -10)
  toast.title:SetWidth(260)
  toast.title:SetJustifyH("LEFT")
  toast.text = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  toast.text:SetPoint("TOPLEFT", toast.title, "BOTTOMLEFT", 0, -3)
  toast.text:SetWidth(270)
  toast.text:SetJustifyH("LEFT")
  toast.close = CreateFrame("Button", nil, toast, "UIPanelCloseButton")
  toast.close:SetSize(22, 22)
  toast.close:SetPoint("TOPRIGHT", -2, -2)
  toast.close:SetScript("OnClick", function() toast:Hide() ShowNext() end)
  toast.buttons = {}
  for i = 1, 2 do
    local b = CreateFrame("Button", nil, toast, "UIPanelButtonTemplate")
    b:SetSize(120, 20)
    b:SetScript("OnClick", function(self)
      if self.fn then self.fn() end
      toast:Hide()
      ShowNext()
    end)
    toast.buttons[i] = b
  end
  toast.buttons[1]:SetPoint("BOTTOMRIGHT", -10, 10)
  toast.buttons[2]:SetPoint("RIGHT", toast.buttons[1], "LEFT", -6, 0)
  toast:SetScript("OnEnter", function(self)
    if self.item then
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:SetItemByID(self.item)
      GameTooltip:Show()
    end
  end)
  toast:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function ShowNext()
  local t = table.remove(queue, 1)
  if not t then return end
  if not toast then CreateToast() end
  toast.icon:SetTexture(t.icon or 134400)
  toast.title:SetText(t.title)
  toast.text:SetText(t.text or "")
  toast.item = t.item
  for i, b in ipairs(toast.buttons) do
    local spec = t.buttons and t.buttons[i]
    b.fn = spec and spec[2]
    b:SetText(spec and spec[1] or "")
    b:SetShown(spec ~= nil)
  end
  local h = 30 + (toast.title:GetStringHeight() or 12) + (toast.text:GetStringHeight() or 12) + (t.buttons and 26 or 0)
  toast:SetHeight(math.max(60, h))
  toast:Show()
  local shown = toast
  local token = {}
  toast.token = token
  if C_Timer and not t.sticky then
    C_Timer.After(TOAST_TIME, function()
      if shown.token == token and shown:IsShown() then shown:Hide() ShowNext() end
    end)
  end
end

-- Chat line + toast { title, text, icon, item, buttons = { { label, fn } }, sticky }.
function Alerts.Notify(t)
  ns.Print(t.title .. (t.text and t.text ~= "" and (" - " .. t.text) or ""))
  queue[#queue + 1] = t
  if not (toast and toast:IsShown()) then ShowNext() end
end

-- Mats ready ------------------------------------------------------------------------------

local readyState = {} -- [skillLine] = spell that was ready at the last check (no alert on first look)
local primed = false

function Alerts.CheckMats()
  if not (ComradeCraftDB and ComradeCraftDB.chars and ns.CraftQueue and Alerts.On("mats")) then return end
  local c = ns.CharData()
  for name, p in pairs(c.professions or {}) do
    local line = p.skillLine
    if line and c.needs and c.needs[line] then
      local nxt = ns.NextCraft((ns.CraftQueue(c, p, "step")))
      local now = nxt and nxt.ready >= nxt.n and nxt.spell or nil
      if primed and now and readyState[line] ~= now then
        Alerts.Notify({ title = L["%s: mats ready"]:format(name),
          text = L["Your bags hold everything for %dx %s."]:format(nxt.n, nxt.label or ns.SpellName(now)),
          icon = p.icon, item = nxt.item ~= 0 and nxt.item or nil })
      end
      readyState[line] = now
    end
  end
  primed = true
end

-- Profession cooldowns --------------------------------------------------------------------

local function Cooldown(spell)
  if C_Spell and C_Spell.GetSpellCooldown then
    local cd = C_Spell.GetSpellCooldown(spell)
    if type(cd) == "table" then return cd.startTime or 0, cd.duration or 0 end
  end
  if GetSpellCooldown then
    local start, duration = GetSpellCooldown(spell)
    return start or 0, duration or 0
  end
  return 0, 0
end

-- Records, for this character, when each known recipe with a long cooldown is ready again
-- (server time), so alts' cooldowns can be announced from any character.
function Alerts.ScanCooldowns()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local c = ns.CharData()
  c.cooldowns = c.cooldowns or {}
  for _, set in pairs(c.known or {}) do
    for spell in pairs(set) do
      local start, duration = Cooldown(spell)
      if duration > LONG_CD then
        c.cooldowns[spell] = math.floor(Now() + (start + duration - (GetTime and GetTime() or 0)))
      elseif duration == 0 and c.cooldowns[spell] and c.cooldowns[spell] > Now() + 60 then
        c.cooldowns[spell] = Now() -- reset early (a game change): ready
      end
    end
  end
end

-- Announces each cooldown that became ready (once per ready time).
function Alerts.CheckCooldowns()
  if not (ComradeCraftDB and ComradeCraftDB.chars and Alerts.On("cooldown")) then return end
  local st = State()
  for key, c in pairs(ComradeCraftDB.chars) do
    for spell, readyAt in pairs(c.cooldowns or {}) do
      local id = key .. "|" .. spell
      if readyAt <= Now() and st.cdAlerted[id] ~= readyAt then
        st.cdAlerted[id] = readyAt
        Alerts.Notify({ title = L["Cooldown ready: %s"]:format(ns.SpellName(spell)),
          text = L["on %s"]:format(key:match("^[^-]+") or key),
          icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spell) or nil })
      end
    end
  end
end

-- Upgrades a group member can craft (opt-in) ----------------------------------------------

-- Short stat summary for players without Pawn: "+5 Intellect, +3 Stamina" (top 3).
local function StatSummary(item)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local _, link = get(item)
  local stats = link and ((C_Item and C_Item.GetItemStats and C_Item.GetItemStats(link)) or (GetItemStats and GetItemStats(link)))
  local list = {}
  for k, v in pairs(type(stats) == "table" and stats or {}) do
    local name = _G[k]
    if type(name) == "string" and type(v) == "number" and v > 0 and not k:find("DAMAGE") then
      list[#list + 1] = { name = name, v = v }
    end
  end
  table.sort(list, function(a, b) return a.v > b.v end)
  local out = {}
  for i = 1, math.min(3, #list) do out[i] = ("+%d %s"):format(list[i].v, list[i].name) end
  return table.concat(out, ", ")
end

-- For the current character: recipes of group members (other accounts) whose product is an
-- upgrade, not shown before. Returns { { key, spell, item, gain, how } }.
function Alerts.FindUpgrades()
  local me = ns.CharData()
  local st, out = State(), {}
  for key, c in pairs(ns.AllChars()) do
    if c.peer then
      for _, set in pairs(c.known or {}) do
        for spell in pairs(set) do
          local r = ns.Recipes[spell]
          local item = r and r[5]
          local seenKey = ns.CharKey() .. "|" .. spell
          if item and item ~= 0 and not st.upgradeSeen[seenKey] then
            local up, gain, how = ns.UpgradeFor(item, me)
            if up and gain then out[#out + 1] = { key = key, spell = spell, item = item, gain = gain, how = how } end
          end
        end
      end
    end
  end
  table.sort(out, function(a, b) return a.gain > b.gain end)
  return out
end

function Alerts.CheckUpgrades()
  if not (ComradeCraftDB and ComradeCraftDB.chars and Alerts.On("upgrade")) then return end
  local st = State()
  for i, u in ipairs(Alerts.FindUpgrades()) do
    if i > 3 then break end -- a few at a time; the rest come next check
    local seenKey = ns.CharKey() .. "|" .. u.spell
    st.upgradeSeen[seenKey] = true
    local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local name, _, _, _, _, _, _, _, _, icon = get(u.item)
    local detail = u.how == "pawn" and L["+%d with Pawn"]:format(math.floor(u.gain + 0.5))
      or (L["+%d item levels"]:format(math.floor(u.gain + 0.5)) .. (function()
        local s = StatSummary(u.item)
        return s ~= "" and (" (" .. s .. ")") or ""
      end)())
    Alerts.Notify({ title = L["%s can craft an upgrade for you"]:format(u.key:match("^[^-]+") or u.key),
      text = (name or ns.SpellName(u.spell)) .. ": " .. detail, icon = icon, item = u.item, sticky = true,
      buttons = { { L["Ask for it"], function() ns.Requests.ShowDialog(u.key, u.spell) end },
        { L["Not interested"], function() end } } })
  end
end

-- Wiring ----------------------------------------------------------------------------------

local cdPending = false
ns.On("SPELL_UPDATE_COOLDOWN", function()
  if cdPending or not C_Timer then return end
  cdPending = true
  C_Timer.After(2, function() cdPending = false Alerts.ScanCooldowns() end)
end)
ns.On("PLAYER_LOGIN", function()
  if not C_Timer then return end
  C_Timer.After(20, function()
    Alerts.ScanCooldowns()
    Alerts.CheckCooldowns()
    Alerts.CheckUpgrades()
  end)
  if C_Timer.NewTicker then C_Timer.NewTicker(60, Alerts.CheckCooldowns) end
end)
