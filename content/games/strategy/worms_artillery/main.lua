-- ============================================================================
-- Worms Artillery — Lurek2D
-- ============================================================================
-- Category : strategy
-- Source   : content/games/strategy/worms_artillery/main.lua
-- Run with : cargo run -- content/games/strategy/worms_artillery
-- ============================================================================
-- Turn-based artillery game inspired by Worms (Amiga 1998).
-- Two teams take turns aiming and firing a bazooka with wind drift.
-- Controls: Left/Right aim, Up/Down power, Space fire, Escape quit
-- ============================================================================

local W, H = 960, 540

-- ── Procedural terrain ────────────────────────────────────────────────────
local TERRAIN_COLS   = 120
local TERRAIN_MIN_H  = 80
local TERRAIN_MAX_H  = 340
local COL_W          = W / TERRAIN_COLS
local terrain_h      = {}     -- terrain_h[c] = height of terrain column c (from bottom)

-- ── Physics ───────────────────────────────────────────────────────────────
local GRAVITY     = 240
local WORM_R      = 10
local PROJ_R      = 5
local EXPLOSION_R = 45

-- ── Turn system ───────────────────────────────────────────────────────────
local TURN_TIME = 30
local team_names = { "Team A", "Team B" }
local teams = {}     -- each: { name, color, worms = { {x,y,hp} } }
local turn        = 1   -- 1 or 2
local active_worm = 1   -- index within current team
local turn_timer  = TURN_TIME
local STATE = { AIM = 1, FLYING = 2, EXPLODING = 3, NEXT = 4, OVER = 5 }
local state = STATE.AIM

-- Aiming
local aim_angle  = -math.pi / 4    -- radians, measured from +x axis
local fire_power = 200
local POWER_MIN  = 80
local POWER_MAX  = 500

-- Projectile
local proj = { x=0, y=0, vx=0, vy=0, active=false }
local wind = 0      -- horizontal drift (reset each turn)

-- Explosion animation
local expl = { x=0, y=0, r=0, max_r=EXPLOSION_R, t=0, dur=0.55 }

-- Particle systems (sparks)
local sparks = nil

-- ── Terrain helpers ───────────────────────────────────────────────────────
local function terrain_y(col)
    -- returns screen-Y of terrain top at column col
    local c = math.max(1, math.min(TERRAIN_COLS, col))
    return H - terrain_h[c]
end

local function terrain_y_at(px)
    local col = math.floor(px / COL_W) + 1
    return terrain_y(col)
end

local function dig_crater(cx, cy, radius)
    -- lower terrain columns inside the crater circle
    for c = 1, TERRAIN_COLS do
        local cx2 = (c - 0.5) * COL_W
        local d   = math.abs(cx2 - cx)
        if d < radius then
            local depth = math.sqrt(math.max(0, radius*radius - d*d))
            terrain_h[c] = math.max(10, terrain_h[c] - depth * 0.8)
        end
    end
end

local function worm_on_ground(w)
    w.y = terrain_y_at(w.x) - WORM_R
end

-- ── Spawn helpers ─────────────────────────────────────────────────────────
local function spawn_teams()
    local rng = lurek.math.newRandomGenerator(os.time())
    teams = {}
    local cols_per = { {5,45}, {70,115} }
    local colors   = { {0.9,0.3,0.1}, {0.1,0.5,0.9} }
    for t = 1, 2 do
        local team = { name = team_names[t], color = colors[t], worms = {} }
        for i = 1, 4 do
            local col = rng:randomInt(cols_per[t][1], cols_per[t][2])
            local wx  = (col - 0.5) * COL_W
            local w   = { x = wx, y = 0, hp = 100 }
            worm_on_ground(w)
            team.worms[i] = w
        end
        teams[t] = team
    end
end

local function next_turn()
    turn        = (turn == 1) and 2 or 1
    active_worm = 1
    -- pick next alive worm
    local found = false
    for i, w in ipairs(teams[turn].worms) do
        if w.hp > 0 then active_worm = i; found = true; break end
    end
    if not found then state = STATE.OVER; return end
    turn_timer  = TURN_TIME
    wind        = (math.random() * 60 - 30)
    aim_angle   = (turn == 1) and -math.pi/4 or -3*math.pi/4
    state       = STATE.AIM
end

