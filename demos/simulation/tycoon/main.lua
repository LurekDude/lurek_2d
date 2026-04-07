-- Tycoon — Luna2D Demo
-- Build a restaurant, serve customers, earn profit

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local TILE = 40
local COLS, ROWS = 15, 12
local grid = {}
local money = 500
local day, dayTimer, dayLength = 1, 0, 45
local customersServed, totalRevenue = 0, 0
local satisfaction = 80
local buildMode = false
local buildType = 1
local buildings = {
    { name = "Counter", cost = 30,  color = { 0.7, 0.5, 0.2 }, key = "counter" },
    { name = "Table",   cost = 50,  color = { 0.5, 0.35, 0.2 }, key = "table" },
    { name = "Kitchen", cost = 100, color = { 0.6, 0.2, 0.2 }, key = "kitchen" },
}
local staff = { cooks = 0, waiters = 0 }
local staffCost = { cook = 20, waiter = 15 }
local customers = {}
local spawnCD = 0
local hasCounter, hasKitchen, hasTable = false, false, false

local function initGrid()
    for y = 1, ROWS do
        grid[y] = {}
        for x = 1, COLS do
            grid[y][x] = "floor"
        end
    end
    -- walls
    for x = 1, COLS do grid[1][x] = "wall"; grid[ROWS][x] = "wall" end
    for y = 1, ROWS do grid[y][1] = "wall"; grid[y][COLS] = "wall" end
    -- entrance
    grid[ROWS][math.floor(COLS / 2)] = "door"
end

local function countType(t)
    local n = 0
    for y = 1, ROWS do for x = 1, COLS do
        if grid[y][x] == t then n = n + 1 end
    end end
    return n
end

local function findTile(t)
    for y = 2, ROWS - 1 do for x = 2, COLS - 1 do
        if grid[y][x] == t then return x, y end
    end end
    return nil, nil
end

local function spawnCustomer()
    local dx = math.floor(COLS / 2)
    table.insert(customers, { x = dx * TILE, y = (ROWS - 1) * TILE, state = "enter", wait = 0, served = false, patience = 12 + math.random(0, 8) })
end

function luna.init()
    luna.window.setTitle("Restaurant Tycoon")
    luna.gfx.setBackgroundColor(0.12, 0.1, 0.08)
    initGrid()
end

function luna.process(dt)
    dayTimer = dayTimer + dt

    -- update facilities flags
    hasCounter = countType("counter") > 0
    hasKitchen = countType("kitchen") > 0
    hasTable = countType("table") > 0

    -- day end
    if dayTimer >= dayLength then
        dayTimer = 0
        day = day + 1
        money = money - staff.cooks * staffCost.cook - staff.waiters * staffCost.waiter
    end

    -- spawn customers
    if hasCounter and hasKitchen then
        spawnCD = spawnCD - dt
        if spawnCD <= 0 and #customers < 6 then
            spawnCustomer()
            spawnCD = 3 + math.random() * 4
        end
    end

    -- customer logic
    for i = #customers, 1, -1 do
        local c = customers[i]
        if c.state == "enter" then
            -- walk toward counter
            local cx, cy = findTile("counter")
            if cx and cy then
                local tx, ty = cx * TILE, cy * TILE
                if math.abs(c.x - tx) > 3 then
                    c.x = c.x + (tx > c.x and 80 or -80) * dt
                elseif math.abs(c.y - ty) > 3 then
                    c.y = c.y + (ty > c.y and 80 or -80) * dt
                else
                    c.state = "order"
                    c.wait = 0
                end
            end
        elseif c.state == "order" then
            local cookSpeed = 1 + staff.cooks * 0.8
            c.wait = c.wait + dt * cookSpeed
            if c.wait >= 4 then
                c.state = "eat"
                c.wait = 0
            end
            c.patience = c.patience - dt
        elseif c.state == "eat" then
            if hasTable then
                local tx, ty = findTile("table")
                if tx and ty then
                    local tpx, tpy = tx * TILE, ty * TILE
                    if math.abs(c.x - tpx) > 3 or math.abs(c.y - tpy) > 3 then
                        c.x = c.x + (tpx > c.x and 60 or -60) * dt
                        c.y = c.y + (tpy > c.y and 60 or -60) * dt
                    else
                        c.wait = c.wait + dt
                        if c.wait >= 3 then c.state = "leave"; c.served = true end
                    end
                else
                    c.state = "leave"
                    c.served = true
                end
            else
                c.wait = c.wait + dt
                if c.wait >= 2 then c.state = "leave"; c.served = true end
            end
        elseif c.state == "leave" then
            c.y = c.y + 100 * dt
            if c.y > ROWS * TILE + 40 then
                if c.served then
                    local rev = 25 + (hasTable and 10 or 0) + staff.waiters * 5
                    money = money + rev
                    totalRevenue = totalRevenue + rev
                    customersServed = customersServed + 1
                    satisfaction = clamp(satisfaction + 2, 0, 100)
                else
                    satisfaction = clamp(satisfaction - 5, 0, 100)
                end
                table.remove(customers, i)
            end
        end

        -- patience timeout
        if c.patience and c.patience <= 0 and c.state ~= "leave" then
            c.state = "leave"
            c.served = false
        end
    end
