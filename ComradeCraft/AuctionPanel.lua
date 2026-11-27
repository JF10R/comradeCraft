-- AuctionPanel: compact Blizzard side panel docked to the Auction House frame.
-- Lists missing mats from your plans + Wishlist, shows estimated cost vs your gold balance,
-- flags overpriced live listings, and lets you search any item in the AH in 1 click (even
-- without TSM or Auctionator).
local _, ns = ...
local L = ns.L

local AH = {}
ns.AuctionPanel = AH

local PANEL_W, MAX_ROWS = 258, 10
local isOpen = false

-- Pure: missing non-vendor materials for the current character (plans + Wishlist), sorted
-- by urgency then estimated cost. Returns items, totalCost, allPriced.
function AH.Items()
  local out, total, complete = {}, 0, true
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return out, total, complete end
  local c = ComradeCraftDB.chars[ns.CharKey()]
  if not c then return out, total, complete end
  local byItem = {}
  for _, need in pairs(c.needs or {}) do
    for item, n in pairs(need.items or {}) do
      if n > 0 and not (ns.IsVendorItem and ns.IsVendorItem(item)) then
        local e = byItem[item]
        local step = need.when and need.when[item]
        if not e then
          e = { item = item, n = 0, step = step }
          byItem[item] = e
          out[#out + 1] = e
        end
        e.n = e.n + n
        if step and (not e.step or step < e.step) then e.step = step end
      end
    end
  end
  for _, e in ipairs(out) do
    local unit = ns.PriceSource and ns.PriceSource(e.item)
    if unit and unit > 0 then
      e.unit = unit
      e.cost = unit * e.n
      total = total + e.cost
    else
      complete = false
    end
  end
  table.sort(out, function(a, b)
    local ua, ub = ns.UrgencyRank(a.step), ns.UrgencyRank(b.step)
    if ua ~= ub then return ua < ub end
    return (a.cost or 0) > (b.cost or 0)
  end)
  return out, total, complete
end

-- Pure: unlearned BoE (non-BoP) BiS patterns from Audit.Run() + PatternsForCrafter() worth searching on the AH.
function AH.BoEPatterns()
  local out, seen = {}, {}
  local function AddPat(rid, forWho, crafter)
    if rid and rid > 0 and not seen[rid] and not (ns.IsBoP and ns.IsBoP(rid)) then
      seen[rid] = true
      local unit = ns.PriceSource and ns.PriceSource(rid)
      out[#out + 1] = {
        item = rid,
        n = 1,
        cost = unit and unit > 0 and unit or nil,
        forWho = forWho,
        crafter = crafter,
      }
    end
  end
  local groups = ns.Audit and ns.Audit.Run and ns.Audit.Run() or {}
  for _, grp in ipairs(groups) do
    for _, p in ipairs(grp.patterns or {}) do AddPat(p.recipeItem, grp.targetKey, p.crafter) end
  end
  local me = ns.CharKey and ns.CharKey()
  if me and ns.Audit and ns.Audit.PatternsForCrafter then
    for _, p in ipairs(ns.Audit.PatternsForCrafter(me)) do
      AddPat(p.recipeItem, p.forList and p.forList[1] and p.forList[1].key or me, me)
    end
  end
  table.sort(out, function(a, b) return (a.cost or 1e12) < (b.cost or 1e12) end)
  return out
end

-- Live AH Bargain Radar: tracks listings seen while browsing the AH (works with TSM/Auctionator
-- market prices, or falls back to a local rolling average in ComradeCraftDB.ahSeen).
local liveSeen = {} -- [itemID] = { price = lowestLiveCopper, ref = marketCopper, pct = discountPct }
local BARGAIN_MIN_PCT = 20

local function RecordSeenPrice(itemID, price)
  if not (ComradeCraftDB and itemID and itemID > 0 and price and price > 0) then return end
  ComradeCraftDB.ahSeen = ComradeCraftDB.ahSeen or {}
  local cur = ComradeCraftDB.ahSeen[itemID]
  if type(cur) ~= "table" then
    ComradeCraftDB.ahSeen[itemID] = { avg = price, n = 1 }
  else
    local n = math.min(20, (cur.n or 1) + 1)
    cur.avg = math.floor(((cur.avg or price) * (n - 1) + price) / n + 0.5)
    cur.n = n
  end
end

function AH.ReferencePrice(itemID)
  local p = ns.PriceSource and ns.PriceSource(itemID)
  if p and p > 0 then return p end
  local s = ComradeCraftDB and ComradeCraftDB.ahSeen and ComradeCraftDB.ahSeen[itemID]
  if type(s) == "table" and (s.n or 0) >= 2 and (s.avg or 0) > 0 then return s.avg end
end

function AH.ObserveListing(itemID, unitPrice)
  if not (itemID and itemID > 0 and unitPrice and unitPrice > 0) then return end
  local ref = AH.ReferencePrice(itemID)
  RecordSeenPrice(itemID, unitPrice)
  if ref and ref > 0 then
    local pct = math.floor((1 - unitPrice / ref) * 100 + 0.5)
    if pct >= BARGAIN_MIN_PCT then
      local prev = liveSeen[itemID]
      if not prev or unitPrice < prev.price then
        liveSeen[itemID] = { price = unitPrice, ref = ref, pct = pct }
      end
    end
  end
end

-- Pure: group-needed materials & unlearned BoE BiS patterns spotted at >= 20% below market.
function AH.Bargains()
  local want = {}
  if ns.GroupPlan then
    for _, row in ipairs(ns.GroupPlan()) do
      if (row.toGet or 0) > 0 and not (ns.IsVendorItem and ns.IsVendorItem(row.item)) then
        local who = row.by and row.by[1] and row.by[1].key or nil
        want[row.item] = { n = row.toGet, forWho = who }
      end
    end
  end
  for _, p in ipairs(AH.BoEPatterns()) do
    if not want[p.item] then want[p.item] = { n = 1, forWho = p.forWho } end
  end
  local out = {}
  for itemID, info in pairs(liveSeen) do
    local w = want[itemID]
    if w and info.pct >= BARGAIN_MIN_PCT then
      out[#out + 1] = { item = itemID, n = w.n, forWho = w.forWho,
        cost = info.price, ref = info.ref, pct = info.pct }
    end
  end
  table.sort(out, function(a, b) return a.pct > b.pct end)
  return out
end

local function ScanBrowseResults()
  if not isOpen then return end
  local changed = false
  if C_AuctionHouse and C_AuctionHouse.GetBrowseResults then
    local ok, list = pcall(C_AuctionHouse.GetBrowseResults)
    for _, r in ipairs(ok and type(list) == "table" and list or {}) do
      local id = r.itemKey and r.itemKey.itemID
      local price = r.minPrice
      if id and price and price > 0 then AH.ObserveListing(id, price) changed = true end
    end
  elseif GetNumAuctionItems and GetAuctionItemInfo then
    local n = GetNumAuctionItems("list") or 0
    for i = 1, math.min(n, 50) do
      local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = GetAuctionItemInfo("list", i)
      if itemID and buyout and buyout > 0 then
        AH.ObserveListing(itemID, math.floor(buyout / math.max(1, count or 1)))
        changed = true
      end
    end
  end
  if changed then AH.UpdatePanel() end
end

-- Searches `itemID` directly in the open Auction House (Blizzard Buy tab, Auctionator Shopping,
-- or legacy Classic AH).
function AH.SearchItem(itemID)
  if not (isOpen and itemID) then return false end
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name = get and get(itemID)
  if not name then
    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, itemID) end
    return false
  end
  -- 1. If Blizzard's modern Buy SearchBar is currently visible, search directly in it.
  local sb = type(AuctionHouseFrame) == "table" and rawget(AuctionHouseFrame, "SearchBar") or (AuctionHouseFrame and AuctionHouseFrame.SearchBar)
  if type(sb) == "table" and type(sb.SearchBox) == "table" and sb.IsShown and sb:IsShown() then
    sb.SearchBox:SetText(name)
    if sb.StartSearch then
      pcall(sb.StartSearch, sb)
    elseif C_AuctionHouse and C_AuctionHouse.SendBrowseQuery then
      pcall(C_AuctionHouse.SendBrowseQuery, { searchString = name, sorts = {}, filters = {} })
    end
    return true
  end
  -- 2. Otherwise, if Auctionator is loaded (e.g. on Auctionator's Shopping tab), run an exact search.
  if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.MultiSearchExact then
    local clean = name:gsub('[;^"]', "")
    local ok = pcall(Auctionator.API.v1.MultiSearchExact, "ComradeCraft", { clean })
    if ok then return true end
  end
  -- 3. Fallback: modern AH SendBrowseQuery (without minLevel/maxLevel=0) or Classic QueryAuctionItems.
  if C_AuctionHouse and C_AuctionHouse.SendBrowseQuery then
    if AuctionHouseFrame and AuctionHouseFrame.SetDisplayMode and AuctionHouseFrameDisplayMode
      and AuctionHouseFrameDisplayMode.Buy then
      pcall(AuctionHouseFrame.SetDisplayMode, AuctionHouseFrame, AuctionHouseFrameDisplayMode.Buy)
    end
    if type(sb) == "table" and type(sb.SearchBox) == "table" then sb.SearchBox:SetText(name) end
    pcall(C_AuctionHouse.SendBrowseQuery, { searchString = name, sorts = {}, filters = {} })
    return true
  elseif BrowseName and QueryAuctionItems then
    BrowseName:SetText(name)
    pcall(QueryAuctionItems, name)
    return true
  end
  return false
end

local panel, rows, dismissed = nil, nil, false
local activeTab = "mats" -- "mats" | "patterns"

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name = get and get(id)
  local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
    or (GetItemIcon and GetItemIcon(id)) or 134400
  return name, icon
end

local function CreateRow(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(PANEL_W - 20, 24)
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
      if self.forWho then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["For %s"]:format(self.forWho:match("^[^-]+") or self.forWho), 1, 0.82, 0)
      end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(L["Click: search in Auction House."], 0.5, 0.8, 1)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if not self.itemID then return end
    if IsShiftKeyDown and IsShiftKeyDown() then
      local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
      local name, link = get and get(self.itemID)
      if link and HandleModifiedItemClick and HandleModifiedItemClick(link) then return end
      if link and ChatEdit_InsertLink and ChatEdit_InsertLink(link) then return end
      if name then
        local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
        if focus and focus.Insert then focus:Insert(name) return end
      end
    end
    AH.SearchItem(self.itemID)
  end)
  return b
