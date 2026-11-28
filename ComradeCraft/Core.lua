-- Core: events, SavedVariables, slash command.
local ADDON, ns = ...
ns.name = ADDON
ns.LOGO = "Interface\\AddOns\\ComradeCraft\\Media\\Logo" -- 64x64 TGA (minimap, window, addon list)

local frame = CreateFrame("Frame")
ns.frame = frame

local LOG_MAX = 2000 -- lines kept in ComradeCraftDB.log (oldest dropped)

-- Appends a plain-text line to the SavedVariables log (written to disk on /reload or logout).
local function Log(line)
  if not ComradeCraftDB then return end
  local log = ComradeCraftDB.log
  if not log then
    log = {}
    ComradeCraftDB.log = log
  end
  local plain = tostring(line):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  log[#log + 1] = date("%Y-%m-%d %H:%M:%S") .. " " .. plain
  if #log > LOG_MAX then table.remove(log, 1) end
end
ns.Log = Log

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37ComradeCraft|r " .. tostring(msg))
  Log(msg)
end
ns.Print = Print

-- Localized profession display name for a skillLine (translates peers using another WoW client language).
local PROF_SPELLS = {
  [164] = 2018, [165] = 2108, [171] = 2259, [182] = 2366, [185] = 2550, [186] = 2575,
  [197] = 3908, [202] = 4036, [333] = 7411, [356] = 7620, [393] = 8613, [129] = 3273,
}
local profNameCache = {}
function ns.ProfName(line, fallback)
  if line then
    local cached = profNameCache[line]
    if cached then return cached end
    local T = C_TradeSkillUI
    if T and T.GetTradeSkillDisplayName then
      local ok, n = pcall(T.GetTradeSkillDisplayName, line)
      if ok and type(n) == "string" and n ~= "" then profNameCache[line] = n return n end
    end
    local sp = PROF_SPELLS[line]
    if sp then
      local n = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(sp))
        or (GetSpellInfo and GetSpellInfo(sp))
      if type(n) == "string" and n ~= "" then profNameCache[line] = n return n end
    end
  end
  return fallback or (line and ("#" .. tostring(line)) or "?")
end

