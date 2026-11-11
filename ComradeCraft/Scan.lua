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
    if info then return info.itemID, info.stackCount end
    return nil
  end
  if GetContainerItemInfo then
    local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
    if link then return tonumber(link:match("item:(%d+)")), count end
  end
end

-- Sums itemID -> count over a list of bag indexes.
local function ScanBags(bags)
  local out = {}
  for _, bag in ipairs(bags) do
    for slot = 1, GetSlots(bag) or 0 do
      local id, count = GetItem(bag, slot)
      if id then out[id] = (out[id] or 0) + (count or 1) end
    end
  end
  return out
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

-- Specialization: the modern API if present, else the talent tree with the most points
-- (Classic talent tabs; return shapes differ between clients, both handled). nil if none.
function ns.ScanSpec()
  if GetSpecialization and GetSpecializationInfo then
    local i = GetSpecialization()
    if i then
      local _, name, _, icon = GetSpecializationInfo(i)
      if name then return name, icon end
    end
  end
  if GetNumTalentTabs and GetTalentTabInfo then
    local bestName, bestIcon, bestPoints = nil, nil, 0
    for t = 1, GetNumTalentTabs() or 0 do
      local r = { GetTalentTabInfo(t) }
      local name, icon, points
      if type(r[1]) == "string" then
        name, icon, points = r[1], r[2], r[3]       -- name, icon, pointsSpent, ...
      else
        name, icon, points = r[2], r[4], r[5]       -- id, name, description, icon, pointsSpent, ...
      end
      if type(points) == "number" and points > bestPoints then
        bestName, bestIcon, bestPoints = name, icon, points
      end
    end
    return bestName, bestIcon
  end
end

-- Equipped items { [slot 1-19] = itemID }, used to tell upgrades for group members.
function ns.ScanEquipped()
  local out = {}
  if not GetInventoryItemID then return out end
  for slot = 1, 19 do
    local id = GetInventoryItemID("player", slot)
    if id then out[slot] = id end
  end
  return out
end

-- Current bag contents { [itemID] = count } (bank excluded).
function ns.ScanBagContents()
  return ScanBags(BagIndexes())
end

function ns.ScanAll()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local c = ns.CharData()
  c.spec, c.specIcon = ns.ScanSpec()
  c.equipped = ns.ScanEquipped()
  c.professions = ScanProfessions()
  c.bags = ScanBags(BagIndexes())
  c.updated = time()
  ns.RequestRefresh()
end

-- Known recipes of the open profession window, keyed by skill line (from our table).
local function ScanKnownRecipes()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local T = C_TradeSkillUI
  if not (T and T.GetAllRecipeIDs and T.GetRecipeInfo) then return end
  if T.IsTradeSkillLinked and T.IsTradeSkillLinked() then return end
  if T.IsTradeSkillGuild and T.IsTradeSkillGuild() then return end
  local c = ns.CharData()
  c.known = c.known or {}
  local found = {}
  for _, id in ipairs(T.GetAllRecipeIDs() or {}) do
    local r = ns.Recipes[id]
    if r then
      local info = T.GetRecipeInfo(id)
      if info and info.learned then
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

ns.On("PLAYER_ENTERING_WORLD", ns.ScanAll)
ns.On("SKILL_LINES_CHANGED", ns.ScanAll)
ns.On("BAG_UPDATE_DELAYED", ns.ScanAll)
ns.On("CHAT_MSG_SKILL", ns.ScanAll) -- "Your skill in X has increased to N"
for _, e in ipairs({ "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED",
  "PLAYER_SPECIALIZATION_CHANGED" }) do
  ns.On(e, ns.ScanAll) -- talents change the specialization
end
ns.On("PLAYER_EQUIPMENT_CHANGED", ns.ScanAll)
ns.On("BANKFRAME_OPENED", ScanBank)
ns.On("TRADE_SKILL_LIST_UPDATE", ScanKnownRecipes)

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

local scanningTrainer = false
local function ScanTrainer()
  if scanningTrainer or not (ComradeCraftDB and GetNumTrainerServices and GetTrainerServiceInfo) then return end
  scanningTrainer = true
  -- Show every service (available, unavailable, already known), then restore the filters.
  local saved = {}
  if GetTrainerServiceTypeFilter and SetTrainerServiceTypeFilter then
    for _, k in ipairs({ "available", "unavailable", "used" }) do
      saved[k] = GetTrainerServiceTypeFilter(k)
      if not saved[k] then SetTrainerServiceTypeFilter(k, 1) end
    end
  end
  local lines = {}
  for name, p in pairs(ns.CharData().professions or {}) do lines[name] = p.skillLine end
  ComradeCraftDB.trainer = ComradeCraftDB.trainer or {}
  local found, lineCount = 0, {}
  for i = 1, GetNumTrainerServices() do
    local name, _, kind = GetTrainerServiceInfo(i)
    if name and kind ~= "header" then
      local skillName, req = nil, nil
      if GetTrainerServiceSkillReq then skillName, req = GetTrainerServiceSkillReq(i) end
      local cost = GetTrainerServiceCost and GetTrainerServiceCost(i) or nil
      local line = skillName and lines[skillName]
      for _, spell in ipairs(SpellIDsByName(name) or {}) do
        if not line or ns.Recipes[spell][1] == line then
          ComradeCraftDB.trainer[spell] = { cost = cost, req = req, t = time() }
          found = found + 1
          lineCount[ns.Recipes[spell][1]] = (lineCount[ns.Recipes[spell][1]] or 0) + 1
        end
      end
    end
  end
  for k, v in pairs(saved) do
    if not v then SetTrainerServiceTypeFilter(k, 0) end
  end
  scanningTrainer = false
  -- Where this trainer stands (exact, unlike the capped lists of LibProfessionDB): used first
  -- for "Learn" waypoints. Their position is the player's while the window is open.
  local guid = UnitGUID and UnitGUID("npc")
  local npc = guid and tonumber(select(6, strsplit("-", guid)))
  local best, most = nil, 0
  for l, n in pairs(lineCount) do if n > most then best, most = l, n end end
  local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
  if npc and best and pos then
    local x, y
    if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
    ComradeCraftDB.trainerSpots = ComradeCraftDB.trainerSpots or {}
    ComradeCraftDB.trainerSpots[npc] = { name = UnitName("npc"), line = best, map = map,
      x = math.floor(x * 10000) / 100, y = math.floor(y * 10000) / 100, t = time() }
  end
  ns.Log(("trainer: %d recipes recorded, npc %s line %s"):format(found, tostring(npc), tostring(best)))
  ns.RequestRefresh()
end
ns.On("TRAINER_SHOW", ScanTrainer)

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
