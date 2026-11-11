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
local sideBtns, rows, mats, steps, recipes, labels, heads = {}, {}, {}, {}, {}, {}, {}

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
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
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
    ShowItemTooltip(self, e.item, e.spell)
    if e.kind == "learn" then
      ns.AddSourceLines(GameTooltip, e.spell)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    local e = self.entry
    if not e or e.kind == "range" or e.kind == "milestone" or LinkOnShiftClick(e.item) then return end
    if e.kind == "craft" and self.own then ns.OpenRecipe(e.spell) end
    if e.kind == "learn" then ns.WaypointRecipe(e.spell) end
  end)
  return b
end

-- Places one steps-column line at content (x, y), width w; returns its height.
local function PlaceStep(x, y, w, e, own)
  local s = Acquire(steps, CreateStep)
  s.entry, s.own = e, own
  s:ClearAllPoints()
  s:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
  s:SetWidth(w)
  s.count:SetText("")
  s.detail:SetText("")
  s.right:SetText("")
  s.line:Hide()
  s.icon:Hide()
  for _, fs in ipairs(s.cols) do fs:SetText("") end
  s.text:SetText("")
  local h
  if e.kind == "range" then
    s.text:ClearAllPoints()
    s.text:SetPoint("TOPLEFT", 0, -4)
    s.text:SetWidth(w - 110)
    s.text:SetText("|cffffd100" .. (e.header or L["Skill %d to %d"]:format(e.from, e.to)) .. "|r")
    s.right:SetText(e.cost or "")
    s.line:Show()
    h = 22
  elseif e.kind == "milestone" then
    for i, v in ipairs(e.cols) do s.cols[i]:SetText(v) end
    h = 16
  else
    s.icon:Show()
    s.icon:SetTexture(e.item and e.item ~= 0 and select(3, ItemInfo(e.item))
      or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(e.spell)) or 134400)
    s.count:SetText(e.n and (e.n .. "x") or "")
    s.text:ClearAllPoints()
    s.text:SetPoint("TOPLEFT", 58, -3)
    s.text:SetWidth(w - 62)
    s.text:SetText(e.kind == "learn" and ("|cff66ccff" .. L["Learn %s"]:format(e.label or "") .. "|r")
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
  r.hit:SetSize(PROF_W - 8, 30)
  r.hit:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  r.hit:SetScript("OnClick", function(self) ToggleCollapsed(self.line) end)
  r.fold = r:CreateTexture(nil, "ARTWORK")
  r.fold:SetSize(14, 14)
  r.fold:SetPoint("TOPLEFT", 2, -8)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(32, 32)
  r.icon:SetPoint("TOPLEFT", 20, -6)
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1)
  r.level = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.level:SetPoint("TOPRIGHT", r, "TOPLEFT", PROF_W - 8, -8)
  r.bar = CreateFrame("StatusBar", nil, r)
  r.bar:SetSize(PROF_W - 70, 8)
  r.bar:SetPoint("TOPLEFT", r.icon, "BOTTOMRIGHT", 8, 10)
  r.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  r.bar:SetStatusBarColor(0.35, 0.7, 0.25)
  local barBg = r.bar:CreateTexture(nil, "BACKGROUND")
  barBg:SetAllPoints()
  barBg:SetColorTexture(0, 0, 0, 0.6)
  for _, k in ipairs({ "top", "mid", "bottom" }) do
    r[k] = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r[k]:SetWidth(RIGHT_W)
    r[k]:SetJustifyH("LEFT")
  end
  r.top:SetPoint("TOPLEFT", r, "TOPLEFT", PROF_W, -8)
  -- Missing mats as an Auctionator list and/or TSM search text (shown only with one of them).
  r.shop = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  r.shop:SetSize(PROF_W - 20, 20)
  r.shop:SetPoint("TOPLEFT", r, "TOPLEFT", 6, -48)
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
  b:SetScript("OnEnter", function(self) ShowItemTooltip(self, self.itemID) end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  -- Shift-click links; on a "you can give" entry with the mailbox open, prepares the mail.
  b:SetScript("OnClick", function(self)
    if not LinkOnShiftClick(self.itemID) and self.giveTo and ns.Mail.IsOpen() then ns.Mail.Prepare(self.giveTo) end
  end)
  return b
end

local function PlaceMat(x, y, item, count, sub, width)
  local m = Acquire(mats, CreateMat)
  m.giveTo = nil
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
  b:SetHeight(RECIPE_H)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
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
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if IsModifiedClick and IsModifiedClick("CHATLINK") then
      local link = ns.RecipeLink(self.spell, self.item)
      if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
    elseif self.own then
      ns.OpenRecipe(self.spell)
    elseif self.requestTo then
      ns.Requests.ShowDialog(self.requestTo, self.spell)
    end
  end)
  return b
