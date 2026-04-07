-- Luna2D Particles Demo
-- Showcases all 5 particle shapes with gravity, color gradients, and burst emission.
--
-- Controls:
--   1–6        switch preset
--   LEFT/RIGHT arrow keys — cycle presets
--   SPACE      burst-fire at mouse position
--   G          toggle gravity on/off for current preset

local W = 900
local H = 600

-- ── Mouse state ────────────────────────────────────────────────────────────
local mouse_x, mouse_y = W / 2, H / 2

-- ── Live particle systems ─────────────────────────────────────────────────
local presets       = {}   -- [i] = ParticleSystem userdata
local active        = 1    -- current preset index

-- Per-preset gravity state (stored gravity when ON, toggled with G)
local preset_gravity = {}  -- [i] = { on=bool, gx=number, gy=number }

-- ── Helper ────────────────────────────────────────────────────────────────
local function col(r, g, b, a)
    return { r, g, b, a or 1.0 }
end

-- ── Preset factories ──────────────────────────────────────────────────────

-- (1) FIRE — Square, warm palette, upward rise, turbulence, no downward gravity
local function make_fire()
    local ps = luna.particle.newSystem({
        maxParticles  = 500,
        emissionRate  = 140,
        lifetimeMin   = 0.5,
        lifetimeMax   = 1.3,
        speedMin      = 50,
        speedMax      = 130,
        direction     = -math.pi / 2,   -- straight up
        spread        = math.pi / 5,    -- ±36°
        gravityX      = 0,
        gravityY      = -30,            -- slight lift
        spinMin       = -1.0,
        spinMax       = 1.0,
        turbulence    = 30,
        sizes          = { 10, 14, 8, 3, 1 },
        colors        = {
            col(1.0, 0.25, 0.0),        -- deep red-orange
            col(1.0, 0.65, 0.0),        -- amber
            col(1.0, 1.0,  0.2, 0.8),   -- bright yellow
            col(0.55, 0.55, 0.55, 0.3), -- smoke grey
            col(0.3,  0.3,  0.3,  0.0), -- fade out
        },
    })
    ps:setShape("square")
    return ps
end

-- (2) EXPLOSION — Spark, radial burst, fast + gravity, short-lived
local function make_explosion()
    local ps = luna.particle.newSystem({
        maxParticles  = 400,
        emissionRate  = 0,              -- burst-only; emit() on SPACE
        lifetimeMin   = 0.3,
        lifetimeMax   = 0.9,
        speedMin      = 180,
        speedMax      = 550,
        direction     = 0,
        spread        = math.pi,        -- full circle
        gravityX      = 0,
        gravityY      = 280,
        spinMin       = 0,
        spinMax       = 0,
        sizes          = { 7, 4, 2, 0.5 },
        colors        = {
            col(1.0, 1.0, 0.9),         -- white-hot core
            col(1.0, 0.55, 0.0),        -- orange
            col(0.8, 0.15, 0.0, 0.6),   -- red-dim
            col(0.3, 0.1,  0.0, 0.0),   -- fade to dark
        },
    })
    ps:setShape("spark")
    return ps
end

-- (3) SMOKE — Circle, slow rise, large puffs, high turbulence
local function make_smoke()
    local ps = luna.particle.newSystem({
        maxParticles  = 100,
        emissionRate  = 18,
        lifetimeMin   = 2.5,
        lifetimeMax   = 4.5,
        speedMin      = 18,
        speedMax      = 40,
        direction     = -math.pi / 2,
        spread        = math.pi / 10,
        gravityX      = 0,
        gravityY      = -8,
        spinMin       = -0.4,
        spinMax       = 0.4,
        turbulence    = 18,
        sizes          = { 12, 24, 34, 30, 12 },
        colors        = {
            col(0.3,  0.3,  0.3,  0.9),
            col(0.5,  0.5,  0.5,  0.65),
            col(0.65, 0.65, 0.65, 0.35),
            col(0.75, 0.75, 0.75, 0.0),
        },
    })
    ps:setShape("circle")
    return ps
end

