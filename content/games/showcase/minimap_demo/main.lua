-- Minimap Demo — Lurek2D
-- Category: showcase
-- Explore a large procedurally generated world with fog of war minimap

-- ── Constants ──────────────────────────────────────────────────────────
local WORLD_W        = 100
local WORLD_H        = 100
local TILE_SIZE       = 16
local WORLD_PX_W     = WORLD_W * TILE_SIZE
local WORLD_PX_H     = WORLD_H * TILE_SIZE

local PLAYER_SIZE     = 12
local PLAYER_SPEED    = 200
local REVEAL_RADIUS   = 8

local MINIMAP_MIN     = 150
local MINIMAP_MAX     = 300
local MINIMAP_DEFAULT = 200
local MINIMAP_STEP    = 25

local NUM_POIS        = 10

local TILE_GRASS   = 1
local TILE_WATER   = 2
local TILE_MOUNTAIN = 3
local TILE_FOREST  = 4
local TILE_SAND    = 5

-- ── State ──────────────────────────────────────────────────────────────
local state         = "TITLE"
local tiles         = {}
local explored      = {}
local visible       = {}

local player_x, player_y       = 0, 0
local player_draw_x, player_draw_y = 0, 0
local player_blink  = 0

local pois          = {}
local discovered    = 0

local minimap_size  = MINIMAP_DEFAULT
local minimap_target_size = MINIMAP_DEFAULT
local minimap_show  = true

local screen_w, screen_h = 800, 600
local title_alpha   = 0
local title_prompt_alpha = 0
local title_prompt_dir = 1
local discovery_popup_alpha = 0
local discovery_popup_text  = ""

local particles     = {}
local tweens        = {}

-- ── Helpers ────────────────────────────────────────────────────────────

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function hash2d(x, y)
    local n = x * 374761393 + y * 668265263
    n = (n * (n * n * 15731 + 789221) + 1376312589)
    return math.abs(n % 1000) / 1000.0
end

local function tile_color(t)
    if t == TILE_GRASS   then return 0.30, 0.65, 0.20 end
    if t == TILE_WATER   then return 0.15, 0.35, 0.75 end
    if t == TILE_MOUNTAIN then return 0.55, 0.40, 0.25 end
    if t == TILE_FOREST  then return 0.12, 0.40, 0.12 end
    if t == TILE_SAND    then return 0.85, 0.78, 0.55 end
    return 0.5, 0.5, 0.5
end

-- ── Tween engine ───────────────────────────────────────────────────────

local function tween_add(target_table, key, target_val, duration, ease)
    ease = ease or "linear"
    table.insert(tweens, {
        tbl      = target_table,
        key      = key,
        start    = target_table[key],
        target   = target_val,
        duration = duration,
        elapsed  = 0,
        ease     = ease,
    })
end

local function ease_apply(e, t)
    if e == "ease_out" then return 1 - (1 - t) * (1 - t) end
    if e == "ease_in"  then return t * t end
    if e == "ease_in_out" then
        if t < 0.5 then return 2 * t * t end
        return 1 - ((-2 * t + 2) * (-2 * t + 2)) / 2
    end
    return t -- linear
end

local function tweens_update(dt)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = clamp(tw.elapsed / tw.duration, 0, 1)
        t = ease_apply(tw.ease, t)
        tw.tbl[tw.key] = lerp(tw.start, tw.target, t)
        if tw.elapsed >= tw.duration then
            tw.tbl[tw.key] = tw.target
            table.remove(tweens, i)
        else
            i = i + 1
        end
    end
end

-- ── Particles ──────────────────────────────────────────────────────────

local function particle_spawn(x, y, count, r, g, b, life, spread)
    spread = spread or 40
    for _ = 1, count do
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * spread,
            vy = (math.random() - 0.5) * spread,
            life = life or 0.8,
            max_life = life or 0.8,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
        })
    end
end

local function particles_update(dt)
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

-- ── World generation ───────────────────────────────────────────────────

local function generate_world()
    math.randomseed(os.time())
    for y = 1, WORLD_H do
        tiles[y] = {}
        explored[y] = {}
        visible[y] = {}
        for x = 1, WORLD_W do
            local h = hash2d(x, y)
            local h2 = hash2d(x + 1000, y + 1000)
            local tile
            if h < 0.12 then
                tile = TILE_WATER
            elseif h < 0.18 then
                tile = TILE_SAND
            elseif h < 0.55 then
                tile = TILE_GRASS
            elseif h < 0.78 then
                tile = TILE_FOREST
            else
                tile = TILE_MOUNTAIN
            end
            -- cluster smoothing
            if h2 < 0.3 and y > 1 and tiles[y-1][x] then
                tile = tiles[y-1][x]
            end
            tiles[y][x] = tile
            explored[y][x] = false
            visible[y][x] = false
        end
    end
