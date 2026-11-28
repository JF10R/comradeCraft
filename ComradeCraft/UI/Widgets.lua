-- UI/Widgets: shared layout constants, frame pools, and reusable Blizzard-styled widgets.
local _, ns = ...
local L = ns.L

local W, H = 940, 640
local SIDE_W = 200                -- character list column, scroll bar included
local SIDE_LIST_W = SIDE_W - 26   -- list width left of that scroll bar
local DETAIL_X = SIDE_W + 26      -- detail column left edge
local LIST_W = W - DETAIL_X - 40  -- detail U.content width
local PROF_W = 190
local RIGHT_W = LIST_W - PROF_W - 8
local MAT_H, MAT_COLS = 40, 2
local MAT_W = math.floor((RIGHT_W - 4) / MAT_COLS)
local ROW_PAD, STEP_H, RECIPE_H = 8, 18, 32
-- Can craft columns (x from the row's left): recipe + mats | for the group | type | cost.
local COL_GROUP, COL_GROUP_W, COL_TYPE, COL_TYPE_W, COL_COST_W = 360, 150, 518, 72, 80
local COLOR = { orange = "ff8040", yellow = "ffff00", green = "40c040", grey = "808080" }

local U = {
  W = W, H = H, SIDE_W = SIDE_W, SIDE_LIST_W = SIDE_LIST_W, DETAIL_X = DETAIL_X,
  LIST_W = LIST_W, PROF_W = PROF_W, RIGHT_W = RIGHT_W, MAT_H = MAT_H, MAT_COLS = MAT_COLS,
  MAT_W = MAT_W, ROW_PAD = ROW_PAD, STEP_H = STEP_H, RECIPE_H = RECIPE_H,
  COL_GROUP = COL_GROUP, COL_GROUP_W = COL_GROUP_W, COL_TYPE = COL_TYPE,
  COL_TYPE_W = COL_TYPE_W, COL_COST_W = COL_COST_W, COLOR = COLOR,
  missingItems = {}, suppressSearch = false,
  pools = { sideBtns = {}, rows = {}, mats = {}, steps = {}, recipes = {}, labels = {},
    actionBtns = {}, checks = {}, toggles = {}, heads = {}, planRows = {},
    groupRows = {}, sectionBars = {}, upgradeRows = {}, patternRows = {} },
}
ns.UI = U
local P = U.pools
local sideBtns, rows, mats, steps, recipes, labels, heads, groupRows, sectionBars, upgradeRows, patternRows =
  P.sideBtns, P.rows, P.mats, P.steps, P.recipes, P.labels, P.heads, P.groupRows, P.sectionBars, P.upgradeRows, P.patternRows
local actionBtns, checks, toggles = P.actionBtns, P.checks, P.toggles
local missingItems = U.missingItems

local function Acquire(pool, create)
  pool.n = (pool.n or 0) + 1
  local w = pool[pool.n]
  if not w then
    w = create()
    pool[pool.n] = w
  end
  w:Show()
  return w
end

local function ReleaseAll(pool)
  for i = 1, #pool do pool[i]:Hide() end
  pool.n = 0
end


function ns.NoteMissingItem(id)
  if id and id ~= 0 then missingItems[id] = true end
end

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link = get(id)
  if name then
    if ns.RememberItemName then ns.RememberItemName(id, name) end
  elseif id and id ~= 0 then
    if ns.RequestItemData then ns.RequestItemData(id) else missingItems[id] = true end
    name = ns.CachedItemName and ns.CachedItemName(id) or nil
  end
  local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
    or (GetItemIcon and GetItemIcon(id)) or 134400
  return name, link, icon
end

local function Ago(t)
  if not t then return "-" end
  local m = math.floor((time() - t) / 60)
  if m < 1 then return L["just now"] end
  if m < 60 then return L["%d min ago"]:format(m) end
  return L["%d h ago"]:format(math.floor(m / 60))
end

local function SortedKeys(t, less)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, less)
  return keys
end

local function ClassName(c)
  return c.class and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[c.class] or ""
end

local function ShortName(key) return key:match("^[^-]+") or key end

-- Profession filter (ui.prof = a skill line, nil = all) and "hide gathering" (default on).
local function LineVisible(line)
  local ui = ComradeCraftDB.ui
  if ui.hideGathering ~= false and line and ns.GATHERING[line] then return false end
  if ui.prof and ui.prof ~= line then return false end
  return true
end

