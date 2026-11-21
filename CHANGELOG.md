# ComradeCraft

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
