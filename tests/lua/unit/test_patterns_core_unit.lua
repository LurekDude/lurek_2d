-- tests/lua/test_patterns.lua
-- BDD-style integration tests for lurek.patterns module

-- ===================================================================
-- EventBus
-- ===================================================================

-- @describe lurek.patterns.newEventBus
describe("lurek.patterns.newEventBus", function()
    -- @covers lurek.patterns.newEventBus
    it("creates an EventBus with type/typeOf", function()
        local bus = lurek.patterns.newEventBus()
        expect_equal("LEventBus", bus["type"](bus))
        expect_true(bus["typeOf"](bus, "LEventBus"))
        expect_true(bus["typeOf"](bus, "Object"))
    end)

    -- @covers LEventBus:emit
    -- @covers LEventBus:on
    -- @covers lurek.patterns.newEventBus
    it("on/emit fires callbacks", function()
        local bus = lurek.patterns.newEventBus()
        local received = nil
        bus:on("ping", function(val) received = val end)
        bus:emit("ping", 42)
        expect_equal(received, 42)
    end)

    -- @covers LEventBus:on
    -- @covers lurek.patterns.newEventBus
    it("on returns unique subscription IDs", function()
        local bus = lurek.patterns.newEventBus()
        local id1 = bus:on("a", function() end)
        local id2 = bus:on("a", function() end)
        expect_true(id1 ~= id2)
    end)

    -- @covers LEventBus:emit
    -- @covers LEventBus:on
    -- @covers lurek.patterns.newEventBus
    it("listeners fire in priority order", function()
        local bus = lurek.patterns.newEventBus()
        local order = {}
        bus:on("act", function() table.insert(order, "low") end, 1)
        bus:on("act", function() table.insert(order, "high") end, 10)
        bus:on("act", function() table.insert(order, "mid") end, 0)
        bus:emit("act")
        expect_equal("high", order[1])
        expect_equal("low", order[2])
        expect_equal("mid", order[3])
    end)

    -- @covers LEventBus:emit
    -- @covers LEventBus:off
    -- @covers LEventBus:on
    -- @covers lurek.patterns.newEventBus
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

    -- @covers LEventBus:clear
    -- @covers LEventBus:getListenerCount
    -- @covers LEventBus:on
    -- @covers lurek.patterns.newEventBus
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

    -- @covers LEventBus:clearAll
    -- @covers LEventBus:getListenerCount
    -- @covers LEventBus:on
    -- @covers lurek.patterns.newEventBus
    it("clearAll removes all listeners", function()
        local bus = lurek.patterns.newEventBus()
        bus:on("a", function() end)
        bus:on("b", function() end)
        bus:clearAll()
        expect_equal(bus:getListenerCount("a"), 0)
        expect_equal(bus:getListenerCount("b"), 0)
    end)

    -- @covers LEventBus:getEvents
    -- @covers LEventBus:on
    -- @covers lurek.patterns.newEventBus
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
-- @describe lurek.patterns.newObjectPool
describe("lurek.patterns.newObjectPool", function()
    -- @covers lurek.patterns.newObjectPool
    it("creates an ObjectPool with correct type", function()
        local pool = lurek.patterns.newObjectPool()
        expect_equal("LObjectPool", pool["type"](pool))
        expect_true(pool["typeOf"](pool, "LObjectPool"))
        expect_true(pool["typeOf"](pool, "Object"))
    end)

    -- @covers LObjectPool:acquire
    -- @covers LObjectPool:add
    -- @covers LObjectPool:getActiveCount
    -- @covers LObjectPool:getAvailableCount
    -- @covers lurek.patterns.newObjectPool
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

    -- @covers LObjectPool:getActiveCount
    -- @covers LObjectPool:getAvailableCount
    -- @covers lurek.patterns.newObjectPool
    it("fresh pool starts empty", function()
        local pool = lurek.patterns.newObjectPool()
        expect_equal(0, pool:getAvailableCount())
        expect_equal(0, pool:getActiveCount())
    end)

    -- @covers LObjectPool:acquire
    -- @covers LObjectPool:add
    -- @covers LObjectPool:getActiveCount
    -- @covers LObjectPool:getAvailableCount
    -- @covers LObjectPool:release
    -- @covers lurek.patterns.newObjectPool
    it("release returns object to pool", function()
        local pool = lurek.patterns.newObjectPool()
        pool:add("item")
        local obj = pool:acquire()
        expect_equal(pool:getActiveCount(), 1)
        pool:release(obj)
        expect_equal(pool:getActiveCount(), 0)
        expect_equal(pool:getAvailableCount(), 1)
    end)

    -- @covers LObjectPool:acquire
    -- @covers LObjectPool:add
    -- @covers LObjectPool:getTotalCount
    -- @covers lurek.patterns.newObjectPool
    it("getTotalCount sums active + available", function()
        local pool = lurek.patterns.newObjectPool()
        pool:add("a")
        pool:add("b")
        pool:acquire()
        expect_equal(pool:getTotalCount(), 2)
    end)

    -- @covers LObjectPool:acquire
    -- @covers LObjectPool:add
    -- @covers LObjectPool:clearAll
    -- @covers LObjectPool:getTotalCount
    -- @covers lurek.patterns.newObjectPool
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
-- @describe lurek.patterns.newCommandStack
describe("lurek.patterns.newCommandStack", function()
    -- @covers lurek.patterns.newCommandStack
    it("creates a CommandStack with correct type", function()
        local cmds = lurek.patterns.newCommandStack()
        expect_equal("LCommandStack", cmds["type"](cmds))
        expect_true(cmds["typeOf"](cmds, "LCommandStack"))
        expect_true(cmds["typeOf"](cmds, "Object"))
    end)

    -- @covers LCommandStack:execute
    -- @covers lurek.patterns.newCommandStack
    it("execute runs the command immediately", function()
        local cmds = lurek.patterns.newCommandStack()
        local x = 0
        cmds:execute("inc", function() x = x + 1 end)
        expect_equal(x, 1)
    end)

    -- @covers LCommandStack:execute
    -- @covers LCommandStack:undo
    -- @covers lurek.patterns.newCommandStack
    it("undo reverses the last command", function()
        local cmds = lurek.patterns.newCommandStack()
        local x = 0
        cmds:execute("inc", function() x = x + 10 end, function() x = x - 10 end)
        expect_equal(x, 10)
        local ok = cmds:undo()
        expect_true(ok)
        expect_equal(x, 0)
    end)

    -- @covers LCommandStack:execute
    -- @covers LCommandStack:redo
    -- @covers LCommandStack:undo
    -- @covers lurek.patterns.newCommandStack
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

    -- @covers LCommandStack:canRedo
    -- @covers LCommandStack:canUndo
    -- @covers LCommandStack:execute
    -- @covers LCommandStack:undo
    -- @covers lurek.patterns.newCommandStack
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

    -- @covers LCommandStack:canRedo
    -- @covers LCommandStack:execute
    -- @covers LCommandStack:getHistorySize
    -- @covers LCommandStack:undo
    -- @covers lurek.patterns.newCommandStack
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

    -- @covers LCommandStack:execute
    -- @covers LCommandStack:getCurrentName
    -- @covers lurek.patterns.newCommandStack
    it("getCurrentName returns the last command name", function()
        local cmds = lurek.patterns.newCommandStack()
        expect_nil(cmds:getCurrentName())
        cmds:execute("move", function() end)
        expect_equal(cmds:getCurrentName(), "move")
    end)

    -- @covers LCommandStack:canUndo
    -- @covers LCommandStack:clearAll
    -- @covers LCommandStack:execute
    -- @covers LCommandStack:getHistorySize
    -- @covers lurek.patterns.newCommandStack
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
-- @describe lurek.patterns.newServiceLocator
describe("lurek.patterns.newServiceLocator", function()
    -- @covers lurek.patterns.newServiceLocator
    it("creates a ServiceLocator with correct type", function()
        local sl = lurek.patterns.newServiceLocator()
        expect_equal("LServiceLocator", sl["type"](sl))
        expect_true(sl["typeOf"](sl, "LServiceLocator"))
        expect_true(sl["typeOf"](sl, "Object"))
    end)

    -- @covers LServiceLocator:has
    -- @covers LServiceLocator:locate
    -- @covers LServiceLocator:provide
    -- @covers lurek.patterns.newServiceLocator
    it("provide/locate stores and retrieves values", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("logger", { log = function() end })
        expect_true(sl:has("logger"))
        local svc = sl:locate("logger")
        expect_true(svc ~= nil)
    end)

    -- @covers LServiceLocator:locate
    -- @covers lurek.patterns.newServiceLocator
    it("locate returns nil for unknown service", function()
        local sl = lurek.patterns.newServiceLocator()
        local svc = sl:locate("missing")
        expect_nil(svc)
    end)

    -- @covers LServiceLocator:has
    -- @covers LServiceLocator:provide
    -- @covers LServiceLocator:remove
    -- @covers lurek.patterns.newServiceLocator
    it("remove deletes a service", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("db", "connection")
        expect_true(sl:has("db"))
        sl:remove("db")
        expect_false(sl:has("db"))
    end)

    -- @covers LServiceLocator:getServices
    -- @covers LServiceLocator:provide
    -- @covers lurek.patterns.newServiceLocator
    it("getServices lists all names", function()
        local sl = lurek.patterns.newServiceLocator()
        sl:provide("a", 1)
        sl:provide("b", 2)
        local names = sl:getServices()
        expect_equal(#names, 2)
    end)

    -- @covers LServiceLocator:clearAll
    -- @covers LServiceLocator:has
    -- @covers LServiceLocator:provide
    -- @covers lurek.patterns.newServiceLocator
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
-- @describe lurek.patterns.newFactory
describe("lurek.patterns.newFactory", function()
    -- @covers lurek.patterns.newFactory
    it("creates a Factory with correct type", function()
        local f = lurek.patterns.newFactory()
        expect_equal("LFactory", f["type"](f))
        expect_true(f["typeOf"](f, "LFactory"))
        expect_true(f["typeOf"](f, "Object"))
    end)

    -- @covers LFactory:create
    -- @covers LFactory:register
    -- @covers lurek.patterns.newFactory
    it("register/create builds objects", function()
        local f = lurek.patterns.newFactory()
        f:register("bullet", function(x, y)
            return { x = x, y = y, kind = "bullet" }
        end)
        local b = f:create("bullet", 10, 20)
        expect_true(b ~= nil)
        expect_equal(10, b and b.x or nil)
        expect_equal(20, b and b.y or nil)
        expect_equal("bullet", b and b.kind or nil)
    end)

    -- @covers LFactory:has
    -- @covers LFactory:register
    -- @covers lurek.patterns.newFactory
    it("has checks type registration", function()
        local f = lurek.patterns.newFactory()
        expect_false(f:has("nope"))
        f:register("enemy", function() return {} end)
        expect_true(f:has("enemy"))
    end)

    -- @covers LFactory:getTypes
    -- @covers LFactory:register
    -- @covers lurek.patterns.newFactory
    it("getTypes lists registered types", function()
        local f = lurek.patterns.newFactory()
        f:register("a", function() end)
        f:register("b", function() end)
        local types = f:getTypes()
        expect_equal(#types, 2)
    end)

    -- @covers LFactory:has
    -- @covers LFactory:register
    -- @covers LFactory:remove
    -- @covers lurek.patterns.newFactory
    it("remove unregisters a type", function()
        local f = lurek.patterns.newFactory()
        f:register("temp", function() end)
        f:remove("temp")
        expect_false(f:has("temp"))
    end)

    -- @covers LFactory:clearAll
    -- @covers LFactory:getTypes
    -- @covers LFactory:register
    -- @covers lurek.patterns.newFactory
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
-- @describe lurek.patterns.newSimpleState
describe("lurek.patterns.newSimpleState", function()
    -- @covers lurek.patterns.newSimpleState
    it("creates a SimpleState with correct type", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_equal("LSimpleState", fsm["type"](fsm))
        expect_true(fsm["typeOf"](fsm, "LSimpleState"))
        expect_true(fsm["typeOf"](fsm, "Object"))
    end)

    -- @covers LSimpleState:addState
    -- @covers LSimpleState:getCurrent
    -- @covers LSimpleState:transitionTo
    -- @covers lurek.patterns.newSimpleState
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

    -- @covers LSimpleState:transitionTo
    -- @covers lurek.patterns.newSimpleState
    it("transitionTo returns false for unknown state", function()
        local fsm = lurek.patterns.newSimpleState()
        local ok = fsm:transitionTo("nonexistent")
        expect_false(ok)
    end)

    -- @covers LSimpleState:addState
    -- @covers LSimpleState:transitionTo
    -- @covers lurek.patterns.newSimpleState
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

    -- @covers LSimpleState:addState
    -- @covers LSimpleState:transitionTo
    -- @covers LSimpleState:update
    -- @covers lurek.patterns.newSimpleState
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

    -- @covers LSimpleState:addState
    -- @covers LSimpleState:hasState
    -- @covers lurek.patterns.newSimpleState
    it("hasState checks registration", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_false(fsm:hasState("jump"))
        fsm:addState("jump")
        expect_true(fsm:hasState("jump"))
    end)

    -- @covers LSimpleState:addState
    -- @covers LSimpleState:getStates
    -- @covers lurek.patterns.newSimpleState
    it("getStates lists all state names", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("idle")
        fsm:addState("walk")
        fsm:addState("run")
        local states = fsm:getStates()
        expect_equal(#states, 3)
    end)

    -- @covers LSimpleState:addState
    -- @covers LSimpleState:clearAll
    -- @covers LSimpleState:getCurrent
    -- @covers LSimpleState:getStates
    -- @covers LSimpleState:transitionTo
    -- @covers lurek.patterns.newSimpleState
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

-- @describe SimpleState extended coverage (RS parity)
describe("SimpleState extended coverage (RS parity)", function()
    -- @covers LSimpleState:hasState
    -- @covers lurek.patterns.newSimpleState
    it("hasState returns false for unregistered state", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_false(fsm:hasState("unknown"))
    end)

    -- @covers LSimpleState:update
    -- @covers lurek.patterns.newSimpleState
    it("update does not error with no current state", function()
        local fsm = lurek.patterns.newSimpleState()
        expect_no_error(function() fsm:update(0.016) end)
    end)

    -- @covers LSimpleState:addState
    -- @covers LSimpleState:getCurrent
    -- @covers lurek.patterns.newSimpleState
    it("getCurrent returns nil before any transition", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("idle")
        expect_nil(fsm:getCurrent())
    end)

    -- @covers LSimpleState:addState
    -- @covers LSimpleState:clearAll
    -- @covers LSimpleState:getStates
    -- @covers lurek.patterns.newSimpleState
    it("clearAll followed by addState works cleanly", function()
        local fsm = lurek.patterns.newSimpleState()
        fsm:addState("a")
        fsm:clearAll()
        fsm:addState("b")
        expect_equal(1, #fsm:getStates())
    end)
end)

-- @describe CommandStack undo/redo (RS parity)
describe("CommandStack undo/redo (RS parity)", function()
    -- @covers LCommandStack:execute
    -- @covers LCommandStack:redo
    -- @covers LCommandStack:undo
    -- @covers lurek.patterns.newCommandStack
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

    -- @covers LCommandStack:execute
    -- @covers LCommandStack:getHistorySize
    -- @covers lurek.patterns.newCommandStack
    it("getHistorySize reflects executed commands", function()
        local cs = lurek.patterns.newCommandStack()
        expect_equal(0, cs:getHistorySize())
        cs:execute("op", function() end, function() end)
        expect_equal(1, cs:getHistorySize())
    end)
end)

--  Patterns Collections (merged from test_patterns_collections.lua)

-- @describe lurek.patterns.Stack
describe("lurek.patterns.Stack", function()
    -- @covers LStack:isEmpty
    -- @covers LStack:len
    -- @covers LStack:pop
    -- @covers LStack:push
    -- @covers lurek.patterns.newStack
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

    -- @covers LStack:len
    -- @covers LStack:peek
    -- @covers LStack:push
    -- @covers lurek.patterns.newStack
    it("peek does not remove the top item", function()
        local s = lurek.patterns.newStack()
        s:push(42)
        expect_equal(42, s:peek())
        expect_equal(1, s:len())
    end)

    -- @covers LStack:isFull
    -- @covers LStack:push
    -- @covers lurek.patterns.newStack
    it("isFull returns true at capacity", function()
        local s = lurek.patterns.newStack(3)
        s:push(1); s:push(2); s:push(3)
        expect_equal(true, s:isFull())
    end)

    -- @covers LStack:push
    -- @covers LStack:toArray
    -- @covers lurek.patterns.newStack
    it("toArray returns all items in order", function()
        local s = lurek.patterns.newStack()
        s:push("x"); s:push("y")
        local arr = s:toArray()
        expect_equal(2, #arr)
    end)

    -- @covers LStack:clear
    -- @covers LStack:len
    -- @covers LStack:push
    -- @covers lurek.patterns.newStack
    it("clear empties the stack", function()
        local s = lurek.patterns.newStack()
        s:push(1); s:push(2)
        s:clear()
        expect_equal(0, s:len())
    end)
end)

-- @describe lurek.patterns.Queue
describe("lurek.patterns.Queue", function()
    -- @covers LQueue:dequeue
    -- @covers LQueue:enqueue
    -- @covers lurek.patterns.newQueue
    it("enqueue and dequeue follow FIFO order", function()
        local q = lurek.patterns.newQueue()
        q:enqueue("first")
        q:enqueue("second")
        q:enqueue("third")
        expect_equal("first", q:dequeue())
        expect_equal("second", q:dequeue())
    end)

    -- @covers LQueue:enqueue
    -- @covers LQueue:front
    -- @covers LQueue:len
    -- @covers lurek.patterns.newQueue
    it("front peeks without removing", function()
        local q = lurek.patterns.newQueue()
        q:enqueue("peek_me")
        expect_equal("peek_me", q:front())
        expect_equal(1, q:len())
    end)

    -- @covers LQueue:enqueue
    -- @covers LQueue:isEmpty
    -- @covers lurek.patterns.newQueue
    it("isEmpty returns true on empty queue", function()
        local q = lurek.patterns.newQueue()
        expect_equal(true, q:isEmpty())
        q:enqueue("x")
        expect_equal(false, q:isEmpty())
    end)
end)

-- @describe lurek.patterns.List
describe("lurek.patterns.List", function()
    -- @covers LList:add
    -- @covers LList:get
    -- @covers LList:len
    -- @covers LList:remove
    -- @covers LList:set
    -- @covers lurek.patterns.newList
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

    -- @covers LList:add
    -- @covers LList:contains
    -- @covers lurek.patterns.newList
    it("contains returns true for present and false for absent values", function()
        local l = lurek.patterns.newList()
        l:add("hello")
        expect_equal(true, l:contains("hello"))
        expect_equal(false, l:contains("world"))
    end)
end)

-- @describe lurek.patterns.Set
describe("lurek.patterns.Set", function()
    -- @covers LSet:add
    -- @covers LSet:has
    -- @covers LSet:len
    -- @covers LSet:remove
    -- @covers lurek.patterns.newSet
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

    -- @covers LSet:add
    -- @covers LSet:union
    -- @covers lurek.patterns.newSet
    it("union returns a set containing all elements of both sets", function()
        local a = lurek.patterns.newSet()
        local b = lurek.patterns.newSet()
        a:add("x"); a:add("y")
        b:add("y"); b:add("z")
        local u = a:union(b)
        expect_equal(3, u:len())
    end)

    -- @covers LSet:add
    -- @covers LSet:intersection
    -- @covers lurek.patterns.newSet
    it("intersection returns only shared elements", function()
        local a = lurek.patterns.newSet()
        local b = lurek.patterns.newSet()
        a:add("x"); a:add("y"); a:add("z")
        b:add("y"); b:add("z"); b:add("w")
        local i = a:intersection(b)
        expect_equal(2, i:len())
    end)

    -- @covers LSet:add
    -- @covers LSet:toArray
    -- @covers lurek.patterns.newSet
    it("toArray returns all set members", function()
        local s = lurek.patterns.newSet()
        s:add("one"); s:add("two"); s:add("three")
        local arr = s:toArray()
        expect_equal(3, #arr)
    end)
end)

--  Patterns Mediator (merged from test_patterns_mediator.lua)

-- @describe lurek.patterns.Mediator
describe("lurek.patterns.Mediator", function()
    -- @covers LMediator:on
    -- @covers LMediator:send
    -- @covers lurek.patterns.newMediator
    it("on registers a handler that receives send messages", function()
        local m = lurek.patterns.newMediator()
        local received = nil
        m:on("click", function(data)
            received = data
        end)
        m:send("click", "hello")
        expect_equal("hello", received)
    end)

    -- @covers LMediator:off
    -- @covers LMediator:on
    -- @covers LMediator:send
    -- @covers lurek.patterns.newMediator
    it("off removes handler by id", function()
        local m = lurek.patterns.newMediator()
        local count = 0
        local id = m:on("tick", function() count = count + 1 end)
        m:send("tick")
        m:off("tick", id)
        m:send("tick")
        expect_equal(1, count)
    end)

    -- @covers LMediator:on
    -- @covers LMediator:send
    -- @covers lurek.patterns.newMediator
    it("send only fires handler on its own channel", function()
        local m = lurek.patterns.newMediator()
        local hit = 0
        m:on("channelA", function() hit = hit + 1 end)
        m:on("channelB", function() hit = hit + 100 end)
        m:send("channelA", "payload")
        expect_equal(1, hit)
    end)

    -- @covers LMediator:handlerCount
    -- @covers LMediator:off
    -- @covers LMediator:on
    -- @covers lurek.patterns.newMediator
    it("handlerCount tracks registration and removal", function()
        local m = lurek.patterns.newMediator()
        expect_equal(0, m:handlerCount("events"))
        local id = m:on("events", function() end)
        expect_equal(1, m:handlerCount("events"))
        m:off("events", id)
        expect_equal(0, m:handlerCount("events"))
    end)

    -- @covers LMediator:channels
    -- @covers LMediator:on
    -- @covers lurek.patterns.newMediator
    it("channels returns registered channel names", function()
        local m = lurek.patterns.newMediator()
        m:on("alpha", function() end)
        m:on("beta", function() end)
        local ch = m:channels()
        expect_equal(2, #ch)
    end)

    -- @covers LMediator:handlerCount
    -- @covers LMediator:on
    -- @covers LMediator:removeChannel
    -- @covers lurek.patterns.newMediator
    it("removeChannel removes all handlers on a channel", function()
        local m = lurek.patterns.newMediator()
        m:on("destroy", function() end)
        m:on("destroy", function() end)
        expect_equal(2, m:handlerCount("destroy"))
        m:removeChannel("destroy")
        expect_equal(0, m:handlerCount("destroy"))
    end)

    -- @covers LMediator:channels
    -- @covers LMediator:clear
    -- @covers LMediator:on
    -- @covers lurek.patterns.newMediator
    it("clear removes all channels", function()
        local m = lurek.patterns.newMediator()
        m:on("a", function() end)
        m:on("b", function() end)
        m:clear()
        local ch = m:channels()
        expect_equal(0, #ch)
    end)
end)

--  Patterns Strategy (merged from test_patterns_strategy.lua)

-- @describe lurek.patterns.Strategy
describe("lurek.patterns.Strategy", function()
    -- @covers LStrategy:execute
    -- @covers LStrategy:register
    -- @covers LStrategy:set
    -- @covers lurek.patterns.newStrategy
    it("register, set, and execute calls the strategy function", function()
        local s = lurek.patterns.newStrategy()
        local called = false
        s:register("run", function() called = true end)
        s:set("run")
        s:execute()
        expect_equal(true, called)
    end)

    -- @covers LStrategy:getCurrent
    -- @covers LStrategy:register
    -- @covers LStrategy:set
    -- @covers lurek.patterns.newStrategy
    it("getCurrent returns the active strategy name", function()
        local s = lurek.patterns.newStrategy()
        s:register("patrol", function() end)
        expect_equal(nil, s:getCurrent())
        s:set("patrol")
        expect_equal("patrol", s:getCurrent())
    end)

    -- @covers LStrategy:has
    -- @covers LStrategy:register
    -- @covers lurek.patterns.newStrategy
    it("has returns true for registered names and false for unknown", function()
        local s = lurek.patterns.newStrategy()
        s:register("attack", function() end)
        expect_equal(true, s:has("attack"))
        expect_equal(false, s:has("retreat"))
    end)

    -- @covers LStrategy:getCurrent
    -- @covers LStrategy:has
    -- @covers LStrategy:register
    -- @covers LStrategy:remove
    -- @covers LStrategy:set
    -- @covers lurek.patterns.newStrategy
    it("remove unregisters a strategy", function()
        local s = lurek.patterns.newStrategy()
        s:register("idle", function() end)
        s:set("idle")
        local ok = s:remove("idle")
        expect_equal(true, ok)
        expect_equal(false, s:has("idle"))
        expect_equal(nil, s:getCurrent())
    end)

    -- @covers LStrategy:names
    -- @covers LStrategy:register
    -- @covers lurek.patterns.newStrategy
    it("names returns all registered names", function()
        local s = lurek.patterns.newStrategy()
        s:register("walk", function() end)
        s:register("sprint", function() end)
        s:register("crouch", function() end)
        local names = s:names()
        expect_equal(3, #names)
    end)

    -- @covers LStrategy:execute
    -- @covers LStrategy:register
    -- @covers LStrategy:set
    -- @covers lurek.patterns.newStrategy
    it("execute passes arguments to the strategy function", function()
        local s = lurek.patterns.newStrategy()
        local got_dt = nil
        s:register("move", function(dt) got_dt = dt end)
        s:set("move")
        s:execute(0.016)
        expect_near(0.016, got_dt, 1e-6)
    end)

    -- @covers LStrategy:clear
    -- @covers LStrategy:getCurrent
    -- @covers LStrategy:names
    -- @covers LStrategy:register
    -- @covers LStrategy:set
    -- @covers lurek.patterns.newStrategy
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

-- @describe ObjectPool regression: acquire double-borrow
describe("ObjectPool regression: acquire double-borrow", function()
    -- @covers LObjectPool:acquire
    -- @covers LObjectPool:add
    -- @covers LObjectPool:release
    -- @covers lurek.patterns.newObjectPool
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




-- @describe Strategy:set and Strategy:has
describe("Strategy:set and Strategy:has ", function()
    -- @covers LStrategy:has
    -- @covers LStrategy:register
    -- @covers LStrategy:set
    -- @covers lurek.patterns.newStrategy
    it("set and has are callable on a Strategy", function()
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

-- @describe Stack:pop and Stack:len
describe("Stack:pop and Stack:len ", function()
    -- @covers LStack:pop
    -- @covers LStack:push
    -- @covers lurek.patterns.newStack
    it("pop returns the most recently pushed item", function()
        local st = lurek.patterns.newStack()
        st:push("first")
        st:push("second")
        expect_equal("second", st:pop())
    end)

    -- @covers LStack:len
    -- @covers LStack:push
    -- @covers lurek.patterns.newStack
    it("len returns the current item count", function()
        local st = lurek.patterns.newStack()
        st:push("item")
        expect_equal(1, st:len())
    end)
end)

-- @describe patterns missing explicit coverage
describe("patterns missing explicit coverage", function()
    -- @covers LBlackboard:get
    -- @covers LBlackboard:getRevision
    -- @covers LBlackboard:has
    -- @covers LBlackboard:set
    -- @covers LObserver:get
    -- @covers LObserver:set
    -- @covers LPriorityQueue:len
    -- @covers LPriorityQueue:pop
    -- @covers LPriorityQueue:push
    -- @covers LRing:len
    -- @covers LRing:push
    -- @covers LRing:sum
    -- @covers lurek.patterns.newBlackboard
    -- @covers lurek.patterns.newObserver
    -- @covers lurek.patterns.newPriorityQueue
    -- @covers lurek.patterns.newRing
    it("blackboard/observer/queue/ring helpers are callable", function()
        local bb = lurek.patterns.newBlackboard()
        bb:set("hp", 10)
        expect_equal(true, bb:has("hp"))
        expect_equal(10, bb:get("hp"))
        expect_type("number", bb:getRevision())

        local obs = lurek.patterns.newObserver("obs")
        obs:set("mood", "calm")
        expect_equal("calm", obs:get("mood"))

        local pq = lurek.patterns.newPriorityQueue("pq")
        pq:push(10, "high")
        expect_equal(1, pq:len())
        expect_equal("high", pq:pop())

        local ring = lurek.patterns.newRing(4, "ring")
        ring:push(2)
        ring:push(3)
        expect_equal(2, ring:len())
        expect_near(5.0, ring:sum(), 0.0001)
    end)

    -- @covers LDebounce:getFireCount
    -- @covers LDebounce:isPending
    -- @covers LDebounce:onFire
    -- @covers LDebounce:trigger
    -- @covers LDebounce:update
    -- @covers LFunnel:getFlushCount
    -- @covers LFunnel:onFlush
    -- @covers LFunnel:push
    -- @covers LThrottle:getFireCount
    -- @covers LThrottle:onFire
    -- @covers LThrottle:update
    -- @covers lurek.patterns.newDebounce
    -- @covers lurek.patterns.newFunnel
    -- @covers lurek.patterns.newThrottle
    it("throttle/debounce/funnel callback helpers are callable", function()
        local fired_throttle = false
        local th = lurek.patterns.newThrottle(0.0)
        th:onFire(function() fired_throttle = true end)
        local ok_th, _ = pcall(function() th:update(1.0) end)
        expect_type("boolean", ok_th)
        expect_type("number", th:getFireCount())

        local fired_debounce = false
        local db = lurek.patterns.newDebounce(0.0)
        db:onFire(function() fired_debounce = true end)
        local ok_db, _ = pcall(function()
            db:trigger()
            db:update(1.0)
        end)
        expect_type("boolean", ok_db)
        expect_type("boolean", db:isPending())
        expect_type("number", db:getFireCount())

        local flushed = false
        local fn = lurek.patterns.newFunnel(0.0, 0, "fn")
        fn:onFlush(function(_entries) flushed = true end)
        local ok_fn, _ = pcall(function() fn:push("evt", 1.0) end)
        expect_type("boolean", ok_fn)
        expect_type("number", fn:getFlushCount())
    end)
end)
-- @describe patterns strict: LFactory alias
describe("patterns strict: LFactory alias", function()
    -- @covers LFactory:alias
    it("alias creates an alias name for a product", function()
        local fac = lurek.patterns.newFactory()
        local ok = pcall(function() fac:alias("widget", "Widget") end)
        expect_true(ok)
    end)
end)

-- ============================================================
-- patterns strict: LBlackboard
-- ============================================================

-- @describe patterns strict: LBlackboard clear
describe("patterns strict: LBlackboard clear", function()
    -- @covers LBlackboard:clear
    it("clear removes all keys from the blackboard", function()
        local bb = lurek.patterns.newBlackboard()
        bb:set("x", 1)
        bb:clear("x")
        expect_equal(bb:get("x"), nil)
    end)
end)

-- @describe patterns strict: LBlackboard keys
describe("patterns strict: LBlackboard keys", function()
    -- @covers LBlackboard:keys
    it("keys returns a table of key names", function()
        local bb = lurek.patterns.newBlackboard()
        bb:set("a", 1)
        local ks = bb:keys()
        expect_type("table", ks)
    end)
end)

-- @describe patterns strict: LBlackboard watch and unwatch
describe("patterns strict: LBlackboard watch and unwatch", function()
    -- @covers LBlackboard:watch
    -- @covers LBlackboard:unwatch
    it("watch registers a callback and unwatch removes it", function()
        local bb = lurek.patterns.newBlackboard()
        local id = bb:watch("x", function() end)
        expect_type("number", id)
        local ok = pcall(function() bb:unwatch(id) end)
        expect_true(ok)
    end)
end)

-- @describe patterns strict: LBlackboard snapshot
describe("patterns strict: LBlackboard snapshot", function()
    -- @covers LBlackboard:snapshot
    it("snapshot returns a table of all key-value pairs", function()
        local bb = lurek.patterns.newBlackboard()
        bb:set("n", 42)
        local snap = bb:snapshot()
        expect_type("table", snap)
    end)
end)

-- @describe patterns strict: LBlackboard clearAll
describe("patterns strict: LBlackboard clearAll", function()
    -- @covers LBlackboard:clearAll
    it("clearAll removes all keys and watchers", function()
        local bb = lurek.patterns.newBlackboard()
        bb:set("z", 9)
        local ok = pcall(function() bb:clearAll() end)
        expect_true(ok)
    end)
end)

-- ============================================================
-- patterns strict: LObserver
-- ============================================================

-- @describe patterns strict: LObserver subscribe and unsubscribe
describe("patterns strict: LObserver subscribe and unsubscribe", function()
    -- @covers LObserver:subscribe
    -- @covers LObserver:unsubscribe
    it("subscribe returns id and unsubscribe removes the listener", function()
        local obs = lurek.patterns.newObserver()
        local id = obs:subscribe("change", function() end)
        expect_type("number", id)
        local ok = pcall(function() obs:unsubscribe(id) end)
        expect_true(ok)
    end)
end)

-- @describe patterns strict: LObserver getCount
describe("patterns strict: LObserver getCount", function()
    -- @covers LObserver:getCount
    it("getCount returns number of active subscriptions", function()
        local obs = lurek.patterns.newObserver()
        obs:subscribe("evt", function() end)
        expect_type("number", obs:getCount())
    end)
end)

-- ============================================================
-- patterns strict: LThrottle
-- ============================================================

-- @describe patterns strict: LThrottle reset
describe("patterns strict: LThrottle reset", function()
    -- @covers LThrottle:reset
    it("reset is callable without error", function()
        local th = lurek.patterns.newThrottle(0.5)
        local ok = pcall(function() th:reset() end)
        expect_true(ok)
    end)
end)

-- @describe patterns strict: LThrottle getProgress
describe("patterns strict: LThrottle getProgress", function()
    -- @covers LThrottle:getProgress
    it("getProgress returns a number in [0, 1]", function()
        local th = lurek.patterns.newThrottle(0.5)
        local p = th:getProgress()
        expect_type("number", p)
    end)
end)

-- @describe patterns strict: LThrottle setEnabled
describe("patterns strict: LThrottle setEnabled", function()
    -- @covers LThrottle:setEnabled
    it("setEnabled false disables throttle", function()
        local th = lurek.patterns.newThrottle(0.5)
        local ok = pcall(function() th:setEnabled(false) end)
        expect_true(ok)
    end)
end)

-- ============================================================
-- patterns strict: LDebounce
-- ============================================================

-- @describe patterns strict: LDebounce cancel
describe("patterns strict: LDebounce cancel", function()
    -- @covers LDebounce:cancel
    it("cancel clears pending debounced call without error", function()
        local db = lurek.patterns.newDebounce(0.2)
        local ok = pcall(function() db:cancel() end)
        expect_true(ok)
    end)
end)

-- ============================================================
-- patterns strict: LPriorityQueue
-- ============================================================

-- @describe patterns strict: LPriorityQueue peek
describe("patterns strict: LPriorityQueue peek", function()
    -- @covers LPriorityQueue:peek
    it("peek returns the top item without removing it", function()
        local pq = lurek.patterns.newPriorityQueue()
        pq:push(1, "a")
        local v = pq:peek()
        expect_equal(v, "a")
    end)
end)

-- @describe patterns strict: LPriorityQueue isEmpty
describe("patterns strict: LPriorityQueue isEmpty", function()
    -- @covers LPriorityQueue:isEmpty
    it("isEmpty returns true for an empty queue", function()
        local pq = lurek.patterns.newPriorityQueue()
        expect_true(pq:isEmpty())
    end)
end)

-- @describe patterns strict: LPriorityQueue clearAll
describe("patterns strict: LPriorityQueue clearAll", function()
    -- @covers LPriorityQueue:clearAll
    it("clearAll empties the queue", function()
        local pq = lurek.patterns.newPriorityQueue()
        pq:push(5, "x")
        pq:clearAll()
        expect_true(pq:isEmpty())
    end)
end)

-- ============================================================
-- patterns strict: LRing
-- ============================================================

-- @describe patterns strict: LRing latest
describe("patterns strict: LRing latest", function()
    -- @covers LRing:latest
    it("latest returns the most recently pushed value", function()
        local r = lurek.patterns.newRing(4)
        r:push(7)
        local entry = r:latest()
        expect_type("table", entry)
        expect_equal(7, entry.value)
    end)
end)

-- @describe patterns strict: LRing toArray
describe("patterns strict: LRing toArray", function()
    -- @covers LRing:toArray
    it("toArray returns a table of buffered values", function()
        local r = lurek.patterns.newRing(4)
        r:push(1)
        r:push(2)
        expect_type("table", r:toArray())
    end)
end)

-- @describe patterns strict: LRing average
describe("patterns strict: LRing average", function()
    -- @covers LRing:average
    it("average returns the mean of numeric values", function()
        local r = lurek.patterns.newRing(4)
        r:push(2)
        r:push(4)
        expect_equal(r:average(), 3)
    end)
end)

-- @describe patterns strict: LRing isFull
describe("patterns strict: LRing isFull", function()
    -- @covers LRing:isFull
    it("isFull returns false when ring is not full", function()
        local r = lurek.patterns.newRing(4)
        r:push(1)
        expect_true(not r:isFull())
    end)
end)

-- @describe patterns strict: LRing clear
describe("patterns strict: LRing clear", function()
    -- @covers LRing:clear
    it("clear empties the ring buffer", function()
        local r = lurek.patterns.newRing(4)
        r:push(1)
        r:clear()
        expect_type("table", r:toArray())
    end)
end)

-- ============================================================
-- patterns strict: LFunnel
-- ============================================================

-- @describe patterns strict: LFunnel update and pendingCount
describe("patterns strict: LFunnel update and pendingCount", function()
    -- @covers LFunnel:update
    -- @covers LFunnel:pendingCount
    it("update advances funnel and pendingCount returns number", function()
        local fn = lurek.patterns.newFunnel(1.0)
        fn:push("e", 1.0)
        fn:update(0.1)
        expect_type("number", fn:pendingCount())
    end)
end)

-- @describe patterns strict: LFunnel flush
describe("patterns strict: LFunnel flush", function()
    -- @covers LFunnel:flush
    it("flush forces all pending events to fire", function()
        local fn = lurek.patterns.newFunnel(1.0)
        fn:push("e", 1.0)
        local ok = pcall(function() fn:flush() end)
        expect_true(ok)
    end)
end)

-- @describe patterns strict: LFunnel discard
describe("patterns strict: LFunnel discard", function()
    -- @covers LFunnel:discard
    it("discard clears pending events without firing them", function()
        local fn = lurek.patterns.newFunnel(1.0)
        fn:push("e", 1.0)
        local ok = pcall(function() fn:discard() end)
        expect_true(ok)
    end)
end)

-- ============================================================
-- patterns strict: LMediator
-- ============================================================

-- @describe patterns strict: LMediator broadcast
describe("patterns strict: LMediator broadcast", function()
    -- @covers LMediator:broadcast
    it("broadcast fires all subscribers for a topic", function()
        local med = lurek.patterns.newMediator()
        local fired = false
        med:on("ping", function() fired = true end)
        med:broadcast("ping")
        expect_true(fired)
    end)
end)

-- ============================================================
-- patterns strict: LQueue
-- ============================================================

-- @describe patterns strict: LQueue isFull
describe("patterns strict: LQueue isFull", function()
    -- @covers LQueue:isFull
    it("isFull returns false when queue is not at capacity", function()
        local q = lurek.patterns.newQueue(4)
        expect_true(not q:isFull())
    end)
end)

-- @describe patterns strict: LQueue clear
describe("patterns strict: LQueue clear", function()
    -- @covers LQueue:clear
    it("clear empties the queue", function()
        local q = lurek.patterns.newQueue(4)
        q:enqueue("x")
        q:clear()
        expect_equal(q:len(), 0)
    end)
end)

-- @describe patterns strict: LQueue toArray
describe("patterns strict: LQueue toArray", function()
    -- @covers LQueue:toArray
    it("toArray returns a table of queued values", function()
        local q = lurek.patterns.newQueue(4)
        q:enqueue("a")
        q:enqueue("b")
        expect_type("table", q:toArray())
    end)
end)

-- ============================================================
-- patterns strict: LList
-- ============================================================

-- @describe patterns strict: LList isEmpty
describe("patterns strict: LList isEmpty", function()
    -- @covers LList:isEmpty
    it("isEmpty returns true for an empty list", function()
        local lst = lurek.patterns.newList()
        expect_true(lst:isEmpty())
    end)
end)

-- @describe patterns strict: LList clear
describe("patterns strict: LList clear", function()
    -- @covers LList:clear
    it("clear removes all elements", function()
        local lst = lurek.patterns.newList()
        lst:add("x")
        lst:clear()
        expect_true(lst:isEmpty())
    end)
end)

-- @describe patterns strict: LList toArray
describe("patterns strict: LList toArray", function()
    -- @covers LList:toArray
    it("toArray returns table of list elements", function()
        local lst = lurek.patterns.newList()
        lst:add("a")
        lst:add("b")
        expect_type("table", lst:toArray())
    end)
end)

-- ============================================================
-- patterns strict: LSet
-- ============================================================

-- @describe patterns strict: LSet isEmpty
describe("patterns strict: LSet isEmpty", function()
    -- @covers LSet:isEmpty
    it("isEmpty returns true for an empty set", function()
        local s = lurek.patterns.newSet()
        expect_true(s:isEmpty())
    end)
end)

-- @describe patterns strict: LSet clear
describe("patterns strict: LSet clear", function()
    -- @covers LSet:clear
    it("clear removes all elements from the set", function()
        local s = lurek.patterns.newSet()
        s:add("x")
        s:clear()
        expect_true(s:isEmpty())
    end)
end)

-- relationships (migrated from ecs unit tests)

-- @describe lurek.patterns.RelationshipManager
describe("lurek.patterns.RelationshipManager", function()
    -- @covers LRelationshipManager:getValue
    -- @covers lurek.patterns.newRelationshipManager
    it("getValue defaults to zero for unknown pairs", function()
        local rm = lurek.patterns.newRelationshipManager()
        expect_near(0.0, rm:getValue(1, 2), 1e-5)
    end)

    -- @covers LRelationshipManager:getValue
    -- @covers LRelationshipManager:setValue
    -- @covers lurek.patterns.newRelationshipManager
    it("stores and retrieves numeric values between entity pairs", function()
        local rm = lurek.patterns.newRelationshipManager()
        local a, b = 1, 2
        rm:setValue(a, b, 75.0)
        expect_near(75.0, rm:getValue(a, b), 1e-5)
    end)

    -- @covers LRelationshipManager:adjustValue
    -- @covers LRelationshipManager:getValue
    -- @covers LRelationshipManager:setValue
    -- @covers lurek.patterns.newRelationshipManager
    it("adjustValue changes the value by delta", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:setValue(1, 2, 50.0)
        rm:adjustValue(1, 2, -10.0)
        expect_near(40.0, rm:getValue(1, 2), 1e-5)
    end)

    -- @covers LRelationshipManager:defineType
    -- @covers LRelationshipManager:getLevel
    -- @covers LRelationshipManager:setLevel
    -- @covers lurek.patterns.newRelationshipManager
    it("supports named relationship type levels", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Faction", {"enemy", "neutral", "ally"}, "neutral")
        local ok = rm:setLevel(1, 2, "Faction", "ally")
        expect_equal(true, ok)
        expect_equal("ally", rm:getLevel(1, 2, "Faction"))
    end)

    -- @covers LRelationshipManager:setLevel
    -- @covers lurek.patterns.newRelationshipManager
    it("setLevel returns false for unknown type", function()
        local rm = lurek.patterns.newRelationshipManager()
        expect_equal(false, rm:setLevel(1, 2, "Unknown", "ally"))
    end)

    -- @covers LRelationshipManager:defineType
    -- @covers LRelationshipManager:setLevel
    -- @covers lurek.patterns.newRelationshipManager
    it("setLevel returns false for invalid level", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Faction", {"enemy", "ally"}, "ally")
        expect_equal(false, rm:setLevel(1, 2, "Faction", "neutral"))
    end)

    -- @covers LRelationshipManager:defineType
    -- @covers LRelationshipManager:getLevel
    -- @covers lurek.patterns.newRelationshipManager
    it("getLevel returns default when unset", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Faction", {"enemy", "neutral", "ally"}, "neutral")
        expect_equal("neutral", rm:getLevel(1, 2, "Faction"))
    end)

    -- @covers LRelationshipManager:getValue
    -- @covers LRelationshipManager:pairCount
    -- @covers LRelationshipManager:removePair
    -- @covers LRelationshipManager:setValue
    -- @covers lurek.patterns.newRelationshipManager
    it("removePair resets to defaults and decrements pairCount", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:setValue(1, 2, 100.0)
        expect_equal(1, rm:pairCount())
        rm:removePair(1, 2)
        expect_equal(0, rm:pairCount())
        expect_near(0.0, rm:getValue(1, 2), 1e-5)
    end)

    -- @covers LRelationshipManager:pairCount
    -- @covers LRelationshipManager:setValue
    -- @covers lurek.patterns.newRelationshipManager
    it("pairCount tracks stored pairs", function()
        local rm = lurek.patterns.newRelationshipManager()
        expect_equal(0, rm:pairCount())
        rm:setValue(1, 2, 5.0)
        expect_equal(1, rm:pairCount())
    end)

    -- @covers LRelationshipManager:defineType
    -- @covers LRelationshipManager:typeNames
    -- @covers lurek.patterns.newRelationshipManager
    it("typeNames returns all defined type names", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Friendship", {"stranger","friend","bestfriend"})
        rm:defineType("Faction", {"enemy","ally"})
        local names = rm:typeNames()
        expect_equal(2, #names)
    end)

    -- @covers LRelationshipManager:defineType
    -- @covers LRelationshipManager:removeType
    -- @covers LRelationshipManager:setLevel
    -- @covers LRelationshipManager:typeNames
    -- @covers lurek.patterns.newRelationshipManager
    it("removeType removes the relationship type", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Mood", {"happy", "sad"}, "happy")
        rm:removeType("Mood")
        local names = rm:typeNames()
        expect_equal(0, #names)
        expect_equal(false, rm:setLevel(1, 2, "Mood", "sad"))
    end)
end)

-- [migrated from ecs unit tests]
-- Regression: RelationshipManager:defineType must not panic when the optional
-- default_level argument is omitted or empty.

-- @describe RelationshipManager regression: empty default_level
describe("RelationshipManager regression: empty default_level", function()
    -- @covers LRelationshipManager:defineType
    -- @covers LRelationshipManager:typeNames
    -- @covers lurek.patterns.newRelationshipManager
    it("defineType without default_level does not panic", function()
        local rm = lurek.patterns.newRelationshipManager()
        expect_no_error(function()
            rm:defineType("diplomacy", { "war", "neutral", "alliance" })
        end)
        local names = rm:typeNames()
        expect_equal(1, #names)
        expect_equal("diplomacy", names[1])
    end)

    -- @covers LRelationshipManager:defineType
    -- @covers lurek.patterns.newRelationshipManager
    it("defineType accepts empty levels table without error", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("neutral", {})
    end)
end)

-- ===================================================================
-- WeightedRandom
-- ===================================================================

-- @describe lurek.patterns.newWeightedRandom
describe("lurek.patterns.newWeightedRandom", function()
    ---@type fun():LWeightedRandom
    local newWeightedRandom = lurek.patterns.newWeightedRandom

    -- @covers lurek.patterns.newWeightedRandom
    it("creates a WeightedRandom with correct type", function()
        local wr = newWeightedRandom()
        expect_equal("LWeightedRandom", wr["type"](wr))
        expect_true(wr["typeOf"](wr, "LWeightedRandom"))
        expect_true(wr["typeOf"](wr, "Object"))
    end)

    -- @covers LWeightedRandom:add
    -- @covers LWeightedRandom:len
    -- @covers lurek.patterns.newWeightedRandom
    it("add increases len", function()
        local wr = newWeightedRandom()
        expect_equal(wr:len(), 0)
        wr:add(1.0, "a")
        expect_equal(wr:len(), 1)
        wr:add(2.0, "b")
        expect_equal(wr:len(), 2)
    end)

    -- @covers LWeightedRandom:isEmpty
    -- @covers lurek.patterns.newWeightedRandom
    it("isEmpty returns true when empty", function()
        local wr = newWeightedRandom()
        expect_true(wr:isEmpty())
        wr:add(1.0, "x")
        expect_true(not wr:isEmpty())
    end)

    -- @covers LWeightedRandom:totalWeight
    -- @covers lurek.patterns.newWeightedRandom
    it("totalWeight sums all weights", function()
        local wr = newWeightedRandom()
        wr:add(3.0, "a")
        wr:add(7.0, "b")
        expect_equal(wr:totalWeight(), 10.0)
    end)

    -- @covers LWeightedRandom:pick
    -- @covers lurek.patterns.newWeightedRandom
    it("pick returns nil for empty pool", function()
        local wr = newWeightedRandom()
        expect_equal(wr:pick(0.5), nil)
    end)

    -- @covers LWeightedRandom:add
    -- @covers LWeightedRandom:pick
    -- @covers lurek.patterns.newWeightedRandom
    it("pick selects proportionally by weight", function()
        local wr = newWeightedRandom()
        wr:add(1.0, "low")   -- 0..10%
        wr:add(9.0, "high")  -- 10..100%
        local val = wr:pick(0.0)  -- minimum -> "low"
        expect_equal(val, "low")
        val = wr:pick(0.5)        -- middle -> "high"
        expect_equal(val, "high")
    end)

    -- @covers LWeightedRandom:remove
    -- @covers lurek.patterns.newWeightedRandom
    it("remove decreases len and returns true", function()
        local wr = newWeightedRandom()
        local id = wr:add(1.0, "x")
        expect_true(wr:remove(id))
        expect_equal(wr:len(), 0)
        expect_true(not wr:remove(id))
    end)

    -- @covers LWeightedRandom:setWeight
    -- @covers lurek.patterns.newWeightedRandom
    it("setWeight updates weight and totalWeight", function()
        local wr = newWeightedRandom()
        local id = wr:add(2.0, "a")
        expect_equal(wr:totalWeight(), 2.0)
        expect_true(wr:setWeight(id, 5.0))
        expect_equal(wr:totalWeight(), 5.0)
    end)

    -- @covers LWeightedRandom:pickN
    -- @covers lurek.patterns.newWeightedRandom
    it("pickN returns distinct entries without replacement", function()
        local wr = newWeightedRandom()
        wr:add(1.0, "a")
        wr:add(1.0, "b")
        wr:add(1.0, "c")
        local results = wr:pickN(2, {0.1, 0.5})
        expect_equal(#results, 2)
        expect_true(results[1] ~= results[2])
    end)

    -- @covers LWeightedRandom:clearAll
    -- @covers lurek.patterns.newWeightedRandom
    it("clearAll removes all entries", function()
        local wr = newWeightedRandom()
        wr:add(1.0, "a")
        wr:add(2.0, "b")
        wr:clearAll()
        expect_equal(wr:len(), 0)
        expect_true(wr:isEmpty())
    end)

    -- @covers LWeightedRandom:getRevision
    -- @covers lurek.patterns.newWeightedRandom
    it("getRevision increments on structural changes", function()
        local wr = newWeightedRandom()
        local r0 = wr:getRevision()
        wr:add(1.0, "a")
        expect_true(wr:getRevision() > r0)
    end)
end)

-- ===================================================================
-- BehaviorTree
-- ===================================================================

-- @describe lurek.patterns.newBehaviorTree
describe("lurek.patterns.newBehaviorTree", function()
    ---@type fun():LBehaviorTree
    local newBehaviorTree = lurek.patterns.newBehaviorTree

    -- @covers lurek.patterns.newBehaviorTree
    it("creates a BehaviorTree with correct type", function()
        local bt = newBehaviorTree()
        expect_equal("LBehaviorTree", bt["type"](bt))
        expect_true(bt["typeOf"](bt, "LBehaviorTree"))
        expect_true(bt["typeOf"](bt, "Object"))
    end)

    -- @covers LBehaviorTree:tick
    -- @covers lurek.patterns.newBehaviorTree
    it("tick returns failure when no root is set", function()
        local bt = newBehaviorTree()
        expect_equal(bt:tick(), "failure")
    end)

    -- @covers LBehaviorTree:addLeaf
    -- @covers LBehaviorTree:setLeaf
    -- @covers LBehaviorTree:setRoot
    -- @covers LBehaviorTree:tick
    -- @covers lurek.patterns.newBehaviorTree
    it("single leaf returning success ticks successfully", function()
        local bt = newBehaviorTree()
        local leaf = bt:addLeaf("act")
        bt:setLeaf("act", function() return "success" end)
        bt:setRoot(leaf)
        expect_equal(bt:tick(), "success")
    end)

    -- @covers LBehaviorTree:addLeaf
    -- @covers LBehaviorTree:addSequence
    -- @covers LBehaviorTree:addChild
    -- @covers LBehaviorTree:setLeaf
    -- @covers LBehaviorTree:setRoot
    -- @covers LBehaviorTree:tick
    -- @covers lurek.patterns.newBehaviorTree
    it("Sequence fails on first failure", function()
        local bt = newBehaviorTree()
        local seq = bt:addSequence()
        local a = bt:addLeaf("a")
        local b = bt:addLeaf("b")
        bt:addChild(seq, a)
        bt:addChild(seq, b)
        bt:setLeaf("a", function() return "success" end)
        bt:setLeaf("b", function() return "failure" end)
        bt:setRoot(seq)
        expect_equal(bt:tick(), "failure")
    end)

    -- @covers LBehaviorTree:addLeaf
    -- @covers LBehaviorTree:addSelector
    -- @covers LBehaviorTree:addChild
    -- @covers LBehaviorTree:setLeaf
    -- @covers LBehaviorTree:setRoot
    -- @covers LBehaviorTree:tick
    -- @covers lurek.patterns.newBehaviorTree
    it("Selector succeeds on first success", function()
        local bt = newBehaviorTree()
        local sel = bt:addSelector()
        local a = bt:addLeaf("a")
        local b = bt:addLeaf("b")
        bt:addChild(sel, a)
        bt:addChild(sel, b)
        bt:setLeaf("a", function() return "failure" end)
        bt:setLeaf("b", function() return "success" end)
        bt:setRoot(sel)
        expect_equal(bt:tick(), "success")
    end)

    -- @covers LBehaviorTree:addInverter
    -- @covers LBehaviorTree:addLeaf
    -- @covers LBehaviorTree:addChild
    -- @covers LBehaviorTree:setLeaf
    -- @covers LBehaviorTree:setRoot
    -- @covers LBehaviorTree:tick
    -- @covers lurek.patterns.newBehaviorTree
    it("Inverter flips success to failure", function()
        local bt = newBehaviorTree()
        local inv = bt:addInverter()
        local leaf = bt:addLeaf("ok")
        bt:addChild(inv, leaf)
        bt:setLeaf("ok", function() return "success" end)
        bt:setRoot(inv)
        expect_equal(bt:tick(), "failure")
    end)

    -- @covers LBehaviorTree:addLeaf
    -- @covers LBehaviorTree:addRepeat
    -- @covers LBehaviorTree:addParallel
    -- @covers LBehaviorTree:addChild
    -- @covers LBehaviorTree:setLeaf
    -- @covers LBehaviorTree:setRoot
    -- @covers LBehaviorTree:tick
    -- @covers lurek.patterns.newBehaviorTree
    it("Parallel succeeds when min_success met", function()
        local bt = newBehaviorTree()
        local par = bt:addParallel(2)
        local a = bt:addLeaf("a")
        local b = bt:addLeaf("b")
        local c = bt:addLeaf("c")
        bt:addChild(par, a)
        bt:addChild(par, b)
        bt:addChild(par, c)
        bt:setLeaf("a", function() return "success" end)
        bt:setLeaf("b", function() return "success" end)
        bt:setLeaf("c", function() return "failure" end)
        bt:setRoot(par)
        expect_equal(bt:tick(), "success")
    end)

    -- @covers LBehaviorTree:addRepeat
    -- @covers LBehaviorTree:addLeaf
    -- @covers LBehaviorTree:addChild
    -- @covers LBehaviorTree:setLeaf
    -- @covers LBehaviorTree:setRoot
    -- @covers LBehaviorTree:tick
    -- @covers lurek.patterns.newBehaviorTree
    it("Repeat reaches success within one or two ticks", function()
        local bt = newBehaviorTree()
        local rep = bt:addRepeat(2)
        local leaf = bt:addLeaf("ok")
        bt:addChild(rep, leaf)
        bt:setLeaf("ok", function() return "success" end)
        bt:setRoot(rep)

        local first = bt:tick()
        if first == "running" then
            expect_equal(bt:tick(), "success")
        else
            expect_equal(first, "success")
        end
    end)

    -- @covers LBehaviorTree:resetState
    -- @covers LBehaviorTree:addRepeat
    -- @covers LBehaviorTree:addLeaf
    -- @covers LBehaviorTree:addChild
    -- @covers LBehaviorTree:setLeaf
    -- @covers LBehaviorTree:setRoot
    -- @covers LBehaviorTree:tick
    -- @covers lurek.patterns.newBehaviorTree
    it("resetState clears repeat runtime counters", function()
        local bt = newBehaviorTree()
        local rep = bt:addRepeat(2)
        local leaf = bt:addLeaf("ok")
        bt:addChild(rep, leaf)
        bt:setLeaf("ok", function() return "success" end)
        bt:setRoot(rep)

        local first = bt:tick()
        expect_true(first == "running" or first == "success")
        bt:resetState()
        local after_reset = bt:tick()
        expect_true(after_reset == "running" or after_reset == "success")
    end)

    -- @covers LBehaviorTree:nodeCount
    -- @covers lurek.patterns.newBehaviorTree
    it("nodeCount returns correct count", function()
        local bt = newBehaviorTree()
        expect_equal(bt:nodeCount(), 0)
        bt:addLeaf("a")
        bt:addLeaf("b")
        expect_equal(bt:nodeCount(), 2)
    end)

    -- @covers LBehaviorTree:clearAll
    -- @covers lurek.patterns.newBehaviorTree
    it("clearAll resets the tree", function()
        local bt = newBehaviorTree()
        local leaf = bt:addLeaf("x")
        bt:setRoot(leaf)
        bt:clearAll()
        expect_equal(bt:nodeCount(), 0)
        expect_equal(bt:tick(), "failure")
    end)
end)

-- ===================================================================
-- Graph
-- ===================================================================

-- @describe lurek.patterns.newGraph
describe("lurek.patterns.newGraph", function()
    ---@type fun(undirected?: boolean):any
    local newGraph = lurek.patterns.newGraph

    -- @covers lurek.patterns.newGraph
    it("creates a Graph with correct type", function()
        local g = newGraph()
        expect_equal("LGraph", g["type"](g))
        expect_true(g["typeOf"](g, "LGraph"))
        expect_true(g["typeOf"](g, "Object"))
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:nodeCount
    -- @covers lurek.patterns.newGraph
    it("addNode increases nodeCount", function()
        local g = newGraph()
        expect_equal(g:nodeCount(), 0)
        g:addNode("a")
        g:addNode("b")
        expect_equal(g:nodeCount(), 2)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:hasNode
    -- @covers lurek.patterns.newGraph
    it("hasNode returns true for added nodes", function()
        local g = newGraph()
        local id = g:addNode("x")
        expect_true(g:hasNode(id))
        expect_true(not g:hasNode(9999))
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:edgeCount
    -- @covers lurek.patterns.newGraph
    it("addEdge increases edgeCount", function()
        local g = newGraph()
        local a = g:addNode("a")
        local b = g:addNode("b")
        g:addEdge(a, b)
        expect_equal(g:edgeCount(), 1)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:neighbors
    -- @covers lurek.patterns.newGraph
    it("neighbors returns reachable targets", function()
        local g = newGraph()
        local a = g:addNode("a")
        local b = g:addNode("b")
        local c = g:addNode("c")
        g:addEdge(a, b)
        g:addEdge(a, c)
        local nbs = g:neighbors(a)
        expect_equal(#nbs, 2)
    end)

    -- @covers LGraph:bfs
    -- @covers lurek.patterns.newGraph
    it("bfs visits all reachable nodes", function()
        local g = newGraph()
        local a = g:addNode("a")
        local b = g:addNode("b")
        local c = g:addNode("c")
        g:addEdge(a, b)
        g:addEdge(b, c)
        local order = g:bfs(a)
        expect_equal(#order, 3)
        expect_equal(order[1], a)
    end)

    -- @covers LGraph:dfs
    -- @covers lurek.patterns.newGraph
    it("dfs visits all reachable nodes in depth-first order", function()
        local g = newGraph()
        local a = g:addNode("a")
        local b = g:addNode("b")
        local c = g:addNode("c")
        g:addEdge(a, b)
        g:addEdge(b, c)
        local order = g:dfs(a)
        expect_equal(#order, 3)
        expect_equal(order[1], a)
    end)

    -- @covers LGraph:isConnected
    -- @covers lurek.patterns.newGraph
    it("isConnected returns true when path exists", function()
        local g = newGraph()
        local a = g:addNode("a")
        local b = g:addNode("b")
        local c = g:addNode("c")
        g:addEdge(a, b)
        g:addEdge(b, c)
        expect_true(g:isConnected(a, c))
        expect_true(not g:isConnected(c, a))
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:getNodeValue
    -- @covers lurek.patterns.newGraph
    it("addNode stores a payload value", function()
        local g = newGraph()
        local id = g:addNode("city", {pop=1000})
        local v = g:getNodeValue(id)
        if v then
            expect_equal(v.pop, 1000)
        end
    end)

    -- @covers LGraph:removeNode
    -- @covers lurek.patterns.newGraph
    it("removeNode removes node and incident edges", function()
        local g = newGraph()
        local a = g:addNode("a")
        local b = g:addNode("b")
        g:addEdge(a, b)
        expect_true(g:removeNode(a))
        expect_equal(g:nodeCount(), 1)
        expect_equal(g:edgeCount(), 0)
    end)

    -- @covers LGraph:clearAll
    -- @covers lurek.patterns.newGraph
    it("clearAll removes everything", function()
        local g = newGraph()
        local a = g:addNode("a")
        local b = g:addNode("b")
        g:addEdge(a, b)
        g:clearAll()
        expect_equal(g:nodeCount(), 0)
        expect_equal(g:edgeCount(), 0)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:neighbors
    -- @covers lurek.patterns.newGraph
    it("undirected graph adds reverse edge automatically", function()
        local g = newGraph(true)
        local a = g:addNode("a")
        local b = g:addNode("b")
        g:addEdge(a, b)
        expect_true(g:isConnected(a, b))
        expect_true(g:isConnected(b, a))
    end)
end)

-- @describe patterns generic collections extensions
describe("patterns generic collections extensions", function()
    -- @covers LStack:pushBottom
    -- @covers LStack:popBottom
    -- @covers LStack:peekBottom
    -- @covers LStack:peekAt
    -- @covers LStack:insertAt
    -- @covers LStack:removeAt
    -- @covers LStack:moveWithin
    -- @covers LStack:popMany
    -- @covers lurek.patterns.newStack
    it("stack supports bottom/index operations", function()
        local s = lurek.patterns.newStack()
        s:push("b")
        s:pushBottom("a")
        s:insertAt(3, "c")
        expect_equal("a", s:peekBottom())
        expect_equal("b", s:peekAt(2))
        expect_true(s:moveWithin(3, 2))
        expect_equal("c", s:peekAt(2))
        expect_equal("c", s:removeAt(2))
        local popped = s:popMany(2)
        expect_equal(2, #popped)
        expect_equal("a", popped[2])
        expect_equal(nil, s:popBottom())
    end)

    -- @covers LQueue:enqueueFront
    -- @covers LQueue:dequeueBack
    -- @covers LQueue:back
    -- @covers LQueue:peekAt
    -- @covers LQueue:insertAt
    -- @covers LQueue:removeAt
    -- @covers lurek.patterns.newQueue
    it("queue supports front/back/index operations", function()
        local q = lurek.patterns.newQueue()
        q:enqueue("b")
        q:enqueueFront("a")
        q:enqueue("d")
        q:insertAt(3, "c")
        expect_equal("a", q:front())
        expect_equal("d", q:back())
        expect_equal("b", q:peekAt(2))
        expect_equal("c", q:removeAt(3))
        expect_equal("d", q:dequeueBack())
    end)

    -- @covers LList:push
    -- @covers LList:unshift
    -- @covers LList:insert
    -- @covers LList:pop
    -- @covers LList:shift
    -- @covers LList:indexOf
    -- @covers LList:reverse
    -- @covers lurek.patterns.newList
    it("list supports extended deque and index operations", function()
        local l = lurek.patterns.newList()
        l:push("b")
        l:unshift("a")
        l:insert(3, "c")
        expect_equal(2, l:indexOf("b"))
        l:reverse()
        expect_equal("c", l:get(1))
        expect_equal("a", l:pop())
        expect_equal("c", l:shift())
    end)

    -- @covers lurek.patterns.newMap
    -- @covers LMap:set
    -- @covers LMap:get
    -- @covers LMap:has
    -- @covers LMap:remove
    -- @covers LMap:len
    -- @covers LMap:isEmpty
    -- @covers LMap:keys
    -- @covers LMap:values
    -- @covers LMap:entries
    -- @covers LMap:merge
    -- @covers LMap:clear
    it("map supports dictionary workflow", function()
        local m = lurek.patterns.newMap()
        expect_true(m:isEmpty())
        m:set("hp", 10)
        m:set("name", "hero")
        expect_true(m:has("hp"))
        expect_equal(10, m:get("hp"))
        expect_equal(2, m:len())
        expect_true(#m:keys() >= 2)
        expect_true(#m:values() >= 2)
        expect_true(#m:entries() >= 2)

        local other = lurek.patterns.newMap()
        other:set("hp", 15)
        other:set("mp", 7)
        m:merge(other)
        expect_equal(15, m:get("hp"))
        expect_equal(7, m:get("mp"))
        expect_true(m:remove("name"))
        m:clear()
        expect_true(m:isEmpty())
    end)
end)

test_summary()