-- "Lvl 20 Frost Mage" (spec when known).
local function LevelSpecClass(c)
  local parts = {}
  if c.level then parts[#parts + 1] = L["Lvl %d"]:format(c.level) end
  if c.spec then parts[#parts + 1] = c.spec end
  parts[#parts + 1] = ClassName(c)
  return table.concat(parts, " ")
end

local function LinkOnShiftClick(item)
  if IsModifiedClick and IsModifiedClick("CHATLINK") and item and item ~= 0 then
    local _, link = ItemInfo(item)
    if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
    return true
  end
end

local function ShowItemTooltip(owner, item, spell)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  if item and item ~= 0 then
    GameTooltip:SetItemByID(item)
  elseif spell and GameTooltip.SetSpellByID then
    GameTooltip:SetSpellByID(spell)
  end
  GameTooltip:Show()
end


-- Crisp 1px carved border helper (replaces flat yellowish fills with authentic dark-stone/bronze chrome).
local function AddBorder(f)
  local b = {}
  for _, side_ in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local t = f:CreateTexture(nil, "BORDER")
    if side_ == "TOP" or side_ == "BOTTOM" then
      t:SetHeight(1)
      t:SetPoint(side_ .. "LEFT", 0, 0)
      t:SetPoint(side_ .. "RIGHT", 0, 0)
    else
      t:SetWidth(1)
      t:SetPoint("TOP" .. side_, 0, 0)
      t:SetPoint("BOTTOM" .. side_, 0, 0)
    end
    b[side_] = t
  end
  f.border = b
end

local function SetBorderColor(f, r, g, bl, a)
  if not f.border then return end
  for _, t in pairs(f.border) do t:SetColorTexture(r, g, bl, a) end
end

local QUALITY_RGB = {
  [0] = { 0.62, 0.62, 0.62, 0.70 },
  [1] = { 0.55, 0.55, 0.58, 0.60 },
  [2] = { 0.12, 0.95, 0.12, 0.92 },
  [3] = { 0.10, 0.52, 1.00, 0.95 },
  [4] = { 0.68, 0.25, 0.95, 0.95 },
  [5] = { 1.00, 0.52, 0.05, 0.98 },
}

-- Draws/updates a crisp 1px item-rarity border around any icon texture (cached per icon).
local function ApplyQualityBorder(parent, icon, itemID)
  if not (parent and icon) then return end
  local q
  if itemID and itemID > 0 then
    if C_Item and C_Item.GetItemQualityByID then
      q = C_Item.GetItemQualityByID(itemID)
    end
    if not q then
      local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
      if get then q = select(3, get(itemID)) end
    end
  end
  local col = QUALITY_RGB[q] or { 0.36, 0.32, 0.24, 0.55 }
  local b = rawget(icon, "_qBorder")
  if type(b) ~= "table" then
    b = {}
    local top = parent:CreateTexture(nil, "OVERLAY")
    top:SetHeight(1)
    top:SetPoint("BOTTOMLEFT", icon, "TOPLEFT", -1, 0)
    top:SetPoint("BOTTOMRIGHT", icon, "TOPRIGHT", 1, 0)
    local bot = parent:CreateTexture(nil, "OVERLAY")
    bot:SetHeight(1)
    bot:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", -1, 0)
    bot:SetPoint("TOPRIGHT", icon, "BOTTOMRIGHT", 1, 0)
    local lft = parent:CreateTexture(nil, "OVERLAY")
    lft:SetWidth(1)
    lft:SetPoint("TOPRIGHT", icon, "TOPLEFT", 0, 1)
    lft:SetPoint("BOTTOMRIGHT", icon, "BOTTOMLEFT", 0, -1)
    local rgt = parent:CreateTexture(nil, "OVERLAY")
    rgt:SetWidth(1)
    rgt:SetPoint("TOPLEFT", icon, "TOPRIGHT", 0, 1)
    rgt:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 0, -1)
    b[1], b[2], b[3], b[4] = top, bot, lft, rgt
    icon._qBorder = b
  end
  for i = 1, 4 do b[i]:SetColorTexture(col[1], col[2], col[3], col[4]) end
end
U.ApplyQualityBorder = ApplyQualityBorder

local function CreateSectionBar()
  local f = CreateFrame("Frame", nil, U.content)
  f:SetHeight(24)
  f.bg = f:CreateTexture(nil, "BACKGROUND")
  f.bg:SetAllPoints()
  f.bg:SetColorTexture(0.11, 0.11, 0.14, 0.72)
  f.accent = f:CreateTexture(nil, "ARTWORK")
  f.accent:SetWidth(2)
  f.accent:SetPoint("TOPLEFT", 0, 0)
  f.accent:SetPoint("BOTTOMLEFT", 0, 0)
  f.accent:SetColorTexture(0.95, 0.78, 0.20, 0.9)
  f.line = f:CreateTexture(nil, "ARTWORK")
  f.line:SetHeight(1)
  f.line:SetPoint("BOTTOMLEFT", 0, 0)
  f.line:SetPoint("BOTTOMRIGHT", 0, 0)
  f.line:SetColorTexture(0.45, 0.38, 0.25, 0.45)
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("LEFT", 8, 0)
  f.title:SetJustifyH("LEFT")
  f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  f.sub:SetPoint("LEFT", f.title, "RIGHT", 10, 0)
  f.sub:SetPoint("RIGHT", -8, 0)
  f.sub:SetJustifyH("LEFT")
  f.sub:SetWordWrap(false)
  return f
end

local function SectionBar(x, y, w, title, sub)
  local f = Acquire(sectionBars, CreateSectionBar)
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", U.content, "TOPLEFT", x, y)
  f:SetWidth(w or (LIST_W - x))
  f.title:SetText(title)
  f.sub:SetText(sub or "")
  return 26
end

-- Collapsed professions (by skill line), shared by Plan and Can craft, kept across sessions.
local function Collapsed(line)
  local ui = ComradeCraftDB.ui
  return line and ui.collapsed and ui.collapsed[line] or false
end
local function ToggleCollapsed(line)
  if not line then return end
  local ui = ComradeCraftDB.ui
  ui.collapsed = ui.collapsed or {}
  ui.collapsed[line] = not ui.collapsed[line] or nil
  ns.RefreshWindow()
end
local function SetAllCollapsed(lines, collapse)
  local ui = ComradeCraftDB.ui
  ui.collapsed = ui.collapsed or {}
  for _, line in ipairs(lines) do ui.collapsed[line] = collapse or nil end
  ns.RefreshWindow()
end
local function AllCollapsed(lines)
  for _, line in ipairs(lines) do if not Collapsed(line) then return false end end
  return #lines > 0
end
local function FoldTexture(collapsed) return collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up" end

local function CreateLabel()
  local fs = U.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetJustifyH("LEFT")
  return fs
end

local function Label(x, y, text, font, width)
  local fs = Acquire(labels, CreateLabel)
  fs:SetFontObject(font or "GameFontHighlightSmall")
  fs:SetJustifyH("LEFT")
  fs:ClearAllPoints()
  fs:SetPoint("TOPLEFT", U.content, "TOPLEFT", x, y)
  fs:SetWidth(width or (LIST_W - x))
  fs:SetText(text)
  return fs, math.max(12, fs:GetStringHeight() or 12)
end

-- Money without copper once above 1 gold (tables stay readable).
local function ShortMoney(c)
  c = math.floor(c + 0.5)
  if math.abs(c) >= 10000 then c = math.floor(c / 100) * 100 end
  return ns.Money(c)
end

-- Milestone table columns (x inside the steps column): range, route, mats, resale, net.
local MS_COLS = { { 0, 64, "LEFT" }, { 66, 86, "LEFT" }, { 154, 92, "RIGHT" }, { 250, 110, "RIGHT" }, { 364, 92, "RIGHT" } }
-- Totals to the target: route | gross | to buy | resale | net.
U.TOTAL_COLS = { { 0, 104, "LEFT" }, { 106, 84, "RIGHT" }, { 192, 92, "RIGHT" }, { 286, 84, "RIGHT" }, { 372, 92, "RIGHT" } }

-- One line of the steps column: a range header ("87 - 107" + its cost), a learn/craft entry
-- (icon | count | name, mats in grey below), or a milestone table row (5 columns).
local function CreateStep()
  local b = CreateFrame("Button", nil, U.content)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.bg:Hide()
  b.accent = b:CreateTexture(nil, "ARTWORK")
  b.accent:SetWidth(2)
  b.accent:SetPoint("TOPLEFT", 0, 0)
  b.accent:SetPoint("BOTTOMLEFT", 0, 0)
  b.accent:SetColorTexture(0.95, 0.78, 0.20, 0.85)
  b.accent:Hide()
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(16, 16)
  b.icon:SetPoint("TOPLEFT", 0, -1)
  b.count = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.count:SetPoint("TOPLEFT", 18, -3)
  b.count:SetWidth(36)
  b.count:SetJustifyH("RIGHT")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetJustifyH("LEFT")
  b.detail = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.detail:SetJustifyH("LEFT")
  b.right = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.right:SetPoint("TOPRIGHT", -4, -4)
  b.right:SetJustifyH("RIGHT")
  b.line = b:CreateTexture(nil, "BACKGROUND")
  b.line:SetHeight(1)
  b.line:SetPoint("BOTTOMLEFT", 0, 1)
  b.line:SetPoint("BOTTOMRIGHT", 0, 1)
  b.line:SetColorTexture(1, 0.82, 0, 0.25)
  b.cols = {}
  for i, col in ipairs(MS_COLS) do
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", col[1], -2)
    fs:SetWidth(col[2])
    fs:SetJustifyH(col[3])
    fs:SetWordWrap(false)
    b.cols[i] = fs
  end
  b:SetScript("OnEnter", function(self)
    local e = self.entry
    if not e or e.kind == "range" then return end
    if e.tip then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      for _, l in ipairs(e.tip) do GameTooltip:AddDoubleLine(l[1], l[2], 0.8, 0.8, 0.8, 1, 1, 1) end
      GameTooltip:Show()
      return
    end
    if e.kind == "milestone" then return end
    if e.kind == "quest" or e.kind == "trainer" or e.kind == "station" then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(e.label, 1, 0.82, 0)
      if e.detail ~= "" then GameTooltip:AddLine(e.detail, 1, 1, 1, true) end
      GameTooltip:AddLine(e.kind ~= "quest" and L["Click: waypoint to the nearest one."]
        or L["Click: waypoint to the quest giver."], 0.5, 0.8, 1)
      GameTooltip:Show()
      return
    end
    ShowItemTooltip(self, e.item, e.spell)
    if e.kind == "learn" then
      ns.AddSourceLines(GameTooltip, e.spell)
      if self.own and e.spell and ns.Recipes[e.spell] then
        GameTooltip:AddLine(L["Right-click: skip this recipe and recalculate."], 0.8, 0.8, 0.8)
      end
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self, btn)
    local e = self.entry
    if not e or e.kind == "range" or e.kind == "milestone" or LinkOnShiftClick(e.item) then return end
    if btn == "RightButton" then
      if e.kind == "learn" and self.own and e.spell and ns.Recipes[e.spell] then
        ComradeCraftDB.skippedLearn = ComradeCraftDB.skippedLearn or {}
        ComradeCraftDB.skippedLearn[e.spell] = true
        ns.UpdateNeeds(ns.CharData())
        ns.RefreshWindow()
      end
      return
    end
    if e.kind == "craft" and self.own then ns.OpenRecipe(e.spell) end
    if e.kind == "learn" then
      if e.npc and ns.WaypointNpc then ns.WaypointNpc(e.npc, e.npcName or e.label, e.zone, e.fallbackPlace)
      else ns.WaypointRecipe(e.spell) end
    end
    if e.kind == "quest" then ns.WaypointQuest(e.quest) end
    if e.kind == "station" then ns.WaypointStation(e.focus) end
    if e.kind == "trainer" and ns.WaypointNpc then ns.WaypointNpc(e.npc, e.label, e.zone, e.fallbackPlace) end
  end)
  return b
end

-- Places one steps-column line at content (x, y), width w; returns its height.
local function PlaceStep(x, y, w, e, own, zebra)
  local s = Acquire(steps, CreateStep)
  s.entry, s.own = e, own
  s:SetAlpha(e.dim and 0.45 or 1) -- steps past the budget are greyed
  s:ClearAllPoints()
  s:SetPoint("TOPLEFT", U.content, "TOPLEFT", x, y)
  s:SetWidth(w)
  s.count:SetText("")
  s.detail:SetText("")
  s.right:SetText("")
  s.line:Hide()
  s.bg:Hide()
  s.accent:Hide()
  s.icon:Hide()
  for _, fs in ipairs(s.cols) do fs:SetText("") end
  s.text:SetText("")
  local h
  if e.kind == "range" then
    s.bg:SetColorTexture(0.11, 0.11, 0.14, 0.72)
    s.bg:Show()
    s.accent:Show()
    s.text:ClearAllPoints()
    s.text:SetPoint("TOPLEFT", 8, -4)
    s.text:SetWidth(e.net and 120 or (w - 118))
    s.text:SetText("|cffffd100" .. (e.header or L["Skill %d to %d"]:format(e.from, e.to)) .. "|r")
    if e.net then -- cost, what the crafts sell back, and the step's profit or loss
      local net = math.floor(e.net + 0.5)
      local sign = net >= 0 and "+" or "-"
      local netTxt = (net >= 0 and "|cff40ff40" or "|cffff6060") .. sign .. (e.costOk and "" or "<")
        .. ShortMoney(math.abs(net)) .. "|r"
      s.right:SetText(("|cff9d9d9d%s  ·  %s  ·|r  %s"):format(L["cost %s"]:format(e.cost or "?"),
        L["resale %s"]:format(ShortMoney(e.back)), netTxt))
    else
      s.right:SetText(e.cost or "")
    end
    s.line:Show()
    h = 22
  elseif e.kind == "milestone" then
    if zebra then s.bg:SetColorTexture(0.10, 0.10, 0.13, 0.35) s.bg:Show() end
    -- e.layout: other column positions (same count), e.g. U.TOTAL_COLS.
    for i, col in ipairs(e.layout or MS_COLS) do
      local fs = s.cols[i]
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", col[1], -2)
      fs:SetWidth(col[2])
      fs:SetJustifyH(col[3])
    end
    for i, v in ipairs(e.cols) do s.cols[i]:SetText(v) end
    h = 16
  else
    if zebra then s.bg:SetColorTexture(0.10, 0.10, 0.13, 0.32) s.bg:Show() end
    s.icon:Show()
    s.icon:SetTexture(e.kind == "quest" and "Interface\\GossipFrame\\AvailableQuestIcon"
      or e.kind == "trainer" and "Interface\\GossipFrame\\TrainerGossipIcon"
      or e.item and e.item ~= 0 and select(3, ItemInfo(e.item))
      or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(e.spell)) or 134400)
    s.count:SetText(e.n and (e.n .. "x") or "")
    s.text:ClearAllPoints()
    s.text:SetPoint("TOPLEFT", 58, -3)
    s.text:SetWidth(w - 62)
    s.text:SetText(e.kind == "learn" and ("|cff66ccff" .. (e.buy and L["Buy recipe: %s"] or L["Learn %s"]):format(e.label or "") .. "|r")
      or e.kind == "quest" and ("|cffffd100" .. L["Quest: %s"]:format(e.label or "") .. "|r")
      or (e.label or e.text))
    s.detail:ClearAllPoints()
    s.detail:SetPoint("TOPLEFT", s.text, "BOTTOMLEFT", 0, -1)
    s.detail:SetWidth(w - 62)
    s.detail:SetText(e.detail or "")
    h = 6 + (s.text:GetStringHeight() or 12) + ((e.detail or "") ~= "" and ((s.detail:GetStringHeight() or 12) + 1) or 0)
    h = math.max(STEP_H, h + 2)
  end
  s:SetHeight(h)
  return h
