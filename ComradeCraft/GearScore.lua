-- GearScore: standalone Classic/Forever gear & enchant scoring by class, spec and weapon setup.
-- Pure logic over WoW's C_Item.GetItemStats / GetItemInfo + ns.EnchantSlots (no external DB).
local _, ns = ...
local L = ns.L

local GS = {}
ns.GearScore = GS

local function Bit(mask, n)
  return math.floor(mask / (2 ^ n)) % 2 == 1
end
GS.Bit = Bit

-- InventoryType string -> numeric inventoryType (matches SpellEquippedItems bit positions).
local INVTYPE = {
  INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4, INVTYPE_CHEST = 5,
  INVTYPE_WAIST = 6, INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
  INVTYPE_FINGER = 11, INVTYPE_TRINKET = 12, INVTYPE_WEAPON = 13, INVTYPE_SHIELD = 14,
  INVTYPE_RANGED = 15, INVTYPE_CLOAK = 16, INVTYPE_2HWEAPON = 17, INVTYPE_ROBE = 20,
  INVTYPE_WEAPONMAINHAND = 21, INVTYPE_WEAPONOFFHAND = 22, INVTYPE_HOLDABLE = 23,
  INVTYPE_THROWN = 25, INVTYPE_RANGEDRIGHT = 26, INVTYPE_RELIC = 28,
}
GS.INVTYPE = INVTYPE

-- Equipment slot(s) an inventoryType goes into (cosmetic Shirts/Tabards excluded).
local SLOTS_OF = {
  INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
  INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
  INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 },
  INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
  INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
  INVTYPE_WEAPON = { 16, 17 }, INVTYPE_WEAPONOFFHAND = { 17 },
  INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
  INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}
GS.SLOTS_OF = SLOTS_OF

-- Specs per class (in Classic talent-tab order 1, 2, 3; extra profiles follow).
GS.SPECS = {
  WARRIOR = { "arms", "fury", "protection" },
  PALADIN = { "holy", "protection", "retribution" },
  HUNTER  = { "beastmastery", "marksmanship", "survival", "survivalmelee" },
  ROGUE   = { "assassination", "combat", "subtlety" },
  PRIEST  = { "discipline", "holy", "shadow" },
  SHAMAN  = { "elemental", "enhancement", "restoration" },
  MAGE    = { "arcane", "fire", "frost" },
  WARLOCK = { "affliction", "demonology", "destruction" },
  DRUID   = { "balance", "feral", "bear", "restoration" },
}

-- Readable short labels for specs (class-agnostic English, kept concise in UI).
local SPEC_LABELS = {
  arms = "Arms", fury = "Fury", protection = "Protection",
  holy = "Holy", retribution = "Retribution",
  beastmastery = "BM", marksmanship = "MM", survival = "Survival", survivalmelee = "Surv Melee",
  assassination = "Assassination", combat = "Combat", subtlety = "Subtlety",
  discipline = "Discipline", shadow = "Shadow",
  elemental = "Elemental", enhancement = "Enhancement", restoration = "Restoration",
  arcane = "Arcane", fire = "Fire", frost = "Frost",
  affliction = "Affliction", demonology = "Demonology", destruction = "Destruction",
  balance = "Balance", feral = "Feral Cat", bear = "Feral Bear",
}

function GS.SpecLabel(spec)
  return SPEC_LABELS[spec] or (spec and (spec:sub(1, 1):upper() .. spec:sub(2))) or ""
end

-- Localized / English talent tab name aliases -> canonical spec key.
local SPEC_ALIASES = {
  -- Warrior
  arms = "arms", armes = "arms", waffen = "arms", armas = "arms",
  fury = "fury", fureur = "fury", furor = "fury", furia = "fury",
  protection = "protection", schutz = "protection", proteccion = "protection", protecao = "protection",
  -- Paladin
  holy = "holy", sacre = "holy", heilig = "holy", sagrado = "holy",
  retribution = "retribution", vindicte = "retribution", vergeltung = "retribution", reprension = "retribution",
  -- Hunter
  ["beast mastery"] = "beastmastery", beastmastery = "beastmastery", bm = "beastmastery",
  ["maitrise des betes"] = "beastmastery", tierherrschaft = "beastmastery", bestias = "beastmastery",
  marksmanship = "marksmanship", mm = "marksmanship", precision = "marksmanship",
  treffsicherheit = "marksmanship", punteria = "marksmanship",
  survival = "survival", survie = "survival", uberleben = "survival", supervivencia = "survival",
  survivalmelee = "survivalmelee", ["surv melee"] = "survivalmelee", melee = "survivalmelee",
  -- Rogue
  assassination = "assassination", assassinat = "assassination", meucheln = "assassination", asesinato = "assassination",
  combat = "combat", kampf = "combat", combate = "combat",
  subtlety = "subtlety", finesse = "subtlety", tauschung = "subtlety", sutileza = "subtlety",
  -- Priest
  discipline = "discipline", disziplin = "discipline", disciplina = "discipline",
  shadow = "shadow", ombre = "shadow", schatten = "shadow", sombra = "shadow", sombras = "shadow",
  -- Shaman
  elemental = "elemental", elementaire = "elemental", elementar = "elemental",
  enhancement = "enhancement", amelioration = "enhancement", verstarker = "enhancement", mejora = "enhancement",
  restoration = "restoration", restauration = "restoration", wiederherstellung = "restoration", restauracion = "restoration",
  -- Mage
  arcane = "arcane", arcanes = "arcane", arkan = "arcane", arcano = "arcane",
  fire = "fire", feu = "fire", feuer = "fire", fuego = "fire",
  frost = "frost", givre = "frost", escarcha = "frost",
  -- Warlock
  affliction = "affliction", gebrechen = "affliction", afliccion = "affliction",
  demonology = "demonology", demonologie = "demonology", demonologia = "demonology",
  destruction = "destruction", zerstorung = "destruction", destruccion = "destruction",
  -- Druid
  balance = "balance", equilibre = "balance", gleichgewicht = "balance", equilibrio = "balance",
  ["feral combat"] = "feral", feral = "feral", ["combat farouche"] = "feral",
  ["wilder kampf"] = "feral", ["feral cat"] = "feral", cat = "feral",
  bear = "bear", ["feral bear"] = "bear", ours = "bear", tank = "bear",
}

local function StripAccents(s)
  -- Strip common Latin UTF-8 accents so French/German/Spanish tab names match cleanly.
  s = s:gsub("\195[\160-\165]", "a"):gsub("\195[\168-\171]", "e"):gsub("\195[\172-\175]", "i")
    :gsub("\195[\178-\182]", "o"):gsub("\195[\185-\188]", "u"):gsub("\195\167", "c")
    :gsub("\195[\128-\133]", "a"):gsub("\195[\136-\139]", "e"):gsub("\195[\140-\143]", "i")
    :gsub("\195[\146-\150]", "o"):gsub("\195[\153-\156]", "u"):gsub("\195\135", "c")
  return s:lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function ValidSpec(class, key)
  for _, s in ipairs(GS.SPECS[class] or {}) do
    if s == key then return s end
  end
end

-- Resolves canonical spec key for a character: explicit override -> talent tab index -> name -> default.
function GS.GetSpec(c)
  if not (c and c.class and GS.SPECS[c.class]) then return nil end
  if c.specOverride then
    local v = ValidSpec(c.class, c.specOverride)
    if v then return v end
  end
  if c.spec then
    local norm = StripAccents(tostring(c.spec))
    local mapped = ValidSpec(c.class, SPEC_ALIASES[norm] or norm)
    if mapped then return mapped end
    -- Partial match for names like "Mage: Frost" or "Feral Combat".
    for alias, key in pairs(SPEC_ALIASES) do
      if #alias >= 4 and norm:find(alias, 1, true) then
        local v = ValidSpec(c.class, key)
        if v then return v end
      end
    end
  end
  if c.specIdx and c.specIdx >= 1 and c.specIdx <= 3 then
    local list = GS.SPECS[c.class]
    -- Map talent tab index 1..3 (Druid tab 3 is restoration, tab 2 is feral).
    if c.class == "DRUID" and c.specIdx == 3 then return "restoration" end
    if list[c.specIdx] then return list[c.specIdx] end
  end
  return GS.SPECS[c.class][1]
