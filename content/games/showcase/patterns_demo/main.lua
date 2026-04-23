-- Patterns Demo — Lurek2D
-- Category: showcase
-- Interactive design patterns showcase with six classic patterns
-- Controls: 1-6 switch pattern, A/B/C events, Space spawn, D release, Arrows move, U undo, R redo, S service, F factory, Escape quit
-- Run with: cargo run -- content/games/showcase/patterns_demo

-- ============================================================
-- Constants
-- ============================================================
local SCREEN_W = 800
local SCREEN_H = 600
local TAB_H = 32
local LOG_H = 100
local LOG_Y = SCREEN_H - LOG_H
local DEMO_X = 10
local DEMO_W = 440
local DEMO_Y = TAB_H + 36
local DEMO_H = LOG_Y - DEMO_Y - 10
local CODE_X = 460
local CODE_W = SCREEN_W - CODE_X - 10
local CODE_Y = DEMO_Y
local CODE_H = DEMO_H
local LOG_MAX = 20

-- ============================================================
-- States
-- ============================================================
local STATE_TITLE = "TITLE"
local STATE_P1 = "PATTERN_1"
local STATE_P2 = "PATTERN_2"
local STATE_P3 = "PATTERN_3"
local STATE_P4 = "PATTERN_4"
local STATE_P5 = "PATTERN_5"
local STATE_P6 = "PATTERN_6"

local state = STATE_TITLE
local title_timer = 0

local pattern_names = {
    [STATE_P1] = "EventBus",
    [STATE_P2] = "ObjectPool",
    [STATE_P3] = "CommandStack",
    [STATE_P4] = "ServiceLocator",
    [STATE_P5] = "Factory",
    [STATE_P6] = "SimpleState",
}
local pattern_order = { STATE_P1, STATE_P2, STATE_P3, STATE_P4, STATE_P5, STATE_P6 }

local pattern_desc = {
    [STATE_P1] = "Publish/Subscribe — decouple event producers from consumers",
    [STATE_P2] = "Pre-allocate and reuse objects to avoid runtime allocation",
    [STATE_P3] = "Encapsulate actions as objects with undo/redo support",
    [STATE_P4] = "Central registry for named services — query by name at runtime",
    [STATE_P5] = "Create objects via a factory function without exposing construction",
    [STATE_P6] = "Finite State Machine — traffic light cycles Green→Yellow→Red",
}

-- ============================================================
-- Helpers
-- ============================================================
local function lerp(a, b, t)
    return a + (b - a) * math.min(math.max(t, 0), 1)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
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
-- Log
-- ============================================================
local log_entries = {}

local function log_add(msg, r, g, b)
    table.insert(log_entries, 1, { text = msg, r = r or 0.8, g = g or 0.8, b = b or 0.8, timer = 6.0 })
    if #log_entries > LOG_MAX then table.remove(log_entries, #log_entries) end
end

local function update_log(dt)
    local i = 1
    while i <= #log_entries do
        log_entries[i].timer = log_entries[i].timer - dt
        if log_entries[i].timer <= 0 then
            table.remove(log_entries, i)
        else
            i = i + 1
        end
    end
end

-- ============================================================
-- Pattern 1: EventBus
-- ============================================================
local bus_listeners = {}
local bus_events = { "player_hit", "score_up", "level_up" }

local function bus_init()
    bus_listeners = {}
    local names = { "HUD", "SoundFX", "Analytics", "Particles" }
    local colors = { {0.4,0.8,1}, {1,0.8,0.2}, {0.5,1,0.5}, {1,0.5,0.8} }
    for i, name in ipairs(names) do
        bus_listeners[name] = { name = name, col = colors[i], events = {} }
        for _, ev in ipairs(bus_events) do
            bus_listeners[name].events[ev] = true
        end
    end
end

local function bus_fire(event_name)
    log_add("EVENT: " .. event_name, 1, 1, 0.4)
    for _, listener in pairs(bus_listeners) do
        if listener.events[event_name] then
            log_add("  -> " .. listener.name .. " handled " .. event_name, listener.col[1], listener.col[2], listener.col[3])
        end
    end
    spawn_particles(DEMO_X + DEMO_W / 2, DEMO_Y + 60, 1, 1, 0.3, 8, 50)