end

local function generate_pois()
    pois = {}
    for i = 1, NUM_POIS do
        local px, py
        repeat
            px = math.random(5, WORLD_W - 5)
            py = math.random(5, WORLD_H - 5)
        until tiles[py][px] ~= TILE_WATER
        pois[i] = { tx = px, ty = py, found = false }
    end
end

-- ── Fog of war ─────────────────────────────────────────────────────────

local function update_visibility()
    -- clear visible
    for y = 1, WORLD_H do
        for x = 1, WORLD_W do
            visible[y][x] = false
        end
    end
    -- player tile position
    local ptx = math.floor(player_x / TILE_SIZE) + 1
    local pty = math.floor(player_y / TILE_SIZE) + 1
    for dy = -REVEAL_RADIUS, REVEAL_RADIUS do
        for dx = -REVEAL_RADIUS, REVEAL_RADIUS do
            if dx * dx + dy * dy <= REVEAL_RADIUS * REVEAL_RADIUS then
                local tx = ptx + dx
                local ty = pty + dy
                if tx >= 1 and tx <= WORLD_W and ty >= 1 and ty <= WORLD_H then
                    visible[ty][tx] = true
                    if not explored[ty][tx] then
                        explored[ty][tx] = true
                        -- fog reveal shimmer particle
                        if math.random() < 0.08 then
                            local wx = (tx - 1) * TILE_SIZE + TILE_SIZE * 0.5
                            local wy = (ty - 1) * TILE_SIZE + TILE_SIZE * 0.5
                            particle_spawn(wx, wy, 1, 0.5, 0.7, 1.0, 0.5, 15)
                        end
                    end
                end
            end
        end
    end
end

local function count_explored()
    local c = 0
    for y = 1, WORLD_H do
        for x = 1, WORLD_W do
            if explored[y][x] then c = c + 1 end
        end
    end
    return c
end

-- ── Input bindings ─────────────────────────────────────────────────────

local move_up, move_down, move_left, move_right = false, false, false, false

lurek.input.bind("move_up",    "w")
lurek.input.bind("move_down",  "s")
lurek.input.bind("move_left",  "a")
lurek.input.bind("move_right", "d")
lurek.input.bind("toggle_map", "m")
lurek.input.bind("zoom_in",    "=")   -- plus key
lurek.input.bind("zoom_out",   "-")
lurek.input.bind("quit",       "escape")

lurek.input.on("toggle_map", "pressed", function()
    if state == "EXPLORING" then
        minimap_show = not minimap_show
    end
end)

lurek.input.on("zoom_in", "pressed", function()
    if state == "EXPLORING" and minimap_show then
        minimap_target_size = clamp(minimap_target_size + MINIMAP_STEP, MINIMAP_MIN, MINIMAP_MAX)
        tween_add(_G, "minimap_size", minimap_target_size, 0.25, "ease_out")
    end
end)

lurek.input.on("zoom_out", "pressed", function()
    if state == "EXPLORING" and minimap_show then
        minimap_target_size = clamp(minimap_target_size - MINIMAP_STEP, MINIMAP_MIN, MINIMAP_MAX)
        tween_add(_G, "minimap_size", minimap_target_size, 0.25, "ease_out")
    end
end)

lurek.input.on("quit", "pressed", function()
    lurek.event.quit()
end)

-- ── Callbacks ──────────────────────────────────────────────────────────

function lurek.init()
    screen_w, screen_h = lurek.window.getSize()
    lurek.render.setBackgroundColor(0.1, 0.15, 0.1)
    generate_world()
    generate_pois()
    -- start player at center
    player_x = (WORLD_W / 2) * TILE_SIZE
    player_y = (WORLD_H / 2) * TILE_SIZE
    player_draw_x = player_x
    player_draw_y = player_y
    update_visibility()
end

function lurek.ready()
    lurek.window.setTitle("Minimap Demo — Lurek2D")
    -- fade in title
    tween_add(_G, "title_alpha", 1, 0.8, "ease_out")
end

