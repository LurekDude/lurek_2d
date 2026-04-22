-- content/examples/graph.lua
-- Practical usage examples for the lurek.graph API (111 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.graph.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/graph.lua

print("[example] lurek.graph — 111 API entries")

-- ── lurek.graph.* free functions ──

--@api-stub: lurek.graph.newGraph
-- Creates a new empty directed graph for item flow simulation.
-- Call when you need to create a new graph.
local ok, obj = pcall(function() return lurek.graph.newGraph() end)
if ok and obj then print("created:", obj) end
print("lurek.graph.newGraph ok=", ok)

-- ── GraphItem methods ──

--@api-stub: GraphItem:getType
-- Returns the item type string.
-- Call when you need to read type.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:getType() end)
  print("GraphItem:getType ->", ok, result)
end

--@api-stub: GraphItem:setType
-- Sets the item type string.
-- Call when you need to assign type.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:setType(nil) end)
  print("GraphItem:setType ->", ok, result)
end

--@api-stub: GraphItem:getDecayTime
-- Returns the decay time in seconds (-1 = immortal).
-- Call when you need to read decay time.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:getDecayTime() end)
  print("GraphItem:getDecayTime ->", ok, result)
end

--@api-stub: GraphItem:setDecayTime
-- Sets the decay time in seconds (-1 = immortal).
-- Call when you need to assign decay time.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:setDecayTime(nil) end)
  print("GraphItem:setDecayTime ->", ok, result)
end

--@api-stub: GraphItem:getRemainingLife
-- Returns the remaining life in seconds.
-- Call when you need to read remaining life.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:getRemainingLife() end)
  print("GraphItem:getRemainingLife ->", ok, result)
end

--@api-stub: GraphItem:isAlive
-- Returns true if the item is alive.
-- Call when you need to check is alive.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:isAlive() end)
  print("GraphItem:isAlive ->", ok, result)
end

--@api-stub: GraphItem:kill
-- Marks this graph item as dead so it is removed on the next cleanup pass.
-- Call when you need to invoke kill.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:kill() end)
  print("GraphItem:kill ->", ok, result)
end

--@api-stub: GraphItem:getPriority
-- Returns the item priority.
-- Call when you need to read priority.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:getPriority() end)
  print("GraphItem:getPriority ->", ok, result)
end

--@api-stub: GraphItem:setPriority
-- Sets the scheduling priority; higher values are processed before lower ones.
-- Call when you need to assign priority.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:setPriority(nil) end)
  print("GraphItem:setPriority ->", ok, result)
end

--@api-stub: GraphItem:getPosition
-- Returns the item position: node userdata if at a node, (edge, progress).
-- Call when you need to read position.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:getPosition() end)
  print("GraphItem:getPosition ->", ok, result)
end

--@api-stub: GraphItem:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("GraphItem:type ->", ok, result)
end

--@api-stub: GraphItem:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a GraphItem via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraphItem(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("GraphItem:typeOf ->", ok, result)
end

-- ── Edge methods ──

--@api-stub: Edge:getType
-- Returns the edge type string.
-- Call when you need to read type.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getType() end)
  print("Edge:getType ->", ok, result)
end

--@api-stub: Edge:setType
-- Sets the edge type string.
-- Call when you need to assign type.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:setType(nil) end)
  print("Edge:setType ->", ok, result)
end

--@api-stub: Edge:getFrom
-- Returns the source node handle.
-- Call when you need to read from.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getFrom() end)
  print("Edge:getFrom ->", ok, result)
end

--@api-stub: Edge:getTo
-- Returns the destination node handle.
-- Call when you need to read to.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getTo() end)
  print("Edge:getTo ->", ok, result)
end

--@api-stub: Edge:getCapacity
-- Returns the edge capacity (-1 = unlimited).
-- Call when you need to read capacity.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getCapacity() end)
  print("Edge:getCapacity ->", ok, result)
