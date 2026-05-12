-- content/examples/graph.lua
-- Hand-written coverage of the lurek.graph API (111 items).
--
-- The lurek.graph module is a directed-graph simulator with typed item
-- transport on edges, node capacities, conversion rules, supply/demand,
-- and pathfinding (Dijkstra, A*, BFS, MST, topo sort, components,
-- bipartite check, graph colouring). Use it for factory belts, road
-- networks, fluid pipes, dependency graphs, or any flow-of-stuff sim.
-- Every block below builds a tiny example graph from real values
-- ("start"/"end" node ids, edge weights, item types like "ore"/"iron")
-- so you can copy-paste a snippet straight into a game and tweak it.
--
-- Run: cargo run -- content/examples/graph.lua

-- â”€â”€ lurek.graph.* functions â”€â”€

--@api-stub: lurek.graph.newGraph
-- Creates a new empty directed graph for item flow simulation.
-- Create one Graph per simulation domain (one for the conveyor network, another for the road map); they are independent.
do -- lurek.graph.newGraph
  local belts = lurek.graph.newGraph()
  local depot = belts:addNode("depot", 32)
  local sink  = belts:addNode("sink", -1)
  belts:addEdge(depot, sink, "belt")
  lurek.log.info("belt graph: " .. tostring(belts), "factory")
end

-- â”€â”€ GraphItem methods â”€â”€

--@api-stub: LGraphItem:getType
-- Returns the item type string.
-- Branch on item type to apply per-type logic (display sprite, sound, conversion).
do -- GraphItem:getType
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if ore:getType() == "ore" then lurek.log.info("crate holds raw ore", "factory") end
end

--@api-stub: LGraphItem:setType
-- Sets the item type string.
-- Use after a manual conversion or upgrade so subsequent filters and conversions see the new type.
do -- GraphItem:setType
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:setType("iron_ingot")
  lurek.log.info("ore promoted to " .. ore:getType(), "factory")
end

--@api-stub: LGraphItem:getDecayTime
-- Returns the decay time in seconds (-1 = immortal).
-- Useful when you want to render a freshness bar â€” divide getRemainingLife by getDecayTime.
do -- GraphItem:getDecayTime
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  local total = ore:getDecayTime()
  local frac = ore:getRemainingLife() / total
  lurek.log.debug("ore freshness " .. math.floor(frac * 100) .. "%", "factory")
end

--@api-stub: LGraphItem:setDecayTime
-- Sets the decay time in seconds (-1 = immortal).
-- Pass -1 to make an item immortal (e.g. a tracked debug marker that should never expire).
do -- GraphItem:setDecayTime
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:setDecayTime(-1)
  lurek.log.debug("ore is now immortal: decay=" .. ore:getDecayTime(), "factory")
end

--@api-stub: LGraphItem:getRemainingLife
-- Returns the remaining life in seconds.
-- Drop the item from the UI early (or warn the player) when remaining life falls under a threshold.
do -- GraphItem:getRemainingLife
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if ore:getRemainingLife() < 5.0 then
    lurek.log.warn("ore about to spoil!", "factory")
  end
end

--@api-stub: LGraphItem:isAlive
-- Returns true if the item is alive.
-- Skip rendering or selecting items that have already decayed but linger in your UI list one frame.
do -- GraphItem:isAlive
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if not ore:isAlive() then
    lurek.log.warn("ore decayed before reaching the smelter", "factory")
  end
end

--@api-stub: LGraphItem:kill
-- Marks this graph item as dead so it is removed on the next cleanup pass.
-- Kill items the player consumes mid-flight (e.g. a missile destroyed by a turret) so the next cleanup pass removes them.
do -- GraphItem:kill
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:kill()
  lurek.log.info("ore manually destroyed, alive=" .. tostring(ore:isAlive()), "factory")
end

--@api-stub: LGraphItem:getPriority
-- Returns the item priority.
-- Sort player-visible item lists by priority so VIP cargo (rescue victims, hero items) appears at the top.
do -- GraphItem:getPriority
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:setPriority(5)
  lurek.log.debug("ore priority " .. ore:getPriority(), "factory")
end

--@api-stub: LGraphItem:setPriority
-- Sets the scheduling priority; higher values are processed before lower ones.
-- Higher priorities ship first when an edge is at capacity; reserve very high values for emergency cargo.
do -- GraphItem:setPriority
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:setPriority(10)
  local rock = g:createItem("rock", 30.0)
  rock:setPriority(1)  -- ore (10) beats rock (1) at the next bottleneck
end

--@api-stub: LGraphItem:getPosition
-- Returns the item position: node userdata if at a node, (edge, progress).
-- Returns Node, (Edge, progress), or nothing â€” use the multi-return arity to dispatch on state.
do -- GraphItem:getPosition
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  local first, second = ore:getPosition()
  if second then
    lurek.log.info("ore in transit progress=" .. tostring(second), "factory")
  elseif first then
    lurek.log.info("ore parked at node", "factory")
  end
end

--@api-stub: LGraphItem:type
-- Returns the type name of this object.
-- Use in a generic dispatcher that handles Nodes, Edges and Items via a shared inspect function.
do -- GraphItem:type
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if ore:type() == "GraphItem" then
    lurek.log.debug("inspecting graph item", "factory")
  end
end

--@api-stub: LGraphItem:typeOf
-- Returns true if this object is of the given type.
-- typeOf is the lurek-wide isInstanceOf check â€” pass "Object" to match the common ancestor.
do -- GraphItem:typeOf
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if ore:typeOf("Object") then
    lurek.log.debug("ore is a tracked Lurek object", "factory")
  end
end

-- â”€â”€ Edge methods â”€â”€

--@api-stub: Edge:getType
-- Returns the edge type string.
-- Group edges by type when rendering (conveyor / pipe / road get different sprites).
do -- Edge:getType
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  if belt:getType() == "conveyor" then
    lurek.log.debug("rendering conveyor segment", "render")
  end
end

--@api-stub: Edge:setType
-- Sets the edge type string.
-- Re-tag an edge after the player upgrades a road to a highway so style and routing rules change.
do -- Edge:setType
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setType("highway")
  lurek.log.info("belt is now a " .. belt:getType(), "factory")
end

--@api-stub: Edge:getFrom
-- Returns the source node handle.
-- Use to walk back from an edge to its source node when displaying a routing overlay.
do -- Edge:getFrom
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  local src = belt:getFrom()
  lurek.log.debug("belt comes from " .. src:getType() .. " node", "factory")
end

--@api-stub: Edge:getTo
-- Returns the destination node handle.
-- Pair with getFrom to draw a directional arrow or to compute the edge's vector for layout.
do -- Edge:getTo
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  local dst = belt:getTo()
  lurek.log.debug("belt feeds into " .. dst:getType() .. " node", "factory")
end

--@api-stub: Edge:getCapacity
-- Returns the edge capacity (-1 = unlimited).
-- -1 means unlimited â€” guard against that when normalising for a UI fill bar.
do -- Edge:getCapacity
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setCapacity(8)
  local cap = belt:getCapacity()
  if cap > 0 then lurek.log.debug("belt cap " .. cap, "factory") end
end

--@api-stub: Edge:setCapacity
-- Sets the edge capacity (-1 = unlimited).
-- Use to model belt-tier upgrades: tier-1 belt = 4 items, tier-2 = 8, tier-3 = 16.
do -- Edge:setCapacity
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setCapacity(8)  -- tier-2 belt holds 8 items
end

--@api-stub: Edge:getThroughput
-- Returns items per second this edge can transfer.
-- Multiply by the simulation tick to estimate items-per-tick when planning factory ratios.
do -- Edge:getThroughput
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setThroughput(2.0)
  local per_sec = belt:getThroughput()
  lurek.log.info("belt moves " .. per_sec .. " items/s", "factory")
end

--@api-stub: Edge:setThroughput
-- Sets items per second this edge can transfer.
-- Items-per-second; raising it is what an upgrade-belt button does.
do -- Edge:setThroughput
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setThroughput(4.0)
end

--@api-stub: Edge:getTravelTime
-- Returns the travel time in seconds for items on this edge.
-- Use the value to time visual effects (fade-in spawn at the destination) so they match the sim.
do -- Edge:getTravelTime
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setTravelTime(1.5)
  local t = belt:getTravelTime()
  lurek.log.debug("items take " .. t .. "s to cross belt", "factory")
end

--@api-stub: Edge:setTravelTime
-- Sets the travel time in seconds for items on this edge.
-- Longer travel times let downstream nodes drain even when the edge is fully loaded.
do -- Edge:setTravelTime
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setTravelTime(2.0)  -- longer belt for slower planet level
end

--@api-stub: Edge:getWeight
-- Returns the pathfinding weight of this edge.
-- Pathfinding (findPath, getDistance, A*) sums edge weights â€” read it back to display the route cost.
do -- Edge:getWeight
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setWeight(3.0)
  lurek.log.debug("edge weight=" .. belt:getWeight(), "pathfind")
end

--@api-stub: Edge:setWeight
-- Sets the pathfinding weight of this edge.
-- Set higher weights on toll roads or rough terrain so Dijkstra prefers cheaper alternatives.
do -- Edge:setWeight
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setWeight(10.0)  -- toll road, prefer alternatives
end

