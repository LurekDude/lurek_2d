-- Boxing Ring — Sport Game (Lurek2D demo)
-- Classic two-fighter boxing. Dodge, block, jab, and hook your way to a TKO.
-- A / D move, W = dodge back, Space = jab, Z = hook, X = block.
-- Run with: cargo run -- content/demos/sports/boxing_ring

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local RING_X  = 90
local RING_Y  = 100
local RING_W  = 620
local RING_H  = 360
local FLOOR_Y = RING_Y + RING_H - 50

local MOVE_SPD   = 180
local JAB_DMG    = 6
local HOOK_DMG   = 14
local JAB_RANGE  = 90
local HOOK_RANGE = 75
local HP_MAX     = 100
local ROUNDS     = 3
local ROUND_TIME = 90  -- seconds

-- ── Helpers ──────────────────────────────────────────────────────────────

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end

-- ── State ─────────────────────────────────────────────────────────────────

local pl  = {}
local cpu = {}
local round = 1
local round_timer = ROUND_TIME
local game_state  = "playing"
local anim = 0
local msg = ""
local msg_timer = 0
local score_pl  = 0  -- round wins
local score_cpu = 0

local function show_msg(s, t)
    msg = s; msg_timer = t
end

local function reset_round()
    pl = {
        x = RING_X + 100, y = FLOOR_Y - 60,
        w = 30, h = 60, hp = HP_MAX,
        jab_cd = 0, hook_cd = 0, block = false,
        dodge = 0,    -- x-velocity boost from dodge
        stun = 0,     -- stun frames
        hit_flash = 0,
        facing = 1,
    }
    cpu = {
        x = RING_X + RING_W - 130, y = FLOOR_Y - 60,
        w = 30, h = 60, hp = HP_MAX,
        jab_cd = 0, hook_cd = 0, block = false,
        dodge = 0, stun = 0, hit_flash = 0,
        facing = -1,
        act_timer = 1.0,  -- next CPU action
    }
    round_timer = ROUND_TIME
    game_state = "playing"
end

local function reset()
    round = 1; score_pl = 0; score_cpu = 0
    reset_round()
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.render.setBackgroundColor(0.08, 0.05, 0.12)
    reset()
end

-- ── Hit detection ─────────────────────────────────────────────────────────

local function try_hit(attacker, defender, dmg, range)
    if defender.block then dmg = math.floor(dmg * 0.2) end
    if defender.stun > 0 then dmg = dmg + 4 end
    if math.abs(attacker.x - defender.x) < range then
        defender.hp = defender.hp - dmg
        defender.stun = 0.25
        defender.hit_flash = 0.18
        return true
    end
    return false
end

-- ── CPU AI ────────────────────────────────────────────────────────────────

local function cpu_ai(dt, cpu, pl)
    cpu.act_timer = cpu.act_timer - dt
    cpu.block = false

    if cpu.act_timer > 0 then return end
    cpu.act_timer = 0.5 + math.random() * 0.6

    local dist = math.abs(cpu.x - pl.x)
    -- Move toward player
    if dist > 70 then
        local dir = pl.x < cpu.x and -1 or 1
        cpu.x = clamp(cpu.x + dir * MOVE_SPD * 0.5, RING_X, RING_X + RING_W - cpu.w)
    end

    local r = math.random()
    if dist < JAB_RANGE and r < 0.5 and cpu.jab_cd <= 0 then
        cpu.jab_cd = 0.5
        try_hit(cpu, pl, JAB_DMG, 95)
    elseif dist < HOOK_RANGE and r < 0.3 and cpu.hook_cd <= 0 then
        cpu.hook_cd = 0.9
        try_hit(cpu, pl, HOOK_DMG, 80)
    elseif r < 0.25 then
        cpu.block = true
        cpu.act_timer = 0.4
    end
end

-- ── Update ────────────────────────────────────────────────────────────────

