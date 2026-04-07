-- Hotel Manager — Skyscraper Management Sim
-- Build floors, place rooms, earn revenue from guests

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local hotel = {}
local guests = {}
local money = 5000
local day = 1
local dayTimer = 0
local DAY_LENGTH = 15 -- seconds per day
local satisfaction = 80
local dailyRevenue = 0
local dailyExpense = 0
local scrollY = 0
local message = ""
local messageTimer = 0

local FLOOR_H = 40
local ROOM_W = 60
local LOBBY_Y = 500
local ELEVATOR_X = 380
local MAX_FLOORS = 20
local ROOMS_PER_FLOOR = 6

local roomTypes = {
    { name = "Empty",      color = {0.3, 0.3, 0.3}, revenue = 0,   cost = 0,   icon = "" },
    { name = "Single",     color = {0.2, 0.5, 0.8}, revenue = 50,  cost = 200,  icon = "S" },
    { name = "Suite",      color = {0.7, 0.3, 0.8}, revenue = 150, cost = 600,  icon = "X" },
    { name = "Restaurant", color = {0.8, 0.5, 0.2}, revenue = 200, cost = 800,  icon = "R" },
    { name = "Office",     color = {0.3, 0.7, 0.3}, revenue = 100, cost = 400,  icon = "O" },
}

local selectedType = 2
local occupancy = {}

local function floorCost(n)
    return 500 + (n - 1) * 300
end

local function addFloor()
    local n = #hotel + 1
    if n > MAX_FLOORS then
        message = "Max floors reached!"
        messageTimer = 2
        return
    end
    local cost = floorCost(n)
    if money < cost then
        message = "Need $" .. cost .. " to build floor " .. n
        messageTimer = 2
        return
    end
    money = money - cost
    local floor = {}
    for i = 1, ROOMS_PER_FLOOR do
        floor[i] = 1 -- empty
    end
    hotel[n] = floor
    occupancy[n] = {}
    for i = 1, ROOMS_PER_FLOOR do occupancy[n][i] = false end
    message = "Built floor " .. n .. " (-$" .. cost .. ")"
    messageTimer = 2
end

local function getFloorY(floorIdx)
    return LOBBY_Y - floorIdx * FLOOR_H + scrollY
end

local function getRoomX(roomIdx)
    local startX = 40
    if roomIdx <= 3 then
        return startX + (roomIdx - 1) * ROOM_W
    else
        return ELEVATOR_X + 40 + (roomIdx - 4) * ROOM_W
    end
end

local function calcSatisfaction()
    local total = 0
    local count = 0
    for fi = 1, #hotel do
        for ri = 1, ROOMS_PER_FLOOR do
            if hotel[fi][ri] > 1 and occupancy[fi][ri] then
                -- Restaurant noise and elevator wait both penalise satisfaction
                -- This incentivises keeping restaurants away from rooms and building elevators
                local noise = 0
                for rj = 1, ROOMS_PER_FLOOR do
                    if hotel[fi][rj] == 4 then noise = noise + 10 end -- restaurant noise
                end
                local elevatorWait = fi * 2  -- higher floors = longer wait
                local roomSat = 100 - noise - elevatorWait
                if roomSat < 0 then roomSat = 0 end
                total = total + roomSat
                count = count + 1
            end
        end
    end
    if count > 0 then satisfaction = math.floor(total / count) end
end

local function processDay()
    dailyRevenue = 0
    dailyExpense = 0
    -- Maintenance
    for fi = 1, #hotel do
        dailyExpense = dailyExpense + 20 + fi * 5
    end
    -- Revenue from occupied rooms
    for fi = 1, #hotel do
        for ri = 1, ROOMS_PER_FLOOR do
            local rt = hotel[fi][ri]
            if rt > 1 then
                if occupancy[fi][ri] then
                    dailyRevenue = dailyRevenue + roomTypes[rt].revenue
                end
                -- Stochastic guest turnover each day: 30% chance of state flip,
                -- plus an extra check that fills empty rooms when satisfaction is high
                if math.random() < 0.3 then
                    occupancy[fi][ri] = not occupancy[fi][ri]
                elseif not occupancy[fi][ri] and satisfaction > 40 and math.random() < 0.5 then
                    occupancy[fi][ri] = true
                end
            end
        end
    end
    money = money + dailyRevenue - dailyExpense
    calcSatisfaction()
    day = day + 1