local function count_alive(t)
    local n = 0
    for _, w in ipairs(teams[t].worms) do if w.hp > 0 then n = n+1 end end
    return n
end

-- ── Load ──────────────────────────────────────────────────────────────────
function lurek.load()
    lurek.window.setTitle("Worms Artillery — Lurek2D")
    lurek.render.setBackgroundColor(0.35, 0.6, 0.85)

    -- Generate terrain with fractal noise
    local ng = lurek.math.newNoiseGenerator(42)
    for c = 1, TERRAIN_COLS do
        local nx   = c / TERRAIN_COLS
        local base = (ng:noise(nx * 3, 0) + 1) * 0.5
        terrain_h[c] = TERRAIN_MIN_H + base * (TERRAIN_MAX_H - TERRAIN_MIN_H)
    end

    spawn_teams()

    -- Particle system for explosions
    sparks = lurek.particle.newSystem(120)
    sparks:setEmissionRate(0)
    sparks:setParticleLifetime(0.3, 0.8)
    sparks:setSpeed(100, 280)
    sparks:setSpread(math.pi * 2)
    sparks:setColors({ 1, 0.8, 0.1, 1 }, { 1, 0.3, 0.0, 0 })
    sparks:setSizes(4, 1)

    wind = math.random() * 60 - 30
end

-- ── Update ────────────────────────────────────────────────────────────────
function lurek.update(dt)
    sparks:update(dt)

    if state == STATE.AIM then
        turn_timer = turn_timer - dt
        if turn_timer <= 0 then next_turn(); return end

        -- Rotate aim
        if lurek.input.isDown("left")  then aim_angle = aim_angle - 1.5 * dt end
        if lurek.input.isDown("right") then aim_angle = aim_angle + 1.5 * dt end
        -- Adjust power
        if lurek.input.isDown("up")   then fire_power = math.min(POWER_MAX, fire_power + 120*dt) end
        if lurek.input.isDown("down") then fire_power = math.max(POWER_MIN, fire_power - 120*dt) end

    elseif state == STATE.FLYING then
        proj.vx = proj.vx + wind * dt
        proj.vy = proj.vy + GRAVITY * dt
        proj.x  = proj.x + proj.vx * dt
        proj.y  = proj.y + proj.vy * dt

        -- Hit terrain
        if proj.y >= terrain_y_at(proj.x) - PROJ_R or proj.x < 0 or proj.x > W then
            expl.x, expl.y, expl.r, expl.t = proj.x, proj.y, 0, 0
            proj.active = false
            dig_crater(proj.x, proj.y, EXPLOSION_R)
            -- Damage worms in blast radius
            for _, team in ipairs(teams) do
                for _, w in ipairs(team.worms) do
                    if w.hp > 0 then
                        local d = lurek.math.distance(w.x, w.y, proj.x, proj.y)
                        if d < EXPLOSION_R then
                            local dmg = math.floor((1 - d/EXPLOSION_R) * 60)
                            w.hp = math.max(0, w.hp - dmg)
                            worm_on_ground(w)
                        end
                    end
                end
            end
            sparks:setPosition(proj.x, proj.y)
            sparks:emit(80)
            state = STATE.EXPLODING
        end

    elseif state == STATE.EXPLODING then
        expl.t = expl.t + dt
        expl.r = lurek.math.lerp(0, expl.max_r, math.min(1, expl.t / expl.dur))
        if expl.t >= expl.dur then
            -- Check win condition
            if count_alive(1) == 0 or count_alive(2) == 0 then
                state = STATE.OVER
            else
                state = STATE.NEXT
            end
        end

    elseif state == STATE.NEXT then
        -- Brief pause before next turn
        expl.t = expl.t + dt
        if expl.t > 1.2 then next_turn() end
    end
end

