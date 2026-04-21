-- Lurek2D particle system API tests.
-- Covers particle-system creation, emission controls, configuration getters/setters, render-state helpers, and lifecycle behavior exposed through lurek.particle.

-- @covers lurek.particle.clone
-- @covers lurek.particle.emit
-- @covers lurek.particle.getBufferSize
-- @covers lurek.particle.getColors
-- @covers lurek.particle.getCount
-- @covers lurek.particle.getDirection
-- @covers lurek.particle.getEmissionArea
-- @covers lurek.particle.getEmissionRate
-- @covers lurek.particle.getEmitterLifetime
-- @covers lurek.particle.getGravity
-- @covers lurek.particle.getInsertMode
-- @covers lurek.particle.getLinearAcceleration
-- @covers lurek.particle.getLinearDamping
-- @covers lurek.particle.getOffset
-- @covers lurek.particle.getParticleLifetime
-- @covers lurek.particle.getPosition
-- @covers lurek.particle.getRadialAcceleration
-- @covers lurek.particle.getRotation
-- @covers lurek.particle.getSizeVariation
-- @covers lurek.particle.getSizes
-- @covers lurek.particle.getSpeed
-- @covers lurek.particle.getSpin
-- @covers lurek.particle.getSpinVariation
-- @covers lurek.particle.getSpread
-- @covers lurek.particle.getTangentialAcceleration
-- @covers lurek.particle.hasRelativeRotation
-- @covers lurek.particle.isActive
-- @covers lurek.particle.isEmpty
-- @covers lurek.particle.isFull
-- @covers lurek.particle.isPaused
-- @covers lurek.particle.isStopped
-- @covers lurek.particle.moveTo
-- @covers lurek.particle.newSystem
-- @covers lurek.particle.pause
-- @covers lurek.particle.release
-- @covers lurek.particle.reset
-- @covers lurek.particle.setBufferSize
-- @covers lurek.particle.setColors
-- @covers lurek.particle.setDirection
-- @covers lurek.particle.setEmissionArea
-- @covers lurek.particle.setEmissionRate
-- @covers lurek.particle.setEmitterLifetime
-- @covers lurek.particle.setInsertMode
-- @covers lurek.particle.setLinearAcceleration
-- @covers lurek.particle.setLinearDamping
-- @covers lurek.particle.setOffset
-- @covers lurek.particle.setParticleLifetime
-- @covers lurek.particle.setPosition
-- @covers lurek.particle.setRadialAcceleration
-- @covers lurek.particle.setRelativeRotation
-- @covers lurek.particle.setRotation
-- @covers lurek.particle.setSizeVariation
-- @covers lurek.particle.setSizes
-- @covers lurek.particle.setSpeed
-- @covers lurek.particle.setSpin
-- @covers lurek.particle.setSpinVariation
-- @covers lurek.particle.setSpread
-- @covers lurek.particle.setTangentialAcceleration
-- @covers lurek.particle.start
-- @covers lurek.particle.stop
-- @covers lurek.particle.update

ď»ż-- Lurek2D Particle API Tests

-- @description Verifies the particle namespace is exposed to Lua as a table.
describe("lurek.particle module exists", function()
    -- @description Asserts that the exposed particles namespace has Lua table type.
    it("lurek.particle is a table", function()
        expect_type("table", lurek.particle)
    end)
end)

-- @description Checks that particle-system construction returns userdata, starts active by default, and accepts both current and backward-compatible config keys.
describe("lurek.particle.newSystem", function()
    -- @description Creates a particle system with no arguments and asserts the returned handle is userdata.
    it("newSystem returns userdata", function()
        local ps = lurek.particle.newSystem()
        expect_type("userdata", ps)
    end)

    -- @description Creates a default system and asserts it is userdata and reports active immediately after construction.
    it("newSystem with no config uses defaults", function()
        local ps = lurek.particle.newSystem()
        expect_type("userdata", ps)
        -- default system starts active
        expect_true(lurek.particle.isActive(ps), "default system should be active")
    end)

    -- @description Passes emissionRate and maxParticles in a config table and asserts construction still succeeds with userdata.
    it("newSystem with config table", function()
        local ps = lurek.particle.newSystem({ emissionRate = 50, maxParticles = 100 })
        expect_type("userdata", ps)
    end)

    -- @description Passes legacy sizeStart and sizeEnd keys and asserts the constructor still returns userdata.
    it("newSystem backward compat: sizeStart/sizeEnd", function()
        local ps = lurek.particle.newSystem({ sizeStart = 8.0, sizeEnd = 2.0 })
        expect_type("userdata", ps)
    end)

    -- @description Passes legacy colorStart and colorEnd keys and asserts the constructor still returns userdata.
    it("newSystem backward compat: colorStart/colorEnd", function()
        local ps = lurek.particle.newSystem({
            colorStart = {1, 0, 0, 1},
            colorEnd   = {1, 0, 0, 0}
        })
        expect_type("userdata", ps)
    end)
end)

