---
name: refresh-forever-data
description: Before a ComradeCraft release (or when someone reports wrong mats, sell prices or difficulty), regenerate Data/Recipes.lua from the latest WoW Forever client build on wago.tools and review the diff. Use when the user says "release", "deploy", "tag", "update data", "hotfix", or reports recipe numbers that differ from the game.
---

# Refresh Forever client data

`ComradeCraft/Data/Recipes.lua` (recipes, reagents, difficulty, merchant prices, reputation)
is generated from the Forever client tables published by wago.tools. Blizzard hotfixes change
them (Nov 2026: five bags +1 bolt, Iron Grenade sell price). A release must ship the latest build.

1. Latest build: `curl -s https://wago.tools/api/builds` -> `wowf[0].version`. Compare with
   `ns.RecipesBuild` in `ComradeCraft/Data/Recipes.lua`. Same build -> nothing to do.
2. Regenerate: `python -X utf8 tools/gen_recipes.py --build <version>` (downloads into the
   gitignored `tools/.cache/`).
3. Review `git diff --stat ComradeCraft/Data/Recipes.lua` and the changed lines: reagent counts,
   difficulty ranks, prices. Name the changed recipes from `tools/.cache/SpellName.csv`.
4. Run `tools/.venv/Scripts/python tools/check_lua.py` (must print `OK`).
5. Commit as `chore(data): regenerate recipes from Forever build <version>` listing the notable
   changes. Push and tags still need the user's explicit consent (a `v*` tag publishes to CurseForge).

Not covered by this data: LibProfessionDB (recipe sources, required skill; Vanilla values,
capped at the client's yellow rank in `ns.RequiredSkill`), required tools (SpellTotems).
