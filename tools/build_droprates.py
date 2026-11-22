"""Offline generator: extracts Classic 1.12 recipe drop rates (%) from CMaNGOS classic-db
into ComradeCraft/Data/DropRates.lua for every recipe scroll in LibProfessionDB.

Usage: tools/.venv/Scripts/python tools/build_droprates.py
"""
import gzip
import io
import os
import re
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECIPE_ITEMS_LUA = os.path.join(ROOT, "ComradeCraft", "Libs", "LibProfessionDB-1.0", "Data", "RecipeItems.lua")
OUT_LUA = os.path.join(ROOT, "ComradeCraft", "Data", "DropRates.lua")
SQL_URL = "https://raw.githubusercontent.com/cmangos/classic-db/master/Full_DB/ClassicDB_1_12_1_z2815.sql.gz"


def load_recipe_items():
    txt = open(RECIPE_ITEMS_LUA, encoding="utf-8").read()
    # [spellID]=itemID
    spell_to_item = {}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*(\d+)", txt):
        spell_to_item[int(m.group(1))] = int(m.group(2))
    return set(spell_to_item.values()), spell_to_item


def parse_tuples(values_str):
    # SQL INSERT values: (a,b,c,'str',...), (...)
    rows = []
    for m in re.finditer(r"\(([^()]+)\)", values_str):
        parts = [p.strip() for p in m.group(1).split(",")]
        if len(parts) >= 6:
            try:
                entry = int(parts[0])
                item = int(parts[1])
                chance = abs(float(parts[2]))
                groupid = int(parts[3])
                min_or_ref = int(parts[4])
                rows.append((entry, item, chance, groupid, min_or_ref))
            except ValueError:
                pass
    return rows


def group_chances(rows):
    # Computes effective drop chance (%) for every row inside an entry's loot table.
    by_eg = {}
    for entry, item, chance, groupid, min_or_ref in rows:
        by_eg.setdefault((entry, groupid), []).append((item, chance, min_or_ref))
    eff = []
    for (entry, gid), lst in by_eg.items():
        if gid == 0:
            for item, ch, mr in lst:
                eff.append((entry, item, ch, mr))
        else:
            pos_sum = sum(ch for _, ch, _ in lst if ch > 0)
            zeros = sum(1 for _, ch, _ in lst if ch == 0)
            zero_ch = max(0.0, 100.0 - pos_sum) / zeros if zeros > 0 else 0.0
            for item, ch, mr in lst:
                eff.append((entry, item, ch if ch > 0 else zero_ch, mr))
    return eff


def main():
    recipe_items, _ = load_recipe_items()
    print(f"Loaded {len(recipe_items)} recipe item IDs from LibProfessionDB")
    print("Downloading CMaNGOS classic-db SQL dump...")
    req = urllib.request.Request(SQL_URL, headers={"User-Agent": "ComradeCraft-Builder"})
    with urllib.request.urlopen(req, timeout=60) as r:
        gz_data = r.read()
    print(f"Downloaded {len(gz_data) / 1024 / 1024:.1f} MB, parsing loot tables...")

    clt_rows = []
    rlt_rows = []
    with gzip.GzipFile(fileobj=io.BytesIO(gz_data)) as f:
        for raw in f:
            line = raw.decode("utf-8", errors="ignore")
            if line.startswith("INSERT INTO `creature_loot_template` VALUES"):
                clt_rows.extend(parse_tuples(line))
            elif line.startswith("INSERT INTO `reference_loot_template` VALUES"):
                rlt_rows.extend(parse_tuples(line))

    print(f"Parsed {len(clt_rows)} creature_loot rows, {len(rlt_rows)} reference_loot rows")
    ref_eff = group_chances(rlt_rows)
    # Build ref_id -> [(item_or_ref, chance, is_ref)]
    ref_map = {}
    for entry, item, ch, mr in ref_eff:
        if ch > 0:
            ref_map.setdefault(entry, []).append((item, ch, mr < 0, -mr if mr < 0 else 0))

    # Resolve reference chains (depth <= 4) to recipe items: ref_id -> { recipeItemID: maxChancePct }
    ref_cache = {}
    def resolve_ref(ref_id, depth=0):
        if ref_id in ref_cache:
            return ref_cache[ref_id]
        if depth > 4:
            return {}
        out = {}
        for item, ch, is_ref, sub_ref in ref_map.get(ref_id, []):
            if is_ref:
                for rid, sub_ch in resolve_ref(sub_ref, depth + 1).items():
                    c = (ch / 100.0) * sub_ch
                    if c > out.get(rid, 0.0):
                        out[rid] = c
            elif item in recipe_items:
                if ch > out.get(item, 0.0):
                    out[item] = ch
        ref_cache[ref_id] = out
        return out

    # Scan creature_loot_template for direct & reference drops of recipe items.
    best_rate = {}
    for entry, item, ch, mr in group_chances(clt_rows):
        if ch <= 0:
            continue
        if mr < 0:
            for rid, sub_ch in resolve_ref(-mr).items():
                c = (ch / 100.0) * sub_ch
                if c > best_rate.get(rid, 0.0):
                    best_rate[rid] = c
        elif item in recipe_items:
            if ch > best_rate.get(item, 0.0):
                best_rate[item] = ch

    # Keep rates >= 0.01% (rounded nicely).
    items_sorted = sorted((rid, round(rate, 2)) for rid, rate in best_rate.items() if rate >= 0.01)
    lines = [
        "-- DropRates: best Classic 1.12 mob drop chance (%) per recipe scroll itemID.",
        "-- Generated offline from CMaNGOS classic-db (tools/build_droprates.py); shown as ~X%.",
        "local _, ns = ...",
        "ns.DropRates = {",
    ]
    buf = []
    for rid, rate in items_sorted:
        rstr = f"{rate:.2f}".rstrip("0").rstrip(".")
        buf.append(f"[{rid}]={rstr}")
        if len(buf) == 8:
            lines.append("  " + ", ".join(buf) + ",")
            buf = []
    if buf:
        lines.append("  " + ", ".join(buf) + ",")
    lines.append("}")
    lines.append("")
    open(OUT_LUA, "w", encoding="utf-8").write("\n".join(lines))
    print(f"Wrote {len(items_sorted)} recipe drop rates to {OUT_LUA}")


if __name__ == "__main__":
    main()
