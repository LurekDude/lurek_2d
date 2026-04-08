-- Scene module Lua tests
-- Headless-safe (no window/GPU/audio needed).
-- luna.scene is a module-level singleton; each describe calls luna.scene.clear() first.

describe("Stack operations", function()
    it("starts empty and tracks push/pop/switchTo/clear correctly", function()
        luna.scene.clear()
        local scene_a = { name = "A" }
        local scene_b = { name = "B" }
        local scene_c = { name = "C" }

        expect_true(luna.scene.isEmpty())
        expect_equal(0, luna.scene.getStackSize())
        expect_equal(nil, luna.scene.getCurrent())

        luna.scene.push(scene_a)
        expect_false(luna.scene.isEmpty())
        expect_equal(1, luna.scene.getStackSize())
        expect_true(luna.scene.getCurrent() ~= nil)

        luna.scene.push(scene_b)
        expect_equal(2, luna.scene.getStackSize())

        luna.scene.pop()
        expect_equal(1, luna.scene.getStackSize())

        luna.scene.switchTo(scene_c)
        expect_equal(1, luna.scene.getStackSize())

        luna.scene.push(scene_a)
        luna.scene.push(scene_b)
        expect_equal(3, luna.scene.getStackSize())
        luna.scene.clear()
        expect_true(luna.scene.isEmpty())
    end)
end)

describe("Transitions", function()
    it("reports transitioning state and progress in [0,1]", function()
        luna.scene.clear()
        expect_false(luna.scene.isTransitioning())
        expect_equal(0, luna.scene.getTransitionProgress())

        local scene_a = { name = "A" }
        luna.scene.push(scene_a, "fade", 1.0)
        expect_true(luna.scene.isTransitioning())

        local p = luna.scene.getTransitionProgress()
        expect_true(p >= 0 and p <= 1)

        luna.scene.update(1.0)  -- complete the transition
    end)
end)

describe("Registry", function()
    it("registers, queries, and unregisters scenes by name", function()
        luna.scene.clear()
        local menu = { name = "menu" }
        local game = { name = "game" }

        luna.scene.registerScene("menu", menu)
        luna.scene.registerScene("game", game)

        expect_true(luna.scene.hasRegistered("menu"))
        expect_true(luna.scene.hasRegistered("game"))
        expect_false(luna.scene.hasRegistered("settings"))

        local names = luna.scene.getRegisteredNames()
        expect_type("table", names)

        local got = luna.scene.getRegistered("menu")
        expect_true(got ~= nil)

        luna.scene.unregisterScene("menu")
        expect_false(luna.scene.hasRegistered("menu"))
    end)
end)

describe("Data store", function()
    it("stores, reads, and removes arbitrary key-value pairs", function()
        luna.scene.setData("score", 42)
        expect_true(luna.scene.hasData("score"))
        expect_equal(42, luna.scene.getData("score"))

        luna.scene.setData("name", "player1")
        expect_equal("player1", luna.scene.getData("name"))

        luna.scene.removeData("score")
        expect_false(luna.scene.hasData("score"))
        expect_equal(nil, luna.scene.getData("score"))
    end)
end)

