-- ============================================================================
--  Metroidvania — Side-scrolling exploration platformer with ability unlocks
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/metroidvania
--
--  Controls (input actions):
--    left/right : A/D or ←/→
--    jump       : Space / W / ↑   (wall jump when touching wall)
--    dash       : Shift            (once unlocked)
--    quit       : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600
local TILE    = 16
local ROOM_W  = 20  -- tiles
local ROOM_H  = 15  -- tiles
local LOGICAL_W = ROOM_W * TILE  -- 320
local LOGICAL_H = ROOM_H * TILE  -- 240
local SCALE_X = SCREEN_W / LOGICAL_W  -- 2.5
local SCALE_Y = SCREEN_H / LOGICAL_H  -- 2.5

local PLAYER_W, PLAYER_H = 16, 24
local GRAVITY     = 600
local MOVE_SPEED  = 120
local JUMP_FORCE  = -260
local DASH_SPEED  = 350
local DASH_TIME   = 0.15
local MAX_HP      = 5
local INVULN_TIME = 1.0

-- ── State enum ────────────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local current_state = STATE.TITLE
local title_blink   = 0

-- ── Player state ──────────────────────────────────────────────────────────
local player = {
    x = 40, y = 180,
    vx = 0, vy = 0,
    on_ground = false,
    touching_wall = 0,   -- -1=left wall, 1=right wall, 0=none
    hp = MAX_HP,
    invuln = 0,
    facing = 1,          -- 1=right, -1=left
    has_dash   = false,
    has_double = false,
    jumps_left = 1,
    dashing = false,
    dash_timer = 0,
    dash_dir = 1,
}

-- ── Room grid (3x3) ──────────────────────────────────────────────────────
local room_x, room_y = 0, 1   -- starting room
local visited = {}             -- visited[rx..","..ry] = true

-- Tile types: 0=air, 1=wall, 2=platform, 3=dash-gate
-- Each room is 20 wide x 15 tall (indices [row][col], 1-based)
local function solid_room()
    local r = {}
    for row = 1, ROOM_H do
        r[row] = {}
        for col = 1, ROOM_W do
            if row == 1 or row == ROOM_H or col == 1 or col == ROOM_W then
                r[row][col] = 1
            else
                r[row][col] = 0
            end
        end
    end
    return r
end

local rooms = {}

