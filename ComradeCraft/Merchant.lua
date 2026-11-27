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

-- Pure: skill-rank books (Expert Cookbook/First Aid/Fishing) and unknown vendor recipes on this
-- merchant that you or a friend in your group still need (even if buried on Page 3!).
-- Returns { { index, item, price, canLearn, isRankBook, who = { shortName, ... } }, ... }.
function Merchant.RecipeItems()
  local out = {}
  if not (ComradeCraftDB and ComradeCraftDB.chars and GetMerchantNumItems and GetMerchantItemID
    and ns.Loot and ns.Loot.RecipeStatus) then return out end
  local meKey = ns.CharKey()
  local seen = {}
  for i = 1, GetMerchantNumItems() do
    local id = GetMerchantItemID(i)
    if id and not seen[id] then
      local st = ns.Loot.RecipeStatus(id)
      if st and #st.unknown > 0 then
        local bop = ns.IsBoP and ns.IsBoP(id)
        local who, canLearn, forMe = {}, false, false
        for _, u in ipairs(st.unknown) do
          if not bop or u.key == meKey then
            if u.rank >= u.req then canLearn = true end
            if u.key == meKey then forMe = true end
            who[#who + 1] = u.key:match("^[^-]+") or u.key
          end
        end
        if #who > 0 then
          local price, avail
          if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
            local info = C_MerchantFrame.GetItemInfo(i)
            if info then price, avail = info.price, info.numAvailable end
          elseif GetMerchantItemInfo then
            local _, _, p, _, av = GetMerchantItemInfo(i)
            price, avail = p, av
          end
          if avail == nil or avail == -1 or avail > 0 then
            seen[id] = true
            out[#out + 1] = { index = i, item = id, price = price or 0, canLearn = canLearn,
              forMe = forMe, isRankBook = st.isRankBook, who = who }
          end
        end
      end
    end
  end
  table.sort(out, function(a, b)
    if (a.isRankBook and 1 or 0) ~= (b.isRankBook and 1 or 0) then return a.isRankBook end
    if a.canLearn ~= b.canLearn then return a.canLearn end
    if a.forMe ~= b.forMe then return a.forMe end
    return a.item < b.item
  end)
  return out
end

-- Highlights matching items directly on Blizzard's native MerchantItem1..10 slots
-- (bright emerald for learnable books/recipes, gold for upcoming recipes or plan reagents).
local slotOverlays = {}
local function GetSlotOverlay(btn)
  local ov = slotOverlays[btn]
  if ov then return ov end
  local edges = {}
  local T = 2
  local top = btn:CreateTexture(nil, "OVERLAY")
  top:SetHeight(T)
  top:SetPoint("TOPLEFT", 0, 0)
  top:SetPoint("TOPRIGHT", 0, 0)
  local bot = btn:CreateTexture(nil, "OVERLAY")
  bot:SetHeight(T)
  bot:SetPoint("BOTTOMLEFT", 0, 0)
  bot:SetPoint("BOTTOMRIGHT", 0, 0)
  local lft = btn:CreateTexture(nil, "OVERLAY")
  lft:SetWidth(T)
  lft:SetPoint("TOPLEFT", 0, 0)
  lft:SetPoint("BOTTOMLEFT", 0, 0)
  local rgt = btn:CreateTexture(nil, "OVERLAY")
  rgt:SetWidth(T)
  rgt:SetPoint("TOPRIGHT", 0, 0)
  rgt:SetPoint("BOTTOMRIGHT", 0, 0)
  local glow = btn:CreateTexture(nil, "ARTWORK")
  glow:SetAllPoints()
  glow:SetBlendMode("ADD")
  local tag = btn:CreateTexture(nil, "OVERLAY", nil, 2)
  tag:SetSize(14, 14)
  tag:SetPoint("TOPRIGHT", 2, 2)
  tag:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  edges[1], edges[2], edges[3], edges[4] = top, bot, lft, rgt
  ov = { edges = edges, glow = glow, tag = tag }
  slotOverlays[btn] = ov
  return ov
end

function Merchant.HighlightSlots()
  local perPage = MERCHANT_ITEMS_PER_PAGE or 10
  local onMerchant = isOpen and MerchantFrame and (MerchantFrame.selectedTab == nil or MerchantFrame.selectedTab == 1)
    and (not ns.PanelEnabled or ns.PanelEnabled("merchant"))
  local wantedRec, wantedMat = {}, {}
  if onMerchant then
    for _, r in ipairs(Merchant.RecipeItems()) do wantedRec[r.item] = r end
    for _, m in ipairs(Merchant.PlanItems()) do wantedMat[m.item] = true end
  end
  local page = (MerchantFrame and MerchantFrame.page) or 1
  for i = 1, perPage do
    local btn = _G["MerchantItem" .. i .. "ItemButton"]
    if btn then
      local idx = (page - 1) * perPage + i
      local id = onMerchant and GetMerchantItemID and GetMerchantItemID(idx) or nil
      local rec = id and wantedRec[id]
      local mat = id and wantedMat[id]
      if rec or mat then
        local ov = GetSlotOverlay(btn)
        local r, g, b
        if rec and rec.canLearn then
          r, g, b = 0.20, 1.00, 0.35 -- bright emerald: learnable right now!
        elseif rec then
          r, g, b = 0.40, 0.80, 1.00 -- sky blue: useful recipe/book for group soon
        else
          r, g, b = 1.00, 0.82, 0.15 -- warm gold: plan reagent
        end
        for _, e in ipairs(ov.edges) do e:SetColorTexture(r, g, b, 0.95) e:Show() end
        ov.glow:SetColorTexture(r, g, b, rec and rec.canLearn and 0.24 or 0.12)
        ov.glow:Show()
        ov.tag:SetShown(rec ~= nil)
      elseif slotOverlays[btn] then
        local ov = slotOverlays[btn]
        for _, e in ipairs(ov.edges) do e:Hide() end
        ov.glow:Hide()
        ov.tag:Hide()
      end
    end
  end
end

-- Buys `need` units of vendor slot `index`, chunking safely by maxStack and bundle stackSize
-- (passing > maxStack or a non-multiple of bundle size triggers WoW's "Internal Bag Error").
function Merchant.BuyItem(index, need, stackSize)
  if not (isOpen and BuyMerchantItem and index) then return 0 end
  stackSize = math.max(1, tonumber(stackSize) or 1)
  local maxStack = (GetMerchantItemMaxStack and GetMerchantItemMaxStack(index)) or 20
  if maxStack < stackSize then maxStack = stackSize end
  local maxChunk = math.max(stackSize, math.floor(maxStack / stackSize) * stackSize)
  local left = math.ceil(math.max(1, tonumber(need) or 1) / stackSize) * stackSize
  local bought = 0
  while left > 0 do
    local chunk = math.min(left, maxChunk)
    if chunk <= stackSize then
      BuyMerchantItem(index) -- exact 1 vendor stack (matches native Blizzard right-click)
    else
      BuyMerchantItem(index, chunk)
    end
    left = left - chunk
    bought = bought + chunk
  end
  return bought
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
    bought = bought + Merchant.BuyItem(it.index, it.need, it.stackSize)
  end
  ns.Log(("merchant: bought %d plan reagents (%s)"):format(bought, ns.Money(total)))
  return bought
end

-- Panel docked to the right of MerchantFrame ----------------------------------------------

local panel, button, rows, dismissed = nil, nil, nil, false

local function ItemInfo(id)
  local name = ns.ItemName and ns.ItemName(id)
  if not name then
    local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    name = get and get(id)
  end
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
  b:SetScript("OnClick", function(self)
    if self.buyIndex and Merchant.BuyItem then
      Merchant.BuyItem(self.buyIndex, self.buyQty or 1, self.buyStack or 1)
      if C_Timer then C_Timer.After(0.3, Merchant.UpdatePanel) else Merchant.UpdatePanel() end
    end
  end)
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
  panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  panel.close:SetSize(22, 22)
  panel.close:SetPoint("TOPRIGHT", -2, -2)
  panel.close:SetScript("OnClick", function() dismissed = true panel:Hide() end)
  button = CreateFrame("Button", "ComradeCraftMerchantButton", panel, "UIPanelButtonTemplate")
  button:SetSize(PANEL_W - 20, 22)
  button:SetScript("OnClick", function()
    Merchant.BuyAll()
    if C_Timer then C_Timer.After(0.4, Merchant.UpdatePanel) else Merchant.UpdatePanel() end
  end)
  rows = {}
end

function Merchant.UpdatePanel()
  Merchant.HighlightSlots()
  if not panel then return end
  if dismissed or not isOpen or (ns.PanelEnabled and not ns.PanelEnabled("merchant")) then panel:Hide() return end
  local items, total = Merchant.PlanItems()
  local recipes = Merchant.RecipeItems()
  if #items == 0 and #recipes == 0 then panel:Hide() return end
  for _, r in ipairs(rows) do r:Hide() end
  local y, idx = -34, 0
  -- Surface needed skill-rank books & vendor recipes first (even if hidden on Page 3!).
  for i = 1, math.min(#recipes, 4) do
    local rc = recipes[i]
    idx = idx + 1
    local r = rows[idx]
    if not r then r = CreateRow(panel) rows[idx] = r end
    local name, icon = ItemInfo(rc.item)
    r.itemID, r.buyIndex, r.buyQty, r.buyStack = rc.item, rc.index, 1, 1
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(icon)
    local tag = rc.canLearn and "|cff40ff40* |r" or "|cff66ccff* |r"
    local who = table.concat(rc.who, ", ")
    r.name:SetText(tag .. (name or ("item:" .. rc.item)) .. " |cff9d9d9d(" .. who .. ")|r")
    r.cost:SetText(rc.price > 0 and ("|cffffd100" .. ns.Money(rc.price) .. "|r") or "")
    r:Show()
    y = y - 24
  end
  for i = 1, math.min(#items, math.max(1, MAX_ROWS - idx)) do
    local it = items[i]
    idx = idx + 1
    local r = rows[idx]
    if not r then r = CreateRow(panel) rows[idx] = r end
    local name, icon = ItemInfo(it.item)
    r.itemID, r.buyIndex, r.buyQty, r.buyStack = it.item, it.index, it.need, it.stackSize or 1
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(icon)
    r.name:SetText(("%dx %s"):format(it.need, name or ("item:" .. it.item)))
    r.cost:SetText("|cffffd100" .. ns.Money(it.cost) .. "|r")
    r:Show()
    y = y - 24
  end
  if #items > 0 then
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", 10, y - 4)
    button:SetText(L["Buy plan reagents (%s)"]:format(ns.Money(total)))
    button:Show()
    panel:SetHeight(-y + 36)
  else
    button:Hide()
    panel:SetHeight(-y + 12)
  end
  panel:Show()
end

local merchantHooked
local function HookMerchantUI()
  if merchantHooked or not (hooksecurefunc and MerchantFrame_UpdateMerchantInfo) then return end
  merchantHooked = true
  hooksecurefunc("MerchantFrame_UpdateMerchantInfo", Merchant.HighlightSlots)
end

ns.On("MERCHANT_SHOW", function()
  isOpen, dismissed = true, false
  HookMerchantUI()
  CreatePanel()
  Merchant.UpdatePanel()
end)
ns.On("MERCHANT_UPDATE", function() if isOpen then Merchant.UpdatePanel() end end)
ns.On("MERCHANT_CLOSED", function()
  isOpen = false
  if panel then panel:Hide() end
end)
ns.On("BAG_UPDATE_DELAYED", function() if isOpen then Merchant.UpdatePanel() end end)