end

local function CreateRow()
  local r = CreateFrame("Frame", nil, U.content)
  -- Click the header (fold icon, icon, name) to collapse or expand the profession.
  r.hit = CreateFrame("Button", nil, r)
  r.hit:SetPoint("TOPLEFT", 0, 0)
  r.hit:SetSize(PROF_W - 8, 38)
  r.hit:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  r.hit:SetScript("OnClick", function(self) ToggleCollapsed(self.line) end)
  r.fold = r:CreateTexture(nil, "ARTWORK")
  r.fold:SetSize(14, 14)
  r.fold:SetPoint("TOPLEFT", 2, -12)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(32, 32)
  r.icon:SetPoint("TOPLEFT", 20, -6)
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1)
  r.name:SetPoint("RIGHT", r, "LEFT", PROF_W - 10, 0)
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(false)
  r.bar = CreateFrame("StatusBar", nil, r)
  r.bar:SetHeight(13)
  r.bar:SetPoint("TOPLEFT", r.icon, "BOTTOMRIGHT", 8, 13)
  r.bar:SetPoint("RIGHT", r, "LEFT", PROF_W - 10, 0)
  r.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  local barBorder = r.bar:CreateTexture(nil, "BACKGROUND", nil, -2)
  barBorder:SetPoint("TOPLEFT", -1, 1)
  barBorder:SetPoint("BOTTOMRIGHT", 1, -1)
  barBorder:SetColorTexture(0.35, 0.3, 0.2, 0.8)
  local barBg = r.bar:CreateTexture(nil, "BACKGROUND", nil, -1)
  barBg:SetAllPoints()
  barBg:SetColorTexture(0.05, 0.05, 0.05, 0.85)
  r.level = r.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.level:SetPoint("CENTER", 0, 0)
  for _, k in ipairs({ "top", "mid", "bottom" }) do
    r[k] = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r[k]:SetWidth(RIGHT_W)
    r[k]:SetJustifyH("LEFT")
  end
  r.top:SetPoint("TOPLEFT", r, "TOPLEFT", PROF_W, -8)
  -- Missing mats as an Auctionator list and/or TSM search text (shown only with one of them).
  r.shop = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  r.shop:SetSize(PROF_W - 20, 20)
  r.shop:SetPoint("TOPLEFT", r, "TOPLEFT", 6, -46)
  r.shop:SetText(L["Shopping list"])
  r.shop:SetScript("OnClick", function(self) ns.ShoppingAction(self.key, self.line) end)
  r.shop:Hide()
  -- Target skill: "Target:" + an editable box (Enter to apply, wheel +/-5) + a "Max" reset.
  r.tLabel = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  r.tLabel:SetText(L["Target:"])
  r.tBox = CreateFrame("EditBox", nil, r, "InputBoxTemplate")
  r.tBox:SetSize(40, 18)
  r.tBox:SetAutoFocus(false)
  r.tBox:SetNumeric(true)
  r.tBox:SetMaxLetters(3)
  r.tBox:SetJustifyH("CENTER")
  r.tBox:EnableMouseWheel(true)
  local function Apply(self, v)
    self:ClearFocus()
    if self.key and v then ns.SetTarget(self.key, self.line, v) end
  end
  r.tBox:SetScript("OnEnterPressed", function(self) Apply(self, tonumber(self:GetText())) end)
  r.tBox:SetScript("OnEscapePressed", function(self) self:SetText(tostring(self.value or "")) self:ClearFocus() end)
  r.tBox:SetScript("OnEditFocusLost", function(self) self:SetText(tostring(self.value or "")) end)
  r.tBox:SetScript("OnMouseWheel", function(self, delta)
    if self.value then Apply(self, self.value + delta * (IsShiftKeyDown and IsShiftKeyDown() and 25 or 5)) end
  end)
  r.tBox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Target skill"], 1, 0.82, 0)
    GameTooltip:AddLine(L["Type a skill (up to 300) and press Enter. Mouse wheel: +/-5 (Shift: 25)."], 1, 1, 1, true)
    GameTooltip:Show()
  end)
  r.tBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
  r.tHint = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  r.tHint:SetPoint("LEFT", r.tBox, "RIGHT", 6, 0)
  r.tMax = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  r.tMax:SetSize(56, 18)
  r.tMax:SetText(L["Cap"])
  r.tMax:SetScript("OnClick", function(self) if self.key then ns.SetTarget(self.key, self.line, nil) end end)
  r.tLabel:Hide() r.tBox:Hide() r.tHint:Hide() r.tMax:Hide()
  -- Budget (gold) for this character's routes: empty = no limit.
  r.bLabel = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  r.bLabel:SetText(L["Budget (g):"])
  r.bBox = CreateFrame("EditBox", nil, r, "InputBoxTemplate")
  r.bBox:SetSize(56, 18)
  r.bBox:SetAutoFocus(false)
  r.bBox:SetNumeric(true)
  r.bBox:SetMaxLetters(6)
  r.bBox:SetJustifyH("CENTER")
  r.bBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    if self.key then ns.SetBudget(self.key, tonumber(self:GetText())) end
  end)
  r.bBox:SetScript("OnEscapePressed", function(self) self:SetText(self.value or "") self:ClearFocus() end)
  r.bBox:SetScript("OnEditFocusLost", function(self) self:SetText(self.value or "") end)
  r.bBox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Budget"], 1, 0.82, 0)
    GameTooltip:AddLine(L["Gold you put into leveling, Enter to apply; empty = no limit. Sales of earlier crafts are reinvested."], 1, 1, 1, true)
    GameTooltip:Show()
  end)
  r.bBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
  r.bHint = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  r.bHint:SetPoint("LEFT", r.bBox, "RIGHT", 6, 0)
  r.bLabel:Hide() r.bBox:Hide() r.bHint:Hide()
  r.line = r:CreateTexture(nil, "BACKGROUND")
  r.line:SetHeight(1)
  r.line:SetPoint("BOTTOMLEFT", 4, 0)
  r.line:SetPoint("BOTTOMRIGHT", -4, 0)
  r.line:SetColorTexture(0.4, 0.33, 0.23, 0.4)
  return r
