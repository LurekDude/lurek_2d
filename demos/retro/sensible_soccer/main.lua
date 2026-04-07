-- Sensible Soccer — Amiga 500 Classic (Luna2D demo)
-- Fast-paced top-down football inspired by Sensible Software's 1992 Amiga classic.
-- Score more goals than the CPU in 3 minutes to win.

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600

-- Pitch dimensions
local PX, PY, PW, PH  = 60, 50, 680, 500
local GOAL_W, GOAL_H  = 10, 90
local PLAYER_SPD      = 160
local CPU_SPD         = 130
local BALL_FRICTION   = 0.88
local KICK_POWER      = 400
local PASS_POWER      = 260
local TACKLE_RANGE    = 26
local DRIBBLE_DIST    = 22
local MATCH_TIME      = 180  -- seconds

-- ── State ─────────────────────────────────────────────────────────────────

local ball = {}
local team  = {}   -- Player's team [1..5]
local cpu   = {}   -- CPU team [1..5]
local scores = { player = 0, cpu = 0 }
local time_left = MATCH_TIME
local game_state = "playing"  -- "playing","halftime","gameover"
local controlled = 1   -- Index in team[] that player controls
local anim = 0
local kickoff_timer = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function dist2(ax,ay,bx,by) return (bx-ax)^2+(by-ay)^2 end

local function in_pitch(x, y, margin)
    margin = margin or 0
    return x > PX + margin and x < PX + PW - margin and
           y > PY + margin and y < PY + PH - margin
end

local function check_goal()
    -- Left goal (CPU scores)
    if ball.x < PX + GOAL_W and
       ball.y > PY + PH/2 - GOAL_H/2 and ball.y < PY + PH/2 + GOAL_H/2 then
        scores.cpu = scores.cpu + 1; return "cpu"
    end
    -- Right goal (player scores)
    if ball.x > PX + PW - GOAL_W and
       ball.y > PY + PH/2 - GOAL_H/2 and ball.y < PY + PH/2 + GOAL_H/2 then
        scores.player = scores.player + 1; return "player"
    end
    return nil
end

local function kickoff()
    ball = { x = W/2, y = H/2, vx = 0, vy = 0, owner = nil }
    kickoff_timer = 1.5
    -- Reset positions
    local positions = {
        {W/2 + 20, H/2}, {W/2 + 80, H/2 - 100}, {W/2 + 80, H/2 + 100},
        {W/2 + 180, H/2 - 140}, {W/2 + 180, H/2 + 140}
    }
    for i, p in ipairs(team) do p.x, p.y = positions[i][1], positions[i][2] end
    local cpos = {
        {W/2 - 20, H/2}, {W/2 - 80, H/2 - 100}, {W/2 - 80, H/2 + 100},
        {W/2 - 180, H/2 - 140}, {W/2 - 180, H/2 + 140}
    }
    for i, p in ipairs(cpu) do p.x, p.y = cpos[i][1], cpos[i][2] end
    controlled = 1
end

local function reset()
    team = {}; cpu = {}
    local tpos = {
        {W/2 + 20, H/2}, {W/2 + 80, H/2 - 100}, {W/2 + 80, H/2 + 100},
        {W/2 + 180, H/2 - 140}, {W/2 + 180, H/2 + 140}
    }
    for i = 1, 5 do
        team[i] = { x = tpos[i][1], y = tpos[i][2], w = 16, h = 16, has_ball = false }
    end
    local cpos = {
        {W/2 - 20, H/2}, {W/2 - 80, H/2 - 100}, {W/2 - 80, H/2 + 100},
        {W/2 - 180, H/2 - 140}, {W/2 - 180, H/2 + 140}
    }
    for i = 1, 5 do
        cpu[i] = { x = cpos[i][1], y = cpos[i][2], w = 16, h = 16, has_ball = false }
    end
    scores = { player = 0, cpu = 0 }
    time_left = MATCH_TIME
    game_state = "playing"
    ball = { x = W/2, y = H/2, vx = 0, vy = 0, owner = nil }
    kickoff_timer = 0
    controlled = 1
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.init()
    luna.gfx.setBackgroundColor(0.2, 0.55, 0.15)
    reset()
end

-- ── Update ───────────────────────────────────────────────────────────────