lurek.process(function(dt)
    tweens_update(dt)
    particles_update(dt)

    if state == "TITLE" then
        -- blinking prompt
        title_prompt_alpha = title_prompt_alpha + title_prompt_dir * dt * 2
        if title_prompt_alpha >= 1 then title_prompt_alpha = 1; title_prompt_dir = -1 end
        if title_prompt_alpha <= 0.2 then title_prompt_alpha = 0.2; title_prompt_dir = 1 end

        if lurek.input.isPressed("move_up") or lurek.input.isPressed("move_down")
           or lurek.input.isPressed("move_left") or lurek.input.isPressed("move_right") then
            state = "EXPLORING"
        end
        return
    end

    -- EXPLORING state
    move_up    = lurek.input.isDown("move_up")
    move_down  = lurek.input.isDown("move_down")
    move_left  = lurek.input.isDown("move_left")
    move_right = lurek.input.isDown("move_right")

    local dx, dy = 0, 0
    if move_up    then dy = dy - 1 end
    if move_down  then dy = dy + 1 end
    if move_left  then dx = dx - 1 end
    if move_right then dx = dx + 1 end

    -- normalize diagonal
    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2)
        dx = dx * inv
        dy = dy * inv
    end

    local target_x = clamp(player_x + dx * PLAYER_SPEED * dt, 0, WORLD_PX_W - PLAYER_SIZE)
    local target_y = clamp(player_y + dy * PLAYER_SPEED * dt, 0, WORLD_PX_H - PLAYER_SIZE)

    -- check collision with water
    local tx = math.floor(target_x / TILE_SIZE) + 1
    local ty = math.floor(target_y / TILE_SIZE) + 1
    tx = clamp(tx, 1, WORLD_W)
    ty = clamp(ty, 1, WORLD_H)
    if tiles[ty][tx] ~= TILE_WATER then
        player_x = target_x
        player_y = target_y
    end

    -- smooth draw position
    player_draw_x = lerp(player_draw_x, player_x, clamp(dt * 12, 0, 1))
    player_draw_y = lerp(player_draw_y, player_y, clamp(dt * 12, 0, 1))

    -- camera follow
    local cam_x = player_draw_x - screen_w / 2 + PLAYER_SIZE / 2
    local cam_y = player_draw_y - screen_h / 2 + PLAYER_SIZE / 2
    cam_x = clamp(cam_x, 0, WORLD_PX_W - screen_w)
    cam_y = clamp(cam_y, 0, WORLD_PX_H - screen_h)
    lurek.camera.setPosition(cam_x, cam_y)

    update_visibility()

    -- player blink for minimap
    player_blink = player_blink + dt * 4
    if player_blink > 2 * math.pi then player_blink = player_blink - 2 * math.pi end

    -- check POI discovery
    local ptx = math.floor(player_x / TILE_SIZE) + 1
    local pty = math.floor(player_y / TILE_SIZE) + 1
    for _, poi in ipairs(pois) do
        if not poi.found then
            local ddx = ptx - poi.tx
            local ddy = pty - poi.ty
            if ddx * ddx + ddy * ddy <= 4 then
                poi.found = true
                discovered = discovered + 1
                -- sparkle particles at POI world position
                local wx = (poi.tx - 1) * TILE_SIZE + TILE_SIZE * 0.5
                local wy = (poi.ty - 1) * TILE_SIZE + TILE_SIZE * 0.5
                particle_spawn(wx, wy, 25, 1.0, 0.9, 0.2, 1.2, 60)
                -- discovery popup
                discovery_popup_text = "Discovery " .. discovered .. "/" .. NUM_POIS .. "!"
                discovery_popup_alpha = 1.0
                tween_add(_G, "discovery_popup_alpha", 0, 2.0, "ease_in")
            end
        end
    end

    -- update FPS title
    local fps = lurek.timer.getFPS()
    local exp = count_explored()
    lurek.window.setTitle(string.format(
        "Minimap Demo | FPS: %d | Explored: %d/%d | Discoveries: %d/%d",
        fps, exp, WORLD_W * WORLD_H, discovered, NUM_POIS
    ))
end)

-- ── Render: world view ─────────────────────────────────────────────────

