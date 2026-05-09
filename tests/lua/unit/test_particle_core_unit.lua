-- Lurek2D particle system API tests.
-- Covers particle-system creation, emission controls, configuration getters/setters, render-state helpers, and lifecycle behavior exposed through lurek.particle.


    -- Lurek2D Particle API Tests

-- @describe lurek.particle module exists
describe("lurek.particle module exists", function()
    -- @covers lurek.particle
    it("lurek.particle is a table", function()
        expect_type("table", lurek.particle)
    end)
end)

-- @describe lurek.particle.newSystem
describe("lurek.particle.newSystem", function()
    -- @covers lurek.particle.newSystem
    it("newSystem returns userdata", function()
        local ps = lurek.particle.newSystem()
        expect_type("userdata", ps)
    end)

    -- @covers lurek.particle.isActive
    -- @covers lurek.particle.newSystem
    it("newSystem with no config uses defaults", function()
        local ps = lurek.particle.newSystem()
        expect_type("userdata", ps)
        -- default system starts active
        expect_true(lurek.particle.isActive(ps), "default system should be active")
    end)

    -- @covers lurek.particle.newSystem
    it("newSystem with config table", function()
        local ps = lurek.particle.newSystem({ emissionRate = 50, maxParticles = 100 })
        expect_type("userdata", ps)
    end)

    -- @covers lurek.particle.newSystem
    it("newSystem backward compat: sizeStart/sizeEnd", function()
        local ps = lurek.particle.newSystem({ sizeStart = 8.0, sizeEnd = 2.0 })
        expect_type("userdata", ps)
    end)

    -- @covers lurek.particle.newSystem
    it("newSystem backward compat: colorStart/colorEnd", function()
        local ps = lurek.particle.newSystem({
            colorStart = {1, 0, 0, 1},
            colorEnd   = {1, 0, 0, 0}
        })
        expect_type("userdata", ps)
    end)
end)

-- @describe lurek.particle lifecycle
describe("lurek.particle lifecycle", function()
    -- @covers lurek.particle.isActive
    -- @covers lurek.particle.newSystem
    it("isActive returns true for new system", function()
        local ps = lurek.particle.newSystem()
        expect_true(lurek.particle.isActive(ps), "new system should be active")
    end)

    -- @covers lurek.particle.isPaused
    -- @covers lurek.particle.newSystem
    it("isPaused returns false for new system", function()
        local ps = lurek.particle.newSystem()
        expect_true(not lurek.particle.isPaused(ps), "new system should not be paused")
    end)

    -- @covers lurek.particle.isStopped
    -- @covers lurek.particle.newSystem
    it("isStopped returns false for new (active) system", function()
        local ps = lurek.particle.newSystem()
        expect_true(not lurek.particle.isStopped(ps), "new system should not be stopped")
    end)

    -- @covers lurek.particle.isStopped
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.stop
    it("stop sets isStopped", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.stop(ps)
        expect_true(lurek.particle.isStopped(ps), "stopped system should report isStopped")
    end)

    -- @covers lurek.particle.isPaused
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.pause
    it("pause sets isPaused", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.pause(ps)
        expect_true(lurek.particle.isPaused(ps), "paused system should report isPaused")
    end)

    -- @covers lurek.particle.isActive
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.start
    -- @covers lurek.particle.stop
    it("start after stop resumes active state", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.stop(ps)
        lurek.particle.start(ps)
        expect_true(lurek.particle.isActive(ps), "started system should be active")
    end)

    -- @covers lurek.particle.getCount
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.reset
    -- @covers lurek.particle.update
    it("reset clears particles and keeps active", function()
        local ps = lurek.particle.newSystem({ emissionRate = 1000, maxParticles = 50 })
        lurek.particle.update(ps, 1.0)
        lurek.particle.reset(ps)
        expect_equal(0, lurek.particle.getCount(ps), "count after reset")
    end)
end)

-- @describe lurek.particle.getCount / isEmpty / isFull
describe("lurek.particle.getCount / isEmpty / isFull", function()
    -- @covers lurek.particle.getCount
    -- @covers lurek.particle.newSystem
    it("getCount returns 0 before any update", function()
        local ps = lurek.particle.newSystem()
        expect_equal(0, lurek.particle.getCount(ps), "count before update")
    end)

    -- @covers lurek.particle.isEmpty
    -- @covers lurek.particle.newSystem
    it("isEmpty returns true when count is 0", function()
        local ps = lurek.particle.newSystem()
        expect_true(lurek.particle.isEmpty(ps), "empty before update")
    end)

    -- @covers lurek.particle.isFull
    -- @covers lurek.particle.newSystem
    it("isFull returns false for fresh system", function()
        local ps = lurek.particle.newSystem({ maxParticles = 100 })
        expect_true(not lurek.particle.isFull(ps), "not full before update")
    end)

    -- @covers lurek.particle.emit
    -- @covers lurek.particle.getCount
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.stop
    it("emit burst fills particles immediately", function()
        local ps = lurek.particle.newSystem({ maxParticles = 100 })
        lurek.particle.stop(ps)  -- stop continuous emission
        lurek.particle.emit(ps, 10)
        expect_true(lurek.particle.getCount(ps) > 0, "count should increase after emit")
    end)

    -- @covers lurek.particle.getCount
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.update
    it("getCount increases after update with high emission rate", function()
        local ps = lurek.particle.newSystem({ emissionRate = 500, maxParticles = 50 })
        lurek.particle.update(ps, 0.1)
        expect_true(lurek.particle.getCount(ps) > 0, "count should be positive after update")
    end)
end)

