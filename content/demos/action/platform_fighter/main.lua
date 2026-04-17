-- Platform Fighter — Smash Bros style 2-player arena
-- Player 1: WASD + F(punch) + G(smash)  |  Player 2: Arrows + K(punch) + L(smash)
-- Run with: cargo run -- content/demos/action/platform_fighter

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600
local GRAVITY = 900
local GROUND_Y = 550
local BLAST_ZONE = { left = -100, right = 900, top = -150, bottom = 700 }

local platforms = {
    { x = 200, y = 400, w = 160, h = 12 },
    { x = 440, y = 320, w = 160, h = 12 },
    { x = 320, y = 220, w = 120, h = 12 },
    { x = 560, y = 440, w = 140, h = 12 },
    { x = 80,  y = 460, w = 120, h = 12 },
}

local function new_player(x, color_r, color_g, color_b, keys)
    return {
        x = x, y = GROUND_Y - 40, w = 28, h = 40,
        vx = 0, vy = 0, grounded = false, jumps = 0,
        cr = color_r, cg = color_g, cb = color_b,
        damage = 0, stocks = 3, dir = 1,
        attacking = false, atk_timer = 0, atk_type = nil,
        hitstun = 0, keys = keys, spawn_x = x,
        invuln = 0,
    }
end

local p1, p2
local match_over = false
local winner = 0

local function reset_match()
    p1 = new_player(200, 0.3, 0.5, 1.0, { left="a", right="d", up="w", down="s", punch="f", smash="g" })
    p2 = new_player(560, 1.0, 0.3, 0.3, { left="left", right="right", up="up", down="down", punch="k", smash="l" })
    match_over = false
    winner = 0
end

function lurek.init()
    lurek.window.setTitle("Platform Fighter")
    lurek.render.setBackgroundColor(0.12, 0.1, 0.18)
    reset_match()
end

local function on_platform(p)
    if p.vy < 0 then return false end
    for _, plat in ipairs(platforms) do
        if p.x + p.w > plat.x and p.x < plat.x + plat.w then
            local feet = p.y + p.h
            if feet >= plat.y and feet <= plat.y + plat.h + 6 and p.vy >= 0 then
                p.y = plat.y - p.h
                return true
            end
        end
    end
    if p.y + p.h >= GROUND_Y then
        p.y = GROUND_Y - p.h
        return true
    end
    return false
end

local function apply_knockback(target, attacker, power)
    local mult = 1 + target.damage / 80
    local dx = (target.x > attacker.x) and 1 or -1
    target.vx = dx * power * mult
    target.vy = -power * 0.7 * mult
    target.hitstun = 0.2 + target.damage / 500
end

local function check_attack_hit(atk, def)
    if not atk.attacking or atk.atk_timer > 0.05 then return end
    local reach = (atk.atk_type == "smash") and 50 or 35
    local ax = (atk.dir == 1) and (atk.x + atk.w) or (atk.x - reach)
    local ay = atk.y
    if ax < def.x + def.w and ax + reach > def.x and ay < def.y + def.h and ay + atk.h > def.y then
        if def.invuln > 0 then return end
        local dmg = (atk.atk_type == "smash") and 18 or 8
        local kb  = (atk.atk_type == "smash") and 350 or 180
        def.damage = def.damage + dmg
        apply_knockback(def, atk, kb)
    end
end

local function respawn(p)
    p.stocks = p.stocks - 1
    if p.stocks <= 0 then return end
    p.x = p.spawn_x
    p.y = 100
    p.vx = 0
    p.vy = 0
    p.damage = 0
    p.hitstun = 0
    p.invuln = 2.0
end

local function update_player(p, dt)
    if p.stocks <= 0 then return end
    p.hitstun = clamp(p.hitstun - dt, 0, 10)
    p.invuln  = clamp(p.invuln - dt, 0, 10)

    if p.hitstun <= 0 then
        local spd = 220
        if lurek.keyboard.isDown(p.keys.left) then p.vx = -spd; p.dir = -1 end
        if lurek.keyboard.isDown(p.keys.right) then p.vx = spd;  p.dir = 1 end
        if not lurek.keyboard.isDown(p.keys.left) and not lurek.keyboard.isDown(p.keys.right) then
            p.vx = p.vx * 0.85
        end
    end

    p.vy = p.vy + GRAVITY * dt
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt

    p.grounded = on_platform(p)
    if p.grounded then
        p.vy = 0
        p.jumps = 2
        p.vx = p.vx * 0.88
    end

    if p.attacking then
        local dur = (p.atk_type == "smash") and 0.35 or 0.15
        p.atk_timer = p.atk_timer + dt
        if p.atk_timer >= dur then p.attacking = false end
    end

    if p.x < BLAST_ZONE.left or p.x > BLAST_ZONE.right or p.y < BLAST_ZONE.top or p.y > BLAST_ZONE.bottom then
        respawn(p)
    end