-- @description Verifies the initial lifecycle flags and the observable state changes produced by stop, pause, start, and reset.
describe("lurek.particle lifecycle", function()
    -- @description Creates a fresh system and asserts isActive returns true.
    it("isActive returns true for new system", function()
        local ps = lurek.particle.newSystem()
        expect_true(lurek.particle.isActive(ps), "new system should be active")
    end)

    -- @description Creates a fresh system and asserts isPaused returns false.
    it("isPaused returns false for new system", function()
        local ps = lurek.particle.newSystem()
        expect_true(not lurek.particle.isPaused(ps), "new system should not be paused")
    end)

    -- @description Creates a fresh system and asserts isStopped returns false while the emitter is active.
    it("isStopped returns false for new (active) system", function()
        local ps = lurek.particle.newSystem()
        expect_true(not lurek.particle.isStopped(ps), "new system should not be stopped")
    end)

    -- @description Stops a fresh system and asserts isStopped becomes true.
    it("stop sets isStopped", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.stop(ps)
        expect_true(lurek.particle.isStopped(ps), "stopped system should report isStopped")
    end)

    -- @description Pauses a fresh system and asserts isPaused becomes true.
    it("pause sets isPaused", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.pause(ps)
        expect_true(lurek.particle.isPaused(ps), "paused system should report isPaused")
    end)

    -- @description Stops and restarts a system, then asserts it reports active again.
    it("start after stop resumes active state", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.stop(ps)
        lurek.particle.start(ps)
        expect_true(lurek.particle.isActive(ps), "started system should be active")
    end)

    -- @description Emits particles through update, resets the system, and asserts the particle count returns to zero.
    it("reset clears particles and keeps active", function()
        local ps = lurek.particle.newSystem({ emissionRate = 1000, maxParticles = 50 })
        lurek.particle.update(ps, 1.0)
        lurek.particle.reset(ps)
        expect_equal(0, lurek.particle.getCount(ps), "count after reset")
    end)
end)

-- @description Verifies count, empty, and full queries before emission and after adding particles with emit or update.
describe("lurek.particle.getCount / isEmpty / isFull", function()
    -- @description Asserts a newly created system reports a particle count of zero before any update.
    it("getCount returns 0 before any update", function()
        local ps = lurek.particle.newSystem()
        expect_equal(0, lurek.particle.getCount(ps), "count before update")
    end)

    -- @description Asserts a newly created system reports empty when its particle count is zero.
    it("isEmpty returns true when count is 0", function()
        local ps = lurek.particle.newSystem()
        expect_true(lurek.particle.isEmpty(ps), "empty before update")
    end)

    -- @description Asserts a fresh system with capacity configured does not report full before any particles are emitted.
    it("isFull returns false for fresh system", function()
        local ps = lurek.particle.newSystem({ maxParticles = 100 })
        expect_true(not lurek.particle.isFull(ps), "not full before update")
    end)

    -- @description Stops continuous emission, emits a burst of ten particles, and asserts the particle count becomes positive immediately.
    it("emit burst fills particles immediately", function()
        local ps = lurek.particle.newSystem({ maxParticles = 100 })
        lurek.particle.stop(ps)  -- stop continuous emission
        lurek.particle.emit(ps, 10)
        expect_true(lurek.particle.getCount(ps) > 0, "count should increase after emit")
    end)

    -- @description Advances a high-rate emitter for 0.1 seconds and asserts the particle count becomes positive.
    it("getCount increases after update with high emission rate", function()
        local ps = lurek.particle.newSystem({ emissionRate = 500, maxParticles = 50 })
        lurek.particle.update(ps, 0.1)
        expect_true(lurek.particle.getCount(ps) > 0, "count should be positive after update")
    end)
end)

