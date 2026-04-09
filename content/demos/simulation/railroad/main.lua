-- Railroad / Transport Logistics Demo
-- Place tracks, route trains between stations, earn revenue from deliveries
-- Run with: cargo run -- demos/simulation/railroad

local TILE = 32
local COLS, ROWS = 25, 19
local W, H = COLS * TILE, ROWS * TILE

-- Track types: 0=empty, 1=horizontal, 2=vertical, 3=curve_ne, 4=curve_se, 5=curve_sw, 6=curve_nw
local grid = {}
local stations = {}
local trains = {}
local revenue = 0
local day = 1
local dayTimer = 0
local DAY_LENGTH = 60
local revenueHistory = {}
local selectedTrack = 1 -- 1=horiz, 2=vert, 3-6=curves
local message = ""
local msgTimer = 0

local TRACK_NAMES = {"Horizontal", "Vertical", "Curve NE", "Curve SE", "Curve SW", "Curve NW"}

-- Direction deltas: right, down, left, up
local DX = {1, 0, -1, 0}
local DY = {0, 1, 0, -1}

-- Track connections: maps each track-type number to the two grid directions
-- (1=right, 2=down, 3=left, 4=up) that a train can pass through.
-- When routing trains, the engine enters from one end and exits via the other.
local TRACK_DIRS = {
    [1] = {1, 3},       -- horizontal straight: enters/exits left or right
    [2] = {2, 4},       -- vertical straight:   enters/exits up or down
    [3] = {1, 4},       -- curve NE: connects right ↔ up   (╗ shape facing south-west)
    [4] = {1, 2},       -- curve SE: connects right ↔ down  (╔ shape facing north-west)
    [5] = {3, 2},       -- curve SW: connects left  ↔ down  (╗ shape facing north-east)
    [6] = {3, 4},       -- curve NW: connects left  ↔ up    (╔ shape facing south-east)
}

local CARGO_COLORS = {
    wood  = {0.6, 0.4, 0.2},
    iron  = {0.5, 0.5, 0.6},
    food  = {0.3, 0.8, 0.3},
}
local CARGO_TYPES = {"wood", "iron", "food"}

local function initGrid()
    for r = 1, ROWS do
        grid[r] = {}
        for c = 1, COLS do
            grid[r][c] = 0
        end
    end
end

local function addStation(col, row, name, produces, consumes)
    table.insert(stations, {
        col = col, row = row, name = name,
        produces = produces, consumes = consumes,
        stock = 0, maxStock = 5,
    })
    grid[row][col] = -1 -- station marker
end

local function hasDir(trackType, dir)
    if not TRACK_DIRS[trackType] then return false end
    for _, d in ipairs(TRACK_DIRS[trackType]) do
        if d == dir then return true end
    end
    return false
end

local function oppositeDir(d) return ((d + 1) % 4) + 1 end

-- nextTrackPos: given a train's current cell and the direction it arrived FROM,
-- returns the next cell (nc, nr) and outgoing direction d.
-- The key invariant: a train must NOT exit through the direction it entered.
-- oppositeDir maps the incoming direction to the "entry face" of this tile so
-- we can skip it and use only the other connector in TRACK_DIRS.
-- Returns nil if the cell is empty or has no valid exit (dead end).
local function nextTrackPos(col, row, fromDir)
    local t = grid[row] and grid[row][col]
    if not t or t <= 0 then return nil end
    local dirs = TRACK_DIRS[t]
    if not dirs then return nil end
    for _, d in ipairs(dirs) do
        if d ~= oppositeDir(fromDir) then
            local nc, nr = col + DX[d], row + DY[d]
            return nc, nr, d
        end
    end
    return nil
end

local function spawnTrain(stationIdx)
    local st = stations[stationIdx]
    if st.stock > 0 then
        st.stock = st.stock - 1
        table.insert(trains, {
            col = st.col, row = st.row,
            dir = 1, -- start heading right
            cargo = st.produces,
            speed = 3, moveTimer = 0,
            fromStation = stationIdx,
            px = st.col * TILE - TILE / 2, py = st.row * TILE - TILE / 2,
        })
    end
end