end

local function getOccupancyRate()
    local total = 0
    local occ = 0
    for fi = 1, #hotel do
        for ri = 1, ROOMS_PER_FLOOR do
            if hotel[fi][ri] > 1 then
                total = total + 1
                if occupancy[fi][ri] then occ = occ + 1 end
            end
        end
    end
    if total == 0 then return 0 end
    return math.floor(occ / total * 100)
end

function luna.load()
    -- Start with 3 floors
    for i = 1, 3 do
        hotel[i] = {}
        occupancy[i] = {}
        for r = 1, ROOMS_PER_FLOOR do
            hotel[i][r] = 1
            occupancy[i][r] = false
        end
    end
end

function luna.update(dt)
    dayTimer = dayTimer + dt
    if dayTimer >= DAY_LENGTH then
        dayTimer = dayTimer - DAY_LENGTH
        processDay()
    end
    if messageTimer > 0 then messageTimer = messageTimer - dt end

    -- Scroll
    if luna.keyboard.isDown("up") then scrollY = scrollY + 200 * dt end
    if luna.keyboard.isDown("down") then scrollY = scrollY - 200 * dt end
    local maxScroll = #hotel * FLOOR_H
    scrollY = clamp(scrollY, 0, maxScroll)
end

function luna.keypressed(key)
    if key == "b" then addFloor() end
    if key == "1" then selectedType = 2 end
    if key == "2" then selectedType = 3 end
    if key == "3" then selectedType = 4 end
    if key == "4" then selectedType = 5 end
    if key == "escape" then luna.event.quit() end
end

function luna.mousepressed(mx, my, btn)
    if btn ~= 1 then return end
    for fi = 1, #hotel do
        local fy = getFloorY(fi)
        for ri = 1, ROOMS_PER_FLOOR do
            local rx = getRoomX(ri)
            if mx >= rx and mx < rx + ROOM_W - 2 and my >= fy and my < fy + FLOOR_H - 2 then
                if hotel[fi][ri] == 1 then
                    local cost = roomTypes[selectedType].cost
                    if money >= cost then
                        money = money - cost
                        hotel[fi][ri] = selectedType
                        message = "Placed " .. roomTypes[selectedType].name .. " (-$" .. cost .. ")"
                        messageTimer = 2
                    else
                        message = "Need $" .. cost
                        messageTimer = 2
                    end
                elseif hotel[fi][ri] == selectedType then
                    -- Remove room (no refund)
                    hotel[fi][ri] = 1
                    occupancy[fi][ri] = false
                    message = "Removed room"
                    messageTimer = 2
                end
                return
            end
        end
    end
end

