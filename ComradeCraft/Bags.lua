-- Bags: highlights spare items in your bags that friends or group members need.
-- Normally shows a subtle Blizzard mailbox badge + urgency glow; when a group member's name
-- is typed in the Send Mail box, highlights their needed items in gold and dims the rest.
local _, ns = ...

local Bags = {}
ns.Bags = Bags

local URG_COLOR = {
  [1] = { 0.30, 0.95, 0.40, 0.65 }, -- now / craft request
  [2] = { 1.00, 0.82, 0.20, 0.55 }, -- soon
  [3] = { 0.45, 0.78, 1.00, 0.45 }, -- later
}

function Bags.On()
  local s = ComradeCraftDB and ComradeCraftDB.settings
  return not (s and s.bagHighlight == false)
end

function Bags.Set(on)
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  ComradeCraftDB.settings.bagHighlight = on and true or false
  Bags.Refresh()
end

-- Pure: builds lookup [itemID] = { mode = "focus"|"give", urgency = 1..3, entry = ... }
-- for the current bag state. When `recipient` is given, only items for that recipient match.
function Bags.BuildIndex(recipient)
  local idx = {}
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return idx end
  if recipient then
    for _, it in ipairs(ns.Mail and ns.Mail.ItemsFor(recipient) or {}) do
      idx[it.item] = { mode = "focus", urgency = 1, entry = it }
    end
    return idx
  end
  local me = ns.CharKey()
  for _, g in ipairs(ns.GiveList(me)) do
    local urg = ns.UrgencyRank(g.step)
    local cur = idx[g.item]
    if not cur or urg < cur.urgency then
      idx[g.item] = { mode = "give", urgency = urg, entry = g }
    end
  end
  local bags = (ComradeCraftDB.chars[me] or {}).bags or {}
  for _, r in pairs(ComradeCraftDB.requests or {}) do
    if r.status == "accepted" and ns.Requests and ns.Requests.Role(r) == "crafter"
      and r.item and r.item ~= 0 and (bags[r.item] or 0) > 0 then
      idx[r.item] = { mode = "give", urgency = 1, entry = r }
    end
  end
  return idx
end

function Bags.ItemState(itemID, recipient)
  if not itemID then return nil end
  return Bags.BuildIndex(recipient)[itemID]
end

-- Weak-keyed overlay cache: never writes fields onto Blizzard's secure item buttons.
local overlays = setmetatable({}, { __mode = "k" })

local function GetOverlay(button)
  local ov = overlays[button]
  if ov then return ov end
  ov = CreateFrame("Frame", nil, button)
  ov:SetAllPoints(button)
  ov:SetFrameLevel((button:GetFrameLevel() or 1) + 4)
  ov.dim = ov:CreateTexture(nil, "OVERLAY", nil, 1)
  ov.dim:SetAllPoints(ov)
  ov.dim:SetColorTexture(0, 0, 0, 0.58)
  ov.dim:Hide()
  ov.glow = ov:CreateTexture(nil, "OVERLAY", nil, 2)
  ov.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  ov.glow:SetBlendMode("ADD")
  ov.glow:SetPoint("CENTER")
  local w, h = button:GetSize()
  if not w or w <= 0 then w, h = 37, 37 end
  ov.glow:SetSize(w * 1.65, h * 1.65)
  ov.glow:Hide()
  ov.badgeBg = ov:CreateTexture(nil, "OVERLAY", nil, 3)
  ov.badgeBg:SetSize(15, 15)
  ov.badgeBg:SetPoint("TOPLEFT", 1, -1)
  ov.badgeBg:SetColorTexture(0.05, 0.04, 0.03, 0.8)
  ov.badgeBg:Hide()
  ov.badge = ov:CreateTexture(nil, "OVERLAY", nil, 4)
  ov.badge:SetSize(13, 13)
  ov.badge:SetPoint("TOPLEFT", 2, -2)
  ov.badge:SetTexture("Interface\\Minimap\\Tracking\\Mailbox")
  ov.badge:Hide()
  overlays[button] = ov
  return ov
end

local function SlotItemID(button, fallbackBag)
  if type(button.info) == "table" and type(button.info.itemID) == "number" then
    return button.info.itemID
  end
  if type(button.itemID) == "number" then return button.itemID end
  if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
  local bag = (button.GetBagID and button:GetBagID())
    or (button.GetBag and button:GetBag())
    or button.bagID
    or fallbackBag
  local slot = (button.GetID and button:GetID()) or button.slotID
  if not (type(bag) == "number" and type(slot) == "number") then return nil end
  local info = C_Container.GetContainerItemInfo(bag, slot)
  return info and info.itemID or nil
end

