-- Tracker: small panel next to the profession window with the plan's current step (what to
-- craft now, skill-up chance, how many the bags allow) and the next one. Drag to move it;
-- right-click puts it back beside the profession window. /comrade tracker toggles it.
local _, ns = ...
local L = ns.L

local W, PAD, ENTRY_H, MAX_ENTRIES = 300, 10, 18, 6
local COLOR = { orange = "ff8040", yellow = "ffff00", green = "40c040", grey = "808080" }
local panel, lastAnchor

-- Pure: how many crafts of `spell` the bags allow right now (0 if a mat is missing).
function ns.CraftableNow(spell, bags)
  local r = ns.Recipes[spell]
  if not r or #r[7] == 0 then return 0 end
  local n = math.huge
  for i = 1, #r[7], 2 do n = math.min(n, math.floor((bags[r[7][i]] or 0) / r[7][i + 1])) end
  return n
end

local function Settings()
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  return ComradeCraftDB.settings
end

-- The profession frame this client shows (load-on-demand, so looked up each time).
local function Anchor()
  for _, name in ipairs({ "TradeSkillFrame", "ProfessionsFrame", "CraftFrame" }) do
    local f = _G[name]
    if f and f.IsShown and f:IsShown() then return f, name end
  end
end

local function Place()
  panel:ClearAllPoints()
  local pos = Settings().trackerPos
  if pos then
    panel:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3])
    return
  end
  local a, name = Anchor()
  if a then
    panel:SetPoint("TOPLEFT", a, "TOPRIGHT", 4, -30)
  else
    panel:SetPoint("RIGHT", UIParent, "RIGHT", -60, 60)
  end
  if name ~= lastAnchor then
    lastAnchor = name
    ns.Log("tracker: docked to " .. tostring(name))
  end
end

