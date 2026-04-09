-- Tactical Turn-Based Battle
-- Controls: Click unit to select, click tile to move/attack, Enter to end turn, Escape to quit
-- Defeat all enemy units to win!
-- Run with: cargo run -- content/demos/strategy/tactical_battle

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local GRID = 8
local TILE = 64
local OX, OY = 80, 60
local units = {}
local selected = nil
local reachable = {}
local attackable = {}
local turn = "player"
local aiTimer = 0
local gameMessage = ""
local msgTimer = 0
local gameOver = false

local function tileAt(gx, gy)
    for i, u in ipairs(units) do
        if u.gx == gx and u.gy == gy and u.hp > 0 then return i, u end
    end
    return nil, nil
end

local function dist(a, b)
    return math.abs(a.gx - b.gx) + math.abs(a.gy - b.gy)
end

-- calcReachable: populates the `reachable` and `attackable` lists for the selected unit.
-- Movement uses a Manhattan diamond (|dx|+|dy| ≤ moveRange) — equivalent to a flat BFS
-- without terrain costs. Occupied cells are excluded so units cannot overlap.
-- Attack range is computed separately: any enemy within atkRange after the move is marked.
-- (Knights are melee range=1; archers have range=3 but lower HP and movement.)
local function calcReachable(u)
    reachable = {}
    for dx = -u.moveRange, u.moveRange do
        for dy = -u.moveRange, u.moveRange do
            if math.abs(dx) + math.abs(dy) <= u.moveRange then
                local nx, ny = u.gx + dx, u.gy + dy
                if nx >= 0 and nx < GRID and ny >= 0 and ny < GRID then
                    local _, occ = tileAt(nx, ny)
                    -- Allow the unit's own current cell (it can stay in place)
                    if not occ or (occ.gx == u.gx and occ.gy == u.gy) then
                        table.insert(reachable, { x = nx, y = ny })
                    end
                end
            end
        end
    end
    -- Attackable targets: enemies within attack range FROM the unit's current position.
    -- The player must move first, then the attack range is re-evaluated from the new position.
    attackable = {}
    for _, other in ipairs(units) do
        if other.team ~= u.team and other.hp > 0 and dist(u, other) <= u.atkRange then
            table.insert(attackable, other)
        end
    end
end

local function showMsg(msg)
    gameMessage = msg
    msgTimer = 2.0
end

local function checkWin()
    local pAlive, eAlive = false, false
    for _, u in ipairs(units) do
        if u.hp > 0 then
            if u.team == "player" then pAlive = true end
            if u.team == "enemy" then eAlive = true end
        end
    end
    if not eAlive then gameOver = true; showMsg("VICTORY!") end
    if not pAlive then gameOver = true; showMsg("DEFEAT!") end
end

local function makeUnit(gx, gy, team, class)
    local u = { gx = gx, gy = gy, team = team, class = class, moved = false }
    if class == "knight" then
        u.hp, u.maxHp, u.atk, u.moveRange, u.atkRange = 10, 10, 4, 3, 1
    else -- archer
        u.hp, u.maxHp, u.atk, u.moveRange, u.atkRange = 6, 6, 3, 2, 3
    end
    return u
end

function lurek.init()
    lurek.window.setTitle("Tactical Battle")
    lurek.gfx.setBackgroundColor(0.15, 0.12, 0.1)
    -- Player units (blue)
    table.insert(units, makeUnit(1, 5, "player", "knight"))
    table.insert(units, makeUnit(1, 2, "player", "knight"))
    table.insert(units, makeUnit(0, 3, "player", "archer"))
    table.insert(units, makeUnit(0, 4, "player", "archer"))
    -- Enemy units (red)
    table.insert(units, makeUnit(6, 2, "enemy", "knight"))
    table.insert(units, makeUnit(6, 5, "enemy", "knight"))
    table.insert(units, makeUnit(7, 3, "enemy", "archer"))
    table.insert(units, makeUnit(7, 4, "enemy", "archer"))
end

local function endTurn()
    for _, u in ipairs(units) do u.moved = false end
    if turn == "player" then
        turn = "enemy"
        aiTimer = 0.5
        selected = nil
        reachable = {}
        attackable = {}
    else
        turn = "player"
    end
end

local function aiTurn()
    -- Simple AI: each unit attacks if possible, otherwise moves toward nearest player unit
    for _, e in ipairs(units) do
        if e.team == "enemy" and e.hp > 0 and not e.moved then
            -- Try to attack
            local target = nil
            local bestDist = 999
            for _, p in ipairs(units) do
                if p.team == "player" and p.hp > 0 then
                    local d = dist(e, p)
                    if d <= e.atkRange and d < bestDist then
                        target = p
                        bestDist = d
                    end
                end
            end
            if target then
                target.hp = target.hp - e.atk
                showMsg(e.class .. " attacks " .. target.class .. " for " .. e.atk .. " dmg!")
                if target.hp <= 0 then target.hp = 0 end
            else
                -- Move toward nearest player
                local closest, closeDist = nil, 999
                for _, p in ipairs(units) do
                    if p.team == "player" and p.hp > 0 then
                        local d = dist(e, p)
                        if d < closeDist then closest = p; closeDist = d end
                    end
                end
                if closest then
                    local dx = closest.gx > e.gx and 1 or (closest.gx < e.gx and -1 or 0)
                    local dy = closest.gy > e.gy and 1 or (closest.gy < e.gy and -1 or 0)
                    local nx, ny = e.gx + dx, e.gy + dy
                    if nx >= 0 and nx < GRID and ny >= 0 and ny < GRID then
                        local _, occ = tileAt(nx, ny)
                        if not occ then e.gx, e.gy = nx, ny end
                    end
                end
            end
            e.moved = true
        end
    end
    checkWin()
    endTurn()