end

local function PlaceRecipe(x, y, e, tags, kind, own)
  local b = Acquire(recipes, CreateRecipe)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
  b:SetWidth(LIST_W - x)
  b.spell, b.item, b.own, b.requestTo = e.spell, e.item, own, nil
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

-- Flat two-state button (like the Plan / Can craft tabs): gold and underlined when active.
local function CreateToggle()
  local b = CreateFrame("Button", nil, content)
  b:SetSize(110, 22)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("CENTER")
  b.under = b:CreateTexture(nil, "ARTWORK")
  b.under:SetHeight(2)
  b.under:SetPoint("BOTTOMLEFT")
  b.under:SetPoint("BOTTOMRIGHT")
  b.under:SetColorTexture(1, 0.82, 0, 1)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b:SetScript("OnClick", function(self) if self.fn and not self.active then self.fn() end end)
  return b
end

local function Toggle(x, y, text, active, enabled, fn)
  local b = Acquire(toggles, CreateToggle)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
  b.label:SetText(text)
  b.active, b.fn = active, enabled and fn or nil
  b.bg:SetColorTexture(active and 0.35 or 0.12, active and 0.27 or 0.1, active and 0.12 or 0.08, 0.9)
  b.label:SetTextColor(active and 1 or 0.6, active and 0.82 or 0.6, active and 0 or 0.6)
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
  r.level:SetText(("%d -> %d"):format(p.rank or 0, p.max or 0))
  r.bar:SetMinMaxValues(0, math.max(1, p.max or 1))
  r.bar:SetValue(p.rank or 0)

  r.shop.key, r.shop.line = key, p.skillLine
  r.shop:SetShown(ns.CanShop() and need ~= nil and next(need.items or {}) ~= nil)

  -- Folding only makes sense with every profession listed ("All"); a filtered view is open.
  local filtered = ComradeCraftDB.ui.prof ~= nil
  local collapsed = not filtered and Collapsed(p.skillLine)
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
    yy = yy + 2 + PlaceStep(PROF_W, y - yy, RIGHT_W, { kind = "range", from = step.from, to = step.to, cost = step.cost }, own)
    for _, e in ipairs(step.entries) do yy = yy + PlaceStep(PROF_W + 4, y - yy, RIGHT_W - 4, e, own) end
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

  -- Cost per milestone: both routes, what they cost, bring back, and the net.
  local ms = ns.MilestoneRows(need)
  if ms then
    yy = yy + 4 + PlaceStep(PROF_W, y - yy, RIGHT_W, { kind = "range", from = 0, to = 0, header = ms.header }, own)
    yy = yy + PlaceStep(PROF_W, y - yy, RIGHT_W, { kind = "milestone", cols = { "|cff8f8f8f" .. L["Skill"] .. "|r",
      "|cff8f8f8f" .. L["Route"] .. "|r", "|cff8f8f8f" .. L["Mats"] .. "|r", "|cff8f8f8f" .. L["Sold back"] .. "|r",
      "|cff8f8f8f" .. L["Net cost"] .. "|r" } }, own)
    for _, row in ipairs(ms.rows) do
      for i, rt in ipairs(row.routes) do
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
            { L["Disenchanted"], Way("de") }, { L["At the auction house (-5%)"], Way("ah") },
            { L["Best way per item"], ShortMoney(m.best) }, { L["Net cost"], cols[5] } }
        end
        yy = yy + PlaceStep(PROF_W, y - yy, RIGHT_W, { kind = "milestone", cols = cols, tip = tip }, own)
      end
    end
    local _, nh = Label(PROF_W, y - yy - 2, "|cff7f7f7f" .. L["Net cost = mats minus the best resale of each item. A green + is a profit. Hover a line for the details."] .. "|r", "GameFontDisableSmall", RIGHT_W)
    yy = yy + nh + 8
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
  local why = mode == "profit"
    and L["Picks recipes whose products sell back well. More crafts, so more mats: tooltips, the give list, mail and shopping all follow this route."]
    or L["Spends the least on mats."]
  if c.peer then why = why .. " " .. L["Chosen by its owner."] end
  local _, hh = Label(296, y - 5, "|cff9d9d9d" .. why .. "|r", nil, LIST_W - 296)
  y = y - math.max(30, hh + 12)
  local own = key == ns.CharKey()
  local plist = SortedKeys(c.professions or {})
  if #plist == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No profession data. Open your profession windows."] .. "|r")
    return h
  end
  for _, pname in ipairs(plist) do
    if LineVisible(c.professions[pname].skillLine) then
      y = y - LayoutProfession(y, pname, c.professions[pname], c, own, key)
    end
  end
  if y == 0 then
    local _, h = Label(0, 0, "|cff9d9d9d" .. L["No profession matches the filter."] .. "|r")
    return h
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
    for _, e in ipairs(list) do
      PlaceRecipe(8, y, e, RecipeTags(e), L[e.category], own).requestTo = c.peer and key or nil
      y = y - RECIPE_H
    end
    y = y - 8
  end
  return -y
