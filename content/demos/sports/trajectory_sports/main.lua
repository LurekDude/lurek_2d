-- Trajectory Sports (Golf / Artillery)
-- Aim with mouse, hold Space to charge power, release to shoot.
-- 3 holes of increasing difficulty with wind.
-- Run with: cargo run -- content/demos/sports/trajectory_sports

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local W, H = 800, 600

-- terrain (line segments)
local terrain = {}
local holes = {}
local ball = {}
local state = {}
local skid_trails = {}

local function generate_terrain(hole_num)
    terrain = {}
    local segments = 40
    local dx = W / segments
    for i = 0, segments do
        local x = i * dx
        local base = H - 120
        local hill = math.sin(i * 0.3 + hole_num) * 40
            + math.sin(i * 0.7) * 20
            + math.sin(i * 0.15) * 30
        terrain[i + 1] = { x = x, y = base + hill }
    end
end

local function terrain_y_at(px)
    for i = 1, #terrain - 1 do
        local a, b = terrain[i], terrain[i + 1]
        if px >= a.x and px <= b.x then
            local t = (px - a.x) / (b.x - a.x)
            return lerp(a.y, b.y, t)
        end
    end
    return H - 120
end

local function terrain_normal_at(px)
    for i = 1, #terrain - 1 do
        local a, b = terrain[i], terrain[i + 1]
        if px >= a.x and px <= b.x then
            local dx = b.x - a.x
            local dy = b.y - a.y
            local len = math.sqrt(dx * dx + dy * dy)
            return -dy / len, dx / len
        end
    end
    return 0, -1
end

local function reset_ball(hole_num)
    local start_x = 60 + hole_num * 10
    ball.x = start_x
    ball.y = terrain_y_at(start_x) - 5
    ball.vx = 0
    ball.vy = 0
    ball.moving = false
    ball.settled = false
    ball.radius = 5
end

local function new_hole(hole_num)
    generate_terrain(hole_num)
    local hx = 600 + hole_num * 60
    if hx > W - 60 then hx = W - 60 end
    holes[hole_num] = { x = hx, y = terrain_y_at(hx), radius = 12 }
    state.wind = (math.random() - 0.5) * 200
    state.power = 0
    state.charging = false
    reset_ball(hole_num)
    skid_trails = {}
end

function lurek.init()
    state.current_hole = 1
    state.total_holes = 3
    state.strokes = 0
    state.hole_strokes = 0
    state.game_over = false
    state.hole_complete = false
    state.complete_timer = 0
    state.message = ""
    new_hole(1)
end

