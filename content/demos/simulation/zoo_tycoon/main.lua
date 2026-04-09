-- Zoo Tycoon — Top-down zoo management
-- Build enclosures, place animals, attract guests, earn revenue
-- Run with: cargo run -- content/demos/simulation/zoo_tycoon

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local GRID_W, GRID_H = 20, 15
local CELL = 28
local OX, OY = 10, 50
local grid = {}
local animals = {}
local guests = {}
local gold = 500
local day = 1
local day_timer = 0
local DAY_LENGTH = 30
local daily_revenue = 0
local daily_cost = 0
local happiness = 50
local selected_tool = "path" -- path, fence, food_stand, gift_shop, water, tree
local selected_animal = 0  -- 1=lion, 2=penguin, 3=monkey, 4=elephant
local message = ""
local msg_timer = 0
local show_report = false
local last_report = ""
local animal_types = {
    { name = "Lion",     icon = "L", needs = "tree",  food_cost = 8,  attract = 15, color = {0.9, 0.7, 0.2} },
    { name = "Penguin",  icon = "P", needs = "water", food_cost = 5,  attract = 12, color = {0.3, 0.5, 0.9} },
    { name = "Monkey",   icon = "M", needs = "tree",  food_cost = 6,  attract = 10, color = {0.7, 0.4, 0.2} },
    { name = "Elephant", icon = "E", needs = "water", food_cost = 12, attract = 20, color = {0.6, 0.6, 0.6} },
}
local tools = { "path", "fence", "water", "tree", "food_stand", "gift_shop", "remove" }
local tool_costs = { path = 5, fence = 8, water = 10, tree = 10, food_stand = 30, gift_shop = 40, remove = 0 }
local TICKET_PRICE = 3

function lurek.init()
    for y = 1, GRID_H do
        grid[y] = {}
        for x = 1, GRID_W do
            grid[y][x] = "grass"
        end
    end
    -- Gate
    grid[GRID_H][1] = "gate"
    grid[GRID_H][2] = "path"
    spawn_guests(5)
end

local function msg(t)
    message = t
    msg_timer = 2
end

local function count_cells(kind)
    local n = 0
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            if grid[y][x] == kind then n = n + 1 end
        end
    end
    return n
end

local function animal_at(gx, gy)
    for i, a in ipairs(animals) do
        if a.gx == gx and a.gy == gy then return a, i end
    end
    return nil
end

local function has_need_nearby(gx, gy, need)
    for dy = -2, 2 do
        for dx = -2, 2 do
            local nx, ny = gx + dx, gy + dy
            if nx >= 1 and nx <= GRID_W and ny >= 1 and ny <= GRID_H then
                if grid[ny][nx] == need then return true end
            end
        end
    end
    return false
end

local function is_enclosed(gx, gy)
    -- Simple check: fence in all 4 cardinal neighbors or boundary
    local dirs = {{0,-1},{0,1},{-1,0},{1,0}}
    local fence_count = 0
    for _, d in ipairs(dirs) do
        local nx, ny = gx + d[1], gy + d[2]
        if nx < 1 or nx > GRID_W or ny < 1 or ny > GRID_H then
            fence_count = fence_count + 1
        elseif grid[ny][nx] == "fence" then
            fence_count = fence_count + 1
        end
    end
    return fence_count >= 3
end

function spawn_guests(n)
    for i = 1, n do
        guests[#guests + 1] = {
            x = OX + 0.5 * CELL,
            y = OY + (GRID_H - 0.5) * CELL,
            target_gx = math.random(2, GRID_W - 1),
            target_gy = math.random(2, GRID_H - 1),
            timer = math.random() * 5 + 3,
            happy = 50,
        }
    end
end

