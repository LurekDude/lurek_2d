-- ============================================================================
-- Commando — Lurek2D
-- ============================================================================
-- Category : retro
-- Source   : content/games/retro/commando/main.lua
-- Run with : cargo run -- content/games/retro/commando
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local current_state = STATE.TITLE

-- Player
local PLAYER_W, PLAYER_H = 16, 20
local PLAYER_SPEED   = 160
local FIRE_COOLDOWN  = 0.15
local BULLET_SPEED   = 400
local BULLET_W, BULLET_H = 3, 8
local MAX_LIVES      = 3
local MAX_GRENADES   = 3
local GRENADE_RADIUS = 60
local INVULN_TIME    = 2.0

-- World scroll
local SCROLL_SPEED   = 60
local CHECKPOINT_DIST = 1000
local BOSS_DIST       = 2000

-- Enemies
local E_INFANTRY = 1
local E_BUNKER   = 2
local E_OFFICER  = 3
local E_BOSS     = 4

local ENEMY_HP     = { [E_INFANTRY] = 1, [E_BUNKER] = 3, [E_OFFICER] = 2, [E_BOSS] = 20 }
local ENEMY_W      = { [E_INFANTRY] = 14, [E_BUNKER] = 28, [E_OFFICER] = 14, [E_BOSS] = 60 }
local ENEMY_H      = { [E_INFANTRY] = 18, [E_BUNKER] = 24, [E_OFFICER] = 18, [E_BOSS] = 40 }
local ENEMY_SPEED  = { [E_INFANTRY] = 40, [E_BUNKER] = 0,  [E_OFFICER] = 70, [E_BOSS] = 0 }
local ENEMY_POINTS = { [E_INFANTRY] = 100, [E_BUNKER] = 200, [E_OFFICER] = 150, [E_BOSS] = 2000 }
local ENEMY_COLORS = {
    [E_INFANTRY] = { 0.55, 0.35, 0.15 },
    [E_BUNKER]   = { 0.45, 0.45, 0.45 },
    [E_OFFICER]  = { 0.70, 0.20, 0.15 },
    [E_BOSS]     = { 0.30, 0.30, 0.30 },
}

local ENEMY_BULLET_SPEED = 140
local ENEMY_FIRE_INTERVAL = 2.0

-- POW
local POW_W, POW_H = 12, 16
local POW_RESCUE_DIST = 30
local POW_BONUS = 300

-- Cover
local COVER_SANDBAG = 1
local COVER_BARREL  = 2
local COVER_TREE    = 3

-- Tile
local TILE_SIZE = 40

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local player = { x = SCREEN_W / 2, y = SCREEN_H - 80 }
local player_bullets = {}
local fire_timer = 0
local lives = MAX_LIVES
local grenades = MAX_GRENADES
local invuln_timer = 0
local score = 0
local high_score = 0
local distance = 0
local last_checkpoint = 0

local enemies = {}
local enemy_bullets = {}
local pows = {}
local covers = {}
local grenades_in_flight = {}

local spawn_timer = 0
local spawn_interval = 2.0
local boss_active = false
local next_boss_dist = BOSS_DIST

local particles = {}
local score_pops = {}

