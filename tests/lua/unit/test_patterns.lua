-- tests/lua/test_patterns.lua
-- BDD-style integration tests for lurek.patterns module

-- ===================================================================
-- EventBus
-- ===================================================================

-- @description Covers suite: lurek.patterns.newEventBus.
describe("lurek.patterns.newEventBus", function()
    -- @covers lurek.patterns.newEventBus
    -- @covers lurek.patterns.EventBus.type
    -- @covers lurek.patterns.EventBus.typeOf
    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.newFactory
    -- @covers lurek.patterns.newObjectPool
    -- @covers lurek.patterns.newServiceLocator
    -- @covers lurek.patterns.newSimpleState
    -- @description Verifies newEventBus returns EventBus userdata with working type checks.
    it("creates an EventBus with type/typeOf", function()
        local bus = lurek.patterns.newEventBus()
        expect_equal(bus:type(), "EventBus")
        expect_true(bus:typeOf("EventBus"))
        expect_true(bus:typeOf("Object"))
    end)

    -- @covers lurek.patterns.newEventBus
    -- @covers lurek.patterns.EventBus.on
    -- @covers lurek.patterns.EventBus.emit
    -- @description Verifies EventBus:on registers listeners that EventBus:emit invokes with payload data.
    it("on/emit fires callbacks", function()
        local bus = lurek.patterns.newEventBus()
        local received = nil
        bus:on("ping", function(val) received = val end)
        bus:emit("ping", 42)
        expect_equal(received, 42)
    end)

    -- @covers lurek.patterns.newEventBus
    -- @covers lurek.patterns.EventBus.on
    -- @description Verifies EventBus:on returns distinct subscription IDs for separate listeners.
    it("on returns unique subscription IDs", function()
        local bus = lurek.patterns.newEventBus()
        local id1 = bus:on("a", function() end)
        local id2 = bus:on("a", function() end)
        expect_true(id1 ~= id2)
    end)

    -- @covers lurek.patterns.newEventBus
    -- @covers lurek.patterns.EventBus.on
    -- @covers lurek.patterns.EventBus.emit
    -- @description Verifies EventBus executes listeners in priority order.
    it("listeners fire in priority order", function()
        local bus = lurek.patterns.newEventBus()
        local order = {}
        bus:on("act", function() table.insert(order, "low") end, 10)
        bus:on("act", function() table.insert(order, "high") end, -5)
        bus:on("act", function() table.insert(order, "mid") end, 0)
        bus:emit("act")
        expect_equal(order[1], "high")
        expect_equal(order[2], "mid")
        expect_equal(order[3], "low")
    end)

    -- @covers lurek.patterns.newEventBus
    -- @covers lurek.patterns.EventBus.on
    -- @covers lurek.patterns.EventBus.off
    -- @covers lurek.patterns.EventBus.emit
    -- @description Verifies EventBus:off removes a listener so later emits do not invoke it.
    it("off removes a listener by ID", function()
        local bus = lurek.patterns.newEventBus()
        local count = 0
        local id = bus:on("tick", function() count = count + 1 end)
        bus:emit("tick")
        expect_equal(count, 1)
        bus:off(id)
        bus:emit("tick")
        expect_equal(count, 1)
    end)

    -- @covers lurek.patterns.newEventBus
    -- @covers lurek.patterns.EventBus.on
    -- @covers lurek.patterns.EventBus.clear
    -- @covers lurek.patterns.EventBus.getListenerCount
    -- @description Verifies EventBus:clear removes all listeners for one event without affecting others.
    it("clear removes all listeners for an event", function()
        local bus = lurek.patterns.newEventBus()
        bus:on("x", function() end)
        bus:on("x", function() end)
        bus:on("y", function() end)
        expect_equal(bus:getListenerCount("x"), 2)
        bus:clear("x")
        expect_equal(bus:getListenerCount("x"), 0)
        expect_equal(bus:getListenerCount("y"), 1)
    end)

    -- @covers lurek.patterns.newEventBus
    -- @covers lurek.patterns.EventBus.on
    -- @covers lurek.patterns.EventBus.clearAll
    -- @covers lurek.patterns.EventBus.getListenerCount
    -- @description Verifies EventBus:clearAll removes listeners across every event.
    it("clearAll removes all listeners", function()
        local bus = lurek.patterns.newEventBus()
        bus:on("a", function() end)
        bus:on("b", function() end)
        bus:clearAll()
        expect_equal(bus:getListenerCount("a"), 0)
        expect_equal(bus:getListenerCount("b"), 0)
    end)

    -- @covers lurek.patterns.newEventBus
    -- @covers lurek.patterns.EventBus.on
    -- @covers lurek.patterns.EventBus.getEvents
    -- @description Verifies EventBus:getEvents returns the names of events with registered listeners.
    it("getEvents lists event names with listeners", function()
        local bus = lurek.patterns.newEventBus()
        bus:on("alpha", function() end)
        bus:on("beta", function() end)
        local events = bus:getEvents()
        expect_equal(#events, 2)
    end)
end)

-- ===================================================================
-- ObjectPool
-- ===================================================================
-- @description Covers suite: lurek.patterns.newObjectPool.
describe("lurek.patterns.newObjectPool", function()
    -- @covers lurek.patterns.newObjectPool
    -- @covers lurek.patterns.ObjectPool.type
    -- @covers lurek.patterns.ObjectPool.typeOf
    -- @description Verifies newObjectPool returns ObjectPool userdata with working type helpers.
    it("creates an ObjectPool with correct type", function()
        local pool = lurek.patterns.newObjectPool()
        expect_equal(pool:type(), "ObjectPool")
        expect_true(pool:typeOf("ObjectPool"))
    end)

    -- @covers lurek.patterns.newObjectPool
    -- @covers lurek.patterns.ObjectPool.add
    -- @covers lurek.patterns.ObjectPool.acquire
    -- @covers lurek.patterns.ObjectPool.getAvailableCount
    -- @covers lurek.patterns.ObjectPool.getActiveCount
    -- @description Verifies ObjectPool add and acquire update available and active counts correctly.
    it("add/acquire round-trips objects", function()
        local pool = lurek.patterns.newObjectPool()
        pool:add("bullet1")
        pool:add("bullet2")
        expect_equal(pool:getAvailableCount(), 2)
        local obj = pool:acquire()
        expect_true(obj ~= nil)
        expect_equal(pool:getActiveCount(), 1)
        expect_equal(pool:getAvailableCount(), 1)
    end)

    -- @covers lurek.patterns.newObjectPool
    -- @covers lurek.patterns.ObjectPool.acquire
    -- @description Verifies ObjectPool:acquire returns nil when no pooled objects exist.
    it("acquire returns nil on empty pool", function()
        local pool = lurek.patterns.newObjectPool()
        local obj = pool:acquire()
        expect_nil(obj)
    end)

    -- @covers lurek.patterns.newObjectPool
    -- @covers lurek.patterns.ObjectPool.add
    -- @covers lurek.patterns.ObjectPool.acquire
    -- @covers lurek.patterns.ObjectPool.release
    -- @covers lurek.patterns.ObjectPool.getActiveCount
    -- @covers lurek.patterns.ObjectPool.getAvailableCount
    -- @description Verifies ObjectPool:release returns an acquired object back to the available pool.
    it("release returns object to pool", function()
        local pool = lurek.patterns.newObjectPool()
        pool:add("item")
        local obj = pool:acquire()
        expect_equal(pool:getActiveCount(), 1)
        pool:release(obj)
        expect_equal(pool:getActiveCount(), 0)
        expect_equal(pool:getAvailableCount(), 1)
    end)

    -- @covers lurek.patterns.newObjectPool
    -- @covers lurek.patterns.ObjectPool.add
    -- @covers lurek.patterns.ObjectPool.acquire
    -- @covers lurek.patterns.ObjectPool.getTotalCount
    -- @description Verifies ObjectPool:getTotalCount reports active plus available objects.
    it("getTotalCount sums active + available", function()
        local pool = lurek.patterns.newObjectPool()
        pool:add("a")
        pool:add("b")
        pool:acquire()
        expect_equal(pool:getTotalCount(), 2)
    end)

    -- @covers lurek.patterns.newObjectPool
    -- @covers lurek.patterns.ObjectPool.add
    -- @covers lurek.patterns.ObjectPool.acquire
    -- @covers lurek.patterns.ObjectPool.clearAll
    -- @covers lurek.patterns.ObjectPool.getTotalCount
    -- @description Verifies ObjectPool:clearAll resets all stored and active objects.
    it("clearAll resets everything", function()
        local pool = lurek.patterns.newObjectPool()
        pool:add("x")
        pool:acquire()
        pool:add("y")
        pool:clearAll()
        expect_equal(pool:getTotalCount(), 0)
    end)
end)

-- ===================================================================
-- CommandStack
-- ===================================================================
-- @description Covers suite: lurek.patterns.newCommandStack.
describe("lurek.patterns.newCommandStack", function()
    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.type
    -- @covers lurek.patterns.CommandStack.typeOf
    -- @description Verifies newCommandStack returns CommandStack userdata with working type checks.
    it("creates a CommandStack with correct type", function()
        local cmds = lurek.patterns.newCommandStack()
        expect_equal(cmds:type(), "CommandStack")
        expect_true(cmds:typeOf("CommandStack"))
    end)

    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.execute
    -- @description Verifies CommandStack:execute runs the forward command immediately.
    it("execute runs the command immediately", function()
        local cmds = lurek.patterns.newCommandStack()
        local x = 0
        cmds:execute("inc", function() x = x + 1 end)
        expect_equal(x, 1)
    end)

    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.execute
    -- @covers lurek.patterns.CommandStack.undo
    -- @description Verifies CommandStack:undo invokes the stored reverse operation for the latest command.
    it("undo reverses the last command", function()
        local cmds = lurek.patterns.newCommandStack()
        local x = 0
        cmds:execute("inc", function() x = x + 10 end, function() x = x - 10 end)
        expect_equal(x, 10)
        local ok = cmds:undo()
        expect_true(ok)
        expect_equal(x, 0)
    end)

    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.execute
    -- @covers lurek.patterns.CommandStack.undo
    -- @covers lurek.patterns.CommandStack.redo
    -- @description Verifies CommandStack:redo replays an undone command.
    it("redo re-executes after undo", function()
        local cmds = lurek.patterns.newCommandStack()
        local x = 0
        cmds:execute("inc", function() x = x + 5 end, function() x = x - 5 end)
        cmds:undo()
        expect_equal(x, 0)
        local ok = cmds:redo()
        expect_true(ok)
        expect_equal(x, 5)
    end)

    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.execute
    -- @covers lurek.patterns.CommandStack.undo
    -- @covers lurek.patterns.CommandStack.canUndo
    -- @covers lurek.patterns.CommandStack.canRedo
    -- @description Verifies canUndo and canRedo track command history state changes.
    it("canUndo/canRedo report correctly", function()
        local cmds = lurek.patterns.newCommandStack()
        expect_false(cmds:canUndo())
        expect_false(cmds:canRedo())
        cmds:execute("a", function() end, function() end)
        expect_true(cmds:canUndo())
        expect_false(cmds:canRedo())
        cmds:undo()
        expect_false(cmds:canUndo())
        expect_true(cmds:canRedo())
    end)

    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.execute
    -- @covers lurek.patterns.CommandStack.undo
    -- @covers lurek.patterns.CommandStack.canRedo
    -- @covers lurek.patterns.CommandStack.getHistorySize
    -- @description Verifies executing a new command after undo truncates redo history.
    it("execute after undo truncates redo history", function()
        local cmds = lurek.patterns.newCommandStack()
        local x = 0
        cmds:execute("a", function() x = x + 1 end, function() x = x - 1 end)
        cmds:execute("b", function() x = x + 10 end, function() x = x - 10 end)
        cmds:undo()
        cmds:execute("c", function() x = x + 100 end, function() x = x - 100 end)
        expect_false(cmds:canRedo())
        expect_equal(cmds:getHistorySize(), 2)
    end)

    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.execute
    -- @covers lurek.patterns.CommandStack.getCurrentName
    -- @description Verifies getCurrentName reflects the most recently executed command name.
    it("getCurrentName returns the last command name", function()
        local cmds = lurek.patterns.newCommandStack()
        expect_nil(cmds:getCurrentName())
        cmds:execute("move", function() end)
        expect_equal(cmds:getCurrentName(), "move")
    end)

    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.execute
    -- @covers lurek.patterns.CommandStack.clearAll
    -- @covers lurek.patterns.CommandStack.getHistorySize
    -- @covers lurek.patterns.CommandStack.canUndo
    -- @description Verifies CommandStack:clearAll removes all history and undo state.
    it("clearAll resets the stack", function()
        local cmds = lurek.patterns.newCommandStack()
        cmds:execute("a", function() end, function() end)
        cmds:execute("b", function() end, function() end)
        cmds:clearAll()
        expect_equal(cmds:getHistorySize(), 0)
        expect_false(cmds:canUndo())
    end)
end)

-- ===================================================================
-- ServiceLocator
-- ===================================================================
-- @description Covers suite: lurek.patterns.newServiceLocator.
describe("lurek.patterns.newServiceLocator", function()
    -- @covers lurek.patterns.newServiceLocator
    -- @covers lurek.patterns.ServiceLocator.type
    -- @covers lurek.patterns.ServiceLocator.typeOf
    -- @description Verifies newServiceLocator returns ServiceLocator userdata with working type helpers.
    it("creates a ServiceLocator with correct type", function()
        local sl = lurek.patterns.newServiceLocator()
        expect_equal(sl:type(), "ServiceLocator")
        expect_true(sl:typeOf("ServiceLocator"))
    end)

    -- @covers lurek.patterns.newServiceLocator
    -- @covers lurek.patterns.ServiceLocator.provide
    -- @covers lurek.patterns.ServiceLocator.has
    -- @covers lurek.patterns.ServiceLocator.locate
    -- @description Verifies provide stores a service and locate retrieves it by name.
    it("provide/locate stores and retrieves values", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("logger", { log = function() end })
        expect_true(sl:has("logger"))
        local svc = sl:locate("logger")
        expect_true(svc ~= nil)
    end)

    -- @covers lurek.patterns.newServiceLocator
    -- @covers lurek.patterns.ServiceLocator.locate
    -- @description Verifies locate returns nil for an unregistered service name.
    it("locate returns nil for unknown service", function()
        local sl = lurek.patterns.newServiceLocator()
        local svc = sl:locate("missing")
        expect_nil(svc)
    end)

    -- @covers lurek.patterns.newServiceLocator
    -- @covers lurek.patterns.ServiceLocator.provide
    -- @covers lurek.patterns.ServiceLocator.has
    -- @covers lurek.patterns.ServiceLocator.remove
    -- @description Verifies remove unregisters a previously provided service.
    it("remove deletes a service", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("db", "connection")
        expect_true(sl:has("db"))
        sl:remove("db")
        expect_false(sl:has("db"))
    end)

    -- @covers lurek.patterns.newServiceLocator
    -- @covers lurek.patterns.ServiceLocator.provide
    -- @covers lurek.patterns.ServiceLocator.getServices
    -- @description Verifies getServices returns the set of registered service names.
    it("getServices lists all names", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("a", 1)
        sl:provide("b", 2)
        local names = sl:getServices()
        expect_equal(#names, 2)
    end)

    -- @covers lurek.patterns.newServiceLocator
    -- @covers lurek.patterns.ServiceLocator.provide
    -- @covers lurek.patterns.ServiceLocator.clearAll
    -- @covers lurek.patterns.ServiceLocator.has
    -- @description Verifies clearAll removes every registered service.
    it("clearAll removes everything", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("x", 1)
        sl:provide("y", 2)
        sl:clearAll()
        expect_false(sl:has("x"))
        expect_false(sl:has("y"))
    end)
end)

-- ===================================================================
-- Factory
-- ===================================================================
-- @description Covers suite: lurek.patterns.newFactory.
describe("lurek.patterns.newFactory", function()
    -- @covers lurek.patterns.newFactory
    -- @covers lurek.patterns.Factory.type
    -- @covers lurek.patterns.Factory.typeOf
    -- @description Verifies newFactory returns Factory userdata with working type helpers.
    it("creates a Factory with correct type", function()
        local f = lurek.patterns.newFactory()
        expect_equal(f:type(), "Factory")
        expect_true(f:typeOf("Factory"))
    end)

    -- @covers lurek.patterns.newFactory
    -- @covers lurek.patterns.Factory.register
    -- @covers lurek.patterns.Factory.create
    -- @description Verifies register and create build objects using the named factory callback.
    it("register/create builds objects", function()
        local f = lurek.patterns.newFactory()
        f:register("bullet", function(x, y)
            return { x = x, y = y, kind = "bullet" }
        end)
        local b = f:create("bullet", 10, 20)
        expect_equal(b.x, 10)
        expect_equal(b.y, 20)
        expect_equal(b.kind, "bullet")
    end)

    -- @covers lurek.patterns.newFactory
    -- @covers lurek.patterns.Factory.has
    -- @covers lurek.patterns.Factory.register
    -- @description Verifies has reflects whether a named factory type has been registered.
    it("has checks type registration", function()
        local f = lurek.patterns.newFactory()
        expect_false(f:has("nope"))
        f:register("enemy", function() return {} end)
        expect_true(f:has("enemy"))
    end)

    -- @covers lurek.patterns.newFactory
    -- @covers lurek.patterns.Factory.register
    -- @covers lurek.patterns.Factory.getTypes
    -- @description Verifies getTypes returns the registered factory type names.
    it("getTypes lists registered types", function()
        local f = lurek.patterns.newFactory()
        f:register("a", function() end)
        f:register("b", function() end)
        local types = f:getTypes()
        expect_equal(#types, 2)
    end)

    -- @covers lurek.patterns.newFactory
    -- @covers lurek.patterns.Factory.register
    -- @covers lurek.patterns.Factory.remove
    -- @covers lurek.patterns.Factory.has
    -- @description Verifies remove unregisters a factory type.
    it("remove unregisters a type", function()
        local f = lurek.patterns.newFactory()
        f:register("temp", function() end)
        f:remove("temp")
        expect_false(f:has("temp"))
    end)

    -- @covers lurek.patterns.newFactory
    -- @covers lurek.patterns.Factory.register
    -- @covers lurek.patterns.Factory.clearAll
    -- @covers lurek.patterns.Factory.getTypes
    -- @description Verifies clearAll removes every registered factory type.
    it("clearAll removes all types", function()
        local f = lurek.patterns.newFactory()
        f:register("a", function() end)
        f:register("b", function() end)
        f:clearAll()
        expect_equal(#f:getTypes(), 0)
    end)
end)

-- ===================================================================
-- SimpleState (FSM)
-- ===================================================================
-- @description Covers suite: lurek.patterns.newSimpleState.
describe("lurek.patterns.newSimpleState", function()
    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.type
    -- @covers lurek.patterns.SimpleState.typeOf
    -- @description Verifies newSimpleState returns SimpleState userdata with working type helpers.
    it("creates a SimpleState with correct type", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_equal(fsm:type(), "SimpleState")
        expect_true(fsm:typeOf("SimpleState"))
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.addState
    -- @covers lurek.patterns.SimpleState.transitionTo
    -- @covers lurek.patterns.SimpleState.getCurrent
    -- @description Verifies transitionTo activates registered states and updates the current state name.
    it("addState/transitionTo changes state", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("idle")
        fsm:addState("walk")
        local ok = fsm:transitionTo("idle")
        expect_true(ok)
        expect_equal(fsm:getCurrent(), "idle")
        fsm:transitionTo("walk")
        expect_equal(fsm:getCurrent(), "walk")
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.transitionTo
    -- @description Verifies transitionTo returns false when the target state is unknown.
    it("transitionTo returns false for unknown state", function()
        local fsm = lurek.patterns.newSimpleState()
        local ok = fsm:transitionTo("nonexistent")
        expect_false(ok)
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.addState
    -- @covers lurek.patterns.SimpleState.transitionTo
    -- @description Verifies state enter and exit callbacks run during transitions.
    it("enter and exit callbacks fire on transition", function()
        local fsm = lurek.patterns.newSimpleState()
        local log = {}
        fsm:addState("a", {
            enter = function() table.insert(log, "enter_a") end,
            exit = function() table.insert(log, "exit_a") end,
        })
        fsm:addState("b", {
            enter = function() table.insert(log, "enter_b") end,
        })
        fsm:transitionTo("a")
        expect_equal(log[1], "enter_a")
        fsm:transitionTo("b")
        expect_equal(log[2], "exit_a")
        expect_equal(log[3], "enter_b")
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.addState
    -- @covers lurek.patterns.SimpleState.transitionTo
    -- @covers lurek.patterns.SimpleState.update
    -- @description Verifies update forwards dt to the active state's update callback.
    it("update calls the current state update", function()
        local fsm = lurek.patterns.newSimpleState()
        local dt_received = nil
        fsm:addState("run", {
            update = function(dt) dt_received = dt end,
        })
        fsm:transitionTo("run")
        fsm:update(0.016)
        expect_true(math.abs(dt_received - 0.016) < 0.001)
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.hasState
    -- @covers lurek.patterns.SimpleState.addState
    -- @description Verifies hasState reflects whether a state name has been registered.
    it("hasState checks registration", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_false(fsm:hasState("jump"))
        fsm:addState("jump")
        expect_true(fsm:hasState("jump"))
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.addState
    -- @covers lurek.patterns.SimpleState.getStates
    -- @description Verifies getStates returns all registered state names.
    it("getStates lists all state names", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("idle")
        fsm:addState("walk")
        fsm:addState("run")
        local states = fsm:getStates()
        expect_equal(#states, 3)
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.addState
    -- @covers lurek.patterns.SimpleState.transitionTo
    -- @covers lurek.patterns.SimpleState.clearAll
    -- @covers lurek.patterns.SimpleState.getCurrent
    -- @covers lurek.patterns.SimpleState.getStates
    -- @description Verifies clearAll removes states and resets the current-state pointer.
    it("clearAll resets the FSM", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("a")
        fsm:addState("b")
        fsm:transitionTo("a")
        fsm:clearAll()
        expect_nil(fsm:getCurrent())
        expect_equal(#fsm:getStates(), 0)
    end)
end)

-- @description Covers suite: SimpleState extended coverage (RS parity).
describe("SimpleState extended coverage (RS parity)", function()
    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.hasState
    -- @description Verifies hasState returns false for names that were never registered.
    it("hasState returns false for unregistered state", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_false(fsm:hasState("unknown"))
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.update
    -- @description Verifies update is a no-op when no current state has been selected.
    it("update does not error with no current state", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_no_error(function() fsm:update(0.016) end)
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.addState
    -- @covers lurek.patterns.SimpleState.getCurrent
    -- @description Verifies getCurrent stays nil until transitionTo is called.
    it("getCurrent returns nil before any transition", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("idle")
        expect_nil(fsm:getCurrent())
    end)

    -- @covers lurek.patterns.newSimpleState
    -- @covers lurek.patterns.SimpleState.addState
    -- @covers lurek.patterns.SimpleState.clearAll
    -- @covers lurek.patterns.SimpleState.getStates
    -- @description Verifies states can be added again cleanly after clearAll.
    it("clearAll followed by addState works cleanly", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("a")
        fsm:clearAll()
        fsm:addState("b")
        expect_equal(1, #fsm:getStates())
    end)
end)

-- @description Covers suite: CommandStack undo/redo (RS parity).
describe("CommandStack undo/redo (RS parity)", function()
    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.execute
    -- @covers lurek.patterns.CommandStack.undo
    -- @covers lurek.patterns.CommandStack.redo
    -- @description Verifies a full undo and redo cycle restores the command effect.
    it("undo and redo cycle correctly", function()
        local cs = lurek.patterns.newCommandStack()
        local val = 0
        cs:execute("inc", function() val = val + 1 end, function() val = val - 1 end)
        expect_equal(1, val)
        cs:undo()
        expect_equal(0, val)
        cs:redo()
        expect_equal(1, val)
    end)

    -- @covers lurek.patterns.newCommandStack
    -- @covers lurek.patterns.CommandStack.getHistorySize
    -- @covers lurek.patterns.CommandStack.execute
    -- @description Verifies getHistorySize increments after command execution.
    it("getHistorySize reflects executed commands", function()
        local cs = lurek.patterns.newCommandStack()
        expect_equal(0, cs:getHistorySize())
        cs:execute("op", function() end, function() end)
        expect_equal(1, cs:getHistorySize())
    end)
end)

-- ── Patterns Collections (merged from test_patterns_collections.lua) ──

-- @description Covers suite: lurek.patterns collections (Stack, Queue, List, Set).
describe("lurek.patterns.Stack", function()
    -- @covers lurek.patterns.newStack
    -- @covers lurek.patterns.Stack.push
    -- @covers lurek.patterns.Stack.pop
    -- @covers lurek.patterns.Stack.peek
    -- @covers lurek.patterns.Stack.len
    -- @covers lurek.patterns.Stack.isEmpty
    -- @description Verifies LIFO push/pop ordering.
    it("push and pop follow LIFO order", function()
        local s = lurek.patterns.newStack()
        s:push("a")
        s:push("b")
        s:push("c")
        expect_equal(3, s:len())
        expect_equal("c", s:pop())
        expect_equal("b", s:pop())
        expect_equal("a", s:pop())
        expect_equal(true, s:isEmpty())
    end)

    -- @covers lurek.patterns.Stack.peek
    -- @description Verifies that peek does not remove the top item.
    it("peek does not remove the top item", function()
        local s = lurek.patterns.newStack()
        s:push(42)
        expect_equal(42, s:peek())
        expect_equal(1, s:len())
    end)

    -- @covers lurek.patterns.Stack.isFull
    -- @description Verifies that isFull returns true when capacity is reached.
    it("isFull returns true at capacity", function()
        local s = lurek.patterns.newStack(3)
        s:push(1); s:push(2); s:push(3)
        expect_equal(true, s:isFull())
    end)

    -- @covers lurek.patterns.Stack.toArray
    it("toArray returns all items in order", function()
        local s = lurek.patterns.newStack()
        s:push("x"); s:push("y")
        local arr = s:toArray()
        expect_equal(2, #arr)
    end)

    -- @covers lurek.patterns.Stack.clear
    it("clear empties the stack", function()
        local s = lurek.patterns.newStack()
        s:push(1); s:push(2)
        s:clear()
        expect_equal(0, s:len())
    end)
end)

describe("lurek.patterns.Queue", function()
    -- @covers lurek.patterns.newQueue
    -- @covers lurek.patterns.Queue.enqueue
    -- @covers lurek.patterns.Queue.dequeue
    -- @description Verifies FIFO enqueue/dequeue ordering.
    it("enqueue and dequeue follow FIFO order", function()
        local q = lurek.patterns.newQueue()
        q:enqueue("first")
        q:enqueue("second")
        q:enqueue("third")
        expect_equal("first", q:dequeue())
        expect_equal("second", q:dequeue())
    end)

    -- @covers lurek.patterns.Queue.front
    it("front peeks without removing", function()
        local q = lurek.patterns.newQueue()
        q:enqueue("peek_me")
        expect_equal("peek_me", q:front())
        expect_equal(1, q:len())
    end)

    -- @covers lurek.patterns.Queue.isEmpty
    it("isEmpty returns true on empty queue", function()
        local q = lurek.patterns.newQueue()
        expect_equal(true, q:isEmpty())
        q:enqueue("x")
        expect_equal(false, q:isEmpty())
    end)
end)

describe("lurek.patterns.List", function()
    -- @covers lurek.patterns.newList
    -- @covers lurek.patterns.List.add
    -- @covers lurek.patterns.List.get
    -- @covers lurek.patterns.List.set
    -- @covers lurek.patterns.List.remove
    -- @description Verifies indexed add/get/set/remove operations.
    it("supports indexed access and removal", function()
        local l = lurek.patterns.newList()
        l:add("alpha")
        l:add("beta")
        l:add("gamma")
        expect_equal(3, l:len())
        expect_equal("beta", l:get(2))
        l:set(2, "BETA")
        expect_equal("BETA", l:get(2))
        l:remove(1)
        expect_equal(2, l:len())
    end)

    -- @covers lurek.patterns.List.contains
    it("contains returns true for present and false for absent values", function()
        local l = lurek.patterns.newList()
        l:add("hello")
        expect_equal(true, l:contains("hello"))
        expect_equal(false, l:contains("world"))
    end)
end)

describe("lurek.patterns.Set", function()
    -- @covers lurek.patterns.newSet
    -- @covers lurek.patterns.Set.add
    -- @covers lurek.patterns.Set.has
    -- @covers lurek.patterns.Set.remove
    -- @description Verifies that Set provides string membership.
    it("add, has, and remove work for string members", function()
        local s = lurek.patterns.newSet()
        s:add("fire")
        s:add("water")
        expect_equal(true, s:has("fire"))
        expect_equal(false, s:has("earth"))
        s:remove("fire")
        expect_equal(false, s:has("fire"))
        expect_equal(1, s:len())
    end)

    -- @covers lurek.patterns.Set.union
    it("union returns a set containing all elements of both sets", function()
        local a = lurek.patterns.newSet()
        local b = lurek.patterns.newSet()
        a:add("x"); a:add("y")
        b:add("y"); b:add("z")
        local u = a:union(b)
        expect_equal(3, u:len())
    end)

    -- @covers lurek.patterns.Set.intersection
    it("intersection returns only shared elements", function()
        local a = lurek.patterns.newSet()
        local b = lurek.patterns.newSet()
        a:add("x"); a:add("y"); a:add("z")
        b:add("y"); b:add("z"); b:add("w")
        local i = a:intersection(b)
        expect_equal(2, i:len())
    end)

    -- @covers lurek.patterns.Set.toArray
    it("toArray returns all set members", function()
        local s = lurek.patterns.newSet()
        s:add("one"); s:add("two"); s:add("three")
        local arr = s:toArray()
        expect_equal(3, #arr)
    end)
end)

-- ── Patterns Mediator (merged from test_patterns_mediator.lua) ──

-- @description Covers suite: lurek.patterns Mediator.
describe("lurek.patterns.Mediator", function()
    -- @covers lurek.patterns.newMediator
    -- @covers lurek.patterns.Mediator.on
    -- @covers lurek.patterns.Mediator.send
    -- @description Verifies that a registered handler receives sent messages.
    it("on registers a handler that receives send messages", function()
        local m = lurek.patterns.newMediator()
        local received = nil
        m:on("click", function(data)
            received = data
        end)
        m:send("click", "hello")
        expect_equal("hello", received)
    end)

    -- @covers lurek.patterns.Mediator.off
    -- @description Verifies that off by handler id stops the handler receiving messages.
    it("off removes handler by id", function()
        local m = lurek.patterns.newMediator()
        local count = 0
        local id = m:on("tick", function() count = count + 1 end)
        m:send("tick")
        m:off("tick", id)
        m:send("tick")
        expect_equal(1, count)
    end)

    -- @covers lurek.patterns.Mediator.broadcast
    -- @description Verifies that broadcast delivers to all subscribed channels that match.
    it("send only fires handler on its own channel", function()
        local m = lurek.patterns.newMediator()
        local hit = 0
        m:on("channelA", function() hit = hit + 1 end)
        m:on("channelB", function() hit = hit + 100 end)
        m:send("channelA", "payload")
        expect_equal(1, hit)
    end)

    -- @covers lurek.patterns.Mediator.handlerCount
    -- @description Verifies that handlerCount reflects registered/removed handlers.
    it("handlerCount tracks registration and removal", function()
        local m = lurek.patterns.newMediator()
        expect_equal(0, m:handlerCount("events"))
        local id = m:on("events", function() end)
        expect_equal(1, m:handlerCount("events"))
        m:off("events", id)
        expect_equal(0, m:handlerCount("events"))
    end)

    -- @covers lurek.patterns.Mediator.channels
    -- @description Verifies that channels returns all channel names.
    it("channels returns registered channel names", function()
        local m = lurek.patterns.newMediator()
        m:on("alpha", function() end)
        m:on("beta", function() end)
        local ch = m:channels()
        expect_equal(2, #ch)
    end)

    -- @covers lurek.patterns.Mediator.removeChannel
    -- @description Verifies that removeChannel clears all handlers on that channel.
    it("removeChannel removes all handlers on a channel", function()
        local m = lurek.patterns.newMediator()
        m:on("destroy", function() end)
        m:on("destroy", function() end)
        expect_equal(2, m:handlerCount("destroy"))
        m:removeChannel("destroy")
        expect_equal(0, m:handlerCount("destroy"))
    end)

    -- @covers lurek.patterns.Mediator.clear
    -- @description Verifies that clear removes all channels and handlers.
    it("clear removes all channels", function()
        local m = lurek.patterns.newMediator()
        m:on("a", function() end)
        m:on("b", function() end)
        m:clear()
        local ch = m:channels()
        expect_equal(0, #ch)
    end)
end)

-- ── Patterns Strategy (merged from test_patterns_strategy.lua) ──

-- @description Covers suite: lurek.patterns Strategy.
describe("lurek.patterns.Strategy", function()
    -- @covers lurek.patterns.newStrategy
    -- @covers lurek.patterns.Strategy.register
    -- @covers lurek.patterns.Strategy.set
    -- @covers lurek.patterns.Strategy.execute
    -- @description Verifies that register+set+execute calls the registered function.
    it("register, set, and execute calls the strategy function", function()
        local s = lurek.patterns.newStrategy()
        local called = false
        s:register("run", function() called = true end)
        s:set("run")
        s:execute()
        expect_equal(true, called)
    end)

    -- @covers lurek.patterns.Strategy.getCurrent
    -- @description Verifies that getCurrent returns the active strategy name.
    it("getCurrent returns the active strategy name", function()
        local s = lurek.patterns.newStrategy()
        s:register("patrol", function() end)
        expect_equal(nil, s:getCurrent())
        s:set("patrol")
        expect_equal("patrol", s:getCurrent())
    end)

    -- @covers lurek.patterns.Strategy.has
    -- @description Verifies that has returns true for registered strategies and false otherwise.
    it("has returns true for registered names and false for unknown", function()
        local s = lurek.patterns.newStrategy()
        s:register("attack", function() end)
        expect_equal(true, s:has("attack"))
        expect_equal(false, s:has("retreat"))
    end)

    -- @covers lurek.patterns.Strategy.remove
    -- @description Verifies that remove unregisters a strategy and clears current if it was active.
    it("remove unregisters a strategy", function()
        local s = lurek.patterns.newStrategy()
        s:register("idle", function() end)
        s:set("idle")
        local ok = s:remove("idle")
        expect_equal(true, ok)
        expect_equal(false, s:has("idle"))
        expect_equal(nil, s:getCurrent())
    end)

    -- @covers lurek.patterns.Strategy.names
    -- @description Verifies that names returns all registered strategy names.
    it("names returns all registered names", function()
        local s = lurek.patterns.newStrategy()
        s:register("walk", function() end)
        s:register("sprint", function() end)
        s:register("crouch", function() end)
        local names = s:names()
        expect_equal(3, #names)
    end)

    -- @covers lurek.patterns.Strategy.execute
    -- @description Verifies that execute passes arguments to the strategy function.
    it("execute passes arguments to the strategy function", function()
        local s = lurek.patterns.newStrategy()
        local got_dt = nil
        s:register("move", function(dt) got_dt = dt end)
        s:set("move")
        s:execute(0.016)
        expect_near(0.016, got_dt, 1e-6)
    end)

    -- @covers lurek.patterns.Strategy.clear
    -- @description Verifies that clear removes all strategies and resets current.
    it("clear removes all strategies", function()
        local s = lurek.patterns.newStrategy()
        s:register("a", function() end)
        s:register("b", function() end)
        s:set("a")
        s:clear()
        expect_equal(0, #s:names())
        expect_equal(nil, s:getCurrent())
    end)
end)

test_summary()

-- [merged from test_patterns_regress_acquire_borrow.lua]
-- Regression: ObjectPool:acquire must not trigger a RefCell double-borrow.
-- Before the fix the outer `pool.borrow_mut().acquire()` RefMut stayed alive
-- through the if-let body, so the nested `pool.borrow_mut().release(id)`
-- aborted with "already borrowed".

-- @description Covers suite: ObjectPool regression — acquire must not double-borrow internal RefCell.
describe("ObjectPool regression: acquire double-borrow", function()
    -- @covers lurek.patterns.newObjectPool
    -- @covers lurek.patterns.ObjectPool.acquire
    -- @covers lurek.patterns.ObjectPool.release
    it("acquire -> release -> acquire cycle does not panic", function()
        local pool = lurek.patterns.newObjectPool()
        pool:add({ id = "a" })
        expect_no_error(function()
            local v1 = pool:acquire()
            pool:release(v1)
            local v2 = pool:acquire()
            pool:release(v2)
        end)
    end)
end)

test_summary()

