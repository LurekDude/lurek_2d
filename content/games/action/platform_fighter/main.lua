-- ============================================================================
--  Platform Fighter — Smash Bros-inspired 2P local platform fighter
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/platform_fighter
--
--  Controls (bound as input actions — see lurek.init):
--    P1: A/D move, W jump, F attack, G special
--    P2: Arrows move, Up jump, K attack, L special
--    Enter = start, Escape = quit
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600
local GRAVITY            = 1400
local MOVE_SPEED         = 250
local JUMP_VEL           = -520
local MAX_JUMPS          = 2
local FIGHTER_W, FIGHTER_H = 20, 30
local PROJECTILE_SPEED   = 400
local PROJECTILE_SIZE    = 6
local PROJECTILE_LIFE    = 1.5

-- Blast zones
local BLAST_LEFT   = -60
local BLAST_RIGHT  = SCREEN_W + 60
local BLAST_TOP    = -60
local BLAST_BOTTOM = SCREEN_H + 60

-- Attack data
local ATK_NORMAL = { dmg = 8,  kb_base = 120, dur = 0.12, cooldown = 0.20 }
local ATK_SPECIAL = { dmg = 12, kb_base = 180, dur = 0.05, cooldown = 1.0 }
local ATK_AIR    = { dmg = 10, kb_base = 150, dur = 0.12, cooldown = 0.20, spike = true }

-- Stocks / invulnerability
local MAX_STOCKS     = 3
local INVULN_TIME    = 2.0
local BLINK_RATE     = 0.1

-- Platforms: {x, y, w, h}
local PLATFORMS = {
    { x = 150, y = 450, w = 500, h = 20 },   -- main ground
    { x = 80,  y = 330, w = 140, h = 14 },    -- left floating
    { x = 580, y = 330, w = 140, h = 14 },    -- right floating
    { x = 310, y = 220, w = 180, h = 14 },    -- top center
}

-- Colors
local P1_COLOR  = {0.3, 0.5, 1.0}
local P2_COLOR  = {1.0, 0.3, 0.3}
local PLAT_MAIN = {0.45, 0.35, 0.25}
local PLAT_FLOAT = {0.5, 0.5, 0.55}

-- ── Scene state ───────────────────────────────────────────────────────────
local STATES = { TITLE = 1, FIGHTING = 2, KO = 3, MATCH_OVER = 4 }
local game_state = STATES.TITLE

-- ── Helpers ───────────────────────────────────────────────────────────────
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- ── Fighter factory ──────────────────────────────────────────────────────
local function new_fighter(id, x, color)
    return {
        id = id,
        x = x, y = 400,
        vx = 0, vy = 0,
        color = color,
        damage_pct = 0,
        stocks = MAX_STOCKS,
        jumps_left = MAX_JUMPS,
        grounded = false,
        facing = (id == 1) and 1 or -1,
        -- Attack state
        atk_timer = 0,
        atk_cooldown = 0,
        cur_attack = nil,
        hit_connected = false,
        -- Special cooldown
        special_cd = 0,
        -- Invulnerability
        invuln = 0,
        -- Animation helpers
        dmg_flash = 0,
    }
end

-- ── Game objects ──────────────────────────────────────────────────────────
local p1, p2
local projectiles = {}
local title_blink = 0
local ko_timer    = 0
local ko_who      = ""
local match_winner = ""

-- Particles
local hit_burst_ps   = nil
local ko_explode_ps  = nil
local land_dust_ps   = nil
local proj_trail_ps  = nil

-- Tweens
local ko_text_scale  = 1.0
local dmg_flash_p1   = 0
local dmg_flash_p2   = 0

-- ── Initialization ───────────────────────────────────────────────────────
local function reset_fighter_pos(f)
    f.x = (f.id == 1) and 300 or 500
    f.y = 200
    f.vx = 0
    f.vy = 0
    f.damage_pct = 0
    f.jumps_left = MAX_JUMPS
    f.grounded = false
    f.atk_timer = 0
    f.atk_cooldown = 0
    f.cur_attack = nil
    f.hit_connected = false
    f.special_cd = 0
    f.invuln = INVULN_TIME
    f.facing = (f.id == 1) and 1 or -1
