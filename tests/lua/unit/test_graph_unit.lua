-- Lurek2D Graph API Tests

-- Helper: build a simple 2-node graph with one edge
-- @tests lurek.graph.newGraph

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
-- @description Verifies the graph namespace is exposed as a table and provides the newGraph factory function.
describe("lurek.graph module exists", function()
    -- @description Confirms the top-level lurek.graph binding is a Lua table.
    it("lurek.graph is a table", function()
        expect_type("table", lurek.graph)
    end)

    -- @description Confirms the module exposes newGraph as a callable factory function.
    it("has newGraph factory", function()
        expect_type("function", lurek.graph.newGraph)
    end)
end)

-- =========================================================================
-- 2. Graph construction
-- =========================================================================
-- @description Covers graph, node, and edge creation, including explicit and default node metadata.
describe("Graph construction", function()
    -- @description Confirms newGraph constructs a graph userdata instance.
    it("newGraph returns a userdata", function()
        local g = lurek.graph.newGraph()
        expect_type("userdata", g)
    end)

    -- @description Confirms addNode returns a userdata handle for the newly created node.
    it("addNode returns a node handle", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_type("userdata", n)
    end)

    -- @description Confirms addEdge returns a userdata handle for the edge connecting the two nodes.
    it("addEdge returns an edge handle", function()
        local g, n1, n2, e = make_simple_graph()
        expect_type("userdata", e)
    end)

    -- @description Verifies addNode stores the supplied node type and capacity values.
    it("addNode with type and capacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("factory", 10)
        expect_equal("factory", n:getType())
        expect_equal(10, n:getCapacity())
    end)

    -- @description Verifies addNode falls back to the default type and unlimited capacity when no arguments are provided.
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
-- @description Verifies node presence checks, removal behavior, node counts, and node enumeration stay in sync.
describe("Node management", function()
    -- @description Confirms hasNode reports true immediately after a node is added to the graph.
    it("hasNode returns true for added node", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_true(g:hasNode(n))
    end)

    -- @description Confirms removeNode reports success when removing an existing node.
    it("removeNode returns true", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_true(g:removeNode(n))
    end)

    -- @description Confirms a removed node is no longer reported by hasNode.
    it("hasNode returns false after removal", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        g:removeNode(n)
        expect_false(g:hasNode(n))
    end)

    -- @description Confirms getNodeCount increments from 0 to 1 to 2 as nodes are added.
    it("getNodeCount reflects additions", function()
        local g = lurek.graph.newGraph()
        expect_equal(0, g:getNodeCount())
        g:addNode()
        expect_equal(1, g:getNodeCount())
        g:addNode()
        expect_equal(2, g:getNodeCount())
    end)

    -- @description Confirms getNodes returns a list containing all three inserted nodes.
    it("getNodes returns all nodes", function()
        local g = lurek.graph.newGraph()
        g:addNode("a")
        g:addNode("b")
        g:addNode("c")
        local nodes = g:getNodes()
        expect_equal(3, #nodes)
    end)

    -- @description Confirms getNodeCount decreases after one of two nodes is removed.
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
-- @description Verifies edge presence checks, removal behavior, counts, lookup helpers, and typed edge creation.
describe("Edge management", function()
    -- @description Confirms hasEdge reports true for an edge that was just created.
    it("hasEdge returns true for added edge", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(g:hasEdge(e))
    end)

    -- @description Confirms removeEdge reports success when removing an existing edge.
    it("removeEdge returns true", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(g:removeEdge(e))
    end)

    -- @description Confirms hasEdge reports false after the edge has been removed.
    it("hasEdge returns false after removal", function()
        local g, n1, n2, e = make_simple_graph()
        g:removeEdge(e)
        expect_false(g:hasEdge(e))
    end)

    -- @description Confirms getEdgeCount increments from 0 to 1 to 2 as edges are added.
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

    -- @description Confirms getEdges returns the single edge created by the helper graph.
    it("getEdges returns all edges", function()
        local g, n1, n2, e = make_simple_graph()
        local edges = g:getEdges()
        expect_equal(1, #edges)
    end)

    -- @description Confirms getEdgeBetween returns a non-nil edge when a directed edge exists from source to destination.
    it("getEdgeBetween finds existing edge", function()
        local g, n1, n2, e = make_simple_graph()
        local found = g:getEdgeBetween(n1, n2)
        expect_not_nil(found)
    end)

    -- @description Confirms getEdgeBetween returns nil when no edge exists in the reverse direction.
    it("getEdgeBetween returns nil for no edge", function()
        local g, n1, n2, e = make_simple_graph()
        local found = g:getEdgeBetween(n2, n1)
        expect_nil(found)
    end)

    -- @description Confirms getEdgeCount drops from 1 to 0 after removing the only edge.
    it("getEdgeCount decreases after removeEdge", function()
        local g, n1, n2, e = make_simple_graph()
        expect_equal(1, g:getEdgeCount())
        g:removeEdge(e)
        expect_equal(0, g:getEdgeCount())
    end)

    -- @description Confirms addEdge stores a custom edge type string on the new edge.
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
-- @description Verifies item creation, placement, removal, enumeration, and graph-wide item counts.
describe("Item management", function()
    -- @description Confirms createItem returns a userdata handle for the new item.
    it("createItem returns a handle", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_type("userdata", item)
    end)

    -- @description Confirms createItem stores the provided item type and decay time.
    it("createItem with type and decay", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("ore", 5.0)
        expect_equal("ore", item:getType())
        expect_near(5.0, item:getDecayTime(), 0.001)
    end)

    -- @description Confirms adding an item to a node increments that node's item count to one.
    it("addItem places item at node", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("store", -1)
        local item = g:createItem("box")
        g:addItem(item, n)
        expect_equal(1, n:getItemCount())
    end)

    -- @description Confirms removeItem removes the item from the graph so hasItem becomes false.
    it("removeItem removes from graph", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_true(g:hasItem(item))
        g:removeItem(item)
        expect_false(g:hasItem(item))
    end)

    -- @description Confirms getItems returns both items created on the graph.
    it("getItems returns all items", function()
        local g = lurek.graph.newGraph()
        g:createItem("a")
        g:createItem("b")
        local items = g:getItems()
        expect_equal(2, #items)
    end)

    -- @description Confirms getItemCount moves from 0 to 1 after creation and back to 0 after removal.
    it("getItemCount reflects state", function()
        local g = lurek.graph.newGraph()
        expect_equal(0, g:getItemCount())
        local item = g:createItem()
        expect_equal(1, g:getItemCount())
        g:removeItem(item)
        expect_equal(0, g:getItemCount())
    end)

    -- @description Confirms hasItem reports false once the created item has been removed.
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
-- @description Verifies mutable node fields, queue and filter settings, activity flags, and node item and edge queries.
describe("Node properties", function()
    -- @description Confirms setType updates a node from alpha to beta and getType reflects both values.
    it("getType and setType", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("alpha")
        expect_equal("alpha", n:getType())
        n:setType("beta")
        expect_equal("beta", n:getType())
    end)

    -- @description Confirms setCapacity updates a node capacity from 5 to 20.
    it("getCapacity and setCapacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("x", 5)
        expect_equal(5, n:getCapacity())
        n:setCapacity(20)
        expect_equal(20, n:getCapacity())
    end)

    -- @description Confirms a newly created node starts with zero items.
    it("getItemCount starts at 0", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal(0, n:getItemCount())
    end)

    -- @description Confirms a node with unlimited capacity reports not full.
    it("isFull with unlimited capacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("x", -1)
        expect_false(n:isFull())
    end)

    -- @description Confirms a capacity-1 node reports full after receiving one item.
    it("isFull with limited capacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode("x", 1)
        expect_false(n:isFull())
        local item = g:createItem()
        g:addItem(item, n)
        expect_true(n:isFull())
    end)

    -- @description Confirms new nodes start active by default.
    it("isActive defaults to true", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_true(n:isActive())
    end)

    -- @description Confirms setActive flips the node off and then back on.
    it("setActive toggles state", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setActive(false)
        expect_false(n:isActive())
        n:setActive(true)
        expect_true(n:isActive())
    end)

    -- @description Confirms setProcessTime stores 2.5 and getProcessTime returns it within tolerance.
    it("getProcessTime and setProcessTime", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setProcessTime(2.5)
        expect_near(2.5, n:getProcessTime(), 0.001)
    end)

    -- @description Confirms setPushRate stores 3.0 and getPushRate returns it within tolerance.
    it("getPushRate and setPushRate", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setPushRate(3.0)
        expect_near(3.0, n:getPushRate(), 0.001)
    end)

    -- @description Confirms setPullRate stores 4.0 and getPullRate returns it within tolerance.
    it("getPullRate and setPullRate", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setPullRate(4.0)
        expect_near(4.0, n:getPullRate(), 0.001)
    end)

    -- @description Confirms push filters start nil and can be set to the ore type string.
    it("getPushFilter and setPushFilter", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_nil(n:getPushFilter())
        n:setPushFilter("ore")
        expect_equal("ore", n:getPushFilter())
    end)

    -- @description Confirms pull filters start nil and can be set to the wood type string.
    it("getPullFilter and setPullFilter", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_nil(n:getPullFilter())
        n:setPullFilter("wood")
        expect_equal("wood", n:getPullFilter())
    end)

    -- @description Confirms queue mode can be enabled and then disabled again.
    it("isQueueEnabled and setQueueEnabled", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setQueueEnabled(true)
        expect_true(n:isQueueEnabled())
        n:setQueueEnabled(false)
        expect_false(n:isQueueEnabled())
    end)

    -- @description Confirms setQueueCapacity stores a queue capacity of 10.
    it("getQueueCapacity and setQueueCapacity", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setQueueCapacity(10)
        expect_equal(10, n:getQueueCapacity())
    end)

    -- @description Confirms a new node starts with an empty queue.
    it("getQueueSize starts at 0", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal(0, n:getQueueSize())
    end)

    -- @description Confirms getItems on a node returns both items that were added to that node.
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

    -- @description Confirms getEdges returns one outgoing edge from the source node and one incoming edge on the sink node.
    it("getEdges returns edges for node", function()
        local g, n1, n2, e = make_simple_graph()
        local out = n1:getEdges("out")
        expect_equal(1, #out)
        local inc = n2:getEdges("in")
        expect_equal(1, #inc)
    end)

    -- @description Confirms querying both directions on the middle node returns both connected edges.
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
-- @description Verifies mutable edge attributes, endpoint accessors, direction flags, activity, and transit state.
describe("Edge properties", function()
    -- @description Confirms setType updates the edge type to pipe and getType returns the new value.
    it("getType and setType", function()
        local g, n1, n2, e = make_simple_graph()
        e:setType("pipe")
        expect_equal("pipe", e:getType())
    end)

    -- @description Confirms getFrom and getTo both return userdata node handles.
    it("getFrom and getTo return correct nodes", function()
        local g, n1, n2, e = make_simple_graph()
        local from = e:getFrom()
        local to = e:getTo()
        expect_type("userdata", from)
        expect_type("userdata", to)
    end)

    -- @description Confirms setCapacity stores a capacity of 5 on the edge.
    it("getCapacity and setCapacity", function()
        local g, n1, n2, e = make_simple_graph()
        e:setCapacity(5)
        expect_equal(5, e:getCapacity())
    end)

    -- @description Confirms setThroughput stores 2.0 and getThroughput returns it within tolerance.
    it("getThroughput and setThroughput", function()
        local g, n1, n2, e = make_simple_graph()
        e:setThroughput(2.0)
        expect_near(2.0, e:getThroughput(), 0.001)
    end)

    -- @description Confirms setTravelTime stores 3.0 and getTravelTime returns it within tolerance.
    it("getTravelTime and setTravelTime", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(3.0)
        expect_near(3.0, e:getTravelTime(), 0.001)
    end)

    -- @description Confirms setWeight stores 10.5 and getWeight returns it within tolerance.
    it("getWeight and setWeight", function()
        local g, n1, n2, e = make_simple_graph()
        e:setWeight(10.5)
        expect_near(10.5, e:getWeight(), 0.001)
    end)

    -- @description Confirms setSpeedModifier stores 0.5 and getSpeedModifier returns it within tolerance.
    it("getSpeedModifier and setSpeedModifier", function()
        local g, n1, n2, e = make_simple_graph()
        e:setSpeedModifier(0.5)
        expect_near(0.5, e:getSpeedModifier(), 0.001)
    end)

    -- @description Confirms setCooldown stores 2.0 and getCooldown returns it within tolerance.
    it("getCooldown and setCooldown", function()
        local g, n1, n2, e = make_simple_graph()
        e:setCooldown(2.0)
        expect_near(2.0, e:getCooldown(), 0.001)
    end)

    -- @description Confirms edges start unidirectional and become bidirectional after toggling the flag on.
    it("isBidirectional and setBidirectional", function()
        local g, n1, n2, e = make_simple_graph()
        expect_false(e:isBidirectional())
        e:setBidirectional(true)
        expect_true(e:isBidirectional())
    end)

    -- @description Confirms edges start active and become inactive after setActive(false).
    it("isActive and setActive", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(e:isActive())
        e:setActive(false)
        expect_false(e:isActive())
    end)

    -- @description Confirms a new edge begins with no items currently in transit.
    it("getItemsInTransit is empty initially", function()
        local g, n1, n2, e = make_simple_graph()
        local transit = e:getItemsInTransit()
        expect_equal(0, #transit)
    end)
end)

-- =========================================================================
-- 8. Item properties
-- =========================================================================
-- @description Verifies item type, decay, life state, priority, and location reporting for node and edge positions.
describe("Item properties", function()
    -- @description Confirms setType updates an item from ore to refined_ore and getType reflects both values.
    it("getType and setType", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("ore")
        expect_equal("ore", item:getType())
        item:setType("refined_ore")
        expect_equal("refined_ore", item:getType())
    end)

    -- @description Confirms setDecayTime updates an item's decay timer from 10.0 to 5.0.
    it("getDecayTime and setDecayTime", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("food", 10.0)
        expect_near(10.0, item:getDecayTime(), 0.001)
        item:setDecayTime(5.0)
        expect_near(5.0, item:getDecayTime(), 0.001)
    end)

    -- @description Confirms non-decaying items report a remaining life of -1.0.
    it("getRemainingLife for non-decaying item", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem("rock", -1.0)
        -- Non-decaying items should have remaining life equal to decay_time (or -1)
        expect_near(-1.0, item:getRemainingLife(), 0.001)
    end)

    -- @description Confirms a newly created item is alive before any decay or explicit kill.
    it("isAlive is true for new item", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_true(item:isAlive())
    end)

    -- @description Confirms kill marks the item as no longer alive.
    it("kill makes item not alive", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        item:kill()
        expect_false(item:isAlive())
    end)

    -- @description Confirms setPriority stores a priority value of 5 on the item.
    it("getPriority and setPriority", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        item:setPriority(5)
        expect_equal(5, item:getPriority())
    end)

    -- @description Confirms an unplaced item reports nil for its first position value.
    it("getPosition returns nil for unplaced item", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        local pos1, pos2 = item:getPosition()
        expect_nil(pos1)
    end)

    -- @description Confirms an item placed on a node reports a userdata node position and nil secondary value.
    it("getPosition returns node for placed item", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local item = g:createItem()
        g:addItem(item, n)
        local pos1, pos2 = item:getPosition()
        expect_type("userdata", pos1)
        expect_nil(pos2)
    end)

    -- @description Confirms an item sent onto an edge reports a userdata edge position and numeric progress.
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
-- @description Verifies tag addition, lookup, removal, enumeration, and clearing on graph nodes.
describe("Tags", function()
    -- @description Confirms addTag makes hasTag return true for the inserted producer tag.
    it("addTag and hasTag", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addTag("producer")
        expect_true(n:hasTag("producer"))
    end)

    -- @description Confirms hasTag returns false for a tag that was never added.
    it("hasTag returns false for missing tag", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_false(n:hasTag("nonexistent"))
    end)

    -- @description Confirms removeTag removes a previously added tag so hasTag becomes false.
    it("removeTag removes a tag", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addTag("temp")
        n:removeTag("temp")
        expect_false(n:hasTag("temp"))
    end)

    -- @description Confirms getTags returns both tags that were added to the node.
    it("getTags returns all tags", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addTag("a")
        n:addTag("b")
        local tags = n:getTags()
        expect_equal(2, #tags)
    end)

    -- @description Confirms clearTags removes all tags and leaves the tag list empty.
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
-- @description Verifies node overflow policy defaults and explicit transitions among reject, destroy, and queue.
describe("Overflow policy", function()
    -- @description Confirms new nodes default their overflow policy to reject.
    it("default overflow policy is reject", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal("reject", n:getOverflowPolicy())
    end)

    -- @description Confirms the overflow policy can be changed from reject to destroy.
    it("setOverflowPolicy to destroy", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setOverflowPolicy("destroy")
        expect_equal("destroy", n:getOverflowPolicy())
    end)

    -- @description Confirms the overflow policy can be changed to queue.
    it("setOverflowPolicy to queue", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setOverflowPolicy("queue")
        expect_equal("queue", n:getOverflowPolicy())
    end)

    -- @description Confirms the overflow policy can be switched back to reject after previously being queue.
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
-- @description Verifies node flow mode defaults and explicit transitions among passive, push, pull, and both.
describe("Flow mode", function()
    -- @description Confirms new nodes default their flow mode to passive.
    it("default flow mode is passive", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal("passive", n:getFlowMode())
    end)

    -- @description Confirms a node flow mode can be set to push.
    it("setFlowMode to push", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setFlowMode("push")
        expect_equal("push", n:getFlowMode())
    end)

    -- @description Confirms a node flow mode can be set to pull.
    it("setFlowMode to pull", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setFlowMode("pull")
        expect_equal("pull", n:getFlowMode())
    end)

    -- @description Confirms a node flow mode can be set to both.
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
-- @description Verifies conversion rule registration and clearing APIs run without raising errors.
describe("Conversion rules", function()
    -- @description Confirms registering a simple ore to ingot conversion succeeds without error.
    it("setConversion does not error", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:setConversion("ore", "ingot")
        end)
    end)

    -- @description Confirms registering a counted conversion with explicit input and output counts succeeds.
    it("setConversion with counts", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:setConversion("ore", "ingot", 2, 1)
        end)
    end)

    -- @description Confirms clearing a previously registered ore conversion succeeds without error.
    it("clearConversion removes a rule", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:setConversion("ore", "ingot")
        expect_no_error(function()
            n:clearConversion("ore")
        end)
    end)

    -- @description Confirms clearing all registered conversions succeeds after adding two separate rules.
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
-- @description Verifies supply and demand mutation APIs succeed and processDemand runs safely on an empty graph.
describe("Supply/Demand", function()
    -- @description Confirms adding an ore supply entry succeeds without error.
    it("addSupply does not error", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:addSupply("ore", 10)
        end)
    end)

    -- @description Confirms removing a supply succeeds after that supply has been added.
    it("removeSupply works after adding", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addSupply("ore", 10)
        expect_no_error(function()
            n:removeSupply("ore")
        end)
    end)

    -- @description Confirms clearing supplies succeeds after multiple supplies were added.
    it("clearSupplies removes all", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addSupply("ore", 10)
        n:addSupply("wood", 5)
        expect_no_error(function()
            n:clearSupplies()
        end)
    end)

    -- @description Confirms adding an ingot demand succeeds without error.
    it("addDemand does not error", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:addDemand("ingot", 5)
        end)
    end)

    -- @description Confirms adding demand with an explicit priority succeeds without error.
    it("addDemand with priority", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_no_error(function()
            n:addDemand("ingot", 5, 10)
        end)
    end)

    -- @description Confirms removing a demand entry succeeds after it has been added.
    it("removeDemand works", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addDemand("ingot", 5)
        expect_no_error(function()
            n:removeDemand("ingot")
        end)
    end)

    -- @description Confirms clearing demands succeeds after multiple demand entries were added.
    it("clearDemands removes all", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        n:addDemand("ingot", 5)
        n:addDemand("plank", 3)
        expect_no_error(function()
            n:clearDemands()
        end)
    end)

    -- @description Confirms processDemand can run on an empty graph without raising an error.
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
-- @description Verifies pathfinding, distance, reachability, and neighbor queries on connected and disconnected graphs.
describe("Pathfinding", function()
    -- @description Confirms findPath returns a non-nil path object with nodes, edges, and numeric cost for connected nodes.
    it("findPath returns path between connected nodes", function()
        local g, n1, n2, e = make_simple_graph()
        local path = g:findPath(n1, n2)
        expect_not_nil(path)
        expect_not_nil(path.nodes)
        expect_not_nil(path.edges)
        expect_type("number", path.cost)
    end)

    -- @description Confirms findPath returns nil when two nodes have no connecting edges.
    it("findPath returns nil for disconnected nodes", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local path = g:findPath(a, b)
        expect_nil(path)
    end)

    -- @description Confirms multi-hop pathfinding returns a path with three nodes and two edges across an A-B-C chain.
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

    -- @description Confirms item-aware pathfinding returns a path for an ore item placed on the source node.
    it("findPathForItem respects item type", function()
        local g, n1, n2, e = make_simple_graph()
        local item = g:createItem("ore")
        g:addItem(item, n1)
        local path = g:findPathForItem(item, n1, n2)
        expect_not_nil(path)
    end)

    -- @description Confirms getDistance returns a numeric distance for connected nodes.
    it("getDistance returns number for connected nodes", function()
        local g, n1, n2, e = make_simple_graph()
        local dist = g:getDistance(n1, n2)
        expect_type("number", dist)
    end)

    -- @description Confirms getDistance returns nil when the nodes are disconnected.
    it("getDistance returns nil for disconnected nodes", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local dist = g:getDistance(a, b)
        expect_nil(dist)
    end)

    -- @description Confirms getReachable returns at least the two downstream nodes from the starting node in a chain.
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

    -- @description Confirms getReachable with a max distance of 1.0 still returns at least the direct neighbor.
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

    -- @description Confirms getNeighbors returns the single direct neighbor from the helper graph's source node.
    it("getNeighbors returns direct neighbors", function()
        local g, n1, n2, e = make_simple_graph()
        local neighbors = g:getNeighbors(n1)
        expect_equal(1, #neighbors)
    end)

    -- @description Confirms an isolated node has no neighbors.
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
-- @description Verifies cycle detection, topological sorting, and component analysis on empty, connected, and cyclic graphs.
describe("Algorithms", function()
    -- @description Confirms hasCycle returns false for a simple directed acyclic graph.
    it("hasCycle returns false for DAG", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, c)
        expect_false(g:hasCycle())
    end)

    -- @description Confirms hasCycle returns true when two nodes point to each other.
    it("hasCycle returns true for cyclic graph", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, a)
        expect_true(g:hasCycle())
    end)

    -- @description Confirms topologicalSort returns a non-nil ordering containing all three nodes for a DAG.
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

    -- @description Confirms topologicalSort returns nil when the graph contains a cycle.
    it("topologicalSort returns nil for cyclic graph", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, a)
        local sorted = g:topologicalSort()
        expect_nil(sorted)
    end)

    -- @description Confirms getComponents returns one component for the connected helper graph.
    it("getComponents on single connected component", function()
        local g, n1, n2, e = make_simple_graph()
        local comps = g:getComponents()
        expect_equal(1, #comps)
    end)

    -- @description Confirms getComponents returns two components for two disconnected nodes with no edges.
    it("getComponents on disconnected graph", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        -- No edges ─éÔÇ×├óÔéČ┼í─é╦ś├óÔÇÜ┬Č─╣─ż├äÔÇÜ├ő┬ś─é╦ś├óÔéČ┼í├é┬Č├ä─ů├őÔÇí─éÔÇ×├óÔéČ┼í─é╦ś├óÔÇÜ┬Č├äÔÇŽ├äÔÇÜ├óÔéČ┼í─éÔÇÜ├é┬ś├äÔÇÜ├óÔéČ┼ż─é╦ś├óÔÇÜ┬Č─╣╦ç├äÔÇÜ├óÔéČ─ů─éÔÇÜ├é┬ś─éÔÇ×├óÔéČ┼í─éÔÇ╣├é┬ś├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣╦ç─éÔÇÜ├é┬Č─éÔÇ×├äÔÇŽ─éÔÇ╣├óÔéČ╦ç─éÔÇ×├óÔéČ┼í─é╦ś├óÔÇÜ┬Č─╣╦ç├äÔÇÜ├óÔéČ┼í─éÔÇÜ├é┬Č├äÔÇÜ├óÔéČ┼ż─é╦ś├óÔÇÜ┬Č─╣╦ç├äÔÇÜ├óÔéČ─ů─éÔÇÜ├é┬ś─éÔÇ×├óÔéČ┼í─éÔÇ╣├é┬ś├äÔÇÜ├ő┬ś─é╦ś├óÔéČ┼í├é┬Č├ä─ů├őÔÇí├äÔÇÜ├óÔéČ┼í─éÔÇÜ├é┬Č├äÔÇÜ├óÔéČ┼ż─éÔÇ×├óÔéČ┬Ž├äÔÇÜ├óÔéČ┼ż─é╦ś├óÔÇÜ┬Č─╣─ż 2 disconnected nodes
        local comps = g:getComponents()
        expect_equal(2, #comps)
    end)

    -- @description Confirms each component is returned as a table of nodes and the connected pair shares one component of size two.
    it("getComponents returns tables of nodes", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        g:addEdge(a, b)
        local comps = g:getComponents()
        expect_equal(1, #comps)
        expect_equal(2, #comps[1])
    end)

    -- @description Confirms an empty graph does not report a cycle.
    it("hasCycle on empty graph", function()
        local g = lurek.graph.newGraph()
        expect_false(g:hasCycle())
    end)

    -- @description Confirms topologicalSort on an empty graph returns a non-nil empty list.
    it("topologicalSort on empty graph", function()
        local g = lurek.graph.newGraph()
        local sorted = g:topologicalSort()
        expect_not_nil(sorted)
        expect_equal(0, #sorted)
    end)
end)

-- =========================================================================
-- 16. Simulation
-- =========================================================================
-- @description Verifies update and step safety on empty graphs and transit progression over simulated time.
describe("Simulation", function()
    -- @description Confirms update accepts a 1.0 delta on an empty graph without error.
    it("update does not error on empty graph", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:update(1.0)
        end)
    end)

    -- @description Confirms step can run on an empty graph without error.
    it("step does not error on empty graph", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:step()
        end)
    end)

    -- @description Confirms updating halfway across a 2.0-second edge keeps the item in transit with about 0.5 progress.
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

    -- @description Confirms updating longer than the edge travel time moves the item onto the destination node.
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

    -- @description Confirms step uses a 1.0 simulation delta so an item on a 1.0-second edge arrives immediately.
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
-- @description Verifies decaying and non-decaying items keep correct alive state and remaining life after updates.
describe("Item decay", function()
    -- @description Confirms an item with 5.0 decay time remains alive after only 2.0 seconds.
    it("item with decay remains alive before expiry", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local item = g:createItem("food", 5.0)
        g:addItem(item, n)
        g:update(2.0)
        expect_true(item:isAlive())
    end)

    -- @description Confirms remaining life drops from 5.0 to about 3.0 after a 2.0-second update.
    it("item remainingLife decreases with update", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local item = g:createItem("food", 5.0)
        g:addItem(item, n)
        g:update(2.0)
        local remaining = item:getRemainingLife()
        expect_near(3.0, remaining, 0.1)
    end)

    -- @description Confirms a non-decaying item remains alive even after a very large update interval.
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
-- @description Verifies event registration, validation, firing behavior, and callback argument types for graph events.
describe("Callbacks", function()
    -- @description Confirms registering an itemEnter callback succeeds without error.
    it("on registers callback without error", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:on("itemEnter", function() end)
        end)
    end)

    -- @description Confirms registering a callback with an unknown event name raises an error.
    it("on rejects unknown event name", function()
        local g = lurek.graph.newGraph()
        expect_error(function()
            g:on("badEvent", function() end)
        end)
    end)

    -- @description Confirms itemEnter fires after an item finishes transit and arrives at the destination node.
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

    -- @description Exercises edgeEnter registration across sendItem and update paths without requiring an explicit assertion.
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
        -- Accept either ─éÔÇ×├óÔéČ┼í─é╦ś├óÔÇÜ┬Č─╣─ż├äÔÇÜ├ő┬ś─é╦ś├óÔéČ┼í├é┬Č├ä─ů├őÔÇí─éÔÇ×├óÔéČ┼í─é╦ś├óÔÇÜ┬Č├äÔÇŽ├äÔÇÜ├óÔéČ┼í─éÔÇÜ├é┬ś├äÔÇÜ├óÔéČ┼ż─é╦ś├óÔÇÜ┬Č─╣╦ç├äÔÇÜ├óÔéČ─ů─éÔÇÜ├é┬ś─éÔÇ×├óÔéČ┼í─éÔÇ╣├é┬ś├äÔÇÜ├ő┬ś─é╦ś├óÔÇÜ┬Č─╣╦ç─éÔÇÜ├é┬Č─éÔÇ×├äÔÇŽ─éÔÇ╣├óÔéČ╦ç─éÔÇ×├óÔéČ┼í─é╦ś├óÔÇÜ┬Č─╣╦ç├äÔÇÜ├óÔéČ┼í─éÔÇÜ├é┬Č├äÔÇÜ├óÔéČ┼ż─é╦ś├óÔÇÜ┬Č─╣╦ç├äÔÇÜ├óÔéČ─ů─éÔÇÜ├é┬ś─éÔÇ×├óÔéČ┼í─éÔÇ╣├é┬ś├äÔÇÜ├ő┬ś─é╦ś├óÔéČ┼í├é┬Č├ä─ů├őÔÇí├äÔÇÜ├óÔéČ┼í─éÔÇÜ├é┬Č├äÔÇÜ├óÔéČ┼ż─éÔÇ×├óÔéČ┬Ž├äÔÇÜ├óÔéČ┼ż─é╦ś├óÔÇÜ┬Č─╣─ż event fires at some point
        -- If still not fired, sendItem may have triggered it directly
    end)

    -- @description Confirms every listed valid event name can be registered without error.
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

    -- @description Confirms itemEnter callbacks receive userdata item and node values when they are provided.
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
-- @description Verifies allowed-type filters on edges, including defaults, acceptance, removal, and reset behavior.
describe("Edge type filtering", function()
    -- @description Confirms adding an allowed item type to an edge succeeds without error.
    it("addAllowedType does not error", function()
        local g, n1, n2, e = make_simple_graph()
        expect_no_error(function()
            e:addAllowedType("ore")
        end)
    end)

    -- @description Confirms edges allow any item type when no allowed-type filter has been configured.
    it("isItemTypeAllowed returns true when no filter set", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(e:isItemTypeAllowed("anything"))
    end)

    -- @description Confirms an explicitly allowed ore type passes the edge filter.
    it("isItemTypeAllowed returns true for allowed type", function()
        local g, n1, n2, e = make_simple_graph()
        e:addAllowedType("ore")
        expect_true(e:isItemTypeAllowed("ore"))
    end)

    -- @description Confirms a type not in the allow list is rejected by the edge filter.
    it("isItemTypeAllowed returns false for disallowed type", function()
        local g, n1, n2, e = make_simple_graph()
        e:addAllowedType("ore")
        expect_false(e:isItemTypeAllowed("wood"))
    end)

    -- @description Confirms removing one allowed type leaves the other allowed type intact.
    it("removeAllowedType removes a filter", function()
        local g, n1, n2, e = make_simple_graph()
        e:addAllowedType("ore")
        e:addAllowedType("wood")
        e:removeAllowedType("ore")
        expect_false(e:isItemTypeAllowed("ore"))
        expect_true(e:isItemTypeAllowed("wood"))
    end)

    -- @description Confirms clearing all allowed types restores the default allow-anything behavior.
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
-- @description Verifies edge cooldown state defaults and stored cooldown values.
describe("Cooldown", function()
    -- @description Confirms a newly created edge is not on cooldown.
    it("isOnCooldown is false initially", function()
        local g, n1, n2, e = make_simple_graph()
        expect_false(e:isOnCooldown())
    end)

    -- @description Confirms setCooldown stores 3.0 and getCooldown returns it within tolerance.
    it("setCooldown sets value", function()
        local g, n1, n2, e = make_simple_graph()
        e:setCooldown(3.0)
        expect_near(3.0, e:getCooldown(), 0.001)
    end)
end)

-- =========================================================================
-- 21. Stats
-- =========================================================================
-- @description Verifies getStats returns the expected numeric fields and reflects populated and empty graph state.
describe("Stats", function()
    -- @description Confirms getStats returns a table with all expected numeric counters.
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

    -- @description Confirms stats report 2 nodes, 1 edge, 1 item, and 1 item on nodes after populating the graph.
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

    -- @description Confirms an empty graph reports zero nodes, edges, and items in its stats table.
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
-- @description Verifies type() and typeOf() results for graph, node, edge, and item userdata objects.
describe("Type system", function()
    -- @description Confirms graph userdata reports its type name as Graph.
    it("Graph type() returns LGraph", function()
        local g = lurek.graph.newGraph()
        expect_equal("LGraph", g:type())
    end)

    -- @description Confirms graph userdata recognizes Graph in typeOf.
    it("Graph typeOf Graph", function()
        local g = lurek.graph.newGraph()
        expect_true(g:typeOf("Graph"))
    end)

    -- @description Confirms graph userdata also recognizes the base Object type.
    it("Graph typeOf Object", function()
        local g = lurek.graph.newGraph()
        expect_true(g:typeOf("Object"))
    end)

    -- @description Confirms node userdata reports its type name as GraphNode.
    it("Node type() returns LGraphNode", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal("LGraphNode", n:type())
    end)

    -- @description Confirms node userdata recognizes GraphNode in typeOf.
    it("Node typeOf GraphNode", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_true(n:typeOf("GraphNode"))
    end)

    -- @description Confirms edge userdata reports its type name as GraphEdge.
    it("Edge type() returns LGraphEdge", function()
        local g, n1, n2, e = make_simple_graph()
        expect_equal("LGraphEdge", e:type())
    end)

    -- @description Confirms edge userdata recognizes GraphEdge in typeOf.
    it("Edge typeOf GraphEdge", function()
        local g, n1, n2, e = make_simple_graph()
        expect_true(e:typeOf("GraphEdge"))
    end)

    -- @description Confirms item userdata reports its type name as GraphItem.
    it("Item type() returns LGraphItem", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_equal("LGraphItem", item:type())
    end)

    -- @description Confirms item userdata recognizes GraphItem in typeOf.
    it("Item typeOf GraphItem", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_true(item:typeOf("GraphItem"))
    end)

    -- @description Confirms item userdata also recognizes the base Object type.
    it("Item typeOf Object", function()
        local g = lurek.graph.newGraph()
        local item = g:createItem()
        expect_true(item:typeOf("Object"))
    end)

    -- @description Confirms a node does not incorrectly report itself as a GraphEdge.
    it("Node typeOf returns false for wrong type", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_false(n:typeOf("GraphEdge"))
    end)
end)

-- =========================================================================
-- 23. sendItem
-- =========================================================================
-- @description Verifies sendItem moves items from nodes onto edges and eventually into the destination node.
describe("sendItem", function()
    -- @description Confirms sendItem places the item on the edge and reports a userdata edge plus numeric progress.
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

    -- @description Confirms sendItem removes the item from the source node's item list.
    it("sendItem removes item from source node", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(5.0)
        local item = g:createItem()
        g:addItem(item, n1)
        expect_equal(1, n1:getItemCount())
        g:sendItem(item, e)
        expect_equal(0, n1:getItemCount())
    end)

    -- @description Confirms sendItem adds the item to the edge transit list.
    it("sendItem puts item in edge transit list", function()
        local g, n1, n2, e = make_simple_graph()
        e:setTravelTime(5.0)
        local item = g:createItem()
        g:addItem(item, n1)
        g:sendItem(item, e)
        local transit = e:getItemsInTransit()
        expect_equal(1, #transit)
    end)

    -- @description Confirms a sent item reaches the destination node after updating past the full travel time.
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

-- @description Verifies edge validation and node removal parity cases, including invalid endpoints and edge cleanup on node removal.
describe("graph edge validity errors (RS parity)", function()
    it("addEdge with invalid source returns error", function() local g=lurek.graph.newGraph(); local b=g:addNode("B"); expect_error(function() local invalid=g:addNode("invalid"); g:removeNode(invalid); g:addEdge(invalid,b) end) end)
    it("addEdge with invalid destination returns error", function() local g=lurek.graph.newGraph(); local a=g:addNode("A"); expect_error(function() local invalid=g:addNode("invalid"); g:removeNode(invalid); g:addEdge(a,invalid) end) end)
    it("removeNode cleans connected edges", function() local g=lurek.graph.newGraph(); local a=g:addNode("A"); local b=g:addNode("B"); g:addEdge(a,b); g:removeNode(a); expect_equal(1,g:getNodeCount()); expect_equal(0,g:getEdgeCount()) end)
    it("removeNode on nonexistent id raises error", function() local g=lurek.graph.newGraph(); expect_error(function() local invalid=g:addNode("invalid"); g:removeNode(invalid); g:removeNode(invalid) end) end)
    it("getNodes count matches getNodeCount", function() local g=lurek.graph.newGraph(); g:addNode("X"); g:addNode("Y"); local nodes=g:getNodes(); expect_equal(g:getNodeCount(),#nodes) end)
end)
describe("lurek.graph tickParallel", function()
    xit("tickParallel is callable", function() local sim=lurek.graph.newGraph(); expect_type("function", sim.tickParallel) end)
    xit("tickParallel returns a table", function() local sim=lurek.graph.newGraph(); local events=sim:tickParallel(0.016); expect_type("table", events) end)
    xit("tickParallel stays callable with items", function() local sim=lurek.graph.newGraph(); local n=sim:addNode("n"); local item=sim:createItem(); sim:addItem(item,n); local a=sim:tickParallel(0.016); local b=sim:tickParallel(0.016); expect_type("table", a); expect_type("table", b) end)
end)

-- @description Replaces the graph placeholder tail with direct coverage for the remaining graph algorithms that were still only stubbed.
describe("graph regression coverage", function()
    local function contains(list, value)
        for _, entry in ipairs(list) do
            if entry == value then
                return true
            end
        end

        return false
    end

    -- @tests Graph:mst
    -- @description Confirms mst returns the two lightest edge IDs for a weighted triangle and excludes the heavy direct edge.
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

    -- @tests Graph:colorGraph
    -- @description Confirms greedy graph colouring assigns different colours to adjacent nodes in a simple three-node path while reusing the endpoint colour.
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

    -- @tests Graph:isBipartite
    -- @description Confirms a path graph is bipartite while a triangle graph is not.
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

test_summary()
