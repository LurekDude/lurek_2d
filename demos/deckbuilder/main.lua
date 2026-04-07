-- Strategic Deckbuilder (Slay the Spire style)
-- Turn-based combat with cards. Click cards to play them.
-- 3 floors with different monsters, card rewards between fights.

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600

-- ── Card Definitions ──────────────────────────────────────
local CARD_DEFS = {
    { name = "Strike",   cost = 1, type = "attack", value = 6,  desc = "Deal 6 damage" },
    { name = "Defend",   cost = 1, type = "block",  value = 5,  desc = "Gain 5 block" },
    { name = "Bash",     cost = 2, type = "attack", value = 8,  desc = "8 dmg + Vulnerable", vuln = 2 },
    { name = "Fireball", cost = 3, type = "attack", value = 12, desc = "Deal 12 damage" },
    { name = "Shield+",  cost = 1, type = "block",  value = 8,  desc = "Gain 8 block" },
    { name = "Slash",    cost = 1, type = "attack", value = 9,  desc = "Deal 9 damage" },
    { name = "Heal",     cost = 1, type = "heal",   value = 5,  desc = "Restore 5 HP" },
    { name = "Rage",     cost = 0, type = "attack", value = 3,  desc = "Deal 3 damage (free)" },
}

local MONSTERS = {
    { name = "Slime",   hp = 30, atk = 7,  intent = "attack" },
    { name = "Goblin",  hp = 45, atk = 10, intent = "attack" },
    { name = "Dragon",  hp = 65, atk = 14, intent = "attack" },
}

local player, monster, deck, draw_pile, discard, hand
local state = {}
local particles = {}
local log_messages = {}

local function make_card(def)
    local c = {}
    for k, v in pairs(def) do c[k] = v end
    return c
end

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

