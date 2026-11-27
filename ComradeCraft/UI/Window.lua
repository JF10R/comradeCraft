-- UI/Window: main frame, sidebar navigation, profession filter chips, refresh loop, and minimap button.
local _, ns = ...
local L = ns.L
local U = ns.UI
local P = U.pools
local W, H, SIDE_W, SIDE_LIST_W, DETAIL_X, LIST_W =
  U.W, U.H, U.SIDE_W, U.SIDE_LIST_W, U.DETAIL_X, U.LIST_W
local sideBtns = P.sideBtns
local missingItems = U.missingItems
local Acquire, ReleaseAll, ItemInfo, Ago, SortedKeys, LineVisible, LevelSpecClass =
  U.Acquire, U.ReleaseAll, U.ItemInfo, U.Ago, U.SortedKeys, U.LineVisible, U.LevelSpecClass
local AddBorder, SetBorderColor, PeerName, ClearSearch =
  U.AddBorder, U.SetBorderColor, U.PeerName, U.ClearSearch
local frame, content, side

local function CreateSideBtn()
  local b = CreateFrame("Button", nil, side)
  b:SetWidth(SIDE_LIST_W - 4)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.sel = b:CreateTexture(nil, "BACKGROUND")
  b.sel:SetAllPoints()
  b.sel:SetColorTexture(0.16, 0.16, 0.20, 0.88)
  b.glow = b:CreateTexture(nil, "BACKGROUND", nil, -1)
  b.glow:SetAllPoints()
  b.glow:SetColorTexture(0.28, 0.20, 0.05, 0.55)
  b.glow:Hide()
  b.accent = b:CreateTexture(nil, "ARTWORK")
  b.accent:SetWidth(2)
  b.accent:SetPoint("TOPLEFT", 0, 0)
  b.accent:SetPoint("BOTTOMLEFT", 0, 0)
  b.accent:SetColorTexture(1, 0.82, 0, 1)
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.name:SetPoint("TOPLEFT", 8, -4)
  b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.sub:SetPoint("TOPLEFT", 8, -20)
  b.sub:SetWidth(SIDE_LIST_W - 18)
  b.sub:SetJustifyH("LEFT")
  b:SetScript("OnClick", function(self)
    if self.foldSec then
      local ui = ComradeCraftDB.ui
      ui.sideFold = ui.sideFold or {}
      ui.sideFold[self.foldSec] = not ui.sideFold[self.foldSec] or nil
      ns.RefreshWindow()
    elseif self.peerID then
      ns.Sync.Include(self.peerID) -- a suggestion: click adds that player to the group
    elseif self.key then
      if ComradeCraftDB.ui.sel ~= self.key then ClearSearch() end
      ComradeCraftDB.ui.sel = self.key
      ns.RefreshWindow()
    end
  end)
  return b
end