lurek.render(function()
    if state == "TITLE" then
        return
    end

    local cam_x, cam_y = lurek.camera.getPosition()

    -- calculate visible tile range
    local start_tx = math.floor(cam_x / TILE_SIZE)
    local start_ty = math.floor(cam_y / TILE_SIZE)
    local end_tx = start_tx + math.ceil(screen_w / TILE_SIZE) + 1
    local end_ty = start_ty + math.ceil(screen_h / TILE_SIZE) + 1
    start_tx = clamp(start_tx, 0, WORLD_W - 1)
    start_ty = clamp(start_ty, 0, WORLD_H - 1)
    end_tx = clamp(end_tx, 0, WORLD_W - 1)
    end_ty = clamp(end_ty, 0, WORLD_H - 1)

    -- draw visible tiles
    for ty = start_ty, end_ty do
        for tx = start_tx, end_tx do
            local gx = ty + 1
            local gy = tx + 1
            if gx >= 1 and gx <= WORLD_H and gy >= 1 and gy <= WORLD_W then
                local r, g, b = tile_color(tiles[gx][gy])
                lurek.render.setColor(r, g, b, 1)
                lurek.render.rectangle(tx * TILE_SIZE, ty * TILE_SIZE, TILE_SIZE, TILE_SIZE)
            end
        end
    end

    -- draw POIs (stars) that are in visible+explored area
    for _, poi in ipairs(pois) do
        if not poi.found then
            local ptx = poi.tx
            local pty = poi.ty
            if explored[pty] and explored[pty][ptx] then
                local wx = (ptx - 1) * TILE_SIZE + TILE_SIZE * 0.5
                local wy = (pty - 1) * TILE_SIZE + TILE_SIZE * 0.5
                -- draw star as diamond
                lurek.render.setColor(1.0, 0.9, 0.1, 1)
                lurek.render.rectangle(wx - 4, wy - 4, 8, 8)
                lurek.render.setColor(1.0, 1.0, 0.5, 0.6)
                lurek.render.rectangle(wx - 6, wy - 2, 12, 4)
                lurek.render.rectangle(wx - 2, wy - 6, 4, 12)
            end
        end
    end

    -- draw particles (world-space)
    for _, p in ipairs(particles) do
        local a = clamp(p.life / p.max_life, 0, 1)
        lurek.render.setColor(p.r, p.g, p.b, a)
        lurek.render.rectangle(p.x - p.size * 0.5, p.y - p.size * 0.5, p.size, p.size)
    end

    -- draw player
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.rectangle(player_draw_x, player_draw_y, PLAYER_SIZE, PLAYER_SIZE)
    -- player outline
    lurek.render.setColor(0.2, 0.2, 0.2, 1)
    lurek.render.rectangle(player_draw_x - 1, player_draw_y - 1, PLAYER_SIZE + 2, 1)
    lurek.render.rectangle(player_draw_x - 1, player_draw_y + PLAYER_SIZE, PLAYER_SIZE + 2, 1)
    lurek.render.rectangle(player_draw_x - 1, player_draw_y, 1, PLAYER_SIZE)
    lurek.render.rectangle(player_draw_x + PLAYER_SIZE, player_draw_y, 1, PLAYER_SIZE)
end)

-- ── Render UI: minimap, fog, stats, title ──────────────────────────────

