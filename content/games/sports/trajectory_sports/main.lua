-- Trajectory Sports — Lurek2D
-- Category: sports
-- Four projectile-based minigames: Archery, Basketball, Bowling, Darts.
-- Controls: Space=power, W/S=aim, A/D=move, 1-4=select sport, Escape=quit
-- Run with: cargo run -- content/games/sports/trajectory_sports

-- ── Constants ─────────────────────────────────────────────────────
local W, H = 800, 600
local GRAVITY = 400
local PI = math.pi

-- ── States ────────────────────────────────────────────────────────
local S_TITLE        = "TITLE"
local S_SPORT_SELECT = "SPORT_SELECT"
local S_PLAYING      = "PLAYING"
local S_ROUND_END    = "ROUND_END"
local S_FINAL_SCORES = "FINAL_SCORES"

-- ── Game state ────────────────────────────────────────────────────
local state = S_TITLE
local sport = 0          -- 1=archery 2=basketball 3=bowling 4=darts
local title_blink = 0
local transition_timer = 0
local particles = {}
local tweens = {}
---@type any
local _cam = nil

-- Per-sport scores
local scores = { 0, 0, 0, 0 }
local medals = { "", "", "", "" }
local sport_names = { "ARCHERY", "BASKETBALL", "BOWLING", "DARTS" }

-- ── Input bindings ────────────────────────────────────────────────
lurek.input.bind("power",      "space")
lurek.input.bind("aim_up",     "w")
lurek.input.bind("aim_down",   "s")
lurek.input.bind("move_left",  "a")
lurek.input.bind("move_right", "d")
lurek.input.bind("select1",    "1")
lurek.input.bind("select2",    "2")
lurek.input.bind("select3",    "3")
lurek.input.bind("select4",    "4")
lurek.input.bind("quit",       "escape")

-- ── Helpers ───────────────────────────────────────────────────────
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function lerp(a, b, t) return a + (b - a) * t end

local function spawn_particles(x, y, count, r, g, b, speed, life)
    speed = speed or 80
    life = life or 0.4
    for _ = 1, count do
        local a = math.random() * PI * 2
        local s = speed * (0.4 + math.random() * 0.6)
        particles[#particles + 1] = {
            x = x, y = y,
            vx = math.cos(a) * s, vy = math.sin(a) * s,
            life = life + math.random() * 0.2,
            r = r, g = g, b = b, a = 1,
            size = 2 + math.random() * 3,
        }
    end
end

local function add_tween(target, field, from, to, dur, delay)
    delay = delay or 0
    tweens[#tweens + 1] = {
        target = target, field = field,
        from = from, to = to,
        elapsed = -delay, dur = dur,
    }
end

local function update_tweens(dt)
    for i = #tweens, 1, -1 do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        if tw.elapsed >= 0 then
            local t = clamp(tw.elapsed / tw.dur, 0, 1)
            -- ease out quad
            local e = 1 - (1 - t) * (1 - t)
            tw.target[tw.field] = lerp(tw.from, tw.to, e)
            if t >= 1 then table.remove(tweens, i) end
        end
    end
end

local function update_particles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 120 * dt
        p.life = p.life - dt
        p.a = clamp(p.life / 0.3, 0, 1)
        p.size = math.max(0.5, p.size - dt * 3)
        if p.life <= 0 then table.remove(particles, i) end
    end
end

local function medal_for(sport_id, score)
    if sport_id == 1 then -- archery: max 100
        if score >= 80 then return "GOLD"
        elseif score >= 55 then return "SILVER"
        elseif score >= 30 then return "BRONZE" end
    elseif sport_id == 2 then -- basketball: max 30
        if score >= 24 then return "GOLD"
        elseif score >= 16 then return "SILVER"
        elseif score >= 8 then return "BRONZE" end
    elseif sport_id == 3 then -- bowling: around 300 max
        if score >= 150 then return "GOLD"
        elseif score >= 90 then return "SILVER"
        elseif score >= 40 then return "BRONZE" end
    elseif sport_id == 4 then -- darts: 301 countdown, lower remaining is better
        if score <= 50 then return "GOLD"
        elseif score <= 150 then return "SILVER"
        elseif score <= 250 then return "BRONZE" end
    end
    return "NONE"
end

local function medal_points(m)
    if m == "GOLD" then return 3
    elseif m == "SILVER" then return 2
    elseif m == "BRONZE" then return 1 end
    return 0
end

local function final_rank()
    local total = 0
    for i = 1, 4 do total = total + medal_points(medals[i]) end
    if total >= 10 then return "CHAMPION"
    elseif total >= 7 then return "GOLD"
    elseif total >= 4 then return "SILVER"
    elseif total >= 2 then return "BRONZE" end
    return "PARTICIPANT"
