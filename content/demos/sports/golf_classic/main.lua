-- Golf Classic — Sport Game (Lurek2D demo)
-- 9 holes of top-down golf. Aim with A/D, hold Space to build power, release to putt.
-- Wind affects each shot. Par 3–5 per hole. Beat par to earn an eagle!
-- Run with: cargo run -- content/demos/sports/golf_classic

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local GRAVITY   = 80     -- rolling friction / slope sim (top-down drag)
local MAX_POWER = 100
local HOLES = 9

-- Hole definitions: {par, tee, hole, obstacles}
-- Each obstacle: {type="rect"|"water"|"bunker", x,y,w,h}
local COURSE = {
    { par=3, tee={150,300}, cup={640,300}, wind={0.3,0}, obs={{type="tree",x=380,y=260,w=18,h=80}} },
    { par=4, tee={100,200}, cup={680,400}, wind={0.4,0.2}, obs={{type="water",x=380,y=350,w=120,h=60}} },
    { par=3, tee={120,450}, cup={670,150}, wind={-0.3,0.1}, obs={{type="bunker",x=440,y=270,w=80,h=80}} },
    { par=4, tee={80,300},  cup={700,300}, wind={0.5,-0.2},
      obs={{type="tree",x=280,y=250,w=18,h=100},{type="bunker",x=500,y=280,w=70,h=60}} },
    { par=5, tee={80,150},  cup={720,450}, wind={0.2,0.4},
      obs={{type="water",x=340,y=220,w=100,h=70},{type="tree",x=560,y=380,w=18,h=80}} },
    { par=3, tee={160,500}, cup={640,100}, wind={-0.4,-0.3}, obs={{type="bunker",x=380,y=250,w=90,h=90}} },
    { par=4, tee={100,300}, cup={690,300}, wind={0.6,0},
      obs={{type="water",x=310,y=260,w=80,h=80},{type="tree",x=490,y=250,w=18,h=90}} },
    { par=5, tee={80,500},  cup={720,100}, wind={0.1,0.5},
      obs={{type="bunker",x=300,y=350,w=80,h=60},{type="water",x=480,y=200,w=100,h=80}} },
    { par=4, tee={80,300},  cup={710,300}, wind={-0.5,0.3},
      obs={{type="tree",x=260,y=260,w=18,h=80},{type="bunker",x=420,y=270,w=80,h=70},{type="tree",x=560,y=280,w=18,h=70}} },
}

-- ── State ─────────────────────────────────────────────────────────────────

local hole_idx  = 1
local shot_count = 0     -- strokes this hole
local total_score = 0    -- cumulative over/under par
local game_state = "aim" -- aim / swing / rolling / holed / gameover
local aim_angle = 0      -- radians
local power     = 0
local power_dir = 1
local ball      = {}
local ball_trail = {}
local anim      = 0
local msg = ""; local msg_timer = 0
local scores    = {}     -- per-hole strokes

local function show_msg(s,t) msg=s; msg_timer=t end

local function load_hole()
    local h = COURSE[hole_idx]
    ball = { x = h.tee[1], y = h.tee[2], vx = 0, vy = 0 }
    shot_count = 0; aim_angle = 0; power = 0; power_dir = 1
    ball_trail = {}
    game_state = "aim"
end

local function reset()
    hole_idx = 1; total_score = 0; scores = {}
    load_hole()
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.gfx.setBackgroundColor(0.18, 0.55, 0.18)
    reset()
end

-- ── Update ────────────────────────────────────────────────────────────────

