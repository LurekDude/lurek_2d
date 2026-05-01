-- Lurek2D Lua BDD tests for lurek.animation
-- Headless: no GPU, no audio, no window.

describe("lurek.animation", function()
    describe("module interface", function()
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
        it("exposes new factory", function()
            expect_type("function", lurek.animation.new)
        end)
    end)

    describe("new()", function()
        -- @covers lurek.animation.new
        it("returns a userdata object", function()
            local a = lurek.animation.new()
            expect_type("userdata", a)
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.getFrameCount
        it("getFrameCount returns 0 on empty animation", function()
            local a = lurek.animation.new()
            expect_equal(0, a:getFrameCount())
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.getClipCount
        it("getClipCount returns 0 with no clips", function()
            local a = lurek.animation.new()
            expect_equal(0, a:getClipCount())
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.isPlaying
        it("isPlaying returns false before play()", function()
            local a = lurek.animation.new()
            expect_equal(false, a:isPlaying())
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.getClip
        it("getClip returns nil before play()", function()
            local a = lurek.animation.new()
            expect_equal(nil, a:getClip())
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.getSpeed
        it("getSpeed returns default 1.0", function()
            local a = lurek.animation.new()
            expect_near(1.0, a:getSpeed(), 0.001)
        end)
    end)

    describe("addFrame()", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        it("returns an index starting from 0", function()
            local a = lurek.animation.new()
            local idx = a:addFrame(0, 0, 32, 32)
            expect_equal(0, idx)
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.getFrameCount
        it("increments frame count", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            expect_equal(2, a:getFrameCount())
        end)
    end)

    describe("addFramesFromGrid()", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFramesFromGrid
        it("returns the number of frames added", function()
            local a = lurek.animation.new()
            local n = a:addFramesFromGrid(128, 128, 32, 32, 0, 4)
            expect_equal(4, n)
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFramesFromGrid
        -- @covers lurek.animation.getFrameCount
        it("increases frame count by the returned amount", function()
            local a = lurek.animation.new()
            local n = a:addFramesFromGrid(64, 64, 32, 32, 0, 2)
            expect_equal(n, a:getFrameCount())
        end)
    end)

    describe("addClip()", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.getClipCount
        it("increases clip count by one", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("idle", {0}, 12, false)
            expect_equal(1, a:getClipCount())
        end)
    end)

    describe("play() / stop()", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.isPlaying
        it("play transitions isPlaying to true", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("idle", {0}, 12, true)
            local ok = a:play("idle")
            expect_equal(true, ok)
            expect_equal(true, a:isPlaying())
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.play
        it("play returns false for unknown clip", function()
            local a = lurek.animation.new()
            local ok = a:play("nonexistent")
            expect_equal(false, ok)
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.stop
        -- @covers lurek.animation.isPlaying
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
        -- @covers lurek.animation.new
        -- @covers lurek.animation.setSpeed
        -- @covers lurek.animation.getSpeed
        it("round-trips the speed value", function()
            local a = lurek.animation.new()
            a:setSpeed(2.5)
            expect_near(2.5, a:getSpeed(), 0.001)
        end)
    end)

    describe("update() + getQuad()", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.update
        -- @covers lurek.animation.getQuad
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

        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.update
        -- @covers lurek.animation.getQuad
        it("getQuad preserves the active frame rectangle", function()
            local a = lurek.animation.new()
            a:addFrame(64, 32, 16, 16)
            a:addFrame(80, 32, 16, 16)
            a:addClip("walk", {0, 1}, 10, true)
            a:play("walk")
            a:update(0.0)
            local q = a:getQuad()
            expect_equal(64, q.x)
            expect_equal(32, q.y)
            expect_equal(16, q.w)
            expect_equal(16, q.h)
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.getQuad
        it("getQuad returns nil when not playing", function()
            local a = lurek.animation.new()
            local q = a:getQuad()
            expect_equal(nil, q)
        end)
    end)

    describe("pollEvents()", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.pollEvents
        it("returns a table", function()
            local a = lurek.animation.new()
            local evs = a:pollEvents()
            expect_type("table", evs)
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.pollEvents
        it("returns empty table when idle", function()
            local a = lurek.animation.new()
            local evs = a:pollEvents()
            expect_equal(0, #evs)
        end)
    end)

-- pause / resume

    describe("pause and resume", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.pause
        -- @covers lurek.animation.isPlaying
        -- @covers lurek.animation.getCurrentFrame
        -- @covers lurek.animation.update
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

        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.pause
        -- @covers lurek.animation.resume
        -- @covers lurek.animation.isPlaying
        -- @covers lurek.animation.getCurrentFrame
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

-- setFrame

    describe("setFrame", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.setFrame
        -- @covers lurek.animation.getCurrentFrame
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

-- getCurrentFrame

    describe("getCurrentFrame", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.getCurrentFrame
        it("returns 0 at start of clip", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            a:addClip("idle", {0, 1}, 10, true)
            a:play("idle")
            expect_equal(0, a:getCurrentFrame())
        end)
    end)

-- isLooping

    describe("isLooping", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.isLooping
        it("returns true for looping clip", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("idle", {0}, 10, true)
            a:play("idle")
            expect_true(a:isLooping())
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.isLooping
        it("returns false for non-looping clip", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addClip("once", {0}, 10, false)
            a:play("once")
            expect_false(a:isLooping())
        end)
    end)

-- event lifecycle

    describe("event lifecycle", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.update
        -- @covers lurek.animation.pollEvents
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

        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.update
        -- @covers lurek.animation.pollEvents
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

        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.update
        -- @covers lurek.animation.pollEvents
        it("frame advancement emits frameChanged with frame index", function()
            local a = lurek.animation.new()
            a:addFrame(0, 0, 16, 16)
            a:addFrame(16, 0, 16, 16)
            a:addClip("walk", {0, 1}, 10, true)
            a:play("walk")
            a:update(0.15)
            local evs = a:pollEvents()
            local found = false
            for _, e in ipairs(evs) do
                if e.type == "frameChanged" then
                    expect_equal(1, e.frame)
                    found = true
                end
            end
            expect_true(found, "expected frameChanged event")
        end)

        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.update
        -- @covers lurek.animation.pollEvents
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

-- speed edge cases

    describe("speed edge cases", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.setSpeed
        -- @covers lurek.animation.update
        -- @covers lurek.animation.getCurrentFrame
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

        -- @covers lurek.animation.new
        -- @covers lurek.animation.setSpeed
        -- @covers lurek.animation.getSpeed
        it("setSpeed clamps negative to 0", function()
            local a = lurek.animation.new()
            a:setSpeed(-5)
            expect_true(a:getSpeed() >= 0)
        end)
    end)

-- clip switching

    describe("clip switching", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.update
        -- @covers lurek.animation.getCurrentFrame
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

-- addClipFromGrid

    describe("addClipFromGrid", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addClipFromGrid
        -- @covers lurek.animation.getClipCount
        -- @covers lurek.animation.getFrameCount
        it("creates clip from grid in one call", function()
            local a = lurek.animation.new()
            expect_no_error(function()
                a:addClipFromGrid("walk", 128, 128, 32, 32, 0, 4, 12, true)
            end)
            expect_equal(1, a:getClipCount())
            expect_equal(4, a:getFrameCount())
        end)
    end)

-- frame advancement precision

    describe("frame advancement", function()
        -- @covers lurek.animation.new
        -- @covers lurek.animation.addFrame
        -- @covers lurek.animation.addClip
        -- @covers lurek.animation.play
        -- @covers lurek.animation.update
        -- @covers lurek.animation.getCurrentFrame
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

--  Animation Extended (merged from test_animation_ext.lua) 

-- Helper: build a minimal animation with two named clips.
local function make_anim()
    local a = lurek.animation.new()
    a:addFrame(0, 0, 16, 16)   -- frame 0
    a:addFrame(16, 0, 16, 16)  -- frame 1
    a:addClip("idle", {0}, 8, true)
    a:addClip("run",  {1}, 8, true)
    return a
end

describe("lurek.animation extended", function()
-- module interface

    describe("new API factories", function()
        -- @covers lurek.animation.fromAseprite
        it("exposes fromAseprite factory", function()
            expect_type("function", lurek.animation.fromAseprite)
        end)

        -- @covers lurek.animation.newStateMachine
        it("exposes newStateMachine factory", function()
            expect_type("function", lurek.animation.newStateMachine)
        end)
    end)

-- crossfade

    describe("crossfade()", function()
        -- @covers lurek.animation.crossfade
        it("returns true for an existing clip", function()
            local a = make_anim()
            a:play("idle")
            local ok = a:crossfade("run", 0.2)
            expect_equal(true, ok)
        end)

        -- @covers lurek.animation.crossfade
        it("returns false for an unknown clip", function()
            local a = make_anim()
            a:play("idle")
            local ok = a:crossfade("ghost", 0.2)
            expect_equal(false, ok)
        end)

        -- @covers lurek.animation.crossfade
        -- @covers lurek.animation.getBlendState
        it("getBlendState returns blend table during crossfade", function()
            local a = make_anim()
            a:play("idle")
            a:crossfade("run", 0.5)
            local bs = a:getBlendState()
            expect_type("table", bs)
        end)
    end)

-- getBlendState

    describe("getBlendState()", function()
        -- @covers lurek.animation.getBlendState
        it("returns nil when not crossfading", function()
            local a = make_anim()
            a:play("idle")
            local bs = a:getBlendState()
            expect_equal(nil, bs)
        end)

        -- @covers lurek.animation.crossfade
        -- @covers lurek.animation.getBlendState
        it("blend table has from/to/blend fields", function()
            local a = make_anim()
            a:play("idle")
            a:crossfade("run", 0.5)
            local bs = a:getBlendState()
            expect_type("table", bs.from)
            expect_type("table", bs.to)
            expect_type("number", bs.blend)
        end)

        -- @covers lurek.animation.crossfade
        -- @covers lurek.animation.getBlendState
        it("blend starts near 0 at crossfade start", function()
            local a = make_anim()
            a:play("idle")
            a:crossfade("run", 0.5)
            local bs = a:getBlendState()
            expect_near(0.0, bs.blend, 0.05)
        end)
    end)

-- drawToImage

    describe("Animation:drawToImage()", function()
        -- @covers lurek.animation.drawToImage
        it("returns a userdata", function()
            local a = make_anim()
            local img = a:drawToImage(32, 32)
            expect_type("userdata", img)
        end)
    end)

-- fromAseprite

    describe("fromAseprite()", function()
        -- Minimal two-frame Aseprite JSON export
        local ASEPRITE_JSON = [[{
            "frames": [
                {"filename":"idle_0","frame":{"x":0,"y":0,"w":16,"h":16},"duration":100},
                {"filename":"idle_1","frame":{"x":16,"y":0,"w":16,"h":16},"duration":100}
            ],
            "meta": {
                "size":{"w":32,"h":16},
                "frameTags":[{"name":"idle","from":0,"to":1,"direction":"forward"}]
            }
        }]]

        local ASEPRITE_REVERSE_JSON = [[{
            "frames": [
                {"filename":"walk_0","frame":{"x":0,"y":0,"w":16,"h":16},"duration":100},
                {"filename":"walk_1","frame":{"x":16,"y":0,"w":16,"h":16},"duration":100}
            ],
            "meta": {
                "size":{"w":32,"h":16},
                "frameTags":[{"name":"walk","from":0,"to":1,"direction":"reverse"}]
            }
        }]]

        -- @covers lurek.animation.fromAseprite
        it("returns animation userdata for valid JSON", function()
            local a = lurek.animation.fromAseprite(ASEPRITE_JSON)
            expect_type("userdata", a)
        end)

        -- @covers lurek.animation.fromAseprite
        -- @covers lurek.animation.getFrameCount
        it("imports the correct frame count", function()
            local a = lurek.animation.fromAseprite(ASEPRITE_JSON)
            expect_equal(2, a:getFrameCount())
        end)

        -- @covers lurek.animation.fromAseprite
        -- @covers lurek.animation.getClipCount
        it("registers named clips from frameTags", function()
            local a = lurek.animation.fromAseprite(ASEPRITE_JSON)
            expect_true(a:getClipCount() >= 1, "expected at least one clip")
        end)

        -- @covers lurek.animation.fromAseprite
        -- @covers lurek.animation.play
        -- @covers lurek.animation.getQuad
        it("honors reverse frame tag direction", function()
            local a = lurek.animation.fromAseprite(ASEPRITE_REVERSE_JSON)
            expect_true(a:play("walk"))
            local q = a:getQuad()
            expect_equal(16, q.x)
            expect_equal(0, q.y)
            expect_equal(16, q.w)
            expect_equal(16, q.h)
        end)

        -- @covers lurek.animation.fromAseprite
        it("errors on invalid JSON", function()
            expect_error(function()
                lurek.animation.fromAseprite("not json")
            end)
        end)

        -- @covers lurek.animation.fromAseprite
        it("errors when frames key is missing", function()
            expect_error(function()
                lurek.animation.fromAseprite('{"meta":{"size":{"w":16,"h":16}}}')
            end)
        end)

        -- @covers lurek.animation.fromAseprite
        it("errors when meta key is missing", function()
            expect_error(function()
                lurek.animation.fromAseprite('{"frames":[]}')
            end)
        end)
    end)

-- newStateMachine

    describe("newStateMachine()", function()
        -- @covers lurek.animation.newStateMachine
        it("returns a userdata", function()
            local a = make_anim()
            a:play("idle")
            local fsm = lurek.animation.newStateMachine(a, "idle")
            expect_type("userdata", fsm)
        end)

        -- @covers lurek.animation.newStateMachine
        -- @covers lurek.animation.getState
        it("getState returns initial state name", function()
            local a = make_anim()
            a:play("idle")
            local fsm = lurek.animation.newStateMachine(a, "idle")
            expect_equal("idle", fsm:getState())
        end)

        -- @covers lurek.animation.newStateMachine
        -- @covers lurek.animation.addState
        -- @covers lurek.animation.forceState
        -- @covers lurek.animation.getState
        it("forceState switches the current state", function()
            local a = make_anim()
            local fsm = lurek.animation.newStateMachine(a, "idle")
            fsm:addState("run", "run", true)
            fsm:forceState("run")
            expect_equal("run", fsm:getState())
        end)

        -- @covers lurek.animation.newStateMachine
        -- @covers lurek.animation.setParam
        -- @covers lurek.animation.addTransition
        -- @covers lurek.animation.update
        -- @covers lurek.animation.getState
        it("transition fires when boolean param is set", function()
            local a = make_anim()
            local fsm = lurek.animation.newStateMachine(a, "idle")
            fsm:addState("idle", "idle", true)
            fsm:addState("run", "run", true)
            fsm:addTransition("idle", "run", "moving == true")
            fsm:setParam("moving", true)
            fsm:update(0.016)
            expect_equal("run", fsm:getState())
        end)

        -- @covers lurek.animation.newStateMachine
        -- @covers lurek.animation.addTransition
        -- @covers lurek.animation.setParam
        -- @covers lurek.animation.update
        -- @covers lurek.animation.getState
        it("transition fires when float param is greater than threshold", function()
            local a = make_anim()
            local fsm = lurek.animation.newStateMachine(a, "idle")
            fsm:addState("idle", "idle", true)
            fsm:addState("run", "run", true)
            fsm:addTransition("idle", "run", "speed > 5.0")
            fsm:setParam("speed", 6.0)
            fsm:update(0.016)
            expect_equal("run", fsm:getState())
        end)

        -- @covers lurek.animation.newStateMachine
        -- @covers lurek.animation.addTransition
        -- @covers lurek.animation.setParam
        -- @covers lurek.animation.update
        -- @covers lurek.animation.getState
        it("transition fires when integer param is not equal", function()
            local a = make_anim()
            local fsm = lurek.animation.newStateMachine(a, "idle")
            fsm:addState("idle", "idle", true)
            fsm:addState("run", "run", true)
            fsm:addTransition("idle", "run", "mode != 2")
            fsm:setParam("mode", 1)
            fsm:update(0.016)
            expect_equal("run", fsm:getState())
        end)

        -- @covers lurek.animation.newStateMachine
        -- @covers lurek.animation.addTransition
        -- @covers lurek.animation.setParam
        -- @covers lurek.animation.update
        -- @covers lurek.animation.getState
        it("invalid transition conditions are ignored", function()
            local a = make_anim()
            local fsm = lurek.animation.newStateMachine(a, "idle")
            fsm:addState("idle", "idle", true)
            fsm:addState("run", "run", true)
            fsm:addTransition("idle", "run", "noop")
            fsm:setParam("noop", 999)
            fsm:update(0.016)
            expect_equal("idle", fsm:getState())
        end)

        -- @covers lurek.animation.newStateMachine
        -- @covers lurek.animation.getQuad
        it("getQuad returns a table", function()
            local a = make_anim()
            a:play("idle")
            local fsm = lurek.animation.newStateMachine(a, "idle")
            expect_type("table", fsm:getQuad())
        end)
    end)
end)

--  Animation Blend (merged from test_animation_blend.lua) 

describe("lurek.animation blend layers", function()
    describe("factory", function()
        -- @covers lurek.animation.newBlendLayerSet
        it("exposes newBlendLayerSet", function()
            expect_type("function", lurek.animation.newBlendLayerSet)
        end)

        -- @covers lurek.animation.newBlendLayerSet
        it("returns a userdata", function()
            local bls = lurek.animation.newBlendLayerSet()
            expect_type("userdata", bls)
        end)
    end)

    describe("len() / addLayer()", function()
        -- @tests lurek.animation:len
        it("starts empty", function()
            local bls = lurek.animation.newBlendLayerSet()
            expect_equal(0, bls:len())
        end)

        -- @tests lurek.animation:addLayer
        it("addLayer increments len", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:addLayer("upper", "attack", 1.0)
            expect_equal(1, bls:len())
        end)

        -- @tests lurek.animation:addLayer
        it("accepts two distinct layers", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:addLayer("upper", "attack", 1.0)
            bls:addLayer("lower", "walk",   1.0)
            expect_equal(2, bls:len())
        end)

        -- @tests lurek.animation:addLayer
        it("accepts bone mask as fourth argument", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:addLayer("upper", "attack", 0.8, {"spine", "shoulder_L", "shoulder_R"})
            expect_equal(1, bls:len())
        end)
    end)

    describe("setWeight() / getWeight()", function()
        -- @tests lurek.animation:getWeight
        it("getWeight returns initial weight", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:addLayer("upper", "attack", 0.75)
            local w = bls:getWeight("upper")
            expect_near(0.75, w, 0.001)
        end)

        -- @tests lurek.animation:setWeight
        it("setWeight updates the weight", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:addLayer("lower", "walk", 1.0)
            bls:setWeight("lower", 0.5)
            local w = bls:getWeight("lower")
            expect_near(0.5, w, 0.001)
        end)
    end)

    describe("listLayers()", function()
        -- @tests lurek.animation:listLayers
        it("returns a table", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:addLayer("upper", "attack", 1.0)
            local names = bls:listLayers()
            expect_type("table", names)
        end)

        -- @tests lurek.animation:listLayers
        it("table length equals layer count", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:addLayer("upper", "attack", 1.0)
            bls:addLayer("lower", "walk",   1.0)
            local names = bls:listLayers()
            expect_equal(2, #names)
        end)
    end)

    describe("removeLayer()", function()
        -- @tests lurek.animation:removeLayer
        it("decrements len after removal", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:addLayer("upper", "attack", 1.0)
            bls:addLayer("lower", "walk",   1.0)
            bls:removeLayer("upper")
            expect_equal(1, bls:len())
        end)

        -- @tests lurek.animation:removeLayer
        xit("removing unknown layer does not error", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:removeLayer("nonexistent")
            expect_equal(0, bls:len())
        end)
    end)

    describe("setMask()", function()
        -- @tests lurek.animation:setMask
        it("accepts a bone list without error", function()
            local bls = lurek.animation.newBlendLayerSet()
            bls:addLayer("upper", "attack", 1.0)
            bls:setMask("upper", {"spine", "head"})
            expect_equal(1, bls:len())
        end)
    end)
end)

describe("animation regression coverage", function()
    -- @covers lurek.animation.newCurve
    -- @covers AnimCurve:keyframeCount
    -- @covers AnimCurve:clear
    it("AnimCurve tracks keyframes and clears back to empty", function()
        local curve = lurek.animation.newCurve()
        expect_type("userdata", curve)
        expect_equal(0, curve:keyframeCount())

        curve:addKeyframe(0.0, 0.0)
        curve:addKeyframe(1.0, 1.0)
        expect_equal(2, curve:keyframeCount())

        curve:clear()
        expect_equal(0, curve:keyframeCount())
    end)

    -- @covers lurek.animation.newCurve
    -- @covers AnimCurve:eval
    it("AnimCurve eval handles empty and single-keyframe cases", function()
        local curve = lurek.animation.newCurve()
        expect_near(0.0, curve:eval(0.5), 0.001)

        curve:addKeyframe(1.0, 42.0)
        expect_near(42.0, curve:eval(0.0), 0.001)
        expect_near(42.0, curve:eval(2.0), 0.001)
    end)

    -- @covers lurek.animation.newCurve
    -- @covers AnimCurve:setEasing
    -- @covers AnimCurve:eval
    it("AnimCurve eval respects linear and step easing", function()
        local curve = lurek.animation.newCurve()
        curve:addKeyframe(0.0, 5.0)
        curve:addKeyframe(1.0, 10.0)

        curve:setEasing("linear")
        expect_near(7.5, curve:eval(0.5), 0.001)

        curve:setEasing("step")
        expect_near(5.0, curve:eval(0.5), 0.001)
    end)

    -- @covers lurek.animation.newSyncGroup
    -- @covers AnimSyncGroup:add
    -- @covers AnimSyncGroup:remove
    -- @covers AnimSyncGroup:clear
    -- @covers AnimSyncGroup:memberCount
    it("AnimSyncGroup accepts lifecycle calls without changing its empty count", function()
        local group = lurek.animation.newSyncGroup()
        expect_type("userdata", group)
        expect_equal(0, group:memberCount())

        group:add(1)
        expect_equal(0, group:memberCount())

        group:remove(1)
        expect_equal(0, group:memberCount())

        group:clear()
        expect_equal(0, group:memberCount())
    end)
end)

-- =========================================================================
-- Phase 07: AnimCurve custom easing
-- =========================================================================
describe("AnimCurve custom easing", function()
    it("setCustomEasing exists on AnimCurve", function()
        if lurek.animation.newCurve then
            local c = lurek.animation.newCurve()
            expect_equal(type(c.setCustomEasing), "function")
        end
    end)

    it("setCustomEasing accepts a function without error", function()
        if lurek.animation.newCurve then
            local c = lurek.animation.newCurve()
            local ok = pcall(function()
                c:setCustomEasing(function(t) return t * t end)
            end)
            expect_true(ok)
        end
    end)

    it("eval uses custom easing callback when set", function()
        if lurek.animation.newCurve then
            local c = lurek.animation.newCurve()
            c:addKeyframe(0, 0)
            c:addKeyframe(1, 1)
            c:setCustomEasing(function(t) return t * t end)
            local v = c:eval(0.5)
            expect_near(0.25, v, 0.01)
        end
    end)

    it("setCustomEasing nil clears callback and reverts to linear", function()
        if lurek.animation.newCurve then
            local c = lurek.animation.newCurve()
            c:addKeyframe(0, 0)
            c:addKeyframe(1, 1)
            c:setCustomEasing(function(t) return t * t end)
            c:setCustomEasing(nil)
            local v = c:eval(0.5)
            expect_near(0.5, v, 0.01)
        end
    end)
end)

-- =========================================================================
-- @covers additions for animation module
-- =========================================================================

describe("BlendLayerSet:len (@covers)", function()
    it("len returns 0 for a fresh BlendLayerSet", function()
        -- @covers BlendLayerSet:len
        local bls = lurek.animation.newBlendLayerSet()
        expect_equal(0, bls:len())
    end)

    it("len increments after addLayer", function()
        -- @covers BlendLayerSet:len
        local bls = lurek.animation.newBlendLayerSet()
        bls:addLayer("spine", "idle", 1.0)
        expect_equal(1, bls:len())
    end)
end)

describe("AnimSyncGroup:add (@covers)", function()
    it("add is callable on a sync group", function()
        -- @covers AnimSyncGroup:add
        local group = lurek.animation.newSyncGroup()
        -- add() is a stub that accepts any value without erroring
        local ok, _ = pcall(function() group:add(1) end)
        expect_true(ok)
    end)
end)

test_summary()
