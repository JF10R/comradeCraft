-- UI/Group: Group overview, materials, craftable upgrades (BiS), disenchant advice, and Group plan.
local _, ns = ...
local L = ns.L
local U = ns.UI
local P = U.pools
local LIST_W, MAT_H, RECIPE_H, COLOR = U.LIST_W, U.MAT_H, U.RECIPE_H, U.COLOR
local groupRows, upgradeRows, planRows = P.groupRows, P.upgradeRows, P.planRows
local Acquire, ItemInfo, SortedKeys, ShortName, LineVisible, LinkOnShiftClick, ShowItemTooltip =
  U.Acquire, U.ItemInfo, U.SortedKeys, U.ShortName, U.LineVisible, U.LinkOnShiftClick, U.ShowItemTooltip
local SectionBar, Label, ShortMoney, PlaceMat, PlaceRecipe, Action, Toggle, FormatDuration =
  U.SectionBar, U.Label, U.ShortMoney, U.PlaceMat, U.PlaceRecipe, U.Action, U.Toggle, U.FormatDuration
local Matches, RecipeTags = U.Matches, U.RecipeTags

-- Group view: sub-tabs (Overview | Materials | Disenchant) to avoid information overload,
-- or instant "who can craft" search results when typing in the search box.
function U.RenderGroup(filter)
  local chars = ns.AllChars()
  local keys = SortedKeys(chars)
  local y = 0
  if filter ~= "" then
    -- 1. In group stock & active in-transit shipments matching `filter`.
    local stockHits = {}
    local seenStock = {}
    for _, key in ipairs(keys) do
      local c = chars[key]
      local totals = {}
      for _, src in ipairs({ c.bags or {}, c.bank or {}, c.mail or {} }) do
        for id, n in pairs(src) do
          if n > 0 then totals[id] = (totals[id] or 0) + n end
        end
      end
      for id, n in pairs(totals) do
        local name = ItemInfo(id)
        if name and name:lower():find(filter, 1, true) then
          local h = stockHits[id]
          if not h then
            h = { item = id, name = name, total = 0, holders = {} }
            stockHits[id] = h
            seenStock[#seenStock + 1] = h
          end
          h.total = h.total + n
          h.holders[#h.holders + 1] = { key = key, class = c.class, n = n, bankAlt = c.bankAlt, peer = c.peer }
        end
      end
    end
    local allTr = {}
    if ns.InTransitFor then allTr = select(2, ns.InTransitFor()) end
    for _, tr in ipairs(allTr) do
      local name = ItemInfo(tr.item)
      if name and name:lower():find(filter, 1, true) then
        local h = stockHits[tr.item]
        if not h then
          h = { item = tr.item, name = name, total = 0, holders = {}, transit = {} }
          stockHits[tr.item] = h
          seenStock[#seenStock + 1] = h
        end
        h.transit = h.transit or {}
        h.transit[#h.transit + 1] = tr
      end
    end
    table.sort(seenStock, function(a, b) return a.name < b.name end)
    local any = false
    if #seenStock > 0 then
      any = true
      y = y - SectionBar(0, y, LIST_W, "|cff80ccff" .. L["In group stock: \"%s\""]:format(filter) .. "|r") - 6
      local width = math.floor((LIST_W - 8) / 2)
      local shown = math.min(#seenStock, 16)
      for i = 1, shown do
        local h = seenStock[i]
        table.sort(h.holders, function(a, b) return a.n > b.n end)
        local parts, bankKey, bankN = {}, nil, nil
        for _, hl in ipairs(h.holders) do
          local tag = hl.bankAlt and (" [" .. L["Bank"] .. "]") or ""
          parts[#parts + 1] = ("%s %d%s"):format(ShortName(hl.key), hl.n, tag)
          if hl.peer and hl.bankAlt and not bankKey then bankKey, bankN = hl.key, hl.n end
        end
        for _, tr in ipairs(h.transit or {}) do
          local mins = math.max(1, math.ceil((tr.left or 0) / 60))
          parts[#parts + 1] = ("|cff80ccff%dx -> %s (~%dm)|r"):format(tr.qty, ShortName(tr.to), mins)
        end
        local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
        local card = PlaceMat(col * (width + 4), y - line * (MAT_H + 4), h.item, h.total, table.concat(parts, ", "), width)
        if bankKey then card.bankReq = { key = bankKey, want = bankN } end
      end
      y = y - math.ceil(shown / 2) * (MAT_H + 4) - 8
    end

    -- 2. Who can craft in your group.
    local found = {}
    for _, key in ipairs(keys) do
      for _, e in ipairs(ns.CraftCatalog(key)) do
        if Matches(e, filter) and LineVisible(e.line) then
          local f = found[e.spell]
          if not f then
            f = { e = e, who = {}, keys = {} }
            found[e.spell] = f
          end
          f.who[#f.who + 1] = ("|cff%s%s|r"):format(COLOR[e.color] or "ffffff", ShortName(key))
          f.keys[#f.keys + 1] = key
        end
      end
    end
    local list = {}
    for _, f in pairs(found) do list[#list + 1] = f end
    table.sort(list, function(a, b) return a.e.name < b.e.name end)
    if #list > 0 then
      any = true
      y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Who can craft \"%s\""]:format(filter) .. "|r") - 6
      for idx, f in ipairs(list) do
        local e = { spell = f.e.spell, item = f.e.item, color = "yellow", name = f.e.name }
        local row = PlaceRecipe(8, y, e, table.concat(f.who, ", "), nil, false, idx % 2 == 0)
        row.name:SetText(f.e.name)
        -- Pick best peer crafter (or own char) for 1-click Request / Pin right from search!
        local peerKey, ownKey
        for _, ck in ipairs(f.keys) do
          if chars[ck] and chars[ck].peer then peerKey = peerKey or ck else ownKey = ownKey or ck end
        end
        if peerKey and ns.Requests and ns.Requests.ShowDialog then
          local pk, sp = peerKey, f.e.spell
          Action(LIST_W - 88, y - 4, L["Request"], function() ns.Requests.ShowDialog(pk, sp) end):SetWidth(84)
        elseif ownKey and ns.Wishlist and ns.Wishlist.ShowDialog then
          local ok_, sp = ownKey, f.e.spell
          Action(LIST_W - 88, y - 4, L["Pin"], function() ns.Wishlist.ShowDialog(sp, ok_) end):SetWidth(84)
        end
        y = y - RECIPE_H
      end
      y = y - 6
    end

    -- 3. Guild directory matches (crafters outside your personal sync group).
    local dirFound = ns.Directory and ns.Directory.Search and ns.Directory.Search(filter) or {}
    if #dirFound > 0 then
      any = true
      y = y - SectionBar(0, y, LIST_W, "|cff66ccff" .. L["Guild directory"] .. "|r") - 6
      for i = 1, math.min(#dirFound, 12) do
        local d = dirFound[i]
        local c0 = d.crafters and d.crafters[1]
        local txt = ("|cffffd100%s|r  |cff9d9d9d- %s|r"):format(d.name, ns.Directory.Names(d.crafters, 4))
        local _, dh = Label(8, y - 4, txt, "GameFontHighlightSmall", LIST_W - 102)
        if c0 and ns.Directory.WhisperTarget(c0) then
          local ck = c0
          Action(LIST_W - 88, y, L["Whisper"], function() ns.Directory.Whisper(ck) end):SetWidth(84)
        end
        y = y - math.max(24, dh + 6)
      end
    end

    if not any then
      local _, h2 = Label(0, y, "|cff9d9d9d" .. L["No recipe matches."] .. "|r")
      y = y - h2
    end
    return -y
  end

  local subTab = ComradeCraftDB.ui.groupTab or "overview"

  if subTab == "mats" then
    y = y - SectionBar(0, y, LIST_W - 118, "|cffffd100" .. L["Most wanted materials"] .. "|r") - 6
    local mats_ = ns.GroupMaterials(LineVisible)
    local bShareMats = Action(LIST_W - 114, -2, L["Share in chat"], function()
      local parts = {}
      for i = 1, math.min(#mats_, 5) do
        local a = mats_[i]
        parts[#parts + 1] = ("%s x%d"):format((ItemInfo(a.item)) or ("item:" .. a.item), a.total)
      end
      if #parts > 0 and ns.ShareChat then
        ns.ShareChat("[ComradeCraft] " .. L["Materials"] .. ": " .. table.concat(parts, ", "))
      end
    end)
    bShareMats:SetWidth(110)
    if #mats_ == 0 then
      local _, h4 = Label(0, y, "|cff9d9d9d" .. L["Nothing missing yet."] .. "|r")
      return -y + h4
    end
    local width = math.floor((LIST_W - 8) / 3)
    for i = 1, math.min(#mats_, 42) do
      local a = mats_[i]
      local by = {}
      for _, b in ipairs(a.by) do
        by[#by + 1] = ("%s %d %s"):format(ShortName(b.key), b.n, ns.UrgencyText(b.step))
      end
      local spare = ns.GroupSupply(a.item)
      local bankKey, bankN
      if spare > 0 then
        by[#by + 1] = "|cff80ccff" .. L["group: %d"]:format(spare) .. "|r"
        for ck, cc in pairs(chars) do
          if cc.peer and cc.bankAlt then
            local sp = ns.Surplus(cc, a.item)
            if sp > 0 and (not bankN or sp > bankN) then bankKey, bankN = ck, sp end
          end
        end
      end
      local col, line = (i - 1) % 3, math.floor((i - 1) / 3)
      local card = PlaceMat(col * (width + 4), y - line * (MAT_H + 4), a.item, a.total, table.concat(by, ", "), width)
      if bankKey then card.bankReq = { key = bankKey, want = math.min(bankN, a.total) } end
    end
    y = y - math.ceil(math.min(#mats_, 42) / 3) * (MAT_H + 4)
    return -y
  end

  if subTab == "de" then
    local advice = ns.BagAdvice(ns.CharKey())
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Disenchant or keep?"] .. "|r",
      L["Green and better items in your bags. Yields are estimates until your disenchants are logged."]) - 6
    if #advice == 0 then
      local _, h4 = Label(0, y, "|cff9d9d9d" .. L["No disenchantable items in your bags."] .. "|r")
      return -y + h4
    end
    local width = math.floor((LIST_W - 8) / 2)
    local myBags = (ComradeCraftDB.chars[ns.CharKey()] or {}).bags or {}
    local shown = math.min(#advice, 24)
    for i = 1, shown do
      local a = advice[i]
      local text, canReserve
      if a.verdict == "target" then
        text = "|cff66ccff" .. L["Keep: enchanting target (%s)"]:format(ns.SpellName(a.spell)) .. "|r"
      elseif a.verdict == "gear" then
        local rv = ns.Reserve and ns.Reserve.Get(a.item)
        if rv then
          text = "|cffc080ff" .. L["Reserved for %s"]:format(ShortName(rv.to)) .. "|r"
        else
          text = "|cff66ccff" .. L["Keep: gear for %s"]:format(ShortName(a.to)) .. "|r"
          if a.to and not (ns.IsBoP and ns.IsBoP(a.item)) then canReserve = a.to end
        end
      elseif a.verdict == "sell" then
        text = "|cffffd100" .. L["Sell: AH %s vs disenchant %s"]:format(ns.Money(math.floor(a.ah)), ns.Money(math.floor(a.de))) .. "|r"
      else
        local parts = {}
        for mat, n in pairs(a.yield) do
          parts[#parts + 1] = { n = n, text = ("%.1f %s"):format(n, (ItemInfo(mat)) or ("item:" .. mat)) }
        end
        table.sort(parts, function(p, q) return p.n > q.n end)
        local list = {}
        for _, p in ipairs(parts) do list[#list + 1] = p.text end
        local _, calibrated, deN = ns.DisenchantYield and ns.DisenchantYield(a.item)
        text = L["Disenchant: %s"]:format(table.concat(list, ", "))
        if calibrated then text = text .. (" |cff40ff40(%s %d)|r"):format(L["measured"], deN or 0) end
        if a.useful then text = text .. "  |cff80ff80" .. L["the group needs these"] .. "|r" end
        if a.enchanter then text = text .. "  |cff66ccff" .. L["give to %s"]:format(ShortName(a.enchanter)) .. "|r" end
      end
      local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
      local card = PlaceMat(col * (width + 4), y - line * (MAT_H + 4), a.item, myBags[a.item] or 1, text, width)
      card.verdictText = text
      if canReserve then card.reserveTo = canReserve end
    end
    y = y - math.ceil(shown / 2) * (MAT_H + 4)
    return -y
  end

local function CreateUpgradeRow()
  local b = CreateFrame("Button", nil, U.content)
  b:SetHeight(24)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.ownBar = b:CreateTexture(nil, "ARTWORK")
  b.ownBar:SetWidth(2)
  b.ownBar:SetPoint("TOPLEFT", 0, 0)
  b.ownBar:SetPoint("BOTTOMLEFT", 0, 0)
  b.ownBar:SetColorTexture(0.35, 0.88, 0.55, 0.9)
  b.ownBar:Hide()
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(18, 18)
  b.icon:SetPoint("LEFT", 6, 0)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("LEFT", 28, 0)
  b.text:SetPoint("RIGHT", -104, 0)
  b.text:SetJustifyH("LEFT")
  b.text:SetWordWrap(false)
  b:SetScript("OnEnter", function(self)
    local u = self.entry
    if not u then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if u.item and u.item ~= 0 then
      GameTooltip:SetItemByID(u.item)
    elseif u.spell and GameTooltip.SetSpellByID then
      GameTooltip:SetSpellByID(u.spell)
    end
    if u.mats and u.mats.mats and #u.mats.mats > 0 then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(L["Group materials:"], 1, 0.82, 0)
      for _, m in ipairs(u.mats.mats) do
        local c = m.missing == 0 and { 0.3, 1, 0.4 } or { 1, 0.82, 0.4 }
        GameTooltip:AddDoubleLine(ns.ItemName(m.item), ("%d / %d"):format(m.have, m.need), 1, 1, 1, c[1], c[2], c[3])
      end
      if u.mats.cost then
        GameTooltip:AddDoubleLine(L["To buy at the AH"], ns.CostText(u.mats.cost, u.mats.complete) or "", 0.8, 0.8, 0.8, 1, 0.82, 0)
      end
    end
    if u.kind == "pattern" and ns.AddSourceLines then
      ns.AddSourceLines(GameTooltip, u.spell)
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    local u = self.entry
    if not u then return end
    if u.item and u.item ~= 0 and LinkOnShiftClick(u.item) then return end
    if u.kind == "pattern" and ns.WaypointRecipe then ns.WaypointRecipe(u.spell) end
  end)
  return b
end

  if subTab == "upgrades" then
    local groups = ns.Audit and ns.Audit.Run() or {}
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Group upgrades"] .. "|r",
      L["Small bags, unenchanted gear and craftable upgrades your group can make."]) - 6
    if #groups == 0 then
      local _, h4 = Label(0, y, "|cff9d9d9d" .. L["Everyone's bags, enchants and gear are up to date."] .. "|r")
      return -y + h4
    end
    local bShare = Action(LIST_W - 116, y, L["Share in chat"], function()
      local parts = {}
      for _, g in ipairs(groups) do
        for _, p in ipairs(g.patterns or {}) do
          if #parts < 4 then
            parts[#parts + 1] = (p.recipeItem and (ItemInfo(p.recipeItem)) or ns.SpellName(p.spell))
              .. " (" .. ShortName(g.targetKey) .. ")"
          end
        end
      end
      if #parts == 0 then
        for _, g in ipairs(groups) do
          for _, u in ipairs(g.items or {}) do
            if #parts < 4 and u.item and u.item ~= 0 then
              parts[#parts + 1] = (ItemInfo(u.item) or ("item:" .. u.item)) .. " (" .. ShortName(g.targetKey) .. ")"
            end
          end
        end
      end
      if #parts > 0 and ns.ShareChat then
        ns.ShareChat("[ComradeCraft] " .. L["Group upgrades"] .. ": " .. table.concat(parts, ", "))
      end
    end)
    bShare:SetWidth(112)
    y = y - 24
    local rowIdx = 0
    local function RenderUpgradeRow(u, targetShort)
      rowIdx = rowIdx + 1
      local ur = Acquire(upgradeRows, CreateUpgradeRow)
      ur.entry = u
      ur:ClearAllPoints()
      ur:SetPoint("TOPLEFT", U.content, "TOPLEFT", 6, y)
      ur:SetWidth(LIST_W - 6)
      local even = (rowIdx % 2 == 0)
      if u.ownCrafter then
        ur.bg:SetColorTexture(0.09, 0.19, 0.13, even and 0.50 or 0.34)
        ur.ownBar:Show()
      else
        ur.bg:SetColorTexture(even and 0.12 or 0.07, even and 0.12 or 0.07, even and 0.16 or 0.09, even and 0.44 or 0.24)
        ur.ownBar:Hide()
      end
      local ico = (u.item and u.item ~= 0 and select(3, ItemInfo(u.item)))
        or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(u.spell)) or 134400
      ur.icon:SetTexture(ico)
      if U.ApplyQualityBorder then U.ApplyQualityBorder(ur, ur.icon, u.item) end
      local tag = ""
      if u.mats then
        if u.mats.ready then
          tag = "  |cff40ff40" .. L["mats ready"] .. "|r"
        elseif u.mats.cost then
          tag = "  |cffb0b0b0(" .. (ns.CostText(u.mats.cost, u.mats.complete) or "") .. ")|r"
        end
      end
      local byTxt
      if u.ownCrafter then
        byTxt = "|cff66e89a" .. L["by %s (you)"]:format(ShortName(u.crafter)) .. "|r"
      elseif u.guildCrafter then
        byTxt = "|cff9d9d9d" .. L["by %s (guild)"]:format(ShortName(u.crafter)) .. "|r"
      else
        byTxt = "|cff9d9d9d" .. L["by %s"]:format(ShortName(u.crafter)) .. "|r"
      end
      ur.text:SetText(u.summary .. tag .. "  " .. byTxt)
      local spell, crafter, qty, own, guild = u.spell, u.crafter, u.qty or 1, u.ownCrafter, u.guildCrafter
      local btn
      if u.kind == "pattern" and ns.WaypointRecipe then
        btn = Action(LIST_W - 96, y - 1, L["Waypoint"], function() ns.WaypointRecipe(spell) end)
      elseif own and ns.Wishlist then
        local existing = ns.Wishlist.Find and ns.Wishlist.Find(spell, targetShort, crafter)
        if existing then
          local exId = existing.id
          btn = Action(LIST_W - 96, y - 1, L["Unpin"], function()
            ns.Wishlist.Remove(exId)
          end)
        else
          btn = Action(LIST_W - 96, y - 1, L["Pin"], function()
            ns.Wishlist.Add(spell, qty, targetShort, nil, true, crafter)
          end)
        end
      elseif guild and ns.Directory and ns.Directory.Whisper then
        btn = Action(LIST_W - 96, y - 1, L["Whisper"], function()
          ns.Directory.Whisper(crafter)
        end)
      elseif not own and ns.Requests then
        btn = Action(LIST_W - 96, y - 1, L["Request"], function()
          ns.Requests.ShowDialog(crafter, spell)
        end)
      end
      if btn then
        btn:SetWidth(90)
        if btn.SetFrameLevel and ur.GetFrameLevel then btn:SetFrameLevel(ur:GetFrameLevel() + 2) end
      end
      y = y - 26
    end
    for _, grp in ipairs(groups) do
      local specSub = grp.targetSpecLabel and grp.targetSpecLabel ~= "" and grp.targetSpecLabel or ""
      local barW = (grp.ownTarget and ns.GearScore and ns.GearScore.CycleSpec) and (LIST_W - 114) or LIST_W
      local barH = SectionBar(0, y, barW, ns.ClassColored(grp.targetKey, grp.targetClass), specSub)
      if grp.ownTarget and ns.GearScore and ns.GearScore.CycleSpec then
        local tkey = grp.targetKey
        local bs = Action(LIST_W - 108, y - 1, L["Spec: %s"]:format(grp.targetSpecLabel or "?"), function()
          ns.GearScore.CycleSpec(tkey)
        end)
        bs:SetWidth(104)
      end
      y = y - barH - 4
      local tShort = ShortName(grp.targetKey)
      for _, u in ipairs(grp.items or {}) do RenderUpgradeRow(u, tShort) end
      if grp.soon and #grp.soon > 0 then
        local _, sh = Label(12, y - 2, "|cffffd100" .. L["Soon (+1-4 lvl)"] .. "|r", "GameFontNormalSmall")
        y = y - sh - 4
        for _, u in ipairs(grp.soon) do RenderUpgradeRow(u, tShort) end
      end
      if grp.consumables and #grp.consumables > 0 then
        local _, sh = Label(12, y - 2, "|cff80ccff" .. L["Consumables"] .. "|r", "GameFontNormalSmall")
        y = y - sh - 4
        for _, u in ipairs(grp.consumables) do RenderUpgradeRow(u, tShort) end
      end
      if grp.patterns and #grp.patterns > 0 then
        local _, sh = Label(12, y - 2, "|cffa080ff" .. L["Patterns to hunt"] .. "|r", "GameFontNormalSmall")
        y = y - sh - 4
        for _, u in ipairs(grp.patterns) do RenderUpgradeRow(u, tShort) end
      end
      y = y - 10
    end
    return -y
  end

  -- Overview sub-tab: Active farming for you, Synergies, "You can give", "Skill levels", "Group cooldowns".
  local meChar = chars[ns.CharKey()]
  local farmForMe = {}
  if meChar and ns.Farmers and ns.NeedOf then
    local seenItem = {}
    for _, need in pairs(meChar.needs or {}) do
      for item, n in pairs(need.items or {}) do
        if n > 0 and not seenItem[item] then
          seenItem[item] = true
          for _, f in ipairs(ns.Farmers(item) or {}) do
            if not (ns.IsSameChar and ns.IsSameChar(f.key, ns.CharKey()) or f.key == ns.CharKey()) then
              local fc = chars[f.key]
              local have = fc and (((fc.bags or {})[item] or 0) + ((fc.bank or {})[item] or 0)) or 0
              farmForMe[#farmForMe + 1] = { farmer = f.key, class = fc and fc.class, item = item,
                have = math.min(have, f.target), target = f.target }
            end
          end
        end
      end
    end
  end
  if #farmForMe > 0 then
    y = y - SectionBar(0, y, LIST_W, "|cff40ff40" .. L["Farming for you"] .. "|r") - 6
    for i = 1, math.min(#farmForMe, 4) do
      local fm = farmForMe[i]
      local line = ("%s  |cff80ff80->|r  %s (%d/%d)"):format(
        ns.ClassColored(fm.farmer, fm.class), (ItemInfo(fm.item)) or ("item:" .. fm.item), fm.have, fm.target)
      local _, fh = Label(8, y - 2, line, "GameFontHighlightSmall", LIST_W - 16)
      y = y - fh - 5
    end
    y = y - 6
  end

  -- Sky-blue banner: active peer mail shipments currently in the 1h Classic/Forever transit window.
  local allTransit = {}
  if ns.InTransitFor then allTransit = select(2, ns.InTransitFor()) end
  if #allTransit > 0 then
    y = y - SectionBar(0, y, LIST_W, "|cff80ccff" .. L["In transit (1h mail)"] .. "|r",
      L["Already mailed between group accounts — counted as on the way so nobody double-sends."]) - 6
    for i = 1, math.min(#allTransit, 6) do
      local tr = allTransit[i]
      local mins = math.max(1, math.ceil((tr.left or 0) / 60))
      local line = ("%s  |cff80ccff->|r  %s : |cffffffff%dx %s|r  |cff9d9d9d(~%dm)|r"):format(
        ns.ClassColored(tr.from, tr.fromClass), ns.ClassColored(tr.to, tr.toClass),
        tr.qty, (ItemInfo(tr.item)) or ("item:" .. tr.item), mins)
      local _, th = Label(8, y - 2, line, "GameFontHighlightSmall", LIST_W - 16)
      y = y - th - 5
    end
    y = y - 6
  end

  -- Violet banner: items other group members reserved/locked for you before mailing.
  local resForMe = {}
  local meKey = ns.CharKey()
  for key, c in pairs(chars) do
    if key ~= meKey and not (ns.IsSameChar and ns.IsSameChar(key, meKey)) then
      for item, rv in pairs(c.reserved or {}) do
        if rv and rv.to and (rv.to == meKey or (ns.IsSameChar and ns.IsSameChar(rv.to, meKey))) and (rv.qty or 0) > 0 then
          resForMe[#resForMe + 1] = { from = key, class = c.class, item = item, qty = rv.qty }
        end
      end
    end
  end
  if #resForMe > 0 then
    table.sort(resForMe, function(a, b) return a.qty > b.qty or (a.qty == b.qty and a.item < b.item) end)
    y = y - SectionBar(0, y, LIST_W, "|cffc080ff" .. L["Reserved for you"] .. "|r") - 6
    for i = 1, math.min(#resForMe, 6) do
      local rm = resForMe[i]
      local line = ("%s  |cffc080ff->|r  %dx %s"):format(
        ns.ClassColored(rm.from, rm.class), rm.qty, (ItemInfo(rm.item)) or ("item:" .. rm.item))
      local _, rh = Label(8, y - 2, line, "GameFontHighlightSmall", LIST_W - 16)
      y = y - rh - 5
    end
    y = y - 6
  end

  -- Compact list of your own currently locked/reserved items with 1-click Unlock.
  local myRes = {}
  for item, rv in pairs(meChar and meChar.reserved or {}) do
    if rv and rv.to and (rv.qty or 0) > 0 then
      myRes[#myRes + 1] = { item = item, to = rv.to, qty = rv.qty }
    end
  end
  if #myRes > 0 then
    table.sort(myRes, function(a, b) return a.to < b.to or (a.to == b.to and a.item < b.item) end)
    y = y - SectionBar(0, y, LIST_W, "|cffc080ff" .. L["Your reserved items"] .. "|r",
      L["Alt+Right-click any bag item to reserve/lock it for a friend before mailing."]) - 6
    for i = 1, math.min(#myRes, 6) do
      local mr = myRes[i]
      local itemID = mr.item
      local line = ("%dx %s  |cffc080ff->|r  %s"):format(
        mr.qty, (ItemInfo(itemID)) or ("item:" .. itemID),
        ns.ClassColored(mr.to, chars[mr.to] and chars[mr.to].class))
      local _, rh = Label(8, y - 4, line, "GameFontHighlightSmall", LIST_W - 92)
      local bu = Action(LIST_W - 80, y, L["Unlock"], function()
        if ns.Reserve then ns.Reserve.Clear(itemID) end
      end)
      bu:SetWidth(76)
      y = y - math.max(24, rh + 6)
    end
    y = y - 6
  end

  -- Zone & Dungeon Radar: rare drops, vendors, BiS patterns & mats useful to your group right here.
  if ns.ZoneRadar and ns.ZoneRadar.Scan then
    local zHits, zName = ns.ZoneRadar.Scan()
    if #zHits > 0 then
      y = y - SectionBar(0, y, LIST_W, "|cff66e89a" .. L["In your zone: %s"]:format(zName or "?") .. "|r",
        L["Rare drops, vendors, patterns and materials useful to your group right here."]) - 6
      for i = 1, math.min(#zHits, 6) do
        local h = zHits[i]
        local badge = h.rare and "|cffff80ff[Rare]|r " or (h.kind == "vendor" and "|cffffd100[Vendor]|r " or "")
        local rate = h.rate and (" |cff9d9d9d(~" .. h.rate .. ")|r") or ""
        local coords = (h.x and h.y) and (" |cff9d9d9d(" .. h.x .. ", " .. h.y .. ")|r") or ""
        local txt = ("%s|cffffffff%s|r  |cff80ccff%s|r%s%s  |cff9d9d9d-> %s|r"):format(
          badge, h.label or "", h.npcName or "", coords, rate, h.who or "")
        local _, zh = Label(8, y - 4, txt, "GameFontHighlightSmall", LIST_W - 102)
        local entry = h
        local bw = Action(LIST_W - 88, y, L["Waypoint"], function() ns.ZoneRadar.Waypoint(entry) end)
        bw:SetWidth(84)
        y = y - math.max(24, zh + 6)
      end
      y = y - 6
    end
  end

  local syns = ns.Synergies and ns.Synergies.Find() or {}
  if #syns > 0 then
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Group synergies"] .. "|r",
      L["Cross-profession links between your group's active plans."]) - 6
    for i = 1, math.min(#syns, 4) do
      local s = syns[i]
      local _, sh = Label(8, y - 2, "|cff80ff80>|r " .. s.detail, "GameFontHighlightSmall", LIST_W - 16)
      y = y - sh - 5
    end
    y = y - 6
  end

  local give = ns.GiveList(ns.CharKey())
  if #give > 0 then
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["You can give"] .. "|r",
      L["Spare items in your bags that others need. With a mailbox open, click one to prepare the mail."]) - 6
    local width = math.floor((LIST_W - 8) / 3)
    local shown = math.min(#give, 12)
    for i = 1, shown do
      local g = give[i]
      local col, line = (i - 1) % 3, math.floor((i - 1) / 3)
      PlaceMat(col * (width + 4), y - line * (MAT_H + 4), g.item, g.n,
        ("-> %s %s"):format(ns.ClassColored(g.to, chars[g.to] and chars[g.to].class), ns.UrgencyText(g.step)), width)
        .giveTo = g.to
    end
    y = y - math.ceil(shown / 3) * (MAT_H + 4) - 10
  end

  -- Actionable prompt when playing without friends added yet.
  local peerCount = 0
  for _, p in pairs(ComradeCraftDB and ComradeCraftDB.peers or {}) do
    if p.included then peerCount = peerCount + 1 end
  end
  if peerCount == 0 then
    local _, eh = Label(4, y - 2, "|cff9d9d9d" .. L["No friends in your group yet. Add guildmates or friends to share mats and upgrades."] .. "|r",
      nil, LIST_W - 140)
    local bAdd = Action(LIST_W - 130, y, L["Add friends"], function()
      ComradeCraftDB.ui.sel = "manage"
      ns.RefreshWindow()
    end)
    bAdd:SetWidth(124)
    y = y - math.max(26, eh + 8) - 6
  end

  -- Skill table: one clickable line per character (click opens that character's sheet).
  y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Skill levels"] .. "|r") - 6
  local ri = 0
  for _, key in ipairs(keys) do
    local c = chars[key]
    local parts = {}
    for _, pname in ipairs(SortedKeys(c.professions or {})) do
      local p = c.professions[pname]
      if LineVisible(p.skillLine) then
        local locName = ns.ProfName and ns.ProfName(p.skillLine, pname) or pname
        parts[#parts + 1] = ("%s %d/%d"):format(locName, p.rank or 0, p.max or 0)
      end
    end
    if #parts > 0 or not ComradeCraftDB.ui.prof then
      ri = ri + 1
      local gr = Acquire(groupRows, function()
        local b = CreateFrame("Button", nil, U.content)
        b:SetWidth(LIST_W)
        b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.bg:Hide()
        b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        b.name:SetPoint("TOPLEFT", 6, -3)
        b.name:SetWidth(170)
        b.name:SetJustifyH("LEFT")
        b.profs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.profs:SetPoint("TOPLEFT", 182, -4)
        b.profs:SetWidth(LIST_W - 188)
        b.profs:SetJustifyH("LEFT")
        b:SetScript("OnClick", function(self)
          if self.key then
            ComradeCraftDB.ui.sel = self.key
            ns.RefreshWindow()
          end
        end)
        return b
      end)
      gr.key = key
      gr:ClearAllPoints()
      gr:SetPoint("TOPLEFT", U.content, "TOPLEFT", 0, y)
      if ri % 2 == 0 then gr.bg:SetColorTexture(0.10, 0.10, 0.13, 0.34) gr.bg:Show() else gr.bg:Hide() end
      gr.name:SetText(ns.ClassColored(key, c.class) .. (c.spec and ("  |cff9d9d9d" .. c.spec .. "|r") or ""))
      gr.profs:SetText(table.concat(parts, "   "))
      local rh = math.max(22, (gr.profs:GetStringHeight() or 12) + 8)
      gr:SetHeight(rh)
      y = y - rh - 1
    end
  end

  -- Group cooldowns + Cooldown Market (net profit estimate + 1-click Claim CD request).
  local now = (GetServerTime and GetServerTime()) or time()
  local cds = {}
  for _, key in ipairs(keys) do
    local c = chars[key]
    for spell, readyAt in pairs(c.cooldowns or {}) do
      local profit
      local r = ns.Recipes and ns.Recipes[spell]
      if r and r[5] and r[5] ~= 0 and ns.PriceSource then
        local outP = ns.PriceSource(r[5])
        if outP and outP > 0 then
          local matCost, complete = 0, true
          local reag = r[7] or {}
          for i = 1, #reag, 2 do
            local mp = ns.BuyCost and ns.BuyCost(reag[i], reag[i + 1])
            if mp then matCost = matCost + mp else complete = false end
          end
          if complete then profit = outP * math.max(1, r[6] or 1) - matCost end
        end
      end
      cds[#cds + 1] = { key = key, class = c.class, peer = c.peer and true or false,
        spell = spell, left = readyAt - now, profit = profit }
    end
  end
  if #cds > 0 then
    table.sort(cds, function(a, b) return a.left < b.left end)
    local claimed = {}
    for _, req in pairs(ComradeCraftDB and ComradeCraftDB.requests or {}) do
      if req.status == "pending" or req.status == "accepted" or req.status == "crafting" then
        claimed[req.to .. "|" .. tostring(req.spell)] = req.from
      end
    end
    local meKeyCd = ns.CharKey()
    y = y - 10
    y = y - SectionBar(0, y, LIST_W, "|cffffd100" .. L["Group cooldowns"] .. "|r",
      L["Estimated net profit and 1-click Claim CD for your group's long cooldowns."]) - 6
    for _, cd in ipairs(cds) do
      Label(6, y - 4, ns.ClassColored(cd.key, cd.class), "GameFontHighlightSmall", 132)
      local profTag = ""
      if cd.profit and cd.profit > 0 then
        profTag = "  |cff40ff40(+" .. ns.Money(math.floor(cd.profit)) .. ")|r"
      end
      local claimer = claimed[cd.key .. "|" .. tostring(cd.spell)]
      local claimTag = claimer and ("  |cffc080ff[" .. L["Reserved by %s"]:format(ShortName(claimer)) .. "]|r") or ""
      local hasAction = (cd.peer and ns.Requests and ns.Requests.ShowDialog) or (cd.key == meKeyCd and cd.left <= 0)
      Label(142, y - 4, ns.SpellName(cd.spell) .. profTag .. claimTag, "GameFontHighlightSmall",
        LIST_W - (hasAction and 326 or 244))
      local st = Label(LIST_W - (hasAction and 180 or 98), y - 4, FormatDuration(cd.left), "GameFontHighlightSmall", 90)
      st:SetJustifyH("RIGHT")
      if cd.peer and ns.Requests and ns.Requests.ShowDialog then
        local cKey, cSpell = cd.key, cd.spell
        local bc = Action(LIST_W - 84, y, L["Claim CD"], function()
          ns.Requests.ShowDialog(cKey, cSpell, "[CD]")
        end)
        bc:SetWidth(80)
      elseif cd.key == meKeyCd and cd.left <= 0 and ns.OpenRecipe then
        local cSpell = cd.spell
        local bc = Action(LIST_W - 84, y, L["Craft"], function() ns.OpenRecipe(cSpell) end)
        bc:SetWidth(80)
      end
      y = y - 24
    end
  end
  return -y
end


-- Group plan view: one row per material the group still needs, its spare, the cost of the
-- rest and who farms it. Columns (x from the row's left): material | needed | spare | to get | cost | farming.
local PLAN_H, PC_NEED, PC_SPARE, PC_GET, PC_COST, PC_FARM = 40, 250, 304, 420, 470, 568

local function CreatePlanRow()
  local b = CreateFrame("Button", nil, U.content)
  b:SetHeight(PLAN_H)
  b:SetWidth(PC_FARM - 4) -- the farming column holds buttons: kept out of the row's hit area
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(24, 24)
  b.icon:SetPoint("TOPLEFT", 0, -4)
  b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.name:SetPoint("TOPLEFT", 30, -4)
  b.by = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  b.by:SetPoint("TOPLEFT", 30, -18)
  for _, k in ipairs({ "name", "by" }) do
    b[k]:SetWidth(PC_NEED - 38)
    b[k]:SetJustifyH("LEFT")
    b[k]:SetWordWrap(false)
  end
  for _, col in ipairs({ { "need", PC_NEED, 44, "RIGHT" }, { "spare", PC_SPARE + 8, 104, "LEFT" },
    { "get", PC_GET, 44, "RIGHT" }, { "cost", PC_COST, 90, "RIGHT" } }) do
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", col[2], -10)
    fs:SetWidth(col[3])
    fs:SetJustifyH(col[4])
    fs:SetWordWrap(false)
    b[col[1]] = fs
  end
  -- No SetItemByID here: its tooltip hook (Tooltip.lua) would add the same breakdown twice.
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine((ItemInfo(self.row.item)) or ("item:" .. self.row.item), 1, 1, 1)
    ns.AddPlanLines(GameTooltip, self.row)
    if self.advice then
      GameTooltip:AddLine(" ")
      GameTooltip:AddDoubleLine(L["Advice"], self.advice.label, 0.8, 0.8, 0.8, 1, 1, 1)
      if self.advice.spot then
        local sp = self.advice.spot
        GameTooltip:AddDoubleLine(L["Farm spot"], ("%s (%s %d, %d)"):format(sp.name, sp.zone or "?", sp.x, sp.y),
          0.5, 0.8, 1, 1, 1, 1)
        GameTooltip:AddLine(L["Click: waypoint to farm spot."], 0.5, 0.8, 1)
      end
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if not LinkOnShiftClick(self.row.item) and self.advice and self.advice.spot and ns.FarmAdvice then
      ns.FarmAdvice.Waypoint(self.row.item)
    end
  end)
  return b
end

function U.RenderGroupPlan()
  local y = 0
  local objective = ns.GroupObjective()
  Label(0, y - 5, L["Objective:"], "GameFontNormal", 72)
  Toggle(76, y, L["Lowest group cost"], objective == "group", true, function() ns.SetGroupObjective("group") end):SetWidth(150)
  Toggle(230, y, L["Market value"], objective == "solo", true, function() ns.SetGroupObjective("solo") end):SetWidth(120)
  local desc = objective == "group"
    and L["Least gold spent by the group: stock already held in the group counts as free."]
    or L["Every material at its market value, as if each character were alone."]
  local _, h = Label(358, y - 5, "|cff9d9d9d" .. desc .. "|r", nil, LIST_W - 478)
  local bSharePlan = Action(LIST_W - 116, y, L["Share in chat"], function()
    local plist = ns.GroupPlan()
    local parts = {}
    for _, row in ipairs(plist) do
      if row.toGet > 0 and #parts < 5 then
        parts[#parts + 1] = ("%s x%d"):format((ItemInfo(row.item)) or ("item:" .. row.item), row.toGet)
      end
    end
    if #parts > 0 and ns.ShareChat then
      ns.ShareChat("[ComradeCraft] " .. L["Group plan"] .. ": " .. table.concat(parts, ", "))
    end
  end)
  bSharePlan:SetWidth(112)
  y = y - math.max(30, h + 12)
  local list, total, complete, any = ns.GroupPlan()
  if #list == 0 then
    local _, h2 = Label(0, y, "|cff9d9d9d" .. L["Nothing missing yet."] .. "|r")
    return -y + h2
  end
  for _, col in ipairs({ { 30, L["Material"], 200 }, { PC_NEED - 16, L["Needed"], 60 },
    { PC_SPARE + 8, L["Spare"], 110 }, { PC_GET - 16, L["To get"], 60 },
    { PC_COST + 20, L["Est. cost"], 70 }, { PC_FARM, L["Farming"], LIST_W - PC_FARM } }) do
    Label(col[1], y, "|cff8f8f8f" .. col[2] .. "|r", "GameFontDisableSmall", col[3])
  end
  y = y - 16
  local chars = ns.AllChars()
  local gold = (GetMoney and GetMoney()) or 0
  for idx, row in ipairs(list) do
    local b = Acquire(planRows, CreatePlanRow)
    b.row = row
    b.advice = row.toGet > 0 and ns.FarmAdvice and ns.FarmAdvice.Evaluate(row.item, row.toGet, gold) or nil
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", U.content, "TOPLEFT", 0, y)
    local name, _, icon = ItemInfo(row.item)
    b.icon:SetTexture(icon)
    if U.ApplyQualityBorder then U.ApplyQualityBorder(b, b.icon, row.item) end
    b.name:SetText(name or ("item:" .. row.item))
    local by, names = {}, {}
    for _, x in ipairs(row.by) do
      by[#by + 1] = ("%s %d"):format(ShortName(x.key), x.n)
      names[#names + 1] = ShortName(x.key)
    end
    b.by:SetText(table.concat(by, ", "))
    b.need:SetText(tostring(row.total))
    local holders = {}
    for i = 1, math.min(3, #row.holders) do holders[i] = ShortName(row.holders[i].key) end
    b.spare:SetText(row.spare > 0 and ("|cff80ccff%d|r |cff9d9d9d(%s)|r"):format(row.spare, table.concat(holders, ", "))
      or "|cff6f6f6f-|r")
    b.get:SetText(row.toGet > 0 and ("|cffffd100" .. row.toGet .. "|r") or "|cff40ff400|r")
    local costTxt = row.toGet == 0 and "|cff6f6f6f-|r" or row.cost and ShortMoney(row.cost) or "|cff9d9d9d?|r"
    if b.advice and row.toGet > 0 then
      local tag = b.advice.action == "buy" and " |cff40ff40" .. L["Buy"] .. "|r"
        or (b.advice.action == "farm" and " |cffffa040" .. L["Farm"] .. "|r" or "")
      costTxt = costTxt .. tag
    end
    b.cost:SetText(costTxt)
    -- Farming: who took it (own: a Drop button), else an offer when something is left to get.
    local farmers, mine = {}, nil
    for _, f in ipairs(row.farmers) do
      farmers[#farmers + 1] = ns.ClassColored(f.key, chars[f.key] and chars[f.key].class)
      if f.own then mine = f end
    end
    if #farmers > 0 then
      Label(PC_FARM, y - 4, L["Farmed by %s"]:format(table.concat(farmers, ", ")), nil, LIST_W - PC_FARM)
      if mine then
        local item = row.item
        Action(PC_FARM, y - 17, L["Drop"], function() ns.FarmDrop(item) end)
      end
    elseif row.toGet > 0 and not ns.IsVendorItem(row.item) then
      local item, n, who = row.item, row.toGet, table.concat(names, ", ")
      Action(PC_FARM, y - 9, L["I'll farm it"], function() ns.ShowFarmDialog(item, n, who) end)
    elseif row.spare > 0 and ns.Requests and ns.Requests.ShowItemDialog then
      local bankHolder
      for _, h in ipairs(row.holders or {}) do
        local hc = chars[h.key]
        if hc and hc.peer and hc.bankAlt then bankHolder = h break end
      end
      if bankHolder then
        local bKey, item, want = bankHolder.key, row.item, math.min(bankHolder.n, row.total)
        Action(PC_FARM, y - 9, L["Request"], function() ns.Requests.ShowItemDialog(bKey, item, want) end)
      end
    end
    y = y - PLAN_H
  end
  y = y - 8
  local text = not any and L["Estimated cost for the group: unknown (TSM or Auctionator give AH prices)."]
    or complete and L["Estimated cost for the group: %s"]:format(ns.Money(math.floor(total)))
    or L["Estimated cost for the group: at least %s (some items have no price)."]:format(ns.Money(math.floor(total)))
  if gold > 0 then
    text = text .. "   |cff9d9d9d" .. L["Your gold: %s"]:format("|cffffffff" .. ns.Money(gold) .. "|cff9d9d9d") .. "|r"
  end
  local _, th = Label(0, y, "|cffffd100" .. text .. "|r", "GameFontNormal")
  return -y + th + 4
end

