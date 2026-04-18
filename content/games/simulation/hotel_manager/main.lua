-- Hotel Manager — Lurek2D
-- Category: simulation
-- Side-view hotel management: build rooms, hire staff, reach 5 stars

------------------------------------------------------------
-- Constants
------------------------------------------------------------
local GRID_COLS    = 5
local GRID_ROWS    = 8
local ROOM_W       = 80
local ROOM_H       = 50
local GRID_X       = 160
local GRID_Y       = 60
local FLOOR_LABEL_W = 40

local ROOM_TYPES = {
    { name = "Standard", color = {0.3,0.78,0.35}, cost = 50,  income = 10 },
    { name = "Deluxe",   color = {0.3,0.5,0.9},   cost = 100, income = 20 },
    { name = "Suite",    color = {0.85,0.72,0.2},  cost = 200, income = 40 },
}

local GUEST_ARRIVE_INTERVAL = 15
local NIGHT_INTERVAL        = 20
local CLEAN_DURATION        = 3
local CLEAN_COST            = 5
local CLEANER_COST          = 20
local CLEANER_CAPACITY      = 5
local ELEVATOR_FEE          = 30
local DIRTY_THRESHOLD       = 2

local STATE_TITLE   = "TITLE"
local STATE_PLAYING = "PLAYING"
local STATE_VICTORY = "VICTORY"

------------------------------------------------------------
-- Game state
------------------------------------------------------------
local state       = STATE_TITLE
local gold        = 200
local displayGold = 200
local rating      = 3.0
local cleaners    = 0
local nightTimer  = 0
local guestTimer  = 0
local totalGuests = 0

local rooms    = {}   -- rooms[row][col] = { type, dirty, occupant, cleanTimer }
local guests   = {}   -- active guest list
local particles = {}
local tweens    = {}

local mode = nil  -- nil | "clean" | "upgrade" | "build1" | "build2" | "build3"

local highestFloor = 1
local hasElevator  = {}  -- hasElevator[floor] = true

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function gridToScreen(row, col)
    local x = GRID_X + (col - 1) * ROOM_W
    local y = GRID_Y + (GRID_ROWS - row) * ROOM_H
    return x, y
end

local function screenToGrid(mx, my)
    local col = math.floor((mx - GRID_X) / ROOM_W) + 1
    local row = GRID_ROWS - math.floor((my - GRID_Y) / ROOM_H)
    if col >= 1 and col <= GRID_COLS and row >= 1 and row <= GRID_ROWS then
        return row, col
    end
    return nil, nil
end

local function spawnParticle(x, y, r, g, b, count, spread)
    for _ = 1, (count or 8) do
        local s = spread or 30
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * s * 2,
            vy = (math.random() - 0.5) * s * 2 - 20,
            life = 0.6 + math.random() * 0.4,
            maxLife = 1.0,
            r = r, g = g, b = b,
            size = 3 + math.random() * 3,
        })
    end
end

local function addTween(target, field, from, to, duration)
    table.insert(tweens, {
        target = target, field = field,
        from = from, to = to,
        duration = duration, elapsed = 0,
    })
end

local function roomLabel(roomType)
    return ROOM_TYPES[roomType].name:sub(1, 1)
end

local function canBuildOnFloor(floor)
    if floor == 1 then return true end
    for c = 1, GRID_COLS do
        if rooms[floor - 1] and rooms[floor - 1][c] then return true end
    end
    return false
end

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
local camera
local fps = 0

lurek.init(function()
    lurek.window.setTitle("Hotel Manager — Lurek2D")
    lurek.render.setBackgroundColor(0.12, 0.1, 0.08)
    camera = lurek.camera.new()

    for row = 1, GRID_ROWS do
        rooms[row] = {}
    end
    -- Start with 3 standard rooms on floor 1
    for c = 1, 3 do
        rooms[1][c] = { type = 1, dirty = 0, occupant = nil, cleanTimer = 0 }
    end
    hasElevator[1] = true
end)