local function add_log(msg)
    log_messages[#log_messages + 1] = { text = msg, timer = 3 }
    if #log_messages > 5 then table.remove(log_messages, 1) end
end

local function draw_cards(n)
    for _ = 1, n do
        -- Auto-reshuffle: discard pile becomes new draw pile when draw pile is empty
        if #draw_pile == 0 then
            for _, c in ipairs(discard) do draw_pile[#draw_pile + 1] = c end
            discard = {}
            shuffle(draw_pile)
        end
        if #draw_pile > 0 and #hand < 10 then
            hand[#hand + 1] = table.remove(draw_pile)
        end
    end
end

local function start_player_turn()
    state.energy = 3
    player.block = 0
    draw_cards(5)
    state.turn = "player"
end

local function discard_hand()
    for _, c in ipairs(hand) do discard[#discard + 1] = c end
    hand = {}
end

local function start_fight(floor)
    local def = MONSTERS[floor]
    monster = { name = def.name, hp = def.hp, max_hp = def.hp, atk = def.atk, vuln = 0, block = 0 }
    draw_pile = {}
    for _, c in ipairs(deck) do draw_pile[#draw_pile + 1] = make_card(c) end
    shuffle(draw_pile)
    discard = {}
    hand = {}
    state.turn = "player"
    state.phase = "combat"
    state.anim_timer = 0
    start_player_turn()
    add_log("Floor " .. floor .. ": " .. def.name .. " appears!")
end

local function spawn_hit_particles(x, y, r, g, b)
    for _ = 1, 8 do
        local a = math.random() * math.pi * 2
        local spd = math.random(40, 150)
        particles[#particles + 1] = {
            x = x, y = y,
            vx = math.cos(a) * spd, vy = math.sin(a) * spd,
            life = 0.4 + math.random() * 0.3,
            r = r, g = g, b = b
        }
    end
end

function luna.load()
    player = { hp = 50, max_hp = 50, block = 0 }
    deck = {}
    -- starter deck: 5 strikes, 4 defends, 1 bash
    for _ = 1, 5 do deck[#deck + 1] = make_card(CARD_DEFS[1]) end
    for _ = 1, 4 do deck[#deck + 1] = make_card(CARD_DEFS[2]) end
    deck[#deck + 1] = make_card(CARD_DEFS[3])

    state.floor = 1
    state.total_floors = 3
    state.phase = "combat" -- combat / reward / gameover / victory
    state.energy = 3
    state.selected_card = nil
    state.reward_cards = {}
    state.anim_timer = 0
    log_messages = {}
    particles = {}
    start_fight(1)
end

local function play_card(idx)
    local card = hand[idx]
    if not card then return end
    if card.cost > state.energy then add_log("Not enough energy!"); return end

    state.energy = state.energy - card.cost
    table.remove(hand, idx)

    if card.type == "attack" then
        local dmg = card.value
        -- Vulnerable: target takes 50% extra damage
        if monster.vuln > 0 then dmg = math.floor(dmg * 1.5) end
        local actual = dmg - monster.block
        if actual < 0 then actual = 0 end
        monster.block = clamp(monster.block - dmg, 0, 999)
        monster.hp = monster.hp - actual
        if card.vuln then monster.vuln = monster.vuln + card.vuln end
        add_log(card.name .. " deals " .. actual .. " damage!")
        spawn_hit_particles(550, 250, 1, 0.3, 0.2)
    elseif card.type == "block" then
        player.block = player.block + card.value
        add_log(card.name .. " gains " .. card.value .. " block")
        spawn_hit_particles(180, 300, 0.3, 0.5, 1)
    elseif card.type == "heal" then
        player.hp = clamp(player.hp + card.value, 0, player.max_hp)
        add_log(card.name .. " heals " .. card.value .. " HP")
        spawn_hit_particles(180, 300, 0.3, 1, 0.3)
    end

    discard[#discard + 1] = card

    -- check monster death
    if monster.hp <= 0 then
        monster.hp = 0
        add_log(monster.name .. " defeated!")
        state.anim_timer = 1
        if state.floor >= state.total_floors then
            state.phase = "victory"
        else
            -- reward phase
            state.phase = "reward"
            state.reward_cards = {}
            local pool = {}
            for i = 4, #CARD_DEFS do pool[#pool + 1] = i end
            shuffle(pool)
            for i = 1, clamp(3, 1, #pool) do
                state.reward_cards[i] = make_card(CARD_DEFS[pool[i]])
            end
        end
    end
end

local function enemy_turn()
    state.turn = "enemy"
    monster.block = 0
    if monster.vuln > 0 then monster.vuln = monster.vuln - 1 end

    local dmg = monster.atk
    local blocked = clamp(player.block, 0, dmg)
    local actual = dmg - blocked
    player.block = player.block - blocked
    if player.block < 0 then player.block = 0 end
    player.hp = player.hp - actual
    add_log(monster.name .. " attacks for " .. actual .. " damage!")
    spawn_hit_particles(180, 300, 1, 0.2, 0.2)

    if player.hp <= 0 then
        player.hp = 0
        state.phase = "gameover"
        add_log("You have been defeated...")
        return
    end

    discard_hand()
    start_player_turn()
end

function luna.update(dt)
    -- particles
    local dead = {}
    for i, p in ipairs(particles) do
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then dead[#dead + 1] = i end
    end
    for i = #dead, 1, -1 do table.remove(particles, dead[i]) end

    -- log timers
    local dl = {}
    for i, m in ipairs(log_messages) do
        m.timer = m.timer - dt
        if m.timer <= 0 then dl[#dl + 1] = i end
    end
    for i = #dl, 1, -1 do table.remove(log_messages, dl[i]) end

    if state.anim_timer > 0 then state.anim_timer = state.anim_timer - dt end
end

function luna.mousepressed(x, y, button)
    if state.phase == "combat" and state.turn == "player" then
        -- check card clicks
        local card_w = 90
        local card_h = 120
        local total_w = #hand * (card_w + 8)
        local start_x = (W - total_w) / 2
        for i, card in ipairs(hand) do
            local cx = start_x + (i - 1) * (card_w + 8)
            local cy = H - card_h - 15
            if x >= cx and x <= cx + card_w and y >= cy and y <= cy + card_h then
                play_card(i)
                return
            end
        end
    end

    if state.phase == "reward" then
        -- check reward card clicks
        local rw = 110
        local rh = 150
        local total = #state.reward_cards * (rw + 20)
        local sx = (W - total) / 2
        for i, card in ipairs(state.reward_cards) do
            local cx = sx + (i - 1) * (rw + 20)
            local cy = H / 2 - rh / 2
            if x >= cx and x <= cx + rw and y >= cy and y <= cy + rh then
                deck[#deck + 1] = card
                add_log("Added " .. card.name .. " to deck!")
                state.floor = state.floor + 1
                start_fight(state.floor)
                return
            end
        end
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" then luna.load() end
    if key == "e" and state.phase == "combat" and state.turn == "player" then
        discard_hand()
        enemy_turn()
    end
    -- number keys to play cards
    if state.phase == "combat" and state.turn == "player" then
        local n = tonumber(key)
        if n and n >= 1 and n <= #hand then
            play_card(n)
        end
    end
end

local function draw_health_bar(x, y, w, h, hp, max_hp, r, g, b)
    luna.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    luna.graphics.rectangle("fill", x, y, w, h)
    local frac = clamp(hp / max_hp, 0, 1)
    luna.graphics.setColor(r, g, b, 1)
    luna.graphics.rectangle("fill", x + 1, y + 1, (w - 2) * frac, h - 2)
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print(hp .. "/" .. max_hp, x + w / 2 - 15, y + 1)
end

local function card_color(card)
    if card.type == "attack" then return 0.8, 0.2, 0.2 end
    if card.type == "block" then return 0.2, 0.4, 0.8 end
    if card.type == "heal" then return 0.2, 0.7, 0.3 end
    return 0.5, 0.5, 0.5
end

function luna.draw()
    luna.graphics.setBackgroundColor(0.1, 0.08, 0.12)

    if state.phase == "combat" or state.phase == "gameover" or state.phase == "victory" then
        -- floor label
        luna.graphics.setColor(0.5, 0.5, 0.6, 1)
        luna.graphics.print("Floor " .. state.floor .. "/" .. state.total_floors, W / 2 - 30, 10)

        -- player
        luna.graphics.setColor(0.3, 0.6, 0.9, 1)
        luna.graphics.rectangle("fill", 140, 240, 80, 100)
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("You", 160, 220)
        draw_health_bar(120, 350, 120, 16, player.hp, player.max_hp, 0.8, 0.2, 0.2)
        if player.block > 0 then
            luna.graphics.setColor(0.3, 0.5, 1, 1)
            luna.graphics.print("Block: " .. player.block, 140, 370)
        end

        -- monster
        if monster.hp > 0 then
            local mr = 0.7
            local mg = 0.2
            if monster.vuln > 0 then mr = 1; mg = 0.5 end
            luna.graphics.setColor(mr, mg, 0.2, 1)
            local mw = 80 + state.floor * 10
            local mh = 90 + state.floor * 10
            luna.graphics.rectangle("fill", 550 - mw / 2, 280 - mh / 2, mw, mh)
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print(monster.name, 530, 200)
            draw_health_bar(490, 350, 120, 16, monster.hp, monster.max_hp, 0.8, 0.2, 0.2)
            -- intent
            luna.graphics.setColor(1, 0.4, 0.4, 0.8)
            luna.graphics.print("Intent: " .. monster.atk .. " dmg", 500, 370)
            if monster.vuln > 0 then
                luna.graphics.setColor(1, 0.6, 0, 1)
                luna.graphics.print("Vulnerable (" .. monster.vuln .. ")", 500, 385)
            end
            if monster.block > 0 then
                luna.graphics.setColor(0.3, 0.5, 1, 1)
                luna.graphics.print("Block: " .. monster.block, 510, 400)
            end
        end

        -- energy
        luna.graphics.setColor(1, 0.9, 0.2, 1)
        luna.graphics.circle("fill", 40, H - 80, 22)
        luna.graphics.setColor(0.2, 0.15, 0, 1)
        luna.graphics.print(state.energy .. "/3", 28, H - 88)

        -- draw hand
        local card_w = 90
        local card_h = 120
        local total_w = #hand * (card_w + 8)
        local start_x = (W - total_w) / 2
        local mx, my = luna.mouse.getPosition()
        for i, card in ipairs(hand) do
            local cx = start_x + (i - 1) * (card_w + 8)
            local cy = H - card_h - 15
            local hovered = mx >= cx and mx <= cx + card_w and my >= cy and my <= cy + card_h
            if hovered then cy = cy - 10 end

            local cr, cg, cb = card_color(card)
            local playable = card.cost <= state.energy
            if not playable then cr = cr * 0.4; cg = cg * 0.4; cb = cb * 0.4 end
            luna.graphics.setColor(cr, cg, cb, 0.9)
            luna.graphics.rectangle("fill", cx, cy, card_w, card_h)
            luna.graphics.setColor(1, 1, 1, 0.3)
            luna.graphics.rectangle("line", cx, cy, card_w, card_h)

            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print(card.name, cx + 5, cy + 5)
            luna.graphics.setColor(1, 0.9, 0.2, 1)
            luna.graphics.print(card.cost .. "E", cx + card_w - 20, cy + 5)
            luna.graphics.setColor(0.85, 0.85, 0.85, 0.9)
            luna.graphics.print(card.desc, cx + 5, cy + 30, 0.7)
            -- key hint
            luna.graphics.setColor(0.7, 0.7, 0.7, 0.5)
            luna.graphics.print("[" .. i .. "]", cx + card_w / 2 - 6, cy + card_h - 18)
        end

        -- pile info
        luna.graphics.setColor(0.6, 0.6, 0.6, 0.8)
        luna.graphics.print("Draw: " .. #draw_pile, 10, H - 20)
        luna.graphics.print("Discard: " .. #discard, 10, H - 40)
        luna.graphics.print("Deck: " .. #deck, 10, H - 60)

        -- end turn hint
        if state.turn == "player" and state.phase == "combat" then
            luna.graphics.setColor(0.8, 0.8, 0.3, 0.7)
            luna.graphics.print("[E] End Turn", W - 100, H - 80)
        end
    end

    -- reward phase
    if state.phase == "reward" then
        luna.graphics.setColor(1, 1, 0.5, 1)
        luna.graphics.print("Victory! Choose a card to add:", W / 2 - 110, 60, 1.2)

        local rw = 110
        local rh = 150
        local total = #state.reward_cards * (rw + 20)
        local sx = (W - total) / 2
        local mx, my = luna.mouse.getPosition()
        for i, card in ipairs(state.reward_cards) do
            local cx = sx + (i - 1) * (rw + 20)
            local cy = H / 2 - rh / 2
            local hovered = mx >= cx and mx <= cx + rw and my >= cy and my <= cy + rh
            if hovered then cy = cy - 8 end

            local cr, cg, cb = card_color(card)
            luna.graphics.setColor(cr, cg, cb, 0.95)
            luna.graphics.rectangle("fill", cx, cy, rw, rh)
            luna.graphics.setColor(1, 1, 1, 0.4)
            luna.graphics.rectangle("line", cx, cy, rw, rh)
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print(card.name, cx + 8, cy + 10, 1.1)
            luna.graphics.setColor(1, 0.9, 0.2, 1)
            luna.graphics.print(card.cost .. " energy", cx + 8, cy + 35)
            luna.graphics.setColor(0.9, 0.9, 0.9, 0.9)
            luna.graphics.print(card.desc, cx + 8, cy + 60, 0.7)
        end
    end

    -- particles
    for _, p in ipairs(particles) do
        local a = clamp(p.life * 3, 0, 1)
        luna.graphics.setColor(p.r, p.g, p.b, a)
        luna.graphics.circle("fill", p.x, p.y, 3)
    end

    -- log
    for i, m in ipairs(log_messages) do
        local a = clamp(m.timer, 0, 1)
        luna.graphics.setColor(1, 1, 0.8, a)
        luna.graphics.print(m.text, W - 250, 10 + (i - 1) * 18, 0.8)
    end

    -- game over / victory
    if state.phase == "gameover" then
        luna.graphics.setColor(0, 0, 0, 0.6)
        luna.graphics.rectangle("fill", 0, H / 2 - 40, W, 80)
        luna.graphics.setColor(1, 0.2, 0.2, 1)
        luna.graphics.print("DEFEATED", W / 2 - 60, H / 2 - 20, 2)
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("R to restart", W / 2 - 30, H / 2 + 20)
    end
    if state.phase == "victory" then
        luna.graphics.setColor(0, 0, 0, 0.6)
        luna.graphics.rectangle("fill", 0, H / 2 - 40, W, 80)
        luna.graphics.setColor(0.3, 1, 0.3, 1)
        luna.graphics.print("VICTORY!", W / 2 - 60, H / 2 - 20, 2)
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("HP remaining: " .. player.hp .. "  |  R to replay", W / 2 - 90, H / 2 + 20)
    end

    luna.graphics.setColor(0.5, 0.5, 0.5, 0.4)
    luna.graphics.print("FPS: " .. luna.timer.getFPS(), W - 70, H - 15)
end
