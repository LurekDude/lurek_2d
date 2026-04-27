-- ============================================================================
-- Wildlife Photo — Lurek2D
-- ============================================================================
-- Category : simulation
-- Source   : content/games/simulation/wildlife_photo/main.lua
-- Run with : cargo run -- content/games/simulation/wildlife_photo
-- ============================================================================
-- Explore a scrolling landscape, frame wildlife in your viewfinder, and snap
-- photos to fill your species journal. Photograph all 8 (9 at night) species!
-- Controls: WASD pan camera, Space photo, Q/E zoom, Tab album, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local WORLD_W, WORLD_H = 2400, 600
local VIEWFINDER_W, VIEWFINDER_H = 200, 150

local STATES = { TITLE = 1, EXPLORING = 2, ALBUM = 3, COMPLETE = 4 }
local current_state = STATES.TITLE

local ZOOM_LEVELS = { 1, 2, 3 }
local ZOOM_NAMES  = { "Wide (1x)", "Medium (2x)", "Close (3x)" }
local ZOOM_MULT   = { 1, 1.5, 2 }

local DAY_CYCLE = 90 -- seconds for full dawn→day→dusk→night
local PATIENCE_THRESHOLD = 5 -- seconds of stillness
local MAX_FILM = 12
local FLEE_DIST = 150
local CAM_SPEED = 200

-- Time-of-day phases
local TOD_DAWN  = 1
local TOD_DAY   = 2
local TOD_DUSK  = 3
local TOD_NIGHT = 4
local TOD_NAMES = { "Dawn", "Day", "Dusk", "Night" }

-- Animal definitions
local ANIMAL_DEFS = {
    { name = "Deer",      rarity = 10, w = 30, h = 24, color = { 0.55, 0.35, 0.15, 1 }, shape = "rect",   flees = true,  sky = false, water = false, tod = { true, true, true, false } },
    { name = "Bird",      rarity = 12, w = 10, h =  8, color = { 0.30, 0.50, 0.90, 1 }, shape = "rect",   flees = false, sky = false, water = false, tod = { true, true, true, false } },
    { name = "Bear",      rarity = 20, w = 40, h = 32, color = { 0.40, 0.25, 0.10, 1 }, shape = "rect",   flees = false, sky = false, water = false, tod = { false, true, true, false } },
    { name = "Rabbit",    rarity =  8, w = 12, h = 10, color = { 0.60, 0.60, 0.60, 1 }, shape = "rect",   flees = true,  sky = false, water = false, tod = { true, true, true, false } },
    { name = "Fox",       rarity = 15, w = 22, h = 16, color = { 0.90, 0.50, 0.10, 1 }, shape = "rect",   flees = false, sky = false, water = false, tod = { true, true, true, false } },
    { name = "Eagle",     rarity = 25, w = 16, h = 16, color = { 0.25, 0.20, 0.15, 1 }, shape = "circle", flees = false, sky = true,  water = false, tod = { true, true, true, false } },
    { name = "Fish",      rarity =  7, w = 14, h =  8, color = { 0.20, 0.50, 0.85, 1 }, shape = "rect",   flees = false, sky = false, water = true,  tod = { true, true, true, true  } },
    { name = "Butterfly", rarity =  5, w =  6, h =  6, color = { 0.95, 0.40, 0.80, 1 }, shape = "rect",   flees = false, sky = false, water = false, tod = { true, true, false, false } },
    { name = "Owl",       rarity = 30, w = 16, h = 16, color = { 0.50, 0.45, 0.35, 1 }, shape = "circle", flees = false, sky = true,  water = false, tod = { false, false, false, true } },
}

-- Background colors per time-of-day
local TOD_BG = {
    { 0.55, 0.40, 0.30 }, -- dawn
    { 0.35, 0.60, 0.85 }, -- day
    { 0.45, 0.30, 0.25 }, -- dusk
    { 0.05, 0.05, 0.12 }, -- night
}