end

--@api-stub: Edge:setCapacity
-- Sets the edge capacity (-1 = unlimited).
-- Call when you need to assign capacity.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:setCapacity(nil) end)
  print("Edge:setCapacity ->", ok, result)
end

--@api-stub: Edge:getThroughput
-- Returns items per second this edge can transfer.
-- Call when you need to read throughput.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getThroughput() end)
  print("Edge:getThroughput ->", ok, result)
end

--@api-stub: Edge:setThroughput
-- Sets items per second this edge can transfer.
-- Call when you need to assign throughput.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:setThroughput(nil) end)
  print("Edge:setThroughput ->", ok, result)
end

--@api-stub: Edge:getTravelTime
-- Returns the travel time in seconds for items on this edge.
-- Call when you need to read travel time.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getTravelTime() end)
  print("Edge:getTravelTime ->", ok, result)
end

--@api-stub: Edge:setTravelTime
-- Sets the travel time in seconds for items on this edge.
-- Call when you need to assign travel time.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:setTravelTime(nil) end)
  print("Edge:setTravelTime ->", ok, result)
end

--@api-stub: Edge:getWeight
-- Returns the pathfinding weight of this edge.
-- Call when you need to read weight.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getWeight() end)
  print("Edge:getWeight ->", ok, result)
end

--@api-stub: Edge:setWeight
-- Sets the pathfinding weight of this edge.
-- Call when you need to assign weight.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:setWeight(100) end)
  print("Edge:setWeight ->", ok, result)
end

--@api-stub: Edge:getSpeedModifier
-- Returns the speed modifier applied to items in transit.
-- Call when you need to read speed modifier.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getSpeedModifier() end)
  print("Edge:getSpeedModifier ->", ok, result)
end

--@api-stub: Edge:setSpeedModifier
-- Sets the speed modifier applied to items in transit.
-- Call when you need to assign speed modifier.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:setSpeedModifier(nil) end)
  print("Edge:setSpeedModifier ->", ok, result)
end

--@api-stub: Edge:getCooldown
-- Returns the cooldown duration in seconds.
-- Call when you need to read cooldown.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getCooldown() end)
  print("Edge:getCooldown ->", ok, result)
end

--@api-stub: Edge:setCooldown
-- Sets the cooldown duration in seconds.
-- Call when you need to assign cooldown.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:setCooldown(nil) end)
  print("Edge:setCooldown ->", ok, result)
end

--@api-stub: Edge:isOnCooldown
-- Returns true if the edge is currently on cooldown.
-- Call when you need to check is on cooldown.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:isOnCooldown() end)
  print("Edge:isOnCooldown ->", ok, result)
end

--@api-stub: Edge:isBidirectional
-- Returns true if items can travel the edge in either direction.
-- Call when you need to check is bidirectional.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:isBidirectional() end)
  print("Edge:isBidirectional ->", ok, result)
end

--@api-stub: Edge:setBidirectional
-- Sets whether items can travel the edge in either direction.
-- Call when you need to assign bidirectional.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:setBidirectional(1) end)
  print("Edge:setBidirectional ->", ok, result)
end

--@api-stub: Edge:isActive
-- Returns true if the edge is active.
-- Call when you need to check is active.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:isActive() end)
  print("Edge:isActive ->", ok, result)
end

--@api-stub: Edge:setActive
-- Sets the active state of this edge.
-- Call when you need to assign active.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:setActive(1) end)
  print("Edge:setActive ->", ok, result)
end

--@api-stub: Edge:getItemsInTransit
-- Returns a table of GraphItem handles currently in transit on this edge.
-- Call when you need to read items in transit.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:getItemsInTransit() end)
  print("Edge:getItemsInTransit ->", ok, result)
end

--@api-stub: Edge:addAllowedType
-- Adds an item type to the edge allow-list.
-- Call when you need to add allowed type.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:addAllowedType(nil) end)
  print("Edge:addAllowedType ->", ok, result)
