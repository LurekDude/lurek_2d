-- 2D Sniper / Ballistics Puzzle
-- Side-view long-distance shooting. Scope sways, wind drifts bullets.
-- Click to shoot. Hold Shift to steady aim. 5 shots per round, 3 rounds.

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local W, H = 800, 600

local scope = {}
local targets = {}
local bullet = {}
local bullet_trail = {}
local state = {}
local terrain_pts = {}

local ROUND_CONFIGS = {
    { wind = 30,  dist_min = 300, dist_max = 500, target_count = 3 },
    { wind = 60,  dist_min = 350, dist_max = 600, target_count = 4 },
    { wind = 100, dist_min = 400, dist_max = 700, target_count = 5 },
}

local function generate_terrain()
    terrain_pts = {}
    for i = 0, 80 do
        local x = i * (W / 80)
        local y = H - 60 + math.sin(i * 0.2) * 15 + math.sin(i * 0.5) * 8
        terrain_pts[i + 1] = { x = x, y = y }
    end
end

local function terrain_y_at(px)
    for i = 1, #terrain_pts - 1 do
        local a, b = terrain_pts[i], terrain_pts[i + 1]
        if px >= a.x and px <= b.x then
            local t = (px - a.x) / (b.x - a.x)
            return lerp(a.y, b.y, t)
        end
    end
    return H - 60
end

local function make_target(x_min, x_max)
    local tx = math.random(math.floor(x_min), math.floor(x_max))
    local ty = terrain_y_at(tx)
    local body_h = math.random(30, 45)
    local head_r = 7
    return {
        x = tx,
        y = ty,
        body_w = 12,
        body_h = body_h,
        head_r = head_r,
        head_y = ty - body_h - head_r,
        hit = false,
        headshot = false,
    }
end

local function setup_round(round_num)
    local cfg = ROUND_CONFIGS[round_num]
    state.wind = (math.random() - 0.5) * 2 * cfg.wind
    state.shots_left = 5
    state.round = round_num
    bullet.active = false
    bullet_trail = {}
    targets = {}
    for i = 1, cfg.target_count do
        local spread = (cfg.dist_max - cfg.dist_min) / cfg.target_count
        targets[i] = make_target(cfg.dist_min + (i - 1) * spread, cfg.dist_min + i * spread)
    end
end

function luna.load()
    generate_terrain()
    scope = {
        x = W / 2, y = H / 2,
        sway_phase = 0,
        sway_amp = 30,
        zoom = 3,
        radius = 60,
    }
    state.round = 1
    state.total_rounds = 3
    state.score = 0
    state.phase = "aiming" -- aiming / flying / round_end / game_over
    state.message = ""
    state.message_timer = 0
    state.breath_phase = 0
    bullet = { active = false, x = 0, y = 0, vx = 0, vy = 0 }
    bullet_trail = {}
    setup_round(1)
end

