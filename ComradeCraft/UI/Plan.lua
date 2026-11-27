-- UI/Plan: character Plan tab (leveling steps, milestones, mats, next rank) and Can Craft tab.
local _, ns = ...
local L = ns.L
local U = ns.UI
local P = U.pools
local LIST_W, PROF_W, RIGHT_W, MAT_H, MAT_COLS, MAT_W, ROW_PAD, RECIPE_H =
  U.LIST_W, U.PROF_W, U.RIGHT_W, U.MAT_H, U.MAT_COLS, U.MAT_W, U.ROW_PAD, U.RECIPE_H
local COL_GROUP, COL_GROUP_W, COL_TYPE, COL_TYPE_W, COL_COST_W =
  U.COL_GROUP, U.COL_GROUP_W, U.COL_TYPE, U.COL_TYPE_W, U.COL_COST_W
local rows = P.rows
local Acquire, ItemInfo, SortedKeys, ShortName, LineVisible =
  U.Acquire, U.ItemInfo, U.SortedKeys, U.ShortName, U.LineVisible
local Collapsed, SetAllCollapsed, AllCollapsed, FoldTexture =
  U.Collapsed, U.SetAllCollapsed, U.AllCollapsed, U.FoldTexture
local Label, ShortMoney, PlaceStep, CreateRow, PlaceMat, PlaceRecipe =
  U.Label, U.ShortMoney, U.PlaceStep, U.CreateRow, U.PlaceMat, U.PlaceRecipe
local Toggle, Action, Head = U.Toggle, U.Action, U.Head

