-- Sprites Demo — Lurek2D
-- Category: showcase
-- Procedural pixel art sprites with animation, scaling, tinting, and collectibles

-- ============================================================
-- Constants
-- ============================================================

local SCREEN_W = 800
local SCREEN_H = 600
local PLAYER_SPEED = 150
local ANIM_INTERVAL = 0.2
local COIN_COUNT = 20
local TREE_COUNT = 5
local TRAIL_LENGTH = 5
local MIN_SCALE = 1
local MAX_SCALE = 4

-- ============================================================
-- States
-- ============================================================
local STATE_TITLE   = "TITLE"
local STATE_PLAYING = "PLAYING"

local state = STATE_TITLE
local title_timer = 0
local title_alpha = 0

-- ============================================================
-- Game data
-- ============================================================
local player = { x = 400, y = 300, frame = 1, anim_timer = 0, moving = false }
local coins = {}
local trees = {}
local score = 0
local sprite_scale = 2
local tint_index = 1
local tint_modes = {
    { name = "Normal", r = 1.0, g = 1.0, b = 1.0 },
    { name = "Red",    r = 1.0, g = 0.4, b = 0.4 },
    { name = "Blue",   r = 0.4, g = 0.4, b = 1.0 },
    { name = "Green",  r = 0.4, g = 1.0, b = 0.4 },
}
local trail_on = false
local trail_positions = {}

-- ============================================================
-- Images (created procedurally)
-- ============================================================
local img_char = {}    -- 2 animation frames
local img_coin = {}    -- 2 rotation frames
local img_tree = nil
local img_heart = nil
local img_star = nil

-- ============================================================
-- Particles & tweens
-- ============================================================
local ps_sparkle = nil
local coin_tweens = {}  -- per-coin hover offset { y = 0 }
local popups = {}       -- score popups { x, y, alpha, text }

-- ============================================================
-- FPS counter
-- ============================================================
local fps = 0
local fps_timer = 0
local fps_count = 0

-- ============================================================
-- Sprite generation helpers
-- ============================================================
local function px(data, x, y, r, g, b, a)
    data:setPixel(x, y, r, g, b, a or 255)
end

local function make_character_frame1()
    local d = lurek.image.newImageData(16, 16)
    -- Head (skin)
    for py = 1, 4 do for px_ = 5, 10 do px(d, px_, py, 255, 210, 170) end end
    -- Eyes
    px(d, 6, 2, 40, 40, 40); px(d, 9, 2, 40, 40, 40)
    -- Body (blue shirt)
    for py = 5, 9 do for px_ = 4, 11 do px(d, px_, py, 60, 100, 200) end end
    -- Arms (skin)
    for py = 5, 8 do px(d, 3, py, 255, 210, 170); px(d, 12, py, 255, 210, 170) end
    -- Legs (brown) — standing pose
    for py = 10, 14 do px(d, 5, py, 140, 90, 50); px(d, 6, py, 140, 90, 50) end
    for py = 10, 14 do px(d, 9, py, 140, 90, 50); px(d, 10, py, 140, 90, 50) end
    -- Shoes (dark)
    px(d, 5, 15, 60, 40, 30); px(d, 6, 15, 60, 40, 30)
    px(d, 9, 15, 60, 40, 30); px(d, 10, 15, 60, 40, 30)
    return lurek.render.newImage(d)
end

local function make_character_frame2()
    local d = lurek.image.newImageData(16, 16)
    -- Head (skin)
    for py = 1, 4 do for px_ = 5, 10 do px(d, px_, py, 255, 210, 170) end end
    -- Eyes
    px(d, 6, 2, 40, 40, 40); px(d, 9, 2, 40, 40, 40)
    -- Body (blue shirt)
    for py = 5, 9 do for px_ = 4, 11 do px(d, px_, py, 60, 100, 200) end end
    -- Arms (skin)
    for py = 5, 8 do px(d, 3, py, 255, 210, 170); px(d, 12, py, 255, 210, 170) end
    -- Legs (brown) — walking pose (spread apart)
    for py = 10, 14 do px(d, 4, py, 140, 90, 50); px(d, 5, py, 140, 90, 50) end
    for py = 10, 14 do px(d, 10, py, 140, 90, 50); px(d, 11, py, 140, 90, 50) end
    -- Shoes (dark)
    px(d, 4, 15, 60, 40, 30); px(d, 5, 15, 60, 40, 30)
    px(d, 10, 15, 60, 40, 30); px(d, 11, 15, 60, 40, 30)
    return lurek.render.newImage(d)