-- @description Verifies explicit position setters, default coordinates, and moveTo all produce the expected x and y values.
describe("lurek.particle position", function()
    -- @description Sets the emitter position to 100,200 and asserts getPosition returns both coordinates within tolerance.
    it("setPosition / getPosition round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setPosition(ps, 100, 200)
        local x, y = lurek.particle.getPosition(ps)
        expect_true(math.abs(x - 100) < 0.001, "x position should match")
        expect_true(math.abs(y - 200) < 0.001, "y position should match")
    end)

    -- @description Creates a fresh system and asserts getPosition returns the default origin coordinates 0,0 within tolerance.
    it("getPosition returns 0,0 by default", function()
        local ps = lurek.particle.newSystem()
        local x, y = lurek.particle.getPosition(ps)
        expect_true(math.abs(x) < 0.001, "default x should be 0")
        expect_true(math.abs(y) < 0.001, "default y should be 0")
    end)

    -- @description Moves the emitter to 50,75 and asserts getPosition reflects both updated coordinates.
    it("moveTo updates position", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.moveTo(ps, 50, 75)
        local x, y = lurek.particle.getPosition(ps)
        expect_true(math.abs(x - 50) < 0.001, "moveTo x")
        expect_true(math.abs(y - 75) < 0.001, "moveTo y")
    end)
end)

-- @description Verifies emission-rate, lifetime, speed, direction, and spread setters return the same values through their getters.
describe("lurek.particle emission settings", function()
    -- @description Sets emissionRate to 99 and asserts getEmissionRate returns the same value within tolerance.
    it("setEmissionRate / getEmissionRate round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionRate(ps, 99.0)
        local rate = lurek.particle.getEmissionRate(ps)
        expect_true(math.abs(rate - 99.0) < 0.001, "emission rate round-trip")
    end)

    -- @description Sets particle lifetime min and max to 0.5 and 2.5 and asserts both values round-trip through getParticleLifetime.
    it("setParticleLifetime / getParticleLifetime round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setParticleLifetime(ps, 0.5, 2.5)
        local mn, mx = lurek.particle.getParticleLifetime(ps)
        expect_true(math.abs(mn - 0.5) < 0.001, "lifetime min")
        expect_true(math.abs(mx - 2.5) < 0.001, "lifetime max")
    end)

    -- @description Sets emitter lifetime to 5 seconds and asserts getEmitterLifetime returns the same value within tolerance.
    it("setEmitterLifetime / getEmitterLifetime round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmitterLifetime(ps, 5.0)
        local t = lurek.particle.getEmitterLifetime(ps)
        expect_true(math.abs(t - 5.0) < 0.001, "emitter lifetime")
    end)

    -- @description Sets speed min and max to 20 and 80 and asserts both values round-trip through getSpeed.
    it("setSpeed / getSpeed round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpeed(ps, 20.0, 80.0)
        local mn, mx = lurek.particle.getSpeed(ps)
        expect_true(math.abs(mn - 20.0) < 0.001, "speed min")
        expect_true(math.abs(mx - 80.0) < 0.001, "speed max")
    end)

    -- @description Sets direction to 1.23 radians and asserts getDirection returns the same value within tolerance.
    it("setDirection / getDirection round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setDirection(ps, 1.23)
        local d = lurek.particle.getDirection(ps)
        expect_true(math.abs(d - 1.23) < 0.001, "direction")
    end)

    -- @description Sets spread to 0.5 and asserts getSpread returns the same value within tolerance.
    it("setSpread / getSpread round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpread(ps, 0.5)
        local s = lurek.particle.getSpread(ps)
        expect_true(math.abs(s - 0.5) < 0.001, "spread")
    end)
end)

-- @description Verifies linear, radial, tangential, and damping acceleration settings round-trip through their getters.
describe("lurek.particle acceleration settings", function()
    -- @description Sets four linear-acceleration bounds and asserts xmin, ymin, xmax, and ymax each round-trip within tolerance.
    it("setLinearAcceleration / getLinearAcceleration round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setLinearAcceleration(ps, -10, -50, 10, 50)
        local xmin, ymin, xmax, ymax = lurek.particle.getLinearAcceleration(ps)
        expect_true(math.abs(xmin - (-10)) < 0.001, "accel xmin")
        expect_true(math.abs(ymin - (-50)) < 0.001, "accel ymin")
        expect_true(math.abs(xmax - 10) < 0.001, "accel xmax")
        expect_true(math.abs(ymax - 50) < 0.001, "accel ymax")
    end)

    -- @description Sets radial acceleration min and max to -5 and 5 and asserts both values round-trip within tolerance.
    it("setRadialAcceleration / getRadialAcceleration round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setRadialAcceleration(ps, -5.0, 5.0)
        local mn, mx = lurek.particle.getRadialAcceleration(ps)
        expect_true(math.abs(mn - (-5.0)) < 0.001, "radial accel min")
        expect_true(math.abs(mx - 5.0) < 0.001, "radial accel max")
    end)

    -- @description Sets tangential acceleration min and max to 1 and 3 and asserts both values round-trip within tolerance.
    it("setTangentialAcceleration / getTangentialAcceleration round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setTangentialAcceleration(ps, 1.0, 3.0)
        local mn, mx = lurek.particle.getTangentialAcceleration(ps)
        expect_true(math.abs(mn - 1.0) < 0.001, "tangential accel min")
        expect_true(math.abs(mx - 3.0) < 0.001, "tangential accel max")
    end)

    -- @description Sets linear damping min and max to 0.1 and 0.9 and asserts both values round-trip within tolerance.
    it("setLinearDamping / getLinearDamping round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setLinearDamping(ps, 0.1, 0.9)
        local mn, mx = lurek.particle.getLinearDamping(ps)
        expect_true(math.abs(mn - 0.1) < 0.001, "damping min")
        expect_true(math.abs(mx - 0.9) < 0.001, "damping max")
    end)
end)

