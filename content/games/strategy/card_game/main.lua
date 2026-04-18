-- ============================================================================
-- Card Game — Lurek2D
-- ============================================================================
-- Category : strategy
-- Source   : content/games/strategy/card_game/main.lua
-- Run with : cargo run -- content/games/strategy/card_game
-- ============================================================================
-- Turn-based strategic card battle. Play creatures and spells, manage mana,
-- defeat the AI opponent by reducing their HP to zero.
-- Controls: Mouse1 select/play, Space end turn, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local MAX_FIELD   = 5
local MAX_HAND    = 8
local START_HP    = 20
local START_MANA  = 3
local MAX_MANA    = 10
local HAND_Y      = 500
local CARD_W, CARD_H = 90, 120
local CARD_GAP    = 8
local FIELD_Y_PLAYER = 340
local FIELD_Y_ENEMY  = 120
local SLOT_W, SLOT_H = 80, 90
local SLOT_GAP    = 10
local HP_BAR_W    = 120
local HP_BAR_H    = 16

-- States
local STATE_TITLE       = "TITLE"
local STATE_PLAYER_TURN = "PLAYER_TURN"
local STATE_ENEMY_TURN  = "ENEMY_TURN"
local STATE_COMBAT      = "COMBAT"
local STATE_GAME_OVER   = "GAME_OVER"

local state = STATE_TITLE
local title_timer = 0

-- ---------------------------------------------------------------------------
-- Card definitions
-- ---------------------------------------------------------------------------
local CARD_DEFS = {
    { name = "Soldier",  type = "creature", cost = 1, atk = 2, hp = 1,  color = {0.6,0.6,0.7}, taunt = false, revive = false },
    { name = "Wolf",     type = "creature", cost = 2, atk = 3, hp = 2,  color = {0.5,0.4,0.3}, taunt = false, revive = false },
    { name = "Knight",   type = "creature", cost = 3, atk = 3, hp = 4,  color = {0.7,0.7,0.8}, taunt = false, revive = false },
    { name = "Golem",    type = "creature", cost = 5, atk = 2, hp = 8,  color = {0.4,0.5,0.4}, taunt = true,  revive = false },
    { name = "Phoenix",  type = "creature", cost = 6, atk = 4, hp = 4,  color = {0.9,0.5,0.2}, taunt = false, revive = true  },
    { name = "Dragon",   type = "creature", cost = 7, atk = 6, hp = 5,  color = {0.8,0.2,0.2}, taunt = false, revive = false },
    { name = "Shield",   type = "spell",    cost = 1, effect = "shield", color = {0.3,0.6,0.9} },
    { name = "Heal",     type = "spell",    cost = 2, effect = "heal",   color = {0.3,0.9,0.4} },
    { name = "Fireball", type = "spell",    cost = 3, effect = "fireball", color = {1.0,0.4,0.1} },
}

local function card_def_by_name(name)
    for _, d in ipairs(CARD_DEFS) do
        if d.name == name then return d end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local player = { hp = START_HP, hp_display = START_HP, mana = START_MANA, max_mana = START_MANA, deck = {}, hand = {}, field = {} }
local enemy  = { hp = START_HP, hp_display = START_HP, mana = START_MANA, max_mana = START_MANA, deck = {}, hand = {}, field = {} }

local selected_card_idx = nil  -- index in player.hand
local selected_spell    = nil  -- card table (spell waiting for target)
local combat_timer      = 0
local combat_phase      = 0    -- 0=not active, 1=player attacks, 2=enemy attacks
local turn_number       = 0
local winner            = nil  -- "player" or "enemy"

-- Particles and tweens
local particles = {}
local tweens    = {}
local shake_x, shake_y = 0, 0
local shake_timer = 0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

local function spawn_particles(x, y, r, g, b, count)
    for i = 1, (count or 8) do
        local angle = math.random() * math.pi * 2
        local speed = 40 + math.random() * 80
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.5 + math.random() * 0.5,
            max_life = 1.0,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
        })
    end
end

local function add_tween(target, field, from, to, duration)
    target[field] = from
    table.insert(tweens, {
        target = target, field = field,
        from = from, to = to,
        elapsed = 0, duration = duration,
    })
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

