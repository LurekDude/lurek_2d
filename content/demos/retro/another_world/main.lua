-- Another World — Amiga 500 Classic (Lurek2D demo)
-- Cinematic puzzle-platformer inspired by Eric Chahi's 1991 masterpiece.
-- Survive an alien planet using your energy gun: fire, shield, and super-shot.
-- Run with: cargo run -- content/demos/retro/another_world

-- ── Constants ────────────────────────────────────────────────────────────

local W, H      = 800, 600
local GRAVITY   = 700
local JUMP_VEL  = -420
local WALK_SPD  = 130
local ALIEN_SPD = 80
local BULLET_SPD = 380
local SHIELD_TIME = 2.5
local MAX_SHIELD = 3

-- ── Scene definitions (rooms) ─────────────────────────────────────────────

-- Each scene has platforms, exits, an enemy, and a story caption.
local SCENES = {
    { caption = "The jungle. Where am I?",
      platforms = { {0,520,W,80}, {180,360,260,20}, {560,300,180,20} },
      exits = { { x=W-10, y=390, w=15, h=130, to=2 } },
      enemy_start = {620, 270} },
    { caption = "A vast chamber beneath the city.",
      platforms = { {0,540,W,60}, {100,420,200,20}, {500,380,240,20}, {260,260,200,20} },
      exits = { { x=W-10, y=460, w=15, h=80, to=3 } },
      enemy_start = {550, 340} },
    { caption = "The prison gate. A way out?",
      platforms = { {0,560,W,40}, {50,430,150,20}, {600,400,160,20},{280,320,230,20} },
      exits = { { x=740, y=350, w=15, h=55, to=1 } },
      enemy_start = {620, 360} },
}

local COLORS = {
    sky_top    = {0.05, 0.05, 0.28},
    sky_bottom = {0.20, 0.12, 0.38},
    ground     = {0.30, 0.18, 0.50},
    ground_hi  = {0.55, 0.30, 0.75},
}

-- ── State ──────────────────────────────────────────────────────────────────

local player    = {}
local enemy     = {}
local bullets   = {}
local shield    = {}
local score     = 0
local current_scene = 1
local game_state = "playing"
local anim      = 0
local caption_timer = 3

-- ── Helpers ───────────────────────────────────────────────────────────────

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end

local function overlap(ax,ay,aw,ah, bx,by,bw,bh)
    return ax < bx+bw and ax+aw > bx and ay < by+bh and ay+ah > by
end

local function resolve_platforms(e, plats)
    e.on_ground = false
    for _, p in ipairs(plats) do
        if e.vy >= 0 and overlap(e.x+2, e.y, e.w-4, e.h+e.vy*0.02+2, p[1], p[2], p[3], p[4]) then
            if e.y + e.h <= p[2] + 8 then
                e.y = p[2] - e.h; e.vy = 0; e.on_ground = true; break
            end
        end
    end
    -- Floor
    if e.y + e.h >= H - 5 then e.y = H - 5 - e.h; e.vy = 0; e.on_ground = true end
end

