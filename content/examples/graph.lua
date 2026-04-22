-- content/examples/graph.lua
-- Scaffolded coverage of the lurek.graph API (111 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/graph_api.rs   (Lua binding, arg types, return shape)
--   * src/graph/                 (semantics, side effects)
--   * docs/specs/graph.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/graph.lua

-- ── lurek.graph.* functions ──

--@api-stub: lurek.graph.newGraph
-- Creates a new empty directed graph for item flow simulation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: lurek.graph.newGraph
  local _todo = "TODO: write a real lurek.graph.newGraph usage example"
  print(_todo)
end

-- ── GraphItem methods ──

--@api-stub: GraphItem:getType
-- Returns the item type string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:getType
  local _todo = "TODO: write a real GraphItem:getType usage example"
  print(_todo)
end

--@api-stub: GraphItem:setType
-- Sets the item type string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:setType
  local _todo = "TODO: write a real GraphItem:setType usage example"
  print(_todo)
end

--@api-stub: GraphItem:getDecayTime
-- Returns the decay time in seconds (-1 = immortal).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:getDecayTime
  local _todo = "TODO: write a real GraphItem:getDecayTime usage example"
  print(_todo)
end

--@api-stub: GraphItem:setDecayTime
-- Sets the decay time in seconds (-1 = immortal).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:setDecayTime
  local _todo = "TODO: write a real GraphItem:setDecayTime usage example"
  print(_todo)
end

--@api-stub: GraphItem:getRemainingLife
-- Returns the remaining life in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:getRemainingLife
  local _todo = "TODO: write a real GraphItem:getRemainingLife usage example"
  print(_todo)
end

--@api-stub: GraphItem:isAlive
-- Returns true if the item is alive.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:isAlive
  local _todo = "TODO: write a real GraphItem:isAlive usage example"
  print(_todo)
end

--@api-stub: GraphItem:kill
-- Marks this graph item as dead so it is removed on the next cleanup pass.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:kill
  local _todo = "TODO: write a real GraphItem:kill usage example"
  print(_todo)
end

--@api-stub: GraphItem:getPriority
-- Returns the item priority.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:getPriority
  local _todo = "TODO: write a real GraphItem:getPriority usage example"
  print(_todo)
end

--@api-stub: GraphItem:setPriority
-- Sets the scheduling priority; higher values are processed before lower ones.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:setPriority
  local _todo = "TODO: write a real GraphItem:setPriority usage example"
  print(_todo)
end

--@api-stub: GraphItem:getPosition
-- Returns the item position: node userdata if at a node, (edge, progress).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:getPosition
  local _todo = "TODO: write a real GraphItem:getPosition usage example"
  print(_todo)
end

--@api-stub: GraphItem:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:type
  local _todo = "TODO: write a real GraphItem:type usage example"
  print(_todo)
end

--@api-stub: GraphItem:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: GraphItem:typeOf
  local _todo = "TODO: write a real GraphItem:typeOf usage example"
  print(_todo)
end

-- ── Edge methods ──

--@api-stub: Edge:getType
-- Returns the edge type string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getType
  local _todo = "TODO: write a real Edge:getType usage example"
  print(_todo)
end

--@api-stub: Edge:setType
-- Sets the edge type string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:setType
  local _todo = "TODO: write a real Edge:setType usage example"
  print(_todo)
end

--@api-stub: Edge:getFrom
-- Returns the source node handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getFrom
  local _todo = "TODO: write a real Edge:getFrom usage example"
  print(_todo)
end

--@api-stub: Edge:getTo
-- Returns the destination node handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getTo
  local _todo = "TODO: write a real Edge:getTo usage example"
  print(_todo)
end

--@api-stub: Edge:getCapacity
-- Returns the edge capacity (-1 = unlimited).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getCapacity
  local _todo = "TODO: write a real Edge:getCapacity usage example"
  print(_todo)
end

--@api-stub: Edge:setCapacity
-- Sets the edge capacity (-1 = unlimited).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:setCapacity
  local _todo = "TODO: write a real Edge:setCapacity usage example"
  print(_todo)
end

--@api-stub: Edge:getThroughput
-- Returns items per second this edge can transfer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getThroughput
  local _todo = "TODO: write a real Edge:getThroughput usage example"
  print(_todo)
end

--@api-stub: Edge:setThroughput
-- Sets items per second this edge can transfer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:setThroughput
  local _todo = "TODO: write a real Edge:setThroughput usage example"
  print(_todo)
end

--@api-stub: Edge:getTravelTime
-- Returns the travel time in seconds for items on this edge.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getTravelTime
  local _todo = "TODO: write a real Edge:getTravelTime usage example"
  print(_todo)
end

--@api-stub: Edge:setTravelTime
-- Sets the travel time in seconds for items on this edge.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:setTravelTime
  local _todo = "TODO: write a real Edge:setTravelTime usage example"
  print(_todo)
end

--@api-stub: Edge:getWeight
-- Returns the pathfinding weight of this edge.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getWeight
  local _todo = "TODO: write a real Edge:getWeight usage example"
  print(_todo)
end

--@api-stub: Edge:setWeight
-- Sets the pathfinding weight of this edge.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:setWeight
  local _todo = "TODO: write a real Edge:setWeight usage example"
  print(_todo)
end

--@api-stub: Edge:getSpeedModifier
-- Returns the speed modifier applied to items in transit.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getSpeedModifier
  local _todo = "TODO: write a real Edge:getSpeedModifier usage example"
  print(_todo)
end

--@api-stub: Edge:setSpeedModifier
-- Sets the speed modifier applied to items in transit.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:setSpeedModifier
  local _todo = "TODO: write a real Edge:setSpeedModifier usage example"
  print(_todo)
end

--@api-stub: Edge:getCooldown
-- Returns the cooldown duration in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getCooldown
  local _todo = "TODO: write a real Edge:getCooldown usage example"
  print(_todo)
end

--@api-stub: Edge:setCooldown
-- Sets the cooldown duration in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:setCooldown
  local _todo = "TODO: write a real Edge:setCooldown usage example"
  print(_todo)
end

--@api-stub: Edge:isOnCooldown
-- Returns true if the edge is currently on cooldown.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:isOnCooldown
  local _todo = "TODO: write a real Edge:isOnCooldown usage example"
  print(_todo)
end

--@api-stub: Edge:isBidirectional
-- Returns true if items can travel the edge in either direction.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:isBidirectional
  local _todo = "TODO: write a real Edge:isBidirectional usage example"
  print(_todo)
end

--@api-stub: Edge:setBidirectional
-- Sets whether items can travel the edge in either direction.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:setBidirectional
  local _todo = "TODO: write a real Edge:setBidirectional usage example"
  print(_todo)
end

--@api-stub: Edge:isActive
-- Returns true if the edge is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:isActive
  local _todo = "TODO: write a real Edge:isActive usage example"
  print(_todo)
end

--@api-stub: Edge:setActive
-- Sets the active state of this edge.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:setActive
  local _todo = "TODO: write a real Edge:setActive usage example"
  print(_todo)
end

--@api-stub: Edge:getItemsInTransit
-- Returns a table of GraphItem handles currently in transit on this edge.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:getItemsInTransit
  local _todo = "TODO: write a real Edge:getItemsInTransit usage example"
  print(_todo)
end

--@api-stub: Edge:addAllowedType
-- Adds an item type to the edge allow-list.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:addAllowedType
  local _todo = "TODO: write a real Edge:addAllowedType usage example"
  print(_todo)
end

--@api-stub: Edge:removeAllowedType
-- Removes an item type from the edge allow-list.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:removeAllowedType
  local _todo = "TODO: write a real Edge:removeAllowedType usage example"
  print(_todo)
end

--@api-stub: Edge:clearAllowedTypes
-- Clears the edge allow-list so all item types are permitted.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:clearAllowedTypes
  local _todo = "TODO: write a real Edge:clearAllowedTypes usage example"
  print(_todo)
end

--@api-stub: Edge:isItemTypeAllowed
-- Returns true if the given item type is allowed on this edge.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:isItemTypeAllowed
  local _todo = "TODO: write a real Edge:isItemTypeAllowed usage example"
  print(_todo)
end

--@api-stub: Edge:type
-- Returns the type name "GraphEdge".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:type
  local _todo = "TODO: write a real Edge:type usage example"
  print(_todo)
end

--@api-stub: Edge:typeOf
-- Returns true when the given name matches "GraphEdge" or a parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Edge:typeOf
  local _todo = "TODO: write a real Edge:typeOf usage example"
  print(_todo)
end

-- ── Node methods ──

--@api-stub: Node:getType
-- Returns the node type string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getType
  local _todo = "TODO: write a real Node:getType usage example"
  print(_todo)
end

--@api-stub: Node:setType
-- Sets the node type string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setType
  local _todo = "TODO: write a real Node:setType usage example"
  print(_todo)
end

--@api-stub: Node:getCapacity
-- Returns the node capacity (-1 = unlimited).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getCapacity
  local _todo = "TODO: write a real Node:getCapacity usage example"
  print(_todo)
end

--@api-stub: Node:setCapacity
-- Sets the node capacity (-1 = unlimited).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setCapacity
  local _todo = "TODO: write a real Node:setCapacity usage example"
  print(_todo)
end

--@api-stub: Node:getItemCount
-- Returns the number of items currently at this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getItemCount
  local _todo = "TODO: write a real Node:getItemCount usage example"
  print(_todo)
end

--@api-stub: Node:isFull
-- Returns true if the node has reached its capacity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:isFull
  local _todo = "TODO: write a real Node:isFull usage example"
  print(_todo)
end

--@api-stub: Node:isActive
-- Returns true if the node is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:isActive
  local _todo = "TODO: write a real Node:isActive usage example"
  print(_todo)
end

--@api-stub: Node:setActive
-- Sets the active state of this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setActive
  local _todo = "TODO: write a real Node:setActive usage example"
  print(_todo)
end

--@api-stub: Node:getOverflowPolicy
-- Returns the overflow policy as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getOverflowPolicy
  local _todo = "TODO: write a real Node:getOverflowPolicy usage example"
  print(_todo)
end

--@api-stub: Node:setOverflowPolicy
-- Sets the overflow policy from a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setOverflowPolicy
  local _todo = "TODO: write a real Node:setOverflowPolicy usage example"
  print(_todo)
end

--@api-stub: Node:getFlowMode
-- Returns the flow mode as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getFlowMode
  local _todo = "TODO: write a real Node:getFlowMode usage example"
  print(_todo)
end

--@api-stub: Node:setFlowMode
-- Sets the flow mode from a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setFlowMode
  local _todo = "TODO: write a real Node:setFlowMode usage example"
  print(_todo)
end

--@api-stub: Node:getPushRate
-- Returns items per second this node pushes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getPushRate
  local _todo = "TODO: write a real Node:getPushRate usage example"
  print(_todo)
end

--@api-stub: Node:setPushRate
-- Sets items per second this node pushes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setPushRate
  local _todo = "TODO: write a real Node:setPushRate usage example"
  print(_todo)
end

--@api-stub: Node:getPullRate
-- Returns items per second this node pulls.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getPullRate
  local _todo = "TODO: write a real Node:getPullRate usage example"
  print(_todo)
end

--@api-stub: Node:setPullRate
-- Sets items per second this node pulls.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setPullRate
  local _todo = "TODO: write a real Node:setPullRate usage example"
  print(_todo)
end

--@api-stub: Node:getPushFilter
-- Returns the push filter string, or nil if unset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getPushFilter
  local _todo = "TODO: write a real Node:getPushFilter usage example"
  print(_todo)
end

--@api-stub: Node:setPushFilter
-- Sets the push filter string, or nil to clear.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setPushFilter
  local _todo = "TODO: write a real Node:setPushFilter usage example"
  print(_todo)
end

--@api-stub: Node:getPullFilter
-- Returns the pull filter string, or nil if unset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getPullFilter
  local _todo = "TODO: write a real Node:getPullFilter usage example"
  print(_todo)
end

--@api-stub: Node:setPullFilter
-- Sets the pull filter string, or nil to clear.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setPullFilter
  local _todo = "TODO: write a real Node:setPullFilter usage example"
  print(_todo)
end

--@api-stub: Node:getProcessTime
-- Returns the processing time in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getProcessTime
  local _todo = "TODO: write a real Node:getProcessTime usage example"
  print(_todo)
end

--@api-stub: Node:setProcessTime
-- Sets the processing time in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setProcessTime
  local _todo = "TODO: write a real Node:setProcessTime usage example"
  print(_todo)
end

--@api-stub: Node:isQueueEnabled
-- Returns true if the node queue is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:isQueueEnabled
  local _todo = "TODO: write a real Node:isQueueEnabled usage example"
  print(_todo)
end

--@api-stub: Node:setQueueEnabled
-- Enables or disables the node queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setQueueEnabled
  local _todo = "TODO: write a real Node:setQueueEnabled usage example"
  print(_todo)
end

--@api-stub: Node:getQueueCapacity
-- Returns the queue capacity (-1 = unlimited).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getQueueCapacity
  local _todo = "TODO: write a real Node:getQueueCapacity usage example"
  print(_todo)
end

--@api-stub: Node:setQueueCapacity
-- Sets the queue capacity (-1 = unlimited).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:setQueueCapacity
  local _todo = "TODO: write a real Node:setQueueCapacity usage example"
  print(_todo)
end

--@api-stub: Node:getQueueSize
-- Returns the number of items currently in the queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getQueueSize
  local _todo = "TODO: write a real Node:getQueueSize usage example"
  print(_todo)
end

--@api-stub: Node:getItems
-- Returns a table of GraphItem handles at this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getItems
  local _todo = "TODO: write a real Node:getItems usage example"
  print(_todo)
end

--@api-stub: Node:getEdges
-- Returns a table of Edge handles connected to this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getEdges
  local _todo = "TODO: write a real Node:getEdges usage example"
  print(_todo)
end

--@api-stub: Node:clearConversion
-- Removes the conversion rule for the given input type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:clearConversion
  local _todo = "TODO: write a real Node:clearConversion usage example"
  print(_todo)
end

--@api-stub: Node:clearAllConversions
-- Removes all conversion rules from this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:clearAllConversions
  local _todo = "TODO: write a real Node:clearAllConversions usage example"
  print(_todo)
end

--@api-stub: Node:addTag
-- Attaches a string tag to this node for fast group queries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:addTag
  local _todo = "TODO: write a real Node:addTag usage example"
  print(_todo)
end

--@api-stub: Node:removeTag
-- Removes a tag from this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:removeTag
  local _todo = "TODO: write a real Node:removeTag usage example"
  print(_todo)
end

--@api-stub: Node:hasTag
-- Returns true if this node has the given tag.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:hasTag
  local _todo = "TODO: write a real Node:hasTag usage example"
  print(_todo)
end

--@api-stub: Node:clearTags
-- Removes all tags from this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:clearTags
  local _todo = "TODO: write a real Node:clearTags usage example"
  print(_todo)
end

--@api-stub: Node:getTags
-- Returns a table of tag strings on this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:getTags
  local _todo = "TODO: write a real Node:getTags usage example"
  print(_todo)
end

--@api-stub: Node:removeSupply
-- Removes the supply declaration for the given item type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:removeSupply
  local _todo = "TODO: write a real Node:removeSupply usage example"
  print(_todo)
end

--@api-stub: Node:clearSupplies
-- Removes all supply declarations from this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:clearSupplies
  local _todo = "TODO: write a real Node:clearSupplies usage example"
  print(_todo)
end

--@api-stub: Node:removeDemand
-- Removes the demand declaration for the given item type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:removeDemand
  local _todo = "TODO: write a real Node:removeDemand usage example"
  print(_todo)
end

--@api-stub: Node:clearDemands
-- Removes all demand declarations from this node.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:clearDemands
  local _todo = "TODO: write a real Node:clearDemands usage example"
  print(_todo)
end

--@api-stub: Node:enqueue
-- Pushes an item into the node queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:enqueue
  local _todo = "TODO: write a real Node:enqueue usage example"
  print(_todo)
end

--@api-stub: Node:dequeue
-- Pops the next item from the node queue, or nil if empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:dequeue
  local _todo = "TODO: write a real Node:dequeue usage example"
  print(_todo)
end

--@api-stub: Node:type
-- Returns the type name "GraphNode".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:type
  local _todo = "TODO: write a real Node:type usage example"
  print(_todo)
end

--@api-stub: Node:typeOf
-- Returns true when the given name matches "GraphNode" or a parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Node:typeOf
  local _todo = "TODO: write a real Node:typeOf usage example"
  print(_todo)
end

-- ── Graph methods ──

--@api-stub: Graph:removeNode
-- Removes a node from the graph.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:removeNode
  local _todo = "TODO: write a real Graph:removeNode usage example"
  print(_todo)
end

--@api-stub: Graph:hasNode
-- Returns true if the node exists in the graph.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:hasNode
  local _todo = "TODO: write a real Graph:hasNode usage example"
  print(_todo)
end

--@api-stub: Graph:getNodes
-- Returns a table of all Node handles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:getNodes
  local _todo = "TODO: write a real Graph:getNodes usage example"
  print(_todo)
end

--@api-stub: Graph:getNodeCount
-- Returns the number of nodes in the graph.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:getNodeCount
  local _todo = "TODO: write a real Graph:getNodeCount usage example"
  print(_todo)
end

--@api-stub: Graph:removeEdge
-- Removes an edge from the graph.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:removeEdge
  local _todo = "TODO: write a real Graph:removeEdge usage example"
  print(_todo)
end

--@api-stub: Graph:hasEdge
-- Returns true if the edge exists in the graph.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:hasEdge
  local _todo = "TODO: write a real Graph:hasEdge usage example"
  print(_todo)
end

--@api-stub: Graph:getEdges
-- Returns a table of all Edge handles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:getEdges
  local _todo = "TODO: write a real Graph:getEdges usage example"
  print(_todo)
end

--@api-stub: Graph:getEdgeCount
-- Returns the number of edges in the graph.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:getEdgeCount
  local _todo = "TODO: write a real Graph:getEdgeCount usage example"
  print(_todo)
end

--@api-stub: Graph:removeItem
-- Removes an item from the graph entirely.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:removeItem
  local _todo = "TODO: write a real Graph:removeItem usage example"
  print(_todo)
end

--@api-stub: Graph:hasItem
-- Returns true if the item exists in the graph.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:hasItem
  local _todo = "TODO: write a real Graph:hasItem usage example"
  print(_todo)
end

--@api-stub: Graph:getItems
-- Returns a table of all GraphItem handles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:getItems
  local _todo = "TODO: write a real Graph:getItems usage example"
  print(_todo)
end

--@api-stub: Graph:getItemCount
-- Returns the number of items in the graph.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:getItemCount
  local _todo = "TODO: write a real Graph:getItemCount usage example"
  print(_todo)
end

--@api-stub: Graph:update
-- Advances simulation by dt seconds and fires event callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:update
  local _todo = "TODO: write a real Graph:update usage example"
  print(_todo)
end

--@api-stub: Graph:step
-- Runs one discrete simulation step and fires event callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:step
  local _todo = "TODO: write a real Graph:step usage example"
  print(_todo)
end

--@api-stub: Graph:tickParallel
-- Advances simulation by dt seconds using a parallelised decay phase.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:tickParallel
  local _todo = "TODO: write a real Graph:tickParallel usage example"
  print(_todo)
end

--@api-stub: Graph:getNeighbors
-- Returns a table of direct neighbor Node handles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:getNeighbors
  local _todo = "TODO: write a real Graph:getNeighbors usage example"
  print(_todo)
end

--@api-stub: Graph:getComponents
-- Returns weakly connected components as a table of tables of Node handles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:getComponents
  local _todo = "TODO: write a real Graph:getComponents usage example"
  print(_todo)
end

--@api-stub: Graph:hasCycle
-- Returns true if the graph contains a directed cycle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:hasCycle
  local _todo = "TODO: write a real Graph:hasCycle usage example"
  print(_todo)
end

--@api-stub: Graph:topologicalSort
-- Returns a topologically sorted table of Node handles, or nil if a cycle exists.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:topologicalSort
  local _todo = "TODO: write a real Graph:topologicalSort usage example"
  print(_todo)
end

--@api-stub: Graph:mst
-- Returns edge IDs forming a minimum spanning tree (Kruskal, undirected view).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:mst
  local _todo = "TODO: write a real Graph:mst usage example"
  print(_todo)
end

--@api-stub: Graph:colorGraph
-- Assigns each node the smallest non-negative integer colour not shared with any.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:colorGraph
  local _todo = "TODO: write a real Graph:colorGraph usage example"
  print(_todo)
end

--@api-stub: Graph:isBipartite
-- Returns `true` when the graph can be 2-coloured (bipartite check via BFS).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:isBipartite
  local _todo = "TODO: write a real Graph:isBipartite usage example"
  print(_todo)
end

--@api-stub: Graph:processDemand
-- Processes all supply/demand declarations and fires event callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:processDemand
  local _todo = "TODO: write a real Graph:processDemand usage example"
  print(_todo)
end

--@api-stub: Graph:getStats
-- Returns a statistics snapshot table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:getStats
  local _todo = "TODO: write a real Graph:getStats usage example"
  print(_todo)
end

--@api-stub: Graph:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:type
  local _todo = "TODO: write a real Graph:type usage example"
  print(_todo)
end

--@api-stub: Graph:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/graph_api.rs and docs/specs/graph.md).
do  -- TODO: Graph:typeOf
  local _todo = "TODO: write a real Graph:typeOf usage example"
  print(_todo)
end