end

-- ═══════════════════════════════════════════════════════════════════
-- ARCHERY
-- ═══════════════════════════════════════════════════════════════════
local arch = {
    power = 0, angle = 20, charging = false,
    arrows_left = 10, score = 0, display_score = 0,
    wind = 0, arrow = nil, target_x = 650, target_y = 300,
}

local function archery_reset()
    arch.power = 0; arch.angle = 20; arch.charging = false
    arch.arrows_left = 10; arch.score = 0; arch.display_score = 0
    arch.arrow = nil
    arch.wind = (math.random() - 0.5) * 80
end

local function archery_fire()
    local rad = math.rad(arch.angle)
    local vel = arch.power * 5
    arch.arrow = {
        x = 100, y = 400,
        vx = math.cos(rad) * vel,
        vy = -math.sin(rad) * vel,
        trail_t = 0,
    }
    arch.charging = false
    arch.power = 0
end

local function archery_score_arrow(ax, ay)
    local d = dist(ax, ay, arch.target_x, arch.target_y)
    if d < 12 then return 10      -- bullseye
    elseif d < 25 then return 8
    elseif d < 40 then return 6
    elseif d < 55 then return 4
    elseif d < 70 then return 2
    end
    return 0
end

local function archery_update(dt)
    -- Aim
    if lurek.input.isActionDown("aim_up") then
        arch.angle = clamp(arch.angle + 60 * dt, 0, 45)
    end
    if lurek.input.isActionDown("aim_down") then
        arch.angle = clamp(arch.angle - 60 * dt, 0, 45)
    end

    -- Charge
    if arch.arrow == nil and arch.arrows_left > 0 then
        if lurek.input.isActionDown("power") then
            arch.charging = true
            arch.power = clamp(arch.power + 80 * dt, 0, 100)
        elseif arch.charging then
            archery_fire()
        end
    end

    -- Arrow flight
    if arch.arrow then
        ---@type {x:number,y:number,vx:number,vy:number,trail_t:number}
        local a = arch.arrow
        a.vx = a.vx + arch.wind * dt
        a.vy = a.vy + GRAVITY * dt
        a.x = a.x + a.vx * dt
        a.y = a.y + a.vy * dt
        -- Trail particles
        a.trail_t = a.trail_t + dt
        if a.trail_t > 0.02 then
            a.trail_t = 0
            spawn_particles(a.x, a.y, 1, 0.8, 0.6, 0.2, 20, 0.3)
        end
        -- Hit target zone or off screen
        if a.x >= arch.target_x - 70 then
            local pts = archery_score_arrow(a.x, a.y)
            arch.score = arch.score + pts
            add_tween(arch, "display_score", arch.display_score, arch.score, 0.4)
            spawn_particles(a.x, a.y, 10, 1, 0.9, 0.3, 60, 0.3)
            arch.arrow = nil
            arch.arrows_left = arch.arrows_left - 1
            arch.wind = (math.random() - 0.5) * 80
        elseif a.y > H + 20 or a.x > W + 20 then
            arch.arrow = nil
            arch.arrows_left = arch.arrows_left - 1
            arch.wind = (math.random() - 0.5) * 80
        end
    end

    if arch.arrows_left <= 0 and arch.arrow == nil then
        scores[1] = arch.score
        medals[1] = medal_for(1, arch.score)
        state = S_ROUND_END
        transition_timer = 3
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- BASKETBALL
-- ═══════════════════════════════════════════════════════════════════
local bball = {
    power = 0, angle = 55, charging = false,
    shots_left = 10, score = 0, display_score = 0,
    ball = nil, hoop_x = 620, hoop_y = 200, rim_r = 20,
    player_x = 150, player_y = 430,
}

local function bball_reset()
    bball.power = 0; bball.angle = 55; bball.charging = false
    bball.shots_left = 10; bball.score = 0; bball.display_score = 0
    bball.ball = nil
end

local function bball_shoot()
    local rad = math.rad(bball.angle)
    local vel = bball.power * 5.5
    bball.ball = {
        x = bball.player_x + 20, y = bball.player_y - 30,
        vx = math.cos(rad) * vel,
        vy = -math.sin(rad) * vel,
        trail_t = 0, bounced = false,
    }
    bball.charging = false
    bball.power = 0
end