end

local function CreatePanel()
  local anchor = AuctionHouseFrame or AuctionFrame
  if panel or not anchor then return end
  panel = CreateFrame("Frame", "ComradeCraftAHPanel", anchor, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(PANEL_W, 120)
  panel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 4, -24)
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
  panel.title:SetText(L["To buy at the AH"])
  panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  panel.close:SetSize(22, 22)
  panel.close:SetPoint("TOPRIGHT", -2, -2)
  panel.close:SetScript("OnClick", function() dismissed = true panel:Hide() end)
  panel.matsBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.matsBtn:SetSize(74, 18)
  panel.matsBtn:SetPoint("TOPLEFT", 10, -30)
  panel.matsBtn:SetText(L["Materials"])
  panel.matsBtn:SetScript("OnClick", function() activeTab = "mats" AH.UpdatePanel() end)
  panel.patBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.patBtn:SetSize(82, 18)
  panel.patBtn:SetPoint("LEFT", panel.matsBtn, "RIGHT", 4, 0)
  panel.patBtn:SetText(L["BoE patterns"])
  panel.patBtn:SetScript("OnClick", function() activeTab = "patterns" AH.UpdatePanel() end)
  panel.dealBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.dealBtn:SetSize(74, 18)
  panel.dealBtn:SetPoint("LEFT", panel.patBtn, "RIGHT", 4, 0)
  panel.dealBtn:SetText(L["Bargains"])
  panel.dealBtn:SetScript("OnClick", function() activeTab = "bargains" AH.UpdatePanel() end)
  panel.sub = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  panel.sub:SetPoint("TOPLEFT", 10, -52)
  panel.sub:SetWidth(PANEL_W - 20)
  panel.sub:SetJustifyH("LEFT")
  panel.foot = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  panel.foot:SetWidth(PANEL_W - 20)
  panel.foot:SetJustifyH("LEFT")
  rows = {}
