-- Locale: English is the key and the default; other client languages override below.
-- tools/check_lua.py fails if a key used in the code has no frFR translation.
local _, ns = ...

local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L

local translations = {
  frFR = {
    -- Core
    ["commands: /comrade (window) | scan | needs | stats | dump | api | audit | log clear"] =
      "commandes : /comrade (fenêtre) | scan | needs | stats | dump | api | audit | log clear",
    ["log cleared"] = "log vidé",
    ["%d lines in the log (written to disk on /reload or logout)"] =
      "%d lignes dans le log (écrit sur disque au /reload ou à la déconnexion)",
    -- Scan
    ["scan ok: %d distinct items in bags"] = "scan ok : %d objets distincts dans les sacs",
    ["DevTools_Dump missing; see WTF\\...\\SavedVariables\\ComradeCraft.lua after /reload"] =
      "DevTools_Dump absent; voir WTF\\...\\SavedVariables\\ComradeCraft.lua après /reload",
    ["audit: C_TradeSkillUI.GetAllRecipeIDs missing on this client"] =
      "audit : C_TradeSkillUI.GetAllRecipeIDs absent sur ce client",
    ["audit: open a profession window first"] = "audit : ouvre une fenêtre de profession d'abord",
    ["  %s (%d): game=%s table=%s [%d/%d]"] = "  %s (%d) : jeu=%s table=%s [%d/%d]",
    ["audit rank %d: %d ok, %d mismatches, %d missing from the table"] =
      "audit rang %d : %d ok, %d écarts, %d absentes de la table",
    ["LibProfessionDB: %d ok, %d mismatches"] = "LibProfessionDB : %d ok, %d écarts",
    ["maxTrivialLevel == grey: %d yes, %d no"] = "maxTrivialLevel == gris : %d oui, %d non",
    ["yes"] = "oui",
    ["no"] = "non",
    -- SkillLog
    ["%d crafts recorded (calibration from %d per color)"] =
      "%d crafts enregistrés (calibrage à partir de %d par couleur)",
    ["orange"] = "orange",
    ["yellow"] = "jaune",
    ["green"] = "vert",
    ["grey"] = "gris",
    ["  %s: %d crafts, %d points, Classic formula %.1f%s"] =
      "  %s : %d crafts, %d points, formule Classic %.1f%s",
    [" -> factor %.2f applied"] = " -> facteur %.2f appliqué",
    ["  game color known on %d crafts: our table %d right, LibProfessionDB %d right"] =
      "  couleur du jeu connue sur %d crafts : notre table %d bonnes, LibProfessionDB %d bonnes",
    -- Tooltip / needs text
    ["needs %d"] = "besoin de %d",
    ["Group total"] = "Total du groupe",
    ["trainer"] = "formateur",
    ["vendor"] = "vendeur",
    ["quest"] = "quête",
    ["drop"] = "drop",
    ["container"] = "coffre",
    ["Gathering profession: levels by gathering, not crafting."] =
      "Profession de récolte : monte en récoltant, pas en craftant.",
    ["Open this profession's window once so your recipes can be read."] =
      "Ouvre la fenêtre de cette profession une fois pour lire tes recettes.",
    ["At the cap (%d). Visit the trainer for the next rank."] =
      "Au maximum du palier (%d). Va voir le formateur pour le palier suivant.",
    ["No data."] = "Aucune donnée.",
    ["Learn %s at the trainer (skill %s, %s)"] = "Aller apprendre %s au formateur (skill %s, %s)",
    ["cost unknown until you visit the trainer"] = "coût inconnu tant que tu n'as pas ouvert le formateur",
    ["Craft %d %s (%s)"] = "Crafte %d %s (%s)",
    ["Craft %dx %s (%s)"] = "Crafte %dx %s (%s)",
    ["%d %s (vendor)"] = "%d %s (vendeur)",
    [" + %d from stock"] = " + %d déjà en stock",
    ["%d %s from stock"] = "%d %s déjà en stock",
    ["With only your current recipes, you would be stuck at %d."] =
      "Avec seulement tes recettes actuelles, tu bloquerais à %d.",
    ["Uses what you already have: %s."] = "Utilise ce que tu as déjà : %s.",
    ["Buy from a vendor: %s."] = "À acheter chez un vendeur : %s.",
    ["Stuck at %d: all your known recipes are grey (no more points)."] =
      "Bloqué à %d : toutes tes recettes connues sont grises (plus aucun point).",
    ["Stuck at %d: your known recipes barely give points anymore (%d%% chance per craft at best, %d%% needed)."] =
      "Bloqué à %d : tes recettes connues ne donnent presque plus de points (%d%% de chance par craft au mieux, il en faut %d%%).",
    [" To learn: %s."] = " À apprendre : %s.",
    [" No recipe to learn found within the next 25 points."] =
      " Aucune recette à apprendre trouvée dans les 25 prochains points.",
    ["  missing %s x%d"] = "  manque %s x%d",
    -- UI
    ["just now"] = "à l'instant",
    ["%d min ago"] = "il y a %d min",
    ["%d h ago"] = "il y a %d h",
    ["What to craft:"] = "Quoi crafter :",
    ["Owned: %d / %d"] = "Possédé : %d / %d",
    ["%d profession"] = "%d profession",
    ["%d professions"] = "%d professions",
    ["%d member"] = "%d membre",
    ["%d members"] = "%d membres",
    ["Group needs"] = "Besoins du groupe",
    ["Materials missing to reach the current cap (character's own stock deducted)."] =
      "Matériaux manquants pour atteindre le palier actuel (stock du perso déduit).",
    ["No data yet. Open your profession windows, then /comrade."] =
      "Aucune donnée. Ouvre tes fenêtres de profession puis /comrade.",
    ["Local data (characters on this account). skill ~N: value taken from Classic, unconfirmed."] =
      "Données locales (persos de ce compte). skill ~N : valeur reprise de Classic, non confirmée.",
    ["Click: group needs"] = "Clic : besoins du groupe",
  },
}
ns.Translations = translations

local t = translations[GetLocale and GetLocale() or "enUS"]
if t then
  for k, v in pairs(t) do rawset(L, k, v) end
end

-- "%d member(s)": picks the singular or plural key.
function ns.Plural(n, one, many)
  return (n == 1 and L[one] or L[many]):format(n)
end
