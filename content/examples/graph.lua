-- content/examples/graph.lua
-- Lurek2D lurek.graph API Reference
-- Run with: cargo run -- content/examples/graph
--
Scenario: A factory automation game where nodes are machines (smelters,
-- assemblers, storages), edges are conveyor belts carrying items between them,
-- and the graph system handles flow logic, routing, supply/demand, and
-- production chains. Items decay, nodes have capacity, and edges filter types.

print("=== lurek.graph — Flow Graph System ===\n")

-- =============================================================================
-- Graph Creation
-- =============================================================================

local factory = lurek.graph.newGraph()

print("graph type: " .. factory:type())

print("is Graph: " .. tostring(factory:typeOf("Graph")))

-- =============================================================================
-- Adding & Querying Nodes
-- =============================================================================

-- Nodes are returned from factory:addNode() — we can't call it directly since
-- it's not listed as a standalone function, but use the graph to get nodes.

print("nodes: " .. factory:getNodeCount())

local nodes = factory:getNodes()

-- Check if a node exists by ID.
-- print("has smelter: " .. tostring(factory:hasNode(smelter_id)))

factory:removeNode(node_id)

-- local neighbors = factory:getNeighbors(node_id)

-- =============================================================================
-- Node Configuration — Machine setup
-- =============================================================================

-- Assume we have a node from the graph:
local smelter = nodes[1]  -- first node if exists

