-- ============================================================================
-- Sensible Soccer — Lurek2D
-- ============================================================================
-- Category : sports
-- Source   : content/games/sports/sensible_soccer/main.lua
-- Run with : cargo run -- content/games/sports/sensible_soccer
-- ============================================================================
-- Arcade top-down football inspired by Sensible Soccer (Amiga 1997).
-- 5-a-side with aftertouch shooting, sliding tackles, and CPU opponents.
-- Controls: WASD move, Space kick/slide, Escape quit
-- ============================================================================

local W, H = 960, 540

-- ── Pitch dimensions ──────────────────────────────────────────────────────
local PITCH_L, PITCH_T = 80, 50
local PITCH_R, PITCH_B = W - 80, H - 50
local PITCH_W = PITCH_R - PITCH_L
local PITCH_H = PITCH_B - PITCH_T
local GOAL_W   = 16
local GOAL_H   = 90
local GOAL_Y   = PITCH_T + (PITCH_H - GOAL_H) * 0.5

-- ── Physics constants ─────────────────────────────────────────────────────
local PLAYER_R      = 9
local BALL_R        = 7
local PLAYER_SPEED  = 130
local CPU_SPEED     = 110
local KICK_POWER    = 380
local FRICTION      = 0.88          -- multiplied per frame (dt-scaled below)
local AFTERTOUCH    = 90            -- lateral curve force from aim dir

-- ── State ─────────────────────────────────────────────────────────────────
local STATE = { KICKOFF = 1, PLAY = 2, GOAL = 3, FT = 4 }
local state        = STATE.KICKOFF
local score        = { [1] = 0, [2] = 0 }
local goal_timer   = 0
local match_time   = 0
local MATCH_LEN    = 90          -- seconds (fast mode)
local kickoff_side = 1           -- which team kicks off

-- Ball
local ball = { x = W/2, y = H/2, vx = 0, vy = 0, owner = nil }

-- Players: team 1 = human (red), team 2 = cpu (blue)
local function make_player(id, team, x, y)
    return { id=id, team=team, x=x, y=y, vx=0, vy=0,
             slide_t=0, dir_x=1, dir_y=0 }
end

local players = {
    -- Team 1 (human) – loose 5-a-side formation
    make_player(1, 1, PITCH_L+90,  H/2),
    make_player(2, 1, PITCH_L+180, H/2 - 60),
    make_player(3, 1, PITCH_L+180, H/2 + 60),
    make_player(4, 1, PITCH_L+270, H/2 - 90),
    make_player(5, 1, PITCH_L+270, H/2 + 90),
    -- Team 2 (cpu)
    make_player(6,  2, PITCH_R-90,  H/2),
    make_player(7,  2, PITCH_R-180, H/2 - 60),
    make_player(8,  2, PITCH_R-180, H/2 + 60),
    make_player(9,  2, PITCH_R-270, H/2 - 90),
    make_player(10, 2, PITCH_R-270, H/2 + 90),
}

-- The human-controlled player nearest the ball
local controlled = players[1]

-- ── Helpers ───────────────────────────────────────────────────────────────
local function dist2(ax,ay,bx,by) return (ax-bx)^2 + (ay-by)^2 end
local function clamp(v,lo,hi) return math.max(lo, math.min(hi, v)) end

local function reset_positions(ko_side)
    ball.x, ball.y, ball.vx, ball.vy, ball.owner = W/2, H/2, 0, 0, nil
    local ox = (ko_side == 1) and -70 or 70
    local spread = { {-90,-0},{-180,-60},{-180,60},{-270,-90},{-270,90} }
    for i=1,5 do
        players[i].x = W/2 + ox*-1 + spread[i][1] * ((ko_side==1) and 1 or -1)
        players[i].y = H/2 + spread[i][2]
        players[i].vx, players[i].vy, players[i].slide_t = 0, 0, 0
    end
    for i=1,5 do
        players[i+5].x = W/2 - ox*-1 - spread[i][1] * ((ko_side==1) and 1 or -1)
        players[i+5].y = H/2 + spread[i][2]
        players[i+5].vx, players[i+5].vy, players[i+5].slide_t = 0, 0, 0
    end
end

local function find_nearest_player(team)
    local best, bd = nil, math.huge
    for _, p in ipairs(players) do
        if p.team == team then
            local d = dist2(p.x, p.y, ball.x, ball.y)
            if d < bd then best, bd = p, d end
        end
    end
    return best
end

-- ── Load ──────────────────────────────────────────────────────────────────
function lurek.load()
    lurek.window.setTitle("Sensible Soccer — Lurek2D")
    lurek.gfx.setBackgroundColor(0.15, 0.48, 0.18)
    lurek.input.bind("left",  "a,left")
    lurek.input.bind("right", "d,right")
    lurek.input.bind("up",    "w,up")
    lurek.input.bind("down",  "s,down")
    lurek.input.bind("kick",  "space")
    reset_positions(1)