local function update_tweens(dt)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = clamp(tw.elapsed / tw.duration, 0, 1)
        -- ease out quad
        local eased = 1 - (1 - t) * (1 - t)
        tw.target[tw.field] = tw.from + (tw.to - tw.from) * eased
        if tw.elapsed >= tw.duration then
            tw.target[tw.field] = tw.to
            table.remove(tweens, i)
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Deck building
-- ---------------------------------------------------------------------------
local function build_deck()
    local deck = {}
    -- 20 cards: 3x Soldier, 3x Wolf, 2x Knight, 2x Golem, 1x Phoenix, 1x Dragon, 3x Shield, 3x Heal, 2x Fireball
    local composition = {
        { "Soldier", 3 }, { "Wolf", 3 }, { "Knight", 2 }, { "Golem", 2 },
        { "Phoenix", 1 }, { "Dragon", 1 }, { "Shield", 3 }, { "Heal", 3 }, { "Fireball", 2 },
    }
    for _, entry in ipairs(composition) do
        local def = card_def_by_name(entry[1])
        for n = 1, entry[2] do
            local card = {
                name = def.name, type = def.type, cost = def.cost,
                color = { def.color[1], def.color[2], def.color[3] },
            }
            if def.type == "creature" then
                card.atk = def.atk
                card.hp = def.hp
                card.max_hp = def.hp
                card.taunt = def.taunt
                card.revive = def.revive
                card.revived = false
                card.can_attack = false
                card.slide_x = 0
            elseif def.type == "spell" then
                card.effect = def.effect
            end
            table.insert(deck, card)
        end
    end
    shuffle(deck)
    return deck
end

local function draw_card(who)
    if #who.deck == 0 then return false end
    if #who.hand >= MAX_HAND then return false end
    local card = table.remove(who.deck)
    card.hand_y_offset = -40
    add_tween(card, "hand_y_offset", -40, 0, 0.3)
    table.insert(who.hand, card)
    return true
end

-- ---------------------------------------------------------------------------
-- Game reset
-- ---------------------------------------------------------------------------
local function reset_game()
    player.hp = START_HP
    player.hp_display = START_HP
    player.mana = START_MANA
    player.max_mana = START_MANA
    player.deck = build_deck()
    player.hand = {}
    player.field = {}

    enemy.hp = START_HP
    enemy.hp_display = START_HP
    enemy.mana = START_MANA
    enemy.max_mana = START_MANA
    enemy.deck = build_deck()
    enemy.hand = {}
    enemy.field = {}

    selected_card_idx = nil
    selected_spell = nil
    combat_timer = 0
    combat_phase = 0
    turn_number = 0
    winner = nil
    particles = {}
    tweens = {}
    shake_x, shake_y = 0, 0
    shake_timer = 0

    -- Initial hand: 5 cards each
    for i = 1, 5 do
        draw_card(player)
        draw_card(enemy)
    end
end

-- ---------------------------------------------------------------------------
-- Damage and death
-- ---------------------------------------------------------------------------
local function apply_damage_to_player(who, amount)
    who.hp = who.hp - amount
    add_tween(who, "hp_display", who.hp_display, who.hp, 0.4)
    shake_timer = 0.2
    if who.hp <= 0 then
        who.hp = 0
    end
end

local function remove_dead_creatures(who)
    local i = 1
    while i <= #who.field do
        local c = who.field[i]
        if c.hp <= 0 then
            -- Check Phoenix revive
            if c.revive and not c.revived then
                c.hp = math.ceil(c.max_hp / 2)
                c.revived = true
                spawn_particles(0, 0, 0.9, 0.5, 0.2, 12)  -- position set during render
                i = i + 1
            else
                spawn_particles(0, 0, c.color[1], c.color[2], c.color[3], 10)
                table.remove(who.field, i)
            end
        else
            i = i + 1
        end
    end
end

local function check_game_over()
    if player.hp <= 0 then
        winner = "enemy"
        state = STATE_GAME_OVER
        return true
    end
    if enemy.hp <= 0 then
        winner = "player"
        state = STATE_GAME_OVER
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Playing cards
-- ---------------------------------------------------------------------------
local function play_creature(who, card_idx)
    if #who.field >= MAX_FIELD then return false end
    local card = table.remove(who.hand, card_idx)
    who.mana = who.mana - card.cost
    card.can_attack = false  -- summoning sickness
    card.slide_x = 0
    add_tween(card, "slide_x", -60, 0, 0.25)
    table.insert(who.field, card)
    -- Play glow particles
    spawn_particles(400, 300, card.color[1], card.color[2], card.color[3], 8)
    return true
end

