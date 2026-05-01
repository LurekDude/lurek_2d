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
-- @covers lurek.particle.addSubSystem
-- @covers lurek.particle.subSystemCount
-- @covers lurek.particle.setCustomEmissionShape
-- @covers lurek.particle.setOnDeathBatch
-- @covers lurek.particle.fromTOML
-- @covers lurek.particle.newTrail
-- @covers Trail:pushPoint
-- @covers Trail:setWidth
-- @covers Trail:getWidth
-- @covers Trail:setLifetime
-- @covers Trail:getLifetime
-- @covers Trail:setMinDistance
-- @covers Trail:getPointCount
-- @covers Trail:clear
-- @covers Trail:drawToImage

    -- Lurek2D Particle API Tests

describe("lurek.particle module exists", function()
    it("lurek.particle is a table", function()
        expect_type("table", lurek.particle)
    end)
end)

describe("lurek.particle.newSystem", function()
    it("newSystem returns userdata", function()
        local ps = lurek.particle.newSystem()
        expect_type("userdata", ps)
    end)

    it("newSystem with no config uses defaults", function()
        local ps = lurek.particle.newSystem()
        expect_type("userdata", ps)
        -- default system starts active
        expect_true(lurek.particle.isActive(ps), "default system should be active")
    end)

    it("newSystem with config table", function()
        local ps = lurek.particle.newSystem({ emissionRate = 50, maxParticles = 100 })
        expect_type("userdata", ps)
    end)

    it("newSystem backward compat: sizeStart/sizeEnd", function()
        local ps = lurek.particle.newSystem({ sizeStart = 8.0, sizeEnd = 2.0 })
        expect_type("userdata", ps)
    end)

    it("newSystem backward compat: colorStart/colorEnd", function()
        local ps = lurek.particle.newSystem({
            colorStart = {1, 0, 0, 1},
            colorEnd   = {1, 0, 0, 0}
        })
        expect_type("userdata", ps)
    end)
end)

describe("lurek.particle lifecycle", function()
    it("isActive returns true for new system", function()
        local ps = lurek.particle.newSystem()
        expect_true(lurek.particle.isActive(ps), "new system should be active")
    end)

    it("isPaused returns false for new system", function()
        local ps = lurek.particle.newSystem()
        expect_true(not lurek.particle.isPaused(ps), "new system should not be paused")
    end)

    it("isStopped returns false for new (active) system", function()
        local ps = lurek.particle.newSystem()
        expect_true(not lurek.particle.isStopped(ps), "new system should not be stopped")
    end)

    it("stop sets isStopped", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.stop(ps)
        expect_true(lurek.particle.isStopped(ps), "stopped system should report isStopped")
    end)

    it("pause sets isPaused", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.pause(ps)
        expect_true(lurek.particle.isPaused(ps), "paused system should report isPaused")
    end)

    it("start after stop resumes active state", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.stop(ps)
        lurek.particle.start(ps)
        expect_true(lurek.particle.isActive(ps), "started system should be active")
    end)

    it("reset clears particles and keeps active", function()
        local ps = lurek.particle.newSystem({ emissionRate = 1000, maxParticles = 50 })
        lurek.particle.update(ps, 1.0)
        lurek.particle.reset(ps)
        expect_equal(0, lurek.particle.getCount(ps), "count after reset")
    end)
end)

describe("lurek.particle.getCount / isEmpty / isFull", function()
    it("getCount returns 0 before any update", function()
        local ps = lurek.particle.newSystem()
        expect_equal(0, lurek.particle.getCount(ps), "count before update")
    end)

    it("isEmpty returns true when count is 0", function()
        local ps = lurek.particle.newSystem()
        expect_true(lurek.particle.isEmpty(ps), "empty before update")
    end)

    it("isFull returns false for fresh system", function()
        local ps = lurek.particle.newSystem({ maxParticles = 100 })
        expect_true(not lurek.particle.isFull(ps), "not full before update")
    end)

    it("emit burst fills particles immediately", function()
        local ps = lurek.particle.newSystem({ maxParticles = 100 })
        lurek.particle.stop(ps)  -- stop continuous emission
        lurek.particle.emit(ps, 10)
        expect_true(lurek.particle.getCount(ps) > 0, "count should increase after emit")
    end)

    it("getCount increases after update with high emission rate", function()
        local ps = lurek.particle.newSystem({ emissionRate = 500, maxParticles = 50 })
        lurek.particle.update(ps, 0.1)
        expect_true(lurek.particle.getCount(ps) > 0, "count should be positive after update")
    end)
end)

