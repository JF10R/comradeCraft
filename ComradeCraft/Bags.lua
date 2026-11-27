-- Bags: highlights spare items in your bags that friends, alts or group members need.
-- Normal mode: crisp colored 2px border + mailbox corner badge by urgency (green=now, gold=soon,
-- blue=later). Focus mode (when a group member is targeted in Mail or Trade): vivid gold border
-- + glow on items for them and dims everything else so sendable items pop instantly.
-- Supports Blizzard bags, Bagnon/Combuctor/BagBrother, Baganator, BetterBags, ElvUI, EllesmereUI & ArkInventory.
local _, ns = ...

local Bags = {}
ns.Bags = Bags

local URG_COLOR = {
  [0] = { 0.78, 0.42, 1.00, 0.98 }, -- manually reserved ("for Mirandaa", vivid violet)
  [1] = { 0.15, 1.00, 0.35, 0.95 }, -- now / craft request (vivid green)
  [2] = { 1.00, 0.82, 0.15, 0.90 }, -- soon (gold)
  [3] = { 0.35, 0.78, 1.00, 0.85 }, -- later (sky blue)
}
local BADGE_MAIL = "Interface\\Minimap\\Tracking\\Mailbox"
local BADGE_LOCK = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK"

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
      if (it.inBags or 0) > 0 then
        idx[it.item] = { mode = "focus", urgency = 1, entry = it }
      end
    end
    return idx
  end
  local me = ns.CharKey()
  for _, g in ipairs(ns.GiveList(me)) do
    if (g.inBags ~= nil and g.inBags or g.n) > 0 then
      local urg = ns.UrgencyRank(g.step)
      local cur = idx[g.item]
      if not cur or urg < cur.urgency then
        idx[g.item] = { mode = "give", urgency = urg, entry = g }
      end
    end
  end
  local chars = ns.AllChars()
  local meData = ComradeCraftDB.chars[me] or {}
  local bags = meData.bags or {}
  local bound = meData.bound or {}
  for _, r in pairs(ComradeCraftDB.requests or {}) do
    -- Finished craft to deliver to requester (or next crafter in chain).
    if (r.status == "accepted" or r.status == "crafting") and ns.Requests and ns.Requests.Role(r) == "crafter"
      and r.item and r.item ~= 0 and (bags[r.item] or 0) > 0 then
      idx[r.item] = { mode = "give", urgency = 1, entry = r }
    -- Reagents in our bags for our own pending/accepted outgoing craft request.
    elseif r.from == me and (r.status == "pending" or r.status == "accepted")
      and ns.Requests and ns.Requests.Role(r) == "requester" and chars[r.to] then
      local rec = ns.Recipes and ns.Recipes[r.spell]
      local tBags = chars[r.to].bags or {}
      for i = 1, #(rec and rec[7] or {}), 2 do
        local item, need = rec[7][i], rec[7][i + 1] * (r.qty or 1)
        local t = ns.ITEM_TRANSFORMS and ns.ITEM_TRANSFORMS[item]
        local tHave = tBags[item] or 0
        if t then
          local pHave = tBags[t.other] or 0
          tHave = tHave + (t.isSmall and (pHave * t.ratio) or math.floor(pHave / t.ratio))
        end
        if tHave < need then
          if (bags[item] or 0) > 0 and not (ns.IsBoP and ns.IsBoP(item)) then
            idx[item] = { mode = "give", urgency = 1, entry = r }
          end
          if t and (bags[t.other] or 0) > 0 and (bags[item] or 0) < (need - tHave) and not (ns.IsBoP and ns.IsBoP(t.other)) then
            idx[t.other] = { mode = "give", urgency = 1, entry = r }
          end
        end
      end
    end
  end
  -- Unknown non-BoP recipe items (Patterns/Plans/Formulas) in our bags that another group member needs.
  if ns.Loot and ns.Loot.RecipeStatus then
    for item, count in pairs(bags) do
      if count > 0 and not idx[item] and not bound[item] and not (ns.IsBoP and ns.IsBoP(item)) then
        local st = ns.Loot.RecipeStatus(item)
        if st and st.unknown then
          for _, u in ipairs(st.unknown) do
            if u.key ~= me then
              idx[item] = { mode = "give", urgency = u.rank >= u.req and 1 or 2, entry = u }
              break
            end
          end
        end
      end
    end
  end
  -- Manually reserved items ("for Mirandaa") in our bags: vivid violet lock badge.
  for item, rv in pairs(meData.reserved or {}) do
    if (bags[item] or 0) > 0 and rv and rv.to then
      idx[item] = { mode = "reserved", urgency = 0, entry = rv, reserved = true }
    end
  end
  return idx
