-- ============================================================================
-- Cannon Fodder — Lurek2D
-- Category: retro
-- A squad-based top-down shooter inspired by Sensible Software's 1993 classic.
-- Command soldiers through jungle missions, eliminate enemies, reach the flag.
-- ============================================================================
-- Controls:
--   WASD        — Move squad direction
--   Space       — Fire (all living soldiers shoot)
--   G           — Throw grenade (3 per mission)
--   Escape      — Quit
-- ============================================================================

local STATE = { TITLE = 1, PLAYING = 2, MISSION_COMPLETE = 3, GAME_OVER = 4 }
local state = STATE.TITLE

-- World / camera
local world_w, world_h = 800, 2400
local cam_x, cam_y = 0, 0
local scroll_speed = 3

-- Squad
local soldiers = {}
local squad_target_dx, squad_target_dy = 0, 0
local squad_speed = 120
local facing_angle = -math.pi / 2  -- up

-- Enemies
local enemies = {}
local enemy_speed = 40
local enemy_detect_range = 220
local enemy_fire_cooldown = 1.2

-- Bullets
local bullets = {}
local bullet_speed = 320
local fire_cooldown = 0.18
local fire_timer = 0

-- Grenades
local grenades = {}
local grenade_count = 0
local grenade_radius = 60
local grenade_speed = 200
local grenade_fuse = 0.8

-- Trees
local trees = {}

-- Flag
local flag = { x = 0, y = 0 }

-- Particles
local particles = {}

-- Tweens
local tweens = {}

-- Missions
local missions = { 6, 10, 14, 18, 22 }
local current_mission = 1
local enemies_remaining = 0

-- Score
local score = 0
local mission_banner_alpha = 0
local flash_alpha = 0

-- Timers
local mission_complete_timer = 0
local title_blink_timer = 0

-- ============================================================================
-- Helpers
-- ============================================================================
local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function normalize(dx, dy)
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return 0, 0 end
    return dx / len, dy / len
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function rand_range(lo, hi)
    return lo + math.random() * (hi - lo)
end

local function add_tween(target, field, from, to, duration, on_done)
    table.insert(tweens, {
        target = target, field = field,
        from = from, to = to,
        duration = duration, elapsed = 0,
        on_done = on_done
    })
end

local function spawn_particles(x, y, count, r, g, b, life, spd)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = rand_range(spd * 0.3, spd)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = rand_range(life * 0.5, life),
            max_life = life,
            r = r + rand_range(-0.1, 0.1),
            g = g + rand_range(-0.1, 0.1),
            b = b + rand_range(-0.1, 0.1),
            size = rand_range(2, 5)
        })
    end
end

-- ============================================================================
-- Init mission
-- ============================================================================
local function init_soldiers()
    soldiers = {}
    for i = 1, 3 do
        table.insert(soldiers, {
            x = world_w / 2 + (i - 2) * 18,
            y = world_h - 120,
            alive = true,
            radius = 6
        })
    end
end

local function generate_trees()
    trees = {}
    for i = 1, 60 do
        local tx = rand_range(40, world_w - 40)
        local ty = rand_range(80, world_h - 200)
        table.insert(trees, { x = tx, y = ty, radius = rand_range(12, 22) })
    end
end

local function spawn_enemies(count)
    enemies = {}
    for i = 1, count do
        local ex = rand_range(60, world_w - 60)
        local ey = rand_range(60, world_h * 0.6)
        local patrol_cx, patrol_cy = ex, ey
        table.insert(enemies, {
            x = ex, y = ey,
            alive = true,
            radius = 6,
            patrol_cx = patrol_cx, patrol_cy = patrol_cy,
            patrol_angle = math.random() * math.pi * 2,
            patrol_radius = rand_range(30, 80),
            fire_timer = rand_range(0, enemy_fire_cooldown),
            hp = 1
        })
    end
    enemies_remaining = count
end

