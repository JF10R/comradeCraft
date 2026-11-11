-- SkillLog: records every craft (rank, color, skill gained) to measure Forever's real
-- skill-up chances, and calibrates ns.SkillUpChance once a color has enough samples.
local _, ns = ...
local Print = ns.Print

local MAX_RAW = 2000      -- raw samples kept (oldest dropped)
local MIN_SAMPLES = 50    -- crafts per color before calibration replaces the Classic formula
local SETTLE = 2          -- seconds to wait for the skill update when no next craft comes

local GAME_COLOR = { [0] = "orange", [1] = "yellow", [2] = "green", [3] = "grey",
  optimal = "orange", medium = "yellow", easy = "green", trivial = "grey" }

-- Live rank of a skill line, read from the profession API (nil if not found).
local function LiveRank(line)
  if not (GetProfessions and GetProfessionInfo) then return nil end
  for _, idx in pairs({ GetProfessions() }) do
    if idx then
      local _, _, rank, _, _, _, skillLine = GetProfessionInfo(idx)
      if skillLine == line then return rank end
    end
  end
end
ns.LiveRank = LiveRank

local function DB()
  local s = ComradeCraftDB.skillups
  if not s then
    s = { raw = {}, colors = {} }
    ComradeCraftDB.skillups = s
  end
  return s
end

-- Pure: adds one finished sample to the aggregate tables.
function ns.RecordSample(s, sample)
  local raw = s.raw
  raw[#raw + 1] = sample
  if #raw > MAX_RAW then table.remove(raw, 1) end
  local c = s.colors[sample.color]
  if not c then
    c = { n = 0, gained = 0, expected = 0 }
    s.colors[sample.color] = c
  end
  c.n = c.n + 1
  c.gained = c.gained + (sample.gain > 0 and 1 or 0)
  c.expected = c.expected + sample.expected
end

local pending -- the last craft, waiting for its skill update

local function Finish(rankAfter)
  local p = pending
  pending = nil
  if not p then return end
  rankAfter = rankAfter or LiveRank(p.line)
  if not rankAfter or rankAfter < p.rank then return end -- unlearned/reset: drop it
  local gain = rankAfter - p.rank
  ns.RecordSample(DB(), {
    spell = p.spell, rank = p.rank, gain = gain, color = p.color,
    game = p.game, lpdb = p.lpdb, expected = p.expected, t = p.t,
  })
end
ns.FinishPendingCraft = Finish

function ns.OnCraft(spell)
  local r = ns.Recipes and ns.Recipes[spell]
  if not r then return end
  local line = r[1]
  local rank = LiveRank(line)
  -- The rank before this craft is the rank after the previous craft of the same line.
  if pending then Finish(pending.line == line and rank or nil) end
  if not rank then return end
  local game
  if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
    local info = C_TradeSkillUI.GetRecipeInfo(spell)
    game = info and GAME_COLOR[info.relativeDifficulty]
  end
  pending = {
    spell = spell, line = line, rank = rank, t = time(),
    color = ns.RecipeColor(spell, rank),
    lpdb = ns.LPDBColor and ns.LPDBColor(spell, rank),
    game = game,
    expected = ns.FormulaChance(spell, rank),
  }
  local mine = pending
  if C_Timer then
    C_Timer.After(SETTLE, function() if pending == mine then Finish() end end)
  end
end

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spell)
  if unit == "player" then ns.OnCraft(spell) end
end)

-- Totals for a color: this account's crafts plus those shared by players in the group.
function ns.SkillupTotals(color)
  local n, gained, expected = 0, 0, 0
  local s = ComradeCraftDB and ComradeCraftDB.skillups
  local c = s and s.colors[color]
  if c then n, gained, expected = c.n, c.gained, c.expected end
  for _, peer in pairs(ComradeCraftDB and ComradeCraftDB.peers or {}) do
    local p = peer.included and peer.skillups and peer.skillups[color]
    if p then n, gained, expected = n + p.n, gained + p.gained, expected + p.expected end
  end
  return n, gained, expected
end

-- Calibration factor per color: observed skill-ups / formula expectation (group-wide).
function ns.Calibration(color)
  local n, gained, expected = ns.SkillupTotals(color)
  if n < MIN_SAMPLES or expected <= 0 then return nil end
  return gained / expected
end

ns.commands.stats = function()
  local s = DB()
  Print(ns.L["%d crafts recorded (calibration from %d per color)"]:format(#s.raw, MIN_SAMPLES))
  for _, color in ipairs({ "orange", "yellow", "green", "grey" }) do
    local n, gained, expected = ns.SkillupTotals(color) -- includes players in the group
    if n > 0 then
      local f = ns.Calibration(color)
      Print(ns.L["  %s: %d crafts, %d points, Classic formula %.1f%s"]:format(ns.L[color], n, gained, expected,
        f and ns.L[" -> factor %.2f applied"]:format(f) or ""))
    end
  end
  local seen, ours, lp = 0, 0, 0
  for _, x in ipairs(s.raw) do
    if x.game then
      seen = seen + 1
      if x.game == x.color then ours = ours + 1 end
      if x.game == x.lpdb then lp = lp + 1 end
    end
  end
  if seen > 0 then
    Print(ns.L["  game color known on %d crafts: our table %d right, LibProfessionDB %d right"]
      :format(seen, ours, lp))
  end
end
