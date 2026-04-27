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
local function rect(...)
    local a, b, c, d, e, f, g, h = ...
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
local function circ(...)
    local a, b, c, d, e, f, g, h = ...
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

-- ============================================================================
--  Infiltration â€” Gadget/stealth puzzle infiltration game
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/infiltration
--
--  Controls (bound as input actions â€” see lurek.init):
--    up/down/left/right : W/S/A/D or arrow keys
--    gadget1            : 1  (Keycard â€” opens keycard doors)
--    gadget2            : 2  (EMP â€” disables cameras 8s)
--    gadget3            : 3  (Lockpick â€” opens mechanical doors)
--    interact           : E  (hack terminal / hack door sequence)
--    quit               : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween
-- ============================================================================

-- â”€â”€ Constants â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- drawText shim: old API used in this demo (render.drawText -> lurek.render.print + setColor)
local function drawText(text, x, y, size, r, g, b, a)
    if r then lurek.render.setColor(r, g or 1, b or 1, a or 1) end
    text_(text, x, y, size or 14)
end
local SCREEN_W, SCREEN_H = 800, 600
local TILE               = 40
local GRID_COLS          = 20
local GRID_ROWS          = 15
local MISSION_TIME       = 180

-- Tile types
local T_FLOOR    = 0
local T_WALL     = 1
local T_DOOR_KEY = 2   -- keycard door
local T_DOOR_HCK = 3   -- hack door
local T_DOOR_LCK = 4   -- lockpick door
local T_TERMINAL = 5   -- data terminal
local T_VAULT    = 6   -- bonus vault
local T_EXIT     = 7   -- escape exit
local T_CAMERA   = 8   -- camera mount (wall with camera)

-- Colors
local C_WALL     = {0.12, 0.12, 0.18}
local C_FLOOR    = {0.08, 0.08, 0.12}
local C_FLOOR2   = {0.10, 0.10, 0.15}
local C_DOOR_KEY = {0.2,  0.6,  0.9}
local C_DOOR_HCK = {0.9,  0.7,  0.1}
local C_DOOR_LCK = {0.7,  0.3,  0.1}
local C_TERMINAL = {0.1,  0.9,  0.4}
local C_VAULT    = {0.9,  0.8,  0.1}
local C_EXIT     = {0.2,  0.9,  0.2}
local C_PLAYER   = {0.3,  0.8,  1.0}
local C_CAM_BODY = {0.8,  0.2,  0.2}
local C_CAM_CONE = {1.0,  0.3,  0.3, 0.15}
local C_CAM_OFF  = {0.3,  0.3,  0.3, 0.08}

-- â”€â”€ States â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local STATE = { TITLE = 1, PLAYING = 2, HACKING = 3, WON = 4, CAUGHT = 5 }
local state = STATE.TITLE

