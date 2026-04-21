-- ============================================================================
--  Stealth — Top-down stealth game with vision cones and suspicion
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/stealth
--
--  Controls (bound as input actions — see lurek.init):
--    up/down/left/right : W/A/S/D or ↑←↓→
--    crouch             : Shift (slower, harder to detect)
--    interact           : E (enter/exit hide spots)
--    quit               : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600
local TILE               = 40
local MAP_COLS           = 20
local MAP_ROWS           = 15
local MAP_W              = MAP_COLS * TILE  -- 800
local MAP_H              = MAP_ROWS * TILE  -- 600

local PLAYER_R           = 8
local WALK_SPEED         = 120
local CROUCH_SPEED       = 60

local VISION_RANGE       = 5 * TILE   -- 200 px
local VISION_HALF_ANGLE  = math.pi / 6  -- 30° half = 60° total
local CROUCH_RANGE_MULT  = 0.6

local SUSPICION_FILL     = 40   -- per second when visible
local SUSPICION_DRAIN    = 20   -- per second when hidden
local SUSPICION_INVESTIGATE = 50
local SUSPICION_ALERT    = 100

local GUARD_PATROL_SPEED = 60
local GUARD_CHASE_SPEED  = 100
local GUARD_INVEST_SPEED = 80
local NOISE_RADIUS       = 3 * TILE
local NOISE_ATTRACT_DIST = 4 * TILE

-- Tile codes
local T_FLOOR  = 0
local T_WALL   = 1
local T_HIDE   = 2
local T_KEY    = 3
local T_EXIT   = 4
local T_SPAWN  = 5

-- ── State enum ────────────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3, LEVEL_COMPLETE = 4 }
local game_state = STATE.TITLE

-- ── Game state ────────────────────────────────────────────────────────────
local player = {
    x = 0, y = 0, r = PLAYER_R,
    crouching = false, hidden = false, hide_spot = nil,
    keys_collected = 0, alive = true,
    noise_timer = 0,
}
local guards       = {}
local keycards     = {}
local hide_spots   = {}
local tiles        = {}
local exit_pos     = { x = 0, y = 0 }
local current_level = 1
local title_blink  = 0
local message      = { text = "", alpha = 0 }

-- Particles
local noise_ps     = nil
local alert_ps     = nil
local sparkle_ps   = nil

-- Tween state
local susp_bar     = { value = 0 }
local alert_flash  = { alpha = 0 }

-- ── Level data ────────────────────────────────────────────────────────────
-- 0=floor, 1=wall, 2=hide, 3=keycard, 4=exit, 5=player spawn
-- Guards defined separately per level
local LEVELS = {}

LEVELS[1] = {
    map = {
        "11111111111111111111",
        "15000001100000000001",
        "10000001100000020001",
        "10000000000000000001",
        "10001110011100001001",
        "10001000000100001001",
        "10001003000100000001",
        "10000000000000011101",
        "10011100001110000001",
        "10010000000010000001",
        "10010002000010030001",
        "10000000000000000001",
        "10001111000011110001",
        "10000000002000000041",
        "11111111111111111111",
    },
    guards = {
        { path = {{5,3},{5,7},{5,3}}, dir = math.pi/2 },
        { path = {{14,5},{14,10},{14,5}}, dir = -math.pi/2 },
        { path = {{10,8},{15,8},{10,8}}, dir = 0 },
    },
}

LEVELS[2] = {
    map = {
        "11111111111111111111",
        "15000000010000000001",
        "10000020010000030001",
        "10000000010000000001",
        "11101110000011101111",
        "10000000000000000001",
        "10003000011000020001",
        "10000000011000000001",
        "10011100000001110001",
        "10000000000000000001",
        "11100011000110001101",
        "10000010000010000001",
        "10020010003010000001",
        "10000000000000000041",
        "11111111111111111111",
    },
    guards = {
        { path = {{4,2},{4,6},{4,2}}, dir = math.pi/2 },
        { path = {{8,5},{8,9},{8,5}}, dir = math.pi/2 },
        { path = {{14,2},{14,7},{14,2}}, dir = math.pi/2 },
        { path = {{12,10},{17,10},{12,10}}, dir = 0 },
    },
}