local function start_mission(mission_num)
    current_mission = mission_num
    bullets = {}
    grenades = {}
    particles = {}
    tweens = {}
    grenade_count = 3
    fire_timer = 0

    if mission_num == 1 then
        init_soldiers()
    end

    generate_trees()

    local enemy_count = missions[mission_num] or 22
    spawn_enemies(enemy_count)

    flag.x = world_w / 2
    flag.y = 80

    -- Reset camera to squad
    local sx, sy, sc = 0, 0, 0
    for _, s in ipairs(soldiers) do
        if s.alive then sx = sx + s.x; sy = sy + s.y; sc = sc + 1 end
    end
    if sc > 0 then
        cam_x = sx / sc - 400
        cam_y = sy / sc - 300
    end

    state = STATE.PLAYING
end

-- ============================================================================
-- Callbacks
-- ============================================================================
function lurek.init()
    lurek.window.setTitle("Cannon Fodder — Lurek2D")
    lurek.setBackgroundColor(0.1, 0.2, 0.05)

    lurek.input.action("up",      {"w", "up"})
    lurek.input.action("down",    {"s", "down"})
    lurek.input.action("left",    {"a", "left"})
    lurek.input.action("right",   {"d", "right"})
    lurek.input.action("fire",    {"space"})
    lurek.input.action("grenade", {"g"})
    lurek.input.action("quit",    {"escape"})
end

function lurek.ready()
    state = STATE.TITLE
    title_blink_timer = 0
end