local function bball_update(dt)
    if lurek.input.isActionDown("aim_up") then
        bball.angle = clamp(bball.angle + 50 * dt, 30, 80)
    end
    if lurek.input.isActionDown("aim_down") then
        bball.angle = clamp(bball.angle - 50 * dt, 30, 80)
    end

    if bball.ball == nil and bball.shots_left > 0 then
        if lurek.input.isActionDown("power") then
            bball.charging = true
            bball.power = clamp(bball.power + 70 * dt, 0, 100)
        elseif bball.charging then
            bball_shoot()
        end
    end

    if bball.ball then
        ---@type {x:number,y:number,vx:number,vy:number,trail_t:number,bounced:boolean}
        local b = bball.ball
        b.vy = b.vy + GRAVITY * dt
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt

        b.trail_t = b.trail_t + dt
        if b.trail_t > 0.03 then
            b.trail_t = 0
            spawn_particles(b.x, b.y, 1, 1.0, 0.5, 0.1, 15, 0.2)
        end

        -- Check scoring zone: near hoop, moving downward
        local d = dist(b.x, b.y, bball.hoop_x, bball.hoop_y)
        if d < bball.rim_r and b.vy > 0 then
            -- Swish (clean entry)
            local pts = 3
            bball.score = bball.score + pts
            add_tween(bball, "display_score", bball.display_score, bball.score, 0.4)
            spawn_particles(bball.hoop_x, bball.hoop_y, 15, 1, 0.8, 0.2, 100, 0.5)
            bball.ball = nil
            bball.shots_left = bball.shots_left - 1
        elseif d < bball.rim_r + 12 and d >= bball.rim_r and not b.bounced then
            -- Rim bounce
            b.bounced = true
            b.vy = -math.abs(b.vy) * 0.5
            b.vx = b.vx * 0.3
            spawn_particles(b.x, b.y, 5, 0.8, 0.3, 0.1, 40, 0.2)
            -- Check if it falls in after bounce
        elseif b.bounced and d < bball.rim_r and b.vy > 0 then
            bball.score = bball.score + 2
            add_tween(bball, "display_score", bball.display_score, bball.score, 0.4)
            spawn_particles(bball.hoop_x, bball.hoop_y, 10, 1, 0.6, 0.1, 80, 0.4)
            bball.ball = nil
            bball.shots_left = bball.shots_left - 1
        elseif b.y > H + 30 or b.x > W + 30 or b.x < -30 then
            bball.ball = nil
            bball.shots_left = bball.shots_left - 1
        end
    end

    if bball.shots_left <= 0 and bball.ball == nil then
        scores[2] = bball.score
        medals[2] = medal_for(2, bball.score)
        state = S_ROUND_END
        transition_timer = 3
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- BOWLING
-- ═══════════════════════════════════════════════════════════════════
local bowl = {
    ball_x = 400, ball_y = 540, ball_vx = 0, ball_vy = 0,
    power = 0, charging = false, rolling = false, spin = 0,
    pins = {}, frame = 1, throw_in_frame = 1,
    frame_scores = {}, total_score = 0, display_score = 0,
}

local PIN_R = 8
local BALL_R = 10
local pin_start_y = 80

local function make_pins()
    local pins = {}
    local rows = { {0}, {-15, 15}, {-30, 0, 30}, {-45, -15, 15, 45} }
    for row_i, row in ipairs(rows) do
        for _, ox in ipairs(row) do
            pins[#pins + 1] = {
                x = 400 + ox, y = pin_start_y + (row_i - 1) * 25,
                vx = 0, vy = 0, alive = true,
            }
        end
    end
    return pins
end

local function bowl_reset()
    bowl.ball_x = 400; bowl.ball_y = 540
    bowl.ball_vx = 0; bowl.ball_vy = 0
    bowl.power = 0; bowl.charging = false; bowl.rolling = false; bowl.spin = 0
    bowl.pins = make_pins()
    bowl.frame = 1; bowl.throw_in_frame = 1
    bowl.frame_scores = {}; bowl.total_score = 0; bowl.display_score = 0
end

local function count_standing()
    local c = 0
    for _, p in ipairs(bowl.pins) do if p.alive then c = c + 1 end end
    return c
end

