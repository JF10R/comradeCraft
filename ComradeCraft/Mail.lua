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
local isOpen, manualTo = false, nil

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

-- Group character whose name matches what was typed in the recipient box (handles Forever
-- two-part names with spaces, e.g. "Mirandaa Jenkins" / "Jhf Mage", and bare first names).
function Mail.KeyForName(name)
  if type(name) ~= "string" then return nil end
  local norm = name:lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
  if norm == "" then return nil end
  local compact = norm:gsub("%s+", "")
  local first = norm:match("^%S+")
  local partial
  for key in pairs(ns.AllChars()) do
    local kl = key:lower()
    local short = (key:match("^[^-]+") or key):lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if short == norm or kl == norm or short:gsub("%s+", "") == compact or kl:gsub("%s+", "") == compact then
      return key
    end
    local sfirst = short:match("^%S+")
    if first and sfirst and sfirst == first then
      partial = partial == nil and key or false -- ambiguous if two chars share first name
    end
  end
  return partial or nil
end

-- Active Postbox frame + Send tab panel when Postbox replaces the native mailbox.
-- Postbox hides MailFrame with SetAlpha(0) and builds PostboxFrame lazily on MAIL_SHOW.
local function PostboxSend()
  local pb = _G.PostboxFrame
  if pb and pb.IsShown and pb:IsShown() then
    return pb, pb.Tabs and pb.Tabs.send or nil
  end
end

