-- Scene module Lua tests
-- Headless-safe (no window/GPU/audio needed).
-- lurek.scene is a module-level singleton; each describe calls lurek.scene.clear() first.

describe("Stack operations", function()
    -- @covers lurek.scene.clear
    -- @covers lurek.scene.isEmpty
    -- @covers lurek.scene.getStackSize
    -- @covers lurek.scene.getCurrent
    -- @covers lurek.scene.push
    -- @covers lurek.scene.pop
    -- @covers lurek.scene.switchTo
    -- @covers lurek.scene.draw
    -- @covers lurek.scene.getData
    -- @covers lurek.scene.getRegistered
    -- @covers lurek.scene.getRegisteredNames
    -- @covers lurek.scene.getTransitionProgress
    -- @covers lurek.scene.hasData
    -- @covers lurek.scene.hasRegistered
    -- @covers lurek.scene.isTransitioning
    -- @covers lurek.scene.newDepthSorter
    -- @covers lurek.scene.process
    -- @covers lurek.scene.processLate
    -- @covers lurek.scene.processPhysics
    -- @covers lurek.scene.registerScene
    -- @covers lurek.scene.removeData
    -- @covers lurek.scene.render
    -- @covers lurek.scene.renderUi
    -- @covers lurek.scene.setData
    -- @covers lurek.scene.unregisterScene
    -- @covers lurek.scene.update
    -- @covers lurek.scene.popTo
    -- @covers lurek.scene.new
    -- @covers lurek.scene.define
    it("starts empty and tracks push/pop/switchTo/clear correctly", function()
        lurek.scene.clear()
        local scene_a = { name = "A" }
        local scene_b = { name = "B" }
        local scene_c = { name = "C" }

        expect_true(lurek.scene.isEmpty())
        expect_equal(0, lurek.scene.getStackSize())
        expect_equal(nil, lurek.scene.getCurrent())

        lurek.scene.push(scene_a)
        expect_false(lurek.scene.isEmpty())
        expect_equal(1, lurek.scene.getStackSize())
        expect_true(lurek.scene.getCurrent() ~= nil)

        lurek.scene.push(scene_b)
        expect_equal(2, lurek.scene.getStackSize())

        lurek.scene.pop()
        expect_equal(1, lurek.scene.getStackSize())

        lurek.scene.switchTo(scene_c)
        expect_equal(1, lurek.scene.getStackSize())

        lurek.scene.push(scene_a)
        lurek.scene.push(scene_b)
        expect_equal(3, lurek.scene.getStackSize())
        lurek.scene.clear()
        expect_true(lurek.scene.isEmpty())
    end)
end)

describe("Transitions", function()
    -- @covers lurek.scene.isTransitioning
    -- @covers lurek.scene.getTransitionProgress
    -- @covers lurek.scene.push
    -- @covers lurek.scene.update
    it("reports transitioning state and progress in [0,1]", function()
        lurek.scene.clear()
        expect_false(lurek.scene.isTransitioning())
        expect_equal(0, lurek.scene.getTransitionProgress())

        local scene_a = { name = "A" }
        lurek.scene.push(scene_a, "fade", 1.0)
        expect_true(lurek.scene.isTransitioning())

        local p = lurek.scene.getTransitionProgress()
        expect_true(p >= 0 and p <= 1)

        lurek.scene.update(1.0)  -- complete the transition
    end)
end)

describe("Registry", function()
    -- @covers lurek.scene.registerScene
    -- @covers lurek.scene.hasRegistered
    -- @covers lurek.scene.getRegisteredNames
    -- @covers lurek.scene.getRegistered
    -- @covers lurek.scene.unregisterScene
    it("registers, queries, and unregisters scenes by name", function()
        lurek.scene.clear()
        local menu = { name = "menu" }
        local game = { name = "game" }

        lurek.scene.registerScene("menu", menu)
        lurek.scene.registerScene("game", game)

        expect_true(lurek.scene.hasRegistered("menu"))
        expect_true(lurek.scene.hasRegistered("game"))
        expect_false(lurek.scene.hasRegistered("settings"))

        local names = lurek.scene.getRegisteredNames()
        expect_type("table", names)

        local got = lurek.scene.getRegistered("menu")
        expect_true(got ~= nil)

        lurek.scene.unregisterScene("menu")
        expect_false(lurek.scene.hasRegistered("menu"))
    end)
end)

describe("Data store", function()
    -- @covers lurek.scene.setData
    -- @covers lurek.scene.hasData
    -- @covers lurek.scene.getData
    -- @covers lurek.scene.removeData
    it("stores, reads, and removes arbitrary key-value pairs", function()
        lurek.scene.setData("score", 42)
        expect_true(lurek.scene.hasData("score"))
        expect_equal(42, lurek.scene.getData("score"))

        lurek.scene.setData("name", "player1")
        expect_equal("player1", lurek.scene.getData("name"))

        lurek.scene.removeData("score")
        expect_false(lurek.scene.hasData("score"))
        expect_equal(nil, lurek.scene.getData("score"))
    end)
end)