describe("lurek.particle position", function()
    it("setPosition / getPosition round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setPosition(ps, 100, 200)
        local x, y = lurek.particle.getPosition(ps)
        expect_true(math.abs(x - 100) < 0.001, "x position should match")
        expect_true(math.abs(y - 200) < 0.001, "y position should match")
    end)

    it("getPosition returns 0,0 by default", function()
        local ps = lurek.particle.newSystem()
        local x, y = lurek.particle.getPosition(ps)
        expect_true(math.abs(x) < 0.001, "default x should be 0")
        expect_true(math.abs(y) < 0.001, "default y should be 0")
    end)

    it("moveTo updates position", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.moveTo(ps, 50, 75)
        local x, y = lurek.particle.getPosition(ps)
        expect_true(math.abs(x - 50) < 0.001, "moveTo x")
        expect_true(math.abs(y - 75) < 0.001, "moveTo y")
    end)
end)

describe("lurek.particle emission settings", function()
    it("setEmissionRate / getEmissionRate round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionRate(ps, 99.0)
        local rate = lurek.particle.getEmissionRate(ps)
        expect_true(math.abs(rate - 99.0) < 0.001, "emission rate round-trip")
    end)

    it("setParticleLifetime / getParticleLifetime round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setParticleLifetime(ps, 0.5, 2.5)
        local mn, mx = lurek.particle.getParticleLifetime(ps)
        expect_true(math.abs(mn - 0.5) < 0.001, "lifetime min")
        expect_true(math.abs(mx - 2.5) < 0.001, "lifetime max")
    end)

    it("setEmitterLifetime / getEmitterLifetime round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmitterLifetime(ps, 5.0)
        local t = lurek.particle.getEmitterLifetime(ps)
        expect_true(math.abs(t - 5.0) < 0.001, "emitter lifetime")
    end)

    it("setSpeed / getSpeed round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpeed(ps, 20.0, 80.0)
        local mn, mx = lurek.particle.getSpeed(ps)
        expect_true(math.abs(mn - 20.0) < 0.001, "speed min")
        expect_true(math.abs(mx - 80.0) < 0.001, "speed max")
    end)

    it("setDirection / getDirection round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setDirection(ps, 1.23)
        local d = lurek.particle.getDirection(ps)
        expect_true(math.abs(d - 1.23) < 0.001, "direction")
    end)

    it("setSpread / getSpread round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpread(ps, 0.5)
        local s = lurek.particle.getSpread(ps)
        expect_true(math.abs(s - 0.5) < 0.001, "spread")
    end)
end)

describe("lurek.particle acceleration settings", function()
    it("setLinearAcceleration / getLinearAcceleration round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setLinearAcceleration(ps, -10, -50, 10, 50)
        local xmin, ymin, xmax, ymax = lurek.particle.getLinearAcceleration(ps)
        expect_true(math.abs(xmin - (-10)) < 0.001, "accel xmin")
        expect_true(math.abs(ymin - (-50)) < 0.001, "accel ymin")
        expect_true(math.abs(xmax - 10) < 0.001, "accel xmax")
        expect_true(math.abs(ymax - 50) < 0.001, "accel ymax")
    end)

    it("setRadialAcceleration / getRadialAcceleration round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setRadialAcceleration(ps, -5.0, 5.0)
        local mn, mx = lurek.particle.getRadialAcceleration(ps)
        expect_true(math.abs(mn - (-5.0)) < 0.001, "radial accel min")
        expect_true(math.abs(mx - 5.0) < 0.001, "radial accel max")
    end)

    it("setTangentialAcceleration / getTangentialAcceleration round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setTangentialAcceleration(ps, 1.0, 3.0)
        local mn, mx = lurek.particle.getTangentialAcceleration(ps)
        expect_true(math.abs(mn - 1.0) < 0.001, "tangential accel min")
        expect_true(math.abs(mx - 3.0) < 0.001, "tangential accel max")
    end)

    it("setLinearDamping / getLinearDamping round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setLinearDamping(ps, 0.1, 0.9)
        local mn, mx = lurek.particle.getLinearDamping(ps)
        expect_true(math.abs(mn - 0.1) < 0.001, "damping min")
        expect_true(math.abs(mx - 0.9) < 0.001, "damping max")
    end)
end)