--@api-stub: Edge:getSpeedModifier
-- Returns the speed modifier applied to items in transit.
-- Multiplies in-transit progress speed without changing pathfinding weight; great for boosters.
do -- Edge:getSpeedModifier
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setSpeedModifier(1.5)
  lurek.log.debug("speed boost " .. belt:getSpeedModifier() .. "x", "factory")
end

--@api-stub: Edge:setSpeedModifier
-- Sets the speed modifier applied to items in transit.
-- Use 0.5 for slowdown zones, 2.0 for booster belts.
do -- Edge:setSpeedModifier
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setSpeedModifier(2.0)  -- accelerator belt
end

--@api-stub: Edge:getCooldown
-- Returns the cooldown duration in seconds.
-- After dispatch the edge waits this long before accepting the next item â€” read it for HUD warnings.
do -- Edge:getCooldown
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setCooldown(0.25)
  lurek.log.debug("edge cooldown " .. belt:getCooldown() .. "s", "factory")
end

--@api-stub: Edge:setCooldown
-- Sets the cooldown duration in seconds.
-- Set on launcher edges (catapults, teleporters) that need to recharge between uses.
do -- Edge:setCooldown
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setCooldown(2.0)  -- catapult, fires every 2s
end

--@api-stub: Edge:isOnCooldown
-- Returns true if the edge is currently on cooldown.
-- Render the edge greyed out or blinking while it cannot accept new items.
do -- Edge:isOnCooldown
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setCooldown(1.0)
  if belt:isOnCooldown() then
    lurek.log.debug("belt charging", "factory")
  end
end

--@api-stub: Edge:isBidirectional
-- Returns true if items can travel the edge in either direction.
-- Bidirectional edges let pathfinding consider reverse traversal â€” useful for roads, deadly for one-way conveyors.
do -- Edge:isBidirectional
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setBidirectional(true)
  if belt:isBidirectional() then
    lurek.log.debug("belt accepts reverse traffic", "factory")
  end
end

--@api-stub: Edge:setBidirectional
-- Sets whether items can travel the edge in either direction.
-- Toggle on for road-graph edges; leave off for conveyor belts where direction is part of the design.
do -- Edge:setBidirectional
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setBidirectional(true)  -- two-way road
end

--@api-stub: Edge:isActive
-- Returns true if the edge is active.
-- Inactive edges are skipped by routing and transport â€” pause one to simulate maintenance or power-loss.
do -- Edge:isActive
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  if belt:isActive() then
    lurek.log.debug("belt is online", "factory")
  end
end

--@api-stub: Edge:setActive
-- Sets the active state of this edge.
-- Use to pause edges during a power-failure event without destroying their config.
do -- Edge:setActive
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setActive(false)  -- power outage; routes will avoid this edge
end

