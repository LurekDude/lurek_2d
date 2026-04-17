-- content/examples/patterns.lua
-- Lurek2D lurek.patterns API Reference
-- Run with: cargo run -- content/examples/patterns
--
-- Scenario: An RPG using design patterns for event-driven combat, undo/redo
-- in a level editor, object pools for bullet recycling, a state machine for
-- game phases, and data structures for AI priority queues and inventories.

print("=== lurek.patterns — Design Patterns & Data Structures ===\n")

-- =============================================================================
-- EventBus — decoupled event-driven communication
-- =============================================================================

--@api-stub: lurek.patterns.newEventBus
local events = lurek.patterns.newEventBus()

--@api-stub: EventBus:on
events:on("player_hit", function(damage)
    print("player took " .. damage .. " damage")
end)
events:on("item_pickup", function(item)
    print("picked up: " .. item)
end)

--@api-stub: EventBus:emit
events:emit("player_hit", 25)
events:emit("item_pickup", "Health Potion")

--@api-stub: EventBus:getListenerCount
print("player_hit listeners: " .. events:getListenerCount("player_hit"))

--@api-stub: EventBus:getEvents
local event_names = events:getEvents()
print("registered events: " .. table.concat(event_names, ", "))

--@api-stub: EventBus:off
events:off("item_pickup")

--@api-stub: EventBus:clear
events:clear("player_hit")

--@api-stub: EventBus:clearAll
events:clearAll()

-- =============================================================================
-- ObjectPool — bullet/particle recycling
-- =============================================================================

--@api-stub: lurek.patterns.newObjectPool
local bullet_pool = lurek.patterns.newObjectPool()

--@api-stub: ObjectPool:add
for i = 1, 50 do
    bullet_pool:add({x = 0, y = 0, active = false})
end

--@api-stub: ObjectPool:acquire
local bullet = bullet_pool:acquire()
print("acquired bullet: " .. tostring(bullet))

--@api-stub: ObjectPool:release
bullet_pool:release(bullet)

--@api-stub: ObjectPool:getActiveCount
print("active bullets: " .. bullet_pool:getActiveCount())

--@api-stub: ObjectPool:getAvailableCount
print("available: " .. bullet_pool:getAvailableCount())

--@api-stub: ObjectPool:getTotalCount
print("total pool: " .. bullet_pool:getTotalCount())

--@api-stub: ObjectPool:clearAll
bullet_pool:clearAll()

-- =============================================================================
-- CommandStack — undo/redo for level editor
-- =============================================================================

--@api-stub: lurek.patterns.newCommandStack
local commands = lurek.patterns.newCommandStack()

--@api-stub: CommandStack:execute
commands:execute("place_tile", function() print("tile placed") end, function() print("tile removed") end)
commands:execute("move_entity", function() print("entity moved") end, function() print("entity restored") end)

--@api-stub: CommandStack:undo
commands:undo()

--@api-stub: CommandStack:redo
commands:redo()

--@api-stub: CommandStack:canUndo
print("can undo: " .. tostring(commands:canUndo()))

--@api-stub: CommandStack:canRedo
print("can redo: " .. tostring(commands:canRedo()))

--@api-stub: CommandStack:getHistorySize
print("history: " .. commands:getHistorySize())

--@api-stub: CommandStack:getCurrentName
print("current: " .. tostring(commands:getCurrentName()))

--@api-stub: CommandStack:clearAll
commands:clearAll()

-- =============================================================================
-- ServiceLocator — global service registry
-- =============================================================================

--@api-stub: lurek.patterns.newServiceLocator
local services = lurek.patterns.newServiceLocator()

--@api-stub: ServiceLocator:provide
services:provide("audio", {play = function(s) print("playing: " .. s) end})
services:provide("save", {save = function() print("saving...") end})

--@api-stub: ServiceLocator:locate
local audio = services:locate("audio")
audio.play("battle_music")

--@api-stub: ServiceLocator:has
print("has audio: " .. tostring(services:has("audio")))

