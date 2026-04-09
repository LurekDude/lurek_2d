-- 2D Fighting Game Demo — Player vs AI with rounds, combos, and super meter
-- P1: WASD move, F punch, G kick, H block | Escape to quit
-- Run with: cargo run -- content/demos/action/fighting_game

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local P1, P2
local stageFloor = 520
local gravity = 1200
local roundsToWin = 2
local roundDelay = 0
local screenShake = 0
local shakeX, shakeY = 0, 0
local comboTexts = {}

local function makeFighter(x, facing)
    return {
        x = x, y = stageFloor, w = 50, h = 80, vx = 0, vy = 0,
        facing = facing, speed = 200, jumpForce = -500,
        hp = 100, maxHp = 100, super = 0, maxSuper = 100,
        state = "idle", stateTimer = 0,
        blocking = false, combo = 0, comboTimer = 0,
        wins = 0, hitCooldown = 0,
        attackBox = nil, attackDamage = 0, attackKnockback = 0,
    }
end

local function resetRound()
    P1 = makeFighter(200, 1)
    P2 = makeFighter(600, -1)
    roundDelay = 1.5
    comboTexts = {}
end

function lurek.init()
    lurek.window.setTitle("Fighting Game")
    lurek.gfx.setBackgroundColor(0.08, 0.05, 0.15)
    resetRound()
end

local function startAttack(f, kind)
    if f.state ~= "idle" and f.state ~= "walk" then return end
    if kind == "punch" then
        f.state = "punch"
        f.stateTimer = 0.2
        f.attackDamage = 8
        f.attackKnockback = 150
        f.attackBox = { ox = 40 * f.facing, oy = -30, w = 35, h = 20 }
    elseif kind == "kick" then
        f.state = "kick"
        f.stateTimer = 0.35
        f.attackDamage = 14
        f.attackKnockback = 250
        f.attackBox = { ox = 35 * f.facing, oy = -10, w = 40, h = 25 }
    elseif kind == "super" then
        f.state = "super"
        f.stateTimer = 0.5
        f.attackDamage = 30
        f.attackKnockback = 400
        f.attackBox = { ox = 45 * f.facing, oy = -40, w = 55, h = 60 }
        f.super = 0
    end
end

local function tryHit(attacker, defender)
    if attacker.attackBox == nil then return end
    if attacker.hitCooldown > 0 then return end
    local ab = attacker.attackBox
    -- Build the attack hitbox in world space: offset shifts with facing direction
    local ax = attacker.x + ab.ox - ab.w / 2
    local ay = attacker.y + ab.oy - ab.h / 2
    -- Defender hurtbox: feet at y, top at y - h
    local dx = defender.x - defender.w / 2
    local dy = defender.y - defender.h
    -- Classic AABB overlap test — no physics engine needed for fighting game hitboxes
    if ax < dx + defender.w and ax + ab.w > dx and ay < dy + defender.h and ay + ab.h > dy then
        attacker.hitCooldown = attacker.stateTimer
        if defender.blocking then
            defender.vx = attacker.facing * ab.w * 2
            attacker.super = clamp(attacker.super + 5, 0, attacker.maxSuper)
            defender.super = clamp(defender.super + 8, 0, defender.maxSuper)
        else
            defender.hp = clamp(defender.hp - attacker.attackDamage, 0, defender.maxHp)
            defender.vx = attacker.facing * attacker.attackKnockback
            attacker.combo = attacker.combo + 1
            attacker.comboTimer = 1.0
            attacker.super = clamp(attacker.super + 12, 0, attacker.maxSuper)
            if attacker.attackDamage >= 14 then
                screenShake = 0.15
            end
            if attacker.combo > 1 then
                -- Combo pop-up: a simple list of timed text entities, no retained-mode UI needed
                table.insert(comboTexts, {
                    x = defender.x, y = defender.y - 100,
                    text = attacker.combo .. " HIT!", timer = 1.0,
                })
            end
        end
    end
end

