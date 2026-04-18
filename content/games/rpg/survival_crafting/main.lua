-- ============================================================================
-- Survival Crafting — Lurek2D
-- Category: rpg
-- A grid-based survival crafting game with day/night cycle, resource gathering,
-- crafting, wall building, and enemy waves at night.
-- ============================================================================

local STATE_TITLE     = "TITLE"
local STATE_PLAYING   = "PLAYING"
local STATE_CRAFT     = "CRAFT_MENU"
local STATE_GAME_OVER = "GAME_OVER"

local TILE     = 32
local MAP_W    = 25
local MAP_H    = 18
local SCREEN_W = 800
local SCREEN_H = 600

-- Tile types
local T_GRASS = 0
local T_STONE = 1
local T_TREE  = 2
local T_WATER = 3
local T_BERRY = 4
local T_WALL  = 5

local TILE_COLORS = {
    [T_GRASS] = {0.30, 0.65, 0.20},
    [T_STONE] = {0.55, 0.55, 0.50},
    [T_TREE]  = {0.15, 0.45, 0.12},
    [T_WATER] = {0.20, 0.40, 0.75},
    [T_BERRY] = {0.60, 0.20, 0.50},
    [T_WALL]  = {0.45, 0.35, 0.25},
}

-- Game state
local state = STATE_TITLE
local map = {}
local player = {}
local inventory = {}
local enemies = {}
local particles = {}
local day_time = 0
local day_count = 1
local survival_time = 0
local mining = {active = false, timer = 0, target_x = 0, target_y = 0}
local night_alpha = 0
local camera_x, camera_y = 0, 0

local DAY_LENGTH     = 60
local NIGHT_START    = 0.6
local MOVE_COOLDOWN  = 0.15
local MINE_TIME      = 1.0
local MINE_TIME_PICK = 0.5
local ENEMY_SPEED    = 60
local ENEMY_DAMAGE   = 15
local HUNGER_DRAIN   = 2
local HP_DRAIN       = 5
local BERRY_HUNGER   = 20

-- Direction vectors
local DIR = {
    up    = {dx = 0, dy = -1},
    down  = {dx = 0, dy =  1},
    left  = {dx = -1, dy = 0},
    right = {dx =  1, dy = 0},
}

-- ============================================================================
-- Map generation
-- ============================================================================
local function generate_map()
    map = {}
    for y = 1, MAP_H do
        map[y] = {}
        for x = 1, MAP_W do
            local r = math.random(100)
            if r <= 5 then
                map[y][x] = T_WATER
            elseif r <= 15 then
                map[y][x] = T_TREE
            elseif r <= 22 then
                map[y][x] = T_STONE
            elseif r <= 27 then
                map[y][x] = T_BERRY
            else
                map[y][x] = T_GRASS
            end
        end
    end
    -- Ensure player spawn area is grass
    for dy = -1, 1 do
        for dx = -1, 1 do
            local py = math.floor(MAP_H / 2) + dy
            local px = math.floor(MAP_W / 2) + dx
            if py >= 1 and py <= MAP_H and px >= 1 and px <= MAP_W then
                map[py][px] = T_GRASS
            end
        end
    end
end

-- ============================================================================
-- Player init
-- ============================================================================
local function reset_player()
    player = {
        gx = math.floor(MAP_W / 2),
        gy = math.floor(MAP_H / 2),
        hp = 100,
        hunger = 100,
        facing = "down",
        move_cd = 0,
        alive = true,
    }
    inventory = {wood = 0, stone = 0, berry = 0, pickaxe = 0, wall = 0}
    enemies = {}
    particles = {}
    day_time = 0
    day_count = 1
    survival_time = 0
    mining = {active = false, timer = 0, target_x = 0, target_y = 0}
    night_alpha = 0
end