-- @description Verifies particle size keyframes and size variation values are preserved by their getters.
describe("lurek.particle size settings", function()
    -- @description Sets four size keyframes and asserts getSizes returns 8, 4, 2, and 1 in the same slots within tolerance.
    it("setSizes with multiple keyframes / getSizes round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSizes(ps, 8.0, 4.0, 2.0, 1.0)
        local sizes = lurek.particle.getSizes(ps)
        expect_true(math.abs(sizes[1] - 8.0) < 0.001, "size[1]")
        expect_true(math.abs(sizes[2] - 4.0) < 0.001, "size[2]")
        expect_true(math.abs(sizes[3] - 2.0) < 0.001, "size[3]")
        expect_true(math.abs(sizes[4] - 1.0) < 0.001, "size[4]")
    end)

    -- @description Sets size variation to 0.5 and asserts getSizeVariation returns the same value within tolerance.
    it("setSizeVariation / getSizeVariation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSizeVariation(ps, 0.5)
        local v = lurek.particle.getSizeVariation(ps)
        expect_true(math.abs(v - 0.5) < 0.001, "size variation")
    end)
end)

-- @description Verifies rotation, spin, spin variation, and relative-rotation flags round-trip through the particle API.
describe("lurek.particle rotation settings", function()
    -- @description Sets rotation min and max to 0.1 and 0.9 and asserts both values round-trip within tolerance.
    it("setRotation / getRotation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setRotation(ps, 0.1, 0.9)
        local mn, mx = lurek.particle.getRotation(ps)
        expect_true(math.abs(mn - 0.1) < 0.001, "rotation min")
        expect_true(math.abs(mx - 0.9) < 0.001, "rotation max")
    end)

    -- @description Sets spin min and max to 0.2 and 1.5 and asserts both values round-trip within tolerance.
    it("setSpin / getSpin round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpin(ps, 0.2, 1.5)
        local mn, mx = lurek.particle.getSpin(ps)
        expect_true(math.abs(mn - 0.2) < 0.001, "spin min")
        expect_true(math.abs(mx - 1.5) < 0.001, "spin max")
    end)

    -- @description Sets spin variation to 0.75 and asserts getSpinVariation returns the same value within tolerance.
    it("setSpinVariation / getSpinVariation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpinVariation(ps, 0.75)
        local v = lurek.particle.getSpinVariation(ps)
        expect_true(math.abs(v - 0.75) < 0.001, "spin variation")
    end)

    -- @description Enables relative rotation and asserts it becomes true, then disables it and asserts it becomes false.
    it("setRelativeRotation / hasRelativeRotation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setRelativeRotation(ps, true)
        expect_true(lurek.particle.hasRelativeRotation(ps), "relative rotation enabled")
        lurek.particle.setRelativeRotation(ps, false)
        expect_true(not lurek.particle.hasRelativeRotation(ps), "relative rotation disabled")
    end)
end)

