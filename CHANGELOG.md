# ComradeCraft

## v0.3.0

### Highlights
- **Built-In Craftable BiS Engine & `Patterns` Tab (All 9 Classes, 29 Specs)**: Auto-detects your spec and shows the best craftable gear, enchants, wands, consumables, and upcoming `+1-4 lvl` upgrades across yourself, your alts, your friends, and your guild. A new **`Patterns`** tab on every character sheet lists valuable unlearned gear, enchant formulas, bags, and consumables to buy or farm (with drop rates for 358 Classic recipes, BoE AH prices, and 1-click TomTom waypoints).
- **Shared Bank Alts & Item Requests**: Flag any alt as a **Shared bank alt** so its entire stock (bags, bank, mail) shows as available to your group, and friends can request items directly through the addon.
- **Reserve Items for Friends (`Alt+Right-Click`)**: Lock any item in your bags for a specific friend. Shows a violet lock badge, warns before vendoring/AHing, queues automatically in Bank/Mail/Trade, and shows up in their **Reserved for you** banner before you even send it.
- **Sync Across Timezones (100% In-Game)**: Friends automatically relay updates for offline group members (Mesh Sync) and guild alt-switches sync right away, with zero external apps or servers.
- **Smart Craft Requests**: Glowing sidebar indicator for incoming requests, live material/stock progress visible to both players (`Missing X`, `Ready to craft`, `Ready to ship`), and automatic tracking (`Crafting` when you cast it, `Shipped` when you mail or trade it).
- **Bank, Merchant & Trainer Companion Panels**: 1-click **Withdraw needed** beside your Bank, native vendor slot highlights + 1-click buying (even for Page 3 books like *Expert Cookbook* for a friend), and a Trainer panel highlighting leveling-plan and group-BiS recipes ready to learn.
- **All 12 Expert & Artisan Trainers (Alliance & Horde)**: Built-in trainer, book (Cooking, First Aid, Fishing), and quest guide with Questie locations and 1-click TomTom waypoints (with built-in fallback coordinates for all 34 NPCs).

### Quality of Life & UI Polish
- **Automatic Enchanting Essence Conversions**: Seamlessly handles `3x Lesser <-> 1x Greater` essences across plans, bags, mail, trade, and tooltips, with right-click conversion hints.
- **Native Bag Sorter Categories**: Adds a built-in `ComradeCraft` category for **Baganator** and **BetterBags** so group and reserved items stay grouped together.
- **Built for Large Guilds (100+ Characters)**: Star favorite players/crafters, collapse Sidebar sections (`Favorites`, `My characters`, `Group members`), quick-filter large rosters, and see a live **Farming for you** banner.
- **Cleaner Tables & Visual Polish**: Alternating row shading and green self-craft highlights in `Upgrades` (with 1-click `Request`), item rarity borders on icons, clickable Bank Alt stock cards in `Materials`, 1-click **BoE pattern AH search**, 1-click `/g` or `/p` chat sharing, subtle sound alerts, and consistent `X` close buttons on all side panels.
- **Native Blizzard Options & System Integration**: New `Esc -> Options -> AddOns -> ComradeCraft` settings page (UI scale `75%-125%`, per-panel toggles, minimap/sound toggles, 1-click reset positions), resizable window height, native Keybinding support, Addon Compartment, and TitanPanel/Bazooka/ElvUI DataText badges.

### Key Bug Fixes
- Fixed tooltips and bags sometimes suggesting to mail materials to yourself on WoW Forever two-part names (`First Last`).
- Fixed the Mail helper panel staying open after closing **Postbox**.
- Fixed Expert book vendor faction matching for Horde First Aid (`Balai Lok'Wein`) and Alliance Cooking (`Shandrina`).
- Fixed 2H weapon and Shield enchant recommendations matching the wrong weapon slots.
- Fixed **Bagnon** cached-alt bag windows showing highlights for your active character.

### Details & Technical Notes
- **Performance**: Instant window opens using C-API `C_Item.GetItemStats` before Pawn tooltip scraping, 60-100x faster Bagnon/BagBrother slot highlights via per-frame caching, diffed event scans, debounced search, and combat-deferred refreshes (`PLAYER_REGEN_ENABLED`).
- **WoW Forever 1.60.1**: Full `"First Last"` name safety across mail/trade/sync, automatic migration of legacy 1-word alt keys via Guild Roster and Friends List, and active live calibration of Forever recipe difficulty bounds.
- **Addons & Compatibility**: Tested with Postbox, Postal, TSM Mailing, TradeSkillMaster, Auctionator, Bagnon, BagBrother, Combuctor, Baganator, BetterBags, ElvUI, EllesmereUI, ArkInventory, Questie, TomTom, and Pawn. Mail and Trade panels clearly separate bag-ready items from bank-only items (`in bank`).
- **Architecture**: Split monolithic `UI.lua` into `UI/{Widgets,Plan,Group,Social,Window}.lua` and `Needs.lua` into `Pricing.lua`, `Needs.lua`, and `GroupNeeds.lua`, plus new `Bank.lua`, `Reserve.lua`, `Options.lua`, and `Bindings.xml` (67 Lua files, 7 languages, 19 automated test suites).

