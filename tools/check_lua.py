"""Syntax-check the addon with Lua 5.1, then load it against minimal WoW API stubs.

Usage: tools/.venv/Scripts/python tools/check_lua.py   (needs: pip install lupa)
Stubs only cover load-time calls; real API behavior is verified in game.
"""
import os
import re
import sys

import lupa.lua51 as lupa

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON = os.path.join(ROOT, "ComradeCraft")

STUBS = r"""
-- Generic widget mock: Create* returns a widget, Get* returns 0, anything else is a no-op.
local Widget
local methods = {
  SetScript = function(self, name, fn) self.scripts[name] = fn if name == "OnEvent" then self.onEvent = fn end end,
  Show = function(self) self.shown = true if self.scripts.OnShow then self.scripts.OnShow(self) end end,
  Hide = function(self) self.shown = false end,
  IsShown = function(self) return self.shown end,
  SetShown = function(self, v) if v then self:Show() else self:Hide() end end,
  SetText = function(self, t) self.text = t end,
  GetText = function(self) return rawget(self, "text") end,
}
Widget = function()
  return setmetatable({ scripts = {}, shown = true }, { __index = function(_, k)
    if methods[k] then return methods[k] end
    if k:match("^Create") then return function() return Widget() end end
    if k:match("^Get") then return function() return 0 end end
    return function() end
  end })
end
MockWidget = Widget
function CreateFrame(_, name)
  local f = Widget()
  if not _G.__frame then _G.__frame = f end
  if name then _G[name] = f end
  __widgets = (__widgets or 0) + 1
  return f
end
UIParent = Widget()
UISpecialFrames = {}
tinsert = table.insert
RAID_CLASS_COLORS = { MAGE = { colorStr = "ff3fc7eb" } }
LOCALIZED_CLASS_NAMES_MALE = { MAGE = "Mage" }
GetItemInfo = function(id) return "Item" .. id, "|Hitem:" .. id .. "|h" end
GetItemIcon = function() return 134400 end
C_Timer = { After = function(_, fn) fn() end }
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) __log[#__log + 1] = m end }
__log = {}
SlashCmdList = {}
UnitName = function() return "Test" end
UnitClass = function() return "Mage", "MAGE" end
GetRealmName = function() return "Realm" end
date = os.date
debugstack = function() return debug.traceback("", 2) end
GetBuildInfo = function() return "1.60.1", "70888", "", 16001 end
time = os.time
GetProfessions = function() return 1 end
GetProfessionInfo = function() return "Tailoring", 0, 86, 150, 0, 0, 197 end
C_Container = {
  GetContainerNumSlots = function() return 2 end,
  GetContainerItemInfo = function(bag, slot) if bag == 0 then return { itemID = 2589, stackCount = 10 } end end,
}
"""


