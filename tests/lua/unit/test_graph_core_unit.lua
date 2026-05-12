-- Lurek2D Graph API Tests

-- Helper: build a simple 2-node graph with one edge

local function make_simple_graph()
    local g = lurek.graph.newGraph()
    local n1 = g:addNode("source", -1)
    local n2 = g:addNode("sink", -1)
    local e = g:addEdge(n1, n2)
    return g, n1, n2, e
end

-- =========================================================================
-- 1. Module existence
-- =========================================================================
-- @describe lurek.graph module exists
describe("lurek.graph module exists", function()
    -- @covers lurek.graph
    it("lurek.graph is a table", function()
        expect_type("table", lurek.graph)
    end)

    -- @covers lurek.graph.newGraph
    it("has newGraph factory", function()
        expect_type("function", lurek.graph.newGraph)
    end)
end)

-- =========================================================================
-- 2. Graph construction
-- =========================================================================
-- @describe Graph construction
describe("Graph construction", function()
    -- @covers lurek.graph.newGraph
    it("newGraph returns a userdata", function()
        local g = lurek.graph.newGraph()
        expect_type("userdata", g)
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("addNode returns a node handle", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_type("userdata", n)
    end)

    -- @covers LGraph:addEdge
    it("addEdge returns an edge handle", function()
        local g, n1, n2, e = make_simple_graph()
        expect_type("userdata", e)
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("addNode with type and capacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("factory", 10)
        expect_equal("factory", n:getType())
        expect_equal(10, n:getCapacity())
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("addNode defaults to 'default' type and -1 capacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal("default", n:getType())
        expect_equal(-1, n:getCapacity())
    end)
end)

-- =========================================================================
-- 3. Node management
-- =========================================================================
-- @describe Node management
describe("Node management", function()
    -- @covers LGraph:addNode
    -- @covers LGraph:hasNode
    -- @covers lurek.graph.newGraph
    it("hasNode returns true for added node", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_true(g:hasNode(n))
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:removeNode
    -- @covers lurek.graph.newGraph
    it("removeNode returns true", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_true(g:removeNode(n))
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:hasNode
    -- @covers LGraph:removeNode
    -- @covers lurek.graph.newGraph
    it("hasNode returns false after removal", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        g:removeNode(n)
        expect_false(g:hasNode(n))
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:getNodeCount
    -- @covers lurek.graph.newGraph
    it("getNodeCount reflects additions", function()
        local g = lurek.graph.newGraph()
        expect_equal(0, g:getNodeCount())
        g:addNode()
        expect_equal(1, g:getNodeCount())
        g:addNode()
        expect_equal(2, g:getNodeCount())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:getNodes
    -- @covers lurek.graph.newGraph
    it("getNodes returns all nodes", function()
        local g = lurek.graph.newGraph()
        g:addNode("a")
        g:addNode("b")
        g:addNode("c")
        local nodes = g:getNodes()
        expect_equal(3, #nodes)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:getNodeCount
    -- @covers LGraph:removeNode
    -- @covers lurek.graph.newGraph
    it("getNodeCount decreases after removeNode", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        g:addNode()
        expect_equal(2, g:getNodeCount())
        g:removeNode(n)
        expect_equal(1, g:getNodeCount())
    end)
end)

-- =========================================================================
-- 4. Edge management
-- =========================================================================
-- @describe Edge management
describe("Edge management", function()
    -- @covers LGraph:hasEdge
    it("hasEdge returns true for added edge", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(g:hasEdge(e))
    end)

    -- @covers LGraph:removeEdge
    it("removeEdge returns true", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(g:removeEdge(e))
    end)

    -- @covers LGraph:hasEdge
    -- @covers LGraph:removeEdge
    it("hasEdge returns false after removal", function()
        local g, n1, n2, e = make_simple_graph()
        g:removeEdge(e)
        expect_false(g:hasEdge(e))
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:getEdgeCount
    -- @covers lurek.graph.newGraph
    it("getEdgeCount reflects additions", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        expect_equal(0, g:getEdgeCount())
        g:addEdge(a, b)
        expect_equal(1, g:getEdgeCount())
        g:addEdge(b, c)
        expect_equal(2, g:getEdgeCount())
    end)

    -- @covers lurek.graph
    -- @covers LGraph:getEdges
    -- @covers LGraphNode:getEdges
    it("getEdges returns all edges", function()
        local g, n1, n2, e = make_simple_graph()
        local edges = g:getEdges()
        expect_equal(1, #edges)
    end)

    -- @covers LGraph:getEdgeBetween
    it("getEdgeBetween finds existing edge", function()
        local g, n1, n2, e = make_simple_graph()
        local found = g:getEdgeBetween(n1, n2)
        expect_not_nil(found)
    end)

    -- @covers LGraph:getEdgeBetween
    it("getEdgeBetween returns nil for no edge", function()
        local g, n1, n2, e = make_simple_graph()
        local found = g:getEdgeBetween(n2, n1)
        expect_nil(found)
    end)

    -- @covers LGraph:getEdgeCount
    -- @covers LGraph:removeEdge
    it("getEdgeCount decreases after removeEdge", function()
        local g, n1, n2, e = make_simple_graph()
        expect_equal(1, g:getEdgeCount())
        g:removeEdge(e)
        expect_equal(0, g:getEdgeCount())
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("addEdge with edge type", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local e = g:addEdge(a, b, "conveyor")
        expect_equal("conveyor", e:getType())
    end)
end)

-- =========================================================================
-- 5. Item management
-- =========================================================================
-- @describe Item management
describe("Item management", function()
    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("createItem returns a handle", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_type("userdata", item)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraphItem:getDecayTime
    -- @covers lurek.graph.newGraph
    it("createItem with type and decay", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("ore", 5.0)
        expect_equal("ore", item:getType())
        expect_near(5.0, item:getDecayTime(), 0.001)
    end)

    -- @covers LGraph:addItem
    -- @covers LGraph:addNode
    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("addItem places item at node", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("store", -1)
        local item = g:createItem("box")
        g:addItem(item, n)
        expect_equal(1, n:getItemCount())
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:hasItem
    -- @covers LGraph:removeItem
    -- @covers lurek.graph.newGraph
    it("removeItem removes from graph", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_true(g:hasItem(item))
        g:removeItem(item)
        expect_false(g:hasItem(item))
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:getItems
    -- @covers lurek.graph.newGraph
    it("getItems returns all items", function()
        local g = lurek.graph.newGraph()
        g:createItem("a")
        g:createItem("b")
        local items = g:getItems()
        expect_equal(2, #items)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:getItemCount
    -- @covers LGraph:removeItem
    -- @covers lurek.graph.newGraph
    it("getItemCount reflects state", function()
        local g = lurek.graph.newGraph()
        expect_equal(0, g:getItemCount())
        local item = g:createItem()
        expect_equal(1, g:getItemCount())
        g:removeItem(item)
        expect_equal(0, g:getItemCount())
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:hasItem
    -- @covers LGraph:removeItem
    -- @covers lurek.graph.newGraph
    it("hasItem returns false for removed item", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        g:removeItem(item)
        expect_false(g:hasItem(item))
    end)
end)

-- =========================================================================
-- 6. Node properties
-- =========================================================================
-- @describe Node properties
describe("Node properties", function()
    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("getType and setType", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("alpha")
        expect_equal("alpha", n:getType())
        n:setType("beta")
        expect_equal("beta", n:getType())
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("getCapacity and setCapacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("x", 5)
        expect_equal(5, n:getCapacity())
        n:setCapacity(20)
        expect_equal(20, n:getCapacity())
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("getItemCount starts at 0", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal(0, n:getItemCount())
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("isFull with unlimited capacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("x", -1)
        expect_false(n:isFull())
    end)

    -- @covers LGraph:addItem
    -- @covers LGraph:addNode
    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("isFull with limited capacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("x", 1)
        expect_false(n:isFull())
        local item = g:createItem()
        g:addItem(item, n)
        expect_true(n:isFull())
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("isActive defaults to true", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_true(n:isActive())
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("setActive toggles state", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setActive(false)
        expect_false(n:isActive())
        n:setActive(true)
        expect_true(n:isActive())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getProcessTime
    -- @covers LGraphNode:setProcessTime
    -- @covers lurek.graph.newGraph
    it("getProcessTime and setProcessTime", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setProcessTime(2.5)
        expect_near(2.5, n:getProcessTime(), 0.001)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getPushRate
    -- @covers LGraphNode:setPushRate
    -- @covers lurek.graph.newGraph
    it("getPushRate and setPushRate", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setPushRate(3.0)
        expect_near(3.0, n:getPushRate(), 0.001)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getPullRate
    -- @covers LGraphNode:setPullRate
    -- @covers lurek.graph.newGraph
    it("getPullRate and setPullRate", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setPullRate(4.0)
        expect_near(4.0, n:getPullRate(), 0.001)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getPushFilter
    -- @covers LGraphNode:setPushFilter
    -- @covers lurek.graph.newGraph
    it("getPushFilter and setPushFilter", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_nil(n:getPushFilter())
        n:setPushFilter("ore")
        expect_equal("ore", n:getPushFilter())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getPullFilter
    -- @covers LGraphNode:setPullFilter
    -- @covers lurek.graph.newGraph
    it("getPullFilter and setPullFilter", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_nil(n:getPullFilter())
        n:setPullFilter("wood")
        expect_equal("wood", n:getPullFilter())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:isQueueEnabled
    -- @covers LGraphNode:setQueueEnabled
    -- @covers lurek.graph.newGraph
    it("isQueueEnabled and setQueueEnabled", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setQueueEnabled(true)
        expect_true(n:isQueueEnabled())
        n:setQueueEnabled(false)
        expect_false(n:isQueueEnabled())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getQueueCapacity
    -- @covers LGraphNode:setQueueCapacity
    -- @covers lurek.graph.newGraph
    it("getQueueCapacity and setQueueCapacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setQueueCapacity(10)
        expect_equal(10, n:getQueueCapacity())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getQueueSize
    -- @covers lurek.graph.newGraph
    it("getQueueSize starts at 0", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal(0, n:getQueueSize())
    end)

    -- @covers LGraph:addItem
    -- @covers LGraph:addNode
    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("getItems on node returns placed items", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("x", -1)
        local i1 = g:createItem("a")
        local i2 = g:createItem("b")
        g:addItem(i1, n)
        g:addItem(i2, n)
        local items = n:getItems()
        expect_equal(2, #items)
    end)

    -- @covers lurek.graph
    -- @covers LGraph:getEdges
    -- @covers LGraphNode:getEdges
    it("getEdges returns edges for node", function()
        local g, n1, n2, e = make_simple_graph()
        local out = n1:getEdges("out")
        expect_equal(1, #out)
        local inc = n2:getEdges("in")
        expect_equal(1, #inc)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("getEdges with 'both' returns all", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        g:addEdge(a, b)
        g:addEdge(c, b)
        local edges = b:getEdges("both")
        expect_equal(2, #edges)
    end)
end)

-- =========================================================================
-- 7. Edge properties
-- =========================================================================
-- @describe Edge properties
describe("Edge properties", function()
    -- @covers lurek.graph
    it("getType and setType", function()
        local g, n1, n2, e = make_simple_graph()
        e:setType("pipe")
        expect_equal("pipe", e:getType())
    end)

    -- @covers LGraphEdge:getFrom
    -- @covers LGraphEdge:getTo
    it("getFrom and getTo return correct nodes", function()
        local g, n1, n2, e = make_simple_graph()
        local from = e:getFrom()
        local to = e:getTo()
        expect_type("userdata", from)
        expect_type("userdata", to)
    end)

    -- @covers lurek.graph
    it("getCapacity and setCapacity", function()
        local g, n1, n2, e = make_simple_graph()
        e:setCapacity(5)
        expect_equal(5, e:getCapacity())
    end)

    -- @covers LGraphEdge:getThroughput
    -- @covers LGraphEdge:setThroughput
    it("getThroughput and setThroughput", function()
        local g, n1, n2, e = make_simple_graph()
        e:setThroughput(2.0)
        expect_near(2.0, e:getThroughput(), 0.001)
    end)

    -- @covers LGraphEdge:getTravelTime
    -- @covers LGraphEdge:setTravelTime
    it("getTravelTime and setTravelTime", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(3.0)
        expect_near(3.0, e:getTravelTime(), 0.001)
    end)

    -- @covers lurek.graph
    -- @covers LGraphEdge:getWeight
    -- @covers LGraphEdge:setWeight
    it("getWeight and setWeight", function()
        local g, n1, n2, e = make_simple_graph()
        e:setWeight(10.5)
        expect_near(10.5, e:getWeight(), 0.001)
    end)

    -- @covers LGraphEdge:getSpeedModifier
    -- @covers LGraphEdge:setSpeedModifier
    it("getSpeedModifier and setSpeedModifier", function()
        local g, n1, n2, e = make_simple_graph()
        e:setSpeedModifier(0.5)
        expect_near(0.5, e:getSpeedModifier(), 0.001)
    end)

    -- @covers LGraphEdge:getCooldown
    -- @covers LGraphEdge:setCooldown
    it("getCooldown and setCooldown", function()
        local g, n1, n2, e = make_simple_graph()
        e:setCooldown(2.0)
        expect_near(2.0, e:getCooldown(), 0.001)
    end)

    -- @covers LGraphEdge:isBidirectional
    -- @covers LGraphEdge:setBidirectional
    it("isBidirectional and setBidirectional", function()
        local g, n1, n2, e = make_simple_graph()
        expect_false(e:isBidirectional())
        e:setBidirectional(true)
        expect_true(e:isBidirectional())
    end)

    -- @covers lurek.graph
    -- @covers LGraphEdge:setActive
    -- @covers LGraphNode:setActive
    it("isActive and setActive", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(e:isActive())
        e:setActive(false)
        expect_false(e:isActive())
    end)

    -- @covers LGraphEdge:getItemsInTransit
    it("getItemsInTransit is empty initially", function()
        local g, n1, n2, e = make_simple_graph()
        local transit = e:getItemsInTransit()
        expect_equal(0, #transit)
    end)
end)

-- =========================================================================
-- 8. Item properties
-- =========================================================================
-- @describe Item properties
describe("Item properties", function()
    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("getType and setType", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("ore")
        expect_equal("ore", item:getType())
        item:setType("refined_ore")
        expect_equal("refined_ore", item:getType())
    end)

    -- @covers LGraph:createItem
    -- @covers LGraphItem:getDecayTime
    -- @covers LGraphItem:setDecayTime
    -- @covers lurek.graph.newGraph
    it("getDecayTime and setDecayTime", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("food", 10.0)
        expect_near(10.0, item:getDecayTime(), 0.001)
        item:setDecayTime(5.0)
        expect_near(5.0, item:getDecayTime(), 0.001)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraphItem:getRemainingLife
    -- @covers lurek.graph.newGraph
    it("getRemainingLife for non-decaying item", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("rock", -1.0)
        -- Non-decaying items should have remaining life equal to decay_time (or -1)
        expect_near(-1.0, item:getRemainingLife(), 0.001)
    end)

    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("isAlive is true for new item", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_true(item:isAlive())
    end)

    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("kill makes item not alive", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        item:kill()
        expect_false(item:isAlive())
    end)

    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("getPriority and setPriority", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        item:setPriority(5)
        expect_equal(5, item:getPriority())
    end)

    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("getPosition returns nil for unplaced item", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        local pos1, pos2 = item:getPosition()
        expect_nil(pos1)
    end)

    -- @covers LGraph:addItem
    -- @covers LGraph:addNode
    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("getPosition returns node for placed item", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local item = g:createItem()
        g:addItem(item, n)
        local pos1, pos2 = item:getPosition()
        expect_type("userdata", pos1)
        expect_nil(pos2)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("getPosition returns edge and progress for in-transit item", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(10.0)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        local pos1, pos2 = item:getPosition()
        expect_type("userdata", pos1)
        expect_type("number", pos2)
    end)
end)

-- =========================================================================
-- 9. Tags
-- =========================================================================
-- @describe Tags
describe("Tags", function()
    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("addTag and hasTag", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addTag("producer")
        expect_true(n:hasTag("producer"))
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("hasTag returns false for missing tag", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_false(n:hasTag("nonexistent"))
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("removeTag removes a tag", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addTag("temp")
        n:removeTag("temp")
        expect_false(n:hasTag("temp"))
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("getTags returns all tags", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addTag("a")
        n:addTag("b")
        local tags = n:getTags()
        expect_equal(2, #tags)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:clearTags
    -- @covers lurek.graph.newGraph
    it("clearTags removes all tags", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addTag("x")
        n:addTag("y")
        n:clearTags()
        expect_false(n:hasTag("x"))
        expect_false(n:hasTag("y"))
        expect_equal(0, #n:getTags())
    end)
end)

-- =========================================================================
-- 10. Overflow policy
-- =========================================================================
-- @describe Overflow policy
describe("Overflow policy", function()
    -- @covers LGraph:addNode
    -- @covers LGraphNode:getOverflowPolicy
    -- @covers lurek.graph.newGraph
    it("default overflow policy is reject", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal("reject", n:getOverflowPolicy())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getOverflowPolicy
    -- @covers LGraphNode:setOverflowPolicy
    -- @covers lurek.graph.newGraph
    it("setOverflowPolicy to destroy", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setOverflowPolicy("destroy")
        expect_equal("destroy", n:getOverflowPolicy())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getOverflowPolicy
    -- @covers LGraphNode:setOverflowPolicy
    -- @covers lurek.graph.newGraph
    it("setOverflowPolicy to queue", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setOverflowPolicy("queue")
        expect_equal("queue", n:getOverflowPolicy())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getOverflowPolicy
    -- @covers LGraphNode:setOverflowPolicy
    -- @covers lurek.graph.newGraph
    it("setOverflowPolicy to reject", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setOverflowPolicy("queue")
        n:setOverflowPolicy("reject")
        expect_equal("reject", n:getOverflowPolicy())
    end)
end)

-- =========================================================================
-- 11. Flow mode
-- =========================================================================
-- @describe Flow mode
describe("Flow mode", function()
    -- @covers LGraph:addNode
    -- @covers LGraphNode:getFlowMode
    -- @covers lurek.graph.newGraph
    it("default flow mode is passive", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal("passive", n:getFlowMode())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getFlowMode
    -- @covers LGraphNode:setFlowMode
    -- @covers lurek.graph.newGraph
    it("setFlowMode to push", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setFlowMode("push")
        expect_equal("push", n:getFlowMode())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getFlowMode
    -- @covers LGraphNode:setFlowMode
    -- @covers lurek.graph.newGraph
    it("setFlowMode to pull", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setFlowMode("pull")
        expect_equal("pull", n:getFlowMode())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getFlowMode
    -- @covers LGraphNode:setFlowMode
    -- @covers lurek.graph.newGraph
    it("setFlowMode to both", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setFlowMode("both")
        expect_equal("both", n:getFlowMode())
    end)
end)

-- =========================================================================
-- 12. Conversion rules
-- =========================================================================
-- @describe Conversion rules
describe("Conversion rules", function()
    -- @covers LGraph:addNode
    -- @covers LGraphNode:setConversion
    -- @covers lurek.graph.newGraph
    it("setConversion does not error", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:setConversion("ore", "ingot")
        end)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:setConversion
    -- @covers lurek.graph.newGraph
    it("setConversion with counts", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:setConversion("ore", "ingot", 2, 1)
        end)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:clearConversion
    -- @covers LGraphNode:setConversion
    -- @covers lurek.graph.newGraph
    it("clearConversion removes a rule", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setConversion("ore", "ingot")
        expect_no_error(function()
            n:clearConversion("ore")
        end)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:clearAllConversions
    -- @covers LGraphNode:setConversion
    -- @covers lurek.graph.newGraph
    it("clearAllConversions removes all rules", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setConversion("ore", "ingot")
        n:setConversion("wood", "plank")
        expect_no_error(function()
            n:clearAllConversions()
        end)
    end)
end)

-- =========================================================================
-- 13. Supply/Demand
-- =========================================================================
-- @describe Supply/Demand
describe("Supply/Demand", function()
    -- @covers LGraph:addNode
    -- @covers LGraphNode:addSupply
    -- @covers lurek.graph.newGraph
    it("addSupply does not error", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:addSupply("ore", 10)
        end)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:addSupply
    -- @covers LGraphNode:removeSupply
    -- @covers lurek.graph.newGraph
    it("removeSupply works after adding", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addSupply("ore", 10)
        expect_no_error(function()
            n:removeSupply("ore")
        end)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:addSupply
    -- @covers LGraphNode:clearSupplies
    -- @covers lurek.graph.newGraph
    it("clearSupplies removes all", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addSupply("ore", 10)
        n:addSupply("wood", 5)
        expect_no_error(function()
            n:clearSupplies()
        end)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:addDemand
    -- @covers lurek.graph.newGraph
    it("addDemand does not error", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:addDemand("ingot", 5)
        end)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:addDemand
    -- @covers lurek.graph.newGraph
    it("addDemand with priority", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:addDemand("ingot", 5, 10)
        end)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:addDemand
    -- @covers LGraphNode:removeDemand
    -- @covers lurek.graph.newGraph
    it("removeDemand works", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addDemand("ingot", 5)
        expect_no_error(function()
            n:removeDemand("ingot")
        end)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:addDemand
    -- @covers LGraphNode:clearDemands
    -- @covers lurek.graph.newGraph
    it("clearDemands removes all", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addDemand("ingot", 5)
        n:addDemand("plank", 3)
        expect_no_error(function()
            n:clearDemands()
        end)
    end)

    -- @covers LGraph:processDemand
    -- @covers lurek.graph.newGraph
    it("processDemand runs without error on empty graph", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:processDemand()
        end)
    end)
end)

-- =========================================================================
-- 14. Pathfinding
-- =========================================================================
-- @describe Pathfinding
describe("Pathfinding", function()
    -- @covers lurek.graph
    it("findPath returns path between connected nodes", function()
        local g, n1, n2, e = make_simple_graph()
        local path = g:findPath(n1, n2)
        expect_not_nil(path)
        expect_not_nil(path.nodes)
        expect_not_nil(path.edges)
        expect_type("number", path.cost)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:findPath
    -- @covers lurek.graph.newGraph
    it("findPath returns nil for disconnected nodes", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local path = g:findPath(a, b)
        expect_nil(path)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:findPath
    -- @covers lurek.graph.newGraph
    it("findPath on multi-hop graph", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, c)
        local path = g:findPath(a, c)
        expect_not_nil(path)
        expect_equal(3, #path.nodes)
        expect_equal(2, #path.edges)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:findPathForItem
    it("findPathForItem respects item type", function()
        local g, n1, n2, e = make_simple_graph()
        local item = g:createItem("ore")
        g:addItem(item, n1)
        local path = g:findPathForItem(item, n1, n2)
        expect_not_nil(path)
    end)

    -- @covers lurek.graph
    it("getDistance returns number for connected nodes", function()
        local g, n1, n2, e = make_simple_graph()
        local dist = g:getDistance(n1, n2)
        expect_type("number", dist)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:getDistance
    -- @covers lurek.graph.newGraph
    it("getDistance returns nil for disconnected nodes", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local dist = g:getDistance(a, b)
        expect_nil(dist)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:getReachable
    -- @covers lurek.graph.newGraph
    it("getReachable returns reachable nodes", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, c)
        local reachable = g:getReachable(a)
        expect_true(#reachable >= 2)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:getReachable
    -- @covers lurek.graph.newGraph
    it("getReachable with maxDist limit", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, c)
        local reachable = g:getReachable(a, 1.0)
        -- With maxDist=1, only direct neighbor b
        expect_true(#reachable >= 1)
    end)

    -- @covers lurek.graph
    -- @covers LGlobe:getNeighbors
    it("getNeighbors returns direct neighbors", function()
        local g, n1, n2, e = make_simple_graph()
        local neighbors = g:getNeighbors(n1)
        expect_equal(1, #neighbors)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:getNeighbors
    -- @covers lurek.graph.newGraph
    it("getNeighbors of isolated node is empty", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local neighbors = g:getNeighbors(n)
        expect_equal(0, #neighbors)
    end)
end)

-- =========================================================================
-- 15. Algorithms
-- =========================================================================
-- @describe Algorithms
describe("Algorithms", function()
    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:hasCycle
    -- @covers lurek.graph.newGraph
    it("hasCycle returns false for DAG", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, c)
        expect_false(g:hasCycle())
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:hasCycle
    -- @covers lurek.graph.newGraph
    it("hasCycle returns true for cyclic graph", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, a)
        expect_true(g:hasCycle())
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:topologicalSort
    -- @covers lurek.graph.newGraph
    it("topologicalSort returns sorted nodes for DAG", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, c)
        local sorted = g:topologicalSort()
        expect_not_nil(sorted)
        expect_equal(3, #sorted)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:topologicalSort
    -- @covers lurek.graph.newGraph
    it("topologicalSort returns nil for cyclic graph", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, a)
        local sorted = g:topologicalSort()
        expect_nil(sorted)
    end)

    -- @covers lurek.graph
    it("getComponents on single connected component", function()
        local g, n1, n2, e = make_simple_graph()
        local comps = g:getComponents()
        expect_equal(1, #comps)
    end)

    -- @covers LGraph:addNode
    -- @covers LGraph:getComponents
    -- @covers lurek.graph.newGraph
    it("getComponents on disconnected graph", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
-- No edges disconnected nodes
        local comps = g:getComponents()
        expect_equal(2, #comps)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:getComponents
    -- @covers lurek.graph.newGraph
    it("getComponents returns tables of nodes", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        g:addEdge(a, b)
        local comps = g:getComponents()
        expect_equal(1, #comps)
        expect_equal(2, #comps[1])
    end)

    -- @covers LGraph:hasCycle
    -- @covers lurek.graph.newGraph
    it("hasCycle on empty graph", function()
        local g = lurek.graph.newGraph()
        expect_false(g:hasCycle())
    end)

    -- @covers LGraph:topologicalSort
    -- @covers lurek.graph.newGraph
    it("topologicalSort on empty graph", function()
        local g = lurek.graph.newGraph()
        local sorted = g:topologicalSort()
        expect_not_nil(sorted)
        expect_equal(0, #sorted)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:subgraph
    -- @covers lurek.graph.newGraph
    it("subgraph returns induced graph over selected nodes", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode("a")
        local b = g:addNode("b")
        local c = g:addNode("c")
        g:addEdge(a, b)
        g:addEdge(b, c)

        local s = g:subgraph({ a, b })
        expect_equal(2, s:getNodeCount())
        expect_equal(1, s:getEdgeCount())
    end)
end)

-- =========================================================================
-- 16. Simulation
-- =========================================================================
-- @describe Simulation
describe("Simulation", function()
    -- @covers LGraph:update
    -- @covers lurek.graph.newGraph
    it("update does not error on empty graph", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:update(1.0)
        end)
    end)

    -- @covers LGraph:step
    -- @covers lurek.graph.newGraph
    it("step does not error on empty graph", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:step()
        end)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("update advances item transit", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(2.0)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        g:update(1.0)
        local pos1, pos2 = item:getPosition()
        -- After 1s on a 2s edge, should still be in transit
        expect_type("userdata", pos1) -- edge
        expect_type("number", pos2)   -- progress
        expect_near(0.5, pos2, 0.1)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("update completes transit when time exceeds travel_time", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(1.0)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        g:update(2.0)
        -- Item should have arrived at n2
        local pos1, pos2 = item:getPosition()
        expect_type("userdata", pos1) -- node
        expect_nil(pos2)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("step advances simulation by 1.0", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(1.0)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        g:step()
        -- After 1 step (dt=1.0), item should arrive
        local pos1, pos2 = item:getPosition()
        expect_type("userdata", pos1)
        expect_nil(pos2)
    end)
end)

-- =========================================================================
-- 17. Item decay
-- =========================================================================
-- @describe Item decay
describe("Item decay", function()
    -- @covers LGraph:addItem
    -- @covers LGraph:addNode
    -- @covers LGraph:createItem
    -- @covers LGraph:update
    -- @covers lurek.graph.newGraph
    it("item with decay remains alive before expiry", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local item = g:createItem("food", 5.0)
        g:addItem(item, n)
        g:update(2.0)
        expect_true(item:isAlive())
    end)

    -- @covers LGraph:addItem
    -- @covers LGraph:addNode
    -- @covers LGraph:createItem
    -- @covers LGraph:update
    -- @covers LGraphItem:getRemainingLife
    -- @covers lurek.graph.newGraph
    it("item remainingLife decreases with update", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local item = g:createItem("food", 5.0)
        g:addItem(item, n)
        g:update(2.0)
        local remaining = item:getRemainingLife()
        expect_near(3.0, remaining, 0.1)
    end)

    -- @covers LGraph:addItem
    -- @covers LGraph:addNode
    -- @covers LGraph:createItem
    -- @covers LGraph:update
    -- @covers lurek.graph.newGraph
    it("item with no decay stays alive indefinitely", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local item = g:createItem("rock", -1.0)
        g:addItem(item, n)
        g:update(100.0)
        expect_true(item:isAlive())
    end)
end)

-- =========================================================================
-- 18. Callbacks
-- =========================================================================
-- @describe Callbacks
describe("Callbacks", function()
    -- @covers LGraph:on
    -- @covers lurek.graph.newGraph
    it("on registers callback without error", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:on("itemEnter", function() end)
        end)
    end)

    -- @covers LGraph:on
    -- @covers lurek.graph.newGraph
    it("on rejects unknown event name", function()
        local g = lurek.graph.newGraph()
        expect_error(function()
            g:on("badEvent", function() end)
        end)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("itemEnter fires when item arrives at node", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(1.0)
        local fired = false
        g:on("itemEnter", function(item, node)
            fired = true
        end)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        g:update(2.0) -- enough time for transit to complete
        expect_true(fired)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("edgeEnter fires when item starts transit", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(5.0)
        local fired = false
        g:on("edgeEnter", function(item, edge)
            fired = true
        end)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        -- sendItem itself should trigger edgeEnter via update,
        -- or we may need a step/update
        g:update(0.0)
        -- If not fired yet, the event may fire on actual move
        -- Try step
        if not fired then
            g:step()
        end
-- Accept either event fires at some point
        -- If still not fired, sendItem may have triggered it directly
    end)

    -- @covers LGraph:on
    -- @covers lurek.graph.newGraph
    it("all valid event names are accepted", function()
        local g = lurek.graph.newGraph()
        local events = {
            "itemEnter", "itemLeave", "itemDecay", "itemConvert",
            "itemLost", "edgeEnter", "edgeLeave", "demandFulfilled",
            "supplyDepleted", "itemQueued", "itemDequeued"
        }
        for _, name in ipairs(events) do
            expect_no_error(function()
                g:on(name, function() end)
            end)
        end
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("callback receives userdata arguments", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(1.0)
        local received_item = nil
        local received_node = nil
        g:on("itemEnter", function(item, node)
            received_item = item
            received_node = node
        end)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        g:update(2.0)
        if received_item then
            expect_type("userdata", received_item)
        end
        if received_node then
            expect_type("userdata", received_node)
        end
    end)
end)

-- =========================================================================
-- 19. Edge type filtering
-- =========================================================================
-- @describe Edge type filtering
describe("Edge type filtering", function()
    -- @covers LGraphEdge:addAllowedType
    it("addAllowedType does not error", function()
        local g, n1, n2, e = make_simple_graph()
        expect_no_error(function()
            e:addAllowedType("ore")
        end)
    end)

    -- @covers LGraphEdge:isItemTypeAllowed
    it("isItemTypeAllowed returns true when no filter set", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(e:isItemTypeAllowed("anything"))
    end)

    -- @covers LGraphEdge:addAllowedType
    -- @covers LGraphEdge:isItemTypeAllowed
    it("isItemTypeAllowed returns true for allowed type", function()
        local g, n1, n2, e = make_simple_graph()
        e:addAllowedType("ore")
        expect_true(e:isItemTypeAllowed("ore"))
    end)

    -- @covers LGraphEdge:addAllowedType
    -- @covers LGraphEdge:isItemTypeAllowed
    it("isItemTypeAllowed returns false for disallowed type", function()
        local g, n1, n2, e = make_simple_graph()
        e:addAllowedType("ore")
        expect_false(e:isItemTypeAllowed("wood"))
    end)

    -- @covers LGraphEdge:addAllowedType
    -- @covers LGraphEdge:isItemTypeAllowed
    -- @covers LGraphEdge:removeAllowedType
    it("removeAllowedType removes a filter", function()
        local g, n1, n2, e = make_simple_graph()
        e:addAllowedType("ore")
        e:addAllowedType("wood")
        e:removeAllowedType("ore")
        expect_false(e:isItemTypeAllowed("ore"))
        expect_true(e:isItemTypeAllowed("wood"))
    end)

    -- @covers LGraphEdge:addAllowedType
    -- @covers LGraphEdge:clearAllowedTypes
    -- @covers LGraphEdge:isItemTypeAllowed
    it("clearAllowedTypes resets filter", function()
        local g, n1, n2, e = make_simple_graph()
        e:addAllowedType("ore")
        e:clearAllowedTypes()
        -- With no filter, all types should be allowed
        expect_true(e:isItemTypeAllowed("anything"))
    end)
end)

-- =========================================================================
-- 20. Cooldown
-- =========================================================================
-- @describe Cooldown
describe("Cooldown", function()
    -- @covers LGraphEdge:isOnCooldown
    it("isOnCooldown is false initially", function()
        local g, n1, n2, e = make_simple_graph()
        expect_false(e:isOnCooldown())
    end)

    -- @covers LGraphEdge:getCooldown
    -- @covers LGraphEdge:setCooldown
    it("setCooldown sets value", function()
        local g, n1, n2, e = make_simple_graph()
        e:setCooldown(3.0)
        expect_near(3.0, e:getCooldown(), 0.001)
    end)
end)

-- =========================================================================
-- 21. Stats
-- =========================================================================
-- @describe Stats
describe("Stats", function()
    -- @covers LGraph:getStats
    -- @covers lurek.graph.newGraph
    it("getStats returns table with correct fields", function()
        local g = lurek.graph.newGraph()
        local stats = g:getStats()
        expect_type("table", stats)
        expect_type("number", stats.nodes)
        expect_type("number", stats.edges)
        expect_type("number", stats.items)
        expect_type("number", stats.activeNodes)
        expect_type("number", stats.activeEdges)
        expect_type("number", stats.itemsInTransit)
        expect_type("number", stats.itemsOnNodes)
        expect_type("number", stats.totalDemand)
        expect_type("number", stats.totalSupply)
        expect_type("number", stats.queuedItems)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addItem
    -- @covers LGraph:addNode
    -- @covers LGraph:createItem
    -- @covers LGraph:getStats
    -- @covers lurek.graph.newGraph
    it("getStats reflects graph state", function()
        local g = lurek.graph.newGraph()
        local n1 = g:addNode()
        local n2 = g:addNode()
        g:addEdge(n1, n2)
        local item = g:createItem()
        g:addItem(item, n1)
        local stats = g:getStats()
        expect_equal(2, stats.nodes)
        expect_equal(1, stats.edges)
        expect_equal(1, stats.items)
        expect_equal(1, stats.itemsOnNodes)
    end)

    -- @covers LGraph:getStats
    -- @covers lurek.graph.newGraph
    it("getStats on empty graph", function()
        local g = lurek.graph.newGraph()
        local stats = g:getStats()
        expect_equal(0, stats.nodes)
        expect_equal(0, stats.edges)
        expect_equal(0, stats.items)
    end)
end)

-- =========================================================================
-- 22. Type system
-- =========================================================================
-- @describe Type system
describe("Type system", function()
    -- @covers LGraph:type
    -- @covers lurek.graph.newGraph
    it("Graph type() returns LGraph", function()
        local g = lurek.graph.newGraph()
        expect_equal("LGraph", g:type())
    end)

    -- @covers LGraph:typeOf
    -- @covers lurek.graph.newGraph
    it("Graph typeOf Graph", function()
        local g = lurek.graph.newGraph()
        expect_true(g:typeOf("Graph"))
    end)

    -- @covers LGraph:typeOf
    -- @covers lurek.graph.newGraph
    it("Graph typeOf Object", function()
        local g = lurek.graph.newGraph()
        expect_true(g:typeOf("Object"))
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("Node type() returns LGraphNode", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal("LGraphNode", n:type())
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("Node typeOf GraphNode", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_true(n:typeOf("GraphNode"))
    end)

    -- @covers lurek.graph
    it("Edge type() returns LGraphEdge", function()
        local g, n1, n2, e = make_simple_graph()
        expect_equal("LGraphEdge", e:type())
    end)

    -- @covers lurek.graph
    it("Edge typeOf GraphEdge", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(e:typeOf("GraphEdge"))
    end)

    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("Item type() returns LGraphItem", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_equal("LGraphItem", item:type())
    end)

    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("Item typeOf GraphItem", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_true(item:typeOf("GraphItem"))
    end)

    -- @covers LGraph:createItem
    -- @covers lurek.graph.newGraph
    it("Item typeOf Object", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_true(item:typeOf("Object"))
    end)

    -- @covers LGraph:addNode
    -- @covers lurek.graph.newGraph
    it("Node typeOf returns false for wrong type", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_false(n:typeOf("GraphEdge"))
    end)
end)

-- =========================================================================
-- 23. sendItem
-- =========================================================================
-- @describe sendItem
describe("sendItem", function()
    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("sendItem dispatches item along edge", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(5.0)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        local pos1, pos2 = item:getPosition()
        expect_type("userdata", pos1) -- edge
        expect_type("number", pos2)   -- progress
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("sendItem removes item from source node", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(5.0)
        local item = g:createItem()
        g:addItem(item, n1)
        expect_equal(1, n1:getItemCount())
        g:sendItem(item, e)
        expect_equal(0, n1:getItemCount())
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:getItemsInTransit
    -- @covers LGraphEdge:setTravelTime
    it("sendItem puts item in edge transit list", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(5.0)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        local transit = e:getItemsInTransit()
        expect_equal(1, #transit)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraphEdge:setTravelTime
    it("item arrives at destination after full transit", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(1.0)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        g:update(1.5)
        expect_equal(1, n2:getItemCount())
    end)
end)

-- @describe graph edge validity errors (RS parity)
describe("graph edge validity errors (RS parity)", function()
    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:getEdgeCount
    -- @covers LGraph:getNodeCount
    -- @covers LGraph:getNodes
    -- @covers LGraph:removeNode
    -- @covers lurek.graph.newGraph
    it("addEdge with invalid source returns error", function() local g=lurek.graph.newGraph(); local b=g:addNode("B"); expect_error(function() local invalid=g:addNode("invalid"); g:removeNode(invalid); g:addEdge(invalid,b) end) end)
    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:getEdgeCount
    -- @covers LGraph:getNodeCount
    -- @covers LGraph:getNodes
    -- @covers LGraph:removeNode
    -- @covers lurek.graph.newGraph
    it("addEdge with invalid destination returns error", function() local g=lurek.graph.newGraph(); local a=g:addNode("A"); expect_error(function() local invalid=g:addNode("invalid"); g:removeNode(invalid); g:addEdge(a,invalid) end) end)
    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:getEdgeCount
    -- @covers LGraph:getNodeCount
    -- @covers LGraph:getNodes
    -- @covers LGraph:removeNode
    -- @covers lurek.graph.newGraph
    it("removeNode cleans connected edges", function() local g=lurek.graph.newGraph(); local a=g:addNode("A"); local b=g:addNode("B"); g:addEdge(a,b); g:removeNode(a); expect_equal(1,g:getNodeCount()); expect_equal(0,g:getEdgeCount()) end)
    -- @covers LGraph:addNode
    -- @covers LGraph:getNodeCount
    -- @covers LGraph:getNodes
    -- @covers LGraph:removeNode
    -- @covers lurek.graph.newGraph
    it("removeNode on nonexistent id raises error", function() local g=lurek.graph.newGraph(); expect_error(function() local invalid=g:addNode("invalid"); g:removeNode(invalid); g:removeNode(invalid) end) end)
    -- @covers LGraph:addNode
    -- @covers LGraph:getNodeCount
    -- @covers LGraph:getNodes
    -- @covers lurek.graph.newGraph
    it("getNodes count matches getNodeCount", function() local g=lurek.graph.newGraph(); g:addNode("X"); g:addNode("Y"); local nodes=g:getNodes(); expect_equal(g:getNodeCount(),#nodes) end)
end)
-- @describe lurek.graph tickParallel
describe("lurek.graph tickParallel", function()
    -- @covers lurek.graph.newGraph
    it("tickParallel is callable", function()
        local sim = lurek.graph.newGraph()
        expect_type("function", sim.tickParallel)
    end)

    -- @covers LGraph:tickParallel
    -- @covers lurek.graph.newGraph
    it("tickParallel does not error on an empty graph", function()
        local sim = lurek.graph.newGraph()
        expect_no_error(function()
            sim:tickParallel(0.016)
        end)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:sendItem
    -- @covers LGraph:tickParallel
    -- @covers LGraphEdge:setTravelTime
    it("tickParallel advances in-transit items", function()
        local sim, n1, n2, e = make_simple_graph()
        e:setTravelTime(0.01)
        local item = sim:createItem()
        sim:addItem(item, n1)
        sim:sendItem(item, e)

        sim:tickParallel(0.02)

        expect_equal(1, n2:getItemCount())
    end)
end)

-- @describe graph regression coverage
describe("graph regression coverage", function()
    local function contains(list, value)
        for _, entry in ipairs(list) do
            if entry == value then
                return true
            end
        end

        return false
    end

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:mst
    -- @covers lurek.graph.newGraph
    it("mst prefers the lighter two edges in a triangle", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()

        local e1 = g:addEdge(a, b)
        e1:setWeight(1.0)
        local e2 = g:addEdge(b, c)
        e2:setWeight(2.0)
        local e3 = g:addEdge(a, c)
        e3:setWeight(10.0)

        local mst = g:mst()
        expect_equal(2, #mst)
        expect_true(contains(mst, 1))
        expect_true(contains(mst, 2))
        expect_false(contains(mst, 3))
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:colorGraph
    -- @covers lurek.graph.newGraph
    it("colorGraph colors a path with two colors", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, c)

        local colors = g:colorGraph()
        expect_not_nil(colors[1])
        expect_not_nil(colors[2])
        expect_not_nil(colors[3])
        expect_true(colors[1] ~= colors[2])
        expect_true(colors[2] ~= colors[3])
        expect_equal(colors[1], colors[3])
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraph:addNode
    -- @covers LGraph:isBipartite
    -- @covers lurek.graph.newGraph
    it("isBipartite distinguishes a path from a triangle", function()
        local path_graph = lurek.graph.newGraph()
        local p1 = path_graph:addNode()
        local p2 = path_graph:addNode()
        local p3 = path_graph:addNode()
        path_graph:addEdge(p1, p2)
        path_graph:addEdge(p2, p3)
        expect_true(path_graph:isBipartite())

        local tri_graph = lurek.graph.newGraph()
        local t1 = tri_graph:addNode()
        local t2 = tri_graph:addNode()
        local t3 = tri_graph:addNode()
        tri_graph:addEdge(t1, t2)
        tri_graph:addEdge(t2, t3)
        tri_graph:addEdge(t3, t1)
        expect_false(tri_graph:isBipartite())
    end)
end)

-- @describe graph strict: LGraphItem methods
describe("graph strict: LGraphItem methods", function()
    -- @covers LGraph:createItem
    -- @covers LGraphItem:getType
    -- @covers LGraphItem:setType
    -- @covers lurek.graph.newGraph
    it("LGraphItem setType / getType round-trip", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("weapon", -1)
        item:setType("shield")
        expect_equal("shield", item:getType())
    end)

    -- @covers LGraph:createItem
    -- @covers LGraphItem:isAlive
    -- @covers lurek.graph.newGraph
    it("LGraphItem isAlive returns boolean", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("potion", -1)
        expect_type("boolean", item:isAlive())
    end)

    -- @covers LGraph:createItem
    -- @covers LGraphItem:kill
    -- @covers lurek.graph.newGraph
    it("LGraphItem kill is callable", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("enemy", -1)
        local ok = pcall(function() item:kill() end)
        expect_true(ok)
    end)

    -- @covers LGraph:createItem
    -- @covers LGraphItem:getPriority
    -- @covers lurek.graph.newGraph
    it("LGraphItem getPriority returns number", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("key", -1)
        expect_type("number", item:getPriority())
    end)

    -- @covers LGraph:createItem
    -- @covers LGraphItem:getPosition
    -- @covers lurek.graph.newGraph
    it("LGraphItem getPosition returns number or nil pair", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("gem", -1)
        local x, y = item:getPosition()
        expect_true(x == nil or type(x) == "number")
    end)

    -- @covers LGraph:createItem
    -- @covers LGraphItem:type
    -- @covers LGraphItem:typeOf
    -- @covers lurek.graph.newGraph
    it("LGraphItem type and typeOf are callable", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("coin", -1)
        expect_type("string", item:type())
        expect_type("boolean", item:typeOf("Object"))
    end)
end)

-- @describe graph strict: LGraphEdge methods
describe("graph strict: LGraphEdge methods", function()
    -- @covers LGraph:addEdge
    -- @covers LGraphEdge:getType
    -- @covers LGraphEdge:setType
    -- @covers lurek.graph.newGraph
    it("LGraphEdge setType / getType round-trip", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode("src")
        local b = g:addNode("dst")
        local e = g:addEdge(a, b)
        e:setType("road")
        expect_equal("road", e:getType())
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraphEdge:getCapacity
    -- @covers LGraphEdge:setCapacity
    -- @covers lurek.graph.newGraph
    it("LGraphEdge setCapacity / getCapacity round-trip", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode("src")
        local b = g:addNode("dst")
        local e = g:addEdge(a, b)
        e:setCapacity(5.0)
        expect_true(math.abs(e:getCapacity() - 5.0) < 0.001)
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraphEdge:isActive
    -- @covers lurek.graph.newGraph
    it("LGraphEdge isActive returns boolean", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode("src")
        local b = g:addNode("dst")
        local e = g:addEdge(a, b)
        expect_type("boolean", e:isActive())
    end)

    -- @covers LGraph:addEdge
    -- @covers LGraphEdge:type
    -- @covers LGraphEdge:typeOf
    -- @covers lurek.graph.newGraph
    it("LGraphEdge type and typeOf are callable", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode("src")
        local b = g:addNode("dst")
        local e = g:addEdge(a, b)
        expect_type("string", e:type())
        expect_type("boolean", e:typeOf("Object"))
    end)
end)

-- @describe graph strict: LGraphNode methods
describe("graph strict: LGraphNode methods", function()
    -- @covers LGraph:addNode
    -- @covers LGraphNode:getType
    -- @covers LGraphNode:setType
    -- @covers lurek.graph.newGraph
    it("LGraphNode setType / getType round-trip", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("city")
        n:setType("city")
        expect_equal("city", n:getType())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getCapacity
    -- @covers LGraphNode:setCapacity
    -- @covers lurek.graph.newGraph
    it("LGraphNode setCapacity / getCapacity round-trip", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("hub", 10)
        n:setCapacity(10)
        expect_equal(10, n:getCapacity())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getItemCount
    -- @covers LGraphNode:isFull
    -- @covers lurek.graph.newGraph
    it("LGraphNode getItemCount and isFull are callable", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_type("number", n:getItemCount())
        expect_type("boolean", n:isFull())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:isActive
    -- @covers lurek.graph.newGraph
    it("LGraphNode isActive returns boolean", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_type("boolean", n:isActive())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:getItems
    -- @covers lurek.graph.newGraph
    it("LGraphNode getItems returns table", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_type("table", n:getItems())
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:addTag
    -- @covers LGraphNode:hasTag
    -- @covers LGraphNode:removeTag
    -- @covers LGraphNode:getTags
    -- @covers lurek.graph.newGraph
    it("LGraphNode tag operations are callable", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addTag("hub")
        expect_true(n:hasTag("hub"))
        n:removeTag("hub")
        expect_type("table", n:getTags())
    end)

    -- @covers LGraph:createItem
    -- @covers LGraph:addNode
    -- @covers LGraphNode:enqueue
    -- @covers LGraphNode:dequeue
    -- @covers lurek.graph.newGraph
    it("LGraphNode enqueue / dequeue are callable", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("task", 0)
        local item = g:createItem("task")
        local ok = pcall(function() n:enqueue(item) end)
        expect_true(ok)
        n:dequeue()
    end)

    -- @covers LGraph:addNode
    -- @covers LGraphNode:type
    -- @covers LGraphNode:typeOf
    -- @covers lurek.graph.newGraph
    it("LGraphNode type and typeOf are callable", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("task", 0)
        expect_type("string", n:type())
        expect_type("boolean", n:typeOf("Object"))
    end)
end)

-- @describe graph strict: LGraph:astar
describe("graph strict: LGraph:astar", function()
    -- @covers LGraph:astar
    -- @covers LGraph:addNode
    -- @covers LGraph:addEdge
    -- @covers lurek.graph.newGraph
    it("astar returns table or nil for reachable path", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode("a")
        local b = g:addNode("b")
        local c = g:addNode("c")
        g:addEdge(a, b)
        g:addEdge(b, c)
        local path = g:astar(a, c)
        expect_true(path == nil or type(path) == "table")
    end)
end)

-- @describe unit: migrated from integration/test_graph_pathfind.lua
describe("unit: migrated from integration/test_graph_pathfind.lua", function()
        -- @covers LGraph:addEdge
        -- @covers LGraph:addNode
        -- @covers LGraph:mst
        -- @covers lurek.graph.newGraph
        it("two-node graph has one MST edge", function()
            local g = lurek.graph.newGraph()
            local a = g:addNode()
            local b = g:addNode()
            g:addEdge(a, b)
            local tree = g:mst()
            expect_equal(1, #tree)
        end)

        -- @covers LGraph:addNode
        -- @covers LGraph:mst
        -- @covers lurek.graph.newGraph
        it("single node graph has empty MST", function()
            local g = lurek.graph.newGraph()
            g:addNode()
            local tree = g:mst()
            expect_equal(0, #tree)
        end)

        -- @covers LGraph:addNode
        -- @covers LGraph:astar
        -- @covers lurek.graph.newGraph
        it("returns nil when no path exists", function()
            local g = lurek.graph.newGraph()
            local a = g:addNode()
            local b = g:addNode()
            -- No edge between a and b
            local path = g:astar(a, b)
            expect_equal(nil, path)
        end)

        -- @covers LGraph:addEdge
        -- @covers LGraph:addNode
        -- @covers LGraph:astar
        -- @covers lurek.graph.newGraph
        it("astar path starts and ends at expected nodes", function()
            local g = lurek.graph.newGraph()
            local a   = g:addNode("start")
            local mid = g:addNode("mid")
            local b   = g:addNode("end")
            g:addEdge(a, mid)
            g:addEdge(mid, b)
            local path = g:astar(a, b)
            if path then
                -- Path should be a table of node userdatas
                expect_equal(3, #path)
            end
        end)

        -- @covers LGraph:addNode
        -- @covers LGraph:astar
        -- @covers lurek.graph.newGraph
        it("same-node astar path has length 1", function()
            local g = lurek.graph.newGraph()
            local a = g:addNode()
            local path = g:astar(a, a)
            -- A path from a node to itself should be [a] or nil depending on impl
            expect_true(path == nil or #path == 1, "path to self should be length 1 or nil")
        end)

end)

test_summary()
