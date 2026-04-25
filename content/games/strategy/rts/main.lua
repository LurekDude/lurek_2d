-- ============================================================
-- RTS — Real-time strategy with base building and unit command
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/rts
-- ============================================================

local W, H = 900, 640

-- Camera
local cam = { x = 0, y = 0, speed = 280 }

-- Resources
local resources = { gold = 200, wood = 100 }

-- Entity types
local UNIT  = "unit"
local BUILD = "building"
local ENEMY = "enemy"

local entities = {}
local selected = {}   -- selected unit ids
local next_id  = 1

-- UI state
local ui_panel_h = 90
local state      = "play"   -- play | gameover | victory
local wave       = 0
local wave_timer = 30.0
local score      = 0

-- Particle systems
local death_sparks = nil
local select_ring  = nil

-- Map (simple flat with some resource nodes)
local MAP_W, MAP_H = 1800, 1200
local resource_nodes = {
    { x = 300,  y = 200,  gold = 50,  wood = 0  },
    { x = 700,  y = 400,  gold = 0,   wood = 80 },
    { x = 1200, y = 300,  gold = 100, wood = 0  },
    { x = 900,  y = 700,  gold = 0,   wood = 120},
    { x = 1500, y = 500,  gold = 80,  wood = 0  },
}

local function new_id()
    local id = next_id
    next_id = next_id + 1
    return id
end

