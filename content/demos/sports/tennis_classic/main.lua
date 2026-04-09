-- Tennis Classic — Sport Game (Lurek2D demo)
-- Top-down tennis with serve, topspin, and slice mechanics.
-- Play against CPU. First to 6 games wins the set.
-- Run with: cargo run -- content/demos/sports/tennis_classic

-- ── Constants ────────────────────────────────────────────────────────────

local W, H       = 800, 600
local COURT_X    = 80
local COURT_Y    = 60
local COURT_W    = 640
local COURT_H    = 480
local NET_Y      = COURT_Y + COURT_H / 2
local BALL_SPD   = 350
local PLAYER_SPD = 200
local CPU_SPD    = 160
local MAX_GAMES  = 6

-- Score names in tennis
local SCORES = { "0", "15", "30", "40" }

-- ── State ─────────────────────────────────────────────────────────────────

local ball = {}
local pl   = {}  -- Player (bottom half)
local cpu  = {}  -- CPU (top half)
local pts  = { pl = 0, cpu = 0 }
local games = { pl = 0, cpu = 0 }
local game_state = "serve"
local server = "pl"
local anim = 0
local swing_cd = 0
local rally_count = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function sign(v) return v > 0 and 1 or (v < 0 and -1 or 0) end

local function serve()
    if server == "pl" then
        ball = { x = pl.x + pl.w/2, y = pl.y - 12, vx = 0, vy = -BALL_SPD * 0.8 }
    else
        ball = { x = cpu.x + cpu.w/2, y = cpu.y + cpu.h + 12, vx = 0, vy = BALL_SPD * 0.8 }
    end
    game_state = "playing"
    rally_count = 0
end

local function point_to(winner)
    pts[winner] = pts[winner] + 1
    if pts.pl >= 4 and pts.cpu >= 4 then
        -- Deuce / adv handled simply
        if math.abs(pts.pl - pts.cpu) >= 2 then
            if pts.pl > pts.cpu then games.pl = games.pl + 1 else games.cpu = games.cpu + 1 end
            pts = { pl = 0, cpu = 0 }
        end
    elseif pts[winner] >= 4 then
        games[winner] = games[winner] + 1
        pts = { pl = 0, cpu = 0 }
    end

    if games.pl >= MAX_GAMES or games.cpu >= MAX_GAMES then
        game_state = "gameover"
    else
        server = winner  -- Winner serves next
        game_state = "serve_prep"
    end
end

