-- System Infiltration / Gadget Puzzle Demo
-- Navigate rooms, avoid cameras, use gadgets, hack terminals, steal data

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local W, H = 800, 600
local TILE = 40
local COLS = 20
local ROWS = 15

-- Map: 0=wall, 1=floor, 2=door_keycard, 3=door_hack, 4=door_mechanical, 5=terminal, 6=vault, 7=exit
local map = {}
local player = {x = 0, y = 0, speed = 130}
local cameras = {}
local gadgets = {keycard = 3, emp = 2, lockpick = 3}
local alertLevel = 0
local maxAlert = 100
local gameState = "playing" -- playing, hacking, won, caught
local hasData = false
local missionTimer = 180
local hackState = nil -- {wires={}, solved=false, target=""}
local message = ""
local msgTimer = 0
local disabledCams = {}

local LEVEL = {
    "11111111111111111111",
    "10001000100050001001",
    "10101010101010101001",
    "10100210001000400001",
    "10111110111111101111",
    "10000010100000100001",
    "11110310101110101101",
    "10000010100010100101",
    "10111110111010111101",
    "10100000001010000001",
    "10101111101510111101",
    "10001000101000400001",
    "11101011101111101111",
    "17001000000000006001",
    "11111111111111111111",
}

local DOOR_NAMES = {[2] = "Keycard", [3] = "Hack", [4] = "Mechanical"}
local DOOR_COLORS = {[2] = {0.2, 0.5, 1}, [3] = {0.2, 0.8, 0.2}, [4] = {0.7, 0.5, 0.2}}

local function initMap()
    for r = 1, ROWS do
        map[r] = {}
        local row = LEVEL[r]
        for c = 1, COLS do
            map[r][c] = tonumber(row:sub(c, c)) or 0
        end
    end
end

local function showMsg(text)
    message = text
    msgTimer = 2.5
end

local function addCamera(x, y, startAngle, sweepRange, speed)
    table.insert(cameras, {
        x = x, y = y,
        angle = startAngle, startAngle = startAngle,
        sweepRange = sweepRange or 1.5,
        speed = speed or 0.8,
        range = 120, coneWidth = 0.5,
        timer = 0, dir = 1,
    })
end

local function isWall(gx, gy)
    local c = math.floor(gx / TILE) + 1
    local r = math.floor(gy / TILE) + 1
    if r < 1 or r > ROWS or c < 1 or c > COLS then return true end
    local v = map[r][c]
    return v == 0 or v == 2 or v == 3 or v == 4
end

local function isCamDisabled(idx)
    return disabledCams[idx] and disabledCams[idx] > 0
end

local function startHack(doorR, doorC)
    -- Wire matching mini-puzzle: player must click wire IDs in the order given by a shuffled target array
    -- Shuffle target order
    local wires = {}
    local order = {1, 2, 3, 4}
    -- Shuffle target order
    for i = 4, 2, -1 do
        local j = math.random(1, i)
        order[i], order[j] = order[j], order[i]
    end
    for i = 1, 4 do
        wires[i] = {id = i, target = order[i], connected = false}
    end
    hackState = {wires = wires, nextWire = 1, doorR = doorR, doorC = doorC, timer = 15}
    gameState = "hacking"
end

function luna.load()
    luna.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    initMap()
    player.x = 1.5 * TILE
    player.y = 13.5 * TILE

    -- Place cameras
    addCamera(5.5 * TILE, 2.5 * TILE, 0, 2.0, 0.6)
    addCamera(15.5 * TILE, 5.5 * TILE, 3.14, 1.8, 0.7)
    addCamera(10.5 * TILE, 8.5 * TILE, 1.57, 2.2, 0.5)
    addCamera(18.5 * TILE, 11.5 * TILE, 3.14, 1.5, 0.9)
end