-- (4) SPARKS — Diamond, radial fountain, strong gravity, drag, spin
local function make_sparks()
    local ps = luna.particle.newSystem({
        maxParticles  = 600,
        emissionRate  = 100,
        lifetimeMin   = 0.6,
        lifetimeMax   = 1.4,
        speedMin      = 130,
        speedMax      = 380,
        direction     = -math.pi / 2,
        spread        = math.pi * 0.75,
        gravityX      = 0,
        gravityY      = 320,
        spinMin       = -6,
        spinMax       = 6,
        drag          = 0.18,
        sizes          = { 5, 4, 2, 0.8 },
        colors        = {
            col(1.0, 1.0, 0.4),         -- bright yellow
            col(1.0, 0.75, 0.0),        -- gold
            col(1.0, 0.35, 0.0, 0.6),   -- orange dimming
            col(0.7, 0.1,  0.0, 0.0),   -- fade out red
        },
    })
    ps:setShape("diamond")
    return ps
end

-- (5) MAGIC — Triangle, rainbow palette, full-circle spread, slow spin, no gravity
local function make_magic()
    local ps = luna.particle.newSystem({
        maxParticles  = 250,
        emissionRate  = 60,
        lifetimeMin   = 1.4,
        lifetimeMax   = 2.8,
        speedMin      = 70,
        speedMax      = 150,
        direction     = 0,
        spread        = math.pi,        -- full circle
        gravityX      = 0,
        gravityY      = 0,
        spinMin       = -4,
        spinMax       = 4,
        turbulence    = 6,
        sizes          = { 5, 8, 7, 4 },
        colors        = {
            col(1.0, 0.2, 0.85),        -- magenta
            col(0.2, 0.5, 1.0),         -- electric blue
            col(0.0, 1.0, 0.55),        -- mint green
            col(1.0, 0.9, 0.1, 0.0),    -- yellow fade-out
        },
    })
    ps:setShape("triangle")
    return ps
end

-- (6) SNOW — Circle, wide-area horizontal line emitter, slow downward drift
local function make_snow()
    local ps = luna.particle.newSystem({
        maxParticles          = 350,
        emissionRate          = 45,
        lifetimeMin           = 3.5,
        lifetimeMax           = 7.0,
        speedMin              = 15,
        speedMax              = 55,
        direction             = math.pi / 2,  -- downward
        spread                = math.pi / 8,
        gravityX              = 0,
        gravityY              = 25,
        spinMin               = -0.4,
        spinMax               = 0.4,
        turbulence            = 10,
        emissionShape         = "line",
        emissionShapeLength   = 900,
        emissionShapeAngle    = 0,
        sizes                  = { 3, 6, 5, 3 },
        colors                = {
            col(0.85, 0.92, 1.0, 0.0),       -- fade in
            col(0.92, 0.96, 1.0, 0.90),      -- white-blue opaque
            col(1.0,  1.0,  1.0, 0.75),      -- pure white
            col(0.85, 0.90, 1.0, 0.0),       -- fade out
        },
    })
    ps:setShape("circle")
    return ps
end

-- ── Preset metadata table (parallel to make_* functions above) ────────────
local preset_defs = {
    { name = "Fire",      shape = "square",   make = make_fire,      gx = 0, gy = -30  },
    { name = "Explosion", shape = "spark",    make = make_explosion, gx = 0, gy = 280  },
    { name = "Smoke",     shape = "circle",   make = make_smoke,     gx = 0, gy = -8   },
    { name = "Sparks",    shape = "diamond",  make = make_sparks,    gx = 0, gy = 320  },
    { name = "Magic",     shape = "triangle", make = make_magic,     gx = 0, gy = 0    },
    { name = "Snow",      shape = "circle",   make = make_snow,      gx = 0, gy = 25   },
}

-- ── luna.load ──────────────────────────────────────────────────────────────
function luna.load()
    luna.window.setTitle("Luna2D — Particles Demo")
    luna.graphics.setBackgroundColor(0.05, 0.05, 0.08)

    for i, def in ipairs(preset_defs) do
        presets[i]       = def.make()
        preset_gravity[i] = { on = true, gx = def.gx, gy = def.gy }
    end

    -- Position all emitters at screen centre by default
    for i, ps in ipairs(presets) do
        ps:setPosition(W / 2, H / 2)
    end

    -- Snow spans the top of the screen via a horizontal line emitter
    presets[6]:setPosition(W / 2, 25)

    -- Start all systems so they begin emitting immediately
    for _, ps in ipairs(presets) do
        ps:start()
    end
end

