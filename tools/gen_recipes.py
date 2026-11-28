"""Generate ComradeCraft/Data/Recipes.lua from the Forever client DB2 tables on wago.tools.

Usage: python -X utf8 tools/gen_recipes.py [--build 1.60.1.70888]
Colors: yellow = TrivialSkillLineRankLow, grey = TrivialSkillLineRankHigh, green = midpoint.
"""
import argparse
import csv
import html
import json
import os
import re
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "tools", ".cache")
OUT = os.path.join(ROOT, "ComradeCraft", "Data", "Recipes.lua")
UA = {"User-Agent": "comradecraft-gen/0.1"}
CREATE_ITEM = "24"


def latest_build():
    req = urllib.request.Request("https://wago.tools/api/builds", headers=UA)
    with urllib.request.urlopen(req) as r:
        return json.load(r)["wowf"][0]["version"]


def hotfixes(name, build):
    """Server hotfixes for one table ({record: values or None if removed}); the CSV export lacks them."""
    path = os.path.join(CACHE, f"hotfix-{name}-{build}.json")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return {int(k): v for k, v in json.load(f).items()}
    num, page, last, best = int(build.split(".")[-1]), 1, 1, {}
    while page <= last:
        q = urllib.parse.urlencode({"search": f"{num} {name.lower()}", "page": page})
        req = urllib.request.Request(f"https://wago.tools/hotfixes?{q}", headers=UA)
        with urllib.request.urlopen(req) as r:
            body = r.read().decode("utf-8")
        hf = json.loads(html.unescape(re.search(r'data-page="([^"]*)"', body).group(1)))["props"]["hotfixes"]
        last = hf["last_page"]
        for h in hf["data"]:
            if h["table_name"] != name or h["build"] != num or h["status"] not in (1, 2):
                continue  # status 1 = valid, 2 = record removed (3 invalid, 4 not public)
            old = best.get(h["record_id"])
            if not old or h["push_id"] > old[0]:
                best[h["record_id"]] = (h["push_id"], h["data"] if h["status"] == 1 else None)
        page += 1
        time.sleep(0.3)  # be gentle with wago.tools
    out = {rec: v for rec, (_, v) in best.items()}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(out, f)
    return out


def flatten(v):
    return [y for x in v for y in (flatten(x) if isinstance(x, list) else [x])]