def main():
    toc = open(os.path.join(ADDON, "ComradeCraft.toc"), encoding="utf-8").read()
    files = [l.strip().replace("\\", "/") for l in toc.splitlines()
             if l.strip() and not l.startswith("#")]

    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    compile_ = lua.eval("function(src, name) local f, err = loadstring(src, name) return f, err end")
    failed = False
    chunks = []
    for name in files:
        src = open(os.path.join(ADDON, name), encoding="utf-8").read()
        fn, err = compile_(src, "@" + name)
        if fn is None:
            print(f"SYNTAX {err}")
            failed = True
        else:
            chunks.append((name, fn))
    if failed:
        return 1

    # Locale completeness: every key the code uses (ns.L["..."], ns.Plural(n, "...", "..."))
    # must have a frFR translation, and frFR must not keep keys the code no longer uses.
    code = "".join(open(os.path.join(ADDON, n), encoding="utf-8").read()
                   for n in files if not n.startswith(("Libs/", "Locales/")) and n != "Locale.lua")
    # ns.L["..."] and a file-local alias L["..."]; Plural keys; plus keys built at runtime.
    used = set(re.findall(r'(?<![\w.])(?:ns\.)?L\["((?:[^"\\]|\\.)*)"\]', code))
    for a, b in re.findall(r'ns\.Plural\([^,]+,\s*"([^"]*)",\s*"([^"]*)"\)', code):
        used.update((a, b))
    used.update(["orange", "yellow", "green", "grey", "trainer", "vendor", "quest", "drop", "container",
                 "Enchant", "Consumable", "Bag", "Weapon", "Armor", "Reagent", "Other", "now", "soon", "later",
                 "pending", "accepted", "crafting", "shipped", "declined", "done", "cancelled",
                 "Journeyman", "Expert", "Artisan", "Master"])
    # A lone backslash before a letter ("Interface\DialogFrame" typed with one) is not a
    # path separator in Lua: the texture silently fails to load. Also catch bare L[...] without local L.
    for n in files:
        if n.startswith("Libs/") or n.startswith("Locales/") or n == "Locale.lua":
            continue
        full_src = open(os.path.join(ADDON, n), encoding="utf-8").read()
        if re.search(r'(?<![\w.])L\[', full_src) and not re.search(r'local\s+L\s*=\s*ns\.L', full_src):
            print(f"GLOBAL_L {n}: uses L[...] without 'local L = ns.L'")
            return 1
        for i, line in enumerate(full_src.splitlines(), 1):
            if re.search(r'(?<!\\)\\(?![\\nrt"\'0-9])[A-Za-z]', line):
                print(f"BACKSLASH {n}:{i}: {line.strip()[:80]}")
                return 1
    # Each language: exactly the used keys, and the same format specifiers in the same order.
    locs = {"frFR": "Locale.lua"}
    for n in files:
        if n.startswith("Locales/"):
            locs[os.path.splitext(os.path.basename(n))[0]] = n
    bad = False
    for code, n in locs.items():
        src = open(os.path.join(ADDON, n), encoding="utf-8").read()
        pairs = re.findall(r'^\s*\["((?:[^"\\]|\\.)*)"\]\s*=\s*"((?:[^"\\]|\\.)*)"', src, re.M | re.S)
        keys = set(re.findall(r'^\s*\["((?:[^"\\]|\\.)*)"\]\s*=', src, re.M))
        for k in sorted(used - keys):
            print(f"LOCALE missing {code}: {k}"); bad = True
        for k in sorted(keys - used):
            print(f"LOCALE unused {code} key: {k}"); bad = True
        spec = re.compile(r'%[-+ #0]*\d*(?:\.\d+)?[dsfx%]')
        for k, v in pairs:
            if spec.findall(k) != spec.findall(v):
                print(f"LOCALE {code} format mismatch: {k!r} -> {v!r}"); bad = True
    if bad:
        return 1

    lua.execute(STUBS)
    ns = lua.table()
    for name, fn in chunks:
        # Third-party libs are syntax-checked only (the addon must tolerate their absence),
        # except LibStub + LibProfessionDB, whose data the addon reads.
        if name.startswith("Libs/") and not name.startswith(("Libs/LibStub/", "Libs/LibProfessionDB-1.0/",
                                                              "Libs/LibSerialize/", "Libs/LibDeflate/")):
            continue
        try:
            fn("ComradeCraft", ns)
        except lupa.LuaError as e:
            print(f"LOAD {name}: {e}")
            return 1

    run = lua.eval("""function(ns)
      local f = __frame
      f.onEvent(f, "ADDON_LOADED", "ComradeCraft")
      f.onEvent(f, "PLAYER_ENTERING_WORLD")
      SlashCmdList.COMRADECRAFT("scan")
      SlashCmdList.COMRADECRAFT("")
      local c = ComradeCraftDB.chars["Test-Realm"]
      assert(c.bags[2589] == 20, "bag scan: expected 20 linen, got " .. tostring(c.bags[2589]))
      assert(c.professions.Tailoring.rank == 86, "profession scan")
      assert(ns.RecipeColor(2963, 1) == "orange")
      assert(ns.RecipeColor(2963, 25) == "yellow")
      assert(ns.RecipeColor(2963, 37) == "green")
      assert(ns.RecipeColor(2963, 50) == "grey")
      -- Needs: Bolt of Linen 1->50. Orange 1..24 = 24 crafts; from 25 the chance is
      -- (50-r)/25, below MIN_GAIN 0.25 from r=44, so it stops at 44 ("lowgain").
      -- 25..43 = 25*(H25-H6) ~ 34.15 crafts. Total ~58.15 crafts * 2 linen -> 117.
      local needs, reached, plan, info = ns.ComputeNeeds(1, 50, { [2963] = true })
      assert(reached == 44 and #plan == 1, "needs: plan, reached " .. reached)
      assert(info.reason == "lowgain", "needs: reason")
      assert(needs[2589] == 117, "needs: expected 117 linen, got " .. tostring(needs[2589]))
      -- Owned intermediates: 10 bolts owned while the plan crafts them -> 20 linen fewer.
      local n2 = ns.ComputeNeeds(1, 10, { [2963] = true, [2385] = true }, nil, { [2996] = 10 })
      local n1 = ns.ComputeNeeds(1, 10, { [2963] = true, [2385] = true })
      -- plan: 4.5 vests + 4.5 bolts = 9 linen; 4 whole owned bolts replace 8 of them -> 1.
      assert(n1[2589] == 9 and n2[2589] == 1, "owned bolts: expected 9 -> 1 linen, got "
        .. tostring(n1[2589]) .. " -> " .. tostring(n2[2589]))
      -- Vest (bolt + thread) with bolt known: bolt is expanded to 2 linen, vest costs 3.
      needs = ns.ComputeNeeds(50, 60, { [2963] = true, [2385] = true })
      assert(needs[2589] and needs[2320], "needs: vest expands bolt into linen + thread")
      assert(needs[2996] == nil, "needs: bolt should be expanded, not requested")
      -- Intermediates count as skill-ups: at orange, a vest action = vest + 1 bolt = 2 points
      -- for 3 raw mats (1.5/pt) beats bolt alone (2/pt). 1->10 = 9 points = 4.5 vests.
      local _, _, p2 = ns.ComputeNeeds(1, 10, { [2963] = true, [2385] = true })
      assert(p2[1].spell == 2385, "intermediates: vest should win, got " .. p2[1].spell)
      assert(math.abs(p2[1].crafts - 4.5) < 1e-6, "intermediates: expected 4.5 vests, got " .. p2[1].crafts)
      assert(math.abs(p2[1].subs[2963] - 4.5) < 1e-6, "intermediates: expected 4.5 bolts")
      -- Cross-profession producer (allKnown) expands but does not add points to this line.
      local fakeBar = 2840 -- Copper Bar, smelted by Mining spell 2657
      if ns.Recipes[2657] then
        assert(ns.Recipes[2657][5] == fakeBar and ns.Recipes[2657][1] ~= 197, "smelting row")
      end
      -- All grey -> blocked at the start rank.
      local _, r2 = ns.ComputeNeeds(86, 150, { [2963] = true })
      assert(r2 == 86, "needs: should be blocked at 86")

      -- Trade skill scan feeds known recipes, then net needs subtract owned linen (20).
      C_TradeSkillUI = {
        GetAllRecipeIDs = function() return { 2963, 2385 } end,
        GetRecipeInfo = function(id) return { learned = (id == 2963) } end,
      }
      GetProfessionInfo = function() return "Tailoring", 0, 1, 75, 0, 0, 197 end
      f.onEvent(f, "TRADE_SKILL_LIST_UPDATE")
      assert(c.known[197][2963] and not c.known[197][2385], "known scan")
      local net = c.needs[197].items[2589]
      assert(net and net > 0, "net needs")
      assert(ns.NeedOf(c, 2589) == net, "NeedOf")

      -- Tooltip line uses the DB.
      local lines = {}
      local tt = { AddDoubleLine = function(_, l, r) lines[#lines + 1] = l .. " | " .. r end,
        AddLine = function() end, Show = function() end }
      ns.AddNeeds(tt, 2589)
      assert(#lines == 1 and lines[1]:find("needs " .. net) and lines[1]:find("Tailoring"),
        "tooltip: " .. tostring(lines[1]))
      SlashCmdList.COMRADECRAFT("needs")

      -- Catalog: a second character needing Bolts of Linen (what Test can craft) is tagged;
      -- a level-15 cloth chest fits a level-20 mage, not a druid.
      ComradeCraftDB.chars["Vez-Realm"] = { class = "DRUID", level = 20, professions = {},
        needs = { [197] = { name = "Tailoring", items = { [2996] = 5 } } } }
      local cat = ns.CraftCatalog("Test-Realm")
      assert(cat[1].spell == 2963 and cat[1].needers[1].key == "Vez-Realm" and cat[1].needers[1].n == 5,
        "catalog: Vez needs the bolts Test can craft")
      local oldGet = GetItemInfo
      GetItemInfo = function(id)
        if id == 99001 then return "Robe", nil, 2, 15, 15, "Armor", "Cloth", 1, "INVTYPE_CHEST", 0, 0, 4, 1 end
        return oldGet(id)
      end
      assert(ns.ItemFits(99001, { class = "MAGE", level = 20 }), "fits: cloth for a mage")
      assert(not ns.ItemFits(99001, { class = "DRUID", level = 20 }), "fits: not for a druid")
      assert(not ns.ItemFits(99001, { class = "MAGE", level = 30 }), "fits: too low for level 30")
      -- Upgrades: item level vs the piece worn in that slot; Pawn's class scale when present.
      local fitsGet = GetItemInfo
      GetItemInfo = function(id)
        local il = ({ [99001] = 15, [99002] = 10, [99003] = 20 })[id]
        if il then return "Robe" .. id, "|Hitem:" .. id .. "|h", 2, il, 15, "Armor", "Cloth", 1, "INVTYPE_CHEST", 0, 0, 4, 1 end
        return fitsGet(id)
      end
      local up, gain = ns.UpgradeFor(99001, { class = "MAGE", level = 20, equipped = { [5] = 99002 } })
      assert(up and gain == 5, "upgrade: +5 item levels over the worn chest")
      assert(not ns.UpgradeFor(99001, { class = "MAGE", level = 20, equipped = { [5] = 99003 } }), "upgrade: worse than worn")
      local up2, gain2 = ns.UpgradeFor(99001, { class = "MAGE", level = 20 })
      assert(up2 and gain2 == nil, "upgrade: no equipment data -> fits, gain unknown")
      PawnCommon = { Scales = { ["Classic:MAGE1"] = { ClassID = 8, LocalizedName = "Mage: Arcane" },
        ["Classic:MAGE3"] = { ClassID = 8, LocalizedName = "Mage: Frost" } } }
      PawnGetItemData = function(link) return { link = link } end
      PawnGetSingleValueFromItem = function(data) return data.link:find("99001") and 50 or 30 end
      local mageFrost = { class = "MAGE", spec = "Frost", level = 20, equipped = { [5] = 99003 } }
      assert(ns.PawnScaleFor(mageFrost) == "Classic:MAGE3", "pawn: spec scale picked")
      local up3, gain3, how3 = ns.UpgradeFor(99001, mageFrost)
      assert(up3 and gain3 == 20 and how3 == "pawn", "pawn: score decides (50 vs 30), not item level")
      PawnCommon, PawnGetItemData, PawnGetSingleValueFromItem = nil, nil, nil
      GetItemInfo = fitsGet
      GetItemInfo = oldGet
      local gm = ns.GroupMaterials()
      assert(gm[1] and gm[1].total > 0, "group materials")
      -- Views render without error: group, group search, character craft tab with a filter.
      ComradeCraftDB.ui = ComradeCraftDB.ui or {}
      if not (ComradeCraftFrame and ComradeCraftFrame:IsShown()) then SlashCmdList.COMRADECRAFT("") end
      ComradeCraftDB.ui.sel = "group"
      ns.RefreshWindow()
      ComradeCraftFrame.search.text = "bolt"
      ns.RefreshWindow()
      ComradeCraftDB.ui.sel, ComradeCraftDB.ui.tab = "Test-Realm", "craft"
      ns.RefreshWindow()
      ComradeCraftFrame.search.text = nil
      ComradeCraftDB.ui.tab = "plan"
      ns.RefreshWindow()
      ComradeCraftDB.chars["Vez-Realm"] = nil

      -- Window: /comrade opens it, renders a header + row + material, Escape-registered.
      -- (the earlier bare "/comrade" already opened it, before any needs existed)
      assert(ComradeCraftFrame and ComradeCraftFrame:IsShown(), "window: not shown")
      assert(UISpecialFrames[1] == "ComradeCraftFrame", "window: Escape")
      SlashCmdList.COMRADECRAFT("show")
      assert(not ComradeCraftFrame:IsShown(), "window: toggle off")
      local before = __widgets
      SlashCmdList.COMRADECRAFT("")
      assert(ComradeCraftFrame:IsShown(), "window: toggle on")
      -- (widgets are pooled and the window auto-refreshes, so check the rendered text instead)
      local d = ns.DescribeNeed(c.professions.Tailoring, c)
      assert(d.plan and d.plan[1] and d.plan[1]:find("1-", 1, true), "window: plan line, got " .. tostring(d.plan and d.plan[1]))
      assert(ComradeCraftFrame.badge.text:find("1 member"), "window badge: " .. tostring(ComradeCraftFrame.badge.text))

      -- LibProfessionDB loaded with Forever data; Brown Linen Vest is {1,23,45,70} there,
      -- so at rank 30 it says yellow while our table says orange (yellow from 45).
      local LPDB = LibStub("LibProfessionDB-1.0", true)
      assert(LPDB and LPDB:IsGameVersion("Forever") and LPDB:IsReady(), "lpdb: not loaded for Forever")
      assert(LPDB:GetRequiredSkill(197, 2385) == 10, "lpdb: vest requiredSkill")
      assert(ns.LPDBColor(2385, 30) == "yellow" and ns.RecipeColor(2385, 30) == "orange", "lpdb: color rules")

      -- SkillLog: two yellow Bolt crafts at 30 (gain) then 31 (no gain). Timers are queued.
      local timers = {}
      C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
      local liveRank = 30
      GetProfessionInfo = function() return "Tailoring", 0, liveRank, 75, 0, 0, 197 end
      C_TradeSkillUI.GetRecipeInfo = function() return { learned = true, relativeDifficulty = 1 } end
      ComradeCraftDB.skillups = nil
      f.onEvent(f, "UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 2963)
      liveRank = 31
      f.onEvent(f, "UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 2963)
      f.onEvent(f, "UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 999999) -- not a recipe: ignored
      for _, fn in ipairs(timers) do fn() end
      local y = ComradeCraftDB.skillups.colors.yellow
      assert(y and y.n == 2 and y.gained == 1, "skilllog: expected 2 yellow crafts, 1 gain")
      assert(math.abs(y.expected - 1.56) < 1e-9, "skilllog: expected formula sum 1.56, got " .. y.expected)
      assert(ComradeCraftDB.skillups.raw[1].game == "yellow", "skilllog: game color")
      -- Calibration: 60 yellow samples at half the formula rate -> factor 0.5.
      assert(ns.Calibration("yellow") == nil, "calibration: too few samples")
      y.n, y.gained, y.expected = 60, 30, 60
      assert(math.abs(ns.SkillUpChance(2963, 30) - 0.4) < 1e-9, "calibration: 0.8 * 0.5")
      assert(ns.SkillUpChance(2963, 10) == 1, "calibration: orange untouched")
      SlashCmdList.COMRADECRAFT("stats")
      ComradeCraftDB.skillups = nil

      -- Trainer scan: services matched to recipe spells by name; cost and skill recorded and
      -- preferred over LibProfessionDB. Filters are widened then restored.
      C_Spell = { GetSpellName = function(id)
        return ({ [2385] = "Brown Linen Vest", [8776] = "Linen Belt" })[id] end }
      local filters = { available = true, unavailable = false, used = true }
      GetTrainerServiceTypeFilter = function(k) return filters[k] end
      SetTrainerServiceTypeFilter = function(k, v) filters[k] = v == 1 end
      GetNumTrainerServices = function() return 2 end
      GetTrainerServiceInfo = function(i) return ({ "Brown Linen Vest", "Linen Belt" })[i], nil, "available" end
      GetTrainerServiceSkillReq = function(i) return "Tailoring", ({ 12, 15 })[i], true end
      GetTrainerServiceCost = function(i) return ({ 50, 125 })[i] end
      UnitGUID = function() return "Creature-0-562-0-10969380-2485-AAAFD0FD82" end
      strsplit = function(sep, s)
        local t = {}
        for part in (s .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do t[#t + 1] = part end
        return unpack(t)
      end
      C_Map = {
        GetBestMapForUnit = function() return 1453 end,
        GetPlayerMapPosition = function() return { x = 0.5123, y = 0.4267 } end,
      }
      f.onEvent(f, "TRAINER_SHOW")
      UnitGUID, strsplit, C_Map = nil, nil, nil
      local tv = ComradeCraftDB.trainer[2385]
      assert(tv and tv.cost == 50 and tv.req == 12, "trainer: vest recorded")
      local ts = ComradeCraftDB.trainerSpots and ComradeCraftDB.trainerSpots[2485]
      assert(ts and ts.line == 197 and ts.map == 1453, "trainer: spot recorded from Creature GUID")
      ComradeCraftDB.trainerSpots = nil
      assert(filters.unavailable == false, "trainer: filter restored")
      assert(ns.TrainerRecipes(197, 75, {})[2385] == 12, "trainer: seen req wins over LibProfessionDB")
      assert(ns.Money(12345) == "1g 23s 45c", "money: " .. ns.Money(12345))
      -- Opening a recipe uses C_TradeSkillUI.OpenRecipe when present.
      local opened
      C_TradeSkillUI.OpenRecipe = function(id) opened = id end
      ns.OpenRecipe(2963)
      assert(opened == 2963, "open recipe")

      -- Prices: with a TSM-like source, steps and the total get costs; vendor reagents use the
      -- merchant buy price. Without a source, no cost is shown.
      assert(ns.DescribeNeed(c.professions.Tailoring, c).cost == nil, "cost: hidden without prices")
      TSM_API = { GetCustomPriceValue = function(_, itemStr)
        return ({ ["i:2589"] = 100 })[itemStr] end }
      ns.DetectPriceSource()
      assert(ns.PriceSourceName == "TSM", "cost: TSM detected")
      assert(ns.BuyCost(2589, 3) == 300 and ns.BuyCost(2320, 2) == 20, "cost: AH and vendor prices")
      ns.UpdateNeeds(c)
      local dc = ns.DescribeNeed(c.professions.Tailoring, c)
      assert(dc.cost and dc.cost:find("TSM", 1, true), "cost: total line, got " .. tostring(dc.cost))
      assert(dc.totals and dc.totals.routes[1].active and dc.totals.routes[1].buy > 0
        and dc.totals.routes[1].brut >= dc.totals.routes[1].buy, "totals: gross >= to buy > 0")
      assert(dc.steps[1].range:find("c", 1, true), "cost: step range has a price, got " .. dc.steps[1].range)
      assert(ns.DisenchantPrice and ns.DisenchantPrice(2589) == 100, "de price: TSM Destroy source wired")
      TSM_API, ns.PriceSource, ns.PriceSourceName, ns.DisenchantPrice = nil, nil, nil, nil
      ns.UpdateNeeds(c)

      -- Route types: with bolts selling for 1g, "profit" grinds bolts (mats - resale < 0),
      -- "cheap" keeps the vest (fewest mats per point). Milestones hold the per-bracket copper.
      local oldPS = ns.PriceSource
      ns.PriceSource = function(item) return ({ [2589] = 100, [2996] = 10000, [2385] = 1000 })[item] end
      local _, _, pc, ic = ns.ComputeNeeds(1, 10, { [2963] = true, [2385] = true }, nil, nil, nil, "cheap")
      local _, _, pp, ip = ns.ComputeNeeds(1, 10, { [2963] = true, [2385] = true }, nil, nil, nil, "profit")
      assert(pc[1].spell == 2385 and pp[1].spell == 2963, "routes: cheap=vest, profit=bolt, got "
        .. pc[1].spell .. "/" .. pp[1].spell)
      assert(ic.milestones[0] and ic.milestones[0].points == 9 and ip.milestones[0].ah > ip.milestones[0].mats,
        "routes: milestone totals")
      ns.PriceSource = oldPS
      ComradeCraftDB.settings = ComradeCraftDB.settings or {}
      ns.SetRouteMode("Test-Realm", "profit")
      assert(ns.RouteMode(c) == "profit" and c.needs[197] and c.needs[197].mode == "profit", "routes: mode stored")
      assert(ns.Sync.CleanRecord({ class = "MAGE", route = "profit" }).route == "profit"
        and ns.Sync.CleanRecord({ class = "MAGE", route = "x" }).route == nil, "routes: synced, validated")

      -- Target skill: rank caps crossed, stored target drives c.needs, auto-reset, sync, steps.
      do
      local rc = ns.RankCaps(150, 300)
      -- Merchant recipes: in the plan, priced once seen on a merchant; cooldown recipes never.
      do
        local vr = ns.VendorRecipes(171, 300, {})
        -- Reputation recipes: only when the character's standing is high enough.
        local girdle = ns.ForeverDB.RecipeSpellForItem(19203)
        assert(girdle and ns.ItemReputation[19203][1] == 529 and not ns.RecipeRepOK(girdle, {})
          and not ns.RecipeRepOK(girdle, { reps = { [529] = 4 } }) and ns.RecipeRepOK(girdle, { reps = { [529] = 5 } })
          and ns.RecipeRepOK(7259, {}), "reputation recipes: need the standing")
        assert(vr[7259] == 190 and not vr[2329], "vendor recipes: Nature Protection Potion, not trainer ones")
        assert(ns.IsCooldownRecipe(11479) and not ns.IsCooldownRecipe(7259), "cooldown recipes: transmute")
        local _, _, cdPlan = ns.ComputeNeeds(225, 260, {}, {}, {}, { [11479] = 225 }, "cheap")
        assert(#cdPlan == 0, "cooldown recipes: never planned")
        -- A mat with no AH price, no merchant and none held (Fiery Core) rules the recipe out.
        ns.Recipes[999801] = { 197, 20, 40, 1, 999802, 1, { 999803, 1 } }
        local oldPSX = ns.PriceSource
        ns.PriceSource = function(item) return item == 2589 and 100 or nil end
        local _, _, xPlan = ns.ComputeNeeds(1, 10, { [999801] = true }, nil, {}, nil, "cheap")
        local _, _, hPlan = ns.ComputeNeeds(1, 10, { [999801] = true }, nil, { [999803] = 5 }, nil, "cheap")
        assert(#xPlan == 0 and #hPlan == 1, "unobtainable mat: no route, unless you hold it")
        ns.PriceSource, ns.Recipes[999801] = oldPSX, nil
        local lib = LibStub("LibProfessionDB-1.0", true)
        local rid = lib:GetRecipeItem(7259)
        local lp, lseen = ns.RecipeBuyPrice(7259)
        assert(lp == 2000 and not lseen, "vendor price: game data list price before a visit")
        ComradeCraftDB.foreverVendors = ComradeCraftDB.foreverVendors or {}
        ComradeCraftDB.foreverVendors[rid] = { npc = 8679, name = "Glyx Brewright", map = 1434, x = 28, y = 77, cost = 20000 }
        assert(select(2, ns.RecipeBuyPrice(7259)) and ns.RecipeBuyPrice(7259) == 20000, "vendor price: seen on a merchant wins")
        local vp = { skillLine = 171, rank = 190, max = 225 }
        local vc = { level = 40, known = { [171] = { [2329] = true } }, needs = { [171] = { name = "Alchemy",
          plan = { { spell = 7259, from = 190, to = 200, crafts = 10, subs = {}, learn = true } }, reached = 200,
          target = 200, cap = 225, items = {}, vendor = {}, gross = {}, milestones = {} } } }
        local vd = ns.DescribeNeed(vp, vc)
        local ve = vd.steps[1].entries[1]
        assert(ve.kind == "learn" and ve.buy and ve.copper == 20000 and ve.detail:find("Glyx Brewright", 1, true),
          "vendor recipe step: buy from the merchant, with its price, got " .. tostring(ve.detail))
        ComradeCraftDB.foreverVendors[rid] = nil
        -- Teaching item = bought/looted on Forever: Thorium Widget leaves the trainer list and is
        -- sold by the vendor of your own faction (our own faction data, no Questie needed).
        assert(ns.ForeverDB.RecipeSpellForItem(16042) == 19791, "forever db: recipe item -> spell")
        -- Looted pattern on the AH (Radiant Boots, plans 12697): planned at its AH price.
        local rb = ns.ForeverDB.RecipeSpellForItem(12697)
        local oldPSA = ns.PriceSource
        ns.PriceSource = function(item) return item == 12697 and 30000 or nil end
        assert(rb and ns.AuctionRecipes(164, 300, {})[rb] and ns.RecipeLearnCost(rb) == 30000, "ah recipes: looted plans on the AH")
        ns.PriceSource = function() return nil end
        assert(not ns.AuctionRecipes(164, 300, {})[rb], "ah recipes: none without an AH price")
        ns.PriceSource = oldPSA
        local rq, rqGuess = ns.RequiredSkill(18401, 250)
        assert(rq == ns.Recipes[18401][2] and rqGuess and ns.RequiredSkill(7259, 190) == 190,
          "required skill: a later-expansion value is capped at the Forever yellow rank")
        assert(ns.TaughtByItem(19791) and not ns.TrainerRecipes(202, 300, {})[19791], "thorium widget: not a trainer recipe")
        local oldUFG = UnitFactionGroup
        UnitFactionGroup = function() return "Alliance" end
        assert(ns.VendorRecipes(202, 300, {})[19791] and ns.NpcFaction(5175) == "A", "thorium widget: Alliance vendor")
        local tw = ns.RecipeSources(19791).vendor.list
        assert(#tw == 1 and tw[1].id == 5175, "thorium widget: only the Ironforge vendor for Alliance")
        UnitFactionGroup = function(u) return u == "npc" and "Horde" or "Alliance" end
        local oldGUID = UnitGUID
        UnitGUID = function(u) return u == "npc" and "Creature-0-1-2-3-4242-0000" or nil end
        local oldSplit = strsplit
        strsplit = function(sep, str)
          local out = {}
          for part in (str .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = part end
          return unpack(out)
        end
        ns.ForeverDB.ObserveNpcFaction()
        strsplit = oldSplit
        assert(ComradeCraftDB.npcFaction[4242] == "H" and ns.NpcFaction(4242) == "H", "npc faction: seen in game")
        UnitFactionGroup, UnitGUID = oldUFG, oldGUID
        ComradeCraftDB.npcFaction = nil
      end
      assert(#ns.RankCaps(150, 175) == 1 and rc[1] == 150 and rc[2] == 225 and #rc == 2
        and #ns.RankCaps(75, 75) == 0, "target: rank caps")
      assert(ns.TargetFor(c, c.professions.Tailoring) == 75, "target: default = cap")
      ns.SetTarget("Test-Realm", 197, 30)
      assert(c.targets[197] == 30 and c.needs[197].target == 30 and c.needs[197].reached == 30
        and c.needs[197].cap == 75, "target: below the cap, got " .. tostring(c.needs[197].reached))
      ns.SetTarget("Test-Realm", 197, 120)
      assert(c.needs[197].target == 120 and c.needs[197].rankCaps[1] == 75, "target: past the cap")
      ns.SetTarget("Test-Realm", 197, 999)
      assert(c.targets[197] == 300, "target: clamped to 300")
      ns.SetTarget("Test-Realm", 197, 30)
      c.professions.Tailoring.rank = 30
      ns.UpdateNeeds(c)
      assert(c.targets == nil, "target: reset once the rank catches up")
      c.professions.Tailoring.rank = 1
      ns.SetTarget("Test-Realm", 197, nil)
      assert(c.targets == nil and c.needs[197].target == 75, "target: back to the cap")
      -- A friend's character: the target is local (kit), never sent, and wins over theirs.
      ComradeCraftDB.remote = ComradeCraftDB.remote or {}
      local fr = { class = "MAGE", peer = "pvT", targets = { [197] = 60 }, updated = 5,
        professions = { Tailoring = { skillLine = 197, rank = 45, max = 75 } },
        known = { [197] = { [2963] = true } } }
      ComradeCraftDB.remote["Friend-Realm"] = fr
      ns.SetTarget("Friend-Realm", 197, 50)
      assert(fr.localTargets[197] == 50 and fr.targets[197] == 60 and fr.updated == 5
        and fr.needs[197].target == 50, "target: friend's target is local")
      ns.SetTarget("Friend-Realm", 197, nil)
      assert(fr.localTargets == nil and fr.needs[197].target == 60, "target: friend's own target back")
      ComradeCraftDB.remote["Friend-Realm"] = nil
      local ct = ns.Sync.CleanRecord({ class = "MAGE", targets = { [197] = 175, [171] = 999, x = 5 } }).targets
      assert(ct and ct[197] == 175 and ct[171] == nil and ct.x == nil, "target: synced, validated")
      local _, _, pb = ns.ComputeNeeds(1, 10, { [2963] = true, [2385] = true }, nil, nil, nil, "cheap", nil, { [5] = true })
      assert(#pb == 2 and pb[1].to == 5 and pb[2].from == 5 and pb[2].spell == pb[1].spell, "target: step split at a cap")
      assert(ns.ShoppingListLabel({ name = "Tailoring", target = 175 }, 131, true) == "Tailoring (131-175)"
        and ns.ShoppingListLabel({ name = "Tailoring", target = 175 }, 131, false) == "Tailoring", "target: list label")
      local oldPS2 = ns.PriceSource
      ns.PriceSource = function(item) return item == 2589 and 100 or nil end
      local tt = ns.TargetTotals({ mode = "cheap", reached = 40, gross = { [2589] = 10 }, items = { [2589] = 4 },
        vendor = {}, milestones = { [0] = { best = 50 } },
        alt = { mode = "profit", reached = 40, gross = { [2589] = 12 }, items = { [2589] = 6 }, milestones = { [0] = { best = 500 } } } },
        30, true)
      local a1, a2 = tt.routes[1], tt.routes[2]
      -- Resale unit by unit: SaleCap units at the AH, the rest at the merchant or disenchanted
      -- by a character of yours with enough Enchanting.
      do
        local oldCap, oldCtx = ns.SaleCap, ns.resaleCtx
        ns.Recipes[999811] = { 197, 20, 40, 1, 999812, 1, { 2589, 1 } }
        ns.ItemPrices[999812] = { 50, 200 }
        local oldPS3, oldDE = ns.PriceSource, ns.DisenchantEstimate
        ns.PriceSource = function(item) return ({ [2589] = 10, [999812] = 10000 })[item] end
        ns.DisenchantEstimate = function(item) return item == 999812 and 300 or nil end
        ns.SaleCap = function() return 3 end
        ns.resaleCtx = { deBy = function() return "Ench-Realm" end }
        local _, _, _, si = ns.ComputeNeeds(1, 10, { [999811] = true }, nil, {}, nil, "cheap")
        local s = si.sales[999812]
        assert(s and math.floor(s.ah + 0.5) == 3 and s.de > 0 and s.vendor == 0 and s.deBy == "Ench-Realm",
          "resale: 3 at the AH, the rest disenchanted")
        ns.resaleCtx = { deBy = function() return nil end }
        _, _, _, si = ns.ComputeNeeds(1, 10, { [999811] = true }, nil, {}, nil, "cheap")
        assert(si.sales[999812].de == 0 and si.sales[999812].vendor > 0, "resale: no enchanter = merchant")
        ns.SaleCap, ns.resaleCtx, ns.PriceSource, ns.DisenchantEstimate = oldCap, oldCtx, oldPS3, oldDE
        ns.Recipes[999811], ns.ItemPrices[999812] = nil, nil
      end
      assert(a1.brut == 1000 and a1.buy == 400 and a1.resale == 50 and a1.net == 380 and a1.netOk,
        "totals: net = to buy - resale + trainer, got " .. a1.net)
      assert(a2.brut == 1200 and a2.buy == 600 and a2.net == 100 and a2.noTrainer, "totals: other route")
      ns.PriceSource = oldPS2
      -- A rank step comes before the first step past the cap, warned when the level is too low.
      local fp = { skillLine = 197, rank = 70, max = 75 }
      local fc = { level = 5, known = { [197] = { [2963] = true } }, needs = { [197] = { name = "Tailoring",
        plan = { { spell = 2963, from = 75, to = 80, crafts = 5, subs = {} } }, rankCaps = { 75 },
        reached = 80, target = 80, cap = 75, items = {}, vendor = {}, gross = {}, milestones = {} } } }
      local fd = ns.DescribeNeed(fp, fc)
      assert(fd.steps[1].rankCap == 75 and fd.steps[1].warn and fd.steps[2].from == 75, "target: rank step + level warning")
      end
      local mt = ns.MilestoneRows(c.needs[197])
      local r1 = mt and mt.rows[1]
      assert(r1 and r1.from == 1 and r1.to == 75 and #r1.routes == 2 and r1.routes[1].mode == "cheap"
        and r1.routes[2].active and r1.routes[2].m and r1.routes[2].net == r1.routes[2].m.mats - r1.routes[2].m.best,
        "routes: milestone rows")
      local ro = ns.ResaleOptions(2996)
      assert(ro.vendor >= 0 and ro.ah == nil and ro.de == nil, "resale: no AH, cloth not disenchantable")
      -- Lesser Magic Wand: merchant 1s10, AH 1s49 -> 1s41 after the cut, minus a quarter of the 1s
      -- estimated deposit = 1s16, under 1s10 + 10%: the merchant wins. A measured deposit replaces the estimate.
      local oldPS = ns.PriceSource
      ns.PriceSource = function(i) return i == 11287 and 149 or nil end
      local rw = ns.ResaleOptions(11287)
      assert(rw.vendor == 110 and rw.deposit == 100 and math.abs(rw.ah - (149 * 0.95 - 25)) < 0.01
        and ns.ResaleValue(11287) == 110, "resale: deposit risk, merchant wins " .. tostring(rw.ah))
      ns.LearnDeposit(11287, 130, 13)
      assert(ns.ResaleOptions(11287).deposit == 10 and ns.AuctionDeposit(11288) == 100, "resale: measured deposit")
      assert(ns.ResaleValue(11287) > 130, "resale: low measured deposit, AH wins")
      ns.PriceSource = function(i) return i == 11287 and 125 or nil end
      assert(ns.ResaleValue(11287) == 110, "resale: AH must beat the merchant by 10%")
      ns.PriceSource, ComradeCraftDB.deposits = oldPS, nil
      ComradeCraftDB.ui.sel = "Test-Realm"
      ComradeCraftDB.ui.tab = "plan"
      ns.RefreshWindow()
      ns.SetRouteMode("Test-Realm", "cheap")
      -- Collapse: a folded profession renders as one line in Plan and Can craft.
      ComradeCraftDB.ui.collapsed = { [197] = true }
      ns.RefreshWindow()
      ComradeCraftDB.ui.tab = "craft"
      ns.RefreshWindow()
      ComradeCraftDB.ui.tab, ComradeCraftDB.ui.collapsed = "plan", nil
      ns.RefreshWindow()

      -- Sources: LibProfessionDB npc ids + QuestieDB spawns; nearest friendly trainer gets the
      -- TomTom waypoint (same map as the player wins).
      local lib = LibStub("LibProfessionDB-1.0")
      local oldSrc = lib.GetRecipeSources
      lib.GetRecipeSources = function(_, spell)
        if spell == 3915 then return { trainer = { { id = 1, name = "Far" }, { id = 2, name = "Near" }, { id = 3, name = "Enemy" }, total = 5 } } end
      end
      LibQuestieDB = { Npc = {
        name = function(id) return "N" .. id end,
        friendlyToFaction = function(id) return id == 3 and "H" or "AH" end,
        spawns = function(id) return ({ [1] = { [12] = { { 10, 10 } } }, [2] = { [14] = { { 50, 52 } } }, [3] = { [14] = { { 50, 50 } } } })[id] end } }
      QuestieLoader = { ImportModule = function() return { GetUiMapIdByAreaId = function(_, a) return a + 1000 end } end }
      UnitFactionGroup = function() return "Alliance" end
      C_Map = { GetBestMapForUnit = function() return 1014 end,
        GetPlayerMapPosition = function() return { x = 0.5, y = 0.5 } end, GetAreaInfo = function(a) return "Zone" .. a end }
      local src = ns.RecipeSources(3915)
      assert(#src.trainer.list == 2 and src.trainer.list[1].name == "Near" and src.trainer.total == 5, "sources: friendly, nearest first")
      local wp
      TomTom = { AddWaypoint = function(_, m, x, y, o) wp = { m = m, x = x, y = y, title = o.title } end }
      assert(ns.WaypointRecipe(3915) and wp.m == 1014 and math.abs(wp.x - 0.5) < 1e-9, "sources: waypoint on the nearest")
      local tl = {}
      ns.AddSourceLines({ AddLine = function(_, l) tl[#tl + 1] = l end, AddDoubleLine = function(_, l, r) tl[#tl + 1] = l .. "=" .. r end }, 3915)
      assert(table.concat(tl, "|"):find("Near (Zone14 50, 52)", 1, true) and table.concat(tl, "|"):find("and 3 more", 1, true),
        "sources: tooltip " .. table.concat(tl, "|"))
      -- Next rank: Cooking at 150 -> the Expert Cookbook (skill 125) from its vendor or the AH.
      local ra = ns.RankAdvice({ skillLine = 185, rank = 150, max = 150 })
      assert(ra and ra.entries[1] and ra.entries[1].item == 16072 and ra.entries[1].detail:find("125", 1, true),
        "rank: expert cookbook " .. tostring(ra and ra.entries[1] and ra.entries[1].detail))
      local rb = ns.RankAdvice({ skillLine = 197, rank = 150, max = 150 })
      assert(rb and rb.entries[1] and rb.entries[1].kind == "trainer" and rb.entries[1].label == "Georgio Bolero"
        and rb.notes[1]:find("trainer", 1, true), "rank: primary from a trainer")
      assert(ns.RankAdvice({ skillLine = 185, rank = 225, max = 225 }).notes[1]:find("Questie", 1, true), "rank: artisan needs Questie")
      -- With QuestieDB: the quest needing Cooking 225, for our faction, nearest giver; waypoint on click.
      LibQuestieDB = { Enum = { factionRaceMasks = { Alliance = 1, Horde = 2 } },
        Quest = { GetAllIds = function() return { 10, 11, 12 } end,
          requiredSkill = function(id) return ({ [10] = { 185, 225 }, [11] = { 185, 225 }, [12] = { 197, 225 } })[id] end,
          requiredRaces = function(id) return id == 11 and 2 or 0 end,
          name = function(id) return "Q" .. id end, requiredLevel = function() return 35 end,
          startedBy = function() return { { 8125 } } end },
        Npc = { name = function() return "Dirge" end, friendlyToFaction = function() return "AH" end,
          spawns = function() return { [440] = { { 52, 28 } } } end } }
      UnitFactionGroup = function() return "Alliance" end
      local rq2 = ns.RankAdvice({ skillLine = 185, rank = 225, max = 225 })
      assert(rq2.entries[1] and rq2.entries[1].kind == "quest" and rq2.entries[1].label == "Q10" and #rq2.entries == 1
        and rq2.entries[1].detail:find("Dirge", 1, true), "rank: artisan quest found " .. tostring(rq2.entries[1] and rq2.entries[1].detail))
      LibQuestieDB, UnitFactionGroup = nil, nil
      assert(ns.DescribeNeed({ skillLine = 185, rank = 150, max = 150 }, { known = { [185] = {} } }).rank, "rank: shown at the cap")
      -- A visited trainer (exact position) beats the capped LibProfessionDB list.
      ComradeCraftDB.trainerSpots = { [5482] = { name = "Stephen Ryback", line = 197, map = 1014, x = 51, y = 51 } }
      ComradeCraftDB.trainer = ComradeCraftDB.trainer or {}
      local src2 = ns.RecipeSources(3915)
      assert(src2.trainer.list[1].name == "Stephen Ryback" and src2.trainer.list[1].visited, "sources: visited trainer first")
      ComradeCraftDB.trainerSpots = nil
      lib.GetRecipeSources, LibQuestieDB, QuestieLoader, TomTom, C_Map, UnitFactionGroup = oldSrc, nil, nil, nil, nil, nil

      -- Shopping: biggest need first; Auctionator list built from exact search terms.
      local si = ns.ShoppingItems({ items = { [2589] = 5, [2320] = 9, [2996] = 0 } })
      assert(#si == 2 and si[1].item == 2320 and si[2].n == 5, "shopping: sorted, zero dropped")
      assert(not ns.CanExportShopping(), "shopping: no Auctionator")
      local made
      Auctionator = { API = { v1 = {
        ConvertToSearchString = function(_, t) return '"' .. t.searchString .. '";;;;;;;;;;;;;' .. t.quantity end,
        CreateShoppingList = function(_, name, list) made = { name = name, list = list } end } } }
      local nn = ns.ExportShopping("Test-Realm", 197)
      assert(nn and nn > 0 and made.name == "ComradeCraft: Tailoring" and made.list[1]:find('"Item', 1, true),
        "shopping: exported " .. tostring(nn))
      SlashCmdList.COMRADECRAFT("shop tail")
      -- TSM: search text with exact names and max quantities; odd names skipped.
      local ts, tskip = ns.TSMSearchString({ { item = 1, n = 124 }, { item = 2, n = 60 }, { item = 3, n = 1 }, { item = 4, n = 2 } },
        function(id) return ({ "Linen Cloth", "Wool Cloth", "A/B" })[id] end)
      assert(ts == "Linen Cloth/exact/x124;Wool Cloth/exact/x60" and tskip == 2, "tsm search text: " .. ts)
      -- TSM group: unique path per import; import text; stale = all bought, or replaced.
      local gp = ns.TSMGroupPath("Vez", "Tailoring", 80, 125)
      assert(gp == "ComradeCraft`Vez`Tailoring 80-125", "tsm group path")
      assert(ns.TSMGroupString(gp, { { item = 2589 }, { item = 2320 } }) == "group:" .. gp .. ",i:2589,i:2320", "tsm group text")
      local stale = ns.TSMStaleGroups({
        ["ComradeCraft`Vez`Tailoring 80-125"] = { 2589 },   -- replaced by 95-125
        ["ComradeCraft`Vez`Tailoring 95-125"] = { 2589 },   -- current
        ["ComradeCraft`Vez`Cooking 1-50"] = { 2672 },       -- all bought
        ["Other`Group"] = { 1 },
      }, function(_, _, id) return id == 2589 end)
      assert(#stale == 2 and stale[1].path:find("Cooking") and stale[1].reason == "done"
        and stale[2].path:find("80%-125") and stale[2].reason == "replaced", "tsm stale groups")
      TSM_API = {}
      ns.ShoppingAction("Test-Realm", 197)
      assert(ComradeCraftCopyFrame and ComradeCraftCopyFrame.search.value:find("/exact/x", 1, true)
        and ComradeCraftCopyFrame.group.value:find("^group:ComradeCraft`Test`Tailoring %d+%-%d+,i:"), "tsm: copy window "
        .. tostring(ComradeCraftCopyFrame and ComradeCraftCopyFrame.group.value))
      TSM_API = nil
      -- Step panel: opens with the profession window, shows the first step; bags allow N crafts.
      assert(ns.CraftableNow(2963, { [2589] = 7 }) == 3 and ns.CraftableNow(2963, {}) == 0, "craftable now")
      -- (market-value plan here: under "group", the 20 owned linen make bolts free, no learn step first)
      ComradeCraftDB.settings.groupObjective = "solo"
      ns.UpdateNeeds(c)
      f.onEvent(f, "TRADE_SKILL_LIST_UPDATE")
      assert(ns.openLine == 197, "tracker: open line " .. tostring(ns.openLine))
      f.onEvent(f, "TRADE_SKILL_SHOW")
      assert(ComradeCraftTracker and ComradeCraftTracker:IsShown(), "tracker: shown")
      assert(ComradeCraftTracker.title.text:find("Tailoring", 1, true), "tracker: title " .. tostring(ComradeCraftTracker.title.text))
      assert(ComradeCraftTracker.entries[1].entry ~= nil, "tracker: first step entries")
      -- Craft queue: bolts first (bags hold linen), one click crafts the batch.
      -- Craft queue: a recipe still to learn blocks it; otherwise the first batch the bags
      -- allow (enchants are done by hand); one click sends that batch.
      local cq = ns.CraftQueue(c, c.professions.Tailoring, "step")
      local nq, blk = ns.NextCraft(cq)
      assert(cq[1].learn and nq == nil and blk == cq[1], "queue: learn first blocks")
      ComradeCraftDB.settings.groupObjective = nil
      local pick = ns.NextCraft({ { spell = 1, n = 5, ready = 0 }, { spell = 2, n = 3, ready = 3, enchant = true },
        { spell = 3, n = 4, ready = 2 } })
      assert(pick and pick.spell == 3, "queue: first ready non-enchant")
      local crafted
      C_TradeSkillUI.CraftRecipe = function(spell, n) crafted = { spell, n } end
      ComradeCraftTracker.next = { spell = 2963, ready = 2 }
      ComradeCraftTracker.craft.scripts.OnClick(ComradeCraftTracker.craft)
      assert(crafted and crafted[1] == 2963 and crafted[2] == 2, "queue: craft next sends the batch")
      ComradeCraftDB.settings.queueExtent = "milestone"
      ns.RefreshTracker()
      ComradeCraftDB.settings.queueExtent = nil
      -- A step with an intermediate: the bags line is about the bolts, not the vest.
      local sc = { bags = { [2589] = 4 }, known = { [197] = { [2963] = true, [2385] = true } },
        professions = { Tailoring = { skillLine = 197, rank = 1, max = 10 } } }
      ns.UpdateNeeds(sc)
      local fe
      for _, e in ipairs(ns.DescribeNeed(sc.professions.Tailoring, sc).steps[1].entries) do
        if e.kind == "craft" and not e.stock then fe = e break end
      end
      assert(fe and fe.spell == 2963 and ns.CraftableNow(fe.spell, sc.bags) == 2, "tracker: first craft is the bolt")
      SlashCmdList.COMRADECRAFT("tracker")
      assert(ComradeCraftDB.settings.tracker == false, "tracker: toggled off")
      assert(not ns.TrackerOn() and #ns.SkillupStatsLines() >= 1, "manage: tracker state, stats lines")
      -- Help view renders; the tour: Skip hides it for the session only, finishing marks it done.
      ComradeCraftDB.ui.sel = "help"
      ns.RefreshWindow()
      ComradeCraftDB.ui.sel = "group"
      ComradeCraftDB.settings.tutorialDone = nil
      ns.StartTutorial(true)
      local tour = ComradeCraftTour
      tour.skip.scripts.OnClick(tour.skip)
      assert(not ComradeCraftDB.settings.tutorialDone and not tour:IsShown(), "tour: skip")
      ns.StartTutorial()
      assert(not tour:IsShown(), "tour: skipped stays hidden this session")
      ns.StartTutorial(true)
      for _ = 1, 5 do tour.next.scripts.OnClick(tour.next) end
      assert(ComradeCraftDB.settings.tutorialDone == true and not tour:IsShown(), "tour: done after the last card")
      SlashCmdList.COMRADECRAFT("tracker")
      f.onEvent(f, "TRADE_SKILL_CLOSE")
      assert(not ComradeCraftTracker:IsShown() and ns.openLine == nil, "tracker: hidden on close")
      Auctionator = nil

      -- Sync, simulated with a captured transport: privacy by default, mutual add, cleaning.
      local sent = {}
      ns.Sync.transport = function(text, dist, target)
        sent[#sent + 1] = { msg = ns.Sync.Decode(text), dist = dist, target = target }
      end
      IsInGuild = function() return true end
      IsInInstance = function() return false end
      Ambiguate = function(n) return n end
      local rt = ns.Sync.Decode(ns.Sync.Encode({ t = "H", x = { 1, "a" } }))
      assert(rt and rt.t == "H" and rt.x[2] == "a", "sync: encode/decode roundtrip")
      local cnt = 0
      for _ in pairs(ns.Sync.Hello().c) do cnt = cnt + 1 end
      assert(cnt == 0, "sync: no character leaves unless shared")
      sent = {}
      ns.Sync.Announce()
      assert(#sent == 1 and sent[1].dist == "GUILD" and sent[1].msg.t == "P" and sent[1].msg.c == nil,
        "sync: login sends only a presence ping to the guild")
      local function From(msg, sender) ns.Sync.OnMessage(ns.Sync.Encode(msg), "WHISPER", sender) end
      sent = {}
      From({ t = "P", v = 1, id = "peerVez" }, "Vez")
      local pv = ComradeCraftDB.peers.peerVez
      assert(pv and not pv.included and #sent == 0, "sync: a ping makes a suggestion, no reply")
      From({ t = "H", v = 1, id = "peerVez", c = { ["Vez-Realm"] = { u = 100, cl = "DRUID", lv = 20,
        p = { [197] = { 50, 75, "Tailoring" } } }, ["bad|key"] = { u = 1 } } }, "Vez")
      assert(pv.asked and pv.chars["Vez-Realm"] and not pv.chars["bad|key"], "sync: hello stored, bad key dropped")
      assert(#sent == 0, "sync: no reply to a player we did not add")
      c.shared = true
      From({ t = "R", v = 1, id = "peerVez", k = { "Test-Realm" } }, "Vez")
      assert(#sent == 0, "sync: requests from non-added players are refused")
      ns.Sync.Include("peerVez")
      assert(sent[1] and sent[1].msg.t == "H" and sent[1].msg.c["Test-Realm"] and sent[1].target == "Vez",
        "sync: adding whispers our shared summaries")
      assert(sent[2] and sent[2].msg.t == "R" and sent[2].msg.k[1] == "Vez-Realm", "sync: adding requests their data")
      sent = {}
      From({ t = "D", v = 1, id = "peerVez", key = "Vez-Realm", rec = { class = "DRUID", level = 20, updated = 100,
        professions = { Tailoring = { rank = 1, max = 75, skillLine = 197 } }, known = { [197] = { 2963, 999999 } },
        owned = { [2589] = 3, [123456789] = 5 } } }, "Vez")
      local vr = ComradeCraftDB.remote["Vez-Realm"]
      assert(vr and vr.known[197][2963] and not vr.known[197][999999], "sync: unknown spell dropped")
      assert(vr.bags[2589] == 3 and not vr.bags[123456789], "sync: unknown item dropped")
      assert(ns.AllChars()["Vez-Realm"] and vr.needs and vr.needs[197], "sync: remote character visible with needs")
      From({ t = "R", v = 1, id = "peerVez", k = { "Test-Realm", "Nope-Realm" } }, "Vez")
      assert(#sent == 1 and sent[1].msg.t == "D" and sent[1].msg.key == "Test-Realm", "sync: added player gets data")
      -- Craft requests: ours goes to Vez and is re-sent until Vez's addon acknowledges it; Vez's
      -- answer updates our copy; theirs for our character lands in our list; bad ones are dropped.
      local function OfType(t)
        local out = {}
        for _, m in ipairs(sent) do if m.msg.t == t then out[#out + 1] = m end end
        return out
      end
      GetServerTime = function() return 1000 end
      sent = {}
      local rq = ns.Requests.Create("Vez-Realm", 2963, 3, "for my vest")
      local q1 = OfType("Q")[1]
      assert(rq and q1 and q1.target == "Vez" and q1.msg.q.qty == 3 and q1.msg.q.note == "for my vest", "requests: sent to Vez")
      sent = {}
      From({ t = "P", v = 1, id = "peerVez" }, "Vez")
      assert(#OfType("Q") == 1, "requests: not acknowledged -> re-sent when Vez shows up")
      From({ t = "A", v = 1, id = "peerVez", rid = rq.id, u = rq.updated }, "Vez")
      assert(rq.acked == rq.updated, "requests: acknowledged")
      sent = {}
      From({ t = "Q", v = 1, id = "peerVez", q = { rid = rq.id, from = "Test-Realm", to = "Vez-Realm", spell = 2963,
        qty = 3, status = "accepted", u = 1005 } }, "Vez")
      assert(rq.status == "accepted" and OfType("A")[1] and OfType("A")[1].msg.rid == rq.id, "requests: answer applied, acked")
      From({ t = "Q", v = 1, id = "peerVez", q = { rid = "vz-1", from = "Vez-Realm", to = "Test-Realm", spell = 2963,
        qty = 2, status = "pending", u = 1000 } }, "Vez")
      From({ t = "Q", v = 1, id = "peerVez", q = { rid = "vz-2", from = "Vez-Realm", to = "Other-Realm", spell = 2963,
        qty = 2, status = "pending", u = 1000 } }, "Vez")
      From({ t = "Q", v = 1, id = "peerVez", q = { rid = "vz-3", from = "Vez-Realm", to = "Test-Realm", spell = 999999,
        qty = 2, status = "pending", u = 1000 } }, "Vez")
      local rqs = ComradeCraftDB.requests
      assert(rqs["vz-1"] and ns.Requests.Role(rqs["vz-1"]) == "crafter" and not rqs["vz-2"] and not rqs["vz-3"],
        "requests: only valid ones for our characters")
      assert(ns.Requests.OpenCount() == 1, "requests: one to answer")
      assert(rqs["vz-1"].item == ns.Recipes[2963][5], "requests: item set from our table")
      -- A request for a character we do not have: acknowledged and declined (no endless resend).
      sent = {}
      From({ t = "Q", v = 1, id = "peerVez", q = { rid = "vz-4", from = "Vez-Realm", to = "Nobody-Realm", spell = 2963,
        qty = 1, status = "pending", u = 1000 } }, "Vez")
      assert(OfType("A")[1] and OfType("Q")[1] and OfType("Q")[1].msg.q.status == "declined", "requests: foreign target declined")
      -- Escape codes rejected; roles enforced (Vez cannot mark our request cancelled-by-us states).
      assert(ns.Requests.Clean({ rid = "x", from = "A|cffff0000", to = "B", spell = 2963, qty = 1, status = "pending", u = 1 }) == nil,
        "requests: escape codes rejected")
      From({ t = "Q", v = 1, id = "peerVez", q = { rid = "vz-1", from = "Vez-Realm", to = "Test-Realm", spell = 2963,
        qty = 2, status = "done", u = 2000 } }, "Vez")
      assert(rqs["vz-1"].status == "pending", "requests: requester cannot mark done")
      -- Mail helper attaches the crafted bolts of an accepted request from Vez.
      rqs["vz-1"].status = "accepted"
      local bolt = ns.Recipes[2963][5]
      local me = ns.CharData()
      local savedBolt = me.bags[bolt]
      me.bags[bolt] = 5
      local gotBolt
      for _, g in ipairs(ns.Mail.ItemsFor("Vez-Realm")) do if g.item == bolt then gotBolt = g.n end end
      assert(gotBolt == 2, "requests: mail attaches the 2 crafted bolts, got " .. tostring(gotBolt))
      me.bags[bolt] = savedBolt
      rqs["vz-1"].status = "pending"
      ComradeCraftDB.ui.sel = "requests"
      ns.RefreshWindow()
      sent = {}
      ns.Requests.Set("vz-1", "done")
      local q2 = OfType("Q")[1]
      assert(q2 and q2.msg.q.status == "done" and q2.target == "Vez", "requests: crafter's answer sent back")
      ns.Requests.ShowDialog("Vez-Realm", 2963)
      ComradeCraftRequestDialog.qty.text = "4"
      sent = {}
      ComradeCraftRequestDialog.send.scripts.OnClick(ComradeCraftRequestDialog.send)
      assert(OfType("Q")[1] and OfType("Q")[1].msg.q.qty == 4, "requests: dialog sends")
      -- By mail (opt-in): subject round-trips; the crafter's inbox scan adds it once, only when on.
      local subj = ns.Requests.MailSubject({ spell = 2963, qty = 3, id = "abc-1700000000-1234" })
      local sp, sq, sr = ns.Requests.ParseSubject(subj)
      assert(#subj <= 64 and sp == 2963 and sq == 3 and sr == "abc-1700000000-1234", "requests: mail subject " .. subj)
      GetInboxNumItems = function() return 1 end
      GetInboxHeaderInfo = function() return nil, nil, "Vez", "[CC:2963:2:vz-mail-1] Bolt" end
      f.onEvent(f, "MAIL_INBOX_UPDATE")
      assert(not rqs["vz-mail-1"], "requests: mail mode off by default")
      ComradeCraftDB.settings.mailRequests = true
      f.onEvent(f, "MAIL_INBOX_UPDATE")
      f.onEvent(f, "MAIL_INBOX_UPDATE")
      assert(rqs["vz-mail-1"] and rqs["vz-mail-1"].to == "Test-Realm" and rqs["vz-mail-1"].from == "Vez-Realm"
        and rqs["vz-mail-1"].qty == 2, "requests: inbox request added once")
      ComradeCraftDB.settings.mailRequests, GetInboxNumItems, GetInboxHeaderInfo = nil, nil, nil
      -- Alerts: each fires once; upgrade alerts are opt-in and offer to ask for the craft.
      local notes = {}
      local origNotify = ns.Alerts.Notify
      ns.Alerts.Notify = function(t) notes[#notes + 1] = t origNotify(t) end
      local me = ns.CharData()
      GetTime = function() return 500 end
      GetSpellCooldown = function(spell) if spell == 2963 then return 490, 3600 end return 0, 0 end
      me.known = me.known or {}
      me.known[197] = me.known[197] or {}
      me.known[197][2963] = true
      ns.Alerts.ScanCooldowns()
      assert(me.cooldowns[2963] == 1000 + 3590, "alerts: cooldown ready time " .. tostring(me.cooldowns[2963]))
      me.cooldowns[2963] = 900
      ns.Alerts.CheckCooldowns()
      ns.Alerts.CheckCooldowns()
      assert(#notes == 1 and notes[1].title:find("Cooldown ready", 1, true), "alerts: cooldown announced once")
      -- Combat: secret numbers cannot be compared; the scan keeps the old value, no error.
      issecretvalue = function() return true end
      ns.Alerts.ScanCooldowns()
      assert(me.cooldowns[2963] == 900, "alerts: secret cooldown skipped")
      InCombatLockdown = function() return true end
      issecretvalue = nil
      ns.Alerts.ScanCooldowns()
      assert(me.cooldowns[2963] == 900, "alerts: no cooldown scan in combat")
      GetSpellCooldown, GetTime, InCombatLockdown = nil, nil, nil
      -- Keep: at a merchant, bag items another character needs; after a sale, a Buy back offer.
      local other = { needs = { [197] = { name = "Tailoring", items = { [2589] = 12 } } } }
      ComradeCraftDB.chars["Mira-Realm"] = other
      me.bags = { [2589] = 30, [159] = 5 }
      local before = #notes
      ns.Alerts.CheckKeep()
      assert(#notes == before + 1 and notes[#notes].title == "Keep for your group", "keep: notice at the merchant")
      local mira
      for _, w in ipairs(ns.Alerts.Wanted(2589)) do if w.name == "Mira" then mira = w.n end end
      assert(mira == 12, "keep: who needs it " .. tostring(mira))
      assert(#ns.Alerts.Wanted(159) == 0, "keep: unneeded item")
      local bb = {}
      GetNumBuybackItems = function() return #bb end
      GetBuybackItemLink = function(i) return bb[i] end
      local bought
      BuybackItem = function(i) bought = i end
      ns.Alerts.CheckBuyback(true)
      bb = { "|cffffffff|Hitem:2589::|h[Linen Cloth]|h|r" }
      ns.Alerts.CheckBuyback()
      local bn = notes[#notes]
      assert(#notes == before + 2 and bn.buttons and bn.buttons[1][1] == "Buy back", "keep: buy back offer")
      bn.buttons[1][2]()
      assert(bought == 1, "keep: buy back clicks the right slot")
      ns.Alerts.CheckBuyback()
      assert(#notes == before + 2, "keep: one offer per sale")
      ComradeCraftDB.chars["Mira-Realm"], me.bags = nil, nil
      GetNumBuybackItems, GetBuybackItemLink, BuybackItem = nil, nil, nil
      -- mats: no alert on the first look, one when the next craft becomes ready
      local origQ, origN = ns.CraftQueue, ns.NextCraft
      local readyNow = false
      ns.CraftQueue = function() return {} end
      ns.NextCraft = function() if readyNow then return { spell = 2963, n = 2, ready = 2, item = 2996, label = "Bolt" } end end
      notes = {}
      ns.Alerts.CheckMats()
      readyNow = true
      ns.Alerts.CheckMats()
      ns.Alerts.CheckMats()
      assert(#notes == 1 and notes[1].title:find("mats ready", 1, true), "alerts: mats ready once")
      ns.CraftQueue, ns.NextCraft = origQ, origN
      -- upgrade (opt-in): Vez knows Bolt of Linen; pretend it is an upgrade for us
      local origUp = ns.UpgradeFor
      ns.UpgradeFor = function(item) if item == ns.Recipes[2963][5] then return true, 7, "pawn" end end
      notes = {}
      ns.Alerts.CheckUpgrades()
      assert(#notes == 0, "alerts: upgrade alert off by default")
      ns.Alerts.Set("upgrade", true)
      ns.Alerts.CheckUpgrades()
      ns.Alerts.CheckUpgrades()
      assert(#notes == 1 and notes[1].title:find("Vez", 1, true) and notes[1].text:find("+7", 1, true), "alerts: upgrade once")
      ComradeCraftRequestDialog:Hide()
      notes[1].buttons[1][2]()
      assert(ComradeCraftRequestDialog:IsShown(), "alerts: Ask for it opens the request dialog")
      ns.UpgradeFor, ns.Alerts.Notify = origUp, origNotify
      ns.Alerts.Set("upgrade", false)
      ComradeCraftDB.ui.sel = "manage"
      ns.RefreshWindow()
      for _, r in pairs(rqs) do r.acked = r.updated end -- (as if Vez acknowledged: later tests count messages)
      GetServerTime = nil
      c.shared = nil
      sent = {}
      From({ t = "R", v = 1, id = "peerVez", k = { "Test-Realm" } }, "Vez")
      assert(#sent == 0, "sync: unshared character never sent")
      From({ t = "D", v = 1, id = "peerVez", key = "Test-Realm", rec = { class = "MAGE" } }, "Vez")
      assert(not ComradeCraftDB.remote["Test-Realm"], "sync: our own characters cannot be overwritten")
      assert(ns.Sync.CleanRecord({ class = "<b>" }).class == nil, "sync: bad class rejected")
      ComradeCraftDB.ui.sel = "group"
      ns.RefreshWindow()
      IsInInstance = function() return true end
      sent = {}
      ns.Sync.AnnounceToGroup()
      assert(#sent == 0 and ns.Sync.QueueSize() == 1, "sync: queued inside an instance")
      IsInInstance = function() return false end
      f.onEvent(f, "ZONE_CHANGED_NEW_AREA")
      assert(#sent == 1 and ns.Sync.QueueSize() == 0, "sync: flushed after leaving")
      -- They upgrade "Vez" to "Vez Ironcrest": your kit target and favorite follow the new key.
      ComradeCraftDB.remote["Vez-Realm"].localTargets = { [197] = 60 }
      ComradeCraftDB.favorites = ComradeCraftDB.favorites or {}
      ComradeCraftDB.favorites["Vez-Realm"] = true
      ComradeCraftDB.requests = ComradeCraftDB.requests or {}
      ComradeCraftDB.requests["rn-1"] = { id = "rn-1", from = "Test-Realm", to = "Vez-Realm", spell = 2963, qty = 1,
        status = "pending", updated = 1 }
      c.reserved = { [2589] = { to = "Vez-Realm", qty = 3, t = 1 } }
      ComradeCraftDB.shopLists = ComradeCraftDB.shopLists or {}
      ComradeCraftDB.shopLists["Vez-Realm:197"] = "Tailoring"
      From({ t = "H", v = 1, id = "peerVez", c = { ["Vez Ironcrest-Realm"] = { u = 2 ^ 31 - 1, cl = "DRUID", lv = 20 } } }, "Vez")
      local vi = ComradeCraftDB.remote["Vez Ironcrest-Realm"]
      assert(vi and vi.localTargets and vi.localTargets[197] == 60 and not ComradeCraftDB.remote["Vez-Realm"]
        and ComradeCraftDB.favorites["Vez Ironcrest-Realm"] and not ComradeCraftDB.favorites["Vez-Realm"],
        "sync: a first-name key upgraded to the full name keeps your target and favorite")
      assert(ComradeCraftDB.requests["rn-1"].to == "Vez Ironcrest-Realm" and c.reserved[2589].to == "Vez Ironcrest-Realm"
        and ComradeCraftDB.shopLists["Vez Ironcrest-Realm:197"] and not ComradeCraftDB.shopLists["Vez-Realm:197"],
        "rename: requests, reservations and shopping lists follow")
      do
      local lateQ = ns.Requests.Clean({ rid = "rn-2", from = "Vez-Realm", to = "Test-Realm", spell = 2963, qty = 1,
        status = "pending", u = 5 })
      local lateR = ns.Sync.CleanRecord({ class = "DRUID", reserved = { [2589] = { t = "Vez-Realm", q = 2 } } })
      assert(lateQ.from == "Vez Ironcrest-Realm" and lateR.reserved[2589].to == "Vez Ironcrest-Realm",
        "rename: data arriving later with the old name lands on the new one")
      end
      ComradeCraftDB.requests["rn-1"], c.reserved, ComradeCraftDB.shopLists["Vez Ironcrest-Realm:197"] = nil, nil, nil
      From({ t = "D", v = 1, id = "peerVez", key = "Vez Ironcrest-Realm", rec = { class = "DRUID", updated = 2 ^ 31 - 1 } }, "Vez")
      assert(ComradeCraftDB.remote["Vez Ironcrest-Realm"].localTargets[197] == 60, "sync: target kept when their record arrives")
      assert(ns.Sync.UpgradedKey("Wo-R", { ["Wo A-R"] = {}, ["Wo B-R"] = {} }, {}) == nil
        and ns.Sync.UpgradedKey("Wo-R", { ["Wox A-R"] = {} }, {}) == nil, "sync: ambiguous or other first name: no rename")
      ComradeCraftDB.favorites["Vez Ironcrest-Realm"] = nil
      From({ t = "H", v = 1, id = "peerVez", c = {} }, "Vez")
      assert(not ComradeCraftDB.remote["Vez-Realm"] and not ComradeCraftDB.remote["Vez Ironcrest-Realm"],
        "sync: a character they stop sharing disappears")
      ns.Sync.Exclude("peerVez")
      assert(not ns.AllChars()["Vez-Realm"], "sync: excluded peer hidden")
      ns.RefreshWindow()

      -- Specialization: Classic talent tabs (name, icon, points) and Wrath shape (id, name, desc, icon, points).
      GetNumTalentTabs = function() return 3 end
      GetTalentTabInfo = function(t) return ({ "Arcane", "Fire", "Frost" })[t], "icon" .. t, ({ 2, 0, 14 })[t] end
      assert(ns.ScanSpec() == "Frost", "spec: classic shape")
      GetTalentTabInfo = function(t) return t, ({ "Balance", "Feral Combat", "Restoration" })[t], "", "i", ({ 0, 11, 3 })[t] end
      assert(ns.ScanSpec() == "Feral Combat", "spec: wrath shape")
      ns.ScanAll()
      assert(c.spec == "Feral Combat", "spec stored")
      assert(ns.Sync.CleanSummary({ sp = "Frost", p = {} }).sp == "Frost", "spec synced")
      GetNumTalentTabs, GetTalentTabInfo = nil, nil

      -- Manage view and filters render; the profession filter hides other professions.
      ComradeCraftDB.ui.sel = "manage"
      ns.RefreshWindow()
      ComradeCraftDB.ui.sel, ComradeCraftDB.ui.tab = "Test-Realm", "plan"
      ComradeCraftDB.ui.prof = 197
      ns.RefreshWindow()
      ComradeCraftDB.ui.prof = 333 -- not a profession of anyone: reset to all
      ComradeCraftDB.ui.sel = "group"
      ns.RefreshWindow()
      assert(ComradeCraftDB.ui.prof == nil, "filter: unknown profession resets to all")
      ComradeCraftDB.ui.hideGathering = false
      ns.RefreshWindow()
      ComradeCraftDB.ui.hideGathering = nil

      -- Group supply: spare = owned - own planned use; the asker is left out.
      local saved2 = ComradeCraftDB.chars
      ComradeCraftDB.chars = {
        ["A-R"] = { bags = { [2592] = 50 }, needs = { [197] = { gross = { [2592] = 20 }, items = {} } } },
        ["B-R"] = { bags = { [2592] = 5 }, bank = { [2592] = 5 }, needs = { [197] = { gross = { [2592] = 30 }, items = { [2592] = 20 } } } },
      }
      local tot, who = ns.GroupSupply(2592, "B-R")
      assert(tot == 30 and who[1].key == "A-R" and who[1].n == 30, "supply: A spares 30, B excluded")
      assert(ns.Surplus(ComradeCraftDB.chars["B-R"], 2592) == 0, "supply: B uses all its stock")
      local tt2 = { AddLine = function() end, Show = function() end, lines = {} }
      tt2.AddDoubleLine = function(self, l, r) self.lines[#self.lines + 1] = l .. "|" .. r end
      ns.AddNeeds(tt2, 2592)
      assert(tt2.lines[#tt2.lines]:find("A 30", 1, true), "supply: tooltip line, got " .. tostring(tt2.lines[#tt2.lines]))
      -- Give list: A's 30 spare go to B (needs 20, step 1), the rest to nobody.
      ComradeCraftDB.chars["B-R"].needs[197].when = { [2592] = 1 }
      ComradeCraftDB.chars["B-R"].needs[197].name = "Tailoring"
      local give = ns.GiveList("A-R")
      assert(#give == 1 and give[1].to == "B-R" and give[1].n == 20 and give[1].step == 1, "give: 20 to B, now")
      assert(#ns.GiveList("B-R") == 0, "give: B has no spare")
      -- Minimap summary and group view with a give list render without error.
      local mt = { AddLine = function() end, AddDoubleLine = function() end }
      local oldKey = ns.CharKey
      ns.CharKey = function() return "A-R" end
      ns.MinimapSummary(mt)
      ComradeCraftDB.ui.sel = "group"
      ns.RefreshWindow()
      ns.CharKey = oldKey
      ComradeCraftDB.chars = saved2
      -- Shared calibration: an added peer's skill-up totals count, a non-added one does not.
      ComradeCraftDB.skillups = { raw = {}, colors = { green = { n = 30, gained = 10, expected = 15 } } }
      ComradeCraftDB.peers.calib = { included = true, skillups = ns.Sync.CleanSkillups({ green = { 30, 20, 15 } }) }
      ComradeCraftDB.peers.other = { included = false, skillups = { green = { n = 100, gained = 0, expected = 50 } } }
      assert(ns.Calibration("green") == 1, "calibration: 60 crafts, 30 gained / 30 expected")
      assert(next(ns.Sync.CleanSkillups({ green = { 10, 50, 5 }, purple = { 1, 1, 1 } })) == nil,
        "calibration: gained > n and unknown colors rejected")
      ComradeCraftDB.peers.calib, ComradeCraftDB.peers.other, ComradeCraftDB.skillups = nil, nil, nil

      -- Mail: Vez needs 15 linen; our bags hold two stacks of 10. Expect a whole stack, then a
      -- split of 5, attached to free slots; recipient and subject filled; nothing sent.
      local saved3 = ComradeCraftDB.chars
      ComradeCraftDB.chars = {
        ["Test-Realm"] = { bags = { [2589] = 20 } },
        ["Vez Stone-Realm"] = { needs = { [197] = { name = "T", items = { [2589] = 15 }, when = { [2589] = 1 } } } },
      }
      local slots = { [1] = { itemID = 2589, stackCount = 10 }, [2] = { itemID = 2589, stackCount = 10 } }
      local attached, cursor, ops = {}, nil, {}
      local oldC = C_Container
      C_Container = {
        GetContainerNumSlots = function(bag) return bag == 0 and 2 or 0 end,
        GetContainerItemInfo = function(bag, slot) return bag == 0 and slots[slot] or nil end,
        PickupContainerItem = function(_, slot) cursor = { slots[slot].itemID, slots[slot].stackCount }; slots[slot] = nil; ops[#ops + 1] = "pick" .. slot end,
        SplitContainerItem = function(_, slot, n)
          cursor = { slots[slot].itemID, n }
          slots[slot] = { itemID = slots[slot].itemID, stackCount = slots[slot].stackCount - n }
          ops[#ops + 1] = "split" .. slot .. ":" .. n
        end,
      }
      GetSendMailItem = function(i) return attached[i] and "x" or nil end
      ClickSendMailItemButton = function(i) attached[i] = cursor; cursor = nil end
      CursorHasItem = function() return cursor ~= nil end
      ClearCursor = function() cursor = nil end
      local oldTimer = C_Timer
      C_Timer = { After = function(_, fn) fn() end }
      SendMailFrame = MockWidget()
      SendMailNameEditBox, SendMailSubjectEditBox = MockWidget(), MockWidget()
      SendMailNameEditBox.text, SendMailSubjectEditBox.text = "", ""
      f.onEvent(f, "MAIL_SHOW")
      assert(ns.Mail.KeyForName("vez stone") == "Vez Stone-Realm", "mail: name match")
      ns.Mail.Prepare("Vez Stone-Realm")
      assert(ops[1] == "pick1" and ops[2] == "split2:5", "mail: whole stack then split, got " .. table.concat(ops, ","))
      assert(attached[1][2] == 10 and attached[2][2] == 5 and cursor == nil, "mail: 10 + 5 attached, cursor clear")
      assert(SendMailNameEditBox.text == "Vez Stone" and SendMailSubjectEditBox.text == "ComradeCraft", "mail: form filled")
      f.onEvent(f, "MAIL_CLOSED")
      ns.Mail.Prepare("Vez Stone-Realm") -- closed: only a message
      C_Container, C_Timer = oldC, oldTimer
      ComradeCraftDB.chars = saved3

      -- Disenchant: yields by required level and type; advice keeps ONE cheapest enchant target
      -- per slot the plan needs, keeps gear for a member it fits, disenchants the rest.
      local oldGII = GetItemInfo
      local ITEMS = {
        [90001] = { "Cheap Bracers", 2, 12, "INVTYPE_WRIST", 10, 4, 2 },   -- quality, reqLevel, equipLoc, sell, class, subclass
        [90002] = { "Fine Bracers", 2, 12, "INVTYPE_WRIST", 50, 4, 2 },
        [90003] = { "Green Sword", 2, 12, "INVTYPE_WEAPON", 30, 2, 7 },
        [90004] = { "Cloth Robe", 2, 18, "INVTYPE_ROBE", 40, 4, 1 },
        [90005] = { "Blue Ring", 3, 12, "INVTYPE_FINGER", 90, 4, 0 },
      }
      GetItemInfo = function(id)
        local t = ITEMS[id]
        if t then return t[1], "|Hitem:" .. id .. "|h", t[2], 20, t[3], "", "", 1, t[4], 0, t[5], t[6], t[7] end
        return oldGII(id)
      end
      local ya = ns.DisenchantYield(90001)
      assert(math.abs(ya[10940] - 1.875) < 1e-9 and math.abs(ya[10939] - 0.3) < 1e-9, "de: armor 75% dust 20% essence")
      local yw = ns.DisenchantYield(90003)
      assert(math.abs(yw[10940] - 0.5) < 1e-9 and math.abs(yw[10939] - 1.125) < 1e-9, "de: weapon reversed")
      assert(ns.DisenchantYield(90005)[10978] == 1, "de: rare gives one shard")
      assert(ns.DisenchantYield(2589) == nil, "de: cloth (trade good) is not disenchantable")
      local saved4 = ComradeCraftDB.chars
      ComradeCraftDB.chars = {
        ["Test-Realm"] = { class = "WARRIOR", level = 20, bags = { [90001] = 1, [90002] = 1, [90003] = 1, [90004] = 1 },
          professions = { Enchanting = { skillLine = 333, rank = 60, max = 75 } },
          needs = { [333] = { name = "Enchanting", items = {}, plan = { { spell = 7418, subs = {} } } } } },
        ["Mage-Realm"] = { class = "MAGE", level = 20, needs = { [333] = { name = "Enchanting", items = { [10940] = 9 } } } },
      }
      local adv = {}
      for _, a in ipairs(ns.BagAdvice("Test-Realm")) do adv[a.item] = a end
      assert(adv[90001].verdict == "target" and adv[90002].verdict == "disenchant", "de: cheapest bracers kept as target")
      assert(adv[90004].verdict == "gear" and adv[90004].to == "Mage-Realm", "de: robe kept for the mage")
      assert(adv[90003].verdict == "disenchant" and adv[90003].useful, "de: sword disenchanted, dust is needed")
      ComradeCraftDB.ui.sel = "group"
      ns.RefreshWindow()
      ComradeCraftDB.chars = saved4
      -- Logging: bag diff finds the source; loot recorded with item facts.
      assert(ns.DisenchantedItem({ [90001] = 1, [2589] = 5 }, { [2589] = 5, [10940] = 2 }, { [10940] = 2 }) == 90001,
        "de: source found by bag diff")
      local bagNow = { [90002] = 1 }
      local oldScan = ns.ScanBagContents
      ns.ScanBagContents = function() return bagNow end
      GetNumLootItems = function() return 1 end
      GetLootSlotLink = function() return "|Hitem:10940:0|h" end
      GetLootSlotInfo = function() return nil, nil, 2 end
      C_Timer = { After = function(_, fn) fn() end }
      f.onEvent(f, "UNIT_SPELLCAST_START", "player", "g", 13262)
      bagNow = {}
      f.onEvent(f, "LOOT_OPENED")
      f.onEvent(f, "LOOT_CLOSED")
      local dl = ComradeCraftDB.disenchants.raw[1]
      assert(dl and dl.item == 90002 and dl.loot[10940] == 2 and dl.quality == 2, "de: disenchant logged")
      ns.ScanBagContents, GetItemInfo = oldScan, oldGII

      -- Urgency: first plan step using an item; most-wanted sorts now < soon < later, then size.
      local when = ns.FirstStepOf({ { spell = 2963, subs = {} }, { spell = 2385, subs = { [2963] = 1 } } })
      assert(when[2589] == 1 and when[2320] == 2, "urgency: first step per item")
      assert(ns.Urgency(1) == "now" and ns.Urgency(4) == "soon" and ns.Urgency(5) == "later"
        and ns.Urgency(nil) == "later", "urgency buckets")
      local saved = ComradeCraftDB.chars
      ComradeCraftDB.chars = {
        ["A-R"] = { needs = { [197] = { name = "T", items = { [111] = 100 }, when = { [111] = 6 } } } },
        ["B-R"] = { needs = { [197] = { name = "T", items = { [222] = 5, [111] = 3 }, when = { [222] = 1, [111] = 3 } } } },
      }
      local gm2 = ns.GroupMaterials()
      assert(gm2[1].item == 222 and gm2[2].item == 111, "urgency: urgent small need first")
      assert(gm2[2].step == 3 and gm2[2].by[1].key == "B-R", "urgency: soonest needer first in the breakdown")
      ComradeCraftDB.chars = saved

      -- Group plan (1) objective: Spare-R can spare 1000 linen. "group" makes bolts free and
      -- grinds them; "solo" (or no stock) keeps the vest, fewest mats per point, as before.
      local savedF, oldPSF = ComradeCraftDB.chars, ns.PriceSource
      ComradeCraftDB.chars = {
        ["Test-Realm"] = { bags = { [2320] = 50 } },
        ["Spare-R"] = { bags = { [2589] = 1000 }, bank = { [2589] = 10 }, needs = { [197] = { gross = { [2589] = 10 }, items = {} } } },
      }
      ns.PriceSource = function(item) return ({ [2589] = 100 })[item] end
      local gst = ns.GroupStock(ComradeCraftDB.chars["Test-Realm"])
      assert(gst[2589] == 1000 and gst[2320] == nil, "group plan: stock = the others' spare, vendor thread left out")
      local kv = { [2963] = true, [2385] = true }
      local gn0, _, gp0 = ns.ComputeNeeds(1, 10, kv, nil, nil, nil, "cheap")
      local gn1, _, gp1 = ns.ComputeNeeds(1, 10, kv, nil, nil, nil, "cheap", { [99999] = 5 })
      local _, _, gpg = ns.ComputeNeeds(1, 10, kv, nil, nil, nil, "cheap", gst)
      assert(gp0[1].spell == 2385 and gp1[1].spell == 2385 and #gp0 == #gp1 and gn0[2589] == gn1[2589],
        "group plan: no usable stock = unchanged route")
      assert(gpg[1].spell == 2963 and #gpg == 1, "group plan: the group's linen makes bolts cheaper, got " .. gpg[1].spell)
      -- Same through UpdateNeeds: the character's route follows the objective.
      local tF = ComradeCraftDB.chars["Test-Realm"]
      tF.professions, tF.known = { Tailoring = { skillLine = 197, rank = 1, max = 10 } }, { [197] = kv }
      ns.UpdateNeeds(tF)
      local groupFirst = tF.needs[197].plan[1].spell
      ComradeCraftDB.settings.groupObjective = "solo"
      ns.UpdateNeeds(tF)
      local soloFirst = tF.needs[197].plan[1].spell
      ComradeCraftDB.settings.groupObjective = nil
      assert(groupFirst == 2963 and soloFirst ~= 2963, "group plan: UpdateNeeds follows the objective, got "
        .. groupFirst .. "/" .. soloFirst)
      tF.professions, tF.known, tF.needs = nil, nil, nil
      ns.SetGroupObjective("solo")
      assert(ns.GroupObjective() == "solo" and ComradeCraftDB.settings.groupObjective == "solo", "group plan: objective stored")
      ns.SetGroupObjective("group")
      assert(ns.GroupObjective() == "group", "group plan: objective back to group")
      -- (2) synced farm table: valid entries kept, bad ones dropped, 40 at most.
      local cr = ns.Sync.CleanRecord({ class = "MAGE", farm = { [2589] = 30, [2592] = 0, x = 5, [2593] = -2 } })
      assert(cr.farm and cr.farm[2589] == 30 and cr.farm[2592] == nil and cr.farm.x == nil and cr.farm[2593] == nil,
        "group plan: farm cleaned")
      assert(ns.Sync.CleanRecord({ class = "MAGE", farm = "x" }).farm == nil
        and ns.Sync.CleanRecord({ farm = { [2589] = "lots" } }).farm == nil, "group plan: bad farm dropped")
      local bigF, nF = {}, 0
      for i = 1, 60 do bigF[1000 + i] = 1 end
      for _ in pairs(ns.Sync.CleanRecord({ farm = bigF }).farm) do nF = nF + 1 end
      assert(nF == 40, "group plan: farm capped at 40, got " .. nF)
      -- (3) assignments: tracker line, x drops it; the dialog's Yes assigns; done = one notice.
      local notesF, origNotifyF = {}, ns.Alerts.Notify
      ns.Alerts.Notify = function(t) notesF[#notesF + 1] = t end
      local meF = ComradeCraftDB.chars["Test-Realm"]
      meF.bags = { [2589] = 3 }
      ns.FarmAssign(2589, 20)
      local fa = ComradeCraftDB.farm[2589]
      assert(fa and fa.target == 20 and fa.char == "Test-Realm" and meF.updated, "farm: assigned")
      local fl = ns.Farmers(2589)
      assert(#fl == 1 and fl[1].own and fl[1].key == "Test-Realm" and fl[1].target == 20, "farm: farmer listed")
      local ftr = ComradeCraftFarmTracker
      -- The 3 already held do not count: progress starts at 0.
      assert(ftr and ftr:IsShown() and ftr.lines[1].text.text:find("0/20", 1, true), "farm: tracker line "
        .. tostring(ftr and ftr.lines[1].text.text))
      ns.SetFarmTracker(false)
      assert(not ftr:IsShown(), "farm: tracker turned off")
      ns.SetFarmTracker(true)
      assert(ftr:IsShown(), "farm: tracker back on")
      ftr.lines[1].drop.scripts.OnClick(ftr.lines[1].drop)
      assert(ComradeCraftDB.farm[2589] == nil and not ftr:IsShown(), "farm: x drops it, tracker hidden")
      ns.ShowFarmDialog(2589, 5, "Vez")
      assert(ComradeCraftFarmDialog.text.text == "5 Item2589 needed for Vez. Do you want to farm them?", "farm: dialog text")
      ComradeCraftFarmDialog.yes.scripts.OnClick(ComradeCraftFarmDialog.yes)
      assert(ComradeCraftDB.farm[2589] and ComradeCraftDB.farm[2589].target == 5 and #notesF == 0, "farm: Yes assigns")
      meF.bags[2589] = 10
      ns.RefreshFarm()
      ns.RefreshFarm()
      assert(#notesF == 1 and notesF[1].title == "Farming done: Item2589" and ComradeCraftDB.farm[2589] == nil
        and not ftr:IsShown(), "farm: done once, cleared")
      -- (4) Group plan view: Need-R needs 50 wool and 8 linen; Spare-R spares 20 wool; we farm the
      -- linen, Vez (a peer) farms the wool. Rows, tooltip lines and the view render.
      ComradeCraftDB.chars["Need-R"] = { class = "MAGE", needs = { [197] = { name = "Tailoring",
        items = { [2592] = 50, [2589] = 8, [2996] = 4 }, gross = { [2592] = 50, [2589] = 8 }, when = { [2592] = 1, [2589] = 2 } } } }
      ComradeCraftDB.chars["Spare-R"] = { bags = { [2592] = 20 } }
      ComradeCraftDB.peers = ComradeCraftDB.peers or {}
      ComradeCraftDB.peers.pvF = { included = true }
      ComradeCraftDB.remote = ComradeCraftDB.remote or {}
      ComradeCraftDB.remote["Vez-Realm"] = ns.Sync.CleanRecord({ class = "DRUID", farm = { [2592] = 30 } })
      ComradeCraftDB.remote["Vez-Realm"].peer = "pvF"
      meF.bags = {}
      ns.FarmAssign(2589, 8)
      -- A shared character's record carries its assignments to the group.
      meF.shared = true
      sent = {}
      From({ t = "R", v = 1, id = "pvF", k = { "Test-Realm" } }, "Vez")
      local dF = OfType("D")[1]
      assert(dF and dF.msg.rec.farm and dF.msg.rec.farm[2589] == 8, "group plan: farm sent with the record")
      meF.shared = nil
      local gpl, gtot, gall, gany = ns.GroupPlan()
      local byItem = {}
      for _, r in ipairs(gpl) do byItem[r.item] = r end
      local wool, linen = byItem[2592], byItem[2589]
      assert(wool and wool.total == 50 and wool.spare == 20 and wool.toGet == 30 and wool.cost == nil
        and wool.farmers[1].key == "Vez-Realm", "group plan: wool row")
      assert(linen and linen.toGet == 8 and linen.cost == 800 and linen.farmers[1].own, "group plan: linen row")
      assert(gtot == 800 and gall == false and gany == true, "group plan: total 800, partial")
      local ptt = { lines = {}, AddLine = function() end }
      ptt.AddDoubleLine = function(self, l, r) self.lines[#self.lines + 1] = l .. "|" .. r end
      ns.AddPlanLines(ptt, wool)
      local pj = table.concat(ptt.lines, " / ")
      assert(pj:find("needs 50", 1, true) and pj:find("Spare-R", 1, false) == nil and pj:find("Spare", 1, true)
        and pj:find("Farmed by Vez|30", 1, true), "group plan: tooltip " .. pj)
      local itt = { lines = {}, AddLine = function() end, Show = function() end }
      itt.AddDoubleLine = function(self, l, r) self.lines[#self.lines + 1] = l .. "|" .. r end
      ns.AddNeeds(itt, 2592)
      assert(itt.lines[#itt.lines] == "Farmed by Vez|30", "group plan: item tooltip " .. tostring(itt.lines[#itt.lines]))
      if not ComradeCraftFrame:IsShown() then SlashCmdList.COMRADECRAFT("") end
      ComradeCraftDB.ui.sel = "groupplan"
      ns.RefreshWindow()
      assert(ComradeCraftDB.ui.sel == "groupplan" and ComradeCraftFrame.title.text == "Group plan", "group plan: view rendered")
      ComradeCraftDB.ui.sel = "manage"
      ns.RefreshWindow()
      ComradeCraftDB.ui.sel = "group"
      ns.RefreshWindow()
      ns.Alerts.Notify, ns.PriceSource = origNotifyF, oldPSF
      ComradeCraftDB.farm, ComradeCraftDB.remote["Vez-Realm"], ComradeCraftDB.peers.pvF = nil, nil, nil
      ComradeCraftDB.chars = savedF
      ns.RefreshFarm()

      -- Guild directory: opt-in per character, its own storage, validated, debounced, whispered catch-up.
      local dme = ns.CharData()
      local dSaved = { dme.professions, dme.known }
      dme.professions = { Tailoring = { skillLine = 197, rank = 80, max = 150 } }
      dme.known = { [197] = { [2963] = true } }
      local function FromD(msg, sender, dist) ns.Sync.OnMessage(ns.Sync.Encode(msg), dist or "GUILD", sender) end
      local function Dir() return OfType("G") end
      sent = {}
      ns.Directory.Flush()
      ns.Directory.Broadcast()
      FromD({ t = "P", v = 1, id = "gPing" }, "Pinger")
      assert(#Dir() == 0, "directory: nothing sent while no character is listed")
      SlashCmdList.COMRADECRAFT("list")
      local g1 = Dir()[1]
      assert(#Dir() == 1 and g1.dist == "GUILD" and g1.msg.c["Test-Realm"].r[197][1] == 2963
        and g1.msg.c["Test-Realm"].p[197][1] == 80, "directory: listing broadcasts on the guild")
      sent = {}
      dme.updated = (dme.updated or 0) + 10
      ns.Directory.MarkDirty()
      ns.Directory.Flush()
      assert(#Dir() == 0, "directory: a bag-only change does not rebroadcast")
      dme.known[197][2385] = true
      ns.Directory.Flush()
      assert(#Dir() == 1 and #Dir()[1].msg.c["Test-Realm"].r[197] == 2, "directory: a new recipe rebroadcasts")
      sent = {}
      ns.Directory.Broadcast() -- the login broadcast (PLAYER_LOGIN is not fired here)
      assert(#Dir() == 1 and Dir()[1].dist == "GUILD", "directory: login broadcast while listed")
      -- Account-wide SavedVariables: an alt listed in another guild is not sent, and entries
      -- received in guild A are hidden while playing in guild B.
      GetGuildInfo = function() return "GuildA" end
      ComradeCraftDB.chars["Alt-Realm"] = { listed = true, guild = "GuildB", class = "MAGE",
        professions = { Tailoring = { skillLine = 197, rank = 5, max = 75 } }, known = { [197] = { [2963] = true } } }
      sent = {}
      ns.Directory.Broadcast()
      assert(Dir()[1].msg.c["Test-Realm"] and not Dir()[1].msg.c["Alt-Realm"], "directory: alt of another guild not sent")
      FromD({ t = "G", v = 1, id = "gA", c = { ["Gil-Realm"] = { cl = "MAGE", p = { [197] = { 50, 75 } }, r = { [197] = { 2963 } } } } }, "Gil")
      ns.Directory.Flush()
      assert(ns.Directory.Index().chars["Gil-Realm"], "directory: guild A entry shown in guild A")
      GetGuildInfo = function() return "GuildB" end
      ns.handlers.PLAYER_GUILD_UPDATE()
      local idxB = ns.Directory.Index().chars
      assert(not idxB["Gil-Realm"] and idxB["Alt-Realm"], "directory: guild B shows its own entries only")
      GetGuildInfo = nil
      ComradeCraftDB.chars["Alt-Realm"], ComradeCraftDB.directory["Gil-Realm"] = nil, nil
      dme.guild = nil
      ns.Directory.Broadcast()
      sent = {}
      -- Received: cleaned, kept apart from the group data; own keys and malformed entries dropped.
      FromD({ t = "G", v = 1, id = "gAcc", c = {
        ["Mira-Realm"] = { cl = "MAGE", lv = 30, p = { [197] = { 120, 150, "Tailoring" } }, r = { [197] = { 2963, 999999, 2657 }, [164] = { 2663 } } },
        ["bad|key"] = { cl = "MAGE", p = {} }, ["Junk-Realm"] = "x", ["Test-Realm"] = { cl = "MAGE", p = {} } } }, "Mira")
      local dir = ComradeCraftDB.directory
      local dm = dir["Mira-Realm"]
      assert(dm and dm.peer == "gAcc" and dm.name == "Mira" and dm.r[2963] and not dm.r[999999] and not dm.r[2657]
        and not dm.r[2663] and dm.p[197][1] == 120 and dm.cl == "MAGE", "directory: entry cleaned (unknown spell, wrong skill line)")
      assert(not dir["bad|key"] and not dir["Junk-Realm"] and not dir["Test-Realm"], "directory: malformed and own keys dropped")
      assert(not ns.AllChars()["Mira-Realm"] and not ComradeCraftDB.remote["Mira-Realm"], "directory: never in the group data")
      FromD({ t = "G", v = 1, id = "gAcc2", c = "nope" }, "Bad")
      FromD({ t = "G", v = 1, id = "gAcc2", c = { ["Odd-Realm"] = { cl = "<b>", lv = "x", p = { [197] = "y" }, r = { [197] = { 2963 } } } } }, "Bad")
      assert(dir["Odd-Realm"] and dir["Odd-Realm"].cl == nil and not next(dir["Odd-Realm"].r), "directory: bad fields dropped")
      local many = {}
      for i = 1, 60 do many["C" .. i .. "-Realm"] = { cl = "MAGE", p = {} } end
      FromD({ t = "G", v = 1, id = "gAcc2", c = many }, "Bad")
      local nMany = 0
      for _, e in pairs(dir) do if e.peer == "gAcc2" then nMany = nMany + 1 end end
      assert(nMany == 50 and not dir["Odd-Realm"], "directory: 50 characters per account, replaced, got " .. nMany)
      -- Whispered entries only shortly after our own guild ping.
      local realTime = time
      time = function() return realTime() + 3600 end
      local wis = { t = "G", v = 1, id = "gW", c = { ["Wis-Realm"] = { cl = "MAGE", p = { [197] = { 1, 75 } }, r = {} } } }
      FromD(wis, "Wis", "WHISPER")
      assert(not dir["Wis-Realm"], "directory: whisper outside the ping window dropped")
      ns.Sync.Announce()
      FromD(wis, "Wis", "WHISPER")
      assert(dir["Wis-Realm"], "directory: whispered answer to our ping kept")
      time = realTime
      dir["Wis-Realm"].seen = time() - 31 * 86400
      FromD({ t = "G", v = 1, id = "gAcc3", c = {} }, "Other")
      assert(not dir["Wis-Realm"] and dir["Mira-Realm"], "directory: entries unseen for 30 days expire")
      -- Catch-up: a guildmate's login ping gets one whispered entry (cooldown).
      sent = {}
      FromD({ t = "P", v = 1, id = "gPing" }, "Pinger")
      FromD({ t = "P", v = 1, id = "gPing" }, "Pinger")
      FromD({ t = "P", v = 1, id = "gPing2" }, "Pinger2", "WHISPER")
      assert(#Dir() == 1 and Dir()[1].dist == "WHISPER" and Dir()[1].target == "Pinger", "directory: one whispered answer to a guild ping")
      -- Search, tooltip, whisper, view and commands.
      local bolt2 = ns.Recipes[2963][5]
      local found = ns.Directory.Search("item" .. bolt2)
      local fm = false
      for _, k in ipairs(found[1] and found[1].crafters or {}) do if k == "Mira-Realm" then fm = true end end
      assert(found[1] and found[1].spell == 2963 and fm, "directory: search by product name")
      local dtt = { lines = {}, AddDoubleLine = function() end, Show = function() end }
      dtt.AddLine = function(self, l) self.lines[#self.lines + 1] = l end
      ns.OnItemTooltip(dtt, bolt2)
      local dl = dtt.lines[#dtt.lines] or ""
      assert(dl:find("Guild crafters: ", 1, true) and dl:find("Mira", 1, true), "directory: tooltip line " .. dl)
      local opened
      ChatFrame_OpenChat = function(t) opened = t end
      ns.Directory.Whisper("Mira-Realm")
      assert(opened == "/w Mira " and not ns.Directory.WhisperTarget("Test-Realm") and not ns.Directory.CanRequest("Mira-Realm"),
        "directory: whisper the crafter, no request outside the group")
      ChatFrame_OpenChat = nil
      if not ComradeCraftFrame:IsShown() then SlashCmdList.COMRADECRAFT("") end
      ComradeCraftDB.ui.sel = "directory"
      ComradeCraftFrame.search.text = "item" .. bolt2
      ns.RefreshWindow()
      assert(ComradeCraftDB.ui.sel == "directory" and ComradeCraftFrame.title.text == "Guild directory", "directory: view rendered")
      ComradeCraftFrame.search.text = nil
      ns.RefreshWindow()
      ComradeCraftDB.ui.sel = "manage"
      ns.RefreshWindow()
      SlashCmdList.COMRADECRAFT("directory item" .. bolt2)
      SlashCmdList.COMRADECRAFT("directory")
      -- An empty entry removes that account's characters; unlisting sends one, then nothing.
      FromD({ t = "G", v = 1, id = "gAcc", c = {} }, "Mira")
      assert(not dir["Mira-Realm"], "directory: empty entry removes that account's characters")
      sent = {}
      SlashCmdList.COMRADECRAFT("list off")
      assert(#Dir() == 1 and Dir()[1].dist == "GUILD" and next(Dir()[1].msg.c) == nil, "directory: unlisting broadcasts an empty entry")
      sent = {}
      ns.Directory.Broadcast()
      ns.Directory.Flush()
      assert(#Dir() == 0, "directory: nothing more once unlisted")
      IsInGuild = function() return false end
      SlashCmdList.COMRADECRAFT("list")
      assert(#Dir() == 0, "directory: nothing sent outside a guild")
      IsInGuild = function() return true end
      dme.listed, ComradeCraftDB.directory, ComradeCraftDB.directoryAnnounced = nil, nil, nil
      dme.professions, dme.known = dSaved[1], dSaved[2]
      for _, id in ipairs({ "gAcc", "gAcc2", "gAcc3", "gW", "gPing", "gPing2" }) do ComradeCraftDB.peers[id] = nil end
      ComradeCraftDB.ui.sel = "group"
      ns.RefreshWindow()

      ;(function() -- Friends add flow + Bags highlight + Mail recipient focus + enriched tooltips.
      assert(not ns.Sync.AddByName("Test"), "sync: cannot add self")
      sent = {}
      assert(ns.Sync.AddByName("Nova"), "sync: pending add")
      local pend = ns.Sync.PendingAdds()
      assert(#pend == 1 and pend[1].name == "Nova", "sync: pending list")
      GetNumGroupMembers = function() return 1 end
      UnitExists = function(u) return u == "party1" end
      UnitName = function(u) return u == "party1" and "PartyPal" or "Test" end
      UnitClass = function() return "Mage", "MAGE" end
      C_FriendList = {
        GetNumFriends = function() return 2 end,
        GetFriendInfoByIndex = function(i)
          return i == 1 and { name = "FriendOnline", connected = true } or { name = "Nova", connected = true }
        end,
      }
      local qc = ns.Sync.QuickAddCandidates()
      assert(#qc == 2 and qc[1].name == "PartyPal" and qc[1].source == "party"
        and qc[2].name == "FriendOnline" and qc[2].source == "friend", "sync: quick add excludes pending, party first")
      ns.Sync.CancelAdd("nova")
      assert(#ns.Sync.PendingAdds() == 0, "sync: cancel pending add")
      -- Share all / none + autoShareNew for new alts.
      ComradeCraftDB.chars["Alt2-Realm"] = { class = "WARRIOR", level = 15 }
      SlashCmdList.COMRADECRAFT("share all")
      assert(ComradeCraftDB.chars["Test-Realm"].shared and ComradeCraftDB.chars["Alt2-Realm"].shared, "sync: share all")
      SlashCmdList.COMRADECRAFT("share none")
      assert(not ComradeCraftDB.chars["Test-Realm"].shared and not ComradeCraftDB.chars["Alt2-Realm"].shared, "sync: share none")
      ComradeCraftDB.settings.autoShareNew = true
      UnitName = function() return "FreshAlt" end
      assert(ns.CharData().shared == true, "core: autoShareNew shares newly created character")
      ComradeCraftDB.chars["FreshAlt-Realm"], ComradeCraftDB.chars["Alt2-Realm"], ComradeCraftDB.settings.autoShareNew = nil, nil, nil
      ComradeCraftDB.chars["Test-Realm"].shared = true
      -- Broken "Name-" and spaced vs normalized realm duplicates are merged (newest data + share flags kept).
      ComradeCraftDB.chars["Test-"] = { class = "MAGE", level = 26, listed = true, updated = 1 }
      ComradeCraftDB.chars["Dup-My Realm PvE"] = { class = "MAGE", level = 26, shared = true, updated = 100 }
      ComradeCraftDB.chars["Dup-MyRealmPvE"] = { class = "MAGE", level = 29, updated = 200 }
      f.onEvent(f, "PLAYER_ENTERING_WORLD")
      assert(ComradeCraftDB.chars["Test-"] == nil and ComradeCraftDB.chars["Test-Realm"].listed == true,
        "core: broken trailing-dash char key merged and removed")
      assert(ComradeCraftDB.chars["Dup-MyRealmPvE"] == nil and ComradeCraftDB.chars["Dup-My Realm PvE"]
        and ComradeCraftDB.chars["Dup-My Realm PvE"].level == 29 and ComradeCraftDB.chars["Dup-My Realm PvE"].shared == true,
        "core: spaced vs normalized realm duplicate merged keeping newest level and shared flag")
      ComradeCraftDB.chars["Dup-My Realm PvE"] = nil
      ComradeCraftDB.chars["Test-Realm"].listed = nil
      -- Trainer refusal (GOSSIP_SHOW with 0 options) and scanned trainer spell filtering.
      local origProfsT = ComradeCraftDB.chars["Test-Realm"].professions
      ComradeCraftDB.chars["Test-Realm"].professions = { Tailoring = { skillLine = 197, rank = 115, max = 150 } }
      UnitGUID = function() return "Creature-0-562-0-1-1346-AAAFD0FD82" end
      UnitName = function(u) return u == "npc" and "Georgio Bolero" or "Test" end
      strsplit = function(sep, s)
        local t = {}
        for part in (s .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do t[#t + 1] = part end
        return unpack(t)
      end
      C_GossipInfo = { GetOptions = function() return {} end }
      f.onEvent(f, "GOSSIP_SHOW")
      assert(ComradeCraftDB.trainerRefused and ComradeCraftDB.trainerRefused[1346], "trainer: refusal recorded")
      local has1346 = false
      for _, e in ipairs((ns.RecipeSources(3848) or {}).trainer and ns.RecipeSources(3848).trainer.list or {}) do
        if e.id == 1346 then has1346 = true end
      end
      assert(not has1346, "trainer: refused NPC excluded at current rank")
      ComradeCraftDB.chars["Test-Realm"].professions.Tailoring.rank = 125
      for _, e in ipairs((ns.RecipeSources(3848) or {}).trainer and ns.RecipeSources(3848).trainer.list or {}) do
        if e.id == 1346 then has1346 = true end
      end
      assert(has1346, "trainer: refused NPC eligible again after leveling up")
      ComradeCraftDB.trainerSpots = { [1346] = { name = "Georgio Bolero", line = 197, scanned = true, spells = { [2385] = true }, maxReq = 125 } }
      has1346 = false
      for _, e in ipairs((ns.RecipeSources(3848) or {}).trainer and ns.RecipeSources(3848).trainer.list or {}) do
        if e.id == 1346 then has1346 = true end
      end
      assert(not has1346, "trainer: scanned NPC without spell excluded")
      assert(ns.TrainerRecipes(197, 150, {})[3848] == nil, "trainer: absent from tier trainer excluded from plan")
      ComradeCraftDB.trainerSpots = nil
      ComradeCraftDB.skippedLearn = { [3848] = true }
      assert(ns.TrainerRecipes(197, 150, {})[3848] == nil, "trainer: user-skipped recipe excluded from plan")
      -- NEW_RECIPE_LEARNED immediately learns the recipe and clears skippedLearn.
      f.onEvent(f, "NEW_RECIPE_LEARNED", 3848)
      assert(ComradeCraftDB.chars["Test-Realm"].known[197][3848] and not ComradeCraftDB.skippedLearn[3848],
        "scan: NEW_RECIPE_LEARNED updates known recipes immediately")
      ComradeCraftDB.chars["Test-Realm"].known[197][3848] = nil
      ComradeCraftDB.skippedLearn = nil
      -- BoP items: no AH resale in Profitable, not shared/given to others.
      local origGetItemInfoB = GetItemInfo
      local origPSB = ns.PriceSource
      ns.PriceSource = function() return 50000 end
      GetItemInfo = function(id)
        if id == 99998 then return "BoPItem", "|Hitem:99998|h", 2, 20, 1, "", "", 1, "", 134400, 500, 0, 0, 1 end
        return origGetItemInfoB(id)
      end
      assert(ns.IsBoP(99998), "bop: detected via bindType 1")
      local bo = ns.ResaleOptions(99998)
      assert(bo.ah == nil and bo.vendor == 500, "bop: no AH resale, vendor price kept")
      assert(ns.GroupSupply(99998) == 0, "bop: never counted as shareable group supply")
      GetItemInfo, ns.PriceSource = origGetItemInfoB, origPSB
      ComradeCraftDB.trainerRefused, ComradeCraftDB.trainerSpots = nil, nil
      ComradeCraftDB.chars["Test-Realm"].professions = origProfsT
      UnitGUID, strsplit, C_GossipInfo = nil, nil, nil
      GetNumGroupMembers, UnitExists, C_FriendList = nil, nil, nil
      UnitName = function() return "Test" end

      local bMe = ns.CharData()
      local savedBags = bMe.bags
      bMe.bags = { [2592] = 15, [99999] = 1 }
      ComradeCraftDB.chars["Vez-Realm"] = { class = "DRUID", level = 20, professions = {},
        needs = { [197] = { name = "Tailoring", items = { [2592] = 10 }, when = { [2592] = 1 },
          plan = { { spell = 2963 } } } } }
      local savedNeedsB = bMe.needs
      bMe.needs = {} ns.ClearGiveCache() -- about Vez's needs: ours must not depend on earlier tests
      local stGive = ns.Bags.ItemState(2592)
      assert(stGive and stGive.mode == "give" and stGive.urgency == 1, "bags: spare item flagged for group")
      assert(ns.Bags.ItemState(99999) == nil, "bags: unneeded item not flagged")
      local recips = ns.Mail.Recipients()
      assert(#recips == 1 and recips[1].key == "Vez-Realm" and recips[1].items == 1, "mail: recipients list")
      MailFrame = MockWidget()
      SendMailFrame = MockWidget()
      SendMailNameEditBox = MockWidget()
      SendMailSubjectEditBox = MockWidget()
      f.onEvent(f, "MAIL_SHOW")
      SendMailNameEditBox:SetText("Vez")
      assert(ns.Mail.CurrentRecipient() == "Vez-Realm", "mail: active recipient from SendMailNameEditBox")
      local stFocus = ns.Bags.ItemState(2592, "Vez-Realm")
      assert(stFocus and stFocus.mode == "focus" and stFocus.entry.prof == "Tailoring" and stFocus.entry.spell == 2963,
        "bags: recipient focus includes profession and recipe")
      local mtt = { lines = {}, Show = function() end }
      mtt.AddLine = function(self, l) if l then self.lines[#self.lines + 1] = l end end
      mtt.AddDoubleLine = function(self, l, r) self.lines[#self.lines + 1] = l .. "|" .. r end
      ns.AddNeeds(mtt, 2592)
      local mj = table.concat(mtt.lines, " / ")
      assert(mj:find("Send x10 to Vez (Tailoring)", 1, true), "tooltip: recipient action line " .. mj)
      local btn1, btn2 = MockWidget(), MockWidget()
      btn1.GetBagID, btn1.GetID = function() return 0 end, function() return 1 end
      btn2.GetBagID, btn2.GetID = function() return 0 end, function() return 2 end
      local oldGetInfo = C_Container.GetContainerItemInfo
      C_Container.GetContainerItemInfo = function(_, slot)
        return slot == 1 and { itemID = 2592, stackCount = 15 } or { itemID = 99999, stackCount = 1 }
      end
      ContainerFrameCombinedBags = MockWidget()
      ContainerFrameCombinedBags.Items = { btn1, btn2 }
      ns.Bags.Refresh()
      ns.Mail.UpdatePanel()
      assert(rawget(btn1, "ccOverlay") == nil, "bags: no fields written onto Blizzard item button")
      f.onEvent(f, "MAIL_CLOSED")
      C_Container.GetContainerItemInfo = oldGetInfo
      ContainerFrameCombinedBags, MailFrame, SendMailFrame, SendMailNameEditBox, SendMailSubjectEditBox = nil, nil, nil, nil, nil
      bMe.bags = savedBags
      bMe.needs = savedNeedsB ns.ClearGiveCache()
      ComradeCraftDB.chars["Vez-Realm"] = nil
      ComradeCraftDB.ui.sel = "group"
      ns.RefreshWindow()
      end)()

      ;(function() -- Custom Forever recipes, live AH prices, inbox mail, Wishlist, Trade, Merchant, Baganator, Group sub-tabs.
      -- 1. Dynamic custom Forever recipe discovery via GetRecipeSchematic.
      local origTS = C_TradeSkillUI
      C_TradeSkillUI = {
        GetBaseProfessionInfo = function() return { professionID = 197, skillLevel = 115 } end,
        GetAllRecipeIDs = function() return { 999901 } end,
        GetRecipeInfo = function(id) return id == 999901 and { learned = true, relativeDifficulty = 1 } or nil end,
        GetRecipeSchematic = function(id)
          if id == 999901 then
            return { outputItemID = 999902, quantityMin = 1,
              reagentSlotSchematics = { { required = true, quantityRequired = 3, reagents = { { itemID = 2589 } } } } }
          end
        end,
      }
      f.onEvent(f, "TRADE_SKILL_LIST_UPDATE")
      assert(ns.Recipes[999901] and ns.Recipes[999901][5] == 999902 and ns.Recipes[999901][7][1] == 2589,
        "custom recipe: discovered dynamically via GetRecipeSchematic")
      ns.Recipes[999901], ComradeCraftDB.customRecipes = nil, nil
      C_TradeSkillUI = origTS

      -- 2. Live AH prices + TSM/Auctionator fallback.
      C_AuctionHouse = {
        GetBrowseResults = function() return { { itemKey = { itemID = 2589 }, minPrice = 42 } } end,
      }
      f.onEvent(f, "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
      assert(ns.LiveAHPrice(2589) == 42 and ns.PriceSource and ns.PriceSource(2589) == 42, "ah: live browse price captured")
      ComradeCraftDB.ahPrices, C_AuctionHouse = nil, nil
      ns.DetectPriceSource()

      -- 3. Inbox mail counted in Surplus / owned.
      local me = ns.CharData()
      local oldBags, oldMail = me.bags, me.mail
      me.bags = {}
      GetInboxNumItems = function() return 1 end
      GetInboxItem = function(i, a) if i == 1 and a == 1 then return "Wool", 2592, 134400, 12 end end
      f.onEvent(f, "MAIL_INBOX_UPDATE")
      local oldNeedsM = me.needs
      me.needs = {} -- surplus of the mail itself, whatever our own route needs
      assert(me.mail and me.mail[2592] == 12 and ns.Surplus(me, 2592) == 12, "mail inbox: counted as owned")
      me.needs = oldNeedsM
      GetInboxNumItems, GetInboxItem = nil, nil
      me.mail = oldMail

      -- 4. Wishlist: add, progress, needs injection, ready alert, tracker & UI view.
      me.bags = { [2589] = 4 }
      local w = ns.Wishlist.Add(2963, 2, "Vez", "pour ses sacs", true)
      assert(w and #ns.Wishlist.List() == 1, "wishlist: entry added")
      local prog = ns.Wishlist.Progress(w, me)
      assert(prog.bagReady and prog.ready, "wishlist: 4 linen covers 2x Bolt of Linen")
      ns.Wishlist.CheckReady()
      assert(w.readyAlerted, "wishlist: ready toast fired")
      me.bags = { [2589] = 1 }
      ns.UpdateNeeds(me)
      assert(me.needs[0] and me.needs[0].items[2589] == 3, "wishlist: missing mats injected into needs[0]")
      ComradeCraftDB.ui.sel = "wishlist"
      ns.RefreshWindow()
      assert(ComradeCraftFrame.title.text == "Wishlist", "wishlist: UI view rendered")
      ns.Wishlist.Remove(w.id)
      assert(#ns.Wishlist.List() == 0, "wishlist: removed cleanly")

      -- 5. Merchant auto-buy plan reagents.
      me.needs = { [197] = { name = "Tailoring", items = {}, vendor = { [2320] = 6 }, gross = {}, have = {} } }
      GetMerchantNumItems = function() return 1 end
      GetMerchantItemID = function() return 2320 end
      GetMerchantItemInfo = function() return "Coarse Thread", 134400, 10, 1, -1 end
      GetMerchantItemMaxStack = function() return 20 end
      GetMoney = function() return 10000 end
      local boughtCount = 0
      BuyMerchantItem = function(_, n) boughtCount = boughtCount + n end
      MerchantFrame = MockWidget()
      f.onEvent(f, "MERCHANT_SHOW")
      local mp, mTotal = ns.Merchant.PlanItems()
      assert(#mp == 1 and mp[1].need == 6 and mTotal == 60, "merchant: plan vendor items detected")
      assert(ns.Merchant.BuyAll() == 6 and boughtCount == 6, "merchant: bought exact missing vendor qty")
      f.onEvent(f, "MERCHANT_CLOSED")
      GetMerchantNumItems, GetMerchantItemID, GetMerchantItemInfo, GetMerchantItemMaxStack, GetMoney, BuyMerchantItem, MerchantFrame = nil, nil, nil, nil, nil, nil, nil

      -- 6. Trade helper + Baganator integration.
      me.bags = { [2592] = 10 }
      me.needs = {}
      ComradeCraftDB.chars["Vez-Realm"] = { class = "DRUID", level = 20, professions = {},
        cooldowns = { [2963] = time() + 3600 },
        needs = { [197] = { name = "Tailoring", items = { [2592] = 8 }, when = { [2592] = 1 }, plan = { { spell = 2963 } } } } }
      local bagReg = false
      Baganator = { API = {
        RegisterCornerWidget = function() bagReg = true end,
        RequestItemButtonsRefresh = function() end,
      } }
      TradeFrame = MockWidget()
      UnitName = function(u) return u == "NPC" and "Vez" or "Test" end
      f.onEvent(f, "PLAYER_ENTERING_WORLD")
      assert(bagReg, "bags: Baganator corner widget registered")
      f.onEvent(f, "TRADE_SHOW")
      assert(ns.Trade.CurrentRecipient() == "Vez-Realm" and ns.Bags.ActiveRecipient() == "Vez-Realm",
        "trade: active recipient synced with Bags")
      f.onEvent(f, "TRADE_CLOSED")
      assert(ns.Trade.CurrentRecipient() == nil, "trade: cleared on close")

      -- 7. Group sub-tabs (overview / mats / upgrades / de) + cooldowns render cleanly.
      ComradeCraftDB.ui.sel = "group"
      for _, gt in ipairs({ "overview", "mats", "upgrades", "de" }) do
        ComradeCraftDB.ui.groupTab = gt
        ns.RefreshWindow()
      end
      ComradeCraftDB.ui.groupTab = "overview"
      Baganator, TradeFrame = nil, nil
      UnitName = function() return "Test" end
      ComradeCraftDB.chars["Vez-Realm"] = nil
      me.bags = oldBags
      ns.UpdateNeeds(me)
      ns.RefreshWindow()
      end)()

      ;(function() -- Trainer refusal deferral + Synergies + Audit + Loot + AH Panel + Buy-vs-Farm gold arbitrage.
      -- 1. Trainer refused at 115 defers unconfirmed ~110 recipes to 125 (so known crafts level 115->125).
      ComradeCraftDB.trainerRefused = { [1346] = { line = 197, rank = 115, name = "Georgio Bolero" } }
      local tr = ns.TrainerRecipes(197, 150, {})
      assert(tr[3848] == 125, "trainer deferral: req 110 deferred to 125 when refused at 115, got " .. tostring(tr[3848]))
      ComradeCraftDB.trainerRefused = nil

      -- 2. Group Upgrades Audit: small bags & missing enchants.
      local me = ns.CharData()
      local savedB, savedK, savedBS, savedEn, savedEq = me.bags, me.known, me.bagSizes, me.enchants, me.equipped
      me.known = { [197] = { [3755] = true, [2963] = true } } -- 3755 = Linen Bag / Woolen Bag check via 3813 (Woolen Bag 8-slot)
      if ns.Recipes[3813] then me.known[197][3813] = true end
      ComradeCraftDB.chars["Wo-Realm"] = { class = "MAGE", level = 10, bagSizes = { 6, 6, 6, 6 },
        professions = { Tailoring = { skillLine = 197, rank = 45, max = 75 } },
        needs = { [197] = { name = "Tailoring", items = { [2996] = 10 }, when = { [2996] = 1 } } } }
      local aud = ns.Audit.Run()
      local foundBag = false
      for _, grp in ipairs(aud) do
        if grp.targetKey == "Wo-Realm" then
          for _, u in ipairs(grp.items) do if u.kind == "bag" then foundBag = true end end
        end
      end
      assert(foundBag, "audit: small bags detected for Wo")

      -- 3. Cross-profession synergy: group spare Linen Cloth (2589) -> Test crafts Bolt (2996) for Wo.
      me.bags = { [2589] = 40 }
      me.needs = {}
      local syns = ns.Synergies.Find()
      assert(#syns >= 1 and syns[1].kind == "craft", "synergies: raw->intermediate synergy detected")

      -- 4. Gold-aware Buy vs Farm arbitrage.
      local oldPS = ns.PriceSource
      ns.PriceSource = function() return 100 end -- 1s each
      local cheapAdv = ns.FarmAdvice.Evaluate(2589, 10, 1000000) -- 10s vs 100g -> buy
      local expAdv = ns.FarmAdvice.Evaluate(2589, 10, 500)       -- 10s vs 5s -> farm
      assert(cheapAdv.action == "buy" and expAdv.action == "farm", "farm advice: respects player gold balance")
      ns.PriceSource = oldPS

      -- 5. Auction House side panel + 1-click search.
      me.needs = { [197] = { name = "Tailoring", items = { [2589] = 20 }, when = { [2589] = 1 } } }
      local searched
      C_AuctionHouse = { SendBrowseQuery = function(q) searched = q.searchString end }
      AuctionHouseFrame = MockWidget()
      f.onEvent(f, "AUCTION_HOUSE_SHOW")
      local ahItems = ns.AuctionPanel.Items()
      assert(#ahItems == 1 and ahItems[1].item == 2589, "ah panel: missing mats listed")
      assert(ns.AuctionPanel.SearchItem(2589) and searched == "Item2589", "ah panel: 1-click AH search")
      f.onEvent(f, "AUCTION_HOUSE_CLOSED")
      C_AuctionHouse, AuctionHouseFrame = nil, nil

      -- 6. Loot roll hint on urgent material.
      GetLootRollItemLink = function() return "|Hitem:2996|h[Bolt]|h" end
      local logBefore = #__log
      f.onEvent(f, "START_LOOT_ROLL", 1)
      assert(#__log > logBefore and __log[#__log]:find("Wo x10", 1, true), "loot: roll hint printed for urgent mat")
      GetLootRollItemLink = nil

      ComradeCraftDB.chars["Wo-Realm"] = nil
      me.bags, me.known, me.bagSizes, me.enchants, me.equipped = savedB, savedK, savedBS, savedEn, savedEq
      ns.UpdateNeeds(me)
      end)()

      -- BoP / soulbound gear: never suggest keeping for another player, never suggest AH sell,
      -- and only suggest disenchant when the holder themselves is an enchanter.
      ;(function()
        local me = ComradeCraftDB.chars["Test-Realm"]
        local savedB, savedBound, savedP = me.bags, me.bound, me.professions
        local savedGet = GetItemInfo
        local savedPS = ns.PriceSource
        ComradeCraftDB.chars["Acuponctus-Realm"] = {
          class = "MAGE", level = 29, equipped = {},
          professions = { Enchanting = { skillLine = 333, rank = 75, max = 150 } },
        }
        -- Item 281318: BoP (bindType=1) green off-hand (classID=4, sub=0, INVTYPE_HOLDABLE).
        -- Item 281319: BoE (bindType=2) green off-hand, but soulbound in bags via me.bound.
        GetItemInfo = function(id)
          if id == 281318 then
            return "Bouquet of Auberdine Flowers", "|Hitem:281318|h[Bouquet]|h", 2, 29, 25,
              "Armor", "Miscellaneous", 1, "INVTYPE_HOLDABLE", 1, 1578, 4, 0, 1
          elseif id == 281319 then
            return "Soulbound Offhand", "|Hitem:281319|h[Soulbound]|h", 2, 29, 25,
              "Armor", "Miscellaneous", 1, "INVTYPE_HOLDABLE", 1, 1578, 4, 0, 2
          end
          return savedGet(id)
        end
        ns.PriceSource = function() return 999999 end
        -- Case 1: holder IS an enchanter -> disenchant (not gear for Acuponctus, not AH sell, no enchanter redirect).
        me.professions = { Enchanting = { skillLine = 333, rank = 100, max = 150 } }
        me.bags = { [281318] = 1, [281319] = 1 }
        me.bound = { [281319] = true }
        local adv = ns.BagAdvice("Test-Realm")
        assert(#adv == 2, "bop advice (enchanter): expected 2 entries, got " .. #adv)
        for _, a in ipairs(adv) do
          assert(a.verdict == "disenchant" and a.to == nil and a.enchanter == nil,
            "bop advice (enchanter): got verdict=" .. tostring(a.verdict) .. " to=" .. tostring(a.to))
        end
        -- Case 2: holder is NOT an enchanter -> omitted (cannot give BoP/soulbound gear nor send to another enchanter).
        me.professions = { Tailoring = { skillLine = 197, rank = 115, max = 150 } }
        local adv2 = ns.BagAdvice("Test-Realm")
        assert(#adv2 == 0, "bop advice (non-enchanter): expected 0 entries, got " .. #adv2)
        ComradeCraftDB.chars["Acuponctus-Realm"] = nil
        me.bags, me.bound, me.professions = savedB, savedBound, savedP
        GetItemInfo, ns.PriceSource = savedGet, savedPS
      end)()

      -- GearScore & Craftable BiS: 2H vs 1H enchant subclass fix, spec weights (Frost Mage, etc.),
      -- 2H vs 1H+OH comparison, self-crafts, guild directory crafters, and top-5 per-slot BiS.
      ;(function()
        local GS = ns.GearScore
        assert(GS, "gearscore: module loaded")
        -- 1. Enchant subclass bug fix: 2H enchant (7793 / 13695) must NOT match a 1H dagger (class=2, sub=15).
        assert(not GS.EnchantMatchesItem(7793, 2, GS.INVTYPE.INVTYPE_WEAPON, 15), "enchant: 2H Lesser Int must not match dagger")
        assert(not GS.EnchantMatchesItem(13695, 2, GS.INVTYPE.INVTYPE_WEAPON, 15), "enchant: 2H Impact must not match dagger")
        assert(GS.EnchantMatchesItem(7793, 2, GS.INVTYPE.INVTYPE_2HWEAPON, 10), "enchant: 2H Lesser Int matches staff")
        assert(GS.EnchantMatchesItem(22749, 2, GS.INVTYPE.INVTYPE_WEAPON, 15), "enchant: Weapon Spell Power matches dagger")
        assert(GS.EnchantMatchesItem(21931, 2, GS.INVTYPE.INVTYPE_WEAPON, 15), "enchant: Winter's Might matches dagger")
        -- Shield enchant (13631, sub=64) must match shield (sub=6) and NOT cloth chest (sub=1) or off-hand (sub=0).
        assert(GS.EnchantMatchesItem(13631, 4, GS.INVTYPE.INVTYPE_SHIELD, 6), "enchant: Shield Stamina matches shield")
        assert(not GS.EnchantMatchesItem(13631, 4, GS.INVTYPE.INVTYPE_CHEST, 1), "enchant: Shield Stamina must not match chest")
        assert(not GS.EnchantMatchesItem(13631, 4, GS.INVTYPE.INVTYPE_HOLDABLE, 0), "enchant: Shield Stamina must not match holdable")
        assert(GS.EnchantMatchesItem(1219577, 4, GS.INVTYPE.INVTYPE_HOLDABLE, 0), "enchant: Off-Hand Superior Int matches holdable")

        -- 2. Spec enchant scoring: Frost Mage prefers Frost/Spell Power & rejects Striking/Fire/Mining.
        local frostMage = { class = "MAGE", spec = "Givre", level = 40 }
        local fireMage = { class = "MAGE", spec = "Fire", level = 40 }
        local armsWar = { class = "WARRIOR", spec = "Arms", level = 40 }
        local holyPri = { class = "PRIEST", spec = "Holy", level = 40 }
        assert(GS.GetSpec(frostMage) == "frost", "spec: French Givre -> frost")
        assert(GS.ScoreEnchant(21931, frostMage) > 0 and GS.ScoreEnchant(21931, fireMage) == 0, "enchant: Winter's Might for Frost only")
        assert(GS.ScoreEnchant(13693, frostMage) == 0 and GS.ScoreEnchant(13693, armsWar) > 0, "enchant: Striking for Warrior, not Mage")
        assert(GS.ScoreEnchant(25074, frostMage) > 0 and GS.ScoreEnchant(25078, frostMage) == 0, "enchant: Frost Gloves > Fire Gloves for Frost")
        assert(GS.ScoreEnchant(13612, frostMage) == 0, "enchant: Mining utility enchant skipped")
        assert(GS.ScoreEnchant(22750, holyPri) > GS.ScoreEnchant(22749, holyPri), "enchant: Healing Power > Spell Power for Holy Priest")

        -- 3. Standalone stat weights: Frost Spell Damage >> Intellect; Fire SP = 0 for Frost; 2H vs 1H+OH.
        local savedGet, savedStats = GetItemInfo, GetItemStats
        local items = {
          -- [id] = { name, ilvl, req, eqLoc, classID, subID, bind, stats }
          [99101] = { "Frost Gloves",   30, 28, "INVTYPE_HAND",     4, 1, 2, { ITEM_MOD_FROST_DAMAGE_DONE_SHORT = 10 } },
          [99102] = { "Int Gloves",     30, 28, "INVTYPE_HAND",     4, 1, 2, { ITEM_MOD_INTELLECT_SHORT = 10 } },
          [99103] = { "Fire Gloves",    30, 28, "INVTYPE_HAND",     4, 1, 2, { ITEM_MOD_FIRE_DAMAGE_DONE_SHORT = 15 } },
          [99104] = { "Worn Dagger",    25, 22, "INVTYPE_WEAPON",   2, 15, 1, { ITEM_MOD_INTELLECT_SHORT = 6, ITEM_MOD_FROST_DAMAGE_DONE_SHORT = 6, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 15 } },
          [99105] = { "Worn Offhand",   25, 22, "INVTYPE_HOLDABLE", 4, 0, 1, { ITEM_MOD_INTELLECT_SHORT = 5, ITEM_MOD_FROST_DAMAGE_DONE_SHORT = 7 } },
          [99106] = { "Weak Staff",     30, 28, "INVTYPE_2HWEAPON", 2, 10, 2, { ITEM_MOD_INTELLECT_SHORT = 10, ITEM_MOD_FROST_DAMAGE_DONE_SHORT = 8, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 30 } },
          [99107] = { "Strong Staff",   38, 35, "INVTYPE_2HWEAPON", 2, 10, 2, { ITEM_MOD_INTELLECT_SHORT = 15, ITEM_MOD_FROST_DAMAGE_DONE_SHORT = 20, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 32 } },
          [99108] = { "Magic Wand",     25, 20, "INVTYPE_RANGEDRIGHT", 2, 19, 2, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 20 } },
          [99109] = { "Melee Sword",    35, 30, "INVTYPE_WEAPON",   2, 7, 2, { ITEM_MOD_STRENGTH_SHORT = 10, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 40 } },
          [99110] = { "BoP Frost Robe", 38, 35, "INVTYPE_CHEST",    4, 1, 1, { ITEM_MOD_FROST_DAMAGE_DONE_SHORT = 22, ITEM_MOD_INTELLECT_SHORT = 10 } },
        }
        GetItemInfo = function(id)
          local nid = type(id) == "string" and tonumber(id:match("item:(%d+)")) or id
          local it = items[nid]
          if it then return it[1], "|Hitem:" .. nid .. "|h[" .. it[1] .. "]|h", 2, it[2], it[3], "", "", 1, it[4], 1, 0, it[5], it[6], it[7] end
          return savedGet(id)
        end
        GetItemStats = function(link)
          local nid = type(link) == "string" and tonumber(link:match("item:(%d+)")) or link
          return items[nid] and items[nid][8] or nil
        end
        local sFrost = GS.ScoreItem(99101, frostMage)
        local sInt = GS.ScoreItem(99102, frostMage)
        local sFire = GS.ScoreItem(99103, frostMage)
        assert(sFrost > sInt, "frost mage: +10 Frost SP (" .. tostring(sFrost) .. ") must beat +10 Int (" .. tostring(sInt) .. ")")
        assert(sFire == 0, "frost mage: Fire SP must score 0, got " .. tostring(sFire))
        assert(GS.ScoreItem(99103, fireMage) > GS.ScoreItem(99102, fireMage), "fire mage: Fire SP beats Int")
        assert(GS.ScoreItem(99109, frostMage) == 0, "frost mage: melee sword scores 0")
        assert(GS.ScoreItem(99109, armsWar) > 500, "arms warrior: melee sword scores high")

        -- 2H Staff vs Dagger + Off-Hand combined: Weak Staff loses, Strong Staff wins; Wand upgrades empty ranged.
        frostMage.equipped = { [10] = 99102, [16] = 99104, [17] = 99105 }
        assert(not ns.UpgradeFor(99106, frostMage), "2H vs 1H+OH: weak staff must NOT beat dagger + off-hand")
        assert(ns.UpgradeFor(99107, frostMage), "2H vs 1H+OH: strong staff beats dagger + off-hand")
        assert(ns.UpgradeFor(99101, frostMage), "frost gloves beat int gloves")
        assert(ns.UpgradeFor(99108, frostMage), "wand upgrades empty ranged slot")
        assert(not ns.UpgradeFor(99109, frostMage), "melee sword is not an upgrade for frost mage")

        -- 4. Audit end-to-end: Frost Mage with unenchanted dagger + off-hand never gets 2H enchant,
        -- gets Spell Power on dagger, gets self BoP robe & guild directory upgrade!
        local me = ns.CharData()
        local savedState = { c = me.class, l = me.level, s = me.spec, so = me.specOverride,
          eq = me.equipped, eql = me.equippedLinks, en = me.enchants, kn = me.known, b = me.bags, p = me.professions }
        local savedDir = ComradeCraftDB.directory
        ns.Recipes[999101] = { 197, 150, 200, 1, 99101, 1, { 2589, 1 } }
        ns.Recipes[999110] = { 197, 150, 200, 1, 99110, 1, { 2589, 1 } }
        me.class, me.level, me.spec, me.specOverride = "MAGE", 40, "Frost", nil
        me.equipped = { [10] = 99102, [16] = 99104, [17] = 99105 }
        me.equippedLinks = nil
        me.enchants = { [16] = 0, [17] = 0 }
        -- Me knows 2H Lesser Intellect (7793), Weapon Striking (13693), Weapon Spell Power (22749),
        -- Off-Hand Superior Int (1219577), and BoP Frost Robe (999110).
        me.known = { [333] = { [7793] = true, [13693] = true, [22749] = true, [1219577] = true }, [197] = { [999110] = true } }
        ComradeCraftDB.directory = {
          ["GuildTailor-Realm"] = { cl = "MAGE", lv = 45, p = { [197] = { 225, 225, "Tailoring" } },
            r = { [999101] = true }, seen = time() },
        }
        if ns.Directory then ns.Directory.OnEntry = ns.Directory.OnEntry end
        -- Force directory index rebuild by toggling guild update handler.
        f.onEvent(f, "PLAYER_GUILD_UPDATE")
        local aud = ns.Audit.Run()
        local myGrp
        for _, g in ipairs(aud) do if g.isMe then myGrp = g break end end
        assert(myGrp, "audit bis: found current char upgrades")
        local saw2H, sawSP, sawOH, sawSelfBoP, sawGuildGloves = false, false, false, false, false
        for _, u in ipairs(myGrp.items) do
          if u.spell == 7793 then saw2H = true end
          if u.kind == "enchant" and u.spell == 22749 then sawSP = true end
          if u.kind == "enchant" and u.spell == 1219577 then sawOH = true end
          if u.kind == "gear" and u.item == 99110 and u.ownCrafter then sawSelfBoP = true end
          if u.kind == "gear" and u.item == 99101 and u.guildCrafter then sawGuildGloves = true end
        end
        assert(not saw2H, "audit bis: must NEVER suggest 2H enchant on dagger!")
        assert(sawSP, "audit bis: must suggest Spell Power on dagger")
        assert(sawOH, "audit bis: must suggest Off-Hand enchant on holdable")
        assert(sawSelfBoP, "audit bis: self BoP craft included")
        assert(sawGuildGloves, "audit bis: guild directory Frost Gloves included")
        -- 5. Features #1-#7: Mats status, Request->Mail reagents, Talent-spell auto-spec & sync,
        --    Soon (+1..4 lvl) BiS, Spec consumables, Loot recipe tooltip BiS, Trainer panel highlights.
        -- #1 MatsStatus: me has 10 linen -> recipe 999110 (needs 1 linen) is ready!
        me.bags = { [2589] = 10 }
        local ms = ns.Audit.MatsStatus(999110, 1)
        assert(ms and ms.ready, "mats status: 10 linen covers 1 linen craft")
        -- #2 Outgoing request reagents appear in Mail.ItemsFor(crafter) automatically.
        ComradeCraftDB.peers = ComradeCraftDB.peers or {}
        ComradeCraftDB.peers["peerCr"] = { included = true, name = "Crafter" }
        ComradeCraftDB.remote = ComradeCraftDB.remote or {}
        ComradeCraftDB.remote["Crafter-Realm"] = { class = "MAGE", level = 40, peer = "peerCr", bags = {} }
        ComradeCraftDB.requests = ComradeCraftDB.requests or {}
        ComradeCraftDB.requests["req-mats-1"] = { id = "req-mats-1", from = ns.CharKey(), to = "Crafter-Realm",
          toPeer = "peerCr", spell = 2963, item = 2996, qty = 2, status = "pending", updated = time() }
        local mItems = ns.Mail.ItemsFor("Crafter-Realm")
        local foundLinen = false
        for _, it in ipairs(mItems) do if it.item == 2589 and it.n == 4 and it.request then foundLinen = true end end
        assert(foundLinen, "request->mail: 4 linen for outgoing 2x Bolt request attached for crafter")
        ComradeCraftDB.requests["req-mats-1"] = nil
        ComradeCraftDB.remote["Crafter-Realm"], ComradeCraftDB.peers["peerCr"] = nil, nil
        -- #3 Talent-spell spec auto-detection (Frost Mage via Ice Barrier 11426 + Cold Snap 12472) & Sync specOverride.
        IsPlayerSpell = function(id) return id == 11426 or id == 12472 end
        assert(GS.DetectSpecFromSpells("MAGE") == "frost", "spec detect: Frost talents -> frost")
        IsPlayerSpell = nil
        assert(ns.Sync.CleanRecord({ class = "MAGE", specOverride = "frost" }).specOverride == "frost", "sync: specOverride preserved")
        -- #6 Upcoming (+1..4 lvl) BiS: level 40 Frost Mage sees lvl 43 Frost Mantle in grp.soon.
        items[99111] = { "Frost Mantle", 45, 43, "INVTYPE_SHOULDER", 4, 1, 2, { ITEM_MOD_FROST_DAMAGE_DONE_SHORT = 18 } }
        ns.Recipes[999111] = { 197, 200, 230, 1, 99111, 1, { 2589, 2 } }
        me.known[197][999111] = true
        -- #7 Spec-matched consumables: Frost Mage knows Elixir of Frost Power (21923) + Lesser Wizard Oil (25126).
        me.known[171] = { [21923] = true }
        me.known[333][25126] = true
        local aud2 = ns.Audit.Run()
        local myGrp2
        for _, g in ipairs(aud2) do if g.isMe then myGrp2 = g break end end
        assert(myGrp2 and myGrp2.soon and #myGrp2.soon >= 1 and myGrp2.soon[1].item == 99111, "audit soon: lvl 43 Frost Mantle shown")
        local sawFrostElixir, sawWizOil = false, false
        for _, cn in ipairs(myGrp2.consumables or {}) do
          if cn.spell == 21923 then sawFrostElixir = true end
          if cn.spell == 25126 then sawWizOil = true end
        end
        assert(sawFrostElixir and sawWizOil, "audit consumables: Frost Elixir + Wizard Oil suggested")
        -- Two of your characters know the same elixir: equal scores tie-break on priority, no error.
        ComradeCraftDB.chars["Twin-Realm"] = { class = "MAGE", level = 40, known = { [171] = { [21923] = true } }, updated = time() + 5 }
        local okTie, errTie = pcall(ns.Audit.Run)
        assert(okTie, "audit consumables: tie on score, got " .. tostring(errTie))
        ComradeCraftDB.chars["Twin-Realm"] = nil
        -- #5 Trainer highlights: available trainer recipe crafting Frost Gloves (999101) flagged as upgrade!
        local oldSN = ns.SpellName
        ns.SpellName = function(sp) return sp == 999101 and "Frost Gloves" or oldSN(sp) end
        GetNumTrainerServices = function() return 1 end
        GetTrainerServiceInfo = function() return "Frost Gloves", nil, "available" end
        GetTrainerServiceSkillReq = function() return "Tailoring", 150, true end
        GetTrainerServiceCost = function() return 500 end
        me.professions = { Tailoring = { skillLine = 197, rank = 200, max = 225 } }
        local th = ns.Trainer.Highlights()
        assert(#th == 1 and th[1].spell == 999101 and th[1].prio == 2, "trainer: BiS upgrade recipe highlighted")
        ns.SpellName = oldSN
        GetNumTrainerServices, GetTrainerServiceInfo, GetTrainerServiceSkillReq, GetTrainerServiceCost = nil, nil, nil, nil
        ns.Recipes[999111] = nil

        -- #8 Postbox mailbox compatibility: anchors to PostboxFrame (UIParent child), switches to
        --    Postbox Send tab, fills ToBox/SubjectBox/BodyBox, and reads CurrentRecipient from ToBox.
        local pbSend = MockWidget()
        pbSend.shown = false
        pbSend.ToBox = MockWidget()
        pbSend.SubjectBox = MockWidget()
        pbSend.BodyBox = MockWidget()
        local pbSendBtn = MockWidget()
        pbSendBtn.Click = function() pbSend.shown = true end
        PostboxFrame = MockWidget()
        PostboxFrame.shown = true
        PostboxFrame.Tabs = { send = pbSend }
        PostboxFrame.TabButtons = { send = pbSendBtn }
        ComradeCraftDB.chars["Vez Stone-Realm"] = { class = "DRUID", level = 20 }
        f.onEvent(f, "MAIL_SHOW")
        assert(ComradeCraftMailPanel and ComradeCraftMailPanel:IsShown(), "postbox: mail panel visible")
        assert(ns.Mail.CurrentRecipient() == nil, "postbox: nil while on Collect tab")
        ns.Mail.SelectRecipient("Vez Stone-Realm")
        assert(pbSend:IsShown() and pbSend.ToBox:GetText() == "Vez Stone" and pbSend.SubjectBox:GetText() == "ComradeCraft",
          "postbox: SelectRecipient switched to send tab and filled full First Last + Subject")
        assert(ns.Mail.CurrentRecipient() == "Vez Stone-Realm", "postbox: CurrentRecipient reads Postbox ToBox")
        ns.Mail.PrepareRequest({ id = "pb-1", to = "Vez Stone-Realm", spell = 2963, qty = 2, note = "merci!" })
        assert(pbSend.SubjectBox:GetText():find("[CC:2963:2:pb-1]", 1, true) and pbSend.BodyBox:GetText() == "merci!",
          "postbox: PrepareRequest fills Postbox SubjectBox and BodyBox")
        -- Forever mail safety: legacy half-name ("LegacyOnly-Realm") must NEVER overwrite ToBox with a half-name,
        -- but MUST preserve an existing matching full name ("LegacyOnly Jenkins") already in ToBox!
        ComradeCraftDB.chars["LegacyOnly-Realm"] = { class = "HUNTER", level = 20 }
        pbSend.ToBox:SetText("")
        ns.Mail.SelectRecipient("LegacyOnly-Realm")
        assert(pbSend.ToBox:GetText() == "", "forever mail safety: refuses to fill half-name into ToBox")
        pbSend.ToBox:SetText("LegacyOnly Jenkins")
        ns.Mail.SelectRecipient("LegacyOnly-Realm")
        assert(pbSend.ToBox:GetText() == "LegacyOnly Jenkins", "forever mail safety: keeps full name already in ToBox")
        ComradeCraftDB.chars["LegacyOnly-Realm"], ComradeCraftDB.chars["Vez Stone-Realm"] = nil, nil
        -- Forever UnitFullName: joins 2 return values (first, surname) without dropping surname.
        local oldUN = UnitName
        UnitName = function() return "Jhf", "Mage" end
        assert(ns.UnitFullName("player") == "Jhf Mage", "forever fullname: joins First + Surname")
        UnitName = oldUN
        f.onEvent(f, "MAIL_CLOSED")
        assert(not ComradeCraftMailPanel:IsShown(), "postbox: mail panel hidden on MAIL_CLOSED")
        PostboxFrame = nil

        -- #9 Bagnon / BagBrother bag highlighting: real frames only (skips descriptors & cached alts),
        --    draws crisp border + mailbox badge in normal & focus modes!
        local bbBtn = MockWidget()
        bbBtn.info = { itemID = 2589 }
        bbBtn.bag = 0
        local bbFrame = MockWidget()
        bbFrame[0] = true
        bbFrame.shown = true
        bbFrame.IsCached = function() return false end
        bbFrame.ItemGroup = { buttons = { bbBtn } }
        Bagnon = { Frames = { Iterate = function() return ipairs({ { id = "bank" }, bbFrame }) end } }
        ComradeCraftDB.chars["Vez-Realm"] = { class = "DRUID", level = 20,
          needs = { [197] = { name = "Tailoring", items = { [2589] = 5 }, when = { [2589] = 1 } } } }
        me.bags = { [2589] = 10 }
        me.needs = {}
        ns.Bags.Refresh()
        assert(ns.Bags.ItemState(2589) and ns.Bags.ItemState(2589).urgency == 1, "bags: Bagnon item highlighted with urgency 1")
        -- #10 Forever two-part names ("Mirandaa Jenkins") + unknown recipe scroll in bags highlighted & mailable!
        ComradeCraftDB.chars["Mirandaa Jenkins-Realm"] = { class = "HUNTER", level = 25,
          professions = { Leatherworking = { skillLine = 165, rank = 95, max = 150 } }, known = { [165] = {} } }
        assert(ns.Mail.KeyForName("Mirandaa Jenkins") == "Mirandaa Jenkins-Realm", "mail: Forever 2-part name matched")
        assert(ns.Mail.KeyForName("Mirandaa") == "Mirandaa Jenkins-Realm", "mail: first-name fallback matched")
        -- Find any Leatherworking (165) recipe item from LibProfessionDB to test unknown pattern in bags.
        local lpdb = LibStub("LibProfessionDB-1.0")
        local lwPatternItem
        for sp, e in pairs(lpdb:GetRecipes(165) or {}) do
          if type(e) == "table" and e.itemId and e.itemId > 0 then lwPatternItem = e.itemId break end
        end
        assert(lwPatternItem, "test setup: found LW pattern item")
        me.bags[lwPatternItem] = 1
        local mirItems = ns.Mail.ItemsFor("Mirandaa Jenkins-Realm")
        local foundPat = false
        for _, it in ipairs(mirItems) do if it.item == lwPatternItem and it.recipe then foundPat = true end end
        assert(foundPat, "mail: unknown LW pattern included in Mail.ItemsFor(Mirandaa)")
        assert(ns.Bags.ItemState(lwPatternItem) ~= nil, "bags: unknown LW pattern highlighted in normal mode")
        assert(ns.Bags.ItemState(lwPatternItem, "Mirandaa Jenkins-Realm") ~= nil, "bags: unknown LW pattern highlighted in focus mode")
        me.bags[lwPatternItem] = nil
        -- #11 Bank-only items: flagged as inBank (inBags=0), not highlighted in bags, button disabled.
        local savedBank = me.bank
        me.bags = {}
        me.bank = { [2589] = 25 }
        local bItems = ns.Mail.ItemsFor("Vez-Realm")
        assert(#bItems == 1 and bItems[1].inBags == 0 and bItems[1].inBank == 5, "mail bank-only: 0 inBags, 5 inBank")
        assert(ns.Bags.ItemState(2589) == nil and ns.Bags.ItemState(2589, "Vez-Realm") == nil, "bags: bank-only not highlighted")
        me.bank = savedBank
        -- #12 Guild roster auto-migration of legacy 1-word alt keys + Expert/Artisan trainers!
        ComradeCraftDB.chars["AltOne-Realm"] = { class = "ROGUE", level = 22, shared = true }
        IsInGuild = function() return true end
        GetNumGuildMembers = function() return 1 end
        GetGuildRosterInfo = function() return "AltOne Shadow-Realm" end
        f.onEvent(f, "GUILD_ROSTER_UPDATE")
        assert(ComradeCraftDB.chars["AltOne Shadow-Realm"] and not ComradeCraftDB.chars["AltOne-Realm"],
          "migration: legacy alt key auto-upgraded from guild roster without logging in")
        ComradeCraftDB.chars["AltOne Shadow-Realm"] = nil
        IsInGuild, GetNumGuildMembers, GetGuildRosterInfo = nil, nil, nil
        -- Expert & Artisan trainers for Alliance (incl. gathering professions like Herbalism/Mining/Skinning).
        UnitFactionGroup = function() return "Alliance" end
        local raTail = ns.RankAdvice({ skillLine = 197, rank = 150, max = 150 })
        assert(raTail and raTail.entries[1] and raTail.entries[1].label == "Georgio Bolero", "expert trainer: Alliance Tailoring = Georgio Bolero")
        local raEnch = ns.RankAdvice({ skillLine = 333, rank = 150, max = 150 })
        assert(raEnch and raEnch.entries[1] and raEnch.entries[1].label == "Kitta Firewind", "expert trainer: Alliance Enchanting = Kitta Firewind")
        local raHerb = ns.DescribeNeed({ skillLine = 182, rank = 140, max = 150 }, {})
        assert(raHerb and raHerb.rank and raHerb.rank.entries[1].label == "Firodren Mooncaller", "expert trainer: gathering Herbalism = Firodren Mooncaller")
        local raArtLW = ns.RankAdvice({ skillLine = 165, rank = 225, max = 225 })
        assert(raArtLW and raArtLW.entries[1] and raArtLW.entries[1].label == "Drakk Stonehand", "artisan trainer: Alliance LW = Drakk Stonehand")
        -- Horde Expert & Artisan trainers + Expert rank books (Cooking 16072, First Aid 16084, Fishing 16083).
        UnitFactionGroup = function() return "Horde" end
        assert(ns.RankAdvice({ skillLine = 165, rank = 150, max = 150 }).entries[1].label == "Una", "horde expert LW = Una")
        assert(ns.RankAdvice({ skillLine = 171, rank = 150, max = 150 }).entries[1].label == "Doctor Herbert Halsey", "horde expert Alch")
        assert(ns.RankAdvice({ skillLine = 197, rank = 150, max = 150 }).entries[1].label == "Josef Gregorian", "horde expert Tailor")
        assert(ns.RankAdvice({ skillLine = 333, rank = 150, max = 150 }).entries[1].label == "Hgarth", "horde expert Ench")
        assert(ns.RankAdvice({ skillLine = 165, rank = 225, max = 225 }).entries[1].label == "Hahrana Ironhide", "horde artisan LW")
        assert(ns.RankAdvice({ skillLine = 171, rank = 225, max = 225 }).entries[1].label == "Rogvar", "horde artisan Alch")
        assert(ns.RankAdvice({ skillLine = 197, rank = 225, max = 225 }).entries[1].label == "Daryl Stack", "horde artisan Tailor")
        local raHordeCook = ns.RankAdvice({ skillLine = 185, rank = 150, max = 150 })
        assert(raHordeCook.entries[1].item == 16072 and raHordeCook.entries[1].detail:find("Wulan", 1, true),
          "horde expert cooking book 16072 from Wulan")
        local raHordeFA = ns.RankAdvice({ skillLine = 129, rank = 150, max = 150 })
        assert(raHordeFA.entries[1].item == 16084 and raHordeFA.entries[1].detail:find("Balai Lok'Wein", 1, true),
          "horde expert first aid book 16084 from Balai Lok'Wein")
        local raFish = ns.RankAdvice({ skillLine = 356, rank = 150, max = 150 })
        assert(raFish.entries[1].item == 16083 and raFish.entries[1].detail:find("Old Man Heming", 1, true),
          "expert fishing book 16083 from Old Man Heming")
        UnitFactionGroup = nil
        -- #13 Transformable items (3x Lesser Magic Essence 10938 <-> 1x Greater Magic Essence 10939).
        do
          local LESSER, GREATER = 10938, 10939
          -- PairBalance exactness (no double counting, reserves partial Lesser when Greater is missing).
          local hS, mS, spS, hB, mB, spB = ns.PairBalance(6, 0, 0, 2, 3)
          assert(hB == 2 and mB == 0 and spS == 0 and spB == 0, "transform: 6 Lesser covers 2 Greater")
          hS, mS, spS, hB, mB, spB = ns.PairBalance(2, 0, 0, 1, 3)
          assert(hB == 0 and mB == 1 and spS == 0, "transform: 2 Lesser reserved toward 1 Greater (not surplus)")
          hS, mS, spS, hB, mB, spB = ns.PairBalance(7, 0, 0, 2, 3)
          assert(hB == 2 and mB == 0 and spS == 1, "transform: 7 Lesser vs 2 Greater -> 1 Lesser spare")
          hS, mS, spS, hB, mB, spB = ns.PairBalance(0, 2, 5, 0, 3)
          assert(hS == 5 and mS == 0 and spB == 0, "transform: 2 Greater covers 5 Lesser")
          hS, mS, spS, hB, mB, spB = ns.PairBalance(3, 1, 3, 2, 3)
          assert(hS == 3 and mS == 0 and hB == 1 and mB == 1, "transform: mixed plan no double-count")
          -- UpdateNeeds: 6 Lesser satisfies a recipe needing 2 Greater (and 1 Greater satisfies 3 Lesser).
          ns.Recipes[999201] = { 999, 55, 100, 1, 0, 1, { GREATER, 2 } }
          ns.Recipes[999202] = { 999, 55, 100, 1, 0, 1, { LESSER, 3 } }
          local tc = { professions = { Enchanting = { skillLine = 999, rank = 50, max = 51 } },
            known = { [999] = { [999201] = true } }, bags = { [LESSER] = 6 }, bank = {}, mail = {} }
          ns.UpdateNeeds(tc)
          assert((tc.needs[999].items[GREATER] or 0) == 0 and tc.needs[999].have[GREATER] == 2,
            "transform UpdateNeeds: 6 Lesser covers 2 Greater")
          assert(ns.Surplus(tc, LESSER) == 0, "transform Surplus: 6 Lesser reserved for own 2 Greater need")
          tc.bags = { [LESSER] = 7 }
          ns.UpdateNeeds(tc)
          assert(ns.Surplus(tc, LESSER) == 1, "transform Surplus: 7 Lesser -> 1 spare")
          local tc2 = { professions = { Enchanting = { skillLine = 999, rank = 50, max = 51 } },
            known = { [999] = { [999202] = true } }, bags = { [GREATER] = 1 }, bank = {}, mail = {} }
          ns.UpdateNeeds(tc2)
          assert((tc2.needs[999].items[LESSER] or 0) == 0 and tc2.needs[999].have[LESSER] == 3,
            "transform UpdateNeeds: 1 Greater covers 3 Lesser")
          -- CraftableNow & Audit.MatsStatus across Lesser <-> Greater.
          assert(ns.CraftableNow(999201, { [LESSER] = 6 }) == 1, "transform CraftableNow: 6 Lesser -> 1x (2 Greater)")
          assert(ns.CraftableNow(999201, { [LESSER] = 5 }) == 0, "transform CraftableNow: 5 Lesser -> 0x (2 Greater)")
          assert(ns.CraftableNow(999202, { [GREATER] = 2 }) == 2, "transform CraftableNow: 2 Greater -> 2x (3 Lesser)")
          local ms = ns.Audit.MatsStatus(999201, 1, { [LESSER] = 6 })
          assert(ms and ms.ready, "transform Audit.MatsStatus: 6 Lesser marks 2 Greater recipe ready")
          -- GiveList / Mail / Bags / NeedRows / GroupSupply:
          -- Vez needs 2 Greater; we hold 1 Greater + 6 Lesser -> send 1 Greater + 3 Lesser (exact, no over-send!).
          ComradeCraftDB.chars["Vez-Realm"].needs = { [333] = { name = "Enchanting",
            items = { [GREATER] = 2 }, gross = { [GREATER] = 2 }, have = { [GREATER] = 0 },
            when = { [GREATER] = 1 }, plan = { { spell = 999201 } } } }
          ComradeCraftDB.chars["Vez-Realm"].bags = {}
          me.bags = { [GREATER] = 1, [LESSER] = 6 }
          me.bank = {}
          me.needs = {}
          local nr = ns.NeedRows(ComradeCraftDB.chars["Vez-Realm"], LESSER)
          assert(#nr == 1 and nr[1].n == 6 and nr[1].convertsTo == GREATER, "transform NeedRows: Lesser shows 6 -> Greater")
          assert(ns.NeedOf(ComradeCraftDB.chars["Vez-Realm"], LESSER) == 6, "transform NeedOf: 6 Lesser")
          local sup = ns.GroupSupply(GREATER, "Vez-Realm")
          assert(sup == 3, "transform GroupSupply: 1 Greater + 6 Lesser = 3 Greater supply")
          local gl = ns.GiveList(ns.CharKey())
          local byItem = {}
          for _, g in ipairs(gl) do if g.to == "Vez-Realm" then byItem[g.item] = g end end
          assert(byItem[GREATER] and byItem[GREATER].n == 1 and not byItem[GREATER].convertsTo,
            "transform GiveList: direct 1 Greater first")
          assert(byItem[LESSER] and byItem[LESSER].n == 3 and byItem[LESSER].convertsTo == GREATER,
            "transform GiveList: then 3 Lesser (not 6!) -> Greater")
          assert(ns.Bags.ItemState(LESSER, "Vez-Realm") ~= nil, "transform Bags: Lesser highlighted for Greater need")
          -- Reverse direction: Vez needs 5 Lesser; we hold 2 Lesser + 3 Greater -> send 2 Lesser + 1 Greater!
          ComradeCraftDB.chars["Vez-Realm"].needs = { [333] = { name = "Enchanting",
            items = { [LESSER] = 5 }, gross = { [LESSER] = 5 }, have = { [LESSER] = 0 },
            when = { [LESSER] = 1 }, plan = { { spell = 999202 } } } }
          me.bags = { [LESSER] = 2, [GREATER] = 3 }
          local gl2 = ns.GiveList(ns.CharKey())
          local byItem2 = {}
          for _, g in ipairs(gl2) do if g.to == "Vez-Realm" then byItem2[g.item] = g end end
          assert(byItem2[LESSER] and byItem2[LESSER].n == 2, "transform GiveList rev: direct 2 Lesser first")
          assert(byItem2[GREATER] and byItem2[GREATER].n == 1 and byItem2[GREATER].convertsTo == LESSER,
            "transform GiveList rev: then 1 Greater -> 3 Lesser")
          assert(ns.Bags.ItemState(GREATER, "Vez-Realm") ~= nil, "transform Bags rev: Greater highlighted for Lesser need")
          -- Clean up temp recipes.
          ns.Recipes[999201], ns.Recipes[999202] = nil, nil
        end
        -- #14 Mail panel closes cleanly when Postbox hides (even if Send tab OnHide fires after).
        do
          local pbShown, sendShown, pbHideFn, sendHideFn = true, true, nil, nil
          local pbSend = {
            IsShown = function() return sendShown end,
            ToBox = { GetText = function() return "" end, SetText = function() end },
            HookScript = function(_, ev, fn) if ev == "OnHide" then sendHideFn = fn end end,
          }
          PostboxFrame = {
            IsShown = function() return pbShown end,
            Tabs = { send = pbSend },
            HookScript = function(_, ev, fn) if ev == "OnHide" then pbHideFn = fn end end,
          }
          f.onEvent(f, "MAIL_SHOW")
          assert(ComradeCraftMailPanel and ComradeCraftMailPanel:IsShown(), "mail panel: opens on MAIL_SHOW with Postbox")
          pbShown, sendShown = false, false
          if pbHideFn then pbHideFn() end
          if sendHideFn then sendHideFn() end
          assert(not ComradeCraftMailPanel:IsShown(), "mail panel: stays hidden when Postbox + Send tab hide")
          PostboxFrame = nil
          f.onEvent(f, "MAIL_CLOSED")
        end
        -- #15 Never suggest mailing items to yourself (Forever surname-as-realm repair, remote shadow, used intermediates).
        do
          -- 1. Corrupted "Jhf Mage-Mage" key merges into "Jhf Mage-Realm" EVEN when GetRealmName() returns ""!
          local savedRealmFn = GetRealmName
          local savedUnitFn = UnitName
          GetRealmName = function() return "" end
          UnitName = function() return "Jhf", "Mage" end
          ComradeCraftDB.chars["Jhf Mage-Mage"] = { class = "MAGE", bags = { [2589] = 21 }, updated = 200 }
          ComradeCraftDB.chars["Jhf Mage-CAMWOW US1 Realm 3 PvE"] = { class = "MAGE", bank = { [2589] = 36 },
            known = { [197] = { [2963] = true } }, updated = 100 }
          f.onEvent(f, "PLAYER_ENTERING_WORLD")
          assert(ns.CharKey() == "Jhf Mage-CAMWOW US1 Realm 3 PvE",
            "self-mail fix: RealmName skips bogus surname 'Mage', got " .. tostring(ns.CharKey()))
          assert(ComradeCraftDB.chars["Jhf Mage-CAMWOW US1 Realm 3 PvE"] and not ComradeCraftDB.chars["Jhf Mage-Mage"],
            "self-mail fix: corrupted surname-as-realm key merged cleanly")
          assert(ComradeCraftDB.chars["Jhf Mage-CAMWOW US1 Realm 3 PvE"].known
            and ComradeCraftDB.chars["Jhf Mage-CAMWOW US1 Realm 3 PvE"].known[197]
            and ComradeCraftDB.chars["Jhf Mage-CAMWOW US1 Realm 3 PvE"].bank
            and ComradeCraftDB.chars["Jhf Mage-CAMWOW US1 Realm 3 PvE"].bank[2589] == 36,
            "self-mail fix: known recipes & bank preserved on merge")
          -- New alt with no usable realm at all: borrows the account's realm instead of never saving.
          UnitName = function() return "Jhf", "Nainsuline" end
          local savedCVar = GetCVar
          GetCVar = function() return "" end
          ComradeCraftDB.chars["Jhf Mage-CAMWOW US1 Realm 3 PvE"].updated = 2 ^ 40 -- latest character
          ns.ResetRealmCache()
          assert(ns.CharKey() == "Jhf Nainsuline-CAMWOW US1 Realm 3 PvE",
            "new alt: borrows the account realm, got " .. tostring(ns.CharKey()))
          ns.CharData()
          assert(ComradeCraftDB.chars["Jhf Nainsuline-CAMWOW US1 Realm 3 PvE"], "new alt: saved")
          ComradeCraftDB.chars["Jhf Nainsuline-CAMWOW US1 Realm 3 PvE"] = nil
          -- Friend's DB with only first-name keys and no realm from the game: logging in on
          -- "Naine Tincelle" upgrades the stale "Naine-<realm>" key instead of never saving.
          local savedChars = ComradeCraftDB.chars
          local RLM = "CAMWOW US1 Realm 3 PvE"
          ComradeCraftDB.chars = { ["Naine-" .. RLM] = { class = "MAGE", shared = true, updated = 50, level = 20 },
            ["Wo-" .. RLM] = { class = "PRIEST", shared = true, updated = 40 } }
          UnitName = function() return "Naine", "Tincelle" end
          ns.ResetRealmCache()
          f.onEvent(f, "PLAYER_ENTERING_WORLD")
          local nt = ComradeCraftDB.chars["Naine Tincelle-" .. RLM]
          assert(nt and nt.shared and not ComradeCraftDB.chars["Naine-" .. RLM] and ComradeCraftDB.chars["Wo-" .. RLM],
            "first-name keys: upgraded to the full name on login, others untouched")
          assert(ns.CharKey() == "Naine Tincelle-" .. RLM and ns.CharData() == nt, "first-name keys: same record kept")
          ComradeCraftDB.chars = savedChars
          GetCVar = savedCVar
          ns.ResetRealmCache()
          GetRealmName, UnitName = savedRealmFn, savedUnitFn
          -- 2. Remote peer entry for same character under normalized realm is shadowed by local char.
          ComradeCraftDB.peers = ComradeCraftDB.peers or {}
          ComradeCraftDB.peers["p-dup"] = { included = true, name = "Friend" }
          ComradeCraftDB.remote = ComradeCraftDB.remote or {}
          ComradeCraftDB.remote["Jhf Mage-CAMWOWUS1Realm3PvE"] = { peer = "p-dup", class = "MAGE",
            needs = { [197] = { name = "Tailoring", items = { [2589] = 215 }, gross = { [2589] = 215 }, when = { [2589] = 2 } } } }
          local allC = ns.AllChars()
          assert(allC["Jhf Mage-CAMWOW US1 Realm 3 PvE"] and not allC["Jhf Mage-CAMWOWUS1Realm3PvE"],
            "self-mail fix: remote duplicate shadowed")
          local glSelf = ns.GiveList("Jhf Mage-CAMWOW US1 Realm 3 PvE")
          for _, g in ipairs(glSelf) do
            assert(not ns.IsSameChar(g.to, "Jhf Mage-CAMWOW US1 Realm 3 PvE"), "self-mail fix: never give to self")
          end
          -- 3. Owned intermediates in need.used are reserved by Surplus (never marked spare).
          local ic = { bags = { [2996] = 21 }, needs = { [197] = { gross = { [2589] = 215 }, used = { [2996] = 21 } } } }
          assert(ns.Surplus(ic, 2996) == 0, "self-mail fix: owned intermediate in need.used has 0 surplus")
          ComradeCraftDB.chars["Jhf Mage-CAMWOW US1 Realm 3 PvE"], ComradeCraftDB.remote["Jhf Mage-CAMWOWUS1Realm3PvE"], ComradeCraftDB.peers["p-dup"] = nil, nil, nil
        end
        -- #16 Bank companion panel, essence conversion hints, BoE pattern AH search, 1-click chat share.
        do
          -- Bank.Items lists both step-1/Wishlist bank items and bank-only group sends.
          local savedBank, savedBags, savedNeeds = me.bank, me.bags, me.needs
          me.bags = {}
          me.bank = { [2589] = 15, [2318] = 8 }
          me.needs = { [197] = { name = "Tailoring", gross = { [2589] = 10 }, items = { [2589] = 10 }, when = { [2589] = 1 } } }
          ComradeCraftDB.chars["Vez-Realm"] = { class = "ROGUE", needs = { [165] = { name = "Leatherworking",
            items = { [2318] = 5 }, gross = { [2318] = 5 }, when = { [2318] = 1 } } } }
          local bi = ns.Bank.Items()
          local bMap = {}
          for _, it in ipairs(bi) do bMap[it.item] = it end
          assert(bMap[2589] and bMap[2589].n == 10, "bank: withdraws 10 Linen for own step-1 plan")
          assert(bMap[2318] and bMap[2318].n == 5, "bank: withdraws 5 Light Leather to send to Vez")
          me.bank, me.bags, me.needs = savedBank, savedBags, savedNeeds
          -- ConversionHints: 3x Lesser -> 1x Greater and 1x Greater -> 3x Lesser.
          ns.Recipes[999301] = { 333, 50, 100, 1, 0, 1, { 10939, 1 } }
          ns.Recipes[999302] = { 333, 50, 100, 1, 0, 1, { 10938, 2 } }
          local h1 = ns.ConversionHints(999301, 1, { [10938] = 3 })
          assert(#h1 == 1 and h1[1].fromItem == 10938 and h1[1].fromQty == 3 and h1[1].toItem == 10939 and h1[1].toQty == 1,
            "conv hint: 3x Lesser -> 1x Greater")
          assert(ns.FormatConversionHints(h1):find("3x", 1, true), "conv hint: formatted")
          local h2 = ns.ConversionHints(999302, 1, { [10939] = 1 })
          assert(#h2 == 1 and h2[1].fromItem == 10939 and h2[1].fromQty == 1 and h2[1].toItem == 10938 and h2[1].toQty == 3,
            "conv hint: 1x Greater -> 3x Lesser")
          assert(#ns.ConversionHints(999301, 1, { [10939] = 1 }) == 0, "conv hint: none when direct essence owned")
          ns.Recipes[999301], ns.Recipes[999302] = nil, nil
          -- AuctionPanel.BoEPatterns: surfaces non-BoP recipeItem from Audit.Run().
          local savedAuditRun = ns.Audit.Run
          ns.Audit.Run = function()
            return { { targetKey = "Test-Realm", patterns = { { recipeItem = 7361, crafter = "Test-Realm" } } } }
          end
          local bp = ns.AuctionPanel.BoEPatterns()
          local found7361 = false
          for _, e in ipairs(bp) do if e.item == 7361 then found7361 = true end end
          assert(found7361, "AH BoE patterns: includes non-BoP recipe scroll")
          ns.Audit.Run = savedAuditRun
          -- ShareChat: posts to GUILD when in guild, strips color codes, caps <=240 chars.
          local sentMsg, sentChan
          IsInGuild = function() return true end
          SendChatMessage = function(m, c) sentMsg, sentChan = m, c end
          local ch = ns.ShareChat("|cff40ff40[ComradeCraft]|r test")
          assert(ch == "GUILD" and sentChan == "GUILD" and sentMsg == "[ComradeCraft] test", "share chat: sends clean guild msg")
          IsInGuild, SendChatMessage = nil, nil
        end
        -- #17 Mesh Sync relay, Guild channel pulse sync, Shared bank alt & bank item requests.
        do
          local Sync, Req = ns.Sync, ns.Requests
          local sent = {}
          local savedTransport = Sync.transport
          Sync.transport = function(txt, dist, target)
            sent[#sent + 1] = { msg = Sync.Decode(txt), dist = dist, target = target }
          end
          -- 1. Shared bank alt: 100% surplus, 0 leveling needs, auto-shared, synced in Record/Summary.
          ComradeCraftDB.chars["Banky-Realm"] = { class = "WARRIOR", level = 1, bags = { [2589] = 40 }, bank = { [4306] = 60 },
            professions = { Tailoring = { skillLine = 197, rank = 1, max = 75 } }, known = { [197] = { [2963] = true } } }
          Sync.SetBankAlt("Banky-Realm", true)
          local bc = ComradeCraftDB.chars["Banky-Realm"]
          assert(bc.bankAlt and bc.shared, "bankAlt: auto-shares and flags character")
          assert(not next(bc.needs or {}), "bankAlt: zero leveling needs")
          assert(ns.Surplus(bc, 2589) == 40 and ns.Surplus(bc, 4306) == 60, "bankAlt: 100% stock is surplus")
          -- Render Shared bank alt sheet without errors.
          ComradeCraftDB.ui.sel = "Banky-Realm"
          ns.RefreshWindow()
          -- 2. Mesh Sync: peer A relays peer B's newer bank alt snapshot to us (mutually included only!).
          ComradeCraftDB.peers["peerA"] = { included = true, name = "Alice", chars = {} }
          ComradeCraftDB.peers["peerB"] = { included = true, name = "Bob", chars = {} }
          ComradeCraftDB.peers["stranger"] = { included = false, name = "Mallory", chars = {} }
          sent = {}
          -- Peer A sends HELLO advertising Mesh index for peerB (newer ts=500) and stranger (must be ignored!).
          local hFromA = Sync.Encode({ t = "H", v = Sync.PROTO, id = "peerA", r = true, c = {},
            m = { peerB = { ["BobBank-Realm"] = 500 }, stranger = { ["Evil-Realm"] = 999 } } })
          Sync.OnMessage(hFromA, "WHISPER", "Alice")
          local reqMsg
          for _, s in ipairs(sent) do if s.msg and s.msg.t == "R" then reqMsg = s.msg end end
          assert(reqMsg and reqMsg.rk and #reqMsg.rk == 1 and reqMsg.rk[1].p == "peerB" and reqMsg.rk[1].k == "BobBank-Realm",
            "mesh sync: requests newer record for mutually trusted peerB, ignores untrusted stranger")
          -- Peer A sends relayed DATA (orig = peerB, bankAlt = true, 80 Silk Cloth).
          local dRelayed = Sync.Encode({ t = "D", v = Sync.PROTO, id = "peerA", orig = "peerB", key = "BobBank-Realm",
            rec = { class = "MAGE", level = 1, bankAlt = true, updated = 500, owned = { [4306] = 80 }, professions = {}, known = {} } })
          Sync.OnMessage(dRelayed, "WHISPER", "Alice")
          local rb = ComradeCraftDB.remote["BobBank-Realm"]
          assert(rb and rb.peer == "peerB" and rb.relayedBy == "peerA" and rb.bankAlt and rb.bags[4306] == 80,
            "mesh sync: stores relayed bankAlt under origin peerB")
          -- Relay security: peer A trying to spoof untrusted stranger is rejected.
          local dBad = Sync.Encode({ t = "D", v = Sync.PROTO, id = "peerA", orig = "stranger", key = "Evil-Realm",
            rec = { class = "MAGE", level = 1, updated = 999, owned = { [4306] = 99 }, professions = {}, known = {} } })
          Sync.OnMessage(dBad, "WHISPER", "Alice")
          assert(not ComradeCraftDB.remote["Evil-Realm"], "mesh sync security: rejects relay for non-included origin")
          -- 3. Guild channel pulse: peerA switches to a new alt "AliceAlt" -> sends guild P -> we reply to AliceAlt!
          sent = {}
          local gPulse = Sync.Encode({ t = "P", v = Sync.PROTO, id = "peerA", u = 900 })
          Sync.OnMessage(gPulse, "GUILD", "AliceAlt")
          assert(ComradeCraftDB.peers["peerA"].name == "AliceAlt", "guild sync: updates peer name on alt switch")
          local repliedToNewAlt = false
          for _, s in ipairs(sent) do if s.msg and s.msg.t == "H" and s.target == "AliceAlt" then repliedToNewAlt = true end end
          assert(repliedToNewAlt, "guild sync: whispers HELLO to peer's new alt immediately")
          -- 4. Bank item request (spell = 0, item = 4306) to remote Shared bank alt -> wire Clean + accept!
          local itemReq = Req.CreateItem("BobBank-Realm", 4306, 20, "need silk")
          assert(itemReq and itemReq.spell == 0 and itemReq.item == 4306 and itemReq.qty == 20, "bank request: created")
          local cleaned = Req.Clean({ rid = itemReq.id, from = itemReq.from, to = "Banky-Realm", spell = 0, item = 4306,
            qty = 20, status = "pending", u = 100, c = 100 })
          assert(cleaned and cleaned.spell == 0 and cleaned.item == 4306, "bank request: Clean accepts spell=0 + item")
          -- Cleanup.
          ComradeCraftDB.requests[itemReq.id] = nil
          ComradeCraftDB.chars["Banky-Realm"] = nil
          ComradeCraftDB.remote["BobBank-Realm"] = nil
          ComradeCraftDB.peers["peerA"], ComradeCraftDB.peers["peerB"], ComradeCraftDB.peers["stranger"] = nil, nil, nil
          Sync.transport = savedTransport
        end
        -- #18 Item Reserve ("for Mirandaa"), Baganator/BetterBags native categories, Favorites & Preferred Crafters.
        do
          local savedBags, savedBank, savedRes = me.bags, me.bank, me.reserved
          me.bags = { [4306] = 15 }
          me.bank = { [4306] = 10 }
          me.reserved = nil
          ComradeCraftDB.chars["Mirandaa Jenkins-Realm"] = { class = "DRUID", level = 20, shared = true, needs = {} }
          -- Reserve 12 Silk Cloth for Mirandaa -> violet lock badge, protected from vendor/AH, excluded from other surplus, queued in Mail.
          assert(ns.Reserve.Set(4306, "Mirandaa Jenkins-Realm", 12), "reserve: set 12 Silk for Mirandaa")
          assert(ns.Reserve.Get(4306).qty == 12, "reserve: stored on char")
          assert(ns.Surplus(me, 4306) == 13, "reserve: 25 owned - 12 reserved = 13 spare for others")
          local st = ns.Bags.ItemState(4306)
          assert(st and st.mode == "reserved" and st.reserved, "reserve: bag highlight uses reserved lock mode")
          local mItems = ns.Mail.ItemsFor("Mirandaa Jenkins-Realm")
          local foundRes
          for _, it in ipairs(mItems) do if it.item == 4306 and it.reserved then foundRes = it end end
          assert(foundRes and foundRes.inBags == 12, "reserve: auto-queued in Mail for Mirandaa")
          -- Recipient sees IncomingFor before mail is sent!
          local inc = ns.Reserve.IncomingFor("Mirandaa Jenkins-Realm", 4306)
          assert(#inc == 1 and inc[1].from == ns.CharKey() and inc[1].qty == 12, "reserve: recipient sees incoming reservation")
          -- Keep alert protects reserved items even when nobody has a leveling need for them.
          local wanted = ns.Alerts.Wanted(4306)
          assert(#wanted >= 1 and wanted[1].n == 12, "reserve: Keep alert protects reserved item from vendor/AH")
          -- Auto-prune clears reservation once item leaves bags+bank.
          me.bags, me.bank = {}, {}
          ns.Reserve.Prune()
          assert(ns.Reserve.Get(4306) == nil, "reserve: auto-pruned once sent")
          -- Favorites & Preferred Crafters.
          assert(ns.ToggleFavorite("Mirandaa Jenkins-Realm") == true and ns.IsFavorite("Mirandaa Jenkins-Realm"), "favorites: star on")
          assert(ns.ToggleFavorite("Mirandaa Jenkins-Realm") == false and not ns.IsFavorite("Mirandaa Jenkins-Realm"), "favorites: star off")
          -- Request full lifecycle: Progress (missing -> craft -> ship) + auto-crafting + auto-shipped on Mail/Trade!
          me.bags = {}
          me.bank = {}
          local rq = { id = "req-auto-1", from = "Mirandaa Jenkins-Realm", to = ns.CharKey(), fromPeer = "p-m",
            spell = 2963, item = 2996, qty = 2, status = "accepted", created = 100, updated = 100 }
          ComradeCraftDB.requests["req-auto-1"] = rq
          local pMiss = ns.Requests.Progress(rq)
          assert(pMiss and pMiss.state == "missing", "req progress: missing mats")
          me.bags = { [2589] = 10 }
          local pCraft = ns.Requests.Progress(rq)
          assert(pCraft and pCraft.state == "craft", "req progress: ready to craft")
          -- Casting the spell auto-advances accepted -> crafting!
          f.onEvent(f, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 2963)
          assert(rq.status == "crafting", "req auto: spellcast advances accepted -> crafting")
          me.bags = { [2996] = 2 }
          local pShip = ns.Requests.Progress(rq)
          assert(pShip and pShip.state == "ship", "req progress: ready to ship")
          -- Mailing/trading the item auto-marks request as shipped!
          assert(ns.Requests.OnItemSent("Mirandaa Jenkins-Realm", 2996, 2) == 1 and rq.status == "shipped",
            "req auto: OnItemSent auto-marks request as shipped")
          -- Render Overview (Reserved banner), Materials, Upgrades (zebra + ownCrafter), Requests without errors.
          ComradeCraftDB.ui.sel, ComradeCraftDB.ui.groupTab = "group", "overview"
          ns.RefreshWindow()
          ComradeCraftDB.ui.sel = "requests"
          ns.RefreshWindow()
          -- #19 Blizzard Options, per-panel toggles, UI scale, ResetPositions, LDB, keybinding, active Forever recipe bounds.
          assert(ns.PanelEnabled("mail") and ns.PanelEnabled("bank"), "options: companion panels enabled by default")
          ns.SetPanelEnabled("merchant", false)
          assert(not ns.PanelEnabled("merchant"), "options: merchant panel disabled")
          ns.SetPanelEnabled("merchant", true)
          assert(ns.SetUIScale(1.15) == 1.15 and ns.UIScale() == 1.15, "options: UI scale stored and clamped")
          assert(ns.SetUIScale(2.0) == 1.25 and ns.SetUIScale(0.5) == 0.75, "options: UI scale bounds enforced")
          ns.SetUIScale(1.0)
          ns.ResetPositions()
          ns.PlaySound("lock")
          ComradeCraft_OnAddonCompartmentClick(nil, "LeftButton")
          if ns.UpdateLDB then ns.UpdateLDB() end
          -- Active Forever recipe difficulty bound calibration (ScanKnownRecipes -> ObserveRecipeBound).
          local savedRec2963 = { ns.Recipes[2963][2], ns.Recipes[2963][3] }
          C_TradeSkillUI = {
            GetChildProfessionInfo = function() return { parentProfessionID = 197, skillLevel = 80 } end,
            GetAllRecipeIDs = function() return { 2963 } end,
            GetRecipeInfo = function() return { learned = true, relativeDifficulty = 0 } end,
          }
          f.onEvent(f, "TRADE_SKILL_LIST_UPDATE")
          assert(ns.Recipes[2963][2] >= 81 and ComradeCraftDB.recipeBounds and ComradeCraftDB.recipeBounds[2963],
            "forever calibration: orange at rank 80 raises yellow bound >= 81")
          ns.Recipes[2963][2], ns.Recipes[2963][3] = savedRec2963[1], savedRec2963[2]
          ComradeCraftDB.recipeBounds, C_TradeSkillUI = nil, nil
          -- ResolveFullName: resolves 1-word legacy peer keys via PostboxDB history, peer names, and RememberFullName.
          PostboxDB = { config = { recipientHistory = { "Mirandaa Jenkins", "Naine Tincelle" } } }
          assert(ns.ResolveFullName("Mirandaa") == "Mirandaa Jenkins", "resolve full name: via PostboxDB recipientHistory")
          PostboxDB = nil
          assert(ns.ResolveFullName("Mirandaa") == "Mirandaa Jenkins", "resolve full name: cached in ComradeCraftDB.fullNames")
          ComradeCraftDB.fullNames = nil
          -- Expert Cookbook TomTom waypoint for Alliance (Shandrina, Ashenvale uiMap 1440) even without Questie!
          local wpMap, wpTitle
          local savedTT, savedFac = TomTom, UnitFactionGroup
          UnitFactionGroup = function() return "Alliance" end
          TomTom = { AddWaypoint = function(_, m, x, y, opts) wpMap, wpTitle = m, opts and opts.title end }
          local raCookA = ns.RankAdvice({ skillLine = 185, rank = 150, max = 150 })
          local eCook = raCookA and raCookA.entries[1]
          assert(eCook and eCook.npc == 3955 and eCook.fallbackPlace and eCook.fallbackPlace.uiMap == 1440,
            "shandrina: Expert Cookbook entry carries Shandrina npc + fallback coords")
          assert(ns.WaypointNpc(eCook.npc, eCook.npcName, eCook.zone, eCook.fallbackPlace) and wpMap == 1440,
            "shandrina: TomTom waypoint set to Ashenvale (1440)")
          -- Every Expert (150) & Artisan (225) trainer/vendor entry has fallback TomTom coords!
          for cap, byLine in pairs(ns.RANK_TRAINERS) do
            for ln, tlist in pairs(byLine) do
              for _, t in ipairs(tlist) do
                assert(t[5] and t[5].uiMap and t[5].x and t[5].y, "rank trainer coords missing: " .. tostring(t[2]))
              end
            end
          end
          -- PatternsForCrafter + Patterns tab render (self + group benefits, drop rates, waypoints).
          local savedEnchRank = me.professions.Enchanting
          me.professions.Enchanting = { skillLine = 333, rank = 270, max = 300 }
          me.known[333] = {}
          local pList = ns.Audit.PatternsForCrafter(ns.CharKey())
          assert(type(pList) == "table" and #pList >= 1, "patterns tab: surfaces unlearned valuable enchants/patterns")
          ComradeCraftDB.ui.sel, ComradeCraftDB.ui.tab = ns.CharKey(), "patterns"
          ns.RefreshWindow()
          me.professions.Enchanting = savedEnchRank
          -- Expert Cookbook (16072) rank-book status: known once max >= 225, unknown when max == 150!
          local savedCook = me.professions.Cooking
          me.professions.Cooking = { skillLine = 185, rank = 150, max = 225 }
          ComradeCraftDB.chars["Naine-Realm"] = { class = "HUNTER", professions = { Cooking = { skillLine = 185, rank = 144, max = 150 } } }
          local stBook = ns.Loot.RecipeStatus(16072)
          assert(stBook and stBook.isRankBook and #stBook.known == 1 and stBook.known[1].key == ns.CharKey()
            and #stBook.unknown == 1 and stBook.unknown[1].key == "Naine-Realm",
            "rank book status: max 225 = known, max 150 = unknown")
          -- Embedded Classic drop rates (358 recipes) + optional live connector (ForeverDrops/Lootified).
          local drCount = 0
          for _ in pairs(ns.DropRates or {}) do drCount = drCount + 1 end
          assert(drCount >= 300, "droprates: embedded table has >= 300 recipe drop rates")
          ForeverDrops = { GetDropRate = function(id) return id == 99999 and 12.5 or nil end }
          assert(ns.DropRateText(99999) == "12.5%", "droprates: optional ForeverDrops connector")
          ForeverDrops = nil
          -- Cross-language profession names: localized via C_TradeSkillUI / spell API regardless of peer language.
          C_TradeSkillUI = { GetTradeSkillDisplayName = function(ln) return ln == 185 and "Cooking" or nil end }
          assert(ns.ProfName(185, "Cuisine") == "Cooking", "profname: translates peer French 'Cuisine' -> local 'Cooking'")
          C_TradeSkillUI = nil
          me.professions.Cooking = savedCook
          ComradeCraftDB.chars["Naine-Realm"] = nil
          TomTom, UnitFactionGroup = savedTT, savedFac
          ComradeCraftDB.requests["req-auto-1"] = nil
          me.bags, me.bank, me.reserved = savedBags, savedBank, savedRes
          ComradeCraftDB.chars["Mirandaa Jenkins-Realm"] = nil
        end
        Bagnon, ComradeCraftDB.chars["Vez-Realm"], ComradeCraftDB.chars["Mirandaa Jenkins-Realm"] = nil, nil, nil

        -- #20 v0.4.0 innovation suite: ForeverDB P2P, ZoneRadar, AH Bargains & Search, Craft Chains.
        do
          -- 1. ForeverDB P2P crowd-calibration: payload + remote merge + DropRate + Vendor + /comrade forever.
          ComradeCraftDB.recipeBounds = ComradeCraftDB.recipeBounds or {}
          ComradeCraftDB.foreverDrops = ComradeCraftDB.foreverDrops or {}
          ComradeCraftDB.foreverVendors = ComradeCraftDB.foreverVendors or {}
          ComradeCraftDB.recipeBounds[2963] = { y = 25, g = 45 }
          ComradeCraftDB.foreverDrops[88881] = { d = 3, k = 30, npc = 5555, name = "Rare Wolf", map = 1440, x = 42, y = 61, rare = true }
          ComradeCraftDB.foreverVendors[16072] = { npc = 3413, name = "Shandrina", map = 1440, x = 49, y = 67, cost = 10000 }
          local fp = ns.ForeverDB.Payload()
          assert(fp and fp.t == "F" and fp.b[2963] and fp.d[88881] and fp.ve[16072], "foreverdb: payload built")
          local savedBounds, savedDrops, savedVend = ComradeCraftDB.recipeBounds, ComradeCraftDB.foreverDrops, ComradeCraftDB.foreverVendors
          ComradeCraftDB.recipeBounds, ComradeCraftDB.foreverDrops, ComradeCraftDB.foreverVendors = {}, {}, {}
          assert(ns.ForeverDB.OnRemote("peer-f1", fp), "foreverdb: OnRemote merges peer packet")
          local pct, kills = ns.ForeverDB.DropRate(88881)
          assert(pct == 10 and kills == 30, "foreverdb: peer DropRate 3/30 = 10%")
          assert(ns.DropRateText(88881) == "10%", "foreverdb: DropRateText uses peer ForeverDB rate")
          local fv = ns.ForeverDB.Vendor(16072)
          assert(fv and fv.name == "Shandrina" and fv.map == 1440, "foreverdb: peer Vendor lookup")
          SlashCmdList.COMRADECRAFT("forever")
          ComradeCraftDB.recipeBounds, ComradeCraftDB.foreverDrops, ComradeCraftDB.foreverVendors = savedBounds, savedDrops, savedVend
          ComradeCraftDB.foreverPeers["peer-f1"] = nil

          -- 2. ZoneRadar: surfaces Ashenvale rank vendor (Shandrina) + ForeverDB rare mob drop in map 1440.
          local savedCook = me.professions.Cooking
          me.professions.Cooking = { skillLine = 185, rank = 145, max = 150 }
          local savedFac = UnitFactionGroup
          UnitFactionGroup = function() return "Alliance" end
          local zHits, zName = ns.ZoneRadar.Scan(1440)
          local hasRare, hasVend = false, false
          for _, h in ipairs(zHits) do
            if h.kind == "rare" and h.item == 88881 then hasRare = true end
            if h.kind == "vendor" and h.npcName == "Shandrina" then hasVend = true end
          end
          assert(hasRare and hasVend, "zoneradar: detects both rare mob drop and rank vendor in Ashenvale (1440)")
          me.professions.Cooking = savedCook
          UnitFactionGroup = savedFac
          ComradeCraftDB.foreverDrops[88881], ComradeCraftDB.foreverVendors[16072] = nil, nil

          -- 3. AH Bargain Radar + Auctionator MultiSearchExact + Blizzard SearchBar.
          local savedNeeds = me.needs
          me.needs = { [197] = { name = "Tailoring", items = { [77777] = 20 }, gross = { [77777] = 20 }, have = { [77777] = 0 }, when = { [77777] = 1 } } }
          ComradeCraftDB.ahSeen = { [77777] = { avg = 1000, n = 5 } }
          ns.AuctionPanel.ObserveListing(77777, 500) -- 50% below local avg!
          local deals = ns.AuctionPanel.Bargains()
          assert(#deals >= 1 and deals[1].item == 77777 and deals[1].pct == 50, "ah bargains: detects 50% underpriced group mat without TSM")
          local aucSearched
          Auctionator = { API = { v1 = { MultiSearchExact = function(_, terms) aucSearched = terms[1] end } } }
          f.onEvent(f, "AUCTION_HOUSE_SHOW")
          ns.AuctionPanel.SearchItem(2589)
          assert(aucSearched == "Item2589", "ah search: calls Auctionator.API.v1.MultiSearchExact when Shopping active")
          f.onEvent(f, "AUCTION_HOUSE_CLOSED")
          Auctionator, me.needs, ComradeCraftDB.ahSeen = nil, savedNeeds, nil

          -- 4. Multi-profession Craft Chain: resolves missing intermediate Bolt (2996) -> final craft (2385).
          ComradeCraftDB.chars["PeerTailor-Realm"] = { peer = "p-chain", class = "MAGE", known = { [197] = { [2963] = true } }, bags = {} }
          ComradeCraftDB.chars["PeerFinisher-Realm"] = { peer = "p-fin", class = "PRIEST", known = { [197] = { [2385] = true } }, bags = {} }
          local savedMyBags, savedMyKnown = me.bags, me.known
          me.bags, me.known = {}, {}
          local chain = ns.Requests.BuildChain("PeerFinisher-Realm", 2385, 2)
          assert(#chain == 2 and chain[1].spell == 2963 and chain[1].to == "PeerTailor-Realm"
            and chain[1].deliverTo == "PeerFinisher-Realm"
            and chain[2].spell == 2385 and chain[2].to == "PeerFinisher-Realm",
            "craft chain: resolves missing intermediate Bolt -> final craft with direct deliverTo")
          me.bags, me.known = savedMyBags, savedMyKnown
          ComradeCraftDB.chars["PeerTailor-Realm"], ComradeCraftDB.chars["PeerFinisher-Realm"] = nil, nil
        end

        -- 20. Co-op Craft v0.4 suite: ForeverDB bounds+customRecipes+DE, Sync Delta+BankAlt+InTransit,
        --     Multi-prof needs deduction, Partial ship & Chain v2, Wishlist Kits+AutoDec, Bank reagents,
        --     Tracker OrdersQueue, and UI smoke renders.
        do
          local FDB = ns.ForeverDB
          -- 20a. ForeverDB recipeBounds round-trip + customRecipes P2P sync + calibrated DE.
          local origY, origG = ns.Recipes[2963][2], ns.Recipes[2963][3]
          ComradeCraftDB.recipeBounds[2963] = { y = origY + 7, g = origG + 11 }
          ComradeCraftDB.customRecipes[999501] = { 197, 55, 80, 1, 2996, 1, { 2589, 3 } }
          ComradeCraftDB.disenchants = { raw = {} }
          for i = 1, 5 do
            ComradeCraftDB.disenchants.raw[i] = { item = 88801, reqLevel = 12, quality = 2, classID = 4, loot = { [10940] = 4 } }
          end
          ns.InvalidateDECache()
          local fpay = FDB.Payload()
          assert(fpay and fpay.b and fpay.b[2963] and fpay.b[2963][1] == origY + 7, "foreverdb: recipeBounds encoded from {y,g}")
          assert(fpay.cr and fpay.cr[999501] and fpay.cr[999501][1] == 197, "foreverdb: customRecipes encoded")
          assert(fpay.de and fpay.de["2:15:0"] and fpay.de["2:15:0"][1] == 5, "foreverdb: DE buckets encoded")
          -- Receive on a clean peer side: custom recipe & bounds applied immediately.
          ns.Recipes[999501], ComradeCraftDB.customRecipes[999501], ComradeCraftDB.recipeBounds[2963] = nil, nil, nil
          assert(FDB.OnRemote("peer-fdb2", fpay), "foreverdb: OnRemote merges cr + bounds + de")
          assert(ns.Recipes[999501] and ns.Recipes[999501][1] == 197, "foreverdb: custom recipe injected into ns.Recipes")
          assert(ns.Recipes[2963][2] == origY + 7 and ns.Recipes[2963][3] == origG + 11, "foreverdb: ApplyRecipeBounds applied live")
          -- Empirical DE overrides Classic estimate once >= 5 samples.
          local prevGII = GetItemInfo
          GetItemInfo = function(id)
            if id == 88801 then return "Test Robe", "|Hitem:88801|h[Test Robe]|h", 2, 16, 12, nil, nil, nil, "INVTYPE_CHEST", nil, 100, 4, 1 end
            return prevGII(id)
          end
          local dy, cal, cnt = ns.DisenchantYield(88801)
          assert(cal and cnt >= 5 and dy and math.abs(dy[10940] - 4) < 0.01, "disenchant: uses calibrated Forever average")
          GetItemInfo = prevGII
          ns.Recipes[2963][2], ns.Recipes[2963][3] = origY, origG
          ns.Recipes[999501], ComradeCraftDB.customRecipes[999501], ComradeCraftDB.recipeBounds[2963] = nil, nil, nil
          ComradeCraftDB.disenchants = { raw = {} }
          if ComradeCraftDB.foreverPeers then ComradeCraftDB.foreverPeers["peer-fdb2"] = nil end
          ns.InvalidateDECache()

          -- 20b. Sync Bank Alt non-ItemPrices + Stock Delta ("S") + Mail In-Transit.
          ComradeCraftDB.peers["p-delta"] = { included = true, name = "DeltaPeer", chars = {} }
          ComradeCraftDB.remote["DeltaBank-Realm"] = { peer = "p-delta", class = "WARRIOR", bankAlt = true, updated = 100,
            professions = {}, known = {}, bags = {} }
          local sEnc = ns.Sync.Encode({ t = "S", v = ns.Sync.PROTO, id = "p-delta", key = "DeltaBank-Realm",
            s = { u = 200, owned = { [998877] = 5 }, inTransit = {
              { t = ns.CharKey(), i = 2589, q = 12, s = time(), a = time() + 3000 }
            } } })
          ns.Sync.OnMessage(sEnc, "WHISPER", "DeltaPeer")
          assert(ComradeCraftDB.remote["DeltaBank-Realm"].bags[998877] == 5, "sync S: Bank Alt accepts item outside ItemPrices")
          local trTot, trList = ns.InTransitFor(ns.CharKey(), 2589)
          assert(trTot == 12 and #trList == 1, "inTransit: tracked from remote Stock Delta")
          ComradeCraftDB.remote["DeltaBank-Realm"], ComradeCraftDB.peers["p-delta"] = nil, nil

          -- 20c. Partial shipment on Requests.OnItemSent.
          local reqId = "partial-req-1"
          ComradeCraftDB.requests[reqId] = { id = reqId, from = "PartialPeer-Realm", to = ns.CharKey(), fromPeer = "p-partial",
            spell = 2963, item = 2996, qty = 5, status = "accepted", created = time(), updated = time() }
          ns.Requests.OnItemSent("PartialPeer-Realm", 2996, 2)
          assert(ComradeCraftDB.requests[reqId].status == "accepted" and ComradeCraftDB.requests[reqId].sentQty == 2,
            "requests: partial shipment keeps status accepted and tracks sentQty")
          ns.Requests.OnItemSent("PartialPeer-Realm", 2996, 3)
          assert(ComradeCraftDB.requests[reqId].status == "shipped" and ComradeCraftDB.requests[reqId].sentQty == 5,
            "requests: completing remaining qty marks shipped")
          ComradeCraftDB.requests[reqId] = nil

          -- 20d. Wishlist Kits + Auto-decrement on craft + Bank incoming request reagent withdraw + Tracker OrdersQueue.
          local savedWl = ComradeCraftDB.wishlist
          ComradeCraftDB.wishlist = {}
          ns.Wishlist.Add(2963, 2, "Vez", "kit test", true, ns.CharKey())
          assert(ns.Wishlist.SaveKit("Raid Kit"), "kits: SaveKit saves current wishlist")
          assert(ns.Wishlist.OnCrafted(2963) and ComradeCraftDB.wishlist[1].qty == 1, "wishlist: OnCrafted decrements qty")
          assert(ns.Wishlist.OnCrafted(2963) and #ComradeCraftDB.wishlist == 0, "wishlist: OnCrafted removes at 0")
          assert(ns.Wishlist.ApplyKit("Raid Kit", 2) == 1 and ComradeCraftDB.wishlist[1].qty == 4, "kits: ApplyKit x2 adds 4x")
          -- Bank withdraws missing reagents for an accepted incoming craft request.
          local savedBank, savedBags = me.bank, me.bags
          me.bags = {}
          me.bank = { [2589] = 10 }
          ComradeCraftDB.requests["bank-reag-1"] = { id = "bank-reag-1", from = "Vez-Realm", to = ns.CharKey(),
            fromPeer = "p-vez", spell = 2963, item = 2996, qty = 3, status = "accepted", created = time(), updated = time() }
          local bItems = ns.Bank.Items()
          local foundReag = false
          for _, bi in ipairs(bItems) do if bi.item == 2589 and bi.n >= 6 then foundReag = true end end
          assert(foundReag, "bank: queues reagents in bank for accepted incoming craft request")
          -- Tracker OrdersQueue lists incoming request + wishlist for Tailoring (197).
          local oq = ns.OrdersQueue(me, 197)
          assert(#oq == 1 and oq[1].spell == 2963 and oq[1].n == 7, "tracker: OrdersQueue merges request (3) + wishlist (4)")
          ComradeCraftDB.requests["bank-reag-1"] = nil
          me.bank, me.bags = savedBank, savedBags
          ns.Wishlist.DeleteKit("Raid Kit")
          ComradeCraftDB.wishlist = savedWl

          -- 20e. UI smoke render: Group unified search, Wishlist kits, Requests chains, Manage ForeverDB.
          ComradeCraftDB.ui.sel, ComradeCraftDB.ui.groupTab = "group", "overview"
          ns.UI.RenderGroup("linen")
          ComradeCraftDB.ui.sel = "wishlist"
          ns.RefreshWindow()
          ComradeCraftDB.ui.sel = "requests"
          ns.RefreshWindow()
          ComradeCraftDB.ui.sel = "manage"
          ns.RefreshWindow()

          -- 20f. Async item name resolution + locale-scoped SavedVariables cache (no stuck "item:2604").
          local reqLoaded = nil
          local savedGII2 = GetItemInfo
          local savedCItem = C_Item
          C_Item = { RequestLoadItemDataByID = function(id) reqLoaded = id end }
          GetItemInfo = function(id)
            if id == 2604 then return nil end
            return savedGII2(id)
          end
          assert(ns.ItemName(2604) == "item:2604", "item name: fallback while uncached")
          assert(reqLoaded == 2604 and ns.UI.missingItems[2604] == true, "item name: requests async load & tracks missing")
          GetItemInfo = function(id)
            if id == 2604 then return "Red Dye" end
            return savedGII2(id)
          end
          f.onEvent(f, "GET_ITEM_INFO_RECEIVED", 2604, true)
          assert(ns.UI.missingItems[2604] == nil and ns.CachedItemName(2604) == "Red Dye", "item name: resolves & caches on event")
          -- Even if WoW cache drops it next session, SavedVariables cache prevents "item:2604" flicker.
          GetItemInfo = function(id)
            if id == 2604 then return nil end
            return savedGII2(id)
          end
          assert(ns.ItemName(2604) == "Red Dye", "item name: returns persisted locale cache when uncached")
          GetItemInfo, C_Item = savedGII2, savedCItem

          -- 20g. Self-duplicate elimination on Forever (1-word w/ shared first name, realm variant, remote relay).
          local savedRU = RegionalUniqueNamesEnabled
          local savedUNU = UnitNameUnmodified
          local savedUC = UnitClass
          local savedUL = UnitLevel
          RegionalUniqueNamesEnabled = function() return true end
          UnitNameUnmodified = function() return "Jhf", "Mage" end
          UnitClass = function() return "Mage", "MAGE" end
          UnitLevel = function() return 34 end
          ComradeCraftDB.chars["Jhf Mage-Realm"] = { class = "MAGE", level = 34, updated = 2000, shared = true, bags = {}, professions = {}, known = {} }
          ComradeCraftDB.chars["Jhf Priest-Realm"] = { class = "PRIEST", level = 20, updated = 1500, bags = {}, professions = {}, known = {} }
          ComradeCraftDB.chars["Jhf-Realm"] = { class = "MAGE", level = 33, updated = 1000, listed = true, bags = {}, professions = {}, known = {} }
          ComradeCraftDB.chars["Jhf Mage-RealmAlias"] = { class = "MAGE", level = 33, updated = 900, bags = {}, professions = {}, known = {} }
          ComradeCraftDB.peers["p-dup"] = { included = true, name = "Alice", chars = {} }
          ComradeCraftDB.remote["Jhf Mage-OtherSpelling"] = { peer = "p-dup", class = "MAGE", level = 33, updated = 1200, bags = {}, professions = {}, known = {} }
          ComradeCraftDB.remote["Jhf-Realm"] = { peer = "p-dup", class = "MAGE", level = 33, updated = 1100, bags = {}, professions = {}, known = {} }
          -- Incoming peer DATA for our own char under another realm spelling must be ignored.
          local dupEnc = ns.Sync.Encode({ t = "D", v = ns.Sync.PROTO, id = "p-dup", key = "Jhf Mage-RelayRealm",
            rec = { class = "MAGE", level = 32, updated = 1300, professions = {}, known = {}, owned = {} } })
          ns.Sync.OnMessage(dupEnc, "WHISPER", "Alice")
          assert(ComradeCraftDB.remote["Jhf Mage-RelayRealm"] == nil, "sync D: refuses remote copy of own character")
          -- CleanBrokenCharKeys merges 1-word (class-disambiguated even with Jhf Priest!) + realm alias + purges remote.
          f.onEvent(f, "PLAYER_LOGIN")
          assert(ComradeCraftDB.chars["Jhf-Realm"] == nil, "dedup: merged 1-word Jhf (MAGE) into Jhf Mage despite Jhf Priest")
          assert(ComradeCraftDB.chars["Jhf Mage-RealmAlias"] == nil, "dedup: merged Forever realm-alias duplicate")
          assert(ComradeCraftDB.chars["Jhf Mage-Realm"].level == 34 and ComradeCraftDB.chars["Jhf Mage-Realm"].listed == true,
            "dedup: kept newer level 34 record and preserved flags")
          assert(ComradeCraftDB.chars["Jhf Priest-Realm"] ~= nil, "dedup: untouched distinct alt Jhf Priest")
          assert(ComradeCraftDB.remote["Jhf Mage-OtherSpelling"] == nil and ComradeCraftDB.remote["Jhf-Realm"] == nil,
            "dedup: purged stale remote copies of own character")
          local allNow, mageCount = ns.AllChars(), 0
          for k, rec in pairs(allNow) do
            if rec.class == "MAGE" and k:find("Jhf", 1, true) then mageCount = mageCount + 1 end
          end
          assert(mageCount == 1, "AllChars: active character appears strictly once")
          -- Cleanup test fixtures.
          ComradeCraftDB.chars["Jhf Mage-Realm"], ComradeCraftDB.chars["Jhf Priest-Realm"] = nil, nil
          ComradeCraftDB.peers["p-dup"] = nil
          RegionalUniqueNamesEnabled, UnitNameUnmodified, UnitClass, UnitLevel = savedRU, savedUNU, savedUC, savedUL

          -- 20h. ForeverDB.ObserveLoot tolerates secret string GUIDs (Midnight/Forever combat/instance API).
          local savedISV, savedGLSI, savedGNLI, savedGLSL = issecretvalue, GetLootSourceInfo, GetNumLootItems, GetLootSlotLink
          local secretVal = "Creature-0-0-0-0-1234-SECRET"
          issecretvalue = function(v) return v == secretVal end
          GetLootSourceInfo = function() return secretVal end
          GetNumLootItems = function() return 1 end
          GetLootSlotLink = function() return "|Hitem:2589|h[Linen]|h" end
          local okLoot, errLoot = pcall(ns.ForeverDB.ObserveLoot)
          assert(okLoot, "foreverdb: ObserveLoot must not error on secret GUID: " .. tostring(errLoot))
          issecretvalue, GetLootSourceInfo, GetNumLootItems, GetLootSlotLink = savedISV, savedGLSI, savedGNLI, savedGLSL

          -- 20i. Wishlist ready alert shows Right-click conversion hint (3x Lesser -> 1x Greater) and deduplicates.
          local savedNotify = ns.Alerts.Notify
          local alertsCaptured = {}
          ns.Alerts.Notify = function(t) alertsCaptured[#alertsCaptured + 1] = t end
          ns.Recipes[999601] = { 333, 150, 175, 1, 0, 1, { 11082, 1 } } -- requires 1x Greater Astral Essence
          local savedBags3, savedWl3 = me.bags, ComradeCraftDB.wishlist
          me.bags = { [10998] = 3 } -- 3x Lesser Astral Essence, 0 Greater
          ComradeCraftDB.wishlist = {
            { id = "conv-1", char = ns.CharKey(), spell = 999601, item = 0, qty = 1, forWho = "Jhf Mage", pinned = true },
            { id = "conv-2", char = ns.CharKey(), spell = 999601, item = 0, qty = 1, forWho = "Jhf Mage", pinned = true },
          }
          ns.Wishlist.CheckReady()
          assert(#alertsCaptured == 1, "wishlist alert: deduplicates identical spell+forWho toasts")
          assert(alertsCaptured[1].text:find("Right-click: 3x", 1, true) and alertsCaptured[1].text:find("1x", 1, true),
            "wishlist alert: includes 3x Lesser -> 1x Greater conversion hint: " .. tostring(alertsCaptured[1].text))
          ns.Alerts.Notify = savedNotify
          ns.Recipes[999601], me.bags, ComradeCraftDB.wishlist = nil, savedBags3, savedWl3

          -- 20j. ZoneRadar detects Expert/Artisan rank trainers in the current map ([cap][line] tuple shape).
          local savedUFG = UnitFactionGroup
          UnitFactionGroup = function() return "Alliance" end
          local savedProfsZR = me.professions
          me.professions = { Tailoring = { rank = 125, max = 150, skillLine = 197 } }
          local zHits = ns.ZoneRadar.Scan(1453) -- Stormwind (Georgio Bolero, Expert Tailoring)
          local foundTrainer = false
          for _, h in ipairs(zHits) do
            if h.npc == 1346 and h.x == 43.2 and h.y == 73.6 then foundTrainer = true end
          end
          assert(foundTrainer, "zoneradar: finds Expert Tailoring trainer Georgio Bolero in Stormwind")
          me.professions = savedProfsZR
          UnitFactionGroup = savedUFG
        end

        -- Spec switcher command & UI render.
        SlashCmdList.COMRADECRAFT("spec fire")
        assert(GS.GetSpec(me) == "fire", "spec cmd: switched to fire")
        GS.CycleSpec(ns.CharKey())
        assert(GS.GetSpec(me) == "frost", "spec cycle: fire -> frost")
        ComradeCraftDB.ui.sel, ComradeCraftDB.ui.groupTab = "group", "upgrades"
        ns.RefreshWindow()
        -- Restore state.
        ns.Recipes[999101], ns.Recipes[999110] = nil, nil
        me.class, me.level, me.spec, me.specOverride = savedState.c, savedState.l, savedState.s, savedState.so
        me.equipped, me.equippedLinks, me.enchants, me.known = savedState.eq, savedState.eql, savedState.en, savedState.kn
        me.bags = savedState.b
        me.professions = savedState.p
        ComradeCraftDB.directory = savedDir
        f.onEvent(f, "PLAYER_GUILD_UPDATE")
        GetItemInfo, GetItemStats = savedGet, savedStats
      end)()

      -- Log: commands and their output are kept, colors stripped; errors logged then re-raised.
      local log = ComradeCraftDB.log
      local joined = table.concat(log, " / ")
      assert(joined:find("> /comrade stats", 1, true), "log: command line")
      assert(joined:find("crafts recorded", 1, true), "log: output line")
      assert(not joined:find("|c", 1, true), "log: color codes stripped")
      ns.commands.boom = function() error("kaboom") end
      local ok = pcall(SlashCmdList.COMRADECRAFT, "boom")
      assert(not ok, "log: error must be re-raised")
      assert(log[#log]:find("ERROR", 1, true) and log[#log]:find("kaboom", 1, true), "log: error line")

      local n = 0 for _ in pairs(ns.Recipes) do n = n + 1 end
      return n
    end""")
    try:
        n = run(ns)
    except lupa.LuaError as e:
        print(f"RUN {e}")
        return 1
    print(f"OK: {len(files)} files, {n} recipes, smoke test passed")
    for m in lua.globals().__log.values():
        print("  chat:", re.sub(r"\|c\w{8}|\|r", "", m))
    return 0


if __name__ == "__main__":
    sys.exit(main())