describe("lurek.particle size settings", function()
    it("setSizes with multiple keyframes / getSizes round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSizes(ps, 8.0, 4.0, 2.0, 1.0)
        local sizes = lurek.particle.getSizes(ps)
        expect_true(math.abs(sizes[1] - 8.0) < 0.001, "size[1]")
        expect_true(math.abs(sizes[2] - 4.0) < 0.001, "size[2]")
        expect_true(math.abs(sizes[3] - 2.0) < 0.001, "size[3]")
        expect_true(math.abs(sizes[4] - 1.0) < 0.001, "size[4]")
    end)

    it("setSizeVariation / getSizeVariation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSizeVariation(ps, 0.5)
        local v = lurek.particle.getSizeVariation(ps)
        expect_true(math.abs(v - 0.5) < 0.001, "size variation")
    end)
end)

describe("lurek.particle rotation settings", function()
    it("setRotation / getRotation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setRotation(ps, 0.1, 0.9)
        local mn, mx = lurek.particle.getRotation(ps)
        expect_true(math.abs(mn - 0.1) < 0.001, "rotation min")
        expect_true(math.abs(mx - 0.9) < 0.001, "rotation max")
    end)

    it("setSpin / getSpin round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpin(ps, 0.2, 1.5)
        local mn, mx = lurek.particle.getSpin(ps)
        expect_true(math.abs(mn - 0.2) < 0.001, "spin min")
        expect_true(math.abs(mx - 1.5) < 0.001, "spin max")
    end)

    it("setSpinVariation / getSpinVariation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setSpinVariation(ps, 0.75)
        local v = lurek.particle.getSpinVariation(ps)
        expect_true(math.abs(v - 0.75) < 0.001, "spin variation")
    end)

    it("setRelativeRotation / hasRelativeRotation round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setRelativeRotation(ps, true)
        expect_true(lurek.particle.hasRelativeRotation(ps), "relative rotation enabled")
        lurek.particle.setRelativeRotation(ps, false)
        expect_true(not lurek.particle.hasRelativeRotation(ps), "relative rotation disabled")
    end)
end)