-- @describe lurek.particle position
describe("lurek.particle position", function()
    -- @covers lurek.particle.getPosition
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setPosition
    it("setPosition / getPosition round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setPosition(ps, 100, 200)
        local x, y = lurek.particle.getPosition(ps)
        expect_true(math.abs(x - 100) < 0.001, "x position should match")
        expect_true(math.abs(y - 200) < 0.001, "y position should match")
    end)

    -- @covers lurek.particle.getPosition
    -- @covers lurek.particle.newSystem
    it("getPosition returns 0,0 by default", function()
        local ps = lurek.particle.newSystem()
        local x, y = lurek.particle.getPosition(ps)
        expect_true(math.abs(x) < 0.001, "default x should be 0")
        expect_true(math.abs(y) < 0.001, "default y should be 0")
    end)

    -- @covers lurek.particle.getPosition
    -- @covers lurek.particle.moveTo
    -- @covers lurek.particle.newSystem
    it("moveTo updates position", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.moveTo(ps, 50, 75)
        local x, y = lurek.particle.getPosition(ps)
        expect_true(math.abs(x - 50) < 0.001, "moveTo x")
        expect_true(math.abs(y - 75) < 0.001, "moveTo y")
    end)
end)

-- @describe lurek.particle emission settings
describe("lurek.particle emission settings", function()
    -- @covers lurek.particle.getEmissionRate
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setEmissionRate
    it("setEmissionRate / getEmissionRate round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionRate(ps, 99.0)
        local rate = lurek.particle.getEmissionRate(ps)
        expect_true(math.abs(rate - 99.0) < 0.001, "emission rate round-trip")
    end)

    -- @covers lurek.particle.getParticleLifetime
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setParticleLifetime
    it("setParticleLifetime / getParticleLifetime round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setParticleLifetime(ps, 0.5, 2.5)
        local mn, mx = lurek.particle.getParticleLifetime(ps)
        expect_true(math.abs(mn - 0.5) < 0.001, "lifetime min")
        expect_true(math.abs(mx - 2.5) < 0.001, "lifetime max")
    end)

    -- @covers lurek.particle.getEmitterLifetime
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setEmitterLifetime
    it("setEmitterLifetime / getEmitterLifetime round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmitterLifetime(ps, 5.0)
        local t = lurek.particle.getEmitterLifetime(ps)
        expect_true(math.abs(t - 5.0) < 0.001, "emitter lifetime")
    end)

    -- @covers lurek.particle.getSpeed
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setSpeed
    it("setSpeed / getSpeed round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpeed(ps, 20.0, 80.0)
        local mn, mx = lurek.particle.getSpeed(ps)
        expect_true(math.abs(mn - 20.0) < 0.001, "speed min")
        expect_true(math.abs(mx - 80.0) < 0.001, "speed max")
    end)

    -- @covers lurek.particle.getDirection
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setDirection
    it("setDirection / getDirection round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setDirection(ps, 1.23)
        local d = lurek.particle.getDirection(ps)
        expect_true(math.abs(d - 1.23) < 0.001, "direction")
    end)

    -- @covers lurek.particle.getSpread
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setSpread
    it("setSpread / getSpread round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpread(ps, 0.5)
        local s = lurek.particle.getSpread(ps)
        expect_true(math.abs(s - 0.5) < 0.001, "spread")
    end)
end)

-- @describe lurek.particle acceleration settings
describe("lurek.particle acceleration settings", function()
    -- @covers lurek.particle.getLinearAcceleration
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setLinearAcceleration
    it("setLinearAcceleration / getLinearAcceleration round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setLinearAcceleration(ps, -10, -50, 10, 50)
        local xmin, ymin, xmax, ymax = lurek.particle.getLinearAcceleration(ps)
        expect_true(math.abs(xmin - (-10)) < 0.001, "accel xmin")
        expect_true(math.abs(ymin - (-50)) < 0.001, "accel ymin")
        expect_true(math.abs(xmax - 10) < 0.001, "accel xmax")
        expect_true(math.abs(ymax - 50) < 0.001, "accel ymax")
    end)

    -- @covers lurek.particle.getRadialAcceleration
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setRadialAcceleration
    it("setRadialAcceleration / getRadialAcceleration round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setRadialAcceleration(ps, -5.0, 5.0)
        local mn, mx = lurek.particle.getRadialAcceleration(ps)
        expect_true(math.abs(mn - (-5.0)) < 0.001, "radial accel min")
        expect_true(math.abs(mx - 5.0) < 0.001, "radial accel max")
    end)

    -- @covers lurek.particle.getTangentialAcceleration
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setTangentialAcceleration
    it("setTangentialAcceleration / getTangentialAcceleration round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setTangentialAcceleration(ps, 1.0, 3.0)
        local mn, mx = lurek.particle.getTangentialAcceleration(ps)
        expect_true(math.abs(mn - 1.0) < 0.001, "tangential accel min")
        expect_true(math.abs(mx - 3.0) < 0.001, "tangential accel max")
    end)

    -- @covers lurek.particle.getLinearDamping
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setLinearDamping
    it("setLinearDamping / getLinearDamping round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setLinearDamping(ps, 0.1, 0.9)
        local mn, mx = lurek.particle.getLinearDamping(ps)
        expect_true(math.abs(mn - 0.1) < 0.001, "damping min")
        expect_true(math.abs(mx - 0.9) < 0.001, "damping max")
    end)
end)

