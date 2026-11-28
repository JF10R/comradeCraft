-- Trainer: when talking to a profession trainer, docks a compact Blizzard panel next to
-- ClassTrainerFrame listing available recipes that are needed by your leveling plan OR
-- craft a BiS gear/enchant upgrade for you or a group member. One click trains the recipe.
local _, ns = ...
local L = ns.L

local Trainer = {}
ns.Trainer = Trainer

local PANEL_W, MAX_ROWS = 264, 8
local isOpen = false

local nameIndex
local function SpellsByName(name)
  if not nameIndex then
    nameIndex = {}
    for spell in pairs(ns.Recipes or {}) do
      local n = ns.SpellName and ns.SpellName(spell)
      if n and not n:find("^spell:") then
        nameIndex[n] = nameIndex[n] or {}
        nameIndex[n][#nameIndex[n] + 1] = spell
      end
    end
  end
  return nameIndex[name]
end

-- Pure: available services at the open trainer that match your leveling plan or a group BiS upgrade.
-- Returns { { index, spell, item, name, cost, reason, prio }, ... }.
function Trainer.Highlights()
  local out = {}
  if not (ComradeCraftDB and ComradeCraftDB.chars and GetNumTrainerServices and GetTrainerServiceInfo) then
    return out
  end
  local meKey = ns.CharKey()
  local me = ComradeCraftDB.chars[meKey]
  if not me then return out end
  local lines = {}
  for pname, p in pairs(me.professions or {}) do
    if p.skillLine then lines[pname] = p.skillLine end
  end
  -- Recipes needed by this character's active leveling plans.
  local planSpells = {}
  for _, need in pairs(me.needs or {}) do
    for _, step in ipairs(need.plan or {}) do
      if step.learn then planSpells[step.spell] = true end
      for sub in pairs(step.subs or {}) do planSpells[sub] = true end
    end
  end

  local chars = ns.AllChars()
  local seen = {}
  for i = 1, GetNumTrainerServices() do
    local name, _, kind = GetTrainerServiceInfo(i)
    if name and kind == "available" then
      local skillName = GetTrainerServiceSkillReq and select(1, GetTrainerServiceSkillReq(i)) or nil
      local line = skillName and lines[skillName]
      local cost = GetTrainerServiceCost and GetTrainerServiceCost(i) or 0
      for _, spell in ipairs(SpellsByName(name) or {}) do
        local rec = ns.Recipes[spell]
        if rec and (not line or rec[1] == line) and not seen[spell] then
          local reason, prio
          if planSpells[spell] then
            reason, prio = L["Leveling plan"], 1
          else
            local item = rec[5]
            if item and item ~= 0 and ns.UpgradeFor then
              local bop = ns.IsBoP and ns.IsBoP(item)
              local bestWho, bestGain, bestHow
              for tkey, tc in pairs(chars) do
                if not bop or tkey == meKey then
                  local up, gain, how = ns.UpgradeFor(item, tc)
                  if up and gain and gain > 0 and (not bestGain or gain > bestGain) then
                    bestWho, bestGain, bestHow = tkey, gain, how
                  end
                end
              end
              if bestWho then
                local tag = bestHow == "pawn" and L["+%d with Pawn"]:format(math.floor(bestGain + 0.5))
                  or bestHow == "stats" and L["+%d score"]:format(math.floor(bestGain + 0.5))
                  or L["+%d item levels"]:format(math.floor(bestGain + 0.5))
                reason = L["Upgrade for %s (%s)"]:format(bestWho:match("^[^-]+") or bestWho, tag)
                prio = 2
              end
            elseif rec[1] == ns.ENCHANTING and ns.GearScore and ns.GearScore.ScoreEnchant then
              local bestWho, bestSc
              for tkey, tc in pairs(chars) do
                local sc = ns.GearScore.ScoreEnchant(spell, tc)
                if sc > 0 and (not bestSc or sc > bestSc) then bestWho, bestSc = tkey, sc end
              end
              if bestWho then
                reason = L["Good enchant for %s"]:format(bestWho:match("^[^-]+") or bestWho)
                prio = 3
              end
            end
          end
          if reason then
            seen[spell] = true
            out[#out + 1] = { index = i, spell = spell, item = rec[5] or 0, name = name,
              cost = cost, reason = reason, prio = prio }
          end
          break
        end
      end
    end
  end
  table.sort(out, function(a, b)
    if a.prio ~= b.prio then return a.prio < b.prio end
    return a.name < b.name
  end)
  return out
end

-- Current index of service `name` (and `cost`): the list shifts after learning or a filter change.
function Trainer.ResolveService(idx, name, cost)
  if not (GetNumTrainerServices and GetTrainerServiceInfo and name) then return nil end
  local function Match(i)
    local n, _, kind = GetTrainerServiceInfo(i)
    return n == name and kind == "available"
      and (not (cost and GetTrainerServiceCost) or GetTrainerServiceCost(i) == cost)
  end
  if idx and Match(idx) then return idx end
  for i = 1, GetNumTrainerServices() do
    if Match(i) then return i end
  end
end

-- Panel docked to the right of ClassTrainerFrame ------------------------------------------

local panel, rows, dismissed = nil, nil, false

local function RowIcon(item, spell)
  if item and item ~= 0 then
    return (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item))
      or (GetItemIcon and GetItemIcon(item)) or 134400
  end
  return (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spell)) or 134400