end

local function CreateMat()
  local b = CreateFrame("Button", nil, U.content)
  b:SetSize(MAT_W, MAT_H)
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(32, 32)
  b.icon:SetPoint("LEFT", 4, 0)
  b.count = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  b.count:SetPoint("RIGHT", -6, 0)
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 6, -2)
  b.name:SetPoint("RIGHT", b.count, "LEFT", -4, 0)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.own = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.own:SetPoint("BOTTOMLEFT", b.icon, "BOTTOMRIGHT", 6, 2)
  b.own:SetPoint("RIGHT", b.count, "LEFT", -4, 0)
  b.own:SetJustifyH("LEFT")
  b.own:SetWordWrap(false)
  b:SetScript("OnEnter", function(self)
    ShowItemTooltip(self, self.itemID)
    if self.verdictText then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("ComradeCraft", 1, 0.82, 0)
      GameTooltip:AddLine(self.verdictText, 1, 1, 1, true)
    end
    if self.reserveTo then
      GameTooltip:AddLine(L["Click: reserve for %s."]:format(ShortName(self.reserveTo)), 0.78, 0.55, 1)
    elseif self.bankReq then
      GameTooltip:AddLine(L["Click: request from %s [Bank]."]:format(ShortName(self.bankReq.key)), 0.5, 0.8, 1)
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  -- Shift-click links; otherwise performs contextual quick-action (Mail / Reserve / Bank Request).
  b:SetScript("OnClick", function(self)
    if LinkOnShiftClick(self.itemID) then return end
    if self.giveTo and ns.Mail.IsOpen() then
      ns.Mail.Prepare(self.giveTo)
    elseif self.reserveTo and ns.Reserve and ns.Reserve.Set then
      ns.Reserve.Set(self.itemID, self.reserveTo, 1)
    elseif self.bankReq and ns.Requests and ns.Requests.ShowItemDialog then
      ns.Requests.ShowItemDialog(self.bankReq.key, self.itemID, self.bankReq.want)
    end
  end)
  return b
end

local function PlaceMat(x, y, item, count, sub, width)
  local m = Acquire(mats, CreateMat)
  m.giveTo, m.verdictText, m.reserveTo, m.bankReq = nil, nil, nil, nil
  m:ClearAllPoints()
  m:SetPoint("TOPLEFT", U.content, "TOPLEFT", x, y)
  m:SetWidth(width or MAT_W)
  local name, _, icon = ItemInfo(item)
  m.itemID = item
  m.icon:SetTexture(icon)
  ApplyQualityBorder(m, m.icon, item)
  m.name:SetText(name or ("item:" .. item))
  m.own:SetText(sub or "")
  m.count:SetText("x" .. count)
  return m
end

-- One known recipe in the "can craft" lists. Line 1: icon, name in its difficulty color,
-- who it helps and its category. Line 2: reagents and the estimated cost of one craft.
-- Click opens it (own character only); shift-click links it in chat (any character).
local function CreateRecipe()
  local b = CreateFrame("Button", nil, U.content)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:SetHeight(RECIPE_H)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.bg:Hide()
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(24, 24)
  b.icon:SetPoint("TOPLEFT", 0, -2)
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("TOPLEFT", 30, -2)
  b.name:SetWidth(COL_GROUP - 38)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.mats = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.mats:SetPoint("TOPLEFT", 30, -16)
  b.mats:SetWidth(COL_GROUP - 38)
  b.mats:SetJustifyH("LEFT")
  b.mats:SetWordWrap(false)
  b.tags = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.tags:SetPoint("TOPLEFT", COL_GROUP, -2)
  b.tags:SetSize(COL_GROUP_W, RECIPE_H - 4)
  b.tags:SetJustifyH("LEFT")
  b.tags:SetJustifyV("TOP")
  b.kind = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.kind:SetPoint("TOPLEFT", COL_TYPE, -2)
  b.kind:SetWidth(COL_TYPE_W)
  b.kind:SetJustifyH("LEFT")
  b.kind:SetWordWrap(false)
  b.cost = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.cost:SetPoint("TOPRIGHT", -4, -2)
  b.cost:SetWidth(COL_COST_W)
  b.cost:SetJustifyH("RIGHT")
  b:SetScript("OnEnter", function(self)
    ShowItemTooltip(self, self.item, self.spell)
    -- The mats column is cut when long: the full list and cost go in the tooltip.
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Mats per craft:"], 1, 0.82, 0)
    GameTooltip:AddLine(ns.ReagentText(self.spell, 1), 1, 1, 1, true)
    if self.costText then GameTooltip:AddLine(self.costText, 1, 0.82, 0) end
    if self.requestTo then
      GameTooltip:AddLine(L["Click: ask %s to craft it."]:format(ShortName(self.requestTo)), 0.5, 0.8, 1)
    elseif self.own and ns.Wishlist then
      GameTooltip:AddLine(L["Right-click: add to Wishlist."], 0.5, 0.8, 1)
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self, btn)
    if IsModifiedClick and IsModifiedClick("CHATLINK") then
      local link = ns.RecipeLink(self.spell, self.item)
      if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
    elseif btn == "RightButton" then
      if self.own and ns.Wishlist then ns.Wishlist.ShowDialog(self.spell, self.crafterKey) end
    elseif self.own then
      ns.OpenRecipe(self.spell)
    elseif self.requestTo then
      ns.Requests.ShowDialog(self.requestTo, self.spell)
    end
  end)
  return b
