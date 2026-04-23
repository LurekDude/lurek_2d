--============================================================
-- Roguelike — Lurek2D
-- Category: rpg
-- Turn-based grid roguelike with permadeath
--============================================================

----------------------------------------
-- Constants
----------------------------------------

local TILE_SIZE   = 24
local MAP_W       = 30
local MAP_H       = 24
local VIEW_RADIUS = 5

local FLOOR  = 0
local WALL   = 1
local STAIRS = 2

local STATE_TITLE    = "TITLE"
local STATE_PLAYING  = "PLAYING"
local STATE_GAMEOVER = "GAME_OVER"

----------------------------------------
-- Game state
----------------------------------------
local state        = STATE_TITLE
local map          = {}
local visible      = {}
local explored     = {}
local player       = nil
local enemies      = {}
local pickups      = {}
local particles    = {}
local tweens_list  = {}
local messages     = {}
local floor_num    = 1
local turn_count   = 0
local total_kills  = 0
local input_locked = false

----------------------------------------
-- Helpers
----------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function distance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

local function add_message(msg)
    table.insert(messages, msg)
    if #messages > 5 then table.remove(messages, 1) end
end

local function make_player()
    return {
        x = 1, y = 1,
        hp = 50, max_hp = 50,
        atk = 8, def = 3,
        level = 1, kills = 0,
        display_hp = 50,
    }
end

local function enemy_template(kind, x, y)
    if kind == "rat" then
        return { x = x, y = y, kind = "Rat", hp = 5, max_hp = 5, atk = 3, def = 0, glyph = "r", color = {0.6, 0.5, 0.3} }
    elseif kind == "goblin" then
        return { x = x, y = y, kind = "Goblin", hp = 10, max_hp = 10, atk = 5, def = 2, glyph = "g", color = {0.2, 0.8, 0.2} }
    else
        return { x = x, y = y, kind = "Orc", hp = 20, max_hp = 20, atk = 8, def = 4, glyph = "O", color = {0.8, 0.3, 0.2} }
    end
end

----------------------------------------
-- Dungeon generation
----------------------------------------
local function init_map()
    map = {}
    visible = {}
    explored = {}
    for y = 0, MAP_H - 1 do
        map[y] = {}
        visible[y] = {}
        explored[y] = {}
        for x = 0, MAP_W - 1 do
            map[y][x] = WALL
            visible[y][x] = false
            explored[y][x] = false
        end
    end
end

local function carve_room(rx, ry, rw, rh)
    for y = ry, ry + rh - 1 do
        for x = rx, rx + rw - 1 do
            if y >= 0 and y < MAP_H and x >= 0 and x < MAP_W then
                map[y][x] = FLOOR
            end
        end
    end
end

local function carve_h_corridor(x1, x2, y)
    local lo = math.min(x1, x2)
    local hi = math.max(x1, x2)
    for x = lo, hi do
        if y >= 0 and y < MAP_H and x >= 0 and x < MAP_W then
            map[y][x] = FLOOR
        end
    end
end

local function carve_v_corridor(y1, y2, x)
    local lo = math.min(y1, y2)
    local hi = math.max(y1, y2)
    for y = lo, hi do
        if y >= 0 and y < MAP_H and x >= 0 and x < MAP_W then
            map[y][x] = FLOOR
        end
    end
end