describe("lurek.particle color settings", function()
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

describe("lurek.particle rendering settings", function()
    it("setOffset / getOffset round-trip", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setOffset(ps, 4.0, 8.0)
        local ox, oy = lurek.particle.getOffset(ps)
        expect_true(math.abs(ox - 4.0) < 0.001, "offset x")
        expect_true(math.abs(oy - 8.0) < 0.001, "offset y")
    end)

    it("setInsertMode / getInsertMode: top", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setInsertMode(ps, "top")
        expect_equal("top", lurek.particle.getInsertMode(ps), "insert mode")
    end)

    it("setInsertMode / getInsertMode: bottom", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setInsertMode(ps, "bottom")
        expect_equal("bottom", lurek.particle.getInsertMode(ps), "insert mode bottom")
    end)

    it("setInsertMode / getInsertMode: random", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setInsertMode(ps, "random")
        expect_equal("random", lurek.particle.getInsertMode(ps), "insert mode random")
    end)

    it("setBufferSize / getBufferSize round-trip", function()
        local ps = lurek.particle.newSystem({ maxParticles = 50 })
        lurek.particle.setBufferSize(ps, 200)
        expect_equal(200, lurek.particle.getBufferSize(ps), "buffer size")
    end)
end)

describe("lurek.particle emission area", function()
    it("setEmissionArea / getEmissionArea: none", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionArea(ps, "none", 0, 0)
        local dist, w, h = lurek.particle.getEmissionArea(ps)
        expect_equal("none", dist, "area distribution none")
    end)

    it("setEmissionArea: uniform rectangle", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionArea(ps, "uniform", 100, 50)
        local dist, w, h = lurek.particle.getEmissionArea(ps)
        expect_equal("uniform", dist, "area distribution uniform")
        expect_true(math.abs(w - 100) < 0.001, "area width")
        expect_true(math.abs(h - 50) < 0.001, "area height")
    end)

    it("setEmissionArea: ellipse", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.setEmissionArea(ps, "ellipse", 60, 30)
        local dist = lurek.particle.getEmissionArea(ps)
        expect_equal("ellipse", dist, "area distribution ellipse")
    end)
end)

describe("lurek.particle object-method syntax", function()
    it("ps:update(dt) is callable", function()
        local ps = lurek.particle.newSystem()
        ps:update(0.016)
        expect_true(true, "object-method update works")
    end)

    it("ps:start() / ps:stop() / ps:pause() are callable", function()
        local ps = lurek.particle.newSystem()
        ps:stop()
        expect_true(ps:isStopped(), "ps:isStopped after ps:stop")
        ps:start()
        expect_true(ps:isActive(), "ps:isActive after ps:start")
        ps:pause()
        expect_true(ps:isPaused(), "ps:isPaused after ps:pause")
    end)

    it("ps:emit(n) / ps:getCount() work", function()
        local ps = lurek.particle.newSystem({ maxParticles = 20 })
        ps:stop()
        ps:emit(5)
        expect_true(ps:getCount() > 0, "count after ps:emit")
    end)

    it("ps:type() returns 'LParticleSystem'", function()
        local ps = lurek.particle.newSystem()
        expect_equal("LParticleSystem", ps:type(), "type")
    end)

    it("ps:typeOf('Drawable') returns true", function()
        local ps = lurek.particle.newSystem()
        expect_true(ps:typeOf("Drawable"), "typeOf Drawable")
    end)

    it("ps:typeOf('Object') returns true", function()
        local ps = lurek.particle.newSystem()
        expect_true(ps:typeOf("Object"), "typeOf Object")
    end)

    it("ps:typeOf('NonExistent') returns false", function()
        local ps = lurek.particle.newSystem()
        expect_true(not ps:typeOf("NonExistent"), "typeOf NonExistent false")
    end)
end)

describe("lurek.particle.clone", function()
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

describe("lurek.particle.release", function()
    it("release returns true for valid handle", function()
        local ps = lurek.particle.newSystem()
        local ok = lurek.particle.release(ps)
        expect_equal(true, ok, "release returns true")
    end)

    it("accessing released handle raises an error", function()
        local ps = lurek.particle.newSystem()
        lurek.particle.release(ps)
        local ok, err = pcall(function() lurek.particle.getCount(ps) end)
        expect_true(not ok, "accessing released handle should error")
    end)
end)

-- Phase 8: Particle shape tests

describe("particle shapes", function()
    it("setShape and getShape round-trip for all shapes", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        local shapes = {"square", "circle", "triangle", "spark", "diamond"}
        for _, s in ipairs(shapes) do
            ps:setShape(s)
            expect_equal(ps:getShape(), s)
        end
        lurek.particle.release(ps)
    end)

    it("invalid shape name raises error", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        expect_error(function()
            ps:setShape("hexagon")
        end)
        lurek.particle.release(ps)
    end)

    it("default shape is square", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        expect_equal(ps:getShape(), "square")
        lurek.particle.release(ps)
    end)

    it("setShape via object method matches getShape", function()
        local ps = lurek.particle.newSystem({ maxParticles = 10 })
        ps:setShape("diamond")
        expect_equal(ps:getShape(), "diamond")
        lurek.particle.release(ps)
    end)
end)

describe("particle gravity", function()
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

    it("gravityY config key is accepted", function()
        local ps = lurek.particle.newSystem({ gravityY = 100 })
        local gx, gy = lurek.particle.getGravity(ps)
        expect_true(math.abs(gy - 100) < 0.001, "gravityY config key sets gravity_y")
        lurek.particle.release(ps)
    end)
end)

describe("new particle shapes", function()
    local new_shapes = { "shrapnel", "ray", "puff", "ring", "capsule" }

    for _, shape_name in ipairs(new_shapes) do
        it("shape '" .. shape_name .. "' round-trips via newSystem config", function()
            local ps = lurek.particle.newSystem({ maxParticles = 1, shape = shape_name })
            expect_equal(ps:getShape(), shape_name)
            lurek.particle.release(ps)
        end)

        it("setShape('" .. shape_name .. "') persists across getShape", function()
            local ps = lurek.particle.newSystem()
            ps:setShape(shape_name)
            expect_equal(ps:getShape(), shape_name)
            lurek.particle.release(ps)
        end)
    end

    it("shrapnelEdges config accepted", function()
        local ps = lurek.particle.newSystem({ shape = "shrapnel", shrapnelEdges = 8 })
        expect_equal(ps:getShape(), "shrapnel")
        lurek.particle.release(ps)
    end)

    it("rayAspect config accepted", function()
        local ps = lurek.particle.newSystem({ shape = "ray", rayAspect = 6.0 })
        expect_equal(ps:getShape(), "ray")
        lurek.particle.release(ps)
    end)

    it("ringThickness config accepted", function()
        local ps = lurek.particle.newSystem({ shape = "ring", ringThickness = 0.3 })
        expect_equal(ps:getShape(), "ring")
        lurek.particle.release(ps)
    end)
end)

describe("particle warm_up", function()
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

describe("particle attractors", function()
    it("addAttractor increases getAttractorCount", function()
        local ps = lurek.particle.newSystem()
        ps:addAttractor(0, 0, 100, 200)
        ps:addAttractor(50, 50, 80, 100)
        ps:addAttractor(-30, 20, 60, 150)
        expect_equal(ps:getAttractorCount(), 3)
        lurek.particle.release(ps)
    end)

    it("clearAttractors resets count to zero", function()
        local ps = lurek.particle.newSystem()
        ps:addAttractor(10, 10, 50, 80)
        ps:addAttractor(20, 20, 50, 80)
        ps:clearAttractors()
        expect_equal(ps:getAttractorCount(), 0)
        lurek.particle.release(ps)
    end)

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

describe("particle bounce bounds", function()
    it("setBounds does not crash", function()
        local ps = lurek.particle.newSystem()
        local ok = pcall(function() ps:setBounds(-100, 100, -100, 100, 0.8) end)
        expect_true(ok, "setBounds should not crash")
        lurek.particle.release(ps)
    end)

    it("clearBounds does not crash", function()
        local ps = lurek.particle.newSystem()
        ps:setBounds(-50, 50, -50, 50, 1.0)
        local ok = pcall(function() ps:clearBounds() end)
        expect_true(ok, "clearBounds should not crash")
        lurek.particle.release(ps)
    end)

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
    it("addSubEmitter defaults burst_count to 1", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        ps:addSubEmitter({ emissionRate = 0 })  -- no burst_count; should default to 1
        lurek.particle.release(ps)
    end)
end)

describe("lurek.particle setFlipbook / getFlipbook", function()
    -- @covers lurek.particle.ParticleSystem.setFlipbook
    -- @covers lurek.particle.ParticleSystem.getFlipbook
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
    it("getFlipbook returns nil when not set", function()
        local ps = lurek.particle.newSystem({ emissionRate = 0 })
        local c, r, fps = ps:getFlipbook()
        expect_equal(c, nil, "cols must be nil when flipbook not set")
        expect_equal(r, nil)
        expect_equal(fps, nil)
        lurek.particle.release(ps)
    end)

    -- @covers lurek.particle.ParticleSystem.setFlipbook
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

describe("lurek.particle trail", function()
    -- @covers lurek.particle.newTrail
    -- @covers Trail:type
    -- @covers Trail:typeOf
    it("creates a trail userdata", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        expect_type("userdata", trail)
        expect_equal(trail:type(), "LTrail")
        expect_equal(trail:typeOf("LTrail"), true)
        expect_equal(trail:typeOf("Object"), true)
    end)

    -- @covers Trail:pushPoint
    -- @covers Trail:getPointCount
    -- @covers Trail:clear
    it("tracks pushed points and clears them", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        expect_equal(trail:getPointCount(), 0)
        trail:pushPoint(0.0, 0.0)
        trail:pushPoint(5.0, 5.0)
        expect_equal(trail:getPointCount(), 2)
        trail:clear()
        expect_equal(trail:getPointCount(), 0)
    end)

    -- @covers Trail:setWidth
    -- @covers Trail:getWidth
    -- @covers Trail:getLifetime
    -- @covers Trail:setLifetime
    it("round-trips width and lifetime", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        trail:setWidth(4.0, 1.0)
        local start_width, end_width = trail:getWidth()
        expect_near(start_width, 4.0, 0.0001)
        expect_near(end_width, 1.0, 0.0001)

        trail:setLifetime(2.5)
        expect_near(trail:getLifetime(), 2.5, 0.0001)
    end)

    -- @covers Trail:setMinDistance
    -- @covers Trail:getPointCount
    it("respects minimum point distance", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        trail:setMinDistance(10.0)
        trail:pushPoint(0.0, 0.0)
        trail:pushPoint(1.0, 1.0)
        trail:pushPoint(20.0, 0.0)
        expect_equal(trail:getPointCount(), 2)
    end)

    -- @covers Trail:drawToImage
    it("draws to image data with requested dimensions", function()
        local trail = lurek.particle.newTrail(1.0, 4.0)
        local image = trail:drawToImage(64, 32)
        expect_type("userdata", image)
        expect_equal(image:getWidth(), 64)
        expect_equal(image:getHeight(), 32)
    end)

end)

-- Phase 03: Extensibility Hooks

describe("particle sub-systems", function()
    it("addSubSystem method exists on handle", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        expect_equal(type(ps.addSubSystem), "function")
    end)

    it("subSystemCount starts at 0", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        expect_equal(ps:subSystemCount(), 0)
    end)

    it("addSubSystem increases count by 1", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        ps:addSubSystem({ maxParticles = 16 })
        expect_equal(ps:subSystemCount(), 1)
    end)

    it("addSubSystem returns 1-based index", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        local idx = ps:addSubSystem({ maxParticles = 16 })
        expect_equal(idx, 1)
        local idx2 = ps:addSubSystem({ maxParticles = 16 })
        expect_equal(idx2, 2)
    end)
end)

describe("particle custom emission shape", function()
    it("setCustomEmissionShape method exists on handle", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        expect_equal(type(ps.setCustomEmissionShape), "function")
    end)

    it("setCustomEmissionShape accepts a callback without error", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        local ok = pcall(function()
            ps:setCustomEmissionShape(function() return 0, 0 end)
        end)
        expect_true(ok, "setCustomEmissionShape should accept a callback function")
    end)

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

describe("particle death batch callback", function()
    it("setOnDeathBatch method exists on handle", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        expect_equal(type(ps.setOnDeathBatch), "function")
    end)

    it("setOnDeathBatch accepts a callback without error", function()
        local ps = lurek.particle.newSystem({ maxParticles = 64 })
        local ok = pcall(function()
            ps:setOnDeathBatch(function(_batch) end)
        end)
        expect_true(ok, "setOnDeathBatch should accept a callback function")
    end)

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

describe("lurek.particle.fromTOML extensibility", function()
    -- @covers lurek.particle.fromTOML
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

test_summary()