end

local function init_match()
    p1 = new_fighter(1, 300, P1_COLOR)
    p2 = new_fighter(2, 500, P2_COLOR)
    p1.invuln = 0
    p2.invuln = 0
    projectiles = {}
    game_state = STATES.FIGHTING
end

-- ── Knockback calculation ────────────────────────────────────────────────
local function calc_knockback(atk, defender_pct, dir_x, dir_y)
    -- Knockback scales with defender's damage%
    local scale = 1.0 + (defender_pct / 50.0)
    local kb = atk.kb_base * scale
    return dir_x * kb, dir_y * kb
end

-- ── Projectile factory ───────────────────────────────────────────────────
local function spawn_projectile(owner, facing)
    local px = owner.x + (facing == 1 and FIGHTER_W + 4 or -PROJECTILE_SIZE - 4)
    local py = owner.y + FIGHTER_H * 0.4
    table.insert(projectiles, {
        x = px, y = py,
        vx = facing * PROJECTILE_SPEED,
        vy = 0,
        owner_id = owner.id,
        color = owner.color,
        life = PROJECTILE_LIFE,
    })
end

-- ── Platform collision ───────────────────────────────────────────────────
local function collide_platforms(f, dt)
    local was_grounded = f.grounded
    f.grounded = false
    for _, plat in ipairs(PLATFORMS) do
        -- Only collide from above (falling down onto platform)
        local foot_y = f.y + FIGHTER_H
        local prev_foot = foot_y - f.vy * dt
        if f.vy >= 0 and prev_foot <= plat.y + 2 and foot_y >= plat.y then
            if f.x + FIGHTER_W > plat.x and f.x < plat.x + plat.w then
                f.y = plat.y - FIGHTER_H
                f.vy = 0
                f.grounded = true
                f.jumps_left = MAX_JUMPS
                -- Landing dust
                if not was_grounded and land_dust_ps then
                    lurek.particles.emit(land_dust_ps, f.x + FIGHTER_W * 0.5, plat.y, 5)
                end
                break
            end
        end
    end
end

-- ── Attack logic ─────────────────────────────────────────────────────────
local function perform_attack(attacker, defender, atk_type)
    if attacker.atk_cooldown > 0 then return end

    -- Air attack override
    local atk = atk_type
    if not attacker.grounded and atk_type == ATK_NORMAL then
        atk = ATK_AIR
    end

    attacker.cur_attack = atk
    attacker.atk_timer = atk.dur
    attacker.atk_cooldown = atk.cooldown
    attacker.hit_connected = false
end

local function perform_special(attacker)
    if attacker.special_cd > 0 then return end
    attacker.special_cd = ATK_SPECIAL.cooldown
    spawn_projectile(attacker, attacker.facing)
end

local function check_melee_hit(attacker, defender)
    if attacker.atk_timer <= 0 or attacker.cur_attack == nil then return end
    if attacker.hit_connected then return end
    if defender.invuln > 0 then return end

    local atk = attacker.cur_attack
    local reach = 28
    local hb_x = attacker.x + (attacker.facing == 1 and FIGHTER_W or -reach)

    -- AABB
    if hb_x < defender.x + FIGHTER_W and hb_x + reach > defender.x and
       attacker.y < defender.y + FIGHTER_H and attacker.y + FIGHTER_H > defender.y then

        attacker.hit_connected = true
        defender.damage_pct = defender.damage_pct + atk.dmg

        -- Knockback direction
        local dir_x = attacker.facing
        local dir_y = -0.5
        if atk.spike then
            dir_x = 0
            dir_y = 1.5
        end
        local kbx, kby = calc_knockback(atk, defender.damage_pct, dir_x, dir_y)
        defender.vx = defender.vx + kbx
        defender.vy = defender.vy + kby

        -- Damage flash tween
        if defender.id == 1 then
            dmg_flash_p1 = 1.0
            lurek.tween.to(0.4, function(t) dmg_flash_p1 = 1.0 - t end)
        else
            dmg_flash_p2 = 1.0
            lurek.tween.to(0.4, function(t) dmg_flash_p2 = 1.0 - t end)
        end

        -- Hit burst particles
        if hit_burst_ps then
            local hx = (attacker.x + defender.x) * 0.5 + FIGHTER_W * 0.5
            local hy = (attacker.y + defender.y) * 0.5 + FIGHTER_H * 0.5
            lurek.particles.emit(hit_burst_ps, hx, hy, 12)
        end
    end
