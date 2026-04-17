-- content/examples/graph.lua
-- Lurek2D lurek.graph API Reference
-- Run with: cargo run -- content/examples/graph
--
-- Scenario: A factory automation game where nodes are machines (smelters,
-- assemblers, storages), edges are conveyor belts carrying items between them,
-- and the graph system handles flow logic, routing, supply/demand, and
-- production chains. Items decay, nodes have capacity, and edges filter types.

print("=== lurek.graph — Flow Graph System ===\n")

-- =============================================================================
-- Graph Creation
-- =============================================================================

--@api-stub: lurek.graph.newGraph
local factory = lurek.graph.newGraph()

--@api-stub: Graph:type
print("graph type: " .. factory:type())

--@api-stub: Graph:typeOf
print("is Graph: " .. tostring(factory:typeOf("Graph")))

-- =============================================================================
-- Adding & Querying Nodes
-- =============================================================================

-- Nodes are returned from factory:addNode() — we can't call it directly since
-- it's not listed as a standalone function, but use the graph to get nodes.

--@api-stub: Graph:getNodeCount
print("nodes: " .. factory:getNodeCount())

--@api-stub: Graph:getNodes
local nodes = factory:getNodes()

--@api-stub: Graph:hasNode
-- Check if a node exists by ID.
-- print("has smelter: " .. tostring(factory:hasNode(smelter_id)))

--@api-stub: Graph:removeNode
-- factory:removeNode(node_id)

--@api-stub: Graph:getNeighbors
-- local neighbors = factory:getNeighbors(node_id)

-- =============================================================================
-- Node Configuration — Machine setup
-- =============================================================================

-- Assume we have a node from the graph:
local smelter = nodes[1]  -- first node if exists

