-- Trade: when trading a group member, docks a compact Blizzard panel next to TradeFrame
-- listing what they need from your bags (profession & recipe) and highlights those items
-- in your bags (Blizzard, Baganator, Bagnon, ElvUI). One click places items; never accepts.
local _, ns = ...
local L = ns.L

local Trade = {}
ns.Trade = Trade

local PANEL_W, MAX_ROWS, MAX_SLOTS = 248, 6, 6
local isOpen, partnerKey = false, nil

local function NotifyBags()
  if ns.Bags and ns.Bags.Refresh then ns.Bags.Refresh() end
end

function Trade.IsOpen() return isOpen end
function Trade.CurrentRecipient() return isOpen and partnerKey or nil end

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link = get(id)
  local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
    or (GetItemIcon and GetItemIcon(id)) or 134400
  return name, link, icon
end

local function FindInBags(item)
  if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID == item and not info.isLocked then return bag, slot, info.stackCount or 1 end
    end
  end
end

local function FreeTradeSlot()
  for i = 1, MAX_SLOTS do
    if not (GetTradePlayerItemInfo and GetTradePlayerItemInfo(i)) then return i end
  end
end

-- Places one item stack (or split) into the next free trade slot. Never accepts trade.
function Trade.PlaceItem(item, n)
  if not isOpen or (InCombatLockdown and InCombatLockdown()) then return false end
  local slotIdx = FreeTradeSlot()
  if not slotIdx then
    ns.Print(L["Trade window is full (%d slots)."]:format(MAX_SLOTS))
    return false
  end
  local bag, slot, stack = FindInBags(item)
  if not bag then return false end
  local take = math.min(n or stack, stack)
  if take < stack and C_Container.SplitContainerItem then
    C_Container.SplitContainerItem(bag, slot, take)
  elseif C_Container.PickupContainerItem then
    C_Container.PickupContainerItem(bag, slot)
  end
  if ClickTradeButton then ClickTradeButton(slotIdx) end
  if CursorHasItem and CursorHasItem() and ClearCursor then ClearCursor() end
  return true
end

function Trade.PlaceAll()
  if not (isOpen and partnerKey and ns.Mail) then return end
  local items = ns.Mail.ItemsFor(partnerKey)
  local delay = 0
  for _, it in ipairs(items) do
    local item, qty = it.item, it.n
    if C_Timer and delay > 0 then
      C_Timer.After(delay, function() Trade.PlaceItem(item, qty) end)
    else
      if not Trade.PlaceItem(item, qty) then break end
    end
    delay = delay + 0.25
  end
end

local panel, button, rows

local function ItemReason(it)
  if it.request then return L["craft request"] end
  local parts = {}
  if it.prof then parts[#parts + 1] = it.prof end
  if it.spell and ns.SpellName then
    local sn = ns.SpellName(it.spell)
    if sn and not sn:find("^spell:") then parts[#parts + 1] = sn end
  end
  return table.concat(parts, " - ")
end

local function CreateRow(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(PANEL_W - 20, 28)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(22, 22)
  b.icon:SetPoint("LEFT", 2, 0)
  b.qty = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.qty:SetPoint("TOPRIGHT", -2, -2)
  b.qty:SetJustifyH("RIGHT")
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("TOPLEFT", 28, -2)
  b.name:SetPoint("RIGHT", b.qty, "LEFT", -4, 0)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.sub:SetPoint("BOTTOMLEFT", 28, 2)
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
    if self.itemID then Trade.PlaceItem(self.itemID, self.qtyNum or 1) end
  end)
  return b
end

local function CreatePanel()
  if panel or not TradeFrame then return end
  panel = CreateFrame("Frame", "ComradeCraftTradePanel", TradeFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(PANEL_W, 110)
  panel:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT", 4, -24)
  panel:SetFrameStrata("HIGH")
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
  panel.title:SetText("ComradeCraft")
  panel.sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  panel.sub:SetPoint("TOPLEFT", 10, -30)
  panel.sub:SetWidth(PANEL_W - 20)
  panel.sub:SetJustifyH("LEFT")
  button = CreateFrame("Button", "ComradeCraftTradeButton", panel, "UIPanelButtonTemplate")
  button:SetSize(PANEL_W - 20, 22)
  button:SetText(L["Place needed items"])
  button:SetScript("OnClick", Trade.PlaceAll)
  panel.foot = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  panel.foot:SetWidth(PANEL_W - 20)
  panel.foot:SetJustifyH("LEFT")
  rows = {}
end

function Trade.UpdatePanel()
  if not panel then return end
  if not (isOpen and partnerKey and ns.Mail) then
    panel:Hide()
    return
  end
  local items = ns.Mail.ItemsFor(partnerKey)
  if #items == 0 then
    panel:Hide()
    return
  end
  local chars = ns.AllChars()
  panel.sub:SetText(L["For %s"]:format(ns.ClassColored(partnerKey, chars[partnerKey] and chars[partnerKey].class)))
  for _, r in ipairs(rows) do r:Hide() end
  local y = -48
  for i = 1, math.min(#items, MAX_ROWS) do
    local it = items[i]
    local r = rows[i]
    if not r then r = CreateRow(panel) rows[i] = r end
    local name, _, icon = ItemInfo(it.item)
    r.itemID, r.qtyNum = it.item, it.n
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(icon)
    r.name:SetText(name or ("item:" .. it.item))
    r.qty:SetText("|cffffd100x" .. it.n .. "|r")
    r.sub:SetText(ItemReason(it))
    r:Show()
    y = y - 30
  end
  button:ClearAllPoints()
  button:SetPoint("TOPLEFT", 10, y - 4)
  button:Show()
  y = y - 30
  panel.foot:SetPoint("TOPLEFT", 10, y - 2)
  panel.foot:SetText("|cff80ff80" .. L["Highlighted in your bags"] .. "|r")
  panel:SetHeight(-y + 22)
  panel:Show()
end

ns.On("TRADE_SHOW", function()
  isOpen = true
  local name = UnitName and UnitName("NPC")
  if name and (issecretvalue and issecretvalue(name)) then name = nil end
  partnerKey = name and ns.Mail and ns.Mail.KeyForName(name) or nil
  CreatePanel()
  Trade.UpdatePanel()
  NotifyBags()
end)

ns.On("TRADE_CLOSED", function()
  isOpen, partnerKey = false, nil
  if panel then panel:Hide() end
  NotifyBags()
end)
ns.On("BAG_UPDATE_DELAYED", function() if isOpen then Trade.UpdatePanel() end end)
