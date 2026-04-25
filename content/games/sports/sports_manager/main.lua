--[[
  Sports Manager — Lurek2D
  Category: sports

  Team soccer management sim: roster, training, transfers, automated
  match simulation with play-by-play, and a 14-week round-robin league.
]]

-- Constants
local SCREEN_W = 800
local SCREEN_H = 600
local TEAM_SIZE = 11
local ROSTER_SIZE = 16
local LEAGUE_TEAMS = 8
local SEASON_WEEKS = 14
local MATCH_DURATION = 5.0
local INJURY_CHANCE = 0.05
local START_BUDGET = 1000
local WIN_GOLD = 50
local DRAW_GOLD = 20
local STAMINA_PER_MATCH = 20
local LOW_STAMINA_THRESHOLD = 30
local POSITIONS = { "GK", "DEF", "DEF", "DEF", "DEF", "MID", "MID", "MID", "FWD", "FWD", "FWD" }
local POS_COLORS = {
  GK  = {0.3, 0.8, 0.3},
  DEF = {0.3, 0.5, 0.9},
  MID = {0.9, 0.7, 0.2},
  FWD = {0.9, 0.3, 0.3},
}

-- States
local STATE_TITLE    = "TITLE"
local STATE_OFFICE   = "OFFICE"
local STATE_ROSTER   = "ROSTER"
local STATE_MATCH    = "MATCH"
local STATE_TRAINING = "TRAINING"
local STATE_TRANSFER = "TRANSFER"
local STATE_SEASON_END = "SEASON_END"

-- Name pools
local FIRST_NAMES = {
  "Alex", "Bruno", "Carlos", "Diego", "Erik", "Felix", "Goran", "Hugo",
  "Ivan", "Jens", "Karim", "Leo", "Marco", "Niko", "Oscar", "Pablo",
  "Rafa", "Sami", "Tomas", "Udo", "Victor", "Werner", "Xavi", "Yuri",
  "Andre", "Boris", "Cesar", "Dario", "Emil", "Franz", "Gregor", "Hector",
}
local LAST_NAMES = {
  "Silva", "Muller", "Rossi", "Garcia", "Park", "Jensen", "Petrov", "Santos",
  "Novak", "Tanaka", "Fischer", "Costa", "Nilsen", "Kim", "Fernandez", "Weber",
  "Ali", "Duval", "Berg", "Torres", "Kovac", "Reyes", "Bakker", "Mori",
  "Cruz", "Varga", "Lund", "Alonso", "Bauer", "Diaz", "Holm", "Patel",
}
local TEAM_NAMES = {
  "FC Lurek", "Red Lions", "Blue Eagles", "Green Vipers",
  "Golden Stars", "Iron Wolves", "Thunder FC", "Shadow United",
}

-- Helpers
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function lerp(a, b, t) return a + (b - a) * clamp(t, 0, 1) end

