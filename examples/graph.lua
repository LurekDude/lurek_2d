-- examples/graph.lua
-- luna.graph — Directed item-flow graph simulation: nodes, edges,
-- GraphItems travelling between nodes, conversion rules, events.
-- All luna.graph API methods demonstrated with code and comments.

-- ── Graph Creation ────────────────────────────────────────────────────────────

-- newGraph() → Graph
-- Models a resource-flow network: mines → smelters → warehouses.
local graph = luna.graph.newGraph()

-- ── Adding Nodes ──────────────────────────────────────────────────────────────

-- addNode(type?, capacity?) → Node
local mine      = graph:addNode("mine",      999)  -- source node, large capacity
local smelter   = graph:addNode("smelter",   20)   -- transforms ore → ingot
local warehouse = graph:addNode("warehouse", 100)  -- sink / storage node

-- hasNode(node) → boolean
local exists = graph:hasNode(mine)  -- true

-- getNodes() → table (array of Node)
local nodes = graph:getNodes()

-- getNodeCount() → integer
local nc = graph:getNodeCount()

-- removeNode(node) → boolean  — also removes connected edges
-- graph:removeNode(mine)

-- ── Node Configuration ────────────────────────────────────────────────────────

-- getType() / setType(type)
mine:setType("source")
local ntype = mine:getType()  -- "source" (or whatever string you assign)

-- getCapacity() / setCapacity(n)
smelter:setCapacity(30)
local cap = smelter:getCapacity()  -- 30

-- getItemCount() → integer
local cnt = smelter:getItemCount()

-- isFull() → boolean
local full = smelter:isFull()

-- setActive(bool) / isActive() → boolean
smelter:setActive(true)

-- ── Overflow Policy ───────────────────────────────────────────────────────────

-- setOverflowPolicy(policy) / getOverflowPolicy() → string
-- Policies: "drop" (discard incoming), "block", "oldest" (evict oldest item)
warehouse:setOverflowPolicy("block")
local policy = warehouse:getOverflowPolicy()

-- ── Flow Mode ────────────────────────────────────────────────────────────────

-- setFlowMode(mode) / getFlowMode() → string
-- Modes: "push" (node pushes items), "pull", "balance"
mine:setFlowMode("push")
local mode = mine:getFlowMode()

-- setPushRate(n) / getPushRate() → number  — items/sec node attempts to push
mine:setPushRate(2.0)

-- setPullRate(n) / getPullRate() → number  — items/sec node pulls from predecessors
warehouse:setPullRate(1.0)

-- setPushFilter(fn) / getPushFilter() → fn?
-- fn(item) → boolean: only push items where fn returns true
mine:setPushFilter(function(item)
    return item:getType() == "ore"
end)

-- setPullFilter(fn) / getPullFilter() → fn?
smelter:setPullFilter(function(item)
    return item:getType() == "ore"
end)

-- ── Queue Configuration ───────────────────────────────────────────────────────

-- setQueueEnabled(bool) / isQueueEnabled() → boolean
smelter:setQueueEnabled(true)

-- setQueueCapacity(n) / getQueueCapacity() → integer
smelter:setQueueCapacity(10)

-- getQueueSize() → integer
local qsize = smelter:getQueueSize()

-- enqueue(item) → boolean  — push item into the queue
-- dequeue() → item?

-- ── Process Time ─────────────────────────────────────────────────────────────

-- setProcessTime(seconds) / getProcessTime() → number
-- Item sits in the node for this duration before moving on.
smelter:setProcessTime(2.0)   -- 2 seconds to smelt ore

-- ── Conversion Rules ─────────────────────────────────────────────────────────

-- setConversion(inType, outType, inCount?, outCount?)
-- When node receives `inCount` items of type `inType`, convert them.
smelter:setConversion("ore", "ingot", 2, 1)   -- 2 ore → 1 ingot

-- clearConversion(inType)
-- smelter:clearConversion("ore")

-- clearAllConversions()
-- smelter:clearAllConversions()

-- ── Tags ─────────────────────────────────────────────────────────────────────

-- addTag(tag) / removeTag(tag) / hasTag(tag) → bool / clearTags() / getTags() → table
mine:addTag("producer")
mine:addTag("outdoor")
local has = mine:hasTag("producer")    -- true
local tags = mine:getTags()

-- ── Supply and Demand ────────────────────────────────────────────────────────

-- addSupply(itemType, quantity) — declares what this node produces
mine:addSupply("ore", 10)   -- supplies 10 ore per cycle

-- addDemand(itemType, quantity, priority?)  — declares what this node needs
smelter:addDemand("ore", 2, 10)   -- needs 2 ore, priority 10

-- removeSupply(type) / clearSupplies()
-- mine:removeSupply("ore")
-- mine:clearSupplies()

-- removeDemand(type) / clearDemands()
-- smelter:removeDemand("ore")
-- smelter:clearDemands()

-- ── Adding Edges ─────────────────────────────────────────────────────────────

-- addEdge(fromNode, toNode, opts?) → Edge
local edge_mine_smelter = graph:addEdge(mine, smelter, {
    capacity     = 5,        -- max items in transit simultaneously
    travelTime   = 1.5,      -- seconds for item to traverse edge
    weight       = 1.0,      -- pathfinding/priority weight
})