LEVELS[3] = {
    map = {
        "11111111111111111111",
        "15000110000011000001",
        "10000110000011002001",
        "10000000000000000001",
        "11100001111000011101",
        "10000001001000000001",
        "10030001001000030001",
        "10000000000000000001",
        "10011100001110010001",
        "10000000000000010001",
        "10000200000020010001",
        "10111001110011000001",
        "10000000000000000001",
        "10000020000000000041",
        "11111111111111111111",
    },
    guards = {
        { path = {{3,2},{3,6},{3,2}}, dir = math.pi/2 },
        { path = {{9,1},{9,6},{9,1}}, dir = math.pi/2 },
        { path = {{16,2},{16,6},{16,2}}, dir = math.pi/2 },
        { path = {{6,8},{6,12},{6,8}}, dir = math.pi/2 },
        { path = {{14,8},{14,12},{14,8}}, dir = math.pi/2 },
    },
}

-- ── Helpers ───────────────────────────────────────────────────────────────

--- Get tile type at grid col, row (0-indexed)
local function tile_at(col, row)
    if col < 0 or col >= MAP_COLS or row < 0 or row >= MAP_ROWS then return T_WALL end
    return tiles[row * MAP_COLS + col + 1] or T_WALL
end

--- Check if a world position is a wall
local function is_wall(wx, wy)
    local col = math.floor(wx / TILE)
    local row = math.floor(wy / TILE)
    return tile_at(col, row) == T_WALL
end

--- Line of sight check between two points (Bresenham on tile grid)
local function has_line_of_sight(x1, y1, x2, y2)
    local c1, r1 = math.floor(x1 / TILE), math.floor(y1 / TILE)
    local c2, r2 = math.floor(x2 / TILE), math.floor(y2 / TILE)
    local dc = math.abs(c2 - c1)
    local dr = math.abs(r2 - r1)
    local sc = c1 < c2 and 1 or -1
    local sr = r1 < r2 and 1 or -1
    local err = dc - dr
    while true do
        if tile_at(c1, r1) == T_WALL then return false end
        if c1 == c2 and r1 == r2 then break end
        local e2 = 2 * err
        if e2 > -dr then err = err - dr; c1 = c1 + sc end
        if e2 < dc  then err = err + dc; r1 = r1 + sr end
    end
    return true
end

