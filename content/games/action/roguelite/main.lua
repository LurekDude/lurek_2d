-- ============================================================================
--  Roguelite — Hades-style top-down action dungeon crawler
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/roguelite
--
--  Controls (bound as input actions — see lurek.init):
--    up/down/left/right : W/A/S/D or arrow keys
--    attack             : Left Click or J  (melee slash)
--    ranged             : Right Click or K (ranged projectile)
--    dash               : Shift            (invulnerable dash)
--    perk1/perk2/perk3  : 1/2/3            (perk selection)
--    restart            : R                (game over)
--    quit               : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600
local ARENA_W, ARENA_H   = 640, 480
local ARENA_X = (SCREEN_W - ARENA_W) / 2
local ARENA_Y = (SCREEN_H - ARENA_H) / 2

local PLAYER_RADIUS   = 12
local PLAYER_SPEED    = 200
local PLAYER_MAX_HP   = 5
local DASH_DISTANCE   = 100
local DASH_COOLDOWN   = 0.5
local DASH_DURATION   = 0.12
local IFRAMES_DUR     = 0.8

local MELEE_DAMAGE    = 10
local MELEE_COOLDOWN  = 0.3
local MELEE_RANGE     = 40
local MELEE_ARC       = math.pi * 0.5 -- 90 degrees

local RANGED_DAMAGE   = 15
local RANGED_COOLDOWN = 0.8
local RANGED_SPEED    = 400
local RANGED_MAX_DIST = 300
local PROJ_RADIUS     = 4

local DOOR_W, DOOR_H  = 60, 20

-- Enemy base stats
local ENEMY_MELEE_HP   = 20
local ENEMY_RANGED_HP  = 15
local ENEMY_CHARGER_HP = 30
local BOSS_HP_BASE     = 120

-- ── States ────────────────────────────────────────────────────────────────
local STATE = { TITLE = 1, COMBAT = 2, PERK_SELECT = 3, BOSS = 4, GAME_OVER = 5 }
local state = STATE.TITLE

-- ── Perk definitions ──────────────────────────────────────────────────────
local PERK_DEFS = {
    { id = "dmg",    label = "+25% Attack Damage",  desc = "All attacks deal 25% more damage" },
    { id = "speed",  label = "+20% Move Speed",     desc = "Move 20% faster"                  },
    { id = "heal",   label = "+2 HP Heal",          desc = "Restore 2 hit points"             },
    { id = "maxhp",  label = "+1 Max HP",           desc = "Increase maximum HP by 1"         },
    { id = "cdr",    label = "-20% Cooldowns",      desc = "All cooldowns reduced by 20%"     },
    { id = "arc",    label = "Wider Melee Arc",      desc = "Melee slash covers a wider arc"   },
}

-- ── Mutable game state ───────────────────────────────────────────────────
local player = {
    x = 0, y = 0,
    hp = PLAYER_MAX_HP, max_hp = PLAYER_MAX_HP,
    facing_x = 1, facing_y = 0,
    speed = PLAYER_SPEED,
    dash_cd = 0, dashing = false, dash_timer = 0,
    dash_dx = 0, dash_dy = 0,
    iframes = 0,
    melee_cd = 0, ranged_cd = 0,
    dmg_mult = 1.0, cd_mult = 1.0,
    melee_arc = MELEE_ARC,
    flash = 0,
}

local enemies       = {}
local projectiles    = {}  -- player projectiles
local enemy_projs    = {}  -- enemy projectiles
local slash_effects  = {}  -- melee visual arcs
local room_number    = 0
local kills_total    = 0
local score          = 0
local perks_collected = {}
local perk_choices   = {}  -- 3 offered perks
local door_open      = false
local door_pulse     = { alpha = 0 }
local title_blink    = 0

-- Boss state
local boss = nil

-- Particle emitters
local death_burst    = nil
local slash_sparks   = nil
local dash_trail     = nil
local proj_sparks    = nil

-- Tween handles
local dmg_flash_tw   = nil
local perk_glow      = { alpha = 0 }
local perk_glow_tw   = nil
local door_pulse_tw  = nil

-- ── Helpers ───────────────────────────────────────────────────────────────
local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function angle_of(dx, dy) return math.atan2(dy, dx) end

local function normalize(dx, dy)
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return 0, 0 end
    return dx / len, dy / len
end

local function point_in_arena(x, y)
    return x >= ARENA_X and x <= ARENA_X + ARENA_W
       and y >= ARENA_Y and y <= ARENA_Y + ARENA_H
end

