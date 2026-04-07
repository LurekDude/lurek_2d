-- Cannon Fodder — Amiga 500 Classic (Luna2D demo)
-- Point-and-click squad-based top-down shooter inspired by Sensible Software's 1993 title.
-- Lead your three soldiers through the jungle, eliminate all enemies, and reach the flag.

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local SOLDIER_SPD = 100
local ENEMY_SPD   = 55
local BULLET_SPD  = 280
local ENEMY_SHOOT_RANGE = 220
local SCROLL_SPD  = 80

-- ── State ─────────────────────────────────────────────────────────────────

local squad = {}      -- Max 3 soldiers
local enemies = {}
local bullets = {}
local trees   = {}    -- Decorative obstacles
local flag    = {}    -- Objective marker
local world_y = 0     -- World scroll
local score, mission = 0, 1
local game_state = "playing"
local mouse_target = { x = W/2, y = H/2 }  -- Where squad walks to
local anim = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function overlap(ax,ay,aw,ah, bx,by,bw,bh)
    return ax < bx+bw and ax+aw > bx and ay < by+bh and ay+ah > by
end

local function dist2(ax,ay, bx,by) return (bx-ax)^2 + (by-ay)^2 end

-- ── Init ─────────────────────────────────────────────────────────────────

local function build_mission(m)
    squad = {}
    local count = math.max(1, 3 - (m - 1))
    for i = 1, count do
        squad[#squad+1] = { x = 100 + i * 30, y = H - 80, vx = 0, vy = 0,
                             hp = 3, alive = true, fire_cd = 0 }
    end

    enemies = {}
    local ecount = 3 + m * 2
    math.randomseed(m * 7)
    for _ = 1, ecount do
        enemies[#enemies+1] = {
            x = 80 + math.random(W - 160),
            y = 40 + math.random(H/2 - 80),
            vx = (math.random()-0.5)*20, vy = (math.random()-0.5)*20,
            hp = 2, alive = true, fire_cd = 1.5 + math.random()
        }
    end
    math.randomseed(os.time())

    trees = {}
    for _ = 1, 18 do
        trees[#trees+1] = { x = math.random(W - 30), y = math.random(H - 100), r = 14 + math.random(10) }
    end

    flag = { x = W/2 + math.random(-100, 100), y = 55, w = 24, h = 24 }
    world_y = 0
    game_state = "playing"
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.load()
    luna.graphics.setBackgroundColor(0.15, 0.32, 0.1)
    score = 0; mission = 1
    build_mission(mission)
end

-- ── Update ───────────────────────────────────────────────────────────────

function luna.update(dt)
    if game_state ~= "playing" then return end
    anim = anim + dt

    -- Move squad toward mouse_target (keyboard-simulated)
    local leader = nil
    for _, s in ipairs(squad) do if s.alive then leader = s; break end end

    for idx, s in ipairs(squad) do
        if not s.alive then goto next_s end
        s.fire_cd = math.max(0, s.fire_cd - dt)

        -- Formation offset from target
        local ox = (idx - 1) * 18 - (math.min(#squad, 3) - 1) * 9
        local tx = mouse_target.x + ox
        local ty = mouse_target.y + ox * 0.3

        local dx, dy = tx - s.x, ty - s.y
        local d = math.sqrt(dx*dx + dy*dy)
        if d > 5 then
            s.x = s.x + (dx / d) * SOLDIER_SPD * dt
            s.y = s.y + (dy / d) * SOLDIER_SPD * dt
        end

        -- Auto-shoot nearest enemy
        local best, best_d = nil, ENEMY_SHOOT_RANGE * ENEMY_SHOOT_RANGE
        for _, e in ipairs(enemies) do
            if e.alive then
                local dd = dist2(s.x, s.y, e.x, e.y)
                if dd < best_d then best = e; best_d = dd end
            end
        end
        if best and s.fire_cd <= 0 then
            local edx = best.x - s.x; local edy = best.y - s.y
            local ed = math.sqrt(edx*edx + edy*edy)
            bullets[#bullets+1] = {
                x = s.x + 8, y = s.y + 8,
                vx = edx / ed * BULLET_SPD, vy = edy / ed * BULLET_SPD,
                life = 0.9, enemy = false
            }
            s.fire_cd = 0.35
        end
        ::next_s::
    end

    -- Bullets
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt; b.y = b.y + b.vy * dt; b.life = b.life - dt
        if b.life <= 0 then table.remove(bullets, i) end
    end

    -- Enemies
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        if not e.alive then goto next_e end
        e.fire_cd = e.fire_cd - dt

        -- Move toward nearest soldier
        local best_s, best_sd = nil, 999999
        for _, s in ipairs(squad) do
            if s.alive then
                local dd = dist2(e.x, e.y, s.x, s.y)
                if dd < best_sd then best_s = s; best_sd = dd end
            end
        end
        if best_s then
            local ddx = best_s.x - e.x; local ddy = best_s.y - e.y
            local dd = math.sqrt(ddx*ddx + ddy*ddy)
            if dd > 30 then
                e.x = e.x + (ddx/dd) * ENEMY_SPD * dt
                e.y = e.y + (ddy/dd) * ENEMY_SPD * dt
            end
            if e.fire_cd <= 0 and dd < ENEMY_SHOOT_RANGE then
                e.fire_cd = 1.5 + math.random() * 0.5
                bullets[#bullets+1] = {
                    x = e.x + 8, y = e.y + 8,
                    vx = (ddx/dd) * BULLET_SPD * 0.65,
                    vy = (ddy/dd) * BULLET_SPD * 0.65,
                    life = 1.1, enemy = true
                }
            end
        end
        ::next_e::
    end

    -- Bullet hits
    for bi = #bullets, 1, -1 do
        if not bullets[bi] then goto bskip end
        local b = bullets[bi]
        if not b.enemy then
            for _, e in ipairs(enemies) do
                if e.alive and overlap(b.x-4,b.y-4,8,8, e.x,e.y,20,20) then
                    e.hp = e.hp - 1
                    if e.hp <= 0 then e.alive = false; score = score + 100 end
                    table.remove(bullets, bi); goto bskip
                end
            end
        else
            for _, s in ipairs(squad) do
                if s.alive and overlap(b.x-4,b.y-4,8,8, s.x,s.y,18,18) then
                    s.hp = s.hp - 1
                    if s.hp <= 0 then s.alive = false end
                    table.remove(bullets, bi); goto bskip
                end
            end
        end
        ::bskip::
    end

    -- Check all squad dead
    local any_alive = false
    for _, s in ipairs(squad) do if s.alive then any_alive = true; break end end
    if not any_alive then game_state = "gameover"; return end

    -- Check all enemies dead → flag
    local all_dead = true
    for _, e in ipairs(enemies) do if e.alive then all_dead = false; break end end
    if all_dead then
        -- Check squad reaches flag
        for _, s in ipairs(squad) do
            if s.alive and overlap(s.x,s.y,18,18, flag.x,flag.y,flag.w,flag.h) then
                score = score + mission * 500
                mission = mission + 1
                if mission > 5 then game_state = "win" else build_mission(mission) end
                return
            end
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function luna.draw()
    -- Ground
    luna.graphics.setColor(0.15, 0.32, 0.1)
    luna.graphics.rectangle("fill", 0, 0, W, H)

    -- Path / sand track
    luna.graphics.setColor(0.55, 0.48, 0.3, 0.5)
    luna.graphics.rectangle("fill", W/2 - 30, 0, 60, H)

    -- Trees
    for _, t in ipairs(trees) do
        luna.graphics.setColor(0.08, 0.22, 0.06)
        luna.graphics.circle("fill", t.x, t.y, t.r)
        luna.graphics.setColor(0.12, 0.30, 0.10)
        luna.graphics.circle("fill", t.x - 4, t.y - 4, t.r * 0.7)
    end

    -- Flag (objective)
    local all_dead = true
    for _, e in ipairs(enemies) do if e.alive then all_dead = false; break end end
    if all_dead then
        luna.graphics.setColor(0.9, 0.1, 0.1)
        luna.graphics.rectangle("fill", flag.x, flag.y, flag.w, flag.h)
        luna.graphics.setColor(1, 1, 1)
        luna.graphics.print("FLAG", flag.x + 1, flag.y + 5, 1.1)
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            luna.graphics.setColor(0.6, 0.4, 0.15)
            luna.graphics.rectangle("fill", e.x, e.y, 18, 20)
            luna.graphics.setColor(0.7, 0.55, 0.35)
            luna.graphics.circle("fill", e.x + 9, e.y + 6, 7)
            luna.graphics.setColor(0.5, 0.35, 0.1)
            luna.graphics.rectangle("fill", e.x - 1, e.y, 20, 6)
        end
    end

    -- Squad
    for i, s in ipairs(squad) do
        if s.alive then
            local pulsing = i == 1 and (0.8 + 0.2 * math.sin(anim * 5)) or 1
            luna.graphics.setColor(0.3 * pulsing, 0.6 * pulsing, 0.3 * pulsing)
            luna.graphics.rectangle("fill", s.x, s.y, 16, 18)
            luna.graphics.setColor(0.85, 0.7, 0.5)
            luna.graphics.circle("fill", s.x + 8, s.y + 6, 7)
            luna.graphics.setColor(0.3, 0.55, 0.3)
            luna.graphics.rectangle("fill", s.x - 1, s.y, 18, 6)
        end
    end

    -- Bullets
    luna.graphics.setColor(1, 0.9, 0.3)
    for _, b in ipairs(bullets) do
        if not b.enemy then luna.graphics.rectangle("fill", b.x - 2, b.y - 2, 5, 5) end
    end
    luna.graphics.setColor(1, 0.3, 0.1)
    for _, b in ipairs(bullets) do
        if b.enemy then luna.graphics.rectangle("fill", b.x - 2, b.y - 2, 5, 5) end
    end

    -- Target cursor
    luna.graphics.setColor(1, 1, 0, 0.6)
    luna.graphics.circle("line", mouse_target.x, mouse_target.y, 10)
    luna.graphics.line(mouse_target.x - 14, mouse_target.y, mouse_target.x + 14, mouse_target.y)
    luna.graphics.line(mouse_target.x, mouse_target.y - 14, mouse_target.x, mouse_target.y + 14)

    -- HUD
    luna.graphics.setColor(0, 0, 0, 0.65)
    luna.graphics.rectangle("fill", 0, 0, W, 30)
    luna.graphics.setColor(0.6, 1, 0.3)
    luna.graphics.print("CANNON FODDER", 8, 4, 1.8)
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print("Mission " .. mission .. "/5", W/2 - 50, 4, 1.7)
    luna.graphics.setColor(1, 0.8, 0.2)
    luna.graphics.print("Score: " .. score, W - 130, 4, 1.6)

    -- Controls hint
    luna.graphics.setColor(0.6, 0.8, 0.6, 0.7)
    luna.graphics.print("[WASD] Move squad  [Arrows] Pan view  Squad auto-fires!", 8, H - 20, 1.3)

    -- Overlay
    local ov_text, ov_col = nil, nil
    if game_state == "gameover" then ov_text = "ALL MEN LOST"; ov_col = {1,0.2,0.2}
    elseif game_state == "win"  then ov_text = "MISSION ACCOMPLISHED"; ov_col = {0.3,1,0.5} end
    if ov_text then
        luna.graphics.setColor(0, 0, 0, 0.75)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(ov_col[1], ov_col[2], ov_col[3])
        luna.graphics.print(ov_text, W/2 - #ov_text * 9, H/2 - 25, 3)
        luna.graphics.setColor(1, 1, 1)
        luna.graphics.print("Score: " .. score, W/2 - 50, H/2 + 20, 2)
        luna.graphics.setColor(0.6, 0.6, 0.6)
        luna.graphics.print("Press R to restart", W/2 - 100, H/2 + 55, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" then luna.load() end
end

function luna.update_extra(dt)
    -- Directional target movement via held keys (called from update)
end

-- Override update to also handle held-key target movement
local _upd = luna.update
luna.update = function(dt)
    if luna.input.isKeyDown("a") or luna.input.isKeyDown("left")  then mouse_target.x = math.max(20, mouse_target.x - 150 * dt) end
    if luna.input.isKeyDown("d") or luna.input.isKeyDown("right") then mouse_target.x = math.min(W-20, mouse_target.x + 150 * dt) end
    if luna.input.isKeyDown("w") or luna.input.isKeyDown("up")    then mouse_target.y = math.max(20, mouse_target.y - 150 * dt) end
    if luna.input.isKeyDown("s") or luna.input.isKeyDown("down")  then mouse_target.y = math.min(H-60, mouse_target.y + 150 * dt) end
    _upd(dt)
end