end

function lurek.process(dt)
    if gameOver then return end
    if msgTimer > 0 then msgTimer = msgTimer - dt end
    if turn == "enemy" then
        aiTimer = aiTimer - dt
        if aiTimer <= 0 then aiTurn() end
    end
end

function lurek.render()
    -- Grid
    for gx = 0, GRID - 1 do
        for gy = 0, GRID - 1 do
            local px, py = OX + gx * TILE, OY + gy * TILE
            if (gx + gy) % 2 == 0 then
                lurek.gfx.setColor(0.25, 0.22, 0.18, 1)
            else
                lurek.gfx.setColor(0.3, 0.27, 0.22, 1)
            end
            lurek.gfx.rectangle("fill", px, py, TILE, TILE)
            lurek.gfx.setColor(0.15, 0.12, 0.1, 1)
            lurek.gfx.rectangle("line", px, py, TILE, TILE)
        end
    end

    -- Reachable tiles
    lurek.gfx.setColor(0.2, 0.5, 0.9, 0.25)
    for _, r in ipairs(reachable) do
        lurek.gfx.rectangle("fill", OX + r.x * TILE, OY + r.y * TILE, TILE, TILE)
    end

    -- Attackable highlights
    lurek.gfx.setColor(0.9, 0.2, 0.2, 0.3)
    for _, a in ipairs(attackable) do
        lurek.gfx.rectangle("fill", OX + a.gx * TILE, OY + a.gy * TILE, TILE, TILE)
    end

    -- Units
    for i, u in ipairs(units) do
        if u.hp > 0 then
            local px = OX + u.gx * TILE + TILE / 2
            local py = OY + u.gy * TILE + TILE / 2
            -- Team color
            if u.team == "player" then
                lurek.gfx.setColor(0.2, 0.4, 0.9, 1)
            else
                lurek.gfx.setColor(0.9, 0.25, 0.2, 1)
            end
            if u.class == "knight" then
                lurek.gfx.rectangle("fill", px - 14, py - 14, 28, 28)
            else
                lurek.gfx.circle("fill", px, py, 14)
            end
            -- Selection ring
            if selected == i then
                lurek.gfx.setColor(1, 1, 0, 1)
                lurek.gfx.setLineWidth(2)
                lurek.gfx.circle("line", px, py, 20)
                lurek.gfx.setLineWidth(1)
            end
            -- HP bar
            local hpFrac = u.hp / u.maxHp
            lurek.gfx.setColor(0.2, 0.2, 0.2, 1)
            lurek.gfx.rectangle("fill", px - 14, py + 18, 28, 4)
            lurek.gfx.setColor(0.1, 0.9, 0.2, 1)
            lurek.gfx.rectangle("fill", px - 14, py + 18, 28 * hpFrac, 4)
            -- Label
            lurek.gfx.setColor(1, 1, 1, 1)
            local label = u.class == "knight" and "K" or "A"
            lurek.gfx.print(label, px - 4, py - 6)
            -- Moved indicator
            if u.moved then
                lurek.gfx.setColor(0.5, 0.5, 0.5, 0.5)
                lurek.gfx.rectangle("fill", px - 14, py - 14, 28, 28)
            end
        end
    end

    -- HUD
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Turn: " .. turn, 10, 10)
    lurek.gfx.print("[Enter] End Turn", 10, 30)
    lurek.gfx.print("K=Knight(melee)  A=Archer(ranged)", 10, 560)

    -- Message
    if msgTimer > 0 then
        lurek.gfx.setColor(1, 1, 0.5, clamp(msgTimer, 0, 1))
        lurek.gfx.print(gameMessage, 240, 10, 1.2)
    end

    if gameOver then
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.print(gameMessage, 300, 280, 2)
    end
end

function lurek.mousepressed(x, y, button)
    if gameOver or turn ~= "player" then return end
    local gx = math.floor((x - OX) / TILE)
    local gy = math.floor((y - OY) / TILE)
    if gx < 0 or gx >= GRID or gy < 0 or gy >= GRID then return end

    local ci, cu = tileAt(gx, gy)

    if selected then
        local su = units[selected]
        -- Attack enemy?
        if cu and cu.team == "enemy" and dist(su, cu) <= su.atkRange and not su.moved then
            cu.hp = cu.hp - su.atk
            showMsg(su.class .. " deals " .. su.atk .. " to " .. cu.class .. "!")
            if cu.hp <= 0 then cu.hp = 0 end
            su.moved = true
            selected = nil
            reachable = {}
            attackable = {}
            checkWin()
            return
        end
        -- Move to empty tile?
        if not cu and not su.moved then
            for _, r in ipairs(reachable) do
                if r.x == gx and r.y == gy then
                    su.gx, su.gy = gx, gy
                    su.moved = true
                    calcReachable(su) -- refresh attack range
                    if #attackable == 0 then
                        selected = nil; reachable = {}; attackable = {}
                    end
                    return
                end
            end
        end
        -- Deselect
        selected = nil; reachable = {}; attackable = {}
    end

    -- Select own unit
    if ci and cu.team == "player" and not cu.moved then
        selected = ci
        calcReachable(cu)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "return" and turn == "player" and not gameOver then endTurn() end
end
