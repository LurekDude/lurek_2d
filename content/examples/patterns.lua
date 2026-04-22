-- content/examples/patterns.lua
-- Practical usage examples for the lurek.patterns API (170 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.patterns.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/patterns.lua

print("[example] lurek.patterns — 170 API entries")

-- ── lurek.patterns.* free functions ──

--@api-stub: lurek.patterns.newEventBus
-- Creates a new EventBus instance.
-- Call when you need to create a new event bus.
local ok, obj = pcall(function() return lurek.patterns.newEventBus("name") end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newEventBus ok=", ok)

--@api-stub: lurek.patterns.newObjectPool
-- Creates a new ObjectPool instance.
-- Call when you need to create a new object pool.
local ok, obj = pcall(function() return lurek.patterns.newObjectPool() end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newObjectPool ok=", ok)

--@api-stub: lurek.patterns.newCommandStack
-- Creates a new CommandStack instance.
-- Call when you need to create a new command stack.
local ok, obj = pcall(function() return lurek.patterns.newCommandStack(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newCommandStack ok=", ok)

--@api-stub: lurek.patterns.newServiceLocator
-- Creates a new ServiceLocator instance.
-- Call when you need to create a new service locator.
local ok, obj = pcall(function() return lurek.patterns.newServiceLocator() end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newServiceLocator ok=", ok)

--@api-stub: lurek.patterns.newFactory
-- Creates a new Factory instance.
-- Call when you need to create a new factory.
local ok, obj = pcall(function() return lurek.patterns.newFactory() end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newFactory ok=", ok)

--@api-stub: lurek.patterns.newSimpleState
-- Creates a new SimpleState finite state machine instance.
-- Call when you need to create a new simple state.
local ok, obj = pcall(function() return lurek.patterns.newSimpleState() end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newSimpleState ok=", ok)

--@api-stub: lurek.patterns.newBlackboard
-- Creates a new Blackboard shared key-value store.
-- Call when you need to create a new blackboard.
local ok, obj = pcall(function() return lurek.patterns.newBlackboard("name") end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newBlackboard ok=", ok)

--@api-stub: lurek.patterns.newObserver
-- Creates a new reactive property Observer.
-- Call when you need to create a new observer.
local ok, obj = pcall(function() return lurek.patterns.newObserver("name") end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newObserver ok=", ok)

--@api-stub: lurek.patterns.newThrottle
-- Creates a leading-edge rate limiter that fires at most once per interval seconds.
-- Call when you need to create a new throttle.
local ok, obj = pcall(function() return lurek.patterns.newThrottle(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newThrottle ok=", ok)

--@api-stub: lurek.patterns.newDebounce
-- Creates a trailing-edge debounce that fires after the input stream is idle for wait seconds.
-- Call when you need to create a new debounce.
local ok, obj = pcall(function() return lurek.patterns.newDebounce(1.0) end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newDebounce ok=", ok)

--@api-stub: lurek.patterns.newPriorityQueue
-- Creates a stable priority-ordered task queue.
-- Call when you need to create a new priority queue.
local ok, obj = pcall(function() return lurek.patterns.newPriorityQueue("name") end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newPriorityQueue ok=", ok)

--@api-stub: lurek.patterns.newRing
-- Creates a fixed-capacity circular history buffer.
-- Call when you need to create a new ring.
local ok, obj = pcall(function() return lurek.patterns.newRing(nil, "name") end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newRing ok=", ok)

--@api-stub: lurek.patterns.newFunnel
-- Creates a time-windowed event aggregator.
-- window=0 means flush on every push.
local ok, obj = pcall(function() return lurek.patterns.newFunnel(nil, nil, "name") end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newFunnel ok=", ok)

--@api-stub: lurek.patterns.newRelationshipManager
-- Creates a new entity relationship manager.
-- Call when you need to create a new relationship manager.
local ok, obj = pcall(function() return lurek.patterns.newRelationshipManager() end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newRelationshipManager ok=", ok)

--@api-stub: lurek.patterns.newMediator
-- Creates a new named-channel message broker.
-- Call when you need to create a new mediator.
local ok, obj = pcall(function() return lurek.patterns.newMediator() end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newMediator ok=", ok)

--@api-stub: lurek.patterns.newStrategy
-- Creates a new strategy registry.
-- Call when you need to create a new strategy.
local ok, obj = pcall(function() return lurek.patterns.newStrategy() end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newStrategy ok=", ok)

--@api-stub: lurek.patterns.newStack
-- Creates a LIFO stack.
-- capacity=0 means unlimited.
local ok, obj = pcall(function() return lurek.patterns.newStack(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newStack ok=", ok)

--@api-stub: lurek.patterns.newQueue
-- Creates a FIFO queue.
-- capacity=0 means unlimited.
local ok, obj = pcall(function() return lurek.patterns.newQueue(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newQueue ok=", ok)

--@api-stub: lurek.patterns.newList
-- Creates an ordered, resizable list.
-- Call when you need to create a new list.
local ok, obj = pcall(function() return lurek.patterns.newList() end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newList ok=", ok)

--@api-stub: lurek.patterns.newSet
-- Creates an unordered set that rejects duplicate values (by string key).
-- Call when you need to create a new set.
local ok, obj = pcall(function() return lurek.patterns.newSet() end)
if ok and obj then print("created:", obj) end
print("lurek.patterns.newSet ok=", ok)

-- ── EventBus methods ──

--@api-stub: EventBus:on
-- Registers a listener callback for an event.
-- Call when you need to invoke on.
-- Build a EventBus via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newEventBus(...)
if instance then
  local ok, result = pcall(function() return instance:on(nil, function() end, nil) end)
  print("EventBus:on ->", ok, result)
end

--@api-stub: EventBus:off
-- Removes a previously registered event listener by subscription ID.
-- Call when you need to invoke off.
-- Build a EventBus via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newEventBus(...)
if instance then
  local ok, result = pcall(function() return instance:off(1) end)
  print("EventBus:off ->", ok, result)
end

--@api-stub: EventBus:emit
-- Dispatches an event, calling all registered listeners in priority order.
-- Call when you need to invoke emit.
-- Build a EventBus via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newEventBus(...)
if instance then
  local ok, result = pcall(function() return instance:emit({}) end)
  print("EventBus:emit ->", ok, result)
end

--@api-stub: EventBus:clear
-- Removes all listeners for a specific event.
-- Call when you need to invoke clear.
-- Build a EventBus via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newEventBus(...)
if instance then
  local ok, result = pcall(function() return instance:clear(nil) end)
  print("EventBus:clear ->", ok, result)
end

--@api-stub: EventBus:clearAll
-- Removes all listeners on this EventBus.
-- Call when you need to invoke clear all.
-- Build a EventBus via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newEventBus(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("EventBus:clearAll ->", ok, result)
end

--@api-stub: EventBus:getListenerCount
-- Returns the number of listeners registered for an event.
-- Call when you need to read listener count.
-- Build a EventBus via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newEventBus(...)
if instance then
  local ok, result = pcall(function() return instance:getListenerCount(nil) end)
  print("EventBus:getListenerCount ->", ok, result)
end

--@api-stub: EventBus:getEvents
-- Returns all event names that have at least one listener.
-- Call when you need to read events.
-- Build a EventBus via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newEventBus(...)
if instance then
  local ok, result = pcall(function() return instance:getEvents() end)
  print("EventBus:getEvents ->", ok, result)
end

-- ── ObjectPool methods ──

--@api-stub: ObjectPool:add
-- Inserts a pre-built object into the available pool.
-- Call when you need to invoke add.
-- Build a ObjectPool via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObjectPool(...)
if instance then
  local ok, result = pcall(function() return instance:add(nil) end)
  print("ObjectPool:add ->", ok, result)
end

--@api-stub: ObjectPool:acquire
-- Acquires an available object from the pool; returns nil if empty.
-- Call when you need to invoke acquire.
-- Build a ObjectPool via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObjectPool(...)
if instance then
  local ok, result = pcall(function() return instance:acquire() end)
  print("ObjectPool:acquire ->", ok, result)
end

--@api-stub: ObjectPool:release
-- Returns an object to the available pool.
-- Call when you need to invoke release.
-- Build a ObjectPool via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObjectPool(...)
if instance then
  local ok, result = pcall(function() return instance:release(nil) end)
  print("ObjectPool:release ->", ok, result)
end

--@api-stub: ObjectPool:getActiveCount
-- Returns the number of currently active (acquired) objects.
-- Call when you need to read active count.
-- Build a ObjectPool via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObjectPool(...)
if instance then
  local ok, result = pcall(function() return instance:getActiveCount() end)
  print("ObjectPool:getActiveCount ->", ok, result)
end

--@api-stub: ObjectPool:getAvailableCount
-- Returns the number of available (idle) objects in the pool.
-- Call when you need to read available count.
-- Build a ObjectPool via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObjectPool(...)
if instance then
  local ok, result = pcall(function() return instance:getAvailableCount() end)
  print("ObjectPool:getAvailableCount ->", ok, result)
end

--@api-stub: ObjectPool:getTotalCount
-- Returns the total number of tracked objects (active + available).
-- Call when you need to read total count.
-- Build a ObjectPool via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObjectPool(...)
if instance then
  local ok, result = pcall(function() return instance:getTotalCount() end)
  print("ObjectPool:getTotalCount ->", ok, result)
end

--@api-stub: ObjectPool:clearAll
-- Clears all objects from the pool, releasing Lua registry values.
-- Call when you need to invoke clear all.
-- Build a ObjectPool via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObjectPool(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("ObjectPool:clearAll ->", ok, result)
end

-- ── CommandStack methods ──

--@api-stub: CommandStack:execute
-- Executes a named command and records it in undo/redo history.
-- Call when you need to invoke execute.
-- Build a CommandStack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newCommandStack(...)
if instance then
  local ok, result = pcall(function() return instance:execute("name", function() end, function() end) end)
  print("CommandStack:execute ->", ok, result)
end

--@api-stub: CommandStack:undo
-- Undoes the most recent command.
-- Returns true if successful.
-- Build a CommandStack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newCommandStack(...)
if instance then
  local ok, result = pcall(function() return instance:undo() end)
  print("CommandStack:undo ->", ok, result)
end

--@api-stub: CommandStack:redo
-- Re-executes the next undone command.
-- Returns true if successful.
-- Build a CommandStack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newCommandStack(...)
if instance then
  local ok, result = pcall(function() return instance:redo() end)
  print("CommandStack:redo ->", ok, result)
end

--@api-stub: CommandStack:canUndo
-- Returns true if the most recent command can be undone.
-- Call when you need to invoke can undo.
-- Build a CommandStack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newCommandStack(...)
if instance then
  local ok, result = pcall(function() return instance:canUndo() end)
  print("CommandStack:canUndo ->", ok, result)
end

--@api-stub: CommandStack:canRedo
-- Returns true if there is a command available to redo.
-- Call when you need to invoke can redo.
-- Build a CommandStack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newCommandStack(...)
if instance then
  local ok, result = pcall(function() return instance:canRedo() end)
  print("CommandStack:canRedo ->", ok, result)
end

--@api-stub: CommandStack:getHistorySize
-- Returns the total number of recorded commands (undo + redo).
-- Call when you need to read history size.
-- Build a CommandStack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newCommandStack(...)
if instance then
  local ok, result = pcall(function() return instance:getHistorySize() end)
  print("CommandStack:getHistorySize ->", ok, result)
end

--@api-stub: CommandStack:getCurrentName
-- Returns the name of the most recently executed command, or nil.
-- Call when you need to read current name.
-- Build a CommandStack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newCommandStack(...)
if instance then
  local ok, result = pcall(function() return instance:getCurrentName() end)
  print("CommandStack:getCurrentName ->", ok, result)
end

--@api-stub: CommandStack:clearAll
-- Clears all command history, releasing Lua registry values.
-- Call when you need to invoke clear all.
-- Build a CommandStack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newCommandStack(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("CommandStack:clearAll ->", ok, result)
end

-- ── ServiceLocator methods ──

--@api-stub: ServiceLocator:provide
-- Registers a named service with an associated Lua value.
-- Call when you need to invoke provide.
-- Build a ServiceLocator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newServiceLocator(...)
if instance then
  local ok, result = pcall(function() return instance:provide("name", nil) end)
  print("ServiceLocator:provide ->", ok, result)
end

--@api-stub: ServiceLocator:locate
-- Retrieves a registered service by name; returns nil if not found.
-- Call when you need to invoke locate.
-- Build a ServiceLocator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newServiceLocator(...)
if instance then
  local ok, result = pcall(function() return instance:locate("name") end)
  print("ServiceLocator:locate ->", ok, result)
end

--@api-stub: ServiceLocator:has
-- Returns true if a service with the given name is registered.
-- Call when you need to invoke has.
-- Build a ServiceLocator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newServiceLocator(...)
if instance then
  local ok, result = pcall(function() return instance:has("name") end)
  print("ServiceLocator:has ->", ok, result)
end

--@api-stub: ServiceLocator:remove
-- Unregisters and removes a named service.
-- Call when you need to invoke remove.
-- Build a ServiceLocator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newServiceLocator(...)
if instance then
  local ok, result = pcall(function() return instance:remove("name") end)
  print("ServiceLocator:remove ->", ok, result)
end

--@api-stub: ServiceLocator:getServices
-- Returns a table of all registered service names.
-- Call when you need to read services.
-- Build a ServiceLocator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newServiceLocator(...)
if instance then
  local ok, result = pcall(function() return instance:getServices() end)
  print("ServiceLocator:getServices ->", ok, result)
end

--@api-stub: ServiceLocator:clearAll
-- Removes all registered services.
-- Call when you need to invoke clear all.
-- Build a ServiceLocator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newServiceLocator(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("ServiceLocator:clearAll ->", ok, result)
end

-- ── Factory methods ──

--@api-stub: Factory:register
-- Registers a named type constructor function.
-- Call when you need to invoke register.
-- Build a Factory via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFactory(...)
if instance then
  local ok, result = pcall(function() return instance:register("type_name", nil) end)
  print("Factory:register ->", ok, result)
end

--@api-stub: Factory:create
-- Creates an instance of the named type by invoking its constructor.
-- Call when you need to invoke create.
-- Build a Factory via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFactory(...)
if instance then
  local ok, result = pcall(function() return instance:create({}) end)
  print("Factory:create ->", ok, result)
end

--@api-stub: Factory:has
-- Returns true if the named type (or alias) is registered.
-- Call when you need to invoke has.
-- Build a Factory via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFactory(...)
if instance then
  local ok, result = pcall(function() return instance:has("type_name") end)
  print("Factory:has ->", ok, result)
end

--@api-stub: Factory:alias
-- Registers an alias pointing to an existing canonical type name.
-- Call when you need to invoke alias.
-- Build a Factory via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFactory(...)
if instance then
  local ok, result = pcall(function() return instance:alias(nil, nil) end)
  print("Factory:alias ->", ok, result)
end

--@api-stub: Factory:getTypes
-- Returns a table of all registered type names.
-- Call when you need to read types.
-- Build a Factory via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFactory(...)
if instance then
  local ok, result = pcall(function() return instance:getTypes() end)
  print("Factory:getTypes ->", ok, result)
end

--@api-stub: Factory:remove
-- Unregisters a type constructor (and any aliases pointing to it).
-- Call when you need to invoke remove.
-- Build a Factory via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFactory(...)
if instance then
  local ok, result = pcall(function() return instance:remove("type_name") end)
  print("Factory:remove ->", ok, result)
end

--@api-stub: Factory:clearAll
-- Removes all registered type constructors and aliases.
-- Call when you need to invoke clear all.
-- Build a Factory via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFactory(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("Factory:clearAll ->", ok, result)
end

-- ── SimpleState methods ──

--@api-stub: SimpleState:addState
-- Registers a named state with optional enter, exit, and update callbacks.
-- Call when you need to add state.
-- Build a SimpleState via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSimpleState(...)
if instance then
  local ok, result = pcall(function() return instance:addState("name", function() end) end)
  print("SimpleState:addState ->", ok, result)
end

--@api-stub: SimpleState:transitionTo
-- Transitions to a named state, calling exit/enter callbacks as needed.
-- Call when you need to invoke transition to.
-- Build a SimpleState via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSimpleState(...)
if instance then
  local ok, result = pcall(function() return instance:transitionTo("name") end)
  print("SimpleState:transitionTo ->", ok, result)
end

--@api-stub: SimpleState:update
-- Calls the update callback of the current state with the given delta time.
-- Call when you need to invoke update.
-- Build a SimpleState via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSimpleState(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("SimpleState:update ->", ok, result)
end

--@api-stub: SimpleState:getCurrent
-- Returns the name of the current state, or nil if none is active.
-- Call when you need to read current.
-- Build a SimpleState via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSimpleState(...)
if instance then
  local ok, result = pcall(function() return instance:getCurrent() end)
  print("SimpleState:getCurrent ->", ok, result)
end

--@api-stub: SimpleState:hasState
-- Returns true if a state with the given name is registered.
-- Call when you need to check has state.
-- Build a SimpleState via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSimpleState(...)
if instance then
  local ok, result = pcall(function() return instance:hasState("name") end)
  print("SimpleState:hasState ->", ok, result)
end

--@api-stub: SimpleState:getStates
-- Returns a table of all registered state names.
-- Call when you need to read states.
-- Build a SimpleState via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSimpleState(...)
if instance then
  local ok, result = pcall(function() return instance:getStates() end)
  print("SimpleState:getStates ->", ok, result)
end

--@api-stub: SimpleState:clearAll
-- Removes all states and callbacks from this state machine.
-- Call when you need to invoke clear all.
-- Build a SimpleState via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSimpleState(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("SimpleState:clearAll ->", ok, result)
end

-- ── Blackboard methods ──

--@api-stub: Blackboard:set
-- Sets a fact on the blackboard.
-- Accepts boolean, number, or string values.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:set("key", nil) end)
  print("Blackboard:set ->", ok, result)
end

--@api-stub: Blackboard:get
-- Gets a fact from the blackboard.
-- Returns nil if not set.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:get("key") end)
  print("Blackboard:get ->", ok, result)
end

--@api-stub: Blackboard:has
-- Returns true when the key has a non-nil value.
-- Call when you need to invoke has.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:has("key") end)
  print("Blackboard:has ->", ok, result)
end

--@api-stub: Blackboard:clear
-- Removes a fact from the blackboard.
-- Call when you need to invoke clear.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:clear("key") end)
  print("Blackboard:clear ->", ok, result)
end

--@api-stub: Blackboard:keys
-- Returns all set fact keys as a table.
-- Call when you need to invoke keys.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:keys() end)
  print("Blackboard:keys ->", ok, result)
end

--@api-stub: Blackboard:watch
-- Subscribes to changes on a specific key (or "*" for all changes).
-- Call when you need to invoke watch.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:watch("key", function() end) end)
  print("Blackboard:watch ->", ok, result)
end

--@api-stub: Blackboard:unwatch
-- Removes a watcher subscription by id.
-- Call when you need to invoke unwatch.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:unwatch(1) end)
  print("Blackboard:unwatch ->", ok, result)
end

--@api-stub: Blackboard:getRevision
-- Returns the monotonic revision counter (incremented on every write).
-- Call when you need to read revision.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:getRevision() end)
  print("Blackboard:getRevision ->", ok, result)
end

--@api-stub: Blackboard:snapshot
-- Returns all facts as a flat keyâ†’value table.
-- Call when you need to invoke snapshot.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:snapshot() end)
  print("Blackboard:snapshot ->", ok, result)
end

--@api-stub: Blackboard:clearAll
-- Clears all facts from the blackboard.
-- Call when you need to invoke clear all.
-- Build a Blackboard via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newBlackboard(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("Blackboard:clearAll ->", ok, result)
end

-- ── Observer methods ──

--@api-stub: Observer:set
-- Sets a property value and fires subscribed watchers.
-- Call when you need to invoke set.
-- Build a Observer via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObserver(...)
if instance then
  local ok, result = pcall(function() return instance:set("key", nil) end)
  print("Observer:set ->", ok, result)
end

--@api-stub: Observer:get
-- Gets a property value, or nil if not set.
-- Call when you need to invoke get.
-- Build a Observer via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObserver(...)
if instance then
  local ok, result = pcall(function() return instance:get("key") end)
  print("Observer:get ->", ok, result)
end

--@api-stub: Observer:subscribe
-- Subscribes to changes on a property key (or "*" for all).
-- Call when you need to invoke subscribe.
-- Build a Observer via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObserver(...)
if instance then
  local ok, result = pcall(function() return instance:subscribe("key", function() end, nil) end)
  print("Observer:subscribe ->", ok, result)
end

--@api-stub: Observer:unsubscribe
-- Removes a subscription by id.
-- Call when you need to invoke unsubscribe.
-- Build a Observer via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObserver(...)
if instance then
  local ok, result = pcall(function() return instance:unsubscribe(1) end)
  print("Observer:unsubscribe ->", ok, result)
end

--@api-stub: Observer:getCount
-- Returns the total number of active subscriptions.
-- Call when you need to read count.
-- Build a Observer via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newObserver(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("Observer:getCount ->", ok, result)
end

-- ── Throttle methods ──

--@api-stub: Throttle:onFire
-- Sets the callback invoked when the throttle fires.
-- Call when you need to invoke on fire.
-- Build a Throttle via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newThrottle(...)
if instance then
  local ok, result = pcall(function() return instance:onFire(nil) end)
  print("Throttle:onFire ->", ok, result)
end

--@api-stub: Throttle:update
-- Advances the timer by dt seconds; fires the callback if the interval elapsed.
-- Call when you need to invoke update.
-- Build a Throttle via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newThrottle(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Throttle:update ->", ok, result)
end

--@api-stub: Throttle:reset
-- Resets the elapsed counter without firing.
-- Call when you need to invoke reset.
-- Build a Throttle via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newThrottle(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("Throttle:reset ->", ok, result)
end

--@api-stub: Throttle:getProgress
-- Returns the normalised progress through the current interval [0, 1].
-- Call when you need to read progress.
-- Build a Throttle via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newThrottle(...)
if instance then
  local ok, result = pcall(function() return instance:getProgress() end)
  print("Throttle:getProgress ->", ok, result)
end

--@api-stub: Throttle:getFireCount
-- Returns the total number of times this throttle has fired.
-- Call when you need to read fire count.
-- Build a Throttle via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newThrottle(...)
if instance then
  local ok, result = pcall(function() return instance:getFireCount() end)
  print("Throttle:getFireCount ->", ok, result)
end

--@api-stub: Throttle:setEnabled
-- Enables or disables the throttle.
-- Call when you need to assign enabled.
-- Build a Throttle via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newThrottle(...)
if instance then
  local ok, result = pcall(function() return instance:setEnabled(nil) end)
  print("Throttle:setEnabled ->", ok, result)
end

-- ── Debounce methods ──

--@api-stub: Debounce:onFire
-- Sets the callback invoked when the debounce fires.
-- Call when you need to invoke on fire.
-- Build a Debounce via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newDebounce(...)
if instance then
  local ok, result = pcall(function() return instance:onFire(nil) end)
  print("Debounce:onFire ->", ok, result)
end

--@api-stub: Debounce:trigger
-- Records an input event, resetting the idle timer.
-- Call when you need to invoke trigger.
-- Build a Debounce via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newDebounce(...)
if instance then
  local ok, result = pcall(function() return instance:trigger() end)
  print("Debounce:trigger ->", ok, result)
end

--@api-stub: Debounce:update
-- Advances the idle timer by dt seconds; fires the callback if idle wait expired.
-- Call when you need to invoke update.
-- Build a Debounce via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newDebounce(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Debounce:update ->", ok, result)
end

--@api-stub: Debounce:cancel
-- Cancels the pending trigger without firing.
-- Call when you need to invoke cancel.
-- Build a Debounce via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newDebounce(...)
if instance then
  local ok, result = pcall(function() return instance:cancel() end)
  print("Debounce:cancel ->", ok, result)
end

--@api-stub: Debounce:isPending
-- Returns true when a trigger is pending.
-- Call when you need to check is pending.
-- Build a Debounce via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newDebounce(...)
if instance then
  local ok, result = pcall(function() return instance:isPending() end)
  print("Debounce:isPending ->", ok, result)
end

--@api-stub: Debounce:getFireCount
-- Returns the total number of times this debounce has fired.
-- Call when you need to read fire count.
-- Build a Debounce via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newDebounce(...)
if instance then
  local ok, result = pcall(function() return instance:getFireCount() end)
  print("Debounce:getFireCount ->", ok, result)
end

-- ── PriorityQueue methods ──

--@api-stub: PriorityQueue:push
-- Inserts an item with a priority.
-- Higher priorities are dequeued first.
-- Build a PriorityQueue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newPriorityQueue(...)
if instance then
  local ok, result = pcall(function() return instance:push(nil, nil, "label") end)
  print("PriorityQueue:push ->", ok, result)
end

--@api-stub: PriorityQueue:pop
-- Removes and returns the highest-priority item, or nil if empty.
-- Call when you need to invoke pop.
-- Build a PriorityQueue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newPriorityQueue(...)
if instance then
  local ok, result = pcall(function() return instance:pop() end)
  print("PriorityQueue:pop ->", ok, result)
end

--@api-stub: PriorityQueue:peek
-- Returns the highest-priority item without removing it, or nil if empty.
-- Call when you need to invoke peek.
-- Build a PriorityQueue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newPriorityQueue(...)
if instance then
  local ok, result = pcall(function() return instance:peek() end)
  print("PriorityQueue:peek ->", ok, result)
end

--@api-stub: PriorityQueue:len
-- Returns the number of items in the queue.
-- Call when you need to invoke len.
-- Build a PriorityQueue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newPriorityQueue(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("PriorityQueue:len ->", ok, result)
end

--@api-stub: PriorityQueue:isEmpty
-- Returns true when the queue has no items.
-- Call when you need to check is empty.
-- Build a PriorityQueue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newPriorityQueue(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("PriorityQueue:isEmpty ->", ok, result)
end

--@api-stub: PriorityQueue:clearAll
-- Removes all items from the queue.
-- Call when you need to invoke clear all.
-- Build a PriorityQueue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newPriorityQueue(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("PriorityQueue:clearAll ->", ok, result)
end

-- ── Ring methods ──

--@api-stub: Ring:push
-- Pushes a value (number or string) with an optional tag.
-- Overwrites oldest on overflow.
-- Build a Ring via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRing(...)
if instance then
  local ok, result = pcall(function() return instance:push(nil, "tag") end)
  print("Ring:push ->", ok, result)
end

--@api-stub: Ring:latest
-- Returns the most recently pushed entry, or nil.
-- Call when you need to invoke latest.
-- Build a Ring via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRing(...)
if instance then
  local ok, result = pcall(function() return instance:latest() end)
  print("Ring:latest ->", ok, result)
end

--@api-stub: Ring:toArray
-- Returns all entries (oldest first) as an array of {id, tag, value?, text?} tables.
-- Call when you need to invoke to array.
-- Build a Ring via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRing(...)
if instance then
  local ok, result = pcall(function() return instance:toArray() end)
  print("Ring:toArray ->", ok, result)
end

--@api-stub: Ring:sum
-- Returns the sum of all numeric values in the ring.
-- Call when you need to invoke sum.
-- Build a Ring via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRing(...)
if instance then
  local ok, result = pcall(function() return instance:sum() end)
  print("Ring:sum ->", ok, result)
end

--@api-stub: Ring:average
-- Returns the average of all numeric values, or 0 if empty.
-- Call when you need to invoke average.
-- Build a Ring via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRing(...)
if instance then
  local ok, result = pcall(function() return instance:average() end)
  print("Ring:average ->", ok, result)
end

--@api-stub: Ring:len
-- Returns the number of entries currently in the ring.
-- Call when you need to invoke len.
-- Build a Ring via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRing(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("Ring:len ->", ok, result)
end

--@api-stub: Ring:isFull
-- Returns true when the ring is at capacity.
-- Call when you need to check is full.
-- Build a Ring via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRing(...)
if instance then
  local ok, result = pcall(function() return instance:isFull() end)
  print("Ring:isFull ->", ok, result)
end

--@api-stub: Ring:clear
-- Removes all entries from the ring.
-- Call when you need to invoke clear.
-- Build a Ring via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRing(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Ring:clear ->", ok, result)
end

-- ── Funnel methods ──

--@api-stub: Funnel:onFlush
-- Sets a callback invoked when the funnel flushes.
-- Receives a table of {tag, value} entries.
-- Build a Funnel via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFunnel(...)
if instance then
  local ok, result = pcall(function() return instance:onFlush(nil) end)
  print("Funnel:onFlush ->", ok, result)
end

--@api-stub: Funnel:push
-- Adds an event to the funnel.
-- Immediately flushes if max_entries reached or window is 0.
-- Build a Funnel via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFunnel(...)
if instance then
  local ok, result = pcall(function() return instance:push("tag", nil) end)
  print("Funnel:push ->", ok, result)
end

--@api-stub: Funnel:update
-- Advances the window timer by dt seconds; flushes when window expires.
-- Call when you need to invoke update.
-- Build a Funnel via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFunnel(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Funnel:update ->", ok, result)
end

--@api-stub: Funnel:flush
-- Manually flushes all pending entries, invoking the onFlush callback.
-- Call when you need to invoke flush.
-- Build a Funnel via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFunnel(...)
if instance then
  local ok, result = pcall(function() return instance:flush() end)
  print("Funnel:flush ->", ok, result)
end

--@api-stub: Funnel:discard
-- Discards all buffered entries without flushing.
-- Call when you need to invoke discard.
-- Build a Funnel via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFunnel(...)
if instance then
  local ok, result = pcall(function() return instance:discard() end)
  print("Funnel:discard ->", ok, result)
end

--@api-stub: Funnel:pendingCount
-- Returns the number of buffered entries not yet flushed.
-- Call when you need to invoke pending count.
-- Build a Funnel via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFunnel(...)
if instance then
  local ok, result = pcall(function() return instance:pendingCount() end)
  print("Funnel:pendingCount ->", ok, result)
end

--@api-stub: Funnel:getFlushCount
-- Returns the total number of flushes performed.
-- Call when you need to read flush count.
-- Build a Funnel via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newFunnel(...)
if instance then
  local ok, result = pcall(function() return instance:getFlushCount() end)
  print("Funnel:getFlushCount ->", ok, result)
end

-- ── RelationshipManager methods ──

--@api-stub: RelationshipManager:defineType
-- Defines a relationship type with ordered levels.
-- Call when you need to invoke define type.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:defineType("name", nil, nil) end)
  print("RelationshipManager:defineType ->", ok, result)
end

--@api-stub: RelationshipManager:removeType
-- Removes a relationship type definition.
-- Call when you need to remove type.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:removeType("name") end)
  print("RelationshipManager:removeType ->", ok, result)
end

--@api-stub: RelationshipManager:typeNames
-- Returns all defined relationship type names.
-- Call when you need to invoke type names.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:typeNames() end)
  print("RelationshipManager:typeNames ->", ok, result)
end

--@api-stub: RelationshipManager:setValue
-- Sets the numeric relationship value between two entities.
-- Call when you need to assign value.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:setValue(1, 1, nil) end)
  print("RelationshipManager:setValue ->", ok, result)
end

--@api-stub: RelationshipManager:getValue
-- Returns the numeric relationship value between two entities (default 0.0).
-- Call when you need to read value.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:getValue(1, 1) end)
  print("RelationshipManager:getValue ->", ok, result)
end

--@api-stub: RelationshipManager:adjustValue
-- Adjusts the numeric relationship value by a delta.
-- Call when you need to invoke adjust value.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:adjustValue(1, 1, 1.0) end)
  print("RelationshipManager:adjustValue ->", ok, result)
end

--@api-stub: RelationshipManager:setLevel
-- Sets a named level for a typed relationship between two entities.
-- Call when you need to assign level.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:setLevel(1, 1, "type_name", nil) end)
  print("RelationshipManager:setLevel ->", ok, result)
end

--@api-stub: RelationshipManager:getLevel
-- Returns the named level for a typed relationship, or nil.
-- Call when you need to read level.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:getLevel(1, 1, "type_name") end)
  print("RelationshipManager:getLevel ->", ok, result)
end

--@api-stub: RelationshipManager:removePair
-- Removes all relationship data between two entities.
-- Call when you need to remove pair.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:removePair(1, 1) end)
  print("RelationshipManager:removePair ->", ok, result)
end

--@api-stub: RelationshipManager:pairCount
-- Returns the total number of stored relationship pairs.
-- Call when you need to invoke pair count.
-- Build a RelationshipManager via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newRelationshipManager(...)
if instance then
  local ok, result = pcall(function() return instance:pairCount() end)
  print("RelationshipManager:pairCount ->", ok, result)
end

-- ── Mediator methods ──

--@api-stub: Mediator:on
-- Registers a handler callback on a channel; returns handler ID.
-- Call when you need to invoke on.
-- Build a Mediator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newMediator(...)
if instance then
  local ok, result = pcall(function() return instance:on(nil, function() end) end)
  print("Mediator:on ->", ok, result)
end

--@api-stub: Mediator:off
-- Unregisters a handler by ID.
-- Call when you need to invoke off.
-- Build a Mediator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newMediator(...)
if instance then
  local ok, result = pcall(function() return instance:off(nil, 1) end)
  print("Mediator:off ->", ok, result)
end

--@api-stub: Mediator:send
-- Dispatches a message to all handlers on a channel.
-- Call when you need to invoke send.
-- Build a Mediator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newMediator(...)
if instance then
  local ok, result = pcall(function() return instance:send({}) end)
  print("Mediator:send ->", ok, result)
end

--@api-stub: Mediator:broadcast
-- Dispatches a message to all handlers across all channels.
-- Call when you need to invoke broadcast.
-- Build a Mediator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newMediator(...)
if instance then
  local ok, result = pcall(function() return instance:broadcast({}) end)
  print("Mediator:broadcast ->", ok, result)
end

--@api-stub: Mediator:handlerCount
-- Returns the number of handlers on a channel.
-- Call when you need to invoke handler count.
-- Build a Mediator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newMediator(...)
if instance then
  local ok, result = pcall(function() return instance:handlerCount(nil) end)
  print("Mediator:handlerCount ->", ok, result)
end

--@api-stub: Mediator:channels
-- Returns all registered channel names.
-- Call when you need to invoke channels.
-- Build a Mediator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newMediator(...)
if instance then
  local ok, result = pcall(function() return instance:channels() end)
  print("Mediator:channels ->", ok, result)
end

--@api-stub: Mediator:removeChannel
-- Removes a channel and all its handlers.
-- Call when you need to remove channel.
-- Build a Mediator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newMediator(...)
if instance then
  local ok, result = pcall(function() return instance:removeChannel(nil) end)
  print("Mediator:removeChannel ->", ok, result)
end

--@api-stub: Mediator:clear
-- Removes all channels and handlers.
-- Call when you need to invoke clear.
-- Build a Mediator via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newMediator(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Mediator:clear ->", ok, result)
end

-- ── Strategy methods ──

--@api-stub: Strategy:register
-- Registers a named strategy function.
-- Call when you need to invoke register.
-- Build a Strategy via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStrategy(...)
if instance then
  local ok, result = pcall(function() return instance:register("name", function() end) end)
  print("Strategy:register ->", ok, result)
end

--@api-stub: Strategy:set
-- Sets the active strategy by name.
-- Returns false if not registered.
-- Build a Strategy via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStrategy(...)
if instance then
  local ok, result = pcall(function() return instance:set("name") end)
  print("Strategy:set ->", ok, result)
end

--@api-stub: Strategy:execute
-- Calls the currently active strategy function with the given arguments.
-- Call when you need to invoke execute.
-- Build a Strategy via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStrategy(...)
if instance then
  local ok, result = pcall(function() return instance:execute({}) end)
  print("Strategy:execute ->", ok, result)
end

--@api-stub: Strategy:getCurrent
-- Returns the name of the active strategy, or nil.
-- Call when you need to read current.
-- Build a Strategy via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStrategy(...)
if instance then
  local ok, result = pcall(function() return instance:getCurrent() end)
  print("Strategy:getCurrent ->", ok, result)
end

--@api-stub: Strategy:has
-- Returns true if a strategy with this name is registered.
-- Call when you need to invoke has.
-- Build a Strategy via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStrategy(...)
if instance then
  local ok, result = pcall(function() return instance:has("name") end)
  print("Strategy:has ->", ok, result)
end

--@api-stub: Strategy:remove
-- Removes a strategy by name.
-- Call when you need to invoke remove.
-- Build a Strategy via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStrategy(...)
if instance then
  local ok, result = pcall(function() return instance:remove("name") end)
  print("Strategy:remove ->", ok, result)
end

--@api-stub: Strategy:names
-- Returns all registered strategy names.
-- Call when you need to invoke names.
-- Build a Strategy via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStrategy(...)
if instance then
  local ok, result = pcall(function() return instance:names() end)
  print("Strategy:names ->", ok, result)
end

--@api-stub: Strategy:clear
-- Removes all strategies and clears the active selection.
-- Call when you need to invoke clear.
-- Build a Strategy via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStrategy(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Strategy:clear ->", ok, result)
end

-- ── Stack methods ──

--@api-stub: Stack:push
-- Pushes a value onto the stack.
-- Returns false if capacity is full.
-- Build a Stack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStack(...)
if instance then
  local ok, result = pcall(function() return instance:push(nil) end)
  print("Stack:push ->", ok, result)
end

--@api-stub: Stack:pop
-- Removes and returns the top value, or nil if empty.
-- Call when you need to invoke pop.
-- Build a Stack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStack(...)
if instance then
  local ok, result = pcall(function() return instance:pop() end)
  print("Stack:pop ->", ok, result)
end

--@api-stub: Stack:peek
-- Returns the top value without removing it, or nil if empty.
-- Call when you need to invoke peek.
-- Build a Stack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStack(...)
if instance then
  local ok, result = pcall(function() return instance:peek() end)
  print("Stack:peek ->", ok, result)
end

--@api-stub: Stack:len
-- Returns the number of items on the stack.
-- Call when you need to invoke len.
-- Build a Stack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStack(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("Stack:len ->", ok, result)
end

--@api-stub: Stack:isEmpty
-- Returns true if the stack is empty.
-- Call when you need to check is empty.
-- Build a Stack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStack(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("Stack:isEmpty ->", ok, result)
end

--@api-stub: Stack:isFull
-- Returns true if the stack is at its capacity limit.
-- Call when you need to check is full.
-- Build a Stack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStack(...)
if instance then
  local ok, result = pcall(function() return instance:isFull() end)
  print("Stack:isFull ->", ok, result)
end

--@api-stub: Stack:clear
-- Removes all values from the stack.
-- Call when you need to invoke clear.
-- Build a Stack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStack(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Stack:clear ->", ok, result)
end

--@api-stub: Stack:toArray
-- Returns all items as a Lua table (bottom to top).
-- Call when you need to invoke to array.
-- Build a Stack via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newStack(...)
if instance then
  local ok, result = pcall(function() return instance:toArray() end)
  print("Stack:toArray ->", ok, result)
end

-- ── Queue methods ──

--@api-stub: Queue:enqueue
-- Adds a value to the back of the queue.
-- Returns false if capacity is full.
-- Build a Queue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newQueue(...)
if instance then
  local ok, result = pcall(function() return instance:enqueue(nil) end)
  print("Queue:enqueue ->", ok, result)
end

--@api-stub: Queue:dequeue
-- Removes and returns the front value, or nil if empty.
-- Call when you need to invoke dequeue.
-- Build a Queue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newQueue(...)
if instance then
  local ok, result = pcall(function() return instance:dequeue() end)
  print("Queue:dequeue ->", ok, result)
end

--@api-stub: Queue:front
-- Returns the front value without removing it, or nil if empty.
-- Call when you need to invoke front.
-- Build a Queue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newQueue(...)
if instance then
  local ok, result = pcall(function() return instance:front() end)
  print("Queue:front ->", ok, result)
end

--@api-stub: Queue:len
-- Returns the number of items in the queue.
-- Call when you need to invoke len.
-- Build a Queue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newQueue(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("Queue:len ->", ok, result)
end

--@api-stub: Queue:isEmpty
-- Returns true if the queue is empty.
-- Call when you need to check is empty.
-- Build a Queue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newQueue(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("Queue:isEmpty ->", ok, result)
end

--@api-stub: Queue:isFull
-- Returns true if the queue is at its capacity limit.
-- Call when you need to check is full.
-- Build a Queue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newQueue(...)
if instance then
  local ok, result = pcall(function() return instance:isFull() end)
  print("Queue:isFull ->", ok, result)
end

--@api-stub: Queue:clear
-- Removes all values from the queue.
-- Call when you need to invoke clear.
-- Build a Queue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newQueue(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Queue:clear ->", ok, result)
end

--@api-stub: Queue:toArray
-- Returns all items as a Lua table (front to back).
-- Call when you need to invoke to array.
-- Build a Queue via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newQueue(...)
if instance then
  local ok, result = pcall(function() return instance:toArray() end)
  print("Queue:toArray ->", ok, result)
end

-- ── List methods ──

--@api-stub: List:add
-- Appends a value to the end of the list.
-- Call when you need to invoke add.
-- Build a List via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newList(...)
if instance then
  local ok, result = pcall(function() return instance:add(nil) end)
  print("List:add ->", ok, result)
end

--@api-stub: List:get
-- Returns the value at a 1-based index, or nil.
-- Call when you need to invoke get.
-- Build a List via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newList(...)
if instance then
  local ok, result = pcall(function() return instance:get(1) end)
  print("List:get ->", ok, result)
end

--@api-stub: List:set
-- Replaces the value at a 1-based index.
-- Call when you need to invoke set.
-- Build a List via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newList(...)
if instance then
  local ok, result = pcall(function() return instance:set(1, nil) end)
  print("List:set ->", ok, result)
end

--@api-stub: List:remove
-- Removes and returns the value at a 1-based index.
-- Call when you need to invoke remove.
-- Build a List via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newList(...)
if instance then
  local ok, result = pcall(function() return instance:remove(1) end)
  print("List:remove ->", ok, result)
end

--@api-stub: List:len
-- Returns the number of items in the list.
-- Call when you need to invoke len.
-- Build a List via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newList(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("List:len ->", ok, result)
end

--@api-stub: List:isEmpty
-- Returns true if the list is empty.
-- Call when you need to check is empty.
-- Build a List via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newList(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("List:isEmpty ->", ok, result)
end

--@api-stub: List:contains
-- Returns true if the list contains a value equal to the given Lua value (string/number/boolean).
-- Call when you need to invoke contains.
-- Build a List via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newList(...)
if instance then
  local ok, result = pcall(function() return instance:contains(nil) end)
  print("List:contains ->", ok, result)
end

--@api-stub: List:clear
-- Removes all values from the list.
-- Call when you need to invoke clear.
-- Build a List via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newList(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("List:clear ->", ok, result)
end

--@api-stub: List:toArray
-- Returns all items as a Lua table.
-- Call when you need to invoke to array.
-- Build a List via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newList(...)
if instance then
  local ok, result = pcall(function() return instance:toArray() end)
  print("List:toArray ->", ok, result)
end

-- ── Set methods ──

--@api-stub: Set:add
-- Adds a string key to the set.
-- Returns true if it was not already present.
-- Build a Set via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSet(...)
if instance then
  local ok, result = pcall(function() return instance:add("key") end)
  print("Set:add ->", ok, result)
end

--@api-stub: Set:remove
-- Removes a key from the set.
-- Returns true if it was present.
-- Build a Set via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSet(...)
if instance then
  local ok, result = pcall(function() return instance:remove("key") end)
  print("Set:remove ->", ok, result)
end

--@api-stub: Set:has
-- Returns true if the key is in the set.
-- Call when you need to invoke has.
-- Build a Set via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSet(...)
if instance then
  local ok, result = pcall(function() return instance:has("key") end)
  print("Set:has ->", ok, result)
end

--@api-stub: Set:len
-- Returns the number of distinct keys in the set.
-- Call when you need to invoke len.
-- Build a Set via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSet(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("Set:len ->", ok, result)
end

--@api-stub: Set:isEmpty
-- Returns true if the set is empty.
-- Call when you need to check is empty.
-- Build a Set via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSet(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("Set:isEmpty ->", ok, result)
end

--@api-stub: Set:toArray
-- Returns all keys as a Lua table (unordered).
-- Call when you need to invoke to array.
-- Build a Set via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSet(...)
if instance then
  local ok, result = pcall(function() return instance:toArray() end)
  print("Set:toArray ->", ok, result)
end

--@api-stub: Set:clear
-- Removes all keys from the set.
-- Call when you need to invoke clear.
-- Build a Set via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSet(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Set:clear ->", ok, result)
end

--@api-stub: Set:union
-- Returns the union of this set and another as a new Set.
-- Call when you need to invoke union.
-- Build a Set via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSet(...)
if instance then
  local ok, result = pcall(function() return instance:union(nil) end)
  print("Set:union ->", ok, result)
end

--@api-stub: Set:intersection
-- Returns the intersection of this set and another as a new Set.
-- Call when you need to invoke intersection.
-- Build a Set via the appropriate lurek.patterns.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.patterns.newSet(...)
if instance then
  local ok, result = pcall(function() return instance:intersection(nil) end)
  print("Set:intersection ->", ok, result)
end