end

-- ── Update ────────────────────────────────────────────────────────────────
function lurek.update(dt)
    if state == STATE.GOAL then
        goal_timer = goal_timer - dt
        if goal_timer <= 0 then
            reset_positions(kickoff_side)
            state = STATE.KICKOFF
        end
        return
    end
    if state == STATE.FT then return end

    match_time = match_time + dt
    if match_time >= MATCH_LEN then state = STATE.FT; return end

    -- Pick controlled player
    controlled = find_nearest_player(1)

    -- Human movement
    local mx, my = 0, 0
    if lurek.input.isActionDown("left")  then mx = mx - 1 end
    if lurek.input.isActionDown("right") then mx = mx + 1 end
    if lurek.input.isActionDown("up")    then my = my - 1 end
    if lurek.input.isActionDown("down")  then my = my + 1 end
    local mlen = math.sqrt(mx*mx + my*my)
    if mlen > 0 then
        mx, my = mx/mlen, my/mlen
        controlled.dir_x, controlled.dir_y = mx, my
    end
    controlled.vx = mx * PLAYER_SPEED
    controlled.vy = my * PLAYER_SPEED

    -- CPU team 2 simple AI: nearest chases ball, others support
    for i, p in ipairs(players) do
        if p.team == 2 then
            local tx, ty
            local nearest_cpu = find_nearest_player(2)
            if p == nearest_cpu then
                tx, ty = ball.x, ball.y
            else
                -- support position: aim toward goal 1 offset from ball
                tx = ball.x - 60 + (i%3)*30
                ty = ball.y + (i%2==0 and -40 or 40)
            end
            local dx = tx - p.x; local dy = ty - p.y
            local d = math.sqrt(dx*dx + dy*dy)
            if d > 4 then
                p.dir_x, p.dir_y = dx/d, dy/d
                p.vx = (dx/d) * CPU_SPEED
                p.vy = (dy/d) * CPU_SPEED
            else
                p.vx, p.vy = 0, 0
            end
        end
    end

    -- Move all players + clamp to pitch
    for _, p in ipairs(players) do
        p.x = clamp(p.x + p.vx*dt, PITCH_L+PLAYER_R, PITCH_R-PLAYER_R)
        p.y = clamp(p.y + p.vy*dt, PITCH_T+PLAYER_R, PITCH_B-PLAYER_R)
        if p.slide_t > 0 then p.slide_t = p.slide_t - dt end
    end

    -- Ball physics
    local f = FRICTION ^ (60*dt)      -- frame-rate independent friction
    ball.vx = ball.vx * f
    ball.vy = ball.vy * f
    ball.x  = ball.x + ball.vx * dt
    ball.y  = ball.y + ball.vy * dt

    -- Ball wall bounce (left/right touch lines → reflect)
    if ball.x < PITCH_L + BALL_R then
        ball.x = PITCH_L + BALL_R; ball.vx = math.abs(ball.vx) * 0.7
    end
    if ball.x > PITCH_R - BALL_R then
        ball.x = PITCH_R - BALL_R; ball.vx = -math.abs(ball.vx) * 0.7
    end
    -- Top/bottom → check for goal, otherwise bounce
    local in_goal_y = ball.y > GOAL_Y and ball.y < GOAL_Y + GOAL_H
    if ball.y < PITCH_T + BALL_R then
        ball.y = PITCH_T + BALL_R; ball.vy = math.abs(ball.vy) * 0.7
    end
    if ball.y > PITCH_B - BALL_R then
        ball.y = PITCH_B - BALL_R; ball.vy = -math.abs(ball.vy) * 0.7
    end

    -- Goal detection
    if ball.x < PITCH_L + GOAL_W and in_goal_y then
        score[2] = score[2] + 1; kickoff_side = 2
        goal_timer = 2.5; state = STATE.GOAL
        return
    end
    if ball.x > PITCH_R - GOAL_W and in_goal_y then
        score[1] = score[1] + 1; kickoff_side = 1
        goal_timer = 2.5; state = STATE.GOAL
        return
    end

    -- Player–ball collision + auto-control
    for _, p in ipairs(players) do
        local dx = ball.x - p.x; local dy = ball.y - p.y
        local d  = math.sqrt(dx*dx + dy*dy)
        local touch_r = PLAYER_R + BALL_R
        if d < touch_r and d > 0 then
            -- push ball away
            local nx, ny = dx/d, dy/d
            ball.x = p.x + nx * touch_r
            ball.y = p.y + ny * touch_r
            -- transfer momentum
            ball.vx = nx * math.max(math.sqrt(p.vx^2+p.vy^2), 40) * 1.2
            ball.vy = ny * math.max(math.sqrt(p.vx^2+p.vy^2), 40) * 1.2
            ball.owner = p
        end
    end

    -- CPU kick toward goal 1
    local nearest_cpu = find_nearest_player(2)
    if ball.owner and ball.owner.team == 2 then
        local dx = PITCH_L - ball.x
        local dy = GOAL_Y + GOAL_H/2 - ball.y
        local d  = math.sqrt(dx*dx + dy*dy)
        ball.vx = (dx/d) * KICK_POWER
        ball.vy = (dy/d) * KICK_POWER
        ball.owner = nil
    end

    -- Kickoff state → wait for kick input
    if state == STATE.KICKOFF and lurek.input.wasActionPressed("kick") then
        state = STATE.PLAY
    end
