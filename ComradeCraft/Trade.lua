-- Trade: when trading a group member, docks a compact Blizzard panel next to TradeFrame
-- listing what they need from your bags (profession & recipe) and highlights those items
-- in your bags (Blizzard, Baganator, Bagnon, ElvUI). One click places items; never accepts.
local _, ns = ...
local L = ns.L

local Trade = {}
ns.Trade = Trade

local PANEL_W, MAX_ROWS, MAX_SLOTS = 248, 6, 6
local isOpen, dismissed, partnerKey = false, false, nil
local tradeSnap, bothAccepted, castDuringTrade = nil, false, {}

local function NotifyBags()
  if ns.Bags and ns.Bags.Refresh then ns.Bags.Refresh() end
end

function Trade.IsOpen() return isOpen end
function Trade.CurrentRecipient() return isOpen and partnerKey or nil end

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link = get and get(id)
  if not name and ns.ItemName then name = ns.ItemName(id) end
  local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
    or (GetItemIcon and GetItemIcon(id)) or 134400
  return name, link, icon
end

local function FindInBags(item)
  if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
  local lastBag = (NUM_BAG_SLOTS or 4) + ((NUM_REAGENTBAG_SLOTS and NUM_REAGENTBAG_SLOTS > 0) and 1 or 0)
  for bag = 0, lastBag do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID == item and not info.isLocked then return bag, slot, info.stackCount or 1 end
    end
  end
end