local cam = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function dist_between(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end
local function rect_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- ---------------------------------------------------------------------------
-- Particle helpers
-- ---------------------------------------------------------------------------
local function spawn_particles(px, py, r, g, b, count, speed_mult)
    speed_mult = speed_mult or 1
    for _ = 1, (count or 8) do
        local angle = math.random() * math.pi * 2
        local spd = (40 + math.random() * 120) * speed_mult
        table.insert(particles, {
            x = px, y = py,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.2 + math.random() * 0.4,
            max_life = 0.6,
            r = r, g = g, b = b,
            size = 1 + math.random() * 3,
        })
    end
end

local function spawn_explosion(px, py, radius)
    local count = math.floor(radius / 3)
    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = 20 + math.random() * (radius * 2)
        table.insert(particles, {
            x = px + (math.random() - 0.5) * 10,
            y = py + (math.random() - 0.5) * 10,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.3 + math.random() * 0.5,
            max_life = 0.8,
            r = 1.0, g = 0.4 + math.random() * 0.4, b = 0.0,
            size = 2 + math.random() * 4,
        })
    end
end

local function spawn_grass_particles(px, py)
    for _ = 1, 3 do
        local angle = math.random() * math.pi * 2
        local spd = 15 + math.random() * 30
        table.insert(particles, {
            x = px + (math.random() - 0.5) * 10,
            y = py + (math.random() - 0.5) * 10,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.15 + math.random() * 0.2,
            max_life = 0.35,
            r = 0.2, g = 0.6 + math.random() * 0.2, b = 0.1,
            size = 1 + math.random() * 2,
        })
    end
end

local function spawn_rescue_sparkle(px, py)
    for _ = 1, 12 do
        local angle = math.random() * math.pi * 2
        local spd = 40 + math.random() * 80
        table.insert(particles, {
            x = px, y = py,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.3 + math.random() * 0.3,
            max_life = 0.6,
            r = 1.0, g = 1.0, b = 0.3,
            size = 2 + math.random() * 3,
        })
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

local function draw_particles()
    for _, p in ipairs(particles) do
        local a = clamp(p.life / p.max_life, 0, 1)
        lurek.render.setColor(p.r, p.g, p.b, a)
        lurek.render.drawRect("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end
end

-- ---------------------------------------------------------------------------
-- Score pop (tween-like floating text)
-- ---------------------------------------------------------------------------
local function add_score_pop(x, y, text, r, g, b)
    table.insert(score_pops, {
        x = x, y = y, text = text,
        alpha = 1.0, dy = 0, life = 0.8,
        r = r or 1, g = g or 1, b = b or 0,
    })
end

local function update_score_pops(dt)
    local i = 1
    while i <= #score_pops do
        local sp = score_pops[i]
        sp.life = sp.life - dt
        sp.dy = sp.dy - 60 * dt
        sp.y = sp.y + sp.dy * dt
        sp.alpha = clamp(sp.life / 0.8, 0, 1)
        if sp.life <= 0 then
            table.remove(score_pops, i)
        else
            i = i + 1
        end
    end
end

local function draw_score_pops()
    for _, sp in ipairs(score_pops) do
        lurek.render.setColor(sp.r, sp.g, sp.b, sp.alpha)
        lurek.render.print(sp.text, sp.x, sp.y)
    end
end

-- ---------------------------------------------------------------------------
-- Jungle tile background
-- ---------------------------------------------------------------------------
local function draw_jungle(scroll_y)
    local offset = scroll_y % TILE_SIZE
    for ty = -1, math.ceil(SCREEN_H / TILE_SIZE) do
        for tx = 0, math.ceil(SCREEN_W / TILE_SIZE) - 1 do
            local px = tx * TILE_SIZE
            local py = ty * TILE_SIZE + offset
            local hash = ((tx * 7 + math.floor((ty + math.floor(scroll_y / TILE_SIZE))) * 13) % 5)
            if hash == 0 then
                lurek.render.setColor(0.12, 0.28, 0.08, 1)
            elseif hash == 1 then
                lurek.render.setColor(0.10, 0.24, 0.07, 1)
            elseif hash == 2 then
                lurek.render.setColor(0.15, 0.30, 0.10, 1)
            elseif hash == 3 then
                lurek.render.setColor(0.20, 0.18, 0.08, 1)
            else
                lurek.render.setColor(0.13, 0.26, 0.09, 1)
            end
            lurek.render.drawRect("fill", px, py, TILE_SIZE, TILE_SIZE)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Spawning
-- ---------------------------------------------------------------------------
local function spawn_enemy(etype, ex, ey)
    table.insert(enemies, {
        etype = etype, x = ex, y = ey,
        hp = ENEMY_HP[etype],
        fire_timer = 1.0 + math.random() * ENEMY_FIRE_INTERVAL,
        alive = true,
    })
end

local function spawn_cover(ctype, cx, cy)
    table.insert(covers, { ctype = ctype, x = cx, y = cy, hp = (ctype == COVER_TREE) and 999 or 2, w = 24, h = 20 })
end

local function spawn_pow(px, py)
    table.insert(pows, { x = px, y = py, rescued = false })
end

local function generate_wave_content()
    local density = math.min(1 + distance / 2000, 4)
    local count = math.floor(2 + math.random() * density * 2)
    for _ = 1, count do
        local ex = 40 + math.random() * (SCREEN_W - 80)
        local ey = -20 - math.random() * 60
        local roll = math.random()
        if roll < 0.5 then
            spawn_enemy(E_INFANTRY, ex, ey)
        elseif roll < 0.75 then
            spawn_enemy(E_BUNKER, ex, ey)
        else
            spawn_enemy(E_OFFICER, ex, ey)
        end
    end
    -- Occasional cover
    if math.random() < 0.4 then
        local cx = 30 + math.random() * (SCREEN_W - 60)
        local cy = -30 - math.random() * 40
        local croll = math.random()
        if croll < 0.4 then spawn_cover(COVER_SANDBAG, cx, cy)
        elseif croll < 0.7 then spawn_cover(COVER_BARREL, cx, cy)
        else spawn_cover(COVER_TREE, cx, cy) end
    end
    -- Occasional POW
    if math.random() < 0.25 then
        local px = 50 + math.random() * (SCREEN_W - 100)
        local py = -20 - math.random() * 40
        spawn_pow(px, py)
    end
end

local function spawn_boss()
    boss_active = true
    local bx = SCREEN_W / 2 - ENEMY_W[E_BOSS] / 2
    spawn_enemy(E_BOSS, bx, -60)
    -- Flanking bunkers
    spawn_enemy(E_BUNKER, bx - 80, -30)
    spawn_enemy(E_BUNKER, bx + ENEMY_W[E_BOSS] + 50, -30)
end

-- ---------------------------------------------------------------------------
-- Reset
-- ---------------------------------------------------------------------------
local function reset_game()
    player.x = SCREEN_W / 2
    player.y = SCREEN_H - 80
    player_bullets = {}
    fire_timer = 0
    lives = MAX_LIVES
    grenades = MAX_GRENADES
    invuln_timer = 0
    score = 0
    distance = 0
    last_checkpoint = 0
    enemies = {}
    enemy_bullets = {}
    pows = {}
    covers = {}
    grenades_in_flight = {}
    particles = {}
    score_pops = {}
    spawn_timer = 0
    spawn_interval = 2.0
    boss_active = false
    next_boss_dist = BOSS_DIST
    current_state = STATE.PLAYING
end

-- ---------------------------------------------------------------------------
-- Grenade arc (tween-like)
-- ---------------------------------------------------------------------------
local function throw_grenade()
    if grenades <= 0 then return end
    grenades = grenades - 1
    table.insert(grenades_in_flight, {
        x = player.x, y = player.y,
        target_y = player.y - 120,
        timer = 0, duration = 0.5,
        start_x = player.x, start_y = player.y,
    })
end

local function update_grenades(dt)
    local i = 1
    while i <= #grenades_in_flight do
        local g = grenades_in_flight[i]
        g.timer = g.timer + dt
        local t = clamp(g.timer / g.duration, 0, 1)
        -- Parabolic arc
        g.x = g.start_x
        g.y = g.start_y + (g.target_y - g.start_y) * t
        local arc_height = -80 * 4 * t * (1 - t)
        g.y = g.y + arc_height

        if g.timer >= g.duration then
            -- Explode
            local ex, ey = g.x, g.target_y
            spawn_explosion(ex, ey, GRENADE_RADIUS)
            -- Damage enemies in radius
            for _, e in ipairs(enemies) do
                if e.alive then
                    local ecx = e.x + ENEMY_W[e.etype] / 2
                    local ecy = e.y + ENEMY_H[e.etype] / 2
                    if dist_between(ex, ey, ecx, ecy) < GRENADE_RADIUS then
                        e.hp = e.hp - 3
                        if e.hp <= 0 then
                            e.alive = false
                            score = score + ENEMY_POINTS[e.etype]
                            add_score_pop(e.x, e.y, "+" .. ENEMY_POINTS[e.etype], 1, 0.8, 0)
                            spawn_particles(ecx, ecy, ENEMY_COLORS[e.etype][1], ENEMY_COLORS[e.etype][2], ENEMY_COLORS[e.etype][3], 12)
                        end
                    end
                end
            end
            -- Destroy destructible cover
            for _, c in ipairs(covers) do
                if c.hp < 999 then
                    local ccx = c.x + c.w / 2
                    local ccy = c.y + c.h / 2
                    if dist_between(ex, ey, ccx, ccy) < GRENADE_RADIUS then
                        c.hp = 0
                        spawn_particles(ccx, ccy, 0.6, 0.4, 0.2, 10)
                    end
                end
            end
            table.remove(grenades_in_flight, i)
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- lurek.init — one-time setup
-- ---------------------------------------------------------------------------
lurek.init(function()
    lurek.window.setTitle("Commando — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.18, 0.06)
    cam = lurek.camera.new()
    cam:setPosition(0, 0)
end)

-- ---------------------------------------------------------------------------
-- lurek.process — logic update
-- ---------------------------------------------------------------------------
lurek.process(function(dt)
    -- Quit
    if lurek.input.isKeyPressed("escape") then
        lurek.event.quit()
        return
    end

    -- ---- TITLE ----
    if current_state == STATE.TITLE then
        if lurek.input.isKeyPressed("return") then
            reset_game()
        end
        return
    end

    -- ---- GAME OVER ----
    if current_state == STATE.GAME_OVER then
        if lurek.input.isKeyPressed("return") then
            current_state = STATE.TITLE
        end
        update_particles(dt)
        update_score_pops(dt)
        return
    end

    -- ---- PLAYING ----
    invuln_timer = math.max(0, invuln_timer - dt)

    -- Scroll world
    local scroll_amount = SCROLL_SPEED * dt
    distance = distance + scroll_amount

    -- Move all world objects downward (scroll effect)
    for _, e in ipairs(enemies) do e.y = e.y + scroll_amount end
    for _, b in ipairs(enemy_bullets) do b.y = b.y + scroll_amount end
    for _, p in ipairs(pows) do p.y = p.y + scroll_amount end
    for _, c in ipairs(covers) do c.y = c.y + scroll_amount end

    -- Score from distance
    score = score + math.floor(scroll_amount)

    -- Checkpoint
    if math.floor(distance / CHECKPOINT_DIST) > math.floor(last_checkpoint / CHECKPOINT_DIST) then
        last_checkpoint = distance
    end

    -- Boss trigger
    if not boss_active and distance >= next_boss_dist then
        spawn_boss()
        next_boss_dist = next_boss_dist + BOSS_DIST
    end

    -- Spawn waves
    spawn_timer = spawn_timer - dt
    if spawn_timer <= 0 and not boss_active then
        generate_wave_content()
        spawn_timer = spawn_interval
        spawn_interval = math.max(0.8, spawn_interval - 0.02)
    end

    -- Player movement
    local dx, dy = 0, 0
    if lurek.input.isKeyDown("w") or lurek.input.isKeyDown("up")    then dy = -1 end
    if lurek.input.isKeyDown("s") or lurek.input.isKeyDown("down")  then dy =  1 end
    if lurek.input.isKeyDown("a") or lurek.input.isKeyDown("left")  then dx = -1 end
    if lurek.input.isKeyDown("d") or lurek.input.isKeyDown("right") then dx =  1 end
    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2)
        dx, dy = dx * inv, dy * inv
    end
    player.x = clamp(player.x + dx * PLAYER_SPEED * dt, 10, SCREEN_W - PLAYER_W - 10)
    player.y = clamp(player.y + dy * PLAYER_SPEED * dt, SCREEN_H * 0.4, SCREEN_H - PLAYER_H - 10)

    -- Grass particles when moving
    if (dx ~= 0 or dy ~= 0) and math.random() < 0.3 then
        spawn_grass_particles(player.x + PLAYER_W / 2, player.y + PLAYER_H)
    end

    -- Shoot
    fire_timer = math.max(0, fire_timer - dt)
    if lurek.input.isKeyDown("space") and fire_timer <= 0 then
        fire_timer = FIRE_COOLDOWN
        table.insert(player_bullets, { x = player.x + PLAYER_W / 2 - BULLET_W / 2, y = player.y - BULLET_H })
    end

    -- Grenade
    if lurek.input.isKeyPressed("g") then
        throw_grenade()
    end

    -- Update player bullets
    local i = 1
    while i <= #player_bullets do
        local b = player_bullets[i]
        b.y = b.y - BULLET_SPEED * dt
        if b.y < -20 then
            table.remove(player_bullets, i)
        else
            i = i + 1
        end
    end

    -- Update enemy bullets
    i = 1
    while i <= #enemy_bullets do
        local b = enemy_bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.y > SCREEN_H + 20 or b.y < -20 or b.x < -20 or b.x > SCREEN_W + 20 then
            table.remove(enemy_bullets, i)
        else
            i = i + 1
        end
    end

    -- Update enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            -- Movement
            if ENEMY_SPEED[e.etype] > 0 then
                local dir_x = player.x - e.x
                local dir_y = player.y - e.y
                local len = math.sqrt(dir_x * dir_x + dir_y * dir_y)
                if len > 1 then
                    dir_x, dir_y = dir_x / len, dir_y / len
                    e.x = e.x + dir_x * ENEMY_SPEED[e.etype] * dt
                    e.y = e.y + dir_y * ENEMY_SPEED[e.etype] * dt * 0.3
                end
            end
            -- Boss stays at y=60
            if e.etype == E_BOSS and e.y > 60 then
                -- let scroll bring it down, then clamp
            elseif e.etype == E_BOSS and e.y >= 60 then
                e.y = 60
            end

            -- Firing
            if e.y > 0 and e.y < SCREEN_H then
                e.fire_timer = e.fire_timer - dt
                if e.fire_timer <= 0 then
                    e.fire_timer = ENEMY_FIRE_INTERVAL + math.random() * 0.5
                    local ecx = e.x + ENEMY_W[e.etype] / 2
                    local ecy = e.y + ENEMY_H[e.etype] / 2
                    if e.etype == E_BUNKER or e.etype == E_BOSS then
                        -- 3-bullet spread
                        for angle_off = -0.3, 0.3, 0.3 do
                            local a = math.atan2(player.y - ecy, player.x - ecx) + angle_off
                            table.insert(enemy_bullets, {
                                x = ecx, y = ecy,
                                vx = math.cos(a) * ENEMY_BULLET_SPEED,
                                vy = math.sin(a) * ENEMY_BULLET_SPEED,
                            })
                        end
                    else
                        local a = math.atan2(player.y - ecy, player.x - ecx)
                        table.insert(enemy_bullets, {
                            x = ecx, y = ecy,
                            vx = math.cos(a) * ENEMY_BULLET_SPEED,
                            vy = math.sin(a) * ENEMY_BULLET_SPEED,
                        })
                    end
                end
            end
        end
    end

    -- Player bullets vs enemies
    for bi = #player_bullets, 1, -1 do
        local b = player_bullets[bi]
        local hit = false
        for _, e in ipairs(enemies) do
            if e.alive and rect_overlap(b.x, b.y, BULLET_W, BULLET_H, e.x, e.y, ENEMY_W[e.etype], ENEMY_H[e.etype]) then
                e.hp = e.hp - 1
                spawn_particles(b.x, b.y, 1, 0.9, 0.3, 4)
                if e.hp <= 0 then
                    e.alive = false
                    score = score + ENEMY_POINTS[e.etype]
                    add_score_pop(e.x, e.y, "+" .. ENEMY_POINTS[e.etype], 1, 0.8, 0)
                    local c = ENEMY_COLORS[e.etype]
                    spawn_particles(e.x + ENEMY_W[e.etype] / 2, e.y + ENEMY_H[e.etype] / 2, c[1], c[2], c[3], 16)
                    if e.etype == E_BOSS then
                        boss_active = false
                        spawn_explosion(e.x + ENEMY_W[e.etype] / 2, e.y + ENEMY_H[e.etype] / 2, 80)
                    end
                end
                hit = true
                break
            end
        end
        -- Bullets vs destructible cover
        if not hit then
            for _, c in ipairs(covers) do
                if c.hp > 0 and c.hp < 999 and rect_overlap(b.x, b.y, BULLET_W, BULLET_H, c.x, c.y, c.w, c.h) then
                    c.hp = c.hp - 1
                    spawn_particles(b.x, b.y, 0.6, 0.4, 0.2, 4)
                    if c.hp <= 0 then
                        spawn_particles(c.x + c.w / 2, c.y + c.h / 2, 0.5, 0.3, 0.1, 10)
                    end
                    hit = true
                    break
                end
            end
        end
        if hit then table.remove(player_bullets, bi) end
    end

    -- Enemy bullets vs player
    if invuln_timer <= 0 then
        for bi = #enemy_bullets, 1, -1 do
            local b = enemy_bullets[bi]
            if rect_overlap(b.x - 3, b.y - 3, 6, 6, player.x, player.y, PLAYER_W, PLAYER_H) then
                table.remove(enemy_bullets, bi)
                lives = lives - 1
                invuln_timer = INVULN_TIME
                spawn_particles(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2, 1, 0.3, 0.3, 12)
                if lives <= 0 then
                    if score > high_score then high_score = score end
                    current_state = STATE.GAME_OVER
                    return
                end
                break
            end
        end
    end

    -- Enemy collision with player
    if invuln_timer <= 0 then
        for _, e in ipairs(enemies) do
            if e.alive and rect_overlap(player.x, player.y, PLAYER_W, PLAYER_H, e.x, e.y, ENEMY_W[e.etype], ENEMY_H[e.etype]) then
                lives = lives - 1
                invuln_timer = INVULN_TIME
                spawn_particles(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2, 1, 0.3, 0.3, 12)
                if lives <= 0 then
                    if score > high_score then high_score = score end
                    current_state = STATE.GAME_OVER
                    return
                end
                break
            end
        end
    end

    -- POW rescue
    for _, p in ipairs(pows) do
        if not p.rescued then
            local pcx = p.x + POW_W / 2
            local pcy = p.y + POW_H / 2
            if dist_between(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2, pcx, pcy) < POW_RESCUE_DIST then
                p.rescued = true
                score = score + POW_BONUS
                add_score_pop(pcx, pcy - 10, "POW +" .. POW_BONUS, 0.3, 1, 0.3)
                spawn_rescue_sparkle(pcx, pcy)
            end
        end
    end

    -- Update grenades in flight
    update_grenades(dt)

    -- Clean up off-screen / dead entities
    local function cull(list, field)
        local j = 1
        while j <= #list do
            local item = list[j]
            local gone = false
            if field and not item[field] then gone = true end
            if item.y and item.y > SCREEN_H + 60 then gone = true end
            if item.hp and item.hp <= 0 then gone = true end
            if item.rescued then gone = true end
            if gone then
                table.remove(list, j)
            else
                j = j + 1
            end
        end
    end
    cull(enemies, "alive")
    cull(covers)
    cull(pows)

    update_particles(dt)
    update_score_pops(dt)
end)

-- ---------------------------------------------------------------------------
-- lurek.render — world drawing
-- ---------------------------------------------------------------------------
lurek.render(function()
    if current_state == STATE.TITLE then
        lurek.render.setColor(0.08, 0.18, 0.06, 1)
        lurek.render.drawRect("fill", 0, 0, SCREEN_W, SCREEN_H)
        return
    end

    -- Jungle background
    draw_jungle(distance)

    -- Cover objects
    for _, c in ipairs(covers) do
        if c.hp > 0 then
            if c.ctype == COVER_SANDBAG then
                lurek.render.setColor(0.75, 0.65, 0.45, 1)
            elseif c.ctype == COVER_BARREL then
                lurek.render.setColor(0.50, 0.30, 0.15, 1)
            else -- tree
                lurek.render.setColor(0.10, 0.40, 0.10, 1)
            end
            lurek.render.drawRect("fill", c.x, c.y, c.w, c.h)
        end
    end

    -- POWs
    for _, p in ipairs(pows) do
        if not p.rescued then
            lurek.render.setColor(1, 1, 1, 1)
            lurek.render.drawRect("fill", p.x, p.y, POW_W, POW_H)
            -- "P" indicator
            lurek.render.setColor(0.8, 0.2, 0.2, 1)
            lurek.render.drawRect("fill", p.x + 3, p.y + 2, 6, 8)
        end
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            local c = ENEMY_COLORS[e.etype]
            lurek.render.setColor(c[1], c[2], c[3], 1)
            lurek.render.drawRect("fill", e.x, e.y, ENEMY_W[e.etype], ENEMY_H[e.etype])
            -- HP bar for bosses
            if e.etype == E_BOSS then
                local bar_w = ENEMY_W[E_BOSS]
                local hp_frac = e.hp / ENEMY_HP[E_BOSS]
                lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
                lurek.render.drawRect("fill", e.x, e.y - 8, bar_w, 4)
                lurek.render.setColor(1, 0.2, 0.2, 1)
                lurek.render.drawRect("fill", e.x, e.y - 8, bar_w * hp_frac, 4)
            end
        end
    end

    -- Enemy bullets
    lurek.render.setColor(1, 0.3, 0.1, 1)
    for _, b in ipairs(enemy_bullets) do
        lurek.render.drawRect("fill", b.x - 3, b.y - 3, 6, 6)
    end

    -- Player bullets
    lurek.render.setColor(1, 1, 0.4, 1)
    for _, b in ipairs(player_bullets) do
        lurek.render.drawRect("fill", b.x, b.y, BULLET_W, BULLET_H)
    end

    -- Grenades in flight
    lurek.render.setColor(0.3, 0.5, 0.1, 1)
    for _, g in ipairs(grenades_in_flight) do
        lurek.render.drawRect("fill", g.x - 4, g.y - 4, 8, 8)
    end

    -- Player
    if invuln_timer <= 0 or math.floor(invuln_timer * 10) % 2 == 0 then
        lurek.render.setColor(0.2, 0.6, 0.15, 1)
        lurek.render.drawRect("fill", player.x, player.y, PLAYER_W, PLAYER_H)
        -- Head
        lurek.render.setColor(0.25, 0.7, 0.2, 1)
        lurek.render.drawRect("fill", player.x + 3, player.y - 4, 10, 6)
    end

    -- Particles & score pops
    draw_particles()
    draw_score_pops()
end)

-- ---------------------------------------------------------------------------
-- lurek.render_ui — HUD overlay
-- ---------------------------------------------------------------------------
lurek.render_ui(function()
    if current_state == STATE.TITLE then
        -- Title screen
        lurek.render.setColor(0.2, 0.8, 0.15, 1)
        lurek.render.print("COMMANDO", SCREEN_W / 2 - 60, SCREEN_H / 2 - 60)
        lurek.render.setColor(0.9, 0.9, 0.7, 1)
        lurek.render.print("PRESS ENTER", SCREEN_W / 2 - 50, SCREEN_H / 2 + 10)
        lurek.render.setColor(0.6, 0.6, 0.5, 1)
        lurek.render.print("WASD - Move   SPACE - Fire   G - Grenade", SCREEN_W / 2 - 140, SCREEN_H / 2 + 50)
        lurek.render.print("Rescue POWs for bonus points!", SCREEN_W / 2 - 110, SCREEN_H / 2 + 75)
        return
    end

    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(1, 0.2, 0.15, 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 50, SCREEN_H / 2 - 40)
        lurek.render.setColor(1, 1, 0.8, 1)
        lurek.render.print("Score: " .. score, SCREEN_W / 2 - 40, SCREEN_H / 2)
        lurek.render.print("High Score: " .. high_score, SCREEN_W / 2 - 55, SCREEN_H / 2 + 25)
        lurek.render.setColor(0.7, 0.7, 0.6, 1)
        lurek.render.print("PRESS ENTER", SCREEN_W / 2 - 50, SCREEN_H / 2 + 60)
        return
    end

    -- HUD — top bar
    lurek.render.setColor(0, 0, 0, 0.5)
    lurek.render.drawRect("fill", 0, 0, SCREEN_W, 24)

    lurek.render.setColor(1, 1, 0.8, 1)
    lurek.render.print("SCORE: " .. score, 10, 4)

    lurek.render.setColor(0.3, 1, 0.3, 1)
    lurek.render.print("LIVES: " .. lives, 200, 4)

    lurek.render.setColor(0.9, 0.7, 0.2, 1)
    lurek.render.print("GRENADES: " .. grenades, 340, 4)

    lurek.render.setColor(0.7, 0.8, 1, 1)
    lurek.render.print("DIST: " .. math.floor(distance), 530, 4)

    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.5, 0.5, 0.5, 0.8)
    lurek.render.print("FPS: " .. fps, SCREEN_W - 80, 4)

    -- High score
    if high_score > 0 then
        lurek.render.setColor(0.8, 0.8, 0.3, 0.7)
        lurek.render.print("HI: " .. high_score, SCREEN_W - 80, SCREEN_H - 20)
    end
end)
