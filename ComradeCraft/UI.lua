-- UI: "Besoins du groupe" window. Blizzard templates only; layout follows ComradeCraft_concept_v1.html.
local _, ns = ...

local W, H = 760, 600
local LIST_W = W - 48
local PROF_W = 230
local MAT_W, MAT_H, MAT_COLS = 236, 40, 2
local RIGHT_W = LIST_W - PROF_W - 8 -- text column right of the profession block
local HEAD_H, ROW_PAD = 28, 8

local frame, content, sections

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
  if not t then return "jamais" end
  local m = math.floor((time() - t) / 60)
  if m < 1 then return ns.L["just now"] end
  if m < 60 then return ns.L["%d min ago"]:format(m) end
  return ns.L["%d h ago"]:format(math.floor(m / 60))
end

local headers, rows, mats, steps = {}, {}, {}, {}
local STEP_H = 18

-- One plan entry: a skill range header, or a clickable "learn"/"craft" line with an icon.
-- Click opens the recipe (craft), shift-click links the item, hover shows its tooltip.
local function CreateStep()
  local b = CreateFrame("Button", nil, content)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(16, 16)
  b.icon:SetPoint("TOPLEFT", 0, -1)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("TOPLEFT", 20, -3)
  b.text:SetWidth(RIGHT_W - 22)
  b.text:SetJustifyH("LEFT")
  b:SetScript("OnEnter", function(self)
    if not self.entry or self.entry.kind == "range" then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.entry.item and self.entry.item ~= 0 then
      GameTooltip:SetItemByID(self.entry.item)
    elseif GameTooltip.SetSpellByID then
      GameTooltip:SetSpellByID(self.entry.spell)
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    local e = self.entry
    if not e or e.kind == "range" then return end
    if IsModifiedClick and IsModifiedClick("CHATLINK") and e.item and e.item ~= 0 then
      local _, link = ItemInfo(e.item)
      if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
    elseif e.kind == "craft" then
      ns.OpenRecipe(e.spell)
    end
  end)
  return b
end

local function CreateHeader()
  local b = CreateFrame("Button", nil, content)
  b:SetSize(LIST_W, HEAD_H)
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.25, 0.19, 0.13, 0.85)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.toggle = b:CreateTexture(nil, "ARTWORK")
  b.toggle:SetSize(14, 14)
  b.toggle:SetPoint("LEFT", 8, 0)
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  b.name:SetPoint("LEFT", b.toggle, "RIGHT", 8, 0)
  b.desc = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.desc:SetPoint("LEFT", b.name, "RIGHT", 10, 0)
  b.sync = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.sync:SetPoint("RIGHT", -10, 0)
  b:SetScript("OnClick", function(self)
    local ui = ComradeCraftDB.ui
    ui.collapsed[self.key] = not ui.collapsed[self.key] or nil
    ns.RefreshWindow()
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
  -- top: status or crafting plan; bottom: vendor purchases + why it is blocked.
  r.top = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.top:SetPoint("TOPLEFT", r, "TOPLEFT", PROF_W, -8)
  r.top:SetWidth(RIGHT_W)
  r.top:SetJustifyH("LEFT")
  r.bottom = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.bottom:SetWidth(RIGHT_W)
  r.bottom:SetJustifyH("LEFT")
  r.mid = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") -- stock used, known-only
  r.mid:SetWidth(RIGHT_W)
  r.mid:SetJustifyH("LEFT")
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
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(self.itemID)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    local _, link = ItemInfo(self.itemID)
    if link and IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
      ChatEdit_InsertLink(link)
    end
  end)
  return b
end

local function SortedKeys(t, less)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, less)
  return keys
end

