-- Wildlife Photography — Lurek2D Demo
-- Explore a nature reserve, photograph animals, fill your encyclopedia
-- Run with: cargo run -- content/demos/simulation/wildlife_photo

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local W, H = 800, 600

-- biome grid
local TILE = 40
local COLS, ROWS = W / TILE, H / TILE
local MAP_W, MAP_H = 1600, 1200

local biomes -- 2D grid
local player, camera_mode, noise_level
local animals, photos, encyclopedia, best_score
local day_timer, day_length, visibility
local message, msg_timer

local BIOME_COLORS = {
    forest = {0.12, 0.35, 0.1},
    meadow = {0.4, 0.7, 0.25},
    pond   = {0.2, 0.45, 0.75},
}

local SPECIES = {
    {name="Deer",  color={0.6,0.4,0.15}, size=6, speed=60, skittish=120, rarity=1},
    {name="Fox",   color={0.9,0.45,0.1}, size=5, speed=80, skittish=100, rarity=2},
    {name="Hare",  color={0.75,0.7,0.55},size=4, speed=100,skittish=90,  rarity=1},
    {name="Owl",   color={0.5,0.4,0.3},  size=5, speed=30, skittish=60,  rarity=3},
    {name="Frog",  color={0.2,0.7,0.2},  size=3, speed=20, skittish=50,  rarity=2},
    {name="Eagle", color={0.35,0.25,0.15},size=6, speed=70, skittish=80,  rarity=4},
    {name="Badger",color={0.3,0.3,0.3},  size=5, speed=40, skittish=70,  rarity=3},
}

local function gen_biome_map()
    biomes = {}
    for y = 1, MAP_H / TILE do
        biomes[y] = {}
        for x = 1, MAP_W / TILE do
            local r = math.random()
            if r < 0.12 then biomes[y][x] = "pond"
            elseif r < 0.45 then biomes[y][x] = "forest"
            else biomes[y][x] = "meadow" end
        end
    end
end

