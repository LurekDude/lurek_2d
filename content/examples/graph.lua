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

-- ── lurek.graph.* functions ──

--@api-stub: lurek.graph.newGraph
-- Creates a new empty directed graph for item flow simulation.
-- Create one Graph per simulation domain (one for the conveyor network, another for the road map); they are independent.
do  -- lurek.graph.newGraph
  local belts = lurek.graph.newGraph()
  local depot = belts:addNode("depot", 32)
  local sink  = belts:addNode("sink", -1)
  belts:addEdge(depot, sink, "belt")
  lurek.log.info("belt graph: " .. tostring(belts), "factory")
end

-- ── GraphItem methods ──

--@api-stub: GraphItem:getType
-- Returns the item type string.
-- Branch on item type to apply per-type logic (display sprite, sound, conversion).
do  -- GraphItem:getType
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if ore:getType() == "ore" then lurek.log.info("crate holds raw ore", "factory") end
end

--@api-stub: GraphItem:setType
-- Sets the item type string.
-- Use after a manual conversion or upgrade so subsequent filters and conversions see the new type.
do  -- GraphItem:setType
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:setType("iron_ingot")
  lurek.log.info("ore promoted to " .. ore:getType(), "factory")
end

--@api-stub: GraphItem:getDecayTime
-- Returns the decay time in seconds (-1 = immortal).
-- Useful when you want to render a freshness bar — divide getRemainingLife by getDecayTime.
do  -- GraphItem:getDecayTime
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  local total = ore:getDecayTime()
  local frac = ore:getRemainingLife() / total
  lurek.log.debug("ore freshness " .. math.floor(frac * 100) .. "%", "factory")
end

--@api-stub: GraphItem:setDecayTime
-- Sets the decay time in seconds (-1 = immortal).
-- Pass -1 to make an item immortal (e.g. a tracked debug marker that should never expire).
do  -- GraphItem:setDecayTime
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:setDecayTime(-1)
  lurek.log.debug("ore is now immortal: decay=" .. ore:getDecayTime(), "factory")
end

--@api-stub: GraphItem:getRemainingLife
-- Returns the remaining life in seconds.
-- Drop the item from the UI early (or warn the player) when remaining life falls under a threshold.
do  -- GraphItem:getRemainingLife
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if ore:getRemainingLife() < 5.0 then
    lurek.log.warn("ore about to spoil!", "factory")
  end
end

--@api-stub: GraphItem:isAlive
-- Returns true if the item is alive.
-- Skip rendering or selecting items that have already decayed but linger in your UI list one frame.
do  -- GraphItem:isAlive
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if not ore:isAlive() then
    lurek.log.warn("ore decayed before reaching the smelter", "factory")
  end
end

--@api-stub: GraphItem:kill
-- Marks this graph item as dead so it is removed on the next cleanup pass.
-- Kill items the player consumes mid-flight (e.g. a missile destroyed by a turret) so the next cleanup pass removes them.
do  -- GraphItem:kill
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:kill()
  lurek.log.info("ore manually destroyed, alive=" .. tostring(ore:isAlive()), "factory")
end

--@api-stub: GraphItem:getPriority
-- Returns the item priority.
-- Sort player-visible item lists by priority so VIP cargo (rescue victims, hero items) appears at the top.
do  -- GraphItem:getPriority
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:setPriority(5)
  lurek.log.debug("ore priority " .. ore:getPriority(), "factory")
end

--@api-stub: GraphItem:setPriority
-- Sets the scheduling priority; higher values are processed before lower ones.
-- Higher priorities ship first when an edge is at capacity; reserve very high values for emergency cargo.
do  -- GraphItem:setPriority
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  ore:setPriority(10)
  local rock = g:createItem("rock", 30.0)
  rock:setPriority(1)  -- ore (10) beats rock (1) at the next bottleneck
end

--@api-stub: GraphItem:getPosition
-- Returns the item position: node userdata if at a node, (edge, progress).
-- Returns Node, (Edge, progress), or nothing — use the multi-return arity to dispatch on state.
do  -- GraphItem:getPosition
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

