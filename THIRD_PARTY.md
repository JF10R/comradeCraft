# Third-party code and data

ComradeCraft's own code is MIT (see LICENSE). Embedded libraries keep their licenses:

| Library | Version | License | Source |
|---|---|---|---|
| LibStub | 2 | Public domain (stated in the file) | Ace3 repository |
| CallbackHandler-1.0 | Ace3 | BSD-style, Ace3 license (`Libs/AceComm-3.0/LICENSE-Ace3.txt`) | github.com/WoWUIDev/Ace3 |
| AceComm-3.0 + ChatThrottleLib | 14 / 32 | Ace3 license | github.com/WoWUIDev/Ace3 |
| LibSerialize | upstream | MIT (`Libs/LibSerialize/LICENSE`) | github.com/rossnichols/LibSerialize |
| LibDeflate | upstream | zlib (`Libs/LibDeflate/LICENSE.txt`) | github.com/SafeteeWoW/LibDeflate |
| LibDataBroker-1.1 | 4 | No license file; made to be embedded | github.com/tekkub/libdatabroker-1-1 |
| LibDBIcon-1.0 | 57 | No license file; made to be embedded | copied from BugSack's embedded copy |
| LibProfessionDB-1.0 | 1.9.1 (Forever data only) | MIT (`Libs/LibProfessionDB-1.0/LICENSE`) | curseforge.com/wow/addons/libprofessiondb |

Optional, not embedded: Pawn (CC BY-NC-ND 3.0). If installed, its scales are queried at
runtime (`PawnGetItemData`, `PawnGetSingleValueFromItem`); none of its weights are copied.

Disenchant yield estimates (`Disenchant.lua`) are facts compiled from the wow-professions.com
Forever disenchanting guide and warcraft.wiki.gg "Disenchanting tables".

Data: `ComradeCraft/Data/Recipes.lua` is generated from the WoW Forever client tables
(SkillLineAbility, SpellEffect, SpellReagents, ItemSparse) published by wago.tools.

Not covered: whether LibDataBroker and LibDBIcon may be redistributed; both ship embedded
in thousands of addons, but neither repository states a license.
