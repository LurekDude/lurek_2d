-- Mining — Lurek2D
-- Category: simulation
-- A mining depth exploration game: dig deep, find riches, upgrade equipment

local TILE = 32
local COLS = 20
local ROWS = 30
local MINE_W = COLS * TILE
local MINE_H = ROWS * TILE
local W, H = 800, 600

-- Tile types
local T_EMPTY   = 0
local T_DIRT    = 1
local T_STONE   = 2
local T_ORE     = 3  -- iron ore
local T_GOLD    = 4  -- gold ore
local T_GEM     = 5
local T_BEDROCK = 6
local T_LADDER  = 7

local TILE_COLORS = {
local _cam = lurek.camera.new()  -- injected by fix_games.py
    [T_EMPTY]   = {0.12, 0.08, 0.06},
    [T_DIRT]    = {0.55, 0.35, 0.15},
    [T_STONE]   = {0.50, 0.50, 0.52},
    [T_ORE]     = {0.60, 0.45, 0.25},
    [T_GOLD]    = {0.85, 0.75, 0.20},
    [T_GEM]     = {0.20, 0.85, 0.90},
    [T_BEDROCK] = {0.10, 0.10, 0.10},
    [T_LADDER]  = {0.70, 0.50, 0.20},
}

local DIG_TIME   = { [T_DIRT]=0.5, [T_STONE]=1.0, [T_ORE]=1.5, [T_GOLD]=1.5, [T_GEM]=2.0 }
local TILE_VALUE = { [T_DIRT]=1,   [T_STONE]=2,   [T_ORE]=5,   [T_GOLD]=15,  [T_GEM]=50 }

-- Game state
local state = "TITLE"
local mine = {}
local player = { cx=10, cy=0, hp=100, gold=0, items=0 }
local upgrades = { pickaxe=false, headlamp=false, cart=false }
local dig = { active=false, timer=0, duration=0, tx=0, ty=0 }
local cam_y = 0
local particles = {}
local tweens = {}
local cavein_timer = 0
local gold_display = 0
local shop_sel = 1
local fps = 0

local function max_carry() return upgrades.cart and 15 or 10 end
local function light_radius() return upgrades.headlamp and 8 or 4 end
local function dig_speed() return upgrades.pickaxe and 0.5 or 1.0 end

-- ── Map generation ──────────────────────────────────────────────
local function generate_mine()
    mine = {}
    for y = 0, ROWS - 1 do
        mine[y] = {}
        for x = 0, COLS - 1 do
            if y == 0 then
                mine[y][x] = T_EMPTY  -- surface row
            elseif y >= ROWS - 1 then
                mine[y][x] = T_BEDROCK
            else
                local r = math.random(100)
                if y > 20 and r <= 3 then
                    mine[y][x] = T_GEM
                elseif y > 12 and r <= 8 then
                    mine[y][x] = T_GOLD
                elseif y > 5 and r <= 18 then
                    mine[y][x] = T_ORE
                elseif r <= 45 then
                    mine[y][x] = T_STONE
                else
                    mine[y][x] = T_DIRT
                end
            end
        end
    end
end

