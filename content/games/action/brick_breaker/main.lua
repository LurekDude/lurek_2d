-- ============================================================================
--  Brick Breaker — Classic Arkanoid-style brick breaking game
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/brick_breaker
--
--  Controls (bound as input actions — see lurek.init):
--    left/right : A/D or ←/→  (move paddle)
--    launch     : Space        (launch ball)
--    start      : Enter        (title / next level / restart)
--    quit       : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
local W, H            = 800, 600
local PADDLE_W        = 100
local PADDLE_WIDE_W   = 160
local PADDLE_H        = 14
local PADDLE_Y        = H - 40
local PADDLE_SPEED    = 500
local BALL_R          = 6
local BALL_BASE_SPEED = 320
local BALL_SPEED_INC  = 15

local BRICK_COLS      = 10
local BRICK_W         = 64
local BRICK_H         = 20
local BRICK_PAD       = 4
local BRICK_OX        = (W - BRICK_COLS * (BRICK_W + BRICK_PAD) + BRICK_PAD) / 2
local BRICK_OY        = 60

local PU_SIZE         = 16
local PU_FALL         = 120
local PU_CHANCE       = 0.30
local PU_DUR          = 8

local HP_CLR = { [3]={0.7,0.2,0.9}, [2]={0.2,0.5,1.0}, [1]={0.2,0.9,0.3} }
local HP_OUT = { [3]={0.5,0.1,0.7}, [2]={0.1,0.3,0.8}, [1]={0.1,0.7,0.2} }
local PU_CLR = { W={1.0,0.6,0.1}, M={0.2,0.8,1.0}, S={0.4,1.0,0.4} }

-- ── State ─────────────────────────────────────────────────────────────────
local STATE = { TITLE=1, PLAYING=2, GAME_OVER=3, LEVEL_COMPLETE=4 }
local state           = STATE.TITLE
local paddle_x, pad_w = 0, PADDLE_W
local balls, bricks, powerups = {}, {}, {}
local score, lives, level     = 0, 3, 1
local ball_speed      = BALL_BASE_SPEED
local brick_count     = 0
local on_paddle       = true
local wide_tmr, slow_tmr = 0, 0
local blink           = 0
local flash           = { alpha = 0 }

-- Particles
local brick_ps, hit_ps

-- ── Helpers ───────────────────────────────────────────────────────────────
local function clamp(v,lo,hi) if v<lo then return lo end if v>hi then return hi end return v end

local function overlap(ax,ay,aw,ah, bx,by,bw,bh)
    return ax<bx+bw and ax+aw>bx and ay<by+bh and ay+ah>by
end

local function make_ball(x,y,a)
    a = a or (-math.pi/2 + (math.random()-0.5)*0.4)
    return {x=x, y=y, dx=math.cos(a), dy=math.sin(a)}
end

local function init_bricks()
    bricks, brick_count = {}, 0
    local rows = clamp(3+level, 4, 8)
    for r=0, rows-1 do
        local hp = 1
        if r<1 then hp=math.min(3,level) elseif r<2 then hp=math.min(2,level) end
        for c=0, BRICK_COLS-1 do
            bricks[#bricks+1] = {
                x = BRICK_OX + c*(BRICK_W+BRICK_PAD),
                y = BRICK_OY + r*(BRICK_H+BRICK_PAD),
                hp = hp, alive = true,
            }
            brick_count = brick_count + 1
        end
    end
end

local function reset_paddle()
    pad_w = PADDLE_W;  paddle_x = W/2 - pad_w/2
    wide_tmr, slow_tmr = 0, 0
end

local function start_level()
    init_bricks();  reset_paddle()
    balls, powerups, on_paddle = {}, {}, true
    ball_speed = BALL_BASE_SPEED + (level-1)*BALL_SPEED_INC
    state = STATE.PLAYING
end

local function start_game()
    score, lives, level = 0, 3, 1;  start_level()
end