--@api-stub: GraphItem:type
-- Returns the type name of this object.
-- Use in a generic dispatcher that handles Nodes, Edges and Items via a shared inspect function.
do  -- GraphItem:type
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if ore:type() == "GraphItem" then
    lurek.log.debug("inspecting graph item", "factory")
  end
end

--@api-stub: GraphItem:typeOf
-- Returns true if this object is of the given type.
-- typeOf is the lurek-wide isInstanceOf check — pass "Object" to match the common ancestor.
do  -- GraphItem:typeOf
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 16)
  local ore = g:createItem("ore", 30.0)
  g:addItem(ore, store)
  if ore:typeOf("Object") then
    lurek.log.debug("ore is a tracked Lurek object", "factory")
  end
end

-- ── Edge methods ──

--@api-stub: Edge:getType
-- Returns the edge type string.
-- Group edges by type when rendering (conveyor / pipe / road get different sprites).
do  -- Edge:getType
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
do  -- Edge:setType
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
do  -- Edge:getFrom
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
do  -- Edge:getTo
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  local dst = belt:getTo()
  lurek.log.debug("belt feeds into " .. dst:getType() .. " node", "factory")
end

--@api-stub: Edge:getCapacity
-- Returns the edge capacity (-1 = unlimited).
-- -1 means unlimited — guard against that when normalising for a UI fill bar.
do  -- Edge:getCapacity
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
do  -- Edge:setCapacity
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setCapacity(8)  -- tier-2 belt holds 8 items
end

--@api-stub: Edge:getThroughput
-- Returns items per second this edge can transfer.
-- Multiply by the simulation tick to estimate items-per-tick when planning factory ratios.
do  -- Edge:getThroughput
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
do  -- Edge:setThroughput
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setThroughput(4.0)
end

--@api-stub: Edge:getTravelTime
-- Returns the travel time in seconds for items on this edge.
-- Use the value to time visual effects (fade-in spawn at the destination) so they match the sim.
do  -- Edge:getTravelTime
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
do  -- Edge:setTravelTime
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setTravelTime(2.0)  -- longer belt for slower planet level
end

--@api-stub: Edge:getWeight
-- Returns the pathfinding weight of this edge.
-- Pathfinding (findPath, getDistance, A*) sums edge weights — read it back to display the route cost.
do  -- Edge:getWeight
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
do  -- Edge:setWeight
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setWeight(10.0)  -- toll road, prefer alternatives
end

--@api-stub: Edge:getSpeedModifier
-- Returns the speed modifier applied to items in transit.
-- Multiplies in-transit progress speed without changing pathfinding weight; great for boosters.
do  -- Edge:getSpeedModifier
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
do  -- Edge:setSpeedModifier
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setSpeedModifier(2.0)  -- accelerator belt
end

--@api-stub: Edge:getCooldown
-- Returns the cooldown duration in seconds.
-- After dispatch the edge waits this long before accepting the next item — read it for HUD warnings.
do  -- Edge:getCooldown
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
do  -- Edge:setCooldown
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setCooldown(2.0)  -- catapult, fires every 2s
end

--@api-stub: Edge:isOnCooldown
-- Returns true if the edge is currently on cooldown.
-- Render the edge greyed out or blinking while it cannot accept new items.
do  -- Edge:isOnCooldown
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
-- Bidirectional edges let pathfinding consider reverse traversal — useful for roads, deadly for one-way conveyors.
do  -- Edge:isBidirectional
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
do  -- Edge:setBidirectional
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setBidirectional(true)  -- two-way road
end

--@api-stub: Edge:isActive
-- Returns true if the edge is active.
-- Inactive edges are skipped by routing and transport — pause one to simulate maintenance or power-loss.
do  -- Edge:isActive
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
do  -- Edge:setActive
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  belt:setActive(false)  -- power outage; routes will avoid this edge
end

