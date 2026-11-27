-- Wishlist: pin concrete crafts (e.g. bags for a friend, raid consumables), track their
-- materials (bags + bank + inbox), feed group tooltips/bags/mail/trade/merchant needs,
-- notify when ready to craft, and show a movable on-screen tracker for pinned goals.
local _, ns = ...
local L = ns.L

local Wishlist = {}
ns.Wishlist = Wishlist

local TRACKER_W, PAD, MAX_PINNED = 270, 10, 6

local function DB()
  ComradeCraftDB.wishlist = ComradeCraftDB.wishlist or {}
  return ComradeCraftDB.wishlist
end

local function Settings()
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  return ComradeCraftDB.settings
end

local function ItemName(id)
  if ns.ItemName then return ns.ItemName(id) end
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  return get and get(id) or ("item:" .. id)
end

local function ItemIcon(item, spell)
  if item and item ~= 0 then
    return (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item))
      or (GetItemIcon and GetItemIcon(item)) or 134400
  end
  return (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spell)) or 134400
end

function Wishlist.TrackerOn()
  return Settings().wishlistTracker ~= false
end

function Wishlist.SetTracker(on)
  Settings().wishlistTracker = on and true or false
  Wishlist.RefreshTracker()
end

function Wishlist.List(charKey, includeRemote)
  local out = {}
  for _, e in ipairs(DB()) do
    if not charKey or e.char == charKey then out[#out + 1] = e end
  end
  if includeRemote then
    for key, c in pairs(ns.AllChars()) do
      if c.peer and type(c.wishlist) == "table" and (not charKey or key == charKey) then
        for _, re in ipairs(c.wishlist) do
          out[#out + 1] = { id = re.id, char = key, spell = re.spell, item = re.item or 0,
            qty = re.qty, forWho = re.forWho, note = re.note, remote = true, peer = c.peer }
        end
      end
    end
  end
  return out
end

function Wishlist.Find(spell, forWho, crafterKey)
  local wantChar = crafterKey or ns.CharKey()
  local wantWho = type(forWho) == "string" and forWho:match("^%s*(.-)%s*$") or nil
  if wantWho == "" then wantWho = nil end
  for _, e in ipairs(DB()) do
    if e.spell == spell and e.char == wantChar and e.forWho == wantWho then return e end
  end
end

function Wishlist.Add(spell, qty, forWho, note, pinned, crafterKey)
  local r = ns.Recipes and ns.Recipes[spell]
  if not r then return nil end
  qty = math.max(1, math.floor(tonumber(qty) or 1))
  forWho = type(forWho) == "string" and forWho:match("^%s*(.-)%s*$") or ""
  note = type(note) == "string" and note:match("^%s*(.-)%s*$") or ""
  local list = DB()
  local entry = {
    id = tostring(time()) .. "-" .. tostring(math.random(1000, 9999)),
    char = crafterKey or ns.CharKey(),
    spell = spell,
    item = r[5] or 0,
    qty = qty,
    forWho = forWho ~= "" and forWho or nil,
    note = note ~= "" and note or nil,
    pinned = pinned ~= false,
    created = time(),
  }
  list[#list + 1] = entry
  ns.Log(("wishlist: added %dx spell %d for %s"):format(qty, spell, entry.forWho or "-"))
  local ch = ComradeCraftDB.chars and ComradeCraftDB.chars[entry.char]
  if ch then
    ch.updated = time()
    if entry.char ~= ns.CharKey() and ns.UpdateNeeds then ns.UpdateNeeds(ch) end
  end
  ns.RequestRefresh()
  Wishlist.RefreshTracker()
  return entry
end

function Wishlist.Remove(id)
  local list = DB()
  for i, e in ipairs(list) do
    if e.id == id then
      local ch = ComradeCraftDB.chars and ComradeCraftDB.chars[e.char]
      table.remove(list, i)
      if ch then
        ch.updated = time()
        if e.char ~= ns.CharKey() and ns.UpdateNeeds then ns.UpdateNeeds(ch) end
      end
      ns.RequestRefresh()
      Wishlist.RefreshTracker()
      return true
    end
  end
  return false
end

function Wishlist.SetPinned(id, on)
  for _, e in ipairs(DB()) do
    if e.id == id then
      e.pinned = on and true or false
      Wishlist.RefreshTracker()
      if ns.RefreshWindow then ns.RefreshWindow() end
      return true
    end
  end
end

-- Computes reagent needs for one wishlist entry against `char`'s owned stock (bags+bank+mail).
-- Expands missing intermediates (e.g. Bolts) when the crafter knows a recipe making them.
function Wishlist.Progress(entry, charData)
  local r = ns.Recipes and ns.Recipes[entry.spell]
  if not r then return { mats = {}, ready = false, missingCount = 0 } end
  local c = charData or (ComradeCraftDB and ComradeCraftDB.chars and ComradeCraftDB.chars[entry.char]) or {}
  local owned, bagOwned = {}, {}
  for item, n in pairs(c.bags or {}) do
    owned[item] = (owned[item] or 0) + n
    bagOwned[item] = (bagOwned[item] or 0) + n
  end
  for _, src in ipairs({ c.bank or {}, c.mail or {} }) do
    for item, n in pairs(src) do owned[item] = (owned[item] or 0) + n end
  end
  -- Known producers on this character for expanding missing intermediates.
  local producers = {}
  for _, set in pairs(c.known or {}) do
    for sp in pairs(set) do
      local sr = ns.Recipes[sp]
      if sr and sr[5] and sr[5] ~= 0 and not producers[sr[5]] then producers[sr[5]] = sp end
    end
  end
  local gross = {}
  local function Accum(spell, mult, depth)
    local reag = ns.Recipes[spell] and ns.Recipes[spell][7] or {}
    for i = 1, #reag, 2 do
      local item, need = reag[i], math.ceil(reag[i + 1] * mult - 1e-9)
      local have = owned[item] or 0
      local sub = producers[item]
      if sub and sub ~= spell and depth < 3 and have < need then
        if have > 0 then gross[item] = (gross[item] or 0) + have end
        local deficit = need - have
        local subYield = math.max(1, ns.Recipes[sub][6] or 1)
        Accum(sub, deficit / subYield, depth + 1)
      else
        gross[item] = (gross[item] or 0) + need
      end
    end
  end
  Accum(entry.spell, entry.qty, 0)
  local mats, ready, bagReady, missingCount = {}, true, true, 0
  local handled = {}
  local function PushMat(item, need, have, inBags)
    local miss = math.max(0, need - have)
    if miss > 0 then ready = false missingCount = missingCount + miss end
    if inBags < need then bagReady = false end
    mats[#mats + 1] = { item = item, need = need, have = math.min(have, need), missing = miss,
      vendor = ns.IsVendorItem and ns.IsVendorItem(item) or false }
  end
  for item, need in pairs(gross) do
    if not handled[item] then
      local t = ns.ITEM_TRANSFORMS and ns.ITEM_TRANSFORMS[item]
      if t and ns.PairBalance then
        local small = t.isSmall and item or t.other
        local big = t.isSmall and t.other or item
        handled[small], handled[big] = true, true
        local nS, nB = gross[small] or 0, gross[big] or 0
        local hS, _, _, hB = ns.PairBalance(owned[small] or 0, owned[big] or 0, nS, nB, t.ratio)
        local bS, _, _, bB = ns.PairBalance(bagOwned[small] or 0, bagOwned[big] or 0, nS, nB, t.ratio)
        if nS > 0 then PushMat(small, nS, hS, bS) end
        if nB > 0 then PushMat(big, nB, hB, bB) end
      else
        PushMat(item, need, owned[item] or 0, bagOwned[item] or 0)
      end
    end
  end
  table.sort(mats, function(a, b)
    if (a.missing > 0) ~= (b.missing > 0) then return a.missing > 0 end
    return a.need > b.need
  end)
  local convHints = ns.ConversionHints and ns.ConversionHints(entry.spell, entry.qty, bagOwned) or {}
  return { mats = mats, ready = ready, bagReady = bagReady, missingCount = missingCount, convHints = convHints }
end

-- Injects missing wishlist materials into `c.needs[0]` so tooltips, bags, mail, trade,
-- merchant auto-buy, shopping lists and group plan all include pinned wishlist goals.
function Wishlist.InjectNeeds(c, charKey)
  if not (ComradeCraftDB and c and charKey) then return end
  local entries = c.peer and (c.wishlist or {}) or Wishlist.List(charKey)
  if #entries == 0 then return end
  local items, vendor, gross, have, when, whenSpell = {}, {}, {}, {}, {}, {}
  local any = false
  for _, e in ipairs(entries) do
    local prog = Wishlist.Progress(e, c)
    for _, m in ipairs(prog.mats) do
      gross[m.item] = (gross[m.item] or 0) + m.need
      have[m.item] = math.max(have[m.item] or 0, m.have)
      if m.missing > 0 then
        any = true
        when[m.item] = 1
        if not whenSpell[m.item] then whenSpell[m.item] = e.spell end
        if m.vendor then vendor[m.item] = (vendor[m.item] or 0) + m.missing
        else items[m.item] = (items[m.item] or 0) + m.missing end
      end
    end
  end
  if any then
    c.needs = c.needs or {}
    c.needs[0] = { name = L["Wishlist"], items = items, vendor = vendor, gross = gross, have = have,
      when = when, whenSpell = whenSpell, plan = { { spell = entries[1].spell } } }
  end
end

-- Auto-decrements (or completes) matching local Wishlist entries when you cast the craft.
function Wishlist.OnCrafted(spellID)
  if not (ComradeCraftDB and ComradeCraftDB.wishlist and spellID) then return false end
  local me = ns.CharKey()
  local list = DB()
  for i, e in ipairs(list) do
    if e.char == me and e.spell == spellID then
      e.qty = (e.qty or 1) - 1
      local ch = ComradeCraftDB.chars and ComradeCraftDB.chars[me]
      if ch then ch.updated = time() end
      if e.qty <= 0 then
        local name = e.item ~= 0 and ItemName(e.item) or ns.SpellName(e.spell)
        table.remove(list, i)
        ns.Print(L["Wishlist completed: %s"]:format(name))
      end
      ns.RequestRefresh()
      Wishlist.RefreshTracker()
      return true
    end
  end
  return false
end

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
  if unit == "player" and spellID then Wishlist.OnCrafted(spellID) end
end)

-- Reusable Craft Kits (e.g. Raid Kit / Dungeon Kit): save current Wishlist and apply xN in 1 click.
local function KitsDB()
  ComradeCraftDB.kits = ComradeCraftDB.kits or {}
  return ComradeCraftDB.kits
end

function Wishlist.Kits()
  local out = {}
  for name, entries in pairs(KitsDB()) do
    if type(entries) == "table" and #entries > 0 then
      out[#out + 1] = { name = name, entries = entries }
    end
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

function Wishlist.SaveKit(name)
  name = type(name) == "string" and name:match("^%s*(.-)%s*$") or ""
  if name == "" then return false end
  local me = ns.CharKey()
  local src = Wishlist.List(me)
  if #src == 0 then src = Wishlist.List() end
  if #src == 0 then return false end
  local entries = {}
  for _, e in ipairs(src) do
    if e.spell and ns.Recipes and ns.Recipes[e.spell] then
      entries[#entries + 1] = { spell = e.spell, qty = math.max(1, e.qty or 1) }
    end
  end
  if #entries == 0 then return false end
  KitsDB()[name] = entries
  ns.Print(L["Saved craft kit \"%s\" (%d recipes)."]:format(name, #entries))
  if ns.RefreshWindow then ns.RefreshWindow() end
  return true
end

function Wishlist.DeleteKit(name)
  if not (name and KitsDB()[name]) then return false end
  KitsDB()[name] = nil
  if ns.RefreshWindow then ns.RefreshWindow() end
  return true
end

function Wishlist.ApplyKit(name, mult, forWho)
  local entries = name and KitsDB()[name]
  if type(entries) ~= "table" or #entries == 0 then return 0 end
  mult = math.max(1, math.floor(tonumber(mult) or 1))
  local me = ns.CharKey()
  local added = 0
  for _, e in ipairs(entries) do
    if e.spell and ns.Recipes and ns.Recipes[e.spell] then
      local existing = Wishlist.Find(e.spell, forWho, me)
      if existing then
        existing.qty = (existing.qty or 1) + (e.qty or 1) * mult
      else
        Wishlist.Add(e.spell, (e.qty or 1) * mult, forWho, name, true, me)
      end
      added = added + 1
    end
  end
  if added > 0 then
    local ch = ComradeCraftDB.chars and ComradeCraftDB.chars[me]
    if ch then ch.updated = time() end
    ns.RequestRefresh()
    Wishlist.RefreshTracker()
    ns.Print(L["Applied craft kit \"%s\" (x%d)."]:format(name, mult))
  end
  return added
end

local kitDialog
function Wishlist.ShowSaveKitDialog()
  if not kitDialog then
    kitDialog = CreateFrame("Frame", "ComradeCraftKitDialog", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    kitDialog:SetSize(320, 124)
    kitDialog:SetPoint("CENTER")
    kitDialog:SetFrameStrata("DIALOG")
    kitDialog:SetToplevel(true)
    kitDialog:EnableMouse(true)
    local solid = kitDialog:CreateTexture(nil, "BACKGROUND", nil, -8)
    solid:SetPoint("TOPLEFT", 4, -4)
    solid:SetPoint("BOTTOMRIGHT", -4, 4)
    solid:SetColorTexture(0.06, 0.05, 0.04, 0.97)
    if kitDialog.SetBackdrop then
      kitDialog:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
      kitDialog:SetBackdropBorderColor(1, 0.82, 0, 1)
    end
    kitDialog.title = kitDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    kitDialog.title:SetPoint("TOPLEFT", 14, -14)
    kitDialog.title:SetText(L["Save current wishlist as a reusable kit"])
    kitDialog.name = CreateFrame("EditBox", nil, kitDialog, "InputBoxTemplate")
    kitDialog.name:SetSize(280, 22)
    kitDialog.name:SetPoint("TOPLEFT", 18, -46)
    kitDialog.name:SetMaxLetters(40)
    kitDialog.name:SetAutoFocus(false)
    kitDialog.name:SetScript("OnEscapePressed", function() kitDialog:Hide() end)
    local function Save()
      if Wishlist.SaveKit(kitDialog.name:GetText()) then kitDialog:Hide() end
    end
    kitDialog.name:SetScript("OnEnterPressed", Save)
    local ok = CreateFrame("Button", nil, kitDialog, "UIPanelButtonTemplate")
    ok:SetSize(96, 22)
    ok:SetPoint("BOTTOMRIGHT", -14, 12)
    ok:SetText(L["Save kit"])
    ok:SetScript("OnClick", Save)
    local cancel = CreateFrame("Button", nil, kitDialog, "UIPanelButtonTemplate")
    cancel:SetSize(84, 22)
    cancel:SetPoint("RIGHT", ok, "LEFT", -6, 0)
    cancel:SetText(CANCEL or "Cancel")
    cancel:SetScript("OnClick", function() kitDialog:Hide() end)
    if UISpecialFrames then tinsert(UISpecialFrames, "ComradeCraftKitDialog") end
  end
  kitDialog.name:SetText("")
  kitDialog:Show()
  kitDialog.name:SetFocus()
end

-- Fires a toast when all materials for a wishlist item are in the current character's bags.
-- Includes right-click essence conversion hints (e.g. 3x Lesser -> 1x Greater) when required.
function Wishlist.CheckReady()
  if not (ComradeCraftDB and ComradeCraftDB.wishlist and ns.Alerts) then return end
  local me = ns.CharKey()
  local c = ComradeCraftDB.chars and ComradeCraftDB.chars[me]
  if not c then return end
  local alertedKey = {}
  for _, e in ipairs(Wishlist.List(me)) do
    local prog = Wishlist.Progress(e, c)
    if prog.bagReady then
      if not e.readyAlerted then
        e.readyAlerted = true
        local dedup = tostring(e.spell) .. "|" .. tostring(e.forWho or "")
        if not alertedKey[dedup] then
          alertedKey[dedup] = true
          if ns.PlaySound then ns.PlaySound("ready") end
          local name = e.item ~= 0 and ItemName(e.item) or ns.SpellName(e.spell)
          local convTxt = ns.FormatConversionHints and ns.FormatConversionHints(prog.convHints)
          local lines = {}
          if e.forWho then lines[#lines + 1] = L["For %s"]:format(e.forWho) end
          if convTxt then
            lines[#lines + 1] = "|cff66ccff" .. convTxt .. "|r"
          elseif #lines == 0 then
            lines[#lines + 1] = L["All materials are in your bags."]
          end
          ns.Alerts.Notify({
            title = L["Wishlist ready: %dx %s"]:format(e.qty, name),
            text = table.concat(lines, "\n"),
            icon = ItemIcon(e.item, e.spell),
            item = e.item ~= 0 and e.item or nil,
            sticky = true,
            buttons = { { L["Craft"], function() ns.OpenRecipe(e.spell) end } },
          })
        end
      end
    else
      e.readyAlerted = nil
    end
  end
end

-- Add-to-Wishlist dialog ------------------------------------------------------------------

local dialog
local function CreateDialog()
  dialog = CreateFrame("Frame", "ComradeCraftWishlistDialog", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  dialog:SetSize(330, 224)
  dialog:SetPoint("CENTER")
  dialog:SetFrameStrata("DIALOG")
  dialog:SetMovable(true)
  dialog:SetClampedToScreen(true)
  dialog:EnableMouse(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetScript("OnDragStart", dialog.StartMoving)
  dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
  if dialog.SetBackdrop then
    dialog:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 } })
  end
  dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  dialog.title:SetPoint("TOPLEFT", 18, -16)
  dialog.title:SetText(L["Add to wishlist"])
  dialog.recipe = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  dialog.recipe:SetPoint("TOPLEFT", 18, -42)
  dialog.recipe:SetWidth(294)
  dialog.recipe:SetJustifyH("LEFT")

  local ql = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ql:SetPoint("TOPLEFT", 18, -68)
  ql:SetText(L["Quantity:"])
  dialog.qty = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
  dialog.qty:SetSize(50, 20)
  dialog.qty:SetPoint("LEFT", ql, "RIGHT", 10, 0)
  dialog.qty:SetAutoFocus(false)
  dialog.qty:SetNumeric(true)

  local fl = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fl:SetPoint("TOPLEFT", 18, -98)
  fl:SetText(L["For who:"])
  dialog.forWho = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
  dialog.forWho:SetSize(200, 20)
  dialog.forWho:SetPoint("LEFT", fl, "RIGHT", 10, 0)
  dialog.forWho:SetAutoFocus(false)

  local nl = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  nl:SetPoint("TOPLEFT", 18, -128)
  nl:SetText(L["Note (optional):"])
  dialog.note = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
  dialog.note:SetSize(180, 20)
  dialog.note:SetPoint("LEFT", nl, "RIGHT", 10, 0)
  dialog.note:SetAutoFocus(false)

  dialog.pin = CreateFrame("CheckButton", nil, dialog, "UICheckButtonTemplate")
  dialog.pin:SetSize(22, 22)
  dialog.pin:SetPoint("TOPLEFT", 14, -154)
  dialog.pin.label = dialog.pin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  dialog.pin.label:SetPoint("LEFT", dialog.pin, "RIGHT", 4, 0)
  dialog.pin.label:SetText(L["Pin on screen"])

  local ok = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
  ok:SetSize(96, 22)
  ok:SetPoint("BOTTOMRIGHT", -16, 14)
  ok:SetText(L["Add"])
  ok:SetScript("OnClick", function()
    if dialog.spell then
      Wishlist.Add(dialog.spell, tonumber(dialog.qty:GetText()) or 1,
        dialog.forWho:GetText(), dialog.note:GetText(), dialog.pin:GetChecked(), dialog.crafterKey)
    end
    dialog:Hide()
  end)
  local cancel = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
  cancel:SetSize(96, 22)
  cancel:SetPoint("RIGHT", ok, "LEFT", -8, 0)
  cancel:SetText(L["Cancel"])
  cancel:SetScript("OnClick", function() dialog:Hide() end)
  tinsert(UISpecialFrames, "ComradeCraftWishlistDialog")
end

function Wishlist.ShowDialog(spell, crafterKey)
  if not (ns.Recipes and ns.Recipes[spell]) then return end
  if not dialog then CreateDialog() end
  dialog.spell = spell
  dialog.crafterKey = crafterKey or ns.CharKey()
  local r = ns.Recipes[spell]
  local name = r[5] ~= 0 and ItemName(r[5]) or ns.SpellName(spell)
  dialog.recipe:SetText("|cffffd100" .. name .. "|r")
  dialog.qty:SetText("1")
  dialog.forWho:SetText("")
  dialog.note:SetText("")
  dialog.pin:SetChecked(true)
  dialog:Show()
end

-- Movable On-Screen Pinned Tracker --------------------------------------------------------

local tracker, rows

local function CreateTracker()
  tracker = CreateFrame("Frame", "ComradeCraftWishlistTracker", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  tracker:SetSize(TRACKER_W, 80)
  local pos = Settings().wishlistPos
  if pos then tracker:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3])
  else tracker:SetPoint("RIGHT", UIParent, "RIGHT", -30, -90) end
  tracker:SetFrameStrata("MEDIUM")
  tracker:SetMovable(true)
  tracker:SetClampedToScreen(true)
  tracker:EnableMouse(true)
  tracker:RegisterForDrag("LeftButton")
  tracker:SetScript("OnDragStart", tracker.StartMoving)
  tracker:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    if point then Settings().wishlistPos = { point, x, y } end
  end)
  if tracker.SetBackdrop then
    tracker:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    tracker:SetBackdropColor(0.06, 0.05, 0.04, 0.92)
    tracker:SetBackdropBorderColor(0.8, 0.68, 0.35, 1)
  end
  tracker.logo = tracker:CreateTexture(nil, "ARTWORK")
  tracker.logo:SetSize(14, 14)
  tracker.logo:SetPoint("TOPLEFT", PAD, -9)
  tracker.logo:SetTexture(ns.LOGO)
  tracker.title = tracker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  tracker.title:SetPoint("LEFT", tracker.logo, "RIGHT", 6, 0)
  tracker.title:SetText(L["Wishlist"])
  tracker.close = CreateFrame("Button", nil, tracker, "UIPanelCloseButton")
  tracker.close:SetSize(20, 20)
  tracker.close:SetPoint("TOPRIGHT", -2, -2)
  tracker.close:SetScript("OnClick", function() Wishlist.SetTracker(false) end)
  rows = {}
end

local function CreateTrackerRow()
  local f = CreateFrame("Button", nil, tracker)
  f:SetSize(TRACKER_W - 2 * PAD, 34)
  f:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetSize(22, 22)
  f.icon:SetPoint("TOPLEFT", 0, -4)
  f.done = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.done:SetSize(22, 20)
  f.done:SetPoint("TOPRIGHT", 0, -4)
  f.done:SetText("x")
  f.done:SetScript("OnClick", function(self) if self.id then Wishlist.Remove(self.id) end end)
  f.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.name:SetPoint("TOPLEFT", 26, -2)
  f.name:SetPoint("RIGHT", f.done, "LEFT", -4, 0)
  f.name:SetJustifyH("LEFT")
  f.name:SetWordWrap(false)
  f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  f.sub:SetPoint("TOPLEFT", 26, -16)
  f.sub:SetPoint("RIGHT", f.done, "LEFT", -4, 0)
  f.sub:SetJustifyH("LEFT")
  f.sub:SetWordWrap(false)
  f:SetScript("OnClick", function(self)
    if self.spell and self.own then ns.OpenRecipe(self.spell) end
  end)
  f:SetScript("OnEnter", function(self)
    if not self.entry then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    if self.entry.item and self.entry.item ~= 0 then GameTooltip:SetItemByID(self.entry.item)
    elseif GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.entry.spell) end
    local prog = Wishlist.Progress(self.entry)
    GameTooltip:AddLine(" ")
    if self.entry.forWho then GameTooltip:AddLine(L["For %s"]:format(self.entry.forWho), 1, 0.82, 0) end
    if self.entry.note then GameTooltip:AddLine(self.entry.note, 0.8, 0.8, 0.8, true) end
    for _, m in ipairs(prog.mats) do
      local c = m.missing == 0 and { 0.3, 1, 0.4 } or { 1, 0.82, 0.4 }
      GameTooltip:AddDoubleLine(ItemName(m.item), ("%d / %d"):format(m.have, m.need), 1, 1, 1, c[1], c[2], c[3])
    end
    local convTip = ns.FormatConversionHints and ns.FormatConversionHints(prog.convHints)
    if convTip then GameTooltip:AddLine(convTip, 0.4, 0.8, 1, true) end
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return f
end

function Wishlist.RefreshTracker()
  if not (ComradeCraftDB and ComradeCraftDB.wishlist) then return end
  local pinned = {}
  for _, e in ipairs(DB()) do
    if e.pinned then pinned[#pinned + 1] = e end
  end
  if #pinned == 0 or not Wishlist.TrackerOn() then
    if tracker then tracker:Hide() end
    return
  end
  if not tracker then CreateTracker() end
  for _, r in ipairs(rows) do r:Hide() end
  local me = ns.CharKey()
  local y = -30
  for i = 1, math.min(#pinned, MAX_PINNED) do
    local e = pinned[i]
    local r = rows[i]
    if not r then r = CreateTrackerRow() rows[i] = r end
    local prog = Wishlist.Progress(e)
    local label = e.item ~= 0 and ItemName(e.item) or ns.SpellName(e.spell)
    r.entry, r.spell, r.own, r.done.id = e, e.spell, e.char == me, e.id
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", PAD, y)
    r.icon:SetTexture(ItemIcon(e.item, e.spell))
    local who = e.forWho and (" |cff80ccff(" .. e.forWho .. ")|r") or ""
    r.name:SetText(("%dx %s%s"):format(e.qty, label, who))
    if prog.bagReady then
      local convTxt = ns.FormatConversionHints and ns.FormatConversionHints(prog.convHints)
      r.sub:SetText(convTxt and ("|cff66ccff" .. convTxt .. "|r") or ("|cff40ff40" .. L["Ready to craft!"] .. "|r"))
    elseif prog.ready then
      r.sub:SetText("|cffffd100" .. L["Ready (some mats in bank/mail)"] .. "|r")
    else
      local parts = {}
      for j = 1, math.min(#prog.mats, 2) do
        local m = prog.mats[j]
        if m.missing > 0 then parts[#parts + 1] = ("%s %d/%d"):format(ItemName(m.item), m.have, m.need) end
      end
      r.sub:SetText(table.concat(parts, ", "))
    end
    r:Show()
    y = y - 36
  end
  tracker:SetHeight(-y + 8)
  tracker:Show()
end

ns.On("PLAYER_LOGIN", function()
  if C_Timer then C_Timer.After(4, Wishlist.RefreshTracker) else Wishlist.RefreshTracker() end
end)