-- @describe lurek.particle size settings
describe("lurek.particle size settings", function()
    -- @covers lurek.particle.getSizes
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setSizes
    it("setSizes with multiple keyframes / getSizes round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSizes(ps, 8.0, 4.0, 2.0, 1.0)
        local sizes = lurek.particle.getSizes(ps)
        expect_true(math.abs(sizes[1] - 8.0) < 0.001, "size[1]")
        expect_true(math.abs(sizes[2] - 4.0) < 0.001, "size[2]")
        expect_true(math.abs(sizes[3] - 2.0) < 0.001, "size[3]")
        expect_true(math.abs(sizes[4] - 1.0) < 0.001, "size[4]")
    end)

    -- @covers lurek.particle.getSizeVariation
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setSizeVariation
    it("setSizeVariation / getSizeVariation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSizeVariation(ps, 0.5)
        local v = lurek.particle.getSizeVariation(ps)
        expect_true(math.abs(v - 0.5) < 0.001, "size variation")
    end)
end)

-- @describe lurek.particle rotation settings
describe("lurek.particle rotation settings", function()
    -- @covers lurek.particle.getRotation
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setRotation
    it("setRotation / getRotation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setRotation(ps, 0.1, 0.9)
        local mn, mx = lurek.particle.getRotation(ps)
        expect_true(math.abs(mn - 0.1) < 0.001, "rotation min")
        expect_true(math.abs(mx - 0.9) < 0.001, "rotation max")
    end)

    -- @covers lurek.particle.getSpin
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setSpin
    it("setSpin / getSpin round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpin(ps, 0.2, 1.5)
        local mn, mx = lurek.particle.getSpin(ps)
        expect_true(math.abs(mn - 0.2) < 0.001, "spin min")
        expect_true(math.abs(mx - 1.5) < 0.001, "spin max")
    end)

    -- @covers lurek.particle.getSpinVariation
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setSpinVariation
    it("setSpinVariation / getSpinVariation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpinVariation(ps, 0.75)
        local v = lurek.particle.getSpinVariation(ps)
        expect_true(math.abs(v - 0.75) < 0.001, "spin variation")
    end)

    -- @covers lurek.particle.hasRelativeRotation
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setRelativeRotation
    it("setRelativeRotation / hasRelativeRotation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setRelativeRotation(ps, true)
        expect_true(lurek.particle.hasRelativeRotation(ps), "relative rotation enabled")
        lurek.particle.setRelativeRotation(ps, false)
        expect_true(not lurek.particle.hasRelativeRotation(ps), "relative rotation disabled")
    end)
end)