--@api-stub: Edge:getItemsInTransit
-- Returns a table of GraphItem handles currently in transit on this edge.
-- Iterate to draw each item along the belt, or to count throughput pressure for an analytics overlay.
do  -- Edge:getItemsInTransit
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
-- Make a belt accept only specific item types — call multiple times to whitelist several ("ore","coal").
do  -- Edge:addAllowedType
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
do  -- Edge:removeAllowedType
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
do  -- Edge:clearAllowedTypes
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
do  -- Edge:isItemTypeAllowed
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
-- Generic dispatcher — branch on type name to route Edges, Nodes, and Items through a shared inspector.
do  -- Edge:type
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
-- typeOf("Object") matches every Lurek graph value — useful for very generic UI helpers.
do  -- Edge:typeOf
  local g = lurek.graph.newGraph()
  local a = g:addNode("source")
  local b = g:addNode("sink")
  local belt = g:addEdge(a, b, "conveyor")
  if belt:typeOf("GraphEdge") then
    lurek.log.debug("yes, this is an edge", "factory")
  end
end

-- ── Node methods ──

--@api-stub: Node:getType
-- Returns the node type string.
-- Render different sprites per node type (depot vs furnace vs sink) by branching on getType().
do  -- Node:getType
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  if depot:getType() == "depot" then
    lurek.log.debug("rendering depot pad", "render")
  end
end

--@api-stub: Node:setType
-- Sets the node type string.
-- Re-type a node when the player upgrades a building (depot → automated_depot).
do  -- Node:setType
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setType("automated_depot")
end

--@api-stub: Node:getCapacity
-- Returns the node capacity (-1 = unlimited).
-- -1 means unlimited; guard against that before computing fill ratios for UI bars.
do  -- Node:getCapacity
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  local cap = depot:getCapacity()
  if cap > 0 then lurek.log.debug("depot holds up to " .. cap, "factory") end
end

--@api-stub: Node:setCapacity
-- Sets the node capacity (-1 = unlimited).
-- Use to apply storage upgrades — doubling the silo size raises capacity from 16 to 32.
do  -- Node:setCapacity
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setCapacity(32)  -- silo upgraded to mk-II
end

--@api-stub: Node:getItemCount
-- Returns the number of items currently at this node.
-- Compare against capacity for HUD fill bars; a full depot also stops upstream pull.
do  -- Node:getItemCount
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  local item = g:createItem("ore", -1)
  g:addItem(item, depot)
  lurek.log.debug("depot now holds " .. depot:getItemCount(), "factory")
end

--@api-stub: Node:isFull
-- Returns true if the node has reached its capacity.
-- Block trains/trucks visually before they offload when isFull returns true.
do  -- Node:isFull
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setCapacity(1)
  g:addItem(g:createItem("ore", -1), depot)
  if depot:isFull() then lurek.log.warn("depot full!", "factory") end
end

--@api-stub: Node:isActive
-- Returns true if the node is active.
-- Inactive nodes are skipped by simulation and pathfinding — perfect for power-down states.
do  -- Node:isActive
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  if depot:isActive() then
    lurek.log.debug("depot is online", "factory")
  end
end

--@api-stub: Node:setActive
-- Sets the active state of this node.
-- Toggle off during a brownout event; routes will avoid the node until it is reactivated.
do  -- Node:setActive
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setActive(false)  -- mothballed for the level
end

--@api-stub: Node:getOverflowPolicy
-- Returns the overflow policy as a string.
-- Returns one of "reject", "destroy", "queue". Display it in the building inspector UI.
do  -- Node:getOverflowPolicy
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setOverflowPolicy("reject")
  lurek.log.debug("overflow policy=" .. depot:getOverflowPolicy(), "factory")
end

--@api-stub: Node:setOverflowPolicy
-- Sets the overflow policy from a string.
-- Common choices: "queue" to buffer, "reject" to refuse, "destroy" to silently discard excess.
do  -- Node:setOverflowPolicy
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setOverflowPolicy("queue")  -- buffer excess items rather than rejecting them
end