end

--@api-stub: Edge:removeAllowedType
-- Removes an item type from the edge allow-list.
-- Call when you need to remove allowed type.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:removeAllowedType(nil) end)
  print("Edge:removeAllowedType ->", ok, result)
end

--@api-stub: Edge:clearAllowedTypes
-- Clears the edge allow-list so all item types are permitted.
-- Call when you need to invoke clear allowed types.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:clearAllowedTypes() end)
  print("Edge:clearAllowedTypes ->", ok, result)
end

--@api-stub: Edge:isItemTypeAllowed
-- Returns true if the given item type is allowed on this edge.
-- Call when you need to check is item type allowed.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:isItemTypeAllowed(nil) end)
  print("Edge:isItemTypeAllowed ->", ok, result)
end

--@api-stub: Edge:type
-- Returns the type name "GraphEdge".
-- Call when you need to invoke type.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Edge:type ->", ok, result)
end

--@api-stub: Edge:typeOf
-- Returns true when the given name matches "GraphEdge" or a parent type.
-- Call when you need to invoke type of.
-- Build a Edge via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newEdge(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Edge:typeOf ->", ok, result)
end

-- ── Node methods ──

--@api-stub: Node:getType
-- Returns the node type string.
-- Call when you need to read type.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getType() end)
  print("Node:getType ->", ok, result)
end

--@api-stub: Node:setType
-- Sets the node type string.
-- Call when you need to assign type.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setType(nil) end)
  print("Node:setType ->", ok, result)
end

--@api-stub: Node:getCapacity
-- Returns the node capacity (-1 = unlimited).
-- Call when you need to read capacity.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getCapacity() end)
  print("Node:getCapacity ->", ok, result)
end

--@api-stub: Node:setCapacity
-- Sets the node capacity (-1 = unlimited).
-- Call when you need to assign capacity.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setCapacity(nil) end)
  print("Node:setCapacity ->", ok, result)
end

--@api-stub: Node:getItemCount
-- Returns the number of items currently at this node.
-- Call when you need to read item count.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getItemCount() end)
  print("Node:getItemCount ->", ok, result)
end

--@api-stub: Node:isFull
-- Returns true if the node has reached its capacity.
-- Call when you need to check is full.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:isFull() end)
  print("Node:isFull ->", ok, result)
end

--@api-stub: Node:isActive
-- Returns true if the node is active.
-- Call when you need to check is active.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:isActive() end)
  print("Node:isActive ->", ok, result)
end

--@api-stub: Node:setActive
-- Sets the active state of this node.
-- Call when you need to assign active.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setActive(1) end)
  print("Node:setActive ->", ok, result)
end

--@api-stub: Node:getOverflowPolicy
-- Returns the overflow policy as a string.
-- Call when you need to read overflow policy.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getOverflowPolicy() end)
  print("Node:getOverflowPolicy ->", ok, result)
end

--@api-stub: Node:setOverflowPolicy
-- Sets the overflow policy from a string.
-- Call when you need to assign overflow policy.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setOverflowPolicy(nil) end)
  print("Node:setOverflowPolicy ->", ok, result)
end

--@api-stub: Node:getFlowMode
-- Returns the flow mode as a string.
-- Call when you need to read flow mode.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getFlowMode() end)
  print("Node:getFlowMode ->", ok, result)
end

--@api-stub: Node:setFlowMode
-- Sets the flow mode from a string.
-- Call when you need to assign flow mode.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setFlowMode(nil) end)
  print("Node:setFlowMode ->", ok, result)
end

--@api-stub: Node:getPushRate
-- Returns items per second this node pushes.
-- Call when you need to read push rate.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getPushRate() end)
  print("Node:getPushRate ->", ok, result)
end

