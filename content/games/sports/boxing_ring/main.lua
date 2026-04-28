-- ============================================================================
-- Boxing Ring — Lurek2D
-- ============================================================================
-- Category : sports
-- Source   : content/games/sports/boxing_ring/main.lua
-- Run with : cargo run -- content/games/sports/boxing_ring
-- ============================================================================
-- Side-view boxing game. 3-round match with stamina, combos, dodging, and
-- an AI opponent that scales in difficulty each round.
-- Controls: A/D move, W duck, S lean back, J jab, K hook, L uppercut,
--           Space block, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREEN_W, SCREEN_H = 800, 600
local RING_LEFT   = 100
local RING_RIGHT  = 700
local RING_FLOOR  = 420
local RING_TOP    = 160

local STATE = { TITLE = 1, FIGHT = 2, ROUND_END = 3, GAME_OVER = 4 }
local current_state = STATE.TITLE

-- Fighter dimensions
local FIGHTER_W, FIGHTER_H = 40, 70
local MOVE_SPEED = 160
local MOVE_SPEED_TIRED = 80

-- Attack definitions: damage, range, cooldown, stamina cost
local ATK = {
    JAB      = { dmg = 5,  range = 55,  cooldown = 0.20, cost = 5,  name = "jab" },
    HOOK     = { dmg = 10, range = 75,  cooldown = 0.50, cost = 10, name = "hook" },
    UPPERCUT = { dmg = 20, range = 45,  cooldown = 1.00, cost = 20, name = "uppercut" },
}

local MAX_HP      = 100
local MAX_STAMINA = 100
local STAMINA_REGEN = 15  -- per second
local BLOCK_REDUCTION = 0.80
local ROUND_TIME  = 60
local MAX_ROUNDS  = 3
local HP_RECOVERY = 0.20  -- between rounds

-- AI states
local AI = { IDLE = 1, APPROACH = 2, ATTACK = 3, RETREAT = 4, BLOCK = 5 }

-- Dodge states
local DODGE_NONE = 0
local DODGE_DUCK = 1      -- avoids jab, hook
local DODGE_LEAN = 2      -- avoids uppercut
local DODGE_DURATION = 0.35

-- Colors
local COL_RING_FLOOR = { 0.35, 0.28, 0.18 }
local COL_ROPE       = { 0.85, 0.75, 0.55 }
local COL_PLAYER     = { 0.25, 0.45, 0.85 }
local COL_PLAYER_GLV = { 0.20, 0.35, 0.70 }
local COL_OPPONENT   = { 0.85, 0.25, 0.20 }
local COL_OPP_GLV    = { 0.70, 0.18, 0.15 }
local COL_HP_GREEN   = { 0.15, 0.80, 0.25 }
local COL_HP_RED     = { 0.85, 0.15, 0.15 }
local COL_STAMINA    = { 0.90, 0.75, 0.15 }
local COL_HUD_BG     = { 0.10, 0.10, 0.12, 0.85 }
local COL_WHITE      = { 1, 1, 1 }
local COL_GOLD       = { 1, 0.85, 0.3 }
local COL_GRAY       = { 0.5, 0.5, 0.5 }

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local player = {}
local opponent = {}
local round_num   = 1
local round_timer = ROUND_TIME
local round_wins  = { 0, 0 }   -- player, opponent
local round_dmg   = { 0, 0 }   -- damage dealt this round
local total_score  = 0
local combo_count  = 0
local best_combo   = 0
local ko_winner    = nil  -- nil | "player" | "opponent"

---@type LCamera
local camera = nil

-- Particle systems
---@type LParticleSystem
local ps_impact = nil
---@type LParticleSystem
local ps_sweat  = nil
---@type LParticleSystem
local ps_ko     = nil

-- Tween state
local banner = { y = -60, alpha = 0 }
local hp_display = { player = MAX_HP, opponent = MAX_HP }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function dist_x(a, b) return math.abs(a.x - b.x) end

local function fighter_center_x(f) return f.x + FIGHTER_W * 0.5 end

local function facing_dir(from, to)
    return fighter_center_x(to) > fighter_center_x(from) and 1 or -1
end

