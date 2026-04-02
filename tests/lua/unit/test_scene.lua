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
end)

test_summary()