function lurek.process(dt)
    anim = anim + dt
    msg_timer = math.max(0, msg_timer - dt)
    if game_state ~= "rolling" then
        if game_state == "swing" then
            -- Animate power bar
            power = power + power_dir * 90 * dt
            if power >= MAX_POWER then power = MAX_POWER; power_dir = -1 end
            if power <= 0 then power = 0; power_dir = 1 end
        end
        return
    end

    local h = COURSE[hole_idx]
    local wind = h.wind

    -- Apply wind
    ball.vx = ball.vx + wind[1] * dt * 20
    ball.vy = ball.vy + wind[2] * dt * 20

    -- Rolling friction
    local spd = math.sqrt(ball.vx^2 + ball.vy^2)
    if spd > 0 then
        local drag = math.min(spd, 60 * dt)
        ball.vx = ball.vx - ball.vx / spd * drag
        ball.vy = ball.vy - ball.vy / spd * drag
    end

    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Trail
    if #ball_trail == 0 or (math.abs(ball.x - ball_trail[#ball_trail].x) + math.abs(ball.y - ball_trail[#ball_trail].y)) > 8 then
        ball_trail[#ball_trail+1] = {x=ball.x, y=ball.y}
        if #ball_trail > 30 then table.remove(ball_trail, 1) end
    end

    -- Obstacle collision
    for _, obs in ipairs(h.obs) do
        if ball.x > obs.x and ball.x < obs.x + obs.w and ball.y > obs.y and ball.y < obs.y + obs.h then
            if obs.type == "tree" then
                -- Bounce off
                ball.vx = -ball.vx * 0.5; ball.vy = -ball.vy * 0.5
                ball.x = ball.x - ball.vx * dt * 3
            elseif obs.type == "water" then
                -- Reset to tee, penalty stroke
                shot_count = shot_count + 1
                show_msg("WATER HAZARD! +1 penalty", 2)
                ball.x = h.tee[1]; ball.y = h.tee[2]
                ball.vx = 0; ball.vy = 0
                ball_trail = {}
            elseif obs.type == "bunker" then
                -- Slow down significantly
                ball.vx = ball.vx * 0.3; ball.vy = ball.vy * 0.3
            end
        end
    end

    -- Boundary
    if ball.x < 50 or ball.x > W - 20 or ball.y < 50 or ball.y > H - 20 then
        ball.vx = -ball.vx * 0.6; ball.vy = -ball.vy * 0.6
        ball.x = math.max(50, math.min(W - 20, ball.x))
        ball.y = math.max(50, math.min(H - 20, ball.y))
    end

    -- Check holed (distance to cup < 14)
    local cx, cy = h.cup[1], h.cup[2]
    if math.sqrt((ball.x-cx)^2 + (ball.y-cy)^2) < 14 then
        ball.x = cx; ball.y = cy; ball.vx = 0; ball.vy = 0
        scores[hole_idx] = shot_count
        local diff = shot_count - h.par
        total_score = total_score + diff
        local n = diff < -1 and "EAGLE! -" .. (-diff) or
                  diff == -1 and "BIRDIE! -1" or
                  diff == 0  and "PAR!" or
                  "BOGEY +" .. diff
        show_msg(n .. "  (Hole " .. hole_idx .. ")", 3)
        if hole_idx >= HOLES then
            game_state = "gameover"
        else
            game_state = "holed"
        end
        return
    end

    -- Ball stopped?
    if spd < 2 then
        ball.vx = 0; ball.vy = 0
        game_state = "aim"
    end
end

-- ── Draw ──────────────────────────────────────────────────────────────────

function lurek.render()
    -- Fairway
    lurek.gfx.setColor(0.18, 0.55, 0.18)
    lurek.gfx.rectangle("fill", 0, 0, W, H)

    local h = COURSE[hole_idx]

    -- Rough border
    lurek.gfx.setColor(0.1, 0.4, 0.1)
    lurek.gfx.rectangle("fill", 0, 0, W, 50)
    lurek.gfx.rectangle("fill", 0, H-50, W, 50)
    lurek.gfx.rectangle("fill", 0, 0, 50, H)
    lurek.gfx.rectangle("fill", W-50, 0, 50, H)

    -- Obstacles
    for _, obs in ipairs(h.obs) do
        if obs.type == "water" then
            lurek.gfx.setColor(0.1, 0.3, 0.8, 0.8)
        elseif obs.type == "bunker" then
            lurek.gfx.setColor(0.88, 0.8, 0.55, 0.9)
        else  -- tree
            lurek.gfx.setColor(0.05, 0.25, 0.05)
        end
        if obs.type == "tree" then
            lurek.gfx.rectangle("fill", obs.x - 2, obs.y, 4, obs.h)
            lurek.gfx.circle("fill", obs.x, obs.y, obs.w/2)
        else
            lurek.gfx.rectangle("fill", obs.x, obs.y, obs.w, obs.h)
        end
    end

    -- Tee
    lurek.gfx.setColor(0.65, 0.55, 0.3)
    lurek.gfx.circle("fill", h.tee[1], h.tee[2], 12)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("T", h.tee[1] - 5, h.tee[2] - 8, 1.5)

    -- Cup / hole
    lurek.gfx.setColor(0.05, 0.05, 0.05)
    lurek.gfx.circle("fill", h.cup[1], h.cup[2], 10)
    lurek.gfx.setColor(1, 0.2, 0)
    lurek.gfx.rectangle("fill", h.cup[1], h.cup[2] - 28, 3, 28)  -- flag pole
    lurek.gfx.rectangle("fill", h.cup[1] + 3, h.cup[2] - 28, 14, 10)  -- flag

    -- Ball trail
    for i, pt in ipairs(ball_trail) do
        local a = i / #ball_trail * 0.6
        lurek.gfx.setColor(1, 1, 1, a * 0.5)
        lurek.gfx.circle("fill", pt.x, pt.y, 2)
    end

    -- Ball
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.circle("fill", ball.x, ball.y, 7)
    lurek.gfx.setColor(0.4, 0.4, 0.4)
    lurek.gfx.circle("line", ball.x, ball.y, 7)

    -- Aim arrow
    if game_state == "aim" then
        local wind = h.wind
        local wx = wind[1]; local wy = wind[2]
        local len = 50
        lurek.gfx.setColor(1, 0.9, 0, 0.8)
        lurek.gfx.line(ball.x, ball.y, ball.x + math.cos(aim_angle)*len, ball.y + math.sin(aim_angle)*len)
        -- Wind arrow (top right)
        local wlen = math.sqrt(wx^2 + wy^2) * 60
        if wlen > 2 then
            local wangle = math.atan(wy, wx)
            lurek.gfx.setColor(0.5, 0.8, 1, 0.8)
            lurek.gfx.line(W - 70, 70, W - 70 + math.cos(wangle)*wlen, 70 + math.sin(wangle)*wlen)
            lurek.gfx.circle("fill", W - 70 + math.cos(wangle)*wlen, 70 + math.sin(wangle)*wlen, 5)
        end
    end

    -- Power bar
    if game_state == "swing" then
        lurek.gfx.setColor(0.2, 0.2, 0.2)
        lurek.gfx.rectangle("fill", W/2 - 80, H - 30, 160, 18)
        local pct = power / MAX_POWER
        local r = pct > 0.7 and 1 or (pct > 0.4 and 0.9 or 0.2)
        local g = pct < 0.4 and 0.9 or (pct < 0.7 and 0.7 or 0.1)
        lurek.gfx.setColor(r, g, 0.1)
        lurek.gfx.rectangle("fill", W/2 - 80, H - 30, 160 * pct, 18)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print("POWER — Release SPACE", W/2 - 80, H - 48, 1.4)
    end

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.65)
    lurek.gfx.rectangle("fill", 0, 0, W, 46)
    lurek.gfx.setColor(1, 0.9, 0.3)
    lurek.gfx.print("HOLE " .. hole_idx .. "/" .. HOLES .. "  PAR " .. h.par, 14, 8, 2.2)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Shots: " .. shot_count, 260, 8, 2)
    local scorestr = total_score == 0 and "E" or (total_score > 0 and "+" .. total_score or tostring(total_score))
    local sc = total_score < 0 and {0.3, 1, 0.3} or (total_score == 0 and {1,1,0.3} or {1,0.4,0.4})
    lurek.gfx.setColor(sc[1], sc[2], sc[3])
    lurek.gfx.print("Score: " .. scorestr, 440, 8, 2)
    lurek.gfx.setColor(0.6, 0.8, 1, 0.7)
    lurek.gfx.print("Wind →", W - 90, 8, 1.4)

    lurek.gfx.setColor(0.7, 0.9, 0.7, 0.7)
    local hint = game_state == "aim" and "[A/D] Aim  [Space] Start swing" or
                 game_state == "swing" and "Power cycling — release [Space] to hit!" or
                 game_state == "rolling" and "Ball rolling..." or ""
    lurek.gfx.print(hint, 14, H - 18, 1.4)

    -- Message
    if msg_timer > 0 then
        local alpha = math.min(1, msg_timer)
        lurek.gfx.setColor(0, 0, 0, alpha * 0.7)
        lurek.gfx.rectangle("fill", W/2 - 200, H/2 - 25, 400, 50)
        lurek.gfx.setColor(1, 1, 0.3, alpha)
        lurek.gfx.print(msg, W/2 - #msg * 7, H/2 - 20, 2)
    end

    -- Hole transition
    if game_state == "holed" then
        lurek.gfx.setColor(0.5, 0.9, 0.5, 0.7)
        lurek.gfx.print("Press SPACE for next hole", W/2 - 130, H - 20, 2)
    end

    -- Game over
    if game_state == "gameover" then
        lurek.gfx.setColor(0, 0, 0, 0.82)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
        lurek.gfx.setColor(1, 0.9, 0.2)
        lurek.gfx.print("ROUND COMPLETE!", W/2 - 105, 60, 2.8)
        for i = 1, HOLES do
            local par_i = COURSE[i].par
            local s_i = scores[i] or 0
            local d = s_i - par_i
            local cl = d < 0 and {0.3,1,0.3} or (d == 0 and {1,1,0.3} or {1,0.4,0.4})
            lurek.gfx.setColor(cl[1], cl[2], cl[3])
            local xs = 70 + ((i-1) % 5) * 135
            local ys = 130 + math.floor((i-1)/5) * 55
            lurek.gfx.print("H" .. i .. ": " .. (s_i > 0 and s_i or "—"), xs, ys, 1.8)
        end
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print("TOTAL: " .. (total_score > 0 and "+" or "") .. total_score, W/2 - 60, 360, 3)
        lurek.gfx.setColor(0.6, 0.6, 0.6)
        lurek.gfx.print("Press R to play again", W/2 - 110, 420, 2)
    end
end

-- ── Input ─────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end

    if game_state == "holed" and key == "space" then
        hole_idx = hole_idx + 1; load_hole(); return
    end

    if game_state == "aim" then
        if key == "a" or key == "left"  then aim_angle = aim_angle - 0.1 end
        if key == "d" or key == "right" then aim_angle = aim_angle + 0.1 end
        if key == "space" then
            game_state = "swing"; power = 0; power_dir = 1
        end
    elseif game_state == "swing" then
        if key == "space" then
            -- Shoot
            shot_count = shot_count + 1
            local spd = power * 4.5
            ball.vx = math.cos(aim_angle) * spd
            ball.vy = math.sin(aim_angle) * spd
            ball_trail = {}
            game_state = "rolling"
            power = 0
        end
    end
end
