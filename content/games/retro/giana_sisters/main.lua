-- ============================================================================
-- Giana Sisters — Lurek2D
-- Category: retro
-- A side-scrolling platformer inspired by the 1987 C-64 classic.
-- Collect gems, stomp monsters, grab powerup stars, reach the exit.
-- ============================================================================

local TILE = 32
local COLS = 40
local ROWS = 14
local GRAVITY = 900
local JUMP_VEL = -500
local SPEED = 180
local SCROLL_FACTOR = 0.15
local STAR_DURATION = 5
local MAX_LIVES = 3

-- States
local TITLE = "TITLE"
local PLAYING = "PLAYING"
local LEVEL_COMPLETE = "LEVEL_COMPLETE"
local GAME_OVER = "GAME_OVER"

local state = TITLE
local score = 0
local lives = MAX_LIVES
local gem_count = 0
local current_level = 1
local level_timer = 0

-- Player
local player = { x = 0, y = 0, vx = 0, vy = 0, w = 24, h = 28, on_ground = false, alive = true, invincible = false, inv_timer = 0, facing = 1 }

-- Camera
local cam_x = 0

-- Particles / tweens
local particles = {}
local tweens = {}
local gem_pulse = 0
local flash_alpha = 0

-- Level data
local monsters = {}
local gems_map = {}
local blocks_map = {}
local stars = {}
local exit_pos = { x = 0, y = 0 }
local level_width = 0

-- Level definitions (40 cols x 14 rows each)
local levels = {
  {
    "1111111111111111111111111111111111111111",
    "1......................................1",
    "1......................................1",
    "1......................................1",
    "1...G..G..G....111.......G..G......E..1",
    "1..........1...........111111..11111..1",
    "1.111.............M.........1.........1",
    "1...........G.G.1111...G...1...G......1",
    "1......M..111..........111.....111....1",
    "1....1111.........M..........M........1",
    "1.........G..G..1111..G.G..1111.......1",
    "1....111111.........1111........111...1",
    "1.................................G....1",
    "1111111111111111111111111111111111111111",
  },
  {
    "1111111111111111111111111111111111111111",
    "1......................................1",
    "1..G...................................1",
    "1.111......G..G........................1",
    "1.........1111.....G.G.....111..G..E..1",
    "1...M...........111111..........1111..1",
    "1..1111....M.........1...M...........1",
    "1.........1111...G.G.....1111..G.G...1",
    "1....G.G......111111..........1111....1",
    "1...1111..M..........M..G............1",
    "1..........1111..G..1111..1111........1",
    "1.....111.......111.........1...111...1",
    "1......................................1",
    "1111111111111111111111111111111111111111",
  },
  {
    "1111111111111111111111111111111111111111",
    "1......................................1",
    "1......................................1",
    "1..G.G.G...........G.G................1",
    "1..111111..M....111111....G.G...E.....1",
    "1..........1111........111111..1111...1",
    "1...M..............M.......1..........1",
    "1..1111..G.G..1111..1111..1...G.G....1",
    "1........1111.........1.......1111....1",
    "1..G.G........M...G..........M.......1",
    "1.1111...1111.1111.1111..G..1111......1",
    "1.................111....111....111...1",
    "1......................................1",
    "1111111111111111111111111111111111111111",
  },
}

-- ============================================================================
-- Helpers
-- ============================================================================

local function tile_at(grid, col, row)
  if row < 1 or row > ROWS or col < 1 or col > COLS then return "1" end
  local line = grid[row]
  if not line then return "1" end
  local ch = line:sub(col, col)
  return ch
end

local function pixel_to_tile(px, py)
  return math.floor(px / TILE) + 1, math.floor(py / TILE) + 1
end

local function spawn_particles(x, y, count, r, g, b, life)
  for i = 1, count do
    particles[#particles + 1] = {
      x = x, y = y,
      vx = (math.random() - 0.5) * 200,
      vy = (math.random() - 0.5) * 200 - 50,
      life = life or 0.6,
      max_life = life or 0.6,
      r = r, g = g, b = b,
    }
  end
end