end

local function make_coin_frame1()
    local d = lurek.image.newImageData(8, 8)
    -- Circle-ish golden coin
    local cx, cy, r2 = 3.5, 3.5, 9
    for py = 0, 7 do
        for px_ = 0, 7 do
            local dx, dy = px_ - cx, py - cy
            if dx * dx + dy * dy <= r2 then
                px(d, px_, py, 255, 210, 60)
            end
        end
    end
    -- Highlight
    px(d, 3, 2, 255, 240, 140); px(d, 4, 2, 255, 240, 140)
    return lurek.render.newImage(d)
end

local function make_coin_frame2()
    local d = lurek.image.newImageData(8, 8)
    -- Slightly narrower coin (simulated rotation)
    for py = 0, 7 do
        for px_ = 2, 5 do
            local dy = py - 3.5
            if dy * dy < 10 then
                px(d, px_, py, 230, 190, 50)
            end
        end
    end
    px(d, 3, 2, 255, 230, 120); px(d, 4, 2, 255, 230, 120)
    return lurek.render.newImage(d)
end

local function make_tree()
    local d = lurek.image.newImageData(16, 24)
    -- Trunk (brown)
    for py = 14, 23 do for px_ = 6, 9 do px(d, px_, py, 120, 80, 40) end end
    -- Canopy (green triangle)
    for row = 0, 13 do
        local half = math.floor(row * 0.6) + 1
        local cx_ = 7
        for off = -half, half do
            local col = cx_ + off
            if col >= 0 and col < 16 then
                local g = 120 + math.floor((14 - row) * 6)
                px(d, col, row, 30, math.min(g, 220), 40)
            end
        end
    end
    return lurek.render.newImage(d)
end

local function make_heart()
    local d = lurek.image.newImageData(8, 8)
    local pattern = {
        "..##.##.",
        ".######.",
        ".######.",
        ".######.",
        "..####..",
        "...##...",
        "....#...",
        "........",
    }
    for py = 0, 7 do
        local row = pattern[py + 1]
        for px_ = 0, 7 do
            if row:sub(px_ + 1, px_ + 1) == "#" then
                px(d, px_, py, 220, 40, 60)
            end
        end
    end
    return lurek.render.newImage(d)
end

local function make_star()
    local d = lurek.image.newImageData(8, 8)
    local pattern = {
        "...#....",
        "..###...",
        "########",
        ".######.",
        "..####..",
        ".##..##.",
        ".#....#.",
        "........",
    }
    for py = 0, 7 do
        local row = pattern[py + 1]
        for px_ = 0, 7 do
            if row:sub(px_ + 1, px_ + 1) == "#" then
                px(d, px_, py, 255, 230, 60)
            end
        end
    end
    return lurek.render.newImage(d)
end

-- ============================================================
-- Collision helpers
-- ============================================================
local function rects_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- ============================================================
-- Input bindings
-- ============================================================
lurek.input.bind("move_up",     { "w" })
lurek.input.bind("move_down",   { "s" })
lurek.input.bind("move_left",   { "a" })
lurek.input.bind("move_right",  { "d" })
lurek.input.bind("scale_up",    { "equal" })
lurek.input.bind("scale_down",  { "minus" })
lurek.input.bind("tint",        { "c" })
lurek.input.bind("trail",       { "t" })
lurek.input.bind("quit",        { "escape" })
lurek.input.bind("start",       { "return" })

