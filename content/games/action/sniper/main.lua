--[[
  Sniper — Ballistics Puzzle Sniper Game
  Category: action
  A side-view shooting range with scope sway, wind, bullet drop,
  and three rounds of escalating difficulty.
]]

-- Action inputs
lurek.input.bindAction("aim_up", {"w", "up"})
lurek.input.bindAction("aim_down", {"s", "down"})
lurek.input.bindAction("aim_left", {"a", "left"})
lurek.input.bindAction("aim_right", {"d", "right"})
lurek.input.bindAction("fire", {"space"})
lurek.input.bindAction("hold_breath", {"lshift", "rshift"})
lurek.input.bindAction("quit", {"escape"})
lurek.input.bindAction("start", {"return"})

-- Constants
local W, H = 800, 600
local AIM_SPEED = 120
local SWAY_AMP = 8
local SWAY_FREQ = 1.2
local BREATH_SWAY_AMP = 1.5
local BREATH_DURATION = 3.0
local BULLET_SPEED = 900
local GRAVITY = 220
local SCOPE_MIN_X, SCOPE_MAX_X = 100, 750
local SCOPE_MIN_Y, SCOPE_MAX_Y = 60, 500

-- States
local STATE_TITLE = "TITLE"
local STATE_AIMING = "AIMING"
local STATE_BULLET_FLIGHT = "BULLET_FLIGHT"
local STATE_ROUND_END = "ROUND_END"
local STATE_GAME_OVER = "GAME_OVER"

-- Game state
local state = STATE_TITLE
local scope_x, scope_y = 200, 300
local sway_time = 0
local breath_held = false
local breath_timer = 0
local breath_available = true
local breath_cooldown = 0

local bullet = nil -- {x, y, vx, vy, trail={}}
local wind = 0     -- px/s lateral
local wind_display = ""

local current_round = 1
local shots_left = 5
local round_score = 0
local round_hits = 0
local total_score = 0
local total_shots_fired = 0
local total_hits = 0

local targets = {}
local score_popup = nil -- {text, x, y, alpha}

-- Particle lists
local particles = {}

-- Round definitions
local round_defs = {
    {
        name = "Round 1 — Close Range",
        wind_min = 0, wind_max = 0,
        dist_min = 200, dist_max = 350,
        moving = 0, target_count = 5,
    },
    {
        name = "Round 2 — Medium Range",
        wind_min = -40, wind_max = 40,
        dist_min = 300, dist_max = 480,
        moving = 0, target_count = 5,
    },
    {
        name = "Round 3 — Long Range",
        wind_min = -80, wind_max = 80,
        dist_min = 400, dist_max = 600,
        moving = 3, target_count = 5,
    },
}

-- Terrain hills (green rectangles approximating rolling hills)
local hills = {
    {x = 0, y = 520, w = 200, h = 80},
    {x = 180, y = 530, w = 160, h = 70},
    {x = 320, y = 510, w = 200, h = 90},
    {x = 500, y = 525, w = 180, h = 75},
    {x = 660, y = 515, w = 140, h = 85},
}
local ground = {x = 0, y = 550, w = 800, h = 50}

-- Target current index
local current_target_idx = 1

--------------------------------------------------------------
-- Helpers
--------------------------------------------------------------
local function rand_range(lo, hi)
    return lo + math.random() * (hi - lo)
end

local function generate_wind(rdef)
    wind = rand_range(rdef.wind_min, rdef.wind_max)
    if math.abs(wind) < 5 then
        wind_display = "Calm"
    elseif wind > 0 then
        wind_display = string.format("Wind >>> %.0f", math.abs(wind))
    else
        wind_display = string.format("%.0f <<< Wind", math.abs(wind))
    end
end

local function spawn_targets(rdef)
    targets = {}
    current_target_idx = 1
    for i = 1, rdef.target_count do
        local tx = rand_range(rdef.dist_min, rdef.dist_max)
        local ty = rand_range(180, 460)
        local moving = i <= rdef.moving
        local move_speed = 0
        local move_range = 0
        if moving then
            move_speed = rand_range(30, 60)
            move_range = rand_range(40, 80)
        end
        targets[i] = {
            x = tx, y = ty,
            base_y = ty,
            alive = true,
            radius = 28,
            moving = moving,
            move_speed = move_speed,
            move_range = move_range,
            move_time = math.random() * 6.28,
        }
    end
