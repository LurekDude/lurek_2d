-- ============================================================================
-- Physics Sandbox — Lurek2D
-- ============================================================================
-- Category : simulation
-- Source   : content/games/simulation/physics_sandbox/main.lua
-- Run with : cargo run -- content/games/simulation/physics_sandbox
-- ============================================================================
-- Free-form physics playground: build structures, destroy them with
-- explosions, launch wrecking balls, toggle/redirect gravity, connect
-- objects with springs, and spawn preset shapes.
-- Controls: B build, D destroy, R rope, G gravity, Space launch,
--           1-4 shapes, C color, X clear, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local MAX_OBJECTS         = 300
local GRAVITY_STRENGTH    = 400
local FRICTION            = 0.98
local GROUND_FRICTION     = 0.90
local WALL_THICK          = 4
local EXPLOSION_RADIUS    = 200
local EXPLOSION_FORCE     = 500
local BALL_MASS           = 5
local BALL_SPEED          = 500
local SPRING_K            = 120
local SPRING_DAMP         = 4
local SPRING_REST         = 80

local STATE = { TITLE = 1, SANDBOX = 2 }
local MODE  = { BUILD = 1, DESTROY = 2, ROPE = 3 }

local BUILD_COLORS = {
    { 0.90, 0.25, 0.25 }, -- red
    { 0.25, 0.50, 0.90 }, -- blue
    { 0.25, 0.85, 0.35 }, -- green
    { 0.95, 0.85, 0.20 }, -- yellow
    { 0.90, 0.90, 0.90 }, -- white
}
local COLOR_NAMES = { "RED", "BLUE", "GREEN", "YELLOW", "WHITE" }

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local current_state = STATE.TITLE
local current_mode  = MODE.BUILD
local color_idx     = 1

local objects  = {}
local springs  = {}
local particles = {}

local gravity_on  = true
local gravity_dir = { x = 0, y = 1 } -- down
local gravity_target = { x = 0, y = 1 }
local gravity_label  = "DOWN"

local drag_start_x, drag_start_y = 0, 0
local dragging_build = false

local rope_first = nil -- index of first object for rope

local title_timer    = 0
local mode_flash     = 0
local mode_flash_text = ""

local obj_count_display = 0
local tween_gravity_t   = 0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function rand_range(lo, hi)
    return lo + math.random() * (hi - lo)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

-- ---------------------------------------------------------------------------
-- Particles
-- ---------------------------------------------------------------------------
local function spawn_particle(x, y, vx, vy, r, g, b, life, size)
    if #particles > 800 then return end
    particles[#particles + 1] = {
        x = x, y = y, vx = vx, vy = vy,
        r = r, g = g, b = b, a = 1.0,
        life = life or 0.5, max_life = life or 0.5,
        size = size or rand_range(2, 5),
    }
end

local function spawn_explosion(cx, cy)
    for _ = 1, 30 do
        local angle = math.random() * math.pi * 2
        local speed = rand_range(100, 300)
        local r, g = rand_range(0.8, 1.0), rand_range(0.3, 0.7)
        spawn_particle(cx, cy,
            math.cos(angle) * speed, math.sin(angle) * speed,
            r, g, 0.1, rand_range(0.3, 0.7), rand_range(3, 8))
    end
end

local function spawn_spark(x, y)
    for _ = 1, 5 do
        local angle = math.random() * math.pi * 2
        local speed = rand_range(40, 100)
        spawn_particle(x, y,
            math.cos(angle) * speed, math.sin(angle) * speed,
            1.0, 0.85, 0.2, 0.25, rand_range(1, 3))
    end
end