--@api-stub: Node:setPushRate
-- Sets items per second this node pushes.
-- Call when you need to assign push rate.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setPushRate(1) end)
  print("Node:setPushRate ->", ok, result)
end

--@api-stub: Node:getPullRate
-- Returns items per second this node pulls.
-- Call when you need to read pull rate.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getPullRate() end)
  print("Node:getPullRate ->", ok, result)
end

--@api-stub: Node:setPullRate
-- Sets items per second this node pulls.
-- Call when you need to assign pull rate.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setPullRate(1) end)
  print("Node:setPullRate ->", ok, result)
end

--@api-stub: Node:getPushFilter
-- Returns the push filter string, or nil if unset.
-- Call when you need to read push filter.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getPushFilter() end)
  print("Node:getPushFilter ->", ok, result)
end

--@api-stub: Node:setPushFilter
-- Sets the push filter string, or nil to clear.
-- Call when you need to assign push filter.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setPushFilter(nil) end)
  print("Node:setPushFilter ->", ok, result)
end

--@api-stub: Node:getPullFilter
-- Returns the pull filter string, or nil if unset.
-- Call when you need to read pull filter.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getPullFilter() end)
  print("Node:getPullFilter ->", ok, result)
end

--@api-stub: Node:setPullFilter
-- Sets the pull filter string, or nil to clear.
-- Call when you need to assign pull filter.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setPullFilter(nil) end)
  print("Node:setPullFilter ->", ok, result)
end

--@api-stub: Node:getProcessTime
-- Returns the processing time in seconds.
-- Call when you need to read process time.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getProcessTime() end)
  print("Node:getProcessTime ->", ok, result)
end

--@api-stub: Node:setProcessTime
-- Sets the processing time in seconds.
-- Call when you need to assign process time.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setProcessTime(nil) end)
  print("Node:setProcessTime ->", ok, result)
end

--@api-stub: Node:isQueueEnabled
-- Returns true if the node queue is enabled.
-- Call when you need to check is queue enabled.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:isQueueEnabled() end)
  print("Node:isQueueEnabled ->", ok, result)
end

--@api-stub: Node:setQueueEnabled
-- Enables or disables the node queue.
-- Call when you need to assign queue enabled.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setQueueEnabled(nil) end)
  print("Node:setQueueEnabled ->", ok, result)
end

--@api-stub: Node:getQueueCapacity
-- Returns the queue capacity (-1 = unlimited).
-- Call when you need to read queue capacity.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getQueueCapacity() end)
  print("Node:getQueueCapacity ->", ok, result)
end

--@api-stub: Node:setQueueCapacity
-- Sets the queue capacity (-1 = unlimited).
-- Call when you need to assign queue capacity.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:setQueueCapacity(nil) end)
  print("Node:setQueueCapacity ->", ok, result)
end

--@api-stub: Node:getQueueSize
-- Returns the number of items currently in the queue.
-- Call when you need to read queue size.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getQueueSize() end)
  print("Node:getQueueSize ->", ok, result)
end

--@api-stub: Node:getItems
-- Returns a table of GraphItem handles at this node.
-- Call when you need to read items.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getItems() end)
  print("Node:getItems ->", ok, result)
end

--@api-stub: Node:getEdges
-- Returns a table of Edge handles connected to this node.
-- Call when you need to read edges.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getEdges("dir") end)
  print("Node:getEdges ->", ok, result)
end

--@api-stub: Node:clearConversion
-- Removes the conversion rule for the given input type.
-- Call when you need to invoke clear conversion.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:clearConversion(nil) end)
  print("Node:clearConversion ->", ok, result)
end

--@api-stub: Node:clearAllConversions
-- Removes all conversion rules from this node.
-- Call when you need to invoke clear all conversions.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:clearAllConversions() end)
  print("Node:clearAllConversions ->", ok, result)
end

--@api-stub: Node:addTag
-- Attaches a string tag to this node for fast group queries.
-- Call when you need to add tag.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:addTag("tag") end)
  print("Node:addTag ->", ok, result)
