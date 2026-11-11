-- Requests: ask a group member's character to craft something. Stored on both sides and
-- carried by the sync (whispers to players you added); a change waits in an outbox until the
-- other player's addon acknowledges it, so it reaches them the next time you are both online.
-- Statuses: pending -> accepted | declined -> done; the requester can cancel.
local _, ns = ...
local L = ns.L

local Requests = {}
ns.Requests = Requests

local RESEND = 60          -- seconds between two resends of unacknowledged changes to a peer
local KEEP_DAYS = 14       -- finished requests are forgotten after this
local STATUS = { pending = true, accepted = true, declined = true, done = true, cancelled = true }
local BY_CRAFTER = { accepted = true, declined = true, done = true }

local function Now() return (GetServerTime and GetServerTime()) or time() end
local function DB()
  ComradeCraftDB.requests = ComradeCraftDB.requests or {}
  return ComradeCraftDB.requests
end

-- Role of this account in a request: "crafter" (it is for one of our characters) or "requester".
function Requests.Role(r)
  return ComradeCraftDB.chars and ComradeCraftDB.chars[r.to] and not r.toPeer and "crafter" or "requester"
end

-- The other side's account id.
local function OtherPeer(r) return Requests.Role(r) == "crafter" and r.fromPeer or r.toPeer end

local function Wire(r)
  return { rid = r.id, from = r.from, to = r.to, spell = r.spell, qty = r.qty, note = r.note,
    status = r.status, u = r.updated, c = r.created }
end

local lastSend = {} -- [peerID] = time of the last outbox flush

local function Send(r)
  local peer = ComradeCraftDB.peers and ComradeCraftDB.peers[OtherPeer(r) or ""]
  if not (ns.Sync and peer and peer.included and peer.name) then return end
  ns.Sync.Send({ t = "Q", v = ns.Sync.PROTO, id = ComradeCraftDB.accountId, q = Wire(r) }, "WHISPER", peer.name)
end

-- Sends every change the peer has not acknowledged yet (on any message from them).
function Requests.OnPeerSeen(id)
  local since = Now() - (lastSend[id] or 0)
  if since >= 0 and since < RESEND then return end -- (a clock that went back does not block)
  lastSend[id] = Now()
  for _, r in pairs(DB()) do
    if OtherPeer(r) == id and r.acked ~= r.updated then Send(r) end
  end
end

-- Pure: a request received from a peer, validated (nil if malformed).
function Requests.Clean(q)
  if type(q) ~= "table" then return nil end
  -- No control characters and no "|" (color, texture and link codes) in text shown to the player.
  local function S(v, n) return type(v) == "string" and #v > 0 and #v <= n and not v:find("[%c|]") and v or nil end
  local function N(v, lo, hi) return type(v) == "number" and v >= lo and v <= hi and math.floor(v) or nil end
  local out = { id = S(q.rid, 48), from = S(q.from, 80), to = S(q.to, 80), spell = N(q.spell, 1, 2 ^ 31),
    qty = N(q.qty, 1, 1000), note = S(q.note, 120), status = STATUS[q.status] and q.status or nil,
    updated = N(q.u, 0, 2 ^ 31), created = N(q.c, 0, 2 ^ 31) }
  if not (out.id and out.from and out.to and out.spell and ns.Recipes[out.spell] and out.qty and out.status
    and out.updated) then return nil end
  out.item = ns.Recipes[out.spell][5]
  return out
end