local function load_scene(idx)
    local sc = SCENES[idx]
    current_scene = idx
    caption_timer = 3
    bullets = {}

    -- Player: place at left of scene
    player = { x = 60, y = 300, w = 26, h = 42,
               vx = 0, vy = 0, on_ground = false, facing = 1,
               shield_count = MAX_SHIELD, shield_active = false, shield_timer = 0 }

    -- Enemy
    local es = sc.enemy_start
    enemy = { x = es[1], y = es[2], w = 30, h = 44,
              vx = 0, vy = 0, on_ground = false, facing = -1,
              hp = 3, alive = true, shoot_cd = 2, fire_state = "patrol",
              shield_active = false, shield_hp = 2 }

    shield = {}
    game_state = "playing"
    anim = 0
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.gfx.setBackgroundColor(0.05, 0.05, 0.28)
    score = 0
    load_scene(1)
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    if game_state ~= "playing" then return end
    anim = anim + dt
    caption_timer = math.max(0, caption_timer - dt)
    local sc = SCENES[current_scene]

    -- ── Player movement ───────────────────────────────────────────────────
    local mv = 0
    if lurek.input.isKeyDown("left") or lurek.input.isKeyDown("a")  then mv = -1 end
    if lurek.input.isKeyDown("right") or lurek.input.isKeyDown("d") then mv =  1 end
    if mv ~= 0 then player.facing = mv end
    player.vx = mv * WALK_SPD

    -- Shield active
    player.shield_active = lurek.input.isKeyDown("z") and player.shield_count > 0
    if player.shield_active then
        player.shield_timer = player.shield_timer + dt
        if player.shield_timer >= SHIELD_TIME then
            player.shield_count = player.shield_count - 1
            player.shield_timer = 0
            if player.shield_count <= 0 then player.shield_active = false end
        end
    else
        player.shield_timer = math.max(0, player.shield_timer - dt * 0.5)
    end

    -- Gravity
    if not player.on_ground then player.vy = player.vy + GRAVITY * dt end
    player.x = clamp(player.x + player.vx * dt, 0, W - player.w)
    player.y = player.y + player.vy * dt
    resolve_platforms(player, sc.platforms)

    -- ── Enemy AI ──────────────────────────────────────────────────────────
    if enemy.alive then
        if not enemy.on_ground then enemy.vy = enemy.vy + GRAVITY * dt end
        -- Facing player
        enemy.facing = player.x > enemy.x and 1 or -1

        enemy.shoot_cd = enemy.shoot_cd - dt
        if enemy.shoot_cd <= 0 then
            enemy.shoot_cd = 1.5 + math.random()
            -- Shoot at player
            local dx = player.x + player.w/2 - (enemy.x + enemy.w/2)
            bullets[#bullets+1] = {
                x = enemy.x + (dx > 0 and enemy.w or 0),
                y = enemy.y + 18,
                vx = (dx > 0 and 1 or -1) * BULLET_SPD,
                owner = "enemy", r = 6
            }
        end

        enemy.x = clamp(enemy.x + enemy.facing * ALIEN_SPD * dt, 0, W - enemy.w)
        enemy.y = enemy.y + enemy.vy * dt
        resolve_platforms(enemy, sc.platforms)
    end

    -- ── Bullets ───────────────────────────────────────────────────────────
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        -- Off screen
        if b.x < -20 or b.x > W + 20 then table.remove(bullets, i); goto next_b end

        if b.owner == "player" then
            -- vs enemy
            if enemy.alive and overlap(b.x - b.r, b.y - b.r, b.r*2, b.r*2, enemy.x, enemy.y, enemy.w, enemy.h) then
                if enemy.shield_active then
                    enemy.shield_hp = enemy.shield_hp - 1
                    if enemy.shield_hp <= 0 then enemy.shield_active = false end
                else
                    enemy.hp = enemy.hp - 1
                    if enemy.hp <= 0 then enemy.alive = false; score = score + 500 end
                end
                table.remove(bullets, i); goto next_b
            end
        else
            -- vs player
            if player.shield_active then
                -- Deflect
                b.vx = -b.vx; b.owner = "player"
            elseif overlap(b.x - b.r, b.y - b.r, b.r*2, b.r*2, player.x, player.y, player.w, player.h) then
                game_state = "gameover"; return
            end
        end
        ::next_b::
    end

    -- Exit traversal
    for _, ex in ipairs(sc.exits) do
        if enemy.alive == false and overlap(player.x, player.y, player.w, player.h, ex.x, ex.y, ex.w, ex.h) then
            score = score + current_scene * 200
            load_scene(ex.to)
            return
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    local sc = SCENES[current_scene]

    -- Sky gradient blocks (simplified)
    lurek.gfx.setColor(COLORS.sky_top[1], COLORS.sky_top[2], COLORS.sky_top[3])
    lurek.gfx.rectangle("fill", 0, 0, W, H / 2)
    lurek.gfx.setColor(COLORS.sky_bottom[1], COLORS.sky_bottom[2], COLORS.sky_bottom[3])
    lurek.gfx.rectangle("fill", 0, H/2, W, H/2)

    -- Background silhouette shapes
    lurek.gfx.setColor(0.12, 0.07, 0.22)
    lurek.gfx.rectangle("fill", 0, H/2 - 40, W, 80)
    for i = 0, 6 do
        local h2 = 60 + math.sin(i * 2.7) * 30
        lurek.gfx.rectangle("fill", i * 120 - 20, H/2 - 40 - h2, 90, h2)
    end

    -- Platforms
    for _, p in ipairs(sc.platforms) do
        lurek.gfx.setColor(COLORS.ground[1], COLORS.ground[2], COLORS.ground[3])
        lurek.gfx.rectangle("fill", p[1], p[2], p[3], p[4])
        lurek.gfx.setColor(COLORS.ground_hi[1], COLORS.ground_hi[2], COLORS.ground_hi[3])
        lurek.gfx.rectangle("fill", p[1], p[2], p[3], 4)
    end

    -- Exits (glow)
    for _, ex in ipairs(sc.exits) do
        local show = not enemy.alive
        if show then
            lurek.gfx.setColor(0.1, 0.8, 0.9, 0.5 + 0.5 * math.sin(anim * 3))
            lurek.gfx.rectangle("fill", ex.x, ex.y, ex.w, ex.h)
        end
    end

    -- Enemy
    if enemy.alive then
        -- Shield glow
        if enemy.shield_active then
            lurek.gfx.setColor(0.8, 0.3, 0.1, 0.4)
            lurek.gfx.circle("fill", enemy.x + enemy.w/2, enemy.y + enemy.h/2, 30)
        end
        lurek.gfx.setColor(0.3, 0.6, 0.35)
        lurek.gfx.rectangle("fill", enemy.x + 4, enemy.y + 14, enemy.w - 8, enemy.h - 14)
        lurek.gfx.setColor(0.2, 0.45, 0.25)
        lurek.gfx.circle("fill", enemy.x + enemy.w/2, enemy.y + 12, 14)
        -- Eyes
        local ex2 = enemy.facing > 0 and enemy.x + enemy.w - 10 or enemy.x + 6
        lurek.gfx.setColor(1, 0.3, 0)
        lurek.gfx.circle("fill", ex2, enemy.y + 10, 4)
        -- HP
        lurek.gfx.setColor(0.8, 0.2, 0.2)
        lurek.gfx.rectangle("fill", enemy.x, enemy.y - 8, enemy.w, 5)
        lurek.gfx.setColor(0.1, 0.9, 0.2)
        lurek.gfx.rectangle("fill", enemy.x, enemy.y - 8, enemy.w * (enemy.hp / 3), 5)
    end

    -- Bullets
    for _, b in ipairs(bullets) do
        if b.owner == "player" then
            lurek.gfx.setColor(0.3, 0.9, 1)
        else
            lurek.gfx.setColor(0.9, 0.4, 0.1)
        end
        lurek.gfx.circle("fill", b.x, b.y, b.r)
    end

    -- Player
    -- Shield
    if player.shield_active then
        lurek.gfx.setColor(0.3, 0.7, 1, 0.35)
        lurek.gfx.circle("fill", player.x + player.w/2, player.y + player.h/2, 28)
    end
    lurek.gfx.setColor(0.7, 0.6, 0.4)
    lurek.gfx.rectangle("fill", player.x + 3, player.y + 16, player.w - 6, player.h - 16)
    lurek.gfx.setColor(0.8, 0.7, 0.55)
    lurek.gfx.circle("fill", player.x + player.w/2, player.y + 14, 13)
    -- Gun arm
    local garm_x = player.x + (player.facing > 0 and player.w or 0)
    lurek.gfx.setColor(0.6, 0.5, 0.3)
    lurek.gfx.rectangle("fill", garm_x - 3, player.y + 18, 12, 6)

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.6)
    lurek.gfx.rectangle("fill", 0, 0, W, 28)
    lurek.gfx.setColor(0.4, 0.8, 1)
    lurek.gfx.print("ANOTHER WORLD", 8, 4, 1.8)
    lurek.gfx.setColor(1, 0.8, 0.3)
    lurek.gfx.print("Score: " .. score, W/2 - 50, 4, 1.6)
    -- Shield charges
    for i = 1, MAX_SHIELD do
        local sx = W - 28 * i - 6
        lurek.gfx.setColor(i <= player.shield_count and 0.3 or 0.25, i <= player.shield_count and 0.7 or 0.25, i <= player.shield_count and 1 or 0.25)
        lurek.gfx.rectangle("fill", sx, 4, 22, 20)
    end

    -- Scene caption
    if caption_timer > 0 then
        local alpha = math.min(1, caption_timer)
        lurek.gfx.setColor(1, 1, 0.8, alpha)
        lurek.gfx.print(sc.caption, W/2 - #sc.caption * 6, H - 45, 1.6)
    end

    lurek.gfx.setColor(0.5, 0.6, 0.7, 0.65)
    lurek.gfx.print("[A/D] Walk  [Space/W] Jump  [X] Shoot  [Z] Shield  Defeat enemy→reach exit", 8, H - 20, 1.2)

    -- Overlay
    if game_state == "gameover" then
        lurek.gfx.setColor(0, 0, 0, 0.85)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
        lurek.gfx.setColor(0.4, 0.8, 1)
        lurek.gfx.print("YOU ARE DEAD", W/2 - 92, H/2 - 25, 3)
        lurek.gfx.setColor(1, 0.9, 0.5)
        lurek.gfx.print("Score: " .. score, W/2 - 50, H/2 + 20, 2)
        lurek.gfx.setColor(0.6, 0.6, 0.6)
        lurek.gfx.print("Press R to restart", W/2 - 100, H/2 + 55, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    if game_state ~= "playing" then return end
    if (key == "space" or key == "up" or key == "w") and player.on_ground then
        player.vy = JUMP_VEL
    end
    if key == "x" then
        bullets[#bullets+1] = {
            x = player.x + (player.facing > 0 and player.w or 0),
            y = player.y + 18,
            vx = player.facing * BULLET_SPD,
            owner = "player", r = 7
        }
    end
end