end

local function start_round(rnum)
    current_round = rnum
    local rdef = round_defs[rnum]
    shots_left = 5
    round_score = 0
    round_hits = 0
    generate_wind(rdef)
    spawn_targets(rdef)
    scope_x = 200
    scope_y = 300
    breath_available = true
    breath_timer = 0
    breath_held = false
    breath_cooldown = 0
    bullet = nil
    particles = {}
    score_popup = nil
    state = STATE_AIMING
end

local function spawn_particles(px, py, color, count, speed, life)
    for i = 1, count do
        local angle = math.random() * 6.28
        local spd = speed * (0.5 + math.random() * 0.5)
        table.insert(particles, {
            x = px, y = py,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = life * (0.6 + math.random() * 0.4),
            max_life = life,
            color = color,
            size = 2 + math.random() * 3,
        })
    end
end

local function fire_bullet()
    if shots_left <= 0 then return end
    shots_left = shots_left - 1
    total_shots_fired = total_shots_fired + 1

    local target = targets[current_target_idx]
    if not target then return end

    local start_x = 40
    local start_y = scope_y
    local dx = scope_x - start_x
    local dy = scope_y - start_y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1 then dist = 1 end

    bullet = {
        x = start_x,
        y = start_y,
        vx = BULLET_SPEED * (dx / dist),
        vy = BULLET_SPEED * (dy / dist),
        trail = {{x = start_x, y = start_y}},
        target_idx = current_target_idx,
    }

    -- Muzzle flash particles
    spawn_particles(start_x + 10, start_y, {1, 0.9, 0.3, 1}, 12, 100, 0.3)

    state = STATE_BULLET_FLIGHT
end

local function score_hit(target, bx, by)
    local dx = bx - target.x
    local dy = by - target.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local r = target.radius

    local points = 0
    local label = "MISS"
    if dist <= r * 0.3 then
        points = 100
        label = "BULLSEYE!"
    elseif dist <= r * 0.65 then
        points = 70
        label = "INNER"
    elseif dist <= r then
        points = 40
        label = "OUTER"
    end

    if points > 0 then
        target.alive = false
        round_hits = round_hits + 1
        total_hits = total_hits + 1
        -- Hit burst particles
        spawn_particles(target.x, target.y, {1, 0.2, 0.1, 1}, 18, 120, 0.5)
    else
        -- Dust impact particles
        spawn_particles(bx, by, {0.7, 0.6, 0.4, 1}, 8, 60, 0.4)
    end

    round_score = round_score + points
    total_score = total_score + points

    -- Score popup tween
    score_popup = {text = label .. " +" .. points, x = bx, y = by - 20, alpha = 1.0}

    return points
end

local function advance_target()
    for i = current_target_idx + 1, #targets do
        if targets[i].alive then
            current_target_idx = i
            generate_wind(round_defs[current_round])
            return true
        end
    end
    -- No more alive targets
    return false
end

local function check_round_end()
    if shots_left <= 0 or not advance_target() then
        state = STATE_ROUND_END
    else
        state = STATE_AIMING
    end
end

local function get_rating(score)
    if score >= 1200 then return "LEGENDARY MARKSMAN"
    elseif score >= 900 then return "SHARPSHOOTER"
    elseif score >= 600 then return "MARKSMAN"
    elseif score >= 300 then return "NOVICE"
    else return "RECRUIT"
    end
end

--------------------------------------------------------------
-- Engine callbacks
--------------------------------------------------------------
lurek.init(function()
    lurek.window.setTitle("Sniper — Lurek2D")
    lurek.setBackgroundColor(0.3, 0.35, 0.25)
    lurek.showFPS(true)
    math.randomseed(os.time())
end)

lurek.ready(function()
    -- Ready
end)