end

-- ============================================================
-- Pattern 2: ObjectPool
-- ============================================================
local pool = { objects = {}, max_size = 12 }

local function pool_init()
    pool.objects = {}
    for i = 1, pool.max_size do
        table.insert(pool.objects, { active = false, x = 0, y = 0, vx = 0, vy = 0, scale = 0, r = 0.5, g = 0.5, b = 0.8 })
    end
end

local function pool_spawn()
    for _, obj in ipairs(pool.objects) do
        if not obj.active then
            obj.active = true
            obj.x = DEMO_X + 40 + math.random() * (DEMO_W - 80)
            obj.y = DEMO_Y + 40 + math.random() * (DEMO_H - 80)
            obj.vx = -30 + math.random() * 60
            obj.vy = -30 + math.random() * 60
            obj.scale = 0.1
            obj.r = 0.3 + math.random() * 0.7
            obj.g = 0.3 + math.random() * 0.7
            obj.b = 0.3 + math.random() * 0.7
            spawn_particles(obj.x, obj.y, obj.r, obj.g, obj.b, 6, 30)
            log_add("POOL: Spawned from pool", 0.3, 1, 0.4)
            return true
        end
    end
    log_add("POOL: Full — no free objects!", 1, 0.3, 0.3)
    return false
end

local function pool_release()
    for i = #pool.objects, 1, -1 do
        if pool.objects[i].active then
            pool.objects[i].active = false
            spawn_particles(pool.objects[i].x, pool.objects[i].y, 1, 0.4, 0.3, 4, 20)
            log_add("POOL: Released back to pool", 1, 0.6, 0.3)
            return true
        end
    end
    log_add("POOL: Nothing to release", 0.6, 0.6, 0.6)
    return false
end

local function pool_counts()
    local active, free = 0, 0
    for _, obj in ipairs(pool.objects) do
        if obj.active then active = active + 1 else free = free + 1 end
    end
    return active, free
end

local function pool_update(dt)
    for _, obj in ipairs(pool.objects) do
        if obj.active then
            obj.x = obj.x + obj.vx * dt
            obj.y = obj.y + obj.vy * dt
            obj.scale = lerp(obj.scale, 1.0, dt * 8)
            if obj.x < DEMO_X + 10 or obj.x > DEMO_X + DEMO_W - 10 then obj.vx = -obj.vx end
            if obj.y < DEMO_Y + 10 or obj.y > DEMO_Y + DEMO_H - 10 then obj.vy = -obj.vy end
        end
    end
end

-- ============================================================
-- Pattern 3: CommandStack
-- ============================================================
local cmd_stack = {}
local cmd_redo = {}
local cmd_square = { x = DEMO_X + DEMO_W / 2, y = DEMO_Y + DEMO_H / 2 }
local CMD_STEP = 30

local function cmd_execute(dx, dy)
    local cmd = { dx = dx, dy = dy, desc = string.format("Move(%+d,%+d)", dx, dy) }
    cmd_square.x = clamp(cmd_square.x + dx, DEMO_X + 15, DEMO_X + DEMO_W - 15)
    cmd_square.y = clamp(cmd_square.y + dy, DEMO_Y + 15, DEMO_Y + DEMO_H - 15)
    table.insert(cmd_stack, cmd)
    cmd_redo = {}
    spawn_particles(cmd_square.x, cmd_square.y, 0.4, 0.7, 1, 4, 20)
    log_add("CMD: " .. cmd.desc, 0.4, 0.7, 1)
end