def table(name, build, hotfix=True):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f"{name}-{build}.csv")
    if not os.path.exists(path):
        url = f"https://wago.tools/db2/{name}/csv?build={build}"
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req) as r, open(path, "wb") as f:
            f.write(r.read())
    with open(path, encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = {int(r["ID"]): r for r in reader}
        cols = reader.fieldnames
    if hotfix:
        applied = 0
        for rec, data in hotfixes(name, build).items():
            if data is None:
                applied += rows.pop(rec, None) is not None
                continue
            vals = flatten(data)
            if len(vals) != len(cols):
                print(f"  {name} hotfix {rec}: {len(vals)} fields vs {len(cols)} columns, skipped")
                continue
            rows[rec] = {c: str(v) for c, v in zip(cols, vals)}
            applied += 1
        print(f"{name}: {applied} server hotfixes applied")
    return list(rows.values())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--build")
    build = ap.parse_args().build or latest_build()

    recipes = {}
    for r in table("SkillLineAbility", build):
        high = int(r["TrivialSkillLineRankHigh"])
        if high <= 0:
            continue  # not a craftable recipe (spells, passives, gathering)
        spell = int(r["Spell"])
        recipes[spell] = {
            "line": int(r["SkillLine"]),
            "yellow": int(r["TrivialSkillLineRankLow"]),
            "grey": high,
            "ups": int(r["NumSkillUps"] or 1),
            "item": 0, "qty": 0, "reagents": [],
        }

    for r in table("SpellEffect", build):
        rec = recipes.get(int(r["SpellID"]))
        if rec and r["Effect"] == CREATE_ITEM and int(r["EffectItemType"]) and not rec["item"]:
            rec["item"] = int(r["EffectItemType"])
            rec["qty"] = max(1, round(float(r["EffectBasePointsF"] or 1)))

    for r in table("SpellReagents", build):
        rec = recipes.get(int(r["SpellID"]))
        if not rec:
            continue
        for i in range(8):
            item, count = int(r[f"Reagent_{i}"]), int(r[f"ReagentCount_{i}"])
            if item and count:
                rec["reagents"] += [item, count]

    # Spells without reagents are not crafts (Disenchant 13262 sits in Enchanting's skill line).
    dropped = [s for s, r in recipes.items() if not r["reagents"]]
    for s in dropped:
        del recipes[s]
    print(f"dropped {len(dropped)} reagent-less spells (e.g. {sorted(dropped)[:5]})")

    # Merchant prices of every reagent and crafted item: a value proxy when no AH data exists.
    items = set()
    for r in recipes.values():
        items.update(r["reagents"][0::2])
        if r["item"]:
            items.add(r["item"])
    # Recipe teaching items (LibProfessionDB): their merchant price feeds the route's recipe cost.
    lib_items = os.path.join(ROOT, "ComradeCraft", "Libs", "LibProfessionDB-1.0", "Data", "RecipeItems.lua")
    with open(lib_items, encoding="utf-8") as f:
        items.update(int(m) for m in re.findall(r"^\[\d+\]=(\d+),", f.read(), re.M))
    prices, reps = {}, {}
    tool_items = {}
    for r in table("ItemSparse", build, hotfix=False):  # ~100k hotfix rows per build: not fetched
        i = int(r["ID"])
        if i in items or int(r["TotemCategoryID"] or 0) > 0:  # tools too: the hammer's price
            prices[i] = (int(r["SellPrice"] or 0), int(r["BuyPrice"] or 0))
            if int(r["MinFactionID"] or 0) > 0:
                reps[i] = (int(r["MinFactionID"]), int(r["MinReputation"] or 0))
        if int(r["TotemCategoryID"] or 0) > 0:
            tool_items[i] = int(r["TotemCategoryID"])

    # Tools (hammer, runed rod) and stations (anvil, loom) a recipe needs.
    tools, focus = {}, {}
    for r in table("SpellTotems", build):
        spell = int(r["SpellID"])
        if spell in recipes:
            cats = [int(r[k]) for k in ("RequiredTotemCategoryID_0", "RequiredTotemCategoryID_1") if int(r[k])]
            cats += [-int(r[k]) for k in ("Totem_0", "Totem_1") if int(r[k])]  # negative = exact item
            if cats:
                tools[spell] = cats
    for r in table("SpellCastingRequirements", build):
        spell = int(r["SpellID"])
        if spell in recipes and int(r["RequiresSpellFocus"] or 0):
            focus[spell] = int(r["RequiresSpellFocus"])
    used_cats = {c for cs in tools.values() for c in cs if c > 0}
    cats = {int(r["ID"]): (r["Name_lang"], int(r["TotemCategoryType"]), int(r["TotemCategoryMask"]))
            for r in table("TotemCategory", build)}
    focus_names = {int(r["ID"]): r["Name_lang"] for r in table("SpellFocusObject", build)
                   if int(r["ID"]) in set(focus.values())}

    lines = [
        f"-- GENERATED by tools/gen_recipes.py from wago.tools build {build}. Do not edit.",
        "-- [spellID] = { skillLine, yellow, grey, numSkillUps, itemID, qty, { reagentID, count, ... } }",
        "local _, ns = ...",
        f'ns.RecipesBuild = "{build}"',
        "ns.Recipes = {",
    ]
    for spell in sorted(recipes):
        r = recipes[spell]
        reag = ",".join(map(str, r["reagents"]))
        lines.append(f"[{spell}]={{{r['line']},{r['yellow']},{r['grey']},{r['ups']},{r['item']},{r['qty']},{{{reag}}}}},")
    lines.append("}")
    # Enchants (no crafted item): which equipment they apply to, so leveling can keep targets
    # and upgrades match exact weapon/armor subclasses (e.g. 2H weapon vs 1H dagger, shield vs armor).
    # invMask bit n = inventory type n (e.g. 512 = 1<<9 = wrist; 1048608 = chest + robe).
    # subMask bit n = item subclass n (e.g. 1378 = 2H weapons + staves; 64 = shields).
    lines.append("-- [spellID] = { itemClass, invTypeMask, subClassMask } for enchants (SpellEquippedItems)")
    lines.append("ns.EnchantSlots = {")
    n_slots = 0
    for r in table("SpellEquippedItems", build):
        spell = int(r["SpellID"])
        if spell in recipes and recipes[spell]["item"] == 0:
            lines.append(
                f"[{spell}]={{{int(r['EquippedItemClass'])},{int(r['EquippedItemInvTypes'])},{int(r['EquippedItemSubclass'])}}},"
            )
            n_slots += 1
    lines.append("}")
    print(f"{n_slots} enchants with an equipment slot")
    lines.append("-- [itemID] = { sellPrice, buyPrice } in copper (ItemSparse)")
    lines.append("ns.ItemPrices = {")
    for i in sorted(prices):
        lines.append(f"[{i}]={{{prices[i][0]},{prices[i][1]}}},")
    lines.append("}")
    lines.append("-- [itemID] = { factionID, standing } reputation needed to buy it (ItemSparse; 4 = Friendly)")
    lines.append("ns.ItemReputation = {")
    for i in sorted(reps):
        lines.append(f"[{i}]={{{reps[i][0]},{reps[i][1]}}},")
    lines.append("}")

    def q(s):
        return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'
    lines.append("-- [spellID] = { totemCategoryID or -itemID, ... } tools the recipe needs (SpellTotems)")
    lines.append("ns.RecipeTools = {")
    lines += [f"[{s}]={{{','.join(map(str, tools[s]))}}}," for s in sorted(tools)]
    lines.append("}")
    lines.append("-- [totemCategoryID] = { name, type, mask }: an item of category B fits A if same type and B's mask covers A's")
    lines.append("ns.ToolCategories = {")
    for c in sorted(cats):
        if cats[c][1] in {cats[u][1] for u in used_cats if u in cats}:
            lines.append(f"[{c}]={{{q(cats[c][0])},{cats[c][1]},{cats[c][2]}}},")
    lines.append("}")
    lines.append("-- [itemID] = totemCategoryID (ItemSparse)")
    lines.append("ns.ToolItems = {")
    lines += [f"[{i}]={tool_items[i]}," for i in sorted(tool_items)]
    lines.append("}")
    lines.append("-- [spellID] = spellFocusObjectID: the station to stand next to (SpellCastingRequirements)")
    lines.append("ns.RecipeFocus = {")
    lines += [f"[{s}]={focus[s]}," for s in sorted(focus)]
    lines.append("}")
    lines.append("-- [spellFocusObjectID] = English name (SpellFocusObject)")
    lines.append("ns.FocusNames = {")
    lines += [f"[{k}]={q(focus_names[k])}," for k in sorted(focus_names)]
    lines.append("}")
    print(f"{len(tools)} recipes need a tool, {len(focus)} a station")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print(f"build {build}: {len(recipes)} recipes -> {OUT}")


if __name__ == "__main__":
    main()