--@api-stub: Edge:getItemsInTransit
-- Returns a table of GraphItem handles currently in transit on this edge.
-- Iterate to draw each item along the belt, or to count throughput pressure for an analytics overlay.
do -- Edge:getItemsInTransit
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  local items = belt:getItemsInTransit()
  lurek.log.debug(#items .. " items currently riding the belt", "factory")
  for _, it in ipairs(items) do lurek.log.debug("  " .. it:getType(), "factory") end
end

--@api-stub: Edge:addAllowedType
-- Adds an item type to the edge allow-list.
-- Make a belt accept only specific item types â€” call multiple times to whitelist several ("ore","coal").
do -- Edge:addAllowedType
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:addAllowedType("ore")
  belt:addAllowedType("coal")
  lurek.log.info("belt accepts ore and coal", "factory")
end

--@api-stub: Edge:removeAllowedType
-- Removes an item type from the edge allow-list.
-- Drop a type from the allow-list when the player retools a belt during a level.
do -- Edge:removeAllowedType
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:addAllowedType("ore")
  belt:addAllowedType("coal")
  belt:removeAllowedType("coal")
end

--@api-stub: Edge:clearAllowedTypes
-- Clears the edge allow-list so all item types are permitted.
-- Wipe the whitelist to make the belt accept anything again.
do -- Edge:clearAllowedTypes
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:addAllowedType("ore")
  belt:clearAllowedTypes()  -- back to permissive
end

--@api-stub: Edge:isItemTypeAllowed
-- Returns true if the given item type is allowed on this edge.
-- Check before sending an item so the UI can warn the player instead of silently dropping it.
do -- Edge:isItemTypeAllowed
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:addAllowedType("ore")
  if not belt:isItemTypeAllowed("water") then
    lurek.log.warn("belt rejects water", "factory")
  end
end

--@api-stub: Edge:type
-- Returns the type name "GraphEdge".
-- Generic dispatcher â€” branch on type name to route Edges, Nodes, and Items through a shared inspector.
do -- Edge:type
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  if belt:type() == "GraphEdge" then
    lurek.log.debug("inspecting an edge", "factory")
  end
end

--@api-stub: Edge:typeOf
-- Returns true when the given name matches "GraphEdge" or a parent type.
-- typeOf("Object") matches every Lurek graph value â€” useful for very generic UI helpers.
do -- Edge:typeOf
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  if belt:typeOf("GraphEdge") then
    lurek.log.debug("yes, this is an edge", "factory")
  end
end

-- â”€â”€ Node methods â”€â”€

--@api-stub: Node:getType
-- Returns the node type string.
-- Render different sprites per node type (depot vs furnace vs sink) by branching on getType().
do -- Node:getType
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  if depot:getType() == "depot" then
    lurek.log.debug("rendering depot pad", "render")
  end
end

--@api-stub: Node:setType
-- Sets the node type string.
-- Re-type a node when the player upgrades a building (depot â†’ automated_depot).
do -- Node:setType
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setType("automated_depot")
end

--@api-stub: Node:getCapacity
-- Returns the node capacity (-1 = unlimited).
-- -1 means unlimited; guard against that before computing fill ratios for UI bars.
do -- Node:getCapacity
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  local cap = depot:getCapacity()
  if cap > 0 then lurek.log.debug("depot holds up to " .. cap, "factory") end
end

--@api-stub: Node:setCapacity
-- Sets the node capacity (-1 = unlimited).
-- Use to apply storage upgrades â€” doubling the silo size raises capacity from 16 to 32.
do -- Node:setCapacity
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setCapacity(32)  -- silo upgraded to mk-II
end

--@api-stub: Node:getItemCount
-- Returns the number of items currently at this node.
-- Compare against capacity for HUD fill bars; a full depot also stops upstream pull.
do -- Node:getItemCount
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  local item = g:createItem("ore", -1)
  g:addItem(item, depot)
  lurek.log.debug("depot now holds " .. depot:getItemCount(), "factory")
end

--@api-stub: Node:isFull
-- Returns true if the node has reached its capacity.
-- Block trains/trucks visually before they offload when isFull returns true.
do -- Node:isFull
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setCapacity(1)
  g:addItem(g:createItem("ore", -1), depot)
  if depot:isFull() then lurek.log.warn("depot full!", "factory") end
end

--@api-stub: Node:isActive
-- Returns true if the node is active.
-- Inactive nodes are skipped by simulation and pathfinding â€” perfect for power-down states.
do -- Node:isActive
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  if depot:isActive() then
    lurek.log.debug("depot is online", "factory")
  end
end

--@api-stub: Node:setActive
-- Sets the active state of this node.
-- Toggle off during a brownout event; routes will avoid the node until it is reactivated.
do -- Node:setActive
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setActive(false)  -- mothballed for the level
end

--@api-stub: Node:getOverflowPolicy
-- Returns the overflow policy as a string.
-- Returns one of "reject", "destroy", "queue". Display it in the building inspector UI.
do -- Node:getOverflowPolicy
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setOverflowPolicy("reject")
  lurek.log.debug("overflow policy=" .. depot:getOverflowPolicy(), "factory")
end

--@api-stub: Node:setOverflowPolicy
-- Sets the overflow policy from a string.
-- Common choices: "queue" to buffer, "reject" to refuse, "destroy" to silently discard excess.
do -- Node:setOverflowPolicy
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setOverflowPolicy("queue")  -- buffer excess items rather than rejecting them
end

--@api-stub: Node:getFlowMode
-- Returns the flow mode as a string.
-- Returns the current mode ("push", "pull", "both") so UIs can show direction arrows.
do -- Node:getFlowMode
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setFlowMode("push")
  lurek.log.debug("flow mode=" .. depot:getFlowMode(), "factory")
end

--@api-stub: Node:setFlowMode
-- Sets the flow mode from a string.
-- "push" sends downstream actively, "pull" requests from upstream, "both" does both each tick.
do -- Node:setFlowMode
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setFlowMode("both")
end

--@api-stub: Node:getPushRate
-- Returns items per second this node pushes.
-- Items/second the node will push out; pair with setPushRate to model pump tiers.
do -- Node:getPushRate
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPushRate(2.5)
  lurek.log.debug("push rate=" .. depot:getPushRate() .. "/s", "factory")
end

--@api-stub: Node:setPushRate
-- Sets items per second this node pushes.
-- Use to model splitter/pump tier upgrades â€” tier-1 = 1.0, tier-2 = 2.5, tier-3 = 5.0.
do -- Node:setPushRate
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPushRate(5.0)  -- tier-3 pump
end

--@api-stub: Node:getPullRate
-- Returns items per second this node pulls.
-- Items/second the node will pull in; combine with push neighbours for accurate throughput estimates.
do -- Node:getPullRate
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPullRate(1.5)
  lurek.log.debug("pull rate=" .. depot:getPullRate() .. "/s", "factory")
end

--@api-stub: Node:setPullRate
-- Sets items per second this node pulls.
-- Set on assemblers/consumers so they cap how fast they request inputs even when belts can deliver more.
do -- Node:setPullRate
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPullRate(3.0)  -- consumer accepts up to 3 items/s
end

--@api-stub: Node:getPushFilter
-- Returns the push filter string, or nil if unset.
-- Returns the item-type string the node will push, or nil if unfiltered.
do -- Node:getPushFilter
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPushFilter("ore")
  local f = depot:getPushFilter()
  if f then lurek.log.debug("pushes only " .. f, "factory") end
end

--@api-stub: Node:setPushFilter
-- Sets the push filter string, or nil to clear.
-- Pass nil to clear; otherwise restrict pushes to a single item type (great for sorters).
do -- Node:setPushFilter
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPushFilter("iron_ingot")  -- splitter routes ingots only
end

--@api-stub: Node:getPullFilter
-- Returns the pull filter string, or nil if unset.
-- Returns the item type the node will accept; nil means it accepts everything.
do -- Node:getPullFilter
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPullFilter("coal")
  local f = depot:getPullFilter()
  if f then lurek.log.debug("pulls only " .. f, "factory") end
end

--@api-stub: Node:setPullFilter
-- Sets the pull filter string, or nil to clear.
-- Use to make a furnace request only its fuel type; pass nil to accept anything again.
do -- Node:setPullFilter
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPullFilter("coal")
end

--@api-stub: Node:getProcessTime
-- Returns the processing time in seconds.
-- Time (s) the node holds an item before passing it on â€” useful for furnace bake-time UIs.
do -- Node:getProcessTime
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setProcessTime(2.0)
  lurek.log.debug("process time " .. depot:getProcessTime() .. "s", "factory")
end

--@api-stub: Node:setProcessTime
-- Sets the processing time in seconds.
-- Set on assemblers/furnaces to model crafting duration â€” the conversion fires after this delay.
do -- Node:setProcessTime
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setProcessTime(1.5)  -- furnace bakes 1.5s per item
end

--@api-stub: Node:isQueueEnabled
-- Returns true if the node queue is enabled.
-- Queue-enabled nodes accept items past capacity into a side queue â€” toggle for FIFO buffering.
do -- Node:isQueueEnabled
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  if depot:isQueueEnabled() then
    lurek.log.debug("depot has FIFO buffer", "factory")
  end
end

--@api-stub: Node:setQueueEnabled
-- Enables or disables the node queue.
-- Enable on staging/buffer nodes; leave off on production nodes where back-pressure is desired.
do -- Node:setQueueEnabled
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
end

--@api-stub: Node:getQueueCapacity
-- Returns the queue capacity (-1 = unlimited).
-- Queue capacity is independent of node capacity; -1 = unlimited buffer (memory beware).
do -- Node:getQueueCapacity
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  depot:setQueueCapacity(64)
  lurek.log.debug("queue cap=" .. depot:getQueueCapacity(), "factory")
end

--@api-stub: Node:setQueueCapacity
-- Sets the queue capacity (-1 = unlimited).
-- Pair with setQueueEnabled(true); cap to a sane number to avoid runaway memory in long sessions.
do -- Node:setQueueCapacity
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  depot:setQueueCapacity(128)
end

--@api-stub: Node:getQueueSize
-- Returns the number of items currently in the queue.
-- Read each frame to render queue-fullness bars and to drive backlog warning sounds.
do -- Node:getQueueSize
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  local qsize = depot:getQueueSize()
  if qsize > 32 then lurek.log.warn("backlog at depot: " .. qsize, "factory") end
end

--@api-stub: Node:getItems
-- Returns a table of GraphItem handles at this node.
-- Iterate the result to render each parked item or to inspect its type and remaining life.
do -- Node:getItems
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  g:addItem(g:createItem("ore", -1), depot)
  g:addItem(g:createItem("coal", -1), depot)
  for _, it in ipairs(depot:getItems()) do lurek.log.debug("at depot: " .. it:getType(), "factory") end
end

--@api-stub: Node:getEdges
-- Returns a table of Edge handles connected to this node.
-- Pass "in", "out", or "both" (default) to filter direction; use to render connection arrows.
do -- Node:getEdges
  local g = lurek.graph.newGraph()
  local a = g:addNode("hub")
  local b = g:addNode("leaf")
  g:addEdge(a, b)
  lurek.log.debug("hub has " .. #a:getEdges("out") .. " outgoing edges", "factory")
end

--@api-stub: Node:clearConversion
-- Removes the conversion rule for the given input type.
-- Remove a single recipe (e.g. when the player swaps a furnace blueprint mid-level).
do -- Node:clearConversion
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setConversion("ore", "iron_ingot", 2, 1)
  depot:clearConversion("ore")
end

--@api-stub: Node:clearAllConversions
-- Removes all conversion rules from this node.
-- Wipe every recipe at once â€” handy when destroying & rebuilding a node's recipe set from a save file.
do -- Node:clearAllConversions
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setConversion("ore", "iron_ingot", 2, 1)
  depot:setConversion("coal", "ash", 1, 1)
  depot:clearAllConversions()
end

--@api-stub: Node:addTag
-- Attaches a string tag to this node for fast group queries.
-- Tag nodes for fast group queries â€” e.g. tag every refuelling bay "fuel" then look them up later.
do -- Node:addTag
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("fuel")
  depot:addTag("priority")
end

--@api-stub: Node:removeTag
-- Removes a tag from this node.
-- Drop a single tag (e.g. clearing the "sale" tag at the end of a market event).
do -- Node:removeTag
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("sale")
  depot:removeTag("sale")
end

--@api-stub: Node:hasTag
-- Returns true if this node has the given tag.
-- Branch on a tag to apply gameplay rules (refuel here? give bonus drops? etc.).
do -- Node:hasTag
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("safe_zone")
  if depot:hasTag("safe_zone") then
    lurek.log.debug("no enemies will spawn here", "ai")
  end
end

--@api-stub: Node:clearTags
-- Removes all tags from this node.
-- Drop every tag in one call â€” use on level-reset to clear stale event tags.
do -- Node:clearTags
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("flagged")
  depot:addTag("sale")
  depot:clearTags()
end

--@api-stub: Node:getTags
-- Returns a table of tag strings on this node.
-- Iterate to display tags in the inspector UI or to serialise them into a save file.
do -- Node:getTags
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("fuel")
  depot:addTag("priority")
  for _, t in ipairs(depot:getTags()) do lurek.log.debug("tag: " .. t, "factory") end
end

--@api-stub: Node:removeSupply
-- Removes the supply declaration for the given item type.
-- Stop a source from emitting a single item type without removing other supplies it produces.
do -- Node:removeSupply
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addSupply("ore", 100)
  depot:removeSupply("ore")
end

--@api-stub: Node:clearSupplies
-- Removes all supply declarations from this node.
-- Wipe every supply declaration at once â€” useful when retooling a mine to produce different ores.
do -- Node:clearSupplies
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addSupply("ore", 100)
  depot:addSupply("coal", 50)
  depot:clearSupplies()
end

--@api-stub: Node:removeDemand
-- Removes the demand declaration for the given item type.
-- Stop a consumer from requesting a single item type while leaving its other demands intact.
do -- Node:removeDemand
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addDemand("coal", 10, 1)
  depot:removeDemand("coal")
end

--@api-stub: Node:clearDemands
-- Removes all demand declarations from this node.
-- Wipe every demand declaration at once â€” useful when a factory is mothballed for a level objective.
do -- Node:clearDemands
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addDemand("ore", 5, 1)
  depot:addDemand("coal", 5, 1)
  depot:clearDemands()
end

--@api-stub: Node:enqueue
-- Pushes an item into the node queue.
-- Push an item directly into the FIFO queue (must be enabled first via setQueueEnabled).
do -- Node:enqueue
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  local item = g:createItem("ore", -1)
  depot:enqueue(item)
end

--@api-stub: Node:dequeue
-- Pops the next item from the node queue, or nil if empty.
-- Returns nil when empty â€” always guard the result before using it.
do -- Node:dequeue
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  depot:enqueue(g:createItem("ore", -1))
  local out = depot:dequeue()
  if out then lurek.log.debug("dequeued " .. out:getType(), "factory") end
end

--@api-stub: Node:type
-- Returns the type name "GraphNode".
-- Use in generic dispatchers that handle Nodes, Edges and Items through a single inspect helper.
do -- Node:type
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  if depot:type() == "GraphNode" then
    lurek.log.debug("inspecting a node", "factory")
  end
end

--@api-stub: Node:typeOf
-- Returns true when the given name matches "GraphNode" or a parent type.
-- typeOf("Object") matches every Lurek graph value â€” useful for very generic UI helpers.
do -- Node:typeOf
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  if depot:typeOf("GraphNode") then
    lurek.log.debug("yes, this is a node", "factory")
  end
end

-- â”€â”€ Graph methods â”€â”€

--@api-stub: LGraph:removeNode
-- Removes a node from the graph.
-- Removing a node also tears down its incident edges; check hasNode afterward to confirm.
do -- Graph:removeNode
  local g = lurek.graph.newGraph()
  local n = g:addNode("temp")
  g:removeNode(n)
  lurek.log.debug("temp node still here? " .. tostring(g:hasNode(n)), "factory")
end

--@api-stub: LGraph:hasNode
-- Returns true if the node exists in the graph.
-- Cheap existence check â€” useful when reloading from a save file before you re-link references.
do -- Graph:hasNode
  local g = lurek.graph.newGraph()
  local n = g:addNode("checkpoint")
  if g:hasNode(n) then
    lurek.log.debug("checkpoint registered", "factory")
  end
end

--@api-stub: LGraph:getNodes
-- Returns a table of all Node handles.
-- Returns a Lua array â€” iterate with ipairs to drive map renderers or save serialisation.
do -- Graph:getNodes
  local g = lurek.graph.newGraph()
  g:addNode("start")
  g:addNode("end")
  for _, n in ipairs(g:getNodes()) do lurek.log.debug("node " .. n:getType(), "factory") end
end

--@api-stub: LGraph:getNodeCount
-- Returns the number of nodes in the graph.
-- Read once after load to size HUD widgets (mini-map, node legend); cheaper than #getNodes().
do -- Graph:getNodeCount
  local g = lurek.graph.newGraph()
  g:addNode("start")
  g:addNode("end")
  lurek.log.info("graph has " .. g:getNodeCount() .. " nodes", "factory")
end

--@api-stub: LGraph:removeEdge
-- Removes an edge from the graph.
-- Use when the player demolishes a belt; downstream items are dropped per the edge cleanup logic.
do -- Graph:removeEdge
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  local e = g:addEdge(a, b)
  g:removeEdge(e)
end

--@api-stub: LGraph:hasEdge
-- Returns true if the edge exists in the graph.
-- Verify after a network mutation (load, undo, remote sync) that the edge survived.
do -- Graph:hasEdge
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  local e = g:addEdge(a, b)
  if g:hasEdge(e) then
    lurek.log.debug("edge a->b is wired", "factory")
  end
end

--@api-stub: LGraph:getEdges
-- Returns a table of all Edge handles.
-- Iterate to render every belt, or to compute a hash of the network for change-detection.
do -- Graph:getEdges
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  g:addEdge(a, b)
  for _, e in ipairs(g:getEdges()) do lurek.log.debug("edge type " .. e:getType(), "factory") end
end

--@api-stub: LGraph:getEdgeCount
-- Returns the number of edges in the graph.
-- Read once after load to size mini-map allocations; cheaper than #getEdges().
do -- Graph:getEdgeCount
  local g = lurek.graph.newGraph()
  g:addEdge(g:addNode("a"), g:addNode("b"))
  lurek.log.info("graph has " .. g:getEdgeCount() .. " edges", "factory")
end

--@api-stub: LGraph:removeItem
-- Removes an item from the graph entirely.
-- Use to scrap an item permanently (e.g. the player sold it from inventory) â€” distinct from kill().
do -- Graph:removeItem
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 8)
  local item = g:createItem("ore", -1)
  g:addItem(item, store)
  g:removeItem(item)
end

--@api-stub: LGraph:hasItem
-- Returns true if the item exists in the graph.
-- Defensive check before calling further methods on an item handle that might have been removed.
do -- Graph:hasItem
  local g = lurek.graph.newGraph()
  local store = g:addNode("store")
  local item = g:createItem("ore", -1)
  g:addItem(item, store)
  if g:hasItem(item) then lurek.log.debug("item still tracked", "factory") end
end

--@api-stub: LGraph:getItems
-- Returns a table of all GraphItem handles.
-- Iterate to draw every item; in tight inner loops prefer per-edge / per-node accessors instead.
do -- Graph:getItems
  local g = lurek.graph.newGraph()
  local store = g:addNode("store")
  g:addItem(g:createItem("ore", -1), store)
  g:addItem(g:createItem("coal", -1), store)
  lurek.log.debug("graph holds " .. #g:getItems() .. " items", "factory")
end

--@api-stub: LGraph:getItemCount
-- Returns the number of items in the graph.
-- Cheap O(1) read; use for HUD counters and to drive end-of-level objectives.
do -- Graph:getItemCount
  local g = lurek.graph.newGraph()
  g:addItem(g:createItem("ore", -1), g:addNode("store"))
  lurek.log.info("items in flight: " .. g:getItemCount(), "factory")
end

--@api-stub: LGraph:update
-- Advances simulation by dt seconds and fires event callbacks.
-- Call once per frame from lurek.process(dt) to advance simulation and fire event callbacks.
do -- Graph:update
  local g = lurek.graph.newGraph()
  g:addNode("hub")
  function lurek.process(dt)
    g:update(dt)
  end
end

--@api-stub: LGraph:step
-- Runs one discrete simulation step and fires event callbacks.
-- Fixed-tick variant â€” useful for deterministic sims (multiplayer, replays) where dt must be constant.
do -- Graph:step
  local g = lurek.graph.newGraph()
  g:addNode("hub")
  g:step()  -- one deterministic tick
end

--@api-stub: LGraph:tickParallel
-- Advances simulation by dt seconds using a parallelised decay phase.
-- Drop-in replacement for update() that parallelises decay scans via rayon â€” use for huge graphs.
do -- Graph:tickParallel
  local g = lurek.graph.newGraph()
  function lurek.process(dt)
    g:tickParallel(dt)
  end
end

--@api-stub: LGraph:getNeighbors
-- Returns a table of direct neighbor Node handles.
-- Returns direct neighbours â€” pair with getEdges to walk the graph for AI or rendering decisions.
do -- Graph:getNeighbors
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  g:addEdge(a, g:addNode("b"))
  g:addEdge(a, g:addNode("c"))
  lurek.log.debug("a has " .. #g:getNeighbors(a) .. " neighbours", "factory")
end

--@api-stub: LGraph:getComponents
-- Returns weakly connected components as a table of tables of Node handles.
-- Each inner table is one weakly-connected island â€” use to detect orphaned subgraphs after deletions.
do -- Graph:getComponents
  local g = lurek.graph.newGraph()
  g:addNode("island_a")
  g:addNode("island_b")
  lurek.log.info("disconnected components: " .. #g:getComponents(), "factory")
end

--@api-stub: LGraph:subgraph
-- Returns a new graph containing only selected nodes and induced links.
-- Use to run isolated simulation on a connected region without mutating the original graph.
do -- Graph:subgraph
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local c = g:addNode("c")
  g:addEdge(a, b)
  g:addEdge(b, c)
  local slice = g:subgraph({ a, b })
  lurek.log.info("slice nodes=" .. slice:getNodeCount() .. " edges=" .. slice:getEdgeCount(), "factory")
end

--@api-stub: LGraph:hasCycle
-- Returns true if the graph contains a directed cycle.
-- Refuse to topo-sort or to lay out a DAG layer-by-layer when this returns true.
do -- Graph:hasCycle
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  g:addEdge(a, b)
  g:addEdge(b, a)  -- creates a cycle
  if g:hasCycle() then lurek.log.warn("graph has a cycle!", "factory") end
end

--@api-stub: LGraph:topologicalSort
-- Returns a topologically sorted table of Node handles, or nil if a cycle exists.
-- Returns nil if the graph has a cycle; otherwise the result is a valid build/process order.
do -- Graph:topologicalSort
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("raw"), g:addNode("ingot")
  g:addEdge(a, b)
  local order = g:topologicalSort()
  if order then lurek.log.info("processing order: " .. #order .. " nodes", "factory") end
end

--@api-stub: LGraph:mst
-- Returns edge IDs forming a minimum spanning tree (Kruskal, undirected view).
-- Returns edge ids of a minimum spanning tree (Kruskal, undirected view) â€” useful for road-network planning.
do -- Graph:mst
  local g = lurek.graph.newGraph()
  g:addEdge(g:addNode("a"), g:addNode("b"))
  local tree = g:mst()
  lurek.log.info("MST contains " .. #tree .. " edges", "pathfind")
end

--@api-stub: LGraph:colorGraph
-- Assigns each node the smallest non-negative integer colour not shared with any.
-- Greedy graph colouring â€” use for register allocation, map colouring, or scheduling conflicts.
do -- Graph:colorGraph
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  g:addEdge(a, b)
  local colors = g:colorGraph()
  for node_id, c in pairs(colors) do lurek.log.debug("node " .. node_id .. " => colour " .. c, "pathfind") end
end

--@api-stub: LGraph:isBipartite
-- Returns `true` when the graph can be 2-coloured (bipartite check via BFS).
-- True when the graph is 2-colourable â€” use to validate matchings or alternating-layer layouts.
do -- Graph:isBipartite
  local g = lurek.graph.newGraph()
  g:addEdge(g:addNode("left"), g:addNode("right"))
  if g:isBipartite() then
    lurek.log.debug("graph splits cleanly into two halves", "pathfind")
  end
end

--@api-stub: LGraph:processDemand
-- Processes all supply/demand declarations and fires event callbacks.
-- Settles supply/demand once and fires demandFulfilled / supplyDepleted callbacks; call after edits.
do -- Graph:processDemand
  local g = lurek.graph.newGraph()
  local src = g:addNode("mine")
  src:addSupply("ore", 50)
  g:processDemand()
end

--@api-stub: LGraph:getStats
-- Returns a statistics snapshot table.
-- Returns a table with nodes/edges/items/itemsInTransit/queuedItems/totalDemand fields â€” perfect for HUDs.
do -- Graph:getStats
  local g = lurek.graph.newGraph()
  g:addNode("hub")
  local s = g:getStats()
  lurek.log.info("nodes=" .. s.nodes .. " edges=" .. s.edges .. " items=" .. s.items, "factory")
end

--@api-stub: LGraph:type
-- Returns the type name of this object.
-- Use in dispatchers that handle Graph, Node, Edge, and GraphItem through a single inspector path.
do -- Graph:type
  local g = lurek.graph.newGraph()
  if g:type() == "Graph" then
    lurek.log.debug("inspecting a graph root", "factory")
  end
end

--@api-stub: LGraph:typeOf
-- Returns true if this object is of the given type.
-- typeOf("Object") matches every Lurek graph value â€” useful for very generic UI helpers.
do -- Graph:typeOf
  local g = lurek.graph.newGraph()
  if g:typeOf("Graph") then
    lurek.log.debug("yes, this is a graph", "factory")
  end
end


--@api-stub: Node:addDemand
-- Registers a demand for a resource type on this node.
-- The graph supply/demand system routes items from supply nodes to demand nodes.
do -- Node:addDemand
  local g = lurek.graph.newGraph()
  local n = g:addNode("warehouse")
  n:addDemand("food", 50)
  lurek.log.info("demand added", "graph")
end

--@api-stub: LGraph:addEdge
-- Adds a directed or bidirectional edge between two nodes by name.
-- Returns an Edge handle for further configuration of capacity and travel time.
do -- Graph:addEdge
  local g = lurek.graph.newGraph()
  local a = g:addNode("city_a")
  local b = g:addNode("city_b")
  local e = g:addEdge(a, b, "road")
  lurek.log.info("edges: " .. g:getEdgeCount(), "graph")
end

--@api-stub: LGraph:addItem
-- Adds an existing item to a named node directly (bypassing createItem).
-- Use when you pre-build items outside the graph and inject them.
do -- Graph:addItem
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot")
  local item = g:createItem("wood", -1)
  g:addItem(item, depot)
  lurek.log.info("item count: " .. g:getItemCount(), "graph")
end

--@api-stub: LGraph:addNode
-- Creates a named node in the graph and returns its Node handle.
-- Nodes represent cities, depots, or production facilities in a logistics graph.
do -- Graph:addNode
  local g = lurek.graph.newGraph()
  local n = g:addNode("mine")
  n:setCapacity(200)
  lurek.log.info("nodes: " .. g:getNodeCount(), "graph")
end

--@api-stub: Node:addSupply
-- Registers a supply source for a resource type on this node.
-- The graph solver routes supply toward demand nodes along weighted edges.
do -- Node:addSupply
  local g = lurek.graph.newGraph()
  local n = g:addNode("mine")
  n:addSupply("ore", 100)
  lurek.log.info("supply added", "graph")
end

--@api-stub: LGraph:astar
-- Finds the shortest path between two nodes using A*.
-- Returns a table of node names or nil if no path exists.
do -- Graph:astar
  local g = lurek.graph.newGraph()
  local na = g:addNode("A") ; local nb = g:addNode("B") ; local nc = g:addNode("C")
  g:addEdge(na, nb) ; g:addEdge(nb, nc)
  local path = g:astar(na, nc)
  lurek.log.info("path length: " .. (path and #path or 0), "graph")
end

--@api-stub: LGraph:createItem
-- Creates a new item of the given type at the named node.
-- Returns a GraphItem handle; items are transported along edges by the graph solver.
do -- Graph:createItem
  local g = lurek.graph.newGraph()
  local factory = g:addNode("factory")
  local item = g:createItem("widget", -1)
  lurek.log.info("item alive: " .. tostring(item:isAlive()), "graph")
end

--@api-stub: LGraph:findPath
-- Returns the lowest-cost path between two nodes as a table of node names.
-- Uses the edge weight attribute; returns nil if target is unreachable.
do -- Graph:findPath
  local g = lurek.graph.newGraph()
  local na = g:addNode("A") ; local nb = g:addNode("B")
  g:addEdge(na, nb)
  local p = g:findPath(na, nb)
  lurek.log.info("found path: " .. (p and #p or 0) .. " nodes", "graph")
end

--@api-stub: LGraph:findPathForItem
-- Finds the optimal path for an item given its type constraints and allowed edges.
-- Some edges may restrict allowed item types; this variant respects those filters.
do -- Graph:findPathForItem
  local g = lurek.graph.newGraph()
  local ns = g:addNode("source") ; local nk = g:addNode("sink")
  g:addEdge(ns, nk)
  local item = g:createItem("ore", -1)
  local p = g:findPathForItem(item, ns, nk)
  lurek.log.info("item path: " .. (p and #p or 0), "graph")
end

--@api-stub: LGraph:getDistance
-- Returns the shortest-path distance between two nodes by edge weight sum.
-- Returns math.huge if the target is not reachable from the source.
do -- Graph:getDistance
  local g = lurek.graph.newGraph()
  local nx = g:addNode("X") ; local ny = g:addNode("Y")
  g:addEdge(nx, ny)
  local d = g:getDistance(nx, ny)
  lurek.log.info("distance X->Y: " .. tostring(d), "graph")
end

--@api-stub: LGraph:getEdgeBetween
-- Returns the Edge handle for the edge connecting two nodes, or nil if absent.
-- Use to query or modify an edge without keeping a reference from addEdge.
do -- Graph:getEdgeBetween
  local g = lurek.graph.newGraph()
  local na = g:addNode("A") ; local nb = g:addNode("B")
  g:addEdge(na, nb)
  local e = g:getEdgeBetween(na, nb)
  lurek.log.info("edge capacity: " .. tostring(e and e:getCapacity() or 0), "graph")
end

--@api-stub: LGraph:getReachable
-- Returns all nodes reachable from a source node within an optional max-cost.
-- Result is a table of node names; useful for range-of-movement or supply radius.
do -- Graph:getReachable
  local g = lurek.graph.newGraph()
  local na = g:addNode("A") ; local nb = g:addNode("B") ; local nc = g:addNode("C")
  g:addEdge(na, nb) ; g:addEdge(nb, nc)
  local reachable = g:getReachable(na, 5)
  lurek.log.info("reachable: " .. (reachable and #reachable or 0), "graph")
end

--@api-stub: LGraph:on
-- Registers a callback for a named graph event ("itemEnter", "edgeLeave", etc.).
-- Returns a listener id for later removal; multiple callbacks can share the same event.
do -- Graph:on
  local g = lurek.graph.newGraph()
  g:on("itemEnter", function(item, node)
    lurek.log.info("item arrived at " .. tostring(node), "graph")
  end)
  lurek.log.info("listener registered", "graph")
end

--@api-stub: LGraph:sendItem
-- Routes an item from its current node toward a destination, traversing edges each update.
-- Item moves by travel-time; subscribe to "itemEnter" to know when it lands.
do -- Graph:sendItem
  local g = lurek.graph.newGraph()
  local na = g:addNode("A") ; local nb = g:addNode("B")
  local edge = g:addEdge(na, nb)
  local item = g:createItem("gold", -1)
  g:sendItem(item, edge)
  lurek.log.info("item dispatched", "graph")
end

--@api-stub: Node:setConversion
-- Sets a type conversion rule on this node: input type + amount -> output type.
-- Conversion fires automatically when enough input items accumulate.
do -- Node:setConversion
  local g = lurek.graph.newGraph()
  local n = g:addNode("smelter")
  n:setConversion("ore", "ingot", 2, 1)
  lurek.log.info("conversion set", "graph")
end

-- =============================================================================
-- COVERAGE: 125 uncovered lurek.graph API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LGraphEdge methods
-- -----------------------------------------------------------------------------

-- ---- Example: LGraphEdge:getType --------------------------------------------
--@api-stub: LGraphEdge:getType
-- Returns the edge type string.
-- Use to filter edges by conveyor/pipe/road type in route queries.
do -- LGraphEdge:getType
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  lurek.log.info("edge type=" .. edge:getType(), "graph")
end
--@api-stub: LGraphEdge:setType
-- Sets the edge type string.
-- Use to upgrade a dirt road edge to a paved road at runtime.
do -- LGraphEdge:setType
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "dirt_road")
  edge:setType("paved_road")
  lurek.log.info("edge type=" .. edge:getType(), "graph")
end
--@api-stub: LGraphEdge:getFrom
-- Returns the source node handle.
-- Use to trace routes backwards from a destination node.
do -- LGraphEdge:getFrom
  local g = lurek.graph.newGraph()
  local na = g:addNode("source", 8); local nb = g:addNode("sink", 8)
  local edge = g:addEdge(na, nb, "pipe")
  local from = edge:getFrom()
  lurek.log.info("from type=" .. from:getType(), "graph")
end
--@api-stub: LGraphEdge:getTo
-- Returns the destination node handle.
-- Use to traverse the graph from source to sink.
do -- LGraphEdge:getTo
  local g = lurek.graph.newGraph()
  local na = g:addNode("source", 8); local nb = g:addNode("sink", 8)
  local edge = g:addEdge(na, nb, "pipe")
  local to = edge:getTo()
  lurek.log.info("to type=" .. to:getType(), "graph")
end
--@api-stub: LGraphEdge:getCapacity
-- Returns the edge capacity (-1 = unlimited).
-- Use to check if an edge can accept more items in a flow simulation.
do -- LGraphEdge:getCapacity
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  edge:setCapacity(50)
  lurek.log.info("capacity=" .. edge:getCapacity(), "graph")
end
--@api-stub: LGraphEdge:setCapacity
-- Sets the edge capacity (-1 = unlimited).
-- Use to simulate bottlenecks in a factory conveyor network.
do -- LGraphEdge:setCapacity
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  edge:setCapacity(100)
  lurek.log.info("capacity=" .. edge:getCapacity(), "graph")
end
--@api-stub: LGraphEdge:getThroughput
-- Returns items per second this edge can transfer.
-- Use in UI to display belt speed to the player.
do -- LGraphEdge:getThroughput
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  edge:setThroughput(5.0)
  lurek.log.info("throughput=" .. edge:getThroughput(), "graph")
end
--@api-stub: LGraphEdge:setThroughput
-- Sets items per second this edge can transfer.
-- Upgrade belts by raising throughput when the player researches better technology.
do -- LGraphEdge:setThroughput
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  edge:setThroughput(15.0)
  lurek.log.info("throughput=" .. edge:getThroughput(), "graph")
end
--@api-stub: LGraphEdge:getTravelTime
-- Returns the travel time in seconds for items on this edge.
-- Use in UI to show ETA for deliveries.
do -- LGraphEdge:getTravelTime
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "road")
  edge:setTravelTime(3.5)
  lurek.log.info("travel_time=" .. edge:getTravelTime(), "graph")
end
--@api-stub: LGraphEdge:setTravelTime
-- Sets the travel time in seconds for items on this edge.
-- Simulate road distance or network latency with this value.
do -- LGraphEdge:setTravelTime
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "road")
  edge:setTravelTime(2.0)
  lurek.log.info("travel_time=" .. edge:getTravelTime(), "graph")
end
--@api-stub: LGraphEdge:getWeight
-- Returns the pathfinding weight of this edge.
-- Use in A* or Dijkstra queries to find least-cost routes.
do -- LGraphEdge:getWeight
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "road")
  edge:setWeight(1.5)
  lurek.log.info("weight=" .. edge:getWeight(), "graph")
end
--@api-stub: LGraphEdge:setWeight
-- Sets the pathfinding weight of this edge.
-- Raise weight on flooded roads to route deliveries around them.
do -- LGraphEdge:setWeight
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "road")
  edge:setWeight(5.0)
  lurek.log.info("weight=" .. edge:getWeight(), "graph")
end
--@api-stub: LGraphEdge:getSpeedModifier
-- Returns the speed modifier applied to items in transit.
-- Use to check uphill road penalties on unit movement.
do -- LGraphEdge:getSpeedModifier
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "uphill_road")
  edge:setSpeedModifier(0.6)
  lurek.log.info("speed_modifier=" .. edge:getSpeedModifier(), "graph")
end
--@api-stub: LGraphEdge:setSpeedModifier
-- Sets the speed modifier applied to items in transit.
-- Use 2.0 for a conveyor boost and 0.5 for a swamp tile.
do -- LGraphEdge:setSpeedModifier
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "boost_belt")
  edge:setSpeedModifier(2.0)
  lurek.log.info("speed_modifier=" .. edge:getSpeedModifier(), "graph")
end
--@api-stub: LGraphEdge:getCooldown
-- Returns the cooldown duration in seconds.
-- Use to show a recharge timer in the UI for a warp-gate edge.
do -- LGraphEdge:getCooldown
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "warp_gate")
  edge:setCooldown(5.0)
  lurek.log.info("cooldown=" .. edge:getCooldown(), "graph")
end
--@api-stub: LGraphEdge:setCooldown
-- Sets the cooldown duration in seconds.
-- Use to prevent edge spam by requiring a delay between shipments.
do -- LGraphEdge:setCooldown
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "express_belt")
  edge:setCooldown(2.0)
  lurek.log.info("cooldown=" .. edge:getCooldown(), "graph")
end
--@api-stub: LGraphEdge:isOnCooldown
-- Returns true if the edge is currently on cooldown.
-- Use to decide whether to route to an alternate edge.
do -- LGraphEdge:isOnCooldown
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  lurek.log.info("on_cooldown=" .. tostring(edge:isOnCooldown()), "graph")
end
--@api-stub: LGraphEdge:isBidirectional
-- Returns true if items can travel the edge in either direction.
-- Use to determine if a road edge is one-way.
do -- LGraphEdge:isBidirectional
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "road")
  edge:setBidirectional(true)
  lurek.log.info("bidirectional=" .. tostring(edge:isBidirectional()), "graph")
end
--@api-stub: LGraphEdge:setBidirectional
-- Sets whether items can travel the edge in either direction.
-- Use for undirected edges like water pipes or two-way roads.
do -- LGraphEdge:setBidirectional
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "road")
  edge:setBidirectional(false)
  lurek.log.info("bidirectional=" .. tostring(edge:isBidirectional()), "graph")
end
--@api-stub: LGraphEdge:isActive
-- Returns true if the edge is active.
-- Inactive edges are excluded from flow and pathfinding.
do -- LGraphEdge:isActive
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  lurek.log.info("active=" .. tostring(edge:isActive()), "graph")
end
--@api-stub: LGraphEdge:setActive
-- Sets the active state of this edge.
-- Deactivate an edge when a bridge is damaged without removing it from the graph.
do -- LGraphEdge:setActive
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "bridge")
  edge:setActive(false)
  lurek.log.info("active=" .. tostring(edge:isActive()), "graph")
end
--@api-stub: LGraphEdge:getItemsInTransit
-- Returns a table of GraphItem handles currently in transit on this edge.
-- Use to render item icons moving along a belt in the UI.
do -- LGraphEdge:getItemsInTransit
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  local items = edge:getItemsInTransit()
  lurek.log.info("items_in_transit=" .. #items, "graph")
end
--@api-stub: LGraphEdge:addAllowedType
-- Adds an item type to the edge allow-list.
-- Use to restrict a pipe to only carry "water" or "oil" items.
do -- LGraphEdge:addAllowedType
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "pipe")
  edge:addAllowedType("water")
  lurek.log.info("water allowed=" .. tostring(edge:isItemTypeAllowed("water")), "graph")
end
--@api-stub: LGraphEdge:removeAllowedType
-- Removes an item type from the edge allow-list.
-- Use to revoke a chemical item's transit rights after a research event.
do -- LGraphEdge:removeAllowedType
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "pipe")
  edge:addAllowedType("acid")
  edge:removeAllowedType("acid")
  lurek.log.info("acid allowed after remove=" .. tostring(edge:isItemTypeAllowed("acid")), "graph")
end
--@api-stub: LGraphEdge:clearAllowedTypes
-- Clears the edge allow-list so all item types are permitted.
-- Use to reset a multi-purpose conveyor back to its default state.
do -- LGraphEdge:clearAllowedTypes
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  edge:addAllowedType("iron")
  edge:clearAllowedTypes()
  lurek.log.info("iron allowed after clear=" .. tostring(edge:isItemTypeAllowed("iron")), "graph")
end
--@api-stub: LGraphEdge:isItemTypeAllowed
-- Returns true if the given item type is allowed on this edge.
-- Use before dispatching an item to check routing compatibility.
do -- LGraphEdge:isItemTypeAllowed
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "pipe")
  edge:addAllowedType("gas")
  lurek.log.info("gas allowed=" .. tostring(edge:isItemTypeAllowed("gas")), "graph")
  lurek.log.info("water allowed=" .. tostring(edge:isItemTypeAllowed("water")), "graph")