end

function Bags.ItemState(itemID, recipient)
  if not itemID then return nil end
  return Bags.BuildIndex(recipient)[itemID]
end

-- Weak-keyed overlay cache: never writes fields onto Blizzard's or bag addons' secure item buttons.
local overlays = setmetatable({}, { __mode = "k" })

local function CreateBorder(parent, thickness)
  local b = {}
  local sides = {
    { "TOPLEFT", "TOPRIGHT", nil, thickness },
    { "BOTTOMLEFT", "BOTTOMRIGHT", nil, thickness },
    { "TOPLEFT", "BOTTOMLEFT", thickness, nil },
    { "TOPRIGHT", "BOTTOMRIGHT", thickness, nil },
  }
  for i, s in ipairs(sides) do
    local t = parent:CreateTexture(nil, "OVERLAY", nil, 5)
    t:SetPoint(s[1], parent, s[1], 0, 0)
    t:SetPoint(s[2], parent, s[2], 0, 0)
    if s[3] then t:SetWidth(s[3]) end
    if s[4] then t:SetHeight(s[4]) end
    t:Hide()
    b[i] = t
  end
  return b
end

local function SetBorder(border, r, g, bl, a, show)
  for i = 1, #border do
    if show then
      border[i]:SetColorTexture(r, g, bl, a)
      border[i]:Show()
    else
      border[i]:Hide()
    end
  end
end

local function GetOverlay(button)
  local ov = overlays[button]
  if ov then
    ov:SetFrameLevel((button:GetFrameLevel() or 1) + 8)
    return ov
  end
  ov = CreateFrame("Frame", nil, button)
  ov:SetAllPoints(button)
  ov:SetFrameLevel((button:GetFrameLevel() or 1) + 8)
  ov.dim = ov:CreateTexture(nil, "OVERLAY", nil, 1)
  ov.dim:SetAllPoints(ov)
  ov.dim:SetColorTexture(0, 0, 0, 0.65)
  ov.dim:Hide()
  ov.glow = ov:CreateTexture(nil, "OVERLAY", nil, 2)
  ov.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  ov.glow:SetBlendMode("ADD")
  ov.glow:SetPoint("CENTER")
  local w, h = button:GetSize()
  if not w or w <= 0 then w, h = 37, 37 end
  ov.glow:SetSize(w * 1.65, h * 1.65)
  ov.glow:Hide()
  ov.border = CreateBorder(ov, 2)
  ov.badgeBg = ov:CreateTexture(nil, "OVERLAY", nil, 6)
  ov.badgeBg:SetSize(16, 16)
  ov.badgeBg:SetPoint("TOPLEFT", 1, -1)
  ov.badgeBg:SetColorTexture(0.05, 0.04, 0.03, 0.90)
  ov.badgeBg:Hide()
  ov.badge = ov:CreateTexture(nil, "OVERLAY", nil, 7)
  ov.badge:SetSize(14, 14)
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
  if type(button.data) == "table" and type(button.data.itemInfo) == "table"
    and type(button.data.itemInfo.itemID) == "number" then
    return button.data.itemInfo.itemID -- BetterBags item button shape
  end
  if type(button.itemID) == "number" then return button.itemID end
  if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
  local bag = (button.GetBagID and button:GetBagID())
    or (button.GetBag and button:GetBag())
    or button.bagID
    or button.bag
    or fallbackBag
  local slot = (button.GetID and button:GetID()) or button.slotID or button.slot
  if not (type(bag) == "number" and type(slot) == "number") then return nil end
  local info = C_Container.GetContainerItemInfo(bag, slot)
  return info and info.itemID or nil
end

local function ApplyButton(button, fallbackBag, idx, focusMode, enabled)
  if not button then return end
  if ns.Reserve and ns.Reserve.AttachButton then ns.Reserve.AttachButton(button, fallbackBag) end
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
    local r, g, bl, a
    if focusMode then
      r, g, bl, a = 1, 0.82, 0.05, 1
    else
      local c = URG_COLOR[hit.urgency] or URG_COLOR[3]
      r, g, bl, a = c[1], c[2], c[3], c[4]
    end
    ov.glow:SetVertexColor(r, g, bl, focusMode and 0.95 or 0.55)
    ov.glow:Show()
    SetBorder(ov.border, r, g, bl, a, true)
    ov.badge:SetTexture(hit.reserved and BADGE_LOCK or BADGE_MAIL)
    ov.badgeBg:Show()
    ov.badge:Show()
  else
    ov.glow:Hide()
    SetBorder(ov.border, 0, 0, 0, 0, false)
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