-- True when an actual mailbox UI is currently visible (ignores Postbox's alpha-0 MailFrame).
local function MailboxVisible()
  local pb = _G.PostboxFrame
  local hasFrame = false
  if pb and pb.IsShown then
    hasFrame = true
    if pb:IsShown() then return true end
  end
  if MailFrame and MailFrame.IsShown then
    hasFrame = true
    local alpha = MailFrame.GetAlpha and MailFrame:GetAlpha() or 1
    if MailFrame:IsShown() and (not pb or alpha > 0.05) then return true end
  end
  return not hasFrame and isOpen
end

-- Active group recipient currently typed in the Send Mail box (Blizzard or Postbox),
-- or `manualTo` when a legacy 1-word peer was clicked before typing their full name.
function Mail.CurrentRecipient()
  if not (isOpen and MailboxVisible()) then return nil end
  local pb, pbSend = PostboxSend()
  local text
  if pb then
    if not (pbSend and pbSend.IsShown and pbSend:IsShown() and pbSend.ToBox) then return manualTo end
    text = pbSend.ToBox:GetText()
  else
    if SendMailFrame and SendMailFrame.IsShown and not SendMailFrame:IsShown() then return manualTo end
    text = SendMailNameEditBox and SendMailNameEditBox:GetText()
  end
  if text and text ~= "" then return Mail.KeyForName(text) end
  return manualTo
end

-- Items this character can give `to`: { { item, n, inBags, inBank, prof, spell, step, request, recipe } }.
-- Bag-ready items come first; bank-only items are flagged (inBags = 0) and never queued for attach.
function Mail.ItemsFor(to)
  local out = {}
  local me = ns.CharKey()
  local already = {}
  for _, g in ipairs(ns.GiveList(me)) do
    if g.to == to then
      local inBags = g.inBags ~= nil and g.inBags or g.n
      local inBank = g.inBank or 0
      out[#out + 1] = { item = g.item, n = g.n, inBags = inBags, inBank = inBank,
        prof = g.prof, spell = g.spell, step = g.step, convertsTo = g.convertsTo }
      already[g.item] = (already[g.item] or 0) + inBags
    end
  end
  local bags = ns.CharData().bags or {}
  local targetChar = ns.AllChars()[to]
  local targetBags = targetChar and targetChar.bags or {}
  for _, r in pairs(ComradeCraftDB.requests or {}) do
    local dest = ns.Requests and ns.Requests.Recipient and ns.Requests.Recipient(r) or r.from
    -- 1. Crafted items or shared bank items of accepted/crafting requests destined for `to`.
    if dest == to and (r.status == "accepted" or r.status == "crafting")
      and ns.Requests and ns.Requests.Role(r) == "crafter" and r.item and r.item ~= 0 then
      local mult = (r.spell and r.spell > 0 and ns.Recipes[r.spell] and ns.Recipes[r.spell][6]) or 1
      local want = math.max(1, r.qty * math.max(1, mult) - (r.sentQty or 0))
      local inBags = math.min(bags[r.item] or 0, want)
      local bankStock = (ns.CharData().bank or {})[r.item] or 0
      local inBank = math.min(bankStock, math.max(0, want - inBags))
      if (inBags + inBank) > 0 then
        out[#out + 1] = { item = r.item, n = inBags + inBank, inBags = inBags, inBank = inBank,
          spell = r.spell, request = true }
        already[r.item] = (already[r.item] or 0) + inBags
      end
    -- 2. Reagents in our bags for our own pending/accepted outgoing requests TO `to`.
    elseif r.to == to and r.from == me and (r.status == "pending" or r.status == "accepted")
      and ns.Requests and ns.Requests.Role(r) == "requester" then
      local rec = ns.Recipes and ns.Recipes[r.spell]
      local reag = rec and rec[7]
      for i = 1, #(reag or {}), 2 do
        local item, need = reag[i], reag[i + 1] * (r.qty or 1)
        local t = ns.ITEM_TRANSFORMS and ns.ITEM_TRANSFORMS[item]
        local tHave = targetBags[item] or 0
        if t then
          local pHave = targetBags[t.other] or 0
          tHave = tHave + (t.isSmall and (pHave * t.ratio) or math.floor(pHave / t.ratio))
        end
        local miss = math.max(0, need - tHave)
        local spare = (bags[item] or 0) - (already[item] or 0)
        if spare > 0 and miss > 0 and not (ns.IsBoP and ns.IsBoP(item)) then
          local sendN = math.min(spare, miss)
          already[item] = (already[item] or 0) + sendN
          miss = miss - sendN
          out[#out + 1] = { item = item, n = sendN, inBags = sendN, inBank = 0, spell = r.spell, request = true }
        end
        if miss > 0 and t and not (ns.IsBoP and ns.IsBoP(t.other)) then
          local pSpare = (bags[t.other] or 0) - (already[t.other] or 0)
          if pSpare > 0 then
            local wantP = t.isSmall and math.ceil(miss / t.ratio) or (miss * t.ratio)
            local sendP = math.min(pSpare, wantP)
            already[t.other] = (already[t.other] or 0) + sendP
            out[#out + 1] = { item = t.other, n = sendP, inBags = sendP, inBank = 0,
              spell = r.spell, request = true, convertsTo = item }
          end
        end
      end
    end
  end
  -- 3. Unknown non-BoP recipe items (Patterns/Plans/Formulas) in our bags that `to` does not know.
  local bound = ns.CharData().bound or {}
  if ns.Loot and ns.Loot.RecipeStatus then
    for item, count in pairs(bags) do
      if count > 0 and not already[item] and not bound[item] and not (ns.IsBoP and ns.IsBoP(item)) then
        local st = ns.Loot.RecipeStatus(item)
        if st and st.unknown then
          for _, u in ipairs(st.unknown) do
            if u.key == to then
              already[item] = 1
              out[#out + 1] = { item = item, n = 1, inBags = 1, inBank = 0,
                prof = u.prof, spell = st.spell, recipe = true }
              break
            end
          end
        end
      end
    end
  end
  -- 4. Items manually reserved ("for Mirandaa") by the current character.
  if ns.Reserve and ns.Reserve.ForTarget then
    for _, rv in ipairs(ns.Reserve.ForTarget(to)) do
      if not already[rv.item] then
        already[rv.item] = rv.inBags
        out[#out + 1] = { item = rv.item, n = rv.n, inBags = rv.inBags, inBank = rv.inBank,
          step = 1, reserved = true }
      end
    end
  end
  table.sort(out, function(a, b)
    local ab, bb = (a.inBags or 0) > 0, (b.inBags or 0) > 0
    if ab ~= bb then return ab end
    return (a.step or 99) < (b.step or 99)
  end)
  return out
end

-- Group members this character currently has items to send to (bag-ready first, then bank-only).
function Mail.Recipients()
  local chars = ns.AllChars()
  local me = ns.CharKey()
  local byTo, order = {}, {}
  local function Entry(to)
    local e = byTo[to]
    if not e then
      e = { key = to, class = chars[to] and chars[to].class, items = 0, bagItems = 0, bankItems = 0,
        profs = {}, seenProf = {}, bestUrg = 99 }
      byTo[to] = e
      order[#order + 1] = e
    end
    return e
  end
  for _, g in ipairs(ns.GiveList(me)) do
    local e = Entry(g.to)
    e.items = e.items + 1
    if (g.inBags ~= nil and g.inBags or g.n) > 0 then e.bagItems = e.bagItems + 1
    else e.bankItems = e.bankItems + 1 end
    e.bestUrg = math.min(e.bestUrg, ns.UrgencyRank(g.step))
    if g.prof and not e.seenProf[g.prof] then
      e.seenProf[g.prof] = true
      e.profs[#e.profs + 1] = g.prof
    end
  end
  local bags = ns.CharData().bags or {}
  for _, r in pairs(ComradeCraftDB.requests or {}) do
    local dest = ns.Requests and ns.Requests.Recipient and ns.Requests.Recipient(r) or r.from
    if (r.status == "accepted" or r.status == "crafting") and ns.Requests and ns.Requests.Role(r) == "crafter"
      and r.item and r.item ~= 0 and (bags[r.item] or 0) > 0 and dest then
      local e = Entry(dest)
      e.items = e.items + 1
      e.bagItems = e.bagItems + 1
      e.bestUrg = 1
      e.hasRequest = true
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
        local hasDirect = (bags[item] or 0) > 0 and not (ns.IsBoP and ns.IsBoP(item))
        local hasConv = t and (bags[t.other] or 0) > 0 and not (ns.IsBoP and ns.IsBoP(t.other))
        if tHave < need and (hasDirect or hasConv) then
          local e = Entry(r.to)
          e.items = e.items + 1
          e.bagItems = e.bagItems + 1
          e.bestUrg = 1
          e.hasRequest = true
        end
      end
    end
  end
  -- Unknown non-BoP recipe items in our bags for other group members (highest-rank crafter first).
  local bound = ns.CharData().bound or {}
  if ns.Loot and ns.Loot.RecipeStatus then
    for item, count in pairs(bags) do
      if count > 0 and not bound[item] and not (ns.IsBoP and ns.IsBoP(item)) then
        local st = ns.Loot.RecipeStatus(item)
        if st and st.unknown then
          for _, u in ipairs(st.unknown) do
            if u.key ~= me then
              local e = Entry(u.key)
              e.items = e.items + 1
              e.bagItems = e.bagItems + 1
              e.bestUrg = math.min(e.bestUrg, u.rank >= u.req and 1 or 2)
              if u.prof and not e.seenProf[u.prof] then
                e.seenProf[u.prof] = true
                e.profs[#e.profs + 1] = u.prof
              end
              break -- attribute each recipe scroll to the top unknown crafter in the group
            end
          end
        end
      end
    end
  end
  -- 4. Manually reserved items ("for Mirandaa") on the current character.
  local meData = ns.CharData()
  for item, rv in pairs(meData and meData.reserved or {}) do
    if rv and rv.to and rv.to ~= me then
      local inBags = math.min((bags[item] or 0), rv.qty or (bags[item] or 0))
      local inBank = math.min(((meData.bank or {})[item] or 0), math.max(0, (rv.qty or 0) - inBags))
      if (inBags + inBank) > 0 then
        local e = Entry(rv.to)
        e.items = e.items + 1
        if inBags > 0 then e.bagItems = e.bagItems + 1 else e.bankItems = e.bankItems + 1 end
        e.bestUrg = 1
        e.hasRequest = true
      end
    end
  end
  table.sort(order, function(a, b)
    local ab, bb = a.bagItems > 0, b.bagItems > 0
    if ab ~= bb then return ab end
    if a.bestUrg ~= b.bestUrg then return a.bestUrg < b.bestUrg end
    if a.items ~= b.items then return a.items > b.items end
    return a.key < b.key
  end)
  return order
end

-- First bag slot holding `item` that is not locked (includes Reagent Bag): bag, slot, stack count.
local function FindInBags(item)
  if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
  local lastBag = (NUM_BAG_SLOTS or 4) + ((NUM_REAGENTBAG_SLOTS and NUM_REAGENTBAG_SLOTS > 0) and 1 or 0)
  for bag = 0, lastBag do
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
local queue, running, queueTo, queueBox = {}, false, nil, nil -- queueBox: recipient the To box resolved to
local function ResetQueue() queue, running, queueTo, queueBox = {}, false, nil, nil end

local function Step()
  local job = queue[1]
  if not job then
    running = false
    return
  end
  local cur = isOpen and Mail.CurrentRecipient()
  if not isOpen or (InCombatLockdown and InCombatLockdown()) or (cur and cur ~= queueBox) then
    return ResetQueue() -- mailbox closed or another recipient typed: stop attaching
  end
  local index = FreeAttachment()
  if not index then
    ns.Print(L["Mail full (%d attachments): send it, then click again for the rest."]:format(MaxAttachments()))
    return ResetQueue()
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

local function CurrentToText()
  local pb, pbSend = PostboxSend()
  if pb and pbSend and pbSend.ToBox then return pbSend.ToBox:GetText() or "" end
  if SendMailNameEditBox then return SendMailNameEditBox:GetText() or "" end
  return ""
end

-- Prepares the Send Mail form (Postbox or Blizzard) for recipient `to`.
-- SAFETY on WoW Forever (two-part names): never overwrite an existing full "First Last" in the
-- To: box with a legacy single-word name, and refuse to auto-fill a half-name (prevents mailing
-- loot to the wrong player). Returns true when safe to attach/proceed.
local function EnsureSendForm(to, selecting)
  local short = to:match("^[^-]+") or to
  local pb, pbSend = PostboxSend()
  if pb and pbSend and pbSend.IsShown and not pbSend:IsShown() and pb.TabButtons and pb.TabButtons.send then
    local btn = pb.TabButtons.send
    if btn.Click then pcall(btn.Click, btn)
    else
      local fn = btn.GetScript and btn:GetScript("OnClick")
      if fn then pcall(fn, btn) end
    end
  elseif not pb and MailFrameTab_OnClick and MailFrameTab2 and SendMailFrame and not SendMailFrame:IsShown() then
    pcall(MailFrameTab_OnClick, MailFrameTab2, 2) -- the send tab must be active to attach
  end

  local writeName = short
  local needManualName = false
  if ns.TwoPartNames and ns.TwoPartNames() and not short:find(" ", 1, true) then
    local cur = CurrentToText()
    if cur:match("%S+%s+%S+") and Mail.KeyForName(cur) == to then
      if ns.RememberFullName then ns.RememberFullName(cur) end
      writeName = nil -- keep the full two-part name already typed in the mailbox!
    else
      local resolved = ns.ResolveFullName and ns.ResolveFullName(short)
      if resolved then
        writeName = resolved
      else
        needManualName = true
        manualTo = to
        writeName = "" -- clear any previous recipient so items are never sent to the wrong player
        if not selecting then
          ns.Print(L["Full name (First Last) required for %s: log them in once or type their full name first."]:format(short))
        end
      end
    end
  end
  if not needManualName then manualTo = nil end

  if pb then
    pbSend = pb.Tabs and pb.Tabs.send
    if writeName ~= nil and pbSend and pbSend.ToBox then
      pbSend.ToBox:SetText(writeName)
      if pbSend.ToBox.SetCursorPosition then pbSend.ToBox:SetCursorPosition(#writeName) end
      if needManualName and pbSend.ToBox.SetFocus then pbSend.ToBox:SetFocus() end
    end
    if pbSend and pbSend.SubjectBox and (pbSend.SubjectBox:GetText() or "") == "" then
      pbSend.SubjectBox:SetText("ComradeCraft")
    end
    return true
  end
  if writeName ~= nil and SendMailNameEditBox then
    SendMailNameEditBox:SetText(writeName)
    if needManualName and SendMailNameEditBox.SetFocus then SendMailNameEditBox:SetFocus() end
  end
  if SendMailSubjectEditBox and SendMailSubjectEditBox:GetText() == "" then
    SendMailSubjectEditBox:SetText("ComradeCraft")
  end
  return true
end

-- Selects a group member in the Send Mail box (highlights their needed items in bags).
function Mail.SelectRecipient(to)
  if not isOpen then return end
  EnsureSendForm(to, true)
  if Mail.UpdatePanel then Mail.UpdatePanel() end
  NotifyBags()
end

-- Fills the send form for group character `to` (name, subject) and attaches what is in bags.
function Mail.Prepare(to)
  if not isOpen then
    ns.Print(L["Open a mailbox first."])
    return
  end
  local items = Mail.ItemsFor(to)
  local ready = {}
  for _, it in ipairs(items) do
    if (it.inBags or 0) > 0 then ready[#ready + 1] = it end
  end
  if #ready == 0 then
    ns.Print(#items > 0 and L["In bank (retrieve first)"] or L["Nothing to give to %s."]:format(to:match("^[^-]+") or to))
    return
  end
  if running and queueTo == to then return end -- double click: already attaching these
  if not EnsureSendForm(to) then return end
  if queueTo ~= to then ResetQueue() end
  queueTo, queueBox = to, Mail.CurrentRecipient() or to
  for _, it in ipairs(ready) do queue[#queue + 1] = { item = it.item, n = it.inBags } end
  ns.Log(("mail: preparing %d item types for %s"):format(#ready, to))
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
  if not EnsureSendForm(to) then return end
  if queueTo ~= to then ResetQueue() end
  queueTo, queueBox = to, Mail.CurrentRecipient() or to
  for _, job in ipairs(queue) do if job.item == item then return end end -- already queued
  queue[#queue + 1] = { item = item, n = n }
  if not running then
    running = true
    Step()
  end
end

-- Panel docked to the right of the mailbox frame (Blizzard MailFrame or PostboxFrame) -----

local panel, button, rows, postboxHooked

local function MailAnchor()
  local pb = PostboxSend()
  if pb then return pb end
  -- Fallback for other mail addons (Postal, EasyMail, ElvUI, etc. decorate MailFrame;
  -- TSM Mailing hides MailFrame when its own UI is active).
  if MailFrame and MailFrame.IsShown and MailFrame:IsShown()
    and (not MailFrame.GetAlpha or MailFrame:GetAlpha() > 0.05) then
    return MailFrame
  end
  if SendMailFrame and SendMailFrame.IsShown and SendMailFrame:IsShown()
    and (not SendMailFrame.GetAlpha or SendMailFrame:GetAlpha() > 0.05) then
    return SendMailFrame
  end
  return nil
end

local function AnchorPanel()
  if not panel then return end
  local anchor = MailAnchor()
  panel:ClearAllPoints()
  if anchor then
    panel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, -24)
  else
    -- Custom mail UI (e.g. TSM Mailing) hid MailFrame: dock cleanly on screen instead of disappearing.
    panel:SetPoint("LEFT", UIParent, "CENTER", 220, 40)
  end
end

local function ItemInfo(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link = get and get(id)
  if not name and ns.ItemName then name = ns.ItemName(id) end
  local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
    or (GetItemIcon and GetItemIcon(id)) or 134400
  return name, link, icon
end

local function ItemReason(it)
  local base
  if it.reserved then
    base = L["Reserved"]
  elseif it.request then
    local sn = it.spell and it.spell > 0 and ns.SpellName and ns.SpellName(it.spell)
    base = sn and not sn:find("^spell:") and (L["craft request"] .. " - " .. sn) or L["craft request"]
  else
    local parts = {}
    if it.prof then parts[#parts + 1] = it.prof end
    if it.spell and ns.SpellName then
      local sn = ns.SpellName(it.spell)
      if sn and not sn:find("^spell:") then parts[#parts + 1] = sn end
    end
    base = table.concat(parts, " - ")
  end
  if it.convertsTo then
    local tn = ns.ItemName and ns.ItemName(it.convertsTo) or ("item:" .. it.convertsTo)
    return base ~= "" and (base .. " -> " .. tn) or ("-> " .. tn)
  end
  return base
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
      if self.to and (self.qtyNum or 0) > 0 then Mail.PrepareItem(self.to, self.itemID, self.qtyNum) end
    elseif self.recipKey then
      Mail.SelectRecipient(self.recipKey)
    end
  end)
  return b
end

-- Next group member who still has bag-ready items to mail (for 1-click Mailbox Tour).
function Mail.NextRecipient(excludeKey)
  local recips = Mail.Recipients()
  local others = {}
  for _, rec in ipairs(recips) do
    if (rec.bagItems or 0) > 0 and rec.key ~= excludeKey then
      others[#others + 1] = rec
    end
  end
  return others[1] and others[1].key or nil, #others
end

local dismissed = false
local function UpdatePanel()
  if not panel then return end
  if dismissed or not (isOpen and MailboxVisible() and (not ns.PanelEnabled or ns.PanelEnabled("mail"))) then
    panel:Hide()
    return
  end
  AnchorPanel()
  local to = Mail.CurrentRecipient()
  for _, r in ipairs(rows) do
    r:Hide()
    r.itemID, r.recipKey, r.to, r.qtyNum = nil, nil, nil, nil
  end
  if panel.nextBtn then panel.nextBtn:Hide() end
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
      local bagReadyCount = 0
      for i = 1, #items do
        if (items[i].inBags or 0) > 0 then bagReadyCount = bagReadyCount + 1 end
      end
      for i = 1, math.min(#items, MAX_ROWS) do
        local it = items[i]
        local r = rows[i]
        if not r then r = CreateRow(panel) rows[i] = r end
        local name, _, icon = ItemInfo(it.item)
        local inBags, inBank = it.inBags or 0, it.inBank or 0
        local bankOnly = inBags == 0
        r.to, r.itemID, r.qtyNum = to, it.item, inBags
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 10, y)
        r.icon:SetTexture(icon)
        r.icon:SetDesaturated(bankOnly)
        r.icon:SetAlpha(bankOnly and 0.55 or 1)
        r.icon:Show()
        r.name:SetPoint("TOPLEFT", 28, -2)
        r.sub:SetPoint("BOTTOMLEFT", 28, 2)
        local dname = name or ("item:" .. it.item)
        r.name:SetText(bankOnly and ("|cff888888" .. dname .. "|r") or dname)
        if bankOnly then
          r.qty:SetText(("|cff888888x%d (%s)|r"):format(inBank, L["in bank"]))
        elseif inBank > 0 then
          r.qty:SetText(("|cffffd100x%d|r |cff888888(+%d %s)|r"):format(inBags, inBank, L["in bank"]))
        else
          r.qty:SetText("|cffffd100x" .. inBags .. "|r")
        end
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
      button.bagReadyCount = bagReadyCount
    end
    local bagReady = #items > 0 and (button.bagReadyCount or 0) > 0
    button.to = to
    button:SetEnabled(bagReady)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", 10, y - 4)
    button:Show()
    y = y - 30
    local nextKey, nextCount = Mail.NextRecipient(to)
    if nextKey and panel.nextBtn then
      panel.nextBtn.nextKey = nextKey
      panel.nextBtn:SetText(L["Next: %s (%d left)"]:format(nextKey:match("^[^-]+") or nextKey, nextCount))
      panel.nextBtn:ClearAllPoints()
      panel.nextBtn:SetPoint("TOPLEFT", 10, y - 2)
      panel.nextBtn:Show()
      y = y - 26
    end
    if bagReady then
      panel.foot:SetText("|cff80ff80" .. L["Highlighted in your bags"] .. "|r")
    elseif #items > 0 then
      panel.foot:SetText("|cff9d9d9d" .. L["In bank (retrieve first)"] .. "|r")
    else
      panel.foot:SetText("")
    end
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
        local bankOnly = (rec.bagItems or 0) == 0
        r.recipKey, r.recipClass = rec.key, rec.class
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 10, y)
        r.icon:SetTexture("Interface\\Minimap\\Tracking\\Mailbox")
        r.icon:SetDesaturated(bankOnly)
        r.icon:SetAlpha(bankOnly and 0.55 or 1)
        r.icon:Show()
        r.name:SetPoint("TOPLEFT", 28, -2)
        r.sub:SetPoint("BOTTOMLEFT", 28, 2)
        r.name:SetText(ns.ClassColored(rec.key, rec.class))
        r.qty:SetText(bankOnly and ("|cff888888" .. L["in bank"] .. "|r")
          or ns.Plural(rec.bagItems, "%d item", "%d items"))
        local sub = table.concat(rec.profs, ", ")
        if rec.hasRequest then sub = sub ~= "" and (sub .. ", " .. L["craft request"]) or L["craft request"] end
        if bankOnly then sub = sub ~= "" and (sub .. " (" .. L["in bank"] .. ")") or L["in bank"] end
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
  local cur = CurrentToText()
  if cur:match("%S+%s+%S+") and Mail.KeyForName(cur) and ns.RememberFullName then
    ns.RememberFullName(cur)
  end
  UpdatePanel()
  NotifyBags()
end

local function OnMailboxHide()
  isOpen, manualTo = false, nil
  ResetQueue()
  if panel then panel:Hide() end
  NotifyBags()
end

local function OnSendTabHide()
  if MailboxVisible() then OnMailChanged() else OnMailboxHide() end
end

local mailFrameHooked
local function HookPostbox()
  if MailFrame and mailFrameHooked ~= MailFrame and MailFrame.HookScript then
    mailFrameHooked = MailFrame
    MailFrame:HookScript("OnHide", function()
      if not MailboxVisible() then OnMailboxHide() end
    end)
  end
  local pb, pbSend = PostboxSend()
  if not pb or postboxHooked == pb then return end
  postboxHooked = pb
  if pb.HookScript then
    pb:HookScript("OnShow", function()
      isOpen = true
      dismissed = false
      OnMailChanged()
    end)
    pb:HookScript("OnHide", OnMailboxHide)
  end
  if pbSend then
    if pbSend.HookScript then
      pbSend:HookScript("OnShow", OnMailChanged)
      pbSend:HookScript("OnHide", OnSendTabHide)
    end
    if pbSend.ToBox and pbSend.ToBox.HookScript then
      pbSend.ToBox:HookScript("OnTextChanged", OnMailChanged)
    end
  end
end

local function CreatePanel()
  if panel then return end
  if not (isOpen or MailAnchor()) then return end
  -- Parent to UIParent (never MailFrame): Postbox hides MailFrame via SetAlpha(0), which
  -- would otherwise make any child of MailFrame invisible too.
  panel = CreateFrame("Frame", "ComradeCraftMailPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(PANEL_W, 120)
  panel:SetFrameStrata("DIALOG")
  AnchorPanel()
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
  panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  panel.close:SetSize(22, 22)
  panel.close:SetPoint("TOPRIGHT", -2, -2)
  panel.close:SetScript("OnClick", function()
    dismissed = true
    panel:Hide()
  end)
  panel.back = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.back:SetSize(52, 18)
  panel.back:SetPoint("RIGHT", panel.close, "LEFT", -2, 0)
  panel.back:SetText(L["All"])
  panel.back:SetScript("OnClick", function()
    manualTo = nil
    local _, pbSend = PostboxSend()
    if pbSend and pbSend.ToBox then pbSend.ToBox:SetText("")
    elseif SendMailNameEditBox then SendMailNameEditBox:SetText("") end
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
  panel.nextBtn = CreateFrame("Button", "ComradeCraftMailNextButton", panel, "UIPanelButtonTemplate")
  panel.nextBtn:SetSize(PANEL_W - 20, 20)
  panel.nextBtn:SetScript("OnClick", function(self)
    if self.nextKey then Mail.SelectRecipient(self.nextKey) end
  end)
  panel.nextBtn:Hide()
  rows = {}
  if SendMailNameEditBox then SendMailNameEditBox:HookScript("OnTextChanged", OnMailChanged) end
  if SendMailFrame then
    SendMailFrame:HookScript("OnShow", OnMailChanged)
    SendMailFrame:HookScript("OnHide", OnSendTabHide)
  end
  HookPostbox()
end

local function SyncMailboxPanel()
  CreatePanel()
  HookPostbox()
  OnMailChanged()
end

local pendingSend
local sendMailHooked
local function HookSendMail()
  if sendMailHooked or not (hooksecurefunc and SendMail) then return end
  sendMailHooked = true
  hooksecurefunc("SendMail", function(target)
    if ns.RememberFullName then ns.RememberFullName(target) end
    local toKey = Mail.KeyForName(target)
    if not toKey then pendingSend = nil return end
    local items = {}
    for i = 1, MaxAttachments() do
      local link = GetSendMailItemLink and GetSendMailItemLink(i)
      local id = link and tonumber(link:match("item:(%d+)"))
      if id then
        local _, _, _, count = GetSendMailItem and GetSendMailItem(i)
        items[id] = (items[id] or 0) + (count or 1)
      end
    end
    pendingSend = next(items) and { to = toKey, items = items } or nil
  end)
end

ns.On("MAIL_SHOW", function()
  dismissed = false
  HookSendMail()
  SyncMailboxPanel()
  -- Postbox builds and shows PostboxFrame lazily on MAIL_SHOW; re-anchor one tick later.
  if C_Timer and C_Timer.After then
    C_Timer.After(0, SyncMailboxPanel)
    C_Timer.After(0.2, SyncMailboxPanel)
  end
end)
ns.On("MAIL_SEND_SUCCESS", function()
  if pendingSend then
    if ns.RecordInTransit then ns.RecordInTransit(pendingSend.to, pendingSend.items) end
    if ns.Requests and ns.Requests.OnItemSent then
      for itemID, qty in pairs(pendingSend.items) do
        ns.Requests.OnItemSent(pendingSend.to, itemID, qty)
      end
    end
  end
  pendingSend = nil
  if C_Timer and C_Timer.After then C_Timer.After(0.25, OnMailChanged) else OnMailChanged() end
end)
ns.On("MAIL_FAILED", function() pendingSend = nil end)
ns.On("MAIL_CLOSED", function() pendingSend = nil OnMailboxHide() end)
ns.On("BAG_UPDATE_DELAYED", function() if isOpen then OnMailChanged() end end) -- Bags.lua refreshes itself
ns.On("MAIL_SEND_INFO_UPDATE", OnMailChanged)

-- Writes a craft request as a mail (opt-in mode): recipient, subject, note. Never sends.
function Mail.PrepareRequest(r)
  if not isOpen then
    ns.Print(L["Open a mailbox first."])
    return
  end
  if not EnsureSendForm(r.to) then return end
  local pb, pbSend = PostboxSend()
  if pb and pbSend then
    if pbSend.SubjectBox then pbSend.SubjectBox:SetText(ns.Requests.MailSubject(r)) end
    if pbSend.BodyBox and r.note then pbSend.BodyBox:SetText(r.note) end
  else
    if SendMailSubjectEditBox then SendMailSubjectEditBox:SetText(ns.Requests.MailSubject(r)) end
    if SendMailBodyEditBox and r.note then SendMailBodyEditBox:SetText(r.note) end
  end
  ns.Print(L["Request mail ready: check it and click Send."])
end

-- /comrade mail NAME: same as the button.
ns.commands.mail = function(name)
  local to = Mail.KeyForName(name)
  if to then Mail.Prepare(to) else ns.Print(L["Type the name of a group member."]) end
end