--@api-stub: ServiceLocator:getServices
local svc_list = services:getServices()
print("services: " .. table.concat(svc_list, ", "))

--@api-stub: ServiceLocator:remove
services:remove("save")

--@api-stub: ServiceLocator:clearAll
services:clearAll()

-- =============================================================================
-- Factory — dynamic entity creation
-- =============================================================================

--@api-stub: lurek.patterns.newFactory
local entity_factory = lurek.patterns.newFactory()

--@api-stub: Factory:register
entity_factory:register("goblin", function() return {hp = 30, atk = 5} end)
entity_factory:register("dragon", function() return {hp = 500, atk = 80} end)

--@api-stub: Factory:create
local goblin = entity_factory:create("goblin")
print("goblin hp: " .. goblin.hp)

--@api-stub: Factory:has
print("has dragon: " .. tostring(entity_factory:has("dragon")))

--@api-stub: Factory:alias
entity_factory:alias("boss", "dragon")

--@api-stub: Factory:getTypes
local types = entity_factory:getTypes()
print("entity types: " .. table.concat(types, ", "))

--@api-stub: Factory:remove
entity_factory:remove("goblin")

--@api-stub: Factory:clearAll
entity_factory:clearAll()

-- =============================================================================
-- SimpleState — game phase state machine
-- =============================================================================

--@api-stub: lurek.patterns.newSimpleState
local game_state = lurek.patterns.newSimpleState()

--@api-stub: SimpleState:addState
game_state:addState("menu", {
    enter = function() print("entering menu") end,
    update = function(dt) end,
    exit = function() print("leaving menu") end
})
game_state:addState("gameplay", {
    enter = function() print("entering gameplay") end,
    update = function(dt) end,
    exit = function() print("leaving gameplay") end
})

--@api-stub: SimpleState:transitionTo
game_state:transitionTo("menu")

--@api-stub: SimpleState:update
game_state:update(1/60)

--@api-stub: SimpleState:getCurrent
print("state: " .. game_state:getCurrent())

--@api-stub: SimpleState:hasState
print("has 'gameplay': " .. tostring(game_state:hasState("gameplay")))

--@api-stub: SimpleState:getStates
local states = game_state:getStates()
print("states: " .. table.concat(states, ", "))

--@api-stub: SimpleState:clearAll
game_state:clearAll()

-- =============================================================================
-- Blackboard — shared AI knowledge base
-- =============================================================================

--@api-stub: lurek.patterns.newBlackboard
local bb = lurek.patterns.newBlackboard()

--@api-stub: Blackboard:set
bb:set("player_pos", {x = 200, y = 300})
bb:set("alert_level", 0)

--@api-stub: Blackboard:get
local pos = bb:get("player_pos")
print("player pos: " .. tostring(pos))

--@api-stub: Blackboard:has
print("has alert_level: " .. tostring(bb:has("alert_level")))

--@api-stub: Blackboard:keys
local bb_keys = bb:keys()
print("blackboard keys: " .. table.concat(bb_keys, ", "))

--@api-stub: Blackboard:watch
bb:watch("alert_level", function(old, new)
    print("alert changed: " .. tostring(old) .. " -> " .. tostring(new))
end)

--@api-stub: Blackboard:unwatch
bb:unwatch("alert_level")

--@api-stub: Blackboard:getRevision
print("revision: " .. bb:getRevision())

--@api-stub: Blackboard:snapshot
local snap = bb:snapshot()
print("snapshot: " .. tostring(snap))

--@api-stub: Blackboard:clear
bb:clear("player_pos")

--@api-stub: Blackboard:clearAll
bb:clearAll()

-- =============================================================================
-- Observer — reactive property watching
-- =============================================================================

--@api-stub: lurek.patterns.newObserver
local hp_obs = lurek.patterns.newObserver()

--@api-stub: Observer:set
hp_obs:set(100)

--@api-stub: Observer:get
print("observed HP: " .. hp_obs:get())