function luna.draw()
    luna.graphics.setBackgroundColor(0.1, 0.12, 0.18)

    -- Draw ground
    luna.graphics.setColor(0.3, 0.25, 0.2, 1)
    luna.graphics.rectangle("fill", 0, LOBBY_Y + scrollY, 800, 200)

    -- Draw elevator shaft
    luna.graphics.setColor(0.15, 0.15, 0.2, 1)
    luna.graphics.rectangle("fill", ELEVATOR_X, LOBBY_Y - #hotel * FLOOR_H + scrollY, 40, #hotel * FLOOR_H)

    -- Draw floors
    for fi = 1, #hotel do
        local fy = getFloorY(fi)
        -- Floor platform
        luna.graphics.setColor(0.25, 0.25, 0.3, 1)
        luna.graphics.rectangle("fill", 30, fy + FLOOR_H - 4, 740, 4)

        -- Floor number
        luna.graphics.setColor(0.5, 0.5, 0.6, 1)
        luna.graphics.print(tostring(fi), 10, fy + 12)

        -- Rooms
        for ri = 1, ROOMS_PER_FLOOR do
            local rx = getRoomX(ri)
            local rt = hotel[fi][ri]
            local c = roomTypes[rt].color
            luna.graphics.setColor(c[1], c[2], c[3], 1)
            luna.graphics.rectangle("fill", rx, fy + 2, ROOM_W - 4, FLOOR_H - 6)

            if rt > 1 then
                -- Occupancy indicator
                if occupancy[fi][ri] then
                    luna.graphics.setColor(0, 1, 0, 0.6)
                    luna.graphics.circle("fill", rx + ROOM_W - 12, fy + 10, 4)
                else
                    luna.graphics.setColor(0.5, 0.5, 0.5, 0.6)
                    luna.graphics.circle("fill", rx + ROOM_W - 12, fy + 10, 4)
                end
                luna.graphics.setColor(1, 1, 1, 0.8)
                luna.graphics.print(roomTypes[rt].icon, rx + 4, fy + 10)
            end
        end
    end

    -- Elevator car (animated)
    local elevFloor = math.floor(luna.timer.getTime() * 0.5 % clamp(#hotel, 1, 20)) + 1
    if elevFloor <= #hotel then
        local ey = getFloorY(elevFloor)
        luna.graphics.setColor(0.8, 0.8, 0.2, 1)
        luna.graphics.rectangle("fill", ELEVATOR_X + 5, ey + 5, 30, FLOOR_H - 12)
    end

    -- HUD background
    luna.graphics.setColor(0, 0, 0, 0.8)
    luna.graphics.rectangle("fill", 0, 0, 800, 60)

    -- Stats
    luna.graphics.setColor(0.2, 1, 0.3, 1)
    luna.graphics.print("$" .. money, 10, 8, 1.2)
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Day " .. day, 140, 10)
    luna.graphics.print("Rev: $" .. dailyRevenue .. "/day", 240, 10)
    luna.graphics.print("Exp: $" .. dailyExpense .. "/day", 420, 10)
    luna.graphics.print("Occ: " .. getOccupancyRate() .. "%", 600, 10)

    local satColor = satisfaction > 60 and {0.2, 1, 0.3} or (satisfaction > 30 and {1, 0.8, 0.2} or {1, 0.2, 0.2})
    luna.graphics.setColor(satColor[1], satColor[2], satColor[3], 1)
    luna.graphics.print("Satisfaction: " .. satisfaction .. "%", 600, 30)

    -- Day progress bar
    luna.graphics.setColor(0.3, 0.3, 0.4, 1)
    luna.graphics.rectangle("fill", 140, 30, 200, 10)
    luna.graphics.setColor(1, 0.8, 0.2, 1)
    luna.graphics.rectangle("fill", 140, 30, 200 * (dayTimer / DAY_LENGTH), 10)

    -- Build controls
    luna.graphics.setColor(0, 0, 0, 0.7)
    luna.graphics.rectangle("fill", 0, 565, 800, 35)
    luna.graphics.setColor(0.8, 0.8, 0.8, 1)
    luna.graphics.print("[B] Build floor ($" .. floorCost(#hotel + 1) .. ")", 10, 572)
    for i = 2, 5 do
        local sel = (selectedType == i) and "> " or "  "
        local c = roomTypes[i].color
        luna.graphics.setColor(c[1], c[2], c[3], 1)
        luna.graphics.print(sel .. "[" .. (i - 1) .. "] " .. roomTypes[i].name .. " $" .. roomTypes[i].cost, 200 + (i - 2) * 150, 572)
    end

    -- Message
    if messageTimer > 0 then
        luna.graphics.setColor(1, 1, 0.5, messageTimer)
        luna.graphics.print(message, 300, 45)
    end
end
