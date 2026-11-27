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
local STATUS = { pending = true, accepted = true, crafting = true, shipped = true, declined = true, done = true, cancelled = true }
local BY_CRAFTER = { accepted = true, crafting = true, shipped = true, declined = true, done = true }

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
  return { rid = r.id, from = r.from, to = r.to, spell = r.spell, item = r.spell == 0 and r.item or nil,
    qty = r.qty, sentQty = r.sentQty, deliverTo = r.deliverTo,
    chainId = r.chainId, chainStep = r.chainStep, chainTotal = r.chainTotal, blockedBy = r.blockedBy,
    note = r.note, status = r.status, u = r.updated, c = r.created }
end

-- Where the crafter delivers the finished item (next crafter in a chain, else original requester).
function Requests.Recipient(r)
  return (r and r.deliverTo) or (r and r.from) or nil
end

-- True when this request is part of a craft chain waiting on an earlier step to be shipped/done.
function Requests.IsBlocked(r)
  if not (r and r.blockedBy) then return false end
  local prev = DB()[r.blockedBy]
  if not prev then return false end
  return prev.status ~= "shipped" and prev.status ~= "done"
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
-- Supports both craft requests (spell > 0 in ns.Recipes) and shared bank item requests (spell == 0, item > 0).
function Requests.Clean(q)
  if type(q) ~= "table" then return nil end
  -- No control characters and no "|" (color, texture and link codes) in text shown to the player.
  local function S(v, n) return type(v) == "string" and #v > 0 and #v <= n and not v:find("[%c|]") and v or nil end
  local function N(v, lo, hi) return type(v) == "number" and v >= lo and v <= hi and math.floor(v) or nil end
  local spell = N(q.spell, 0, 2 ^ 31)
  local item = spell == 0 and N(q.item, 1, 2 ^ 31) or (spell and ns.Recipes[spell] and ns.Recipes[spell][5])
  local out = { id = S(q.rid, 48), from = S(q.from, 80), to = S(q.to, 80), spell = spell,
    item = item, qty = N(q.qty, 1, 1000), sentQty = N(q.sentQty, 0, 10000),
    deliverTo = S(q.deliverTo, 80), chainId = S(q.chainId, 48),
    chainStep = N(q.chainStep, 1, 10), chainTotal = N(q.chainTotal, 1, 10),
    blockedBy = S(q.blockedBy, 48),
    note = S(q.note, 120), status = STATUS[q.status] and q.status or nil,
    updated = N(q.u, 0, 2 ^ 31), created = N(q.c, 0, 2 ^ 31) }
  local validTarget = (spell and spell > 0 and ns.Recipes[spell]) or (spell == 0 and item and item > 0)
  if not (out.id and out.from and out.to and validTarget and out.qty and out.status and out.updated) then
    return nil
  end
  return out
end