function lurek.process(dt)
    if msg_timer > 0 then msg_timer = msg_timer - dt end
    if show_report then return end

    day_timer = day_timer + dt
    if day_timer >= DAY_LENGTH then
        day_timer = 0
        day = day + 1
        -- Calculate daily
        local rev = #guests * TICKET_PRICE
        local food = 0
        local staff = 10
        local shop_income = count_cells("food_stand") * 8 + count_cells("gift_shop") * 12
        for _, a in ipairs(animals) do
            food = food + animal_types[a.kind].food_cost
        end
        daily_revenue = rev + shop_income
        daily_cost = food + staff
        gold = gold + daily_revenue - daily_cost
        -- Happiness
        local total_happy = 0
        for _, a in ipairs(animals) do
            total_happy = total_happy + (a.happy and 1 or 0)
        end
        local animal_ratio = #animals > 0 and (total_happy / #animals) or 0
        happiness = clamp(50 + animal_ratio * 30 + #animals * 3 - 5, 0, 100)
        -- Spawn more guests based on happiness
        local new_guests = math.floor(happiness / 25)
        spawn_guests(new_guests)
        last_report = "Day " .. (day - 1) .. " Report:\nRevenue: " .. daily_revenue .. "g  Costs: " .. daily_cost .. "g\nNet: " .. (daily_revenue - daily_cost) .. "g\nGuests: " .. #guests .. "  Animals: " .. #animals .. "\nHappiness: " .. math.floor(happiness) .. "%"
        show_report = true
    end

    -- Move guests
    for _, g in ipairs(guests) do
        local tx = OX + (g.target_gx - 0.5) * CELL
        local ty = OY + (g.target_gy - 0.5) * CELL
        local dx, dy = tx - g.x, ty - g.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 2 then
            g.x = g.x + (dx / dist) * 30 * dt
            g.y = g.y + (dy / dist) * 30 * dt
        else
            g.timer = g.timer - dt
            if g.timer <= 0 then
                g.target_gx = math.random(2, GRID_W - 1)
                g.target_gy = math.random(2, GRID_H - 1)
                g.timer = math.random() * 5 + 3
            end
        end
    end

    -- Update animal happiness
    for _, a in ipairs(animals) do
        local at = animal_types[a.kind]
        a.happy = has_need_nearby(a.gx, a.gy, at.needs) and is_enclosed(a.gx, a.gy)
    end
end

function lurek.keypressed(key)
    if show_report then
        if key == "return" then show_report = false end
        return
    end
    if key == "1" then selected_animal = 1; selected_tool = "animal"; msg("Place Lion (50g)")
    elseif key == "2" then selected_animal = 2; selected_tool = "animal"; msg("Place Penguin (30g)")
    elseif key == "3" then selected_animal = 3; selected_tool = "animal"; msg("Place Monkey (25g)")
    elseif key == "4" then selected_animal = 4; selected_tool = "animal"; msg("Place Elephant (60g)")
    elseif key == "tab" then
        -- Cycle tools
        local idx = 1
        for i, t in ipairs(tools) do
            if t == selected_tool then idx = i; break end
        end
        idx = idx % #tools + 1
        selected_tool = tools[idx]
        selected_animal = 0
        msg("Tool: " .. selected_tool)
    elseif key == "escape" then
        lurek.signal.quit()
    end
end

function lurek.mousepressed(mx, my, btn)
    if show_report then return end
    if btn ~= 1 then return end
    -- Grid click
    local gx = math.floor((mx - OX) / CELL) + 1
    local gy = math.floor((my - OY) / CELL) + 1
    if gx < 1 or gx > GRID_W or gy < 1 or gy > GRID_H then return end
    if grid[gy][gx] == "gate" then return end

    if selected_tool == "animal" and selected_animal > 0 then
        local costs = {50, 30, 25, 60}
        local cost = costs[selected_animal]
        if gold >= cost and not animal_at(gx, gy) then
            animals[#animals + 1] = { kind = selected_animal, gx = gx, gy = gy, happy = false }
            gold = gold - cost
            msg("Placed " .. animal_types[selected_animal].name)
        elseif gold < cost then
            msg("Not enough gold!")
        end
    elseif selected_tool == "remove" then
        local a, idx = animal_at(gx, gy)
        if a then
            table.remove(animals, idx)
            msg("Removed animal")
        else
            grid[gy][gx] = "grass"
            msg("Cleared cell")
        end
    else
        local cost = tool_costs[selected_tool] or 0
        if gold >= cost then
            grid[gy][gx] = selected_tool
            gold = gold - cost
        else
            msg("Not enough gold!")
        end
    end
end

local cell_colors = {
    grass = {0.2, 0.5, 0.15},
    path = {0.6, 0.55, 0.4},
    fence = {0.5, 0.35, 0.15},
    water = {0.2, 0.4, 0.8},
    tree = {0.1, 0.6, 0.1},
    food_stand = {0.9, 0.6, 0.2},
    gift_shop = {0.8, 0.3, 0.7},
    gate = {0.8, 0.7, 0.3},
}

function lurek.render()
    lurek.gfx.setBackgroundColor(0.1, 0.12, 0.08)

    -- UI header
    lurek.gfx.setColor(1, 0.9, 0.4, 1)
    lurek.gfx.print("Zoo Tycoon", 10, 5, 1.2)
    lurek.gfx.setColor(1, 1, 0.6, 1)
    lurek.gfx.print("Gold: " .. gold, 160, 8, 0.9)
    lurek.gfx.print("Day: " .. day, 300, 8, 0.9)
    lurek.gfx.print("Guests: " .. #guests, 400, 8, 0.9)
    lurek.gfx.print("Happy: " .. math.floor(happiness) .. "%", 520, 8, 0.9)

    -- Tool bar
    lurek.gfx.setColor(0.7, 0.7, 0.6, 1)
    lurek.gfx.print("Tool: " .. selected_tool, 10, 30, 0.75)
    lurek.gfx.print("Tab=cycle | 1-4=animals | Click=place", 150, 30, 0.65)

    -- Grid
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local c = cell_colors[grid[y][x]] or {0.3, 0.3, 0.3}
            lurek.gfx.setColor(c[1], c[2], c[3], 1)
            lurek.gfx.rectangle("fill", OX + (x - 1) * CELL, OY + (y - 1) * CELL, CELL - 1, CELL - 1)
        end
    end

    -- Gate label
    lurek.gfx.setColor(0, 0, 0, 1)
    lurek.gfx.print("G", OX + 6, OY + (GRID_H - 1) * CELL + 6, 0.7)

    -- Animals
    for _, a in ipairs(animals) do
        local at = animal_types[a.kind]
        local ax = OX + (a.gx - 1) * CELL + 2
        local ay = OY + (a.gy - 1) * CELL + 2
        -- Happiness indicator
        if a.happy then
            lurek.gfx.setColor(0.2, 0.8, 0.2, 0.4)
        else
            lurek.gfx.setColor(0.8, 0.2, 0.2, 0.4)
        end
        lurek.gfx.rectangle("fill", ax, ay, CELL - 3, CELL - 3)
        -- Icon
        lurek.gfx.setColor(at.color[1], at.color[2], at.color[3], 1)
        lurek.gfx.print(at.icon, ax + 6, ay + 4, 1)
    end

    -- Guests
    lurek.gfx.setColor(1, 0.9, 0.7, 1)
    for _, g in ipairs(guests) do
        lurek.gfx.circle("fill", g.x, g.y, 4)
    end

    -- Day timer bar
    lurek.gfx.setColor(0.2, 0.2, 0.2, 1)
    lurek.gfx.rectangle("fill", OX, OY + GRID_H * CELL + 5, GRID_W * CELL, 8)
    lurek.gfx.setColor(0.4, 0.7, 1, 1)
    lurek.gfx.rectangle("fill", OX, OY + GRID_H * CELL + 5, GRID_W * CELL * (day_timer / DAY_LENGTH), 8)

    -- Legend
    local lx = OX + GRID_W * CELL + 10
    lurek.gfx.setColor(0.9, 0.85, 0.6, 1)
    lurek.gfx.print("Legend:", lx, OY, 0.8)
    local legend = { {"Path",0.6,0.55,0.4}, {"Fence",0.5,0.35,0.15}, {"Water",0.2,0.4,0.8},
                     {"Tree",0.1,0.6,0.1}, {"Food",0.9,0.6,0.2}, {"Gift",0.8,0.3,0.7} }
    for i, l in ipairs(legend) do
        lurek.gfx.setColor(l[2], l[3], l[4], 1)
        lurek.gfx.rectangle("fill", lx, OY + 18 + (i - 1) * 20, 12, 12)
        lurek.gfx.setColor(0.8, 0.8, 0.8, 1)
        lurek.gfx.print(l[1], lx + 16, OY + 16 + (i - 1) * 20, 0.65)
    end

    -- Animal key
    lurek.gfx.setColor(0.9, 0.85, 0.6, 1)
    lurek.gfx.print("Animals:", lx, OY + 150, 0.8)
    for i, at in ipairs(animal_types) do
        lurek.gfx.setColor(at.color[1], at.color[2], at.color[3], 1)
        lurek.gfx.print(i .. "=" .. at.name, lx, OY + 170 + (i - 1) * 18, 0.65)
    end

    -- Message
    if msg_timer > 0 then
        lurek.gfx.setColor(1, 1, 0.7, clamp(msg_timer, 0, 1))
        lurek.gfx.print(message, OX, OY + GRID_H * CELL + 20, 0.85)
    end

    -- Day report overlay
    if show_report then
        lurek.gfx.setColor(0, 0, 0, 0.75)
        lurek.gfx.rectangle("fill", 100, 100, 400, 220)
        lurek.gfx.setColor(1, 0.9, 0.4, 1)
        lurek.gfx.print(last_report, 120, 120, 1)
        lurek.gfx.setColor(0.5, 1, 0.5, 1)
        lurek.gfx.print("Press ENTER to continue", 180, 290, 0.9)
    end

    lurek.gfx.setColor(0.5, 0.5, 0.5, 1)
    lurek.gfx.print("FPS: " .. lurek.time.getFPS(), 700, 5, 0.6)
end