function lurek.process(dt)
    if state.game_over then return end

    if state.hole_complete then
        state.complete_timer = state.complete_timer - dt
        if state.complete_timer <= 0 then
            state.hole_complete = false
            if state.current_hole < state.total_holes then
                state.current_hole = state.current_hole + 1
                state.hole_strokes = 0
                new_hole(state.current_hole)
            else
                state.game_over = true
                state.message = "Complete! Total strokes: " .. state.strokes
            end
        end
        return
    end

    -- charging power
    if lurek.keyboard.isDown("space") and not ball.moving then
        state.charging = true
        state.power = clamp(state.power + dt * 400, 0, 500)
    end

    -- ball physics
    if ball.moving then
        local gravity = 400
        ball.vy = ball.vy + gravity * dt
        ball.vx = ball.vx + state.wind * dt * 0.3
        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + ball.vy * dt

        -- terrain collision
        local gy = terrain_y_at(ball.x)
        if ball.y + ball.radius >= gy then
            ball.y = gy - ball.radius
            local nx, ny = terrain_normal_at(ball.x)
            local dot = ball.vx * nx + ball.vy * ny
            ball.vx = ball.vx - 2 * dot * nx
            ball.vy = ball.vy - 2 * dot * ny
            ball.vx = ball.vx * 0.6
            ball.vy = ball.vy * 0.6
            skid_trails[#skid_trails + 1] = { x = ball.x, y = ball.y + ball.radius }
        end

        -- walls
        if ball.x < ball.radius then ball.x = ball.radius; ball.vx = -ball.vx * 0.5 end
        if ball.x > W - ball.radius then ball.x = W - ball.radius; ball.vx = -ball.vx * 0.5 end
        if ball.y < ball.radius then ball.y = ball.radius; ball.vy = -ball.vy * 0.5 end

        -- settle
        local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
        if speed < 5 and ball.y + ball.radius >= gy - 2 then
            ball.moving = false
            ball.vx = 0
            ball.vy = 0
            ball.y = gy - ball.radius
        end

        -- hole check
        local hole = holes[state.current_hole]
        local dx = ball.x - hole.x
        local dy = (ball.y + ball.radius) - hole.y
        if math.sqrt(dx * dx + dy * dy) < hole.radius then
            ball.moving = false
            state.hole_complete = true
            state.complete_timer = 2
            state.message = "Hole " .. state.current_hole .. " in " .. state.hole_strokes .. " strokes!"
        end
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
end

function lurek.keyreleased(key)
    if key == "space" and state.charging and not ball.moving then
        state.charging = false
        local mx, my = lurek.mouse.getPosition()
        local angle = math.atan2(my - ball.y, mx - ball.x)
        ball.vx = math.cos(angle) * state.power
        ball.vy = math.sin(angle) * state.power
        ball.moving = true
        state.power = 0
        state.strokes = state.strokes + 1
        state.hole_strokes = state.hole_strokes + 1
    end
end

function lurek.render()
    lurek.render.setBackgroundColor(0.15, 0.2, 0.35)

    -- sky gradient bands
    for i = 0, 5 do
        local t = i / 5
        lurek.render.setColor(0.15 + t * 0.1, 0.2 + t * 0.15, 0.35 + t * 0.15, 1)
        lurek.render.rectangle("fill", 0, i * 60, W, 60)
    end

    -- terrain fill
    lurek.render.setColor(0.2, 0.5, 0.2, 1)
    for i = 1, #terrain - 1 do
        local a, b = terrain[i], terrain[i + 1]
        lurek.render.polygon("fill", { a.x, a.y, b.x, b.y, b.x, H, a.x, H })
    end

    -- terrain outline
    lurek.render.setColor(0.3, 0.65, 0.3, 1)
    lurek.render.setLineWidth(2)
    for i = 1, #terrain - 1 do
        lurek.render.line(terrain[i].x, terrain[i].y, terrain[i + 1].x, terrain[i + 1].y)
    end

    -- hole/target
    local hole = holes[state.current_hole]
    if hole then
        lurek.render.setColor(0.1, 0.1, 0.1, 1)
        lurek.render.circle("fill", hole.x, hole.y, hole.radius)
        lurek.render.setColor(1, 0.8, 0, 1)
        lurek.render.circle("line", hole.x, hole.y, hole.radius)
        -- flag
        lurek.render.setColor(1, 0.2, 0.2, 1)
        lurek.render.line(hole.x, hole.y - 30, hole.x, hole.y)
        lurek.render.polygon("fill", { hole.x, hole.y - 30, hole.x + 15, hole.y - 22, hole.x, hole.y - 14 })
    end

    -- skid marks
    lurek.render.setColor(0.15, 0.35, 0.15, 0.6)
    for _, s in ipairs(skid_trails) do
        lurek.render.circle("fill", s.x, s.y, 2)
    end

    -- ball
    if not state.hole_complete then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.circle("fill", ball.x, ball.y, ball.radius)
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        lurek.render.circle("line", ball.x, ball.y, ball.radius)
    end

    -- aim line
    if not ball.moving and not state.hole_complete and not state.game_over then
        local mx, my = lurek.mouse.getPosition()
        lurek.render.setColor(1, 1, 1, 0.4)
        lurek.render.setLineWidth(1)
        lurek.render.line(ball.x, ball.y, mx, my)
    end

    -- power bar
    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    lurek.render.rectangle("fill", 20, 20, 160, 20)
    local pf = state.power / 500
    local pr = clamp(pf * 2, 0, 1)
    local pg = clamp(2 - pf * 2, 0, 1)
    lurek.render.setColor(pr, pg, 0, 1)
    lurek.render.rectangle("fill", 22, 22, 156 * pf, 16)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Power", 70, 22)

    -- wind arrow
    local wind_str = "Wind: "
    if state.wind > 0 then wind_str = wind_str .. ">>>" else wind_str = wind_str .. "<<<" end
    lurek.render.setColor(0.7, 0.9, 1, 1)
    lurek.render.print(wind_str .. " " .. math.floor(math.abs(state.wind)), 20, 50)

    -- HUD
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Hole: " .. state.current_hole .. "/" .. state.total_holes, 20, 75)
    lurek.render.print("Strokes: " .. state.hole_strokes, 20, 95)
    lurek.render.print("Total: " .. state.strokes, 20, 115)

    -- distance to hole
    if hole and not state.hole_complete then
        local dist = math.floor(math.abs(ball.x - hole.x))
        lurek.render.print("Distance: " .. dist .. "px", 20, 135)
    end

    -- message
    if state.message ~= "" and (state.hole_complete or state.game_over) then
        lurek.render.setColor(1, 1, 0.3, 1)
        lurek.render.print(state.message, W / 2 - 100, H / 2 - 20, 1.5)
    end

    -- controls
    lurek.render.setColor(0.6, 0.6, 0.6, 0.6)
    lurek.render.print("Aim: Mouse | Power: Hold Space | R: Restart", 200, H - 25)
    lurek.render.print("FPS: " .. lurek.time.getFPS(), W - 80, 10)
end