function luna.process(dt)
    if game_state ~= "playing" then return end
    anim = anim + dt
    time_left = time_left - dt

    if kickoff_timer > 0 then kickoff_timer = kickoff_timer - dt; return end

    -- Controlled player movement
    local p = team[controlled]
    local pvx, pvy = 0, 0
    if luna.input.isKeyDown("left") or luna.input.isKeyDown("a")  then pvx = -PLAYER_SPD end
    if luna.input.isKeyDown("right") or luna.input.isKeyDown("d") then pvx =  PLAYER_SPD end
    if luna.input.isKeyDown("up") or luna.input.isKeyDown("w")    then pvy = -PLAYER_SPD end
    if luna.input.isKeyDown("down") or luna.input.isKeyDown("s")  then pvy =  PLAYER_SPD end

    if pvx ~= 0 and pvy ~= 0 then pvx = pvx * 0.707; pvy = pvy * 0.707 end
    p.x = clamp(p.x + pvx * dt, PX + 8, PX + PW - 8)
    p.y = clamp(p.y + pvy * dt, PY + 8, PY + PH - 8)

    -- Ball dribbling
    if ball.owner == "player" then
        local dir_x = pvx ~= 0 and pvx / math.abs(pvx + 0.001) or 0
        local dir_y = pvy ~= 0 and pvy / math.abs(pvy + 0.001) or 0
        ball.x = p.x + dir_x * DRIBBLE_DIST
        ball.y = p.y + dir_y * DRIBBLE_DIST
        if dir_x == 0 and dir_y == 0 then ball.x = p.x; ball.y = p.y end
    else
        -- Ball physics
        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + ball.vy * dt
        ball.vx = ball.vx * (1 - (1 - BALL_FRICTION) * dt * 60)
        ball.vy = ball.vy * (1 - (1 - BALL_FRICTION) * dt * 60)
        if math.sqrt(ball.vx^2 + ball.vy^2) < 5 then ball.vx = 0; ball.vy = 0 end

        -- Pitch boundary bounce
        if ball.x < PX + 5 then ball.x = PX + 5; ball.vx = -ball.vx * 0.7
        elseif ball.x > PX + PW - 5 then ball.x = PX + PW - 5; ball.vx = -ball.vx * 0.7 end
        if ball.y < PY + 5 then ball.y = PY + 5; ball.vy = -ball.vy * 0.7
        elseif ball.y > PY + PH - 5 then ball.y = PY + PH - 5; ball.vy = -ball.vy * 0.7 end

        -- Player picks up loose ball
        if dist2(p.x, p.y, ball.x, ball.y) < TACKLE_RANGE^2 and ball.owner ~= "cpu" then
            ball.owner = "player"; ball.vx = 0; ball.vy = 0
        end
    end

    -- CPU team AI
    local cpu_has = ball.owner == "cpu"
    local cpu_carrier = nil
    for _, cp in ipairs(cpu) do
        if cp.has_ball then cpu_carrier = cp; break end
    end

    for i, cp in ipairs(cpu) do
        local tx, ty
        if cpu_has and cpu_carrier == cp then
            -- Dribble toward player goal
            tx = PX + PW - 20; ty = PY + PH/2
        elseif not cpu_has then
            -- Chase ball
            tx = ball.x; ty = ball.y
        else
            -- Support run
            tx = PX + PW - 60 - i * 20; ty = PY + PH/2 + (i - 3) * 60
        end
        local ddx, ddy = tx - cp.x, ty - cp.y
        local dd = math.sqrt(ddx*ddx + ddy*ddy)
        if dd > 5 then
            cp.x = clamp(cp.x + (ddx/dd) * CPU_SPD * dt, PX+8, PX+PW-8)
            cp.y = clamp(cp.y + (ddy/dd) * CPU_SPD * dt, PY+8, PY+PH-8)
        end
        -- CPU picks up ball
        if not cpu_has and dist2(cp.x, cp.y, ball.x, ball.y) < TACKLE_RANGE^2 then
            ball.owner = "cpu"; cp.has_ball = true; ball.vx = 0; ball.vy = 0
        end
        -- CPU shoots when close to goal
        if cpu_has and cp.has_ball and cp.x > PX + PW - 150 then
            local gx = PX + PW; local gy = PY + PH/2
            local gd = math.sqrt((gx-cp.x)^2+(gy-cp.y)^2)
            ball.owner = nil; cp.has_ball = false
            ball.vx = (gx - cp.x) / gd * KICK_POWER
            ball.vy = (gy - cp.y) / gd * KICK_POWER + (math.random()-0.5) * 80
        end
    end
    -- Sync CPU has_ball flag
    if ball.owner ~= "cpu" then for _, cp in ipairs(cpu) do cp.has_ball = false end end

    -- Goal?
    local scorer = check_goal()
    if scorer then ball.owner = nil; kickoff() end

    -- Time up
    if time_left <= 0 then game_state = "gameover" end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function luna.render()
    -- Pitch
    luna.gfx.setColor(0.16, 0.52, 0.12)
    luna.gfx.rectangle("fill", PX, PY, PW, PH)
    -- Striped grass
    for i = 0, 9 do
        if i % 2 == 0 then
            luna.gfx.setColor(0.2, 0.56, 0.15, 0.4)
            luna.gfx.rectangle("fill", PX + i * (PW/10), PY, PW/10, PH)
        end
    end
    -- Lines
    luna.gfx.setColor(1, 1, 1, 0.8)
    luna.gfx.rectangle("line", PX, PY, PW, PH)
    luna.gfx.line(PX + PW/2, PY, PX + PW/2, PY + PH)
    luna.gfx.circle("line", PX + PW/2, PY + PH/2, 50)
    -- Goals
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.rectangle("line", PX - GOAL_W, PY + PH/2 - GOAL_H/2, GOAL_W, GOAL_H)
    luna.gfx.rectangle("line", PX + PW, PY + PH/2 - GOAL_H/2, GOAL_W, GOAL_H)
    -- Penalty areas
    luna.gfx.rectangle("line", PX, PY + PH/2 - 90, 70, 180)
    luna.gfx.rectangle("line", PX + PW - 70, PY + PH/2 - 90, 70, 180)

    -- CPU team (red)
    for i, cp in ipairs(cpu) do
        luna.gfx.setColor(0.85, 0.15, 0.15)
        luna.gfx.circle("fill", cp.x, cp.y, 9)
        luna.gfx.setColor(0, 0, 0)
        luna.gfx.print(tostring(i), cp.x - 4, cp.y - 6, 1.1)
    end

    -- Player team (blue)
    for i, p in ipairs(team) do
        local sel = i == controlled
        luna.gfx.setColor(sel and 0.9 or 0.2, sel and 0.9 or 0.4, sel and 0.2 or 0.9)
        luna.gfx.circle("fill", p.x, p.y, 9)
        if sel then
            luna.gfx.setColor(1, 1, 0)
            luna.gfx.circle("line", p.x, p.y, 12)
        end
        luna.gfx.setColor(0, 0, 0)
        luna.gfx.print(tostring(i), p.x - 4, p.y - 6, 1.1)
    end

    -- Ball
    local bs = 0.6 + 0.4 * math.sin(anim * 10)
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.circle("fill", ball.x, ball.y, 7)
    luna.gfx.setColor(0, 0, 0)
    luna.gfx.circle("line", ball.x, ball.y, 7)
    -- Spinning pattern
    luna.gfx.setColor(0.2, 0.2, 0.2)
    luna.gfx.rectangle("fill", ball.x - 2, ball.y - 2, 4, 4)

    -- HUD
    luna.gfx.setColor(0, 0, 0, 0.7)
    luna.gfx.rectangle("fill", 0, 0, W, 42)
    luna.gfx.setColor(0.4, 0.6, 1)
    luna.gfx.print("YOU", 20, 5, 2)
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print(scores.player .. " — " .. scores.cpu, W/2 - 30, 5, 2.5)
    luna.gfx.setColor(1, 0.4, 0.4)
    luna.gfx.print("CPU", W - 70, 5, 2)
    local mins = math.floor(time_left / 60)
    local secs = math.floor(time_left % 60)
    luna.gfx.setColor(1, 0.9, 0.3)
    luna.gfx.print(string.format("%d:%02d", mins, secs), W/2 - 20, H - 25, 1.8)

    luna.gfx.setColor(0.6, 0.8, 0.6, 0.6)
    luna.gfx.print("[WASD/Arrows] Move  [Space] Kick  [Tab] Switch player", 10, H - 20, 1.3)

    -- Kickoff flash
    if kickoff_timer > 0 then
        luna.gfx.setColor(1, 1, 0.3, kickoff_timer)
        luna.gfx.print("GOAL!", W/2 - 35, H/2 - 15, 4)
    end

    if game_state == "gameover" then
        luna.gfx.setColor(0, 0, 0, 0.75)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        local msg = scores.player > scores.cpu and "YOU WIN!" or
                    scores.player < scores.cpu and "CPU WINS" or "DRAW!"
        local col = scores.player > scores.cpu and {0.3,1,0.4} or
                    scores.player < scores.cpu and {1,0.3,0.3} or {1,1,0.4}
        luna.gfx.setColor(col[1], col[2], col[3])
        luna.gfx.print(msg, W/2 - #msg * 14, H/2 - 25, 4)
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print(scores.player .. " — " .. scores.cpu, W/2 - 30, H/2 + 20, 3)
        luna.gfx.setColor(0.6, 0.6, 0.6)
        luna.gfx.print("Press R to restart", W/2 - 100, H/2 + 65, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then luna.load() end
    if game_state ~= "playing" or kickoff_timer > 0 then return end
    local p = team[controlled]
    if key == "space" then
        if ball.owner == "player" then
            -- Kick toward CPU goal
            local gx = PX + PW; local gy = PY + PH/2
            local dx = gx - ball.x; local dy = gy - ball.y
            local d = math.sqrt(dx*dx + dy*dy)
            ball.owner = nil
            ball.vx = (dx/d) * KICK_POWER + (math.random()-0.5) * 60
            ball.vy = (dy/d) * KICK_POWER + (math.random()-0.5) * 60
        else
            -- Tackle — try to take ball from nearest CPU player
            for _, cp in ipairs(cpu) do
                if cp.has_ball and dist2(p.x, p.y, cp.x, cp.y) < TACKLE_RANGE^2 + 200 then
                    ball.owner = "player"; cp.has_ball = false
                    ball.vx = 0; ball.vy = 0; break
                end
            end
        end
    end
    if key == "tab" then
        -- Switch to nearest player to the ball
        local best, best_d = 1, 999999
        for i, pl in ipairs(team) do
            local d = dist2(pl.x, pl.y, ball.x, ball.y)
            if d < best_d then best = i; best_d = d end
        end
        controlled = best
    end
end
