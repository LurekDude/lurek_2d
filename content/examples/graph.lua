-- content/examples/graph.lua
-- lurek.graph API examples: logistics graphs, pathfinding, supply/demand, and graph algorithms.
-- Run: cargo run -- content/examples/graph.lua

-- =============================================================================
-- Graph Creation
-- =============================================================================

--@api-stub: lurek.graph.newGraph
-- Creates an empty logistics graph with no nodes, edges, items, or callbacks.
do
  -- newGraph() returns a fresh graph handle. Use it to model any directed network:
  -- factory belts, quest dependency trees, tech trees, dialog flow, or AI decision graphs.
  local quest_graph = lurek.graph.newGraph()

  -- Build a simple quest dependency: "find_sword" must complete before "slay_dragon"
  local find_sword = quest_graph:addNode("find_sword")
  local slay_dragon = quest_graph:addNode("slay_dragon")
  quest_graph:addEdge(find_sword, slay_dragon, "requires")

  lurek.log.info("quest graph: " .. quest_graph:getNodeCount() .. " quests, "
    .. quest_graph:getEdgeCount() .. " dependencies", "quest")
end

-- =============================================================================
-- GraphItem Methods
-- =============================================================================

--@api-stub: LGraphNode:getType
-- Returns the item type string used by filters, conversions, supplies, and demands.
do
  -- Item types drive routing decisions. The graph uses them to match supply/demand
  -- and decide which edges an item may traverse (via allowed-type filters).
  local g = lurek.graph.newGraph()
  local warehouse = g:addNode("warehouse", 32)
  local package = g:createItem("health_potion", 60.0)
  g:addItem(package, warehouse)

  -- Check the type to decide rendering: potions get a glow effect
  if package:getType() == "health_potion" then
    lurek.log.info("rendering potion with glow shader", "render")
  end
end

--@api-stub: LGraphNode:setType
-- Changes the item type string used by graph routing and processing rules.
do
  -- Use setType to model item transformation outside of node conversions.
  -- Example: a crafting system where raw materials get refined mid-transit.
  local g = lurek.graph.newGraph()
  local forge = g:addNode("forge", 8)
  local raw_blade = g:createItem("raw_blade", -1)
  g:addItem(raw_blade, forge)

  -- The smith finishes the blade
  raw_blade:setType("enchanted_sword")
  lurek.log.info("blade forged into: " .. raw_blade:getType(), "craft")
end

--@api-stub: LGraphItem:getDecayTime
-- Returns the total decay lifetime configured for this item.
do
  -- Decay models perishable goods: food spoilage, spell duration, buff timers.
  -- A decay time of -1 means the item never expires.
  local g = lurek.graph.newGraph()
  local kitchen = g:addNode("kitchen", 16)
  local bread = g:createItem("bread", 30.0)  -- spoils after 30 seconds
  g:addItem(bread, kitchen)

  -- Show freshness percentage in the UI
  local total = bread:getDecayTime()
  local remaining = bread:getRemainingLife()
  local freshness = math.floor((remaining / total) * 100)
  lurek.log.debug("bread freshness: " .. freshness .. "%", "ui")
end

--@api-stub: LGraphItem:setDecayTime
-- Sets the total decay lifetime for this item.
do
  -- Use setDecayTime(-1) to make an item immortal (e.g., quest items that must not expire).
  -- Use a positive value to start or reset a spoilage timer.
  local g = lurek.graph.newGraph()
  local vault = g:addNode("vault", 4)
  local artifact = g:createItem("ancient_relic", 10.0)
  g:addItem(artifact, vault)

  -- Player casts a preservation spell: relic no longer decays
  artifact:setDecayTime(-1)
  lurek.log.info("relic preserved, decay=" .. artifact:getDecayTime(), "magic")
end

--@api-stub: LGraphItem:getRemainingLife
-- Returns this item's remaining lifetime before decay.
do
  -- Use getRemainingLife() to trigger urgency warnings in the UI.
  -- When remaining life hits 0, the graph fires an "itemDecay" event.
  local g = lurek.graph.newGraph()
  local cooler = g:addNode("cooler", 8)
  local fish = g:createItem("fish", 20.0)
  g:addItem(fish, cooler)

  -- Warn the player when perishables are about to spoil
  if fish:getRemainingLife() < 5.0 then
    lurek.log.warn("fish about to spoil! Deliver it now!", "logistics")
  end
end

--@api-stub: LGraphItem:isAlive
-- Returns whether this item is still alive in the graph simulation.
do
  -- isAlive() returns false after the item decays or is manually killed.
  -- Dead items are ignored by routing but remain queryable until removed.
  local g = lurek.graph.newGraph()
  local market = g:addNode("market", 16)
  local milk = g:createItem("milk", 5.0)
  g:addItem(milk, market)

  -- In the update loop: check before processing deliveries
  if not milk:isAlive() then
    lurek.log.warn("milk expired before delivery — customer unhappy", "economy")
  end
end

--@api-stub: LGraphItem:kill
-- Marks this item as dead so graph processing can remove or ignore it.
do
  -- kill() is useful when a player consumes, sells, or destroys an item manually.
  -- The graph will fire "itemDecay" on the next step for killed items.
  local g = lurek.graph.newGraph()
  local inventory = g:addNode("inventory", 20)
  local scroll = g:createItem("teleport_scroll", -1)
  g:addItem(scroll, inventory)

  -- Player uses the scroll: consume it
  scroll:kill()
  lurek.log.info("scroll consumed, alive=" .. tostring(scroll:isAlive()), "gameplay")
end

--@api-stub: LGraphItem:getPriority
-- Returns this item's routing or queue priority.
do
  -- Priority determines which items get routed first when edges or nodes are contested.
  -- Higher priority = processed first in queues and routing decisions.
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)
  local urgent_package = g:createItem("antidote", -1)
  g:addItem(urgent_package, depot)
  urgent_package:setPriority(10)

  lurek.log.debug("antidote priority: " .. urgent_package:getPriority()
    .. " (will be routed before normal items)", "logistics")
end

--@api-stub: LGraphItem:setPriority
-- Sets this item's routing or queue priority.
do
  -- Use priority to implement VIP lanes, emergency routing, or quest-critical deliveries.
  local g = lurek.graph.newGraph()
  local hub = g:addNode("hub", 32)
  local supplies = g:createItem("medical_supplies", -1)
  local luxury = g:createItem("silk", -1)
  g:addItem(supplies, hub)
  g:addItem(luxury, hub)

  -- Medical supplies get priority routing over luxury goods
  supplies:setPriority(10)
  luxury:setPriority(1)
  lurek.log.info("medical supplies will route before silk at bottlenecks", "logistics")
end

--@api-stub: LGraphItem:getPosition
-- Returns where this item is stored: a node, an edge plus progress, or no values when unplaced.
do
  -- getPosition() returns different values depending on item state:
  --   At a node: returns (node_handle, nil)
  --   In transit: returns (edge_handle, progress_0_to_1)
  --   Unplaced:  returns (nil, nil)
  local g = lurek.graph.newGraph()
  local mine = g:addNode("mine", 16)
  local smelter = g:addNode("smelter", 8)
  local belt = g:addEdge(mine, smelter, "conveyor")
  local ore = g:createItem("iron_ore", -1)
  g:addItem(ore, mine)

  local first, second = ore:getPosition()
  if second then
    -- Item is on an edge: second is the 0..1 progress along it
    lurek.log.info("ore in transit, progress=" .. string.format("%.0f%%", second * 100), "factory")
  elseif first then
    -- Item is parked at a node
    lurek.log.info("ore stored at node: " .. first:getType(), "factory")
  else
    -- Item is unplaced (just created, not yet added to graph)
    lurek.log.info("ore is floating (unplaced)", "factory")
  end
end

--@api-stub: LGraph:type
-- Returns the Lua-visible type name string for this graph item handle.
do
  local g = lurek.graph.newGraph()
  local node = g:addNode("store", 8)
  local item = g:createItem("gem", -1)
  g:addItem(item, node)

  -- Useful for generic serialization or debug printing
  lurek.log.debug("handle type: " .. item:type(), "debug")  -- prints "GraphItem"
end

--@api-stub: LGraph:typeOf
-- Returns true if this graph item handle matches the given type name string.
do
  local g = lurek.graph.newGraph()
  local node = g:addNode("store", 8)
  local item = g:createItem("gem", -1)
  g:addItem(item, node)

  -- typeOf checks against "GraphItem", "Object", or any parent type
  if item:typeOf("Object") then
    lurek.log.debug("item is a tracked Lurek engine object", "debug")
  end
end

-- =============================================================================
-- Edge Methods
-- =============================================================================

--@api-stub: LGraphNode:getType
-- Returns the edge type string used by routing and filters.
do
  -- Edge types let you differentiate transport mechanisms: roads, rails, pipes, portals.
  -- Routing and visualization logic can branch on edge type.
  local g = lurek.graph.newGraph()
  local town_a = g:addNode("town_a")
  local town_b = g:addNode("town_b")
  local road = g:addEdge(town_a, town_b, "highway")

  if road:getType() == "highway" then
    lurek.log.debug("draw a wide road sprite between towns", "render")
  end
end

--@api-stub: LGraphNode:setType
-- Sets the edge type string used by routing and filters.
do
  -- Upgrade a road mid-game: dirt path becomes a paved highway after construction.
  local g = lurek.graph.newGraph()
  local village = g:addNode("village")
  local castle = g:addNode("castle")
  local path = g:addEdge(village, castle, "dirt_path")

  -- Player completes road-building quest
  path:setType("stone_road")
  lurek.log.info("path upgraded to: " .. path:getType(), "world")
end

--@api-stub: LGraphEdge:getFrom
-- Returns the source node for this edge.
do
  -- Use getFrom()/getTo() to inspect edge endpoints for rendering or pathfinding UI.
  local g = lurek.graph.newGraph()
  local barracks = g:addNode("barracks")
  local battlefield = g:addNode("battlefield")
  local march_route = g:addEdge(barracks, battlefield, "march")

  local origin = march_route:getFrom()
  lurek.log.info("troops depart from: " .. origin:getType(), "military")
end

--@api-stub: LGraphEdge:getTo
-- Returns the destination node for this edge.
do
  local g = lurek.graph.newGraph()
  local barracks = g:addNode("barracks")
  local battlefield = g:addNode("battlefield")
  local march_route = g:addEdge(barracks, battlefield, "march")

  local destination = march_route:getTo()
  lurek.log.info("troops arrive at: " .. destination:getType(), "military")
end

--@api-stub: LGraphNode:getCapacity
-- Returns this edge's maximum concurrent item capacity.
do
  -- Edge capacity limits how many items can be in-transit simultaneously.
  -- Use this for bandwidth-limited connections (narrow bridges, single-lane roads).
  local g = lurek.graph.newGraph()
  local dock = g:addNode("dock")
  local island = g:addNode("island")
  local ferry = g:addEdge(dock, island, "ferry")
  ferry:setCapacity(4)  -- ferry holds max 4 passengers at once

  lurek.log.info("ferry capacity: " .. ferry:getCapacity() .. " passengers", "transport")
end

--@api-stub: LGraphNode:setCapacity
-- Sets this edge's maximum concurrent item capacity.
do
  -- Upgrade capacity when the player builds a better bridge or buys a larger ship.
  local g = lurek.graph.newGraph()
  local port_a = g:addNode("port_a")
  local port_b = g:addNode("port_b")
  local ship_route = g:addEdge(port_a, port_b, "cargo_ship")

  -- Player upgrades from rowboat to galleon
  ship_route:setCapacity(20)
  lurek.log.info("cargo capacity upgraded to " .. ship_route:getCapacity(), "economy")
end

--@api-stub: LGraphEdge:getThroughput
-- Returns this edge's throughput value (items per second).
do
  -- Throughput controls the rate at which items are accepted onto the edge.
  -- High throughput = more items can enter per second.
  local g = lurek.graph.newGraph()
  local mine = g:addNode("mine")
  local smelter = g:addNode("smelter")
  local conveyor = g:addEdge(mine, smelter, "belt_mk2")
  conveyor:setThroughput(3.0)

  lurek.log.info("belt moves " .. conveyor:getThroughput() .. " items/sec", "factory")
end

--@api-stub: LGraphEdge:setThroughput
-- Sets this edge's throughput value.
do
  -- Adjust throughput for belt tier upgrades in a factory game.
  local g = lurek.graph.newGraph()
  local src = g:addNode("source")
  local dst = g:addNode("destination")
  local belt = g:addEdge(src, dst, "express_belt")

  -- Tier 3 express belt: 6 items per second
  belt:setThroughput(6.0)
end

--@api-stub: LGraphEdge:getTravelTime
-- Returns the travel time for items moving across this edge.
do
  -- Travel time determines how long items spend in-transit on this edge.
  -- Longer edges (visually) should have longer travel times for realism.
  local g = lurek.graph.newGraph()
  local city = g:addNode("city")
  local frontier = g:addNode("frontier")
  local caravan_route = g:addEdge(city, frontier, "caravan")
  caravan_route:setTravelTime(5.0)  -- 5 seconds to cross the desert

  lurek.log.info("caravan takes " .. caravan_route:getTravelTime() .. "s", "trade")
end

--@api-stub: LGraphEdge:setTravelTime
-- Sets the travel time for items moving across this edge.
do
  -- Reduce travel time when the player builds a shortcut or fast-travel portal.
  local g = lurek.graph.newGraph()
  local a = g:addNode("oasis")
  local b = g:addNode("temple")
  local desert_road = g:addEdge(a, b, "sand_path")

  -- Player discovers a hidden tunnel: travel time drops
  desert_road:setTravelTime(1.0)
