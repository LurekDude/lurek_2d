-- Constants (grouped into C to stay within LuaJIT 60-upvalue limit)
local C = {
  SCREEN_W=800, SCREEN_H=600, WATER_Y=300, SHORE_X=80,
  ROD_TIP_X=110, ROD_TIP_Y=240,
  MAX_CAST_DIST=400, HOOK_WINDOW=1.5,
  TENSION_SNAP=0.80, TENSION_SNAP_TIME=2.0, TENSION_SAFE=0.20,
  REEL_SPEED=60, FISH_PULL_SPEED=30, FISH_BURST_CALM=3.0, FISH_BURST_PULL=1.0,
  LAND_DIST=20, DAY_CYCLE=120, WIN_COUNT=10,
  BITE_MIN=3.0, BITE_MAX=10.0, RAIN_BITE_MULT=0.5,
}
local STATES = {
  TITLE="TITLE", FISHING="FISHING", CATCHING="CATCHING",
  BUCKET="BUCKET_VIEW", GAMEOVER="GAME_OVER",
}

--[[

  Fishing — Lurek2D
  Category: sports

  Side-view lake fishing game with casting, reeling tension minigame,
  five fish species, bait selection, day/night cycle, and weather.
]]



-- Fish definitions
local FISH_TYPES = {
  { name = "Minnow",      points = 5,   fight = 0.3, deep = false, rarity = 0.40, color = {0.7, 0.7, 0.7} },
  { name = "Trout",       points = 15,  fight = 0.5, deep = false, rarity = 0.25, color = {0.3, 0.7, 0.4} },
  { name = "Bass",        points = 30,  fight = 0.7, deep = false, rarity = 0.15, color = {0.2, 0.5, 0.2} },
  { name = "Catfish",     points = 25,  fight = 0.5, deep = true,  rarity = 0.10, color = {0.5, 0.4, 0.3} },
  { name = "Golden Fish", points = 100, fight = 0.9, deep = false, rarity = 0.05, color = {1.0, 0.85, 0.0} },
}

-- Bait definitions
local BAITS = {
  { name = "Worm",      boost = {} },
  { name = "Fly",       boost = { Trout = 2.0, Bass = 1.5 } },
  { name = "Deep Bait", boost = { Catfish = 3.0 } },
}

-- Game state
local state = STATES.TITLE
local power = 0
local charging = false
local cast_x = 0
local bobber_y = C.WATER_Y
local bobber_base_y = C.WATER_Y
local bite_timer = 0
local bite_active = false
local hook_timer = 0
local hooked_fish = nil  ---@type table?
local tension = 0.40
local tension_high_timer = 0
local fish_x = 0
local fish_fight_timer = 0
local fish_bursting = false
local bucket = {}
local total_points = 0
local day_timer = 0
local is_night = false
local raining = false
local rain_timer = 0
local rain_duration = 0
local bait_index = 1
local message = ""
local message_timer = 0
local dt = 0
local bobber_dip_tween = nil
local tension_tween = nil
local fish_approach_tween = nil
local splash_particles = {}
local rain_particles = {}
local sparkle_particles = {}
local ripple_particles = {}
local game_won = false
local win_reason = ""

-- Helpers
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function lerp(a, b, t) return a + (b - a) * clamp(t, 0, 1) end

local function show_message(msg, dur)
  message = msg
  message_timer = dur or 2.0
end

local function pick_fish()
  local weights = {}
  local total = 0
  local night_mult = is_night and 2.0 or 1.0
  local bait = BAITS[bait_index]
  local deep_cast = cast_x > C.SHORE_X + C.MAX_CAST_DIST * 0.7

  for i, f in ipairs(FISH_TYPES) do
    local w = f.rarity
    if f.deep and not deep_cast then
      w = 0
    end
    if f.name == "Golden Fish" or f.name == "Catfish" then
      w = w * night_mult
    end
    if bait.boost[f.name] then
      w = w * bait.boost[f.name]
    end
    weights[i] = w
    total = total + w
  end

  local r = math.random() * total
  local acc = 0
  for i, w in ipairs(weights) do
    acc = acc + w
    if r <= acc then return FISH_TYPES[i] end
  end
  return FISH_TYPES[1]
end