local function reset_fighter(f, x, is_player)
    f.x = x
    f.y = RING_FLOOR - FIGHTER_H
    f.hp = MAX_HP
    f.stamina = MAX_STAMINA
    f.atk_timer = 0
    f.stagger = 0
    f.blocking = false
    f.dodge = DODGE_NONE
    f.dodge_timer = 0
    f.current_atk = nil
    f.atk_anim = 0
    f.is_player = is_player or false
end

local function init_round()
    reset_fighter(player, RING_LEFT + 40, true)
    reset_fighter(opponent, RING_RIGHT - 40 - FIGHTER_W, false)
    -- Between rounds: recover HP
    if round_num > 1 then
        player.hp   = clamp(player.hp + MAX_HP * HP_RECOVERY, 0, MAX_HP)
        opponent.hp = clamp(opponent.hp + MAX_HP * HP_RECOVERY, 0, MAX_HP)
    end
    round_timer = ROUND_TIME
    round_dmg   = { 0, 0 }
    ko_winner   = nil
    -- Tween HP display
    hp_display.player   = player.hp
    hp_display.opponent = opponent.hp
end

-- ---------------------------------------------------------------------------
-- AI Logic
-- ---------------------------------------------------------------------------
local ai_state     = AI.IDLE
local ai_timer     = 0
local ai_atk_choice = nil
local ai_block_chance = 0.15

local function ai_difficulty()
    -- Scales with round number (1-based)
    return 0.6 + (round_num - 1) * 0.2  -- 0.6, 0.8, 1.0
end

local function ai_update(dt)
    local diff = ai_difficulty()
    local dx   = dist_x(player, opponent)
    local dir  = facing_dir(opponent, player)

    opponent.blocking = false
    ai_timer = ai_timer - dt

    if ai_timer <= 0 then
        -- State transitions
        if dx > 120 then
            ai_state = AI.APPROACH
            ai_timer = 0.3 + math.random() * 0.4 / diff
        elseif dx < 50 and math.random() < 0.35 * diff then
            ai_state = AI.ATTACK
            ai_timer = 0.1
            -- Pick attack
            local r = math.random()
            if r < 0.5 then ai_atk_choice = ATK.JAB
            elseif r < 0.8 then ai_atk_choice = ATK.HOOK
            else ai_atk_choice = ATK.UPPERCUT end
        elseif dx < 80 then
            if math.random() < ai_block_chance * diff * 2 then
                ai_state = AI.BLOCK
                ai_timer = 0.4 + math.random() * 0.3
            else
                ai_state = AI.ATTACK
                ai_timer = 0.15 / diff
                ai_atk_choice = math.random() < 0.6 and ATK.JAB or ATK.HOOK
            end
        else
            if math.random() < 0.3 then
                ai_state = AI.RETREAT
                ai_timer = 0.3 + math.random() * 0.3
            else
                ai_state = AI.APPROACH
                ai_timer = 0.2
            end
        end
    end

    -- Execute state
    local speed = opponent.stamina > 0 and MOVE_SPEED or MOVE_SPEED_TIRED
    speed = speed * diff

    if ai_state == AI.APPROACH then
        opponent.x = opponent.x + dir * speed * dt
    elseif ai_state == AI.RETREAT then
        opponent.x = opponent.x - dir * speed * 0.7 * dt
    elseif ai_state == AI.BLOCK then
        opponent.blocking = true
    elseif ai_state == AI.ATTACK then
        if ai_atk_choice and opponent.atk_timer <= 0 and opponent.stamina >= ai_atk_choice.cost then
            opponent.current_atk = ai_atk_choice
            opponent.atk_timer   = ai_atk_choice.cooldown
            opponent.atk_anim    = 0.15
            opponent.stamina     = opponent.stamina - ai_atk_choice.cost
            ai_state = AI.IDLE
            ai_timer = 0.3 / diff
        end
    end

    opponent.x = clamp(opponent.x, RING_LEFT + 10, RING_RIGHT - FIGHTER_W - 10)
end

