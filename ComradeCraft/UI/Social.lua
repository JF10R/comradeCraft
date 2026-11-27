-- UI/Social: Wishlist, Manage group, Help, first-open Tutorial, Craft requests, and Guild directory.
local _, ns = ...
local L = ns.L
local U = ns.UI
local LIST_W, SIDE_W, DETAIL_X = U.LIST_W, U.SIDE_W, U.DETAIL_X
local ItemInfo, Ago, SortedKeys, ShortName, LevelSpecClass =
  U.ItemInfo, U.Ago, U.SortedKeys, U.ShortName, U.LevelSpecClass
local SectionBar, Section, Label, Action, Check, Toggle =
  U.SectionBar, U.Section, U.Label, U.Action, U.Check, U.Toggle

-- Wishlist view: reusable Craft Kits, local + synced group pinned crafts, material progress, and quick actions.
function U.RenderWishlist()
  local Wl = ns.Wishlist
  local y = 0
  local list = Wl and Wl.List(nil, true) or {}
  local kits = Wl and Wl.Kits and Wl.Kits() or {}
  if #kits > 0 then
    y = y - SectionBar(0, y, LIST_W, "|cff80ccff" .. L["Craft kits"] .. "|r",
      L["Reusable craft bundles (raid, dungeon, reroll) — apply in 1 click."]) - 6
    for _, kit in ipairs(kits) do
      local kName = kit.name
      local summary = ("%s  |cff9d9d9d(%d)|r"):format("|cffffd100" .. kName .. "|r", #kit.entries)
      local _, kh = Label(8, y - 4, summary, "GameFontHighlightSmall", LIST_W - 252)
      local b1 = Action(LIST_W - 238, y, L["Apply x1"], function() Wl.ApplyKit(kName, 1) end)
      b1:SetWidth(76)
      local b5 = Action(LIST_W - 158, y, L["Apply x5"], function() Wl.ApplyKit(kName, 5) end)
      b5:SetWidth(76)
      local bDel = Action(LIST_W - 78, y, L["Remove"], function() Wl.DeleteKit(kName) end)
      bDel:SetWidth(74)
      y = y - math.max(24, kh + 6)
    end
    y = y - 8
  end
  if #list == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No craft pinned yet. Right-click any recipe in your Can craft tab to add it here, track its materials and get notified when ready."] .. "|r")
    y = y - h - 10
    local bGo = Action(0, y, L["Browse Can craft"], function()
      ComradeCraftDB.ui.sel = ns.CharKey()
      ComradeCraftDB.ui.tab = "craft"
      ns.RefreshWindow()
    end)
    bGo:SetWidth(150)
    return -y + 28
  end
  local me = ns.CharKey()
  local chars = ns.AllChars()
  if Wl and Wl.ShowSaveKitDialog then
    local bKit = Action(LIST_W - 236, y, L["Save as kit"], function() Wl.ShowSaveKitDialog() end)
    bKit:SetWidth(114)
  end
  local bShare = Action(LIST_W - 116, y, L["Share in chat"], function()
    local miss, order = {}, {}
    for _, e in ipairs(list) do
      local prog = Wl.Progress(e, chars[e.char])
      for _, m in ipairs(prog.mats or {}) do
        if m.missing > 0 then
          if not miss[m.item] then order[#order + 1] = m.item end
          miss[m.item] = (miss[m.item] or 0) + m.missing
        end
      end
    end
    local parts = {}
    for i = 1, math.min(5, #order) do
      local id = order[i]
      parts[#parts + 1] = ("%s x%d"):format((ItemInfo(id)) or ("item:" .. id), miss[id])
    end
    if #parts > 0 and ns.ShareChat then
      ns.ShareChat("[ComradeCraft] " .. L["Wishlist"] .. ": " .. table.concat(parts, ", "))
    end
  end)
  bShare:SetWidth(112)
  y = y - 26
  for _, e in ipairs(list) do
    local prog = Wl.Progress(e, chars[e.char])
    local label = e.item ~= 0 and (ItemInfo(e.item) or ("item:" .. e.item)) or ns.SpellName(e.spell)
    local who = e.forWho and ("  |cff80ccff" .. L["For %s"]:format(e.forWho) .. "|r") or ""
    local convTxt = ns.FormatConversionHints and ns.FormatConversionHints(prog.convHints)
    local status = prog.bagReady and (convTxt and ("  |cff66ccff" .. convTxt .. "|r") or ("  |cff40ff40" .. L["Ready to craft!"] .. "|r"))
      or (prog.ready and ("  |cffffd100" .. L["Ready (some mats in bank/mail)"] .. "|r") or "")
    local sub = e.remote and (L["via %s"]:format(ShortName(e.char)) .. (e.note and (" - " .. e.note) or ""))
      or (e.note or ShortName(e.char))
    y = y - SectionBar(0, y, LIST_W, ("|cffffd100%dx %s|r%s%s"):format(e.qty, label, who, status), sub) - 6
    local parts = {}
    for _, m in ipairs(prog.mats) do
      local col = m.missing == 0 and "40ff40" or "ffd100"
      parts[#parts + 1] = ("%s |cff%s%d/%d|r"):format((ItemInfo(m.item)) or ("item:" .. m.item), col, m.have, m.need)
    end
    if convTxt and not prog.bagReady then parts[#parts + 1] = "|cff66ccff" .. convTxt .. "|r" end
    local _, mh = Label(8, y - 2, table.concat(parts, "   "), "GameFontHighlightSmall",
      LIST_W - (e.remote and 20 or (e.char == me and 316 or 228)))
    if not e.remote then
      local id, spell, own = e.id, e.spell, e.char == me
      local bx = LIST_W - 86
      local bd = Action(bx, y, L["Remove"], function() Wl.Remove(id) end)
      bd:SetWidth(82)
      bx = bx - 126
      Check(bx, y + 2, e.pinned, function(on) Wl.SetPinned(id, on) end)
      Label(bx + 24, y - 4, L["Pin on screen"], "GameFontHighlightSmall", 98)
      if own then
        bx = bx - 88
        local bc = Action(bx, y, L["Craft"], function() ns.OpenRecipe(spell) end)
        bc:SetWidth(82)
      end
    end
    y = y - math.max(28, mh + 10) - 6
  end
  return -y
end


local function CharCount(peer)
  local n = 0
  for _ in pairs(peer.chars or {}) do n = n + 1 end
  return n
end

-- Your characters (share boxes), players in the group (remove), requests and suggestions
-- (add), add by name, options. Everything sync-related is done from here.
function U.RenderManage()
  local db = ComradeCraftDB
  local Sync = ns.Sync
  local y = 0

  y = Section(y, L["Your characters"], L["Only checked characters are shared, and only with the players in your group."])
  local _, lh = Label(0, y + 4, "|cff9d9d9d" .. L["Right box: list the character in the guild directory (professions and recipes only, sent to your guild)."] .. "|r")
  y = y - lh - 2
  local _, bh = Label(0, y + 4, "|cff80ccff" .. L["Shared bank alt: all items on this character (bags, bank, mail) appear as available to your group, and members can request them via the addon."] .. "|r")
  y = y - bh - 4
  local ownKeys = SortedKeys(db.chars)
  local nameCounts = {}
  for _, key in ipairs(ownKeys) do
    local s = ShortName(key)
    nameCounts[s] = (nameCounts[s] or 0) + 1
  end
  local meKey = ns.CharKey()
  local anyShared, anyUnshared = false, false
  for _, key in ipairs(ownKeys) do
    local c = db.chars[key]
    if c.shared then anyShared = true else anyUnshared = true end
    Check(0, y + 2, c.shared, function(on) Sync.SetShared(key, on) end)
    local realmTag = nameCounts[ShortName(key)] > 1 and (" |cff6f6f6f(" .. (key:match("-(.+)$") or "?") .. ")|r") or ""
    local canRemove = key ~= meKey
    Label(28, y - 4, ns.ClassColored(key, c.class) .. realmTag .. "  |cff9d9d9d" .. LevelSpecClass(c) .. "|r",
      "GameFontHighlight", LIST_W - (canRemove and 455 or 375))
    local bankX = canRemove and (LIST_W - 420) or (LIST_W - 340)
    Check(bankX, y + 2, c.bankAlt, function(on) Sync.SetBankAlt(key, on) end)
    Label(bankX + 26, y - 4, L["Shared bank alt"], nil, 118)
    local dirX = canRemove and (LIST_W - 270) or (LIST_W - 190)
    Check(dirX, y + 2, c.listed, function(on) ns.Directory.SetListed(key, on) end)
    Label(dirX + 26, y - 4, L["List in guild directory"], nil, 160)
    if canRemove then
      local delKey = key
      local delBtn = Action(LIST_W - 80, y, L["Remove"], function()
        db.chars[delKey] = nil
        if db.ui and db.ui.sel == delKey then db.ui.sel = meKey end
        Sync.AnnounceToGroup()
        ns.RefreshWindow()
      end)
      delBtn:SetWidth(76)
    end
    y = y - 28
  end
  if #ownKeys > 0 then
    local bAll = Action(0, y, L["Share all"], function() Sync.SetAllShared(true) end)
    bAll:SetWidth(104)
    bAll:SetEnabled(anyUnshared)
    local bNone = Action(110, y, L["Unshare all"], function() Sync.SetAllShared(false) end)
    bNone:SetWidth(104)
    bNone:SetEnabled(anyShared)
    db.settings = db.settings or {}
    Check(226, y + 1, db.settings.autoShareNew, function(on) db.settings.autoShareNew = on or nil end)
    local _, ah = Label(254, y - 4, L["Automatically share new characters on this account"], nil, LIST_W - 254)
    y = y - math.max(28, ah + 10)
  end

  local inGroup, others = {}, {}
  for id, peer in pairs(db.peers or {}) do
    if peer.name then
      table.insert(peer.included and inGroup or others, { id = id, peer = peer })
    end
  end
  local byName = function(a, b) return a.peer.name < b.peer.name end
  table.sort(inGroup, byName)
  table.sort(others, function(a, b)
    if (a.peer.asked and 1 or 0) ~= (b.peer.asked and 1 or 0) then return a.peer.asked and true or false end
    return a.peer.name < b.peer.name
  end)

  y = Section(y - 10, L["Players in your group"], L["They receive your shared characters and you see theirs."])
  if #inGroup == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody yet."] .. "|r")
    y = y - h - 8
  end
  for _, e in ipairs(inGroup) do
    Label(0, y - 4, "|cff80ff80" .. e.peer.name .. "|r  |cff9d9d9d" .. ns.Plural(CharCount(e.peer), "%d character", "%d characters")
      .. " - " .. L["seen %s"]:format(Ago(e.peer.seen)) .. "|r", "GameFontHighlight", LIST_W - 110)
    Action(LIST_W - 100, y, L["Remove"], function() Sync.Exclude(e.id) end)
    y = y - 28
  end
  if #inGroup > 0 then
    -- Updates go out by themselves (debounced); this sends right away.
    Action(0, y, L["Send now"], function() ns.commands.sync() end)
    y = y - 30
  end

  local pendingAdds = Sync.PendingAdds and Sync.PendingAdds() or {}
  y = Section(y - 10, L["Requests and suggestions"],
    L["Players with ComradeCraft in your guild, or who added you. Add them to share both ways."])
  if #others == 0 and #pendingAdds == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody yet."] .. "|r")
    y = y - h - 8
  end
  for _, e in ipairs(others) do
    local status = e.peer.asked and ("|cff80ff80" .. L["wants to join"] .. "|r") or ("|cff9d9d9d" .. L["suggested"] .. "|r")
    Label(0, y - 4, e.peer.name .. "  " .. status .. (CharCount(e.peer) > 0 and ("  |cff9d9d9d"
      .. ns.Plural(CharCount(e.peer), "%d character", "%d characters") .. "|r") or ""), "GameFontHighlight", LIST_W - 110)
    Action(LIST_W - 100, y, L["Add"], function() Sync.Include(e.id) end)
    y = y - 28
  end
  for _, p in ipairs(pendingAdds) do
    Label(0, y - 4, p.name .. "  |cffffd100" .. L["waiting for reply"] .. "|r  |cff9d9d9d(" .. Ago(p.t) .. ")|r",
      "GameFontHighlight", LIST_W - 210)
    Action(LIST_W - 200, y, L["Retry"], function() Sync.RetryAdd(p.key) end)
    Action(LIST_W - 100, y, L["Cancel"], function() Sync.CancelAdd(p.key) end)
    y = y - 28
  end

  y = Section(y - 10, L["Add a player by name"], L["For friends outside your guild. They must add you back."])
  U.frame.addBox:ClearAllPoints()
  U.frame.addBox:SetPoint("TOPLEFT", U.content, "TOPLEFT", 6, y)
  U.frame.addBox:Show()
  Action(200, y + 1, L["Add"], function()
    local name = U.frame.addBox:GetText()
    if name and name ~= "" then
      Sync.AddByName(name)
      U.frame.addBox:SetText("")
    end
  end)
  local targetName = Sync.TargetPlayerName and Sync.TargetPlayerName() or nil
  local tBtn = Action(304, y + 1, targetName and L["Add %s"]:format(targetName) or L["Add target"], function()
    if targetName then Sync.AddByName(targetName) end
  end)
  tBtn:SetWidth(140)
  tBtn:SetEnabled(targetName ~= nil)
  y = y - 34

  local quick = Sync.QuickAddCandidates and Sync.QuickAddCandidates() or {}
  if #quick > 0 then
    local _, qh = Label(0, y, "|cff9d9d9d" .. L["Online in your party, friends or guild:"] .. "|r")
    y = y - qh - 6
    local srcLabel = { party = L["Party"], friend = L["Friend"], guild = L["Guild"] }
    for i = 1, math.min(#quick, 6) do
      local q = quick[i]
      Label(0, y - 4, ns.ClassColored(q.name, q.class) .. "  |cff9d9d9d" .. (srcLabel[q.source] or "") .. "|r",
        "GameFontHighlight", LIST_W - 110)
      Action(LIST_W - 100, y, L["Add"], function() Sync.AddByName(q.name) end)
      y = y - 26
    end
    y = y - 4
  end

  y = Section(y - 6, L["Options"])
  db.settings = db.settings or {}
  Check(0, y + 2, db.settings.guildPing ~= false, function(on)
    db.settings.guildPing = on
  end)
  local _, h = Label(30, y - 4, L["Send a presence signal to the guild at login (no character data)."], nil, LIST_W - 30)
  y = y - math.max(28, h + 10)
  Check(0, y + 2, ns.Requests.MailOn(), function(on) db.settings.mailRequests = on or nil ns.RefreshWindow() end)
  _, h = Label(30, y - 4, L["Craft requests by mail too: for players who are never online at the same time (you send the mail yourself, 30c postage)."], nil, LIST_W - 30)
  y = y - math.max(28, h + 10)
  Check(0, y + 2, ns.TrackerOn(), function(on) ns.SetTracker(on) end)
  _, h = Label(30, y - 4, L["Show the step panel next to the profession window."], nil, LIST_W - 140)
  Action(LIST_W - 100, y, L["Re-dock"], function() ns.SetTracker(nil, true) end)
  y = y - math.max(28, h + 10)
  Check(0, y + 2, ns.FarmTrackerOn(), function(on) ns.SetFarmTracker(on) end)
  _, h = Label(30, y - 4, L["Show the farming tracker (your farming assignments from the Group plan)."], nil, LIST_W - 30)
  y = y - math.max(28, h + 10)
  if ns.Bags then
    Check(0, y + 2, ns.Bags.On(), function(on) ns.Bags.Set(on) end)
    _, h = Label(30, y - 4, L["Highlight items for your group in your bags (and focus a recipient's items when mailing)."], nil, LIST_W - 30)
    y = y - math.max(28, h + 10)
  end
  if ns.Wishlist then
    Check(0, y + 2, ns.Wishlist.TrackerOn(), function(on) ns.Wishlist.SetTracker(on) end)
    _, h = Label(30, y - 4, L["Show the wishlist tracker on screen (pinned crafts)."], nil, LIST_W - 30)
    y = y - math.max(28, h + 10)
  end

  -- Group plan objective: what "cheapest" means for every plan.
  local _, gh = Label(0, y - 2, "|cffffd100" .. L["Group plan"] .. "|r", "GameFontNormal")
  y = y - gh - 8
  local objective = ns.GroupObjective()
  for _, o in ipairs({ { "group", L["Lowest group cost"], L["Least gold spent by the group: stock already held in the group counts as free."] },
    { "solo", L["Market value"], L["Every material at its market value, as if each character were alone."] } }) do
    local v = o[1]
    Toggle(0, y, o[2], objective == v, true, function() ns.SetGroupObjective(v) end):SetWidth(150)
    local _, oh = Label(160, y - 5, "|cff9d9d9d" .. o[3] .. "|r", nil, LIST_W - 160)
    y = y - math.max(28, oh + 12)
  end

  y = Section(y - 6, L["Alerts"], L["A chat line and a short notice at the top of the screen."])
  for _, a in ipairs({ { "mats", L["Your bags hold the mats for your next craft."] },
    { "cooldown", L["A profession cooldown is ready on one of your characters."] },
    { "requests", L["A craft request arrives or changes."] },
    { "keep", L["At a merchant or the auction house: items in your bags that your group needs."] },
    { "upgrade", L["A group member can craft an upgrade for you (off by default)."] } }) do
    Check(0, y + 2, ns.Alerts.On(a[1]), function(on) ns.Alerts.Set(a[1], on) end)
    local _, ah = Label(30, y - 4, a[2], nil, LIST_W - 30)
    y = y - math.max(26, ah + 10)
  end

  y = Section(y - 6, L["Measured skill-up chances"],
    L["Crafts logged by you and your group automatically calibrate skill-up chances for WoW Forever."])
  for _, l in ipairs(ns.SkillupStatsLines()) do
    local _, lh = Label(0, y, (l:gsub("^%s+", "")))
    y = y - lh - 2
  end
  if ns.ForeverDB and ns.ForeverDB.Stats then
    local nb, nv, nd, np, ncr, nde = ns.ForeverDB.Stats()
    y = Section(y - 10, L["Forever P2P database"],
      L["Observed WoW Forever recipe bounds, custom recipes, disenchants, vendors and drops shared automatically."])
    local statTxt = L["%d bounds  |  %d custom recipes  |  %d disenchants  |  %d vendors  |  %d drops  (%d peers)"]
      :format(nb, ncr or 0, nde or 0, nv, nd, np)
    local _, fh = Label(0, y - 4, statTxt, "GameFontHighlightSmall", LIST_W - 120)
    local bSyncFdb = Action(LIST_W - 112, y, L["Share now"], function()
      if ns.ForeverDB.BroadcastGuild then ns.ForeverDB.BroadcastGuild() end
      for id, p in pairs(ComradeCraftDB.peers or {}) do
        if p.included and p.name then ns.ForeverDB.SendToPeer(id, p.name) end
      end
      ns.Print(L["sync: sent to the players in your group"])
    end)
    bSyncFdb:SetWidth(108)
    y = y - math.max(26, fh + 8)
  end
  return -y
end

-- Help view ("?" button): one short paragraph per feature, plus a button to replay the tour.
local HELP = {
  { L["The window"], L["Left: the group, then each character. Plan = how to level a profession; Can craft = what that character can make for the group. The chips filter by profession."] },
  { L["Plans"], L["Each step says what to learn at the trainer, what to craft first (bolts, bars...) and how many. Click a line to open the recipe, Shift+click to link it. Colors: orange always gives a point, yellow usually, green rarely, grey never."] },
  { L["Routes"], L["Each character picks Cheapest (least spent on mats) or Profitable (products sold back). The milestone table compares both: mats, what the products bring back (merchant, disenchant or AH) and the net cost."] },
  { L["Learning recipes"], L["Hover a Learn line for its trainers, vendors and drops; click it for a TomTom waypoint (with Questie installed for positions)."] },
  { L["Craft queue"], L["In the step panel: the crafts of this step or of the whole milestone, what your bags allow, and Craft next (one batch per click, the game needs a click per craft)."] },
  { L["Group plan"], L["Plans count stock already held in the group as free (or every mat at market value: Manage group > Options). The Group plan view lists what the group still needs and its cost; take a material with I'll farm it and a small tracker follows your progress."] },
  { L["Craft requests"], L["Click a recipe in a group member's Can craft tab to ask for it. Answer what you are asked in Craft requests. Requests reach the other player the next time you are both online (or by mail, if turned on in Manage group)."] },
  { L["Tooltips"], L["On any material: who in the group needs it, how many, and how soon (now, soon, later). Spare stock in the group is shown too."] },
  { L["Step panel"], L["Next to your profession window: the current step, the chance per craft, how many crafts your bags allow, and what comes next."] },
  { L["Giving and mail"], L["You can give lists what you hold that others need. At a mailbox, the button beside the send frame attaches it. Nothing is ever sent for you."] },
  { L["Disenchant or keep"], L["Your green items: keep one per slot your enchanting plan needs, keep upgrades for group members, sell what is worth more than its mats, disenchant the rest."] },
  { L["Shopping"], L["The Shopping list button makes an Auctionator list, or a TSM search and group to paste. TSM groups that are done are pointed out."] },
  { L["Sharing"], L["Nothing is shared until you check a character in Manage group, and only with players you added who added you back."] },
  { L["Guild directory"], L["Opt-in, per character: List in guild directory in Manage group (or /comrade list) sends its professions and recipes to guildmates who use ComradeCraft. Search who can craft an item, whisper them, or ask for the craft if they are in your group. Item tooltips name up to 3 guild crafters."] },
  { L["Next rank"], L["At the skill cap: the Expert book (vendor or AH), the Artisan quest found in Questie (click for a waypoint to its giver), or the trainer."] },
  { L["Alerts"], L["Mats ready, profession cooldowns ready on any of your characters, craft requests, items your group needs when you open a merchant or the AH (with Buy back after a sale), and opt-in upgrades. Each one can be turned off in Manage group."] },
  { L["Better with"], L["TSM or Auctionator (prices), Questie (positions), TomTom (waypoints), Pawn (upgrades for each class and spec). All optional."] },
  { L["Shared bank alt"], L["Shared bank alt: all items on this character (bags, bank, mail) appear as available to your group, and members can request them via the addon."] },
  { L["Item reservations"], L["Alt+Right-click any bag item to reserve/lock it for a friend before mailing."] },
}

function U.RenderHelp()
  local y = 0
  for _, h in ipairs(HELP) do
    local _, th = Label(0, y, "|cffffd100" .. h[1] .. "|r", "GameFontNormal")
    y = y - th - 2
    local _, bh = Label(0, y, h[2])
    y = y - bh - 10
  end
  Action(0, y, L["Replay the tour"], function() ns.StartTutorial(true) end)
  return -y + 30
end

-- First-open tour: a few cards over the window. Skip = not again this session;
-- "Do not show again" (or finishing it) = never again.
local TOUR = {
  { L["Welcome to ComradeCraft"], L["It answers one question: what should I do with what I have, for the group? 30 seconds to see the main parts."],
    { "CENTER", 0, 40 } },
  { L["Your group"], L["Left: Group overview, Materials, Craftable BiS Upgrades, Wishlist, Requests, and every character in your group."],
    { "TOPLEFT", SIDE_W + 10, -80 }, "group" },
  { L["Plan and Can craft"], L["Pick a character: Plan shows how to level each profession step by step; Can craft shows what it can make for others."],
    { "TOPLEFT", DETAIL_X + 260, -100 }, "self" },
  { L["While you play"], L["Bags highlight items your group needs; helper panels dock at Mail, Bank, Trade, Merchant, AH, and Trainers."],
    { "CENTER", 0, 0 } },
  { L["Sharing is off until you check a box"], L["Nothing is shared yet. Here, in Manage group, check characters to share (or flag a Shared bank alt), then add friends below. Mutually added peers relay updates automatically."],
    { "TOPLEFT", DETAIL_X + 330, -150 }, "manage" },
}
local tourSkipped, tourCard = false, nil

local function TutorialCard()
  if tourCard then return tourCard end
  local t = CreateFrame("Frame", "ComradeCraftTour", U.frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
  t:SetSize(340, 150)
  t:SetFrameStrata("DIALOG")
  t:SetToplevel(true)
  -- Opaque: the dialog background texture is see-through on its own.
  local solid = t:CreateTexture(nil, "BACKGROUND", nil, -8)
  solid:SetPoint("TOPLEFT", 4, -4)
  solid:SetPoint("BOTTOMRIGHT", -4, 4)
  solid:SetColorTexture(0.06, 0.05, 0.04, 0.97)

  if t.SetBackdrop then
    t:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    t:SetBackdropBorderColor(1, 0.82, 0, 1)
  end
  t:EnableMouse(true)
  t.title = t:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  t.title:SetPoint("TOPLEFT", 14, -12)
  t.count = t:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  t.count:SetPoint("TOPRIGHT", -14, -14)
  t.text = t:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  t.text:SetPoint("TOPLEFT", 14, -36)
  t.text:SetWidth(312)
  t.text:SetJustifyH("LEFT")
  t.never = CreateFrame("CheckButton", nil, t, "UICheckButtonTemplate")
  t.never:SetSize(22, 22)
  t.never:SetPoint("BOTTOMLEFT", 10, 8)
  t.never.label = t.never:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  t.never.label:SetPoint("LEFT", t.never, "RIGHT", 2, 0)
  t.never.label:SetText(L["Do not show again"])
  t.next = CreateFrame("Button", nil, t, "UIPanelButtonTemplate")
  t.next:SetSize(80, 22)
  t.next:SetPoint("BOTTOMRIGHT", -10, 10)
  t.skip = CreateFrame("Button", nil, t, "UIPanelButtonTemplate")
  t.skip:SetSize(80, 22)
  t.skip:SetPoint("RIGHT", t.next, "LEFT", -6, 0)
  t.skip:SetText(L["Skip"])
  local function Close(finished)
    if finished or t.never:GetChecked() == true then ComradeCraftDB.settings.tutorialDone = true end
    tourSkipped = true
    t:Hide()
  end
  t.skip:SetScript("OnClick", function() Close(false) end)
  t.next:SetScript("OnClick", function()
    if t.step >= #TOUR then Close(true) else ns.ShowTutorialStep(t.step + 1) end
  end)
  tourCard = t
  return t
end

function ns.ShowTutorialStep(i)
  local t = TutorialCard()
  local s = TOUR[i]
  t.step = i
  t.title:SetText(s[1])
  t.text:SetText(s[2])
  t.count:SetText(("%d/%d"):format(i, #TOUR))
  t.next:SetText(i == #TOUR and L["Done"] or L["Next"])
  -- Each step opens the view it talks about.
  if s[4] then
    ComradeCraftDB.ui.sel = s[4] == "self" and ns.CharKey() or s[4]
    ComradeCraftDB.ui.tab = "plan"
    ns.RefreshWindow()
  end
  t:SetHeight(i == #TOUR and 200 or 150)
  t:ClearAllPoints()
  t:SetPoint(s[3][1], U.frame, s[3][1], s[3][2], s[3][3])
  t:Show()
end

-- Shown on the first opening (unless done, or skipped this session); `force` from Help.
function ns.StartTutorial(force)
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  if not force and (ComradeCraftDB.settings.tutorialDone or tourSkipped) then return end
  if not (U.frame and U.frame:IsShown()) then return end
  ns.ShowTutorialStep(1)
end

-- Craft requests view: for your characters (answer them), then yours (follow them).
local STATUS_COLOR = { pending = "ffd100", accepted = "40c0ff", crafting = "66ccff", shipped = "c080ff",
  done = "40ff40", declined = "ff6040", cancelled = "9d9d9d" }

local function RequestRow(y, r, incoming)
  local R = ns.Requests
  local who = incoming and L["%s for %s"]:format(ShortName(r.from), ShortName(r.to))
    or L["asked to %s"]:format(ShortName(r.to))
  local title = R.Label and R.Label(r) or ns.SpellName(r.spell)
  local prog = R.Progress and R.Progress(r)
  local progTag = prog and ("  |cff%s[%s]|r"):format(prog.color, prog.text) or ""
  local chainTag = (r.chainStep and r.chainTotal) and ("  |cff80ccff[" .. L["Step %d/%d"]:format(r.chainStep, r.chainTotal) .. "]|r") or ""
  local blockedTag = (R.IsBlocked and R.IsBlocked(r)) and ("  |cffff9933[" .. L["Waiting previous step"] .. "]|r") or ""
  local line1 = ("|cffffffff%dx %s|r  |cff9d9d9d%s|r  |cff%s%s|r%s%s%s"):format(r.qty, title, who,
    STATUS_COLOR[r.status] or "ffffff", L[r.status], progTag, chainTag, blockedTag)
  local details = {}
  if r.deliverTo and r.deliverTo ~= r.from then
    details[#details + 1] = "|cff80ccff" .. L["Deliver to %s"]:format(ShortName(r.deliverTo)) .. "|r"
  end
  if (r.sentQty or 0) > 0 and r.status ~= "shipped" and r.status ~= "done" then
    local mult = (r.spell and r.spell > 0 and ns.Recipes[r.spell] and ns.Recipes[r.spell][6]) or 1
    details[#details + 1] = L["Sent %d/%d"]:format(r.sentQty, (r.qty or 1) * math.max(1, mult))
  end
  if r.note then details[#details + 1] = "\"" .. r.note .. "\"" end
  if r.acked ~= r.updated then details[#details + 1] = L["waiting to reach the other player"] end
  if incoming and (r.status == "pending" or r.status == "accepted" or r.status == "crafting") then
    if r.spell and r.spell > 0 then
      details[#details + 1] = L["Mats: %s"]:format(ns.ReagentText(r.spell, r.qty))
      if r.to == ns.CharKey() then
        details[#details + 1] = L["your bags allow %d"]:format(ns.CraftableNow(r.spell, ns.CharData().bags or {}))
      end
    elseif r.item and r.item > 0 and r.to == ns.CharKey() then
      local me = ns.CharData()
      local inBags = (me.bags or {})[r.item] or 0
      local inBank = (me.bank or {})[r.item] or 0
      details[#details + 1] = L["your bags allow %d"]:format(inBags)
        .. (inBank > 0 and (" (+" .. inBank .. " " .. L["in bank"] .. ")") or "")
    end
  end
  local buttons = {}
  if incoming then
    if r.status == "pending" then
      buttons = { { L["Accept"], "accepted" }, { L["Decline"], "declined" } }
    elseif r.status == "accepted" then
      if r.to == ns.CharKey() and r.spell and r.spell > 0 and ns.OpenRecipe then
        buttons = { { L["Done"], "done" }, { L["Shipped"], "shipped" }, { L["Craft"], function() ns.OpenRecipe(r.spell) end } }
      else
        buttons = { { L["Done"], "done" }, { L["Shipped"], "shipped" }, { L["Crafting"], "crafting" } }
      end
    elseif r.status == "crafting" then
      if r.to == ns.CharKey() and r.spell and r.spell > 0 and ns.OpenRecipe then
        buttons = { { L["Done"], "done" }, { L["Shipped"], "shipped" }, { L["Craft"], function() ns.OpenRecipe(r.spell) end } }
      else
        buttons = { { L["Done"], "done" }, { L["Shipped"], "shipped" } }
      end
    elseif r.status == "shipped" then
      buttons = { { L["Remove"], false }, { L["Done"], "done" } }
    end
  elseif r.status == "pending" or r.status == "accepted" or r.status == "crafting" then
    buttons = { { L["Cancel request"], "cancelled" } }
    if r.status == "pending" and r.acked ~= r.updated and R.MailOn() then
      buttons[2] = { L["By mail"], function() ns.Mail.PrepareRequest(r) end }
    end
  end
  if #buttons == 0 then buttons = { { L["Remove"], false } } end
  local btnW = #buttons >= 3 and 78 or 96
  local btnArea = #buttons * (btnW + 4) + 6
  local _, h1 = Label(0, y - 2, line1, "GameFontHighlight", LIST_W - btnArea)
  local _, h2 = Label(0, y - 4 - h1, "|cff9d9d9d" .. table.concat(details, "  -  ") .. "|r", nil, LIST_W - btnArea)
  for i, bt in ipairs(buttons) do
    local b = Action(LIST_W - i * (btnW + 4) + 4, y, bt[1], function()
      if type(bt[2]) == "function" then bt[2]()
      elseif bt[2] then R.Set(r.id, bt[2]) else R.Remove(r.id) end
    end)
    b:SetWidth(btnW)
  end
  return y - math.max(30, h1 + h2 + 12)
end

function U.RenderRequests()
  local inc, out = ns.Requests.Lists()
  local y = Section(0, L["For your characters"],
    L["Accept, craft, then mark it done; the mail helper attaches the item when you write to them."])
  if #inc == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody yet."] .. "|r")
    y = y - h - 8
  end
  for _, r in ipairs(inc) do y = RequestRow(y, r, true) end
  y = Section(y - 10, L["Your requests"],
    L["Click a recipe in a group member's Can craft tab to ask for it. Delivered the next time you are both online."])
  if #out == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody yet."] .. "|r")
    y = y - h - 6
    local bUp = Action(0, y, L["Browse Upgrades"], function()
      ComradeCraftDB.ui.sel = "group"
      ComradeCraftDB.ui.groupTab = "upgrades"
      ns.RefreshWindow()
    end)
    bUp:SetWidth(140)
    y = y - 28
  end
  for _, r in ipairs(out) do y = RequestRow(y, r, false) end
  return -y
end


-- Guild directory view: listed characters (empty search), or who crafts what matches the search.
local function DirectoryProfs(e)
  local parts = {}
  for _, line in ipairs(SortedKeys(e.p or {})) do
    local x = e.p[line]
    local locName = ns.ProfName and ns.ProfName(line, x[3]) or (x[3] or ("#" .. line))
    parts[#parts + 1] = ("%s %d/%d"):format(locName, x[1] or 0, x[2] or 0)
  end
  return table.concat(parts, ", ")
end

-- One crafter line with Favorite star, Whisper, and (for a group member) Ask for it button.
local function DirectoryRow(x, y, key, spell, text)
  local D = ns.Directory
  local fav = ns.IsFavorite and ns.IsFavorite(key)
  local star = fav and "|cffffd100* |r" or ""
  local _, h = Label(x, y - 4, star .. text, "GameFontHighlight", LIST_W - x - 280)
  local bf = Action(LIST_W - 270, y, fav and L["Unstar"] or L["Favorite"], function()
    if ns.ToggleFavorite then ns.ToggleFavorite(key) end
  end)
  bf:SetWidth(64)
  if D.WhisperTarget(key) then Action(LIST_W - 100, y, L["Whisper"], function() D.Whisper(key) end) end
  if spell and D.CanRequest(key) then
    Action(LIST_W - 200, y, L["Ask for it"], function() ns.Requests.ShowDialog(key, spell) end)
  end
  return y - math.max(26, h + 8)
end

function U.RenderDirectory(filter)
  local D = ns.Directory
  local idx = D.Index()
  local y = 0
  if not next(idx.chars) then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Nobody is listed yet. The directory is opt-in: each player lists their own characters in Manage group (List in guild directory) or with /comrade list."] .. "|r")
    y = y - h - 10
    local bList = Action(0, y, L["List my character"], function()
      ns.Directory.SetListed(ns.CharKey(), true)
      ns.RefreshWindow()
    end)
    bList:SetWidth(150)
    return -y + 28
  end
  if filter == "" then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["Type a product or recipe name in the search box."] .. "|r")
    y = y - h - 10
    local keys = SortedKeys(idx.chars, function(a, b)
      local fa = ns.IsFavorite and ns.IsFavorite(a) or false
      local fb = ns.IsFavorite and ns.IsFavorite(b) or false
      if fa ~= fb then return fa end
      return a < b
    end)
    for _, key in ipairs(keys) do
      local e = idx.chars[key]
      local seen = e.own and "" or ("  |cff9d9d9d" .. L["seen %s"]:format(Ago(e.seen)) .. "|r")
      y = DirectoryRow(0, y, key, nil, ns.ClassColored(key, e.cl) .. "  |cff9d9d9d" .. DirectoryProfs(e) .. "|r" .. seen)
    end
    return -y
  end
  local found = D.Search(filter)
  if #found == 0 then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["No crafter found."] .. "|r")
    return -y + h
  end
  for i = 1, math.min(#found, D.MAX_ROWS) do
    local r = found[i]
    local _, h = Label(0, y, "|cffffd100" .. r.name .. "|r  |cff9d9d9d- " .. D.Names(r.crafters, 3) .. "|r", "GameFontNormal")
    y = y - h - 6
    for i2 = 1, math.min(#r.crafters, 10) do
      local key = r.crafters[i2]
      y = DirectoryRow(16, y, key, r.spell, ns.ClassColored(key, idx.chars[key] and idx.chars[key].cl))
    end
    y = y - 6
  end
  if #found > D.MAX_ROWS then
    local _, h = Label(0, y, "|cff9d9d9d" .. L["... and %d more"]:format(#found - D.MAX_ROWS) .. "|r")
    y = y - h
  end
  return -y
end