local function spawn_splash(x, y, count)
  for _ = 1, count do
    table.insert(splash_particles, {
      x = x, y = y,
      vx = (math.random() - 0.5) * 120,
      vy = -math.random() * 80 - 40,
      life = 0.5 + math.random() * 0.3,
    })
  end
end

local function spawn_sparkle(x, y, count)
  for _ = 1, count do
    table.insert(sparkle_particles, {
      x = x, y = y,
      vx = (math.random() - 0.5) * 60,
      vy = -math.random() * 60 - 20,
      life = 0.8 + math.random() * 0.4,
      size = 2 + math.random() * 3,
    })
  end
end

local function spawn_ripple(x, y)
  table.insert(ripple_particles, {
    x = x, y = y, radius = 2, max_radius = 12 + math.random() * 8, life = 0.6,
  })
end

local function reset_cast()
  power = 0
  charging = false
  cast_x = 0
  bobber_y = C.WATER_Y
  bobber_base_y = C.WATER_Y
  bite_timer = 0
  bite_active = false
  hook_timer = 0
  hooked_fish = nil
  tension = 0.40
  tension_high_timer = 0
  fish_x = 0
  fish_fight_timer = 0
  fish_bursting = false
  bobber_dip_tween = nil
  tension_tween = nil
  fish_approach_tween = nil
end

local function start_game()
  state = STATES.FISHING
  bucket = {}
  total_points = 0
  day_timer = 0
  is_night = false
  raining = false
  rain_timer = 0
  bait_index = 1
  game_won = false
  win_reason = ""
  reset_cast()
  show_message("Cast with SPACE! Bait: 1/2/3", 3)
end

-- Input bindings
lurek.input.bind("cast_reel", "space")
lurek.input.bind("bait1", "1")
lurek.input.bind("bait2", "2")
lurek.input.bind("bait3", "3")
lurek.input.bind("quit", "escape")

lurek.window.setTitle("Fishing — Lurek2D")
lurek.render.setBackgroundColor(0.4, 0.6, 0.8)

-- Callbacks
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
local function ln(x1, y1, x2, y2, r, g, b, a)
    if type(r) == "table" then _sc(r)
    elseif r then _gfx.setColor(r, g or 1, b or 1, a or 1) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
  math.randomseed(os.time())
end

local function _ready_setup()
  show_message("", 0)
end