end

-- ── Projectile hit check ─────────────────────────────────────────────────
local function check_projectile_hits()
    local to_remove = {}
    for i, proj in ipairs(projectiles) do
        local targets = {}
        if proj.owner_id == 1 then targets = {p2} else targets = {p1} end
        for _, def in ipairs(targets) do
            if def.invuln <= 0 then
                if proj.x < def.x + FIGHTER_W and proj.x + PROJECTILE_SIZE > def.x and
                   proj.y < def.y + FIGHTER_H and proj.y + PROJECTILE_SIZE > def.y then
                    def.damage_pct = def.damage_pct + ATK_SPECIAL.dmg
                    local dir_x = (proj.vx > 0) and 1 or -1
                    local kbx, kby = calc_knockback(ATK_SPECIAL, def.damage_pct, dir_x, -0.3)
                    def.vx = def.vx + kbx
                    def.vy = def.vy + kby

                    if def.id == 1 then
                        dmg_flash_p1 = 1.0
                        lurek.tween.to(0.4, function(t) dmg_flash_p1 = 1.0 - t end)
                    else
                        dmg_flash_p2 = 1.0
                        lurek.tween.to(0.4, function(t) dmg_flash_p2 = 1.0 - t end)
                    end
                    if hit_burst_ps then
                        lurek.particles.emit(hit_burst_ps, proj.x, proj.y, 10)
                    end
                    table.insert(to_remove, i)
                    break
                end
            end
        end
    end
    for j = #to_remove, 1, -1 do
        table.remove(projectiles, to_remove[j])
    end
end

-- ── Blast zone check ─────────────────────────────────────────────────────
local function check_blast_zones(f)
    local cx = f.x + FIGHTER_W * 0.5
    local cy = f.y + FIGHTER_H * 0.5
    if cx < BLAST_LEFT or cx > BLAST_RIGHT or cy < BLAST_TOP or cy > BLAST_BOTTOM then
        -- KO explosion
        if ko_explode_ps then
            lurek.particles.emit(ko_explode_ps, clamp(f.x, 0, SCREEN_W), clamp(f.y, 0, SCREEN_H), 30)
        end
        f.stocks = f.stocks - 1
        if f.stocks > 0 then
            reset_fighter_pos(f)
        end
        return true
    end
    return false
end