--- Angle between two points
local function angle_to(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

--- Distance between two points
local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

--- Normalize angle to [-pi, pi]
local function norm_angle(a)
    while a > math.pi  do a = a - 2 * math.pi end
    while a < -math.pi do a = a + 2 * math.pi end
    return a
end

--- Check if angle b is within half_angle of angle a
local function angle_in_cone(a, b, half_angle)
    return math.abs(norm_angle(b - a)) <= half_angle
end

--- Move entity with wall collision, returns new x, y
local function move_with_collision(x, y, dx, dy, r)
    local nx = x + dx
    if is_wall(nx - r, y) or is_wall(nx + r, y) then nx = x end
    local ny = y + dy
    if is_wall(nx, ny - r) or is_wall(nx, ny + r) then ny = y end
    -- clamp to map
    nx = math.max(r, math.min(MAP_W - r, nx))
    ny = math.max(r, math.min(MAP_H - r, ny))
    return nx, ny
end

--- Load a level by index
local function load_level(idx)
    local lvl = LEVELS[idx]
    if not lvl then return end

    tiles = {}
    keycards = {}
    hide_spots = {}
    guards = {}
    player.keys_collected = 0
    player.hidden = false
    player.hide_spot = nil
    player.alive = true
    player.crouching = false

    -- Parse map
    for row = 0, MAP_ROWS - 1 do
        local line = lvl.map[row + 1]
        for col = 0, MAP_COLS - 1 do
            local ch = tonumber(line:sub(col + 1, col + 1)) or 0
            local ti = row * MAP_COLS + col + 1
            if ch == T_SPAWN then
                player.x = col * TILE + TILE / 2
                player.y = row * TILE + TILE / 2
                tiles[ti] = T_FLOOR
            elseif ch == T_KEY then
                keycards[#keycards + 1] = {
                    x = col * TILE + TILE / 2,
                    y = row * TILE + TILE / 2,
                    collected = false,
                }
                tiles[ti] = T_FLOOR
            elseif ch == T_HIDE then
                hide_spots[#hide_spots + 1] = {
                    x = col * TILE, y = row * TILE,
                    w = TILE, h = TILE, occupied = false,
                }
                tiles[ti] = T_FLOOR
            elseif ch == T_EXIT then
                exit_pos.x = col * TILE
                exit_pos.y = row * TILE
                tiles[ti] = T_EXIT
            else
                tiles[ti] = ch
            end
        end
    end

    -- Setup guards
    for _, gd in ipairs(lvl.guards) do
        local wp = gd.path[1]
        guards[#guards + 1] = {
            x = wp[1] * TILE + TILE / 2,
            y = wp[2] * TILE + TILE / 2,
            dir = gd.dir,
            path = gd.path,
            path_idx = 1,
            suspicion = 0,
            mode = "patrol",   -- patrol | investigate | chase
            last_seen_x = 0, last_seen_y = 0,
            return_timer = 0,
        }
    end

    game_state = STATE.PLAYING
end

--- Show a timed message
local function show_message(text)
    message.text = text
    message.alpha = 1.0
    lurek.tween.to(message, 2.0, { alpha = 0 })
end

-- ── Engine callbacks ──────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Stealth — Lurek2D")
    lurek.window.setBackgroundColor(0.05, 0.08, 0.05)

    -- Input actions
    lurek.input.addAction("up",       {"w", "up"})
    lurek.input.addAction("down",     {"s", "down"})
    lurek.input.addAction("left",     {"a", "left"})
    lurek.input.addAction("right",    {"d", "right"})
    lurek.input.addAction("crouch",   {"lshift", "rshift"})
    lurek.input.addAction("interact", {"e"})
    lurek.input.addAction("quit",     {"escape"})

    -- Particle systems
    noise_ps = lurek.particle.new({
        maxParticles = 30, lifetime = 0.6,
        speed = 50, spread = 6.28,
        sizeStart = 6, sizeEnd = 12,
        colorStart = {0.8, 0.8, 0.6, 0.4},
        colorEnd   = {0.8, 0.8, 0.6, 0.0},
    })
    alert_ps = lurek.particle.new({
        maxParticles = 20, lifetime = 0.4,
        speed = 80, spread = 6.28,
        sizeStart = 4, sizeEnd = 2,
        colorStart = {1.0, 0.3, 0.1, 1.0},
        colorEnd   = {1.0, 0.1, 0.0, 0.0},
    })
    sparkle_ps = lurek.particle.new({
        maxParticles = 15, lifetime = 0.5,
        speed = 60, spread = 6.28,
        sizeStart = 3, sizeEnd = 1,
        colorStart = {1.0, 0.95, 0.3, 1.0},
        colorEnd   = {1.0, 0.85, 0.1, 0.0},
    })
end

function lurek.ready()
    game_state = STATE.TITLE
end

-- ── Process ───────────────────────────────────────────────────────────────
lurek.process(function(dt)
    -- Quit
    if lurek.input.isActionJustPressed("quit") then
        lurek.event.quit()
        return
    end

    -- Title screen
    if game_state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.isKeyJustPressed("return") then
            current_level = 1
            load_level(1)
        end
        return
    end

    -- Game over / level complete — press Enter to restart/continue
    if game_state == STATE.GAME_OVER or game_state == STATE.LEVEL_COMPLETE then
        if lurek.input.isKeyJustPressed("return") then
            if game_state == STATE.LEVEL_COMPLETE then
                current_level = current_level + 1
                if current_level > #LEVELS then
                    game_state = STATE.TITLE
                else
                    load_level(current_level)
                end
            else
                game_state = STATE.TITLE
            end
        end
        return
    end

    if not player.alive then return end

    -- ── Player movement ──
    local spd = WALK_SPEED
    player.crouching = lurek.input.isActionPressed("crouch")
    if player.crouching then spd = CROUCH_SPEED end

    local moving = false
    if not player.hidden then
        local dx, dy = 0, 0
        if lurek.input.isActionPressed("left")  then dx = dx - 1 end
        if lurek.input.isActionPressed("right") then dx = dx + 1 end
        if lurek.input.isActionPressed("up")    then dy = dy - 1 end
        if lurek.input.isActionPressed("down")  then dy = dy + 1 end

        -- Normalize diagonal
        if dx ~= 0 and dy ~= 0 then
            local inv = 1 / math.sqrt(2)
            dx, dy = dx * inv, dy * inv
        end

        if dx ~= 0 or dy ~= 0 then
            moving = true
            player.x, player.y = move_with_collision(
                player.x, player.y, dx * spd * dt, dy * spd * dt, PLAYER_R
            )
        end
    end

    -- Noise generation (walking, not crouching)
    if moving and not player.crouching and not player.hidden then
        player.noise_timer = player.noise_timer + dt
        if player.noise_timer >= 0.4 then
            player.noise_timer = 0
            noise_ps:emit(player.x, player.y, 8)
            -- Attract nearby guards
            for _, g in ipairs(guards) do
                if dist(player.x, player.y, g.x, g.y) < NOISE_ATTRACT_DIST then
                    if g.mode == "patrol" then
                        g.mode = "investigate"
                        g.last_seen_x = player.x
                        g.last_seen_y = player.y
                        g.return_timer = 3.0
                    end
                end
            end
        end
    else
        player.noise_timer = 0
    end

    -- Interact — enter/exit hide spots
    if lurek.input.isActionJustPressed("interact") then
        if player.hidden then
            player.hidden = false
            if player.hide_spot then player.hide_spot.occupied = false end
            player.hide_spot = nil
        else
            for _, hs in ipairs(hide_spots) do
                local cx = hs.x + hs.w / 2
                local cy = hs.y + hs.h / 2
                if dist(player.x, player.y, cx, cy) < TILE then
                    player.hidden = true
                    player.hide_spot = hs
                    hs.occupied = true
                    player.x = cx
                    player.y = cy
                    break
                end
            end
        end
    end

    -- Keycard collection
    for _, kc in ipairs(keycards) do
        if not kc.collected and not player.hidden then
            if dist(player.x, player.y, kc.x, kc.y) < TILE * 0.6 then
                kc.collected = true
                player.keys_collected = player.keys_collected + 1
                sparkle_ps:emit(kc.x, kc.y, 12)
                show_message("Keycard " .. player.keys_collected .. "/3")
            end
        end
    end

    -- Exit check
    if player.keys_collected >= 3 and not player.hidden then
        local ecx = exit_pos.x + TILE / 2
        local ecy = exit_pos.y + TILE / 2
        if dist(player.x, player.y, ecx, ecy) < TILE * 0.7 then
            game_state = STATE.LEVEL_COMPLETE
            if current_level >= #LEVELS then
                show_message("YOU WIN! All levels complete!")
            else
                show_message("Level " .. current_level .. " complete!")
            end
            return
        end
    end

    -- ── Guard AI ──
    for _, g in ipairs(guards) do
        -- Vision detection
        local can_see = false
        if not player.hidden then
            local d = dist(g.x, g.y, player.x, player.y)
            local range = VISION_RANGE
            if player.crouching then range = range * CROUCH_RANGE_MULT end

            if d < range then
                local a = angle_to(g.x, g.y, player.x, player.y)
                if angle_in_cone(g.dir, a, VISION_HALF_ANGLE) then
                    if has_line_of_sight(g.x, g.y, player.x, player.y) then
                        can_see = true
                    end
                end
            end
        end

        -- Suspicion update
        if can_see then
            g.suspicion = math.min(SUSPICION_ALERT, g.suspicion + SUSPICION_FILL * dt)
            g.last_seen_x = player.x
            g.last_seen_y = player.y
        else
            g.suspicion = math.max(0, g.suspicion - SUSPICION_DRAIN * dt)
        end

        -- Mode transitions
        if g.suspicion >= SUSPICION_ALERT then
            if g.mode ~= "chase" then
                g.mode = "chase"
                alert_ps:emit(g.x, g.y - 12, 15)
                alert_flash.alpha = 0.4
                lurek.tween.to(alert_flash, 0.5, { alpha = 0 })
            end
        elseif g.suspicion >= SUSPICION_INVESTIGATE then
            if g.mode == "patrol" then
                g.mode = "investigate"
                g.return_timer = 4.0
            end
        elseif g.suspicion <= 5 and g.mode == "investigate" then
            g.return_timer = g.return_timer - dt
            if g.return_timer <= 0 then
                g.mode = "patrol"
            end
        end

        -- Reset from chase when suspicion drops
        if g.mode == "chase" and g.suspicion <= 10 then
            g.mode = "investigate"
            g.return_timer = 3.0
        end

        -- Movement
        if g.mode == "patrol" then
            -- Follow patrol path
            local wp = g.path[g.path_idx]
            local tx = wp[1] * TILE + TILE / 2
            local ty = wp[2] * TILE + TILE / 2
            local d = dist(g.x, g.y, tx, ty)
            if d < 4 then
                g.path_idx = g.path_idx + 1
                if g.path_idx > #g.path then g.path_idx = 1 end
                wp = g.path[g.path_idx]
                tx = wp[1] * TILE + TILE / 2
                ty = wp[2] * TILE + TILE / 2
            end
            local a = angle_to(g.x, g.y, tx, ty)
            g.dir = a
            g.x = g.x + math.cos(a) * GUARD_PATROL_SPEED * dt
            g.y = g.y + math.sin(a) * GUARD_PATROL_SPEED * dt

        elseif g.mode == "investigate" then
            local d = dist(g.x, g.y, g.last_seen_x, g.last_seen_y)
            if d > 6 then
                local a = angle_to(g.x, g.y, g.last_seen_x, g.last_seen_y)
                g.dir = a
                g.x = g.x + math.cos(a) * GUARD_INVEST_SPEED * dt
                g.y = g.y + math.sin(a) * GUARD_INVEST_SPEED * dt
            else
                g.return_timer = g.return_timer - dt
                if g.return_timer <= 0 then g.mode = "patrol" end
            end

        elseif g.mode == "chase" then
            local a = angle_to(g.x, g.y, player.x, player.y)
            g.dir = a
            g.x = g.x + math.cos(a) * GUARD_CHASE_SPEED * dt
            g.y = g.y + math.sin(a) * GUARD_CHASE_SPEED * dt

            -- Catch player
            if dist(g.x, g.y, player.x, player.y) < TILE * 0.5 then
                player.alive = false
                game_state = STATE.GAME_OVER
                alert_ps:emit(player.x, player.y, 20)
                show_message("DETECTED! Game Over")
                return
            end
        end
    end

    -- Update particles
    noise_ps:update(dt)
    alert_ps:update(dt)
    sparkle_ps:update(dt)

    -- Suspicion bar tween target
    local max_susp = 0
    for _, g in ipairs(guards) do
        if g.suspicion > max_susp then max_susp = g.suspicion end
    end
    susp_bar.value = max_susp

    -- Camera
    lurek.camera.setPosition(0, 0)

    -- FPS in title
    local fps = lurek.timer.getFPS()
    lurek.window.setTitle("Stealth — Lurek2D [FPS: " .. fps .. "]")
end)

-- ── Render (world) ────────────────────────────────────────────────────────
lurek.render(function()
    if game_state == STATE.TITLE then return end

    -- Draw tiles
    for row = 0, MAP_ROWS - 1 do
        for col = 0, MAP_COLS - 1 do
            local t = tile_at(col, row)
            local tx = col * TILE
            local ty = row * TILE

            if t == T_WALL then
                lurek.render.setColor(0.2, 0.2, 0.25, 1)
                lurek.render.rectangle(tx, ty, TILE, TILE)
            elseif t == T_EXIT then
                if player.keys_collected >= 3 then
                    lurek.render.setColor(0.1, 0.8, 0.2, 0.8)
                else
                    lurek.render.setColor(0.1, 0.4, 0.15, 0.5)
                end
                lurek.render.rectangle(tx, ty, TILE, TILE)
            else
                lurek.render.setColor(0.08, 0.12, 0.08, 1)
                lurek.render.rectangle(tx, ty, TILE, TILE)
                -- Grid lines
                lurek.render.setColor(0.1, 0.15, 0.1, 1)
                lurek.render.line(tx, ty, tx + TILE, ty, 1)
                lurek.render.line(tx, ty, tx, ty + TILE, 1)
            end
        end
    end

    -- Draw hide spots
    for _, hs in ipairs(hide_spots) do
        lurek.render.setColor(0.4, 0.28, 0.12, 0.9)
        lurek.render.rectangle(hs.x + 2, hs.y + 2, hs.w - 4, hs.h - 4)
        -- Crate marks
        lurek.render.setColor(0.3, 0.2, 0.08, 1)
        lurek.render.line(hs.x + 4, hs.y + 4, hs.x + hs.w - 4, hs.y + hs.h - 4, 1)
        lurek.render.line(hs.x + hs.w - 4, hs.y + 4, hs.x + 4, hs.y + hs.h - 4, 1)
    end

    -- Draw keycards
    for _, kc in ipairs(keycards) do
        if not kc.collected then
            lurek.render.setColor(1.0, 0.9, 0.15, 1)
            lurek.render.rectangle(kc.x - 6, kc.y - 4, 12, 8)
            -- Key notch
            lurek.render.setColor(0.8, 0.7, 0.1, 1)
            lurek.render.rectangle(kc.x + 3, kc.y - 2, 4, 4)
        end
    end

    -- Draw guard vision cones
    for _, g in ipairs(guards) do
        local cone_r = VISION_RANGE
        local cr, cg_col, cb, ca

        if g.mode == "chase" or g.suspicion >= SUSPICION_ALERT then
            cr, cg_col, cb, ca = 0.9, 0.15, 0.1, 0.2
        elseif g.suspicion >= SUSPICION_INVESTIGATE then
            cr, cg_col, cb, ca = 0.9, 0.8, 0.1, 0.15
        else
            cr, cg_col, cb, ca = 0.2, 0.7, 0.2, 0.1
        end

        -- Draw cone as a filled triangle fan
        local segments = 12
        local step = (VISION_HALF_ANGLE * 2) / segments
        local start_a = g.dir - VISION_HALF_ANGLE

        lurek.render.setColor(cr, cg_col, cb, ca)
        for i = 0, segments - 1 do
            local a1 = start_a + i * step
            local a2 = start_a + (i + 1) * step
            lurek.render.drawTriangle(
                g.x, g.y,
                g.x + math.cos(a1) * cone_r, g.y + math.sin(a1) * cone_r,
                g.x + math.cos(a2) * cone_r, g.y + math.sin(a2) * cone_r
            )
        end

        -- Cone edge lines
        lurek.render.setColor(cr, cg_col, cb, ca + 0.15)
        local la = g.dir - VISION_HALF_ANGLE
        local ra = g.dir + VISION_HALF_ANGLE
        lurek.render.line(g.x, g.y, g.x + math.cos(la) * cone_r, g.y + math.sin(la) * cone_r, 1)
        lurek.render.line(g.x, g.y, g.x + math.cos(ra) * cone_r, g.y + math.sin(ra) * cone_r, 1)
    end

    -- Draw guards
    for _, g in ipairs(guards) do
        -- Body
        if g.mode == "chase" then
            lurek.render.setColor(1.0, 0.2, 0.1, 1)
        elseif g.mode == "investigate" then
            lurek.render.setColor(0.9, 0.7, 0.1, 1)
        else
            lurek.render.setColor(0.8, 0.2, 0.2, 1)
        end
        lurek.render.rectangle(g.x - 10, g.y - 10, 20, 20)

        -- Direction indicator
        lurek.render.setColor(1, 1, 1, 0.9)
        local dx = math.cos(g.dir) * 12
        local dy = math.sin(g.dir) * 12
        lurek.render.line(g.x, g.y, g.x + dx, g.y + dy, 2)

        -- Suspicion indicator above guard
        if g.suspicion > 5 then
            local bw = 20
            local bh = 3
            local bx = g.x - bw / 2
            local by = g.y - 18
            lurek.render.setColor(0.3, 0.3, 0.3, 0.7)
            lurek.render.rectangle(bx, by, bw, bh)
            local fill = (g.suspicion / SUSPICION_ALERT) * bw
            if g.suspicion >= SUSPICION_ALERT then
                lurek.render.setColor(1, 0.1, 0.1, 0.9)
            elseif g.suspicion >= SUSPICION_INVESTIGATE then
                lurek.render.setColor(1, 0.8, 0.1, 0.9)
            else
                lurek.render.setColor(0.2, 0.8, 0.2, 0.9)
            end
            lurek.render.rectangle(bx, by, fill, bh)
        end

        -- Exclamation mark when alert
        if g.mode == "chase" then
            lurek.render.setColor(1, 0.2, 0.1, 1)
            lurek.render.print("!", g.x - 3, g.y - 26)
        elseif g.mode == "investigate" then
            lurek.render.setColor(1, 0.9, 0.2, 1)
            lurek.render.print("?", g.x - 3, g.y - 26)
        end
    end

    -- Draw player
    if not player.hidden then
        if player.crouching then
            lurek.render.setColor(0.3, 0.7, 0.4, 0.8)
            lurek.render.circle(player.x, player.y, PLAYER_R - 2)
        else
            lurek.render.setColor(0.3, 0.85, 0.4, 1)
            lurek.render.circle(player.x, player.y, PLAYER_R)
        end
    end

    -- Draw particles (world-space)
    noise_ps:draw()
    alert_ps:draw()
    sparkle_ps:draw()

    -- Alert flash overlay
    if alert_flash.alpha > 0 then
        lurek.render.setColor(1, 0.1, 0.05, alert_flash.alpha)
        lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H)
    end
end)