end

local function PlaceRecipe(x, y, e, tags, kind, own, zebra, crafterKey)
  local b = Acquire(recipes, CreateRecipe)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", U.content, "TOPLEFT", x, y)
  b:SetWidth(LIST_W - x)
  b.spell, b.item, b.own, b.requestTo, b.crafterKey = e.spell, e.item, own, nil, crafterKey
  if zebra then b.bg:SetColorTexture(0.10, 0.10, 0.13, 0.34) b.bg:Show() else b.bg:Hide() end
  local icon = e.item ~= 0 and select(3, ItemInfo(e.item))
    or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(e.spell)) or 134400
  b.icon:SetTexture(icon)
  ApplyQualityBorder(b, b.icon, e.item)
  b.name:SetText(("|cff%s%s|r"):format(COLOR[e.color] or "ffffff", e.name or ns.SpellName(e.spell)))
  b.tags:SetText(tags or "")
  b.kind:SetText(kind or "")
  local cost = ns.CostText(ns.RecipeCost(e.spell, 1))
  b.costText = cost
  b.cost:SetText(cost and ("|cffffd100" .. cost .. "|r") or "|cff6f6f6f-|r")
  b.mats:SetText(ns.ReagentText(e.spell, 1))
  return b
end


-- Sculpted dark-stone two-state toggle: crisp bronze/gold border and gold underline when active.
local function CreateToggle()
  local b = CreateFrame("Button", nil, U.content)
  b:SetSize(110, 22)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  AddBorder(b)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.label:SetPoint("CENTER")
  b.under = b:CreateTexture(nil, "ARTWORK")
  b.under:SetHeight(2)
  b.under:SetPoint("BOTTOMLEFT", 1, 0)
  b.under:SetPoint("BOTTOMRIGHT", -1, 0)
  b.under:SetColorTexture(0.95, 0.78, 0.20, 1)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b:SetScript("OnClick", function(self) if self.fn and not self.active then self.fn() end end)
  return b
