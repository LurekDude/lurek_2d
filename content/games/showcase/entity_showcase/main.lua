-- Entity Showcase — Lurek2D
-- Category: showcase
-- Interactive ECS deep dive with six chapters

-- ============================================================
-- Constants
-- ============================================================
local SCREEN_W = 800
local SCREEN_H = 600
local PANEL_W = 180
local PANEL_X = SCREEN_W - PANEL_W - 10
local PLAY_W = SCREEN_W - PANEL_W - 30
local HUD_H = 30
local INST_Y = 40
local ENTITY_RADIUS = 12
local MAX_ENTITIES_STRESS = 500
local HEALTH_DECAY_RATE = 5
local SPAWN_BURST_COUNT = 8
local DESTROY_POOF_COUNT = 6
local COLLISION_SPARK_COUNT = 4
local PANEL_SLIDE_SPEED = 8

-- ============================================================
-- States
-- ============================================================
local STATE_TITLE = "TITLE"
local STATE_CH1   = "CHAPTER_1"
local STATE_CH2   = "CHAPTER_2"
local STATE_CH3   = "CHAPTER_3"
local STATE_CH4   = "CHAPTER_4"
local STATE_CH5   = "CHAPTER_5"
local STATE_CH6   = "CHAPTER_6"

local state = STATE_TITLE
local title_timer = 0
local chapter_names = {
    [STATE_CH1] = "Create / Destroy",
    [STATE_CH2] = "Components",
    [STATE_CH3] = "Systems",
    [STATE_CH4] = "Queries",
    [STATE_CH5] = "Events",
    [STATE_CH6] = "Stress Test",
}

-- ============================================================
-- ECS simulation
-- ============================================================
local next_id = 1
local entities = {}       -- id → entity table
local entity_order = {}   -- ordered list of ids for iteration
local selected_id = nil

local component_counts = { position = 0, velocity = 0, health = 0, color = 0 }

local function new_entity(opts)
    opts = opts or {}
    local id = next_id
    next_id = next_id + 1
    local e = {
        id = id,
        x = opts.x or (40 + math.random() * (PLAY_W - 80)),
        y = opts.y or (80 + math.random() * (SCREEN_H - 160)),
        vx = 0, vy = 0,
        health = nil,
        max_health = 100,
        r = 0.5, g = 0.5, b = 0.8, a = 1.0,
        has_position = true,
        has_velocity = false,
        has_health = false,
        has_color = false,
        scale = 0.0,
        scale_target = 1.0,
        alive = true,
    }
    if opts.velocity then
        e.has_velocity = true
        e.vx = opts.vx or (-40 + math.random() * 80)
        e.vy = opts.vy or (-40 + math.random() * 80)
    end
    if opts.health then
        e.has_health = true
        e.health = opts.health_val or 100
    end
    if opts.color then
        e.has_color = true
        e.r = opts.r or (0.3 + math.random() * 0.7)
        e.g = opts.g or (0.3 + math.random() * 0.7)
        e.b = opts.b or (0.3 + math.random() * 0.7)
    end
    component_counts.position = component_counts.position + 1
    if e.has_velocity then component_counts.velocity = component_counts.velocity + 1 end
    if e.has_health then component_counts.health = component_counts.health + 1 end
    if e.has_color then component_counts.color = component_counts.color + 1 end
    entities[id] = e
    table.insert(entity_order, id)
    return e
end

local function destroy_entity(id)
    local e = entities[id]
    if not e then return end
    if e.has_position then component_counts.position = component_counts.position - 1 end
    if e.has_velocity then component_counts.velocity = component_counts.velocity - 1 end
    if e.has_health then component_counts.health = component_counts.health - 1 end
    if e.has_color then component_counts.color = component_counts.color - 1 end
    e.alive = false
    entities[id] = nil
    for i, oid in ipairs(entity_order) do
        if oid == id then
            table.remove(entity_order, i)
            break
        end
    end
    if selected_id == id then selected_id = nil end
end

local function clear_entities()
    entities = {}
    entity_order = {}
    selected_id = nil
    next_id = 1
    component_counts = { position = 0, velocity = 0, health = 0, color = 0 }