--@api-stub: Node:getFlowMode
-- Returns the flow mode as a string.
-- Returns the current mode ("push", "pull", "both") so UIs can show direction arrows.
do  -- Node:getFlowMode
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setFlowMode("push")
  lurek.log.debug("flow mode=" .. depot:getFlowMode(), "factory")
end

--@api-stub: Node:setFlowMode
-- Sets the flow mode from a string.
-- "push" sends downstream actively, "pull" requests from upstream, "both" does both each tick.
do  -- Node:setFlowMode
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setFlowMode("both")
end

--@api-stub: Node:getPushRate
-- Returns items per second this node pushes.
-- Items/second the node will push out; pair with setPushRate to model pump tiers.
do  -- Node:getPushRate
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPushRate(2.5)
  lurek.log.debug("push rate=" .. depot:getPushRate() .. "/s", "factory")
end

--@api-stub: Node:setPushRate
-- Sets items per second this node pushes.
-- Use to model splitter/pump tier upgrades — tier-1 = 1.0, tier-2 = 2.5, tier-3 = 5.0.
do  -- Node:setPushRate
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPushRate(5.0)  -- tier-3 pump
end

--@api-stub: Node:getPullRate
-- Returns items per second this node pulls.
-- Items/second the node will pull in; combine with push neighbours for accurate throughput estimates.
do  -- Node:getPullRate
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPullRate(1.5)
  lurek.log.debug("pull rate=" .. depot:getPullRate() .. "/s", "factory")
end

--@api-stub: Node:setPullRate
-- Sets items per second this node pulls.
-- Set on assemblers/consumers so they cap how fast they request inputs even when belts can deliver more.
do  -- Node:setPullRate
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPullRate(3.0)  -- consumer accepts up to 3 items/s
end

--@api-stub: Node:getPushFilter
-- Returns the push filter string, or nil if unset.
-- Returns the item-type string the node will push, or nil if unfiltered.
do  -- Node:getPushFilter
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPushFilter("ore")
  local f = depot:getPushFilter()
  if f then lurek.log.debug("pushes only " .. f, "factory") end
end

--@api-stub: Node:setPushFilter
-- Sets the push filter string, or nil to clear.
-- Pass nil to clear; otherwise restrict pushes to a single item type (great for sorters).
do  -- Node:setPushFilter
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPushFilter("iron_ingot")  -- splitter routes ingots only
end

--@api-stub: Node:getPullFilter
-- Returns the pull filter string, or nil if unset.
-- Returns the item type the node will accept; nil means it accepts everything.
do  -- Node:getPullFilter
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPullFilter("coal")
  local f = depot:getPullFilter()
  if f then lurek.log.debug("pulls only " .. f, "factory") end
end

--@api-stub: Node:setPullFilter
-- Sets the pull filter string, or nil to clear.
-- Use to make a furnace request only its fuel type; pass nil to accept anything again.
do  -- Node:setPullFilter
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setPullFilter("coal")
end

--@api-stub: Node:getProcessTime
-- Returns the processing time in seconds.
-- Time (s) the node holds an item before passing it on — useful for furnace bake-time UIs.
do  -- Node:getProcessTime
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setProcessTime(2.0)
  lurek.log.debug("process time " .. depot:getProcessTime() .. "s", "factory")
end

--@api-stub: Node:setProcessTime
-- Sets the processing time in seconds.
-- Set on assemblers/furnaces to model crafting duration — the conversion fires after this delay.
do  -- Node:setProcessTime
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setProcessTime(1.5)  -- furnace bakes 1.5s per item
end

--@api-stub: Node:isQueueEnabled
-- Returns true if the node queue is enabled.
-- Queue-enabled nodes accept items past capacity into a side queue — toggle for FIFO buffering.
do  -- Node:isQueueEnabled
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
do  -- Node:setQueueEnabled
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
end

--@api-stub: Node:getQueueCapacity
-- Returns the queue capacity (-1 = unlimited).
-- Queue capacity is independent of node capacity; -1 = unlimited buffer (memory beware).
do  -- Node:getQueueCapacity
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  depot:setQueueCapacity(64)
  lurek.log.debug("queue cap=" .. depot:getQueueCapacity(), "factory")
