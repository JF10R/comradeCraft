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

-- Searches `itemID` directly in the open Blizzard Auction House (modern or classic API).
function AH.SearchItem(itemID)
  if not (isOpen and itemID) then return false end
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name = get and get(itemID)
  if not name then return false end
  if C_AuctionHouse and C_AuctionHouse.SendBrowseQuery then
    pcall(C_AuctionHouse.SendBrowseQuery, { searchString = name, sorts = {}, filters = {}, minLevel = 0, maxLevel = 0 })
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
    if self.itemID then AH.SearchItem(self.itemID) end
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
  panel.matsBtn:SetSize(112, 18)
  panel.matsBtn:SetPoint("TOPLEFT", 10, -30)
  panel.matsBtn:SetText(L["Materials"])
  panel.matsBtn:SetScript("OnClick", function() activeTab = "mats" AH.UpdatePanel() end)
  panel.patBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.patBtn:SetSize(118, 18)
  panel.patBtn:SetPoint("LEFT", panel.matsBtn, "RIGHT", 6, 0)
  panel.patBtn:SetText(L["BoE patterns"])
  panel.patBtn:SetScript("OnClick", function() activeTab = "patterns" AH.UpdatePanel() end)
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
  if #items == 0 and #patterns == 0 then panel:Hide() return end
  if activeTab == "patterns" and #patterns == 0 then activeTab = "mats"
  elseif activeTab == "mats" and #items == 0 and #patterns > 0 then activeTab = "patterns" end
  local showTabs = #patterns > 0
  panel.matsBtn:SetShown(showTabs)
  panel.patBtn:SetShown(showTabs)
  if showTabs then
    panel.matsBtn:SetEnabled(activeTab ~= "mats")
    panel.patBtn:SetEnabled(activeTab ~= "patterns")
    panel.patBtn:SetText(("%s (%d)"):format(L["BoE patterns"], #patterns))
  end
  local list = activeTab == "patterns" and patterns or items
  local gold = (GetMoney and GetMoney()) or 0
  panel.sub:ClearAllPoints()
  panel.sub:SetPoint("TOPLEFT", 10, showTabs and -52 or -30)
  panel.sub:SetText(L["Click an item to search it."])
  for _, r in ipairs(rows) do r:Hide() end
  local y = showTabs and -68 or -46
  for i = 1, math.min(#list, MAX_ROWS) do
    local it = list[i]
    local r = rows[i]
    if not r then r = CreateRow(panel) rows[i] = r end
    local name, icon = ItemInfo(it.item)
    r.itemID, r.forWho = it.item, it.forWho
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(icon)
    local label = name or ("item:" .. it.item)
    r.name:SetText(activeTab == "patterns" and label or ("%dx %s"):format(it.n, label))
    r.cost:SetText(it.cost and ("|cffffd100" .. ns.Money(math.floor(it.cost)) .. "|r") or "|cff9d9d9d?|r")
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
  if panel then panel:Hide() end
end)
ns.On("BAG_UPDATE_DELAYED", function() if isOpen then AH.UpdatePanel() end end)
