-- Colony Simulation — Top-down colony builder with colonist AI
-- Click to place buildings (1=Farm, 2=Bed, 3=Rec), right-click to assign colonist

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600
local TILE = 24
local COLS = math.floor(W / TILE)
local ROWS = math.floor(H / TILE) - 2 -- reserve bottom for HUD

local colonists, buildings, food_store, materials
local day_time, day_length, day_count
local place_type -- 1=farm, 2=bed, 3=rec
local spawn_timer

local BUILD_COST = 5
local BUILD_NAMES = { "Farm", "Bed", "Rec Hall" }
local BUILD_COLORS = {
    { 0.3, 0.7, 0.2 }, -- farm green
    { 0.4, 0.3, 0.6 }, -- bed purple
    { 0.9, 0.7, 0.2 }, -- rec yellow
}

local function grid_dist(ax, ay, bx, by)
    return math.abs(ax - bx) + math.abs(ay - by)
end

local function find_nearest_building(cx, cy, btype)
    local best, best_d = nil, 99999
    for _, b in ipairs(buildings) do
        if b.type == btype then
            local d = grid_dist(cx, cy, b.x, b.y)
            if d < best_d then best = b; best_d = d end
        end
    end
    return best
end

local function new_colonist(x, y)
    return {
        x = x, y = y,
        tx = x, ty = y, -- target
        hunger = 50 + math.random() * 30,
        energy = 50 + math.random() * 30,
        happiness = 60 + math.random() * 20,
        state = "idle",
        task_timer = 0,
        target_building = nil,
        speed = 2 + math.random() * 1.5, -- tiles per second
        name = "C" .. (#colonists + 1),
    }
end

function luna.load()
    luna.window.setTitle("Colony Sim")
    luna.graphics.setBackgroundColor(0.12, 0.15, 0.1)

    colonists = {}
    buildings = {}
    food_store = 30
    materials = 20
    day_time = 0
    day_length = 60 -- seconds per day
    day_count = 1
    place_type = 1
    spawn_timer = 0

    -- start with 3 colonists
    for i = 1, 3 do
        table.insert(colonists, new_colonist(
            math.random(3, COLS - 3),
            math.random(3, ROWS - 3)
        ))
    end

    -- starting buildings
    table.insert(buildings, { type = 1, x = 10, y = 8 }) -- farm
    table.insert(buildings, { type = 2, x = 14, y = 8 }) -- bed
    table.insert(buildings, { type = 3, x = 18, y = 8 }) -- rec
end

local function move_toward(c, dt)
    if c.x == c.tx and c.y == c.ty then return true end
    local dx = c.tx - c.x
    local dy = c.ty - c.y
    local step = c.speed * dt
    if math.abs(dx) > 0.1 then
        c.x = c.x + (dx > 0 and 1 or -1) * clamp(step, 0, math.abs(dx))
    elseif math.abs(dy) > 0.1 then
        c.y = c.y + (dy > 0 and 1 or -1) * clamp(step, 0, math.abs(dy))
    end
    return math.abs(c.x - c.tx) < 0.2 and math.abs(c.y - c.ty) < 0.2
end

local function is_night()
    local norm = day_time / day_length
    return norm > 0.7
end

function luna.update(dt)
    -- day cycle
    day_time = day_time + dt
    if day_time >= day_length then
        day_time = day_time - day_length
        day_count = day_count + 1
        -- daily food consumption
        for _, c in ipairs(colonists) do
            food_store = food_store - 1
        end
        -- materials trickle
        materials = materials + 2
    end

    -- farms produce food
    -- Each Farm building ticks independently; food is global not per-building
    for _, b in ipairs(buildings) do
        if b.type == 1 then -- farm
            b.timer = (b.timer or 0) + dt
            if b.timer >= 8 then
                b.timer = 0
                food_store = food_store + 1
            end
        end
    end

    -- colonist AI
    for _, c in ipairs(colonists) do
        -- decay needs
        c.hunger = c.hunger - 5 * dt
        c.energy = c.energy - 3 * dt
        c.happiness = c.happiness - 2 * dt

        if c.hunger < 0 then c.hunger = 0 end
        if c.energy < 0 then c.energy = 0 end
        if c.happiness < 0 then c.happiness = 0 end

        if c.state == "idle" then
            -- Needs AI: pick the currently lowest stat to satisfy next
            local lowest = "hunger"
            local lowest_val = c.hunger
            if c.energy < lowest_val then lowest = "energy"; lowest_val = c.energy end
            if c.happiness < lowest_val then lowest = "happiness"; lowest_val = c.happiness end

            -- Night override: force sleep regardless of other needs
            if is_night() and c.energy < 80 then lowest = "energy" end

            local target_type = 1 -- farm for hunger
            if lowest == "energy" then target_type = 2 end
            if lowest == "happiness" then target_type = 3 end

            local b = find_nearest_building(c.x, c.y, target_type)
            if b then
                c.tx = b.x; c.ty = b.y
                c.target_building = b
                c.state = "moving"
                c.need = lowest
            else
                -- wander
                c.tx = clamp(c.x + math.random(-3, 3), 1, COLS - 1)
                c.ty = clamp(c.y + math.random(-3, 3), 1, ROWS - 1)
                c.state = "moving"
                c.need = nil
            end
        elseif c.state == "moving" then
            local arrived = move_toward(c, dt)
            if arrived then
                if c.need then
                    c.state = "working"
                    c.task_timer = 0
                else
                    c.state = "idle"
                end
            end
        elseif c.state == "working" then
            c.task_timer = c.task_timer + dt
            local work_time = 3

            if c.need == "hunger" and food_store > 0 then
                c.hunger = c.hunger + 20 * dt
                if c.task_timer > work_time then
                    food_store = food_store - 1
                    c.state = "idle"
                end
            elseif c.need == "energy" then
                c.energy = c.energy + 25 * dt
                if c.task_timer > work_time then c.state = "idle" end
            elseif c.need == "happiness" then
                c.happiness = c.happiness + 20 * dt
                if c.task_timer > work_time then c.state = "idle" end
            else
                c.state = "idle"
            end

            -- clamp
            c.hunger = clamp(c.hunger, 0, 100)
            c.energy = clamp(c.energy, 0, 100)
            c.happiness = clamp(c.happiness, 0, 100)
        end
    end

    -- spawn new colonist if average happiness > 60
    spawn_timer = spawn_timer + dt
    if spawn_timer >= 30 and #colonists < 12 then
        spawn_timer = 0
        local avg = 0
        for _, c in ipairs(colonists) do avg = avg + c.happiness end
        avg = avg / #colonists
        if avg > 60 then
            table.insert(colonists, new_colonist(
                math.random(2, COLS - 2),
                math.random(2, ROWS - 2)
            ))
        end
    end
end

function luna.draw()
    -- day/night tint
    local night_alpha = 0
    local norm = day_time / day_length
    if norm > 0.7 then night_alpha = (norm - 0.7) / 0.3 * 0.4
    elseif norm < 0.1 then night_alpha = (1 - norm / 0.1) * 0.4
    end

    -- grid
    luna.graphics.setColor(0.18, 0.2, 0.15, 0.3)
    for r = 0, ROWS do
        luna.graphics.line(0, r * TILE, COLS * TILE, r * TILE)
    end
    for c = 0, COLS do
        luna.graphics.line(c * TILE, 0, c * TILE, ROWS * TILE)
    end

    -- buildings
    for _, b in ipairs(buildings) do
        local col = BUILD_COLORS[b.type]
        luna.graphics.setColor(col[1], col[2], col[3], 0.8)
        luna.graphics.rectangle("fill", (b.x - 0.5) * TILE, (b.y - 0.5) * TILE, TILE, TILE)
        luna.graphics.setColor(1, 1, 1, 0.4)
        luna.graphics.rectangle("line", (b.x - 0.5) * TILE, (b.y - 0.5) * TILE, TILE, TILE)

        -- label
        luna.graphics.setColor(1, 1, 1, 0.6)
        local tag = ({ "F", "B", "R" })[b.type]
        luna.graphics.print(tag, (b.x - 0.3) * TILE, (b.y - 0.35) * TILE, 0.7)
    end

    -- colonists
    for _, c in ipairs(colonists) do
        -- color by state
        local cr, cg, cb = 0.3, 0.7, 1
        if c.state == "working" then cr, cg, cb = 0.2, 0.9, 0.3 end
        if c.hunger < 20 or c.energy < 15 then cr, cg, cb = 1, 0.3, 0.2 end

        luna.graphics.setColor(cr, cg, cb, 1)
        luna.graphics.circle("fill", c.x * TILE, c.y * TILE, 5)

        -- need indicators (tiny bars)
        local bx = c.x * TILE - 6
        local by = c.y * TILE - 10
        -- hunger (red)
        luna.graphics.setColor(0.8, 0.2, 0.2, 0.7)
        luna.graphics.rectangle("fill", bx, by, 12 * (c.hunger / 100), 2)
        -- energy (blue)
        luna.graphics.setColor(0.2, 0.4, 0.9, 0.7)
        luna.graphics.rectangle("fill", bx, by + 3, 12 * (c.energy / 100), 2)
        -- happiness (yellow)
        luna.graphics.setColor(0.9, 0.8, 0.2, 0.7)
        luna.graphics.rectangle("fill", bx, by + 6, 12 * (c.happiness / 100), 2)
    end

    -- placement ghost
    local mx, my = luna.mouse.getPosition()
    local gc = math.floor(mx / TILE) + 0.5
    local gr = math.floor(my / TILE) + 0.5
    if gr <= ROWS then
        local col = BUILD_COLORS[place_type]
        luna.graphics.setColor(col[1], col[2], col[3], 0.3)
        luna.graphics.rectangle("fill", (gc - 0.5) * TILE, (gr - 0.5) * TILE, TILE, TILE)
    end

    -- night overlay
    if night_alpha > 0 then
        luna.graphics.setColor(0.02, 0.02, 0.08, night_alpha)
        luna.graphics.rectangle("fill", 0, 0, W, H)
    end

    -- HUD background
    local hud_y = ROWS * TILE
    luna.graphics.setColor(0.1, 0.1, 0.12, 0.9)
    luna.graphics.rectangle("fill", 0, hud_y, W, H - hud_y)

    luna.graphics.setColor(1, 1, 1, 1)
    local time_str = is_night() and "Night" or "Day"
    luna.graphics.print(string.format("Day %d (%s)  |  Food: %d  Materials: %d  Colonists: %d  |  Placing: %s (1/2/3 to switch)",
        day_count, time_str, food_store, materials, #colonists, BUILD_NAMES[place_type]),
        10, hud_y + 6, 0.8)

    -- colonist details on second line
    local detail = ""
    for i, c in ipairs(colonists) do
        if i <= 6 then
            detail = detail .. string.format("%s: H%d E%d J%d  ", c.name,
                math.floor(c.hunger), math.floor(c.energy), math.floor(c.happiness))
        end
    end
    luna.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    luna.graphics.print(detail, 10, hud_y + 24, 0.65)

    luna.graphics.setColor(1, 1, 1, 0.4)
    luna.graphics.print("FPS: " .. luna.timer.getFPS(), W - 70, hud_y + 6, 0.7)
end

function luna.mousepressed(x, y, button)
    local gc = math.floor(x / TILE) + 0.5
    local gr = math.floor(y / TILE) + 0.5
    if gr > ROWS then return end

    if button == 1 and materials >= BUILD_COST then
        materials = materials - BUILD_COST
        table.insert(buildings, { type = place_type, x = gc, y = gr })
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "1" then place_type = 1 end
    if key == "2" then place_type = 2 end
    if key == "3" then place_type = 3 end
end