local function generate_dungeon()
    init_map()

    local rooms = {}
    local attempts = 0
    local max_rooms = math.random(6, 10)

    while #rooms < max_rooms and attempts < 200 do
        attempts = attempts + 1
        local rw = math.random(4, 8)
        local rh = math.random(3, 6)
        local rx = math.random(1, MAP_W - rw - 1)
        local ry = math.random(1, MAP_H - rh - 1)

        local overlap = false
        for _, r in ipairs(rooms) do
            if rx <= r.x + r.w + 1 and rx + rw >= r.x - 1 and
               ry <= r.y + r.h + 1 and ry + rh >= r.y - 1 then
                overlap = true
                break
            end
        end

        if not overlap then
            carve_room(rx, ry, rw, rh)
            table.insert(rooms, { x = rx, y = ry, w = rw, h = rh,
                cx = math.floor(rx + rw / 2), cy = math.floor(ry + rh / 2) })
        end
    end

    -- Connect rooms with corridors
    for i = 2, #rooms do
        local prev = rooms[i - 1]
        local curr = rooms[i]
        if math.random() < 0.5 then
            carve_h_corridor(prev.cx, curr.cx, prev.cy)
            carve_v_corridor(prev.cy, curr.cy, curr.cx)
        else
            carve_v_corridor(prev.cy, curr.cy, prev.cx)
            carve_h_corridor(prev.cx, curr.cx, curr.cy)
        end
    end

    -- Place player in first room
    player.x = rooms[1].cx
    player.y = rooms[1].cy

    -- Place stairs in last room
    local last = rooms[#rooms]
    map[last.cy][last.cx] = STAIRS

    -- Spawn enemies
    enemies = {}
    for i = 2, #rooms - 1 do
        local r = rooms[i]
        local count = math.random(1, 2 + math.floor(floor_num / 2))
        for _ = 1, count do
            local ex = math.random(r.x + 1, r.x + r.w - 2)
            local ey = math.random(r.y + 1, r.y + r.h - 2)
            if not (ex == player.x and ey == player.y) then
                local roll = math.random(1, 10)
                local kind
                if floor_num <= 2 then
                    kind = roll <= 7 and "rat" or "goblin"
                elseif floor_num <= 4 then
                    kind = roll <= 3 and "rat" or (roll <= 7 and "goblin" or "orc")
                else
                    kind = roll <= 2 and "rat" or (roll <= 5 and "goblin" or "orc")
                end
                table.insert(enemies, enemy_template(kind, ex, ey))
            end
        end
    end

    -- Spawn pickups
    pickups = {}
    for i = 2, #rooms do
        if math.random() < 0.4 then
            local r = rooms[i]
            local px = math.random(r.x + 1, r.x + r.w - 2)
            local py = math.random(r.y + 1, r.y + r.h - 2)
            local kind = math.random() < 0.7 and "potion" or "weapon"
            table.insert(pickups, { x = px, y = py, kind = kind })
        end
    end
end

----------------------------------------
-- Fog of war
----------------------------------------
local function update_visibility()
    for y = 0, MAP_H - 1 do
        for x = 0, MAP_W - 1 do
            visible[y][x] = false
        end
    end
    for y = 0, MAP_H - 1 do
        for x = 0, MAP_W - 1 do
            if distance(player.x, player.y, x, y) <= VIEW_RADIUS then
                visible[y][x] = true
                explored[y][x] = true
            end
        end
    end
end

----------------------------------------
-- Combat & interaction
----------------------------------------
local function enemy_at(x, y)
    for i, e in ipairs(enemies) do
        if e.x == x and e.y == y then return i, e end
    end
    return nil, nil
end

local function pickup_at(x, y)
    for i, p in ipairs(pickups) do
        if p.x == x and p.y == y then return i, p end
    end
    return nil, nil
end

local function spawn_particle(x, y, r, g, b, count)
    for _ = 1, (count or 6) do
        table.insert(particles, {
            x = (x + 0.5) * TILE_SIZE,
            y = (y + 0.5) * TILE_SIZE,
            vx = (math.random() - 0.5) * 80,
            vy = (math.random() - 0.5) * 80,
            life = 0.5 + math.random() * 0.3,
            max_life = 0.8,
            r = r, g = g, b = b,
        })
    end
end

local function spawn_damage_popup(x, y, text, r, g, b)
    table.insert(tweens_list, {
        x = (x + 0.5) * TILE_SIZE,
        y = y * TILE_SIZE - 4,
        start_y = y * TILE_SIZE - 4,
        text = text,
        life = 0.8,
        max_life = 0.8,
        r = r or 1, g = g or 0.2, b = b or 0.2,
    })
end

local function attack_enemy(idx, enemy)
    local dmg = math.max(1, player.atk - enemy.def)
    enemy.hp = enemy.hp - dmg
    add_message("You hit " .. enemy.kind .. " for " .. dmg .. " dmg!")
    spawn_damage_popup(enemy.x, enemy.y, "-" .. dmg, 1, 0.3, 0.2)

    if enemy.hp <= 0 then
        add_message(enemy.kind .. " defeated!")
        spawn_particle(enemy.x, enemy.y, 0.8, 0.2, 0.1, 8)
        table.remove(enemies, idx)
        total_kills = total_kills + 1
        player.kills = player.kills + 1

        if player.kills % 5 == 0 then
            player.level = player.level + 1
            player.max_hp = player.max_hp + 2
            player.hp = math.min(player.hp + 2, player.max_hp)
            player.atk = player.atk + 1
            add_message("Level up! Lv" .. player.level .. " ATK+" .. 1 .. " HP+" .. 2)
        end
    end
end

local function enemies_act()
    for _, e in ipairs(enemies) do
        if distance(e.x, e.y, player.x, player.y) <= VIEW_RADIUS then
            local dx = 0
            local dy = 0
            if player.x < e.x then dx = -1
            elseif player.x > e.x then dx = 1 end
            if player.y < e.y then dy = -1
            elseif player.y > e.y then dy = 1 end

            -- Prefer axis with larger distance
            if math.abs(player.x - e.x) >= math.abs(player.y - e.y) then
                dy = 0
            else
                dx = 0
            end

            local nx, ny = e.x + dx, e.y + dy
            if nx == player.x and ny == player.y then
                -- Attack player
                local dmg = math.max(1, e.atk - player.def)
                player.hp = player.hp - dmg
                add_message(e.kind .. " hits you for " .. dmg .. " dmg!")
                spawn_damage_popup(player.x, player.y, "-" .. dmg, 1, 0.6, 0.1)
            elseif ny >= 0 and ny < MAP_H and nx >= 0 and nx < MAP_W and
                   map[ny][nx] ~= WALL and not enemy_at(nx, ny) then
                e.x = nx
                e.y = ny
            end
        end
    end
end

local function try_move(dx, dy)
    if state ~= STATE_PLAYING or input_locked then return end

    local nx = player.x + dx
    local ny = player.y + dy
    if nx < 0 or nx >= MAP_W or ny < 0 or ny >= MAP_H then return end
    if map[ny][nx] == WALL then return end

    -- Check enemy
    local idx, enemy = enemy_at(nx, ny)
    if enemy then
        attack_enemy(idx, enemy)
    else
        player.x = nx
        player.y = ny

        -- Check pickup
        local pi, pickup = pickup_at(nx, ny)
        if pickup then
            if pickup.kind == "potion" then
                local heal = math.min(15, player.max_hp - player.hp)
                player.hp = player.hp + heal
                add_message("Picked up potion! +" .. heal .. " HP")
                spawn_particle(nx, ny, 0.2, 0.9, 0.3, 6)
            else
                player.atk = player.atk + 2
                add_message("Weapon upgrade! ATK +" .. 2)
                spawn_particle(nx, ny, 0.9, 0.8, 0.2, 6)
            end
            table.remove(pickups, pi)
        end

        -- Check stairs
        if map[ny][nx] == STAIRS then
            floor_num = floor_num + 1
            add_message("Descending to floor " .. floor_num .. "...")
            generate_dungeon()
        end
    end

    turn_count = turn_count + 1
    enemies_act()
    update_visibility()

    -- Check death
    if player.hp <= 0 then
        player.hp = 0
        state = STATE_GAMEOVER
        add_message("You died!")
    end
end

----------------------------------------
-- Update particles & tweens
----------------------------------------
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

local function update_tweens(dt)
    local i = 1
    while i <= #tweens_list do
        local t = tweens_list[i]
        t.life = t.life - dt
        t.y = t.start_y - (1 - t.life / t.max_life) * 20
        if t.life <= 0 then
            table.remove(tweens_list, i)
        else
            i = i + 1
        end
    end

    -- Tween player HP bar
    if player then
        local diff = player.hp - player.display_hp
        if math.abs(diff) > 0.1 then
            player.display_hp = player.display_hp + diff * dt * 6
        else
            player.display_hp = player.hp
        end
    end
end

-- Stair shimmer particles
local function update_stair_particles(dt)
    if state ~= STATE_PLAYING then return end
    for y = 0, MAP_H - 1 do
        for x = 0, MAP_W - 1 do
            if map[y][x] == STAIRS and visible[y][x] and math.random() < dt * 2 then
                spawn_particle(x, y, 0.3, 0.6, 1.0, 1)
            end
        end
    end
end

-- Pickup glow particles
local function update_pickup_particles(dt)
    if state ~= STATE_PLAYING then return end
    for _, p in ipairs(pickups) do
        if visible[p.y] and visible[p.y][p.x] and math.random() < dt * 1.5 then
            if p.kind == "potion" then
                spawn_particle(p.x, p.y, 0.2, 0.9, 0.3, 1)
            else
                spawn_particle(p.x, p.y, 0.9, 0.8, 0.2, 1)
            end
        end
    end
end

----------------------------------------
-- Engine callbacks
----------------------------------------
lurek.render.setBackgroundColor(0.05, 0.05, 0.08)

lurek.input.bind("move_up",    {"up", "w"})
lurek.input.bind("move_down",  {"down", "s"})
lurek.input.bind("move_left",  {"left", "a"})
lurek.input.bind("move_right", {"right", "d"})
lurek.input.bind("confirm",    {"return"})
lurek.input.bind("quit",       {"escape"})

function lurek.init()
    lurek.window.setTitle("Roguelike — Lurek2D")
    math.randomseed(os.time())
    player = make_player()
end

local function _ready_setup()
    -- Ready
end

function lurek.process(dt)
    -- Input handling
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    if state == STATE_TITLE then
        if lurek.input.wasActionPressed("confirm") then
            state = STATE_PLAYING
            player = make_player()
            floor_num = 1
            turn_count = 0
            total_kills = 0
            messages = {}
            generate_dungeon()
            update_visibility()
            add_message("Welcome to the dungeon! Floor 1")
        end
    elseif state == STATE_PLAYING then
        if lurek.input.wasActionPressed("move_up") then try_move(0, -1) end
        if lurek.input.wasActionPressed("move_down") then try_move(0, 1) end
        if lurek.input.wasActionPressed("move_left") then try_move(-1, 0) end
        if lurek.input.wasActionPressed("move_right") then try_move(1, 0) end
    elseif state == STATE_GAMEOVER then
        if lurek.input.wasActionPressed("confirm") then
            state = STATE_TITLE
        end
    end

    -- Update effects
    update_particles(dt)
    update_tweens(dt)
    update_stair_particles(dt)
    update_pickup_particles(dt)
end

----------------------------------------
-- Rendering: dungeon, player, enemies
----------------------------------------
function lurek.draw()
    if state == STATE_TITLE then return end
    if state == STATE_GAMEOVER then return end

    -- Camera offset to center player
    local cam_x = player.x * TILE_SIZE - 400 + TILE_SIZE / 2
    local cam_y = player.y * TILE_SIZE - 300 + TILE_SIZE / 2
    lurek.camera.setPosition(-cam_x, -cam_y)

    -- Draw map
    for y = 0, MAP_H - 1 do
        for x = 0, MAP_W - 1 do
            local px = x * TILE_SIZE
            local py = y * TILE_SIZE

            if visible[y][x] then
                if map[y][x] == WALL then
                    lurek.render.setColor(0.25, 0.22, 0.30, 1)
                    lurek.render.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
                elseif map[y][x] == FLOOR then
                    lurek.render.setColor(0.12, 0.11, 0.15, 1)
                    lurek.render.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
                    -- Grid lines
                    lurek.render.setColor(0.16, 0.15, 0.19, 1)
                    lurek.render.rectangle("line", px, py, TILE_SIZE, TILE_SIZE)
                elseif map[y][x] == STAIRS then
                    lurek.render.setColor(0.15, 0.3, 0.6, 1)
                    lurek.render.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
                    lurek.render.setColor(0.4, 0.7, 1, 1)
                    lurek.render.print(">", px + 6, py + 3)
                end
            elseif explored[y][x] then
                if map[y][x] == WALL then
                    lurek.render.setColor(0.12, 0.11, 0.14, 1)
                    lurek.render.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
                else
                    lurek.render.setColor(0.07, 0.06, 0.09, 1)
                    lurek.render.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
                end
            end
        end
    end

    -- Draw pickups
    for _, p in ipairs(pickups) do
        if visible[p.y] and visible[p.y][p.x] then
            local px = p.x * TILE_SIZE
            local py = p.y * TILE_SIZE
            if p.kind == "potion" then
                lurek.render.setColor(0.2, 0.9, 0.3, 1)
                lurek.render.print("!", px + 8, py + 3)
            else
                lurek.render.setColor(0.9, 0.8, 0.2, 1)
                lurek.render.print("+", px + 6, py + 3)
            end
        end
    end

    -- Draw enemies
    for _, e in ipairs(enemies) do
        if visible[e.y] and visible[e.y][e.x] then
            local px = e.x * TILE_SIZE
            local py = e.y * TILE_SIZE
            lurek.render.setColor(e.color[1], e.color[2], e.color[3], 1)
            lurek.render.print(e.glyph, px + 7, py + 3)

            -- HP bar above enemy
            local bar_w = TILE_SIZE - 4
            local hp_ratio = e.hp / e.max_hp
            lurek.render.setColor(0.3, 0.0, 0.0, 0.8)
            lurek.render.rectangle("fill", px + 2, py - 4, bar_w, 3)
            lurek.render.setColor(0.9, 0.1, 0.1, 0.9)
            lurek.render.rectangle("fill", px + 2, py - 4, bar_w * hp_ratio, 3)
        end
    end

    -- Draw player
    local ppx = player.x * TILE_SIZE
    local ppy = player.y * TILE_SIZE
    lurek.render.setColor(1, 1, 0.3, 1)
    lurek.render.print("@", ppx + 6, ppy + 3)

    -- Draw particles (world-space)
    for _, p in ipairs(particles) do
        local alpha = clamp(p.life / p.max_life, 0, 1)
        local size = 2 + alpha * 2
        lurek.render.setColor(p.r, p.g, p.b, alpha)
        lurek.render.rectangle("fill", p.x - size / 2, p.y - size / 2, size, size)
    end

    -- Draw damage popups (world-space)
    for _, t in ipairs(tweens_list) do
        local alpha = clamp(t.life / t.max_life, 0, 1)
        lurek.render.setColor(t.r, t.g, t.b, alpha)
        lurek.render.print(t.text, t.x - 8, t.y)
    end
end

----------------------------------------
-- UI rendering: stats, messages, minimap
----------------------------------------
function lurek.draw_ui()
    if state == STATE_TITLE then
        lurek.render.setColor(0.8, 0.6, 1, 1)
        lurek.render.print("ROGUELIKE", 290, 200, 0, 2.5, 2.5)
        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        lurek.render.print("A turn-based dungeon crawler", 270, 270)
        lurek.render.setColor(1, 1, 1, math.abs(math.sin(lurek.timer.getTime() * 2)))
        lurek.render.print("PRESS ENTER", 330, 340)
        lurek.render.setColor(0.4, 0.4, 0.4, 1)
        lurek.render.print("Arrow keys / WASD to move  |  ESC to quit", 200, 500)
        return
    end

    if state == STATE_GAMEOVER then
        lurek.render.setColor(0.9, 0.1, 0.1, 1)
        lurek.render.print("GAME OVER", 300, 180, 0, 2.5, 2.5)
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        lurek.render.print("Floors explored: " .. floor_num, 310, 280)
        lurek.render.print("Enemies slain:   " .. total_kills, 310, 310)
        lurek.render.print("Turns survived:  " .. turn_count, 310, 340)
        lurek.render.print("Player level:    " .. player.level, 310, 370)
        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        lurek.render.print("Press ENTER to return to title", 260, 450)
        return
    end

    -- HUD background bar
    lurek.render.setColor(0.0, 0.0, 0.0, 0.7)
    lurek.render.rectangle("fill", 0, 0, 800, 28)

    -- HP bar with tween
    local hp_pct = clamp(player.display_hp / player.max_hp, 0, 1)
    local bar_x, bar_y, bar_w, bar_h = 70, 6, 140, 14
    lurek.render.setColor(0.2, 0.0, 0.0, 1)
    lurek.render.rectangle("fill", bar_x, bar_y, bar_w, bar_h)
    -- Tween trail (slightly different color)
    local tween_pct = clamp(player.display_hp / player.max_hp, 0, 1)
    if tween_pct > hp_pct then
        lurek.render.setColor(0.7, 0.2, 0.1, 0.7)
        lurek.render.rectangle("fill", bar_x, bar_y, bar_w * tween_pct, bar_h)
    end
    -- Actual HP
    local real_pct = clamp(player.hp / player.max_hp, 0, 1)
    local r_hp = real_pct > 0.5 and 0.2 or (real_pct > 0.25 and 0.9 or 0.9)
    local g_hp = real_pct > 0.5 and 0.8 or (real_pct > 0.25 and 0.6 or 0.1)
    lurek.render.setColor(r_hp, g_hp, 0.1, 1)
    lurek.render.rectangle("fill", bar_x, bar_y, bar_w * real_pct, bar_h)
    -- HP text
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("HP", 46, 7)
    lurek.render.print(math.floor(player.hp) .. "/" .. player.max_hp, bar_x + 4, bar_y + 1)

    -- Stats
    lurek.render.setColor(0.9, 0.9, 0.9, 1)
    lurek.render.print("ATK:" .. player.atk, 230, 7)
    lurek.render.print("DEF:" .. player.def, 300, 7)
    lurek.render.print("Lv:" .. player.level, 370, 7)
    lurek.render.print("Floor:" .. floor_num, 440, 7)
    lurek.render.print("Turn:" .. turn_count, 540, 7)
    lurek.render.print("Kills:" .. total_kills, 640, 7)

    -- FPS
    lurek.render.setColor(0.4, 0.4, 0.4, 1)
    lurek.render.print("FPS:" .. lurek.timer.getFPS(), 740, 7)

    -- Message log at bottom
    lurek.render.setColor(0.0, 0.0, 0.0, 0.6)
    lurek.render.rectangle("fill", 0, 510, 640, 90)
    for i, msg in ipairs(messages) do
        local alpha = 0.4 + 0.6 * (i / #messages)
        lurek.render.setColor(0.9, 0.85, 0.7, alpha)
        lurek.render.print(msg, 10, 510 + (i - 1) * 16)
    end

    -- Minimap (top-right)
    local mm_x = 650
    local mm_y = 40
    local mm_s = 4
    lurek.render.setColor(0.0, 0.0, 0.0, 0.5)
    lurek.render.rectangle("fill", mm_x - 2, mm_y - 2, MAP_W * mm_s + 4, MAP_H * mm_s + 4)
    for y = 0, MAP_H - 1 do
        for x = 0, MAP_W - 1 do
            if explored[y][x] then
                local mx = mm_x + x * mm_s
                local my = mm_y + y * mm_s
                if visible[y][x] then
                    if map[y][x] == WALL then
                        lurek.render.setColor(0.3, 0.28, 0.35, 0.8)
                    elseif map[y][x] == STAIRS then
                        lurek.render.setColor(0.3, 0.5, 1, 0.9)
                    else
                        lurek.render.setColor(0.2, 0.18, 0.25, 0.7)
                    end
                else
                    lurek.render.setColor(0.1, 0.1, 0.12, 0.5)
                end
                lurek.render.rectangle("fill", mx, my, mm_s, mm_s)
            end
        end
    end
    -- Player on minimap
    lurek.render.setColor(1, 1, 0.3, 1)
    lurek.render.rectangle("fill", mm_x + player.x * mm_s, mm_y + player.y * mm_s, mm_s, mm_s)
    -- Enemies on minimap (visible only)
    for _, e in ipairs(enemies) do
        if visible[e.y] and visible[e.y][e.x] then
            lurek.render.setColor(0.9, 0.2, 0.2, 0.8)
            lurek.render.rectangle("fill", mm_x + e.x * mm_s, mm_y + e.y * mm_s, mm_s, mm_s)
        end
    end
end