local function play_spell_fireball(caster, target_creature, target_owner)
    if target_creature then
        target_creature.hp = target_creature.hp - 3
        spawn_particles(400, 250, 1.0, 0.4, 0.1, 14)
        remove_dead_creatures(target_owner)
    else
        -- Hit player/enemy directly
        if caster == player then
            apply_damage_to_player(enemy, 3)
        else
            apply_damage_to_player(player, 3)
        end
        spawn_particles(400, 100, 1.0, 0.4, 0.1, 14)
    end
end

local function play_spell_heal(caster)
    caster.hp = math.min(caster.hp + 5, START_HP)
    add_tween(caster, "hp_display", caster.hp_display, caster.hp, 0.4)
    spawn_particles(100, 500, 0.3, 0.9, 0.4, 10)
end

local function play_spell_shield(target_creature)
    if target_creature then
        target_creature.hp = target_creature.hp + 3
        target_creature.max_hp = target_creature.max_hp + 3
        spawn_particles(400, 340, 0.3, 0.6, 0.9, 8)
    end
end

-- ---------------------------------------------------------------------------
-- Combat resolution
-- ---------------------------------------------------------------------------
local function has_taunt(who)
    for _, c in ipairs(who.field) do
        if c.taunt and c.hp > 0 then return true end
    end
    return false
end

local function resolve_creature_attack(attacker_c, defender_field, defender_player)
    if not attacker_c.can_attack then return end
    attacker_c.can_attack = false

    -- Must attack taunt creatures first
    local target = nil
    if has_taunt({ field = defender_field }) then
        for _, c in ipairs(defender_field) do
            if c.taunt and c.hp > 0 then
                target = c
                break
            end
        end
    elseif #defender_field > 0 then
        -- Attack strongest creature (by atk)
        local best_atk = -1
        for _, c in ipairs(defender_field) do
            if c.hp > 0 and c.atk > best_atk then
                best_atk = c.atk
                target = c
            end
        end
    end

    if target then
        -- Simultaneous combat
        target.hp = target.hp - attacker_c.atk
        attacker_c.hp = attacker_c.hp - target.atk
        -- Damage number particles
        spawn_particles(400, 230, 1.0, 0.3, 0.3, 6)
        shake_timer = 0.15
    else
        -- Attack player directly
        apply_damage_to_player(defender_player, attacker_c.atk)
        spawn_particles(400, 50, 1.0, 0.2, 0.2, 8)
    end
end

-- ---------------------------------------------------------------------------
-- AI logic
-- ---------------------------------------------------------------------------
local function ai_play_cards()
    -- Sort hand by cost descending, play what we can afford
    local playable = true
    while playable do
        playable = false
        -- Find highest-cost affordable card
        local best_idx = nil
        local best_cost = -1
        for i, card in ipairs(enemy.hand) do
            if card.cost <= enemy.mana and card.cost > best_cost then
                if card.type == "creature" and #enemy.field >= MAX_FIELD then
                    -- skip if field full
                else
                    best_cost = card.cost
                    best_idx = i
                    playable = true
                end
            end
        end
        if best_idx then
            local card = enemy.hand[best_idx]
            if card.type == "creature" then
                play_creature(enemy, best_idx)
            elseif card.type == "spell" then
                enemy.mana = enemy.mana - card.cost
                table.remove(enemy.hand, best_idx)
                if card.effect == "fireball" then
                    -- Target strongest player creature, or player
                    local target = nil
                    local best_atk = -1
                    for _, c in ipairs(player.field) do
                        if c.atk > best_atk then
                            best_atk = c.atk
                            target = c
                        end
                    end
                    play_spell_fireball(enemy, target, player)
                elseif card.effect == "heal" then
                    play_spell_heal(enemy)
                elseif card.effect == "shield" then
                    -- Shield weakest creature
                    local weakest = nil
                    local min_hp = 9999
                    for _, c in ipairs(enemy.field) do
                        if c.hp < min_hp then
                            min_hp = c.hp
                            weakest = c
                        end
                    end
                    play_spell_shield(weakest)
                end
            end
        end
    end
end

local function ai_attack()
    for _, c in ipairs(enemy.field) do
        resolve_creature_attack(c, player.field, player)
    end
    remove_dead_creatures(player)
    remove_dead_creatures(enemy)
end

-- ---------------------------------------------------------------------------
-- Turn management
-- ---------------------------------------------------------------------------
local function start_player_turn()
    turn_number = turn_number + 1
    player.max_mana = math.min(player.max_mana + 1, MAX_MANA)
    player.mana = player.max_mana
    draw_card(player)
    -- Allow creatures to attack
    for _, c in ipairs(player.field) do
        c.can_attack = true
    end
    selected_card_idx = nil
    selected_spell = nil
    state = STATE_PLAYER_TURN
    -- Mana fill tween visual cue
    spawn_particles(70, 570, 0.3, 0.4, 0.9, 6)
