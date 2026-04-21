--[[
  Physics Demo — Lurek2D
  Category: simulation

  A physics playground sandbox: spawn shapes, drag and throw them,
  toggle gravity/wind/slow-mo, place ramps, pin objects, and watch
  AABB collisions with configurable restitution.
]]

-- ───────────────────────── constants ─────────────────────────
local SCREEN_W       = 800
local SCREEN_H       = 600
local GRAVITY        = 400
local WIND_FORCE     = 50
local FRICTION       = 0.98
local GROUND_FRICTION = 0.92
local MAX_OBJECTS    = 200
local WALL_THICK     = 4

local RESTITUTION_LEVELS = { 0.3, 0.7, 1.0 }

-- ───────────────────────── state ─────────────────────────────
local state           = "TITLE"
local objects         = {}
local ramps           = {}
local particles       = {}

local gravity_on      = true
local wind_on         = false
local slow_mo         = false
local time_scale      = 1.0
local restitution_idx = 2
local spawn_type      = 1          -- 1=circle 2=rect 3=triangle

local dragging        = nil        -- index of dragged object
local drag_offset_x   = 0
local drag_offset_y   = 0
local prev_mouse_x    = 0
local prev_mouse_y    = 0
local throw_vx        = 0
local throw_vy        = 0

local title_timer     = 0

-- ───────────────────────── helpers ───────────────────────────
local function rand_range(lo, hi)
  return lo + math.random() * (hi - lo)
end

local function rand_color()
  return rand_range(0.35, 1.0), rand_range(0.35, 1.0), rand_range(0.35, 1.0)
end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function dist(x1, y1, x2, y2)
  local dx, dy = x2 - x1, y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

-- ───────────────────────── particles ─────────────────────────
local function spawn_particle(x, y, vx, vy, r, g, b, life)
  particles[#particles + 1] = {
    x = x, y = y, vx = vx, vy = vy,
    r = r, g = g, b = b, a = 1.0,
    life = life or 0.5, max_life = life or 0.5,
    size = rand_range(2, 5),
  }
end

local function spawn_poof(x, y)
  for _ = 1, 8 do
    local angle = math.random() * math.pi * 2
    local speed = rand_range(30, 80)
    spawn_particle(x, y, math.cos(angle) * speed, math.sin(angle) * speed,
                   1.0, 1.0, 1.0, 0.4)
  end
end

local function spawn_spark(x, y)
  for _ = 1, 4 do
    local angle = math.random() * math.pi * 2
    local speed = rand_range(50, 120)
    spawn_particle(x, y, math.cos(angle) * speed, math.sin(angle) * speed,
                   1.0, 0.8, 0.2, 0.25)
  end
end

local function spawn_trail(x, y, r, g, b)
  spawn_particle(x, y, rand_range(-5, 5), rand_range(-5, 5), r, g, b, 0.3)
end