local edge_smelt_ware = graph:addEdge(smelter, warehouse, {
    capacity   = 10,
    travelTime = 0.5,
})

-- getEdges() → table (all edges)  /  getNodeEdges(node,"in"|"out"|"both") → table
local all_edges = graph:getEdges()
local out_edges = mine:getEdges("out")

-- removeEdge(edge) → boolean
-- graph:removeEdge(edge_mine_smelter)

-- hasEdge(from, to) → boolean
local connected = graph:hasEdge(mine, smelter)  -- true

-- getEdgeCount() → integer
local ec = graph:getEdgeCount()

-- ── Edge Configuration ───────────────────────────────────────────────────────

-- getFrom() → Node  /  getTo() → Node
local src = edge_mine_smelter:getFrom()
local dst = edge_mine_smelter:getTo()

-- getCapacity() / setCapacity(n)
edge_mine_smelter:setCapacity(8)

-- getThroughput() / setThroughput(n)  — max items/sec passing through edge
edge_mine_smelter:setThroughput(3.0)

-- getTravelTime() / setTravelTime(seconds)
edge_mine_smelter:setTravelTime(2.0)

-- getWeight() / setWeight(n)
edge_mine_smelter:setWeight(2.0)

-- getSpeedModifier() / setSpeedModifier(n)  — multiplies travel time
edge_mine_smelter:setSpeedModifier(0.5)   -- double speed

-- getCooldown() / setCooldown(n)  — ticks between item launches
edge_mine_smelter:setCooldown(0.3)

-- isOnCooldown() → boolean
local cooldown = edge_mine_smelter:isOnCooldown()

-- isBidirectional() / setBidirectional(bool)
edge_mine_smelter:setBidirectional(false)

-- isActive() / setActive(bool)
edge_mine_smelter:setActive(true)

-- getItemsInTransit() → table (array of GraphItem)
local transit = edge_mine_smelter:getItemsInTransit()

-- Allowed item type filter
edge_mine_smelter:addAllowedType("ore")
local allowed = edge_mine_smelter:isItemTypeAllowed("ore")  -- true
-- edge_mine_smelter:removeAllowedType("ore")
-- edge_mine_smelter:clearAllowedTypes()

-- ── Items ────────────────────────────────────────────────────────────────────

-- addItem(type, targetNode, opts?) → GraphItem  — inject a free-floating item
-- that will route itself to targetNode
local ore = graph:addItem("ore", mine)

-- removeItem(item)
-- graph:removeItem(ore)

-- getItems() → table  — all items in the graph
local all_items = graph:getItems()

-- getItemCount() → integer
local ic = graph:getItemCount()

-- ── GraphItem Methods ─────────────────────────────────────────────────────────

-- ore is a GraphItem
-- getType() / setType(type)
local itype = ore:getType()   -- "ore"
ore:setType("rich_ore")

-- getDecayTime() / setDecayTime(seconds)  — item is removed after this time
ore:setDecayTime(60)  -- ore spoils in 60 seconds
local decay = ore:getDecayTime()

-- getRemainingLife() → number  — time left before decay fires
local life = ore:getRemainingLife()

-- isAlive() → boolean
local alive = ore:isAlive()

-- kill() — immediately remove the item from the graph
-- ore:kill()

-- getPriority() / setPriority(n)
ore:setPriority(5)
local pri = ore:getPriority()

-- getPosition() → Node | Edge | nil  — where the item currently is
local pos = ore:getPosition()

-- ── Events ────────────────────────────────────────────────────────────────────

-- on(event, fn) — subscribe to a graph event
-- off(event, fn?) — unsubscribe

graph:on("itemEnter", function(item, node)
    -- item arrived at node
end)

graph:on("itemLeave", function(item, node)
    -- item left node
end)

graph:on("itemDecay", function(item)
    -- item life ran out
end)

graph:on("itemConvert", function(input_items, output_item, node)
    -- conversion fired in node
end)

graph:on("itemLost", function(item)
    -- item overflow-dropped or otherwise lost
end)

graph:on("edgeEnter", function(item, edge)
    -- item started traversing edge
end)

graph:on("edgeLeave", function(item, edge)
    -- item finished traversing edge
end)

graph:on("demandFulfilled", function(node, item_type)
    -- node's demand for item_type was met
end)

graph:on("supplyDepleted", function(node, item_type)
    -- node ran out of supply for item_type
end)

graph:on("itemQueued", function(item, node)
    -- item entered node's queue
end)

graph:on("itemDequeued", function(item, node)
    -- item left node's queue
end)

-- ── Main Loop Update ──────────────────────────────────────────────────────────

-- update(dt)  — advance all items, check conversions, fire events
--[[
function luna.process(dt)
    graph:update(dt)
end
]]

-- ── Simulation Query ─────────────────────────────────────────────────────────

-- findPath(fromNode, toNode) → {node1, node2, ...}? — shortest path by weight
-- local path_nodes = graph:findPath(mine, warehouse)
