------------------------------------------------------------------------
-- Horror — Psychological Horror Survival — Lurek2D
-- Category: rpg
-- Navigate a dark facility with only a flashlight. Find 5 keys,
-- manage sanity and battery, avoid the patrolling enemy, and escape.
------------------------------------------------------------------------

-- Action input bindings:
-- up(w,up), down(s,down), left(a,left), right(d,right)
-- flashlight(f), interact(e), quit(escape)

local STATE = { TITLE = 1, PLAYING = 2, NOTE_READING = 3, DEAD = 4, WON = 5 }

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local TILE_SIZE    = 40
local MAP_COLS     = 20
local MAP_ROWS     = 15
local PLAYER_SPEED = 120
local PLAYER_RAD   = 8
local FLASH_RANGE  = 200
local FLASH_SPREAD = 0.6   -- radians half-angle
local BATTERY_MAX  = 100
local BATTERY_DRAIN= 15    -- per second
local SANITY_MAX   = 100
local SANITY_DRAIN = 5     -- per second in dark
local ENEMY_SPEED  = 50
local ENEMY_RAD    = 10
local SCARE_MIN    = 4     -- min seconds between scare events
local SCARE_MAX    = 12

-- Tile types: 0=wall, 1=floor, 2=recharge, 3=exit
local TILE_WALL    = 0
local TILE_FLOOR   = 1
local TILE_RECHARGE= 2
local TILE_EXIT    = 3

------------------------------------------------------------------------
-- Map (20x15)
------------------------------------------------------------------------
local MAP = {
local _cam = lurek.camera.new()  -- injected by fix_games.py
    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    {0,1,1,1,0,1,1,1,1,0,1,1,1,1,1,0,1,1,1,0},
    {0,1,0,1,0,1,0,0,1,0,1,0,0,0,1,0,1,0,1,0},
    {0,1,0,1,1,1,0,0,1,1,1,0,0,0,1,1,1,0,1,0},
    {0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0},
    {0,1,1,1,1,1,2,1,1,0,1,1,1,0,1,1,1,1,1,0},
    {0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0},
    {0,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,0,1,0},
    {0,1,0,1,0,1,0,0,0,0,1,0,0,0,0,0,1,0,1,0},
    {0,1,0,1,1,1,0,0,0,0,1,1,1,1,0,2,1,1,1,0},
    {0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0},
    {0,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,0,1,1,0},
    {0,0,0,0,1,0,1,0,0,0,1,0,1,0,0,1,0,0,0,0},
    {0,1,1,1,1,1,1,0,0,0,1,1,1,0,0,1,1,1,3,0},
    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
}

------------------------------------------------------------------------
-- Key positions (tile col, row) — 5 keys
------------------------------------------------------------------------
local KEY_POSITIONS = {
    { col = 2,  row = 2  },
    { col = 11, row = 2  },
    { col = 17, row = 4  },
    { col = 7,  row = 8  },
    { col = 14, row = 12 },
}

------------------------------------------------------------------------
-- Note positions and lore text
------------------------------------------------------------------------
local NOTES = {
    {
        col = 5, row = 6,
        title = "Research Log #7",
        text = "The subjects began hearing whispers after day 3. "
            .. "By day 5, they refused to turn off the lights. "
            .. "We are suspending all further trials.",
        read = false,
    },
    {
        col = 10, row = 8,
        title = "Scrawled Warning",
        text = "DON'T LET IT SEE YOU. It cannot chase what hides "
            .. "in the light. Keep your flashlight charged. "
            .. "The recharge stations still work... for now.",
        read = false,
    },
    {
        col = 4, row = 12,
        title = "Final Transmission",
        text = "To anyone receiving this: the exit is in the "
            .. "south-east corner. You need ALL FIVE keycards. "
            .. "I didn't make it. Don't repeat my mistakes.",
        read = false,
    },
}

------------------------------------------------------------------------
-- Enemy patrol path (tile col, row)
------------------------------------------------------------------------
local ENEMY_PATH = {
    { col = 1,  row = 8  },
    { col = 4,  row = 8  },
    { col = 4,  row = 10 },
    { col = 1,  row = 10 },
    { col = 1,  row = 12 },
    { col = 5,  row = 12 },
    { col = 5,  row = 8  },
    { col = 1,  row = 8  },
}

------------------------------------------------------------------------
-- Game state
------------------------------------------------------------------------
local game_state     = STATE.TITLE
local player         = { x = 1.5 * TILE_SIZE, y = 1.5 * TILE_SIZE }
local facing         = { x = 1, y = 0 }  -- flashlight direction
local flashlight_on  = true
local battery        = BATTERY_MAX
local sanity         = SANITY_MAX
local keys_found     = {}
local notes_read     = 0
local current_note   = nil