local function updateFighter(f, dt)
    -- timers
    if f.stateTimer > 0 then
        f.stateTimer = f.stateTimer - dt
        if f.stateTimer <= 0 then
            f.state = "idle"
            f.attackBox = nil
            f.hitCooldown = 0
        end
    end
    if f.comboTimer > 0 then
        f.comboTimer = f.comboTimer - dt
        if f.comboTimer <= 0 then f.combo = 0 end
    end

    -- physics
    f.vy = f.vy + gravity * dt
    f.y = f.y + f.vy * dt
    if f.y >= stageFloor then f.y = stageFloor; f.vy = 0 end
    f.x = f.x + f.vx * dt
    f.vx = f.vx * (1 - 8 * dt) -- friction
    f.x = clamp(f.x, 30, 770)
end

local function aiUpdate(ai, target, dt)
    if roundDelay > 0 then return end
    local dx = target.x - ai.x
    ai.facing = dx > 0 and 1 or -1
    local dist = math.abs(dx)

    -- approach
    if dist > 100 then
        ai.x = ai.x + ai.facing * ai.speed * 0.7 * dt
    end

    -- attack decision
    if dist < 90 then
        local r = math.random()
        if ai.super >= ai.maxSuper and r < 0.01 then
            startAttack(ai, "super")
        elseif r < 0.03 then
            startAttack(ai, "punch")
        elseif r < 0.015 then
            startAttack(ai, "kick")
        elseif r < 0.04 then
            ai.blocking = true
        else
            ai.blocking = false
        end
    else
        ai.blocking = false
    end

    -- occasional jump
    if math.random() < 0.005 and ai.y >= stageFloor then
        ai.vy = ai.jumpForce
    end
end

function lurek.process(dt)
    if roundDelay > 0 then
        roundDelay = roundDelay - dt
        return
    end

    -- P1 input
    P1.blocking = lurek.keyboard.isDown("h")
    if lurek.keyboard.isDown("a") then P1.x = P1.x - P1.speed * dt end
    if lurek.keyboard.isDown("d") then P1.x = P1.x + P1.speed * dt end
    if lurek.keyboard.isDown("w") and P1.y >= stageFloor then P1.vy = P1.jumpForce end
    P1.facing = P2.x > P1.x and 1 or -1

    -- AI
    aiUpdate(P2, P1, dt)

    -- update fighters
    updateFighter(P1, dt)
    updateFighter(P2, dt)

    -- hit detection
    tryHit(P1, P2)
    tryHit(P2, P1)

    -- screen shake
    if screenShake > 0 then
        screenShake = screenShake - dt
        shakeX = (math.random() - 0.5) * 6
        shakeY = (math.random() - 0.5) * 6
    else
        shakeX, shakeY = 0, 0
    end

    -- combo texts
    for i = #comboTexts, 1, -1 do
        local ct = comboTexts[i]
        ct.y = ct.y - dt * 40
        ct.timer = ct.timer - dt
        if ct.timer <= 0 then table.remove(comboTexts, i) end
    end

    -- round end
    if P1.hp <= 0 then
        P2.wins = P2.wins + 1
        if P2.wins >= roundsToWin then
            roundDelay = 999
        else
            resetRound()
            local w = P2.wins; P2.wins = w
        end
    elseif P2.hp <= 0 then
        P1.wins = P1.wins + 1
        if P1.wins >= roundsToWin then
            roundDelay = 999
        else
            resetRound()
            local w = P1.wins; P1.wins = w
        end
    end
end

local function drawFighter(f, r, g, b)
    local bx = f.x - f.w / 2 + shakeX
    local by = f.y - f.h + shakeY

    -- body
    lurek.gfx.setColor(r, g, b, 1)
    lurek.gfx.rectangle("fill", bx, by, f.w, f.h)

    -- blocking indicator
    if f.blocking then
        lurek.gfx.setColor(0.5, 0.5, 1, 0.4)
        lurek.gfx.rectangle("fill", bx - 4, by - 4, f.w + 8, f.h + 8)
    end

    -- attack hitbox
    if f.attackBox and f.stateTimer > 0 then
        local ab = f.attackBox
        local ax = f.x + ab.ox - ab.w / 2 + shakeX
        local ay = f.y + ab.oy - ab.h / 2 + shakeY
        if f.state == "super" then
            lurek.gfx.setColor(1, 1, 0, 0.6)
        else
            lurek.gfx.setColor(1, 0.3, 0.3, 0.4)
        end
        lurek.gfx.rectangle("fill", ax, ay, ab.w, ab.h)
    end
