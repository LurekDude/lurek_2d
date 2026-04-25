-- ============================================================
-- Deckbuilder — Slay-the-Spire-style card battler
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/deckbuilder
-- ============================================================

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
    { name = "Shockwave",cost = 2, type = "attack", value = 10, desc = "Deal 10 + stun enemy", stun = 1 },
    { name = "Fortify",  cost = 1, type = "block",  value = 12, desc = "Gain 12 block" },
}

local MONSTERS = {
    { name = "Slime",   hp = 30, maxHp = 30, atk = 7,  intent = "attack" },
    { name = "Goblin",  hp = 45, maxHp = 45, atk = 10, intent = "attack" },
    { name = "Dragon",  hp = 65, maxHp = 65, atk = 14, intent = "attack" },
}

local player, monster, deck, draw_pile, discard, hand
local state = {}
local log_messages = {}

-- Particles
local hit_particles  = nil
local card_particles = nil

-- Tweens
local hp_tween_val     = { v = 1.0 }
local enemy_hp_tween   = { v = 1.0 }
local card_hover_idx   = 0

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

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
    table.insert(log_messages, { text = msg, timer = 3.0 })
    if #log_messages > 5 then table.remove(log_messages, 1) end
end

local function draw_cards(n)
    for _ = 1, n do
        if #draw_pile == 0 and #discard > 0 then
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
    local m = MONSTERS[floor] or MONSTERS[#MONSTERS]
    monster = { name = m.name, hp = m.hp, maxHp = m.maxHp, atk = m.atk, vuln = 0, block = 0, stun = 0 }
    draw_pile = {}
    discard   = {}
    hand      = {}
    state = { floor = floor, turn = "player", energy = 3, won = false, lost = false }
    for _, def in ipairs(CARD_DEFS) do
        if def.name == "Strike" or def.name == "Defend" then
            draw_pile[#draw_pile + 1] = make_card(def)
            draw_pile[#draw_pile + 1] = make_card(def)
        end
    end
    shuffle(draw_pile)
    deck = {}
    for _, def in ipairs(CARD_DEFS) do deck[#deck + 1] = make_card(def) end
    draw_cards(5)
    hp_tween_val.v   = player.hp / player.maxHp
    enemy_hp_tween.v = 1.0
end

local function reward_card()
    local pick1 = CARD_DEFS[math.random(#CARD_DEFS)]
    local pick2 = CARD_DEFS[math.random(#CARD_DEFS)]
    state.reward  = { pick1, pick2 }
    state.turn    = "reward"
end

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("end_turn",   "return")
lurek.input.bind("card1",      "1")
lurek.input.bind("card2",      "2")
lurek.input.bind("card3",      "3")
lurek.input.bind("card4",      "4")
lurek.input.bind("card5",      "5")
lurek.input.bind("pick1",      "q")
lurek.input.bind("pick2",      "e")
lurek.input.bind("confirm",    "space")
lurek.input.bind("quit",       "escape")

-- ── Init ─────────────────────────────────────────────────

-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Deckbuilder — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.06, 0.14)
    math.randomseed(os.time())

    hit_particles = lurek.particle.newSystem({
        maxParticles = 40,
        emitRate     = 0,
        lifetime     = { 0.2, 0.5 },
        speed        = { 50, 150 },
        startColor   = { 1.0, 0.3, 0.1, 1.0 },
        endColor     = { 0.8, 0.0, 0.0, 0.0 },
        startSize    = 5, endSize = 1,
        spread       = math.pi * 2,
    })

    card_particles = lurek.particle.newSystem({
        maxParticles = 20,
        emitRate     = 0,
        lifetime     = { 0.3, 0.6 },
        speed        = { 30, 80 },
        startColor   = { 0.3, 0.6, 1.0, 1.0 },
        endColor     = { 0.1, 0.3, 0.8, 0.0 },
        startSize    = 4, endSize = 1,
        spread       = math.pi * 2,
    })

    player = { hp = 50, maxHp = 50, block = 0 }
    start_fight(1)
end

-- ── Process ───────────────────────────────────────────────
function lurek.process(dt)
    if hit_particles  then hit_particles:update(dt)  end
    if card_particles then card_particles:update(dt) end

    -- Log timers
    for i = #log_messages, 1, -1 do
        log_messages[i].timer = log_messages[i].timer - dt
        if log_messages[i].timer <= 0 then table.remove(log_messages, i) end
    end

    if lurek.input.wasActionPressed("quit") then lurek.event.quit() return end

    -- Title
    if state.turn == "title" then
        if lurek.input.wasActionPressed("confirm") then
            start_fight(1)
        end
        return
    end

    -- Reward screen
    if state.turn == "reward" then
        if lurek.input.wasActionPressed("pick1") and state.reward then
            draw_pile[#draw_pile + 1] = make_card(state.reward[1])
            state.reward = nil
            state.floor  = state.floor + 1
            if state.floor > #MONSTERS then state.turn = "win" else start_fight(state.floor) end
        elseif lurek.input.wasActionPressed("pick2") and state.reward then
            draw_pile[#draw_pile + 1] = make_card(state.reward[2])
            state.reward = nil
            state.floor  = state.floor + 1
            if state.floor > #MONSTERS then state.turn = "win" else start_fight(state.floor) end
        end
        return
    end

    -- Win / lose
    if state.turn == "win" or state.turn == "lost" then
        if lurek.input.wasActionPressed("confirm") then
            player = { hp = 50, maxHp = 50, block = 0 }
            start_fight(1)
        end
        return
    end

    -- Player turn
    if state.turn == "player" then
        local card_keys = { "card1","card2","card3","card4","card5" }
        for i, key in ipairs(card_keys) do
            if lurek.input.wasActionPressed(key) and hand[i] then
                local card = hand[i]
                if state.energy >= card.cost then
                    state.energy = state.energy - card.cost
                    table.remove(hand, i)
                    discard[#discard + 1] = card

                    if card.type == "attack" then
                        local dmg = card.value
                        if monster.vuln > 0 then dmg = math.floor(dmg * 1.5) end
                        monster.hp = monster.hp - dmg
                        if hit_particles then hit_particles:emit(560, 200, 8) end
                        lurek.tween.to(enemy_hp_tween, { v = math.max(0, monster.hp / monster.maxHp) }, 0.3)
                        add_log("You deal " .. dmg .. " damage!")
                        if card.vuln then monster.vuln = (monster.vuln or 0) + card.vuln end
                        if card.stun then monster.stun = (monster.stun or 0) + card.stun end
                    elseif card.type == "block" then
                        player.block = player.block + card.value
                        if card_particles then card_particles:emit(200, 300, 6) end
                        add_log("You gain " .. card.value .. " block.")
                    elseif card.type == "heal" then
                        player.hp = math.min(player.maxHp, player.hp + card.value)
                        lurek.tween.to(hp_tween_val, { v = player.hp / player.maxHp }, 0.3)
                        add_log("You heal " .. card.value .. " HP.")
                    end

                    if monster.hp <= 0 then
                        add_log(monster.name .. " defeated!")
                        discard_hand()
                        reward_card()
                        return
                    end
                else
                    add_log("Not enough energy!")
                end
            end
        end

        if lurek.input.wasActionPressed("end_turn") then
            discard_hand()
            -- Enemy turn
            if monster.stun and monster.stun > 0 then
                monster.stun = monster.stun - 1
                add_log(monster.name .. " is stunned!")
            else
                local dmg = math.max(0, monster.atk - player.block)
                player.hp = player.hp - dmg
                lurek.tween.to(hp_tween_val, { v = math.max(0, player.hp / player.maxHp) }, 0.3)
                if hit_particles then hit_particles:emit(200, 300, 6) end
                add_log(monster.name .. " deals " .. dmg .. " damage!")
                if monster.vuln > 0 then monster.vuln = monster.vuln - 1 end
            end
            if player.hp <= 0 then
                state.turn = "lost"
                return
            end
            start_player_turn()
        end
    end
end

-- ── Render world ──────────────────────────────────────────
function lurek.draw()
    if hit_particles  then hit_particles:draw()  end
    if card_particles then card_particles:draw() end
end

-- ── Render UI ─────────────────────────────────────────────
function lurek.draw_ui()
    local t = state.turn
    if t == "win" then
        text_("YOU WIN!", 280, 220, { color = {1,0.9,0.2,1}, size = 48 })
        text_("Press SPACE to restart", 270, 310, { color = {0.7,0.7,0.7,1}, size = 18 })
        return
    end
    if t == "lost" then
        text_("DEFEATED", 260, 220, { color = {0.9,0.2,0.2,1}, size = 48 })
        text_("Press SPACE to restart", 270, 310, { color = {0.7,0.7,0.7,1}, size = 18 })
        return
    end
    if t == "reward" and state.reward then
        text_("Choose a card reward:", 260, 150, { color = {1,0.85,0.3,1}, size = 22 })
        local r = state.reward
        rect(150, 220, 180, 100, { color = {0.2,0.3,0.6,1} })
        text_("[Q] " .. r[1].name, 160, 250, { color = {1,1,1,1}, size = 16 })
        text_(r[1].desc,            160, 270, { color = {0.7,0.7,0.7,1}, size = 12 })
        rect(470, 220, 180, 100, { color = {0.2,0.3,0.6,1} })
        text_("[E] " .. r[2].name, 480, 250, { color = {1,1,1,1}, size = 16 })
        text_(r[2].desc,            480, 270, { color = {0.7,0.7,0.7,1}, size = 12 })
        return
    end

    -- Monster info
    text_(monster.name, 440, 80, { color = {0.9,0.4,0.4,1}, size = 20 })
    rect(440, 110, 240, 16, { color = {0.3,0.0,0.0,1} })
    rect(440, 110, math.floor(240 * clamp(enemy_hp_tween.v, 0, 1)), 16, { color = {0.8,0.2,0.2,1} })
    text_("HP: " .. math.max(0, monster.hp) .. "/" .. monster.maxHp, 440, 130, { color = {1,1,1,1}, size = 12 })
    if monster.vuln > 0 then text_("VULNERABLE x" .. monster.vuln, 440, 148, { color = {1,0.5,0.1,1}, size = 11 }) end
    if monster.stun and monster.stun > 0 then text_("STUNNED", 560, 148, { color = {0.3,0.8,1,1}, size = 11 }) end

    -- Player info
    rect(20, 20, 200, 14, { color = {0.2,0.0,0.0,1} })
    rect(20, 20, math.floor(200 * clamp(hp_tween_val.v, 0, 1)), 14, { color = {0.1,0.8,0.2,1} })
    text_("HP " .. math.max(0, player.hp) .. "/" .. player.maxHp, 22, 22, { color = {1,1,1,1}, size = 11 })
    text_("Block: " .. player.block, 240, 22, { color = {0.3,0.5,1,1}, size = 14 })
    text_("Energy: " .. state.energy .. "/3", 360, 22, { color = {1,0.8,0.2,1}, size = 14 })
    text_("Floor: " .. state.floor .. "/" .. #MONSTERS, 500, 22, { color = {0.6,0.6,0.8,1}, size = 14 })

    -- Hand
    local cx = 80
    for i, card in ipairs(hand) do
        local col = card.type == "attack" and {0.7,0.2,0.2,1} or card.type == "block" and {0.2,0.3,0.8,1} or {0.2,0.6,0.3,1}
        local affordable = state.energy >= card.cost
        local alpha = affordable and 1.0 or 0.5
        col[4] = alpha
        rect(cx, 450, 120, 120, { color = {0.15,0.15,0.25, alpha} })
        rect(cx, 450, 120, 4,   { color = col })
        text_("[" .. i .. "] " .. card.name, cx + 6, 460, { color = {1,1,1, alpha}, size = 13 })
        text_(card.desc, cx + 6, 482, { color = {0.7,0.7,0.7, alpha}, size = 10 })
        text_("Cost: " .. card.cost, cx + 6, 552, { color = {1,0.8,0.2, alpha}, size = 11 })
        cx = cx + 130
    end

    -- Log
    for i, msg in ipairs(log_messages) do
        local a = math.min(1.0, msg.timer)
        text_(msg.text, 20, 380 + i * 18, { color = {0.8, 0.8, 0.6, a}, size = 12 })
    end

    text_("1-5: play card  Enter: end turn  Esc: quit", 20, H - 20, { color = {0.4,0.4,0.4,1}, size = 12 })
end