-- Enemy
local enemy          = { x = 0, y = 0, path_idx = 1, chasing = false }
local enemy_target   = { x = 0, y = 0 }

-- Scare events
local scare_timer    = 6
local scare_active   = false
local scare_text     = ""
local scare_fade     = 0

-- Screen shake
local shake_amount   = 0
local shake_decay    = 0

-- Sanity distortion
local distort_pulse  = 0
local distort_offset = { x = 0, y = 0 }

-- Hallucination
local halluc_enemies = {}
local halluc_timer   = 0

-- Title flicker
local title_time     = 0
local msg_timer      = 0
local msg_text       = ""

-- Particles
local dust_ps        = nil
local flash_ps       = nil
local glow_ps        = nil

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
local function tile_at(col, row)
    if row < 1 or row > MAP_ROWS or col < 1 or col > MAP_COLS then return TILE_WALL end
    return MAP[row][col]
end

local function is_walkable(px, py)
    local col = math.floor(px / TILE_SIZE) + 1
    local row = math.floor(py / TILE_SIZE) + 1
    local t = tile_at(col, row)
    return t == TILE_FLOOR or t == TILE_RECHARGE or t == TILE_EXIT
end

local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function normalize(x, y)
    local len = math.sqrt(x * x + y * y)
    if len < 0.001 then return 0, 0 end
    return x / len, y / len
end

local function angle_of(x, y)
    return math.atan2(y, x)
end

local function angle_diff(a, b)
    local d = b - a
    while d > math.pi do d = d - 2 * math.pi end
    while d < -math.pi do d = d + 2 * math.pi end
    return d
end

local function in_flashlight_cone(tx, ty)
    if not flashlight_on or battery <= 0 then return false end
    local dx, dy = tx - player.x, ty - player.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > FLASH_RANGE then return false end
    local target_angle = angle_of(dx, dy)
    local facing_angle = angle_of(facing.x, facing.y)
    return math.abs(angle_diff(facing_angle, target_angle)) <= FLASH_SPREAD
end

local function has_line_of_sight(x1, y1, x2, y2)
    local d = dist(x1, y1, x2, y2)
    local steps = math.ceil(d / (TILE_SIZE * 0.5))
    if steps < 1 then return true end
    for i = 1, steps do
        local t = i / steps
        local cx = x1 + (x2 - x1) * t
        local cy = y1 + (y2 - y1) * t
        local col = math.floor(cx / TILE_SIZE) + 1
        local row = math.floor(cy / TILE_SIZE) + 1
        if tile_at(col, row) == TILE_WALL then return false end
    end
    return true
end

local function show_message(text, duration)
    msg_text  = text
    msg_timer = duration or 2.0
end

local function start_shake(amount)
    shake_amount = amount
    shake_decay  = amount
end

local SCARE_MESSAGES = {
    "...you hear breathing behind you...",
    "A distant scream echoes through the halls.",
    "Something scrapes along the wall nearby.",
    "The lights flicker. Was something there?",
    "You feel cold fingers brush your neck.",
    "A door slams somewhere in the dark.",
    "Whispering... always whispering...",
}

------------------------------------------------------------------------
-- Init
------------------------------------------------------------------------

function lurek.init()
    lurek.input.bind("up",        {"w", "up"})
    lurek.input.bind("down",      {"s", "down"})
    lurek.input.bind("left",      {"a", "left"})
    lurek.input.bind("right",     {"d", "right"})
    lurek.input.bind("flashlight",{"f"})
    lurek.input.bind("interact",  {"e"})
    lurek.input.bind("quit",      {"escape"})

    -- Particle systems
    dust_ps = lurek.particle.newSystem({
        maxParticles = 30, lifetime = 1.2,
        speed = 15, spread = 6.28,
        sizeStart = 2, sizeEnd = 1,
        colorStart = {0.9, 0.85, 0.6, 0.4},
        colorEnd   = {0.7, 0.65, 0.4, 0.0},
    })
    flash_ps = lurek.particle.newSystem({
        maxParticles = 20, lifetime = 0.3,
        speed = 120, spread = 6.28,
        sizeStart = 8, sizeEnd = 2,
        colorStart = {1.0, 1.0, 1.0, 0.9},
        colorEnd   = {1.0, 0.9, 0.7, 0.0},
    })
    glow_ps = lurek.particle.newSystem({
        maxParticles = 15, lifetime = 0.8,
        speed = 25, spread = 6.28,
        sizeStart = 5, sizeEnd = 2,
        colorStart = {0.2, 1.0, 0.3, 0.8},
        colorEnd   = {0.1, 0.6, 0.2, 0.0},
    })

    -- Place enemy at start of patrol
    local ep = ENEMY_PATH[1]
    enemy.x = (ep.col - 0.5) * TILE_SIZE
    enemy.y = (ep.row - 0.5) * TILE_SIZE
    local et = ENEMY_PATH[2]
    enemy_target.x = (et.col - 0.5) * TILE_SIZE
    enemy_target.y = (et.row - 0.5) * TILE_SIZE

    -- Init keys_found
    for i = 1, #KEY_POSITIONS do keys_found[i] = false end
