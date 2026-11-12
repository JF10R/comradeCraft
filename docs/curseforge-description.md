**Level your professions together.** ComradeCraft is a WoW Forever addon for groups of friends leveling professions. It answers one question: *what should I do with what I have, for the group?*

## Features

- **Item tooltip**: who in your group needs this material, how many, and how soon.
- **Group window** (`/comrade`): each character's leveling route (recipes to learn, intermediates to craft, skill-up chances, costs), what they can craft, the most wanted materials, what you can give to whom, and what to disenchant or keep.
- **Two route types**: *Cheapest* (least spent on materials) or *Profitable* (products sold back to a merchant, disenchanted or auctioned, with the auction cut and deposit counted). Cost and net cost per 75-point milestone.
- **Step panel** next to the profession window: the current step, its skill-up chance, how many crafts your bags allow, and a craft queue.
- **Shopping list**: export the missing materials to Auctionator, or copy a search text and a group import for TradeSkillMaster.
- **Where to learn a recipe**: trainers, vendors and drops, with a TomTom waypoint to the nearest one.
- **Next rank**: at the skill cap, the Expert book, the Artisan quest (with Questie) or the trainer.
- **Craft requests**: ask a group member to craft a recipe for you; it is delivered the next time you are both online.
- **Mail helper**: attaches what a group member needs. It never sends the mail for you.
- **Alerts** (each can be turned off): materials ready, profession cooldowns ready on any of your characters, craft requests, and (opt-in) upgrades a group member can craft for you.

English and French (follows the game's language). A help page (**?** button) and a short tour open the first time.

## Getting started

1. Type `/comrade` to open the window.
2. In **Manage group > Your characters**, check the characters you want to share.
3. Add your friends (`/comrade add Name`). Both of you must add each other.

## Recommended addons

All optional; ComradeCraft detects them.

- **TradeSkillMaster** or **Auctionator**: auction prices, disenchant values, shopping lists. Without them, merchant prices are used.
- **Questie**: positions of trainers, vendors and quest givers.
- **TomTom**: waypoints.
- **Pawn**: upgrade detection with each member's stat scale. Without it, item level is compared.

## Commands

| Command | Effect |
|---|---|
| `/comrade` | Open the group window |
| `/comrade shop [profession]` | List the materials to buy and export them |
| `/comrade tracker [reset]` | Show or hide the step panel |
| `/comrade mail Name` | At a mailbox: attach what Name needs |
| `/comrade share [off]` | Share this character with your group |
| `/comrade add Name` / `remove Name` | Add or remove a player |
| `/comrade guildping [off]` | Tell your guild you use ComradeCraft |

Every command also exists in the window.

## Privacy

No character data is sent until you share a character. Data then goes by addon whisper, only to the players you added and who added you back. At login, a presence signal (no character data) goes to your guild's addon channel so guildmates with ComradeCraft can be suggested; `/comrade guildping off` turns it off.

## Early version

Some parts have not been tested with two real players yet (craft requests, sync between friends). Bug reports and ideas are welcome.
