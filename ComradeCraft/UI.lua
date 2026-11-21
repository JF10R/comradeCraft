-- UI: list + detail window. Left: "Group" then each character. Right: the group overview,
-- or a character's Plan / Can craft tabs. Blizzard templates only.
local _, ns = ...
local L = ns.L

local W, H = 940, 640
local SIDE_W = 200                -- character list column, scroll bar included
local SIDE_LIST_W = SIDE_W - 26   -- list width left of that scroll bar
local DETAIL_X = SIDE_W + 26      -- detail column left edge
local LIST_W = W - DETAIL_X - 40  -- detail content width
local PROF_W = 190
local RIGHT_W = LIST_W - PROF_W - 8
local MAT_H, MAT_COLS = 40, 2
local MAT_W = math.floor((RIGHT_W - 4) / MAT_COLS)
local ROW_PAD, STEP_H, RECIPE_H = 8, 18, 32
-- Can craft columns (x from the row's left): recipe + mats | for the group | type | cost.
local COL_GROUP, COL_GROUP_W, COL_TYPE, COL_TYPE_W, COL_COST_W = 360, 150, 518, 72, 80
local COLOR = { orange = "ff8040", yellow = "ffff00", green = "40c040", grey = "808080" }

local frame, content, side

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

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link = get(id)
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

-- Pools ---------------------------------------------------------------------------------
local sideBtns, rows, mats, steps, recipes, labels, heads, groupRows, sectionBars = {}, {}, {}, {}, {}, {}, {}, {}, {}

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

local function CreateSectionBar()
  local f = CreateFrame("Frame", nil, content)
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
  f:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
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
  local fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetJustifyH("LEFT")
  return fs
end

local function Label(x, y, text, font, width)
  local fs = Acquire(labels, CreateLabel)
  fs:SetFontObject(font or "GameFontHighlightSmall")
  fs:SetJustifyH("LEFT")
  fs:ClearAllPoints()
  fs:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
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

-- One line of the steps column: a range header ("87 - 107" + its cost), a learn/craft entry
-- (icon | count | name, mats in grey below), or a milestone table row (5 columns).
local function CreateStep()
  local b = CreateFrame("Button", nil, content)
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
    if e.kind == "quest" then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(e.label, 1, 0.82, 0)
      if e.detail ~= "" then GameTooltip:AddLine(e.detail, 1, 1, 1, true) end
      GameTooltip:AddLine(L["Click: waypoint to the quest giver."], 0.5, 0.8, 1)
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
    if e.kind == "learn" then ns.WaypointRecipe(e.spell) end
    if e.kind == "quest" then ns.WaypointQuest(e.quest) end
  end)
  return b
end

-- Places one steps-column line at content (x, y), width w; returns its height.
local function PlaceStep(x, y, w, e, own, zebra)
  local s = Acquire(steps, CreateStep)
  s.entry, s.own = e, own
  s:ClearAllPoints()
  s:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
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
    s.text:SetWidth(w - 118)
    s.text:SetText("|cffffd100" .. (e.header or L["Skill %d to %d"]:format(e.from, e.to)) .. "|r")
    s.right:SetText(e.cost or "")
    s.line:Show()
    h = 22
  elseif e.kind == "milestone" then
    if zebra then s.bg:SetColorTexture(0.10, 0.10, 0.13, 0.35) s.bg:Show() end
    for i, v in ipairs(e.cols) do s.cols[i]:SetText(v) end
    h = 16
  else
    if zebra then s.bg:SetColorTexture(0.10, 0.10, 0.13, 0.32) s.bg:Show() end
    s.icon:Show()
    s.icon:SetTexture(e.kind == "quest" and "Interface\\GossipFrame\\AvailableQuestIcon"
      or e.item and e.item ~= 0 and select(3, ItemInfo(e.item))
      or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(e.spell)) or 134400)
    s.count:SetText(e.n and (e.n .. "x") or "")
    s.text:ClearAllPoints()
    s.text:SetPoint("TOPLEFT", 58, -3)
    s.text:SetWidth(w - 62)
    s.text:SetText(e.kind == "learn" and ("|cff66ccff" .. L["Learn %s"]:format(e.label or "") .. "|r")
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
  local r = CreateFrame("Frame", nil, content)
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
  r.line = r:CreateTexture(nil, "BACKGROUND")
  r.line:SetHeight(1)
  r.line:SetPoint("BOTTOMLEFT", 4, 0)
  r.line:SetPoint("BOTTOMRIGHT", -4, 0)
  r.line:SetColorTexture(0.4, 0.33, 0.23, 0.4)
  return r
end

local function CreateMat()
  local b = CreateFrame("Button", nil, content)
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
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  -- Shift-click links; on a "you can give" entry with the mailbox open, prepares the mail.
  b:SetScript("OnClick", function(self)
    if not LinkOnShiftClick(self.itemID) and self.giveTo and ns.Mail.IsOpen() then ns.Mail.Prepare(self.giveTo) end
  end)
  return b
end

local function PlaceMat(x, y, item, count, sub, width)
  local m = Acquire(mats, CreateMat)
  m.giveTo, m.verdictText = nil, nil
  m:ClearAllPoints()
  m:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
  m:SetWidth(width or MAT_W)
  local name, _, icon = ItemInfo(item)
  m.itemID = item
  m.icon:SetTexture(icon)
  m.name:SetText(name or ("item:" .. item))
  m.own:SetText(sub or "")
  m.count:SetText("x" .. count)
  return m
end

-- One known recipe in the "can craft" lists. Line 1: icon, name in its difficulty color,
-- who it helps and its category. Line 2: reagents and the estimated cost of one craft.
-- Click opens it (own character only); shift-click links it in chat (any character).
local function CreateRecipe()
  local b = CreateFrame("Button", nil, content)
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
  b:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
  b:SetWidth(LIST_W - x)
  b.spell, b.item, b.own, b.requestTo, b.crafterKey = e.spell, e.item, own, nil, crafterKey
  if zebra then b.bg:SetColorTexture(0.10, 0.10, 0.13, 0.34) b.bg:Show() else b.bg:Hide() end
  local icon = e.item ~= 0 and select(3, ItemInfo(e.item))
    or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(e.spell)) or 134400
  b.icon:SetTexture(icon)
  b.name:SetText(("|cff%s%s|r"):format(COLOR[e.color] or "ffffff", e.name or ns.SpellName(e.spell)))
  b.tags:SetText(tags or "")
  b.kind:SetText(kind or "")
  local cost = ns.CostText(ns.RecipeCost(e.spell, 1))
  b.costText = cost
  b.cost:SetText(cost and ("|cffffd100" .. cost .. "|r") or "|cff6f6f6f-|r")
  b.mats:SetText(ns.ReagentText(e.spell, 1))
  return b
end

-- Views ---------------------------------------------------------------------------------

-- Plan tab: one block per profession (status, clickable plan, cost, mats, vendor, blocked).
local actionBtns, checks, toggles = {}, {}, {}

-- Sculpted dark-stone two-state toggle: crisp bronze/gold border and gold underline when active.
local function CreateToggle()
  local b = CreateFrame("Button", nil, content)
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
  b:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
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
  local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  b:SetSize(96, 22)
  b:SetScript("OnClick", function(self) if self.fn then self.fn() end end)
  return b
end

local function Action(x, y, text, fn)
  local b = Acquire(actionBtns, CreateActionBtn)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
  b:SetWidth(96) -- pooled: a caller may have widened it
  b:SetText(text)
  b:SetEnabled(true)
  b.fn = fn
  return b
end

local function CreateCheck()
  local b = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
  b:SetSize(24, 24)
  b:SetScript("OnClick", function(self) if self.fn then self.fn(self:GetChecked() and true or false) end end)
  return b
end

local function Check(x, y, checked, fn)
  local b = Acquire(checks, CreateCheck)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
  b:SetChecked(checked and true or false)
  b.fn = fn
  return b
end

local function LayoutProfession(y, name, p, c, own, key)
  local r = Acquire(rows, CreateRow)
  r:ClearAllPoints()
  r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
  r:SetWidth(LIST_W)
  r.icon:SetTexture(p.icon or 134400)
  r.name:SetText(name)
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

local function RenderPlan(key, c)
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

local function Matches(e, filter)
  if filter == "" then return true end
  local name = (e.name or ""):lower()
  local item = e.item ~= 0 and (ItemInfo(e.item) or ""):lower() or ""
  return name:find(filter, 1, true) or item:find(filter, 1, true)
end