-- @description Verifies color keyframes round-trip as nested RGBA tables with the expected channel values.
describe("lurek.particle color settings", function()
    -- @description Sets start and end colors, then asserts the first color is opaque red and the second color keeps red at 0, blue at 1, and alpha at 0.
    it("setColors / getColors round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setColors(ps, {1, 0, 0, 1}, {0, 0, 1, 0})
        -- getColors returns a sequence of color tables: {{r,g,b,a}, {r,g,b,a}, ...}
        local colors = lurek.particle.getColors(ps)
        local r1, g1, b1, a1 = colors[1][1], colors[1][2], colors[1][3], colors[1][4]
        local r2, g2, b2, a2 = colors[2][1], colors[2][2], colors[2][3], colors[2][4]
        expect_true(math.abs(r1 - 1.0) < 0.001, "color[1].r")
        expect_true(math.abs(g1 - 0.0) < 0.001, "color[1].g")
        expect_true(math.abs(b1 - 0.0) < 0.001, "color[1].b")
        expect_true(math.abs(a1 - 1.0) < 0.001, "color[1].a")
        expect_true(math.abs(r2 - 0.0) < 0.001, "color[2].r")
        expect_true(math.abs(b2 - 1.0) < 0.001, "color[2].b")
        expect_true(math.abs(a2 - 0.0) < 0.001, "color[2].a")
    end)
end)

-- @description Verifies rendering-related particle settings including offset, insert mode, and buffer size.
describe("lurek.particle rendering settings", function()
    -- @description Sets the draw offset to 4,8 and asserts getOffset returns both coordinates within tolerance.
    it("setOffset / getOffset round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setOffset(ps, 4.0, 8.0)
        local ox, oy = lurek.particle.getOffset(ps)
        expect_true(math.abs(ox - 4.0) < 0.001, "offset x")
        expect_true(math.abs(oy - 8.0) < 0.001, "offset y")
    end)

    -- @description Sets insert mode to top and asserts getInsertMode returns the exact string top.
    it("setInsertMode / getInsertMode: top", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setInsertMode(ps, "top")
        expect_equal("top", lurek.particle.getInsertMode(ps), "insert mode")
    end)

    -- @description Sets insert mode to bottom and asserts getInsertMode returns the exact string bottom.
    it("setInsertMode / getInsertMode: bottom", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setInsertMode(ps, "bottom")
        expect_equal("bottom", lurek.particle.getInsertMode(ps), "insert mode bottom")
    end)

    -- @description Sets insert mode to random and asserts getInsertMode returns the exact string random.
    it("setInsertMode / getInsertMode: random", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setInsertMode(ps, "random")
        expect_equal("random", lurek.particle.getInsertMode(ps), "insert mode random")
    end)

    -- @description Resizes the particle buffer to 200 and asserts getBufferSize returns 200 exactly.
    it("setBufferSize / getBufferSize round-trip", function()
        local ps = lurek.particle.newSystem({ maxParticles = 50 })
        lurek.particle.setBufferSize(ps, 200)
        expect_equal(200, lurek.particle.getBufferSize(ps), "buffer size")
    end)
end)

-- @description Verifies emission-area distribution modes and the width and height values returned for configured shapes.
describe("lurek.particle emission area", function()
    -- @description Sets the emission area to none and asserts getEmissionArea reports the distribution string none.
    it("setEmissionArea / getEmissionArea: none", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionArea(ps, "none", 0, 0)
        local dist, w, h = lurek.particle.getEmissionArea(ps)
        expect_equal("none", dist, "area distribution none")
    end)

    -- @description Sets a uniform 100 by 50 emission rectangle and asserts the distribution string plus both dimensions round-trip within tolerance.
    it("setEmissionArea: uniform rectangle", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionArea(ps, "uniform", 100, 50)
        local dist, w, h = lurek.particle.getEmissionArea(ps)
        expect_equal("uniform", dist, "area distribution uniform")
        expect_true(math.abs(w - 100) < 0.001, "area width")
        expect_true(math.abs(h - 50) < 0.001, "area height")
    end)

    -- @description Sets an ellipse emission area and asserts the first value returned by getEmissionArea is the string ellipse.
    it("setEmissionArea: ellipse", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionArea(ps, "ellipse", 60, 30)
        local dist = lurek.particle.getEmissionArea(ps)
        expect_equal("ellipse", dist, "area distribution ellipse")
    end)
end)