-- ============================================================================
-- Process
-- ============================================================================
lurek.process(function(dt)
    if lurek.input.action_just_pressed("quit") then
        lurek.event.quit()
        return
    end

    title_blink_timer = title_blink_timer + dt

    -- Update tweens
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = clamp(tw.elapsed / tw.duration, 0, 1)
        -- ease out quad
        local eased = 1 - (1 - t) * (1 - t)
        if tw.target then
            tw.target[tw.field] = tw.from + (tw.to - tw.from) * eased
        end
        if t >= 1 then
            if tw.on_done then tw.on_done() end
            table.remove(tweens, i)
        else
            i = i + 1
        end
    end

    -- Update particles
    local pi = 1
    while pi <= #particles do
        local p = particles[pi]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.vx = p.vx * 0.96
        p.vy = p.vy * 0.96
        if p.life <= 0 then
            table.remove(particles, pi)
        else
            pi = pi + 1
        end
    end

    -- ---- TITLE ----
    if state == STATE.TITLE then
        if lurek.input.action_just_pressed("fire") then
            start_mission(1)
            score = 0
        end
        return
    end

    -- ---- MISSION COMPLETE ----
    if state == STATE.MISSION_COMPLETE then
        mission_complete_timer = mission_complete_timer - dt
        if mission_complete_timer <= 0 then
            if current_mission < #missions then
                start_mission(current_mission + 1)
            else
                state = STATE.TITLE
            end
        end
        return
    end

    -- ---- GAME OVER ----
    if state == STATE.GAME_OVER then
        if lurek.input.action_just_pressed("fire") then
            state = STATE.TITLE
        end
        return
    end

    -- ---- PLAYING ----
    -- Squad direction
    squad_target_dx, squad_target_dy = 0, 0
    if lurek.input.action_pressed("up")    then squad_target_dy = squad_target_dy - 1 end
    if lurek.input.action_pressed("down")  then squad_target_dy = squad_target_dy + 1 end
    if lurek.input.action_pressed("left")  then squad_target_dx = squad_target_dx - 1 end
    if lurek.input.action_pressed("right") then squad_target_dx = squad_target_dx + 1 end

    local ndx, ndy = normalize(squad_target_dx, squad_target_dy)
    if math.abs(ndx) > 0.01 or math.abs(ndy) > 0.01 then
        facing_angle = math.atan2(ndy, ndx)
    end

    -- Move soldiers
    local alive_count = 0
    local center_x, center_y = 0, 0
    for idx, s in ipairs(soldiers) do
        if s.alive then
            s.x = s.x + ndx * squad_speed * dt
            s.y = s.y + ndy * squad_speed * dt
            s.x = clamp(s.x, 10, world_w - 10)
            s.y = clamp(s.y, 10, world_h - 10)

            -- Tree collision
            for _, tr in ipairs(trees) do
                local d = dist(s.x, s.y, tr.x, tr.y)
                if d < s.radius + tr.radius then
                    local px, py = normalize(s.x - tr.x, s.y - tr.y)
                    s.x = tr.x + px * (s.radius + tr.radius + 1)
                    s.y = tr.y + py * (s.radius + tr.radius + 1)
                end
            end

            alive_count = alive_count + 1
            center_x = center_x + s.x
            center_y = center_y + s.y
        end
    end

    if alive_count == 0 then
        state = STATE.GAME_OVER
        return
    end

    center_x = center_x / alive_count
    center_y = center_y / alive_count

    -- Camera follow squad center
    local target_cam_x = center_x - 400
    local target_cam_y = center_y - 300
    cam_x = cam_x + (target_cam_x - cam_x) * 4 * dt
    cam_y = cam_y + (target_cam_y - cam_y) * 4 * dt
    cam_x = clamp(cam_x, 0, world_w - 800)
    cam_y = clamp(cam_y, 0, world_h - 600)

    -- Shooting
    fire_timer = fire_timer - dt
    if lurek.input.action_pressed("fire") and fire_timer <= 0 then
        fire_timer = fire_cooldown
        local fdx = math.cos(facing_angle)
        local fdy = math.sin(facing_angle)
        for _, s in ipairs(soldiers) do
            if s.alive then
                table.insert(bullets, {
                    x = s.x, y = s.y,
                    vx = fdx * bullet_speed,
                    vy = fdy * bullet_speed,
                    friendly = true,
                    life = 2.0
                })
            end
        end
    end

    -- Grenade
    if lurek.input.action_just_pressed("grenade") and grenade_count > 0 then
        grenade_count = grenade_count - 1
        local fdx = math.cos(facing_angle)
        local fdy = math.sin(facing_angle)
        table.insert(grenades, {
            x = center_x, y = center_y,
            vx = fdx * grenade_speed,
            vy = fdy * grenade_speed,
            fuse = grenade_fuse,
            arc_height = 0,
            arc_vel = 80
        })
    end

    -- Update grenades
    local gi = 1
    while gi <= #grenades do
        local gr = grenades[gi]
        gr.x = gr.x + gr.vx * dt
        gr.y = gr.y + gr.vy * dt
        gr.vx = gr.vx * 0.97
        gr.vy = gr.vy * 0.97
        gr.arc_height = gr.arc_height + gr.arc_vel * dt
        gr.arc_vel = gr.arc_vel - 160 * dt
        gr.fuse = gr.fuse - dt

        if gr.fuse <= 0 then
            -- Explode
            spawn_particles(gr.x, gr.y, 30, 1.0, 0.6, 0.1, 0.8, 150)
            spawn_particles(gr.x, gr.y, 15, 0.3, 0.3, 0.3, 1.0, 80)

            -- Flash tween
            flash_alpha = 0.6
            local flash_ref = { val = 0.6 }
            add_tween(flash_ref, "val", 0.6, 0, 0.3, function()
                flash_alpha = 0
            end)

            -- Damage enemies in radius
            for _, e in ipairs(enemies) do
                if e.alive and dist(gr.x, gr.y, e.x, e.y) < grenade_radius then
                    e.alive = false
                    enemies_remaining = enemies_remaining - 1
                    score = score + 50
                    spawn_particles(e.x, e.y, 10, 0.8, 0.1, 0.1, 0.6, 100)
                end
            end

            -- Scatter nearby tree leaves
            for _, tr in ipairs(trees) do
                if dist(gr.x, gr.y, tr.x, tr.y) < grenade_radius + 30 then
                    spawn_particles(tr.x, tr.y - tr.radius, 8, 0.2, 0.5, 0.1, 1.0, 60)
                end
            end

            table.remove(grenades, gi)
        else
            gi = gi + 1
        end
    end

    -- Update bullets
    local bi = 1
    while bi <= #bullets do
        local b = bullets[bi]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        local removed = false

        if b.life <= 0 or b.x < 0 or b.x > world_w or b.y < 0 or b.y > world_h then
            removed = true
        end

        -- Tree collision
        if not removed then
            for _, tr in ipairs(trees) do
                if dist(b.x, b.y, tr.x, tr.y) < tr.radius then
                    spawn_particles(b.x, b.y, 4, 0.2, 0.5, 0.1, 0.4, 40)
                    removed = true
                    break
                end
            end
        end

        if not removed and b.friendly then
            -- Hit enemy
            for _, e in ipairs(enemies) do
                if e.alive and dist(b.x, b.y, e.x, e.y) < e.radius + 3 then
                    e.alive = false
                    enemies_remaining = enemies_remaining - 1
                    score = score + 100
                    spawn_particles(e.x, e.y, 8, 0.8, 0.1, 0.1, 0.5, 80)
                    spawn_particles(b.x, b.y, 3, 1.0, 0.8, 0.2, 0.3, 50)
                    removed = true
                    break
                end
            end
        elseif not removed and not b.friendly then
            -- Hit soldier
            for _, s in ipairs(soldiers) do
                if s.alive and dist(b.x, b.y, s.x, s.y) < s.radius + 3 then
                    s.alive = false
                    spawn_particles(s.x, s.y, 12, 0.7, 0.05, 0.05, 0.7, 90)
                    spawn_particles(b.x, b.y, 3, 1.0, 0.8, 0.2, 0.3, 50)
                    removed = true
                    break
                end
            end
        end

        if removed then
            table.remove(bullets, bi)
        else
            bi = bi + 1
        end
    end

    -- Enemy AI
    for _, e in ipairs(enemies) do
        if e.alive then
            -- Find nearest alive soldier
            local nearest_dist = 99999
            local nearest_s = nil
            for _, s in ipairs(soldiers) do
                if s.alive then
                    local d = dist(e.x, e.y, s.x, s.y)
                    if d < nearest_dist then
                        nearest_dist = d
                        nearest_s = s
                    end
                end
            end

            if nearest_s and nearest_dist < enemy_detect_range then
                -- Chase and shoot
                local edx, edy = normalize(nearest_s.x - e.x, nearest_s.y - e.y)
                e.x = e.x + edx * enemy_speed * 1.5 * dt
                e.y = e.y + edy * enemy_speed * 1.5 * dt

                e.fire_timer = e.fire_timer - dt
                if e.fire_timer <= 0 then
                    e.fire_timer = enemy_fire_cooldown
                    table.insert(bullets, {
                        x = e.x, y = e.y,
                        vx = edx * bullet_speed * 0.7,
                        vy = edy * bullet_speed * 0.7,
                        friendly = false,
                        life = 1.8
                    })
                end
            else
                -- Patrol
                e.patrol_angle = e.patrol_angle + 0.5 * dt
                local target_x = e.patrol_cx + math.cos(e.patrol_angle) * e.patrol_radius
                local target_y = e.patrol_cy + math.sin(e.patrol_angle) * e.patrol_radius
                local pdx, pdy = normalize(target_x - e.x, target_y - e.y)
                e.x = e.x + pdx * enemy_speed * dt
                e.y = e.y + pdy * enemy_speed * dt
            end

            e.x = clamp(e.x, 10, world_w - 10)
            e.y = clamp(e.y, 10, world_h - 10)

            -- Tree collision for enemies
            for _, tr in ipairs(trees) do
                local d = dist(e.x, e.y, tr.x, tr.y)
                if d < e.radius + tr.radius then
                    local px, py = normalize(e.x - tr.x, e.y - tr.y)
                    e.x = tr.x + px * (e.radius + tr.radius + 1)
                    e.y = tr.y + py * (e.radius + tr.radius + 1)
                end
            end
        end
    end

    -- Check mission complete: all enemies dead + squad near flag
    if enemies_remaining <= 0 then
        if dist(center_x, center_y, flag.x, flag.y) < 40 then
            score = score + 500
            state = STATE.MISSION_COMPLETE
            mission_complete_timer = 3.0
            mission_banner_alpha = 0
            add_tween({ ref = "banner" }, "ref", 0, 1, 0.5)
            mission_banner_alpha = 1
        end
    end
end)