end
--@api-stub: LGraphEdge:type
-- Returns the type name "GraphEdge".
-- Use for generic object type dispatching in a mixed-object container.
do -- LGraphEdge:type
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  lurek.log.info("type=" .. edge:type(), "graph")
end
--@api-stub: LGraphEdge:typeOf
-- Returns true when the given name matches "GraphEdge" or a parent type.
-- Use to check instance types in polymorphic collections.
do -- LGraphEdge:typeOf
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  local edge = g:addEdge(na, nb, "belt")
  lurek.log.info("is GraphEdge=" .. tostring(edge:typeOf("GraphEdge")), "graph")
  lurek.log.info("is Other=" .. tostring(edge:typeOf("Other")), "graph")
end
--@api-stub: LGraphNode:getType
-- Returns the node type string.
-- Use to query node type in a heterogeneous supply-chain graph.
do -- LGraphNode:getType
  local g = lurek.graph.newGraph()
  local n = g:addNode("furnace", 16)
  lurek.log.info("node type=" .. n:getType(), "graph")
end
--@api-stub: LGraphNode:setType
-- Sets the node type string.
-- Use to upgrade a node type (e.g. "furnace" â†’ "blast_furnace") during play.
do -- LGraphNode:setType
  local g = lurek.graph.newGraph()
  local n = g:addNode("furnace", 16)
  n:setType("blast_furnace")
  lurek.log.info("node type=" .. n:getType(), "graph")