end

--@api-stub: Node:setQueueCapacity
-- Sets the queue capacity (-1 = unlimited).
-- Pair with setQueueEnabled(true); cap to a sane number to avoid runaway memory in long sessions.
do  -- Node:setQueueCapacity
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  depot:setQueueCapacity(128)
end

--@api-stub: Node:getQueueSize
-- Returns the number of items currently in the queue.
-- Read each frame to render queue-fullness bars and to drive backlog warning sounds.
do  -- Node:getQueueSize
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  local qsize = depot:getQueueSize()
  if qsize > 32 then lurek.log.warn("backlog at depot: " .. qsize, "factory") end
end

--@api-stub: Node:getItems
-- Returns a table of GraphItem handles at this node.
-- Iterate the result to render each parked item or to inspect its type and remaining life.
do  -- Node:getItems
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  g:addItem(g:createItem("ore", -1), depot)
  g:addItem(g:createItem("coal", -1), depot)
  for _, it in ipairs(depot:getItems()) do lurek.log.debug("at depot: " .. it:getType(), "factory") end
end

--@api-stub: Node:getEdges
-- Returns a table of Edge handles connected to this node.
-- Pass "in", "out", or "both" (default) to filter direction; use to render connection arrows.
do  -- Node:getEdges
  local g = lurek.graph.newGraph()
  local a = g:addNode("hub")
  local b = g:addNode("leaf")
  g:addEdge(a, b)
  lurek.log.debug("hub has " .. #a:getEdges("out") .. " outgoing edges", "factory")
end

--@api-stub: Node:clearConversion
-- Removes the conversion rule for the given input type.
-- Remove a single recipe (e.g. when the player swaps a furnace blueprint mid-level).
do  -- Node:clearConversion
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setConversion("ore", "iron_ingot", 2, 1)
  depot:clearConversion("ore")
end

--@api-stub: Node:clearAllConversions
-- Removes all conversion rules from this node.
-- Wipe every recipe at once — handy when destroying & rebuilding a node's recipe set from a save file.
do  -- Node:clearAllConversions
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setConversion("ore", "iron_ingot", 2, 1)
  depot:setConversion("coal", "ash", 1, 1)
  depot:clearAllConversions()
end

--@api-stub: Node:addTag
-- Attaches a string tag to this node for fast group queries.
-- Tag nodes for fast group queries — e.g. tag every refuelling bay "fuel" then look them up later.
do  -- Node:addTag
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("fuel")
  depot:addTag("priority")
end

--@api-stub: Node:removeTag
-- Removes a tag from this node.
-- Drop a single tag (e.g. clearing the "sale" tag at the end of a market event).
do  -- Node:removeTag
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("sale")
  depot:removeTag("sale")
end

--@api-stub: Node:hasTag
-- Returns true if this node has the given tag.
-- Branch on a tag to apply gameplay rules (refuel here? give bonus drops? etc.).
do  -- Node:hasTag
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("safe_zone")
  if depot:hasTag("safe_zone") then
    lurek.log.debug("no enemies will spawn here", "ai")
  end
end

--@api-stub: Node:clearTags
-- Removes all tags from this node.
-- Drop every tag in one call — use on level-reset to clear stale event tags.
do  -- Node:clearTags
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("flagged")
  depot:addTag("sale")
  depot:clearTags()
end

--@api-stub: Node:getTags
-- Returns a table of tag strings on this node.
-- Iterate to display tags in the inspector UI or to serialise them into a save file.
do  -- Node:getTags
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addTag("fuel")
  depot:addTag("priority")
  for _, t in ipairs(depot:getTags()) do lurek.log.debug("tag: " .. t, "factory") end
end

--@api-stub: Node:removeSupply
-- Removes the supply declaration for the given item type.
-- Stop a source from emitting a single item type without removing other supplies it produces.
do  -- Node:removeSupply
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addSupply("ore", 100)
  depot:removeSupply("ore")
end

--@api-stub: Node:clearSupplies
-- Removes all supply declarations from this node.
-- Wipe every supply declaration at once — useful when retooling a mine to produce different ores.
do  -- Node:clearSupplies
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addSupply("ore", 100)
  depot:addSupply("coal", 50)
  depot:clearSupplies()
end

--@api-stub: Node:removeDemand
-- Removes the demand declaration for the given item type.
-- Stop a consumer from requesting a single item type while leaving its other demands intact.
do  -- Node:removeDemand
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addDemand("coal", 10, 1)
  depot:removeDemand("coal")
end

--@api-stub: Node:clearDemands
-- Removes all demand declarations from this node.
-- Wipe every demand declaration at once — useful when a factory is mothballed for a level objective.
do  -- Node:clearDemands
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:addDemand("ore", 5, 1)
  depot:addDemand("coal", 5, 1)
  depot:clearDemands()
end

--@api-stub: Node:enqueue
-- Pushes an item into the node queue.
-- Push an item directly into the FIFO queue (must be enabled first via setQueueEnabled).
do  -- Node:enqueue
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  depot:setQueueEnabled(true)
  local item = g:createItem("ore", -1)
  depot:enqueue(item)
end

--@api-stub: Node:dequeue
-- Pops the next item from the node queue, or nil if empty.
-- Returns nil when empty — always guard the result before using it.
do  -- Node:dequeue
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
do  -- Node:type
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  if depot:type() == "GraphNode" then
    lurek.log.debug("inspecting a node", "factory")
  end
end

--@api-stub: Node:typeOf
-- Returns true when the given name matches "GraphNode" or a parent type.
-- typeOf("Object") matches every Lurek graph value — useful for very generic UI helpers.
do  -- Node:typeOf
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  if depot:typeOf("GraphNode") then
    lurek.log.debug("yes, this is a node", "factory")
  end
end

-- ── Graph methods ──

--@api-stub: Graph:removeNode
-- Removes a node from the graph.
-- Removing a node also tears down its incident edges; check hasNode afterward to confirm.
do  -- Graph:removeNode
  local g = lurek.graph.newGraph()
  local n = g:addNode("temp")
  g:removeNode(n)
  lurek.log.debug("temp node still here? " .. tostring(g:hasNode(n)), "factory")
end

--@api-stub: Graph:hasNode
-- Returns true if the node exists in the graph.
-- Cheap existence check — useful when reloading from a save file before you re-link references.
do  -- Graph:hasNode
  local g = lurek.graph.newGraph()
  local n = g:addNode("checkpoint")
  if g:hasNode(n) then
    lurek.log.debug("checkpoint registered", "factory")
  end
end

--@api-stub: Graph:getNodes
-- Returns a table of all Node handles.
-- Returns a Lua array — iterate with ipairs to drive map renderers or save serialisation.
do  -- Graph:getNodes
  local g = lurek.graph.newGraph()
  g:addNode("start")
  g:addNode("end")
  for _, n in ipairs(g:getNodes()) do lurek.log.debug("node " .. n:getType(), "factory") end
end

--@api-stub: Graph:getNodeCount
-- Returns the number of nodes in the graph.
-- Read once after load to size HUD widgets (mini-map, node legend); cheaper than #getNodes().
do  -- Graph:getNodeCount
  local g = lurek.graph.newGraph()
  g:addNode("start")
  g:addNode("end")
  lurek.log.info("graph has " .. g:getNodeCount() .. " nodes", "factory")
end

--@api-stub: Graph:removeEdge
-- Removes an edge from the graph.
-- Use when the player demolishes a belt; downstream items are dropped per the edge cleanup logic.
do  -- Graph:removeEdge
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  local e = g:addEdge(a, b)
  g:removeEdge(e)
end

--@api-stub: Graph:hasEdge
-- Returns true if the edge exists in the graph.
-- Verify after a network mutation (load, undo, remote sync) that the edge survived.
do  -- Graph:hasEdge
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  local e = g:addEdge(a, b)
  if g:hasEdge(e) then
    lurek.log.debug("edge a->b is wired", "factory")
  end
end

--@api-stub: Graph:getEdges
-- Returns a table of all Edge handles.
-- Iterate to render every belt, or to compute a hash of the network for change-detection.
do  -- Graph:getEdges
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  g:addEdge(a, b)
  for _, e in ipairs(g:getEdges()) do lurek.log.debug("edge type " .. e:getType(), "factory") end
end

--@api-stub: Graph:getEdgeCount
-- Returns the number of edges in the graph.
-- Read once after load to size mini-map allocations; cheaper than #getEdges().
do  -- Graph:getEdgeCount
  local g = lurek.graph.newGraph()
  g:addEdge(g:addNode("a"), g:addNode("b"))
  lurek.log.info("graph has " .. g:getEdgeCount() .. " edges", "factory")
end

--@api-stub: Graph:removeItem
-- Removes an item from the graph entirely.
-- Use to scrap an item permanently (e.g. the player sold it from inventory) — distinct from kill().
do  -- Graph:removeItem
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 8)
  local item = g:createItem("ore", -1)
  g:addItem(item, store)
  g:removeItem(item)