local function define_rooms()
    -- Room (0,0) — upper left, double-jump item at top
    local r00 = solid_room()
    for c = 2, 19 do r00[13][c] = 2 end         -- ground platform
    for c = 2, 8  do r00[10][c] = 2 end          -- mid left
    for c = 12, 19 do r00[7][c] = 2 end          -- mid right
    for c = 6, 14 do r00[4][c] = 2 end           -- top
    r00[1][20] = 0  -- exit right
    r00[14][20] = 0
    r00[15][10] = 0; r00[15][11] = 0             -- exit down
    rooms["0,0"] = r00

    -- Room (1,0) — upper middle, has dash-gate passage
    local r10 = solid_room()
    for c = 2, 19 do r10[13][c] = 2 end
    for c = 2, 7  do r10[9][c] = 2 end
    for c = 13, 19 do r10[9][c] = 2 end
    r10[13][10] = 3; r10[13][11] = 3             -- dash-gate on ground
    r10[1][1] = 0                                 -- exit left
    r10[14][1] = 0
    r10[1][20] = 0                                -- exit right
    r10[14][20] = 0
    r10[15][10] = 0; r10[15][11] = 0
    rooms["1,0"] = r10

    -- Room (2,0) — upper right, DOUBLE JUMP ITEM
    local r20 = solid_room()
    for c = 2, 19 do r20[13][c] = 2 end
    for c = 2, 8  do r20[9][c] = 2 end
    for c = 14, 19 do r20[5][c] = 2 end
    r20[1][1] = 0; r20[14][1] = 0                -- exit left
    r20[15][10] = 0; r20[15][11] = 0
    rooms["2,0"] = r20

    -- Room (0,1) — middle left, START ROOM
    local r01 = solid_room()
    for c = 2, 19 do r01[13][c] = 2 end
    for c = 4, 10 do r01[10][c] = 2 end
    for c = 12, 18 do r01[7][c] = 2 end
    r01[1][10] = 0; r01[1][11] = 0               -- exit up
    r01[14][20] = 0; r01[1][20] = 0              -- exit right
    r01[15][10] = 0; r01[15][11] = 0
    rooms["0,1"] = r01

    -- Room (1,1) — center, DASH ITEM
    local r11 = solid_room()
    for c = 2, 19 do r11[14][c] = 2 end
    for c = 2, 6  do r11[10][c] = 2 end
    for c = 14, 19 do r11[10][c] = 2 end
    for c = 8, 12 do r11[6][c] = 2 end
    r11[1][1] = 0; r11[14][1] = 0                -- exit left
    r11[1][20] = 0; r11[14][20] = 0              -- exit right
    r11[1][10] = 0; r11[1][11] = 0               -- exit up
    r11[15][10] = 0; r11[15][11] = 0             -- exit down
    rooms["1,1"] = r11

    -- Room (2,1) — middle right
    local r21 = solid_room()
    for c = 2, 19 do r21[13][c] = 2 end
    for c = 2, 9  do r21[8][c] = 2 end
    for c = 11, 19 do r21[5][c] = 2 end
    r21[1][1] = 0; r21[14][1] = 0
    r21[1][10] = 0; r21[1][11] = 0
    r21[15][10] = 0; r21[15][11] = 0
    rooms["2,1"] = r21

    -- Room (0,2) — bottom left
    local r02 = solid_room()
    for c = 2, 19 do r02[13][c] = 2 end
    for c = 5, 15 do r02[9][c] = 2 end
    r02[1][10] = 0; r02[1][11] = 0
    r02[14][20] = 0; r02[1][20] = 0
    rooms["0,2"] = r02

    -- Room (1,2) — bottom center
    local r12 = solid_room()
    for c = 2, 19 do r12[13][c] = 2 end
    for c = 2, 7  do r12[7][c] = 2 end
    for c = 13, 19 do r12[7][c] = 2 end
    r12[7][9] = 3; r12[7][10] = 3; r12[7][11] = 3  -- dash-gate
    r12[1][10] = 0; r12[1][11] = 0
    r12[1][1] = 0; r12[14][1] = 0
    rooms["1,2"] = r12
end

-- ── Items in the world ────────────────────────────────────────────────────
local items = {}       -- { {rx,ry,x,y,type,collected} }
local hp_pickups = {}  -- { {rx,ry,x,y,collected} }

local function define_items()
    items = {
        { rx = 1, ry = 1, x = 10 * TILE, y = 4.5 * TILE, type = "dash",   collected = false },
        { rx = 2, ry = 0, x = 16 * TILE, y = 3.5 * TILE, type = "double", collected = false },
    }
    hp_pickups = {
        { rx = 0, ry = 0, x = 5  * TILE, y = 12 * TILE, collected = false },
        { rx = 2, ry = 1, x = 15 * TILE, y = 12 * TILE, collected = false },
        { rx = 0, ry = 2, x = 10 * TILE, y = 8  * TILE, collected = false },
        { rx = 1, ry = 0, x = 5  * TILE, y = 8  * TILE, collected = false },
        { rx = 1, ry = 2, x = 15 * TILE, y = 6  * TILE, collected = false },
    }
end

-- ── Enemies ───────────────────────────────────────────────────────────────
local enemies = {}
local projectiles = {}