end

local function _ready_setup()
    lurek.render.setBackgroundColor(0.01, 0.01, 0.02)
    game_state = STATE.TITLE
end

------------------------------------------------------------------------
-- Process
------------------------------------------------------------------------
function lurek.process(dt)
    title_time = title_time + dt

    -- Quit
    if lurek.input.wasActionPressed("quit") then
        if game_state == STATE.NOTE_READING then
            current_note = nil
            game_state = STATE.PLAYING
        elseif game_state == STATE.DEAD or game_state == STATE.WON then
            lurek.event.quit()
        else
            lurek.event.quit()
        end
        return
    end

    -- Title
    if game_state == STATE.TITLE then
        if lurek.input.wasActionPressed("interact") then
            game_state = STATE.PLAYING
        end
        return
    end

    -- Dead / Won — wait for quit
    if game_state == STATE.DEAD or game_state == STATE.WON then return end

    -- Note reading
    if game_state == STATE.NOTE_READING then
        if lurek.input.wasActionPressed("interact") then
            current_note = nil
            game_state = STATE.PLAYING
        end
        return
    end

    -- ── PLAYING ───────────────────────────────────────────────

    -- Flashlight toggle
    if lurek.input.wasActionPressed("flashlight") then
        flashlight_on = not flashlight_on
    end

    -- Battery drain
    if flashlight_on and battery > 0 then
        battery = battery - BATTERY_DRAIN * dt
        if battery < 0 then
            battery = 0
            flashlight_on = false
            show_message("Battery dead!", 1.5)
        end
    end

    -- Player movement
    local dx, dy = 0, 0
    if lurek.input.isActionDown("up")    then dy = -1 end
    if lurek.input.isActionDown("down")  then dy =  1 end
    if lurek.input.isActionDown("left")  then dx = -1 end
    if lurek.input.isActionDown("right") then dx =  1 end

    if dx ~= 0 or dy ~= 0 then
        local nx, ny = normalize(dx, dy)
        facing.x, facing.y = nx, ny

        local move_x = player.x + nx * PLAYER_SPEED * dt
        local move_y = player.y + ny * PLAYER_SPEED * dt

        -- Axis-separated collision
        if is_walkable(move_x, player.y) then player.x = move_x end
        if is_walkable(player.x, move_y) then player.y = move_y end
    end

    -- Flashlight dust motes
    if flashlight_on and battery > 0 then
        local fx = player.x + facing.x * 40
        local fy = player.y + facing.y * 40
        dust_ps:emit(fx, fy, 1)
    end

    -- Recharge station check
    local pcol = math.floor(player.x / TILE_SIZE) + 1
    local prow = math.floor(player.y / TILE_SIZE) + 1
    if tile_at(pcol, prow) == TILE_RECHARGE then
        battery = math.min(battery + 40 * dt, BATTERY_MAX)
    end

    -- Key pickup check
    for i, kp in ipairs(KEY_POSITIONS) do
        if not keys_found[i] then
            local kx = (kp.col - 0.5) * TILE_SIZE
            local ky = (kp.row - 0.5) * TILE_SIZE
            if dist(player.x, player.y, kx, ky) < TILE_SIZE * 0.6 then
                keys_found[i] = true
                glow_ps:emit(kx, ky, 12)
                local count = 0
                for j = 1, #keys_found do if keys_found[j] then count = count + 1 end end
                show_message("Key found! (" .. count .. "/5)", 2.0)
                start_shake(3)
            end
        end
    end

    -- Note pickup check
    if lurek.input.wasActionPressed("interact") then
        for _, note in ipairs(NOTES) do
            if not note.read then
                local nx = (note.col - 0.5) * TILE_SIZE
                local ny = (note.row - 0.5) * TILE_SIZE
                if dist(player.x, player.y, nx, ny) < TILE_SIZE * 0.8 then
                    note.read = true
                    notes_read = notes_read + 1
                    current_note = note
                    game_state = STATE.NOTE_READING
                    break
                end
            end
        end
    end

    -- Exit check
    if tile_at(pcol, prow) == TILE_EXIT then
        local all_keys = true
        for i = 1, #keys_found do
            if not keys_found[i] then all_keys = false break end
        end
        if all_keys then
            game_state = STATE.WON
            flash_ps:emit(player.x, player.y, 20)
            return
        else
            local count = 0
            for i = 1, #keys_found do if keys_found[i] then count = count + 1 end end
            show_message("Exit locked. Need " .. (5 - count) .. " more keys.", 1.5)
        end
    end

    -- Sanity drain
    local player_lit = in_flashlight_cone(player.x + facing.x * 20, player.y + facing.y * 20)
    if not flashlight_on or battery <= 0 then
        sanity = sanity - SANITY_DRAIN * dt
    end
    if sanity < 0 then sanity = 0 end

    -- Sanity effects
    if sanity <= 0 then
        game_state = STATE.DEAD
        show_message("Your mind shatters in the darkness.", 3)
        return
    end

    -- Distortion pulse (sanity < 50)
    if sanity < 50 then
        distort_pulse = distort_pulse + dt * (2 + (50 - sanity) * 0.1)
        local intensity = (50 - sanity) / 50
        distort_offset.x = math.sin(distort_pulse * 3.7) * intensity * 4
        distort_offset.y = math.cos(distort_pulse * 2.3) * intensity * 3
    else
        distort_offset.x = 0
        distort_offset.y = 0
    end

    -- Hallucinations (sanity < 25)
    if sanity < 25 then
        halluc_timer = halluc_timer + dt
        if halluc_timer > 2.0 then
            halluc_timer = 0
            -- Spawn brief hallucination near player
            local ha = math.random() * math.pi * 2
            local hd = 80 + math.random() * 60
            halluc_enemies[#halluc_enemies + 1] = {
                x = player.x + math.cos(ha) * hd,
                y = player.y + math.sin(ha) * hd,
                life = 0.4 + math.random() * 0.4,
            }
        end
    end

    -- Update hallucinations
    for i = #halluc_enemies, 1, -1 do
        halluc_enemies[i].life = halluc_enemies[i].life - dt
        if halluc_enemies[i].life <= 0 then
            table.remove(halluc_enemies, i)
        end
    end

    -- Enemy patrol / chase
    local ed = dist(enemy.x, enemy.y, player.x, player.y)
    local can_see_player = has_line_of_sight(enemy.x, enemy.y, player.x, player.y)
    local player_in_shadow = not in_flashlight_cone(player.x, player.y)

    -- Flashlight pointed at enemy → retreat
    local light_on_enemy = in_flashlight_cone(enemy.x, enemy.y)

    if light_on_enemy and ed < FLASH_RANGE then
        -- Retreat from player
        enemy.chasing = false
        local rx, ry = normalize(enemy.x - player.x, enemy.y - player.y)
        local nx_e = enemy.x + rx * ENEMY_SPEED * 1.5 * dt
        local ny_e = enemy.y + ry * ENEMY_SPEED * 1.5 * dt
        if is_walkable(nx_e, enemy.y) then enemy.x = nx_e end
        if is_walkable(enemy.x, ny_e) then enemy.y = ny_e end
    elseif can_see_player and not player_in_shadow and ed < 250 then
        -- Chase
        enemy.chasing = true
        local cx, cy = normalize(player.x - enemy.x, player.y - enemy.y)
        local nx_e = enemy.x + cx * ENEMY_SPEED * dt
        local ny_e = enemy.y + cy * ENEMY_SPEED * dt
        if is_walkable(nx_e, enemy.y) then enemy.x = nx_e end
        if is_walkable(enemy.x, ny_e) then enemy.y = ny_e end
    else
        -- Patrol
        enemy.chasing = false
        local tx, ty = enemy_target.x, enemy_target.y
        local pd = dist(enemy.x, enemy.y, tx, ty)
        if pd < 4 then
            enemy.path_idx = enemy.path_idx + 1
            if enemy.path_idx > #ENEMY_PATH then enemy.path_idx = 1 end
            local np = ENEMY_PATH[enemy.path_idx]
            enemy_target.x = (np.col - 0.5) * TILE_SIZE
            enemy_target.y = (np.row - 0.5) * TILE_SIZE
        else
            local px_e, py_e = normalize(tx - enemy.x, ty - enemy.y)
            local nx_e = enemy.x + px_e * ENEMY_SPEED * dt
            local ny_e = enemy.y + py_e * ENEMY_SPEED * dt
            if is_walkable(nx_e, enemy.y) then enemy.x = nx_e end
            if is_walkable(enemy.x, ny_e) then enemy.y = ny_e end
        end
    end

    -- Enemy contact = death
    if dist(player.x, player.y, enemy.x, enemy.y) < (PLAYER_RAD + ENEMY_RAD) then
        game_state = STATE.DEAD
        flash_ps:emit(player.x, player.y, 15)
        start_shake(10)
        show_message("It caught you.", 3)
        return
    end

    -- Shake near enemy
    if ed < 120 and not light_on_enemy then
        shake_amount = math.max(shake_amount, (120 - ed) / 120 * 3)
    end

    -- Scare events
    scare_timer = scare_timer - dt
    if scare_timer <= 0 then
        scare_timer = SCARE_MIN + math.random() * (SCARE_MAX - SCARE_MIN)
        scare_text  = SCARE_MESSAGES[math.random(#SCARE_MESSAGES)]
        scare_fade  = 3.0
        scare_active = true
        start_shake(4)
        flash_ps:emit(player.x, player.y, 8)
    end
    if scare_active then
        scare_fade = scare_fade - dt
        if scare_fade <= 0 then scare_active = false end
    end

    -- Screen shake decay
    if shake_amount > 0 then
        shake_amount = shake_amount - shake_amount * 5 * dt
        if shake_amount < 0.1 then shake_amount = 0 end
    end
    lurek.tween.update(dt)

    -- Message timer
    if msg_timer > 0 then msg_timer = msg_timer - dt end

    -- Update particles
    dust_ps:update(dt)
    flash_ps:update(dt)
    glow_ps:update(dt)

    -- Camera + title
    local sx = shake_amount > 0 and (math.random() - 0.5) * shake_amount * 2 or 0
    local sy = shake_amount > 0 and (math.random() - 0.5) * shake_amount * 2 or 0
    _cam:setPosition(
        player.x - SCREEN_W / 2 + sx + distort_offset.x,
        player.y - SCREEN_H / 2 + sy + distort_offset.y
    )
    lurek.render.setBackgroundColor(0.01, 0.01, 0.02)
    local fps = lurek.timer.getFPS()
    lurek.window.setTitle("Horror — Lurek2D [FPS: " .. fps .. "]")
end

------------------------------------------------------------------------
-- Render (world)
------------------------------------------------------------------------
function lurek.draw()
    if game_state == STATE.TITLE then
        -- Dark background
        lurek.render.setColor(0.02, 0.01, 0.03, 1)
        lurek.render.rectangle(-400, -300, SCREEN_W + 800, SCREEN_H + 600)

        -- Flickering title
        local flicker = math.sin(title_time * 7) * 0.3 + 0.7
        if math.random() < 0.05 then flicker = 0.2 end
        lurek.render.setColor(0.8 * flicker, 0.1 * flicker, 0.1 * flicker, 1)
        lurek.render.print("HORROR", SCREEN_W / 2 - 80, SCREEN_H / 2 - 60, 40)

        lurek.render.setColor(0.5 * flicker, 0.5 * flicker, 0.5 * flicker, 0.8)
        lurek.render.print("FIND THE KEYS. ESCAPE.", SCREEN_W / 2 - 110, SCREEN_H / 2 + 10, 14)

        local blink = math.sin(title_time * 3) > 0
        if blink then
            lurek.render.setColor(0.5, 0.5, 0.4, 0.7)
            lurek.render.print("Press [E] to start", SCREEN_W / 2 - 80, SCREEN_H / 2 + 80, 12)
        end
        return
    end

    if game_state == STATE.DEAD then
        lurek.render.setColor(0.15, 0.02, 0.02, 1)
        lurek.render.rectangle(
            player.x - SCREEN_W, player.y - SCREEN_H,
            SCREEN_W * 2, SCREEN_H * 2
        )
        lurek.render.setColor(0.9, 0.1, 0.1, 1)
        lurek.render.print("YOU DIED", player.x - 60, player.y - 20, 32)
        lurek.render.setColor(0.6, 0.3, 0.3, 0.8)
        lurek.render.print("The darkness consumed you.", player.x - 100, player.y + 30, 14)
        lurek.render.print("Press [Escape] to quit.", player.x - 90, player.y + 60, 12)
        flash_ps:draw()
        return
    end

    if game_state == STATE.WON then
        lurek.render.setColor(0.02, 0.06, 0.02, 1)
        lurek.render.rectangle(
            player.x - SCREEN_W, player.y - SCREEN_H,
            SCREEN_W * 2, SCREEN_H * 2
        )
        local glow = 0.7 + 0.3 * math.sin(title_time * 2)
        lurek.render.setColor(0.2 * glow, 0.9 * glow, 0.3 * glow, 1)
        lurek.render.print("ESCAPED", player.x - 60, player.y - 20, 32)
        lurek.render.setColor(0.4, 0.7, 0.4, 0.8)
        lurek.render.print("You made it out alive.", player.x - 90, player.y + 30, 14)
        lurek.render.print("Press [Escape] to quit.", player.x - 90, player.y + 60, 12)
        flash_ps:draw()
        return
    end

    -- ── Map tiles ─────────────────────────────────────────────
    for row = 1, MAP_ROWS do
        for col = 1, MAP_COLS do
            local tx = (col - 1) * TILE_SIZE
            local ty = (row - 1) * TILE_SIZE
            local tile = MAP[row][col]
            local center_x = tx + TILE_SIZE / 2
            local center_y = ty + TILE_SIZE / 2

            -- Visibility: tiles in flashlight cone are bright, nearby tiles dim, rest dark
            local lit = in_flashlight_cone(center_x, center_y)
            local d_to_player = dist(player.x, player.y, center_x, center_y)
            local ambient = math.max(0, 0.08 - d_to_player * 0.0003)

            local brightness = ambient
            if lit then
                local cone_d = dist(player.x, player.y, center_x, center_y)
                brightness = math.max(0.15, 1.0 - cone_d / FLASH_RANGE) * 0.9
            end

            if tile == TILE_WALL then
                lurek.render.setColor(0.12 * brightness, 0.10 * brightness, 0.15 * brightness, 1)
                lurek.render.rectangle(tx, ty, TILE_SIZE, TILE_SIZE)
                -- Wall edge highlight
                lurek.render.setColor(0.18 * brightness, 0.15 * brightness, 0.22 * brightness, 1)
                lurek.render.rectangle("line", tx, ty, TILE_SIZE, TILE_SIZE, 1)
            elseif tile == TILE_FLOOR then
                lurek.render.setColor(0.22 * brightness, 0.20 * brightness, 0.18 * brightness, 1)
                lurek.render.rectangle(tx, ty, TILE_SIZE, TILE_SIZE)
            elseif tile == TILE_RECHARGE then
                local pulse = 0.5 + 0.5 * math.sin(title_time * 3)
                lurek.render.setColor(0.1 * brightness, 0.3 * brightness * pulse, 0.15 * brightness, 1)
                lurek.render.rectangle(tx, ty, TILE_SIZE, TILE_SIZE)
                -- Recharge icon
                lurek.render.setColor(0.2, 0.8 * pulse, 0.3, brightness * 0.6)
                lurek.render.rectangle("line", tx + 8, ty + 8, TILE_SIZE - 16, TILE_SIZE - 16, 2)
            elseif tile == TILE_EXIT then
                local pulse = 0.5 + 0.5 * math.sin(title_time * 2)
                lurek.render.setColor(0.35 * brightness * pulse, 0.12 * brightness, 0.12 * brightness, 1)
                lurek.render.rectangle(tx, ty, TILE_SIZE, TILE_SIZE)
                lurek.render.setColor(0.9, 0.2, 0.2, brightness * 0.7)
                lurek.render.print("EXIT", tx + 4, ty + 14, 10)
            end
        end
    end

    -- ── Keys ──────────────────────────────────────────────────
    for i, kp in ipairs(KEY_POSITIONS) do
        if not keys_found[i] then
            local kx = (kp.col - 0.5) * TILE_SIZE
            local ky = (kp.row - 0.5) * TILE_SIZE
            local lit = in_flashlight_cone(kx, ky)
            local d_k = dist(player.x, player.y, kx, ky)
            local vis = lit and math.max(0.3, 1 - d_k / FLASH_RANGE) or 0.05
            local bob = math.sin(title_time * 3 + i) * 3
            lurek.render.setColor(0.9 * vis, 0.8 * vis, 0.1 * vis, vis)
            lurek.render.rectangle(kx - 5, ky - 5 + bob, 10, 10)
        end
    end

    -- ── Notes ─────────────────────────────────────────────────
    for _, note in ipairs(NOTES) do
        if not note.read then
            local nx = (note.col - 0.5) * TILE_SIZE
            local ny = (note.row - 0.5) * TILE_SIZE
            local lit = in_flashlight_cone(nx, ny)
            local vis = lit and 0.7 or 0.03
            lurek.render.setColor(0.9 * vis, 0.9 * vis, 0.7 * vis, vis)
            lurek.render.rectangle(nx - 6, ny - 4, 12, 8)
            lurek.render.setColor(0.3 * vis, 0.3 * vis, 0.2 * vis, vis)
            lurek.render.line(nx - 4, ny - 1, nx + 4, ny - 1, 1)
            lurek.render.line(nx - 4, ny + 1, nx + 4, ny + 1, 1)
        end
    end

    -- ── Enemy ─────────────────────────────────────────────────
    local enemy_lit = in_flashlight_cone(enemy.x, enemy.y)
    local d_enemy = dist(player.x, player.y, enemy.x, enemy.y)
    local enemy_vis = enemy_lit and math.max(0.3, 1 - d_enemy / FLASH_RANGE) or 0.0
    if d_enemy < 60 then enemy_vis = math.max(enemy_vis, 0.15) end -- always slightly visible up close

    if enemy_vis > 0.01 then
        local r = enemy.chasing and 0.9 or 0.4
        lurek.render.setColor(r * enemy_vis, 0.05 * enemy_vis, 0.1 * enemy_vis, enemy_vis)
        lurek.render.circle(enemy.x, enemy.y, ENEMY_RAD)
        -- Eyes
        lurek.render.setColor(1.0 * enemy_vis, 0.2 * enemy_vis, 0.2 * enemy_vis, enemy_vis * 0.9)
        lurek.render.circle(enemy.x - 3, enemy.y - 3, 2)
        lurek.render.circle(enemy.x + 3, enemy.y - 3, 2)
    end

    -- ── Hallucination enemies ─────────────────────────────────
    for _, h in ipairs(halluc_enemies) do
        local ha = h.life * 2
        lurek.render.setColor(0.6, 0.0, 0.1, ha * 0.5)
        lurek.render.circle(h.x, h.y, 8)
        lurek.render.setColor(0.9, 0.1, 0.1, ha * 0.3)
        lurek.render.circle(h.x - 2, h.y - 2, 2)
        lurek.render.circle(h.x + 2, h.y - 2, 2)
    end

    -- ── Flashlight cone (visual) ──────────────────────────────
    if flashlight_on and battery > 0 then
        local fa = angle_of(facing.x, facing.y)
        local segments = 12
        for s = 0, segments - 1 do
            local a1 = fa - FLASH_SPREAD + (2 * FLASH_SPREAD) * (s / segments)
            local a2 = fa - FLASH_SPREAD + (2 * FLASH_SPREAD) * ((s + 1) / segments)
            local r = FLASH_RANGE
            local alpha = 0.06 - s * 0.003
            lurek.render.setColor(1, 0.95, 0.7, alpha)
            -- Draw cone segment as triangle approximation (line fan)
            lurek.render.line(
                player.x, player.y,
                player.x + math.cos(a1) * r, player.y + math.sin(a1) * r, 2
            )
        end
        -- Outer arc
        lurek.render.setColor(1, 0.95, 0.7, 0.04)
        for s = 0, segments do
            local a = fa - FLASH_SPREAD + (2 * FLASH_SPREAD) * (s / segments)
            lurek.render.circle(
                player.x + math.cos(a) * FLASH_RANGE,
                player.y + math.sin(a) * FLASH_RANGE, 2
            )
        end
    end

    -- ── Player ────────────────────────────────────────────────
    local p_bright = (flashlight_on and battery > 0) and 0.9 or 0.3
    lurek.render.setColor(0.7 * p_bright, 0.75 * p_bright, 0.9 * p_bright, 1)
    lurek.render.circle(player.x, player.y, PLAYER_RAD)
    -- Direction indicator
    lurek.render.setColor(1, 0.95, 0.5, p_bright * 0.8)
    lurek.render.circle(
        player.x + facing.x * (PLAYER_RAD + 3),
        player.y + facing.y * (PLAYER_RAD + 3), 2
    )

    -- ── Particles ─────────────────────────────────────────────
    dust_ps:draw()
    flash_ps:draw()
    glow_ps:draw()

    -- ── Sanity color overlay ──────────────────────────────────
    if sanity < 50 then
        local intensity = (50 - sanity) / 50
        local r_shift = math.sin(distort_pulse) * intensity * 0.15
        lurek.render.setColor(0.3 + r_shift, 0.0, 0.1, intensity * 0.15)
        lurek.render.rectangle(
            player.x - SCREEN_W / 2, player.y - SCREEN_H / 2,
            SCREEN_W, SCREEN_H
        )
    end
end

------------------------------------------------------------------------
-- Render UI
------------------------------------------------------------------------
function lurek.draw_ui()
    if game_state == STATE.TITLE or game_state == STATE.DEAD or game_state == STATE.WON then
        return
    end

    -- ── Sanity bar ────────────────────────────────────────────
    lurek.render.setColor(0, 0, 0, 0.7)
    lurek.render.rectangle(10, 10, 154, 18)
    local san_ratio = sanity / SANITY_MAX
    local san_r = 1 - san_ratio
    local san_g = san_ratio
    lurek.render.setColor(san_r, san_g, 0.1, 0.9)
    lurek.render.rectangle(12, 12, 150 * san_ratio, 14)
    lurek.render.setColor(1, 1, 1, 0.9)
    lurek.render.print("Sanity: " .. math.floor(sanity), 14, 13, 11)

    -- ── Battery bar ───────────────────────────────────────────
    lurek.render.setColor(0, 0, 0, 0.7)
    lurek.render.rectangle(10, 32, 154, 18)
    local bat_ratio = battery / BATTERY_MAX
    lurek.render.setColor(0.9 * bat_ratio, 0.8 * bat_ratio, 0.1, 0.9)
    lurek.render.rectangle(12, 34, 150 * bat_ratio, 14)
    lurek.render.setColor(1, 1, 1, 0.9)
    local fl_status = flashlight_on and "ON" or "OFF"
    lurek.render.print("Battery: " .. math.floor(battery) .. " [" .. fl_status .. "]", 14, 35, 11)

    -- ── Keys counter ──────────────────────────────────────────
    local key_count = 0
    for i = 1, #keys_found do if keys_found[i] then key_count = key_count + 1 end end
    lurek.render.setColor(0, 0, 0, 0.7)
    lurek.render.rectangle(10, 54, 100, 18)
    lurek.render.setColor(0.9, 0.8, 0.2, 1)
    lurek.render.print("Keys: " .. key_count .. "/5", 14, 57, 11)

    -- ── Notes counter ─────────────────────────────────────────
    lurek.render.setColor(0, 0, 0, 0.7)
    lurek.render.rectangle(10, 76, 100, 18)
    lurek.render.setColor(0.8, 0.8, 0.6, 1)
    lurek.render.print("Notes: " .. notes_read .. "/3", 14, 79, 11)

    -- ── Controls hint ─────────────────────────────────────────
    lurek.render.setColor(0.5, 0.5, 0.4, 0.6)
    lurek.render.print("WASD:move  F:flashlight  E:interact  ESC:quit", 10, SCREEN_H - 20, 10)

    -- ── Message popup ─────────────────────────────────────────
    if msg_timer > 0 then
        local alpha = math.min(1, msg_timer)
        lurek.render.setColor(0, 0, 0, 0.7 * alpha)
        lurek.render.rectangle(SCREEN_W / 2 - 150, SCREEN_H / 2 - 16, 300, 32)
        lurek.render.setColor(1, 0.9, 0.5, alpha)
        lurek.render.print(msg_text, SCREEN_W / 2 - 140, SCREEN_H / 2 - 8, 13)
    end

    -- ── Scare event text ──────────────────────────────────────
    if scare_active and scare_fade > 0 then
        local alpha = math.min(1, scare_fade)
        lurek.render.setColor(0.8, 0.1, 0.1, alpha * 0.6)
        lurek.render.print(scare_text, SCREEN_W / 2 - 160, 120, 13)
    end

    -- ── Note reading overlay ──────────────────────────────────
    if game_state == STATE.NOTE_READING and current_note then
        lurek.render.setColor(0, 0, 0, 0.85)
        lurek.render.rectangle(60, 100, SCREEN_W - 120, 300)
        lurek.render.setColor(0.6, 0.5, 0.3, 1)
        lurek.render.rectangle("line", 60, 100, SCREEN_W - 120, 300, 2)

        lurek.render.setColor(0.95, 0.9, 0.7, 1)
        lurek.render.print(current_note.title, 90, 130, 18)

        lurek.render.setColor(0.85, 0.8, 0.65, 0.9)
        -- Word-wrap: split text manually into ~50 char lines
        local text = current_note.text
        local y = 170
        while #text > 0 do
            local line = string.sub(text, 1, 55)
            local last_space = 55
            if #text > 55 then
                last_space = line:find(" [^ ]*$") or 55
                line = string.sub(text, 1, last_space)
            end
            lurek.render.print(line, 90, y, 12)
            y = y + 18
            text = string.sub(text, last_space + 1)
        end

        local blink = math.sin(title_time * 3) > 0
        if blink then
            lurek.render.setColor(0.6, 0.55, 0.4, 0.7)
            lurek.render.print("[E] close", SCREEN_W - 180, 370, 11)
        end
    end
end