-- ── Render UI ─────────────────────────────────────────────────────────────
function lurek.render_ui()
    if game_state == STATE.TITLE then
        -- Title screen
        lurek.render.setColor(0.2, 0.9, 0.3, 1)
        lurek.render.print("STEALTH", SCREEN_W / 2 - 50, SCREEN_H / 2 - 60)

        local show = math.floor(title_blink * 2) % 2 == 0
        if show then
            lurek.render.setColor(0.7, 0.9, 0.7, 0.8)
            lurek.render.print("PRESS ENTER", SCREEN_W / 2 - 55, SCREEN_H / 2 + 10)
        end

        lurek.render.setColor(0.5, 0.6, 0.5, 0.6)
        lurek.render.print("Sneak past guards. Collect keycards. Reach the exit.", 175, SCREEN_H / 2 + 60)
        return
    end

    -- HUD — keycards
    lurek.render.setColor(1, 0.9, 0.2, 1)
    lurek.render.print("KEYS: " .. player.keys_collected .. "/3", 10, 10)

    -- Level indicator
    lurek.render.setColor(0.7, 0.8, 0.7, 0.8)
    lurek.render.print("LEVEL " .. current_level, SCREEN_W / 2 - 25, 10)

    -- Suspicion bar (top-right)
    if susp_bar.value > 0 then
        local bw = 100
        local bh = 8
        local bx = SCREEN_W - bw - 10
        local by = 10
        lurek.render.setColor(0.3, 0.3, 0.3, 0.7)
        lurek.render.rectangle(bx, by, bw, bh)
        local fill = (susp_bar.value / SUSPICION_ALERT) * bw
        if susp_bar.value >= SUSPICION_ALERT then
            lurek.render.setColor(1, 0.1, 0.1, 1)
        elseif susp_bar.value >= SUSPICION_INVESTIGATE then
            lurek.render.setColor(1, 0.8, 0.1, 1)
        else
            lurek.render.setColor(0.2, 0.8, 0.2, 1)
        end
        lurek.render.rectangle(bx, by, fill, bh)
        lurek.render.setColor(0.8, 0.8, 0.8, 0.7)
        lurek.render.print("SUSPICION", bx, by + 12)
    end

    -- Crouch indicator
    if player.crouching and not player.hidden then
        lurek.render.setColor(0.5, 0.8, 0.5, 0.6)
        lurek.render.print("CROUCHING", 10, SCREEN_H - 25)
    end

    -- Hidden indicator
    if player.hidden then
        lurek.render.setColor(0.4, 0.7, 0.9, 0.7)
        lurek.render.print("HIDDEN", 10, SCREEN_H - 25)
    end

    -- Message overlay
    if message.alpha > 0 then
        lurek.render.setColor(1, 1, 1, message.alpha)
        lurek.render.print(message.text, SCREEN_W / 2 - 60, SCREEN_H / 2 - 10)
    end

    -- Game over screen
    if game_state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H)
        lurek.render.setColor(1, 0.2, 0.15, 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 45, SCREEN_H / 2 - 30)
        lurek.render.setColor(0.8, 0.8, 0.8, 0.8)
        lurek.render.print("Press ENTER to return to title", SCREEN_W / 2 - 100, SCREEN_H / 2 + 10)
    end

    -- Level complete screen
    if game_state == STATE.LEVEL_COMPLETE then
        lurek.render.setColor(0, 0, 0, 0.5)
        lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H)
        lurek.render.setColor(0.2, 0.9, 0.3, 1)
        if current_level >= #LEVELS then
            lurek.render.print("ALL LEVELS COMPLETE!", SCREEN_W / 2 - 75, SCREEN_H / 2 - 30)
        else
            lurek.render.print("LEVEL " .. current_level .. " COMPLETE!", SCREEN_W / 2 - 65, SCREEN_H / 2 - 30)
        end
        lurek.render.setColor(0.8, 0.8, 0.8, 0.8)
        lurek.render.print("Press ENTER to continue", SCREEN_W / 2 - 80, SCREEN_H / 2 + 10)
    end
end