------------------------------------------------------------
-- Input bindings
------------------------------------------------------------
lurek.ready(function()
    lurek.input.bind("build_standard", "1")
    lurek.input.bind("build_deluxe",   "2")
    lurek.input.bind("build_suite",    "3")
    lurek.input.bind("clean",          "c")
    lurek.input.bind("hire",           "h")
    lurek.input.bind("upgrade",        "u")
    lurek.input.bind("select",         "mouse1")
    lurek.input.bind("quit",           "escape")
end)

------------------------------------------------------------
-- Update
------------------------------------------------------------
lurek.process(function(dt)
    fps = lurek.timer.getFPS()

    if state == STATE_TITLE then
        if lurek.input.isActionJustPressed("select") then
            state = STATE_PLAYING
        end
        return
    end

    if state == STATE_VICTORY then
        if lurek.input.isActionJustPressed("quit") then
            lurek.signal.quit()
        end
        return
    end

    if lurek.input.isActionJustPressed("quit") then
        lurek.signal.quit()
        return
    end

    -- Mode selection
    if lurek.input.isActionJustPressed("build_standard") then mode = "build1" end
    if lurek.input.isActionJustPressed("build_deluxe")   then mode = "build2" end
    if lurek.input.isActionJustPressed("build_suite")    then mode = "build3" end
    if lurek.input.isActionJustPressed("clean")          then mode = "clean" end
    if lurek.input.isActionJustPressed("upgrade")        then mode = "upgrade" end

    -- Hire cleaner
    if lurek.input.isActionJustPressed("hire") and gold >= CLEANER_COST then
        gold = gold - CLEANER_COST
        cleaners = cleaners + 1
    end

    -- Click handling
    if lurek.input.isActionJustPressed("select") then
        local mx, my = lurek.input.getMousePosition()
        local row, col = screenToGrid(mx, my)
        if row and col then
            if mode and mode:sub(1, 5) == "build" then
                local typeIdx = tonumber(mode:sub(6))
                if typeIdx and not rooms[row][col] and canBuildOnFloor(row) then
                    local info = ROOM_TYPES[typeIdx]
                    local totalCost = info.cost
                    if row > highestFloor then
                        totalCost = totalCost + ELEVATOR_FEE
                    end
                    if gold >= totalCost then
                        gold = gold - totalCost
                        rooms[row][col] = { type = typeIdx, dirty = 0, occupant = nil, cleanTimer = 0 }
                        if row > highestFloor then
                            highestFloor = row
                            hasElevator[row] = true
                        end
                        local sx, sy = gridToScreen(row, col)
                        spawnParticle(sx + ROOM_W / 2, sy + ROOM_H / 2,
                            info.color[1], info.color[2], info.color[3], 12, 40)
                    end
                end
                mode = nil

            elseif mode == "clean" then
                local room = rooms[row][col]
                if room and room.dirty >= DIRTY_THRESHOLD and not room.cleanTimer or
                   (room and room.cleanTimer and room.cleanTimer <= 0 and room.dirty >= DIRTY_THRESHOLD) then
                    if gold >= CLEAN_COST then
                        gold = gold - CLEAN_COST
                        room.cleanTimer = CLEAN_DURATION
                        local sx, sy = gridToScreen(row, col)
                        spawnParticle(sx + ROOM_W / 2, sy + ROOM_H / 2, 0.5, 0.8, 1.0, 10, 25)
                    end
                end
                mode = nil

            elseif mode == "upgrade" then
                local room = rooms[row][col]
                if room and room.type < 3 then
                    local nextType = room.type + 1
                    local upgradeCost = ROOM_TYPES[nextType].cost - ROOM_TYPES[room.type].cost
                    if gold >= upgradeCost then
                        gold = gold - upgradeCost
                        room.type = nextType
                        local sx, sy = gridToScreen(row, col)
                        local info = ROOM_TYPES[nextType]
                        spawnParticle(sx + ROOM_W / 2, sy + ROOM_H / 2,
                            info.color[1], info.color[2], info.color[3], 16, 50)
                    end
                end
                mode = nil
            else
                mode = nil
            end
        end
    end

    -- Cleaning timers
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            local room = rooms[r][c]
            if room and room.cleanTimer and room.cleanTimer > 0 then
                room.cleanTimer = room.cleanTimer - dt
                if room.cleanTimer <= 0 then
                    room.dirty = 0
                    room.cleanTimer = 0
                end
            end
        end
    end

    -- Auto-cleaners
    if cleaners > 0 then
        local dirtyRooms = {}
        for r = 1, GRID_ROWS do
            for c = 1, GRID_COLS do
                local room = rooms[r][c]
                if room and room.dirty >= DIRTY_THRESHOLD and (not room.cleanTimer or room.cleanTimer <= 0) then
                    table.insert(dirtyRooms, { r = r, c = c, room = room })
                end
            end
        end
        local capacity = cleaners * CLEANER_CAPACITY
        for i = 1, math.min(#dirtyRooms, capacity) do
            local d = dirtyRooms[i]
            d.room.cleanTimer = CLEAN_DURATION
            local sx, sy = gridToScreen(d.r, d.c)
            spawnParticle(sx + ROOM_W / 2, sy + ROOM_H / 2, 0.5, 0.8, 1.0, 6, 20)
        end
    end

    -- Guest arrival
    guestTimer = guestTimer + dt
    local arrivalRate = GUEST_ARRIVE_INTERVAL / math.max(rating / 3.0, 0.5)
    if guestTimer >= arrivalRate then
        guestTimer = guestTimer - arrivalRate
        local wantedType = math.random(1, 3)
        -- Find available room of wanted type
        local found = nil
        for r = 1, GRID_ROWS do
            for c = 1, GRID_COLS do
                local room = rooms[r][c]
                if room and room.type == wantedType and not room.occupant then
                    found = { r = r, c = c, room = room }
                    break
                end
            end
            if found then break end
        end
        if found then
            local guest = {
                row = found.r, col = found.c,
                staysLeft = 1 + math.random(0, 2),
                satisfaction = 1.0,
                walkX = 0, walkTarget = 1.0,
            }
            found.room.occupant = guest
            table.insert(guests, guest)
            totalGuests = totalGuests + 1
            local sx, sy = gridToScreen(found.r, found.c)
            spawnParticle(sx + ROOM_W / 2, sy + ROOM_H / 2, 1.0, 0.9, 0.3, 8, 35)
            addTween(guest, "walkX", 0, 1.0, 0.8)
        end
    end

    -- Night cycle — revenue
    nightTimer = nightTimer + dt
    if nightTimer >= NIGHT_INTERVAL then
        nightTimer = nightTimer - NIGHT_INTERVAL
        for r = 1, GRID_ROWS do
            for c = 1, GRID_COLS do
                local room = rooms[r][c]
                if room and room.occupant then
                    local income = ROOM_TYPES[room.type].income
                    gold = gold + income
                    room.occupant.staysLeft = room.occupant.staysLeft - 1
                    room.dirty = room.dirty + 1

                    -- Satisfaction based on cleanliness
                    if room.dirty < DIRTY_THRESHOLD then
                        room.occupant.satisfaction = math.min(room.occupant.satisfaction + 0.1, 1.0)
                        rating = math.min(rating + 0.1, 5.0)
                    else
                        room.occupant.satisfaction = math.max(room.occupant.satisfaction - 0.3, 0)
                        rating = math.max(rating - 0.2, 1.0)
                    end

                    -- Guest leaves
                    if room.occupant.staysLeft <= 0 then
                        if room.occupant.satisfaction < 0.3 then
                            rating = math.max(rating - 0.1, 1.0)
                        end
                        room.occupant = nil
                    end
                end
            end
        end
        -- Remove departed guests
        for i = #guests, 1, -1 do
            local g = guests[i]
            local room = rooms[g.row][g.col]
            if not room or not room.occupant or room.occupant ~= g then
                table.remove(guests, i)
            end
        end
        addTween({ ref = "displayGold" }, "value", displayGold, gold, 0.5)
    end

    -- Update tweens
    for i = #tweens, 1, -1 do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = math.min(tw.elapsed / tw.duration, 1.0)
        local eased = t * t * (3 - 2 * t)  -- smoothstep
        local val = tw.from + (tw.to - tw.from) * eased
        if tw.target.ref == "displayGold" then
            displayGold = val
        elseif tw.target and tw.field then
            tw.target[tw.field] = val
        end
        if t >= 1.0 then
            table.remove(tweens, i)
        end
    end

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 40 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end

    -- Victory check
    if rating >= 5.0 and gold >= 1000 then
        state = STATE_VICTORY
    end
end)

------------------------------------------------------------
-- Render — world
------------------------------------------------------------
lurek.render(function()
    if state == STATE_TITLE then return end

    camera:attach()

    -- Draw floor labels
    for r = 1, GRID_ROWS do
        local _, y = gridToScreen(r, 1)
        lurek.render.print(tostring(r) .. "F", GRID_X - FLOOR_LABEL_W, y + ROOM_H / 2 - 6, FLOOR_LABEL_W, "right")
    end

    -- Draw elevator shaft
    if highestFloor > 1 then
        local _, topY = gridToScreen(highestFloor, 1)
        local _, botY = gridToScreen(1, 1)
        local shaftX = GRID_X - 14
        lurek.render.setColor(0.35, 0.35, 0.4, 0.7)
        lurek.render.rectangle("fill", shaftX, topY, 8, botY - topY + ROOM_H)
    end

    -- Draw grid and rooms
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            local x, y = gridToScreen(r, c)
            local room = rooms[r][c]
            if room then
                local info = ROOM_TYPES[room.type]
                local dr, dg, db = info.color[1], info.color[2], info.color[3]

                -- Darken if dirty
                if room.dirty >= DIRTY_THRESHOLD then
                    dr = dr * 0.6
                    dg = dg * 0.6
                    db = db * 0.6
                end

                -- Cleaning animation
                if room.cleanTimer and room.cleanTimer > 0 then
                    local pulse = 0.7 + 0.3 * math.sin(room.cleanTimer * 8)
                    dr = dr * pulse + 0.3 * (1 - pulse)
                    dg = dg * pulse + 0.6 * (1 - pulse)
                    db = db * pulse + 1.0 * (1 - pulse)
                end

                lurek.render.setColor(dr, dg, db, 0.9)
                lurek.render.rectangle("fill", x + 2, y + 2, ROOM_W - 4, ROOM_H - 4)

                -- Room label
                lurek.render.setColor(1, 1, 1, 0.9)
                lurek.render.print(roomLabel(room.type), x + 4, y + 4)

                -- Occupant indicator
                if room.occupant then
                    local g = room.occupant
                    local faceX = x + 10 + (ROOM_W - 30) * g.walkX
                    local faceY = y + ROOM_H - 20
                    if g.satisfaction > 0.6 then
                        lurek.render.setColor(0.2, 0.9, 0.2, 1)
                    elseif g.satisfaction > 0.3 then
                        lurek.render.setColor(0.9, 0.9, 0.2, 1)
                    else
                        lurek.render.setColor(0.9, 0.2, 0.2, 1)
                    end
                    lurek.render.circle("fill", faceX, faceY, 6)
                    lurek.render.setColor(0, 0, 0, 1)
                    lurek.render.circle("fill", faceX - 2, faceY - 2, 1)
                    lurek.render.circle("fill", faceX + 2, faceY - 2, 1)
                end

                -- Dirty indicator
                if room.dirty >= DIRTY_THRESHOLD and (not room.cleanTimer or room.cleanTimer <= 0) then
                    lurek.render.setColor(0.6, 0.4, 0.1, 0.8)
                    lurek.render.print("!", x + ROOM_W - 16, y + 4)
                end
            else
                -- Empty slot
                lurek.render.setColor(0.2, 0.18, 0.16, 0.4)
                lurek.render.rectangle("line", x + 2, y + 2, ROOM_W - 4, ROOM_H - 4)
            end
        end
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        local alpha = math.max(p.life / p.maxLife, 0)
        lurek.render.setColor(p.r, p.g, p.b, alpha)
        lurek.render.circle("fill", p.x, p.y, p.size * alpha)
    end

    camera:detach()
end)

------------------------------------------------------------
-- Render — UI
------------------------------------------------------------
lurek.render_ui(function()
    if state == STATE_TITLE then
        lurek.render.setColor(0.85, 0.72, 0.2, 1)
        lurek.render.print("HOTEL MANAGER", 220, 180, 360, "center", 0, 3, 3)
        lurek.render.setColor(0.7, 0.65, 0.5, 1)
        lurek.render.print("BUILD YOUR EMPIRE", 220, 260, 360, "center", 0, 1.5, 1.5)
        lurek.render.setColor(1, 1, 1, 0.5 + 0.5 * math.sin(lurek.timer.getTime() * 3))
        lurek.render.print("Click to Start", 280, 360, 240, "center")
        return
    end

    if state == STATE_VICTORY then
        lurek.render.setColor(0.85, 0.72, 0.2, 1)
        lurek.render.print("5-STAR HOTEL!", 200, 180, 400, "center", 0, 3, 3)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("Gold: " .. math.floor(gold), 280, 280, 240, "center", 0, 1.5, 1.5)
        lurek.render.print("Total Guests: " .. totalGuests, 280, 320, 240, "center")
        lurek.render.setColor(1, 1, 1, 0.5 + 0.5 * math.sin(lurek.timer.getTime() * 3))
        lurek.render.print("Press ESC to exit", 280, 400, 240, "center")
        return
    end

    -- HUD background
    lurek.render.setColor(0.08, 0.07, 0.06, 0.85)
    lurek.render.rectangle("fill", 0, 0, 800, 28)

    -- Gold
    lurek.render.setColor(0.95, 0.85, 0.2, 1)
    lurek.render.print("Gold: " .. math.floor(displayGold), 10, 6)

    -- Rating stars
    lurek.render.setColor(1, 0.9, 0.3, 1)
    local starStr = ""
    for i = 1, 5 do
        if rating >= i then
            starStr = starStr .. "*"
        elseif rating >= i - 0.5 then
            starStr = starStr .. "~"
        else
            starStr = starStr .. "."
        end
    end
    lurek.render.print("Rating: " .. starStr .. " (" .. string.format("%.1f", rating) .. ")", 200, 6)

    -- Cleaners
    lurek.render.setColor(0.5, 0.8, 1, 1)
    lurek.render.print("Cleaners: " .. cleaners, 460, 6)

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.5, 0.7)
    lurek.render.print("FPS: " .. fps, 740, 6)

    -- Mode indicator
    if mode then
        lurek.render.setColor(1, 1, 1, 0.9)
        local modeText = "Mode: " .. mode
        lurek.render.print(modeText, 10, 580)
    end

    -- Controls bar
    lurek.render.setColor(0.08, 0.07, 0.06, 0.85)
    lurek.render.rectangle("fill", 0, 558, 800, 42)
    lurek.render.setColor(0.6, 0.6, 0.55, 0.9)
    lurek.render.print("[1]Std [2]Dlx [3]Suite  [C]Clean [U]Upgrade [H]Hire  [ESC]Quit", 10, 566)

    -- Guests count
    lurek.render.setColor(0.7, 0.9, 0.7, 1)
    lurek.render.print("Guests: " .. #guests .. "  Total: " .. totalGuests, 580, 6)
end)