local function reset()
    pl  = { x = W/2 - 20, y = COURT_Y + COURT_H - 80, w = 40, h = 20 }
    cpu = { x = W/2 - 20, y = COURT_Y + 20, w = 40, h = 20 }
    pts = { pl = 0, cpu = 0 }
    games = { pl = 0, cpu = 0 }
    server = "pl"
    game_state = "serve"
    rally_count = 0
    swing_cd = 0
    serve()
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.gfx.setBackgroundColor(0.15, 0.5, 0.15)
    reset()
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    if game_state ~= "playing" then return end
    anim = anim + dt
    swing_cd = math.max(0, swing_cd - dt)

    -- Player movement
    if lurek.input.isKeyDown("left") or lurek.input.isKeyDown("a") then
        pl.x = clamp(pl.x - PLAYER_SPD * dt, COURT_X, COURT_X + COURT_W - pl.w)
    end
    if lurek.input.isKeyDown("right") or lurek.input.isKeyDown("d") then
        pl.x = clamp(pl.x + PLAYER_SPD * dt, COURT_X, COURT_X + COURT_W - pl.w)
    end
    -- Player also moves up/down in back half of court
    pl.y = clamp(pl.y, NET_Y + 5, COURT_Y + COURT_H - pl.h)
    if lurek.input.isKeyDown("up") or lurek.input.isKeyDown("w") then
        pl.y = clamp(pl.y - PLAYER_SPD * 0.5 * dt, NET_Y + 5, COURT_Y + COURT_H - pl.h)
    end
    if lurek.input.isKeyDown("down") or lurek.input.isKeyDown("s") then
        pl.y = clamp(pl.y + PLAYER_SPD * 0.5 * dt, NET_Y + 5, COURT_Y + COURT_H - pl.h)
    end

    -- Ball movement
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Court boundary bounce (sidelines = fault → point to opponent)
    if ball.x < COURT_X or ball.x > COURT_X + COURT_W then
        point_to(ball.vy > 0 and "pl" or "cpu")
        return
    end

    -- Baseline out
    if ball.y < COURT_Y then     -- CPU out
        point_to("pl"); return
    end
    if ball.y > COURT_Y + COURT_H then  -- Player out
        point_to("cpu"); return
    end

    -- Net collision
    if math.abs(ball.y - NET_Y) < 8 then
        point_to(ball.vy < 0 and "pl" or "cpu"); return
    end

    -- Player hit detection (bottom of court)
    local pbx = pl.x + pl.w/2
    if ball.vy > 0 and ball.y >= pl.y and ball.y < pl.y + pl.h and
       ball.x > pl.x - 5 and ball.x < pl.x + pl.w + 5 then
        rally_count = rally_count + 1
        -- Angle based on contact offset
        local offset = (ball.x - (pl.x + pl.w/2)) / (pl.w / 2)
        ball.vy = -BALL_SPD * (1 + rally_count * 0.02)
        ball.vx = offset * BALL_SPD * 0.8
        -- Topspin
        if lurek.input.isKeyDown("space") then ball.vy = ball.vy * 1.2 end
    end

    -- CPU AI: track ball in its half
    if ball.vy < 0 then  -- Ball moving toward CPU
        local target_x = ball.x - cpu.w/2
        local diff = target_x - cpu.x
        cpu.x = cpu.x + clamp(diff, -CPU_SPD * dt, CPU_SPD * dt)
    else
        -- Return to center
        local diff = W/2 - cpu.w/2 - cpu.x
        cpu.x = cpu.x + clamp(diff, -CPU_SPD * 0.4 * dt, CPU_SPD * 0.4 * dt)
    end
    cpu.x = clamp(cpu.x, COURT_X, COURT_X + COURT_W - cpu.w)

    -- CPU hit
    if ball.vy < 0 and ball.y <= cpu.y + cpu.h and ball.y > cpu.y and
       ball.x > cpu.x - 5 and ball.x < cpu.x + cpu.w + 5 then
        rally_count = rally_count + 1
        local offset = (ball.x - (cpu.x + cpu.w/2)) / (cpu.w / 2)
        ball.vy = BALL_SPD * (1 + rally_count * 0.02)
        ball.vx = offset * BALL_SPD * 0.7 + (math.random()-0.5) * 40
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    -- Green court
    lurek.gfx.setColor(0.12, 0.45, 0.12)
    lurek.gfx.rectangle("fill", COURT_X, COURT_Y, COURT_W, COURT_H)

    -- Court lines
    lurek.gfx.setColor(1, 1, 1, 0.9)
    lurek.gfx.rectangle("line", COURT_X, COURT_Y, COURT_W, COURT_H)
    -- Net
    lurek.gfx.rectangle("fill", COURT_X, NET_Y - 3, COURT_W, 6)
    -- Service boxes
    local mid_x = COURT_X + COURT_W/2
    lurek.gfx.line(mid_x, COURT_Y, mid_x, COURT_Y + COURT_H)
    lurek.gfx.line(COURT_X, NET_Y - COURT_H/4, COURT_X + COURT_W, NET_Y - COURT_H/4)
    lurek.gfx.line(COURT_X, NET_Y + COURT_H/4, COURT_X + COURT_W, NET_Y + COURT_H/4)

    -- CPU player
    lurek.gfx.setColor(0.9, 0.2, 0.2)
    lurek.gfx.rectangle("fill", cpu.x, cpu.y, cpu.w, cpu.h)
    lurek.gfx.setColor(0.85, 0.65, 0.4)
    lurek.gfx.circle("fill", cpu.x + cpu.w/2, cpu.y - 8, 9)

    -- Player
    local plr = 0.9 + 0.1 * math.sin(anim * 6)
    lurek.gfx.setColor(0.2, 0.5, plr)
    lurek.gfx.rectangle("fill", pl.x, pl.y, pl.w, pl.h)
    lurek.gfx.setColor(0.85, 0.65, 0.4)
    lurek.gfx.circle("fill", pl.x + pl.w/2, pl.y + pl.h + 8, 9)

    -- Ball
    lurek.gfx.setColor(0.9, 0.9, 0.1)
    lurek.gfx.circle("fill", ball.x, ball.y, 7)
    lurek.gfx.setColor(0, 0.3, 0)
    lurek.gfx.circle("line", ball.x, ball.y, 7)

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.65)
    lurek.gfx.rectangle("fill", 0, 0, COURT_X, H)
    lurek.gfx.rectangle("fill", COURT_X + COURT_W, 0, W - COURT_X - COURT_W, H)

    local pl_score = pts.pl <= 3 and SCORES[pts.pl + 1] or (pts.pl > pts.cpu and "ADV" or "40")
    local cpu_score = pts.cpu <= 3 and SCORES[pts.cpu + 1] or (pts.cpu > pts.pl and "ADV" or "40")

    lurek.gfx.setColor(1, 0.4, 0.4)
    lurek.gfx.print("CPU", 10, 130, 1.4)
    lurek.gfx.print(tostring(games.cpu), 12, 150, 2.5)
    lurek.gfx.print(cpu_score, 10, 185, 1.8)

    lurek.gfx.setColor(0.4, 0.7, 1)
    lurek.gfx.print("YOU", 10, 360, 1.4)
    lurek.gfx.print(tostring(games.pl), 12, 380, 2.5)
    lurek.gfx.print(pl_score, 10, 415, 1.8)

    lurek.gfx.setColor(0.9, 0.9, 0.9)
    lurek.gfx.print("SET", 14, 110, 1.3)
    lurek.gfx.print("pts:", 12, 170, 1.1)

    -- Ball shadow for depth cue
    local shadow_y_offset = math.abs(math.sin(anim * (math.abs(ball.vy) / BALL_SPD) * 3)) * 5
    lurek.gfx.setColor(0, 0, 0, 0.3)
    lurek.gfx.circle("fill", ball.x, ball.y + shadow_y_offset + 6, 5)

    lurek.gfx.setColor(0.6, 0.8, 0.6, 0.6)
    lurek.gfx.print("[WASD/Arrows] Move  [Space] Topspin", COURT_X + 5, COURT_Y + COURT_H + 8, 1.3)

    -- Serve prompt
    if game_state == "serve_prep" then
        lurek.gfx.setColor(1, 1, 0.5, 0.8)
        lurek.gfx.print("Press SPACE to serve", COURT_X + COURT_W/2 - 100, NET_Y - 18, 1.8)
    end

    -- Gameover
    if game_state == "gameover" then
        lurek.gfx.setColor(0, 0, 0, 0.78)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
        local winner = games.pl >= MAX_GAMES and "YOU WIN!" or "CPU WINS"
        local col = games.pl >= MAX_GAMES and {0.4, 1, 0.3} or {1, 0.3, 0.3}
        lurek.gfx.setColor(col[1], col[2], col[3])
        lurek.gfx.print(winner, W/2 - 80, H/2 - 25, 3.2)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print(games.pl .. " — " .. games.cpu, W/2 - 28, H/2 + 18, 2.5)
        lurek.gfx.setColor(0.6, 0.6, 0.6)
        lurek.gfx.print("Press R to restart", W/2 - 100, H/2 + 55, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    if key == "space" and game_state == "serve_prep" then serve() end
end