local function cmd_undo()
    if #cmd_stack == 0 then log_add("CMD: Nothing to undo", 0.5, 0.5, 0.5) return end
    local cmd = table.remove(cmd_stack)
    cmd_square.x = clamp(cmd_square.x - cmd.dx, DEMO_X + 15, DEMO_X + DEMO_W - 15)
    cmd_square.y = clamp(cmd_square.y - cmd.dy, DEMO_Y + 15, DEMO_Y + DEMO_H - 15)
    table.insert(cmd_redo, cmd)
    spawn_particles(cmd_square.x, cmd_square.y, 1, 0.8, 0.2, 4, 20)
    log_add("CMD: Undo " .. cmd.desc, 1, 0.8, 0.2)
end

local function cmd_redo_action()
    if #cmd_redo == 0 then log_add("CMD: Nothing to redo", 0.5, 0.5, 0.5) return end
    local cmd = table.remove(cmd_redo)
    cmd_square.x = clamp(cmd_square.x + cmd.dx, DEMO_X + 15, DEMO_X + DEMO_W - 15)
    cmd_square.y = clamp(cmd_square.y + cmd.dy, DEMO_Y + 15, DEMO_Y + DEMO_H - 15)
    table.insert(cmd_stack, cmd)
    spawn_particles(cmd_square.x, cmd_square.y, 0.2, 1, 0.6, 4, 20)
    log_add("CMD: Redo " .. cmd.desc, 0.2, 1, 0.6)
end

-- ============================================================
-- Pattern 4: ServiceLocator
-- ============================================================
local services = {}

local function svc_init()
    services = {
        { name = "AudioService",   status = "ready", color = {1, 0.6, 0.2} },
        { name = "RenderService",  status = "ready", color = {0.4, 0.8, 1} },
        { name = "PhysicsService", status = "ready", color = {0.5, 1, 0.4} },
    }
end

local function svc_query()
    for _, svc in ipairs(services) do
        log_add("SVC: " .. svc.name .. " → " .. svc.status, svc.color[1], svc.color[2], svc.color[3])
        svc.status = (svc.status == "ready") and "busy" or "ready"
    end
    spawn_particles(DEMO_X + DEMO_W / 2, DEMO_Y + DEMO_H / 2, 0.8, 0.5, 1, 8, 40)
end

-- ============================================================
-- Pattern 5: Factory
-- ============================================================
local factory_entities = {}
local FACTORY_TYPES = {
    { name = "Warrior", hp = 120, atk = 15, color = {0.9, 0.3, 0.2} },
    { name = "Mage",    hp = 60,  atk = 30, color = {0.3, 0.4, 1.0} },
    { name = "Archer",  hp = 80,  atk = 20, color = {0.2, 0.9, 0.3} },
}