-- A request (new or changed) from peer `id`, whispered by `sender`. Acknowledged either way.
function Requests.OnRemote(id, q, sender)
  local clean = Requests.Clean(q)
  if not clean then return end
  local db = DB()
  local mine = db[clean.id]
  local function Ack()
    ns.Sync.Send({ t = "A", v = ns.Sync.PROTO, id = ComradeCraftDB.accountId, rid = clean.id, u = clean.updated },
      "WHISPER", sender)
  end
  if not mine then
    -- New: only kept when it is for one of our characters and still open. Always acknowledged
    -- (or it would be re-sent forever); one for a character we do not have is declined.
    if not (ComradeCraftDB.chars[clean.to] and clean.status == "pending") then
      Ack()
      if clean.status == "pending" then
        local back = Wire(clean)
        back.status, back.u = "declined", Now()
        ns.Sync.Send({ t = "Q", v = ns.Sync.PROTO, id = ComradeCraftDB.accountId, q = back }, "WHISPER", sender)
      end
      return
    end
    clean.fromPeer, clean.acked = id, clean.updated
    db[clean.id] = clean
    if ns.Alerts and ns.Alerts.On("requests") then
      ns.Alerts.Notify({ title = L["New craft request"],
        text = L["%s asks %s to craft %dx %s."]:format(clean.from:match("^[^-]+") or clean.from,
          clean.to:match("^[^-]+") or clean.to, clean.qty, ns.SpellName(clean.spell)),
        item = clean.item ~= 0 and clean.item or nil,
        buttons = { { L["Open"], function()
          ComradeCraftDB.ui = ComradeCraftDB.ui or {}
          ComradeCraftDB.ui.sel = "requests"
          if not (ComradeCraftFrame and ComradeCraftFrame:IsShown()) then ns.ToggleWindow() else ns.RefreshWindow() end
        end } } })
    end
  elseif clean.updated > (mine.updated or 0) and OtherPeer(mine) == id
    -- Each side may only make its own moves: the requester cancels, the crafter answers.
    and ((Requests.Role(mine) == "crafter" and clean.status == "cancelled")
      or (Requests.Role(mine) == "requester" and BY_CRAFTER[clean.status])) then
    local before = mine.status
    mine.status, mine.updated, mine.note = clean.status, clean.updated, clean.note or mine.note
    mine.acked = mine.updated
    if before ~= mine.status and ns.Alerts and ns.Alerts.On("requests") then
      ns.Alerts.Notify({ title = L["Request %dx %s: %s."]:format(mine.qty, ns.SpellName(mine.spell), L[mine.status]),
        item = mine.item ~= 0 and mine.item or nil })
    end
  end
  Ack()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

function Requests.OnAck(id, rid, u)
  local r = type(rid) == "string" and DB()[rid]
  if r and OtherPeer(r) == id and r.updated == u then r.acked = u end
end

-- New request from one of our characters to a group member's character (key from AllChars).
function Requests.Create(to, spell, qty, note)
  local target = ns.AllChars()[to]
  if not (target and target.peer and ns.Recipes[spell]) then return nil end
  local now = Now()
  local r = { id = ("%s-%d-%d"):format(ComradeCraftDB.accountId or "x", now, math.random(1000, 9999)),
    from = ns.CharKey(), to = to, toPeer = target.peer, spell = spell, item = ns.Recipes[spell][5],
    qty = math.max(1, math.min(1000, math.floor(qty or 1))), note = note ~= "" and note or nil,
    status = "pending", created = now, updated = now }
  DB()[r.id] = r
  Send(r)
  ns.Log(("request: %s -> %s spell %d x%d"):format(r.from, r.to, spell, r.qty))
  ns.Print(L["Request sent to %s. It is delivered as soon as you are both online."]:format(to:match("^[^-]+") or to))
  if ns.RefreshWindow then ns.RefreshWindow() end
  return r
end

-- Status change by this side (crafter: accepted/declined/done; requester: cancelled).
function Requests.Set(rid, status)
  local r = DB()[rid]
  if not (r and STATUS[status]) then return end
  r.status, r.updated = status, Now()
  Send(r)
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- Forgets a finished request on this side only.
function Requests.Remove(rid)
  DB()[rid] = nil
  if ns.RefreshWindow then ns.RefreshWindow() end
end

-- Sorted lists for the window: incoming (for our characters) and outgoing.
function Requests.Lists()
  local inc, out = {}, {}
  for _, r in pairs(DB()) do
    table.insert(Requests.Role(r) == "crafter" and inc or out, r)
  end
  local order = { pending = 1, accepted = 2, done = 3, declined = 4, cancelled = 5 }
  local function less(a, b)
    if order[a.status] ~= order[b.status] then return order[a.status] < order[b.status] end
    return (a.updated or 0) > (b.updated or 0)
  end
  table.sort(inc, less)
  table.sort(out, less)
  return inc, out
end

-- Open requests waiting for an answer from us (sidebar badge).
function Requests.OpenCount()
  local n = 0
  for _, r in pairs(DB()) do
    if Requests.Role(r) == "crafter" and (r.status == "pending" or r.status == "accepted") then n = n + 1 end
  end
  return n
end

ns.On("PLAYER_LOGIN", function()
  if not ComradeCraftDB then return end
  local cutoff = Now() - KEEP_DAYS * 86400
  for rid, r in pairs(DB()) do
    local finished = r.status == "done" or r.status == "declined" or r.status == "cancelled"
    if finished and (r.updated or 0) < cutoff then DB()[rid] = nil end
  end
end)

-- Requests by mail (opt-in, off by default): for players who are never online together.
-- The requester writes a mail whose subject carries the request; the crafter's addon reads
-- its inbox headers and adds it. Answers still travel by the sync.
function Requests.MailOn() return ComradeCraftDB.settings and ComradeCraftDB.settings.mailRequests == true end