function luna.init()
    luna.gfx.setBackgroundColor(0.15, 0.2, 0.15)
    initGrid()
    addStation(3, 4, "Lumber", "wood", "food")
    addStation(22, 4, "Forge", "iron", "wood")
    addStation(12, 16, "Farm", "food", "iron")

    -- Pre-place some track
    for c = 4, 21 do grid[4][c] = 1 end
    for r = 5, 15 do grid[r][12] = 2 end
    grid[4][12] = 1 -- override with horizontal at junction
    grid[16][12] = -1 -- station

    revenueHistory = {0}
end

function luna.process(dt)
    -- Day cycle
    dayTimer = dayTimer + dt
    if dayTimer >= DAY_LENGTH then
        dayTimer = dayTimer - DAY_LENGTH
        day = day + 1
        table.insert(revenueHistory, revenue)
        if #revenueHistory > 10 then table.remove(revenueHistory, 1) end
    end

    -- Station production
    for _, st in ipairs(stations) do
        st.prodTimer = (st.prodTimer or 0) + dt
        if st.prodTimer >= 5 and st.stock < st.maxStock then
            st.stock = st.stock + 1
            st.prodTimer = 0
        end
    end

    -- Auto-spawn trains from stations with stock
    for i, st in ipairs(stations) do
        st.spawnTimer = (st.spawnTimer or 0) + dt
        if st.spawnTimer >= 8 and st.stock > 0 and #trains < 6 then
            spawnTrain(i)
            st.spawnTimer = 0
        end
    end

    -- Move trains
    for i = #trains, 1, -1 do
        local tr = trains[i]
        tr.moveTimer = tr.moveTimer + dt * tr.speed
        if tr.moveTimer >= 1 then
            tr.moveTimer = tr.moveTimer - 1
            local nc, nr, nd = nextTrackPos(tr.col, tr.row, tr.dir)
            if nc and nr and grid[nr] and grid[nr][nc] and grid[nr][nc] ~= 0 then
                -- Check collision with other trains
                local blocked = false
                for j, other in ipairs(trains) do
                    if j ~= i and other.col == nc and other.row == nr then
                        blocked = true
                        break
                    end
                end
                if not blocked then
                    tr.col, tr.row, tr.dir = nc, nr, nd
                    tr.px = tr.col * TILE - TILE / 2
                    tr.py = tr.row * TILE - TILE / 2
                    -- Check delivery
                    for _, st in ipairs(stations) do
                        if st.col == tr.col and st.row == tr.row and st.consumes == tr.cargo then
                            revenue = revenue + 50
                            message = "+$50 delivered " .. tr.cargo .. " to " .. st.name
                            msgTimer = 2
                            table.remove(trains, i)
                            break
                        end
                    end
                end
            else
                -- Dead end: remove train
                table.remove(trains, i)
            end
        end
    end

    if msgTimer > 0 then msgTimer = msgTimer - dt end

    -- Cycle track type with scroll or keys
    if luna.keyboard.isDown("1") then selectedTrack = 1 end
    if luna.keyboard.isDown("2") then selectedTrack = 2 end
    if luna.keyboard.isDown("3") then selectedTrack = 3 end
    if luna.keyboard.isDown("4") then selectedTrack = 4 end
    if luna.keyboard.isDown("5") then selectedTrack = 5 end
    if luna.keyboard.isDown("6") then selectedTrack = 6 end
end

function luna.mousepressed(mx, my, button)
    local col = math.floor(mx / TILE) + 1
    local row = math.floor(my / TILE) + 1
    if col < 1 or col > COLS or row < 1 or row > ROWS then return end
    if grid[row][col] == -1 then return end -- station

    if button == 1 then
        grid[row][col] = selectedTrack
    elseif button == 2 then
        -- Right click: cycle existing track or remove
        local cur = grid[row][col]
        if cur > 0 then
            grid[row][col] = (cur % 6) + 1
        else
            grid[row][col] = 0
        end
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "tab" then
        selectedTrack = (selectedTrack % 6) + 1
    end
end