local function WalkBagBrotherFrame(f, idx, focusMode, enabled)
  if not (f and f[0] and f.IsShown and f:IsShown()) then return end
  if f.IsCached and f:IsCached() then return end -- skip offline alt views
  local grp = f.ItemGroup
  if not grp then return end
  local seen = {}
  if type(grp.buttons) == "table" then
    for _, btn in pairs(grp.buttons) do
      if type(btn) == "table" then
        seen[btn] = true
        ApplyButton(btn, btn.bag or (btn.GetBag and btn:GetBag()), idx, focusMode, enabled)
      end
    end
  end
  if type(grp.byBag) == "table" then
    for bagID, slots in pairs(grp.byBag) do
      if type(slots) == "table" then
        for _, btn in pairs(slots) do
          if type(btn) == "table" and not seen[btn] and btn.IsShown and btn:IsShown() then
            ApplyButton(btn, bagID, idx, focusMode, enabled)
          end
        end
      end
    end
  end
end

local function WalkEllesmere(frame, idx, focusMode, enabled)
  if not (frame and frame.IsShown and frame:IsShown() and frame.GetChildren) then return end
  for _, holder in ipairs({ frame:GetChildren() }) do
    if holder and holder.GetID and holder.GetChildren then
      local bagID = holder:GetID()
      for _, kid in ipairs({ holder:GetChildren() }) do
        if kid and kid.IsObjectType and kid:IsObjectType("ItemButton") then
          ApplyButton(kid, bagID, idx, focusMode, enabled)
        end
      end
    end
  end
end

function Bags.Refresh()
  if not (ComradeCraftDB and ComradeCraftDB.chars) then return end
  local enabled = Bags.On()
  local recipient = Bags.ActiveRecipient()
  local idx = (enabled or recipient) and Bags.BuildIndex(recipient) or {}
  -- Only dim other bag items in focus mode when the recipient actually has >=1 sendable item in bags.
  local focusMode = recipient ~= nil and next(idx) ~= nil
  if recipient and not focusMode and enabled then idx = Bags.BuildIndex(nil) end

  -- 1. Blizzard native bags (combined & individual).
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

  -- 2. ElvUI bags.
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

  -- 3. EllesmereUI bags.
  for _, name in ipairs({ "EUI_Bags", "EUI_BagsReagent" }) do
    local ef = _G[name]
    if ef then WalkEllesmere(ef, idx, focusMode, enabled) end
  end

  -- 4. Bagnon / Combuctor / BagBrother (real frames only, live inventory only).
  for _, addon in ipairs({ _G.Bagnon, _G.Combuctor, _G.BagBrother }) do
    if type(addon) == "table" and addon.Frames and addon.Frames.Iterate then
      local ok, iter, st, k = pcall(addon.Frames.Iterate, addon.Frames)
      if ok and type(iter) == "function" then
        for _, f in iter, st, k do
          WalkBagBrotherFrame(f, idx, focusMode, enabled)
        end
      end
    end
  end

  -- 5. ArkInventory (main bag frame #1).
  local ark = _G.ARKINV_Frame1
  if ark and ark.IsShown and ark:IsShown() then
    for b = 1, 6 do
      for s = 1, 40 do
        local btn = _G["ARKINV_Frame1ScrollContainerBag" .. b .. "Item" .. s]
        if not btn then break end
        if btn:IsShown() then ApplyButton(btn, nil, idx, focusMode, enabled) end
      end
    end
  end

  -- 6. BetterBags (walk active item buttons when BetterBags backpack is open).
  local bbFrame = _G.BetterBagsBagBackpack
  if bbFrame and bbFrame.IsShown and bbFrame:IsShown() then
    local ace = LibStub and LibStub("AceAddon-3.0", true)
    local ok, bb = pcall(function() return ace and ace:GetAddon("BetterBags", true) end)
    local bag = ok and bb and bb.Bags and bb.Bags.Backpack
    if bag and bag.currentView and type(bag.currentView.itemsByBagAndSlot) == "table" then
      for _, it in pairs(bag.currentView.itemsByBagAndSlot) do
        if type(it) == "table" and it.button then
          ApplyButton(it.button, nil, idx, focusMode, enabled)
        end
      end
    end
  end

  -- 7. Baganator official refresh trigger.
  if Baganator and Baganator.API and Baganator.API.RequestItemButtonsRefresh then
    pcall(Baganator.API.RequestItemButtonsRefresh)
  end
end

-- Baganator official corner widget: shows the crisp border, mailbox badge & recipient focus highlight.
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
        local r, g, bl, a
        if focusMode then
          r, g, bl, a = 1, 0.82, 0.05, 1
        else
          local c = URG_COLOR[hit.urgency] or URG_COLOR[3]
          r, g, bl, a = c[1], c[2], c[3], c[4]
        end
        if cornerFrame.glow then
          cornerFrame.glow:SetVertexColor(r, g, bl, focusMode and 0.95 or 0.55)
          cornerFrame.glow:Show()
        end
        if cornerFrame.border then SetBorder(cornerFrame.border, r, g, bl, a, true) end
        if cornerFrame.badgeBg then cornerFrame.badgeBg:Show() end
        if cornerFrame.badge then cornerFrame.badge:Show() end
        return true
      elseif focusMode then
        if cornerFrame.glow then cornerFrame.glow:Hide() end
        if cornerFrame.border then SetBorder(cornerFrame.border, 0, 0, 0, 0, false) end
        if cornerFrame.badgeBg then cornerFrame.badgeBg:Hide() end
        if cornerFrame.badge then cornerFrame.badge:Hide() end
        if cornerFrame.dim then cornerFrame.dim:Show() end
        return true
      end
      return false
    end,
    function(itemButton)
      local f = CreateFrame("Frame", nil, itemButton)
      f:SetSize(16, 16)
      f.dim = f:CreateTexture(nil, "OVERLAY", nil, 1)
      f.dim:SetAllPoints(itemButton)
      f.dim:SetColorTexture(0, 0, 0, 0.65)
      f.dim:Hide()
      f.glow = f:CreateTexture(nil, "OVERLAY", nil, 2)
      f.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
      f.glow:SetBlendMode("ADD")
      f.glow:SetPoint("CENTER", itemButton, "CENTER")
      local w, h = itemButton:GetSize()
      if not w or w <= 0 then w, h = 37, 37 end
      f.glow:SetSize(w * 1.65, h * 1.65)
      f.glow:Hide()
      f.borderHost = CreateFrame("Frame", nil, f)
      f.borderHost:SetAllPoints(itemButton)
      f.border = CreateBorder(f.borderHost, 2)
      f.badgeBg = f:CreateTexture(nil, "OVERLAY", nil, 6)
      f.badgeBg:SetSize(16, 16)
      f.badgeBg:SetPoint("CENTER")
      f.badgeBg:SetColorTexture(0.05, 0.04, 0.03, 0.90)
      f.badge = f:CreateTexture(nil, "OVERLAY", nil, 7)
      f.badge:SetSize(14, 14)
      f.badge:SetPoint("CENTER")
      f.badge:SetTexture("Interface\\Minimap\\Tracking\\Mailbox")
      return f
    end,
    { corner = "top_left", priority = 2 })