-- ── Switch active preset ────────────────────────────────────────────────────
local function activate(idx)
    if idx < 1 then idx = #presets end
    if idx > #presets then idx = 1 end
    active = idx
    -- Reset gravity-toggle indicator to the preset's default
    local pg        = preset_gravity[active]
    local gravity_on = pg.on
    -- Apply the correct gravity to the particle system in case it was altered
    local ps = presets[active]
    if gravity_on then
        ps:setGravity(pg.gx, pg.gy)
    else
        ps:setGravity(0, 0)
    end
end

-- ── luna.update ────────────────────────────────────────────────────────────
function luna.update(dt)
    local ps = presets[active]
    -- Non-snow presets follow the mouse
    if active ~= 6 then
        ps:setPosition(mouse_x, mouse_y)
    end
    ps:update(dt)
end

-- ── luna.draw ──────────────────────────────────────────────────────────────
function luna.draw()
    local ps  = presets[active]
    local def = preset_defs[active]
    local cnt = ps:getCount()
    local fps = math.floor(luna.timer.getFPS())
    local pg  = preset_gravity[active]

    -- Draw particle system
    luna.particle.draw(ps)

    -- ── HUD bottom strip ─────────────────────────────────────────────────
    luna.graphics.setColor(0.0, 0.0, 0.0, 0.6)
    luna.graphics.rectangle("fill", 0, H - 84, W, 84)

    -- Preset name
    luna.graphics.setColor(1.0, 0.88, 0.25)
    luna.graphics.print(def.name, 14, H - 76, 3)

    -- Shape label
    luna.graphics.setColor(0.65, 0.80, 1.0)
    luna.graphics.print("Shape: " .. def.shape, 14, H - 46, 1.5)

    -- Particle count
    luna.graphics.setColor(0.65, 0.80, 1.0)
    luna.graphics.print("Particles: " .. tostring(cnt), 14, H - 28, 1.5)

    -- FPS (right side)
    luna.graphics.setColor(0.45, 0.90, 0.50)
    luna.graphics.print("FPS: " .. tostring(fps), W - 115, H - 46, 1.5)

    -- Gravity state indicator
    if pg.on then
        luna.graphics.setColor(0.30, 1.0, 0.45)
        luna.graphics.print("Gravity: ON", W - 150, H - 28, 1.5)
    else
        luna.graphics.setColor(1.0, 0.40, 0.35)
        luna.graphics.print("Gravity: OFF", W - 160, H - 28, 1.5)
    end

    -- ── Controls hint (top bar) ───────────────────────────────────────────
    luna.graphics.setColor(0.0, 0.0, 0.0, 0.45)
    luna.graphics.rectangle("fill", 0, 0, W, 22)
    luna.graphics.setColor(0.38, 0.38, 0.48)
    luna.graphics.print(
        "1-6 / \xE2\x86\x90\xE2\x86\x92 : switch preset   SPACE : burst   G : toggle gravity",
        8, 4, 1.2
    )

    -- ── Preset indicator dots ─────────────────────────────────────────────
    local dot_y  = H - 8
    local dot_x0 = W / 2 - (#presets - 1) * 10
    for i = 1, #presets do
        local dx = dot_x0 + (i - 1) * 20
        if i == active then
            luna.graphics.setColor(1.0, 0.88, 0.25)
            luna.graphics.circle("fill", dx, dot_y, 5)
        else
            luna.graphics.setColor(0.28, 0.28, 0.38)
            luna.graphics.circle("fill", dx, dot_y, 4)
        end
    end
end

-- ── luna.mousemoved ────────────────────────────────────────────────────────
function luna.mousemoved(x, y, dx, dy)
    mouse_x = x
    mouse_y = y
end

-- ── luna.keypressed ────────────────────────────────────────────────────────
function luna.keypressed(key)
    -- Numbered preset switching
    if     key == "1" then activate(1)
    elseif key == "2" then activate(2)
    elseif key == "3" then activate(3)
    elseif key == "4" then activate(4)
    elseif key == "5" then activate(5)
    elseif key == "6" then activate(6)

    -- Arrow cycling
    elseif key == "left"  then activate(active - 1)
    elseif key == "right" then activate(active + 1)

    -- SPACE → burst 80 particles at mouse
    elseif key == "space" then
        local ps = presets[active]
        ps:setPosition(mouse_x, mouse_y)
        ps:emit(80)

    -- G → toggle gravity for the active preset
    elseif key == "g" then
        local pg = preset_gravity[active]
        local ps = presets[active]
        pg.on = not pg.on
        if pg.on then
            ps:setGravity(pg.gx, pg.gy)
        else
            ps:setGravity(0, 0)
        end
    end
end
