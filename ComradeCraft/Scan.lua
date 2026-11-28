-- Scan: profession skills, bags, bank. Defensive: API presence on 16001 is unverified.
local _, ns = ...
local Print = ns.Print

local function ScanProfessions()
  local out = {}
  if GetProfessions and GetProfessionInfo then
    for _, idx in pairs({ GetProfessions() }) do
      if idx then
        local name, icon, rank, maxRank, _, _, skillLine = GetProfessionInfo(idx)
        if name then out[name] = { rank = rank, max = maxRank, skillLine = skillLine, icon = icon } end
      end
    end
  elseif GetNumSkillLines and GetSkillLineInfo then
    -- Classic-style fallback: every skill line; filtering is left to the caller.
    for i = 1, GetNumSkillLines() do
      local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
      if not isHeader and name then out[name] = { rank = rank, max = maxRank } end
    end
  end
  return out
end

local function GetSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then
    return C_Container.GetContainerNumSlots(bag)
  end
  return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

local function GetItem(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info then return info.itemID, info.stackCount, info.isBound end
    return nil
  end
  if GetContainerItemInfo then
    local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
    if link then return tonumber(link:match("item:(%d+)")), count end
  end
end

-- Sums itemID -> count over a list of bag indexes; also returns { [itemID] = true }
-- for items whose every stack in those bags is already soulbound.
local function ScanBags(bags)
  local out, boundAny, unbound = {}, {}, {}
  for _, bag in ipairs(bags) do
    for slot = 1, GetSlots(bag) or 0 do
      local id, count, isBound = GetItem(bag, slot)
      if id then
        out[id] = (out[id] or 0) + (count or 1)
        if isBound then boundAny[id] = true else unbound[id] = true end
      end
    end
  end
  local bound = {}
  for id in pairs(boundAny) do
    if not unbound[id] then bound[id] = true end
  end
  return out, bound
end

local function BagIndexes()
  local list = {}
  for b = 0, (NUM_BAG_SLOTS or 4) do list[#list + 1] = b end
  if NUM_REAGENTBAG_SLOTS and NUM_REAGENTBAG_SLOTS > 0 then
    list[#list + 1] = (NUM_BAG_SLOTS or 4) + 1
  end
  return list
end

local function BankIndexes()
  local list = { BANK_CONTAINER or -1 }
  local first = (NUM_BAG_SLOTS or 4) + (NUM_REAGENTBAG_SLOTS or 0) + 1
  for b = first, first + (NUM_BANKBAGSLOTS or 6) - 1 do list[#list + 1] = b end
  return list
end

-- Specialization: modern API, else Classic talent tabs, else signature talent spells (Forever).
function ns.ScanSpec()
  if GetSpecialization and GetSpecializationInfo then
    local i = GetSpecialization()
    if i then
      local _, name, _, icon = GetSpecializationInfo(i)
      if name then return name, icon, i end
    end
  end
  if GetNumTalentTabs and GetTalentTabInfo then
    local bestName, bestIcon, bestPoints, bestIdx = nil, nil, 0, nil
    for t = 1, GetNumTalentTabs() or 0 do
      local r = { GetTalentTabInfo(t) }
      local name, icon, points
      if type(r[1]) == "string" then
        name, icon, points = r[1], r[2], r[3]       -- name, icon, pointsSpent, ...
      else
        name, icon, points = r[2], r[4], r[5]       -- id, name, description, icon, pointsSpent, ...
      end
      if type(points) == "number" and points > bestPoints then
        bestName, bestIcon, bestPoints, bestIdx = name, icon, points, t
      end
    end
    if bestName then return bestName, bestIcon, bestIdx end
  end
  if ns.GearScore and ns.GearScore.DetectSpecFromSpells and UnitClass then
    local _, class = UnitClass("player")
    local key = ns.GearScore.DetectSpecFromSpells(class)
    if key then return ns.GearScore.SpecLabel(key), nil, nil end
  end
end

-- Equipped items { [slot 1-19] = itemID } and links { [slot] = itemLink } (for random suffixes).
function ns.ScanEquipped()
  local out, links = {}, {}
  if not GetInventoryItemID then return out, links end
  for slot = 1, 19 do
    local id = GetInventoryItemID("player", slot)
    if id then
      out[slot] = id
      local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
      if link then links[slot] = link end
    end
  end
  return out, links
end

-- Current bag contents { [itemID] = count } (bank excluded).
function ns.ScanBagContents()
  local out = ScanBags(BagIndexes())
  return out
end

-- Equipped enchant IDs { [slot] = enchantID (0 = unenchanted) } for enchantable slots (incl. Neck on Forever).
local ENCHANT_SLOTS = { 2, 5, 8, 9, 10, 15, 16, 17 }
function ns.ScanEnchants()
  local out = {}
  if not GetInventoryItemLink then return out end
  for _, slot in ipairs(ENCHANT_SLOTS) do
    local link = GetInventoryItemLink("player", slot)
    if link then
      local ench = tonumber(link:match("item:%d+:(%d+)")) or 0
      out[slot] = ench
    end
  end
  return out
end

-- Equipped bag slot sizes { s1, s2, s3, s4 } (0 = empty bag slot).
function ns.ScanBagSizes()
  local out = {}
  for b = 1, (NUM_BAG_SLOTS or 4) do
    local family = C_Container and C_Container.GetContainerNumFreeSlots
      and select(2, C_Container.GetContainerNumFreeSlots(b))
    if (family or 0) == 0 then out[b] = GetSlots(b) or 0 end -- skip quivers, soul/profession bags
  end
  return out
end

function ns.ScanAll()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local c = ns.CharData()
  c.spec, c.specIcon, c.specIdx = ns.ScanSpec()
  c.equipped, c.equippedLinks = ns.ScanEquipped()
  c.enchants = ns.ScanEnchants()
  c.bagSizes = ns.ScanBagSizes()
  c.professions = ScanProfessions()
  c.bags, c.bound = ScanBags(BagIndexes())
  c.updated = time()
  ns.RequestRefresh()
end

-- Restores dynamically discovered Forever custom recipes into ns.Recipes on load.
local function LoadCustomRecipes()
  if not (ComradeCraftDB and ComradeCraftDB.customRecipes and ns.Recipes) then return end
  for id, r in pairs(ComradeCraftDB.customRecipes) do
    if not ns.Recipes[id] and type(r) == "table" and r[1] and r[7] then ns.Recipes[id] = r end
  end
end
ns.LoadCustomRecipes = LoadCustomRecipes

local function OpenProfessionLineAndRank()
  local T = C_TradeSkillUI
  if not T then return nil, nil end
  for _, fn in ipairs({ "GetChildProfessionInfo", "GetBaseProfessionInfo" }) do
    if T[fn] then
      local ok, info = pcall(T[fn])
      if ok and info and (info.professionID or info.parentProfessionID) then
        local line = info.parentProfessionID or info.professionID
        if info.skillLevel and info.skillLevel > 0 then return line, info.skillLevel end
      end
    end
  end
end

-- Discovers a custom/new Forever recipe via C_TradeSkillUI.GetRecipeSchematic and saves it.
local function DiscoverRecipe(id, info, line, rank)
  local T = C_TradeSkillUI
  if not (T and T.GetRecipeSchematic and line) then return nil end
  local ok, sch = pcall(T.GetRecipeSchematic, id, false)
  if not (ok and type(sch) == "table") then return nil end
  local reag = {}
  for _, slot in ipairs(sch.reagentSlotSchematics or {}) do
    local first = slot.reagents and slot.reagents[1]
    if slot.required ~= false and first and first.itemID and (slot.quantityRequired or 0) > 0 then
      reag[#reag + 1] = first.itemID
      reag[#reag + 1] = slot.quantityRequired
    end
  end
  if #reag == 0 then return nil end
  rank = rank or 1
  local diff = info and info.relativeDifficulty
  local yellow, grey
  if diff == 0 then yellow, grey = rank + 15, rank + 35
  elseif diff == 1 then yellow, grey = math.max(1, rank - 5), rank + 20
  elseif diff == 2 then yellow, grey = math.max(1, rank - 15), rank + 10
  elseif diff == 3 then yellow, grey = 1, rank
  else yellow, grey = rank + 10, rank + 25 end
  local row = { line, yellow, grey, 1, sch.outputItemID or 0, math.max(1, sch.quantityMin or 1), reag }
  ComradeCraftDB.customRecipes = ComradeCraftDB.customRecipes or {}
  ComradeCraftDB.customRecipes[id] = row
  ns.Recipes[id] = row
  return row
end

-- Applies saved live-observed Forever recipe difficulty bounds ({ y, g } or legacy { [1], [2] }) on startup/sync.
-- Client build number now, and the build Data/Recipes.lua was generated from.
function ns.ClientBuild()
  return GetBuildInfo and tonumber((select(2, GetBuildInfo()))) or nil
end
function ns.DataBuild()
  return tonumber(tostring(ns.RecipesBuild or ""):match("(%d+)$"))
end

-- A bound seen in game counts only if seen on a build at least as new as our data: a hotfix
-- (Coarse Grinding Stone grey 75 -> 90) must not be undone by an older observation.
function ns.BoundIsCurrent(b)
  local data = ns.DataBuild()
  return not data or (type(b) == "table" and tonumber(b.b) and tonumber(b.b) >= data) or false
end

local function LoadRecipeBounds()
  if not (ComradeCraftDB and ComradeCraftDB.recipeBounds) then return end
  for id, b in pairs(ComradeCraftDB.recipeBounds) do
    local r = ns.Recipes and ns.Recipes[id]
    if r and type(b) == "table" and ns.BoundIsCurrent(b) then
      local y = b.y or b[1]
      local g = b.g or b[2]
      if y and y > 0 then r[2] = y end
      if g and g > 0 then r[3] = g end
    end
  end
end
ns.ApplyRecipeBounds = LoadRecipeBounds

-- Refines yellow/grey bounds for ANY recipe observed live in WoW Forever's profession window.
local function ObserveRecipeBound(id, r, diff, rank)
  if not (r and diff and rank and rank > 0) then return end
  local y, g = r[2], r[3]
  local ny, ng = y, g
  if diff == 0 and rank >= y then
    ny = rank + 1
    ng = math.max(g, ny + 15)
  elseif diff == 1 and rank < y then
    ny = rank
  elseif diff == 2 and rank < y then
    ny = math.max(1, rank - 10)
  elseif diff == 3 and rank < g then
    ng = rank
    ny = math.min(y, rank)
  end
  if ny ~= y or ng ~= g then
    r[2], r[3] = ny, ng
    ComradeCraftDB.recipeBounds = ComradeCraftDB.recipeBounds or {}
    ComradeCraftDB.recipeBounds[id] = { y = ny, g = ng, b = ns.ClientBuild() }
  end
end

-- Known recipes of the open profession window, keyed by skill line (static + Forever custom).
local function ScanKnownRecipes()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  LoadCustomRecipes()
  LoadRecipeBounds()
  local T = C_TradeSkillUI
  if not (T and T.GetAllRecipeIDs and T.GetRecipeInfo) then return end
  if T.IsTradeSkillLinked and T.IsTradeSkillLinked() then return end
  if T.IsTradeSkillGuild and T.IsTradeSkillGuild() then return end
  local c = ns.CharData()
  c.known = c.known or {}
  local openLine, openRank = OpenProfessionLineAndRank()
  local found = {}
  for _, id in ipairs(T.GetAllRecipeIDs() or {}) do
    local info = T.GetRecipeInfo(id)
    if info and info.learned then
      local r = ns.Recipes[id] or DiscoverRecipe(id, info, openLine, openRank)
      if r then
        -- Active Forever calibration: update yellow/grey thresholds from live client difficulty.
        if openRank then ObserveRecipeBound(id, r, info.relativeDifficulty, openRank) end
        found[r[1]] = found[r[1]] or {}
        found[r[1]][id] = true
      end
    end
  end
  local best, most = nil, 0
  for line, set in pairs(found) do
    c.known[line] = set
    local n = 0
    for _ in pairs(set) do n = n + 1 end
    if n > most then best, most = line, n end
  end
  ns.openLine = best -- the open profession, for the step panel (Tracker.lua)
  c.professions = ScanProfessions()
  ns.RequestRefresh()
end

local function ScanBank()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local c = ns.CharData()
  c.bank = ScanBags(BankIndexes())
  c.updated = time()
  ns.RequestRefresh()
end

-- Inbox items waiting to be looted: counted as owned so the group doesn't double-farm/buy them.
local function ScanInbox()
  if not (ComradeCraftDB and ComradeCraftDB.chars and GetInboxNumItems) then return end
  local out = {}
  local n = GetInboxNumItems() or 0
  for i = 1, n do
    local cod = GetInboxHeaderInfo and select(6, GetInboxHeaderInfo(i))
    for a = 1, (type(cod) == "number" and cod > 0) and 0 or (ATTACHMENTS_MAX_RECEIVE or 16) do -- unpaid C.O.D.
      local id, count
      if GetInboxItem then
        local _, itemID, _, qty = GetInboxItem(i, a)
        if type(itemID) == "number" then id, count = itemID, qty end
      end
      if not id and GetInboxItemLink then
        local link = GetInboxItemLink(i, a)
        id = link and tonumber(link:match("item:(%d+)"))
        if id and GetInboxItem then local _, _, _, qty = GetInboxItem(i, a) count = qty end
      end
      if id then out[id] = (out[id] or 0) + (count or 1) end
    end
  end
  local c = ns.CharData()
  c.mail = next(out) and out or nil
  c.updated = time()
  ns.RequestRefresh()
end

-- Captures live lowest unit buyout prices while browsing the AH (modern & classic APIs).
-- `prev` keeps the price from before this scan (deal benchmark); `exact` buyouts (item or
-- commodity search) beat a browse minPrice, which may be a bid.
local function RecordAHPrice(item, unitPrice, exact)
  if not (ComradeCraftDB and item and unitPrice and unitPrice > 0) then return end
  ComradeCraftDB.ahPrices = ComradeCraftDB.ahPrices or {}
  local cur = ComradeCraftDB.ahPrices[item]
  local now = time()
  local fresh = cur and (now - (cur.t or 0)) <= 60
  if fresh and cur.exact and not exact then return end
  if not fresh or unitPrice < (cur.price or 0) or (exact and not cur.exact) then
    local prev, prevT = cur and cur.prev, cur and cur.prevT
    if cur and not fresh then prev, prevT = cur.price, cur.t end
    ComradeCraftDB.ahPrices[item] = { price = math.floor(unitPrice), t = now,
      prev = prev, prevT = prevT, exact = exact or nil }
  end
end

local function ScanAHBrowse()
  if not (C_AuctionHouse and C_AuctionHouse.GetBrowseResults) then return end
  local ok, res = pcall(C_AuctionHouse.GetBrowseResults)
  if not (ok and type(res) == "table") then return end
  for _, e in ipairs(res) do
    local id = e.itemKey and e.itemKey.itemID
    if id and e.minPrice and e.minPrice > 0 then RecordAHPrice(id, e.minPrice) end
  end
  ns.DetectPriceSource()
end

-- Commodity search: results come sorted by unit price, the first is the lowest buyout.
local function ScanAHCommodity(itemID)
  local f = C_AuctionHouse and C_AuctionHouse.GetCommoditySearchResultInfo
  if not (f and itemID) then return end
  local ok, r = pcall(f, itemID, 1)
  if ok and type(r) == "table" and type(r.unitPrice) == "number" then
    RecordAHPrice(itemID, r.unitPrice, true)
    ns.DetectPriceSource()
  end
end

-- Item search: lowest single-item buyout (bid-only auctions have no buyoutAmount).
local function ScanAHItemSearch(itemKey)
  local C = C_AuctionHouse
  if not (C and C.GetNumItemSearchResults and C.GetItemSearchResultInfo
    and type(itemKey) == "table" and itemKey.itemID) then return end
  local okN, n = pcall(C.GetNumItemSearchResults, itemKey)
  local best
  for i = 1, (okN and type(n) == "number") and math.min(n, 200) or 0 do
    local ok, r = pcall(C.GetItemSearchResultInfo, itemKey, i)
    local b = ok and type(r) == "table" and r.buyoutAmount
    if type(b) == "number" and b > 0 and (r.quantity or 1) <= 1 and (not best or b < best) then best = b end
  end
  if best then
    RecordAHPrice(itemKey.itemID, best, true)
    ns.DetectPriceSource()
  end
end

local function ScanAHClassic()
  if not (GetNumAuctionItems and GetAuctionItemInfo) then return end
  local n = GetNumAuctionItems("list") or 0
  for i = 1, math.min(n, 200) do
    local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = GetAuctionItemInfo("list", i)
    if itemID and buyout and buyout > 0 and count and count > 0 then
      RecordAHPrice(itemID, buyout / count)
    end
  end
  ns.DetectPriceSource()
end
ns.On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", ScanAHBrowse)
ns.On("COMMODITY_SEARCH_RESULTS_UPDATED", ScanAHCommodity)
ns.On("ITEM_SEARCH_RESULTS_UPDATED", ScanAHItemSearch)

local function FlatEqual(a, b)
  if a == b then return true end
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  for k, v in pairs(a) do if b[k] ~= v then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function ProfsEqual(a, b)
  if a == b then return true end
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  for k, p in pairs(a) do
    local q = b[k]
    if not q or p.rank ~= q.rank or p.max ~= q.max or p.skillLine ~= q.skillLine then return false end
  end
  for k in pairs(b) do if not a[k] then return false end end
  return true
end

-- Withdrawals/deposits while the bank is open keep c.bank current (no double count with bags).
local bankOpen = false
local function RescanBank()
  if not (bankOpen and ComradeCraftDB and ComradeCraftDB.chars) then return end
  local bank = ScanBags(BankIndexes())
  local c = ns.CharData()
  if FlatEqual(c.bank, bank) then return end
  c.bank, c.updated = bank, time()
  ns.RequestRefresh()
end

-- Targeted lightweight scans so frequent events (bag changes, looting, combat) never re-scan
-- unrelated state or trigger redundant UpdateNeeds() passes when nothing actually changed.
local function ScanBagsOnly()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local c = ns.CharData()
  local bags, bound = ScanBags(BagIndexes())
  if FlatEqual(c.bags, bags) and FlatEqual(c.bound, bound) then return end
  c.bags, c.bound = bags, bound
  c.updated = time()
  ns.RequestRefresh()
end

local function ScanGearOnly()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local c = ns.CharData()
  c.equipped, c.equippedLinks = ns.ScanEquipped()
  c.enchants = ns.ScanEnchants()
  c.bagSizes = ns.ScanBagSizes()
  c.updated = time()
  ns.RequestRefresh()
end

local function ScanSpecOnly()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local c = ns.CharData()
  local sp, icon, idx = ns.ScanSpec()
  if c.spec == sp and c.specIdx == idx then return end
  c.spec, c.specIcon, c.specIdx = sp, icon, idx
  c.updated = time()
  ns.RequestRefresh()
end

local function ScanProfessionsOnly()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local c = ns.CharData()
  local profs = ScanProfessions()
  if ProfsEqual(c.professions, profs) then return end
  c.professions = profs
  c.updated = time()
  ns.RequestRefresh()
end

ns.On("PLAYER_LOGIN", function()
  LoadCustomRecipes()
  LoadRecipeBounds()
end)
-- Standing with each faction a recipe needs (ns.ItemReputation): c.reps[factionID] = 1-8.
function ns.ScanReputations()
  if not (ComradeCraftDB and ComradeCraftDB.chars and GetFactionInfoByID and ns.ItemReputation) then return end
  local c = ns.CharData()
  local done = {}
  for _, rep in pairs(ns.ItemReputation) do
    local fid = rep[1]
    if not done[fid] then
      done[fid] = true
      local ok, _, _, standing = pcall(GetFactionInfoByID, fid)
      if ok and type(standing) == "number" and standing > 0 then
        c.reps = c.reps or {}
        c.reps[fid] = standing
      end
    end
  end
end
ns.On("PLAYER_ENTERING_WORLD", function() LoadCustomRecipes() ns.ScanAll() ns.ScanReputations() end)
ns.On("UPDATE_FACTION", function() ns.ScanReputations() end)
ns.On("SKILL_LINES_CHANGED", ScanProfessionsOnly)
ns.On("BAG_UPDATE_DELAYED", ScanBagsOnly)
ns.On("CHAT_MSG_SKILL", ScanProfessionsOnly) -- "Your skill in X has increased to N"
for _, e in ipairs({ "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED",
  "PLAYER_SPECIALIZATION_CHANGED" }) do
  ns.On(e, ScanSpecOnly) -- talents change the specialization
end
ns.On("PLAYER_EQUIPMENT_CHANGED", ScanGearOnly)
ns.On("BANKFRAME_OPENED", function() bankOpen = true ScanBank() end)
ns.On("PLAYERBANKSLOTS_CHANGED", RescanBank)
ns.On("BAG_UPDATE_DELAYED", RescanBank)
ns.On("BANKFRAME_CLOSED", function()
  if (GetSlots(BANK_CONTAINER or -1) or 0) > 0 then RescanBank() end -- only while still readable
  bankOpen = false
end)
ns.On("MAIL_INBOX_UPDATE", ScanInbox)
ns.On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", ScanAHBrowse)
ns.On("AUCTION_ITEM_LIST_UPDATE", ScanAHClassic)
ns.On("TRADE_SKILL_LIST_UPDATE", ScanKnownRecipes)
ns.On("NEW_RECIPE_LEARNED", function(spell)
  if not (ComradeCraftDB and ComradeCraftDB.chars and spell and ns.Recipes[spell]) then return end
  local c = ns.CharData()
  local line = ns.Recipes[spell][1]
  c.known = c.known or {}
  c.known[line] = c.known[line] or {}
  c.known[line][spell] = true
  if ComradeCraftDB.skippedLearn then ComradeCraftDB.skippedLearn[spell] = nil end
  ns.RequestRefresh()
end)

-- Remembers items merchants sell in unlimited supply: those are bought, not shared.
ns.On("MERCHANT_SHOW", function()
  if not (ComradeCraftDB and GetMerchantNumItems and GetMerchantItemID) then return end
  ComradeCraftDB.vendorSeen = ComradeCraftDB.vendorSeen or {}
  for i = 1, GetMerchantNumItems() do
    local id = GetMerchantItemID(i)
    local available
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
      local info = C_MerchantFrame.GetItemInfo(i)
      available = info and info.numAvailable
    elseif GetMerchantItemInfo then
      available = select(5, GetMerchantItemInfo(i))
    end
    if id and available == -1 then ComradeCraftDB.vendorSeen[id] = true end
  end
end)

-- Trainer window: records cost and required skill of each recipe it teaches, so the plan
-- can say "learn X at the trainer (cost)" with Forever's real values. Services are matched
-- to recipe spells by name (game language), within the trainer's profession.
local nameIndex -- [localized spell name] = { spellID, ... }
local function SpellIDsByName(name)
  if not nameIndex then
    nameIndex = {}
    for spell in pairs(ns.Recipes) do
      local n = ns.SpellName and ns.SpellName(spell)
      if n and not n:find("^spell:") then
        nameIndex[n] = nameIndex[n] or {}
        table.insert(nameIndex[n], spell)
      end
    end
  end
  return nameIndex[name]
end

-- Name twins (a Classic id and a later SoD/Forever one, e.g. Black Mageweave Vest 12048 / 439086):
-- candidates for trainer service i, the one crafting the item it shows first, then lowest id.
function ns.TrainerServiceSpells(i, list)
  if not list or #list < 2 then return list or {} end
  local link = GetTrainerServiceItemLink and GetTrainerServiceItemLink(i)
  local item = type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
  local out = { unpack(list) }
  table.sort(out, function(a, b)
    local ma, mb = item ~= nil and ns.Recipes[a][5] == item, item ~= nil and ns.Recipes[b][5] == item
    if ma ~= mb then return ma end
    return a < b
  end)
  return out
end

local scanningTrainer = false
local function ScanTrainer()
  if scanningTrainer or not (ComradeCraftDB and GetNumTrainerServices and GetTrainerServiceInfo) then return end
  scanningTrainer = true
  -- Show every service (available, unavailable, already known), then restore the filters.
  -- Forever takes a boolean on/off (Classic took 1/0).
  local function SetFilter(k, on)
    if not pcall(SetTrainerServiceTypeFilter, k, on) then pcall(SetTrainerServiceTypeFilter, k, on and 1 or 0) end
  end
  local saved = {}
  if GetTrainerServiceTypeFilter and SetTrainerServiceTypeFilter then
    for _, k in ipairs({ "available", "unavailable", "used" }) do
      saved[k] = GetTrainerServiceTypeFilter(k)
      if not saved[k] then SetFilter(k, true) end
    end
  end
  local lines = {}
  for name, p in pairs(ns.CharData().professions or {}) do lines[name] = p.skillLine end
  ComradeCraftDB.trainer = ComradeCraftDB.trainer or {}
  local found, lineCount, offered, maxReqByLine = 0, {}, {}, {}
  for i = 1, GetNumTrainerServices() do
    local name, _, kind = GetTrainerServiceInfo(i)
    if name and kind ~= "header" then
      local skillName, req = nil, nil
      if GetTrainerServiceSkillReq then skillName, req = GetTrainerServiceSkillReq(i) end
      local cost = GetTrainerServiceCost and GetTrainerServiceCost(i) or nil
      local line = skillName and lines[skillName]
      local took = {} -- one spell per service and skill line: its best twin
      for _, spell in ipairs(ns.TrainerServiceSpells(i, SpellIDsByName(name))) do
        local sl = ns.Recipes[spell][1]
        if (not line or sl == line) and not took[sl] then
          took[sl] = true
          ComradeCraftDB.trainer[spell] = { cost = cost, req = req, t = time() }
          offered[spell] = true
          if req and req > (maxReqByLine[sl] or 0) then maxReqByLine[sl] = req end
          found = found + 1
          lineCount[sl] = (lineCount[sl] or 0) + 1
        end
      end
    end
  end
  for k, v in pairs(saved) do
    if not v then SetFilter(k, false) end
  end
  scanningTrainer = false
  -- Where this trainer stands and which recipes they actually teach (unlike LibProfessionDB's
  -- flat lists): used for "Learn" waypoints so Apprentice trainers aren't picked for high-rank recipes.
  local guid = UnitGUID and UnitGUID("npc")
  if guid and issecretvalue and issecretvalue(guid) then guid = nil end
  local id = type(guid) == "string" and select(6, strsplit("-", guid))
  local npc = tonumber(id)
  local best, most = nil, 0
  for l, n in pairs(lineCount) do if n > most then best, most = l, n end end
  local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
  if npc then
    if ComradeCraftDB.trainerRefused then ComradeCraftDB.trainerRefused[npc] = nil end
    ComradeCraftDB.trainerSpots = ComradeCraftDB.trainerSpots or {}
    local spot = ComradeCraftDB.trainerSpots[npc] or {}
    local npcName = UnitName and UnitName("npc")
    if npcName and issecretvalue and issecretvalue(npcName) then npcName = nil end
    spot.name = npcName or spot.name
    spot.line = best or spot.line
    spot.scanned = true
    spot.spells = offered
    spot.maxReq = best and maxReqByLine[best] or 0
    spot.t = time()
    if pos then
      local x, y
      if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
      if x and y then spot.map, spot.x, spot.y = map, math.floor(x * 10000) / 100, math.floor(y * 10000) / 100 end
    end
    ComradeCraftDB.trainerSpots[npc] = spot
  end
  ns.Log(("trainer: %d recipes recorded, npc %s line %s"):format(found, tostring(npc), tostring(best)))
  ns.RequestRefresh()
end
ns.On("TRAINER_SHOW", ScanTrainer)

-- Expert/Artisan trainers on Classic/Forever open a gossip box ("You'll need more training...")
-- with zero options when your skill is too low. Remember that so waypoints skip them until you level up.
local function CheckTrainerRefusal()
  if not (ComradeCraftDB and UnitGUID and strsplit) then return end
  local opts = (C_GossipInfo and C_GossipInfo.GetOptions and #(C_GossipInfo.GetOptions() or {}))
    or (GetNumGossipOptions and GetNumGossipOptions()) or 0
  if opts > 0 then return end
  local guid = UnitGUID("npc")
  if not guid or (issecretvalue and issecretvalue(guid)) then return end
  local id = select(6, strsplit("-", guid))
  local npc = tonumber(id)
  if not npc then return end
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  local c = ns.CharData()
  for pname, p in pairs(c.professions or {}) do
    local line = p.skillLine
    if line and not ns.GATHERING[line] and lib and lib.GetRecipes and lib.GetRecipeSources then
      local matched = false
      for spell in pairs(lib:GetRecipes(line) or {}) do
        local src = lib:GetRecipeSources(spell)
        for _, t in ipairs(src and src.trainer or {}) do
          if t.id == npc then matched = true break end
        end
        if matched then break end
      end
      if matched then
        ComradeCraftDB.trainerRefused = ComradeCraftDB.trainerRefused or {}
        local refName = UnitName and UnitName("npc")
        if refName and issecretvalue and issecretvalue(refName) then refName = nil end
        ComradeCraftDB.trainerRefused[npc] = { line = line, rank = p.rank or 0,
          name = refName or ("#" .. npc), t = time() }
        ns.Print(ns.L["%s requires higher %s skill; skipped for waypoints until you level up."]
          :format(ComradeCraftDB.trainerRefused[npc].name, pname))
        ns.RequestRefresh()
        return
      end
    end
  end
end
ns.On("GOSSIP_SHOW", CheckTrainerRefusal)

ns.commands.scan = function()
  ns.ScanAll()
  local c = ns.CharData()
  local n = 0
  for _ in pairs(c.bags) do n = n + 1 end
  Print(ns.L["scan ok: %d distinct items in bags"]:format(n))
  for name, p in pairs(c.professions) do
    Print(("  %s %s/%s"):format(name, tostring(p.rank), tostring(p.max)))
  end
end

ns.commands.dump = function()
  if DevTools_Dump then
    DevTools_Dump(ns.CharData())
  else
    Print(ns.L["DevTools_Dump missing; see WTF\\...\\SavedVariables\\ComradeCraft.lua after /reload"])
  end
end

-- Color of a recipe at a given rank, from the static table (nil if unknown).
-- Below yellow is orange: a known recipe is craftable, so the learn rank is not needed.
function ns.RecipeColor(spell, rank)
  local r = ns.Recipes and ns.Recipes[spell]
  if not r then return nil end
  local yellow, grey = r[2], r[3]
  if rank < yellow then return "orange" end
  if rank < math.floor((yellow + grey) / 2) then return "yellow" end
  if rank < grey then return "green" end
  return "grey"
end

-- Same, from LibProfessionDB's tiers {orange, yellow, green, grey}. On 614 Forever recipes
-- they disagree with ours (green at the client's low rank); the audit decides which is right.
function ns.LPDBColor(spell, rank)
  local lib = LibStub and LibStub("LibProfessionDB-1.0", true)
  local r = ns.Recipes and ns.Recipes[spell]
  if not (lib and r and lib.GetDifficulty) then return nil end
  local d = lib:GetDifficulty(r[1], spell)
  if not d then return nil end
  if rank < d[2] then return "orange" end
  if rank < d[3] then return "yellow" end
  if rank < d[4] then return "green" end
  return "grey"
end

local DIFF = { [0] = "orange", [1] = "yellow", [2] = "green", [3] = "grey",
  optimal = "orange", medium = "yellow", easy = "green", trivial = "grey" }

local function CurrentRank()
  local T = C_TradeSkillUI
  for _, fn in ipairs({ "GetChildProfessionInfo", "GetBaseProfessionInfo" }) do
    if T[fn] then
      local ok, info = pcall(T[fn])
      if ok and info and info.skillLevel and info.skillLevel > 0 then return info.skillLevel end
    end
  end
  if GetTradeSkillLine then return select(2, GetTradeSkillLine()) end
end

-- With a profession window open: compare the table's colors with the game's.
ns.commands.audit = function()
  local T = C_TradeSkillUI
  if not (T and T.GetAllRecipeIDs and T.GetRecipeInfo) then
    Print(ns.L["audit: C_TradeSkillUI.GetAllRecipeIDs missing on this client"]) return
  end
  local rank = CurrentRank()
  if not rank then Print(ns.L["audit: open a profession window first"]) return end
  local ok, bad, missing, trivialSame, trivialDiff = 0, 0, 0, 0, 0
  local lpOk, lpBad = 0, 0
  for _, id in ipairs(T.GetAllRecipeIDs() or {}) do
    local info = T.GetRecipeInfo(id)
    if info and info.learned then
      local game = DIFF[info.relativeDifficulty]
      local ours = ns.RecipeColor(id, rank)
      local lp = ns.LPDBColor(id, rank)
      if lp then
        if lp == game then lpOk = lpOk + 1 else lpBad = lpBad + 1 end
      end
      if not ours then
        missing = missing + 1
      elseif ours == game then
        ok = ok + 1
      else
        bad = bad + 1
        if bad <= 10 then
          local r = ns.Recipes[id]
          Print(ns.L["  %s (%d): game=%s table=%s [%d/%d]"]:format(info.name or "?", id, tostring(game), ours, r[2], r[3]))
        end
      end
      local r = ns.Recipes[id]
      if r and info.maxTrivialLevel then
        if info.maxTrivialLevel == r[3] then trivialSame = trivialSame + 1 else trivialDiff = trivialDiff + 1 end
      end
    end
  end
  Print(ns.L["audit rank %d: %d ok, %d mismatches, %d missing from the table"]:format(rank, ok, bad, missing))
  if lpOk + lpBad > 0 then
    Print(ns.L["LibProfessionDB: %d ok, %d mismatches"]:format(lpOk, lpBad))
  end
  Print(ns.L["maxTrivialLevel == grey: %d yes, %d no"]:format(trivialSame, trivialDiff))
end

-- Reports which APIs exist on this client, to validate the brief's assumptions.
ns.commands.api = function()
  Print("build : " .. tostring(select(4, GetBuildInfo())))
  local checks = {
    "GetProfessions", "GetProfessionInfo", "GetSkillLineInfo",
    "C_Container", "C_TradeSkillUI", "C_TooltipInfo", "TooltipDataProcessor",
    "ProfessionsFrame", "TradeSkillFrame", "GetTrainerServiceCost", "GetTrainerServiceSkillReq",
    "SetTrainerServiceTypeFilter", "GetSpecialization", "GetTalentTabInfo",
    "PawnGetItemData", "PawnGetSingleValueFromItem", "PawnCommon",
  }
  Print(("  pawn scale : %s"):format(tostring(ns.PawnScaleFor(ns.CharData()))))
  Print(("  spec : %s"):format(tostring((ns.ScanSpec()))))
  for _, k in ipairs({ "OpenRecipe", "OpenTradeSkill", "SetRecipeItemNameFilter" }) do
    Print(("  C_TradeSkillUI.%s : %s"):format(k, (C_TradeSkillUI and C_TradeSkillUI[k]) and ns.L["yes"] or ns.L["no"]))
  end
  for _, k in ipairs(checks) do
    Print(("  %s : %s"):format(k, _G[k] and ns.L["yes"] or ns.L["no"]))
  end
end