-- Pure: subject "[CC:<spell>:<qty>:<rid>] <name>" (64 chars max) and its parser.
function Requests.MailSubject(r)
  return (("[CC:%d:%d:%s] %s"):format(r.spell, r.qty, r.id, ns.SpellName(r.spell))):sub(1, 64)
end
function Requests.ParseSubject(subject)
  local spell, qty, rid = (subject or ""):match("^%[CC:(%d+):(%d+):([%w%-]+)%]")
  if not spell then return nil end
  return tonumber(spell), tonumber(qty), rid
end

-- Group member's character key for a mail sender name, and its account id.
local function SenderKey(sender)
  local short = (sender or ""):match("^[^-]+")
  if not short then return nil end
  for key, c in pairs(ns.AllChars()) do
    if c.peer and (key:match("^[^-]+") or key) == short then return key, c.peer end
  end
end

-- Inbox headers -> new incoming requests for the character reading the mail.
function Requests.ScanInbox()
  if not (Requests.MailOn() and GetInboxNumItems and GetInboxHeaderInfo) then return end
  local db, added = DB(), 0
  for i = 1, GetInboxNumItems() do
    local _, _, sender, subject = GetInboxHeaderInfo(i)
    local spell, qty, rid = Requests.ParseSubject(subject)
    local from, peer = SenderKey(sender)
    local p = peer and ComradeCraftDB.peers and ComradeCraftDB.peers[peer]
    if spell and ns.Recipes[spell] and from and p and p.included and not db[rid] then
      local now = Now()
      db[rid] = { id = rid, from = from, to = ns.CharKey(), fromPeer = peer, spell = spell,
        item = ns.Recipes[spell][5], qty = math.max(1, math.min(1000, qty)), status = "pending",
        created = now, updated = 0, acked = 0, byMail = true }
      added = added + 1
      ns.Print(L["%s asks %s to craft %dx %s."]:format(from:match("^[^-]+") or from,
        ns.CharKey():match("^[^-]+"), qty, ns.SpellName(spell)) .. " " .. L["(by mail)"])
    end
  end
  if added > 0 then
    ns.Log(("requests: %d from the inbox"):format(added))
    if ns.RefreshWindow then ns.RefreshWindow() end
  end
end
ns.On("MAIL_INBOX_UPDATE", function() Requests.ScanInbox() end)

-- Request dialog: quantity + note, from a recipe of a group member's character ------------

local dialog
local function CreateDialog()
  dialog = CreateFrame("Frame", "ComradeCraftRequestDialog", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  dialog:SetSize(360, 150)
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
  dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  dialog.title:SetPoint("TOPLEFT", 14, -14)
  dialog.title:SetWidth(332)
  dialog.title:SetJustifyH("LEFT")
  local function Labeled(y, text, w)
    local fs = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", 14, y)
    fs:SetText(text)
    local eb = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    eb:SetSize(w, 20)
    eb:SetPoint("TOPLEFT", 110, y + 4)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", function() dialog:Hide() end)
    return eb
  end
  dialog.qty = Labeled(-46, L["Quantity"], 50)
  dialog.qty:SetNumeric(true)
  dialog.note = Labeled(-74, L["Note (optional)"], 230)
  dialog.note:SetMaxLetters(120)
  dialog.send = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
  dialog.send:SetSize(110, 22)
  dialog.send:SetPoint("BOTTOMRIGHT", -12, 12)
  dialog.send:SetText(L["Send request"])
  dialog.send:SetScript("OnClick", function()
    Requests.Create(dialog.to, dialog.spell, tonumber(dialog.qty:GetText()) or 1, dialog.note:GetText() or "")
    dialog:Hide()
  end)
  dialog.cancel = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
  dialog.cancel:SetSize(90, 22)
  dialog.cancel:SetPoint("RIGHT", dialog.send, "LEFT", -6, 0)
  dialog.cancel:SetText(CANCEL or "Cancel")
  dialog.cancel:SetScript("OnClick", function() dialog:Hide() end)
  if UISpecialFrames then tinsert(UISpecialFrames, "ComradeCraftRequestDialog") end
end

function Requests.ShowDialog(to, spell)
  if not dialog then CreateDialog() end
  dialog.to, dialog.spell = to, spell
  dialog.title:SetText(L["Ask %s to craft %s"]:format(to:match("^[^-]+") or to, ns.SpellName(spell)))
  dialog.qty:SetText("1")
  dialog.note:SetText("")
  dialog:Show()
  dialog.qty:SetFocus()
end