end

--@api-stub: Node:removeTag
-- Removes a tag from this node.
-- Call when you need to remove tag.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:removeTag("tag") end)
  print("Node:removeTag ->", ok, result)
end

--@api-stub: Node:hasTag
-- Returns true if this node has the given tag.
-- Call when you need to check has tag.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:hasTag("tag") end)
  print("Node:hasTag ->", ok, result)
end

--@api-stub: Node:clearTags
-- Removes all tags from this node.
-- Call when you need to invoke clear tags.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:clearTags() end)
  print("Node:clearTags ->", ok, result)
end

--@api-stub: Node:getTags
-- Returns a table of tag strings on this node.
-- Call when you need to read tags.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:getTags() end)
  print("Node:getTags ->", ok, result)
end

--@api-stub: Node:removeSupply
-- Removes the supply declaration for the given item type.
-- Call when you need to remove supply.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:removeSupply(nil) end)
  print("Node:removeSupply ->", ok, result)
end

--@api-stub: Node:clearSupplies
-- Removes all supply declarations from this node.
-- Call when you need to invoke clear supplies.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:clearSupplies() end)
  print("Node:clearSupplies ->", ok, result)
end

--@api-stub: Node:removeDemand
-- Removes the demand declaration for the given item type.
-- Call when you need to remove demand.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:removeDemand(nil) end)
  print("Node:removeDemand ->", ok, result)
end

--@api-stub: Node:clearDemands
-- Removes all demand declarations from this node.
-- Call when you need to invoke clear demands.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:clearDemands() end)
  print("Node:clearDemands ->", ok, result)
end

--@api-stub: Node:enqueue
-- Pushes an item into the node queue.
-- Call when you need to invoke enqueue.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:enqueue(nil) end)
  print("Node:enqueue ->", ok, result)
end

--@api-stub: Node:dequeue
-- Pops the next item from the node queue, or nil if empty.
-- Call when you need to invoke dequeue.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:dequeue() end)
  print("Node:dequeue ->", ok, result)
end

--@api-stub: Node:type
-- Returns the type name "GraphNode".
-- Call when you need to invoke type.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Node:type ->", ok, result)
end

--@api-stub: Node:typeOf
-- Returns true when the given name matches "GraphNode" or a parent type.
-- Call when you need to invoke type of.
-- Build a Node via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newNode(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Node:typeOf ->", ok, result)
end

-- ── Graph methods ──

--@api-stub: Graph:removeNode
-- Removes a node from the graph.
-- Call when you need to remove node.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:removeNode(nil) end)
  print("Graph:removeNode ->", ok, result)
end

--@api-stub: Graph:hasNode
-- Returns true if the node exists in the graph.
-- Call when you need to check has node.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:hasNode(nil) end)
  print("Graph:hasNode ->", ok, result)
end

--@api-stub: Graph:getNodes
-- Returns a table of all Node handles.
-- Call when you need to read nodes.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:getNodes() end)
  print("Graph:getNodes ->", ok, result)
end

--@api-stub: Graph:getNodeCount
-- Returns the number of nodes in the graph.
-- Call when you need to read node count.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:getNodeCount() end)
  print("Graph:getNodeCount ->", ok, result)
end

--@api-stub: Graph:removeEdge
-- Removes an edge from the graph.
-- Call when you need to remove edge.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:removeEdge(nil) end)
  print("Graph:removeEdge ->", ok, result)
end

--@api-stub: Graph:hasEdge
-- Returns true if the edge exists in the graph.
-- Call when you need to check has edge.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:hasEdge(nil) end)
  print("Graph:hasEdge ->", ok, result)
end

--@api-stub: Graph:getEdges
-- Returns a table of all Edge handles.
-- Call when you need to read edges.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:getEdges() end)
  print("Graph:getEdges ->", ok, result)