end
--@api-stub: LGraphNode:getCapacity
-- Returns the node capacity (-1 = unlimited).
-- Use to render a capacity bar in the factory overlay UI.
do -- LGraphNode:getCapacity
  local g = lurek.graph.newGraph()
  local n = g:addNode("warehouse", 100)
  lurek.log.info("capacity=" .. n:getCapacity(), "graph")
end
--@api-stub: LGraphNode:setCapacity
-- Sets the node capacity (-1 = unlimited).
-- Upgrade storage capacity with a tech research unlock.
do -- LGraphNode:setCapacity
  local g = lurek.graph.newGraph()
  local n = g:addNode("warehouse", 50)
  n:setCapacity(200)
  lurek.log.info("capacity=" .. n:getCapacity(), "graph")
end
--@api-stub: LGraphNode:getItemCount
-- Returns the number of items currently at this node.
-- Use to trigger a delivery when a node is almost full.
do -- LGraphNode:getItemCount
  local g = lurek.graph.newGraph()
  local n = g:addNode("depot", 32)
  lurek.log.info("items=" .. n:getItemCount(), "graph")
end
--@api-stub: LGraphNode:isFull
-- Returns true if the node has reached its capacity.
-- Use to pause input belts before overflow.
do -- LGraphNode:isFull
  local g = lurek.graph.newGraph()
  local n = g:addNode("buffer", 4)
  lurek.log.info("full=" .. tostring(n:isFull()), "graph")
