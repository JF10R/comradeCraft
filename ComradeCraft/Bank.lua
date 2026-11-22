-- Bank: compact Blizzard side panel docked beside the bank window.
-- Lists items stored in your bank needed right now (for your current plan step, Wishlist,
-- or to mail to group members) and withdraws them into your bags in 1 click.
local _, ns = ...
local L = ns.L

local Bank = {}
ns.Bank = Bank

local PANEL_W, MAX_ROWS, STEP_DELAY = 256, 8, 0.25
local isOpen, dismissed = false, false

local function BankBagIndexes()
  local list = { BANK_CONTAINER or -1 }
  local first = (NUM_BAG_SLOTS or 4) + (NUM_REAGENTBAG_SLOTS or 0) + 1
  for b = first, first + (NUM_BANKBAGSLOTS or 6) - 1 do list[#list + 1] = b end
  return list
end

local function PlayerBagIndexes()
  local list = {}
  for b = 0, (NUM_BAG_SLOTS or 4) do list[#list + 1] = b end
  if NUM_REAGENTBAG_SLOTS and NUM_REAGENTBAG_SLOTS > 0 then
    list[#list + 1] = (NUM_BAG_SLOTS or 4) + 1
  end
  return list
end

-- Pure: items in the current character's bank worth withdrawing right now:
-- { { item, n, reason, prio, to? } } (own plan / Wishlist first, then group sends).
function Bank.Items()
  local out = {}
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return out end
  local me = ns.CharKey()
  local c = ComradeCraftDB.chars[me]
  if not (c and c.bank) then return out end
  local bank, bags = c.bank, c.bags or {}
  local byItem = {}
  local function Add(item, qty, reason, prio, to)
    local avail = bank[item] or 0
    if avail <= 0 or qty <= 0 then return end
    local e = byItem[item]
    if not e then
      e = { item = item, n = 0, reason = reason, prio = prio, to = to }
      byItem[item] = e
      out[#out + 1] = e
    elseif prio < e.prio then
      e.reason, e.prio, e.to = reason, prio, to
    end
    e.n = math.min(avail, e.n + qty)
  end

  -- 1. Own Wishlist (line 0) and active step-1 profession needs not yet in bags.
  for line, need in pairs(c.needs or {}) do
    for item, gross in pairs(need.gross or {}) do
      local urgent = line == 0 or (need.when and need.when[item] == 1)
      if urgent and gross > 0 then
        local inBags = bags[item] or 0
        local t = ns.ITEM_TRANSFORMS and ns.ITEM_TRANSFORMS[item]
        if t then
          local pBags = bags[t.other] or 0
          inBags = inBags + (t.isSmall and (pBags * t.ratio) or math.floor(pBags / t.ratio))
        end
        local miss = gross - inBags
        if miss > 0 then
          local reason = line == 0 and L["Wishlist"] or L["For your plan"]
          if (bank[item] or 0) > 0 then
            local take = math.min(bank[item], miss)
            Add(item, take, reason, line == 0 and 1 or 2)
            miss = miss - take
          end
          if miss > 0 and t and (bank[t.other] or 0) > 0 then
            local wantP = t.isSmall and math.ceil(miss / t.ratio) or (miss * t.ratio)
            Add(t.other, wantP, reason, line == 0 and 1 or 2)
          end
        end
      end
    end
  end

  -- 2. Group sends currently stored in bank (mirrors GiveList bank-only / split items).
  for _, g in ipairs(ns.GiveList and ns.GiveList(me) or {}) do
    if (g.inBank or 0) > 0 then
      local who = g.to:match("^[^-]+") or g.to
      Add(g.item, g.inBank, L["To send to %s"]:format(who), 3, g.to)
    end
  end

  -- 3. Accepted/crafting incoming requests (craft output or shared bank alt items) stored in bank.
  for _, r in pairs(ComradeCraftDB.requests or {}) do
    if (r.status == "accepted" or r.status == "crafting") and r.to == me and ns.Requests and ns.Requests.Role(r) == "crafter"
      and r.item and r.item ~= 0 and (bank[r.item] or 0) > 0 then
      local mult = (r.spell and r.spell > 0 and ns.Recipes[r.spell] and ns.Recipes[r.spell][6]) or 1
      local need = r.qty * math.max(1, mult)
      local miss = math.max(0, need - (bags[r.item] or 0))
      if miss > 0 then
        local who = r.from:match("^[^-]+") or r.from
        Add(r.item, miss, L["To send to %s"]:format(who), 1, r.from)
      end
    end
  end

  -- 4. Manually reserved items ("for Mirandaa") currently stored in bank.
  for item, rv in pairs(c.reserved or {}) do
    local totalBank = bank[item] or 0
    if totalBank > 0 and rv and rv.to then
      local want = math.max(0, (rv.qty or totalBank) - (bags[item] or 0))
      if want > 0 then
        local who = rv.to:match("^[^-]+") or rv.to
        Add(item, want, "|cffc080ff" .. L["Reserved for %s"]:format(who) .. "|r", 1, rv.to)
      end
    end
  end

  table.sort(out, function(a, b)
    if a.prio ~= b.prio then return a.prio < b.prio end
    if a.n ~= b.n then return a.n > b.n end
    return a.item < b.item
  end)
  return out
end

local function FindInBank(item)
  if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
  for _, bag in ipairs(BankBagIndexes()) do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID == item and not info.isLocked then
        return bag, slot, info.stackCount or 1
      end
    end
  end
end

local function FindFreeBagSlot()
  if not (C_Container and C_Container.GetContainerNumSlots) then return nil end
  for _, bag in ipairs(PlayerBagIndexes()) do
    local free = C_Container.GetContainerNumFreeSlots and C_Container.GetContainerNumFreeSlots(bag) or 0
    if free > 0 then
      for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
        if not C_Container.GetContainerItemInfo(bag, slot) then return bag, slot end
      end
    end
  end
end

-- Withdraws up to `qty` of `item` from bank into player bags. Returns withdrawn count.
function Bank.WithdrawItem(item, qty)
  if not isOpen or (InCombatLockdown and InCombatLockdown()) then return 0 end
  local bag, slot, stack = FindInBank(item)
  if not bag then return 0 end
  local take = math.min(qty or stack, stack)
  if take >= stack and C_Container.UseContainerItem then
    C_Container.UseContainerItem(bag, slot)
    return stack
  end
  local dbag, dslot = FindFreeBagSlot()
  if not dbag then
    ns.Print(L["Your bags are full."])
    return 0
  end
  if C_Container.SplitContainerItem and C_Container.PickupContainerItem then
    C_Container.SplitContainerItem(bag, slot, take)
    C_Container.PickupContainerItem(dbag, dslot)
    if CursorHasItem and CursorHasItem() and ClearCursor then ClearCursor() end
    return take
  end
  return 0
end

local queue, running = {}, false
local function Step()
  local job = queue[1]
  if not (job and isOpen) or (InCombatLockdown and InCombatLockdown()) then
    queue, running = {}, false
    return
  end
  local moved = Bank.WithdrawItem(job.item, job.n)
  if moved <= 0 then
    table.remove(queue, 1)
  else
    job.n = job.n - moved
    if job.n <= 0 then table.remove(queue, 1) end
  end
  if #queue > 0 and C_Timer and C_Timer.After then
    C_Timer.After(STEP_DELAY, Step)
  else
    running = false
    if Bank.UpdatePanel then Bank.UpdatePanel() end
  end
end

function Bank.WithdrawAll()
  if not isOpen then return end
  local items = Bank.Items()
  if #items == 0 then return end
  for _, it in ipairs(items) do queue[#queue + 1] = { item = it.item, n = it.n } end
  if not running then
    running = true
    Step()
  end
end

-- Side panel docked to the bank window (Blizzard BankFrame or Bagnon/BagBrother bank) -----

local panel, button, rows

local function BankAnchor()
  for _, name in ipairs({ "BagnonBankFrame1", "BagnonFramebank", "ElvUI_BankContainerFrame", "BankFrame" }) do
    local f = _G[name]
    if f and f.IsShown and f:IsShown() then return f end
  end
  return BankFrame
end

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name = get and get(id)
  local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
    or (GetItemIcon and GetItemIcon(id)) or 134400
  return name, icon
end

local function CreateRow(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(PANEL_W - 20, 28)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(20, 20)
  b.icon:SetPoint("LEFT", 2, 0)
  b.qty = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.qty:SetPoint("TOPRIGHT", -2, -2)
  b.qty:SetJustifyH("RIGHT")
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("TOPLEFT", 26, -2)
  b.name:SetPoint("RIGHT", b.qty, "LEFT", -4, 0)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.sub:SetPoint("BOTTOMLEFT", 26, 2)
  b.sub:SetPoint("RIGHT", -2, 0)
  b.sub:SetJustifyH("LEFT")
  b.sub:SetWordWrap(false)
  b:SetScript("OnEnter", function(self)
    if self.itemID then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.itemID)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if self.itemID and (self.qtyNum or 0) > 0 then
      Bank.WithdrawItem(self.itemID, self.qtyNum)
    end
  end)
  return b
end

local function AnchorPanel()
  if not panel then return end
  local anchor = BankAnchor()
  panel:ClearAllPoints()
  if anchor then
    panel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, -12)
  else
    panel:SetPoint("CENTER", UIParent, "CENTER", 220, 40)
  end
end

local function CreatePanel()
  if panel then return end
  panel = CreateFrame("Frame", "ComradeCraftBankPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(PANEL_W, 120)
  panel:SetFrameStrata("DIALOG")
  AnchorPanel()
  if panel.SetBackdrop then
    panel:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    panel:SetBackdropColor(0.06, 0.05, 0.04, 0.94)
    panel:SetBackdropBorderColor(0.8, 0.68, 0.35, 1)
  end
  panel.logo = panel:CreateTexture(nil, "ARTWORK")
  panel.logo:SetSize(16, 16)
  panel.logo:SetPoint("TOPLEFT", 10, -10)
  panel.logo:SetTexture(ns.LOGO)
  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  panel.title:SetPoint("LEFT", panel.logo, "RIGHT", 6, 0)
  panel.title:SetText(L["Withdraw from bank"])
  panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  panel.close:SetSize(22, 22)
  panel.close:SetPoint("TOPRIGHT", -2, -2)
  panel.close:SetScript("OnClick", function()
    dismissed = true
    panel:Hide()
  end)
  panel.sub = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  panel.sub:SetPoint("TOPLEFT", 10, -30)
  panel.sub:SetWidth(PANEL_W - 20)
  panel.sub:SetJustifyH("LEFT")
  button = CreateFrame("Button", "ComradeCraftBankButton", panel, "UIPanelButtonTemplate")
  button:SetSize(PANEL_W - 20, 22)
  button:SetText(L["Withdraw needed"])
  button:SetScript("OnClick", Bank.WithdrawAll)
  rows = {}
end

function Bank.UpdatePanel()
  if not panel then return end
  if dismissed or not isOpen or (ns.PanelEnabled and not ns.PanelEnabled("bank")) then
    panel:Hide()
    return
  end
  local items = Bank.Items()
  if #items == 0 then
    panel:Hide()
    return
  end
  AnchorPanel()
  panel.sub:SetText(L["Click an item to withdraw it."])
  for _, r in ipairs(rows) do r:Hide() end
  local y = -46
  for i = 1, math.min(#items, MAX_ROWS) do
    local it = items[i]
    local r = rows[i]
    if not r then r = CreateRow(panel) rows[i] = r end
    local name, icon = ItemInfo(it.item)
    r.itemID, r.qtyNum = it.item, it.n
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(icon)
    r.name:SetText(name or ("item:" .. it.item))
    r.qty:SetText("|cffffd100x" .. it.n .. "|r")
    r.sub:SetText(it.reason or "")
    r:Show()
    y = y - 30
  end
  button:ClearAllPoints()
  button:SetPoint("TOPLEFT", 10, y - 4)
  button:Show()
  panel:SetHeight(-y + 34)
  panel:Show()
end

ns.On("BANKFRAME_OPENED", function()
  isOpen, dismissed = true, false
  CreatePanel()
  Bank.UpdatePanel()
  if C_Timer and C_Timer.After then C_Timer.After(0.1, Bank.UpdatePanel) end
end)
ns.On("BANKFRAME_CLOSED", function()
  isOpen, queue, running = false, {}, false
  if panel then panel:Hide() end
end)
ns.On("PLAYERBANKSLOTS_CHANGED", function() if isOpen then Bank.UpdatePanel() end end)
ns.On("BAG_UPDATE_DELAYED", function() if isOpen then Bank.UpdatePanel() end end)