if smelter then
        print("node type: " .. smelter:type())

        print("is Node: " .. tostring(smelter:typeOf("Node")))

        smelter:setType("smelter")

        print("machine: " .. smelter:getType())

        -- Maximum items the smelter can hold.
    smelter:setCapacity(10)

        print("capacity: " .. smelter:getCapacity())

        print("items stored: " .. smelter:getItemCount())

        print("full: " .. tostring(smelter:isFull()))

        smelter:setActive(true)

        print("active: " .. tostring(smelter:isActive()))

    -- =============================================================================
    -- Node Flow Mode — Push/Pull production
    -- =============================================================================

        smelter:setFlowMode("push")

        print("flow mode: " .. smelter:getFlowMode())

        smelter:setPushRate(5)

        print("push rate: " .. smelter:getPushRate())

        smelter:setPullRate(3)

        print("pull rate: " .. smelter:getPullRate())

        smelter:setPushFilter("iron_ingot")

        print("push filter: " .. smelter:getPushFilter())

        smelter:setPullFilter("iron_ore")

        print("pull filter: " .. smelter:getPullFilter())

        smelter:setOverflowPolicy("drop")

        print("overflow: " .. smelter:getOverflowPolicy())

    -- =============================================================================
    -- Node Processing — Conversion recipes
    -- =============================================================================

        -- 2 seconds to smelt one ore into an ingot.
    smelter:setProcessTime(2.0)

        print("process time: " .. smelter:getProcessTime())

        smelter:clearConversion("iron_ore")

        smelter:clearAllConversions()

    -- =============================================================================
    -- Node Queue
    -- =============================================================================

        smelter:setQueueEnabled(true)

        print("queue: " .. tostring(smelter:isQueueEnabled()))

        smelter:setQueueCapacity(20)

        print("queue cap: " .. smelter:getQueueCapacity())

        print("queue size: " .. smelter:getQueueSize())

        -- smelter:enqueue(item)

        -- local next_item = smelter:dequeue()

        local stored = smelter:getItems()

        local connected = smelter:getEdges()

    -- =============================================================================
    -- Node Tags & Supply/Demand
    -- =============================================================================

        smelter:addTag("production")
    smelter:addTag("tier1")

        print("is production: " .. tostring(smelter:hasTag("production")))

        smelter:removeTag("tier1")

        local tags = smelter:getTags()
    print("tags: " .. #tags)

        -- smelter:clearTags()

        smelter:removeSupply("iron_ingot")

        smelter:clearSupplies()

        smelter:removeDemand("iron_ore")

        smelter:clearDemands()
end

-- =============================================================================
-- Edges — Conveyor belts
-- =============================================================================

print("edges: " .. factory:getEdgeCount())

local edges = factory:getEdges()

-- print("has edge: " .. tostring(factory:hasEdge(edge_id)))

factory:removeEdge(edge_id)

local belt = edges[1]
if belt then
        print("edge type: " .. belt:type())

        print("is Edge: " .. tostring(belt:typeOf("Edge")))

        belt:setType("conveyor_mk2")

        print("belt: " .. belt:getType())

        print("from: " .. tostring(belt:getFrom()))

        print("to: " .. tostring(belt:getTo()))

        belt:setWeight(1.0)

        print("weight: " .. belt:getWeight())

    -- =============================================================================
    -- Edge — Capacity & Throughput
    -- =============================================================================

        belt:setCapacity(10)

        print("belt capacity: " .. belt:getCapacity())

        belt:setThroughput(5)

        print("throughput: " .. belt:getThroughput())

        belt:setSpeedModifier(1.5)

        print("speed mod: " .. belt:getSpeedModifier())

        belt:setTravelTime(1.0)

        print("travel time: " .. belt:getTravelTime())

    -- =============================================================================
    -- Edge — Cooldown & Directionality
    -- =============================================================================

        belt:setCooldown(0.5)

        print("cooldown: " .. belt:getCooldown())

        print("on cooldown: " .. tostring(belt:isOnCooldown()))

        belt:setBidirectional(false)

        print("bidirectional: " .. tostring(belt:isBidirectional()))

        belt:setActive(true)

        print("belt active: " .. tostring(belt:isActive()))

    -- =============================================================================
    -- Edge — Item Filtering
    -- =============================================================================

        belt:addAllowedType("iron_ingot")
    belt:addAllowedType("copper_ingot")

        print("iron allowed: " .. tostring(belt:isItemTypeAllowed("iron_ingot")))

        belt:removeAllowedType("copper_ingot")

        -- belt:clearAllowedTypes()

        print("in transit: " .. belt:getItemsInTransit())
end

-- =============================================================================
-- Items — Resources flowing through the factory
-- =============================================================================

print("total items: " .. factory:getItemCount())

local items = factory:getItems()

-- print("has item: " .. tostring(factory:hasItem(item_id)))

factory:removeItem(item_id)

local item = items[1]
if item then
        print("item type id: " .. item:type())

        print("is GraphItem: " .. tostring(item:typeOf("GraphItem")))

        item:setType("iron_ore")

        print("item: " .. item:getType())

        item:setDecayTime(30.0)

        print("decay: " .. item:getDecayTime() .. "s")

        print("remaining life: " .. item:getRemainingLife())

        print("alive: " .. tostring(item:isAlive()))

        -- item:kill()

        item:setPriority(5)

        print("priority: " .. item:getPriority())

        print("position: " .. tostring(item:getPosition()))
end

-- =============================================================================
-- Graph Simulation
-- =============================================================================

factory:update(1/60)

-- Advance one discrete simulation step.
factory:step()

-- Multi-threaded tick for large graphs.
factory:tickParallel(4)

-- =============================================================================
-- Graph Analysis
-- =============================================================================

local components = factory:getComponents()
print("connected components: " .. #components)

print("has cycle: " .. tostring(factory:hasCycle()))

local sorted = factory:topologicalSort()

local mst = factory:mst()
print("MST edges: " .. #mst)

local coloring = factory:colorGraph()

print("bipartite: " .. tostring(factory:isBipartite()))

-- Pathfind through the graph (e.g. item routing).
local path = factory:astar(1, 5)

-- =============================================================================
-- Supply & Demand Processing
-- =============================================================================

factory:processDemand()

local stats = factory:getStats()
print("graph stats: " .. tostring(stats))

print("\n-- graph.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Edge methods
-- -----------------------------------------------------------------------------

-- Clears the edge allow-list so all item types are permitted.
edge:clearAllowedTypes()
-- -----------------------------------------------------------------------------
-- Graph methods
-- -----------------------------------------------------------------------------

-- Removes a node from the graph.
graph:removeNode(node_ud)  -- -> boolean
-- Returns true if the node exists in the graph.
graph:hasNode(node_ud)  -- -> boolean
-- Removes an edge from the graph.
graph:removeEdge(edge_ud)  -- -> boolean
-- Returns true if the edge exists in the graph.
graph:hasEdge(edge_ud)  -- -> boolean
-- Removes an item from the graph entirely.
graph:removeItem(item_ud)  -- -> boolean
-- Returns true if the item exists in the graph.
graph:hasItem(item_ud)  -- -> boolean
-- Returns a table of direct neighbor Node handles.
graph:getNeighbors(node_ud)  -- -> table
-- -----------------------------------------------------------------------------
-- GraphItem methods
-- -----------------------------------------------------------------------------

-- Marks this graph item as dead so it is removed on the next cleanup pass.
graphItem_stub:kill()
-- -----------------------------------------------------------------------------
-- Node methods
-- -----------------------------------------------------------------------------

-- Removes all tags from this node.
node:clearTags()
-- Pushes an item into the node queue.
node:enqueue(item_ud)  -- -> boolean
-- Pops the next item from the node queue, or nil if empty.
node:dequeue()