lurek.process(function(dt)
    if lurek.input.isActionPressed("quit") then
        lurek.event.quit()
        return
    end

    sway_time = sway_time + dt

    -- Update particles
    local alive_particles = {}
    for _, p in ipairs(particles) do
        p.life = p.life - dt
        if p.life > 0 then
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + 100 * dt -- particle gravity
            p.size = p.size * 0.97
            table.insert(alive_particles, p)
        end
    end
    particles = alive_particles

    -- Score popup fade
    if score_popup then
        score_popup.alpha = score_popup.alpha - dt * 1.2
        score_popup.y = score_popup.y - 40 * dt
        if score_popup.alpha <= 0 then
            score_popup = nil
        end
    end

    if state == STATE_TITLE then
        if lurek.input.isActionPressed("start") then
            total_score = 0
            total_shots_fired = 0
            total_hits = 0
            start_round(1)
        end

    elseif state == STATE_AIMING then
        -- Breath holding
        if lurek.input.isActionDown("hold_breath") and breath_available then
            breath_held = true
            breath_timer = breath_timer + dt
            if breath_timer >= BREATH_DURATION then
                breath_held = false
                breath_available = false
                breath_cooldown = 2.0
                breath_timer = 0
            end
        else
            breath_held = false
            if not breath_available then
                breath_cooldown = breath_cooldown - dt
                if breath_cooldown <= 0 then
                    breath_available = true
                    breath_timer = 0
                end
            end
        end

        -- Scope movement
        local aim_dx, aim_dy = 0, 0
        if lurek.input.isActionDown("aim_up") then aim_dy = -1 end
        if lurek.input.isActionDown("aim_down") then aim_dy = 1 end
        if lurek.input.isActionDown("aim_left") then aim_dx = -1 end
        if lurek.input.isActionDown("aim_right") then aim_dx = 1 end

        scope_x = scope_x + aim_dx * AIM_SPEED * dt
        scope_y = scope_y + aim_dy * AIM_SPEED * dt

        -- Sway
        local sway_amp = breath_held and BREATH_SWAY_AMP or SWAY_AMP
        local sway_offset_x = math.sin(sway_time * SWAY_FREQ * 2 * math.pi) * sway_amp
        local sway_offset_y = math.cos(sway_time * SWAY_FREQ * 1.4 * 2 * math.pi) * sway_amp * 0.6

        scope_x = math.max(SCOPE_MIN_X, math.min(SCOPE_MAX_X, scope_x))
        scope_y = math.max(SCOPE_MIN_Y, math.min(SCOPE_MAX_Y, scope_y))

        -- Effective scope position with sway
        scope_x = scope_x + sway_offset_x * dt * 10
        scope_y = scope_y + sway_offset_y * dt * 10

        -- Fire
        if lurek.input.isActionPressed("fire") then
            fire_bullet()
        end

        -- Update moving targets
        for _, t in ipairs(targets) do
            if t.moving and t.alive then
                t.move_time = t.move_time + dt
                t.y = t.base_y + math.sin(t.move_time * t.move_speed * 0.05) * t.move_range
            end
        end

    elseif state == STATE_BULLET_FLIGHT then
        if bullet then
            -- Apply wind and gravity
            bullet.vx = bullet.vx + wind * dt * 0.5
            bullet.vy = bullet.vy + GRAVITY * dt

            bullet.x = bullet.x + bullet.vx * dt
            bullet.y = bullet.y + bullet.vy * dt

            -- Trail
            table.insert(bullet.trail, {x = bullet.x, y = bullet.y})

            -- Check hit on target
            local target = targets[bullet.target_idx]
            if target and target.alive then
                local dx = bullet.x - target.x
                local dy = bullet.y - target.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist <= target.radius + 5 then
                    score_hit(target, bullet.x, bullet.y)
                    bullet = nil
                    check_round_end()
                    return
                end
            end

            -- Off screen
            if bullet.x > W + 50 or bullet.y > H + 50 or bullet.x < -50 or bullet.y < -50 then
                -- Miss — dust at last position
                spawn_particles(bullet.trail[#bullet.trail].x, bullet.trail[#bullet.trail].y,
                    {0.6, 0.5, 0.3, 1}, 6, 40, 0.3)
                score_hit(target or {x = -999, y = -999, radius = 0, alive = false}, bullet.x, bullet.y)
                bullet = nil
                check_round_end()
            end
        end

        -- Update moving targets during flight
        for _, t in ipairs(targets) do
            if t.moving and t.alive then
                t.move_time = t.move_time + dt
                t.y = t.base_y + math.sin(t.move_time * t.move_speed * 0.05) * t.move_range
            end
        end

    elseif state == STATE_ROUND_END then
        if lurek.input.isActionPressed("start") then
            if current_round < 3 then
                start_round(current_round + 1)
            else
                state = STATE_GAME_OVER
            end
        end

    elseif state == STATE_GAME_OVER then
        if lurek.input.isActionPressed("start") then
            state = STATE_TITLE
        end
    end
end)

--------------------------------------------------------------
-- Render: terrain, targets, bullet, trail, scope
--------------------------------------------------------------
lurek.render(function()
    -- Ground
    lurek.render.drawRect(ground.x, ground.y, ground.w, ground.h, {0.25, 0.35, 0.15, 1})

    -- Hills
    for _, h in ipairs(hills) do
        lurek.render.drawRect(h.x, h.y, h.w, h.h, {0.3, 0.45, 0.2, 1})
    end

    if state == STATE_TITLE or state == STATE_GAME_OVER then
        return
    end

    -- Targets
    for _, t in ipairs(targets) do
        if t.alive then
            -- Outer ring (white)
            lurek.render.drawCircle(t.x, t.y, t.radius, {1, 1, 1, 1})
            -- Middle ring (blue)
            lurek.render.drawCircle(t.x, t.y, t.radius * 0.65, {0.2, 0.4, 0.9, 1})
            -- Bullseye (red)
            lurek.render.drawCircle(t.x, t.y, t.radius * 0.3, {0.9, 0.15, 0.1, 1})
        end
    end

    -- Bullet trail
    if bullet and #bullet.trail > 1 then
        for i = 2, #bullet.trail do
            local a = bullet.trail[i - 1]
            local b = bullet.trail[i]
            local alpha = i / #bullet.trail
            lurek.render.drawLine(a.x, a.y, b.x, b.y, {1, 0.85, 0.3, alpha * 0.7})
        end
    end

    -- Bullet
    if bullet then
        lurek.render.drawCircle(bullet.x, bullet.y, 3, {1, 0.9, 0.2, 1})
    end

    -- Particles
    for _, p in ipairs(particles) do
        local alpha = p.life / p.max_life
        local c = {p.color[1], p.color[2], p.color[3], alpha}
        lurek.render.drawCircle(p.x, p.y, p.size, c)
    end

    -- Scope crosshair (only when aiming)
    if state == STATE_AIMING then
        local ch_len = 18
        local ch_color = {0.1, 1, 0.2, 0.85}
        -- Horizontal
        lurek.render.drawLine(scope_x - ch_len, scope_y, scope_x + ch_len, scope_y, ch_color)
        -- Vertical
        lurek.render.drawLine(scope_x, scope_y - ch_len, scope_x, scope_y + ch_len, ch_color)
        -- Center dot
        lurek.render.drawCircle(scope_x, scope_y, 2, {1, 0.2, 0.2, 0.9})
    end
end)

--------------------------------------------------------------
-- Render UI: HUD, wind, score, round info, title/game over
--------------------------------------------------------------
lurek.render_ui(function()
    if state == STATE_TITLE then
        lurek.render.drawText("SNIPER", W / 2 - 80, H / 2 - 60, 48, {0.9, 0.85, 0.7, 1})
        lurek.render.drawText("Ballistics Puzzle", W / 2 - 70, H / 2, 18, {0.7, 0.7, 0.6, 1})
        local blink = math.abs(math.sin(sway_time * 2))
        lurek.render.drawText("PRESS ENTER", W / 2 - 55, H / 2 + 60, 16, {1, 1, 1, blink})
        return
    end

    if state == STATE_GAME_OVER then
        lurek.render.drawText("FINAL SCORE: " .. total_score, W / 2 - 90, H / 2 - 80, 28, {1, 0.9, 0.3, 1})
        local rating = get_rating(total_score)
        lurek.render.drawText("Rating: " .. rating, W / 2 - 80, H / 2 - 30, 22, {1, 1, 1, 1})
        local acc = 0
        if total_shots_fired > 0 then
            acc = math.floor(total_hits / total_shots_fired * 100)
        end
        lurek.render.drawText("Accuracy: " .. acc .. "%", W / 2 - 50, H / 2 + 10, 18, {0.8, 0.8, 0.8, 1})
        lurek.render.drawText("Shots: " .. total_shots_fired .. "  Hits: " .. total_hits,
            W / 2 - 70, H / 2 + 40, 16, {0.7, 0.7, 0.7, 1})
        local blink = math.abs(math.sin(sway_time * 2))
        lurek.render.drawText("PRESS ENTER TO RESTART", W / 2 - 95, H / 2 + 90, 16, {1, 1, 1, blink})
        return
    end

    if state == STATE_ROUND_END then
        local rdef = round_defs[current_round]
        lurek.render.drawText(rdef.name .. " Complete!", W / 2 - 100, H / 2 - 60, 22, {1, 0.9, 0.4, 1})
        lurek.render.drawText("Round Score: " .. round_score, W / 2 - 65, H / 2 - 20, 20, {1, 1, 1, 1})
        local acc = 0
        local fired = 5 - shots_left
        if fired > 0 then
            acc = math.floor(round_hits / fired * 100)
        end
        lurek.render.drawText("Accuracy: " .. acc .. "%", W / 2 - 50, H / 2 + 15, 18, {0.8, 0.8, 0.8, 1})
        if current_round < 3 then
            lurek.render.drawText("PRESS ENTER FOR NEXT ROUND", W / 2 - 110, H / 2 + 60, 16, {1, 1, 1, 1})
        else
            lurek.render.drawText("PRESS ENTER FOR RESULTS", W / 2 - 100, H / 2 + 60, 16, {1, 1, 1, 1})
        end
        return
    end

    -- HUD — Aiming / Bullet Flight
    local rdef = round_defs[current_round]

    -- Round & shots
    lurek.render.drawText(rdef.name, 10, 10, 16, {1, 1, 1, 0.9})
    lurek.render.drawText("Shots: " .. shots_left, 10, 32, 14, {0.9, 0.9, 0.8, 1})
    lurek.render.drawText("Score: " .. round_score, 10, 50, 14, {1, 0.9, 0.3, 1})
    lurek.render.drawText("Total: " .. total_score, 10, 68, 14, {0.8, 0.8, 0.7, 1})

    -- Wind indicator
    lurek.render.drawText(wind_display, W / 2 - 60, 10, 16, {0.6, 0.85, 1, 1})
    -- Wind arrow
    local arrow_cx = W / 2
    local arrow_cy = 38
    local arrow_len = math.min(math.abs(wind), 80)
    if math.abs(wind) > 2 then
        local dir = wind > 0 and 1 or -1
        local ax = arrow_cx + dir * arrow_len
        lurek.render.drawLine(arrow_cx - dir * arrow_len, arrow_cy, ax, arrow_cy, {0.6, 0.85, 1, 0.9})
        -- Arrowhead
        lurek.render.drawLine(ax, arrow_cy, ax - dir * 8, arrow_cy - 5, {0.6, 0.85, 1, 0.9})
        lurek.render.drawLine(ax, arrow_cy, ax - dir * 8, arrow_cy + 5, {0.6, 0.85, 1, 0.9})
    end

    -- Breath indicator
    if breath_held then
        local pct = 1.0 - (breath_timer / BREATH_DURATION)
        lurek.render.drawRect(W - 120, 10, 100 * pct, 10, {0.3, 0.9, 0.4, 0.8})
        lurek.render.drawText("HOLDING BREATH", W - 120, 24, 12, {0.3, 0.9, 0.4, 1})
    elseif not breath_available then
        lurek.render.drawText("Recovering...", W - 110, 10, 12, {0.8, 0.4, 0.3, 1})
    else
        lurek.render.drawText("[Shift] Hold Breath", W - 130, 10, 12, {0.7, 0.7, 0.6, 0.7})
    end

    -- Target distance hint
    local ct = targets[current_target_idx]
    if ct and ct.alive then
        local d = math.floor(ct.x)
        lurek.render.drawText("Range: " .. d .. "px", W - 130, H - 30, 14, {0.8, 0.8, 0.7, 0.8})
    end

    -- Score popup
    if score_popup then
        local c = {1, 1, 0.5, score_popup.alpha}
        lurek.render.drawText(score_popup.text, score_popup.x - 30, score_popup.y, 18, c)
    end
end)