local function drawTrack(col, row, t)
    local x, y = (col - 1) * TILE, (row - 1) * TILE
    local cx, cy = x + TILE / 2, y + TILE / 2
    luna.gfx.setColor(0.6, 0.6, 0.5, 1)
    luna.gfx.setLineWidth(3)
    if t == 1 then
        luna.gfx.line(x, cy, x + TILE, cy)
    elseif t == 2 then
        luna.gfx.line(cx, y, cx, y + TILE)
    elseif t == 3 then
        luna.gfx.line(cx, cy, x + TILE, cy)
        luna.gfx.line(cx, cy, cx, y)
    elseif t == 4 then
        luna.gfx.line(cx, cy, x + TILE, cy)
        luna.gfx.line(cx, cy, cx, y + TILE)
    elseif t == 5 then
        luna.gfx.line(cx, cy, x, cy)
        luna.gfx.line(cx, cy, cx, y + TILE)
    elseif t == 6 then
        luna.gfx.line(cx, cy, x, cy)
        luna.gfx.line(cx, cy, cx, y)
    end
    luna.gfx.setLineWidth(1)
end

function luna.render()
    -- Grid
    luna.gfx.setColor(0.2, 0.25, 0.2, 1)
    for r = 1, ROWS do
        for c = 1, COLS do
            luna.gfx.rectangle("line", (c - 1) * TILE, (r - 1) * TILE, TILE, TILE)
        end
    end

    -- Tracks
    for r = 1, ROWS do
        for c = 1, COLS do
            if grid[r][c] > 0 then drawTrack(c, r, grid[r][c]) end
        end
    end

    -- Stations
    for _, st in ipairs(stations) do
        local x, y = (st.col - 1) * TILE, (st.row - 1) * TILE
        local clr = CARGO_COLORS[st.produces]
        luna.gfx.setColor(clr[1], clr[2], clr[3], 1)
        luna.gfx.rectangle("fill", x + 2, y + 2, TILE - 4, TILE - 4)
        luna.gfx.setColor(1, 1, 1, 1)
        luna.gfx.print(st.name, x, y - 14, 0.8)
        luna.gfx.print("Stock:" .. st.stock, x, y + TILE + 2, 0.7)
    end

    -- Trains
    for _, tr in ipairs(trains) do
        local clr = CARGO_COLORS[tr.cargo] or {1, 1, 0}
        luna.gfx.setColor(clr[1], clr[2], clr[3], 1)
        luna.gfx.rectangle("fill", tr.px - 8, tr.py - 8, 16, 16)
        luna.gfx.setColor(0, 0, 0, 1)
        luna.gfx.rectangle("line", tr.px - 8, tr.py - 8, 16, 16)
    end

    -- HUD
    luna.gfx.setColor(0, 0, 0, 0.7)
    luna.gfx.rectangle("fill", 0, H - 60, W, 60)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("Day " .. day .. "  Revenue: $" .. revenue .. "  Track: " .. TRACK_NAMES[selectedTrack] .. " (1-6/Tab)", 10, H - 55, 1)
    luna.gfx.print("Left-click: place track | Right-click: cycle/remove | Trains auto-spawn from stations", 10, H - 35, 0.8)

    -- Revenue mini-graph
    if #revenueHistory > 1 then
        luna.gfx.setColor(0.2, 0.8, 0.2, 1)
        local gx, gy, gw, gh = W - 160, H - 55, 150, 45
        local maxR = 1
        for _, v in ipairs(revenueHistory) do if v > maxR then maxR = v end end
        for i = 2, #revenueHistory do
            local x1 = gx + (i - 2) / (#revenueHistory - 1) * gw
            local x2 = gx + (i - 1) / (#revenueHistory - 1) * gw
            local y1 = gy + gh - (revenueHistory[i - 1] / maxR) * gh
            local y2 = gy + gh - (revenueHistory[i] / maxR) * gh
            luna.gfx.line(x1, y1, x2, y2)
        end
    end

    -- Message
    if msgTimer > 0 then
        luna.gfx.setColor(0, 1, 0.5, msgTimer / 2)
        luna.gfx.print(message, W / 2 - 100, 20, 1)
    end

    -- Mouse hover preview
    local mx, my = luna.mouse.getPosition()
    local hc = math.floor(mx / TILE) + 1
    local hr = math.floor(my / TILE) + 1
    if hc >= 1 and hc <= COLS and hr >= 1 and hr <= ROWS and grid[hr] and grid[hr][hc] == 0 then
        luna.gfx.setColor(1, 1, 0, 0.3)
        luna.gfx.rectangle("fill", (hc - 1) * TILE, (hr - 1) * TILE, TILE, TILE)
    end
end