local function maybe_drop(bx, by)
    if math.random() < PU_CHANCE then
        local k = ({"W","M","S"})[math.random(3)]
        powerups[#powerups+1] = {x=bx+BRICK_W/2-PU_SIZE/2, y=by, kind=k}
    end
end

local function apply_pu(k)
    if k=="W" then
        wide_tmr = PU_DUR;  pad_w = PADDLE_WIDE_W
        paddle_x = clamp(paddle_x, 0, W-pad_w)
    elseif k=="M" then
        local add={}
        for _,b in ipairs(balls) do
            local a=math.atan2(b.dy,b.dx)
            add[#add+1]=make_ball(b.x,b.y,a+0.3)
            add[#add+1]=make_ball(b.x,b.y,a-0.3)
        end
        for _,b in ipairs(add) do balls[#balls+1]=b end
    elseif k=="S" then
        slow_tmr = PU_DUR
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────

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
local function rect(a, b, c, d, e, f, g, h, i)
    if type(a) == "string" then
        if type(f) == "number" then _gfx.setColor(f, g or 1, h or 1, i or 1) end
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
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
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Brick Breaker — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.1)

    lurek.input.bind("left",   {"a","left"})
    lurek.input.bind("right",  {"d","right"})
    lurek.input.bind("launch", {"space"})
    lurek.input.bind("start",  {"return"})
    lurek.input.bind("quit",   {"escape"})

    brick_ps = lurek.particle.newSystem({maxParticles=200})
    brick_ps:setParticleLifetime(0.3, 0.6)
    brick_ps:setSpeed(60, 150)
    brick_ps:setSpread(math.pi*2)
    brick_ps:setSizes(4, 1)

    hit_ps = lurek.particle.newSystem({maxParticles=50})
    hit_ps:setParticleLifetime(0.1, 0.25)
    hit_ps:setSpeed(40, 100)
    hit_ps:setSpread(math.pi)
    hit_ps:setSizes(3, 1)
    hit_ps:setColors({1,0.9,0.5,1}, {1,0.5,0.1,0})

    lurek.camera.new()
end

-- ── Process ───────────────────────────────────────────────────────────────
function lurek.process(dt)
    blink = blink + dt
    if lurek.input.wasActionPressed("quit") then lurek.event.quit(); return end

    brick_ps:update(dt)
    hit_ps:update(dt)

    -- Non-playing states
    if state == STATE.TITLE then
        if lurek.input.wasActionPressed("start") or lurek.input.wasActionPressed("launch") then start_game() end
        return
    end
    if state == STATE.LEVEL_COMPLETE then
        if lurek.input.wasActionPressed("start") or lurek.input.wasActionPressed("launch") then
            level = level + 1;  start_level()
        end
        return
    end
    if state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("start") or lurek.input.wasActionPressed("launch") then start_game() end
        return
    end

    -- Power-up timer decay
    if wide_tmr > 0 then
        wide_tmr = wide_tmr - dt
        if wide_tmr <= 0 then pad_w = PADDLE_W; paddle_x = clamp(paddle_x,0,W-pad_w) end
    end
    if slow_tmr > 0 then slow_tmr = slow_tmr - dt end

    -- Paddle
    if lurek.input.isActionDown("left")  then paddle_x = paddle_x - PADDLE_SPEED*dt end
    if lurek.input.isActionDown("right") then paddle_x = paddle_x + PADDLE_SPEED*dt end
    paddle_x = clamp(paddle_x, 0, W-pad_w)

    if on_paddle then
        if lurek.input.wasActionPressed("launch") then
            on_paddle = false
            balls = { make_ball(paddle_x+pad_w/2, PADDLE_Y-BALL_R-1) }
        end
        return
    end

    local spd = ball_speed * (slow_tmr > 0 and 0.55 or 1)

    -- Move balls
    local lost = {}
    for i,b in ipairs(balls) do
        b.x = b.x + b.dx*spd*dt
        b.y = b.y + b.dy*spd*dt

        if b.x-BALL_R < 0 then b.x=BALL_R; b.dx=math.abs(b.dx) end
        if b.x+BALL_R > W then b.x=W-BALL_R; b.dx=-math.abs(b.dx) end
        if b.y-BALL_R < 0 then b.y=BALL_R; b.dy=math.abs(b.dy) end

        -- Paddle bounce
        if b.dy>0 and overlap(b.x-BALL_R,b.y-BALL_R,BALL_R*2,BALL_R*2, paddle_x,PADDLE_Y,pad_w,PADDLE_H) then
            b.y = PADDLE_Y - BALL_R
            local hit = (b.x - paddle_x)/pad_w
            local ang = -math.pi/2 + (hit-0.5)*(math.pi*0.7)
            ang = clamp(ang, -math.pi+0.15, -0.15)
            b.dx, b.dy = math.cos(ang), math.sin(ang)
            hit_ps:setDirection(-math.pi/2)
            hit_ps:moveTo(b.x, PADDLE_Y)
            hit_ps:emit(8)
        end

        -- Brick collision
        for _,br in ipairs(bricks) do
            if br.alive and overlap(b.x-BALL_R,b.y-BALL_R,BALL_R*2,BALL_R*2, br.x,br.y,BRICK_W,BRICK_H) then
                br.hp = br.hp - 1
                local c = HP_CLR[math.max(br.hp,1)]
                if br.hp <= 0 then
                    br.alive = false;  brick_count = brick_count - 1
                    score = score + 10*level
                    brick_ps:setColors({c[1],c[2],c[3],1}, {c[1],c[2],c[3],0})
                    brick_ps:moveTo(br.x+BRICK_W/2, br.y+BRICK_H/2)
                    brick_ps:emit(15)
                    maybe_drop(br.x, br.y)
                else
                    brick_ps:setColors({c[1],c[2],c[3],1}, {c[1],c[2],c[3],0})
                    brick_ps:moveTo(br.x+BRICK_W/2, br.y+BRICK_H/2)
                    brick_ps:emit(6)
                end
                -- Reflect
                local dx_p = math.abs(b.x-(br.x+BRICK_W/2)) - BRICK_W/2
                local dy_p = math.abs(b.y-(br.y+BRICK_H/2)) - BRICK_H/2
                if dx_p > dy_p then b.dx=-b.dx else b.dy=-b.dy end
                break
            end
        end

        if b.y-BALL_R > H then lost[#lost+1] = i end
    end
    for i=#lost,1,-1 do table.remove(balls, lost[i]) end

    if #balls==0 and not on_paddle then
        lives = lives - 1
        if lives <= 0 then state = STATE.GAME_OVER
        else on_paddle = true; reset_paddle() end
    end

    if brick_count <= 0 then
        state = STATE.LEVEL_COMPLETE
        flash.alpha = 1
        lurek.tween.to(flash, { alpha = 0 }, 1.5)
    end

    -- Power-ups
    local pr = {}
    for i,pu in ipairs(powerups) do
        pu.y = pu.y + PU_FALL*dt
        if overlap(pu.x,pu.y,PU_SIZE,PU_SIZE, paddle_x,PADDLE_Y,pad_w,PADDLE_H) then
            apply_pu(pu.kind); pr[#pr+1]=i
        elseif pu.y > H then pr[#pr+1]=i end
    end
    for i=#pr,1,-1 do table.remove(powerups, pr[i]) end
end

-- ── Render (world) ────────────────────────────────────────────────────────
function lurek.draw()
    -- Bricks
    for _,br in ipairs(bricks) do
        if br.alive then
            local c = HP_CLR[br.hp] or HP_CLR[1]
            local o = HP_OUT[br.hp] or HP_OUT[1]
            rect("fill", br.x,br.y, BRICK_W,BRICK_H, c[1],c[2],c[3])
            rect("line", br.x,br.y, BRICK_W,BRICK_H, o[1],o[2],o[3])
        end
    end

    -- Paddle
    local pc = wide_tmr>0 and {1,0.7,0.2} or {0.9,0.9,0.9}
    rect("fill", paddle_x,PADDLE_Y, pad_w,PADDLE_H, pc[1],pc[2],pc[3])
    rect("line", paddle_x,PADDLE_Y, pad_w,PADDLE_H, 1,1,1,0.5)

    -- Balls
    if on_paddle then
        circ("fill", paddle_x+pad_w/2, PADDLE_Y-BALL_R-1, BALL_R, 1,1,1)
    else
        for _,b in ipairs(balls) do
            circ("fill", b.x,b.y, BALL_R, 1,1,1)
            circ("fill", b.x,b.y, BALL_R+3, 1,1,1,0.15)
        end
    end

    -- Power-ups
    for _,pu in ipairs(powerups) do
        local c = PU_CLR[pu.kind]
        rect("fill", pu.x,pu.y, PU_SIZE,PU_SIZE, c[1],c[2],c[3],0.9)
        text_(pu.kind, pu.x+3, pu.y+1, 14, 1,1,1)
    end

    -- Particles
    brick_ps:render()
    hit_ps:render()

    -- Level flash
    if flash.alpha > 0.01 then
        rect("fill", 0,0, W,H, 1,1,1, flash.alpha*0.3)
    end
end

-- ── Render UI ─────────────────────────────────────────────────────────────
function lurek.draw_ui()
    local fps = lurek.timer.getFPS()
    local a = math.sin(blink*3)*0.5+0.5

    if state == STATE.TITLE then
        text_("BRICK BREAKER", W/2-130, H/2-60, 36, 0.2,0.6,1.0)
        text_("PRESS ENTER", W/2-75, H/2+10, 20, 1,1,1,a)
        text_("A/D or Arrows = Move  |  Space = Launch  |  Esc = Quit",
            W/2-220, H/2+60, 14, 0.6,0.6,0.6)
        text_(string.format("FPS: %d", fps), 10, H-20, 12, 0.4,0.4,0.4)
        return
    end

    -- HUD
    text_(string.format("SCORE: %d", score), 10, 8, 18, 1,1,1)
    text_(string.format("LEVEL: %d", level), W/2-40, 8, 18, 0.6,0.9,1)
    text_(string.format("LIVES: %d", lives), W-110, 8, 18, 1,0.4,0.4)
    text_(string.format("FPS: %d", fps), W-80, H-20, 12, 0.4,0.4,0.4)

    local iy = 30
    if wide_tmr>0 then
        text_(string.format("[W] Wide: %.0fs",wide_tmr), W-150,iy, 12, 1,0.6,0.1)
        iy = iy + 16
    end
    if slow_tmr>0 then
        text_(string.format("[S] Slow: %.0fs",slow_tmr), W-150,iy, 12, 0.4,1,0.4)
    end

    if state == STATE.GAME_OVER then
        rect("fill", 0,0, W,H, 0,0,0,0.6)
        text_("GAME OVER", W/2-100, H/2-40, 36, 1,0.3,0.3)
        text_(string.format("Final Score: %d", score), W/2-80, H/2+10, 20, 1,1,1)
        text_("PRESS ENTER TO RESTART", W/2-120, H/2+50, 16, 1,1,1,a)
    end

    if state == STATE.LEVEL_COMPLETE then
        rect("fill", 0,0, W,H, 0,0,0,0.5)
        text_(string.format("LEVEL %d COMPLETE!", level), W/2-120, H/2-30, 30, 0.2,1,0.5)
        text_("PRESS ENTER FOR NEXT LEVEL", W/2-140, H/2+20, 16, 1,1,1,a)
    end

    if state == STATE.PLAYING and on_paddle then
        text_("PRESS SPACE TO LAUNCH", W/2-105, PADDLE_Y+30, 16, 1,1,1,a)
    end
end