## v0.2.0

- Guild directory (opt-in, per character): list a character in Manage group or with
  `/comrade list`; guildmates with the addon search who can craft an item
  (`/comrade directory`), whisper them, and see up to 3 guild crafters in item tooltips.
- Group plan: plans count stock already in the group as free (or market value, in Options),
  a view of what the group still needs and its cost, and opt-in farming assignments with a tracker.
- Keep for the group: at a merchant or the AH, the bag items your group needs; Buy back
  after selling one.
- Auction values count the 5% cut and the deposit risk (refunded on sale on Forever).
- Shared craft wishlist: pin any recipe for yourself or a friend, track materials in a movable
  on-screen tracker, get an alert when ready to craft, and sync pinned items with your group.
- Bag highlights: badges and glows on items your group needs in Blizzard bags, Baganator,
  Bagnon, Combuctor and ElvUI, dynamically focused on the active mailbox or trade recipient.
- Side panels at the Mailbox, Trade window, Merchant (1-click reagent auto-buy), and Auction
  House (1-click search for missing materials with gold balance summary).
- Cross-profession synergies (Craft -> Disenchant and Raw -> Intermediate), Group Upgrades
  audit (small bags, missing enchants, craftable upgrades), and gold-aware Buy vs Farm advice
  with QuestieDB farm spots and TomTom waypoints.
- Recipe-item tooltips and group loot roll hints showing who still needs a recipe or urgent mat.
- UI rework with authentic dark-stone Blizzard styling, organized Group sub-tabs
  (Overview, Materials, Upgrades, Disenchant), Share all / auto-share new characters, and
  right-click player menu integration to add friends to your group.
- Route accuracy and bug fixes: automatic recalculation on learning new recipes (world drops,
  vendors, Forever custom recipes), trainer refusal detection with right-click skip on Learn
  steps, strict BoP/soulbound handling in Disenchant/Keep advice, and duplicate character
  cleanup on multi-word realms.

## v0.1.0

First version for WoW Forever (Interface 16001):

- Group needs window: per character plan (what to craft, what to learn at the trainer, costs
  with TSM or Auctionator), "can craft" list, group overview, profession filters.
- Item tooltip: who in the group needs this material, and how soon.
- Opt-in sharing with friends and guildmates you add (addon messages, no server).
- Step panel next to the profession window: current step, skill-up chance, crafts your bags
  allow, next step (`/comrade tracker`).
- Shopping list: export a plan's missing mats to Auctionator, or copy a TSM search text and
  group import (`/comrade shop`); finished or replaced TSM groups are reported.
- Disenchant advice uses the TSM or Auctionator disenchant value when available.
- Mail helper, disenchant-or-keep advice, gear upgrades (Pawn when installed).
- Route types: Cheapest (default) or Profitable (products sold back), with the cost of both
  per 75-point milestone.
- Help page (? button) and a short first-open tour.
- Where to get a recipe: hover a "Learn" step for its trainers, vendors and drops (with
  Questie positions); click it for a TomTom waypoint to the nearest one.
- Craft queue in the step panel: this step or up to the milestone, what your bags allow now,
  and a Craft next button (one batch per click, as the game requires).
- Collapse professions in Plan and Can craft; Can craft in columns; plan steps and a
  milestone table with net cost (mats minus the best resale).
- Craft requests between group members, kept until the other player's addon confirms it
  received them (both online once is enough).
- Alerts (Manage group > Options): mats ready, cooldowns ready on any character, craft
  requests, and opt-in upgrades a group member can craft (with Pawn score or stats).
- Next rank at the skill cap: Expert book (vendor or AH), Artisan quest from Questie with a
  TomTom waypoint to its giver, or the trainer.
- German, Spanish, Italian, Brazilian Portuguese and Russian translations.
- Addon logo as the minimap button, window portrait and addon list icon.
- Trainers you visit are remembered and come first in waypoints; distances work across
  zones (HereBeDragons, shipped with TomTom).