function lurek.process(delta)
  dt = delta

  -- Message timer
  if message_timer > 0 then
    message_timer = message_timer - dt
    if message_timer <= 0 then message = "" end
  end

  -- Quit
  if lurek.input.keyboard.isDown("quit") then
    lurek.event.quit()
    return
  end

  -- Update particles
  for i = #splash_particles, 1, -1 do
    local p = splash_particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy + 200 * dt
    p.life = p.life - dt
    if p.life <= 0 then table.remove(splash_particles, i) end
  end
  for i = #sparkle_particles, 1, -1 do
    local p = sparkle_particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    if p.life <= 0 then table.remove(sparkle_particles, i) end
  end
  for i = #ripple_particles, 1, -1 do
    local p = ripple_particles[i]
    local t = 1.0 - (p.life / 0.6)
    p.radius = lerp(2, p.max_radius, t)
    p.life = p.life - dt
    if p.life <= 0 then table.remove(ripple_particles, i) end
  end

  -- Rain particles
  if raining then
    for _ = 1, 3 do
      table.insert(rain_particles, {
        x = math.random() * C.SCREEN_W,
        y = -10,
        vy = 300 + math.random() * 100,
        life = 2.0,
      })
    end
  end
  for i = #rain_particles, 1, -1 do
    local p = rain_particles[i]
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    if p.life <= 0 or p.y > C.SCREEN_H then table.remove(rain_particles, i) end
  end

  -- TITLE
  if state == STATES.TITLE then
    if lurek.input.keyboard.isDown("cast_reel") then
      start_game()
    end
    return
  end

  -- GAME OVER
  if state == STATES.GAMEOVER then
    if lurek.input.keyboard.isDown("cast_reel") then
      state = STATES.TITLE
    end
    return
  end

  -- BUCKET VIEW
  if state == STATES.BUCKET then
    if lurek.input.keyboard.isDown("cast_reel") then
      state = STATES.FISHING
      reset_cast()
    end
    return
  end

  -- Day/night cycle
  day_timer = day_timer + dt
  local cycle_pos = day_timer % C.DAY_CYCLE
  is_night = cycle_pos > C.DAY_CYCLE * 0.5

  -- Weather
  rain_timer = rain_timer - dt
  if rain_timer <= 0 then
    raining = not raining
    rain_duration = 10 + math.random() * 20
    rain_timer = rain_duration
    if raining then show_message("Rain starts...", 2) end
  end

  -- Bait selection
  if lurek.input.keyboard.isDown("bait1") then bait_index = 1; show_message("Bait: Worm", 1.5) end
  if lurek.input.keyboard.isDown("bait2") then bait_index = 2; show_message("Bait: Fly", 1.5) end
  if lurek.input.keyboard.isDown("bait3") then bait_index = 3; show_message("Bait: Deep Bait", 1.5) end

  -- FISHING state
  if state == STATES.FISHING then
    if cast_x == 0 then
      -- Charging
      if lurek.input.isActionDown("cast_reel") then
        charging = true
        power = clamp(power + dt * 80, 0, 100)
      elseif charging then
        -- Release cast
        charging = false
        local dist = (power / 100) * C.MAX_CAST_DIST
        cast_x = C.SHORE_X + dist
        bobber_y = C.WATER_Y
        bobber_base_y = C.WATER_Y
        local bite_delay = C.BITE_MIN + math.random() * (C.BITE_MAX - C.BITE_MIN)
        if raining then bite_delay = bite_delay * C.RAIN_BITE_MULT end
        bite_timer = bite_delay
        bite_active = false
        spawn_splash(cast_x, C.WATER_Y, 8)
        spawn_ripple(cast_x, C.WATER_Y)
        show_message("Waiting for a bite...", 2)
        power = 0
      end
    else
      -- Waiting for bite
      if not bite_active then
        bite_timer = bite_timer - dt
        -- Bobber gentle bob
        bobber_y = bobber_base_y + math.sin(day_timer * 3) * 2

        if bite_timer <= 0 then
          bite_active = true
          hook_timer = C.HOOK_WINDOW
          hooked_fish = pick_fish()
          -- Bobber dip
          bobber_dip_tween = { from = bobber_y, to = bobber_y + 15, t = 0, dur = 0.3 }
          show_message("BITE! Press SPACE!", 1.5)
          spawn_ripple(cast_x, C.WATER_Y)
        end
      else
        -- Bite window
        hook_timer = hook_timer - dt

        -- Animate bobber dip
        if bobber_dip_tween then
          bobber_dip_tween.t = bobber_dip_tween.t + dt
          local prog = clamp(bobber_dip_tween.t / bobber_dip_tween.dur, 0, 1)
          local ease = math.sin(prog * math.pi)
          bobber_y = lerp(bobber_dip_tween.from, bobber_dip_tween.to, ease)
          if bobber_dip_tween.t >= bobber_dip_tween.dur then bobber_dip_tween = nil end
        end

        if lurek.input.keyboard.isDown("cast_reel") then
          -- Hooked!
          state = STATES.CATCHING
          fish_x = cast_x
          tension = 0.40
          tension_high_timer = 0
          fish_fight_timer = 0
          fish_bursting = false
          ---@cast hooked_fish table
          show_message("Hooked " .. hooked_fish.name .. "! Reel with SPACE!", 2)
          spawn_splash(cast_x, C.WATER_Y, 5)
        elseif hook_timer <= 0 then
          show_message("Too slow! Fish escaped.", 2)
          reset_cast()
        end
      end

      -- Bucket view shortcut
      if lurek.input.keyboard.isDown("bait1") and cast_x > 0 then
        -- already handled above
      end
    end
  end

  -- CATCHING state
  if state == STATES.CATCHING then
    ---@cast hooked_fish table
    local fight = hooked_fish.fight

    -- Fish fight bursts
    fish_fight_timer = fish_fight_timer + dt
    local cycle_t = fish_fight_timer % (C.FISH_BURST_CALM + C.FISH_BURST_PULL)
    fish_bursting = cycle_t > C.FISH_BURST_CALM

    -- Tension dynamics
    if fish_bursting then
      tension = tension + fight * 0.4 * dt
    else
      tension = tension - 0.05 * dt
    end

    if lurek.input.isActionDown("cast_reel") then
      -- Reeling in
      fish_x = fish_x - C.REEL_SPEED * dt
      tension = tension + 0.15 * dt
      spawn_ripple(fish_x, C.WATER_Y)
    else
      -- Fish pulls away
      if fish_bursting then
        fish_x = fish_x + C.FISH_PULL_SPEED * fight * dt
      end
      tension = tension - 0.08 * dt
    end

    tension = clamp(tension, 0, 1.0)
    fish_x = clamp(fish_x, C.SHORE_X, C.SCREEN_W - 20)

    -- Snap check
    if tension > C.TENSION_SNAP then
      tension_high_timer = tension_high_timer + dt
      if tension_high_timer >= C.TENSION_SNAP_TIME then
        show_message("LINE SNAPPED! " .. hooked_fish.name .. " escaped!", 2.5)
        spawn_splash(fish_x, C.WATER_Y, 10)
        state = STATES.FISHING
        reset_cast()
        return
      end
    else
      tension_high_timer = 0
    end

    -- Land check
    if fish_x <= C.SHORE_X + C.LAND_DIST then
      -- Caught!
      table.insert(bucket, { name = hooked_fish.name, points = hooked_fish.points, color = hooked_fish.color })
      total_points = total_points + hooked_fish.points
      spawn_sparkle(C.SHORE_X + 20, C.WATER_Y - 30, 15)
      spawn_splash(C.SHORE_X, C.WATER_Y, 6)
      show_message("Caught " .. hooked_fish.name .. "! +" .. hooked_fish.points .. "pts", 2.5)

      -- Win check
      if hooked_fish.name == "Golden Fish" then
        game_won = true
        win_reason = "You caught the legendary Golden Fish!"
        state = STATES.GAMEOVER
      elseif #bucket >= C.WIN_COUNT then
        game_won = true
        win_reason = "You filled the bucket with " .. #bucket .. " fish!"
        state = STATES.GAMEOVER
      else
        state = STATES.FISHING
        reset_cast()
      end
    end
  end