end

local function drawHealthBar(x, y, w, hp, maxHp, r, g, b)
    lurek.gfx.setColor(0.2, 0.2, 0.2, 1)
    lurek.gfx.rectangle("fill", x, y, w, 18)
    local ratio = hp / maxHp
    lurek.gfx.setColor(r, g, b, 1)
    lurek.gfx.rectangle("fill", x, y, w * ratio, 18)
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.rectangle("line", x, y, w, 18)
end

local function drawSuperBar(x, y, w, s, maxS)
    lurek.gfx.setColor(0.15, 0.15, 0.15, 1)
    lurek.gfx.rectangle("fill", x, y, w, 8)
    local ratio = s / maxS
    lurek.gfx.setColor(1, 1, 0, 1)
    lurek.gfx.rectangle("fill", x, y, w * ratio, 8)
end

function lurek.render()
    -- stage floor
    lurek.gfx.setColor(0.25, 0.2, 0.3, 1)
    lurek.gfx.rectangle("fill", 0, stageFloor + shakeY, 800, 80)

    -- fighters
    drawFighter(P1, 0.2, 0.5, 1)
    drawFighter(P2, 1, 0.3, 0.2)

    -- health bars
    drawHealthBar(30, 20, 300, P1.hp, P1.maxHp, 0.2, 0.7, 1)
    drawHealthBar(470, 20, 300, P2.hp, P2.maxHp, 1, 0.3, 0.2)
    drawSuperBar(30, 42, 300, P1.super, P1.maxSuper)
    drawSuperBar(470, 42, 300, P2.super, P2.maxSuper)

    -- round wins
    lurek.gfx.setColor(1, 1, 1, 1)
    for i = 1, P1.wins do
        lurek.gfx.circle("fill", 340 - i * 20, 28, 6)
    end
    for i = 1, P2.wins do
        lurek.gfx.circle("fill", 460 + i * 20, 28, 6)
    end

    -- labels
    lurek.gfx.setColor(0.5, 0.7, 1, 1)
    lurek.gfx.print("P1", 30, 5)
    lurek.gfx.setColor(1, 0.5, 0.4, 1)
    lurek.gfx.print("AI", 740, 5)
    lurek.gfx.setColor(1, 1, 1, 0.6)
    lurek.gfx.print("VS", 390, 5)

    -- combo texts
    for _, ct in ipairs(comboTexts) do
        lurek.gfx.setColor(1, 1, 0, clamp(ct.timer, 0, 1))
        lurek.gfx.print(ct.text, ct.x - 20 + shakeX, ct.y + shakeY, 1.3)
    end

    -- HUD
    lurek.gfx.setColor(1, 1, 1, 0.5)
    lurek.gfx.print("WASD: Move | F: Punch | G: Kick | H: Block | V: Super (when full)", 120, 575)

    -- round start / game over
    if roundDelay > 0 then
        lurek.gfx.setColor(0, 0, 0, 0.6)
        lurek.gfx.rectangle("fill", 250, 250, 300, 80)
        lurek.gfx.setColor(1, 1, 1, 1)
        if P1.wins >= roundsToWin then
            lurek.gfx.print("P1 WINS THE MATCH!", 300, 270, 1.3)
            lurek.gfx.print("Press R to rematch", 320, 300)
        elseif P2.wins >= roundsToWin then
            lurek.gfx.print("AI WINS THE MATCH!", 300, 270, 1.3)
            lurek.gfx.print("Press R to rematch", 320, 300)
        else
            lurek.gfx.print("ROUND " .. (P1.wins + P2.wins + 1), 340, 275, 1.5)
        end
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then P1 = nil; P2 = nil; resetRound(); P1.wins = 0; P2.wins = 0 end
    if key == "f" then startAttack(P1, "punch") end
    if key == "g" then startAttack(P1, "kick") end
    if key == "v" and P1.super >= P1.maxSuper then startAttack(P1, "super") end
end
