-- ============================================================================
-- Paradroid — Lurek2D
-- Category: retro
-- Top-down droid shooter inspired by Andrew Braybrook's 1985 C-64 masterpiece
-- Controls: Arrow keys = move, Space = fire, E = transfer, Escape = quit
-- ============================================================================

local signal = lurek.signal
local input  = lurek.input
local gfx    = lurek.render
local tween  = lurek.tween
local particle = lurek.particle

-- Constants
local PLAY_X, PLAY_Y = 60, 40
local PLAY_W, PLAY_H = 680, 520
local CELL = 40
local COLS, ROWS = 17, 13
local BULLET_SPEED = 320
local TRANSFER_RANGE = 50
local ENERGY_DRAIN_BASE = 2
local TRANSFER_BAR_MAX = 100

-- States
local STATE_TITLE      = "TITLE"
local STATE_PLAYING    = "PLAYING"
local STATE_TRANSFER   = "TRANSFER"
local STATE_LEVEL_CLEAR = "LEVEL_CLEAR"
local STATE_GAME_OVER  = "GAME_OVER"

-- Game state
local state = STATE_TITLE
local score = 0
local level = 1
local dt = 0
local title_blink = 0

-- Player
local player = {
    x = 0, y = 0, dir = "right",
    droid_class = 1, droid_num = "001",
    hp = 1, max_hp = 1, energy = 100, max_energy = 100,
    fire_cooldown = 0, speed = 120
}

-- Enemies, bullets, particles, room
local enemies = {}
local bullets = {}
local emitters = {}
local room_walls = {}

-- Transfer mini-game state
local transfer = {
    target = nil,
    player_bar = 0, enemy_bar = 0,
    timer = 0, duration = 3.0,
    result = nil, result_timer = 0
}

-- Level definitions: {droid_count, classes_available}
local LEVELS = {
    { count = 5,  classes = {100, 100, 100, 200, 200} },
    { count = 7,  classes = {100, 200, 200, 200, 500, 500, 100} },
    { count = 9,  classes = {200, 200, 500, 500, 500, 900, 200, 100, 100} },
    { count = 11, classes = {200, 500, 500, 500, 900, 900, 900, 200, 200, 500, 100} },
}

-- Droid class stats: {hp, damage, speed, color, energy_drain_mult}
local DROID_STATS = {
    [1]   = { hp = 1, dmg = 1, spd = 120, color = {0.3, 0.8, 1.0},  drain = 0.5 },
    [100] = { hp = 1, dmg = 1, spd = 80,  color = {0.4, 0.7, 0.3},  drain = 1.0 },
    [200] = { hp = 2, dmg = 1, spd = 90,  color = {0.9, 0.7, 0.2},  drain = 1.5 },
    [500] = { hp = 3, dmg = 2, spd = 100, color = {0.9, 0.3, 0.2},  drain = 2.5 },
    [900] = { hp = 5, dmg = 3, spd = 110, color = {0.9, 0.2, 0.9},  drain = 4.0 },
}

-- Room generation
local function generate_room()
    room_walls = {}
    for r = 0, ROWS - 1 do
        room_walls[r] = {}
        for c = 0, COLS - 1 do
            if r == 0 or r == ROWS - 1 or c == 0 or c == COLS - 1 then
                room_walls[r][c] = true
            else
                room_walls[r][c] = false
            end
        end
    end
    -- Add internal walls for corridors
    math.randomseed(level * 42 + 7)
    local wall_count = 12 + level * 4
    for _ = 1, wall_count do
        local r = math.random(2, ROWS - 3)
        local c = math.random(2, COLS - 3)
        room_walls[r][c] = true
    end
    -- Ensure player start area is clear
    for r = 1, 3 do
        for c = 1, 3 do
            room_walls[r][c] = false
        end
    end
end

local function cell_to_world(c, r)
    return PLAY_X + c * CELL + CELL / 2, PLAY_Y + r * CELL + CELL / 2
end

local function world_to_cell(x, y)
    return math.floor((x - PLAY_X) / CELL), math.floor((y - PLAY_Y) / CELL)
end

local function is_wall(x, y)
    local c, r = world_to_cell(x, y)
    if r < 0 or r >= ROWS or c < 0 or c >= COLS then return true end
    return room_walls[r] and room_walls[r][c]