end

--@api-stub: Graph:getEdgeCount
-- Returns the number of edges in the graph.
-- Call when you need to read edge count.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:getEdgeCount() end)
  print("Graph:getEdgeCount ->", ok, result)
end

--@api-stub: Graph:removeItem
-- Removes an item from the graph entirely.
-- Call when you need to remove item.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:removeItem(nil) end)
  print("Graph:removeItem ->", ok, result)
end

--@api-stub: Graph:hasItem
-- Returns true if the item exists in the graph.
-- Call when you need to check has item.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:hasItem(nil) end)
  print("Graph:hasItem ->", ok, result)
end

--@api-stub: Graph:getItems
-- Returns a table of all GraphItem handles.
-- Call when you need to read items.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:getItems() end)
  print("Graph:getItems ->", ok, result)
end

--@api-stub: Graph:getItemCount
-- Returns the number of items in the graph.
-- Call when you need to read item count.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:getItemCount() end)
  print("Graph:getItemCount ->", ok, result)
end

--@api-stub: Graph:update
-- Advances simulation by dt seconds and fires event callbacks.
-- Call when you need to invoke update.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Graph:update ->", ok, result)
end

--@api-stub: Graph:step
-- Runs one discrete simulation step and fires event callbacks.
-- Call when you need to invoke step.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:step() end)
  print("Graph:step ->", ok, result)
end

--@api-stub: Graph:tickParallel
-- Advances simulation by dt seconds using a parallelised decay phase.
-- Call when you need to invoke tick parallel.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:tickParallel(1.0) end)
  print("Graph:tickParallel ->", ok, result)
end

--@api-stub: Graph:getNeighbors
-- Returns a table of direct neighbor Node handles.
-- Call when you need to read neighbors.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:getNeighbors(nil) end)
  print("Graph:getNeighbors ->", ok, result)
end

--@api-stub: Graph:getComponents
-- Returns weakly connected components as a table of tables of Node handles.
-- Call when you need to read components.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:getComponents() end)
  print("Graph:getComponents ->", ok, result)
end

--@api-stub: Graph:hasCycle
-- Returns true if the graph contains a directed cycle.
-- Call when you need to check has cycle.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:hasCycle() end)
  print("Graph:hasCycle ->", ok, result)
end

--@api-stub: Graph:topologicalSort
-- Returns a topologically sorted table of Node handles, or nil if a cycle exists.
-- Call when you need to invoke topological sort.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:topologicalSort() end)
  print("Graph:topologicalSort ->", ok, result)
end

--@api-stub: Graph:mst
-- Returns edge IDs forming a minimum spanning tree (Kruskal, undirected view).
-- Call when you need to invoke mst.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:mst() end)
  print("Graph:mst ->", ok, result)
end

--@api-stub: Graph:colorGraph
-- Assigns each node the smallest non-negative integer colour not shared with any.
-- Call when you need to invoke color graph.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:colorGraph() end)
  print("Graph:colorGraph ->", ok, result)
end

--@api-stub: Graph:isBipartite
-- Returns `true` when the graph can be 2-coloured (bipartite check via BFS).
-- Call when you need to check is bipartite.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:isBipartite() end)
  print("Graph:isBipartite ->", ok, result)
end

--@api-stub: Graph:processDemand
-- Processes all supply/demand declarations and fires event callbacks.
-- Call when you need to invoke process demand.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:processDemand() end)
  print("Graph:processDemand ->", ok, result)
end

--@api-stub: Graph:getStats
-- Returns a statistics snapshot table.
-- Call when you need to read stats.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:getStats() end)
  print("Graph:getStats ->", ok, result)
end

--@api-stub: Graph:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Graph:type ->", ok, result)
end

--@api-stub: Graph:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a Graph via the appropriate lurek.graph.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.graph.newGraph(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Graph:typeOf ->", ok, result)
end