function lurek.process(dt)
    anim = anim + dt
    msg_timer = math.max(0, msg_timer - dt)
    if game_state ~= "playing" then return end

    round_timer = round_timer - dt
    if round_timer <= 0 then
        -- Judge round by HP
        if pl.hp > cpu.hp then score_pl = score_pl + 1
        elseif cpu.hp > pl.hp then score_cpu = score_cpu + 1 end
        round = round + 1
        if round > ROUNDS then
            game_state = "gameover"
        else
            show_msg("ROUND " .. round, 2)
            reset_round()
        end
        return
    end

    -- Player movement
    pl.jab_cd  = math.max(0, pl.jab_cd  - dt)
    pl.hook_cd = math.max(0, pl.hook_cd - dt)
    pl.stun    = math.max(0, pl.stun    - dt)
    pl.hit_flash = math.max(0, pl.hit_flash - dt)
    pl.block = false

    if pl.stun <= 0 then
        if lurek.input.isKeyDown("a") or lurek.input.isKeyDown("left") then
            pl.x = clamp(pl.x - MOVE_SPD * dt, RING_X, RING_X + RING_W - pl.w)
            pl.facing = -1
        end
        if lurek.input.isKeyDown("d") or lurek.input.isKeyDown("right") then
            pl.x = clamp(pl.x + MOVE_SPD * dt, RING_X, RING_X + RING_W - pl.w)
            pl.facing = 1
        end
        if lurek.input.isKeyDown("x") then
            pl.block = true
        end
    end

    -- CPU
    cpu.jab_cd   = math.max(0, cpu.jab_cd  - dt)
    cpu.hook_cd  = math.max(0, cpu.hook_cd - dt)
    cpu.stun     = math.max(0, cpu.stun    - dt)
    cpu.hit_flash = math.max(0, cpu.hit_flash - dt)
    cpu_ai(dt, cpu, pl)

    -- Face each other
    pl.facing  = pl.x < cpu.x and 1 or -1
    cpu.facing = cpu.x < pl.x and 1 or -1

    -- KO check
    if pl.hp <= 0 then
        pl.hp = 0; score_cpu = score_cpu + 1
        if round >= ROUNDS then game_state = "gameover"
        else show_msg("KNOCKED DOWN!", 2.5); round = round + 1; reset_round() end
    end
    if cpu.hp <= 0 then
        cpu.hp = 0; score_pl = score_pl + 1
        if round >= ROUNDS then game_state = "gameover"
        else show_msg("TKO! ROUND WIN!", 2.5); round = round + 1; reset_round() end
    end
end

-- ── Drawing helpers ────────────────────────────────────────────────────────

local function draw_boxer(bx, col, facing, is_blocking, is_punching, hp_pct)
    local x = bx.x; local y = bx.y
    local flash = bx.hit_flash > 0

    -- Shadow
    lurek.render.setColor(0, 0, 0, 0.3)
    lurek.render.circle("fill", x + bx.w/2, FLOOR_Y + 5, 18)

    -- Body
    local r, g, b = col[1], col[2], col[3]
    if flash then r, g, b = 1, 0.3, 0.3 end
    lurek.render.setColor(r, g, b)
    lurek.render.rectangle("fill", x + 5, y + 18, bx.w - 10, bx.h - 30)

    -- Shorts
    lurek.render.setColor(col[1] * 0.4, col[2] * 0.4, col[3] * 0.4)
    lurek.render.rectangle("fill", x + 5, y + 36, bx.w - 10, 14)

    -- Head
    lurek.render.setColor(0.85, 0.65, 0.4)
    lurek.render.circle("fill", x + bx.w/2, y + 12, 11)
    -- Gloves
    local gx = x + (facing > 0 and bx.w - 2 or -8)
    local jgx = x + (facing > 0 and bx.w + 10 or -20)
    lurek.render.setColor(col[1] * 1.2, col[2] * 0.5, col[3] * 0.5)
    if is_punching then
        lurek.render.circle("fill", jgx, y + 18, 9)
    else
        lurek.render.circle("fill", gx, y + 22, 9)
    end
    -- Block stance
    if is_blocking then
        lurek.render.setColor(col[1], col[2], col[3], 0.5)
        lurek.render.rectangle("fill", x - 3, y + 5, bx.w + 6, 28)
    end
end

local function draw_hpbar(x, y, vals, total, col, label)
    local bw = 200
    lurek.render.setColor(0.2, 0.2, 0.2)
    lurek.render.rectangle("fill", x, y, bw, 18)
    local pct = math.max(0, vals) / total
    local r = pct < 0.3 and 1 or (pct < 0.6 and 0.9 or col[1])
    local g = pct < 0.3 and 0.1 or (pct < 0.6 and 0.7 or col[2])
    lurek.render.setColor(r, g, col[3])
    lurek.render.rectangle("fill", x, y, bw * pct, 18)
    lurek.render.setColor(1, 1, 1)
    lurek.render.print(label .. ": " .. vals, x + 4, y + 1, 1.4)
end