-- ── Update fighter ───────────────────────────────────────────────────────
local function update_fighter(f, dt, move_left, move_right, do_jump, do_attack, do_special)
    if game_state ~= STATES.FIGHTING then return end

    -- Invulnerability countdown
    if f.invuln > 0 then f.invuln = f.invuln - dt end

    -- Timers
    if f.atk_timer > 0 then f.atk_timer = f.atk_timer - dt end
    if f.atk_cooldown > 0 then f.atk_cooldown = f.atk_cooldown - dt end
    if f.special_cd > 0 then f.special_cd = f.special_cd - dt end

    -- Horizontal movement
    if f.atk_timer <= 0 then
        if move_left then
            f.vx = -MOVE_SPEED
            f.facing = -1
        elseif move_right then
            f.vx = MOVE_SPEED
            f.facing = 1
        else
            -- Friction
            f.vx = f.vx * 0.85
            if math.abs(f.vx) < 10 then f.vx = 0 end
        end
    end

    -- Jump
    if do_jump and f.jumps_left > 0 then
        f.vy = JUMP_VEL
        f.jumps_left = f.jumps_left - 1
        f.grounded = false
    end

    -- Attacks
    if do_attack then
        local other = (f.id == 1) and p2 or p1
        perform_attack(f, other, ATK_NORMAL)
    end
    if do_special then
        perform_special(f)
    end

    -- Gravity
    f.vy = f.vy + GRAVITY * dt

    -- Apply velocity
    f.x = f.x + f.vx * dt
    f.y = f.y + f.vy * dt

    -- Platform collision
    collide_platforms(f, dt)

    -- Melee hit detection
    local other = (f.id == 1) and p2 or p1
    check_melee_hit(f, other)

    -- Blast zone check
    if check_blast_zones(f) then
        if f.stocks <= 0 then
            game_state = STATES.KO
            ko_who = (f.id == 1) and "PLAYER 2" or "PLAYER 1"
            ko_timer = 2.0
            ko_text_scale = 3.0
            lurek.tween.to(0.5, function(t) ko_text_scale = 3.0 - 2.0 * t end)
        end
    end
end

-- ── lurek.init ───────────────────────────────────────────────────────────
lurek.init(function()
    lurek.window.setTitle("Platform Fighter — Lurek2D")
    lurek.render.setBackgroundColor(0.15, 0.2, 0.35)

    -- Input actions — P1
    lurek.input.action("p1_left",    {"a"})
    lurek.input.action("p1_right",   {"d"})
    lurek.input.action("p1_jump",    {"w"})
    lurek.input.action("p1_attack",  {"f"})
    lurek.input.action("p1_special", {"g"})
    -- Input actions — P2
    lurek.input.action("p2_left",    {"left"})
    lurek.input.action("p2_right",   {"right"})
    lurek.input.action("p2_jump",    {"up"})
    lurek.input.action("p2_attack",  {"k"})
    lurek.input.action("p2_special", {"l"})
    -- Global
    lurek.input.action("quit",  {"escape"})
    lurek.input.action("start", {"return"})

    -- Particle systems
    hit_burst_ps = lurek.particles.new({
        max        = 60,
        lifetime   = {0.15, 0.35},
        speed      = {100, 300},
        direction  = {0, 360},
        colors     = {{1,1,0.3,1},{1,0.5,0,0}},
        sizes      = {4, 1},
    })
    ko_explode_ps = lurek.particles.new({
        max        = 80,
        lifetime   = {0.3, 0.8},
        speed      = {80, 250},
        direction  = {0, 360},
        colors     = {{1,0.8,0.2,1},{1,0.2,0,0}},
        sizes      = {8, 2},
    })
    land_dust_ps = lurek.particles.new({
        max        = 30,
        lifetime   = {0.1, 0.3},
        speed      = {20, 60},
        direction  = {160, 200},
        colors     = {{0.7,0.65,0.5,0.7},{0.5,0.5,0.4,0}},
        sizes      = {3, 1},
    })
    proj_trail_ps = lurek.particles.new({
        max        = 100,
        lifetime   = {0.1, 0.25},
        speed      = {5, 20},
        direction  = {0, 360},
        colors     = {{1,1,1,0.6},{0.5,0.5,1,0}},
        sizes      = {3, 1},
    })
end)

-- ── lurek.ready ──────────────────────────────────────────────────────────
lurek.ready(function()
    lurek.camera.setPosition(0, 0)
end)