--@api-stub: Observer:subscribe
hp_obs:subscribe(function(old, new)
    print("HP: " .. old .. " -> " .. new)
end)

--@api-stub: Observer:unsubscribe
hp_obs:unsubscribe(1)

--@api-stub: Observer:getCount
print("subscribers: " .. hp_obs:getCount())

-- =============================================================================
-- Throttle & Debounce — input/event rate limiting
-- =============================================================================

--@api-stub: lurek.patterns.newThrottle
local attack_throttle = lurek.patterns.newThrottle()

--@api-stub: Throttle:onFire
attack_throttle:onFire(function()
    print("attack executed!")
end)

--@api-stub: Throttle:update
attack_throttle:update(1/60)

--@api-stub: Throttle:reset
attack_throttle:reset()

--@api-stub: Throttle:getProgress
print("cooldown: " .. string.format("%.0f%%", attack_throttle:getProgress() * 100))

--@api-stub: Throttle:getFireCount
print("attacks fired: " .. attack_throttle:getFireCount())

--@api-stub: Throttle:setEnabled
attack_throttle:setEnabled(true)

--@api-stub: lurek.patterns.newDebounce
local search_debounce = lurek.patterns.newDebounce()

--@api-stub: Debounce:onFire
search_debounce:onFire(function()
    print("search executed!")
end)

--@api-stub: Debounce:trigger
search_debounce:trigger()

--@api-stub: Debounce:update
search_debounce:update(1/60)

--@api-stub: Debounce:cancel
search_debounce:cancel()

--@api-stub: Debounce:isPending
print("search pending: " .. tostring(search_debounce:isPending()))

--@api-stub: Debounce:getFireCount
print("searches: " .. search_debounce:getFireCount())

-- =============================================================================
-- PriorityQueue — AI action scheduling
-- =============================================================================

--@api-stub: lurek.patterns.newPriorityQueue
local ai_queue = lurek.patterns.newPriorityQueue()

--@api-stub: PriorityQueue:push
ai_queue:push("heal", 10)
ai_queue:push("attack", 5)
ai_queue:push("flee", 1)

--@api-stub: PriorityQueue:peek
print("highest priority: " .. tostring(ai_queue:peek()))

--@api-stub: PriorityQueue:pop
local action = ai_queue:pop()
print("executing: " .. action)

--@api-stub: PriorityQueue:len
print("remaining: " .. ai_queue:len())

--@api-stub: PriorityQueue:isEmpty
print("empty: " .. tostring(ai_queue:isEmpty()))

--@api-stub: PriorityQueue:clearAll
ai_queue:clearAll()

-- =============================================================================
-- Ring Buffer — damage history tracking
-- =============================================================================

--@api-stub: lurek.patterns.newRing
local dmg_history = lurek.patterns.newRing()

--@api-stub: Ring:push
dmg_history:push(25)
dmg_history:push(10)
dmg_history:push(50)

--@api-stub: Ring:latest
print("last damage: " .. dmg_history:latest())

--@api-stub: Ring:toArray
local hist = dmg_history:toArray()
print("history: " .. table.concat(hist, ", "))

--@api-stub: Ring:sum
print("total damage: " .. dmg_history:sum())

--@api-stub: Ring:average
print("avg damage: " .. dmg_history:average())

--@api-stub: Ring:len
print("samples: " .. dmg_history:len())

--@api-stub: Ring:isFull
print("buffer full: " .. tostring(dmg_history:isFull()))

--@api-stub: Ring:clear
dmg_history:clear()

-- =============================================================================
-- Funnel — batch event processing
-- =============================================================================

--@api-stub: lurek.patterns.newFunnel
local damage_funnel = lurek.patterns.newFunnel()