end

-- Signature talent spells per class & spec: { { spellID, weight }, ... }.
-- Used as fallback auto-detection on WoW Forever when GetTalentTabInfo is unavailable,
-- so e.g. a Mage with Frost talents defaults to Frost automatically.
local TALENT_SPELLS = {
  MAGE = {
    arcane = { { 11210, 1 }, { 11222, 1 }, { 12536, 2 }, { 12043, 3 }, { 12042, 3 } },
    fire   = { { 11103, 1 }, { 11119, 2 }, { 11366, 2 }, { 11113, 3 }, { 11129, 3 } },
    frost  = { { 11070, 1 }, { 11071, 1 }, { 11207, 1 }, { 11175, 1 }, { 11170, 2 }, { 11180, 2 },
               { 12472, 3 }, { 11958, 3 }, { 11426, 3 } },
  },
  WARRIOR = {
    arms       = { { 12296, 1 }, { 12162, 2 }, { 16493, 2 }, { 12292, 3 }, { 12294, 3 } },
    fury       = { { 12320, 1 }, { 12317, 2 }, { 12319, 2 }, { 12328, 3 }, { 23881, 3 } },
    protection = { { 12298, 1 }, { 12792, 2 }, { 12975, 2 }, { 12809, 3 }, { 23922, 3 } },
  },
  PALADIN = {
    holy        = { { 20205, 1 }, { 20210, 2 }, { 20216, 3 }, { 20473, 3 } },
    protection  = { { 20127, 1 }, { 20911, 2 }, { 20925, 3 } },
    retribution = { { 20101, 1 }, { 20117, 2 }, { 20375, 2 }, { 20049, 2 }, { 20066, 3 } },
  },
  HUNTER = {
    beastmastery = { { 19583, 1 }, { 19616, 2 }, { 19577, 3 }, { 19621, 2 }, { 19574, 3 } },
    marksmanship = { { 19485, 2 }, { 19434, 2 }, { 19503, 3 }, { 19506, 3 } },
    survival     = { { 24294, 1 }, { 19159, 1 }, { 19263, 2 }, { 19306, 3 }, { 24335, 3 } },
  },
  ROGUE = {
    assassination = { { 14138, 1 }, { 14156, 2 }, { 14179, 2 }, { 14177, 3 }, { 14186, 3 }, { 14983, 3 } },
    combat        = { { 13705, 1 }, { 14251, 2 }, { 13715, 2 }, { 13877, 3 }, { 13750, 3 } },
    subtlety      = { { 13958, 1 }, { 14278, 2 }, { 14185, 3 }, { 16511, 3 }, { 14183, 3 } },
  },
  PRIEST = {
    discipline = { { 14522, 1 }, { 14520, 2 }, { 14751, 2 }, { 14752, 3 }, { 10060, 3 } },
    holy       = { { 16181, 1 }, { 15237, 2 }, { 14901, 2 }, { 20711, 3 }, { 724, 3 } },
    shadow     = { { 15270, 1 }, { 15407, 2 }, { 15257, 2 }, { 15487, 2 }, { 15286, 3 }, { 15473, 3 } },
  },
  SHAMAN = {
    elemental   = { { 16035, 1 }, { 16039, 1 }, { 16038, 1 }, { 16089, 2 }, { 16166, 3 } },
    enhancement = { { 17485, 1 }, { 16255, 1 }, { 16269, 2 }, { 16256, 2 }, { 17364, 3 } },
    restoration = { { 16179, 1 }, { 16176, 1 }, { 16188, 3 }, { 16190, 3 } },
  },
  WARLOCK = {
    affliction  = { { 17810, 1 }, { 12623, 1 }, { 18094, 2 }, { 18223, 2 }, { 18265, 3 }, { 18220, 3 } },
    demonology  = { { 18697, 1 }, { 18708, 2 }, { 18788, 3 }, { 23759, 2 }, { 19028, 3 } },
    destruction = { { 17778, 1 }, { 17788, 1 }, { 17877, 2 }, { 17954, 2 }, { 17959, 3 }, { 17962, 3 } },
  },
  DRUID = {
    balance     = { { 16814, 1 }, { 16880, 2 }, { 16909, 2 }, { 24858, 3 } },
    feral       = { { 17056, 1 }, { 16929, 1 }, { 16979, 2 }, { 16857, 2 }, { 17007, 3 } },
    restoration = { { 17063, 1 }, { 17106, 2 }, { 17104, 2 }, { 17116, 3 }, { 18562, 3 } },
  },
}

local function SpellKnown(id)
  local fn = IsPlayerSpell or (C_SpellBook and C_SpellBook.IsSpellKnown) or IsSpellKnown
  if not fn then return false end
  local ok, v = pcall(fn, id)
  return ok and v == true
end

-- Infers the player's primary spec from learned talent spells (nil if none learned yet).
function GS.DetectSpecFromSpells(class)
  local trees = class and TALENT_SPELLS[class]
  if not trees then return nil end
  local bestSpec, bestScore = nil, 0
  for spec, spells in pairs(trees) do
    local score = 0
    for _, pair in ipairs(spells) do
      if SpellKnown(pair[1]) then score = score + pair[2] end
    end
    if score > bestScore then bestSpec, bestScore = spec, score end
  end
  return bestSpec
end

