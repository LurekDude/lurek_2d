-- Wargame — Tactical Tabletop with Two Armies
-- Turn-based combat on a grid with terrain, morale, and command points
-- Run with: cargo run -- content/demos/strategy/wargame

local GRID = 40
local MAP_W, MAP_H = 16, 12
local OX, OY = 40, 50

local terrain = {}  -- 0=open, 1=forest, 2=hill
local units = {}
local turn = "blue"  -- "blue" or "red"
local cp = 4         -- command points
local MAX_CP = 4
local selected = nil
local phase = "select"  -- "select", "move", "attack"
local moveRange = {}
local attackTargets = {}
local message = ""
local messageTimer = 0
local gameOver = false
local winner = ""
local combatLog = {}

local unitTypes = {
    infantry  = { hp = 4, atk = 2, move = 3, range = 1, icon = "I" },
    cavalry   = { hp = 3, atk = 3, move = 5, range = 1, icon = "C" },
    artillery = { hp = 2, atk = 4, move = 2, range = 4, icon = "A" },
}

local function addUnit(team, utype, gx, gy)
    local t = unitTypes[utype]
    table.insert(units, {
        team = team, type = utype,
        gx = gx, gy = gy,
        hp = t.hp, maxHp = t.hp,
        atk = t.atk, move = t.move, range = t.range,
        icon = t.icon, acted = false,
    })
end

local function unitAt(gx, gy)
    for i, u in ipairs(units) do
        if u.gx == gx and u.gy == gy then return i, u end
    end
    return nil, nil
end

local function dist(a, b)
    return math.abs(a.gx - b.gx) + math.abs(a.gy - b.gy)
end