end

function lurek.process(dt)
    if match_over then return end
    update_player(p1, dt)
    update_player(p2, dt)
    check_attack_hit(p1, p2)
    check_attack_hit(p2, p1)
    if p1.stocks <= 0 then match_over = true; winner = 2 end
    if p2.stocks <= 0 then match_over = true; winner = 1 end
end

local function draw_player(p, label)
    if p.stocks <= 0 then return end
    local alpha = (p.invuln > 0 and math.sin(lurek.time.getTime() * 20) > 0) and 0.3 or 1.0
    lurek.render.setColor(p.cr, p.cg, p.cb, alpha)
    lurek.render.rectangle("fill", p.x, p.y, p.w, p.h)
    -- eyes
    lurek.render.setColor(1, 1, 1, alpha)
    local ex = (p.dir == 1) and (p.x + 18) or (p.x + 6)
    lurek.render.rectangle("fill", ex, p.y + 10, 6, 6)
    -- attack flash
    if p.attacking then
        lurek.render.setColor(1, 1, 0, 0.6)
        local reach = (p.atk_type == "smash") and 50 or 35
        local ax = (p.dir == 1) and (p.x + p.w) or (p.x - reach)
        lurek.render.rectangle("fill", ax, p.y + 5, reach, p.h - 10)
    end
end

local function draw_hud(p, x_base, label)
    lurek.render.setColor(p.cr, p.cg, p.cb, 1)
    lurek.render.print(label, x_base, 10, 1.2)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(tostring(math.floor(p.damage)) .. "%", x_base, 35, 1.8)
    for i = 1, 3 do
        if i <= p.stocks then
            lurek.render.setColor(p.cr, p.cg, p.cb, 1)
            lurek.render.circle("fill", x_base + (i - 1) * 20 + 8, 75, 7)
        else
            lurek.render.setColor(0.3, 0.3, 0.3, 1)
            lurek.render.circle("line", x_base + (i - 1) * 20 + 8, 75, 7)
        end
    end
end

function lurek.render()
    -- ground
    lurek.render.setColor(0.25, 0.22, 0.3, 1)
    lurek.render.rectangle("fill", 0, GROUND_Y, W, H - GROUND_Y)
    -- platforms
    lurek.render.setColor(0.35, 0.3, 0.45, 1)
    for _, plat in ipairs(platforms) do
        lurek.render.rectangle("fill", plat.x, plat.y, plat.w, plat.h)
    end
    draw_player(p1, "P1")
    draw_player(p2, "P2")
    draw_hud(p1, 30, "P1")
    draw_hud(p2, W - 120, "P2")
    if match_over then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("PLAYER " .. winner .. " WINS!", W / 2 - 80, H / 2 - 20, 2)
        lurek.render.print("Press R to rematch", W / 2 - 70, H / 2 + 20, 1)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" and match_over then reset_match() end
    if match_over then return end
    -- P1 jump
    if key == p1.keys.up and p1.jumps > 0 and p1.hitstun <= 0 then
        p1.vy = -400; p1.jumps = p1.jumps - 1
    end
    -- P2 jump
    if key == p2.keys.up and p2.jumps > 0 and p2.hitstun <= 0 then
        p2.vy = -400; p2.jumps = p2.jumps - 1
    end
    -- P1 attacks
    if key == p1.keys.punch and not p1.attacking and p1.hitstun <= 0 then
        p1.attacking = true; p1.atk_timer = 0; p1.atk_type = "punch"
    end
    if key == p1.keys.smash and not p1.attacking and p1.hitstun <= 0 then
        p1.attacking = true; p1.atk_timer = 0; p1.atk_type = "smash"
    end
    -- P2 attacks
    if key == p2.keys.punch and not p2.attacking and p2.hitstun <= 0 then
        p2.attacking = true; p2.atk_timer = 0; p2.atk_type = "punch"
    end
    if key == p2.keys.smash and not p2.attacking and p2.hitstun <= 0 then
        p2.attacking = true; p2.atk_timer = 0; p2.atk_type = "smash"
    end
end