--@api-stub: Funnel:onFlush
damage_funnel:onFlush(function(items)
    print("flushing " .. #items .. " damage events")
end)

--@api-stub: Funnel:push
damage_funnel:push({target = "player", amount = 15})
damage_funnel:push({target = "player", amount = 8})

--@api-stub: Funnel:update
damage_funnel:update(1/60)

--@api-stub: Funnel:pendingCount
print("pending: " .. damage_funnel:pendingCount())

--@api-stub: Funnel:flush
damage_funnel:flush()

--@api-stub: Funnel:getFlushCount
print("flushes: " .. damage_funnel:getFlushCount())

--@api-stub: Funnel:discard
damage_funnel:discard()

-- =============================================================================
-- RelationshipManager — NPC faction relations
-- =============================================================================

--@api-stub: lurek.patterns.newRelationshipManager
local relations = lurek.patterns.newRelationshipManager()

--@api-stub: RelationshipManager:defineType
relations:defineType("alliance")
relations:defineType("trade")

--@api-stub: RelationshipManager:typeNames
local rtypes = relations:typeNames()
print("relation types: " .. table.concat(rtypes, ", "))

--@api-stub: RelationshipManager:setValue
relations:setValue("humans", "elves", "alliance", 80)
relations:setValue("humans", "orcs", "alliance", -50)

--@api-stub: RelationshipManager:getValue
print("human-elf alliance: " .. relations:getValue("humans", "elves", "alliance"))

--@api-stub: RelationshipManager:adjustValue
relations:adjustValue("humans", "orcs", "alliance", 10)

--@api-stub: RelationshipManager:setLevel
relations:setLevel("humans", "elves", "trade", "partner")

--@api-stub: RelationshipManager:getLevel
print("human-elf trade: " .. relations:getLevel("humans", "elves", "trade"))

--@api-stub: RelationshipManager:pairCount
print("tracked pairs: " .. relations:pairCount())

--@api-stub: RelationshipManager:removePair
relations:removePair("humans", "orcs")

--@api-stub: RelationshipManager:removeType
relations:removeType("trade")

-- =============================================================================
-- Mediator — cross-system communication
-- =============================================================================

--@api-stub: lurek.patterns.newMediator
local mediator = lurek.patterns.newMediator()

--@api-stub: Mediator:on
mediator:on("combat", function(msg)
    print("combat channel: " .. tostring(msg))
end)

--@api-stub: Mediator:send
mediator:send("combat", "attack_started")

--@api-stub: Mediator:broadcast
mediator:broadcast("game paused")

--@api-stub: Mediator:handlerCount
print("combat handlers: " .. mediator:handlerCount("combat"))

--@api-stub: Mediator:channels
local ch = mediator:channels()
print("channels: " .. table.concat(ch, ", "))

--@api-stub: Mediator:off
mediator:off("combat")

--@api-stub: Mediator:removeChannel
mediator:removeChannel("combat")

--@api-stub: Mediator:clear
mediator:clear()

-- =============================================================================
-- Strategy — interchangeable AI behaviors
-- =============================================================================

--@api-stub: lurek.patterns.newStrategy
local ai_strategy = lurek.patterns.newStrategy()

--@api-stub: Strategy:register
ai_strategy:register("aggressive", function(ctx) return "attack" end)
ai_strategy:register("defensive", function(ctx) return "defend" end)

--@api-stub: Strategy:set
ai_strategy:set("aggressive")

--@api-stub: Strategy:execute
local action2 = ai_strategy:execute({hp = 50})
print("AI chose: " .. action2)

--@api-stub: Strategy:getCurrent
print("strategy: " .. ai_strategy:getCurrent())

--@api-stub: Strategy:has
print("has defensive: " .. tostring(ai_strategy:has("defensive")))

--@api-stub: Strategy:names
local strat_names = ai_strategy:names()
print("strategies: " .. table.concat(strat_names, ", "))

--@api-stub: Strategy:remove
ai_strategy:remove("defensive")

--@api-stub: Strategy:clear
ai_strategy:clear()

-- =============================================================================
-- Stack — navigation history
-- =============================================================================

--@api-stub: lurek.patterns.newStack
local nav_stack = lurek.patterns.newStack()

--@api-stub: Stack:push
nav_stack:push("main_menu")
nav_stack:push("inventory")
nav_stack:push("item_detail")

--@api-stub: Stack:peek
print("current screen: " .. nav_stack:peek())

--@api-stub: Stack:pop
local prev = nav_stack:pop()
print("back to: " .. nav_stack:peek())

--@api-stub: Stack:len
print("stack depth: " .. nav_stack:len())

--@api-stub: Stack:isEmpty
print("stack empty: " .. tostring(nav_stack:isEmpty()))

--@api-stub: Stack:isFull
print("stack full: " .. tostring(nav_stack:isFull()))

--@api-stub: Stack:toArray
local stack_arr = nav_stack:toArray()
print("stack: " .. table.concat(stack_arr, " > "))

--@api-stub: Stack:clear
nav_stack:clear()

-- =============================================================================
-- Queue — turn order / action queue
-- =============================================================================

--@api-stub: lurek.patterns.newQueue
local turn_queue = lurek.patterns.newQueue()

--@api-stub: Queue:enqueue
turn_queue:enqueue("warrior")
turn_queue:enqueue("mage")
turn_queue:enqueue("archer")

--@api-stub: Queue:front
print("next turn: " .. turn_queue:front())

--@api-stub: Queue:dequeue
local current_turn = turn_queue:dequeue()
print("acting: " .. current_turn)

--@api-stub: Queue:len
print("remaining turns: " .. turn_queue:len())

--@api-stub: Queue:isEmpty
print("queue empty: " .. tostring(turn_queue:isEmpty()))

--@api-stub: Queue:isFull
print("queue full: " .. tostring(turn_queue:isFull()))

--@api-stub: Queue:toArray
local q_arr = turn_queue:toArray()
print("turn order: " .. table.concat(q_arr, ", "))

--@api-stub: Queue:clear
turn_queue:clear()

-- =============================================================================
-- List — ordered inventory
-- =============================================================================

--@api-stub: lurek.patterns.newList
local inventory = lurek.patterns.newList()

--@api-stub: List:add
inventory:add("Iron Sword")
inventory:add("Health Potion")
inventory:add("Shield")

--@api-stub: List:get
print("slot 0: " .. inventory:get(0))

--@api-stub: List:set
inventory:set(0, "Steel Sword")

--@api-stub: List:len
print("items: " .. inventory:len())

--@api-stub: List:contains
print("has Shield: " .. tostring(inventory:contains("Shield")))

--@api-stub: List:isEmpty
print("empty: " .. tostring(inventory:isEmpty()))

--@api-stub: List:remove
inventory:remove(1)

--@api-stub: List:toArray
local inv_arr = inventory:toArray()
print("inventory: " .. table.concat(inv_arr, ", "))

--@api-stub: List:clear
inventory:clear()

-- =============================================================================
-- Set — unique tag collection
-- =============================================================================

--@api-stub: lurek.patterns.newSet
local tags = lurek.patterns.newSet()

--@api-stub: Set:add
tags:add("fire")
tags:add("magic")
tags:add("rare")

--@api-stub: Set:has
print("has fire: " .. tostring(tags:has("fire")))

--@api-stub: Set:len
print("tags: " .. tags:len())

--@api-stub: Set:isEmpty
print("empty: " .. tostring(tags:isEmpty()))

--@api-stub: Set:toArray
local tag_arr = tags:toArray()
print("tags: " .. table.concat(tag_arr, ", "))

--@api-stub: Set:remove
tags:remove("rare")

local other_tags = lurek.patterns.newSet()
other_tags:add("fire")
other_tags:add("ice")

--@api-stub: Set:union
local all_tags = tags:union(other_tags)
print("union: " .. all_tags:len())

--@api-stub: Set:intersection
local shared = tags:intersection(other_tags)
print("shared: " .. shared:len())

--@api-stub: Set:clear
tags:clear()

print("\n-- patterns.lua example complete --")
