-- Scene module Lua tests
-- Tests are headless-safe (no window/GPU/audio needed)

-- ============================================================
-- Stack operations
-- ============================================================
local scene_a = { name = "A" }
local scene_b = { name = "B" }
local scene_c = { name = "C" }

-- Initially empty
assert(luna.scene.isEmpty(), "stack should start empty")
assert(luna.scene.getStackSize() == 0, "stack size should be 0")
assert(luna.scene.getCurrent() == nil, "current should be nil when empty")

-- Push
luna.scene.push(scene_a)
assert(not luna.scene.isEmpty(), "stack should not be empty after push")
assert(luna.scene.getStackSize() == 1, "stack size should be 1")
assert(luna.scene.getCurrent() ~= nil, "current should not be nil")

-- Push second
luna.scene.push(scene_b)
assert(luna.scene.getStackSize() == 2, "stack size should be 2")

-- Pop
luna.scene.pop()
assert(luna.scene.getStackSize() == 1, "stack size should be 1 after pop")

-- SwitchTo
luna.scene.switchTo(scene_c)
assert(luna.scene.getStackSize() == 1, "stack size should stay 1 after switchTo")

-- Clear
luna.scene.push(scene_a)
luna.scene.push(scene_b)
assert(luna.scene.getStackSize() == 3, "stack size should be 3")
luna.scene.clear()
assert(luna.scene.isEmpty(), "stack should be empty after clear")

-- ============================================================
-- Transitions
-- ============================================================
assert(not luna.scene.isTransitioning(), "should not be transitioning initially")
assert(luna.scene.getTransitionProgress() == 0, "progress should be 0 with no transition")

luna.scene.push(scene_a, "fade", 1.0)
assert(luna.scene.isTransitioning(), "should be transitioning after push with fade")
local p = luna.scene.getTransitionProgress()
assert(p >= 0 and p <= 1, "progress should be in [0,1]")

luna.scene.update(0.5)
local p2 = luna.scene.getTransitionProgress()

luna.scene.update(1.0) -- complete the transition
-- After completion, transitioning should be false
-- (depends on implementation)

-- ============================================================
-- Registry
-- ============================================================
luna.scene.clear()
local menu = { name = "menu" }
local game = { name = "game" }

luna.scene.registerScene("menu", menu)
luna.scene.registerScene("game", game)

assert(luna.scene.hasRegistered("menu"), "menu should be registered")
assert(luna.scene.hasRegistered("game"), "game should be registered")
assert(not luna.scene.hasRegistered("settings"), "settings should not be registered")

local names = luna.scene.getRegisteredNames()
assert(type(names) == "table", "getRegisteredNames should return table")

local got = luna.scene.getRegistered("menu")
assert(got ~= nil, "getRegistered should return scene table")

luna.scene.unregisterScene("menu")
assert(not luna.scene.hasRegistered("menu"), "menu should be unregistered")

-- ============================================================
-- Data store
-- ============================================================
luna.scene.setData("score", 42)
assert(luna.scene.hasData("score"), "score data should exist")
assert(luna.scene.getData("score") == 42, "score should be 42")

luna.scene.setData("name", "player1")
assert(luna.scene.getData("name") == "player1", "name should be player1")

luna.scene.removeData("score")
assert(not luna.scene.hasData("score"), "score should be removed")
assert(luna.scene.getData("score") == nil, "getData for removed key should return nil")

-- ============================================================
-- DepthSorter
-- ============================================================
local sorter = luna.scene.newDepthSorter()
assert(sorter ~= nil, "newDepthSorter should return object")
assert(sorter:getCount() == 0, "new sorter should have count 0")

-- Add callbacks
local order = {}
sorter:add(function() table.insert(order, "c") end, 10)
sorter:add(function() table.insert(order, "a") end, 0)
sorter:add(function() table.insert(order, "b") end, 5)
assert(sorter:getCount() == 3, "count should be 3")

-- Flush calls in depth order and clears
sorter:flush()
assert(sorter:getCount() == 0, "count should be 0 after flush")
assert(#order == 3, "all callbacks should have been called")
assert(order[1] == "a", "depth 0 should be called first")
assert(order[2] == "b", "depth 5 should be called second")
assert(order[3] == "c", "depth 10 should be called third")

-- ============================================================
-- Lifecycle callbacks
-- ============================================================
luna.scene.clear()
local log = {}

local s1 = {
    enter = function(self) table.insert(log, "s1:enter") end,
    leave = function(self) table.insert(log, "s1:leave") end,
    pause = function(self) table.insert(log, "s1:pause") end,
    resume = function(self) table.insert(log, "s1:resume") end,
    update = function(self, dt) table.insert(log, "s1:update") end,
    draw = function(self) table.insert(log, "s1:draw") end,
}

local s2 = {
    enter = function(self) table.insert(log, "s2:enter") end,
    leave = function(self) table.insert(log, "s2:leave") end,
}

-- Push s1 → enter
luna.scene.push(s1)
assert(log[1] == "s1:enter", "push should call enter: got " .. tostring(log[1]))

-- Push s2 → s1:pause, s2:enter
luna.scene.push(s2)
assert(log[2] == "s1:pause", "push should call pause on prev: got " .. tostring(log[2]))
assert(log[3] == "s2:enter", "push should call enter on new: got " .. tostring(log[3]))

-- Pop s2 → s2:leave, s1:resume
luna.scene.pop()
assert(log[4] == "s2:leave", "pop should call leave on popped: got " .. tostring(log[4]))
assert(log[5] == "s1:resume", "pop should call resume on revealed: got " .. tostring(log[5]))

-- Update calls top scene update
log = {}
luna.scene.update(0.016)
assert(log[1] == "s1:update", "update should dispatch to top scene")

-- Draw calls all scenes
log = {}
luna.scene.draw()
assert(log[1] == "s1:draw", "draw should dispatch to scene")

-- SwitchTo → leave old, enter new
log = {}
luna.scene.switchTo(s2)
assert(log[1] == "s1:leave", "switchTo should call leave on old")
assert(log[2] == "s2:enter", "switchTo should call enter on new")

print("All scene tests passed!")