-- ============================================================
-- Init
-- ============================================================
function lurek.init()
    lurek.window.setTitle("Sprites Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.15, 0.1)

    -- Generate sprites
    img_char[1] = make_character_frame1()
    img_char[2] = make_character_frame2()
    img_coin[1] = make_coin_frame1()
    img_coin[2] = make_coin_frame2()
    img_tree    = make_tree()
    img_heart   = make_heart()
    img_star    = make_star()

    -- Spawn coins
    for i = 1, COIN_COUNT do
        local ct = { y = 0 }
        coins[i] = {
            x = 40 + math.random() * (SCREEN_W - 80),
            y = 40 + math.random() * (SCREEN_H - 120),
            alive = true,
            frame = 1,
            frame_timer = math.random() * 0.5,
            hover = ct,
        }
        coin_tweens[i] = ct
    end

    -- Spawn trees (avoid spawn near center)
    for i = 1, TREE_COUNT do
        local tx, ty
        repeat
            tx = 30 + math.random() * (SCREEN_W - 60)
            ty = 30 + math.random() * (SCREEN_H - 100)
        until math.abs(tx - 400) > 80 or math.abs(ty - 300) > 80
        trees[i] = { x = tx, y = ty }
    end

    -- Sparkle particle system
    ps_sparkle = lurek.particle.newSystem({
        maxParticles = 100,
        emissionRate = 0,
        lifetimeMin = 0.2, lifetimeMax = 0.6,
        speedMin = 40, speedMax = 120,
        direction = -1.57, spread = 6.28,
        gravityY = 30,
        sizes = { 3, 2, 0 },
        colors = { 1, 1, 0.3, 1,  1, 0.8, 0.1, 0 },
    })

    -- Start coin hover tweens
    for i = 1, COIN_COUNT do
        local ct = coin_tweens[i]
        local function bounce()
            lurek.tween.to(ct, 0.6, { y = -4 }, "inOutSine", function()
                lurek.tween.to(ct, 0.6, { y = 4 }, "inOutSine", bounce)
            end)
        end
        -- Stagger start
        lurek.tween.to(ct, 0.3 + i * 0.05, { y = 4 }, "inOutSine", bounce)
    end

    lurek.camera.setPosition(0, 0)
end

-- ============================================================
-- Ready
-- ============================================================
local function _ready_setup()
    -- nothing extra
end

-- ============================================================
-- Process
-- ============================================================
function lurek.process(dt)
    -- FPS
    fps_count = fps_count + 1
    fps_timer = fps_timer + dt
    if fps_timer >= 1.0 then
        fps = fps_count
        fps_count = 0
        fps_timer = fps_timer - 1.0
    end

    -- Quit
    if lurek.input.pressed("quit") then
        lurek.event.quit()
        return
    end

    -- Update tweens + particles
    lurek.tween.update(dt)
    ps_sparkle:update(dt)

    -- Update popups
    for i = #popups, 1, -1 do
        local p = popups[i]
        p.y = p.y - 40 * dt
        p.alpha = p.alpha - 1.2 * dt
        if p.alpha <= 0 then table.remove(popups, i) end
    end

    -- ── Title state ────────────────────────────────────────
    if state == STATE_TITLE then
        title_timer = title_timer + dt
        title_alpha = math.min(1.0, title_timer * 1.5)
        if lurek.input.pressed("start") then
            state = STATE_PLAYING
        end
        return
    end

    -- ── Playing state ──────────────────────────────────────

    -- Movement
    local dx, dy = 0, 0
    if lurek.input.isActionDown("move_up")    then dy = dy - 1 end
    if lurek.input.isActionDown("move_down")  then dy = dy + 1 end
    if lurek.input.isActionDown("move_left")  then dx = dx - 1 end
    if lurek.input.isActionDown("move_right") then dx = dx + 1 end

    player.moving = (dx ~= 0 or dy ~= 0)

    if player.moving then
        -- Normalize diagonal
        if dx ~= 0 and dy ~= 0 then
            local inv = 1.0 / math.sqrt(2)
            dx = dx * inv
            dy = dy * inv
        end

        local nx = player.x + dx * PLAYER_SPEED * dt
        local ny = player.y + dy * PLAYER_SPEED * dt

        -- Tree collision check
        local blocked = false
        local ps = 16 * sprite_scale
        local tw, th = 16 * sprite_scale, 24 * sprite_scale
        for _, t in ipairs(trees) do
            if rects_overlap(nx, ny, ps, ps, t.x, t.y, tw, th) then
                blocked = true
                break
            end
        end

        if not blocked then
            player.x = nx
            player.y = ny
        end

        -- Screen wrapping
        if player.x < -ps then player.x = SCREEN_W end
        if player.x > SCREEN_W then player.x = -ps end
        if player.y < -ps then player.y = SCREEN_H end
        if player.y > SCREEN_H then player.y = -ps end

        -- Trail
        if trail_on then
            table.insert(trail_positions, 1, { x = player.x, y = player.y })
            while #trail_positions > TRAIL_LENGTH do
                table.remove(trail_positions)
            end
        end
    end

    -- Animation
    if player.moving then
        player.anim_timer = player.anim_timer + dt
        if player.anim_timer >= ANIM_INTERVAL then
            player.anim_timer = player.anim_timer - ANIM_INTERVAL
            player.frame = (player.frame == 1) and 2 or 1
        end
    else
        player.frame = 1
        player.anim_timer = 0
    end

    -- Coin animation (rotation frames)
    for _, c in ipairs(coins) do
        if c.alive then
            c.frame_timer = c.frame_timer + dt
            if c.frame_timer >= 0.35 then
                c.frame_timer = c.frame_timer - 0.35
                c.frame = (c.frame == 1) and 2 or 1
            end
        end
    end

    -- Coin collection
    local ps2 = 16 * sprite_scale
    local cs = 8 * sprite_scale
    for _, c in ipairs(coins) do
        if c.alive then
            if rects_overlap(player.x, player.y, ps2, ps2,
                             c.x, c.y + c.hover.y, cs, cs) then
                c.alive = false
                score = score + 1
                -- Sparkle burst at coin position
                ps_sparkle:setPosition(c.x + cs / 2, c.y + cs / 2)
                ps_sparkle:emit(12)
                -- Score popup
                table.insert(popups, {
                    x = c.x, y = c.y - 10,
                    alpha = 1.0, text = "+1",
                })
            end
        end
    end

    -- Scale controls
    if lurek.input.pressed("scale_up") then
        sprite_scale = math.min(MAX_SCALE, sprite_scale + 1)
    end
    if lurek.input.pressed("scale_down") then
        sprite_scale = math.max(MIN_SCALE, sprite_scale - 1)
    end

    -- Tint cycle
    if lurek.input.pressed("tint") then
        tint_index = (tint_index % #tint_modes) + 1
    end

    -- Trail toggle
    if lurek.input.pressed("trail") then
        trail_on = not trail_on
        if not trail_on then trail_positions = {} end
    end
end

-- ============================================================
-- Render (world space)
-- ============================================================
function lurek.draw()
    if state == STATE_TITLE then return end

    local s = sprite_scale

    -- Gather all Y-sortable objects
    local drawables = {}

    -- Trees
    for _, t in ipairs(trees) do
        table.insert(drawables, { y = t.y + 24 * s, kind = "tree", data = t })
    end

    -- Player
    table.insert(drawables, { y = player.y + 16 * s, kind = "player" })

    -- Sort by Y (bottom edge) for pseudo-depth
    table.sort(drawables, function(a, b) return a.y < b.y end)

    -- Trail (drawn behind everything)
    if trail_on and #trail_positions > 0 then
        for i, tp in ipairs(trail_positions) do
            local a = 0.15 * (1 - (i - 1) / TRAIL_LENGTH)
            local tint = tint_modes[tint_index]
            lurek.render.setColor(tint.r, tint.g, tint.b, a)
            lurek.render.draw(img_char[1], tp.x, tp.y, 0, s, s)
        end
    end

    -- Coins (behind everything sorted)
    lurek.render.setColor(1, 1, 1)
    for _, c in ipairs(coins) do
        if c.alive then
            lurek.render.draw(img_coin[c.frame], c.x, c.y + c.hover.y, 0, s, s)
        end
    end

    -- Draw sorted objects
    for _, obj in ipairs(drawables) do
        if obj.kind == "tree" then
            lurek.render.setColor(1, 1, 1)
            lurek.render.draw(img_tree, obj.data.x, obj.data.y, 0, s, s)
        elseif obj.kind == "player" then
            local tint = tint_modes[tint_index]
            lurek.render.setColor(tint.r, tint.g, tint.b)
            lurek.render.draw(img_char[player.frame], player.x, player.y, 0, s, s)
        end
    end

    -- Particles
    lurek.render.setColor(1, 1, 1)
    lurek.render.draw(ps_sparkle)

    -- Score popups
    for _, p in ipairs(popups) do
        lurek.render.setColor(1, 1, 0.3, p.alpha)
        lurek.render.print(p.text, p.x, p.y, 3)
    end
end

-- ============================================================
-- Render UI (screen space)
-- ============================================================
function lurek.draw_ui()
    if state == STATE_TITLE then
        -- Title screen
        local pulse = 0.7 + 0.3 * math.sin(title_timer * 3)
        lurek.render.setColor(0.3, 1.0, 0.4, title_alpha)
        lurek.render.print("SPRITES DEMO", SCREEN_W / 2 - 120, SCREEN_H / 2 - 60, 4)
        lurek.render.setColor(0.6, 0.8, 0.6, title_alpha * 0.8)
        lurek.render.print("PIXEL ART SHOWCASE", SCREEN_W / 2 - 130, SCREEN_H / 2 - 10, 3)

        lurek.render.setColor(1, 1, 1, pulse * title_alpha)
        lurek.render.print("Press ENTER to start", SCREEN_W / 2 - 100, SCREEN_H / 2 + 60, 2)

        -- Preview sprites on title
        lurek.render.setColor(1, 1, 1, title_alpha)
        if img_heart then lurek.render.draw(img_heart, 200, 400, 0, 3, 3) end
        if img_star  then lurek.render.draw(img_star,  340, 395, 0, 3, 3) end
        if img_char[1] then lurek.render.draw(img_char[1], 460, 380, 0, 3, 3) end
        if img_coin[1] then lurek.render.draw(img_coin[1], 570, 400, 0, 3, 3) end
        return
    end

    -- HUD background
    lurek.render.setColor(0, 0, 0, 0.6)
    lurek.render.rectangle("fill", 0, 0, SCREEN_W, 32)

    -- Score
    lurek.render.setColor(1, 1, 0.3)
    if img_coin[1] then lurek.render.draw(img_coin[1], 8, 4, 0, 3, 3) end
    lurek.render.print("x " .. score .. " / " .. COIN_COUNT, 38, 8, 2)

    -- Lives / hearts
    lurek.render.setColor(1, 1, 1)
    for i = 1, 3 do
        if img_heart then lurek.render.draw(img_heart, 180 + (i - 1) * 30, 4, 0, 3, 3) end
    end

    -- FPS
    lurek.render.setColor(0.6, 0.6, 0.6)
    lurek.render.print("FPS: " .. fps, SCREEN_W - 90, 8, 2)

    -- Info bar at bottom
    lurek.render.setColor(0, 0, 0, 0.5)
    lurek.render.rectangle("fill", 0, SCREEN_H - 28, SCREEN_W, 28)

    lurek.render.setColor(0.7, 0.7, 0.7)
    local tint = tint_modes[tint_index]
    local trail_str = trail_on and "ON" or "OFF"
    local alive_coins = 0
    for _, c in ipairs(coins) do if c.alive then alive_coins = alive_coins + 1 end end
    local info = string.format(
        "Scale: %dx | Tint: %s | Frame: %d | Trail: %s | Sprites: %d | Coins left: %d",
        sprite_scale, tint.name, player.frame, trail_str,
        COIN_COUNT + TREE_COUNT + 1, alive_coins
    )
    lurek.render.print(info, 10, SCREEN_H - 22, 1.5)

    -- Controls hint
    lurek.render.setColor(0.5, 0.5, 0.5, 0.7)
    lurek.render.print("WASD:move  +/-:scale  C:tint  T:trail  ESC:quit", 10, SCREEN_H - 10, 1)
end