-- ── lurek.process ────────────────────────────────────────────────────────
lurek.process(function(dt)
    -- Quit
    if lurek.input.pressed("quit") then
        lurek.signal.quit()
        return
    end

    -- FPS in title
    local fps = lurek.time.fps()
    lurek.window.setTitle("Platform Fighter — Lurek2D | FPS: " .. fps)

    -- ── TITLE state ──────────────────────────────────────────────────
    if game_state == STATES.TITLE then
        title_blink = title_blink + dt
        if lurek.input.pressed("start") then
            init_match()
        end
        return
    end

    -- ── FIGHTING state ───────────────────────────────────────────────
    if game_state == STATES.FIGHTING then
        -- P1 input
        local p1_left  = lurek.input.down("p1_left")
        local p1_right = lurek.input.down("p1_right")
        local p1_jump  = lurek.input.pressed("p1_jump")
        local p1_atk   = lurek.input.pressed("p1_attack")
        local p1_spc   = lurek.input.pressed("p1_special")

        -- P2 input
        local p2_left  = lurek.input.down("p2_left")
        local p2_right = lurek.input.down("p2_right")
        local p2_jump  = lurek.input.pressed("p2_jump")
        local p2_atk   = lurek.input.pressed("p2_attack")
        local p2_spc   = lurek.input.pressed("p2_special")

        update_fighter(p1, dt, p1_left, p1_right, p1_jump, p1_atk, p1_spc)
        update_fighter(p2, dt, p2_left, p2_right, p2_jump, p2_atk, p2_spc)

        -- Projectile update
        local dead = {}
        for i, proj in ipairs(projectiles) do
            proj.x = proj.x + proj.vx * dt
            proj.y = proj.y + proj.vy * dt
            proj.life = proj.life - dt
            -- Trail particles
            if proj_trail_ps then
                lurek.particles.emit(proj_trail_ps, proj.x + PROJECTILE_SIZE * 0.5,
                                     proj.y + PROJECTILE_SIZE * 0.5, 1)
            end
            if proj.life <= 0 or proj.x < BLAST_LEFT or proj.x > BLAST_RIGHT then
                table.insert(dead, i)
            end
        end
        for j = #dead, 1, -1 do table.remove(projectiles, dead[j]) end

        check_projectile_hits()

        -- Auto face opponent
        if p1.atk_timer <= 0 and p2.atk_timer <= 0 then
            if p1.vx == 0 then p1.facing = (p2.x > p1.x) and 1 or -1 end
            if p2.vx == 0 then p2.facing = (p1.x > p2.x) and 1 or -1 end
        end
        return
    end

    -- ── KO state ─────────────────────────────────────────────────────
    if game_state == STATES.KO then
        ko_timer = ko_timer - dt
        if ko_timer <= 0 then
            -- Check for match over
            if p1.stocks <= 0 then
                match_winner = "PLAYER 2 WINS!"
                game_state = STATES.MATCH_OVER
            elseif p2.stocks <= 0 then
                match_winner = "PLAYER 1 WINS!"
                game_state = STATES.MATCH_OVER
            else
                game_state = STATES.FIGHTING
            end
        end
        return
    end

    -- ── MATCH_OVER state ─────────────────────────────────────────────
    if game_state == STATES.MATCH_OVER then
        if lurek.input.pressed("start") then
            game_state = STATES.TITLE
        end
    end
end)

-- ── Draw helpers ─────────────────────────────────────────────────────────
local function draw_platform(plat, color)
    lurek.render.rectangle("fill", plat.x, plat.y, plat.w, plat.h,
                           color[1], color[2], color[3], 1)
end

local function draw_fighter(f)
    -- Invulnerability blink
    if f.invuln > 0 then
        local blink = math.floor(f.invuln / BLINK_RATE) % 2
        if blink == 1 then return end
    end

    local c = f.color
    local alpha = 1.0

    -- Body rectangle
    lurek.render.rectangle("fill", f.x, f.y, FIGHTER_W, FIGHTER_H,
                           c[1], c[2], c[3], alpha)

    -- Simple face: two eyes + mouth
    local eye_y = f.y + 8
    local eye_lx = f.x + 5
    local eye_rx = f.x + 13
    lurek.render.rectangle("fill", eye_lx, eye_y, 3, 3, 1, 1, 1, alpha)
    lurek.render.rectangle("fill", eye_rx, eye_y, 3, 3, 1, 1, 1, alpha)
    lurek.render.rectangle("fill", f.x + 6, f.y + 16, 8, 2, 1, 1, 1, alpha)

    -- Attack indicator: small rectangle extending from fighter
    if f.atk_timer > 0 and f.cur_attack ~= nil then
        local atk_x = f.x + (f.facing == 1 and FIGHTER_W or -10)
        local atk_y = f.y + FIGHTER_H * 0.3
        local atk_w = 10
        local atk_h = 6
        if f.cur_attack.spike then
            -- Downward spike visual
            atk_x = f.x + 4
            atk_y = f.y + FIGHTER_H
            atk_w = 12
            atk_h = 8
        end
        lurek.render.rectangle("fill", atk_x, atk_y, atk_w, atk_h,
                               1, 1, 0.3, 0.9)
    end