function luna.update(dt)
    if gameState == "won" or gameState == "caught" then return end

    missionTimer = missionTimer - dt
    if missionTimer <= 0 then
        gameState = "caught"
        showMsg("Time's up! Mission failed.")
        return
    end

    if msgTimer > 0 then msgTimer = msgTimer - dt end

    -- Disabled camera timers
    for k, v in pairs(disabledCams) do
        disabledCams[k] = v - dt
        if disabledCams[k] <= 0 then disabledCams[k] = nil end
    end

    if gameState == "hacking" then
        hackState.timer = hackState.timer - dt
        if hackState.timer <= 0 then
            gameState = "playing"
            alertLevel = clamp(alertLevel + 20, 0, maxAlert)
            showMsg("Hack failed! Alert +20")
        end
        return
    end

    -- Player movement
    local dx, dy = 0, 0
    if luna.keyboard.isDown("w") or luna.keyboard.isDown("up") then dy = -1 end
    if luna.keyboard.isDown("s") or luna.keyboard.isDown("down") then dy = 1 end
    if luna.keyboard.isDown("a") or luna.keyboard.isDown("left") then dx = -1 end
    if luna.keyboard.isDown("d") or luna.keyboard.isDown("right") then dx = 1 end
    if dx ~= 0 and dy ~= 0 then dx = dx * 0.707; dy = dy * 0.707 end

    local nx = player.x + dx * player.speed * dt
    local ny = player.y + dy * player.speed * dt
    local r = 8
    if not isWall(nx - r, player.y) and not isWall(nx + r, player.y) then player.x = nx end
    if not isWall(player.x, ny - r) and not isWall(player.x, ny + r) then player.y = ny end

    -- Camera sweep and detection
    -- Each camera oscillates its angle via a timer and checks if the player falls inside the cone
    for i, cam in ipairs(cameras) do
        if not isCamDisabled(i) then
            cam.timer = cam.timer + dt * cam.speed
            cam.angle = cam.startAngle + math.sin(cam.timer) * cam.sweepRange

            -- Detection
            local cdx = player.x - cam.x
            local cdy = player.y - cam.y
            local dist = math.sqrt(cdx * cdx + cdy * cdy)
            if dist < cam.range then
                local angle = math.atan2(cdy, cdx)
                local diff = angle - cam.angle
                while diff > 3.14159 do diff = diff - 6.28318 end
                while diff < -3.14159 do diff = diff + 6.28318 end
                if math.abs(diff) < cam.coneWidth then
                    alertLevel = clamp(alertLevel + dt * 30, 0, maxAlert)
                end
            end
        end
    end

    -- Alert decay
    if alertLevel > 0 then
        alertLevel = clamp(alertLevel - dt * 2, 0, maxAlert)
    end
    if alertLevel >= maxAlert then
        gameState = "caught"
    end

    -- Check vault
    local pc = math.floor(player.x / TILE) + 1
    local pr = math.floor(player.y / TILE) + 1
    if pr >= 1 and pr <= ROWS and pc >= 1 and pc <= COLS then
        if map[pr][pc] == 6 and not hasData then
            hasData = true
            showMsg("Downloaded secret data!")
        end
        if map[pr][pc] == 7 and hasData then
            gameState = "won"
        end
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end

    if gameState == "hacking" then
        -- Wire matching: press 1-4 to connect next wire to that target
        local n = tonumber(key)
        if n and n >= 1 and n <= 4 and hackState then
            local wire = hackState.wires[hackState.nextWire]
            if wire then
                if n == wire.target then
                    wire.connected = true
                    hackState.nextWire = hackState.nextWire + 1
                    if hackState.nextWire > 4 then
                        -- Hack success
                        map[hackState.doorR][hackState.doorC] = 1
                        gameState = "playing"
                        showMsg("Door hacked!")
                    end
                else
                    alertLevel = clamp(alertLevel + 10, 0, maxAlert)
                    showMsg("Wrong wire! Alert +10")
                end
            end
        end
        if key == "q" then
            gameState = "playing"
        end
        return
    end

    -- Interact with adjacent doors/terminals
    if key == "e" or key == "space" then
        local dirs = {{0, -1}, {0, 1}, {-1, 0}, {1, 0}}
        local pc = math.floor(player.x / TILE) + 1
        local pr = math.floor(player.y / TILE) + 1
        for _, d in ipairs(dirs) do
            local tc = pc + d[1]
            local tr = pr + d[2]
            if tr >= 1 and tr <= ROWS and tc >= 1 and tc <= COLS then
                local v = map[tr][tc]
                if v == 2 then -- keycard door
                    if gadgets.keycard > 0 then
                        gadgets.keycard = gadgets.keycard - 1
                        map[tr][tc] = 1
                        showMsg("Keycard used. (" .. gadgets.keycard .. " left)")
                    else
                        showMsg("No keycards left!")
                    end
                    return
                elseif v == 3 then -- hack door
                    startHack(tr, tc)
                    return
                elseif v == 4 then -- mechanical door
                    if gadgets.lockpick > 0 then
                        gadgets.lockpick = gadgets.lockpick - 1
                        map[tr][tc] = 1
                        showMsg("Lockpicked! (" .. gadgets.lockpick .. " left)")
                    else
                        showMsg("No lockpicks left!")
                    end
                    return
                elseif v == 5 then -- terminal
                    showMsg("Terminal accessed: security logs cleared. Alert -20")
                    alertLevel = clamp(alertLevel - 20, 0, maxAlert)
                    map[tr][tc] = 1
                    return
                end
            end
        end
    end

    -- EMP gadget
    if key == "q" and gadgets.emp > 0 then
        gadgets.emp = gadgets.emp - 1
        for i, cam in ipairs(cameras) do
            local dist = math.sqrt((player.x - cam.x)^2 + (player.y - cam.y)^2)
            if dist < 200 then
                disabledCams[i] = 15
            end
        end
        showMsg("EMP deployed! Nearby cameras disabled. (" .. gadgets.emp .. " left)")
    end

    if key == "r" and (gameState == "won" or gameState == "caught") then
        gameState = "playing"
        hasData = false
        alertLevel = 0
        missionTimer = 180
        gadgets = {keycard = 3, emp = 2, lockpick = 3}
        disabledCams = {}
        initMap()
        player.x = 1.5 * TILE
        player.y = 13.5 * TILE
    end