local function bowl_end_throw()
    bowl.rolling = false
    local knocked = 10 - count_standing()
    local frame_entry = bowl.frame_scores[bowl.frame] or { throws = {}, total = 0 }

    if bowl.throw_in_frame == 1 then
        frame_entry.throws[1] = knocked
        if knocked == 10 then
            -- Strike
            frame_entry.total = 10
            frame_entry.strike = true
            bowl.frame_scores[bowl.frame] = frame_entry
            spawn_particles(400, pin_start_y + 30, 20, 1, 0.9, 0.2, 120, 0.5)
            if bowl.frame < 10 then
                bowl.frame = bowl.frame + 1
                bowl.throw_in_frame = 1
                bowl.pins = make_pins()
            else
                bowl_finalize()
                return
            end
        else
            bowl.frame_scores[bowl.frame] = frame_entry
            bowl.throw_in_frame = 2
        end
    else
        local first_throw = frame_entry.throws[1] or 0
        frame_entry.throws[2] = knocked - first_throw
        if knocked == 10 then
            frame_entry.spare = true
            frame_entry.total = 5 + (10 - first_throw)
            spawn_particles(400, pin_start_y + 30, 12, 0.2, 0.8, 1.0, 80, 0.4)
        else
            frame_entry.total = knocked
        end
        bowl.frame_scores[bowl.frame] = frame_entry
        if bowl.frame < 10 then
            bowl.frame = bowl.frame + 1
            bowl.throw_in_frame = 1
            bowl.pins = make_pins()
        else
            bowl_finalize()
            return
        end
    end

    -- Reset ball position for next throw
    bowl.ball_x = 400; bowl.ball_y = 540
    bowl.ball_vx = 0; bowl.ball_vy = 0
    bowl.power = 0; bowl.spin = 0
end

function bowl_finalize()
    local t = 0
    for _, fs in pairs(bowl.frame_scores) do t = t + (fs.total or 0) end
    bowl.total_score = t
    scores[3] = t
    medals[3] = medal_for(3, t)
    state = S_ROUND_END
    transition_timer = 3
end

local function bowl_update(dt)
    if not bowl.rolling then
        -- Position
        if lurek.input.isActionDown("move_left") then
            bowl.ball_x = clamp(bowl.ball_x - 200 * dt, 300, 500)
        end
        if lurek.input.isActionDown("move_right") then
            bowl.ball_x = clamp(bowl.ball_x + 200 * dt, 300, 500)
        end
        -- Power charge
        if lurek.input.isActionDown("power") then
            bowl.charging = true
            bowl.power = clamp(bowl.power + 70 * dt, 0, 100)
        elseif bowl.charging then
            bowl.charging = false
            bowl.rolling = true
            bowl.ball_vy = -(bowl.power / 100) * 500
            bowl.ball_vx = 0
            bowl.spin = 0
        end
    else
        -- Spin during roll
        if lurek.input.isActionDown("move_left") then
            bowl.spin = clamp(bowl.spin - 300 * dt, -150, 150)
        end
        if lurek.input.isActionDown("move_right") then
            bowl.spin = clamp(bowl.spin + 300 * dt, -150, 150)
        end

        bowl.ball_vx = bowl.ball_vx + bowl.spin * dt
        bowl.ball_x = bowl.ball_x + bowl.ball_vx * dt
        bowl.ball_y = bowl.ball_y + bowl.ball_vy * dt
        bowl.ball_x = clamp(bowl.ball_x, 300, 500)

        -- Pin collision
        for _, p in ipairs(bowl.pins) do
            if p.alive then
                local d = dist(bowl.ball_x, bowl.ball_y, p.x, p.y)
                if d < BALL_R + PIN_R then
                    p.alive = false
                    local dx, dy = p.x - bowl.ball_x, p.y - bowl.ball_y
                    local nd = math.max(d, 0.01)
                    p.vx = (dx / nd) * 200
                    p.vy = (dy / nd) * 200
                    spawn_particles(p.x, p.y, 4, 1, 1, 1, 60, 0.3)
                end
            end
        end

        -- Pin-to-pin chain
        for i, p1 in ipairs(bowl.pins) do
            if not p1.alive and (math.abs(p1.vx) > 10 or math.abs(p1.vy) > 10) then
                for j, p2 in ipairs(bowl.pins) do
                    if i ~= j and p2.alive then
                        local d = dist(p1.x, p1.y, p2.x, p2.y)
                        if d < PIN_R * 2.5 then
                            p2.alive = false
                            local dx, dy = p2.x - p1.x, p2.y - p1.y
                            local nd = math.max(d, 0.01)
                            p2.vx = (dx / nd) * 120
                            p2.vy = (dy / nd) * 120
                            spawn_particles(p2.x, p2.y, 3, 1, 1, 0.8, 40, 0.2)
                        end
                    end
                end
                p1.vx = p1.vx * 0.9
                p1.vy = p1.vy * 0.9
            end
        end

        -- Update dead pin positions (visual)
        for _, p in ipairs(bowl.pins) do
            if not p.alive then
                p.x = p.x + p.vx * dt
                p.y = p.y + p.vy * dt
                p.vx = p.vx * 0.95
                p.vy = p.vy * 0.95
            end
        end

        -- Ball reached end or stopped
        if bowl.ball_y < pin_start_y - 40 or
           (math.abs(bowl.ball_vy) < 5 and math.abs(bowl.ball_vx) < 5) then
            bowl_end_throw()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- DARTS