end

function luna.render()
    -- grid
    for y = 1, ROWS do
        for x = 1, COLS do
            local t = grid[y][x]
            if t == "wall" then
                luna.gfx.setColor(0.3, 0.25, 0.2, 1)
            elseif t == "door" then
                luna.gfx.setColor(0.5, 0.4, 0.15, 1)
            elseif t == "counter" then
                luna.gfx.setColor(0.7, 0.5, 0.2, 1)
            elseif t == "table" then
                luna.gfx.setColor(0.5, 0.35, 0.2, 1)
            elseif t == "kitchen" then
                luna.gfx.setColor(0.6, 0.2, 0.2, 1)
            else
                luna.gfx.setColor(0.2, 0.18, 0.15, 1)
            end
            luna.gfx.rectangle("fill", (x - 1) * TILE, (y - 1) * TILE, TILE - 1, TILE - 1)
        end
    end

    -- customers
    for _, c in ipairs(customers) do
        if c.state == "order" then
            luna.gfx.setColor(1, 0.8, 0.2, 1)
        elseif c.state == "eat" then
            luna.gfx.setColor(0.3, 0.9, 0.3, 1)
        else
            luna.gfx.setColor(0.3, 0.6, 1, 1)
        end
        luna.gfx.circle("fill", c.x, c.y, 10)
    end

    -- build cursor
    if buildMode then
        local mx, my = luna.mouse.getPosition()
        local gx = math.floor(mx / TILE) + 1
        local gy = math.floor(my / TILE) + 1
        if gx >= 2 and gx <= COLS - 1 and gy >= 2 and gy <= ROWS - 1 then
            local b = buildings[buildType]
            luna.gfx.setColor(b.color[1], b.color[2], b.color[3], 0.4)
            luna.gfx.rectangle("fill", (gx - 1) * TILE, (gy - 1) * TILE, TILE - 1, TILE - 1)
        end
    end

    -- RIGHT PANEL
    local px = COLS * TILE + 10
    luna.gfx.setColor(0, 0, 0, 0.5)
    luna.gfx.rectangle("fill", COLS * TILE, 0, 200, ROWS * TILE)

    luna.gfx.setColor(1, 0.85, 0.2, 1)
    luna.gfx.print("$" .. money, px, 10, 1.3)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("Day " .. day, px, 40)
    luna.gfx.print("Served: " .. customersServed, px, 60)
    luna.gfx.print("Satisfaction: " .. math.floor(satisfaction) .. "%", px, 80)
    luna.gfx.print("Cooks: " .. staff.cooks .. " ($" .. staffCost.cook .. "/d)", px, 110)
    luna.gfx.print("Waiters: " .. staff.waiters .. " ($" .. staffCost.waiter .. "/d)", px, 130)

    -- build panel
    luna.gfx.setColor(0.6, 0.8, 1, 1)
    luna.gfx.print("BUILD (B toggle):", px, 170)
    for i, b in ipairs(buildings) do
        local sel = (buildMode and i == buildType) and "> " or "  "
        luna.gfx.setColor(1, 1, 1, 1)
        luna.gfx.print(sel .. i .. ") " .. b.name .. " $" .. b.cost, px, 190 + i * 18)
    end

    luna.gfx.setColor(0.7, 0.7, 0.7, 1)
    luna.gfx.print("H=Hire Cook", px, 280)
    luna.gfx.print("J=Hire Waiter", px, 298)
    luna.gfx.print("Day: " .. math.floor(dayTimer) .. "/" .. dayLength, px, 330)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), px, 360)
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "b" then buildMode = not buildMode end
    if buildMode then
        if key == "1" then buildType = 1 end
        if key == "2" then buildType = 2 end
        if key == "3" then buildType = 3 end
    end
    if key == "h" then
        local cost = staffCost.cook * 3
        if money >= cost then money = money - cost; staff.cooks = staff.cooks + 1 end
    end
    if key == "j" then
        local cost = staffCost.waiter * 3
        if money >= cost then money = money - cost; staff.waiters = staff.waiters + 1 end
    end
end

function luna.mousepressed(x, y, button)
    if not buildMode then return end
    local gx = math.floor(x / TILE) + 1
    local gy = math.floor(y / TILE) + 1
    if gx < 2 or gx > COLS - 1 or gy < 2 or gy > ROWS - 1 then return end
    if grid[gy][gx] ~= "floor" then return end
    local b = buildings[buildType]
    if money >= b.cost then
        money = money - b.cost
        grid[gy][gx] = b.key
    end
end