end

--@api-stub: Graph:hasItem
-- Returns true if the item exists in the graph.
-- Defensive check before calling further methods on an item handle that might have been removed.
do  -- Graph:hasItem
  local g = lurek.graph.newGraph()
  local store = g:addNode("store")
  local item = g:createItem("ore", -1)
  g:addItem(item, store)
  if g:hasItem(item) then lurek.log.debug("item still tracked", "factory") end
end

--@api-stub: Graph:getItems
-- Returns a table of all GraphItem handles.
-- Iterate to draw every item; in tight inner loops prefer per-edge / per-node accessors instead.
do  -- Graph:getItems
  local g = lurek.graph.newGraph()
  local store = g:addNode("store")
  g:addItem(g:createItem("ore", -1), store)
  g:addItem(g:createItem("coal", -1), store)
  lurek.log.debug("graph holds " .. #g:getItems() .. " items", "factory")
end

--@api-stub: Graph:getItemCount
-- Returns the number of items in the graph.
-- Cheap O(1) read; use for HUD counters and to drive end-of-level objectives.
do  -- Graph:getItemCount
  local g = lurek.graph.newGraph()
  g:addItem(g:createItem("ore", -1), g:addNode("store"))
  lurek.log.info("items in flight: " .. g:getItemCount(), "factory")
end

--@api-stub: Graph:update
-- Advances simulation by dt seconds and fires event callbacks.
-- Call once per frame from lurek.process(dt) to advance simulation and fire event callbacks.
do  -- Graph:update
  local g = lurek.graph.newGraph()
  g:addNode("hub")
  function lurek.process(dt)
    g:update(dt)
  end
end

--@api-stub: Graph:step
-- Runs one discrete simulation step and fires event callbacks.
-- Fixed-tick variant — useful for deterministic sims (multiplayer, replays) where dt must be constant.
do  -- Graph:step
  local g = lurek.graph.newGraph()
  g:addNode("hub")
  g:step()  -- one deterministic tick
end

--@api-stub: Graph:tickParallel
-- Advances simulation by dt seconds using a parallelised decay phase.
-- Drop-in replacement for update() that parallelises decay scans via rayon — use for huge graphs.
do  -- Graph:tickParallel
  local g = lurek.graph.newGraph()
  function lurek.process(dt)
    g:tickParallel(dt)
  end
end

--@api-stub: Graph:getNeighbors
-- Returns a table of direct neighbor Node handles.
-- Returns direct neighbours — pair with getEdges to walk the graph for AI or rendering decisions.
do  -- Graph:getNeighbors
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  g:addEdge(a, g:addNode("b"))
  g:addEdge(a, g:addNode("c"))
  lurek.log.debug("a has " .. #g:getNeighbors(a) .. " neighbours", "factory")
end

--@api-stub: Graph:getComponents
-- Returns weakly connected components as a table of tables of Node handles.
-- Each inner table is one weakly-connected island — use to detect orphaned subgraphs after deletions.
do  -- Graph:getComponents
  local g = lurek.graph.newGraph()
  g:addNode("island_a")
  g:addNode("island_b")
  lurek.log.info("disconnected components: " .. #g:getComponents(), "factory")
end

--@api-stub: Graph:hasCycle
-- Returns true if the graph contains a directed cycle.
-- Refuse to topo-sort or to lay out a DAG layer-by-layer when this returns true.
do  -- Graph:hasCycle
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  g:addEdge(a, b)
  g:addEdge(b, a)  -- creates a cycle
  if g:hasCycle() then lurek.log.warn("graph has a cycle!", "factory") end
end

--@api-stub: Graph:topologicalSort
-- Returns a topologically sorted table of Node handles, or nil if a cycle exists.
-- Returns nil if the graph has a cycle; otherwise the result is a valid build/process order.
do  -- Graph:topologicalSort
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("raw"), g:addNode("ingot")
  g:addEdge(a, b)
  local order = g:topologicalSort()
  if order then lurek.log.info("processing order: " .. #order .. " nodes", "factory") end
end

--@api-stub: Graph:mst
-- Returns edge IDs forming a minimum spanning tree (Kruskal, undirected view).
-- Returns edge ids of a minimum spanning tree (Kruskal, undirected view) — useful for road-network planning.
do  -- Graph:mst
  local g = lurek.graph.newGraph()
  g:addEdge(g:addNode("a"), g:addNode("b"))
  local tree = g:mst()
  lurek.log.info("MST contains " .. #tree .. " edges", "pathfind")
end

--@api-stub: Graph:colorGraph
-- Assigns each node the smallest non-negative integer colour not shared with any.
-- Greedy graph colouring — use for register allocation, map colouring, or scheduling conflicts.
do  -- Graph:colorGraph
  local g = lurek.graph.newGraph()
  local a, b = g:addNode("a"), g:addNode("b")
  g:addEdge(a, b)
  local colors = g:colorGraph()
  for node_id, c in pairs(colors) do lurek.log.debug("node " .. node_id .. " => colour " .. c, "pathfind") end
end

--@api-stub: Graph:isBipartite
-- Returns `true` when the graph can be 2-coloured (bipartite check via BFS).
-- True when the graph is 2-colourable — use to validate matchings or alternating-layer layouts.
do  -- Graph:isBipartite
  local g = lurek.graph.newGraph()
  g:addEdge(g:addNode("left"), g:addNode("right"))
  if g:isBipartite() then
    lurek.log.debug("graph splits cleanly into two halves", "pathfind")
  end
end

--@api-stub: Graph:processDemand
-- Processes all supply/demand declarations and fires event callbacks.
-- Settles supply/demand once and fires demandFulfilled / supplyDepleted callbacks; call after edits.
do  -- Graph:processDemand
  local g = lurek.graph.newGraph()
  local src = g:addNode("mine")
  src:addSupply("ore", 50)
  g:processDemand()
end

--@api-stub: Graph:getStats
-- Returns a statistics snapshot table.
-- Returns a table with nodes/edges/items/itemsInTransit/queuedItems/totalDemand fields — perfect for HUDs.
do  -- Graph:getStats
  local g = lurek.graph.newGraph()
  g:addNode("hub")
  local s = g:getStats()
  lurek.log.info("nodes=" .. s.nodes .. " edges=" .. s.edges .. " items=" .. s.items, "factory")
end

--@api-stub: Graph:type
-- Returns the type name of this object.
-- Use in dispatchers that handle Graph, Node, Edge, and GraphItem through a single inspector path.
do  -- Graph:type
  local g = lurek.graph.newGraph()
  if g:type() == "Graph" then
    lurek.log.debug("inspecting a graph root", "factory")
  end
end

--@api-stub: Graph:typeOf
-- Returns true if this object is of the given type.
-- typeOf("Object") matches every Lurek graph value — useful for very generic UI helpers.
do  -- Graph:typeOf
  local g = lurek.graph.newGraph()
  if g:typeOf("Graph") then
    lurek.log.debug("yes, this is a graph", "factory")
  end
end