end

function luna.draw()
    -- Draw map
    for r = 1, ROWS do
        for c = 1, COLS do
            local x, y = (c - 1) * TILE, (r - 1) * TILE
            local v = map[r][c]
            if v == 0 then
                luna.graphics.setColor(0.12, 0.12, 0.18, 1)
                luna.graphics.rectangle("fill", x, y, TILE, TILE)
            elseif v == 1 then
                luna.graphics.setColor(0.2, 0.2, 0.25, 1)
                luna.graphics.rectangle("fill", x, y, TILE, TILE)
            elseif v >= 2 and v <= 4 then
                local clr = DOOR_COLORS[v]
                luna.graphics.setColor(clr[1], clr[2], clr[3], 1)
                luna.graphics.rectangle("fill", x, y, TILE, TILE)
                luna.graphics.setColor(1, 1, 1, 0.7)
                luna.graphics.print(DOOR_NAMES[v], x + 2, y + 12, 0.5)
            elseif v == 5 then
                luna.graphics.setColor(0.2, 0.2, 0.25, 1)
                luna.graphics.rectangle("fill", x, y, TILE, TILE)
                luna.graphics.setColor(0, 0.8, 0, 1)
                luna.graphics.print(">_", x + 8, y + 10, 1)
            elseif v == 6 then
                luna.graphics.setColor(0.6, 0.5, 0.1, 1)
                luna.graphics.rectangle("fill", x, y, TILE, TILE)
                luna.graphics.setColor(1, 1, 1, 1)
                luna.graphics.print("VAULT", x + 2, y + 12, 0.5)
            elseif v == 7 then
                luna.graphics.setColor(0.1, 0.5, 0.1, 1)
                luna.graphics.rectangle("fill", x, y, TILE, TILE)
                luna.graphics.setColor(1, 1, 1, 1)
                luna.graphics.print("EXIT", x + 4, y + 12, 0.55)
            end
        end
    end

    -- Grid lines
    luna.graphics.setColor(0.15, 0.15, 0.2, 0.5)
    for r = 0, ROWS do
        luna.graphics.line(0, r * TILE, COLS * TILE, r * TILE)
    end
    for c = 0, COLS do
        luna.graphics.line(c * TILE, 0, c * TILE, ROWS * TILE)
    end

    -- Cameras
    for i, cam in ipairs(cameras) do
        local disabled = isCamDisabled(i)
        if disabled then
            luna.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        else
            luna.graphics.setColor(1, 0, 0, 0.2)
            -- Vision cone
            local cx1 = cam.x + math.cos(cam.angle - cam.coneWidth) * cam.range
            local cy1 = cam.y + math.sin(cam.angle - cam.coneWidth) * cam.range
            local cx2 = cam.x + math.cos(cam.angle + cam.coneWidth) * cam.range
            local cy2 = cam.y + math.sin(cam.angle + cam.coneWidth) * cam.range
            luna.graphics.polygon("fill", {cam.x, cam.y, cx1, cy1, cx2, cy2})
        end
        luna.graphics.setColor(disabled and 0.4 or 1, 0, 0, 1)
        luna.graphics.circle("fill", cam.x, cam.y, 6)
    end

    -- Player
    luna.graphics.setColor(0, 0.8, 1, 1)
    luna.graphics.circle("fill", player.x, player.y, 10)
    luna.graphics.setColor(0, 0.5, 0.8, 1)
    luna.graphics.circle("line", player.x, player.y, 12)

    -- HUD
    luna.graphics.setColor(0, 0, 0, 0.8)
    luna.graphics.rectangle("fill", 0, 0, W, 35)
    -- Alert bar
    luna.graphics.setColor(0.3, 0.3, 0.3, 1)
    luna.graphics.rectangle("fill", 10, 5, 150, 12)
    local alertPct = alertLevel / maxAlert
    local ar = lerp(0.2, 1, alertPct)
    luna.graphics.setColor(ar, 0.1, 0.1, 1)
    luna.graphics.rectangle("fill", 10, 5, alertPct * 150, 12)
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Alert", 165, 3, 0.75)
    -- Timer
    local mins = math.floor(missionTimer / 60)
    local secs = math.floor(missionTimer % 60)
    local timeStr = mins .. ":" .. (secs < 10 and "0" or "") .. secs
    luna.graphics.setColor(missionTimer < 30 and 1 or 0.8, missionTimer < 30 and 0.3 or 0.8, missionTimer < 30 and 0.3 or 0.8, 1)
    luna.graphics.print("Time: " .. timeStr, 220, 5, 0.9)
    -- Gadgets
    luna.graphics.setColor(0.7, 0.7, 0.7, 1)
    luna.graphics.print("Keycards:" .. gadgets.keycard .. " EMP(Q):" .. gadgets.emp .. " Picks:" .. gadgets.lockpick, 350, 5, 0.75)
    -- Data
    luna.graphics.setColor(hasData and 0 or 0.5, hasData and 1 or 0.5, hasData and 0 or 0.5, 1)
    luna.graphics.print(hasData and "DATA ACQUIRED" or "No Data", 650, 5, 0.8)

    -- Bottom HUD
    luna.graphics.setColor(0, 0, 0, 0.7)
    luna.graphics.rectangle("fill", 0, H - 25, W, 25)
    luna.graphics.setColor(0.6, 0.6, 0.6, 1)
    luna.graphics.print("WASD move | E interact with doors/terminals | Q EMP | Get to vault, steal data, reach exit", 10, H - 22, 0.7)

    -- Hack overlay
    if gameState == "hacking" and hackState then
        luna.graphics.setColor(0, 0, 0, 0.9)
        luna.graphics.rectangle("fill", W / 2 - 200, H / 2 - 120, 400, 240)
        luna.graphics.setColor(0, 1, 0, 1)
        luna.graphics.print("HACK TERMINAL", W / 2 - 70, H / 2 - 110, 1)
        luna.graphics.print("Match wires: press 1-4 in correct order", W / 2 - 150, H / 2 - 85, 0.75)
        luna.graphics.print("Time: " .. math.floor(hackState.timer) .. "s | Q to cancel", W / 2 - 100, H / 2 - 65, 0.7)

        local wireColors = {{1, 0, 0}, {0, 1, 0}, {0, 0.5, 1}, {1, 1, 0}}
        for i = 1, 4 do
            local wire = hackState.wires[i]
            local wx = W / 2 - 150
            local wy = H / 2 - 30 + (i - 1) * 40
            -- Left side (source)
            local c = wireColors[wire.id]
            luna.graphics.setColor(c[1], c[2], c[3], 1)
            luna.graphics.circle("fill", wx, wy, 10)
            luna.graphics.print("Wire " .. wire.id, wx + 15, wy - 7, 0.7)
            -- Right side (target)
            local tc = wireColors[wire.target]
            luna.graphics.setColor(tc[1], tc[2], tc[3], 1)
            luna.graphics.circle("fill", wx + 280, wy, 10)
            luna.graphics.print("Port " .. wire.target, wx + 220, wy - 7, 0.7)

            if wire.connected then
                luna.graphics.setColor(0, 1, 0, 0.8)
                luna.graphics.line(wx + 10, wy, wx + 270, wy)
            end
            if i == hackState.nextWire then
                luna.graphics.setColor(1, 1, 1, 0.5 + math.sin(luna.timer.getTime() * 6) * 0.5)
                luna.graphics.circle("line", wx, wy, 14)
            end
        end
    end

    -- Message
    if msgTimer > 0 then
        luna.graphics.setColor(0, 1, 0.5, clamp(msgTimer, 0, 1))
        luna.graphics.print(message, W / 2 - 120, H / 2 + 80, 1)
    end

    -- Game over / win
    if gameState == "caught" then
        luna.graphics.setColor(0.5, 0, 0, 0.85)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("MISSION FAILED", W / 2 - 100, H / 2 - 20, 1.5)
        luna.graphics.print("Press R to retry", W / 2 - 60, H / 2 + 20, 0.9)
    elseif gameState == "won" then
        luna.graphics.setColor(0, 0.2, 0.1, 0.85)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(0, 1, 0.5, 1)
        luna.graphics.print("MISSION COMPLETE", W / 2 - 110, H / 2 - 20, 1.5)
        luna.graphics.print("Press R to replay", W / 2 - 65, H / 2 + 20, 0.9)
    end
end
