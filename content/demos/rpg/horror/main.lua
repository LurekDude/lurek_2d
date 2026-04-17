-- Atmospheric / Psychological Horror Demo
-- Dark environment, flashlight, sanity meter, find keys and escape
-- Run with: cargo run -- content/demos/rpg/horror

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600
local TILE = 40
local COLS = 20
local ROWS = 15

-- Map: 0=wall, 1=floor, 2=recharge station, 3=exit
local map = {}
local player = {x = 0, y = 0, speed = 120, angle = 0}
local flashlight = {on = true, battery = 100, maxBattery = 100, cone = 0.6, range = 200}
local sanity = {value = 100, max = 100}
local keys = {}
local keysFound = 0
local KEYS_NEEDED = 5
local notes = {}
local noteDisplay = nil
local noteTimer = 0
local enemy = {x = 0, y = 0, speed = 50, angle = 0, patrolIdx = 1}
local patrolPoints = {}
local events = {}
local eventTimer = 0
local footsteps = {}
local gameState = "playing" -- playing, won, dead
local screenShake = 0
local distortion = 0

-- Level layout (hand-designed)
local LEVEL = {
    "11111111111111111111",
    "10001000100010001001",
    "10101010101010101001",
    "10100010001000100001",
    "10111110111111101111",
    "10000010100000100001",
    "11110010101110101101",
    "10000010100010100101",
    "10111110111010111101",
    "10100000001010000001",
    "10101111101010111101",
    "10001000101000100001",
    "11101011101111101111",
    "12001000000000003001",
    "11111111111111111111",
}

local function initMap()
    for r = 1, ROWS do
        map[r] = {}
        local row = LEVEL[r]
        for c = 1, COLS do
            local ch = row:sub(c, c)
            map[r][c] = tonumber(ch) or 0
        end
    end
end

local function isWall(gx, gy)
    local c = math.floor(gx / TILE) + 1
    local r = math.floor(gy / TILE) + 1
    if r < 1 or r > ROWS or c < 1 or c > COLS then return true end
    return map[r][c] == 0
end

