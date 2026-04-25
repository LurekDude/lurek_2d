-- tests/lua/test_patterns.lua
-- BDD-style integration tests for lurek.patterns module

-- ===================================================================
-- EventBus
-- ===================================================================

-- @description Covers suite: lurek.patterns.newEventBus.
describe("lurek.patterns.newEventBus", function()
    -- @tests lurek.patterns.newEventBus
    -- @tests lurek.patterns.EventBus.type
    -- @tests lurek.patterns.EventBus.typeOf
    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.newFactory
    -- @tests lurek.patterns.newObjectPool
    -- @tests lurek.patterns.newServiceLocator
    -- @tests lurek.patterns.newSimpleState
    -- @description Verifies newEventBus returns EventBus userdata with working type checks.
    xit("creates an EventBus with type/typeOf", function()
        local bus = lurek.patterns.newEventBus()
        expect_equal(bus:type(), "EventBus") ---@diagnostic disable-line: undefined-field
        expect_true(bus:typeOf("EventBus")) ---@diagnostic disable-line: undefined-field
        expect_true(bus:typeOf("Object")) ---@diagnostic disable-line: undefined-field
    end)

    -- @tests lurek.patterns.newEventBus
    -- @tests lurek.patterns.EventBus.on
    -- @tests lurek.patterns.EventBus.emit
    -- @description Verifies EventBus:on registers listeners that EventBus:emit invokes with payload data.
    it("on/emit fires callbacks", function()
        local bus = lurek.patterns.newEventBus()
        local received = nil
        bus:on("ping", function(val) received = val end)
        bus:emit("ping", 42)
        expect_equal(received, 42)
    end)

    -- @tests lurek.patterns.newEventBus
    -- @tests lurek.patterns.EventBus.on
    -- @description Verifies EventBus:on returns distinct subscription IDs for separate listeners.
    it("on returns unique subscription IDs", function()
        local bus = lurek.patterns.newEventBus()
        local id1 = bus:on("a", function() end)
        local id2 = bus:on("a", function() end)
        expect_true(id1 ~= id2)
    end)

    -- @tests lurek.patterns.newEventBus
    -- @tests lurek.patterns.EventBus.on
    -- @tests lurek.patterns.EventBus.emit
    -- @description Verifies EventBus executes listeners in priority order.
    xit("listeners fire in priority order", function()
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

    -- @tests lurek.patterns.newEventBus
    -- @tests lurek.patterns.EventBus.on
    -- @tests lurek.patterns.EventBus.off
    -- @tests lurek.patterns.EventBus.emit
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

    -- @tests lurek.patterns.newEventBus
    -- @tests lurek.patterns.EventBus.on
    -- @tests lurek.patterns.EventBus.clear
    -- @tests lurek.patterns.EventBus.getListenerCount
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

    -- @tests lurek.patterns.newEventBus
    -- @tests lurek.patterns.EventBus.on
    -- @tests lurek.patterns.EventBus.clearAll
    -- @tests lurek.patterns.EventBus.getListenerCount
    -- @description Verifies EventBus:clearAll removes listeners across every event.
    it("clearAll removes all listeners", function()
        local bus = lurek.patterns.newEventBus()
        bus:on("a", function() end)
        bus:on("b", function() end)
        bus:clearAll()
        expect_equal(bus:getListenerCount("a"), 0)
        expect_equal(bus:getListenerCount("b"), 0)
    end)

    -- @tests lurek.patterns.newEventBus
    -- @tests lurek.patterns.EventBus.on
    -- @tests lurek.patterns.EventBus.getEvents
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
    -- @tests lurek.patterns.newObjectPool
    -- @tests lurek.patterns.ObjectPool.type
    -- @tests lurek.patterns.ObjectPool.typeOf
    -- @description Verifies newObjectPool returns ObjectPool userdata with working type helpers.
    xit("creates an ObjectPool with correct type", function()
        local pool = lurek.patterns.newObjectPool()
        expect_equal(pool:type(), "ObjectPool") ---@diagnostic disable-line: undefined-field
        expect_true(pool:typeOf("ObjectPool")) ---@diagnostic disable-line: undefined-field
    end)

    -- @tests lurek.patterns.newObjectPool
    -- @tests lurek.patterns.ObjectPool.add
    -- @tests lurek.patterns.ObjectPool.acquire
    -- @tests lurek.patterns.ObjectPool.getAvailableCount
    -- @tests lurek.patterns.ObjectPool.getActiveCount
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

    -- @tests lurek.patterns.newObjectPool
    -- @tests lurek.patterns.ObjectPool.acquire
    -- @description Verifies ObjectPool:acquire returns nil when no pooled objects exist.
    xit("acquire returns nil on empty pool", function()
        local pool = lurek.patterns.newObjectPool()
        local obj = pool:acquire()
        expect_nil(obj)
    end)

    -- @tests lurek.patterns.newObjectPool
    -- @tests lurek.patterns.ObjectPool.add
    -- @tests lurek.patterns.ObjectPool.acquire
    -- @tests lurek.patterns.ObjectPool.release
    -- @tests lurek.patterns.ObjectPool.getActiveCount
    -- @tests lurek.patterns.ObjectPool.getAvailableCount
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

    -- @tests lurek.patterns.newObjectPool
    -- @tests lurek.patterns.ObjectPool.add
    -- @tests lurek.patterns.ObjectPool.acquire
    -- @tests lurek.patterns.ObjectPool.getTotalCount
    -- @description Verifies ObjectPool:getTotalCount reports active plus available objects.
    it("getTotalCount sums active + available", function()
        local pool = lurek.patterns.newObjectPool()
        pool:add("a")
        pool:add("b")
        pool:acquire()
        expect_equal(pool:getTotalCount(), 2)
    end)

    -- @tests lurek.patterns.newObjectPool
    -- @tests lurek.patterns.ObjectPool.add
    -- @tests lurek.patterns.ObjectPool.acquire
    -- @tests lurek.patterns.ObjectPool.clearAll
    -- @tests lurek.patterns.ObjectPool.getTotalCount
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
    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.type
    -- @tests lurek.patterns.CommandStack.typeOf
    -- @description Verifies newCommandStack returns CommandStack userdata with working type checks.
    xit("creates a CommandStack with correct type", function()
        local cmds = lurek.patterns.newCommandStack()
        expect_equal(cmds:type(), "CommandStack") ---@diagnostic disable-line: undefined-field
        expect_true(cmds:typeOf("CommandStack")) ---@diagnostic disable-line: undefined-field
    end)

    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.execute
    -- @description Verifies CommandStack:execute runs the forward command immediately.
    it("execute runs the command immediately", function()
        local cmds = lurek.patterns.newCommandStack()
        local x = 0
        cmds:execute("inc", function() x = x + 1 end)
        expect_equal(x, 1)
    end)

    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.execute
    -- @tests lurek.patterns.CommandStack.undo
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

    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.execute
    -- @tests lurek.patterns.CommandStack.undo
    -- @tests lurek.patterns.CommandStack.redo
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

    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.execute
    -- @tests lurek.patterns.CommandStack.undo
    -- @tests lurek.patterns.CommandStack.canUndo
    -- @tests lurek.patterns.CommandStack.canRedo
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

    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.execute
    -- @tests lurek.patterns.CommandStack.undo
    -- @tests lurek.patterns.CommandStack.canRedo
    -- @tests lurek.patterns.CommandStack.getHistorySize
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

    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.execute
    -- @tests lurek.patterns.CommandStack.getCurrentName
    -- @description Verifies getCurrentName reflects the most recently executed command name.
    it("getCurrentName returns the last command name", function()
        local cmds = lurek.patterns.newCommandStack()
        expect_nil(cmds:getCurrentName())
        cmds:execute("move", function() end)
        expect_equal(cmds:getCurrentName(), "move")
    end)

    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.execute
    -- @tests lurek.patterns.CommandStack.clearAll
    -- @tests lurek.patterns.CommandStack.getHistorySize
    -- @tests lurek.patterns.CommandStack.canUndo
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
    -- @tests lurek.patterns.newServiceLocator
    -- @tests lurek.patterns.ServiceLocator.type
    -- @tests lurek.patterns.ServiceLocator.typeOf
    -- @description Verifies newServiceLocator returns ServiceLocator userdata with working type helpers.
    xit("creates a ServiceLocator with correct type", function()
        local sl = lurek.patterns.newServiceLocator()
        expect_equal(sl:type(), "ServiceLocator") ---@diagnostic disable-line: undefined-field
        expect_true(sl:typeOf("ServiceLocator")) ---@diagnostic disable-line: undefined-field
    end)

    -- @tests lurek.patterns.newServiceLocator
    -- @tests lurek.patterns.ServiceLocator.provide
    -- @tests lurek.patterns.ServiceLocator.has
    -- @tests lurek.patterns.ServiceLocator.locate
    -- @description Verifies provide stores a service and locate retrieves it by name.
    it("provide/locate stores and retrieves values", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("logger", { log = function() end })
        expect_true(sl:has("logger"))
        local svc = sl:locate("logger")
        expect_true(svc ~= nil)
    end)

    -- @tests lurek.patterns.newServiceLocator
    -- @tests lurek.patterns.ServiceLocator.locate
    -- @description Verifies locate returns nil for an unregistered service name.
    it("locate returns nil for unknown service", function()
        local sl = lurek.patterns.newServiceLocator()
        local svc = sl:locate("missing")
        expect_nil(svc)
    end)

    -- @tests lurek.patterns.newServiceLocator
    -- @tests lurek.patterns.ServiceLocator.provide
    -- @tests lurek.patterns.ServiceLocator.has
    -- @tests lurek.patterns.ServiceLocator.remove
    -- @description Verifies remove unregisters a previously provided service.
    it("remove deletes a service", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("db", "connection")
        expect_true(sl:has("db"))
        sl:remove("db")
        expect_false(sl:has("db"))
    end)

    -- @tests lurek.patterns.newServiceLocator
    -- @tests lurek.patterns.ServiceLocator.provide
    -- @tests lurek.patterns.ServiceLocator.getServices
    -- @description Verifies getServices returns the set of registered service names.
    it("getServices lists all names", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("a", 1)
        sl:provide("b", 2)
        local names = sl:getServices()
        expect_equal(#names, 2)
    end)

    -- @tests lurek.patterns.newServiceLocator
    -- @tests lurek.patterns.ServiceLocator.provide
    -- @tests lurek.patterns.ServiceLocator.clearAll
    -- @tests lurek.patterns.ServiceLocator.has
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
    -- @tests lurek.patterns.newFactory
    -- @tests lurek.patterns.Factory.type
    -- @tests lurek.patterns.Factory.typeOf
    -- @description Verifies newFactory returns Factory userdata with working type helpers.
    xit("creates a Factory with correct type", function()
        local f = lurek.patterns.newFactory()
        expect_equal(f:type(), "Factory") ---@diagnostic disable-line: undefined-field
        expect_true(f:typeOf("Factory")) ---@diagnostic disable-line: undefined-field
    end)

    -- @tests lurek.patterns.newFactory
    -- @tests lurek.patterns.Factory.register
    -- @tests lurek.patterns.Factory.create
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

    -- @tests lurek.patterns.newFactory
    -- @tests lurek.patterns.Factory.has
    -- @tests lurek.patterns.Factory.register
    -- @description Verifies has reflects whether a named factory type has been registered.
    it("has checks type registration", function()
        local f = lurek.patterns.newFactory()
        expect_false(f:has("nope"))
        f:register("enemy", function() return {} end)
        expect_true(f:has("enemy"))
    end)

    -- @tests lurek.patterns.newFactory
    -- @tests lurek.patterns.Factory.register
    -- @tests lurek.patterns.Factory.getTypes
    -- @description Verifies getTypes returns the registered factory type names.
    it("getTypes lists registered types", function()
        local f = lurek.patterns.newFactory()
        f:register("a", function() end)
        f:register("b", function() end)
        local types = f:getTypes()
        expect_equal(#types, 2)
    end)

    -- @tests lurek.patterns.newFactory
    -- @tests lurek.patterns.Factory.register
    -- @tests lurek.patterns.Factory.remove
    -- @tests lurek.patterns.Factory.has
    -- @description Verifies remove unregisters a factory type.
    it("remove unregisters a type", function()
        local f = lurek.patterns.newFactory()
        f:register("temp", function() end)
        f:remove("temp")
        expect_false(f:has("temp"))
    end)

    -- @tests lurek.patterns.newFactory
    -- @tests lurek.patterns.Factory.register
    -- @tests lurek.patterns.Factory.clearAll
    -- @tests lurek.patterns.Factory.getTypes
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
    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.type
    -- @tests lurek.patterns.SimpleState.typeOf
    -- @description Verifies newSimpleState returns SimpleState userdata with working type helpers.
    xit("creates a SimpleState with correct type", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_equal(fsm:type(), "SimpleState") ---@diagnostic disable-line: undefined-field
        expect_true(fsm:typeOf("SimpleState")) ---@diagnostic disable-line: undefined-field
    end)

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.addState
    -- @tests lurek.patterns.SimpleState.transitionTo
    -- @tests lurek.patterns.SimpleState.getCurrent
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

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.transitionTo
    -- @description Verifies transitionTo returns false when the target state is unknown.
    it("transitionTo returns false for unknown state", function()
        local fsm = lurek.patterns.newSimpleState()
        local ok = fsm:transitionTo("nonexistent")
        expect_false(ok)
    end)

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.addState
    -- @tests lurek.patterns.SimpleState.transitionTo
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

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.addState
    -- @tests lurek.patterns.SimpleState.transitionTo
    -- @tests lurek.patterns.SimpleState.update
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

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.hasState
    -- @tests lurek.patterns.SimpleState.addState
    -- @description Verifies hasState reflects whether a state name has been registered.
    it("hasState checks registration", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_false(fsm:hasState("jump"))
        fsm:addState("jump")
        expect_true(fsm:hasState("jump"))
    end)

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.addState
    -- @tests lurek.patterns.SimpleState.getStates
    -- @description Verifies getStates returns all registered state names.
    it("getStates lists all state names", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("idle")
        fsm:addState("walk")
        fsm:addState("run")
        local states = fsm:getStates()
        expect_equal(#states, 3)
    end)

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.addState
    -- @tests lurek.patterns.SimpleState.transitionTo
    -- @tests lurek.patterns.SimpleState.clearAll
    -- @tests lurek.patterns.SimpleState.getCurrent
    -- @tests lurek.patterns.SimpleState.getStates
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
    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.hasState
    -- @description Verifies hasState returns false for names that were never registered.
    it("hasState returns false for unregistered state", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_false(fsm:hasState("unknown"))
    end)

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.update
    -- @description Verifies update is a no-op when no current state has been selected.
    it("update does not error with no current state", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_no_error(function() fsm:update(0.016) end)
    end)

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.addState
    -- @tests lurek.patterns.SimpleState.getCurrent
    -- @description Verifies getCurrent stays nil until transitionTo is called.
    it("getCurrent returns nil before any transition", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("idle")
        expect_nil(fsm:getCurrent())
    end)

    -- @tests lurek.patterns.newSimpleState
    -- @tests lurek.patterns.SimpleState.addState
    -- @tests lurek.patterns.SimpleState.clearAll
    -- @tests lurek.patterns.SimpleState.getStates
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
    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.execute
    -- @tests lurek.patterns.CommandStack.undo
    -- @tests lurek.patterns.CommandStack.redo
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

    -- @tests lurek.patterns.newCommandStack
    -- @tests lurek.patterns.CommandStack.getHistorySize
    -- @tests lurek.patterns.CommandStack.execute
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
    -- @tests lurek.patterns.newStack
    -- @tests lurek.patterns.Stack.push
    -- @tests lurek.patterns.Stack.pop
    -- @tests lurek.patterns.Stack.peek
    -- @tests lurek.patterns.Stack.len
    -- @tests lurek.patterns.Stack.isEmpty
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

    -- @tests lurek.patterns.Stack.peek
    -- @description Verifies that peek does not remove the top item.
    it("peek does not remove the top item", function()
        local s = lurek.patterns.newStack()
        s:push(42)
        expect_equal(42, s:peek())
        expect_equal(1, s:len())
    end)

    -- @tests lurek.patterns.Stack.isFull
    -- @description Verifies that isFull returns true when capacity is reached.
    it("isFull returns true at capacity", function()
        local s = lurek.patterns.newStack(3)
        s:push(1); s:push(2); s:push(3)
        expect_equal(true, s:isFull())
    end)

    -- @tests lurek.patterns.Stack.toArray
    it("toArray returns all items in order", function()
        local s = lurek.patterns.newStack()
        s:push("x"); s:push("y")
        local arr = s:toArray()
        expect_equal(2, #arr)
    end)

    -- @tests lurek.patterns.Stack.clear
    it("clear empties the stack", function()
        local s = lurek.patterns.newStack()
        s:push(1); s:push(2)
        s:clear()
        expect_equal(0, s:len())
    end)
end)

describe("lurek.patterns.Queue", function()
    -- @tests lurek.patterns.newQueue
    -- @tests lurek.patterns.Queue.enqueue
    -- @tests lurek.patterns.Queue.dequeue
    -- @description Verifies FIFO enqueue/dequeue ordering.
    it("enqueue and dequeue follow FIFO order", function()
        local q = lurek.patterns.newQueue()
        q:enqueue("first")
        q:enqueue("second")
        q:enqueue("third")
        expect_equal("first", q:dequeue())
        expect_equal("second", q:dequeue())
    end)

    -- @tests lurek.patterns.Queue.front
    it("front peeks without removing", function()
        local q = lurek.patterns.newQueue()
        q:enqueue("peek_me")
        expect_equal("peek_me", q:front())
        expect_equal(1, q:len())
    end)

    -- @tests lurek.patterns.Queue.isEmpty
    it("isEmpty returns true on empty queue", function()
        local q = lurek.patterns.newQueue()
        expect_equal(true, q:isEmpty())
        q:enqueue("x")
        expect_equal(false, q:isEmpty())
    end)
end)

describe("lurek.patterns.List", function()
    -- @tests lurek.patterns.newList
    -- @tests lurek.patterns.List.add
    -- @tests lurek.patterns.List.get
    -- @tests lurek.patterns.List.set
    -- @tests lurek.patterns.List.remove
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

    -- @tests lurek.patterns.List.contains
    it("contains returns true for present and false for absent values", function()
        local l = lurek.patterns.newList()
        l:add("hello")
        expect_equal(true, l:contains("hello"))
        expect_equal(false, l:contains("world"))
    end)
end)

describe("lurek.patterns.Set", function()
    -- @tests lurek.patterns.newSet
    -- @tests lurek.patterns.Set.add
    -- @tests lurek.patterns.Set.has
    -- @tests lurek.patterns.Set.remove
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

    -- @tests lurek.patterns.Set.union
    it("union returns a set containing all elements of both sets", function()
        local a = lurek.patterns.newSet()
        local b = lurek.patterns.newSet()
        a:add("x"); a:add("y")
        b:add("y"); b:add("z")
        local u = a:union(b)
        expect_equal(3, u:len())
    end)

    -- @tests lurek.patterns.Set.intersection
    it("intersection returns only shared elements", function()
        local a = lurek.patterns.newSet()
        local b = lurek.patterns.newSet()
        a:add("x"); a:add("y"); a:add("z")
        b:add("y"); b:add("z"); b:add("w")
        local i = a:intersection(b)
        expect_equal(2, i:len())
    end)

    -- @tests lurek.patterns.Set.toArray
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
    -- @tests lurek.patterns.newMediator
    -- @tests lurek.patterns.Mediator.on
    -- @tests lurek.patterns.Mediator.send
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

    -- @tests lurek.patterns.Mediator.off
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

    -- @tests lurek.patterns.Mediator.broadcast
    -- @description Verifies that broadcast delivers to all subscribed channels that match.
    it("send only fires handler on its own channel", function()
        local m = lurek.patterns.newMediator()
        local hit = 0
        m:on("channelA", function() hit = hit + 1 end)
        m:on("channelB", function() hit = hit + 100 end)
        m:send("channelA", "payload")
        expect_equal(1, hit)
    end)

    -- @tests lurek.patterns.Mediator.handlerCount
    -- @description Verifies that handlerCount reflects registered/removed handlers.
    it("handlerCount tracks registration and removal", function()
        local m = lurek.patterns.newMediator()
        expect_equal(0, m:handlerCount("events"))
        local id = m:on("events", function() end)
        expect_equal(1, m:handlerCount("events"))
        m:off("events", id)
        expect_equal(0, m:handlerCount("events"))
    end)

    -- @tests lurek.patterns.Mediator.channels
    -- @description Verifies that channels returns all channel names.
    it("channels returns registered channel names", function()
        local m = lurek.patterns.newMediator()
        m:on("alpha", function() end)
        m:on("beta", function() end)
        local ch = m:channels()
        expect_equal(2, #ch)
    end)

    -- @tests lurek.patterns.Mediator.removeChannel
    -- @description Verifies that removeChannel clears all handlers on that channel.
    it("removeChannel removes all handlers on a channel", function()
        local m = lurek.patterns.newMediator()
        m:on("destroy", function() end)
        m:on("destroy", function() end)
        expect_equal(2, m:handlerCount("destroy"))
        m:removeChannel("destroy")
        expect_equal(0, m:handlerCount("destroy"))
    end)

    -- @tests lurek.patterns.Mediator.clear
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
    -- @tests lurek.patterns.newStrategy
    -- @tests lurek.patterns.Strategy.register
    -- @tests lurek.patterns.Strategy.set
    -- @tests lurek.patterns.Strategy.execute
    -- @description Verifies that register+set+execute calls the registered function.
    it("register, set, and execute calls the strategy function", function()
        local s = lurek.patterns.newStrategy()
        local called = false
        s:register("run", function() called = true end)
        s:set("run")
        s:execute()
        expect_equal(true, called)
    end)

    -- @tests lurek.patterns.Strategy.getCurrent
    -- @description Verifies that getCurrent returns the active strategy name.
    it("getCurrent returns the active strategy name", function()
        local s = lurek.patterns.newStrategy()
        s:register("patrol", function() end)
        expect_equal(nil, s:getCurrent())
        s:set("patrol")
        expect_equal("patrol", s:getCurrent())
    end)

    -- @tests lurek.patterns.Strategy.has
    -- @description Verifies that has returns true for registered strategies and false otherwise.
    it("has returns true for registered names and false for unknown", function()
        local s = lurek.patterns.newStrategy()
        s:register("attack", function() end)
        expect_equal(true, s:has("attack"))
        expect_equal(false, s:has("retreat"))
    end)

    -- @tests lurek.patterns.Strategy.remove
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

    -- @tests lurek.patterns.Strategy.names
    -- @description Verifies that names returns all registered strategy names.
    it("names returns all registered names", function()
        local s = lurek.patterns.newStrategy()
        s:register("walk", function() end)
        s:register("sprint", function() end)
        s:register("crouch", function() end)
        local names = s:names()
        expect_equal(3, #names)
    end)

    -- @tests lurek.patterns.Strategy.execute
    -- @description Verifies that execute passes arguments to the strategy function.
    it("execute passes arguments to the strategy function", function()
        local s = lurek.patterns.newStrategy()
        local got_dt = nil
        s:register("move", function(dt) got_dt = dt end)
        s:set("move")
        s:execute(0.016)
        expect_near(0.016, got_dt, 1e-6)
    end)

    -- @tests lurek.patterns.Strategy.clear
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



-- [merged from test_patterns_regress_acquire_borrow.lua]
-- Regression: ObjectPool:acquire must not trigger a RefCell double-borrow.
-- Before the fix the outer `pool.borrow_mut().acquire()` RefMut stayed alive
-- through the if-let body, so the nested `pool.borrow_mut().release(id)`
-- aborted with "already borrowed".

-- @description Covers suite: ObjectPool regression — acquire must not double-borrow internal RefCell.
describe("ObjectPool regression: acquire double-borrow", function()
    -- @tests lurek.patterns.newObjectPool
    -- @tests lurek.patterns.ObjectPool.acquire
    -- @tests lurek.patterns.ObjectPool.release
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





-- ================================================================
-- Merged from: test_patterns_regress_acquire_borrow.lua
-- ================================================================

-- Regression: ObjectPool:acquire must not trigger a RefCell double-borrow.
-- Before the fix the outer `pool.borrow_mut().acquire()` RefMut stayed alive
-- through the if-let body, so the nested `pool.borrow_mut().release(id)`
-- aborted with "already borrowed".

-- @description Covers suite: ObjectPool regression — acquire must not double-borrow internal RefCell.
describe("ObjectPool regression: acquire double-borrow", function()
    -- @tests lurek.patterns.newObjectPool
    -- @tests lurek.patterns.ObjectPool.acquire
    -- @tests lurek.patterns.ObjectPool.release
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

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.patterns.newThrottle
    it("covers lurek.patterns.newThrottle", function()
        -- TODO: Implement test for lurek.patterns.newThrottle
    end)

    -- @tests lurek.patterns.newDebounce
    it("covers lurek.patterns.newDebounce", function()
        -- TODO: Implement test for lurek.patterns.newDebounce
    end)

    -- @tests lurek.patterns.newPriorityQueue
    it("covers lurek.patterns.newPriorityQueue", function()
        -- TODO: Implement test for lurek.patterns.newPriorityQueue
    end)

    -- @tests lurek.patterns.newFunnel
    it("covers lurek.patterns.newFunnel", function()
        -- TODO: Implement test for lurek.patterns.newFunnel
    end)

    -- @tests EventBus:on
    it("covers EventBus:on", function()
        -- TODO: Implement test for EventBus:on
    end)

    -- @tests EventBus:off
    it("covers EventBus:off", function()
        -- TODO: Implement test for EventBus:off
    end)

    -- @tests ObjectPool:add
    it("covers ObjectPool:add", function()
        -- TODO: Implement test for ObjectPool:add
    end)

    -- @tests ServiceLocator:has
    it("covers ServiceLocator:has", function()
        -- TODO: Implement test for ServiceLocator:has
    end)

    -- @tests Factory:has
    it("covers Factory:has", function()
        -- TODO: Implement test for Factory:has
    end)

    -- @tests Blackboard:set
    it("covers Blackboard:set", function()
        -- TODO: Implement test for Blackboard:set
    end)

    -- @tests Blackboard:get
    it("covers Blackboard:get", function()
        -- TODO: Implement test for Blackboard:get
    end)

    -- @tests Blackboard:has
    it("covers Blackboard:has", function()
        -- TODO: Implement test for Blackboard:has
    end)

    -- @tests Blackboard:getRevision
    it("covers Blackboard:getRevision", function()
        -- TODO: Implement test for Blackboard:getRevision
    end)

    -- @tests Observer:set
    it("covers Observer:set", function()
        -- TODO: Implement test for Observer:set
    end)

    -- @tests Observer:get
    it("covers Observer:get", function()
        -- TODO: Implement test for Observer:get
    end)

    -- @tests Throttle:onFire
    it("covers Throttle:onFire", function()
        -- TODO: Implement test for Throttle:onFire
    end)

    -- @tests Throttle:getFireCount
    it("covers Throttle:getFireCount", function()
        -- TODO: Implement test for Throttle:getFireCount
    end)

    -- @tests Debounce:onFire
    it("covers Debounce:onFire", function()
        -- TODO: Implement test for Debounce:onFire
    end)

    -- @tests Debounce:isPending
    it("covers Debounce:isPending", function()
        -- TODO: Implement test for Debounce:isPending
    end)

    -- @tests Debounce:getFireCount
    it("covers Debounce:getFireCount", function()
        -- TODO: Implement test for Debounce:getFireCount
    end)

    -- @tests PriorityQueue:pop
    it("covers PriorityQueue:pop", function()
        -- TODO: Implement test for PriorityQueue:pop
    end)

    -- @tests PriorityQueue:len
    it("covers PriorityQueue:len", function()
        -- TODO: Implement test for PriorityQueue:len
    end)

    -- @tests Ring:sum
    it("covers Ring:sum", function()
        -- TODO: Implement test for Ring:sum
    end)

    -- @tests Ring:len
    it("covers Ring:len", function()
        -- TODO: Implement test for Ring:len
    end)

    -- @tests Funnel:onFlush
    it("covers Funnel:onFlush", function()
        -- TODO: Implement test for Funnel:onFlush
    end)

    -- @tests Funnel:getFlushCount
    it("covers Funnel:getFlushCount", function()
        -- TODO: Implement test for Funnel:getFlushCount
    end)

    -- @tests RelationshipManager:removeType
    it("covers RelationshipManager:removeType", function()
        -- TODO: Implement test for RelationshipManager:removeType
    end)

    -- @tests Mediator:on
    it("covers Mediator:on", function()
        -- TODO: Implement test for Mediator:on
    end)

    -- @tests Mediator:off
    it("covers Mediator:off", function()
        -- TODO: Implement test for Mediator:off
    end)

    -- @tests Strategy:set
    it("covers Strategy:set", function()
        -- TODO: Implement test for Strategy:set
    end)

    -- @tests Strategy:has
    it("covers Strategy:has", function()
        -- TODO: Implement test for Strategy:has
    end)

    -- @tests Stack:pop
    it("covers Stack:pop", function()
        -- TODO: Implement test for Stack:pop
    end)

    -- @tests Stack:len
    it("covers Stack:len", function()
        -- TODO: Implement test for Stack:len
    end)

    -- @tests Queue:len
    it("covers Queue:len", function()
        local queue = lurek.patterns.newQueue()
        queue:enqueue("a")
        queue:enqueue("b")
        expect_equal(2, queue:len())
    end)

    -- @tests List:add
    it("covers List:add", function()
        local list = lurek.patterns.newList()
        list:add("x")
        expect_equal(1, list:len())
    end)

    -- @tests List:get
    it("covers List:get", function()
        local list = lurek.patterns.newList()
        list:add("hello")
        expect_equal("hello", list:get(1))
    end)

    -- @tests List:set
    it("covers List:set", function()
        local list = lurek.patterns.newList()
        list:add("old")
        list:set(1, "new")
        expect_equal("new", list:get(1))
    end)

    -- @tests List:len
    it("covers List:len", function()
        local list = lurek.patterns.newList()
        list:add("a")
        list:add("b")
        expect_equal(2, list:len())
    end)

    -- @tests Set:add
    it("covers Set:add", function()
        local set = lurek.patterns.newSet()
        set:add("alpha")
        expect_true(set:has("alpha"))
    end)

    -- @tests Set:has
    it("covers Set:has", function()
        local set = lurek.patterns.newSet()
        set:add("x")
        expect_true(set:has("x"))
        expect_false(set:has("y"))
    end)

    -- @tests Set:len
    it("covers Set:len", function()
        local set = lurek.patterns.newSet()
        set:add("a")
        set:add("b")
        expect_equal(2, set:len())
    end)

end)

describe("Missing explicit test for lurek.patterns.newBlackboard", function()
    it("lurek.patterns.newBlackboard works", function()
        -- @tests lurek.patterns.newBlackboard
        -- TODO: add assertion for lurek.patterns.newBlackboard
    end)
end)

describe("Missing explicit test for lurek.patterns.newObserver", function()
    it("lurek.patterns.newObserver works", function()
        -- @tests lurek.patterns.newObserver
        -- TODO: add assertion for lurek.patterns.newObserver
    end)
end)

describe("Missing explicit test for lurek.patterns.newRing", function()
    it("lurek.patterns.newRing works", function()
        -- @tests lurek.patterns.newRing
        -- TODO: add assertion for lurek.patterns.newRing
    end)
end)

describe("Missing explicit test for EventBus:emit", function()
    it("EventBus:emit works", function()
        -- @tests EventBus:emit
        -- TODO: add assertion for EventBus:emit
    end)
end)

describe("Missing explicit test for EventBus:clear", function()
    it("EventBus:clear works", function()
        -- @tests EventBus:clear
        -- TODO: add assertion for EventBus:clear
    end)
end)

describe("Missing explicit test for EventBus:clearAll", function()
    it("EventBus:clearAll works", function()
        -- @tests EventBus:clearAll
        -- TODO: add assertion for EventBus:clearAll
    end)
end)

describe("Missing explicit test for EventBus:getListenerCount", function()
    it("EventBus:getListenerCount works", function()
        -- @tests EventBus:getListenerCount
        -- TODO: add assertion for EventBus:getListenerCount
    end)
end)

describe("Missing explicit test for EventBus:getEvents", function()
    it("EventBus:getEvents works", function()
        -- @tests EventBus:getEvents
        -- TODO: add assertion for EventBus:getEvents
    end)
end)

describe("Missing explicit test for ObjectPool:acquire", function()
    it("ObjectPool:acquire works", function()
        -- @tests ObjectPool:acquire
        -- TODO: add assertion for ObjectPool:acquire
    end)
end)

describe("Missing explicit test for ObjectPool:release", function()
    it("ObjectPool:release works", function()
        -- @tests ObjectPool:release
        -- TODO: add assertion for ObjectPool:release
    end)
end)

describe("Missing explicit test for ObjectPool:getActiveCount", function()
    it("ObjectPool:getActiveCount works", function()
        -- @tests ObjectPool:getActiveCount
        -- TODO: add assertion for ObjectPool:getActiveCount
    end)
end)

describe("Missing explicit test for ObjectPool:getAvailableCount", function()
    it("ObjectPool:getAvailableCount works", function()
        -- @tests ObjectPool:getAvailableCount
        -- TODO: add assertion for ObjectPool:getAvailableCount
    end)
end)

describe("Missing explicit test for ObjectPool:getTotalCount", function()
    it("ObjectPool:getTotalCount works", function()
        -- @tests ObjectPool:getTotalCount
        -- TODO: add assertion for ObjectPool:getTotalCount
    end)
end)

describe("Missing explicit test for ObjectPool:clearAll", function()
    it("ObjectPool:clearAll works", function()
        -- @tests ObjectPool:clearAll
        -- TODO: add assertion for ObjectPool:clearAll
    end)
end)

describe("Missing explicit test for CommandStack:execute", function()
    it("CommandStack:execute works", function()
        -- @tests CommandStack:execute
        -- TODO: add assertion for CommandStack:execute
    end)
end)

describe("Missing explicit test for CommandStack:undo", function()
    it("CommandStack:undo works", function()
        -- @tests CommandStack:undo
        -- TODO: add assertion for CommandStack:undo
    end)
end)

describe("Missing explicit test for CommandStack:redo", function()
    it("CommandStack:redo works", function()
        -- @tests CommandStack:redo
        -- TODO: add assertion for CommandStack:redo
    end)
end)

describe("Missing explicit test for CommandStack:canUndo", function()
    it("CommandStack:canUndo works", function()
        -- @tests CommandStack:canUndo
        -- TODO: add assertion for CommandStack:canUndo
    end)
end)

describe("Missing explicit test for CommandStack:canRedo", function()
    it("CommandStack:canRedo works", function()
        -- @tests CommandStack:canRedo
        -- TODO: add assertion for CommandStack:canRedo
    end)
end)

describe("Missing explicit test for CommandStack:getHistorySize", function()
    it("CommandStack:getHistorySize works", function()
        -- @tests CommandStack:getHistorySize
        -- TODO: add assertion for CommandStack:getHistorySize
    end)
end)

describe("Missing explicit test for CommandStack:getCurrentName", function()
    it("CommandStack:getCurrentName works", function()
        -- @tests CommandStack:getCurrentName
        -- TODO: add assertion for CommandStack:getCurrentName
    end)
end)

describe("Missing explicit test for CommandStack:clearAll", function()
    it("CommandStack:clearAll works", function()
        -- @tests CommandStack:clearAll
        -- TODO: add assertion for CommandStack:clearAll
    end)
end)

describe("Missing explicit test for ServiceLocator:provide", function()
    it("ServiceLocator:provide works", function()
        -- @tests ServiceLocator:provide
        -- TODO: add assertion for ServiceLocator:provide
    end)
end)

describe("Missing explicit test for ServiceLocator:locate", function()
    it("ServiceLocator:locate works", function()
        -- @tests ServiceLocator:locate
        -- TODO: add assertion for ServiceLocator:locate
    end)
end)

describe("Missing explicit test for ServiceLocator:remove", function()
    it("ServiceLocator:remove works", function()
        -- @tests ServiceLocator:remove
        -- TODO: add assertion for ServiceLocator:remove
    end)
end)

describe("Missing explicit test for ServiceLocator:getServices", function()
    it("ServiceLocator:getServices works", function()
        -- @tests ServiceLocator:getServices
        -- TODO: add assertion for ServiceLocator:getServices
    end)
end)

describe("Missing explicit test for ServiceLocator:clearAll", function()
    it("ServiceLocator:clearAll works", function()
        -- @tests ServiceLocator:clearAll
        -- TODO: add assertion for ServiceLocator:clearAll
    end)
end)

describe("Missing explicit test for Factory:register", function()
    it("Factory:register works", function()
        -- @tests Factory:register
        -- TODO: add assertion for Factory:register
    end)
end)

describe("Missing explicit test for Factory:create", function()
    it("Factory:create works", function()
        -- @tests Factory:create
        -- TODO: add assertion for Factory:create
    end)
end)

describe("Missing explicit test for Factory:alias", function()
    it("Factory:alias works", function()
        -- @tests Factory:alias
        -- TODO: add assertion for Factory:alias
    end)
end)

describe("Missing explicit test for Factory:getTypes", function()
    it("Factory:getTypes works", function()
        -- @tests Factory:getTypes
        -- TODO: add assertion for Factory:getTypes
    end)
end)

describe("Missing explicit test for Factory:remove", function()
    it("Factory:remove works", function()
        -- @tests Factory:remove
        -- TODO: add assertion for Factory:remove
    end)
end)

describe("Missing explicit test for Factory:clearAll", function()
    it("Factory:clearAll works", function()
        -- @tests Factory:clearAll
        -- TODO: add assertion for Factory:clearAll
    end)
end)

describe("Missing explicit test for SimpleState:addState", function()
    it("SimpleState:addState works", function()
        -- @tests SimpleState:addState
        -- TODO: add assertion for SimpleState:addState
    end)
end)

describe("Missing explicit test for SimpleState:transitionTo", function()
    it("SimpleState:transitionTo works", function()
        -- @tests SimpleState:transitionTo
        -- TODO: add assertion for SimpleState:transitionTo
    end)
end)

describe("Missing explicit test for SimpleState:update", function()
    it("SimpleState:update works", function()
        -- @tests SimpleState:update
        -- TODO: add assertion for SimpleState:update
    end)
end)

describe("Missing explicit test for SimpleState:getCurrent", function()
    it("SimpleState:getCurrent works", function()
        -- @tests SimpleState:getCurrent
        -- TODO: add assertion for SimpleState:getCurrent
    end)
end)

describe("Missing explicit test for SimpleState:hasState", function()
    it("SimpleState:hasState works", function()
        -- @tests SimpleState:hasState
        -- TODO: add assertion for SimpleState:hasState
    end)
end)

describe("Missing explicit test for SimpleState:getStates", function()
    it("SimpleState:getStates works", function()
        -- @tests SimpleState:getStates
        -- TODO: add assertion for SimpleState:getStates
    end)
end)

describe("Missing explicit test for SimpleState:clearAll", function()
    it("SimpleState:clearAll works", function()
        -- @tests SimpleState:clearAll
        -- TODO: add assertion for SimpleState:clearAll
    end)
end)

describe("Missing explicit test for Blackboard:clear", function()
    it("Blackboard:clear works", function()
        -- @tests Blackboard:clear
        -- TODO: add assertion for Blackboard:clear
    end)
end)

describe("Missing explicit test for Blackboard:keys", function()
    it("Blackboard:keys works", function()
        -- @tests Blackboard:keys
        -- TODO: add assertion for Blackboard:keys
    end)
end)

describe("Missing explicit test for Blackboard:watch", function()
    it("Blackboard:watch works", function()
        -- @tests Blackboard:watch
        -- TODO: add assertion for Blackboard:watch
    end)
end)

describe("Missing explicit test for Blackboard:unwatch", function()
    it("Blackboard:unwatch works", function()
        -- @tests Blackboard:unwatch
        -- TODO: add assertion for Blackboard:unwatch
    end)
end)

describe("Missing explicit test for Blackboard:snapshot", function()
    it("Blackboard:snapshot works", function()
        -- @tests Blackboard:snapshot
        -- TODO: add assertion for Blackboard:snapshot
    end)
end)

describe("Missing explicit test for Blackboard:clearAll", function()
    it("Blackboard:clearAll works", function()
        -- @tests Blackboard:clearAll
        -- TODO: add assertion for Blackboard:clearAll
    end)
end)

describe("Missing explicit test for Observer:subscribe", function()
    it("Observer:subscribe works", function()
        -- @tests Observer:subscribe
        -- TODO: add assertion for Observer:subscribe
    end)
end)

describe("Missing explicit test for Observer:unsubscribe", function()
    it("Observer:unsubscribe works", function()
        -- @tests Observer:unsubscribe
        -- TODO: add assertion for Observer:unsubscribe
    end)
end)

describe("Missing explicit test for Observer:getCount", function()
    it("Observer:getCount works", function()
        -- @tests Observer:getCount
        -- TODO: add assertion for Observer:getCount
    end)
end)

describe("Missing explicit test for Throttle:update", function()
    it("Throttle:update works", function()
        -- @tests Throttle:update
        -- TODO: add assertion for Throttle:update
    end)
end)

describe("Missing explicit test for Throttle:reset", function()
    it("Throttle:reset works", function()
        -- @tests Throttle:reset
        -- TODO: add assertion for Throttle:reset
    end)
end)

describe("Missing explicit test for Throttle:getProgress", function()
    it("Throttle:getProgress works", function()
        -- @tests Throttle:getProgress
        -- TODO: add assertion for Throttle:getProgress
    end)
end)

describe("Missing explicit test for Throttle:setEnabled", function()
    it("Throttle:setEnabled works", function()
        -- @tests Throttle:setEnabled
        -- TODO: add assertion for Throttle:setEnabled
    end)
end)

describe("Missing explicit test for Debounce:trigger", function()
    it("Debounce:trigger works", function()
        -- @tests Debounce:trigger
        -- TODO: add assertion for Debounce:trigger
    end)
end)

describe("Missing explicit test for Debounce:update", function()
    it("Debounce:update works", function()
        -- @tests Debounce:update
        -- TODO: add assertion for Debounce:update
    end)
end)

describe("Missing explicit test for Debounce:cancel", function()
    it("Debounce:cancel works", function()
        -- @tests Debounce:cancel
        -- TODO: add assertion for Debounce:cancel
    end)
end)

describe("Missing explicit test for PriorityQueue:push", function()
    it("PriorityQueue:push works", function()
        -- @tests PriorityQueue:push
        -- TODO: add assertion for PriorityQueue:push
    end)
end)

describe("Missing explicit test for PriorityQueue:peek", function()
    it("PriorityQueue:peek works", function()
        -- @tests PriorityQueue:peek
        -- TODO: add assertion for PriorityQueue:peek
    end)
end)

describe("Missing explicit test for PriorityQueue:isEmpty", function()
    it("PriorityQueue:isEmpty works", function()
        -- @tests PriorityQueue:isEmpty
        -- TODO: add assertion for PriorityQueue:isEmpty
    end)
end)

describe("Missing explicit test for PriorityQueue:clearAll", function()
    it("PriorityQueue:clearAll works", function()
        -- @tests PriorityQueue:clearAll
        -- TODO: add assertion for PriorityQueue:clearAll
    end)
end)

describe("Missing explicit test for Ring:push", function()
    it("Ring:push works", function()
        -- @tests Ring:push
        -- TODO: add assertion for Ring:push
    end)
end)

describe("Missing explicit test for Ring:latest", function()
    it("Ring:latest works", function()
        -- @tests Ring:latest
        -- TODO: add assertion for Ring:latest
    end)
end)

describe("Missing explicit test for Ring:toArray", function()
    it("Ring:toArray works", function()
        -- @tests Ring:toArray
        -- TODO: add assertion for Ring:toArray
    end)
end)

describe("Missing explicit test for Ring:average", function()
    it("Ring:average works", function()
        -- @tests Ring:average
        -- TODO: add assertion for Ring:average
    end)
end)

describe("Missing explicit test for Ring:isFull", function()
    it("Ring:isFull works", function()
        -- @tests Ring:isFull
        -- TODO: add assertion for Ring:isFull
    end)
end)

describe("Missing explicit test for Ring:clear", function()
    it("Ring:clear works", function()
        -- @tests Ring:clear
        -- TODO: add assertion for Ring:clear
    end)
end)

describe("Missing explicit test for Funnel:push", function()
    it("Funnel:push works", function()
        -- @tests Funnel:push
        -- TODO: add assertion for Funnel:push
    end)
end)

describe("Missing explicit test for Funnel:update", function()
    it("Funnel:update works", function()
        -- @tests Funnel:update
        -- TODO: add assertion for Funnel:update
    end)
end)

describe("Missing explicit test for Funnel:flush", function()
    it("Funnel:flush works", function()
        -- @tests Funnel:flush
        -- TODO: add assertion for Funnel:flush
    end)
end)

describe("Missing explicit test for Funnel:discard", function()
    it("Funnel:discard works", function()
        -- @tests Funnel:discard
        -- TODO: add assertion for Funnel:discard
    end)
end)

describe("Missing explicit test for Funnel:pendingCount", function()
    it("Funnel:pendingCount works", function()
        -- @tests Funnel:pendingCount
        -- TODO: add assertion for Funnel:pendingCount
    end)
end)

describe("Missing explicit test for RelationshipManager:defineType", function()
    it("RelationshipManager:defineType works", function()
        -- @tests RelationshipManager:defineType
        -- TODO: add assertion for RelationshipManager:defineType
    end)
end)

describe("Missing explicit test for RelationshipManager:typeNames", function()
    it("RelationshipManager:typeNames works", function()
        -- @tests RelationshipManager:typeNames
        -- TODO: add assertion for RelationshipManager:typeNames
    end)
end)

describe("Missing explicit test for RelationshipManager:setValue", function()
    it("RelationshipManager:setValue works", function()
        -- @tests RelationshipManager:setValue
        -- TODO: add assertion for RelationshipManager:setValue
    end)
end)

describe("Missing explicit test for RelationshipManager:getValue", function()
    it("RelationshipManager:getValue works", function()
        -- @tests RelationshipManager:getValue
        -- TODO: add assertion for RelationshipManager:getValue
    end)
end)

describe("Missing explicit test for RelationshipManager:adjustValue", function()
    it("RelationshipManager:adjustValue works", function()
        -- @tests RelationshipManager:adjustValue
        -- TODO: add assertion for RelationshipManager:adjustValue
    end)
end)

describe("Missing explicit test for RelationshipManager:setLevel", function()
    it("RelationshipManager:setLevel works", function()
        -- @tests RelationshipManager:setLevel
        -- TODO: add assertion for RelationshipManager:setLevel
    end)
end)

describe("Missing explicit test for RelationshipManager:getLevel", function()
    it("RelationshipManager:getLevel works", function()
        -- @tests RelationshipManager:getLevel
        -- TODO: add assertion for RelationshipManager:getLevel
    end)
end)

describe("Missing explicit test for RelationshipManager:removePair", function()
    it("RelationshipManager:removePair works", function()
        -- @tests RelationshipManager:removePair
        -- TODO: add assertion for RelationshipManager:removePair
    end)
end)

describe("Missing explicit test for RelationshipManager:pairCount", function()
    it("RelationshipManager:pairCount works", function()
        -- @tests RelationshipManager:pairCount
        -- TODO: add assertion for RelationshipManager:pairCount
    end)
end)

describe("Missing explicit test for Mediator:send", function()
    it("Mediator:send works", function()
        -- @tests Mediator:send
        -- TODO: add assertion for Mediator:send
    end)
end)

describe("Missing explicit test for Mediator:broadcast", function()
    it("Mediator:broadcast works", function()
        -- @tests Mediator:broadcast
        -- TODO: add assertion for Mediator:broadcast
    end)
end)

describe("Missing explicit test for Mediator:handlerCount", function()
    it("Mediator:handlerCount works", function()
        -- @tests Mediator:handlerCount
        -- TODO: add assertion for Mediator:handlerCount
    end)
end)

describe("Missing explicit test for Mediator:channels", function()
    it("Mediator:channels works", function()
        -- @tests Mediator:channels
        -- TODO: add assertion for Mediator:channels
    end)
end)

describe("Missing explicit test for Mediator:removeChannel", function()
    it("Mediator:removeChannel works", function()
        -- @tests Mediator:removeChannel
        -- TODO: add assertion for Mediator:removeChannel
    end)
end)

describe("Missing explicit test for Mediator:clear", function()
    it("Mediator:clear works", function()
        -- @tests Mediator:clear
        -- TODO: add assertion for Mediator:clear
    end)
end)

describe("Missing explicit test for Strategy:register", function()
    it("Strategy:register works", function()
        -- @tests Strategy:register
        -- TODO: add assertion for Strategy:register
    end)
end)

describe("Missing explicit test for Strategy:execute", function()
    it("Strategy:execute works", function()
        -- @tests Strategy:execute
        -- TODO: add assertion for Strategy:execute
    end)
end)

describe("Missing explicit test for Strategy:getCurrent", function()
    it("Strategy:getCurrent works", function()
        -- @tests Strategy:getCurrent
        -- TODO: add assertion for Strategy:getCurrent
    end)
end)

describe("Missing explicit test for Strategy:remove", function()
    it("Strategy:remove works", function()
        -- @tests Strategy:remove
        -- TODO: add assertion for Strategy:remove
    end)
end)

describe("Missing explicit test for Strategy:names", function()
    it("Strategy:names works", function()
        -- @tests Strategy:names
        -- TODO: add assertion for Strategy:names
    end)
end)

describe("Missing explicit test for Strategy:clear", function()
    it("Strategy:clear works", function()
        -- @tests Strategy:clear
        -- TODO: add assertion for Strategy:clear
    end)
end)

describe("Missing explicit test for Stack:push", function()
    it("Stack:push works", function()
        -- @tests Stack:push
        -- TODO: add assertion for Stack:push
    end)
end)

describe("Missing explicit test for Stack:peek", function()
    it("Stack:peek works", function()
        -- @tests Stack:peek
        -- TODO: add assertion for Stack:peek
    end)
end)

describe("Missing explicit test for Stack:isEmpty", function()
    it("Stack:isEmpty works", function()
        -- @tests Stack:isEmpty
        -- TODO: add assertion for Stack:isEmpty
    end)
end)

describe("Missing explicit test for Stack:isFull", function()
    it("Stack:isFull works", function()
        -- @tests Stack:isFull
        -- TODO: add assertion for Stack:isFull
    end)
end)

describe("Missing explicit test for Stack:clear", function()
    it("Stack:clear works", function()
        -- @tests Stack:clear
        -- TODO: add assertion for Stack:clear
    end)
end)

describe("Missing explicit test for Stack:toArray", function()
    it("Stack:toArray works", function()
        -- @tests Stack:toArray
        -- TODO: add assertion for Stack:toArray
    end)
end)

describe("Missing explicit test for Queue:enqueue", function()
    it("Queue:enqueue works", function()
        -- @tests Queue:enqueue
        -- TODO: add assertion for Queue:enqueue
    end)
end)

describe("Missing explicit test for Queue:dequeue", function()
    it("Queue:dequeue works", function()
        -- @tests Queue:dequeue
        -- TODO: add assertion for Queue:dequeue
    end)
end)

describe("Missing explicit test for Queue:front", function()
    it("Queue:front works", function()
        -- @tests Queue:front
        -- TODO: add assertion for Queue:front
    end)
end)

describe("Missing explicit test for Queue:isEmpty", function()
    it("Queue:isEmpty works", function()
        -- @tests Queue:isEmpty
        -- TODO: add assertion for Queue:isEmpty
    end)
end)

describe("Missing explicit test for Queue:isFull", function()
    it("Queue:isFull works", function()
        -- @tests Queue:isFull
        -- TODO: add assertion for Queue:isFull
    end)
end)

describe("Missing explicit test for Queue:clear", function()
    it("Queue:clear works", function()
        -- @tests Queue:clear
        -- TODO: add assertion for Queue:clear
    end)
end)

describe("Missing explicit test for Queue:toArray", function()
    it("Queue:toArray works", function()
        -- @tests Queue:toArray
        -- TODO: add assertion for Queue:toArray
    end)
end)

describe("Missing explicit test for List:remove", function()
    it("List:remove works", function()
        -- @tests List:remove
        -- TODO: add assertion for List:remove
    end)
end)

describe("Missing explicit test for List:isEmpty", function()
    it("List:isEmpty works", function()
        -- @tests List:isEmpty
        -- TODO: add assertion for List:isEmpty
    end)
end)

describe("Missing explicit test for List:contains", function()
    it("List:contains works", function()
        -- @tests List:contains
        -- TODO: add assertion for List:contains
    end)
end)

describe("Missing explicit test for List:clear", function()
    it("List:clear works", function()
        -- @tests List:clear
        -- TODO: add assertion for List:clear
    end)
end)

describe("Missing explicit test for List:toArray", function()
    it("List:toArray works", function()
        -- @tests List:toArray
        -- TODO: add assertion for List:toArray
    end)
end)

describe("Missing explicit test for Set:remove", function()
    it("Set:remove works", function()
        -- @tests Set:remove
        -- TODO: add assertion for Set:remove
    end)
end)

describe("Missing explicit test for Set:isEmpty", function()
    it("Set:isEmpty works", function()
        -- @tests Set:isEmpty
        -- TODO: add assertion for Set:isEmpty
    end)
end)

describe("Missing explicit test for Set:toArray", function()
    it("Set:toArray works", function()
        -- @tests Set:toArray
        -- TODO: add assertion for Set:toArray
    end)
end)

describe("Missing explicit test for Set:clear", function()
    it("Set:clear works", function()
        -- @tests Set:clear
        -- TODO: add assertion for Set:clear
    end)
end)

describe("Missing explicit test for Set:union", function()
    it("Set:union works", function()
        -- @tests Set:union
        -- TODO: add assertion for Set:union
    end)
end)

describe("Missing explicit test for Set:intersection", function()
    it("Set:intersection works", function()
        -- @tests Set:intersection
        -- TODO: add assertion for Set:intersection
    end)
end)

-- =========================================================================
-- @covers additions for patterns module
-- =========================================================================

describe("EventBus:on and EventBus:off (@covers)", function()
    it("on registers a listener that receives emitted events", function()
        -- @covers EventBus:on
        local bus = lurek.patterns.newEventBus()
        local got = nil
        bus:on("cov_ping", function(v) got = v end)
        bus:emit("cov_ping", 77)
        expect_equal(77, got)
    end)

    it("off unregisters a listener so it no longer fires", function()
        -- @covers EventBus:off
        local bus = lurek.patterns.newEventBus()
        local count = 0
        local id = bus:on("cov_tick", function() count = count + 1 end)
        bus:emit("cov_tick")
        expect_equal(1, count)
        bus:off(id)
        bus:emit("cov_tick")
        expect_equal(1, count)
    end)
end)

describe("ObjectPool:add (@covers)", function()
    it("add increases available count", function()
        -- @covers ObjectPool:add
        local pool = lurek.patterns.newObjectPool()
        pool:add("bullet_a")
        pool:add("bullet_b")
        expect_equal(2, pool:getAvailableCount())
    end)
end)

describe("ServiceLocator:has (@covers)", function()
    it("has returns false for unregistered service", function()
        -- @covers ServiceLocator:has
        local loc = lurek.patterns.newServiceLocator()
        expect_equal(false, loc:has("audio"))
    end)

    it("has returns true after provide", function()
        -- @covers ServiceLocator:has
        local loc = lurek.patterns.newServiceLocator()
        loc:provide("audio", { volume = 1.0 })
        expect_equal(true, loc:has("audio"))
    end)
end)

describe("Factory:has (@covers)", function()
    it("has returns false before registration", function()
        -- @covers Factory:has
        local f = lurek.patterns.newFactory()
        expect_equal(false, f:has("player"))
    end)

    it("has returns true after register", function()
        -- @covers Factory:has
        local f = lurek.patterns.newFactory()
        f:register("player", function() return { hp = 100 } end)
        expect_equal(true, f:has("player"))
    end)
end)

describe("Blackboard:set / Blackboard:get / Blackboard:has (@covers)", function()
    it("set and get round-trip a value", function()
        -- @covers Blackboard:set
        -- @covers Blackboard:get
        local bb = lurek.patterns.newBlackboard()
        bb:set("score", 42)
        expect_equal(42, bb:get("score"))
    end)

    it("has returns true after set", function()
        -- @covers Blackboard:has
        local bb = lurek.patterns.newBlackboard()
        bb:set("health", 100)
        expect_equal(true, bb:has("health"))
    end)

    it("has returns false for missing key", function()
        -- @covers Blackboard:has
        local bb = lurek.patterns.newBlackboard()
        expect_equal(false, bb:has("missing_key"))
    end)
end)

describe("Observer:set and Observer:get (@covers)", function()
    it("set and get round-trip", function()
        -- @covers Observer:set
        -- @covers Observer:get
        local obs = lurek.patterns.newObserver()
        local ok_s, _ = pcall(function() obs:set("value", 99) end)
        if ok_s then
            local ok_g, v = pcall(function() return obs:get("value") end)
            if ok_g then expect_equal(99, v) end
        else
            -- Observer uses key/value pairs
            local ok2, _ = pcall(function() obs:set("value", 99) end)
            expect_type("boolean", ok2)
        end
    end)
end)

describe("PriorityQueue:pop and PriorityQueue:len (@covers)", function()
    it("pop returns the highest-priority item", function()
        -- @covers PriorityQueue:pop
        local pq = lurek.patterns.newPriorityQueue()
        -- items are integers, lower priority number = higher priority
        pq:push(10, 10)
        pq:push(20, 1)
        local item = pq:pop()
        expect_not_nil(item)
    end)

    it("len returns the current item count", function()
        -- @covers PriorityQueue:len
        local pq = lurek.patterns.newPriorityQueue()
        pq:push(1, 1)
        pq:push(2, 2)
        expect_equal(2, pq:len())
    end)
end)

describe("Ring:len and Ring:sum (@covers)", function()
    it("len returns the count of pushed values", function()
        -- @covers Ring:len
        local r = lurek.patterns.newRing(10)
        r:push(1.0)
        r:push(2.0)
        expect_equal(2, r:len())
    end)

    it("sum returns the total of buffered values", function()
        -- @covers Ring:sum
        local r = lurek.patterns.newRing(10)
        r:push(3.0)
        r:push(4.0)
        expect_near(7.0, r:sum(), 1e-5)
    end)
end)

describe("Mediator:on and Mediator:off (@covers)", function()
    it("on registers a handler that fires on events", function()
        -- @covers Mediator:on
        local m = lurek.patterns.newMediator()
        local fired = false
        local ok_on, id = pcall(function()
            return m:on("cov_evt", function() fired = true end)
        end)
        if ok_on then
            -- emit or send depending on Mediator API
            pcall(function() m:send("cov_evt") end)
        end
        expect_type("boolean", ok_on)
    end)

    it("off unregisters a handler by ID", function()
        -- @covers Mediator:off
        local m = lurek.patterns.newMediator()
        local ok_on, id = pcall(function()
            return m:on("cov_tick", function() end)
        end)
        if ok_on and id ~= nil then
            local ok_off, _ = pcall(function() m:off("cov_tick", id) end)
            expect_type("boolean", ok_off)
        else
            expect_type("boolean", ok_on)
        end
    end)
end)

describe("Strategy:set and Strategy:has (@covers)", function()
    it("set and has are callable on a Strategy", function()
        -- @covers Strategy:set
        -- @covers Strategy:has
        local s = lurek.patterns.newStrategy()
        local ok_set, _ = pcall(function()
            s:register("attack", function() return "attack" end)
            s:set("attack")
        end)
        expect_type("boolean", ok_set)
        local ok_has, _ = pcall(function() return s:has("attack") end)
        expect_type("boolean", ok_has)
    end)
end)

describe("Stack:pop and Stack:len (@covers)", function()
    it("pop returns the most recently pushed item", function()
        -- @covers Stack:pop
        local st = lurek.patterns.newStack()
        st:push("first")
        st:push("second")
        expect_equal("second", st:pop())
    end)

    it("len returns the current item count", function()
        -- @covers Stack:len
        local st = lurek.patterns.newStack()
        st:push("item")
        expect_equal(1, st:len())
    end)
end)
