# ComradeCraft

## v0.5.0

### Highlights
- **Target Skill & True Cost of Leveling**: Type the skill you want to reach in the `Plan` tab (or scroll the mouse wheel: +/-5, Shift: +/-25). The plan stops there and shows the full bill: **gross**, **to buy** (missing mats from the AH and merchants), **resale**, **trainer & recipes**, and the **net** cost or profit. Every step now shows its own `cost · resale · net` line, in green for profit and red for loss. You can also set a target on a friend's or an alt's plan; that target stays on your side only.
- **Leveling Budget**: Enter the gold you want to spend in **Budget (g)**. The plan reinvests the sales of your earlier crafts, tells you how far your budget gets you (`With your budget you can reach 215`), greys out the steps you can't afford yet, and shows the most gold you'll need at any one moment.
- **Smarter, Cheaper Leveling Routes**:
  - Routes now include **recipes sold by merchants** (with faction and location) and **world-drop patterns listed at the Auction House**, and only pick a bought recipe when it actually pays for itself. A recipe bought for just a few points is dropped if leveling without it is cheaper.
  - When a quest gives a cheaper recipe, the plan tells you (`Alternative: X from the quest Y would save about 3g`).
  - Recipes that need a higher character level, a reputation you don't have, or materials you can't get on WoW Forever are no longer suggested.
  - Recipes with a cooldown (Transmutes, Mooncloth…) stay out of leveling routes, and their real WoW Forever cooldowns are now used everywhere.
- **Realistic Resale**: For each step, the plan suggests what to do with your crafts: `12 at the AH`, `disenchant 8 with Enchanting`, `5 to a merchant`. It accounts for how many actually sell per day (when your price addon provides that data), the AH cut, and the real deposit (5% of the merchant price per 2h; the neutral AH deposit is handled too).
- **Tools & Crafting Stations**: Steps now tell you which tool you need (`Get a Blacksmith Hammer`, `Sold by trade supplies vendors`) and where to craft (`Craft at: Anvil`, `Nearest: …`), with a 1-click TomTom waypoint to the nearest Anvil, Forge, Cooking Fire, Alchemy Lab, Black Anvil and more. New station locations are saved the first time someone in your group crafts there.
- **New `Goldmaking` View** (in the `Plan` tab):
  - **Repeat goldmakers**: The crafts you know that earn the most at the AH, at the pace the AH actually buys them, after the cut and deposit. Sub-components are bought or crafted, whichever is cheaper (`craft the Bronze Bar yourself`). **Queue** sends a batch to your profession's craft queue in 1 click, and **Restock** tops up what's missing.
  - **No risk: sell to a merchant**: Crafts that turn a profit straight at a vendor.
  - **Cooldown goldmakers**: Your best daily cooldowns, with `ready in 3h` timers.
  - **Recipes worth buying**: Unlearned recipes that pay for themselves (`recipe 4g, paid back in 6 crafts`), with waypoints. **What if I learned** shows how a recipe would change your list before you buy it.
- **Auction House Helpers**:
  - Without TSM or Auctionator, the new **Price mats** button searches the next unpriced material from your plan in 1 click (`Price mats (3/12)`), and your plans update as prices come in.
  - Shopping lists for Auctionator are ready in 1 click.
- **Bank: Deposit Later Mats**: 1 click stores the materials you only need for later steps (`Needed at skill 175`). Mats for your current step, your Wishlist, friends' requests and reserved items stay in your bags.

### Quality of Life & Bug Fixes
- **More Accurate WoW Forever Data**: Recipes now include the latest WoW Forever server hotfixes. 4 recipes that listed outdated reagents are fixed. Merchant prices and NPC locations come from what you and your friends actually see in game.
- **Faster Tooltips After Login**: Item details (bound or not, stackable, bag size, disenchant results) are now built into the addon, so plans and tooltips are right even before the game has loaded the item.
- **Friends' New Alts Need Your OK**: When a friend says a new character is theirs, you get a message to **Accept** or **Refuse** it in `Manage group`. A new **Forget** button removes a player you no longer play with.
- **Character Renames & Surnames**: Your data, requests and reservations now follow a renamed character, and nothing is lost when a friend's character gets its WoW Forever surname. New alts are saved correctly even when WoW Forever doesn't give a realm.
- **Fixed Tooltip Flickering at the Auction House**: Shift-comparing an item, or hovering the ComradeCraft AH panel, no longer makes the tooltip flash.
- **Fixed Repeated Tooltip Lines**: The ComradeCraft block no longer disappears or doubles when you move between two stacks of the same item.
- **Fixed Merchant Error**: Opening certain WoW Forever vendors (e.g. *Gearcutter Cogspinner*) no longer throws a Lua error.
- **Bags, Bank & Mail**: The bank is rescanned while open, Cash-on-Delivery mail is no longer counted as yours, special profession bags are no longer counted as free space, and the mail queue no longer skips items.
- **Sharper Planning**: Unknown prices no longer turn a loss into a profit (a `<` means "at most"). Materials you already own are used first, and trainer choices are correct when two trainers share a name.
- **Safer Sharing**: The shared WoW Forever database now only shares what you saw yourself, rejects bad values, and calculates drop rates and disenchant results more accurately.

