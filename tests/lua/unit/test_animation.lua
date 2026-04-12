-- Lurek2D Lua BDD tests for lurek.animation
-- Headless: no GPU, no audio, no window.
-- @covers lurek.animation.new
-- @covers lurek.animation.addFrame
-- @covers lurek.animation.addFramesFromGrid
-- @covers lurek.animation.addClip
-- @covers lurek.animation.addClipFromGrid
-- @covers lurek.animation.play
-- @covers lurek.animation.stop
-- @covers lurek.animation.pause
-- @covers lurek.animation.resume
-- @covers lurek.animation.update
-- @covers lurek.animation.getQuad
-- @covers lurek.animation.pollEvents
-- @covers lurek.animation.isPlaying
-- @covers lurek.animation.isLooping
-- @covers lurek.animation.getClip
-- @covers lurek.animation.getSpeed
-- @covers lurek.animation.setSpeed
-- @covers lurek.animation.getFrameCount
-- @covers lurek.animation.getClipCount
-- @covers lurek.animation.getCurrentFrame
-- @covers lurek.animation.setFrame


describe("lurek.animation", function()
    describe("module interface", function()
        it("exposes new factory", function()
            expect_type("function", lurek.animation.new)
        end)
    end)

    describe("new()", function()
        it("returns a userdata object", function()
            local a = lurek.animation.new()
            expect_type("userdata", a)
        end)

        it("getFrameCount returns 0 on empty animation", function()
            local a = lurek.animation.new()
            expect_equal(0, a:getFrameCount())
        end)

        it("getClipCount returns 0 with no clips", function()
            local a = lurek.animation.new()
            expect_equal(0, a:getClipCount())
        end)

        it("isPlaying returns false before play()", function()
            local a = lurek.animation.new()
            expect_equal(false, a:isPlaying())
        end)

        it("getClip returns nil before play()", function()
            local a = lurek.animation.new()
            expect_equal(nil, a:getClip())
        end)

        it("getSpeed returns default 1.0", function()
            local a = lurek.animation.new()
            expect_near(1.0, a:getSpeed(), 0.001)
        end)
    end)

    describe("addFrame()", function()
        it("returns an index starting from 0", function()
            local a = lurek.animation.new()
            local idx = a:addFrame(0, 0, 32, 32)
            expect_equal(0, idx)
        end)

        it("increments frame count", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            expect_equal(2, a:getFrameCount())
        end)
    end)

    describe("addFramesFromGrid()", function()
        it("returns the number of frames added", function()
            local a = lurek.animation.new()
            local n = a:addFramesFromGrid(128, 128, 32, 32, 0, 4)
            expect_equal(4, n)
        end)

        it("increases frame count by the returned amount", function()
            local a = lurek.animation.new()
            local n = a:addFramesFromGrid(64, 64, 32, 32, 0, 2)
            expect_equal(n, a:getFrameCount())
        end)
    end)

    describe("addClip()", function()
        it("increases clip count by one", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("idle", {0}, 12, false)
            expect_equal(1, a:getClipCount())
        end)
    end)

    describe("play() / stop()", function()
        it("play transitions isPlaying to true", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("idle", {0}, 12, true)
            local ok = a:play("idle")
            expect_equal(true, ok)
            expect_equal(true, a:isPlaying())
        end)

        it("play returns false for unknown clip", function()
            local a = lurek.animation.new()
            local ok = a:play("nonexistent")
            expect_equal(false, ok)
        end)

        it("stop makes isPlaying false", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("run", {0}, 12, true)
            a:play("run")
            a:stop()
            expect_equal(false, a:isPlaying())
        end)
    end)

    describe("setSpeed() / getSpeed()", function()
        it("round-trips the speed value", function()
            local a = lurek.animation.new()
            a:setSpeed(2.5)
            expect_near(2.5, a:getSpeed(), 0.001)
        end)
    end)

    describe("update() + getQuad()", function()
        it("getQuad returns a table after play + update", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 32, 32)
            a:addClip("idle", {0}, 12, true)
            a:play("idle")
            a:update(0.0)
            local q = a:getQuad()
            expect_type("table", q)
            expect_type("number", q.x)
            expect_type("number", q.y)
            expect_type("number", q.w)
            expect_type("number", q.h)
        end)

        it("getQuad returns nil when not playing", function()
            local a = lurek.animation.new()
            local q = a:getQuad()
            expect_equal(nil, q)
        end)
    end)

    describe("pollEvents()", function()
        it("returns a table", function()
            local a = lurek.animation.new()
            local evs = a:pollEvents()
            expect_type("table", evs)
        end)

        it("returns empty table when idle", function()
            local a = lurek.animation.new()
            local evs = a:pollEvents()
            expect_equal(0, #evs)
        end)
    end)

    -- ── pause / resume ──────────────────────────────────────────────

    describe("pause and resume", function()
        it("pause stops advancement", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            a:addClip("walk", {0, 1}, 10, true)
            a:play("walk")
            a:pause()
            expect_false(a:isPlaying())
            local f_before = a:getCurrentFrame()
            a:update(1.0)
            expect_equal(f_before, a:getCurrentFrame())
        end)

        it("resume continues from paused frame", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            a:addClip("walk", {0, 1}, 10, true)
            a:play("walk")
            a:pause()
            local f_paused = a:getCurrentFrame()
            a:resume()
            expect_true(a:isPlaying())
            expect_equal(f_paused, a:getCurrentFrame())
        end)
    end)

    -- ── setFrame ────────────────────────────────────────────────────

    describe("setFrame", function()
        it("sets playback to a specific frame index", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            a:addFrame(32, 0, 16, 16)
            a:addClip("run", {0, 1, 2}, 10, false)
            a:play("run")
            a:setFrame(2)
            expect_equal(2, a:getCurrentFrame())
        end)
    end)

    -- ── getCurrentFrame ─────────────────────────────────────────────

    describe("getCurrentFrame", function()
        it("returns 0 at start of clip", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            a:addClip("idle", {0, 1}, 10, true)
            a:play("idle")
            expect_equal(0, a:getCurrentFrame())
        end)
    end)

    -- ── isLooping ───────────────────────────────────────────────────

    describe("isLooping", function()
        it("returns true for looping clip", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("idle", {0}, 10, true)
            a:play("idle")
            expect_true(a:isLooping())
        end)

        it("returns false for non-looping clip", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("once", {0}, 10, false)
            a:play("once")
            expect_false(a:isLooping())
        end)
    end)

    -- ── event lifecycle ─────────────────────────────────────────────

    describe("event lifecycle", function()
        it("non-looping clip emits Finished event", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("once", {0}, 10, false)
            a:play("once")
            a:update(1.0) -- well past single frame
            local evs = a:pollEvents()
            local found = false
            for _, e in ipairs(evs) do
                if e.type == "finished" then found = true end
            end
            expect_true(found, "expected Finished event")
        end)

        it("looping clip emits Looped event", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("loop", {0}, 10, true)
            a:play("loop")
            a:update(1.0) -- enough to loop
            local evs = a:pollEvents()
            local found = false
            for _, e in ipairs(evs) do
                if e.type == "looped" then found = true end
            end
            expect_true(found, "expected Looped event")
        end)

        it("pollEvents drains events", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("once", {0}, 10, false)
            a:play("once")
            a:update(1.0)
            a:pollEvents() -- drain
            local evs2 = a:pollEvents()
            expect_equal(0, #evs2)
        end)
    end)

    -- ── speed edge cases ────────────────────────────────────────────

    describe("speed edge cases", function()
        it("speed 0 freezes playback", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            a:addClip("walk", {0, 1}, 10, true)
            a:play("walk")
            a:setSpeed(0)
            local f0 = a:getCurrentFrame()
            a:update(1.0)
            expect_equal(f0, a:getCurrentFrame())
        end)

        it("setSpeed clamps negative to 0", function()
            local a = lurek.animation.new()
            a:setSpeed(-5)
            expect_true(a:getSpeed() >= 0)
        end)
    end)

    -- ── clip switching ──────────────────────────────────────────────

    describe("clip switching", function()
        it("switching clips resets frame to 0", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            a:addClip("a", {0, 1}, 10, true)
            a:addClip("b", {0, 1}, 10, true)
            a:play("a")
            a:update(0.5)
            a:play("b")
            expect_equal(0, a:getCurrentFrame())
        end)
    end)

    -- ── addClipFromGrid ─────────────────────────────────────────────

    describe("addClipFromGrid", function()
        it("creates clip from grid in one call", function()
            local a = lurek.animation.new()
            expect_no_error(function()
                a:addClipFromGrid("walk", 128, 128, 32, 32, 0, 4, 12, true)
            end)
            expect_equal(1, a:getClipCount())
            expect_equal(4, a:getFrameCount())
        end)
    end)

    -- ── frame advancement precision ─────────────────────────────────

    describe("frame advancement", function()
        it("zero dt does not advance frame", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            a:addClip("walk", {0, 1}, 10, true)
            a:play("walk")
            a:update(0)
            expect_equal(0, a:getCurrentFrame())
        end)
    end)
end)

test_summary()
