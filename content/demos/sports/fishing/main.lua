-- Marine / Fishing Simulation Demo
-- Cast line, catch fish with tension mini-game, sell at end of day
-- Run with: cargo run -- content/demos/sports/fishing

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600
local WATER_Y = 250
local DOCK_Y = WATER_Y - 30

-- Player
local playerX = 400
local playerSpeed = 100
local castPower = 0
local casting = false
local lineX, lineY = 0, 0
local lineOut = false
local lineDepth = 0
local maxDepth = 300

-- Fishing state
local state = "idle" -- idle, casting, waiting, hooked, reeling
local tension = 50
local tensionMin = 20
local tensionMax = 80
local tensionSpeed = 0
local hookedFish = nil
local reelProgress = 0

-- Fish types
local FISH_TYPES = {
    {name = "Minnow",    size = "S", depthMin = 30,  depthMax = 100, speed = 80,  value = 5,  pull = 8,  bait = 1, color = {0.6, 0.7, 0.8}},
    {name = "Trout",     size = "M", depthMin = 60,  depthMax = 180, speed = 60,  value = 15, pull = 15, bait = 1, color = {0.4, 0.6, 0.3}},
    {name = "Bass",      size = "M", depthMin = 80,  depthMax = 200, speed = 50,  value = 20, pull = 20, bait = 2, color = {0.3, 0.5, 0.2}},
    {name = "Catfish",   size = "L", depthMin = 150, depthMax = 280, speed = 35,  value = 30, pull = 25, bait = 2, color = {0.5, 0.4, 0.3}},
    {name = "Pike",      size = "L", depthMin = 100, depthMax = 250, speed = 70,  value = 40, pull = 30, bait = 3, color = {0.3, 0.4, 0.2}},
    {name = "Sturgeon",  size = "L", depthMin = 200, depthMax = 300, speed = 25,  value = 60, pull = 35, bait = 3, color = {0.4, 0.4, 0.5}},
}

-- Bait
local BAITS = {
    {name = "Worm",   id = 1, color = {0.7, 0.4, 0.3}},
    {name = "Lure",   id = 2, color = {1, 0.5, 0}},
    {name = "Shrimp", id = 3, color = {1, 0.6, 0.5}},
}
local currentBait = 1

-- Fish in water (boids-like)
local fish = {}
local MAX_FISH = 20

-- Catch log
local catches = {}
local money = 0
local dayTimer = 120
local day = 1

-- Waves
local waveOffset = 0

local message = ""
local msgTimer = 0
local biteTimer = 0

local function showMsg(text)
    message = text
    msgTimer = 2
end

