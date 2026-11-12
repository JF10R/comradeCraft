-- Farm: the group plan's data (what the group still needs, its spare, the cost of the rest)
-- and opt-in farming assignments: ComradeCraftDB.farm[itemID] = { target, char, t }, synced
-- with the character's record, plus a small movable tracker of your own assignments.
local _, ns = ...
local L = ns.L

local W, PAD, LINE_H, MAX_LINES = 260, 10, 30, 10

local function ShortName(key) return key:match("^[^-]+") or key end

local function ItemName(item)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  return get and get(item) or ("item:" .. item)
end

local function ItemIcon(item)
  return (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item))
    or (GetItemIcon and GetItemIcon(item)) or 134400
end

local function Settings()
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  return ComradeCraftDB.settings
end

-- Assignments ------------------------------------------------------------------------------

-- Who farms `item`: { { key, target, own } }; own = stored on this account (it can drop it).
function ns.Farmers(item)
  local out = {}
  local a = ComradeCraftDB and ComradeCraftDB.farm and ComradeCraftDB.farm[item]
  if a then out[#out + 1] = { key = a.char, target = a.target, own = true } end
  for key, c in pairs(ns.AllChars()) do
    if c.peer and c.farm and c.farm[item] then out[#out + 1] = { key = key, target = c.farm[item] } end
  end
  return out
end

-- Peers fetch a record again only when its `updated` is newer.
local function Touch(key)
  local c = ComradeCraftDB.chars and ComradeCraftDB.chars[key]
  if c then c.updated = time() end
  if ns.Sync then ns.Sync.MarkDirty() end
end

local function Changed()
  if ns.RefreshFarm then ns.RefreshFarm() end
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- The current character takes `item` (n to gather).
function ns.FarmAssign(item, n)
  ComradeCraftDB.farm = ComradeCraftDB.farm or {}
  local key = ns.CharKey()
  local c = ComradeCraftDB.chars and ComradeCraftDB.chars[key] or {}
  -- base: what this character already holds; progress counts only what is gathered after.
  local base = ((c.bags or {})[item] or 0) + ((c.bank or {})[item] or 0)
  ComradeCraftDB.farm[item] = { target = math.max(1, math.floor(n)), char = key, t = time(), base = base }
  ns.Log(("farm: %s takes %d x item %d"):format(key, n, item))
  Touch(key)
  Changed()
end

function ns.FarmDrop(item)
  local a = ComradeCraftDB.farm and ComradeCraftDB.farm[item]
  if not a then return end
  ComradeCraftDB.farm[item] = nil
  Touch(a.char)
  Changed()
end

-- Group plan rows ----------------------------------------------------------------------------

-- Rows { item, total, by, spare, holders, toGet, cost (nil = unknown), farmers }, total cost,
-- all priced, and whether the total means anything (a price known, or nothing left to get).
function ns.GroupPlan(lineOK)
  local rows, total, complete, any, toBuy = {}, 0, true, false, 0
  for _, a in ipairs(ns.GroupMaterials(lineOK)) do
    local spare, holders = ns.GroupSupply(a.item)
    local toGet = math.max(0, a.total - spare)
    local cost = 0
    if toGet > 0 then
      cost = ns.BuyCost(a.item, toGet) -- nil when no price is known
      toBuy = toBuy + 1
    end
    if cost then
      total = total + cost
      if toGet > 0 then any = true end
    else
      complete = false
    end
    rows[#rows + 1] = { item = a.item, total = a.total, by = a.by, spare = spare, holders = holders,
      toGet = toGet, cost = cost, farmers = ns.Farmers(a.item) }
  end
  return rows, total, complete, any or toBuy == 0
end

-- Per-character breakdown of a row, on a tooltip (needers, spare, farmers).
function ns.AddPlanLines(tt, row)
  local chars = ns.AllChars()
  tt:AddLine(" ")
  tt:AddLine(L["Group plan"], 1, 0.82, 0)
  for _, b in ipairs(row.by) do
    local c = chars[b.key]
    tt:AddDoubleLine(ns.ClassColored(b.key, c and c.class), L["needs %d"]:format(b.n) .. " " .. ns.UrgencyText(b.step),
      1, 1, 1, 1, 0.82, 0.4)
  end
  for _, h in ipairs(row.holders) do
    tt:AddDoubleLine(L["Spare in the group"] .. ": " .. ShortName(h.key), tostring(h.n), 0.5, 0.8, 1, 0.5, 0.8, 1)
  end
  for _, f in ipairs(row.farmers) do
    tt:AddDoubleLine(L["Farmed by %s"]:format(ShortName(f.key)), tostring(f.target), 0.4, 1, 0.4, 0.4, 1, 0.4)
  end
end

-- Confirm dialog ("I'll farm it") ---------------------------------------------------------

local dialog
local function CreateDialog()
  dialog = CreateFrame("Frame", "ComradeCraftFarmDialog", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  dialog:SetSize(360, 120)
  dialog:SetPoint("CENTER", 0, 100)
  dialog:SetFrameStrata("DIALOG")
  dialog:SetToplevel(true)
  dialog:EnableMouse(true)
  local solid = dialog:CreateTexture(nil, "BACKGROUND", nil, -8)
  solid:SetPoint("TOPLEFT", 4, -4)
  solid:SetPoint("BOTTOMRIGHT", -4, 4)
  solid:SetColorTexture(0.06, 0.05, 0.04, 0.97)
  if dialog.SetBackdrop then
    dialog:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    dialog:SetBackdropBorderColor(1, 0.82, 0, 1)
  end
  dialog.text = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  dialog.text:SetPoint("TOPLEFT", 14, -16)
  dialog.text:SetWidth(332)
  dialog.text:SetJustifyH("LEFT")
  dialog.yes = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
  dialog.yes:SetSize(90, 22)
  dialog.yes:SetPoint("BOTTOMRIGHT", -12, 12)
  dialog.yes:SetText(YES or "Yes")
  dialog.yes:SetScript("OnClick", function()
    dialog:Hide()
    ns.FarmAssign(dialog.item, dialog.n)
  end)
  dialog.no = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
  dialog.no:SetSize(90, 22)
  dialog.no:SetPoint("RIGHT", dialog.yes, "LEFT", -6, 0)
  dialog.no:SetText(NO or "No")
  dialog.no:SetScript("OnClick", function() dialog:Hide() end)
  if UISpecialFrames then tinsert(UISpecialFrames, "ComradeCraftFarmDialog") end
end

-- names: who needs it ("Vez, Mira").
function ns.ShowFarmDialog(item, n, names)
  if not dialog then CreateDialog() end
  dialog.item, dialog.n = item, n
  dialog.text:SetText(L["%d %s needed for %s. Do you want to farm them?"]:format(n, ItemName(item), names))
  dialog:Show()
end

-- Farming tracker ------------------------------------------------------------------------------

local tracker

local function CreateLine(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(W - 2 * PAD, LINE_H)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(16, 16)
  b.icon:SetPoint("TOPLEFT", 0, -1)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("TOPLEFT", 20, -3)
  b.text:SetWidth(W - 2 * PAD - 44)
  b.text:SetJustifyH("LEFT")
  b.text:SetWordWrap(false)
  b.bar = CreateFrame("StatusBar", nil, b)
  b.bar:SetSize(W - 2 * PAD - 44, 6)
  b.bar:SetPoint("TOPLEFT", 20, -18)
  b.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  b.bar:SetStatusBarColor(0.35, 0.7, 0.25)
  local bg = b.bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.6)
  -- "x": drops this assignment.
  b.drop = CreateFrame("Button", nil, b, "UIPanelCloseButton")
  b.drop:SetSize(20, 20)
  b.drop:SetPoint("TOPRIGHT", 0, 2)
  b.drop.line = b
  b.drop:SetScript("OnClick", function(self) ns.FarmDrop(self.line.item) end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(self.item)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

local function Place()
  tracker:ClearAllPoints()
  local pos = Settings().farmPos
  if pos then
    tracker:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3])
  else
    tracker:SetPoint("RIGHT", UIParent, "RIGHT", -60, -120)
  end
end

local function CreateTracker()
  tracker = CreateFrame("Frame", "ComradeCraftFarmTracker", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  tracker:SetSize(W, 80)
  tracker:SetFrameStrata("HIGH")
  if tracker.SetBackdrop then
    tracker:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    tracker:SetBackdropColor(0.06, 0.06, 0.08, 0.92)
  end
  tracker:EnableMouse(true)
  tracker:SetMovable(true)
  tracker:SetClampedToScreen(true)
  tracker:RegisterForDrag("LeftButton")
  tracker:SetScript("OnDragStart", tracker.StartMoving)
  tracker:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    Settings().farmPos = { point, x, y }
  end)
  tracker.title = tracker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  tracker.title:SetPoint("TOPLEFT", PAD, -PAD)
  tracker.title:SetText(L["Farming"])
  tracker.close = CreateFrame("Button", nil, tracker, "UIPanelCloseButton")
  tracker.close:SetSize(22, 22)
  tracker.close:SetPoint("TOPRIGHT", -2, -2)
  tracker.close:SetScript("OnClick", function() ns.SetFarmTracker(false) end)
  tracker.lines = {}
  for i = 1, MAX_LINES do tracker.lines[i] = CreateLine(tracker) end
  tracker:Hide()
  Place()
end

function ns.FarmTrackerOn() return Settings().farmTracker ~= false end

function ns.SetFarmTracker(on)
  Settings().farmTracker = on and true or false
  ns.RefreshFarm()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- Clears the current character's finished assignments (one notice each), then redraws the
-- tracker: hidden without assignments or when turned off.
function ns.RefreshFarm()
  local db = ComradeCraftDB
  if not (db and db.chars and db.farm and next(db.farm)) then
    if tracker then tracker:Hide() end
    return
  end
  local key = ns.CharKey()
  local c = db.chars[key] or {}
  local list, done = {}, false
  for item, a in pairs(db.farm) do
    if a.char == key then
      local have = math.max(0, ((c.bags or {})[item] or 0) + ((c.bank or {})[item] or 0) - (a.base or 0))
      if have >= a.target then
        db.farm[item] = nil
        done = true
        ns.Alerts.Notify({ title = L["Farming done: %s"]:format(ItemName(item)),
          text = L["Give them from You can give in the Group view, or by mail."], icon = ItemIcon(item), item = item })
      else
        list[#list + 1] = { item = item, have = have, target = a.target }
      end
    end
  end
  if done then Touch(key) end
  if #list == 0 or not ns.FarmTrackerOn() then
    if tracker then tracker:Hide() end
    return
  end
  if not tracker then CreateTracker() end
  table.sort(list, function(x, y) return x.item < y.item end)
  local y = PAD + 20
  for i, b in ipairs(tracker.lines) do
    local e = list[i]
    if e then
      b.item = e.item
      b.icon:SetTexture(ItemIcon(e.item))
      b.text:SetText(("%s  |cffffffff%d/%d|r"):format(ItemName(e.item), e.have, e.target))
      b.bar:SetMinMaxValues(0, e.target)
      b.bar:SetValue(e.have)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", PAD, -y)
      b:Show()
      y = y + LINE_H
    else
      b:Hide()
    end
  end
  tracker:SetHeight(y + PAD)
  tracker:Show()
end