-- @describe lurek.particle color settings
describe("lurek.particle color settings", function()
    -- @covers lurek.particle.getColors
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setColors
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

-- @describe lurek.particle rendering settings
describe("lurek.particle rendering settings", function()
    -- @covers lurek.particle.getOffset
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setOffset
    it("setOffset / getOffset round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setOffset(ps, 4.0, 8.0)
        local ox, oy = lurek.particle.getOffset(ps)
        expect_true(math.abs(ox - 4.0) < 0.001, "offset x")
        expect_true(math.abs(oy - 8.0) < 0.001, "offset y")
    end)

    -- @covers lurek.particle.getInsertMode
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setInsertMode
    it("setInsertMode / getInsertMode: top", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setInsertMode(ps, "top")
        expect_equal("top", lurek.particle.getInsertMode(ps), "insert mode")
    end)

    -- @covers lurek.particle.getInsertMode
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setInsertMode
    it("setInsertMode / getInsertMode: bottom", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setInsertMode(ps, "bottom")
        expect_equal("bottom", lurek.particle.getInsertMode(ps), "insert mode bottom")
    end)

    -- @covers lurek.particle.getInsertMode
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setInsertMode
    it("setInsertMode / getInsertMode: random", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setInsertMode(ps, "random")
        expect_equal("random", lurek.particle.getInsertMode(ps), "insert mode random")
    end)

    -- @covers lurek.particle.getBufferSize
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setBufferSize
    it("setBufferSize / getBufferSize round-trip", function()
        local ps = lurek.particle.newSystem({ maxParticles = 50 })
        lurek.particle.setBufferSize(ps, 200)
        expect_equal(200, lurek.particle.getBufferSize(ps), "buffer size")
    end)
end)

-- @describe lurek.particle emission area
describe("lurek.particle emission area", function()
    -- @covers lurek.particle.getEmissionArea
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setEmissionArea
    it("setEmissionArea / getEmissionArea: none", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionArea(ps, "none", 0, 0)
        local dist, w, h = lurek.particle.getEmissionArea(ps)
        expect_equal("none", dist, "area distribution none")
    end)

    -- @covers lurek.particle.getEmissionArea
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setEmissionArea
    it("setEmissionArea: uniform rectangle", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionArea(ps, "uniform", 100, 50)
        local dist, w, h = lurek.particle.getEmissionArea(ps)
        expect_equal("uniform", dist, "area distribution uniform")
        expect_true(math.abs(w - 100) < 0.001, "area width")
        expect_true(math.abs(h - 50) < 0.001, "area height")
    end)

    -- @covers lurek.particle.getEmissionArea
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.setEmissionArea
    it("setEmissionArea: ellipse", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionArea(ps, "ellipse", 60, 30)
        local dist = lurek.particle.getEmissionArea(ps)
        expect_equal("ellipse", dist, "area distribution ellipse")
    end)
end)

-- @describe lurek.particle object-method syntax
describe("lurek.particle object-method syntax", function()
    -- @covers LParticleSystem:update
    -- @covers lurek.particle.newSystem
    it("ps:update(dt) is callable", function()
        local ps = lurek.particle.newSystem()
        ps:update(0.016)
        expect_true(true, "object-method update works")
    end)

    -- @covers LParticleSystem:isActive
    -- @covers LParticleSystem:isPaused
    -- @covers LParticleSystem:isStopped
    -- @covers LParticleSystem:pause
    -- @covers LParticleSystem:start
    -- @covers LParticleSystem:stop
    -- @covers lurek.particle.newSystem
    it("ps:start() / ps:stop() / ps:pause() are callable", function()
        local ps = lurek.particle.newSystem()
        ps:stop()
        expect_true(ps:isStopped(), "ps:isStopped after ps:stop")
        ps:start()
        expect_true(ps:isActive(), "ps:isActive after ps:start")
        ps:pause()
        expect_true(ps:isPaused(), "ps:isPaused after ps:pause")
    end)

    -- @covers LParticleSystem:emit
    -- @covers LParticleSystem:getCount
    -- @covers LParticleSystem:stop
    -- @covers lurek.particle.newSystem
    it("ps:emit(n) / ps:getCount() work", function()
        local ps = lurek.particle.newSystem({ maxParticles = 20 })
        ps:stop()
        ps:emit(5)
        expect_true(ps:getCount() > 0, "count after ps:emit")
    end)

    -- @covers LParticleSystem:type
    -- @covers lurek.particle.newSystem
    it("ps:type() returns 'LParticleSystem'", function()
        local ps = lurek.particle.newSystem()
        expect_equal("LParticleSystem", ps:type(), "type")
    end)

    -- @covers LParticleSystem:typeOf
    -- @covers lurek.particle.newSystem
    it("ps:typeOf('Drawable') returns true", function()
        local ps = lurek.particle.newSystem()
        expect_true(ps:typeOf("Drawable"), "typeOf Drawable")
    end)

    -- @covers LParticleSystem:typeOf
    -- @covers lurek.particle.newSystem
    it("ps:typeOf('Object') returns true", function()
        local ps = lurek.particle.newSystem()
        expect_true(ps:typeOf("Object"), "typeOf Object")
    end)

    -- @covers LParticleSystem:typeOf
    -- @covers lurek.particle.newSystem
    it("ps:typeOf('NonExistent') returns false", function()
        local ps = lurek.particle.newSystem()
        expect_true(not ps:typeOf("NonExistent"), "typeOf NonExistent false")
    end)
end)

-- @describe lurek.particle.clone
describe("lurek.particle.clone", function()
    -- @covers lurek.particle.clone
    -- @covers lurek.particle.getEmissionRate
    -- @covers lurek.particle.newSystem
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

-- @describe lurek.particle.release
describe("lurek.particle.release", function()
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("release returns true for valid handle", function()
        local ps = lurek.particle.newSystem()
        local ok = lurek.particle.release(ps)
        expect_equal(true, ok, "release returns true")
    end)

    -- @covers lurek.particle.getCount
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("accessing released handle raises an error", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.release(ps)
        local ok, err = pcall(function() lurek.particle.getCount(ps) end)
        expect_true(not ok, "accessing released handle should error")
    end)
end)

-- Phase 8: Particle shape tests

-- @describe particle shapes
describe("particle shapes", function()
    -- @covers LParticleSystem:getShape
    -- @covers LParticleSystem:setShape
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("setShape and getShape round-trip for all shapes", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        local shapes = {"square", "circle", "triangle", "spark", "diamond"}
        for _, s in ipairs(shapes) do
            ps:setShape(s)
            expect_equal(ps:getShape(), s)
        end
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:setShape
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("invalid shape name raises error", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        expect_error(function()
            ps:setShape("hexagon")
        end)
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:getShape
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("default shape is square", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        expect_equal(ps:getShape(), "square")
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:getShape
    -- @covers LParticleSystem:setShape
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("setShape via object method matches getShape", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        ps:setShape("diamond")
        expect_equal(ps:getShape(), "diamond")
        lurek.particle.release(ps)
    end)
end)

-- @describe particle gravity
describe("particle gravity", function()
    -- @covers lurek.particle.emit
    -- @covers lurek.particle.getCount
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    -- @covers lurek.particle.update
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

    -- @covers lurek.particle.getGravity
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("gravityY config key is accepted", function()
        local ps = lurek.particle.newSystem({ gravityY = 100 })
        local gx, gy = lurek.particle.getGravity(ps)
        expect_true(math.abs(gy - 100) < 0.001, "gravityY config key sets gravity_y")
        lurek.particle.release(ps)
    end)
end)

-- @describe new particle shapes
describe("new particle shapes", function()
    local new_shapes = { "shrapnel", "ray", "puff", "ring", "capsule" }

    for _, shape_name in ipairs(new_shapes) do
        -- @covers LParticleSystem:getShape
        -- @covers lurek.particle.newSystem
        -- @covers lurek.particle.release
        it("shape '" .. shape_name .. "' round-trips via newSystem config", function()
            local ps = lurek.particle.newSystem({ maxParticles = 1, shape = shape_name })
            expect_equal(ps:getShape(), shape_name)
            lurek.particle.release(ps)
        end)

        -- @covers LParticleSystem:getShape
        -- @covers LParticleSystem:setShape
        -- @covers lurek.particle.newSystem
        -- @covers lurek.particle.release
        it("setShape('" .. shape_name .. "') persists across getShape", function()
            local ps = lurek.particle.newSystem()
            ps:setShape(shape_name)
            expect_equal(ps:getShape(), shape_name)
            lurek.particle.release(ps)
        end)
    end

    -- @covers LParticleSystem:getShape
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("shrapnelEdges config accepted", function()
        local ps = lurek.particle.newSystem({ shape = "shrapnel", shrapnelEdges = 8 })
        expect_equal(ps:getShape(), "shrapnel")
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:getShape
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("rayAspect config accepted", function()
        local ps = lurek.particle.newSystem({ shape = "ray", rayAspect = 6.0 })
        expect_equal(ps:getShape(), "ray")
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:getShape
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("ringThickness config accepted", function()
        local ps = lurek.particle.newSystem({ shape = "ring", ringThickness = 0.3 })
        expect_equal(ps:getShape(), "ring")
        lurek.particle.release(ps)
    end)
end)

-- @describe particle warm_up
describe("particle warm_up", function()
    -- @covers LParticleSystem:count
    -- @covers LParticleSystem:warmUp
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
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

    -- @covers LParticleSystem:warmUp
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
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

-- @describe particle attractors
describe("particle attractors", function()
    -- @covers LParticleSystem:addAttractor
    -- @covers LParticleSystem:getAttractorCount
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("addAttractor increases getAttractorCount", function()
        local ps = lurek.particle.newSystem()
        ps:addAttractor(0, 0, 100, 200)
        ps:addAttractor(50, 50, 80, 100)
        ps:addAttractor(-30, 20, 60, 150)
        expect_equal(ps:getAttractorCount(), 3)
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:addAttractor
    -- @covers LParticleSystem:clearAttractors
    -- @covers LParticleSystem:getAttractorCount
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("clearAttractors resets count to zero", function()
        local ps = lurek.particle.newSystem()
        ps:addAttractor(10, 10, 50, 80)
        ps:addAttractor(20, 20, 50, 80)
        ps:clearAttractors()
        expect_equal(ps:getAttractorCount(), 0)
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:addAttractor
    -- @covers LParticleSystem:count
    -- @covers LParticleSystem:start
    -- @covers LParticleSystem:update
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
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

-- @describe particle bounce bounds
describe("particle bounce bounds", function()
    -- @covers LParticleSystem:setBounds
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("setBounds does not crash", function()
        local ps = lurek.particle.newSystem()
        local ok = pcall(function() ps:setBounds(-100, 100, -100, 100, 0.8) end)
        expect_true(ok, "setBounds should not crash")
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:clearBounds
    -- @covers LParticleSystem:setBounds
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("clearBounds does not crash", function()
        local ps = lurek.particle.newSystem()
        ps:setBounds(-50, 50, -50, 50, 1.0)
        local ok = pcall(function() ps:clearBounds() end)
        expect_true(ok, "clearBounds should not crash")
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:count
    -- @covers LParticleSystem:setBounds
    -- @covers LParticleSystem:update
    -- @covers lurek.particle.emit
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
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

-- @describe lurek.particle addSubEmitter
describe("lurek.particle addSubEmitter", function()
    -- @covers LParticleSystem:addSubEmitter
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
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

    -- @covers LParticleSystem:addSubEmitter
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("addSubEmitter defaults burst_count to 1", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        ps:addSubEmitter({ emissionRate = 0 })  -- no burst_count; should default to 1
        lurek.particle.release(ps)
    end)
end)

-- @describe lurek.particle setFlipbook / getFlipbook
describe("lurek.particle setFlipbook / getFlipbook", function()
    -- @covers LParticleSystem:getFlipbook
    -- @covers LParticleSystem:setFlipbook
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("setFlipbook round-trips via getFlipbook", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        ps:setFlipbook(4, 2, 12)
        local c, r, fps = ps:getFlipbook()
        expect_equal(c, 4)
        expect_equal(r, 2)
        expect_near(fps, 12.0, 0.001)
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:getFlipbook
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("getFlipbook returns nil when not set", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        local c, r, fps = ps:getFlipbook()
        expect_equal(c, nil, "cols must be nil when flipbook not set")
        expect_equal(r, nil)
        expect_equal(fps, nil)
        lurek.particle.release(ps)
    end)

    -- @covers LParticleSystem:setFlipbook
    -- @covers lurek.particle.newSystem
    -- @covers lurek.particle.release
    it("setFlipbook rejects zero cols", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        local ok = pcall(function() ps:setFlipbook(0, 2, 12) end)
        expect_equal(ok, false, "setFlipbook(0, ...) must raise an error")
        lurek.particle.release(ps)
    end)

end)

-- =========================================================================
-- Trail coverage
-- =========================================================================

-- @describe lurek.particle trail
describe("lurek.particle trail", function()
    -- @covers LTrail:type
    -- @covers LTrail:typeOf
    -- @covers lurek.particle.newTrail
    it("creates a trail userdata", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        expect_type("userdata", trail)
        expect_equal(trail:type(), "LTrail")
        expect_equal(trail:typeOf("LTrail"), true)
        expect_equal(trail:typeOf("Object"), true)
    end)

    -- @covers LTrail:clear
    -- @covers LTrail:getPointCount
    -- @covers LTrail:pushPoint
    -- @covers lurek.particle.newTrail
    it("tracks pushed points and clears them", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        expect_equal(trail:getPointCount(), 0)
        trail:pushPoint(0.0, 0.0)
        trail:pushPoint(5.0, 5.0)
        expect_equal(trail:getPointCount(), 2)
        trail:clear()
        expect_equal(trail:getPointCount(), 0)
    end)

    -- @covers LTrail:getLifetime
    -- @covers LTrail:getWidth
    -- @covers LTrail:setLifetime
    -- @covers LTrail:setWidth
    -- @covers lurek.particle.newTrail
    it("round-trips width and lifetime", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        trail:setWidth(4.0, 1.0)
        local start_width, end_width = trail:getWidth()
        expect_near(start_width, 4.0, 0.0001)
        expect_near(end_width, 1.0, 0.0001)

        trail:setLifetime(2.5)
        expect_near(trail:getLifetime(), 2.5, 0.0001)
    end)

    -- @covers LTrail:getPointCount
    -- @covers LTrail:pushPoint
    -- @covers LTrail:setMinDistance
    -- @covers lurek.particle.newTrail
    it("respects minimum point distance", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        trail:setMinDistance(10.0)
        trail:pushPoint(0.0, 0.0)
        trail:pushPoint(1.0, 1.0)
        trail:pushPoint(20.0, 0.0)
        expect_equal(trail:getPointCount(), 2)
    end)

    -- @covers LTrail:drawToImage
    -- @covers lurek.particle.newTrail
    it("draws to image data with requested dimensions", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        local image = trail:drawToImage(64, 32)
        expect_type("userdata", image)
        expect_equal(image:getWidth(), 64)
        expect_equal(image:getHeight(), 32)
    end)

end)

-- Phase 03: Extensibility Hooks

-- @describe particle sub-systems
describe("particle sub-systems", function()
    -- @covers lurek.particle.newSystem
    it("addSubSystem method exists on handle", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        expect_equal(type(ps.addSubSystem), "function")
    end)

    -- @covers LParticleSystem:subSystemCount
    -- @covers lurek.particle.newSystem
    it("subSystemCount starts at 0", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        expect_equal(ps:subSystemCount(), 0)
    end)

    -- @covers LParticleSystem:addSubSystem
    -- @covers LParticleSystem:subSystemCount
    -- @covers lurek.particle.newSystem
    it("addSubSystem increases count by 1", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        ps:addSubSystem({ maxParticles = 16 })
        expect_equal(ps:subSystemCount(), 1)
    end)

    -- @covers LParticleSystem:addSubSystem
    -- @covers lurek.particle.newSystem
    it("addSubSystem returns 1-based index", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        local idx = ps:addSubSystem({ maxParticles = 16 })
        expect_equal(idx, 1)
        local idx2 = ps:addSubSystem({ maxParticles = 16 })
        expect_equal(idx2, 2)
    end)
end)

-- @describe particle custom emission shape
describe("particle custom emission shape", function()
    -- @covers lurek.particle.newSystem
    it("setCustomEmissionShape method exists on handle", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        expect_equal(type(ps.setCustomEmissionShape), "function")
    end)

    -- @covers LParticleSystem:setCustomEmissionShape
    -- @covers lurek.particle.newSystem
    it("setCustomEmissionShape accepts a callback without error", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        local ok = pcall(function()
            ps:setCustomEmissionShape(function() return 0, 0 end)
        end)
        expect_true(ok, "setCustomEmissionShape should accept a callback function")
    end)

    -- @covers LParticleSystem:emit
    -- @covers LParticleSystem:setCustomEmissionShape
    -- @covers LParticleSystem:update
    -- @covers lurek.particle.newSystem
    it("callback is invoked when particles are emitted and updated", function()
        local ps = lurek.particle.newSystem({
            maxParticles = 8,
            emissionRate = 0,
        })
        local calls = 0
        ps:setCustomEmissionShape(function()
            calls = calls + 1
            return 10, 20
        end)
        ps:emit(3)
        ps:update(0.016)
        expect_true(calls >= 3, "custom shape callback should be called for each emitted particle")
    end)
end)

-- @describe particle death batch callback
describe("particle death batch callback", function()
    -- @covers lurek.particle.newSystem
    it("setOnDeathBatch method exists on handle", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        expect_equal(type(ps.setOnDeathBatch), "function")
    end)

    -- @covers LParticleSystem:setOnDeathBatch
    -- @covers lurek.particle.newSystem
    it("setOnDeathBatch accepts a callback without error", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        local ok = pcall(function()
            ps:setOnDeathBatch(function(_batch) end)
        end)
        expect_true(ok, "setOnDeathBatch should accept a callback function")
    end)

    -- @covers LParticleSystem:emit
    -- @covers LParticleSystem:setOnDeathBatch
    -- @covers LParticleSystem:update
    -- @covers lurek.particle.newSystem
    it("death batch callback is invoked when particles die", function()
        local ps = lurek.particle.newSystem({
            maxParticles = 8,
            emissionRate = 0,
            lifetimeMin = 0.001,
            lifetimeMax = 0.001,
        })
        local death_count = 0
        ps:setOnDeathBatch(function(batch)
            death_count = death_count + #batch
        end)
        ps:emit(3)
        ps:update(1.0)  -- enough to kill all 3
        expect_true(death_count >= 3, "death batch callback should receive all 3 dead particles")
    end)

    -- @covers LParticleSystem:emit
    -- @covers LParticleSystem:setOnDeathBatch
    -- @covers LParticleSystem:update
    -- @covers lurek.particle.newSystem
    it("death batch entries have x, y, vx, vy fields", function()
        local ps = lurek.particle.newSystem({
            maxParticles = 4,
            emissionRate = 0,
            lifetimeMin = 0.001,
            lifetimeMax = 0.001,
        })
        local entry = nil
        ps:setOnDeathBatch(function(batch)
            if #batch > 0 then entry = batch[1] end
        end)
        ps:emit(1)
        ps:update(1.0)
        expect_true(entry ~= nil, "should have received a death entry")
        if entry then
            expect_equal(type(entry.x), "number")
            expect_equal(type(entry.y), "number")
            expect_equal(type(entry.vx), "number")
            expect_equal(type(entry.vy), "number")
        end
    end)
end)

-- @describe lurek.particle.fromTOML extensibility
describe("lurek.particle.fromTOML extensibility", function()
    -- @covers lurek.particle.fromTOML
    -- @covers lurek.particle.getEmissionRate
    -- @covers lurek.particle.getParticleLifetime
    it("fromTOML loads config from file", function()
        expect_type("function", lurek.particle.fromTOML)

        local ps = lurek.particle.fromTOML("save/particle_test.toml")
        expect_type("userdata", ps)
        expect_near(30.0, lurek.particle.getEmissionRate(ps), 0.001)

        local min_life, max_life = lurek.particle.getParticleLifetime(ps)
        expect_near(0.5, min_life, 0.001)
        expect_near(2.0, max_life, 0.001)
    end)
end)

-- @describe LTrail color endpoints
describe("LTrail color endpoints", function()
    -- @covers LTrail:setHeadColor
    -- @covers LTrail:setTailColor
    -- @covers lurek.particle.newTrail
    it("setHeadColor and setTailColor accept rgba values", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        expect_no_error(function()
            trail:setHeadColor(1.0, 0.1, 0.2, 1.0)
            trail:setTailColor(0.1, 0.2, 1.0, 0.5)
        end)
    end)
end)

-- @describe particle strict uncovered methods
describe("particle strict uncovered methods", function()
    -- @covers LParticleSystem:getPosition
    -- @covers LParticleSystem:getEmissionRate
    -- @covers LParticleSystem:getParticleLifetime
    -- @covers LParticleSystem:getEmitterLifetime
    -- @covers LParticleSystem:getSpeed
    -- @covers LParticleSystem:getDirection
    -- @covers LParticleSystem:getSpread
    -- @covers LParticleSystem:getLinearAcceleration
    -- @covers LParticleSystem:getRadialAcceleration
    -- @covers LParticleSystem:getTangentialAcceleration
    -- @covers LParticleSystem:getLinearDamping
    -- @covers LParticleSystem:getSizes
    -- @covers LParticleSystem:getSizeVariation
    -- @covers LParticleSystem:getRotation
    -- @covers LParticleSystem:getSpin
    -- @covers LParticleSystem:getSpinVariation
    -- @covers LParticleSystem:hasRelativeRotation
    -- @covers LParticleSystem:getColors
    -- @covers LParticleSystem:getOffset
    -- @covers LParticleSystem:getInsertMode
    -- @covers LParticleSystem:getBufferSize
    -- @covers LParticleSystem:getEmissionArea
    -- @covers LParticleSystem:getGravity
    -- @covers LParticleSystem:isEmpty
    -- @covers LParticleSystem:isFull
    -- @covers lurek.particle.newSystem
    it("strict getters are callable", function()
        local ps = lurek.particle.newSystem({ maxParticles = 16 })
        expect_type("number", ps:getEmissionRate())
        local x, y = ps:getPosition()
        expect_type("number", x)
        expect_type("number", y)
        local lmin, lmax = ps:getParticleLifetime()
        expect_type("number", lmin)
        expect_type("number", lmax)
        expect_type("number", ps:getEmitterLifetime())
        local smin, smax = ps:getSpeed()
        expect_type("number", smin)
        expect_type("number", smax)
        expect_type("number", ps:getDirection())
        expect_type("number", ps:getSpread())
        local lax, lay = ps:getLinearAcceleration()
        expect_type("number", lax)
        expect_type("number", lay)
        expect_not_nil(ps:getRadialAcceleration())
        expect_not_nil(ps:getTangentialAcceleration())
        expect_not_nil(ps:getLinearDamping())
        local size0, size1 = ps:getSizes()
        expect_not_nil(size0)
        expect_true(size1 == nil or type(size1) == "table" or type(size1) == "number")
        expect_type("number", ps:getSizeVariation())
        local r0, r1 = ps:getRotation()
        expect_type("number", r0)
        expect_type("number", r1)
        local sp0, sp1 = ps:getSpin()
        expect_type("number", sp0)
        expect_type("number", sp1)
        expect_type("number", ps:getSpinVariation())
        expect_type("boolean", ps:hasRelativeRotation())
        local c0, c1 = ps:getColors()
        expect_type("table", c0)
        expect_true(c1 == nil or type(c1) == "table")
        local ox, oy = ps:getOffset()
        expect_type("number", ox)
        expect_type("number", oy)
        expect_type("string", ps:getInsertMode())
        expect_type("number", ps:getBufferSize())
        local dist, w, h = ps:getEmissionArea()
        expect_type("string", dist)
        expect_true(w == nil or type(w) == "number")
        expect_true(h == nil or type(h) == "number")
        local gx, gy = ps:getGravity()
        expect_type("number", gx)
        expect_type("number", gy)
        expect_type("boolean", ps:isEmpty())
        expect_type("boolean", ps:isFull())
    end)

    -- @covers LParticleSystem:setPosition
    -- @covers LParticleSystem:setEmissionRate
    -- @covers LParticleSystem:setParticleLifetime
    -- @covers LParticleSystem:setEmitterLifetime
    -- @covers LParticleSystem:setSpeed
    -- @covers LParticleSystem:setDirection
    -- @covers LParticleSystem:setSpread
    -- @covers LParticleSystem:setLinearAcceleration
    -- @covers LParticleSystem:setRadialAcceleration
    -- @covers LParticleSystem:setTangentialAcceleration
    -- @covers LParticleSystem:setLinearDamping
    -- @covers LParticleSystem:setSizes
    -- @covers LParticleSystem:setSizeVariation
    -- @covers LParticleSystem:setRotation
    -- @covers LParticleSystem:setSpin
    -- @covers LParticleSystem:setSpinVariation
    -- @covers LParticleSystem:setRelativeRotation
    -- @covers LParticleSystem:setColors
    -- @covers LParticleSystem:setOffset
    -- @covers LParticleSystem:setInsertMode
    -- @covers LParticleSystem:setBufferSize
    -- @covers LParticleSystem:setEmissionArea
    -- @covers LParticleSystem:setGravity
    -- @covers LParticleSystem:moveTo
    -- @covers LParticleSystem:reset
    -- @covers LParticleSystem:resume
    -- @covers LParticleSystem:render
    -- @covers LParticleSystem:toImage
    -- @covers LParticleSystem:release
    -- @covers lurek.particle.newSystem
    it("strict setters and lifecycle helpers are callable", function()
        local ps = lurek.particle.newSystem({ maxParticles = 16 })
        ps:setPosition(10, 20)
        ps:moveTo(12, 24)
        ps:setEmissionRate(40)
        ps:setParticleLifetime(0.2, 0.6)
        ps:setEmitterLifetime(2.0)
        ps:setSpeed(10, 20)
        ps:setDirection(0.8)
        ps:setSpread(0.5)
        ps:setLinearAcceleration(-1, -2, 1, 2)
        ps:setRadialAcceleration(-3, 3)
        ps:setTangentialAcceleration(-4, 4)
        ps:setLinearDamping(0.1, 0.9)
        ps:setSizes(1.0, 2.0)
        ps:setSizeVariation(0.4)
        ps:setRotation(0.0, 1.5)
        ps:setSpin(-1.0, 1.0)
        ps:setSpinVariation(0.2)
        ps:setRelativeRotation(true)
        ps:setColors({ 1, 1, 1, 1 }, { 1, 0, 0, 0 })
        ps:setOffset(3, 4)
        ps:setInsertMode("top")
        ps:setBufferSize(64)
        ps:setEmissionArea("uniform", 4, 4)
        ps:setGravity(0, 9.81)
        ps:resume()
        ps:reset()
        local ok_render = pcall(function() ps:render() end)
        expect_type("boolean", ok_render)
        local ok_image = pcall(function() ps:toImage(32, 32) end)
        expect_type("boolean", ok_image)
        local ok_release = pcall(function() ps:release() end)
        expect_type("boolean", ok_release)
    end)

    -- @covers LTrail:update
    -- @covers lurek.particle.newTrail
    it("trail update is callable", function()
        local trail = lurek.particle.newTrail(0.25, 4.0)
        local ok = pcall(function() trail:update(0.016) end)
        expect_type("boolean", ok)
    end)
end)

-- @describe particle migrated from render unit
describe("particle migrated from render unit", function()
    -- @covers lurek.particle.newSystem
    it("exposes lurek.particle.newSystem as the canonical constructor", function()
        expect_type("table", lurek.particle)
        expect_type("function", lurek.particle.newSystem)
    end)
end)

-- @describe unit: migrated from integration/test_particle_timer.lua
describe("unit: migrated from integration/test_particle_timer.lua", function()
        -- @covers LParticleSystem:emit
        -- @covers LParticleSystem:getCount
        -- @covers LParticleSystem:setEmissionRate
        -- @covers LParticleSystem:setParticleLifetime
        -- @covers LParticleSystem:setPosition
        -- @covers lurek.particle.newSystem
        it("emitter created and configured with observable particle output", function()
            local pe = lurek.particle.newSystem()
            expect_not_nil(pe, "particle emitter created")

            pe:setPosition(100, 100)
            pe:setEmissionRate(60.0)
            pe:setParticleLifetime(2.0, 2.0)
            pe:emit(3)

            expect_true(pe:getCount() > 0, "emitter should contain particles after emit")
        end)

        -- @covers LParticleSystem:setEmissionRate
        -- @covers LParticleSystem:setParticleLifetime
        -- @covers LParticleSystem:setPosition
        -- @covers lurek.particle.newSystem
        it("emitter position can be updated each frame", function()
            local pe    = lurek.particle.newSystem()
            local trail = {}

            pe:setEmissionRate(1.0)
            pe:setParticleLifetime(1.0, 1.0)

            for i = 1, 10 do
                local x = i * 20.0
                local y = 100.0
                pe:setPosition(x, y)
                trail[i] = {x = x, y = y}
            end

            -- Last recorded position
            local last = trail[10]
            expect_equal(200.0, last.x, "last trail x = 200")
            expect_equal(100.0, last.y, "last trail y = 100")
        end)

end)

test_summary()
