-- Tracker: small panel next to the profession window with the plan's current step (what to
-- craft now, skill-up chance, how many the bags allow) and the next one. Drag to move it;
-- right-click puts it back beside the profession window. /comrade tracker toggles it.
local _, ns = ...
local L = ns.L

local W, PAD, ENTRY_H, MAX_ENTRIES = 300, 10, 18, 8
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
    if e.kind == "learn" then ns.AddSourceLines(GameTooltip, e.spell) end
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
    if e.kind == "learn" then ns.WaypointRecipe(e.spell) end
  end)
  return b
end

-- Craft queue of the open profession: the plan's craft entries of the current step, or of
-- every step up to the end of the current milestone. Same recipe merged; a recipe still to
-- learn stops the queue. Each entry: { spell, item, label, n (planned), ready (bags allow
-- now, capped at n), enchant (needs a target item: crafted by hand) } or { learn = true }.
function ns.CraftQueue(c, p, extent)
  local d = ns.DescribeNeed(p, c)
  local out, bySpell = {}, {}
  local stop = (math.floor((p.rank or 0) / ns.MILESTONE) + 1) * ns.MILESTONE
  for i, step in ipairs(d.steps or {}) do
    if (extent == "milestone" and step.from >= stop) or (extent ~= "milestone" and i > 1) then break end
    for _, e in ipairs(step.entries) do
      if e.kind == "learn" then
        out[#out + 1] = { learn = true, spell = e.spell, item = e.item, label = e.label, entry = e }
        return out, stop
      end
      if e.kind == "craft" and not e.stock then
        local q = bySpell[e.spell]
        if not q then
          q = { spell = e.spell, item = e.item, label = e.label, n = 0, entry = e,
            enchant = ns.EnchantSlots and ns.EnchantSlots[e.spell] ~= nil,
            other = ns.Recipes[e.spell] and ns.Recipes[e.spell][1] ~= p.skillLine or nil }
          bySpell[e.spell] = q
          out[#out + 1] = q
        end
        q.n = q.n + (e.n or 0)
      end
    end
  end
  for _, q in ipairs(out) do
    if not q.learn then q.ready = math.min(q.n, ns.CraftableNow(q.spell, c.bags or {})) end
  end
  return out, stop
end

-- The entry "Craft next" would start: the first one the bags allow (enchants excluded).
function ns.NextCraft(queue)
  for _, q in ipairs(queue) do
    if q.learn then return nil, q end
    if not q.enchant and not q.other and (q.ready or 0) > 0 then return q end
  end
end

-- One click = one batch (the game needs a click per craft, like TSM's Craft Next).
local function CraftNext()
  local q = panel and panel.next
  if not q or (InCombatLockdown and InCombatLockdown()) then return end
  local T = C_TradeSkillUI
  local ok, err = false, "no CraftRecipe"
  if T and T.CraftRecipe then ok, err = pcall(T.CraftRecipe, q.spell, q.ready) end
  ns.Log(("craft queue: %d x%d -> %s"):format(q.spell, q.ready, ok and "ok" or tostring(err)))
  if not ok then ns.Print(L["Could not start the craft (see /comrade log)."]) end
end

local function Create()
  if panel then return end
  panel = CreateFrame("Frame", "ComradeCraftTracker", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(W, 120)
  panel:SetFrameStrata("HIGH") -- small, beside the profession window: never hidden behind ours
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
  -- Queue extent: this step, or up to the end of the current milestone.
  panel.extent = CreateFrame("Button", nil, panel)
  panel.extent:SetSize(W - 2 * PAD, 16)
  panel.extent.text = panel.extent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  panel.extent.text:SetPoint("LEFT")
  panel.extent:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  panel.extent:SetScript("OnClick", function()
    local s = Settings()
    s.queueExtent = s.queueExtent == "milestone" and "step" or "milestone"
    ns.RefreshTracker()
  end)
  panel.craft = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.craft:SetSize(W - 2 * PAD, 24)
  panel.craft:SetScript("OnClick", CraftNext)
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
  panel.extent:Hide()
  panel.craft:Hide()
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
    if d.rank and not (step and first) then
      info[#info + 1] = "|cffffd100" .. d.rank.title .. "|r"
      for _, e in ipairs(d.rank.entries) do info[#info + 1] = "|cff66ccff" .. e.text .. "|r |cff9d9d9d" .. e.detail .. "|r" end
      for _, n in ipairs(d.rank.notes) do info[#info + 1] = "|cff9d9d9d" .. n .. "|r" end
    end
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
    -- Queue (this step, or to the end of the milestone) with what the bags allow now.
    local extent = Settings().queueExtent == "milestone" and "milestone" or "step"
    local queue, stop = ns.CraftQueue(c, p, extent)
    panel.extent.text:SetText("|cff9d9d9d" .. L["Queue:"] .. "|r " .. (extent == "milestone"
      and L["up to skill %d (click: this step only)"]:format(stop) or L["this step (click: up to the milestone)"]))
    panel.extent:ClearAllPoints()
    panel.extent:SetPoint("TOPLEFT", PAD, -y)
    panel.extent:Show()
    y = y + 18
    local more = 0
    for i, q in ipairs(queue) do
      local b = panel.entries[i]
      if not b then more = more + 1 else
        b.entry = q.entry
        b.icon:SetTexture(q.item and q.item ~= 0 and GetItemIcon and GetItemIcon(q.item)
          or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(q.spell)) or 134400)
        local text
        if q.learn then
          text = "|cff66ccff" .. L["Learn %s"]:format(q.label or "") .. "|r"
        else
          local ready = q.other and ("|cff9d9d9d" .. L["other profession"] .. "|r")
            or q.enchant and ("|cff9d9d9d" .. L["by hand (needs a target)"] .. "|r")
            or ((q.ready or 0) >= q.n and ("|cff40ff40" .. L["ready"] .. "|r")
            or ("|cffff9933" .. L["%d ready"]:format(q.ready or 0) .. "|r"))
          text = ("%dx %s  %s"):format(q.n, q.label or "", ready)
        end
        b.text:SetText(text)
        local h = math.max(ENTRY_H, (b.text:GetStringHeight() or 0) + 6)
        b:SetHeight(h)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", PAD, -y)
        b:Show()
        y = y + h
      end
    end
    local after = {}
    if more > 0 then after[#after + 1] = "|cff9d9d9d" .. L["+%d more"]:format(more) .. "|r" end
    panel.after:SetText(table.concat(after, "\n"))
    if #after > 0 then
      panel.after:ClearAllPoints()
      panel.after:SetPoint("TOPLEFT", PAD, -(y + 2))
      y = y + 4 + (panel.after:GetStringHeight() or 12)
    end
    -- Craft next: one batch per click.
    local nxt, blocker = ns.NextCraft(queue)
    panel.next = nxt
    if nxt then
      panel.craft:SetText(L["Craft next: %dx %s"]:format(nxt.ready, nxt.label or ""))
      panel.craft:SetEnabled(true)
    else
      panel.craft:SetText(blocker and L["Learn %s first"]:format(blocker.label or "")
        or (#queue > 0 and L["Missing mats for the queue"] or L["Nothing to craft"]))
      panel.craft:SetEnabled(false)
    end
    panel.craft:ClearAllPoints()
    panel.craft:SetPoint("TOPLEFT", PAD, -(y + 4))
    panel.craft:Show()
    y = y + 32
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