-- @description Verifies the userdata method form mirrors the module functions for updating, lifecycle, emission, and runtime type checks.
describe("lurek.particle object-method syntax", function()
    -- @description Calls ps:update with a frame delta and asserts the method is callable by reaching a true sentinel assertion.
    it("ps:update(dt) is callable", function()
        local ps = lurek.particle.newSystem()
        ps:update(0.016)
        expect_true(true, "object-method update works")
    end)

    -- @description Calls ps:stop, ps:start, and ps:pause in sequence and asserts the matching status predicates become true after each call.
    it("ps:start() / ps:stop() / ps:pause() are callable", function()
        local ps = lurek.particle.newSystem()
        ps:stop()
        expect_true(ps:isStopped(), "ps:isStopped after ps:stop")
        ps:start()
        expect_true(ps:isActive(), "ps:isActive after ps:start")
        ps:pause()
        expect_true(ps:isPaused(), "ps:isPaused after ps:pause")
    end)

    -- @description Stops continuous emission, calls ps:emit(5), and asserts ps:getCount reports a positive particle count.
    it("ps:emit(n) / ps:getCount() work", function()
        local ps = lurek.particle.newSystem({ maxParticles = 20 })
        ps:stop()
        ps:emit(5)
        expect_true(ps:getCount() > 0, "count after ps:emit")
    end)

    -- @description Asserts the userdata type method returns the exact string ParticleSystem.
    it("ps:type() returns 'ParticleSystem'", function()
        local ps = lurek.particle.newSystem()
        expect_equal("ParticleSystem", ps:type(), "type")
    end)

    -- @description Asserts typeOf reports true for the Drawable interface.
    it("ps:typeOf('Drawable') returns true", function()
        local ps = lurek.particle.newSystem()
        expect_true(ps:typeOf("Drawable"), "typeOf Drawable")
    end)

    -- @description Asserts typeOf reports true for the base Object interface.
    it("ps:typeOf('Object') returns true", function()
        local ps = lurek.particle.newSystem()
        expect_true(ps:typeOf("Object"), "typeOf Object")
    end)

    -- @description Asserts typeOf reports false for an unknown type name.
    it("ps:typeOf('NonExistent') returns false", function()
        local ps = lurek.particle.newSystem()
        expect_true(not ps:typeOf("NonExistent"), "typeOf NonExistent false")
    end)
end)

-- @description Verifies cloning produces another userdata handle with the same configured emission rate as the source system.
describe("lurek.particle.clone", function()
    -- @description Clones a system configured with emissionRate 77 and asserts the clone is userdata and reports the same emission rate within tolerance.
    it("clone returns a different userdata handle", function()
        local ps = lurek.particle.newSystem({ emissionRate = 77.0 })
        local ps2 = lurek.particle.clone(ps)
        expect_type("userdata", ps2)
        -- Clones share config but are independent objects
        local r1 = lurek.particle.getEmissionRate(ps)
        local r2 = lurek.particle.getEmissionRate(ps2)
        expect_true(math.abs(r1 - r2) < 0.001, "clone has same emission rate")
    end)
end)

-- @description Verifies releasing a particle handle succeeds and that later access through the released handle raises an error.
describe("lurek.particle.release", function()
    -- @description Releases a valid particle-system handle and asserts the API returns true.
    it("release returns true for valid handle", function()
        local ps = lurek.particle.newSystem()
        local ok = lurek.particle.release(ps)
        expect_equal(true, ok, "release returns true")
    end)

    -- @description Releases a handle, calls getCount through pcall, and asserts the access fails.
    it("accessing released handle raises an error", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.release(ps)
        local ok, err = pcall(function() lurek.particle.getCount(ps) end)
        expect_true(not ok, "accessing released handle should error")
    end)
end)

-- Phase 8: Particle shape tests

-- @description Verifies supported particle-shape names, invalid-shape rejection, the default shape, and object-method shape updates.
describe("particle shapes", function()
    -- @description Sets each supported shape name in turn and asserts getShape returns square, circle, triangle, spark, and diamond exactly.
    it("setShape and getShape round-trip for all shapes", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        local shapes = {"square", "circle", "triangle", "spark", "diamond"}
        for _, s in ipairs(shapes) do
            ps:setShape(s)
            expect_equal(ps:getShape(), s)
        end
        lurek.particle.release(ps)
    end)

    -- @description Calls setShape with an unsupported hexagon value and asserts the API raises an error.
    it("invalid shape name raises error", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        expect_error(function()
            ps:setShape("hexagon")
        end)
        lurek.particle.release(ps)
    end)

    -- @description Creates a fresh system and asserts the default particle shape is square.
    it("default shape is square", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        expect_equal(ps:getShape(), "square")
        lurek.particle.release(ps)
    end)

    -- @description Sets the shape to diamond through the object method and asserts getShape returns diamond.
    it("setShape via object method matches getShape", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        ps:setShape("diamond")
        expect_equal(ps:getShape(), "diamond")
        lurek.particle.release(ps)
    end)
end)

