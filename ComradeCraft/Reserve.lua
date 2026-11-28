-- Reserve: tag/lock items in your bags or bank for a specific group member ("for Mirandaa").
-- Locally: distinct violet border + lock icon in bags, anti-sell warning at merchants/AH,
-- auto-queued in Bank withdraw & Mail/Trade for that recipient, and auto-cleared once sent.
-- Synced to your group so the recipient sees "Reserved for you by X" before you even mail it.
-- Trigger: Alt+Right-click any bag item (Blizzard, Bagnon/BagBrother, ElvUI) or /comrade reserve.
local _, ns = ...
local L = ns.L

local Reserve = {}
ns.Reserve = Reserve

local function CharData()
  return ComradeCraftDB and ComradeCraftDB.chars and ns.CharData and ns.CharData() or nil
end

local function OwnedTotal(c, itemID)
  if not (c and itemID) then return 0, 0, 0 end
  local b = (c.bags or {})[itemID] or 0
  local k = (c.bank or {})[itemID] or 0
  return b + k, b, k
end

-- Returns { to = charKey, qty = n, t = ts } if the current character reserved `itemID`.
function Reserve.Get(itemID)
  local c = CharData()
  return c and c.reserved and itemID and c.reserved[itemID] or nil
end

-- Reserves `itemID` on the current character for `toKey` (defaults to full owned count).
function Reserve.Set(itemID, toKey, qty)
  local c = CharData()
  if not (c and itemID and itemID > 0 and type(toKey) == "string" and toKey ~= "") then return false end
  if ns.IsBoP and ns.IsBoP(itemID) then return false end
  local total = OwnedTotal(c, itemID)
  qty = math.max(1, math.floor(tonumber(qty) or (total > 0 and total or 1)))
  c.reserved = c.reserved or {}
  c.reserved[itemID] = { to = toKey, qty = qty, t = time() }
  c.updated = time()
  if ns.ClearGiveCache then ns.ClearGiveCache() end
  if ns.Sync then ns.Sync.MarkDirty() end
  if ns.Bags and ns.Bags.Refresh then ns.Bags.Refresh() end
  if ns.Mail and ns.Mail.UpdatePanel then ns.Mail.UpdatePanel() end
  if ns.RefreshWindow then ns.RefreshWindow() end
  local who = toKey:match("^[^-]+") or toKey
  local name = ns.ItemName and ns.ItemName(itemID) or ("item:" .. itemID)
  if ns.PlaySound then ns.PlaySound("lock") end
  ns.Print(L["Reserved %dx %s for %s."]:format(qty, name, who))
  return true
end

-- Unlocks/releases a reservation on `itemID`.
function Reserve.Clear(itemID)
  local c = CharData()
  if not (c and c.reserved and itemID and c.reserved[itemID]) then return false end
  c.reserved[itemID] = nil
  if not next(c.reserved) then c.reserved = nil end
  c.updated = time()
  if ns.ClearGiveCache then ns.ClearGiveCache() end
  if ns.Sync then ns.Sync.MarkDirty() end
  if ns.Bags and ns.Bags.Refresh then ns.Bags.Refresh() end
  if ns.Mail and ns.Mail.UpdatePanel then ns.Mail.UpdatePanel() end
  if ns.RefreshWindow then ns.RefreshWindow() end
  local name = ns.ItemName and ns.ItemName(itemID) or ("item:" .. itemID)
  if ns.PlaySound then ns.PlaySound("unlock") end
  ns.Print(L["Reservation removed for %s."]:format(name))
  return true
end

-- Auto-clears reservations once the item has left your bags and bank (e.g. after mailing/trading).
function Reserve.Prune()
  local c = CharData()
  if not (c and c.reserved) then return end
  local changed = false
  for item, r in pairs(c.reserved) do
    local total = OwnedTotal(c, item)
    if total <= 0 then
      c.reserved[item] = nil
      changed = true
    elseif (r.qty or 0) > total then
      r.qty = total
      changed = true
    end
  end
  if not next(c.reserved) then c.reserved = nil end
  if changed then
    c.updated = time()
    if ns.ClearGiveCache then ns.ClearGiveCache() end
  end
end

