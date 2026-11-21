-- Mail: fills a mail to a group member with what they need from this character's bags.
-- Never sends: it sets the recipient/subject and attaches; the player reviews and clicks Send.
-- A compact Blizzard panel docks outside the right edge of MailFrame: pick a recipient or type
-- their name to highlight what they need in your bags and see why (profession & recipe).
local _, ns = ...
local L = ns.L

local Mail = {}
ns.Mail = Mail

local STEP_DELAY = 0.3 -- seconds between attachments, so the bag slot unlocks
local PANEL_W, MAX_ROWS = 250, 8
local isOpen = false

local function NotifyBags()
  if ns.Bags and ns.Bags.Refresh then ns.Bags.Refresh() end
end

ns.On("MAIL_SHOW", function() isOpen = true end)
ns.On("MAIL_CLOSED", function()
  isOpen = false
  NotifyBags()
end)
function Mail.IsOpen() return isOpen end

local function MaxAttachments() return ATTACHMENTS_MAX_SEND or 12 end

-- Group character whose short name matches what was typed in the recipient box.
function Mail.KeyForName(name)
  name = name and name:lower():gsub("%s", "")
  if not name or name == "" then return nil end
  for key in pairs(ns.AllChars()) do
    local short = (key:match("^[^-]+") or key):lower()
    if short == name or key:lower() == name then return key end
  end
end

-- Active group recipient currently typed in the Send Mail box (nil if mailbox/send tab closed).
function Mail.CurrentRecipient()
  if not isOpen then return nil end
  if SendMailFrame and SendMailFrame.IsShown and not SendMailFrame:IsShown() then return nil end
  return Mail.KeyForName(SendMailNameEditBox and SendMailNameEditBox:GetText())
end

