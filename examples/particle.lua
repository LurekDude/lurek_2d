-- examples/particle.lua
-- luna.particles — Emitter-based 2D particle systems and trail ribbons.
-- All luna.particles API methods demonstrated with code and comments.

-- ── Creating a Particle System ────────────────────────────────────────────────

-- newSystem(config) → ParticleSystem
-- The config table controls every aspect of particle behaviour.
-- All fields are optional; unset fields use engine defaults.
local ps = luna.particles.newSystem({
    -- Core emission settings
    maxParticles  = 500,        -- maximum live particles
    emissionRate  = 50,         -- particles per second (continuous)
    emitterLifetime = -1,       -- -1 = infinite; >0 = auto-stop after N seconds

    -- Particle lifetime range (seconds)
    lifetimeMin = 0.5,
    lifetimeMax = 1.5,

    -- Initial speed range
    speedMin = 40,
    speedMax = 120,

    -- Emission direction (radians) and angular spread (radians)
    direction = -math.pi / 2,  -- upward
    spread    = math.pi / 4,   -- ±45 degrees

    -- Per-particle acceleration
    gravityX = 0,
    gravityY = 200,

    -- Spin (rotation rate, radians/second)
    spinMin = -2,
    spinMax =  2,
    spinVariation = 0.5,  -- 0..1 random blend

    -- Initial rotation
    rotationMin = 0,
    rotationMax = math.pi * 2,

    -- Size keyframes (interpolated 0..1 over lifetime)
    -- 1 value = constant; multiple = keyframe gradient
    sizes = { 1.0, 0.5, 0.0 },  -- shrinks over lifetime

    -- Color keyframes — table of {r, g, b, a} tables
    colors = {
        { 1.0, 0.8, 0.2, 1.0 },  -- fiery yellow-orange
        { 1.0, 0.3, 0.0, 0.8 },  -- orange
        { 0.3, 0.3, 0.3, 0.0 },  -- dark grey smoke, fades out
    },

    -- Alpha keyframes (0..1), overrides colors[4] if provided
    -- alphaKeyframes = { 1, 1, 0.5, 0 },

    -- Emission area distribution
    --   "uniform" | "normal" | "ellipse" | "borderRectangle" | "borderEllipse"
    areaDistribution = "uniform",
    areaWidth  = 0,
    areaHeight = 0,

    -- Emission shape
    --   "point" | "circle" | "rectangle" | "ring" | "line" | "cone" | "star" | "spiral"
    emissionShape = "point",

    -- Particle draw shape: "square" | "circle" | "triangle" | "spark" | "diamond"
    shape = "circle",

    -- Relative emission mode: "detached" (default) | "attached"
    relativeMode = "detached",

    -- Physics
    linearDampingMin = 0.0,
    linearDampingMax = 0.1,
    radialAccelMin   = 0,
    radialAccelMax   = 0,
    tangentialAccelMin = 0,
    tangentialAccelMax = 0,
    linearAccelXMin = 0,
    linearAccelXMax = 0,
    linearAccelYMin = 0,
    linearAccelYMax = 0,

    -- Extra effects
    turbulence = 0,      -- random force magnitude each tick
    drag       = 0,      -- simple speed drag coefficient
    orbitSpeed = 0,      -- rotational drift speed
    offsetX    = 0,      -- emitter centre offset
    offsetY    = 0,

    -- Insert order: "top" | "bottom" | "random"
    insertMode = "top",

    -- Sprite sheet animation (if using a texture atlas)
    animatedFrames = 0,       -- 0 = single frame
    frameRate      = 12,

    -- Color-by-speed mapping
    colorBySpeed   = false,
    speedColorMin  = 0,
    speedColorMax  = 200,
})

-- ── Moving the Emitter ────────────────────────────────────────────────────────

-- moveTo(x, y) — reposition the emitter in world space
ps:moveTo(400, 300)

-- ── Emission Control ─────────────────────────────────────────────────────────

-- start() — begin continuous emission at emissionRate
ps:start()

-- emit(count) — fire a one-shot burst regardless of emissionRate
ps:emit(20)

-- pause() / resume()
ps:pause()
ps:resume()

-- stop() — halt new emission; live particles finish their lifetime
ps:stop()

-- reset() — kill all particles and reset the emitter
ps:reset()

-- ── State Queries ─────────────────────────────────────────────────────────────

-- count() → integer — number of live particles
local live = ps:count()

-- isActive() → boolean — emitting OR has live particles
local active = ps:isActive()

-- isPaused() → boolean
local paused = ps:isPaused()

-- isStopped() → boolean
local stopped = ps:isStopped()

-- isEmpty() → boolean — no live particles
local empty = ps:isEmpty()

-- isFull() → boolean — at max_particles
local full = ps:isFull()

-- ── Update / Draw ─────────────────────────────────────────────────────────────

-- update(dt) — call each frame to advance simulation
ps:update(luna.time.getDelta())

-- To draw the particle system, pass it to luna.gfx.draw():
-- luna.gfx.draw(ps, 0, 0)

-- ── Release ───────────────────────────────────────────────────────────────────

-- release() — free the engine slot; ps is invalid afterwards
ps:release()

-- ── Trail Ribbons ─────────────────────────────────────────────────────────────

-- newTrail() → Trail
-- Trails produce a smooth ribbon following a moving point.
local trail = luna.particles.newTrail()

-- setWidth(start_w, end_w?) — ribbon width at head and tail
trail:setWidth(8, 0)  -- tapers to a point

-- setLifetime(seconds) — how long each segment persists
trail:setLifetime(1.0)

-- setMinDistance(px) — minimum pixel distance before adding a new segment
trail:setMinDistance(4)

-- setHeadColor(r, g, b, a) / setTailColor(r, g, b, a)
trail:setHeadColor(1, 1, 0, 1)   -- bright yellow at head
trail:setTailColor(1, 0.2, 0, 0) -- fades to transparent orange at tail

-- getWidth() → start_w, end_w
local sw, ew = trail:getWidth()

-- getLifetime() → number
local lt = trail:getLifetime()

-- pushPoint(x, y) — add the current position each frame
trail:pushPoint(200, 300)

-- update(dt) — age and prune segments
trail:update(1/60)

-- getPointCount() → integer
local pts = trail:getPointCount()

-- clear() — remove all segments
trail:clear()

-- To draw: luna.gfx.draw(trail, 0, 0)

-- ── Typical Particle Usage ────────────────────────────────────────────────────

--[[
function luna.init()
    fire = luna.particles.newSystem({
        maxParticles  = 300,
        emissionRate  = 80,
        lifetimeMin   = 0.4,
        lifetimeMax   = 1.0,
        speedMin      = 30,
        speedMax      = 90,
        direction     = -math.pi / 2,
        spread        = math.pi / 3,
        gravityY      = -60,  -- rises
        sizes         = { 1.0, 0.6, 0.0 },
        colors        = {{ 1, 0.9, 0.1, 1 }, { 1, 0.3, 0, 0.8 }, { 0.2, 0.2, 0.2, 0 }},
        shape         = "circle",
    })
    fire:moveTo(400, 500)
    fire:start()
end

function luna.process(dt)
    fire:update(dt)
end

function luna.render()
    luna.gfx.draw(fire, 0, 0)
end
]]