local function update_particles(dt)
  local i = 1
  while i <= #particles do
    local p = particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    p.a = clamp(p.life / p.max_life, 0, 1)
    p.size = p.size * 0.97
    if p.life <= 0 then
      particles[i] = particles[#particles]
      particles[#particles] = nil
    else
      i = i + 1
    end
  end
end

-- ───────────────────────── objects ────────────────────────────
local function make_circle(x, y)
  local radius = rand_range(15, 30)
  local r, g, b = rand_color()
  return {
    shape = "circle", x = x, y = y, vx = 0, vy = 0,
    radius = radius, w = radius * 2, h = radius * 2,
    mass = radius * 0.5, r = r, g = g, b = b,
    pinned = false, on_ground = false,
  }
end

local function make_rect(x, y)
  local w = rand_range(20, 50)
  local h = rand_range(20, 50)
  local r, g, b = rand_color()
  return {
    shape = "rect", x = x, y = y, vx = 0, vy = 0,
    w = w, h = h, radius = math.min(w, h) * 0.5,
    mass = (w * h) * 0.01, r = r, g = g, b = b,
    pinned = false, on_ground = false,
  }
end

local function make_triangle(x, y)
  local size = rand_range(20, 40)
  local r, g, b = rand_color()
  return {
    shape = "triangle", x = x, y = y, vx = 0, vy = 0,
    w = size, h = size, radius = size * 0.5,
    mass = size * 0.3, r = r, g = g, b = b,
    pinned = false, on_ground = false,
    size = size,
  }
end

local function spawn_object(x, y)
  local obj
  if spawn_type == 1 then obj = make_circle(x, y)
  elseif spawn_type == 2 then obj = make_rect(x, y)
  else obj = make_triangle(x, y) end

  objects[#objects + 1] = obj
  spawn_poof(x, y)

  -- enforce max
  while #objects > MAX_OBJECTS do
    table.remove(objects, 1)
    if dragging and dragging > 1 then dragging = dragging - 1 end
  end
end

-- ───────────────────────── AABB helpers ──────────────────────
local function get_aabb(o)
  local hw, hh = o.w * 0.5, o.h * 0.5
  return o.x - hw, o.y - hh, o.x + hw, o.y + hh
end

local function aabb_overlap(a, b)
  local ax1, ay1, ax2, ay2 = get_aabb(a)
  local bx1, by1, bx2, by2 = get_aabb(b)
  return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end

local function resolve_collision(a, b)
  if a.pinned and b.pinned then return end
  local rest = RESTITUTION_LEVELS[restitution_idx]

  local ax1, ay1, ax2, ay2 = get_aabb(a)
  local bx1, by1, bx2, by2 = get_aabb(b)

  local ox = math.min(ax2 - bx1, bx2 - ax1)
  local oy = math.min(ay2 - by1, by2 - ay1)

  if ox <= 0 or oy <= 0 then return end

  spawn_spark((a.x + b.x) * 0.5, (a.y + b.y) * 0.5)

  local total_mass = a.mass + b.mass
  if total_mass == 0 then total_mass = 1 end

  if ox < oy then
    -- horizontal separation
    local sign = (a.x < b.x) and -1 or 1
    if not a.pinned and not b.pinned then
      a.x = a.x + sign * ox * (b.mass / total_mass)
      b.x = b.x - sign * ox * (a.mass / total_mass)
    elseif a.pinned then
      b.x = b.x - sign * ox
    else
      a.x = a.x + sign * ox
    end
    -- velocity exchange
    if not a.pinned then
      a.vx = -a.vx * rest + (b.pinned and 0 or b.vx * 0.1)
    end
    if not b.pinned then
      b.vx = -b.vx * rest + (a.pinned and 0 or a.vx * 0.1)
    end
  else
    -- vertical separation
    local sign = (a.y < b.y) and -1 or 1
    if not a.pinned and not b.pinned then
      a.y = a.y + sign * oy * (b.mass / total_mass)
      b.y = b.y - sign * oy * (a.mass / total_mass)
    elseif a.pinned then
      b.y = b.y - sign * oy
    else
      a.y = a.y + sign * oy
    end
    if not a.pinned then
      a.vy = -a.vy * rest + (b.pinned and 0 or b.vy * 0.1)
    end
    if not b.pinned then
      b.vy = -b.vy * rest + (a.pinned and 0 or a.vy * 0.1)
    end
  end
end

-- ───────────────────────── ramp collision ────────────────────
local function collide_with_ramps(o)
  if o.pinned then return end
  local rest = RESTITUTION_LEVELS[restitution_idx]
  for _, ramp in ipairs(ramps) do
    local rx, ry, rw, rh = ramp.x, ramp.y, ramp.w, ramp.h
    -- simple AABB check first
    local ox1, oy1, ox2, oy2 = get_aabb(o)
    if ox1 < rx + rw and ox2 > rx and oy1 < ry + rh and oy2 > ry then
      -- push out upward along ramp surface (simplified 45°)
      local rel_x = (o.x - rx) / rw
      local surface_y = ry + rh - rel_x * rh
      if o.y + o.h * 0.5 > surface_y then
        o.y = surface_y - o.h * 0.5
        -- deflect: convert downward into sideways
        local deflect = o.vy * 0.5
        o.vx = o.vx + deflect * (ramp.dir == "right" and 1 or -1)
        o.vy = -math.abs(o.vy) * rest * 0.5
        o.on_ground = true
        spawn_spark(o.x, surface_y)
      end
    end
  end
end

-- ───────────────────────── wall bounce ───────────────────────
local function wall_collide(o)
  if o.pinned then return end
  local rest = RESTITUTION_LEVELS[restitution_idx]
  local hw, hh = o.w * 0.5, o.h * 0.5

  o.on_ground = false
  if o.x - hw < WALL_THICK then
    o.x = WALL_THICK + hw
    o.vx = math.abs(o.vx) * rest
  end
  if o.x + hw > SCREEN_W - WALL_THICK then
    o.x = SCREEN_W - WALL_THICK - hw
    o.vx = -math.abs(o.vx) * rest
  end
  if o.y - hh < WALL_THICK then
    o.y = WALL_THICK + hh
    o.vy = math.abs(o.vy) * rest
  end
  if o.y + hh > SCREEN_H - WALL_THICK then
    o.y = SCREEN_H - WALL_THICK - hh
    o.vy = -math.abs(o.vy) * rest
    o.on_ground = true
  end
end

-- ───────────────────────── total energy ──────────────────────
local function total_energy()
  local ke = 0
  local pe = 0
  for _, o in ipairs(objects) do
    if not o.pinned then
      ke = ke + 0.5 * o.mass * (o.vx * o.vx + o.vy * o.vy)
      pe = pe + o.mass * GRAVITY * (SCREEN_H - o.y)
    end
  end
  return ke + pe
end

-- ───────────────────────── find object at point ──────────────
local function find_at(mx, my)
  for i = #objects, 1, -1 do
    local o = objects[i]
    if o.shape == "circle" then
      if dist(mx, my, o.x, o.y) <= o.radius then return i end
    else
      local hw, hh = o.w * 0.5, o.h * 0.5
      if mx >= o.x - hw and mx <= o.x + hw and my >= o.y - hh and my <= o.y + hh then
        return i
      end
    end
  end
  return nil
end

-- ═════════════════════════ CALLBACKS ═════════════════════════

lurek.init(function()
  lurek.window.setTitle("Physics Demo — Lurek2D")
  lurek.render.setBackgroundColor(0.08, 0.08, 0.1)

  -- shape selectors
  lurek.input.bind("key_1", function() spawn_type = 1 end)
  lurek.input.bind("key_2", function() spawn_type = 2 end)
  lurek.input.bind("key_3", function() spawn_type = 3 end)

  -- gravity toggle
  lurek.input.bind("key_g", function()
    gravity_on = not gravity_on
    lurek.tween.to({ time_scale }, 0.3, { [1] = time_scale })  -- pulse feel
  end)

  -- bounce cycle
  lurek.input.bind("key_b", function()
    restitution_idx = restitution_idx % #RESTITUTION_LEVELS + 1
  end)

  -- clear
  lurek.input.bind("key_c", function()
    objects = {}
    ramps = {}
    particles = {}
  end)

  -- slow-mo toggle
  lurek.input.bind("key_m", function()
    slow_mo = not slow_mo
    local target = slow_mo and 0.25 or 1.0
    lurek.tween.to(_G, 0.4, { time_scale = target })
  end)

  -- wind toggle
  lurek.input.bind("key_w", function()
    wind_on = not wind_on
  end)

  -- ramp placement
  lurek.input.bind("key_r", function()
    local mx, my = lurek.input.getMousePosition()
    ramps[#ramps + 1] = {
      x = mx - 40, y = my - 10, w = 80, h = 40,
      dir = (math.random() > 0.5) and "right" or "left",
    }
  end)

  -- pin nearest object
  lurek.input.bind("key_p", function()
    local mx, my = lurek.input.getMousePosition()
    local best_i, best_d = nil, math.huge
    for i, o in ipairs(objects) do
      local d = dist(mx, my, o.x, o.y)
      if d < best_d then best_i, best_d = i, d end
    end
    if best_i and best_d < 60 then
      objects[best_i].pinned = not objects[best_i].pinned
      objects[best_i].vx = 0
      objects[best_i].vy = 0
      spawn_poof(objects[best_i].x, objects[best_i].y)
    end
  end)

  -- mouse spawn / drag
  lurek.input.bind("mouse_1", function()
    if state == "TITLE" then
      state = "RUNNING"
      return
    end
    local mx, my = lurek.input.getMousePosition()
    local idx = find_at(mx, my)
    if idx then
      dragging = idx
      drag_offset_x = objects[idx].x - mx
      drag_offset_y = objects[idx].y - my
      prev_mouse_x = mx
      prev_mouse_y = my
    else
      spawn_object(mx, my)
    end
  end)

  -- quit
  lurek.input.bind("key_escape", function()
    lurek.event.quit()
  end)
end)

lurek.ready(function()
  lurek.camera.reset()
end)

-- ───────────────────────── process ───────────────────────────
lurek.process(function(dt)
  if state == "TITLE" then
    title_timer = title_timer + dt
    return
  end

  local sdt = dt * time_scale

  -- mouse release
  if dragging then
    if not lurek.input.isMouseDown(1) then
      local o = objects[dragging]
      if o and not o.pinned then
        o.vx = throw_vx
        o.vy = throw_vy
      end
      dragging = nil
    else
      local mx, my = lurek.input.getMousePosition()
      throw_vx = (mx - prev_mouse_x) / math.max(sdt, 0.001)
      throw_vy = (my - prev_mouse_y) / math.max(sdt, 0.001)
      throw_vx = clamp(throw_vx, -1200, 1200)
      throw_vy = clamp(throw_vy, -1200, 1200)
      if objects[dragging] then
        objects[dragging].x = mx + drag_offset_x
        objects[dragging].y = my + drag_offset_y
        objects[dragging].vx = 0
        objects[dragging].vy = 0
        spawn_trail(mx, my, objects[dragging].r, objects[dragging].g, objects[dragging].b)
      end
      prev_mouse_x = mx
      prev_mouse_y = my
    end
  end

  -- physics step
  for _, o in ipairs(objects) do
    if not o.pinned and (_ ~= dragging or not dragging) then
      -- gravity
      if gravity_on then
        o.vy = o.vy + GRAVITY * sdt
      end
      -- wind
      if wind_on then
        o.vx = o.vx + WIND_FORCE * sdt
      end
      -- integrate
      o.x = o.x + o.vx * sdt
      o.y = o.y + o.vy * sdt
      -- air friction
      o.vx = o.vx * FRICTION
      o.vy = o.vy * FRICTION
      -- ground friction
      if o.on_ground then
        o.vx = o.vx * GROUND_FRICTION
      end
    end
  end

  -- collisions (O(n²))
  for i = 1, #objects do
    for j = i + 1, #objects do
      if aabb_overlap(objects[i], objects[j]) then
        resolve_collision(objects[i], objects[j])
      end
    end
  end

  -- ramp collisions
  for _, o in ipairs(objects) do
    collide_with_ramps(o)
  end

  -- wall collisions
  for _, o in ipairs(objects) do
    wall_collide(o)
  end

  -- particles
  update_particles(sdt)
end)

-- ───────────────────────── render (world) ────────────────────
lurek.render(function()
  if state == "TITLE" then
    return
  end

  -- walls
  lurek.render.setColor(0.25, 0.25, 0.3, 1)
  lurek.render.drawRectFill(0, 0, SCREEN_W, WALL_THICK)
  lurek.render.drawRectFill(0, SCREEN_H - WALL_THICK, SCREEN_W, WALL_THICK)
  lurek.render.drawRectFill(0, 0, WALL_THICK, SCREEN_H)
  lurek.render.drawRectFill(SCREEN_W - WALL_THICK, 0, WALL_THICK, SCREEN_H)

  -- ramps
  for _, ramp in ipairs(ramps) do
    lurek.render.setColor(0.5, 0.4, 0.2, 0.9)
    if ramp.dir == "right" then
      lurek.render.drawTriangleFill(
        ramp.x, ramp.y + ramp.h,
        ramp.x + ramp.w, ramp.y + ramp.h,
        ramp.x + ramp.w, ramp.y
      )
    else
      lurek.render.drawTriangleFill(
        ramp.x, ramp.y,
        ramp.x, ramp.y + ramp.h,
        ramp.x + ramp.w, ramp.y + ramp.h
      )
    end
  end

  -- objects
  for i, o in ipairs(objects) do
    local a = o.pinned and 0.6 or 1.0
    lurek.render.setColor(o.r, o.g, o.b, a)

    if o.shape == "circle" then
      lurek.render.drawCircleFill(o.x, o.y, o.radius)
    elseif o.shape == "rect" then
      lurek.render.drawRectFill(o.x - o.w * 0.5, o.y - o.h * 0.5, o.w, o.h)
    elseif o.shape == "triangle" then
      local s = o.size
      lurek.render.drawTriangleFill(
        o.x, o.y - s * 0.5,
        o.x - s * 0.5, o.y + s * 0.5,
        o.x + s * 0.5, o.y + s * 0.5
      )
    end

    -- pinned indicator
    if o.pinned then
      lurek.render.setColor(1, 1, 1, 0.5)
      lurek.render.drawCircle(o.x, o.y, 5)
    end
  end

  -- particles
  for _, p in ipairs(particles) do
    lurek.render.setColor(p.r, p.g, p.b, p.a)
    lurek.render.drawCircleFill(p.x, p.y, p.size)
  end
end)

-- ───────────────────────── render_ui (HUD) ───────────────────
lurek.render_ui(function()
  if state == "TITLE" then
    -- title screen
    local pulse = 0.7 + 0.3 * math.sin(title_timer * 2.5)
    lurek.render.setColor(0.3, 0.7, 1.0, 1)
    lurek.render.drawText("PHYSICS DEMO", SCREEN_W * 0.5 - 120, SCREEN_H * 0.35, 36)
    lurek.render.setColor(0.8, 0.8, 0.8, pulse)
    lurek.render.drawText("PLAY WITH FORCES", SCREEN_W * 0.5 - 100, SCREEN_H * 0.5, 20)
    lurek.render.setColor(0.5, 0.5, 0.5, pulse * 0.8)
    lurek.render.drawText("Click to Start", SCREEN_W * 0.5 - 60, SCREEN_H * 0.62, 16)
    return
  end

  local fps = lurek.timer.getFPS()
  local energy = total_energy()
  local rest = RESTITUTION_LEVELS[restitution_idx]

  -- top-left stats
  lurek.render.setColor(1, 1, 1, 0.9)
  lurek.render.drawText(string.format("FPS: %d", fps), 10, 10, 14)
  lurek.render.drawText(string.format("Objects: %d / %d", #objects, MAX_OBJECTS), 10, 28, 14)
  lurek.render.drawText(string.format("Energy: %.0f", energy), 10, 46, 14)

  -- indicators
  local y = 70
  local function indicator(label, on, color_r, color_g, color_b)
    if on then
      lurek.render.setColor(color_r, color_g, color_b, 1)
    else
      lurek.render.setColor(0.4, 0.4, 0.4, 0.5)
    end
    lurek.render.drawText(label, 10, y, 13)
    y = y + 16
  end

  indicator(string.format("Gravity [G]: %s", gravity_on and "ON" or "OFF"), gravity_on, 0.3, 1, 0.3)
  indicator(string.format("Wind [W]: %s", wind_on and "ON" or "OFF"), wind_on, 0.3, 0.7, 1)
  indicator(string.format("Slow-Mo [M]: %s", slow_mo and "ON" or "OFF"), slow_mo, 1, 0.7, 0.3)
  indicator(string.format("Bounce [B]: %.1f", rest), true, 0.9, 0.9, 0.3)

  -- shape selector
  lurek.render.setColor(0.7, 0.7, 0.7, 0.8)
  lurek.render.drawText("Shape:", SCREEN_W - 180, 10, 14)
  local shapes = { "Circle[1]", "Rect[2]", "Tri[3]" }
  for i, name in ipairs(shapes) do
    if i == spawn_type then
      lurek.render.setColor(1, 1, 0.3, 1)
    else
      lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
    end
    lurek.render.drawText(name, SCREEN_W - 180 + (i - 1) * 60, 28, 13)
  end

  -- bottom help
  lurek.render.setColor(0.5, 0.5, 0.5, 0.5)
  lurek.render.drawText("R=Ramp  P=Pin  C=Clear  Click=Spawn/Drag  ESC=Quit", 10, SCREEN_H - 20, 12)
end)
