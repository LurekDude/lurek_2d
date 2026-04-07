-- Ski Jump — Sport Game (Luna2D demo)
-- Three phases: crouch (hold Space) → in-air lean (A/D) → land (Space).
-- Your distance depends on all three phases perfectly timed.

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600

-- The ramp profile: list of {x,y} screen points
local RAMP = {
    {  60,  60 }, { 120,  80 }, { 180, 110 }, { 240, 150 },
    { 300, 200 }, { 360, 260 }, { 400, 310 }, { 430, 340 },
    { 450, 368 },  -- kicker / take-off point (index 9)
}
local TAKEOFF_X   = RAMP[#RAMP].x
local TAKEOFF_Y   = RAMP[#RAMP].y
local LANDING_X   = 460   -- slope starts here
local LANDING_SLOPE = 1.2  -- rise/run of landing hill
local GRAVITY = 350

-- ── State ─────────────────────────────────────────────────────────────────

local phase     = "intro"  -- intro / slide / airborne / landing / score / gameover
local skier     = {}
local anim      = 0
local run       = 0    -- progress along ramp 0→1
local speed     = 0    -- slope speed
local crouch    = 0    -- 0=standing 1=crouched (held Space)
local launch_v  = 0
local lean      = 0    -- -1 back  0 neutral  +1 forward
local air_time  = 0
local land_dist = 0    -- in metres (proportional to x distance)
local scores    = {}   -- 3 attempts
local attempt   = 0
local best      = 0

local function start_attempt()
    run = 0; speed = 0; crouch = 0; lean = 0; air_time = 0; land_dist = 0
    phase = "slide"
    skier = { x = RAMP[1].x, y = RAMP[1].y - 12,
              vx = 0, vy = 0, angle = 0 }
end

local function reset()
    scores = {}; attempt = 0; best = 0
    start_attempt()
end

-- Interpolate ramp position
local function ramp_pos(t)
    local idx = math.floor(t * (#RAMP - 1)) + 1
    idx = math.min(idx, #RAMP - 1)
    local frac = (t * (#RAMP - 1)) - (idx - 1)
    local a, b = RAMP[idx], RAMP[idx + 1]
    return a.x + (b.x - a.x) * frac, a.y + (b.y - a.y) * frac
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.init()
    luna.gfx.setBackgroundColor(0.55, 0.75, 0.92)
    reset()
end

-- ── Update ────────────────────────────────────────────────────────────────

function luna.process(dt)
    anim = anim + dt
    if phase == "intro" or phase == "score" or phase == "gameover" then return end

    if phase == "slide" then
        -- Speed increases as slope steepens; crouch at the bottom boosts
        speed = speed + (2.5 + crouch * 3.0) * dt
        run = run + speed * dt * 0.04
        if run >= 1 then run = 1 end
        skier.x, skier.y = ramp_pos(run)

        -- Launch at kicker
        if run >= 1 then
            phase = "airborne"
            local boost = 0.55 + crouch * 0.45   -- crouch timing
            skier.vx = 280 * boost
            skier.vy = -180 * boost
            skier.x = TAKEOFF_X; skier.y = TAKEOFF_Y
        end

    elseif phase == "airborne" then
        air_time = air_time + dt
        -- Lean changes vy (forward = gain distance / back = balance)
        skier.vy = skier.vy + GRAVITY * dt
        skier.vx = skier.vx + lean * 12 * dt
        skier.x  = skier.x + skier.vx * dt
        skier.y  = skier.y + skier.vy * dt
        skier.angle = math.atan(skier.vy, skier.vx)

        -- Landing: check if skier hits slope
        local slope_y = TAKEOFF_Y + (skier.x - LANDING_X) * LANDING_SLOPE
        if skier.x > LANDING_X and skier.y >= slope_y then
            skier.y = slope_y
            -- Fall check: bad landing if vx almost matches lean*factor
            land_dist = math.floor((skier.x - TAKEOFF_X) / 3.5)
            phase = "landing"
        end

    elseif phase == "landing" then
        -- Slide to stop on slope
        skier.vx = skier.vx * (1 - dt * 4)
        skier.x = skier.x + skier.vx * dt
        skier.y = TAKEOFF_Y + (skier.x - LANDING_X) * LANDING_SLOPE
        if math.abs(skier.vx) < 5 then
            attempt = attempt + 1
            scores[attempt] = land_dist
            if land_dist > best then best = land_dist end
            phase = "score"
            anim = 0
        end
    end
end

-- ── Draw ──────────────────────────────────────────────────────────────────

local function draw_skier(x, y, angle, crouching)
    luna.gfx.setColor(0.1, 0.2, 0.7)
    -- Body
    local bx = x + math.cos(angle) * 6
    local by = y + math.sin(angle) * 6
    if crouching then
        luna.gfx.rectangle("fill", x - 5, y - 6, 10, 10)
    else
        luna.gfx.rectangle("fill", x - 5, y - 14, 10, 16)
    end
    -- Head
    luna.gfx.setColor(0.9, 0.6, 0.3)
    luna.gfx.circle("fill", x, crouching and y - 10 or y - 18, 7)
    -- Skis
    luna.gfx.setColor(0.9, 0.1, 0.1)
    luna.gfx.rectangle("fill", x - 14, y, 28, 4)
end

local function draw_ramp()
    -- Fill
    luna.gfx.setColor(0.88, 0.94, 1)
    local pts_x, pts_y = {}, {}
    for _, p in ipairs(RAMP) do pts_x[#pts_x+1] = p.x; pts_y[#pts_y+1] = p.y end
    -- Draw ramp as thick segments
    luna.gfx.setColor(0.88, 0.94, 1)
    for i = 1, #RAMP - 1 do
        local a, b = RAMP[i], RAMP[i+1]
        luna.gfx.line(a.x, a.y, b.x, b.y)
    end
    -- Draw outline
    luna.gfx.setColor(0.6, 0.75, 0.95)
    for i = 1, #RAMP - 1 do
        local a, b = RAMP[i], RAMP[i+1]
        luna.gfx.rectangle("fill", a.x - 5, a.y - 5, b.x - a.x + 10, 10)
    end
end

local function draw_landing_slope()
    -- Slope continues from takeoff point
    luna.gfx.setColor(0.88, 0.94, 1)
    for xi = LANDING_X, W - 10, 10 do
        local ya = TAKEOFF_Y + (xi - LANDING_X) * LANDING_SLOPE
        local yb = TAKEOFF_Y + (xi + 10 - LANDING_X) * LANDING_SLOPE
        luna.gfx.line(xi, ya, xi + 10, yb)
    end
    -- Slope fill
    luna.gfx.setColor(0.72, 0.88, 0.98)
    for xi = LANDING_X, W - 20, 20 do
        local sy = TAKEOFF_Y + (xi - LANDING_X) * LANDING_SLOPE
        luna.gfx.rectangle("fill", xi, sy, 20, 12)
    end
    -- Distance markers (every ~30m)
    for m = 30, 120, 30 do
        local mx = LANDING_X + m * 3.5
        local my = TAKEOFF_Y + (mx - LANDING_X) * LANDING_SLOPE - 10
        if mx < W then
            luna.gfx.setColor(0.4, 0.4, 0.4, 0.8)
            luna.gfx.line(mx, my, mx, my + 10)
            luna.gfx.setColor(0.2, 0.2, 0.2)
            luna.gfx.print(tostring(m), mx - 8, my - 14, 1.2)
        end
    end
end

function luna.render()
    -- Background
    luna.gfx.setColor(0.55, 0.75, 0.92)
    luna.gfx.rectangle("fill", 0, 0, W, H)
    -- Mountains
    luna.gfx.setColor(0.8, 0.88, 0.96)
    luna.gfx.rectangle("fill", 0, H - 150, W, 150)
    luna.gfx.setColor(0.92, 0.96, 1)
    for i = 0, 6 do
        local mx = 60 + i * 110
        luna.gfx.rectangle("fill", mx - 50, H - 200 - (i%3)*40, 100, 100)
    end

    draw_landing_slope()
    draw_ramp()

    -- Skier
    local crouching = (phase == "slide" and luna.input.isKeyDown("space"))
    draw_skier(skier.x, skier.y, phase == "airborne" and skier.angle or 0, crouching)

    -- HUD
    luna.gfx.setColor(0, 0, 0, 0.6)
    luna.gfx.rectangle("fill", 0, 0, W, 50)
    luna.gfx.setColor(1, 0.9, 0.3)
    luna.gfx.print("SKI JUMP", 14, 8, 2.5)

    -- Scores
    for i = 1, 3 do
        luna.gfx.setColor(i <= attempt and 1 or 0.5, i <= attempt and 1 or 0.5, 0.5)
        local s = scores[i] and (scores[i] .. "m") or "—"
        luna.gfx.print("Jump " .. i .. ": " .. s, W/2 + (i-2)*140 - 50, 12, 1.6)
    end
    luna.gfx.setColor(0.4, 1, 0.6)
    luna.gfx.print("Best: " .. best .. "m", W - 130, 12, 1.8)

    -- Phase instruction
    if phase == "slide" then
        luna.gfx.setColor(1, 1, 0.6, 0.9)
        luna.gfx.print("Hold SPACE to crouch low on the ramp!", 14, H - 24, 1.6)
        -- Crouch indicator
        local cb = luna.input.isKeyDown("space") and 1 or 0.3
        luna.gfx.setColor(cb, cb * 0.7, 0)
        luna.gfx.print("[HOLD SPACE] = Crouch", 14, H - 46, 1.4)
    elseif phase == "airborne" then
        luna.gfx.setColor(1, 1, 0.6, 0.9)
        luna.gfx.print("A = Lean back   D = Lean forward   (neutral = straight arms)", 14, H - 24, 1.4)
        -- Lean bar
        luna.gfx.setColor(0.3, 0.3, 0.3)
        luna.gfx.rectangle("fill", W - 150, H - 55, 130, 20)
        luna.gfx.setColor(0.1, 0.8, 0.3)
        luna.gfx.rectangle("fill", W - 85, H - 55, lean * 60, 20)
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.line(W - 85, H - 60, W - 85, H - 30)
        luna.gfx.print("LEAN", W - 152, H - 55, 1.2)
    elseif phase == "landing" then
        luna.gfx.setColor(0.5, 0.9, 1, 0.9)
        luna.gfx.print("Landing...", 14, H - 24, 2)
    end

    -- Score overlay
    if phase == "score" then
        luna.gfx.setColor(0, 0, 0, 0.65)
        luna.gfx.rectangle("fill", W/2 - 160, H/2 - 50, 320, 100)
        luna.gfx.setColor(1, 1, 0.3)
        luna.gfx.print("JUMP " .. attempt .. ":", W/2 - 50, H/2 - 42, 1.8)
        luna.gfx.setColor(0.3, 1, 0.3)
        luna.gfx.print(land_dist .. " m", W/2 - 30, H/2 - 10, 3)
        luna.gfx.setColor(0.7, 0.7, 0.7)
        if attempt < 3 then
            luna.gfx.print("Press SPACE for attempt " .. (attempt+1), W/2 - 110, H/2 + 38, 1.5)
        else
            luna.gfx.print("Press SPACE to see final", W/2 - 110, H/2 + 38, 1.5)
        end
    end

    -- Game over
    if phase == "gameover" then
        luna.gfx.setColor(0, 0, 0, 0.8)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        luna.gfx.setColor(1, 0.9, 0.2)
        luna.gfx.print("COMPETITION OVER", W/2 - 130, H/2 - 60, 2.8)
        local golds = {}
        for i = 1, 3 do golds[i] = scores[i] and (scores[i] .. " m") or "—" end
        luna.gfx.setColor(1, 1, 1)
        for i = 1, 3 do
            luna.gfx.print("Jump " .. i .. ": " .. golds[i], W/2 - 60, H/2 - 10 + i*30, 2)
        end
        luna.gfx.setColor(0.3, 1, 0.5)
        luna.gfx.print("BEST: " .. best .. " m", W/2 - 55, H/2 + 110, 2.5)
        luna.gfx.setColor(0.6, 0.6, 0.6)
        luna.gfx.print("Press R to compete again", W/2 - 120, H/2 + 145, 1.8)
    end
end

-- ── Input ─────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then luna.load() end

    if phase == "score" then
        if key == "space" then
            if attempt < 3 then start_attempt()
            else phase = "gameover" end
        end
        return
    end

    if phase == "airborne" then
        if key == "a" or key == "left"  then lean = -1 end
        if key == "d" or key == "right" then lean =  1 end
    end
end