end

function AH.UpdatePanel()
  if not panel then return end
  if dismissed or not isOpen or (ns.PanelEnabled and not ns.PanelEnabled("ah")) then panel:Hide() return end
  local items, total = AH.Items()
  local patterns = AH.BoEPatterns()
  local bargains = AH.Bargains()
  if #items == 0 and #patterns == 0 and #bargains == 0 then panel:Hide() return end
  if activeTab == "bargains" and #bargains == 0 then activeTab = #items > 0 and "mats" or "patterns"
  elseif activeTab == "patterns" and #patterns == 0 then activeTab = #items > 0 and "mats" or "bargains"
  elseif activeTab == "mats" and #items == 0 then activeTab = #bargains > 0 and "bargains" or "patterns" end
  local showTabs = #patterns > 0 or #bargains > 0
  panel.matsBtn:SetShown(showTabs)
  panel.patBtn:SetShown(showTabs)
  panel.dealBtn:SetShown(showTabs and #bargains > 0)
  if showTabs then
    local nBtns = #bargains > 0 and 3 or 2
    local bw = nBtns == 3 and 76 or 116
    panel.matsBtn:SetWidth(bw)
    panel.patBtn:SetWidth(bw)
    panel.dealBtn:SetWidth(bw)
    panel.matsBtn:SetEnabled(activeTab ~= "mats")
    panel.patBtn:SetEnabled(activeTab ~= "patterns" and #patterns > 0)
    panel.dealBtn:SetEnabled(activeTab ~= "bargains" and #bargains > 0)
    panel.patBtn:SetText(("%s (%d)"):format(L["Patterns"], #patterns))
    panel.dealBtn:SetText(("|cff40ff40%s (%d)|r"):format(L["Deals"], #bargains))
  end
  local list = activeTab == "bargains" and bargains or (activeTab == "patterns" and patterns or items)
  local gold = (GetMoney and GetMoney()) or 0
  panel.sub:ClearAllPoints()
  panel.sub:SetPoint("TOPLEFT", 10, showTabs and -52 or -30)
  panel.sub:SetText(activeTab == "bargains" and L["Group needs spotted below market price."] or L["Click an item to search it."])
  for _, r in ipairs(rows) do r:Hide() end
  local y = showTabs and -68 or -46
  for i = 1, math.min(#list, MAX_ROWS) do
    local it = list[i]
    local r = rows[i]
    if not r then r = CreateRow(panel) rows[i] = r end
    local name, icon = ItemInfo(it.item)
    if not name and C_Item and C_Item.RequestLoadItemDataByID then
      pcall(C_Item.RequestLoadItemDataByID, it.item)
    end
    r.itemID, r.forWho = it.item, it.forWho
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(icon)
    local label = name or ("item:" .. it.item)
    if activeTab == "bargains" then
      r.name:SetText(label)
      r.cost:SetText(("|cff40ff40-%d%%|r %s"):format(it.pct or 0, ns.Money(math.floor(it.cost or 0))))
    else
      r.name:SetText(activeTab == "patterns" and label or ("%dx %s"):format(it.n, label))
      r.cost:SetText(it.cost and ("|cffffd100" .. ns.Money(math.floor(it.cost)) .. "|r") or "|cff9d9d9d?|r")
    end
    r:Show()
    y = y - 24
  end
  local col = total > 0 and (gold >= total and "40ff40" or "ff8040") or "9d9d9d"
  panel.foot:ClearAllPoints()
  panel.foot:SetPoint("TOPLEFT", 10, y - 6)
  panel.foot:SetText((activeTab == "mats" and total > 0)
    and L["Total: %s (you have %s)"]:format("|cff" .. col .. ns.Money(math.floor(total)) .. "|r", ns.Money(gold))
    or L["Gold: %s"]:format(ns.Money(gold)))
  panel:SetHeight(-y + 30)
  panel:Show()
end

ns.On("AUCTION_HOUSE_SHOW", function()
  isOpen, dismissed = true, false
  CreatePanel()
  AH.UpdatePanel()
end)
ns.On("AUCTION_HOUSE_CLOSED", function()
  isOpen = false
  liveSeen = {}
  if panel then panel:Hide() end
end)
ns.On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", ScanBrowseResults)
ns.On("AUCTION_ITEM_LIST_UPDATE", ScanBrowseResults)
ns.On("BAG_UPDATE_DELAYED", function() if isOpen then AH.UpdatePanel() end end)
local infoRefreshPending = false
ns.On("GET_ITEM_INFO_RECEIVED", function()
  if not isOpen or infoRefreshPending then return end
  infoRefreshPending = true
  if C_Timer and C_Timer.After then
    C_Timer.After(0.15, function()
      infoRefreshPending = false
      if isOpen then AH.UpdatePanel() end
    end)
  else
    infoRefreshPending = false
    AH.UpdatePanel()
  end
end)