function luna.update(dt)
    -- breath / sway
    state.breath_phase = state.breath_phase + dt * 2.5
    scope.sway_phase = scope.sway_phase + dt * 1.8

    local base_amp = 30
    if luna.keyboard.isDown("lshift") or luna.keyboard.isDown("rshift") then
        base_amp = 8 -- steady aim
    end
    scope.sway_amp = lerp(scope.sway_amp, base_amp, dt * 4)

    -- scope follows mouse with sway
    local mx, my = luna.mouse.getPosition()
    local sway_x = math.sin(scope.sway_phase) * scope.sway_amp
    local sway_y = math.cos(scope.sway_phase * 0.7 + 1) * scope.sway_amp * 0.6
    scope.x = mx + sway_x
    scope.y = my + sway_y

    -- message timer
    if state.message_timer > 0 then state.message_timer = state.message_timer - dt end

    -- bullet physics
    if bullet.active then
        local gravity = 80
        bullet.vy = bullet.vy + gravity * dt
        bullet.vx = bullet.vx + state.wind * 0.5 * dt
        bullet.x = bullet.x + bullet.vx * dt
        bullet.y = bullet.y + bullet.vy * dt

        -- trail
        bullet_trail[#bullet_trail + 1] = { x = bullet.x, y = bullet.y }
        if #bullet_trail > 200 then table.remove(bullet_trail, 1) end

        -- hit terrain
        local gy = terrain_y_at(bullet.x)
        if bullet.y >= gy or bullet.x > W + 50 or bullet.x < -50 then
            bullet.active = false
            state.phase = "aiming"
            if state.shots_left <= 0 then
                check_round_end()
            end
        end

        -- hit targets
        for _, tgt in ipairs(targets) do
            if not tgt.hit then
                -- headshot check
                local hdx = bullet.x - tgt.x
                local hdy = bullet.y - tgt.head_y
                if math.sqrt(hdx * hdx + hdy * hdy) < tgt.head_r + 2 then
                    tgt.hit = true
                    tgt.headshot = true
                    state.score = state.score + 100
                    state.message = "HEADSHOT! +100"
                    state.message_timer = 2
                    bullet.active = false
                    state.phase = "aiming"
                    if state.shots_left <= 0 then check_round_end() end
                -- body check
                elseif bullet.x >= tgt.x - tgt.body_w / 2 and bullet.x <= tgt.x + tgt.body_w / 2 and
                    bullet.y >= tgt.y - tgt.body_h and bullet.y <= tgt.y then
                    tgt.hit = true
                    state.score = state.score + 50
                    state.message = "Hit! +50"
                    state.message_timer = 2
                    bullet.active = false
                    state.phase = "aiming"
                    if state.shots_left <= 0 then check_round_end() end
                end
            end
        end
    end
end

function check_round_end()
    -- all targets hit or no shots left
    local all_hit = true
    for _, t in ipairs(targets) do if not t.hit then all_hit = false end end
    if all_hit or state.shots_left <= 0 then
        if state.round >= state.total_rounds then
            state.phase = "game_over"
            state.message = "Final Score: " .. state.score
        else
            state.phase = "round_end"
            state.message = "Round " .. state.round .. " complete! Score: " .. state.score
            state.message_timer = 3
        end
    end
end

function luna.mousepressed(x, y, button)
    if state.phase == "aiming" and state.shots_left > 0 and not bullet.active then
        -- shoot from left edge toward scope position
        local start_x = 30
        local start_y = H - 100
        local dx = scope.x - start_x
        local dy = scope.y - start_y
        local dist = math.sqrt(dx * dx + dy * dy)
        local speed = 600
        bullet.x = start_x
        bullet.y = start_y
        bullet.vx = (dx / dist) * speed
        bullet.vy = (dy / dist) * speed
        bullet.active = true
        bullet_trail = {}
        state.shots_left = state.shots_left - 1
        state.phase = "flying"
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" then luna.load() end
    if key == "return" or key == "space" then
        if state.phase == "round_end" then
            setup_round(state.round + 1)
            state.phase = "aiming"
        end
        if state.phase == "game_over" then
            luna.load()
        end
    end
end

function luna.draw()
    luna.graphics.setBackgroundColor(0.55, 0.75, 0.9)

    -- sky gradient
    for i = 0, 5 do
        local t = i / 5
        luna.graphics.setColor(0.45 + t * 0.15, 0.65 + t * 0.1, 0.85 + t * 0.05, 1)
        luna.graphics.rectangle("fill", 0, i * 60, W, 60)
    end

    -- distant mountains
    luna.graphics.setColor(0.35, 0.45, 0.55, 0.5)
    for i = 0, 20 do
        local x = i * 40
        local mh = 80 + math.sin(i * 0.8) * 40
        luna.graphics.polygon("fill", { x, H - 100 - mh, x + 20, H - 100 - mh - 30, x + 40, H - 100 - mh, x + 40, H - 60, x, H - 60 })
    end

    -- terrain fill
    luna.graphics.setColor(0.25, 0.45, 0.2, 1)
    for i = 1, #terrain_pts - 1 do
        local a, b = terrain_pts[i], terrain_pts[i + 1]
        luna.graphics.polygon("fill", { a.x, a.y, b.x, b.y, b.x, H, a.x, H })
    end
    luna.graphics.setColor(0.35, 0.55, 0.3, 1)
    luna.graphics.setLineWidth(2)
    for i = 1, #terrain_pts - 1 do
        luna.graphics.line(terrain_pts[i].x, terrain_pts[i].y, terrain_pts[i + 1].x, terrain_pts[i + 1].y)
    end

    -- targets
    for _, tgt in ipairs(targets) do
        if tgt.hit then
            luna.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        else
            -- body
            luna.graphics.setColor(0.6, 0.3, 0.2, 1)
        end
        luna.graphics.rectangle("fill", tgt.x - tgt.body_w / 2, tgt.y - tgt.body_h, tgt.body_w, tgt.body_h)
        -- head
        if tgt.hit and tgt.headshot then
            luna.graphics.setColor(1, 0.3, 0.1, 0.7)
        elseif tgt.hit then
            luna.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        else
            luna.graphics.setColor(0.8, 0.6, 0.5, 1)
        end
        luna.graphics.circle("fill", tgt.x, tgt.head_y, tgt.head_r)
        -- hit marker
        if tgt.hit then
            luna.graphics.setColor(1, 0, 0, 0.8)
            luna.graphics.setLineWidth(2)
            luna.graphics.line(tgt.x - 8, tgt.head_y - 8, tgt.x + 8, tgt.head_y + 8)
            luna.graphics.line(tgt.x + 8, tgt.head_y - 8, tgt.x - 8, tgt.head_y + 8)
        end
    end

    -- shooter position
    luna.graphics.setColor(0.2, 0.3, 0.2, 1)
    luna.graphics.rectangle("fill", 10, H - 110, 30, 50)
    luna.graphics.setColor(0.5, 0.5, 0.5, 1)
    luna.graphics.line(25, H - 100, 60, H - 95)

    -- bullet trail
    luna.graphics.setColor(1, 0.8, 0.2, 0.6)
    luna.graphics.setLineWidth(1)
    for i = 1, #bullet_trail - 1, 3 do
        local a, b = bullet_trail[i], bullet_trail[i + 1]
        if a and b then
            luna.graphics.setColor(1, 0.8, 0.2, 0.3 + (i / #bullet_trail) * 0.4)
            luna.graphics.circle("fill", a.x, a.y, 1.5)
        end
    end

    -- bullet
    if bullet.active then
        luna.graphics.setColor(1, 1, 0.3, 1)
        luna.graphics.circle("fill", bullet.x, bullet.y, 3)
    end

    -- scope overlay (zoomed circle)
    if state.phase == "aiming" then
        local sr = scope.radius
        -- scope ring
        luna.graphics.setColor(0, 0, 0, 0.15)
        luna.graphics.circle("fill", scope.x, scope.y, sr)
        luna.graphics.setColor(0.1, 0.1, 0.1, 0.8)
        luna.graphics.setLineWidth(2)
        luna.graphics.circle("line", scope.x, scope.y, sr)

        -- crosshair
        luna.graphics.setColor(1, 0.2, 0.2, 0.8)
        luna.graphics.setLineWidth(1)
        luna.graphics.line(scope.x - sr, scope.y, scope.x - 5, scope.y)
        luna.graphics.line(scope.x + 5, scope.y, scope.x + sr, scope.y)
        luna.graphics.line(scope.x, scope.y - sr, scope.x, scope.y - 5)
        luna.graphics.line(scope.x, scope.y + 5, scope.x, scope.y + sr)

        -- mil dots
        for i = 1, 3 do
            local offset = i * 15
            luna.graphics.circle("fill", scope.x, scope.y + offset, 2)
            luna.graphics.circle("fill", scope.x + offset, scope.y, 2)
            luna.graphics.circle("fill", scope.x - offset, scope.y, 2)
        end
    end

    -- HUD panel
    luna.graphics.setColor(0, 0, 0, 0.6)
    luna.graphics.rectangle("fill", 0, 0, W, 45)

    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Score: " .. state.score, 10, 5)
    luna.graphics.print("Round: " .. state.round .. "/" .. state.total_rounds, 10, 22)
    luna.graphics.print("Shots: " .. state.shots_left .. "/5", 180, 5)

    -- wind indicator
    luna.graphics.setColor(0.7, 0.9, 1, 1)
    local wind_label = "Wind: "
    if state.wind > 0 then wind_label = wind_label .. ">>> "
    elseif state.wind < 0 then wind_label = wind_label .. "<<< "
    else wind_label = wind_label .. "--- " end
    wind_label = wind_label .. math.floor(math.abs(state.wind))
    luna.graphics.print(wind_label, 180, 22)

    -- breath indicator
    local breath = math.sin(state.breath_phase) * 0.5 + 0.5
    luna.graphics.setColor(0.3, 0.3, 0.3, 0.7)
    luna.graphics.rectangle("fill", 380, 8, 80, 10)
    luna.graphics.setColor(0.2, 0.8, 0.3, 1)
    luna.graphics.rectangle("fill", 382, 10, 76 * breath, 6)
    luna.graphics.setColor(1, 1, 1, 0.8)
    luna.graphics.print("Breath", 380, 22)

    -- steady aim hint
    if luna.keyboard.isDown("lshift") or luna.keyboard.isDown("rshift") then
        luna.graphics.setColor(0.3, 1, 0.5, 1)
        luna.graphics.print("STEADY", 470, 8)
    else
        luna.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        luna.graphics.print("[Shift] Steady", 470, 8)
    end

    -- targets hit count
    local hit_count = 0
    for _, t in ipairs(targets) do if t.hit then hit_count = hit_count + 1 end end
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Targets: " .. hit_count .. "/" .. #targets, 600, 5)

    -- message
    if state.message_timer > 0 then
        local a = clamp(state.message_timer, 0, 1)
        luna.graphics.setColor(1, 1, 0.3, a)
        luna.graphics.print(state.message, W / 2 - 60, H / 2 - 40, 1.5)
    end

    -- round end / game over overlay
    if state.phase == "round_end" then
        luna.graphics.setColor(0, 0, 0, 0.5)
        luna.graphics.rectangle("fill", 0, H / 2 - 40, W, 80)
        luna.graphics.setColor(1, 1, 0.5, 1)
        luna.graphics.print("Round Complete! Score: " .. state.score, W / 2 - 100, H / 2 - 25, 1.3)
        luna.graphics.setColor(1, 1, 1, 0.8)
        luna.graphics.print("Press Enter for next round", W / 2 - 80, H / 2 + 15)
    end
    if state.phase == "game_over" then
        luna.graphics.setColor(0, 0, 0, 0.6)
        luna.graphics.rectangle("fill", 0, H / 2 - 50, W, 100)
        luna.graphics.setColor(1, 0.8, 0.2, 1)
        luna.graphics.print("FINAL SCORE: " .. state.score, W / 2 - 80, H / 2 - 35, 1.5)
        local headshots = 0
        for _, t in ipairs(targets) do if t.headshot then headshots = headshots + 1 end end
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("Headshots: " .. headshots .. "  |  Press Enter to play again", W / 2 - 120, H / 2 + 15)
    end

    luna.graphics.setColor(0.5, 0.5, 0.5, 0.4)
    luna.graphics.print("FPS: " .. luna.timer.getFPS(), W - 70, H - 18)
end