-- Display label for a request (item name for shared bank item requests, else spell name).
function Requests.Label(r)
  if r and r.spell == 0 and r.item and r.item > 0 then
    return ns.ItemName and ns.ItemName(r.item) or ("item:" .. r.item)
  end
  return r and r.spell and ns.SpellName and ns.SpellName(r.spell) or "?"
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
      if ns.PlaySound then ns.PlaySound("request") end
      local msgFmt = clean.spell == 0 and L["%s asks %s for %dx %s."] or L["%s asks %s to craft %dx %s."]
      ns.Alerts.Notify({ title = L["New craft request"],
        text = msgFmt:format(clean.from:match("^[^-]+") or clean.from,
          clean.to:match("^[^-]+") or clean.to, clean.qty, Requests.Label(clean)),
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
    if clean.sentQty then mine.sentQty = clean.sentQty end
    mine.acked = mine.updated
    if before ~= mine.status and ns.Alerts and ns.Alerts.On("requests") then
      ns.Alerts.Notify({ title = L["Request %dx %s: %s."]:format(mine.qty, Requests.Label(mine), L[mine.status]),
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
-- `meta` (optional): { deliverTo, chainId, chainStep, chainTotal, blockedBy }.
function Requests.Create(to, spell, qty, note, meta)
  local target = ns.AllChars()[to]
  if not (target and target.peer and ns.Recipes[spell]) then return nil end
  local now = Now()
  local r = { id = ("%s-%d-%d"):format(ComradeCraftDB.accountId or "x", now, math.random(1000, 9999)),
    from = ns.CharKey(), to = to, toPeer = target.peer, spell = spell, item = ns.Recipes[spell][5],
    qty = math.max(1, math.min(1000, math.floor(qty or 1))), note = note ~= "" and note or nil,
    deliverTo = meta and meta.deliverTo or nil, chainId = meta and meta.chainId or nil,
    chainStep = meta and meta.chainStep or nil, chainTotal = meta and meta.chainTotal or nil,
    blockedBy = meta and meta.blockedBy or nil,
    status = "pending", created = now, updated = now }
  DB()[r.id] = r
  Send(r)
  ns.Log(("request: %s -> %s spell %d x%d"):format(r.from, r.to, spell, r.qty))
  ns.Print(L["Request sent to %s. It is delivered as soon as you are both online."]:format(to:match("^[^-]+") or to))
  if ns.RefreshWindow then ns.RefreshWindow() end
  return r
end

-- New item request from a group member's Shared bank alt (spell = 0, item = itemID).
function Requests.CreateItem(to, itemID, qty, note)
  local target = ns.AllChars()[to]
  if not (target and target.peer and itemID and itemID > 0) then return nil end
  local now = Now()
  local r = { id = ("%s-%d-%d"):format(ComradeCraftDB.accountId or "x", now, math.random(1000, 9999)),
    from = ns.CharKey(), to = to, toPeer = target.peer, spell = 0, item = itemID,
    qty = math.max(1, math.min(1000, math.floor(qty or 1))), note = note ~= "" and note or nil,
    status = "pending", created = now, updated = now }
  DB()[r.id] = r
  Send(r)
  ns.Log(("bank request: %s -> %s item %d x%d"):format(r.from, r.to, itemID, r.qty))
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
  local order = { pending = 1, accepted = 2, crafting = 3, shipped = 4, done = 5, declined = 6, cancelled = 7 }
  local function less(a, b)
    if order[a.status] ~= order[b.status] then return order[a.status] < order[b.status] end
    return (a.updated or 0) > (b.updated or 0)
  end
  table.sort(inc, less)
  table.sort(out, less)
  return inc, out
end

-- Open requests waiting for action from us (sidebar badge & glow).
function Requests.OpenCount()
  local n = 0
  for _, r in pairs(DB()) do
    if Requests.Role(r) == "crafter" and (r.status == "pending" or r.status == "accepted" or r.status == "crafting") then
      n = n + 1
    end
  end
  return n
end

-- Live material / stock progress for a request, visible to BOTH crafter and requester.
-- Returns { state = "ship"|"craft"|"missing", text = string, color = hex } or nil.
function Requests.Progress(r)
  if not r or r.status == "done" or r.status == "shipped" or r.status == "declined" or r.status == "cancelled" then
    return nil
  end
  local c = ns.AllChars and ns.AllChars()[r.to]
  if not c then return nil end
  local stock = {}
  for id, n in pairs(c.bags or {}) do stock[id] = (stock[id] or 0) + n end
  for id, n in pairs(c.bank or {}) do stock[id] = (stock[id] or 0) + n end
  local mult = (r.spell and r.spell > 0 and ns.Recipes[r.spell] and ns.Recipes[r.spell][6]) or 1
  local needOut = (r.qty or 1) * math.max(1, mult)
  if r.item and r.item > 0 and (stock[r.item] or 0) >= needOut then
    return { state = "ship", text = L["Ready to ship"], color = "40ff40" }
  end
  if r.spell == 0 then
    local miss = math.max(0, needOut - (stock[r.item] or 0))
    return { state = "missing", text = L["Missing %d"]:format(miss), color = "ffd100" }
  end
  if ns.Audit and ns.Audit.MatsStatus then
    local ms = ns.Audit.MatsStatus(r.spell, r.qty or 1, stock)
    if ms then
      if ms.ready then return { state = "craft", text = L["Ready to craft"], color = "80ff80" } end
      local parts = {}
      for _, m in ipairs(ms.mats or {}) do
        if m.missing > 0 and #parts < 2 then
          parts[#parts + 1] = ("%dx %s"):format(m.missing, ns.ItemName and ns.ItemName(m.item) or ("item:" .. m.item))
        end
      end
      if #parts > 0 then
        return { state = "missing", text = L["Missing %s"]:format(table.concat(parts, ", ")), color = "ffd100" }
      end
    end
  end
  return nil
end

-- Auto-tracks shipping: when we mail or trade an item matching an open incoming request for `toKey`,
-- accumulates sentQty and advances to "shipped" once the full requested quantity has been sent.
function Requests.OnItemSent(toKey, itemID, qty)
  if not (toKey and itemID and itemID > 0 and (qty or 0) > 0) then return 0 end
  local changed, rem = 0, qty
  for _, r in pairs(DB()) do
    local dest = Requests.Recipient(r)
    if rem > 0 and Requests.Role(r) == "crafter"
      and (r.status == "pending" or r.status == "accepted" or r.status == "crafting")
      and r.item == itemID
      and dest and (dest == toKey or (ns.IsSameChar and ns.IsSameChar(dest, toKey))) then
      local mult = (r.spell and r.spell > 0 and ns.Recipes[r.spell] and ns.Recipes[r.spell][6]) or 1
      local needOut = (r.qty or 1) * math.max(1, mult)
      local prevSent = r.sentQty or 0
      local take = math.min(rem, math.max(1, needOut - prevSent))
      r.sentQty = prevSent + take
      rem = rem - take
      r.updated = Now()
      if r.sentQty >= needOut then
        r.status = "shipped"
        if ns.PlaySound then ns.PlaySound("shipped") end
        ns.Print(L["Auto-marked request %dx %s as shipped."]:format(r.qty, Requests.Label(r)))
      else
        ns.Print(L["Sent %d/%d %s."]:format(r.sentQty, needOut, Requests.Label(r)))
      end
      Send(r)
      changed = changed + 1
    end
  end
  if changed > 0 and ns.RefreshWindow then ns.RefreshWindow() end
  return changed
end

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
  if unit ~= "player" or not spellID or not ComradeCraftDB then return end
  local me = ns.CharKey()
  local changed = false
  for _, r in pairs(DB()) do
    if Requests.Role(r) == "crafter" and r.to == me and r.status == "accepted" and r.spell == spellID then
      r.status, r.updated = "crafting", Now()
      Send(r)
      changed = true
    end
  end
  if changed and ns.RefreshWindow then ns.RefreshWindow() end
end)

ns.On("PLAYER_LOGIN", function()
  if not ComradeCraftDB then return end
  local cutoff = Now() - KEEP_DAYS * 86400
  for rid, r in pairs(DB()) do
    local finished = r.status == "done" or r.status == "shipped" or r.status == "declined" or r.status == "cancelled"
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

-- Pure: builds a multi-profession craft chain for `qty` of `spell` crafted by `targetKey`.
-- Walks reagents recursively (depth <= 3) and finds any missing intermediate crafted item
-- that another group member knows how to make (e.g. Arcanite Bar -> Enchanted Thorium -> Armor).
-- Returns ordered list of steps (sub-crafts first, final craft last):
--   { { to, spell, qty, item, isFinal } }.
function Requests.BuildChain(targetKey, spell, qty)
  local r = ns.Recipes and ns.Recipes[spell]
  if not (r and targetKey) then return {} end
  qty = math.max(1, math.floor(tonumber(qty) or 1))
  local chars = ns.AllChars and ns.AllChars() or {}
  -- Total stock across the whole group (bags + bank + mail) so we only chain what is actually missing.
  local stock = {}
  for _, c in pairs(chars) do
    for _, src in ipairs({ c.bags or {}, c.bank or {}, c.mail or {} }) do
      for id, n in pairs(src) do stock[id] = (stock[id] or 0) + n end
    end
  end
  -- Index who in the group can craft each product item (prefer ready cooldown, then targetKey, own, fav, peers).
  local now = Now()
  local producerOf = {}
  for ckey, c in pairs(chars) do
    local basePrio = ckey == targetKey and 0 or (not c.peer and 1 or (ns.IsFavorite and ns.IsFavorite(ckey) and 2 or 3))
    for _, set in pairs(c.known or {}) do
      for sp in pairs(set) do
        local sr = ns.Recipes[sp]
        local outItem = sr and sr[5]
        if outItem and outItem > 0 then
          local readyAt = c.cooldowns and c.cooldowns[sp] or 0
          local onCD = readyAt > now and 1 or 0
          local prev = producerOf[outItem]
          local better = not prev
            or (onCD < prev.onCD)
            or (onCD == prev.onCD and onCD == 1 and readyAt < prev.readyAt)
            or (onCD == prev.onCD and basePrio < prev.prio)
          if better then
            producerOf[outItem] = { key = ckey, spell = sp, yield = math.max(1, sr[6] or 1),
              prio = basePrio, onCD = onCD, readyAt = readyAt }
          end
        end
      end
    end
  end
  local steps, visited = {}, {}
  local function Walk(sp, cnt, ownerKey, depth)
    if depth >= 3 or visited[sp] then return end
    visited[sp] = true
    local rec = ns.Recipes[sp]
    local reag = rec and rec[7] or {}
    for i = 1, #reag, 2 do
      local item, need = reag[i], reag[i + 1] * cnt
      local have = stock[item] or 0
      if have >= need then
        stock[item] = have - need
      else
        local miss = need - have
        stock[item] = 0
        local prod = producerOf[item]
        if prod and prod.spell ~= sp and prod.key ~= ownerKey and not (ns.IsBoP and ns.IsBoP(item)) then
          local subQty = math.ceil(miss / prod.yield)
          Walk(prod.spell, subQty, prod.key, depth + 1)
          steps[#steps + 1] = { to = prod.key, deliverTo = ownerKey, spell = prod.spell,
            qty = subQty, item = item, isFinal = false }
        end
      end
    end
    visited[sp] = nil
  end
  Walk(spell, qty, targetKey, 0)
  steps[#steps + 1] = { to = targetKey, deliverTo = nil, spell = spell, qty = qty, item = r[5] or 0, isFinal = true }
  return steps
end

-- Dispatches every peer step of a multi-profession craft chain (linking chainId, blockedBy, deliverTo)
-- and pins own sub-crafts to Wishlist.
function Requests.SendChain(steps, note)
  if type(steps) ~= "table" or #steps == 0 then return 0 end
  local final = steps[#steps]
  local finalName = (final.item and final.item > 0 and ns.ItemName and ns.ItemName(final.item)) or ns.SpellName(final.spell)
  local chainId = ("ch-%s-%d-%d"):format(ComradeCraftDB.accountId or "x", Now(), math.random(100, 999))
  local sent, prevReqId = 0, nil
  local chars = ns.AllChars and ns.AllChars() or {}
  for idx, st in ipairs(steps) do
    local tag = ("[Chain %d/%d -> %s]"):format(idx, #steps, finalName)
    local fullNote = (type(note) == "string" and note ~= "") and (tag .. " " .. note) or tag
    local c = chars[st.to]
    if c and c.peer then
      local req = Requests.Create(st.to, st.spell, st.qty, fullNote, {
        deliverTo = st.deliverTo,
        chainId = chainId,
        chainStep = idx,
        chainTotal = #steps,
        blockedBy = prevReqId,
      })
      if req then
        prevReqId = req.id
        sent = sent + 1
      end
    elseif ns.Wishlist and ns.Wishlist.Add then
      local destShort = (st.deliverTo or final.to):match("^[^-]+") or (st.deliverTo or final.to)
      ns.Wishlist.Add(st.spell, st.qty, destShort, fullNote, true, st.to)
      sent = sent + 1
    end
  end
  if sent > 0 then
    ns.Print(L["Craft chain planned (%d steps for %s)."]:format(sent, finalName))
  end
  return sent
end

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
    local qty = tonumber(dialog.qty:GetText()) or 1
    local note = dialog.note:GetText() or ""
    if type(dialog.itemID) == "number" and dialog.itemID > 0 then
      Requests.CreateItem(dialog.to, dialog.itemID, qty, note)
    else
      Requests.Create(dialog.to, dialog.spell, qty, note)
    end
    dialog:Hide()
  end)
  dialog.cancel = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
  dialog.cancel:SetSize(84, 22)
  dialog.cancel:SetPoint("RIGHT", dialog.send, "LEFT", -6, 0)
  dialog.cancel:SetText(CANCEL or "Cancel")
  dialog.cancel:SetScript("OnClick", function() dialog:Hide() end)
  dialog.chain = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
  dialog.chain:SetSize(134, 22)
  dialog.chain:SetPoint("BOTTOMLEFT", 12, 12)
  dialog.chain:SetScript("OnClick", function()
    local qty = tonumber(dialog.qty:GetText()) or 1
    local note = dialog.note:GetText() or ""
    local steps = Requests.BuildChain(dialog.to, dialog.spell, qty)
    if #steps > 1 then Requests.SendChain(steps, note) end
    dialog:Hide()
  end)
  dialog.chain:SetScript("OnEnter", function(self)
    if not (dialog.to and dialog.spell and dialog.spell > 0) then return end
    local qty = tonumber(dialog.qty:GetText()) or 1
    local steps = Requests.BuildChain(dialog.to, dialog.spell, qty)
    if #steps <= 1 then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(L["Multi-profession craft chain"], 1, 0.82, 0)
    for i, st in ipairs(steps) do
      GameTooltip:AddDoubleLine(("%d. %dx %s"):format(i, st.qty, ns.SpellName(st.spell)),
        st.to:match("^[^-]+") or st.to, 1, 1, 1, 0.5, 0.8, 1)
    end
    GameTooltip:Show()
  end)
  dialog.chain:SetScript("OnLeave", function() GameTooltip:Hide() end)
  dialog.chain:Hide()
  if UISpecialFrames then tinsert(UISpecialFrames, "ComradeCraftRequestDialog") end
end

function Requests.ShowDialog(to, spell, defaultNote)
  if not dialog then CreateDialog() end
  dialog.to, dialog.spell, dialog.itemID = to, spell, nil
  dialog.title:SetText(L["Ask %s to craft %s"]:format(to:match("^[^-]+") or to, ns.SpellName(spell)))
  dialog.qty:SetText("1")
  dialog.note:SetText(defaultNote or "")
  local chain = Requests.BuildChain(to, spell, 1)
  if #chain > 1 then
    dialog.chain:SetText(L["Plan chain (%d)"]:format(#chain))
    dialog.chain:Show()
  else
    dialog.chain:Hide()
  end
  dialog:Show()
  dialog.qty:SetFocus()
end

function Requests.ShowItemDialog(to, itemID, defaultQty)
  if not dialog then CreateDialog() end
  dialog.to, dialog.spell, dialog.itemID = to, 0, itemID
  local name = ns.ItemName and ns.ItemName(itemID) or ("item:" .. tostring(itemID))
  dialog.title:SetText(L["Ask %s for %s"]:format(to:match("^[^-]+") or to, name))
  dialog.qty:SetText(tostring(math.max(1, math.floor(defaultQty or 1))))
  dialog.note:SetText("")
  dialog.chain:Hide()
  dialog:Show()
  dialog.qty:SetFocus()
end
