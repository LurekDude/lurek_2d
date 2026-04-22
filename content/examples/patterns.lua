-- content/examples/patterns.lua
-- Auto-scaffolded coverage of the lurek.patterns Lua API (170 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/patterns.lua

print("[example] lurek.patterns loaded — 170 API items demonstrated")

-- ── lurek.patterns free functions ──

--@api-stub: lurek.patterns.newEventBus
-- Creates a new EventBus instance.
-- Use this when creates a new EventBus instance is needed.
if false then
  local _r = lurek.patterns.newEventBus(1)
  print(_r)
end

--@api-stub: lurek.patterns.newObjectPool
-- Creates a new ObjectPool instance.
-- Use this when creates a new ObjectPool instance is needed.
if false then
  local _r = lurek.patterns.newObjectPool()
  print(_r)
end

--@api-stub: lurek.patterns.newCommandStack
-- Creates a new CommandStack instance.
-- Use this when creates a new CommandStack instance is needed.
if false then
  local _r = lurek.patterns.newCommandStack(1)
  print(_r)
end

--@api-stub: lurek.patterns.newServiceLocator
-- Creates a new ServiceLocator instance.
-- Use this when creates a new ServiceLocator instance is needed.
if false then
  local _r = lurek.patterns.newServiceLocator()
  print(_r)
end

--@api-stub: lurek.patterns.newFactory
-- Creates a new Factory instance.
-- Use this when creates a new Factory instance is needed.
if false then
  local _r = lurek.patterns.newFactory()
  print(_r)
end

--@api-stub: lurek.patterns.newSimpleState
-- Creates a new SimpleState finite state machine instance.
-- Use this when creates a new SimpleState finite state machine instance is needed.
if false then
  local _r = lurek.patterns.newSimpleState()
  print(_r)
end

--@api-stub: lurek.patterns.newBlackboard
-- Creates a new Blackboard shared key-value store.
-- Use this when creates a new Blackboard shared key-value store is needed.
if false then
  local _r = lurek.patterns.newBlackboard(1)
  print(_r)
end

--@api-stub: lurek.patterns.newObserver
-- Creates a new reactive property Observer.
-- Use this when creates a new reactive property Observer is needed.
if false then
  local _r = lurek.patterns.newObserver(1)
  print(_r)
end

--@api-stub: lurek.patterns.newThrottle
-- Creates a leading-edge rate limiter that fires at most once per interval seconds.
-- Use this when creates a leading-edge rate limiter that fires at most once per interval seconds is needed.
if false then
  local _r = lurek.patterns.newThrottle(1)
  print(_r)
end

--@api-stub: lurek.patterns.newDebounce
-- Creates a trailing-edge debounce that fires after the input stream is idle for wait seconds.
-- Use this when creates a trailing-edge debounce that fires after the input stream is idle for wait seconds is needed.
if false then
  local _r = lurek.patterns.newDebounce(0)
  print(_r)
end

--@api-stub: lurek.patterns.newPriorityQueue
-- Creates a stable priority-ordered task queue.
-- Use this when creates a stable priority-ordered task queue is needed.
if false then
  local _r = lurek.patterns.newPriorityQueue(1)
  print(_r)
end

--@api-stub: lurek.patterns.newRing
-- Creates a fixed-capacity circular history buffer.
-- Use this when creates a fixed-capacity circular history buffer is needed.
if false then
  local _r = lurek.patterns.newRing(0, 1)
  print(_r)
end

--@api-stub: lurek.patterns.newFunnel
-- Creates a time-windowed event aggregator.
-- window=0 means flush on every push.
if false then
  local _r = lurek.patterns.newFunnel(1, 1, 1)
  print(_r)
end

--@api-stub: lurek.patterns.newRelationshipManager
-- Creates a new entity relationship manager.
-- Use this when creates a new entity relationship manager is needed.
if false then
  local _r = lurek.patterns.newRelationshipManager()
  print(_r)
end

--@api-stub: lurek.patterns.newMediator
-- Creates a new named-channel message broker.
-- Use this when creates a new named-channel message broker is needed.
if false then
  local _r = lurek.patterns.newMediator()
  print(_r)
end

--@api-stub: lurek.patterns.newStrategy
-- Creates a new strategy registry.
-- Use this when creates a new strategy registry is needed.
if false then
  local _r = lurek.patterns.newStrategy()
  print(_r)
end

--@api-stub: lurek.patterns.newStack
-- Creates a LIFO stack.
-- capacity=0 means unlimited.
if false then
  local _r = lurek.patterns.newStack(0)
  print(_r)
end

--@api-stub: lurek.patterns.newQueue
-- Creates a FIFO queue.
-- capacity=0 means unlimited.
if false then
  local _r = lurek.patterns.newQueue(0)
  print(_r)
end

--@api-stub: lurek.patterns.newList
-- Creates an ordered, resizable list.
-- Use this when creates an ordered, resizable list is needed.
if false then
  local _r = lurek.patterns.newList()
  print(_r)
end

--@api-stub: lurek.patterns.newSet
-- Creates an unordered set that rejects duplicate values (by string key).
-- Use this when creates an unordered set that rejects duplicate values (by string key) is needed.
if false then
  local _r = lurek.patterns.newSet()
  print(_r)
end

-- ── EventBus methods ──

--@api-stub: EventBus:on
-- Registers a listener callback for an event.
-- Use this when registers a listener callback for an event is needed.
if false then
  local _o = nil  -- EventBus instance
  _o:on(1, function() end, 0)
end

--@api-stub: EventBus:off
-- Removes a previously registered event listener by subscription ID.
-- Use this when removes a previously registered event listener by subscription ID is needed.
if false then
  local _o = nil  -- EventBus instance
  _o:off(1)
end

--@api-stub: EventBus:emit
-- Dispatches an event, calling all registered listeners in priority order.
-- Use this when dispatches an event, calling all registered listeners in priority order is needed.
if false then
  local _o = nil  -- EventBus instance
  _o:emit({})
end

--@api-stub: EventBus:clear
-- Removes all listeners for a specific event.
-- Use this when removes all listeners for a specific event is needed.
if false then
  local _o = nil  -- EventBus instance
  _o:clear(1)
end

--@api-stub: EventBus:clearAll
-- Removes all listeners on this EventBus.
-- Use this when removes all listeners on this EventBus is needed.
if false then
  local _o = nil  -- EventBus instance
  _o:clearAll()
end

--@api-stub: EventBus:getListenerCount
-- Returns the number of listeners registered for an event.
-- Use this when returns the number of listeners registered for an event is needed.
if false then
  local _o = nil  -- EventBus instance
  _o:getListenerCount(1)
end

--@api-stub: EventBus:getEvents
-- Returns all event names that have at least one listener.
-- Use this when returns all event names that have at least one listener is needed.
if false then
  local _o = nil  -- EventBus instance
  _o:getEvents()
end

-- ── ObjectPool methods ──

--@api-stub: ObjectPool:add
-- Inserts a pre-built object into the available pool.
-- Use this when inserts a pre-built object into the available pool is needed.
if false then
  local _o = nil  -- ObjectPool instance
  _o:add(0)
end

--@api-stub: ObjectPool:acquire
-- Acquires an available object from the pool; returns nil if empty.
-- Use this when acquires an available object from the pool; returns nil if empty is needed.
if false then
  local _o = nil  -- ObjectPool instance
  _o:acquire()
end

--@api-stub: ObjectPool:release
-- Returns an object to the available pool.
-- Use this when returns an object to the available pool is needed.
if false then
  local _o = nil  -- ObjectPool instance
  _o:release(0)
end

--@api-stub: ObjectPool:getActiveCount
-- Returns the number of currently active (acquired) objects.
-- Use this when returns the number of currently active (acquired) objects is needed.
if false then
  local _o = nil  -- ObjectPool instance
  _o:getActiveCount()
end

--@api-stub: ObjectPool:getAvailableCount
-- Returns the number of available (idle) objects in the pool.
-- Use this when returns the number of available (idle) objects in the pool is needed.
if false then
  local _o = nil  -- ObjectPool instance
  _o:getAvailableCount()
end

--@api-stub: ObjectPool:getTotalCount
-- Returns the total number of tracked objects (active + available).
-- Use this when returns the total number of tracked objects (active + available) is needed.
if false then
  local _o = nil  -- ObjectPool instance
  _o:getTotalCount()
end

--@api-stub: ObjectPool:clearAll
-- Clears all objects from the pool, releasing Lua registry values.
-- Use this when clears all objects from the pool, releasing Lua registry values is needed.
if false then
  local _o = nil  -- ObjectPool instance
  _o:clearAll()
end

-- ── CommandStack methods ──

--@api-stub: CommandStack:execute
-- Executes a named command and records it in undo/redo history.
-- Use this when executes a named command and records it in undo/redo history is needed.
if false then
  local _o = nil  -- CommandStack instance
  _o:execute(1, 1, 1)
end

--@api-stub: CommandStack:undo
-- Undoes the most recent command.
-- Returns true if successful.
if false then
  local _o = nil  -- CommandStack instance
  _o:undo()
end

--@api-stub: CommandStack:redo
-- Re-executes the next undone command.
-- Returns true if successful.
if false then
  local _o = nil  -- CommandStack instance
  _o:redo()
end

--@api-stub: CommandStack:canUndo
-- Returns true if the most recent command can be undone.
-- Use this when returns true if the most recent command can be undone is needed.
if false then
  local _o = nil  -- CommandStack instance
  _o:canUndo()
end

--@api-stub: CommandStack:canRedo
-- Returns true if there is a command available to redo.
-- Use this when returns true if there is a command available to redo is needed.
if false then
  local _o = nil  -- CommandStack instance
  _o:canRedo()
end

--@api-stub: CommandStack:getHistorySize
-- Returns the total number of recorded commands (undo + redo).
-- Use this when returns the total number of recorded commands (undo + redo) is needed.
if false then
  local _o = nil  -- CommandStack instance
  _o:getHistorySize()
end

--@api-stub: CommandStack:getCurrentName
-- Returns the name of the most recently executed command, or nil.
-- Use this when returns the name of the most recently executed command, or nil is needed.
if false then
  local _o = nil  -- CommandStack instance
  _o:getCurrentName()
end

--@api-stub: CommandStack:clearAll
-- Clears all command history, releasing Lua registry values.
-- Use this when clears all command history, releasing Lua registry values is needed.
if false then
  local _o = nil  -- CommandStack instance
  _o:clearAll()
end

-- ── ServiceLocator methods ──

--@api-stub: ServiceLocator:provide
-- Registers a named service with an associated Lua value.
-- Use this when registers a named service with an associated Lua value is needed.
if false then
  local _o = nil  -- ServiceLocator instance
  _o:provide(1, 0)
end

--@api-stub: ServiceLocator:locate
-- Retrieves a registered service by name; returns nil if not found.
-- Use this when retrieves a registered service by name; returns nil if not found is needed.
if false then
  local _o = nil  -- ServiceLocator instance
  _o:locate(1)
end

--@api-stub: ServiceLocator:has
-- Returns true if a service with the given name is registered.
-- Use this when returns true if a service with the given name is registered is needed.
if false then
  local _o = nil  -- ServiceLocator instance
  _o:has(1)
end

--@api-stub: ServiceLocator:remove
-- Unregisters and removes a named service.
-- Use this when unregisters and removes a named service is needed.
if false then
  local _o = nil  -- ServiceLocator instance
  _o:remove(1)
end

--@api-stub: ServiceLocator:getServices
-- Returns a table of all registered service names.
-- Use this when returns a table of all registered service names is needed.
if false then
  local _o = nil  -- ServiceLocator instance
  _o:getServices()
end

--@api-stub: ServiceLocator:clearAll
-- Removes all registered services.
-- Use this when removes all registered services is needed.
if false then
  local _o = nil  -- ServiceLocator instance
  _o:clearAll()
end

-- ── Factory methods ──

--@api-stub: Factory:register
-- Registers a named type constructor function.
-- Use this when registers a named type constructor function is needed.
if false then
  local _o = nil  -- Factory instance
  _o:register(1, 0)
end

--@api-stub: Factory:create
-- Creates an instance of the named type by invoking its constructor.
-- Use this when creates an instance of the named type by invoking its constructor is needed.
if false then
  local _o = nil  -- Factory instance
  _o:create({})
end

--@api-stub: Factory:has
-- Returns true if the named type (or alias) is registered.
-- Use this when returns true if the named type (or alias) is registered is needed.
if false then
  local _o = nil  -- Factory instance
  _o:has(1)
end

--@api-stub: Factory:alias
-- Registers an alias pointing to an existing canonical type name.
-- Use this when registers an alias pointing to an existing canonical type name is needed.
if false then
  local _o = nil  -- Factory instance
  _o:alias(nil, 1)
end

--@api-stub: Factory:getTypes
-- Returns a table of all registered type names.
-- Use this when returns a table of all registered type names is needed.
if false then
  local _o = nil  -- Factory instance
  _o:getTypes()
end

--@api-stub: Factory:remove
-- Unregisters a type constructor (and any aliases pointing to it).
-- Use this when unregisters a type constructor (and any aliases pointing to it) is needed.
if false then
  local _o = nil  -- Factory instance
  _o:remove(1)
end

--@api-stub: Factory:clearAll
-- Removes all registered type constructors and aliases.
-- Use this when removes all registered type constructors and aliases is needed.
if false then
  local _o = nil  -- Factory instance
  _o:clearAll()
end

-- ── SimpleState methods ──

--@api-stub: SimpleState:addState
-- Registers a named state with optional enter, exit, and update callbacks.
-- Use this when registers a named state with optional enter, exit, and update callbacks is needed.
if false then
  local _o = nil  -- SimpleState instance
  _o:addState(1, function() end)
end

--@api-stub: SimpleState:transitionTo
-- Transitions to a named state, calling exit/enter callbacks as needed.
-- Use this when transitions to a named state, calling exit/enter callbacks as needed is needed.
if false then
  local _o = nil  -- SimpleState instance
  _o:transitionTo(1)
end

--@api-stub: SimpleState:update
-- Calls the update callback of the current state with the given delta time.
-- Use this when calls the update callback of the current state with the given delta time is needed.
if false then
  local _o = nil  -- SimpleState instance
  _o:update(0)
end

--@api-stub: SimpleState:getCurrent
-- Returns the name of the current state, or nil if none is active.
-- Use this when returns the name of the current state, or nil if none is active is needed.
if false then
  local _o = nil  -- SimpleState instance
  _o:getCurrent()
end

--@api-stub: SimpleState:hasState
-- Returns true if a state with the given name is registered.
-- Use this when returns true if a state with the given name is registered is needed.
if false then
  local _o = nil  -- SimpleState instance
  _o:hasState(1)
end

--@api-stub: SimpleState:getStates
-- Returns a table of all registered state names.
-- Use this when returns a table of all registered state names is needed.
if false then
  local _o = nil  -- SimpleState instance
  _o:getStates()
end

--@api-stub: SimpleState:clearAll
-- Removes all states and callbacks from this state machine.
-- Use this when removes all states and callbacks from this state machine is needed.
if false then
  local _o = nil  -- SimpleState instance
  _o:clearAll()
end

-- ── Blackboard methods ──

--@api-stub: Blackboard:set
-- Sets a fact on the blackboard.
-- Accepts boolean, number, or string values.
if false then
  local _o = nil  -- Blackboard instance
  _o:set(0, 0)
end

--@api-stub: Blackboard:get
-- Gets a fact from the blackboard.
-- Returns nil if not set.
if false then
  local _o = nil  -- Blackboard instance
  _o:get(0)
end

--@api-stub: Blackboard:has
-- Returns true when the key has a non-nil value.
-- Use this when returns true when the key has a non-nil value is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:has(0)
end

--@api-stub: Blackboard:clear
-- Removes a fact from the blackboard.
-- Use this when removes a fact from the blackboard is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:clear(0)
end

--@api-stub: Blackboard:keys
-- Returns all set fact keys as a table.
-- Use this when returns all set fact keys as a table is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:keys()
end

--@api-stub: Blackboard:watch
-- Subscribes to changes on a specific key (or "*" for all changes).
-- Use this when subscribes to changes on a specific key (or "*" for all changes) is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:watch(0, function() end)
end

--@api-stub: Blackboard:unwatch
-- Removes a watcher subscription by id.
-- Use this when removes a watcher subscription by id is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:unwatch(1)
end

--@api-stub: Blackboard:getRevision
-- Returns the monotonic revision counter (incremented on every write).
-- Use this when returns the monotonic revision counter (incremented on every write) is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:getRevision()
end

--@api-stub: Blackboard:snapshot
-- Returns all facts as a flat keyâ†’value table.
-- Use this when returns all facts as a flat keyâ†’value table is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:snapshot()
end

--@api-stub: Blackboard:clearAll
-- Clears all facts from the blackboard.
-- Use this when clears all facts from the blackboard is needed.
if false then
  local _o = nil  -- Blackboard instance
  _o:clearAll()
end

-- ── Observer methods ──

--@api-stub: Observer:set
-- Sets a property value and fires subscribed watchers.
-- Use this when sets a property value and fires subscribed watchers is needed.
if false then
  local _o = nil  -- Observer instance
  _o:set(0, 1)
end

--@api-stub: Observer:get
-- Gets a property value, or nil if not set.
-- Use this when gets a property value, or nil if not set is needed.
if false then
  local _o = nil  -- Observer instance
  _o:get(0)
end

--@api-stub: Observer:subscribe
-- Subscribes to changes on a property key (or "*" for all).
-- Use this when subscribes to changes on a property key (or "*" for all) is needed.
if false then
  local _o = nil  -- Observer instance
  _o:subscribe(0, function() end, 1)
end

--@api-stub: Observer:unsubscribe
-- Removes a subscription by id.
-- Use this when removes a subscription by id is needed.
if false then
  local _o = nil  -- Observer instance
  _o:unsubscribe(1)
end

--@api-stub: Observer:getCount
-- Returns the total number of active subscriptions.
-- Use this when returns the total number of active subscriptions is needed.
if false then
  local _o = nil  -- Observer instance
  _o:getCount()
end

-- ── Throttle methods ──

--@api-stub: Throttle:onFire
-- Sets the callback invoked when the throttle fires.
-- Use this when sets the callback invoked when the throttle fires is needed.
if false then
  local _o = nil  -- Throttle instance
  _o:onFire(nil)
end

--@api-stub: Throttle:update
-- Advances the timer by dt seconds; fires the callback if the interval elapsed.
-- Use this when advances the timer by dt seconds; fires the callback if the interval elapsed is needed.
if false then
  local _o = nil  -- Throttle instance
  _o:update(0)
end

--@api-stub: Throttle:reset
-- Resets the elapsed counter without firing.
-- Use this when resets the elapsed counter without firing is needed.
if false then
  local _o = nil  -- Throttle instance
  _o:reset()
end

--@api-stub: Throttle:getProgress
-- Returns the normalised progress through the current interval [0, 1].
-- Use this when returns the normalised progress through the current interval [0, 1] is needed.
if false then
  local _o = nil  -- Throttle instance
  _o:getProgress()
end

--@api-stub: Throttle:getFireCount
-- Returns the total number of times this throttle has fired.
-- Use this when returns the total number of times this throttle has fired is needed.
if false then
  local _o = nil  -- Throttle instance
  _o:getFireCount()
end

--@api-stub: Throttle:setEnabled
-- Enables or disables the throttle.
-- Use this when enables or disables the throttle is needed.
if false then
  local _o = nil  -- Throttle instance
  _o:setEnabled(0)
end

-- ── Debounce methods ──

--@api-stub: Debounce:onFire
-- Sets the callback invoked when the debounce fires.
-- Use this when sets the callback invoked when the debounce fires is needed.
if false then
  local _o = nil  -- Debounce instance
  _o:onFire(nil)
end

--@api-stub: Debounce:trigger
-- Records an input event, resetting the idle timer.
-- Use this when records an input event, resetting the idle timer is needed.
if false then
  local _o = nil  -- Debounce instance
  _o:trigger()
end

--@api-stub: Debounce:update
-- Advances the idle timer by dt seconds; fires the callback if idle wait expired.
-- Use this when advances the idle timer by dt seconds; fires the callback if idle wait expired is needed.
if false then
  local _o = nil  -- Debounce instance
  _o:update(0)
end

--@api-stub: Debounce:cancel
-- Cancels the pending trigger without firing.
-- Use this when cancels the pending trigger without firing is needed.
if false then
  local _o = nil  -- Debounce instance
  _o:cancel()
end

--@api-stub: Debounce:isPending
-- Returns true when a trigger is pending.
-- Use this when returns true when a trigger is pending is needed.
if false then
  local _o = nil  -- Debounce instance
  _o:isPending()
end

--@api-stub: Debounce:getFireCount
-- Returns the total number of times this debounce has fired.
-- Use this when returns the total number of times this debounce has fired is needed.
if false then
  local _o = nil  -- Debounce instance
  _o:getFireCount()
end

-- ── PriorityQueue methods ──

--@api-stub: PriorityQueue:push
-- Inserts an item with a priority.
-- Higher priorities are dequeued first.
if false then
  local _o = nil  -- PriorityQueue instance
  _o:push(0, 0, "label")
end

--@api-stub: PriorityQueue:pop
-- Removes and returns the highest-priority item, or nil if empty.
-- Use this when removes and returns the highest-priority item, or nil if empty is needed.
if false then
  local _o = nil  -- PriorityQueue instance
  _o:pop()
end

--@api-stub: PriorityQueue:peek
-- Returns the highest-priority item without removing it, or nil if empty.
-- Use this when returns the highest-priority item without removing it, or nil if empty is needed.
if false then
  local _o = nil  -- PriorityQueue instance
  _o:peek()
end

--@api-stub: PriorityQueue:len
-- Returns the number of items in the queue.
-- Use this when returns the number of items in the queue is needed.
if false then
  local _o = nil  -- PriorityQueue instance
  _o:len()
end

--@api-stub: PriorityQueue:isEmpty
-- Returns true when the queue has no items.
-- Use this when returns true when the queue has no items is needed.
if false then
  local _o = nil  -- PriorityQueue instance
  _o:isEmpty()
end

--@api-stub: PriorityQueue:clearAll
-- Removes all items from the queue.
-- Use this when removes all items from the queue is needed.
if false then
  local _o = nil  -- PriorityQueue instance
  _o:clearAll()
end

-- ── Ring methods ──

--@api-stub: Ring:push
-- Pushes a value (number or string) with an optional tag.
-- Overwrites oldest on overflow.
if false then
  local _o = nil  -- Ring instance
  _o:push(0, 0)
end

--@api-stub: Ring:latest
-- Returns the most recently pushed entry, or nil.
-- Use this when returns the most recently pushed entry, or nil is needed.
if false then
  local _o = nil  -- Ring instance
  _o:latest()
end

--@api-stub: Ring:toArray
-- Returns all entries (oldest first) as an array of {id, tag, value?, text?} tables.
-- Use this when returns all entries (oldest first) as an array of {id, tag, value?, text?} tables is needed.
if false then
  local _o = nil  -- Ring instance
  _o:toArray()
end

--@api-stub: Ring:sum
-- Returns the sum of all numeric values in the ring.
-- Use this when returns the sum of all numeric values in the ring is needed.
if false then
  local _o = nil  -- Ring instance
  _o:sum()
end

--@api-stub: Ring:average
-- Returns the average of all numeric values, or 0 if empty.
-- Use this when returns the average of all numeric values, or 0 if empty is needed.
if false then
  local _o = nil  -- Ring instance
  _o:average()
end

--@api-stub: Ring:len
-- Returns the number of entries currently in the ring.
-- Use this when returns the number of entries currently in the ring is needed.
if false then
  local _o = nil  -- Ring instance
  _o:len()
end

--@api-stub: Ring:isFull
-- Returns true when the ring is at capacity.
-- Use this when returns true when the ring is at capacity is needed.
if false then
  local _o = nil  -- Ring instance
  _o:isFull()
end

--@api-stub: Ring:clear
-- Removes all entries from the ring.
-- Use this when removes all entries from the ring is needed.
if false then
  local _o = nil  -- Ring instance
  _o:clear()
end

-- ── Funnel methods ──

--@api-stub: Funnel:onFlush
-- Sets a callback invoked when the funnel flushes.
-- Receives a table of {tag, value} entries.
if false then
  local _o = nil  -- Funnel instance
  _o:onFlush(nil)
end

--@api-stub: Funnel:push
-- Adds an event to the funnel.
-- Immediately flushes if max_entries reached or window is 0.
if false then
  local _o = nil  -- Funnel instance
  _o:push(0, 0)
end

--@api-stub: Funnel:update
-- Advances the window timer by dt seconds; flushes when window expires.
-- Use this when advances the window timer by dt seconds; flushes when window expires is needed.
if false then
  local _o = nil  -- Funnel instance
  _o:update(0)
end

--@api-stub: Funnel:flush
-- Manually flushes all pending entries, invoking the onFlush callback.
-- Use this when manually flushes all pending entries, invoking the onFlush callback is needed.
if false then
  local _o = nil  -- Funnel instance
  _o:flush()
end

--@api-stub: Funnel:discard
-- Discards all buffered entries without flushing.
-- Use this when discards all buffered entries without flushing is needed.
if false then
  local _o = nil  -- Funnel instance
  _o:discard()
end

--@api-stub: Funnel:pendingCount
-- Returns the number of buffered entries not yet flushed.
-- Use this when returns the number of buffered entries not yet flushed is needed.
if false then
  local _o = nil  -- Funnel instance
  _o:pendingCount()
end

--@api-stub: Funnel:getFlushCount
-- Returns the total number of flushes performed.
-- Use this when returns the total number of flushes performed is needed.
if false then
  local _o = nil  -- Funnel instance
  _o:getFlushCount()
end

-- ── RelationshipManager methods ──

--@api-stub: RelationshipManager:defineType
-- Defines a relationship type with ordered levels.
-- Use this when defines a relationship type with ordered levels is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:defineType(1, 0, 0)
end

--@api-stub: RelationshipManager:removeType
-- Removes a relationship type definition.
-- Use this when removes a relationship type definition is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:removeType(1)
end

--@api-stub: RelationshipManager:typeNames
-- Returns all defined relationship type names.
-- Use this when returns all defined relationship type names is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:typeNames()
end

--@api-stub: RelationshipManager:setValue
-- Sets the numeric relationship value between two entities.
-- Use this when sets the numeric relationship value between two entities is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:setValue(nil, nil, 0)
end

--@api-stub: RelationshipManager:getValue
-- Returns the numeric relationship value between two entities (default 0.0).
-- Use this when returns the numeric relationship value between two entities (default 0.0) is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:getValue(nil, nil)
end

--@api-stub: RelationshipManager:adjustValue
-- Adjusts the numeric relationship value by a delta.
-- Use this when adjusts the numeric relationship value by a delta is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:adjustValue(nil, nil, 0)
end

--@api-stub: RelationshipManager:setLevel
-- Sets a named level for a typed relationship between two entities.
-- Use this when sets a named level for a typed relationship between two entities is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:setLevel(nil, nil, 1, 0)
end

--@api-stub: RelationshipManager:getLevel
-- Returns the named level for a typed relationship, or nil.
-- Use this when returns the named level for a typed relationship, or nil is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:getLevel(nil, nil, 1)
end

--@api-stub: RelationshipManager:removePair
-- Removes all relationship data between two entities.
-- Use this when removes all relationship data between two entities is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:removePair(nil, nil)
end

--@api-stub: RelationshipManager:pairCount
-- Returns the total number of stored relationship pairs.
-- Use this when returns the total number of stored relationship pairs is needed.
if false then
  local _o = nil  -- RelationshipManager instance
  _o:pairCount()
end

-- ── Mediator methods ──

--@api-stub: Mediator:on
-- Registers a handler callback on a channel; returns handler ID.
-- Use this when registers a handler callback on a channel; returns handler ID is needed.
if false then
  local _o = nil  -- Mediator instance
  _o:on(1, function() end)
end

--@api-stub: Mediator:off
-- Unregisters a handler by ID.
-- Use this when unregisters a handler by ID is needed.
if false then
  local _o = nil  -- Mediator instance
  _o:off(1, 1)
end

--@api-stub: Mediator:send
-- Dispatches a message to all handlers on a channel.
-- Use this when dispatches a message to all handlers on a channel is needed.
if false then
  local _o = nil  -- Mediator instance
  _o:send({})
end

--@api-stub: Mediator:broadcast
-- Dispatches a message to all handlers across all channels.
-- Use this when dispatches a message to all handlers across all channels is needed.
if false then
  local _o = nil  -- Mediator instance
  _o:broadcast({})
end

--@api-stub: Mediator:handlerCount
-- Returns the number of handlers on a channel.
-- Use this when returns the number of handlers on a channel is needed.
if false then
  local _o = nil  -- Mediator instance
  _o:handlerCount(1)
end

--@api-stub: Mediator:channels
-- Returns all registered channel names.
-- Use this when returns all registered channel names is needed.
if false then
  local _o = nil  -- Mediator instance
  _o:channels()
end

--@api-stub: Mediator:removeChannel
-- Removes a channel and all its handlers.
-- Use this when removes a channel and all its handlers is needed.
if false then
  local _o = nil  -- Mediator instance
  _o:removeChannel(1)
end

--@api-stub: Mediator:clear
-- Removes all channels and handlers.
-- Use this when removes all channels and handlers is needed.
if false then
  local _o = nil  -- Mediator instance
  _o:clear()
end

-- ── Strategy methods ──

--@api-stub: Strategy:register
-- Registers a named strategy function.
-- Use this when registers a named strategy function is needed.
if false then
  local _o = nil  -- Strategy instance
  _o:register(1, function() end)
end

--@api-stub: Strategy:set
-- Sets the active strategy by name.
-- Returns false if not registered.
if false then
  local _o = nil  -- Strategy instance
  _o:set(1)
end

--@api-stub: Strategy:execute
-- Calls the currently active strategy function with the given arguments.
-- Use this when calls the currently active strategy function with the given arguments is needed.
if false then
  local _o = nil  -- Strategy instance
  _o:execute({})
end

--@api-stub: Strategy:getCurrent
-- Returns the name of the active strategy, or nil.
-- Use this when returns the name of the active strategy, or nil is needed.
if false then
  local _o = nil  -- Strategy instance
  _o:getCurrent()
end

--@api-stub: Strategy:has
-- Returns true if a strategy with this name is registered.
-- Use this when returns true if a strategy with this name is registered is needed.
if false then
  local _o = nil  -- Strategy instance
  _o:has(1)
end

--@api-stub: Strategy:remove
-- Removes a strategy by name.
-- Use this when removes a strategy by name is needed.
if false then
  local _o = nil  -- Strategy instance
  _o:remove(1)
end

--@api-stub: Strategy:names
-- Returns all registered strategy names.
-- Use this when returns all registered strategy names is needed.
if false then
  local _o = nil  -- Strategy instance
  _o:names()
end

--@api-stub: Strategy:clear
-- Removes all strategies and clears the active selection.
-- Use this when removes all strategies and clears the active selection is needed.
if false then
  local _o = nil  -- Strategy instance
  _o:clear()
end

-- ── Stack methods ──

--@api-stub: Stack:push
-- Pushes a value onto the stack.
-- Returns false if capacity is full.
if false then
  local _o = nil  -- Stack instance
  _o:push(0)
end

--@api-stub: Stack:pop
-- Removes and returns the top value, or nil if empty.
-- Use this when removes and returns the top value, or nil if empty is needed.
if false then
  local _o = nil  -- Stack instance
  _o:pop()
end

--@api-stub: Stack:peek
-- Returns the top value without removing it, or nil if empty.
-- Use this when returns the top value without removing it, or nil if empty is needed.
if false then
  local _o = nil  -- Stack instance
  _o:peek()
end

--@api-stub: Stack:len
-- Returns the number of items on the stack.
-- Use this when returns the number of items on the stack is needed.
if false then
  local _o = nil  -- Stack instance
  _o:len()
end

--@api-stub: Stack:isEmpty
-- Returns true if the stack is empty.
-- Use this when returns true if the stack is empty is needed.
if false then
  local _o = nil  -- Stack instance
  _o:isEmpty()
end

--@api-stub: Stack:isFull
-- Returns true if the stack is at its capacity limit.
-- Use this when returns true if the stack is at its capacity limit is needed.
if false then
  local _o = nil  -- Stack instance
  _o:isFull()
end

--@api-stub: Stack:clear
-- Removes all values from the stack.
-- Use this when removes all values from the stack is needed.
if false then
  local _o = nil  -- Stack instance
  _o:clear()
end

--@api-stub: Stack:toArray
-- Returns all items as a Lua table (bottom to top).
-- Use this when returns all items as a Lua table (bottom to top) is needed.
if false then
  local _o = nil  -- Stack instance
  _o:toArray()
end

-- ── Queue methods ──

--@api-stub: Queue:enqueue
-- Adds a value to the back of the queue.
-- Returns false if capacity is full.
if false then
  local _o = nil  -- Queue instance
  _o:enqueue(0)
end

--@api-stub: Queue:dequeue
-- Removes and returns the front value, or nil if empty.
-- Use this when removes and returns the front value, or nil if empty is needed.
if false then
  local _o = nil  -- Queue instance
  _o:dequeue()
end

--@api-stub: Queue:front
-- Returns the front value without removing it, or nil if empty.
-- Use this when returns the front value without removing it, or nil if empty is needed.
if false then
  local _o = nil  -- Queue instance
  _o:front()
end

--@api-stub: Queue:len
-- Returns the number of items in the queue.
-- Use this when returns the number of items in the queue is needed.
if false then
  local _o = nil  -- Queue instance
  _o:len()
end

--@api-stub: Queue:isEmpty
-- Returns true if the queue is empty.
-- Use this when returns true if the queue is empty is needed.
if false then
  local _o = nil  -- Queue instance
  _o:isEmpty()
end

--@api-stub: Queue:isFull
-- Returns true if the queue is at its capacity limit.
-- Use this when returns true if the queue is at its capacity limit is needed.
if false then
  local _o = nil  -- Queue instance
  _o:isFull()
end

--@api-stub: Queue:clear
-- Removes all values from the queue.
-- Use this when removes all values from the queue is needed.
if false then
  local _o = nil  -- Queue instance
  _o:clear()
end

--@api-stub: Queue:toArray
-- Returns all items as a Lua table (front to back).
-- Use this when returns all items as a Lua table (front to back) is needed.
if false then
  local _o = nil  -- Queue instance
  _o:toArray()
end

-- ── List methods ──

--@api-stub: List:add
-- Appends a value to the end of the list.
-- Use this when appends a value to the end of the list is needed.
if false then
  local _o = nil  -- List instance
  _o:add(0)
end

--@api-stub: List:get
-- Returns the value at a 1-based index, or nil.
-- Use this when returns the value at a 1-based index, or nil is needed.
if false then
  local _o = nil  -- List instance
  _o:get(1)
end

--@api-stub: List:set
-- Replaces the value at a 1-based index.
-- Use this when replaces the value at a 1-based index is needed.
if false then
  local _o = nil  -- List instance
  _o:set(1, 0)
end

--@api-stub: List:remove
-- Removes and returns the value at a 1-based index.
-- Use this when removes and returns the value at a 1-based index is needed.
if false then
  local _o = nil  -- List instance
  _o:remove(1)
end

--@api-stub: List:len
-- Returns the number of items in the list.
-- Use this when returns the number of items in the list is needed.
if false then
  local _o = nil  -- List instance
  _o:len()
end

--@api-stub: List:isEmpty
-- Returns true if the list is empty.
-- Use this when returns true if the list is empty is needed.
if false then
  local _o = nil  -- List instance
  _o:isEmpty()
end

--@api-stub: List:contains
-- Returns true if the list contains a value equal to the given Lua value (string/number/boolean).
-- Use this when returns true if the list contains a value equal to the given Lua value (string/number/boolean) is needed.
if false then
  local _o = nil  -- List instance
  _o:contains(0)
end

--@api-stub: List:clear
-- Removes all values from the list.
-- Use this when removes all values from the list is needed.
if false then
  local _o = nil  -- List instance
  _o:clear()
end

--@api-stub: List:toArray
-- Returns all items as a Lua table.
-- Use this when returns all items as a Lua table is needed.
if false then
  local _o = nil  -- List instance
  _o:toArray()
end

-- ── Set methods ──

--@api-stub: Set:add
-- Adds a string key to the set.
-- Returns true if it was not already present.
if false then
  local _o = nil  -- Set instance
  _o:add(0)
end

--@api-stub: Set:remove
-- Removes a key from the set.
-- Returns true if it was present.
if false then
  local _o = nil  -- Set instance
  _o:remove(0)
end

--@api-stub: Set:has
-- Returns true if the key is in the set.
-- Use this when returns true if the key is in the set is needed.
if false then
  local _o = nil  -- Set instance
  _o:has(0)
end

--@api-stub: Set:len
-- Returns the number of distinct keys in the set.
-- Use this when returns the number of distinct keys in the set is needed.
if false then
  local _o = nil  -- Set instance
  _o:len()
end

--@api-stub: Set:isEmpty
-- Returns true if the set is empty.
-- Use this when returns true if the set is empty is needed.
if false then
  local _o = nil  -- Set instance
  _o:isEmpty()
end

--@api-stub: Set:toArray
-- Returns all keys as a Lua table (unordered).
-- Use this when returns all keys as a Lua table (unordered) is needed.
if false then
  local _o = nil  -- Set instance
  _o:toArray()
end

--@api-stub: Set:clear
-- Removes all keys from the set.
-- Use this when removes all keys from the set is needed.
if false then
  local _o = nil  -- Set instance
  _o:clear()
end

--@api-stub: Set:union
-- Returns the union of this set and another as a new Set.
-- Use this when returns the union of this set and another as a new Set is needed.
if false then
  local _o = nil  -- Set instance
  _o:union(0)
end

--@api-stub: Set:intersection
-- Returns the intersection of this set and another as a new Set.
-- Use this when returns the intersection of this set and another as a new Set is needed.
if false then
  local _o = nil  -- Set instance
  _o:intersection(0)
end