-- Accepted/crafting incoming enchant requests (no output item) for the active trade partner.
function Trade.EnchantRequestsFor(toKey)
  local out = {}
  if not (toKey and ComradeCraftDB and ComradeCraftDB.requests and ns.Requests) then return out end
  local me = ns.CharKey()
  for _, r in pairs(ComradeCraftDB.requests) do
    local dest = ns.Requests.Recipient and ns.Requests.Recipient(r) or r.from
    if (r.status == "accepted" or r.status == "crafting")
      and ns.Requests.Role(r) == "crafter" and r.to == me
      and r.spell and r.spell > 0 and (not r.item or r.item == 0)
      and dest and (dest == toKey or (ns.IsSameChar and ns.IsSameChar(dest, toKey))) then
      out[#out + 1] = r
    end
  end
  return out
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
    local qty = it.inBags or 0
    if qty > 0 then
      local item = it.item
      if C_Timer and delay > 0 then
        C_Timer.After(delay, function() Trade.PlaceItem(item, qty) end)
      else
        if not Trade.PlaceItem(item, qty) then break end
      end
      delay = delay + 0.25
    end
  end
end

local panel, button, rows

local function ItemReason(it)
  local base
  if it.reserved then
    return "|cffc080ff" .. L["reserved"] .. "|r"
  elseif it.request then
    base = L["craft request"]
  else
    local parts = {}
    if it.prof then parts[#parts + 1] = it.prof end
    if it.spell and ns.SpellName then
      local sn = ns.SpellName(it.spell)
      if sn and not sn:find("^spell:") then parts[#parts + 1] = sn end
    end
    base = table.concat(parts, " - ")
  end
  if it.convertsTo then
    local tn = ns.ItemName and ns.ItemName(it.convertsTo) or ("item:" .. it.convertsTo)
    return base ~= "" and (base .. " -> " .. tn) or ("-> " .. tn)
  end
  return base
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
    elseif self.enchantSpell and GameTooltip.SetSpellByID then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetSpellByID(self.enchantSpell)
      GameTooltip:AddLine(L["Click to open this enchant for the trade slot."], 0.5, 0.8, 1, true)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if self.enchantSpell and ns.OpenRecipe then
      ns.OpenRecipe(self.enchantSpell)
    elseif self.itemID and (self.qtyNum or 0) > 0 then
      Trade.PlaceItem(self.itemID, self.qtyNum)
    end
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
  panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  panel.close:SetSize(22, 22)
  panel.close:SetPoint("TOPRIGHT", -2, -2)
  panel.close:SetScript("OnClick", function()
    dismissed = true
    panel:Hide()
  end)
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
  if dismissed or not (isOpen and partnerKey and ns.Mail) or (ns.PanelEnabled and not ns.PanelEnabled("trade")) then
    panel:Hide()
    return
  end
  local items = ns.Mail.ItemsFor(partnerKey)
  local enchants = Trade.EnchantRequestsFor(partnerKey)
  if #items == 0 and #enchants == 0 then
    panel:Hide()
    return
  end
  local chars = ns.AllChars()
  panel.sub:SetText(L["For %s"]:format(ns.ClassColored(partnerKey, chars[partnerKey] and chars[partnerKey].class)))
  for _, r in ipairs(rows) do
    r:Hide()
    r.itemID, r.qtyNum, r.enchantSpell = nil, nil, nil
  end
  local y, bagReady, rIdx = -48, 0, 0
  for _, er in ipairs(enchants) do
    if rIdx >= MAX_ROWS then break end
    rIdx = rIdx + 1
    local r = rows[rIdx]
    if not r then r = CreateRow(panel) rows[rIdx] = r end
    local ico = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(er.spell)) or 136244
    r.enchantSpell = er.spell
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(ico)
    r.icon:SetDesaturated(false)
    r.icon:SetAlpha(1)
    r.name:SetText("|cff66ccff" .. (ns.SpellName and ns.SpellName(er.spell) or ("spell:" .. er.spell)) .. "|r")
    r.qty:SetText("|cff40ff40" .. L["Enchant"] .. "|r")
    r.sub:SetText(L["Click to open recipe (trade slot 7)"])
    r:Show()
    y = y - 30
  end
  for i = 1, #items do
    if rIdx >= MAX_ROWS then break end
    rIdx = rIdx + 1
    local it = items[i]
    local r = rows[rIdx]
    if not r then r = CreateRow(panel) rows[rIdx] = r end
    local name, _, icon = ItemInfo(it.item)
    local inBags, inBank = it.inBags or 0, it.inBank or 0
    local bankOnly = inBags == 0
    if not bankOnly then bagReady = bagReady + 1 end
    r.itemID, r.qtyNum = it.item, inBags
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(icon)
    r.icon:SetDesaturated(bankOnly)
    r.icon:SetAlpha(bankOnly and 0.55 or 1)
    local dname = name or ("item:" .. it.item)
    r.name:SetText(bankOnly and ("|cff888888" .. dname .. "|r") or dname)
    r.qty:SetText(bankOnly and ("|cff888888x%d (%s)|r"):format(inBank, L["in bank"]) or ("|cffffd100x" .. inBags .. "|r"))
    r.sub:SetText(ItemReason(it))
    r:Show()
    y = y - 30
  end
  if #items > 0 then
    button:SetEnabled(bagReady > 0)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", 10, y - 4)
    button:Show()
    y = y - 30
  else
    button:Hide()
  end
  panel.foot:SetPoint("TOPLEFT", 10, y - 2)
  panel.foot:SetText(bagReady > 0 and ("|cff80ff80" .. L["Highlighted in your bags"] .. "|r")
    or (#enchants > 0 and ("|cff66ccff" .. L["Enchant auto-completes request on trade"] .. "|r")
    or ("|cff9d9d9d" .. L["In bank (retrieve first)"] .. "|r")))
  panel:SetHeight(-y + 22)
  panel:Show()
end

local function SnapshotTradeItems()
  local items = {}
  for i = 1, MAX_SLOTS do
    local link = GetTradePlayerItemLink and GetTradePlayerItemLink(i)
    local id = link and tonumber(link:match("item:(%d+)"))
    if id then
      local _, _, count = GetTradePlayerItemInfo and GetTradePlayerItemInfo(i)
      items[id] = (items[id] or 0) + (count or 1)
    end
  end
  tradeSnap = next(items) and items or nil
end

ns.On("TRADE_SHOW", function()
  isOpen, dismissed, tradeSnap, bothAccepted, castDuringTrade = true, false, nil, false, {}
  local name = ns.UnitFullName and ns.UnitFullName("NPC") or (UnitName and UnitName("NPC"))
  if name and (issecretvalue and issecretvalue(name)) then name = nil end
  partnerKey = name and ns.Mail and ns.Mail.KeyForName(name) or nil
  CreatePanel()
  Trade.UpdatePanel()
  NotifyBags()
end)
ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
  if isOpen and unit == "player" and spellID then castDuringTrade[spellID] = true end
end)
ns.On("TRADE_PLAYER_ITEM_CHANGED", function() if isOpen then SnapshotTradeItems() end end)
ns.On("TRADE_ACCEPT_UPDATE", function(playerAccepted, targetAccepted)
  if isOpen then
    SnapshotTradeItems()
    bothAccepted = (playerAccepted == 1 and targetAccepted == 1)
  end
end)
ns.On("TRADE_CLOSED", function()
  if bothAccepted and partnerKey and ns.Requests then
    if tradeSnap and ns.Requests.OnItemSent then
      for itemID, qty in pairs(tradeSnap) do ns.Requests.OnItemSent(partnerKey, itemID, qty) end
    end
    for _, er in ipairs(Trade.EnchantRequestsFor(partnerKey)) do
      if castDuringTrade[er.spell] then
        ns.Requests.Set(er.id, "done")
        if ns.PlaySound then ns.PlaySound("shipped") end
      end
    end
  end
  isOpen, partnerKey, tradeSnap, bothAccepted, castDuringTrade = false, nil, nil, false, {}
  if panel then panel:Hide() end
  NotifyBags()
end)
ns.On("BAG_UPDATE_DELAYED", function() if isOpen then Trade.UpdatePanel() end end)