-- Lays out one profession row; returns its height.
local function LayoutProfession(y, name, p, c)
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
  if d.steps and #d.steps > 0 then top[#top + 1] = "|cffffd100" .. ns.L["What to craft:"] .. "|r" end
  r.top:SetText(table.concat(top, "\n"))
  local yy = 8 + (#top > 0 and (r.top:GetStringHeight() + 4) or 0)

  for _, step in ipairs(d.steps or {}) do
    local list = { { kind = "range", text = "|cffffd100" .. step.range .. "|r" } }
    for _, e in ipairs(step.entries) do list[#list + 1] = e end
    for _, e in ipairs(list) do
      local s = Acquire(steps, CreateStep)
      s.entry = e
      s:ClearAllPoints()
      s:SetPoint("TOPLEFT", content, "TOPLEFT", PROF_W + (e.kind == "range" and 0 or 12), y - yy)
      s:SetWidth(RIGHT_W - 12)
      if e.kind == "range" then
        s.icon:Hide()
      else
        s.icon:Show()
        local icon = e.item and e.item ~= 0 and select(3, ItemInfo(e.item))
          or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(e.spell)) or 134400
        s.icon:SetTexture(icon)
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
    local m = Acquire(mats, CreateMat)
    local col, line = (i - 1) % MAT_COLS, math.floor((i - 1) / MAT_COLS)
    m:ClearAllPoints()
    m:SetPoint("TOPLEFT", content, "TOPLEFT", PROF_W + col * (MAT_W + 4), y - yy - line * (MAT_H + 4))
    local iname, _, icon = ItemInfo(item)
    m.itemID = item
    m.icon:SetTexture(icon)
    m.name:SetText(iname or ("item:" .. item))
    m.own:SetText(ns.L["Owned: %d / %d"]:format(need.have[item] or 0, need.gross[item] or 0))
    m.count:SetText("x" .. need.items[item])
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

function ns.RefreshWindow()
  if not (frame and frame:IsShown()) then return end
  ReleaseAll(headers) ReleaseAll(rows) ReleaseAll(mats) ReleaseAll(steps)
  local chars = ComradeCraftDB.chars
  local collapsed = ComradeCraftDB.ui.collapsed
  local y, members, profs = 0, 0, 0
  for _, key in ipairs(SortedKeys(chars)) do
    local c = chars[key]
    local plist = SortedKeys(c.professions or {})
    if #plist > 0 then
      members = members + 1
      profs = profs + #plist
      local hd = Acquire(headers, CreateHeader)
      hd.key = key
      hd:ClearAllPoints()
      hd:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
      hd.name:SetText(ns.ClassColored(key, c.class))
      local className = c.class and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[c.class] or ""
      hd.desc:SetText(className .. " - " .. ns.Plural(#plist, "%d profession", "%d professions"))
      hd.sync:SetText(Ago(c.updated))
      hd.toggle:SetTexture(collapsed[key] and "Interface\\Buttons\\UI-PlusButton-Up"
        or "Interface\\Buttons\\UI-MinusButton-Up")
      y = y - HEAD_H - 2
      if not collapsed[key] then
        for _, pname in ipairs(plist) do
          y = y - LayoutProfession(y, pname, c.professions[pname], c)
        end
      end
      y = y - 8
    end
  end
  content:SetHeight(math.max(1, -y))
  frame.badge:SetText(ns.Plural(members, "%d member", "%d members") .. " - "
    .. ns.Plural(profs, "%d profession", "%d professions"))
  frame.empty:SetShown(members == 0)
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

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  title:SetPoint("TOPLEFT", 24, -68)
  title:SetText(ns.L["Group needs"])
  local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText(ns.L["Materials missing to reach the current cap (character's own stock deducted)."])
  f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.badge:SetPoint("TOPRIGHT", -24, -72)

  local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 16, -118)
  scroll:SetPoint("BOTTOMRIGHT", -34, 36)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(LIST_W, 1)
  scroll:SetScrollChild(content)

  f.empty = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  f.empty:SetPoint("CENTER", scroll, "CENTER")
  f.empty:SetText(ns.L["No data yet. Open your profession windows, then /comrade."])

  local foot = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  foot:SetPoint("BOTTOMLEFT", 20, 14)
  foot:SetText(ns.L["Local data (characters on this account). skill ~N: value taken from Classic, unconfirmed."])
  local foot2 = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  foot2:SetPoint("BOTTOMRIGHT", -20, 14)
  foot2:SetText("/comrade")

  f:SetScript("OnShow", ns.RefreshWindow)
  return f
end

function ns.ToggleWindow()
  ComradeCraftDB.ui = ComradeCraftDB.ui or {}
  ComradeCraftDB.ui.collapsed = ComradeCraftDB.ui.collapsed or {}
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
      tt:AddLine(ns.L["Click: group needs"], 1, 1, 1)
    end,
  })
  ComradeCraftDB.minimap = ComradeCraftDB.minimap or {}
  Icon:Register("ComradeCraft", obj, ComradeCraftDB.minimap)
end)