-- Keybinding labels (used by Bindings.xml in WoW's Key Bindings UI).
BINDING_HEADER_COMRADECRAFT = "ComradeCraft"
BINDING_NAME_COMRADECRAFT_TOGGLE = ns.L["Toggle ComradeCraft"]
function ComradeCraft_Toggle()
  if ns.ToggleWindow then ns.ToggleWindow() end
end

-- Addon Compartment callbacks (minimap dropdown menu).
function ComradeCraft_OnAddonCompartmentClick(_, btn)
  if btn == "RightButton" and ns.OpenOptions then ns.OpenOptions()
  elseif ns.ToggleWindow then ns.ToggleWindow() end
end
function ComradeCraft_OnAddonCompartmentEnter(_, menuBtn)
  if not GameTooltip then return end
  GameTooltip:SetOwner(menuBtn or UIParent, "ANCHOR_LEFT")
  GameTooltip:AddLine("ComradeCraft", 1, 0.82, 0)
  if ns.MinimapSummary then ns.MinimapSummary(GameTooltip) end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine(ns.L["Left-click: open window  |  Right-click: options"], 0.8, 0.8, 0.8)
  GameTooltip:Show()
end
function ComradeCraft_OnAddonCompartmentLeave()
  if GameTooltip then GameTooltip:Hide() end
end

-- Subtle Blizzard sound notifications (configurable in Options).
local SOUNDS = {
  lock = function() return SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856 end,
  unlock = function() return SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or 857 end,
  request = function() return SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081 end,
  ready = function() return SOUNDKIT and SOUNDKIT.READY_CHECK or 8960 end,
  shipped = function() return SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE or 878 end,
}
function ns.PlaySound(kind)
  if ComradeCraftDB and ComradeCraftDB.settings and ComradeCraftDB.settings.sounds == false then return end
  if not PlaySound then return end
  local fn = SOUNDS[kind]
  local id = fn and fn()
  if id then pcall(PlaySound, id, "Master") end
end

-- Per-companion-panel enable/disable setting (default: all enabled).
function ns.PanelEnabled(name)
  local s = ComradeCraftDB and ComradeCraftDB.settings
  local p = s and s.panels
  return not (p and p[name] == false)
end

function ns.SetPanelEnabled(name, on)
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  ComradeCraftDB.settings.panels = ComradeCraftDB.settings.panels or {}
  ComradeCraftDB.settings.panels[name] = on and true or false
  if ns.Mail and ns.Mail.UpdatePanel then ns.Mail.UpdatePanel() end
  if ns.Bank and ns.Bank.UpdatePanel then ns.Bank.UpdatePanel() end
  if ns.Trade and ns.Trade.UpdatePanel then ns.Trade.UpdatePanel() end
  if ns.Merchant and ns.Merchant.UpdatePanel then ns.Merchant.UpdatePanel() end
  if ns.Trainer and ns.Trainer.UpdatePanel then ns.Trainer.UpdatePanel() end
  if ns.AuctionPanel and ns.AuctionPanel.UpdatePanel then ns.AuctionPanel.UpdatePanel() end
end

-- Main window UI scale (0.75 to 1.25).
function ns.UIScale()
  local v = ComradeCraftDB and ComradeCraftDB.settings and tonumber(ComradeCraftDB.settings.uiScale)
  return (v and v >= 0.75 and v <= 1.25) and v or 1.0
end

function ns.SetUIScale(v)
  v = math.max(0.75, math.min(1.25, math.floor((tonumber(v) or 1) * 20 + 0.5) / 20))
  ComradeCraftDB.settings = ComradeCraftDB.settings or {}
  ComradeCraftDB.settings.uiScale = v
  if ComradeCraftFrame and ComradeCraftFrame.SetScale then ComradeCraftFrame:SetScale(v) end
  return v
end

-- Resets main window and all movable trackers back to their default on-screen positions.
function ns.ResetPositions()
  if ComradeCraftDB then
    if ComradeCraftDB.ui then ComradeCraftDB.ui.pos = nil ComradeCraftDB.ui.height = nil end
    if ComradeCraftDB.settings then
      ComradeCraftDB.settings.trackerPos = nil
      ComradeCraftDB.settings.wishlistPos = nil
      ComradeCraftDB.settings.farmPos = nil
    end
  end
  if ComradeCraftFrame then
    ComradeCraftFrame:ClearAllPoints()
    ComradeCraftFrame:SetPoint("CENTER")
    if ComradeCraftFrame.SetHeight then ComradeCraftFrame:SetHeight(560) end
  end
  if ns.SetTracker then ns.SetTracker(nil, true) end
  if ns.Wishlist and ns.Wishlist.RefreshTracker then ns.Wishlist.RefreshTracker() end
  Print(ns.L["All window and tracker positions reset."])
end

-- Shares a short summary line to guild chat (/g), party (/p), or opens the chat input box
-- pre-filled when solo. Never exceeds WoW's 255-byte chat message limit.
function ns.ShareChat(text)
  if type(text) ~= "string" or text == "" then return false end
  local msg = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  if #msg > 240 then msg = msg:sub(1, 237) .. "..." end
  local inGuild = IsInGuild and IsInGuild()
  local inGroup = IsInGroup and IsInGroup()
  local wantParty = inGroup and (not inGuild or (IsShiftKeyDown and IsShiftKeyDown()))
  if SendChatMessage and (wantParty or inGuild) then
    local chan = wantParty and ((IsInRaid and IsInRaid()) and "RAID" or "PARTY") or "GUILD"
    SendChatMessage(msg, chan)
    return chan
  end
  if ChatEdit_ChooseBoxForSend and ChatEdit_ActivateChat then
    local box = ChatEdit_ChooseBoxForSend()
    if box then
      ChatEdit_ActivateChat(box)
      box:SetText(msg)
      return "EDITBOX"
    end
  end
  Print(msg)
  return "PRINT"
end

local function NormRealm(r)
  return type(r) == "string" and r:gsub("[%s%-']", ""):lower() or ""
end

local function NameSeparator()
  local c = type(Constants) == "table" and Constants.CharacterNameSeparatorConsts or nil
  local s = type(c) == "table" and c.CHARACTERNAME_SURNAME_SEPARATOR or nil
  return (type(s) == "string" and s ~= "") and s or " "
end

-- True on WoW Forever (two-part character names: "First Surname").
function ns.TwoPartNames()
  if type(RegionalUniqueNamesEnabled) == "function" then
    local ok, v = pcall(RegionalUniqueNamesEnabled)
    if ok and v == true then return true end
  end
  if type(Constants) == "table" and type(Constants.CharacterNameSeparatorConsts) == "table" then
    return true
  end
  if type(GetBuildInfo) == "function" then
    local iface = select(4, GetBuildInfo())
    if type(iface) == "number" and iface >= 16000 and iface < 20000 then return true end
  end
  return false
end

local function JoinSurname(first, surname)
  if type(first) ~= "string" or first == "" then return first end
  if type(surname) ~= "string" or surname == "" then return first end
  local sep = NameSeparator()
  local tail = sep .. surname
  if #first > #tail and first:sub(-#tail) == tail then return first end
  return first .. tail
end

-- Full character name of `unit`: on WoW Forever joins First + Surname ("Jhf Mage"),
-- never silently dropping the 2nd return value of UnitNameUnmodified / UnitName.
function ns.UnitFullName(unit)
  unit = unit or "player"
  if not UnitName then return nil end
  local function Safe(v)
    if v == nil or (issecretvalue and issecretvalue(v)) then return nil end
    return v
  end
  if not ns.TwoPartNames() then
    return Safe(UnitName(unit))
  end
  local fn = type(UnitNameUnmodified) == "function" and UnitNameUnmodified or UnitName
  local a, b = fn(unit)
  a, b = Safe(a), Safe(b)
  local full = JoinSurname(a, b)
  if type(full) == "string" and not full:find(NameSeparator(), 1, true) and fn ~= UnitName then
    local a2, b2 = UnitName(unit)
    local other = JoinSurname(Safe(a2), Safe(b2))
    if type(other) == "string" and other:find(NameSeparator(), 1, true) then full = other end
  end
  return full
end

local cachedRealm
local function IsBogusSurnameRealm(r, fullName)
  if type(r) ~= "string" or r == "" or type(fullName) ~= "string" then return false end
  local surname = fullName:match("%s+(%S+)$")
  return surname ~= nil and NormRealm(r) == NormRealm(surname)
end

-- Remembers a seen two-part Forever name ("First Last") so legacy 1-word peer keys auto-resolve.
function ns.RememberFullName(full)
  if type(full) ~= "string" or not ComradeCraftDB then return end
  local clean = (full:match("^[^-]+") or full):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
  if not clean:find(" ", 1, true) then return end
  local first = clean:match("^%S+")
  if not (first and #first >= 2) then return end
  ComradeCraftDB.fullNames = ComradeCraftDB.fullNames or {}
  ComradeCraftDB.fullNames[first:lower()] = clean
end

-- Resolves a unique "First Surname" for a bare first name across remembered names, peers,
-- guild roster, friends list, party/raid, inbox, and Postbox recipient history.
function ns.ResolveFullName(firstName)
  if type(firstName) ~= "string" or firstName == "" then return nil end
  if firstName:find(" ", 1, true) then return firstName end
  local target = firstName:lower()
  local saved = ComradeCraftDB and ComradeCraftDB.fullNames and ComradeCraftDB.fullNames[target]
  if type(saved) == "string" and saved:find(" ", 1, true) then return saved end
  local match
  local function Consider(full)
    if type(full) ~= "string" then return end
    local clean = (full:match("^[^-]+") or full):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if not clean:find(" ", 1, true) then return end
    local first = clean:match("^%S+")
    if first and first:lower() == target then
      if match == nil then match = clean
      elseif match and match:lower() ~= clean:lower() then match = false end
    end
  end
  Consider(ns.UnitFullName("player"))
  if ComradeCraftDB then
    for k in pairs(ComradeCraftDB.chars or {}) do Consider(k) end
    for k in pairs(ComradeCraftDB.remote or {}) do Consider(k) end
    for _, p in pairs(ComradeCraftDB.peers or {}) do
      if p and p.name then Consider(p.name) end
    end
  end
  if IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo then
    for i = 1, (GetNumGuildMembers() or 0) do
      local gname = GetGuildRosterInfo(i)
      if gname then Consider(gname) end
    end
  end
  if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
    for i = 1, (C_FriendList.GetNumFriends() or 0) do
      local info = C_FriendList.GetFriendInfoByIndex(i)
      if info and info.name then Consider(info.name) end
    end
  end
  if IsInGroup and IsInGroup() then
    local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
    local prefix = (IsInRaid and IsInRaid()) and "raid" or "party"
    for i = 1, math.min(n, 40) do Consider(ns.UnitFullName(prefix .. i)) end
  end
  if GetInboxNumItems and GetInboxHeaderInfo then
    for i = 1, math.min(GetInboxNumItems() or 0, 50) do
      local _, _, sender = GetInboxHeaderInfo(i)
      if sender then Consider(sender) end
    end
  end
  if type(_G.PostboxDB) == "table" then
    local function ScanHist(tbl)
      if type(tbl) ~= "table" then return end
      if type(tbl.recipientHistory) == "table" then
        for _, n in ipairs(tbl.recipientHistory) do Consider(n) end
      end
    end
    ScanHist(_G.PostboxDB)
    for _, v in pairs(_G.PostboxDB) do
      if type(v) == "table" then
        ScanHist(v)
        for _, v2 in pairs(v) do ScanHist(v2) end
      end
    end
  end
  if match then ns.RememberFullName(match) end
  return match or nil
end

local function RealmName()
  local name = ns.UnitFullName("player")
  local r = GetRealmName and GetRealmName()
  if type(r) == "string" and r ~= "" and not IsBogusSurnameRealm(r, name) then
    cachedRealm = r
    return r
  end
  if GetCVar then
    local cr = GetCVar("realmName")
    if type(cr) == "string" and cr ~= "" and not IsBogusSurnameRealm(cr, name) then
      cachedRealm = cr
      return cr
    end
  end
  if name and name ~= "" and ComradeCraftDB and ComradeCraftDB.chars then
    local prefix = name .. "-"
    local bestR
    for k in pairs(ComradeCraftDB.chars) do
      if k:sub(1, #prefix) == prefix and #k > #prefix then
        local cand = k:sub(#prefix + 1)
        if not IsBogusSurnameRealm(cand, name) and (not bestR or #cand > #bestR) then bestR = cand end
      end
    end
    if bestR then
      cachedRealm = bestR
      return cachedRealm
    end
  end
  if cachedRealm and not IsBogusSurnameRealm(cachedRealm, name) then return cachedRealm end
  if not ns.TwoPartNames() and UnitFullName then
    local _, ur = UnitFullName("player")
    if type(ur) == "string" and ur ~= "" then
      cachedRealm = ur
      return ur
    end
  end
  r = GetNormalizedRealmName and GetNormalizedRealmName()
  if type(r) == "string" and r ~= "" and not IsBogusSurnameRealm(r, name) then
    cachedRealm = r
    return r
  end
  -- Forever can give no usable realm on a new character: reuse the realm of this account's
  -- latest character, or the character would never be saved.
  if ns.TwoPartNames() and ComradeCraftDB and ComradeCraftDB.chars then
    local best, bestU
    for k, ch in pairs(ComradeCraftDB.chars) do
      local kr = k:match("^[^-]+%-(.+)$")
      local u = type(ch) == "table" and ch.updated or 0
      if kr and not IsBogusSurnameRealm(kr, name) and (not bestU or u > bestU) then best, bestU = kr, u end
    end
    if best then
      cachedRealm = best
      return best
    end
  end
  return nil
end
function ns.ResetRealmCache() cachedRealm = nil end -- tests only

function ns.CharKey()
  local name = ns.UnitFullName("player") or ""
  local realm = RealmName()
  return realm and (name .. "-" .. realm) or name
end

-- True when two character keys refer to the same character (ignoring realm spacing/punctuation,
-- Forever regionally-unique "First Last" realm spelling variants, and legacy 1-word -> 2-word
-- upgrades when optional character records confirm the same class).
function ns.IsSameChar(k1, k2, c1, c2)
  if not (k1 and k2) then return false end
  if k1 == k2 then return true end
  local b1, r1 = k1:match("^([^-]+)-(.*)$")
  local b2, r2 = k2:match("^([^-]+)-(.*)$")
  b1 = (b1 or k1):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " "):lower()
  b2 = (b2 or k2):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " "):lower()
  if b1 == "" or b2 == "" then return false end
  local nr1, nr2 = NormRealm(r1), NormRealm(r2)
  local sameRealm = nr1 == nr2 or nr1 == "" or nr2 == ""
  if b1 == b2 then
    -- On WoW Forever, two-part names ("First Last") are regionally unique regardless of realm alias.
    if sameRealm or (ns.TwoPartNames() and b1:find(" ", 1, true)) then return true end
    return false
  end
  if ns.TwoPartNames() and sameRealm and c1 and c2 and c1.class and c2.class and c1.class == c2.class then
    local f1, hasSp1 = b1:match("^%S+"), b1:find(" ", 1, true) ~= nil
    local f2, hasSp2 = b2:match("^%S+"), b2:find(" ", 1, true) ~= nil
    if f1 and f1 == f2 and hasSp1 ~= hasSp2 then return true end
  end
  return false
end

local function MergeCharRecords(dst, src)
  if not (dst and src) or dst == src then return dst end
  if src.shared then dst.shared = true end
  if src.listed then dst.listed = true end
  if src.bankAlt then dst.bankAlt = true end
  if src.specOverride and not dst.specOverride then dst.specOverride = src.specOverride end
  if src.bank and next(src.bank) and not (dst.bank and next(dst.bank)) then dst.bank = src.bank end
  if src.mail and next(src.mail) and not (dst.mail and next(dst.mail)) then dst.mail = src.mail end
  if src.professions and next(src.professions) and not (dst.professions and next(dst.professions)) then
    dst.professions = src.professions
  end
  dst.known = dst.known or {}
  for line, set in pairs(src.known or {}) do
    if not dst.known[line] then dst.known[line] = set end
  end
  return dst
end

-- A character key after renames (Forever "First" -> "First Last"), for data still using the old one.
function ns.RenamedKey(key)
  local map = ComradeCraftDB and ComradeCraftDB.renamed
  for _ = 1, 5 do
    local nk = map and key and map[key]
    if not nk or nk == key then break end
    key = nk
  end
  return key
end

-- Moves everything stored under a character key to its new key, and remembers the rename so
-- data arriving later with the old key (requests, reservations, mail) lands on the new one.
local function RebindKeyRefs(oldKey, newKey)
  if not (ComradeCraftDB and oldKey and newKey and oldKey ~= newKey) then return end
  ComradeCraftDB.renamed = ComradeCraftDB.renamed or {}
  ComradeCraftDB.renamed[oldKey] = newKey
  if ComradeCraftDB.renamed[newKey] == oldKey then ComradeCraftDB.renamed[newKey] = nil end
  for _, r in pairs(ComradeCraftDB.requests or {}) do
    if type(r) == "table" then
      if r.from == oldKey then r.from = newKey end
      if r.to == oldKey then r.to = newKey end
      if r.deliverTo == oldKey then r.deliverTo = newKey end
    end
  end
  for _, store in ipairs({ ComradeCraftDB.chars or {}, ComradeCraftDB.remote or {} }) do
    for _, ch in pairs(store) do
      if type(ch) == "table" then
        for _, rv in pairs(ch.reserved or {}) do if rv.to == oldKey then rv.to = newKey end end
        for _, e in ipairs(ch.inTransit or {}) do if e.to == oldKey then e.to = newKey end end
      end
    end
  end
  local lists = ComradeCraftDB.shopLists
  if lists then
    local moves = {}
    for slot, name in pairs(lists) do
      local line = slot:sub(1, #oldKey + 1) == oldKey .. ":" and slot:sub(#oldKey + 2)
      if line then moves[slot] = { newKey .. ":" .. line, name } end
    end
    for slot, m in pairs(moves) do lists[slot], lists[m[1]] = nil, m[2] end
  end
  if ComradeCraftDB.ui and ComradeCraftDB.ui.sel == oldKey then ComradeCraftDB.ui.sel = newKey end
  local budgets = ComradeCraftDB.budgets
  if budgets and budgets[oldKey] then budgets[newKey], budgets[oldKey] = budgets[newKey] or budgets[oldKey], nil end
  if ComradeCraftDB.favorites and ComradeCraftDB.favorites[oldKey] then
    ComradeCraftDB.favorites[newKey] = true
    ComradeCraftDB.favorites[oldKey] = nil
  end
  for _, e in ipairs(ComradeCraftDB.wishlist or {}) do
    if e.char == oldKey then e.char = newKey end
  end
  for _, a in pairs(ComradeCraftDB.farm or {}) do
    if a.char == oldKey then a.char = newKey end
  end
end
ns.RebindKeyRefs = RebindKeyRefs

-- Merges broken "Name-" keys, realm-alias duplicates, legacy 1-word Forever keys (even when
-- multiple alts share a first name, using class disambiguation), and purges stale remote copies
-- of local characters so you never see yourself twice.
local function CleanBrokenCharKeys()
  local chars = ComradeCraftDB and ComradeCraftDB.chars
  if not chars then return end
  local realm = RealmName()
  local aliases = {}
  local function AddAlias(v)
    local nr = NormRealm(v)
    if nr ~= "" then aliases[nr] = true end
  end
  AddAlias(realm)
  if GetRealmName then AddAlias(GetRealmName()) end
  if GetNormalizedRealmName then AddAlias(GetNormalizedRealmName()) end
  if GetCVar then AddAlias(GetCVar("realmName")) end
  if not ns.TwoPartNames() and UnitFullName then local _, ur = UnitFullName("player") AddAlias(ur) end
  local normCur = NormRealm(realm)
  local twoPart = ns.TwoPartNames()
  local groups = {}
  for key in pairs(chars) do
    local bare, r = key:match("^([^-]+)-(.*)$")
    if not bare then bare, r = key, "" end
    local cleanBare = bare:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    local surname = cleanBare:match("%s+(%S+)$")
    local nr = NormRealm(r)
    -- Also repair Forever keys where surname was mistaken for realm ("Jhf Mage-Mage"),
    -- and unify Forever regionally-unique two-part names across realm spelling variants.
    local bogusSurname = surname and nr ~= "" and nr == NormRealm(surname)
    if (nr == "" or aliases[nr] or bogusSurname or (twoPart and surname ~= nil)) and normCur ~= "" then
      nr = normCur
    end
    if cleanBare ~= "" and nr ~= "" then
      local gkey = cleanBare:lower() .. "|" .. nr
      groups[gkey] = groups[gkey] or {}
      table.insert(groups[gkey], key)
    end
  end
  local moved = false
  for _, list in pairs(groups) do
    if #list > 1 or list[1]:match("-$") or not list[1]:find("-", 1, true) then
      local canonical
      for _, k in ipairs(list) do
        if realm and k:sub(-#realm - 1) == "-" .. realm then canonical = k break end
      end
      if not canonical then
        for _, k in ipairs(list) do
          if k:find("-", 1, true) and not k:match("-$") and (not canonical or #k > #canonical) then canonical = k end
        end
      end
      if not canonical and realm then
        canonical = (list[1]:match("^([^-]+)") or list[1]) .. "-" .. realm
      end
      if canonical then
        local best, bestU, bestLv = nil, -1, -1
        for _, k in ipairs(list) do
          local v = chars[k]
          if v then
            local u, lv = v.updated or 0, v.level or 0
            if u > bestU or (u == bestU and lv > bestLv) then best, bestU, bestLv = v, u, lv end
          end
        end
        if best then
          for _, k in ipairs(list) do
            if chars[k] and chars[k] ~= best then MergeCharRecords(best, chars[k]) end
          end
          chars[canonical] = best
          for _, k in ipairs(list) do
            if k ~= canonical then
              chars[k] = nil
              RebindKeyRefs(k, canonical)
              moved = true
            end
          end
          if ns.UpdateNeeds then ns.UpdateNeeds(best) end
        end
      end
    end
  end
  -- Forever migration: upgrade legacy first-name-only keys ("Mirandaa-<realm>", "Jhf-<realm>")
  -- to full two-part names using current player, existing 2-word chars, guild roster & friends list.
  -- Uses class disambiguation too so "Jhf" (MAGE) merges into "Jhf Mage" even when "Jhf Priest" exists!
  if realm and twoPart then
    local byFirst, byFirstClass = {}, {}
    local function RegisterFull(full, cls)
      if type(full) ~= "string" then return end
      local clean = (full:match("^[^-]+") or full):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
      if not clean:find(" ", 1, true) then return end
      local first = clean:match("^%S+")
      local fl = first and first:lower()
      if not fl then return end
      if byFirst[fl] == nil then byFirst[fl] = clean
      elseif byFirst[fl] and byFirst[fl]:lower() ~= clean:lower() then byFirst[fl] = false end
      if type(cls) == "string" and cls ~= "" then
        local fc = fl .. "|" .. cls
        if byFirstClass[fc] == nil then byFirstClass[fc] = clean
        elseif byFirstClass[fc] and byFirstClass[fc]:lower() ~= clean:lower() then byFirstClass[fc] = false end
      end
    end
    local _, playerCls = UnitClass and UnitClass("player")
    RegisterFull(ns.UnitFullName("player"), playerCls)
    for k, ch in pairs(chars) do
      if type(ch) == "table" then RegisterFull(k, ch.class) end
    end
    if IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo then
      for i = 1, (GetNumGuildMembers() or 0) do
        local gname, _, _, _, _, _, _, _, _, _, gcls = GetGuildRosterInfo(i)
        if gname then RegisterFull(gname, gcls) end
      end
    end
    if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
      for i = 1, (C_FriendList.GetNumFriends() or 0) do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name then RegisterFull(info.name) end
      end
    end
    local toMove = {}
    for key, ch in pairs(chars) do
      local bare, r = key:match("^([^-]+)-(.*)$")
      if bare and not bare:find(" ", 1, true) then
        local fl = bare:lower()
        local full = (ch and ch.class and byFirstClass[fl .. "|" .. ch.class]) or byFirst[fl]
        if full and r and r ~= "" then
          toMove[#toMove + 1] = { oldKey = key, newKey = full .. "-" .. realm }
        end
      end
    end
    for _, m in ipairs(toMove) do
      local oldC, newC = chars[m.oldKey], chars[m.newKey]
      if oldC and m.oldKey ~= m.newKey then
        if not newC then
          chars[m.newKey] = oldC
        else
          local keep = ((newC.updated or 0) >= (oldC.updated or 0)) and newC or oldC
          local drop = keep == newC and oldC or newC
          MergeCharRecords(keep, drop)
          chars[m.newKey] = keep
        end
        chars[m.oldKey] = nil
        RebindKeyRefs(m.oldKey, m.newKey)
        moved = true
      end
    end
  end
  -- Purge any stale remote copies of our own local characters (e.g. relayed via Mesh Sync under a
  -- legacy 1-word key or realm alias) so you never appear twice in the group list.
  if ComradeCraftDB.remote then
    for rKey, rRec in pairs(ComradeCraftDB.remote) do
      for lKey, lRec in pairs(chars) do
        if ns.IsSameChar(rKey, lKey, rRec, lRec) then
          ComradeCraftDB.remote[rKey] = nil
          moved = true
          break
        end
      end
    end
  end
  if moved and ns.RequestRefresh then ns.RequestRefresh() end
end

-- Returns (and creates) the SavedVariables entry for the current character.
local scratchChar = {}
function ns.CharData()
  local realm = RealmName()
  local name = ns.UnitFullName("player")
  if not realm or type(name) ~= "string" or name == "" or name == "Unknown" or name == UNKNOWNOBJECT then
    return scratchChar
  end
  local _, class = UnitClass("player")
  local key = name .. "-" .. realm
  -- On Forever, if surname hasn't populated yet on a super-early login event, reuse the existing
  -- 2-word entry for this first name + class instead of creating a duplicate 1-word entry.
  if ns.TwoPartNames() and not name:find(" ", 1, true) and class and ComradeCraftDB and ComradeCraftDB.chars then
    local fl = name:lower()
    local matchKey
    for k, ch in pairs(ComradeCraftDB.chars) do
      local bare = (k:match("^[^-]+") or k):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
      if bare:find(" ", 1, true) and (bare:match("^%S+") or ""):lower() == fl and ch and ch.class == class then
        if matchKey == nil then matchKey = k else matchKey = false break end
      end
    end
    if matchKey then key = matchKey end
  end
  local c = ComradeCraftDB.chars[key]
  if not c then
    c = {}
    if ComradeCraftDB.settings and ComradeCraftDB.settings.autoShareNew then c.shared = true end
    ComradeCraftDB.chars[key] = c
  end
  c.class = class
  c.level = UnitLevel and UnitLevel("player") or c.level
  return c
end

-- Every character the group views show: this account's characters plus the ones received
-- from peers the player included (Sync.lua). Local characters always win on a key clash,
-- and any residual duplicates (realm spelling or 1-word/2-word Forever variants) are collapsed
-- so a character — especially the active player — can never appear twice.
function ns.AllChars()
  local all = {}
  local db = ComradeCraftDB
  if not db then return all end
  local meKey = ns.CharKey()
  local localList = {}
  -- Active character first so it always wins any dedup tie.
  local keys = {}
  for key in pairs(db.chars or {}) do keys[#keys + 1] = key end
  table.sort(keys, function(a, b)
    if (a == meKey) ~= (b == meKey) then return a == meKey end
    local ca, cb = db.chars[a], db.chars[b]
    local ua, ub = (ca and ca.updated) or 0, (cb and cb.updated) or 0
    if ua ~= ub then return ua > ub end
    return a < b
  end)
  for _, key in ipairs(keys) do
    local c = db.chars[key]
    local dup = false
    for i = 1, #localList do
      if ns.IsSameChar(key, localList[i].key, c, localList[i].rec) then dup = true break end
    end
    if not dup then
      all[key] = c
      localList[#localList + 1] = { key = key, rec = c }
    end
  end
  local remoteKeys = {}
  for key in pairs(db.remote or {}) do remoteKeys[#remoteKeys + 1] = key end
  table.sort(remoteKeys, function(a, b)
    local ra, rb = db.remote[a], db.remote[b]
    local ua, ub = (ra and ra.updated) or 0, (rb and rb.updated) or 0
    if ua ~= ub then return ua > ub end
    return a < b
  end)
  local addedRemote = {}
  for _, key in ipairs(remoteKeys) do
    local rec = db.remote[key]
    local peer = rec and db.peers and db.peers[rec.peer]
    if peer and peer.included and not all[key] then
      local dup = false
      for i = 1, #localList do
        if ns.IsSameChar(key, localList[i].key, rec, localList[i].rec) then dup = true break end
      end
      if not dup then
        for i = 1, #addedRemote do
          if ns.IsSameChar(key, addedRemote[i].key, rec, addedRemote[i].rec) then dup = true break end
        end
      end
      if not dup then
        all[key] = rec
        addedRemote[#addedRemote + 1] = { key = key, rec = rec }
      end
    end
  end
  return all
end

local handlers = {}
ns.handlers = handlers

function handlers.ADDON_LOADED(name)
  if name ~= ADDON then return end
  ComradeCraftDB = ComradeCraftDB or {}
  ComradeCraftDB.version = 1
  ComradeCraftDB.chars = ComradeCraftDB.chars or {}
  CleanBrokenCharKeys()
  frame:UnregisterEvent("ADDON_LOADED")
end

frame:SetScript("OnEvent", function(_, event, ...)
  local h = handlers[event]
  if h then h(...) end
end)
frame:RegisterEvent("ADDON_LOADED")

-- Lets other files register events: ns.On("EVENT", fn)
-- Events missing on this client are skipped (RegisterEvent errors on unknown events).
local PLAYER_ONLY = { UNIT_SPELLCAST_SUCCEEDED = true, UNIT_SPELLCAST_START = true } -- all handlers want "player"
function ns.On(event, fn)
  local prev = handlers[event]
  handlers[event] = prev and function(...) prev(...) fn(...) end or fn
  if not (PLAYER_ONLY[event] and frame.RegisterUnitEvent and pcall(frame.RegisterUnitEvent, frame, event, "player")) then
    pcall(frame.RegisterEvent, frame, event)
  end
end

ns.On("PLAYER_LOGIN", function()
  CleanBrokenCharKeys()
  if IsInGuild and IsInGuild() and C_GuildInfo and C_GuildInfo.GuildRoster then
    pcall(C_GuildInfo.GuildRoster)
  end
end)
ns.On("PLAYER_ENTERING_WORLD", CleanBrokenCharKeys)
ns.On("GUILD_ROSTER_UPDATE", CleanBrokenCharKeys)
ns.On("FRIENDLIST_UPDATE", CleanBrokenCharKeys)

-- Favorite characters / preferred crafters (float to top of sidebar, directory, and Upgrades ties).
function ns.IsFavorite(key)
  return key ~= nil and ComradeCraftDB and ComradeCraftDB.favorites and ComradeCraftDB.favorites[key] == true or false
end

function ns.ToggleFavorite(key)
  if not (key and ComradeCraftDB) then return false end
  ComradeCraftDB.favorites = ComradeCraftDB.favorites or {}
  local on = not ComradeCraftDB.favorites[key]
  ComradeCraftDB.favorites[key] = on or nil
  if ns.Audit and ns.Audit.Invalidate then ns.Audit.Invalidate() end
  if ns.Directory and ns.Directory.Invalidate then ns.Directory.Invalidate() end
  if ns.RefreshWindow then ns.RefreshWindow() end
  return on
end

-- Recomputes the current character's needs and redraws the window, coalesced: a burst
-- of events (Create All, looting) triggers one recompute 0.3 s after the last one.
-- Defers heavy recomputation while in combat so mid-fight looting/consumables cause zero spikes.
local refreshPending, combatRefreshPending = false, false
function ns.RequestRefresh()
  if InCombatLockdown and InCombatLockdown() then
    combatRefreshPending = true
    return
  end
  if refreshPending then return end
  local function run()
    refreshPending = false
    if InCombatLockdown and InCombatLockdown() then
      combatRefreshPending = true
      return
    end
    if ns.Audit and ns.Audit.Invalidate then ns.Audit.Invalidate() end
    if ns.ClearGiveCache then ns.ClearGiveCache() end
    if ns.PruneInTransit then ns.PruneInTransit() end
    if ns.Reserve and ns.Reserve.Prune then ns.Reserve.Prune() end
    if ComradeCraftDB and ComradeCraftDB.chars then ns.UpdateNeeds(ns.CharData()) end
    if ns.Alerts then ns.Alerts.CheckMats() end
    if ns.Wishlist then ns.Wishlist.CheckReady() ns.Wishlist.RefreshTracker() end
    if ns.RefreshFarm then ns.RefreshFarm() end -- farming tracker + completed assignments
    if ns.RefreshWindow then ns.RefreshWindow() end
    if ns.UpdateLDB then ns.UpdateLDB() end
    if ns.RefreshTracker then ns.RefreshTracker() end
    if ns.Bags and ns.Bags.Refresh then ns.Bags.Refresh() end
    if ns.Merchant and ns.Merchant.UpdatePanel then ns.Merchant.UpdatePanel() end
    if ns.Bank and ns.Bank.UpdatePanel then ns.Bank.UpdatePanel() end
    if ns.AuctionPanel and ns.AuctionPanel.UpdatePanel then ns.AuctionPanel.UpdatePanel() end
    if ns.Mail and ns.Mail.UpdatePanel then ns.Mail.UpdatePanel() end
    if ns.Trade and ns.Trade.UpdatePanel then ns.Trade.UpdatePanel() end
    if ns.Sync then ns.Sync.MarkDirty() end -- peers hear about the change (debounced)
    if ns.Directory then ns.Directory.MarkDirty() end -- guild directory: ranks and recipes only
  end
  if C_Timer and C_Timer.After then
    refreshPending = true
    C_Timer.After(0.3, run)
  else
    run()
  end
end
ns.On("PLAYER_REGEN_ENABLED", function()
  if combatRefreshPending then
    combatRefreshPending = false
    ns.RequestRefresh()
  end
end)

local commands = {}
ns.commands = commands

SLASH_COMRADECRAFT1 = "/comrade"
SlashCmdList.COMRADECRAFT = function(msg)
  local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  cmd = cmd:lower()
  local fn = commands[cmd == "" and "show" or cmd]
  if fn then
    Log("> /comrade " .. (msg or ""))
    -- Errors are logged with their stack, then re-raised so BugSack still shows them.
    local ok, err = xpcall(function() fn(rest) end, function(e)
      return tostring(e) .. "\n" .. (debugstack and debugstack(2) or "")
    end)
    if not ok then
      Log("ERROR " .. err)
      error(err, 0)
    end
  else
    Print(ns.L["commands: /comrade (window) | share [off] | list [off] | directory [text] | add NAME | remove NAME | peers | sync | guildping [off] | shop [profession] | tracker [reset] | mail NAME | scan | needs | stats | api | audit | log clear"])
  end
end

commands.log = function(rest)
  if rest == "clear" then
    ComradeCraftDB.log = {}
    Print(ns.L["log cleared"])
  else
    Print(ns.L["%d lines in the log (written to disk on /reload or logout)"]:format(
      #(ComradeCraftDB.log or {})))
  end
end

commands.scale = function(rest)
  local v = tonumber(rest)
  if not v then
    Print(ns.L["Window scale"] .. ": " .. ("%d%%"):format(math.floor(ns.UIScale() * 100 + 0.5)) .. " (/comrade scale 0.75-1.25)")
    return
  end
  v = ns.SetUIScale(v)
  Print(ns.L["Window scale"] .. ": " .. ("%d%%"):format(math.floor(v * 100 + 0.5)))
end

commands.reset = ns.ResetPositions