-- ═══════════════════════════════════════════════════════════════════
local dart = {
    cx = 400, cy = 280, board_r = 140,
    crosshair_x = 400, crosshair_y = 280,
    wobble_t = 0, wobble_speed = 1.8,
    remaining = 301, darts_in_turn = 3, turn = 1, max_turns = 5,
    thrown = false, throw_anim = 0,
    hit_x = 0, hit_y = 0, last_points = 0,
    hits = {},
}

local function dart_reset()
    dart.remaining = 301; dart.darts_in_turn = 3; dart.turn = 1
    dart.thrown = false; dart.throw_anim = 0
    dart.wobble_t = math.random() * 10
    dart.hits = {}
    dart.last_points = 0
end

local function dart_score_hit(hx, hy)
    local dx, dy = hx - dart.cx, hy - dart.cy
    local d = math.sqrt(dx * dx + dy * dy)
    local r = dart.board_r

    -- Bullseye regions
    if d < r * 0.04 then return 50 end    -- double bull
    if d < r * 0.10 then return 25 end    -- single bull

    -- Segment angle (20 segments)
    local seg_order = { 20, 1, 18, 4, 13, 6, 10, 15, 2, 17,
                        3, 19, 7, 16, 8, 11, 14, 9, 12, 5 }
    local angle = math.atan2(dy, dx)
    if angle < 0 then angle = angle + PI * 2 end
    local seg_angle = PI / 20  -- half segment
    local rotated = angle + seg_angle
    if rotated >= PI * 2 then rotated = rotated - PI * 2 end
    local seg_idx = math.floor(rotated / (PI * 2 / 20)) + 1
    seg_idx = clamp(seg_idx, 1, 20)
    local base = seg_order[seg_idx]

    -- Ring multipliers
    local norm = d / r
    if norm > 1.0 then return 0 end       -- off board
    if norm > 0.90 then return base * 2 end -- double ring
    if norm > 0.82 then return base end
    if norm > 0.48 then return base * 3 end -- triple ring
    if norm > 0.40 then return base end
    return base
end

local function dart_update(dt)
    dart.wobble_t = dart.wobble_t + dt * dart.wobble_speed

    if not dart.thrown then
        -- Figure-8 wobble
        local wx = math.sin(dart.wobble_t * 2.3) * 60
        local wy = math.sin(dart.wobble_t * 1.7) * 40
        dart.crosshair_x = dart.cx + wx
        dart.crosshair_y = dart.cy + wy

        if lurek.input.isActionDown("power") and dart.darts_in_turn > 0 then
            dart.thrown = true
            dart.throw_anim = 0.3
            dart.hit_x = dart.crosshair_x
            dart.hit_y = dart.crosshair_y
            local pts = dart_score_hit(dart.hit_x, dart.hit_y)
            dart.last_points = pts
            dart.remaining = math.max(0, dart.remaining - pts)
            dart.darts_in_turn = dart.darts_in_turn - 1
            dart.hits[#dart.hits + 1] = { x = dart.hit_x, y = dart.hit_y, pts = pts }
            spawn_particles(dart.hit_x, dart.hit_y, 8, 0.9, 0.2, 0.2, 50, 0.3)
        end
    else
        dart.throw_anim = dart.throw_anim - dt
        if dart.throw_anim <= 0 then
            dart.thrown = false
            -- Check turn end
            if dart.darts_in_turn <= 0 then
                if dart.turn >= dart.max_turns or dart.remaining <= 0 then
                    scores[4] = dart.remaining
                    medals[4] = medal_for(4, dart.remaining)
                    state = S_ROUND_END
                    transition_timer = 3
                    return
                end
                dart.turn = dart.turn + 1
                dart.darts_in_turn = 3
                dart.wobble_speed = 1.8 + dart.turn * 0.3  -- harder each turn
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- Callbacks
-- ═══════════════════════════════════════════════════════════════════

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
local function circ(...)
    local a, b, c, d, e, f, g, h = ...
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
local function ln(...)
    local x1, y1, x2, y2, c, r, g, b = ...
    if type(c) == "number" then
        _gfx.setColor(c or 1, r or 1, g or 1, b or 1)
    elseif type(c) == "table" then
        _sc(c)
    end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Trajectory Sports — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.1, 0.15)
    _cam = lurek.camera.new()
end

local function _ready_setup()
    _cam:setPosition(W, H)
end