end

local function draw_projectile(proj)
    lurek.render.circle("fill", proj.x + PROJECTILE_SIZE * 0.5,
                        proj.y + PROJECTILE_SIZE * 0.5, PROJECTILE_SIZE,
                        proj.color[1], proj.color[2], proj.color[3], 1)
end

local function draw_blast_indicators()
    -- Faint lines at blast zone edges (visible portion)
    local a = 0.15
    -- Left
    lurek.render.rectangle("fill", 0, 0, 2, SCREEN_H, 1, 0.3, 0.3, a)
    -- Right
    lurek.render.rectangle("fill", SCREEN_W - 2, 0, 2, SCREEN_H, 1, 0.3, 0.3, a)
    -- Top
    lurek.render.rectangle("fill", 0, 0, SCREEN_W, 2, 1, 0.3, 0.3, a)
    -- Bottom
    lurek.render.rectangle("fill", 0, SCREEN_H - 2, SCREEN_W, 2, 1, 0.3, 0.3, a)
end

-- ── lurek.render ─────────────────────────────────────────────────────────
lurek.render(function()
    -- ── TITLE ────────────────────────────────────────────────────────
    if game_state == STATES.TITLE then
        lurek.render.print("PLATFORM FIGHTER", SCREEN_W * 0.5 - 140, 180, 32, 1, 1, 1, 1)
        lurek.render.print("2 PLAYERS", SCREEN_W * 0.5 - 60, 230, 20, 0.8, 0.8, 0.8, 1)
        local show = math.floor(title_blink * 2) % 2 == 0
        if show then
            lurek.render.print("PRESS ENTER", SCREEN_W * 0.5 - 75, 320, 18, 0.9, 0.9, 0.3, 1)
        end
        -- Draw preview platforms
        for i, plat in ipairs(PLATFORMS) do
            local c = (i == 1) and PLAT_MAIN or PLAT_FLOAT
            draw_platform(plat, c)
        end
        return
    end

    -- ── FIGHTING / KO / MATCH_OVER arena ─────────────────────────────
    -- Blast zone indicators
    draw_blast_indicators()

    -- Platforms
    for i, plat in ipairs(PLATFORMS) do
        local c = (i == 1) and PLAT_MAIN or PLAT_FLOAT
        draw_platform(plat, c)
    end

    -- Fighters
    if p1 and p1.stocks > 0 then draw_fighter(p1) end
    if p2 and p2.stocks > 0 then draw_fighter(p2) end

    -- Projectiles
    for _, proj in ipairs(projectiles) do
        draw_projectile(proj)
    end
end)