end

local function entity_count()
    return #entity_order
end

-- ============================================================
-- Particles
-- ============================================================
local particles = {}

local function spawn_particles(x, y, r, g, b, count, spread)
    count = count or 6
    spread = spread or 40
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 20 + math.random() * spread
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            r = r, g = g, b = b, a = 1.0,
            life = 0.3 + math.random() * 0.4,
            size = 2 + math.random() * 3,
        })
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.a = math.max(0, p.life / 0.7)
        p.size = p.size * (1 - dt * 1.5)
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

-- ============================================================
-- Events log
-- ============================================================
local event_log = {}
local EVENT_LOG_MAX = 12

local function log_event(msg, r, g, b)
    table.insert(event_log, 1, { text = msg, r = r or 1, g = g or 1, b = b or 1, timer = 4.0 })
    if #event_log > EVENT_LOG_MAX then
        table.remove(event_log, #event_log)
    end
end

local function update_event_log(dt)
    local i = 1
    while i <= #event_log do
        event_log[i].timer = event_log[i].timer - dt
        if event_log[i].timer <= 0 then
            table.remove(event_log, i)
        else
            i = i + 1
        end
    end
end

-- ============================================================
-- Helpers
-- ============================================================
local function lerp(a, b, t)
    return a + (b - a) * math.min(math.max(t, 0), 1)
end

local function dist(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local panel_offset = PANEL_W + 20
local panel_offset_target = 0

local fps = 0
local fps_timer = 0
local fps_count = 0
local perf_update_ms = 0

local chapter_instructions = {
    [STATE_CH1] = "SPACE: Spawn  |  D: Destroy  |  Click: Select",
    [STATE_CH2] = "P/V/H/K: Toggle Position/Velocity/Health/Color  |  Click: Select",
    [STATE_CH3] = "Watch systems run: Movement, Health Decay, Render  |  SPACE: Spawn",
    [STATE_CH4] = "Entities with Velocity+Health are highlighted  |  SPACE: Spawn",
    [STATE_CH5] = "Observe collision, health, spawn/destroy events  |  SPACE: Spawn",
    [STATE_CH6] = "SPACE: Spawn 500 entities  |  D: Clear all  |  Watch FPS",
}

-- ============================================================
-- Input bindings
-- ============================================================
lurek.input.bind("chapter_1", "1")
lurek.input.bind("chapter_2", "2")
lurek.input.bind("chapter_3", "3")
lurek.input.bind("chapter_4", "4")
lurek.input.bind("chapter_5", "5")
lurek.input.bind("chapter_6", "6")
lurek.input.bind("spawn", "space")
lurek.input.bind("destroy", "d")
lurek.input.bind("toggle_position", "p")
lurek.input.bind("toggle_velocity", "v")
lurek.input.bind("toggle_health", "h")
lurek.input.bind("toggle_color", "k")
lurek.input.bind("select", "mouse1")
lurek.input.bind("quit", "escape")

-- ============================================================
-- Chapter transitions
-- ============================================================
local function switch_chapter(new_state)
    if state == new_state then return end
    state = new_state
    clear_entities()
    event_log = {}
    panel_offset = PANEL_W + 20
    panel_offset_target = 0
    spawn_particles(SCREEN_W / 2, SCREEN_H / 2, 0.4, 0.7, 1.0, 10, 60)

    -- Seed some entities per chapter
    if state == STATE_CH2 then
        for i = 1, 5 do
            new_entity({ color = true, health = true, velocity = true })
        end
    elseif state == STATE_CH3 then
        for i = 1, 8 do
            new_entity({ velocity = true, health = true, color = true, health_val = 60 + math.random() * 40 })
        end
    elseif state == STATE_CH4 then
        -- Mix: some with velocity+health, some without
        for i = 1, 6 do
            new_entity({ velocity = (i % 2 == 0), health = (i % 3 ~= 0), color = true })
        end
    elseif state == STATE_CH5 then
        for i = 1, 6 do
            new_entity({ velocity = true, health = true, color = true, health_val = 80 })
        end
    end
end

-- ============================================================
-- Systems
-- ============================================================
local function system_movement(dt)
    for _, id in ipairs(entity_order) do
        local e = entities[id]
        if e and e.has_velocity then
            e.x = e.x + e.vx * dt
            e.y = e.y + e.vy * dt
            -- Bounce off play area walls
            if e.x < ENTITY_RADIUS then e.x = ENTITY_RADIUS; e.vx = -e.vx end
            if e.x > PLAY_W - ENTITY_RADIUS then e.x = PLAY_W - ENTITY_RADIUS; e.vx = -e.vx end
            if e.y < 70 + ENTITY_RADIUS then e.y = 70 + ENTITY_RADIUS; e.vy = -e.vy end
            if e.y > SCREEN_H - 20 - ENTITY_RADIUS then e.y = SCREEN_H - 20 - ENTITY_RADIUS; e.vy = -e.vy end
        end
    end
end

local function system_health(dt)
    local to_destroy = {}
    for _, id in ipairs(entity_order) do
        local e = entities[id]
        if e and e.has_health and e.health then
            e.health = e.health - HEALTH_DECAY_RATE * dt
            if e.health <= 0 then
                table.insert(to_destroy, id)
                log_event(string.format("Entity #%d died (health=0)", id), 1, 0.3, 0.3)
            end
        end
    end
    for _, id in ipairs(to_destroy) do
        local e = entities[id]
        if e then
            spawn_particles(e.x, e.y, 1, 0.2, 0.2, DESTROY_POOF_COUNT, 30)
            destroy_entity(id)
        end
    end
end

local function system_collision()
    -- Simple pairwise collision for small counts
    local ids = entity_order
    for i = 1, #ids do
        for j = i + 1, #ids do
            local a = entities[ids[i]]
            local b = entities[ids[j]]
            if a and b then
                local d = dist(a.x, a.y, b.x, b.y)
                if d < ENTITY_RADIUS * 2 then
                    -- Separate
                    local nx = (b.x - a.x) / (d + 0.001)
                    local ny = (b.y - a.y) / (d + 0.001)
                    local overlap = ENTITY_RADIUS * 2 - d
                    a.x = a.x - nx * overlap * 0.5
                    a.y = a.y - ny * overlap * 0.5
                    b.x = b.x + nx * overlap * 0.5
                    b.y = b.y + ny * overlap * 0.5
                    -- Bounce velocities
                    if a.has_velocity and b.has_velocity then
                        a.vx, b.vx = b.vx, a.vx
                        a.vy, b.vy = b.vy, a.vy
                    end
                    spawn_particles((a.x + b.x) / 2, (a.y + b.y) / 2, 1, 0.9, 0.3, COLLISION_SPARK_COUNT, 20)
                    if state == STATE_CH5 then
                        log_event(string.format("Collision: #%d <> #%d", a.id, b.id), 1, 0.9, 0.3)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- Callbacks
-- ============================================================

function lurek.init()
    lurek.window.setTitle("Entity Showcase — Lurek2D")
    lurek.render.setBackgroundColor(0.06, 0.08, 0.1)
end

local function _ready_setup()
    title_timer = 0
end

function lurek.process(dt)
    -- FPS
    fps_count = fps_count + 1
    fps_timer = fps_timer + dt
    if fps_timer >= 1.0 then
        fps = fps_count
        fps_count = 0
        fps_timer = fps_timer - 1.0
    end

    -- Title
    if state == STATE_TITLE then
        title_timer = title_timer + dt
        if lurek.input.wasActionPressed("chapter_1") then switch_chapter(STATE_CH1) end
        if lurek.input.wasActionPressed("chapter_2") then switch_chapter(STATE_CH2) end
        if lurek.input.wasActionPressed("chapter_3") then switch_chapter(STATE_CH3) end
        if lurek.input.wasActionPressed("chapter_4") then switch_chapter(STATE_CH4) end
        if lurek.input.wasActionPressed("chapter_5") then switch_chapter(STATE_CH5) end
        if lurek.input.wasActionPressed("chapter_6") then switch_chapter(STATE_CH6) end
        if lurek.input.wasActionPressed("quit") then lurek.event.quit() end
        return
    end

    -- Chapter switching (always available)
    if lurek.input.wasActionPressed("chapter_1") then switch_chapter(STATE_CH1) end
    if lurek.input.wasActionPressed("chapter_2") then switch_chapter(STATE_CH2) end
    if lurek.input.wasActionPressed("chapter_3") then switch_chapter(STATE_CH3) end
    if lurek.input.wasActionPressed("chapter_4") then switch_chapter(STATE_CH4) end
    if lurek.input.wasActionPressed("chapter_5") then switch_chapter(STATE_CH5) end
    if lurek.input.wasActionPressed("chapter_6") then switch_chapter(STATE_CH6) end
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Panel tween
    panel_offset = lerp(panel_offset, panel_offset_target, dt * PANEL_SLIDE_SPEED)

    -- Scale tween for entities
    for _, id in ipairs(entity_order) do
        local e = entities[id]
        if e then
            e.scale = lerp(e.scale, e.scale_target, dt * 10)
        end
    end

    -- Entity selection via mouse click
    if lurek.input.wasActionPressed("select") then
        local mx, my = lurek.input.mouse.getPosition()
        local best_id = nil
        local best_dist = ENTITY_RADIUS + 4
        for _, id in ipairs(entity_order) do
            local e = entities[id]
            if e then
                local d = dist(mx, my, e.x, e.y)
                if d < best_dist then
                    best_dist = d
                    best_id = id
                end
            end
        end
        selected_id = best_id
    end

    local perf_start = lurek.timer.getTime()

    -- Chapter-specific logic
    if state == STATE_CH1 then
        if lurek.input.wasActionPressed("spawn") then
            local e = new_entity({ color = true })
            spawn_particles(e.x, e.y, e.r, e.g, e.b, SPAWN_BURST_COUNT, 35)
            log_event(string.format("Spawned entity #%d", e.id), 0.3, 1, 0.3)
        end
        if lurek.input.wasActionPressed("destroy") then
            if selected_id and entities[selected_id] then
                local e = entities[selected_id]
                spawn_particles(e.x, e.y, 1, 0.3, 0.3, DESTROY_POOF_COUNT, 30)
                log_event(string.format("Destroyed entity #%d", e.id), 1, 0.3, 0.3)
                destroy_entity(selected_id)
            elseif #entity_order > 0 then
                local id = entity_order[1]
                local e = entities[id]
                if e then
                    spawn_particles(e.x, e.y, 1, 0.3, 0.3, DESTROY_POOF_COUNT, 30)
                    log_event(string.format("Destroyed entity #%d", id), 1, 0.3, 0.3)
                    destroy_entity(id)
                end
            end
        end

    elseif state == STATE_CH2 then
        if selected_id and entities[selected_id] then
            local e = entities[selected_id]
            if lurek.input.wasActionPressed("toggle_position") then
                e.has_position = not e.has_position
                component_counts.position = component_counts.position + (e.has_position and 1 or -1)
                log_event(string.format("#%d Position %s", e.id, e.has_position and "ON" or "OFF"), 0.4, 0.8, 1)
            end
            if lurek.input.wasActionPressed("toggle_velocity") then
                e.has_velocity = not e.has_velocity
                component_counts.velocity = component_counts.velocity + (e.has_velocity and 1 or -1)
                if e.has_velocity then e.vx = -30 + math.random() * 60; e.vy = -30 + math.random() * 60 end
                log_event(string.format("#%d Velocity %s", e.id, e.has_velocity and "ON" or "OFF"), 0.4, 1, 0.6)
            end
            if lurek.input.wasActionPressed("toggle_health") then
                e.has_health = not e.has_health
                component_counts.health = component_counts.health + (e.has_health and 1 or -1)
                if e.has_health then e.health = 100 end
                log_event(string.format("#%d Health %s", e.id, e.has_health and "ON" or "OFF"), 1, 0.5, 0.5)
            end
            if lurek.input.wasActionPressed("toggle_color") then
                e.has_color = not e.has_color
                component_counts.color = component_counts.color + (e.has_color and 1 or -1)
                if e.has_color then e.r = 0.3 + math.random() * 0.7; e.g = 0.3 + math.random() * 0.7; e.b = 0.3 + math.random() * 0.7 end
                log_event(string.format("#%d Color %s", e.id, e.has_color and "ON" or "OFF"), 0.9, 0.8, 0.3)
            end
        end
        system_movement(dt)

    elseif state == STATE_CH3 then
        if lurek.input.wasActionPressed("spawn") then
            local e = new_entity({ velocity = true, health = true, color = true, health_val = 60 + math.random() * 40 })
            spawn_particles(e.x, e.y, e.r, e.g, e.b, SPAWN_BURST_COUNT, 35)
        end
        system_movement(dt)
        system_health(dt)

    elseif state == STATE_CH4 then
        if lurek.input.wasActionPressed("spawn") then
            local use_vel = math.random() > 0.4
            local use_hp = math.random() > 0.4
            new_entity({ velocity = use_vel, health = use_hp, color = true })
        end
        system_movement(dt)

    elseif state == STATE_CH5 then
        if lurek.input.wasActionPressed("spawn") then
            local e = new_entity({ velocity = true, health = true, color = true, health_val = 80 })
            spawn_particles(e.x, e.y, e.r, e.g, e.b, SPAWN_BURST_COUNT, 35)
            log_event(string.format("SPAWN: Entity #%d created", e.id), 0.3, 1, 0.4)
        end
        system_movement(dt)
        system_collision()
        system_health(dt)

    elseif state == STATE_CH6 then
        if lurek.input.wasActionPressed("spawn") then
            for i = 1, MAX_ENTITIES_STRESS do
                new_entity({
                    velocity = true, color = true, health = true,
                    health_val = 200 + math.random() * 300,
                    vx = -60 + math.random() * 120,
                    vy = -60 + math.random() * 120,
                })
            end
        end
        if lurek.input.wasActionPressed("destroy") then
            clear_entities()
        end
        system_movement(dt)
        system_health(dt)
        if entity_count() <= 60 then
            system_collision()
        end
    end

    perf_update_ms = (lurek.timer.getTime() - perf_start) * 1000

    update_particles(dt)
    update_event_log(dt)
end

-- ============================================================
-- Render: world-space entities
-- ============================================================
function lurek.draw()
    if state == STATE_TITLE then return end

    -- Draw entities
    for _, id in ipairs(entity_order) do
        local e = entities[id]
        if e then
            local s = e.scale
            local r, g, b = 0.5, 0.5, 0.8
            if e.has_color then r, g, b = e.r, e.g, e.b end

            -- Highlight matched query entities in Ch4
            local is_match = false
            if state == STATE_CH4 and e.has_velocity and e.has_health then
                is_match = true
                lurek.render.setColor(1, 1, 0.3, 0.25)
                lurek.render.circle("fill", e.x, e.y, ENTITY_RADIUS * s + 6)
            end

            -- Selection ring
            if id == selected_id then
                lurek.render.setColor(1, 1, 1, 0.7)
                lurek.render.circle("line", e.x, e.y, ENTITY_RADIUS * s + 3)
            end

            -- Entity body
            lurek.render.setColor(r, g, b, e.a)
            lurek.render.circle("fill", e.x, e.y, ENTITY_RADIUS * s)

            -- Component indicators (small dots around entity)
            local ind_r = ENTITY_RADIUS * s + 5
            if e.has_velocity then
                lurek.render.setColor(0.2, 1, 0.4, 0.8)
                lurek.render.circle("fill", e.x + ind_r, e.y, 2.5)
            end
            if e.has_health then
                lurek.render.setColor(1, 0.3, 0.3, 0.8)
                lurek.render.circle("fill", e.x, e.y - ind_r, 2.5)
                -- Health bar
                local hp_frac = (e.health or 0) / e.max_health
                local bar_w = ENTITY_RADIUS * 2 * s
                lurek.render.setColor(0.2, 0.2, 0.2, 0.6)
                lurek.render.rectangle("fill", e.x - bar_w / 2, e.y + ENTITY_RADIUS * s + 4, bar_w, 3)
                lurek.render.setColor(lerp(1, 0, hp_frac), lerp(0, 1, hp_frac), 0.1, 0.9)
                lurek.render.rectangle("fill", e.x - bar_w / 2, e.y + ENTITY_RADIUS * s + 4, bar_w * hp_frac, 3)
            end
            if e.has_color then
                lurek.render.setColor(0.9, 0.9, 0.2, 0.8)
                lurek.render.circle("fill", e.x - ind_r, e.y, 2.5)
            end
        end
    end

    -- Particles
    for _, p in ipairs(particles) do
        lurek.render.setColor(p.r, p.g, p.b, p.a)
        lurek.render.circle("fill", p.x, p.y, p.size)
    end
end

-- ============================================================
-- Render UI: panels, HUD, instructions
-- ============================================================
function lurek.draw_ui()
    -- Title screen
    if state == STATE_TITLE then
        local pulse = 0.7 + 0.3 * math.sin(title_timer * 2.5)
        lurek.render.setColor(0.4, 0.7, 1.0, pulse)
        lurek.render.print("ENTITY SHOWCASE", SCREEN_W / 2 - 120, SCREEN_H / 2 - 60, 28)
        lurek.render.setColor(0.7, 0.8, 0.9, 0.8)
        lurek.render.print("ECS DEEP DIVE", SCREEN_W / 2 - 80, SCREEN_H / 2 - 20, 18)
        lurek.render.setColor(0.6, 0.6, 0.7, 0.5 + 0.3 * math.sin(title_timer * 1.8))
        lurek.render.print("Press 1-6 to select a chapter", SCREEN_W / 2 - 130, SCREEN_H / 2 + 40, 14)
        lurek.render.setColor(0.4, 0.4, 0.5, 0.6)
        lurek.render.print("1: Create/Destroy   2: Components   3: Systems", SCREEN_W / 2 - 190, SCREEN_H / 2 + 80, 12)
        lurek.render.print("4: Queries   5: Events   6: Stress Test", SCREEN_W / 2 - 150, SCREEN_H / 2 + 100, 12)
        lurek.render.setColor(0.3, 0.3, 0.4, 0.5)
        lurek.render.print("ESC to quit", SCREEN_W / 2 - 40, SCREEN_H - 40, 12)
        return
    end

    -- HUD bar
    lurek.render.setColor(0.08, 0.1, 0.14, 0.9)
    lurek.render.rectangle("fill", 0, 0, SCREEN_W, HUD_H)
    lurek.render.setColor(0.3, 0.5, 0.8, 1)
    local ch_name = chapter_names[state] or "?"
    lurek.render.print(string.format("Ch %s: %s", string.sub(state, -1), ch_name), 10, 8, 13)
    lurek.render.setColor(0.6, 0.8, 0.6, 1)
    lurek.render.print(string.format("Entities: %d", entity_count()), 280, 8, 12)
    lurek.render.setColor(0.8, 0.8, 0.6, 1)
    lurek.render.print(string.format("FPS: %d", fps), SCREEN_W - 80, 8, 12)

    -- Instructions bar
    lurek.render.setColor(0.06, 0.07, 0.1, 0.85)
    lurek.render.rectangle("fill", 0, HUD_H, SCREEN_W, 26)
    lurek.render.setColor(0.5, 0.6, 0.7, 0.9)
    local inst = chapter_instructions[state] or ""
    lurek.render.print(inst, 10, HUD_H + 6, 11)

    -- Component panel (right side, slides in)
    local px = PANEL_X + panel_offset
    lurek.render.setColor(0.1, 0.12, 0.16, 0.92)
    lurek.render.rectangle("fill", px, 70, PANEL_W, SCREEN_H - 80)
    lurek.render.setColor(0.3, 0.4, 0.6, 0.6)
    lurek.render.rectangle("line", px, 70, PANEL_W, SCREEN_H - 80)

    lurek.render.setColor(0.5, 0.7, 1, 1)
    lurek.render.print("Components", px + 10, 78, 13)

    -- Component counts
    local cy = 100
    local comp_list = { "position", "velocity", "health", "color" }
    local comp_colors = {
        position = {0.4, 0.7, 1},
        velocity = {0.2, 1, 0.4},
        health = {1, 0.3, 0.3},
        color = {0.9, 0.9, 0.2},
    }
    for _, cname in ipairs(comp_list) do
        local cc = comp_colors[cname]
        lurek.render.setColor(cc[1], cc[2], cc[3], 0.9)
        lurek.render.circle("fill", px + 16, cy + 5, 4)
        lurek.render.setColor(0.7, 0.7, 0.8, 0.9)
        lurek.render.print(string.format("%s: %d", cname, component_counts[cname]), px + 26, cy, 11)
        cy = cy + 20
    end

    -- Selected entity details
    cy = cy + 15
    lurek.render.setColor(0.4, 0.5, 0.7, 0.8)
    lurek.render.print("Selected:", px + 10, cy, 12)
    cy = cy + 18
    if selected_id and entities[selected_id] then
        local e = entities[selected_id]
        lurek.render.setColor(0.8, 0.9, 1, 1)
        lurek.render.print(string.format("Entity #%d", e.id), px + 14, cy, 11)
        cy = cy + 18
        lurek.render.setColor(0.6, 0.7, 0.8, 0.8)
        lurek.render.print(string.format("Pos: %.0f, %.0f", e.x, e.y), px + 14, cy, 10)
        cy = cy + 15
        if e.has_velocity then
            lurek.render.setColor(0.2, 1, 0.4, 0.8)
            lurek.render.print(string.format("Vel: %.1f, %.1f", e.vx, e.vy), px + 14, cy, 10)
            cy = cy + 15
        end
        if e.has_health then
            local hp_frac = (e.health or 0) / e.max_health
            lurek.render.setColor(lerp(1, 0, hp_frac), lerp(0, 1, hp_frac), 0.1, 0.9)
            lurek.render.print(string.format("HP: %.0f / %d", e.health or 0, e.max_health), px + 14, cy, 10)
            cy = cy + 15
        end
        if e.has_color then
            lurek.render.setColor(e.r, e.g, e.b, 1)
            lurek.render.rectangle("fill", px + 14, cy, 30, 10)
            lurek.render.setColor(0.7, 0.7, 0.8, 0.8)
            lurek.render.print(string.format("%.2f %.2f %.2f", e.r, e.g, e.b), px + 50, cy, 10)
            cy = cy + 15
        end
    else
        lurek.render.setColor(0.4, 0.4, 0.5, 0.6)
        lurek.render.print("(none — click entity)", px + 14, cy, 10)
    end

    -- Performance metrics (Chapter 6)
    if state == STATE_CH6 then
        cy = cy + 25
        lurek.render.setColor(0.5, 0.8, 0.5, 0.9)
        lurek.render.print("Performance", px + 10, cy, 12)
        cy = cy + 18
        lurek.render.setColor(0.7, 0.8, 0.7, 0.8)
        lurek.render.print(string.format("Update: %.2f ms", perf_update_ms), px + 14, cy, 10)
        cy = cy + 15
        lurek.render.print(string.format("Entities: %d", entity_count()), px + 14, cy, 10)
        cy = cy + 15
        lurek.render.print(string.format("FPS: %d", fps), px + 14, cy, 10)
    end

    -- Event log (Chapter 5)
    if state == STATE_CH5 and #event_log > 0 then
        lurek.render.setColor(0.08, 0.1, 0.14, 0.85)
        lurek.render.rectangle("fill", 10, SCREEN_H - 20 - EVENT_LOG_MAX * 15, 280, EVENT_LOG_MAX * 15 + 10)
        for i, ev in ipairs(event_log) do
            local alpha = math.min(ev.timer / 1.0, 1.0)
            lurek.render.setColor(ev.r, ev.g, ev.b, alpha * 0.9)
            lurek.render.print(ev.text, 16, SCREEN_H - 18 - i * 15, 10)
        end
    end
end