-- Items reserved on the current character for `toKey`: { { item, n, inBags, inBank } }.
function Reserve.ForTarget(toKey)
  local out = {}
  local c = CharData()
  if not (c and c.reserved and toKey) then return out end
  for item, r in pairs(c.reserved) do
    if r.to == toKey or (ns.IsSameChar and ns.IsSameChar(r.to, toKey)) then
      local total, inBags, inBank = OwnedTotal(c, item)
      local want = math.min(total, r.qty or total)
      if want > 0 then
        local b = math.min(inBags, want)
        local k = math.min(inBank, want - b)
        out[#out + 1] = { item = item, n = b + k, inBags = b, inBank = k, reserved = true }
      end
    end
  end
  table.sort(out, function(a, b) return a.item < b.item end)
  return out
end

-- All characters in the group who currently reserved `itemID` for `targetKey`:
-- { { from = key, class = cls, qty = n }, ... }.
function Reserve.IncomingFor(targetKey, itemID)
  local out = {}
  if not (targetKey and itemID) then return out end
  for key, c in pairs(ns.AllChars()) do
    local r = c.reserved and c.reserved[itemID]
    if r and (r.to == targetKey or (ns.IsSameChar and ns.IsSameChar(r.to, targetKey))) and (r.qty or 0) > 0 then
      out[#out + 1] = { from = key, class = c.class, qty = r.qty }
    end
  end
  table.sort(out, function(a, b) return a.qty > b.qty or (a.qty == b.qty and a.from < b.from) end)
  return out
end

-- Candidate recipients for the Alt+Right-click reserve menu:
-- anyone who needs `itemID` (material need, unknown recipe/book, or gear upgrade) floats to the top
-- with a clear green/gold tag, followed by favorites and the rest of the group.
local function RecipientList(itemID)
  local me = ns.CharKey()
  local chars = ns.AllChars()
  local needTag, needPrio = {}, {}
  if itemID and itemID > 0 then
    -- 1. Unknown recipe or skill-rank book (e.g. Expert Cookbook -> Naine can learn now).
    local st = ns.Loot and ns.Loot.RecipeStatus and ns.Loot.RecipeStatus(itemID)
    if st and st.unknown then
      for _, u in ipairs(st.unknown) do
        local now = u.rank >= u.req
        needPrio[u.key] = now and 1 or 2
        needTag[u.key] = now and ("|cff40ff40(" .. L["can learn now"] .. ")|r")
          or ("|cffffd100(" .. L["needs skill %d"]:format(u.req) .. ")|r")
      end
    end
    -- 2. Crafting material need or gear upgrade per character.
    for key, c in pairs(chars) do
      if not needPrio[key] and not (ns.IsSameChar and ns.IsSameChar(key, me) or key == me) then
        local rows = ns.NeedRows and ns.NeedRows(c, itemID) or {}
        if #rows > 0 then
          local tot, bestStep = 0, 99
          for _, r in ipairs(rows) do
            tot = tot + (r.n or 0)
            if (r.step or 99) < bestStep then bestStep = r.step or 99 end
          end
          if tot > 0 then
            needPrio[key] = (ns.UrgencyRank and ns.UrgencyRank(bestStep) <= 1) and 1 or 2
            needTag[key] = "|cff40ff40(" .. L["needs %d"]:format(tot) .. ")|r"
          end
        elseif ns.UpgradeFor and c.equipped and ns.UpgradeFor(itemID, c) then
          needPrio[key] = 2
          needTag[key] = "|cff66ccff(" .. L["Gear"] .. ")|r"
        end
      end
    end
  end
  local list = {}
  for key, c in pairs(chars) do
    if not (ns.IsSameChar and ns.IsSameChar(key, me) or key == me) then
      list[#list + 1] = { key = key, class = c.class, fav = ns.IsFavorite and ns.IsFavorite(key) or false,
        prio = needPrio[key] or 9, tag = needTag[key] }
    end
  end
  table.sort(list, function(a, b)
    if a.prio ~= b.prio then return a.prio < b.prio end
    if a.fav ~= b.fav then return a.fav end
    return a.key < b.key
  end)
  return list
end

-- Popup menu for tagging/untagging a bag item (MenuUtil on modern/Forever clients, native fallback).
local fallbackMenu, fallbackBtns
local function ShowFallbackMenu(owner, itemID, cur, list)
  if not fallbackMenu then
    fallbackMenu = CreateFrame("Frame", "ComradeCraftReserveMenu", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    fallbackMenu:SetFrameStrata("TOOLTIP")
    fallbackMenu:SetClampedToScreen(true)
    if fallbackMenu.SetBackdrop then
      fallbackMenu:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
      fallbackMenu:SetBackdropColor(0.06, 0.05, 0.04, 0.96)
      fallbackMenu:SetBackdropBorderColor(0.8, 0.68, 0.35, 1)
    end
    fallbackMenu.title = fallbackMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fallbackMenu.title:SetPoint("TOPLEFT", 10, -8)
    fallbackBtns = {}
    if UISpecialFrames then tinsert(UISpecialFrames, "ComradeCraftReserveMenu") end
  end
  for _, b in ipairs(fallbackBtns) do b:Hide() end
  fallbackMenu.title:SetText(L["Reserve for..."])
  local entries = {}
  if cur then
    entries[#entries + 1] = { text = "|cffff8080" .. L["Unlock reservation"] .. "|r",
      fn = function() Reserve.Clear(itemID) end }
  end
  for i = 1, math.min(#list, 14) do
    local rec = list[i]
    local star = rec.fav and "|cffffd100* |r" or ""
    local suffix = rec.tag and (" " .. rec.tag) or ""
    entries[#entries + 1] = { text = star .. ns.ClassColored(rec.key, rec.class) .. suffix,
      fn = function() Reserve.Set(itemID, rec.key) end }
  end
  local y = -24
  for i, e in ipairs(entries) do
    local b = fallbackBtns[i]
    if not b then
      b = CreateFrame("Button", nil, fallbackMenu)
      b:SetSize(176, 18)
      b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
      b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      b.text:SetPoint("LEFT", 4, 0)
      b.text:SetJustifyH("LEFT")
      fallbackBtns[i] = b
    end
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", 8, y)
    b.text:SetText(e.text)
    b:SetScript("OnClick", function() e.fn() fallbackMenu:Hide() end)
    b:Show()
    y = y - 19
  end
  fallbackMenu:SetSize(192, -y + 10)
  fallbackMenu:ClearAllPoints()
  if owner then fallbackMenu:SetPoint("TOPLEFT", owner, "TOPRIGHT", 4, 0)
  else fallbackMenu:SetPoint("CENTER") end
  fallbackMenu:Show()
end

function Reserve.OpenMenu(owner, itemID)
  if not (itemID and itemID > 0) or (ns.IsBoP and ns.IsBoP(itemID)) then return false end
  local cur = Reserve.Get(itemID)
  local list = RecipientList(itemID)
  if not cur and #list == 0 then return false end
  if MenuUtil and MenuUtil.CreateContextMenu then
    local ok = pcall(MenuUtil.CreateContextMenu, owner or UIParent, function(_, root)
      root:CreateTitle(L["Reserve for..."])
      if cur then
        root:CreateButton("|cffff8080" .. L["Unlock reservation"] .. "|r", function() Reserve.Clear(itemID) end)
        root:CreateDivider()
      end
      local hadNeed = false
      for i = 1, math.min(#list, 16) do
        local rec = list[i]
        if hadNeed and rec.prio >= 9 then
          root:CreateDivider()
          hadNeed = false
        elseif rec.prio < 9 then
          hadNeed = true
        end
        local star = rec.fav and "|cffffd100* |r" or ""
        local suffix = rec.tag and (" " .. rec.tag) or ""
        root:CreateButton(star .. ns.ClassColored(rec.key, rec.class) .. suffix, function() Reserve.Set(itemID, rec.key) end)
      end
    end)
    if ok then return true end
  end
  ShowFallbackMenu(owner, itemID, cur, list)
  return true
end

-- Alt+Right-click hook on Blizzard, Bagnon/BagBrother, Combuctor, Baganator, BetterBags & ElvUI bag buttons.
local hookedButtons = setmetatable({}, { __mode = "k" })
local lastClickT, lastClickBtn = 0, nil

local function BagButtonItem(self, fallbackBag)
  -- Check bag addons' authoritative live slot table FIRST (Bagnon/BagBrother/BetterBags reuse
  -- pooled buttons across bags/slots, so self.info.itemID is always the exact item under cursor).
  if type(self.info) == "table" and type(self.info.itemID) == "number" then
    local bag = self.bag or (self.GetBag and self:GetBag()) or (self.GetBagID and self:GetBagID())
    local slot = (self.GetID and self:GetID()) or self.slot
    local isBound = self.info.isBound
    if isBound == nil and type(bag) == "number" and type(slot) == "number"
      and C_Container and C_Container.GetContainerItemInfo then
      local ci = C_Container.GetContainerItemInfo(bag, slot)
      if ci and ci.itemID == self.info.itemID then isBound = ci.isBound end
    end
    return self.info.itemID, isBound
  end
  if type(self.data) == "table" and type(self.data.itemInfo) == "table"
    and type(self.data.itemInfo.itemID) == "number" then
    return self.data.itemInfo.itemID, self.data.itemInfo.isBound
  end
  local bag = (self.GetBagID and self:GetBagID()) or (self.GetBag and self:GetBag())
    or self.bagID or self.bag
    or (self.GetParent and self:GetParent() and self:GetParent().GetID and self:GetParent():GetID())
    or fallbackBag
  local slot = (self.GetID and self:GetID()) or self.slotID or self.slot
  if type(bag) == "number" and type(slot) == "number" and C_Container and C_Container.GetContainerItemInfo then
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info and info.itemID then return info.itemID, info.isBound end
  end
  if type(self.itemID) == "number" then return self.itemID, false end
end

local function OnBagClick(self, button)
  if button ~= "RightButton" or not (IsAltKeyDown and IsAltKeyDown()) then return end
  if InCombatLockdown and InCombatLockdown() then return end
  -- Post-hook: the click already sold/deposited/attached the item at these windows.
  for _, name in ipairs({ "MerchantFrame", "BankFrame", "MailFrame", "TradeFrame" }) do
    local fr = _G[name]
    if fr and fr.IsShown and fr:IsShown() then return end
  end
  local now = GetTime and GetTime() or 0
  if lastClickBtn == self and math.abs(now - lastClickT) < 0.05 then return end
  lastClickT, lastClickBtn = now, self
  local itemID, isBound = BagButtonItem(self, hookedButtons[self])
  if itemID and (not isBound or Reserve.Get(itemID)) then
    Reserve.OpenMenu(self, itemID)
  end
end

-- Called by Bags.lua on every live bag slot button (Blizzard, Bagnon, Baganator, BetterBags, ElvUI, etc.).
function Reserve.AttachButton(btn, fallbackBag)
  if not (btn and btn.HookScript) then return end
  local already = hookedButtons[btn] ~= nil
  hookedButtons[btn] = fallbackBag or false -- keep fallbackBag fresh when addons recycle pooled buttons
  if not already then
    pcall(btn.HookScript, btn, "OnClick", OnBagClick)
  end
end

local hookedBagClick = false
local function HookBagClicks()
  if hookedBagClick or not hooksecurefunc then return end
  hookedBagClick = true
  if ContainerFrameItemButtonMixin then
    if type(ContainerFrameItemButtonMixin.OnModifiedClick) == "function" then
      pcall(hooksecurefunc, ContainerFrameItemButtonMixin, "OnModifiedClick", OnBagClick)
    end
    if type(ContainerFrameItemButtonMixin.OnClick) == "function" then
      pcall(hooksecurefunc, ContainerFrameItemButtonMixin, "OnClick", OnBagClick)
    end
  end
  if ContainerFrameItemButton_OnModifiedClick then
    pcall(hooksecurefunc, "ContainerFrameItemButton_OnModifiedClick", OnBagClick)
  end
  for _, name in ipairs({ "Bagnon", "Combuctor", "BagBrother" }) do
    local addon = _G[name]
    if type(addon) == "table" then
      for _, cls in ipairs({ addon.ContainerItem, addon.Item, addon.ItemSlot }) do
        if type(cls) == "table" and type(cls.OnClick) == "function" then
          pcall(hooksecurefunc, cls, "OnClick", OnBagClick)
        end
      end
    end
  end
end

ns.On("PLAYER_LOGIN", HookBagClicks)

-- Slash commands: /comrade reserve [itemLink|itemID] <name> [qty]  |  /comrade unreserve [itemLink|itemID]
ns.commands.reserve = function(rest)
  local id = tonumber((rest or ""):match("item:(%d+)")) or tonumber((rest or ""):match("^(%d+)"))
  local tail = (rest or ""):gsub("|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r", ""):gsub("^%s*%d+%s*", ""):match("^%s*(.-)%s*$")
  local name, qty = tail:match("^(.-)%s+(%d+)$")
  if not name then name = tail end
  local key = name ~= "" and ns.Mail and ns.Mail.KeyForName and ns.Mail.KeyForName(name)
  if not (id and key) then
    ns.Print(L["Usage: /comrade reserve [Item] Name [qty]"])
    return
  end
  Reserve.Set(id, key, tonumber(qty))
end

ns.commands.unreserve = function(rest)
  local id = tonumber((rest or ""):match("item:(%d+)")) or tonumber((rest or ""):match("(%d+)"))
  if not id then
    ns.Print(L["Usage: /comrade unreserve [Item]"])
    return
  end
  Reserve.Clear(id)
end
