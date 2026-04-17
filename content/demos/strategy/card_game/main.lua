-- Card Game (CCG)
-- Controls: Click card in hand to play it, Enter to end turn, Escape to quit
-- Defeat the AI opponent by reducing their HP to 0!
-- Run with: cargo run -- content/demos/strategy/card_game

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600
local CARD_W, CARD_H = 80, 110

local allCards = {
    { name = "Slash",    cost = 1, atk = 3, kind = "attack", color = {0.8, 0.2, 0.2} },
    { name = "Fireball", cost = 3, atk = 6, kind = "attack", color = {1.0, 0.5, 0.1} },
    { name = "Arrow",   cost = 2, atk = 4, kind = "attack", color = {0.4, 0.7, 0.2} },
    { name = "Heal",    cost = 2, atk = 0, kind = "heal",   color = {0.2, 0.8, 0.6} },
    { name = "Shield",  cost = 1, atk = 0, kind = "shield", color = {0.3, 0.4, 0.9} },
    { name = "Bolt",    cost = 1, atk = 2, kind = "attack", color = {0.9, 0.9, 0.3} },
    { name = "Smash",   cost = 4, atk = 8, kind = "attack", color = {0.6, 0.1, 0.1} },
    { name = "Drain",   cost = 3, atk = 4, kind = "drain",  color = {0.5, 0.1, 0.6} },
}

local player, enemy
local turn = "player"
local phase = "play"  -- play or wait
local turnNum = 0
local log = {}
local gameOver = false
local waitTimer = 0

local function copyCard(c)
    return { name = c.name, cost = c.cost, atk = c.atk, kind = c.kind, color = {c.color[1], c.color[2], c.color[3]} }
end