local function add_tween(target, field, from, to, duration, callback)
  tweens[#tweens + 1] = { target = target, field = field, from = from, to = to, duration = duration, elapsed = 0, callback = callback }
end

-- ============================================================================
-- Level loading
-- ============================================================================

local grid = {}

local function load_level(idx)
  local def = levels[idx]
  if not def then
    state = GAME_OVER
    return
  end
  grid = {}
  monsters = {}
  gems_map = {}
  blocks_map = {}
  stars = {}
  particles = {}
  tweens = {}
  gem_pulse = 0
  flash_alpha = 0

  for row = 1, ROWS do
    grid[row] = {}
    local line = def[row] or string.rep(".", COLS)
    for col = 1, COLS do
      local ch = line:sub(col, col)
      if ch == "G" then
        gems_map[row * 1000 + col] = { x = (col - 1) * TILE, y = (row - 1) * TILE, alive = true }
        grid[row][col] = "."
      elseif ch == "M" then
        monsters[#monsters + 1] = { x = (col - 1) * TILE, y = (row - 1) * TILE, w = 28, h = 28, vx = 60, alive = true }
        grid[row][col] = "."
      elseif ch == "E" then
        exit_pos = { x = (col - 1) * TILE, y = (row - 1) * TILE }
        grid[row][col] = "."
      elseif ch == "1" then
        blocks_map[row * 1000 + col] = true
        grid[row][col] = "1"
      else
        grid[row][col] = "."
      end
    end
  end

  level_width = COLS * TILE
  player.x = 2 * TILE
  player.y = 11 * TILE
  player.vx = 0
  player.vy = 0
  player.on_ground = false
  player.alive = true
  player.invincible = false
  player.inv_timer = 0
  player.facing = 1
  cam_x = 0
end

-- ============================================================================
-- Collision helpers
-- ============================================================================

local function is_solid(col, row)
  if col < 1 or col > COLS or row < 1 or row > ROWS then return true end
  return grid[row] and grid[row][col] == "1"
end

local function rect_overlap(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- ============================================================================
-- Callbacks
-- ============================================================================

lurek.window.setTitle("Giana Sisters — Lurek2D")
lurek.render.setBackgroundColor(0.1, 0.1, 0.3)

function lurek.init()
  load_level(1)
end

function lurek.process(dt)
  -- Global quit
  if lurek.input.keyboard.isDown("escape") then
    lurek.event.quit()
    return
  end

  -- ---- TITLE ----
  if state == TITLE then
    if lurek.input.keyboard.isDown("return") then
      state = PLAYING
      score = 0
      gem_count = 0
      lives = MAX_LIVES
      current_level = 1
      load_level(1)
    end
    return
  end

  -- ---- GAME OVER ----
  if state == GAME_OVER then
    if lurek.input.keyboard.isDown("return") then
      state = TITLE
    end
    return
  end

  -- ---- LEVEL COMPLETE ----
  if state == LEVEL_COMPLETE then
    level_timer = level_timer - dt
    if level_timer <= 0 then
      current_level = current_level + 1
      if current_level > #levels then
        state = GAME_OVER
      else
        load_level(current_level)
        state = PLAYING
      end
    end
    return
  end

  -- ---- PLAYING ----
  if not player.alive then return end

  -- Input
  local move_x = 0
  if lurek.input.isActionDown("a") or lurek.input.isActionDown("left") then move_x = move_x - 1 end
  if lurek.input.isActionDown("d") or lurek.input.isActionDown("right") then move_x = move_x + 1 end
  if move_x ~= 0 then player.facing = move_x end

  player.vx = move_x * SPEED
  if (lurek.input.keyboard.isDown("space") or lurek.input.keyboard.isDown("w") or lurek.input.keyboard.isDown("up")) and player.on_ground then
    player.vy = JUMP_VEL
    player.on_ground = false
  end

  -- Gravity
  player.vy = player.vy + GRAVITY * dt

  -- Move X
  local nx = player.x + player.vx * dt
  local left_col = math.floor(nx / TILE) + 1
  local right_col = math.floor((nx + player.w - 1) / TILE) + 1
  local top_row = math.floor(player.y / TILE) + 1
  local bot_row = math.floor((player.y + player.h - 1) / TILE) + 1
  local blocked_x = false
  for r = top_row, bot_row do
    if is_solid(left_col, r) or is_solid(right_col, r) then blocked_x = true; break end
  end
  if not blocked_x then player.x = nx end

  -- Move Y
  local ny = player.y + player.vy * dt
  local top_row2 = math.floor(ny / TILE) + 1
  local bot_row2 = math.floor((ny + player.h - 1) / TILE) + 1
  local left_col2 = math.floor(player.x / TILE) + 1
  local right_col2 = math.floor((player.x + player.w - 1) / TILE) + 1
  local blocked_y = false
  player.on_ground = false

  -- Check block hit from below (moving up)
  if player.vy < 0 then
    for c = left_col2, right_col2 do
      if is_solid(c, top_row2) then
        blocked_y = true
        player.vy = 0
        -- Break block or reveal star
        local key = top_row2 * 1000 + c
        if blocks_map[key] and top_row2 > 1 then
          -- 20% chance to spawn a star
          if math.random() < 0.2 then
            stars[#stars + 1] = {
              x = (c - 1) * TILE + TILE / 2,
              y = (top_row2 - 1) * TILE - TILE,
              vy = -200, vx = 80,
              alive = true, angle = 0,
            }
          end
          -- Break the block
          grid[top_row2][c] = "."
          blocks_map[key] = nil
          spawn_particles((c - 1) * TILE + TILE / 2, (top_row2 - 1) * TILE + TILE / 2, 8, 0.6, 0.4, 0.2, 0.5)
          score = score + 10
        end
        break
      end
    end
  end

  -- Check ground (moving down)
  if player.vy >= 0 then
    for c = left_col2, right_col2 do
      if is_solid(c, bot_row2) then
        blocked_y = true
        player.on_ground = true
        player.vy = 0
        player.y = (bot_row2 - 1) * TILE - player.h
        break
      end
    end
  end

  if not blocked_y then player.y = ny end

  -- Clamp player
  if player.x < 0 then player.x = 0 end
  if player.x + player.w > level_width then player.x = level_width - player.w end

  -- Invincibility timer
  if player.invincible then
    player.inv_timer = player.inv_timer - dt
    if player.inv_timer <= 0 then
      player.invincible = false
    end
  end

  -- Gem collection
  for k, gem in pairs(gems_map) do
    if gem.alive and rect_overlap(player.x, player.y, player.w, player.h, gem.x, gem.y, TILE, TILE) then
      gem.alive = false
      score = score + 50
      gem_count = gem_count + 1
      spawn_particles(gem.x + TILE / 2, gem.y + TILE / 2, 12, 1.0, 1.0, 0.2, 0.7)
      gem_pulse = 1.0
      add_tween(nil, "gem_pulse", 1.0, 0.0, 0.4)
    end
  end

  -- Monster update & collision
  for _, mon in ipairs(monsters) do
    if mon.alive then
      mon.x = mon.x + mon.vx * dt
      -- Turn at edges / walls
      local mc = math.floor((mon.x + mon.w / 2) / TILE) + 1
      local mr = math.floor((mon.y + mon.h) / TILE) + 1
      local ahead_col = mc
      if mon.vx > 0 then
        ahead_col = math.floor((mon.x + mon.w) / TILE) + 1
      else
        ahead_col = math.floor(mon.x / TILE) + 1
      end
      -- Wall ahead or no ground ahead
      if is_solid(ahead_col, math.floor(mon.y / TILE) + 1) or not is_solid(ahead_col, mr) then
        mon.vx = -mon.vx
      end

      -- Player collision
      if rect_overlap(player.x, player.y, player.w, player.h, mon.x, mon.y, mon.w, mon.h) then
        if player.invincible then
          -- Kill monster while invincible
          mon.alive = false
          score = score + 100
          spawn_particles(mon.x + mon.w / 2, mon.y + mon.h / 2, 10, 1.0, 0.3, 0.1, 0.6)
        elseif player.vy > 0 and player.y + player.h - mon.y < 16 then
          -- Stomp from above
          mon.alive = false
          player.vy = JUMP_VEL * 0.6
          score = score + 100
          spawn_particles(mon.x + mon.w / 2, mon.y + mon.h / 2, 10, 1.0, 0.3, 0.1, 0.6)
        else
          -- Side hit = death
          if not player.invincible then
            player.alive = false
            lives = lives - 1
            spawn_particles(player.x + player.w / 2, player.y + player.h / 2, 15, 0.3, 0.5, 1.0, 0.8)
            if lives <= 0 then
              state = GAME_OVER
            else
              -- Respawn after brief delay handled by alive check
              add_tween(nil, "respawn", 0, 1, 1.0, function()
                load_level(current_level)
              end)
            end
          end
        end
      end
    end
  end

  -- Star powerups
  for _, star in ipairs(stars) do
    if star.alive then
      star.x = star.x + star.vx * dt
      star.vy = star.vy + GRAVITY * 0.5 * dt
      star.y = star.y + star.vy * dt
      star.angle = star.angle + 360 * dt

      -- Bounce off ground
      local sr = math.floor((star.y + 16) / TILE) + 1
      local sc = math.floor(star.x / TILE) + 1
      if is_solid(sc, sr) then
        star.vy = -250
        star.y = (sr - 1) * TILE - 16
      end
      -- Bounce off walls
      if is_solid(math.floor((star.x + 16) / TILE) + 1, math.floor(star.y / TILE) + 1) or
         is_solid(math.floor((star.x - 4) / TILE) + 1, math.floor(star.y / TILE) + 1) then
        star.vx = -star.vx
      end
      -- Remove if off screen
      if star.y > ROWS * TILE + 100 or star.x < -50 or star.x > level_width + 50 then
        star.alive = false
      end

      -- Star trail particles
      if math.random() < 0.3 then
        spawn_particles(star.x, star.y, 1, 1.0, 1.0, 0.8, 0.3)
      end

      -- Player pickup
      if rect_overlap(player.x, player.y, player.w, player.h, star.x - 8, star.y - 8, 16, 16) then
        star.alive = false
        player.invincible = true
        player.inv_timer = STAR_DURATION
        score = score + 200
        spawn_particles(star.x, star.y, 20, 1.0, 1.0, 1.0, 0.8)
      end
    end
  end

  -- Exit check
  if rect_overlap(player.x, player.y, player.w, player.h, exit_pos.x, exit_pos.y, TILE, TILE) then
    state = LEVEL_COMPLETE
    level_timer = 2.0
    flash_alpha = 1.0
    add_tween(nil, "flash_alpha", 1.0, 0.0, 2.0)
    score = score + 500
  end

  -- Camera
  local target_cam = player.x - 400 + player.w / 2
  target_cam = math.max(0, math.min(target_cam, level_width - 800))
  cam_x = cam_x + (target_cam - cam_x) * SCROLL_FACTOR

  -- Update particles
  for i = #particles, 1, -1 do
    local p = particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy + 200 * dt
    p.life = p.life - dt
    if p.life <= 0 then table.remove(particles, i) end
  end

  -- Update tweens
  for i = #tweens, 1, -1 do
    local tw = tweens[i]
    tw.elapsed = tw.elapsed + dt
    local t = math.min(tw.elapsed / tw.duration, 1.0)
    local val = tw.from + (tw.to - tw.from) * t
    if tw.field == "gem_pulse" then gem_pulse = val
    elseif tw.field == "flash_alpha" then flash_alpha = val
    end
    if t >= 1.0 then
      if tw.callback then tw.callback() end
      table.remove(tweens, i)
    end
  end
end

-- ============================================================================
-- Render: world
-- ============================================================================

function lurek.draw()
  if state == TITLE or state == GAME_OVER then return end

  local ox = -math.floor(cam_x)

  -- Draw tiles
  for row = 1, ROWS do
    for col = 1, COLS do
      local tx = (col - 1) * TILE + ox
      local ty = (row - 1) * TILE
      if tx > -TILE and tx < 820 then
        if grid[row][col] == "1" then
          -- Solid block: brown/gray
          local shade = ((row + col) % 2 == 0) and 0.45 or 0.35
          lurek.render.rectangle(tx, ty, TILE, TILE, shade, 0.28, 0.14, 1)
          lurek.render.rectangle(tx + 2, ty + 2, TILE - 4, TILE - 4, shade + 0.1, 0.33, 0.18, 1)
        end
      end
    end
  end

  -- Draw exit (green arch)
  local ex = exit_pos.x + ox
  local ey = exit_pos.y
  lurek.render.rectangle(ex, ey, TILE, TILE, 0.1, 0.7, 0.2, 1)
  lurek.render.rectangle(ex + 4, ey + 4, TILE - 8, TILE - 8, 0.2, 0.9, 0.3, 1)
  lurek.render.rectangle(ex + 6, ey, TILE - 12, 6, 0.2, 0.9, 0.3, 1)

  -- Draw gems (yellow diamonds)
  for _, gem in pairs(gems_map) do
    if gem.alive then
      local gx = gem.x + ox + TILE / 2
      local gy = gem.y + TILE / 2
      local s = 10
      -- Approximate diamond with small rotated square
      lurek.render.rectangle(gx - s / 2, gy - s / 2, s, s, 1.0, 0.85, 0.1, 1)
      lurek.render.rectangle(gx - s / 4, gy - s / 4, s / 2, s / 2, 1.0, 1.0, 0.5, 1)
    end
  end

  -- Draw monsters (red/orange ovals approximated as rectangles)
  for _, mon in ipairs(monsters) do
    if mon.alive then
      local mx = mon.x + ox
      local my = mon.y
      -- Body
      lurek.render.rectangle(mx + 2, my + 2, mon.w - 4, mon.h - 4, 0.9, 0.25, 0.1, 1)
      lurek.render.rectangle(mx + 4, my + 4, mon.w - 8, mon.h - 8, 1.0, 0.4, 0.15, 1)
      -- Eyes
      lurek.render.rectangle(mx + 6, my + 6, 5, 5, 1, 1, 1, 1)
      lurek.render.rectangle(mx + 17, my + 6, 5, 5, 1, 1, 1, 1)
      lurek.render.rectangle(mx + 7, my + 8, 3, 3, 0, 0, 0, 1)
      lurek.render.rectangle(mx + 18, my + 8, 3, 3, 0, 0, 0, 1)
    end
  end

  -- Draw stars (white spinning shape)
  for _, star in ipairs(stars) do
    if star.alive then
      local sx = star.x + ox
      local sy = star.y
      local s = 12
      lurek.render.rectangle(sx - s / 2, sy - 2, s, 4, 1, 1, 0.8, 1)
      lurek.render.rectangle(sx - 2, sy - s / 2, 4, s, 1, 1, 0.8, 1)
      lurek.render.rectangle(sx - 3, sy - 3, 6, 6, 1, 1, 1, 1)
    end
  end

  -- Draw player (blue/pink rectangle)
  if player.alive then
    local px = player.x + ox
    local py = player.y
    local blink = player.invincible and (math.floor(player.inv_timer * 10) % 2 == 0)
    if not blink then
      -- Body
      local pr, pg, pb = 0.3, 0.5, 1.0
      if player.invincible then pr, pg, pb = 1.0, 0.8, 0.3 end
      lurek.render.rectangle(px, py, player.w, player.h, pr, pg, pb, 1)
      -- Hair (pink top)
      lurek.render.rectangle(px + 2, py, player.w - 4, 8, 1.0, 0.45, 0.6, 1)
      -- Face
      lurek.render.rectangle(px + 5, py + 10, 4, 4, 1, 1, 1, 1)
      lurek.render.rectangle(px + 15, py + 10, 4, 4, 1, 1, 1, 1)
      -- Feet
      lurek.render.rectangle(px + 2, py + player.h - 4, 8, 4, 0.2, 0.2, 0.6, 1)
      lurek.render.rectangle(px + 14, py + player.h - 4, 8, 4, 0.2, 0.2, 0.6, 1)
    end
  end

  -- Draw particles
  for _, p in ipairs(particles) do
    local alpha = p.life / p.max_life
    local ps = 3 + alpha * 3
    lurek.render.rectangle(p.x + ox - ps / 2, p.y - ps / 2, ps, ps, p.r, p.g, p.b, alpha)
  end

  -- Level complete flash overlay
  if flash_alpha > 0 then
    lurek.render.rectangle(0, 0, 800, 600, 1, 1, 1, flash_alpha * 0.5)
  end
end

-- ============================================================================
-- Render: UI
-- ============================================================================

function lurek.draw_ui()
  -- ---- TITLE SCREEN ----
  if state == TITLE then
    lurek.render.rectangle(0, 0, 800, 600, 0.05, 0.05, 0.2, 1)
    -- Title text background
    lurek.render.rectangle(100, 150, 600, 60, 0.2, 0.1, 0.4, 0.8)
    lurek.render.print("THE GREAT GIANA SISTERS", 160, 165, 28, 1.0, 0.85, 0.2, 1)
    lurek.render.print("A Lurek2D Retro Tribute", 260, 210, 16, 0.7, 0.7, 0.7, 1)

    -- Controls
    lurek.render.print("A/D or Arrows - Move", 280, 300, 16, 0.8, 0.8, 0.8, 1)
    lurek.render.print("Space/W/Up - Jump", 290, 325, 16, 0.8, 0.8, 0.8, 1)
    lurek.render.print("Stomp monsters from above!", 250, 365, 16, 1.0, 0.5, 0.3, 1)

    -- Blink prompt
    local blink = math.floor(lurek.timer.getTime() * 2) % 2 == 0
    if blink then
      lurek.render.print("PRESS ENTER TO START", 270, 440, 22, 1, 1, 1, 1)
    end

    -- Decorative gems
    for i = 0, 7 do
      local gx = 120 + i * 80
      lurek.render.rectangle(gx, 500, 10, 10, 1.0, 0.85, 0.1, 0.6)
    end
    return
  end

  -- ---- GAME OVER ----
  if state == GAME_OVER then
    lurek.render.rectangle(0, 0, 800, 600, 0.1, 0.0, 0.0, 0.85)
    lurek.render.print("GAME OVER", 280, 200, 36, 1.0, 0.2, 0.2, 1)
    lurek.render.print("Final Score: " .. score, 300, 280, 22, 1, 1, 1, 1)
    lurek.render.print("Levels Cleared: " .. (current_level - 1) .. " / " .. #levels, 270, 320, 18, 0.8, 0.8, 0.8, 1)
    local blink = math.floor(lurek.timer.getTime() * 2) % 2 == 0
    if blink then
      lurek.render.print("PRESS ENTER", 320, 420, 22, 1, 1, 1, 1)
    end
    return
  end

  -- ---- LEVEL COMPLETE ----
  if state == LEVEL_COMPLETE then
    lurek.render.rectangle(200, 200, 400, 120, 0.1, 0.3, 0.1, 0.9)
    lurek.render.print("LEVEL " .. current_level .. " COMPLETE!", 270, 230, 26, 0.2, 1.0, 0.3, 1)
    lurek.render.print("Score: " .. score, 330, 280, 20, 1, 1, 1, 1)
  end

  -- ---- HUD ----
  -- Background bar
  lurek.render.rectangle(0, 0, 800, 28, 0, 0, 0, 0.6)

  -- Score
  lurek.render.print("SCORE: " .. score, 10, 5, 18, 1, 1, 1, 1)

  -- Gems with pulse effect
  local gem_scale = 1.0 + gem_pulse * 0.3
  local gem_text_size = math.floor(18 * gem_scale)
  lurek.render.print("GEMS: " .. gem_count, 200, 5, gem_text_size, 1.0, 0.85, 0.1, 1)

  -- Level
  lurek.render.print("LEVEL: " .. current_level .. "/" .. #levels, 400, 5, 18, 0.6, 0.8, 1.0, 1)

  -- Lives
  lurek.render.print("LIVES: ", 580, 5, 18, 1, 1, 1, 1)
  for i = 1, lives do
    lurek.render.rectangle(648 + (i - 1) * 22, 6, 16, 16, 1.0, 0.45, 0.6, 1)
  end

  -- FPS
  local fps = lurek.timer.getFPS()
  lurek.render.print("FPS: " .. fps, 730, 5, 14, 0.5, 0.5, 0.5, 1)

  -- Invincibility indicator
  if player.invincible then
    local remaining = math.ceil(player.inv_timer)
    lurek.render.rectangle(300, 35, 200, 20, 0.2, 0.2, 0.0, 0.7)
    local bar_w = (player.inv_timer / STAR_DURATION) * 196
    lurek.render.rectangle(302, 37, bar_w, 16, 1.0, 0.9, 0.2, 0.9)
    lurek.render.print("STAR POWER " .. remaining .. "s", 340, 38, 14, 1, 1, 1, 1)
  end
end