describe("DepthSorter", function()
    it("flushes callbacks in ascending depth order", function()
        local sorter = luna.scene.newDepthSorter()
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
    it("calls enter/leave/pause/resume on push/pop/switchTo", function()
        luna.scene.clear()
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
        luna.scene.push(s1)
        expect_equal("s1:enter", log[1])

        -- push s2 -> s1:pause, s2:enter
        luna.scene.push(s2)
        expect_equal("s1:pause", log[2])
        expect_equal("s2:enter", log[3])

        -- pop s2 -> s2:leave, s1:resume
        luna.scene.pop()
        expect_equal("s2:leave", log[4])
        expect_equal("s1:resume", log[5])
    end)

    it("update dispatches to the top scene", function()
        luna.scene.clear()
        local log = {}
        local s1 = { update = function(self, dt) table.insert(log, "s1:update") end }
        luna.scene.push(s1)

        luna.scene.update(0.016)
        expect_equal("s1:update", log[1])
    end)

    it("draw dispatches to all scenes", function()
        luna.scene.clear()
        local log = {}
        local s1 = { draw = function(self) table.insert(log, "s1:draw") end }
        luna.scene.push(s1)

        luna.scene.draw()
        expect_equal("s1:draw", log[1])
    end)

    it("switchTo calls leave on old and enter on new", function()
        luna.scene.clear()
        local log = {}
        local s1 = { leave = function(self) table.insert(log, "s1:leave") end }
        local s2 = { enter = function(self) table.insert(log, "s2:enter") end }

        luna.scene.push(s1)
        log = {}  -- reset after push's enter (s1 has no enter)
        luna.scene.switchTo(s2)
        expect_equal("s1:leave", log[1])
        expect_equal("s2:enter", log[2])
    end)

    it("push forwards params to enter callback", function()
        luna.scene.clear()
        local received = nil
        local s = { enter = function(self, p) received = p end }

        luna.scene.push(s, nil, nil, { level = 3, mode = "hard" })
        expect_type("table", received)
        expect_equal(3, received.level)
        expect_equal("hard", received.mode)
    end)

    it("push with no params calls enter with nil", function()
        luna.scene.clear()
        local called = false
        local received = "sentinel"
        local s = { enter = function(self, p) called = true; received = p end }

        luna.scene.push(s)
        expect_true(called)
        expect_equal(nil, received)
    end)

    it("switchTo forwards params to enter callback", function()
        luna.scene.clear()
        local received = nil
        local s1 = {}
        local s2 = { enter = function(self, p) received = p end }

        luna.scene.push(s1)
        luna.scene.switchTo(s2, nil, nil, { map = "village" })
        expect_type("table", received)
        expect_equal("village", received.map)
    end)
end)

describe("luna.scene new pipeline callbacks", function()
    it("processPhysics is a function", function()
        expect_type("function", luna.scene.processPhysics)
    end)

    it("processLate is a function", function()
        expect_type("function", luna.scene.processLate)
    end)

    it("process is a function", function()
        expect_type("function", luna.scene.process)
    end)

    it("render is a function", function()
        expect_type("function", luna.scene.render)
    end)

    it("renderUi is a function", function()
        expect_type("function", luna.scene.renderUi)
    end)

    it("processPhysics calls scene:process_physics(dt)", function()
        local called_dt = nil
        local scene = {
            process_physics = function(self, dt) called_dt = dt end
        }
        luna.scene.push(scene)
        luna.scene.processPhysics(1.0 / 60.0)
        expect_near(1.0 / 60.0, called_dt, 1e-9)
        luna.scene.pop()
    end)

    it("processLate calls scene:process_late(dt)", function()
        local called_dt = nil
        local scene = {
            process_late = function(self, dt) called_dt = dt end
        }
        luna.scene.push(scene)
        luna.scene.processLate(0.016)
        expect_near(0.016, called_dt, 1e-3)
        luna.scene.pop()
    end)

    it("process calls scene:process(dt)", function()
        local called_dt = nil
        local scene = {
            process = function(self, dt) called_dt = dt end
        }
        luna.scene.push(scene)
        luna.scene.process(0.016)
        expect_near(0.016, called_dt, 1e-3)
        luna.scene.pop()
    end)

    it("render calls scene:render() for all scenes", function()
        local calls = {}
        local s1 = { render = function(self) table.insert(calls, "s1") end }
        local s2 = { render = function(self) table.insert(calls, "s2") end }
        luna.scene.push(s1)
        luna.scene.push(s2)
        luna.scene.render()
        expect_equal(2, #calls)
        expect_equal("s1", calls[1])
        expect_equal("s2", calls[2])
        luna.scene.pop()
        luna.scene.pop()
    end)

    it("renderUi calls scene:render_ui() for all scenes", function()
        local calls = {}
        local s1 = { render_ui = function(self) table.insert(calls, "s1") end }
        local s2 = { render_ui = function(self) table.insert(calls, "s2") end }
        luna.scene.push(s1)
        luna.scene.push(s2)
        luna.scene.renderUi()
        expect_equal(2, #calls)
        expect_equal("s1", calls[1])
        expect_equal("s2", calls[2])
        luna.scene.pop()
        luna.scene.pop()
    end)

    it("process fires scene:ready() once on first tick, then never again", function()
        local ready_count = 0
        local scene = {
            ready = function(self) ready_count = ready_count + 1 end
        }
        luna.scene.push(scene)
        luna.scene.process(0.016) -- first tick: fires ready, then process
        luna.scene.process(0.016) -- second tick: ready must NOT fire again
        luna.scene.process(0.016)
        expect_equal(1, ready_count)
        luna.scene.pop()
    end)

    it("process calls scene:ready() before scene:process() on first tick", function()
        local order = {}
        local scene = {
            ready   = function(self) table.insert(order, "ready") end,
            process = function(self, dt) table.insert(order, "process") end,
        }
        luna.scene.push(scene)
        luna.scene.process(0.016)
        expect_equal(2, #order)
        expect_equal("ready", order[1])
        expect_equal("process", order[2])
        luna.scene.pop()
    end)

    it("ready fires for the new scene after switchTo", function()
        luna.scene.clear()
        local a_ready = 0
        local b_ready = 0
        local a = { ready = function(self) a_ready = a_ready + 1 end }
        local b = { ready = function(self) b_ready = b_ready + 1 end }
        luna.scene.push(a)
        luna.scene.process(0.016) -- fires a:ready
        luna.scene.switchTo(b)
        luna.scene.process(0.016) -- fires b:ready, must NOT re-fire a:ready
        expect_equal(1, a_ready)
        expect_equal(1, b_ready)
        luna.scene.clear()
    end)

    it("ready fires again after pop and re-push of same scene", function()
        luna.scene.clear()
        local count = 0
        local scene = { ready = function(self) count = count + 1 end }
        luna.scene.push(scene)
        luna.scene.process(0.016)   -- first push → ready fires (count = 1)
        luna.scene.pop()
        luna.scene.push(scene)
        luna.scene.process(0.016)   -- second push → ready must fire again (count = 2)
        expect_equal(2, count)
        luna.scene.clear()
    end)

    it("scene without process method does not crash", function()
        luna.scene.clear()
        local scene = {}  -- no process method
        luna.scene.push(scene)
        luna.scene.process(0.016)
        luna.scene.pop()
    end)

    it("scene without ready method does not crash", function()
        luna.scene.clear()
        local scene = {}  -- no ready method
        luna.scene.push(scene)
        luna.scene.process(0)
        luna.scene.pop()
    end)

    it("scene without render or render_ui methods does not crash", function()
        luna.scene.clear()
        local scene = {}  -- no render / render_ui methods
        luna.scene.push(scene)
        luna.scene.render()
        luna.scene.renderUi()
        luna.scene.pop()
    end)

    it("renderUi with empty stack is safe", function()
        luna.scene.clear()
        luna.scene.renderUi()
    end)

    it("render with empty stack is safe", function()
        luna.scene.clear()
        luna.scene.render()
    end)

    it("processPhysics with empty stack is safe", function()
        luna.scene.clear()
        luna.scene.processPhysics(0.016)
    end)
end)

test_summary()