local function CreateEntry(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(W - 2 * PAD, ENTRY_H)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(16, 16)
  b.icon:SetPoint("TOPLEFT", 0, -1)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("TOPLEFT", 20, -3)
  b.text:SetWidth(W - 2 * PAD - 20)
  b.text:SetJustifyH("LEFT")
  b:SetScript("OnEnter", function(self)
    local e = self.entry
    if not e then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if e.item and e.item ~= 0 then GameTooltip:SetItemByID(e.item)
    elseif GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(e.spell) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    local e = self.entry
    if not e then return end
    if IsModifiedClick and IsModifiedClick("CHATLINK") then
      local link = ns.RecipeLink(e.spell, e.item)
      if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
      return
    end
    if e.kind == "craft" then ns.OpenRecipe(e.spell) end
  end)
  return b
end

local function Create()
  if panel then return end
  panel = CreateFrame("Frame", "ComradeCraftTracker", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(W, 120)
  panel:SetFrameStrata("MEDIUM")
  if panel.SetBackdrop then
    panel:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    panel:SetBackdropColor(0.06, 0.06, 0.08, 0.92)
  end
  panel:EnableMouse(true)
  panel:SetMovable(true)
  panel:SetClampedToScreen(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    Settings().trackerPos = { point, x, y }
  end)
  panel:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" then
      Settings().trackerPos = nil
      Place()
    end
  end)
  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  panel.title:SetPoint("TOPLEFT", PAD, -PAD)
  panel.title:SetWidth(W - 2 * PAD - 20)
  panel.title:SetJustifyH("LEFT")
  panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  panel.close:SetSize(22, 22)
  panel.close:SetPoint("TOPRIGHT", -2, -2)
  panel.close:SetScript("OnClick", function()
    Settings().tracker = false
    panel:Hide()
    ns.Print(L["Step panel hidden. /comrade tracker shows it again."])
  end)
  for _, k in ipairs({ "info", "after" }) do
    panel[k] = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel[k]:SetWidth(W - 2 * PAD)
    panel[k]:SetJustifyH("LEFT")
  end
  panel.entries = {}
  for i = 1, MAX_ENTRIES do panel.entries[i] = CreateEntry(panel) end
  panel.shop = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.shop:SetSize(130, 20)
  panel.shop:SetText(L["Shopping list"])
  panel.shop:SetScript("OnClick", function() ns.ShoppingAction(ns.CharKey(), ns.openLine) end)
  panel.open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.open:SetSize(130, 20)
  panel.open:SetText(L["Full plan"])
  panel.open:SetScript("OnClick", function()
    if ComradeCraftDB.ui then ComradeCraftDB.ui.sel = ns.CharKey() end
    if not (ComradeCraftFrame and ComradeCraftFrame:IsShown()) then ns.ToggleWindow() else ns.RefreshWindow() end
  end)
  panel:Hide()
end

-- Redraws the panel from the current character's plan for the open profession.
function ns.RefreshTracker()
  if not (panel and panel:IsShown() and ComradeCraftDB and ComradeCraftDB.chars) then return end
  if not Settings().trackerPos then Place() end -- the profession frame may show (or change) late
  local c = ns.CharData()
  local p, pname
  for name, prof in pairs(c.professions or {}) do
    if ns.openLine and prof.skillLine == ns.openLine then p, pname = prof, name end
  end
  for _, b in ipairs(panel.entries) do b:Hide() end
  panel.shop:Hide()
  local y = PAD
  if not p then
    panel.title:SetText("ComradeCraft")
    y = y + 18
    panel.info:SetText("|cff9d9d9d" .. L["Reading the recipes of this profession..."] .. "|r")
    panel.info:ClearAllPoints()
    panel.info:SetPoint("TOPLEFT", PAD, -y)
    y = y + 16
    panel.after:SetText("")
  else
    panel.title:SetText(("%s  |cffffffff%d/%d|r"):format(pname, p.rank or 0, p.max or 0))
    y = y + 18
    local d = ns.DescribeNeed(p, c)
    local need = c.needs and c.needs[p.skillLine]
    local step = need and need.plan and need.plan[1]
    local first = d.steps and d.steps[1]
    local info = {}
    if d.status then info[#info + 1] = "|cff9d9d9d" .. d.status .. "|r" end
    if step and first then
      local color = ns.RecipeColor(step.spell, p.rank) or "grey"
      local chance = math.floor(ns.SkillUpChance(step.spell, p.rank) * 100 + 0.5)
      info[#info + 1] = ("|cffffd100%s|r  |cff%s%s|r"):format(first.range, COLOR[color], L["%d%% chance per craft (%s)"]
        :format(chance, L[color]))
    elseif d.blocked then
      info[#info + 1] = "|cffff9933" .. d.blocked .. "|r"
    end
    panel.info:SetText(table.concat(info, "\n"))
    panel.info:ClearAllPoints()
    panel.info:SetPoint("TOPLEFT", PAD, -y)
    y = y + (panel.info:GetStringHeight() or 12) + 4
    -- Too many entries: keep the first ones and always the last (the main craft).
    local list = {}
    for _, e in ipairs(first and first.entries or {}) do list[#list + 1] = e end
    if #list > MAX_ENTRIES then
      local last = list[#list]
      for i = #list, MAX_ENTRIES, -1 do list[i] = nil end
      list[MAX_ENTRIES] = last
    end
    for i, e in ipairs(list) do
      local b = panel.entries[i]
      b.entry = e
      b.icon:SetTexture(e.item and e.item ~= 0 and GetItemIcon and GetItemIcon(e.item)
        or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(e.spell)) or 134400)
      b.text:SetText(e.kind == "learn" and ("|cff66ccff" .. e.text .. "|r") or e.text)
      local h = math.max(ENTRY_H, (b.text:GetStringHeight() or 0) + 6)
      b:SetHeight(h)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", PAD, -y)
      b:Show()
      y = y + h
    end
    local after = {}
    -- What the bags allow for the first thing to craft (an intermediate when the step has one).
    local todo
    for _, e in ipairs(first and first.entries or {}) do
      if e.kind == "learn" then break end
      if e.kind == "craft" and not e.stock then todo = e break end
    end
    if todo then
      local n = ns.CraftableNow(todo.spell, c.bags or {})
      after[#after + 1] = n > 0
        and ("|cff40ff40" .. L["Your bags allow %d crafts of %s now."]:format(n, ns.SpellName(todo.spell)) .. "|r")
        or ("|cffff9933" .. L["Missing mats in your bags for %s."]:format(ns.SpellName(todo.spell)) .. "|r")
    end
    local second = d.steps and d.steps[2]
    if second then
      local last = second.entries[#second.entries]
      after[#after + 1] = "|cff9d9d9d" .. L["Then %s: %s"]:format(second.range, last and last.text or "") .. "|r"
    end
    panel.after:SetText(table.concat(after, "\n"))
    if #after > 0 then
      panel.after:ClearAllPoints()
      panel.after:SetPoint("TOPLEFT", PAD, -(y + 4))
      y = y + 8 + (panel.after:GetStringHeight() or 12)
    end
    if ns.CanShop() and need and next(need.items or {}) then panel.shop:Show() end
  end
  y = y + 6
  panel.open:ClearAllPoints()
  panel.open:SetPoint("TOPRIGHT", -PAD, -y)
  panel.shop:ClearAllPoints()
  panel.shop:SetPoint("TOPLEFT", PAD, -y)
  panel:SetHeight(y + 20 + PAD)
end

local function Linked()
  local T = C_TradeSkillUI
  return T and ((T.IsTradeSkillLinked and T.IsTradeSkillLinked()) or (T.IsTradeSkillGuild and T.IsTradeSkillGuild()))
end

ns.On("TRADE_SKILL_SHOW", function()
  if not (ComradeCraftDB and Settings().tracker ~= false) or Linked() then return end
  Create()
  panel:Show()
  Place()
  ns.RefreshTracker()
end)

ns.On("TRADE_SKILL_CLOSE", function()
  ns.openLine = nil
  if panel then panel:Hide() end
end)

-- Step panel on/off (`on` nil = keep) and `redock` = forget the dragged position.
-- Used by /comrade tracker and the Manage view.
function ns.SetTracker(on, redock)
  local s = Settings()
  if on ~= nil then s.tracker = on end
  if redock then s.trackerPos = nil end
  if s.tracker == false and panel then panel:Hide() end
  if s.tracker ~= false and Anchor() and not Linked() then
    Create()
    panel:Show()
  end
  if panel and panel:IsShown() then
    Place()
    ns.RefreshTracker()
  end
end
function ns.TrackerOn() return Settings().tracker ~= false end

-- /comrade tracker [reset]: show/hide the step panel, or dock it back.
ns.commands.tracker = function(rest)
  if rest == "reset" then ns.SetTracker(nil, true) else ns.SetTracker(not ns.TrackerOn()) end
  ns.Print(ns.TrackerOn() and L["Step panel: on (shown with the profession window)"] or L["Step panel: off"])
end
