-- Mail: fills a mail to a group member with what they need from this character's bags.
-- Never sends: it sets the recipient/subject and attaches; the player reviews and clicks Send.
-- A button docks outside the right edge of the send-mail frame (no overlap with Postal etc.);
-- the "You can give" entries of the main window do the same while the mailbox is open.
local _, ns = ...
local L = ns.L

local Mail = {}
ns.Mail = Mail

local STEP_DELAY = 0.3 -- seconds between attachments, so the bag slot unlocks
local isOpen = false

ns.On("MAIL_SHOW", function() isOpen = true end)
ns.On("MAIL_CLOSED", function() isOpen = false end)
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

-- Items this character can give `to`: { { item, n } } from the give list.
function Mail.ItemsFor(to)
  local out = {}
  for _, g in ipairs(ns.GiveList(ns.CharKey())) do
    if g.to == to then out[#out + 1] = { item = g.item, n = g.n } end
  end
  -- Crafted items of accepted requests from that character (when they are in our bags).
  local bags = ns.CharData().bags or {}
  for _, r in pairs(ComradeCraftDB.requests or {}) do
    if r.from == to and r.status == "accepted" and ns.Requests and ns.Requests.Role(r) == "crafter"
      and r.item and r.item ~= 0 and (bags[r.item] or 0) > 0 then
      out[#out + 1] = { item = r.item, n = math.min(bags[r.item], r.qty * math.max(1, ns.Recipes[r.spell][6])) }
    end
  end
  return out
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
  if MailFrameTab_OnClick and MailFrameTab2 and SendMailFrame and not SendMailFrame:IsShown() then
    pcall(MailFrameTab_OnClick, MailFrameTab2, 2) -- the send tab must be active to attach
  end
  if SendMailNameEditBox then SendMailNameEditBox:SetText(to:match("^[^-]+") or to) end
  if SendMailSubjectEditBox and SendMailSubjectEditBox:GetText() == "" then
    SendMailSubjectEditBox:SetText("ComradeCraft")
  end
  for _, it in ipairs(items) do queue[#queue + 1] = { item = it.item, n = it.n } end
  ns.Log(("mail: preparing %d item types for %s"):format(#items, to))
  if not running then
    running = true
    Step()
  end
end

-- Button docked to the right of the send-mail frame -----------------------------------------

local button
local function UpdateButton()
  if not button then return end
  local to = Mail.KeyForName(SendMailNameEditBox and SendMailNameEditBox:GetText())
  button.to = to
  button:SetEnabled(to ~= nil and #Mail.ItemsFor(to) > 0)
end

local function CreateButton()
  if button or not SendMailFrame then return end
  button = CreateFrame("Button", "ComradeCraftMailButton", SendMailFrame, "UIPanelButtonTemplate")
  button:SetSize(170, 24)
  button:SetPoint("TOPLEFT", SendMailFrame, "TOPRIGHT", 4, -30)
  button:SetText(L["Attach what they need"])
  button:SetScript("OnClick", function(self) if self.to then Mail.Prepare(self.to) end end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("ComradeCraft")
    if not self.to then
      GameTooltip:AddLine(L["Type the name of a group member."], 1, 1, 1, true)
    else
      local items = Mail.ItemsFor(self.to)
      if #items == 0 then GameTooltip:AddLine(L["Nothing to give to %s."]:format(self.to:match("^[^-]+") or self.to), 1, 1, 1) end
      for _, it in ipairs(items) do
        local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
        GameTooltip:AddDoubleLine(get(it.item) or ("item:" .. it.item), "x" .. it.n, 1, 1, 1, 1, 1, 1)
      end
    end
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  if SendMailNameEditBox then SendMailNameEditBox:HookScript("OnTextChanged", UpdateButton) end
  button:HookScript("OnShow", UpdateButton)
end

ns.On("MAIL_SHOW", function()
  CreateButton()
  UpdateButton()
end)
ns.On("BAG_UPDATE_DELAYED", UpdateButton)

-- /comrade mail NAME: same as the button.
ns.commands.mail = function(name)
  local to = Mail.KeyForName(name)
  if to then Mail.Prepare(to) else ns.Print(L["Type the name of a group member."]) end
end