local function ApplyButton(button, fallbackBag, idx, focusMode, enabled)
  if not button then return end
  local existing = overlays[button]
  if not enabled and not focusMode then
    if existing then existing:Hide() end
    return
  end
  local itemID = SlotItemID(button, fallbackBag)
  local hit = itemID and idx[itemID]
  if not hit and not (focusMode and itemID) then
    if existing then existing:Hide() end
    return
  end
  local ov = GetOverlay(button)
  ov:Show()
  if hit then
    ov.dim:Hide()
    if focusMode then
      ov.glow:SetVertexColor(1, 0.82, 0, 0.95)
    else
      local c = URG_COLOR[hit.urgency] or URG_COLOR[3]
      ov.glow:SetVertexColor(c[1], c[2], c[3], c[4])
    end
    ov.glow:Show()
    ov.badgeBg:Show()
    ov.badge:Show()
  else
    ov.glow:Hide()
    ov.badgeBg:Hide()
    ov.badge:Hide()
    ov.dim:Show()
  end
end

local function RefreshContainer(frame, idx, focusMode, enabled)
  if not (frame and frame.IsShown and frame:IsShown()) then return end
  local bag = frame.GetID and frame:GetID()
  if type(frame.Items) == "table" then
    for _, btn in ipairs(frame.Items) do
      ApplyButton(btn, bag, idx, focusMode, enabled)
    end
  elseif type(frame.EnumerateValidItems) == "function" then
    local iter, state, init = frame:EnumerateValidItems()
    if type(iter) == "function" then
      for _, btn in iter, state, init do
        ApplyButton(btn, bag, idx, focusMode, enabled)
      end
    end
  elseif frame.GetName and type(frame.size) == "number" then
    local prefix = frame:GetName() .. "Item"
    for i = 1, frame.size do
      ApplyButton(_G[prefix .. i], bag, idx, focusMode, enabled)
    end
  end
end

-- Active recipient from either Send Mail or Trade window (nil when neither is targeting a member).
function Bags.ActiveRecipient()
  if ns.Trade and ns.Trade.CurrentRecipient then
    local tr = ns.Trade.CurrentRecipient()
    if tr then return tr end
  end
  if ns.Mail and ns.Mail.CurrentRecipient then
    return ns.Mail.CurrentRecipient()
  end
end

function Bags.Refresh()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local enabled = Bags.On()
  local recipient = Bags.ActiveRecipient()
  local focusMode = recipient ~= nil
  local idx = (enabled or focusMode) and Bags.BuildIndex(recipient) or {}
  if ContainerFrameCombinedBags then
    RefreshContainer(ContainerFrameCombinedBags, idx, focusMode, enabled)
  end
  if ContainerFrameContainer and ContainerFrameContainer.ContainerFrames then
    for _, f in ipairs(ContainerFrameContainer.ContainerFrames) do
      RefreshContainer(f, idx, focusMode, enabled)
    end
  else
    for i = 1, (NUM_CONTAINER_FRAMES or 13) do
      local f = _G["ContainerFrame" .. i]
      if f then RefreshContainer(f, idx, focusMode, enabled) end
    end
  end
  -- ElvUI bag frames when active.
  local elv = _G.ElvUI_ContainerFrame
  if elv and elv.IsShown and elv:IsShown() and type(elv.Bags) == "table" then
    for bagID, bagFrame in pairs(elv.Bags) do
      if type(bagFrame) == "table" then
        for _, btn in pairs(bagFrame) do
          if type(btn) == "table" and btn.GetID then ApplyButton(btn, bagID, idx, focusMode, enabled) end
        end
      end
    end
  end
  -- Bagnon / Combuctor / BagBrother: refresh visible item buttons directly.
  for _, addon in ipairs({ _G.Bagnon, _G.Combuctor, _G.BagBrother }) do
    if type(addon) == "table" and addon.Frames and addon.Frames.Iterate then
      local ok, iter, st, k = pcall(addon.Frames.Iterate, addon.Frames)
      if ok and type(iter) == "function" then
        for _, f in iter, st, k do
          if f and f.IsShown and f:IsShown() and f.ItemGroup and type(f.ItemGroup.buttons) == "table" then
            for _, btn in pairs(f.ItemGroup.buttons) do
              ApplyButton(btn, btn.GetBag and btn:GetBag(), idx, focusMode, enabled)
            end
          end
        end
      end
    end
  end
  -- Baganator official refresh trigger.
  if Baganator and Baganator.API and Baganator.API.RequestItemButtonsRefresh then
    pcall(Baganator.API.RequestItemButtonsRefresh)
  end
end