local function spawn_unit(x, y, team)
    local e = {
        id     = new_id(),
        kind   = UNIT,
        team   = team,
        x      = x,
        y      = y,
        tx     = x,
        ty     = y,
        speed  = team == "player" and 80 or 60,
        hp     = team == "player" and 30 or 20,
        maxHp  = team == "player" and 30 or 20,
        atk    = team == "player" and 5  or 4,
        atkCD  = 0,
        state  = "idle",  -- idle | move | attack
        target = nil,
    }
    entities[#entities + 1] = e
    return e
end

local function spawn_building(x, y, btype)
    local e = {
        id    = new_id(),
        kind  = BUILD,
        team  = "player",
        btype = btype,
        x     = x,
        y     = y,
        hp    = btype == "base" and 200 or 80,
        maxHp = btype == "base" and 200 or 80,
        trainCD = 0,
    }
    entities[#entities + 1] = e
    return e
end

-- Initial setup
local function init_game()
    entities = {}
    selected = {}
    resources = { gold = 200, wood = 100 }
    wave      = 0
    wave_timer = 25.0
    score     = 0
    state     = "play"
    cam       = { x = 0, y = 0, speed = 280 }

    -- Player base + starting units
    spawn_building(120, 560, "base")
    spawn_building(240, 560, "barracks")
    spawn_unit(200, 460, "player")
    spawn_unit(250, 460, "player")
    spawn_unit(300, 460, "player")
end

local function find_entity(id)
    for _, e in ipairs(entities) do if e.id == id then return e end end
end

local function dist(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx*dx + dy*dy)
end

local function find_nearest_enemy(e, team)
    local best, bd = nil, 1e9
    local eteam = team == "player" and "enemy" or "player"
    for _, other in ipairs(entities) do
        if other.team == eteam and other.hp > 0 then
            local d = dist(e.x, e.y, other.x, other.y)
            if d < bd then best = other ; bd = d end
        end
    end
    return best, bd
end

local function spawn_wave(n)
    -- Enemies come from top-right
    for i = 1, n do
        local e = spawn_unit(MAP_W - 100 + math.random(-80, 80), 60 + i * 50, "enemy")
        e.tx = 150
        e.ty = 550
        e.state = "move"
    end
end

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("select",    "mouse1")
lurek.input.bind("order",     "mouse2")
lurek.input.bind("train",     "t")
lurek.input.bind("cam_up",    "w")
lurek.input.bind("cam_down",  "s")
lurek.input.bind("cam_left",  "a")
lurek.input.bind("cam_right", "d")
lurek.input.bind("quit",      "escape")

-- ── Init ──────────────────────────────────────────────────

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
    lurek.window.setTitle("RTS — Lurek2D")
    lurek.render.setBackgroundColor(0.06, 0.12, 0.06)

    death_sparks = lurek.particle.newSystem({
        maxParticles = 30,
        emitRate     = 0,
        lifetime     = { 0.2, 0.6 },
        speed        = { 30, 100 },
        startColor   = { 0.9, 0.4, 0.1, 1.0 },
        endColor     = { 0.5, 0.1, 0.0, 0.0 },
        startSize    = 5, endSize = 1,
        spread       = math.pi * 2,
    })

    select_ring = lurek.particle.newSystem({
        maxParticles = 20,
        emitRate     = 0,
        lifetime     = { 0.3, 0.5 },
        speed        = { 10, 30 },
        startColor   = { 0.3, 0.8, 1.0, 0.8 },
        endColor     = { 0.1, 0.4, 0.7, 0.0 },
        startSize    = 3, endSize = 1,
        spread       = math.pi * 2,
    })

    math.randomseed(os.time())
    init_game()
end

-- ── Process ───────────────────────────────────────────────
function lurek.process(dt)
    if death_sparks then death_sparks:update(dt) end
    if select_ring  then select_ring:update(dt)  end

    if lurek.input.wasActionPressed("quit") then lurek.event.quit() return end
    if state ~= "play" then return end

    -- Camera scroll
    if lurek.input.isActionDown("cam_up")    then cam.y = cam.y - cam.speed * dt end
    if lurek.input.isActionDown("cam_down")  then cam.y = cam.y + cam.speed * dt end
    if lurek.input.isActionDown("cam_left")  then cam.x = cam.x - cam.speed * dt end
    if lurek.input.isActionDown("cam_right") then cam.x = cam.x + cam.speed * dt end
    cam.x = math.max(0, math.min(MAP_W - W, cam.x))
    cam.y = math.max(0, math.min(MAP_H - H + ui_panel_h, cam.y))

    -- Mouse world pos
    local mx, my = lurek.input.getPosition()
    local wx, wy = mx + cam.x, my + cam.y

    -- Select units
    if lurek.input.wasActionPressed("select") then
        selected = {}
        for _, e in ipairs(entities) do
            if e.team == "player" and e.kind == UNIT and e.hp > 0 then
                if math.abs(e.x - wx) < 14 and math.abs(e.y - wy) < 14 then
                    selected[#selected + 1] = e.id
                    if select_ring then select_ring:emit(e.x - cam.x, e.y - cam.y, 5) end
                end
            end
        end
    end

    -- Order selected units
    if lurek.input.wasActionPressed("order") then
        for _, id in ipairs(selected) do
            local e = find_entity(id)
            if e and e.hp > 0 then
                e.tx    = wx + math.random(-20, 20)
                e.ty    = wy + math.random(-20, 20)
                e.state = "move"
            end
        end
    end

    -- Train unit at barracks
    if lurek.input.wasActionPressed("train") then
        for _, e in ipairs(entities) do
            if e.kind == BUILD and e.btype == "barracks" and e.trainCD <= 0 then
                if resources.gold >= 50 then
                    resources.gold = resources.gold - 50
                    spawn_unit(e.x + math.random(-30, 30), e.y - 60, "player")
                    e.trainCD = 4.0
                end
                break
            end
        end
    end

    -- Wave timer
    wave_timer = wave_timer - dt
    if wave_timer <= 0 then
        wave       = wave + 1
        wave_timer = 20.0 + wave * 5
        spawn_wave(3 + wave * 2)
        if wave >= 5 then
            -- Check if player still has base
        end
    end

    -- Train cooldowns
    for _, e in ipairs(entities) do
        if e.kind == BUILD and e.trainCD and e.trainCD > 0 then
            e.trainCD = e.trainCD - dt
        end
    end

    -- Resource node harvesting (units near nodes auto-collect over time)
    for _, e in ipairs(entities) do
        if e.kind == UNIT and e.team == "player" and e.hp > 0 then
            for _, node in ipairs(resource_nodes) do
                if node.gold > 0 or node.wood > 0 then
                    if dist(e.x, e.y, node.x, node.y) < 60 then
                        local harvest = math.min(1, node.gold) * dt * 8
                        resources.gold = resources.gold + harvest
                        node.gold = math.max(0, node.gold - harvest)
                        harvest = math.min(1, node.wood) * dt * 8
                        resources.wood = resources.wood + harvest
                        node.wood = math.max(0, node.wood - harvest)
                    end
                end
            end
        end
    end

    -- AI / unit movement
    for _, e in ipairs(entities) do
        if e.hp <= 0 then goto continue end

        if e.kind == UNIT then
            -- Find attack target
            local target, d = find_nearest_enemy(e, e.team)
            local attack_range = 50

            if target and d < attack_range then
                e.state  = "attack"
                e.target = target.id
                e.atkCD  = e.atkCD - dt
                if e.atkCD <= 0 then
                    e.atkCD = 1.0
                    target.hp = target.hp - e.atk
                    if target.hp <= 0 then
                        if death_sparks then death_sparks:emit(target.x - cam.x, target.y - cam.y, 6) end
                        if target.team == "enemy" then score = score + 10 end
                    end
                end
            else
                e.state  = "move"
                e.target = nil
                -- Enemy AI: move toward player base
                if e.team == "enemy" then
                    local base = nil
                    for _, b in ipairs(entities) do
                        if b.kind == BUILD and b.team == "player" and b.hp > 0 then
                            base = b ; break
                        end
                    end
                    if base then
                        e.tx = base.x + math.random(-40, 40)
                        e.ty = base.y + math.random(-40, 40)
                    end
                end
            end

            if e.state == "move" then
                local dx, dy = e.tx - e.x, e.ty - e.y
                local d2 = math.sqrt(dx*dx + dy*dy)
                if d2 > 4 then
                    e.x = e.x + (dx / d2) * e.speed * dt
                    e.y = e.y + (dy / d2) * e.speed * dt
                end
            end
        end

        -- Check if player base destroyed
        if e.kind == BUILD and e.team == "player" and e.btype == "base" and e.hp <= 0 then
            state = "gameover"
        end

        ::continue::
    end

    -- Remove dead entities (keep buildings at 0 HP visible briefly)
    for i = #entities, 1, -1 do
        if entities[i].hp <= 0 and entities[i].kind == UNIT then
            table.remove(entities, i)
        end
    end

    -- Victory: survive 5 waves
    if wave >= 5 then
        local enemies_left = 0
        for _, e in ipairs(entities) do
            if e.team == "enemy" and e.hp > 0 then enemies_left = enemies_left + 1 end
        end
        if enemies_left == 0 then state = "victory" end
    end
end

-- ── Render world ──────────────────────────────────────────
function lurek.draw()
    -- Map background tint
    rect(0, 0, W, H - ui_panel_h, { color = {0.08,0.14,0.08,1} })

    -- Resource nodes
    for _, node in ipairs(resource_nodes) do
        if node.gold > 0 or node.wood > 0 then
            local sx, sy = node.x - cam.x, node.y - cam.y
            if sx > -20 and sx < W and sy > -20 and sy < H then
                local col = node.gold > 0 and {0.9,0.75,0.1,1} or {0.4,0.7,0.3,1}
                circ(sx, sy, 12, { color = col, segments = 8 })
            end
        end
    end

    -- Entities
    for _, e in ipairs(entities) do
        if e.hp <= 0 then goto skip end
        local sx, sy = e.x - cam.x, e.y - cam.y
        if sx < -30 or sx > W + 30 or sy < -30 or sy > H then goto skip end

        if e.kind == BUILD then
            local col = e.btype == "base" and {0.2,0.5,0.8,1} or {0.4,0.6,0.3,1}
            local size = e.btype == "base" and 36 or 24
            rect(sx - size/2, sy - size/2, size, size, { color = col })
        elseif e.kind == UNIT then
            local col = e.team == "player" and {0.3,0.7,1.0,1} or {0.8,0.3,0.2,1}
            circ(sx, sy, 10, { color = col, segments = 8 })
            -- HP bar
            rect(sx - 10, sy - 16, 20, 3, { color = {0.3,0,0,1} })
            rect(sx - 10, sy - 16, math.floor(20 * e.hp / e.maxHp), 3, { color = {0.2,0.8,0.2,1} })
        end

        -- Selection ring
        for _, id in ipairs(selected) do
            if id == e.id then
                circ(sx, sy, 14, { color = {0.3,0.9,1.0,0.4}, segments = 10 })
            end
        end

        ::skip::
    end

    if death_sparks then death_sparks:draw() end
    if select_ring  then select_ring:draw()  end
end

-- ── Render UI ─────────────────────────────────────────────
function lurek.draw_ui()
    -- Panel
    rect(0, H - ui_panel_h, W, ui_panel_h, { color = {0.1,0.1,0.1,0.9} })

    text_("Gold: " .. math.floor(resources.gold), 10, H - ui_panel_h + 8, { color = {1,0.85,0.2,1}, size = 14 })
    text_("Wood: " .. math.floor(resources.wood), 130, H - ui_panel_h + 8, { color = {0.5,0.8,0.3,1}, size = 14 })
    text_("Wave: " .. wave .. "/5  Next: " .. math.floor(wave_timer) .. "s", 260, H - ui_panel_h + 8, { color = {0.8,0.6,0.6,1}, size = 14 })
    text_("Score: " .. score, 480, H - ui_panel_h + 8, { color = {1,1,1,1}, size = 14 })
    text_("T=train unit(50g)  WASD=camera  LMB=select  RMB=order", 10, H - ui_panel_h + 28, { color = {0.5,0.5,0.5,1}, size = 12 })

    if #selected > 0 then
        text_("Selected: " .. #selected .. " units", 10, H - ui_panel_h + 48, { color = {0.4,0.8,1.0,1}, size = 12 })
    end

    if state == "gameover" then
        rect(200, 200, 400, 120, { color = {0,0,0,0.85} })
        text_("BASE DESTROYED", 250, 225, { color = {0.9,0.2,0.2,1}, size = 28 })
        text_("Score: " .. score, 330, 270, { color = {1,1,1,1}, size = 18 })
    elseif state == "victory" then
        rect(200, 200, 400, 120, { color = {0,0,0,0.85} })
        text_("VICTORY!", 290, 225, { color = {1,0.9,0.2,1}, size = 32 })
        text_("Score: " .. score, 330, 270, { color = {1,1,1,1}, size = 18 })
    end
end
