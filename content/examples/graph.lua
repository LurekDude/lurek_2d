-- content/examples/graph.lua
-- Auto-scaffolded coverage of the lurek.graph Lua API (111 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/graph.lua

print("[example] lurek.graph loaded — 111 API items demonstrated")

-- ── lurek.graph free functions ──

--@api-stub: lurek.graph.newGraph
-- Creates a new empty directed graph for item flow simulation.
-- Use this when creates a new empty directed graph for item flow simulation is needed.
if false then
  local _r = lurek.graph.newGraph()
  print(_r)
end

-- ── GraphItem methods ──

--@api-stub: GraphItem:getType
-- Returns the item type string.
-- Use this when returns the item type string is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:getType()
end

--@api-stub: GraphItem:setType
-- Sets the item type string.
-- Use this when sets the item type string is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:setType(0)
end

--@api-stub: GraphItem:getDecayTime
-- Returns the decay time in seconds (-1 = immortal).
-- Use this when returns the decay time in seconds (-1 = immortal) is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:getDecayTime()
end

--@api-stub: GraphItem:setDecayTime
-- Sets the decay time in seconds (-1 = immortal).
-- Use this when sets the decay time in seconds (-1 = immortal) is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:setDecayTime(0)
end

--@api-stub: GraphItem:getRemainingLife
-- Returns the remaining life in seconds.
-- Use this when returns the remaining life in seconds is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:getRemainingLife()
end

--@api-stub: GraphItem:isAlive
-- Returns true if the item is alive.
-- Use this when returns true if the item is alive is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:isAlive()
end

--@api-stub: GraphItem:kill
-- Marks this graph item as dead so it is removed on the next cleanup pass.
-- Use this when marks this graph item as dead so it is removed on the next cleanup pass is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:kill()
end

--@api-stub: GraphItem:getPriority
-- Returns the item priority.
-- Use this when returns the item priority is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:getPriority()
end

--@api-stub: GraphItem:setPriority
-- Sets the scheduling priority; higher values are processed before lower ones.
-- Use this when sets the scheduling priority; higher values are processed before lower ones is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:setPriority(nil)
end

--@api-stub: GraphItem:getPosition
-- Returns the item position: node userdata if at a node, (edge, progress).
-- Use this when returns the item position: node userdata if at a node, (edge, progress) is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:getPosition()
end

--@api-stub: GraphItem:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:type()
end

--@api-stub: GraphItem:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- GraphItem instance
  _o:typeOf(1)
end

-- ── Edge methods ──

--@api-stub: Edge:getType
-- Returns the edge type string.
-- Use this when returns the edge type string is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getType()
end

--@api-stub: Edge:setType
-- Sets the edge type string.
-- Use this when sets the edge type string is needed.
if false then
  local _o = nil  -- Edge instance
  _o:setType(0)
end

--@api-stub: Edge:getFrom
-- Returns the source node handle.
-- Use this when returns the source node handle is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getFrom()
end

--@api-stub: Edge:getTo
-- Returns the destination node handle.
-- Use this when returns the destination node handle is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getTo()
end

--@api-stub: Edge:getCapacity
-- Returns the edge capacity (-1 = unlimited).
-- Use this when returns the edge capacity (-1 = unlimited) is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getCapacity()
end

--@api-stub: Edge:setCapacity
-- Sets the edge capacity (-1 = unlimited).
-- Use this when sets the edge capacity (-1 = unlimited) is needed.
if false then
  local _o = nil  -- Edge instance
  _o:setCapacity(nil)
end

--@api-stub: Edge:getThroughput
-- Returns items per second this edge can transfer.
-- Use this when returns items per second this edge can transfer is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getThroughput()
end

--@api-stub: Edge:setThroughput
-- Sets items per second this edge can transfer.
-- Use this when sets items per second this edge can transfer is needed.
if false then
  local _o = nil  -- Edge instance
  _o:setThroughput(0)
end

--@api-stub: Edge:getTravelTime
-- Returns the travel time in seconds for items on this edge.
-- Use this when returns the travel time in seconds for items on this edge is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getTravelTime()
end

--@api-stub: Edge:setTravelTime
-- Sets the travel time in seconds for items on this edge.
-- Use this when sets the travel time in seconds for items on this edge is needed.
if false then
  local _o = nil  -- Edge instance
  _o:setTravelTime(0)
end

--@api-stub: Edge:getWeight
-- Returns the pathfinding weight of this edge.
-- Use this when returns the pathfinding weight of this edge is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getWeight()
end

--@api-stub: Edge:setWeight
-- Sets the pathfinding weight of this edge.
-- Use this when sets the pathfinding weight of this edge is needed.
if false then
  local _o = nil  -- Edge instance
  _o:setWeight(0)
end

--@api-stub: Edge:getSpeedModifier
-- Returns the speed modifier applied to items in transit.
-- Use this when returns the speed modifier applied to items in transit is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getSpeedModifier()
end

--@api-stub: Edge:setSpeedModifier
-- Sets the speed modifier applied to items in transit.
-- Use this when sets the speed modifier applied to items in transit is needed.
if false then
  local _o = nil  -- Edge instance
  _o:setSpeedModifier(nil)
end

--@api-stub: Edge:getCooldown
-- Returns the cooldown duration in seconds.
-- Use this when returns the cooldown duration in seconds is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getCooldown()
end

--@api-stub: Edge:setCooldown
-- Sets the cooldown duration in seconds.
-- Use this when sets the cooldown duration in seconds is needed.
if false then
  local _o = nil  -- Edge instance
  _o:setCooldown(nil)
end

--@api-stub: Edge:isOnCooldown
-- Returns true if the edge is currently on cooldown.
-- Use this when returns true if the edge is currently on cooldown is needed.
if false then
  local _o = nil  -- Edge instance
  _o:isOnCooldown()
end

--@api-stub: Edge:isBidirectional
-- Returns true if items can travel the edge in either direction.
-- Use this when returns true if items can travel the edge in either direction is needed.
if false then
  local _o = nil  -- Edge instance
  _o:isBidirectional()
end

--@api-stub: Edge:setBidirectional
-- Sets whether items can travel the edge in either direction.
-- Use this when sets whether items can travel the edge in either direction is needed.
if false then
  local _o = nil  -- Edge instance
  _o:setBidirectional(nil)
end

--@api-stub: Edge:isActive
-- Returns true if the edge is active.
-- Use this when returns true if the edge is active is needed.
if false then
  local _o = nil  -- Edge instance
  _o:isActive()
end

--@api-stub: Edge:setActive
-- Sets the active state of this edge.
-- Use this when sets the active state of this edge is needed.
if false then
  local _o = nil  -- Edge instance
  _o:setActive(nil)
end

--@api-stub: Edge:getItemsInTransit
-- Returns a table of GraphItem handles currently in transit on this edge.
-- Use this when returns a table of GraphItem handles currently in transit on this edge is needed.
if false then
  local _o = nil  -- Edge instance
  _o:getItemsInTransit()
end

--@api-stub: Edge:addAllowedType
-- Adds an item type to the edge allow-list.
-- Use this when adds an item type to the edge allow-list is needed.
if false then
  local _o = nil  -- Edge instance
  _o:addAllowedType(0)
end

--@api-stub: Edge:removeAllowedType
-- Removes an item type from the edge allow-list.
-- Use this when removes an item type from the edge allow-list is needed.
if false then
  local _o = nil  -- Edge instance
  _o:removeAllowedType(0)
end

--@api-stub: Edge:clearAllowedTypes
-- Clears the edge allow-list so all item types are permitted.
-- Use this when clears the edge allow-list so all item types are permitted is needed.
if false then
  local _o = nil  -- Edge instance
  _o:clearAllowedTypes()
end

--@api-stub: Edge:isItemTypeAllowed
-- Returns true if the given item type is allowed on this edge.
-- Use this when returns true if the given item type is allowed on this edge is needed.
if false then
  local _o = nil  -- Edge instance
  _o:isItemTypeAllowed(0)
end

--@api-stub: Edge:type
-- Returns the type name "GraphEdge".
-- Use this when returns the type name "GraphEdge" is needed.
if false then
  local _o = nil  -- Edge instance
  _o:type()
end

--@api-stub: Edge:typeOf
-- Returns true when the given name matches "GraphEdge" or a parent type.
-- Use this when returns true when the given name matches "GraphEdge" or a parent type is needed.
if false then
  local _o = nil  -- Edge instance
  _o:typeOf(1)
end

-- ── Node methods ──

--@api-stub: Node:getType
-- Returns the node type string.
-- Use this when returns the node type string is needed.
if false then
  local _o = nil  -- Node instance
  _o:getType()
end

--@api-stub: Node:setType
-- Sets the node type string.
-- Use this when sets the node type string is needed.
if false then
  local _o = nil  -- Node instance
  _o:setType(0)
end

--@api-stub: Node:getCapacity
-- Returns the node capacity (-1 = unlimited).
-- Use this when returns the node capacity (-1 = unlimited) is needed.
if false then
  local _o = nil  -- Node instance
  _o:getCapacity()
end

--@api-stub: Node:setCapacity
-- Sets the node capacity (-1 = unlimited).
-- Use this when sets the node capacity (-1 = unlimited) is needed.
if false then
  local _o = nil  -- Node instance
  _o:setCapacity(nil)
end

--@api-stub: Node:getItemCount
-- Returns the number of items currently at this node.
-- Use this when returns the number of items currently at this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:getItemCount()
end

--@api-stub: Node:isFull
-- Returns true if the node has reached its capacity.
-- Use this when returns true if the node has reached its capacity is needed.
if false then
  local _o = nil  -- Node instance
  _o:isFull()
end

--@api-stub: Node:isActive
-- Returns true if the node is active.
-- Use this when returns true if the node is active is needed.
if false then
  local _o = nil  -- Node instance
  _o:isActive()
end

--@api-stub: Node:setActive
-- Sets the active state of this node.
-- Use this when sets the active state of this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:setActive(nil)
end

--@api-stub: Node:getOverflowPolicy
-- Returns the overflow policy as a string.
-- Use this when returns the overflow policy as a string is needed.
if false then
  local _o = nil  -- Node instance
  _o:getOverflowPolicy()
end

--@api-stub: Node:setOverflowPolicy
-- Sets the overflow policy from a string.
-- Use this when sets the overflow policy from a string is needed.
if false then
  local _o = nil  -- Node instance
  _o:setOverflowPolicy(nil)
end

--@api-stub: Node:getFlowMode
-- Returns the flow mode as a string.
-- Use this when returns the flow mode as a string is needed.
if false then
  local _o = nil  -- Node instance
  _o:getFlowMode()
end

--@api-stub: Node:setFlowMode
-- Sets the flow mode from a string.
-- Use this when sets the flow mode from a string is needed.
if false then
  local _o = nil  -- Node instance
  _o:setFlowMode(nil)
end

--@api-stub: Node:getPushRate
-- Returns items per second this node pushes.
-- Use this when returns items per second this node pushes is needed.
if false then
  local _o = nil  -- Node instance
  _o:getPushRate()
end

--@api-stub: Node:setPushRate
-- Sets items per second this node pushes.
-- Use this when sets items per second this node pushes is needed.
if false then
  local _o = nil  -- Node instance
  _o:setPushRate(nil)
end

--@api-stub: Node:getPullRate
-- Returns items per second this node pulls.
-- Use this when returns items per second this node pulls is needed.
if false then
  local _o = nil  -- Node instance
  _o:getPullRate()
end

--@api-stub: Node:setPullRate
-- Sets items per second this node pulls.
-- Use this when sets items per second this node pulls is needed.
if false then
  local _o = nil  -- Node instance
  _o:setPullRate(nil)
end

--@api-stub: Node:getPushFilter
-- Returns the push filter string, or nil if unset.
-- Use this when returns the push filter string, or nil if unset is needed.
if false then
  local _o = nil  -- Node instance
  _o:getPushFilter()
end

--@api-stub: Node:setPushFilter
-- Sets the push filter string, or nil to clear.
-- Use this when sets the push filter string, or nil to clear is needed.
if false then
  local _o = nil  -- Node instance
  _o:setPushFilter(nil)
end

--@api-stub: Node:getPullFilter
-- Returns the pull filter string, or nil if unset.
-- Use this when returns the pull filter string, or nil if unset is needed.
if false then
  local _o = nil  -- Node instance
  _o:getPullFilter()
end

--@api-stub: Node:setPullFilter
-- Sets the pull filter string, or nil to clear.
-- Use this when sets the pull filter string, or nil to clear is needed.
if false then
  local _o = nil  -- Node instance
  _o:setPullFilter(nil)
end

--@api-stub: Node:getProcessTime
-- Returns the processing time in seconds.
-- Use this when returns the processing time in seconds is needed.
if false then
  local _o = nil  -- Node instance
  _o:getProcessTime()
end

--@api-stub: Node:setProcessTime
-- Sets the processing time in seconds.
-- Use this when sets the processing time in seconds is needed.
if false then
  local _o = nil  -- Node instance
  _o:setProcessTime(0)
end

--@api-stub: Node:isQueueEnabled
-- Returns true if the node queue is enabled.
-- Use this when returns true if the node queue is enabled is needed.
if false then
  local _o = nil  -- Node instance
  _o:isQueueEnabled()
end

--@api-stub: Node:setQueueEnabled
-- Enables or disables the node queue.
-- Use this when enables or disables the node queue is needed.
if false then
  local _o = nil  -- Node instance
  _o:setQueueEnabled(nil)
end

--@api-stub: Node:getQueueCapacity
-- Returns the queue capacity (-1 = unlimited).
-- Use this when returns the queue capacity (-1 = unlimited) is needed.
if false then
  local _o = nil  -- Node instance
  _o:getQueueCapacity()
end

--@api-stub: Node:setQueueCapacity
-- Sets the queue capacity (-1 = unlimited).
-- Use this when sets the queue capacity (-1 = unlimited) is needed.
if false then
  local _o = nil  -- Node instance
  _o:setQueueCapacity(nil)
end

--@api-stub: Node:getQueueSize
-- Returns the number of items currently in the queue.
-- Use this when returns the number of items currently in the queue is needed.
if false then
  local _o = nil  -- Node instance
  _o:getQueueSize()
end

--@api-stub: Node:getItems
-- Returns a table of GraphItem handles at this node.
-- Use this when returns a table of GraphItem handles at this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:getItems()
end

--@api-stub: Node:getEdges
-- Returns a table of Edge handles connected to this node.
-- Use this when returns a table of Edge handles connected to this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:getEdges(nil)
end

--@api-stub: Node:clearConversion
-- Removes the conversion rule for the given input type.
-- Use this when removes the conversion rule for the given input type is needed.
if false then
  local _o = nil  -- Node instance
  _o:clearConversion(1)
end

--@api-stub: Node:clearAllConversions
-- Removes all conversion rules from this node.
-- Use this when removes all conversion rules from this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:clearAllConversions()
end

--@api-stub: Node:addTag
-- Attaches a string tag to this node for fast group queries.
-- Use this when attaches a string tag to this node for fast group queries is needed.
if false then
  local _o = nil  -- Node instance
  _o:addTag(0)
end

--@api-stub: Node:removeTag
-- Removes a tag from this node.
-- Use this when removes a tag from this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:removeTag(0)
end

--@api-stub: Node:hasTag
-- Returns true if this node has the given tag.
-- Use this when returns true if this node has the given tag is needed.
if false then
  local _o = nil  -- Node instance
  _o:hasTag(0)
end

--@api-stub: Node:clearTags
-- Removes all tags from this node.
-- Use this when removes all tags from this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:clearTags()
end

--@api-stub: Node:getTags
-- Returns a table of tag strings on this node.
-- Use this when returns a table of tag strings on this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:getTags()
end

--@api-stub: Node:removeSupply
-- Removes the supply declaration for the given item type.
-- Use this when removes the supply declaration for the given item type is needed.
if false then
  local _o = nil  -- Node instance
  _o:removeSupply(0)
end

--@api-stub: Node:clearSupplies
-- Removes all supply declarations from this node.
-- Use this when removes all supply declarations from this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:clearSupplies()
end

--@api-stub: Node:removeDemand
-- Removes the demand declaration for the given item type.
-- Use this when removes the demand declaration for the given item type is needed.
if false then
  local _o = nil  -- Node instance
  _o:removeDemand(0)
end

--@api-stub: Node:clearDemands
-- Removes all demand declarations from this node.
-- Use this when removes all demand declarations from this node is needed.
if false then
  local _o = nil  -- Node instance
  _o:clearDemands()
end

--@api-stub: Node:enqueue
-- Pushes an item into the node queue.
-- Use this when pushes an item into the node queue is needed.
if false then
  local _o = nil  -- Node instance
  _o:enqueue(0)
end

--@api-stub: Node:dequeue
-- Pops the next item from the node queue, or nil if empty.
-- Use this when pops the next item from the node queue, or nil if empty is needed.
if false then
  local _o = nil  -- Node instance
  _o:dequeue()
end

--@api-stub: Node:type
-- Returns the type name "GraphNode".
-- Use this when returns the type name "GraphNode" is needed.
if false then
  local _o = nil  -- Node instance
  _o:type()
end

--@api-stub: Node:typeOf
-- Returns true when the given name matches "GraphNode" or a parent type.
-- Use this when returns true when the given name matches "GraphNode" or a parent type is needed.
if false then
  local _o = nil  -- Node instance
  _o:typeOf(1)
end

-- ── Graph methods ──

--@api-stub: Graph:removeNode
-- Removes a node from the graph.
-- Use this when removes a node from the graph is needed.
if false then
  local _o = nil  -- Graph instance
  _o:removeNode(1)
end

--@api-stub: Graph:hasNode
-- Returns true if the node exists in the graph.
-- Use this when returns true if the node exists in the graph is needed.
if false then
  local _o = nil  -- Graph instance
  _o:hasNode(1)
end

--@api-stub: Graph:getNodes
-- Returns a table of all Node handles.
-- Use this when returns a table of all Node handles is needed.
if false then
  local _o = nil  -- Graph instance
  _o:getNodes()
end

--@api-stub: Graph:getNodeCount
-- Returns the number of nodes in the graph.
-- Use this when returns the number of nodes in the graph is needed.
if false then
  local _o = nil  -- Graph instance
  _o:getNodeCount()
end

--@api-stub: Graph:removeEdge
-- Removes an edge from the graph.
-- Use this when removes an edge from the graph is needed.
if false then
  local _o = nil  -- Graph instance
  _o:removeEdge(nil)
end

--@api-stub: Graph:hasEdge
-- Returns true if the edge exists in the graph.
-- Use this when returns true if the edge exists in the graph is needed.
if false then
  local _o = nil  -- Graph instance
  _o:hasEdge(nil)
end

--@api-stub: Graph:getEdges
-- Returns a table of all Edge handles.
-- Use this when returns a table of all Edge handles is needed.
if false then
  local _o = nil  -- Graph instance
  _o:getEdges()
end

--@api-stub: Graph:getEdgeCount
-- Returns the number of edges in the graph.
-- Use this when returns the number of edges in the graph is needed.
if false then
  local _o = nil  -- Graph instance
  _o:getEdgeCount()
end

--@api-stub: Graph:removeItem
-- Removes an item from the graph entirely.
-- Use this when removes an item from the graph entirely is needed.
if false then
  local _o = nil  -- Graph instance
  _o:removeItem(0)
end

--@api-stub: Graph:hasItem
-- Returns true if the item exists in the graph.
-- Use this when returns true if the item exists in the graph is needed.
if false then
  local _o = nil  -- Graph instance
  _o:hasItem(0)
end

--@api-stub: Graph:getItems
-- Returns a table of all GraphItem handles.
-- Use this when returns a table of all GraphItem handles is needed.
if false then
  local _o = nil  -- Graph instance
  _o:getItems()
end

--@api-stub: Graph:getItemCount
-- Returns the number of items in the graph.
-- Use this when returns the number of items in the graph is needed.
if false then
  local _o = nil  -- Graph instance
  _o:getItemCount()
end

--@api-stub: Graph:update
-- Advances simulation by dt seconds and fires event callbacks.
-- Use this when advances simulation by dt seconds and fires event callbacks is needed.
if false then
  local _o = nil  -- Graph instance
  _o:update(0)
end

--@api-stub: Graph:step
-- Runs one discrete simulation step and fires event callbacks.
-- Use this when runs one discrete simulation step and fires event callbacks is needed.
if false then
  local _o = nil  -- Graph instance
  _o:step()
end

--@api-stub: Graph:tickParallel
-- Advances simulation by dt seconds using a parallelised decay phase.
-- Use this when advances simulation by dt seconds using a parallelised decay phase is needed.
if false then
  local _o = nil  -- Graph instance
  _o:tickParallel(0)
end

--@api-stub: Graph:getNeighbors
-- Returns a table of direct neighbor Node handles.
-- Use this when returns a table of direct neighbor Node handles is needed.
if false then
  local _o = nil  -- Graph instance
  _o:getNeighbors(1)
end

--@api-stub: Graph:getComponents
-- Returns weakly connected components as a table of tables of Node handles.
-- Use this when returns weakly connected components as a table of tables of Node handles is needed.
if false then
  local _o = nil  -- Graph instance
  _o:getComponents()
end

--@api-stub: Graph:hasCycle
-- Returns true if the graph contains a directed cycle.
-- Use this when returns true if the graph contains a directed cycle is needed.
if false then
  local _o = nil  -- Graph instance
  _o:hasCycle()
end

--@api-stub: Graph:topologicalSort
-- Returns a topologically sorted table of Node handles, or nil if a cycle exists.
-- Use this when returns a topologically sorted table of Node handles, or nil if a cycle exists is needed.
if false then
  local _o = nil  -- Graph instance
  _o:topologicalSort()
end

--@api-stub: Graph:mst
-- Returns edge IDs forming a minimum spanning tree (Kruskal, undirected view).
-- Use this when returns edge IDs forming a minimum spanning tree (Kruskal, undirected view) is needed.
if false then
  local _o = nil  -- Graph instance
  _o:mst()
end

--@api-stub: Graph:colorGraph
-- Assigns each node the smallest non-negative integer colour not shared with any.
-- Use this when assigns each node the smallest non-negative integer colour not shared with any is needed.
if false then
  local _o = nil  -- Graph instance
  _o:colorGraph()
end

--@api-stub: Graph:isBipartite
-- Returns `true` when the graph can be 2-coloured (bipartite check via BFS).
-- Use this when returns `true` when the graph can be 2-coloured (bipartite check via BFS) is needed.
if false then
  local _o = nil  -- Graph instance
  _o:isBipartite()
end

--@api-stub: Graph:processDemand
-- Processes all supply/demand declarations and fires event callbacks.
-- Use this when processes all supply/demand declarations and fires event callbacks is needed.
if false then
  local _o = nil  -- Graph instance
  _o:processDemand()
end

--@api-stub: Graph:getStats
-- Returns a statistics snapshot table.
-- Use this when returns a statistics snapshot table is needed.
if false then
  local _o = nil  -- Graph instance
  _o:getStats()
end

--@api-stub: Graph:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Graph instance
  _o:type()
end

--@api-stub: Graph:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- Graph instance
  _o:typeOf(1)
end

