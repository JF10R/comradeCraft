# ComradeCraft

A WoW Forever addon for groups of friends leveling professions together. It answers one
question: *what should I do with what I have, for the group?*

- **Item tooltip**: who in your group needs this material, how many, and how soon.
- **Group window** (`/comrade`): each character's leveling route (recipes to learn at the
  trainer, intermediates to craft, skill-up chances, costs), what they can craft, the most
  wanted materials, what you can give to whom, and what to disenchant or keep.
- **Step panel**: next to the profession window, the current step, its skill-up chance,
  how many crafts your bags allow, and the next step.
- **Mail helper**: attaches what a group member needs. It never sends the mail for you.
- **Sharing** with the friends and guildmates you add, opt-in per character.

English and French (follows the game's language).

## Requirements

- WoW Forever (client 1.60.1, Interface 16001).
- No other addon is required. The libraries it uses are embedded; see
  [THIRD_PARTY.md](THIRD_PARTY.md) for the list and their licenses.

## Recommended addons

All optional. ComradeCraft detects them when the game loads.

| Addon | What it adds | Without it |
|---|---|---|
| [TradeSkillMaster](https://www.curseforge.com/wow/addons/tradeskill-master) | Auction prices (DBMarket) for step costs and route choice; disenchant value (Destroy) for "sell or disenchant" advice; **Shopping list** button gives a search text for TSM's Shopping tab and a group to import (`ComradeCraft > Character > Tailoring 80-125`); TSM has no API to create, change or delete groups, so ComradeCraft tells you which ones are done or replaced | Auctionator, else merchant prices |
| [Auctionator](https://www.curseforge.com/wow/addons/auctionator) | Auction prices when TSM is absent; **Shopping list** button exports a plan's missing mats as an Auctionator list; disenchant value | No shopping list export (`/comrade shop` still prints the list) |
| [Pawn](https://www.curseforge.com/wow/addons/pawn) | Upgrade detection with the class and specialization scale of each group member | Item level comparison |

Notes:

- When TSM and Auctionator are both loaded, prices come from TSM.
- Pawn is called while the game runs; none of its scales are copied (its license forbids it).
- Mail addons (Postal, TSM's mail tab, ...): the mail button sits outside the send-mail
  frame so it does not cover them. If an addon replaces that frame, click an entry of
  "You can give" in the group window while the mailbox is open, or type `/comrade mail NAME`.

Not yet verified in game: the step panel's position, the TSM search text and group import, Pawn's scale names on Forever, the
Auctionator export, the TSM and Auctionator disenchant values, and the mail helper next to
other mail addons.

## Commands

| Command | Effect |
|---|---|
| `/comrade` | Open the group window |
| `/comrade shop [profession]` | List the mats to buy; export them to Auctionator and/or show TSM's search text |
| `/comrade tracker [reset]` | Show/hide the step panel; `reset` docks it back next to the profession window |
| `/comrade mail NAME` | At a mailbox: attach what NAME needs |
| `/comrade share [off]` | Share this character with your group (off by default) |
| `/comrade add NAME` / `remove NAME` | Add or remove a player (both sides must add each other) |
| `/comrade peers` / `sync` | List the players seen / send your data now |
| `/comrade guildping [off]` | Tell the guild you use ComradeCraft (a presence signal only) |
| `/comrade needs` / `stats` | Print your route / the measured skill-up rates |
| `/comrade scan` / `api` / `audit` / `log clear` | Diagnostics |

## Privacy

No character data is sent until you share a character. Data then goes by addon whisper,
only to the players you added and who added you back. At login, a presence signal (no
character data) goes to your guild's addon channel so guildmates with ComradeCraft can be
suggested; `/comrade guildping off` turns it off.

## Data

Recipe colors and reagents come from the WoW Forever client tables (published by
wago.tools). Skill-up chances start from the Classic formula and are calibrated with the
crafts you and your group log. Disenchant yields are estimates until enough real
disenchants are logged.

## License

MIT, see [LICENSE](LICENSE). Embedded libraries keep their own licenses.
