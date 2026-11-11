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

-- TSM groups, one per import: "ComradeCraft`<character>`<profession> <from>-<to>" (TSM
-- separates group levels with `), so names never collide and deleting "ComradeCraft" in TSM
-- removes them all. Pure: the text TSM's Groups > Import accepts ("group:<path>,i:1,i:2").
local GROUP_ROOT = "ComradeCraft"
function ns.TSMGroupPath(char, profession, from, to)
  return ("%s`%s`%s %d-%d"):format(GROUP_ROOT, char, profession, from, to)
end
function ns.TSMGroupString(path, items)
  local parts = { "group:" .. path:gsub(",", "``") }
  for _, e in ipairs(items) do parts[#parts + 1] = "i:" .. e.item end
  return table.concat(parts, ",")
end

-- Pure: which of our groups are superfluous. TSM's API is read-only (no delete, no edit),
-- so they are reported. `groups` = { [path] = { itemIDs } }; `needOf(char, prof, item)`.
-- Stale = no item still needed, or a newer import (higher start rank) of the same char+prof.
-- Returns { { path, reason = "done"|"replaced" } }, sorted by path.
function ns.TSMStaleGroups(groups, needOf)
  local latest, parsed = {}, {}
  for path in pairs(groups) do
    local char, prof, from = path:match("^" .. GROUP_ROOT .. "`([^`]+)`(.+) (%d+)%-%d+$")
    if char then
      parsed[path] = { char = char, prof = prof, from = tonumber(from) }
      local k = char .. "`" .. prof
      latest[k] = math.max(latest[k] or 0, tonumber(from))
    end
  end
  local out = {}
  for path, g in pairs(parsed) do
    local useful = false
    for _, id in ipairs(groups[path]) do
      if needOf(g.char, g.prof, id) then useful = true end
    end
    if not useful then
      out[#out + 1] = { path = path, reason = "done" }
    elseif g.from < latest[g.char .. "`" .. g.prof] then
      out[#out + 1] = { path = path, reason = "replaced" }
    end
  end
  table.sort(out, function(x, y) return x.path < y.path end)
  return out
end

-- Our groups as TSM has them now: { [path] = { itemIDs } }.
local function ReadTSMGroups()
  local groups = {}
  if not (TSM_API and TSM_API.GetGroupPaths and TSM_API.GetGroupItems) then return groups end
  local ok, paths = pcall(TSM_API.GetGroupPaths, {})
  for _, path in ipairs(ok and paths or {}) do
    if path:find("^" .. GROUP_ROOT .. "`") then
      local ok2, items = pcall(TSM_API.GetGroupItems, path, false, {})
      local ids = {}
      for _, str in ipairs(ok2 and items or {}) do
        local id = tonumber(str:match("^i:(%d+)"))
        if id then ids[#ids + 1] = id end
      end
      if #ids > 0 then groups[path] = ids end
    end
  end
  return groups
end

local function CharNeeds(char, prof, item)
  for key, c in pairs(ns.AllChars()) do
    if (key:match("^[^-]+") or key) == char then
      for _, need in pairs(c.needs or {}) do
        if need.name == prof and (need.items[item] or 0) > 0 then return true end
      end
    end
  end
  return false
end

function ns.StaleTSMGroupsText()
  local lines = {}
  for _, g in ipairs(ns.TSMStaleGroups(ReadTSMGroups(), CharNeeds)) do
    local name = g.path:gsub("`", " > ")
    lines[#lines + 1] = (g.reason == "done" and L["TSM group \"%s\": everything bought, delete it in TSM (Groups, right-click)."]
      or L["TSM group \"%s\": replaced by a newer one, delete it in TSM (Groups, right-click)."]):format(name)
  end
  return lines
end

-- Copy window: TSM search text and group import text, each selected on click.
local copy
local function CopyBox(parent, y, label)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fs:SetPoint("TOPLEFT", 16, y)
  fs:SetWidth(408)
  fs:SetJustifyH("LEFT")
  fs:SetText(label)
  local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  eb:SetSize(400, 20)
  eb:SetPoint("TOPLEFT", 22, y - 16)
  eb:SetAutoFocus(false)
  eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  eb:SetScript("OnEscapePressed", function() parent:Hide() end)
  eb:SetScript("OnTextChanged", function(self, user) if user then self:SetText(self.value or "") self:HighlightText() end end)
  return eb
end

local function ShowCopy(search, group, warnings)
  if not copy then
    copy = CreateFrame("Frame", "ComradeCraftCopyFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    copy:SetSize(440, 190)
    copy:SetPoint("CENTER", 0, 120)
    copy:SetFrameStrata("DIALOG")
    if copy.SetBackdrop then
      copy:SetBackdrop({ bgFile = "Interface\DialogFrame\UI-DialogBox-Background",
        edgeFile = "Interface\DialogFrame\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    end
    copy:EnableMouse(true)
    copy.title = copy:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    copy.title:SetPoint("TOP", 0, -16)
    copy.title:SetText(L["TSM shopping (Ctrl+C to copy)"])
    copy.close = CreateFrame("Button", nil, copy, "UIPanelCloseButton")
    copy.close:SetPoint("TOPRIGHT", -4, -4)
    copy.search = CopyBox(copy, -40, L["Search: paste in the search box of TSM's Shopping tab."])
    copy.group = CopyBox(copy, -84, L["Group: TSM, Groups, Import. Quantities are in the search above (recomputed on each click)."])
    copy.warn = copy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    copy.warn:SetPoint("TOPLEFT", 16, -130)
    copy.warn:SetWidth(408)
    copy.warn:SetJustifyH("LEFT")
    if UISpecialFrames then tinsert(UISpecialFrames, "ComradeCraftCopyFrame") end
  end
  copy.search.value, copy.group.value = search, group
  copy.search:SetText(search)
  copy.group:SetText(group)
  copy.warn:SetText(#warnings > 0 and ("|cffff9933" .. table.concat(warnings, "\n") .. "|r") or "")
  copy:Show()
  copy.search:SetFocus()
end

-- The Shopping list button: Auctionator list and/or TSM texts, whichever is loaded.
function ns.ShoppingAction(key, line)
  if ns.CanExportShopping() then ns.ExportShoppingVerbose(key, line) end
  if ns.CanTSMShopping() then
    local c = ns.AllChars()[key]
    local need = c and c.needs and c.needs[line]
    local items = ns.ShoppingItems(need)
    local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local text, skipped = ns.TSMSearchString(items, function(id) return (get(id)) end)
    ns.Log(("shopping: TSM search text, %d chars, %d skipped"):format(#text, skipped))
    if #items == 0 then
      ns.Print(L["Nothing to buy."])
    else
      local first = need.plan and need.plan[1]
      local path = ns.TSMGroupPath(key:match("^[^-]+") or key, need.name,
        first and first.from or need.reached, need.reached)
      ShowCopy(text, ns.TSMGroupString(path, items), ns.StaleTSMGroupsText())
    end
  end
end

-- At the auction house: one reminder per session about ComradeCraft groups TSM still keeps.
local reminded = false
ns.On("AUCTION_HOUSE_SHOW", function()
  if reminded or not ComradeCraftDB then return end
  reminded = true
  for _, l in ipairs(ns.StaleTSMGroupsText()) do ns.Print(l) end
end)

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