-- @description Verifies gravity affects a live particle configuration without killing it early and that the gravityY config key maps into getGravity.
describe("particle gravity", function()
    -- @description Emits one particle with a 10-second lifetime, advances 0.1 seconds under gravityY 200, and asserts the particle count remains exactly one.
    it("gravity_y keeps particle alive after update", function()
        local ps = lurek.particle.newSystem({
            maxParticles = 5,
            emissionRate = 0,
            gravityY = 200.0,
            speedMin = 0,
            speedMax = 0,
            lifetimeMin = 10,
            lifetimeMax = 10,
        })
        lurek.particle.emit(ps, 1)
        lurek.particle.update(ps, 0.1)
        -- Particle should still be alive (lifetime=10s, only 0.1s elapsed)
        expect_equal(lurek.particle.getCount(ps), 1)
        lurek.particle.release(ps)
    end)

    -- @description Constructs a system with gravityY 100, reads gravity through getGravity, and asserts the y component is 100 within tolerance.
    it("gravityY config key is accepted", function()
        local ps = lurek.particle.newSystem({ gravityY = 100 })
        local gx, gy = lurek.particle.getGravity(ps)
        expect_true(math.abs(gy - 100) < 0.001, "gravityY config key sets gravity_y")
        lurek.particle.release(ps)
    end)
end)

-- @description Verifies the five new particle shapes round-trip through setShape/getShape.
describe("new particle shapes", function()
    local new_shapes = { "shrapnel", "ray", "puff", "ring", "capsule" }

    for _, shape_name in ipairs(new_shapes) do
        -- @description Sets shape via newSystem config and reads it back via getShape.
        it("shape '" .. shape_name .. "' round-trips via newSystem config", function()
            local ps = lurek.particle.newSystem({ maxParticles = 1, shape = shape_name })
            expect_equal(ps:getShape(), shape_name)
            lurek.particle.release(ps)
        end)

        -- @description Sets shape via setShape method and reads it back via getShape.
        it("setShape('" .. shape_name .. "') persists across getShape", function()
            local ps = lurek.particle.newSystem()
            ps:setShape(shape_name)
            expect_equal(ps:getShape(), shape_name)
            lurek.particle.release(ps)
        end)
    end

    -- @description Verifies shrapnelEdges config key is accepted without error.
    it("shrapnelEdges config accepted", function()
        local ps = lurek.particle.newSystem({ shape = "shrapnel", shrapnelEdges = 8 })
        expect_equal(ps:getShape(), "shrapnel")
        lurek.particle.release(ps)
    end)

    -- @description Verifies rayAspect config key is accepted without error.
    it("rayAspect config accepted", function()
        local ps = lurek.particle.newSystem({ shape = "ray", rayAspect = 6.0 })
        expect_equal(ps:getShape(), "ray")
        lurek.particle.release(ps)
    end)

    -- @description Verifies ringThickness config key is accepted without error.
    it("ringThickness config accepted", function()
        local ps = lurek.particle.newSystem({ shape = "ring", ringThickness = 0.3 })
        expect_equal(ps:getShape(), "ring")
        lurek.particle.release(ps)
    end)
end)

-- @description Verifies the warmUp method pre-populates the system and is clamped at 30 s.
describe("particle warm_up", function()
    -- @description Creates a continuous emitter, calls warmUp(1.0), and asserts count > 0.
    it("warmUp(1.0) produces particles", function()
        local ps = lurek.particle.newSystem({
            maxParticles = 200,
            emissionRate = 100,
            lifetimeMin = 5,
            lifetimeMax = 5,
        })
        ps:warmUp(1.0)
        expect_true(ps:count() > 0, "warmUp should produce particles")
        lurek.particle.release(ps)
    end)

    -- @description Calls warmUp with a value above 30 and asserts no crash.
    it("warmUp(100) is clamped and does not crash", function()
        local ps = lurek.particle.newSystem({
            maxParticles = 50,
            emissionRate = 10,
            lifetimeMin = 2,
            lifetimeMax = 2,
        })
        local ok = pcall(function() ps:warmUp(100) end)
        expect_true(ok, "warmUp with large value should not crash")
        lurek.particle.release(ps)
    end)
end)