end

local function CreateRow(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(PANEL_W - 20, 28)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(22, 22)
  b.icon:SetPoint("LEFT", 2, 0)
  b.cost = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.cost:SetPoint("TOPRIGHT", -2, -2)
  b.cost:SetJustifyH("RIGHT")
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("TOPLEFT", 28, -2)
  b.name:SetPoint("RIGHT", b.cost, "LEFT", -4, 0)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.sub:SetPoint("BOTTOMLEFT", 28, 2)
  b.sub:SetPoint("RIGHT", -2, 0)
  b.sub:SetJustifyH("LEFT")
  b.sub:SetWordWrap(false)
  b:SetScript("OnEnter", function(self)
    if not self.spell then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.item and self.item ~= 0 then GameTooltip:SetItemByID(self.item)
    elseif GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spell) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Click to train."], 0.5, 0.8, 1)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if self.serviceIdx and BuyTrainerService then
      local i = Trainer.ResolveService(self.serviceIdx, self.serviceName, self.serviceCost)
      if i then BuyTrainerService(i) end
      if C_Timer then C_Timer.After(0.3, Trainer.UpdatePanel) else Trainer.UpdatePanel() end
    end
  end)
  return b
end

local function CreatePanel()
  local anchor = ClassTrainerFrame
  if panel or not anchor then return end
  panel = CreateFrame("Frame", "ComradeCraftTrainerPanel", anchor, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(PANEL_W, 100)
  panel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 4, -24)
  panel:SetFrameStrata("HIGH")
  if panel.SetBackdrop then
    panel:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    panel:SetBackdropColor(0.06, 0.05, 0.04, 0.94)
    panel:SetBackdropBorderColor(0.8, 0.68, 0.35, 1)
  end
  panel.logo = panel:CreateTexture(nil, "ARTWORK")
  panel.logo:SetSize(16, 16)
  panel.logo:SetPoint("TOPLEFT", 10, -10)
  panel.logo:SetTexture(ns.LOGO)
  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  panel.title:SetPoint("LEFT", panel.logo, "RIGHT", 6, 0)
  panel.title:SetText(L["Recommended recipes"])
  panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  panel.close:SetSize(22, 22)
  panel.close:SetPoint("TOPRIGHT", -2, -2)
  panel.close:SetScript("OnClick", function() dismissed = true panel:Hide() end)
  rows = {}
end

function Trainer.UpdatePanel()
  if not panel then return end
  if dismissed or not isOpen or (ns.PanelEnabled and not ns.PanelEnabled("trainer")) then panel:Hide() return end
  local items = Trainer.Highlights()
  if #items == 0 then panel:Hide() return end
  for _, r in ipairs(rows) do r:Hide() end
  local y = -34
  for i = 1, math.min(#items, MAX_ROWS) do
    local it = items[i]
    local r = rows[i]
    if not r then r = CreateRow(panel) rows[i] = r end
    r.serviceIdx, r.spell, r.item = it.index, it.spell, it.item
    r.serviceName, r.serviceCost = it.name, it.cost
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, y)
    r.icon:SetTexture(RowIcon(it.item, it.spell))
    r.name:SetText(it.name)
    r.cost:SetText(it.cost > 0 and ("|cffffd100" .. ns.Money(it.cost) .. "|r") or "")
    r.sub:SetText(it.prio == 1 and ("|cff40ff40" .. it.reason .. "|r") or ("|cff66ccff" .. it.reason .. "|r"))
    r:Show()
    y = y - 30
  end
  panel:SetHeight(-y + 10)
  panel:Show()
end

ns.On("TRAINER_SHOW", function()
  isOpen, dismissed = true, false
  CreatePanel()
  if C_Timer then C_Timer.After(0.1, Trainer.UpdatePanel) else Trainer.UpdatePanel() end
end)
ns.On("TRAINER_UPDATE", function() if isOpen then Trainer.UpdatePanel() end end)
ns.On("TRAINER_CLOSED", function()
  isOpen = false
  if panel then panel:Hide() end
end)
