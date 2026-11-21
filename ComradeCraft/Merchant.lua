-- Merchant: when talking to a vendor who sells reagents needed by your profession plans
-- or Wishlist (thread, dyes, vials, flux...), docks a compact Blizzard panel next to
-- MerchantFrame so you can buy the exact missing quantities in one click.
local _, ns = ...
local L = ns.L

local Merchant = {}
ns.Merchant = Merchant

local PANEL_W, MAX_ROWS = 248, 8
local isOpen = false

-- Pure: missing vendor reagents of the current character that this merchant sells.
-- Returns { { index, item, need, stackSize, price, cost }, ... }, totalCost.
function Merchant.PlanItems()
  local out, total = {}, 0
  if not (ComradeCraftDB and ComradeCraftDB.chars and GetMerchantNumItems and GetMerchantItemID) then
    return out, total
  end
  local c = ComradeCraftDB.chars[ns.CharKey()]
  if not c then return out, total end
  local wanted = {}
  for _, need in pairs(c.needs or {}) do
    for item, n in pairs(need.vendor or {}) do
      if n > 0 then wanted[item] = (wanted[item] or 0) + n end
    end
  end
  if not next(wanted) then return out, total end
  local seen = {}
  for i = 1, GetMerchantNumItems() do
    local id = GetMerchantItemID(i)
    local need = id and not seen[id] and wanted[id]
    if need and need > 0 then
      local price, stackSize, avail
      if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local info = C_MerchantFrame.GetItemInfo(i)
        if info then price, stackSize, avail = info.price, info.stackCount, info.numAvailable end
      elseif GetMerchantItemInfo then
        local _, _, p, q, av = GetMerchantItemInfo(i)
        price, stackSize, avail = p, q, av
      end
      if price and price > 0 and (avail == nil or avail == -1 or avail > 0) then
        seen[id] = true
        stackSize = math.max(1, stackSize or 1)
        local buyQty = avail and avail > 0 and math.min(need, avail) or need
        local batches = math.ceil(buyQty / stackSize)
        local cost = batches * price
        total = total + cost
        out[#out + 1] = { index = i, item = id, need = buyQty, stackSize = stackSize, price = price, cost = cost }
      end
    end
  end
  table.sort(out, function(a, b) return a.need > b.need end)
  return out, total
end

function Merchant.BuyAll()
  if not (isOpen and BuyMerchantItem) then return 0 end
  local items, total = Merchant.PlanItems()
  if #items == 0 then return 0 end
  if GetMoney and GetMoney() < total then
    ns.Print(L["Not enough gold (%s needed)."]:format(ns.Money(total)))
    return 0
  end
  local bought = 0
  for _, it in ipairs(items) do
    local maxStack = (GetMerchantItemMaxStack and GetMerchantItemMaxStack(it.index)) or 20
    if maxStack < 1 then maxStack = 1 end
    local left = it.need
    while left > 0 do
      local chunk = math.min(left, maxStack)
      BuyMerchantItem(it.index, chunk)
      left = left - chunk
      bought = bought + chunk
    end
  end
  ns.Log(("merchant: bought %d plan reagents (%s)"):format(bought, ns.Money(total)))
  return bought
end

-- Panel docked to the right of MerchantFrame ----------------------------------------------

local panel, button, rows

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name = get and get(id)
  local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
    or (GetItemIcon and GetItemIcon(id)) or 134400
  return name, icon
end

local function CreateRow(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(PANEL_W - 20, 22)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(18, 18)
  b.icon:SetPoint("LEFT", 2, 0)
  b.cost = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.cost:SetPoint("RIGHT", -2, 0)
  b.cost:SetJustifyH("RIGHT")
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("LEFT", 24, 0)
  b.name:SetPoint("RIGHT", b.cost, "LEFT", -6, 0)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b:SetScript("OnEnter", function(self)
    if self.itemID then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.itemID)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

local function CreatePanel()
  if panel or not MerchantFrame then return end
  panel = CreateFrame("Frame", "ComradeCraftMerchantPanel", MerchantFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(PANEL_W, 100)
  panel:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 4, -24)
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
  panel.title:SetText(L["Plan reagents"])
  button = CreateFrame("Button", "ComradeCraftMerchantButton", panel, "UIPanelButtonTemplate")
  button:SetSize(PANEL_W - 20, 22)
  button:SetScript("OnClick", function()
    Merchant.BuyAll()
    if C_Timer then C_Timer.After(0.4, Merchant.UpdatePanel) else Merchant.UpdatePanel() end
  end)
  rows = {}
end

function Merchant.UpdatePanel()
  if not panel then return end
  if not isOpen then panel:Hide() return end
  local items, total = Merchant.PlanItems()
  if #items == 0 then panel:Hide() return end
  for _, r in ipairs(rows) do r:Hide() end
  local y = -34
  for i = 1, math.min(#items, MAX_ROWS) do
    local it = items[i]
    local r = rows[i]
    if not r then r = CreateRow(panel) rows[i] = r end
    local name, icon = ItemInfo(it.item)
    r.itemID = it.item
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(icon)
    r.name:SetText(("%dx %s"):format(it.need, name or ("item:" .. it.item)))
    r.cost:SetText("|cffffd100" .. ns.Money(it.cost) .. "|r")
    r:Show()
    y = y - 24
  end
  button:ClearAllPoints()
  button:SetPoint("TOPLEFT", 10, y - 4)
  button:SetText(L["Buy plan reagents (%s)"]:format(ns.Money(total)))
  button:Show()
  panel:SetHeight(-y + 36)
  panel:Show()
end

ns.On("MERCHANT_SHOW", function()
  isOpen = true
  CreatePanel()
  Merchant.UpdatePanel()
end)
ns.On("MERCHANT_CLOSED", function()
  isOpen = false
  if panel then panel:Hide() end
end)
ns.On("BAG_UPDATE_DELAYED", function() if isOpen then Merchant.UpdatePanel() end end)