local function makeDeck()
    local deck = {}
    -- Build 3 copies of every card definition into the deck
    for i = 1, 3 do
        for _, c in ipairs(allCards) do
            table.insert(deck, copyCard(c))
        end
    end
    -- Fisher-Yates in-place shuffle
    for i = #deck, 2, -1 do
        local j = math.random(1, i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

local function drawCards(p, count)
    for i = 1, count do
        if #p.deck > 0 then
            table.insert(p.hand, table.remove(p.deck))
        end
    end
end

local function addLog(msg)
    table.insert(log, 1, msg)
    if #log > 6 then table.remove(log) end
end

function lurek.init()
    lurek.window.setTitle("Card Game")
    lurek.render.setBackgroundColor(0.1, 0.08, 0.15)
    player = { hp = 30, maxHp = 30, mana = 0, maxMana = 1, shield = 0, deck = makeDeck(), hand = {} }
    enemy  = { hp = 30, maxHp = 30, mana = 0, maxMana = 1, shield = 0, deck = makeDeck(), hand = {} }
    turnNum = 0
    nextTurn()
end

function nextTurn()
    turnNum = turnNum + 1
    turn = "player"
    phase = "play"
    -- Mana ramp: max mana grows by 1 per turn, capped at 10 (classic CCG pacing)
    player.maxMana = clamp(turnNum, 1, 10)
    enemy.maxMana = clamp(turnNum, 1, 10)
    player.mana = player.maxMana
    enemy.mana = enemy.maxMana
    player.shield = 0
    enemy.shield = 0
    drawCards(player, 2)
    drawCards(enemy, 2)
    -- Cap hand size
    while #player.hand > 7 do table.remove(player.hand) end
    while #enemy.hand > 7 do table.remove(enemy.hand) end
    addLog("--- Turn " .. turnNum .. " ---")
end

local function applyCard(card, attacker, defender)
    if card.kind == "attack" then
        local dmg = card.atk
        if defender.shield > 0 then
            local blocked = clamp(defender.shield, 0, dmg)
            defender.shield = defender.shield - blocked
            dmg = dmg - blocked
        end
        defender.hp = defender.hp - dmg
    elseif card.kind == "heal" then
        attacker.hp = clamp(attacker.hp + 5, 0, attacker.maxHp)
    elseif card.kind == "shield" then
        attacker.shield = attacker.shield + 4
    elseif card.kind == "drain" then
        defender.hp = defender.hp - card.atk
        attacker.hp = clamp(attacker.hp + 2, 0, attacker.maxHp)
    end
end

local function aiPlay()
    -- Greedy AI: sort by cost descending then play everything affordable in one pass
    local played = false
    -- Sort hand by cost descending to play expensive cards first
    table.sort(enemy.hand, function(a, b) return a.cost > b.cost end)
    for i = #enemy.hand, 1, -1 do
        local c = enemy.hand[i]
        if c.cost <= enemy.mana then
            enemy.mana = enemy.mana - c.cost
            applyCard(c, enemy, player)
            addLog("Enemy plays " .. c.name)
            table.remove(enemy.hand, i)
            played = true
        end
    end
    if not played then addLog("Enemy passes") end
    if player.hp <= 0 then
        player.hp = 0; gameOver = true; addLog("YOU LOSE!")
    end
end

function lurek.process(dt)
    if gameOver then return end
    if phase == "wait" then
        waitTimer = waitTimer - dt
        if waitTimer <= 0 then
            aiPlay()
            nextTurn()
        end
    end
end

local function drawCard(c, x, y, hovered)
    local cr, cg, cb = c.color[1], c.color[2], c.color[3]
    -- Card bg
    if hovered then
        lurek.render.setColor(cr, cg, cb, 1)
    else
        lurek.render.setColor(cr * 0.6, cg * 0.6, cb * 0.6, 1)
    end
    lurek.render.rectangle("fill", x, y, CARD_W, CARD_H)
    lurek.render.setColor(0.9, 0.9, 0.8, 1)
    lurek.render.rectangle("line", x, y, CARD_W, CARD_H)
    -- Name
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(c.name, x + 4, y + 6)
    -- Cost
    lurek.render.setColor(0.3, 0.5, 1, 1)
    lurek.render.circle("fill", x + CARD_W - 14, y + 14, 12)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(c.cost, x + CARD_W - 18, y + 7)
    -- Stats
    lurek.render.setColor(1, 0.9, 0.7, 1)
    if c.kind == "attack" or c.kind == "drain" then
        lurek.render.print("ATK:" .. c.atk, x + 6, y + 50)
    end
    lurek.render.setColor(0.7, 0.7, 0.7, 1)
    lurek.render.print(c.kind, x + 6, y + 80)
end

function lurek.render()
    local mx, my = lurek.mouse.getPosition()

    -- Enemy area
    lurek.render.setColor(0.15, 0.1, 0.1, 1)
    lurek.render.rectangle("fill", 50, 20, 700, 80)
    lurek.render.setColor(0.9, 0.3, 0.3, 1)
    lurek.render.print("ENEMY", 60, 26)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("HP: " .. enemy.hp .. "/" .. enemy.maxHp, 60, 46)
    lurek.render.print("Mana: " .. enemy.mana .. "/" .. enemy.maxMana, 60, 66)
    lurek.render.print("Shield: " .. enemy.shield, 200, 46)
    lurek.render.print("Cards: " .. #enemy.hand, 200, 66)
    -- Enemy HP bar
    lurek.render.setColor(0.3, 0.1, 0.1, 1)
    lurek.render.rectangle("fill", 340, 40, 200, 16)
    lurek.render.setColor(0.9, 0.2, 0.2, 1)
    lurek.render.rectangle("fill", 340, 40, 200 * (enemy.hp / enemy.maxHp), 16)

    -- Player area
    lurek.render.setColor(0.1, 0.1, 0.15, 1)
    lurek.render.rectangle("fill", 50, 110, 700, 80)
    lurek.render.setColor(0.3, 0.5, 1, 1)
    lurek.render.print("YOU", 60, 116)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("HP: " .. player.hp .. "/" .. player.maxHp, 60, 136)
    lurek.render.print("Mana: " .. player.mana .. "/" .. player.maxMana, 60, 156)
    lurek.render.print("Shield: " .. player.shield, 200, 136)
    lurek.render.print("Deck: " .. #player.deck, 200, 156)
    -- Player HP bar
    lurek.render.setColor(0.1, 0.1, 0.3, 1)
    lurek.render.rectangle("fill", 340, 130, 200, 16)
    lurek.render.setColor(0.2, 0.5, 1, 1)
    lurek.render.rectangle("fill", 340, 130, 200 * (player.hp / player.maxHp), 16)

    -- Log
    lurek.render.setColor(0, 0, 0, 0.5)
    lurek.render.rectangle("fill", 50, 200, 300, 120)
    for i, msg in ipairs(log) do
        lurek.render.setColor(0.8, 0.8, 0.7, clamp(1.2 - i * 0.15, 0.3, 1))
        lurek.render.print(msg, 58, 200 + (i - 1) * 18)
    end

    -- Player hand
    local handY = 440
    local handStartX = W / 2 - (#player.hand * (CARD_W + 8)) / 2
    for i, c in ipairs(player.hand) do
        local cx = handStartX + (i - 1) * (CARD_W + 8)
        local cy = handY
        local hovered = mx >= cx and mx <= cx + CARD_W and my >= cy and my <= cy + CARD_H
        if hovered then cy = cy - 12 end
        local canPlay = c.cost <= player.mana and phase == "play" and turn == "player"
        if not canPlay then
            lurek.render.setColor(0.4, 0.4, 0.4, 0.4)
            drawCard(c, cx, cy, false)
        else
            drawCard(c, cx, cy, hovered)
        end
    end

    -- Phase info
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Turn " .. turnNum .. "  [Enter] End Turn", 400, 200)

    if gameOver then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle("fill", 200, 250, 400, 80)
        lurek.render.setColor(1, 1, 0.3, 1)
        local msg = enemy.hp <= 0 and "YOU WIN!" or "YOU LOSE!"
        lurek.render.print(msg, 330, 270, 2)
    end
end

function lurek.mousepressed(x, y, button)
    if gameOver or turn ~= "player" or phase ~= "play" then return end
    local handY = 440
    local handStartX = W / 2 - (#player.hand * (CARD_W + 8)) / 2
    for i, c in ipairs(player.hand) do
        local cx = handStartX + (i - 1) * (CARD_W + 8)
        if x >= cx and x <= cx + CARD_W and y >= handY - 12 and y <= handY + CARD_H then
            if c.cost <= player.mana then
                player.mana = player.mana - c.cost
                applyCard(c, player, enemy)
                addLog("You play " .. c.name)
                table.remove(player.hand, i)
                if enemy.hp <= 0 then
                    enemy.hp = 0; gameOver = true; addLog("YOU WIN!")
                end
                return
            end
        end
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "return" and turn == "player" and phase == "play" and not gameOver then
        phase = "wait"
        waitTimer = 0.6
        addLog("You end your turn")
    end
end