end

local function Toggle(x, y, text, active, enabled, fn)
  local b = Acquire(toggles, CreateToggle)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", U.content, "TOPLEFT", x, y)
  b:SetWidth(110) -- pooled: a caller may have widened it
  b.label:SetText(text)
  b.active, b.fn = active, enabled and fn or nil
  if active then
    b.bg:SetColorTexture(0.15, 0.15, 0.19, 0.96)
    SetBorderColor(b, 0.78, 0.64, 0.24, 0.9)
    b.label:SetTextColor(1, 0.85, 0.22)
  else
    b.bg:SetColorTexture(0.08, 0.08, 0.10, 0.9)
    SetBorderColor(b, 0.28, 0.25, 0.20, 0.65)
    b.label:SetTextColor(0.68, 0.68, 0.72)
  end
  b.under:SetShown(active)
  return b
end

local function CreateActionBtn()
  local b = CreateFrame("Button", nil, U.content, "UIPanelButtonTemplate")
  b:SetSize(96, 22)
  b:SetScript("OnClick", function(self) if self.fn then self.fn() end end)
  return b
end

local function Action(x, y, text, fn)
  local b = Acquire(actionBtns, CreateActionBtn)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", U.content, "TOPLEFT", x, y)
  b:SetWidth(96) -- pooled: a caller may have widened it
  b:SetText(text)
  b:SetEnabled(true)
  b.fn = fn
  return b