end

--@api-stub: LGraphEdge:getWeight
-- Returns the pathfinding weight for this edge.
do
  -- Weight affects A* and shortest-path calculations.
  -- Higher weight = less preferred by pathfinding (toll roads, dangerous paths).
  local g = lurek.graph.newGraph()
  local safe_town = g:addNode("safe_town")
  local bandit_pass = g:addNode("bandit_pass")
  local risky_road = g:addEdge(safe_town, bandit_pass, "mountain_pass")
  risky_road:setWeight(10.0)

  lurek.log.debug("risky road weight=" .. risky_road:getWeight() .. " (pathfinder avoids it)", "ai")
end

--@api-stub: LGraphEdge:setWeight
-- Sets the pathfinding weight for this edge.
do
  -- Dynamic weight changes: increase weight when enemies are spotted on a route.
  local g = lurek.graph.newGraph()
  local village = g:addNode("village")
  local forest = g:addNode("forest")
  local trail = g:addEdge(village, forest, "trail")

  -- Scouts report wolves on the trail: increase cost
  trail:setWeight(15.0)
end

--@api-stub: LGraphEdge:getSpeedModifier
-- Returns this edge's speed modifier.
do
  -- Speed modifier scales item movement speed on this edge.
  -- 1.0 = normal, 2.0 = double speed, 0.5 = half speed.
  local g = lurek.graph.newGraph()
  local hilltop = g:addNode("hilltop")
  local valley = g:addNode("valley")
  local slope = g:addEdge(hilltop, valley, "downhill")
  slope:setSpeedModifier(1.5)  -- gravity helps: 50% faster downhill

  lurek.log.debug("downhill speed: " .. slope:getSpeedModifier() .. "x", "physics")
end

--@api-stub: LGraphEdge:setSpeedModifier
-- Sets this edge's speed modifier.
do
  -- Use speed modifiers for terrain effects: mud slows, ice slides, wind boosts.
  local g = lurek.graph.newGraph()
  local swamp_a = g:addNode("swamp_entrance")
  local swamp_b = g:addNode("swamp_exit")
  local mud_path = g:addEdge(swamp_a, swamp_b, "mud")

  -- Mud terrain halves movement speed
  mud_path:setSpeedModifier(0.5)
end

--@api-stub: LGraphEdge:getCooldown
-- Returns this edge's cooldown timer value.
do
  -- Cooldown prevents rapid repeated use of an edge. Good for:
  -- catapults, teleporters, one-shot bridges, or rate-limited gates.
  local g = lurek.graph.newGraph()
  local tower = g:addNode("tower")
  local target = g:addNode("target_zone")
  local catapult = g:addEdge(tower, target, "catapult")
  catapult:setCooldown(3.0)  -- fires once every 3 seconds

  lurek.log.debug("catapult cooldown: " .. catapult:getCooldown() .. "s", "siege")
end

--@api-stub: LGraphEdge:setCooldown
-- Sets this edge's cooldown timer value.
do
  -- Set cooldown to 0 to remove the restriction (instant reuse).
  local g = lurek.graph.newGraph()
  local portal_in = g:addNode("portal_in")
  local portal_out = g:addNode("portal_out")
  local warp = g:addEdge(portal_in, portal_out, "warp_gate")

  -- Warp gate recharges in 10 seconds between uses
  warp:setCooldown(10.0)
end

--@api-stub: LGraphEdge:isOnCooldown
-- Returns true if this edge is currently on cooldown.
do
  -- Check before attempting to send items: if on cooldown, items must wait.
  local g = lurek.graph.newGraph()
  local launcher = g:addNode("launcher")
  local landing = g:addNode("landing_pad")
  local cannon = g:addEdge(launcher, landing, "space_cannon")
  cannon:setCooldown(5.0)

  if cannon:isOnCooldown() then
    lurek.log.info("cannon recharging, please wait...", "ui")
  else
    lurek.log.info("cannon ready to fire!", "ui")
  end
end

--@api-stub: LGraphEdge:isBidirectional
-- Returns whether this edge allows travel in both directions.
do
  -- By default edges are one-directional (from -> to).
  -- Bidirectional edges model two-way roads or reversible conveyor belts.
  local g = lurek.graph.newGraph()
  local market = g:addNode("market")
  local farm = g:addNode("farm")
  local road = g:addEdge(market, farm, "country_road")
  road:setBidirectional(true)

  if road:isBidirectional() then
    lurek.log.debug("road accepts traffic in both directions", "world")
  end
end

--@api-stub: LGraphEdge:setBidirectional
-- Sets whether this edge allows travel in both directions.
do
  -- Make a one-way street during a festival event, then restore it later.
  local g = lurek.graph.newGraph()
  local plaza = g:addNode("plaza")
  local temple = g:addNode("temple")
  local avenue = g:addEdge(plaza, temple, "main_avenue")

  -- During the parade: one-way only
  avenue:setBidirectional(false)
end

--@api-stub: LGraphNode:isActive
-- Returns whether this edge is active for routing and simulation.
do
  -- Inactive edges are invisible to pathfinding and simulation.
  -- Items cannot enter inactive edges; existing items finish their transit.
  local g = lurek.graph.newGraph()
  local north = g:addNode("north_gate")
  local south = g:addNode("south_gate")
  local drawbridge = g:addEdge(north, south, "drawbridge")

  if drawbridge:isActive() then
    lurek.log.info("drawbridge is down, trade flows freely", "world")
  end
end

--@api-stub: LGraphNode:setActive
-- Enables or disables this edge for routing and simulation.
do
  -- Disable edges to simulate broken infrastructure, locked doors, or power outages.
  local g = lurek.graph.newGraph()
  local generator = g:addNode("generator")
  local factory = g:addNode("factory")
  local power_line = g:addEdge(generator, factory, "cable")

  -- Sabotage event: power line cut!
  power_line:setActive(false)
  lurek.log.warn("power line severed — factory offline", "event")
end