function lurek.process(dt)
    title_blink = title_blink + dt
    update_particles(dt)
    update_tweens(dt)

    if lurek.input.isActionDown("quit") then
        lurek.event.quit()
        return
    end

    -- ── TITLE ──
    if state == S_TITLE then
        if lurek.input.isActionDown("power") then
            state = S_SPORT_SELECT
        end
        return
    end

    -- ── SPORT SELECT ──
    if state == S_SPORT_SELECT then
        for i = 1, 4 do
            if lurek.input.isActionDown("select" .. i) then
                sport = i
                if i == 1 then archery_reset()
                elseif i == 2 then bball_reset()
                elseif i == 3 then bowl_reset()
                elseif i == 4 then dart_reset() end
                state = S_PLAYING
                return
            end
        end
        return
    end

    -- ── PLAYING ──
    if state == S_PLAYING then
        if sport == 1 then archery_update(dt)
        elseif sport == 2 then bball_update(dt)
        elseif sport == 3 then bowl_update(dt)
        elseif sport == 4 then dart_update(dt) end
        return
    end

    -- ── ROUND END ──
    if state == S_ROUND_END then
        transition_timer = transition_timer - dt
        if transition_timer <= 0 then
            -- Check if all sports played
            local all_done = true
            for i = 1, 4 do
                if medals[i] == "" then all_done = false; break end
            end
            if all_done then
                state = S_FINAL_SCORES
            else
                state = S_SPORT_SELECT
            end
        end
        return
    end

    -- ── FINAL SCORES ──
    if state == S_FINAL_SCORES then
        if lurek.input.isActionDown("power") then
            -- Reset everything
            scores = { 0, 0, 0, 0 }
            medals = { "", "", "", "" }
            state = S_TITLE
        end
        return
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- Render — field, projectiles, targets
-- ═══════════════════════════════════════════════════════════════════
function lurek.draw()
    if state == S_PLAYING then
        if sport == 1 then
            -- Archery field
            -- Ground
            rect(0, 450, W, 150, 0.2, 0.5, 0.2)
            -- Bow
            local bx, by = 80, 400
            local rad = math.rad(arch.angle)
            local ex = bx + math.cos(rad) * 40
            local ey = by - math.sin(rad) * 40
            ln(bx, by - 20, bx, by + 20, 0.5, 0.3, 0.1)
            ln(bx, by - 20, ex, ey, 0.9, 0.9, 0.9)
            ln(bx, by + 20, ex, ey, 0.9, 0.9, 0.9)
            -- Target
            local tx, ty = arch.target_x, arch.target_y
            circ(tx, ty, 70, 1, 1, 1)
            circ(tx, ty, 55, 0, 0, 0.8)
            circ(tx, ty, 40, 1, 0, 0)
            circ(tx, ty, 25, 1, 1, 0)
            circ(tx, ty, 12, 1, 0, 0)
            -- Arrow in flight
            local a = arch.arrow
            if a ~= nil then
                circ(a.x, a.y, 3, 0.8, 0.6, 0.1)
                local len = 20
                local spd = math.sqrt(a.vx * a.vx + a.vy * a.vy)
                if spd > 1 then
                    local nx, ny = a.vx / spd, a.vy / spd
                    ln(a.x, a.y, a.x - nx * len, a.y - ny * len, 0.6, 0.4, 0.1)
                end
            end

        elseif sport == 2 then
            -- Basketball court
            rect(0, 480, W, 120, 0.6, 0.35, 0.15)
            -- Backboard
            rect(bball.hoop_x + 15, bball.hoop_y - 40, 8, 80, 0.9, 0.9, 0.9)
            -- Hoop rim
            circ(bball.hoop_x, bball.hoop_y, bball.rim_r + 3, 0.8, 0.3, 0.1)
            circ(bball.hoop_x, bball.hoop_y, bball.rim_r - 2, 0.6, 0.35, 0.15)
            -- Net lines
            for i = 0, 3 do
                local nx = bball.hoop_x - bball.rim_r + i * (bball.rim_r * 2 / 3)
                ln(nx, bball.hoop_y, nx + 3, bball.hoop_y + 30, 0.9, 0.9, 0.9)
            end
            -- Player
            rect(bball.player_x - 10, bball.player_y - 40, 20, 40, 0.2, 0.4, 0.8)
            circ(bball.player_x, bball.player_y - 50, 10, 0.9, 0.7, 0.5)
            -- Ball in flight
            local ball = bball.ball
            if ball ~= nil then
                circ(ball.x, ball.y, 8, 0.9, 0.5, 0.1)
            end

        elseif sport == 3 then
            -- Bowling lane
            rect(290, 40, 220, 520, 0.7, 0.55, 0.3)
            -- Lane lines
            ln(290, 40, 290, 560, 0.5, 0.4, 0.2)
            ln(510, 40, 510, 560, 0.5, 0.4, 0.2)
            -- Gutters
            rect(280, 40, 10, 520, 0.3, 0.3, 0.3)
            rect(510, 40, 10, 520, 0.3, 0.3, 0.3)
            -- Pins
            for _, p in ipairs(bowl.pins) do
                if p.alive then
                    circ(p.x, p.y, PIN_R, 1, 1, 1)
                    circ(p.x, p.y, PIN_R - 2, 0.9, 0.1, 0.1)
                else
                    circ(p.x, p.y, PIN_R * 0.6, 0.5, 0.5, 0.5)
                end
            end
            -- Ball
            circ(bowl.ball_x, bowl.ball_y, BALL_R, 0.15, 0.15, 0.15)
            circ(bowl.ball_x - 2, bowl.ball_y - 2, 2, 0.3, 0.3, 0.3)

        elseif sport == 4 then
            -- Dartboard
            local cx, cy, r = dart.cx, dart.cy, dart.board_r
            -- Outer ring
            circ(cx, cy, r + 5, 0.2, 0.2, 0.2)
            -- Board rings
            circ(cx, cy, r, 0.1, 0.4, 0.1)
            circ(cx, cy, r * 0.90, 0.8, 0.2, 0.2)
            circ(cx, cy, r * 0.82, 0.1, 0.4, 0.1)
            circ(cx, cy, r * 0.48, 0.8, 0.2, 0.2)
            circ(cx, cy, r * 0.40, 0.1, 0.4, 0.1)
            circ(cx, cy, r * 0.10, 0.1, 0.6, 0.1)
            circ(cx, cy, r * 0.04, 0.9, 0.2, 0.1)
            -- Hit markers
            for _, h in ipairs(dart.hits) do
                circ(h.x, h.y, 3, 0.9, 0.9, 0.1)
            end
            -- Crosshair
            if not dart.thrown then
                local chx, chy = dart.crosshair_x, dart.crosshair_y
                ln(chx - 10, chy, chx + 10, chy, 1, 1, 1)
                ln(chx, chy - 10, chx, chy + 10, 1, 1, 1)
                circ(chx, chy, 4, 1, 0.3, 0.3)
            end
        end
    end

    -- Particles (world-space)
    for _, p in ipairs(particles) do
        circ(p.x, p.y, p.size, p.r, p.g, p.b)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- Render UI — HUD, scores, power bars, menus