local function gen_name()
  return FIRST_NAMES[math.random(#FIRST_NAMES)] .. " " .. LAST_NAMES[math.random(#LAST_NAMES)]
end

local function gen_player(pos_hint)
  local pos = pos_hint or POSITIONS[math.random(#POSITIONS)]
  return {
    name = gen_name(),
    pos = pos,
    skill = math.random(30, 90),
    stamina = math.random(50, 100),
    morale = math.random(50, 100),
    starter = false,
    injured = 0,   -- weeks remaining
  }
end

local function team_avg_skill(players)
  local sum, n = 0, 0
  for _, p in ipairs(players) do
    if p.starter and p.injured == 0 then
      local eff = p.skill
      if p.stamina < LOW_STAMINA_THRESHOLD then eff = eff * 0.6 end
      sum = sum + eff
      n = n + 1
    end
  end
  return n > 0 and (sum / n) or 30
end

-- Game state
local state = STATE_TITLE
local dt = 0
local my_team_index = 1
local budget = START_BUDGET
local week = 1
local roster = {}
local league = {}
local schedule = {}
local match_timer = 0
local match_events = {}
local match_score = {0, 0}
local match_opponent = ""
local match_event_timer = 0
local match_event_index = 0
local market = {}
local training_done = false
local season_result = ""
local title_blink = 0

-- Particles (manual lightweight system)
local goal_particles = {}
local train_particles = {}
local transfer_particles = {}

-- Tweens (manual lightweight)
local tweens = {}

local function add_tween(target, field, from, to, dur)
  table.insert(tweens, { target = target, field = field, from = from, to = to, dur = dur, t = 0 })
end

local function update_tweens(delta)
  local i = 1
  while i <= #tweens do
    local tw = tweens[i]
    tw.t = tw.t + delta
    local p = clamp(tw.t / tw.dur, 0, 1)
    -- ease out quad
    local ep = 1 - (1 - p) * (1 - p)
    tw.target[tw.field] = lerp(tw.from, tw.to, ep)
    if tw.t >= tw.dur then
      tw.target[tw.field] = tw.to
      table.remove(tweens, i)
    else
      i = i + 1
    end
  end
end

local function spawn_goal_particles(x, y, count)
  for _ = 1, count do
    table.insert(goal_particles, {
      x = x, y = y,
      vx = (math.random() - 0.5) * 200,
      vy = -math.random() * 150 - 50,
      life = 1.0 + math.random() * 0.5,
      r = 1.0, g = 0.85, b = 0.0,
      size = 3 + math.random() * 4,
    })
  end
end

local function spawn_train_particles(x, y, count)
  for _ = 1, count do
    table.insert(train_particles, {
      x = x + (math.random() - 0.5) * 100,
      y = y + (math.random() - 0.5) * 40,
      vx = (math.random() - 0.5) * 30,
      vy = -math.random() * 40 - 10,
      life = 0.6 + math.random() * 0.4,
      size = 2 + math.random() * 2,
    })
  end
end

local function spawn_transfer_particles(x, y, count)
  for _ = 1, count do
    table.insert(transfer_particles, {
      x = x + (math.random() - 0.5) * 60,
      y = y + (math.random() - 0.5) * 30,
      vx = (math.random() - 0.5) * 80,
      vy = -math.random() * 60 - 20,
      life = 0.8 + math.random() * 0.4,
      size = 2 + math.random() * 3,
      r = 1.0, g = 0.95, b = 0.5,
    })
  end
end

local function update_particles(list, delta)
  local i = 1
  while i <= #list do
    local p = list[i]
    p.x = p.x + p.vx * delta
    p.y = p.y + p.vy * delta
    p.vy = p.vy + 120 * delta  -- gravity
    p.life = p.life - delta
    if p.life <= 0 then
      table.remove(list, i)
    else
      i = i + 1
    end
  end
end

-- Score display tween targets
local score_display = { home = 0, away = 0 }
local morale_bars = {}

-- League init
local function init_league()
  league = {}
  for i = 1, LEAGUE_TEAMS do
    league[i] = {
      name = TEAM_NAMES[i],
      w = 0, d = 0, l = 0,
      gf = 0, ga = 0, pts = 0,
      skill = (i == my_team_index) and 0 or (40 + math.random(30)),
      display_pts = 0,
    }
  end
end

local function init_schedule()
  schedule = {}
  -- simple round-robin: each team plays each other once at home, once away = 14 weeks
  local teams_idx = {}
  for i = 1, LEAGUE_TEAMS do teams_idx[i] = i end
  -- generate 14 rounds using circle method
  local n = LEAGUE_TEAMS
  local fixed = teams_idx[1]
  local rotating = {}
  for i = 2, n do rotating[i - 1] = teams_idx[i] end
  for round = 1, SEASON_WEEKS do
    local round_matches = {}
    local current = { fixed }
    for _, v in ipairs(rotating) do table.insert(current, v) end
    local half = n / 2
    for m = 1, half do
      local home = current[m]
      local away = current[n + 1 - m]
      if round > n - 1 then home, away = away, home end
      table.insert(round_matches, { home = home, away = away })
    end
    schedule[round] = round_matches
    -- rotate
    local last = table.remove(rotating)
    table.insert(rotating, 1, last)
  end
end

local function refresh_market()
  market = {}
  for i = 1, 3 do
    local p = gen_player()
    p.price = math.floor(100 + (p.skill - 30) * (400 / 60))
    market[i] = p
  end
end

local function count_starters()
  local n = 0
  for _, p in ipairs(roster) do
    if p.starter and p.injured == 0 then n = n + 1 end
  end
  return n
end

local function auto_fill_starters()
  -- ensure exactly 11 starters among healthy players
  local starters = 0
  for _, p in ipairs(roster) do
    if p.injured > 0 then p.starter = false end
    if p.starter then starters = starters + 1 end
  end
  if starters < TEAM_SIZE then
    for _, p in ipairs(roster) do
      if not p.starter and p.injured == 0 and starters < TEAM_SIZE then
        p.starter = true
        starters = starters + 1
      end
    end
  end
end

local function simulate_match()
  match_events = {}
  match_score = {0, 0}
  score_display.home = 0
  score_display.away = 0
  match_timer = 0
  match_event_index = 0
  match_event_timer = 0

  auto_fill_starters()
  local my_skill = team_avg_skill(roster)
  -- find opponent
  local opp_skill = 50
  local opp_name = "Opponent"
  local round = schedule[week]
  if round then
    for _, m in ipairs(round) do
      if m.home == my_team_index then
        opp_skill = league[m.away].skill
        opp_name = league[m.away].name
      elseif m.away == my_team_index then
        opp_skill = league[m.home].skill
        opp_name = league[m.home].name
      end
    end
  end
  match_opponent = opp_name

  -- generate events
  local skill_diff = my_skill - opp_skill
  local my_goals = 0
  local opp_goals = 0

  -- 6 event slots over the match
  for slot = 1, 6 do
    local roll = math.random(100)
    local my_chance = 30 + skill_diff * 0.3
    local opp_chance = 30 - skill_diff * 0.3

    if roll <= my_chance then
      my_goals = my_goals + 1
      local scorer = "Player"
      for _, p in ipairs(roster) do
        if p.starter and p.injured == 0 then scorer = p.name; break end
      end
      -- pick a random starter
      local starters_list = {}
      for _, p in ipairs(roster) do
        if p.starter and p.injured == 0 then table.insert(starters_list, p) end
      end
      if #starters_list > 0 then
        scorer = starters_list[math.random(#starters_list)].name
      end
      table.insert(match_events, {
        time = slot * 15, text = scorer .. " scores! GOAL!", type = "goal_home",
      })
    elseif roll <= my_chance + opp_chance then
      opp_goals = opp_goals + 1
      table.insert(match_events, {
        time = slot * 15, text = gen_name() .. " scores for " .. opp_name .. "!", type = "goal_away",
      })
    elseif roll <= my_chance + opp_chance + 5 then
      table.insert(match_events, {
        time = slot * 15, text = "Red card! A player is sent off!", type = "red_card",
      })
    else
      local saves = {
        "Great save by the keeper!", "Shot goes wide!", "Blocked on the line!",
        "Corner kick cleared!", "Free kick hits the wall!",
      }
      table.insert(match_events, {
        time = slot * 15, text = saves[math.random(#saves)], type = "save",
      })
    end
  end

  match_score = { my_goals, opp_goals }

  -- injuries
  for _, p in ipairs(roster) do
    if p.starter and p.injured == 0 and math.random() < INJURY_CHANCE then
      p.injured = 3
      table.insert(match_events, {
        time = 80 + math.random(10), text = "INJURY! " .. p.name .. " is out for 3 weeks!", type = "injury",
      })
    end
  end

  -- stamina depletion
  for _, p in ipairs(roster) do
    if p.starter and p.injured == 0 then
      p.stamina = clamp(p.stamina - STAMINA_PER_MATCH, 0, 100)
    end
  end

  -- update league for our match
  local my = league[my_team_index]
  my.gf = my.gf + my_goals
  my.ga = my.ga + opp_goals
  if my_goals > opp_goals then
    my.w = my.w + 1; my.pts = my.pts + 3
    budget = budget + WIN_GOLD
  elseif my_goals == opp_goals then
    my.d = my.d + 1; my.pts = my.pts + 1
    budget = budget + DRAW_GOLD
  else
    my.l = my.l + 1
  end

  -- simulate other matches
  local round_data = schedule[week]
  if round_data then
    for _, m in ipairs(round_data) do
      if m.home ~= my_team_index and m.away ~= my_team_index then
        local h = league[m.home]
        local a = league[m.away]
        local hg = math.max(0, math.floor((h.skill - a.skill) * 0.05 + math.random(3)))
        local ag = math.max(0, math.floor((a.skill - h.skill) * 0.05 + math.random(3)))
        h.gf = h.gf + hg; h.ga = h.ga + ag
        a.gf = a.gf + ag; a.ga = a.ga + hg
        if hg > ag then
          h.w = h.w + 1; h.pts = h.pts + 3
          a.l = a.l + 1
        elseif hg == ag then
          h.d = h.d + 1; h.pts = h.pts + 1
          a.d = a.d + 1; a.pts = a.pts + 1
        else
          a.w = a.w + 1; a.pts = a.pts + 3
          h.l = h.l + 1
        end
      end
    end
  end
end

local function sort_league()
  table.sort(league, function(a, b)
    if a.pts ~= b.pts then return a.pts > b.pts end
    return (a.gf - a.ga) > (b.gf - b.ga)
  end)
end

local function get_my_position()
  sort_league()
  for i, t in ipairs(league) do
    if t.name == TEAM_NAMES[my_team_index] then return i end
  end
  return LEAGUE_TEAMS
end

-- Input bindings
lurek.input.bind("roster", "r")
lurek.input.bind("train", "t")
lurek.input.bind("buy", "b")
lurek.input.bind("next_match", "space")
lurek.input.bind("confirm", "return")
lurek.input.bind("quit", "escape")
lurek.input.bind("select", "mouse1")
lurek.input.bind("opt_o", "o")
lurek.input.bind("opt_d", "d")
lurek.input.bind("opt_f", "f")
lurek.input.bind("opt_m", "m")
lurek.input.bind("opt_1", "1")
lurek.input.bind("opt_2", "2")
lurek.input.bind("opt_3", "3")
lurek.input.bind("opt_4", "4")

-- Init

-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
  lurek.window.setTitle("Sports Manager — Lurek2D")
  lurek.render.setBackgroundColor(0.08, 0.12, 0.08)

  -- Build roster
  for i = 1, ROSTER_SIZE do
    local pos = POSITIONS[((i - 1) % #POSITIONS) + 1]
    local p = gen_player(pos)
    if i <= TEAM_SIZE then p.starter = true end
    roster[i] = p
  end

  init_league()
  init_schedule()
  refresh_market()
end

-- Process
function lurek.process(delta)
  dt = delta
  title_blink = title_blink + delta

  update_tweens(delta)
  update_particles(goal_particles, delta)
  update_particles(train_particles, delta)
  update_particles(transfer_particles, delta)

  if lurek.input.wasActionPressed("quit") then
    lurek.event.quit()
    return
  end

  -- TITLE
  if state == STATE_TITLE then
    if lurek.input.wasActionPressed("confirm") then
      state = STATE_OFFICE
    end
    return
  end

  -- OFFICE
  if state == STATE_OFFICE then
    if lurek.input.wasActionPressed("roster") then
      state = STATE_ROSTER
    elseif lurek.input.wasActionPressed("train") and not training_done then
      state = STATE_TRAINING
    elseif lurek.input.wasActionPressed("buy") then
      state = STATE_TRANSFER
    elseif lurek.input.wasActionPressed("next_match") then
      if week > SEASON_WEEKS then
        local pos = get_my_position()
        if pos <= 3 then
          season_result = "CHAMPION! You finished #" .. pos .. "!"
        else
          season_result = "Season over. You finished #" .. pos .. ". Try again!"
        end
        state = STATE_SEASON_END
      else
        simulate_match()
        state = STATE_MATCH
      end
    end
    return
  end

  -- ROSTER
  if state == STATE_ROSTER then
    if lurek.input.wasActionPressed("roster") or lurek.input.wasActionPressed("confirm") then
      state = STATE_OFFICE
    end
    if lurek.input.wasActionPressed("select") then
      local mx, my = lurek.input.mouse.getPosition()
      for i, p in ipairs(roster) do
        local py = 80 + (i - 1) * 30
        if my >= py and my < py + 28 and mx >= 40 and mx <= 760 then
          if p.injured == 0 then
            if p.starter then
              p.starter = false
            else
              if count_starters() < TEAM_SIZE then
                p.starter = true
              end
            end
          end
        end
      end
    end
    return
  end

  -- MATCH
  if state == STATE_MATCH then
    match_timer = match_timer + delta
    match_event_timer = match_event_timer + delta
    local interval = MATCH_DURATION / math.max(#match_events, 1)
    if match_event_index < #match_events and match_event_timer >= interval then
      match_event_timer = match_event_timer - interval
      match_event_index = match_event_index + 1
      local ev = match_events[match_event_index]
      if ev.type == "goal_home" then
        spawn_goal_particles(SCREEN_W * 0.3, SCREEN_H * 0.3, 30)
        add_tween(score_display, "home", score_display.home, match_score[1], 0.5)
      elseif ev.type == "goal_away" then
        spawn_goal_particles(SCREEN_W * 0.7, SCREEN_H * 0.3, 20)
        add_tween(score_display, "away", score_display.away, match_score[2], 0.5)
      end
    end
    if match_timer >= MATCH_DURATION + 2.0 then
      -- heal injuries by 1 week
      for _, p in ipairs(roster) do
        if p.injured > 0 then p.injured = p.injured - 1 end
      end
      week = week + 1
      training_done = false
      refresh_market()
      -- tween league table points display
      sort_league()
      for i, t in ipairs(league) do
        add_tween(t, "display_pts", t.display_pts or 0, t.pts, 0.8)
      end
      state = STATE_OFFICE
    end
    return
  end

  -- TRAINING
  if state == STATE_TRAINING then
    if lurek.input.wasActionPressed("opt_o") then
      for _, p in ipairs(roster) do
        if p.pos == "FWD" then p.skill = clamp(p.skill + 2, 0, 99) end
      end
      training_done = true
      spawn_train_particles(SCREEN_W / 2, SCREEN_H / 2, 25)
      state = STATE_OFFICE
    elseif lurek.input.wasActionPressed("opt_d") then
      for _, p in ipairs(roster) do
        if p.pos == "DEF" or p.pos == "GK" then p.skill = clamp(p.skill + 2, 0, 99) end
      end
      training_done = true
      spawn_train_particles(SCREEN_W / 2, SCREEN_H / 2, 25)
      state = STATE_OFFICE
    elseif lurek.input.wasActionPressed("opt_f") then
      for _, p in ipairs(roster) do
        p.stamina = clamp(p.stamina + 5, 0, 100)
      end
      training_done = true
      spawn_train_particles(SCREEN_W / 2, SCREEN_H / 2, 25)
      state = STATE_OFFICE
    elseif lurek.input.wasActionPressed("opt_m") then
      for _, p in ipairs(roster) do
        p.morale = clamp(p.morale + 10, 0, 100)
        add_tween(p, "morale", p.morale - 10, p.morale, 0.6)
      end
      training_done = true
      spawn_train_particles(SCREEN_W / 2, SCREEN_H / 2, 25)
      state = STATE_OFFICE
    elseif lurek.input.wasActionPressed("confirm") or lurek.input.wasActionPressed("train") then
      state = STATE_OFFICE
    end
    return
  end

  -- TRANSFER
  if state == STATE_TRANSFER then
    for idx = 1, 3 do
      local key = "opt_" .. idx
      if lurek.input.wasActionPressed(key) and market[idx] then
        local p = market[idx]
        if budget >= p.price and #roster < 24 then
          budget = budget - p.price
          table.insert(roster, p)
          spawn_transfer_particles(SCREEN_W / 2, 120 + idx * 60, 20)
          market[idx] = nil
        end
      end
    end
    if lurek.input.wasActionPressed("confirm") or lurek.input.wasActionPressed("buy") then
      state = STATE_OFFICE
    end
    return
  end

  -- SEASON END
  if state == STATE_SEASON_END then
    if lurek.input.wasActionPressed("confirm") then
      -- reset for new season
      state = STATE_TITLE
      week = 1
      budget = START_BUDGET
      roster = {}
      for i = 1, ROSTER_SIZE do
        local pos = POSITIONS[((i - 1) % #POSITIONS) + 1]
        local p = gen_player(pos)
        if i <= TEAM_SIZE then p.starter = true end
        roster[i] = p
      end
      init_league()
      init_schedule()
      refresh_market()
      training_done = false
    end
  end
end

-- Render: pitch / match visuals
function lurek.draw()
  if state == STATE_MATCH then
    -- draw pitch
    lurek.render.setColor(0.15, 0.55, 0.15, 1)
    rect("fill", "fill", 50, 100, 700, 400)
    -- pitch lines
    lurek.render.setColor(1, 1, 1, 0.4)
    rect("fill", "line", 50, 100, 700, 400)
    ln(400, 100, 400, 500)
    circ("line", 400, 300, 60)
    -- goals
    lurek.render.setColor(1, 1, 1, 0.7)
    rect("fill", "line", 50, 240, 40, 120)
    rect("fill", "line", 710, 240, 40, 120)

    -- animated "players" as dots
    local time = match_timer
    for i = 1, 11 do
      local bx = 100 + math.sin(time * 2 + i * 0.7) * 40 + (i * 50) % 300
      local by = 150 + math.cos(time * 1.5 + i * 1.1) * 30 + (i * 30) % 250
      lurek.render.setColor(0.2, 0.4, 1, 0.9)
      circ("fill", bx, by, 6)
    end
    for i = 1, 11 do
      local rx = 400 + math.sin(time * 1.8 + i * 0.9) * 40 + (i * 45) % 250
      local ry = 150 + math.cos(time * 2.2 + i * 0.6) * 30 + (i * 35) % 250
      lurek.render.setColor(1, 0.2, 0.2, 0.9)
      circ("fill", rx, ry, 6)
    end

    -- goal particles
    for _, p in ipairs(goal_particles) do
      local a = clamp(p.life, 0, 1)
      lurek.render.setColor(p.r, p.g, p.b, a)
      circ("fill", p.x, p.y, p.size)
    end
  end

  -- training particles (on field background)
  if state == STATE_TRAINING then
    lurek.render.setColor(0.12, 0.4, 0.12, 1)
    rect("fill", "fill", 100, 200, 600, 250)
    lurek.render.setColor(1, 1, 1, 0.3)
    rect("fill", "line", 100, 200, 600, 250)
  end

  for _, p in ipairs(train_particles) do
    local a = clamp(p.life, 0, 1)
    lurek.render.setColor(0.6, 0.8, 1.0, a * 0.7)
    circ("fill", p.x, p.y, p.size)
  end

  -- transfer sparkle
  for _, p in ipairs(transfer_particles) do
    local a = clamp(p.life, 0, 1)
    lurek.render.setColor(p.r, p.g, p.b, a)
    circ("fill", p.x, p.y, p.size)
  end
end

-- Render UI: menus, tables, stats
function lurek.draw_ui()
  lurek.render.setColor(1, 1, 1, 1)

  -- FPS
  lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
  text_("FPS: " .. tostring(lurek.timer.getFPS()), 10, SCREEN_H - 20)
  lurek.render.setColor(1, 1, 1, 1)

  -- TITLE
  if state == STATE_TITLE then
    lurek.render.setColor(0.1, 0.7, 0.3, 1)
    text_("SPORTS MANAGER", SCREEN_W / 2 - 100, 150)
    lurek.render.setColor(0.8, 0.9, 0.8, 1)
    text_("LEAD YOUR TEAM", SCREEN_W / 2 - 80, 200)
    local blink_a = 0.5 + 0.5 * math.sin(title_blink * 3)
    lurek.render.setColor(1, 1, 1, blink_a)
    text_("Press ENTER to start", SCREEN_W / 2 - 90, 320)

    lurek.render.setColor(0.6, 0.6, 0.6, 0.7)
    text_("R=Roster  T=Train  B=Buy  Space=Next Match", SCREEN_W / 2 - 180, 400)
    return
  end

  -- OFFICE
  if state == STATE_OFFICE then
    lurek.render.setColor(0.1, 0.7, 0.3, 1)
    text_("OFFICE — " .. TEAM_NAMES[my_team_index], 20, 15)
    lurek.render.setColor(1, 1, 1, 1)
    text_("Week " .. week .. " / " .. SEASON_WEEKS .. "    Budget: " .. budget .. "g", 20, 40)

    local starters = count_starters()
    text_("Starters: " .. starters .. "/" .. TEAM_SIZE .. "    Roster: " .. #roster, 20, 60)

    if training_done then
      lurek.render.setColor(0.5, 0.5, 0.5, 0.7)
      text_("[T] Train (done this week)", 20, 90)
    else
      lurek.render.setColor(0.8, 1, 0.8, 1)
      text_("[T] Train", 20, 90)
    end
    lurek.render.setColor(0.8, 1, 0.8, 1)
    text_("[R] Roster    [B] Transfer Market    [Space] Next Match", 20, 110)

    -- Mini league table
    sort_league()
    lurek.render.setColor(0.2, 0.6, 0.2, 1)
    text_("LEAGUE TABLE", 20, 150)
    lurek.render.setColor(0.7, 0.7, 0.7, 1)
    text_("#   Team             W   D   L   GF  GA  Pts", 20, 170)
    for i, t in ipairs(league) do
      local y = 190 + (i - 1) * 22
      local is_me = (t.name == TEAM_NAMES[my_team_index])
      if is_me then
        lurek.render.setColor(0.2, 0.4, 0.2, 0.5)
        rect("fill", "fill", 18, y - 2, 550, 20)
      end
      if i <= 3 then
        lurek.render.setColor(0.3, 1, 0.5, 1)
      else
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
      end
      local pts_show = math.floor((t.display_pts or t.pts) + 0.5)
      local line = string.format("%-3d %-16s %3d %3d %3d %3d %3d  %3d",
        i, t.name, t.w, t.d, t.l, t.gf, t.ga, pts_show)
      text_(line, 20, y)
    end

    -- next opponent
    if week <= SEASON_WEEKS then
      local round = schedule[week]
      if round then
        for _, m in ipairs(round) do
          if m.home == my_team_index or m.away == my_team_index then
            local opp_idx = m.home == my_team_index and m.away or m.home
            local venue = m.home == my_team_index and "HOME" or "AWAY"
            lurek.render.setColor(1, 0.9, 0.4, 1)
            text_("Next: vs " .. TEAM_NAMES[opp_idx] .. " (" .. venue .. ")", 20, 390 + 20)
          end
        end
      end
    else
      lurek.render.setColor(1, 0.6, 0.2, 1)
      text_("Season complete! Press SPACE to see results.", 20, 410)
    end
    return
  end

  -- ROSTER
  if state == STATE_ROSTER then
    lurek.render.setColor(0.1, 0.7, 0.3, 1)
    text_("ROSTER — Click to toggle starter/bench", 20, 15)
    lurek.render.setColor(0.7, 0.7, 0.7, 1)
    text_("Name                 Pos  Skill  Stam  Morale  Status", 40, 55)

    for i, p in ipairs(roster) do
      local y = 80 + (i - 1) * 30
      -- highlight starters
      if p.starter then
        lurek.render.setColor(0.15, 0.3, 0.15, 0.5)
        rect("fill", "fill", 38, y - 2, 720, 26)
      end

      if p.injured > 0 then
        lurek.render.setColor(0.8, 0.3, 0.3, 1)
      elseif p.starter then
        local c = POS_COLORS[p.pos] or {1, 1, 1}
        lurek.render.setColor(c[1], c[2], c[3], 1)
      else
        lurek.render.setColor(0.5, 0.5, 0.5, 1)
      end

      local status = p.starter and "START" or "BENCH"
      if p.injured > 0 then status = "INJ(" .. p.injured .. "w)" end

      -- morale bar
      local bar_x = 600
      local bar_w = 80
      local bar_h = 10
      local fill = p.morale / 100
      lurek.render.setColor(0.3, 0.3, 0.3, 0.5)
      rect("fill", "fill", bar_x, y + 4, bar_w, bar_h)
      if p.morale > 70 then
        lurek.render.setColor(0.2, 0.8, 0.3, 0.8)
      elseif p.morale > 40 then
        lurek.render.setColor(0.8, 0.7, 0.2, 0.8)
      else
        lurek.render.setColor(0.8, 0.2, 0.2, 0.8)
      end
      rect("fill", "fill", bar_x, y + 4, bar_w * fill, bar_h)

      local c = POS_COLORS[p.pos] or {1, 1, 1}
      if p.injured > 0 then
        lurek.render.setColor(0.8, 0.3, 0.3, 1)
      elseif p.starter then
        lurek.render.setColor(c[1], c[2], c[3], 1)
      else
        lurek.render.setColor(0.5, 0.5, 0.5, 1)
      end

      local line = string.format("%-20s %-4s %3d    %3d    %3d     %s",
        p.name, p.pos, p.skill, p.stamina, p.morale, status)
      text_(line, 40, y)
    end

    lurek.render.setColor(0.6, 0.6, 0.6, 0.7)
    text_("Press R or ENTER to return to office", 20, SCREEN_H - 30)
    return
  end

  -- MATCH
  if state == STATE_MATCH then
    -- scoreboard
    lurek.render.setColor(0, 0, 0, 0.7)
    rect("fill", "fill", 200, 20, 400, 70)
    lurek.render.setColor(0.3, 0.6, 1, 1)
    text_(TEAM_NAMES[my_team_index], 220, 30)
    lurek.render.setColor(1, 0.3, 0.3, 1)
    text_(match_opponent, 480, 30)
    lurek.render.setColor(1, 1, 1, 1)
    local h_disp = math.floor(score_display.home + 0.5)
    local a_disp = math.floor(score_display.away + 0.5)
    text_(h_disp .. " — " .. a_disp, 370, 50)

    -- match time bar
    local progress = clamp(match_timer / MATCH_DURATION, 0, 1)
    lurek.render.setColor(0.3, 0.3, 0.3, 0.6)
    rect("fill", "fill", 200, 95, 400, 8)
    lurek.render.setColor(0.4, 0.9, 0.4, 0.9)
    rect("fill", "fill", 200, 95, 400 * progress, 8)

    -- event feed
    lurek.render.setColor(0, 0, 0, 0.6)
    rect("fill", "fill", 50, 520, 700, 70)
    for i = math.max(1, match_event_index - 2), match_event_index do
      if match_events[i] then
        local ey = 525 + (i - math.max(1, match_event_index - 2)) * 20
        local ev = match_events[i]
        if ev.type == "goal_home" then
          lurek.render.setColor(0.3, 1, 0.5, 1)
        elseif ev.type == "goal_away" then
          lurek.render.setColor(1, 0.4, 0.4, 1)
        elseif ev.type == "injury" then
          lurek.render.setColor(1, 0.6, 0.2, 1)
        elseif ev.type == "red_card" then
          lurek.render.setColor(1, 0.2, 0.2, 1)
        else
          lurek.render.setColor(0.8, 0.8, 0.8, 1)
        end
        text_(ev.time .. "' — " .. ev.text, 60, ey)
      end
    end
    return
  end

  -- TRAINING
  if state == STATE_TRAINING then
    lurek.render.setColor(0.1, 0.7, 0.3, 1)
    text_("TRAINING SESSION", SCREEN_W / 2 - 80, 30)
    lurek.render.setColor(1, 1, 1, 1)
    text_("Choose training focus:", SCREEN_W / 2 - 90, 80)

    lurek.render.setColor(0.9, 0.4, 0.4, 1)
    text_("[O] Offense — +2 skill to Forwards", 200, 130)
    lurek.render.setColor(0.4, 0.5, 0.9, 1)
    text_("[D] Defense — +2 skill to Defenders & GK", 200, 160)
    lurek.render.setColor(0.4, 0.9, 0.4, 1)
    text_("[F] Fitness — +5 stamina to all", 200, 190)
    lurek.render.setColor(0.9, 0.8, 0.3, 1)
    text_("[M] Morale — +10 morale to all", 200, 220)

    lurek.render.setColor(0.6, 0.6, 0.6, 0.7)
    text_("Press ENTER to cancel", SCREEN_W / 2 - 70, SCREEN_H - 40)
    return
  end

  -- TRANSFER
  if state == STATE_TRANSFER then
    lurek.render.setColor(0.1, 0.7, 0.3, 1)
    text_("TRANSFER MARKET", SCREEN_W / 2 - 80, 20)
    lurek.render.setColor(1, 1, 1, 1)
    text_("Budget: " .. budget .. "g    Roster: " .. #roster .. "/24", 20, 50)

    lurek.render.setColor(0.7, 0.7, 0.7, 1)
    text_("#   Name                 Pos  Skill  Price", 40, 90)

    for i, p in ipairs(market) do
      if p then
        local y = 120 + (i - 1) * 60
        local can_buy = budget >= p.price and #roster < 24
        if can_buy then
          lurek.render.setColor(1, 1, 1, 1)
        else
          lurek.render.setColor(0.5, 0.4, 0.4, 1)
        end
        local c = POS_COLORS[p.pos] or {1, 1, 1}
        lurek.render.setColor(c[1], c[2], c[3], can_buy and 1 or 0.5)
        local line = string.format("[%d] %-20s %-4s %3d    %dg",
          i, p.name, p.pos, p.skill, p.price)
        text_(line, 40, y)
      else
        local y = 120 + (i - 1) * 60
        lurek.render.setColor(0.4, 0.4, 0.4, 0.5)
        text_("[" .. i .. "] — SOLD —", 40, y)
      end
    end

    lurek.render.setColor(0.6, 0.6, 0.6, 0.7)
    text_("Press 1-3 to buy, B or ENTER to return", 20, SCREEN_H - 30)
    return
  end

  -- SEASON END
  if state == STATE_SEASON_END then
    local pos = get_my_position()
    if pos <= 3 then
      lurek.render.setColor(1, 0.85, 0.0, 1)
    else
      lurek.render.setColor(0.8, 0.3, 0.3, 1)
    end
    text_(season_result, SCREEN_W / 2 - 140, 100)

    sort_league()
    lurek.render.setColor(0.7, 0.7, 0.7, 1)
    text_("FINAL STANDINGS", SCREEN_W / 2 - 70, 160)
    text_("#   Team             W   D   L   GF  GA  Pts", 80, 190)
    for i, t in ipairs(league) do
      local y = 215 + (i - 1) * 24
      local is_me = (t.name == TEAM_NAMES[my_team_index])
      if is_me then
        lurek.render.setColor(0.2, 0.4, 0.2, 0.6)
        rect("fill", "fill", 78, y - 2, 500, 22)
      end
      if i <= 3 then
        lurek.render.setColor(0.3, 1, 0.5, 1)
      else
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
      end
      local line = string.format("%-3d %-16s %3d %3d %3d %3d %3d  %3d",
        i, t.name, t.w, t.d, t.l, t.gf, t.ga, t.pts)
      text_(line, 80, y)
    end

    lurek.render.setColor(1, 1, 1, 0.5 + 0.5 * math.sin(title_blink * 3))
    text_("Press ENTER to play again", SCREEN_W / 2 - 100, SCREEN_H - 50)
  end
end
