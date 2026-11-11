# Stat weights + disenchant research (2026-11-11)
Caveat: all fetches went through a summarizing fetch tool (WebFetch), so "quotes" below are tool-relayed, not eyeballed raw. Nothing was executed.

## Q1 Stat weights
VERIFIED (read via fetch of raw GitHub files):
1. Pawn license = CC BY-NC-ND 3.0. Src: https://github.com/VgerMods/Pawn Readme + every .lua header: "This mod is released under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 license", (c) Travis Spomer. Consequence: do NOT copy Pawn's scale numbers into an MIT addon (NC + ND). Falsifier: separate permissive license on ClassicHawsJon.lua (none seen; header says same CC).
2. Pawn ships Classic starter scales: ClassicHawsJon.lua, provider "Classic". Credit: "HawsJon curated the Classic Era, Burning Crusade Classic, Wrath Classic, and Forever scales". Registered via PawnAddPluginScaleFromTemplate(ProviderName, classID, specID, {weights}). Classic Era has per-class-spec scales (Warrior Arms/Fury/Prot, Druid Feral Dmg/Tank, etc.). Sample: Warrior Arms Strength=1, Agility=0.69, MeleeDps=5.31, Ap=0.45, Stamina=0.1. File only 100k/124k chars read.
3. Pawn has explicit WoW Forever support: Readme "Pawn now fully supports World of Warcraft Forever" (v2.14.0); v2.14.1 "new default stat weights for all classes and specs, curated by HawsJon". Forever itemization changed (spell hit/crit/haste removed from Weights tab; expertise etc.) so Vanilla tables are partly wrong for Forever. Also: Method/Icy Veins report Forever reworks itemization (not opened).
4. Pawn Lua API (from Pawn.lua, raw master; 2 of 3 chunks read):
   - `PawnGetItemValue(Item, ItemLevel, SocketBonus, ScaleName, DebugMessages, NoNormalization, NoReforging)` -> Value, TotalSocketValue, SocketBonusValue. "Calculates the value of an item." Takes a ScaleName: works for NAMED scales, not just current char.
   - `PawnGetSingleValueFromItem(Item, ScaleName)` -> "single scale value (enchanted and unenchanted) for a cached item"; computes on demand if scale not visible. Item = from PawnGetItemData(ItemLink).
   - `PawnIsItemAnUpgrade(Item, DoNotRescan)` -> UpgradeInfo, ItemLevelIncrease, BestItemFor, SecondBestItemFor, NeedsEnhancements. Current user's enabled scales only; NOT per-named-scale.
   - I did not find an "official public API" doc; these are file-global functions. Parameter details of PawnGetItemData unverified (definition in unread chunk).
   - Scale names can be enumerated via PawnCommon.Scales (not verified; check). Starter scale internal names/provider prefix unverified.
5. Template classes in ScaleTemplates.lua: Classic keyed by class only (primary stats list); weights live in ClassicHawsJon.lua.

RELAYED / NOT FOUND:
- Wowhead stat-weight reuse forbidden: well-known ToS; I did not open the ToS.
- No explicit-license open Classic stat-weight table found (did not search GitHub deeply: WoWSims `wowsims/classic` is MIT-licensed per my memory, UNVERIFIED; its ep/weights are per-spec sim output, check LICENSE + data).

RECOMMENDATION: (a) optional Pawn bridge: if `PawnGetItemValue` and `PawnGetItemData` exist, call with the group member's class scale name (Pawn scales shown in PawnCommon.Scales; names vary, so let user map class/spec -> scale). Runtime calls to another addon are not copying; fine for MIT. Guard with pcall + nil checks; Pawn needs item cached. (b) Fallback: our OWN tiny table, authored by us (rough per-class primary-stat priorities, e.g. Warrior Str>Agi>Sta), cite WoWSims (if license verified MIT) or write from first principles. Do not transcribe Pawn/HawsJon values. Forever changes stats, so keep it coarse.

