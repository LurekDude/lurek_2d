-- God Game / Ecosystem Simulator — Lurek2D Demo
-- Top-down world: guide tribes, perform miracles, balance ecosystem
-- Run with: cargo run -- content/demos/simulation/god_game

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600
local TILE = 20
local COLS, ROWS = W / TILE, H / TILE

local world, tribes, predators, prey, temples
local faith, food_supply, day_timer, day_count, is_night
local selected_miracle, message, msg_timer
local storms, game_time

local MIRACLES = {"rain","lightning","heal","spawn_food"}
local MIRACLE_COST = {rain=15, lightning=10, heal=20, spawn_food=8}
local TERRAIN = {grass=1, water=2, forest=3, desert=4}
local TERRAIN_COLORS = {
    [1] = {0.3,0.65,0.2},
    [2] = {0.2,0.4,0.8},
    [3] = {0.15,0.4,0.12},
    [4] = {0.8,0.7,0.4},
}

local function gen_world()
    world = {}
    for y = 1, ROWS do
        world[y] = {}
        for x = 1, COLS do
            local r = math.random()
            if r < 0.08 then world[y][x] = 2
            elseif r < 0.25 then world[y][x] = 3
            elseif r < 0.32 then world[y][x] = 4
            else world[y][x] = 1 end
        end
    end
end