end

local function CreateCheck()
  local b = CreateFrame("CheckButton", nil, U.content, "UICheckButtonTemplate")
  b:SetSize(24, 24)
  b:SetScript("OnClick", function(self) if self.fn then self.fn(self:GetChecked() and true or false) end end)
  return b
end

local function Check(x, y, checked, fn)
  local b = Acquire(checks, CreateCheck)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", U.content, "TOPLEFT", x, y)
  b:SetChecked(checked and true or false)
  b.fn = fn
  return b
end


local function CreateHead()
  local b = CreateFrame("Button", nil, U.content)
  b:SetSize(LIST_W, 20)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.fold = b:CreateTexture(nil, "ARTWORK")
  b.fold:SetSize(14, 14)
  b.fold:SetPoint("LEFT", 0, 0)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.text:SetPoint("LEFT", 20, 0)
  b:SetScript("OnClick", function(self) ToggleCollapsed(self.line) end)
  return b
end

-- Profession title that folds its section; returns its height.
local function Head(y, line, text)
  local b = Acquire(heads, CreateHead)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", U.content, "TOPLEFT", 0, y)
  b.line = line
  b.fold:SetTexture(FoldTexture(Collapsed(line)))
  b.text:SetText(text)
  return 22
end


local function FormatDuration(sec)
  if sec <= 0 then return "|cff40ff40" .. L["Ready"] .. "|r" end
  local d = math.floor(sec / 86400)
  local h = math.floor((sec % 86400) / 3600)
  local m = math.floor((sec % 3600) / 60)
  if d > 0 then return ("|cffffd100%dd %dh|r"):format(d, h) end
  if h > 0 then return ("|cffffd100%dh %dm|r"):format(h, m) end
  return ("|cffffd100%dm|r"):format(math.max(1, m))