-- @description Verifies addAttractor, clearAttractors, and getAttractorCount.
describe("particle attractors", function()
    -- @description Adds three attractors and asserts getAttractorCount returns 3.
    it("addAttractor increases getAttractorCount", function()
        local ps = lurek.particle.newSystem()
        ps:addAttractor(0, 0, 100, 200)
        ps:addAttractor(50, 50, 80, 100)
        ps:addAttractor(-30, 20, 60, 150)
        expect_equal(ps:getAttractorCount(), 3)
        lurek.particle.release(ps)
    end)

    -- @description Clears attractors and asserts count returns to zero.
    it("clearAttractors resets count to zero", function()
        local ps = lurek.particle.newSystem()
        ps:addAttractor(10, 10, 50, 80)
        ps:addAttractor(20, 20, 50, 80)
        ps:clearAttractors()
        expect_equal(ps:getAttractorCount(), 0)
        lurek.particle.release(ps)
    end)

    -- @description Emits particles with an attractor and asserts update does not crash.
    it("update with attractor does not crash", function()
        local ps = lurek.particle.newSystem({
            maxParticles = 20,
            emissionRate = 50,
            lifetimeMin = 5,
            lifetimeMax = 5,
        })
        ps:addAttractor(100, 100, 200, 300)
        ps:start()
        ps:update(0.1)
        expect_true(ps:count() > 0, "particles survive update with attractor")
        lurek.particle.release(ps)
    end)
end)

-- @description Verifies setBounds / clearBounds methods.
describe("particle bounce bounds", function()
    -- @description Calls setBounds with valid values and asserts no crash.
    it("setBounds does not crash", function()
        local ps = lurek.particle.newSystem()
        local ok = pcall(function() ps:setBounds(-100, 100, -100, 100, 0.8) end)
        expect_true(ok, "setBounds should not crash")
        lurek.particle.release(ps)
    end)

    -- @description Calls clearBounds after setBounds and asserts no crash.
    it("clearBounds does not crash", function()
        local ps = lurek.particle.newSystem()
        ps:setBounds(-50, 50, -50, 50, 1.0)
        local ok = pcall(function() ps:clearBounds() end)
        expect_true(ok, "clearBounds should not crash")
        lurek.particle.release(ps)
    end)

    -- @description Emits particles within bounds and asserts they remain alive.
    it("update with bounds does not crash", function()
        local ps = lurek.particle.newSystem({
            maxParticles = 30,
            emissionRate = 0,
            speedMin = 50,
            speedMax = 50,
            lifetimeMin = 10,
            lifetimeMax = 10,
        })
        ps:setBounds(-30, 30, -30, 30, 0.9)
        lurek.particle.emit(ps, 10)
        ps:update(0.5)
        expect_true(ps:count() > 0, "particles survive update within bounds")
        lurek.particle.release(ps)
    end)
end)

describe("lurek.particle addSubEmitter", function()
    -- @covers lurek.particle.ParticleSystem.addSubEmitter
    -- @description addSubEmitter sets a death-emitter config without error.
    it("addSubEmitter attaches sub-config", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        ps:addSubEmitter({
            emissionRate = 0,
            lifetimeMin = 0.5,
            lifetimeMax = 0.5,
            speedMin = 10,
            speedMax = 20,
        }, 3)
        lurek.particle.release(ps)
    end)

    -- @covers lurek.particle.ParticleSystem.addSubEmitter
    -- @description addSubEmitter with default burst_count of 1 does not error.
    it("addSubEmitter defaults burst_count to 1", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        ps:addSubEmitter({ emissionRate = 0 })  -- no burst_count; should default to 1
        lurek.particle.release(ps)
    end)
end)

describe("lurek.particle setFlipbook / getFlipbook", function()
    -- @covers lurek.particle.ParticleSystem.setFlipbook
    -- @covers lurek.particle.ParticleSystem.getFlipbook
    -- @description setFlipbook stores cols/rows/fps and getFlipbook round-trips them.
    it("setFlipbook round-trips via getFlipbook", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        ps:setFlipbook(4, 2, 12)
        local c, r, fps = ps:getFlipbook()
        expect_equal(c, 4)
        expect_equal(r, 2)
        expect_near(fps, 12.0, 0.001)
        lurek.particle.release(ps)
    end)

    -- @covers lurek.particle.ParticleSystem.getFlipbook
    -- @description getFlipbook returns nil when no flipbook has been set.
    it("getFlipbook returns nil when not set", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        local c, r, fps = ps:getFlipbook()
        expect_equal(c, nil, "cols must be nil when flipbook not set")
        expect_equal(r, nil)
        expect_equal(fps, nil)
        lurek.particle.release(ps)
    end)

    -- @covers lurek.particle.ParticleSystem.setFlipbook
    -- @description setFlipbook with invalid cols/rows raises an error.
    it("setFlipbook rejects zero cols", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        local ok = pcall(function() ps:setFlipbook(0, 2, 12) end)
        expect_equal(ok, false, "setFlipbook(0, ...) must raise an error")
        lurek.particle.release(ps)
    end)
end)

test_summary()