local function calcMoveRange(u)
    local range = {}
    for y = 1, MAP_H do
        for x = 1, MAP_W do
            local d = math.abs(u.gx - x) + math.abs(u.gy - y)
            if d <= u.move and d > 0 then
                local _, occ = unitAt(x, y)
                if not occ then
                    range[#range + 1] = {x, y}
                end
            end
        end
    end
    return range
end

local function calcAttackTargets(u)
    local targets = {}
    local r = u.range
    -- Hill bonus: artillery and ranged units on elevated terrain gain +1 range.
    -- This makes holding the high ground a meaningful tactical decision.
    if terrain[u.gy] and terrain[u.gy][u.gx] == 2 then r = r + 1 end
    for _, other in ipairs(units) do
        if other.team ~= u.team and other.hp > 0 then
            local d = dist(u, other)
            if d <= r then
                targets[#targets + 1] = other
            end
        end
    end
    return targets
end

local function doAttack(attacker, defender)
    -- Terrain attack bonus: hills give the attacker +1 damage.
    local bonus = 0
    if terrain[attacker.gy] and terrain[attacker.gy][attacker.gx] == 2 then bonus = bonus + 1 end
    -- Terrain defence bonus: forests reduce incoming damage by 1.
    local defBonus = 0
    if terrain[defender.gy] and terrain[defender.gy][defender.gx] == 1 then defBonus = defBonus + 1 end

    -- d6 swing keeps individual combats unpredictable. The die roll is centred at 3
    -- so the expected delta is 0 — terrain bonuses are the deciding swing.
    local roll = math.random(1, 6)
    local damage = attacker.atk + bonus + roll - 3 - defBonus
    if damage < 1 then damage = 1 end  -- always deal at least 1 damage
    defender.hp = defender.hp - damage

    local log = attacker.team .. " " .. attacker.type .. " hits " .. defender.team .. " " .. defender.type .. " for " .. damage
    if defender.hp <= 0 then
        log = log .. " (DESTROYED)"
    end
    table.insert(combatLog, 1, log)
    if #combatLog > 5 then table.remove(combatLog) end

    message = log
    messageTimer = 2
end

local function morale(team)
    local alive = 0
    for _, u in ipairs(units) do
        if u.team == team and u.hp > 0 then alive = alive + 1 end
    end
    return alive
end

local function checkVictory()
    if morale("blue") == 0 then
        gameOver = true
        winner = "RED"
    elseif morale("red") == 0 then
        gameOver = true
        winner = "BLUE"
    end
end

local function endTurn()
    -- Remove dead units
    for i = #units, 1, -1 do
        if units[i].hp <= 0 then table.remove(units, i) end
    end
    checkVictory()
    if gameOver then return end

    for _, u in ipairs(units) do u.acted = false end
    selected = nil
    phase = "select"
    moveRange = {}
    attackTargets = {}

    if turn == "blue" then
        turn = "red"
        cp = MAX_CP  -- Red always gets a full 4 CP at the start of its turn
        -- Red AI: each unit costs 1 CP to act. The AI prefers attacking over
        -- moving — it charges the closest blue unit and attacks if in range,
        -- otherwise uses a greedy best-move scan (all cells within move range,
        -- pick the one with smallest remaining distance to target).
        for _, u in ipairs(units) do
            if u.team == "red" and u.hp > 0 and cp > 0 then
                local closest = nil
                local closestDist = 999
                for _, b in ipairs(units) do
                    if b.team == "blue" and b.hp > 0 then
                        local d = dist(u, b)
                        if d < closestDist then
                            closestDist = d
                            closest = b
                        end
                    end
                end
                if closest then
                    if closestDist <= u.range then
                        -- enemy in range — attack immediately and spend 1 CP
                        doAttack(u, closest)
                        cp = cp - 1
                    else
                        -- Greedy move: scan all cells within Manhattan range,
                        -- ignore occupied cells, pick the one closest to the target.
                        local bestx, besty = u.gx, u.gy
                        local bestd = closestDist
                        for dy = -u.move, u.move do
                            for dx = -u.move, u.move do
                                local nx, ny = u.gx + dx, u.gy + dy
                                if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H then
                                    if math.abs(dx) + math.abs(dy) <= u.move then
                                        local _, occ = unitAt(nx, ny)
                                        if not occ then
                                            local nd = math.abs(closest.gx - nx) + math.abs(closest.gy - ny)
                                            if nd < bestd then
                                                bestd = nd
                                                bestx, besty = nx, ny
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if bestx ~= u.gx or besty ~= u.gy then
                            u.gx, u.gy = bestx, besty
                            cp = cp - 1
                        end
                    end
                end
            end
        end
        -- Purge units destroyed during the AI's attacks before checking victory.
        for i = #units, 1, -1 do
            if units[i].hp <= 0 then table.remove(units, i) end
        end
        checkVictory()
        turn = "blue"
        cp = MAX_CP
    else
        turn = "blue"
        cp = MAX_CP
    end
end

function lurek.init()
    -- Generate terrain
    for y = 1, MAP_H do
        terrain[y] = {}
        for x = 1, MAP_W do
            local r = math.random()
            if r < 0.15 then terrain[y][x] = 1      -- forest
            elseif r < 0.22 then terrain[y][x] = 2   -- hill
            else terrain[y][x] = 0 end
        end
    end
    -- Clear spawn areas
    for y = 1, MAP_H do
        for x = 1, 3 do terrain[y][x] = 0 end
        for x = MAP_W - 2, MAP_W do terrain[y][x] = 0 end
    end

    -- Blue army (left)
    addUnit("blue", "infantry", 1, 3)
    addUnit("blue", "infantry", 1, 6)
    addUnit("blue", "cavalry", 2, 9)
    addUnit("blue", "artillery", 1, 11)
    addUnit("blue", "infantry", 2, 1)

    -- Red army (right)
    addUnit("red", "infantry", MAP_W, 4)
    addUnit("red", "infantry", MAP_W, 7)
    addUnit("red", "cavalry", MAP_W - 1, 2)
    addUnit("red", "artillery", MAP_W, 10)
    addUnit("red", "infantry", MAP_W - 1, 12)
end

function lurek.process(dt)
    if messageTimer > 0 then messageTimer = messageTimer - dt end
end

function lurek.keypressed(key)
    if key == "space" and turn == "blue" and not gameOver then endTurn() end
    if key == "escape" then
        if phase ~= "select" then
            phase = "select"
            selected = nil
            moveRange = {}
            attackTargets = {}
        else
            lurek.signal.quit()
        end
    end
    if gameOver and key == "r" then
        gameOver = false
        units = {}
        combatLog = {}
        lurek.signal.restart()
    end
end

function lurek.mousepressed(mx, my, btn)
    if gameOver or turn ~= "blue" then return end

    local gx = math.floor((mx - OX) / GRID) + 1
    local gy = math.floor((my - OY) / GRID) + 1
    if gx < 1 or gx > MAP_W or gy < 1 or gy > MAP_H then return end

    if phase == "select" then
        local idx, u = unitAt(gx, gy)
        if u and u.team == "blue" and not u.acted then
            selected = idx
            moveRange = calcMoveRange(u)
            attackTargets = calcAttackTargets(u)
            phase = "move"
        end
    elseif phase == "move" then
        if btn == 2 then
            -- Right click: attack
            local _, target = unitAt(gx, gy)
            if target and target.team == "red" then
                local u = units[selected]
                local r = u.range
                if terrain[u.gy] and terrain[u.gy][u.gx] == 2 then r = r + 1 end
                if dist(u, target) <= r and cp > 0 then
                    doAttack(u, target)
                    u.acted = true
                    cp = cp - 1
                    selected = nil
                    phase = "select"
                    moveRange = {}
                    attackTargets = {}
                end
            end
        else
            -- Left click: move
            for _, m in ipairs(moveRange) do
                if m[1] == gx and m[2] == gy and cp > 0 then
                    units[selected].gx = gx
                    units[selected].gy = gy
                    cp = cp - 1
                    -- Recalculate attacks from new position
                    attackTargets = calcAttackTargets(units[selected])
                    moveRange = calcMoveRange(units[selected])
                    if cp <= 0 then
                        units[selected].acted = true
                        selected = nil
                        phase = "select"
                        moveRange = {}
                        attackTargets = {}
                    end
                    break
                end
            end
        end
    end
end

function lurek.render()
    lurek.render.setBackgroundColor(0.12, 0.14, 0.1)

    -- Grid and terrain
    for y = 1, MAP_H do
        for x = 1, MAP_W do
            local px = OX + (x - 1) * GRID
            local py = OY + (y - 1) * GRID
            local t = terrain[y][x]
            if t == 0 then
                lurek.render.setColor(0.25, 0.3, 0.2, 1)
            elseif t == 1 then
                lurek.render.setColor(0.15, 0.35, 0.15, 1)
            elseif t == 2 then
                lurek.render.setColor(0.35, 0.3, 0.2, 1)
            end
            lurek.render.rectangle("fill", px, py, GRID - 1, GRID - 1)
            if t == 1 then
                lurek.render.setColor(0.1, 0.5, 0.1, 0.5)
                lurek.render.print("F", px + 14, py + 12)
            elseif t == 2 then
                lurek.render.setColor(0.6, 0.5, 0.3, 0.5)
                lurek.render.print("H", px + 14, py + 12)
            end
        end
    end

    -- Move range highlight
    lurek.render.setColor(0.3, 0.6, 1, 0.3)
    for _, m in ipairs(moveRange) do
        lurek.render.rectangle("fill", OX + (m[1]-1)*GRID, OY + (m[2]-1)*GRID, GRID-1, GRID-1)
    end

    -- Attack target highlight
    for _, t in ipairs(attackTargets) do
        lurek.render.setColor(1, 0.3, 0.3, 0.4)
        lurek.render.rectangle("fill", OX + (t.gx-1)*GRID, OY + (t.gy-1)*GRID, GRID-1, GRID-1)
    end

    -- Units
    for i, u in ipairs(units) do
        if u.hp > 0 then
            local px = OX + (u.gx - 1) * GRID
            local py = OY + (u.gy - 1) * GRID
            -- Team color
            if u.team == "blue" then
                lurek.render.setColor(0.2, 0.4, 0.9, 1)
            else
                lurek.render.setColor(0.9, 0.25, 0.2, 1)
            end
            lurek.render.circle("fill", px + GRID/2, py + GRID/2, GRID/2 - 4)

            -- Selected indicator
            if i == selected then
                lurek.render.setColor(1, 1, 0, 1)
                lurek.render.setLineWidth(2)
                lurek.render.circle("line", px + GRID/2, py + GRID/2, GRID/2 - 2)
                lurek.render.setLineWidth(1)
            end

            -- Icon
            lurek.render.setColor(1, 1, 1, 1)
            lurek.render.print(u.icon, px + GRID/2 - 4, py + GRID/2 - 6)

            -- HP bar
            lurek.render.setColor(0.2, 0.2, 0.2, 1)
            lurek.render.rectangle("fill", px + 4, py + GRID - 8, GRID - 8, 4)
            lurek.render.setColor(0.2, 0.9, 0.2, 1)
            lurek.render.rectangle("fill", px + 4, py + GRID - 8, (GRID - 8) * (u.hp / u.maxHp), 4)
        end
    end

    -- HUD
    lurek.render.setColor(0, 0, 0, 0.85)
    lurek.render.rectangle("fill", 0, 0, 800, 46)

    local turnColor = turn == "blue" and {0.4, 0.6, 1} or {1, 0.4, 0.3}
    lurek.render.setColor(turnColor[1], turnColor[2], turnColor[3], 1)
    lurek.render.print(turn:upper() .. " TURN", 10, 5, 1.2)

    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("CP: " .. cp .. "/" .. MAX_CP, 150, 8)
    lurek.render.print("Blue: " .. morale("blue") .. " units", 280, 8)
    lurek.render.print("Red: " .. morale("red") .. " units", 420, 8)
    lurek.render.print("[Space] End Turn  [Esc] Deselect", 10, 28)
    lurek.render.print("LClick=Move  RClick=Attack", 400, 28)

    -- Combat log
    lurek.render.setColor(0, 0, 0, 0.7)
    lurek.render.rectangle("fill", 0, 530, 800, 70)
    lurek.render.setColor(0.8, 0.8, 0.6, 1)
    for i, log in ipairs(combatLog) do
        lurek.render.print(log, 10, 530 + (i - 1) * 13)
    end

    -- Game over
    if gameOver then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", 200, 220, 400, 100)
        lurek.render.setColor(1, 1, 0.3, 1)
        lurek.render.print(winner .. " WINS!", 330, 240, 1.8)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("Press R to restart", 330, 290)
    end
end
