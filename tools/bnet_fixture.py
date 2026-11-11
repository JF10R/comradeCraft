"""Fetch a Forever character's professions from the Battle.net API and write a test fixture
in ComradeCraftDB.chars format (tools/fixtures/<slug>.json). No inventory: the API has none.

Usage: python -X utf8 tools/bnet_fixture.py <name>-<realm>
Battle.net recipe ids are SkillLineAbility IDs; they are mapped to spell ids via tools/.cache.
"""
import base64
import csv
import glob
import json
import os
import sys
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def env():
    cfg = {}
    with open(os.path.join(ROOT, ".env"), encoding="utf-8") as f:
        for line in f:
            if "=" in line and not line.lstrip().startswith("#"):
                k, v = line.split("=", 1)
                cfg[k.strip()] = v.strip()
    return cfg


def get(url, headers=None, data=None):
    req = urllib.request.Request(url, headers=headers or {}, data=data)
    with urllib.request.urlopen(req) as r:
        return json.load(r)


def main(slug):
    cfg = env()
    region = cfg.get("BNET_REGION") or "us"
    namespace = cfg.get("BNET_NAMESPACE") or f"profile-forever-{region}"
    basic = base64.b64encode(f"{cfg['BNET_CLIENT_ID']}:{cfg['BNET_CLIENT_SECRET']}".encode()).decode()
    token = get("https://oauth.battle.net/token", {"Authorization": "Basic " + basic},
                urllib.parse.urlencode({"grant_type": "client_credentials"}).encode())["access_token"]
    auth = {"Authorization": "Bearer " + token}
    base = f"https://{region}.api.blizzard.com/profile/wow/character/{slug}"
    profile = get(f"{base}?namespace={namespace}&locale=en_US", auth)
    profs = get(f"{base}/professions?namespace={namespace}&locale=en_US", auth)

    sla = glob.glob(os.path.join(ROOT, "tools", ".cache", "SkillLineAbility-*.csv"))[0]
    spell_of = {}
    with open(sla, encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            spell_of[int(r["ID"])] = (int(r["Spell"]), int(r["SkillLine"]))

    char = {"class": profile["character_class"]["name"].upper(), "professions": {}, "known": {},
            "bags": {}, "updated": profile.get("last_login_timestamp", 0) // 1000, "source": "bnet"}
    for group in ("primaries", "secondaries"):
        for p in profs.get(group, []):
            line = p["profession"]["id"]
            for tier in p.get("tiers", []):
                name = p["profession"]["name"]
                char["professions"][name] = {"rank": tier["skill_points"], "max": tier["max_skill_points"],
                                             "skillLine": line}
                known = char["known"].setdefault(str(line), {})
                for rec in tier.get("known_recipes", []):
                    if rec["id"] in spell_of:
                        known[str(spell_of[rec["id"]][0])] = True
            if "skill_points" in p:  # flat shape (no tiers)
                char["professions"][p["profession"]["name"]] = {
                    "rank": p["skill_points"], "max": p["max_skill_points"], "skillLine": line}

    key = f"{profile['name']}-{profile['realm']['name'] if 'realm' in profile else 'Forever'}"
    out = os.path.join(ROOT, "tools", "fixtures", f"{slug}.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        json.dump({"key": key, "char": char}, f, indent=1, ensure_ascii=False)
    n = sum(len(v) for v in char["known"].values())
    print(f"{key}: {len(char['professions'])} professions, {n} known recipes -> {out}")


if __name__ == "__main__":
    main(sys.argv[1])