## Q2 Disenchanting
VERIFIED via fetch of https://warcraft.wiki.gg/wiki/Disenchanting_tables (page itself says it's pre-BfA, bands to ilvl 352; the fetch tool summarized it):
Uncommon ARMOR: ~75% dust, ~20% essence, 3-10% shard (shard small bands only at 5-10%). WEAPON: ~20% dust, ~75% essence, shard 3-10%.
Rare: 100% shard (~0.5% Nexus Crystal at ilvl 56-65). Epic: 100% shard (ilvl 40-55, 2-4x) or Nexus Crystal (ilvl 56-60, 1x; 61-88 1-2x).
Uncommon by ilvl (Armor dust qty / essence qty 1-2 / shard):
 5-15 Strange 1-2 / Lesser Magic | 16-20 Strange 2-3 / Greater Magic / Sm Glimmering 5% | 21-25 Strange 4-6 / Lesser Astral / Sm Glim 10%
 26-30 Soul 1-2 / Gr Astral / Lg Glim 5% | 31-35 Soul 2-5 / Lesser Mystic / Sm Glowing | 36-40 Vision 1-2 / Gr Mystic / Lg Glowing
 41-45 Vision 2-5 / Lesser Nether / Sm Radiant | 46-50 Dream 1-2 / Gr Nether / Lg Radiant | 51-55 Dream 2-5 / Lesser Eternal / Sm Brilliant
 56-60 Illusion 1-2 / Gr Eternal / Lg Brilliant 5% | 61-65 Illusion 2-5 / Gr Eternal 2-3 / Lg Brilliant
Rare shard by ilvl: 1-25 Sm Glim, 26-30 Lg Glim, 31-35 Sm Glowing, 36-40 Lg Glowing, 41-45 Sm Radiant, 46-50 Lg Radiant, 51-55 Sm Brilliant, 56-65 Lg Brilliant.
Quantities split evenly across the range unless noted (wiki convention). Raw per-weapon/band exceptions are in the wiki; use it as the data source for item-level tables.

VERIFIED (https://www.wow-professions.com/forever/disenchanting-guide, WoW Forever page): table is keyed by REQUIRED LEVEL, not item level: 1-10 Strange 1-2 / Lesser Magic; 11-15 Strange 2-3 / Gr Magic; 16-20 Strange 4-6 / Lesser Astral; 21-25 Soul 1-2; 26-30 Soul 2-5; 31-35 Vision 1-2; 36-40 Vision 2-5; 41-45 Dream 1-2; 46-50 Dream 2-5; 51-55 Illusion 1-2 (+Lg Brilliant & Nexus); 56-60 Illusion 2-5 (+Nexus), Gr Eternal 1-3. Same quality rules (75/20 armor, 20/75 weapon, rare 100% shard, ~0.5% crystal). Likely equals Classic Era in structure but keyed by req-level; this page does not compare to Classic Era.
WoW Forever changes: no source found stating DE was changed in 1.60/16001 (searched once; Forever reworks itemization generally). Use req-level keyed table for Forever, ilvl for Era; test in-game.

TSM: NOT SETTLED. TSM_API reference is at https://api.tradeskillmaster.com/addon/ (fetch failed: expired cert). Support article lists API categories only: UI, Group, Profile, Price, Money, Item, Inventory (no mention of destroy mats). Destroy is documented as a price source (avg value of mats via DBMarket), not a mats/probability API. Conclusion: no evidence of a mats/probability API; embed table. Check the reference page in a browser to be sure.

## Verdict
Q1: Pawn = optional runtime bridge via PawnGetItemValue(named scale); don't copy its CC NC-ND values; ship a coarse own table. Q2: embed wiki table (facts, not copyrightable expression, still attribute) keyed by ilvl (Era) and req level (Forever); TSM gives no mats API as far as found.
Not covered: Pawn.lua first/last chunks, WoWSims license, Wowhead ToS, TSM reference page, in-game DE test.
