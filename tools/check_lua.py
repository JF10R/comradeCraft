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
                 "Enchant", "Consumable", "Bag", "Weapon", "Armor", "Reagent", "Other"])
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
      TSM_API, ns.PriceSource, ns.PriceSourceName = nil, nil, nil
      ns.UpdateNeeds(c)

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