local function spawn_entity(list, count)
    for i = 1, count do
        local x = math.random(20, W - 20)
        local y = math.random(20, H - 20)
        list[#list+1] = {x=x, y=y, vx=0, vy=0, hp=100, hunger=0, state="wander", timer=0}
    end
end

function lurek.init()
    gen_world()
    tribes = {}
    predators = {}
    prey = {}
    temples = {}
    storms = {}
    faith = 50
    food_supply = 100
    day_timer = 0
    day_count = 1
    is_night = false
    game_time = 0
    selected_miracle = 1
    message = nil
    msg_timer = 0
    spawn_entity(tribes, 8)
    spawn_entity(predators, 4)
    spawn_entity(prey, 12)
end

local function show_msg(t) message = t; msg_timer = 2.5 end

local function move_entity(e, dt, speed)
    e.timer = e.timer - dt
    if e.timer <= 0 then
        e.vx = (math.random() - 0.5) * speed
        e.vy = (math.random() - 0.5) * speed
        e.timer = math.random() * 3 + 1
    end
    e.x = clamp(e.x + e.vx * dt * 60, 5, W - 5)
    e.y = clamp(e.y + e.vy * dt * 60, 5, H - 5)
end

local function dist(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx*dx + dy*dy)
end

function lurek.process(dt)
    game_time = game_time + dt
    if msg_timer > 0 then msg_timer = msg_timer - dt end

    -- day/night cycle (30s per cycle)
    -- is_night slows tribe movement to 30% speed; predators are unaffected
    day_timer = day_timer + dt
    if day_timer > 30 then
        day_timer = 0
        is_night = not is_night
        if not is_night then day_count = day_count + 1 end
    end

    -- tribes
    for i = #tribes, 1, -1 do
        local t = tribes[i]
        move_entity(t, dt, is_night and 0.3 or 0.8)
        t.hunger = t.hunger + dt * 2
        if food_supply > 0 and t.hunger > 30 then
            food_supply = food_supply - 1
            t.hunger = 0
        end
        if t.hunger > 80 then t.hp = t.hp - dt * 10 end
        if t.hp <= 0 then table.remove(tribes, i) end
        -- worship near temples
        for _, tp in ipairs(temples) do
            if dist(t, tp) < 40 then faith = faith + dt * 0.5 end
        end
    end
    -- population growth
    if food_supply > 30 and #tribes < 30 and math.random() < 0.002 then
        spawn_entity(tribes, 1)
    end

    -- predators hunt prey
    -- Each predator scans the full prey list each frame to find the nearest target (O(n²))
    -- Acceptable for small populations; would need spatial hashing for hundreds of entities
    for _, p in ipairs(predators) do
        local nearest = nil
        local nd = 999
        for _, pr in ipairs(prey) do
            local d = dist(p, pr)
            if d < nd then nd = d; nearest = pr end
        end
        if nearest and nd < 150 then
            local dx = nearest.x - p.x
            local dy = nearest.y - p.y
            local len = math.sqrt(dx*dx + dy*dy)
            if len > 0 then
                p.vx = (dx / len) * 1.2
                p.vy = (dy / len) * 1.2
            end
            if nd < 10 then nearest.hp = nearest.hp - 50 end
        else
            move_entity(p, dt, 0.6)
        end
        p.x = clamp(p.x + p.vx * dt * 60, 5, W - 5)
        p.y = clamp(p.y + p.vy * dt * 60, 5, H - 5)
        p.hunger = p.hunger + dt
        if p.hunger > 60 then p.hp = p.hp - dt * 5 end
    end
    -- predators eat killed prey
    for i = #prey, 1, -1 do
        if prey[i].hp <= 0 then
            for _, p in ipairs(predators) do
                if dist(p, prey[i]) < 30 then p.hunger = 0 end
            end
            table.remove(prey, i)
        end
    end
    -- prey wander and reproduce
    for _, pr in ipairs(prey) do move_entity(pr, dt, 0.5) end
    if #prey < 30 and math.random() < 0.005 then spawn_entity(prey, 1) end
    -- predator reproduce
    if #prey > 5 and #predators < 15 and math.random() < 0.001 then spawn_entity(predators, 1) end
    -- remove dead predators
    for i = #predators, 1, -1 do
        if predators[i].hp <= 0 then table.remove(predators, i) end
    end

    -- storms
    if math.random() < 0.0005 then
        storms[#storms+1] = {x=math.random(50,W-50), y=math.random(50,H-50), t=3, r=60}
    end
    for i = #storms, 1, -1 do
        storms[i].t = storms[i].t - dt
        -- damage nearby
        for _, t in ipairs(tribes) do
            if dist(t, storms[i]) < storms[i].r then t.hp = t.hp - dt * 8 end
        end
        if storms[i].t <= 0 then table.remove(storms, i) end
    end

    -- faith from temples over time
    faith = faith + #temples * dt * 0.3
end

local function do_miracle(mx, my)
    local m = MIRACLES[selected_miracle]
    local cost = MIRACLE_COST[m]
    if faith < cost then show_msg("Not enough faith!"); return end
    faith = faith - cost

    if m == "rain" then
        food_supply = food_supply + 20
        show_msg("+20 food from rain")
    elseif m == "lightning" then
        for i = #predators, 1, -1 do
            if dist(predators[i], {x=mx,y=my}) < 50 then
                table.remove(predators, i)
                show_msg("Lightning strikes!")
            end
        end
    elseif m == "heal" then
        for _, t in ipairs(tribes) do
            if dist(t, {x=mx,y=my}) < 60 then t.hp = clamp(t.hp + 40, 0, 100) end
        end
        show_msg("Tribe healed")
    elseif m == "spawn_food" then
        food_supply = food_supply + 8
        show_msg("+8 food spawned")
    end
end

function lurek.mousepressed(mx, my, btn)
    if btn ~= 1 then return end
    -- miracle buttons
    for i, m in ipairs(MIRACLES) do
        local bx = 10 + (i-1) * 100
        if mx > bx and mx < bx + 90 and my > H - 35 and my < H - 5 then
            selected_miracle = i; return
        end
    end
    -- build temple
    if btn == 1 and lurek.keyboard.isDown("t") then
        if faith >= 30 then
            faith = faith - 30
            temples[#temples+1] = {x=mx, y=my}
            show_msg("Temple built!")
        else show_msg("Need 30 faith for temple") end
        return
    end
    do_miracle(mx, my)
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    if key == "1" then selected_miracle = 1 end
    if key == "2" then selected_miracle = 2 end
    if key == "3" then selected_miracle = 3 end
    if key == "4" then selected_miracle = 4 end
end

function lurek.render()
    -- terrain
    for y = 1, ROWS do
        for x = 1, COLS do
            local c = TERRAIN_COLORS[world[y][x]]
            local bright = is_night and 0.4 or 1
            lurek.gfx.setColor(c[1]*bright, c[2]*bright, c[3]*bright, 1)
            lurek.gfx.rectangle("fill", (x-1)*TILE, (y-1)*TILE, TILE, TILE)
        end
    end

    -- temples
    for _, tp in ipairs(temples) do
        lurek.gfx.setColor(1,0.85,0.3,1)
        local verts = {tp.x, tp.y-12, tp.x-8, tp.y+6, tp.x+8, tp.y+6}
        lurek.gfx.polygon("fill", verts)
    end

    -- prey (deer)
    lurek.gfx.setColor(0.6,0.45,0.2,1)
    for _, pr in ipairs(prey) do lurek.gfx.circle("fill", pr.x, pr.y, 4) end

    -- predators (wolves)
    lurek.gfx.setColor(0.5,0.1,0.1,1)
    for _, p in ipairs(predators) do lurek.gfx.circle("fill", p.x, p.y, 5) end

    -- tribes
    for _, t in ipairs(tribes) do
        local g = t.hp / 100
        lurek.gfx.setColor(0.2, 0.2 + g * 0.6, 1, 1)
        lurek.gfx.circle("fill", t.x, t.y, 5)
    end

    -- storms
    for _, s in ipairs(storms) do
        lurek.gfx.setColor(0.7,0.7,1, 0.3)
        lurek.gfx.circle("fill", s.x, s.y, s.r)
        lurek.gfx.setColor(1,1,0.5,0.8)
        lurek.gfx.line(s.x, s.y - 20, s.x + 5, s.y + 10)
    end

    -- night overlay
    if is_night then
        lurek.gfx.setColor(0, 0, 0.1, 0.35)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
    end

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.6)
    lurek.gfx.rectangle("fill", 0, 0, W, 30)
    lurek.gfx.setColor(1,1,1,1)
    lurek.gfx.print("Day " .. day_count .. (is_night and " (Night)" or ""), 10, 5, 0.9)
    lurek.gfx.print("Faith: " .. math.floor(faith), 150, 5, 0.9)
    lurek.gfx.print("Food: " .. math.floor(food_supply), 290, 5, 0.9)
    lurek.gfx.print("Pop: " .. #tribes, 400, 5, 0.9)
    lurek.gfx.print("Wolves: " .. #predators .. "  Deer: " .. #prey, 490, 5, 0.9)
    lurek.gfx.print("FPS: " .. lurek.time.getFPS(), 720, 5, 0.8)

    -- miracle bar
    lurek.gfx.setColor(0, 0, 0, 0.7)
    lurek.gfx.rectangle("fill", 0, H - 40, W, 40)
    for i, m in ipairs(MIRACLES) do
        local bx = 10 + (i-1) * 100
        if i == selected_miracle then
            lurek.gfx.setColor(1,1,0.3,0.4)
            lurek.gfx.rectangle("fill", bx, H-35, 90, 30)
        end
        lurek.gfx.setColor(1,1,1,1)
        lurek.gfx.print(m .. "(" .. MIRACLE_COST[m] .. ")", bx+5, H-28, 0.8)
    end
    lurek.gfx.setColor(0.7,0.7,0.7,1)
    lurek.gfx.print("[T+click] Build Temple(30)  [1-4] Select  [R] Restart", 420, H-28, 0.7)

    -- message
    if message and msg_timer > 0 then
        lurek.gfx.setColor(1,1,0.5,1)
        lurek.gfx.print(message, 300, 50, 1.1)
    end
end
