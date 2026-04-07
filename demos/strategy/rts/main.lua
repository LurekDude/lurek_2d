-- Real-Time Strategy
-- Controls: Left-click to select units, Right-click to move/attack, B to build worker, S to build soldier, Escape to quit
-- Gather gold, build an army, destroy the enemy base!

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600
local units = {}
local buildings = {}
local resources = {}
local gold = 100
local enemyGold = 100
local selected = {}
local nextId = 1
local gameOver = false
local gameMsg = ""
local aiTimer = 0

local function newId()
    nextId = nextId + 1
    return nextId - 1
end

local function dist(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function newUnit(x, y, team, kind)
    local u = { id = newId(), x = x, y = y, team = team, kind = kind, tx = x, ty = y, target = nil }
    if kind == "worker" then
        u.hp, u.maxHp, u.atk, u.speed, u.range = 5, 5, 1, 60, 15
        u.carrying = 0
    elseif kind == "soldier" then
        u.hp, u.maxHp, u.atk, u.speed, u.range = 12, 12, 3, 80, 20
        u.carrying = 0
    end
    u.atkCd = 0
    table.insert(units, u)
    return u
end

local function newBuilding(x, y, team, kind)
    local b = { id = newId(), x = x, y = y, team = team, kind = kind }
    if kind == "base" then b.hp, b.maxHp = 50, 50 end
    table.insert(buildings, b)
    return b
end

local function newResource(x, y)
    table.insert(resources, { x = x, y = y, amount = 200, r = 12 })
end

function luna.init()
    luna.window.setTitle("RTS")
    luna.gfx.setBackgroundColor(0.12, 0.18, 0.1)
    -- Player base
    newBuilding(60, H / 2, "player", "base")
    newUnit(100, H / 2 - 20, "player", "worker")
    newUnit(100, H / 2 + 20, "player", "worker")
    newUnit(120, H / 2, "player", "soldier")
    -- Enemy base
    newBuilding(W - 60, H / 2, "enemy", "base")
    newUnit(W - 100, H / 2 - 20, "enemy", "worker")
    newUnit(W - 100, H / 2 + 20, "enemy", "worker")
    newUnit(W - 120, H / 2, "enemy", "soldier")
    -- Resources
    newResource(250, 150)
    newResource(300, 400)
    newResource(400, 280)
    newResource(500, 180)
    newResource(550, 420)
end

local function getBase(team)
    for _, b in ipairs(buildings) do
        if b.team == team and b.kind == "base" then return b end
    end
    return nil
end

local function moveToward(u, tx, ty, dt)
    local dx, dy = tx - u.x, ty - u.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > 2 then
        u.x = u.x + dx / d * u.speed * dt
        u.y = u.y + dy / d * u.speed * dt
        return false
    end
    return true
end

local function findNearestResource(u)
    local best, bestD = nil, 9999
    for _, r in ipairs(resources) do
        if r.amount > 0 then
            local d = dist(u, r)
            if d < bestD then best = r; bestD = d end
        end
    end
    return best
end

local function findNearestEnemy(u, range)
    local best, bestD = nil, range
    for _, e in ipairs(units) do
        if e.team ~= u.team and e.hp > 0 then
            local d = dist(u, e)
            if d < bestD then best = e; bestD = d end
        end
    end
    -- Also check enemy buildings
    for _, b in ipairs(buildings) do
        if b.team ~= u.team and b.hp > 0 then
            local d = dist(u, b)
            if d < bestD then best = b; bestD = d end
        end
    end
    return best
end

local function updateUnit(u, dt)
    u.atkCd = clamp(u.atkCd - dt, 0, 9)
    -- Auto-combat: attack nearby enemies
    local nearby = findNearestEnemy(u, u.range + 5)
    if nearby and u.kind == "soldier" then
        if dist(u, nearby) <= u.range then
            if u.atkCd <= 0 then
                nearby.hp = nearby.hp - u.atk
                u.atkCd = 0.8
            end
            return
        else
            moveToward(u, nearby.x, nearby.y, dt)
            return
        end
    end

    -- Worker AI for enemy
    if u.team == "enemy" and u.kind == "worker" then
        local base = getBase("enemy")
        if u.carrying >= 10 and base then
            if moveToward(u, base.x, base.y, dt) then
                enemyGold = enemyGold + u.carrying
                u.carrying = 0
            end
        else
            local res = findNearestResource(u)
            if res then
                if dist(u, res) < res.r + 8 then
                    local take = clamp(res.amount, 0, 2)
                    res.amount = res.amount - take
                    u.carrying = u.carrying + take
                else
                    moveToward(u, res.x, res.y, dt)
                end
            end
        end
        return
    end

    -- Player worker auto-harvest when near resource
    if u.kind == "worker" and u.carrying < 10 then
        for _, r in ipairs(resources) do
            if r.amount > 0 and dist(u, r) < r.r + 8 then
                local take = clamp(r.amount, 0, 2)
                r.amount = r.amount - take
                u.carrying = u.carrying + take
            end
        end
    end

    -- Player worker auto-deposit at base
    if u.kind == "worker" and u.carrying >= 10 then
        local base = getBase(u.team)
        if base and dist(u, base) < 30 then
            gold = gold + u.carrying
            u.carrying = 0
        end
    end

    -- Move toward target
    moveToward(u, u.tx, u.ty, dt)
end

local function aiUpdate(dt)
    aiTimer = aiTimer - dt
    if aiTimer > 0 then return end
    aiTimer = 3.0
    local base = getBase("enemy")
    if not base then return end
    -- Build units
    if enemyGold >= 25 then
        if math.random() > 0.4 then
            newUnit(base.x - 30, base.y + math.random(-30, 30), "enemy", "soldier")
        else
            newUnit(base.x - 30, base.y + math.random(-30, 30), "enemy", "worker")
        end
        enemyGold = enemyGold - 25
    end
    -- Send soldiers to attack
    local pBase = getBase("player")
    if pBase then
        for _, u in ipairs(units) do
            if u.team == "enemy" and u.kind == "soldier" then
                u.tx, u.ty = pBase.x, pBase.y
            end
        end
    end
end

function luna.process(dt)
    if gameOver then return end
    -- Update units
    for i = #units, 1, -1 do
        local u = units[i]
        updateUnit(u, dt)
        if u.hp <= 0 then
            -- Remove from selected
            for j = #selected, 1, -1 do
                if selected[j] == u.id then table.remove(selected, j) end
            end
            table.remove(units, i)
        end
    end
    -- Check building hp
    for i = #buildings, 1, -1 do
        if buildings[i].hp <= 0 then
            if buildings[i].team == "enemy" then gameMsg = "VICTORY!" end
            if buildings[i].team == "player" then gameMsg = "DEFEAT!" end
            gameOver = true
            table.remove(buildings, i)
        end
    end
    -- Remove depleted resources
    for i = #resources, 1, -1 do
        if resources[i].amount <= 0 then table.remove(resources, i) end
    end
    aiUpdate(dt)
end

function luna.render()
    -- Resources
    for _, r in ipairs(resources) do
        luna.gfx.setColor(1, 0.85, 0.2, 0.8)
        luna.gfx.circle("fill", r.x, r.y, r.r)
        luna.gfx.setColor(1, 1, 1, 0.7)
        luna.gfx.print(r.amount, r.x - 8, r.y - 6)
    end

    -- Buildings
    for _, b in ipairs(buildings) do
        if b.team == "player" then luna.gfx.setColor(0.2, 0.5, 1, 1)
        else luna.gfx.setColor(1, 0.3, 0.2, 1) end
        luna.gfx.rectangle("fill", b.x - 25, b.y - 25, 50, 50)
        luna.gfx.setColor(1, 1, 1, 1)
        luna.gfx.print("BASE", b.x - 16, b.y - 6)
        -- HP bar
        luna.gfx.setColor(0.2, 0.2, 0.2, 1)
        luna.gfx.rectangle("fill", b.x - 25, b.y - 32, 50, 5)
        luna.gfx.setColor(0.1, 0.9, 0.1, 1)
        luna.gfx.rectangle("fill", b.x - 25, b.y - 32, 50 * (b.hp / b.maxHp), 5)
    end

    -- Units
    for _, u in ipairs(units) do
        if u.team == "player" then
            luna.gfx.setColor(0.3, 0.6, 1, 1)
        else
            luna.gfx.setColor(1, 0.4, 0.3, 1)
        end
        local sz = u.kind == "soldier" and 8 or 6
        luna.gfx.circle("fill", u.x, u.y, sz)
        -- Worker gold indicator
        if u.kind == "worker" and u.carrying > 0 then
            luna.gfx.setColor(1, 0.9, 0.2, 1)
            luna.gfx.circle("fill", u.x, u.y - sz - 3, 3)
        end
        -- Selected ring
        for _, sid in ipairs(selected) do
            if sid == u.id then
                luna.gfx.setColor(1, 1, 0, 1)
                luna.gfx.circle("line", u.x, u.y, sz + 3)
            end
        end
        -- HP bar
        if u.hp < u.maxHp then
            luna.gfx.setColor(0.9, 0.1, 0.1, 1)
            luna.gfx.rectangle("fill", u.x - 8, u.y + sz + 2, 16 * (u.hp / u.maxHp), 2)
        end
    end

    -- HUD
    luna.gfx.setColor(0, 0, 0, 0.6)
    luna.gfx.rectangle("fill", 0, 0, W, 30)
    luna.gfx.setColor(1, 0.85, 0.2, 1)
    luna.gfx.print("Gold: " .. gold, 10, 6)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("[B] Worker (25g)  [S] Soldier (25g)  LClick:Select  RClick:Move", 180, 6)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), W - 80, 6)

    if gameOver then
        luna.gfx.setColor(0, 0, 0, 0.5)
        luna.gfx.rectangle("fill", 250, 260, 300, 60)
        luna.gfx.setColor(1, 1, 0.3, 1)
        luna.gfx.print(gameMsg, 330, 275, 2)
    end
end

function luna.mousepressed(x, y, button)
    if gameOver then return end
    if button == 1 then
        -- Select unit
        selected = {}
        for _, u in ipairs(units) do
            if u.team == "player" and dist(u, {x = x, y = y}) < 12 then
                table.insert(selected, u.id)
            end
        end
    elseif button == 2 then
        -- Right-click: move selected units
        for _, sid in ipairs(selected) do
            for _, u in ipairs(units) do
                if u.id == sid then
                    u.tx, u.ty = x, y
                end
            end
        end
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if gameOver then return end
    local base = getBase("player")
    if not base then return end
    if key == "b" and gold >= 25 then
        gold = gold - 25
        newUnit(base.x + 30, base.y + math.random(-20, 20), "player", "worker")
    end
    if key == "s" and gold >= 25 then
        gold = gold - 25
        newUnit(base.x + 30, base.y + math.random(-20, 20), "player", "soldier")
    end
end