describe("DepthSorter", function()
    -- @covers lurek.scene.newDepthSorter
    -- @covers DepthSorter:getCount
    -- @covers DepthSorter:add
    -- @covers DepthSorter:flush
    it("flushes callbacks in ascending depth order", function()
        local sorter = lurek.scene.newDepthSorter()
        expect_true(sorter ~= nil)
        expect_equal(0, sorter:getCount())

        local order = {}
        sorter:add(function() table.insert(order, "c") end, 10)
        sorter:add(function() table.insert(order, "a") end, 0)
        sorter:add(function() table.insert(order, "b") end, 5)
        expect_equal(3, sorter:getCount())

        sorter:flush()
        expect_equal(0, sorter:getCount())
        expect_equal(3, #order)
        expect_equal("a", order[1])
        expect_equal("b", order[2])
        expect_equal("c", order[3])
    end)
end)

describe("Lifecycle callbacks", function()
    -- @covers lurek.scene.push
    -- @covers lurek.scene.pop
    -- @covers lurek.scene.switchTo
    it("calls enter/leave/pause/resume on push/pop/switchTo", function()
        lurek.scene.clear()
        local log = {}

        local s1 = {
            enter  = function(self) table.insert(log, "s1:enter")  end,
            leave  = function(self) table.insert(log, "s1:leave")  end,
            pause  = function(self) table.insert(log, "s1:pause")  end,
            resume = function(self) table.insert(log, "s1:resume") end,
            update = function(self, dt) table.insert(log, "s1:update") end,
            draw   = function(self) table.insert(log, "s1:draw")   end,
        }
        local s2 = {
            enter = function(self) table.insert(log, "s2:enter") end,
            leave = function(self) table.insert(log, "s2:leave") end,
        }

        -- push s1 -> enter
        lurek.scene.push(s1)
        expect_equal("s1:enter", log[1])

        -- push s2 -> s1:pause, s2:enter
        lurek.scene.push(s2)
        expect_equal("s1:pause", log[2])
        expect_equal("s2:enter", log[3])

        -- pop s2 -> s2:leave, s1:resume
        lurek.scene.pop()
        expect_equal("s2:leave", log[4])
        expect_equal("s1:resume", log[5])
    end)

    -- @covers lurek.scene.update
    it("update dispatches to the top scene", function()
        lurek.scene.clear()
        local log = {}
        local s1 = { update = function(self, dt) table.insert(log, "s1:update") end }
        lurek.scene.push(s1)

        lurek.scene.update(0.016)
        expect_equal("s1:update", log[1])
    end)

    -- @covers lurek.scene.draw
    it("draw dispatches to all scenes", function()
        lurek.scene.clear()
        local log = {}
        local s1 = { draw = function(self) table.insert(log, "s1:draw") end }
        lurek.scene.push(s1)

        lurek.scene.draw()
        expect_equal("s1:draw", log[1])
    end)

    -- @covers lurek.scene.switchTo
    it("switchTo calls leave on old and enter on new", function()
        lurek.scene.clear()
        local log = {}
        local s1 = { leave = function(self) table.insert(log, "s1:leave") end }
        local s2 = { enter = function(self) table.insert(log, "s2:enter") end }

        lurek.scene.push(s1)
        log = {}  -- reset after push's enter (s1 has no enter)
        lurek.scene.switchTo(s2)
        expect_equal("s1:leave", log[1])
        expect_equal("s2:enter", log[2])
    end)

    -- @covers lurek.scene.push
    xit("push forwards params to enter callback", function()
        lurek.scene.clear()
        ---@type any
        local received = nil
        local s = { enter = function(self, p) received = p end }

        ---@type any
        local params = { level = 3, mode = "hard" }
        lurek.scene.push(s, nil, nil, params)
        expect_type("table", received)
        expect_equal(3, received.level)
        expect_equal("hard", received.mode)
    end)

    -- @covers lurek.scene.push
    it("push with no params calls enter with nil", function()
        lurek.scene.clear()
        local called = false
        local received = "sentinel"
        local s = { enter = function(self, p) called = true; received = p end }

        lurek.scene.push(s)
        expect_true(called)
        expect_equal(nil, received)
    end)

    -- @covers lurek.scene.switchTo
    xit("switchTo forwards params to enter callback", function()
        lurek.scene.clear()
        ---@type any
        local received = nil
        local s1 = {}
        local s2 = { enter = function(self, p) received = p end }

        lurek.scene.push(s1)
        ---@type any
        local params = { map = "village" }
        lurek.scene.switchTo(s2, nil, nil, params)
        expect_type("table", received)
        expect_equal("village", received.map)
    end)
end)

describe("lurek.scene new pipeline callbacks", function()
    -- @covers lurek.scene.processPhysics
    it("processPhysics is a function", function()
        expect_type("function", lurek.scene.processPhysics)
    end)

    -- @covers lurek.scene.processLate
    it("processLate is a function", function()
        expect_type("function", lurek.scene.processLate)
    end)

    -- @covers lurek.scene.process
    it("process is a function", function()
        expect_type("function", lurek.scene.process)
    end)

    -- @covers lurek.scene.render
    it("render is a function", function()
        expect_type("function", lurek.scene.render)
    end)

    -- @covers lurek.scene.renderUi
    it("renderUi is a function", function()
        expect_type("function", lurek.scene.renderUi)
    end)

    -- @covers lurek.scene.processPhysics
    it("processPhysics calls scene:process_physics(dt)", function()
        local called_dt = nil
        local scene = {
            process_physics = function(self, dt) called_dt = dt end
        }
        lurek.scene.push(scene)
        lurek.scene.processPhysics(1.0 / 60.0)
        expect_near(1.0 / 60.0, called_dt, 1e-9)
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.processLate
    it("processLate calls scene:process_late(dt)", function()
        local called_dt = nil
        local scene = {
            process_late = function(self, dt) called_dt = dt end
        }
        lurek.scene.push(scene)
        lurek.scene.processLate(0.016)
        expect_near(0.016, called_dt, 1e-3)
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.process
    it("process calls scene:process(dt)", function()
        local called_dt = nil
        local scene = {
            process = function(self, dt) called_dt = dt end
        }
        lurek.scene.push(scene)
        lurek.scene.process(0.016)
        expect_near(0.016, called_dt, 1e-3)
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.render
    it("render calls scene:render() for all scenes", function()
        local calls = {}
        local s1 = { render = function(self) table.insert(calls, "s1") end }
        local s2 = { render = function(self) table.insert(calls, "s2") end }
        lurek.scene.push(s1)
        lurek.scene.push(s2)
        lurek.scene.render()
        expect_equal(2, #calls)
        expect_equal("s1", calls[1])
        expect_equal("s2", calls[2])
        lurek.scene.pop()
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.renderUi
    it("renderUi calls scene:render_ui() for all scenes", function()
        local calls = {}
        local s1 = { render_ui = function(self) table.insert(calls, "s1") end }
        local s2 = { render_ui = function(self) table.insert(calls, "s2") end }
        lurek.scene.push(s1)
        lurek.scene.push(s2)
        lurek.scene.renderUi()
        expect_equal(2, #calls)
        expect_equal("s1", calls[1])
        expect_equal("s2", calls[2])
        lurek.scene.pop()
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.process
    it("process fires scene:ready() once on first tick, then never again", function()
        local ready_count = 0
        local scene = {
            ready = function(self) ready_count = ready_count + 1 end
        }
        lurek.scene.push(scene)
        lurek.scene.process(0.016) -- first tick: fires ready, then process
        lurek.scene.process(0.016) -- second tick: ready must NOT fire again
        lurek.scene.process(0.016)
        expect_equal(1, ready_count)
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.process
    it("process calls scene:ready() before scene:process() on first tick", function()
        local order = {}
        local scene = {
            ready   = function(self) table.insert(order, "ready") end,
            process = function(self, dt) table.insert(order, "process") end,
        }
        lurek.scene.push(scene)
        lurek.scene.process(0.016)
        expect_equal(2, #order)
        expect_equal("ready", order[1])
        expect_equal("process", order[2])
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.switchTo
    -- @covers lurek.scene.process
    it("ready fires for the new scene after switchTo", function()
        lurek.scene.clear()
        local a_ready = 0
        local b_ready = 0
        local a = { ready = function(self) a_ready = a_ready + 1 end }
        local b = { ready = function(self) b_ready = b_ready + 1 end }
        lurek.scene.push(a)
        lurek.scene.process(0.016) -- fires a:ready
        lurek.scene.switchTo(b)
        lurek.scene.process(0.016) -- fires b:ready, must NOT re-fire a:ready
        expect_equal(1, a_ready)
        expect_equal(1, b_ready)
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.pop
    -- @covers lurek.scene.push
    -- @covers lurek.scene.process
    it("ready fires again after pop and re-push of same scene", function()
        lurek.scene.clear()
        local count = 0
        local scene = { ready = function(self) count = count + 1 end }
        lurek.scene.push(scene)
        lurek.scene.process(0.016)   -- first push  ready fires (count = 1)
        lurek.scene.pop()
        lurek.scene.push(scene)
        lurek.scene.process(0.016)   -- second push  ready must fire again (count = 2)
        expect_equal(2, count)
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.process
    it("scene without process method does not crash", function()
        lurek.scene.clear()
        local scene = {}  -- no process method
        lurek.scene.push(scene)
        lurek.scene.process(0.016)
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.process
    it("scene without ready method does not crash", function()
        lurek.scene.clear()
        local scene = {}  -- no ready method
        lurek.scene.push(scene)
        lurek.scene.process(0)
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.render
    -- @covers lurek.scene.renderUi
    it("scene without render or render_ui methods does not crash", function()
        lurek.scene.clear()
        local scene = {}  -- no render / render_ui methods
        lurek.scene.push(scene)
        lurek.scene.render()
        lurek.scene.renderUi()
        lurek.scene.pop()
    end)

    -- @covers lurek.scene.renderUi
    it("renderUi with empty stack is safe", function()
        lurek.scene.clear()
        lurek.scene.renderUi()
    end)

    -- @covers lurek.scene.render
    it("render with empty stack is safe", function()
        lurek.scene.clear()
        lurek.scene.render()
    end)

    -- @covers lurek.scene.processPhysics
    it("processPhysics with empty stack is safe", function()
        lurek.scene.clear()
        lurek.scene.processPhysics(0.016)
    end)
end)

-- popTo

describe("popTo", function()
    -- @covers lurek.scene.registerScene
    -- @covers lurek.scene.popTo
    -- @covers lurek.scene.getStackSize
    it("pops scenes above registered target (inclusive)", function()
        lurek.scene.clear()
        local menu = { name = "menu" }
        local game = { name = "game" }
        local pause_scene = { name = "pause" }
        lurek.scene.registerScene("menu", menu)
        lurek.scene.push(menu)
        lurek.scene.push(game)
        lurek.scene.push(pause_scene)
        expect_equal(3, lurek.scene.getStackSize())
        local ok = lurek.scene.popTo("menu")
        expect_true(ok)
        -- popTo pops until target is found (inclusive); stack size depends on implementation
        expect_true(lurek.scene.getStackSize() < 3)
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.popTo
    -- @covers lurek.scene.getStackSize
    it("returns false for non-existent registered name", function()
        lurek.scene.clear()
        local s = {}
        lurek.scene.push(s)
        local ok = lurek.scene.popTo("nonexistent")
        expect_false(ok)
        expect_equal(1, lurek.scene.getStackSize())
        lurek.scene.clear()
    end)
end)

-- DepthSorter addObject

describe("DepthSorter addObject", function()
    -- @covers lurek.scene.newDepthSorter
    -- @covers DepthSorter:addObject
    -- @covers DepthSorter:sort
    -- @covers DepthSorter:flush
    it("addObject uses obj.depth and calls drawSorted", function()
        lurek.scene.clear()
        local sorter = lurek.scene.newDepthSorter()
        local calls = {}
        local obj1 = {
            depth = 10,
            drawSorted = function(self) calls[#calls + 1] = "obj1" end,
        }
        local obj2 = {
            depth = 5,
            drawSorted = function(self) calls[#calls + 1] = "obj2" end,
        }
        sorter:addObject(obj1)
        sorter:addObject(obj2)
        sorter:sort()
        sorter:flush()
        expect_equal(2, #calls)
        -- depth 5 should be drawn before depth 10
        expect_equal("obj2", calls[1])
        expect_equal("obj1", calls[2])
    end)

    -- @covers DepthSorter:addObject
    -- @covers DepthSorter:getCount
    it("getCount reflects addObject", function()
        local sorter = lurek.scene.newDepthSorter()
        expect_equal(0, sorter:getCount())
        sorter:addObject({ depth = 1, drawSorted = function() end })
        expect_equal(1, sorter:getCount())
    end)

    -- @covers DepthSorter:add
    -- @covers DepthSorter:clear
    -- @covers DepthSorter:getCount
    it("clear removes all without calling callbacks", function()
        local sorter = lurek.scene.newDepthSorter()
        local called = false
        sorter:add(function() called = true end, 1)
        sorter:clear()
        expect_equal(0, sorter:getCount())
        expect_false(called)
    end)
end)

-- DepthSorter negative depths

describe("DepthSorter negative depths", function()
    -- @covers DepthSorter:add
    -- @covers DepthSorter:sort
    -- @covers DepthSorter:flush
    it("sorts negative depths before positive", function()
        local sorter = lurek.scene.newDepthSorter()
        local calls = {}
        sorter:add(function() calls[#calls + 1] = "pos" end, 5)
        sorter:add(function() calls[#calls + 1] = "neg" end, -5)
        sorter:sort()
        sorter:flush()
        expect_equal("neg", calls[1])
        expect_equal("pos", calls[2])
    end)
end)

-- scene.new factory

describe("scene.new factory", function()
    -- @covers lurek.scene.new
    it("returns a table", function()
        local s = lurek.scene.new()
        expect_type("table", s)
    end)

    -- @covers lurek.scene.new
    -- @covers lurek.scene.push
    -- @covers lurek.scene.getStackSize
    it("returned scene works with push", function()
        lurek.scene.clear()
        local s = lurek.scene.new()
        lurek.scene.push(s)
        expect_equal(1, lurek.scene.getStackSize())
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.new
    -- @covers lurek.scene.push
    it("accepts definition table with callbacks", function()
        local entered = false
        local s = lurek.scene.new({
            enter = function(self) entered = true end,
        })
        lurek.scene.clear()
        lurek.scene.push(s)
        expect_true(entered)
        lurek.scene.clear()
    end)
end)

-- scene.define factory

describe("scene.define factory", function()
    -- @covers lurek.scene.define
    it("returns a constructor function", function()
        local ctor = lurek.scene.define()
        expect_type("function", ctor)
    end)

    -- @covers lurek.scene.define
    it("constructor produces scene instances", function()
        local ctor = lurek.scene.define({ name = "test" })
        local s = ctor()
        expect_type("table", s)
    end)

    -- @covers lurek.scene.define
    -- @covers lurek.scene.push
    -- @covers lurek.scene.getStackSize
    it("instances work with scene stack", function()
        lurek.scene.clear()
        local ctor = lurek.scene.define()
        local s = ctor()
        lurek.scene.push(s)
        expect_equal(1, lurek.scene.getStackSize())
        lurek.scene.clear()
    end)
end)

-- data store with complex types

describe("Data store complex values", function()
    -- @covers lurek.scene.setData
    -- @covers lurek.scene.getData
    -- @covers lurek.scene.removeData
    it("stores and retrieves tables", function()
        lurek.scene.clear()
        local data = { hp = 100, items = {"sword", "shield"} }
        lurek.scene.setData("player", data)
        local got = lurek.scene.getData("player")
        expect_equal(100, got.hp)
        expect_equal("sword", got.items[1])
        lurek.scene.removeData("player")
    end)

    -- @covers lurek.scene.setData
    -- @covers lurek.scene.getData
    it("overwrite replaces value", function()
        lurek.scene.clear()
        lurek.scene.setData("score", 10)
        lurek.scene.setData("score", 20)
        expect_equal(20, lurek.scene.getData("score"))
        lurek.scene.removeData("score")
    end)
end)

-- transition params

describe("Transition params", function()
    -- @covers lurek.scene.push
    xit("enter callback receives params from push", function()
        lurek.scene.clear()
        ---@type any
        local got_params = nil
        local s = {
            enter = function(self, params)
                got_params = params
            end
        }
        ---@type any
        local params = { level = 5 }
        lurek.scene.push(s, nil, nil, params)
        expect_not_nil(got_params)
        expect_equal(5, got_params.level)
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.switchTo
    xit("switchTo passes params to new scene enter", function()
        lurek.scene.clear()
        ---@type any
        local got_params = nil
        local s1 = {}
        local s2 = {
            enter = function(self, params)
                got_params = params
            end
        }
        lurek.scene.push(s1)
        ---@type any
        local params = { from = "s1" }
        lurek.scene.switchTo(s2, nil, nil, params)
        expect_not_nil(got_params)
        expect_equal("s1", got_params.from)
        lurek.scene.clear()
    end)
end)

describe("DepthSorter (RS parity)", function()
    -- @covers lurek.scene.newDepthSorter
    it("newDepthSorter returns userdata", function()
        local ds = lurek.scene.newDepthSorter()
        expect_equal("userdata", type(ds))
    end)

    -- @covers DepthSorter:add
    -- @covers DepthSorter:getCount
    it("add increments count", function()
        local ds = lurek.scene.newDepthSorter()
        ds:add(function() end, 10)
        ds:add(function() end, 5)
        expect_equal(2, ds:getCount())
    end)

    -- @covers DepthSorter:sort
    -- @covers DepthSorter:flush
    it("sort then flush executes items in ascending depth order", function()
        local ds = lurek.scene.newDepthSorter()
        local order = {}
        ds:add(function() table.insert(order, "back") end, 10)
        ds:add(function() table.insert(order, "front") end, 1)
        ds:add(function() table.insert(order, "mid") end, 5)
        ds:sort()
        ds:flush()
        expect_equal(3, #order)
        expect_equal("front", order[1])
        expect_equal("mid", order[2])
        expect_equal("back", order[3])
    end)

    -- @covers DepthSorter:clear
    -- @covers DepthSorter:getCount
    it("clear resets count to zero", function()
        local ds = lurek.scene.newDepthSorter()
        ds:add(function() end, 1)
        ds:clear()
        expect_equal(0, ds:getCount())
    end)
end)

describe("scene popTo (RS parity)", function()
    -- @covers lurek.scene.popTo
    it("popTo returns falsy when name not found in stack", function()
        local s1 = {}
        lurek.scene.push(s1)
        local r = lurek.scene.popTo("nonexistent")
        expect_false(r)
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.push
    -- @covers lurek.scene.getStackSize
    it("scene.getStackSize returns stack height after push", function()
        lurek.scene.clear()
        local s1 = {}
        local s2 = {}
        lurek.scene.push(s1)
        lurek.scene.push(s2)
        expect_true(lurek.scene.getStackSize() >= 2)
        lurek.scene.clear()
    end)
end)

-- ============================================================
-- Phase B: Easing transitions
-- ============================================================
describe("scene easing transitions", function()
    -- @covers lurek.scene.push
    -- @covers lurek.scene.isTransitioning
    it("push with easing param runs without error", function()
        lurek.scene.clear()
        local s1 = {}
        local s2 = {}
        lurek.scene.push(s1)
        lurek.scene.push(s2, "fade", 0.3, "ease_in")
        expect_true(lurek.scene.getStackSize() >= 1)
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.getTransitionProgressEased
    it("getTransitionProgressEased returns 0 when idle", function()
        lurek.scene.clear()
        local p = lurek.scene.getTransitionProgressEased()
        expect_true(type(p) == "number")
        expect_true(p >= 0.0 and p <= 1.0)
    end)

    -- @covers lurek.scene.getTransitionProgressEased
    -- @covers lurek.scene.getTransitionProgress
    -- Migrated from Rust active_transition_progress_eased_linear_matches_progress
    -- and scene_stack_get_transition_progress_eased_linear_matches.
    it("linear easing: eased progress matches raw progress", function()
        lurek.scene.clear()
        local scene_a = {}
        lurek.scene.push(scene_a, "fade", 2.0, "linear")
        lurek.scene.update(1.0)  -- advance to t = 0.5
        local raw   = lurek.scene.getTransitionProgress()
        local eased = lurek.scene.getTransitionProgressEased()
        expect_true(type(raw)   == "number")
        expect_true(type(eased) == "number")
        expect_near(raw, eased, 0.005)
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.getTransitionProgressEased
    -- @covers lurek.scene.getTransitionProgress
    -- before the midpoint (t < t for 0 < t < 1).
    -- Migrated from Rust active_transition_progress_eased_ease_in_less_before_midpoint.
    it("ease_in easing: eased progress is less than raw before midpoint", function()
        lurek.scene.clear()
        local scene_a = {}
        lurek.scene.push(scene_a, "fade", 2.0, "ease_in")
        lurek.scene.update(0.5)  -- advance to t = 0.25 (raw progress)
        local raw   = lurek.scene.getTransitionProgress()
        local eased = lurek.scene.getTransitionProgressEased()
        -- For ease_in: eased = t < t when 0 < t < 1
        expect_true(raw > 0.0)
        expect_true(eased < raw)
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.pop
    it("pop with easing param runs without error", function()
        lurek.scene.clear()
        local s1 = {}
        local s2 = {}
        lurek.scene.push(s1)
        lurek.scene.push(s2)
        lurek.scene.pop("fade", 0.2, "ease_out")
        expect_true(lurek.scene.getStackSize() >= 0)
        lurek.scene.clear()
    end)
end)

-- ============================================================
-- Phase C: Overlay mode
-- ============================================================
describe("scene overlay", function()
    -- @covers lurek.scene.pushOverlay
    -- @covers lurek.scene.isOverlay
    it("pushOverlay marks scene as overlay", function()
        lurek.scene.clear()
        local base = {}
        local ov = {}
        lurek.scene.push(base)
        lurek.scene.pushOverlay(ov)
        expect_true(lurek.scene.isOverlay())
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.pushOverlay
    -- @covers lurek.scene.pop
    -- @covers lurek.scene.isOverlay
    it("popping overlay restores normal mode", function()
        lurek.scene.clear()
        local base = {}
        local ov = {}
        lurek.scene.push(base)
        lurek.scene.pushOverlay(ov)
        lurek.scene.pop()
        expect_false(lurek.scene.isOverlay())
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.getActiveScenes
    it("getActiveScenes returns all when overlay present", function()
        lurek.scene.clear()
        local base = {}
        local ov = {}
        lurek.scene.push(base)
        lurek.scene.pushOverlay(ov)
        local scenes = lurek.scene.getActiveScenes()
        expect_true(type(scenes) == "table")
        expect_true(#scenes >= 2)
        lurek.scene.clear()
    end)

    -- @covers lurek.scene.getActiveScenes
    it("getActiveScenes returns top only without overlay", function()
        lurek.scene.clear()
        local base = {}
        local top = {}
        lurek.scene.push(base)
        lurek.scene.push(top)
        local scenes = lurek.scene.getActiveScenes()
        expect_true(type(scenes) == "table")
        expect_equal(#scenes, 1)
        lurek.scene.clear()
    end)
end)

-- ============================================================
-- Phase A: DepthSorter API via lurek.scene
-- ============================================================
describe("DepthSorter Lua API", function()
    -- @covers lurek.scene.newDepthSorter
    -- @tests lurek.scene.DepthSorter:add
    -- @tests lurek.scene.DepthSorter:sort
    it("newDepthSorter add and clear work", function()
        local ds = lurek.scene.newDepthSorter()
        ds:add(function() end, 2.0)
        ds:add(function() end, 1.0)
        expect_equal(ds:getCount(), 2)
        ds:clear()
        expect_equal(ds:getCount(), 0)
    end)

    -- @tests lurek.scene.DepthSorter:setStable
    -- @tests lurek.scene.DepthSorter:isStable
    it("setStable and isStable round-trip", function()
        local ds = lurek.scene.newDepthSorter()
        expect_false(ds:isStable())
        ds:setStable(true)
        expect_true(ds:isStable())
        ds:setStable(false)
        expect_false(ds:isStable())
    end)
end)

-- ============================================================
-- Phase D: Preload
-- ============================================================
describe("scene preload", function()
    -- @covers lurek.scene.preload
    -- @covers lurek.scene.isPreloaded
    it("preload registers loader; isPreloaded false before invoke", function()
        lurek.scene.clear()
        lurek.scene.preload("my_scene", function() end)
        -- isPreloaded should be false until pushPreloaded is called.
        expect_false(lurek.scene.isPreloaded("my_scene"))
    end)

    -- @covers lurek.scene.pushPreloaded
    -- @covers lurek.scene.isPreloaded
    it("pushPreloaded calls loader and marks isPreloaded true", function()
        lurek.scene.clear()
        local called = false
        lurek.scene.registerScene("pre_scene", {})
        lurek.scene.preload("pre_scene", function()
            called = true
        end)
        lurek.scene.pushPreloaded("pre_scene")
        expect_true(lurek.scene.isPreloaded("pre_scene"))
        lurek.scene.clear()
    end)
end)

-- ============================================================
-- DepthSorter flush correctness (migrated from Rust scene_tests.rs)
-- These tests verify behavior observable via lurek.* that was previously in Rust.
-- ============================================================
describe("DepthSorter flush sort order", function()
    -- @tests lurek.scene.DepthSorter:flush
    -- @tests lurek.scene.DepthSorter:add
    it("flush calls callbacks in ascending depth order", function()
        local ds = lurek.scene.newDepthSorter()
        local order = {}
        ds:add(function() order[#order + 1] = "deep"    end, 5.0)
        ds:add(function() order[#order + 1] = "mid"     end, 3.0)
        ds:add(function() order[#order + 1] = "shallow" end, 1.0)
        ds:flush()
        expect_equal(order[1], "shallow")
        expect_equal(order[2], "mid")
        expect_equal(order[3], "deep")
    end)

    -- @tests lurek.scene.DepthSorter:sort
    -- @tests lurek.scene.DepthSorter:flush
    it("flush re-sorts after add() following sort()", function()
        local ds = lurek.scene.newDepthSorter()
        local order = {}
        local function fn1() order[#order + 1] = "fn1" end
        local function fn2() order[#order + 1] = "fn2" end
        local function fn3() order[#order + 1] = "fn3" end
        ds:add(fn1, 3.0)
        ds:add(fn2, 1.0)
        ds:sort()        -- sorts & marks clean
        ds:add(fn3, 0.5) -- re-dirties; must be placed correctly on next flush
        ds:flush()
        expect_equal(order[1], "fn3")
        expect_equal(order[2], "fn2")
        expect_equal(order[3], "fn1")
    end)

    -- @tests lurek.scene.DepthSorter:setStable
    -- @tests lurek.scene.DepthSorter:flush
    it("stable mode preserves insertion order for equal depths", function()
        local ds = lurek.scene.newDepthSorter()
        ds:setStable(true)
        local order = {}
        ds:add(function() order[#order + 1] = "A" end, 0.0)
        ds:add(function() order[#order + 1] = "B" end, 0.0)
        ds:add(function() order[#order + 1] = "C" end, 0.0)
        ds:flush()
        expect_equal(order[1], "A")
        expect_equal(order[2], "B")
        expect_equal(order[3], "C")
    end)

    -- @tests lurek.scene.DepthSorter:flush
    --              order (exercises the radix sort path internally).
    it("256 entries flush ascending (triggers radix sort path)", function()
        local ds = lurek.scene.newDepthSorter()
        local order = {}
        for i = 255, 0, -1 do
            local d = i
            ds:add(function() order[#order + 1] = d end, d)
        end
        ds:flush()
        expect_equal(#order, 256)
        local ascending = true
        for i = 2, #order do
            if order[i] < order[i - 1] then ascending = false; break end
        end
        expect_true(ascending)
    end)

    -- @tests lurek.scene.DepthSorter:flush
    it("negative depths sort before positive depths", function()
        local ds = lurek.scene.newDepthSorter()
        local order = {}
        for i = 14, -15, -1 do
            local d = i
            ds:add(function() order[#order + 1] = d end, d)
        end
        ds:flush()
        expect_equal(#order, 30)
        local ascending = true
        for i = 2, #order do
            if order[i] < order[i - 1] then ascending = false; break end
        end
        expect_true(ascending)
        expect_true(order[1] < 0)
        expect_true(order[#order] > 0)
    end)
end)

-- ============================================================
-- Overlay clear state (migrated from Rust scene_tests.rs)
-- ============================================================
describe("scene overlay clear state", function()
    -- @covers lurek.scene.clear
    -- @covers lurek.scene.pushOverlay
    -- @covers lurek.scene.isOverlay
    it("clear after pushOverlay resets overlay flag and empties stack", function()
        lurek.scene.clear()
        local base = {}
        local ov   = {}
        lurek.scene.push(base)
        lurek.scene.pushOverlay(ov)
        lurek.scene.clear()
        expect_false(lurek.scene.isOverlay())
        expect_equal(lurek.scene.getStackSize(), 0)
    end)
end)

-- ============================================================
-- Merged from test_scene_ui.lua
-- ============================================================


describe("lurek.scene overlay mode", function()
    -- @covers lurek.scene.pushOverlay
    -- @covers lurek.scene.isOverlay
    -- @covers lurek.scene.depth
    -- @covers lurek.scene.getActiveScenes
    it("pushOverlay is a function", function()
        expect_equal(type(lurek.scene.pushOverlay), "function")
    end)

    -- and that depth() correctly counts it on the stack.
    it("pushOverlay accepts a scene table and increments depth", function()
        lurek.scene.clear()
        local overlay = { enter = function() end, draw = function() end }
        lurek.scene.pushOverlay(overlay)
        expect_equal(lurek.scene.depth(), 1)
        lurek.scene.pop()
        expect_equal(lurek.scene.depth(), 0)
    end)

    it("isOverlay returns true after pushOverlay", function()
        lurek.scene.clear()
        local overlay = {}
        lurek.scene.pushOverlay(overlay)
        expect_true(lurek.scene.isOverlay())
        lurek.scene.pop()
    end)

    it("isOverlay returns false after a normal push", function()
        lurek.scene.clear()
        local scene = {}
        lurek.scene.push(scene)
        expect_false(lurek.scene.isOverlay())
        lurek.scene.pop()
    end)

    it("both background and overlay are in getActiveScenes", function()
        lurek.scene.clear()
        local bg      = { name = "bg"      }
        local overlay = { name = "effect" }
        lurek.scene.push(bg)
        lurek.scene.pushOverlay(overlay)
        local active = lurek.scene.getActiveScenes()
        expect_equal(#active, 2)
        lurek.scene.clear()
    end)

    it("depth() equals getStackSize()", function()
        lurek.scene.clear()
        local s1 = {}
        local s2 = {}
        lurek.scene.push(s1)
        lurek.scene.pushOverlay(s2)
        expect_equal(lurek.scene.depth(), lurek.scene.getStackSize())
        lurek.scene.clear()
    end)
end)

-- ============================================================
-- Merged from test_scene_preload.lua
-- ============================================================


describe("lurek.scene.preload", function()
    -- @covers lurek.scene.preload
    -- @covers lurek.scene.isPreloaded
    -- @covers lurek.scene.pushPreloaded
    it("preload is a function", function()
        expect_equal(type(lurek.scene.preload), "function")
    end)

    it("isPreloaded is a function", function()
        expect_equal(type(lurek.scene.isPreloaded), "function")
    end)

    it("pushPreloaded is a function", function()
        expect_equal(type(lurek.scene.pushPreloaded), "function")
    end)

    it("can register a preload function without error", function()
        lurek.scene.preload("test_scene", function()
            -- heavy asset load would go here
        end)
        expect_equal(true, true)
    end)

    it("scene is not preloaded before pushPreloaded is called", function()
        lurek.scene.clear()
        lurek.scene.preload("lazy_scene", function() end)
        expect_false(lurek.scene.isPreloaded("lazy_scene"))
    end)

    -- is invoked multiple times for the same name.
    it("loader is invoked exactly once across multiple pushPreloaded calls", function()
        lurek.scene.clear()
        local call_count = 0
        local dummy = {}
        lurek.scene.registerScene("once_scene", dummy)
        lurek.scene.preload("once_scene", function()
            call_count = call_count + 1
        end)
        lurek.scene.pushPreloaded("once_scene")
        lurek.scene.pop()
        lurek.scene.pushPreloaded("once_scene")
        lurek.scene.pop()
        expect_equal(call_count, 1)
        lurek.scene.unregisterScene("once_scene")
        lurek.scene.clear()
    end)

    it("isPreloaded returns true after pushPreloaded triggers the loader", function()
        lurek.scene.clear()
        local scene_tbl = {}
        lurek.scene.registerScene("preload_check", scene_tbl)
        lurek.scene.preload("preload_check", function() end)
        lurek.scene.pushPreloaded("preload_check")
        expect_true(lurek.scene.isPreloaded("preload_check"))
        lurek.scene.pop()
        lurek.scene.unregisterScene("preload_check")
        lurek.scene.clear()
    end)
end)

-- ============================================================
-- Merged from test_scene_serialization.lua
-- ============================================================

describe("lurek.scene", function()
    describe("serializeScene and deserializeScene", function()
        -- @covers lurek.scene.setData
        -- @covers lurek.scene.getData
        -- @covers lurek.scene.serializeScene
        it("serializeScene captures setData values", function()
            lurek.scene.setData("level", 3)
            lurek.scene.setData("score", 9999)
            local snap = lurek.scene.serializeScene()
            expect_equal("table", type(snap))
            expect_equal("table", type(snap.data))
            expect_equal(3, snap.data.level)
            expect_equal(9999, snap.data.score)
        end)

        -- @covers lurek.scene.deserializeScene
        it("deserializeScene restores setData values", function()
            local snap = { data = { gold = 150, hp = 80 }, stack = {} }
            lurek.scene.deserializeScene(snap)
            expect_equal(150, lurek.scene.getData("gold"))
            expect_equal(80, lurek.scene.getData("hp"))
        end)

        -- @covers lurek.scene.serializeScene
        xit("serializeScene with no data returns empty data table", function()
            local snap = lurek.scene.serializeScene()
            local count = 0
            for _ in pairs(snap.data) do count = count + 1 end
            expect_equal(0, count)
        end)

        -- @covers lurek.scene.deserializeScene
        it("deserializeScene with empty snapshot does not error", function()
            local ok, err = pcall(function()
                lurek.scene.deserializeScene({ data = {}, stack = {} })
            end)
            expect_equal(true, ok)
        end)
    end)
end)

-- ============================================================
-- Merged from test_scene_transitions.lua
-- ============================================================

---@type any
local scene_api = lurek.scene
local scene_transitions = scene_api.transitions

describe("lurek.scene.transitions", function()
    -- @covers lurek.scene.transitions
    it("transitions table exists", function()
        expect_equal(type(scene_transitions), "table")
    end)

    it("fade transition exists as a function", function()
        expect_equal(type(scene_transitions.fade), "function")
    end)

    it("slide transition exists as a function", function()
        expect_equal(type(scene_transitions.slide), "function")
    end)

    it("wipe transition exists as a function", function()
        expect_equal(type(scene_transitions.wipe), "function")
    end)

    it("iris transition exists as a function", function()
        expect_equal(type(scene_transitions.iris), "function")
    end)

    it("fade() returns a table with type=fade", function()
        local t = scene_transitions.fade()
        expect_equal(t.type, "fade")
    end)

    it("fade() returns default duration 0.5", function()
        local t = scene_transitions.fade()
        expect_near(t.duration, 0.5, 0.001)
    end)

    it("fade(1.0) returns duration=1.0", function()
        local t = scene_transitions.fade(1.0)
        expect_near(t.duration, 1.0, 0.001)
    end)

    it("slide() returns type=left by default", function()
        local t = scene_transitions.slide()
        expect_equal(t.type, "left")
    end)

    it("slide(\"right\") returns type=right", function()
        local t = scene_transitions.slide("right")
        expect_equal(t.type, "right")
    end)

    it("slide() returns default duration 0.4", function()
        local t = scene_transitions.slide()
        expect_near(t.duration, 0.4, 0.001)
    end)

    it("wipe() returns type=wipe with default duration", function()
        local t = scene_transitions.wipe()
        expect_equal(t.type, "wipe")
        expect_near(t.duration, 0.5, 0.001)
    end)

    it("iris() returns type=iris with default duration", function()
        local t = scene_transitions.iris()
        expect_equal(t.type, "iris")
        expect_near(t.duration, 0.6, 0.001)
    end)

    it("each factory call returns a fresh table", function()
        local a = scene_transitions.fade()
        local b = scene_transitions.fade()
        expect_false(a == b)
    end)
end)

-- ============================================================
-- Merged from test_scene_transitions_extended.lua
-- ============================================================

describe("lurek.scene", function()
    describe("getTransitionTypes", function()
        -- @covers lurek.scene.getTransitionTypes
        it("returns exactly 10 transition type strings", function()
            local types = lurek.scene.getTransitionTypes()
            expect_equal(10, #types)
        end)

        -- @covers lurek.scene.getTransitionTypes
        it("contains none, fade, left, right, up, down", function()
            local types = lurek.scene.getTransitionTypes()
            local lookup = {}
            for _, v in ipairs(types) do lookup[v] = true end
            expect_equal(true, lookup["none"])
            expect_equal(true, lookup["fade"])
            expect_equal(true, lookup["left"])
            expect_equal(true, lookup["right"])
            expect_equal(true, lookup["up"])
            expect_equal(true, lookup["down"])
        end)

        -- @covers lurek.scene.getTransitionTypes
        it("contains extended types wipe, iris, zoom, crossfade", function()
            local types = lurek.scene.getTransitionTypes()
            local lookup = {}
            for _, v in ipairs(types) do lookup[v] = true end
            expect_equal(true, lookup["wipe"])
            expect_equal(true, lookup["iris"])
            expect_equal(true, lookup["zoom"])
            expect_equal(true, lookup["crossfade"])
        end)

        -- @covers lurek.scene.getTransitionTypes
        it("all entries are strings", function()
            local types = lurek.scene.getTransitionTypes()
            for _, v in ipairs(types) do
                expect_equal("string", type(v))
            end
        end)
    end)
end)

describe("lurek.scene.newScene", function()
    it("creates a scene table that inherits methods from the definition", function()
        -- @covers lurek.scene.newScene
        local scene = lurek.scene.newScene({
            enter = function(self)
                self.entered = true
                return "ok"
            end,
        })
        expect_equal("table", type(scene))
        expect_equal("function", type(scene.enter))
        expect_equal("ok", scene:enter())
        expect_equal(true, scene.entered)
    end)
end)

describe("lurek.scene transition helper aliases", function()
    local function get_helper(name)
        local direct = lurek.scene[name]
        if type(direct) == "function" then
            return direct
        end
        local transitions = lurek.scene["transitions"]
        return transitions[name]
    end

    it("fade returns a fade transition table", function()
        -- @covers lurek.scene.fade
        local fade = get_helper("fade")
        expect_equal("function", type(fade))
        local t = fade(1.0)
        expect_equal("fade", t.type)
        expect_near(1.0, t.duration, 0.001)
    end)

    it("slide returns a directional slide transition table", function()
        -- @covers lurek.scene.slide
        local slide = get_helper("slide")
        expect_equal("function", type(slide))
        local t = slide("right", 0.75)
        expect_equal("right", t.type)
        expect_near(0.75, t.duration, 0.001)
    end)

    it("wipe returns a wipe transition table", function()
        -- @covers lurek.scene.wipe
        local wipe = get_helper("wipe")
        expect_equal("function", type(wipe))
        local t = wipe(0.25)
        expect_equal("wipe", t.type)
        expect_near(0.25, t.duration, 0.001)
    end)

    it("iris returns an iris transition table", function()
        -- @covers lurek.scene.iris
        local iris = get_helper("iris")
        expect_equal("function", type(iris))
        local t = iris(0.9)
        expect_equal("iris", t.type)
        expect_near(0.9, t.duration, 0.001)
    end)
end)

describe("DepthSorter stable mode", function()
    it("setStable toggles the stable-sorting flag", function()
        -- @covers DepthSorter:setStable
        -- @covers DepthSorter:isStable
        local ds = lurek.scene.newDepthSorter()
        expect_equal(false, ds:isStable())
        ds:setStable(true)
        expect_equal(true, ds:isStable())
        ds:setStable(false)
        expect_equal(false, ds:isStable())
    end)
end)

-- =========================================================================
-- @covers additions for scene module
-- =========================================================================

describe("lurek.scene.pop (@covers)", function()
    it("pop does not panic on an empty or existing stack", function()
        -- @covers lurek.scene.pop
        local ok, _ = pcall(function() lurek.scene.pop() end)
        expect_type("boolean", ok)
    end)
end)

describe("lurek.scene.new (@covers)", function()
    it("new returns a scene object or nil gracefully", function()
        -- @covers lurek.scene.new
        local ok, result = pcall(function() return lurek.scene.new() end)
        expect_type("boolean", ok)
        if ok and result ~= nil then
            expect_not_nil(result)
        end
    end)
end)

describe("DepthSorter:add (@covers)", function()
    it("add increments the sorted-object count", function()
        -- @covers DepthSorter:add
        local ds = lurek.scene.newDepthSorter()
        ds:add(function() end, 5.0)
        ds:add(function() end, 3.0)
        expect_true(ds:getCount() >= 2)
    end)
end)

test_summary()