lurek.render_ui(function()
    if state == "TITLE" then
        -- title screen
        lurek.render.setColor(1, 1, 1, title_alpha)
        lurek.render.print("MINIMAP DEMO", screen_w / 2 - 100, screen_h / 2 - 60, 32)

        lurek.render.setColor(0.7, 0.9, 0.7, title_prompt_alpha)
        lurek.render.print("EXPLORE THE WORLD", screen_w / 2 - 90, screen_h / 2, 18)

        lurek.render.setColor(0.5, 0.5, 0.5, title_prompt_alpha * 0.7)
        lurek.render.print("Press WASD to begin", screen_w / 2 - 80, screen_h / 2 + 40, 14)
        return
    end

    -- ── Minimap ────────────────────────────────────────────────────────
    if minimap_show then
        local mm = math.floor(minimap_size)
        local margin = 10
        local mx = screen_w - mm - margin
        local my = margin
        local scale = mm / WORLD_W

        -- minimap background
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle(mx - 2, my - 2, mm + 4, mm + 4)

        -- draw tiles on minimap
        for ty = 1, WORLD_H do
            for tx = 1, WORLD_W do
                local px = mx + (tx - 1) * scale
                local py = my + (ty - 1) * scale
                local sz = math.max(scale, 1)

                if visible[ty][tx] then
                    local r, g, b = tile_color(tiles[ty][tx])
                    lurek.render.setColor(r, g, b, 1)
                    lurek.render.rectangle(px, py, sz, sz)
                elseif explored[ty][tx] then
                    local r, g, b = tile_color(tiles[ty][tx])
                    lurek.render.setColor(r * 0.4, g * 0.4, b * 0.4, 0.8)
                    lurek.render.rectangle(px, py, sz, sz)
                else
                    lurek.render.setColor(0.05, 0.05, 0.05, 0.9)
                    lurek.render.rectangle(px, py, sz, sz)
                end
            end
        end

        -- draw POIs on minimap
        for _, poi in ipairs(pois) do
            if explored[poi.ty] and explored[poi.ty][poi.tx] then
                local px = mx + (poi.tx - 1) * scale
                local py = my + (poi.ty - 1) * scale
                if poi.found then
                    lurek.render.setColor(0.5, 0.5, 0.3, 0.6)
                else
                    lurek.render.setColor(1.0, 0.9, 0.1, 1)
                end
                lurek.render.rectangle(px - 1, py - 1, 3, 3)
            end
        end

        -- viewport rectangle
        local cam_x, cam_y = lurek.camera.getPosition()
        local vx = mx + (cam_x / TILE_SIZE) * scale
        local vy = my + (cam_y / TILE_SIZE) * scale
        local vw = (screen_w / TILE_SIZE) * scale
        local vh = (screen_h / TILE_SIZE) * scale
        lurek.render.setColor(1, 1, 1, 0.8)
        -- top
        lurek.render.rectangle(vx, vy, vw, 1)
        -- bottom
        lurek.render.rectangle(vx, vy + vh, vw, 1)
        -- left
        lurek.render.rectangle(vx, vy, 1, vh)
        -- right
        lurek.render.rectangle(vx + vw, vy, 1, vh)

        -- player dot on minimap (blinking)
        local blink_alpha = 0.5 + 0.5 * math.sin(player_blink)
        local ppx = mx + (player_x / TILE_SIZE) * scale
        local ppy = my + (player_y / TILE_SIZE) * scale
        lurek.render.setColor(1, 1, 1, blink_alpha)
        lurek.render.rectangle(ppx - 2, ppy - 2, 4, 4)

        -- minimap border
        lurek.render.setColor(0.6, 0.7, 0.6, 0.5)
        lurek.render.rectangle(mx - 2, my - 2, mm + 4, 1)
        lurek.render.rectangle(mx - 2, my + mm + 1, mm + 4, 1)
        lurek.render.rectangle(mx - 2, my - 2, 1, mm + 4)
        lurek.render.rectangle(mx + mm + 1, my - 2, 1, mm + 4)
    end

    -- ── Stats overlay ──────────────────────────────────────────────────
    local exp = count_explored()
    local ptx = math.floor(player_x / TILE_SIZE) + 1
    local pty = math.floor(player_y / TILE_SIZE) + 1

    lurek.render.setColor(0, 0, 0, 0.5)
    lurek.render.rectangle(5, screen_h - 70, 280, 65)

    lurek.render.setColor(0.9, 0.95, 0.9, 1)
    lurek.render.print(
        string.format("Explored: %d / %d (%.1f%%)", exp, WORLD_W * WORLD_H, exp / (WORLD_W * WORLD_H) * 100),
        10, screen_h - 65, 13
    )
    lurek.render.print(
        string.format("Discoveries: %d / %d", discovered, NUM_POIS),
        10, screen_h - 45, 13
    )
    lurek.render.print(
        string.format("Position: (%d, %d)  |  Minimap: %dpx  [M] toggle  [+/-] zoom",
            ptx, pty, math.floor(minimap_size)),
        10, screen_h - 25, 11
    )

    -- ── Discovery popup ────────────────────────────────────────────────
    if discovery_popup_alpha > 0.01 then
        lurek.render.setColor(1.0, 0.9, 0.2, discovery_popup_alpha)
        lurek.render.print(discovery_popup_text, screen_w / 2 - 60, screen_h / 2 - 30, 22)
    end

    -- ── Controls hint (first 5 seconds) ────────────────────────────────
    local t = lurek.timer.getTime()
    if t < 8 then
        local hint_a = clamp(1 - (t - 5) / 3, 0, 1)
        if hint_a > 0 then
            lurek.render.setColor(0.7, 0.7, 0.7, hint_a * 0.6)
            lurek.render.print("WASD: move | M: minimap | +/-: zoom | ESC: quit", 10, 10, 12)
        end
    end
end)