-- Tags shown after a recipe: who needs its product, who it fits, its category.
local function RecipeTags(e)
  local t = {}
  for _, n in ipairs(e.needers) do
    t[#t + 1] = ("|cff80ff80%s : %s|r"):format(ShortName(n.key), L["needs %d"]:format(n.n))
  end
  for _, u in ipairs(e.fits) do
    t[#t + 1] = "|cff66ccff" .. (u.gain and L["upgrade for %s (+%d)"]:format(ShortName(u.key), math.floor(u.gain + 0.5))
      or L["gear for %s"]:format(ShortName(u.key))) .. "|r"
  end
  -- Two lines fit in a row; the rest is summed up.
  if #t > 2 then t = { t[1], L["+%d more"]:format(#t - 1) } end
  return table.concat(t, "\n")
end

-- Can craft tab: known recipes by profession; helps-the-group and fits-someone first.
local function CreateHead()
  local b = CreateFrame("Button", nil, content)
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
  b:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
  b.line = line
  b.fold:SetTexture(FoldTexture(Collapsed(line)))
  b.text:SetText(text)
  return 22
end

local function RenderCraft(key, c, filter)
  local y = 0
  local own = key == ns.CharKey()
  local byLine, nameOf = {}, {}
  for pname, p in pairs(c.professions or {}) do
    if p.skillLine then nameOf[p.skillLine] = pname end
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

local function FormatDuration(sec)
  if sec <= 0 then return "|cff40ff40" .. L["Ready"] .. "|r" end
  local d = math.floor(sec / 86400)
  local h = math.floor((sec % 86400) / 3600)
  local m = math.floor((sec % 3600) / 60)
  if d > 0 then return ("|cffffd100%dd %dh|r"):format(d, h) end
  if h > 0 then return ("|cffffd100%dh %dm|r"):format(h, m) end
  return ("|cffffd100%dm|r"):format(math.max(1, m))
end

-- Group view: sub-tabs (Overview | Materials | Disenchant) to avoid information overload,
-- or instant "who can craft" search results when typing in the search box.
local function RenderGroup(filter)
  local chars = ns.AllChars()
  local keys = SortedKeys(chars)
  local y = 0
  if filter ~= "" then
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Who can craft \"%s\""]:format(filter) .. "|r") - 6
    local found, any = {}, false
    for _, key in ipairs(keys) do
      for _, e in ipairs(ns.CraftCatalog(key)) do
        if Matches(e, filter) and LineVisible(e.line) then
          local f = found[e.spell]
          if not f then
            f = { e = e, who = {} }
            found[e.spell] = f
          end
          f.who[#f.who + 1] = ("|cff%s%s|r"):format(COLOR[e.color] or "ffffff", ShortName(key))
        end
      end
    end
    local list = {}
    for _, f in pairs(found) do list[#list + 1] = f end
    table.sort(list, function(a, b) return a.e.name < b.e.name end)
    for idx, f in ipairs(list) do
      any = true
      local e = { spell = f.e.spell, item = f.e.item, color = "yellow", name = f.e.name }
      PlaceRecipe(8, y, e, table.concat(f.who, ", "), nil, false, idx % 2 == 0).name:SetText(f.e.name)
      y = y - RECIPE_H
    end
    if not any then
      local _, h2 = Label(0, y, "|cff9d9d9d" .. L["No recipe matches."] .. "|r")
      y = y - h2
    end
    return -y
  end

  local subTab = ComradeCraftDB.ui.groupTab or "overview"

  if subTab == "mats" then
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Most wanted materials"] .. "|r") - 6
    local mats_ = ns.GroupMaterials(LineVisible)
    if #mats_ == 0 then
      local _, h4 = Label(0, y, "|cff9d9d9d" .. L["Nothing missing yet."] .. "|r")
      return -y + h4
    end
    local width = math.floor((LIST_W - 8) / 3)
    for i = 1, math.min(#mats_, 42) do
      local a = mats_[i]
      local by = {}
      for _, b in ipairs(a.by) do
        by[#by + 1] = ("%s %d %s"):format(ShortName(b.key), b.n, ns.UrgencyText(b.step))
      end
      local spare = ns.GroupSupply(a.item)
      if spare > 0 then by[#by + 1] = "|cff80ccff" .. L["group: %d"]:format(spare) .. "|r" end
      local col, line = (i - 1) % 3, math.floor((i - 1) / 3)
      PlaceMat(col * (width + 4), y - line * (MAT_H + 4), a.item, a.total, table.concat(by, ", "), width)
    end
    y = y - math.ceil(math.min(#mats_, 42) / 3) * (MAT_H + 4)
    return -y
  end

  if subTab == "de" then
    local advice = ns.BagAdvice(ns.CharKey())
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Disenchant or keep?"] .. "|r",
      L["Green and better items in your bags. Yields are estimates until your disenchants are logged."]) - 6
    if #advice == 0 then
      local _, h4 = Label(0, y, "|cff9d9d9d" .. L["No disenchantable items in your bags."] .. "|r")
      return -y + h4
    end
    local width = math.floor((LIST_W - 8) / 2)
    local myBags = (ComradeCraftDB.chars[ns.CharKey()] or {}).bags or {}
    local shown = math.min(#advice, 24)
    for i = 1, shown do
      local a = advice[i]
      local text
      if a.verdict == "target" then
        text = "|cff66ccff" .. L["Keep: enchanting target (%s)"]:format(ns.SpellName(a.spell)) .. "|r"
      elseif a.verdict == "gear" then
        text = "|cff66ccff" .. L["Keep: gear for %s"]:format(ShortName(a.to)) .. "|r"
      elseif a.verdict == "sell" then
        text = "|cffffd100" .. L["Sell: AH %s vs disenchant %s"]:format(ns.Money(math.floor(a.ah)), ns.Money(math.floor(a.de))) .. "|r"
      else
        local parts = {}
        for mat, n in pairs(a.yield) do
          parts[#parts + 1] = { n = n, text = ("%.1f %s"):format(n, (ItemInfo(mat)) or ("item:" .. mat)) }
        end
        table.sort(parts, function(p, q) return p.n > q.n end)
        local list = {}
        for _, p in ipairs(parts) do list[#list + 1] = p.text end
        text = L["Disenchant: %s"]:format(table.concat(list, ", "))
        if a.useful then text = text .. "  |cff80ff80" .. L["the group needs these"] .. "|r" end
        if a.enchanter then text = text .. "  |cff66ccff" .. L["give to %s"]:format(ShortName(a.enchanter)) .. "|r" end
      end
      local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
      PlaceMat(col * (width + 4), y - line * (MAT_H + 4), a.item, myBags[a.item] or 1, text, width).verdictText = text
    end
    y = y - math.ceil(shown / 2) * (MAT_H + 4)
    return -y
  end

  if subTab == "upgrades" then
    local groups = ns.Audit and ns.Audit.Run() or {}
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Group upgrades"] .. "|r",
      L["Small bags, unenchanted gear and craftable upgrades your group can make."]) - 6
    if #groups == 0 then
      local _, h4 = Label(0, y, "|cff9d9d9d" .. L["Everyone's bags, enchants and gear are up to date."] .. "|r")
      return -y + h4
    end
    for _, grp in ipairs(groups) do
      local _, ch = Label(0, y - 2, ns.ClassColored(grp.targetKey, grp.targetClass), "GameFontNormal")
      y = y - ch - 4
      for _, u in ipairs(grp.items) do
        local byTxt = ("|cff9d9d9d%s|r"):format(L["by %s"]:format(ShortName(u.crafter)))
        local _, uh = Label(12, y - 3, u.summary .. "  " .. byTxt, "GameFontHighlightSmall", LIST_W - 120)
        local spell, crafter, qty, targetShort, own = u.spell, u.crafter, u.qty or 1, ShortName(grp.targetKey), u.ownCrafter
        if own and ns.Wishlist then
          local bp = Action(LIST_W - 96, y, L["Pin"], function()
            ns.Wishlist.Add(spell, qty, targetShort, nil, true, crafter)
          end)
          bp:SetWidth(90)
        elseif not own and ns.Requests then
          local ba = Action(LIST_W - 96, y, L["Ask"], function()
            ns.Requests.ShowDialog(crafter, spell)
          end)
          ba:SetWidth(90)
        end
        y = y - math.max(26, uh + 8)
      end
      y = y - 6
    end
    return -y
  end

  -- Overview sub-tab: Synergies (when any), "You can give", clickable "Skill levels", and "Group cooldowns".
  local syns = ns.Synergies and ns.Synergies.Find() or {}
  if #syns > 0 then
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Group synergies"] .. "|r",
      L["Cross-profession links between your group's active plans."]) - 6
    for i = 1, math.min(#syns, 4) do
      local s = syns[i]
      local _, sh = Label(8, y - 2, "|cff80ff80>|r " .. s.detail, "GameFontHighlightSmall", LIST_W - 16)
      y = y - sh - 5
    end
    y = y - 6
  end

  local give = ns.GiveList(ns.CharKey())
  if #give > 0 then
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["You can give"] .. "|r",
      L["Spare items in your bags that others need. With a mailbox open, click one to prepare the mail."]) - 6
    local width = math.floor((LIST_W - 8) / 3)
    local shown = math.min(#give, 12)
    for i = 1, shown do
      local g = give[i]
      local col, line = (i - 1) % 3, math.floor((i - 1) / 3)
      PlaceMat(col * (width + 4), y - line * (MAT_H + 4), g.item, g.n,
        ("-> %s %s"):format(ns.ClassColored(g.to, chars[g.to] and chars[g.to].class), ns.UrgencyText(g.step)), width)
        .giveTo = g.to
    end
    y = y - math.ceil(shown / 3) * (MAT_H + 4) - 10
  end

  -- Skill table: one clickable line per character (click opens that character's sheet).
  y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Skill levels"] .. "|r") - 6
  local ri = 0
  for _, key in ipairs(keys) do
    local c = chars[key]
    local parts = {}
    for _, pname in ipairs(SortedKeys(c.professions or {})) do
      local p = c.professions[pname]
      if LineVisible(p.skillLine) then parts[#parts + 1] = ("%s %d/%d"):format(pname, p.rank or 0, p.max or 0) end
    end
    if #parts > 0 or not ComradeCraftDB.ui.prof then
      ri = ri + 1
      local gr = Acquire(groupRows, function()
        local b = CreateFrame("Button", nil, content)
        b:SetWidth(LIST_W)
        b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.bg:Hide()
        b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        b.name:SetPoint("TOPLEFT", 6, -3)
        b.name:SetWidth(170)
        b.name:SetJustifyH("LEFT")
        b.profs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.profs:SetPoint("TOPLEFT", 182, -4)
        b.profs:SetWidth(LIST_W - 188)
        b.profs:SetJustifyH("LEFT")
        b:SetScript("OnClick", function(self)
          if self.key then
            ComradeCraftDB.ui.sel = self.key
            ns.RefreshWindow()
          end
        end)
        return b
      end)
      gr.key = key
      gr:ClearAllPoints()
      gr:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
      if ri % 2 == 0 then gr.bg:SetColorTexture(0.10, 0.10, 0.13, 0.34) gr.bg:Show() else gr.bg:Hide() end
      gr.name:SetText(ns.ClassColored(key, c.class) .. (c.spec and ("  |cff9d9d9d" .. c.spec .. "|r") or ""))
      gr.profs:SetText(table.concat(parts, "   "))
      local rh = math.max(22, (gr.profs:GetStringHeight() or 12) + 8)
      gr:SetHeight(rh)
      y = y - rh - 1
    end
  end

  -- Group profession cooldowns (when any character has recorded long cooldowns).
  local now = (GetServerTime and GetServerTime()) or time()
  local cds = {}
  for _, key in ipairs(keys) do
    local c = chars[key]
    for spell, readyAt in pairs(c.cooldowns or {}) do
      cds[#cds + 1] = { key = key, class = c.class, spell = spell, left = readyAt - now }
    end
  end
  if #cds > 0 then
    table.sort(cds, function(a, b) return a.left < b.left end)
    y = y - 10
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Group cooldowns"] .. "|r") - 6
    for _, cd in ipairs(cds) do
      Label(6, y - 2, ns.ClassColored(cd.key, cd.class), "GameFontHighlightSmall", 140)
      Label(150, y - 2, ns.SpellName(cd.spell), "GameFontHighlightSmall", LIST_W - 260)
      local st = Label(LIST_W - 100, y - 2, FormatDuration(cd.left), "GameFontHighlightSmall", 94)
      st:SetJustifyH("RIGHT")
      y = y - 18
    end
  end
  return -y
end

-- Wishlist view: local + synced group pinned crafts, material progress, who they're for, and quick actions.
local function RenderWishlist()
  local Wl = ns.Wishlist
  local y = 0
  local list = Wl and Wl.List(nil, true) or {}
  if #list == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No craft pinned yet. Right-click any recipe in your Can craft tab to add it here, track its materials and get notified when ready."] .. "|r")
    return -y + h
  end
  local me = ns.CharKey()
  local chars = ns.AllChars()
  for _, e in ipairs(list) do
    local prog = Wl.Progress(e, chars[e.char])
    local label = e.item ~= 0 and (ItemInfo(e.item) or ("item:" .. e.item)) or ns.SpellName(e.spell)
    local who = e.forWho and ("  |cff80ccff" .. L["For %s"]:format(e.forWho) .. "|r") or ""
    local status = prog.bagReady and ("  |cff40ff40" .. L["Ready to craft!"] .. "|r")
      or (prog.ready and ("  |cffffd100" .. L["Ready (some mats in bank/mail)"] .. "|r") or "")
    local sub = e.remote and (L["via %s"]:format(ShortName(e.char)) .. (e.note and (" - " .. e.note) or ""))
      or (e.note or ShortName(e.char))
    y = y - SectionBar(0, y, LIST_W, ("|cffffd100%dx %s|r%s%s"):format(e.qty, label, who, status), sub) - 6
    local parts = {}
    for _, m in ipairs(prog.mats) do
      local col = m.missing == 0 and "40ff40" or "ffd100"
      parts[#parts + 1] = ("%s |cff%s%d/%d|r"):format((ItemInfo(m.item)) or ("item:" .. m.item), col, m.have, m.need)
    end
    local _, mh = Label(8, y - 2, table.concat(parts, "   "), "GameFontHighlightSmall", LIST_W - (e.remote and 20 or 290))
    if not e.remote then
      local id, spell, own = e.id, e.spell, e.char == me
      local bx = LIST_W - 86
      local bd = Action(bx, y, L["Done"], function() Wl.Remove(id) end)
      bd:SetWidth(82)
      bx = bx - 88
      local bp = Action(bx, y, e.pinned and L["Unpin"] or L["Pin"], function() Wl.SetPinned(id, not e.pinned) end)
      bp:SetWidth(82)
      if own then
        bx = bx - 88
        local bc = Action(bx, y, L["Craft"], function() ns.OpenRecipe(spell) end)
        bc:SetWidth(82)
      end
    end
    y = y - math.max(28, mh + 10) - 6
  end
  return -y
end

-- Sidebar ---------------------------------------------------------------------------------

local suppressSearch = false
local function ClearSearch()
  if frame and frame.search and (frame.search:GetText() or "") ~= "" then
    suppressSearch = true
    frame.search:SetText("")
    suppressSearch = false
  end
end

local function CreateSideBtn()
  local b = CreateFrame("Button", nil, side)
  b:SetWidth(SIDE_LIST_W - 4)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.sel = b:CreateTexture(nil, "BACKGROUND")
  b.sel:SetAllPoints()
  b.sel:SetColorTexture(0.16, 0.16, 0.20, 0.88)
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
    if self.peerID then
      ns.Sync.Include(self.peerID) -- a suggestion: click adds that player to the group
    elseif self.key then
      if ComradeCraftDB.ui.sel ~= self.key then ClearSearch() end
      ComradeCraftDB.ui.sel = self.key
      ns.RefreshWindow()
    end
  end)
  return b
end

-- Name of the peer a remote character came from.
local function PeerName(c)
  local peer = c.peer and ComradeCraftDB.peers and ComradeCraftDB.peers[c.peer]
  return peer and peer.name
end

local sideDiv, sideCharHead
local function RenderSide(sel)
  ReleaseAll(sideBtns)
  local chars = ns.AllChars()
  local y = -2
  local function Add(key, name, sub, peerID)
    local b = Acquire(sideBtns, CreateSideBtn)
    b.key, b.peerID = key, peerID
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", side, "TOPLEFT", 4, y)
    b.name:SetText(name)
    b.sub:SetText(sub)
    local h = 24 + (sub ~= "" and (b.sub:GetStringHeight() or 12) or 0)
    b:SetHeight(h)
    b.sel:SetShown(sel == key)
    b.accent:SetShown(sel == key)
    y = y - h - 4
  end
  Add("group", L["Group"], ns.Plural(#SortedKeys(chars), "%d member", "%d members"))
  Add("groupplan", L["Group plan"], "|cff9d9d9d" .. (ns.GroupObjective() == "group" and L["Lowest group cost"]
    or L["Market value"]) .. "|r")
  local wList = ns.Wishlist and ns.Wishlist.List() or {}
  local wReady = 0
  for _, e in ipairs(wList) do if ns.Wishlist.Progress(e).bagReady then wReady = wReady + 1 end end
  local wSub = wReady > 0 and ("|cff40ff40" .. L["%d ready"]:format(wReady) .. "|r")
    or (#wList > 0 and ("|cff9d9d9d" .. ns.Plural(#wList, "%d tracked", "%d tracked") .. "|r")
    or ("|cff9d9d9d" .. L["none pinned"] .. "|r"))
  Add("wishlist", L["Wishlist"], wSub)
  local open = ns.Requests and ns.Requests.OpenCount() or 0
  Add("requests", L["Craft requests"], open > 0 and ("|cff80ff80" .. ns.Plural(open, "%d to answer", "%d to answer") .. "|r")
    or ("|cff9d9d9d" .. L["none open"] .. "|r"))
  local listed = 0
  for _ in pairs(ns.Directory.Index().chars) do listed = listed + 1 end
  Add("directory", L["Guild directory"], "|cff9d9d9d" .. ns.Plural(listed, "%d crafter", "%d crafters") .. "|r")
  local inGroup, requests = 0, 0
  for _, peer in pairs(ComradeCraftDB.peers or {}) do
    if peer.included then inGroup = inGroup + 1 elseif peer.asked then requests = requests + 1 end
  end
  Add("manage", L["Manage group"], ns.Plural(inGroup, "%d player", "%d players")
    .. (requests > 0 and ("  |cff80ff80" .. ns.Plural(requests, "%d request", "%d requests") .. "|r") or ""))

  -- Visual divider between navigation views and character sheets.
  if not sideDiv then
    sideDiv = side:CreateTexture(nil, "ARTWORK")
    sideDiv:SetHeight(1)
    sideDiv:SetWidth(SIDE_LIST_W - 12)
    sideDiv:SetColorTexture(0.6, 0.5, 0.3, 0.45)
    sideCharHead = side:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sideCharHead:SetJustifyH("LEFT")
  end
  sideDiv:ClearAllPoints()
  sideDiv:SetPoint("TOPLEFT", side, "TOPLEFT", 6, y - 3)
  sideCharHead:ClearAllPoints()
  sideCharHead:SetPoint("TOPLEFT", side, "TOPLEFT", 8, y - 9)
  sideCharHead:SetText("|cffffd100" .. L["Characters"] .. "|r")
  y = y - 24
  for _, key in ipairs(SortedKeys(chars)) do
    local c = chars[key]
    local lines = { LevelSpecClass(c) }
    if c.peer then
      lines[#lines + 1] = "|cff66ccff" .. L["via %s"]:format(PeerName(c) or "?") .. "|r"
    elseif not c.shared then
      lines[#lines + 1] = "|cff9d9d9d" .. L["not shared"] .. "|r"
    end
    local shown = 0
    for _, pname in ipairs(SortedKeys(c.professions or {})) do
      local p = c.professions[pname]
      if LineVisible(p.skillLine) then
        shown = shown + 1
        local pct = (p.max or 0) > 0 and (p.rank or 0) / p.max or 0
        lines[#lines + 1] = ("%s |cff%s%d/%d|r"):format(pname, pct >= 1 and "40c040" or "ffd100", p.rank or 0, p.max or 0)
      end
    end
    -- With a profession filter, characters without that profession are left out.
    if shown > 0 or not ComradeCraftDB.ui.prof or sel == key then
      Add(key, ns.ClassColored(key, c.class), table.concat(lines, "\n"))
    end
  end
  side:SetHeight(math.max(1, -y))
end

-- Manage group view ------------------------------------------------------------------------

-- Section title bar + optional one-line explanation; returns the new y.
local function Section(y, title, help)
  y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. title .. "|r") - 4
  if help then
    local _, h2 = Label(4, y, "|cff9d9d9d" .. help .. "|r", nil, LIST_W - 8)
    y = y - h2 - 4
  end
  return y - 4
end

local function CharCount(peer)
  local n = 0
  for _ in pairs(peer.chars or {}) do n = n + 1 end
  return n
end

-- Your characters (share boxes), players in the group (remove), requests and suggestions
-- (add), add by name, options. Everything sync-related is done from here.
local function RenderManage()
  local db = ComradeCraftDB
  local Sync = ns.Sync
  local y = 0

  y = Section(y, L["Your characters"], L["Only checked characters are shared, and only with the players in your group."])
  local _, lh = Label(0, y + 4, "|cff9d9d9d" .. L["Right box: list the character in the guild directory (professions and recipes only, sent to your guild)."] .. "|r")
  y = y - lh - 4
  local ownKeys = SortedKeys(db.chars)
  local nameCounts = {}
  for _, key in ipairs(ownKeys) do
    local s = ShortName(key)
    nameCounts[s] = (nameCounts[s] or 0) + 1
  end
  local meKey = ns.CharKey()
  local anyShared, anyUnshared = false, false
  for _, key in ipairs(ownKeys) do
    local c = db.chars[key]
    if c.shared then anyShared = true else anyUnshared = true end
    Check(0, y + 2, c.shared, function(on) Sync.SetShared(key, on) end)
    local realmTag = nameCounts[ShortName(key)] > 1 and (" |cff6f6f6f(" .. (key:match("-(.+)$") or "?") .. ")|r") or ""
    local canRemove = key ~= meKey
    Label(30, y - 4, ns.ClassColored(key, c.class) .. realmTag .. "  |cff9d9d9d" .. LevelSpecClass(c) .. "|r",
      "GameFontHighlight", LIST_W - (canRemove and 330 or 250))
    local dirX = canRemove and (LIST_W - 290) or (LIST_W - 210)
    Check(dirX, y + 2, c.listed, function(on) ns.Directory.SetListed(key, on) end)
    Label(dirX + 28, y - 4, L["List in guild directory"], nil, 175)
    if canRemove then
      local delKey = key
      local delBtn = Action(LIST_W - 80, y, L["Remove"], function()
        db.chars[delKey] = nil
        if db.ui and db.ui.sel == delKey then db.ui.sel = meKey end
        Sync.AnnounceToGroup()
        ns.RefreshWindow()
      end)
      delBtn:SetWidth(76)
    end
    y = y - 28
  end
  if #ownKeys > 0 then
    local bAll = Action(0, y, L["Share all"], function() Sync.SetAllShared(true) end)
    bAll:SetWidth(104)
    bAll:SetEnabled(anyUnshared)
    local bNone = Action(110, y, L["Unshare all"], function() Sync.SetAllShared(false) end)
    bNone:SetWidth(104)
    bNone:SetEnabled(anyShared)
    db.settings = db.settings or {}
    Check(226, y + 1, db.settings.autoShareNew, function(on) db.settings.autoShareNew = on or nil end)
    local _, ah = Label(254, y - 4, L["Automatically share new characters on this account"], nil, LIST_W - 254)
    y = y - math.max(28, ah + 10)
  end

  local inGroup, others = {}, {}
  for id, peer in pairs(db.peers or {}) do
    if peer.name then
      table.insert(peer.included and inGroup or others, { id = id, peer = peer })
    end
  end
  local byName = function(a, b) return a.peer.name < b.peer.name end
  table.sort(inGroup, byName)
  table.sort(others, function(a, b)
    if (a.peer.asked and 1 or 0) ~= (b.peer.asked and 1 or 0) then return a.peer.asked and true or false end
    return a.peer.name < b.peer.name
  end)

  y = Section(y - 10, L["Players in your group"], L["They receive your shared characters and you see theirs."])
  if #inGroup == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody yet."] .. "|r")
    y = y - h - 8
  end
  for _, e in ipairs(inGroup) do
    Label(0, y - 4, "|cff80ff80" .. e.peer.name .. "|r  |cff9d9d9d" .. ns.Plural(CharCount(e.peer), "%d character", "%d characters")
      .. " - " .. L["seen %s"]:format(Ago(e.peer.seen)) .. "|r", "GameFontHighlight", LIST_W - 110)
    Action(LIST_W - 100, y, L["Remove"], function() Sync.Exclude(e.id) end)
    y = y - 28
  end
  if #inGroup > 0 then
    -- Updates go out by themselves (debounced); this sends right away.
    Action(0, y, L["Send now"], function() ns.commands.sync() end)
    y = y - 30
  end

  local pendingAdds = Sync.PendingAdds and Sync.PendingAdds() or {}
  y = Section(y - 10, L["Requests and suggestions"],
    L["Players with ComradeCraft in your guild, or who added you. Add them to share both ways."])
  if #others == 0 and #pendingAdds == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody yet."] .. "|r")
    y = y - h - 8
  end
  for _, e in ipairs(others) do
    local status = e.peer.asked and ("|cff80ff80" .. L["wants to join"] .. "|r") or ("|cff9d9d9d" .. L["suggested"] .. "|r")
    Label(0, y - 4, e.peer.name .. "  " .. status .. (CharCount(e.peer) > 0 and ("  |cff9d9d9d"
      .. ns.Plural(CharCount(e.peer), "%d character", "%d characters") .. "|r") or ""), "GameFontHighlight", LIST_W - 110)
    Action(LIST_W - 100, y, L["Add"], function() Sync.Include(e.id) end)
    y = y - 28
  end
  for _, p in ipairs(pendingAdds) do
    Label(0, y - 4, p.name .. "  |cffffd100" .. L["waiting for reply"] .. "|r  |cff9d9d9d(" .. Ago(p.t) .. ")|r",
      "GameFontHighlight", LIST_W - 210)
    Action(LIST_W - 200, y, L["Retry"], function() Sync.RetryAdd(p.key) end)
    Action(LIST_W - 100, y, L["Cancel"], function() Sync.CancelAdd(p.key) end)
    y = y - 28
  end

  y = Section(y - 10, L["Add a player by name"], L["For friends outside your guild. They must add you back."])
  frame.addBox:ClearAllPoints()
  frame.addBox:SetPoint("TOPLEFT", content, "TOPLEFT", 6, y)
  frame.addBox:Show()
  Action(200, y + 1, L["Add"], function()
    local name = frame.addBox:GetText()
    if name and name ~= "" then
      Sync.AddByName(name)
      frame.addBox:SetText("")
    end
  end)
  local targetName = Sync.TargetPlayerName and Sync.TargetPlayerName() or nil
  local tBtn = Action(304, y + 1, targetName and L["Add %s"]:format(targetName) or L["Add target"], function()
    if targetName then Sync.AddByName(targetName) end
  end)
  tBtn:SetWidth(140)
  tBtn:SetEnabled(targetName ~= nil)
  y = y - 34

  local quick = Sync.QuickAddCandidates and Sync.QuickAddCandidates() or {}
  if #quick > 0 then
    local _, qh = Label(0, y, "|cff9d9d9d" .. L["Online in your party, friends or guild:"] .. "|r")
    y = y - qh - 6
    local srcLabel = { party = L["Party"], friend = L["Friend"], guild = L["Guild"] }
    for i = 1, math.min(#quick, 6) do
      local q = quick[i]
      Label(0, y - 4, ns.ClassColored(q.name, q.class) .. "  |cff9d9d9d" .. (srcLabel[q.source] or "") .. "|r",
        "GameFontHighlight", LIST_W - 110)
      Action(LIST_W - 100, y, L["Add"], function() Sync.AddByName(q.name) end)
      y = y - 26
    end
    y = y - 4
  end

  y = Section(y - 6, L["Options"])
  db.settings = db.settings or {}
  Check(0, y + 2, db.settings.guildPing ~= false, function(on)
    db.settings.guildPing = on
  end)
  local _, h = Label(30, y - 4, L["Send a presence signal to the guild at login (no character data)."], nil, LIST_W - 30)
  y = y - math.max(28, h + 10)
  Check(0, y + 2, ns.Requests.MailOn(), function(on) db.settings.mailRequests = on or nil ns.RefreshWindow() end)
  _, h = Label(30, y - 4, L["Craft requests by mail too: for players who are never online at the same time (you send the mail yourself, 30c postage)."], nil, LIST_W - 30)
  y = y - math.max(28, h + 10)
  Check(0, y + 2, ns.TrackerOn(), function(on) ns.SetTracker(on) end)
  _, h = Label(30, y - 4, L["Show the step panel next to the profession window."], nil, LIST_W - 140)
  Action(LIST_W - 100, y, L["Re-dock"], function() ns.SetTracker(nil, true) end)
  y = y - math.max(28, h + 10)
  Check(0, y + 2, ns.FarmTrackerOn(), function(on) ns.SetFarmTracker(on) end)
  _, h = Label(30, y - 4, L["Show the farming tracker (your farming assignments from the Group plan)."], nil, LIST_W - 30)
  y = y - math.max(28, h + 10)
  if ns.Bags then
    Check(0, y + 2, ns.Bags.On(), function(on) ns.Bags.Set(on) end)
    _, h = Label(30, y - 4, L["Highlight items for your group in your bags (and focus a recipient's items when mailing)."], nil, LIST_W - 30)
    y = y - math.max(28, h + 10)
  end
  if ns.Wishlist then
    Check(0, y + 2, ns.Wishlist.TrackerOn(), function(on) ns.Wishlist.SetTracker(on) end)
    _, h = Label(30, y - 4, L["Show the wishlist tracker on screen (pinned crafts)."], nil, LIST_W - 30)
    y = y - math.max(28, h + 10)
  end

  -- Group plan objective: what "cheapest" means for every plan.
  local _, gh = Label(0, y - 2, "|cffffd100" .. L["Group plan"] .. "|r", "GameFontNormal")
  y = y - gh - 8
  local objective = ns.GroupObjective()
  for _, o in ipairs({ { "group", L["Lowest group cost"], L["Least gold spent by the group: stock already held in the group counts as free."] },
    { "solo", L["Market value"], L["Every material at its market value, as if each character were alone."] } }) do
    local v = o[1]
    Toggle(0, y, o[2], objective == v, true, function() ns.SetGroupObjective(v) end):SetWidth(150)
    local _, oh = Label(160, y - 5, "|cff9d9d9d" .. o[3] .. "|r", nil, LIST_W - 160)
    y = y - math.max(28, oh + 12)
  end

  y = Section(y - 6, L["Alerts"], L["A chat line and a short notice at the top of the screen."])
  for _, a in ipairs({ { "mats", L["Your bags hold the mats for your next craft."] },
    { "cooldown", L["A profession cooldown is ready on one of your characters."] },
    { "requests", L["A craft request arrives or changes."] },
    { "keep", L["At a merchant or the auction house: items in your bags that your group needs."] },
    { "upgrade", L["A group member can craft an upgrade for you (off by default)."] } }) do
    Check(0, y + 2, ns.Alerts.On(a[1]), function(on) ns.Alerts.Set(a[1], on) end)
    local _, ah = Label(30, y - 4, a[2], nil, LIST_W - 30)
    y = y - math.max(26, ah + 10)
  end

  y = Section(y - 6, L["Measured skill-up chances"],
    L["Crafts logged by you and your group correct the Classic formula once a color has enough of them."])
  for _, l in ipairs(ns.SkillupStatsLines()) do
    local _, lh = Label(0, y, (l:gsub("^%s+", "")))
    y = y - lh - 2
  end
  return -y
end

-- Help view ("?" button): one short paragraph per feature, plus a button to replay the tour.
local HELP = {
  { L["The window"], L["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] },
  { L["Plans"], L["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never. ~ marks a value taken from Classic."] },
  { L["Routes"], L["Each character picks Cheapest (least spent on mats) or Profitable (products sold back). The milestone table compares both: mats, what the products bring back (merchant, disenchant or AH) and the net cost."] },
  { L["Learning recipes"], L["Hover a Learn line for its trainers, vendors and drops; click it for a TomTom waypoint (with Questie installed for positions)."] },
  { L["Craft queue"], L["In the step panel: the crafts of this step or of the whole milestone, what your bags allow, and Craft next (one batch per click, the game needs a click per craft)."] },
  { L["Group plan"], L["Plans count stock already held in the group as free (or every mat at market value: Manage group > Options). The Group plan view lists what the group still needs and its cost; take a material with I'll farm it and a small tracker follows your progress."] },
  { L["Craft requests"], L["Click a recipe in a group member's Can craft tab to ask for it. Answer what you are asked in Craft requests. Requests reach the other player the next time you are both online (or by mail, if turned on in Manage group)."] },
  { L["Tooltips"], L["On any material: who in the group needs it, how many, and how soon (now, soon, later). Spare stock in the group is shown too."] },
  { L["Step panel"], L["Next to your profession window: the current step, the chance per craft, how many crafts your bags allow, and what comes next."] },
  { L["Giving and mail"], L["You can give lists what you hold that others need. At a mailbox, the button beside the send frame attaches it. Nothing is ever sent for you."] },
  { L["Disenchant or keep"], L["Your green items: keep one per slot your enchanting plan needs, keep upgrades for group members, sell what is worth more than its mats, disenchant the rest."] },
  { L["Shopping"], L["The Shopping list button makes an Auctionator list, or a TSM search and group to paste. TSM groups that are done are pointed out."] },
  { L["Sharing"], L["Nothing is shared until you check a character in Manage group, and only with players you added who added you back."] },
  { L["Guild directory"], L["Opt-in, per character: List in guild directory in Manage group (or /comrade list) sends its professions and recipes to guildmates who use ComradeCraft. Search who can craft an item, whisper them, or ask for the craft if they are in your group. Item tooltips name up to 3 guild crafters."] },
  { L["Next rank"], L["At the skill cap: the Expert book (vendor or AH), the Artisan quest found in Questie (click for a waypoint to its giver), or the trainer."] },
  { L["Alerts"], L["Mats ready, profession cooldowns ready on any of your characters, craft requests, items your group needs when you open a merchant or the AH (with Buy back after a sale), and opt-in upgrades. Each one can be turned off in Manage group."] },
  { L["Better with"], L["TSM or Auctionator (prices), Questie (positions), TomTom (waypoints), Pawn (upgrades for each class and spec). All optional."] },
}

local function RenderHelp()
  local y = 0
  for _, h in ipairs(HELP) do
    local _, th = Label(0, y, "|cffffd100" .. h[1] .. "|r", "GameFontNormal")
    y = y - th - 2
    local _, bh = Label(0, y, h[2])
    y = y - bh - 10
  end
  Action(0, y, L["Replay the tour"], function() ns.StartTutorial(true) end)
  return -y + 30
end

-- First-open tour: a few cards over the window. Skip = not again this session;
-- "Do not show again" (or finishing it) = never again.
local TOUR = {
  { L["Welcome to ComradeCraft"], L["It answers one question: what should I do with what I have, for the group? 30 seconds to see the main parts."],
    { "CENTER", 0, 40 } },
  { L["Your group"], L["Left: the group overview, the group management, then every character you share or receive."],
    { "TOPLEFT", SIDE_W + 10, -80 }, "group" },
  { L["Plan and Can craft"], L["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."],
    { "TOPLEFT", DETAIL_X + 260, -100 }, "self" },
  { L["While you play"], L["Item tooltips show who needs a material. A step panel opens next to your profession window."],
    { "CENTER", 0, 0 } },
  { L["Sharing is off until you check a box"], L["Nothing is shared yet. Here, in Manage group, check the box next to each character you want to share under Your characters (on the left of this card). Unchecked characters never leave your computer. Then add your friends below, or accept guildmates who appear there. The ? button explains the rest."],
    { "TOPLEFT", DETAIL_X + 330, -150 }, "manage" },
}
local tourSkipped, tourCard = false, nil

local function TutorialCard()
  if tourCard then return tourCard end
  local t = CreateFrame("Frame", "ComradeCraftTour", frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
  t:SetSize(340, 150)
  t:SetFrameStrata("DIALOG")
  t:SetToplevel(true)
  -- Opaque: the dialog background texture is see-through on its own.
  local solid = t:CreateTexture(nil, "BACKGROUND", nil, -8)
  solid:SetPoint("TOPLEFT", 4, -4)
  solid:SetPoint("BOTTOMRIGHT", -4, 4)
  solid:SetColorTexture(0.06, 0.05, 0.04, 0.97)

  if t.SetBackdrop then
    t:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    t:SetBackdropBorderColor(1, 0.82, 0, 1)
  end
  t:EnableMouse(true)
  t.title = t:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  t.title:SetPoint("TOPLEFT", 14, -12)
  t.count = t:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  t.count:SetPoint("TOPRIGHT", -14, -14)
  t.text = t:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  t.text:SetPoint("TOPLEFT", 14, -36)
  t.text:SetWidth(312)
  t.text:SetJustifyH("LEFT")
  t.never = CreateFrame("CheckButton", nil, t, "UICheckButtonTemplate")
  t.never:SetSize(22, 22)
  t.never:SetPoint("BOTTOMLEFT", 10, 8)
  t.never.label = t.never:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  t.never.label:SetPoint("LEFT", t.never, "RIGHT", 2, 0)
  t.never.label:SetText(L["Do not show again"])
  t.next = CreateFrame("Button", nil, t, "UIPanelButtonTemplate")
  t.next:SetSize(80, 22)
  t.next:SetPoint("BOTTOMRIGHT", -10, 10)
  t.skip = CreateFrame("Button", nil, t, "UIPanelButtonTemplate")
  t.skip:SetSize(80, 22)
  t.skip:SetPoint("RIGHT", t.next, "LEFT", -6, 0)
  t.skip:SetText(L["Skip"])
  local function Close(finished)
    if finished or t.never:GetChecked() == true then ComradeCraftDB.settings.tutorialDone = true end
    tourSkipped = true
    t:Hide()
  end
  t.skip:SetScript("OnClick", function() Close(false) end)
  t.next:SetScript("OnClick", function()
    if t.step >= #TOUR then Close(true) else ns.ShowTutorialStep(t.step + 1) end
  end)
  tourCard = t
  return t
end

function ns.ShowTutorialStep(i)
  local t = TutorialCard()
  local s = TOUR[i]
  t.step = i
  t.title:SetText(s[1])
  t.text:SetText(s[2])
  t.count:SetText(("%d/%d"):format(i, #TOUR))
  t.next:SetText(i == #TOUR and L["Done"] or L["Next"])
  -- Each step opens the view it talks about.
  if s[4] then
    ComradeCraftDB.ui.sel = s[4] == "self" and ns.CharKey() or s[4]
    ComradeCraftDB.ui.tab = "plan"
    ns.RefreshWindow()
  end
  t:SetHeight(i == #TOUR and 200 or 150)
  t:ClearAllPoints()
  t:SetPoint(s[3][1], frame, s[3][1], s[3][2], s[3][3])
  t:Show()
end

-- Shown on the first opening (unless done, or skipped this session); `force` from Help.
function ns.StartTutorial(force)
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  if not force and (ComradeCraftDB.settings.tutorialDone or tourSkipped) then return end
  if not (frame and frame:IsShown()) then return end
  ns.ShowTutorialStep(1)
end

-- Craft requests view: for your characters (answer them), then yours (follow them).
local STATUS_COLOR = { pending = "ffd100", accepted = "40c0ff", done = "40ff40", declined = "ff6040", cancelled = "9d9d9d" }

local function RequestRow(y, r, incoming)
  local R = ns.Requests
  local who = incoming and L["%s for %s"]:format(ShortName(r.from), ShortName(r.to))
    or L["asked to %s"]:format(ShortName(r.to))
  local line1 = ("|cffffffff%dx %s|r  |cff9d9d9d%s|r  |cff%s%s|r"):format(r.qty, ns.SpellName(r.spell), who,
    STATUS_COLOR[r.status] or "ffffff", L[r.status])
  local details = {}
  if r.note then details[#details + 1] = "\"" .. r.note .. "\"" end
  if r.acked ~= r.updated then details[#details + 1] = L["waiting to reach the other player"] end
  if incoming and (r.status == "pending" or r.status == "accepted") then
    details[#details + 1] = L["Mats: %s"]:format(ns.ReagentText(r.spell, r.qty))
    if r.to == ns.CharKey() then
      details[#details + 1] = L["your bags allow %d"]:format(ns.CraftableNow(r.spell, ns.CharData().bags or {}))
    end
  end
  local _, h1 = Label(0, y - 2, line1, "GameFontHighlight", LIST_W - 210)
  local _, h2 = Label(0, y - 4 - h1, "|cff9d9d9d" .. table.concat(details, "  -  ") .. "|r", nil, LIST_W - 210)
  local buttons = {}
  if incoming then
    if r.status == "pending" then
      buttons = { { L["Accept"], "accepted" }, { L["Decline"], "declined" } }
    elseif r.status == "accepted" then
      buttons = { { L["Done"], "done" }, { L["Decline"], "declined" } }
    end
  elseif r.status == "pending" or r.status == "accepted" then
    buttons = { { L["Cancel request"], "cancelled" } }
    if r.status == "pending" and r.acked ~= r.updated and R.MailOn() then
      buttons[2] = { L["By mail"], function() ns.Mail.PrepareRequest(r) end }
    end
  end
  if #buttons == 0 then buttons = { { L["Remove"], false } } end
  for i, bt in ipairs(buttons) do
    Action(LIST_W - 100 * i, y, bt[1], function()
      if type(bt[2]) == "function" then bt[2]()
      elseif bt[2] then R.Set(r.id, bt[2]) else R.Remove(r.id) end
    end)
  end
  return y - math.max(30, h1 + h2 + 12)
end

local function RenderRequests()
  local inc, out = ns.Requests.Lists()
  local y = Section(0, L["For your characters"],
    L["Accept, craft, then mark it done; the mail helper attaches the item when you write to them."])
  if #inc == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody yet."] .. "|r")
    y = y - h - 8
  end
  for _, r in ipairs(inc) do y = RequestRow(y, r, true) end
  y = Section(y - 10, L["Your requests"],
    L["Click a recipe in a group member's Can craft tab to ask for it. Delivered the next time you are both online."])
  if #out == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody yet."] .. "|r")
    y = y - h - 8
  end
  for _, r in ipairs(out) do y = RequestRow(y, r, false) end
  return -y
end

-- Group plan view: one row per material the group still needs, its spare, the cost of the
-- rest and who farms it. Columns (x from the row's left): material | needed | spare | to get | cost | farming.
local PLAN_H, PC_NEED, PC_SPARE, PC_GET, PC_COST, PC_FARM = 40, 250, 304, 420, 470, 568
local planRows = {}

local function CreatePlanRow()
  local b = CreateFrame("Button", nil, content)
  b:SetHeight(PLAN_H)
  b:SetWidth(PC_FARM - 4) -- the farming column holds buttons: kept out of the row's hit area
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(24, 24)
  b.icon:SetPoint("TOPLEFT", 0, -4)
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("TOPLEFT", 30, -4)
  b.by = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.by:SetPoint("TOPLEFT", 30, -18)
  for _, k in ipairs({ "name", "by" }) do
    b[k]:SetWidth(PC_NEED - 38)
    b[k]:SetJustifyH("LEFT")
    b[k]:SetWordWrap(false)
  end
  for _, col in ipairs({ { "need", PC_NEED, 44, "RIGHT" }, { "spare", PC_SPARE + 8, 104, "LEFT" },
    { "get", PC_GET, 44, "RIGHT" }, { "cost", PC_COST, 90, "RIGHT" } }) do
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", col[2], -10)
    fs:SetWidth(col[3])
    fs:SetJustifyH(col[4])
    fs:SetWordWrap(false)
    b[col[1]] = fs
  end
  -- No SetItemByID here: its tooltip hook (Tooltip.lua) would add the same breakdown twice.
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine((ItemInfo(self.row.item)) or ("item:" .. self.row.item), 1, 1, 1)
    ns.AddPlanLines(GameTooltip, self.row)
    if self.advice then
      GameTooltip:AddLine(" ")
      GameTooltip:AddDoubleLine(L["Advice"], self.advice.label, 0.8, 0.8, 0.8, 1, 1, 1)
      if self.advice.spot then
        local sp = self.advice.spot
        GameTooltip:AddDoubleLine(L["Farm spot"], ("%s (%s %d, %d)"):format(sp.name, sp.zone or "?", sp.x, sp.y),
          0.5, 0.8, 1, 1, 1, 1)
        GameTooltip:AddLine(L["Click: waypoint to farm spot."], 0.5, 0.8, 1)
      end
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if not LinkOnShiftClick(self.row.item) and self.advice and self.advice.spot and ns.FarmAdvice then
      ns.FarmAdvice.Waypoint(self.row.item)
    end
  end)
  return b
end

local function RenderGroupPlan()
  local y = 0
  local objective = ns.GroupObjective()
  Label(0, y - 5, L["Objective:"], "GameFontNormal", 72)
  Toggle(76, y, L["Lowest group cost"], objective == "group", true, function() ns.SetGroupObjective("group") end):SetWidth(150)
  Toggle(230, y, L["Market value"], objective == "solo", true, function() ns.SetGroupObjective("solo") end):SetWidth(120)
  local desc = objective == "group"
    and L["Least gold spent by the group: stock already held in the group counts as free."]
    or L["Every material at its market value, as if each character were alone."]
  local _, h = Label(358, y - 5, "|cff9d9d9d" .. desc .. "|r", nil, LIST_W - 358)
  y = y - math.max(30, h + 12)
  local list, total, complete, any = ns.GroupPlan()
  if #list == 0 then
    local _, h2 = Label(0, y, "|cff9d9d9d" .. L["Nothing missing yet."] .. "|r")
    return -y + h2
  end
  for _, col in ipairs({ { 30, L["Material"], 200 }, { PC_NEED - 16, L["Needed"], 60 },
    { PC_SPARE + 8, L["Spare"], 110 }, { PC_GET - 16, L["To get"], 60 },
    { PC_COST + 20, L["Est. cost"], 70 }, { PC_FARM, L["Farming"], LIST_W - PC_FARM } }) do
    Label(col[1], y, "|cff8f8f8f" .. col[2] .. "|r", "GameFontDisableSmall", col[3])
  end
  y = y - 16
  local chars = ns.AllChars()
  local gold = (GetMoney and GetMoney()) or 0
  for idx, row in ipairs(list) do
    local b = Acquire(planRows, CreatePlanRow)
    b.row = row
    b.advice = row.toGet > 0 and ns.FarmAdvice and ns.FarmAdvice.Evaluate(row.item, row.toGet, gold) or nil
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    local name, _, icon = ItemInfo(row.item)
    b.icon:SetTexture(icon)
    b.name:SetText(name or ("item:" .. row.item))
    local by, names = {}, {}
    for _, x in ipairs(row.by) do
      by[#by + 1] = ("%s %d"):format(ShortName(x.key), x.n)
      names[#names + 1] = ShortName(x.key)
    end
    b.by:SetText(table.concat(by, ", "))
    b.need:SetText(tostring(row.total))
    local holders = {}
    for i = 1, math.min(3, #row.holders) do holders[i] = ShortName(row.holders[i].key) end
    b.spare:SetText(row.spare > 0 and ("|cff80ccff%d|r |cff9d9d9d(%s)|r"):format(row.spare, table.concat(holders, ", "))
      or "|cff6f6f6f-|r")
    b.get:SetText(row.toGet > 0 and ("|cffffd100" .. row.toGet .. "|r") or "|cff40ff400|r")
    local costTxt = row.toGet == 0 and "|cff6f6f6f-|r" or row.cost and ShortMoney(row.cost) or "|cff9d9d9d?|r"
    if b.advice and row.toGet > 0 then
      local tag = b.advice.action == "buy" and " |cff40ff40" .. L["Buy"] .. "|r"
        or (b.advice.action == "farm" and " |cffffa040" .. L["Farm"] .. "|r" or "")
      costTxt = costTxt .. tag
    end
    b.cost:SetText(costTxt)
    -- Farming: who took it (own: a Drop button), else an offer when something is left to get.
    local farmers, mine = {}, nil
    for _, f in ipairs(row.farmers) do
      farmers[#farmers + 1] = ns.ClassColored(f.key, chars[f.key] and chars[f.key].class)
      if f.own then mine = f end
    end
    if #farmers > 0 then
      Label(PC_FARM, y - 4, L["Farmed by %s"]:format(table.concat(farmers, ", ")), nil, LIST_W - PC_FARM)
      if mine then
        local item = row.item
        Action(PC_FARM, y - 17, L["Drop"], function() ns.FarmDrop(item) end)
      end
    elseif row.toGet > 0 and not ns.IsVendorItem(row.item) then
      local item, n, who = row.item, row.toGet, table.concat(names, ", ")
      Action(PC_FARM, y - 9, L["I'll farm it"], function() ns.ShowFarmDialog(item, n, who) end)
    end
    y = y - PLAN_H
  end
  y = y - 8
  local text = not any and L["Estimated cost for the group: unknown (TSM or Auctionator give AH prices)."]
    or complete and L["Estimated cost for the group: %s"]:format(ns.Money(math.floor(total)))
    or L["Estimated cost for the group: at least %s (some items have no price)."]:format(ns.Money(math.floor(total)))
  if gold > 0 then
    text = text .. "   |cff9d9d9d" .. L["Your gold: %s"]:format("|cffffffff" .. ns.Money(gold) .. "|cff9d9d9d") .. "|r"
  end
  local _, th = Label(0, y, "|cffffd100" .. text .. "|r", "GameFontNormal")
  return -y + th + 4
end

-- Guild directory view: listed characters (empty search), or who crafts what matches the search.
local function DirectoryProfs(e)
  local parts = {}
  for _, line in ipairs(SortedKeys(e.p or {})) do
    local x = e.p[line]
    parts[#parts + 1] = ("%s %d/%d"):format(x[3] or ("#" .. line), x[1] or 0, x[2] or 0)
  end
  return table.concat(parts, ", ")
end

-- One crafter line with its Whisper (and, for a group member, Ask for it) button.
local function DirectoryRow(x, y, key, spell, text)
  local D = ns.Directory
  local _, h = Label(x, y - 4, text, "GameFontHighlight", LIST_W - x - 210)
  if D.WhisperTarget(key) then Action(LIST_W - 100, y, L["Whisper"], function() D.Whisper(key) end) end
  if spell and D.CanRequest(key) then
    Action(LIST_W - 200, y, L["Ask for it"], function() ns.Requests.ShowDialog(key, spell) end)
  end
  return y - math.max(26, h + 8)
end

local function RenderDirectory(filter)
  local D = ns.Directory
  local idx = D.Index()
  local y = 0
  if not next(idx.chars) then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody is listed yet. The directory is opt-in: each player lists their own characters in Manage group (List in guild directory) or with /comrade list."] .. "|r")
    return -y + h
  end
  if filter == "" then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Type a product or recipe name in the search box."] .. "|r")
    y = y - h - 10
    for _, key in ipairs(SortedKeys(idx.chars)) do
      local e = idx.chars[key]
      local seen = e.own and "" or ("  |cff9d9d9d" .. L["seen %s"]:format(Ago(e.seen)) .. "|r")
      y = DirectoryRow(0, y, key, nil, ns.ClassColored(key, e.cl) .. "  |cff9d9d9d" .. DirectoryProfs(e) .. "|r" .. seen)
    end
    return -y
  end
  local found = D.Search(filter)
  if #found == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No crafter found."] .. "|r")
    return -y + h
  end
  for i = 1, math.min(#found, D.MAX_ROWS) do
    local r = found[i]
    local _, h = Label(0, y, "|cffffd100" .. r.name .. "|r  |cff9d9d9d- " .. D.Names(r.crafters, 3) .. "|r", "GameFontNormal")
    y = y - h - 6
    for i2 = 1, math.min(#r.crafters, 10) do
      local key = r.crafters[i2]
      y = DirectoryRow(16, y, key, r.spell, ns.ClassColored(key, idx.chars[key] and idx.chars[key].cl))
    end
    y = y - 6
  end
  if #found > D.MAX_ROWS then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["... and %d more"]:format(#found - D.MAX_ROWS) .. "|r")
    y = y - h
  end
  return -y
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
  local T = C_TradeSkillUI
  if T and T.GetTradeSkillDisplayName then
    local ok, n = pcall(T.GetTradeSkillDisplayName, line)
    if ok and type(n) == "string" and n ~= "" then return n end
  end
  return fallback
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
  ReleaseAll(rows) ReleaseAll(mats) ReleaseAll(steps) ReleaseAll(recipes) ReleaseAll(labels)
  ReleaseAll(actionBtns) ReleaseAll(checks) ReleaseAll(toggles) ReleaseAll(heads) ReleaseAll(planRows)
  ReleaseAll(groupRows) ReleaseAll(sectionBars)
  frame.addBox:Hide()
  frame.groupOverTab:Hide() frame.groupMatsTab:Hide() frame.groupUpTab:Hide() frame.groupDeTab:Hide()
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
    h = RenderWishlist()
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
    h = RenderRequests()
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
    h = RenderGroupPlan()
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
    h = RenderDirectory(filter)
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
    h = RenderHelp()
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
    h = RenderManage()
  elseif ui.sel == "group" then
    local gTab = ui.groupTab or "overview"
    frame.groupOverTab:Show() frame.groupMatsTab:Show() frame.groupUpTab:Show() frame.groupDeTab:Show()
    frame.groupOverTab:SetActive(gTab == "overview")
    frame.groupMatsTab:SetActive(gTab == "mats")
    frame.groupUpTab:SetActive(gTab == "upgrades")
    frame.groupDeTab:SetActive(gTab == "de")
    frame.search:ClearAllPoints()
    frame.search:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -112)
    SetSearchPlaceholder(L["Find who can craft..."])
    frame.search:Show()
    if (gTab == "de" or gTab == "upgrades") and filter == "" then
      ReleaseAll(chips)
      frame.gatherBox:Hide()
      scrollTop = -142
    else
      scrollTop = RenderChips(chars, -142)
    end
    frame.title:SetText(L["Group"])
    frame.sub:SetText(L["Skill levels and the materials the group still needs. Type to find who can craft something."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    frame.removeBtn:Hide()
    frame.shareBox:Hide()
    h = RenderGroup(filter)
  else
    local c = chars[ui.sel]
    frame.title:SetText(ns.ClassColored(ui.sel, c.class))
    frame.sub:SetWidth(LIST_W - 260)
    frame.sub:SetText(("%s - %s%s"):format(LevelSpecClass(c),
      L["updated %s"]:format(Ago(c.updated)), c.peer and (" - " .. L["via %s"]:format(PeerName(c) or "?")) or ""))
    frame.removeBtn.peerID = c.peer
    frame.removeBtn:SetShown(c.peer ~= nil)
    frame.shareBox.key = not c.peer and ui.sel or nil
    frame.shareBox:SetShown(c.peer == nil)
    frame.shareBox:SetChecked(c.shared and true or false)
    frame.planTab:Show()
    frame.craftTab:Show()
    frame.planTab:SetActive(ui.tab ~= "craft")
    frame.craftTab:SetActive(ui.tab == "craft")
    if ui.tab == "craft" then
      frame.search:ClearAllPoints()
      frame.search:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -112)
      SetSearchPlaceholder(L["Filter recipes..."])
      frame.search:Show()
    else
      frame.search:Hide()
    end
    scrollTop = RenderChips({ [ui.sel] = c }, -142)
    if ui.tab == "craft" then
      h = RenderCraft(ui.sel, c, filter)
    else
      h = RenderPlan(ui.sel, c)
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
  frame.foot:SetText(L["Sync: %d players in the group, %d suggested. skill ~N: value taken from Classic, unconfirmed."]
    :format(inGroup, suggested))
end

local function CreateWindow()
  local ok, f = pcall(CreateFrame, "Frame", "ComradeCraftFrame", UIParent, "ButtonFrameTemplate")
  if not ok or not f then
    f = CreateFrame("Frame", "ComradeCraftFrame", UIParent, "BasicFrameTemplateWithInset")
  end
  f:SetSize(W, H)
  local pos = ComradeCraftDB and ComradeCraftDB.ui and ComradeCraftDB.ui.pos
  if pos then f:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3]) else f:SetPoint("CENTER") end
  -- Same layer as the game's windows: the profession window can come in front of it.
  f:SetFrameStrata("MEDIUM")
  f:SetToplevel(true)
  f:SetMovable(true)
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
  f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.badge:SetPoint("RIGHT", f.helpBtn, "LEFT", -10, 0)

  -- Sculpted dark-stone tabs: bronze/gold carved border + gold underline when active (no yellowish box fill).
  local function Tab(text, tab, anchor, field, w)
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
    b:SetScript("OnClick", function()
      ComradeCraftDB.ui[field or "tab"] = tab
      ns.RefreshWindow()
    end)
    return b
  end
  f.planTab = Tab(L["Plan"], "plan", { "TOPLEFT", DETAIL_X, -112 })
  f.craftTab = Tab(L["Can craft"], "craft", { "TOPLEFT", DETAIL_X + 126, -112 })
  f.groupOverTab = Tab(L["Overview"], "overview", { "TOPLEFT", DETAIL_X, -112 }, "groupTab", 100)
  f.groupMatsTab = Tab(L["Materials"], "mats", { "TOPLEFT", DETAIL_X + 104, -112 }, "groupTab", 100)
  f.groupUpTab = Tab(L["Upgrades"], "upgrades", { "TOPLEFT", DETAIL_X + 208, -112 }, "groupTab", 100)
  f.groupDeTab = Tab(L["Disenchant"], "de", { "TOPLEFT", DETAIL_X + 312, -112 }, "groupTab", 104)
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

  local ok2, search = pcall(CreateFrame, "EditBox", nil, f, "SearchBoxTemplate")
  if not ok2 or not search then search = CreateFrame("EditBox", nil, f, "InputBoxTemplate") end
  search:SetSize(200, 20)
  search:SetPoint("TOPRIGHT", -30, -112)
  search:SetAutoFocus(false)
  search:HookScript("OnTextChanged", function() if not suppressSearch then ns.RefreshWindow() end end)
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
  foot2:SetPoint("BOTTOMRIGHT", -20, 14)
  foot2:SetText("/comrade")

  f:SetScript("OnShow", ns.RefreshWindow)
  return f
end

function ns.ToggleWindow()
  ComradeCraftDB.ui = ComradeCraftDB.ui or {}
  frame = frame or CreateWindow()
  frame:SetShown(not frame:IsShown())
  if frame:IsShown() then ns.StartTutorial() end
end

-- Item names load asynchronously; redraw once they arrive (coalesced).
local pending = false
ns.On("GET_ITEM_INFO_RECEIVED", function()
  if pending or not (frame and frame:IsShown()) then return end
  pending = true
  C_Timer.After(0.2, function() pending = false ns.RefreshWindow() end)
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

-- Minimap button (LibDataBroker launcher + LibDBIcon). Position saved in ComradeCraftDB.minimap.
ns.On("PLAYER_LOGIN", function()
  local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
  local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
  if not (LDB and Icon) then return end
  local obj = LDB:NewDataObject("ComradeCraft", {
    type = "launcher",
    icon = ns.LOGO,
    OnClick = function() ns.ToggleWindow() end,
    OnTooltipShow = function(tt)
      tt:AddLine("ComradeCraft")
      ns.MinimapSummary(tt)
      tt:AddLine(" ")
      tt:AddLine(L["Click: group needs"], 1, 1, 1)
    end,
  })
  ComradeCraftDB.minimap = ComradeCraftDB.minimap or {}
  Icon:Register("ComradeCraft", obj, ComradeCraftDB.minimap)
end)