local function spawn_trail(x, y, r, g, b)
    spawn_particle(x, y,
        rand_range(-15, 15), rand_range(-15, 15),
        r, g, b, 0.35, rand_range(2, 4))
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x    = p.x + p.vx * dt
        p.y    = p.y + p.vy * dt
        p.life = p.life - dt
        p.a    = clamp(p.life / p.max_life, 0, 1)
        p.size = p.size * 0.97
        if p.life <= 0 then
            particles[i] = particles[#particles]
            particles[#particles] = nil
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Objects
-- ---------------------------------------------------------------------------
local function make_object(x, y, w, h, mass, r, g, b, is_static, restitution)
    return {
        x = x, y = y, vx = 0, vy = 0,
        w = w, h = h, mass = mass,
        r = r, g = g, b = b,
        is_static = is_static or false,
        restitution = restitution or 0.4,
        on_ground = false,
    }
end

local function add_object(obj)
    objects[#objects + 1] = obj
    while #objects > MAX_OBJECTS do
        table.remove(objects, 1)
    end
end

-- Preset shapes
local function spawn_small_circle(x, y)
    local o = make_object(x, y, 16, 16, 1, 0.7, 0.7, 0.9, false, 0.5)
    o.shape = "circle"
    add_object(o)
end

local function spawn_medium_rect(x, y)
    local o = make_object(x, y, 36, 24, 3, 0.6, 0.85, 0.6, false, 0.3)
    o.shape = "rect"
    add_object(o)
end

local function spawn_heavy_square(x, y)
    local o = make_object(x, y, 32, 32, 8, 0.85, 0.5, 0.3, false, 0.2)
    o.shape = "rect"
    add_object(o)
end

local function spawn_bouncy_ball(x, y)
    local o = make_object(x, y, 20, 20, 2, 1.0, 0.4, 0.8, false, 1.0)
    o.shape = "circle"
    add_object(o)
end

-- ---------------------------------------------------------------------------
-- AABB Collision
-- ---------------------------------------------------------------------------
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
    if a.is_static and b.is_static then return end

    local ax1, ay1, ax2, ay2 = get_aabb(a)
    local bx1, by1, bx2, by2 = get_aabb(b)

    local ox = math.min(ax2 - bx1, bx2 - ax1)
    local oy = math.min(ay2 - by1, by2 - ay1)
    if ox <= 0 or oy <= 0 then return end

    local rest = math.min(a.restitution, b.restitution)
    local total_mass = a.mass + b.mass
    if total_mass == 0 then total_mass = 1 end

    spawn_spark((a.x + b.x) * 0.5, (a.y + b.y) * 0.5)

    if ox < oy then
        local sign = (a.x < b.x) and -1 or 1
        if not a.is_static and not b.is_static then
            a.x = a.x + sign * ox * (b.mass / total_mass)
            b.x = b.x - sign * ox * (a.mass / total_mass)
        elseif a.is_static then
            b.x = b.x - sign * ox
        else
            a.x = a.x + sign * ox
        end
        if not a.is_static then
            a.vx = -a.vx * rest + (b.is_static and 0 or b.vx * 0.1)
        end
        if not b.is_static then
            b.vx = -b.vx * rest + (a.is_static and 0 or a.vx * 0.1)
        end
    else
        local sign = (a.y < b.y) and -1 or 1
        if not a.is_static and not b.is_static then
            a.y = a.y + sign * oy * (b.mass / total_mass)
            b.y = b.y - sign * oy * (a.mass / total_mass)
        elseif a.is_static then
            b.y = b.y - sign * oy
        else
            a.y = a.y + sign * oy
        end
        if not a.is_static then
            a.vy = -a.vy * rest + (b.is_static and 0 or b.vy * 0.1)
        end
        if not b.is_static then
            b.vy = -b.vy * rest + (a.is_static and 0 or a.vy * 0.1)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Springs
-- ---------------------------------------------------------------------------
local function update_springs(dt)
    local i = 1
    while i <= #springs do
        local s = springs[i]
        local a, b = s.a, s.b
        -- validate both still exist
        local a_ok, b_ok = false, false
        for _, o in ipairs(objects) do
            if o == a then a_ok = true end
            if o == b then b_ok = true end
        end
        if not a_ok or not b_ok then
            springs[i] = springs[#springs]
            springs[#springs] = nil
        else
            local dx = b.x - a.x
            local dy = b.y - a.y
            local d  = math.sqrt(dx * dx + dy * dy)
            if d > 0.001 then
                local nx, ny = dx / d, dy / d
                local stretch = d - SPRING_REST
                local force   = SPRING_K * stretch
                -- damping
                local rel_vx = b.vx - a.vx
                local rel_vy = b.vy - a.vy
                local damp   = SPRING_DAMP * (rel_vx * nx + rel_vy * ny)
                local fx = (force + damp) * nx
                local fy = (force + damp) * ny
                if not a.is_static then
                    a.vx = a.vx + fx * dt / a.mass
                    a.vy = a.vy + fy * dt / a.mass
                end
                if not b.is_static then
                    b.vx = b.vx - fx * dt / b.mass
                    b.vy = b.vy - fy * dt / b.mass
                end
            end
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Physics step
-- ---------------------------------------------------------------------------
local function physics_update(dt)
    -- gravity
    local gx = gravity_dir.x * GRAVITY_STRENGTH
    local gy = gravity_dir.y * GRAVITY_STRENGTH

    for _, o in ipairs(objects) do
        if not o.is_static then
            if gravity_on then
                o.vx = o.vx + gx * dt
                o.vy = o.vy + gy * dt
            end
            o.vx = o.vx * FRICTION
            o.vy = o.vy * FRICTION
            o.x  = o.x + o.vx * dt
            o.y  = o.y + o.vy * dt

            -- wall bounds
            local hw, hh = o.w * 0.5, o.h * 0.5
            if o.x - hw < WALL_THICK then
                o.x = WALL_THICK + hw
                o.vx = math.abs(o.vx) * o.restitution
            end
            if o.x + hw > SCREEN_W - WALL_THICK then
                o.x = SCREEN_W - WALL_THICK - hw
                o.vx = -math.abs(o.vx) * o.restitution
            end
            if o.y - hh < WALL_THICK then
                o.y = WALL_THICK + hh
                o.vy = math.abs(o.vy) * o.restitution
            end
            if o.y + hh > SCREEN_H - WALL_THICK then
                o.y = SCREEN_H - WALL_THICK - hh
                o.vy = -math.abs(o.vy) * o.restitution
                o.vx = o.vx * GROUND_FRICTION
                o.on_ground = true
            else
                o.on_ground = false
            end
        end
    end

    -- object–object collisions (O(n²) but fine for 300)
    for i = 1, #objects do
        for j = i + 1, #objects do
            if aabb_overlap(objects[i], objects[j]) then
                resolve_collision(objects[i], objects[j])
            end
        end
    end

    update_springs(dt)
end

-- ---------------------------------------------------------------------------
-- Explosion
-- ---------------------------------------------------------------------------
local function apply_explosion(cx, cy)
    spawn_explosion(cx, cy)
    for _, o in ipairs(objects) do
        if not o.is_static then
            local d = dist(cx, cy, o.x, o.y)
            if d < EXPLOSION_RADIUS and d > 0.01 then
                local strength = EXPLOSION_FORCE * (1.0 - d / EXPLOSION_RADIUS)
                local nx = (o.x - cx) / d
                local ny = (o.y - cy) / d
                o.vx = o.vx + nx * strength
                o.vy = o.vy + ny * strength
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Ball launcher
-- ---------------------------------------------------------------------------
local function launch_ball(mx, my)
    local sx = 20
    local sy = SCREEN_H * 0.5
    local dx, dy = mx - sx, my - sy
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 1 then d = 1 end
    local nx, ny = dx / d, dy / d

    local ball = make_object(sx, sy, 28, 28, BALL_MASS, 0.95, 0.6, 0.15, false, 0.6)
    ball.shape = "circle"
    ball.vx = nx * BALL_SPEED
    ball.vy = ny * BALL_SPEED
    add_object(ball)

    -- launch trail
    for k = 1, 10 do
        local t = k / 10
        spawn_trail(sx + nx * 20 * t, sy + ny * 20 * t, 0.95, 0.6, 0.15)
    end
end

-- ---------------------------------------------------------------------------
-- Find object at point
-- ---------------------------------------------------------------------------
local function object_at(px, py)
    for i, o in ipairs(objects) do
        local hw, hh = o.w * 0.5, o.h * 0.5
        if px >= o.x - hw and px <= o.x + hw and py >= o.y - hh and py <= o.y + hh then
            return i
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Flash mode indicator
-- ---------------------------------------------------------------------------
local function flash_mode(text)
    mode_flash = 1.0
    mode_flash_text = text
end

-- ---------------------------------------------------------------------------
-- Gravity direction tweening
-- ---------------------------------------------------------------------------
local function set_gravity_dir(gx, gy, label)
    gravity_target.x = gx
    gravity_target.y = gy
    gravity_label = label
    tween_gravity_t = 0
end

local function update_gravity_tween(dt)
    if tween_gravity_t < 1.0 then
        tween_gravity_t = math.min(tween_gravity_t + dt * 4, 1.0)
        -- ease-out quad
        local t = 1.0 - (1.0 - tween_gravity_t) * (1.0 - tween_gravity_t)
        gravity_dir.x = lerp(gravity_dir.x, gravity_target.x, t)
        gravity_dir.y = lerp(gravity_dir.y, gravity_target.y, t)
    end
end

-- ---------------------------------------------------------------------------
-- Input bindings
-- ---------------------------------------------------------------------------
lurek.input.bind("build",    "b")
lurek.input.bind("destroy",  "d")
lurek.input.bind("gravity",  "g")
lurek.input.bind("rope",     "r")
lurek.input.bind("clear",    "x")
lurek.input.bind("shape1",   "1")
lurek.input.bind("shape2",   "2")
lurek.input.bind("shape3",   "3")
lurek.input.bind("shape4",   "4")
lurek.input.bind("launch",   "space")
lurek.input.bind("color",    "c")
lurek.input.bind("place",    "mouse1")
lurek.input.bind("quit",     "escape")
lurek.input.bind("grav_up",    "up")
lurek.input.bind("grav_down",  "down")
lurek.input.bind("grav_left",  "left")
lurek.input.bind("grav_right", "right")
lurek.input.bind("confirm",    "return")

-- ---------------------------------------------------------------------------
-- Callbacks
-- ---------------------------------------------------------------------------
lurek.init(function()
    lurek.window.setTitle("Physics Sandbox — Lurek2D")
    lurek.window.setBackgroundColor(0.06, 0.06, 0.08)
end)

lurek.ready(function()
    title_timer = 0
end)

-- ---------------------------------------------------------------------------
-- Process: TITLE
-- ---------------------------------------------------------------------------
local function process_title(dt)
    title_timer = title_timer + dt
    if lurek.input.wasActionPressed("confirm") or lurek.input.wasActionPressed("place") then
        current_state = STATE.SANDBOX
        flash_mode("BUILD")
    end
end

-- ---------------------------------------------------------------------------
-- Process: SANDBOX
-- ---------------------------------------------------------------------------
local function process_sandbox(dt)
    local mx, my = lurek.input.getMousePosition()

    -- mode switches
    if lurek.input.wasActionPressed("build") then
        current_mode = MODE.BUILD
        rope_first = nil
        flash_mode("BUILD")
    end
    if lurek.input.wasActionPressed("destroy") then
        current_mode = MODE.DESTROY
        rope_first = nil
        flash_mode("DESTROY")
    end
    if lurek.input.wasActionPressed("rope") then
        current_mode = MODE.ROPE
        rope_first = nil
        flash_mode("ROPE")
    end

    -- gravity toggle
    if lurek.input.wasActionPressed("gravity") then
        gravity_on = not gravity_on
        flash_mode(gravity_on and "GRAVITY ON" or "GRAVITY OFF")
    end

    -- gravity direction
    if lurek.input.wasActionPressed("grav_up") then
        set_gravity_dir(0, -1, "UP")
        flash_mode("GRAVITY: UP")
    end
    if lurek.input.wasActionPressed("grav_down") then
        set_gravity_dir(0, 1, "DOWN")
        flash_mode("GRAVITY: DOWN")
    end
    if lurek.input.wasActionPressed("grav_left") then
        set_gravity_dir(-1, 0, "LEFT")
        flash_mode("GRAVITY: LEFT")
    end
    if lurek.input.wasActionPressed("grav_right") then
        set_gravity_dir(1, 0, "RIGHT")
        flash_mode("GRAVITY: RIGHT")
    end

    -- color cycle
    if lurek.input.wasActionPressed("color") then
        color_idx = color_idx % #BUILD_COLORS + 1
        flash_mode("COLOR: " .. COLOR_NAMES[color_idx])
    end

    -- clear
    if lurek.input.wasActionPressed("clear") then
        objects  = {}
        springs  = {}
        particles = {}
        rope_first = nil
        flash_mode("CLEARED")
    end

    -- shape spawns
    if lurek.input.wasActionPressed("shape1") then spawn_small_circle(mx, my) end
    if lurek.input.wasActionPressed("shape2") then spawn_medium_rect(mx, my) end
    if lurek.input.wasActionPressed("shape3") then spawn_heavy_square(mx, my) end
    if lurek.input.wasActionPressed("shape4") then spawn_bouncy_ball(mx, my) end

    -- ball launcher
    if lurek.input.wasActionPressed("launch") then
        launch_ball(mx, my)
    end

    -- BUILD mode: drag to create rectangles
    if current_mode == MODE.BUILD then
        if lurek.input.wasActionPressed("place") then
            drag_start_x = mx
            drag_start_y = my
            dragging_build = true
        end
        if dragging_build and not lurek.input.isActionDown("place") then
            dragging_build = false
            local x1 = math.min(drag_start_x, mx)
            local y1 = math.min(drag_start_y, my)
            local x2 = math.max(drag_start_x, mx)
            local y2 = math.max(drag_start_y, my)
            local w = x2 - x1
            local h = y2 - y1
            if w > 4 and h > 4 then
                local col = BUILD_COLORS[color_idx]
                local is_static = lurek.input.isKeyDown("lshift") or lurek.input.isKeyDown("rshift")
                local mass = is_static and 0 or (w * h * 0.005)
                local o = make_object(x1 + w * 0.5, y1 + h * 0.5, w, h, mass,
                                      col[1], col[2], col[3], is_static, 0.3)
                o.shape = "rect"
                add_object(o)
            end
        end
    end

    -- DESTROY mode: click to explode
    if current_mode == MODE.DESTROY then
        if lurek.input.wasActionPressed("place") then
            apply_explosion(mx, my)
        end
    end

    -- ROPE mode: click two objects to connect
    if current_mode == MODE.ROPE then
        if lurek.input.wasActionPressed("place") then
            local idx = object_at(mx, my)
            if idx then
                if rope_first == nil then
                    rope_first = idx
                    flash_mode("ROPE: SELECT 2ND")
                else
                    if idx ~= rope_first then
                        springs[#springs + 1] = { a = objects[rope_first], b = objects[idx] }
                        flash_mode("ROPE CONNECTED")
                    end
                    rope_first = nil
                end
            end
        end
    end

    -- quit
    if lurek.input.wasActionPressed("quit") then
        lurek.signal.quit()
    end

    -- physics
    physics_update(dt)
    update_gravity_tween(dt)
    update_particles(dt)

    -- mode flash decay
    if mode_flash > 0 then
        mode_flash = mode_flash - dt * 2.5
        if mode_flash < 0 then mode_flash = 0 end
    end

    -- smooth object count for HUD
    obj_count_display = obj_count_display + (#objects - obj_count_display) * dt * 8
end

-- ---------------------------------------------------------------------------
-- Process dispatch
-- ---------------------------------------------------------------------------
lurek.process(function(dt)
    if current_state == STATE.TITLE then
        process_title(dt)
    elseif current_state == STATE.SANDBOX then
        process_sandbox(dt)
    end
end)

-- ---------------------------------------------------------------------------
-- Render: TITLE
-- ---------------------------------------------------------------------------
local function render_title()
    local pulse = 0.5 + 0.5 * math.sin(title_timer * 3)

    lurek.render.drawText("PHYSICS SANDBOX", SCREEN_W * 0.5 - 140, 180,
        { r = 0.3 + 0.7 * pulse, g = 0.5 + 0.5 * pulse, b = 1.0, size = 32 })
    lurek.render.drawText("BUILD AND DESTROY", SCREEN_W * 0.5 - 110, 230,
        { r = 0.8, g = 0.8, b = 0.8, size = 18 })

    lurek.render.drawText("[B] Build   [D] Destroy   [R] Rope",
        SCREEN_W * 0.5 - 160, 310, { r = 0.6, g = 0.6, b = 0.6, size = 14 })
    lurek.render.drawText("[1-4] Shapes   [Space] Launch Ball",
        SCREEN_W * 0.5 - 150, 335, { r = 0.6, g = 0.6, b = 0.6, size = 14 })
    lurek.render.drawText("[G] Gravity   [Arrows] Direction   [C] Color",
        SCREEN_W * 0.5 - 185, 360, { r = 0.6, g = 0.6, b = 0.6, size = 14 })

    local blink = pulse > 0.5 and 1.0 or 0.4
    lurek.render.drawText("Click or press Enter to start",
        SCREEN_W * 0.5 - 120, 440, { r = blink, g = blink, b = blink, size = 14 })
end

-- ---------------------------------------------------------------------------
-- Render: SANDBOX objects + ropes + particles
-- ---------------------------------------------------------------------------
local function render_sandbox()
    -- walls
    lurek.render.drawRectFill(0, 0, SCREEN_W, WALL_THICK, { r = 0.2, g = 0.2, b = 0.25 })
    lurek.render.drawRectFill(0, SCREEN_H - WALL_THICK, SCREEN_W, WALL_THICK, { r = 0.2, g = 0.2, b = 0.25 })
    lurek.render.drawRectFill(0, 0, WALL_THICK, SCREEN_H, { r = 0.2, g = 0.2, b = 0.25 })
    lurek.render.drawRectFill(SCREEN_W - WALL_THICK, 0, WALL_THICK, SCREEN_H, { r = 0.2, g = 0.2, b = 0.25 })

    -- springs (ropes)
    for _, s in ipairs(springs) do
        lurek.render.drawLine(s.a.x, s.a.y, s.b.x, s.b.y,
            { r = 0.6, g = 0.9, b = 0.4, width = 2 })
    end

    -- objects
    for _, o in ipairs(objects) do
        local alpha = o.is_static and 0.85 or 1.0
        if o.shape == "circle" then
            lurek.render.drawCircleFill(o.x, o.y, o.w * 0.5,
                { r = o.r, g = o.g, b = o.b, a = alpha })
        else
            lurek.render.drawRectFill(o.x - o.w * 0.5, o.y - o.h * 0.5, o.w, o.h,
                { r = o.r, g = o.g, b = o.b, a = alpha })
        end
        -- static indicator: small diamond
        if o.is_static then
            lurek.render.drawRectFill(o.x - 3, o.y - 3, 6, 6,
                { r = 1.0, g = 1.0, b = 1.0, a = 0.6 })
        end
    end

    -- particles
    for _, p in ipairs(particles) do
        lurek.render.drawRectFill(p.x - p.size * 0.5, p.y - p.size * 0.5,
            p.size, p.size,
            { r = p.r, g = p.g, b = p.b, a = p.a })
    end

    -- build mode drag preview
    if current_mode == MODE.BUILD and dragging_build then
        local mx, my = lurek.input.getMousePosition()
        local x1 = math.min(drag_start_x, mx)
        local y1 = math.min(drag_start_y, my)
        local x2 = math.max(drag_start_x, mx)
        local y2 = math.max(drag_start_y, my)
        local col = BUILD_COLORS[color_idx]
        lurek.render.drawRectFill(x1, y1, x2 - x1, y2 - y1,
            { r = col[1], g = col[2], b = col[3], a = 0.35 })
        lurek.render.drawRect(x1, y1, x2 - x1, y2 - y1,
            { r = col[1], g = col[2], b = col[3], a = 0.8 })
    end

    -- destroy mode cursor indicator
    if current_mode == MODE.DESTROY then
        local mx, my = lurek.input.getMousePosition()
        lurek.render.drawCircle(mx, my, EXPLOSION_RADIUS,
            { r = 1.0, g = 0.3, b = 0.2, a = 0.15 })
        lurek.render.drawCircle(mx, my, 8,
            { r = 1.0, g = 0.5, b = 0.3, a = 0.7 })
    end

    -- rope mode indicator
    if current_mode == MODE.ROPE and rope_first then
        local mx, my = lurek.input.getMousePosition()
        local a = objects[rope_first]
        if a then
            lurek.render.drawLine(a.x, a.y, mx, my,
                { r = 0.4, g = 0.9, b = 0.4, a = 0.5, width = 1 })
        end
    end
end

-- ---------------------------------------------------------------------------
-- Render dispatch
-- ---------------------------------------------------------------------------
lurek.render(function()
    if current_state == STATE.TITLE then
        render_title()
    elseif current_state == STATE.SANDBOX then
        render_sandbox()
    end
end)

-- ---------------------------------------------------------------------------
-- Render UI (HUD overlay)
-- ---------------------------------------------------------------------------
lurek.render_ui(function()
    if current_state ~= STATE.SANDBOX then return end

    local fps = lurek.time.getFPS()
    local count = math.floor(obj_count_display + 0.5)
    local spring_count = #springs

    -- top-left info
    lurek.render.drawText(string.format("FPS: %d", fps),
        10, 10, { r = 0.5, g = 0.5, b = 0.5, size = 12 })
    lurek.render.drawText(string.format("Objects: %d / %d", count, MAX_OBJECTS),
        10, 26, { r = 0.6, g = 0.8, b = 0.6, size = 12 })
    if spring_count > 0 then
        lurek.render.drawText(string.format("Springs: %d", spring_count),
            10, 42, { r = 0.6, g = 0.9, b = 0.4, size = 12 })
    end

    -- mode indicator (top-right)
    local mode_names = { [MODE.BUILD] = "BUILD", [MODE.DESTROY] = "DESTROY", [MODE.ROPE] = "ROPE" }
    local mode_colors = {
        [MODE.BUILD]   = { 0.3, 0.6, 1.0 },
        [MODE.DESTROY] = { 1.0, 0.35, 0.2 },
        [MODE.ROPE]    = { 0.4, 0.9, 0.4 },
    }
    local mc = mode_colors[current_mode]
    lurek.render.drawText("MODE: " .. mode_names[current_mode],
        SCREEN_W - 150, 10, { r = mc[1], g = mc[2], b = mc[3], size = 14 })

    -- build color indicator
    if current_mode == MODE.BUILD then
        local col = BUILD_COLORS[color_idx]
        lurek.render.drawRectFill(SCREEN_W - 150, 30, 14, 14,
            { r = col[1], g = col[2], b = col[3] })
        lurek.render.drawText(COLOR_NAMES[color_idx],
            SCREEN_W - 130, 31, { r = 0.7, g = 0.7, b = 0.7, size = 12 })
    end

    -- gravity indicator
    local grav_text = gravity_on and ("GRAVITY: " .. gravity_label) or "GRAVITY: OFF"
    local grav_col = gravity_on and { 0.7, 0.7, 0.3 } or { 0.4, 0.4, 0.4 }
    lurek.render.drawText(grav_text,
        SCREEN_W - 150, 50, { r = grav_col[1], g = grav_col[2], b = grav_col[3], size = 12 })

    -- mode flash overlay
    if mode_flash > 0 then
        lurek.render.drawText(mode_flash_text,
            SCREEN_W * 0.5 - #mode_flash_text * 5, SCREEN_H * 0.5 - 20,
            { r = 1.0, g = 1.0, b = 1.0, a = mode_flash, size = 28 })
    end

    -- bottom help bar
    lurek.render.drawRectFill(0, SCREEN_H - 22, SCREEN_W, 22,
        { r = 0.0, g = 0.0, b = 0.0, a = 0.5 })
    lurek.render.drawText(
        "[B]uild  [D]estroy  [R]ope  [1-4]Shapes  [Space]Ball  [G]ravity  [Arrows]Dir  [C]olor  [X]Clear",
        8, SCREEN_H - 18, { r = 0.5, g = 0.5, b = 0.5, size = 11 })
end)