end
--@api-stub: LGraphNode:isActive
-- Returns true if the node is active.
-- Inactive nodes are skipped during flow and pathfinding.
do -- LGraphNode:isActive
  local g = lurek.graph.newGraph()
  local n = g:addNode("reactor", 8)
  lurek.log.info("active=" .. tostring(n:isActive()), "graph")
end
--@api-stub: LGraphNode:setActive
-- Sets the active state of this node.
-- Deactivate a node during a power failure event.
do -- LGraphNode:setActive
  local g = lurek.graph.newGraph()
  local n = g:addNode("reactor", 8)
  n:setActive(false)
  lurek.log.info("active=" .. tostring(n:isActive()), "graph")
end
--@api-stub: LGraphNode:getOverflowPolicy
-- Returns the overflow policy as a string.
-- Policies may include 'drop', 'block', or 'overflow_to_queue'.
do -- LGraphNode:getOverflowPolicy
  local g = lurek.graph.newGraph()
  local n = g:addNode("silo", 50)
  n:setOverflowPolicy("destroy")
  lurek.log.info("overflow_policy=" .. n:getOverflowPolicy(), "graph")
end
--@api-stub: LGraphNode:setOverflowPolicy
-- Sets the overflow policy from a string.
-- 'reject' stalls incoming items; 'destroy' discards surplus items; 'queue' buffers them.
do -- LGraphNode:setOverflowPolicy
  local g = lurek.graph.newGraph()
  local n = g:addNode("silo", 50)
  n:setOverflowPolicy("reject")
  lurek.log.info("overflow_policy=" .. n:getOverflowPolicy(), "graph")