--@api-stub: LGraphEdge:getItemsInTransit
-- Returns graph items currently traveling along this edge.
do
  -- Use this to render items moving on conveyor belts or to count traffic.
  local g = lurek.graph.newGraph()
  local mine = g:addNode("mine", 32)
  local refinery = g:addNode("refinery", 16)
  local pipeline = g:addEdge(mine, refinery, "pipe")

  local in_transit = pipeline:getItemsInTransit()
  lurek.log.debug(#in_transit .. " items currently in the pipeline", "factory")
  for _, item in ipairs(in_transit) do
    lurek.log.debug("  carrying: " .. item:getType(), "factory")
  end
end

--@api-stub: LGraphEdge:addAllowedType
-- Allows an item type to traverse this edge (creates a whitelist filter).
do
  -- By default, all item types can use any edge. Once you call addAllowedType,
  -- only explicitly allowed types may enter. Use this for typed pipes or filtered belts.
  local g = lurek.graph.newGraph()
  local oil_well = g:addNode("oil_well")
  local refinery = g:addNode("refinery")
  local oil_pipe = g:addEdge(oil_well, refinery, "oil_pipe")

  -- Only crude oil and natural gas may flow through this pipe
  oil_pipe:addAllowedType("crude_oil")
  oil_pipe:addAllowedType("natural_gas")
  lurek.log.info("pipe accepts: crude_oil, natural_gas", "factory")
end

--@api-stub: LGraphEdge:removeAllowedType
-- Removes an item type from this edge's allow-list.
do
  -- Remove a type when contamination makes the pipe unsafe for that substance.
  local g = lurek.graph.newGraph()
  local tank = g:addNode("tank")
  local mixer = g:addNode("mixer")
  local pipe = g:addEdge(tank, mixer, "chemical_pipe")
  pipe:addAllowedType("acid")
  pipe:addAllowedType("water")

  -- Pipe corroded: no longer safe for acid
  pipe:removeAllowedType("acid")
end

--@api-stub: LGraphEdge:clearAllowedTypes
-- Clears this edge's item type allow-list (returns to permissive mode).
do
  -- Clear the filter to make the edge accept any item type again.
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local belt = g:addEdge(a, b, "universal_belt")
  belt:addAllowedType("iron")

  -- Upgrade: belt now handles everything
  belt:clearAllowedTypes()
  lurek.log.info("belt filter cleared — accepts all items", "factory")
end

--@api-stub: LGraphEdge:isItemTypeAllowed
-- Returns whether an item type may traverse this edge.
do
  -- Check before manually routing items to avoid rejected deliveries.
  local g = lurek.graph.newGraph()
  local src = g:addNode("source")
  local dst = g:addNode("destination")
  local filtered_belt = g:addEdge(src, dst, "ore_belt")
  filtered_belt:addAllowedType("iron_ore")

  if not filtered_belt:isItemTypeAllowed("copper_ore") then
    lurek.log.warn("copper ore rejected by ore belt — rerouting", "logistics")
  end
end

--@api-stub: LGraph:type
-- Returns the Lua-visible type name string for this edge handle.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local edge = g:addEdge(a, b, "link")

  -- Always returns "LGraphEdge" — useful for type-checking in generic code
  lurek.log.debug("edge handle type: " .. edge:type(), "debug")
end

--@api-stub: LGraph:typeOf
-- Returns true if this edge handle matches the given type name string.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local edge = g:addEdge(a, b, "link")

  -- Matches "GraphEdge", "LGraphEdge", or "Object"
  if edge:typeOf("GraphEdge") then
    lurek.log.debug("confirmed: this is a graph edge", "debug")
  end
end

-- =============================================================================
-- Node Methods
-- =============================================================================

--@api-stub: LGraphNode:getType
-- Returns this node's type string.
do
  -- Node types categorize locations: mines, factories, warehouses, markets, etc.
  -- Use them for rendering decisions and gameplay logic.
  local g = lurek.graph.newGraph()
  local forge = g:addNode("blacksmith", 8)

  if forge:getType() == "blacksmith" then
    lurek.log.debug("draw anvil icon on minimap", "render")
  end
end

--@api-stub: LGraphNode:setType
-- Sets this node's type string.
do
  -- Upgrade buildings by changing their type.
  local g = lurek.graph.newGraph()
  local workshop = g:addNode("workshop", 8)

  -- Player upgrades workshop to factory
  workshop:setType("factory")
  lurek.log.info("building upgraded to: " .. workshop:getType(), "build")
end

--@api-stub: LGraphNode:getCapacity
-- Returns this node's item capacity.
do
  -- Capacity limits how many items a node can hold simultaneously.
  -- -1 means unlimited capacity (infinite storage).
  local g = lurek.graph.newGraph()
  local silo = g:addNode("grain_silo", 200)

  lurek.log.info("silo can hold " .. silo:getCapacity() .. " items", "economy")
end

--@api-stub: LGraphNode:setCapacity
-- Sets this node's item capacity.
do
  -- Increase capacity when the player upgrades storage buildings.
  local g = lurek.graph.newGraph()
  local warehouse = g:addNode("warehouse", 50)

  -- Level 2 warehouse upgrade doubles capacity
  warehouse:setCapacity(100)
  lurek.log.info("warehouse expanded to " .. warehouse:getCapacity(), "build")
end

--@api-stub: LGraph:getItemCount
-- Returns the number of items currently stored on this node.
do
  -- Use to display inventory counts in the UI or detect empty/full states.
  local g = lurek.graph.newGraph()
  local armory = g:addNode("armory", 20)
  g:addItem(g:createItem("sword", -1), armory)
  g:addItem(g:createItem("shield", -1), armory)

  lurek.log.info("armory contains " .. armory:getItemCount() .. " items", "inventory")
end

--@api-stub: LGraphNode:isFull
-- Returns whether this node has reached its item capacity.
do
  -- Check isFull() before routing items to avoid overflow behavior.
  local g = lurek.graph.newGraph()
  local chest = g:addNode("chest", 2)
  g:addItem(g:createItem("gold_coin", -1), chest)
  g:addItem(g:createItem("gold_coin", -1), chest)

  if chest:isFull() then
    lurek.log.warn("chest is full! Find another storage location.", "ui")
  end
end

--@api-stub: LGraphNode:isActive
-- Returns whether this node is active for graph simulation.
do
  -- Inactive nodes are skipped by push/pull flow and simulation.
  -- Items already at inactive nodes remain but do not get processed.
  local g = lurek.graph.newGraph()
  local reactor = g:addNode("reactor", 8)

  if reactor:isActive() then
    lurek.log.info("reactor online — processing fuel", "factory")
  end
end

--@api-stub: LGraphNode:setActive
-- Enables or disables this node for graph simulation.
do
  -- Disable nodes for shutdown events, maintenance, or seasonal closures.
  local g = lurek.graph.newGraph()
  local farm = g:addNode("farm", 32)

  -- Winter: farm shuts down
  farm:setActive(false)
  lurek.log.info("farm closed for winter", "season")
end

--@api-stub: LGraphNode:getOverflowPolicy
-- Returns this node's overflow policy name.
do
  -- Overflow policy controls what happens when items arrive at a full node.
  -- Policies: "reject" (bounce back), "destroy" (delete item), "queue" (buffer).
  local g = lurek.graph.newGraph()
  local bin = g:addNode("recycling_bin", 4)
  bin:setOverflowPolicy("destroy")

  lurek.log.info("overflow policy: " .. bin:getOverflowPolicy(), "logistics")
end

--@api-stub: LGraphNode:setOverflowPolicy
-- Sets this node's overflow policy from a policy name.
do
  -- Choose policy based on game design:
  --   "reject" — item stays where it was (safe, nothing lost)
  --   "destroy" — item is deleted (harsh, simulates waste)
  --   "queue" — item goes into a queue for later processing
  local g = lurek.graph.newGraph()
  local incinerator = g:addNode("incinerator", 1)

  -- Incinerator destroys overflow (by design)
  incinerator:setOverflowPolicy("destroy")
end

--@api-stub: LGraphNode:getFlowMode
-- Returns this node's flow mode name.
do
  -- Flow mode controls whether the node pushes items out, pulls items in, or both.
  -- Modes: "push", "pull", "both", "none"
  local g = lurek.graph.newGraph()
  local pump = g:addNode("water_pump", 16)
  pump:setFlowMode("push")

  lurek.log.info("pump flow mode: " .. pump:getFlowMode(), "factory")
end

--@api-stub: LGraphNode:setFlowMode
-- Sets this node's flow mode from a mode name.
do
  -- "push" — node actively sends items to connected nodes via outgoing edges
  -- "pull" — node actively requests items from connected source nodes
  -- "both" — node does push AND pull
  -- "none" — passive storage; items must be moved manually via sendItem
  local g = lurek.graph.newGraph()
  local distributor = g:addNode("distributor", 64)

  -- Distributor actively pushes items to all connected consumers
  distributor:setFlowMode("push")
end

--@api-stub: LGraphNode:getPushRate
-- Returns this node's push rate (items per second pushed to outgoing edges).
do
  -- Push rate limits how fast a node emits items. Use for production speed.
  local g = lurek.graph.newGraph()
  local quarry = g:addNode("quarry", 100)
  quarry:setFlowMode("push")
  quarry:setPushRate(2.0)

  lurek.log.info("quarry pushes " .. quarry:getPushRate() .. " stones/sec", "factory")
end

--@api-stub: LGraphNode:setPushRate
-- Sets this node's push rate.
do
  -- Upgrade production speed when the player builds better machinery.
  local g = lurek.graph.newGraph()
  local sawmill = g:addNode("sawmill", 32)
  sawmill:setFlowMode("push")

  -- Tier 2 sawmill: faster output
  sawmill:setPushRate(4.0)
end

--@api-stub: LGraphNode:getPullRate
-- Returns this node's pull rate (items per second pulled from source nodes).
do
  -- Pull rate limits how fast a node consumes input materials.
  local g = lurek.graph.newGraph()
  local furnace = g:addNode("furnace", 8)
  furnace:setFlowMode("pull")
  furnace:setPullRate(1.5)

  lurek.log.info("furnace consumes " .. furnace:getPullRate() .. " ore/sec", "factory")
end

--@api-stub: LGraphNode:setPullRate
-- Sets this node's pull rate.
do
  -- Higher pull rate = faster consumption. Balance with supply to avoid starvation.
  local g = lurek.graph.newGraph()
  local assembler = g:addNode("assembler", 16)
  assembler:setFlowMode("pull")

  -- Fast assembler: needs steady input to avoid idle time
  assembler:setPullRate(3.0)
end

--@api-stub: LGraphNode:getPushFilter
-- Returns this node's optional push item-type filter.
do
  -- Push filter restricts which item types this node will push out.
  -- nil means "push everything"; a string means "push only this type".
  local g = lurek.graph.newGraph()
  local sorter = g:addNode("sorter", 32)
  sorter:setPushFilter("iron_ingot")

  local filter = sorter:getPushFilter()
  if filter then
    lurek.log.info("sorter only pushes: " .. filter, "factory")
  end
end

--@api-stub: LGraphNode:setPushFilter
-- Sets or clears this node's push item-type filter.
do
  -- Use push filters on splitter nodes to route different items to different outputs.
  local g = lurek.graph.newGraph()
  local splitter = g:addNode("splitter", 16)

  -- This splitter only pushes copper ingots (other items stay until pulled)
  splitter:setPushFilter("copper_ingot")
end

--@api-stub: LGraphNode:getPullFilter
-- Returns this node's optional pull item-type filter.
do
  -- Pull filter restricts which item types this node will pull from neighbors.
  local g = lurek.graph.newGraph()
  local smelter = g:addNode("smelter", 8)
  smelter:setPullFilter("iron_ore")

  local filter = smelter:getPullFilter()
  if filter then
    lurek.log.info("smelter only pulls: " .. filter, "factory")
  end
end

--@api-stub: LGraphNode:setPullFilter
-- Sets or clears this node's pull item-type filter.
do
  -- Set to nil to clear the filter and pull any available type.
  local g = lurek.graph.newGraph()
  local furnace = g:addNode("furnace", 8)

  -- Furnace specifically consumes coal (ignores other items at connected nodes)
  furnace:setPullFilter("coal")
end

--@api-stub: LGraphNode:getProcessTime
-- Returns the processing time used by this node's conversions.
do
  -- Process time determines how long a conversion takes (e.g., smelting duration).
  -- Items are held at the node during processing.
  local g = lurek.graph.newGraph()
  local kiln = g:addNode("kiln", 4)
  kiln:setProcessTime(3.0)

  lurek.log.info("kiln process time: " .. kiln:getProcessTime() .. "s per batch", "factory")
end

--@api-stub: LGraphNode:setProcessTime
-- Sets the processing time used by this node's conversions.
do
  -- Reduce process time for technology upgrades.
  local g = lurek.graph.newGraph()
  local refinery = g:addNode("refinery", 8)

  -- Advanced refinery: processes crude oil in 1.5 seconds
  refinery:setProcessTime(1.5)
end

--@api-stub: LGraphNode:isQueueEnabled
-- Returns whether this node's explicit queue is enabled.
do
  -- Queues provide FIFO ordering for items waiting to be processed.
  -- When enabled, items enter the queue instead of the main inventory.
  local g = lurek.graph.newGraph()
  local station = g:addNode("train_station", 8)
  station:setQueueEnabled(true)

  if station:isQueueEnabled() then
    lurek.log.info("station uses FIFO buffer for arrivals", "transport")
  end
end

--@api-stub: LGraphNode:setQueueEnabled
-- Enables or disables this node's explicit queue.
do
  -- Enable queues on processing nodes to maintain arrival order.
  local g = lurek.graph.newGraph()
  local customs = g:addNode("customs_office", 4)

  -- Customs processes packages in the order they arrive
  customs:setQueueEnabled(true)
end

--@api-stub: LGraphNode:getQueueCapacity
-- Returns this node's queue capacity.
do
  -- Queue capacity limits how many items can wait in the queue.
  -- Items beyond capacity follow the overflow policy.
  local g = lurek.graph.newGraph()
  local buffer = g:addNode("buffer_station", 8)
  buffer:setQueueEnabled(true)
  buffer:setQueueCapacity(32)

  lurek.log.info("buffer queue holds up to " .. buffer:getQueueCapacity() .. " items", "logistics")
end

--@api-stub: LGraphNode:setQueueCapacity
-- Sets this node's queue capacity.
do
  -- Expand queue when upgrading infrastructure.
  local g = lurek.graph.newGraph()
  local loading_dock = g:addNode("loading_dock", 16)
  loading_dock:setQueueEnabled(true)

  -- Dock expansion: larger waiting area
  loading_dock:setQueueCapacity(64)
end

--@api-stub: LGraphNode:getQueueSize
-- Returns the number of items currently queued at this node.
do
  -- Monitor queue size for congestion warnings or AI decisions.
  local g = lurek.graph.newGraph()
  local checkpoint = g:addNode("checkpoint", 4)
  checkpoint:setQueueEnabled(true)

  local backlog = checkpoint:getQueueSize()
  if backlog > 10 then
    lurek.log.warn("checkpoint backlog: " .. backlog .. " items waiting!", "alert")
  end
end

--@api-stub: LGraph:getItems
-- Returns item handles currently stored on this node.
do
  -- Iterate node inventory for display, auditing, or conditional logic.
  local g = lurek.graph.newGraph()
  local shop = g:addNode("shop", 16)
  g:addItem(g:createItem("health_potion", -1), shop)
  g:addItem(g:createItem("mana_potion", -1), shop)
  g:addItem(g:createItem("antidote", -1), shop)

  -- List shop inventory
  for _, item in ipairs(shop:getItems()) do
    lurek.log.info("  for sale: " .. item:getType(), "shop")
  end
end

--@api-stub: LGraph:getEdges
-- Returns edge handles connected to this node in the requested direction.
do
  -- Direction can be "in", "out", or "both" (default).
  -- Use this to inspect a node's connections for routing UI or graph analysis.
  local g = lurek.graph.newGraph()
  local hub = g:addNode("trading_hub")
  local north = g:addNode("north_city")
  local south = g:addNode("south_city")
  g:addEdge(hub, north, "road")
  g:addEdge(hub, south, "road")
  g:addEdge(north, hub, "road")  -- return road

  local outgoing = hub:getEdges("out")
  local incoming = hub:getEdges("in")
  lurek.log.info("hub: " .. #outgoing .. " outgoing, " .. #incoming .. " incoming roads", "world")
end

--@api-stub: LGraphNode:clearConversion
-- Removes a conversion rule by input item type.
do
  -- Use when a building loses a recipe (e.g., removed technology).
  local g = lurek.graph.newGraph()
  local foundry = g:addNode("foundry", 8)
  foundry:setConversion("iron_ore", "steel", 3, 1)

  -- Player resets the foundry recipe
  foundry:clearConversion("iron_ore")
end

--@api-stub: LGraphNode:clearAllConversions
-- Removes every conversion rule from this node.
do
  -- Reset all recipes when repurposing a building.
  local g = lurek.graph.newGraph()
  local multi_crafter = g:addNode("crafter", 16)
  multi_crafter:setConversion("wood", "plank", 2, 4)
  multi_crafter:setConversion("iron_ore", "ingot", 2, 1)

  -- Building converted to pure storage: remove all recipes
  multi_crafter:clearAllConversions()
end

--@api-stub: LGraphNode:addTag
-- Adds a tag to this node.
do
  -- Tags are free-form labels for grouping, filtering, or AI logic.
  -- A node can have multiple tags.
  local g = lurek.graph.newGraph()
  local fortress = g:addNode("fortress", 32)

  fortress:addTag("military")
  fortress:addTag("defended")
  fortress:addTag("capital")
  lurek.log.info("fortress tagged as military capital", "world")
end

--@api-stub: LGraphNode:removeTag
-- Removes a tag from this node.
do
  -- Remove tags when state changes (e.g., defenses fall).
  local g = lurek.graph.newGraph()
  local city = g:addNode("city", 64)
  city:addTag("defended")
  city:addTag("prosperous")

  -- City walls breached!
  city:removeTag("defended")
  lurek.log.info("city lost its defenses", "combat")
end

--@api-stub: LGraphNode:hasTag
-- Returns whether this node has a tag.
do
  -- Use hasTag for AI decisions: "should I attack this node?"
  local g = lurek.graph.newGraph()
  local outpost = g:addNode("outpost", 8)
  outpost:addTag("safe_zone")

  if outpost:hasTag("safe_zone") then
    lurek.log.info("AI will not spawn enemies near this outpost", "ai")
  end
end

--@api-stub: LGraphNode:clearTags
-- Removes every tag from this node.
do
  -- Reset tags when a location changes ownership or purpose.
  local g = lurek.graph.newGraph()
  local camp = g:addNode("camp", 8)
  camp:addTag("friendly")
  camp:addTag("supply_point")

  -- Camp captured by enemy: reset all associations
  camp:clearTags()
end

--@api-stub: LGraphNode:getTags
-- Returns all tags assigned to this node.
do
  -- Retrieve tags for serialization or UI display.
  local g = lurek.graph.newGraph()
  local base = g:addNode("player_base", 32)
  base:addTag("home")
  base:addTag("respawn_point")
  base:addTag("fast_travel")

  local tags = base:getTags()
  lurek.log.info("base has " .. #tags .. " tags: " .. table.concat(tags, ", "), "ui")
end

--@api-stub: LGraphNode:removeSupply
-- Removes supply entry for an item type from this node.
do
  -- Remove supply when a resource is exhausted or disabled.
  local g = lurek.graph.newGraph()
  local mine = g:addNode("gold_mine", 32)
  mine:addSupply("gold_ore", 500)

  -- Mine depleted
  mine:removeSupply("gold_ore")
  lurek.log.info("gold mine exhausted", "economy")
end

--@api-stub: LGraphNode:clearSupplies
-- Removes every supply entry from this node.
do
  -- Clear all supplies when a node is destroyed or captured.
  local g = lurek.graph.newGraph()
  local plantation = g:addNode("plantation", 64)
  plantation:addSupply("cotton", 200)
  plantation:addSupply("tobacco", 100)

  -- Fire destroys the plantation
  plantation:clearSupplies()
end

--@api-stub: LGraphNode:removeDemand
-- Removes demand entry for an item type from this node.
do
  -- Remove demand when a building stops needing a resource.
  local g = lurek.graph.newGraph()
  local tavern = g:addNode("tavern", 16)
  tavern:addDemand("ale", 20, 2)

  -- Tavern switches to wine-only menu
  tavern:removeDemand("ale")
end

--@api-stub: LGraphNode:clearDemands
-- Removes every demand entry from this node.
do
  -- Clear demands when a building is mothballed or changes purpose.
  local g = lurek.graph.newGraph()
  local barracks = g:addNode("barracks", 32)
  barracks:addDemand("food", 50, 1)
  barracks:addDemand("weapons", 20, 2)

  -- Peacetime: barracks shut down
  barracks:clearDemands()
end

--@api-stub: LGraphNode:enqueue
-- Adds an item handle to this node's explicit queue.
do
  -- Enqueue is the manual way to add items to the FIFO buffer.
  -- The simulation also auto-enqueues arriving items when queue is enabled.
  local g = lurek.graph.newGraph()
  local loading_bay = g:addNode("loading_bay", 8)
  loading_bay:setQueueEnabled(true)
  loading_bay:setQueueCapacity(10)

  local crate = g:createItem("supplies", -1)
  loading_bay:enqueue(crate)
  lurek.log.info("crate queued, queue size: " .. loading_bay:getQueueSize(), "logistics")
end

--@api-stub: LGraphNode:dequeue
-- Removes and returns the next item from this node's explicit queue.
do
  -- dequeue() returns the oldest item (FIFO order), or nil if empty.
  local g = lurek.graph.newGraph()
  local printer = g:addNode("3d_printer", 4)
  printer:setQueueEnabled(true)

  -- Queue up print jobs
  printer:enqueue(g:createItem("gear_model", -1))
  printer:enqueue(g:createItem("chassis_model", -1))

  -- Process next job
  local next_job = printer:dequeue()
  if next_job then
    lurek.log.info("now printing: " .. next_job:getType(), "factory")
  end
end

--@api-stub: LGraph:type
-- Returns the Lua-visible type name string for this node handle.
do
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)

  -- Always returns "LGraphNode"
  lurek.log.debug("node handle type: " .. depot:type(), "debug")
end

--@api-stub: LGraph:typeOf
-- Returns true if this node handle matches the given type name string.
do
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 16)

  -- Matches "GraphNode", "LGraphNode", or "Object"
  if depot:typeOf("GraphNode") then
    lurek.log.debug("confirmed: this is a graph node", "debug")
  end
end

-- =============================================================================
-- Graph Methods
-- =============================================================================

--@api-stub: LGraph:removeNode
-- Removes a node and all edges connected to it.
do
  -- Removing a node also removes all edges that reference it.
  -- Items at the removed node become unplaced.
  local g = lurek.graph.newGraph()
  local outpost = g:addNode("abandoned_outpost")
  local city = g:addNode("city")
  g:addEdge(outpost, city, "trail")

  -- Outpost destroyed: remove from graph
  g:removeNode(outpost)
  lurek.log.info("outpost removed, still exists? " .. tostring(g:hasNode(outpost)), "world")
end

--@api-stub: LGraph:hasNode
-- Returns whether a node handle still exists in this graph.
do
  -- Use after removal operations to verify cleanup.
  local g = lurek.graph.newGraph()
  local waypoint = g:addNode("checkpoint_alpha")

  if g:hasNode(waypoint) then
    lurek.log.info("checkpoint registered in navigation graph", "nav")
  end
end

--@api-stub: LGraph:getNodes
-- Returns all nodes in this graph.
do
  -- Iterate all nodes for rendering, saving, or analysis.
  local g = lurek.graph.newGraph()
  g:addNode("town_square")
  g:addNode("harbor")
  g:addNode("lighthouse")

  for _, node in ipairs(g:getNodes()) do
    lurek.log.info("location: " .. node:getType(), "map")
  end
end

--@api-stub: LGraph:getNodeCount
-- Returns the number of nodes in this graph.
do
  local g = lurek.graph.newGraph()
  g:addNode("alpha_base")
  g:addNode("beta_base")
  g:addNode("gamma_base")

  lurek.log.info("map has " .. g:getNodeCount() .. " bases", "strategy")
end

--@api-stub: LGraph:removeEdge
-- Removes an edge from this graph.
do
  -- Remove edges to model destroyed bridges, severed supply lines, etc.
  local g = lurek.graph.newGraph()
  local east = g:addNode("east_fort")
  local west = g:addNode("west_fort")
  local bridge = g:addEdge(east, west, "stone_bridge")

  -- Enemy destroys the bridge
  g:removeEdge(bridge)
  lurek.log.info("bridge destroyed, edge exists? " .. tostring(g:hasEdge(bridge)), "combat")
end

--@api-stub: LGraph:hasEdge
-- Returns whether an edge handle still exists in this graph.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("dock_a")
  local b = g:addNode("dock_b")
  local ferry_route = g:addEdge(a, b, "ferry")

  if g:hasEdge(ferry_route) then
    lurek.log.info("ferry route is operational", "transport")
  end
end

--@api-stub: LGraph:getEdges
-- Returns all edges in this graph.
do
  -- Iterate edges for rendering connections on a map.
  local g = lurek.graph.newGraph()
  local hq = g:addNode("headquarters")
  local outpost = g:addNode("outpost")
  g:addEdge(hq, outpost, "supply_line")

  for _, edge in ipairs(g:getEdges()) do
    lurek.log.info("route: " .. edge:getFrom():getType() .. " -> "
      .. edge:getTo():getType() .. " [" .. edge:getType() .. "]", "map")
  end
end

--@api-stub: LGraph:getEdgeCount
-- Returns the number of edges in this graph.
do
  local g = lurek.graph.newGraph()
  g:addEdge(g:addNode("hub"), g:addNode("spoke_1"), "rail")
  g:addEdge(g:addNode("hub2"), g:addNode("spoke_2"), "rail")

  lurek.log.info("rail network: " .. g:getEdgeCount() .. " connections", "transport")
end

--@api-stub: LGraph:removeItem
-- Removes an item from this graph.
do
  -- Remove items when they are consumed, sold, or destroyed.
  local g = lurek.graph.newGraph()
  local shop = g:addNode("shop", 16)
  local potion = g:createItem("healing_potion", -1)
  g:addItem(potion, shop)

  -- Player buys the potion: remove from shop graph
  g:removeItem(potion)
  lurek.log.info("potion sold, still in graph? " .. tostring(g:hasItem(potion)), "shop")
end

--@api-stub: LGraph:hasItem
-- Returns whether an item handle still exists in this graph.
do
  local g = lurek.graph.newGraph()
  local vault = g:addNode("vault", 4)
  local diamond = g:createItem("diamond", -1)
  g:addItem(diamond, vault)

  if g:hasItem(diamond) then
    lurek.log.info("diamond is safe in the vault", "security")
  end
end

--@api-stub: LGraph:getItems
-- Returns all items in this graph.
do
  -- Get a global view of all items for save/load or statistics.
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 32)
  g:addItem(g:createItem("iron", -1), depot)
  g:addItem(g:createItem("copper", -1), depot)
  g:addItem(g:createItem("gold", -1), depot)

  lurek.log.info("total items in logistics: " .. #g:getItems(), "stats")
end

--@api-stub: LGraph:getItemCount
-- Returns the number of items in this graph.
do
  local g = lurek.graph.newGraph()
  local store = g:addNode("store", 32)
  g:addItem(g:createItem("widget", -1), store)

  lurek.log.info("items tracked: " .. g:getItemCount(), "logistics")
end

--@api-stub: LGraph:update
-- Advances graph simulation by delta time and dispatches generated callbacks.
do
  -- Call update(dt) every frame to advance item movement, decay, push/pull flow,
  -- and conversions. This is the standard way to tick the graph in lurek.process().
  local g = lurek.graph.newGraph()
  local mine = g:addNode("mine", 32)
  mine:setFlowMode("push")
  mine:setPushRate(2.0)

  function lurek.process(dt)
    -- Advance the logistics simulation each frame
    g:update(dt)
  end
end

--@api-stub: LGraph:step
-- Performs one discrete graph simulation step and dispatches generated callbacks.
do
  -- step() is a single deterministic tick (no dt). Use for turn-based games
  -- or when you want exact frame-by-frame control over the simulation.
  local g = lurek.graph.newGraph()
  local hub = g:addNode("hub", 8)

  -- Turn-based: advance logistics once per player turn
  g:step()
  lurek.log.info("logistics step complete", "turn")
end

--@api-stub: LGraph:tickParallel
-- Advances graph simulation through the parallel update path.
do
  -- tickParallel(dt) is the high-performance path for large graphs.
  -- It processes nodes in parallel using Rust threads, then dispatches callbacks.
  -- Use for massive logistics networks (1000+ nodes).
  local g = lurek.graph.newGraph()
  local hub = g:addNode("central_hub", 64)

  function lurek.process(dt)
    -- Use parallel tick for large-scale factory simulations
    g:tickParallel(dt)
  end
end

--@api-stub: LGraph:getNeighbors
-- Returns neighbor nodes connected to a node.
do
  -- getNeighbors returns nodes directly reachable via outgoing edges.
  -- Useful for AI decision-making or fog-of-war reveal.
  local g = lurek.graph.newGraph()
  local capital = g:addNode("capital")
  local port = g:addNode("port")
  local mine = g:addNode("mountain_mine")
  g:addEdge(capital, port, "road")
  g:addEdge(capital, mine, "mountain_pass")

  local neighbors = g:getNeighbors(capital)
  lurek.log.info("capital connects to " .. #neighbors .. " locations", "map")
end

--@api-stub: LGraph:getComponents
-- Returns connected components as arrays of node handles.
do
  -- Disconnected components reveal isolated sub-networks.
  -- Use to detect if supply lines are broken or islands are unreachable.
  local g = lurek.graph.newGraph()
  local mainland = g:addNode("mainland")
  local coast = g:addNode("coast")
  g:addEdge(mainland, coast, "road")

  -- These two nodes form a separate island with no connection
  local island_a = g:addNode("island_north")
  local island_b = g:addNode("island_south")
  g:addEdge(island_a, island_b, "bridge")

  local components = g:getComponents()
  lurek.log.info("network has " .. #components .. " disconnected regions", "logistics")
end

--@api-stub: LGraph:subgraph
-- Creates a new graph containing a subset of nodes (and edges between them).
do
  -- Use subgraph to extract a local area for focused analysis or rendering.
  local g = lurek.graph.newGraph()
  local a = g:addNode("zone_a")
  local b = g:addNode("zone_b")
  local c = g:addNode("zone_c")
  g:addEdge(a, b, "path")
  g:addEdge(b, c, "path")
  g:addEdge(a, c, "shortcut")

  -- Extract just zones a and b for a local minimap view
  local local_map = g:subgraph({ a, b })
  lurek.log.info("local map: " .. local_map:getNodeCount() .. " nodes, "
    .. local_map:getEdgeCount() .. " edges", "minimap")
end

--@api-stub: LGraph:hasCycle
-- Returns whether this graph contains a cycle.
do
  -- Cycle detection is important for tech trees and quest dependencies:
  -- a cycle means a circular dependency (bug in game data).
  local g = lurek.graph.newGraph()
  local research_a = g:addNode("basic_tools")
  local research_b = g:addNode("metallurgy")
  local research_c = g:addNode("advanced_smelting")
  g:addEdge(research_a, research_b, "requires")
  g:addEdge(research_b, research_c, "requires")

  if g:hasCycle() then
    lurek.log.warn("tech tree has circular dependency!", "data")
  else
    lurek.log.info("tech tree is valid (no cycles)", "data")
  end
end

--@api-stub: LGraph:topologicalSort
-- Returns nodes in topological order when the graph is acyclic.
do
  -- Topological sort gives a valid processing/research order.
  -- Returns nil if the graph has a cycle (impossible to sort).
  local g = lurek.graph.newGraph()
  local gather = g:addNode("gather_herbs")
  local brew = g:addNode("brew_potion")
  local enchant = g:addNode("enchant_potion")
  g:addEdge(gather, brew, "requires")
  g:addEdge(brew, enchant, "requires")

  local order = g:topologicalSort()
  if order then
    lurek.log.info("crafting order (" .. #order .. " steps):", "craft")
    for i, node in ipairs(order) do
      lurek.log.info("  " .. i .. ". " .. node:getType(), "craft")
    end
  end
end

--@api-stub: LGraph:mst
-- Computes a minimum spanning tree using Kruskal and returns edge ids.
do
  -- MST finds the cheapest set of edges that connects all nodes.
  -- Use for optimal road-building, cable layout, or trade route planning.
  local g = lurek.graph.newGraph()
  local a = g:addNode("city_a")
  local b = g:addNode("city_b")
  local c = g:addNode("city_c")
  local e1 = g:addEdge(a, b, "road")
  e1:setWeight(5.0)
  local e2 = g:addEdge(b, c, "road")
  e2:setWeight(3.0)
  local e3 = g:addEdge(a, c, "road")
  e3:setWeight(7.0)

  local tree_edges = g:mst()
  lurek.log.info("MST uses " .. #tree_edges .. " edges (cheapest network)", "plan")
end

--@api-stub: LGraph:colorGraph
-- Computes graph coloring and returns color indices by node id.
do
  -- Graph coloring assigns colors so no two adjacent nodes share a color.
  -- Use for map coloring, scheduling, or register allocation.
  local g = lurek.graph.newGraph()
  local region_a = g:addNode("region_a")
  local region_b = g:addNode("region_b")
  local region_c = g:addNode("region_c")
  g:addEdge(region_a, region_b, "border")
  g:addEdge(region_b, region_c, "border")
  g:addEdge(region_a, region_c, "border")

  local colors = g:colorGraph()
  for node_id, color_idx in pairs(colors) do
    lurek.log.info("region " .. node_id .. " => color " .. color_idx, "render")
  end
end

--@api-stub: LGraph:isBipartite
-- Returns whether this graph is bipartite (can be split into two independent sets).
do
  -- A bipartite graph has no odd-length cycles. Useful for matching problems:
  -- workers-to-tasks, buyers-to-sellers, students-to-courses.
  local g = lurek.graph.newGraph()
  local worker_1 = g:addNode("worker_1")
  local worker_2 = g:addNode("worker_2")
  local task_a = g:addNode("task_a")
  local task_b = g:addNode("task_b")
  g:addEdge(worker_1, task_a, "can_do")
  g:addEdge(worker_2, task_b, "can_do")

  if g:isBipartite() then
    lurek.log.info("graph is bipartite — valid for matching algorithm", "ai")
  end
end

--@api-stub: LGraph:processDemand
-- Processes graph supply and demand once and dispatches generated callbacks.
do
  -- processDemand() matches supply nodes to demand nodes and creates items/routes.
  -- Call it periodically or after supply/demand changes.
  local g = lurek.graph.newGraph()
  local mine = g:addNode("mine", 100)
  mine:addSupply("iron_ore", 50)
  local factory = g:addNode("factory", 32)
  factory:addDemand("iron_ore", 20, 1)
  g:addEdge(mine, factory, "rail")

  -- Process: mine will attempt to fulfill factory's demand
  g:processDemand()
  lurek.log.info("supply-demand matching complete", "logistics")
end

--@api-stub: LGraph:getStats
-- Returns graph counts and aggregate supply-demand statistics.
do
  -- getStats() returns a table with: nodes, edges, items, activity, transit,
  -- demand, supply, and queue counts. Use for debug overlays or analytics.
  local g = lurek.graph.newGraph()
  local depot = g:addNode("depot", 32)
  g:addItem(g:createItem("cargo", -1), depot)

  local stats = g:getStats()
  lurek.log.info("graph stats: nodes=" .. stats.nodes
    .. " edges=" .. stats.edges
    .. " items=" .. stats.items, "debug")
end

--@api-stub: LGraph:type
-- Returns the Lua-visible type name string for this graph handle.
do
  local g = lurek.graph.newGraph()

  -- Returns "LGraph" — the Lua handle type name
  lurek.log.debug("graph type: " .. g:type(), "debug")
end

--@api-stub: LGraph:typeOf
-- Returns true if this graph handle matches the given type name string.
do
  local g = lurek.graph.newGraph()

  -- Matches "Graph", "LGraph", or "Object"
  if g:typeOf("Graph") then
    lurek.log.debug("confirmed: this is a graph handle", "debug")
  end
end

-- =============================================================================
-- Supply & Demand
-- =============================================================================

--@api-stub: LGraphNode:addDemand
-- Adds demand quantity and optional priority for an item type on this node.
do
  -- Demand tells the graph "this node needs X units of item_type".
  -- processDemand() will try to route items from supply nodes to fulfill it.
  -- Priority (optional, default 0) determines which demands get served first.
  local g = lurek.graph.newGraph()
  local hospital = g:addNode("hospital", 32)

  -- Hospital urgently needs medical supplies (high priority = 5)
  hospital:addDemand("medical_supplies", 100, 5)
  -- Also needs food but less urgently (priority = 1)
  hospital:addDemand("food", 50, 1)
  lurek.log.info("hospital demands registered", "logistics")
end

--@api-stub: LGraphNode:addSupply
-- Adds supply quantity for an item type on this node.
do
  -- Supply tells the graph "this node can provide X units of item_type".
  -- processDemand() pairs suppliers with demanders and routes items.
  local g = lurek.graph.newGraph()
  local farm = g:addNode("farm", 64)

  -- Farm produces wheat and eggs
  farm:addSupply("wheat", 200)
  farm:addSupply("eggs", 50)
  lurek.log.info("farm supply registered", "economy")
end

-- =============================================================================
-- Graph Construction & Pathfinding
-- =============================================================================

--@api-stub: LGraph:addEdge
-- Creates an edge between two nodes with an optional edge type.
do
  -- Edges are directed by default (from -> to). Use setBidirectional(true) for two-way.
  -- The optional third argument names the edge type for routing filters and rendering.
  local g = lurek.graph.newGraph()
  local castle = g:addNode("castle")
  local village = g:addNode("village")

  -- Create a trade route from castle to village
  local trade_route = g:addEdge(castle, village, "trade_road")
  trade_route:setTravelTime(2.0)
  trade_route:setCapacity(10)
  lurek.log.info("trade route established, edges: " .. g:getEdgeCount(), "world")
end

--@api-stub: LGraph:addItem
-- Places an item onto a node.
do
  -- addItem places a previously-created item at a specific node.
  -- The item becomes part of the graph simulation (affected by flow, decay, etc.)
  local g = lurek.graph.newGraph()
  local warehouse = g:addNode("warehouse", 32)
  local cargo = g:createItem("spices", -1)

  -- Place the cargo at the warehouse to begin its logistics journey
  g:addItem(cargo, warehouse)
  lurek.log.info("warehouse now holds " .. g:getItemCount() .. " items", "trade")
end

--@api-stub: LGraph:addNode
-- Creates a node with optional type and capacity.
do
  -- Nodes represent locations, buildings, or abstract processing points.
  -- Type (string) names the node; capacity (number) limits stored items (-1 = unlimited).
  local g = lurek.graph.newGraph()

  -- Create a mine with capacity for 200 ore
  local mine = g:addNode("gold_mine", 200)
  mine:setFlowMode("push")
  mine:setPushRate(3.0)

  lurek.log.info("mine created, capacity=" .. mine:getCapacity(), "build")
end

--@api-stub: LGraph:astar
-- Runs A* pathfinding between two nodes.
do
  -- astar() returns an array of node handles forming the shortest path,
  -- or nil if no path exists. Uses edge weights for cost calculation.
  local g = lurek.graph.newGraph()
  local start = g:addNode("player_pos")
  local mid = g:addNode("crossroads")
  local goal = g:addNode("treasure")
  local e1 = g:addEdge(start, mid, "road")
  e1:setWeight(2.0)
  local e2 = g:addEdge(mid, goal, "road")
  e2:setWeight(3.0)

  local path = g:astar(start, goal)
  if path then
    lurek.log.info("A* path found: " .. #path .. " nodes", "pathfind")
  else
    lurek.log.warn("no path to treasure!", "pathfind")
  end
end

--@api-stub: LGraph:createItem
-- Creates an unplaced graph item with optional type and decay time.
do
  -- createItem makes an item but does NOT place it in the graph yet.
  -- Use addItem(item, node) afterwards to place it at a node.
  -- decay_time: seconds until item expires. -1 = never decays.
  local g = lurek.graph.newGraph()

  -- Create a perishable item (spoils in 60 seconds)
  local fresh_fish = g:createItem("fish", 60.0)
  -- Create an immortal item (never decays)
  local gold_bar = g:createItem("gold", -1)

  lurek.log.info("fish alive=" .. tostring(fresh_fish:isAlive())
    .. ", gold alive=" .. tostring(gold_bar:isAlive()), "items")
end

--@api-stub: LGraph:findPath
-- Finds a path between two nodes with detailed result.
do
  -- findPath returns a table with: nodes (array), edges (array), and cost (number).
  -- More detailed than astar() which only returns node handles.
  local g = lurek.graph.newGraph()
  local town = g:addNode("town")
  local forest = g:addNode("forest")
  local cave = g:addNode("cave")
  g:addEdge(town, forest, "trail")
  g:addEdge(forest, cave, "hidden_path")

  local result = g:findPath(town, cave)
  if result then
    lurek.log.info("path found, cost: " .. tostring(result.cost), "nav")
  end
end

--@api-stub: LGraph:findPathForItem
-- Finds a path for a specific item while respecting item constraints (type filters).
do
  -- findPathForItem respects edge allowed-type filters: it only routes through
  -- edges that permit the item's type. Essential for typed logistics networks.
  local g = lurek.graph.newGraph()
  local refinery = g:addNode("refinery")
  local tank = g:addNode("fuel_tank")
  local pipe = g:addEdge(refinery, tank, "fuel_pipe")
  pipe:addAllowedType("fuel")  -- only fuel items may use this pipe

  local fuel = g:createItem("fuel", -1)
  local path = g:findPathForItem(fuel, refinery, tank)
  if path then
    lurek.log.info("fuel can reach the tank via pipe", "logistics")
  end
end

--@api-stub: LGraph:getDistance
-- Returns graph distance between two nodes when reachable.
do
  -- getDistance returns the weighted shortest-path distance, or nil if unreachable.
  -- Use for AI range checks ("is this target within striking distance?").
  local g = lurek.graph.newGraph()
  local guard = g:addNode("guard_post")
  local gate = g:addNode("city_gate")
  local throne = g:addNode("throne_room")
  local e1 = g:addEdge(guard, gate, "corridor")
  e1:setWeight(1.0)
  local e2 = g:addEdge(gate, throne, "hallway")
  e2:setWeight(2.0)

  local dist = g:getDistance(guard, throne)
  if dist then
    lurek.log.info("guard to throne distance: " .. dist, "ai")
  end
end

--@api-stub: LGraph:getEdgeBetween
-- Returns the edge connecting two nodes when one exists.
do
  -- Lookup a specific edge without iterating all edges.
  -- Returns nil if no direct edge exists between the two nodes.
  local g = lurek.graph.newGraph()
  local port_a = g:addNode("port_a")
  local port_b = g:addNode("port_b")
  g:addEdge(port_a, port_b, "shipping_lane")

  local lane = g:getEdgeBetween(port_a, port_b)
  if lane then
    lurek.log.info("shipping lane capacity: " .. lane:getCapacity(), "trade")
  end
end

--@api-stub: LGraph:getReachable
-- Returns nodes reachable from a start node within an optional maximum distance.
do
  -- Use getReachable for fog-of-war, influence spread, or "what can I reach in N steps?"
  -- max_dist is optional: omit it to get ALL reachable nodes regardless of distance.
  local g = lurek.graph.newGraph()
  local castle = g:addNode("castle")
  local farm = g:addNode("farm")
  local mine = g:addNode("distant_mine")
  local e1 = g:addEdge(castle, farm, "road")
  e1:setWeight(1.0)
  local e2 = g:addEdge(farm, mine, "mountain_trail")
  e2:setWeight(4.0)

  -- What can be reached within distance 3 from the castle?
  local nearby = g:getReachable(castle, 3.0)
  lurek.log.info("reachable within range 3: " .. #nearby .. " nodes", "strategy")
end

--@api-stub: LGraph:on
-- Registers a callback for a named graph event generated during simulation.
do
  -- Valid events: "itemEnter", "itemLeave", "itemDecay", "itemConvert",
  --   "itemLost", "edgeEnter", "edgeLeave", "demandFulfilled",
  --   "supplyDepleted", "itemQueued", "itemDequeued"
  -- Callbacks fire during update()/step()/tickParallel() when the event occurs.
  local g = lurek.graph.newGraph()

  -- React when an item arrives at a node
  g:on("itemEnter", function(item, node)
    lurek.log.info(item:getType() .. " arrived at " .. node:getType(), "event")
  end)

  -- React when an item decays (spoils)
  g:on("itemDecay", function(item)
    lurek.log.warn(item:getType() .. " has decayed!", "event")
  end)

  -- React when supply runs out
  g:on("supplyDepleted", function(node, item_type)
    lurek.log.warn(node:getType() .. " ran out of " .. tostring(item_type), "event")
  end)

  lurek.log.info("event listeners registered", "setup")
end

--@api-stub: LGraph:sendItem
-- Starts moving an item along an edge.
do
  -- sendItem manually pushes an item onto an edge for transit.
  -- Use this for direct control (instead of relying on push/pull flow).
  -- The item will travel for the edge's travelTime before arriving at the destination.
  local g = lurek.graph.newGraph()
  local dock = g:addNode("dock", 32)
  local island = g:addNode("island", 16)
  local ferry = g:addEdge(dock, island, "ferry_route")
  ferry:setTravelTime(3.0)

  local passenger = g:createItem("traveler", -1)
  g:addItem(passenger, dock)

  -- Manually dispatch the traveler onto the ferry
  g:sendItem(passenger, ferry)
  lurek.log.info("traveler boarding ferry (3s crossing)", "transport")
end

--@api-stub: LGraphNode:setConversion
-- Configures an item conversion rule on this node.
do
  -- Conversions transform input items into output items at this node.
  -- Parameters: input_type, output_type, input_count (optional, default 1),
  --             output_count (optional, default 1).
  -- The node's processTime determines how long each conversion takes.
  local g = lurek.graph.newGraph()
  local smelter = g:addNode("smelter", 16)
  smelter:setProcessTime(2.0)

  -- 2 iron ore -> 1 iron ingot (takes 2 seconds)
  smelter:setConversion("iron_ore", "iron_ingot", 2, 1)
  -- 1 gold ore -> 1 gold bar
  smelter:setConversion("gold_ore", "gold_bar", 1, 1)

  lurek.log.info("smelter recipes configured", "craft")
end

-- =============================================================================
-- LGraphEdge Methods (full handle API)
-- =============================================================================

--@api-stub: LGraphNode:getType
-- Returns the edge type string used by routing and filters.
do
  local g = lurek.graph.newGraph()
  local src = g:addNode("warehouse", 8)
  local dst = g:addNode("shop", 8)
  local delivery = g:addEdge(src, dst, "delivery_van")

  -- Use edge type to select rendering: van sprite, pipe sprite, rail sprite, etc.
  lurek.log.info("transport type: " .. delivery:getType(), "render")
end

--@api-stub: LGraphNode:setType
-- Sets the edge type string used by routing and filters.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("port_a", 8)
  local b = g:addNode("port_b", 8)
  local route = g:addEdge(a, b, "rowboat")

  -- Player upgrades transport
  route:setType("steamship")
  lurek.log.info("route upgraded to: " .. route:getType(), "upgrade")
end

--@api-stub: LGraphEdge:getFrom
-- Returns the source node for this edge.
do
  local g = lurek.graph.newGraph()
  local origin = g:addNode("origin_city", 8)
  local dest = g:addNode("destination", 8)
  local route = g:addEdge(origin, dest, "airmail")

  local from_node = route:getFrom()
  lurek.log.info("mail departs from: " .. from_node:getType(), "mail")
end

--@api-stub: LGraphEdge:getTo
-- Returns the destination node for this edge.
do
  local g = lurek.graph.newGraph()
  local origin = g:addNode("sender", 8)
  local dest = g:addNode("receiver", 8)
  local route = g:addEdge(origin, dest, "courier")

  local to_node = route:getTo()
  lurek.log.info("package arrives at: " .. to_node:getType(), "mail")
end

--@api-stub: LGraphNode:getCapacity
-- Returns this edge's maximum concurrent item capacity.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("station_a", 8)
  local b = g:addNode("station_b", 8)
  local rail = g:addEdge(a, b, "rail")
  rail:setCapacity(12)

  lurek.log.info("rail capacity: " .. rail:getCapacity() .. " cars", "transport")
end

--@api-stub: LGraphNode:setCapacity
-- Sets this edge's maximum concurrent item capacity.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("dock_a", 8)
  local b = g:addNode("dock_b", 8)
  local channel = g:addEdge(a, b, "shipping_channel")

  -- Widen the channel to allow more simultaneous ships
  channel:setCapacity(25)
  lurek.log.info("channel expanded to " .. channel:getCapacity(), "infra")
end

--@api-stub: LGraphEdge:getThroughput
-- Returns this edge's throughput value.
do
  local g = lurek.graph.newGraph()
  local pump = g:addNode("pump", 8)
  local tank = g:addNode("tank", 8)
  local pipe = g:addEdge(pump, tank, "water_pipe")
  pipe:setThroughput(5.0)

  lurek.log.info("pipe flow: " .. pipe:getThroughput() .. " liters/sec", "factory")
end

--@api-stub: LGraphEdge:setThroughput
-- Sets this edge's throughput value.
do
  local g = lurek.graph.newGraph()
  local well = g:addNode("well", 8)
  local cistern = g:addNode("cistern", 8)
  local aqueduct = g:addEdge(well, cistern, "aqueduct")

  -- High-capacity Roman aqueduct
  aqueduct:setThroughput(15.0)
  lurek.log.info("aqueduct throughput set to " .. aqueduct:getThroughput(), "infra")
end

--@api-stub: LGraphEdge:getTravelTime
-- Returns the travel time for items moving across this edge.
do
  local g = lurek.graph.newGraph()
  local city = g:addNode("city", 8)
  local outpost = g:addNode("outpost", 8)
  local caravan = g:addEdge(city, outpost, "desert_route")
  caravan:setTravelTime(8.0)

  lurek.log.info("caravan crossing: " .. caravan:getTravelTime() .. " seconds", "trade")
end

--@api-stub: LGraphEdge:setTravelTime
-- Sets the travel time for items moving across this edge.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("mountain_base", 8)
  local b = g:addNode("summit", 8)
  local climb = g:addEdge(a, b, "mountain_trail")

  -- Harsh terrain: slow crossing
  climb:setTravelTime(12.0)
  lurek.log.info("mountain crossing set to " .. climb:getTravelTime() .. "s", "world")
end

--@api-stub: LGraphEdge:getWeight
-- Returns the pathfinding weight for this edge.
do
  local g = lurek.graph.newGraph()
  local safe = g:addNode("safe_zone", 8)
  local danger = g:addNode("danger_zone", 8)
  local path = g:addEdge(safe, danger, "exposed_road")
  path:setWeight(8.0)

  lurek.log.info("exposed road weight: " .. path:getWeight() .. " (high cost)", "pathfind")
end

--@api-stub: LGraphEdge:setWeight
-- Sets the pathfinding weight for this edge.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("village", 8)
  local b = g:addNode("market", 8)
  local road = g:addEdge(a, b, "main_road")

  -- Freshly paved road: low weight = preferred by pathfinder
  road:setWeight(1.0)
  lurek.log.info("road weight: " .. road:getWeight(), "pathfind")
end

--@api-stub: LGraphEdge:getSpeedModifier
-- Returns this edge's speed modifier.
do
  local g = lurek.graph.newGraph()
  local top = g:addNode("hill_top", 8)
  local bottom = g:addNode("hill_bottom", 8)
  local slope = g:addEdge(top, bottom, "steep_slope")
  slope:setSpeedModifier(1.8)

  lurek.log.info("downhill speed: " .. slope:getSpeedModifier() .. "x normal", "physics")
end

--@api-stub: LGraphEdge:setSpeedModifier
-- Sets this edge's speed modifier.
do
  local g = lurek.graph.newGraph()
  local start = g:addNode("runway_start", 8)
  local liftoff = g:addNode("liftoff_point", 8)
  local runway = g:addEdge(start, liftoff, "runway")

  -- Catapult-assisted launch: items move 3x faster on this edge
  runway:setSpeedModifier(3.0)
  lurek.log.info("runway boost: " .. runway:getSpeedModifier() .. "x", "launch")
end

--@api-stub: LGraphEdge:getCooldown
-- Returns this edge's cooldown timer value.
do
  local g = lurek.graph.newGraph()
  local cannon = g:addNode("siege_cannon", 8)
  local target = g:addNode("enemy_wall", 8)
  local shot = g:addEdge(cannon, target, "cannonball_arc")
  shot:setCooldown(5.0)

  lurek.log.info("cannon reload time: " .. shot:getCooldown() .. "s", "siege")
end

--@api-stub: LGraphEdge:setCooldown
-- Sets this edge's cooldown timer value.
do
  local g = lurek.graph.newGraph()
  local mage = g:addNode("mage_tower", 8)
  local target = g:addNode("battlefield", 8)
  local spell_channel = g:addEdge(mage, target, "fireball_path")

  -- Mage needs 8 seconds to recharge between fireballs
  spell_channel:setCooldown(8.0)
  lurek.log.info("spell cooldown: " .. spell_channel:getCooldown() .. "s", "combat")
end

--@api-stub: LGraphEdge:isOnCooldown
-- Returns whether this edge is currently on cooldown.
do
  local g = lurek.graph.newGraph()
  local turret = g:addNode("turret", 8)
  local zone = g:addNode("kill_zone", 8)
  local fire_arc = g:addEdge(turret, zone, "bullet_stream")
  fire_arc:setCooldown(1.0)

  -- Check if turret can fire again
  lurek.log.info("turret on cooldown: " .. tostring(fire_arc:isOnCooldown()), "combat")
end

--@api-stub: LGraphEdge:isBidirectional
-- Returns whether this edge allows travel in both directions.
do
  local g = lurek.graph.newGraph()
  local town_a = g:addNode("town_a", 8)
  local town_b = g:addNode("town_b", 8)
  local highway = g:addEdge(town_a, town_b, "highway")
  highway:setBidirectional(true)

  lurek.log.info("highway two-way: " .. tostring(highway:isBidirectional()), "world")
end

--@api-stub: LGraphEdge:setBidirectional
-- Sets whether this edge allows travel in both directions.
do
  local g = lurek.graph.newGraph()
  local east = g:addNode("east_gate", 8)
  local west = g:addNode("west_gate", 8)
  local corridor = g:addEdge(east, west, "castle_corridor")

  -- One-way traffic during evacuation
  corridor:setBidirectional(false)
  lurek.log.info("corridor one-way: " .. tostring(not corridor:isBidirectional()), "event")
end

--@api-stub: LGraphNode:isActive
-- Returns whether this edge is active for routing and simulation.
do
  local g = lurek.graph.newGraph()
  local generator = g:addNode("power_plant", 8)
  local city = g:addNode("city_grid", 8)
  local power_line = g:addEdge(generator, city, "high_voltage")

  lurek.log.info("power line active: " .. tostring(power_line:isActive()), "infra")
end

--@api-stub: LGraphNode:setActive
-- Enables or disables this edge for routing and simulation.
do
  local g = lurek.graph.newGraph()
  local north = g:addNode("north_tower", 8)
  local south = g:addNode("south_tower", 8)
  local drawbridge = g:addEdge(north, south, "drawbridge")

  -- Raise the drawbridge: disable the edge
  drawbridge:setActive(false)
  lurek.log.info("drawbridge raised, active=" .. tostring(drawbridge:isActive()), "castle")
end

--@api-stub: LGraphEdge:getItemsInTransit
-- Returns graph items currently traveling along this edge.
do
  local g = lurek.graph.newGraph()
  local factory = g:addNode("factory", 8)
  local store = g:addNode("store", 8)
  local truck_route = g:addEdge(factory, store, "delivery")

  local on_road = truck_route:getItemsInTransit()
  lurek.log.info("deliveries in progress: " .. #on_road, "logistics")
end

--@api-stub: LGraphEdge:addAllowedType
-- Allows an item type to traverse this edge.
do
  local g = lurek.graph.newGraph()
  local reservoir = g:addNode("reservoir", 8)
  local treatment = g:addNode("treatment_plant", 8)
  local pipe = g:addEdge(reservoir, treatment, "water_main")

  -- Only clean water flows through this pipe
  pipe:addAllowedType("clean_water")
  lurek.log.info("water pipe filter set", "infra")
end

--@api-stub: LGraphEdge:removeAllowedType
-- Removes an item type from this edge's allow-list.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("chemical_plant", 8)
  local b = g:addNode("waste_depot", 8)
  local pipe = g:addEdge(a, b, "waste_pipe")
  pipe:addAllowedType("toxic_waste")
  pipe:addAllowedType("sludge")

  -- Regulation change: no more toxic waste through this pipe
  pipe:removeAllowedType("toxic_waste")
  lurek.log.info("toxic waste no longer allowed", "compliance")
end

--@api-stub: LGraphEdge:clearAllowedTypes
-- Clears this edge's item type allow-list.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("hub", 8)
  local b = g:addNode("depot", 8)
  local belt = g:addEdge(a, b, "universal_belt")
  belt:addAllowedType("only_iron")

  -- Remove all filters: belt accepts anything again
  belt:clearAllowedTypes()
  lurek.log.info("belt filter cleared", "factory")
end

--@api-stub: LGraphEdge:isItemTypeAllowed
-- Returns whether an item type may traverse this edge.
do
  local g = lurek.graph.newGraph()
  local src = g:addNode("gas_well", 8)
  local dst = g:addNode("processing", 8)
  local pipe = g:addEdge(src, dst, "gas_pipe")
  pipe:addAllowedType("natural_gas")

  -- Check before routing
  lurek.log.info("gas allowed: " .. tostring(pipe:isItemTypeAllowed("natural_gas")), "check")
  lurek.log.info("oil allowed: " .. tostring(pipe:isItemTypeAllowed("crude_oil")), "check")
end

--@api-stub: LGraph:type
-- Returns the Lua-visible type name for this graph edge handle.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a", 8)
  local b = g:addNode("b", 8)
  local edge = g:addEdge(a, b, "link")

  lurek.log.info("handle type: " .. edge:type(), "debug")
end

--@api-stub: LGraph:typeOf
-- Returns whether this graph edge handle matches a supported type name.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a", 8)
  local b = g:addNode("b", 8)
  local edge = g:addEdge(a, b, "link")

  lurek.log.info("is GraphEdge: " .. tostring(edge:typeOf("GraphEdge")), "debug")
  lurek.log.info("is Object: " .. tostring(edge:typeOf("Object")), "debug")
end

-- =============================================================================
-- LGraphNode Methods (full handle API)
-- =============================================================================

--@api-stub: LGraphNode:getType
-- Returns this node's type string.
do
  local g = lurek.graph.newGraph()
  local smithy = g:addNode("smithy", 12)

  lurek.log.info("node type: " .. smithy:getType(), "world")
end

--@api-stub: LGraphNode:setType
-- Sets this node's type string.
do
  local g = lurek.graph.newGraph()
  local building = g:addNode("hut", 4)

  -- Upgrade hut to stone house
  building:setType("stone_house")
  lurek.log.info("building upgraded to: " .. building:getType(), "build")
end

--@api-stub: LGraphNode:getCapacity
-- Returns this node's item capacity.
do
  local g = lurek.graph.newGraph()
  local granary = g:addNode("granary", 500)

  lurek.log.info("granary holds " .. granary:getCapacity() .. " bushels", "economy")
end

--@api-stub: LGraphNode:setCapacity
-- Sets this node's item capacity.
do
  local g = lurek.graph.newGraph()
  local barn = g:addNode("barn", 50)

  -- Player expands the barn
  barn:setCapacity(150)
  lurek.log.info("barn expanded to " .. barn:getCapacity(), "build")
end

--@api-stub: LGraph:getItemCount
-- Returns the number of items currently stored on this node.
do
  local g = lurek.graph.newGraph()
  local pantry = g:addNode("pantry", 32)
  g:addItem(g:createItem("bread", -1), pantry)
  g:addItem(g:createItem("cheese", -1), pantry)

  lurek.log.info("pantry contains " .. pantry:getItemCount() .. " items", "inventory")
end

--@api-stub: LGraphNode:isFull
-- Returns whether this node has reached its item capacity.
do
  local g = lurek.graph.newGraph()
  local locker = g:addNode("locker", 2)
  g:addItem(g:createItem("book", -1), locker)
  g:addItem(g:createItem("pen", -1), locker)

  lurek.log.info("locker full: " .. tostring(locker:isFull()), "inventory")
end

--@api-stub: LGraphNode:isActive
-- Returns whether this node is active for graph simulation.
do
  local g = lurek.graph.newGraph()
  local generator = g:addNode("wind_turbine", 8)

  lurek.log.info("turbine active: " .. tostring(generator:isActive()), "energy")
end

--@api-stub: LGraphNode:setActive
-- Enables or disables this node for graph simulation.
do
  local g = lurek.graph.newGraph()
  local solar_panel = g:addNode("solar_panel", 4)

  -- Night time: solar panel goes offline
  solar_panel:setActive(false)
  lurek.log.info("solar panel active: " .. tostring(solar_panel:isActive()), "energy")
end

--@api-stub: LGraphNode:getOverflowPolicy
-- Returns this node's overflow policy name.
do
  local g = lurek.graph.newGraph()
  local trash_bin = g:addNode("trash_bin", 10)
  trash_bin:setOverflowPolicy("destroy")

  lurek.log.info("overflow policy: " .. trash_bin:getOverflowPolicy(), "config")
end

--@api-stub: LGraphNode:setOverflowPolicy
-- Sets this node's overflow policy from a policy name.
do
  local g = lurek.graph.newGraph()
  local buffer = g:addNode("overflow_buffer", 5)

  -- When buffer is full, reject new items (sender keeps them)
  buffer:setOverflowPolicy("reject")
  lurek.log.info("policy set: " .. buffer:getOverflowPolicy(), "config")
end

--@api-stub: LGraphNode:getFlowMode
-- Returns this node's flow mode name.
do
  local g = lurek.graph.newGraph()
  local hub = g:addNode("distribution_hub", 64)
  hub:setFlowMode("both")

  lurek.log.info("hub flow mode: " .. hub:getFlowMode(), "logistics")
end

--@api-stub: LGraphNode:setFlowMode
-- Sets this node's flow mode from a mode name.
do
  local g = lurek.graph.newGraph()
  local consumer = g:addNode("consumer", 16)

  -- Consumer only pulls items from neighbors, never pushes
  consumer:setFlowMode("pull")
  lurek.log.info("consumer flow mode: " .. consumer:getFlowMode(), "logistics")
end

--@api-stub: LGraphNode:getPushRate
-- Returns this node's push rate.
do
  local g = lurek.graph.newGraph()
  local producer = g:addNode("assembly_line", 32)
  producer:setFlowMode("push")
  producer:setPushRate(4.0)

  lurek.log.info("assembly pushes " .. producer:getPushRate() .. " items/sec", "factory")
end

--@api-stub: LGraphNode:setPushRate
-- Sets this node's push rate.
do
  local g = lurek.graph.newGraph()
  local extractor = g:addNode("ore_extractor", 64)
  extractor:setFlowMode("push")

  -- Tier 3 extractor: high output rate
  extractor:setPushRate(8.0)
  lurek.log.info("extractor push rate: " .. extractor:getPushRate(), "factory")
end

--@api-stub: LGraphNode:getPullRate
-- Returns this node's pull rate.
do
  local g = lurek.graph.newGraph()
  local crafter = g:addNode("workbench", 16)
  crafter:setFlowMode("pull")
  crafter:setPullRate(2.0)

  lurek.log.info("workbench pulls " .. crafter:getPullRate() .. " items/sec", "factory")
end

--@api-stub: LGraphNode:setPullRate
-- Sets this node's pull rate.
do
  local g = lurek.graph.newGraph()
  local centrifuge = g:addNode("centrifuge", 8)
  centrifuge:setFlowMode("pull")

  -- Fast centrifuge: high consumption rate
  centrifuge:setPullRate(6.0)
  lurek.log.info("centrifuge pull rate: " .. centrifuge:getPullRate(), "factory")
end

--@api-stub: LGraphNode:getPushFilter
-- Returns this node's optional push item-type filter.
do
  local g = lurek.graph.newGraph()
  local sorter = g:addNode("item_sorter", 16)
  sorter:setPushFilter("electronics")

  lurek.log.info("sorter pushes: " .. tostring(sorter:getPushFilter()), "factory")
end

--@api-stub: LGraphNode:setPushFilter
-- Sets or clears this node's push item-type filter.
do
  local g = lurek.graph.newGraph()
  local output_valve = g:addNode("valve", 8)

  -- Valve only outputs steam (filters out water)
  output_valve:setPushFilter("steam")
  lurek.log.info("valve push filter: " .. tostring(output_valve:getPushFilter()), "factory")
end

--@api-stub: LGraphNode:getPullFilter
-- Returns this node's optional pull item-type filter.
do
  local g = lurek.graph.newGraph()
  local reactor = g:addNode("nuclear_reactor", 4)
  reactor:setPullFilter("uranium_rod")

  lurek.log.info("reactor pulls: " .. tostring(reactor:getPullFilter()), "energy")
end

--@api-stub: LGraphNode:setPullFilter
-- Sets or clears this node's pull item-type filter.
do
  local g = lurek.graph.newGraph()
  local boiler = g:addNode("boiler", 8)

  -- Boiler only accepts coal as fuel
  boiler:setPullFilter("coal")
  lurek.log.info("boiler pull filter: " .. tostring(boiler:getPullFilter()), "energy")
end

--@api-stub: LGraphNode:getProcessTime
-- Returns the processing time used by this node's conversions.
do
  local g = lurek.graph.newGraph()
  local oven = g:addNode("bakery_oven", 4)
  oven:setProcessTime(5.0)

  lurek.log.info("baking time: " .. oven:getProcessTime() .. "s per loaf", "craft")
end

--@api-stub: LGraphNode:setProcessTime
-- Sets the processing time used by this node's conversions.
do
  local g = lurek.graph.newGraph()
  local press = g:addNode("printing_press", 8)

  -- Fast printing: 0.5 seconds per page
  press:setProcessTime(0.5)
  lurek.log.info("print time: " .. press:getProcessTime() .. "s", "craft")
end

--@api-stub: LGraphNode:isQueueEnabled
-- Returns whether this node's explicit queue is enabled.
do
  local g = lurek.graph.newGraph()
  local ticket_booth = g:addNode("ticket_booth", 4)
  ticket_booth:setQueueEnabled(true)

  lurek.log.info("queue enabled: " .. tostring(ticket_booth:isQueueEnabled()), "service")
end

--@api-stub: LGraphNode:setQueueEnabled
-- Enables or disables this node's explicit queue.
do
  local g = lurek.graph.newGraph()
  local checkout = g:addNode("checkout_counter", 2)

  -- Enable queue: customers line up in order
  checkout:setQueueEnabled(true)
  lurek.log.info("checkout queue: " .. tostring(checkout:isQueueEnabled()), "service")
end

--@api-stub: LGraphNode:getQueueCapacity
-- Returns this node's queue capacity.
do
  local g = lurek.graph.newGraph()
  local runway = g:addNode("airport_runway", 2)
  runway:setQueueEnabled(true)
  runway:setQueueCapacity(5)

  lurek.log.info("runway queue holds " .. runway:getQueueCapacity() .. " planes", "transport")
end

--@api-stub: LGraphNode:setQueueCapacity
-- Sets this node's queue capacity.
do
  local g = lurek.graph.newGraph()
  local platform = g:addNode("train_platform", 4)
  platform:setQueueEnabled(true)

  -- Expand platform to hold more waiting trains
  platform:setQueueCapacity(8)
  lurek.log.info("platform queue: " .. platform:getQueueCapacity(), "transport")
end

--@api-stub: LGraphNode:getQueueSize
-- Returns the number of item ids currently queued at this node.
do
  local g = lurek.graph.newGraph()
  local printer = g:addNode("laser_printer", 4)
  printer:setQueueEnabled(true)

  lurek.log.info("print queue: " .. printer:getQueueSize() .. " jobs", "office")
end

--@api-stub: LGraph:getItems
-- Returns item handles currently stored on this node.
do
  local g = lurek.graph.newGraph()
  local fridge = g:addNode("fridge", 10)
  g:addItem(g:createItem("milk", 60.0), fridge)
  g:addItem(g:createItem("butter", -1), fridge)

  local contents = fridge:getItems()
  lurek.log.info("fridge has " .. #contents .. " items", "kitchen")
end

--@api-stub: LGraph:getEdges
-- Returns edge handles connected to this node in the requested direction.
do
  local g = lurek.graph.newGraph()
  local junction = g:addNode("rail_junction", 8)
  local north = g:addNode("north_station", 8)
  local south = g:addNode("south_station", 8)
  g:addEdge(junction, north, "rail")
  g:addEdge(junction, south, "rail")
  g:addEdge(south, junction, "rail")

  -- Get only outgoing edges
  local out_edges = junction:getEdges("out")
  lurek.log.info("junction has " .. #out_edges .. " outgoing tracks", "transport")
end

--@api-stub: LGraphNode:setConversion
-- Configures an item conversion rule on this node.
do
  local g = lurek.graph.newGraph()
  local brewery = g:addNode("brewery", 16)
  brewery:setProcessTime(4.0)

  -- 3 wheat + process time -> 1 ale
  brewery:setConversion("wheat", "ale", 3, 1)
  lurek.log.info("brewery recipe: 3 wheat -> 1 ale", "craft")
end

--@api-stub: LGraphNode:clearConversion
-- Removes a conversion rule by input item type.
do
  local g = lurek.graph.newGraph()
  local kiln = g:addNode("kiln", 8)
  kiln:setConversion("clay", "brick", 2, 4)

  -- Remove the clay recipe (kiln repurposed)
  kiln:clearConversion("clay")
  lurek.log.info("clay recipe removed from kiln", "craft")
end

--@api-stub: LGraphNode:clearAllConversions
-- Removes every conversion rule from this node.
do
  local g = lurek.graph.newGraph()
  local workshop = g:addNode("workshop", 16)
  workshop:setConversion("wood", "plank", 1, 4)
  workshop:setConversion("plank", "furniture", 4, 1)

  -- Reset workshop: remove all recipes
  workshop:clearAllConversions()
  lurek.log.info("workshop recipes cleared", "craft")
end

--@api-stub: LGraphNode:addTag
-- Adds a tag to this node.
do
  local g = lurek.graph.newGraph()
  local castle = g:addNode("castle", 100)

  castle:addTag("fortified")
  castle:addTag("capital")
  lurek.log.info("castle tagged, has fortified: " .. tostring(castle:hasTag("fortified")), "world")
end

--@api-stub: LGraphNode:removeTag
-- Removes a tag from this node.
do
  local g = lurek.graph.newGraph()
  local outpost = g:addNode("outpost", 8)
  outpost:addTag("manned")
  outpost:addTag("supply_cached")

  -- Guards withdraw
  outpost:removeTag("manned")
  lurek.log.info("outpost manned: " .. tostring(outpost:hasTag("manned")), "military")
end

--@api-stub: LGraphNode:hasTag
-- Returns whether this node has a tag.
do
  local g = lurek.graph.newGraph()
  local village = g:addNode("village", 32)
  village:addTag("peaceful")

  if village:hasTag("peaceful") then
    lurek.log.info("no combat encounters near this village", "ai")
  end
end

--@api-stub: LGraphNode:clearTags
-- Removes every tag from this node.
do
  local g = lurek.graph.newGraph()
  local camp = g:addNode("bandit_camp", 8)
  camp:addTag("hostile")
  camp:addTag("hidden")

  -- Camp cleared by player: reset all tags
  camp:clearTags()
  lurek.log.info("camp tags cleared, count: " .. #camp:getTags(), "quest")
end

--@api-stub: LGraphNode:getTags
-- Returns all tags assigned to this node.
do
  local g = lurek.graph.newGraph()
  local shrine = g:addNode("shrine", 4)
  shrine:addTag("holy")
  shrine:addTag("healing")
  shrine:addTag("fast_travel")

  local tags = shrine:getTags()
  lurek.log.info("shrine tags (" .. #tags .. "): " .. table.concat(tags, ", "), "world")
end

--@api-stub: LGraphNode:addSupply
-- Adds supply quantity for an item type on this node.
do
  local g = lurek.graph.newGraph()
  local iron_mine = g:addNode("iron_mine", 200)

  -- This mine can supply 500 units of iron ore to the network
  iron_mine:addSupply("iron_ore", 500)
  lurek.log.info("iron mine supply registered", "economy")
end

--@api-stub: LGraphNode:removeSupply
-- Removes supply entry for an item type from this node.
do
  local g = lurek.graph.newGraph()
  local quarry = g:addNode("quarry", 100)
  quarry:addSupply("marble", 300)

  -- Quarry exhausted its marble vein
  quarry:removeSupply("marble")
  lurek.log.info("marble supply removed", "economy")
end

--@api-stub: LGraphNode:clearSupplies
-- Removes every supply entry from this node.
do
  local g = lurek.graph.newGraph()
  local harbor = g:addNode("harbor", 64)
  harbor:addSupply("fish", 100)
  harbor:addSupply("salt", 50)

  -- Harbor blockaded: all supplies cut off
  harbor:clearSupplies()
  lurek.log.info("harbor supplies cleared", "war")
end

--@api-stub: LGraphNode:addDemand
-- Adds demand quantity and optional priority for an item type on this node.
do
  local g = lurek.graph.newGraph()
  local army_camp = g:addNode("army_camp", 64)

  -- Army needs weapons urgently (priority 5) and food normally (priority 2)
  army_camp:addDemand("weapons", 100, 5)
  army_camp:addDemand("food", 200, 2)
  lurek.log.info("army demands registered", "military")
end

--@api-stub: LGraphNode:removeDemand
-- Removes demand entry for an item type from this node.
do
  local g = lurek.graph.newGraph()
  local workshop = g:addNode("workshop", 16)
  workshop:addDemand("leather", 30, 1)

  -- Workshop switches production: no longer needs leather
  workshop:removeDemand("leather")
  lurek.log.info("leather demand removed", "craft")
end

--@api-stub: LGraphNode:clearDemands
-- Removes every demand entry from this node.
do
  local g = lurek.graph.newGraph()
  local settlement = g:addNode("settlement", 32)
  settlement:addDemand("food", 50, 1)
  settlement:addDemand("tools", 20, 2)

  -- Settlement abandoned: clear all demands
  settlement:clearDemands()
  lurek.log.info("settlement demands cleared", "world")
end

--@api-stub: LGraphNode:enqueue
-- Adds an item handle to this node's explicit queue.
do
  local g = lurek.graph.newGraph()
  local assembly = g:addNode("assembly_station", 8)
  assembly:setQueueEnabled(true)
  assembly:setQueueCapacity(10)

  -- Queue up work orders
  assembly:enqueue(g:createItem("chassis", -1))
  assembly:enqueue(g:createItem("engine", -1))
  lurek.log.info("assembly queue: " .. assembly:getQueueSize() .. " items", "factory")
end

--@api-stub: LGraphNode:dequeue
-- Removes and returns the next item from this node's explicit queue.
do
  local g = lurek.graph.newGraph()
  local serve_counter = g:addNode("counter", 4)
  serve_counter:setQueueEnabled(true)
  serve_counter:enqueue(g:createItem("order_42", -1))
  serve_counter:enqueue(g:createItem("order_43", -1))

  -- Serve next customer
  local next_order = serve_counter:dequeue()
  if next_order then
    lurek.log.info("serving: " .. next_order:getType(), "service")
  end
end

--@api-stub: LGraph:type
-- Returns the Lua-visible type name for this graph node handle.
do
  local g = lurek.graph.newGraph()
  local node = g:addNode("waypoint", 4)

  lurek.log.info("node handle type: " .. node:type(), "debug")
end

--@api-stub: LGraph:typeOf
-- Returns whether this graph node handle matches a supported type name.
do
  local g = lurek.graph.newGraph()
  local node = g:addNode("marker", 4)

  lurek.log.info("is GraphNode: " .. tostring(node:typeOf("GraphNode")), "debug")
  lurek.log.info("is Object: " .. tostring(node:typeOf("Object")), "debug")
end

-- =============================================================================
-- Additional Graph Methods
-- =============================================================================

--@api-stub: LGraph:bfs
-- Performs a breadth-first search from a start node and returns nodes in visit order.
do
  -- BFS visits nodes level by level (closest first). Use for:
  -- influence spread, finding nearest resource, or flood-fill logic.
  -- NOTE: bfs() is on lurek.patterns.newGraph() (algorithmic graph), not lurek.graph.newGraph()
  local g = lurek.patterns.newGraph()
  local center = g:addNode("center")
  local ring1 = g:addNode("ring1")
  local ring2 = g:addNode("ring2")
  g:addEdge(center, ring1, 1.0, "path")
  g:addEdge(ring1, ring2, 1.0, "path")

  local visit_order = g:bfs(center)
  lurek.log.info("BFS visited " .. #visit_order .. " nodes", "algorithm")
end

--@api-stub: LGraph:clearAll
-- Removes all nodes and edges from this graph and resets it to an empty state.
do
  -- Use clearAll() to reset a graph for a new level or game restart.
  -- NOTE: clearAll() is on lurek.patterns.newGraph() (algorithmic graph)
  local g = lurek.patterns.newGraph()
  g:addNode("temp_a")
  g:addNode("temp_b")

  g:clearAll()
  lurek.log.info("graph cleared, nodes=" .. g:nodeCount(), "reset")
end

--@api-stub: LGraph:dfs
-- Performs a depth-first search from a start node and returns nodes in visit order.
do
  -- DFS explores as deep as possible before backtracking. Use for:
  -- maze solving, cycle detection, or topological ordering alternatives.
  -- NOTE: dfs() is on lurek.patterns.newGraph() (algorithmic graph)
  local g = lurek.patterns.newGraph()
  local root = g:addNode("dungeon_entrance")
  local hall = g:addNode("hallway")
  local chamber = g:addNode("treasure_chamber")
  g:addEdge(root, hall, 1.0, "corridor")
  g:addEdge(hall, chamber, 1.0, "door")

  local visit_order = g:dfs(root)
  lurek.log.info("DFS visited " .. #visit_order .. " rooms", "explore")
end

--@api-stub: LGraph:edgeCount
-- Returns the total number of edges currently in this graph.
do
  -- NOTE: edgeCount() is on lurek.patterns.newGraph() (algorithmic graph)
  local g = lurek.patterns.newGraph()
  local a = g:addNode("A")
  local b = g:addNode("B")
  g:addEdge(a, b, 1.0, "link")

  lurek.log.info("total edges: " .. g:edgeCount(), "stats")
end

--@api-stub: LGraph:getNodeValue
-- Returns the value stored at a node id in this graph.
do
  -- NOTE: getNodeValue() is on lurek.patterns.newGraph() (algorithmic graph)
  local g = lurek.patterns.newGraph()
  local city = g:addNode("metropolis")

  local val = g:getNodeValue(city)
  lurek.log.info("node value: " .. tostring(val), "data")
end

--@api-stub: LGraph:isConnected
-- Returns true if there is a path between two given nodes in this graph.
do
  -- isConnected(from, to) checks if there is any path from one node to another.
  -- NOTE: isConnected() is on lurek.patterns.newGraph() (algorithmic graph)
  local g = lurek.patterns.newGraph()
  local a = g:addNode("base_alpha")
  local b = g:addNode("base_beta")
  g:addEdge(a, b, 1.0, "supply_line")

  if g:isConnected(a, b) then
    lurek.log.info("all bases connected — supply network intact", "logistics")
  else
    lurek.log.warn("network broken! Some bases are isolated", "alert")
  end
end

--@api-stub: LGraph:neighbors
-- Returns a list of node ids directly connected to a given node in this graph.
do
  -- NOTE: neighbors() is on lurek.patterns.newGraph() (algorithmic graph)
  local g = lurek.patterns.newGraph()
  local hub = g:addNode("central_hub")
  local spoke1 = g:addNode("spoke_1")
  local spoke2 = g:addNode("spoke_2")
  g:addEdge(hub, spoke1, 1.0, "rail")
  g:addEdge(hub, spoke2, 1.0, "rail")

  local adjacent = g:neighbors(hub)
  lurek.log.info("hub connects to " .. #adjacent .. " neighbors", "nav")
end

--@api-stub: LGraph:nodeCount
-- Returns the total number of nodes currently in this graph.
do
  -- NOTE: nodeCount() is on lurek.patterns.newGraph() (algorithmic graph)
  local g = lurek.patterns.newGraph()
  g:addNode("checkpoint_1")
  g:addNode("checkpoint_2")
  g:addNode("checkpoint_3")

  lurek.log.info("total nodes: " .. g:nodeCount(), "stats")
end

print("content/examples/graph.lua")

-- =============================================================================
-- STUBS: 51 uncovered lurek.graph API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LGraph methods
-- -----------------------------------------------------------------------------

--@api-stub: LGraphItem:getType
-- Returns the item type string used by filters, conversions, supplies, and demands.
do
  -- getType returns the current type label (e.g., resource kind or product name).
  local g = lurek.graph.newGraph()
  local node = g:addNode("warehouse", 32)
  local item = g:createItem("iron_ore", -1)
  g:addItem(item, node)
  lurek.log.info("item type: " .. item:getType(), "graph")
end

--@api-stub: LGraphItem:setType
-- Changes the item type string used by graph routing and processing rules.
do
  -- setType renames the item — use it for crafting transformations.
  local g = lurek.graph.newGraph()
  local anvil = g:addNode("anvil", 8)
  local bar = g:createItem("iron_bar", -1)
  g:addItem(bar, anvil)
  bar:setType("steel_ingot")
  lurek.log.info("transformed to: " .. bar:getType(), "graph")
end

--@api-stub: LGraphItem:type
-- Returns the Lua-visible type name for this graph item handle.
do
  -- type() returns the engine type string for this userdata handle.
  local g = lurek.graph.newGraph()
  local node = g:addNode("depot", 4)
  local crate = g:createItem("crate", -1)
  g:addItem(crate, node)
  lurek.log.info("handle type: " .. crate:type(), "graph")
end

--@api-stub: LGraphItem:typeOf
-- Returns whether this graph item handle matches a supported type name.
do
  -- typeOf checks handle identity for polymorphic dispatch.
  local g = lurek.graph.newGraph()
  local node = g:addNode("dock", 4)
  local pkg = g:createItem("package", -1)
  g:addItem(pkg, node)
  local is_item = pkg:typeOf("LGraphItem")
  lurek.log.info("is LGraphItem=" .. tostring(is_item), "graph")
end

-- =============================================================================
-- STUBS: 13 uncovered lurek.graph API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LGraphEdge methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGraphEdge:getType --------------------------------------------
--@api-stub: LGraphEdge:getType
-- Returns the edge type string used by routing and filters.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b)
  local t = e:getType()
  lurek.log.debug("edge type: " .. tostring(t), "graph")
end

-- ---- Stub: LGraphEdge:setType --------------------------------------------
--@api-stub: LGraphEdge:setType
-- Sets the edge type string used by routing and filters.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b)
  e:setType("road")
  lurek.log.debug("edge type set: " .. tostring(e:getType()), "graph") -- "road"
end

-- ---- Stub: LGraphEdge:getCapacity ----------------------------------------
--@api-stub: LGraphEdge:getCapacity
-- Returns this edge's maximum concurrent item capacity.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b)
  local cap = e:getCapacity()
  lurek.log.debug("capacity: " .. tostring(cap), "graph")
end

-- ---- Stub: LGraphEdge:setCapacity ----------------------------------------
--@api-stub: LGraphEdge:setCapacity
-- Sets this edge's maximum concurrent item capacity.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b)
  e:setCapacity(10.0)
  lurek.log.debug("new capacity: " .. tostring(e:getCapacity()), "graph") -- 10
end

-- ---- Stub: LGraphEdge:isActive -------------------------------------------
--@api-stub: LGraphEdge:isActive
-- Returns whether this edge is active for routing and simulation.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b)
  lurek.log.debug("edge active: " .. tostring(e:isActive()), "graph") -- true
end

-- ---- Stub: LGraphEdge:setActive ------------------------------------------
--@api-stub: LGraphEdge:setActive
-- Enables or disables this edge for routing and simulation.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b)
  e:setActive(false)
  lurek.log.debug("edge disabled: " .. tostring(not e:isActive()), "graph") -- true
end

-- ---- Stub: LGraphEdge:type -----------------------------------------------
--@api-stub: LGraphEdge:type
-- Returns the Lua-visible type name for this graph edge handle.
do
  local obj = (function() local g = lurek.graph.newGraph(); local a = g:addNode('a'); local b = g:addNode('b'); return g:addEdge(a, b) end)()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LGraphEdge"
end

-- ---- Stub: LGraphEdge:typeOf ---------------------------------------------
--@api-stub: LGraphEdge:typeOf
-- Returns whether this graph edge handle matches a supported type name.
do
  local obj = (function() local g = lurek.graph.newGraph(); local a = g:addNode('a'); local b = g:addNode('b'); return g:addEdge(a, b) end)()
  lurek.log.debug("typeOf LGraphEdge: " .. tostring(obj:typeOf("LGraphEdge")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LGraphNode methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGraphNode:getItemCount ---------------------------------------
--@api-stub: LGraphNode:getItemCount
-- Returns the number of items currently stored on this node.
do
  local g = lurek.graph.newGraph()
  local n = g:addNode("hub")
  g:addItem(g:createItem("station"), n)
  g:addItem(g:createItem("market"), n)
  lurek.log.debug("items on node: " .. n:getItemCount(), "graph") -- 2
end

-- ---- Stub: LGraphNode:getItems -------------------------------------------
--@api-stub: LGraphNode:getItems
-- Returns item handles currently stored on this node.
do
  local g = lurek.graph.newGraph()
  local n = g:addNode("hub")
  g:addItem(g:createItem("port"), n)
  local items = n:getItems()
  lurek.log.debug("item count: " .. #items, "graph") -- 1
end

-- ---- Stub: LGraphNode:getEdges -------------------------------------------
--@api-stub: LGraphNode:getEdges
-- Returns edge handles connected to this node in the requested direction.
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("city_a")
  local b = g:addNode("city_b")
  g:addEdge(a, b)
  local edges = a:getEdges()
  lurek.log.debug("edges from a: " .. #edges, "graph") -- 1
end

-- ---- Stub: LGraphNode:type -----------------------------------------------
--@api-stub: LGraphNode:type
-- Returns the Lua-visible type name for this graph node handle.
do
  local obj = lurek.graph.newGraph():addNode('n1')
  lurek.log.debug("type: " .. obj:type(), "example") -- "LGraphNode"
end

-- ---- Stub: LGraphNode:typeOf ---------------------------------------------
--@api-stub: LGraphNode:typeOf
-- Returns whether this graph node handle matches a supported type name.
do
  local obj = lurek.graph.newGraph():addNode('n1')
  lurek.log.debug("typeOf LGraphNode: " .. tostring(obj:typeOf("LGraphNode")), "example") -- true
end
