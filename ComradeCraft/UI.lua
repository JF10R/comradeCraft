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
local ROW_PAD, STEP_H, RECIPE_H = 8, 18, 20
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
local sideBtns, rows, mats, steps, recipes, labels = {}, {}, {}, {}, {}, {}

local function CreateLabel()
  local fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetJustifyH("LEFT")
  return fs
end

local function Label(x, y, text, font, width)
  local fs = Acquire(labels, CreateLabel)
  fs:SetFontObject(font or "GameFontHighlightSmall")
  fs:ClearAllPoints()
  fs:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
  fs:SetWidth(width or (LIST_W - x))
  fs:SetText(text)
  return fs, math.max(12, fs:GetStringHeight() or 12)
end

-- One plan entry: a skill range header, or a clickable "learn"/"craft" line with an icon.
local function CreateStep()
  local b = CreateFrame("Button", nil, content)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(16, 16)
  b.icon:SetPoint("TOPLEFT", 0, -1)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("TOPLEFT", 20, -3)
  b.text:SetWidth(RIGHT_W - 34)
  b.text:SetJustifyH("LEFT")
  b:SetScript("OnEnter", function(self)
    if self.entry and self.entry.kind ~= "range" then ShowItemTooltip(self, self.entry.item, self.entry.spell) end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    local e = self.entry
    if not e or e.kind == "range" or LinkOnShiftClick(e.item) then return end
    if e.kind == "craft" and self.own then ns.OpenRecipe(e.spell) end
  end)
  return b
end

local function CreateRow()
  local r = CreateFrame("Frame", nil, content)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(32, 32)
  r.icon:SetPoint("TOPLEFT", 6, -6)
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1)
  r.level = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.level:SetPoint("TOPRIGHT", r, "TOPLEFT", PROF_W - 8, -8)
  r.bar = CreateFrame("StatusBar", nil, r)
  r.bar:SetSize(PROF_W - 54, 8)
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
  b:SetScript("OnClick", function(self) LinkOnShiftClick(self.itemID) end)
  return b
end

local function PlaceMat(x, y, item, count, sub, width)
  local m = Acquire(mats, CreateMat)
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

-- One known recipe in the "can craft" lists: icon, name in its difficulty color, category,
-- and who it helps. Click opens it (own character), shift-click links it.
local function CreateRecipe()
  local b = CreateFrame("Button", nil, content)
  b:SetHeight(RECIPE_H)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(18, 18)
  b.icon:SetPoint("LEFT", 0, 0)
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("LEFT", 24, 0)
  b.name:SetWidth(240)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.tags = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.tags:SetPoint("LEFT", 270, 0)
  b.tags:SetPoint("RIGHT", -4, 0)
  b.tags:SetJustifyH("LEFT")
  b.tags:SetWordWrap(false)
  b:SetScript("OnEnter", function(self) ShowItemTooltip(self, self.item, self.spell) end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if not LinkOnShiftClick(self.item) and self.own then ns.OpenRecipe(self.spell) end
  end)
  return b
end

local function PlaceRecipe(x, y, e, tags, own)
  local b = Acquire(recipes, CreateRecipe)
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
  b:SetWidth(LIST_W - x)
  b.spell, b.item, b.own = e.spell, e.item, own
  local icon = e.item ~= 0 and select(3, ItemInfo(e.item))
    or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(e.spell)) or 134400
  b.icon:SetTexture(icon)
  b.name:SetText(("|cff%s%s|r"):format(COLOR[e.color] or "ffffff", e.name or ns.SpellName(e.spell)))
  b.tags:SetText(tags or "")
  return b
end

-- Views ---------------------------------------------------------------------------------