end
RegisterBaganator()

local baganatorRegistered, betterBagsRegistered = false, false
local function RegisterBagCategories()
  -- Baganator native category: lets Baganator's auto-sort/layout group all ComradeCraft items together.
  if not baganatorRegistered and Baganator and Baganator.API and Baganator.API.RegisterCategory then
    baganatorRegistered = true
    pcall(Baganator.API.RegisterCategory, "ComradeCraft", "comradecraft_group", function(details)
      if not (details and details.itemID and Bags.On()) then return false end
      return Bags.ItemState(details.itemID) ~= nil
    end)
  end
  -- BetterBags native category: groups items needed/reserved for your group into a "ComradeCraft" section.
  if not betterBagsRegistered and LibStub then
    local ok, bb = pcall(LibStub, "AceAddon-3.0")
    local addon = ok and bb and bb.GetAddon and select(2, pcall(bb.GetAddon, bb, "BetterBags", true))
    local cats = addon and addon.GetModule and select(2, pcall(addon.GetModule, addon, "Categories", true))
    if cats and cats.RegisterCategoryFunction then
      betterBagsRegistered = true
      pcall(cats.RegisterCategoryFunction, cats, "ComradeCraftCategory", function(data)
        local id = data and data.itemInfo and data.itemInfo.itemID
        if id and Bags.On() and Bags.ItemState(id) then return "ComradeCraft" end
      end)
    end
  end
end

-- Debounced refresh when bag addons redraw dozens of slots in a single Layout/Update burst.
local refreshQueued = false
local frameCacheT, frameCacheRecip, frameCacheIdx
local function FastIndex(recipient)
  local now = GetTime and GetTime() or nil
  if now and frameCacheIdx and frameCacheT == now and frameCacheRecip == recipient then
    return frameCacheIdx
  end
  local idx = Bags.BuildIndex(recipient)
  if now then frameCacheT, frameCacheRecip, frameCacheIdx = now, recipient, idx end
  return idx