-- â”€â”€ Map layout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 20x15 grid: 1=wall, 0=floor, 2=keycard door, 3=hack door, 4=lock door,
-- 5=terminal, 6=vault, 7=exit, 8=camera mount
local MAP = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},
    {1,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},
    {1,0,0,0,2,0,0,8,0,3,0,0,8,0,4,0,0,0,0,1},
    {1,1,1,2,1,1,0,0,1,1,1,0,0,1,1,4,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,1},
    {1,0,8,0,0,1,1,1,0,0,0,1,1,1,0,0,8,0,0,1},
    {1,0,0,0,0,1,6,1,0,0,0,1,5,1,0,0,0,0,0,1},
    {1,0,0,0,0,1,0,4,0,0,0,3,0,1,0,0,0,0,0,1},
    {1,0,8,0,0,1,1,1,0,0,0,1,1,1,0,0,8,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,2,1,1,0,0,1,1,1,0,0,1,1,4,1,1,1,1},
    {1,0,0,0,2,0,0,8,0,3,0,0,8,0,4,0,0,0,0,1},
    {1,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

-- Working copy of map (doors get removed when opened)
local map = {}

-- â”€â”€ Camera definitions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local cameras = {}
local CAM_RANGE     = 4        -- tiles of vision
local CAM_HALF_ARC  = math.pi / 4  -- 45 deg half-arc
local CAM_ROTATE_SP = 0.8      -- radians/sec
local CAM_DISABLE_T = 8.0      -- seconds EMP lasts

-- â”€â”€ Player state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local player = { gx = 2, gy = 2, move_cd = 0 }
local MOVE_COOLDOWN = 0.12

-- Gadgets: {name, uses, max_uses, color}
local gadgets = {
    { name = "Keycard",  uses = 3, max = 3, color = {0.2, 0.6, 0.9} },
    { name = "EMP",      uses = 2, max = 2, color = {0.9, 0.4, 1.0} },
    { name = "Lockpick", uses = 3, max = 3, color = {0.7, 0.3, 0.1} },
}

-- Alert system
local alert          = 0
local alert_decay    = 2.0    -- per second
local alert_raise    = 25.0   -- per second when detected
local alert_bar_glow = 0

-- Mission state
local timer_left   = MISSION_TIME
local has_data     = false
local vault_open   = false
local msg_text     = ""
local msg_timer    = 0

-- Hack mini-game state
local hack = { sequence = {}, input_idx = 1, target_door = nil, timer = 0 }

-- Particles
local emp_particles  = nil ---@type LParticleSystem?
local hack_particles = nil ---@type LParticleSystem?

-- Tween state
local tween_alert_pulse = nil
local tween_cam_fade    = nil

-- â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

local function show_msg(text, dur)
    msg_text  = text
    msg_timer = dur or 2.0
end

local function tile_at(gx, gy)
    if gy < 1 or gy > GRID_ROWS or gx < 1 or gx > GRID_COLS then return T_WALL end
    return map[gy][gx]
end

local function is_walkable(gx, gy)
    local t = tile_at(gx, gy)
    return t == T_FLOOR or t == T_TERMINAL or t == T_VAULT or t == T_EXIT or t == T_CAMERA
end

local function init_map()
    map = {}
    for y = 1, GRID_ROWS do
        map[y] = {}
        for x = 1, GRID_COLS do
            map[y][x] = MAP[y][x]
        end
    end
end

local function init_cameras()
    cameras = {}
    for y = 1, GRID_ROWS do
        for x = 1, GRID_COLS do
            if MAP[y][x] == T_CAMERA then
                map[y][x] = T_FLOOR  -- camera mount becomes walkable floor
                cameras[#cameras + 1] = {
                    gx = x, gy = y,
                    angle = 0,
                    dir = 1,            -- rotation direction
                    disabled = 0,       -- time remaining disabled
                    sweep_min = -math.pi / 3,
                    sweep_max =  math.pi / 3,
                }
            end
        end
    end
    -- Alternate initial angles for variety
    for i, cam in ipairs(cameras) do
        cam.angle = (i % 4) * (math.pi / 2)
        cam.dir   = (i % 2 == 0) and -1 or 1
    end
end

local function reset_game()
    init_map()
    init_cameras()
    player.gx      = 2
    player.gy       = 2
    player.move_cd  = 0
    alert           = 0
    alert_bar_glow  = 0
    timer_left      = MISSION_TIME
    has_data        = false
    vault_open      = false
    msg_text        = ""
    msg_timer       = 0
    hack.sequence   = {}
    hack.input_idx  = 1
    hack.target_door = nil

    gadgets[1].uses = gadgets[1].max
    gadgets[2].uses = gadgets[2].max
    gadgets[3].uses = gadgets[3].max
end

-- â”€â”€ Camera vision check â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function cam_sees_player(cam)
    if cam.disabled > 0 then return false end
    local dx = player.gx - cam.gx
    local dy = player.gy - cam.gy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > CAM_RANGE then return false end
    local ang_to_player = math.atan2(dy, dx)
    local diff = ang_to_player - cam.angle
    -- normalize to [-pi, pi]
    while diff >  math.pi do diff = diff - 2 * math.pi end
    while diff < -math.pi do diff = diff + 2 * math.pi end
    if math.abs(diff) > CAM_HALF_ARC then return false end
    -- Simple ray: check tiles between camera and player for walls
    local steps = math.floor(dist)
    for s = 1, steps do
        local t = s / dist
        local cx = math.floor(cam.gx + dx * t + 0.5)
        local cy = math.floor(cam.gy + dy * t + 0.5)
        if tile_at(cx, cy) == T_WALL then return false end
    end
    return true
end

-- â”€â”€ Generate hack sequence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function start_hack(door_gx, door_gy)
    hack.sequence = {}
    for i = 1, 4 do
        hack.sequence[i] = math.random(1, 4)
    end
    hack.input_idx   = 1
    hack.target_door = { gx = door_gx, gy = door_gy }
    hack.timer       = 0
    state = STATE.HACKING
    show_msg("HACK: Match the wire sequence!", 10)
end

-- â”€â”€ lurek.init â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

function lurek.init()
    lurek.window.setTitle("Infiltration â€” Lurek2D")
    lurek.render.setBackgroundColor(0.02, 0.02, 0.04)

    lurek.input.bind("up",      {"w", "up"})
    lurek.input.bind("down",    {"s", "down"})
    lurek.input.bind("left",    {"a", "left"})
    lurek.input.bind("right",   {"d", "right"})
    lurek.input.bind("gadget1", {"1"})
    lurek.input.bind("gadget2", {"2"})
    lurek.input.bind("gadget3", {"3"})
    lurek.input.bind("interact",{"e"})
    lurek.input.bind("hack1",   {"1"})
    lurek.input.bind("hack2",   {"2"})
    lurek.input.bind("hack3",   {"3"})
    lurek.input.bind("hack4",   {"4"})
    lurek.input.bind("quit",    {"escape"})

    -- Particle emitters
    emp_particles = lurek.particle.newSystem({
        max       = 60,
        lifetime  = {0.4, 0.8},
        speed     = {80, 160},
        spread    = math.pi * 2,
        colors    = {{0.6, 0.3, 1.0, 0.9}, {0.3, 0.1, 0.6, 0.0}},
        sizes     = {4, 1},
    })

    hack_particles = lurek.particle.newSystem({
        max       = 40,
        lifetime  = {0.2, 0.5},
        speed     = {40, 100},
        spread    = math.pi * 2,
        colors    = {{1.0, 0.9, 0.2, 1.0}, {1.0, 0.4, 0.0, 0.0}},
        sizes     = {3, 1},
    })
end

-- â”€â”€ lurek.ready â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function _ready_setup()
    reset_game()
end

-- â”€â”€ lurek.process â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function lurek.process(dt)
    -- Quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- Message timer
    if msg_timer > 0 then msg_timer = msg_timer - dt end

    -- Particles
    local emp = emp_particles
    if emp ~= nil then
        emp:update(dt)
    end

    local hack_ps = hack_particles
    if hack_ps ~= nil then
        hack_ps:update(dt)
    end

    -- â”€â”€ TITLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if state == STATE.TITLE then
        if lurek.input.wasActionPressed("interact") then
            reset_game()
            state = STATE.PLAYING
        end
        return
    end

    -- â”€â”€ WON / CAUGHT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if state == STATE.WON or state == STATE.CAUGHT then
        if lurek.input.wasActionPressed("interact") then
            state = STATE.TITLE
        end
        return
    end

    -- â”€â”€ HACKING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if state == STATE.HACKING then
        hack.timer = hack.timer + dt
        -- Check number key presses
        for k = 1, 4 do
            if lurek.input.wasActionPressed("hack" .. k) then
                if hack.sequence[hack.input_idx] == k then
                    hack.input_idx = hack.input_idx + 1
                    local px = player.gx * TILE - TILE / 2
                    local py = player.gy * TILE - TILE / 2
                    local hack_ps = hack_particles
                    if hack_ps ~= nil then
                        ---@diagnostic disable-next-line
                        hack_ps:moveTo(px, py)
                        hack_ps:emit(8)
                    end
                    if hack.input_idx > #hack.sequence then
                        -- Hack success
                        local dg = hack.target_door
                        if dg then map[dg.gy][dg.gx] = T_FLOOR end
                        show_msg("HACK COMPLETE", 1.5)
                        state = STATE.PLAYING
                    end
                else
                    -- Failed â€” reset sequence
                    hack.input_idx = 1
                    show_msg("WRONG WIRE! Restarting sequence...", 1.5)
                    alert = math.min(100, alert + 10)
                end
            end
        end
        -- Alert still ticks during hacking
        update_alert_decay(dt)
        update_cameras(dt)
        return
    end

    -- â”€â”€ PLAYING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    -- Timer
    timer_left = timer_left - dt
    if timer_left <= 0 then
        timer_left = 0
        state = STATE.CAUGHT
        show_msg("TIME'S UP â€” MISSION FAILED", 5)
        return
    end

    -- Player movement
    player.move_cd = math.max(0, player.move_cd - dt)
    if player.move_cd <= 0 then
        local dx, dy = 0, 0
        if lurek.input.isActionDown("up")    then dy = -1 end
        if lurek.input.isActionDown("down")  then dy =  1 end
        if lurek.input.isActionDown("left")  then dx = -1 end
        if lurek.input.isActionDown("right") then dx =  1 end
        if dx ~= 0 or dy ~= 0 then
            -- Try horizontal first, then vertical
            if dx ~= 0 and is_walkable(player.gx + dx, player.gy) then
                player.gx = player.gx + dx
                player.move_cd = MOVE_COOLDOWN
            elseif dy ~= 0 and is_walkable(player.gx, player.gy + dy) then
                player.gy = player.gy + dy
                player.move_cd = MOVE_COOLDOWN
            end
        end
    end

    -- Gadget usage
    if lurek.input.wasActionPressed("gadget1") then
        use_gadget(1)
    elseif lurek.input.wasActionPressed("gadget2") then
        use_gadget(2)
    elseif lurek.input.wasActionPressed("gadget3") then
        use_gadget(3)
    end

    -- Interact
    if lurek.input.wasActionPressed("interact") then
        do_interact()
    end

    -- Update cameras
    update_cameras(dt)

    -- Check detection
    local detected = false
    for _, cam in ipairs(cameras) do
        if cam_sees_player(cam) then
            detected = true
            break
        end
    end

    -- Alert
    if detected then
        alert = math.min(100, alert + alert_raise * dt)
        alert_bar_glow = 1.0
    else
        update_alert_decay(dt)
    end

    -- Alert bar glow decay
    if alert_bar_glow > 0 then
        alert_bar_glow = math.max(0, alert_bar_glow - dt * 2)
    end

    -- Caught
    if alert >= 100 then
        state = STATE.CAUGHT
        show_msg("ALERT MAXIMUM â€” YOU'VE BEEN CAUGHT!", 5)
        return
    end

    -- Check win â€” on exit tile with data
    if tile_at(player.gx, player.gy) == T_EXIT and has_data then
        state = STATE.WON
        local bonus = vault_open and " + VAULT BONUS!" or ""
        show_msg("MISSION COMPLETE! Data extracted" .. bonus, 5)
    end
end

-- â”€â”€ Helpers called from process â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

function update_alert_decay(dt)
    if alert > 0 then
        alert = math.max(0, alert - alert_decay * dt)
    end
end

function update_cameras(dt)
    for _, cam in ipairs(cameras) do
        if cam.disabled > 0 then
            cam.disabled = cam.disabled - dt
            if cam.disabled < 0 then cam.disabled = 0 end
        else
            cam.angle = cam.angle + CAM_ROTATE_SP * cam.dir * dt
            -- Reverse at sweep limits
            if cam.angle > cam.sweep_max + math.pi then
                cam.dir = -cam.dir
            elseif cam.angle < cam.sweep_min - math.pi then
                cam.dir = -cam.dir
            end
        end
    end
end

function use_gadget(idx)
    local g = gadgets[idx]
    if g.uses <= 0 then
        show_msg(g.name .. " â€” no uses remaining!", 1.5)
        return
    end

    if idx == 1 then -- Keycard
        local dirs = {{0,-1},{0,1},{-1,0},{1,0}}
        for _, d in ipairs(dirs) do
            local nx, ny = player.gx + d[1], player.gy + d[2]
            if tile_at(nx, ny) == T_DOOR_KEY then
                map[ny][nx] = T_FLOOR
                g.uses = g.uses - 1
                show_msg("Keycard used â€” door opened", 1.5)
                return
            end
        end
        show_msg("No keycard door nearby", 1.0)

    elseif idx == 2 then -- EMP
        g.uses = g.uses - 1
        for _, cam in ipairs(cameras) do
            cam.disabled = CAM_DISABLE_T
        end
        -- EMP pulse particles
        local px = player.gx * TILE - TILE / 2
        local py = player.gy * TILE - TILE / 2
        local emp = emp_particles
        if emp ~= nil then
            ---@diagnostic disable-next-line
            emp:moveTo(px, py)
            emp:emit(40)
        end
        -- Tween: camera disable fade
        tween_cam_fade = { t = 0, dur = 0.6 }
        show_msg("EMP PULSE â€” cameras disabled!", 2.0)

    elseif idx == 3 then -- Lockpick
        local dirs = {{0,-1},{0,1},{-1,0},{1,0}}
        for _, d in ipairs(dirs) do
            local nx, ny = player.gx + d[1], player.gy + d[2]
            if tile_at(nx, ny) == T_DOOR_LCK then
                map[ny][nx] = T_FLOOR
                g.uses = g.uses - 1
                show_msg("Lock picked â€” door opened", 1.5)
                return
            end
        end
        show_msg("No locked door nearby", 1.0)
    end
end

function do_interact()
    local t = tile_at(player.gx, player.gy)

    -- Terminal: hack to get data
    if t == T_TERMINAL and not has_data then
        has_data = true
        show_msg("DATA DOWNLOADED â€” reach the exit!", 2.5)
        local px = player.gx * TILE - TILE / 2
        local py = player.gy * TILE - TILE / 2
        local hack_ps = hack_particles
        if hack_ps ~= nil then
            ---@diagnostic disable-next-line
            hack_ps:moveTo(px, py)
            hack_ps:emit(20)
        end
        return
    end

    -- Hack door adjacent
    local dirs = {{0,-1},{0,1},{-1,0},{1,0}}
    for _, d in ipairs(dirs) do
        local nx, ny = player.gx + d[1], player.gy + d[2]
        if tile_at(nx, ny) == T_DOOR_HCK then
            start_hack(nx, ny)
            return
        end
    end

    -- Vault: requires all 3 gadget types used on adjacent tiles
    if t == T_VAULT and not vault_open then
        local total_used = 0
        for _, g in ipairs(gadgets) do
            if g.uses < g.max then total_used = total_used + 1 end
        end
        if total_used >= 3 then
            vault_open = true
            show_msg("VAULT CRACKED â€” bonus objective complete!", 2.5)
        else
            show_msg("Vault requires all 3 gadget types to be used first", 2.0)
        end
        return
    end

    show_msg("Nothing to interact with here", 1.0)
end

-- â”€â”€ lurek.render â€” map, player, cameras â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function lurek.draw()
    if state == STATE.TITLE then return end

    local render = lurek.render

    -- Draw floor grid
    for y = 1, GRID_ROWS do
        for x = 1, GRID_COLS do
            local t  = map[y][x]
            local px = (x - 1) * TILE
            local py = (y - 1) * TILE

            -- Floor checkerboard
            if t == T_FLOOR then
                local c = ((x + y) % 2 == 0) and C_FLOOR or C_FLOOR2
                rect(px, py, TILE, TILE, c[1], c[2], c[3], 1)

            elseif t == T_WALL then
                rect(px, py, TILE, TILE, C_WALL[1], C_WALL[2], C_WALL[3], 1)

            elseif t == T_DOOR_KEY then
                rect(px, py, TILE, TILE, C_FLOOR[1], C_FLOOR[2], C_FLOOR[3], 1)
                rect(px + 4, py + 4, TILE - 8, TILE - 8, C_DOOR_KEY[1], C_DOOR_KEY[2], C_DOOR_KEY[3], 1)

            elseif t == T_DOOR_HCK then
                rect(px, py, TILE, TILE, C_FLOOR[1], C_FLOOR[2], C_FLOOR[3], 1)
                rect(px + 4, py + 4, TILE - 8, TILE - 8, C_DOOR_HCK[1], C_DOOR_HCK[2], C_DOOR_HCK[3], 1)

            elseif t == T_DOOR_LCK then
                rect(px, py, TILE, TILE, C_FLOOR[1], C_FLOOR[2], C_FLOOR[3], 1)
                rect(px + 4, py + 4, TILE - 8, TILE - 8, C_DOOR_LCK[1], C_DOOR_LCK[2], C_DOOR_LCK[3], 1)

            elseif t == T_TERMINAL then
                rect(px, py, TILE, TILE, C_FLOOR[1], C_FLOOR[2], C_FLOOR[3], 1)
                rect(px + 6, py + 6, TILE - 12, TILE - 12, C_TERMINAL[1], C_TERMINAL[2], C_TERMINAL[3], 1)
                -- Blinking indicator
                if math.floor(lurek.timer.getTime() * 3) % 2 == 0 then
                    rect(px + 14, py + 14, 12, 12, 0.0, 1.0, 0.3, 0.8)
                end

            elseif t == T_VAULT then
                rect(px, py, TILE, TILE, C_FLOOR[1], C_FLOOR[2], C_FLOOR[3], 1)
                local vc = vault_open and {0.4, 0.9, 0.4} or C_VAULT
                rect(px + 4, py + 4, TILE - 8, TILE - 8, vc[1], vc[2], vc[3], 1)

            elseif t == T_EXIT then
                rect(px, py, TILE, TILE, C_FLOOR[1], C_FLOOR[2], C_FLOOR[3], 1)
                local pulse = 0.5 + 0.5 * math.sin(lurek.timer.getTime() * 4)
                rect(px + 2, py + 2, TILE - 4, TILE - 4, C_EXIT[1] * pulse, C_EXIT[2] * pulse, C_EXIT[3] * pulse, 0.7)
            end
        end
    end

    -- Camera vision cones
    for _, cam in ipairs(cameras) do
        local cx = (cam.gx - 0.5) * TILE
        local cy = (cam.gy - 0.5) * TILE

        if cam.disabled > 0 then
            -- Disabled: dim indicator
            circ(cx, cy, 6, C_CAM_OFF[1], C_CAM_OFF[2], C_CAM_OFF[3], 0.5)
        else
            -- Vision cone approximation: draw a series of small rects along the cone
            local cone_col = C_CAM_CONE
            for step = 1, CAM_RANGE * 2 do
                local dist = step * (TILE / 2)
                local spread = dist * math.tan(CAM_HALF_ARC) * 0.8
                local fx = cx + math.cos(cam.angle) * dist
                local fy = cy + math.sin(cam.angle) * dist
                local alpha = cone_col[4] * (1 - step / (CAM_RANGE * 2 + 1))
                rect(fx - spread / 2, fy - spread / 2, spread, spread,
                    cone_col[1], cone_col[2], cone_col[3], alpha)
            end
            -- Camera body
            circ(cx, cy, 5, C_CAM_BODY[1], C_CAM_BODY[2], C_CAM_BODY[3], 1)
        end
    end

    -- Player
    local px = (player.gx - 0.5) * TILE
    local py = (player.gy - 0.5) * TILE
    circ(px, py, 10, C_PLAYER[1], C_PLAYER[2], C_PLAYER[3], 1)
    -- Direction indicator dot
    circ(px, py - 6, 3, 0.1, 0.4, 0.7, 1)

    -- Particles
    local emp = emp_particles
    if emp ~= nil then
        ---@diagnostic disable-next-line
        emp:render()
    end

    local hack_ps = hack_particles
    if hack_ps ~= nil then
        ---@diagnostic disable-next-line
        hack_ps:render()
    end
end

-- â”€â”€ lurek.render_ui â€” HUD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function lurek.draw_ui()
    local render = _gfx

    -- â”€â”€ TITLE SCREEN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if state == STATE.TITLE then
        drawText("SYSTEM INFILTRATION", SCREEN_W / 2 - 180, 120, 32, 0.3, 0.9, 1.0, 1)
        drawText("â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€", SCREEN_W / 2 - 180, 160, 16, 0.2, 0.5, 0.7, 0.6)

        local y = 200
        local briefing = {
            "MISSION BRIEFING:",
            "",
            "Infiltrate the facility and download data from the terminal.",
            "Reach the exit before time runs out.",
            "",
            "GADGETS:",
            "  [1] Keycard  (3x) â€” Opens electronic doors",
            "  [2] EMP      (2x) â€” Disables all cameras for 8 sec",
            "  [3] Lockpick (3x) â€” Opens mechanical locks",
            "",
            "  [E] Interact â€” Hack terminals & wire-doors",
            "",
            "Avoid camera detection. Alert at 100 = CAUGHT.",
            "Bonus: crack the vault using all 3 gadget types.",
            "",
            "Press [E] to begin mission",
        }
        for _, line in ipairs(briefing) do
            drawText(line, 180, y, 16, 0.7, 0.8, 0.9, 0.9)
            y = y + 22
        end
        return
    end

    -- â”€â”€ WON SCREEN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if state == STATE.WON then
        rect(0, 0, SCREEN_W, SCREEN_H, 0, 0, 0, 0.7)
        drawText("MISSION COMPLETE", SCREEN_W / 2 - 150, 200, 32, 0.2, 1.0, 0.4, 1)
        local time_str = string.format("Time remaining: %d seconds", math.floor(timer_left))
        drawText(time_str, SCREEN_W / 2 - 120, 260, 18, 0.7, 0.9, 0.7, 1)
        if vault_open then
            drawText("VAULT BONUS ACHIEVED", SCREEN_W / 2 - 120, 300, 18, 0.9, 0.9, 0.2, 1)
        end
        drawText("Press [E] to return to title", SCREEN_W / 2 - 130, 380, 16, 0.5, 0.7, 0.8, 0.8)
        return
    end

    -- â”€â”€ CAUGHT SCREEN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if state == STATE.CAUGHT then
        rect(0, 0, SCREEN_W, SCREEN_H, 0.15, 0, 0, 0.7)
        drawText("MISSION FAILED", SCREEN_W / 2 - 130, 200, 32, 1.0, 0.2, 0.2, 1)
        local reason = timer_left <= 0 and "Time expired" or "Alert level critical"
        drawText(reason, SCREEN_W / 2 - 80, 260, 18, 0.9, 0.5, 0.5, 1)
        drawText("Press [E] to return to title", SCREEN_W / 2 - 130, 340, 16, 0.5, 0.7, 0.8, 0.8)
        return
    end

    -- â”€â”€ HUD â€” playing / hacking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    -- Timer
    local t_col = timer_left < 30 and {1.0, 0.3, 0.3} or {0.7, 0.9, 0.7}
    local time_str = string.format("TIME: %d:%02d", math.floor(timer_left / 60), math.floor(timer_left) % 60)
    drawText(time_str, SCREEN_W - 140, 10, 18, t_col[1], t_col[2], t_col[3], 1)

    -- Alert bar background
    rect(10, 10, 200, 20, 0.15, 0.15, 0.2, 0.8)
    -- Alert bar fill
    local bar_w = (alert / 100) * 196
    local ar, ag, ab = 0.2 + 0.8 * (alert / 100), 0.8 - 0.6 * (alert / 100), 0.2
    -- Glow pulse when rising
    local glow = alert_bar_glow * 0.3
    rect(12, 12, bar_w, 16, ar + glow, ag + glow, ab, 1)
    -- Alert label
    drawText(string.format("ALERT: %d%%", math.floor(alert)), 14, 12, 14, 1, 1, 1, 0.9)

    -- Gadget slots
    local gy = 40
    for i, g in ipairs(gadgets) do
        local gc = g.color
        local alpha = g.uses > 0 and 1.0 or 0.3
        rect(10, gy, 160, 22, 0.1, 0.1, 0.15, 0.8)
        rect(12, gy + 2, 18, 18, gc[1], gc[2], gc[3], alpha)
        local label = string.format("[%d] %s: %d/%d", i, g.name, g.uses, g.max)
        drawText(label, 34, gy + 3, 14, gc[1], gc[2], gc[3], alpha)
        gy = gy + 26
    end

    -- Data status
    local data_label = has_data and "DATA: ACQUIRED" or "DATA: NOT YET"
    local dc = has_data and {0.2, 1.0, 0.4} or {0.5, 0.5, 0.5}
    drawText(data_label, 10, gy + 4, 14, dc[1], dc[2], dc[3], 1)

    -- Vault status
    if vault_open then
        drawText("VAULT: OPEN", 10, gy + 22, 14, 0.9, 0.9, 0.2, 1)
    end

    -- FPS
    drawText(string.format("FPS: %d", lurek.timer.getFPS()), SCREEN_W - 80, SCREEN_H - 20, 12, 0.4, 0.4, 0.5, 0.6)

    -- Message
    if msg_timer > 0 then
        local ma = math.min(1.0, msg_timer)
        rect(SCREEN_W / 2 - 200, SCREEN_H - 60, 400, 30, 0.05, 0.05, 0.1, 0.85 * ma)
        drawText(msg_text, SCREEN_W / 2 - 190, SCREEN_H - 55, 14, 0.9, 0.9, 0.3, ma)
    end

    -- â”€â”€ HACKING overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if state == STATE.HACKING then
        rect(SCREEN_W / 2 - 150, SCREEN_H / 2 - 80, 300, 160, 0.05, 0.05, 0.12, 0.95)
        drawText("WIRE HACK", SCREEN_W / 2 - 40, SCREEN_H / 2 - 70, 18, 0.9, 0.7, 0.1, 1)

        local wire_colors = {
            {0.9, 0.2, 0.2}, -- 1 = red
            {0.2, 0.8, 0.2}, -- 2 = green
            {0.3, 0.4, 0.9}, -- 3 = blue
            {0.9, 0.9, 0.2}, -- 4 = yellow
        }
        local wire_names = {"RED", "GRN", "BLU", "YLW"}

        -- Show sequence
        local sx = SCREEN_W / 2 - 100
        local sy = SCREEN_H / 2 - 30
        drawText("Sequence:", sx, sy, 14, 0.7, 0.7, 0.8, 1)
        sy = sy + 20
        for i, w in ipairs(hack.sequence) do
            local wc = wire_colors[w]
            local done = i < hack.input_idx
            local current = i == hack.input_idx
            local a = done and 0.3 or 1.0
            local label = string.format("[%d] %s", w, wire_names[w])
            if done then label = label .. " âś“" end
            if current then label = "â†’ " .. label end
            drawText(label, sx + 10, sy, 16, wc[1], wc[2], wc[3], a)
            sy = sy + 22
        end

        drawText("Press 1-4 to match wires", SCREEN_W / 2 - 80, SCREEN_H / 2 + 60, 12, 0.5, 0.5, 0.6, 0.8)
    end
end