-- Baganator official corner widget: shows the mailbox badge & recipient focus highlight directly
-- inside Baganator item buttons. Registered immediately at load time so Baganator auto-inserts it.
local baganatorRegistered = false
local function RegisterBaganator()
  if baganatorRegistered then return end
  if not (Baganator and Baganator.API and Baganator.API.RegisterCornerWidget) then return end
  baganatorRegistered = true
  pcall(Baganator.API.RegisterCornerWidget, "ComradeCraft", "comradecraft_give",
    function(cornerFrame, details)
      if not details or not details.itemID then return false end
      local enabled = Bags.On()
      local recipient = Bags.ActiveRecipient()
      local focusMode = recipient ~= nil
      if not enabled and not focusMode then return false end
      local hit = Bags.ItemState(details.itemID, recipient)
      if hit then
        if cornerFrame.dim then cornerFrame.dim:Hide() end
        if cornerFrame.glow then
          if focusMode then cornerFrame.glow:SetVertexColor(1, 0.82, 0, 0.95)
          else
            local c = URG_COLOR[hit.urgency] or URG_COLOR[3]
            cornerFrame.glow:SetVertexColor(c[1], c[2], c[3], c[4])
          end
          cornerFrame.glow:Show()
        end
        if cornerFrame.badge then cornerFrame.badge:Show() end
        return true
      elseif focusMode then
        if cornerFrame.glow then cornerFrame.glow:Hide() end
        if cornerFrame.badge then cornerFrame.badge:Hide() end
        if cornerFrame.dim then cornerFrame.dim:Show() end
        return true
      end
      return false
    end,
    function(itemButton)
      local f = CreateFrame("Frame", nil, itemButton)
      f:SetSize(14, 14)
      f.dim = f:CreateTexture(nil, "OVERLAY", nil, 1)
      f.dim:SetAllPoints(itemButton)
      f.dim:SetColorTexture(0, 0, 0, 0.58)
      f.dim:Hide()
      f.glow = f:CreateTexture(nil, "OVERLAY", nil, 2)
      f.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
      f.glow:SetBlendMode("ADD")
      f.glow:SetPoint("CENTER", itemButton, "CENTER")
      local w, h = itemButton:GetSize()
      if not w or w <= 0 then w, h = 37, 37 end
      f.glow:SetSize(w * 1.65, h * 1.65)
      f.glow:Hide()
      f.badge = f:CreateTexture(nil, "OVERLAY", nil, 4)
      f.badge:SetSize(13, 13)
      f.badge:SetPoint("CENTER")
      f.badge:SetTexture("Interface\\Minimap\\Tracking\\Mailbox")
      return f
    end,
    { corner = "top_left", priority = 2 })
end
RegisterBaganator()

-- Bagnon / Combuctor (BagBrother) item button hooks.
local function HookBagAddons()
  RegisterBaganator()
  if not hooksecurefunc then return end
  local function HookItem(btn, bag)
    local enabled = Bags.On()
    local recipient = Bags.ActiveRecipient()
    local focusMode = recipient ~= nil
    local idx = (enabled or focusMode) and Bags.BuildIndex(recipient) or {}
    ApplyButton(btn, bag, idx, focusMode, enabled)
  end
  for _, cls in ipairs({
    _G.BagBrother and _G.BagBrother.Item,
    _G.Bagnon and _G.Bagnon.Item,
    _G.Bagnon and _G.Bagnon.ItemSlot,
    _G.Combuctor and _G.Combuctor.Item,
  }) do
    if type(cls) == "table" and type(cls.Update) == "function" then
      pcall(hooksecurefunc, cls, "Update", function(self)
        HookItem(self, self.GetBag and self:GetBag())
      end)
    end
  end
end

local hooked = false
local function HookBags()
  if hooked then return end
  hooked = true
  HookBagAddons()
  if not hooksecurefunc then return end
  if ContainerFrameCombinedBags and ContainerFrameCombinedBags.UpdateItems then
    hooksecurefunc(ContainerFrameCombinedBags, "UpdateItems", function() Bags.Refresh() end)
  end
  if ContainerFrameContainer and ContainerFrameContainer.ContainerFrames then
    for _, f in ipairs(ContainerFrameContainer.ContainerFrames) do
      if f.UpdateItems then hooksecurefunc(f, "UpdateItems", function() Bags.Refresh() end) end
    end
  end
  if ContainerFrame_Update then
    hooksecurefunc("ContainerFrame_Update", function() Bags.Refresh() end)
  end
end

ns.On("PLAYER_LOGIN", HookBags)
ns.On("BAG_UPDATE_DELAYED", function() Bags.Refresh() end)
ns.On("PLAYER_ENTERING_WORLD", function() RegisterBaganator() Bags.Refresh() end)