## v0.4.0

### Highlights
- **1-Hour Mail In-Transit Tracking & 1-Click Mailbox Tour**: When you mail materials to a friend on another account, ComradeCraft now tracks the 1-hour mail delivery window across your group — showing an **In transit** banner in `Group -> Overview`, live countdowns in tooltips and `Group plan`, and subtracting mailed items right away so nobody double-farms or sends duplicates. A new **Next recipient** button in the Mailbox panel lets you step through every friend you have items for in 1 click per mail.
- **Unified Profession Craft Queue (`Plan` | `Orders`)**: Your docked profession step panel now has an **Orders** view showing accepted group craft requests and pinned Wishlist crafts for that profession, automatically queuing missing intermediates first and letting you click **Craft next** (with a clear `in bank` hint if mats are stored in your bank).
- **Reusable Craft Kits & Auto-Completing Wishlist**: Save your current Wishlist as a reusable kit (e.g., *Raid Kit*, *Dungeon Kit*, *Reroll Kit*) and apply it **x1** or **x5** in 1 click from the Wishlist tab. Crafting a wishlisted item now automatically counts down and completes it for you.
- **Smarter Multi-Profession Craft Chains & Trade Enchants**: Craft chains now link steps together (`Step 1/3`, `Waiting previous step`), prioritize crafters whose cooldown is ready, route intermediates directly to the next crafter in the chain (`Deliver to X`), and track partial shipments accurately (`Sent 4/10`). When trading a friend who requested an **Enchant**, the Trade panel lets you open the enchant in 1 click and automatically marks the request done once traded.
- **Unified Group Search**: The search bar in `Group` now searches **everything at once** — items in bags/bank/mail/Shared Bank Alts/in-transit (with 1-click **Request**), who can craft it in your group (1-click **Request** or **Pin**), and matches from the **Guild directory** (1-click **Whisper**).
- **Zone Radar, AH Bargain Radar & Shared WoW Forever Knowledge**:
  - **Zone Radar**: See local Expert/Artisan trainers, recipe vendors, rare drops, and farmable mats useful to your group right in your current zone, with 1-click TomTom waypoints.
  - **AH Bargain Radar**: Automatically spots group-needed materials and BoE patterns listed at 20%+ below market while browsing the Auction House, with improved Blizzard & Auctionator search support.
  - **Shared WoW Forever P2P Database**: Automatically shares newly discovered custom WoW Forever recipes, real orange/yellow/green/grey skill thresholds, measured disenchant yields, vendor locations, and mob drop rates with your friends and guild (with a live status counter in `Manage group`).
- **Faster Sync & Complete Shared Bank Alts**: Bag, bank, mail, reservation, and in-transit updates now sync as lightweight updates every **15 seconds** instead of resending full recipe lists, and **Shared Bank Alts** now share all tradable items (including custom Forever items, recipes, bags, and consumables).

### Quality of Life & Bug Fixes
- **No More Duplicate Character Entries**: Fixed an issue where your active character could appear twice (for example, an older 1-level-behind copy on WoW Forever two-part names or when multiple alts share the same first name). Existing duplicates are cleaned up automatically on login.
- **No More `item:XXXX` Placeholders**: Uncached reagent and item names now load automatically and refresh open windows/panels within a fraction of a second, with a per-language name cache so they appear instantly on future logins.
- **Clearer Enchanting Essence Alerts**: Wishlist and profession "ready" notifications now clearly tell you when you need to right-click convert essences first (e.g. `Right-click: 3x Lesser Astral Essence -> 1x Greater Astral Essence`), and duplicate Wishlist notifications no longer spam chat.
- **Fixed Dungeon/Combat Loot Error**: Guarded loot and NPC checks against WoW Forever's protected combat/instance values so looting in dungeons never throws Lua errors.
- **More Accurate Bags, Bank & Multi-Profession Planning**:
  - **Reagent Bags** are now included when attaching items in Mail and Trade.
  - The **Bank panel** now withdraws missing crafting reagents for accepted incoming craft requests (not just finished items).
  - Items being crafted (`crafting` status) keep their bag highlights and tooltips until shipped.
  - Characters with two professions sharing the same material (e.g., Tailoring + First Aid cloth) no longer double-count the same stack.
  - Group Cooldowns now show who claimed a cooldown (`Reserved by X`) and offer a 1-click **Craft** button on your own ready cooldowns.
  - `Patterns` tab now lets you group by **Character** or **Slot** and shows world-drop zone hints.

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