end

local function get_droid_stats(class)
    return DROID_STATS[class] or DROID_STATS[100]
end

-- Spawn enemies for current level
local function spawn_enemies()
    enemies = {}
    local lvl = LEVELS[level] or LEVELS[#LEVELS]
    for i = 1, lvl.count do
        local class = lvl.classes[i] or 100
        local stats = get_droid_stats(class)
        local placed = false
        for _ = 1, 50 do
            local c = math.random(4, COLS - 3)
            local r = math.random(4, ROWS - 3)
            if not room_walls[r][c] then
                local wx, wy = cell_to_world(c, r)
                local num = class + math.random(0, 99)
                enemies[#enemies + 1] = {
                    x = wx, y = wy, hp = stats.hp, max_hp = stats.hp,
                    class = class, num = string.format("%03d", num),
                    speed = stats.spd, dmg = stats.dmg,
                    dir = "down", move_timer = math.random() * 3,
                    color = stats.color, alive = true,
                    fire_cooldown = 0
                }
                placed = true
                break
            end
        end
    end
end

local function spawn_particle(x, y, r, g, b, count, speed, life)
    local e = particle.newEmitter(x, y)
    e:setColors(r, g, b, 1.0)
    e:setSpeed(speed or 60)
    e:setLifetime(life or 0.5)
    e:setSizes(3, 1)
    e:emit(count or 8)
    emitters[#emitters + 1] = { em = e, timer = (life or 0.5) + 0.2 }
end

local function init_level()
    generate_room()
    local px, py = cell_to_world(2, 2)
    player.x, player.y = px, py
    player.dir = "right"
    player.fire_cooldown = 0
    bullets = {}
    emitters = {}
    spawn_enemies()
end

local function reset_game()
    score = 0
    level = 1
    player.droid_class = 1
    player.droid_num = "001"
    local stats = get_droid_stats(1)
    player.hp = stats.hp
    player.max_hp = stats.hp
    player.energy = 100
    player.max_energy = 100
    player.speed = stats.spd
    init_level()
end

local function set_player_droid(class, num)
    player.droid_class = class
    player.droid_num = num
    local stats = get_droid_stats(class)
    player.hp = stats.hp
    player.max_hp = stats.hp
    player.energy = 100
    player.max_energy = 100
    player.speed = stats.spd
end

-- Direction vectors
local DIR_VEC = {
    up    = { dx = 0, dy = -1 },
    down  = { dx = 0, dy = 1 },
    left  = { dx = -1, dy = 0 },
    right = { dx = 1, dy = 0 },
}

local function fire_bullet(x, y, dir, dmg, owner)
    local v = DIR_VEC[dir]
    if not v then return end
    bullets[#bullets + 1] = {
        x = x, y = y, dx = v.dx * BULLET_SPEED, dy = v.dy * BULLET_SPEED,
        dmg = dmg, owner = owner, alive = true
    }
end

local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Update
local function update_playing()
    -- Player movement
    local mx, my = 0, 0
    if input.isKeyDown("up")    then my = -1; player.dir = "up" end
    if input.isKeyDown("down")  then my = 1;  player.dir = "down" end
    if input.isKeyDown("left")  then mx = -1; player.dir = "left" end
    if input.isKeyDown("right") then mx = 1;  player.dir = "right" end

    if mx ~= 0 or my ~= 0 then
        local len = math.sqrt(mx * mx + my * my)
        mx, my = mx / len, my / len
        local nx = player.x + mx * player.speed * dt
        local ny = player.y + my * player.speed * dt
        if not is_wall(nx, player.y) then player.x = nx end
        if not is_wall(player.x, ny) then player.y = ny end
        -- Clamp to play area
        player.x = math.max(PLAY_X + 12, math.min(PLAY_X + PLAY_W - 12, player.x))
        player.y = math.max(PLAY_Y + 12, math.min(PLAY_Y + PLAY_H - 12, player.y))
    end

    -- Fire
    player.fire_cooldown = math.max(0, player.fire_cooldown - dt)
    if input.isKeyDown("space") and player.fire_cooldown <= 0 then
        local stats = get_droid_stats(player.droid_class)
        fire_bullet(player.x, player.y, player.dir, stats.dmg, "player")
        player.fire_cooldown = 0.25
        local pc = stats.color or {0.5, 0.8, 1.0}
        spawn_particle(player.x, player.y, pc[1], pc[2], pc[3], 4, 80, 0.2)
    end

    -- Transfer initiate
    if input.isKeyPressed("e") then
        for _, e in ipairs(enemies) do
            if e.alive and dist(player.x, player.y, e.x, e.y) < TRANSFER_RANGE then
                state = STATE_TRANSFER
                transfer.target = e
                transfer.player_bar = 0
                transfer.enemy_bar = 0
                transfer.timer = 0
                transfer.duration = 2.5 + (e.class / 500)
                transfer.result = nil
                transfer.result_timer = 0
                return
            end
        end
    end

    -- Energy drain
    local drain = ENERGY_DRAIN_BASE * (get_droid_stats(player.droid_class).drain or 1)
    player.energy = player.energy - drain * dt
    if player.energy <= 10 then
        spawn_particle(player.x, player.y, 1, 0.3, 0.1, 1, 20, 0.3)
    end
    if player.energy <= 0 then
        player.energy = 0
        player.hp = player.hp - 1
        if player.hp <= 0 then
            spawn_particle(player.x, player.y, 1, 0.5, 0.1, 20, 120, 0.8)
            state = STATE_GAME_OVER
            return
        end
        player.energy = 20
    end

    -- Enemy AI
    for _, e in ipairs(enemies) do
        if e.alive then
            e.move_timer = e.move_timer - dt
            if e.move_timer <= 0 then
                local dirs = {"up", "down", "left", "right"}
                e.dir = dirs[math.random(#dirs)]
                e.move_timer = 1.5 + math.random() * 2
            end
            local v = DIR_VEC[e.dir]
            if v then
                local nx = e.x + v.dx * e.speed * 0.5 * dt
                local ny = e.y + v.dy * e.speed * 0.5 * dt
                if not is_wall(nx, e.y) then e.x = nx end
                if not is_wall(e.x, ny) then e.y = ny end
                e.x = math.max(PLAY_X + 12, math.min(PLAY_X + PLAY_W - 12, e.x))
                e.y = math.max(PLAY_Y + 12, math.min(PLAY_Y + PLAY_H - 12, e.y))
            end
            -- Enemy fire
            e.fire_cooldown = e.fire_cooldown - dt
            if e.fire_cooldown <= 0 and dist(player.x, player.y, e.x, e.y) < 200 then
                fire_bullet(e.x, e.y, e.dir, e.dmg, "enemy")
                e.fire_cooldown = 1.5 + math.random() * 2
            end
        end
    end

    -- Update bullets
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.dx * dt
        b.y = b.y + b.dy * dt
        -- Wall collision
        if is_wall(b.x, b.y) or b.x < PLAY_X or b.x > PLAY_X + PLAY_W or
           b.y < PLAY_Y or b.y > PLAY_Y + PLAY_H then
            spawn_particle(b.x, b.y, 1, 0.8, 0.3, 5, 60, 0.3)
            table.remove(bullets, i)
        else
            -- Hit detection
            if b.owner == "player" then
                for _, e in ipairs(enemies) do
                    if e.alive and dist(b.x, b.y, e.x, e.y) < 14 then
                        e.hp = e.hp - b.dmg
                        spawn_particle(e.x, e.y, 1, 0.6, 0.2, 6, 80, 0.3)
                        if e.hp <= 0 then
                            e.alive = false
                            score = score + e.class
                            spawn_particle(e.x, e.y, e.color[1], e.color[2], e.color[3], 16, 120, 0.7)
                        end
                        b.alive = false
                        break
                    end
                end
            elseif b.owner == "enemy" then
                if dist(b.x, b.y, player.x, player.y) < 14 then
                    player.hp = player.hp - b.dmg
                    spawn_particle(player.x, player.y, 1, 0.3, 0.3, 8, 80, 0.4)
                    if player.hp <= 0 then
                        spawn_particle(player.x, player.y, 1, 0.5, 0.1, 24, 140, 1.0)
                        state = STATE_GAME_OVER
                        return
                    end
                    b.alive = false
                end
            end
            if not b.alive then
                table.remove(bullets, i)
            end
        end
    end

    -- Update emitters
    for i = #emitters, 1, -1 do
        local em = emitters[i]
        em.timer = em.timer - dt
        em.em:update(dt)
        if em.timer <= 0 then
            table.remove(emitters, i)
        end
    end

    -- Check level clear
    local all_dead = true
    for _, e in ipairs(enemies) do
        if e.alive then all_dead = false; break end
    end
    if all_dead then
        state = STATE_LEVEL_CLEAR
    end
end

local function update_transfer()
    transfer.timer = transfer.timer + dt

    -- Player boosts with WASD
    if input.isKeyPressed("w") or input.isKeyPressed("a") or
       input.isKeyPressed("s") or input.isKeyPressed("d") then
        transfer.player_bar = transfer.player_bar + 4 + math.random() * 3
    end
    -- Enemy bar auto-advances based on class
    local enemy_rate = 8 + (transfer.target.class / 100) * 3
    transfer.enemy_bar = transfer.enemy_bar + enemy_rate * dt
    -- Player bar also auto-advances slowly
    transfer.player_bar = transfer.player_bar + 5 * dt

    -- Electricity particles
    if math.random() < 0.3 then
        spawn_particle(
            (player.x + transfer.target.x) / 2 + math.random(-20, 20),
            (player.y + transfer.target.y) / 2 + math.random(-20, 20),
            0.4, 0.7, 1.0, 3, 100, 0.2
        )
    end

    -- Time up — determine winner
    if transfer.timer >= transfer.duration then
        if transfer.player_bar >= transfer.enemy_bar then
            -- Win: take over enemy droid
            transfer.result = "WIN"
            score = score + transfer.target.class
            set_player_droid(transfer.target.class, transfer.target.num)
            player.x, player.y = transfer.target.x, transfer.target.y
            transfer.target.alive = false
            spawn_particle(player.x, player.y, 0.3, 0.8, 1.0, 20, 100, 0.6)
        else
            -- Lose: player droid destroyed
            transfer.result = "LOSE"
            spawn_particle(player.x, player.y, 1, 0.3, 0.1, 20, 120, 0.8)
        end
        transfer.result_timer = 0
    end

    -- Show result briefly then return
    if transfer.result then
        transfer.result_timer = transfer.result_timer + dt
        if transfer.result_timer > 1.5 then
            if transfer.result == "LOSE" then
                state = STATE_GAME_OVER
            else
                state = STATE_PLAYING
            end
        end
    end
end

-- Callbacks
lurek.init(function()
    lurek.window.setTitle("Paradroid — Lurek2D")
    lurek.setBackgroundColor(0.03, 0.03, 0.08)
end)

lurek.ready(function() end)

lurek.process(function(delta)
    dt = delta
    title_blink = title_blink + dt

    if input.isKeyPressed("escape") then
        signal.quit()
        return
    end

    if state == STATE_TITLE then
        if input.isKeyPressed("space") or input.isKeyPressed("return") then
            reset_game()
            state = STATE_PLAYING
        end
    elseif state == STATE_PLAYING then
        update_playing()
    elseif state == STATE_TRANSFER then
        update_transfer()
    elseif state == STATE_LEVEL_CLEAR then
        if input.isKeyPressed("space") or input.isKeyPressed("return") then
            level = level + 1
            if level > #LEVELS then
                state = STATE_GAME_OVER
            else
                init_level()
                state = STATE_PLAYING
            end
        end
    elseif state == STATE_GAME_OVER then
        if input.isKeyPressed("space") or input.isKeyPressed("return") then
            state = STATE_TITLE
        end
    end
end)

lurek.render(function()
    if state == STATE_TITLE then
        -- Title screen
        gfx.drawText("PARADROID", 240, 160, 48, 0.3, 0.8, 1.0)
        gfx.drawText("Lurek2D Remake", 290, 220, 18, 0.5, 0.5, 0.6)

        -- Animated droid number
        local display_num = math.floor(title_blink * 5) % 999
        local num_str = string.format("%03d", display_num)
        gfx.drawCircle(400, 340, 40, 0.2, 0.6, 0.8, 1.0)
        gfx.drawCircleLines(400, 340, 42, 0.4, 0.8, 1.0, 1.0)
        gfx.drawText(num_str, 376, 328, 24, 1, 1, 1)

        if math.floor(title_blink * 2) % 2 == 0 then
            gfx.drawText("PRESS SPACE TO START", 270, 440, 20, 0.8, 0.8, 0.8)
        end

        gfx.drawText("Arrow keys: Move | Space: Fire | E: Transfer", 175, 500, 14, 0.4, 0.4, 0.5)
        return
    end

    if state == STATE_GAME_OVER then
        gfx.drawText("GAME OVER", 260, 220, 48, 1, 0.3, 0.2)
        gfx.drawText("Score: " .. score, 330, 290, 24, 0.8, 0.8, 0.8)
        gfx.drawText("Level: " .. level, 345, 330, 20, 0.6, 0.6, 0.6)
        if math.floor(title_blink * 2) % 2 == 0 then
            gfx.drawText("PRESS SPACE", 320, 420, 20, 0.7, 0.7, 0.7)
        end
        return
    end

    if state == STATE_LEVEL_CLEAR then
        gfx.drawText("LEVEL " .. level .. " CLEAR", 240, 240, 40, 0.3, 1, 0.4)
        gfx.drawText("Score: " .. score, 330, 310, 24, 0.8, 0.8, 0.8)
        if math.floor(title_blink * 2) % 2 == 0 then
            gfx.drawText("PRESS SPACE FOR NEXT LEVEL", 225, 400, 18, 0.7, 0.7, 0.7)
        end
        return
    end

    -- Draw room
    -- Floor
    gfx.drawRect(PLAY_X, PLAY_Y, PLAY_W, PLAY_H, 0.08, 0.08, 0.12, 1)

    -- Walls and corridors
    for r = 0, ROWS - 1 do
        if room_walls[r] then
            for c = 0, COLS - 1 do
                local wx = PLAY_X + c * CELL
                local wy = PLAY_Y + r * CELL
                if room_walls[r][c] then
                    gfx.drawRect(wx, wy, CELL, CELL, 0.15, 0.15, 0.2, 1)
                    gfx.drawRectLines(wx, wy, CELL, CELL, 0.2, 0.2, 0.28, 1)
                else
                    -- Floor tile lines
                    gfx.drawRectLines(wx, wy, CELL, CELL, 0.06, 0.06, 0.1, 0.3)
                end
            end
        end
    end

    -- Draw bullets
    for _, b in ipairs(bullets) do
        if b.owner == "player" then
            gfx.drawCircle(b.x, b.y, 3, 0.5, 0.9, 1.0, 1)
        else
            gfx.drawCircle(b.x, b.y, 3, 1.0, 0.4, 0.2, 1)
        end
    end

    -- Draw enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            local c = e.color
            gfx.drawCircle(e.x, e.y, 14, c[1], c[2], c[3], 1)
            gfx.drawCircleLines(e.x, e.y, 15, c[1] * 0.7, c[2] * 0.7, c[3] * 0.7, 1)
            gfx.drawText(e.num, e.x - 12, e.y - 6, 12, 1, 1, 1)
            -- HP bar
            local hp_frac = e.hp / e.max_hp
            gfx.drawRect(e.x - 12, e.y - 22, 24, 3, 0.3, 0.1, 0.1, 1)
            gfx.drawRect(e.x - 12, e.y - 22, 24 * hp_frac, 3, 0.2, 0.9, 0.3, 1)
        end
    end

    -- Draw player
    local ps = get_droid_stats(player.droid_class)
    local pc = ps.color
    gfx.drawCircle(player.x, player.y, 14, pc[1], pc[2], pc[3], 1)
    gfx.drawCircleLines(player.x, player.y, 16, 1, 1, 1, 0.8)
    gfx.drawText(player.droid_num, player.x - 12, player.y - 6, 12, 1, 1, 1)

    -- Direction indicator
    local dv = DIR_VEC[player.dir]
    if dv then
        gfx.drawCircle(player.x + dv.dx * 18, player.y + dv.dy * 18, 3, 1, 1, 1, 0.7)
    end

    -- Particles
    for _, em in ipairs(emitters) do
        em.em:draw()
    end

    -- Transfer overlay
    if state == STATE_TRANSFER then
        -- Dim background
        gfx.drawRect(0, 0, 800, 600, 0, 0, 0, 0.6)

        gfx.drawText("TRANSFER SEQUENCE", 250, 100, 28, 0.4, 0.8, 1.0)
        gfx.drawText("Mash WASD to boost!", 280, 140, 16, 0.6, 0.6, 0.7)

        -- Player bar
        local bar_w = 300
        local bar_h = 30
        local bar_x = 250
        local p_frac = math.min(transfer.player_bar / TRANSFER_BAR_MAX, 1.0)
        local e_frac = math.min(transfer.enemy_bar / TRANSFER_BAR_MAX, 1.0)

        gfx.drawText("YOU [" .. player.droid_num .. "]", bar_x, 200, 16, 0.3, 0.8, 1.0)
        gfx.drawRect(bar_x, 220, bar_w, bar_h, 0.1, 0.1, 0.15, 1)
        gfx.drawRect(bar_x, 220, bar_w * p_frac, bar_h, 0.3, 0.7, 1.0, 1)
        gfx.drawRectLines(bar_x, 220, bar_w, bar_h, 0.4, 0.8, 1.0, 1)

        local te = transfer.target
        local tc = te.color
        gfx.drawText("ENEMY [" .. te.num .. "]", bar_x, 280, 16, tc[1], tc[2], tc[3])
        gfx.drawRect(bar_x, 300, bar_w, bar_h, 0.1, 0.1, 0.15, 1)
        gfx.drawRect(bar_x, 300, bar_w * e_frac, bar_h, tc[1], tc[2], tc[3], 1)
        gfx.drawRectLines(bar_x, 300, bar_w, bar_h, tc[1]*0.7, tc[2]*0.7, tc[3]*0.7, 1)

        -- Timer bar
        local time_frac = math.min(transfer.timer / transfer.duration, 1.0)
        gfx.drawRect(bar_x, 360, bar_w, 6, 0.15, 0.15, 0.2, 1)
        gfx.drawRect(bar_x, 360, bar_w * time_frac, 6, 0.8, 0.8, 0.3, 1)

        -- Result text
        if transfer.result == "WIN" then
            gfx.drawText("TRANSFER COMPLETE!", 260, 410, 24, 0.3, 1.0, 0.4)
        elseif transfer.result == "LOSE" then
            gfx.drawText("TRANSFER FAILED!", 270, 410, 24, 1.0, 0.3, 0.2)
        end
    end
end)

lurek.render_ui(function()
    if state ~= STATE_PLAYING and state ~= STATE_TRANSFER then return end

    -- Droid ID
    local ps = get_droid_stats(player.droid_class)
    local pc = ps.color
    gfx.drawRect(4, 4, 120, 28, 0.05, 0.05, 0.1, 0.9)
    gfx.drawText("DROID " .. player.droid_num, 12, 8, 18, pc[1], pc[2], pc[3])

    -- HP
    gfx.drawRect(4, 36, 120, 14, 0.1, 0.05, 0.05, 0.9)
    local hp_frac = player.hp / player.max_hp
    gfx.drawRect(4, 36, 120 * hp_frac, 14, 0.2, 0.8, 0.3, 1)
    gfx.drawText("HP", 8, 37, 11, 1, 1, 1)

    -- Energy bar
    gfx.drawRect(4, 54, 120, 14, 0.05, 0.05, 0.1, 0.9)
    local en_frac = player.energy / player.max_energy
    local er, eg, eb = 0.3, 0.6, 1.0
    if en_frac < 0.25 then er, eg, eb = 1.0, 0.3, 0.1 end
    gfx.drawRect(4, 54, 120 * en_frac, 14, er, eg, eb, 1)
    gfx.drawText("NRG", 8, 55, 11, 1, 1, 1)

    -- Score and Level
    gfx.drawRect(660, 4, 136, 28, 0.05, 0.05, 0.1, 0.9)
    gfx.drawText("SCORE " .. score, 668, 8, 16, 0.8, 0.8, 0.8)

    gfx.drawRect(660, 36, 136, 18, 0.05, 0.05, 0.1, 0.9)
    gfx.drawText("LEVEL " .. level, 668, 38, 14, 0.6, 0.6, 0.7)

    -- FPS
    if dt > 0 then
        gfx.drawText(string.format("FPS %d", math.floor(1 / dt + 0.5)), 4, 580, 12, 0.3, 0.3, 0.4)
    end
end)