-- ============================================================================
-- Particles
-- ============================================================================
local function spawn_particles(wx, wy, count, r, g, b, life, spread)
    spread = spread or 40
    for i = 1, count do
        particles[#particles + 1] = {
            x = wx + math.random(-4, 4),
            y = wy + math.random(-4, 4),
            vx = (math.random() - 0.5) * spread,
            vy = (math.random() - 0.5) * spread - 20,
            life = life or (0.4 + math.random() * 0.4),
            max_life = life or 0.6,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
        }
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 40 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            particles[i] = particles[#particles]
            particles[#particles] = nil
        else
            i = i + 1
        end
    end
end

-- ============================================================================
-- Enemy logic
-- ============================================================================
local function spawn_enemy()
    local side = math.random(4)
    local ex, ey
    if side == 1 then ex = math.random() * SCREEN_W; ey = -20
    elseif side == 2 then ex = math.random() * SCREEN_W; ey = SCREEN_H + 20
    elseif side == 3 then ex = -20; ey = math.random() * SCREEN_H
    else ex = SCREEN_W + 20; ey = math.random() * SCREEN_H end
    enemies[#enemies + 1] = {x = ex, y = ey, hp = 30}
end

local function tile_at(gx, gy)
    if gy < 1 or gy > MAP_H or gx < 1 or gx > MAP_W then return T_WATER end
    return map[gy][gx]
end

local function is_solid(gx, gy)
    local t = tile_at(gx, gy)
    return t == T_WATER or t == T_WALL or t == T_STONE or t == T_TREE
end

local function update_enemies(dt)
    local px = (player.gx - 1) * TILE + TILE / 2
    local py = (player.gy - 1) * TILE + TILE / 2
    local i = 1
    while i <= #enemies do
        local e = enemies[i]
        local dx = px - e.x
        local dy = py - e.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 1 then
            local nx = dx / dist
            local ny = dy / dist
            local new_x = e.x + nx * ENEMY_SPEED * dt
            local new_y = e.y + ny * ENEMY_SPEED * dt
            -- Wall collision check
            local gx = math.floor(new_x / TILE) + 1
            local gy = math.floor(new_y / TILE) + 1
            if tile_at(gx, gy) ~= T_WALL then
                e.x = new_x
                e.y = new_y
            end
        end
        -- Damage player on contact
        if dist < TILE * 0.6 and player.alive then
            player.hp = player.hp - ENEMY_DAMAGE * dt
            if player.hp <= 0 then
                player.hp = 0
                player.alive = false
            end
        end
        i = i + 1
    end
end

-- ============================================================================
-- Input bindings
-- ============================================================================
lurek.init(function()
    lurek.window.setTitle("Survival Crafting — Lurek2D")
    lurek.render.setBackgroundColor(0.30, 0.65, 0.20)

    lurek.input.bind("up",    {"w", "up"})
    lurek.input.bind("down",  {"s", "down"})
    lurek.input.bind("left",  {"a", "left"})
    lurek.input.bind("right", {"d", "right"})
    lurek.input.bind("mine",  {"space"})
    lurek.input.bind("craft", {"c"})
    lurek.input.bind("place", {"p"})
    lurek.input.bind("eat",   {"b"})
    lurek.input.bind("quit",  {"escape"})
    lurek.input.bind("start", {"return"})

    math.randomseed(os.time())
end)

lurek.ready(function()
    lurek.camera.setPosition(0, 0)
end)

-- ============================================================================
-- Start / restart
-- ============================================================================
local function start_game()
    generate_map()
    reset_player()
    state = STATE_PLAYING
    lurek.render.setBackgroundColor(0.30, 0.65, 0.20)
end

-- ============================================================================
-- Process
-- ============================================================================
lurek.process(function(dt)
    if lurek.input.isActionJustPressed("quit") then
        lurek.signal.quit()
        return
    end

    -- Title screen
    if state == STATE_TITLE then
        if lurek.input.isActionJustPressed("start") then
            start_game()
        end
        return
    end

    -- Game over
    if state == STATE_GAME_OVER then
        if lurek.input.isActionJustPressed("start") then
            start_game()
        end
        return
    end

    -- Craft menu toggle
    if state == STATE_CRAFT then
        if lurek.input.isActionJustPressed("craft") then
            state = STATE_PLAYING
        end
        -- Crafting choices via number keys
        if lurek.input.isKeyJustPressed("1") then
            if inventory.wood >= 2 and inventory.stone >= 3 then
                inventory.wood = inventory.wood - 2
                inventory.stone = inventory.stone - 3
                inventory.pickaxe = inventory.pickaxe + 1
                local wx = (player.gx - 1) * TILE + TILE / 2
                local wy = (player.gy - 1) * TILE + TILE / 2
                spawn_particles(wx, wy, 12, 1.0, 0.9, 0.2, 0.6, 50)
            end
        end
        if lurek.input.isKeyJustPressed("2") then
            if inventory.wood >= 4 then
                inventory.wood = inventory.wood - 4
                inventory.wall = inventory.wall + 1
                local wx = (player.gx - 1) * TILE + TILE / 2
                local wy = (player.gy - 1) * TILE + TILE / 2
                spawn_particles(wx, wy, 8, 0.7, 0.5, 0.3, 0.5, 30)
            end
        end
        update_particles(dt)
        return
    end

    -- ---- STATE_PLAYING ----
    survival_time = survival_time + dt

    -- Day/night cycle
    day_time = day_time + dt
    if day_time >= DAY_LENGTH then
        day_time = day_time - DAY_LENGTH
        day_count = day_count + 1
    end
    local day_frac = day_time / DAY_LENGTH
    local is_night = day_frac >= NIGHT_START
    local target_alpha = 0
    if is_night then
        target_alpha = 0.55 + 0.15 * math.sin((day_frac - NIGHT_START) / (1 - NIGHT_START) * math.pi)
    end
    -- Tween night overlay
    night_alpha = night_alpha + (target_alpha - night_alpha) * math.min(1, dt * 3)

    -- Background color based on day/night
    local bg_r = 0.30 - night_alpha * 0.20
    local bg_g = 0.65 - night_alpha * 0.40
    local bg_b = 0.20 + night_alpha * 0.10
    lurek.render.setBackgroundColor(bg_r, bg_g, bg_b)

    -- Hunger and HP drain
    player.hunger = player.hunger - HUNGER_DRAIN * dt
    if player.hunger < 0 then player.hunger = 0 end
    if player.hunger <= 0 then
        player.hp = player.hp - HP_DRAIN * dt
    end
    if player.hp <= 0 then
        player.hp = 0
        player.alive = false
        state = STATE_GAME_OVER
        return
    end

    -- Movement
    player.move_cd = player.move_cd - dt
    if player.move_cd <= 0 and not mining.active then
        for name, dir in pairs(DIR) do
            if lurek.input.isActionPressed(name) then
                local nx = player.gx + dir.dx
                local ny = player.gy + dir.dy
                player.facing = name
                if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H then
                    local t = map[ny][nx]
                    if t == T_GRASS or t == T_BERRY then
                        player.gx = nx
                        player.gy = ny
                        player.move_cd = MOVE_COOLDOWN
                    end
                end
                break
            end
        end
    end

    -- Mining
    if lurek.input.isActionJustPressed("mine") and not mining.active then
        local dir = DIR[player.facing]
        if dir then
            local tx = player.gx + dir.dx
            local ty = player.gy + dir.dy
            local t = tile_at(tx, ty)
            if t == T_TREE or t == T_STONE or t == T_BERRY then
                mining.active = true
                mining.target_x = tx
                mining.target_y = ty
                mining.timer = (inventory.pickaxe > 0) and MINE_TIME_PICK or MINE_TIME
            end
        end
    end
    if mining.active then
        mining.timer = mining.timer - dt
        -- Mining debris particles
        if math.random() < dt * 15 then
            local wx = (mining.target_x - 1) * TILE + TILE / 2
            local wy = (mining.target_y - 1) * TILE + TILE / 2
            spawn_particles(wx, wy, 2, 0.7, 0.6, 0.4, 0.3, 25)
        end
        if mining.timer <= 0 then
            local t = tile_at(mining.target_x, mining.target_y)
            local wx = (mining.target_x - 1) * TILE + TILE / 2
            local wy = (mining.target_y - 1) * TILE + TILE / 2
            if t == T_TREE then
                inventory.wood = inventory.wood + 2
                spawn_particles(wx, wy, 10, 0.15, 0.45, 0.12, 0.5, 40)
            elseif t == T_STONE then
                inventory.stone = inventory.stone + 2
                spawn_particles(wx, wy, 10, 0.55, 0.55, 0.50, 0.5, 40)
            elseif t == T_BERRY then
                inventory.berry = inventory.berry + 3
                spawn_particles(wx, wy, 8, 0.8, 0.2, 0.6, 0.5, 35)
            end
            map[mining.target_y][mining.target_x] = T_GRASS
            mining.active = false
        end
    end

    -- Eat berry
    if lurek.input.isActionJustPressed("eat") and inventory.berry > 0 then
        inventory.berry = inventory.berry - 1
        player.hunger = math.min(100, player.hunger + BERRY_HUNGER)
        local wx = (player.gx - 1) * TILE + TILE / 2
        local wy = (player.gy - 1) * TILE + TILE / 2
        spawn_particles(wx, wy, 6, 0.8, 0.2, 0.6, 0.4, 30)
    end

    -- Craft menu open
    if lurek.input.isActionJustPressed("craft") then
        state = STATE_CRAFT
        return
    end

    -- Place wall
    if lurek.input.isActionJustPressed("place") and inventory.wall > 0 then
        local dir = DIR[player.facing]
        if dir then
            local tx = player.gx + dir.dx
            local ty = player.gy + dir.dy
            if tx >= 1 and tx <= MAP_W and ty >= 1 and ty <= MAP_H then
                if map[ty][tx] == T_GRASS then
                    map[ty][tx] = T_WALL
                    inventory.wall = inventory.wall - 1
                    local wx = (tx - 1) * TILE + TILE / 2
                    local wy = (ty - 1) * TILE + TILE / 2
                    spawn_particles(wx, wy, 8, 0.45, 0.35, 0.25, 0.4, 30)
                end
            end
        end
    end

    -- Enemy spawning at night
    if is_night then
        if math.random() < dt * (1.0 + day_count * 0.3) then
            spawn_enemy()
        end
        -- Night atmosphere motes
        if math.random() < dt * 5 then
            spawn_particles(
                math.random() * MAP_W * TILE,
                math.random() * MAP_H * TILE,
                1, 0.3, 0.3, 0.6, 1.5, 15
            )
        end
    else
        -- Despawn enemies during day with death poof
        for _, e in ipairs(enemies) do
            spawn_particles(e.x, e.y, 6, 0.8, 0.2, 0.2, 0.4, 35)
        end
        enemies = {}
    end

    update_enemies(dt)
    update_particles(dt)

    -- Camera follow player
    local target_cx = (player.gx - 1) * TILE + TILE / 2 - SCREEN_W / 2
    local target_cy = (player.gy - 1) * TILE + TILE / 2 - SCREEN_H / 2
    camera_x = camera_x + (target_cx - camera_x) * math.min(1, dt * 6)
    camera_y = camera_y + (target_cy - camera_y) * math.min(1, dt * 6)
    lurek.camera.setPosition(camera_x, camera_y)
end)

-- ============================================================================
-- Render (world space)
-- ============================================================================
lurek.render(function()
    if state == STATE_TITLE or state == STATE_GAME_OVER then return end

    -- Draw map tiles
    for y = 1, MAP_H do
        for x = 1, MAP_W do
            local t = map[y][x]
            local c = TILE_COLORS[t] or TILE_COLORS[T_GRASS]
            local px = (x - 1) * TILE
            local py = (y - 1) * TILE
            lurek.render.drawRect(px, py, TILE, TILE, c[1], c[2], c[3], 1)
            -- Tile detail
            if t == T_TREE then
                lurek.render.drawCircle(px + TILE / 2, py + TILE / 3, 10, 0.10, 0.55, 0.08, 1)
                lurek.render.drawRect(px + 14, py + 14, 4, 14, 0.4, 0.25, 0.1, 1)
            elseif t == T_STONE then
                lurek.render.drawCircle(px + TILE / 2, py + TILE / 2, 8, 0.65, 0.65, 0.60, 1)
            elseif t == T_BERRY then
                lurek.render.drawCircle(px + 10, py + 20, 4, 0.85, 0.15, 0.4, 1)
                lurek.render.drawCircle(px + 22, py + 18, 4, 0.85, 0.15, 0.4, 1)
                lurek.render.drawCircle(px + 16, py + 24, 4, 0.85, 0.15, 0.4, 1)
            elseif t == T_WATER then
                lurek.render.drawCircle(px + 10, py + 16, 3, 0.4, 0.6, 0.9, 0.6)
                lurek.render.drawCircle(px + 22, py + 12, 3, 0.4, 0.6, 0.9, 0.6)
            elseif t == T_WALL then
                lurek.render.drawRect(px + 2, py + 2, TILE - 4, TILE - 4, 0.55, 0.40, 0.28, 1)
                lurek.render.drawRect(px + 4, py + TILE / 2 - 1, TILE - 8, 2, 0.35, 0.25, 0.15, 1)
            end
        end
    end

    -- Draw player
    local ppx = (player.gx - 1) * TILE
    local ppy = (player.gy - 1) * TILE
    lurek.render.drawRect(ppx + 4, ppy + 4, TILE - 8, TILE - 8, 0.2, 0.6, 0.9, 1)
    lurek.render.drawRect(ppx + 10, ppy + 8, 4, 4, 1, 1, 1, 1) -- eye left
    lurek.render.drawRect(ppx + 18, ppy + 8, 4, 4, 1, 1, 1, 1) -- eye right
    -- Facing indicator
    local dir = DIR[player.facing]
    if dir then
        lurek.render.drawRect(
            ppx + TILE / 2 - 2 + dir.dx * 10,
            ppy + TILE / 2 - 2 + dir.dy * 10,
            4, 4, 1, 0.8, 0.2, 1
        )
    end

    -- Mining progress bar
    if mining.active then
        local mx = (mining.target_x - 1) * TILE
        local my = (mining.target_y - 1) * TILE - 6
        local max_t = (inventory.pickaxe > 0) and MINE_TIME_PICK or MINE_TIME
        local frac = 1 - (mining.timer / max_t)
        lurek.render.drawRect(mx, my, TILE, 4, 0.2, 0.2, 0.2, 0.8)
        lurek.render.drawRect(mx, my, TILE * frac, 4, 0.9, 0.7, 0.1, 1)
    end

    -- Draw enemies
    for _, e in ipairs(enemies) do
        lurek.render.drawCircle(e.x, e.y, 10, 0.85, 0.15, 0.15, 1)
        lurek.render.drawCircle(e.x - 3, e.y - 3, 2, 1, 1, 0.2, 1)
        lurek.render.drawCircle(e.x + 3, e.y - 3, 2, 1, 1, 0.2, 1)
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        local alpha = p.life / p.max_life
        lurek.render.drawCircle(p.x, p.y, p.size * alpha, p.r, p.g, p.b, alpha)
    end

    -- Night overlay
    if night_alpha > 0.01 then
        lurek.render.drawRect(
            camera_x, camera_y, SCREEN_W, SCREEN_H,
            0.02, 0.02, 0.08, night_alpha
        )
    end
end)

-- ============================================================================
-- Render UI (screen space)
-- ============================================================================
lurek.render_ui(function()
    local fps = lurek.timer.getFPS()

    -- TITLE SCREEN
    if state == STATE_TITLE then
        lurek.render.drawRect(0, 0, SCREEN_W, SCREEN_H, 0.08, 0.12, 0.08, 1)
        lurek.render.drawText("SURVIVAL CRAFTING", SCREEN_W / 2 - 160, 180, 36, 0.4, 0.85, 0.3, 1)
        lurek.render.drawText("Gather. Craft. Survive the Night.", SCREEN_W / 2 - 140, 240, 16, 0.7, 0.7, 0.6, 1)
        lurek.render.drawText("WASD - Move    SPACE - Mine    C - Craft", SCREEN_W / 2 - 170, 310, 14, 0.6, 0.6, 0.5, 1)
        lurek.render.drawText("P - Place Wall    B - Eat Berry", SCREEN_W / 2 - 130, 335, 14, 0.6, 0.6, 0.5, 1)
        lurek.render.drawText("PRESS ENTER", SCREEN_W / 2 - 60, 420, 20, 1, 1, 0.6, 1)
        lurek.render.drawText("FPS: " .. fps, 10, SCREEN_H - 20, 12, 0.5, 0.5, 0.5, 1)
        return
    end

    -- GAME OVER
    if state == STATE_GAME_OVER then
        lurek.render.drawRect(0, 0, SCREEN_W, SCREEN_H, 0.12, 0.04, 0.04, 0.85)
        lurek.render.drawText("GAME OVER", SCREEN_W / 2 - 90, 200, 36, 0.9, 0.2, 0.2, 1)
        lurek.render.drawText(
            string.format("Survived %d days (%.0fs)", day_count, survival_time),
            SCREEN_W / 2 - 110, 260, 18, 0.8, 0.8, 0.7, 1
        )
        lurek.render.drawText("PRESS ENTER TO RETRY", SCREEN_W / 2 - 100, 340, 18, 1, 1, 0.6, 1)
        lurek.render.drawText("FPS: " .. fps, 10, SCREEN_H - 20, 12, 0.5, 0.5, 0.5, 1)
        return
    end

    -- HUD background
    lurek.render.drawRect(0, 0, SCREEN_W, 52, 0, 0, 0, 0.65)

    -- HP bar (tween-style smooth interpolation is handled in process)
    local hp_frac = player.hp / 100
    lurek.render.drawRect(10, 8, 150, 14, 0.25, 0.05, 0.05, 1)
    lurek.render.drawRect(10, 8, 150 * hp_frac, 14, 0.85, 0.15, 0.15, 1)
    lurek.render.drawText(string.format("HP: %d", math.ceil(player.hp)), 15, 8, 12, 1, 1, 1, 1)

    -- Hunger bar
    local hun_frac = player.hunger / 100
    lurek.render.drawRect(10, 28, 150, 14, 0.15, 0.12, 0.02, 1)
    lurek.render.drawRect(10, 28, 150 * hun_frac, 14, 0.85, 0.65, 0.15, 1)
    lurek.render.drawText(string.format("Hunger: %d", math.ceil(player.hunger)), 15, 28, 12, 1, 1, 1, 1)

    -- Inventory
    local inv_x = 180
    local inv_items = {
        {"Wood: " .. inventory.wood, 0.55, 0.35, 0.15},
        {"Stone: " .. inventory.stone, 0.6, 0.6, 0.55},
        {"Berry: " .. inventory.berry, 0.8, 0.2, 0.5},
        {"Pick: " .. inventory.pickaxe, 0.7, 0.7, 0.8},
        {"Wall: " .. inventory.wall, 0.45, 0.35, 0.25},
    }
    for i, item in ipairs(inv_items) do
        lurek.render.drawText(item[1], inv_x, 10, 13, item[2], item[3], item[4], 1)
        inv_x = inv_x + 80
    end

    -- Day counter and time
    local day_label = (day_time / DAY_LENGTH >= NIGHT_START) and "NIGHT" or "DAY"
    lurek.render.drawText(
        string.format("Day %d  %s  Time: %.0fs", day_count, day_label, survival_time),
        inv_x + 10, 10, 13, 0.9, 0.9, 0.7, 1
    )

    -- FPS
    lurek.render.drawText("FPS: " .. fps, SCREEN_W - 70, SCREEN_H - 20, 12, 0.5, 0.5, 0.5, 1)

    -- Controls hint
    lurek.render.drawText(
        "WASD:Move  SPACE:Mine  C:Craft  P:Place  B:Eat  ESC:Quit",
        10, SCREEN_H - 20, 11, 0.5, 0.5, 0.4, 1
    )

    -- Mining indicator
    if mining.active then
        lurek.render.drawText("MINING...", SCREEN_W / 2 - 30, 60, 16, 1, 0.8, 0.2, 1)
    end

    -- CRAFT MENU OVERLAY
    if state == STATE_CRAFT then
        lurek.render.drawRect(150, 100, 500, 350, 0.08, 0.08, 0.10, 0.92)
        lurek.render.drawRect(152, 102, 496, 346, 0.15, 0.15, 0.18, 0.95)

        lurek.render.drawText("CRAFTING MENU", 310, 115, 24, 0.4, 0.85, 0.3, 1)
        lurek.render.drawRect(170, 145, 460, 2, 0.3, 0.3, 0.3, 1)

        -- Recipe 1: Pickaxe
        local can_pick = inventory.wood >= 2 and inventory.stone >= 3
        local pick_r = can_pick and 1 or 0.4
        local pick_g = can_pick and 1 or 0.4
        lurek.render.drawText("[1] Pickaxe", 180, 165, 18, pick_r, pick_g, 0.6, 1)
        lurek.render.drawText("    Cost: 2 Wood + 3 Stone", 180, 190, 14, 0.6, 0.6, 0.5, 1)
        lurek.render.drawText("    Effect: Mines 2x faster", 180, 210, 14, 0.5, 0.7, 0.5, 1)
        lurek.render.drawText(string.format("    You have: %d Pickaxe(s)", inventory.pickaxe), 180, 230, 14, 0.7, 0.7, 0.8, 1)

        -- Recipe 2: Wall
        local can_wall = inventory.wood >= 4
        local wall_r = can_wall and 1 or 0.4
        local wall_g = can_wall and 1 or 0.4
        lurek.render.drawText("[2] Wall Block", 180, 270, 18, wall_r, wall_g, 0.6, 1)
        lurek.render.drawText("    Cost: 4 Wood", 180, 295, 14, 0.6, 0.6, 0.5, 1)
        lurek.render.drawText("    Effect: Placeable defense (P key)", 180, 315, 14, 0.5, 0.7, 0.5, 1)
        lurek.render.drawText(string.format("    You have: %d Wall(s)", inventory.wall), 180, 335, 14, 0.7, 0.7, 0.8, 1)

        -- Inventory summary
        lurek.render.drawRect(170, 370, 460, 2, 0.3, 0.3, 0.3, 1)
        lurek.render.drawText(
            string.format("Inventory: %d Wood  %d Stone  %d Berry", inventory.wood, inventory.stone, inventory.berry),
            180, 385, 14, 0.8, 0.8, 0.6, 1
        )
        lurek.render.drawText("Press C to close", 330, 420, 13, 0.5, 0.5, 0.4, 1)
    end
end)