end

local function start_enemy_turn()
    state = STATE_ENEMY_TURN
    enemy.max_mana = math.min(enemy.max_mana + 1, MAX_MANA)
    enemy.mana = enemy.max_mana
    draw_card(enemy)
    for _, c in ipairs(enemy.field) do
        c.can_attack = true
    end
    combat_timer = 0.6  -- brief delay before AI acts
    combat_phase = 1
end

-- ---------------------------------------------------------------------------
-- Click detection helpers
-- ---------------------------------------------------------------------------
local function get_hand_card_at(mx, my)
    local count = #player.hand
    if count == 0 then return nil end
    local total_w = count * CARD_W + (count - 1) * CARD_GAP
    local start_x = (SCREEN_W - total_w) / 2
    for i, card in ipairs(player.hand) do
        local cx = start_x + (i - 1) * (CARD_W + CARD_GAP)
        local cy = HAND_Y + (card.hand_y_offset or 0)
        if mx >= cx and mx <= cx + CARD_W and my >= cy and my <= cy + CARD_H then
            return i
        end
    end
    return nil
end

local function get_field_slot_at(mx, my, field_y)
    local total_w = MAX_FIELD * SLOT_W + (MAX_FIELD - 1) * SLOT_GAP
    local start_x = (SCREEN_W - total_w) / 2
    for i = 1, MAX_FIELD do
        local sx = start_x + (i - 1) * (SLOT_W + SLOT_GAP)
        if mx >= sx and mx <= sx + SLOT_W and my >= field_y and my <= field_y + SLOT_H then
            return i
        end
    end
    return nil
end