-- Sets (or clears with nil) the manual spec override for a character key.
function GS.SetSpec(charKey, specInput)
  local c = ComradeCraftDB and ComradeCraftDB.chars and ComradeCraftDB.chars[charKey]
  if not (c and c.class and GS.SPECS[c.class]) then return nil end
  if not specInput or specInput == "" or specInput == "auto" then
    c.specOverride = nil
    c.updated = time()
    ns.RequestRefresh()
    return GS.GetSpec(c)
  end
  local norm = StripAccents(tostring(specInput))
  local key = ValidSpec(c.class, SPEC_ALIASES[norm] or norm)
  if not key then
    for _, s in ipairs(GS.SPECS[c.class]) do
      if s:sub(1, #norm) == norm then key = s break end
    end
  end
  if not key then return nil end
  c.specOverride = key
  c.updated = time()
  ns.RequestRefresh()
  return key
end

-- Cycles to the next spec of a character (for quick UI toggle in Upgrades).
function GS.CycleSpec(charKey)
  local c = ComradeCraftDB and ComradeCraftDB.chars and ComradeCraftDB.chars[charKey]
  local list = c and c.class and GS.SPECS[c.class]
  if not (list and #list > 0) then return nil end
  local cur = GS.GetSpec(c)
  local idx = 1
  for i, s in ipairs(list) do
    if s == cur then idx = (i % #list) + 1 break end
  end
  return GS.SetSpec(charKey, list[idx])
end

-- Stat weights per class & spec (points per 1 of each stat, crit/hit/exp/dodge/parry/block/haste per 1%).
-- Authored from Classic/Forever combat mechanics: school spell damage & spell power dominate casters,
-- weapon DPS dominates melee/ranged physical specs, healing + MP5/Spirit/Int dominate healers.
local function Caster(extra)
  local w = { splpwr = 2.6, spldmg = 2.6, hit = 20, crit = 18, haste = 15, int = 1.0, spi = 0.4,
    mp5 = 1.4, sta = 0.4, splpen = 0.5, wandDps = 2.5 }
  for k, v in pairs(extra or {}) do w[k] = v end
  return w
end

local function Healer(extra)
  local w = { splheal = 2.4, splpwr = 2.4, mp5 = 2.8, spi = 1.3, int = 1.1, crit = 13, haste = 14, sta = 0.4 }
  for k, v in pairs(extra or {}) do w[k] = v end
  return w
end

GS.WEIGHTS = {
  WARRIOR = {
    arms = { dps = 15, ohDps = 6, str = 2.2, atkpwr = 1.0, agi = 1.3, crit = 22, hit = 24, exp = 20,
      haste = 14, sta = 0.5, armor = 0.02 },
    fury = { dps = 15, ohDps = 9, str = 2.2, atkpwr = 1.0, agi = 1.4, crit = 23, hit = 26, exp = 22,
      haste = 16, sta = 0.5, armor = 0.02 },
    protection = { sta = 2.4, def = 2.2, dodge = 20, parry = 20, blockPct = 14, block = 0.9, armor = 0.18,
      str = 1.3, agi = 1.1, hit = 14, exp = 16, atkpwr = 0.4, dps = 6 },
  },
  PALADIN = {
    holy = Healer({ crit = 20, int = 1.5, mp5 = 2.4, spi = 0.3, haste = 12 }),
    protection = { sta = 2.2, splpwr = 2.0, spldmg = 2.0, holsplpwr = 2.0, def = 2.0, blockPct = 16,
      block = 1.0, dodge = 18, parry = 18, armor = 0.16, str = 1.0, int = 0.8, hit = 12, exp = 12,
      mp5 = 1.2, dps = 5 },
    retribution = { dps = 15, str = 2.3, atkpwr = 1.0, crit = 20, hit = 22, exp = 18, agi = 1.1,
      splpwr = 1.1, spldmg = 1.1, holsplpwr = 1.1, int = 0.5, haste = 14, sta = 0.5, armor = 0.02 },
  },
  HUNTER = {
    beastmastery = { rangedDps = 16, agi = 2.4, rgdatkpwr = 1.0, atkpwr = 1.0, crit = 22, hit = 22,
      haste = 15, int = 0.6, mp5 = 0.8, sta = 0.4, str = 0.1, dps = 1.5 },
    marksmanship = { rangedDps = 17, agi = 2.4, rgdatkpwr = 1.0, atkpwr = 1.0, crit = 24, hit = 22,
      haste = 14, int = 0.6, mp5 = 0.8, sta = 0.4, str = 0.1, dps = 1.5 },
    survival = { rangedDps = 16, agi = 2.6, rgdatkpwr = 1.0, atkpwr = 1.0, crit = 22, hit = 22,
      haste = 14, int = 0.6, mp5 = 0.8, sta = 0.5, str = 0.2, dps = 2.5 },
    survivalmelee = { dps = 14, ohDps = 7, agi = 2.5, str = 1.2, atkpwr = 1.0, rgdatkpwr = 0.4,
      rangedDps = 4, crit = 22, hit = 22, exp = 18, haste = 14, int = 0.5, sta = 0.5 },
  },
  ROGUE = {
    assassination = { dps = 15, ohDps = 8, agi = 2.3, str = 1.0, atkpwr = 1.0, crit = 21, hit = 24,
      exp = 22, haste = 16, sta = 0.4, rangedDps = 1.0 },
    combat = { dps = 15, ohDps = 8.5, agi = 2.3, str = 1.0, atkpwr = 1.0, crit = 20, hit = 25,
      exp = 24, haste = 17, sta = 0.4, rangedDps = 1.0 },
    subtlety = { dps = 15, ohDps = 7.5, agi = 2.4, str = 1.0, atkpwr = 1.0, crit = 22, hit = 22,
      exp = 20, haste = 14, sta = 0.4, rangedDps = 1.0 },
  },
  PRIEST = {
    discipline = Healer({ int = 1.2, wandDps = 2.5 }),
    holy = Healer({ splheal = 2.5, splpwr = 2.5, spi = 1.4, crit = 14, wandDps = 2.5 }),
    shadow = Caster({ shasplpwr = 2.6, crit = 12, spi = 0.9, mp5 = 1.5, sta = 0.5 }),
  },
  SHAMAN = {
    elemental = Caster({ natsplpwr = 2.5, firsplpwr = 1.1, crit = 21, hit = 19, int = 1.2, mp5 = 1.6,
      spi = 0.3, sta = 0.5, wandDps = 0 }),
    enhancement = { dps = 14, str = 2.2, atkpwr = 1.0, agi = 1.5, crit = 20, hit = 22, exp = 18,
      haste = 14, splpwr = 0.9, spldmg = 0.9, natsplpwr = 0.7, firsplpwr = 0.6, int = 0.5,
      sta = 0.6, armor = 0.02 },
    restoration = Healer({ mp5 = 3.0, int = 1.2, crit = 14, haste = 15, spi = 0.5 }),
  },
  MAGE = {
    arcane = Caster({ arcsplpwr = 2.6, int = 1.6, spi = 0.6, mp5 = 1.6, haste = 16 }),
    fire = Caster({ firsplpwr = 2.6, crit = 23, int = 1.1 }),
    frost = Caster({ frosplpwr = 2.6, crit = 19, spi = 0.5 }),
  },
  WARLOCK = {
    affliction = Caster({ shasplpwr = 2.6, crit = 12, int = 0.9, sta = 0.8, spi = 0.3, mp5 = 1.0 }),
    demonology = Caster({ shasplpwr = 2.4, firsplpwr = 1.2, splpwr = 2.5, spldmg = 2.5, hit = 18,
      crit = 14, haste = 14, sta = 1.0, spi = 0.3, mp5 = 1.0 }),
    destruction = Caster({ firsplpwr = 2.5, shasplpwr = 2.0, crit = 21, hit = 19, haste = 16,
      sta = 0.7, spi = 0.3, mp5 = 1.0 }),
  },
  DRUID = {
    balance = Caster({ arcsplpwr = 2.1, natsplpwr = 2.3, crit = 19, hit = 19, int = 1.2, spi = 0.5,
      mp5 = 1.6, wandDps = 0 }),
    feral = { dps = 13, str = 2.2, agi = 2.2, atkpwr = 1.0, feratkpwr = 1.0, crit = 21, hit = 20,
      exp = 19, haste = 13, sta = 0.6, armor = 0.04 },
    bear = { sta = 2.4, armor = 0.28, agi = 1.8, str = 1.4, def = 2.0, dodge = 22, atkpwr = 0.5,
      feratkpwr = 0.6, hit = 12, exp = 14, dps = 6 },
    restoration = Healer({ mp5 = 2.6, crit = 11 }),
  },
}

-- Specs that can profitably wear lighter caster/healer armor (e.g. Cloth Frost/Healing gear).
local CASTER_ARMOR_SPECS = {
  ["PALADIN:holy"] = true, ["SHAMAN:elemental"] = true, ["SHAMAN:restoration"] = true,
  ["DRUID:balance"] = true, ["DRUID:restoration"] = true,
}

-- Specs that can hold caster off-hand items (INVTYPE_HOLDABLE).
local HOLDABLE_CLASSES = {
  MAGE = true, PRIEST = true, WARLOCK = true, DRUID = true, SHAMAN = true, PALADIN = true,
}
local SHIELD_CLASSES = { WARRIOR = true, PALADIN = true, SHAMAN = true }
local DUAL_WIELD_LEVEL = { ROGUE = 10, WARRIOR = 20, HUNTER = 20 } -- Shamans cannot DW on Forever

-- Weapon subclassIDs usable by each class:
-- 0=1HAxe, 1=2HAxe, 2=Bow, 3=Gun, 4=1HMace, 5=2HMace, 6=Polearm, 7=1HSword, 8=2HSword,
-- 10=Staff, 13=Fist, 15=Dagger, 16=Thrown, 18=Crossbow, 19=Wand
local function Set(t) local o = {} for _, v in ipairs(t) do o[v] = true end return o end
local WEAPON_PROF = {
  WARRIOR = Set({ 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18 }),
  PALADIN = Set({ 0, 1, 4, 5, 6, 7, 8 }),
  HUNTER  = Set({ 0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 18 }),
  ROGUE   = Set({ 2, 3, 4, 7, 13, 15, 16, 18 }),
  PRIEST  = Set({ 4, 10, 15, 19 }),
  SHAMAN  = Set({ 0, 1, 4, 5, 10, 13, 15 }),
  MAGE    = Set({ 7, 10, 15, 19 }),
  WARLOCK = Set({ 7, 10, 15, 19 }),
  DRUID   = Set({ 4, 5, 6, 10, 13, 15 }),
}

local function MainArmor(class, level)
  if class == "MAGE" or class == "PRIEST" or class == "WARLOCK" then return 1 end
  if class == "DRUID" or class == "ROGUE" then return 2 end
  local high = (level or 0) >= 40
  if class == "HUNTER" or class == "SHAMAN" then return high and 3 or 2 end
  if class == "WARRIOR" or class == "PALADIN" then return high and 4 or 3 end
  return nil
end

function GS.WeightsFor(c)
  local class = c and c.class
  local spec = GS.GetSpec(c)
  return class and spec and GS.WEIGHTS[class] and GS.WEIGHTS[class][spec] or nil, spec
end

-- WoW C_Item.GetItemStats keys -> internal weight key & divisor (for ratings reported at level 60 scale).
local STAT_MAP = {
  ITEM_MOD_STRENGTH_SHORT = { "str", 1 },
  ITEM_MOD_AGILITY_SHORT = { "agi", 1 },
  ITEM_MOD_STAMINA_SHORT = { "sta", 1 },
  ITEM_MOD_INTELLECT_SHORT = { "int", 1 },
  ITEM_MOD_SPIRIT_SHORT = { "spi", 1 },
  RESISTANCE0_NAME = { "armor", 1 },
  ITEM_MOD_ATTACK_POWER_SHORT = { "atkpwr", 1 },
  ITEM_MOD_RANGED_ATTACK_POWER_SHORT = { "rgdatkpwr", 1 },
  ITEM_MOD_FERAL_ATTACK_POWER_SHORT = { "feratkpwr", 1 },
  ITEM_MOD_MELEE_ATTACK_POWER_SHORT = { "feratkpwr", 1 },
  ITEM_MOD_SPELL_POWER_SHORT = { "splpwr", 1 },
  ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = { "spldmg", 1 },
  ITEM_MOD_SPELL_HEALING_DONE_SHORT = { "splheal", 1 },
  ITEM_MOD_SPELL_PENETRATION_SHORT = { "splpen", 1 },
  ITEM_MOD_ARCANE_DAMAGE_DONE_SHORT = { "arcsplpwr", 1 },
  ITEM_MOD_FIRE_DAMAGE_DONE_SHORT = { "firsplpwr", 1 },
  ITEM_MOD_FROST_DAMAGE_DONE_SHORT = { "frosplpwr", 1 },
  ITEM_MOD_HOLY_DAMAGE_DONE_SHORT = { "holsplpwr", 1 },
  ITEM_MOD_NATURE_DAMAGE_DONE_SHORT = { "natsplpwr", 1 },
  ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT = { "shasplpwr", 1 },
  ITEM_MOD_HIT_RATING_SHORT = { "hit", 10 },
  ITEM_MOD_HIT_SPELL_RATING_SHORT = { "hit", 10 },
  ITEM_MOD_CRIT_RATING_SHORT = { "crit", 14 },
  ITEM_MOD_CRIT_SPELL_RATING_SHORT = { "crit", 14 },
  ITEM_MOD_HASTE_RATING_SHORT = { "haste", 10 },
  ITEM_MOD_HASTE_SPELL_RATING_SHORT = { "haste", 10 },
  ITEM_MOD_EXPERTISE_RATING_SHORT = { "exp", 10 },
  ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = { "def", 1.5 },
  ITEM_MOD_DODGE_RATING_SHORT = { "dodge", 12 },
  ITEM_MOD_PARRY_RATING_SHORT = { "parry", 15 },
  ITEM_MOD_BLOCK_RATING_SHORT = { "blockPct", 5 },
  ITEM_MOD_BLOCK_VALUE_SHORT = { "block", 1 },
  ITEM_MOD_MANA_REGENERATION_SHORT = { "mp5", 1 },
  ITEM_MOD_POWER_REGEN0_SHORT = { "mp5", 1 },
}

local function ItemFacts(item)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not (get and item and item ~= 0) then return nil end
  local name, link, quality, ilvl, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID = get(item)
  if not name then return nil end
  return { name = name, link = link, quality = quality or 1, ilvl = ilvl or 0, reqLevel = reqLevel or 0,
    equipLoc = equipLoc or "", classID = classID, subclassID = subclassID }
end
GS.ItemFacts = ItemFacts

-- Scores a single item (itemID or itemLink) for character c using standalone spec weights.
-- Returns score, "stats" when stats/DPS were read, or nil when GetItemStats has no data.
function GS.ScoreItem(itemOrLink, c, offHand)
  local w = GS.WeightsFor(c)
  if not w then return nil end
  local f = ItemFacts(itemOrLink)
  if not f then return nil end
  local link = type(itemOrLink) == "string" and itemOrLink or f.link
  local getStats = (C_Item and C_Item.GetItemStats) or GetItemStats
  local raw = getStats and link and getStats(link)
  if type(raw) ~= "table" or next(raw) == nil then return nil end

  local score = 0
  for key, val in pairs(raw) do
    if type(val) == "number" and val ~= 0 then
      if key == "ITEM_MOD_DAMAGE_PER_SECOND_SHORT" then
        local eq = f.equipLoc
        if f.classID == 2 and f.subclassID == 19 then -- Wand
          score = score + val * (w.wandDps or 0)
        elseif eq == "INVTYPE_RANGED" or eq == "INVTYPE_RANGEDRIGHT" or eq == "INVTYPE_THROWN" then
          score = score + val * (w.rangedDps or 0)
        elseif offHand then
          score = score + val * (w.ohDps or ((w.dps or 0) * 0.5))
        else
          score = score + val * (w.dps or 0)
        end
      else
        local m = STAT_MAP[key]
        if m and w[m[1]] then
          score = score + (val / m[2]) * w[m[1]]
        end
      end
    end
  end
  return score, "stats"
end

-- Does `item` fit character `c` (class proficiencies, armor type, weapon type, level)?
-- `levelAhead` (optional, default 0): allow items up to `c.level + levelAhead` for "Soon" previews.
function GS.ItemFits(item, c, checkLevelFloor, levelAhead)
  local f = ItemFacts(item)
  if not (f and c and c.class and c.level and f.equipLoc ~= "") then return false end
  if not SLOTS_OF[f.equipLoc] then return false end
  if f.reqLevel > c.level + (levelAhead or 0) then return false end
  if checkLevelFloor ~= false and f.reqLevel < c.level - 10 then return false end

  local _, spec = GS.WeightsFor(c)
  if f.classID == 4 then -- Armor / Jewelry / Shield / Off-hand
    if f.equipLoc == "INVTYPE_SHIELD" or f.subclassID == 6 then
      if not SHIELD_CLASSES[c.class] then return false end
      -- Pure 2H specs (Arms, Fury, Retribution) don't want shields unless currently wearing one.
      if (spec == "arms" or spec == "fury" or spec == "retribution") then
        local wornOH = c.equipped and c.equipped[17]
        local ohf = wornOH and ItemFacts(wornOH)
        if not (ohf and (ohf.equipLoc == "INVTYPE_SHIELD" or ohf.subclassID == 6)) then return false end
      end
      return true
    end
    if f.equipLoc == "INVTYPE_HOLDABLE" then
      return HOLDABLE_CLASSES[c.class] == true and spec ~= "protection" and spec ~= "enhancement"
        and spec ~= "retribution" and spec ~= "feral" and spec ~= "bear"
    end
    if f.equipLoc == "INVTYPE_CLOAK" or f.equipLoc == "INVTYPE_NECK" or f.equipLoc == "INVTYPE_FINGER"
      or f.equipLoc == "INVTYPE_TRINKET" or f.equipLoc == "INVTYPE_RELIC" or f.subclassID == 0 then
      return true
    end
    local maxArmor = MainArmor(c.class, c.level)
    if not maxArmor then return false end
    if f.subclassID == maxArmor then return true end
    -- Lighter caster/healer armor only when the character explicitly plays that caster/healer spec.
    local hasExplicitSpec = c.specOverride or c.spec or c.specIdx
    if hasExplicitSpec and CASTER_ARMOR_SPECS[c.class .. ":" .. tostring(spec)]
      and f.subclassID >= 1 and f.subclassID < maxArmor then
      return true
    end
    return false
  elseif f.classID == 2 then -- Weapon
    local prof = WEAPON_PROF[c.class]
    if not (prof and prof[f.subclassID]) then return false end
    -- Off-hand only weapons require Dual Wield.
    if f.equipLoc == "INVTYPE_WEAPONOFFHAND" then
      local dwLvl = DUAL_WIELD_LEVEL[c.class]
      if not (dwLvl and c.level >= dwLvl) then return false end
    end
    -- Tank shield specs should not be suggested 2H weapons.
    if f.equipLoc == "INVTYPE_2HWEAPON" and spec == "protection" then return false end
    -- Assassination / Subtlety Rogues (18+) prefer daggers in main hand.
    if c.class == "ROGUE" and (spec == "assassination" or spec == "subtlety") and c.level >= 18
      and f.equipLoc == "INVTYPE_WEAPONMAINHAND" and f.subclassID ~= 15 then
      return false
    end
    return true
  end
  return false
end

-- Returns the worn itemLink (when scanned locally, preserving random suffixes) or itemID for a slot.
local function WornRef(c, slot)
  return (c.equippedLinks and c.equippedLinks[slot]) or (c.equipped and c.equipped[slot])
end

-- Evaluates if `item` is an upgrade for character `c`.
-- `levelAhead` (optional): when > 0, evaluates upcoming items (c.level < reqLevel <= c.level + levelAhead).
-- Returns isUpgrade, gain, how, slotKey, reqLevel.
function GS.UpgradeFor(item, c, scoreFn, levelAhead)
  local hasEq = c and c.equipped ~= nil
  if not GS.ItemFits(item, c, not hasEq, levelAhead) then return false end
  local f = ItemFacts(item)
  if levelAhead and levelAhead > 0 and (not f or f.reqLevel <= c.level) then return false end
  local slots = f and SLOTS_OF[f.equipLoc]
  if not slots then return false end
  if not hasEq then
    -- Without equipment data, do not blindly claim weapons for casters/healers unless stats confirm value.
    if f.classID == 2 and f.subclassID ~= 19 then
      local w = GS.WeightsFor(c)
      local s = GS.ScoreItem(item, c, false)
      if s then
        if s <= 0 then return false end
      elseif not (w and ((w.dps or 0) > 0 or (w.rangedDps or 0) > 0)) then
        return false
      end
    end
    return true, nil, nil, slots[1]
  end
  -- A worn piece not in the item cache would score 0: skip until it loads (cold login).
  local check = f.classID == 2 or f.equipLoc == "INVTYPE_SHIELD" or f.equipLoc == "INVTYPE_HOLDABLE"
    or f.equipLoc == "INVTYPE_RANGED" or f.equipLoc == "INVTYPE_RANGEDRIGHT"
  for _, slot in ipairs(check and { 16, 17, unpack(slots) } or slots) do
    local ref = WornRef(c, slot)
    if ref and not ItemFacts(ref) then
      if ns.RequestItemData then ns.RequestItemData(c.equipped[slot]) end
      return false
    end
  end

  local function Score(ref, offHand)
    if not ref then return 0, nil end
    if scoreFn then return scoreFn(ref, c, offHand) end
    local s, how = GS.ScoreItem(ref, c, offHand)
    if s then return s, how end
    local rf = ItemFacts(ref)
    return rf and rf.ilvl or 0, "ilvl"
  end

  local eq = f.equipLoc
  -- 2H Weapon: compare against worn MH + worn OH combined (so a staff must beat dagger + off-hand!).
  if eq == "INVTYPE_2HWEAPON" then
    local cand, how = Score(item, false)
    if not cand or cand <= 0 then return false end
    local mhRef, ohRef = WornRef(c, 16), WornRef(c, 17)
    local wornScore = Score(mhRef, false) + Score(ohRef, true)
    if cand > wornScore then return true, cand - wornScore, how, 16 end
    return false
  end

  -- 1H / Main-hand / Off-hand weapons.
  if eq == "INVTYPE_WEAPON" or eq == "INVTYPE_WEAPONMAINHAND" or eq == "INVTYPE_WEAPONOFFHAND" then
    local mhRef, ohRef = WornRef(c, 16), WornRef(c, 17)
    local mhFacts = mhRef and ItemFacts(mhRef)
    local wearing2H = mhFacts and mhFacts.equipLoc == "INVTYPE_2HWEAPON"
    local dwLvl = DUAL_WIELD_LEVEL[c.class]
    local canDW = dwLvl and c.level >= dwLvl and GS.GetSpec(c) ~= "protection"

    if eq == "INVTYPE_WEAPONOFFHAND" then
      if wearing2H or not canDW then return false end
      local cand, how = Score(item, true)
      if not cand or cand <= 0 then return false end
      local worn = Score(ohRef, true)
      if cand > worn then return true, cand - worn, how, 17 end
      return false
    end

    local candMH, how = Score(item, false)
    if not candMH or candMH <= 0 then return false end
    local wornMH = Score(mhRef, false)
    local bestGain, bestSlot = candMH - wornMH, 16

    if eq == "INVTYPE_WEAPON" and canDW and not wearing2H then
      local candOH = Score(item, true)
      local wornOH = Score(ohRef, true)
      if candOH and (candOH - wornOH) > bestGain then
        bestGain, bestSlot = candOH - wornOH, 17
      end
    end
    if bestGain > 0 then return true, bestGain, how, bestSlot end
    return false
  end

  -- Shield / Holdable Off-Hand: do not suggest while wearing a 2H weapon unless OH alone beats the 2H.
  if eq == "INVTYPE_SHIELD" or eq == "INVTYPE_HOLDABLE" then
    local cand, how = Score(item, true)
    if not cand or cand <= 0 then return false end
    local mhRef, ohRef = WornRef(c, 16), WornRef(c, 17)
    local mhFacts = mhRef and ItemFacts(mhRef)
    if mhFacts and mhFacts.equipLoc == "INVTYPE_2HWEAPON" then
      return false -- wearing a 2H weapon; don't push a solo off-hand
    end
    local worn = Score(ohRef, true)
    if cand > worn then return true, cand - worn, how, 17 end
    return false
  end

  -- Armor, Jewelry, Ranged / Wands.
  local cand, how = Score(item, false)
  if not cand or cand <= 0 then return false end
  local worst, worstSlot
  for _, slot in ipairs(slots) do
    local s = Score(WornRef(c, slot), false)
    if not worst or s < worst then worst, worstSlot = s, slot end
  end
  if cand > (worst or 0) then return true, cand - (worst or 0), how, worstSlot end
  return false
end

-- Enchants --------------------------------------------------------------------------------

-- DB2 quirk override: Enchant 2H Weapon - Grand Inquisitor (1232172) has 1H+2H mask in DB2.
local ENCHANT_SUB_OVERRIDE = {
  [1232172] = 1378, -- 2H weapons only
}

-- True when enchant `spell` can legally be applied to an item with (classID, invType, subClassID).
-- Checks classID, invTypeMask (when ~= 0), AND subClassMask (when ~= 0) so 2H enchants never
-- match 1H daggers and Shield enchants never match other armor slots!
function GS.EnchantMatchesItem(spell, classID, invType, subClassID)
  local es = ns.EnchantSlots and ns.EnchantSlots[spell]
  if not (es and classID and es[1] == classID) then return false end
  local invMask = es[2] or 0
  local subMask = ENCHANT_SUB_OVERRIDE[spell] or es[3] or 0
  if invMask ~= 0 and not (invType and Bit(invMask, invType)) then return false end
  if subMask ~= 0 and not (subClassID and Bit(subMask, subClassID)) then return false end
  return true
end

-- Combat stat vectors for Classic & Forever Enchanting spells (keyed by spellID).
-- Gathering, riding, stealth and pure-resist enchants are intentionally omitted (score 0).
local function AllStats(n) return { str = n, agi = n, sta = n, int = n, spi = n } end
GS.ENCHANT_STATS = {
  -- Bracer
  [7418] = { sta = 1 }, [7457] = { sta = 3 }, [13501] = { sta = 5 }, [13648] = { sta = 7 },
  [13945] = { sta = 9 }, [20011] = { sta = 12 },
  [7428] = { def = 1 }, [13646] = { def = 2 }, [13931] = { def = 3 }, [1248665] = { def = 5 },
  [7766] = { spi = 1 }, [7859] = { spi = 3 }, [13642] = { spi = 5 }, [13846] = { spi = 7 }, [20009] = { spi = 9 },
  [1248458] = { int = 1 }, [13622] = { int = 3 }, [13822] = { int = 5 }, [20008] = { int = 7 }, [1248661] = { int = 10 },
  [7779] = { agi = 1 }, [1248460] = { agi = 3 }, [1248497] = { agi = 5 }, [1248500] = { agi = 7 },
  [1248599] = { agi = 9 }, [1217203] = { agi = 9 },
  [7782] = { str = 1 }, [13536] = { str = 3 }, [13661] = { str = 5 }, [13939] = { str = 7 }, [20010] = { str = 9 },
  [23801] = { mp5 = 4 },
  [1248459] = { splheal = 6 }, [1248498] = { splheal = 12 }, [23802] = { splheal = 24 },
  [1217189] = { splpwr = 12 }, [1220624] = { splpwr = 15 },
  -- Chest
  [7420] = { sta = 1 }, [7748] = { sta = 3 }, [7857] = { sta = 5 }, [13640] = { sta = 7 },
  [13858] = { sta = 10 }, [20026] = { sta = 12 },
  [7426] = { sta = 1, armor = 10 }, [13538] = { sta = 2, armor = 20 }, [1249071] = { sta = 4, armor = 35 },
  [7443] = { int = 1 }, [7776] = { int = 3 }, [13607] = { int = 5 }, [13663] = { int = 7 },
  [13917] = { int = 9 }, [20028] = { int = 12 },
  [13626] = AllStats(1), [13700] = AllStats(2), [13941] = AllStats(3), [20025] = AllStats(4),
  [1213616] = AllStats(5), [435903] = { str = 4, splpwr = 8 },
  -- Cloak
  [7771] = { armor = 10 }, [13421] = { armor = 20 }, [13635] = { armor = 30 },
  [13746] = { armor = 50 }, [20015] = { armor = 70 },
  [13419] = { agi = 1 }, [13882] = { agi = 3 }, [1219587] = { agi = 5 },
  [25086] = { dodge = 1 },
  -- Boots
  [7863] = { sta = 1 }, [13644] = { sta = 3 }, [13836] = { sta = 5 }, [20020] = { sta = 7 },
  [7867] = { agi = 1 }, [13637] = { agi = 3 }, [13935] = { agi = 5 }, [20023] = { agi = 7 },
  [13687] = { spi = 3 }, [20024] = { spi = 5 },
  [13890] = { sta = 2, agi = 2, int = 2 }, [1328948] = { sta = 3, agi = 3, int = 3 },
  -- Gloves
  [13815] = { agi = 5 }, [20012] = { agi = 7 }, [25080] = { agi = 15 },
  [13887] = { str = 5 }, [20013] = { str = 7 }, [1248640] = { str = 10 },
  [13948] = { haste = 1 },
  [25072] = { def = 4, sta = 4 }, -- Threat (tanks)
  [25073] = { shasplpwr = 20 }, [25074] = { frosplpwr = 20 }, [25078] = { firsplpwr = 20 },
  [25079] = { splheal = 30 }, [1213622] = { holsplpwr = 20 }, [1213626] = { arcsplpwr = 20 },
  [1248645] = { natsplpwr = 20 }, [1294054] = { agi = 10, str = 10 },
  -- Shield
  [13378] = { sta = 1 }, [13631] = { sta = 3 }, [13817] = { sta = 5 }, [20017] = { sta = 7 }, [1219581] = { sta = 9 },
  [13464] = { armor = 30 }, [13689] = { blockPct = 2 },
  [13485] = { spi = 3 }, [13659] = { spi = 5 }, [13905] = { spi = 7 }, [20016] = { spi = 9 },
  [463871] = { splpwr = 15, splheal = 15 }, [1220623] = { crit = 1 },
  -- Off-Hand (Holdable - Forever)
  [1219577] = { int = 12 }, [1219578] = { spi = 12 }, [1219579] = { mp5 = 5, int = 6 },
  -- Necklace (Forever)
  [1249019] = { str = 5 }, [1249057] = { splpwr = 10 }, [1249058] = { splheal = 14 },
  [1249059] = { agi = 5 }, [1249060] = { def = 4 },
  -- 1H / Melee Weapons
  [7786] = { dps = 0.8 }, [13653] = { dps = 1.5 }, [13655] = { dps = 1.5 }, [13915] = { dps = 2.0 },
  [7788] = { dps = 0.5 }, [13503] = { dps = 1.0 }, [13693] = { dps = 1.5 }, [13943] = { dps = 2.0 },
  [20031] = { dps = 2.5 },
  [13898] = { dps = 3.2 }, [20029] = { dps = 1.8 }, [20032] = { dps = 3.5 }, [20033] = { dps = 3.0 },
  [20034] = { str = 45 }, [1231128] = { str = 55 }, [435481] = { dps = 3.0 },
  [23799] = { str = 15 }, [23800] = { agi = 15 },
  [21931] = { frosplpwr = 7 },
  [22749] = { splpwr = 30 }, [22750] = { splheal = 55 },
  [23803] = { spi = 20 }, [23804] = { int = 22 },
  [1231164] = { splpwr = 35 }, [1248757] = { int = 5 }, [1248760] = { spi = 5 }, [1248805] = { splpwr = 10 },
  -- 2H Weapons
  [7745] = { dps = 0.7 }, [13529] = { dps = 1.2 }, [13695] = { dps = 1.8 }, [13937] = { dps = 2.4 },
  [20030] = { dps = 3.2 },
  [7793] = { int = 3 }, [13380] = { spi = 3 }, [20035] = { spi = 9 }, [20036] = { int = 9 },
  [1248510] = { agi = 8 }, [1248511] = { str = 8 }, [1248668] = { str = 15 }, [27837] = { agi = 25 },
  [1219580] = { splpwr = 35 }, [1248607] = { splpwr = 45 }, [1248636] = { splheal = 70 },
  [1231139] = { splpwr = 45 }, [1232172] = { splpwr = 40, str = 20 },
}

-- Scores an enchanting recipe for character `c` using their spec weights (0 = unsuitable/utility).
function GS.ScoreEnchant(spell, c)
  local w = GS.WeightsFor(c)
  local st = GS.ENCHANT_STATS[spell]
  if not (w and st) then return 0 end
  local score = 0
  for k, v in pairs(st) do
    if w[k] then score = score + v * w[k] end
  end
  return score
end

-- Spec-matched combat consumables (Alchemy, Enchanting Oils, Cooking, Blacksmithing Stones).
-- [spellID] = { cat = "elixir"|"weapon"|"potion", minLvl, maxLvl, stats = { ... }, manaOnly?, rageOnly? }
GS.CONSUMABLES = {
  -- Spell & School Elixirs / Flasks
  [1245246] = { cat = "elixir", minLvl = 1,  maxLvl = 25, stats = { splpwr = 6 } },   -- Minor Arcane Elixir
  [1250791] = { cat = "elixir", minLvl = 15, maxLvl = 40, stats = { splpwr = 14 } },  -- Lesser Arcane Elixir
  [439960]  = { cat = "elixir", minLvl = 20, maxLvl = 45, stats = { splpwr = 14 } },  -- Lesser Arcane Elixir
  [7845]    = { cat = "elixir", minLvl = 20, maxLvl = 60, stats = { firsplpwr = 20 } }, -- Elixir of Fire Power
  [21923]   = { cat = "elixir", minLvl = 28, maxLvl = 60, stats = { frosplpwr = 25 } }, -- Elixir of Frost Power
  [11461]   = { cat = "elixir", minLvl = 35, maxLvl = 55, stats = { splpwr = 20 } },  -- Arcane Elixir
  [11476]   = { cat = "elixir", minLvl = 40, maxLvl = 60, stats = { shasplpwr = 40 } }, -- Elixir of Shadow Power
  [26277]   = { cat = "elixir", minLvl = 40, maxLvl = 60, stats = { holsplpwr = 35 } }, -- Elixir of Holy Power
  [1250792] = { cat = "elixir", minLvl = 45, maxLvl = 60, stats = { natsplpwr = 40 } }, -- Elixir of Nature Power
  [17573]   = { cat = "elixir", minLvl = 47, maxLvl = 60, stats = { splpwr = 35 } },  -- Greater Arcane Elixir
  [1213563] = { cat = "elixir", minLvl = 55, maxLvl = 60, stats = { splpwr = 45, crit = 1 } }, -- Elixir of the Mage-Lord
  [17637]   = { cat = "elixir", minLvl = 50, maxLvl = 60, stats = { splpwr = 150 } }, -- Flask of Supreme Power
  -- Healer / Mana Elixirs
  [3171]    = { cat = "elixir", minLvl = 10, maxLvl = 35, stats = { int = 6 } },      -- Elixir of Wisdom
  [1250801] = { cat = "elixir", minLvl = 15, maxLvl = 35, stats = { int = 10 } },     -- Elixir of Lesser Intellect
  [1250802] = { cat = "elixir", minLvl = 25, maxLvl = 48, stats = { int = 18 } },     -- Elixir of Intellect
  [11465]   = { cat = "elixir", minLvl = 37, maxLvl = 60, stats = { int = 25 } },     -- Elixir of Greater Intellect
  [1250779] = { cat = "elixir", minLvl = 5,  maxLvl = 25, stats = { splheal = 12 } }, -- Minor Cleric's Elixir
  [1250780] = { cat = "elixir", minLvl = 15, maxLvl = 35, stats = { splheal = 22 } }, -- Lesser Cleric's Elixir
  [1250781] = { cat = "elixir", minLvl = 25, maxLvl = 45, stats = { splheal = 35 } }, -- Cleric's Elixir
  [1250782] = { cat = "elixir", minLvl = 35, maxLvl = 60, stats = { splheal = 50 } }, -- Greater Cleric's Elixir
  [1250788] = { cat = "elixir", minLvl = 5,  maxLvl = 25, stats = { mp5 = 4 } },      -- Minor Mageblood Elixir
  [1250789] = { cat = "elixir", minLvl = 15, maxLvl = 40, stats = { mp5 = 8 } },      -- Lesser Mageblood Elixir
  [1250790] = { cat = "elixir", minLvl = 30, maxLvl = 55, stats = { mp5 = 12 } },     -- Greater Mageblood Elixir
  [24365]   = { cat = "elixir", minLvl = 40, maxLvl = 60, stats = { mp5 = 15 } },     -- Mageblood Elixir
  [17555]   = { cat = "elixir", minLvl = 45, maxLvl = 60, stats = { int = 18, spi = 18 } }, -- Elixir of the Sages
  -- Physical / Melee / Hunter / Tank Elixirs
  [2329]    = { cat = "elixir", minLvl = 1,  maxLvl = 22, stats = { str = 4 } },      -- Elixir of Minor Strength
  [3230]    = { cat = "elixir", minLvl = 2,  maxLvl = 22, stats = { agi = 4 } },      -- Elixir of Minor Agility
  [8240]    = { cat = "elixir", minLvl = 8,  maxLvl = 35, stats = { str = 8 } },      -- Elixir of Giant Growth
  [3390]    = { cat = "elixir", minLvl = 18, maxLvl = 40, stats = { agi = 8 } },      -- (spell 2333 below)
  [2333]    = { cat = "elixir", minLvl = 18, maxLvl = 40, stats = { agi = 8 } },      -- Elixir of Lesser Agility
  [3188]    = { cat = "elixir", minLvl = 20, maxLvl = 45, stats = { str = 8 } },      -- Elixir of Ogre Strength
  [1250798] = { cat = "elixir", minLvl = 22, maxLvl = 48, stats = { str = 14 } },     -- Elixir of Strength
  [11449]   = { cat = "elixir", minLvl = 27, maxLvl = 50, stats = { agi = 15 } },     -- Elixir of Agility
  [11467]   = { cat = "elixir", minLvl = 38, maxLvl = 60, stats = { agi = 25 } },     -- Elixir of Greater Agility
  [11472]   = { cat = "elixir", minLvl = 40, maxLvl = 60, stats = { str = 25 } },     -- Elixir of Greater Strength
  [17557]   = { cat = "elixir", minLvl = 45, maxLvl = 60, stats = { str = 18, sta = 18 } }, -- Elixir of Brute Force
  [17571]   = { cat = "elixir", minLvl = 46, maxLvl = 60, stats = { agi = 25, crit = 2 } }, -- Elixir of the Mongoose
  [1250799] = { cat = "elixir", minLvl = 45, maxLvl = 60, stats = { atkpwr = 45, crit = 1 } }, -- Elixir of Ferocity
  [1213559] = { cat = "elixir", minLvl = 55, maxLvl = 60, stats = { agi = 30, str = 20 } }, -- Elixir of the Honey Badger
  [2334]    = { cat = "elixir", minLvl = 2,  maxLvl = 25, stats = { sta = 4 } },      -- Elixir of Minor Fortitude
  [7183]    = { cat = "elixir", minLvl = 1,  maxLvl = 25, stats = { armor = 50 } },   -- Elixir of Minor Defense
  [3177]    = { cat = "elixir", minLvl = 18, maxLvl = 42, stats = { armor = 150 } },  -- Elixir of Lesser Defense
  [3450]    = { cat = "elixir", minLvl = 25, maxLvl = 50, stats = { sta = 12 } },     -- Elixir of Lesser Fortitude
  [11450]   = { cat = "elixir", minLvl = 28, maxLvl = 52, stats = { armor = 250 } },  -- Elixir of Defense
  [17554]   = { cat = "elixir", minLvl = 43, maxLvl = 60, stats = { armor = 450 } },  -- Elixir of Greater Defense
  [1213565] = { cat = "elixir", minLvl = 55, maxLvl = 60, stats = { sta = 25, armor = 500 } }, -- Elixir of the Ironside
  [17635]   = { cat = "elixir", minLvl = 50, maxLvl = 60, stats = { sta = 120 } },    -- Flask of the Titans
  -- Weapon Oils & Sharpening Stones
  [25124]   = { cat = "weapon", minLvl = 5,  maxLvl = 32, stats = { splpwr = 8 } },   -- Minor Wizard Oil
  [25126]   = { cat = "weapon", minLvl = 30, maxLvl = 48, stats = { splpwr = 16 } },  -- Lesser Wizard Oil
  [25128]   = { cat = "weapon", minLvl = 45, maxLvl = 58, stats = { splpwr = 24 } },  -- Wizard Oil
  [25129]   = { cat = "weapon", minLvl = 50, maxLvl = 60, stats = { splpwr = 36, crit = 1 } }, -- Brilliant Wizard Oil
  [25125]   = { cat = "weapon", minLvl = 20, maxLvl = 42, stats = { mp5 = 4 } },      -- Minor Mana Oil
  [25127]   = { cat = "weapon", minLvl = 40, maxLvl = 56, stats = { mp5 = 8 } },      -- Lesser Mana Oil
  [25130]   = { cat = "weapon", minLvl = 50, maxLvl = 60, stats = { mp5 = 12, splheal = 25 } }, -- Brilliant Mana Oil
  [2660]    = { cat = "weapon", minLvl = 1,  maxLvl = 18, stats = { dps = 0.8 } },    -- Rough Sharpening Stone
  [2665]    = { cat = "weapon", minLvl = 5,  maxLvl = 28, stats = { dps = 1.2 } },    -- Coarse Sharpening Stone
  [2674]    = { cat = "weapon", minLvl = 15, maxLvl = 38, stats = { dps = 1.8 } },    -- Heavy Sharpening Stone
  [9918]    = { cat = "weapon", minLvl = 25, maxLvl = 48, stats = { dps = 2.6 } },    -- Solid Sharpening Stone
  [16641]   = { cat = "weapon", minLvl = 35, maxLvl = 60, stats = { dps = 3.5 } },    -- Dense Sharpening Stone
  [22757]   = { cat = "weapon", minLvl = 50, maxLvl = 60, stats = { crit = 2 } },     -- Elemental Sharpening Stone
  -- Potions & Buff Food
  [2331]    = { cat = "potion", minLvl = 5,  maxLvl = 20, stats = { mp5 = 3, int = 3 } }, -- Minor Mana Potion
  [3173]    = { cat = "potion", minLvl = 14, maxLvl = 30, stats = { mp5 = 5, int = 5 } }, -- Lesser Mana Potion
  [3452]    = { cat = "potion", minLvl = 22, maxLvl = 40, stats = { mp5 = 8, int = 8 } }, -- Mana Potion
  [11448]   = { cat = "potion", minLvl = 31, maxLvl = 48, stats = { mp5 = 11, int = 11 } }, -- Greater Mana Potion
  [17553]   = { cat = "potion", minLvl = 41, maxLvl = 56, stats = { mp5 = 15, int = 15 } }, -- Superior Mana Potion
  [17580]   = { cat = "potion", minLvl = 49, maxLvl = 60, stats = { mp5 = 22, int = 22 } }, -- Major Mana Potion
  [25704]   = { cat = "potion", minLvl = 10, maxLvl = 35, stats = { mp5 = 4 } },      -- Smoked Sagefish
  [25954]   = { cat = "potion", minLvl = 30, maxLvl = 52, stats = { mp5 = 6 } },      -- Sagefish Delight
  [18243]   = { cat = "potion", minLvl = 35, maxLvl = 60, stats = { mp5 = 9 } },      -- Nightfin Soup
  [6617]    = { cat = "potion", minLvl = 4,  maxLvl = 30, stats = { atkpwr = 12 }, classes = { WARRIOR = true } }, -- Rage Potion
  [6618]    = { cat = "potion", minLvl = 25, maxLvl = 50, stats = { atkpwr = 25 }, classes = { WARRIOR = true } }, -- Great Rage Potion
  [17552]   = { cat = "potion", minLvl = 46, maxLvl = 60, stats = { str = 30 }, classes = { WARRIOR = true } }, -- Mighty Rage Potion
  [1251729] = { cat = "potion", minLvl = 5,  maxLvl = 22, stats = { splpwr = 12 } },  -- Minor Spellblasting Potion
  [1251730] = { cat = "potion", minLvl = 15, maxLvl = 32, stats = { splpwr = 22 } },  -- Lesser Spellblasting Potion
  [1251731] = { cat = "potion", minLvl = 25, maxLvl = 42, stats = { splpwr = 34 } },  -- Spellblasting Potion
  [1251732] = { cat = "potion", minLvl = 35, maxLvl = 52, stats = { splpwr = 48 } },  -- Greater Spellblasting Potion
  [1251733] = { cat = "potion", minLvl = 45, maxLvl = 58, stats = { splpwr = 65 } },  -- Superior Spellblasting Potion
  [1251734] = { cat = "potion", minLvl = 52, maxLvl = 60, stats = { splpwr = 85 } },  -- Major Spellblasting Potion
  [1251735] = { cat = "potion", minLvl = 5,  maxLvl = 22, stats = { atkpwr = 18 } },  -- Minor Frenzy Potion
  [1251736] = { cat = "potion", minLvl = 15, maxLvl = 32, stats = { atkpwr = 32 } },  -- Lesser Frenzy Potion
  [1251737] = { cat = "potion", minLvl = 25, maxLvl = 42, stats = { atkpwr = 50 } },  -- Frenzy Potion
  [1251738] = { cat = "potion", minLvl = 35, maxLvl = 52, stats = { atkpwr = 70 } },  -- Greater Frenzy Potion
  [1251739] = { cat = "potion", minLvl = 45, maxLvl = 58, stats = { atkpwr = 95 } },  -- Superior Frenzy Potion
  [1251740] = { cat = "potion", minLvl = 52, maxLvl = 60, stats = { atkpwr = 120 } }, -- Major Frenzy Potion
  [1251741] = { cat = "potion", minLvl = 5,  maxLvl = 22, stats = { splheal = 16 } }, -- Minor Mender's Potion
  [1251742] = { cat = "potion", minLvl = 15, maxLvl = 32, stats = { splheal = 28 } }, -- Lesser Mender's Potion
  [1251743] = { cat = "potion", minLvl = 25, maxLvl = 42, stats = { splheal = 45 } }, -- Mender's Potion
  [1251744] = { cat = "potion", minLvl = 35, maxLvl = 52, stats = { splheal = 65 } }, -- Greater Mender's Potion
  [1251745] = { cat = "potion", minLvl = 45, maxLvl = 58, stats = { splheal = 90 } }, -- Superior Mender's Potion
  [1251747] = { cat = "potion", minLvl = 52, maxLvl = 60, stats = { splheal = 120 } }, -- Major Mender's Potion
}

-- Scores a craftable consumable spell for character `c` (0 if wrong level/class/spec).
function GS.ScoreConsumable(spell, c)
  local cons = GS.CONSUMABLES[spell]
  local w = GS.WeightsFor(c)
  if not (cons and w and c and c.level) then return 0 end
  if c.level < cons.minLvl or c.level > cons.maxLvl then return 0 end
  if cons.classes and not cons.classes[c.class] then return 0 end
  local score = 0
  for k, v in pairs(cons.stats) do
    if w[k] then score = score + v * w[k] end
  end
  return score, cons.cat
end

-- /comrade spec [name|auto]: set or show the active spec override for upgrade scoring.
ns.commands.spec = function(arg)
  local key = ns.CharKey()
  local c = ns.CharData()
  if not (c and c.class and GS.SPECS[c.class]) then return end
  arg = (arg or ""):match("^%s*(.-)%s*$")
  if arg == "" then
    local cur = GS.GetSpec(c)
    ns.Print(L["Spec: %s"]:format(GS.SpecLabel(cur)))
    return
  end
  local picked = GS.SetSpec(key, arg)
  if picked then
    ns.Print(L["Spec set to %s."]:format(GS.SpecLabel(picked)))
  else
    local names = {}
    for _, s in ipairs(GS.SPECS[c.class]) do names[#names + 1] = s end
    ns.Print(L["Unknown spec. Available: %s"]:format(table.concat(names, ", ")))
  end
end