end
--@api-stub: LGraphNode:getFlowMode
-- Returns the flow mode as a string.
-- Modes like 'push', 'pull', or 'balanced' control item distribution.
do -- LGraphNode:getFlowMode
  local g = lurek.graph.newGraph()
  local n = g:addNode("distributor", 16)
  n:setFlowMode("both")
  lurek.log.info("flow_mode=" .. n:getFlowMode(), "graph")
end
--@api-stub: LGraphNode:setFlowMode
-- Sets the flow mode from a string.
-- Use 'pull' for consumer nodes, 'push' for producer nodes, 'both' for bidirectional.
do -- LGraphNode:setFlowMode
  local g = lurek.graph.newGraph()
  local n = g:addNode("factory", 16)
  n:setFlowMode("pull")
  lurek.log.info("flow_mode=" .. n:getFlowMode(), "graph")
end
--@api-stub: LGraphNode:getPushRate
-- Returns items per second this node pushes.
-- Use to display production rate in the factory HUD.
do -- LGraphNode:getPushRate
  local g = lurek.graph.newGraph()
  local n = g:addNode("mine", 32)
  n:setPushRate(2.5)
  lurek.log.info("push_rate=" .. n:getPushRate(), "graph")
end
--@api-stub: LGraphNode:setPushRate
-- Sets items per second this node pushes.
-- Increase push rate when the player upgrades the mine.
do -- LGraphNode:setPushRate
  local g = lurek.graph.newGraph()
  local n = g:addNode("mine", 32)
  n:setPushRate(5.0)
  lurek.log.info("push_rate=" .. n:getPushRate(), "graph")
end
--@api-stub: LGraphNode:getPullRate
-- Returns items per second this node pulls.
-- Use to balance supply with consumer demand in the factory.
do -- LGraphNode:getPullRate
  local g = lurek.graph.newGraph()
  local n = g:addNode("furnace", 16)
  n:setPullRate(3.0)
  lurek.log.info("pull_rate=" .. n:getPullRate(), "graph")
end
--@api-stub: LGraphNode:setPullRate
-- Sets items per second this node pulls.
-- Throttle a consumer to avoid starving other consumers.
do -- LGraphNode:setPullRate
  local g = lurek.graph.newGraph()
  local n = g:addNode("assembler", 16)
  n:setPullRate(1.5)
  lurek.log.info("pull_rate=" .. n:getPullRate(), "graph")
end
--@api-stub: LGraphNode:getPushFilter
-- Returns the push filter string, or nil if unset.
-- Use to validate that the filter was configured correctly before the game starts.
do -- LGraphNode:getPushFilter
  local g = lurek.graph.newGraph()
  local n = g:addNode("sorter", 8)
  n:setPushFilter("iron_ore")
  lurek.log.info("push_filter=" .. tostring(n:getPushFilter()), "graph")
end
--@api-stub: LGraphNode:setPushFilter
-- Sets the push filter string, or nil to clear.
-- Use to restrict a node to only push a specific item type.
do -- LGraphNode:setPushFilter
  local g = lurek.graph.newGraph()
  local n = g:addNode("sorter", 8)
  n:setPushFilter("copper_ore")
  lurek.log.info("push_filter=" .. tostring(n:getPushFilter()), "graph")
end
--@api-stub: LGraphNode:getPullFilter
-- Returns the pull filter string, or nil if unset.
-- Use to display the configured demand type in the factory UI.
do -- LGraphNode:getPullFilter
  local g = lurek.graph.newGraph()
  local n = g:addNode("furnace", 16)
  n:setPullFilter("coal")
  lurek.log.info("pull_filter=" .. tostring(n:getPullFilter()), "graph")
end
--@api-stub: LGraphNode:setPullFilter
-- Sets the pull filter string, or nil to clear.
-- Restrict what a consumer node accepts to avoid mixing item types.
do -- LGraphNode:setPullFilter
  local g = lurek.graph.newGraph()
  local n = g:addNode("furnace", 16)
  n:setPullFilter("iron_ore")
  lurek.log.info("pull_filter=" .. tostring(n:getPullFilter()), "graph")
end
--@api-stub: LGraphNode:getProcessTime
-- Returns the processing time in seconds.
-- Use in UI to display a progress bar duration for a crafting node.
do -- LGraphNode:getProcessTime
  local g = lurek.graph.newGraph()
  local n = g:addNode("assembler", 8)
  n:setProcessTime(4.0)
  lurek.log.info("process_time=" .. n:getProcessTime(), "graph")
end
--@api-stub: LGraphNode:setProcessTime
-- Sets the processing time in seconds.
-- Lower this on upgrade to simulate faster crafting machines.
do -- LGraphNode:setProcessTime
  local g = lurek.graph.newGraph()
  local n = g:addNode("assembler", 8)
  n:setProcessTime(2.0)
  lurek.log.info("process_time=" .. n:getProcessTime(), "graph")
end
--@api-stub: LGraphNode:isQueueEnabled
-- Returns true if the node queue is enabled.
-- Queuing allows items to wait at a node instead of backing up the network.
do -- LGraphNode:isQueueEnabled
  local g = lurek.graph.newGraph()
  local n = g:addNode("buffer", 32)
  n:setQueueEnabled(true)
  lurek.log.info("queue_enabled=" .. tostring(n:isQueueEnabled()), "graph")
end
--@api-stub: LGraphNode:setQueueEnabled
-- Enables or disables the node queue.
-- Disable on pass-through nodes to reduce memory overhead.
do -- LGraphNode:setQueueEnabled
  local g = lurek.graph.newGraph()
  local n = g:addNode("splitter", 8)
  n:setQueueEnabled(false)
  lurek.log.info("queue_enabled=" .. tostring(n:isQueueEnabled()), "graph")
end
--@api-stub: LGraphNode:getQueueCapacity
-- Returns the queue capacity (-1 = unlimited).
-- Use to display remaining queue slots in the factory UI.
do -- LGraphNode:getQueueCapacity
  local g = lurek.graph.newGraph()
  local n = g:addNode("buffer", 32)
  n:setQueueEnabled(true); n:setQueueCapacity(10)
  lurek.log.info("queue_capacity=" .. n:getQueueCapacity(), "graph")