end
local function QueueRefresh()
  frameCacheIdx = nil
  if refreshQueued then return end
  if C_Timer and C_Timer.After then
    refreshQueued = true
    C_Timer.After(0, function()
      refreshQueued = false
      Bags.Refresh()
    end)
  else
    Bags.Refresh()
  end
end

-- Bagnon / Combuctor / BagBrother / ElvUI / EllesmereUI / BetterBags hooks.
local hookedAddons = {}
local function HookBagAddons()
  RegisterBaganator()
  RegisterBagCategories()
  if not hooksecurefunc then return end
  -- Bagnon / Combuctor / BagBrother: hook ContainerItem, Item, ItemGroup.Layout, and Frames.Show.
  -- (Bagnon mixes ContainerItem.Update onto buttons at Bind time, so hooking Layout & Frames.Show
  -- guarantees every bag open, sort, search or tab switch paints our overlays!)
  for _, name in ipairs({ "Bagnon", "Combuctor", "BagBrother" }) do
    local addon = _G[name]
    if type(addon) == "table" and not hookedAddons[name] then
      hookedAddons[name] = true
      for _, cls in ipairs({ addon.ContainerItem, addon.Item, addon.ItemSlot }) do
        if type(cls) == "table" and type(cls.Update) == "function" then
          pcall(hooksecurefunc, cls, "Update", function(self)
            if self.IsCached and self:IsCached() then return end
            local enabled = Bags.On()
            local recipient = Bags.ActiveRecipient()
            local focusMode = recipient ~= nil
            local idx = (enabled or focusMode) and FastIndex(recipient) or {}
            ApplyButton(self, self.bag or (self.GetBag and self:GetBag()), idx, focusMode, enabled)
          end)
        end
      end
      if type(addon.ItemGroup) == "table" and type(addon.ItemGroup.Layout) == "function" then
        pcall(hooksecurefunc, addon.ItemGroup, "Layout", QueueRefresh)
      end
      if type(addon.Frames) == "table" and type(addon.Frames.Show) == "function" then
        pcall(hooksecurefunc, addon.Frames, "Show", QueueRefresh)
      end
    end
  end
  -- ElvUI bag frame show.
  local elv = _G.ElvUI_ContainerFrame
  if elv and not hookedAddons.ElvUI and elv.HookScript then
    hookedAddons.ElvUI = true
    pcall(elv.HookScript, elv, "OnShow", QueueRefresh)
  end
  -- EllesmereUI bags.
  for _, name in ipairs({ "EUI_Bags", "EUI_BagsReagent" }) do
    local ef = _G[name]
    if ef and not hookedAddons[name] and type(ef.RefreshInventory) == "function" then
      hookedAddons[name] = true
      pcall(hooksecurefunc, ef, "RefreshInventory", QueueRefresh)
      if ef.HookScript then pcall(ef.HookScript, ef, "OnShow", QueueRefresh) end
    end
  end
  -- BetterBags backpack show.
  local bb = _G.BetterBagsBagBackpack
  if bb and not hookedAddons.BetterBags and bb.HookScript then
    hookedAddons.BetterBags = true
    pcall(bb.HookScript, bb, "OnShow", QueueRefresh)
  end
end

local hooked = false
local function HookBags()
  if hooked then return end
  hooked = true
  HookBagAddons()
  if not hooksecurefunc then return end
  if ContainerFrameCombinedBags and ContainerFrameCombinedBags.UpdateItems then
    hooksecurefunc(ContainerFrameCombinedBags, "UpdateItems", QueueRefresh)
  end
  if ContainerFrameContainer and ContainerFrameContainer.ContainerFrames then
    for _, f in ipairs(ContainerFrameContainer.ContainerFrames) do
      if f.UpdateItems then hooksecurefunc(f, "UpdateItems", QueueRefresh) end
    end
  end
  if ContainerFrame_Update then
    hooksecurefunc("ContainerFrame_Update", QueueRefresh)
  end
  for _, fn in ipairs({ "OpenAllBags", "ToggleAllBags", "ToggleBackpack" }) do
    if type(_G[fn]) == "function" then pcall(hooksecurefunc, fn, QueueRefresh) end
  end
end

ns.On("PLAYER_LOGIN", HookBags)
ns.On("BAG_UPDATE_DELAYED", function()
  HookBagAddons()
  Bags.Refresh()
end)
ns.On("PLAYER_ENTERING_WORLD", function()
  HookBagAddons()
  Bags.Refresh()
end)