local sideDiv
local function RenderSide(sel)
  ReleaseAll(sideBtns)
  local chars = ns.AllChars()
  local y = -2
  local function Add(key, name, sub, peerID, alertGlow, foldSec)
    local b = Acquire(sideBtns, CreateSideBtn)
    b.key, b.peerID, b.foldSec = key, peerID, foldSec
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", side, "TOPLEFT", 4, y)
    b.name:SetText(name)
    b.sub:SetText(sub)
    local h = foldSec and 20 or (24 + (sub ~= "" and (b.sub:GetStringHeight() or 12) or 0))
    b:SetHeight(h)
    b.sel:SetShown(not foldSec and sel == key)
    b.glow:SetShown(alertGlow and sel ~= key)
    b.accent:SetShown((not foldSec and sel == key) or alertGlow)
    if alertGlow and sel ~= key then
      b.accent:SetColorTexture(0.35, 1.0, 0.45, 1)
    else
      b.accent:SetColorTexture(1, 0.82, 0, 1)
    end
    y = y - h - (foldSec and 2 or 4)
  end
  local inToMe = ns.InTransitFor and select(2, ns.InTransitFor(ns.CharKey())) or {}
  local grpSub = ns.Plural(#SortedKeys(chars), "%d member", "%d members")
    .. (#inToMe > 0 and ("  |cff80ccff" .. L["%d in transit"]:format(#inToMe) .. "|r") or "")
  Add("group", L["Group"], grpSub)
  local farmCount = 0
  for _, c in pairs(chars) do
    for _ in pairs(c.farming or {}) do farmCount = farmCount + 1 end
  end
  local planSub = farmCount > 0 and ("|cff40ff40" .. L["%d farming"]:format(farmCount) .. "|r")
    or ("|cff9d9d9d" .. (ns.GroupObjective() == "group" and L["Lowest group cost"] or L["Market value"]) .. "|r")
  Add("groupplan", L["Group plan"], planSub)
  local wList = ns.Wishlist and ns.Wishlist.List() or {}
  local wReady = 0
  for _, e in ipairs(wList) do if ns.Wishlist.Progress(e).bagReady then wReady = wReady + 1 end end
  local wSub = wReady > 0 and ("|cff40ff40" .. L["%d ready"]:format(wReady) .. "|r")
    or (#wList > 0 and ("|cff9d9d9d" .. ns.Plural(#wList, "%d tracked", "%d tracked") .. "|r")
    or ("|cff9d9d9d" .. L["none pinned"] .. "|r"))
  Add("wishlist", L["Wishlist"], wSub)
  local open = ns.Requests and ns.Requests.OpenCount() or 0
  Add("requests", open > 0 and ("|cff60ff70" .. L["Craft requests"] .. "|r") or L["Craft requests"],
    open > 0 and ("|cff80ff80" .. ns.Plural(open, "%d to answer", "%d to answer") .. "|r")
    or ("|cff9d9d9d" .. L["none open"] .. "|r"), nil, open > 0)
  local listed = 0
  for _ in pairs(ns.Directory.Index().chars) do listed = listed + 1 end
  Add("directory", L["Guild directory"], "|cff9d9d9d" .. ns.Plural(listed, "%d crafter", "%d crafters") .. "|r")
  local inGroup, requests = 0, 0
  for _, peer in pairs(ComradeCraftDB.peers or {}) do
    if peer.included then inGroup = inGroup + 1 elseif peer.asked then requests = requests + 1 end
  end
  Add("manage", L["Manage group"], ns.Plural(inGroup, "%d player", "%d players")
    .. (requests > 0 and ("  |cff80ff80" .. ns.Plural(requests, "%d request", "%d requests") .. "|r") or ""),
    nil, requests > 0)

  -- Visual divider between navigation views and character sheets.
  if not sideDiv then
    sideDiv = side:CreateTexture(nil, "ARTWORK")
    sideDiv:SetHeight(1)
    sideDiv:SetWidth(SIDE_LIST_W - 12)
    sideDiv:SetColorTexture(0.6, 0.5, 0.3, 0.45)
  end
  sideDiv:ClearAllPoints()
  sideDiv:SetPoint("TOPLEFT", side, "TOPLEFT", 6, y - 3)
  y = y - 10
  local charKeys = SortedKeys(chars)
  local meKey = ns.CharKey()
  -- Quick filter in sidebar when the group/guild grows large (>8 characters).
  local sideFilter = ""
  if frame and frame.sideSearch then
    local showFilter = #charKeys > 8
    frame.sideSearch:SetShown(showFilter)
    if showFilter then
      frame.sideSearch:ClearAllPoints()
      frame.sideSearch:SetPoint("TOPLEFT", side, "TOPLEFT", 6, y)
      sideFilter = (frame.sideSearch:GetText() or ""):lower()
      y = y - 24
    end
  end
  local compact = #charKeys > 12 and sideFilter == ""
  local favList, ownList, grpList = {}, {}, {}
  for _, key in ipairs(charKeys) do
    local c = chars[key]
    local matchFilter = sideFilter == "" or key:lower():find(sideFilter, 1, true)
      or (c.peer and (PeerName(c) or ""):lower():find(sideFilter, 1, true))
    if matchFilter or sel == key then
      local shown = 0
      for _, p in pairs(c.professions or {}) do
        if LineVisible(p.skillLine) then shown = shown + 1 end
      end
      if shown > 0 or c.bankAlt or not ComradeCraftDB.ui.prof or sel == key then
        if ns.IsFavorite and ns.IsFavorite(key) then favList[#favList + 1] = key
        elseif not c.peer then ownList[#ownList + 1] = key
        else grpList[#grpList + 1] = key end
      end
    end
  end
  table.sort(ownList, function(a, b)
    if (a == meKey) ~= (b == meKey) then return a == meKey end
    return a < b
  end)
  local fold = ComradeCraftDB.ui and ComradeCraftDB.ui.sideFold or {}
  local function AddCharSection(secId, title, list)
    if #list == 0 then return end
    local isFolded = sideFilter == "" and fold[secId] == true
    local marker = isFolded and "|cff9d9d9d[+]|r " or "|cffffd100[-]|r "
    Add(nil, marker .. "|cffffd100" .. title .. "|r |cff9d9d9d(" .. #list .. ")|r", "", nil, false, secId)
    if isFolded then return end
    for _, key in ipairs(list) do
      local c = chars[key]
      local lines = {}
      if compact and key ~= sel and key ~= meKey then
        local tag = c.bankAlt and (" |cff80ccff[" .. L["Bank"] .. "]|r") or ""
        lines[1] = LevelSpecClass(c) .. tag
      else
        lines[1] = LevelSpecClass(c)
        if c.bankAlt then lines[#lines + 1] = "|cff80ccff[" .. L["Bank"] .. "]|r" end
        if c.peer then lines[#lines + 1] = "|cff66ccff" .. L["via %s"]:format(PeerName(c) or "?") .. "|r"
        elseif not c.shared then lines[#lines + 1] = "|cff9d9d9d" .. L["not shared"] .. "|r" end
        for _, pname in ipairs(SortedKeys(c.professions or {})) do
          local p = c.professions[pname]
          if LineVisible(p.skillLine) then
            local pct = (p.max or 0) > 0 and (p.rank or 0) / p.max or 0
            local locName = ns.ProfName and ns.ProfName(p.skillLine, pname) or pname
            lines[#lines + 1] = ("%s |cff%s%d/%d|r"):format(locName, pct >= 1 and "40c040" or "ffd100", p.rank or 0, p.max or 0)
          end
        end
      end
      local star = ns.IsFavorite and ns.IsFavorite(key) and "|cffffd100* |r" or ""
      Add(key, star .. ns.ClassColored(key, c.class), table.concat(lines, "\n"))
    end
  end
  AddCharSection("fav", L["Favorites"], favList)
  AddCharSection("own", L["My characters"], ownList)
  AddCharSection("grp", L["Group members"], grpList)
  side:SetHeight(math.max(1, -y))
end


-- Refresh ---------------------------------------------------------------------------------

-- Filter row: "All" + one chip per profession present in the group, and "Hide gathering".
local chips = {}
local function CreateChip()
  local b = CreateFrame("Button", nil, frame)
  b:SetHeight(20)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  AddBorder(b)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.label:SetPoint("CENTER")
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b:SetScript("OnClick", function(self)
    ComradeCraftDB.ui.prof = self.line
    ns.RefreshWindow()
  end)
  return b
end

local function LocalProfName(line, fallback)
  return ns.ProfName and ns.ProfName(line, fallback) or fallback
end

local function RenderChips(chars, startY)
  ReleaseAll(chips)
  local ui = ComradeCraftDB.ui
  local names, lines = {}, {}
  for _, c in pairs(chars) do
    for pname, p in pairs(c.professions or {}) do
      local line = p.skillLine
      if line and not names[line] and not (ui.hideGathering ~= false and ns.GATHERING[line]) then
        names[line] = LocalProfName(line, pname)
        lines[#lines + 1] = line
      end
    end
  end
  table.sort(lines, function(a, b) return names[a] < names[b] end)
  if ui.prof and not names[ui.prof] then ui.prof = nil end
  local x, rowY = DETAIL_X, startY or -140
  local maxX = W - 34
  local function Chip(line, text)
    local b = Acquire(chips, CreateChip)
    b.line = line
    b.label:SetText(text)
    local active = ui.prof == line
    if active then
      b.bg:SetColorTexture(0.16, 0.16, 0.20, 0.96)
      SetBorderColor(b, 0.82, 0.66, 0.24, 0.92)
      b.label:SetTextColor(1, 0.85, 0.22)
    else
      b.bg:SetColorTexture(0.08, 0.08, 0.10, 0.9)
      SetBorderColor(b, 0.28, 0.25, 0.20, 0.6)
      b.label:SetTextColor(0.75, 0.75, 0.78)
    end
    local w = math.max(40, (b.label:GetStringWidth() or 40) + 16)
    if x > DETAIL_X and x + w > maxX then
      x = DETAIL_X
      rowY = rowY - 24
    end
    b:SetWidth(w)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", frame, "TOPLEFT", x, rowY)
    x = x + w + 4
  end
  Chip(nil, L["All"])
  for _, line in ipairs(lines) do Chip(line, names[line]) end
  local gw = 26 + (frame.gatherBox.label:GetStringWidth() or 100)
  if x > DETAIL_X and x + gw + 8 > maxX then
    x = DETAIL_X
    rowY = rowY - 24
  end
  frame.gatherBox:ClearAllPoints()
  frame.gatherBox:SetPoint("TOPLEFT", frame, "TOPLEFT", x + (x > DETAIL_X and 8 or 0), rowY + 2)
  frame.gatherBox:SetChecked(ui.hideGathering ~= false)
  frame.gatherBox:Show()
  return rowY - 26
end

local function SetSearchPlaceholder(text)
  local inst = frame and frame.search and frame.search.Instructions
  if type(inst) == "table" and inst.SetText then inst:SetText(text or "") end
end

local lastSel, lastTab, lastGroupTab
function ns.RefreshWindow()
  if not (frame and frame:IsShown()) then return end
  local ui = ComradeCraftDB.ui
  local chars = ns.AllChars()
  if ui.sel ~= "group" and ui.sel ~= "manage" and ui.sel ~= "help" and ui.sel ~= "requests" and ui.sel ~= "groupplan"
    and ui.sel ~= "directory" and ui.sel ~= "wishlist" and not chars[ui.sel or ""] then
    ui.sel = chars[ns.CharKey()] and ns.CharKey() or "group"
  end
  if ui.sel ~= lastSel or ui.tab ~= lastTab or ui.groupTab ~= lastGroupTab then
    if frame.scroll and frame.scroll.SetVerticalScroll then frame.scroll:SetVerticalScroll(0) end
    lastSel, lastTab, lastGroupTab = ui.sel, ui.tab, ui.groupTab
  end
  U.ReleaseContentPools()
  frame.addBox:Hide()
  if frame.favBtn then frame.favBtn:Hide() end
  frame.groupOverTab:Hide() frame.groupMatsTab:Hide() frame.groupUpTab:Hide() frame.groupDeTab:Hide()
  if frame.patTab then frame.patTab:Hide() end
  RenderSide(ui.sel)

  local filter = (frame.search:GetText() or ""):lower()
  local h, scrollTop = 1, -110
  frame.sub:SetWidth(LIST_W - 20)
  if ui.sel == "wishlist" then
    frame.title:SetText(L["Wishlist"])
    frame.sub:SetText(L["Pinned crafts to track materials for yourself or friends."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    frame.removeBtn:Hide()
    frame.shareBox:Hide()
    frame.search:Hide()
    ReleaseAll(chips)
    frame.gatherBox:Hide()
    h = U.RenderWishlist()
  elseif ui.sel == "requests" then
    frame.title:SetText(L["Craft requests"])
    frame.sub:SetText(L["Ask a group member to craft something, or answer what they asked you."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    frame.removeBtn:Hide()
    frame.shareBox:Hide()
    frame.search:Hide()
    ReleaseAll(chips)
    frame.gatherBox:Hide()
    h = U.RenderRequests()
  elseif ui.sel == "groupplan" then
    frame.title:SetText(L["Group plan"])
    frame.sub:SetText(L["What the group still needs, what it already holds, and who farms what."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    frame.removeBtn:Hide()
    frame.shareBox:Hide()
    frame.search:Hide()
    ReleaseAll(chips)
    frame.gatherBox:Hide()
    h = U.RenderGroupPlan()
  elseif ui.sel == "directory" then
    frame.title:SetText(L["Guild directory"])
    frame.sub:SetText(L["Who in your guild can craft what. Each player lists their own characters (opt-in)."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    frame.removeBtn:Hide()
    frame.shareBox:Hide()
    frame.search:ClearAllPoints()
    frame.search:SetPoint("TOPLEFT", frame, "TOPLEFT", DETAIL_X + 6, -108)
    SetSearchPlaceholder(L["Search guild crafters..."])
    frame.search:Show()
    ReleaseAll(chips)
    frame.gatherBox:Hide()
    scrollTop = -136
    h = U.RenderDirectory(filter)
  elseif ui.sel == "help" then
    frame.title:SetText(L["Help"])
    frame.sub:SetText(L["How ComradeCraft works, in short."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    frame.removeBtn:Hide()
    frame.shareBox:Hide()
    frame.search:Hide()
    ReleaseAll(chips)
    frame.gatherBox:Hide()
    h = U.RenderHelp()
  elseif ui.sel == "manage" then
    frame.title:SetText(L["Manage group"])
    frame.sub:SetText(L["Choose what you share, and with whom."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    frame.removeBtn:Hide()
    frame.shareBox:Hide()
    frame.search:Hide()
    ReleaseAll(chips)
    frame.gatherBox:Hide()
    h = U.RenderManage()
  elseif ui.sel == "group" then
    local gTab = ui.groupTab or "overview"
    frame.groupOverTab:Show() frame.groupMatsTab:Show() frame.groupUpTab:Show() frame.groupDeTab:Show()
    frame.groupOverTab:SetActive(gTab == "overview")
    frame.groupMatsTab:SetActive(gTab == "mats")
    frame.groupUpTab:SetActive(gTab == "upgrades")
    frame.groupDeTab:SetActive(gTab == "de")
    frame.search:ClearAllPoints()
    frame.search:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -112)
    SetSearchPlaceholder(L["Search stock or crafters..."])
    frame.search:Show()
    if (gTab == "de" or gTab == "upgrades") and filter == "" then
      ReleaseAll(chips)
      frame.gatherBox:Hide()
      scrollTop = -142
    else
      scrollTop = RenderChips(chars, -142)
    end
    frame.title:SetText(L["Group"])
    local gSubs = {
      overview = L["Your group's skill levels, synergies, items you can give, and active cooldowns."],
      mats = L["All materials your group still needs, sorted by urgency. Type to find who can craft something."],
      upgrades = L["Craftable BiS gear, enchants, consumables, small bags, and patterns to hunt for each member."],
      de = L["Green items in your bags: keep for enchants or upgrades, sell on the AH, or disenchant."],
    }
    frame.sub:SetText(gSubs[gTab] or L["Skill levels and the materials the group still needs. Type to find who can craft something."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    frame.removeBtn:Hide()
    frame.shareBox:Hide()
    h = U.RenderGroup(filter)
  else
    local c = chars[ui.sel]
    local bankTag = c.bankAlt and ("  |cff80ccff[" .. L["Bank"] .. "]|r") or ""
    frame.title:SetText(ns.ClassColored(ui.sel, c.class) .. bankTag)
    frame.sub:SetWidth(LIST_W - 260)
    frame.sub:SetText(("%s - %s%s"):format(LevelSpecClass(c),
      L["updated %s"]:format(Ago(c.updated)), c.peer and (" - " .. L["via %s"]:format(PeerName(c) or "?")) or ""))
    frame.removeBtn.peerID = c.peer
    frame.removeBtn:SetShown(c.peer ~= nil)
    if frame.favBtn then
      frame.favBtn.key = ui.sel
      local fav = ns.IsFavorite and ns.IsFavorite(ui.sel)
      frame.favBtn:SetText(fav and ("|cffffd100* |r" .. L["Unstar"]) or L["Favorite"])
      frame.favBtn:ClearAllPoints()
      if c.peer then
        frame.favBtn:SetPoint("RIGHT", frame.removeBtn, "LEFT", -6, 0)
      else
        frame.favBtn:SetPoint("RIGHT", frame.shareBox.label, "LEFT", -10, 0)
      end
      frame.favBtn:Show()
    end
    frame.shareBox.key = not c.peer and ui.sel or nil
    frame.shareBox:SetShown(c.peer == nil)
    frame.shareBox:SetChecked(c.shared and true or false)
    if c.bankAlt then
      frame.planTab:Hide()
      frame.craftTab:Hide()
      frame.search:ClearAllPoints()
      frame.search:SetPoint("TOPLEFT", frame, "TOPLEFT", DETAIL_X + 6, -108)
      SetSearchPlaceholder(L["Filter items..."])
      frame.search:Show()
      ReleaseAll(chips)
      frame.gatherBox:Hide()
      scrollTop = -136
      h = U.RenderBankAlt(ui.sel, c, filter)
    else
      frame.planTab:Show()
      frame.craftTab:Show()
      if frame.patTab then frame.patTab:Show() end
      frame.planTab:SetActive(ui.tab ~= "craft" and ui.tab ~= "patterns")
      frame.craftTab:SetActive(ui.tab == "craft")
      if frame.patTab then frame.patTab:SetActive(ui.tab == "patterns") end
      if ui.tab == "craft" or ui.tab == "patterns" then
        frame.search:ClearAllPoints()
        frame.search:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -112)
        SetSearchPlaceholder(L["Filter recipes..."])
        frame.search:Show()
      else
        frame.search:Hide()
      end
      scrollTop = RenderChips({ [ui.sel] = c }, -142)
      if ui.tab == "craft" then
        h = U.RenderCraft(ui.sel, c, filter)
      elseif ui.tab == "patterns" then
        h = U.RenderPatterns(ui.sel, c, filter)
      else
        h = U.RenderPlan(ui.sel, c)
      end
    end
  end
  if frame.scroll then
    frame.scroll:ClearAllPoints()
    frame.scroll:SetPoint("TOPLEFT", DETAIL_X, scrollTop)
    frame.scroll:SetPoint("BOTTOMRIGHT", -34, 36)
  end
  content:SetHeight(math.max(1, h or 1))

  local members, profs = 0, 0
  for _, c in pairs(chars) do
    members = members + 1
    for _ in pairs(c.professions or {}) do profs = profs + 1 end
  end
  frame.badge:SetText(ns.Plural(members, "%d member", "%d members") .. " - "
    .. ns.Plural(profs, "%d profession", "%d professions"))

  local inGroup, suggested = 0, 0
  for _, peer in pairs(ComradeCraftDB.peers or {}) do
    if peer.included then inGroup = inGroup + 1 elseif peer.name then suggested = suggested + 1 end
  end
  frame.foot:SetText(L["Sync: %d players in the group, %d suggested."]:format(inGroup, suggested))
end

local function CreateWindow()
  local ok, f = pcall(CreateFrame, "Frame", "ComradeCraftFrame", UIParent, "ButtonFrameTemplate")
  if not ok or not f then
    f = CreateFrame("Frame", "ComradeCraftFrame", UIParent, "BasicFrameTemplateWithInset")
  end
  local savedH = ComradeCraftDB and ComradeCraftDB.ui and tonumber(ComradeCraftDB.ui.height)
  f:SetSize(W, (savedH and savedH >= 440 and savedH <= 820) and savedH or H)
  if f.SetScale and ns.UIScale then f:SetScale(ns.UIScale()) end
  local pos = ComradeCraftDB and ComradeCraftDB.ui and ComradeCraftDB.ui.pos
  if pos then f:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3]) else f:SetPoint("CENTER") end
  -- Same layer as the game's windows: the profession window can come in front of it.
  f:SetFrameStrata("MEDIUM")
  f:SetToplevel(true)
  f:SetMovable(true)
  if f.SetResizable then f:SetResizable(true) end
  if f.SetResizeBounds then f:SetResizeBounds(W, 440, W, 820)
  elseif f.SetMinResize and f.SetMaxResize then f:SetMinResize(W, 440) f:SetMaxResize(W, 820) end
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    if ComradeCraftDB and ComradeCraftDB.ui and point then ComradeCraftDB.ui.pos = { point, x, y } end
  end)
  f:Hide()
  if ButtonFrameTemplate_HideButtonBar then pcall(ButtonFrameTemplate_HideButtonBar, f) end
  if f.SetTitle then f:SetTitle("ComradeCraft")
  elseif f.TitleText then f.TitleText:SetText("ComradeCraft") end
  if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, ns.LOGO) end
  tinsert(UISpecialFrames, "ComradeCraftFrame") -- Escape closes it

  -- Left: character list.
  local sideScroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  sideScroll:SetPoint("TOPLEFT", 12, -66)
  sideScroll:SetPoint("BOTTOMLEFT", 12, 36)
  sideScroll:SetWidth(SIDE_LIST_W) -- the template's scroll bar sits outside, to the right
  side = CreateFrame("Frame", nil, sideScroll)
  U.side = side
  side:SetSize(SIDE_LIST_W, 1)
  sideScroll:SetScrollChild(side)
  local sep = f:CreateTexture(nil, "ARTWORK")
  sep:SetColorTexture(0.6, 0.5, 0.3, 0.5)
  sep:SetWidth(1)
  sep:SetPoint("TOPLEFT", DETAIL_X - 4, -64)
  sep:SetPoint("BOTTOMLEFT", DETAIL_X - 4, 36)

  -- Right: header, tabs, search, scrolling detail.
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  f.title:SetPoint("TOPLEFT", DETAIL_X, -66)
  f.title:SetJustifyH("LEFT")
  f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -4)
  f.sub:SetJustifyH("LEFT")
  f.sub:SetWordWrap(false)
  -- "?" opens the help view (click again to go back to the group).
  f.helpBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.helpBtn:SetSize(24, 22)
  f.helpBtn:SetPoint("TOPRIGHT", -24, -64)
  f.helpBtn:SetText("?")
  f.helpBtn:SetScript("OnClick", function()
    local ui = ComradeCraftDB.ui
    ui.sel = ui.sel == "help" and "group" or "help"
    ns.RefreshWindow()
  end)
  f.optBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.optBtn:SetSize(64, 22)
  f.optBtn:SetPoint("RIGHT", f.helpBtn, "LEFT", -4, 0)
  f.optBtn:SetText(L["Options"])
  f.optBtn:SetScript("OnClick", function() if ns.OpenOptions then ns.OpenOptions() end end)
  f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.badge:SetPoint("RIGHT", f.optBtn, "LEFT", -10, 0)

  -- Sculpted dark-stone tabs: bronze/gold carved border + gold underline + hover tooltip.
  local function Tab(text, tab, anchor, field, w, tip)
    local b = CreateFrame("Button", nil, f)
    b:SetSize(w or 120, 24)
    b:SetPoint(unpack(anchor))
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    AddBorder(b)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.label:SetPoint("CENTER")
    b.label:SetText(text)
    b.under = b:CreateTexture(nil, "ARTWORK")
    b.under:SetHeight(2)
    b.under:SetPoint("BOTTOMLEFT", 1, 0)
    b.under:SetPoint("BOTTOMRIGHT", -1, 0)
    b.under:SetColorTexture(0.95, 0.78, 0.20, 1)
    b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    function b:SetActive(on)
      if on then
        self.bg:SetColorTexture(0.16, 0.16, 0.20, 0.98)
        SetBorderColor(self, 0.82, 0.66, 0.24, 0.92)
        self.label:SetTextColor(1, 0.86, 0.24)
      else
        self.bg:SetColorTexture(0.08, 0.08, 0.10, 0.90)
        SetBorderColor(self, 0.28, 0.25, 0.20, 0.65)
        self.label:SetTextColor(0.68, 0.68, 0.72)
      end
      self.under:SetShown(on)
    end
    if tip then
      b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(text, 1, 0.82, 0)
        GameTooltip:AddLine(tip, 1, 1, 1, true)
        GameTooltip:Show()
      end)
      b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    b:SetScript("OnClick", function()
      ComradeCraftDB.ui[field or "tab"] = tab
      ns.RefreshWindow()
    end)
    return b
  end
  f.planTab = Tab(L["Plan"], "plan", { "TOPLEFT", DETAIL_X, -112 }, nil, nil,
    L["Step-by-step profession leveling route, cost comparison, and trainer guide."])
  f.craftTab = Tab(L["Can craft"], "craft", { "TOPLEFT", DETAIL_X + 126, -112 }, nil, nil,
    L["Known recipes. Right-click to pin to Wishlist, or click a friend's recipe to request it."])
  f.patTab = Tab(L["Patterns"], "patterns", { "TOPLEFT", DETAIL_X + 252, -112 }, nil, 110,
    L["Important unlearned patterns to buy or farm for yourself and your group (with drop rate and waypoints)."])
  f.groupOverTab = Tab(L["Overview"], "overview", { "TOPLEFT", DETAIL_X, -112 }, "groupTab", 100,
    L["Your group's skill levels, synergies, items you can give, and active cooldowns."])
  f.groupMatsTab = Tab(L["Materials"], "mats", { "TOPLEFT", DETAIL_X + 104, -112 }, "groupTab", 100,
    L["All materials your group still needs, sorted by urgency. Type to find who can craft something."])
  f.groupUpTab = Tab(L["Upgrades"], "upgrades", { "TOPLEFT", DETAIL_X + 208, -112 }, "groupTab", 100,
    L["Craftable BiS gear, enchants, consumables, small bags, and patterns to hunt for each member."])
  f.groupDeTab = Tab(L["Disenchant"], "de", { "TOPLEFT", DETAIL_X + 312, -112 }, "groupTab", 104,
    L["Green items in your bags: keep for enchants or upgrades, sell on the AH, or disenchant."])
  f.groupOverTab:Hide() f.groupMatsTab:Hide() f.groupUpTab:Hide() f.groupDeTab:Hide()

  -- Shown on this account's characters: opt-in sharing (nothing is sent until checked).
  f.shareBox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  f.shareBox:SetSize(22, 22)
  f.shareBox:SetPoint("TOPRIGHT", -24, -88)
  f.shareBox.label = f.shareBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.shareBox.label:SetPoint("RIGHT", f.shareBox, "LEFT", -2, 0)
  f.shareBox.label:SetText(L["Share this character with the group"])
  f.shareBox:SetScript("OnClick", function(self)
    if self.key then ns.Sync.SetShared(self.key, self:GetChecked() and true or false) end
  end)

  -- Shown on a character received from another player: stops sharing with that player.
  f.removeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.removeBtn:SetSize(150, 22)
  f.removeBtn:SetText(L["Remove from group"])
  f.removeBtn:SetPoint("TOPRIGHT", -24, -88)
  f.removeBtn:SetScript("OnClick", function(self)
    if self.peerID then
      ns.Sync.Exclude(self.peerID)
      ComradeCraftDB.ui.sel = "group"
      ns.RefreshWindow()
    end
  end)

  -- Favorite toggle on character sheets (pins character at top of sidebar & prefers as crafter).
  f.favBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.favBtn:SetSize(78, 22)
  f.favBtn:SetText(L["Favorite"])
  f.favBtn:SetScript("OnClick", function(self)
    if self.key and ns.ToggleFavorite then ns.ToggleFavorite(self.key) end
  end)
  f.favBtn:Hide()

  -- Compact sidebar quick-filter shown automatically when the group/guild has >10 characters.
  local okS, sideSearch = pcall(CreateFrame, "EditBox", nil, side, "SearchBoxTemplate")
  if not okS or not sideSearch then sideSearch = CreateFrame("EditBox", nil, side, "InputBoxTemplate") end
  sideSearch:SetSize(SIDE_LIST_W - 14, 18)
  sideSearch:SetAutoFocus(false)
  if type(sideSearch.Instructions) == "table" and sideSearch.Instructions.SetText then
    sideSearch.Instructions:SetText(L["Filter characters..."])
  end
  local sidePending = false
  sideSearch:HookScript("OnTextChanged", function()
    if C_Timer and C_Timer.After then
      if sidePending then return end
      sidePending = true
      C_Timer.After(0.15, function() sidePending = false ns.RefreshWindow() end)
    else
      ns.RefreshWindow()
    end
  end)
  sideSearch:Hide()
  f.sideSearch = sideSearch

  local ok2, search = pcall(CreateFrame, "EditBox", nil, f, "SearchBoxTemplate")
  if not ok2 or not search then search = CreateFrame("EditBox", nil, f, "InputBoxTemplate") end
  search:SetSize(200, 20)
  search:SetPoint("TOPRIGHT", -30, -112)
  search:SetAutoFocus(false)
  local searchPending = false
  search:HookScript("OnTextChanged", function()
    if U.suppressSearch then return end
    if C_Timer and C_Timer.After then
      if searchPending then return end
      searchPending = true
      C_Timer.After(0.15, function()
        searchPending = false
        ns.RefreshWindow()
      end)
    else
      ns.RefreshWindow()
    end
  end)
  f.search = search

  -- "Hide gathering" next to the profession chips (placed by RenderChips).
  f.gatherBox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  f.gatherBox:SetSize(22, 22)
  f.gatherBox.label = f.gatherBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.gatherBox.label:SetPoint("LEFT", f.gatherBox, "RIGHT", 2, 0)
  f.gatherBox.label:SetText(L["Hide gathering"])
  f.gatherBox:SetScript("OnClick", function(self)
    ComradeCraftDB.ui.hideGathering = self:GetChecked() and true or false
    ns.RefreshWindow()
  end)

  local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", DETAIL_X, -166)
  scroll:SetPoint("BOTTOMRIGHT", -34, 36)
  content = CreateFrame("Frame", nil, scroll)
  U.content = content
  content:SetSize(LIST_W, 1)
  scroll:SetScrollChild(content)
  f.scroll = scroll

  -- Manage view: add a player by name (Enter or the Add button).
  f.addBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
  f.addBox:SetSize(180, 20)
  f.addBox:SetAutoFocus(false)
  f.addBox:SetScript("OnEnterPressed", function(self)
    local name = self:GetText()
    if name and name ~= "" then
      ns.Sync.AddByName(name)
      self:SetText("")
    end
    self:ClearFocus()
  end)
  f.addBox:Hide()

  local footBtn = CreateFrame("Button", nil, f)
  footBtn:SetSize(640, 18)
  footBtn:SetPoint("BOTTOMLEFT", 20, 10)
  footBtn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  footBtn:SetScript("OnClick", function() if ns.commands.sync then ns.commands.sync() end end)
  footBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:AddLine(L["Click to sync now with your group."], 0.5, 0.8, 1)
    GameTooltip:Show()
  end)
  footBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  f.foot = footBtn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  f.foot:SetPoint("LEFT", 0, 0)
  local foot2 = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  foot2:SetPoint("BOTTOMRIGHT", -24, 14)
  foot2:SetText("/comrade")

  -- Bottom-right vertical resize grip (height persisted in ComradeCraftDB.ui.height).
  local grip = CreateFrame("Button", nil, f)
  grip:SetSize(16, 16)
  grip:SetPoint("BOTTOMRIGHT", -4, 4)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function() if f.StartSizing then f:StartSizing("BOTTOM") end end)
  grip:SetScript("OnMouseUp", function()
    if f.StopMovingOrSizing then f:StopMovingOrSizing() end
    if ComradeCraftDB and ComradeCraftDB.ui and f.GetHeight then
      ComradeCraftDB.ui.height = math.floor(f:GetHeight() + 0.5)
    end
  end)

  U.frame = f
  f:SetScript("OnShow", function()
    if f.SetScale and ns.UIScale then f:SetScale(ns.UIScale()) end
    ns.RefreshWindow()
  end)
  return f
end

function ns.ToggleWindow()
  ComradeCraftDB.ui = ComradeCraftDB.ui or {}
  frame = frame or CreateWindow()
  U.frame = frame
  frame:SetShown(not frame:IsShown())
  if frame:IsShown() then ns.StartTutorial() end
end

-- Only redraw on GET_ITEM_INFO_RECEIVED when an item WE actually needed just finished caching
-- (ignores background item loads from TSM, Auctionator, Questie, tooltips, etc. — zero lag loop!).
local pending = false
ns.On("GET_ITEM_INFO_RECEIVED", function(itemID, success)
  if not (success and itemID and missingItems[itemID]) then return end
  missingItems[itemID] = nil
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local resolved = get and get(itemID)
  if resolved and ns.RememberItemName then ns.RememberItemName(itemID, resolved) end
  if ns.Audit and ns.Audit.Invalidate then ns.Audit.Invalidate() end
  if pending then return end
  pending = true
  local function Redraw()
    pending = false
    if frame and frame:IsShown() then ns.RefreshWindow() end
    if ns.RefreshTracker then ns.RefreshTracker() end
    if ns.Wishlist and ns.Wishlist.RefreshTracker then ns.Wishlist.RefreshTracker() end
    if ns.RefreshFarm then ns.RefreshFarm() end
    if ns.Mail and ns.Mail.UpdatePanel then ns.Mail.UpdatePanel() end
    if ns.Bank and ns.Bank.UpdatePanel then ns.Bank.UpdatePanel() end
    if ns.Trade and ns.Trade.UpdatePanel then ns.Trade.UpdatePanel() end
    if ns.Merchant and ns.Merchant.UpdatePanel then ns.Merchant.UpdatePanel() end
  end
  if C_Timer and C_Timer.After then C_Timer.After(0.25, Redraw) else Redraw() end
end)

ns.commands.show = ns.ToggleWindow

-- Minimap tooltip: what this character needs now or soon, and what it can give.
function ns.MinimapSummary(tt)
  local key = ns.CharKey()
  local c = ComradeCraftDB and ComradeCraftDB.chars and ComradeCraftDB.chars[key]
  if not c then return end
  local urgent = {}
  for _, need in pairs(c.needs or {}) do
    for item, n in pairs(need.items or {}) do
      local step = need.when and need.when[item]
      if ns.UrgencyRank(step) <= 2 then urgent[#urgent + 1] = { item = item, n = n, step = step } end
    end
  end
  table.sort(urgent, function(a, b) return (a.step or 99) < (b.step or 99) or ((a.step == b.step) and a.n > b.n) end)
  if #urgent > 0 then
    tt:AddLine(" ")
    tt:AddLine(L["You need"], 1, 0.82, 0)
    for i = 1, math.min(#urgent, 5) do
      local u = urgent[i]
      tt:AddDoubleLine((ItemInfo(u.item)) or ("item:" .. u.item), ("x%d %s"):format(u.n, ns.UrgencyText(u.step)),
        1, 1, 1, 1, 1, 1)
    end
  end
  local give = ns.GiveList(key)
  if #give > 0 then
    tt:AddLine(" ")
    tt:AddLine(L["You can give"], 1, 0.82, 0)
    for i = 1, math.min(#give, 5) do
      local g = give[i]
      tt:AddDoubleLine(((ItemInfo(g.item)) or ("item:" .. g.item)) .. " x" .. g.n,
        "-> " .. (g.to:match("^[^-]+") or g.to) .. " " .. ns.UrgencyText(g.step), 1, 1, 1, 1, 1, 1)
    end
  end
end

-- Minimap button + LibDataBroker DataText (TitanPanel, Bazooka, ElvUI).
-- Position and hide flag saved in ComradeCraftDB.minimap.
local ldbObj
function ns.UpdateLDB()
  if not ldbObj then return end
  local open = ns.Requests and ns.Requests.OpenCount() or 0
  if open > 0 then
    ldbObj.text = "|cff40ff40" .. ns.Plural(open, "%d request", "%d requests") .. "|r"
    return
  end
  local ready = 0
  for _, e in ipairs(ns.Wishlist and ns.Wishlist.List() or {}) do
    if ns.Wishlist.Progress(e).bagReady then ready = ready + 1 end
  end
  if ready > 0 then
    ldbObj.text = "|cff40ff40" .. L["%d ready"]:format(ready) .. "|r"
  else
    ldbObj.text = "ComradeCraft"
  end
end

function ns.SetMinimapShown(on)
  ComradeCraftDB.minimap = ComradeCraftDB.minimap or {}
  ComradeCraftDB.minimap.hide = not on
  local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
  if Icon then
    if on then Icon:Show("ComradeCraft") else Icon:Hide("ComradeCraft") end
  end
end

ns.On("PLAYER_LOGIN", function()
  local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
  local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
  if not LDB then return end
  ldbObj = LDB:NewDataObject("ComradeCraft", {
    type = "data source",
    label = "ComradeCraft",
    text = "ComradeCraft",
    icon = ns.LOGO,
    OnClick = function(_, btn)
      if btn == "RightButton" and ns.OpenOptions then ns.OpenOptions()
      else ns.ToggleWindow() end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine("ComradeCraft")
      ns.MinimapSummary(tt)
      tt:AddLine(" ")
      tt:AddLine(L["Left-click: open window  |  Right-click: options"], 1, 1, 1)
    end,
  })
  ns.UpdateLDB()
  if Icon then
    ComradeCraftDB.minimap = ComradeCraftDB.minimap or {}
    Icon:Register("ComradeCraft", ldbObj, ComradeCraftDB.minimap)
  end
end)