-- Plan tab: one block per profession (status, clickable plan, cost, mats, vendor, blocked).
local function LayoutProfession(y, name, p, c, own)
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

  local d = ns.DescribeNeed(p, c)
  local top = {}
  if d.status then top[#top + 1] = "|cff9d9d9d" .. d.status .. "|r" end
  if d.steps and #d.steps > 0 then top[#top + 1] = "|cffffd100" .. L["What to craft:"] .. "|r" end
  r.top:SetText(table.concat(top, "\n"))
  local yy = 8 + (#top > 0 and (r.top:GetStringHeight() + 4) or 0)

  for _, step in ipairs(d.steps or {}) do
    local list = { { kind = "range", text = "|cffffd100" .. step.range .. "|r" } }
    for _, e in ipairs(step.entries) do list[#list + 1] = e end
    for _, e in ipairs(list) do
      local s = Acquire(steps, CreateStep)
      s.entry, s.own = e, own
      s:ClearAllPoints()
      s:SetPoint("TOPLEFT", content, "TOPLEFT", PROF_W + (e.kind == "range" and 0 or 12), y - yy)
      s:SetWidth(RIGHT_W - 12)
      if e.kind == "range" then
        s.icon:Hide()
      else
        s.icon:Show()
        s.icon:SetTexture(e.item and e.item ~= 0 and select(3, ItemInfo(e.item))
          or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(e.spell)) or 134400)
      end
      s.text:SetText(e.kind == "learn" and ("|cff66ccff" .. e.text .. "|r") or e.text)
      local h = math.max(STEP_H, (s.text:GetStringHeight() or 0) + 6)
      s:SetHeight(h)
      yy = yy + h
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

  local items = need and SortedKeys(need.items) or {}
  for i, item in ipairs(items) do
    local col, line = (i - 1) % MAT_COLS, math.floor((i - 1) / MAT_COLS)
    PlaceMat(PROF_W + col * (MAT_W + 4), y - yy - line * (MAT_H + 4), item, need.items[item],
      L["Owned: %d / %d"]:format(need.have[item] or 0, need.gross[item] or 0))
  end
  if #items > 0 then yy = yy + math.ceil(#items / MAT_COLS) * (MAT_H + 4) + 2 end

  local bottom = {}
  if d.vendor then bottom[#bottom + 1] = "|cffb0b0b0" .. d.vendor .. "|r" end
  if d.blocked then bottom[#bottom + 1] = "|cffff9933" .. d.blocked .. "|r" end
  r.bottom:ClearAllPoints()
  r.bottom:SetPoint("TOPLEFT", r, "TOPLEFT", PROF_W, -yy)
  r.bottom:SetText(table.concat(bottom, "\n"))
  if #bottom > 0 then yy = yy + r.bottom:GetStringHeight() + 4 end

  local h = math.max(48, yy + ROW_PAD)
  r:SetHeight(h)
  return h
end

local function RenderPlan(key, c)
  local y = 0
  local own = key == ns.CharKey()
  local plist = SortedKeys(c.professions or {})
  if #plist == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No profession data. Open your profession windows."] .. "|r")
    return h
  end
  for _, pname in ipairs(plist) do
    y = y - LayoutProfession(y, pname, c.professions[pname], c, own)
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
  for _, k in ipairs(e.fits) do t[#t + 1] = "|cff66ccff" .. L["gear for %s"]:format(ShortName(k)) .. "|r" end
  t[#t + 1] = "|cff9d9d9d" .. L[e.category] .. "|r"
  return table.concat(t, "  ")
end

-- Can craft tab: known recipes by profession; helps-the-group and fits-someone first.
local function RenderCraft(key, c, filter)
  local y = 0
  local own = key == ns.CharKey()
  local byLine, nameOf = {}, {}
  for pname, p in pairs(c.professions or {}) do
    if p.skillLine then nameOf[p.skillLine] = pname end
  end
  for _, e in ipairs(ns.CraftCatalog(key)) do
    if Matches(e, filter) then
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
    local _, h = Label(0, y, ("|cffffd100%s|r  |cff9d9d9d%s|r"):format(nameOf[line] or tostring(line),
      ns.Plural(#list, "%d recipe", "%d recipes")), "GameFontNormal")
    y = y - h - 4
    for _, e in ipairs(list) do
      PlaceRecipe(8, y, e, RecipeTags(e), own)
      y = y - RECIPE_H
    end
    y = y - 8
  end
  return -y
end

-- Group view: skill table, most wanted materials, or "who can craft" search results.
local function RenderGroup(filter)
  local chars = ComradeCraftDB.chars
  local keys = SortedKeys(chars)
  local y = 0
  if filter ~= "" then
    local _, h = Label(0, y, "|cffffd100" .. L["Who can craft \"%s\""]:format(filter) .. "|r", "GameFontNormal")
    y = y - h - 6
    local found, any = {}, false
    for _, key in ipairs(keys) do
      for _, e in ipairs(ns.CraftCatalog(key)) do
        if Matches(e, filter) then
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
      PlaceRecipe(8, y, e, table.concat(f.who, ", "), false).name:SetText(f.e.name)
      y = y - RECIPE_H
    end
    if not any then
      local _, h2 = Label(0, y, "|cff9d9d9d" .. L["No recipe matches."] .. "|r")
      y = y - h2
    end
    return -y
  end

  -- Skill table: one line per character.
  local _, h = Label(0, y, "|cffffd100" .. L["Skill levels"] .. "|r", "GameFontNormal")
  y = y - h - 6
  for _, key in ipairs(keys) do
    local c = chars[key]
    local parts = {}
    for _, pname in ipairs(SortedKeys(c.professions or {})) do
      local p = c.professions[pname]
      parts[#parts + 1] = ("%s %d/%d"):format(pname, p.rank or 0, p.max or 0)
    end
    Label(0, y, ns.ClassColored(key, c.class), "GameFontHighlight", 130)
    local _, h2 = Label(140, y, table.concat(parts, "   "), "GameFontHighlightSmall", LIST_W - 140)
    y = y - math.max(16, h2) - 4
  end

  y = y - 10
  local _, h3 = Label(0, y, "|cffffd100" .. L["Most wanted materials"] .. "|r", "GameFontNormal")
  y = y - h3 - 6
  local mats_ = ns.GroupMaterials()
  if #mats_ == 0 then
    local _, h4 = Label(0, y, "|cff9d9d9d" .. L["Nothing missing yet."] .. "|r")
    return -y + h4
  end
  local width = math.floor((LIST_W - 8) / 3)
  for i = 1, math.min(#mats_, 30) do
    local a = mats_[i]
    local by = {}
    for _, b in ipairs(a.by) do by[#by + 1] = ("%s %d"):format(ShortName(b.key), b.n) end
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
    ComradeCraftDB.ui.sel = self.key
    ns.RefreshWindow()
  end)
  return b
end

local function RenderSide(sel)
  ReleaseAll(sideBtns)
  local chars = ComradeCraftDB.chars
  local y = -2
  local function Add(key, name, sub)
    local b = Acquire(sideBtns, CreateSideBtn)
    b.key = key
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
  for _, key in ipairs(SortedKeys(chars)) do
    local c = chars[key]
    local lines = { ("%s %s"):format(c.level and L["Lvl %d"]:format(c.level) or "", ClassName(c)) }
    for _, pname in ipairs(SortedKeys(c.professions or {})) do
      local p = c.professions[pname]
      local pct = (p.max or 0) > 0 and (p.rank or 0) / p.max or 0
      lines[#lines + 1] = ("%s |cff%s%d/%d|r"):format(pname, pct >= 1 and "40c040" or "ffd100", p.rank or 0, p.max or 0)
    end
    Add(key, ns.ClassColored(key, c.class), table.concat(lines, "\n"))
  end
  side:SetHeight(math.max(1, -y))
end

-- Refresh ---------------------------------------------------------------------------------

function ns.RefreshWindow()
  if not (frame and frame:IsShown()) then return end
  local ui = ComradeCraftDB.ui
  local chars = ComradeCraftDB.chars
  if ui.sel ~= "group" and not chars[ui.sel or ""] then ui.sel = chars[ns.CharKey()] and ns.CharKey() or "group" end
  ReleaseAll(rows) ReleaseAll(mats) ReleaseAll(steps) ReleaseAll(recipes) ReleaseAll(labels)
  RenderSide(ui.sel)

  local filter = (frame.search:GetText() or ""):lower()
  local h
  if ui.sel == "group" then
    frame.title:SetText(L["Group"])
    frame.sub:SetText(L["Skill levels and the materials the group still needs. Type to find who can craft something."])
    frame.planTab:Hide()
    frame.craftTab:Hide()
    h = RenderGroup(filter)
  else
    local c = chars[ui.sel]
    frame.title:SetText(ns.ClassColored(ui.sel, c.class))
    frame.sub:SetText(("%s %s - %s"):format(c.level and L["Lvl %d"]:format(c.level) or "", ClassName(c),
      L["updated %s"]:format(Ago(c.updated))))
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
end

local function CreateWindow()
  local ok, f = pcall(CreateFrame, "Frame", "ComradeCraftFrame", UIParent, "ButtonFrameTemplate")
  if not ok or not f then
    f = CreateFrame("Frame", "ComradeCraftFrame", UIParent, "BasicFrameTemplateWithInset")
  end
  f:SetSize(W, H)
  f:SetPoint("CENTER")
  f:SetFrameStrata("HIGH")
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

  local ok2, search = pcall(CreateFrame, "EditBox", nil, f, "SearchBoxTemplate")
  if not ok2 or not search then search = CreateFrame("EditBox", nil, f, "InputBoxTemplate") end
  search:SetSize(200, 20)
  search:SetPoint("TOPRIGHT", -30, -112)
  search:SetAutoFocus(false)
  search:HookScript("OnTextChanged", function() ns.RefreshWindow() end)
  f.search = search

  local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", DETAIL_X, -142)
  scroll:SetPoint("BOTTOMRIGHT", -34, 36)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(LIST_W, 1)
  scroll:SetScrollChild(content)

  local foot = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  foot:SetPoint("BOTTOMLEFT", 20, 14)
  foot:SetText(L["Local data (characters on this account). skill ~N: value taken from Classic, unconfirmed."])
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
end

-- Item names load asynchronously; redraw once they arrive (coalesced).
local pending = false
ns.On("GET_ITEM_INFO_RECEIVED", function()
  if pending or not (frame and frame:IsShown()) then return end
  pending = true
  C_Timer.After(0.2, function() pending = false ns.RefreshWindow() end)
end)

ns.commands.show = ns.ToggleWindow

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
      tt:AddLine(L["Click: group needs"], 1, 1, 1)
    end,
  })
  ComradeCraftDB.minimap = ComradeCraftDB.minimap or {}
  Icon:Register("ComradeCraft", obj, ComradeCraftDB.minimap)
end)