-- ── Particles ───────────────────────────────────────────────────
local function spawn_particles(wx, wy, color, count, spread)
    for i = 1, (count or 5) do
        local s = spread or 16
        particles[#particles + 1] = {
            x = wx + math.random(-s, s),
            y = wy + math.random(-s, s),
            vx = math.random(-40, 40),
            vy = math.random(-60, -10),
            life = 0.4 + math.random() * 0.4,
            r = color[1], g = color[2], b = color[3],
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
        p.vy = p.vy + 120 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            particles[i] = particles[#particles]
            particles[#particles] = nil
        else
            i = i + 1
        end
    end
end

-- ── Tweens ──────────────────────────────────────────────────────
local function add_tween(target, field, to, duration, delay)
    tweens[#tweens + 1] = {
        target = target, field = field,
        from = target[field], to = to,
        elapsed = -(delay or 0), duration = duration or 0.3,
    }
end

local function update_tweens(dt)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        if tw.elapsed >= 0 then
            local t = math.min(tw.elapsed / tw.duration, 1.0)
            t = t * t * (3 - 2 * t)  -- smoothstep
            tw.target[tw.field] = tw.from + (tw.to - tw.from) * t
        end
        if tw.elapsed >= tw.duration then
            tw.target[tw.field] = tw.to
            tweens[i] = tweens[#tweens]
            tweens[#tweens] = nil
        else
            i = i + 1
        end
    end
end

-- ── Tile queries ────────────────────────────────────────────────
local function tile_at(cx, cy)
    if cy < 0 or cy >= ROWS or cx < 0 or cx >= COLS then return T_BEDROCK end
    return mine[cy][cx]
end

local function is_solid(cx, cy)
    local t = tile_at(cx, cy)
    return t ~= T_EMPTY and t ~= T_LADDER
end

local function can_stand(cx, cy)
    return cy >= ROWS - 1 or is_solid(cx, cy + 1) or tile_at(cx, cy) == T_LADDER
end

-- ── Player actions ──────────────────────────────────────────────
local function try_move(dx, dy)
    if dig.active then return end
    local nx, ny = player.cx + dx, player.cy + dy
    if nx < 0 or nx >= COLS or ny < 0 or ny >= ROWS then return end
    if is_solid(nx, ny) then return end
    -- Cannot move up unless on ladder
    if dy < 0 and tile_at(player.cx, player.cy) ~= T_LADDER then return end
    player.cx = nx
    player.cy = ny
end

local function start_dig(tx, ty)
    if dig.active then return end
    local t = tile_at(tx, ty)
    if t == T_BEDROCK or t == T_EMPTY or t == T_LADDER then return end
    if not DIG_TIME[t] then return end
    -- Can only dig down or sideways (not up without special)
    local dx = tx - player.cx
    local dy = ty - player.cy
    if math.abs(dx) + math.abs(dy) ~= 1 then return end
    if dy < 0 then return end  -- cannot dig up
    dig.active = true
    dig.timer = 0
    dig.duration = DIG_TIME[t] * dig_speed()
    dig.tx = tx
    dig.ty = ty
end

local function finish_dig()
    local t = mine[dig.ty][dig.tx]
    local val = TILE_VALUE[t] or 0
    if player.items < max_carry() then
        player.items = player.items + 1
        player.gold = player.gold + val
        add_tween({v=gold_display}, "v", player.gold, 0.4)
    end
    local color = TILE_COLORS[t] or {0.5, 0.5, 0.5}
    spawn_particles(dig.tx * TILE + TILE / 2, dig.ty * TILE + TILE / 2, color, 8)
    mine[dig.ty][dig.tx] = T_EMPTY
    dig.active = false
end

local function place_ladder()
    if player.gold < 5 then return end
    if tile_at(player.cx, player.cy) == T_LADDER then return end
    if tile_at(player.cx, player.cy) ~= T_EMPTY then return end
    player.gold = player.gold - 5
    mine[player.cy][player.cx] = T_LADDER
    spawn_particles(player.cx * TILE + TILE / 2, player.cy * TILE + TILE / 2, {0.7, 0.5, 0.2}, 4)
end

local function return_to_surface()
    player.cx = 10
    player.cy = 0
    player.items = 0
    player.hp = 100
    dig.active = false
end

-- ── Cave-ins ────────────────────────────────────────────────────
local function check_cavein(dt)
    if player.cy < 15 then return end
    cavein_timer = cavein_timer + dt
    if cavein_timer > 3.0 + math.random() * 4.0 then
        cavein_timer = 0
        -- rocks fall from 2 tiles above
        local fy = player.cy - 2
        if fy >= 0 and tile_at(player.cx, fy) ~= T_EMPTY then
            player.hp = player.hp - 25
            spawn_particles(player.cx * TILE + TILE / 2, player.cy * TILE, {0.5, 0.4, 0.3}, 15, 24)
            if player.hp <= 0 then
                state = "GAME_OVER"
            end
        end
    end
end

-- ── Shop ────────────────────────────────────────────────────────
local shop_items = {
    { name = "Better Pickaxe", cost = 50,  key = "pickaxe",  desc = "Mine 50% faster" },
    { name = "Headlamp",       cost = 30,  key = "headlamp", desc = "Light radius 4→8" },
    { name = "Cart",           cost = 100, key = "cart",     desc = "Carry 15 items" },
}

local function buy_item()
    local item = shop_items[shop_sel]
    if not item then return end
    if upgrades[item.key] then return end
    if player.gold < item.cost then return end
    player.gold = player.gold - item.cost
    upgrades[item.key] = true
end

-- ── Input bindings ──────────────────────────────────────────────
lurek.input.bind("move_up",    "w")
lurek.input.bind("move_down",  "s")
lurek.input.bind("move_left",  "a")
lurek.input.bind("move_right", "d")
lurek.input.bind("dig",        "space")
lurek.input.bind("shop",       "s")
lurek.input.bind("ladder",     "l")
lurek.input.bind("quit",       "escape")
lurek.input.bind("confirm",    "return")
lurek.input.bind("nav_up",     "up")
lurek.input.bind("nav_down",   "down")

-- ── Init ────────────────────────────────────────────────────────

function lurek.init()
    lurek.window.setTitle("Mining — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.03, 0.02)
    math.randomseed(os.time())
    generate_mine()
end

local function _ready_setup()
    state = "TITLE"
end

-- ── Process ─────────────────────────────────────────────────────
function lurek.process(dt)
    fps = lurek.timer.getFPS()

    if state == "TITLE" then
        if lurek.input.wasActionPressed("confirm") then
            state = "MINING"
            generate_mine()
            player = { cx=10, cy=0, hp=100, gold=0, items=0 }
            upgrades = { pickaxe=false, headlamp=false, cart=false }
            dig = { active=false, timer=0, duration=0, tx=0, ty=0 }
            particles = {}
            tweens = {}
            gold_display = 0
            cavein_timer = 0
        end
        if lurek.input.wasActionPressed("quit") then lurek.event.quit() end
        return
    end

    if state == "GAME_OVER" or state == "VICTORY" then
        if lurek.input.wasActionPressed("confirm") then state = "TITLE" end
        if lurek.input.wasActionPressed("quit") then lurek.event.quit() end
        return
    end

    if state == "SHOP" then
        if lurek.input.wasActionPressed("nav_up") then
            shop_sel = shop_sel - 1
            if shop_sel < 1 then shop_sel = #shop_items end
        end
        if lurek.input.wasActionPressed("nav_down") then
            shop_sel = shop_sel + 1
            if shop_sel > #shop_items then shop_sel = 1 end
        end
        if lurek.input.wasActionPressed("confirm") then buy_item() end
        if lurek.input.wasActionPressed("quit") then state = "MINING" end
        return
    end

    -- MINING state
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Movement
    if lurek.input.wasActionPressed("move_up")    then try_move(0, -1) end
    if lurek.input.wasActionPressed("move_down")  then try_move(0,  1) end
    if lurek.input.wasActionPressed("move_left")  then try_move(-1, 0) end
    if lurek.input.wasActionPressed("move_right") then try_move(1,  0) end

    -- Dig: mine the tile the player is facing (below first, then sides)
    if lurek.input.wasActionPressed("dig") and not dig.active then
        -- Try dig down first, then left, then right
        if is_solid(player.cx, player.cy + 1) then
            start_dig(player.cx, player.cy + 1)
        elseif is_solid(player.cx - 1, player.cy) then
            start_dig(player.cx - 1, player.cy)
        elseif is_solid(player.cx + 1, player.cy) then
            start_dig(player.cx + 1, player.cy)
        end
    end

    -- Dig progress
    if dig.active then
        dig.timer = dig.timer + dt
        -- Dig debris particles
        if math.random() < 0.3 then
            local tc = TILE_COLORS[tile_at(dig.tx, dig.ty)] or {0.5, 0.5, 0.5}
            spawn_particles(dig.tx * TILE + TILE / 2, dig.ty * TILE + TILE / 2, tc, 1)
        end
        if dig.timer >= dig.duration then
            finish_dig()
        end
    end

    -- Ladder
    if lurek.input.wasActionPressed("ladder") then place_ladder() end

    -- Shop access (at surface)
    if player.cy == 0 and lurek.input.wasActionPressed("shop") then
        return_to_surface()
        state = "SHOP"
        return
    end

    -- Gravity: fall if nothing below and not on ladder
    if not can_stand(player.cx, player.cy) then
        player.cy = player.cy + 1
    end

    -- Cave-ins
    check_cavein(dt)

    -- Camera follow
    local target_y = player.cy * TILE - H / 2 + TILE / 2
    target_y = math.max(0, math.min(target_y, MINE_H - H))
    cam_y = cam_y + (target_y - cam_y) * math.min(dt * 6, 1)

    -- Ore sparkle particles
    local lr = light_radius()
    for dy = -lr, lr do
        for dx = -lr, lr do
            local tx, ty = player.cx + dx, player.cy + dy
            if tx >= 0 and tx < COLS and ty >= 0 and ty < ROWS then
                local t = tile_at(tx, ty)
                if (t == T_GOLD or t == T_GEM) and math.random() < 0.02 then
                    local c = TILE_COLORS[t]
                    spawn_particles(tx * TILE + TILE / 2, ty * TILE + TILE / 2, c, 1, 8)
                end
            end
        end
    end

    -- Victory check
    if player.gold >= 500 then
        state = "VICTORY"
    end

    update_particles(dt)
    update_tweens(dt)
end

-- ── Render (world) ──────────────────────────────────────────────
function lurek.draw()
    if state ~= "MINING" then return end

    _cam:setPosition(0, -cam_y)
    local lr = light_radius()

    -- Draw mine tiles
    local start_row = math.max(0, math.floor(cam_y / TILE) - 1)
    local end_row = math.min(ROWS - 1, math.floor((cam_y + H) / TILE) + 1)
    for y = start_row, end_row do
        for x = 0, COLS - 1 do
            local dist = math.abs(x - player.cx) + math.abs(y - player.cy)
            local t = mine[y][x]
            local c = TILE_COLORS[t] or TILE_COLORS[T_EMPTY]

            if dist <= lr then
                local bright = 1.0 - (dist / lr) * 0.6
                lurek.render.setColor(c[1] * bright, c[2] * bright, c[3] * bright, 1)
            else
                -- Dark / hidden
                lurek.render.setColor(0.03, 0.02, 0.01, 1)
            end
            lurek.render.rectangle("fill", x * TILE, y * TILE, TILE - 1, TILE - 1)

            -- Tile detail overlays
            if dist <= lr and t == T_ORE then
                lurek.render.setColor(0.8, 0.55, 0.2, 0.5)
                lurek.render.rectangle("fill", x * TILE + 8, y * TILE + 8, 6, 6)
                lurek.render.rectangle("fill", x * TILE + 18, y * TILE + 20, 5, 5)
            elseif dist <= lr and t == T_GOLD then
                lurek.render.setColor(1, 0.9, 0.3, 0.7)
                lurek.render.rectangle("fill", x * TILE + 6, y * TILE + 10, 8, 6)
                lurek.render.rectangle("fill", x * TILE + 18, y * TILE + 16, 6, 8)
            elseif dist <= lr and t == T_GEM then
                lurek.render.setColor(0.4, 1, 1, 0.8)
                lurek.render.rectangle("fill", x * TILE + 10, y * TILE + 8, 12, 16)
                lurek.render.setColor(0.7, 1, 1, 0.5)
                lurek.render.rectangle("fill", x * TILE + 13, y * TILE + 10, 6, 4)
            elseif dist <= lr and t == T_LADDER then
                lurek.render.setColor(0.85, 0.65, 0.30, 1)
                lurek.render.rectangle("fill", x * TILE + 4, y * TILE, 4, TILE)
                lurek.render.rectangle("fill", x * TILE + 24, y * TILE, 4, TILE)
                lurek.render.rectangle("fill", x * TILE + 4, y * TILE + 8, 24, 3)
                lurek.render.rectangle("fill", x * TILE + 4, y * TILE + 22, 24, 3)
            end
        end
    end

    -- Draw player
    lurek.render.setColor(1, 0.85, 0.3, 1)
    lurek.render.rectangle("fill", player.cx * TILE + 4, player.cy * TILE + 2, TILE - 8, TILE - 4)
    -- Hard hat
    lurek.render.setColor(0.9, 0.7, 0.1, 1)
    lurek.render.rectangle("fill", player.cx * TILE + 6, player.cy * TILE, TILE - 12, 6)
    -- Headlamp glow
    if upgrades.headlamp then
        lurek.render.setColor(1, 1, 0.7, 0.15)
        local glow = lr * TILE
        lurek.render.rectangle("fill", player.cx * TILE - glow + TILE / 2, player.cy * TILE - glow + TILE / 2, glow * 2, glow * 2)
    end

    -- Dig progress indicator (world-space bar above target tile)
    if dig.active then
        local progress = dig.timer / dig.duration
        lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
        lurek.render.rectangle("fill", dig.tx * TILE, dig.ty * TILE - 6, TILE, 4)
        lurek.render.setColor(0.2, 0.9, 0.3, 1)
        lurek.render.rectangle("fill", dig.tx * TILE, dig.ty * TILE - 6, TILE * progress, 4)
    end

    -- Particles (world-space)
    for _, p in ipairs(particles) do
        local a = math.min(p.life / 0.3, 1)
        lurek.render.setColor(p.r, p.g, p.b, a)
        lurek.render.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end

    _cam:reset()
end

-- ── Render UI ───────────────────────────────────────────────────
function lurek.draw_ui()
    if state == "TITLE" then
        lurek.render.setColor(0.85, 0.7, 0.2, 1)
        lurek.render.print("MINING", W / 2 - 80, H / 3, 48)
        lurek.render.setColor(0.7, 0.55, 0.2, 1)
        lurek.render.print("DIG DEEP, FIND RICHES", W / 2 - 130, H / 3 + 60, 20)
        lurek.render.setColor(0.6, 0.6, 0.5, 0.7 + math.sin(lurek.timer.getTime() * 3) * 0.3)
        lurek.render.print("Press ENTER to start", W / 2 - 100, H / 2 + 60, 16)
        lurek.render.setColor(0.4, 0.4, 0.35, 1)
        lurek.render.print("ESC to quit", W / 2 - 45, H / 2 + 90, 14)
        return
    end

    if state == "GAME_OVER" then
        lurek.render.setColor(0.9, 0.15, 0.1, 1)
        lurek.render.print("GAME OVER", W / 2 - 90, H / 3, 40)
        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.print("You were buried at depth " .. player.cy, W / 2 - 130, H / 3 + 55, 18)
        lurek.render.print("Gold collected: " .. player.gold .. "g", W / 2 - 85, H / 3 + 85, 18)
        lurek.render.setColor(0.6, 0.6, 0.5, 0.7 + math.sin(lurek.timer.getTime() * 3) * 0.3)
        lurek.render.print("Press ENTER to retry", W / 2 - 100, H / 2 + 60, 16)
        return
    end

    if state == "VICTORY" then
        lurek.render.setColor(1, 0.9, 0.2, 1)
        lurek.render.print("VICTORY!", W / 2 - 75, H / 3, 42)
        lurek.render.setColor(0.8, 0.8, 0.7, 1)
        lurek.render.print("You struck it rich with " .. player.gold .. "g!", W / 2 - 140, H / 3 + 55, 20)
        lurek.render.setColor(0.6, 0.6, 0.5, 0.7 + math.sin(lurek.timer.getTime() * 3) * 0.3)
        lurek.render.print("Press ENTER for title", W / 2 - 100, H / 2 + 60, 16)
        return
    end

    if state == "SHOP" then
        lurek.render.setColor(0.85, 0.7, 0.2, 1)
        lurek.render.print("SURFACE SHOP", W / 2 - 80, 40, 28)
        lurek.render.setColor(0.7, 0.7, 0.6, 1)
        lurek.render.print("Gold: " .. player.gold .. "g", W / 2 - 40, 80, 18)

        for i, item in ipairs(shop_items) do
            local y = 130 + (i - 1) * 60
            local owned = upgrades[item.key]
            if i == shop_sel then
                lurek.render.setColor(0.3, 0.25, 0.1, 0.6)
                lurek.render.rectangle("fill", W / 2 - 160, y - 5, 320, 50)
            end
            if owned then
                lurek.render.setColor(0.4, 0.7, 0.3, 1)
                lurek.render.print(item.name .. " [OWNED]", W / 2 - 140, y, 18)
            elseif player.gold >= item.cost then
                lurek.render.setColor(0.9, 0.85, 0.6, 1)
                lurek.render.print(item.name .. " — " .. item.cost .. "g", W / 2 - 140, y, 18)
            else
                lurek.render.setColor(0.5, 0.4, 0.3, 1)
                lurek.render.print(item.name .. " — " .. item.cost .. "g", W / 2 - 140, y, 18)
            end
            lurek.render.setColor(0.6, 0.6, 0.5, 0.8)
            lurek.render.print(item.desc, W / 2 - 140, y + 22, 14)
        end

        lurek.render.setColor(0.5, 0.5, 0.4, 1)
        lurek.render.print("UP/DOWN to select, ENTER to buy, ESC to return", W / 2 - 180, H - 60, 14)
        return
    end

    -- MINING HUD
    -- Top bar background
    lurek.render.setColor(0, 0, 0, 0.6)
    lurek.render.rectangle("fill", 0, 0, W, 36)

    -- Depth
    lurek.render.setColor(0.8, 0.8, 0.7, 1)
    lurek.render.print("Depth: " .. player.cy .. "/" .. ROWS, 10, 8, 16)

    -- Gold
    lurek.render.setColor(1, 0.85, 0.2, 1)
    lurek.render.print("Gold: " .. math.floor(gold_display) .. "g", 180, 8, 16)

    -- Items
    lurek.render.setColor(0.7, 0.7, 0.65, 1)
    lurek.render.print("Items: " .. player.items .. "/" .. max_carry(), 340, 8, 16)

    -- HP bar
    lurek.render.setColor(0.3, 0.3, 0.3, 0.8)
    lurek.render.rectangle("fill", 500, 10, 100, 14)
    local hp_frac = player.hp / 100
    local hp_r = hp_frac < 0.5 and 1 or (1 - (hp_frac - 0.5) * 2)
    local hp_g = hp_frac > 0.3 and math.min(hp_frac * 1.5, 1) or 0.2
    lurek.render.setColor(hp_r, hp_g, 0.1, 1)
    lurek.render.rectangle("fill", 500, 10, 100 * hp_frac, 14)
    lurek.render.setColor(1, 1, 1, 0.9)
    lurek.render.print("HP:" .. player.hp, 505, 9, 13)

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.4, 0.7)
    lurek.render.print("FPS:" .. math.floor(fps), W - 70, 8, 13)

    -- Upgrade indicators
    local uy = 44
    if upgrades.pickaxe then
        lurek.render.setColor(0.6, 0.9, 0.3, 0.8)
        lurek.render.print("[PICK+]", 10, uy, 12)
    end
    if upgrades.headlamp then
        lurek.render.setColor(1, 1, 0.6, 0.8)
        lurek.render.print("[LAMP]", 75, uy, 12)
    end
    if upgrades.cart then
        lurek.render.setColor(0.6, 0.7, 0.9, 0.8)
        lurek.render.print("[CART]", 135, uy, 12)
    end

    -- Surface hint
    if player.cy == 0 then
        lurek.render.setColor(0.7, 0.7, 0.5, 0.6 + math.sin(lurek.timer.getTime() * 2) * 0.3)
        lurek.render.print("Press S to open shop  |  L to place ladder (5g)", W / 2 - 180, H - 30, 14)
    end
end