end

-- ── Draw ──────────────────────────────────────────────────────────────────
function lurek.draw()
    -- Pitch markings
    lurek.gfx.setColor(0.12, 0.40, 0.14)
    lurek.gfx.rectangle("fill", PITCH_L, PITCH_T, PITCH_W, PITCH_H)
    lurek.gfx.setColor(1, 1, 1, 0.9)
    lurek.gfx.rectangle("line", PITCH_L, PITCH_T, PITCH_W, PITCH_H)
    -- Centre line & circle
    local cx = W/2
    lurek.gfx.line(cx, PITCH_T, cx, PITCH_B)
    lurek.gfx.circle("line", cx, H/2, 50)
    lurek.gfx.circle("fill", cx, H/2, 3)
    -- Goals
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.rectangle("fill", PITCH_L - GOAL_W, GOAL_Y, GOAL_W, GOAL_H)
    lurek.gfx.rectangle("fill", PITCH_R, GOAL_Y, GOAL_W, GOAL_H)

    -- Players
    for _, p in ipairs(players) do
        if p.team == 1 then
            lurek.gfx.setColor(0.9, 0.15, 0.15)
        else
            lurek.gfx.setColor(0.15, 0.3, 0.9)
        end
        lurek.gfx.circle("fill", p.x, p.y, PLAYER_R)
        -- direction dot
        lurek.gfx.setColor(1, 1, 1, 0.8)
        lurek.gfx.circle("fill", p.x + p.dir_x*PLAYER_R*0.6, p.y + p.dir_y*PLAYER_R*0.6, 2)
        -- controlled marker
        if p == controlled then
            lurek.gfx.setColor(1, 1, 0, 0.8)
            lurek.gfx.circle("line", p.x, p.y, PLAYER_R + 3)
        end
    end

    -- Ball
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.circle("fill", ball.x, ball.y, BALL_R)
    lurek.gfx.setColor(0, 0, 0, 0.5)
    lurek.gfx.circle("line", ball.x, ball.y, BALL_R)

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.55)
    lurek.gfx.rectangle("fill", W/2 - 90, 4, 180, 30)
    lurek.gfx.setColor(0.9, 0.15, 0.15)
    lurek.gfx.print(tostring(score[1]), W/2 - 65, 8, 0, 1.4)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("–", W/2 - 9, 8, 0, 1.4)
    lurek.gfx.setColor(0.15, 0.3, 0.9)
    lurek.gfx.print(tostring(score[2]), W/2 + 30, 8, 0, 1.4)
    -- Clock
    local remaining = math.max(0, MATCH_LEN - match_time)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print(string.format("%d'", math.floor(remaining)), W/2 - 10, H - 24)

    if state == STATE.KICKOFF then
        lurek.gfx.setColor(1, 1, 0, 0.9)
        lurek.gfx.print("KICK OFF — press Space", W/2 - 100, H/2 - 15)
    elseif state == STATE.GOAL then
        lurek.gfx.setColor(1, 0.9, 0, 0.95)
        lurek.gfx.print("G O A L !", W/2 - 45, H/2 - 14, 0, 1.8)
    elseif state == STATE.FT then
        lurek.gfx.setColor(0, 0, 0, 0.7)
        lurek.gfx.rectangle("fill", W/2 - 130, H/2 - 30, 260, 60)
        lurek.gfx.setColor(1, 1, 0)
        lurek.gfx.print("FULL TIME", W/2 - 50, H/2 - 22, 0, 1.4)
        lurek.gfx.setColor(1,1,1)
        lurek.gfx.print(string.format("Final: %d – %d  (Esc to quit)", score[1], score[2]), W/2 - 110, H/2 + 8)
    end
end

-- ── Keypressed ────────────────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if (key == "space" or key == "return") and state == STATE.PLAY then
        -- Shoot: kick ball in player's facing direction + aftertouch
        if controlled then
            local kx = controlled.dir_x
            local ky = controlled.dir_y
            -- apply aftertouch (slight curve from lateral motion)
            local lat = -controlled.vy * 0.003
            ball.vx = kx * KICK_POWER + lat * ky * AFTERTOUCH
            ball.vy = ky * KICK_POWER - lat * kx * AFTERTOUCH
            ball.owner = nil
        end
    end
end