local function spawnFish()
    local ft = FISH_TYPES[math.random(1, #FISH_TYPES)]
    table.insert(fish, {
        type = ft,
        x = math.random(50, W - 50),
        y = WATER_Y + math.random(ft.depthMin, ft.depthMax),
        vx = (math.random() - 0.5) * ft.speed,
        vy = (math.random() - 0.5) * ft.speed * 0.3,
        size = ft.size == "S" and 6 or (ft.size == "M" and 10 or 14),
    })
end

function lurek.init()
    lurek.gfx.setBackgroundColor(0.4, 0.7, 1)
    for _ = 1, MAX_FISH do spawnFish() end
end

function lurek.process(dt)
    waveOffset = waveOffset + dt * 2

    if msgTimer > 0 then msgTimer = msgTimer - dt end

    -- Day timer
    dayTimer = dayTimer - dt
    if dayTimer <= 0 then
        -- End of day: sell fish
        local dayEarnings = 0
        for _, c in ipairs(catches) do
            dayEarnings = dayEarnings + c.value
        end
        money = money + dayEarnings
        showMsg("Day " .. day .. " over! Earned $" .. dayEarnings)
        catches = {}
        day = day + 1
        dayTimer = 120
    end

    -- Player movement
    if state == "idle" or state == "waiting" then
        if lurek.keyboard.isDown("left") or lurek.keyboard.isDown("a") then
            playerX = clamp(playerX - playerSpeed * dt, 50, W - 50)
        end
        if lurek.keyboard.isDown("right") or lurek.keyboard.isDown("d") then
            playerX = clamp(playerX + playerSpeed * dt, 50, W - 50)
        end
    end

    -- Casting power
    if casting then
        castPower = clamp(castPower + dt * 80, 0, 100)
    end

    -- Line sinking
    if state == "waiting" then
        lineDepth = clamp(lineDepth + dt * 40, 0, maxDepth)
        lineY = WATER_Y + lineDepth

        -- Fish attraction to lure
        biteTimer = biteTimer + dt
        for _, f in ipairs(fish) do
            local dist = math.sqrt((f.x - lineX)^2 + (f.y - lineY)^2)
            -- Depth-gated bite: fish only strike when bait type matches AND lure is in range
            if dist < 40 and f.type.bait == currentBait and biteTimer > 2 then
                -- Probabilistic bite per frame: dt * 0.5 ≈ ~50%/s chance once close
                if math.random() < dt * 0.5 then
                    -- Fish bites!
                    hookedFish = f
                    state = "hooked"
                    tension = 50
                    reelProgress = 0
                    showMsg(f.type.name .. " on the hook!")
                    break
                end
            end
        end
    end

    -- Reeling / tension
    if state == "hooked" and hookedFish then
        -- Fish pulls tension up in a sinusoidal pattern — heavier fish have higher pull values
        local pull = hookedFish.type.pull
        -- Oscillate tension speed between 0 and pull using a sine wave for realistic struggle
        tensionSpeed = pull * (math.sin(lurek.time.getTime() * 3) * 0.5 + 0.5)

        if lurek.keyboard.isDown("up") then
            tension = tension + dt * 40
            reelProgress = reelProgress + dt * 15
        end
        if lurek.keyboard.isDown("down") then
            tension = tension - dt * 30
        end
        tension = tension + tensionSpeed * dt
        tension = tension - dt * 5 -- natural decay

        tension = clamp(tension, 0, 100)

        -- Check snap / escape
        if tension > tensionMax then
            showMsg("Line snapped!")
            state = "idle"
            lineOut = false
            hookedFish = nil
        elseif tension < tensionMin then
            showMsg("Fish escaped!")
            state = "idle"
            lineOut = false
            hookedFish = nil
        end

        -- Catch success
        if reelProgress >= 100 then
            table.insert(catches, {name = hookedFish.type.name, value = hookedFish.type.value, size = hookedFish.type.size})
            showMsg("Caught " .. hookedFish.type.name .. "! ($" .. hookedFish.type.value .. ")")
            -- Remove from water, spawn replacement
            for i, f in ipairs(fish) do
                if f == hookedFish then table.remove(fish, i); break end
            end
            spawnFish()
            hookedFish = nil
            state = "idle"
            lineOut = false
        end
    end

    -- Fish movement (simple boids)
    for _, f in ipairs(fish) do
        -- Wander
        f.vx = f.vx + (math.random() - 0.5) * 20 * dt
        f.vy = f.vy + (math.random() - 0.5) * 10 * dt
        -- Clamp speed
        local spd = math.sqrt(f.vx * f.vx + f.vy * f.vy)
        if spd > f.type.speed then
            f.vx = f.vx / spd * f.type.speed
            f.vy = f.vy / spd * f.type.speed
        end
        -- Bounds
        if f.x < 30 then f.vx = math.abs(f.vx) end
        if f.x > W - 30 then f.vx = -math.abs(f.vx) end
        if f.y < WATER_Y + f.type.depthMin then f.vy = math.abs(f.vy) end
        if f.y > WATER_Y + f.type.depthMax then f.vy = -math.abs(f.vy) end

        -- Cohesion with nearby same-type fish
        for _, other in ipairs(fish) do
            if other ~= f and other.type == f.type then
                local dx = other.x - f.x
                local dy = other.y - f.y
                local d = math.sqrt(dx * dx + dy * dy)
                if d < 80 and d > 1 then
                    f.vx = f.vx + dx / d * 5 * dt
                    f.vy = f.vy + dy / d * 5 * dt
                end
                if d < 20 and d > 1 then
                    f.vx = f.vx - dx / d * 30 * dt
                    f.vy = f.vy - dy / d * 30 * dt
                end
            end
        end

        f.x = f.x + f.vx * dt
        f.y = f.y + f.vy * dt
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end

    if key == "space" and state == "idle" and not casting then
        casting = true
        castPower = 0
    elseif key == "space" and casting then
        casting = false
        -- Cast line
        lineX = playerX + (castPower / 100) * 200 - 100
        lineY = WATER_Y
        lineDepth = 0
        lineOut = true
        state = "waiting"
        biteTimer = 0
        showMsg("Cast! Power: " .. math.floor(castPower) .. "%")
    elseif key == "space" and state == "waiting" then
        -- Reel in empty
        state = "idle"
        lineOut = false
        showMsg("Reeled in.")
    end

    -- Bait selection
    if key == "1" then currentBait = 1 end
    if key == "2" then currentBait = 2 end
    if key == "3" then currentBait = 3 end
end

function lurek.render()
    -- Sky gradient (simple bands)
    lurek.gfx.setColor(0.3, 0.55, 0.9, 1)
    lurek.gfx.rectangle("fill", 0, 0, W, WATER_Y / 2)
    lurek.gfx.setColor(0.5, 0.7, 1, 1)
    lurek.gfx.rectangle("fill", 0, WATER_Y / 2, W, WATER_Y / 2)

    -- Sun
    lurek.gfx.setColor(1, 0.9, 0.3, 1)
    lurek.gfx.circle("fill", 650, 60, 35)

    -- Dock
    lurek.gfx.setColor(0.5, 0.35, 0.15, 1)
    lurek.gfx.rectangle("fill", playerX - 60, DOCK_Y, 120, 15)
    lurek.gfx.rectangle("fill", playerX - 40, DOCK_Y + 15, 8, 30)
    lurek.gfx.rectangle("fill", playerX + 32, DOCK_Y + 15, 8, 30)

    -- Player (stick figure on dock)
    lurek.gfx.setColor(0.9, 0.8, 0.6, 1)
    lurek.gfx.circle("fill", playerX, DOCK_Y - 20, 10)
    lurek.gfx.setColor(0.2, 0.3, 0.6, 1)
    lurek.gfx.rectangle("fill", playerX - 6, DOCK_Y - 10, 12, 20)

    -- Rod
    lurek.gfx.setColor(0.5, 0.3, 0.1, 1)
    lurek.gfx.setLineWidth(2)
    lurek.gfx.line(playerX + 5, DOCK_Y - 15, playerX + 30, DOCK_Y - 45)

    -- Fishing line
    if lineOut then
        lurek.gfx.setColor(0.8, 0.8, 0.8, 0.7)
        lurek.gfx.setLineWidth(1)
        lurek.gfx.line(playerX + 30, DOCK_Y - 45, lineX, lineY)
        -- Bobber
        lurek.gfx.setColor(1, 0.2, 0, 1)
        lurek.gfx.circle("fill", lineX, WATER_Y + math.sin(waveOffset + lineX * 0.1) * 3, 4)
    end

    -- Water surface with waves
    lurek.gfx.setColor(0.1, 0.3, 0.7, 0.9)
    lurek.gfx.rectangle("fill", 0, WATER_Y, W, H - WATER_Y)
    -- Wave lines
    lurek.gfx.setColor(0.2, 0.4, 0.8, 0.4)
    lurek.gfx.setLineWidth(1)
    for wy = WATER_Y, WATER_Y + 30, 8 do
        for wx = 0, W - 20, 20 do
            local yo = math.sin(waveOffset + wx * 0.08 + wy * 0.2) * 3
            lurek.gfx.line(wx, wy + yo, wx + 15, wy + yo + 1)
        end
    end

    -- Depth markers
    lurek.gfx.setColor(0.5, 0.6, 0.8, 0.3)
    for d = 50, maxDepth, 50 do
        local dy = WATER_Y + d
        if dy < H then
            lurek.gfx.line(0, dy, W, dy)
            lurek.gfx.print(d .. "m", 5, dy - 12, 0.6)
        end
    end

    -- Fish
    for _, f in ipairs(fish) do
        if f.y < H + 20 then
            local c = f.type.color
            local depth_fade = clamp(1 - (f.y - WATER_Y) / (maxDepth * 1.2), 0.2, 1)
            lurek.gfx.setColor(c[1] * depth_fade, c[2] * depth_fade, c[3] * depth_fade, 0.8)
            -- Fish body (triangle-ish)
            local dir = f.vx >= 0 and 1 or -1
            local s = f.size
            lurek.gfx.polygon("fill", {
                f.x + dir * s, f.y,
                f.x - dir * s, f.y - s * 0.5,
                f.x - dir * s, f.y + s * 0.5,
            })
            -- Tail
            lurek.gfx.polygon("fill", {
                f.x - dir * s, f.y,
                f.x - dir * (s + 4), f.y - s * 0.4,
                f.x - dir * (s + 4), f.y + s * 0.4,
            })
        end
    end

    -- Cast power bar
    if casting then
        lurek.gfx.setColor(0, 0, 0, 0.7)
        lurek.gfx.rectangle("fill", playerX - 25, DOCK_Y - 70, 50, 10)
        lurek.gfx.setColor(1, 1 - castPower / 100, 0, 1)
        lurek.gfx.rectangle("fill", playerX - 25, DOCK_Y - 70, castPower / 2, 10)
    end

    -- Tension meter (when hooked)
    if state == "hooked" then
        lurek.gfx.setColor(0, 0, 0, 0.8)
        lurek.gfx.rectangle("fill", W / 2 - 110, 50, 220, 70)
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.print("TENSION", W / 2 - 30, 55, 0.9)

        -- Tension bar
        lurek.gfx.setColor(0.3, 0.3, 0.3, 1)
        lurek.gfx.rectangle("fill", W / 2 - 95, 75, 190, 16)
        -- Sweet spot zone
        lurek.gfx.setColor(0, 0.6, 0, 0.4)
        local zoneX = W / 2 - 95 + tensionMin / 100 * 190
        local zoneW = (tensionMax - tensionMin) / 100 * 190
        lurek.gfx.rectangle("fill", zoneX, 75, zoneW, 16)
        -- Current tension
        local tColor = (tension > tensionMax or tension < tensionMin) and {1, 0, 0} or {0, 1, 0}
        lurek.gfx.setColor(tColor[1], tColor[2], tColor[3], 1)
        local tx = W / 2 - 95 + tension / 100 * 190
        lurek.gfx.rectangle("fill", tx - 3, 73, 6, 20)

        -- Reel progress
        lurek.gfx.setColor(0.3, 0.3, 0.3, 1)
        lurek.gfx.rectangle("fill", W / 2 - 95, 97, 190, 10)
        lurek.gfx.setColor(0, 0.7, 1, 1)
        lurek.gfx.rectangle("fill", W / 2 - 95, 97, reelProgress / 100 * 190, 10)
        lurek.gfx.setColor(1, 1, 1, 0.7)
        lurek.gfx.print("Up/Down keys", W / 2 - 45, 110, 0.6)
    end

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.75)
    lurek.gfx.rectangle("fill", 0, 0, W, 40)
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Day " .. day, 10, 5, 1)
    local mins = math.floor(dayTimer / 60)
    local secs = math.floor(dayTimer % 60)
    lurek.gfx.print("Time: " .. mins .. ":" .. (secs < 10 and "0" or "") .. secs, 80, 8, 0.8)
    lurek.gfx.print("Money: $" .. money, 200, 8, 0.8)

    -- Bait selector
    for i, b in ipairs(BAITS) do
        local sel = i == currentBait
        lurek.gfx.setColor(b.color[1], b.color[2], b.color[3], sel and 1 or 0.4)
        lurek.gfx.rectangle("fill", 320 + (i - 1) * 80, 5, 70, 20)
        lurek.gfx.setColor(1, 1, 1, sel and 1 or 0.5)
        lurek.gfx.print(i .. ":" .. b.name, 325 + (i - 1) * 80, 8, 0.7)
    end

    -- Catch log
    lurek.gfx.setColor(0.6, 0.6, 0.6, 1)
    lurek.gfx.print("Catches: " .. #catches, 600, 8, 0.75)
    if #catches > 0 then
        local logY = 45
        lurek.gfx.setColor(0, 0, 0, 0.5)
        local logH = clamp(#catches, 1, 8) * 14 + 5
        lurek.gfx.rectangle("fill", W - 160, logY, 155, logH)
        for i = clamp(#catches - 7, 1, #catches), #catches do
            local c = catches[i]
            lurek.gfx.setColor(0.8, 0.9, 1, 1)
            lurek.gfx.print(c.name .. " (" .. c.size .. ") $" .. c.value, W - 155, logY + (i - clamp(#catches - 7, 1, #catches)) * 14, 0.6)
        end
    end

    -- Bottom controls
    lurek.gfx.setColor(0, 0, 0, 0.6)
    lurek.gfx.rectangle("fill", 0, H - 22, W, 22)
    lurek.gfx.setColor(0.7, 0.7, 0.7, 1)
    lurek.gfx.print("A/D move | Space hold+release to cast | Up/Down reel tension | 1/2/3 bait", 10, H - 19, 0.7)

    -- Message
    if msgTimer > 0 then
        lurek.gfx.setColor(1, 1, 0.5, clamp(msgTimer, 0, 1))
        lurek.gfx.print(message, W / 2 - 80, H / 2 - 50, 1.1)
    end
end