end

-- Group view: skill table, most wanted materials, or "who can craft" search results.
local function RenderGroup(filter)
  local chars = ns.AllChars()
  local keys = SortedKeys(chars)
  local y = 0
  if filter ~= "" then
    local _, h = Label(0, y, "|cffffd100" .. L["Who can craft \"%s\""]:format(filter) .. "|r", "GameFontNormal")
    y = y - h - 6
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
    for _, f in ipairs(list) do
      any = true
      local e = { spell = f.e.spell, item = f.e.item, color = "yellow", name = f.e.name }
      PlaceRecipe(8, y, e, table.concat(f.who, ", "), nil, false).name:SetText(f.e.name)
      y = y - RECIPE_H
    end
    if not any then
      local _, h2 = Label(0, y, "|cff9d9d9d" .. L["No recipe matches."] .. "|r")
      y = y - h2
    end
    return -y
  end

  -- "You can give": the current character's spare items that someone else needs.
  local give = ns.GiveList(ns.CharKey())
  if #give > 0 then
    local _, hg = Label(0, y, "|cffffd100" .. L["You can give"] .. "|r  |cff9d9d9d"
      .. L["Spare items in your bags that others need. With a mailbox open, click one to prepare the mail."] .. "|r", "GameFontNormal")
    y = y - hg - 6
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

  -- "Disenchant or keep?": the current character's disenchantable bag items, with a verdict.
  local advice = ns.BagAdvice(ns.CharKey())
  if #advice > 0 then
    local _, ha = Label(0, y, "|cffffd100" .. L["Disenchant or keep?"] .. "|r  |cff9d9d9d"
      .. L["Green and better items in your bags. Yields are estimates until your disenchants are logged."] .. "|r",
      "GameFontNormal")
    y = y - ha - 6
    local width = math.floor((LIST_W - 8) / 2)
    local myBags = (ComradeCraftDB.chars[ns.CharKey()] or {}).bags or {}
    local shown = math.min(#advice, 12)
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
      PlaceMat(col * (width + 4), y - line * (MAT_H + 4), a.item, myBags[a.item] or 1, text, width)
    end
    y = y - math.ceil(shown / 2) * (MAT_H + 4) - 10
  end

  -- Skill table: one line per character.
  local _, h = Label(0, y, "|cffffd100" .. L["Skill levels"] .. "|r", "GameFontNormal")
  y = y - h - 6
  for _, key in ipairs(keys) do
    local c = chars[key]
    local parts = {}
    for _, pname in ipairs(SortedKeys(c.professions or {})) do
      local p = c.professions[pname]
      if LineVisible(p.skillLine) then parts[#parts + 1] = ("%s %d/%d"):format(pname, p.rank or 0, p.max or 0) end
    end
    if #parts > 0 or not ComradeCraftDB.ui.prof then
      Label(0, y, ns.ClassColored(key, c.class) .. (c.spec and ("  |cff9d9d9d" .. c.spec .. "|r") or ""),
        "GameFontHighlight", 170)
      local _, h2 = Label(180, y, table.concat(parts, "   "), "GameFontHighlightSmall", LIST_W - 180)
      y = y - math.max(16, h2) - 4
    end
  end

  y = y - 10
  local _, h3 = Label(0, y, "|cffffd100" .. L["Most wanted materials"] .. "|r", "GameFontNormal")
  y = y - h3 - 6
  local mats_ = ns.GroupMaterials(LineVisible)
  if #mats_ == 0 then
    local _, h4 = Label(0, y, "|cff9d9d9d" .. L["Nothing missing yet."] .. "|r")
    return -y + h4
  end
  local width = math.floor((LIST_W - 8) / 3)
  for i = 1, math.min(#mats_, 30) do
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
  y = y - math.ceil(math.min(#mats_, 30) / 3) * (MAT_H + 4)
  return -y
end

-- Sidebar ---------------------------------------------------------------------------------

local function CreateSideBtn()
  local b = CreateFrame("Button", nil, side)
  b:SetWidth(SIDE_LIST_W - 4)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.sel = b:CreateTexture(nil, "BACKGROUND")
  b.sel:SetAllPoints()
  b.sel:SetColorTexture(0.4, 0.3, 0.1, 0.5)
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.name:SetPoint("TOPLEFT", 6, -4)
  b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.sub:SetPoint("TOPLEFT", 6, -20)
  b.sub:SetWidth(SIDE_LIST_W - 16)
  b.sub:SetJustifyH("LEFT")
  b:SetScript("OnClick", function(self)
    if self.peerID then
      ns.Sync.Include(self.peerID) -- a suggestion: click adds that player to the group
    elseif self.key then
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
    y = y - h - 4
  end
  Add("group", L["Group"], ns.Plural(#SortedKeys(chars), "%d member", "%d members"))
  local inGroup, requests = 0, 0
  for _, peer in pairs(ComradeCraftDB.peers or {}) do
    if peer.included then inGroup = inGroup + 1 elseif peer.asked then requests = requests + 1 end
  end
  Add("manage", L["Manage group"], ns.Plural(inGroup, "%d player", "%d players")
    .. (requests > 0 and ("  |cff80ff80" .. ns.Plural(requests, "%d request", "%d requests") .. "|r") or ""))
  local open = ns.Requests and ns.Requests.OpenCount() or 0
  Add("requests", L["Craft requests"], open > 0 and ("|cff80ff80" .. ns.Plural(open, "%d to answer", "%d to answer") .. "|r")
    or ("|cff9d9d9d" .. L["none open"] .. "|r"))
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

-- Section title + one-line explanation; returns the new y.
local function Section(y, title, help)
  local _, h = Label(0, y, "|cffffd100" .. title .. "|r", "GameFontNormalLarge")
  y = y - h - 2
  if help then
    local _, h2 = Label(0, y, "|cff9d9d9d" .. help .. "|r")
    y = y - h2
  end
  return y - 8
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
  for _, key in ipairs(SortedKeys(db.chars)) do
    local c = db.chars[key]
    Check(0, y + 2, c.shared, function(on) Sync.SetShared(key, on) end)
    Label(30, y - 4, ns.ClassColored(key, c.class) .. "  |cff9d9d9d" .. LevelSpecClass(c) .. "|r", "GameFontHighlight")
    y = y - 28
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

  y = Section(y - 10, L["Requests and suggestions"],
    L["Players with ComradeCraft in your guild, or who added you. Add them to share both ways."])
  if #others == 0 then
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

  y = Section(y - 10, L["Add a player by name"], L["For friends outside your guild. They must add you back."])
  frame.addBox:ClearAllPoints()
  frame.addBox:SetPoint("TOPLEFT", content, "TOPLEFT", 6, y)
  frame.addBox:Show()
  Action(200, y + 1, L["Add"], function()
    local name = frame.addBox:GetText()
    if name and name ~= "" then
      ns.commands.add(name)
      frame.addBox:SetText("")
    end
  end)
  y = y - 34

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

  y = Section(y - 6, L["Alerts"], L["A chat line and a short notice at the top of the screen."])
  for _, a in ipairs({ { "mats", L["Your bags hold the mats for your next craft."] },
    { "cooldown", L["A profession cooldown is ready on one of your characters."] },
    { "requests", L["A craft request arrives or changes."] },
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
  { L["Craft requests"], L["Click a recipe in a group member's Can craft tab to ask for it. Answer what you are asked in Craft requests. Requests reach the other player the next time you are both online (or by mail, if turned on in Manage group)."] },
  { L["Tooltips"], L["On any material: who in the group needs it, how many, and how soon (now, soon, later). Spare stock in the group is shown too."] },
  { L["Step panel"], L["Next to your profession window: the current step, the chance per craft, how many crafts your bags allow, and what comes next."] },
  { L["Giving and mail"], L["You can give lists what you hold that others need. At a mailbox, the button beside the send frame attaches it. Nothing is ever sent for you."] },
  { L["Disenchant or keep"], L["Your green items: keep one per slot your enchanting plan needs, keep upgrades for group members, sell what is worth more than its mats, disenchant the rest."] },
  { L["Shopping"], L["The Shopping list button makes an Auctionator list, or a TSM search and group to paste. TSM groups that are done are pointed out."] },
  { L["Sharing"], L["Nothing is shared until you check a character in Manage group, and only with players you added who added you back."] },
  { L["Better with"], L["TSM or Auctionator (prices), Pawn (upgrades for each class and spec). All optional."] },
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

-- Refresh ---------------------------------------------------------------------------------

-- Filter row: "All" + one chip per profession present in the group, and "Hide gathering".
local chips = {}
local function CreateChip()
  local b = CreateFrame("Button", nil, frame)
  b:SetHeight(20)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.label:SetPoint("CENTER")
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b:SetScript("OnClick", function(self)
    ComradeCraftDB.ui.prof = self.line
    ns.RefreshWindow()
  end)
  return b
end

local function RenderChips(chars)
  ReleaseAll(chips)
  local ui = ComradeCraftDB.ui
  local names, lines = {}, {}
  for _, c in pairs(chars) do
    for pname, p in pairs(c.professions or {}) do
      local line = p.skillLine
      if line and not names[line] and not (ui.hideGathering ~= false and ns.GATHERING[line]) then
        names[line] = pname
        lines[#lines + 1] = line
      end
    end
  end
  table.sort(lines, function(a, b) return names[a] < names[b] end)
  if ui.prof and not names[ui.prof] then ui.prof = nil end
  local x = DETAIL_X
  local function Chip(line, text)
    local b = Acquire(chips, CreateChip)
    b.line = line
    b.label:SetText(text)
    local active = ui.prof == line
    b.label:SetTextColor(active and 1 or 0.75, active and 0.82 or 0.75, active and 0 or 0.75)
    b.bg:SetColorTexture(active and 0.35 or 0.12, active and 0.27 or 0.1, active and 0.12 or 0.08, 0.9)
    local w = math.max(40, (b.label:GetStringWidth() or 40) + 16)
    b:SetWidth(w)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -140)
    x = x + w + 4
  end
  Chip(nil, L["All"])
  for _, line in ipairs(lines) do Chip(line, names[line]) end
  frame.gatherBox:ClearAllPoints()
  frame.gatherBox:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 8, -138)
  frame.gatherBox:SetChecked(ui.hideGathering ~= false)
  frame.gatherBox:Show()
end

function ns.RefreshWindow()
  if not (frame and frame:IsShown()) then return end
  local ui = ComradeCraftDB.ui
  local chars = ns.AllChars()
  if ui.sel ~= "group" and ui.sel ~= "manage" and ui.sel ~= "help" and ui.sel ~= "requests" and not chars[ui.sel or ""] then
    ui.sel = chars[ns.CharKey()] and ns.CharKey() or "group"
  end
  ReleaseAll(rows) ReleaseAll(mats) ReleaseAll(steps) ReleaseAll(recipes) ReleaseAll(labels)
  ReleaseAll(actionBtns) ReleaseAll(checks) ReleaseAll(toggles) ReleaseAll(heads)
  frame.addBox:Hide()
  RenderSide(ui.sel)

  local filter = (frame.search:GetText() or ""):lower()
  local h
  if ui.sel == "requests" then
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
    frame.search:Show()
    RenderChips(chars)
    frame.title:SetText(L["Group"])
    frame.sub:SetText(L["Skill levels and the materials the group still needs. Type to find who can craft something."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    frame.removeBtn:Hide()
    frame.shareBox:Hide()
    h = RenderGroup(filter)
  else
    frame.search:Show()
    RenderChips(chars)
    local c = chars[ui.sel]
    frame.title:SetText(ns.ClassColored(ui.sel, c.class))
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
      h = RenderCraft(ui.sel, c, filter)
    else
      h = RenderPlan(ui.sel, c)
    end
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
  f:SetPoint("CENTER")
  -- Same layer as the game's windows: the profession window can come in front of it.
  f:SetFrameStrata("MEDIUM")
  f:SetToplevel(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:Hide()
  if ButtonFrameTemplate_HideButtonBar then pcall(ButtonFrameTemplate_HideButtonBar, f) end
  if f.SetTitle then f:SetTitle("ComradeCraft")
  elseif f.TitleText then f.TitleText:SetText("ComradeCraft") end
  if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, "Interface\\Icons\\INV_Misc_Bag_10") end
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
  sep:SetPoint("TOPLEFT", DETAIL_X - 6, -64)
  sep:SetPoint("BOTTOMLEFT", DETAIL_X - 6, 36)

  -- Right: header, tabs, search, scrolling detail.
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  f.title:SetPoint("TOPLEFT", DETAIL_X, -66)
  f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -4)
  f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.badge:SetPoint("TOPRIGHT", -24, -68)
  -- "?" opens the help view (click again to go back to the group).
  f.helpBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.helpBtn:SetSize(24, 22)
  f.helpBtn:SetPoint("TOPRIGHT", -24, -36)
  f.helpBtn:SetText("?")
  f.helpBtn:SetScript("OnClick", function()
    local ui = ComradeCraftDB.ui
    ui.sel = ui.sel == "help" and "group" or "help"
    ns.RefreshWindow()
  end)

  -- Flat tabs: the active one is gold, lighter and underlined; the other stays grey.
  local function Tab(text, tab, anchor)
    local b = CreateFrame("Button", nil, f)
    b:SetSize(120, 24)
    b:SetPoint(unpack(anchor))
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.label:SetPoint("CENTER")
    b.label:SetText(text)
    b.under = b:CreateTexture(nil, "ARTWORK")
    b.under:SetHeight(2)
    b.under:SetPoint("BOTTOMLEFT")
    b.under:SetPoint("BOTTOMRIGHT")
    b.under:SetColorTexture(1, 0.82, 0, 1)
    b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    function b:SetActive(on)
      self.bg:SetColorTexture(on and 0.35 or 0.12, on and 0.27 or 0.1, on and 0.12 or 0.08, 0.9)
      self.label:SetTextColor(on and 1 or 0.6, on and 0.82 or 0.6, on and 0 or 0.6)
      self.under:SetShown(on)
    end
    b:SetScript("OnClick", function()
      ComradeCraftDB.ui.tab = tab
      ns.RefreshWindow()
    end)
    return b
  end
  f.planTab = Tab(L["Plan"], "plan", { "TOPLEFT", DETAIL_X, -112 })
  f.craftTab = Tab(L["Can craft"], "craft", { "TOPLEFT", DETAIL_X + 126, -112 })

  -- Shown on this account's characters: opt-in sharing (nothing is sent until checked).
  f.shareBox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  f.shareBox:SetSize(22, 22)
  f.shareBox:SetPoint("TOPRIGHT", -230, -88)
  f.shareBox.label = f.shareBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.shareBox.label:SetPoint("LEFT", f.shareBox, "RIGHT", 2, 0)
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
  search:HookScript("OnTextChanged", function() ns.RefreshWindow() end)
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

  -- Manage view: add a player by name (Enter or the Add button).
  f.addBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
  f.addBox:SetSize(180, 20)
  f.addBox:SetAutoFocus(false)
  f.addBox:SetScript("OnEnterPressed", function(self)
    local name = self:GetText()
    if name and name ~= "" then
      ns.commands.add(name)
      self:SetText("")
    end
    self:ClearFocus()
  end)
  f.addBox:Hide()

  f.foot = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  f.foot:SetPoint("BOTTOMLEFT", 20, 14)
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
    icon = "Interface\\Icons\\INV_Misc_Bag_10",
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