if smelter then
    --@api-stub: Node:type
    print("node type: " .. smelter:type())

    --@api-stub: Node:typeOf
    print("is Node: " .. tostring(smelter:typeOf("Node")))

    --@api-stub: Node:setType
    smelter:setType("smelter")

    --@api-stub: Node:getType
    print("machine: " .. smelter:getType())

    --@api-stub: Node:setCapacity
    -- Maximum items the smelter can hold.
    smelter:setCapacity(10)

    --@api-stub: Node:getCapacity
    print("capacity: " .. smelter:getCapacity())

    --@api-stub: Node:getItemCount
    print("items stored: " .. smelter:getItemCount())

    --@api-stub: Node:isFull
    print("full: " .. tostring(smelter:isFull()))

    --@api-stub: Node:setActive
    smelter:setActive(true)

    --@api-stub: Node:isActive
    print("active: " .. tostring(smelter:isActive()))

    -- =============================================================================
    -- Node Flow Mode — Push/Pull production
    -- =============================================================================

    --@api-stub: Node:setFlowMode
    smelter:setFlowMode("push")

    --@api-stub: Node:getFlowMode
    print("flow mode: " .. smelter:getFlowMode())

    --@api-stub: Node:setPushRate
    smelter:setPushRate(5)

    --@api-stub: Node:getPushRate
    print("push rate: " .. smelter:getPushRate())

    --@api-stub: Node:setPullRate
    smelter:setPullRate(3)

    --@api-stub: Node:getPullRate
    print("pull rate: " .. smelter:getPullRate())

    --@api-stub: Node:setPushFilter
    smelter:setPushFilter("iron_ingot")

    --@api-stub: Node:getPushFilter
    print("push filter: " .. smelter:getPushFilter())

    --@api-stub: Node:setPullFilter
    smelter:setPullFilter("iron_ore")

    --@api-stub: Node:getPullFilter
    print("pull filter: " .. smelter:getPullFilter())

    --@api-stub: Node:setOverflowPolicy
    smelter:setOverflowPolicy("drop")

    --@api-stub: Node:getOverflowPolicy
    print("overflow: " .. smelter:getOverflowPolicy())

    -- =============================================================================
    -- Node Processing — Conversion recipes
    -- =============================================================================

    --@api-stub: Node:setProcessTime
    -- 2 seconds to smelt one ore into an ingot.
    smelter:setProcessTime(2.0)

    --@api-stub: Node:getProcessTime
    print("process time: " .. smelter:getProcessTime())

    --@api-stub: Node:clearConversion
    smelter:clearConversion("iron_ore")

    --@api-stub: Node:clearAllConversions
    smelter:clearAllConversions()

    -- =============================================================================
    -- Node Queue
    -- =============================================================================

    --@api-stub: Node:setQueueEnabled
    smelter:setQueueEnabled(true)

    --@api-stub: Node:isQueueEnabled
    print("queue: " .. tostring(smelter:isQueueEnabled()))

    --@api-stub: Node:setQueueCapacity
    smelter:setQueueCapacity(20)

    --@api-stub: Node:getQueueCapacity
    print("queue cap: " .. smelter:getQueueCapacity())

    --@api-stub: Node:getQueueSize
    print("queue size: " .. smelter:getQueueSize())

    --@api-stub: Node:enqueue
    -- smelter:enqueue(item)

    --@api-stub: Node:dequeue
    -- local next_item = smelter:dequeue()

    --@api-stub: Node:getItems
    local stored = smelter:getItems()

    --@api-stub: Node:getEdges
    local connected = smelter:getEdges()

    -- =============================================================================
    -- Node Tags & Supply/Demand
    -- =============================================================================

    --@api-stub: Node:addTag
    smelter:addTag("production")
    smelter:addTag("tier1")

    --@api-stub: Node:hasTag
    print("is production: " .. tostring(smelter:hasTag("production")))

    --@api-stub: Node:removeTag
    smelter:removeTag("tier1")

    --@api-stub: Node:getTags
    local tags = smelter:getTags()
    print("tags: " .. #tags)

    --@api-stub: Node:clearTags
    -- smelter:clearTags()

    --@api-stub: Node:removeSupply
    smelter:removeSupply("iron_ingot")

    --@api-stub: Node:clearSupplies
    smelter:clearSupplies()

    --@api-stub: Node:removeDemand
    smelter:removeDemand("iron_ore")

    --@api-stub: Node:clearDemands
    smelter:clearDemands()
end

-- =============================================================================
-- Edges — Conveyor belts
-- =============================================================================

--@api-stub: Graph:getEdgeCount
print("edges: " .. factory:getEdgeCount())

--@api-stub: Graph:getEdges
local edges = factory:getEdges()

--@api-stub: Graph:hasEdge
-- print("has edge: " .. tostring(factory:hasEdge(edge_id)))

--@api-stub: Graph:removeEdge
-- factory:removeEdge(edge_id)

local belt = edges[1]
if belt then
    --@api-stub: Edge:type
    print("edge type: " .. belt:type())

    --@api-stub: Edge:typeOf
    print("is Edge: " .. tostring(belt:typeOf("Edge")))

    --@api-stub: Edge:setType
    belt:setType("conveyor_mk2")

    --@api-stub: Edge:getType
    print("belt: " .. belt:getType())

    --@api-stub: Edge:getFrom
    print("from: " .. tostring(belt:getFrom()))

    --@api-stub: Edge:getTo
    print("to: " .. tostring(belt:getTo()))

    --@api-stub: Edge:setWeight
    belt:setWeight(1.0)

    --@api-stub: Edge:getWeight
    print("weight: " .. belt:getWeight())

    -- =============================================================================
    -- Edge — Capacity & Throughput
    -- =============================================================================

    --@api-stub: Edge:setCapacity
    belt:setCapacity(10)

    --@api-stub: Edge:getCapacity
    print("belt capacity: " .. belt:getCapacity())

    --@api-stub: Edge:setThroughput
    belt:setThroughput(5)

    --@api-stub: Edge:getThroughput
    print("throughput: " .. belt:getThroughput())

    --@api-stub: Edge:setSpeedModifier
    belt:setSpeedModifier(1.5)

    --@api-stub: Edge:getSpeedModifier
    print("speed mod: " .. belt:getSpeedModifier())

    --@api-stub: Edge:setTravelTime
    belt:setTravelTime(1.0)

    --@api-stub: Edge:getTravelTime
    print("travel time: " .. belt:getTravelTime())

    -- =============================================================================
    -- Edge — Cooldown & Directionality
    -- =============================================================================

    --@api-stub: Edge:setCooldown
    belt:setCooldown(0.5)

    --@api-stub: Edge:getCooldown
    print("cooldown: " .. belt:getCooldown())

    --@api-stub: Edge:isOnCooldown
    print("on cooldown: " .. tostring(belt:isOnCooldown()))

    --@api-stub: Edge:setBidirectional
    belt:setBidirectional(false)

    --@api-stub: Edge:isBidirectional
    print("bidirectional: " .. tostring(belt:isBidirectional()))

    --@api-stub: Edge:setActive
    belt:setActive(true)

    --@api-stub: Edge:isActive
    print("belt active: " .. tostring(belt:isActive()))

    -- =============================================================================
    -- Edge — Item Filtering
    -- =============================================================================

    --@api-stub: Edge:addAllowedType
    belt:addAllowedType("iron_ingot")
    belt:addAllowedType("copper_ingot")

    --@api-stub: Edge:isItemTypeAllowed
    print("iron allowed: " .. tostring(belt:isItemTypeAllowed("iron_ingot")))

    --@api-stub: Edge:removeAllowedType
    belt:removeAllowedType("copper_ingot")

    --@api-stub: Edge:clearAllowedTypes
    -- belt:clearAllowedTypes()

    --@api-stub: Edge:getItemsInTransit
    print("in transit: " .. belt:getItemsInTransit())
end

-- =============================================================================
-- Items — Resources flowing through the factory
-- =============================================================================

--@api-stub: Graph:getItemCount
print("total items: " .. factory:getItemCount())

--@api-stub: Graph:getItems
local items = factory:getItems()

--@api-stub: Graph:hasItem
-- print("has item: " .. tostring(factory:hasItem(item_id)))

--@api-stub: Graph:removeItem
-- factory:removeItem(item_id)

local item = items[1]
if item then
    --@api-stub: GraphItem:type
    print("item type id: " .. item:type())

    --@api-stub: GraphItem:typeOf
    print("is GraphItem: " .. tostring(item:typeOf("GraphItem")))

    --@api-stub: GraphItem:setType
    item:setType("iron_ore")

    --@api-stub: GraphItem:getType
    print("item: " .. item:getType())

    --@api-stub: GraphItem:setDecayTime
    item:setDecayTime(30.0)

    --@api-stub: GraphItem:getDecayTime
    print("decay: " .. item:getDecayTime() .. "s")

    --@api-stub: GraphItem:getRemainingLife
    print("remaining life: " .. item:getRemainingLife())

    --@api-stub: GraphItem:isAlive
    print("alive: " .. tostring(item:isAlive()))

    --@api-stub: GraphItem:kill
    -- item:kill()

    --@api-stub: GraphItem:setPriority
    item:setPriority(5)

    --@api-stub: GraphItem:getPriority
    print("priority: " .. item:getPriority())

    --@api-stub: GraphItem:getPosition
    print("position: " .. tostring(item:getPosition()))
end

-- =============================================================================
-- Graph Simulation
-- =============================================================================

--@api-stub: Graph:update
factory:update(1/60)

--@api-stub: Graph:step
-- Advance one discrete simulation step.
factory:step()

--@api-stub: Graph:tickParallel
-- Multi-threaded tick for large graphs.
factory:tickParallel(4)

-- =============================================================================
-- Graph Analysis
-- =============================================================================

--@api-stub: Graph:getComponents
local components = factory:getComponents()
print("connected components: " .. #components)

--@api-stub: Graph:hasCycle
print("has cycle: " .. tostring(factory:hasCycle()))

--@api-stub: Graph:topologicalSort
local sorted = factory:topologicalSort()

--@api-stub: Graph:mst
local mst = factory:mst()
print("MST edges: " .. #mst)

--@api-stub: Graph:colorGraph
local coloring = factory:colorGraph()

--@api-stub: Graph:isBipartite
print("bipartite: " .. tostring(factory:isBipartite()))

--@api-stub: Graph:astar
-- Pathfind through the graph (e.g. item routing).
local path = factory:astar(1, 5)

-- =============================================================================
-- Supply & Demand Processing
-- =============================================================================

--@api-stub: Graph:processDemand
factory:processDemand()

--@api-stub: Graph:getStats
local stats = factory:getStats()
print("graph stats: " .. tostring(stats))

print("\n-- graph.lua example complete --")