local function get_creature_at_slot(who, slot_idx)
    if slot_idx and slot_idx <= #who.field then
        return who.field[slot_idx]
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Engine callbacks
-- ---------------------------------------------------------------------------
lurek.init(function()
    lurek.window.setTitle("Card Game — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.05, 0.1)
    lurek.timer.setTargetFPS(60)
    lurek.input.bind("select", "mouse1")
    lurek.input.bind("end_turn", "space")
    lurek.input.bind("quit", "escape")
    reset_game()
end)

lurek.ready(function()
    state = STATE_TITLE
    title_timer = 0
end)

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
lurek.process(function(dt)
    -- Shake decay
    if shake_timer > 0 then
        shake_timer = shake_timer - dt
        shake_x = (math.random() - 0.5) * 4
        shake_y = (math.random() - 0.5) * 4
    else
        shake_x, shake_y = 0, 0
    end

    update_particles(dt)
    update_tweens(dt)

    -- ===== TITLE =====
    if state == STATE_TITLE then
        title_timer = title_timer + dt
        if lurek.input.isPressed("select") or lurek.input.isPressed("end_turn") then
            reset_game()
            start_player_turn()
        end
        if lurek.input.isPressed("quit") then
            lurek.event.signal("quit")
        end
        return
    end

    -- ===== GAME OVER =====
    if state == STATE_GAME_OVER then
        if lurek.input.isPressed("select") or lurek.input.isPressed("end_turn") then
            reset_game()
            state = STATE_TITLE
            title_timer = 0
        end
        if lurek.input.isPressed("quit") then
            lurek.event.signal("quit")
        end
        return
    end

    -- ===== ENEMY TURN =====
    if state == STATE_ENEMY_TURN then
        combat_timer = combat_timer - dt
        if combat_timer <= 0 then
            if combat_phase == 1 then
                ai_play_cards()
                combat_timer = 0.5
                combat_phase = 2
            elseif combat_phase == 2 then
                ai_attack()
                combat_phase = 0
                if not check_game_over() then
                    start_player_turn()
                end
            end
        end
        return
    end

    -- ===== PLAYER TURN =====
    if state ~= STATE_PLAYER_TURN then return end

    local mx, my = lurek.input.getMousePosition()

    -- End turn
    if lurek.input.isPressed("end_turn") then
        -- Player creatures attack
        for _, c in ipairs(player.field) do
            resolve_creature_attack(c, enemy.field, enemy)
        end
        remove_dead_creatures(player)
        remove_dead_creatures(enemy)
        if not check_game_over() then
            start_enemy_turn()
        end
        return
    end

    -- Quit
    if lurek.input.isPressed("quit") then
        lurek.event.signal("quit")
        return
    end

    -- Card selection / playing
    if lurek.input.isPressed("select") then
        -- If we have a spell selected, look for target
        if selected_spell then
            if selected_spell.effect == "fireball" then
                -- Click enemy creature or enemy HP area
                local eslot = get_field_slot_at(mx, my, FIELD_Y_ENEMY)
                local target_c = get_creature_at_slot(enemy, eslot)
                if target_c then
                    player.mana = player.mana - selected_spell.cost
                    play_spell_fireball(player, target_c, enemy)
                    -- Remove from hand
                    for hi, hc in ipairs(player.hand) do
                        if hc == selected_spell then
                            table.remove(player.hand, hi)
                            break
                        end
                    end
                    if not check_game_over() then end
                elseif my < FIELD_Y_ENEMY then
                    -- Hit enemy player directly
                    player.mana = player.mana - selected_spell.cost
                    play_spell_fireball(player, nil, nil)
                    for hi, hc in ipairs(player.hand) do
                        if hc == selected_spell then
                            table.remove(player.hand, hi)
                            break
                        end
                    end
                    check_game_over()
                end
                selected_spell = nil
                selected_card_idx = nil
            elseif selected_spell.effect == "shield" then
                -- Click own creature
                local pslot = get_field_slot_at(mx, my, FIELD_Y_PLAYER)
                local target_c = get_creature_at_slot(player, pslot)
                if target_c then
                    player.mana = player.mana - selected_spell.cost
                    play_spell_shield(target_c)
                    for hi, hc in ipairs(player.hand) do
                        if hc == selected_spell then
                            table.remove(player.hand, hi)
                            break
                        end
                    end
                end
                selected_spell = nil
                selected_card_idx = nil
            end
            return
        end

        -- Check if clicking a hand card
        local hand_idx = get_hand_card_at(mx, my)
        if hand_idx then
            local card = player.hand[hand_idx]
            if card.cost > player.mana then
                -- Can't afford — flash red
                spawn_particles(400, HAND_Y, 0.9, 0.2, 0.2, 4)
            elseif card.type == "creature" then
                selected_card_idx = hand_idx
                selected_spell = nil
            elseif card.type == "spell" then
                if card.effect == "heal" then
                    -- Instant: no target needed
                    player.mana = player.mana - card.cost
                    play_spell_heal(player)
                    table.remove(player.hand, hand_idx)
                else
                    -- Needs a target
                    selected_spell = card
                    selected_card_idx = hand_idx
                end
            end
            return
        end

        -- Check if clicking player field slot to place creature
        if selected_card_idx and not selected_spell then
            local pslot = get_field_slot_at(mx, my, FIELD_Y_PLAYER)
            if pslot then
                local card = player.hand[selected_card_idx]
                if card and card.type == "creature" then
                    if play_creature(player, selected_card_idx) then
                        selected_card_idx = nil
                    end
                end
            else
                selected_card_idx = nil
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Render — battlefield (world-space with camera)
-- ---------------------------------------------------------------------------
lurek.render(function()
    if state == STATE_TITLE or state == STATE_GAME_OVER then return end

    local cam = lurek.camera.getPosition()
    local ox, oy = shake_x, shake_y

    -- Battlefield divider line
    lurek.render.drawRect(50 + ox, 240 + oy, SCREEN_W - 100, 2, 0.25, 0.2, 0.35, 0.6)

    -- Enemy field slots
    local total_w = MAX_FIELD * SLOT_W + (MAX_FIELD - 1) * SLOT_GAP
    local start_x = (SCREEN_W - total_w) / 2
    for i = 1, MAX_FIELD do
        local sx = start_x + (i - 1) * (SLOT_W + SLOT_GAP) + ox
        local sy = FIELD_Y_ENEMY + oy
        -- Slot outline
        lurek.render.drawRect(sx, sy, SLOT_W, SLOT_H, 0.15, 0.1, 0.2, 0.5)
        -- Creature
        if i <= #enemy.field then
            local c = enemy.field[i]
            local cx = sx + (c.slide_x or 0)
            -- Body
            lurek.render.drawRect(cx + 5, sy + 10, SLOT_W - 10, SLOT_H - 20, c.color[1], c.color[2], c.color[3], 0.9)
            -- Taunt indicator
            if c.taunt then
                lurek.render.drawRect(cx + 2, sy + 5, SLOT_W - 4, SLOT_H - 10, 0.4, 0.5, 0.4, 0.3)
            end
            -- HP bar
            local hp_ratio = clamp(c.hp / c.max_hp, 0, 1)
            lurek.render.drawRect(cx + 5, sy + SLOT_H - 12, SLOT_W - 10, 6, 0.2, 0.1, 0.1, 1)
            lurek.render.drawRect(cx + 5, sy + SLOT_H - 12, (SLOT_W - 10) * hp_ratio, 6, 0.2, 0.8, 0.2, 1)
        end
    end

    -- Player field slots
    for i = 1, MAX_FIELD do
        local sx = start_x + (i - 1) * (SLOT_W + SLOT_GAP) + ox
        local sy = FIELD_Y_PLAYER + oy
        -- Slot outline
        lurek.render.drawRect(sx, sy, SLOT_W, SLOT_H, 0.12, 0.1, 0.18, 0.5)
        -- Selected slot highlight
        if selected_card_idx and not selected_spell then
            lurek.render.drawRect(sx, sy, SLOT_W, SLOT_H, 0.3, 0.3, 0.5, 0.15)
        end
        -- Creature
        if i <= #player.field then
            local c = player.field[i]
            local cx = sx + (c.slide_x or 0)
            lurek.render.drawRect(cx + 5, sy + 10, SLOT_W - 10, SLOT_H - 20, c.color[1], c.color[2], c.color[3], 0.9)
            if c.taunt then
                lurek.render.drawRect(cx + 2, sy + 5, SLOT_W - 4, SLOT_H - 10, 0.4, 0.5, 0.4, 0.3)
            end
            -- Attack-ready indicator
            if c.can_attack then
                lurek.render.drawRect(cx + SLOT_W / 2 - 15, sy + 2, 20, 4, 0.9, 0.8, 0.2, 0.7)
            end
            -- HP bar
            local hp_ratio = clamp(c.hp / c.max_hp, 0, 1)
            lurek.render.drawRect(cx + 5, sy + SLOT_H - 12, SLOT_W - 10, 6, 0.2, 0.1, 0.1, 1)
            lurek.render.drawRect(cx + 5, sy + SLOT_H - 12, (SLOT_W - 10) * hp_ratio, 6, 0.2, 0.8, 0.2, 1)
        end
    end

    -- Particles (world-space)
    for _, p in ipairs(particles) do
        local alpha = clamp(p.life / p.max_life, 0, 1)
        lurek.render.drawCircle(p.x + ox, p.y + oy, p.size, p.r, p.g, p.b, alpha)
    end
end)

-- ---------------------------------------------------------------------------
-- Render UI — hand, HUD, mana, HP, title, game over
-- ---------------------------------------------------------------------------
lurek.render_ui(function()
    -- ===== TITLE =====
    if state == STATE_TITLE then
        lurek.render.drawRect(0, 0, SCREEN_W, SCREEN_H, 0.08, 0.05, 0.1, 1)
        local pulse = 0.7 + 0.3 * math.sin(title_timer * 2.5)
        lurek.render.drawText("CARD GAME", SCREEN_W / 2 - 110, 180, 36, 0.9, 0.7, 0.3, 1)
        lurek.render.drawText("PLAY YOUR HAND", SCREEN_W / 2 - 95, 240, 20, 0.7, 0.5, 0.3, pulse)
        lurek.render.drawText("Click or Space to start", SCREEN_W / 2 - 100, 340, 14, 0.5, 0.4, 0.5, 1)
        lurek.render.drawText("Mouse1: select/play  |  Space: end turn  |  Esc: quit", SCREEN_W / 2 - 210, 380, 12, 0.4, 0.35, 0.45, 1)
        lurek.render.drawText("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 12, 0.3, 0.3, 0.3, 1)
        return
    end

    -- ===== GAME OVER =====
    if state == STATE_GAME_OVER then
        lurek.render.drawRect(0, 0, SCREEN_W, SCREEN_H, 0.06, 0.03, 0.08, 1)
        if winner == "player" then
            lurek.render.drawText("VICTORY!", SCREEN_W / 2 - 80, 180, 36, 0.3, 0.9, 0.4, 1)
            lurek.render.drawText("You defeated the enemy!", SCREEN_W / 2 - 110, 240, 18, 0.5, 0.8, 0.5, 1)
        else
            lurek.render.drawText("DEFEAT", SCREEN_W / 2 - 65, 180, 36, 0.9, 0.2, 0.2, 1)
            lurek.render.drawText("The enemy destroyed you!", SCREEN_W / 2 - 115, 240, 18, 0.8, 0.4, 0.4, 1)
        end
        lurek.render.drawText("Turn " .. turn_number, SCREEN_W / 2 - 30, 290, 16, 0.6, 0.5, 0.7, 1)
        lurek.render.drawText("Click or Space to restart", SCREEN_W / 2 - 105, 380, 14, 0.5, 0.4, 0.5, 1)
        lurek.render.drawText("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 12, 0.3, 0.3, 0.3, 1)
        return
    end

    -- ===== HUD =====
    -- Turn indicator
    local turn_label = (state == STATE_PLAYER_TURN) and "YOUR TURN" or "ENEMY TURN"
    local turn_r = (state == STATE_PLAYER_TURN) and 0.3 or 0.9
    local turn_g = (state == STATE_PLAYER_TURN) and 0.8 or 0.3
    lurek.render.drawText(turn_label, SCREEN_W / 2 - 50, 8, 18, turn_r, turn_g, 0.3, 1)
    lurek.render.drawText("Turn " .. turn_number, SCREEN_W / 2 - 25, 30, 12, 0.5, 0.5, 0.6, 1)

    -- Player HP
    lurek.render.drawText("HP", 15, SCREEN_H - 85, 14, 0.8, 0.3, 0.3, 1)
    lurek.render.drawRect(40, SCREEN_H - 85, HP_BAR_W, HP_BAR_H, 0.2, 0.1, 0.1, 1)
    local p_hp_ratio = clamp(player.hp_display / START_HP, 0, 1)
    lurek.render.drawRect(40, SCREEN_H - 85, HP_BAR_W * p_hp_ratio, HP_BAR_H, 0.8, 0.2, 0.2, 1)
    lurek.render.drawText(string.format("%d/%d", math.max(0, player.hp), START_HP), 45, SCREEN_H - 84, 12, 1, 1, 1, 1)

    -- Player Mana
    lurek.render.drawText("Mana", 15, SCREEN_H - 62, 14, 0.3, 0.4, 0.9, 1)
    for i = 1, player.max_mana do
        local mx = 60 + (i - 1) * 14
        local filled = (i <= player.mana)
        if filled then
            lurek.render.drawCircle(mx, SCREEN_H - 52, 5, 0.3, 0.5, 1.0, 1)
        else
            lurek.render.drawCircle(mx, SCREEN_H - 52, 5, 0.15, 0.15, 0.3, 0.6)
        end
    end

    -- Enemy HP
    lurek.render.drawText("Enemy HP", 15, 10, 14, 0.8, 0.3, 0.3, 1)
    lurek.render.drawRect(100, 10, HP_BAR_W, HP_BAR_H, 0.2, 0.1, 0.1, 1)
    local e_hp_ratio = clamp(enemy.hp_display / START_HP, 0, 1)
    lurek.render.drawRect(100, 10, HP_BAR_W * e_hp_ratio, HP_BAR_H, 0.8, 0.2, 0.2, 1)
    lurek.render.drawText(string.format("%d/%d", math.max(0, enemy.hp), START_HP), 105, 11, 12, 1, 1, 1, 1)

    -- Enemy mana
    for i = 1, enemy.max_mana do
        local mx = 100 + (i - 1) * 14
        local filled = (i <= enemy.mana)
        if filled then
            lurek.render.drawCircle(mx, 35, 5, 0.3, 0.5, 1.0, 1)
        else
            lurek.render.drawCircle(mx, 35, 5, 0.15, 0.15, 0.3, 0.6)
        end
    end

    -- Deck counts
    lurek.render.drawText("Deck: " .. #player.deck, SCREEN_W - 90, SCREEN_H - 85, 12, 0.5, 0.5, 0.6, 1)
    lurek.render.drawText("Enemy deck: " .. #enemy.deck, SCREEN_W - 110, 10, 12, 0.5, 0.5, 0.6, 1)

    -- End Turn button hint
    if state == STATE_PLAYER_TURN then
        lurek.render.drawRect(SCREEN_W - 130, SCREEN_H - 55, 110, 30, 0.2, 0.15, 0.3, 0.8)
        lurek.render.drawText("SPACE: End Turn", SCREEN_W - 125, SCREEN_H - 50, 12, 0.8, 0.7, 0.4, 1)
    end

    -- ===== HAND =====
    local count = #player.hand
    if count > 0 then
        local total_w = count * CARD_W + (count - 1) * CARD_GAP
        local hand_start_x = (SCREEN_W - total_w) / 2
        for i, card in ipairs(player.hand) do
            local cx = hand_start_x + (i - 1) * (CARD_W + CARD_GAP)
            local cy = HAND_Y + (card.hand_y_offset or 0)
            -- Card background
            local sel = (i == selected_card_idx)
            local bg_r = sel and 0.3 or 0.12
            local bg_g = sel and 0.25 or 0.1
            local bg_b = sel and 0.4 or 0.18
            lurek.render.drawRect(cx, cy, CARD_W, CARD_H, bg_r, bg_g, bg_b, 0.95)
            -- Card border
            local affordable = (card.cost <= player.mana)
            local br = affordable and 0.4 or 0.25
            local bg2 = affordable and 0.5 or 0.2
            local bb = affordable and 0.6 or 0.25
            lurek.render.drawRect(cx, cy, CARD_W, 3, br, bg2, bb, 1)
            lurek.render.drawRect(cx, cy + CARD_H - 3, CARD_W, 3, br, bg2, bb, 1)
            -- Card color stripe
            lurek.render.drawRect(cx + 5, cy + 8, CARD_W - 10, 30, card.color[1], card.color[2], card.color[3], 0.7)
            -- Card name
            lurek.render.drawText(card.name, cx + 5, cy + 42, 11, 0.9, 0.9, 0.9, 1)
            -- Cost
            lurek.render.drawCircle(cx + CARD_W - 12, cy + 12, 8, 0.2, 0.3, 0.7, 1)
            lurek.render.drawText(tostring(card.cost), cx + CARD_W - 16, cy + 6, 12, 1, 1, 1, 1)
            -- Stats
            if card.type == "creature" then
                lurek.render.drawText(card.atk .. "/" .. card.hp, cx + 5, cy + 58, 14, 1.0, 0.9, 0.3, 1)
                if card.taunt then
                    lurek.render.drawText("taunt", cx + 5, cy + 76, 10, 0.4, 0.6, 0.4, 0.8)
                end
                if card.revive then
                    lurek.render.drawText("revive", cx + 5, cy + 76, 10, 0.9, 0.5, 0.2, 0.8)
                end
            elseif card.type == "spell" then
                lurek.render.drawText("SPELL", cx + 5, cy + 58, 10, 0.7, 0.5, 0.9, 1)
                lurek.render.drawText(card.effect, cx + 5, cy + 72, 11, 0.8, 0.8, 0.8, 0.8)
            end
            -- Mana affordability overlay
            if not affordable then
                lurek.render.drawRect(cx, cy, CARD_W, CARD_H, 0.0, 0.0, 0.0, 0.4)
            end
        end
    end

    -- Creature stats on field (UI overlay)
    local fld_total_w = MAX_FIELD * SLOT_W + (MAX_FIELD - 1) * SLOT_GAP
    local fld_start_x = (SCREEN_W - fld_total_w) / 2
    -- Enemy creatures stats
    for i, c in ipairs(enemy.field) do
        local sx = fld_start_x + (i - 1) * (SLOT_W + SLOT_GAP)
        lurek.render.drawText(c.name, sx + 3, FIELD_Y_ENEMY - 12, 9, 0.7, 0.6, 0.6, 1)
        lurek.render.drawText(c.atk .. "/" .. c.hp, sx + 3, FIELD_Y_ENEMY + SLOT_H + 2, 11, 1.0, 0.8, 0.3, 1)
    end
    -- Player creatures stats
    for i, c in ipairs(player.field) do
        local sx = fld_start_x + (i - 1) * (SLOT_W + SLOT_GAP)
        lurek.render.drawText(c.name, sx + 3, FIELD_Y_PLAYER - 12, 9, 0.7, 0.7, 0.8, 1)
        lurek.render.drawText(c.atk .. "/" .. c.hp, sx + 3, FIELD_Y_PLAYER + SLOT_H + 2, 11, 1.0, 0.8, 0.3, 1)
    end

    -- Spell targeting hint
    if selected_spell then
        local hint = ""
        if selected_spell.effect == "fireball" then
            hint = "Click enemy creature or enemy area to cast Fireball"
        elseif selected_spell.effect == "shield" then
            hint = "Click your creature to cast Shield"
        end
        lurek.render.drawText(hint, SCREEN_W / 2 - 180, HAND_Y - 20, 12, 0.9, 0.7, 0.3, 1)
    end

    -- FPS
    lurek.render.drawText("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 12, 0.3, 0.3, 0.3, 1)
end)
