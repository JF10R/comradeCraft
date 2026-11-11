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
                   for n in files if not n.startswith("Libs/") and n != "Locale.lua")
    # ns.L["..."] and a file-local alias L["..."]; Plural keys; plus keys built at runtime.
    used = set(re.findall(r'(?<![\w.])(?:ns\.)?L\["((?:[^"\\]|\\.)*)"\]', code))
    for a, b in re.findall(r'ns\.Plural\([^,]+,\s*"([^"]*)",\s*"([^"]*)"\)', code):
        used.update((a, b))
    used.update(["orange", "yellow", "green", "grey", "trainer", "vendor", "quest", "drop", "container",
                 "Enchant", "Consumable", "Bag", "Weapon", "Armor", "Reagent", "Other", "now", "soon", "later",
                 "pending", "accepted", "declined", "done", "cancelled"])
    # A lone backslash before a letter ("Interface\DialogFrame" typed with one) is not a
    # path separator in Lua: the texture silently fails to load.
    for n in files:
        if n.startswith("Libs/"):
            continue
        for i, line in enumerate(open(os.path.join(ADDON, n), encoding="utf-8"), 1):
            if re.search(r'(?<!\\)\\(?![\\nrt"\'0-9])[A-Za-z]', line):
                print(f"BACKSLASH {n}:{i}: {line.strip()[:80]}")
                return 1
    loc = open(os.path.join(ADDON, "Locale.lua"), encoding="utf-8").read()
    fr = set(re.findall(r'^\s*\["((?:[^"\\]|\\.)*)"\]\s*=', loc, re.M))
    missing, stale = sorted(used - fr), sorted(fr - used)
    for k in missing:
        print(f"LOCALE missing frFR: {k}")
    for k in stale:
        print(f"LOCALE unused frFR key: {k}")
    if missing or stale:
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
      f.onEvent(f, "TRAINER_SHOW")
      local tv = ComradeCraftDB.trainer[2385]
      assert(tv and tv.cost == 50 and tv.req == 12, "trainer: vest recorded")
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
      local mt = ns.MilestoneRows(c.needs[197])
      local r1 = mt and mt.rows[1]
      assert(r1 and r1.from == 1 and r1.to == 75 and #r1.routes == 2 and r1.routes[1].mode == "cheap"
        and r1.routes[2].active and r1.routes[2].m and r1.routes[2].net == r1.routes[2].m.mats - r1.routes[2].m.best,
        "routes: milestone rows")
      local ro = ns.ResaleOptions(2996)
      assert(ro.vendor >= 0 and ro.ah == nil and ro.de == nil, "resale: no AH, cloth not disenchantable")
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
      From({ t = "H", v = 1, id = "peerVez", c = {} }, "Vez")
      assert(not ComradeCraftDB.remote["Vez-Realm"], "sync: a character they stop sharing disappears")
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
        ["Vez-Realm"] = { needs = { [197] = { name = "T", items = { [2589] = 15 }, when = { [2589] = 1 } } } },
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
      assert(ns.Mail.KeyForName("vez") == "Vez-Realm", "mail: name match")
      ns.Mail.Prepare("Vez-Realm")
      assert(ops[1] == "pick1" and ops[2] == "split2:5", "mail: whole stack then split, got " .. table.concat(ops, ","))
      assert(attached[1][2] == 10 and attached[2][2] == 5 and cursor == nil, "mail: 10 + 5 attached, cursor clear")
      assert(SendMailNameEditBox.text == "Vez" and SendMailSubjectEditBox.text == "ComradeCraft", "mail: form filled")
      f.onEvent(f, "MAIL_CLOSED")
      ns.Mail.Prepare("Vez-Realm") -- closed: only a message
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