-- ---------------------------------------------------------------------------
-- Attack resolution
-- ---------------------------------------------------------------------------
local function try_hit(attacker, defender, atk_def)
    if not atk_def then return false end
    local dx = dist_x(attacker, defender)
    if dx > atk_def.range then return false end

    -- Dodge checks
    if defender.dodge == DODGE_DUCK and (atk_def == ATK.JAB or atk_def == ATK.HOOK) then
        return false  -- ducked under head shot
    end
    if defender.dodge == DODGE_LEAN and atk_def == ATK.UPPERCUT then
        return false  -- leaned away from uppercut
    end

    local dmg = atk_def.dmg
    if defender.blocking then
        dmg = math.floor(dmg * (1.0 - BLOCK_REDUCTION))
    end
    defender.hp = clamp(defender.hp - dmg, 0, MAX_HP)
    defender.stagger = 0.15

    -- Track stats
    if attacker.is_player then
        round_dmg[1] = round_dmg[1] + dmg
        combo_count = combo_count + 1
        if combo_count > best_combo then best_combo = combo_count end
        total_score = total_score + dmg + combo_count * 2
    else
        round_dmg[2] = round_dmg[2] + dmg
        combo_count = 0  -- player got hit, reset combo
    end

    -- Particles
    local hx = (attacker.x + defender.x) * 0.5 + FIGHTER_W * 0.5
    local hy = RING_FLOOR - FIGHTER_H * 0.6
    if ps_impact then ps_impact:moveTo(hx, hy) ps_impact:emit(12) end

    -- Tween HP bars
    if defender.is_player then
        lurek.tween.to(hp_display, { player = defender.hp }, 0.3)
    else
        lurek.tween.to(hp_display, { opponent = defender.hp }, 0.3)
    end

    return true
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
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
    lurek.window.setTitle("Boxing Ring — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.08)

    lurek.input.bind("left",     { "a" })
    lurek.input.bind("right",    { "d" })
    lurek.input.bind("duck",     { "w" })
    lurek.input.bind("lean",     { "s" })
    lurek.input.bind("jab",      { "j" })
    lurek.input.bind("hook",     { "k" })
    lurek.input.bind("uppercut", { "l" })
    lurek.input.bind("block",    { "space" })
    lurek.input.bind("quit",     { "escape" })

    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Particle: punch impact sparks
    ps_impact = lurek.particle.newSystem({
        maxParticles = 80, emissionRate = 0, lifetimeMin = 0.08, lifetimeMax = 0.22,
        speedMin = 100, speedMax = 240, direction = 0, spread = 6.28,
        sizes = { 3, 1 }, colors = { 1, 0.95, 0.5, 1, 1, 0.5, 0.1, 0 },
    })
    -- Particle: sweat drops
    ps_sweat = lurek.particle.newSystem({
        maxParticles = 40, emissionRate = 0, lifetimeMin = 0.2, lifetimeMax = 0.5,
        speedMin = 30, speedMax = 80, direction = -1.57, spread = 1.2,
        gravityY = 200, sizes = { 2, 1 }, colors = { 0.6, 0.8, 1, 0.8, 0.4, 0.6, 1, 0 },
    })
    -- Particle: KO stars
    ps_ko = lurek.particle.newSystem({
        maxParticles = 60, emissionRate = 0, lifetimeMin = 0.5, lifetimeMax = 1.2,
        speedMin = 40, speedMax = 120, direction = -1.57, spread = 3.14,
        sizes = { 5, 3, 1 }, colors = { 1, 1, 0.3, 1, 1, 0.8, 0.1, 0 },
    })
end

-- ---------------------------------------------------------------------------
-- Ready
-- ---------------------------------------------------------------------------
local function _ready_setup()
    round_num  = 1
    round_wins = { 0, 0 }
    total_score = 0
    combo_count = 0
    best_combo  = 0
    reset_fighter(player, RING_LEFT + 40, true)
    reset_fighter(opponent, RING_RIGHT - 40 - FIGHTER_W, false)
    hp_display.player   = MAX_HP
    hp_display.opponent = MAX_HP
end

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Update particles and tweens
    ps_impact:update(dt)
    ps_sweat:update(dt)
    ps_ko:update(dt)
    lurek.tween.update(dt)

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("jab") or lurek.input.wasActionPressed("block") then
            round_num   = 1
            round_wins  = { 0, 0 }
            total_score = 0
            combo_count = 0
            best_combo  = 0
            init_round()
            current_state = STATE.FIGHT
            banner.y = -60
            lurek.tween.to(banner, { y = SCREEN_H * 0.35 }, 0.5)
        end
        return
    end

    -- ── ROUND END ─────────────────────────────────────────────
    if current_state == STATE.ROUND_END then
        if lurek.input.wasActionPressed("jab") or lurek.input.wasActionPressed("block") then
            round_num = round_num + 1
            if round_num > MAX_ROUNDS then
                current_state = STATE.GAME_OVER
            else
                init_round()
                current_state = STATE.FIGHT
                banner.y = -60
                lurek.tween.to(banner, { y = SCREEN_H * 0.35 }, 0.5)
            end
        end
        return
    end

    -- ── GAME OVER ─────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("jab") or lurek.input.wasActionPressed("block") then
            current_state = STATE.TITLE
        end
        return
    end

    -- ── FIGHT ─────────────────────────────────────────────────
    round_timer = round_timer - dt

    -- Stamina regeneration
    player.stamina   = clamp(player.stamina + STAMINA_REGEN * dt, 0, MAX_STAMINA)
    opponent.stamina = clamp(opponent.stamina + STAMINA_REGEN * dt, 0, MAX_STAMINA)

    -- Cooldown timers
    player.atk_timer   = math.max(0, player.atk_timer - dt)
    opponent.atk_timer = math.max(0, opponent.atk_timer - dt)

    -- Stagger timers
    player.stagger   = math.max(0, player.stagger - dt)
    opponent.stagger = math.max(0, opponent.stagger - dt)

    -- Attack animation decay
    player.atk_anim   = math.max(0, player.atk_anim - dt)
    opponent.atk_anim = math.max(0, opponent.atk_anim - dt)

    -- Dodge timers
    if player.dodge_timer > 0 then
        player.dodge_timer = player.dodge_timer - dt
        if player.dodge_timer <= 0 then player.dodge = DODGE_NONE end
    end

    -- Sweat when stamina low
    if player.stamina < 25 then
        ps_sweat:moveTo(fighter_center_x(player), player.y + 5)
        ps_sweat:emit(1)
    end
    if opponent.stamina < 25 then
        ps_sweat:moveTo(fighter_center_x(opponent), opponent.y + 5)
        ps_sweat:emit(1)
    end

    -- Player movement (can't move while staggered)
    player.blocking = false
    player.current_atk = nil

    if player.stagger <= 0 then
        local speed = player.stamina > 0 and MOVE_SPEED or MOVE_SPEED_TIRED
        local dx = 0
        if lurek.input.isActionDown("left")  then dx = -1 end
        if lurek.input.isActionDown("right") then dx = 1 end
        player.x = clamp(player.x + dx * speed * dt, RING_LEFT + 10, RING_RIGHT - FIGHTER_W - 10)

        -- Blocking
        if lurek.input.isActionDown("block") then
            player.blocking = true
        end

        -- Dodging
        if player.dodge == DODGE_NONE then
            if lurek.input.wasActionPressed("duck") then
                player.dodge = DODGE_DUCK
                player.dodge_timer = DODGE_DURATION
            elseif lurek.input.wasActionPressed("lean") then
                player.dodge = DODGE_LEAN
                player.dodge_timer = DODGE_DURATION
            end
        end

        -- Attacks (can't attack while blocking)
        if not player.blocking and player.atk_timer <= 0 then
            if lurek.input.wasActionPressed("jab") and player.stamina >= ATK.JAB.cost then
                player.current_atk = ATK.JAB
                player.atk_timer   = ATK.JAB.cooldown
                player.atk_anim    = 0.12
                player.stamina     = player.stamina - ATK.JAB.cost
            elseif lurek.input.wasActionPressed("hook") and player.stamina >= ATK.HOOK.cost then
                player.current_atk = ATK.HOOK
                player.atk_timer   = ATK.HOOK.cooldown
                player.atk_anim    = 0.18
                player.stamina     = player.stamina - ATK.HOOK.cost
            elseif lurek.input.wasActionPressed("uppercut") and player.stamina >= ATK.UPPERCUT.cost then
                player.current_atk = ATK.UPPERCUT
                player.atk_timer   = ATK.UPPERCUT.cooldown
                player.atk_anim    = 0.25
                player.stamina     = player.stamina - ATK.UPPERCUT.cost
            end
        end
    end

    -- AI update
    if opponent.stagger <= 0 then
        ai_update(dt)
    end

    -- Resolve player attack
    if player.current_atk and player.atk_anim > 0.10 then
        try_hit(player, opponent, player.current_atk)
        player.current_atk = nil  -- consume
    end

    -- Resolve opponent attack
    if opponent.current_atk and opponent.atk_anim > 0.10 then
        try_hit(opponent, player, opponent.current_atk)
        opponent.current_atk = nil
    end

    -- KO check
    if player.hp <= 0 then
        ko_winner = "opponent"
        round_wins[2] = round_wins[2] + 1
        ps_ko:moveTo(fighter_center_x(player), player.y)
        ps_ko:emit(30)
        current_state = STATE.ROUND_END
        return
    end
    if opponent.hp <= 0 then
        ko_winner = "player"
        round_wins[1] = round_wins[1] + 1
        total_score = total_score + 200
        ps_ko:moveTo(fighter_center_x(opponent), opponent.y)
        ps_ko:emit(30)
        current_state = STATE.ROUND_END
        return
    end

    -- Round timer expired
    if round_timer <= 0 then
        round_timer = 0
        if round_dmg[1] >= round_dmg[2] then
            round_wins[1] = round_wins[1] + 1
            total_score = total_score + 100
        else
            round_wins[2] = round_wins[2] + 1
        end
        ko_winner = nil
        current_state = STATE.ROUND_END
    end
end

-- ---------------------------------------------------------------------------
-- Render (world space — ring and fighters)
-- ---------------------------------------------------------------------------
local function draw_ring()
    -- Floor
    rect(RING_LEFT, RING_FLOOR, RING_RIGHT - RING_LEFT, 8,
        COL_RING_FLOOR[1], COL_RING_FLOOR[2], COL_RING_FLOOR[3])
    -- Corner posts
    rect(RING_LEFT - 6, RING_TOP, 12, RING_FLOOR - RING_TOP + 8, 0.5, 0.4, 0.3)
    rect(RING_RIGHT - 6, RING_TOP, 12, RING_FLOOR - RING_TOP + 8, 0.5, 0.4, 0.3)
    -- Ropes (3 lines each side)
    for i = 1, 3 do
        local ry = RING_TOP + (RING_FLOOR - RING_TOP) * (i / 4)
        rect(RING_LEFT, ry - 1, RING_RIGHT - RING_LEFT, 3,
            COL_ROPE[1], COL_ROPE[2], COL_ROPE[3])
    end
end

local function draw_fighter(f, col_body, col_glove)
    local oy = 0
    if f.dodge == DODGE_DUCK then oy = 20 end       -- crouch offset
    if f.dodge == DODGE_LEAN then oy = -5 end

    -- Stagger shake
    local sx = 0
    if f.stagger > 0 then sx = math.sin(f.stagger * 60) * 3 end

    local fx = f.x + sx
    local fy = f.y + oy
    local bh = FIGHTER_H
    if f.dodge == DODGE_DUCK then bh = FIGHTER_H - 20 end

    -- Body
    rect(fx + 8, fy + (FIGHTER_H - bh), FIGHTER_W - 16, bh,
        col_body[1], col_body[2], col_body[3])
    -- Head
    local head_size = 16
    rect(fx + (FIGHTER_W - head_size) * 0.5, fy + (FIGHTER_H - bh) - head_size - 2, head_size, head_size,
        col_body[1] * 1.2, col_body[2] * 1.2, col_body[3] * 1.2)

    -- Gloves
    local dir = facing_dir(f, f.is_player and opponent or player)
    local glove_x = fx + (dir > 0 and FIGHTER_W or -12)
    local glove_y = fy + (FIGHTER_H - bh) + 10

    if f.atk_anim > 0 then
        -- Extend glove forward during punch
        glove_x = glove_x + dir * 20
    end
    if f.blocking then
        -- Gloves up in front
        glove_x = fx + FIGHTER_W * 0.5 - 6
        glove_y = fy + (FIGHTER_H - bh) + 2
    end

    rect(glove_x, glove_y, 12, 12,
        col_glove[1], col_glove[2], col_glove[3])
end

function lurek.draw()
    camera:attach()

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        draw_ring()
        -- Silhouette fighters
        rect(RING_LEFT + 80, RING_FLOOR - FIGHTER_H, FIGHTER_W, FIGHTER_H, 0.15, 0.25, 0.55, 0.5)
        rect(RING_RIGHT - 120, RING_FLOOR - FIGHTER_H, FIGHTER_W, FIGHTER_H, 0.55, 0.15, 0.12, 0.5)
        camera:detach()
        return
    end

    -- ── FIGHT / ROUND_END / GAME_OVER ─────────────────────────
    draw_ring()
    draw_fighter(player, COL_PLAYER, COL_PLAYER_GLV)
    draw_fighter(opponent, COL_OPPONENT, COL_OPP_GLV)

    -- Particles (world space)
    ps_impact:render()
    ps_sweat:render()
    ps_ko:render()

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI (screen space — HUD, overlays)
-- ---------------------------------------------------------------------------
local function draw_bar(x, y, w, h, value, max_val, r, g, b)
    -- Background
    rect(x, y, w, h, 0.2, 0.2, 0.2, 0.8)
    -- Fill
    local frac = clamp(value / max_val, 0, 1)
    rect(x, y, w * frac, h, r, g, b)
    -- Border
    rect(x, y, w, 1, 1, 1, 1, 0.3)
    rect(x, y + h - 1, w, 1, 1, 1, 1, 0.3)
    rect(x, y, 1, h, 1, 1, 1, 0.3)
    rect(x + w - 1, y, 1, h, 1, 1, 1, 0.3)
end

function lurek.draw_ui()
    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        text_("BOXING RING", SCREEN_W * 0.5 - 100, 140, 36, COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
        text_("FIGHT NIGHT", SCREEN_W * 0.5 - 85, 190, 22, COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
        text_("Press J or SPACE to start", SCREEN_W * 0.5 - 110, 340, 16, COL_GRAY[1], COL_GRAY[2], COL_GRAY[3])
        text_("J=Jab  K=Hook  L=Uppercut  Space=Block", SCREEN_W * 0.5 - 170, 380, 14, COL_GRAY[1], COL_GRAY[2], COL_GRAY[3])
        text_("W=Duck  S=Lean back  A/D=Move", SCREEN_W * 0.5 - 130, 405, 14, COL_GRAY[1], COL_GRAY[2], COL_GRAY[3])
        -- FPS
        text_("FPS: " .. tostring(lurek.timer.getFPS()), 10, SCREEN_H - 20, 12, 0.4, 0.4, 0.4)
        return
    end

    -- ── HUD (FIGHT + ROUND_END + GAME_OVER) ──────────────────
    -- Top bar background
    rect(0, 0, SCREEN_W, 55, COL_HUD_BG[1], COL_HUD_BG[2], COL_HUD_BG[3], COL_HUD_BG[4])

    -- Player HP (left side)
    text_("PLAYER", 10, 4, 12, COL_PLAYER[1], COL_PLAYER[2], COL_PLAYER[3])
    local hp_col = hp_display.player > 30 and COL_HP_GREEN or COL_HP_RED
    draw_bar(10, 18, 200, 14, hp_display.player, MAX_HP, hp_col[1], hp_col[2], hp_col[3])
    -- Player stamina
    draw_bar(10, 36, 160, 8, player.stamina, MAX_STAMINA, COL_STAMINA[1], COL_STAMINA[2], COL_STAMINA[3])

    -- Opponent HP (right side)
    text_("OPPONENT", SCREEN_W - 85, 4, 12, COL_OPPONENT[1], COL_OPPONENT[2], COL_OPPONENT[3])
    local ohp_col = hp_display.opponent > 30 and COL_HP_GREEN or COL_HP_RED
    draw_bar(SCREEN_W - 210, 18, 200, 14, hp_display.opponent, MAX_HP, ohp_col[1], ohp_col[2], ohp_col[3])
    -- Opponent stamina
    draw_bar(SCREEN_W - 170, 36, 160, 8, opponent.stamina, MAX_STAMINA, COL_STAMINA[1], COL_STAMINA[2], COL_STAMINA[3])

    -- Round info (center)
    text_("Round " .. round_num .. "/" .. MAX_ROUNDS, SCREEN_W * 0.5 - 35, 4, 14, COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
    local timer_str = string.format("%d", math.ceil(math.max(0, round_timer)))
    text_(timer_str, SCREEN_W * 0.5 - 8, 22, 20, COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
    -- Wins
    text_(round_wins[1] .. " - " .. round_wins[2], SCREEN_W * 0.5 - 12, 44, 10, COL_GRAY[1], COL_GRAY[2], COL_GRAY[3])

    -- Bottom bar: score, combo, FPS
    rect(0, SCREEN_H - 30, SCREEN_W, 30, COL_HUD_BG[1], COL_HUD_BG[2], COL_HUD_BG[3], COL_HUD_BG[4])
    text_("Score: " .. total_score, 10, SCREEN_H - 24, 14, COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
    if combo_count > 1 then
        text_("Combo x" .. combo_count, SCREEN_W * 0.5 - 40, SCREEN_H - 24, 14, 1, 0.5, 0.2)
    end
    text_("FPS: " .. tostring(lurek.timer.getFPS()), SCREEN_W - 80, SCREEN_H - 24, 12, 0.4, 0.4, 0.4)

    -- Dodge indicator
    if player.dodge == DODGE_DUCK then
        text_("DUCK!", player.x + 5, player.y - 20, 12, 0.3, 1, 0.3)
    elseif player.dodge == DODGE_LEAN then
        text_("LEAN!", player.x + 5, player.y - 20, 12, 0.3, 0.8, 1)
    end

    -- Block indicator
    if player.blocking then
        text_("BLOCK", player.x + 2, player.y - 20, 12, 0.9, 0.9, 0.3)
    end

    -- ── ROUND END overlay ─────────────────────────────────────
    if current_state == STATE.ROUND_END then
        rect(0, 0, SCREEN_W, SCREEN_H, 0, 0, 0, 0.5)
        if ko_winner then
            local ko_text = ko_winner == "player" and "KNOCKOUT! YOU WIN!" or "KNOCKOUT! YOU LOSE!"
            local ko_col = ko_winner == "player" and COL_HP_GREEN or COL_HP_RED
            text_(ko_text, SCREEN_W * 0.5 - 120, 200, 28, ko_col[1], ko_col[2], ko_col[3])
        else
            local rd_text = round_dmg[1] >= round_dmg[2] and "ROUND TO PLAYER!" or "ROUND TO OPPONENT!"
            text_(rd_text, SCREEN_W * 0.5 - 110, 200, 24, COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
        end
        text_("Damage: " .. round_dmg[1] .. " vs " .. round_dmg[2], SCREEN_W * 0.5 - 70, 250, 16, COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
        text_("Press J or SPACE to continue", SCREEN_W * 0.5 - 120, 310, 16, COL_GRAY[1], COL_GRAY[2], COL_GRAY[3])
    end

    -- ── GAME OVER overlay ─────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        rect(0, 0, SCREEN_W, SCREEN_H, 0, 0, 0, 0.6)
        local winner = round_wins[1] > round_wins[2] and "YOU WIN!" or (round_wins[1] < round_wins[2] and "YOU LOSE!" or "DRAW!")
        local w_col  = round_wins[1] > round_wins[2] and COL_HP_GREEN or (round_wins[1] < round_wins[2] and COL_HP_RED or COL_GOLD)
        text_("FIGHT OVER", SCREEN_W * 0.5 - 80, 160, 30, COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
        text_(winner, SCREEN_W * 0.5 - 60, 210, 28, w_col[1], w_col[2], w_col[3])
        text_("Rounds: " .. round_wins[1] .. " - " .. round_wins[2], SCREEN_W * 0.5 - 55, 260, 16, COL_WHITE[1], COL_WHITE[2], COL_WHITE[3])
        text_("Score: " .. total_score, SCREEN_W * 0.5 - 40, 290, 16, COL_GOLD[1], COL_GOLD[2], COL_GOLD[3])
        text_("Best combo: " .. best_combo, SCREEN_W * 0.5 - 55, 315, 14, 1, 0.5, 0.2)
        text_("Press J or SPACE for title", SCREEN_W * 0.5 - 110, 370, 16, COL_GRAY[1], COL_GRAY[2], COL_GRAY[3])
    end
end