local function factory_create()
    local tmpl = FACTORY_TYPES[math.random(1, #FACTORY_TYPES)]
    local e = {
        name = tmpl.name,
        hp = tmpl.hp, atk = tmpl.atk,
        r = tmpl.color[1], g = tmpl.color[2], b = tmpl.color[3],
        x = DEMO_X + 30 + math.random() * (DEMO_W - 60),
        y = DEMO_Y + 30 + math.random() * (DEMO_H - 60),
        scale = 0.1, alive = true,
    }
    table.insert(factory_entities, e)
    if #factory_entities > 15 then table.remove(factory_entities, 1) end
    spawn_particles(e.x, e.y, e.r, e.g, e.b, 6, 35)
    log_add("FACTORY: Created " .. e.name .. string.format(" (HP:%d ATK:%d)", e.hp, e.atk), e.r, e.g, e.b)
end

-- ============================================================
-- Pattern 6: SimpleState (Traffic Light FSM)
-- ============================================================
local fsm = { state = "GREEN", timer = 0 }
local FSM_DURATIONS = { GREEN = 3.0, YELLOW = 1.5, RED = 3.0 }
local FSM_NEXT = { GREEN = "YELLOW", YELLOW = "RED", RED = "GREEN" }
local FSM_COLORS = {
    GREEN  = { 0.1, 0.9, 0.2 },
    YELLOW = { 1.0, 0.9, 0.1 },
    RED    = { 1.0, 0.2, 0.1 },
}
local fsm_blend = { r = 0.1, g = 0.9, b = 0.2 }

local function fsm_transition()
    local old = fsm.state
    fsm.state = FSM_NEXT[fsm.state]
    fsm.timer = 0
    local c = FSM_COLORS[fsm.state]
    spawn_particles(DEMO_X + DEMO_W / 2, DEMO_Y + DEMO_H / 2, c[1], c[2], c[3], 10, 50)
    log_add("FSM: " .. old .. " → " .. fsm.state, c[1], c[2], c[3])
end

-- ============================================================
-- Pseudocode per pattern
-- ============================================================
local pseudocode = {
    [STATE_P1] = {
        "-- EventBus Pattern",
        "bus = EventBus.new()",
        "",
        "bus:subscribe('hit', fn)",
        "bus:subscribe('score', fn)",
        "",
        "-- When event fires:",
        "bus:publish('hit', data)",
        "  -> all listeners notified",
        "",
        "-- Decouples sender",
        "-- from receiver",
    },
    [STATE_P2] = {
        "-- ObjectPool Pattern",
        "pool = Pool.new(max=12)",
        "",
        "obj = pool:acquire()",
        "obj:init(x, y, vel)",
        "",
        "-- When done:",
        "pool:release(obj)",
        "  -> obj recycled,",
        "     not destroyed",
        "",
        "-- Avoids alloc/GC",
    },
    [STATE_P3] = {
        "-- Command Pattern",
        "cmd = MoveCmd(dx, dy)",
        "cmd:execute(target)",
        "stack:push(cmd)",
        "",
        "-- Undo:",
        "cmd = stack:pop()",
        "cmd:undo(target)",
        "redo_stack:push(cmd)",
        "",
        "-- Full history trail",
    },
    [STATE_P4] = {
        "-- ServiceLocator",
        "locator = {}",
        "locator:register(",
        "  'Audio', AudioSvc)",
        "locator:register(",
        "  'Render', RenderSvc)",
        "",
        "svc = locator:get(",
        "  'Audio')",
        "svc:play('boom.wav')",
        "",
        "-- Central registry",
    },
    [STATE_P5] = {
        "-- Factory Pattern",
        "function create(type)",
        "  if type=='Warrior'",
        "    return {hp=120,",
        "            atk=15}",
        "  elseif type=='Mage'",
        "    return {hp=60,",
        "            atk=30}",
        "  end",
        "end",
        "",
        "-- Hides construction",
    },
    [STATE_P6] = {
        "-- State Machine",
        "fsm = { state='GREEN' }",
        "",
        "transitions = {",
        "  GREEN  -> YELLOW",
        "  YELLOW -> RED",
        "  RED    -> GREEN",
        "}",
        "",
        "fsm:transition()",
        "  -> auto or manual",
    },
}

-- ============================================================
-- Tab tween
-- ============================================================
local tab_slide_x = 0
local tab_slide_target = 0

-- FPS counter
local fps = 0
local fps_timer = 0
local fps_count = 0

-- ============================================================
-- Input bindings
-- ============================================================
lurek.input.bind("pattern_1", "1")
lurek.input.bind("pattern_2", "2")
lurek.input.bind("pattern_3", "3")
lurek.input.bind("pattern_4", "4")
lurek.input.bind("pattern_5", "5")
lurek.input.bind("pattern_6", "6")
lurek.input.bind("action_a", "a")
lurek.input.bind("action_b", "b")
lurek.input.bind("action_c", "c")
lurek.input.bind("spawn", "space")
lurek.input.bind("release", "d")
lurek.input.bind("undo", "u")
lurek.input.bind("redo", "r")
lurek.input.bind("service", "s")
lurek.input.bind("factory", "f")
lurek.input.bind("move_up", "up")
lurek.input.bind("move_down", "down")
lurek.input.bind("move_left", "left")
lurek.input.bind("move_right", "right")
lurek.input.bind("quit", "escape")

-- ============================================================
-- Pattern switching
-- ============================================================
local function switch_pattern(new_state)
    if state == new_state then return end
    state = new_state
    log_entries = {}

    -- Compute tab slide target
    for i, ps in ipairs(pattern_order) do
        if ps == new_state then tab_slide_target = (i - 1) * (SCREEN_W / 6) end
    end

    -- Init pattern data
    if new_state == STATE_P1 then bus_init()
    elseif new_state == STATE_P2 then pool_init()
    elseif new_state == STATE_P3 then
        cmd_stack = {}; cmd_redo = {}
        cmd_square = { x = DEMO_X + DEMO_W / 2, y = DEMO_Y + DEMO_H / 2 }
    elseif new_state == STATE_P4 then svc_init()
    elseif new_state == STATE_P5 then factory_entities = {}
    elseif new_state == STATE_P6 then
        fsm = { state = "GREEN", timer = 0 }
        local c = FSM_COLORS["GREEN"]
        fsm_blend = { r = c[1], g = c[2], b = c[3] }
    end

    spawn_particles(SCREEN_W / 2, TAB_H + 10, 0.5, 0.7, 1, 8, 50)
    log_add("Switched to: " .. pattern_names[new_state], 0.5, 0.8, 1)
end

-- ============================================================
-- Callbacks
-- ============================================================

function lurek.init()
    lurek.window.setTitle("Patterns Demo — Lurek2D")
    lurek.window.setBackgroundColor(0.08, 0.06, 0.1)
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
        for i, ps in ipairs(pattern_order) do
            if lurek.input.pressed("pattern_" .. i) then switch_pattern(ps) end
        end
        if lurek.input.pressed("quit") then lurek.event.quit() end
        return
    end

    -- Global pattern switching
    for i, ps in ipairs(pattern_order) do
        if lurek.input.pressed("pattern_" .. i) then switch_pattern(ps) end
    end
    if lurek.input.pressed("quit") then lurek.event.quit() end

    -- Tab slide tween
    tab_slide_x = lerp(tab_slide_x, tab_slide_target, dt * 10)

    -- Pattern-specific update
    if state == STATE_P1 then
        if lurek.input.pressed("action_a") then bus_fire("player_hit") end
        if lurek.input.pressed("action_b") then bus_fire("score_up") end
        if lurek.input.pressed("action_c") then bus_fire("level_up") end

    elseif state == STATE_P2 then
        if lurek.input.pressed("spawn") then pool_spawn() end
        if lurek.input.pressed("release") then pool_release() end
        pool_update(dt)

    elseif state == STATE_P3 then
        if lurek.input.pressed("move_up") then cmd_execute(0, -CMD_STEP) end
        if lurek.input.pressed("move_down") then cmd_execute(0, CMD_STEP) end
        if lurek.input.pressed("move_left") then cmd_execute(-CMD_STEP, 0) end
        if lurek.input.pressed("move_right") then cmd_execute(CMD_STEP, 0) end
        if lurek.input.pressed("undo") then cmd_undo() end
        if lurek.input.pressed("redo") then cmd_redo_action() end

    elseif state == STATE_P4 then
        if lurek.input.pressed("service") then svc_query() end

    elseif state == STATE_P5 then
        if lurek.input.pressed("factory") then factory_create() end
        for _, e in ipairs(factory_entities) do
            e.scale = lerp(e.scale, 1.0, dt * 8)
        end

    elseif state == STATE_P6 then
        fsm.timer = fsm.timer + dt
        if fsm.timer >= FSM_DURATIONS[fsm.state] then fsm_transition() end
        if lurek.input.pressed("spawn") then fsm_transition() end
        local c = FSM_COLORS[fsm.state]
        fsm_blend.r = lerp(fsm_blend.r, c[1], dt * 5)
        fsm_blend.g = lerp(fsm_blend.g, c[2], dt * 5)
        fsm_blend.b = lerp(fsm_blend.b, c[3], dt * 5)
    end

    update_particles(dt)
    update_log(dt)
end

-- ============================================================
-- Render: world-space demo visualizations
-- ============================================================
function lurek.draw()
    if state == STATE_TITLE then return end

    -- Demo area border
    lurek.render.setColor(0.15, 0.13, 0.2, 0.5)
    lurek.render.rectangle("fill", DEMO_X, DEMO_Y, DEMO_W, DEMO_H)
    lurek.render.setColor(0.3, 0.25, 0.4, 0.4)
    lurek.render.rectangle("line", DEMO_X, DEMO_Y, DEMO_W, DEMO_H)

    if state == STATE_P1 then
        -- EventBus: show listeners as boxes
        local lx, ly = DEMO_X + 30, DEMO_Y + 40
        for name, listener in pairs(bus_listeners) do
            local c = listener.col
            lurek.render.setColor(c[1], c[2], c[3], 0.3)
            lurek.render.rectangle("fill", lx, ly, 90, 36)
            lurek.render.setColor(c[1], c[2], c[3], 0.8)
            lurek.render.rectangle("line", lx, ly, 90, 36)
            lurek.render.print(name, lx + 6, ly + 10, 11)
            lx = lx + 100
            if lx > DEMO_X + DEMO_W - 100 then lx = DEMO_X + 30; ly = ly + 50 end
        end
        lurek.render.setColor(0.6, 0.6, 0.7, 0.7)
        lurek.render.print("A: player_hit  B: score_up  C: level_up", DEMO_X + 20, DEMO_Y + DEMO_H - 30, 10)

    elseif state == STATE_P2 then
        -- ObjectPool: draw pool objects
        for _, obj in ipairs(pool.objects) do
            if obj.active then
                lurek.render.setColor(obj.r, obj.g, obj.b, 0.9)
                local sz = 10 * obj.scale
                lurek.render.circle("fill", obj.x, obj.y, sz)
            end
        end
        local active, free = pool_counts()
        lurek.render.setColor(0.6, 0.8, 0.6, 0.8)
        lurek.render.print(string.format("Pool: %d/%d  Active: %d  Free: %d", #pool.objects, pool.max_size, active, free), DEMO_X + 20, DEMO_Y + DEMO_H - 30, 10)

    elseif state == STATE_P3 then
        -- CommandStack: draw square and trail
        for i, cmd in ipairs(cmd_stack) do
            local alpha = 0.1 + 0.4 * (i / #cmd_stack)
            lurek.render.setColor(0.3, 0.5, 0.8, alpha)
            lurek.render.rectangle("fill", cmd_square.x - 10 - cmd.dx * (#cmd_stack - i) / #cmd_stack, cmd_square.y - 10 - cmd.dy * (#cmd_stack - i) / #cmd_stack, 20, 20)
        end
        lurek.render.setColor(0.4, 0.7, 1, 1)
        lurek.render.rectangle("fill", cmd_square.x - 12, cmd_square.y - 12, 24, 24)
        lurek.render.setColor(1, 1, 1, 0.8)
        lurek.render.rectangle("line", cmd_square.x - 12, cmd_square.y - 12, 24, 24)
        lurek.render.setColor(0.6, 0.6, 0.7, 0.7)
        lurek.render.print(string.format("Stack: %d  Redo: %d", #cmd_stack, #cmd_redo), DEMO_X + 20, DEMO_Y + DEMO_H - 30, 10)

    elseif state == STATE_P4 then
        -- ServiceLocator: draw services as cards
        local sy = DEMO_Y + 30
        for _, svc in ipairs(services) do
            local c = svc.color
            lurek.render.setColor(c[1], c[2], c[3], 0.2)
            lurek.render.rectangle("fill", DEMO_X + 30, sy, 200, 40)
            lurek.render.setColor(c[1], c[2], c[3], 0.8)
            lurek.render.rectangle("line", DEMO_X + 30, sy, 200, 40)
            lurek.render.print(svc.name, DEMO_X + 40, sy + 6, 12)
            local stat_col = svc.status == "ready" and {0.3, 1, 0.4} or {1, 0.6, 0.2}
            lurek.render.setColor(stat_col[1], stat_col[2], stat_col[3], 0.9)
            lurek.render.print("[" .. svc.status .. "]", DEMO_X + 40, sy + 22, 10)
            sy = sy + 52
        end
        lurek.render.setColor(0.6, 0.6, 0.7, 0.7)
        lurek.render.print("S: Query all services", DEMO_X + 20, DEMO_Y + DEMO_H - 30, 10)

    elseif state == STATE_P5 then
        -- Factory: draw created entities
        for _, e in ipairs(factory_entities) do
            local sz = 10 * e.scale
            lurek.render.setColor(e.r, e.g, e.b, 0.9)
            lurek.render.circle("fill", e.x, e.y, sz)
            lurek.render.setColor(1, 1, 1, 0.7)
            lurek.render.print(e.name, e.x - 16, e.y - sz - 12, 9)
        end
        lurek.render.setColor(0.6, 0.6, 0.7, 0.7)
        lurek.render.print(string.format("F: Create entity  (%d alive)", #factory_entities), DEMO_X + 20, DEMO_Y + DEMO_H - 30, 10)

    elseif state == STATE_P6 then
        -- SimpleState: traffic light
        local cx = DEMO_X + DEMO_W / 2
        local cy_base = DEMO_Y + 40
        lurek.render.setColor(0.12, 0.12, 0.15, 0.9)
        lurek.render.rectangle("fill", cx - 30, cy_base, 60, 170)
        lurek.render.setColor(0.25, 0.25, 0.3, 0.8)
        lurek.render.rectangle("line", cx - 30, cy_base, 60, 170)
        local light_states = { "RED", "YELLOW", "GREEN" }
        for i, ls in ipairs(light_states) do
            local ly = cy_base + 10 + (i - 1) * 55
            local c = FSM_COLORS[ls]
            local is_active = (fsm.state == ls)
            local alpha = is_active and 1.0 or 0.15
            lurek.render.setColor(c[1], c[2], c[3], alpha)
            lurek.render.circle("fill", cx, ly + 20, 18)
            if is_active then
                lurek.render.setColor(fsm_blend.r, fsm_blend.g, fsm_blend.b, 0.3)
                lurek.render.circle("fill", cx, ly + 20, 26)
            end
        end
        local progress = fsm.timer / FSM_DURATIONS[fsm.state]
        lurek.render.setColor(0.5, 0.5, 0.6, 0.6)
        lurek.render.rectangle("fill", cx - 40, cy_base + 180, 80, 6)
        lurek.render.setColor(fsm_blend.r, fsm_blend.g, fsm_blend.b, 0.9)
        lurek.render.rectangle("fill", cx - 40, cy_base + 180, 80 * progress, 6)
        lurek.render.setColor(0.6, 0.6, 0.7, 0.7)
        lurek.render.print("Space: Force transition", DEMO_X + 20, DEMO_Y + DEMO_H - 30, 10)
    end

    -- Particles (world-space)
    for _, p in ipairs(particles) do
        lurek.render.setColor(p.r, p.g, p.b, p.a)
        lurek.render.circle("fill", p.x, p.y, p.size)
    end
end

-- ============================================================
-- Render UI: tabs, pseudocode panel, log, HUD
-- ============================================================
function lurek.draw_ui()
    -- Title screen
    if state == STATE_TITLE then
        local pulse = 0.7 + 0.3 * math.sin(title_timer * 2.5)
        lurek.render.setColor(0.5, 0.4, 1.0, pulse)
        lurek.render.print("PATTERNS DEMO", SCREEN_W / 2 - 110, SCREEN_H / 2 - 70, 28)
        lurek.render.setColor(0.7, 0.6, 0.9, 0.8)
        lurek.render.print("DESIGN PATTERNS IN ACTION", SCREEN_W / 2 - 130, SCREEN_H / 2 - 30, 16)
        lurek.render.setColor(0.6, 0.6, 0.7, 0.5 + 0.3 * math.sin(title_timer * 1.8))
        lurek.render.print("Press 1-6 to select a pattern", SCREEN_W / 2 - 130, SCREEN_H / 2 + 30, 14)
        lurek.render.setColor(0.4, 0.4, 0.5, 0.6)
        lurek.render.print("1: EventBus   2: ObjectPool   3: CommandStack", SCREEN_W / 2 - 180, SCREEN_H / 2 + 70, 11)
        lurek.render.print("4: ServiceLocator   5: Factory   6: SimpleState", SCREEN_W / 2 - 180, SCREEN_H / 2 + 88, 11)
        lurek.render.setColor(0.3, 0.3, 0.4, 0.5)
        lurek.render.print("ESC to quit", SCREEN_W / 2 - 35, SCREEN_H - 40, 12)
        return
    end

    -- Tab bar
    lurek.render.setColor(0.1, 0.08, 0.14, 0.95)
    lurek.render.rectangle("fill", 0, 0, SCREEN_W, TAB_H)
    local tw = SCREEN_W / 6
    for i, ps in ipairs(pattern_order) do
        local tx = (i - 1) * tw
        local is_active = (ps == state)
        if is_active then
            lurek.render.setColor(0.2, 0.15, 0.35, 1)
            lurek.render.rectangle("fill", tx, 0, tw, TAB_H)
        end
        local c_a = is_active and 1.0 or 0.5
        lurek.render.setColor(0.6, 0.5, 1.0, c_a)
        lurek.render.print(i .. ": " .. pattern_names[ps], tx + 8, 9, 11)
    end
    -- Active tab indicator (tweened)
    lurek.render.setColor(0.6, 0.4, 1, 0.9)
    lurek.render.rectangle("fill", tab_slide_x, TAB_H - 3, tw, 3)

    -- Pattern description
    lurek.render.setColor(0.08, 0.07, 0.12, 0.85)
    lurek.render.rectangle("fill", 0, TAB_H, SCREEN_W, 30)
    lurek.render.setColor(0.7, 0.65, 0.9, 0.9)
    local desc = pattern_desc[state] or ""
    lurek.render.print(desc, 12, TAB_H + 8, 11)

    -- Pseudocode panel
    lurek.render.setColor(0.1, 0.09, 0.15, 0.9)
    lurek.render.rectangle("fill", CODE_X, CODE_Y, CODE_W, CODE_H)
    lurek.render.setColor(0.3, 0.25, 0.45, 0.5)
    lurek.render.rectangle("line", CODE_X, CODE_Y, CODE_W, CODE_H)
    lurek.render.setColor(0.5, 0.45, 0.7, 0.9)
    lurek.render.print("Pseudocode", CODE_X + 8, CODE_Y + 6, 12)
    local lines = pseudocode[state] or {}
    for i, line in ipairs(lines) do
        local is_comment = (line:sub(1, 2) == "--")
        if is_comment then
            lurek.render.setColor(0.4, 0.6, 0.4, 0.7)
        else
            lurek.render.setColor(0.7, 0.8, 0.9, 0.85)
        end
        lurek.render.print(line, CODE_X + 10, CODE_Y + 24 + (i - 1) * 15, 10)
    end

    -- Log window
    lurek.render.setColor(0.06, 0.05, 0.09, 0.92)
    lurek.render.rectangle("fill", 0, LOG_Y, SCREEN_W, LOG_H)
    lurek.render.setColor(0.25, 0.2, 0.35, 0.5)
    lurek.render.line(0, LOG_Y, SCREEN_W, LOG_Y)
    lurek.render.setColor(0.45, 0.4, 0.6, 0.8)
    lurek.render.print("Log", 8, LOG_Y + 4, 10)
    local max_visible = math.floor((LOG_H - 20) / 13)
    for i = 1, math.min(#log_entries, max_visible) do
        local entry = log_entries[i]
        local alpha = math.min(entry.timer / 2.0, 1.0)
        lurek.render.setColor(entry.r, entry.g, entry.b, alpha * 0.9)
        lurek.render.print(entry.text, 12, LOG_Y + 16 + (i - 1) * 13, 9)
    end

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.6, 0.7)
    lurek.render.print(string.format("FPS: %d", fps), SCREEN_W - 70, TAB_H + 8, 10)
end