-- Items this character can give `to`: { { item, n, prof, spell, step, request } }.
function Mail.ItemsFor(to)
  local out = {}
  for _, g in ipairs(ns.GiveList(ns.CharKey())) do
    if g.to == to then
      out[#out + 1] = { item = g.item, n = g.n, prof = g.prof, spell = g.spell, step = g.step }
    end
  end
  -- Crafted items of accepted requests from that character (when they are in our bags).
  local bags = ns.CharData().bags or {}
  for _, r in pairs(ComradeCraftDB.requests or {}) do
    if r.from == to and r.status == "accepted" and ns.Requests and ns.Requests.Role(r) == "crafter"
      and r.item and r.item ~= 0 and (bags[r.item] or 0) > 0 then
      local mult = (ns.Recipes[r.spell] and ns.Recipes[r.spell][6]) or 1
      out[#out + 1] = { item = r.item, n = math.min(bags[r.item], r.qty * math.max(1, mult)),
        spell = r.spell, request = true }
    end
  end
  return out
end

-- Group members this character currently has items to send to (most urgent first).
function Mail.Recipients()
  local chars = ns.AllChars()
  local byTo, order = {}, {}
  local function Entry(to)
    local e = byTo[to]
    if not e then
      e = { key = to, class = chars[to] and chars[to].class, items = 0, profs = {}, seenProf = {}, bestUrg = 99 }
      byTo[to] = e
      order[#order + 1] = e
    end
    return e
  end
  for _, g in ipairs(ns.GiveList(ns.CharKey())) do
    local e = Entry(g.to)
    e.items = e.items + 1
    e.bestUrg = math.min(e.bestUrg, ns.UrgencyRank(g.step))
    if g.prof and not e.seenProf[g.prof] then
      e.seenProf[g.prof] = true
      e.profs[#e.profs + 1] = g.prof
    end
  end
  local bags = ns.CharData().bags or {}
  for _, r in pairs(ComradeCraftDB.requests or {}) do
    if r.status == "accepted" and ns.Requests and ns.Requests.Role(r) == "crafter"
      and r.item and r.item ~= 0 and (bags[r.item] or 0) > 0 then
      local e = Entry(r.from)
      e.items = e.items + 1
      e.bestUrg = 1
      e.hasRequest = true
    end
  end
  table.sort(order, function(a, b)
    if a.bestUrg ~= b.bestUrg then return a.bestUrg < b.bestUrg end
    if a.items ~= b.items then return a.items > b.items end
    return a.key < b.key
  end)
  return order
end

-- First bag slot holding `item` that is not locked: bag, slot, stack count.
local function FindInBags(item)
  if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID == item and not info.isLocked then return bag, slot, info.stackCount or 1 end
    end
  end
end

local function FreeAttachment()
  for i = 1, MaxAttachments() do
    if not (GetSendMailItem and GetSendMailItem(i)) then return i end
  end
end

-- Attachments to make, split so that each one is a single bag stack (or part of one).
local queue, running = {}, false

local function Step()
  local job = queue[1]
  if not job then
    running = false
    return
  end
  if InCombatLockdown and InCombatLockdown() then
    running = false
    queue = {}
    return
  end
  local index = FreeAttachment()
  if not index then
    ns.Print(L["Mail full (%d attachments): send it, then click again for the rest."]:format(MaxAttachments()))
    queue, running = {}, false
    return
  end
  local bag, slot, stack = FindInBags(job.item)
  if not bag then
    table.remove(queue, 1)
    return C_Timer.After(0, Step)
  end
  local take = math.min(job.n, stack)
  if take < stack then
    C_Container.SplitContainerItem(bag, slot, take)
  else
    C_Container.PickupContainerItem(bag, slot)
  end
  ClickSendMailItemButton(index)
  if CursorHasItem and CursorHasItem() then ClearCursor() end -- never leave an item on the cursor
  job.n = job.n - take
  if job.n <= 0 then table.remove(queue, 1) end
  C_Timer.After(STEP_DELAY, Step)
end

local function EnsureSendForm(to)
  if MailFrameTab_OnClick and MailFrameTab2 and SendMailFrame and not SendMailFrame:IsShown() then
    pcall(MailFrameTab_OnClick, MailFrameTab2, 2) -- the send tab must be active to attach
  end
  if SendMailNameEditBox then SendMailNameEditBox:SetText(to:match("^[^-]+") or to) end
  if SendMailSubjectEditBox and SendMailSubjectEditBox:GetText() == "" then
    SendMailSubjectEditBox:SetText("ComradeCraft")
  end
end

-- Selects a group member in the Send Mail box (highlights their needed items in bags).
function Mail.SelectRecipient(to)
  if not isOpen then return end
  EnsureSendForm(to)
  if Mail.UpdatePanel then Mail.UpdatePanel() end
  NotifyBags()
end

-- Fills the send form for group character `to` (name, subject) and attaches what they need.
function Mail.Prepare(to)
  if not isOpen then
    ns.Print(L["Open a mailbox first."])
    return
  end
  local items = Mail.ItemsFor(to)
  if #items == 0 then
    ns.Print(L["Nothing to give to %s."]:format(to:match("^[^-]+") or to))
    return
  end
  EnsureSendForm(to)
  for _, it in ipairs(items) do queue[#queue + 1] = { item = it.item, n = it.n } end
  ns.Log(("mail: preparing %d item types for %s"):format(#items, to))
  if not running then
    running = true
    Step()
  end
end

-- Attaches a single item stack/amount for `to`.
function Mail.PrepareItem(to, item, n)
  if not isOpen then
    ns.Print(L["Open a mailbox first."])
    return
  end
  EnsureSendForm(to)
  queue[#queue + 1] = { item = item, n = n }
  if not running then
    running = true
    Step()
  end
end

-- Panel docked to the right of the mailbox frame -------------------------------------------

local panel, button, rows

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link = get(id)
  local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
    or (GetItemIcon and GetItemIcon(id)) or 134400
  return name, link, icon
end

local function ItemReason(it)
  if it.request then
    local sn = it.spell and ns.SpellName and ns.SpellName(it.spell)
    return sn and not sn:find("^spell:") and (L["craft request"] .. " - " .. sn) or L["craft request"]
  end
  local parts = {}
  if it.prof then parts[#parts + 1] = it.prof end
  if it.spell and ns.SpellName then
    local sn = ns.SpellName(it.spell)
    if sn and not sn:find("^spell:") then parts[#parts + 1] = sn end
  end
  return table.concat(parts, " - ")
end

local function CreateRow(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(PANEL_W - 20, 28)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(22, 22)
  b.icon:SetPoint("LEFT", 2, 0)
  b.qty = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.qty:SetPoint("TOPRIGHT", -2, -2)
  b.qty:SetJustifyH("RIGHT")
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("TOPLEFT", 28, -2)
  b.name:SetPoint("RIGHT", b.qty, "LEFT", -4, 0)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.sub:SetPoint("BOTTOMLEFT", 28, 2)
  b.sub:SetPoint("RIGHT", -2, 0)
  b.sub:SetJustifyH("LEFT")
  b.sub:SetWordWrap(false)
  b:SetScript("OnEnter", function(self)
    if self.itemID then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.itemID)
      GameTooltip:Show()
    elseif self.recipKey then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(ns.ClassColored(self.recipKey, self.recipClass))
      GameTooltip:AddLine(L["Click to select recipient and highlight needed items in your bags."], 0.5, 0.8, 1, true)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if self.itemID then
      if IsModifiedClick and IsModifiedClick("CHATLINK") then
        local _, link = ItemInfo(self.itemID)
        if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
        return
      end
      if self.to then Mail.PrepareItem(self.to, self.itemID, self.qtyNum or 1) end
    elseif self.recipKey then
      Mail.SelectRecipient(self.recipKey)
    end
  end)
  return b
end

local function UpdatePanel()
  if not panel then return end
  if not isOpen then
    panel:Hide()
    return
  end
  local to = Mail.CurrentRecipient()
  for _, r in ipairs(rows) do
    r:Hide()
    r.itemID, r.recipKey, r.to, r.qtyNum = nil, nil, nil, nil
  end
  local y = -32
  local chars = ns.AllChars()
  if to then
    local items = Mail.ItemsFor(to)
    local cls = chars[to] and chars[to].class
    panel.sub:SetText(L["For %s"]:format(ns.ClassColored(to, cls)))
    panel.back:Show()
    y = y - 16
    if #items == 0 then
      panel.empty:SetText(L["Nothing to give to %s."]:format(to:match("^[^-]+") or to))
      panel.empty:SetPoint("TOPLEFT", 10, y)
      panel.empty:Show()
      y = y - 22
    else
      panel.empty:Hide()
      for i = 1, math.min(#items, MAX_ROWS) do
        local it = items[i]
        local r = rows[i]
        if not r then r = CreateRow(panel) rows[i] = r end
        local name, _, icon = ItemInfo(it.item)
        r.to, r.itemID, r.qtyNum = to, it.item, it.n
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 10, y)
        r.icon:SetTexture(icon)
        r.icon:Show()
        r.name:SetPoint("TOPLEFT", 28, -2)
        r.sub:SetPoint("BOTTOMLEFT", 28, 2)
        r.name:SetText(name or ("item:" .. it.item))
        r.qty:SetText("|cffffd100x" .. it.n .. "|r")
        r.sub:SetText(ItemReason(it))
        r:Show()
        y = y - 30
      end
      if #items > MAX_ROWS then
        panel.empty:SetText(L["and %d more"]:format(#items - MAX_ROWS))
        panel.empty:SetPoint("TOPLEFT", 10, y - 2)
        panel.empty:Show()
        y = y - 18
      end
    end
    button.to = to
    button:SetEnabled(#items > 0)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", 10, y - 4)
    button:Show()
    y = y - 30
    panel.foot:SetText(#items > 0 and ("|cff80ff80" .. L["Highlighted in your bags"] .. "|r") or "")
    panel.foot:SetPoint("TOPLEFT", 10, y - 2)
    panel.foot:SetShown(#items > 0)
    if #items > 0 then y = y - 16 end
  else
    local recips = Mail.Recipients()
    panel.back:Hide()
    button:Hide()
    panel.sub:SetText(L["Ready to send from your bags"])
    y = y - 16
    if #recips == 0 then
      panel.empty:SetText(L["Nothing to send from your bags."])
      panel.empty:SetPoint("TOPLEFT", 10, y)
      panel.empty:Show()
      panel.foot:Hide()
      y = y - 22
    else
      panel.empty:Hide()
      for i = 1, math.min(#recips, MAX_ROWS) do
        local rec = recips[i]
        local r = rows[i]
        if not r then r = CreateRow(panel) rows[i] = r end
        r.recipKey, r.recipClass = rec.key, rec.class
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 10, y)
        r.icon:SetTexture("Interface\\Minimap\\Tracking\\Mailbox")
        r.icon:Show()
        r.name:SetPoint("TOPLEFT", 28, -2)
        r.sub:SetPoint("BOTTOMLEFT", 28, 2)
        r.name:SetText(ns.ClassColored(rec.key, rec.class))
        r.qty:SetText(ns.Plural(rec.items, "%d item", "%d items"))
        local sub = table.concat(rec.profs, ", ")
        if rec.hasRequest then sub = sub ~= "" and (sub .. ", " .. L["craft request"]) or L["craft request"] end
        r.sub:SetText(sub)
        r:Show()
        y = y - 30
      end
      panel.foot:SetText(L["Click a member to highlight their items."])
      panel.foot:SetPoint("TOPLEFT", 10, y - 2)
      panel.foot:Show()
      y = y - 16
    end
  end
  panel:SetHeight(math.max(84, -y + 10))
  panel:Show()
end
Mail.UpdatePanel = UpdatePanel

local function OnMailChanged()
  UpdatePanel()
  NotifyBags()
end

local function CreatePanel()
  local anchor = MailFrame or SendMailFrame
  if panel or not anchor then return end
  panel = CreateFrame("Frame", "ComradeCraftMailPanel", anchor, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(PANEL_W, 120)
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
  panel.title:SetText("ComradeCraft")
  panel.back = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.back:SetSize(56, 18)
  panel.back:SetPoint("TOPRIGHT", -8, -9)
  panel.back:SetText(L["All"])
  panel.back:SetScript("OnClick", function()
    if SendMailNameEditBox then SendMailNameEditBox:SetText("") end
    OnMailChanged()
  end)
  panel.back:Hide()
  panel.sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  panel.sub:SetPoint("TOPLEFT", 10, -30)
  panel.sub:SetWidth(PANEL_W - 20)
  panel.sub:SetJustifyH("LEFT")
  panel.empty = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  panel.empty:SetWidth(PANEL_W - 20)
  panel.empty:SetJustifyH("LEFT")
  panel.foot = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  panel.foot:SetWidth(PANEL_W - 20)
  panel.foot:SetJustifyH("LEFT")
  button = CreateFrame("Button", "ComradeCraftMailButton", panel, "UIPanelButtonTemplate")
  button:SetSize(PANEL_W - 20, 22)
  button:SetText(L["Attach what they need"])
  button:SetScript("OnClick", function(self) if self.to then Mail.Prepare(self.to) end end)
  rows = {}
  if SendMailNameEditBox then SendMailNameEditBox:HookScript("OnTextChanged", OnMailChanged) end
  if SendMailFrame then
    SendMailFrame:HookScript("OnShow", OnMailChanged)
    SendMailFrame:HookScript("OnHide", OnMailChanged)
  end
end

ns.On("MAIL_SHOW", function()
  CreatePanel()
  OnMailChanged()
end)
ns.On("BAG_UPDATE_DELAYED", OnMailChanged)
ns.On("MAIL_SEND_INFO_UPDATE", OnMailChanged)

-- Writes a craft request as a mail (opt-in mode): recipient, subject, note. Never sends.
function Mail.PrepareRequest(r)
  if not isOpen then
    ns.Print(L["Open a mailbox first."])
    return
  end
  if MailFrameTab_OnClick and MailFrameTab2 and SendMailFrame and not SendMailFrame:IsShown() then
    pcall(MailFrameTab_OnClick, MailFrameTab2, 2)
  end
  if SendMailNameEditBox then SendMailNameEditBox:SetText(r.to:match("^[^-]+") or r.to) end
  if SendMailSubjectEditBox then SendMailSubjectEditBox:SetText(ns.Requests.MailSubject(r)) end
  if SendMailBodyEditBox and r.note then SendMailBodyEditBox:SetText(r.note) end
  ns.Print(L["Request mail ready: check it and click Send."])
end

-- /comrade mail NAME: same as the button.
ns.commands.mail = function(name)
  local to = Mail.KeyForName(name)
  if to then Mail.Prepare(to) else ns.Print(L["Type the name of a group member."]) end
end