function lurek.render()
    -- Ring floor
    lurek.render.setColor(0.7, 0.65, 0.5)
    lurek.render.rectangle("fill", RING_X, RING_Y, RING_W, RING_H)
    -- Ring canvas
    lurek.render.setColor(0.75, 0.7, 0.55)
    lurek.render.rectangle("fill", RING_X + 20, RING_Y + 20, RING_W - 40, RING_H - 40)
    -- Ropes
    for i = 1, 3 do
        local ry = RING_Y + i * (RING_H / 4)
        lurek.render.setColor(1, 0.1, 0.1)
        lurek.render.line(RING_X, ry, RING_X + RING_W, ry)
    end
    -- Corner posts
    lurek.render.setColor(0.5, 0.1, 0.1)
    for _, cx in ipairs({RING_X, RING_X + RING_W}) do
        lurek.render.rectangle("fill", cx - 5, RING_Y - 10, 10, RING_H + 20)
    end
    -- Center line
    lurek.render.setColor(0.6, 0.55, 0.4, 0.5)
    lurek.render.line(RING_X + RING_W/2, FLOOR_Y - 80, RING_X + RING_W/2, FLOOR_Y + 20)

    -- Fighters
    local pl_punch  = pl.jab_cd > 0.25 or pl.hook_cd > 0.55
    local cpu_punch = cpu.jab_cd > 0.25 or cpu.hook_cd > 0.55
    draw_boxer(pl, {0.2, 0.5, 0.9}, pl.facing, pl.block, pl_punch, pl.hp/HP_MAX)
    draw_boxer(cpu, {0.9, 0.3, 0.2}, cpu.facing, cpu.block, cpu_punch, cpu.hp/HP_MAX)

    -- HUD
    lurek.render.setColor(0, 0, 0, 0.7)
    lurek.render.rectangle("fill", 0, 0, W, 95)
    draw_hpbar(14, 12, pl.hp,  HP_MAX, {0.3, 0.5, 1}, "YOU")
    draw_hpbar(W - 214, 12, cpu.hp, HP_MAX, {1, 0.4, 0.3}, "CPU")

    -- Round / timer
    lurek.render.setColor(1, 0.9, 0.3)
    lurek.render.print("ROUND " .. round .. "/" .. ROUNDS, W/2 - 55, 8, 2.2)
    local secs = math.ceil(round_timer)
    local tc = secs <= 10 and {1, 0.2, 0.2} or {1, 1, 1}
    lurek.render.setColor(tc[1], tc[2], tc[3])
    lurek.render.print(string.format("%d:%02d", math.floor(secs/60), secs%60), W/2 - 22, 32, 2.5)

    -- Score
    lurek.render.setColor(0.4, 0.7, 1)
    lurek.render.print("YOU: " .. score_pl, W/2 - 110, 56, 1.8)
    lurek.render.setColor(1, 0.5, 0.4)
    lurek.render.print("CPU: " .. score_cpu, W/2 + 30, 56, 1.8)

    -- Controls reminder
    lurek.render.setColor(0.6, 0.6, 0.6, 0.7)
    lurek.render.rectangle("fill", 0, H - 22, W, 22)
    lurek.render.setColor(0.8, 0.9, 1, 0.9)
    lurek.render.print("[A/D] Move  [Space] Jab  [Z] Hook  [X] Block", 14, H - 18, 1.4)

    -- Float message
    if msg_timer > 0 then
        lurek.render.setColor(1, 1, 0.3, math.min(1, msg_timer))
        lurek.render.print(msg, W/2 - #msg * 7, H/2 - 10, 3)
    end

    -- Game over
    if game_state == "gameover" then
        lurek.render.setColor(0, 0, 0, 0.8)
        lurek.render.rectangle("fill", 0, 0, W, H)
        local winner = score_pl > score_cpu and "YOU WIN!" or (score_pl == score_cpu and "DRAW!" or "CPU WINS!")
        local col = score_pl > score_cpu and {0.3, 1, 0.4} or (score_pl == score_cpu and {1,1,0.3} or {1,0.3,0.3})
        lurek.render.setColor(col[1], col[2], col[3])
        lurek.render.print(winner, W/2 - #winner * 9, H/2 - 35, 3)
        lurek.render.setColor(0.5, 0.8, 1)
        lurek.render.print("You: " .. score_pl .. "   CPU: " .. score_cpu, W/2 - 80, H/2 + 15, 2.2)
        lurek.render.setColor(0.6, 0.6, 0.6)
        lurek.render.print("Press R to fight again", W/2 - 110, H/2 + 55, 2)
    end
end

-- ── Input ─────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    if game_state ~= "playing" then return end

    if key == "space" and pl.stun <= 0 and pl.jab_cd <= 0 then
        pl.jab_cd = 0.4
        try_hit(pl, cpu, JAB_DMG, JAB_RANGE)
    end
    if key == "z" and pl.stun <= 0 and pl.hook_cd <= 0 then
        pl.hook_cd = 0.8
        try_hit(pl, cpu, HOOK_DMG, HOOK_RANGE)
    end
end