local function random_perk_choices()
    local pool = {}
    for i = 1, #PERK_DEFS do pool[i] = i end
    -- shuffle first 3
    for i = 1, 3 do
        local j = math.random(i, #pool)
        pool[i], pool[j] = pool[j], pool[i]
    end
    return { PERK_DEFS[pool[1]], PERK_DEFS[pool[2]], PERK_DEFS[pool[3]] }
end

local function apply_perk(perk)
    perks_collected[#perks_collected + 1] = perk.label
    if perk.id == "dmg" then
        player.dmg_mult = player.dmg_mult * 1.25
    elseif perk.id == "speed" then
        player.speed = player.speed * 1.20
    elseif perk.id == "heal" then
        player.hp = math.min(player.hp + 2, player.max_hp)
    elseif perk.id == "maxhp" then
        player.max_hp = player.max_hp + 1
        player.hp = player.hp + 1
    elseif perk.id == "cdr" then
        player.cd_mult = player.cd_mult * 0.80
    elseif perk.id == "arc" then
        player.melee_arc = player.melee_arc + math.pi * 0.15
    end
end

-- ── Enemy spawn ───────────────────────────────────────────────────────────
local function spawn_enemy(etype)
    local side = math.random(1, 4)
    local ex, ey
    if side == 1 then     ex = ARENA_X + 20;              ey = ARENA_Y + math.random(20, ARENA_H - 20)
    elseif side == 2 then ex = ARENA_X + ARENA_W - 20;    ey = ARENA_Y + math.random(20, ARENA_H - 20)
    elseif side == 3 then ex = ARENA_X + math.random(20, ARENA_W - 20); ey = ARENA_Y + 20
    else                  ex = ARENA_X + math.random(20, ARENA_W - 20); ey = ARENA_Y + ARENA_H - 20
    end

    local hp, radius, speed, dmg, color
    if etype == "melee" then
        hp = ENEMY_MELEE_HP; radius = 10; speed = 80; dmg = 1
        color = {0.9, 0.2, 0.2}
    elseif etype == "ranged" then
        hp = ENEMY_RANGED_HP; radius = 9; speed = 50; dmg = 1
        color = {0.9, 0.5, 0.1}
    elseif etype == "charger" then
        hp = ENEMY_CHARGER_HP; radius = 14; speed = 60; dmg = 2
        color = {0.8, 0.1, 0.3}
    end

    enemies[#enemies + 1] = {
        etype = etype, x = ex, y = ey,
        hp = hp, max_hp = hp, radius = radius,
        speed = speed, dmg = dmg, color = color,
        shoot_cd = 0, charge_cd = 0,
        charging = false, charge_dx = 0, charge_dy = 0, charge_timer = 0,
        windup = 0,
    }
end

local function spawn_boss()
    boss = {
        x = ARENA_X + ARENA_W / 2, y = ARENA_Y + 80,
        hp = BOSS_HP_BASE + room_number * 10,
        max_hp = BOSS_HP_BASE + room_number * 10,
        radius = 28, phase = 1, phase_timer = 0,
        shoot_cd = 0, charge_cd = 0, speed = 60,
        charging = false, charge_dx = 0, charge_dy = 0, charge_timer = 0,
        windup = 0, dmg = 2,
        color = {0.7, 0.1, 0.6},
    }
end

local function spawn_room_enemies()
    enemies = {}
    enemy_projs = {}
    local count = math.min(3 + room_number, 12)
    for _ = 1, count do
        local roll = math.random(1, 100)
        if roll <= 50 then spawn_enemy("melee")
        elseif roll <= 80 then spawn_enemy("ranged")
        else spawn_enemy("charger")
        end
    end
end

-- ── Room management ───────────────────────────────────────────────────────
local function start_room()
    room_number = room_number + 1
    door_open = false
    projectiles = {}
    enemy_projs = {}
    slash_effects = {}
    player.x = ARENA_X + ARENA_W / 2
    player.y = ARENA_Y + ARENA_H - 60

    if room_number % 5 == 0 then
        enemies = {}
        spawn_boss()
        state = STATE.BOSS
    else
        boss = nil
        spawn_room_enemies()
        state = STATE.COMBAT
    end
end

local function open_door()
    door_open = true
    if door_pulse_tw then lurek.tween.cancel(door_pulse_tw) end
    door_pulse.alpha = 0
    door_pulse_tw = lurek.tween.to(door_pulse, 0.6, { alpha = 1 }, { loop = -1, yoyo = true })
end

local function enter_perk_select()
    perk_choices = random_perk_choices()
    perk_glow.alpha = 0
    if perk_glow_tw then lurek.tween.cancel(perk_glow_tw) end
    perk_glow_tw = lurek.tween.to(perk_glow, 0.5, { alpha = 1 }, { loop = -1, yoyo = true })
    state = STATE.PERK_SELECT
end

-- ── Reset ─────────────────────────────────────────────────────────────────
local function reset_game()
    player.hp = PLAYER_MAX_HP
    player.max_hp = PLAYER_MAX_HP
    player.speed = PLAYER_SPEED
    player.dmg_mult = 1.0
    player.cd_mult = 1.0
    player.melee_arc = MELEE_ARC
    player.iframes = 0
    player.dash_cd = 0
    player.melee_cd = 0
    player.ranged_cd = 0
    player.dashing = false
    player.flash = 0
    room_number = 0
    kills_total = 0
    score = 0
    perks_collected = {}
    enemies = {}
    projectiles = {}
    enemy_projs = {}
    slash_effects = {}
    boss = nil
    start_room()
end

-- ── Damage player ─────────────────────────────────────────────────────────
local function damage_player(amount)
    if player.iframes > 0 or player.dashing then return end
    player.hp = player.hp - amount
    player.iframes = IFRAMES_DUR
    player.flash = 0.3

    if dmg_flash_tw then lurek.tween.cancel(dmg_flash_tw) end
    dmg_flash_tw = lurek.tween.to(player, 0.3, { flash = 0 })

    if death_burst then
        lurek.particle.emit(death_burst, player.x, player.y, 8)
    end

    if player.hp <= 0 then
        player.hp = 0
        state = STATE.GAME_OVER
    end
end

-- ── Damage enemy ──────────────────────────────────────────────────────────
local function damage_enemy(e, amount)
    e.hp = e.hp - amount * player.dmg_mult
    if e.hp <= 0 then
        kills_total = kills_total + 1
        score = score + 100
        if death_burst then
            lurek.particle.emit(death_burst, e.x, e.y, 15)
        end
        return true -- dead
    end
    return false
end

-- ── Player attacks ────────────────────────────────────────────────────────
local function do_melee()
    if player.melee_cd > 0 then return end
    player.melee_cd = MELEE_COOLDOWN * player.cd_mult
    local facing_a = angle_of(player.facing_x, player.facing_y)

    -- visual slash arc
    slash_effects[#slash_effects + 1] = {
        x = player.x, y = player.y,
        angle = facing_a, arc = player.melee_arc,
        range = MELEE_RANGE, timer = 0.15,
    }
    if slash_sparks then
        lurek.particle.emit(slash_sparks, player.x + player.facing_x * 20, player.y + player.facing_y * 20, 6)
    end

    -- hit enemies in arc
    local hit_list = enemies
    if state == STATE.BOSS and boss and boss.hp > 0 then
        hit_list = { boss }
    end
    for i = #hit_list, 1, -1 do
        local e = hit_list[i]
        local d = dist(player.x, player.y, e.x, e.y)
        if d <= MELEE_RANGE + e.radius then
            local ea = angle_of(e.x - player.x, e.y - player.y)
            local diff = math.abs(ea - facing_a)
            if diff > math.pi then diff = 2 * math.pi - diff end
            if diff <= player.melee_arc / 2 then
                if e == boss then
                    damage_enemy(e, MELEE_DAMAGE)
                else
                    if damage_enemy(e, MELEE_DAMAGE) then
                        table.remove(enemies, i)
                    end
                end
            end
        end
    end
end

local function do_ranged()
    if player.ranged_cd > 0 then return end
    player.ranged_cd = RANGED_COOLDOWN * player.cd_mult
    local dx, dy = normalize(player.facing_x, player.facing_y)
    if dx == 0 and dy == 0 then dx = 1 end
    projectiles[#projectiles + 1] = {
        x = player.x + dx * 16, y = player.y + dy * 16,
        dx = dx, dy = dy, traveled = 0,
    }
end

local function do_dash()
    if player.dash_cd > 0 or player.dashing then return end
    player.dash_cd = DASH_COOLDOWN * player.cd_mult
    player.dashing = true
    player.dash_timer = DASH_DURATION
    local dx, dy = normalize(player.facing_x, player.facing_y)
    if dx == 0 and dy == 0 then dx = 1 end
    local spd = DASH_DISTANCE / DASH_DURATION
    player.dash_dx = dx * spd
    player.dash_dy = dy * spd
end

-- ── Enemy AI ──────────────────────────────────────────────────────────────
local function update_enemy(e, dt)
    local dx, dy = player.x - e.x, player.y - e.y
    local d = dist(e.x, e.y, player.x, player.y)

    if e.etype == "melee" then
        local nx, ny = normalize(dx, dy)
        e.x = e.x + nx * e.speed * dt
        e.y = e.y + ny * e.speed * dt
        if d < PLAYER_RADIUS + e.radius then
            damage_player(e.dmg)
        end

    elseif e.etype == "ranged" then
        -- keep distance 120-180
        if d < 120 then
            local nx, ny = normalize(-dx, -dy)
            e.x = e.x + nx * e.speed * dt
            e.y = e.y + ny * e.speed * dt
        elseif d > 180 then
            local nx, ny = normalize(dx, dy)
            e.x = e.x + nx * e.speed * dt * 0.5
            e.y = e.y + ny * e.speed * dt * 0.5
        end
        e.shoot_cd = e.shoot_cd - dt
        if e.shoot_cd <= 0 then
            e.shoot_cd = 1.5
            local nx, ny = normalize(dx, dy)
            enemy_projs[#enemy_projs + 1] = {
                x = e.x, y = e.y, dx = nx * 200, dy = ny * 200, timer = 3,
            }
        end

    elseif e.etype == "charger" then
        if e.charging then
            e.charge_timer = e.charge_timer - dt
            e.x = e.x + e.charge_dx * 350 * dt
            e.y = e.y + e.charge_dy * 350 * dt
            if e.charge_timer <= 0 then
                e.charging = false
                e.charge_cd = 2.0
            end
            if d < PLAYER_RADIUS + e.radius then
                damage_player(e.dmg)
            end
        elseif e.windup > 0 then
            e.windup = e.windup - dt
            if e.windup <= 0 then
                e.charging = true
                e.charge_timer = 0.4
                e.charge_dx, e.charge_dy = normalize(dx, dy)
            end
        else
            -- idle: slowly approach
            local nx, ny = normalize(dx, dy)
            e.x = e.x + nx * e.speed * 0.3 * dt
            e.y = e.y + ny * e.speed * 0.3 * dt
            e.charge_cd = e.charge_cd - dt
            if e.charge_cd <= 0 and d < 200 then
                e.windup = 0.5
            end
        end
    end

    -- clamp to arena
    e.x = clamp(e.x, ARENA_X + e.radius, ARENA_X + ARENA_W - e.radius)
    e.y = clamp(e.y, ARENA_Y + e.radius, ARENA_Y + ARENA_H - e.radius)
end

-- ── Boss AI ───────────────────────────────────────────────────────────────
local function update_boss(b, dt)
    if not b or b.hp <= 0 then return end
    local dx, dy = player.x - b.x, player.y - b.y
    local d = dist(b.x, b.y, player.x, player.y)

    b.phase_timer = b.phase_timer + dt
    -- Phase 2 at 50% HP
    if b.hp <= b.max_hp * 0.5 and b.phase < 2 then
        b.phase = 2
        b.speed = 90
        b.phase_timer = 0
    end

    if b.charging then
        b.charge_timer = b.charge_timer - dt
        b.x = b.x + b.charge_dx * 400 * dt
        b.y = b.y + b.charge_dy * 400 * dt
        if b.charge_timer <= 0 then b.charging = false; b.charge_cd = 3.0 end
        if d < PLAYER_RADIUS + b.radius then damage_player(b.dmg) end
    elseif b.windup > 0 then
        b.windup = b.windup - dt
        if b.windup <= 0 then
            b.charging = true
            b.charge_timer = 0.5
            b.charge_dx, b.charge_dy = normalize(dx, dy)
        end
    else
        local nx, ny = normalize(dx, dy)
        b.x = b.x + nx * b.speed * dt
        b.y = b.y + ny * b.speed * dt
        if d < PLAYER_RADIUS + b.radius then damage_player(b.dmg) end

        -- Shoot pattern
        b.shoot_cd = b.shoot_cd - dt
        local shoot_rate = (b.phase == 2) and 0.6 or 1.0
        if b.shoot_cd <= 0 then
            b.shoot_cd = shoot_rate
            if b.phase == 2 then
                -- spread shot
                for a = -0.4, 0.4, 0.4 do
                    local sa = angle_of(dx, dy) + a
                    enemy_projs[#enemy_projs + 1] = {
                        x = b.x, y = b.y,
                        dx = math.cos(sa) * 220, dy = math.sin(sa) * 220,
                        timer = 3,
                    }
                end
            else
                local enx, eny = normalize(dx, dy)
                enemy_projs[#enemy_projs + 1] = {
                    x = b.x, y = b.y, dx = enx * 200, dy = eny * 200, timer = 3,
                }
            end
        end

        -- Charge
        b.charge_cd = b.charge_cd - dt
        if b.charge_cd <= 0 and d < 250 then
            b.windup = 0.6
        end
    end
    b.x = clamp(b.x, ARENA_X + b.radius, ARENA_X + ARENA_W - b.radius)
    b.y = clamp(b.y, ARENA_Y + b.radius, ARENA_Y + ARENA_H - b.radius)
end

-- ══════════════════════════════════════════════════════════════════════════
--  lurek.init — one-time setup
-- ══════════════════════════════════════════════════════════════════════════

function lurek.init()
    lurek.window.setTitle("Roguelite — Lurek2D")
    lurek.window.setBackgroundColor(0.08, 0.06, 0.04)

    lurek.input.bind("up",     {"w", "up"})
    lurek.input.bind("down",   {"s", "down"})
    lurek.input.bind("left",   {"a", "left"})
    lurek.input.bind("right",  {"d", "right"})
    lurek.input.bind("attack", {"j", "mouse_left"})
    lurek.input.bind("ranged", {"k", "mouse_right"})
    lurek.input.bind("dash",   {"lshift", "rshift"})
    lurek.input.bind("perk1",  {"1"})
    lurek.input.bind("perk2",  {"2"})
    lurek.input.bind("perk3",  {"3"})
    lurek.input.bind("restart",{"r"})
    lurek.input.bind("quit",   {"escape"})

    math.randomseed(os.time())
end

-- ══════════════════════════════════════════════════════════════════════════
--  lurek.ready — create particles & tweens after GPU init
-- ══════════════════════════════════════════════════════════════════════════
local function _ready_setup()
    death_burst = lurek.particle.new({
        maxParticles = 60,
        emitRate     = 0,
        lifetime     = { 0.3, 0.6 },
        speed        = { 80, 180 },
        direction    = { 0, 360 },
        colors       = { {1,0.3,0.1,1}, {1,0.8,0.1,0} },
        sizes        = { 4, 1 },
    })

    slash_sparks = lurek.particle.new({
        maxParticles = 30,
        emitRate     = 0,
        lifetime     = { 0.1, 0.25 },
        speed        = { 60, 120 },
        direction    = { 0, 360 },
        colors       = { {0.6,0.8,1,1}, {0.2,0.4,1,0} },
        sizes        = { 3, 1 },
    })

    dash_trail = lurek.particle.new({
        maxParticles = 40,
        emitRate     = 0,
        lifetime     = { 0.15, 0.3 },
        speed        = { 10, 30 },
        direction    = { 0, 360 },
        colors       = { {0.3,0.6,1,0.8}, {0.1,0.2,0.5,0} },
        sizes        = { 6, 2 },
    })

    proj_sparks = lurek.particle.new({
        maxParticles = 30,
        emitRate     = 0,
        lifetime     = { 0.1, 0.2 },
        speed        = { 40, 80 },
        direction    = { 0, 360 },
        colors       = { {1,1,0.5,1}, {1,0.6,0,0} },
        sizes        = { 3, 1 },
    })

    lurek.camera.setPosition(0, 0)
end

-- ══════════════════════════════════════════════════════════════════════════
--  lurek.process — game logic each frame
-- ══════════════════════════════════════════════════════════════════════════
function lurek.process(dt)
    if lurek.input.pressed("quit") then lurek.event.quit() end

    -- ── Title ─────────────────────────────────────────────────────────
    if state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.pressed("attack") or lurek.input.pressed("perk1") then
            reset_game()
        end
        return
    end

    -- ── Game Over ─────────────────────────────────────────────────────
    if state == STATE.GAME_OVER then
        if lurek.input.pressed("restart") then
            state = STATE.TITLE
        end
        return
    end

    -- ── Perk Select ───────────────────────────────────────────────────
    if state == STATE.PERK_SELECT then
        for i = 1, 3 do
            if lurek.input.pressed("perk" .. i) and perk_choices[i] then
                apply_perk(perk_choices[i])
                if perk_glow_tw then lurek.tween.cancel(perk_glow_tw) end
                start_room()
            end
        end
        return
    end

    -- ── Combat / Boss ─────────────────────────────────────────────────
    -- Cooldown timers
    player.melee_cd  = math.max(0, player.melee_cd - dt)
    player.ranged_cd = math.max(0, player.ranged_cd - dt)
    player.dash_cd   = math.max(0, player.dash_cd - dt)
    player.iframes   = math.max(0, player.iframes - dt)

    -- Player movement
    if player.dashing then
        player.dash_timer = player.dash_timer - dt
        player.x = player.x + player.dash_dx * dt
        player.y = player.y + player.dash_dy * dt
        if dash_trail then
            lurek.particle.emit(dash_trail, player.x, player.y, 3)
        end
        if player.dash_timer <= 0 then player.dashing = false end
    else
        local mx, my = 0, 0
        if lurek.input.held("left")  then mx = mx - 1 end
        if lurek.input.held("right") then mx = mx + 1 end
        if lurek.input.held("up")    then my = my - 1 end
        if lurek.input.held("down")  then my = my + 1 end
        if mx ~= 0 or my ~= 0 then
            local nx, ny = normalize(mx, my)
            player.facing_x = nx
            player.facing_y = ny
            player.x = player.x + nx * player.speed * dt
            player.y = player.y + ny * player.speed * dt
        end
    end

    -- Clamp player to arena
    player.x = clamp(player.x, ARENA_X + PLAYER_RADIUS, ARENA_X + ARENA_W - PLAYER_RADIUS)
    player.y = clamp(player.y, ARENA_Y + PLAYER_RADIUS, ARENA_Y + ARENA_H - PLAYER_RADIUS)

    -- Attacks
    if lurek.input.pressed("attack") then do_melee() end
    if lurek.input.pressed("ranged") then do_ranged() end
    if lurek.input.pressed("dash")   then do_dash() end

    -- Update player projectiles
    for i = #projectiles, 1, -1 do
        local p = projectiles[i]
        local step = RANGED_SPEED * dt
        p.x = p.x + p.dx * RANGED_SPEED * dt
        p.y = p.y + p.dy * RANGED_SPEED * dt
        p.traveled = p.traveled + step

        -- Hit enemies
        local hit = false
        if state == STATE.BOSS and boss and boss.hp > 0 then
            if dist(p.x, p.y, boss.x, boss.y) < boss.radius + PROJ_RADIUS then
                damage_enemy(boss, RANGED_DAMAGE)
                hit = true
            end
        else
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if dist(p.x, p.y, e.x, e.y) < e.radius + PROJ_RADIUS then
                    if damage_enemy(e, RANGED_DAMAGE) then
                        table.remove(enemies, j)
                    end
                    hit = true
                    break
                end
            end
        end

        if hit then
            if proj_sparks then lurek.particle.emit(proj_sparks, p.x, p.y, 8) end
            table.remove(projectiles, i)
        elseif p.traveled > RANGED_MAX_DIST or not point_in_arena(p.x, p.y) then
            table.remove(projectiles, i)
        end
    end

    -- Update enemy projectiles
    for i = #enemy_projs, 1, -1 do
        local p = enemy_projs[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.timer = p.timer - dt

        if dist(p.x, p.y, player.x, player.y) < PLAYER_RADIUS + 4 then
            damage_player(1)
            table.remove(enemy_projs, i)
        elseif p.timer <= 0 or not point_in_arena(p.x, p.y) then
            table.remove(enemy_projs, i)
        end
    end

    -- Update slash effects
    for i = #slash_effects, 1, -1 do
        slash_effects[i].timer = slash_effects[i].timer - dt
        if slash_effects[i].timer <= 0 then table.remove(slash_effects, i) end
    end

    -- Update enemies
    if state == STATE.COMBAT then
        for i = #enemies, 1, -1 do
            update_enemy(enemies[i], dt)
        end
        -- Check room clear
        if #enemies == 0 and not door_open then
            open_door()
        end
        -- Door interaction
        if door_open then
            local door_cx = ARENA_X + ARENA_W / 2
            local door_cy = ARENA_Y
            if dist(player.x, player.y, door_cx, door_cy + DOOR_H / 2) < 40 then
                if door_pulse_tw then lurek.tween.cancel(door_pulse_tw) end
                enter_perk_select()
            end
        end
    elseif state == STATE.BOSS then
        update_boss(boss, dt)
        if boss and boss.hp <= 0 then
            score = score + 500
            kills_total = kills_total + 1
            boss = nil
            open_door()
            -- After boss door, go to perk select when player reaches door
        end
        if door_open and not boss then
            local door_cx = ARENA_X + ARENA_W / 2
            local door_cy = ARENA_Y
            if dist(player.x, player.y, door_cx, door_cy + DOOR_H / 2) < 40 then
                if door_pulse_tw then lurek.tween.cancel(door_pulse_tw) end
                enter_perk_select()
            end
        end
    end

    -- Update particles
    if death_burst  then lurek.particle.update(death_burst, dt) end
    if slash_sparks then lurek.particle.update(slash_sparks, dt) end
    if dash_trail   then lurek.particle.update(dash_trail, dt) end
    if proj_sparks  then lurek.particle.update(proj_sparks, dt) end
end

-- ══════════════════════════════════════════════════════════════════════════
--  lurek.render — world-space drawing
-- ══════════════════════════════════════════════════════════════════════════
function lurek.draw()
    if state == STATE.TITLE or state == STATE.GAME_OVER or state == STATE.PERK_SELECT then return end

    -- ── Arena background ──────────────────────────────────────────────
    lurek.render.setColor(0.12, 0.10, 0.08, 1)
    lurek.render.rectangle("fill", ARENA_X, ARENA_Y, ARENA_W, ARENA_H)

    -- Floor grid pattern
    lurek.render.setColor(0.15, 0.13, 0.10, 1)
    for gx = 0, ARENA_W - 1, 40 do
        for gy = 0, ARENA_H - 1, 40 do
            lurek.render.rectangle("line", ARENA_X + gx, ARENA_Y + gy, 40, 40)
        end
    end

    -- Arena border
    lurek.render.setColor(0.4, 0.35, 0.25, 1)
    lurek.render.rectangle("line", ARENA_X, ARENA_Y, ARENA_W, ARENA_H)

    -- ── Door ──────────────────────────────────────────────────────────
    if door_open then
        local da = 0.6 + door_pulse.alpha * 0.4
        lurek.render.setColor(0.2, 0.9, 0.3, da)
        local dx = ARENA_X + (ARENA_W - DOOR_W) / 2
        lurek.render.rectangle("fill", dx, ARENA_Y - 2, DOOR_W, DOOR_H)
    end

    -- ── Enemies ───────────────────────────────────────────────────────
    for _, e in ipairs(enemies) do
        local c = e.color
        lurek.render.setColor(c[1], c[2], c[3], 1)
        if e.etype == "melee" then
            lurek.render.circle("fill", e.x, e.y, e.radius)
        elseif e.etype == "ranged" then
            lurek.render.rectangle("fill", e.x - e.radius, e.y - e.radius, e.radius * 2, e.radius * 2)
        elseif e.etype == "charger" then
            -- triangle-like: draw as wider shape
            lurek.render.circle("fill", e.x, e.y, e.radius)
            if e.windup > 0 then
                lurek.render.setColor(1, 1, 0, 0.5)
                lurek.render.circle("line", e.x, e.y, e.radius + 4)
            end
        end
        -- Enemy HP bar
        local hp_frac = e.hp / e.max_hp
        lurek.render.setColor(0.2, 0.2, 0.2, 0.7)
        lurek.render.rectangle("fill", e.x - 12, e.y - e.radius - 8, 24, 4)
        lurek.render.setColor(0.9, 0.2, 0.2, 0.9)
        lurek.render.rectangle("fill", e.x - 12, e.y - e.radius - 8, 24 * hp_frac, 4)
    end

    -- ── Boss ──────────────────────────────────────────────────────────
    if boss and boss.hp > 0 then
        local c = boss.color
        lurek.render.setColor(c[1], c[2], c[3], 1)
        lurek.render.circle("fill", boss.x, boss.y, boss.radius)
        if boss.phase == 2 then
            lurek.render.setColor(1, 0.3, 0.8, 0.3)
            lurek.render.circle("line", boss.x, boss.y, boss.radius + 6)
        end
        if boss.windup > 0 then
            lurek.render.setColor(1, 1, 0, 0.6)
            lurek.render.circle("line", boss.x, boss.y, boss.radius + 8)
        end
        -- Boss HP bar
        local hp_frac = boss.hp / boss.max_hp
        lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
        lurek.render.rectangle("fill", boss.x - 30, boss.y - boss.radius - 12, 60, 6)
        lurek.render.setColor(0.8, 0.1, 0.6, 1)
        lurek.render.rectangle("fill", boss.x - 30, boss.y - boss.radius - 12, 60 * hp_frac, 6)
    end

    -- ── Player projectiles ────────────────────────────────────────────
    lurek.render.setColor(1, 1, 0.5, 1)
    for _, p in ipairs(projectiles) do
        lurek.render.circle("fill", p.x, p.y, PROJ_RADIUS)
    end

    -- ── Enemy projectiles ─────────────────────────────────────────────
    lurek.render.setColor(1, 0.3, 0.1, 0.9)
    for _, p in ipairs(enemy_projs) do
        lurek.render.circle("fill", p.x, p.y, 4)
    end

    -- ── Slash effects ─────────────────────────────────────────────────
    for _, s in ipairs(slash_effects) do
        local alpha = s.timer / 0.15
        lurek.render.setColor(0.6, 0.8, 1, alpha * 0.6)
        -- draw arc as a thick line fan
        local steps = 8
        for i = 0, steps do
            local a = s.angle - s.arc / 2 + (s.arc / steps) * i
            local ex = s.x + math.cos(a) * s.range
            local ey = s.y + math.sin(a) * s.range
            lurek.render.line(s.x, s.y, ex, ey)
        end
    end

    -- ── Player ────────────────────────────────────────────────────────
    if player.iframes > 0 and math.floor(player.iframes * 10) % 2 == 0 then
        -- blink during iframes
    else
        local r, g, b = 0.3, 0.5, 1.0
        if player.flash > 0 then
            r = r + (1 - r) * (player.flash / 0.3)
            g = g * (1 - player.flash / 0.3)
            b = b * (1 - player.flash / 0.3)
        end
        if player.dashing then
            lurek.render.setColor(0.5, 0.7, 1, 0.5)
        else
            lurek.render.setColor(r, g, b, 1)
        end
        lurek.render.circle("fill", player.x, player.y, PLAYER_RADIUS)

        -- facing indicator
        lurek.render.setColor(0.8, 0.9, 1, 0.7)
        local fx = player.x + player.facing_x * (PLAYER_RADIUS + 5)
        local fy = player.y + player.facing_y * (PLAYER_RADIUS + 5)
        lurek.render.circle("fill", fx, fy, 3)
    end

    -- ── Particles ─────────────────────────────────────────────────────
    if death_burst  then lurek.particle.draw(death_burst) end
    if slash_sparks then lurek.particle.draw(slash_sparks) end
    if dash_trail   then lurek.particle.draw(dash_trail) end
    if proj_sparks  then lurek.particle.draw(proj_sparks) end
end

-- ══════════════════════════════════════════════════════════════════════════
--  lurek.render_ui — screen-space HUD
-- ══════════════════════════════════════════════════════════════════════════
function lurek.draw_ui()
    local fps = lurek.timer.getFPS()

    -- ── Title screen ──────────────────────────────────────────────────
    if state == STATE.TITLE then
        lurek.render.setColor(0.9, 0.2, 0.2, 1)
        lurek.render.print("ROGUELITE", SCREEN_W / 2 - 100, SCREEN_H / 2 - 60, 40)

        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(0.8, 0.8, 0.8, 1)
            lurek.render.print("PRESS ENTER OR CLICK", SCREEN_W / 2 - 110, SCREEN_H / 2 + 10, 16)
        end

        lurek.render.setColor(0.5, 0.5, 0.5, 1)
        lurek.render.print("WASD move | J melee | K ranged | Shift dash", SCREEN_W / 2 - 180, SCREEN_H / 2 + 50, 12)
        lurek.render.print(string.format("FPS: %d", fps), 10, SCREEN_H - 20, 12)
        return
    end

    -- ── Game Over ─────────────────────────────────────────────────────
    if state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.7)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(0.9, 0.2, 0.2, 1)
        lurek.render.print("YOU DIED", SCREEN_W / 2 - 80, 120, 36)

        lurek.render.setColor(0.9, 0.9, 0.9, 1)
        lurek.render.print(string.format("Rooms Cleared: %d", room_number - 1), SCREEN_W / 2 - 80, 200, 16)
        lurek.render.print(string.format("Enemies Killed: %d", kills_total), SCREEN_W / 2 - 80, 225, 16)
        lurek.render.print(string.format("Score: %d", score), SCREEN_W / 2 - 80, 250, 16)

        lurek.render.setColor(0.7, 0.7, 0.9, 1)
        lurek.render.print("Perks collected:", SCREEN_W / 2 - 80, 290, 14)
        for i, pname in ipairs(perks_collected) do
            lurek.render.print("• " .. pname, SCREEN_W / 2 - 70, 290 + i * 18, 12)
        end

        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        lurek.render.print("Press R to return to title", SCREEN_W / 2 - 100, SCREEN_H - 60, 14)
        lurek.render.print(string.format("FPS: %d", fps), 10, SCREEN_H - 20, 12)
        return
    end

    -- ── Perk Select ───────────────────────────────────────────────────
    if state == STATE.PERK_SELECT then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(1, 0.85, 0.3, 1)
        lurek.render.print("CHOOSE A PERK", SCREEN_W / 2 - 90, 100, 24)

        for i = 1, 3 do
            local pk = perk_choices[i]
            if pk then
                local bx = SCREEN_W / 2 - 150
                local by = 170 + (i - 1) * 90
                local glow_a = perk_glow.alpha * 0.15
                lurek.render.setColor(0.2 + glow_a, 0.18 + glow_a, 0.15, 0.9)
                lurek.render.rectangle("fill", bx, by, 300, 70)
                lurek.render.setColor(0.8, 0.7, 0.3, 1)
                lurek.render.rectangle("line", bx, by, 300, 70)

                lurek.render.setColor(1, 0.9, 0.4, 1)
                lurek.render.print(string.format("[%d] %s", i, pk.label), bx + 15, by + 15, 16)
                lurek.render.setColor(0.7, 0.7, 0.7, 1)
                lurek.render.print(pk.desc, bx + 15, by + 40, 12)
            end
        end

        lurek.render.setColor(0.5, 0.5, 0.5, 1)
        lurek.render.print(string.format("Room %d completed", room_number), SCREEN_W / 2 - 70, SCREEN_H - 50, 12)
        lurek.render.print(string.format("FPS: %d", fps), 10, SCREEN_H - 20, 12)
        return
    end

    -- ── Combat / Boss HUD ─────────────────────────────────────────────
    -- HP bar
    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    lurek.render.rectangle("fill", 10, 10, 160, 18)
    local hp_frac = player.hp / player.max_hp
    lurek.render.setColor(0.2, 0.8, 0.3, 1)
    lurek.render.rectangle("fill", 10, 10, 160 * hp_frac, 18)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(string.format("HP %d/%d", player.hp, player.max_hp), 15, 12, 12)

    -- Room + score
    lurek.render.setColor(0.9, 0.9, 0.9, 1)
    lurek.render.print(string.format("Room %d", room_number), 10, 36, 14)
    lurek.render.print(string.format("Score: %d", score), 10, 56, 12)
    lurek.render.print(string.format("Kills: %d", kills_total), 10, 74, 12)

    -- Cooldown indicators
    local cd_y = SCREEN_H - 40
    lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
    lurek.render.print("J:Melee  K:Ranged  Shift:Dash", 10, cd_y, 11)

    if player.melee_cd > 0 then
        lurek.render.setColor(1, 0.3, 0.3, 0.7)
        lurek.render.rectangle("fill", 10, cd_y + 14, 50 * (player.melee_cd / (MELEE_COOLDOWN * player.cd_mult)), 4)
    end
    if player.ranged_cd > 0 then
        lurek.render.setColor(1, 1, 0.3, 0.7)
        lurek.render.rectangle("fill", 80, cd_y + 14, 50 * (player.ranged_cd / (RANGED_COOLDOWN * player.cd_mult)), 4)
    end
    if player.dash_cd > 0 then
        lurek.render.setColor(0.3, 0.7, 1, 0.7)
        lurek.render.rectangle("fill", 170, cd_y + 14, 50 * (player.dash_cd / (DASH_COOLDOWN * player.cd_mult)), 4)
    end

    -- Perks summary
    if #perks_collected > 0 then
        lurek.render.setColor(0.6, 0.5, 0.3, 0.8)
        lurek.render.print("Perks:", SCREEN_W - 200, 10, 11)
        for i, pname in ipairs(perks_collected) do
            if i > 6 then break end -- show max 6
            lurek.render.setColor(0.8, 0.7, 0.4, 0.7)
            lurek.render.print("• " .. pname, SCREEN_W - 200, 10 + i * 14, 10)
        end
    end

    -- Boss HP bar (top center)
    if state == STATE.BOSS and boss and boss.hp > 0 then
        local bw = 300
        local bx = (SCREEN_W - bw) / 2
        lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
        lurek.render.rectangle("fill", bx, 10, bw, 20)
        local bhp_frac = boss.hp / boss.max_hp
        lurek.render.setColor(0.7, 0.1, 0.5, 1)
        lurek.render.rectangle("fill", bx, 10, bw * bhp_frac, 20)
        lurek.render.setColor(1, 1, 1, 1)
        local phase_txt = boss.phase == 2 and " [ENRAGED]" or ""
        lurek.render.print("BOSS" .. phase_txt, bx + 5, 13, 13)
    end

    -- FPS
    lurek.render.setColor(0.4, 0.4, 0.4, 1)
    lurek.render.print(string.format("FPS: %d", fps), SCREEN_W - 70, SCREEN_H - 20, 11)
end