-- ============================================================================
-- Render — world space (jungle, soldiers, enemies, bullets, trees, flag)
-- ============================================================================
lurek.render(function()
    local ox, oy = -cam_x, -cam_y

    -- Ground — dark jungle green gradient strips
    for row = 0, world_h, 40 do
        local shade = 0.12 + (row / world_h) * 0.06
        lurek.render.rectangleangle(ox, oy + row, world_w, 40, shade, shade + 0.08, 0.02)
    end

    -- Trees — trunk + canopy
    for _, tr in ipairs(trees) do
        local tx, ty = tr.x + ox, tr.y + oy
        -- Trunk
        lurek.render.rectangleangle(tx - 3, ty, 6, tr.radius * 0.7, 0.35, 0.22, 0.1)
        -- Canopy
        lurek.render.circle(tx, ty, tr.radius, 0.08, 0.3, 0.06)
        lurek.render.circle(tx - 4, ty - 3, tr.radius * 0.7, 0.1, 0.35, 0.08)
    end

    -- Flag
    if state == STATE.PLAYING or state == STATE.MISSION_COMPLETE then
        local fx, fy = flag.x + ox, flag.y + oy
        -- Pole
        lurek.render.rectangleangle(fx - 1, fy - 20, 3, 40, 0.7, 0.7, 0.7)
        -- Flag cloth
        lurek.render.rectangleangle(fx + 2, fy - 18, 16, 10, 0.9, 0.2, 0.1)
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            local ex, ey = e.x + ox, e.y + oy
            lurek.render.circle(ex, ey, e.radius, 0.8, 0.15, 0.1)
            lurek.render.circle(ex, ey, e.radius - 2, 0.9, 0.25, 0.15)
        end
    end

    -- Soldiers
    for idx, s in ipairs(soldiers) do
        if s.alive then
            local sx, sy = s.x + ox, s.y + oy
            lurek.render.circle(sx, sy, s.radius, 0.15, 0.55, 0.15)
            lurek.render.circle(sx, sy, s.radius - 2, 0.2, 0.65, 0.2)
            -- Facing indicator
            local fdx = math.cos(facing_angle) * (s.radius + 3)
            local fdy = math.sin(facing_angle) * (s.radius + 3)
            lurek.render.circle(sx + fdx, sy + fdy, 2, 0.9, 0.9, 0.3)
        end
    end

    -- Bullets
    for _, b in ipairs(bullets) do
        local bx, by = b.x + ox, b.y + oy
        if b.friendly then
            lurek.render.circle(bx, by, 2, 1.0, 0.9, 0.3)
        else
            lurek.render.circle(bx, by, 2, 1.0, 0.3, 0.2)
        end
    end

    -- Grenades (arcing)
    for _, gr in ipairs(grenades) do
        local gx, gy = gr.x + ox, gr.y + oy - math.max(0, gr.arc_height)
        -- Shadow
        lurek.render.circle(gr.x + ox, gr.y + oy, 3, 0.0, 0.0, 0.0)
        -- Grenade body
        lurek.render.circle(gx, gy, 4, 0.3, 0.35, 0.1)
        lurek.render.circle(gx, gy, 2, 0.5, 0.55, 0.2)
    end

    -- Particles
    for _, p in ipairs(particles) do
        local px, py = p.x + ox, p.y + oy
        local alpha_factor = clamp(p.life / p.max_life, 0, 1)
        local sz = p.size * alpha_factor
        lurek.render.circle(px, py, sz, p.r, p.g, p.b)
    end

    -- Explosion flash overlay
    if flash_alpha > 0 then
        lurek.render.rectangleangle(0, 0, 800, 600, 1.0, 0.9, 0.5, flash_alpha)
    end
end)

