-- Simple tower defense starter
local path = {
    { x = 0,   y = 300 },
    { x = 200, y = 300 },
    { x = 200, y = 100 },
    { x = 500, y = 100 },
    { x = 500, y = 400 },
    { x = 700, y = 400 },
    { x = 700, y = 300 },
    { x = 800, y = 300 },
}

local enemies = {}
local towers  = {}
local wave = 1
local gold = 100
local lives = 10
local spawn_timer = 0
local spawn_count = 0
local TOWER_COST = 25

function luna.init()
    spawnWave()
end

function spawnWave()
    spawn_count = wave * 3
    spawn_timer = 0
end

function luna.process(dt)
    -- Spawn enemies
    if spawn_count > 0 then
        spawn_timer = spawn_timer - dt
        if spawn_timer <= 0 then
            enemies[#enemies + 1] = {
                pathIdx = 1, t = 0,
                x = path[1].x, y = path[1].y,
                hp = 30 + wave * 10, speed = 60,
            }
            spawn_count = spawn_count - 1
            spawn_timer = 0.8
        end
    end

    -- Move enemies along path
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        if e.pathIdx < #path then
            local target = path[e.pathIdx + 1]
            local dx = target.x - e.x
            local dy = target.y - e.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < 2 then
                e.pathIdx = e.pathIdx + 1
            else
                e.x = e.x + (dx / dist) * e.speed * dt
                e.y = e.y + (dy / dist) * e.speed * dt
            end
        else
            -- Reached end
            lives = lives - 1
            table.remove(enemies, i)
        end
    end

    -- Towers shoot
    for _, t in ipairs(towers) do
        t.cooldown = (t.cooldown or 0) - dt
        if t.cooldown <= 0 then
            for _, e in ipairs(enemies) do
                local dx = e.x - t.x
                local dy = e.y - t.y
                if dx * dx + dy * dy < 120 * 120 then
                    e.hp = e.hp - 15
                    t.cooldown = 0.5
                    break
                end
            end
        end
    end

    -- Remove dead enemies
    for i = #enemies, 1, -1 do
        if enemies[i].hp <= 0 then
            gold = gold + 5
            table.remove(enemies, i)
        end
    end

    -- Next wave
    if #enemies == 0 and spawn_count == 0 then
        wave = wave + 1
        spawnWave()
    end
end

function luna.render()
    luna.gfx.clear(0.1, 0.15, 0.1)

    -- Draw path
    luna.gfx.setColor(0.3, 0.3, 0.25, 1)
    for i = 1, #path - 1 do
        luna.gfx.line(path[i].x, path[i].y, path[i + 1].x, path[i + 1].y)
    end

    -- Draw towers
    for _, t in ipairs(towers) do
        luna.gfx.setColor(0.2, 0.6, 1, 1)
        luna.gfx.rectangle("fill", t.x - 12, t.y - 12, 24, 24)
    end

    -- Draw enemies
    for _, e in ipairs(enemies) do
        luna.gfx.setColor(0.9, 0.2, 0.2, 1)
        luna.gfx.circle("fill", e.x, e.y, 8)
    end

    -- UI
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("Wave: " .. wave .. "  Gold: " .. gold .. "  Lives: " .. lives, 10, 10)
    luna.gfx.print("Click to place tower (" .. TOWER_COST .. "g)", 10, 580)
end

function luna.mousepressed(x, y, btn)
    if btn == 1 and gold >= TOWER_COST then
        towers[#towers + 1] = { x = x, y = y, cooldown = 0 }
        gold = gold - TOWER_COST
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
end