end


-- Name of the peer a remote character came from.
local function PeerName(c)
  local peer = c.peer and ComradeCraftDB.peers and ComradeCraftDB.peers[c.peer]
  return peer and peer.name
end


-- Section title bar + optional one-line explanation; returns the new y.
local function Section(y, title, help)
  y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. title .. "|r") - 4
  if help then
    local _, h2 = Label(4, y, "|cff9d9d9d" .. help .. "|r", nil, LIST_W - 8)
    y = y - h2 - 4
  end
  return y - 4
end



function U.ClearSearch()
  if U.frame and U.frame.search and (U.frame.search:GetText() or "") ~= "" then
    U.suppressSearch = true
    U.frame.search:SetText("")
    U.suppressSearch = false
  end
end

function U.ReleaseContentPools()
  ReleaseAll(rows) ReleaseAll(mats) ReleaseAll(steps) ReleaseAll(recipes) ReleaseAll(labels)
  ReleaseAll(actionBtns) ReleaseAll(checks) ReleaseAll(toggles) ReleaseAll(heads) ReleaseAll(P.planRows)
  ReleaseAll(groupRows) ReleaseAll(sectionBars) ReleaseAll(upgradeRows) ReleaseAll(patternRows)
end

U.Acquire, U.ReleaseAll = Acquire, ReleaseAll
U.ItemInfo, U.Ago, U.SortedKeys = ItemInfo, Ago, SortedKeys
U.ClassName, U.ShortName, U.LineVisible, U.LevelSpecClass = ClassName, ShortName, LineVisible, LevelSpecClass
U.LinkOnShiftClick, U.ShowItemTooltip = LinkOnShiftClick, ShowItemTooltip
U.AddBorder, U.SetBorderColor, U.SectionBar, U.Section = AddBorder, SetBorderColor, SectionBar, Section
U.Collapsed, U.ToggleCollapsed, U.SetAllCollapsed, U.AllCollapsed, U.FoldTexture =
  Collapsed, ToggleCollapsed, SetAllCollapsed, AllCollapsed, FoldTexture
U.Label, U.ShortMoney, U.PlaceStep, U.CreateRow, U.PlaceMat, U.PlaceRecipe =
  Label, ShortMoney, PlaceStep, CreateRow, PlaceMat, PlaceRecipe
U.Toggle, U.Action, U.Check, U.Head = Toggle, Action, Check, Head
U.FormatDuration, U.PeerName = FormatDuration, PeerName