-- ── Draw ──────────────────────────────────────────────────────────────────
function lurek.draw()
    -- Sky gradient (simple top strip)
    lurek.render.setColor(0.35, 0.6, 0.85)
    lurek.render.rectangle("fill", 0, 0, W, H)

    -- Terrain
    lurek.render.setColor(0.28, 0.55, 0.18)
    for c = 1, TERRAIN_COLS do
        local tx = (c-1) * COL_W
        local ty = terrain_y(c)
        lurek.render.rectangle("fill", tx, ty, COL_W + 1, H - ty)
    end
    -- Terrain edge highlight
    lurek.render.setColor(0.4, 0.7, 0.25)
    for c = 1, TERRAIN_COLS - 1 do
        lurek.render.line((c-1)*COL_W, terrain_y(c), c*COL_W, terrain_y(c+1))
    end

    -- Worms
    for ti, team in ipairs(teams) do
        for i, w in ipairs(team.worms) do
            if w.hp > 0 then
                lurek.render.setColor(team.color[1], team.color[2], team.color[3])
                lurek.render.circle("fill", w.x, w.y, WORM_R)
                -- HP bar
                lurek.render.setColor(0,0,0,0.7)
                lurek.render.rectangle("fill", w.x - 14, w.y - 22, 28, 5)
                lurek.render.setColor(0.1, 0.9, 0.1)
                lurek.render.rectangle("fill", w.x - 14, w.y - 22, 28*(w.hp/100), 5)
                -- Active marker
                if ti == turn and i == active_worm and state == STATE.AIM then
                    lurek.render.setColor(1, 1, 0)
                    lurek.render.circle("line", w.x, w.y, WORM_R + 4)
                    -- Aim line
                    lurek.render.setColor(1, 1, 0, 0.7)
                    local len = 30 + (fire_power / POWER_MAX) * 40
                    lurek.render.line(w.x, w.y,
                        w.x + math.cos(aim_angle)*len,
                        w.y + math.sin(aim_angle)*len)
                end
            end
        end
    end

    -- Projectile
    if proj.active then
        lurek.render.setColor(1, 0.8, 0.1)
        lurek.render.circle("fill", proj.x, proj.y, PROJ_R)
    end

    -- Explosion
    if state == STATE.EXPLODING and expl.r > 0 then
        local alpha = 1 - expl.t / expl.dur
        lurek.render.setColor(1, 0.5, 0, alpha * 0.7)
        lurek.render.circle("fill", expl.x, expl.y, expl.r)
        lurek.render.setColor(1, 1, 0, alpha)
        lurek.render.circle("line", expl.x, expl.y, expl.r)
    end

    -- Sparks
    lurek.render.setColor(1, 1, 1)
    lurek.render.draw(sparks, 0, 0)

    -- HUD
    lurek.render.setColor(0, 0, 0, 0.6)
    lurek.render.rectangle("fill", 0, 0, W, 28)
    local tc = teams[turn].color
    lurek.render.setColor(tc[1], tc[2], tc[3])
    lurek.render.print(string.format("%s — Power: %d  Wind: %+.0f  Time: %d",
        teams[turn].name, math.floor(fire_power), wind, math.max(0, math.ceil(turn_timer))), 10, 6)
    -- Team health totals
    for t = 1, 2 do
        local total = 0
        for _, w in ipairs(teams[t].worms) do total = total + w.hp end
        local c2 = teams[t].color
        lurek.render.setColor(c2[1], c2[2], c2[3])
        lurek.render.print(string.format("%s HP: %d", teams[t].name, total), W - 240 + (t-1)*120, 6)
    end

    -- Wind arrow
    lurek.render.setColor(1, 1, 1, 0.8)
    local wx = W/2
    lurek.render.line(wx, H - 12, wx + wind * 0.5, H - 12)

    -- Game over
    if state == STATE.OVER then
        lurek.render.setColor(0, 0, 0, 0.7)
        lurek.render.rectangle("fill", W/2 - 160, H/2 - 30, 320, 60)
        lurek.render.setColor(1, 1, 0)
        local winner = (count_alive(1) > 0) and teams[1].name or teams[2].name
        lurek.render.print(winner .. " wins!", W/2 - 55, H/2 - 10, 0, 1.4)
        lurek.render.setColor(1,1,1)
        lurek.render.print("Press R to restart or Esc to quit", W/2 - 130, H/2 + 18)
    end
end

-- ── Keypressed ────────────────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
    if key == "r" and state == STATE.OVER then
        -- restart
        for c = 1, TERRAIN_COLS do terrain_h[c] = 0 end
        lurek.load()
    end
    if key == "space" and state == STATE.AIM then
        local aw = teams[turn].worms[active_worm]
        proj.x      = aw.x
        proj.y      = aw.y - WORM_R
        proj.vx     = math.cos(aim_angle) * fire_power
        proj.vy     = math.sin(aim_angle) * fire_power
        proj.active = true
        state       = STATE.FLYING
    end
end