end
--@api-stub: LGraphNode:setQueueCapacity
-- Sets the queue capacity (-1 = unlimited).
-- Limit queue to prevent runaway memory use on throughput bottlenecks.
do -- LGraphNode:setQueueCapacity
  local g = lurek.graph.newGraph()
  local n = g:addNode("buffer", 32)
  n:setQueueEnabled(true); n:setQueueCapacity(20)
  lurek.log.info("queue_capacity=" .. n:getQueueCapacity(), "graph")
end
--@api-stub: LGraphNode:getQueueSize
-- Returns the number of items currently in the queue.
-- Use to trigger overflow warnings when the queue approaches capacity.
do -- LGraphNode:getQueueSize
  local g = lurek.graph.newGraph()
  local n = g:addNode("depot", 32)
  n:setQueueEnabled(true)
  lurek.log.info("queue_size=" .. n:getQueueSize(), "graph")
end
--@api-stub: LGraphNode:getItems
-- Returns a table of GraphItem handles at this node.
-- Use to iterate items and apply buffs or transformations.
do -- LGraphNode:getItems
  local g = lurek.graph.newGraph()
  local n = g:addNode("depot", 32)
  local items = n:getItems()
  lurek.log.info("item_count=" .. #items, "graph")
end
--@api-stub: LGraphNode:getEdges
-- Returns a table of Edge handles connected to this node.
-- Use to traverse the graph from a given node.
do -- LGraphNode:getEdges
  local g = lurek.graph.newGraph()
  local na = g:addNode("a", 8); local nb = g:addNode("b", 8)
  g:addEdge(na, nb, "belt")
  local edges = na:getEdges()
  lurek.log.info("edge_count=" .. #edges, "graph")
end
--@api-stub: LGraphNode:setConversion
-- Adds or replaces a conversion rule on this node.
-- Use a furnace node to automatically convert "iron_ore" â†’ "iron_ingot".
do -- LGraphNode:setConversion
  local g = lurek.graph.newGraph()
  local n = g:addNode("furnace", 16)
  n:setConversion("iron_ore", "iron_ingot", 1)
  lurek.log.info("conversion added to furnace", "graph")
end
--@api-stub: LGraphNode:clearConversion
-- Removes the conversion rule for the given input type.
-- Use when the furnace recipe is changed by the player.
do -- LGraphNode:clearConversion
  local g = lurek.graph.newGraph()
  local n = g:addNode("furnace", 16)
  n:setConversion("iron_ore", "iron_ingot", 1)
  n:clearConversion("iron_ore")
  lurek.log.info("conversion cleared", "graph")
end
--@api-stub: LGraphNode:clearAllConversions
-- Removes all conversion rules from this node.
-- Use when upgrading a furnace to a different machine type.
do -- LGraphNode:clearAllConversions
  local g = lurek.graph.newGraph()
  local n = g:addNode("multi_furnace", 32)
  n:setConversion("iron_ore", "iron_ingot", 1)
  n:setConversion("copper_ore", "copper_ingot", 1)
  n:clearAllConversions()
  lurek.log.info("all conversions cleared", "graph")
end
--@api-stub: LGraphNode:addTag
-- Attaches a string tag to this node for fast group queries.
-- Use to find all "storage" or "producer" nodes in a single query.
do -- LGraphNode:addTag
  local g = lurek.graph.newGraph()
  local n = g:addNode("warehouse", 100)
  n:addTag("storage"); n:addTag("secure")
  lurek.log.info("has storage=" .. tostring(n:hasTag("storage")), "graph")
end
--@api-stub: LGraphNode:removeTag
-- Removes a tag from this node.
-- Use to revoke the "available" tag when a node is taken offline.
do -- LGraphNode:removeTag
  local g = lurek.graph.newGraph()
  local n = g:addNode("depot", 32)
  n:addTag("available"); n:removeTag("available")
  lurek.log.info("has available=" .. tostring(n:hasTag("available")), "graph")
end
--@api-stub: LGraphNode:hasTag
-- Returns true if this node has the given tag.
-- Use to query which nodes are eligible depots in a delivery query.
do -- LGraphNode:hasTag
  local g = lurek.graph.newGraph()
  local n = g:addNode("station", 64)
  n:addTag("train_stop")
  lurek.log.info("has train_stop=" .. tostring(n:hasTag("train_stop")), "graph")
end
--@api-stub: LGraphNode:clearTags
-- Removes all tags from this node.
-- Use when resetting a repurposed node.
do -- LGraphNode:clearTags
  local g = lurek.graph.newGraph()
  local n = g:addNode("depot", 32)
  n:addTag("a"); n:addTag("b"); n:clearTags()
  lurek.log.info("tags after clear=" .. #n:getTags(), "graph")
end
--@api-stub: LGraphNode:getTags
-- Returns a table of tag strings on this node.
-- Use when saving a node's full metadata to a save file.
do -- LGraphNode:getTags
  local g = lurek.graph.newGraph()
  local n = g:addNode("depot", 32)
  n:addTag("port"); n:addTag("western")
  local tags = n:getTags()
  lurek.log.info("tag count=" .. #tags, "graph")
end
--@api-stub: LGraphNode:addSupply
-- Declares a supply of the given item type and quantity at this node.
-- Use on mine nodes to advertise available resources for routing.
do -- LGraphNode:addSupply
  local g = lurek.graph.newGraph()
  local n = g:addNode("mine", 100)
  n:addSupply("iron_ore", 500)
  lurek.log.info("supply added", "graph")
end
--@api-stub: LGraphNode:removeSupply
-- Removes the supply declaration for the given item type.
-- Use when a mine runs out of a specific ore type.
do -- LGraphNode:removeSupply
  local g = lurek.graph.newGraph()
  local n = g:addNode("mine", 100)
  n:addSupply("iron_ore", 500)
  n:removeSupply("iron_ore")
  lurek.log.info("supply removed", "graph")
end
--@api-stub: LGraphNode:clearSupplies
-- Removes all supply declarations from this node.
-- Use when a node changes role from mine to depot.
do -- LGraphNode:clearSupplies
  local g = lurek.graph.newGraph()
  local n = g:addNode("mine", 100)
  n:addSupply("gold_ore", 200)
  n:clearSupplies()
  lurek.log.info("all supplies cleared", "graph")
end
--@api-stub: LGraphNode:addDemand
-- Declares a demand for the given item type, quantity, and priority.
-- Use on factory nodes to signal which materials they need from suppliers.
do -- LGraphNode:addDemand
  local g = lurek.graph.newGraph()
  local n = g:addNode("factory", 32)
  n:addDemand("steel", 100, 1)   -- priority 1 (high)
  lurek.log.info("demand declared for steel", "graph")
end
--@api-stub: LGraphNode:removeDemand
-- Removes the demand declaration for the given item type.
-- Use when the factory switches to a different recipe.
do -- LGraphNode:removeDemand
  local g = lurek.graph.newGraph()
  local n = g:addNode("factory", 32)
  n:addDemand("steel", 100, 1)
  n:removeDemand("steel")
  lurek.log.info("demand removed", "graph")
end
--@api-stub: LGraphNode:clearDemands
-- Removes all demand declarations from this node.
-- Use when a factory is decommissioned.
do -- LGraphNode:clearDemands
  local g = lurek.graph.newGraph()
  local n = g:addNode("factory", 32)
  n:addDemand("wood", 50, 2); n:addDemand("stone", 50, 2)
  n:clearDemands()
  lurek.log.info("all demands cleared", "graph")
end
--@api-stub: LGraphNode:enqueue
-- Pushes an item into the node queue.
-- Use to seed a node's queue with initial items at level start.
do -- LGraphNode:enqueue
  local g = lurek.graph.newGraph()
  local n = g:addNode("buffer", 32)
  n:setQueueEnabled(true)
  n:enqueue(g:createItem("iron_ingot", 1))
  lurek.log.info("queue_size=" .. n:getQueueSize(), "graph")
end
--@api-stub: LGraphNode:dequeue
-- Pops the next item from the node queue, or nil if empty.
-- Use in a consumer loop to process queued items one per tick.
do -- LGraphNode:dequeue
  local g = lurek.graph.newGraph()
  local n = g:addNode("buffer", 32)
  n:setQueueEnabled(true)
  n:enqueue(g:createItem("coal", 1))
  local item = n:dequeue()
  lurek.log.info("dequeued=" .. tostring(item), "graph")
end
--@api-stub: LGraphNode:type
-- Returns the type name "GraphNode".
-- Use for generic object type dispatching in a mixed-object container.
do -- LGraphNode:type
  local g = lurek.graph.newGraph()
  local n = g:addNode("depot", 8)
  lurek.log.info("type=" .. n:type(), "graph")
end
--@api-stub: LGraphNode:typeOf
-- Returns true when the given name matches "GraphNode" or a parent type.
-- Use to check instance types in polymorphic collections.
do -- LGraphNode:typeOf
  local g = lurek.graph.newGraph()
  local n = g:addNode("depot", 8)
  lurek.log.info("is GraphNode=" .. tostring(n:typeOf("GraphNode")), "graph")
  lurek.log.info("is Other=" .. tostring(n:typeOf("Other")), "graph")
end