-- ============================================================================
-- Render UI — HUD overlay (score, grenades, mission, soldier count)
-- ============================================================================
lurek.render_ui(function()
    if state == STATE.TITLE then
        -- Title screen
        lurek.render.rectangleangle(0, 0, 800, 600, 0.05, 0.08, 0.02)
        lurek.render.print("CANNON FODDER", 170, 180, 48, 0.9, 0.8, 0.2)
        lurek.render.print("WAR HAS NEVER BEEN SO MUCH FUN", 180, 260, 18, 0.7, 0.7, 0.6)

        -- Blinking prompt
        if math.floor(title_blink_timer * 2) % 2 == 0 then
            lurek.render.print("Press SPACE to start", 280, 400, 20, 0.9, 0.9, 0.9)
        end

        lurek.render.print("WASD = Move   SPACE = Fire   G = Grenade", 180, 500, 14, 0.5, 0.5, 0.5)
        return
    end

    if state == STATE.GAME_OVER then
        lurek.render.rectangleangle(0, 0, 800, 600, 0.05, 0.02, 0.02, 0.85)
        lurek.render.print("GAME OVER", 260, 220, 48, 0.9, 0.2, 0.15)
        lurek.render.print("Final Score: " .. score, 300, 300, 24, 0.9, 0.9, 0.9)
        if math.floor(title_blink_timer * 2) % 2 == 0 then
            lurek.render.print("Press SPACE", 330, 400, 20, 0.8, 0.8, 0.8)
        end
        return
    end

    -- HUD background bar
    lurek.render.rectangleangle(0, 0, 800, 32, 0.0, 0.0, 0.0, 0.6)

    -- Score
    lurek.render.print("SCORE: " .. score, 10, 6, 18, 0.9, 0.85, 0.3)

    -- Mission
    lurek.render.print("MISSION " .. current_mission .. "/" .. #missions, 300, 6, 18, 0.9, 0.9, 0.9)

    -- Grenades
    lurek.render.print("GRENADES: " .. grenade_count, 530, 6, 18, 0.6, 0.9, 0.4)

    -- Enemies remaining
    lurek.render.print("ENEMIES: " .. enemies_remaining, 680, 6, 14, 0.9, 0.4, 0.3)

    -- Soldiers alive indicator (bottom left)
    local alive = 0
    for _, s in ipairs(soldiers) do
        if s.alive then alive = alive + 1 end
    end
    for i = 1, 3 do
        local sx = 20 + (i - 1) * 22
        local sy = 575
        if i <= alive then
            lurek.render.circle(sx, sy, 7, 0.15, 0.6, 0.15)
        else
            lurek.render.circle(sx, sy, 7, 0.3, 0.1, 0.1)
            lurek.render.print("X", sx - 4, sy - 7, 14, 0.6, 0.2, 0.2)
        end
    end

    -- FPS
    local fps = lurek.timer.getFPS()
    lurek.render.print("FPS: " .. fps, 730, 580, 12, 0.5, 0.5, 0.5)

    -- Mission complete banner
    if state == STATE.MISSION_COMPLETE then
        lurek.render.rectangleangle(0, 230, 800, 80, 0.0, 0.0, 0.0, 0.75)
        lurek.render.print("MISSION " .. current_mission .. " COMPLETE!", 220, 250, 32, 0.2, 0.9, 0.3)
        lurek.render.print("+500 BONUS", 340, 290, 18, 0.9, 0.85, 0.3)
    end
end)