local function spawn_enemies_for_room(rx, ry)
    enemies = {}
    projectiles = {}
    local key = rx .. "," .. ry
    if key == "0,0" then
        enemies[#enemies + 1] = { type = "walker", x = 8*TILE, y = 12*TILE, w = 12, h = 12, vx = 40, hp = 2, patrol_l = 2*TILE, patrol_r = 18*TILE }
        enemies[#enemies + 1] = { type = "flyer",  x = 14*TILE, y = 6*TILE, w = 10, h = 10, hp = 2, cx = 14*TILE, cy = 6*TILE }
    elseif key == "1,0" then
        enemies[#enemies + 1] = { type = "walker", x = 4*TILE, y = 12*TILE, w = 12, h = 12, vx = 50, hp = 2, patrol_l = 2*TILE, patrol_r = 8*TILE }
        enemies[#enemies + 1] = { type = "turret", x = 16*TILE, y = 8*TILE, w = 12, h = 12, hp = 3, timer = 0, rate = 1.5 }
    elseif key == "2,0" then
        enemies[#enemies + 1] = { type = "flyer",  x = 6*TILE, y = 5*TILE, w = 10, h = 10, hp = 2, cx = 6*TILE, cy = 5*TILE }
        enemies[#enemies + 1] = { type = "walker", x = 10*TILE, y = 12*TILE, w = 12, h = 12, vx = 45, hp = 2, patrol_l = 2*TILE, patrol_r = 18*TILE }
    elseif key == "0,1" then
        enemies[#enemies + 1] = { type = "walker", x = 6*TILE, y = 12*TILE, w = 12, h = 12, vx = 40, hp = 2, patrol_l = 2*TILE, patrol_r = 18*TILE }
    elseif key == "1,1" then
        enemies[#enemies + 1] = { type = "turret", x = 4*TILE, y = 9*TILE, w = 12, h = 12, hp = 3, timer = 0, rate = 2.0 }
        enemies[#enemies + 1] = { type = "flyer",  x = 15*TILE, y = 5*TILE, w = 10, h = 10, hp = 2, cx = 15*TILE, cy = 5*TILE }
    elseif key == "2,1" then
        enemies[#enemies + 1] = { type = "walker", x = 5*TILE, y = 12*TILE, w = 12, h = 12, vx = 55, hp = 2, patrol_l = 2*TILE, patrol_r = 18*TILE }
        enemies[#enemies + 1] = { type = "walker", x = 14*TILE, y = 7*TILE, w = 12, h = 12, vx = 40, hp = 2, patrol_l = 11*TILE, patrol_r = 18*TILE }
    elseif key == "0,2" then
        enemies[#enemies + 1] = { type = "turret", x = 12*TILE, y = 8*TILE, w = 12, h = 12, hp = 3, timer = 0, rate = 1.8 }
    elseif key == "1,2" then
        enemies[#enemies + 1] = { type = "flyer",  x = 5*TILE, y = 5*TILE, w = 10, h = 10, hp = 2, cx = 5*TILE, cy = 5*TILE }
        enemies[#enemies + 1] = { type = "walker", x = 15*TILE, y = 12*TILE, w = 12, h = 12, vx = 50, hp = 2, patrol_l = 13*TILE, patrol_r = 18*TILE }
    end
end

-- ── Particles ─────────────────────────────────────────────────────────────
local death_particles = nil
local dash_particles  = nil
local land_particles  = nil
local pickup_particles = nil

-- ── Tween state ───────────────────────────────────────────────────────────
local fade_alpha = 0
local damage_flash = 0

-- ── Room transition ───────────────────────────────────────────────────────
local transitioning = false
local transition_timer = 0
local TRANSITION_DUR = 0.3

-- ── Helpers ───────────────────────────────────────────────────────────────
local function get_room()
    return rooms[room_x .. "," .. room_y]
end

local function tile_at(room, px, py)
    local col = math.floor(px / TILE) + 1
    local row = math.floor(py / TILE) + 1
    if col < 1 or col > ROOM_W or row < 1 or row > ROOM_H then return 0 end
    return room[row][col] or 0
end

local function is_solid(room, px, py)
    local t = tile_at(room, px, py)
    if t == 1 then return true end
    if t == 3 and not player.has_dash then return true end
    return false
end

local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- ── Reset game ────────────────────────────────────────────────────────────
local function reset_game()
    room_x, room_y = 0, 1
    player.x = 40; player.y = 180
    player.vx = 0; player.vy = 0
    player.on_ground = false
    player.touching_wall = 0
    player.hp = MAX_HP
    player.invuln = 0
    player.facing = 1
    player.has_dash = false
    player.has_double = false
    player.jumps_left = 1
    player.dashing = false
    player.dash_timer = 0
    visited = {}
    visited[room_x .. "," .. room_y] = true
    define_items()
    spawn_enemies_for_room(room_x, room_y)
    fade_alpha = 0
    damage_flash = 0
    transitioning = false
end

-- ── Update enemies ────────────────────────────────────────────────────────
local function update_enemies(dt)
    local room = get_room()
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        if e.type == "walker" then
            e.x = e.x + e.vx * dt
            if e.x <= e.patrol_l or e.x + e.w >= e.patrol_r then
                e.vx = -e.vx
            end
        elseif e.type == "flyer" then
            local dx = player.x - e.x
            local dy = player.y - e.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < 80 and dist > 1 then
                e.x = e.x + (dx / dist) * 35 * dt
                e.y = e.y + (dy / dist) * 35 * dt
            else
                -- hover around center
                e.x = e.cx + math.sin(lurek.timer.getTime() * 2) * 10
                e.y = e.cy + math.cos(lurek.timer.getTime() * 3) * 6
            end
        elseif e.type == "turret" then
            e.timer = e.timer + dt
            if e.timer >= e.rate then
                e.timer = 0
                local dx = player.x - e.x
                local dy = player.y - e.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist > 1 then
                    projectiles[#projectiles + 1] = {
                        x = e.x + e.w / 2, y = e.y + e.h / 2,
                        vx = (dx / dist) * 100, vy = (dy / dist) * 100,
                        r = 3,
                    }
                end
            end
        end

        -- Check player collision
        if player.invuln <= 0 and aabb(player.x, player.y, PLAYER_W, PLAYER_H, e.x, e.y, e.w, e.h) then
            player.hp = player.hp - 1
            player.invuln = INVULN_TIME
            damage_flash = 0.2
            if player.hp <= 0 then
                current_state = STATE.GAME_OVER
            end
        end

        -- Dash kills enemies
        if player.dashing and aabb(player.x, player.y, PLAYER_W, PLAYER_H, e.x, e.y, e.w, e.h) then
            e.hp = e.hp - 2
            if e.hp <= 0 then
                if death_particles then
                    lurek.particle.emit(death_particles, e.x + e.w / 2, e.y + e.h / 2, 8)
                end
                table.remove(enemies, i)
            end
        end
    end

    -- Update projectiles
    for i = #projectiles, 1, -1 do
        local p = projectiles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        -- Off-screen
        if p.x < 0 or p.x > LOGICAL_W or p.y < 0 or p.y > LOGICAL_H then
            table.remove(projectiles, i)
        elseif player.invuln <= 0 and aabb(player.x, player.y, PLAYER_W, PLAYER_H, p.x - p.r, p.y - p.r, p.r * 2, p.r * 2) then
            player.hp = player.hp - 1
            player.invuln = INVULN_TIME
            damage_flash = 0.2
            table.remove(projectiles, i)
            if player.hp <= 0 then
                current_state = STATE.GAME_OVER
            end
        end
    end
end

-- ── Break dash-gates ──────────────────────────────────────────────────────
local function try_break_dash_gates()
    if not player.dashing then return end
    local room = get_room()
    if not room then return end
    local cx = player.x + PLAYER_W / 2
    local cy = player.y + PLAYER_H / 2
    for dr = -1, 1 do
        for dc = -1, 1 do
            local col = math.floor(cx / TILE) + 1 + dc
            local row = math.floor(cy / TILE) + 1 + dr
            if col >= 1 and col <= ROOM_W and row >= 1 and row <= ROOM_H then
                if room[row][col] == 3 and player.has_dash then
                    room[row][col] = 0
                    if death_particles then
                        lurek.particle.emit(death_particles, (col - 0.5) * TILE, (row - 0.5) * TILE, 6)
                    end
                end
            end
        end
    end
end

-- ── load ──────────────────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Metroidvania — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.03, 0.08)

    -- Input actions
    lurek.input.addAction("left",  { "a", "left" })
    lurek.input.addAction("right", { "d", "right" })
    lurek.input.addAction("jump",  { "space", "w", "up" })
    lurek.input.addAction("dash",  { "lshift", "rshift" })
    lurek.input.addAction("quit",  { "escape" })

    -- Particle systems
    death_particles = lurek.particle.new({
        maxParticles = 30, emitRate = 0,
        lifetime = { 0.3, 0.6 },
        speed = { 30, 80 },
        colors = { { 1, 0.4, 0.2, 1 }, { 1, 0.8, 0.1, 0 } },
        sizes = { 3, 0 },
    })
    dash_particles = lurek.particle.new({
        maxParticles = 20, emitRate = 0,
        lifetime = { 0.1, 0.25 },
        speed = { 5, 15 },
        colors = { { 0.3, 0.8, 1, 0.8 }, { 0.1, 0.3, 1, 0 } },
        sizes = { 4, 1 },
    })
    land_particles = lurek.particle.new({
        maxParticles = 10, emitRate = 0,
        lifetime = { 0.15, 0.3 },
        speed = { 20, 50 },
        colors = { { 0.6, 0.5, 0.4, 0.7 }, { 0.4, 0.3, 0.2, 0 } },
        sizes = { 2, 0 },
    })
    pickup_particles = lurek.particle.new({
        maxParticles = 20, emitRate = 0,
        lifetime = { 0.3, 0.7 },
        speed = { 20, 60 },
        colors = { { 1, 1, 0.3, 1 }, { 1, 0.8, 0, 0 } },
        sizes = { 4, 1 },
    })

    define_rooms()
    reset_game()
end

-- ── update ────────────────────────────────────────────────────────────────
function lurek.process(dt)
    if current_state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.isActionJustPressed("jump") then
            current_state = STATE.PLAYING
            reset_game()
        end
        if lurek.input.isActionJustPressed("quit") then lurek.event.quit() end
        return
    end

    if current_state == STATE.GAME_OVER then
        if lurek.input.isActionJustPressed("jump") then
            current_state = STATE.TITLE
        end
        if lurek.input.isActionJustPressed("quit") then lurek.event.quit() end
        return
    end

    if lurek.input.isActionJustPressed("quit") then lurek.event.quit() end

    -- Transition fade
    if transitioning then
        transition_timer = transition_timer - dt
        fade_alpha = math.max(0, transition_timer / TRANSITION_DUR)
        if transition_timer <= 0 then
            transitioning = false
            fade_alpha = 0
        end
        return
    end

    -- Invulnerability
    if player.invuln > 0 then player.invuln = player.invuln - dt end
    if damage_flash > 0 then damage_flash = damage_flash - dt end

    local room = get_room()
    if not room then return end

    -- Dash
    if player.dashing then
        player.dash_timer = player.dash_timer - dt
        player.vx = player.dash_dir * DASH_SPEED
        player.vy = 0
        if dash_particles then
            lurek.particle.emit(dash_particles, player.x + PLAYER_W / 2, player.y + PLAYER_H / 2, 1)
        end
        if player.dash_timer <= 0 then
            player.dashing = false
            player.vx = 0
        end
        try_break_dash_gates()
    else
        -- Horizontal movement
        player.vx = 0
        if lurek.input.isActionPressed("left") then
            player.vx = -MOVE_SPEED
            player.facing = -1
        end
        if lurek.input.isActionPressed("right") then
            player.vx = MOVE_SPEED
            player.facing = 1
        end

        -- Gravity
        player.vy = player.vy + GRAVITY * dt

        -- Jump
        if lurek.input.isActionJustPressed("jump") then
            if player.on_ground then
                player.vy = JUMP_FORCE
                player.on_ground = false
                player.jumps_left = player.has_double and 1 or 0
            elseif player.touching_wall ~= 0 then
                -- Wall jump
                player.vy = JUMP_FORCE * 0.9
                player.vx = -player.touching_wall * MOVE_SPEED * 1.5
                player.facing = -player.touching_wall
                player.jumps_left = player.has_double and 1 or 0
            elseif player.jumps_left > 0 and player.has_double then
                player.vy = JUMP_FORCE * 0.85
                player.jumps_left = player.jumps_left - 1
            end
        end

        -- Dash activation
        if lurek.input.isActionJustPressed("dash") and player.has_dash and not player.dashing then
            player.dashing = true
            player.dash_timer = DASH_TIME
            player.dash_dir = player.facing
        end
    end

    -- Move X
    local new_x = player.x + player.vx * dt
    player.touching_wall = 0
    if not is_solid(room, new_x, player.y) and not is_solid(room, new_x + PLAYER_W - 1, player.y) and
       not is_solid(room, new_x, player.y + PLAYER_H - 1) and not is_solid(room, new_x + PLAYER_W - 1, player.y + PLAYER_H - 1) then
        player.x = new_x
    else
        player.vx = 0
        -- Wall detection
        if is_solid(room, player.x - 1, player.y + PLAYER_H / 2) then
            player.touching_wall = -1
        elseif is_solid(room, player.x + PLAYER_W, player.y + PLAYER_H / 2) then
            player.touching_wall = 1
        end
    end

    -- Move Y
    local was_in_air = not player.on_ground
    local new_y = player.y + player.vy * dt
    player.on_ground = false
    if not is_solid(room, player.x, new_y) and not is_solid(room, player.x + PLAYER_W - 1, new_y) and
       not is_solid(room, player.x, new_y + PLAYER_H - 1) and not is_solid(room, player.x + PLAYER_W - 1, new_y + PLAYER_H - 1) then
        player.y = new_y
    else
        if player.vy > 0 then
            player.on_ground = true
            player.jumps_left = player.has_double and 2 or 1
            if was_in_air and land_particles then
                lurek.particle.emit(land_particles, player.x + PLAYER_W / 2, player.y + PLAYER_H, 4)
            end
        end
        player.vy = 0
    end

    -- Wall touch re-check after Y move
    if not player.on_ground then
        if is_solid(room, player.x - 1, player.y + PLAYER_H / 2) then
            player.touching_wall = -1
        elseif is_solid(room, player.x + PLAYER_W, player.y + PLAYER_H / 2) then
            player.touching_wall = 1
        end
    end

    -- Room transitions
    local changed = false
    if player.x + PLAYER_W > LOGICAL_W then
        room_x = room_x + 1; player.x = 2; changed = true
    elseif player.x < 0 then
        room_x = room_x - 1; player.x = LOGICAL_W - PLAYER_W - 2; changed = true
    end
    if player.y + PLAYER_H > LOGICAL_H then
        room_y = room_y + 1; player.y = 2; changed = true
    elseif player.y < 0 then
        room_y = room_y - 1; player.y = LOGICAL_H - PLAYER_H - 2; changed = true
    end

    if changed then
        local key = room_x .. "," .. room_y
        if rooms[key] then
            visited[key] = true
            spawn_enemies_for_room(room_x, room_y)
            transitioning = true
            transition_timer = TRANSITION_DUR
            fade_alpha = 1
            player.vy = 0
        else
            -- No room there, push back
            if player.x <= 2 then room_x = room_x + 1; player.x = 40 end
            if player.x >= LOGICAL_W - PLAYER_W - 2 then room_x = room_x - 1; player.x = LOGICAL_W - 50 end
            if player.y <= 2 then room_y = room_y + 1; player.y = 40 end
            if player.y >= LOGICAL_H - PLAYER_H - 2 then room_y = room_y - 1; player.y = LOGICAL_H - 40 end
        end
    end

    -- Items
    for _, it in ipairs(items) do
        if not it.collected and it.rx == room_x and it.ry == room_y then
            if aabb(player.x, player.y, PLAYER_W, PLAYER_H, it.x - 6, it.y - 6, 12, 12) then
                it.collected = true
                if it.type == "dash" then player.has_dash = true end
                if it.type == "double" then player.has_double = true; player.jumps_left = 2 end
                if pickup_particles then
                    lurek.particle.emit(pickup_particles, it.x, it.y, 15)
                end
            end
        end
    end

    -- HP pickups
    for _, hp in ipairs(hp_pickups) do
        if not hp.collected and hp.rx == room_x and hp.ry == room_y and player.hp < MAX_HP then
            if aabb(player.x, player.y, PLAYER_W, PLAYER_H, hp.x - 4, hp.y - 4, 8, 8) then
                hp.collected = true
                player.hp = math.min(player.hp + 1, MAX_HP)
                if pickup_particles then
                    lurek.particle.emit(pickup_particles, hp.x, hp.y, 8)
                end
            end
        end
    end

    -- Enemies
    update_enemies(dt)

    -- Update particles
    if death_particles  then lurek.particle.update(death_particles, dt)  end
    if dash_particles   then lurek.particle.update(dash_particles, dt)   end
    if land_particles   then lurek.particle.update(land_particles, dt)   end
    if pickup_particles then lurek.particle.update(pickup_particles, dt) end
end

-- ── Tile colors ───────────────────────────────────────────────────────────
local TILE_COLORS = {
    [1] = { 0.25, 0.22, 0.30 },   -- wall: dark purple-grey
    [2] = { 0.45, 0.30, 0.18 },   -- platform: brown
    [3] = { 0.55, 0.15, 0.65 },   -- dash-gate: purple
}

-- ── draw ──────────────────────────────────────────────────────────────────
function lurek.render()
    if current_state == STATE.TITLE then
        local pulse = math.abs(math.sin(title_blink * 2))
        lurek.render.scale(SCALE_X, SCALE_Y)
        lurek.render.print("METROIDVANIA", LOGICAL_W / 2 - 60, LOGICAL_H / 2 - 30, { 0.4, 0.7, 1, 1 })
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.print("PRESS SPACE", LOGICAL_W / 2 - 50, LOGICAL_H / 2 + 10, { 0.7, 0.7, 0.7, pulse })
        end
        return
    end

    if current_state == STATE.GAME_OVER then
        lurek.render.scale(SCALE_X, SCALE_Y)
        lurek.render.print("GAME OVER", LOGICAL_W / 2 - 40, LOGICAL_H / 2 - 10, { 1, 0.2, 0.2, 1 })
        lurek.render.print("PRESS SPACE", LOGICAL_W / 2 - 50, LOGICAL_H / 2 + 15, { 0.7, 0.7, 0.7, 1 })
        return
    end

    -- Scale logical room to screen
    lurek.render.push()
    lurek.render.scale(SCALE_X, SCALE_Y)

    -- Draw tiles
    local room = get_room()
    if room then
        for row = 1, ROOM_H do
            for col = 1, ROOM_W do
                local t = room[row][col]
                if t and t > 0 then
                    local c = TILE_COLORS[t]
                    if c then
                        lurek.render.setColor(c[1], c[2], c[3], 1)
                        lurek.render.fillRect((col - 1) * TILE, (row - 1) * TILE, TILE, TILE)
                    end
                end
            end
        end
    end

    -- Draw HP pickups in this room
    for _, hp in ipairs(hp_pickups) do
        if not hp.collected and hp.rx == room_x and hp.ry == room_y then
            local pulse = 0.6 + 0.4 * math.sin(lurek.timer.getTime() * 4)
            lurek.render.setColor(0.2, 1, 0.3, pulse)
            lurek.render.fillCircle(hp.x, hp.y, 4)
        end
    end

    -- Draw ability items in this room
    for _, it in ipairs(items) do
        if not it.collected and it.rx == room_x and it.ry == room_y then
            local pulse = 0.7 + 0.3 * math.sin(lurek.timer.getTime() * 3)
            if it.type == "dash" then
                lurek.render.setColor(0.3, 0.8, 1, pulse)
            else
                lurek.render.setColor(1, 1, 0.3, pulse)
            end
            lurek.render.fillCircle(it.x, it.y, 6)
            lurek.render.setColor(1, 1, 1, pulse * 0.5)
            lurek.render.fillCircle(it.x, it.y, 3)
        end
    end

    -- Draw enemies
    for _, e in ipairs(enemies) do
        if e.type == "walker" then
            lurek.render.setColor(0.9, 0.2, 0.2, 1)
            lurek.render.fillRect(e.x, e.y, e.w, e.h)
        elseif e.type == "flyer" then
            lurek.render.setColor(1, 0.5, 0.1, 1)
            lurek.render.fillCircle(e.x + e.w / 2, e.y + e.h / 2, e.w / 2)
        elseif e.type == "turret" then
            lurek.render.setColor(0.8, 0.2, 0.6, 1)
            lurek.render.fillRect(e.x, e.y, e.w, e.h)
            lurek.render.setColor(1, 0.3, 0.3, 1)
            lurek.render.fillCircle(e.x + e.w / 2, e.y + e.h / 2, 3)
        end
    end

    -- Draw projectiles
    lurek.render.setColor(1, 0.3, 0.3, 0.9)
    for _, p in ipairs(projectiles) do
        lurek.render.fillCircle(p.x, p.y, p.r)
    end

    -- Draw player
    local show = true
    if player.invuln > 0 then
        show = math.floor(player.invuln * 10) % 2 == 0
    end
    if show then
        if player.dashing then
            lurek.render.setColor(0.3, 0.9, 1, 1)
        else
            lurek.render.setColor(0.3, 0.5, 1, 1)
        end
        lurek.render.fillRect(player.x, player.y, PLAYER_W, PLAYER_H)
        -- Eyes
        lurek.render.setColor(1, 1, 1, 1)
        local eye_x = player.facing == 1 and (player.x + 10) or (player.x + 4)
        lurek.render.fillRect(eye_x, player.y + 6, 3, 3)
    end

    -- Particles (in world space)
    if death_particles  then lurek.particle.draw(death_particles)  end
    if dash_particles   then lurek.particle.draw(dash_particles)   end
    if land_particles   then lurek.particle.draw(land_particles)   end
    if pickup_particles then lurek.particle.draw(pickup_particles) end

    -- Transition fade overlay
    if fade_alpha > 0 then
        lurek.render.setColor(0, 0, 0, fade_alpha)
        lurek.render.fillRect(0, 0, LOGICAL_W, LOGICAL_H)
    end

    -- Damage flash overlay
    if damage_flash > 0 then
        lurek.render.setColor(1, 0, 0, damage_flash * 0.4)
        lurek.render.fillRect(0, 0, LOGICAL_W, LOGICAL_H)
    end

    lurek.render.pop()
end

-- ── HUD (render_ui) ──────────────────────────────────────────────────────
function lurek.render_ui()
    if current_state ~= STATE.PLAYING then return end

    -- HP bar
    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    lurek.render.fillRect(8, 8, MAX_HP * 22 + 4, 18)
    for i = 1, MAX_HP do
        if i <= player.hp then
            lurek.render.setColor(0.2, 0.9, 0.3, 1)
        else
            lurek.render.setColor(0.3, 0.1, 0.1, 1)
        end
        lurek.render.fillRect(10 + (i - 1) * 22, 10, 18, 14)
    end

    -- Ability icons
    local ax = SCREEN_W - 90
    lurek.render.setColor(0.15, 0.15, 0.2, 0.8)
    lurek.render.fillRect(ax - 4, 6, 88, 22)
    -- Dash
    if player.has_dash then
        lurek.render.setColor(0.3, 0.8, 1, 1)
    else
        lurek.render.setColor(0.3, 0.3, 0.3, 0.5)
    end
    lurek.render.print("DASH", ax, 10, nil)
    -- Double jump
    if player.has_double then
        lurek.render.setColor(1, 1, 0.3, 1)
    else
        lurek.render.setColor(0.3, 0.3, 0.3, 0.5)
    end
    lurek.render.print("2xJMP", ax + 45, 10, nil)

    -- Minimap (3x3 grid)
    local mm_x = SCREEN_W - 70
    local mm_y = SCREEN_H - 70
    local mm_cell = 16
    lurek.render.setColor(0.1, 0.1, 0.15, 0.8)
    lurek.render.fillRect(mm_x - 4, mm_y - 4, 3 * mm_cell + 8, 3 * mm_cell + 8)

    for ry = 0, 2 do
        for rx = 0, 2 do
            local key = rx .. "," .. ry
            local cx = mm_x + rx * mm_cell
            local cy = mm_y + ry * mm_cell
            if rooms[key] then
                if rx == room_x and ry == room_y then
                    lurek.render.setColor(0.3, 0.7, 1, 1)
                elseif visited[key] then
                    lurek.render.setColor(0.35, 0.35, 0.45, 1)
                else
                    lurek.render.setColor(0.15, 0.15, 0.2, 0.6)
                end
                lurek.render.fillRect(cx + 1, cy + 1, mm_cell - 2, mm_cell - 2)
            end
        end
    end

    -- Room label
    lurek.render.setColor(0.5, 0.5, 0.6, 0.7)
    lurek.render.print("Room " .. room_x .. "," .. room_y, mm_x - 4, mm_y - 18, nil)

    -- FPS
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.5, 0.5, 0.5, 0.5)
    lurek.render.print(tostring(fps) .. " FPS", SCREEN_W - 60, SCREEN_H - 18, nil)
end