local function LayoutProfession(y, name, p, c, own, key)
  local r = Acquire(rows, CreateRow)
  r:ClearAllPoints()
  r:SetPoint("TOPLEFT", U.content, "TOPLEFT", 0, y)
  r:SetWidth(LIST_W)
  r.icon:SetTexture(p.icon or 134400)
  r.name:SetText(ns.ProfName and ns.ProfName(p.skillLine, name) or name)
  local need = p.skillLine and c.needs and c.needs[p.skillLine]
  local rank, maxRank = p.rank or 0, p.max or 0
  r.level:SetText(("%d / %d"):format(rank, maxRank))
  r.bar:SetMinMaxValues(0, math.max(1, maxRank))
  r.bar:SetValue(rank)
  if maxRank > 0 and rank >= maxRank then
    r.bar:SetStatusBarColor(0.24, 0.62, 0.22)
  else
    r.bar:SetStatusBarColor(0.10, 0.42, 0.78)
  end

  r.shop.key, r.shop.line = key, p.skillLine
  r.shop:SetShown(ns.CanShop() and need ~= nil and next(need.items or {}) ~= nil)

  -- Folding only makes sense with every profession listed ("All"); a filtered view is open.
  local filtered = ComradeCraftDB.ui.prof ~= nil
  local collapsed = not filtered and Collapsed(p.skillLine)
  r.icon:ClearAllPoints()
  r.icon:SetPoint("TOPLEFT", filtered and 6 or 20, -6)
  r.hit.line = p.skillLine
  r.hit:SetShown(not filtered)
  r.fold:SetShown(not filtered)
  r.fold:SetTexture(FoldTexture(collapsed))
  local d = ns.DescribeNeed(p, c)
  if collapsed then
    -- Folded: one summary line, nothing else.
    r.shop:Hide()
    local first = d.steps and d.steps[1]
    local last = first and first.entries[#first.entries]
    r.top:SetText("|cff9d9d9d" .. (d.status or (last and L["Next: %s"]:format(last.text))
      or L["Click to expand."]) .. "|r")
    r.mid:SetText("")
    r.bottom:SetText("")
    local h = math.max(48, 16 + (r.top:GetStringHeight() or 12))
    r:SetHeight(h)
    return h
  end
  local top = {}
  if d.status then top[#top + 1] = "|cff9d9d9d" .. d.status .. "|r" end
  if d.steps and #d.steps > 0 then top[#top + 1] = "|cffffd100" .. L["What to craft:"] .. "|r" end
  r.top:SetText(table.concat(top, "\n"))
  local yy = 8 + (#top > 0 and (r.top:GetStringHeight() + 4) or 0)

  for _, step in ipairs(d.steps or {}) do
    yy = yy + 4 + PlaceStep(PROF_W, y - yy - 2, RIGHT_W, { kind = "range", from = step.from, to = step.to, cost = step.cost }, own)
    for idx, e in ipairs(step.entries) do
      if e.kind == "craft" and e.item and e.item ~= 0 and ns.Synergies and ns.Synergies.DisenchantTarget then
        local deTo = ns.Synergies.DisenchantTarget(key, e.item)
        if deTo then
          local hint = "|cff80ff80" .. (deTo == key and L["Disenchant for your enchanting plan"]
            or L["Send to %s to disenchant"]:format(ShortName(deTo))) .. "|r"
          e = { kind = e.kind, spell = e.spell, item = e.item, n = e.n, label = e.label, text = e.text,
            detail = (e.detail and e.detail ~= "" and (e.detail .. "  -  ") or "") .. hint }
        end
      end
      yy = yy + PlaceStep(PROF_W + 4, y - yy, RIGHT_W - 4, e, own, idx % 2 == 0)
    end
  end

  local extra = {}
  if d.cost then extra[#extra + 1] = "|cffffd100" .. d.cost .. "|r" end
  if d.used then extra[#extra + 1] = "|cff80c080" .. d.used .. "|r" end
  if d.knownOnly then extra[#extra + 1] = "|cff9d9d9d" .. d.knownOnly .. "|r" end
  r.mid:ClearAllPoints()
  r.mid:SetPoint("TOPLEFT", r, "TOPLEFT", PROF_W, -(yy + 4))
  r.mid:SetText(table.concat(extra, "\n"))
  if #extra > 0 then yy = yy + 8 + r.mid:GetStringHeight() end
  yy = yy + 4

  -- Cost per milestone: collapsed behind a button by default so the plan stays easy to scan.
  local ms = ns.MilestoneRows(need)
  if ms then
    local ui = ComradeCraftDB.ui
    local showMs = ui.showMilestones and p.skillLine and ui.showMilestones[p.skillLine]
    local lineId = p.skillLine
    local mb = Action(PROF_W, y - yy - 2, showMs and L["Hide route comparison"] or L["Compare routes"], function()
      ui.showMilestones = ui.showMilestones or {}
      ui.showMilestones[lineId] = not ui.showMilestones[lineId] or nil
      ns.RefreshWindow()
    end)
    mb:SetWidth(155)
    yy = yy + 28
    if showMs then
      yy = yy + 2 + PlaceStep(PROF_W, y - yy, RIGHT_W, { kind = "range", from = 0, to = 0, header = ms.header }, own)
      yy = yy + PlaceStep(PROF_W, y - yy, RIGHT_W, { kind = "milestone", cols = { "|cff8f8f8f" .. L["Skill"] .. "|r",
        "|cff8f8f8f" .. L["Route"] .. "|r", "|cff8f8f8f" .. L["Mats"] .. "|r", "|cff8f8f8f" .. L["Sold back"] .. "|r",
        "|cff8f8f8f" .. L["Net cost"] .. "|r" } }, own)
      local mi = 0
      for _, row in ipairs(ms.rows) do
        for i, rt in ipairs(row.routes) do
          mi = mi + 1
          local name = L[rt.mode == "cheap" and "Cheapest" or "Profitable"]
          name = rt.active and ("|cffffd100" .. name .. "|r") or ("|cffb0b0b0" .. name .. "|r")
          local cols, tip = { i == 1 and ("%d-%d"):format(row.from, row.to) or "", name, "-", "-", "-" }, nil
          local m = rt.m
          if m then
            local net = rt.net
            cols[3] = ShortMoney(m.mats)
            cols[4] = m.best > 0 and ShortMoney(m.best) or ("|cff6f6f6f" .. L["nothing"] .. "|r")
            cols[5] = net < 0 and ("|cff40ff40+" .. ShortMoney(-net) .. "|r") or ShortMoney(net)
            local function Way(k)
              if k ~= "vendor" and m[k] == 0 and m[k .. "Missing"] then return L["unknown"] end
              return (m[k .. "Missing"] and ">" or "") .. ShortMoney(m[k])
            end
            tip = { { L["Mats"], ShortMoney(m.mats) }, { L["Sold to a merchant"], Way("vendor") },
              { L["Disenchanted"], Way("de") }, { L["At the auction house (-5%, deposit risk)"], Way("ah") },
              { L["Best way per item"], ShortMoney(m.best) }, { L["Net cost"], cols[5] } }
          end
          yy = yy + PlaceStep(PROF_W, y - yy, RIGHT_W, { kind = "milestone", cols = cols, tip = tip }, own, mi % 2 == 0)
        end
      end
      local _, nh = Label(PROF_W, y - yy - 2, "|cff7f7f7f" .. L["Net cost = mats minus the best resale of each item. A green + is a profit. Hover a line for the details."] .. "|r", "GameFontDisableSmall", RIGHT_W)
      yy = yy + nh + 8
    end
  end

  local items = need and SortedKeys(need.items) or {}
  for i, item in ipairs(items) do
    local col, line = (i - 1) % MAT_COLS, math.floor((i - 1) / MAT_COLS)
    local spare = ns.GroupSupply(item, key)
    PlaceMat(PROF_W + col * (MAT_W + 4), y - yy - line * (MAT_H + 4), item, need.items[item],
      L["Owned: %d / %d"]:format(need.have[item] or 0, need.gross[item] or 0)
        .. (spare > 0 and ("  |cff80ccff" .. L["group: %d"]:format(spare) .. "|r") or ""))
  end
  if #items > 0 then yy = yy + math.ceil(#items / MAT_COLS) * (MAT_H + 4) + 2 end

  local bottom = {}
  if d.vendor then bottom[#bottom + 1] = "|cffb0b0b0" .. d.vendor .. "|r" end
  if d.blocked then bottom[#bottom + 1] = "|cffff9933" .. d.blocked .. "|r" end
  r.bottom:ClearAllPoints()
  r.bottom:SetPoint("TOPLEFT", r, "TOPLEFT", PROF_W, -yy)
  r.bottom:SetText(table.concat(bottom, "\n"))
  if #bottom > 0 then yy = yy + r.bottom:GetStringHeight() + 4 end

  -- Next rank: the book (hover: vendors; click: waypoint) or where to learn it.
  if d.rank then
    yy = yy + 4 + PlaceStep(PROF_W, y - yy, RIGHT_W, { kind = "range", header = d.rank.title }, own)
    for _, e in ipairs(d.rank.entries) do yy = yy + PlaceStep(PROF_W + 4, y - yy, RIGHT_W - 4, e, own) end
    for _, n in ipairs(d.rank.notes) do
      local _, nh = Label(PROF_W + 4, y - yy - 2, "|cff9d9d9d" .. n .. "|r", nil, RIGHT_W - 4)
      yy = yy + nh + 6
    end
  end

  if own and p.skillLine and ComradeCraftDB and ComradeCraftDB.skippedLearn then
    local nSkip = 0
    for sp in pairs(ComradeCraftDB.skippedLearn) do
      if ns.Recipes[sp] and ns.Recipes[sp][1] == p.skillLine then nSkip = nSkip + 1 end
    end
    if nSkip > 0 then
      local line = p.skillLine
      local rb = Action(PROF_W, y - yy - 4, L["Reset skipped (%d)"]:format(nSkip), function()
        for sp in pairs(ComradeCraftDB.skippedLearn or {}) do
          if ns.Recipes[sp] and ns.Recipes[sp][1] == line then ComradeCraftDB.skippedLearn[sp] = nil end
        end
        ns.UpdateNeeds(ns.CharData())
        ns.RefreshWindow()
      end)
      rb:SetWidth(140)
      yy = yy + 28
    end
  end

  local h = math.max(r.shop:IsShown() and 76 or 48, yy + ROW_PAD)
  r:SetHeight(h)
  return h
end

function U.RenderPlan(key, c)
  local y = 0
  -- Route type of this character: cheapest (default) or profitable (products sold back).
  -- Only its owner can change it; everything else (tooltips, give list, mail) follows it.
  local mode = ns.RouteMode(c)
  Label(0, y - 5, L["Route:"], "GameFontNormal", 60)
  Toggle(60, y, L["Cheapest"], mode == "cheap", not c.peer, function() ns.SetRouteMode(key, "cheap") end)
  Toggle(174, y, L["Profitable"], mode == "profit", not c.peer, function() ns.SetRouteMode(key, "profit") end)
  local visibleLines = {}
  local plist = SortedKeys(c.professions or {})
  for _, pname in ipairs(plist) do
    local line = c.professions[pname].skillLine
    if LineVisible(line) and line then visibleLines[#visibleLines + 1] = line end
  end
  local canFoldAll = #visibleLines > 1 and not ComradeCraftDB.ui.prof
  local whyW = LIST_W - 296 - (canFoldAll and 106 or 0)
  local why = mode == "profit"
    and L["Picks recipes whose products sell back well. More crafts, so more mats: tooltips, the give list, mail and shopping all follow this route."]
    or L["Spends the least on mats."]
  if c.peer then why = why .. " " .. L["Chosen by its owner."] end
  local _, hh = Label(296, y - 5, "|cff9d9d9d" .. why .. "|r", nil, math.max(120, whyW))
  if canFoldAll then
    local folded = AllCollapsed(visibleLines)
    Action(LIST_W - 100, y, folded and L["Expand all"] or L["Collapse all"],
      function() SetAllCollapsed(visibleLines, not folded) end)
  end
  y = y - math.max(30, hh + 12)
  local own = key == ns.CharKey()
  if #plist == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No profession data. Open your profession windows."] .. "|r")
    return -y + h
  end
  local shown = 0
  for _, pname in ipairs(plist) do
    if LineVisible(c.professions[pname].skillLine) then
      shown = shown + 1
      y = y - LayoutProfession(y, pname, c.professions[pname], c, own, key)
    end
  end
  if shown == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No profession matches the filter."] .. "|r")
    return -y + h
  end
  return -y
end

function U.Matches(e, filter)
  if filter == "" then return true end
  local name = (e.name or ""):lower()
  local item = e.item ~= 0 and (ItemInfo(e.item) or ""):lower() or ""
  return name:find(filter, 1, true) or item:find(filter, 1, true)
end

-- Tags shown after a recipe: who needs its product, who it fits, its category.
function U.RecipeTags(e)
  local t = {}
  for _, n in ipairs(e.needers) do
    t[#t + 1] = ("|cff80ff80%s : %s|r"):format(ShortName(n.key), L["needs %d"]:format(n.n))
  end
  for _, u in ipairs(e.fits) do
    local rounded = u.gain and math.floor(u.gain + 0.5) or 0
    t[#t + 1] = "|cff66ccff" .. (rounded > 0 and L["upgrade for %s (+%d)"]:format(ShortName(u.key), rounded)
      or L["gear for %s"]:format(ShortName(u.key))) .. "|r"
  end
  -- Two lines fit in a row; the rest is summed up.
  if #t > 2 then t = { t[1], L["+%d more"]:format(#t - 1) } end
  return table.concat(t, "\n")
end
local Matches, RecipeTags = U.Matches, U.RecipeTags


function U.RenderCraft(key, c, filter)
  local y = 0
  local own = key == ns.CharKey()
  local byLine, nameOf = {}, {}
  for pname, p in pairs(c.professions or {}) do
    if p.skillLine then nameOf[p.skillLine] = ns.ProfName and ns.ProfName(p.skillLine, pname) or pname end
  end
  for _, e in ipairs(ns.CraftCatalog(key)) do
    if Matches(e, filter) and LineVisible(e.line) then
      byLine[e.line] = byLine[e.line] or {}
      table.insert(byLine[e.line], e)
    end
  end
  local lines = SortedKeys(byLine, function(a, b) return (nameOf[a] or "") < (nameOf[b] or "") end)
  if #lines == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No recipe matches."] .. "|r")
    return h
  end
  if #lines > 1 and not ComradeCraftDB.ui.prof then
    local folded = AllCollapsed(lines)
    Action(LIST_W - 100, y, folded and L["Expand all"] or L["Collapse all"],
      function() SetAllCollapsed(lines, not folded) end)
    y = y - 26
  end
  for _, line in ipairs(lines) do
    local list = byLine[line]
    y = y - Head(y, line, ("|cffffd100%s|r  |cff9d9d9d%s|r"):format(nameOf[line] or tostring(line),
      ns.Plural(#list, "%d recipe", "%d recipes")))
    if Collapsed(line) then list = {} end
    if #list > 0 then
      -- Column titles.
      Label(8 + 30, y, "|cff8f8f8f" .. L["Recipe and mats"] .. "|r", "GameFontDisableSmall", 200)
      Label(8 + COL_GROUP, y, "|cff8f8f8f" .. L["For the group"] .. "|r", "GameFontDisableSmall", COL_GROUP_W)
      Label(8 + COL_TYPE, y, "|cff8f8f8f" .. L["Type"] .. "|r", "GameFontDisableSmall", COL_TYPE_W)
      local ct = Label(LIST_W - 4 - COL_COST_W, y, "|cff8f8f8f" .. L["Mats cost"] .. "|r", "GameFontDisableSmall", COL_COST_W)
      ct:SetJustifyH("RIGHT")
      y = y - 16
    end
    for idx, e in ipairs(list) do
      PlaceRecipe(8, y, e, RecipeTags(e), L[e.category], own, idx % 2 == 0, key).requestTo = c.peer and key or nil
      y = y - RECIPE_H
    end
    y = y - 8
  end
  return -y
end

-- Shared bank alt view: searchable inventory of every item stored on this character (bags +
-- bank + mail), needed-by-you first, with 1-click Request buttons for remote bank alts.
function U.RenderBankAlt(key, c, filter)
  local y = 0
  local _, bh = Label(0, y, "|cff80ccff" .. L["Shared bank alt: all items on this character (bags, bank, mail) appear as available to your group, and members can request them via the addon."] .. "|r")
  y = y - bh - 10
  local stock = {}
  for _, src in ipairs({ c.bags or {}, c.bank or {}, c.mail or {} }) do
    for item, n in pairs(src) do
      if n > 0 and not (ns.IsBoP and ns.IsBoP(item)) then
        stock[item] = (stock[item] or 0) + n
      end
    end
  end
  local me = ns.CharData and ns.CharData()
  local list = {}
  for item, n in pairs(stock) do
    local name = ItemInfo(item) or ("item:" .. item)
    if filter == "" or name:lower():find(filter, 1, true) then
      local myNeed = me and ns.NeedOf and ns.NeedOf(me, item) or 0
      list[#list + 1] = { item = item, n = n, name = name, need = myNeed }
    end
  end
  if #list == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No items stored yet."] .. "|r")
    return -y + h
  end
  table.sort(list, function(a, b)
    if (a.need > 0) ~= (b.need > 0) then return a.need > 0 end
    if a.need ~= b.need then return a.need > b.need end
    if a.n ~= b.n then return a.n > b.n end
    return a.name < b.name
  end)
  local canReq = c.peer ~= nil and ns.Requests and ns.Requests.ShowItemDialog
  local cols = canReq and 2 or 3
  local w = math.floor((LIST_W - (cols - 1) * 4) / cols)
  local rowH = MAT_H + 4
  for i, it in ipairs(list) do
    local col, line = (i - 1) % cols, math.floor((i - 1) / cols)
    local x = col * (w + 4)
    local yy = y - line * rowH
    local sub = it.need > 0 and ("|cff40ff40" .. L["needs %d"]:format(it.need) .. "|r") or L["Shared bank alt"]
    local tileW = canReq and (w - 86) or w
    PlaceMat(x, yy, it.item, it.n, sub, tileW)
    if canReq then
      local itemId, want = it.item, it.need > 0 and math.min(it.n, it.need) or 1
      local br = Action(x + tileW + 4, yy - 9, L["Request"], function()
        ns.Requests.ShowItemDialog(key, itemId, want)
      end)
      br:SetWidth(80)
    end
  end
  return -y + math.ceil(#list / cols) * rowH + 4
end

-- Unlearned high-value patterns for this character (for yourself and your group):
-- shows who benefits, where to buy/farm (with drop rate when known & AH price if BoE), and 1-click Waypoint.
local PAT_H = 38
local function CreatePatternRow()
  local b = CreateFrame("Button", nil, U.content)
  b:SetHeight(PAT_H)
  b:SetWidth(LIST_W)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.selfBar = b:CreateTexture(nil, "ARTWORK")
  b.selfBar:SetWidth(2)
  b.selfBar:SetPoint("TOPLEFT", 0, 0)
  b.selfBar:SetPoint("BOTTOMLEFT", 0, 0)
  b.selfBar:SetColorTexture(0.35, 0.88, 0.55, 0.9)
  b.selfBar:Hide()
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(26, 26)
  b.icon:SetPoint("LEFT", 6, 0)
  b.line1 = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.line1:SetPoint("TOPLEFT", 38, -4)
  b.line1:SetPoint("RIGHT", -102, 0)
  b.line1:SetJustifyH("LEFT")
  b.line1:SetWordWrap(false)
  b.line2 = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.line2:SetPoint("TOPLEFT", 38, -20)
  b.line2:SetPoint("RIGHT", -102, 0)
  b.line2:SetJustifyH("LEFT")
  b.line2:SetWordWrap(false)
  b:SetScript("OnEnter", function(self)
    local p = self.pat
    if not p then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if p.item and p.item ~= 0 then GameTooltip:SetItemByID(p.item)
    elseif p.spell and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(p.spell) end
    if ns.AddSourceLines then ns.AddSourceLines(GameTooltip, p.spell) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    local p = self.pat
    if not p then return end
    if p.recipeItem and U.LinkOnShiftClick and U.LinkOnShiftClick(p.recipeItem) then return end
    if p.item and p.item ~= 0 and U.LinkOnShiftClick and U.LinkOnShiftClick(p.item) then return end
    if ns.WaypointRecipe then ns.WaypointRecipe(p.spell) end
  end)
  return b
end

function U.RenderPatterns(key, c, filter)
  local y = 0
  local _, ih = Label(0, y, "|cff9d9d9d" .. L["Valuable unlearned patterns for yourself and your group: where to buy or farm them, drop rate when known, and 1-click waypoints."] .. "|r")
  y = y - ih - 6
  local ui = ComradeCraftDB and ComradeCraftDB.ui or {}
  local groupMode = ui.patGroup or "all" -- "all" | "char" | "slot"
  Label(0, y - 5, L["Group by:"], "GameFontNormalSmall", 68)
  local function SetGroup(m)
    ComradeCraftDB.ui = ComradeCraftDB.ui or {}
    ComradeCraftDB.ui.patGroup = m
    ns.RefreshWindow()
  end
  Toggle(70, y, L["All"], groupMode == "all", true, function() SetGroup("all") end):SetWidth(72)
  Toggle(146, y, L["Character"], groupMode == "char", true, function() SetGroup("char") end):SetWidth(94)
  Toggle(244, y, L["Slot"], groupMode == "slot", true, function() SetGroup("slot") end):SetWidth(76)
  y = y - 28

  local list = ns.Audit and ns.Audit.PatternsForCrafter and ns.Audit.PatternsForCrafter(key) or {}
  local filtered = {}
  for _, p in ipairs(list) do
    if LineVisible(p.line) then
      local name = (p.item and p.item ~= 0 and (ItemInfo(p.item))) or ns.SpellName(p.spell)
      local whoPlain = {}
      for i = 1, math.min(3, #p.forList) do whoPlain[#whoPlain + 1] = ShortName(p.forList[i].key) end
      local haystack = (name .. " " .. (p.sourceText or "") .. " " .. table.concat(whoPlain, " ") .. " " .. (p.prof or "")):lower()
      if filter == "" or haystack:find(filter, 1, true) then
        filtered[#filtered + 1] = p
      end
    end
  end

  local shown = 0
  local function DrawPatternRow(p)
    shown = shown + 1
    local name = (p.item and p.item ~= 0 and (ItemInfo(p.item))) or ns.SpellName(p.spell)
    local whoParts = {}
    for i = 1, math.min(3, #p.forList) do
      local f = p.forList[i]
      local sn = ShortName(f.key)
      whoParts[#whoParts + 1] = f.isSelf and ("|cff66e89a" .. sn .. "|r") or ns.ClassColored(f.key, f.class)
    end
    local row = Acquire(P.patternRows, CreatePatternRow)
    row.pat = p
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", U.content, "TOPLEFT", 0, y)
    local even = (shown % 2 == 0)
    if p.helpsSelf then
      row.bg:SetColorTexture(0.09, 0.19, 0.13, even and 0.50 or 0.34)
      row.selfBar:Show()
    else
      row.bg:SetColorTexture(even and 0.12 or 0.07, even and 0.12 or 0.07, even and 0.16 or 0.09, even and 0.44 or 0.24)
      row.selfBar:Hide()
    end
    local ico = (p.item and p.item ~= 0 and select(3, ItemInfo(p.item)))
      or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(p.spell)) or 134400
    row.icon:SetTexture(ico)
    if U.ApplyQualityBorder then U.ApplyQualityBorder(row, row.icon, p.item) end
    local skillTag = p.canLearn and ("|cff40ff40" .. L["can learn now"] .. "|r")
      or ("|cffffd100" .. L["needs skill %d"]:format(p.req) .. "|r")
    local more = #p.forList > 3 and (" +" .. (#p.forList - 3)) or ""
    row.line1:SetText(("|cffffffff%s|r  |cff9d9d9d(%s - %s)|r  %s: %s%s"):format(
      name, p.prof, skillTag, L["For"], table.concat(whoParts, ", "), more))
    row.line2:SetText("|cffc8d8ff" .. (p.sourceText or "") .. "|r")
    local spell = p.spell
    local bw = Action(LIST_W - 94, y - 7, L["Waypoint"], function()
      if ns.WaypointRecipe then ns.WaypointRecipe(spell) end
    end)
    bw:SetWidth(88)
    if bw.SetFrameLevel and row.GetFrameLevel then bw:SetFrameLevel(row:GetFrameLevel() + 2) end
    y = y - PAT_H - 2
  end

  if groupMode == "char" then
    local byChar, order = {}, {}
    for _, p in ipairs(filtered) do
      local f = p.forList[1]
      if f then
        if not byChar[f.key] then
          byChar[f.key] = { key = f.key, class = f.class, isSelf = f.isSelf, level = f.level or 1, items = {} }
          order[#order + 1] = byChar[f.key]
        end
        byChar[f.key].items[#byChar[f.key].items + 1] = p
      end
    end
    table.sort(order, function(a, b)
      if a.isSelf ~= b.isSelf then return a.isSelf end
      if a.level ~= b.level then return a.level > b.level end
      return a.key < b.key
    end)
    for _, g in ipairs(order) do
      y = y - SectionBar(0, y, LIST_W, ns.ClassColored(g.key, g.class), L["Lvl %d"]:format(g.level)) - 4
      for _, p in ipairs(g.items) do DrawPatternRow(p) end
      y = y - 6
    end
  elseif groupMode == "slot" then
    local SLOT_CATS = {
      { "Weapon", L["Weapon"] }, { "Armor", L["Armor"] }, { "Enchants", L["Enchants"] },
      { "Bags", L["Bags"] }, { "Consumables", L["Consumables"] }, { "Other", L["Other"] },
    }
    local byCat = {}
    for _, p in ipairs(filtered) do
      local sg = p.slotGroup or "Other"
      byCat[sg] = byCat[sg] or {}
      byCat[sg][#byCat[sg] + 1] = p
    end
    for _, def in ipairs(SLOT_CATS) do
      local items = byCat[def[1]]
      if items and #items > 0 then
        y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. def[2] .. "|r", tostring(#items)) - 4
        for _, p in ipairs(items) do DrawPatternRow(p) end
        y = y - 6
      end
    end
  else
    for _, p in ipairs(filtered) do DrawPatternRow(p) end
  end

  if shown == 0 then
    local _, eh = Label(0, y, "|cff9d9d9d" .. L["No unlearned upgrade patterns found for this character right now."] .. "|r")
    y = y - eh
  end
  return -y + 4
end

