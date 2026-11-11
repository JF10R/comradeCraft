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
  b.name:SetWidth(240)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.tags = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.tags:SetPoint("TOPLEFT", 276, -2)
  b.tags:SetPoint("RIGHT", -4, 0)
  b.tags:SetJustifyH("LEFT")
  b.tags:SetWordWrap(false)
  b.mats = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.mats:SetPoint("TOPLEFT", 30, -16)
  b.mats:SetPoint("RIGHT", -4, 0)
  b.mats:SetJustifyH("LEFT")
  b.mats:SetWordWrap(false)
  b:SetScript("OnEnter", function(self) ShowItemTooltip(self, self.item, self.spell) end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if IsModifiedClick and IsModifiedClick("CHATLINK") then
      local link = ns.RecipeLink(self.spell, self.item)
      if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
    elseif self.own then
      ns.OpenRecipe(self.spell)
    end
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
  local cost = ns.CostText(ns.RecipeCost(e.spell, 1))
  b.mats:SetText(ns.ReagentText(e.spell, 1) .. (cost and ("  |cffffd100" .. cost .. "|r") or ""))
  return b
end

-- Views ---------------------------------------------------------------------------------

-- Plan tab: one block per profession (status, clickable plan, cost, mats, vendor, blocked).
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
      PlaceRecipe(8, y, e, table.concat(f.who, ", "), false).name:SetText(f.e.name)
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

local actionBtns, checks = {}, {}

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
  if ui.sel ~= "group" and ui.sel ~= "manage" and not chars[ui.sel or ""] then
    ui.sel = chars[ns.CharKey()] and ns.CharKey() or "group"
  end
  ReleaseAll(rows) ReleaseAll(mats) ReleaseAll(steps) ReleaseAll(recipes) ReleaseAll(labels)
  ReleaseAll(actionBtns) ReleaseAll(checks)
  frame.addBox:Hide()
  RenderSide(ui.sel)

  local filter = (frame.search:GetText() or ""):lower()
  local h
  if ui.sel == "manage" then
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