end

function lurek.draw()
  -- Sky gradient
  local sky_r, sky_g, sky_b = 0.4, 0.6, 0.9
  if is_night then sky_r, sky_g, sky_b = 0.05, 0.05, 0.15 end
  lurek.render.setBackgroundColor(sky_r, sky_g, sky_b)

  -- Water
  local water_r, water_g, water_b = 0.1, 0.2, 0.5
  if is_night then water_r, water_g, water_b = 0.03, 0.06, 0.15 end
  rect(0, C.WATER_Y, C.SCREEN_W, C.SCREEN_H - C.WATER_Y, water_r, water_g, water_b, 0.85)

  -- Water surface line
  rect(0, C.WATER_Y - 2, C.SCREEN_W, 4, 0.3, 0.5, 0.8, 0.6)

  -- Shore
  rect(0, C.WATER_Y - 10, C.SHORE_X + 10, C.SCREEN_H - C.WATER_Y + 10, 0.45, 0.35, 0.2, 1.0)
  -- Grass
  rect(0, C.WATER_Y - 15, C.SHORE_X + 15, 8, 0.2, 0.6, 0.2, 1.0)

  -- Fisher (stick figure)
  -- Body
  rect(C.SHORE_X - 5, C.WATER_Y - 55, 6, 30, 0.3, 0.2, 0.1, 1.0)
  -- Head
  circ(C.SHORE_X - 2, C.WATER_Y - 62, 8, 0.9, 0.75, 0.6, 1.0)
  -- Legs
  rect(C.SHORE_X - 8, C.WATER_Y - 25, 5, 20, 0.2, 0.15, 0.1, 1.0)
  rect(C.SHORE_X, C.WATER_Y - 25, 5, 20, 0.2, 0.15, 0.1, 1.0)
  -- Rod
  ln(C.SHORE_X, C.WATER_Y - 50, C.ROD_TIP_X, C.ROD_TIP_Y, 0.5, 0.35, 0.1, 1.0)

  -- Fishing line + bobber
  if cast_x > 0 then
    ln(C.ROD_TIP_X, C.ROD_TIP_Y, cast_x, bobber_y, 0.8, 0.8, 0.8, 0.6)
    -- Bobber
    circ(cast_x, bobber_y, 5, 1.0, 0.2, 0.1, 1.0)
    circ(cast_x, bobber_y - 4, 3, 1.0, 1.0, 1.0, 1.0)
  end

  -- Fish under water (visible when hooked in CATCHING)
  if state == STATES.CATCHING and hooked_fish then
    local fc = hooked_fish.color
    local fy = C.WATER_Y + 30 + math.sin(day_timer * 5) * 8
    -- Fish body
    circ(fish_x, fy, 10, fc[1], fc[2], fc[3], 0.8)
    -- Tail
    rect(fish_x + 8, fy - 5, 8, 10, fc[1] * 0.8, fc[2] * 0.8, fc[3] * 0.8, 0.7)
    -- Line to fish
    ln(cast_x, bobber_y, fish_x, fy, 0.8, 0.8, 0.8, 0.4)
  end

  -- Bite indicator
  if state == STATES.FISHING and bite_active then
    text_("!", cast_x - 3, bobber_y - 25, 1.0, 0.9, 0.0, 1.0)
  end

  -- Splash particles
  for _, p in ipairs(splash_particles) do
    local a = clamp(p.life / 0.5, 0, 1)
    circ(p.x, p.y, 2, 0.6, 0.8, 1.0, a)
  end

  -- Ripple particles
  for _, p in ipairs(ripple_particles) do
    local a = clamp(p.life / 0.6, 0, 1) * 0.5
    circ(p.x, p.y, p.radius, 0.5, 0.7, 1.0, a)
  end

  -- Sparkle particles
  for _, p in ipairs(sparkle_particles) do
    local a = clamp(p.life / 0.8, 0, 1)
    circ(p.x, p.y, p.size, 1.0, 1.0, 0.5, a)
  end

  -- Rain particles
  for _, p in ipairs(rain_particles) do
    ln(p.x, p.y, p.x - 1, p.y + 8, 0.5, 0.6, 0.9, 0.3)
  end

  -- Night/day indicator stars
  if is_night then
    for i = 1, 12 do
      local sx = (i * 67 + 13) % C.SCREEN_W
      local sy = (i * 43 + 7) % (C.WATER_Y - 30)
      local flicker = 0.5 + 0.5 * math.sin(day_timer * 2 + i)
      circ(sx, sy, 1.5, 1.0, 1.0, 0.8, flicker)
    end
  end