-- ── lurek.render_ui ──────────────────────────────────────────────────────
lurek.render_ui(function()
    if game_state == STATES.TITLE then return end
    if not p1 or not p2 then return end

    -- ── Damage percentage display ────────────────────────────────────
    -- P1 damage (bottom left)
    local p1_dmg_str = string.format("%.0f%%", p1.damage_pct)
    local p1_r = 1
    local p1_g = math.max(0, 1.0 - p1.damage_pct / 150)
    local p1_b = math.max(0, 1.0 - p1.damage_pct / 100)
    local p1_flash_add = dmg_flash_p1 * 0.5
    lurek.render.print(p1_dmg_str, 80, SCREEN_H - 60, 28,
                       math.min(1, p1_r + p1_flash_add),
                       math.min(1, p1_g + p1_flash_add),
                       math.min(1, p1_b + p1_flash_add), 1)
    lurek.render.print("P1", 80, SCREEN_H - 82, 14,
                       P1_COLOR[1], P1_COLOR[2], P1_COLOR[3], 1)

    -- P2 damage (bottom right)
    local p2_dmg_str = string.format("%.0f%%", p2.damage_pct)
    local p2_r = 1
    local p2_g = math.max(0, 1.0 - p2.damage_pct / 150)
    local p2_b = math.max(0, 1.0 - p2.damage_pct / 100)
    local p2_flash_add = dmg_flash_p2 * 0.5
    lurek.render.print(p2_dmg_str, SCREEN_W - 140, SCREEN_H - 60, 28,
                       math.min(1, p2_r + p2_flash_add),
                       math.min(1, p2_g + p2_flash_add),
                       math.min(1, p2_b + p2_flash_add), 1)
    lurek.render.print("P2", SCREEN_W - 140, SCREEN_H - 82, 14,
                       P2_COLOR[1], P2_COLOR[2], P2_COLOR[3], 1)

    -- ── Stocks display ──────────────────────────────────────────────
    for i = 1, MAX_STOCKS do
        local sx = 80 + (i - 1) * 18
        local sy = SCREEN_H - 36
        local a = (i <= p1.stocks) and 1.0 or 0.2
        lurek.render.circle("fill", sx + 5, sy + 5, 6,
                            P1_COLOR[1], P1_COLOR[2], P1_COLOR[3], a)
    end
    for i = 1, MAX_STOCKS do
        local sx = SCREEN_W - 140 + (i - 1) * 18
        local sy = SCREEN_H - 36
        local a = (i <= p2.stocks) and 1.0 or 0.2
        lurek.render.circle("fill", sx + 5, sy + 5, 6,
                            P2_COLOR[1], P2_COLOR[2], P2_COLOR[3], a)
    end

    -- ── Special cooldown indicators ──────────────────────────────────
    if p1.special_cd > 0 then
        local pct = p1.special_cd / ATK_SPECIAL.cooldown
        lurek.render.rectangle("fill", 80, SCREEN_H - 18, 50 * (1 - pct), 4,
                               0.3, 0.8, 1, 0.7)
        lurek.render.rectangle("line", 80, SCREEN_H - 18, 50, 4,
                               0.5, 0.5, 0.5, 0.4)
    end
    if p2.special_cd > 0 then
        local pct = p2.special_cd / ATK_SPECIAL.cooldown
        lurek.render.rectangle("fill", SCREEN_W - 140, SCREEN_H - 18, 50 * (1 - pct), 4,
                               1, 0.5, 0.3, 0.7)
        lurek.render.rectangle("line", SCREEN_W - 140, SCREEN_H - 18, 50, 4,
                               0.5, 0.5, 0.5, 0.4)
    end

    -- ── KO text ──────────────────────────────────────────────────────
    if game_state == STATES.KO then
        local sz = math.floor(36 * ko_text_scale)
        lurek.render.print("KO!", SCREEN_W * 0.5 - sz, SCREEN_H * 0.5 - sz * 0.5,
                           sz, 1, 0.2, 0.2, 1)
        lurek.render.print(ko_who .. " SCORES!", SCREEN_W * 0.5 - 100,
                           SCREEN_H * 0.5 + 30, 20, 1, 1, 0.5, 1)
    end

    -- ── Match over text ──────────────────────────────────────────────
    if game_state == STATES.MATCH_OVER then
        lurek.render.print(match_winner, SCREEN_W * 0.5 - 120, SCREEN_H * 0.5 - 20,
                           30, 1, 1, 0.3, 1)
        lurek.render.print("PRESS ENTER TO RETURN", SCREEN_W * 0.5 - 120,
                           SCREEN_H * 0.5 + 30, 16, 0.8, 0.8, 0.8, 1)
    end
end)
