-- Shopping: the mats a plan still misses, as an Auctionator shopping list (one list per
-- profession, replaced on each export), a TSM search text to paste, or chat text.
-- Vendor reagents are left out.
local _, ns = ...
local L = ns.L

local CALLER = "ComradeCraft"

-- Pure: mats to buy for one profession need, biggest count first: { { item, n } }.
function ns.ShoppingItems(need)
  local out = {}
  for item, n in pairs(need and need.items or {}) do
    if n > 0 then out[#out + 1] = { item = item, n = n } end
  end
  table.sort(out, function(a, b)
    if a.n ~= b.n then return a.n > b.n end
    return a.item < b.item
  end)
  return out
end

local function Api()
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  return api and api.CreateShoppingList and api.ConvertToSearchString and api or nil
end
function ns.CanExportShopping() return Api() ~= nil end

-- Creates (or replaces) the Auctionator list "ComradeCraft: <profession>". Items whose name
-- the client has not cached yet are skipped. Returns exported, skipped (nil without Auctionator).
function ns.ExportShopping(key, line)
  local api = Api()
  local c = ns.AllChars()[key]
  local need = c and c.needs and c.needs[line]
  if not (api and need) then return nil end
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local strings, skipped = {}, 0
  for _, e in ipairs(ns.ShoppingItems(need)) do
    local name = get(e.item)
    if not name then
      skipped = skipped + 1
    else
      local ok, s = pcall(api.ConvertToSearchString, CALLER, { searchString = name, isExact = true, quantity = e.n })
      if ok and type(s) == "string" then
        strings[#strings + 1] = s
      else
        ns.Log(("shopping: ConvertToSearchString failed for %d: %s"):format(e.item, tostring(s)))
        return nil
      end
    end
  end
  if #strings == 0 then return 0, skipped end
  local listName = "ComradeCraft: " .. need.name
  local ok, err = pcall(api.CreateShoppingList, CALLER, listName, strings)
  ns.Log(("shopping: %s -> %s (%d items, %d skipped)%s"):format(listName, ok and "ok" or "error",
    #strings, skipped, ok and "" or (" " .. tostring(err))))
  if not ok then return nil end
  return #strings, skipped
end

-- Pure: TSM Shopping search text, e.g. "Linen Cloth/exact/x124;Wool Cloth/exact/x60" (TSM
-- splits searches on ";", "/xN" = max quantity). TSM has no API to create lists or groups.
-- Returns the text and how many items were skipped (name not cached, or with / or ;).
function ns.TSMSearchString(items, nameOf)
  local parts, skipped = {}, 0
  for _, e in ipairs(items) do
    local name = nameOf(e.item)
    if name and not name:find("[/;]") then
      parts[#parts + 1] = ("%s/exact/x%d"):format(name, e.n)
    else
      skipped = skipped + 1
    end
  end
  return table.concat(parts, ";"), skipped
end

function ns.CanTSMShopping() return TSM_API ~= nil end
function ns.CanShop() return ns.CanExportShopping() or ns.CanTSMShopping() end

-- Copy box: TSM's search text, selected, ready for Ctrl+C.
local function ShowCopy(text)
  if not (StaticPopupDialogs and StaticPopup_Show) then return ns.Print(text) end
  StaticPopupDialogs.COMRADECRAFT_COPY = StaticPopupDialogs.COMRADECRAFT_COPY or {
    text = L["TSM: Ctrl+C, then paste in the search box of TSM's Shopping tab."],
    button1 = OKAY or "OK", hasEditBox = true, editBoxWidth = 350, timeout = 0,
    whileDead = true, hideOnEscape = true,
    OnShow = function(self, data)
      local eb = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
      if not eb then return end
      eb:SetText(data or self.data or "")
      eb:HighlightText()
      eb:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
  }
  local dialog = StaticPopup_Show("COMRADECRAFT_COPY", nil, nil, text)
  if dialog then dialog.data = text end
end

-- The Shopping list button: Auctionator list and/or TSM search text, whichever is loaded.
function ns.ShoppingAction(key, line)
  if ns.CanExportShopping() then ns.ExportShoppingVerbose(key, line) end
  if ns.CanTSMShopping() then
    local c = ns.AllChars()[key]
    local need = c and c.needs and c.needs[line]
    local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local text, skipped = ns.TSMSearchString(ns.ShoppingItems(need), function(id) return (get(id)) end)
    ns.Log(("shopping: TSM search text, %d chars, %d skipped"):format(#text, skipped))
    if text == "" then
      ns.Print(skipped > 0 and L["%d not cached yet; try again in a moment."]:format(skipped) or L["Nothing to buy."])
    else
      ShowCopy(text)
    end
  end
end

-- Exports and tells the player what happened.
function ns.ExportShoppingVerbose(key, line)
  local need = ns.AllChars()[key] and ns.AllChars()[key].needs and ns.AllChars()[key].needs[line]
  local n, skipped = ns.ExportShopping(key, line)
  if not n then
    ns.Print(L["Could not create the Auctionator list (see /comrade log)."])
  elseif n == 0 and skipped > 0 then
    ns.Print(L["%d not cached yet; try again in a moment."]:format(skipped))
  elseif n == 0 then
    ns.Print(L["Nothing to buy for %s."]:format(need and need.name or "?"))
  else
    ns.Print(L["Auctionator list \"ComradeCraft: %s\" created: %d items. Open the Shopping tab at the auction house."]
      :format(need.name, n) .. (skipped > 0 and (" " .. L["%d not cached yet; try again in a moment."]:format(skipped)) or ""))
  end
end

-- /comrade shop [profession]: lists what to buy (and exports it when Auctionator is loaded).
ns.commands.shop = function(rest)
  local key = ns.CharKey()
  local c = ns.CharData()
  ns.UpdateNeeds(c)
  local filter = (rest or ""):lower()
  local any = false
  for line, need in pairs(c.needs or {}) do
    if filter == "" or need.name:lower():find(filter, 1, true) then
      local items = ns.ShoppingItems(need)
      if #items > 0 then
        any = true
        local parts, total, complete = {}, 0, true
        for _, e in ipairs(items) do
          parts[#parts + 1] = ("%s x%d"):format(ns.ItemName(e.item), e.n)
          local v = ns.BuyCost(e.item, e.n)
          if v then total = total + v else complete = false end
        end
        local cost = ns.PriceSource and (" (" .. ns.CostText(total, complete) .. ")") or ""
        ns.Print(("%s%s: %s"):format(need.name, cost, table.concat(parts, ", ")))
        if ns.CanShop() then ns.ShoppingAction(key, line) end
      end
    end
  end
  if not any then ns.Print(L["Nothing to buy."]) end
end