end

function lurek.draw_ui()
  local fps = lurek.timer.getFPS()
  text_("FPS: " .. fps, C.SCREEN_W - 80, 10, 1, 1, 1, 0.5)

  -- TITLE
  if state == STATES.TITLE then
    rect(150, 150, 500, 250, 0.0, 0.1, 0.3, 0.85)
    text_("FISHING", 300, 200, 1.0, 1.0, 1.0, 1.0)
    text_("PATIENCE REWARDED", 275, 250, 0.7, 0.85, 1.0, 0.9)
    text_("Press SPACE to start", 290, 320, 0.8, 0.8, 0.8, 0.7)
    return
  end

  -- GAME OVER
  if state == STATES.GAMEOVER then
    rect(100, 120, 600, 350, 0.0, 0.05, 0.15, 0.9)
    if game_won then
      text_("YOU WIN!", 320, 150, 1.0, 0.9, 0.2, 1.0)
      text_(win_reason, 200, 200, 0.9, 0.9, 0.9, 1.0)
    else
      text_("GAME OVER", 310, 150, 1.0, 0.3, 0.3, 1.0)
    end
    text_("Fish caught: " .. #bucket, 300, 260, 0.8, 0.8, 0.8, 1.0)
    text_("Total points: " .. total_points, 290, 290, 0.8, 0.8, 0.8, 1.0)
    -- Show bucket summary
    local y_off = 320
    for i, f in ipairs(bucket) do
      if i <= 8 then
        text_(f.name .. " (" .. f.points .. "pts)", 280, y_off, f.color[1], f.color[2], f.color[3], 0.9)
        y_off = y_off + 20
      end
    end
    if #bucket > 8 then
      text_("...and " .. (#bucket - 8) .. " more", 300, y_off, 0.6, 0.6, 0.6, 0.7)
    end
    text_("Press SPACE to return", 285, y_off + 30, 0.6, 0.6, 0.6, 0.6)
    return
  end

  -- BUCKET VIEW
  if state == STATES.BUCKET then
    rect(150, 80, 500, 440, 0.1, 0.08, 0.2, 0.9)
    text_("BUCKET", 340, 100, 1.0, 1.0, 1.0, 1.0)
    text_("Fish: " .. #bucket .. "/" .. C.WIN_COUNT .. "  Points: " .. total_points, 250, 135, 0.8, 0.8, 0.8, 1.0)
    local y_off = 170
    for i, f in ipairs(bucket) do
      text_(i .. ". " .. f.name .. "  +" .. f.points, 200, y_off, f.color[1], f.color[2], f.color[3], 0.9)
      y_off = y_off + 22
      if y_off > 490 then
        text_("..." .. (#bucket - i) .. " more", 200, y_off, 0.5, 0.5, 0.5, 0.7)
        break
      end
    end
    text_("Press SPACE to continue", 275, 500, 0.6, 0.6, 0.6, 0.6)
    return
  end

  -- HUD during FISHING / CATCHING
  -- Bait indicator
  text_("Bait: " .. BAITS[bait_index].name, 10, 10, 1, 1, 1, 0.8)
  -- Bucket count
  text_("Bucket: " .. #bucket .. "/" .. C.WIN_COUNT, 10, 30, 1, 1, 1, 0.8)
  -- Points
  text_("Points: " .. total_points, 10, 50, 1, 1, 0.5, 0.8)
  -- Day/night
  local dn = is_night and "Night" or "Day"
  text_(dn, C.SCREEN_W - 60, 30, 0.8, 0.8, 0.4, 0.7)
  -- Weather
  if raining then
    text_("Rain", C.SCREEN_W - 60, 50, 0.5, 0.6, 0.9, 0.7)
  end

  -- Power bar (while charging)
  if charging then
    rect(C.SCREEN_W / 2 - 100, C.SCREEN_H - 50, 200, 20, 0.2, 0.2, 0.2, 0.7)
    local pw = (power / 100) * 196
    local pr = power / 100
    rect(C.SCREEN_W / 2 - 98, C.SCREEN_H - 48, pw, 16, pr, 1.0 - pr * 0.5, 0.1, 0.9)
    text_("POWER", C.SCREEN_W / 2 - 22, C.SCREEN_H - 48, 1, 1, 1, 0.9)
  end

  -- Tension bar (while catching)
  if state == STATES.CATCHING then
    local bar_x = C.SCREEN_W / 2 - 100
    local bar_y = C.SCREEN_H - 60
    rect(bar_x, bar_y, 200, 24, 0.15, 0.15, 0.15, 0.8)
    local tw = tension * 196
    local tr = tension
    local tg = 1.0 - tension
    rect(bar_x + 2, bar_y + 2, tw, 20, tr, tg, 0.1, 0.9)
    -- Snap danger zone
    rect(bar_x + 2 + C.TENSION_SNAP * 196, bar_y + 2, (1.0 - C.TENSION_SNAP) * 196, 20, 1.0, 0.0, 0.0, 0.2)
    text_("TENSION", bar_x + 70, bar_y + 3, 1, 1, 1, 0.9)

    -- Fish name
    if hooked_fish then
      text_(hooked_fish.name, bar_x + 60, bar_y - 20, hooked_fish.color[1], hooked_fish.color[2], hooked_fish.color[3], 1.0)
    end

    -- Warning
    if tension > C.TENSION_SNAP then
      local blink = math.sin(day_timer * 10) > 0
      if blink then
        text_("!! LINE STRAIN !!", C.SCREEN_W / 2 - 60, bar_y - 40, 1.0, 0.2, 0.1, 1.0)
      end
    end
  end

  -- Message
  if message ~= "" then
    text_(message, C.SCREEN_W / 2 - #message * 3.5, C.SCREEN_H / 2 - 80, 1.0, 1.0, 0.6, 0.9)
  end
end