local function placeKeys()
    local spots = {}
    for r = 2, ROWS - 1 do
        for c = 2, COLS - 1 do
            if map[r][c] == 1 then
                table.insert(spots, {x = (c - 0.5) * TILE, y = (r - 0.5) * TILE})
            end
        end
    end
    -- Shuffle and pick
    for i = #spots, 2, -1 do
        local j = math.random(1, i)
        spots[i], spots[j] = spots[j], spots[i]
    end
    keys = {}
    for i = 1, clamp(KEYS_NEEDED, 1, #spots) do
        table.insert(keys, {x = spots[i].x, y = spots[i].y, found = false})
    end
    -- Place notes
    notes = {}
    for i = KEYS_NEEDED + 1, clamp(KEYS_NEEDED + 3, 1, #spots) do
        local texts = {
            "I can hear them in the walls...",
            "Don't look back. Never look back.",
            "The exit needs five keys. I only found three before...",
        }
        table.insert(notes, {x = spots[i].x, y = spots[i].y, text = texts[#notes + 1] or "...", read = false})
    end
    -- Patrol points for enemy
    patrolPoints = {}
    for i = KEYS_NEEDED + 4, clamp(KEYS_NEEDED + 8, 1, #spots) do
        table.insert(patrolPoints, {x = spots[i].x, y = spots[i].y})
    end
    if #patrolPoints < 2 then
        patrolPoints = {{x = 200, y = 200}, {x = 600, y = 400}}
    end
end

function lurek.init()
    lurek.render.setBackgroundColor(0, 0, 0)
    initMap()
    -- Player start
    player.x = 1.5 * TILE
    player.y = 1.5 * TILE
    -- Enemy start
    enemy.x = patrolPoints[1] and patrolPoints[1].x or 400
    enemy.y = patrolPoints[1] and patrolPoints[1].y or 300
    placeKeys()
end

function lurek.process(dt)
    if gameState ~= "playing" then return end

    -- Player movement
    local dx, dy = 0, 0
    if lurek.keyboard.isDown("w") or lurek.keyboard.isDown("up") then dy = -1 end
    if lurek.keyboard.isDown("s") or lurek.keyboard.isDown("down") then dy = 1 end
    if lurek.keyboard.isDown("a") or lurek.keyboard.isDown("left") then dx = -1 end
    if lurek.keyboard.isDown("d") or lurek.keyboard.isDown("right") then dx = 1 end
    if dx ~= 0 and dy ~= 0 then dx = dx * 0.707; dy = dy * 0.707 end

    -- Resolve movement per-axis so the player slides along walls instead of getting stuck
    local nx = player.x + dx * player.speed * dt
    local ny = player.y + dy * player.speed * dt
    local r = 10
    if not isWall(nx - r, player.y) and not isWall(nx + r, player.y) then player.x = nx end
    if not isWall(player.x, ny - r) and not isWall(player.x, ny + r) then player.y = ny end

    -- Flashlight direction follows mouse
    local mx, my = lurek.mouse.getPosition()
    player.angle = math.atan2(my - player.y, mx - player.x)

    -- Battery
    if flashlight.on then
        flashlight.battery = flashlight.battery - dt * 5
        if flashlight.battery <= 0 then
            flashlight.battery = 0
            flashlight.on = false
        end
    end

    -- Recharge station
    local pc = math.floor(player.x / TILE) + 1
    local pr = math.floor(player.y / TILE) + 1
    if pr >= 1 and pr <= ROWS and pc >= 1 and pc <= COLS and map[pr][pc] == 2 then
        flashlight.battery = clamp(flashlight.battery + dt * 30, 0, flashlight.maxBattery)
    end

    -- Sanity/light coupling: darkness drains sanity, light slowly restores it
    -- This creates a risk/reward loop around battery management
    local inLight = flashlight.on and flashlight.battery > 0
    if not inLight then
        sanity.value = sanity.value - dt * 3
    else
        sanity.value = clamp(sanity.value + dt * 1, 0, sanity.max)
    end
    distortion = 1 - sanity.value / sanity.max

    if sanity.value <= 0 then
        gameState = "dead"
    end

    -- Footstep particles
    if dx ~= 0 or dy ~= 0 then
        table.insert(footsteps, {x = player.x, y = player.y, life = 1.5, maxLife = 1.5})
    end
    for i = #footsteps, 1, -1 do
        footsteps[i].life = footsteps[i].life - dt
        if footsteps[i].life <= 0 then table.remove(footsteps, i) end
    end

    -- Key pickup
    for _, k in ipairs(keys) do
        if not k.found then
            local d = math.sqrt((player.x - k.x)^2 + (player.y - k.y)^2)
            if d < 20 then
                k.found = true
                keysFound = keysFound + 1
                sanity.value = clamp(sanity.value - 10, 0, sanity.max)
                screenShake = 0.3
            end
        end
    end

    -- Note pickup
    for _, n in ipairs(notes) do
        if not n.read then
            local d = math.sqrt((player.x - n.x)^2 + (player.y - n.y)^2)
            if d < 20 then
                n.read = true
                noteDisplay = n.text
                noteTimer = 4
                sanity.value = clamp(sanity.value - 5, 0, sanity.max)
            end
        end
    end
    if noteTimer > 0 then noteTimer = noteTimer - dt end
    if noteTimer <= 0 then noteDisplay = nil end

    -- Exit check
    if map[pr] and map[pr][pc] == 3 and keysFound >= KEYS_NEEDED then
        gameState = "won"
    end

    -- Enemy patrol
    if #patrolPoints >= 2 then
        local target = patrolPoints[enemy.patrolIdx]
        local edx = target.x - enemy.x
        local edy = target.y - enemy.y
        local dist = math.sqrt(edx * edx + edy * edy)
        if dist > 5 then
            enemy.x = enemy.x + (edx / dist) * enemy.speed * dt
            enemy.y = enemy.y + (edy / dist) * enemy.speed * dt
            enemy.angle = math.atan2(edy, edx)
        else
            enemy.patrolIdx = (enemy.patrolIdx % #patrolPoints) + 1
        end
    end

    -- Enemy detection
    local eDist = math.sqrt((player.x - enemy.x)^2 + (player.y - enemy.y)^2)
    if eDist < 40 then
        gameState = "dead"
    elseif eDist < 120 then
        sanity.value = sanity.value - dt * 8
        screenShake = 0.1
    end

    -- Screen shake decay
    if screenShake > 0 then screenShake = screenShake - dt end

    -- Random scare events
    eventTimer = eventTimer + dt
    if eventTimer > 8 + math.random() * 10 then
        eventTimer = 0
        sanity.value = clamp(sanity.value - 5, 0, sanity.max)
        screenShake = 0.2
        table.insert(events, {
            x = player.x + math.random(-150, 150),
            y = player.y + math.random(-150, 150),
            life = 1.5,
        })
    end
    for i = #events, 1, -1 do
        events[i].life = events[i].life - dt
        if events[i].life <= 0 then table.remove(events, i) end
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "f" then flashlight.on = not flashlight.on end
    if key == "r" and gameState ~= "playing" then
        gameState = "playing"
        sanity.value = 100
        flashlight.battery = 100
        flashlight.on = true
        keysFound = 0
        player.x = 1.5 * TILE
        player.y = 1.5 * TILE
        placeKeys()
        events = {}
        footsteps = {}
    end
end

local function isInFlashlight(px, py)
    if not flashlight.on or flashlight.battery <= 0 then return false end
    local dx = px - player.x
    local dy = py - player.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > flashlight.range then return false end
    local angle = math.atan2(dy, dx)
    local diff = angle - player.angle
    -- Normalize
    while diff > 3.14159 do diff = diff - 6.28318 end
    while diff < -3.14159 do diff = diff + 6.28318 end
    return math.abs(diff) < flashlight.cone
end

local function visibility(px, py)
    local dx = px - player.x
    local dy = py - player.y
    local dist = math.sqrt(dx * dx + dy * dy)
    -- Base ambient (very dark)
    local ambient = 0.03
    -- Near player glow
    local nearGlow = clamp(1 - dist / 60, 0, 0.3)
    -- Flashlight
    local fl = 0
    if isInFlashlight(px, py) then
        fl = clamp(1 - dist / flashlight.range, 0, 1) * (flashlight.battery / flashlight.maxBattery)
    end
    return clamp(ambient + nearGlow + fl, 0, 1)
end

function lurek.render()
    local shx = screenShake > 0 and math.random(-3, 3) or 0
    local shy = screenShake > 0 and math.random(-3, 3) or 0

    -- Draw map tiles
    for r = 1, ROWS do
        for c = 1, COLS do
            local x = (c - 1) * TILE + shx
            local y = (r - 1) * TILE + shy
            local cx = x + TILE / 2
            local cy = y + TILE / 2
            local vis = visibility(cx, cy)
            if map[r][c] == 0 then
                lurek.render.setColor(0.08 * vis, 0.08 * vis, 0.12 * vis, 1)
                lurek.render.rectangle("fill", x, y, TILE, TILE)
            elseif map[r][c] == 2 then
                lurek.render.setColor(0.1 * vis, 0.4 * vis, 0.5 * vis, 1)
                lurek.render.rectangle("fill", x, y, TILE, TILE)
            elseif map[r][c] == 3 then
                local g = keysFound >= KEYS_NEEDED and 0.8 or 0.3
                lurek.render.setColor(g * vis, 0.2 * vis, 0.2 * vis, 1)
                lurek.render.rectangle("fill", x, y, TILE, TILE)
            else
                lurek.render.setColor(0.25 * vis, 0.22 * vis, 0.2 * vis, 1)
                lurek.render.rectangle("fill", x, y, TILE, TILE)
            end
        end
    end

    -- Footstep ripples
    for _, f in ipairs(footsteps) do
        local a = f.life / f.maxLife * 0.3
        local r = (1 - f.life / f.maxLife) * 20
        lurek.render.setColor(0.5, 0.5, 0.5, a)
        lurek.render.circle("line", f.x + shx, f.y + shy, r)
    end

    -- Keys
    for _, k in ipairs(keys) do
        if not k.found then
            local vis = visibility(k.x, k.y)
            lurek.render.setColor(1 * vis, 0.9 * vis, 0.2 * vis, 1)
            lurek.render.circle("fill", k.x + shx, k.y + shy, 5)
        end
    end

    -- Notes
    for _, n in ipairs(notes) do
        if not n.read then
            local vis = visibility(n.x, n.y)
            lurek.render.setColor(0.9 * vis, 0.9 * vis, 0.8 * vis, 1)
            lurek.render.rectangle("fill", n.x - 5 + shx, n.y - 5 + shy, 10, 10)
        end
    end

    -- Scare events
    for _, ev in ipairs(events) do
        local vis = visibility(ev.x, ev.y)
        lurek.render.setColor(0.5 * vis, 0, 0, ev.life)
        lurek.render.circle("fill", ev.x + shx, ev.y + shy, 15)
    end

    -- Enemy
    local eVis = visibility(enemy.x, enemy.y)
    if eVis > 0.05 then
        lurek.render.setColor(0.8 * eVis, 0.1, 0.1, eVis)
        lurek.render.circle("fill", enemy.x + shx, enemy.y + shy, 12)
        -- Vision cone
        lurek.render.setColor(0.5, 0, 0, 0.15 * eVis)
        local ex1 = enemy.x + math.cos(enemy.angle - 0.4) * 60
        local ey1 = enemy.y + math.sin(enemy.angle - 0.4) * 60
        local ex2 = enemy.x + math.cos(enemy.angle + 0.4) * 60
        local ey2 = enemy.y + math.sin(enemy.angle + 0.4) * 60
        lurek.render.polygon("fill", {enemy.x + shx, enemy.y + shy, ex1 + shx, ey1 + shy, ex2 + shx, ey2 + shy})
    end

    -- Player
    lurek.render.setColor(0.9, 0.8, 0.6, 1)
    lurek.render.circle("fill", player.x + shx, player.y + shy, 8)

    -- Flashlight cone visualization
    if flashlight.on and flashlight.battery > 0 then
        local intensity = flashlight.battery / flashlight.maxBattery * 0.15
        local fx1 = player.x + math.cos(player.angle - flashlight.cone) * flashlight.range
        local fy1 = player.y + math.sin(player.angle - flashlight.cone) * flashlight.range
        local fx2 = player.x + math.cos(player.angle + flashlight.cone) * flashlight.range
        local fy2 = player.y + math.sin(player.angle + flashlight.cone) * flashlight.range
        lurek.render.setColor(1, 1, 0.8, intensity)
        lurek.render.polygon("fill", {player.x + shx, player.y + shy, fx1 + shx, fy1 + shy, fx2 + shx, fy2 + shy})
    end

    -- Distortion overlay (low sanity)
    if distortion > 0.3 then
        local a = (distortion - 0.3) * 0.5
        local r = 0.3 + math.sin(lurek.time.getTime() * 5) * 0.2
        lurek.render.setColor(r, 0, 0.1, a)
        lurek.render.rectangle("fill", 0, 0, W, H)
    end

    -- HUD
    lurek.render.setColor(0, 0, 0, 0.7)
    lurek.render.rectangle("fill", 0, 0, W, 30)
    -- Battery bar
    lurek.render.setColor(0.3, 0.3, 0.3, 1)
    lurek.render.rectangle("fill", 10, 5, 100, 12)
    local bc = flashlight.battery / flashlight.maxBattery
    lurek.render.setColor(bc, bc, 0.2, 1)
    lurek.render.rectangle("fill", 10, 5, bc * 100, 12)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Battery", 115, 4, 0.7)
    -- Sanity bar
    lurek.render.setColor(0.3, 0.3, 0.3, 1)
    lurek.render.rectangle("fill", 200, 5, 100, 12)
    local sc = sanity.value / sanity.max
    lurek.render.setColor(0.2, sc * 0.8, sc, 1)
    lurek.render.rectangle("fill", 200, 5, sc * 100, 12)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Sanity", 305, 4, 0.7)
    -- Keys
    lurek.render.setColor(1, 0.9, 0.2, 1)
    lurek.render.print("Keys: " .. keysFound .. "/" .. KEYS_NEEDED, 400, 5, 0.9)
    lurek.render.setColor(0.6, 0.6, 0.6, 1)
    lurek.render.print("WASD move | F flashlight | Find 5 keys, reach exit", 520, 6, 0.65)

    -- Note display
    if noteDisplay and noteTimer > 0 then
        lurek.render.setColor(0, 0, 0, 0.85)
        lurek.render.rectangle("fill", W / 2 - 200, H / 2 - 40, 400, 80)
        lurek.render.setColor(0.9, 0.85, 0.7, 1)
        lurek.render.print(noteDisplay, W / 2 - 180, H / 2 - 20, 0.9)
    end

    -- Game over / win
    if gameState == "dead" then
        lurek.render.setColor(0.5, 0, 0, 0.8)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("YOUR MIND IS LOST", W / 2 - 120, H / 2 - 20, 1.5)
        lurek.render.print("Press R to retry", W / 2 - 60, H / 2 + 20, 0.9)
    elseif gameState == "won" then
        lurek.render.setColor(0, 0.2, 0, 0.8)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("YOU ESCAPED!", W / 2 - 80, H / 2 - 20, 1.5)
        lurek.render.print("Press R to play again", W / 2 - 70, H / 2 + 20, 0.9)
    end
end