-- Water zone (bottom strip of world)
local WATER_Y = WORLD_H - 80
local SKY_MAX_Y = 120

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local cam_x = 0
local cam_y = 0
local zoom_index = 1
local zoom_display = 1 -- tweened
local tod_timer = 0
local tod_phase = TOD_DAWN
local bg_r, bg_g, bg_b = TOD_BG[1][1], TOD_BG[1][2], TOD_BG[1][3]

local animals = {}
local photos = {}       -- { species, score, zoom, tod }
local journal = {}      -- set of species names photographed
local film_remaining = MAX_FILM

local patience_timer = 0
local last_cam_x, last_cam_y = 0, 0

-- Particle systems
---@type LParticleSystem
local ps_flash    = nil
---@type LParticleSystem
local ps_leaves   = nil
---@type LParticleSystem
local ps_firefly  = nil
---@type LParticleSystem
local ps_footprint = nil

-- Camera object
---@type LCamera
local camera = nil

-- Score popup
local score_popup = { text = "", alpha = 0, y = 0 }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function dist(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

local function lerp(a, b, t) return a + (b - a) * t end

local function get_tod_phase(t)
    local frac = (t % DAY_CYCLE) / DAY_CYCLE
    if frac < 0.2 then return TOD_DAWN
    elseif frac < 0.5 then return TOD_DAY
    elseif frac < 0.7 then return TOD_DUSK
    else return TOD_NIGHT end
end

local function spawn_animal(def_index)
    local def = ANIMAL_DEFS[def_index]
    local a = {
        def_index = def_index,
        name = def.name,
        x = 0, y = 0,
        vx = 0, vy = 0,
        behavior = "wander",
        behavior_timer = math.random() * 3 + 1,
        feeding = false,
        feeding_timer = 0,
        visible = true,
    }
    if def.sky then
        a.x = math.random(50, WORLD_W - 50)
        a.y = math.random(30, SKY_MAX_Y)
    elseif def.water then
        a.x = math.random(50, WORLD_W - 50)
        a.y = WATER_Y + math.random(10, 50)
    else
        a.x = math.random(50, WORLD_W - 50)
        a.y = math.random(SKY_MAX_Y + 40, WATER_Y - 40)
    end
    return a
end

local function init_animals()
    animals = {}
    -- Spawn 2-3 of each ground/water type, 1-2 of each sky type
    for i, def in ipairs(ANIMAL_DEFS) do
        local count = (def.sky) and math.random(1, 2) or math.random(2, 3)
        for _ = 1, count do
            table.insert(animals, spawn_animal(i))
        end
    end
end

local function reset_game()
    cam_x = WORLD_W * 0.5 - SCREEN_W * 0.5
    cam_y = 0
    zoom_index = 1
    zoom_display = 1
    tod_timer = 0
    tod_phase = TOD_DAWN
    bg_r, bg_g, bg_b = TOD_BG[1][1], TOD_BG[1][2], TOD_BG[1][3]
    photos = {}
    journal = {}
    film_remaining = MAX_FILM
    patience_timer = 0
    last_cam_x = cam_x
    last_cam_y = cam_y
    score_popup = { text = "", alpha = 0, y = 0 }
    init_animals()
end

local function viewfinder_world_rect()
    local cx = cam_x + SCREEN_W * 0.5
    local cy = cam_y + SCREEN_H * 0.5
    local z = ZOOM_LEVELS[zoom_index]
    local vw = VIEWFINDER_W / z
    local vh = VIEWFINDER_H / z
    return cx - vw * 0.5, cy - vh * 0.5, vw, vh
end

local function animal_in_viewfinder(a)
    local vx, vy, vw, vh = viewfinder_world_rect()
    local def = ANIMAL_DEFS[a.def_index]
    return a.x + def.w > vx and a.x < vx + vw and a.y + def.h > vy and a.y < vy + vh
end

local function score_photo(a)
    local def = ANIMAL_DEFS[a.def_index]
    local base = def.rarity
    local z = ZOOM_LEVELS[zoom_index]
    -- Zoom bonus
    local zoom_bonus = z * 5
    -- Centering bonus: how close to viewfinder center
    local vx, vy, vw, vh = viewfinder_world_rect()
    local acx = a.x + def.w * 0.5
    local acy = a.y + def.h * 0.5
    local vcx = vx + vw * 0.5
    local vcy = vy + vh * 0.5
    local center_dist = dist(acx, acy, vcx, vcy)
    local max_dist = math.sqrt(vw * vw + vh * vh) * 0.5
    local center_bonus = math.floor((1 - clamp(center_dist / max_dist, 0, 1)) * 15)
    -- Feeding bonus
    local feed_bonus = a.feeding and 10 or 0
    return base + zoom_bonus + center_bonus + feed_bonus
end

local function take_photo()
    if film_remaining <= 0 then return end
    film_remaining = film_remaining - 1

    -- Flash
    local sx = SCREEN_W * 0.5
    local sy = SCREEN_H * 0.5
    ps_flash:moveTo(sx, sy)
    ps_flash:emit(30)

    -- Find best animal in viewfinder
    local best_animal = nil
    local best_score = 0
    for _, a in ipairs(animals) do
        if a.visible and animal_in_viewfinder(a) then
            local s = score_photo(a)
            if s > best_score then
                best_score = s
                best_animal = a
            end
        end
    end

    if best_animal then
        local entry = {
            species = best_animal.name,
            score = best_score,
            zoom = ZOOM_NAMES[zoom_index],
            tod = TOD_NAMES[tod_phase],
        }
        table.insert(photos, entry)
        journal[best_animal.name] = true

        -- Score popup tween
        score_popup.text = string.format("+%d  %s", best_score, best_animal.name)
        score_popup.alpha = 1
        score_popup.y = SCREEN_H * 0.35
        lurek.tween.to(score_popup, { alpha = 0, y = SCREEN_H * 0.25 }, 1.5)
    else
        score_popup.text = "Nothing captured..."
        score_popup.alpha = 1
        score_popup.y = SCREEN_H * 0.35
        lurek.tween.to(score_popup, { alpha = 0, y = SCREEN_H * 0.28 }, 1.2)
    end

    -- Check complete: all 8 daytime species
    local species_count = 0
    for _ in pairs(journal) do species_count = species_count + 1 end
    if species_count >= 8 then
        current_state = STATES.COMPLETE
    end
end

local function reload_film()
    film_remaining = MAX_FILM
    cam_x = math.random(0, WORLD_W - SCREEN_W)
    cam_y = 0
end

-- ---------------------------------------------------------------------------
-- Animal AI
-- ---------------------------------------------------------------------------
local function update_animal(a, dt)
    local def = ANIMAL_DEFS[a.def_index]

    -- Visibility by time of day
    a.visible = def.tod[tod_phase]
    if not a.visible then return end

    -- Patience: shy animals approach camera if player is still
    local player_wx = cam_x + SCREEN_W * 0.5
    local player_wy = cam_y + SCREEN_H * 0.5

    -- Flee behavior for shy animals
    if def.flees then
        local d = dist(a.x, a.y, player_wx, player_wy)
        if d < FLEE_DIST and patience_timer < PATIENCE_THRESHOLD then
            a.behavior = "flee"
            local dx = a.x - player_wx
            local dy = a.y - player_wy
            local len = math.max(1, math.sqrt(dx * dx + dy * dy))
            a.vx = (dx / len) * 100
            a.vy = (dy / len) * 60
            a.behavior_timer = 1.5
        end
    end

    a.behavior_timer = a.behavior_timer - dt
    if a.behavior_timer <= 0 then
        -- Pick new behavior
        local roll = math.random(100)
        if roll < 40 then
            a.behavior = "wander"
            a.behavior_timer = math.random() * 4 + 2
            local angle = math.random() * 6.28
            local spd = def.sky and 60 or (def.name == "Bear" and 20 or 40)
            if def.water then spd = 30 end
            a.vx = math.cos(angle) * spd
            a.vy = math.sin(angle) * spd * 0.3
        elseif roll < 65 then
            a.behavior = "idle"
            a.behavior_timer = math.random() * 3 + 1
            a.vx = 0
            a.vy = 0
        else
            a.behavior = "feeding"
            a.behavior_timer = math.random() * 4 + 2
            a.vx = 0
            a.vy = 0
            a.feeding = true
            a.feeding_timer = a.behavior_timer
        end
    end

    -- Update feeding
    if a.feeding then
        a.feeding_timer = a.feeding_timer - dt
        if a.feeding_timer <= 0 then a.feeding = false end
    end

    -- Patience attracting shy animals
    if def.flees and patience_timer >= PATIENCE_THRESHOLD and a.behavior ~= "flee" then
        local d = dist(a.x, a.y, player_wx, player_wy)
        if d > 200 and d < 500 then
            local dx = player_wx - a.x
            local dy = player_wy - a.y
            local len = math.max(1, math.sqrt(dx * dx + dy * dy))
            a.vx = (dx / len) * 25
            a.vy = (dy / len) * 15
        end
    end

    -- Bird arc flight
    if def.name == "Bird" then
        a.vy = math.sin(tod_timer * 2 + a.x * 0.1) * 20
    end

    -- Eagle soar
    if def.name == "Eagle" or def.name == "Owl" then
        a.vx = math.cos(tod_timer * 0.5 + a.y * 0.05) * 35
        a.vy = math.sin(tod_timer * 0.8 + a.x * 0.03) * 10
    end

    -- Fish swim pattern
    if def.water then
        a.vy = math.sin(tod_timer * 1.5 + a.x * 0.08) * 12
    end

    -- Move
    a.x = a.x + a.vx * dt
    a.y = a.y + a.vy * dt

    -- Clamp to valid zones
    if def.sky then
        a.y = clamp(a.y, 20, SKY_MAX_Y)
    elseif def.water then
        a.y = clamp(a.y, WATER_Y, WORLD_H - 20)
    else
        a.y = clamp(a.y, SKY_MAX_Y + 20, WATER_Y - 20)
    end
    a.x = clamp(a.x, 10, WORLD_W - 50)

    -- Footprint particles for ground animals
    if not def.sky and not def.water and (a.behavior == "wander" or a.behavior == "flee") then
        if math.random() < 0.05 then
            ps_footprint:moveTo(a.x + def.w * 0.5, a.y + def.h)
            ps_footprint:emit(1)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------

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
    lurek.window.setTitle("Wildlife Photo — Lurek2D")
    lurek.render.setBackgroundColor(bg_r, bg_g, bg_b)

    lurek.input.bind("move_up",    { "w" })
    lurek.input.bind("move_down",  { "s" })
    lurek.input.bind("move_left",  { "a" })
    lurek.input.bind("move_right", { "d" })
    lurek.input.bind("photo",      { "space" })
    lurek.input.bind("zoom_in",    { "e" })
    lurek.input.bind("zoom_out",   { "q" })
    lurek.input.bind("album",      { "tab" })
    lurek.input.bind("quit",       { "escape" })

    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Particle systems
    ps_flash = lurek.particle.newSystem({
        maxParticles = 60, emissionRate = 0, lifetimeMin = 0.15, lifetimeMax = 0.4,
        speedMin = 80, speedMax = 200, direction = 0, spread = 6.28,
        sizes = { 6, 3, 0 },
        colors = { 1, 1, 0.9, 1, 1, 1, 0.7, 0 },
    })
    ps_leaves = lurek.particle.newSystem({
        maxParticles = 40, emissionRate = 3, lifetimeMin = 2.0, lifetimeMax = 4.0,
        speedMin = 10, speedMax = 30, direction = 1.2, spread = 1.0,
        gravityY = 15, sizes = { 3, 2, 1 },
        colors = { 0.3, 0.6, 0.15, 0.6, 0.5, 0.7, 0.2, 0 },
    })
    ps_firefly = lurek.particle.newSystem({
        maxParticles = 30, emissionRate = 0, lifetimeMin = 1.5, lifetimeMax = 3.0,
        speedMin = 5, speedMax = 15, direction = -1.57, spread = 3.14,
        sizes = { 3, 4, 2, 0 },
        colors = { 0.9, 0.95, 0.3, 0.8, 0.7, 0.9, 0.2, 0 },
    })
    ps_footprint = lurek.particle.newSystem({
        maxParticles = 80, emissionRate = 0, lifetimeMin = 1.0, lifetimeMax = 2.5,
        speedMin = 0, speedMax = 2, direction = -1.57, spread = 0.3,
        sizes = { 2, 1, 0 },
        colors = { 0.35, 0.25, 0.15, 0.5, 0.3, 0.2, 0.1, 0 },
    })

    reset_game()
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    -- Quit / back
    if lurek.input.wasActionPressed("quit") then
        if current_state == STATES.ALBUM then
            current_state = STATES.EXPLORING
        else
            lurek.event.quit()
        end
        return
    end

    -- Title
    if current_state == STATES.TITLE then
        if lurek.input.wasActionPressed("photo") then
            current_state = STATES.EXPLORING
        end
        return
    end

    -- Complete
    if current_state == STATES.COMPLETE then
        if lurek.input.wasActionPressed("photo") then
            reset_game()
            current_state = STATES.EXPLORING
        end
        lurek.tween.update(dt)
        return
    end

    -- Album toggle
    if lurek.input.wasActionPressed("album") then
        if current_state == STATES.EXPLORING then
            current_state = STATES.ALBUM
        else
            current_state = STATES.EXPLORING
        end
    end

    if current_state == STATES.ALBUM then
        lurek.tween.update(dt)
        ps_flash:update(dt)
        return
    end

    -- ─── EXPLORING state ───

    -- Camera pan
    local moved = false
    if lurek.input.isActionDown("move_up")    then cam_y = cam_y - CAM_SPEED * dt; moved = true end
    if lurek.input.isActionDown("move_down")  then cam_y = cam_y + CAM_SPEED * dt; moved = true end
    if lurek.input.isActionDown("move_left")  then cam_x = cam_x - CAM_SPEED * dt; moved = true end
    if lurek.input.isActionDown("move_right") then cam_x = cam_x + CAM_SPEED * dt; moved = true end
    cam_x = clamp(cam_x, 0, WORLD_W - SCREEN_W)
    cam_y = clamp(cam_y, 0, WORLD_H - SCREEN_H)

    -- Patience meter
    if moved then
        patience_timer = 0
    else
        patience_timer = patience_timer + dt
    end
    last_cam_x = cam_x
    last_cam_y = cam_y

    -- Zoom
    if lurek.input.wasActionPressed("zoom_in") then
        zoom_index = math.min(#ZOOM_LEVELS, zoom_index + 1)
        lurek.tween.to(zoom_display, { [1] = ZOOM_LEVELS[zoom_index] }, 0.3)
    end
    if lurek.input.wasActionPressed("zoom_out") then
        zoom_index = math.max(1, zoom_index - 1)
        lurek.tween.to(zoom_display, { [1] = ZOOM_LEVELS[zoom_index] }, 0.3)
    end

    -- Take photo
    if lurek.input.wasActionPressed("photo") then
        take_photo()
    end

    -- Reload film
    if film_remaining <= 0 then
        if lurek.input.wasActionPressed("photo") then
            reload_film()
        end
    end

    -- Time of day
    tod_timer = tod_timer + dt
    local new_phase = get_tod_phase(tod_timer)
    if new_phase ~= tod_phase then
        tod_phase = new_phase
        local target_bg = TOD_BG[tod_phase]
        lurek.tween.to({ bg_r, bg_g, bg_b }, { target_bg[1], target_bg[2], target_bg[3] }, 3.0)
    end
    -- Smooth bg transition
    local target_bg = TOD_BG[tod_phase]
    bg_r = lerp(bg_r, target_bg[1], dt * 0.8)
    bg_g = lerp(bg_g, target_bg[2], dt * 0.8)
    bg_b = lerp(bg_b, target_bg[3], dt * 0.8)
    lurek.render.setBackgroundColor(bg_r, bg_g, bg_b)

    -- Update animals
    for _, a in ipairs(animals) do
        update_animal(a, dt)
    end

    -- Leaf particles from random tree positions
    ps_leaves:setPosition(cam_x + math.random(0, SCREEN_W), cam_y + SKY_MAX_Y + 20)

    -- Fireflies at night
    if tod_phase == TOD_NIGHT then
        ps_firefly:moveTo(cam_x + math.random(50, SCREEN_W - 50), cam_y + math.random(200, 500))
        ps_firefly:emit(1)
    end

    -- Update camera
    camera:setPosition(cam_x + SCREEN_W * 0.5, cam_y + SCREEN_H * 0.5)

    -- Update systems
    lurek.tween.update(dt)
    ps_flash:update(dt)
    ps_leaves:update(dt)
    ps_firefly:update(dt)
    ps_footprint:update(dt)
end

-- ---------------------------------------------------------------------------
-- Render (world)
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state == STATES.TITLE then return end
    if current_state == STATES.ALBUM then return end
    if current_state == STATES.COMPLETE then return end

    camera:attach()

    -- Sky gradient band
    rect(0, 0, WORLD_W, SKY_MAX_Y, {
        color = { bg_r * 0.8, bg_g * 0.9, bg_b * 1.1, 0.3 },
    })

    -- Ground
    rect(0, SKY_MAX_Y, WORLD_W, WATER_Y - SKY_MAX_Y, {
        color = { 0.25, 0.50, 0.18, 1 },
    })

    -- Trees (decorative)
    for i = 0, 15 do
        local tx = 80 + i * 150
        local ty = SKY_MAX_Y - 10
        -- Trunk
        rect(tx - 4, ty, 8, 40, { color = { 0.35, 0.22, 0.10, 1 } })
        -- Canopy
        circ(tx, ty, 20, { color = { 0.18, 0.45, 0.12, 1 } })
    end

    -- Bushes
    for i = 0, 20 do
        local bx = 40 + i * 110
        local by = math.random(200, 440)
        circ(bx, by, 10, { color = { 0.22, 0.48, 0.15, 0.7 } })
    end

    -- Water zone
    rect(0, WATER_Y, WORLD_W, WORLD_H - WATER_Y, {
        color = { 0.10, 0.30, 0.60, 0.8 },
    })
    -- Water ripples
    for i = 0, 8 do
        local rx = 100 + i * 280
        local ry = WATER_Y + 20 + math.sin(tod_timer + i) * 8
        rect(rx, ry, 40, 2, { color = { 0.3, 0.5, 0.8, 0.4 } })
    end

    -- Draw animals
    for _, a in ipairs(animals) do
        if a.visible then
            local def = ANIMAL_DEFS[a.def_index]
            if def.shape == "circle" then
                circ(a.x + def.w * 0.5, a.y + def.h * 0.5, def.w * 0.5, {
                    color = def.color,
                })
            else
                rect(a.x, a.y, def.w, def.h, {
                    color = def.color,
                })
            end
            -- Feeding indicator (small sparkle)
            if a.feeding then
                circ(a.x + def.w * 0.5, a.y - 6, 3, {
                    color = { 1, 0.9, 0.3, 0.7 + math.sin(tod_timer * 8) * 0.3 },
                })
            end
        end
    end

    -- Particles (world-space)
    ps_leaves:render()
    ps_firefly:render()
    ps_footprint:render()

    -- Night overlay
    if tod_phase == TOD_NIGHT then
        rect(cam_x, cam_y, SCREEN_W, SCREEN_H, {
            color = { 0.02, 0.02, 0.10, 0.35 },
        })
    elseif tod_phase == TOD_DUSK then
        rect(cam_x, cam_y, SCREEN_W, SCREEN_H, {
            color = { 0.4, 0.15, 0.05, 0.12 },
        })
    elseif tod_phase == TOD_DAWN then
        rect(cam_x, cam_y, SCREEN_W, SCREEN_H, {
            color = { 0.5, 0.3, 0.15, 0.08 },
        })
    end

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI (HUD overlay)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    local W, H = SCREEN_W, SCREEN_H

    -- ─── TITLE ───
    if current_state == STATES.TITLE then
        rect(0, 0, W, H, { color = { 0.05, 0.12, 0.08, 1 } })
        text_("WILDLIFE PHOTO", 200, 180, { size = 42, color = { 0.85, 0.95, 0.70, 1 } })
        text_("CAPTURE THE WILD", 250, 240, { size = 20, color = { 0.55, 0.75, 0.45, 1 } })
        text_("Press SPACE to begin", 290, 340, { size = 16, color = { 0.5, 0.5, 0.5, 1 } })
        text_("WASD pan  |  SPACE photo  |  Q/E zoom  |  TAB album", 135, 400, { size = 12, color = { 0.4, 0.4, 0.4, 1 } })
        return
    end

    -- ─── COMPLETE ───
    if current_state == STATES.COMPLETE then
        rect(0, 0, W, H, { color = { 0.02, 0.08, 0.04, 0.9 } })
        text_("JOURNAL COMPLETE!", 200, 160, { size = 40, color = { 1, 0.9, 0.3, 1 } })
        local total = 0
        for _, p in ipairs(photos) do total = total + p.score end
        text_(string.format("Total Score: %d  |  Photos: %d", total, #photos), 200, 230, { size = 18, color = { 0.85, 0.85, 0.85, 1 } })
        text_("All 8 species photographed!", 230, 270, { size = 16, color = { 0.6, 0.9, 0.5, 1 } })
        text_("Press SPACE to play again", 270, 360, { size = 16, color = { 0.5, 0.5, 0.5, 1 } })
        return
    end

    -- ─── ALBUM ───
    if current_state == STATES.ALBUM then
        rect(0, 0, W, H, { color = { 0, 0, 0, 0.8 } })
        text_("PHOTO ALBUM", 300, 30, { size = 28, color = { 0.9, 0.85, 0.6, 1 } })

        if #photos == 0 then
            text_("No photos yet. Get out there!", 250, 280, { size = 16, color = { 0.5, 0.5, 0.5, 1 } })
        else
            local y = 70
            text_("  #   Species       Score   Zoom           Time", 80, y, { size = 13, color = { 0.6, 0.6, 0.6, 1 } })
            y = y + 25
            local max_show = math.min(#photos, 16)
            for i = 1, max_show do
                local p = photos[i]
                local line = string.format(" %2d   %-12s  %3d     %-14s %s", i, p.species, p.score, p.zoom, p.tod)
                text_(line, 80, y, { size = 13, color = { 0.8, 0.8, 0.8, 1 } })
                y = y + 20
            end
            if #photos > 16 then
                text_(string.format("  ... and %d more", #photos - 16), 80, y, { size = 13, color = { 0.5, 0.5, 0.5, 1 } })
            end
        end

        -- Journal section
        text_("SPECIES JOURNAL", 300, 440, { size = 18, color = { 0.8, 0.9, 0.6, 1 } })
        local jx = 100
        for _, def in ipairs(ANIMAL_DEFS) do
            local found = journal[def.name]
            local col = found and { 0.5, 0.9, 0.4, 1 } or { 0.3, 0.3, 0.3, 1 }
            local mark = found and "[x]" or "[ ]"
            text_(mark .. " " .. def.name, jx, 470, { size = 12, color = col })
            jx = jx + 80
        end

        text_("Press TAB or ESC to close", 290, 550, { size = 12, color = { 0.4, 0.4, 0.4, 1 } })
        return
    end

    -- ─── EXPLORING HUD ───

    -- Viewfinder rectangle (screen center)
    local vf_sx = (W - VIEWFINDER_W) * 0.5
    local vf_sy = (H - VIEWFINDER_H) * 0.5
    rect(vf_sx, vf_sy, VIEWFINDER_W, VIEWFINDER_H, {
        color = { 1, 1, 1, 0.5 }, mode = "line",
    })
    -- Crosshair
    local cx, cy = W * 0.5, H * 0.5
    rect(cx - 8, cy, 16, 1, { color = { 1, 1, 1, 0.3 } })
    rect(cx, cy - 8, 1, 16, { color = { 1, 1, 1, 0.3 } })

    -- Corner brackets
    local bk = 12
    rect(vf_sx, vf_sy, bk, 2, { color = { 1, 1, 1, 0.7 } })
    rect(vf_sx, vf_sy, 2, bk, { color = { 1, 1, 1, 0.7 } })
    rect(vf_sx + VIEWFINDER_W - bk, vf_sy, bk, 2, { color = { 1, 1, 1, 0.7 } })
    rect(vf_sx + VIEWFINDER_W - 2, vf_sy, 2, bk, { color = { 1, 1, 1, 0.7 } })
    rect(vf_sx, vf_sy + VIEWFINDER_H - 2, bk, 2, { color = { 1, 1, 1, 0.7 } })
    rect(vf_sx, vf_sy + VIEWFINDER_H - bk, 2, bk, { color = { 1, 1, 1, 0.7 } })
    rect(vf_sx + VIEWFINDER_W - bk, vf_sy + VIEWFINDER_H - 2, bk, 2, { color = { 1, 1, 1, 0.7 } })
    rect(vf_sx + VIEWFINDER_W - 2, vf_sy + VIEWFINDER_H - bk, 2, bk, { color = { 1, 1, 1, 0.7 } })

    -- Top HUD bar
    rect(0, 0, W, 26, { color = { 0, 0, 0, 0.7 } })

    -- Film counter
    text_(string.format("Film: %d/%d", film_remaining, MAX_FILM), 10, 5, {
        size = 14, color = film_remaining > 3 and { 0.8, 0.8, 0.8, 1 } or { 1, 0.4, 0.3, 1 },
    })

    -- Zoom
    text_(ZOOM_NAMES[zoom_index], 140, 5, { size = 14, color = { 0.7, 0.85, 1, 1 } })

    -- Time of day
    text_(TOD_NAMES[tod_phase], 310, 5, { size = 14, color = { 0.9, 0.8, 0.5, 1 } })

    -- Score total
    local total_score = 0
    for _, p in ipairs(photos) do total_score = total_score + p.score end
    text_(string.format("Score: %d", total_score), 420, 5, { size = 14, color = { 1, 0.9, 0.3, 1 } })

    -- Journal progress
    local species_count = 0
    for _ in pairs(journal) do species_count = species_count + 1 end
    text_(string.format("Journal: %d/8", species_count), 560, 5, { size = 14, color = { 0.5, 0.9, 0.5, 1 } })

    -- FPS
    local fps = lurek.timer.getFPS()
    text_(string.format("FPS: %d", fps), W - 70, 5, { size = 12, color = { 0.5, 0.5, 0.5, 1 } })

    -- Patience indicator
    if patience_timer >= PATIENCE_THRESHOLD then
        local pulse = 0.5 + math.sin(tod_timer * 4) * 0.3
        text_("Patience...", W * 0.5 - 30, H - 50, { size = 14, color = { 0.5, 0.9, 0.5, pulse } })
    end

    -- Film empty notice
    if film_remaining <= 0 then
        text_("FILM EMPTY — press SPACE for new roll", W * 0.5 - 120, H - 30, {
            size = 14, color = { 1, 0.5, 0.3, 1 },
        })
    end

    -- Score popup
    if score_popup.alpha > 0.01 then
        text_(score_popup.text, W * 0.5 - 60, score_popup.y, {
            size = 22, color = { 1, 0.95, 0.5, score_popup.alpha },
        })
    end

    -- Camera flash particles (screen space)
    ps_flash:render()
end