local function spawn_animal()
    local sp = SPECIES[math.random(1, #SPECIES)]
    return {
        species = sp,
        x = math.random(30, MAP_W - 30),
        y = math.random(30, MAP_H - 30),
        vx = 0, vy = 0,
        state = "graze", -- graze, flee, sleep
        state_timer = math.random() * 5 + 2,
        discovered = false,
    }
end

function lurek.init()
    gen_biome_map()
    player = {x = MAP_W / 2, y = MAP_H / 2, crouching = false}
    camera_mode = false
    noise_level = 0
    animals = {}
    for i = 1, 25 do animals[i] = spawn_animal() end
    photos = {}
    encyclopedia = {}
    best_score = 0
    day_timer = 0
    day_length = 120
    visibility = 1
    message = nil
    msg_timer = 0
end

local function show_msg(t) message = t; msg_timer = 2.5 end

local function dist(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx*dx + dy*dy)
end

function lurek.process(dt)
    if msg_timer > 0 then msg_timer = msg_timer - dt end

    -- day cycle
    day_timer = day_timer + dt
    local phase = (day_timer % day_length) / day_length
    if phase < 0.3 then visibility = 1
    elseif phase < 0.4 then visibility = lerp(1, 0.35, (phase - 0.3) / 0.1)
    elseif phase < 0.8 then visibility = 0.35
    else visibility = lerp(0.35, 1, (phase - 0.8) / 0.2) end

    -- movement
    local speed = 120
    local moving = false
    if player.crouching then speed = 50 end

    if lurek.keyboard.isDown("w") or lurek.keyboard.isDown("up") then
        player.y = player.y - speed * dt; moving = true end
    if lurek.keyboard.isDown("s") or lurek.keyboard.isDown("down") then
        player.y = player.y + speed * dt; moving = true end
    if lurek.keyboard.isDown("a") or lurek.keyboard.isDown("left") then
        player.x = player.x - speed * dt; moving = true end
    if lurek.keyboard.isDown("d") or lurek.keyboard.isDown("right") then
        player.x = player.x + speed * dt; moving = true end

    player.x = clamp(player.x, 10, MAP_W - 10)
    player.y = clamp(player.y, 10, MAP_H - 10)

    -- noise
    if moving then
        noise_level = player.crouching and 20 or 60
    else
        noise_level = clamp(noise_level - 40 * dt, 0, 100)
    end

    -- animal AI
    for _, a in ipairs(animals) do
        local d = dist(player.x, player.y, a.x, a.y)
        a.state_timer = a.state_timer - dt

        if a.state == "graze" then
            if d < a.species.skittish and noise_level > 30 then
                a.state = "flee"; a.state_timer = 2
                local dx = a.x - player.x
                local dy = a.y - player.y
                local len = math.sqrt(dx*dx + dy*dy)
                if len > 0 then
                    a.vx = (dx / len) * a.species.speed
                    a.vy = (dy / len) * a.species.speed
                end
            elseif a.state_timer <= 0 then
                a.vx = (math.random() - 0.5) * a.species.speed * 0.3
                a.vy = (math.random() - 0.5) * a.species.speed * 0.3
                a.state_timer = math.random() * 4 + 2
                if math.random() < 0.1 and visibility < 0.5 then
                    a.state = "sleep"; a.state_timer = math.random() * 6 + 3
                    a.vx = 0; a.vy = 0
                end
            end
        elseif a.state == "flee" then
            if a.state_timer <= 0 or d > a.species.skittish * 2 then
                a.state = "graze"; a.state_timer = math.random() * 3 + 1
                a.vx = 0; a.vy = 0
            end
        elseif a.state == "sleep" then
            a.vx = 0; a.vy = 0
            if a.state_timer <= 0 then a.state = "graze"; a.state_timer = 3 end
        end

        a.x = clamp(a.x + a.vx * dt, 10, MAP_W - 10)
        a.y = clamp(a.y + a.vy * dt, 10, MAP_H - 10)
    end

    -- respawn
    if #animals < 20 and math.random() < 0.01 then
        animals[#animals+1] = spawn_animal()
    end
end

local function take_photo()
    local mx, my = lurek.mouse.getPosition()
    -- convert screen to world
    local wx = mx + (player.x - W / 2)
    local wy = my + (player.y - H / 2)

    local best_animal = nil
    local best_d = 999
    for _, a in ipairs(animals) do
        local d = dist(wx, wy, a.x, a.y)
        if d < 40 and d < best_d then best_d = d; best_animal = a end
    end

    if not best_animal then show_msg("Nothing in frame!"); return end

    local d = dist(player.x, player.y, best_animal.x, best_animal.y)
    local dist_score = clamp(150 - d, 10, 100)
    local center_bonus = clamp(40 - best_d, 0, 30)
    local behavior_bonus = 0
    if best_animal.state == "sleep" then behavior_bonus = 25
    elseif best_animal.state == "flee" then behavior_bonus = 15 end
    local rarity_bonus = best_animal.species.rarity * 10
    local total = math.floor(dist_score + center_bonus + behavior_bonus + rarity_bonus)

    photos[#photos+1] = {species=best_animal.species.name, score=total}
    if total > best_score then best_score = total end

    -- encyclopedia
    if not encyclopedia[best_animal.species.name] then
        encyclopedia[best_animal.species.name] = true
        best_animal.discovered = true
        show_msg("NEW DISCOVERY: " .. best_animal.species.name .. "! Score: " .. total)
    else
        show_msg(best_animal.species.name .. " — Score: " .. total)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    if key == "c" then camera_mode = not camera_mode end
    if key == "space" and camera_mode then take_photo() end
    if key == "lshift" or key == "rshift" then player.crouching = not player.crouching end
end

function lurek.render()
    -- camera offset
    local ox = player.x - W / 2
    local oy = player.y - H / 2

    -- draw biome tiles
    local sx = clamp(math.floor(ox / TILE), 0, MAP_W / TILE - 1)
    local sy = clamp(math.floor(oy / TILE), 0, MAP_H / TILE - 1)
    local ex = clamp(sx + COLS + 2, 1, MAP_W / TILE)
    local ey = clamp(sy + ROWS + 2, 1, MAP_H / TILE)

    for y = sy + 1, ey do
        for x = sx + 1, ex do
            if biomes[y] and biomes[y][x] then
                local c = BIOME_COLORS[biomes[y][x]]
                lurek.gfx.setColor(c[1]*visibility, c[2]*visibility, c[3]*visibility, 1)
                lurek.gfx.rectangle("fill", (x-1)*TILE - ox, (y-1)*TILE - oy, TILE, TILE)
            end
        end
    end

    -- animals
    for _, a in ipairs(animals) do
        local ax = a.x - ox
        local ay = a.y - oy
        if ax > -20 and ax < W + 20 and ay > -20 and ay < H + 20 then
            local c = a.species.color
            local alpha = 1
            if a.state == "sleep" then alpha = 0.6 end
            lurek.gfx.setColor(c[1]*visibility, c[2]*visibility, c[3]*visibility, alpha)
            lurek.gfx.circle("fill", ax, ay, a.species.size)
            -- state indicator
            if a.state == "sleep" then
                lurek.gfx.setColor(1,1,1,0.5*visibility)
                lurek.gfx.print("z", ax+6, ay-10, 0.7)
            elseif a.state == "flee" then
                lurek.gfx.setColor(1,0.3,0.3,0.7)
                lurek.gfx.print("!", ax+6, ay-10, 0.7)
            end
        end
    end

    -- player
    local px, py = W / 2, H / 2
    local pr = player.crouching and 5 or 7
    lurek.gfx.setColor(0.9, 0.85, 0.3, 1)
    lurek.gfx.circle("fill", px, py, pr)
    lurek.gfx.setColor(0.2, 0.2, 0.2, 1)
    lurek.gfx.circle("line", px, py, pr)

    -- camera mode crosshair
    if camera_mode then
        local mx, my = lurek.mouse.getPosition()
        lurek.gfx.setColor(1, 1, 1, 0.8)
        lurek.gfx.line(mx - 15, my, mx + 15, my)
        lurek.gfx.line(mx, my - 15, mx, my + 15)
        lurek.gfx.circle("line", mx, my, 25)
        lurek.gfx.setColor(1,0.3,0.3,0.6)
        lurek.gfx.print("CAMERA", mx + 20, my - 8, 0.8)
    end

    -- night overlay
    if visibility < 0.9 then
        lurek.gfx.setColor(0, 0, 0.05, 1 - visibility)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
    end

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.6)
    lurek.gfx.rectangle("fill", 0, 0, W, 28)
    lurek.gfx.setColor(1,1,1,1)
    local discovered = 0
    for _ in pairs(encyclopedia) do discovered = discovered + 1 end
    lurek.gfx.print("Photos: " .. #photos .. "  Best: " .. best_score
        .. "  Species: " .. discovered .. "/" .. #SPECIES, 10, 5, 0.9)
    lurek.gfx.print(camera_mode and "[CAMERA ON]" or "[C] Camera", 500, 5, 0.9)
    lurek.gfx.print(player.crouching and "Crouching" or "Standing", 630, 5, 0.9)
    lurek.gfx.print("FPS: " .. lurek.time.getFPS(), 740, 5, 0.7)

    -- noise meter
    lurek.gfx.setColor(0.3,0.3,0.3,0.7)
    lurek.gfx.rectangle("fill", 10, H-22, 80, 12)
    local np = noise_level / 100
    lurek.gfx.setColor(np, 1-np, 0, 0.8)
    lurek.gfx.rectangle("fill", 10, H-22, 80*np, 12)
    lurek.gfx.setColor(1,1,1,0.7)
    lurek.gfx.print("Noise", 14, H-24, 0.7)

    -- photo log (last 5)
    if #photos > 0 then
        lurek.gfx.setColor(0,0,0,0.5)
        lurek.gfx.rectangle("fill", W-160, H-110, 155, 105)
        lurek.gfx.setColor(1,1,1,0.9)
        lurek.gfx.print("Recent Photos:", W-155, H-108, 0.7)
        local start = clamp(#photos - 4, 1, #photos)
        for i = start, #photos do
            local p = photos[i]
            local yi = (i - start) * 16 + (H - 92)
            lurek.gfx.print(p.species .. ": " .. p.score .. "pts", W-150, yi, 0.7)
        end
    end

    -- message
    if message and msg_timer > 0 then
        lurek.gfx.setColor(1,1,0.4,1)
        lurek.gfx.print(message, 200, 50, 1.1)
    end

    lurek.gfx.setColor(0.6,0.6,0.6,0.7)
    lurek.gfx.print("[WASD] Move  [Shift] Crouch  [C] Camera  [Space] Photo  [R] Restart", 100, H-14, 0.65)
end