-- ═══════════════════════════════════════════════════════════════════
function lurek.draw_ui()
    local fps = lurek.timer.getFPS()
    text_(string.format("FPS: %d", fps), W - 80, 10, 14, 0.6, 0.6, 0.6)

    -- ── TITLE ──
    if state == S_TITLE then
        text_("TRAJECTORY SPORTS", W / 2 - 140, 160, 32, 1, 0.9, 0.3)
        text_("AIM AND FIRE", W / 2 - 80, 210, 20, 0.8, 0.8, 0.8)
        if math.floor(title_blink * 2) % 2 == 0 then
            text_("Press SPACE to start", W / 2 - 100, 350, 18, 0.7, 0.7, 0.7)
        end
        text_("W/S = Aim   A/D = Move   Space = Power", W / 2 - 180, 450, 14, 0.5, 0.5, 0.5)
        return
    end

    -- ── SPORT SELECT ──
    if state == S_SPORT_SELECT then
        text_("SELECT SPORT", W / 2 - 90, 80, 28, 1, 0.9, 0.3)
        local items = {
            "[1] ARCHERY    — Bow & Target",
            "[2] BASKETBALL — Hoop Shots",
            "[3] BOWLING    — Pin Strike",
            "[4] DARTS      — 301 Countdown",
        }
        for i, txt in ipairs(items) do
            local c = medals[i] ~= "" and 0.4 or 1.0
            local medal_txt = medals[i] ~= "" and ("  [" .. medals[i] .. "]") or ""
            text_(txt .. medal_txt, 200, 160 + i * 50, 20, c, c, c * 0.8)
        end
        local done = 0
        for i = 1, 4 do if medals[i] ~= "" then done = done + 1 end end
        text_(string.format("Completed: %d/4", done), W / 2 - 60, 480, 16, 0.6, 0.6, 0.6)
        return
    end

    -- ── ROUND END ──
    if state == S_ROUND_END then
        text_(sport_names[sport] .. " COMPLETE!", W / 2 - 120, 180, 28, 1, 0.9, 0.3)
        if sport == 4 then
            text_(string.format("Remaining: %d", scores[4]), W / 2 - 70, 250, 22, 1, 1, 1)
        else
            text_(string.format("Score: %d", scores[sport]), W / 2 - 50, 250, 22, 1, 1, 1)
        end
        local mc = medals[sport] == "GOLD" and {1, 0.85, 0.1} or
                   medals[sport] == "SILVER" and {0.75, 0.75, 0.8} or
                   medals[sport] == "BRONZE" and {0.8, 0.5, 0.2} or {0.5, 0.5, 0.5}
        text_("Medal: " .. medals[sport], W / 2 - 60, 300, 22, mc[1], mc[2], mc[3])
        return
    end

    -- ── FINAL SCORES ──
    if state == S_FINAL_SCORES then
        text_("FINAL RESULTS", W / 2 - 100, 60, 28, 1, 0.9, 0.3)
        for i = 1, 4 do
            local sc = sport == 4 and string.format("Remaining: %d", scores[i])
                       or string.format("Score: %d", scores[i])
            if i == 4 then sc = string.format("Remaining: %d", scores[4]) end
            text_(string.format("%s: %s  [%s]", sport_names[i], sc, medals[i]),
                120, 120 + i * 50, 18, 0.9, 0.9, 0.9)
        end
        local rank = final_rank()
        text_("Overall: " .. rank, W / 2 - 80, 420, 26, 1, 0.8, 0.2)
        if math.floor(title_blink * 2) % 2 == 0 then
            text_("Press SPACE to restart", W / 2 - 110, 500, 16, 0.6, 0.6, 0.6)
        end
        return
    end

    -- ── PLAYING HUD ──
    if state == S_PLAYING then
        text_(sport_names[sport], 10, 10, 20, 1, 0.9, 0.3)

        if sport == 1 then
            -- Archery HUD
            text_(string.format("Score: %d", math.floor(arch.display_score)), 10, 40, 16, 1, 1, 1)
            text_(string.format("Arrows: %d", arch.arrows_left), 10, 60, 16, 1, 1, 1)
            text_(string.format("Angle: %.0f°", arch.angle), 10, 80, 14, 0.8, 0.8, 0.8)
            text_(string.format("Wind: %.0f", arch.wind), 10, 100, 14, 0.6, 0.8, 1.0)
            -- Power bar
            local pw = arch.power / 100
            rect(10, 125, 100, 10, 0.3, 0.3, 0.3)
            rect(10, 125, pw * 100, 10, 1.0, 1.0 - pw, 0.1)

        elseif sport == 2 then
            -- Basketball HUD
            text_(string.format("Score: %d", math.floor(bball.display_score)), 10, 40, 16, 1, 1, 1)
            text_(string.format("Shots: %d", bball.shots_left), 10, 60, 16, 1, 1, 1)
            text_(string.format("Angle: %.0f°", bball.angle), 10, 80, 14, 0.8, 0.8, 0.8)
            -- Power bar
            local pw = bball.power / 100
            rect(10, 105, 100, 10, 0.3, 0.3, 0.3)
            rect(10, 105, pw * 100, 10, 1.0, 0.5, 0.1)

        elseif sport == 3 then
            -- Bowling HUD
            text_(string.format("Frame: %d/10", bowl.frame), 10, 40, 16, 1, 1, 1)
            text_(string.format("Throw: %d", bowl.throw_in_frame), 10, 60, 14, 0.8, 0.8, 0.8)
            local standing = count_standing()
            text_(string.format("Pins: %d/10", standing), 10, 80, 14, 0.8, 0.8, 0.8)
            -- Score
            local t = 0
            for _, fs in pairs(bowl.frame_scores) do t = t + (fs.total or 0) end
            text_(string.format("Total: %d", t), 10, 100, 16, 1, 1, 1)
            -- Power bar
            if not bowl.rolling then
                local pw = bowl.power / 100
                rect(10, 125, 100, 10, 0.3, 0.3, 0.3)
                rect(10, 125, pw * 100, 10, 0.2, 0.6, 1.0)
            end

        elseif sport == 4 then
            -- Darts HUD
            text_(string.format("Remaining: %d", dart.remaining), 10, 40, 18, 1, 1, 1)
            text_(string.format("Turn: %d/%d", dart.turn, dart.max_turns), 10, 65, 14, 0.8, 0.8, 0.8)
            text_(string.format("Darts: %d", dart.darts_in_turn), 10, 85, 14, 0.8, 0.8, 0.8)
            if dart.last_points > 0 then
                text_(string.format("Last: %d pts", dart.last_points), 10, 110, 16, 1, 0.8, 0.2)
            end
        end
    end
end
