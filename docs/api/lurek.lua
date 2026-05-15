---@meta
--- Auto-generated Lurek2D API documentation for LuaCATS.

lurek = {}

---@alias LuaValue nil|boolean|number|string|table|function|userdata|thread

---@alias SoundData LSoundData

---@class Success
Success = {}

---@alias AlignMode "left"|"center"|"right"|"justify"

---@alias ArcType "pie"|"open"|"closed"

---@alias BlendMode "alpha"|"add"|"subtract"|"multiply"|"replace"|"screen"|"none"

---@alias BodyType "static"|"dynamic"|"kinematic"

---@alias DrawMode "fill"|"line"

---@alias EasingFunction "linear"|"quadIn"|"quadOut"|"quadInOut"|"cubicIn"|"cubicOut"|"cubicInOut"|"sineIn"|"sineOut"|"sineInOut"|"elasticIn"|"elasticOut"|"elasticInOut"|"bounceIn"|"bounceOut"|"bounceInOut"|"backIn"|"backOut"|"backInOut"

---@alias FilterMode "nearest"|"linear"

---@alias JointType "revolute"|"prismatic"|"distance"|"weld"|"friction"|"motor"|"rope"|"pulley"|"gear"|"mouse"

---@alias LineCap "butt"|"square"|"none"

---@alias LineJoin "miter"|"bevel"|"none"

---@alias SourceType "static"|"stream"|"queue"

---@alias WrapMode "clamp"|"repeat"|"mirroredrepeat"|"clampzero"

--- Called once after the game script is loaded.
function lurek.load() end

--- Called every frame. `dt` is elapsed seconds.
---@param dt number Delta time in seconds
function lurek.update(dt) end

--- Called every frame for rendering. All draw calls must happen here.
function lurek.draw() end

--- Called when a keyboard key is pressed.
---@param key string Key name
function lurek.keypressed(key) end

--- Called when a keyboard key is released.
---@param key string Key name
function lurek.keyreleased(key) end

--- Called when text input is received.
---@param text string Input character(s)
function lurek.textinput(text) end

--- Called when a mouse button is pressed.
---@param x number Mouse X
---@param y number Mouse Y
---@param button number Button index (1=left, 2=right, 3=middle)
function lurek.mousepressed(x, y, button) end

--- Called when a mouse button is released.
---@param x number Mouse X
---@param y number Mouse Y
---@param button number Button index
function lurek.mousereleased(x, y, button) end

--- Called when the mouse cursor moves.
---@param x number X
---@param y number Y
---@param dx number X delta
---@param dy number Y delta
function lurek.mousemoved(x, y, dx, dy) end

--- Called on mouse wheel scroll.
---@param x number Horizontal scroll
---@param y number Vertical scroll
function lurek.wheelmoved(x, y) end

--- Called when a gamepad button is pressed.
---@param id number Gamepad ID
---@param button string Button name
function lurek.gamepadpressed(id, button) end

--- Called when a gamepad button is released.
---@param id number Gamepad ID
---@param button string Button name
function lurek.gamepadreleased(id, button) end

--- Called when a gamepad axis changes.
---@param id number Gamepad ID
---@param axis string Axis name
---@param value number Axis value
function lurek.gamepadaxis(id, axis, value) end

--- Called when a gamepad is connected.
---@param id number Device ID
function lurek.joystickadded(id) end

--- Called when a gamepad is disconnected.
---@param id number Device ID
function lurek.joystickremoved(id) end

--- Called when window gains or loses focus.
---@param has_focus boolean True if focused
function lurek.focus(has_focus) end

--- Called when window visibility changes.
---@param is_visible boolean True if visible
function lurek.visible(is_visible) end

--- Called when the window is resized.
---@param w number New width
---@param h number New height
function lurek.resize(w, h) end

--- Called when the window is about to close. Return true to cancel.
function lurek.quit() end

--- Called once when the engine initialises, before the first frame.
function lurek.init() end

--- Called once after init, when the window and GPU are ready.
function lurek.ready() end

--- Called every frame for game logic. `dt` is elapsed seconds.
---@param dt number Delta time in seconds
function lurek.process(dt) end

--- Called every frame after process, for late updates (camera follow, etc).
---@param dt number Delta time in seconds
function lurek.process_late(dt) end

--- Called at fixed physics timestep rate.
---@param dt number Fixed delta time
function lurek.process_physics(dt) end

--- Alias for process_physics — called at fixed timestep rate.
---@param dt number Fixed delta time
function lurek.fixedUpdate(dt) end

--- Called every frame after draw, for UI overlay rendering.
function lurek.draw_ui() end

--- Called when the engine is shutting down, after quit.
function lurek.exit() end

--- Called when a touch begins.
---@param id number Touch ID
---@param x number X
---@param y number Y
---@param dx number X delta
---@param dy number Y delta
---@param pressure number Pressure
function lurek.touchpressed(id, x, y, dx, dy, pressure) end

--- Called when a touch point moves.
---@param id number Touch ID
---@param x number X
---@param y number Y
---@param dx number X delta
---@param dy number Y delta
---@param pressure number Pressure
function lurek.touchmoved(id, x, y, dx, dy, pressure) end

--- Called when a touch ends.
---@param id number Touch ID
---@param x number X
---@param y number Y
---@param dx number X delta
---@param dy number Y delta
---@param pressure number Pressure
function lurek.touchreleased(id, x, y, dx, dy, pressure) end

--- Called when IME composition text changes.
---@param text string Composition text
---@param start number Cursor start
---@param length number Selection length
function lurek.textedited(text, start, length) end

---@class lurek.ai
lurek.ai = {}

--- Lua-side wrapper around a key-value blackboard for sharing state between AI subsystems. Blackboards store typed data (numbers, booleans, strings) that AI decision logic reads and writes.
---@class LAIBlackboard
LAIBlackboard = {}

--- Removes all entries from the blackboard.
---@return nil No return value.
function LAIBlackboard:clear() end

--- Retrieves a boolean value from the blackboard, returning a default if the key is absent.
---@param key string The key to look up.
---@param default? boolean Fallback value if key not found (defaults to false).
---@return boolean The stored or default value.
function LAIBlackboard:getBool(key, default) end

--- Returns a table containing all keys currently stored in the blackboard.
---@return table Array of key strings.
function LAIBlackboard:getKeys() end

--- Retrieves a numeric value from the blackboard, returning a default if the key is absent.
---@param key string The key to look up.
---@param default? number Fallback value if key not found (defaults to 0).
---@return number The stored or default value.
function LAIBlackboard:getNumber(key, default) end

--- Returns the number of entries currently stored in the blackboard.
---@return number Number of key-value pairs.
function LAIBlackboard:getSize() end

--- Retrieves a string value from the blackboard, returning a default if the key is absent.
---@param key string The key to look up.
---@param default? string Fallback value if key not found (defaults to empty string).
---@return string The stored or default value.
function LAIBlackboard:getString(key, default) end

--- Checks whether the blackboard contains a value for the given key.
---@param key string The key to check.
---@return boolean True if the key exists in the blackboard.
function LAIBlackboard:has(key) end

--- Removes the entry for the given key from the blackboard.
---@param key string The key to remove.
---@return nil No return value.
function LAIBlackboard:remove(key) end

--- Stores a boolean value under the given key in the blackboard.
---@param key string The key to store under.
---@param value boolean The boolean value to store.
---@return nil No return value.
function LAIBlackboard:setBool(key, value) end

--- Stores a numeric value under the given key in the blackboard.
---@param key string The key to store under.
---@param value number The numeric value to store.
---@return nil No return value.
function LAIBlackboard:setNumber(key, value) end

--- Stores a string value under the given key in the blackboard.
---@param key string The key to store under.
---@param value string The string value to store.
---@return nil No return value.
function LAIBlackboard:setString(key, value) end

--- Returns the type name of this userdata object.
---@return string Always returns "LAIBlackboard".
function LAIBlackboard:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("AIBlackboard", "Blackboard", or "Object").
---@return boolean True if the name matches.
function LAIBlackboard:typeOf(name) end

--- Lua-side wrapper around an AI director that manages game tension pacing and spawn/loot tuning. Inspired by Left 4 Dead's AI Director, it tracks intensity events and controls buildup/peak/relax phases.
---@class LAIDirector
LAIDirector = {}

--- Returns the recommended ambient intensity (music, environment) for current phase.
---@return number Ambient intensity value.
function LAIDirector:ambientIntensity() end

--- Returns a multiplier for loot drop quality based on current tension.
---@return number Loot quality factor.
function LAIDirector:lootFactor() end

--- Returns the current pacing phase name (e.g. "buildup", "peak", "relax").
---@return string Phase name.
function LAIDirector:phase() end

--- Records a game event with the given intensity to influence tension calculation.
---@param intensity number Event intensity (higher = more tension).
---@return nil No return value.
function LAIDirector:pushEvent(intensity) end

--- Resets the director to initial state, clearing all tension history.
---@return nil No return value.
function LAIDirector:reset() end

--- Manually overrides the current tension level.
---@param value number Tension value (0-1).
---@return nil No return value.
function LAIDirector:setTension(value) end

--- Returns a multiplier for enemy spawn rate based on current tension.
---@return number Spawn rate factor.
function LAIDirector:spawnRateFactor() end

--- Returns the current tension level (0-1) representing game pacing intensity.
---@return number Current tension value.
function LAIDirector:tension() end

--- Returns the type name of this userdata object.
---@return string Always returns "LAIDirector".
function LAIDirector:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LAIDirector" or "Object").
---@return boolean True if the name matches.
function LAIDirector:typeOf(name) end

--- Advances the director's internal state and tension pacing by delta time.
---@param dt number Delta time in seconds.
---@return nil No return value.
function LAIDirector:update(dt) end

--- Lua-side wrapper around an AI Level-of-Detail system that reduces update frequency for distant agents. Saves CPU by ticking far-away agents less often while keeping nearby ones responsive.
---@class LAILod
LAILod = {}

--- Checks whether an agent at the given tier should be updated on the current frame.
---@param tier number LOD tier index.
---@param frame number Current frame number.
---@return boolean True if the agent should be updated this frame.
function LAILod:shouldUpdate(tier, frame) end

--- Returns the total number of configured LOD tiers.
---@return number Number of tiers.
function LAILod:tierCount() end

--- Determines the LOD tier for an agent based on distance from a reference point.
---@param ax number Agent X position.
---@param ay number Agent Y position.
---@param rx number Reference X position (usually camera/player).
---@param ry number Reference Y position.
---@return number LOD tier index (0 = closest, highest detail).
function LAILod:tierFor(ax, ay, rx, ry) end

--- Returns the name of a specific LOD tier by index.
---@param tier number Tier index.
---@return string? Tier name, or nil if invalid index.
function LAILod:tierName(tier) end

--- Returns the type name of this userdata object.
---@return string Always returns "LAILod".
function LAILod:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LAILod" or "Object").
---@return boolean True if the name matches.
function LAILod:typeOf(name) end

--- Lua-side wrapper around AIWorld that manages AI agents, their decision models, and a global blackboard. Use this as the central container for all AI entities in your game.
---@class LAIWorld
LAIWorld = {}

--- Creates a new named AI agent in this world and returns a handle to it. Each agent has its own position, velocity, blackboard, and decision model.
---@param name string Unique name identifying the agent (used for lookups and inter-agent references).
---@return LAgent The newly created agent handle.
function LAIWorld:addAgent(name) end

--- Returns an existing agent by name, or nil if no agent with that name exists.
---@param name string Name of the agent to look up.
---@return LAgent? The agent handle, or nil if not found.
function LAIWorld:getAgent(name) end

--- Returns the total number of agents currently in this AI world.
---@return number Number of active agents.
function LAIWorld:getAgentCount() end

--- Returns a copy of the world-level shared blackboard for cross-agent data.
---@return LAIBlackboard The global blackboard instance.
function LAIWorld:getGlobalBlackboard() end

--- Removes an agent from the world, freeing its resources.
---@param agent LAgent The agent handle to remove.
---@return nil No return value.
function LAIWorld:removeAgent(agent) end

--- Returns the type name of this userdata object.
---@return string Always returns "LAIWorld".
function LAIWorld:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("AIWorld" or "Object").
---@return boolean True if the name matches.
function LAIWorld:typeOf(name) end

--- Advances the AI world by one time step, executing all custom decision model callbacks. Call this once per frame in your game loop to drive all agent AI.
---@param dt number Delta time in seconds since last update.
---@return nil No return value.
function LAIWorld:update(dt) end

--- Lua-side wrapper around an individual AI agent with position, velocity, tags, and decision model. Each agent represents one AI-controlled entity in the game world.
---@class LAgent
LAgent = {}

--- Adds a string tag to this agent for group filtering and queries.
---@param tag string The tag to add.
---@return nil No return value.
function LAgent:addTag(tag) end

--- Returns a copy of this agent's private blackboard for storing per-agent state.
---@return LAIBlackboard The agent's blackboard instance.
function LAgent:getBlackboard() end

--- Returns the name of the agent's current decision model.
---@return string Decision model identifier.
function LAgent:getDecisionModel() end

--- Returns the agent's maximum steering force.
---@return number Maximum force in units per second squared.
function LAgent:getMaxForce() end

--- Returns the agent's maximum movement speed.
---@return number Maximum speed in units per second.
function LAgent:getMaxSpeed() end

--- Returns the unique name of this agent.
---@return string The agent's registered name.
function LAgent:getName() end

--- Returns the agent's current 2D world position.
---@return number a X and Y coordinates.
---@return number b X and Y coordinates.
function LAgent:getPosition() end

--- Returns the agent's current decision priority.
---@return number The priority value.
function LAgent:getPriority() end

--- Returns the agent's current velocity vector.
---@return number a X and Y components of velocity.
---@return number b X and Y components of velocity.
function LAgent:getVelocity() end

--- Checks whether the agent currently has the specified tag.
---@param tag string The tag to check.
---@return boolean True if the agent has the tag.
function LAgent:hasTag(tag) end

--- Removes a previously added tag from this agent.
---@param tag string The tag to remove.
---@return nil No return value.
function LAgent:removeTag(tag) end

--- Assigns a Lua callback as this agent's custom decision model, called each update.
---@param callback function Function(agent, blackboard, dt) invoked each world update.
---@return nil No return value.
function LAgent:setCustomModel(callback) end

--- Sets the agent's decision model by name (e.g. "fsm", "bt", "utility").
---@param model string Name of the built-in decision model to use.
---@return nil No return value.
function LAgent:setDecisionModel(model) end

--- Sets the maximum steering force magnitude that can be applied to this agent. Limits how sharply the agent can turn or accelerate.
---@param v number Maximum force in units per second squared.
---@return nil No return value.
function LAgent:setMaxForce(v) end

--- Sets the maximum movement speed this agent can achieve. Used by steering behaviors to cap velocity magnitude.
---@param v number Maximum speed in units per second.
---@return nil No return value.
function LAgent:setMaxSpeed(v) end

--- Sets the agent's 2D world position.
---@param x number X coordinate in world space.
---@param y number Y coordinate in world space.
---@return nil No return value.
function LAgent:setPosition(x, y) end

--- Sets the agent's decision priority for ordering in multi-agent evaluation.
---@param p number Priority value; higher values are evaluated first.
---@return nil No return value.
function LAgent:setPriority(p) end

--- Sets the agent's current velocity vector.
---@param x number X component of velocity.
---@param y number Y component of velocity.
---@return nil No return value.
function LAgent:setVelocity(x, y) end

--- Returns the type name of this userdata object.
---@return string Always returns "LAgent".
function LAgent:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("Agent" or "Object").
---@return boolean True if the name matches.
function LAgent:typeOf(name) end

--- Lua-side wrapper around a single behavior tree node (selector, sequence, action, condition, decorator). Nodes are composed into trees to define complex AI behavior.
---@class LBTNode
LBTNode = {}

--- Appends a child node to a composite (Selector, Sequence, or Parallel) node.
---@param child_ud LBTNode The child node to append.
---@return nil No return value.
function LBTNode:addChild(child_ud) end

--- Returns the number of children attached to this composite node.
---@return number Number of child nodes.
function LBTNode:getChildCount() end

--- Returns the configured repetition count of a Repeater node.
---@return number The repeat count (0 means infinite).
function LBTNode:getCount() end

--- Returns the type name of this node (e.g. "selector", "sequence", "action").
---@return string The node type identifier.
function LBTNode:getNodeType() end

--- Resets this node's internal running state so it re-evaluates from scratch.
---@return nil No return value.
function LBTNode:reset() end

--- Sets the single child of a decorator node (Inverter, Repeater, or Succeeder).
---@param child_ud LBTNode The child node to set.
---@return nil No return value.
function LBTNode:setChild(child_ud) end

--- Sets the repetition count for a Repeater node (0 means infinite).
---@param n number Number of times to repeat the child.
---@return nil No return value.
function LBTNode:setCount(n) end

--- Sets the failure policy for a Parallel node ("requireOne" or "requireAll").
---@param policy string Policy name determining when parallel fails.
---@return nil No return value.
function LBTNode:setFailurePolicy(policy) end

--- Sets the success policy for a Parallel node ("requireOne" or "requireAll").
---@param policy string Policy name determining when parallel succeeds.
---@return nil No return value.
function LBTNode:setSuccessPolicy(policy) end

--- Returns the type name of this userdata object.
---@return string Always returns "LBTNode".
function LBTNode:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("BTNode" or "Object").
---@return boolean True if the name matches.
function LBTNode:typeOf(name) end

--- Lua-side wrapper around a multi-armed bandit for adaptive action selection. Bandits balance exploration vs exploitation to find the best option over time (e.g. adaptive difficulty, A/B testing).
---@class LBandit
LBandit = {}

--- Returns the number of arms in the bandit.
---@return number Number of arms.
function LBandit:armCount() end

--- Returns the arm with the highest estimated reward.
---@return number Best arm index (0-based).
function LBandit:bestArm() end

--- Resets all arm statistics to initial state.
---@return nil No return value.
function LBandit:reset() end

--- Selects an arm using the configured strategy (epsilon-greedy, UCB1, or Thompson).
---@return number Selected arm index (0-based).
function LBandit:select() end

--- Returns the total number of arm selections made so far.
---@return number Total pull count.
function LBandit:totalPulls() end

--- Returns the type name of this userdata object.
---@return string Always returns "LBandit".
function LBandit:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LBandit" or "Object").
---@return boolean True if the name matches.
function LBandit:typeOf(name) end

--- Updates the reward estimate for a specific arm after observing a result.
---@param idx number Arm index (0-based).
---@param reward number Observed reward value.
---@return nil No return value.
function LBandit:update(idx, reward) end

--- Lua-side wrapper around a behavior tree that executes hierarchical AI logic each tick. Behavior trees are best for complex AI with many interruptible subtasks and priority fallbacks.
---@class LBehaviorTree
LBehaviorTree = {}

--- Returns a debug info table with node_count and last_status for inspection.
---@return table Table with fields node_count (integer) and last_status (string).
function LBehaviorTree:getDebugState() end

--- Returns the status string from the most recent tree evaluation ("success", "failure", or "running").
---@return string Last tick result status.
function LBehaviorTree:getLastStatus() end

--- Sets the root node of this behavior tree, replacing any existing tree structure.
---@param node_ud LBTNode The node to use as the tree root.
---@return nil No return value.
function LBehaviorTree:setRoot(node_ud) end

--- Returns the type name of this userdata object.
---@return string Always returns "LBehaviorTree".
function LBehaviorTree:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("BehaviorTree" or "Object").
---@return boolean True if the name matches.
function LBehaviorTree:typeOf(name) end

--- Lua-side wrapper around a priority command queue for ordered AI task execution. Commands are processed in order with priority override and interrupt support for responsive AI behavior.
---@class LCommandQueue
LCommandQueue = {}

--- Cancels the currently executing command and advances to the next.
---@return boolean True if a command was cancelled.
function LCommandQueue:cancelCurrent() end

--- Removes all commands from the queue.
---@return nil No return value.
function LCommandQueue:clear() end

--- Adds a command to the back of the queue with a type, callback, and optional target/priority.
---@param kind string Command type identifier.
---@param callback function Function to execute when this command runs.
---@param opts? table Optional {targetX, targetY, priority, interruptible}.
---@return nil No return value.
function LCommandQueue:enqueue(kind, callback, opts) end

--- Returns the number of commands currently in the queue.
---@return number Queue length.
function LCommandQueue:getCount() end

--- Returns the target position of the currently executing command.
---@return number a Target X and Y, or (0,0) if no command.
---@return number b Target X and Y, or (0,0) if no command.
function LCommandQueue:getCurrentTarget() end

--- Returns the type string of the currently executing command, or nil.
---@return string? Current command type.
function LCommandQueue:getCurrentType() end

--- Checks whether the command queue has no commands.
---@return boolean True if queue is empty.
function LCommandQueue:isEmpty() end

--- Inserts a command at the front of the queue for immediate execution next.
---@param kind string Command type identifier.
---@param callback function Function to execute when this command runs.
---@param opts? table Optional {targetX, targetY, priority, interruptible}.
---@return nil No return value.
function LCommandQueue:pushFront(kind, callback, opts) end

--- Clears the queue and sets this as the only command.
---@param kind string Command type identifier.
---@param callback function Function to execute when this command runs.
---@param opts? table Optional {targetX, targetY, priority, interruptible}.
---@return nil No return value.
function LCommandQueue:replace(kind, callback, opts) end

--- Returns the type name of this userdata object.
---@return string Always returns "LCommandQueue".
function LCommandQueue:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("CommandQueue" or "Object").
---@return boolean True if the name matches.
function LCommandQueue:typeOf(name) end

--- Lua-side wrapper around context-based steering that uses interest/danger maps for movement. Context steering avoids oscillation problems of traditional steering by evaluating all directions simultaneously.
---@class LContextSteering
LContextSteering = {}

--- Adds rectangular boundary avoidance to the context map.
---@param min_x number Left edge.
---@param min_y number Top edge.
---@param max_x number Right edge.
---@param max_y number Bottom edge.
---@param margin number Distance from edge where danger starts.
---@param weight number Danger weight.
---@return nil No return value.
function LContextSteering:addAvoidBounds(min_x, min_y, max_x, max_y, margin, weight) end

--- Adds a point danger source to the context map that repels from a position.
---@param x number Danger source X.
---@param y number Danger source Y.
---@param radius number Avoidance radius.
---@param weight number Danger weight.
---@return nil No return value.
function LContextSteering:addAvoidPoint(x, y, radius, weight) end

--- Adds a target position as an interest source to the context map.
---@param tx number Target X coordinate.
---@param ty number Target Y coordinate.
---@param weight number Interest weight.
---@return nil No return value.
function LContextSteering:addSeekTarget(tx, ty, weight) end

--- Adds random wander interest to the context map.
---@param jitter number Random variation per frame.
---@param weight number Interest weight.
---@return nil No return value.
function LContextSteering:addWander(jitter, weight) end

--- Returns the magnitude of the last chosen direction vector.
---@return number Direction magnitude.
function LContextSteering:chosenMagnitude() end

--- Removes all interest and danger sources from the context map.
---@return nil No return value.
function LContextSteering:clearBehaviors() end

--- Evaluates the context map and returns the best movement direction.
---@param ax number Agent X position.
---@param ay number Agent Y position.
---@param vx number Agent X velocity.
---@param vy number Agent Y velocity.
---@return number a Best direction X and Y components.
---@return number b Best direction X and Y components.
function LContextSteering:evaluate(ax, ay, vx, vy) end

--- Returns the number of directional slots in the context map.
---@return number Number of slots.
function LContextSteering:slotCount() end

--- Returns the type name of this userdata object.
---@return string Always returns "LContextSteering".
function LContextSteering:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LContextSteering" or "Object").
---@return boolean True if the name matches.
function LContextSteering:typeOf(name) end

--- Lua-side wrapper around a dialogue AI that selects conversation topics and branches based on game state. Integrates with FSM state, BT status, and utility scores for context-aware NPC dialogue.
---@class LDialogueAI
LDialogueAI = {}

--- Adds a dialogue branch to an existing topic with optional state-based filters.
---@param topic_id string Topic to add the branch to.
---@param branch_id string Unique branch identifier.
---@param weight? number Selection weight (default 1.0).
---@param fsm_state? string Required FSM state for this branch.
---@param bt_status? string Required BT status for this branch.
---@param utility_key? string Utility score key for weighting.
---@return boolean True if the branch was added successfully.
function LDialogueAI:addBranch(topic_id, branch_id, weight, fsm_state, bt_status, utility_key) end

--- Registers a dialogue topic with optional state filters for conditional availability.
---@param id string Unique topic identifier.
---@param weight? number Base selection weight (default 1.0).
---@param fsm_state? string Required FSM state for this topic to be selectable.
---@param bt_status? string Required BT status for this topic to be selectable.
---@param utility_key? string Utility score key that modifies selection weight.
---@return nil No return value.
function LDialogueAI:addTopic(id, weight, fsm_state, bt_status, utility_key) end

--- Removes all stored utility scores from the dialogue AI.
---@return nil No return value.
function LDialogueAI:clearUtilityScores() end

--- Returns the total number of registered dialogue topics.
---@return number Number of topics.
function LDialogueAI:getTopicCount() end

--- Selects the best branch within a given topic based on state and scores.
---@param topic_id string Topic to select a branch from.
---@return string? The chosen branch id, or nil if none available.
function LDialogueAI:selectBranch(topic_id) end

--- Selects the best available topic based on current state and utility scores.
---@return string? The chosen topic id, or nil if none available.
function LDialogueAI:selectTopic() end

--- Sets the behavior tree status context for topic/branch selection.
---@param status? string BT status string, or nil to clear.
---@return nil No return value.
function LDialogueAI:setBTStatus(status) end

--- Sets the current FSM state context used for topic/branch selection filtering.
---@param state? string FSM state name, or nil to clear.
---@return nil No return value.
function LDialogueAI:setFSMState(state) end

--- Sets a named utility score used to weight topic/branch selection.
---@param key string Name of the utility score.
---@param score number The score value.
---@return nil No return value.
function LDialogueAI:setUtilityScore(key, score) end

--- Returns the type name of this userdata object.
---@return string Always returns "LDialogueAI".
function LDialogueAI:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("DialogueAI" or "Object").
---@return boolean True if the name matches.
function LDialogueAI:typeOf(name) end

--- Lua-side wrapper around an emotion model that tracks multiple named emotions with decay. Each emotion has a rest value it decays toward, useful for NPCs that react emotionally to game events.
---@class LEmotionModel
LEmotionModel = {}

--- Registers a new emotion with rest value, decay rate, and minimum visibility threshold.
---@param name string Emotion name (e.g. "joy", "fear").
---@param rest number Resting value the emotion decays toward.
---@param decay number Decay speed per second.
---@param min_vis number Minimum value for the emotion to be considered active.
---@return nil No return value.
function LEmotionModel:add(name, rest, decay, min_vis) end

--- Returns the name of the most intense active emotion, or nil.
---@return string? Dominant emotion name.
function LEmotionModel:dominant() end

--- Returns the current value of a named emotion.
---@param name string Emotion name.
---@return number Current emotion intensity.
function LEmotionModel:get(name) end

--- Checks whether a named emotion exceeds its minimum visibility threshold.
---@param name string Emotion name.
---@return boolean True if the emotion is active.
function LEmotionModel:isActive(name) end

--- Resets all emotions to their rest values.
---@return nil No return value.
function LEmotionModel:reset() end

--- Triggers an emotion, increasing its value by the given amount.
---@param name string Emotion to trigger.
---@param amount number Intensity to add.
---@return nil No return value.
function LEmotionModel:trigger(name, amount) end

--- Returns the type name of this userdata object.
---@return string Always returns "LEmotionModel".
function LEmotionModel:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LEmotionModel" or "Object").
---@return boolean True if the name matches.
function LEmotionModel:typeOf(name) end

--- Decays all emotions toward their rest values over delta time.
---@param dt number Delta time in seconds.
---@return nil No return value.
function LEmotionModel:update(dt) end

--- Lua-side wrapper around a Goal-Oriented Action Planner that finds action sequences to reach goals. GOAP automatically chains actions with preconditions and effects to solve complex multi-step objectives.
---@class LGOAPPlanner
LGOAPPlanner = {}

--- Registers a named GOAP action with a cost and optional execution callback.
---@param name string Unique action name.
---@param cost? number Action cost for planning (default 1.0).
---@param callback? function Optional function called when executing this action.
---@return nil No return value.
function LGOAPPlanner:addAction(name, cost, callback) end

--- Registers a named goal with a priority for planning.
---@param name string Unique goal name.
---@param priority? number Goal priority; higher is preferred (default 1.0).
---@return nil No return value.
function LGOAPPlanner:addGoal(name, priority) end

--- Returns the number of registered GOAP actions.
---@return number Action count.
function LGOAPPlanner:getActionCount() end

--- Returns the number of registered goals.
---@return number Goal count.
function LGOAPPlanner:getGoalCount() end

--- Returns the maximum number of planning iterations allowed.
---@return number Max iterations.
function LGOAPPlanner:getMaxIterations() end

--- Runs the planner against the given world state and returns an ordered action sequence.
---@param world_state_tbl table Table of string-boolean pairs representing current state.
---@param max_depth? number Maximum plan depth (default 10).
---@return table Array of action name strings forming the plan.
function LGOAPPlanner:plan(world_state_tbl, max_depth) end

--- Sets a boolean effect that this action applies to world state when executed.
---@param action_name string Action to set the effect on.
---@param key string World state key to modify.
---@param value boolean Value to set when action completes.
---@return nil No return value.
function LGOAPPlanner:setEffect(action_name, key, value) end

--- Sets a required boolean value in the goal's desired world state.
---@param goal_name string Goal to modify.
---@param key string World state key.
---@param value boolean Desired value for the goal to be satisfied.
---@return nil No return value.
function LGOAPPlanner:setGoalState(goal_name, key, value) end

--- Sets the maximum number of planning iterations to prevent runaway searches.
---@param n number Maximum iteration count.
---@return nil No return value.
function LGOAPPlanner:setMaxIterations(n) end

--- Sets a boolean precondition that must be true in world state before an action can execute.
---@param action_name string Action to set the precondition on.
---@param key string World state key.
---@param value boolean Required value for the precondition.
---@return nil No return value.
function LGOAPPlanner:setPrecondition(action_name, key, value) end

--- Returns the type name of this userdata object.
---@return string Always returns "LGOAPPlanner".
function LGOAPPlanner:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("GOAPPlanner" or "Object").
---@return boolean True if the name matches.
function LGOAPPlanner:typeOf(name) end

--- Lua-side wrapper around a genetic algorithm for evolving populations of gene arrays. Use with neural networks (neuroevolution) or directly to optimize AI parameters through selection and mutation.
---@class LGeneticAlgorithm
LGeneticAlgorithm = {}

--- Returns the gene array of the highest-fitness chromosome.
---@return table Array of gene float values from the best individual.
function LGeneticAlgorithm:bestGenes() end

--- Runs one generation of selection, crossover, and mutation on the population.
---@return nil No return value.
function LGeneticAlgorithm:evolve() end

--- Returns the current generation number.
---@return number Generation count.
function LGeneticAlgorithm:generation() end

--- Returns the gene array for a specific chromosome.
---@param idx number Chromosome index (0-based).
---@return table Array of gene float values.
function LGeneticAlgorithm:getGenes(idx) end

--- Returns the population size.
---@return number Number of chromosomes in the population.
function LGeneticAlgorithm:popSize() end

--- Sets the fitness score for a specific chromosome by index.
---@param idx number Chromosome index (0-based).
---@param fitness number Fitness value.
---@return nil No return value.
function LGeneticAlgorithm:setFitness(idx, fitness) end

--- Returns the type name of this userdata object.
---@return string Always returns "LGeneticAlgorithm".
function LGeneticAlgorithm:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LGeneticAlgorithm" or "Object").
---@return boolean True if the name matches.
function LGeneticAlgorithm:typeOf(name) end

--- Lua-side wrapper around a Hierarchical Task Network domain for decomposition-based planning. HTN breaks complex goals into ordered primitive tasks through method decomposition with preconditions.
---@class LHTNDomain
LHTNDomain = {}

--- Registers a compound task with decomposition methods containing preconditions and sub-tasks.
---@param comp_name string Compound task name.
---@param methods_table table Array of method tables with name, preconditions, sub_tasks fields.
---@return nil No return value.
function LHTNDomain:addCompound(comp_name, methods_table) end

--- Registers a primitive task with preconditions, effects, and clear-list.
---@param name string Unique task name.
---@param preconds table Array of precondition state keys.
---@param effects table Array of state keys set to true on completion.
---@param clears table Array of state keys cleared on completion.
---@return nil No return value.
function LHTNDomain:addPrimitive(name, preconds, effects, clears) end

--- Decomposes from a root task given world state and returns an ordered primitive task list.
---@param root_task string Starting compound task name.
---@param state_table table Current world state as string-number pairs.
---@return table? Array of primitive task names, or nil if no valid plan.
function LHTNDomain:plan(root_task, state_table) end

--- Returns the total number of registered tasks (primitive + compound).
---@return number Task count.
function LHTNDomain:taskCount() end

--- Returns the type name of this userdata object.
---@return string Always returns "LHTNDomain".
function LHTNDomain:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LHTNDomain" or "Object").
---@return boolean True if the name matches.
function LHTNDomain:typeOf(name) end

--- Lua-side wrapper around a grid-based influence map for spatial AI reasoning. Use influence maps to track danger zones, territory control, resource density, and other spatial data for strategic decisions.
---@class LInfluenceMap
LInfluenceMap = {}

--- Creates a new named influence layer on the map.
---@param name string Unique layer name.
---@return nil No return value.
function LInfluenceMap:addLayer(name) end

--- Blends two layers with weights into a destination layer.
---@param layer_a string First source layer.
---@param weight_a number Weight for first layer.
---@param layer_b string Second source layer.
---@param weight_b number Weight for second layer.
---@param dest string Destination layer name.
---@return nil No return value.
function LInfluenceMap:blend(layer_a, weight_a, layer_b, weight_b, dest) end

--- Resets all influence values across all layers to zero.
---@return nil No return value.
function LInfluenceMap:clearAll() end

--- Resets all influence values in a specific layer to zero.
---@param layer string Layer to clear.
---@return nil No return value.
function LInfluenceMap:clearLayer(layer) end

--- Multiplies all influence values in a layer by a decay factor.
---@param layer string Target layer name.
---@param factor number Decay multiplier (e.g. 0.95).
---@return nil No return value.
function LInfluenceMap:decay(layer, factor) end

--- Returns the world-space size of each grid cell.
---@return number Cell size in world units.
function LInfluenceMap:getCellSize() end

--- Returns the grid height in cells.
---@return number Number of rows.
function LInfluenceMap:getHeight() end

--- Returns the influence value at a specific grid cell (1-based coordinates).
---@param layer string Target layer name.
---@param x number Grid column (1-based).
---@param y number Grid row (1-based).
---@return number The influence value at that cell.
function LInfluenceMap:getInfluence(layer, x, y) end

--- Returns the grid cell (1-based) with the highest influence value in a layer.
---@param layer string Layer to query.
---@return number a X and Y cell coordinates of the maximum.
---@return number b X and Y cell coordinates of the maximum.
function LInfluenceMap:getMaxPosition(layer) end

--- Returns the grid cell (1-based) with the lowest influence value in a layer.
---@param layer string Layer to query.
---@return number a X and Y cell coordinates of the minimum.
---@return number b X and Y cell coordinates of the minimum.
function LInfluenceMap:getMinPosition(layer) end

--- Returns the grid width in cells.
---@return number Number of columns.
function LInfluenceMap:getWidth() end

--- Checks whether a layer with the given name exists.
---@param name string Layer name to check.
---@return boolean True if the layer exists.
function LInfluenceMap:hasLayer(name) end

--- Spreads influence values to neighboring cells using a momentum factor.
---@param layer string Target layer name.
---@param momentum? number Propagation momentum (default 0.5).
---@return nil No return value.
function LInfluenceMap:propagate(layer, momentum) end

--- Returns the total influence within a world-space rectangle.
---@param layer string Layer to query.
---@param wx number Rectangle left X.
---@param wy number Rectangle top Y.
---@param ww number Rectangle width.
---@param wh number Rectangle height.
---@return number Sum of influence values in the rectangle.
function LInfluenceMap:queryRect(layer, wx, wy, ww, wh) end

--- Sets the influence value at a specific grid cell (1-based coordinates).
---@param layer string Target layer name.
---@param x number Grid column (1-based).
---@param y number Grid row (1-based).
---@param value number Influence value to set.
---@return nil No return value.
function LInfluenceMap:setInfluence(layer, x, y, value) end

--- Stamps a radial influence pattern at a world-space position with falloff.
---@param layer string Target layer name.
---@param wx number World X coordinate of stamp center.
---@param wy number World Y coordinate of stamp center.
---@param radius number Stamp radius in world units.
---@param value number Peak influence value at center.
---@param falloff? number Falloff exponent (default 1.0 for linear).
---@return nil No return value.
function LInfluenceMap:stampInfluence(layer, wx, wy, radius, value, falloff) end

--- Returns the type name of this userdata object.
---@return string Always returns "LInfluenceMap".
function LInfluenceMap:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("InfluenceMap" or "Object").
---@return boolean True if the name matches.
function LInfluenceMap:typeOf(name) end

--- Lua-side wrapper around a Monte Carlo Tree Search engine for game-tree decision making. MCTS simulates many random playouts to find the best move in turn-based or strategy games.
---@class LMCTSEngine
LMCTSEngine = {}

--- Runs MCTS from a root state using provided action/apply/evaluate callbacks.
---@param root_state number Initial game state identifier.
---@param get_actions_fn function Callback(state) returning array of valid actions.
---@param apply_fn function Callback(state, action) returning new state.
---@param eval_fn function Callback(state) returning heuristic evaluation score.
---@return number? Best action found, or nil if no actions available.
function LMCTSEngine:search(root_state, get_actions_fn, apply_fn, eval_fn) end

--- Returns the type name of this userdata object.
---@return string Always returns "LMCTSEngine".
function LMCTSEngine:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LMCTSEngine" or "Object").
---@return boolean True if the name matches.
function LMCTSEngine:typeOf(name) end

--- Lua-side wrapper around a need system that models agent drives with decay and urgency. Needs decay over time (hunger grows) and can be satisfied by actions, driving utility-based AI decisions.
---@class LNeedSystem
LNeedSystem = {}

--- Registers a new need with decay rate, urgency threshold, and urgency scaling factor.
---@param name string Unique need name (e.g. "hunger", "rest").
---@param decay_rate number How fast the need increases per second.
---@param urgency_threshold number Value above which the need becomes urgent.
---@param urgency_factor number Multiplier for urgency scoring.
---@return nil No return value.
function LNeedSystem:addNeed(name, decay_rate, urgency_threshold, urgency_factor) end

--- Returns the name of the most urgent need, or nil if all are satisfied.
---@return string? Most urgent need name.
function LNeedSystem:mostUrgent() end

--- Reduces a need's value by the given amount (e.g. feeding reduces hunger).
---@param name string Need to satisfy.
---@param amount number Amount to reduce by.
---@return nil No return value.
function LNeedSystem:satisfy(name, amount) end

--- Returns the type name of this userdata object.
---@return string Always returns "LNeedSystem".
function LNeedSystem:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LNeedSystem" or "Object").
---@return boolean True if the name matches.
function LNeedSystem:typeOf(name) end

--- Advances all need decay timers by delta time.
---@param dt number Delta time in seconds.
---@return nil No return value.
function LNeedSystem:update(dt) end

--- Returns the current value of a specific need.
---@param name string Need name.
---@return number Current need value.
function LNeedSystem:valueOf(name) end

--- Lua-side wrapper around a simple feedforward neural network for game AI inference. Networks can be trained via neuroevolution or have weights set manually for learned behaviors.
---@class LNeuralNet
LNeuralNet = {}

--- Adds a fully-connected layer with specified input size, output size, and activation.
---@param inputs number Number of input neurons.
---@param outputs number Number of output neurons.
---@param activation string Activation function name ("relu", "sigmoid", "tanh", "linear", "softmax").
---@return nil No return value.
function LNeuralNet:addLayer(inputs, outputs, activation) end

--- Runs a forward pass through the network and returns the output values.
---@param input table Array of input numbers.
---@return table Array of output numbers.
function LNeuralNet:forward(input) end

--- Returns all network weights as a flat array.
---@return table Flat array of weight values.
function LNeuralNet:getWeights() end

--- Returns the number of layers in the network.
---@return number Layer count.
function LNeuralNet:layerCount() end

--- Returns the total number of trainable parameters (weights + biases).
---@return number Parameter count.
function LNeuralNet:paramCount() end

--- Sets all network weights from a flat array (used with genetic algorithms).
---@param weights table Flat array of weight values.
---@return boolean True if the weight count matched.
function LNeuralNet:setWeights(weights) end

--- Returns the type name of this userdata object.
---@return string Always returns "LNeuralNet".
function LNeuralNet:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LNeuralNet" or "Object").
---@return boolean True if the name matches.
function LNeuralNet:typeOf(name) end

--- Lua-side wrapper around neuroevolution combining genetic algorithms with neural networks. Evolves a population of neural networks by treating weights as chromosomes for selection and crossover.
---@class LNeuroevolution
LNeuroevolution = {}

--- Returns the highest fitness score in the current population.
---@return number Best fitness value.
function LNeuroevolution:bestFitness() end

--- Returns the neural network with the highest fitness in the population.
---@return LNeuralNet? Best network, or nil if population is empty.
function LNeuroevolution:bestNetwork() end

--- Creates a neural network from a specific chromosome's genes.
---@param idx number Chromosome index (0-based).
---@return LNeuralNet? Neural network instance, or nil if index is invalid.
function LNeuroevolution:chromosomeToNet(idx) end

--- Runs one generation of neuroevolution on the population.
---@return nil No return value.
function LNeuroevolution:evolve() end

--- Returns the current generation number.
---@return number Generation count.
function LNeuroevolution:generation() end

--- Returns the population size.
---@return number Number of networks in the population.
function LNeuroevolution:popSize() end

--- Sets the fitness for a specific network in the population.
---@param idx number Network index (0-based).
---@param fitness number Fitness score.
---@return nil No return value.
function LNeuroevolution:setFitness(idx, fitness) end

--- Returns the type name of this userdata object.
---@return string Always returns "LNeuroevolution".
function LNeuroevolution:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LNeuroevolution" or "Object").
---@return boolean True if the name matches.
function LNeuroevolution:typeOf(name) end

--- Lua-side wrapper around an ORCA collision avoidance solver for crowd simulation. ORCA computes collision-free velocities for multiple agents moving simultaneously without oscillation.
---@class LORCASolver
LORCASolver = {}

--- Adds a circular agent to the ORCA solver at the given position.
---@param x number Initial X position.
---@param y number Initial Y position.
---@param radius number Agent collision radius.
---@param max_speed number Maximum movement speed.
---@return number Agent index (0-based) in the solver.
function LORCASolver:addAgent(x, y, radius, max_speed) end

--- Returns the total number of agents in the solver.
---@return number Agent count.
function LORCASolver:agentCount() end

--- Runs the ORCA algorithm to compute collision-free velocities for all agents.
---@param dt number Delta time for the computation step.
---@return nil No return value.
function LORCASolver:compute(dt) end

--- Returns the collision-free velocity computed for a specific agent.
---@param idx number Agent index (0-based).
---@return number a Safe velocity X and Y.
---@return number b Safe velocity X and Y.
function LORCASolver:getSafeVelocity(idx) end

--- Updates an agent's position in the solver for the next computation step.
---@param idx number Agent index (0-based).
---@param x number New X position.
---@param y number New Y position.
---@return nil No return value.
function LORCASolver:setPosition(idx, x, y) end

--- Sets the desired velocity for an agent; ORCA will compute a collision-free approximation.
---@param idx number Agent index (0-based).
---@param pvx number Preferred velocity X.
---@param pvy number Preferred velocity Y.
---@return nil No return value.
function LORCASolver:setPreferredVelocity(idx, pvx, pvy) end

--- Returns the type name of this userdata object.
---@return string Always returns "LORCASolver".
function LORCASolver:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LORCASolver" or "Object").
---@return boolean True if the name matches.
function LORCASolver:typeOf(name) end

--- Lua-side wrapper around a tabular Q-learning agent for reinforcement learning. Useful for NPCs that learn optimal strategies over repeated episodes (e.g. adaptive difficulty, enemy tactics).
---@class LQLearner
LQLearner = {}

--- Returns the greedy best action for the given state without exploration.
---@param state number State index (1-based).
---@return number Best action index (1-based).
function LQLearner:bestAction(state) end

--- Chooses an action using epsilon-greedy exploration for the given state (1-based).
---@param state number State index (1-based).
---@return number Chosen action index (1-based).
function LQLearner:chooseAction(state) end

--- Restores the Q-table from a previously serialized JSON string.
---@param json string JSON data to load.
---@return nil No return value.
function LQLearner:deserialize(json) end

--- Signals the end of a learning episode, decaying exploration rate.
---@return nil No return value.
function LQLearner:endEpisode() end

--- Returns the number of actions in the Q-table.
---@return number Action count.
function LQLearner:getActionCount() end

--- Returns the current discount factor.
---@return number The gamma value.
function LQLearner:getDiscountFactor() end

--- Returns the total number of completed learning episodes.
---@return number Episode count.
function LQLearner:getEpisodeCount() end

--- Returns the current exploration decay factor.
---@return number The epsilon decay value.
function LQLearner:getExplorationDecay() end

--- Returns the current exploration rate.
---@return number The epsilon value.
function LQLearner:getExplorationRate() end

--- Returns the current learning rate.
---@return number The alpha value.
function LQLearner:getLearningRate() end

--- Returns the current Q-value for a specific state-action pair.
---@param state number State index (1-based).
---@param action number Action index (1-based).
---@return number The Q-value.
function LQLearner:getQValue(state, action) end

--- Returns the number of states in the Q-table.
---@return number State count.
function LQLearner:getStateCount() end

--- Updates the Q-value for a state-action pair given a reward and next state.
---@param state number Current state index (1-based).
---@param action number Action taken (1-based).
---@param reward number Reward received for the transition.
---@param next_state number Resulting state index (1-based).
---@return nil No return value.
function LQLearner:learn(state, action, reward, next_state) end

--- Serializes the entire Q-table to a JSON string for saving.
---@return string JSON representation of the Q-learner state.
function LQLearner:serialize() end

--- Sets the discount factor (gamma) for weighting future rewards.
---@param v number Discount factor between 0 and 1.
---@return nil No return value.
function LQLearner:setDiscountFactor(v) end

--- Sets the decay factor applied to epsilon at each episode end.
---@param v number Decay multiplier (e.g. 0.99).
---@return nil No return value.
function LQLearner:setExplorationDecay(v) end

--- Sets the exploration rate (epsilon) controlling random action probability.
---@param v number Epsilon value between 0 and 1.
---@return nil No return value.
function LQLearner:setExplorationRate(v) end

--- Sets the learning rate (alpha) controlling how fast Q-values update.
---@param v number Learning rate between 0 and 1.
---@return nil No return value.
function LQLearner:setLearningRate(v) end

--- Manually sets the Q-value for a specific state-action pair.
---@param state number State index (1-based).
---@param action number Action index (1-based).
---@param value number The Q-value to set.
---@return nil No return value.
function LQLearner:setQValue(state, action, value) end

--- Returns the type name of this userdata object.
---@return string Always returns "LQLearner".
function LQLearner:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("QLearner" or "Object").
---@return boolean True if the name matches.
function LQLearner:typeOf(name) end

--- Lua-side wrapper around a squad of agents with formations and shared blackboard. Squads coordinate group behavior like line, wedge, or circle formations with a designated leader.
---@class LSquad
LSquad = {}

--- Adds an agent name to the squad's member list.
---@param name string Agent name to add.
---@return nil No return value.
function LSquad:addMember(name) end

--- Returns the squad's shared blackboard for coordinating member behavior.
---@return LAIBlackboard The squad's blackboard.
function LSquad:getBlackboard() end

--- Returns the current formation type name.
---@return string Formation type identifier.
function LSquad:getFormation() end

--- Computes the world position for a squad member given the leader's position.
---@param member_idx number Member index (1-based).
---@param leader_x number Leader X position.
---@param leader_y number Leader Y position.
---@return number a Member's formation X and Y position.
---@return number b Member's formation X and Y position.
function LSquad:getFormationPosition(member_idx, leader_x, leader_y) end

--- Returns the spacing between members in the current formation.
---@return number Spacing in world units.
function LSquad:getFormationSpacing() end

--- Returns the current squad leader name, or nil if unset.
---@return string? Leader agent name.
function LSquad:getLeader() end

--- Returns the number of members in the squad.
---@return number Member count.
function LSquad:getMemberCount() end

--- Returns a table array of all member agent names.
---@return table Array of member name strings.
function LSquad:getMembers() end

--- Returns the squad's name.
---@return string The squad name.
function LSquad:getName() end

--- Removes an agent by name from the squad.
---@param name string Agent name to remove.
---@return nil No return value.
function LSquad:removeMember(name) end

--- Sets the squad's formation type and optional spacing.
---@param ftype string Formation name (e.g. "line", "wedge", "circle").
---@param spacing? number Distance between members in formation.
---@return nil No return value.
function LSquad:setFormation(ftype, spacing) end

--- Designates an agent as the squad leader for formation calculations.
---@param name string Agent name to set as leader.
---@return nil No return value.
function LSquad:setLeader(name) end

--- Returns the type name of this userdata object.
---@return string Always returns "LSquad".
function LSquad:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("Squad" or "Object").
---@return boolean True if the name matches.
function LSquad:typeOf(name) end

--- Lua-side wrapper around a finite state machine with states, transitions, and lifecycle callbacks. Ideal for enemies with clear behavioral phases (patrol, chase, attack, flee).
---@class LStateMachine
LStateMachine = {}

--- Registers a new state with optional onEnter, onUpdate, and onExit lifecycle callbacks.
---@param name string Unique name for this state.
---@param opts table Table with optional onEnter, onUpdate, onExit function fields.
---@return nil No return value.
function LStateMachine:addState(name, opts) end

--- Adds a conditional transition between two states, evaluated each update. When multiple transitions from the same state have true guards, the highest priority wins.
---@param from string Source state name.
---@param to string Target state name.
---@param guard? function Optional predicate function that must return true to transition.
---@param priority? number Transition priority when multiple guards are true (default 0).
---@return nil No return value.
function LStateMachine:addTransition(from, to, guard, priority) end

--- Immediately forces the FSM into a specific state, resetting time-in-state to zero.
---@param name string Name of the state to switch to.
---@return nil No return value.
function LStateMachine:forceState(name) end

--- Returns the name of the currently active state, or nil if none.
---@return string? Current state name.
function LStateMachine:getCurrentState() end

--- Returns how many seconds the FSM has spent in the current state.
---@return number Elapsed time in seconds.
function LStateMachine:getTimeInState() end

--- Sets the starting state for this state machine.
---@param name string Name of the state to start in.
---@return nil No return value.
function LStateMachine:setInitialState(name) end

--- Returns the type name of this userdata object.
---@return string Always returns "LStateMachine".
function LStateMachine:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("StateMachine" or "Object").
---@return boolean True if the name matches.
function LStateMachine:typeOf(name) end

--- Lua-side wrapper around a steering behavior manager that combines multiple movement behaviors. Use steering for smooth, physics-like autonomous movement (seek, flee, wander, flock, path follow).
---@class LSteeringManager
LSteeringManager = {}

--- Adds an arrive behavior that decelerates as the agent nears the target.
---@param tx number Target X coordinate.
---@param ty number Target Y coordinate.
---@param slowing? number Slowing radius in pixels (default 50).
---@param weight? number Behavior weight for blending (default 1.0).
---@return nil No return value.
function LSteeringManager:addArrive(tx, ty, slowing, weight) end

--- Registers a Lua function as a custom steering behavior with an optional weight.
---@param func function Callback(agent, dt) returning (fx, fy) force vector.
---@param weight? number Behavior weight for blending (default 1.0).
---@return nil No return value.
function LSteeringManager:addCustomBehavior(func, weight) end

--- Adds an evade behavior that flees from a named threat agent's predicted position.
---@param threat_name? string Name of the agent to evade.
---@param weight? number Behavior weight for blending (default 1.0).
---@return nil No return value.
function LSteeringManager:addEvade(threat_name, weight) end

--- Adds a flee behavior that steers the agent away from a threat within panic distance.
---@param tx number Threat X coordinate.
---@param ty number Threat Y coordinate.
---@param panic_dist? number Distance within which fleeing activates (default 200).
---@param weight? number Behavior weight for blending (default 1.0).
---@return nil No return value.
function LSteeringManager:addFlee(tx, ty, panic_dist, weight) end

--- Adds flocking behavior combining separation, alignment, and cohesion with nearby agents.
---@param neighbor_radius? number Radius to detect neighbors (default 100).
---@param sep_w? number Separation weight (default 1.5).
---@param align_w? number Alignment weight (default 1.0).
---@param coh_w? number Cohesion weight (default 1.0).
---@param weight? number Overall behavior weight (default 1.0).
---@return nil No return value.
function LSteeringManager:addFlock(neighbor_radius, sep_w, align_w, coh_w, weight) end

--- Adds a pursue behavior that intercepts a named target agent's predicted position.
---@param target_name? string Name of the agent to pursue.
---@param weight? number Behavior weight for blending (default 1.0).
---@return nil No return value.
function LSteeringManager:addPursue(target_name, weight) end

--- Adds a seek behavior that steers the agent directly toward a target position.
---@param tx number Target X coordinate.
---@param ty number Target Y coordinate.
---@param weight? number Behavior weight for blending (default 1.0).
---@return nil No return value.
function LSteeringManager:addSeek(tx, ty, weight) end

--- Adds a wander behavior for random exploratory movement using a projected circle.
---@param radius? number Wander circle radius (default 20).
---@param dist? number Distance of wander circle from agent (default 40).
---@param jitter? number Random jitter applied each frame (default 5).
---@param weight? number Behavior weight for blending (default 1.0).
---@return nil No return value.
function LSteeringManager:addWander(radius, dist, jitter, weight) end

--- Evaluates all registered custom steering callbacks and returns their combined force.
---@param agent_ud LAgent The agent userdata passed to each callback.
---@param dt number Delta time in seconds.
---@return number a Combined custom steering force X and Y.
---@return number b Combined custom steering force X and Y.
function LSteeringManager:applyCustomSteering(agent_ud, dt) end

--- Computes the combined steering force for the given agent state and returns the result. Apply this force to your agent's velocity each frame for smooth autonomous movement.
---@param px number Agent X position.
---@param py number Agent Y position.
---@param vx number Agent X velocity.
---@param vy number Agent Y velocity.
---@param max_speed number Agent's maximum speed.
---@param max_force number Agent's maximum force.
---@param dt number Delta time in seconds.
---@return number a Computed steering force X and Y.
---@return number b Computed steering force X and Y.
function LSteeringManager:calculate(px, py, vx, vy, max_speed, max_force, dt) end

--- Removes the current path-following behavior and its waypoints.
---@return nil No return value.
function LSteeringManager:clearPath() end

--- Enables or disables the spatial hash optimization for neighbor queries.
---@param enabled boolean True to enable spatial hashing.
---@return nil No return value.
function LSteeringManager:enableSpatialHash(enabled) end

--- Returns the number of steering behaviors currently registered.
---@return number Number of active behaviors.
function LSteeringManager:getBehaviorCount() end

--- Returns the current steering force combination mode name.
---@return string The active combine mode.
function LSteeringManager:getCombineMode() end

--- Returns the last computed steering force vector.
---@return number a X and Y components of the last force.
---@return number b X and Y components of the last force.
function LSteeringManager:getLastSteering() end

--- Returns the current waypoint index (1-based) and total waypoint count.
---@return number a Current waypoint index and total count.
---@return number b Current waypoint index and total count.
function LSteeringManager:getPathProgress() end

--- Checks whether a path-following behavior is currently active.
---@return boolean True if a path is set and not yet completed.
function LSteeringManager:hasPath() end

--- Sets how multiple steering forces are combined (e.g. "weighted", "priority", "truncated").
---@param mode string Combine mode name.
---@return nil No return value.
function LSteeringManager:setCombineMode(mode) end

--- Sets a waypoint path for path-following steering behavior.
---@param waypoints table Array of {x, y} tables defining the path.
---@param reach_radius? number Distance to consider a waypoint reached (default 12).
---@param weight? number Behavior weight for blending (default 1.0).
---@return nil No return value.
function LSteeringManager:setPath(waypoints, reach_radius, weight) end

--- Sets the cell size for the spatial hash used in neighbor lookups.
---@param size number Cell size in world units.
---@return nil No return value.
function LSteeringManager:setSpatialHashCellSize(size) end

--- Returns the type name of this userdata object.
---@return string Always returns "LSteeringManager".
function LSteeringManager:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("SteeringManager" or "Object").
---@return boolean True if the name matches.
function LSteeringManager:typeOf(name) end

--- Lua-side wrapper around a stimulus world that tracks visual and auditory signals for AI perception. Agents can detect stimuli within range to simulate sight and hearing awareness.
---@class LStimulusWorld
LStimulusWorld = {}

--- Adds an auditory stimulus with position, intensity, radius, and decay rate.
---@param x number X position.
---@param y number Y position.
---@param intensity number Signal strength.
---@param radius number Detection radius.
---@param decay_rate number How fast the stimulus fades per second.
---@param tag? string Optional tag for filtering.
---@return number Stimulus ID for later removal.
function LStimulusWorld:addAuditory(x, y, intensity, radius, decay_rate, tag) end

--- Adds a visual stimulus at a world position with intensity and detection radius.
---@param x number X position.
---@param y number Y position.
---@param intensity number Signal strength.
---@param radius number Detection radius.
---@param tag? string Optional tag for filtering.
---@return number Stimulus ID for later removal.
function LStimulusWorld:addVisual(x, y, intensity, radius, tag) end

--- Removes all stimuli from the world.
---@return nil No return value.
function LStimulusWorld:clear() end

--- Returns the number of active stimuli in the world.
---@return number Active stimulus count.
function LStimulusWorld:count() end

--- Removes a stimulus by its ID.
---@param id number Stimulus ID returned by addVisual/addAuditory.
---@return boolean True if the stimulus was found and removed.
function LStimulusWorld:remove(id) end

--- Returns the type name of this userdata object.
---@return string Always returns "LStimulusWorld".
function LStimulusWorld:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LStimulusWorld" or "Object").
---@return boolean True if the name matches.
function LStimulusWorld:typeOf(name) end

--- Advances stimulus decay timers and removes expired stimuli.
---@param dt number Delta time in seconds.
---@return nil No return value.
function LStimulusWorld:update(dt) end

--- Lua-side wrapper around a strategy AI that periodically evaluates and selects the best goal. Useful for high-level faction or commander AI that re-evaluates priorities on a timer.
---@class LStrategyAI
LStrategyAI = {}

--- Returns the name of the currently selected goal, or nil if none.
---@return string? Active goal name.
function LStrategyAI:activeGoal() end

--- Registers a named strategic goal for periodic evaluation.
---@param name string Goal name.
---@return nil No return value.
function LStrategyAI:addGoal(name) end

--- Adds a tag to filter which goals are considered during evaluation.
---@param tag string Tag to add.
---@return nil No return value.
function LStrategyAI:addTag(tag) end

--- Forces an immediate goal re-evaluation regardless of timer state.
---@param scorer_fn function Callback(goal_name) returning a score for each goal.
---@return nil No return value.
function LStrategyAI:forceEvaluate(scorer_fn) end

--- Removes a filtering tag from the strategy AI.
---@param tag string Tag to remove.
---@return nil No return value.
function LStrategyAI:removeTag(tag) end

--- Returns the seconds remaining until the next scheduled evaluation.
---@return number Time remaining in seconds.
function LStrategyAI:timeUntilNext() end

--- Returns the type name of this userdata object.
---@return string Always returns "LStrategyAI".
function LStrategyAI:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LStrategyAI" or "Object").
---@return boolean True if the name matches.
function LStrategyAI:typeOf(name) end

--- Advances the strategy timer and re-evaluates goals when the interval elapses.
---@param dt number Delta time in seconds.
---@param scorer_fn function Callback(goal_name) returning a score for each goal.
---@return nil No return value.
function LStrategyAI:update(dt, scorer_fn) end

--- Lua-side wrapper around a personality trait profile with base values and timed modifiers. Use traits to define NPC personalities (courage, aggression, friendliness) that influence AI decisions.
---@class LTraitProfile
LTraitProfile = {}

--- Adds a temporary modifier to a trait that expires after a duration.
---@param trait_name string Trait to modify.
---@param delta number Value to add to the trait.
---@param duration? number Duration in seconds (nil for permanent).
---@param source string Source identifier for later removal.
---@return nil No return value.
function LTraitProfile:addModifier(trait_name, delta, duration, source) end

--- Returns the dominant personality archetype based on trait values, or nil.
---@return string? Archetype name.
function LTraitProfile:archetype() end

--- Returns the effective trait value including all active modifiers.
---@param name string Trait name.
---@return number Effective trait value.
function LTraitProfile:get(name) end

--- Returns the base trait value without any modifiers applied.
---@param name string Trait name.
---@return number Base trait value.
function LTraitProfile:getBase(name) end

--- Checks whether a named trait exists in the profile.
---@param name string Trait name to check.
---@return boolean True if the trait is defined.
function LTraitProfile:has(name) end

--- Removes all modifiers from a specific source.
---@param source string Source identifier to match.
---@return nil No return value.
function LTraitProfile:removeModifiers(source) end

--- Sets the base value of a named personality trait.
---@param name string Trait name.
---@param value number Base value (typically 0-1).
---@return nil No return value.
function LTraitProfile:set(name, value) end

--- Returns the total number of defined traits.
---@return number Number of traits.
function LTraitProfile:traitCount() end

--- Returns the type name of this userdata object.
---@return string Always returns "LTraitProfile".
function LTraitProfile:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LTraitProfile" or "Object").
---@return boolean True if the name matches.
function LTraitProfile:typeOf(name) end

--- Advances modifier timers and removes expired ones.
---@param dt number Delta time in seconds.
---@return nil No return value.
function LTraitProfile:update(dt) end

--- Lua-side wrapper around a utility AI system that scores and selects the best action each evaluation. Best for AI with many possible actions weighted by multiple competing factors (hunger, danger, opportunity).
---@class LUtilityAI
LUtilityAI = {}

--- Registers a named action with a scorer callback and optional momentum bonus.
---@param name string Unique action name.
---@param scorer_fn function Callback returning a 0-1 score for this action.
---@param weight? number Momentum bonus when re-selecting same action (default 1.0).
---@return nil No return value.
function LUtilityAI:addAction(name, scorer_fn, weight) end

--- Adds a response-curve consideration to a specific action for fine-grained scoring.
---@param action_name string Action to attach the consideration to.
---@param name string Consideration name for debugging.
---@param scorer_fn function Callback returning a raw 0-1 input value.
---@param curve_arg string|function Response curve name or custom curve function.
---@param p1? number Curve parameter 1 (default 1.0).
---@param p2? number Curve parameter 2 (default 0.0).
---@param p3? number Curve parameter 3 (default 0.0).
---@param weight? number Consideration weight (default 1.0).
---@return nil No return value.
function LUtilityAI:addConsideration(action_name, name, scorer_fn, curve_arg, p1, p2, p3, weight) end

--- Evaluates all actions and returns the name of the highest-scoring one.
---@return string? Name of the best action, or nil if no actions registered.
function LUtilityAI:evaluate() end

--- Returns the number of registered utility actions.
---@return number Number of actions.
function LUtilityAI:getActionCount() end

--- Returns the name of the action chosen in the most recent evaluation.
---@return string? Last chosen action name, or nil if never evaluated.
function LUtilityAI:getLastAction() end

--- Returns the type name of this userdata object.
---@return string Always returns "LUtilityAI".
function LUtilityAI:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("UtilityAI" or "Object").
---@return boolean True if the name matches.
function LUtilityAI:typeOf(name) end

--- Creates a new AI director for managing game tension pacing.
---@return LAIDirector A fresh AI director instance.
lurek.ai.newAIDirector = function() end

--- Creates an AI level-of-detail system with default tier configuration.
---@return LAILod A fresh AI LOD instance.
lurek.ai.newAILod = function() end

--- Creates an action leaf node that executes a callback and returns its status.
---@param callback function Function returning "success", "failure", or "running".
---@return LBTNode A new action node.
lurek.ai.newAction = function(callback) end

--- Creates a multi-armed bandit with the given arm count, strategy, epsilon, and seed.
---@param arm_count number Number of arms.
---@param strategy string Strategy name ("epsilon_greedy", "ucb1", "thompson").
---@param epsilon number Exploration rate for epsilon-greedy.
---@param seed number Random seed.
---@return LBandit A fresh bandit instance.
lurek.ai.newBandit = function(arm_count, strategy, epsilon, seed) end

--- Creates a new behavior tree for hierarchical AI logic execution.
---@return LBehaviorTree A fresh behavior tree instance.
lurek.ai.newBehaviorTree = function() end

--- Creates a standalone blackboard for sharing key-value state data.
---@return LAIBlackboard A fresh blackboard instance.
lurek.ai.newBlackboard = function() end

--- Creates a new priority command queue for ordered AI task execution.
---@return LCommandQueue A fresh command queue instance.
lurek.ai.newCommandQueue = function() end

--- Creates a condition leaf node that checks a boolean predicate.
---@param callback function Function returning true (success) or false (failure).
---@return LBTNode A new condition node.
lurek.ai.newCondition = function(callback) end

--- Creates a context-based steering system with the given number of directional slots.
---@param slots number Number of direction slots (0 defaults to 16).
---@return LContextSteering A fresh context steering instance.
lurek.ai.newContextSteering = function(slots) end

--- Creates a new dialogue AI for state-aware topic and branch selection.
---@return LDialogueAI A fresh dialogue AI instance.
lurek.ai.newDialogueAI = function() end

--- Creates a new emotion model for tracking multiple named emotions with decay.
---@return LEmotionModel A fresh emotion model instance.
lurek.ai.newEmotionModel = function() end

--- Creates a new Goal-Oriented Action Planner for automated plan generation.
---@return LGOAPPlanner A fresh GOAP planner instance.
lurek.ai.newGOAPPlanner = function() end

--- Creates a new genetic algorithm with specified population size, gene count, and seed.
---@param pop_size number Population size.
---@param gene_count number Number of genes per chromosome.
---@param seed number Random seed.
---@return LGeneticAlgorithm A fresh genetic algorithm instance.
lurek.ai.newGeneticAlgorithm = function(pop_size, gene_count, seed) end

--- Creates a guard decorator that only executes its child when the predicate is true.
---@param predicate function Guard function returning true to allow child execution.
---@param child_ud LBTNode Child node to guard.
---@return LBTNode A new guard node.
lurek.ai.newGuard = function(predicate, child_ud) end

--- Creates a new HTN domain for hierarchical task network planning.
---@return LHTNDomain A fresh HTN domain instance.
lurek.ai.newHTNDomain = function() end

--- Creates a new grid-based influence map for spatial AI reasoning.
---@param w number Grid width in cells.
---@param h number Grid height in cells.
---@param cs number Cell size in world units.
---@return LInfluenceMap A fresh influence map instance.
lurek.ai.newInfluenceMap = function(w, h, cs) end

--- Creates an inverter decorator that negates its child's result.
---@return LBTNode A new inverter node.
lurek.ai.newInverter = function() end

--- Creates a new MCTS engine with specified iteration count, UCT constant, depth, and seed.
---@param iters number Number of MCTS iterations per search.
---@param uct_c number UCT exploration constant (typically ~1.41).
---@param depth number Maximum rollout depth.
---@param seed number Random seed for reproducibility.
---@return LMCTSEngine A fresh MCTS engine instance.
lurek.ai.newMCTSEngine = function(iters, uct_c, depth, seed) end

--- Creates a new need system for modeling agent drives and urgency.
---@return LNeedSystem A fresh need system instance.
lurek.ai.newNeedSystem = function() end

--- Creates a new empty feedforward neural network (add layers before use).
---@return LNeuralNet A fresh neural network instance.
lurek.ai.newNeuralNet = function() end

--- Creates a neuroevolution system combining genetic algorithms with neural networks.
---@param layer_spec table Array of {inputs, outputs, activation} layer definitions.
---@param pop_size number Population size.
---@param seed number Random seed.
---@return LNeuroevolution A fresh neuroevolution instance.
lurek.ai.newNeuroevolution = function(layer_spec, pop_size, seed) end

--- Creates a new ORCA collision avoidance solver with the given time horizon.
---@param time_horizon number Look-ahead time for velocity obstacles.
---@return LORCASolver A fresh ORCA solver instance.
lurek.ai.newORCASolver = function(time_horizon) end

--- Creates a parallel node that runs all children simultaneously with configurable policies.
---@param sp? string?|Success policy(\"requireOne\" or \"requireAll\").\n    /// @param|fp|string Failure policy (\"requireOne\" or \"requireAll\").
---@param fp? LuaValue
---@return LBTNode A new parallel node.
lurek.ai.newParallel = function(sp, fp) end

--- Creates a new tabular Q-learning agent with the given state and action counts.
---@param sc number Number of states.
---@param ac number Number of actions.
---@return LQLearner A fresh Q-learner instance.
lurek.ai.newQLearner = function(sc, ac) end

--- Creates a repeater decorator that re-runs its child a specified number of times.
---@param count? number Repetitions (0 or nil for infinite).
---@return LBTNode A new repeater node.
lurek.ai.newRepeater = function(count) end

--- Creates a selector node that succeeds when any child succeeds (OR logic).
---@return LBTNode A new selector node.
lurek.ai.newSelector = function() end

--- Creates a sequence node that succeeds only when all children succeed (AND logic).
---@return LBTNode A new sequence node.
lurek.ai.newSequence = function() end

--- Creates a new squad for organizing agents into formations with shared state.
---@param name string Squad name.
---@return LSquad A fresh squad instance.
lurek.ai.newSquad = function(name) end

--- Creates a new finite state machine for state-based AI decision making.
---@return LStateMachine A fresh FSM instance.
lurek.ai.newStateMachine = function() end

--- Creates a new steering behavior manager for combining movement behaviors.
---@return LSteeringManager A fresh steering manager instance.
lurek.ai.newSteeringManager = function() end

--- Creates a new stimulus world for tracking AI perception signals.
---@return LStimulusWorld A fresh stimulus world instance.
lurek.ai.newStimulusWorld = function() end

--- Creates a strategy AI that periodically re-evaluates goals at the given interval.
---@param update_interval number Seconds between evaluations.
---@return LStrategyAI A fresh strategy AI instance.
lurek.ai.newStrategyAI = function(update_interval) end

--- Creates a succeeder decorator that always returns success regardless of child result.
---@return LBTNode A new succeeder node.
lurek.ai.newSucceeder = function() end

--- Creates a new personality trait profile with modifiable traits.
---@return LTraitProfile A fresh trait profile instance.
lurek.ai.newTraitProfile = function() end

--- Creates a new utility AI system for scoring and selecting the best action.
---@return LUtilityAI A fresh utility AI instance.
lurek.ai.newUtilityAI = function() end

--- Creates a new AI world container for managing agents and their decision models.
---@return LAIWorld A fresh AI world instance.
lurek.ai.newWorld = function() end

---@class lurek.animation
lurek.animation = {}

--- Lua-side wrapper around a keyframe-based animation curve for interpolating numeric values over time with configurable easing functions.
---@class LAnimCurve
LAnimCurve = {}

--- Inserts a keyframe at the given time with the specified value. Keyframes are automatically sorted by time. The curve interpolates between adjacent keyframes using the active easing function.
---@param t number Time position for this keyframe (in seconds or any consistent unit).
---@param v number The value at this keyframe (position, opacity, scale, etc.).
---@return nil No return value.
function LAnimCurve:addKeyframe(t, v) end

--- Removes all keyframes from the curve, resetting it to an empty state ready for new keyframe definitions.
---@return nil No return value.
function LAnimCurve:clear() end

--- Evaluates the curve at the given time, returning the interpolated value between surrounding keyframes using the active easing function. Before the first keyframe returns its value; after the last keyframe returns the last value.
---@param t number Time position to sample the curve at (same unit as keyframe times).
---@return number The interpolated value at time t.
function LAnimCurve:eval(t) end

--- Returns the total number of keyframes defined in this curve. Useful for verifying curve setup or debugging.
---@return number The number of keyframes added to this curve.
function LAnimCurve:keyframeCount() end

--- Sets a custom Lua function as the easing interpolator, allowing arbitrary easing curves. The function receives a normalized time t (0.0 to 1.0) and must return the eased value. Pass nil to reset to the built-in linear easing.
---@param func? function A function(t) returning the eased value for the given progress, or nil to clear custom easing.
---@return nil No return value.
function LAnimCurve:setCustomEasing(func) end

--- Sets the built-in easing function used for interpolation between all keyframes. Affects how values transition: "step" snaps instantly, "linear" interpolates evenly, and ease variants add acceleration curves.
---@param mode string One of: "step" (instant jump), "linear" (constant rate), "ease_in" (slow start), "ease_out" (slow end), "ease_in_out" (slow start and end).
---@return nil No return value.
function LAnimCurve:setEasing(mode) end

--- Returns the type name of this userdata object for runtime type checking.
---@return string Always returns "LAnimCurve".
function LAnimCurve:type() end

--- Checks whether this object matches the given type name. Accepts "LAnimCurve" or "Object".
---@param name string Type name to check against.
---@return boolean True if the name matches this type or its base type.
function LAnimCurve:typeOf(name) end

--- Lua-side wrapper around the animation state machine controller, which drives clip transitions based on named parameters and condition expressions.
---@class LAnimStateMachine
LAnimStateMachine = {}

--- Registers a new state that maps to a named animation clip. States represent discrete animation poses (e.g., "idle", "walk", "jump") and can be connected by transitions.
---@param name string Unique state identifier used in transitions and forceState.
---@param clip string Name of the animation clip this state plays when active.
---@param looping boolean Whether the clip loops in this state (true for walk/idle, false for one-shot attacks).
---@return nil No return value.
function LAnimStateMachine:addState(name, clip, looping) end

--- Adds a conditional transition between two states that is evaluated each frame during update(). When the condition becomes true, the state machine switches from the source to the destination state.
---@param fromState string Source state name (transition triggers only when this state is active).
---@param toState string Destination state name to switch to when the condition is met.
---@param condition string Parameter condition expression (e.g., "speed > 0", "grounded == true").
---@return nil No return value.
function LAnimStateMachine:addTransition(fromState, toState, condition) end

--- Forces an immediate transition to the named state, bypassing all condition checks. Useful for cutscenes, respawns, or overriding the normal state flow.
---@param name string Name of the state to switch to immediately.
---@return boolean True if the state was found and activated, false if no state with that name exists.
function LAnimStateMachine:forceState(name) end

--- Returns the source rectangle of the current frame from the state machine's active animation state. Use with lurek.graphics.drawQuad to render the correct sprite.
---@return table? A table with x, y, w, h fields for texture sampling, or nil if no frame is active.
function LAnimStateMachine:getQuad() end

--- Returns the name of the currently active state in the state machine.
---@return string The current state name (e.g., "idle", "walk", "attack").
function LAnimStateMachine:getState() end

--- Sets a named parameter value used by transition condition expressions. Update parameters each frame based on game state (e.g., velocity, grounded flag) to drive automatic transitions.
---@param name string Parameter name referenced in condition expressions.
---@param value boolean|number|number The parameter value (type must match what the condition expects).
---@return nil No return value.
function LAnimStateMachine:setParam(name, value) end

--- Returns the type name of this userdata object for runtime type checking.
---@return string Always returns "LAnimStateMachine".
function LAnimStateMachine:type() end

--- Checks whether this object matches the given type name. Accepts "LAnimStateMachine" or "Object".
---@param name string Type name to check against.
---@return boolean True if the name matches this type or its base type.
function LAnimStateMachine:typeOf(name) end

--- Advances the state machine by the given delta time, evaluating all transition conditions and switching states when triggered. Call once per frame after setting parameters.
---@param dt number Elapsed time in seconds since the last update.
---@return nil No return value.
function LAnimStateMachine:update(dt) end

--- Lua-side wrapper around the animation synchronization group, which keeps multiple animations playing in lockstep for coordinated multi-entity animations.
---@class LAnimSyncGroup
LAnimSyncGroup = {}

--- Adds an animation to the synchronization group so its playback stays aligned with other group members.
---@param handle LAnimation The animation to synchronize with the group.
---@return nil No return value.
function LAnimSyncGroup:add(handle) end

--- Removes all animations from the synchronization group, disbanding the sync relationship.
---@return nil No return value.
function LAnimSyncGroup:clear() end

--- Returns the number of animations currently synchronized in this group.
---@return number The number of group members.
function LAnimSyncGroup:memberCount() end

--- Removes an animation from the synchronization group, letting it play independently again.
---@param handle LAnimation The animation to detach from the group.
---@return nil No return value.
function LAnimSyncGroup:remove(handle) end

--- Returns the type name of this userdata object for runtime type checking.
---@return string Always returns "LAnimSyncGroup".
function LAnimSyncGroup:type() end

--- Checks whether this object matches the given type name. Accepts "LAnimSyncGroup" or "Object".
---@param name string Type name to check against.
---@return boolean True if the name matches this type or its base type.
function LAnimSyncGroup:typeOf(name) end

--- Lua-side wrapper around the sprite-sheet Animation controller, managing frames, named clips, playback state, crossfade blending, and animation events.
---@class LAnimation
LAnimation = {}

--- Defines a named animation clip from a sequence of frame indices. Clips are reusable animation sequences (e.g., "walk", "attack", "idle") that can be played, crossfaded, or used in state machines.
---@param name string Unique identifier for this clip (used to play or reference it later).
---@param indices table Array of zero-based frame indices that compose this clip's sequence.
---@param fps number Playback speed in frames per second (e.g., 12 for standard animation, 24 for smooth).
---@param looping boolean Whether the clip repeats from the beginning after the last frame.
---@param mode? string Playback direction: "forward" (default), "reverse", or "pingpong" (plays forward then backward).
---@return nil No return value.
function LAnimation:addClip(name, indices, fps, looping, mode) end

--- Creates a named clip by slicing frames directly from a grid region of the texture atlas in one call. Combines addFramesFromGrid + addClip for convenience when each clip occupies a contiguous row or range in the sheet.
---@param name string Unique identifier for this clip.
---@param tw number Total texture atlas width in pixels.
---@param th number Total texture atlas height in pixels.
---@param fw number Width of each frame cell in pixels.
---@param fh number Height of each frame cell in pixels.
---@param start number Zero-based index of the first grid cell for this clip.
---@param count number Number of consecutive grid cells to include in the clip.
---@param fps number Playback speed in frames per second.
---@param looping boolean Whether the clip repeats after reaching the last frame.
---@return nil No return value.
function LAnimation:addClipFromGrid(name, tw, th, fw, fh, start, count, fps, looping) end

--- Adds a single frame rectangle to the animation by specifying its pixel region in the source texture atlas. Use this for irregular or manually positioned frames.
---@param x number Left edge of the frame in the texture atlas (pixels from left).
---@param y number Top edge of the frame in the texture atlas (pixels from top).
---@param w number Width of the frame region in pixels.
---@param h number Height of the frame region in pixels.
---@return number The zero-based index of the newly added frame, usable in clip definitions.
function LAnimation:addFrame(x, y, w, h) end

--- Generates frame rectangles by slicing a uniform grid from the texture atlas. Ideal for sprite sheets where all frames are the same size arranged in rows and columns.
---@param tw number Total texture atlas width in pixels.
---@param th number Total texture atlas height in pixels.
---@param fw number Width of each individual frame cell in pixels.
---@param fh number Height of each individual frame cell in pixels.
---@param start number Zero-based index of the first cell to include (counted left-to-right, top-to-bottom).
---@param count number Number of consecutive cells to add starting from the start index.
---@return number The number of frames actually added to the animation.
function LAnimation:addFramesFromGrid(tw, th, fw, fh, start, count) end

--- Adds multiple frames from an array of rectangle tables, useful for texture atlases with non-uniform frame sizes (e.g., packed sprite sheets).
---@param rects table Array of tables, each containing x, y, w, h number fields defining a frame region.
---@return number The number of frames successfully added.
function LAnimation:addFramesFromRects(rects) end

--- Smoothly transitions from the current clip to another over a specified duration, blending between the two frame sources. Use this for polished animation transitions (e.g., walk-to-run, idle-to-jump).
---@param clipName string Name of the target clip to blend into.
---@param duration number Crossfade blend duration in seconds (e.g., 0.2 for quick, 0.5 for smooth).
---@return boolean True if the crossfade was started successfully, false if the clip was not found.
function LAnimation:crossfade(clipName, duration) end

--- Renders all registered frames into a grid preview image for debugging or asset inspection. Each frame is drawn into its own cell.
---@param columns number Number of columns in the grid layout.
---@param cellSize number Width and height of each grid cell in pixels.
---@return LImage A new image showing all frames arranged in a grid.
function LAnimation:drawPreviewGrid(columns, cellSize) end

--- Renders the current animation frame into an image of the specified size. Useful for generating thumbnails, UI previews, or off-screen rendering of animated sprites.
---@param w number Output image width in pixels.
---@param h number Output image height in pixels.
---@return LImage A new image containing the rendered frame.
function LAnimation:drawToImage(w, h) end

--- Returns the current crossfade blend state between two frames during a transition. Use this to render a weighted mix of two sprite frames for smooth visual blending.
---@return table? A table with "from" (rect table), "to" (rect table), and "blend" (0.0-1.0 interpolation factor), or nil if not currently blending.
function LAnimation:getBlendState() end

--- Returns the name of the currently active clip, useful for conditional logic based on animation state.
---@return string? The clip name (e.g., "walk", "idle"), or nil if no clip is playing.
function LAnimation:getClip() end

--- Returns the total number of named clips defined in this animation object.
---@return number The number of defined clips.
function LAnimation:getClipCount() end

--- Returns the current playback direction of a named clip, useful for checking or restoring state.
---@param name string Name of the clip to query.
---@return string? The mode string ("forward", "reverse", or "pingpong"), or nil if no clip with that name exists.
function LAnimation:getClipMode(name) end

--- Returns the zero-based index of the currently displayed frame within the active clip's sequence.
---@return number The current frame index (0-based).
function LAnimation:getCurrentFrame() end

--- Returns the total number of frame rectangles registered in this animation (across all clips).
---@return number The total frame count.
function LAnimation:getFrameCount() end

--- Returns the source rectangle of the current frame for texture sampling. Use this with lurek.graphics.drawQuad to render the correct sprite region from your atlas.
---@return table? A table with x, y, w, h fields defining the texture region, or nil if no frame is active.
function LAnimation:getQuad() end

--- Returns the global playback speed multiplier applied to all clips.
---@return number The current speed factor (1.0 = normal, 0.5 = half speed, 2.0 = double speed).
function LAnimation:getSpeed() end

--- Returns whether the currently active clip is configured to loop. Non-looping clips stop after reaching their last frame.
---@return boolean True if the active clip loops, false if it plays once and stops.
function LAnimation:isLooping() end

--- Returns whether an animation clip is currently playing (not stopped or paused).
---@return boolean True if the animation is actively advancing frames.
function LAnimation:isPlaying() end

--- Pauses the current playback without resetting the frame position. The animation freezes on the current frame until resume() is called.
---@return nil No return value.
function LAnimation:pause() end

--- Starts playing the named clip from its first frame, replacing any currently active clip immediately without blending.
---@param name string Name of the clip to play (must have been added with addClip or addClipFromGrid).
---@return boolean True if the clip was found and playback started, false if no clip with that name exists.
function LAnimation:play(name) end

--- Drains and returns all animation events that accumulated since the last poll. Events include clip completion, loop restart, and frame triggers. Call this each frame after update() to react to animation milestones.
---@return table Array of event tables, each with a "type" field (e.g., "clip_ended", "looped") and optional "frame" field.
function LAnimation:pollEvents() end

--- Resumes playback from the exact frame and time offset where it was paused.
---@return nil No return value.
function LAnimation:resume() end

--- Changes the playback direction of an existing clip at runtime. Useful for reversing an animation (e.g., closing a door uses the opening clip in reverse).
---@param name string Name of the clip to modify.
---@param mode string New playback mode: "forward", "reverse", or "pingpong" (oscillates).
---@return boolean True if the clip was found and updated, false if no clip with that name exists.
function LAnimation:setClipMode(name, mode) end

--- Jumps directly to a specific frame index without affecting playback state. Useful for manually controlling frame display or implementing custom playback logic.
---@param index number Zero-based frame index to display immediately.
---@return nil No return value.
function LAnimation:setFrame(index) end

--- Sets the global playback speed multiplier affecting all clips. Useful for slow-motion effects or speed-up during fast-forward.
---@param speed number Speed factor: 1.0 = normal, 0.5 = half speed, 2.0 = double speed, 0 = frozen.
---@return nil No return value.
function LAnimation:setSpeed(speed) end

--- Stops playback completely and resets the animation to an idle state. The current frame returns to the first frame of the last played clip.
---@return nil No return value.
function LAnimation:stop() end

--- Returns the type name of this userdata object for runtime type checking.
---@return string Always returns "LAnimation".
function LAnimation:type() end

--- Checks whether this object matches the given type name. Accepts "LAnimation" or "Object".
---@param name string Type name to check against.
---@return boolean True if the name matches this type or its base type.
function LAnimation:typeOf(name) end

--- Advances the animation timer by the given delta time, progressing to the next frame when enough time has elapsed. Call this once per frame in your game loop.
---@param dt number Elapsed time in seconds since the last update (typically from lurek.timer.getDelta()).
---@return nil No return value.
function LAnimation:update(dt) end

--- Lua-side wrapper around the animation blend layer set for layered clip mixing. Allows combining multiple animation clips with independent weights and bone masks for partial body animation (e.g., upper body attack while legs walk).
---@class LBlendLayerSet
LBlendLayerSet = {}

--- Adds a named blend layer with a clip, weight, and optional bone mask. Layers stack together to produce the final animation output, with each layer contributing proportionally to its weight.
---@param name string Unique layer identifier for later reference.
---@param clipName string Animation clip to assign to this layer.
---@param weight number Blend weight from 0.0 (no contribution) to 1.0 (full contribution).
---@param bones? table Optional array of bone name strings to restrict this layer to specific body parts. Nil means all bones.
---@return boolean True if the layer was added successfully.
function LBlendLayerSet:addLayer(name, clipName, weight, bones) end

--- Returns the current blend weight of a named layer for inspection or interpolation logic.
---@param name string Layer name to query.
---@return number? The weight value (0.0 to 1.0), or nil if no layer with that name exists.
function LBlendLayerSet:getWeight(name) end

--- Returns the number of blend layers currently in this set.
---@return number The layer count.
function LBlendLayerSet:len() end

--- Returns a table describing all layers in the set with their names, assigned clips, weights, and bone masks. Useful for debugging blend setups or building editor UIs.
---@return table Array of tables, each with name (string), clip_name (string), weight (number), and bones (string array) fields.
function LBlendLayerSet:listLayers() end

--- Removes a blend layer by name from the set. The layer's contribution is immediately removed from the blend output.
---@param name string Name of the layer to remove.
---@return boolean True if the layer was found and removed, errors if the layer does not exist.
function LBlendLayerSet:removeLayer(name) end

--- Replaces the bone mask of a named layer with a new set of bone names. Only the listed bones will be affected by this layer's animation, allowing partial body overrides.
---@param name string Layer name to update.
---@param bones table Array of bone name strings that this layer should control.
---@return boolean True if the layer was found and its mask updated.
function LBlendLayerSet:setMask(name, bones) end

--- Sets the blend weight of a named layer at runtime. Animate this value over time to smoothly fade layers in or out (e.g., transition between walk and run by adjusting weights).
---@param name string Layer name to update.
---@param weight number New blend weight from 0.0 (silent) to 1.0 (full strength).
---@return boolean True if the layer was found and updated.
function LBlendLayerSet:setWeight(name, weight) end

--- Returns the type name of this userdata object for runtime type checking.
---@return string Always returns "LBlendLayerSet".
function LBlendLayerSet:type() end

--- Checks whether this object matches the given type name. Accepts "LBlendLayerSet" or "Object".
---@param name string Type name to check against.
---@return boolean True if the name matches this type or its base type.
function LBlendLayerSet:typeOf(name) end

--- Creates a complete character animation setup from a single configuration table. Automatically generates frames from a grid, defines clips, and optionally creates a state machine with transitions — all in one call. Ideal for quickly setting up player or NPC animations.
---@param cfg table Configuration with texW, texH, frameW, frameH, clips (array of {name, start, count, fps?, looping?, mode?}), and optional states, transitions, initialClip, initialState fields.
---@return table A table containing "animation" (LAnimation) and optionally "stateMachine" (LAnimStateMachine) if states were provided.
lurek.animation.buildCharacter = function(cfg) end

--- Loads a complete animation from an Aseprite JSON export string, automatically creating frames from the sprite data and clips from each tag. This is the fastest way to set up animations exported from Aseprite.
---@param jsonStr string The raw JSON content exported from Aseprite (File > Export Sprite Sheet with JSON output).
---@return LAnimation A fully configured animation with all frames and tag-based clips ready to play.
lurek.animation.fromAseprite = function(jsonStr) end

--- Creates a new empty animation object ready to receive frames and clips. Start by adding frames with addFrame or addFramesFromGrid, then define clips with addClip.
---@return LAnimation A fresh animation instance with no frames or clips defined.
lurek.animation.new = function() end

--- Creates a new blend layer set for layered clip mixing with per-bone masks. Use blend layers to combine multiple animations simultaneously (e.g., upper body aiming while lower body walks).
---@return LBlendLayerSet An empty blend layer set ready for layer additions.
lurek.animation.newBlendLayerSet = function() end

--- Creates a new animation curve for keyframe-based value interpolation over time. Use curves to animate any numeric property (position, opacity, scale) with custom easing between keyframes.
---@return LAnimCurve An empty curve ready to receive keyframes via addKeyframe().
lurek.animation.newCurve = function() end

--- Creates a new animation state machine from an animation and an initial state name. The state machine automatically transitions between clips based on parameter conditions, perfect for character controllers.
---@param animation LAnimation The animation containing clips that states will reference (consumed — do not reuse the animation object).
---@param initial string Name of the starting state (must be added via addState before the first update).
---@return LAnimStateMachine A new state machine controller ready for state and transition definitions.
lurek.animation.newStateMachine = function(animation, initial) end

--- Creates a new synchronization group that keeps multiple animations aligned in time. When animations share a sync group, their playback positions stay in lockstep regardless of frame rate differences.
---@return LAnimSyncGroup An empty sync group ready to receive animation members.
lurek.animation.newSyncGroup = function() end

---@class lurek.audio
lurek.audio = {}

--- Lua-side wrapper around an audio mixing bus for grouped volume and effect control.
---@class LBus
LBus = {}

--- Removes the ducking configuration from this bus.
---@return nil No return value.
function LBus:clearDuck() end

--- Returns the name of this audio bus.
---@return string Bus name as registered during creation.
function LBus:getName() end

--- Returns the current peak amplitude level of this bus for VU-meter displays.
---@return number Peak level from 0.0 to 1.0.
function LBus:getPeak() end

--- Returns the current pitch multiplier of this bus.
---@return number Current pitch multiplier (defaults to 1.0).
function LBus:getPitch() end

--- Returns the current volume multiplier of this bus.
---@return number Volume multiplier (defaults to 1.0).
function LBus:getVolume() end

--- Returns whether this bus is currently paused.
---@return boolean True if the bus is paused.
function LBus:isPaused() end

--- Pauses all sources routed through this bus.
---@return nil No return value.
function LBus:pause() end

--- Resumes all sources routed through this bus that were paused.
---@return nil No return value.
function LBus:resume() end

--- Configures ducking so this bus lowers the volume of a target bus when active.
---@param target_name string Name of the bus to duck.
---@param duck_vol number Volume multiplier applied to the target when ducking (0.0-1.0).
---@return nil No return value.
function LBus:setDuckTarget(target_name, duck_vol) end

--- Sets the pitch multiplier applied to all sources routed through this bus.
---@param pitch number Pitch multiplier (1.0 = normal speed).
---@return nil No return value.
function LBus:setPitch(pitch) end

--- Sets the volume multiplier for all sources routed through this bus.
---@param vol number Volume multiplier (0.0 = silent, 1.0 = normal).
---@return nil No return value.
function LBus:setVolume(vol) end

--- Returns the type name of this object for runtime type-checking.
---@return string Always returns "LBus".
function LBus:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check (e.g. "LBus", "Bus", or "Object").
---@return boolean True if this object matches the given type.
function LBus:typeOf(name) end

--- Lua-side wrapper around a streaming audio decoder for incremental PCM extraction.
---@class LDecoder
LDecoder = {}

--- Decodes the next chunk of audio data and returns it as a SoundData object.
---@return SoundData? Decoded PCM data, or nil if end of stream reached.
function LDecoder:decode() end

--- Returns the bit depth of the source audio file.
---@return number Bits per sample (e.g. 16, 24).
function LDecoder:getBitDepth() end

--- Returns the number of audio channels in the source file.
---@return number Channel count (1 = mono, 2 = stereo).
function LDecoder:getChannelCount() end

--- Returns the total duration of the source audio file in seconds.
---@return number Duration in seconds.
function LDecoder:getDuration() end

--- Returns the sample rate of the source audio file.
---@return number Sample rate in Hz.
function LDecoder:getSampleRate() end

--- Returns whether this decoder supports seeking.
---@return boolean True if seek operations are supported.
function LDecoder:isSeekable() end

--- Releases decoder resources (no-op, kept for API symmetry).
---@return nil No return value.
function LDecoder:release() end

--- Rewinds the decoder back to the beginning of the audio stream.
---@return nil No return value.
function LDecoder:rewind() end

--- Seeks to a specific position in the audio stream.
---@param offset number Target position in seconds.
---@return nil No return value.
function LDecoder:seek(offset) end

--- Returns the current read position in the audio stream in seconds.
---@return number Current position in seconds.
function LDecoder:tell() end

--- Returns the type name of this object for runtime type-checking.
---@return string Always returns "LDecoder".
function LDecoder:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check (e.g. "LDecoder" or "Object").
---@return boolean True if this object matches the given type.
function LDecoder:typeOf(name) end

--- Lua-side wrapper around a MIDI file player with per-channel control and tempo scaling.
---@class LMidiPlayer
LMidiPlayer = {}

--- Returns the audio bus this MIDI player is routed through.
---@return LBus? The assigned bus, or nil if using direct output.
function LMidiPlayer:getBus() end

--- Returns the number of active MIDI channels in the loaded file.
---@return number Number of active channels.
function LMidiPlayer:getChannelCount() end

--- Returns the current GM instrument program for a channel.
---@param ch number Channel number (1-16).
---@return number GM instrument program number (0-127).
function LMidiPlayer:getChannelInstrument(ch) end

--- Returns the volume of a specific MIDI channel.
---@param ch number Channel number (1-16).
---@return number Channel volume (0.0-1.0).
function LMidiPlayer:getChannelVolume(ch) end

--- Returns the number of output audio channels for MIDI synthesis.
---@return number Channel count (1 = mono, 2 = stereo).
function LMidiPlayer:getChannels() end

--- Returns the total duration of the loaded MIDI file in seconds.
---@return number Duration in seconds.
function LMidiPlayer:getDuration() end

--- Returns the file path of the currently loaded MIDI file.
---@return string? File path string or nil if no file is loaded.
function LMidiPlayer:getFilePath() end

--- Returns the total number of note events in the loaded MIDI file.
---@return number Total note count.
function LMidiPlayer:getNoteCount() end

--- Returns the original tempo of the MIDI file as authored.
---@return number Original tempo in BPM.
function LMidiPlayer:getOriginalTempo() end

--- Returns the output sample rate used for MIDI synthesis.
---@return number Sample rate in Hz (e.g. 44100).
function LMidiPlayer:getSampleRate() end

--- Returns the path of the currently set SoundFont (stub, not yet implemented).
---@return string? SoundFont path or nil.
function LMidiPlayer:getSoundFontPath() end

--- Returns the current effective tempo in beats per minute.
---@return number Current tempo in BPM.
function LMidiPlayer:getTempo() end

--- Returns the current tempo scale multiplier.
---@return number Tempo scale factor.
function LMidiPlayer:getTempoScale() end

--- Returns the MIDI file's resolution in ticks per beat (PPQN).
---@return number Ticks per quarter note.
function LMidiPlayer:getTicksPerBeat() end

--- Returns the number of tracks in the loaded MIDI file.
---@return number Number of MIDI tracks.
function LMidiPlayer:getTrackCount() end

--- Returns the name of a MIDI track by 1-based index.
---@param idx number Track index (1-based).
---@return string? Track name or nil if not available.
function LMidiPlayer:getTrackName(idx) end

--- Returns the current master volume of the MIDI player.
---@return number Volume multiplier.
function LMidiPlayer:getVolume() end

--- Returns whether a specific MIDI channel is muted.
---@param ch number Channel number (1-16).
---@return boolean True if the channel is muted.
function LMidiPlayer:isChannelMuted(ch) end

--- Returns whether a MIDI file is currently loaded and ready to play.
---@return boolean True if a MIDI file is loaded.
function LMidiPlayer:isLoaded() end

--- Returns whether MIDI looping is enabled.
---@return boolean True if looping.
function LMidiPlayer:isLooping() end

--- Returns whether the MIDI player is currently paused.
---@return boolean True if paused.
function LMidiPlayer:isPaused() end

--- Returns whether the MIDI player is currently playing.
---@return boolean True if playing.
function LMidiPlayer:isPlaying() end

--- Returns whether a specific MIDI track is muted.
---@param idx number Track index (1-based).
---@return boolean True if the track is muted.
function LMidiPlayer:isTrackMuted(idx) end

--- Loads a MIDI file from the given path relative to the game directory.
---@param path string Relative path to the .mid file.
---@return boolean True if the file was loaded successfully.
function LMidiPlayer:load(path) end

--- Loads MIDI data from a raw byte string in memory.
---@param data string Raw MIDI binary data.
---@return boolean True if the data was parsed successfully.
function LMidiPlayer:loadData(data) end

--- Pauses MIDI playback at the current position.
---@return nil No return value.
function LMidiPlayer:pause() end

--- Starts MIDI playback from the current position using the audio output stream.
---@return nil No return value.
function LMidiPlayer:play() end

--- Seeks to a specific position in the MIDI file.
---@param secs number Target position in seconds.
---@return nil No return value.
function LMidiPlayer:seek(secs) end

--- Routes this MIDI player's output through the specified audio bus.
---@param bus? LBus Bus to route through, or nil for direct output.
---@return nil No return value.
function LMidiPlayer:setBus(bus) end

--- Sets the General MIDI instrument program for a channel.
---@param ch number Channel number (1-16).
---@param inst number GM instrument program number (0-127).
---@return nil No return value.
function LMidiPlayer:setChannelInstrument(ch, inst) end

--- Mutes or unmutes a specific MIDI channel.
---@param ch number Channel number (1-16).
---@param muted boolean True to mute, false to unmute.
---@return nil No return value.
function LMidiPlayer:setChannelMuted(ch, muted) end

--- Sets the volume for a specific MIDI channel (1-16).
---@param ch number Channel number (1-16).
---@param vol number Volume multiplier (0.0-1.0).
---@return nil No return value.
function LMidiPlayer:setChannelVolume(ch, vol) end

--- Sets the number of output audio channels for MIDI synthesis.
---@param channels number Channel count (1 = mono, 2 = stereo).
---@return nil No return value.
function LMidiPlayer:setChannels(channels) end

--- Enables or disables looping for MIDI playback.
---@param looping boolean True to loop, false to play once.
---@return nil No return value.
function LMidiPlayer:setLooping(looping) end

--- Registers a callback invoked when MIDI playback finishes (stub, not yet implemented).
---@param cb? function Callback function or nil to clear.
---@return nil No return value.
function LMidiPlayer:setOnEnd(cb) end

--- Registers a callback for MIDI note-off events (stub, not yet implemented).
---@param cb? function Callback function or nil to clear.
---@return nil No return value.
function LMidiPlayer:setOnNoteOff(cb) end

--- Registers a callback for MIDI note-on events (stub, not yet implemented).
---@param cb? function Callback function or nil to clear.
---@return nil No return value.
function LMidiPlayer:setOnNoteOn(cb) end

--- Sets the output sample rate for MIDI synthesis.
---@param rate number Sample rate in Hz (e.g. 44100, 48000).
---@return nil No return value.
function LMidiPlayer:setSampleRate(rate) end

--- Sets a custom SoundFont file for MIDI synthesis (stub, not yet implemented).
---@param path string Relative path to the .sf2 file.
---@return nil No return value.
function LMidiPlayer:setSoundFont(path) end

--- Sets the playback tempo in beats per minute.
---@param bpm number Desired tempo in BPM.
---@return nil No return value.
function LMidiPlayer:setTempo(bpm) end

--- Sets a tempo multiplier relative to the original speed.
---@param scale number Tempo scale (1.0 = original, 2.0 = double speed).
---@return nil No return value.
function LMidiPlayer:setTempoScale(scale) end

--- Mutes or unmutes a specific MIDI track.
---@param idx number Track index (1-based).
---@param muted boolean True to mute, false to unmute.
---@return nil No return value.
function LMidiPlayer:setTrackMuted(idx, muted) end

--- Sets the master volume for MIDI playback.
---@param vol number Volume multiplier (0.0 = silent, 1.0 = normal).
---@return nil No return value.
function LMidiPlayer:setVolume(vol) end

--- Solos a specific MIDI channel, muting all others.
---@param ch number Channel number (1-16) to solo.
---@return nil No return value.
function LMidiPlayer:soloChannel(ch) end

--- Stops MIDI playback and resets position to the beginning.
---@return nil No return value.
function LMidiPlayer:stop() end

--- Returns the current playback position of the MIDI player in seconds.
---@return number Current position in seconds.
function LMidiPlayer:tell() end

--- Returns the type name of this object for runtime type-checking.
---@return string Always returns "LMidiPlayer".
function LMidiPlayer:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check (e.g. "LMidiPlayer", "MidiPlayer", or "Object").
---@return boolean True if this object matches the given type.
function LMidiPlayer:typeOf(name) end

--- Removes solo from all channels, restoring normal playback.
---@return nil No return value.
function LMidiPlayer:unsoloAll() end

--- Reverts to the built-in default SoundFont (stub, not yet implemented).
---@return nil No return value.
function LMidiPlayer:useDefaultSoundFont() end

---@class LSoundData
LSoundData = {}

function LSoundData:drawWaveform() end

function LSoundData:getBitDepth() end

function LSoundData:getChannelCount() end

function LSoundData:getDuration() end

---@param index LuaValue
function LSoundData:getSample(index) end

function LSoundData:getSampleCount() end

function LSoundData:getSampleRate() end

---@param index LuaValue
---@param value LuaValue
function LSoundData:setSample(index, value) end

--- Lua-side wrapper around a pre-allocated pool of identical sound voices for rapid fire effects.
---@class LSoundPool
LSoundPool = {}

--- Returns the number of pre-allocated voices in this pool.
---@return number Voice count.
function LSoundPool:getVoiceCount() end

--- Plays the next available voice from the pool in round-robin order.
---@return number Numeric source ID of the voice that started playing.
function LSoundPool:play() end

--- Releases all voices and frees audio resources held by this pool.
---@return nil No return value.
function LSoundPool:release() end

--- Routes all voices in this pool through the named audio bus.
---@param name string Name of the target bus.
---@return nil No return value.
function LSoundPool:setBus(name) end

--- Sets the volume for all voices in this pool.
---@param vol number Volume multiplier (0.0 = silent, 1.0 = normal).
---@return nil No return value.
function LSoundPool:setVolume(vol) end

--- Stops all voices in this sound pool immediately.
---@return nil No return value.
function LSoundPool:stopAll() end

--- Returns the type name of this object for runtime type-checking.
---@return string Always returns "LSoundPool".
function LSoundPool:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check (e.g. "SoundPool" or "Object").
---@return boolean True if this object matches the given type.
function LSoundPool:typeOf(name) end

--- Lua-side wrapper around a loaded audio source (sound effect or music stream).
---@class LSource
LSource = {}

--- Removes all frequency filters (lowpass and highpass) from this source.
---@return nil No return value.
function LSource:clearFilter() end

--- Creates an independent copy of this source sharing the same audio data.
---@return LSource A new source instance with identical settings.
function LSource:clone() end

--- Sets the fade-in duration so the source ramps from silence to full volume on play.
---@param dur number Fade-in duration in seconds.
---@return nil No return value.
function LSource:fadeIn(dur) end

--- Returns the total duration of this audio source in seconds.
---@return number Duration in seconds.
function LSource:getDuration() end

--- Returns the configured fade-in duration for this source.
---@return number Fade-in duration in seconds.
function LSource:getFadeIn() end

--- Returns the current highpass filter cutoff frequency in Hertz.
---@return number Cutoff frequency in Hz, or 0 if no highpass is set.
function LSource:getHighpass() end

--- Returns the current lowpass filter cutoff frequency in Hertz.
---@return number Cutoff frequency in Hz, or 0 if no lowpass is set.
function LSource:getLowpass() end

--- Returns the current stereo panning position of this source.
---@return number Pan value from -1.0 (left) to 1.0 (right).
function LSource:getPan() end

--- Returns the current pitch multiplier of this audio source.
---@return number Current pitch multiplier.
function LSource:getPitch() end

--- Returns whether this source was loaded as static (fully in memory) or streaming.
---@return string Either "static" or "stream".
function LSource:getType() end

--- Returns the current volume level of this audio source.
---@return number Current volume multiplier.
function LSource:getVolume() end

--- Returns whether this source is set to loop continuously.
---@return boolean True if looping is enabled.
function LSource:isLooping() end

--- Returns whether this source is currently paused.
---@return boolean True if the source is paused.
function LSource:isPaused() end

--- Returns whether this source is currently playing audio.
---@return boolean True if the source is actively playing.
function LSource:isPlaying() end

--- Returns whether this source is currently stopped (not playing or paused).
---@return boolean True if the source is stopped.
function LSource:isStopped() end

--- Pauses playback at the current position, allowing later resumption.
---@return nil No return value.
function LSource:pause() end

--- Starts playback of this audio source from the current position.
---@return nil No return value.
function LSource:play() end

--- Resumes playback from the position where the source was paused.
---@return nil No return value.
function LSource:resume() end

--- Seeks to a specific position in seconds within this audio source.
---@param pos number Target position in seconds.
---@return nil No return value.
function LSource:seek(pos) end

--- Applies a highpass filter that attenuates frequencies below the cutoff.
---@param cutoff_hz number Cutoff frequency in Hertz.
---@return nil No return value.
function LSource:setHighpass(cutoff_hz) end

--- Enables or disables looping so the source restarts automatically after finishing.
---@param looping boolean True to loop continuously, false to play once.
---@return nil No return value.
function LSource:setLooping(looping) end

--- Applies a lowpass filter that attenuates frequencies above the cutoff.
---@param cutoff_hz number Cutoff frequency in Hertz.
---@return nil No return value.
function LSource:setLowpass(cutoff_hz) end

--- Sets the stereo panning position of this source.
---@param pan number Pan value from -1.0 (full left) to 1.0 (full right), 0.0 is center.
---@return nil No return value.
function LSource:setPan(pan) end

--- Sets the playback speed multiplier, affecting both pitch and duration.
---@param pitch number Pitch multiplier (1.0 = normal, 2.0 = double speed/octave up).
---@return nil No return value.
function LSource:setPitch(pitch) end

--- Sets the volume level of this source where 0.0 is silent and 1.0 is full volume.
---@param vol number Volume multiplier (0.0 = silent, 1.0 = normal, >1.0 = amplified).
---@return nil No return value.
function LSource:setVolume(vol) end

--- Stops playback and resets the source position to the beginning.
---@return nil No return value.
function LSource:stop() end

--- Returns the current playback position of this source in seconds.
---@return number Current position in seconds from the start.
function LSource:tell() end

--- Returns the type name of this object for runtime type-checking.
---@return string Always returns "LSource".
function LSource:type() end

--- Checks whether this object is of the given type name or a parent type.
---@param name string Type name to check (e.g. "LSource" or "Object").
---@return boolean True if this object matches the given type.
function LSource:typeOf(name) end

---@param bus_name LuaValue
---@param effect_type_str LuaValue
---@param params? LuaValue
lurek.audio.add_effect = function(bus_name, effect_type_str, params) end

---@param sd_ud LuaValue
---@param low_hz LuaValue
---@param high_hz LuaValue
lurek.audio.applyBandpass = function(sd_ud, low_hz, high_hz) end

---@param sd_ud LuaValue
---@param gain LuaValue
lurek.audio.applyGain = function(sd_ud, gain) end

---@param sd_ud LuaValue
---@param cutoff_hz LuaValue
lurek.audio.applyHighpass = function(sd_ud, cutoff_hz) end

---@param sd_ud LuaValue
---@param cutoff_hz LuaValue
lurek.audio.applyLowpass = function(sd_ud, cutoff_hz) end

--- Removes all frequency filters from a source.
---@param source LSource|number Audio source or numeric source ID.
---@return nil No return value.
lurek.audio.clearFilter = function(source) end

lurek.audio.clearMidiSoundFont = function() end

---@param src_ud LuaValue
lurek.audio.clearRandomPitch = function(src_ud) end

--- Creates an independent copy of a source sharing the same audio data.
---@param source LSource|number Audio source or numeric source ID to clone.
---@return LSource A new source instance with identical settings.
lurek.audio.clone = function(source) end

---@param name LuaValue
---@param parent_name? LuaValue
lurek.audio.create_bus = function(name, parent_name) end

---@param from_ud LuaValue
---@param to_ud LuaValue
---@param duration LuaValue
lurek.audio.crossfade = function(from_ud, to_ud, duration) end

--- Sets the fade-in duration for a source so it ramps from silence on play.
---@param source LSource|number Audio source or numeric source ID.
---@param dur number Fade-in duration in seconds.
---@return nil No return value.
lurek.audio.fadeIn = function(source, dur) end

--- Returns the number of sources currently playing audio.
---@return number Count of active (playing) sources.
lurek.audio.getActiveSourceCount = function() end

---@param bus_name LuaValue
lurek.audio.getBusPeak = function(bus_name) end

---@param bus_name LuaValue
lurek.audio.getBusRms = function(bus_name) end

--- Returns the current distance attenuation model name.
---@return string Distance model name.
lurek.audio.getDistanceModel = function() end

--- Returns the current global Doppler effect scale.
---@return number Doppler scale factor.
lurek.audio.getDopplerScale = function() end

--- Returns the total duration of a source in seconds.
---@param source LSource|number Audio source or numeric source ID.
---@return number Duration in seconds.
lurek.audio.getDuration = function(source) end

--- Returns the configured fade-in duration of a source.
---@param source LSource|number Audio source or numeric source ID.
---@return number Fade-in duration in seconds.
lurek.audio.getFadeIn = function(source) end

---@param qsource_id LuaValue
lurek.audio.getFreeBufferCount = function(qsource_id) end

--- Returns the current highpass filter cutoff of a source.
---@param source LSource|number Audio source or numeric source ID.
---@return number Cutoff frequency in Hz, or 0 if not set.
lurek.audio.getHighpass = function(source) end

--- Returns the current 3D listener position.
---@return number a X, Y, and Z position of the listener.
---@return number b X, Y, and Z position of the listener.
---@return number c X, Y, and Z position of the listener.
lurek.audio.getListener = function() end

--- Returns the current 2D listener position.
---@return number a X and Y position of the listener.
---@return number b X and Y position of the listener.
lurek.audio.getListener2D = function() end

--- Returns the current lowpass filter cutoff of a source.
---@param source LSource|number Audio source or numeric source ID.
---@return number Cutoff frequency in Hz, or 0 if not set.
lurek.audio.getLowpass = function(source) end

--- Returns the current global master volume level.
---@return number Master volume multiplier.
lurek.audio.getMasterVolume = function() end

--- Returns the maximum number of simultaneous audio sources supported.
---@return number Maximum source count (64).
lurek.audio.getMaxSources = function() end

--- Returns the current master peak level for VU-meter displays.
---@return number Peak level from 0.0 to 1.0.
lurek.audio.getMeter = function() end

--- Returns the orientation vectors of a source.
---@param source LSource|number Audio source or numeric source ID.
---@return number a Forward (fx,fy,fz) and up (ux,uy,uz) vectors.
---@return number b Forward (fx,fy,fz) and up (ux,uy,uz) vectors.
---@return number c Forward (fx,fy,fz) and up (ux,uy,uz) vectors.
---@return number d Forward (fx,fy,fz) and up (ux,uy,uz) vectors.
---@return number e Forward (fx,fy,fz) and up (ux,uy,uz) vectors.
---@return number f Forward (fx,fy,fz) and up (ux,uy,uz) vectors.
lurek.audio.getOrientation = function(source) end

--- Returns the current stereo pan position of a source.
---@param source LSource|number Audio source or numeric source ID.
---@return number Pan value from -1.0 (left) to 1.0 (right).
lurek.audio.getPan = function(source) end

--- Returns the current pitch multiplier of a source.
---@param source LSource|number Audio source or numeric source ID.
---@return number Current pitch multiplier.
lurek.audio.getPitch = function(source) end

lurek.audio.getPlaybackDevice = function() end

lurek.audio.getPlaybackDevices = function() end

--- Returns the 3D position of a source.
---@param source LSource|number Audio source or numeric source ID.
---@return number a X, Y, and Z position.
---@return number b X, Y, and Z position.
---@return number c X, Y, and Z position.
lurek.audio.getPosition = function(source) end

--- Returns the bus a source is routed through.
---@param source LSource|number Audio source or numeric source ID.
---@return LBus? The assigned bus, or nil if using direct output.
lurek.audio.getSourceBus = function(source) end

--- Returns the total number of loaded audio sources (playing or idle).
---@return number Total source count.
lurek.audio.getSourceCount = function() end

--- Returns whether a source is static or streaming.
---@param source LSource|number Audio source or numeric source ID.
---@return string Either "static" or "stream".
lurek.audio.getSourceType = function(source) end

---@param src_ud LuaValue
lurek.audio.getStereoWidth = function(src_ud) end

--- Returns the velocity vector of a source.
---@param source LSource|number Audio source or numeric source ID.
---@return number a X, Y, and Z velocity components.
---@return number b X, Y, and Z velocity components.
---@return number c X, Y, and Z velocity components.
lurek.audio.getVelocity = function(source) end

--- Returns the current volume of a source.
---@param source LSource|number Audio source or numeric source ID.
---@return number Current volume multiplier.
lurek.audio.getVolume = function(source) end

lurek.audio.hasMidiSoundFont = function() end

--- Returns whether a source has looping enabled.
---@param source LSource|number Audio source or numeric source ID.
---@return boolean True if looping is enabled.
lurek.audio.isLooping = function(source) end

--- Returns whether a source is currently paused.
---@param source LSource|number Audio source or numeric source ID.
---@return boolean True if the source is paused.
lurek.audio.isPaused = function(source) end

--- Returns whether a source is currently playing.
---@param source LSource|number Audio source or numeric source ID.
---@return boolean True if the source is playing.
lurek.audio.isPlaying = function(source) end

--- Returns whether a source is currently stopped.
---@param source LSource|number Audio source or numeric source ID.
---@return boolean True if the source is stopped.
lurek.audio.isStopped = function(source) end

---@param dest_ud LuaValue
---@param src_ud LuaValue
lurek.audio.mixInto = function(dest_ud, src_ud) end

--- Creates a new audio mixing bus for grouping and controlling sources.
---@param name string Unique name for the bus (e.g. "music", "sfx").
---@return LBus The new audio bus handle.
lurek.audio.newBus = function(name) end

---@param source LuaValue
---@param buffersize? LuaValue
lurek.audio.newDecoder = function(source, buffersize) end

--- Creates a new MIDI player instance, optionally loading a file immediately.
---@param path? string Optional relative path to a .mid file to load.
---@return LMidiPlayer A new MIDI player ready for playback.
lurek.audio.newMidiPlayer = function(path) end

---@param file_path LuaValue
---@param voice_count LuaValue
lurek.audio.newPool = function(file_path, voice_count) end

lurek.audio.newQueueableSource = function() end

---@param freq LuaValue
---@param duration LuaValue
---@param sample_rate LuaValue
---@param amplitude LuaValue
lurek.audio.newSawtoothWave = function(freq, duration, sample_rate, amplitude) end

---@param freq LuaValue
---@param duration LuaValue
---@param sample_rate LuaValue
---@param amplitude LuaValue
lurek.audio.newSineWave = function(freq, duration, sample_rate, amplitude) end

--- Creates a new SoundData object from a file path or blank buffer for procedural audio.
---@param ... string|number|number|number
---@return SoundData Raw PCM sample data for manipulation or playback.
lurek.audio.newSoundData = function(...) end

--- Creates a new audio source from a file path, either fully loaded or streaming.
---@param ... string|string
---@return LSource A new audio source ready for playback.
lurek.audio.newSource = function(...) end

---@param freq LuaValue
---@param duration LuaValue
---@param sample_rate LuaValue
---@param amplitude LuaValue
lurek.audio.newSquareWave = function(freq, duration, sample_rate, amplitude) end

---@param freq LuaValue
---@param duration LuaValue
---@param sample_rate LuaValue
---@param amplitude LuaValue
lurek.audio.newTriangleWave = function(freq, duration, sample_rate, amplitude) end

---@param duration LuaValue
---@param sample_rate LuaValue
---@param amplitude LuaValue
---@param seed LuaValue
lurek.audio.newWhiteNoise = function(duration, sample_rate, amplitude, seed) end

---@param input LuaValue
---@param output LuaValue
---@param target LuaValue
lurek.audio.normalizeFile = function(input, output, target) end

--- Pauses playback of a source at its current position.
---@param source LSource|number Audio source or numeric source ID.
---@return nil No return value.
lurek.audio.pause = function(source) end

--- Pauses all currently playing audio sources.
---@return nil No return value.
lurek.audio.pauseAll = function() end

--- Starts playback of a source by handle, optionally routing through a named bus.
---@param source LSource|number Audio source or numeric source ID.
---@param options? table Optional table with "bus" field for bus routing.
---@return number Numeric source ID of the playing source.
lurek.audio.play = function(source, options) end

--- Starts playback of a source with looping enabled in one call.
---@param source LSource|number Audio source or numeric source ID.
---@return nil No return value.
lurek.audio.playLooping = function(source) end

---@param qsource_id LuaValue
lurek.audio.playQueueable = function(qsource_id) end

---@param input LuaValue
---@param output LuaValue
---@param effects_tbl LuaValue
lurek.audio.processOffline = function(input, output, effects_tbl) end

---@param qsource_id LuaValue
---@param sd LuaValue
lurek.audio.queueSource = function(qsource_id, sd) end

--- Releases an audio source, freeing its memory and stopping playback.
---@param source LSource|number Audio source or numeric source ID to release.
---@return boolean True if the source was successfully released.
lurek.audio.release = function(source) end

---@param bus_name LuaValue
---@param effect_id LuaValue
lurek.audio.remove_effect = function(bus_name, effect_id) end

--- Resumes playback of a paused source.
---@param source LSource|number Audio source or numeric source ID.
---@return nil No return value.
lurek.audio.resume = function(source) end

--- Resumes all paused audio sources.
---@return nil No return value.
lurek.audio.resumeAll = function() end

---@param sd_ud LuaValue
---@param filename LuaValue
lurek.audio.saveWAV = function(sd_ud, filename) end

--- Seeks a source to a specific position in seconds.
---@param source LSource|number Audio source or numeric source ID.
---@param pos number Target position in seconds.
---@return nil No return value.
lurek.audio.seek = function(source, pos) end

--- Sets the distance attenuation model for spatial audio.
---@param model string Model name (e.g. "inverse", "linear", "exponent", "none").
---@return nil No return value.
lurek.audio.setDistanceModel = function(model) end

--- Sets the global Doppler effect intensity multiplier.
---@param scale number Doppler scale (0 = disabled, 1.0 = realistic).
---@return nil No return value.
lurek.audio.setDopplerScale = function(scale) end

--- Applies a highpass filter to a source, attenuating low frequencies.
---@param source LSource|number Audio source or numeric source ID.
---@param cutoff_hz number Cutoff frequency in Hertz.
---@return nil No return value.
lurek.audio.setHighpass = function(source, cutoff_hz) end

--- Sets the 3D listener position for spatial audio (Z defaults to 0 for 2D games).
---@param x number Listener X position.
---@param y number Listener Y position.
---@param z? number Listener Z position (defaults to 0).
---@return nil No return value.
lurek.audio.setListener = function(x, y, z) end

--- Sets the 2D listener position for spatial audio calculations.
---@param x number Listener X position in world units.
---@param y number Listener Y position in world units.
---@return nil No return value.
lurek.audio.setListener2D = function(x, y) end

--- Enables or disables looping for a source.
---@param source LSource|number Audio source or numeric source ID.
---@param looping boolean True to loop, false to play once.
---@return nil No return value.
lurek.audio.setLooping = function(source, looping) end

--- Applies a lowpass filter to a source, attenuating high frequencies.
---@param source LSource|number Audio source or numeric source ID.
---@param cutoff_hz number Cutoff frequency in Hertz.
---@return nil No return value.
lurek.audio.setLowpass = function(source, cutoff_hz) end

--- Sets the global master volume affecting all audio output.
---@param vol number Master volume multiplier (0.0 = silent, 1.0 = normal).
---@return nil No return value.
lurek.audio.setMasterVolume = function(vol) end

--- Sets the master peak level for metering purposes.
---@param level number Peak level clamped to 0.0-1.0.
---@return nil No return value.
lurek.audio.setMeter = function(level) end

---@param path LuaValue
lurek.audio.setMidiSoundFont = function(path) end

--- Sets the orientation of a source using forward and up vectors.
---@param source LSource|number Audio source or numeric source ID.
---@param fx number Forward vector X.
---@param fy number Forward vector Y.
---@param fz number Forward vector Z.
---@param ux number Up vector X.
---@param uy number Up vector Y.
---@param uz number Up vector Z.
---@return nil No return value.
lurek.audio.setOrientation = function(source, fx, fy, fz, ux, uy, uz) end

--- Sets the stereo panning of a source.
---@param source LSource|number Audio source or numeric source ID.
---@param pan number Pan from -1.0 (left) to 1.0 (right), 0.0 is center.
---@return nil No return value.
lurek.audio.setPan = function(source, pan) end

--- Sets the pitch multiplier of a source, affecting playback speed and tone.
---@param source LSource|number Audio source or numeric source ID.
---@param pitch number Pitch multiplier (1.0 = normal, 2.0 = octave up).
---@return nil No return value.
lurek.audio.setPitch = function(source, pitch) end

---@param name LuaValue
lurek.audio.setPlaybackDevice = function(name) end

--- Sets the 3D position of a source for spatial audio panning and attenuation.
---@param source LSource|number Audio source or numeric source ID.
---@param x number X position in world units.
---@param y number Y position in world units.
---@param z? number Z position (defaults to 0).
---@return nil No return value.
lurek.audio.setPosition = function(source, x, y, z) end

---@param src_ud LuaValue
---@param min LuaValue
---@param max LuaValue
lurek.audio.setRandomPitch = function(src_ud, min, max) end

--- Routes a source through a specific audio bus for grouped mixing.
---@param source LSource|number Audio source or numeric source ID.
---@param bus LBus The bus to route through.
---@return nil No return value.
lurek.audio.setSourceBus = function(source, bus) end

---@param src_ud LuaValue
---@param width LuaValue
lurek.audio.setStereoWidth = function(src_ud, width) end

--- Sets the velocity of a source for Doppler effect calculations.
---@param source LSource|number Audio source or numeric source ID.
---@param x number X velocity component.
---@param y number Y velocity component.
---@param z? number Z velocity component (defaults to 0).
---@return nil No return value.
lurek.audio.setVelocity = function(source, x, y, z) end

--- Sets the volume of a source by handle.
---@param source LSource|number Audio source or numeric source ID.
---@param vol number Volume multiplier (0.0 = silent, 1.0 = normal).
---@return nil No return value.
lurek.audio.setVolume = function(source, vol) end

---@param name LuaValue
---@param volume LuaValue
lurek.audio.set_bus_volume = function(name, volume) end

---@param bus_name LuaValue
---@param effect_id LuaValue
---@param param_name LuaValue
---@param value LuaValue
lurek.audio.set_effect_param = function(bus_name, effect_id, param_name, value) end

---@param input LuaValue
---@param output LuaValue
---@param width LuaValue
---@param height LuaValue
lurek.audio.spectrogramToPng = function(input, output, width, height) end

--- Stops playback of a source and resets its position to the beginning.
---@param source LSource|number Audio source or numeric source ID.
---@return nil No return value.
lurek.audio.stop = function(source) end

--- Stops all audio sources and resets their positions.
---@return nil No return value.
lurek.audio.stopAll = function() end

---@param qsource_id LuaValue
lurek.audio.stopQueueable = function(qsource_id) end

--- Returns the current playback position of a source in seconds.
---@param source LSource|number Audio source or numeric source ID.
---@return number Current position in seconds.
lurek.audio.tell = function(source) end

---@param input LuaValue
---@param output LuaValue
---@param width LuaValue
---@param height LuaValue
lurek.audio.waveformToPng = function(input, output, width, height) end

---@class lurek.automation
lurek.automation = {}

--- Returns the current value of a named condition flag. Returns false if the condition was never set. Useful for debugging conditional branches in automation scripts.
---@param name string Condition name to query.
---@return boolean Current condition value (false if unset).
lurek.automation.getCondition = function(name) end

--- Returns the name of the script currently being played back, or nil if the simulator is idle. Useful for logging which test is active.
---@return string? Active script name, or nil if no playback is in progress.
lurek.automation.getCurrentScript = function() end

--- Returns the zero-based index of the step currently being executed in the active script. Combine with getStepCount() to display progress (e.g., "Step 5/20").
---@return number? Current step index (0-based), or nil if no script is running.
lurek.automation.getCurrentStep = function() end

--- Returns the total seconds elapsed since the current script started, scaled by the playback speed factor. Useful for timeout checks and performance metrics in test reports.
---@return number Elapsed playback time in seconds (0.0 if idle).
lurek.automation.getElapsedTime = function() end

--- Returns the human-readable error message from the most recent script failure, including assertion text or step limit details. Returns nil if the last run succeeded or no script has been started.
---@return string? Error description string, or nil if no failure occurred.
lurek.automation.getLastError = function() end

--- Returns the current playback speed multiplier set by setPlaybackSpeed().
---@return number Speed factor (1.0 = real-time, default).
lurek.automation.getPlaybackSpeed = function() end

--- Returns a list of all currently loaded script names. Useful for building a test-runner UI or iterating over available automation scenarios.
---@return table Array of script name strings in load order.
lurek.automation.getScripts = function() end

--- Returns the total number of steps in the currently active script. Useful for progress bars and timeout estimation in test harnesses.
---@return number? Total step count, or nil if no script is active.
lurek.automation.getStepCount = function() end

--- Returns the maximum number of steps allowed for a script before the simulator forcibly fails it. Returns nil if no limit is set, meaning the script runs until all steps complete.
---@param name string Script name to query.
---@return number? Step limit count, or nil if unlimited.
lurek.automation.getStepLimit = function(name) end

--- Checks whether a macro with the given name has been saved in the simulator. Use as a guard before playMacro() to avoid runtime errors.
---@param name string Macro name to look up.
---@return boolean True if the macro exists and can be played.
lurek.automation.hasMacro = function(name) end

--- Checks whether a script with the given name is currently loaded in the simulator. Useful for guard checks before calling start() or for verifying test setup completed.
---@param name string Name of the script to look up.
---@return boolean True if the script is loaded and ready to play.
lurek.automation.hasScript = function(name) end

--- Returns whether the last started script finished all its steps successfully. Use this in your test harness to know when to check assertions or exit the game loop.
---@return boolean True if the script ran to completion without assertion failures or runtime errors.
lurek.automation.isComplete = function() end

--- Returns whether the last started script terminated due to an assertion failure, step limit exceeded, or runtime error. Check getLastError() for details on what went wrong.
---@return boolean True if the script ended in a failure state.
lurek.automation.isFailed = function() end

--- Returns whether visual highlight mode is currently enabled for debugging automation playback.
---@return boolean True if input highlight overlays are being drawn.
lurek.automation.isHighlightMode = function() end

--- Returns whether playback is currently suspended via pause() and waiting for resume().
---@return boolean True if a script is loaded and paused mid-execution.
lurek.automation.isPaused = function() end

--- Returns whether a script is currently playing back steps (not paused, not complete, not failed).
---@return boolean True if a script is actively advancing through its step list.
lurek.automation.isRunning = function() end

--- Returns a list of all saved macro names for enumeration, debug display, or test-runner UIs.
---@return table Array of macro name strings in save order.
lurek.automation.listMacros = function() end

--- Loads an automation script into the simulator from a Lua table describing a sequence of simulated input events. Use this to drive full playthroughs, regression tests, or demo recordings without manual input. The data table must contain a "steps" array where each entry specifies an action (keypress, mousemove, wait, assert, etc.) and timing. An optional "meta.description" field documents the script's purpose.
---@param name string Unique identifier for the script, referenced by start(), unload(), and setStepLimit().
---@param data table Table with a "steps" array of step entries and an optional "meta" subtable containing "description".
---@return nil No return value.
lurek.automation.load = function(name, data) end

--- Parses a TOML-formatted automation script string and loads it into the simulator. TOML scripts are the preferred format for version-controlled test recordings because they are human-readable and diff-friendly. The TOML schema mirrors the Lua table format with [[steps]] arrays.
---@param name string Unique identifier for the script (used in start/unload calls).
---@param toml_str string TOML source string defining steps and optional metadata.
---@return nil No return value. Raises a Lua error if the TOML is malformed or contains unknown action types.
lurek.automation.loadFromToml = function(name, toml_str) end

--- Suspends the running script so no further steps are dispatched until resume() is called. The elapsed timer also pauses, preserving relative step timing on resume.
---@return nil No return value.
lurek.automation.pause = function() end

--- Starts playback of a previously saved macro, injecting its steps into the event queue as if it were a standalone script. The macro replaces any currently running script for the duration of its steps.
---@param name string Macro name to play (must have been saved with saveMacro()).
---@return nil No return value. Raises a Lua error if the macro does not exist.
lurek.automation.playMacro = function(name) end

--- Resumes a paused script from the exact step and elapsed time where it was suspended. Has no effect if no script is paused.
---@return nil No return value.
lurek.automation.resume = function() end

--- Saves a copy of a loaded script as a reusable macro that can be played back by name from other scripts via the "callmacro" action or playMacro(). Use macros to compose complex test sequences from smaller building blocks (e.g., a "login" macro reused across many tests).
---@param macro_name string Name to assign to the saved macro for later retrieval.
---@param script_name string Name of the currently loaded source script to copy into the macro store.
---@return nil No return value. Raises a Lua error if the source script is not found.
lurek.automation.saveMacro = function(macro_name, script_name) end

--- Sets a named boolean condition flag that conditional steps check via their "when" field. Use this to drive branching in automation scripts based on runtime game state (e.g., skip a boss fight sequence if the player already has an item).
---@param name string Condition name that step entries reference in their "when" field.
---@param value boolean True to enable the condition, false to disable it.
---@return nil No return value.
lurek.automation.setCondition = function(name, value) end

--- Enables or disables visual highlight mode that draws colored indicators on simulated click positions and key targets. Useful when watching automation playback in a window to visually confirm the script is interacting with the correct UI elements.
---@param enable boolean True to show highlight overlays on simulated inputs, false to hide them.
---@return nil No return value.
lurek.automation.setHighlightMode = function(enable) end

--- Sets the time multiplier for script playback, allowing faster or slower replay of input sequences. Speeds above 1.0 are useful for fast CI runs; speeds below 1.0 help debug timing-sensitive interactions.
---@param factor number Speed multiplier (1.0 = real-time, 2.0 = double speed, 0.5 = half speed). Must be positive.
---@return nil No return value.
lurek.automation.setPlaybackSpeed = function(factor) end

--- Sets the maximum step count for a script to prevent runaway loops during automated testing. If the script reaches this many executed steps, it is forcibly stopped and marked as failed with a step-limit-exceeded error.
---@param name string Script name to apply the limit to (must be loaded).
---@param n number Maximum number of steps before forced failure.
---@return boolean True if the script exists and the limit was applied, false if the script name was not found.
lurek.automation.setStepLimit = function(name, n) end

--- Begins playback of a loaded script, advancing through its steps on each update() call and injecting simulated keyboard, mouse, and assertion events into the engine event queue. Only one script can run at a time; starting a new one implicitly stops any active playback.
---@param name string Name of the previously loaded script to start.
---@return nil No return value. Raises a Lua error if the script name is not loaded.
lurek.automation.start = function(name) end

--- Stops the currently running script immediately, discarding remaining steps and resetting playback state to idle. The script remains loaded and can be restarted with start().
---@return nil No return value.
lurek.automation.stop = function() end

--- Removes a previously loaded script from the simulator by name, freeing its steps and metadata. Call this to clean up after a test run or to replace a script with an updated version.
---@param name string Name of the script to remove (must match the name passed to load()).
---@return boolean True if the script existed and was removed, false if no script had that name.
lurek.automation.unload = function(name) end

--- Advances the simulator by the given delta time, dispatching all steps whose scheduled time has been reached as input events into the engine event queue. Call this once per frame from lurek.update. If a waitUntil() predicate is active, the simulator stalls until the predicate resolves or times out before processing further steps.
---@param dt number Frame delta time in seconds (typically from lurek.timer.getDelta()).
---@return nil No return value.
lurek.automation.update = function(dt) end

--- Pauses script advancement until the predicate function returns true or the timeout expires. Use this to synchronize automation with asynchronous game state (e.g., wait for a menu to open, an animation to finish, or a network response to arrive) without hard-coding sleep durations.
---@param predicate function Zero-argument function called each update(); should return true when the wait condition is satisfied.
---@param timeout number Maximum seconds to wait before resuming playback regardless of predicate result. Clamped to >= 0.
---@return nil No return value.
lurek.automation.waitUntil = function(predicate, timeout) end

---@class lurek.camera
lurek.camera = {}

---@class LCamera
LCamera = {}

function LCamera:apply() end

function LCamera:attach() end

function LCamera:clearParallaxFactors() end

function LCamera:clearTarget() end

function LCamera:detach() end

---@param points LuaValue
---@param duration LuaValue
function LCamera:followPath(points, duration) end

function LCamera:getBounds() end

function LCamera:getDeadZone() end

function LCamera:getEffectOffset() end

function LCamera:getEffectiveZoom() end

function LCamera:getFollowEasing() end

function LCamera:getFollowSmooth() end

function LCamera:getLookAhead() end

---@param layer LuaValue
function LCamera:getParallaxFactor(layer) end

function LCamera:getPosition() end

function LCamera:getRenderOffset() end

function LCamera:getRotation() end

function LCamera:getRotationConstraints() end

function LCamera:getRotationDamping() end

function LCamera:getShakeOffset() end

function LCamera:getTarget() end

function LCamera:getViewport() end

function LCamera:getVisibleArea() end

function LCamera:getZoom() end

function LCamera:getZoomConstraints() end

function LCamera:getZoomDamping() end

function LCamera:hasBounds() end

function LCamera:isBreathing() end

function LCamera:isSway() end

---@param x LuaValue
---@param y LuaValue
function LCamera:lookAt(x, y) end

---@param dx LuaValue
---@param dy LuaValue
function LCamera:move(dx, dy) end

---@param window_w LuaValue
---@param window_h LuaValue
function LCamera:onWindowResize(window_w, window_h) end

---@param game_w LuaValue
---@param game_h LuaValue
---@param window_w LuaValue
---@param window_h LuaValue
---@param mode LuaValue
function LCamera:onWindowResizeScaled(game_w, game_h, window_w, window_h, mode) end

function LCamera:pathProgress() end

function LCamera:presetAggressiveFollow() end

function LCamera:presetBalancedFollow() end

function LCamera:presetCinematicFollow() end

function LCamera:presetTightFollow() end

function LCamera:removeBounds() end

function LCamera:reset() end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LCamera:setBounds(x, y, w, h) end

---@param w LuaValue
---@param h LuaValue
function LCamera:setDeadZone(w, h) end

---@param easing LuaValue
function LCamera:setFollowEasing(easing) end

---@param speed LuaValue
function LCamera:setFollowSmooth(speed) end

---@param mul LuaValue
function LCamera:setLookAhead(mul) end

---@param layer LuaValue
---@param factor LuaValue
function LCamera:setParallaxFactor(layer, factor) end

---@param x LuaValue
---@param y LuaValue
function LCamera:setPosition(x, y) end

---@param r LuaValue
function LCamera:setRotation(r) end

---@param min_rot? LuaValue
---@param max_rot? LuaValue
function LCamera:setRotationConstraints(min_rot, max_rot) end

---@param damping LuaValue
function LCamera:setRotationDamping(damping) end

---@param x LuaValue
---@param y LuaValue
function LCamera:setTarget(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LCamera:setViewport(x, y, w, h) end

---@param zoom LuaValue
function LCamera:setZoom(zoom) end

---@param min_zoom? LuaValue
---@param max_zoom? LuaValue
function LCamera:setZoomConstraints(min_zoom, max_zoom) end

---@param damping LuaValue
function LCamera:setZoomDamping(damping) end

---@param intensity LuaValue
---@param duration LuaValue
function LCamera:shake(intensity, duration) end

---@param amplitude? LuaValue
---@param rate? LuaValue
function LCamera:startBreathing(amplitude, rate) end

---@param amplitude_x LuaValue
---@param amplitude_y LuaValue
---@param frequency LuaValue
---@param decay? LuaValue
function LCamera:startSway(amplitude_x, amplitude_y, frequency, decay) end

function LCamera:stopBreathing() end

function LCamera:stopPath() end

function LCamera:stopSway() end

function LCamera:stopZoom() end

---@param wx LuaValue
---@param wy LuaValue
function LCamera:toScreen(wx, wy) end

---@param sx LuaValue
---@param sy LuaValue
function LCamera:toWorld(sx, sy) end

function LCamera:type() end

---@param name LuaValue
function LCamera:typeOf(name) end

---@param dt LuaValue
function LCamera:update(dt) end

---@param dt LuaValue
function LCamera:updatePath(dt) end

---@param dt LuaValue
function LCamera:updateZoom(dt) end

---@param amplitude LuaValue
---@param duration LuaValue
function LCamera:zoomPulse(amplitude, duration) end

---@param target_zoom LuaValue
---@param duration LuaValue
---@param easing? LuaValue
function LCamera:zoomTo(target_zoom, duration, easing) end

---@class LCameraRig
LCameraRig = {}

---@param name LuaValue
function LCameraRig:apply(name) end

---@param name LuaValue
function LCameraRig:getViewport(name) end

---@param name LuaValue
function LCameraRig:has(name) end

---@param window_w LuaValue
---@param window_h LuaValue
---@param ratio? LuaValue
function LCameraRig:minimap(window_w, window_h, ratio) end

function LCameraRig:names() end

---@param window_w LuaValue
---@param window_h LuaValue
---@param pip_w? LuaValue
---@param pip_h? LuaValue
function LCameraRig:pictureInPicture(window_w, window_h, pip_w, pip_h) end

---@param name LuaValue
function LCameraRig:remove(name) end

---@param name LuaValue
---@param x LuaValue
---@param y LuaValue
function LCameraRig:setPosition(name, x, y) end

---@param name LuaValue
---@param x LuaValue
---@param y LuaValue
function LCameraRig:setTarget(name, x, y) end

---@param name LuaValue
---@param zoom LuaValue
function LCameraRig:setZoom(name, zoom) end

---@param window_w LuaValue
---@param window_h LuaValue
function LCameraRig:splitScreen(window_w, window_h) end

function LCameraRig:type() end

---@param name LuaValue
function LCameraRig:typeOf(name) end

---@param dt LuaValue
function LCameraRig:updateAll(dt) end

---@param vw? LuaValue
---@param vh? LuaValue
lurek.camera.new = function(vw, vh) end

---@param vw? LuaValue
---@param vh? LuaValue
lurek.camera.newCamera = function(vw, vh) end

lurek.camera.newRig = function() end

---@class lurek.compute
lurek.compute = {}

--- Lua-side wrapper around an N-dimensional numeric array supporting element-wise math, reductions, linear algebra, spatial filters, and analytics.
---@class LArray
LArray = {}

--- Returns a new array with the absolute value of each element.
---@return LArray A new array with non-negative values.
function LArray:abs() end

--- Returns a new array with each element added by the other array or scalar. Does not modify the original.
---@param value LArray|number An array for element-wise addition or a scalar to add to all elements.
---@return LArray A new array with the sum.
function LArray:add(value) end

--- Adds another array element-wise into this array, modifying it in place. Shapes must match.
---@param other LArray The array to add.
---@return nil No return value.
function LArray:addInplace(other) end

--- Returns true if every element in the array is non-zero. Useful for verifying all conditions hold.
---@return boolean True if all elements are non-zero.
function LArray:all() end

--- Returns true if any element in the array is non-zero. Useful for checking boolean masks.
---@return boolean True if at least one element is non-zero.
function LArray:any() end

--- Returns the 1-based index of the largest element in the flattened array.
---@return number The 1-based position of the maximum value.
function LArray:argmax() end

--- Returns the 1-based index of the smallest element in the flattened array.
---@return number The 1-based position of the minimum value.
function LArray:argmin() end

--- Returns a new array with each element being the bitwise AND of this array and another (integer arrays).
---@param other LArray The array to AND with.
---@return LArray A new array with the bitwise result.
function LArray:bitwiseAnd(other) end

--- Returns a new array with each element left-shifted by the given number of bits.
---@param amount number Number of bit positions to shift left.
---@return LArray A new array with shifted values.
function LArray:bitwiseLShift(amount) end

--- Returns a new array with each element bitwise-inverted (ones complement for integer arrays).
---@return LArray A new array with the bitwise NOT result.
function LArray:bitwiseNot() end

--- Returns a new array with each element being the bitwise OR of this array and another (integer arrays).
---@param other LArray The array to OR with.
---@return LArray A new array with the bitwise result.
function LArray:bitwiseOr(other) end

--- Returns a new array with each element right-shifted by the given number of bits.
---@param amount number Number of bit positions to shift right.
---@return LArray A new array with shifted values.
function LArray:bitwiseRShift(amount) end

--- Returns a new array with each element being the bitwise XOR of this array and another (integer arrays).
---@param other LArray The array to XOR with.
---@return LArray A new array with the bitwise result.
function LArray:bitwiseXor(other) end

--- Returns a new array with each element clamped between min and max (inclusive). Useful for constraining values.
---@param min number Minimum allowed value.
---@param max number Maximum allowed value.
---@return LArray A new array with clamped values.
function LArray:clamp(min, max) end

--- Creates an independent deep copy of this array. Mutations on the clone do not affect the original.
---@return LArray A new array with identical shape, dtype, and values.
function LArray:clone() end

--- Applies a 1D convolution kernel to a 1D array. Useful for smoothing, edge detection, or signal filtering.
---@param kernel LArray A 1D kernel array.
---@return LArray A new convolved 1D array.
function LArray:convolve1d(kernel) end

--- Applies a 2D convolution kernel to a 2D array, useful for image filters like blur, sharpen, or edge detect.
---@param kernel LArray A 2D array representing the convolution kernel.
---@return LArray A new 2D array with the convolution result.
function LArray:convolve2D(kernel) end

--- Computes 1D cross-correlation between this array and a template. Finds where the template best matches the signal.
---@param template LArray A 1D template array to correlate against.
---@return LArray A new array of correlation values at each offset.
function LArray:correlate1d(template) end

--- Returns the number of elements in the array that are not equal to zero.
---@return number Count of non-zero elements.
function LArray:countNonZero() end

--- Computes the sample covariance between this array and another. Both must be 1D with the same length.
---@param other LArray The second variable array.
---@return number The covariance value.
function LArray:covariance(other) end

--- Computes the 2D cross product (scalar) of two 2-element vectors. Result is positive for counter-clockwise orientation.
---@param other LArray A 2-element vector.
---@return number The z-component of the 3D cross product (a scalar in 2D).
function LArray:cross2d(other) end

--- Returns a new array containing the cumulative sum of elements. Each element is the running total up to that index.
---@return LArray A new array of cumulative sums.
function LArray:cumsum() end

--- Returns a new array containing successive differences between elements. Higher orders apply the operation repeatedly.
---@param order? number Number of times to differentiate (default 1). Higher order = smoother derivative estimate.
---@return LArray A new array shorter by `order` elements.
function LArray:diff(order) end

--- Applies morphological dilation to a 2D binary mask, expanding non-zero regions by the given radius.
---@param radius number The dilation radius in cells.
---@return LArray A new dilated mask array.
function LArray:dilate(radius) end

--- Returns a new array with each element divided by the other array or scalar. Does not modify the original.
---@param value LArray|number An array for element-wise division or a scalar divisor.
---@return LArray A new array with the quotient.
function LArray:div(value) end

--- Divides this array element-wise by another array, modifying it in place. Shapes must match.
---@param other LArray The array to divide by.
---@return nil No return value.
function LArray:divInplace(other) end

--- Computes the dot product (inner product) of two 1D arrays. Both must be 1D with the same length.
---@param other LArray The other vector to dot with.
---@return number The scalar dot product result.
function LArray:dot(other) end

--- Estimates the dominant eigenvalue and eigenvector using power iteration. Good for largest principal component.
---@param max_iter? number Maximum iterations (0 = use default internal limit).
---@param tol? number Convergence tolerance (0 = use default).
---@return table Table with "value" (eigenvalue number) and "vector" (eigenvector as a number table).
function LArray:eigenPower(max_iter, tol) end

--- Returns a new array where each element is 1.0 if equal to the comparand, 0.0 otherwise.
---@param value LArray|number An array or scalar to compare against.
---@return LArray A boolean mask array (1.0 = true, 0.0 = false).
function LArray:eq(value) end

--- Applies morphological erosion to a 2D binary mask, shrinking non-zero regions by the given radius.
---@param radius number The erosion radius in cells.
---@return LArray A new eroded mask array.
function LArray:erode(radius) end

--- Evaluates a Lua expression string on each element, where `x` represents the current element value.
---@param expr string A Lua expression using variable `x` (e.g. "x * 2 + 1" or "math.sin(x)").
---@return LArray A new array with the evaluated results.
function LArray:eval(expr) end

--- Overwrites every element in the array with the given value. Modifies the array in place.
---@param val number The value to fill all elements with.
---@return nil No return value.
function LArray:fill(val) end

--- Performs a flood-fill on a 2D array starting at the given 1-based row and column, replacing connected regions with the new value.
---@param row number 1-based starting row.
---@param col number 1-based starting column.
---@param val number The fill value to spread to connected cells.
---@return LArray A new 2D array with the flood-filled region.
function LArray:floodFill(row, col, val) end

--- Reads a single element value at the given 1-based indices. For a 2D array use `arr:get(row, col)`.
---@param ... number One or more 1-based integer indices, one per dimension.
---@return number The element value at the specified position.
function LArray:get(...) end

--- Returns the element data type name of the array (e.g. "float32", "float64", "int32").
---@return string The data type identifier.
function LArray:getDataType() end

--- Returns the number of dimensions (rank) of the array. A 1D vector returns 1, a 2D matrix returns 2, etc.
---@return number The number of dimensions.
function LArray:getDimensions() end

--- Extracts a rectangular sub-region from a 2D array starting at the given 1-based row and column.
---@param row number 1-based top-left row of the region.
---@param col number 1-based top-left column of the region.
---@param rows number Number of rows to extract.
---@param cols number Number of columns to extract.
---@return LArray A new 2D array containing the extracted sub-region.
function LArray:getRegion(row, col, rows, cols) end

--- Returns the shape of the array as a table of dimension sizes (e.g. {3, 4} for a 3x4 matrix).
---@return table Array of integers representing each dimension's size.
function LArray:getShape() end

--- Returns the total number of elements in the array across all dimensions.
---@return number Total element count.
function LArray:getSize() end

--- Returns a new array where each element is 1.0 if greater than the comparand, 0.0 otherwise.
---@param value LArray|number An array or scalar to compare against.
---@return LArray A boolean mask array (1.0 = true, 0.0 = false).
function LArray:gt(value) end

--- Returns a new array where each element is 1.0 if greater than or equal to the comparand, 0.0 otherwise.
---@param value LArray|number An array or scalar to compare against.
---@return LArray A boolean mask array (1.0 = true, 0.0 = false).
function LArray:gte(value) end

--- Computes a histogram of the array values with the given number of bins. Returns a table of {lo, hi, count} entries.
---@param bins number Number of histogram bins.
---@param lo? number Lower bound of the range (nil = use array minimum).
---@param hi? number Upper bound of the range (nil = use array maximum).
---@return table Array of tables, each with fields "lo", "hi", and "count".
function LArray:histogram(bins, lo, hi) end

--- Returns whether the array data resides on the GPU. Currently always returns false (CPU-only arrays).
---@return boolean Always false in the current implementation.
function LArray:isOnGPU() end

--- Solves the linear system Ax = b for x, where this array is the coefficient matrix A.
---@param b LArray The right-hand side vector or matrix.
---@return LArray The solution vector x.
function LArray:linsolve(b) end

--- Returns a new array where each element is 1.0 if less than the comparand, 0.0 otherwise.
---@param value LArray|number An array or scalar to compare against.
---@return LArray A boolean mask array (1.0 = true, 0.0 = false).
function LArray:lt(value) end

--- Returns a new array where each element is 1.0 if less than or equal to the comparand, 0.0 otherwise.
---@param value LArray|number An array or scalar to compare against.
---@return LArray A boolean mask array (1.0 = true, 0.0 = false).
function LArray:lte(value) end

--- Computes the LU decomposition with partial pivoting. Returns a table with n, det_sign, perm, and lu_data.
---@return table Table with "n" (size), "det_sign" (+1 or -1), "perm" (permutation), "lu_data" (packed LU factors).
function LArray:luDecompose() end

--- Applies a Lua function to each element, returning a new array of the results. The function receives one number and must return one number.
---@param func function A function(x) -> number to apply to each element.
---@return LArray A new array with the mapped values.
function LArray:map(func) end

--- Performs matrix multiplication between this array and another. Both must be 2D with compatible inner dimensions.
---@param other LArray The right-hand matrix to multiply with.
---@return LArray A new array containing the matrix product.
function LArray:matmul(other) end

--- Returns the largest element value, or reduces along an axis returning element-wise maximums.
---@param axis? number Optional 1-based axis to find maximums along. Nil returns the global maximum.
---@return number LArray | A scalar maximum when no axis given, or a reduced array along the specified axis.
function LArray:max(axis) end

--- Returns the arithmetic mean of all elements, or the mean along an axis.
---@param axis? number Optional 1-based axis to compute mean along. Nil averages all elements.
---@return number LArray | A scalar average when no axis given, or a reduced array along the specified axis.
function LArray:mean(axis) end

--- Returns the smallest element value, or reduces along an axis returning element-wise minimums.
---@param axis? number Optional 1-based axis to find minimums along. Nil returns the global minimum.
---@return number LArray | A scalar minimum when no axis given, or a reduced array along the specified axis.
function LArray:min(axis) end

--- Returns a new array with each element multiplied by the other array or scalar. Does not modify the original.
---@param value LArray|number An array for element-wise multiplication or a scalar multiplier.
---@return LArray A new array with the product.
function LArray:mul(value) end

--- Multiplies this array element-wise by another array, modifying it in place. Shapes must match.
---@param other LArray The array to multiply by.
---@return nil No return value.
function LArray:mulInplace(other) end

--- Returns a new array with each element negated (multiplied by -1).
---@return LArray A new array with negated values.
function LArray:neg() end

--- Returns a new array where each element is 1.0 if not equal to the comparand, 0.0 otherwise.
---@param value LArray|number An array or scalar to compare against.
---@return LArray A boolean mask array (1.0 = true, 0.0 = false).
function LArray:neq(value) end

--- Returns a new array with values linearly rescaled so the minimum maps to lo and the maximum maps to hi.
---@param lo number Target minimum value.
---@param hi number Target maximum value.
---@return LArray A new array with values in [lo, hi].
function LArray:normalizeRange(lo, hi) end

--- Returns a new 1D array normalized to unit length (magnitude 1). Useful for direction vectors.
---@return LArray A new unit-length array.
function LArray:normalizeVec() end

--- Computes the outer product of two 1D arrays, producing a 2D matrix where result[i][j] = a[i] * b[j].
---@param other LArray The second 1D vector.
---@return LArray A new 2D array (matrix) of the outer product.
function LArray:outer(other) end

--- Computes the Pearson correlation coefficient between this array and another (-1 to +1 range).
---@param other LArray The second variable array.
---@return number Correlation coefficient between -1.0 and 1.0.
function LArray:pearsonCorr(other) end

--- Returns the value at the given percentile (0-100) of the sorted array data using linear interpolation.
---@param p number Percentile between 0 and 100.
---@return number The interpolated value at that percentile.
function LArray:percentile(p) end

--- Returns a new array with each element raised to the given exponent.
---@param exp number The exponent to raise each element to.
---@return LArray A new array with the power result.
function LArray:pow(exp) end

--- Reduces all elements to a single value by applying a binary function sequentially with an accumulator.
---@param func function A function(accumulator, element) -> new_accumulator.
---@param init number The initial accumulator value.
---@return number The final accumulated result.
function LArray:reduce(func, init) end

--- Returns a new array with the same data rearranged into the given shape. Total element count must match.
---@param shape table New shape as a table of dimension sizes (e.g. {2, 6} for a 2x6 matrix).
---@return LArray A new array with the requested shape.
function LArray:reshape(shape) end

--- Like reduce but stores each intermediate accumulator value, producing a running-total array.
---@param func function A function(accumulator, element) -> new_accumulator.
---@param init number The initial accumulator value.
---@return LArray A new array where each element is the accumulator state at that step.
function LArray:scan(func, init) end

--- Writes a value at the given 1-based indices. The last argument is the value; preceding arguments are indices.
---@param ... number One or more 1-based indices followed by the value to store.
---@return nil No return value.
function LArray:set(...) end

--- Copies a source array into a rectangular sub-region of this array starting at the given 1-based position. Modifies in place.
---@param row number 1-based top-left row where writing starts.
---@param col number 1-based top-left column where writing starts.
---@param source LArray The 2D array to paste into this region.
---@return nil No return value.
function LArray:setRegion(row, col, source) end

--- Applies Sobel edge-detection operators to a 2D array, returning horizontal and vertical gradient arrays.
---@return table A table with fields "gx" (horizontal gradient LArray) and "gy" (vertical gradient LArray).
function LArray:sobel() end

--- Returns a new array with the square root of each element. Negative values produce NaN.
---@return LArray A new array with square root values.
function LArray:sqrt() end

--- Returns a new array with each element subtracted by the other array or scalar. Does not modify the original.
---@param value LArray|number An array for element-wise subtraction or a scalar to subtract.
---@return LArray A new array with the difference.
function LArray:sub(value) end

--- Subtracts another array element-wise from this array, modifying it in place. Shapes must match.
---@param other LArray The array to subtract.
---@return nil No return value.
function LArray:subInplace(other) end

--- Returns the sum of all elements, or reduces along an axis returning a smaller array.
---@param axis? number Optional 1-based axis to sum along. Nil sums all elements into a scalar.
---@return number LArray | A scalar total when no axis given, or a reduced array along the specified axis.
function LArray:sum(axis) end

--- Returns a new binary mask array where elements >= val become 1.0 and the rest become 0.0.
---@param val number The threshold value.
---@return LArray A new binary mask array.
function LArray:threshold(val) end

--- Flattens the array into a Lua table of numbers in row-major order. Useful for passing data to other APIs.
---@return table A flat array of all element values.
function LArray:toTable() end

--- Applies this 3x3 affine matrix to a set of 2D points (Nx2 array), returning transformed points.
---@param pts LArray An Nx2 array of 2D points to transform.
---@return LArray A new Nx2 array of transformed points.
function LArray:transformPoints(pts) end

--- Returns the matrix transpose of a 2D array (swaps rows and columns). Only valid for 2D arrays.
---@return LArray A new transposed array.
function LArray:transpose() end

--- Returns the type name of this userdata object.
---@return string Always returns "LArray".
function LArray:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LArray", "Array", or "Object").
---@return boolean True if the name matches.
function LArray:typeOf(name) end

--- Selects elements from this array where the mask is non-zero, otherwise takes from the other array.
---@param mask LArray A boolean mask array (non-zero = select from this, zero = select from other).
---@param other LArray The fallback array for positions where the mask is zero.
---@return LArray A new array with conditionally selected elements.
function LArray:where(mask, other) end

--- Returns a new array with each element standardized to zero mean and unit variance (Z-score normalization).
---@return LArray A new array with mean≈0 and stddev≈1.
function LArray:zscore() end

--- Creates a 3x3 affine transformation matrix combining translation, rotation, and scale for 2D points.
---@param tx number Translation along x.
---@param ty number Translation along y.
---@param angle_rad number Rotation angle in radians.
---@param sx number Scale factor along x.
---@param sy number Scale factor along y.
---@return LArray A 3x3 affine transformation matrix.
lurek.compute.affine2d = function(tx, ty, angle_rad, sx, sy) end

--- Computes the Fast Fourier Transform of a real-valued sample array. Returns complex frequency bins as {re, im} tables.
---@param samples table Flat array of real-valued time-domain samples.
---@return table Array of tables, each with "re" and "im" fields for the complex frequency component.
lurek.compute.fft = function(samples) end

--- Computes the FFT and returns only the magnitude (amplitude) spectrum, discarding phase information.
---@param samples table Flat array of real-valued time-domain samples.
---@return table Array of magnitude values for each frequency bin.
lurek.compute.fftMagnitude = function(samples) end

--- Creates an array from a flat Lua table of numbers, optionally reshaping it to the given dimensions.
---@param data table Flat array of numeric values.
---@param shape? table Optional shape to reshape into (default is a 1D array matching data length).
---@param dtype? string Data type (default "float32").
---@return LArray A new array initialized from the provided data.
lurek.compute.fromTable = function(data, shape, dtype) end

--- Creates a normalized 2D Gaussian blur kernel of the given size. Use with convolve2D for image smoothing.
---@param size number Kernel side length in pixels (should be odd, e.g. 3, 5, 7).
---@param sigma number Standard deviation controlling blur spread.
---@return LArray A 2D array (size x size) representing the Gaussian kernel.
lurek.compute.gaussianKernel = function(size, sigma) end

--- Returns the current parallel-execution element threshold. Arrays larger than this may use multi-threaded operations.
---@return number The current threshold element count.
lurek.compute.getParThreshold = function() end

--- Computes the inverse FFT, converting complex frequency bins back to real-valued time-domain samples.
---@param freqs table Array of {re, im} tables from a previous fft call.
---@return table Flat array of reconstructed real-valued samples.
lurek.compute.ifft = function(freqs) end

--- Creates a new zero-initialized N-dimensional array with the given shape and optional data type.
---@param shape table Dimension sizes (e.g. {3, 4} for a 3x4 matrix).
---@param dtype? string Data type: "float32" (default), "float64", "int32", or "uint8".
---@return LArray A new array filled with zeros.
lurek.compute.newArray = function(shape, dtype) end

--- Creates a new array where every element is initialized to 1.0. Useful for multiplicative identities or masks.
---@param shape table Dimension sizes.
---@param dtype? string Data type: "float32" (default), "float64", "int32", or "uint8".
---@return LArray A new array filled with ones.
lurek.compute.ones = function(shape, dtype) end

--- Creates a 1D array of evenly spaced values from start (inclusive) to stop (exclusive) with the given step.
---@param start number First value in the sequence.
---@param stop number Upper bound (exclusive) of the sequence.
---@param step? number Spacing between values (default 1.0).
---@param dtype? string Data type (default "float32").
---@return LArray A new 1D array of the generated sequence.
lurek.compute.range = function(start, stop, step, dtype) end

--- Creates a 2x2 rotation matrix for the given angle in radians. Use with matmul to rotate 2D vectors.
---@param angle_rad number Rotation angle in radians (positive = counter-clockwise).
---@return LArray A 2x2 rotation matrix array.
lurek.compute.rotate2dMatrix = function(angle_rad) end

--- Sets the minimum array size for parallel execution. Smaller arrays use single-threaded ops. Returns the previous value.
---@param threshold number Minimum element count to enable parallel operations (clamped to >= 1).
---@return number The previous threshold value.
lurek.compute.setParThreshold = function(threshold) end

--- Creates a new array filled with zeros. Identical to newArray but named for clarity.
---@param shape table Dimension sizes (e.g. {10} for a 10-element vector).
---@param dtype? string Data type: "float32" (default), "float64", "int32", or "uint8".
---@return LArray A new zero-filled array.
lurek.compute.zeros = function(shape, dtype) end

---@class lurek.data
lurek.data = {}

--- Creates a new byte buffer, either zero-filled with the given size or initialized from a string.
---@class LByteData
LByteData = {}

--- Creates an independent copy of this byte buffer with identical contents.
---@return LByteData A new byte buffer containing the same data.
function LByteData:clone() end

--- Reads a single bit from the buffer, returning true if the bit is set to 1.
---@param byte_offset number Zero-based byte index.
---@param bit_offset number Bit position within that byte (0-7, where 0 is the least significant bit).
---@return boolean True if the bit is 1, false if 0.
function LByteData:getBit(byte_offset, bit_offset) end

--- Reads a single byte at the given offset, raising an error if out of bounds.
---@param offset number Zero-based byte offset to read from.
---@return number The byte value (0-255).
function LByteData:getByte(offset) end

--- Returns the total number of bytes in this byte buffer.
---@return number Buffer size in bytes.
function LByteData:getSize() end

--- Interprets the buffer contents as a UTF-8 string and returns it.
---@return string The buffer data as a Lua string.
function LByteData:getString() end

--- Reads a sequence of 1-32 consecutive bits starting at the given byte and bit offset, returned as an unsigned integer.
---@param byte_offset number Zero-based starting byte index.
---@param bit_offset number Starting bit position within that byte (0-7).
---@param count number Number of bits to read (1-32).
---@return number The unsigned integer value assembled from the read bits (LSB first).
function LByteData:readBits(byte_offset, bit_offset, count) end

--- Sets or clears a single bit within a byte, useful for compact flag storage or bitmask manipulation.
---@param byte_offset number Zero-based byte index.
---@param bit_offset number Bit position within that byte (0-7, where 0 is the least significant bit).
---@param value boolean True to set the bit to 1, false to clear it to 0.
---@return nil No return value.
function LByteData:setBit(byte_offset, bit_offset, value) end

--- Writes a single byte at the given offset, raising an error if out of bounds.
---@param offset number Zero-based byte offset to write to.
---@param value number Byte value to write (0-255).
---@return nil No return value.
function LByteData:setByte(offset, value) end

--- Creates a read-only typed view over raw binary data for structured field access without copying.
---@class LDataView
LDataView = {}

--- Reads a 64-bit IEEE 754 double-precision float (little-endian) at the given byte offset.
---@param offset number Zero-based byte offset to read from.
---@return number The double-precision value.
function LDataView:getDouble(offset) end

--- Reads a 32-bit IEEE 754 floating-point value (little-endian) at the given byte offset.
---@param offset number Zero-based byte offset to read from.
---@return number The float value promoted to Lua number precision.
function LDataView:getFloat(offset) end

--- Reads a signed 16-bit integer (little-endian) at the given byte offset.
---@param offset number Zero-based byte offset to read from.
---@return number The signed 16-bit value.
function LDataView:getInt16(offset) end

--- Reads a signed 32-bit integer (little-endian) at the given byte offset.
---@param offset number Zero-based byte offset to read from.
---@return number The signed 32-bit value.
function LDataView:getInt32(offset) end

--- Reads a signed 8-bit integer (-128 to 127) at the given byte offset.
---@param offset number Zero-based byte offset to read from.
---@return number The signed byte value.
function LDataView:getInt8(offset) end

--- Returns the total byte length of this data view.
---@return number Number of bytes accessible through this view.
function LDataView:getSize() end

--- Reads an unsigned 16-bit integer (little-endian) at the given byte offset.
---@param offset number Zero-based byte offset to read from.
---@return number The unsigned 16-bit value (0-65535).
function LDataView:getUInt16(offset) end

--- Reads an unsigned 32-bit integer (little-endian) at the given byte offset.
---@param offset number Zero-based byte offset to read from.
---@return number The unsigned 32-bit value (0 to ~4 billion).
function LDataView:getUInt32(offset) end

--- Reads an unsigned 8-bit integer (0-255) at the given byte offset.
---@param offset number Zero-based byte offset to read from.
---@return number The unsigned byte value.
function LDataView:getUInt8(offset) end

--- Returns the type name of this userdata object.
---@return string Always returns "LDataView".
function LDataView:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LDataView" or "Object").
---@return boolean True if the name matches.
function LDataView:typeOf(name) end

--- Sequential binary writer that builds byte payloads incrementally with typed write methods, seek, and export to string.
---@class LDataWriter
LDataWriter = {}

--- Returns the total number of bytes written so far.
---@return number Current buffer length in bytes.
function LDataWriter:len() end

--- Moves the write cursor to an absolute byte position, allowing overwrites of previously written data.
---@param pos number Zero-based byte position to seek to.
---@return nil No return value.
function LDataWriter:seek(pos) end

--- Returns the current write cursor position.
---@return number Zero-based byte offset of the cursor.
function LDataWriter:tell() end

--- Exports the entire written buffer as a binary string for saving or sending.
---@return string The accumulated binary data.
function LDataWriter:toBytes() end

--- Returns the type name of this userdata object.
---@return string Always returns "LDataWriter".
function LDataWriter:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LDataWriter" or "Object").
---@return boolean True if the name matches.
function LDataWriter:typeOf(name) end

--- Writes raw bytes directly without any length prefix, useful for appending binary blobs.
---@param data string Raw byte data to append.
---@return nil No return value.
function LDataWriter:writeBytes(data) end

--- Writes a 32-bit float in little-endian byte order and advances by 4 bytes.
---@param value number Floating-point value to write.
---@return nil No return value.
function LDataWriter:writeF32LE(value) end

--- Writes a 64-bit double in little-endian byte order and advances by 8 bytes.
---@param value number Double-precision value to write.
---@return nil No return value.
function LDataWriter:writeF64LE(value) end

--- Writes a signed 16-bit integer in little-endian byte order and advances by 2 bytes.
---@param value number Value to write (-32768 to 32767).
---@return nil No return value.
function LDataWriter:writeI16LE(value) end

--- Writes a signed 32-bit integer in little-endian byte order and advances by 4 bytes.
---@param value number Value to write.
---@return nil No return value.
function LDataWriter:writeI32LE(value) end

--- Writes a signed 8-bit integer (-128 to 127) at the current position and advances by 1 byte.
---@param value number Value to write (clamped to i8 range).
---@return nil No return value.
function LDataWriter:writeI8(value) end

--- Writes a length-prefixed UTF-8 string (4-byte u32 length header followed by string bytes).
---@param str string The string to write.
---@return nil No return value.
function LDataWriter:writeString(str) end

--- Writes an unsigned 16-bit integer in big-endian byte order and advances by 2 bytes.
---@param value number Value to write (0-65535).
---@return nil No return value.
function LDataWriter:writeU16BE(value) end

--- Writes an unsigned 16-bit integer in little-endian byte order and advances by 2 bytes.
---@param value number Value to write (0-65535).
---@return nil No return value.
function LDataWriter:writeU16LE(value) end

--- Writes an unsigned 32-bit integer in little-endian byte order and advances by 4 bytes.
---@param value number Value to write (0 to ~4 billion).
---@return nil No return value.
function LDataWriter:writeU32LE(value) end

--- Writes an unsigned 8-bit integer (0-255) at the current position and advances by 1 byte.
---@param value number Value to write (clamped to u8 range).
---@return nil No return value.
function LDataWriter:writeU8(value) end

--- Fixed-capacity circular buffer that evicts the oldest element when full, useful for recent-history tracking like input replay, damage logs, or chat messages.
---@class LRingBuffer
LRingBuffer = {}

--- Returns the maximum number of elements the ring buffer can hold before evicting.
---@return number The fixed capacity set at creation time.
function LRingBuffer:capacity() end

--- Removes all elements from the ring buffer, releasing their references.
---@return nil No return value.
function LRingBuffer:clear() end

--- Checks whether the ring buffer contains no elements.
---@return boolean True if the buffer has zero stored elements.
function LRingBuffer:isEmpty() end

--- Checks whether the ring buffer is at maximum capacity and will evict on next push.
---@return boolean True if current length equals capacity.
function LRingBuffer:isFull() end

--- Returns the number of elements currently stored in the ring buffer.
---@return number Current element count (0 to capacity).
function LRingBuffer:len() end

--- Returns the oldest value without removing it from the buffer.
---@return LuaValue The oldest stored value, or nil if the buffer is empty.
function LRingBuffer:peek() end

--- Returns the most recently added value without removing it from the buffer.
---@return LuaValue The newest stored value, or nil if the buffer is empty.
function LRingBuffer:peekNewest() end

--- Removes and returns the oldest value from the front of the ring buffer.
---@return LuaValue The oldest stored value, or nil if the buffer is empty.
function LRingBuffer:pop() end

--- Adds a value to the back of the ring buffer, evicting the oldest entry if the buffer is at capacity.
---@param value LuaValue The value to store (any Lua type including tables, userdata, etc.).
---@return boolean True if an old value was evicted to make room, false if there was space.
function LRingBuffer:push(value) end

--- Copies all elements into a Lua array table ordered from oldest to newest.
---@return table An array-like table containing all stored values.
function LRingBuffer:toTable() end

--- Returns the type name of this userdata object.
---@return string Always returns "LRingBuffer".
function LRingBuffer:type() end

--- Checks whether this object matches the given type name.
---@param name string Type name to check ("LRingBuffer" or "Object").
---@return boolean True if the name matches.
function LRingBuffer:typeOf(name) end

--- Compresses raw binary data using the specified algorithm, useful for reducing save file size or network payload.
---@param format string Compression algorithm: "deflate", "zlib", "gzip", or "lz4".
---@param data string Raw binary data to compress.
---@param level? number Compression level 0-9 (default 6; higher = smaller but slower).
---@return string The compressed binary data.
lurek.data.compress = function(format, data, level) end

--- Compresses multiple data chunks into a single compressed output, avoiding concatenation overhead for streaming or batched data.
---@param format string Compression algorithm: "deflate", "zlib", "gzip", or "lz4".
---@param chunks string|table A single string or an array of strings to compress together.
---@param level? number Compression level 0-9 (default 6).
---@return string The compressed binary data.
lurek.data.compressChunks = function(format, chunks, level) end

--- Computes the CRC-32 checksum of binary data, useful for quick integrity checks on save files or network packets.
---@param data string Raw binary data to checksum.
---@return number The 32-bit CRC value as an integer.
lurek.data.crc32 = function(data) end

--- Decodes a text-encoded string back into raw binary data.
---@param format string Encoding format: "base64", "base32", or "hex".
---@param encoded string The encoded text string to decode.
---@return string The decoded raw binary data.
lurek.data.decode = function(format, encoded) end

--- Decompresses data that was previously compressed with the matching algorithm.
---@param format string Compression algorithm: "deflate", "zlib", "gzip", or "lz4".
---@param data string Compressed binary data to decompress.
---@return string The original uncompressed data.
lurek.data.decompress = function(format, data) end

--- Decompresses multiple compressed chunks into a single output, the inverse of compressChunks.
---@param format string Compression algorithm: "deflate", "zlib", "gzip", or "lz4".
---@param chunks string|table A single compressed string or array of compressed strings.
---@return string The decompressed binary data.
lurek.data.decompressChunks = function(format, chunks) end

--- Encodes raw binary data into a text-safe string representation for storage or transmission.
---@param format string Encoding format: "base64", "base32", or "hex".
---@param data string Raw binary data to encode.
---@return string The encoded text string.
lurek.data.encode = function(format, data) end

--- Serializes a Lua table into a TOML-formatted string for writing configuration files.
---@param tbl table Lua table to encode (must contain only TOML-compatible types: strings, numbers, booleans, arrays, tables).
---@return string TOML-formatted text.
lurek.data.encodeToml = function(tbl) end

--- Deserializes binary data produced by toMsgPack back into a Lua value.
---@param bytes string Binary data previously produced by toMsgPack.
---@return LuaValue The reconstructed Lua value.
lurek.data.fromMsgPack = function(bytes) end

--- Calculates the byte size that would result from packing the given values with the format string, without actually packing.
---@param fmt string Format string describing the data layout.
---@param ... LuaValue Values that would be packed (needed for variable-length types like strings).
---@return number The total byte size of the packed output.
lurek.data.getPackedSize = function(fmt, ...) end

--- Computes a cryptographic or fast hash of binary data, returning the hex digest string.
---@param algorithm string Hash algorithm: "md5", "sha1", "sha256", "sha512", "xxh3", or "xxh64".
---@param data string Raw binary data to hash.
---@return string Hex-encoded hash digest.
lurek.data.hash = function(algorithm, data) end

--- Creates a new byte buffer, either zero-filled with the given size or initialized from a string.
---@param sizeOrString number|string Number of bytes to allocate (zero-filled), or a string whose bytes are copied in.
---@return LByteData A mutable byte buffer userdata for low-level binary manipulation.
lurek.data.newByteData = function(sizeOrString) end

--- Creates a read-only typed view over raw binary data for structured field access without copying.
---@param data string Raw binary source data to view.
---@param offset? number Byte offset into the data to start the view (default 0).
---@param size? number Number of bytes the view covers (default: remaining bytes from offset).
---@return LDataView A read-only view userdata with typed getter methods.
lurek.data.newDataView = function(data, offset, size) end

--- Creates a new fixed-capacity ring buffer for storing a rolling window of recent values (e.g. input history, damage log).
---@param capacity number Maximum number of elements before the oldest is evicted (must be > 0).
---@return LRingBuffer A new ring buffer userdata object.
lurek.data.newRingBuffer = function(capacity) end

--- Creates a new sequential binary writer for building binary payloads byte-by-byte with typed write methods.
---@return LDataWriter A mutable writer userdata with write, seek, and export methods.
lurek.data.newWriter = function() end

--- Packs Lua values into a binary string using a format descriptor (similar to Lua 5.3 string.pack).
---@param fmt string Format string specifying types: b(i8), B(u8), h(i16), H(u16), i/l(i32), I/L(u32), q(i64), f(f32), d(f64), s(length-prefixed string), z(null-terminated string).
---@param ... LuaValue Values to pack matching the format specifiers in order.
---@return string Binary string containing the packed data.
lurek.data.pack = function(fmt, ...) end

--- Parses a TOML-formatted string into a Lua table, used for reading configuration files.
---@param text string TOML source text to parse.
---@return table Lua table representing the parsed TOML structure.
lurek.data.parseToml = function(text) end

--- Reads typed values from a binary string according to format specifiers, inverse of write.
---@param fmt string Format string matching the layout written by data.write.
---@param data string Binary string to read from.
---@param offset? number Byte offset to start reading (default 0).
---@return LuaValue a The deserialized values in order.
---@return ... b The deserialized values in order.
lurek.data.read = function(fmt, data, offset) end

--- Returns the total byte size of a binary format string, useful for pre-allocating buffers or validating data length.
---@param fmt string Format string with fixed-size type specifiers.
---@return number Total byte size the format would occupy.
lurek.data.size = function(fmt) end

--- Serializes a Lua value into a compact binary format (JSON-backed) for efficient storage or network transfer.
---@param value LuaValue The Lua value to serialize (table, string, number, boolean, or nil).
---@return string Binary-encoded representation of the value.
lurek.data.toMsgPack = function(value) end

--- Unpacks values from a binary string according to a format descriptor, returning the values plus the next read position.
---@param fmt string Format string specifying the layout of packed data.
---@param data string Binary string to unpack from.
---@param offset? number Byte offset to start reading from (default 0).
---@return LuaValue a The unpacked values followed by the next byte position after the last read.
---@return ... b The unpacked values followed by the next byte position after the last read.
---@return number c The unpacked values followed by the next byte position after the last read.
lurek.data.unpack = function(fmt, data, offset) end

--- Writes values into a binary string using typed format specifiers for precise binary protocol construction.
---@param fmt string Format string: u8, i8, u16, i16, u32, i32, u64, i64, f32, f64, bool, str, bytes.
---@param ... LuaValue Values to serialize in order matching the format.
---@return string Binary string containing the serialized data.
lurek.data.write = function(fmt, ...) end

---@class lurek.dataframe
lurek.dataframe = {}

--- A tabular data container with named, typed columns. Supports row/column manipulation, filtering,
---@class LDataFrame
LDataFrame = {}

--- Adds a new column to the DataFrame with an optional default value for all existing rows.
---@param name string The name for the new column. Must be unique.
---@param default? LuaValue Default cell value for existing rows. Nil if omitted.
---@return nil Errors if a column with that name already exists.
function LDataFrame:addColumn(name, default) end

--- Appends a new row to the DataFrame. Pass a table mapping column names to values, or nil/nothing for an empty row.
---@param row_tbl? table Key-value pairs {colName = value, ...}. Missing columns get nil.
---@return number The 1-based row index of the new row.
function LDataFrame:addRow(row_tbl) end

--- Appends multiple rows at once for better performance than calling addRow in a loop.
---@param rows table Array of row arrays, e.g. {{1,"a"}, {2,"b"}}. Values must match column count.
function LDataFrame:addRowBatch(rows) end

--- Applies a Lua function to every cell in the specified column, replacing each value with the function's return.
---@param col string|number Column to transform.
---@param func function A function(cellValue) -> newValue applied to each cell.
function LDataFrame:apply(col, func) end

--- Creates a deep copy of this DataFrame. Changes to the clone do not affect the original.
---@return LDataFrame An independent copy of the DataFrame.
function LDataFrame:clone() end

--- Returns a sequential table of all column names in their definition order.
---@return table Array of column name strings, e.g. {"name", "score", "level"}.
function LDataFrame:columns() end

--- Computes the Pearson correlation coefficient between two numeric columns.
---@param col_a string|number First column.
---@param col_b string|number Second column.
---@return number Pearson correlation coefficient.
function LDataFrame:corr(col_a, col_b) end

--- Computes a correlation matrix across all numeric columns. Each cell [i][j] is the Pearson
---@return LDataFrame A square DataFrame where rows and columns are named after the numeric columns.
function LDataFrame:correlationMatrix() end

--- Returns the total number of non-nil cell values across all columns and rows.
---@return number The count of cells that are not nil.
function LDataFrame:count() end

--- Groups by a column and counts occurrences of each distinct value.
---@param col string|number The column to count distinct values in.
---@return LDataFrame A two-column DataFrame with value counts.
function LDataFrame:countBy(col) end

--- Returns a summary statistics DataFrame for all numeric columns (count, mean, std, min, max, median).
---@return LDataFrame A new DataFrame where each row is a stat and each column is a source column.
function LDataFrame:describe() end

--- Returns a new DataFrame with rows removed where the specified column has a nil value.
---@param col string|number Column to check for nil values.
---@return LDataFrame A new DataFrame with nil-rows removed.
function LDataFrame:dropNil(col) end

--- Computes the Shannon entropy of a column, measuring how spread out or unpredictable the values are.
---@param col string|number Column to compute entropy for.
---@return number The Shannon entropy in bits.
function LDataFrame:entropy(col) end

--- Replaces all nil values in the specified column with a given fill value. Modifies the DataFrame in place.
---@param col string|number Column to fill.
---@param val LuaValue The value to substitute for nil cells.
function LDataFrame:fillNil(col, val) end

--- Returns a new DataFrame containing only rows where the comparison is true.
---@param col string|number Column to filter on.
---@param op string Comparison operator string.
---@param val LuaValue The value to compare each cell against.
---@return LDataFrame A new DataFrame with matching rows only.
function LDataFrame:filter(col, op, val) end

--- Returns all values in a column as a sequential table. Useful for extracting a series for charting or aggregation.
---@param col string|number Column name or 1-based index.
---@return table Array of cell values in row order (may include nil entries).
function LDataFrame:getColumn(col) end

--- Returns all values in a column as a flat array of numbers. Non-numeric cells become NaN.
---@param col string|number Column name or 1-based index.
---@return table Array of f64 numbers (NaN for non-numeric cells).
function LDataFrame:getColumnAsF64(col) end

--- Returns a single row as a table mapping column names to their values. Useful for inspecting individual records.
---@param row number The 1-based row index to retrieve.
---@return table A key-value table {colName = value, ...} for that row.
function LDataFrame:getRow(row) end

--- Gets a single cell value by row index and column reference.
---@param row number The 1-based row index.
---@param col string|number Column name or 1-based column index.
---@return LuaValue The cell value (number, string, boolean, or nil).
function LDataFrame:getValue(row, col) end

--- Groups by one column and aggregates another column using a named function.
---@param group_col string|number Column to group by.
---@param agg_col string|number Column to aggregate.
---@param fn_name string Aggregation function name.
---@return LDataFrame A new DataFrame with group keys and aggregated results.
function LDataFrame:groupAgg(group_col, agg_col, fn_name) end

--- Groups rows by distinct values in a column and returns a table mapping each group key to its sub-DataFrame.
---@param col string|number Column to group by.
---@return table A table where keys are the distinct column values and values are LDataFrame sub-frames.
function LDataFrame:groupBy(col) end

--- Groups rows by a column and returns a LGroupedFrame object that supports custom aggregation via :aggregate().
---@param col string|number Column to group by.
---@return LGroupedFrame A grouped frame object for chained aggregation.
function LDataFrame:groupByObj(col) end

--- Returns a new DataFrame containing only the first N rows. Defaults to 5 if not specified.
---@param n? number Number of rows to take from the top. Defaults to 5.
---@return LDataFrame A new DataFrame with at most N rows.
function LDataFrame:head(n) end

--- Joins this DataFrame with another on matching column values, producing a combined DataFrame.
---@param other LDataFrame The other DataFrame to join with.
---@param this_col string|number The join key column in this frame.
---@param other_col string|number The join key column in the other frame.
---@param jtype? string Join type: "inner", "left", "right", or "outer". Defaults to "inner".
---@return LDataFrame A new DataFrame with combined columns from both frames.
function LDataFrame:join(other, this_col, other_col, jtype) end

--- Creates a lazy query builder for this DataFrame. Chain filter, sort, head, tail, select, etc.
---@return LLazyQuery A lazy query object for chained operations.
function LDataFrame:lazy() end

--- Returns the maximum numeric value in the specified column.
---@param col string|number Column name or 1-based index.
---@return number The largest numeric value found.
function LDataFrame:max(col) end

--- Computes the arithmetic mean (average) of all numeric values in the specified column.
---@param col string|number Column name or 1-based index.
---@return number The mean value. Returns NaN if the column has no numeric values.
function LDataFrame:mean(col) end

--- Returns the median (middle value) of all numeric values in the specified column.
---@param col string|number Column name or 1-based index.
---@return number The median value.
function LDataFrame:median(col) end

--- Appends all rows from another DataFrame into this one. Both frames must have the same columns.
---@param other LDataFrame The DataFrame whose rows will be appended.
function LDataFrame:merge(other) end

--- Returns the minimum numeric value in the specified column.
---@param col string|number Column name or 1-based index.
---@return number The smallest numeric value found.
function LDataFrame:min(col) end

--- Returns the most frequently occurring value in the specified column (the statistical mode).
---@param col string|number Column to find the mode of.
---@return LuaValue The most frequent value (number, string, boolean, or nil).
function LDataFrame:modeVal(col) end

--- Returns the number of columns in the DataFrame.
---@return number The total column count.
function LDataFrame:ncols() end

--- Adds a new column with values normalized (min-max scaled) to a target range [out_min, out_max].
---@param col string|number Source numeric column.
---@param out_min number The minimum of the output range.
---@param out_max number The maximum of the output range.
---@param name string Name for the new normalized column.
function LDataFrame:normalizeCol(col, out_min, out_max, name) end

--- Returns the number of rows in the DataFrame.
---@return number The total row count (0 for an empty frame).
function LDataFrame:nrows() end

--- Returns a new DataFrame containing only the rows where the column value is an outlier.
---@param col string|number Column to check for outliers.
---@param threshold? number Number of standard deviations for the outlier boundary. Defaults to 2.0.
---@return LDataFrame A new DataFrame with only the outlier rows.
function LDataFrame:outliers(col, threshold) end

--- Pivots the DataFrame by creating a cross-tabulation: rows become unique values from row_col,
---@param row_col string|number Column whose unique values become row labels.
---@param col_col string|number Column whose unique values become new column headers.
---@param val_col string|number Column whose values fill the pivot cells.
---@return LDataFrame A new wide-format DataFrame.
function LDataFrame:pivot(row_col, col_col, val_col) end

--- Creates a pivot table with aggregation. Groups data by row_key, spreads col_key values into columns,
---@param row_key string|number Column whose unique values become row labels.
---@param col_key string|number Column whose unique values become new column headers.
---@param value_key string|number Column whose values are aggregated into cells.
---@param agg? string Aggregation function: "sum", "mean", "min", "max", "count". Defaults to "mean".
---@return LDataFrame A new pivot DataFrame.
function LDataFrame:pivotTable(row_key, col_key, value_key, agg) end

--- Executes a SQL-like query string against this DataFrame and returns the result.
---@param sql_str string The SQL query, e.g. "SELECT name, score WHERE score > 10 ORDER BY score DESC".
---@return LDataFrame A new DataFrame with the query results.
function LDataFrame:query(sql_str) end

--- Returns a new DataFrame with an added column containing the ordinal rank for a given column.
---@param col string|number Column to rank by.
---@param order? string "asc" or "desc". Defaults to "asc".
---@param result_col? string Name for the rank column. Defaults to "rank".
---@return LDataFrame A new DataFrame with the rank column added.
function LDataFrame:rank(col, order, result_col) end

--- Removes a column from the DataFrame by name or 1-based index. All data in that column is discarded.
---@param col string|number Column name or 1-based index to remove.
---@return nil Errors if the column does not exist.
function LDataFrame:removeColumn(col) end

--- Removes a row by its 1-based index. All subsequent rows shift down by one.
---@param row number The 1-based row index to remove.
---@return nil Errors if the index is out of bounds.
function LDataFrame:removeRow(row) end

--- Renames an existing column. References by name or 1-based index. Useful for schema migration or display.
---@param col string|number The column to rename (name or 1-based index).
---@param new_name string The new name for the column.
---@return nil Errors if the column does not exist or the new name is already taken.
function LDataFrame:rename(col, new_name) end

--- Returns a new DataFrame with an added column containing the rolling mean over a sliding window.
---@param col string|number Source numeric column.
---@param window number Window size for the rolling computation.
---@param result_col? string Name for the output column. Defaults to "rolling_mean".
---@return LDataFrame A new DataFrame with the rolling mean column added.
function LDataFrame:rollingMean(col, window, result_col) end

--- Returns a new DataFrame with an added column containing the rolling sum over a sliding window.
---@param col string|number Source numeric column.
---@param window number Window size for the rolling computation.
---@param result_col? string Name for the output column. Defaults to "rolling_sum".
---@return LDataFrame A new DataFrame with the rolling sum column added.
function LDataFrame:rollingSum(col, window, result_col) end

--- Returns a stateful iterator function for use in a for-loop. Yields (rowIndex, rowTable) pairs.
---@return function An iterator function yielding (number, table) pairs.
function LDataFrame:rows() end

--- Returns a new DataFrame with N randomly selected rows. Optionally accepts a seed for reproducibility.
---@param n number Number of rows to sample.
---@param seed? number Optional RNG seed for deterministic results.
---@return LDataFrame A new DataFrame with N randomly chosen rows.
function LDataFrame:sample(n, seed) end

--- Returns a new DataFrame containing only the specified columns. Pass column names or indices as varargs.
---@param ... string|number One or more column names or 1-based indices to keep.
---@return LDataFrame A new DataFrame with only the selected columns.
function LDataFrame:select(...) end

--- Replaces all values in a column with the provided array of numbers.
---@param col string|number Column name or 1-based index to overwrite.
---@param values table Array of numbers matching the DataFrame row count.
function LDataFrame:setColumnFromF64(col, values) end

--- Sets a single cell value at the given row and column. Overwrites any existing value.
---@param row number The 1-based row index.
---@param col string|number Column name or 1-based column index.
---@param val LuaValue The new value to store (number, string, boolean, or nil).
---@return nil Errors if row or column is out of bounds.
function LDataFrame:setValue(row, col, val) end

--- Returns a new DataFrame containing rows from start to end (both inclusive, 1-based).
---@param start number The 1-based starting row index (inclusive).
---@param end_ number The 1-based ending row index (inclusive).
---@return LDataFrame A new DataFrame with the sliced rows.
function LDataFrame:slice(start, end_) end

--- Returns a new DataFrame with rows sorted by the given column. Does not modify the original.
---@param col string|number Column to sort by.
---@param ascending? boolean Sort direction. True (default) for ascending, false for descending.
---@return LDataFrame A new sorted DataFrame.
function LDataFrame:sort(col, ascending) end

--- Returns the standard deviation of numeric values in the specified column.
---@param col string|number Column name or 1-based index.
---@return number The population standard deviation.
function LDataFrame:stddev(col) end

--- Computes the sum of all numeric values in the specified column. Non-numeric cells are ignored.
---@param col string|number Column name or 1-based index.
---@return number The sum of numeric values in the column.
function LDataFrame:sum(col) end

--- Returns a new DataFrame containing only the last N rows. Defaults to 5 if not specified.
---@param n? number Number of rows to take from the bottom. Defaults to 5.
---@return LDataFrame A new DataFrame with at most N rows from the end.
function LDataFrame:tail(n) end

--- Serializes the DataFrame to a compact binary format. Much smaller than CSV or JSON.
---@return string A binary-encoded string (use fromBinary to decode).
function LDataFrame:toBinary() end

--- Serializes the DataFrame to a CSV-formatted string. First row is the header.
---@return string The full CSV text with header row and data rows.
function LDataFrame:toCSV() end

--- Serializes the DataFrame to a JSON string (array of objects). Each row becomes a JSON object.
---@return string A JSON array string like [{"col":val}, ...].
function LDataFrame:toJSON() end

--- Returns a human-readable formatted table string representation of the DataFrame.
---@return string A formatted multi-line text table with headers and aligned columns.
function LDataFrame:toString() end

--- Converts the entire DataFrame to a Lua table of row-tables.
---@return table Array of {colName = value, ...} tables, one per row.
function LDataFrame:toTable() end

--- Returns the type name string for this object.
---@return string Always returns "LDataFrame".
function LDataFrame:type() end

--- Checks whether this object matches a given type name. Supports "LDataFrame", "DataFrame", and "Object".
---@param name string The type name to check against.
---@return boolean True if the name matches this object's type hierarchy.
function LDataFrame:typeOf(name) end

--- Returns a table of distinct values found in the specified column. Duplicates are removed.
---@param col string|number Column name or 1-based index.
---@return table Array of unique cell values from that column.
function LDataFrame:unique(col) end

--- Returns the variance of numeric values in the specified column. Variance is the square of standard deviation.
---@param col string|number Column name or 1-based index.
---@return number The population variance.
function LDataFrame:variance(col) end

--- Adds a new column with the cumulative sum of a numeric column (running total).
---@param col string|number Source numeric column.
---@param name string Name for the new cumulative sum column.
function LDataFrame:withCumsum(col, name) end

--- Evaluates a column expression and adds the result as a new column. The expression can reference
---@param col_name string Name for the new computed column.
---@param expr string Expression string referencing existing column names.
---@return LDataFrame A new DataFrame with the computed column added.
function LDataFrame:withEval(col_name, expr) end

--- Adds a new column with the percent change between consecutive rows in a numeric column.
---@param col string|number Source numeric column.
---@param name string Name for the new percent-change column.
function LDataFrame:withPctChange(col, name) end

--- Adds a new column with the ordinal rank of each row based on a source column.
---@param col string|number Source column to rank by.
---@param asc? boolean Rank direction. True (default) = lowest value gets rank 1.
---@param name string Name for the new rank column.
function LDataFrame:withRank(col, asc, name) end

--- Adds a new column containing the rolling maximum of a source column over a sliding window.
---@param col string|number Source column.
---@param window number The window size.
---@param name string Name for the new output column.
function LDataFrame:withRollingMax(col, window, name) end

--- Adds a new column containing the rolling average of a source column over a sliding window.
---@param col string|number Source column to compute rolling mean from.
---@param window number The window size (number of consecutive rows to average).
---@param name string Name for the new output column.
function LDataFrame:withRollingMean(col, window, name) end

--- Adds a new column containing the rolling minimum of a source column over a sliding window.
---@param col string|number Source column.
---@param window number The window size.
---@param name string Name for the new output column.
function LDataFrame:withRollingMin(col, window, name) end

--- Adds a new column containing the rolling sum of a source column over a sliding window.
---@param col string|number Source column for the rolling sum.
---@param window number The window size.
---@param name string Name for the new output column.
function LDataFrame:withRollingSum(col, window, name) end

--- Adds a new column containing the z-score (standard score) of each value in the source column.
---@param col string|number Source numeric column.
---@param name string Name for the new z-score column.
function LDataFrame:zscoreCol(col, name) end

---@class LDatabase
LDatabase = {}

---@param name LuaValue
---@param df_ud LuaValue
function LDatabase:addTable(name, df_ud) end

function LDatabase:clear() end

---@param name LuaValue
function LDatabase:getTable(name) end

---@param name LuaValue
function LDatabase:hasTable(name) end

function LDatabase:listTables() end

---@param other LuaValue
function LDatabase:merge(other) end

---@param sql_str LuaValue
function LDatabase:query(sql_str) end

---@param name LuaValue
function LDatabase:removeTable(name) end

function LDatabase:tableCount() end

function LDatabase:toJSON() end

function LDatabase:type() end

---@param name LuaValue
function LDatabase:typeOf(name) end

--- A grouped DataFrame resulting from a `groupByObj` operation. Contains sub-frames keyed by distinct group values,
---@class LGroupedFrame
LGroupedFrame = {}

--- Applies a custom aggregation function to each group and returns a new DataFrame with one row per group.
---@param col_name string The column name whose values are passed to the aggregation function.
---@param func function A Lua function(values: table) -> number that reduces the group's column values to a single result.
---@return LDataFrame A new DataFrame with columns "group_key" and the aggregated column.
function LGroupedFrame:aggregate(col_name, func) end

--- Returns the type name string for this object.
---@return string Always returns "LGroupedFrame".
function LGroupedFrame:type() end

--- Checks whether this object matches a given type name. Supports "LGroupedFrame" and "Object".
---@param name string The type name to check against.
---@return boolean True if the name matches this object's type hierarchy.
function LGroupedFrame:typeOf(name) end

--- A deferred query builder that chains DataFrame operations without executing them until :collect() is called.
---@class LLazyQuery
LLazyQuery = {}

function LLazyQuery:collect() end

---@param col LuaValue
function LLazyQuery:dropNil(col) end

---@param col LuaValue
---@param op LuaValue
---@param val LuaValue
function LLazyQuery:filter(col, op, val) end

---@param n LuaValue
function LLazyQuery:head(n) end

---@param n LuaValue
function LLazyQuery:limit(n) end

---@param cols LuaValue
function LLazyQuery:select(cols) end

---@param start LuaValue
---@param end_ LuaValue
function LLazyQuery:slice(start, end_) end

---@param col LuaValue
---@param ascending? LuaValue
function LLazyQuery:sort(col, ascending) end

---@param n LuaValue
function LLazyQuery:tail(n) end

function LLazyQuery:type() end

---@param name LuaValue
function LLazyQuery:typeOf(name) end

---@class LVecFrame
LVecFrame = {}

---@param mask_tbl LuaValue
function LVecFrame:applyMask(mask_tbl) end

---@param col LuaValue
function LVecFrame:colAbs(col) end

---@param col LuaValue
---@param val LuaValue
function LVecFrame:colAdd(col, val) end

---@param col LuaValue
---@param dtype LuaValue
function LVecFrame:colCast(col, dtype) end

---@param col LuaValue
function LVecFrame:colCeil(col) end

---@param col LuaValue
---@param min_val LuaValue
---@param max_val LuaValue
function LVecFrame:colClamp(col, min_val, max_val) end

---@param col LuaValue
---@param val LuaValue
function LVecFrame:colDiv(col, val) end

---@param col LuaValue
function LVecFrame:colFloor(col) end

---@param col LuaValue
---@param val LuaValue
function LVecFrame:colMul(col, val) end

---@param col LuaValue
function LVecFrame:colNeg(col) end

---@param out_col LuaValue
---@param left_col LuaValue
---@param op LuaValue
---@param right_col LuaValue
function LVecFrame:colOp(out_col, left_col, op, right_col) end

---@param col LuaValue
function LVecFrame:colSqrt(col) end

---@param col LuaValue
---@param val LuaValue
function LVecFrame:colSub(col, val) end

---@param col LuaValue
function LVecFrame:colType(col) end

function LVecFrame:columns() end

---@param col LuaValue
---@param cmp_op LuaValue
---@param val LuaValue
function LVecFrame:filterMask(col, cmp_op, val) end

function LVecFrame:ncols() end

function LVecFrame:nrows() end

---@param cols_tbl LuaValue
---@param op LuaValue
function LVecFrame:parReduce(cols_tbl, op) end

---@param cols_tbl LuaValue
---@param op LuaValue
---@param val LuaValue
function LVecFrame:parScalarOp(cols_tbl, op, val) end

---@param col LuaValue
---@param op LuaValue
function LVecFrame:reduce(col, op) end

function LVecFrame:toDataFrame() end

function LVecFrame:type() end

---@param name LuaValue
function LVecFrame:typeOf(name) end

---@param s LuaValue
lurek.dataframe.fromBinary = function(s) end

---@param s LuaValue
lurek.dataframe.fromCSV = function(s) end

---@param s LuaValue
lurek.dataframe.fromJSON = function(s) end

---@param columns_tbl LuaValue
---@param rows_tbl LuaValue
lurek.dataframe.fromRows = function(columns_tbl, rows_tbl) end

---@param rows LuaValue
lurek.dataframe.fromTable = function(rows) end

---@param vf LuaValue
lurek.dataframe.fromVec = function(vf) end

lurek.dataframe.newDataFrame = function() end

lurek.dataframe.newDatabase = function() end

---@param defs_tbl LuaValue
---@param n LuaValue
---@param seed? LuaValue
lurek.dataframe.random = function(defs_tbl, n, seed) end

---@param df LuaValue
lurek.dataframe.toVec = function(df) end

---@class lurek.debugbridge
lurek.debugbridge = {}

--- Sends a named event with JSON payload to all connected debug clients.
---@param event string Event name identifier.
---@param json_data string JSON-encoded payload string.
---@return nil No return value.
lurek.debugbridge.broadcast = function(event, json_data) end

--- Records a print message into the debug bridge history and broadcasts it to connected clients.
---@param msg string The message text to capture.
---@param source? string Source file path or identifier (defaults to "?").
---@param line? number Line number where the print originated (defaults to 0).
---@return nil No return value.
lurek.debugbridge.capturePrint = function(msg, source, line) end

--- Clears all stored print history entries from the debug bridge buffer.
---@return nil No return value.
lurek.debugbridge.clearPrintHistory = function() end

--- Checks and clears the hot-reload flag set by an external client. Returns `true` once when
---@return boolean `true` if a hot-reload was requested since the last call.
lurek.debugbridge.consumeHotReloadRequest = function() end

--- Returns the number of external tool clients currently connected to the debug bridge.
---@return number Count of active TCP connections.
lurek.debugbridge.getClientCount = function() end

--- Returns a table of current performance metrics (FPS, frame time, etc.) collected by the bridge.
---@return table Key-value pairs of performance metric names to numeric values.
lurek.debugbridge.getPerformance = function() end

--- Returns the TCP port the debug bridge server is listening on, or 0 if not started.
---@return number The active port number, or 0 when the server is inactive.
lurek.debugbridge.getPort = function() end

--- Returns an array of captured print entries. Each entry has `timestamp`, `message`, `source`, and `line` fields.
---@param count? number Maximum number of most recent entries to return. Nil or 0 returns all.
---@return table Array of `{timestamp, message, source, line}` tables.
lurek.debugbridge.getPrintHistory = function(count) end

--- Returns protocol metadata for the debug bridge handshake. Contains version, capabilities list,
---@return table `{version: number, capabilities: table, nonce: string}`.
lurek.debugbridge.getProtocolInfo = function() end

--- Returns whether the debug bridge server is currently active and accepting connections.
---@return boolean `true` if the server is running, `false` otherwise.
lurek.debugbridge.isRunning = function() end

--- Returns whether an external client has requested a screenshot capture.
---@return boolean `true` if a screenshot is pending, `false` otherwise.
lurek.debugbridge.isScreenshotRequested = function() end

--- Processes pending debug requests from connected clients. Call once per frame in your game loop.
---@return nil No return value.
lurek.debugbridge.poll = function() end

--- Flags a screenshot request for the next rendered frame. The renderer will capture
---@param scale? number Integer scale factor for the capture (1-8, default 1).
---@return nil No return value.
lurek.debugbridge.requestScreenshot = function(scale) end

--- Sets the maximum number of print entries kept in the history ring buffer.
---@param max number Maximum number of entries to retain.
---@return nil No return value.
lurek.debugbridge.setMaxPrintHistory = function(max) end

--- Starts the debug bridge TCP server on the specified port. Only one server can run at a time.
---@param port? number TCP port to listen on (default 19740, must be >= 1024).
---@return boolean `true` if the server started successfully, `false` if already running.
lurek.debugbridge.start = function(port) end

--- Stops the debug bridge server and disconnects all clients. Blocks until the server thread exits.
---@return nil No return value.
lurek.debugbridge.stop = function() end

---@class lurek.devtools
lurek.devtools = {}

--- Lua-exposed file watcher userdata that monitors a single path for changes.
---@class LFileWatcher
LFileWatcher = {}

--- Stops watching the file and removes the registered callback. The watcher becomes inert after this call.
function LFileWatcher:cancel() end

--- Polls the filesystem for changes. If changes are detected and a callback is registered, the callback is invoked.
---@return boolean True if the watched file changed since the last check.
function LFileWatcher:check() end

--- Returns the filesystem path being watched by this watcher instance.
---@return string The absolute or relative path originally passed to `newFileWatcher`.
function LFileWatcher:getPath() end

--- Registers a callback function invoked whenever the watched file changes on disk.
---@param callback function A zero-argument function called on each detected change.
function LFileWatcher:onChanged(callback) end

--- Returns the type name of this userdata object.
---@return string Always `"LFileWatcher"`.
function LFileWatcher:type() end

--- Checks whether this object matches the given type name. Supports `"LFileWatcher"` and `"Object"`.
---@param name string The type name to test against.
---@return boolean True if the object matches the given type name.
function LFileWatcher:typeOf(name) end

---@class LReplConsole
LReplConsole = {}

function LReplConsole:clear() end

---@param code LuaValue
function LReplConsole:eval(code) end

function LReplConsole:history() end

function LReplConsole:len() end

function LReplConsole:type() end

---@param name LuaValue
function LReplConsole:typeOf(name) end

--- Clears all entries from the in-memory log history buffer.
lurek.devtools.clearLog = function() end

--- Removes all watched paths, stopping all file monitoring.
lurek.devtools.clearWatches = function() end

--- Logs a message at `debug` level. Used for development-time diagnostic output not shown in production.
---@param message string The debug message text.
lurek.devtools.debug = function(message) end

--- Logs a message at `error` level. Signals a runtime error that may affect game behavior.
---@param message string The error message text.
lurek.devtools.error = function(message) end

--- Evaluates a Lua code string at runtime and returns the results. Returns `true, ...results` on success or `false, errorMessage` on failure.
---@param code string The Lua source code to evaluate.
---@return boolean a First value is success flag; subsequent values are results or the error string.
---@return ... b First value is success flag; subsequent values are results or the error string.
lurek.devtools.eval = function(code) end

--- Registers a named watch variable whose value is sampled via a getter function. Useful for live dashboards and overlays.
---@param name string Display name for the watch variable.
---@param getter function Zero-argument function that returns the current value to display.
---@param category? string Optional category for grouping watches in the inspector.
---@return number A unique watch ID that can be passed to `removeWatch`.
lurek.devtools.exposeWatch = function(name, getter, category) end

--- Logs a message at `fatal` level. Highest severity — indicates an unrecoverable failure.
---@param message string The fatal message text.
lurek.devtools.fatal = function(message) end

--- Captures the current Lua call stack as an array of frame tables. Useful for runtime introspection and error reporting.
---@param maxDepth? number Maximum number of stack frames to capture (default 20, max 100).
---@return table Array of frame tables, each with `source`, `line`, `name`, and `what` fields.
lurek.devtools.getCallStack = function(maxDepth) end

--- Returns the raw array of recent frame time samples stored in the history ring buffer.
---@return table Array of frame time values in seconds, oldest first.
lurek.devtools.getFrameHistory = function() end

--- Returns the current capacity of the frame time history ring buffer.
---@return number The maximum number of stored frame time samples.
lurek.devtools.getFrameHistorySize = function() end

--- Returns a snapshot of CPU frame timing statistics including FPS, percentiles, and min/max.
---@return table Table with fields: `fps`, `dt`, `avg`, `min`, `max`, `p50`, `p95`, `p99`, `samples`.
lurek.devtools.getFrameStats = function() end

--- Returns a snapshot of GPU frame timing statistics, mirroring the CPU stats format.
---@return table Table with fields: `fps`, `dt`, `avg`, `min`, `max`, `p50`, `p95`, `p99`, `samples`.
lurek.devtools.getGpuFrameStats = function() end

--- Returns whether log messages are currently being printed to the system console.
---@return boolean True if console logging is enabled.
lurek.devtools.getLogConsole = function() end

--- Returns the currently configured log file path, or an empty string if file logging is disabled.
---@return string The active log file path.
lurek.devtools.getLogFile = function() end

--- Retrieves the most recent log entries from the in-memory history buffer.
---@param count? number Maximum number of entries to return. Omit for all entries.
---@return table Array of tables with fields: `level`, `timestamp`, `message`, `source`, `line`, and optional `category`.
lurek.devtools.getLogHistory = function(count) end

--- Returns the current minimum log severity threshold as a string.
---@return string The active log level name (e.g. `"info"`).
lurek.devtools.getLogLevel = function() end

--- Retrieves the profiling zone tree for a specific frame. Each zone has `name`, `time`, `selfTime`, `startTime`, and `children`.
---@param frame? number Frame index (0 = most recent). Defaults to 0.
---@return table Array of top-level profile zone tables for the requested frame.
lurek.devtools.getProfileData = function(frame) end

--- Returns the number of completed profiling frames stored in the buffer.
---@return number The frame count.
lurek.devtools.getProfileFrameCount = function() end

--- Returns the polling interval (in seconds) used when scanning for file changes.
---@return number The interval in seconds.
lurek.devtools.getWatchInterval = function() end

--- Returns a sorted array of all file paths currently being watched.
---@return table Array of path strings.
lurek.devtools.getWatchedPaths = function() end

--- Evaluates all registered watch getters and returns their current values as an array of tables.
---@return table Array of tables with fields: `name`, `category`, `value`.
lurek.devtools.getWatches = function() end

--- Logs a message at `info` level. General-purpose informational output for significant events.
---@param message string The info message text.
lurek.devtools.info = function(message) end

--- Returns whether the developer REPL console overlay is currently open.
---@return boolean True if the console is open.
lurek.devtools.isConsoleOpen = function() end

--- Returns whether the entity inspector overlay is currently open.
---@return boolean True if the entity inspector is open.
lurek.devtools.isEntityInspectorOpen = function() end

--- Returns whether the frame profiler is currently active.
---@return boolean True if profiling is enabled.
lurek.devtools.isProfilingEnabled = function() end

--- Logs a message at the specified severity level. Use for structured diagnostic output.
---@param level string Severity: `"trace"`, `"debug"`, `"info"`, `"warn"`, `"error"`, or `"fatal"`.
---@param message string The log message text.
lurek.devtools.log = function(level, message) end

---@param path LuaValue
lurek.devtools.newFileWatcher = function(path) end

---@param max_history? LuaValue
lurek.devtools.newRepl = function(max_history) end

--- Opens the developer REPL console overlay. Returns true to confirm the console was opened.
---@return boolean Always true.
lurek.devtools.openConsole = function() end

--- Opens the entity inspector overlay for examining live game object state.
---@return boolean Always true.
lurek.devtools.openEntityInspector = function() end

--- Ends the current profiling frame and begins a new one. Call once per game loop iteration.
lurek.devtools.profileFrame = function() end

--- Ends the most recently pushed profiling zone, recording its elapsed time.
---@param name? string Optional zone name for validation (unused, kept for symmetry).
lurek.devtools.profilePop = function(name) end

--- Begins a named profiling zone. Must be paired with a corresponding `profilePop` call.
---@param name string The zone label (e.g. `"physics"`, `"render"`).
lurek.devtools.profilePush = function(name) end

lurek.devtools.profilerReport = function() end

--- Records a CPU frame time sample for the frame statistics tracker.
---@param dt number The frame delta time in seconds (e.g. 0.016 for 60 FPS).
lurek.devtools.recordFrameTime = function(dt) end

--- Records a GPU frame time sample for the GPU statistics tracker.
---@param dt number The GPU frame delta time in seconds.
lurek.devtools.recordGpuFrameTime = function(dt) end

--- Removes a previously registered watch variable by its ID.
---@param id number The watch ID returned by `exposeWatch`.
---@return boolean True if the watch was found and removed, false otherwise.
lurek.devtools.removeWatch = function(id) end

--- Clears all stored profiling frames and resets the profiler state.
lurek.devtools.resetProfile = function() end

--- Polls all watched paths and returns an array of paths that have changed since the last scan.
---@return table Array of changed file path strings (empty if nothing changed).
lurek.devtools.scan = function() end

--- Sets the maximum number of frame time samples retained in the history ring buffer.
---@param size number The new capacity (number of samples to keep).
lurek.devtools.setFrameHistorySize = function(size) end

--- Enables or disables printing log messages to the system console (stdout).
---@param enabled boolean True to enable console output, false to suppress.
lurek.devtools.setLogConsole = function(enabled) end

--- Sets the file path for log output. Messages are appended to this file in addition to the console.
---@param path string The file path to write logs to. Use an empty string to disable file logging.
lurek.devtools.setLogFile = function(path) end

--- Sets the minimum log severity threshold. Messages below this level are discarded.
---@param level string One of `"trace"`, `"debug"`, `"info"`, `"warn"`, `"error"`, `"fatal"`.
lurek.devtools.setLogLevel = function(level) end

--- Enables or disables the frame profiler. When disabled, `profilePush`/`profilePop` calls are no-ops.
---@param enabled boolean True to enable profiling, false to disable.
lurek.devtools.setProfilingEnabled = function(enabled) end

--- Sets the minimum polling interval for file change detection. Clamped to at least 0.01 seconds.
---@param interval number The desired interval in seconds.
lurek.devtools.setWatchInterval = function(interval) end

--- Captures a combined devtools snapshot including frame stats, watch values, recent profile data, and log tail. Ideal for debug overlays.
---@return table Table with fields: `frameStats`, `watches`, `profile`, `log`, `watchCount`.
lurek.devtools.snapshot = function() end

--- Logs a message at `trace` level. Lowest priority, typically used for fine-grained execution tracing.
---@param message string The trace message text.
lurek.devtools.trace = function(message) end

--- Stops watching a previously registered file path.
---@param path string The path to stop monitoring.
---@return boolean True if the path was found and removed, false otherwise.
lurek.devtools.unwatch = function(path) end

--- Logs a message at `warn` level. Indicates a potential problem that does not halt execution.
---@param message string The warning message text.
lurek.devtools.warn = function(message) end

--- Begins watching a file path for changes. Duplicate paths are ignored.
---@param path string The file or directory path to monitor for modifications.
---@return boolean True if the path was added, false if it was already being watched.
lurek.devtools.watch = function(path) end

---@class lurek.docs
lurek.docs = {}

--- Scans the entire live `lurek` table and returns an ApiCatalog of all discovered functions and sub-tables.
---@class LApiCatalog
LApiCatalog = {}

--- Returns the number of entries in the catalog, optionally filtered to a module.
---@param module? string If provided, counts only entries in this module.
---@return number Total entry count.
function LApiCatalog:entryCount(module) end

--- Returns a new catalog containing only entries for which the predicate function returns true.
---@param predicate function A function receiving an LDocEntry and returning a boolean.
---@return LApiCatalog Filtered catalog.
function LApiCatalog:filter(predicate) end

--- Returns all doc entries, optionally filtered to a single module.
---@param module? string If provided, only entries from this module are returned.
---@return table Sequence of LDocEntry userdata objects.
function LApiCatalog:getEntries(module) end

--- Looks up a single entry by its fully-qualified name (e.g. `"lurek.graphics.draw"`).
---@param qualified_name string The dot-separated qualified name to find.
---@return LDocEntry? The matching entry, or nil if not found.
function LApiCatalog:getEntry(qualified_name) end

--- Returns a sorted array of all unique module names present in this catalog.
---@return table Sequence of module-name strings.
function LApiCatalog:getModules() end

--- Returns all method entries that belong to a given type (matched by qualified-name prefix).
---@param qualified_name string Qualified type name (e.g. `"lurek.physics.Body"`).
---@return table Sequence of LDocEntry objects representing the type's methods.
function LApiCatalog:getTypeMethods(qualified_name) end

--- Returns the names of all entries with kind `"type"` in a given module.
---@param module_name string Module to search for type entries.
---@return table Sequence of type-name strings.
function LApiCatalog:getTypes(module_name) end

--- Merges another ApiCatalog into this one, returning a new combined catalog. Existing entries with the same qualified name are replaced.
---@param other LApiCatalog The catalog to merge in.
---@return LApiCatalog A new catalog containing entries from both sources.
function LApiCatalog:merge(other) end

--- Performs a case-insensitive text search across entry names, qualified names, and descriptions.
---@param query string The search term to match.
---@return table Sequence of matching LDocEntry objects.
function LApiCatalog:search(query) end

--- Serializes the entire catalog to a pretty-printed JSON string.
---@return string JSON array of entry objects with name, qualifiedName, module, kind, description, score, parameters, and returns.
function LApiCatalog:toJSON() end

--- Converts the entire catalog to a plain Lua table of summary records.
---@return table Sequence of plain tables.
function LApiCatalog:toTable() end

--- Returns the type tag string for this object: `"LApiCatalog"`.
---@return string Always `"LApiCatalog"`.
function LApiCatalog:type() end

--- Checks whether this object matches a given type name. Supports `"LApiCatalog"` and `"Object"`.
---@param name string Type name to test against.
---@return boolean True if the object is of the specified type.
function LApiCatalog:typeOf(name) end

---@class LDocEntry
LDocEntry = {}

--- Returns the deprecation notice if this entry is deprecated, or nil.
---@return string? Deprecation message, or nil.
function LDocEntry:getDeprecated() end

--- Returns the human-readable description text for this entry.
---@return string Description (may be empty if undocumented).
function LDocEntry:getDescription() end

--- Returns the example code snippet for this entry, or nil if none exists.
---@return string? Example Lua code, or nil.
function LDocEntry:getExample() end

--- Returns the kind of this entry: `"function"`, `"method"`, `"type"`, or `"value"`.
---@return string Entry kind tag.
function LDocEntry:getKind() end

--- Returns the module this entry belongs to (e.g. `"graphics"`).
---@return string Module name.
function LDocEntry:getModule() end

--- Returns the short name of this API entry (e.g. `"draw"`).
---@return string The unqualified function or type name.
function LDocEntry:getName() end

--- Returns an array of parameter info tables for this entry.
---@return table Sequence of parameter-info tables.
function LDocEntry:getParameters() end

--- Returns the fully-qualified name including the module path (e.g. `"lurek.graphics.draw"`).
---@return string The dot-separated qualified name.
function LDocEntry:getQualifiedName() end

--- Returns an array of return-type info tables for this entry.
---@return table Sequence of return-info tables.
function LDocEntry:getReturns() end

--- Returns the documentation quality score for this entry (0.0 to 1.0).
---@return number Quality score between 0.0 and 1.0.
function LDocEntry:getScore() end

--- Returns the engine version string when this entry was introduced, or nil.
---@return string? Version string like `"0.5.0"`, or nil.
function LDocEntry:getSince() end

--- Returns true if this entry has a non-empty description.
---@return boolean Whether a description exists.
function LDocEntry:hasDescription() end

--- Returns true if this entry has an example code snippet.
---@return boolean Whether an example exists.
function LDocEntry:hasExample() end

--- Returns true if this entry has at least one documented parameter.
---@return boolean Whether parameters are documented.
function LDocEntry:hasParameters() end

--- Returns true if this entry has at least one documented return type.
---@return boolean Whether return types are documented.
function LDocEntry:hasReturnType() end

--- Returns the type tag string for this object: `"LDocEntry"`.
---@return string Always `"LDocEntry"`.
function LDocEntry:type() end

--- Checks whether this object matches a given type name. Supports `"LDocEntry"` and `"Object"`.
---@param name string Type name to test against.
---@return boolean True if the object is of the specified type.
function LDocEntry:typeOf(name) end

---@class LQualityReport
LQualityReport = {}

--- Returns the N entries with the highest documentation quality scores, sorted best-first.
---@param count? number Number of entries to return (default 10).
---@return table Sequence of LDocEntry objects ranked by descending score.
function LQualityReport:getBest(count) end

--- Returns all entries matching a specific letter grade (A, B, C, D, or F).
---@param grade string The letter grade to filter by.
---@return table Sequence of LDocEntry objects with the requested grade.
function LQualityReport:getByGrade(grade) end

--- Returns a letter grade (A, B, C, D, F) corresponding to the overall quality score.
---@return string Grade string.
function LQualityReport:getGrade() end

--- Returns a table mapping each module name to its quality score (0.0 to 1.0).
---@return table Map of module-name → score.
function LQualityReport:getModuleScores() end

--- Returns the overall documentation quality score across all entries (0.0 to 1.0).
---@return number Aggregate quality score.
function LQualityReport:getOverallScore() end

--- Returns a multi-line summary string with overall grade and per-module percentage scores.
---@return string Human-readable quality summary.
function LQualityReport:getSummary() end

--- Returns the N entries with the lowest documentation quality scores, sorted worst-first.
---@param count? number Number of entries to return (default 10).
---@return table Sequence of LDocEntry objects ranked by ascending score.
function LQualityReport:getWorst(count) end

--- Serializes the quality report to a pretty-printed JSON string.
---@return string JSON object with `overallScore`, `grade`, and `moduleScores`.
function LQualityReport:toJSON() end

--- Converts the quality report to a plain table with `overallScore`, `grade`, and `moduleScores`.
---@return table Plain Lua table.
function LQualityReport:toTable() end

--- Returns the type tag string for this object: `"LQualityReport"`.
---@return string Always `"LQualityReport"`.
function LQualityReport:type() end

--- Checks whether this object matches a given type name. Supports `"LQualityReport"` and `"Object"`.
---@param name string Type name to test against.
---@return boolean True if the object is of the specified type.
function LQualityReport:typeOf(name) end

--- Lua-facing wrapper around a `docs::Schema`, enabling data validation from Lua scripts.
---@class LSchema
LSchema = {}

--- Validates a data table and throws a Lua error if validation fails. Use as a guard at function entry points.
---@param data table Key-value table to validate against the schema.
---@return nil Returns nothing on success; raises an error string on failure.
function LSchema:assert(data) end

--- Validates a data table and returns only a boolean (no error details). Use for quick pass/fail checks.
---@param data table Key-value table to validate against the schema.
---@return boolean True if the data passes all schema rules.
function LSchema:check(data) end

--- Returns a sorted array of all field names declared in this schema.
---@return table Sequence of field-name strings.
function LSchema:getFields() end

--- Returns the human-readable name assigned to this schema when it was created.
---@return string The schema name.
function LSchema:getName() end

--- Returns the type tag string for this object: `"LSchema"`.
---@return string Always `"LSchema"`.
function LSchema:type() end

--- Checks whether this object matches a given type name. Supports `"LSchema"` and `"Object"`.
---@param name string Type name to test against.
---@return boolean True if the object is of the specified type.
function LSchema:typeOf(name) end

--- Validates a data table against this schema. Returns a boolean indicating success and a table of error objects.
---@param data table Key-value table whose fields are checked against the schema rules.
---@return boolean a True if all fields pass validation.
---@return table b Array of `{field, message}` tables describing each validation failure.
function LSchema:validate(data) end

---@class LValidationReport
LValidationReport = {}

--- Returns qualified names of entries that exist but lack a description, parameters, or return info.
---@return table Sequence of qualified-name strings for incomplete entries.
function LValidationReport:getIncomplete() end

--- Returns qualified names of live API functions that have no matching documentation entry.
---@return table Sequence of qualified-name strings.
function LValidationReport:getMissing() end

--- Returns qualified names of documented entries that have no matching live API function (stale docs).
---@return table Sequence of qualified-name strings.
function LValidationReport:getPhantom() end

--- Returns a one-line summary string showing counts of missing, phantom, and incomplete entries.
---@return string Human-readable summary like `"Missing: 3, Phantom: 1, Incomplete: 5"`.
function LValidationReport:getSummary() end

--- Returns the number of entries with incomplete documentation.
---@return number Count of incomplete entries.
function LValidationReport:incompleteCount() end

--- Returns true if the validation found no missing entries (docs cover all live API functions).
---@return boolean True when the `missing` list is empty.
function LValidationReport:isValid() end

--- Returns the number of undocumented live API functions.
---@return number Count of missing entries.
function LValidationReport:missingCount() end

--- Returns the number of phantom (stale) documentation entries.
---@return number Count of phantom entries.
function LValidationReport:phantomCount() end

--- Serializes the validation report to a pretty-printed JSON string.
---@return string JSON object with `missing`, `phantom`, `incomplete` arrays and an `isValid` boolean.
function LValidationReport:toJSON() end

--- Converts the validation report to a plain Lua table with `missing`, `phantom`, and `incomplete` arrays.
---@return table Table with three keyed arrays of qualified-name strings.
function LValidationReport:toTable() end

--- Returns the type tag string for this object: `"LValidationReport"`.
---@return string Always `"LValidationReport"`.
function LValidationReport:type() end

--- Checks whether this object matches a given type name. Supports `"LValidationReport"` and `"Object"`.
---@param name string Type name to test against.
---@return boolean True if the object is of the specified type.
function LValidationReport:typeOf(name) end

---@param catalog_ud LuaValue
---@param source_dir LuaValue
lurek.docs.checkStaleness = function(catalog_ud, source_dir) end

---@param catalog_ud? LuaValue
lurek.docs.coverage = function(catalog_ud) end

---@param module_name LuaValue
---@param catalog_ud? LuaValue
lurek.docs.coverageModule = function(module_name, catalog_ud) end

--- Sets or updates the description text for a documented entry by its qualified name.
---@param qualified_name string Dot-separated qualified name (e.g. `"lurek.graphics.draw"`).
---@param description string Human-readable description to assign.
lurek.docs.describe = function(qualified_name, description) end

---@param catalog_ud LuaValue
---@param output_dir LuaValue
lurek.docs.exportAll = function(catalog_ud, output_dir) end

---@param catalog_ud LuaValue
---@param path LuaValue
lurek.docs.exportCheatsheet = function(catalog_ud, path) end

---@param catalog_ud LuaValue
---@param path LuaValue
lurek.docs.exportCompletions = function(catalog_ud, path) end

---@param catalog_ud LuaValue
---@param path LuaValue
lurek.docs.exportHover = function(catalog_ud, path) end

---@param catalog_ud LuaValue
---@param path LuaValue
lurek.docs.exportMarkdown = function(catalog_ud, path) end

---@param catalog_ud LuaValue
---@param path LuaValue
lurek.docs.exportSignatures = function(catalog_ud, path) end

--- Returns the current in-memory catalog built via `describe`/`setParamInfo`/`setReturnInfo` calls.
---@return LApiCatalog The runtime-assembled catalog.
lurek.docs.getCatalog = function() end

--- Loads and merges all `.toml` documentation files from the specified directory into one catalog.
---@param directory string Path to a folder containing TOML documentation files.
---@return LApiCatalog Combined catalog from all TOML files found.
lurek.docs.loadAll = function(directory) end

--- Loads API documentation entries from a TOML file at the given path. The TOML must have an `entries` array.
---@param path string Filesystem path to the TOML documentation file.
---@return LApiCatalog Catalog populated from the file.
lurek.docs.loadToml = function(path) end

---@param catalog_ud? LuaValue
lurek.docs.quality = function(catalog_ud) end

---@param module_name LuaValue
---@param catalog_ud? LuaValue
lurek.docs.qualityModule = function(module_name, catalog_ud) end

---@param ns? LuaValue
lurek.docs.reflectLive = function(ns) end

---@param tbl LuaValue
---@param name? LuaValue
lurek.docs.reflectTable = function(tbl, name) end

--- Clears all entries from the in-memory documentation catalog, resetting it to empty.
lurek.docs.resetCatalog = function() end

--- Scans the entire live `lurek` table and returns an ApiCatalog of all discovered functions and sub-tables.
---@param opts? LuaValue
---@return LApiCatalog Catalog of live API entries found by introspection.
lurek.docs.scan = function(opts) end

--- Scans a single sub-module of `lurek` by name (e.g. `"graphics"`) and returns its entries as an ApiCatalog.
---@param module_name string Name of the lurek sub-module to scan.
---@return LApiCatalog Catalog containing only entries from the specified module.
lurek.docs.scanModule = function(module_name) end

---@param rules LuaValue
---@param name? LuaValue
lurek.docs.schema = function(rules, name) end

---@param toml_text LuaValue
lurek.docs.schemaFromToml = function(toml_text) end

--- Sets parameter metadata for an existing documented entry.
---@param qualified_name string Qualified name of the entry to update.
---@param params table Array of `{name, type, description, optional?, default?}` tables.
lurek.docs.setParamInfo = function(qualified_name, params) end

--- Sets return-type metadata for an existing documented entry.
---@param qualified_name string Qualified name of the entry to update.
---@param returns table Array of `{type, description}` tables.
lurek.docs.setReturnInfo = function(qualified_name, returns) end

---@param catalog_ud? LuaValue
lurek.docs.validate = function(catalog_ud) end

---@param module_name LuaValue
---@param catalog_ud? LuaValue
lurek.docs.validateModule = function(module_name, catalog_ud) end

---@class lurek.ecs
lurek.ecs = {}

--- A Lua-visible ECS universe that owns all entities, components, systems, tags, layers,
---@class LUniverse
LUniverse = {}

--- Creates a named directed relationship from one entity to another.
---@param from number Source entity ID.
---@param name string Relationship name (e.g. "owns", "attacks").
---@param to number Target entity ID.
function LUniverse:addRelation(from, name, to) end

--- Registers a system table with the universe. Systems are Lua tables with an `update`
---@param system table A table with update(self, world, dt) and/or render(self, world).
---@param opts? table Options: {priority=number, phase=string, name=string, after={...}}.
function LUniverse:addSystem(system, opts) end

--- Attaches a string tag to an entity. Tags are lightweight labels without data,
---@param id number The entity ID.
---@param tag string The tag name to add.
function LUniverse:addTag(id, tag) end

--- Restores the universe to a previously captured snapshot state. All current entities
---@param snapshot table A snapshot table previously returned by snapshot().
function LUniverse:applySnapshot(snapshot) end

--- Applies a bitmap-based tag to an entity. Much faster than string tags for bulk queries,
---@param id number The entity ID.
---@param name string A previously defined bitmap tag name.
function LUniverse:bitmapTag(id, name) end

--- Removes a bitmap tag from an entity.
---@param id number The entity ID.
---@param name string A previously defined bitmap tag name.
function LUniverse:bitmapUntag(id, name) end

--- Destroys all entities, components, tags, and systems — resetting the universe.
function LUniverse:clear() end

--- Removes all relationships of a given name from a source entity.
---@param from number Source entity ID.
---@param name string Relationship name to clear entirely.
function LUniverse:clearRelations(from, name) end

--- Registers a named entity blueprint (template). Blueprints define a set of default
---@param name string Unique blueprint name (e.g. "enemy_goblin").
---@param components table Table of {componentName = defaultValue, ...}.
function LUniverse:defineBlueprint(name, components) end

--- Pre-registers a bitmap tag name and assigns it a unique bit index. Must be called
---@param name string The tag name to define.
function LUniverse:defineTag(name) end

--- Restores the universe from a serialized table. Alias for applySnapshot().
---@param snapshot table A state table previously returned by serialize().
function LUniverse:deserialize(snapshot) end

--- Iterates all entities that have a named component, calling a function for each.
---@param name string The component name to iterate over.
---@param callback function Called as callback(id, value) for each matching entity.
function LUniverse:each(name, callback) end

--- Broadcasts a custom event to all systems. Each system that has a method matching
---@param event string The event name to broadcast (matches a method key on systems).
---@param ... LuaValue Additional arguments passed through to each handler.
function LUniverse:emit(event, ...) end

--- Creates a new blueprint that inherits from a parent blueprint and applies overrides.
---@param name string New blueprint name.
---@param parent string Name of the parent blueprint to inherit from.
---@param overrides table Component values to override or add on top of parent.
function LUniverse:extendBlueprint(name, parent, overrides) end

--- Dispatches all queued component-add and component-remove events to their registered
function LUniverse:flushObservers() end

--- Retrieves the current value of a named component on an entity.
---@param id number The entity ID.
---@param name string Component name to retrieve.
---@return LuaValue The component value, or nil if not present.
function LUniverse:get(id, name) end

--- Returns the internal bit index assigned to a bitmap tag name, or nil if not defined.
---@param name string The bitmap tag name.
---@return number? The bit index (0-63), or nil if not defined.
function LUniverse:getBitmapTagBit(name) end

--- Returns the default component table for a named blueprint.
---@param name string Blueprint name to inspect.
---@return table The component defaults table {compName = value, ...}.
function LUniverse:getBlueprintComponents(name) end

--- Returns an array of entity IDs that are direct children of the given parent.
---@param parentId number The parent entity ID.
---@return table Array of child entity ID numbers.
function LUniverse:getChildren(parentId) end

--- Returns a list of all component names currently attached to an entity.
---@param id number The entity ID.
---@return table Array of component name strings.
function LUniverse:getComponents(id) end

--- Returns an array of entity IDs that have been modified (component set/removed)
---@return table Array of entity ID numbers.
function LUniverse:getDirtyEntities() end

--- Returns a flat array of all currently alive entity IDs in the universe.
---@return table Array of entity ID numbers.
function LUniverse:getEntities() end

--- Returns all entity IDs on a specific layer.
---@param layer number The layer number to filter by.
---@return table Array of entity ID numbers on that layer.
function LUniverse:getEntitiesByLayer(layer) end

--- Returns all entity IDs that have a specific tag. Useful for batch operations
---@param tag string The tag name to filter by.
---@return table Array of entity ID numbers.
function LUniverse:getEntitiesByTag(tag) end

--- Returns all entity IDs sorted by layer (ascending). Within the same layer,
---@return table Array of entity ID numbers in layer-sorted order.
function LUniverse:getEntitiesSorted() end

--- Returns the number of entities currently alive in the universe.
---@return number Total alive entity count.
function LUniverse:getEntityCount() end

--- Returns the layer number assigned to an entity (default 0).
---@param id number The entity ID.
---@return number The entity's layer value.
function LUniverse:getLayer(id) end

--- Returns the parent entity ID of a child, or nil if the entity has no parent.
---@param childId number The child entity ID.
---@return number? The parent entity ID, or nil.
function LUniverse:getParent(childId) end

--- Returns all entity IDs that a source entity has a named relationship to.
---@param from number Source entity ID.
---@param name string Relationship name to query.
---@return table Array of target entity ID numbers.
function LUniverse:getRelated(from, name) end

--- Returns the number of systems currently registered in the universe.
---@return number System count.
function LUniverse:getSystemCount() end

--- Returns all string tags currently attached to an entity.
---@param id number The entity ID.
---@return table Array of tag name strings.
function LUniverse:getTags(id) end

--- Checks whether an entity currently has a specific named component attached.
---@param id number The entity ID.
---@param name string Component name to check.
---@return boolean True if the component exists on the entity.
function LUniverse:has(id, name) end

--- Checks whether an entity has a specific bitmap tag set.
---@param id number The entity ID.
---@param name string The bitmap tag name to check.
---@return boolean True if the bitmap tag is set on the entity.
function LUniverse:hasBitmapTag(id, name) end

--- Checks whether a blueprint with the given name is registered.
---@param name string Blueprint name to check.
---@return boolean True if the blueprint exists.
function LUniverse:hasBlueprint(name) end

--- Checks whether a specific directed relationship exists between two entities.
---@param from number Source entity ID.
---@param name string Relationship name.
---@param to number Target entity ID.
---@return boolean True if the relationship exists.
function LUniverse:hasRelation(from, name, to) end

--- Checks whether an entity has a specific string tag.
---@param id number The entity ID.
---@param tag string The tag name to check.
---@return boolean True if the entity has the tag.
function LUniverse:hasTag(id, tag) end

--- Checks whether an entity with the given ID currently exists in the universe.
---@param id number The entity ID to check.
---@return boolean True if the entity is alive, false if dead or never created.
function LUniverse:isAlive(id) end

--- Destroys an entity and removes all its components, tags, and relationships.
---@param id number The entity ID to destroy.
function LUniverse:kill(id) end

--- Destroys an entity and all of its children (and their children, recursively).
---@param id number The root entity ID to destroy.
function LUniverse:killRecursive(id) end

--- Returns an array of all registered blueprint names.
---@return table Array of blueprint name strings.
function LUniverse:listBlueprints() end

--- Registers an observer callback that fires whenever a specific component is added
---@param name string Component name to observe.
---@param callback function Called as callback(id, name) when the component is added.
function LUniverse:onComponentAdded(name, callback) end

--- Registers an observer callback that fires whenever a specific component is removed
---@param name string Component name to observe.
---@param callback function Called as callback(id, name) when the component is removed.
function LUniverse:onComponentRemoved(name, callback) end

--- Queries all entities that have ALL of the specified components.
---@param ... string One or more component names to match against.
---@return table Array of {id, comp1, comp2, ...} tables for matching entities.
function LUniverse:query(...) end

--- Returns all entities that have ALL of the specified bitmap tags (AND query).
---@param names table Array of bitmap tag name strings.
---@return table Array of entity IDs matching every tag.
function LUniverse:queryBitmapAll(names) end

--- Returns all entities that have ANY of the specified bitmap tags (OR query).
---@param names table Array of bitmap tag name strings.
---@return table Array of entity IDs matching at least one tag.
function LUniverse:queryBitmapAny(names) end

--- Returns all entity IDs that have a specific bitmap tag. O(n) scan with bitwise check,
---@param name string The bitmap tag name to filter by.
---@return table Array of matching entity ID numbers.
function LUniverse:queryBitmapTag(name) end

--- Queries entities with multiple components and invokes a callback for each match.
---@param names table Array of component name strings to require.
---@param callback function Called as callback(id, val1, val2, ...) per entity.
function LUniverse:queryMulti(names, callback) end

--- Queries entities that have ALL components in the first list but NONE from the second.
---@param with table Array of required component names.
---@param without table Array of excluded component names.
---@return table Array of matching {id, comp1, comp2, ...} tables.
function LUniverse:queryNot(with, without) end

--- Alias for clear(). Destroys all entities, components, tags, and systems.
function LUniverse:release() end

--- Removes a named component from an entity. Triggers onComponentRemoved observers.
---@param id number The entity ID.
---@param name string Component name to remove.
function LUniverse:remove(id, name) end

--- Unregisters a blueprint by name. Does not affect entities already spawned from it.
---@param name string Blueprint name to remove.
function LUniverse:removeBlueprint(name) end

--- Removes a specific directed relationship between two entities.
---@param from number Source entity ID.
---@param name string Relationship name.
---@param to number Target entity ID to unlink.
function LUniverse:removeRelation(from, name, to) end

--- Unregisters a previously added system table from the universe.
---@param system table The same system table reference that was passed to addSystem.
function LUniverse:removeSystem(system) end

--- Removes a string tag from an entity. Does nothing if the tag is not present.
---@param id number The entity ID.
---@param tag string The tag name to remove.
function LUniverse:removeTag(id, tag) end

--- Runs all registered systems' render (or draw) methods sorted by priority for
function LUniverse:render() end

--- Serializes the entire universe to a Lua table. Alias for snapshot().
---@return table A table representing the full universe state.
function LUniverse:serialize() end

--- Sets a named component value on an entity. If the component already exists it is
---@param id number The entity ID.
---@param name string Component name (e.g. "position", "health").
---@param value LuaValue The component value — typically a table, number, or string.
function LUniverse:set(id, name, value) end

--- Assigns a numeric render/sort layer to an entity. Entities on lower layers are
---@param id number The entity ID.
---@param layer number Integer layer value.
function LUniverse:setLayer(id, layer) end

--- Sets the parent of a child entity, creating a hierarchy. Pass nil to un-parent.
---@param childId number The child entity ID.
---@param parentId? number The parent entity ID, or nil to detach.
function LUniverse:setParent(childId, parentId) end

--- Serializes the entire universe state (all entities and components) into a Lua table.
---@return table A table representing the full universe state.
function LUniverse:snapshot() end

--- Creates a new entity in the universe and returns its unique numeric ID.
---@return number The newly created entity ID.
function LUniverse:spawn() end

--- Creates a new entity from a named blueprint. Optionally applies per-instance
---@param name string Blueprint name to instantiate.
---@param overrides? table Optional component overrides for this instance.
---@return number The newly created entity ID.
function LUniverse:spawnBlueprint(name, overrides) end

--- Spawns multiple entities from a blueprint in one call. Returns an array of the new
---@param name string Blueprint name to instantiate.
---@param count number How many entities to create.
---@param overrides? table Optional component overrides applied to all spawned entities.
---@return table Array of newly created entity ID numbers.
function LUniverse:spawnBulk(name, count, overrides) end

--- Returns and resets the diff of changes since the last call. Contains added/removed
---@return table {added_components, removed_components, deleted_entities, dirty_entities}.
function LUniverse:takeSnapshotDiff() end

--- Returns the type name string "LUniverse" for this userdata object.
---@return string Always "LUniverse".
function LUniverse:type() end

--- Checks whether this object matches a given type name. Returns true for
---@param name string Type name to check against.
---@return boolean True if the name matches.
function LUniverse:typeOf(name) end

--- Runs all registered systems' update methods sorted by priority for the "update" phase.
---@param dt number Delta time in seconds since the last frame.
function LUniverse:update(dt) end

--- Runs update on all systems that belong to a specific named phase.
---@param phase string The phase name to tick.
---@param dt number Delta time in seconds.
function LUniverse:updatePhase(phase, dt) end

--- Creates a new empty ECS universe. This is the entry point for all ECS operations.
---@return LUniverse A fresh universe with no entities, systems, or blueprints.
lurek.ecs.newUniverse = function() end

---@class lurek.effect
lurek.effect = {}

---@class LImageEffect
LImageEffect = {}

---@param name LuaValue
function LImageEffect:addEffect(name) end

function LImageEffect:clear() end

function LImageEffect:clearEffects() end

function LImageEffect:clone() end

function LImageEffect:effectCount() end

---@param key LuaValue
function LImageEffect:getEffect(key) end

function LImageEffect:getEffectCount() end

---@param idx LuaValue
function LImageEffect:removeByIndex(idx) end

---@param name LuaValue
function LImageEffect:removeByName(name) end

---@param key LuaValue
function LImageEffect:removeEffect(key) end

function LImageEffect:save() end

function LImageEffect:type() end

---@param name LuaValue
function LImageEffect:typeOf(name) end

---@class LOverlay
LOverlay = {}

function LOverlay:clear() end

---@param w LuaValue
---@param h LuaValue
function LOverlay:drawToImage(w, h) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
---@param dur? LuaValue
function LOverlay:fade(r, g, b, a, dur) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
---@param dur? LuaValue
function LOverlay:flash(r, g, b, a, dur) end

function LOverlay:getAmbientColor() end

function LOverlay:getCloudCount() end

function LOverlay:getCloudOpacity() end

function LOverlay:getCloudScale() end

function LOverlay:getCloudSpeed() end

function LOverlay:getDimensions() end

function LOverlay:getFilmGrainIntensity() end

function LOverlay:getFlashAlpha() end

function LOverlay:getFogColor() end

function LOverlay:getFogDensity() end

function LOverlay:getHeatHazeIntensity() end

function LOverlay:getHeight() end

function LOverlay:getLightningAlpha() end

function LOverlay:getLightningColor() end

function LOverlay:getShakeOffset() end

function LOverlay:getTimeOfDay() end

function LOverlay:getVignetteStrength() end

function LOverlay:getWater() end

function LOverlay:getWeather() end

function LOverlay:getWeatherIntensity() end

function LOverlay:getWidth() end

function LOverlay:getWindDirection() end

function LOverlay:getWindSpeed() end

function LOverlay:isActive() end

function LOverlay:isAmbientEnabled() end

function LOverlay:isCloudShadowsEnabled() end

function LOverlay:isFading() end

function LOverlay:isFilmGrainEnabled() end

function LOverlay:isFlashing() end

function LOverlay:isFogEnabled() end

function LOverlay:isHeatHazeEnabled() end

function LOverlay:isShaking() end

function LOverlay:isVignetteEnabled() end

function LOverlay:isWeatherEnabled() end

function LOverlay:pullAmbientFromLight() end

function LOverlay:pushAmbientToLight() end

function LOverlay:render() end

---@param w LuaValue
---@param h LuaValue
function LOverlay:resize(w, h) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LOverlay:setAmbientColor(r, g, b, a) end

---@param v LuaValue
function LOverlay:setAmbientEnabled(v) end

---@param v LuaValue
function LOverlay:setCloudCount(v) end

---@param v LuaValue
function LOverlay:setCloudOpacity(v) end

---@param v LuaValue
function LOverlay:setCloudScale(v) end

---@param v LuaValue
function LOverlay:setCloudShadows(v) end

---@param v LuaValue
function LOverlay:setCloudSpeed(v) end

---@param name? LuaValue
function LOverlay:setCustomShader(name) end

---@param v LuaValue
function LOverlay:setFilmGrainEnabled(v) end

---@param v LuaValue
function LOverlay:setFilmGrainIntensity(v) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LOverlay:setFogColor(r, g, b, a) end

---@param v LuaValue
function LOverlay:setFogDensity(v) end

---@param v LuaValue
function LOverlay:setFogEnabled(v) end

---@param v LuaValue
function LOverlay:setHeatHazeEnabled(v) end

---@param v LuaValue
function LOverlay:setHeatHazeIntensity(v) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LOverlay:setLightningColor(r, g, b, a) end

---@param v LuaValue
function LOverlay:setTimeOfDay(v) end

---@param v LuaValue
function LOverlay:setVignetteEnabled(v) end

---@param v LuaValue
function LOverlay:setVignetteStrength(v) end

---@param amplitude LuaValue
---@param frequency LuaValue
---@param speed LuaValue
function LOverlay:setWater(amplitude, frequency, speed) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param strength LuaValue
function LOverlay:setWaterTint(r, g, b, strength) end

---@param name LuaValue
function LOverlay:setWeather(name) end

---@param v LuaValue
function LOverlay:setWeatherEnabled(v) end

---@param v LuaValue
function LOverlay:setWeatherIntensity(v) end

---@param v LuaValue
function LOverlay:setWindDirection(v) end

---@param v LuaValue
function LOverlay:setWindSpeed(v) end

---@param intensity LuaValue
---@param dur? LuaValue
function LOverlay:shake(intensity, dur) end

---@param mode LuaValue
function LOverlay:syncAmbientWithLight(mode) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param target_alpha LuaValue
---@param duration LuaValue
function LOverlay:triggerFade(r, g, b, target_alpha, duration) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
---@param duration LuaValue
function LOverlay:triggerFlash(r, g, b, a, duration) end

function LOverlay:triggerLightning() end

---@param intensity LuaValue
---@param duration LuaValue
function LOverlay:triggerShake(intensity, duration) end

function LOverlay:type() end

---@param name LuaValue
function LOverlay:typeOf(name) end

---@param dt LuaValue
function LOverlay:update(dt) end

---@class LPostFxEffect
LPostFxEffect = {}

function LPostFxEffect:disableAutoUniforms() end

function LPostFxEffect:enableAutoUniforms() end

function LPostFxEffect:getEffectType() end

---@param name LuaValue
---@param default? LuaValue
function LPostFxEffect:getParameter(name, default) end

function LPostFxEffect:getParameterNames() end

function LPostFxEffect:getType() end

function LPostFxEffect:getTypeName() end

---@param name LuaValue
function LPostFxEffect:hasParameter(name) end

function LPostFxEffect:isAutoUniforms() end

function LPostFxEffect:isBuiltIn() end

function LPostFxEffect:isEnabled() end

---@param v LuaValue
function LPostFxEffect:setBrightness(v) end

---@param v LuaValue
function LPostFxEffect:setContrast(v) end

---@param enabled LuaValue
function LPostFxEffect:setEnabled(enabled) end

---@param v LuaValue
function LPostFxEffect:setIntensity(v) end

---@param v LuaValue
function LPostFxEffect:setOffset(v) end

---@param name LuaValue
---@param value LuaValue
function LPostFxEffect:setParameter(name, value) end

---@param v LuaValue
function LPostFxEffect:setRadius(v) end

---@param v LuaValue
function LPostFxEffect:setSaturation(v) end

---@param v LuaValue
function LPostFxEffect:setScanlineStrength(v) end

---@param v LuaValue
function LPostFxEffect:setStrength(v) end

---@param v LuaValue
function LPostFxEffect:setThreshold(v) end

function LPostFxEffect:type() end

---@param name LuaValue
function LPostFxEffect:typeOf(name) end

---@class LPostFxStack
LPostFxStack = {}

---@param effect_ud LuaValue
function LPostFxStack:add(effect_ud) end

function LPostFxStack:apply() end

function LPostFxStack:beginCapture() end

function LPostFxStack:clear() end

function LPostFxStack:clearFeedback() end

function LPostFxStack:dedup() end

function LPostFxStack:endCapture() end

function LPostFxStack:getDimensions() end

---@param index LuaValue
function LPostFxStack:getEffect(index) end

function LPostFxStack:getEffectCount() end

function LPostFxStack:getEnabledEffects() end

function LPostFxStack:getFeedback() end

function LPostFxStack:getHeight() end

function LPostFxStack:getWidth() end

---@param position LuaValue
---@param effect_ud LuaValue
function LPostFxStack:insert(position, effect_ud) end

function LPostFxStack:isCapturing() end

function LPostFxStack:isEmpty() end

---@param position LuaValue
function LPostFxStack:isEnabled(position) end

function LPostFxStack:len() end

---@param effect_ud LuaValue
function LPostFxStack:remove(effect_ud) end

---@param w LuaValue
---@param h LuaValue
function LPostFxStack:resize(w, h) end

---@param position LuaValue
---@param enabled LuaValue
function LPostFxStack:setEnabled(position, enabled) end

---@param factor LuaValue
function LPostFxStack:setFeedback(factor) end

function LPostFxStack:type() end

---@param name LuaValue
function LPostFxStack:typeOf(name) end

---@class LScreenTransition
LScreenTransition = {}

function LScreenTransition:color() end

function LScreenTransition:isActive() end

function LScreenTransition:isDone() end

function LScreenTransition:kind() end

function LScreenTransition:play() end

function LScreenTransition:progress() end

function LScreenTransition:reverse() end

function LScreenTransition:setColor() end

function LScreenTransition:type() end

---@param name LuaValue
function LScreenTransition:typeOf(name) end

---@param dt LuaValue
function LScreenTransition:update(dt) end

lurek.effect.getEffectTypes = function() end

lurek.effect.getShaderErrorDisplay = function() end

---@param shader_id LuaValue
lurek.effect.newCustomEffect = function(shader_id) end

---@param type_name LuaValue
lurek.effect.newEffect = function(type_name) end

---@param ... LuaValue
lurek.effect.newImageEffect = function(...) end

---@param w? LuaValue
---@param h? LuaValue
lurek.effect.newOverlay = function(w, h) end

---@param shader_id LuaValue
lurek.effect.newPass = function(shader_id) end

---@param name LuaValue
---@param w? LuaValue
---@param h? LuaValue
lurek.effect.newPresetStack = function(name, w, h) end

---@param w? LuaValue
---@param h? LuaValue
lurek.effect.newStack = function(w, h) end

---@param kind? LuaValue
---@param duration? LuaValue
---@param color_tbl? LuaValue
lurek.effect.newTransition = function(kind, duration, color_tbl) end

---@param enabled LuaValue
lurek.effect.setShaderErrorDisplay = function(enabled) end

---@class lurek.engine
lurek.engine = {}

lurek.engine.fps = function() end

lurek.engine.frameCount = function() end

lurek.engine.getConfigRevision = function() end

lurek.engine.getFrameBudget = function() end

lurek.engine.getFrameProfile = function() end

lurek.engine.getFrameProfileText = function() end

lurek.engine.getResourceStats = function() end

lurek.engine.getVersion = function() end

lurek.engine.isDebug = function() end

lurek.engine.memoryUsage = function() end

lurek.engine.platform = function() end

---@param budget_bytes LuaValue
lurek.engine.setResourceBudget = function(budget_bytes) end

lurek.engine.uptime = function() end

---@class lurek.event
lurek.event = {}

---@class LSignal
LSignal = {}

---@param name LuaValue
function LSignal:clear(name) end

function LSignal:clearAll() end

---@param name LuaValue
---@param func LuaValue
function LSignal:connect(name, func) end

---@param ... LuaValue
function LSignal:emit(...) end

---@param name LuaValue
function LSignal:getCount(name) end

function LSignal:getTotalCount() end

---@param name LuaValue
---@param callback LuaValue
function LSignal:once(name, callback) end

---@param name LuaValue
---@param callback LuaValue
function LSignal:register(name, callback) end

---@param name LuaValue
---@param callback LuaValue
---@param filter LuaValue
function LSignal:registerWithFilter(name, callback, filter) end

---@param handle LuaValue
function LSignal:remove(handle) end

function LSignal:type() end

---@param name LuaValue
function LSignal:typeOf(name) end

lurek.event.clear = function() end

lurek.event.clearHistory = function() end

---@param capacity LuaValue
lurek.event.enableHistory = function(capacity) end

---@param code? LuaValue
lurek.event.exit = function(code) end

lurek.event.flushDeferred = function() end

lurek.event.getHistory = function() end

lurek.event.newSignal = function() end

lurek.event.poll = function() end

lurek.event.pump = function() end

---@param ... LuaValue
lurek.event.push = function(...) end

---@param ... LuaValue
lurek.event.pushDeferred = function(...) end

---@param ... LuaValue
lurek.event.pushDeferredPriority = function(...) end

---@param ... LuaValue
lurek.event.pushPriority = function(...) end

lurek.event.quit = function() end

lurek.event.restart = function() end

---@param timeout? LuaValue
lurek.event.wait = function(timeout) end

---@class lurek.filesystem
lurek.filesystem = {}

---@class LFileData
LFileData = {}

function LFileData:getFilename() end

function LFileData:getSize() end

function LFileData:getString() end

function LFileData:type() end

---@param name LuaValue
function LFileData:typeOf(name) end

---@class LFileHandle
LFileHandle = {}

function LFileHandle:close() end

function LFileHandle:flush() end

function LFileHandle:getMode() end

function LFileHandle:getSize() end

function LFileHandle:isEOF() end

---@param count? LuaValue
function LFileHandle:read(count) end

function LFileHandle:readLine() end

---@param pos LuaValue
function LFileHandle:seek(pos) end

function LFileHandle:tell() end

function LFileHandle:type() end

---@param name LuaValue
function LFileHandle:typeOf(name) end

---@param data LuaValue
function LFileHandle:write(data) end

---@class LZipMount
LZipMount = {}

---@param virtual_path LuaValue
function LZipMount:contains(virtual_path) end

function LZipMount:listFiles() end

function LZipMount:prefix() end

---@param virtual_path LuaValue
function LZipMount:readFile(virtual_path) end

function LZipMount:type() end

---@param name LuaValue
function LZipMount:typeOf(name) end

---@param path LuaValue
---@param data LuaValue
lurek.filesystem.append = function(path, data) end

---@param src LuaValue
---@param dst LuaValue
lurek.filesystem.copy = function(src, dst) end

---@param path LuaValue
lurek.filesystem.createDirectory = function(path) end

---@param prefix? LuaValue
lurek.filesystem.createTempFile = function(prefix) end

---@param path LuaValue
lurek.filesystem.exists = function(path) end

---@param path LuaValue
lurek.filesystem.getDirectoryItems = function(path) end

lurek.filesystem.getIdentity = function() end

---@param path LuaValue
lurek.filesystem.getInfo = function(path) end

lurek.filesystem.getSaveDirectory = function() end

lurek.filesystem.getSource = function() end

lurek.filesystem.getUserDirectory = function() end

lurek.filesystem.getWorkingDirectory = function() end

---@param pattern LuaValue
lurek.filesystem.glob = function(pattern) end

---@param path LuaValue
lurek.filesystem.isDirectory = function(path) end

---@param path LuaValue
lurek.filesystem.isFile = function(path) end

---@param path LuaValue
lurek.filesystem.lines = function(path) end

---@param path LuaValue
lurek.filesystem.listRecursive = function(path) end

---@param path LuaValue
lurek.filesystem.load = function(path) end

---@param path LuaValue
lurek.filesystem.mkdir = function(path) end

---@param src LuaValue
---@param mp LuaValue
lurek.filesystem.mount = function(src, mp) end

---@param archive_path LuaValue
---@param prefix LuaValue
lurek.filesystem.mountZip = function(archive_path, prefix) end

---@param src LuaValue
---@param dst LuaValue
lurek.filesystem.move = function(src, dst) end

---@param path LuaValue
lurek.filesystem.newFileData = function(path) end

---@param path LuaValue
---@param mode LuaValue
lurek.filesystem.openFile = function(path, mode) end

---@param handle_id LuaValue
lurek.filesystem.pollAsync = function(handle_id) end

---@param handle_id LuaValue
lurek.filesystem.pollAsyncWrite = function(handle_id) end

lurek.filesystem.pollWatchers = function() end

---@param path LuaValue
lurek.filesystem.read = function(path) end

---@param path LuaValue
lurek.filesystem.readAsync = function(path) end

---@param path LuaValue
lurek.filesystem.readBytes = function(path) end

---@param path LuaValue
lurek.filesystem.readJson = function(path) end

---@param path LuaValue
---@param default_json LuaValue
lurek.filesystem.readOrWriteJson = function(path, default_json) end

---@param path LuaValue
lurek.filesystem.remove = function(path) end

---@param path LuaValue
lurek.filesystem.removeDir = function(path) end

---@param name LuaValue
lurek.filesystem.setIdentity = function(name) end

---@param path LuaValue
lurek.filesystem.stat = function(path) end

---@param path LuaValue
lurek.filesystem.toAbsolutePath = function(path) end

---@param mp LuaValue
lurek.filesystem.unmount = function(mp) end

---@param path LuaValue
lurek.filesystem.unwatchPath = function(path) end

---@param path LuaValue
lurek.filesystem.watchPath = function(path) end

---@param path LuaValue
---@param data LuaValue
lurek.filesystem.write = function(path, data) end

---@param path LuaValue
---@param data LuaValue
lurek.filesystem.writeAsync = function(path, data) end

---@param path LuaValue
---@param data LuaValue
lurek.filesystem.writeBytes = function(path, data) end

---@param path LuaValue
---@param json LuaValue
lurek.filesystem.writeJson = function(path, json) end

---@class lurek.globe
---@field MAX_PROVINCES number  Maximum number of provinces the globe supports.
---@field LOD_FAR string  LOD tier constant "far" â€” zoomed-out view (zoom < 1.5).
---@field LOD_MID string  LOD tier constant "mid" â€” medium zoom (1.5 ≤ zoom < 4.0).
---@field LOD_NEAR string  LOD tier constant "near" â€” close-zoom view (zoom ≥ 4.0).
lurek.globe = {}

---@class LGlobe
LGlobe = {}

---@param lat1 LuaValue
---@param lon1 LuaValue
---@param lat2 LuaValue
---@param lon2 LuaValue
---@param steps? LuaValue
function LGlobe:addArc(lat1, lon1, lat2, lon2, steps) end

---@param ltype LuaValue
---@param lat LuaValue
---@param lon LuaValue
---@param text LuaValue
function LGlobe:addLabel(ltype, lat, lon, text) end

---@param name LuaValue
---@param z_order? LuaValue
function LGlobe:addLayer(name, z_order) end

---@param mtype LuaValue
---@param lat LuaValue
---@param lon LuaValue
---@param label? LuaValue
function LGlobe:addMarker(mtype, lat, lon, label) end

---@param p LuaValue
function LGlobe:addProvince(p) end

---@param faction LuaValue
---@param start_id LuaValue
---@param max_cost LuaValue
function LGlobe:cacheReachability(faction, start_id, max_cost) end

---@param id LuaValue
function LGlobe:clearProvinceTexture(id) end

---@param viewer LuaValue
---@param payload LuaValue
function LGlobe:decodeFogBase64(viewer, payload) end

---@param viewer LuaValue
function LGlobe:encodeFogBase64(viewer) end

function LGlobe:exportProvinceMeshOBJ() end

---@param from_id LuaValue
---@param to_id LuaValue
function LGlobe:findPath(from_id, to_id) end

---@param faction LuaValue
function LGlobe:getCachedReachability(faction) end

function LGlobe:getCamera() end

---@param viewer LuaValue
---@param id LuaValue
function LGlobe:getFogState(viewer, id) end

function LGlobe:getLod() end

---@param id LuaValue
---@param key LuaValue
function LGlobe:getMarkerAttr(id, key) end

function LGlobe:getName() end

---@param id LuaValue
function LGlobe:getNeighbors(id) end

---@param id LuaValue
---@param key LuaValue
function LGlobe:getProvinceAttr(id, key) end

---@param id LuaValue
function LGlobe:getProvinceSector(id) end

---@param sector LuaValue
function LGlobe:getSectorProvinces(sector) end

function LGlobe:getTimeOfDay() end

---@param viewer LuaValue
---@param id LuaValue
function LGlobe:hideProvince(viewer, id) end

---@param viewer LuaValue
---@param id LuaValue
function LGlobe:isVisible(viewer, id) end

---@param id LuaValue
---@param lat LuaValue
---@param lon LuaValue
function LGlobe:moveMarker(id, lat, lon) end

---@param dlat LuaValue
---@param dlon LuaValue
function LGlobe:pan(dlat, dlon) end

---@param sx LuaValue
---@param sy LuaValue
function LGlobe:pick(sx, sy) end

---@param sx LuaValue
---@param sy LuaValue
function LGlobe:pickLatLon(sx, sy) end

---@param sx LuaValue
---@param sy LuaValue
---@param steps? LuaValue
function LGlobe:pickRaycast(sx, sy, steps) end

function LGlobe:provinceCount() end

---@param start_id LuaValue
---@param max_cost LuaValue
function LGlobe:reachable(start_id, max_cost) end

---@param id LuaValue
function LGlobe:removeArc(id) end

---@param name LuaValue
function LGlobe:removeHeatLayer(name) end

---@param id LuaValue
function LGlobe:removeLabel(id) end

---@param name LuaValue
function LGlobe:removeLayer(name) end

---@param id LuaValue
function LGlobe:removeMarker(id) end

---@param id LuaValue
function LGlobe:removeProvince(id) end

---@param viewer LuaValue
function LGlobe:revealAll(viewer) end

---@param viewer LuaValue
---@param id LuaValue
function LGlobe:revealProvince(viewer, id) end

---@param viewer? LuaValue
function LGlobe:setActiveViewer(viewer) end

---@param dps LuaValue
function LGlobe:setAutoRotationSpeed(dps) end

---@param show LuaValue
function LGlobe:setBorders(show) end

---@param lat LuaValue
---@param lon LuaValue
---@param z LuaValue
function LGlobe:setCamera(lat, lon, z) end

---@param viewer LuaValue
---@param id LuaValue
---@param state LuaValue
function LGlobe:setFogState(viewer, id, state) end

---@param name LuaValue
---@param attr_key LuaValue
---@param min LuaValue
---@param max LuaValue
---@param alpha LuaValue
function LGlobe:setHeatLayer(name, attr_key, min, max, alpha) end

---@param id LuaValue
---@param text LuaValue
function LGlobe:setLabelText(id, text) end

---@param id LuaValue
---@param vis LuaValue
function LGlobe:setLabelVisible(id, vis) end

---@param name LuaValue
---@param alpha LuaValue
function LGlobe:setLayerAlpha(name, alpha) end

---@param layer LuaValue
---@param id LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LGlobe:setLayerColor(layer, id, r, g, b, a) end

---@param name LuaValue
---@param vis LuaValue
function LGlobe:setLayerVisible(name, vis) end

---@param id LuaValue
---@param key LuaValue
---@param val LuaValue
function LGlobe:setMarkerAttr(id, key, val) end

---@param id LuaValue
---@param hz LuaValue
---@param amp LuaValue
function LGlobe:setMarkerPulse(id, hz, amp) end

---@param id LuaValue
---@param dps LuaValue
function LGlobe:setMarkerRotation(id, dps) end

---@param id LuaValue
---@param vis LuaValue
function LGlobe:setMarkerVisible(id, vis) end

---@param id LuaValue
---@param key LuaValue
---@param val LuaValue
function LGlobe:setProvinceAttr(id, key, val) end

---@param id LuaValue
---@param sector LuaValue
function LGlobe:setProvinceSector(id, sector) end

---@param id LuaValue
---@param tex_raw LuaValue
---@param u0 LuaValue
---@param v0 LuaValue
---@param u1 LuaValue
---@param v1 LuaValue
function LGlobe:setProvinceTexture(id, tex_raw, u0, v0, u1, v1) end

---@param deg LuaValue
function LGlobe:setRotation(deg) end

---@param t LuaValue
function LGlobe:setTimeOfDay(t) end

function LGlobe:type() end

---@param name LuaValue
function LGlobe:typeOf(name) end

---@param dt LuaValue
function LGlobe:update(dt) end

---@param factor LuaValue
function LGlobe:zoom(factor) end

---@class LGlobeRegistry
LGlobeRegistry = {}

---@param name LuaValue
function LGlobeRegistry:get(name) end

function LGlobeRegistry:names() end

---@param name LuaValue
---@param spec_tbl? LuaValue
function LGlobeRegistry:new(name, spec_tbl) end

---@param name LuaValue
function LGlobeRegistry:remove(name) end

function LGlobeRegistry:type() end

---@param name LuaValue
function LGlobeRegistry:typeOf(name) end

---@param name LuaValue
---@param seeds_tbl LuaValue
---@param spec_tbl? LuaValue
lurek.globe.generateVoronoi = function(name, seeds_tbl, spec_tbl) end

---@param name LuaValue
lurek.globe.get = function(name) end

---@param la LuaValue
---@param lo LuaValue
---@param lb LuaValue
---@param lo2 LuaValue
lurek.globe.greatCircleDistance = function(la, lo, lb, lo2) end

---@param la LuaValue
---@param lo LuaValue
---@param lb LuaValue
---@param lo2 LuaValue
---@param n LuaValue
lurek.globe.greatCirclePath = function(la, lo, lb, lo2, n) end

---@param lat LuaValue
---@param lon LuaValue
lurek.globe.latLonToUnit = function(lat, lon) end

---@param name LuaValue
---@param png_path LuaValue
---@param spec_tbl? LuaValue
lurek.globe.loadFromPNG = function(name, png_path, spec_tbl) end

---@param name LuaValue
---@param toml_src LuaValue
---@param spec_tbl? LuaValue
lurek.globe.loadFromTOML = function(name, toml_src, spec_tbl) end

---@param name LuaValue
---@param spec_tbl? LuaValue
lurek.globe.new = function(name, spec_tbl) end

---@class lurek.graph
lurek.graph = {}

---@class LGraph
LGraph = {}

---@param from_ud LuaValue
---@param to_ud LuaValue
---@param edge_type? LuaValue
function LGraph:addEdge(from_ud, to_ud, edge_type) end

---@param item_ud LuaValue
---@param node_ud LuaValue
function LGraph:addItem(item_ud, node_ud) end

---@param node_type? LuaValue
---@param capacity? LuaValue
function LGraph:addNode(node_type, capacity) end

---@param from_node LuaValue
---@param to_node LuaValue
function LGraph:astar(from_node, to_node) end

function LGraph:colorGraph() end

---@param item_type? LuaValue
---@param decay_time? LuaValue
function LGraph:createItem(item_type, decay_time) end

---@param from_ud LuaValue
---@param to_ud LuaValue
function LGraph:findPath(from_ud, to_ud) end

---@param item_ud LuaValue
---@param from_ud LuaValue
---@param to_ud LuaValue
function LGraph:findPathForItem(item_ud, from_ud, to_ud) end

function LGraph:getComponents() end

---@param from_ud LuaValue
---@param to_ud LuaValue
function LGraph:getDistance(from_ud, to_ud) end

---@param from_ud LuaValue
---@param to_ud LuaValue
function LGraph:getEdgeBetween(from_ud, to_ud) end

function LGraph:getEdgeCount() end

function LGraph:getEdges() end

function LGraph:getItemCount() end

function LGraph:getItems() end

---@param node_ud LuaValue
function LGraph:getNeighbors(node_ud) end

function LGraph:getNodeCount() end

function LGraph:getNodes() end

---@param from_ud LuaValue
---@param max_dist? LuaValue
function LGraph:getReachable(from_ud, max_dist) end

function LGraph:getStats() end

function LGraph:hasCycle() end

---@param edge_ud LuaValue
function LGraph:hasEdge(edge_ud) end

---@param item_ud LuaValue
function LGraph:hasItem(item_ud) end

---@param node_ud LuaValue
function LGraph:hasNode(node_ud) end

function LGraph:isBipartite() end

function LGraph:mst() end

---@param event_name LuaValue
---@param func LuaValue
function LGraph:on(event_name, func) end

function LGraph:processDemand() end

---@param edge_ud LuaValue
function LGraph:removeEdge(edge_ud) end

---@param item_ud LuaValue
function LGraph:removeItem(item_ud) end

---@param node_ud LuaValue
function LGraph:removeNode(node_ud) end

---@param item_ud LuaValue
---@param edge_ud LuaValue
function LGraph:sendItem(item_ud, edge_ud) end

function LGraph:step() end

---@param nodes LuaValue
function LGraph:subgraph(nodes) end

---@param dt LuaValue
function LGraph:tickParallel(dt) end

function LGraph:topologicalSort() end

function LGraph:type() end

---@param name LuaValue
function LGraph:typeOf(name) end

---@param dt LuaValue
function LGraph:update(dt) end

---@class LGraphEdge
LGraphEdge = {}

---@param t LuaValue
function LGraphEdge:addAllowedType(t) end

function LGraphEdge:clearAllowedTypes() end

function LGraphEdge:getCapacity() end

function LGraphEdge:getCooldown() end

function LGraphEdge:getFrom() end

function LGraphEdge:getItemsInTransit() end

function LGraphEdge:getSpeedModifier() end

function LGraphEdge:getThroughput() end

function LGraphEdge:getTo() end

function LGraphEdge:getTravelTime() end

function LGraphEdge:getType() end

function LGraphEdge:getWeight() end

function LGraphEdge:isActive() end

function LGraphEdge:isBidirectional() end

---@param t LuaValue
function LGraphEdge:isItemTypeAllowed(t) end

function LGraphEdge:isOnCooldown() end

---@param t LuaValue
function LGraphEdge:removeAllowedType(t) end

---@param a LuaValue
function LGraphEdge:setActive(a) end

---@param b LuaValue
function LGraphEdge:setBidirectional(b) end

---@param c LuaValue
function LGraphEdge:setCapacity(c) end

---@param c LuaValue
function LGraphEdge:setCooldown(c) end

---@param m LuaValue
function LGraphEdge:setSpeedModifier(m) end

---@param t LuaValue
function LGraphEdge:setThroughput(t) end

---@param t LuaValue
function LGraphEdge:setTravelTime(t) end

---@param t LuaValue
function LGraphEdge:setType(t) end

---@param w LuaValue
function LGraphEdge:setWeight(w) end

function LGraphEdge:type() end

---@param name LuaValue
function LGraphEdge:typeOf(name) end

---@class LGraphItem
LGraphItem = {}

function LGraphItem:getDecayTime() end

function LGraphItem:getPosition() end

function LGraphItem:getPriority() end

function LGraphItem:getRemainingLife() end

function LGraphItem:getType() end

function LGraphItem:isAlive() end

function LGraphItem:kill() end

---@param t LuaValue
function LGraphItem:setDecayTime(t) end

---@param p LuaValue
function LGraphItem:setPriority(p) end

---@param t LuaValue
function LGraphItem:setType(t) end

function LGraphItem:type() end

---@param name LuaValue
function LGraphItem:typeOf(name) end

---@class LGraphNode
LGraphNode = {}

---@param item_type LuaValue
---@param quantity LuaValue
---@param priority? LuaValue
function LGraphNode:addDemand(item_type, quantity, priority) end

---@param item_type LuaValue
---@param quantity LuaValue
function LGraphNode:addSupply(item_type, quantity) end

---@param tag LuaValue
function LGraphNode:addTag(tag) end

function LGraphNode:clearAllConversions() end

---@param in_type LuaValue
function LGraphNode:clearConversion(in_type) end

function LGraphNode:clearDemands() end

function LGraphNode:clearSupplies() end

function LGraphNode:clearTags() end

function LGraphNode:dequeue() end

---@param item_ud LuaValue
function LGraphNode:enqueue(item_ud) end

function LGraphNode:getCapacity() end

---@param dir? LuaValue
function LGraphNode:getEdges(dir) end

function LGraphNode:getFlowMode() end

function LGraphNode:getItemCount() end

function LGraphNode:getItems() end

function LGraphNode:getOverflowPolicy() end

function LGraphNode:getProcessTime() end

function LGraphNode:getPullFilter() end

function LGraphNode:getPullRate() end

function LGraphNode:getPushFilter() end

function LGraphNode:getPushRate() end

function LGraphNode:getQueueCapacity() end

function LGraphNode:getQueueSize() end

function LGraphNode:getTags() end

function LGraphNode:getType() end

---@param tag LuaValue
function LGraphNode:hasTag(tag) end

function LGraphNode:isActive() end

function LGraphNode:isFull() end

function LGraphNode:isQueueEnabled() end

---@param item_type LuaValue
function LGraphNode:removeDemand(item_type) end

---@param item_type LuaValue
function LGraphNode:removeSupply(item_type) end

---@param tag LuaValue
function LGraphNode:removeTag(tag) end

---@param a LuaValue
function LGraphNode:setActive(a) end

---@param c LuaValue
function LGraphNode:setCapacity(c) end

function LGraphNode:setConversion() end

---@param m LuaValue
function LGraphNode:setFlowMode(m) end

---@param p LuaValue
function LGraphNode:setOverflowPolicy(p) end

---@param t LuaValue
function LGraphNode:setProcessTime(t) end

---@param f? LuaValue
function LGraphNode:setPullFilter(f) end

---@param r LuaValue
function LGraphNode:setPullRate(r) end

---@param f? LuaValue
function LGraphNode:setPushFilter(f) end

---@param r LuaValue
function LGraphNode:setPushRate(r) end

---@param c LuaValue
function LGraphNode:setQueueCapacity(c) end

---@param e LuaValue
function LGraphNode:setQueueEnabled(e) end

---@param t LuaValue
function LGraphNode:setType(t) end

function LGraphNode:type() end

---@param name LuaValue
function LGraphNode:typeOf(name) end

lurek.graph.newGraph = function() end

---@class lurek.html
lurek.html = {}

---@class LHtmlDocument
LHtmlDocument = {}

---@param css LuaValue
function LHtmlDocument:addCss(css) end

function LHtmlDocument:clearCss() end

---@param x? LuaValue
---@param y? LuaValue
function LHtmlDocument:draw(x, y) end

---@param id LuaValue
function LHtmlDocument:getElementById(id) end

function LHtmlDocument:getHtml() end

function LHtmlDocument:getRoot() end

function LHtmlDocument:getViewport() end

function LHtmlDocument:isDirty() end

---@param key LuaValue
function LHtmlDocument:keypressed(key) end

---@param x LuaValue
---@param y LuaValue
function LHtmlDocument:mousemoved(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param button? LuaValue
function LHtmlDocument:mousepressed(x, y, button) end

---@param x LuaValue
---@param y LuaValue
---@param button? LuaValue
function LHtmlDocument:mousereleased(x, y, button) end

---@param handle LuaValue
function LHtmlDocument:off(handle) end

---@param event LuaValue
---@param func LuaValue
function LHtmlDocument:on(event, func) end

---@param selector LuaValue
function LHtmlDocument:query(selector) end

---@param selector LuaValue
function LHtmlDocument:queryAll(selector) end

function LHtmlDocument:relayout() end

---@param x? LuaValue
---@param y? LuaValue
function LHtmlDocument:render(x, y) end

---@param css LuaValue
function LHtmlDocument:setCss(css) end

---@param html LuaValue
function LHtmlDocument:setHtml(html) end

---@param w LuaValue
---@param h LuaValue
function LHtmlDocument:setViewport(w, h) end

---@param text LuaValue
function LHtmlDocument:textinput(text) end

function LHtmlDocument:type() end

---@param name LuaValue
function LHtmlDocument:typeOf(name) end

---@param dt LuaValue
function LHtmlDocument:update(dt) end

---@param dx LuaValue
---@param dy LuaValue
function LHtmlDocument:wheelmoved(dx, dy) end

---@class LHtmlElement
LHtmlElement = {}

---@param name LuaValue
function LHtmlElement:addClass(name) end

---@param html LuaValue
function LHtmlElement:appendHtml(html) end

function LHtmlElement:blur() end

function LHtmlElement:focus() end

---@param name LuaValue
function LHtmlElement:getAttribute(name) end

function LHtmlElement:getDocument() end

function LHtmlElement:getHtml() end

function LHtmlElement:getId() end

function LHtmlElement:getRect() end

---@param name LuaValue
function LHtmlElement:getStyle(name) end

function LHtmlElement:getTagName() end

function LHtmlElement:getText() end

---@param name LuaValue
function LHtmlElement:hasClass(name) end

---@param handle LuaValue
function LHtmlElement:off(handle) end

---@param event LuaValue
---@param func LuaValue
function LHtmlElement:on(event, func) end

---@param selector LuaValue
function LHtmlElement:query(selector) end

---@param selector LuaValue
function LHtmlElement:queryAll(selector) end

function LHtmlElement:remove() end

---@param name LuaValue
function LHtmlElement:removeAttribute(name) end

---@param name LuaValue
function LHtmlElement:removeClass(name) end

---@param name LuaValue
---@param value? LuaValue
function LHtmlElement:setAttribute(name, value) end

---@param html LuaValue
function LHtmlElement:setHtml(html) end

---@param id? LuaValue
function LHtmlElement:setId(id) end

---@param name LuaValue
---@param value? LuaValue
function LHtmlElement:setStyle(name, value) end

---@param text LuaValue
function LHtmlElement:setText(text) end

---@param name LuaValue
---@param force? LuaValue
function LHtmlElement:toggleClass(name, force) end

function LHtmlElement:type() end

---@param name LuaValue
function LHtmlElement:typeOf(name) end

lurek.html.isDefaultPrevented = function() end

---@param path LuaValue
---@param opts? LuaValue
lurek.html.loadDocument = function(path, opts) end

---@param source? LuaValue
---@param opts? LuaValue
lurek.html.newDocument = function(source, opts) end

lurek.html.preventDefault = function() end

lurek.html.stopPropagation = function() end

---@param feature LuaValue
lurek.html.supports = function(feature) end

---@class lurek.i18n
lurek.i18n = {}

lurek.i18n.buildIndex = function() end

lurek.i18n.categories = function() end

lurek.i18n.detectLocale = function() end

---@param timestamp LuaValue
---@param fmt? LuaValue
lurek.i18n.formatDate = function(timestamp, fmt) end

---@param n LuaValue
---@param opts? LuaValue
lurek.i18n.formatNumber = function(n, opts) end

lurek.i18n.getAvailableLanguages = function() end

lurek.i18n.getBase = function() end

lurek.i18n.getFallbacks = function() end

lurek.i18n.getKeys = function() end

lurek.i18n.getLanguage = function() end

lurek.i18n.getLanguages = function() end

lurek.i18n.getLoadedLocales = function() end

---@param key LuaValue
lurek.i18n.hasKey = function(key) end

---@param locale LuaValue
lurek.i18n.hasLanguage = function(locale) end

---@param template LuaValue
---@param vars LuaValue
lurek.i18n.interpolate = function(template, vars) end

---@param locale? LuaValue
lurek.i18n.isRTL = function(locale) end

lurek.i18n.keyCount = function() end

---@param category LuaValue
lurek.i18n.keysInCategory = function(category) end

---@param locale LuaValue
---@param content LuaValue
---@param format LuaValue
lurek.i18n.loadString = function(locale, content, format) end

---@param locale LuaValue
---@param tbl LuaValue
lurek.i18n.loadTable = function(locale, tbl) end

---@param reference LuaValue
lurek.i18n.localeCoverage = function(reference) end

---@param locale LuaValue
---@param entries LuaValue
lurek.i18n.mergeLocale = function(locale, entries) end

lurek.i18n.offChange = function() end

---@param cb LuaValue
lurek.i18n.onChange = function(cb) end

---@param cb LuaValue
lurek.i18n.onLanguageChange = function(cb) end

---@param n LuaValue
lurek.i18n.pluralFor = function(n) end

---@param query LuaValue
---@param limit? LuaValue
lurek.i18n.search = function(query, limit) end

---@param index LuaValue
---@param query LuaValue
---@param limit? LuaValue
lurek.i18n.searchIndexed = function(index, query, limit) end

---@param locale LuaValue
lurek.i18n.setBase = function(locale) end

---@param locales LuaValue
lurek.i18n.setFallbacks = function(locales) end

---@param locale LuaValue
---@param key LuaValue
---@param value LuaValue
lurek.i18n.setKey = function(locale, key, value) end

---@param locale LuaValue
lurek.i18n.setLanguage = function(locale) end

---@param key LuaValue
---@param vars? LuaValue
---@param count? LuaValue
lurek.i18n.t = function(key, vars, count) end

---@param key LuaValue
---@param gender LuaValue
---@param vars? LuaValue
lurek.i18n.tGender = function(key, gender, vars) end

---@param locale LuaValue
lurek.i18n.unloadTable = function(locale) end

---@param locale LuaValue
lurek.i18n.validateLocale = function(locale) end

---@class lurek.image
lurek.image = {}

---@class LCompressedImageData
LCompressedImageData = {}

function LCompressedImageData:getDimensions() end

function LCompressedImageData:getFormat() end

function LCompressedImageData:getHeight() end

function LCompressedImageData:getMipmapCount() end

function LCompressedImageData:getWidth() end

function LCompressedImageData:type() end

---@param name LuaValue
function LCompressedImageData:typeOf(name) end

---@class LImageData
LImageData = {}

---@param factor LuaValue
function LImageData:alphaMask(factor) end

---@param lut_ud LuaValue
function LImageData:applyPaletteLut(lut_ud) end

---@param src_ud LuaValue
---@param dst_x LuaValue
---@param dst_y LuaValue
function LImageData:blit(src_ud, dst_x, dst_y) end

---@param radius LuaValue
function LImageData:blur(radius) end

---@param factor LuaValue
function LImageData:brightness(factor) end

---@param factor LuaValue
function LImageData:contrast(factor) end

---@param kernel_t LuaValue
---@param ksize LuaValue
function LImageData:convolve(kernel_t, ksize) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LImageData:crop(x, y, w, h) end

---@param other_ud LuaValue
function LImageData:diff(other_ud) end

---@param cx LuaValue
---@param cy LuaValue
---@param radius LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LImageData:drawCircle(cx, cy, radius, r, g, b, a) end

---@param x0 LuaValue
---@param y0 LuaValue
---@param x1 LuaValue
---@param y1 LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LImageData:drawLine(x0, y0, x1, y1, r, g, b, a) end

function LImageData:drawNineSlice() end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LImageData:drawRect(x, y, w, h, r, g, b, a) end

---@param format LuaValue
function LImageData:encode(format) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LImageData:fill(r, g, b, a) end

function LImageData:flipHorizontal() end

function LImageData:flipVertical() end

---@param gamma LuaValue
function LImageData:gamma(gamma) end

function LImageData:getDimensions() end

function LImageData:getHeight() end

---@param x LuaValue
---@param y LuaValue
function LImageData:getPixel(x, y) end

function LImageData:getRawBytes() end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LImageData:getRegion(x, y, w, h) end

function LImageData:getString() end

function LImageData:getWidth() end

function LImageData:grayscale() end

function LImageData:invert() end

---@param func LuaValue
function LImageData:mapPixel(func) end

---@param func LuaValue
function LImageData:mapPixels(func) end

---@param amount LuaValue
function LImageData:noise(amount) end

---@param src_ud LuaValue
---@param dx LuaValue
---@param dy LuaValue
function LImageData:paste(src_ud, dx, dy) end

---@param levels LuaValue
function LImageData:posterize(levels) end

---@param ... LuaValue
function LImageData:resize(...) end

---@param new_w LuaValue
---@param new_h LuaValue
function LImageData:resizeNearest(new_w, new_h) end

function LImageData:rotate90cw() end

---@param factor LuaValue
function LImageData:saturation(factor) end

function LImageData:sepia() end

---@param x LuaValue
---@param y LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LImageData:setPixel(x, y, r, g, b, a) end

---@param bytes LuaValue
function LImageData:setRawData(bytes) end

function LImageData:sharpen() end

---@param value LuaValue
function LImageData:threshold(value) end

---@param tr LuaValue
---@param tg LuaValue
---@param tb LuaValue
---@param factor LuaValue
function LImageData:tint(tr, tg, tb, factor) end

function LImageData:type() end

---@param name LuaValue
function LImageData:typeOf(name) end

---@class LLayeredImage
LLayeredImage = {}

---@param name? LuaValue
function LLayeredImage:addLayer(name) end

function LLayeredImage:getHeight() end

---@param index LuaValue
function LLayeredImage:getLayer(index) end

---@param index LuaValue
function LLayeredImage:getName(index) end

---@param index LuaValue
function LLayeredImage:getOpacity(index) end

function LLayeredImage:getWidth() end

---@param index LuaValue
function LLayeredImage:isVisible(index) end

function LLayeredImage:layerCount() end

function LLayeredImage:merge() end

---@param from_idx LuaValue
---@param to_idx LuaValue
function LLayeredImage:moveLayer(from_idx, to_idx) end

---@param index LuaValue
function LLayeredImage:removeLayer(index) end

---@param path LuaValue
function LLayeredImage:save(path) end

---@param index LuaValue
---@param img LuaValue
function LLayeredImage:setLayer(index, img) end

---@param index LuaValue
---@param name LuaValue
function LLayeredImage:setName(index, name) end

---@param index LuaValue
---@param opacity LuaValue
function LLayeredImage:setOpacity(index, opacity) end

---@param index LuaValue
---@param visible LuaValue
function LLayeredImage:setVisible(index, visible) end

---@param a LuaValue
---@param b LuaValue
function LLayeredImage:swapLayers(a, b) end

function LLayeredImage:type() end

---@param name LuaValue
function LLayeredImage:typeOf(name) end

---@class LPaletteLUT
LPaletteLUT = {}

function LPaletteLUT:clear() end

---@param offset LuaValue
function LPaletteLUT:cycle(offset) end

function LPaletteLUT:getColorCount() end

---@param fr LuaValue
---@param fg LuaValue
---@param fb LuaValue
---@param fa LuaValue
---@param tr LuaValue
---@param tg LuaValue
---@param tb LuaValue
---@param ta LuaValue
function LPaletteLUT:setColor(fr, fg, fb, fa, tr, tg, tb, ta) end

function LPaletteLUT:type() end

---@param name LuaValue
function LPaletteLUT:typeOf(name) end

---@class LProvinceGrid
LProvinceGrid = {}

function LProvinceGrid:adjacencies() end

function LProvinceGrid:borderSegments() end

---@param bytes LuaValue
function LProvinceGrid:deserializeShapeData(bytes) end

---@param ... LuaValue
function LProvinceGrid:drawShapes(...) end

---@param x LuaValue
---@param y LuaValue
function LProvinceGrid:getAt(x, y) end

function LProvinceGrid:getHeight() end

function LProvinceGrid:getPolygons() end

function LProvinceGrid:getPolygonsSimplified() end

function LProvinceGrid:getWidth() end

function LProvinceGrid:provinceCount() end

function LProvinceGrid:provinceSpans() end

function LProvinceGrid:serializeShapeData() end

function LProvinceGrid:type() end

---@param name LuaValue
function LProvinceGrid:typeOf(name) end

lurek.image.fromScreen = function() end

---@param filename LuaValue
lurek.image.isCompressed = function(filename) end

---@param filename LuaValue
lurek.image.loadImage = function(filename) end

---@param filename LuaValue
lurek.image.loadLayered = function(filename) end

---@param filename LuaValue
lurek.image.newCompressedData = function(filename) end

---@param ... LuaValue
lurek.image.newImageData = function(...) end

---@param w LuaValue
---@param h LuaValue
---@param bytes LuaValue
lurek.image.newImageDataFromBytes = function(w, h, bytes) end

---@param width LuaValue
---@param height LuaValue
lurek.image.newLayeredImage = function(width, height) end

lurek.image.newPaletteLut = function() end

---@param filename LuaValue
lurek.image.newProvinceGrid = function(filename) end

---@param img_ud LuaValue
---@param filename LuaValue
lurek.image.saveImage = function(img_ud, filename) end

---@param img_ud LuaValue
---@param filename LuaValue
lurek.image.savePNG = function(img_ud, filename) end

---@class lurek.input
lurek.input = {}

---@class lurek.input.keyboard
lurek.input.keyboard = {}

---@class lurek.input.mouse
lurek.input.mouse = {}

---@class lurek.input.gamepad
lurek.input.gamepad = {}

---@class lurek.input.touch
lurek.input.touch = {}

---@class LCombo
LCombo = {}

---@param key LuaValue
function LCombo:feed(key) end

---@param index LuaValue
function LCombo:getStep(index) end

function LCombo:isInProgress() end

function LCombo:progress() end

function LCombo:reset() end

---@param dt LuaValue
function LCombo:tick(dt) end

function LCombo:totalSteps() end

function LCombo:type() end

---@param name LuaValue
function LCombo:typeOf(name) end

---@class LCursor
LCursor = {}

function LCursor:getType() end

function LCursor:release() end

function LCursor:type() end

---@param name LuaValue
function LCursor:typeOf(name) end

---@class LInputRecording
LInputRecording = {}

function LInputRecording:frameCount() end

function LInputRecording:toJson() end

function LInputRecording:totalFrames() end

function LInputRecording:type() end

---@param name LuaValue
function LInputRecording:typeOf(name) end

lurek.input.advancePlayback = function() end

---@param action LuaValue
---@param keys LuaValue
lurek.input.bind = function(action, keys) end

lurek.input.clearBindings = function() end

---@param id LuaValue
---@param axis LuaValue
lurek.input.gamepad.getAxis = function(id, axis) end

---@param id LuaValue
lurek.input.gamepad.getAxisCount = function(id) end

lurek.input.gamepad.getBackgroundEvents = function() end

lurek.input.getBindings = function() end

---@param id LuaValue
lurek.input.gamepad.getButtonCount = function(id) end

lurek.input.gamepad.getCount = function() end

lurek.input.mouse.getCursor = function() end

---@param id LuaValue
lurek.input.gamepad.getGUID = function(id) end

---@param guid LuaValue
lurek.input.gamepad.getGamepadMappingString = function(guid) end

---@param id LuaValue
---@param hat LuaValue
lurek.input.gamepad.getHat = function(id, hat) end

lurek.input.gamepad.getJoystickCount = function() end

lurek.input.gamepad.getJoysticks = function() end

---@param scancode LuaValue
lurek.input.keyboard.getKeyFromScancode = function(scancode) end

---@param id LuaValue
lurek.input.gamepad.getName = function(id) end

lurek.input.getPlaybackFrame = function() end

lurek.input.mouse.getPosition = function() end

---@param id LuaValue
lurek.input.touch.getPosition = function(id) end

---@param id LuaValue
lurek.input.touch.getPressure = function(id) end

lurek.input.mouse.getRelativeMode = function() end

---@param key LuaValue
lurek.input.keyboard.getScancodeFromKey = function(key) end

---@param name LuaValue
lurek.input.mouse.getSystemCursor = function(name) end

lurek.input.touch.getTouchCount = function() end

lurek.input.touch.getTouches = function() end

lurek.input.mouse.getWheelDelta = function() end

lurek.input.mouse.getX = function() end

lurek.input.mouse.getY = function() end

lurek.input.keyboard.hasKeyRepeat = function() end

lurek.input.keyboard.hasTextInput = function() end

---@param action LuaValue
lurek.input.isActionDown = function(action) end

---@param id LuaValue
lurek.input.gamepad.isConnected = function(id) end

lurek.input.mouse.isCursorSupported = function() end

---@param args LuaValue
lurek.input.keyboard.isDown = function(args) end

---@param button LuaValue
lurek.input.mouse.isDown = function(button) end

---@param id LuaValue
---@param button LuaValue
lurek.input.gamepad.isDown = function(id, button) end

lurek.input.isDown = function() end

---@param id LuaValue
lurek.input.gamepad.isGamepad = function(id) end

lurek.input.mouse.isGrabbed = function() end

---@param modifier LuaValue
lurek.input.keyboard.isModifierActive = function(modifier) end

lurek.input.isPlayingBack = function() end

lurek.input.isRecording = function() end

---@param scancode LuaValue
lurek.input.keyboard.isScancodeDown = function(scancode) end

---@param id LuaValue
lurek.input.gamepad.isVibrationSupported = function(id) end

lurek.input.mouse.isVisible = function() end

---@param path LuaValue
lurek.input.gamepad.loadGamepadMappings = function(path) end

---@param json LuaValue
lurek.input.loadRecording = function(json) end

---@param steps_val LuaValue
---@param opts? LuaValue
lurek.input.newCombo = function(steps_val, opts) end

lurek.input.mouse.newCursor = function() end

---@param name LuaValue
---@param keys LuaValue
lurek.input.newMapping = function(name, keys) end

---@param path LuaValue
lurek.input.gamepad.saveGamepadMappings = function(path) end

---@param enable LuaValue
lurek.input.gamepad.setBackgroundEvents = function(enable) end

---@param cursor_val LuaValue
lurek.input.mouse.setCursor = function(cursor_val) end

---@param guid LuaValue
---@param mapping LuaValue
lurek.input.gamepad.setGamepadMapping = function(guid, mapping) end

---@param grabbed LuaValue
lurek.input.mouse.setGrabbed = function(grabbed) end

---@param enabled LuaValue
lurek.input.keyboard.setKeyRepeat = function(enabled) end

---@param x LuaValue
---@param y LuaValue
lurek.input.mouse.setPosition = function(x, y) end

---@param relative LuaValue
lurek.input.mouse.setRelativeMode = function(relative) end

---@param enabled LuaValue
lurek.input.keyboard.setTextInput = function(enabled) end

---@param id LuaValue
---@param low_freq LuaValue
---@param high_freq LuaValue
---@param duration_ms LuaValue
lurek.input.gamepad.setVibration = function(id, low_freq, high_freq, duration_ms) end

---@param visible LuaValue
lurek.input.mouse.setVisible = function(visible) end

lurek.input.startPlayback = function() end

lurek.input.startRecording = function() end

lurek.input.stopPlayback = function() end

lurek.input.stopRecording = function() end

---@param action LuaValue
lurek.input.unbind = function(action) end

---@param id LuaValue
---@param low_freq LuaValue
---@param high_freq LuaValue
---@param duration_ms LuaValue
lurek.input.gamepad.vibrate = function(id, low_freq, high_freq, duration_ms) end

---@param x LuaValue
---@param y LuaValue
---@param deadzone? LuaValue
lurek.input.gamepad.virtualDpad = function(x, y, deadzone) end

---@param action LuaValue
lurek.input.wasActionPressed = function(action) end

---@param action LuaValue
---@param frames LuaValue
lurek.input.wasActionPressedWithin = function(action, frames) end

---@param action LuaValue
lurek.input.wasActionReleased = function(action) end

---@param id LuaValue
lurek.input.gamepad.wasConnected = function(id) end

---@param id LuaValue
lurek.input.gamepad.wasDisconnected = function(id) end

---@param id LuaValue
---@param button LuaValue
lurek.input.gamepad.wasPressed = function(id, button) end

---@param id LuaValue
lurek.input.touch.wasPressed = function(id) end

lurek.input.wasPressed = function() end

---@param id LuaValue
---@param button LuaValue
lurek.input.gamepad.wasReleased = function(id, button) end

---@param id LuaValue
lurek.input.touch.wasReleased = function(id) end

lurek.input.wasReleased = function() end

---@class lurek.light
lurek.light = {}

---@class LLight
LLight = {}

---@param min LuaValue
---@param max LuaValue
---@param hz LuaValue
function LLight:addFlicker(min, max, hz) end

function LLight:clearCookie() end

function LLight:clearNormalMap() end

function LLight:getAttenuation() end

function LLight:getBlendMode() end

function LLight:getColor() end

function LLight:getCookie() end

function LLight:getDirection() end

function LLight:getEnergy() end

function LLight:getFalloff() end

function LLight:getFlicker() end

function LLight:getGroupId() end

function LLight:getInnerAngle() end

function LLight:getIntensity() end

function LLight:getLightMask() end

function LLight:getLightType() end

function LLight:getNormalMap() end

function LLight:getNormalStrength() end

function LLight:getOuterAngle() end

function LLight:getPosition() end

function LLight:getRadius() end

function LLight:getShadowColor() end

function LLight:getShadowFilter() end

function LLight:getShadowMask() end

function LLight:getShadowSmooth() end

function LLight:getShadowSoftness() end

function LLight:isEnabled() end

function LLight:isFlickerEnabled() end

function LLight:isShadowEnabled() end

function LLight:isValid() end

function LLight:isVolumetric() end

function LLight:remove() end

---@param c LuaValue
---@param l LuaValue
---@param q LuaValue
function LLight:setAttenuation(c, l, q) end

---@param mode LuaValue
function LLight:setBlendMode(mode) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LLight:setColor(r, g, b, a) end

---@param path LuaValue
function LLight:setCookie(path) end

---@param dir LuaValue
function LLight:setDirection(dir) end

---@param b LuaValue
function LLight:setEnabled(b) end

---@param e LuaValue
function LLight:setEnergy(e) end

---@param mode LuaValue
function LLight:setFalloff(mode) end

---@param speed LuaValue
---@param strength LuaValue
function LLight:setFlicker(speed, strength) end

---@param b LuaValue
function LLight:setFlickerEnabled(b) end

---@param id LuaValue
function LLight:setGroupId(id) end

---@param a LuaValue
function LLight:setInnerAngle(a) end

---@param i LuaValue
function LLight:setIntensity(i) end

---@param mask LuaValue
function LLight:setLightMask(mask) end

---@param t LuaValue
function LLight:setLightType(t) end

---@param path LuaValue
function LLight:setNormalMap(path) end

---@param strength LuaValue
function LLight:setNormalStrength(strength) end

---@param a LuaValue
function LLight:setOuterAngle(a) end

---@param x LuaValue
---@param y LuaValue
function LLight:setPosition(x, y) end

---@param r LuaValue
function LLight:setRadius(r) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LLight:setShadowColor(r, g, b, a) end

---@param b LuaValue
function LLight:setShadowEnabled(b) end

---@param filter LuaValue
function LLight:setShadowFilter(filter) end

---@param mask LuaValue
function LLight:setShadowMask(mask) end

---@param s LuaValue
function LLight:setShadowSmooth(s) end

---@param softness LuaValue
function LLight:setShadowSoftness(softness) end

---@param b LuaValue
function LLight:setVolumetric(b) end

function LLight:stopTransition() end

function LLight:transitionProgress() end

---@param target LuaValue
---@param duration LuaValue
function LLight:transitionTo(target, duration) end

function LLight:type() end

---@param name LuaValue
function LLight:typeOf(name) end

---@param dt LuaValue
function LLight:updateTransition(dt) end

---@class LOccluder
LOccluder = {}

function LOccluder:getLightMask() end

function LOccluder:getOpacity() end

function LOccluder:getPosition() end

function LOccluder:getVertices() end

function LOccluder:isEnabled() end

function LOccluder:isValid() end

function LOccluder:remove() end

---@param b LuaValue
function LOccluder:setEnabled(b) end

---@param mask LuaValue
function LOccluder:setLightMask(mask) end

---@param o LuaValue
function LOccluder:setOpacity(o) end

---@param x LuaValue
---@param y LuaValue
function LOccluder:setPosition(x, y) end

---@param tbl LuaValue
function LOccluder:setVertices(tbl) end

function LOccluder:type() end

---@param name LuaValue
function LOccluder:typeOf(name) end

---@param dt LuaValue
lurek.light.advanceFlickers = function(dt) end

lurek.light.clear = function() end

lurek.light.getAmbient = function() end

lurek.light.getGodRayHints = function() end

---@param group_id LuaValue
lurek.light.getGroupCount = function(group_id) end

lurek.light.getLightCount = function() end

lurek.light.getMaxLights = function() end

lurek.light.getNormalMapHints = function() end

lurek.light.getOccluderCount = function() end

lurek.light.isEnabled = function() end

---@param x LuaValue
---@param y LuaValue
---@param radius LuaValue
---@param opts? LuaValue
lurek.light.newLight = function(x, y, radius, opts) end

---@param vtbl LuaValue
---@param opts? LuaValue
lurek.light.newOccluder = function(vtbl, opts) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
lurek.light.setAmbient = function(r, g, b, a) end

---@param enabled LuaValue
lurek.light.setEnabled = function(enabled) end

---@param group_id LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
lurek.light.setGroupColor = function(group_id, r, g, b, a) end

---@param group_id LuaValue
---@param enabled LuaValue
lurek.light.setGroupEnabled = function(group_id, enabled) end

---@param group_id LuaValue
---@param intensity LuaValue
lurek.light.setGroupIntensity = function(group_id, intensity) end

---@param n LuaValue
lurek.light.setMaxLights = function(n) end

lurek.light.syncAmbient = function() end

---@class lurek.log
lurek.log = {}

---@param config LuaValue
lurek.log.addSink = function(config) end

lurek.log.clearSinks = function() end

---@param message LuaValue
---@param tag? LuaValue
lurek.log.debug = function(message, tag) end

---@param message LuaValue
---@param fields_tbl LuaValue
lurek.log.debug_fields = function(message, fields_tbl) end

---@param message LuaValue
---@param tag? LuaValue
lurek.log.error = function(message, tag) end

---@param message LuaValue
---@param fields_tbl LuaValue
lurek.log.error_fields = function(message, fields_tbl) end

---@param id LuaValue
lurek.log.flushFile = function(id) end

lurek.log.getLevel = function() end

---@param message LuaValue
---@param tag? LuaValue
lurek.log.info = function(message, tag) end

---@param message LuaValue
---@param fields_tbl LuaValue
lurek.log.info_fields = function(message, fields_tbl) end

lurek.log.listSinks = function() end

---@param level LuaValue
---@param message LuaValue
---@param tag? LuaValue
lurek.log.print = function(level, message, tag) end

---@param id LuaValue
---@param drain? LuaValue
lurek.log.readMemory = function(id, drain) end

---@param id LuaValue
lurek.log.removeSink = function(id) end

---@param level LuaValue
lurek.log.setLevel = function(level) end

---@param level_str LuaValue
---@param message LuaValue
---@param fields_tbl LuaValue
lurek.log.struct = function(level_str, message, fields_tbl) end

---@param message LuaValue
---@param tag? LuaValue
lurek.log.warn = function(message, tag) end

---@param message LuaValue
---@param fields_tbl LuaValue
lurek.log.warn_fields = function(message, fields_tbl) end

---@class lurek.math
---@field pi number  π ≈ 3.14159265358979
---@field tau number  τ = 2π ≈ 6.28318530717959
lurek.math = {}

---@class LAabbTree
LAabbTree = {}

function LAabbTree:clear() end

---@param id LuaValue
function LAabbTree:contains(id) end

---@param id LuaValue
---@param min_x LuaValue
---@param min_y LuaValue
---@param max_x LuaValue
---@param max_y LuaValue
function LAabbTree:insert(id, min_x, min_y, max_x, max_y) end

function LAabbTree:isEmpty() end

function LAabbTree:len() end

---@param min_x LuaValue
---@param min_y LuaValue
---@param max_x LuaValue
---@param max_y LuaValue
function LAabbTree:query(min_x, min_y, max_x, max_y) end

---@param x LuaValue
---@param y LuaValue
function LAabbTree:queryPoint(x, y) end

---@param id LuaValue
function LAabbTree:remove(id) end

function LAabbTree:type() end

---@param name LuaValue
function LAabbTree:typeOf(name) end

---@param id LuaValue
---@param min_x LuaValue
---@param min_y LuaValue
---@param max_x LuaValue
---@param max_y LuaValue
function LAabbTree:update(id, min_x, min_y, max_x, max_y) end

---@class LBezierCurve
LBezierCurve = {}

---@param t LuaValue
function LBezierCurve:evaluate(t) end

---@param distance LuaValue
---@param samples? LuaValue
function LBezierCurve:evaluateAtDistance(distance, samples) end

---@param index LuaValue
function LBezierCurve:getControlPoint(index) end

function LBezierCurve:getControlPointCount() end

function LBezierCurve:getDerivative() end

---@param x LuaValue
---@param y LuaValue
---@param index? LuaValue
function LBezierCurve:insertControlPoint(x, y, index) end

function LBezierCurve:length() end

---@param index LuaValue
function LBezierCurve:removeControlPoint(index) end

---@param segments LuaValue
function LBezierCurve:render(segments) end

---@param angle LuaValue
---@param ox LuaValue
---@param oy LuaValue
function LBezierCurve:rotate(angle, ox, oy) end

---@param s LuaValue
---@param ox LuaValue
---@param oy LuaValue
function LBezierCurve:scale(s, ox, oy) end

---@param index LuaValue
---@param x LuaValue
---@param y LuaValue
function LBezierCurve:setControlPoint(index, x, y) end

---@param dx LuaValue
---@param dy LuaValue
function LBezierCurve:translate(dx, dy) end

function LBezierCurve:type() end

---@param name LuaValue
function LBezierCurve:typeOf(name) end

---@class LCatmullRom
LCatmullRom = {}

---@param x LuaValue
---@param y LuaValue
function LCatmullRom:addPoint(x, y) end

function LCatmullRom:len() end

---@param idx LuaValue
function LCatmullRom:removePoint(idx) end

---@param t LuaValue
function LCatmullRom:sample(t) end

---@param seg LuaValue
---@param t LuaValue
function LCatmullRom:sampleSegment(seg, t) end

function LCatmullRom:type() end

---@param name LuaValue
function LCatmullRom:typeOf(name) end

---@class LCircle
LCircle = {}

function LCircle:aabb() end

function LCircle:area() end

---@param px LuaValue
---@param py LuaValue
function LCircle:contains(px, py) end

---@param other LuaValue
function LCircle:intersects(other) end

function LCircle:perimeter() end

function LCircle:radius() end

function LCircle:type() end

---@param name LuaValue
function LCircle:typeOf(name) end

function LCircle:x() end

function LCircle:y() end

---@class LHermite
LHermite = {}

---@param t LuaValue
function LHermite:sample(t) end

function LHermite:type() end

---@param name LuaValue
function LHermite:typeOf(name) end

---@class LNoiseGenerator
LNoiseGenerator = {}

function LNoiseGenerator:fbm() end

---@param w LuaValue
---@param h LuaValue
---@param opts? LuaValue
function LNoiseGenerator:generateMap(w, h, opts) end

---@param w LuaValue
---@param h LuaValue
---@param opts? LuaValue
function LNoiseGenerator:generateMapCompute(w, h, opts) end

function LNoiseGenerator:getSeed() end

---@param x LuaValue
function LNoiseGenerator:perlin1d(x) end

---@param x LuaValue
---@param y LuaValue
function LNoiseGenerator:perlin2d(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param z LuaValue
function LNoiseGenerator:perlin3d(x, y, z) end

---@param x LuaValue
---@param y LuaValue
---@param z LuaValue
---@param w LuaValue
function LNoiseGenerator:perlin4d(x, y, z, w) end

function LNoiseGenerator:ridged() end

---@param seed LuaValue
function LNoiseGenerator:setSeed(seed) end

---@param x LuaValue
function LNoiseGenerator:simplex1d(x) end

---@param x LuaValue
---@param y LuaValue
function LNoiseGenerator:simplex2d(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param z LuaValue
function LNoiseGenerator:simplex3d(x, y, z) end

function LNoiseGenerator:turbulence() end

function LNoiseGenerator:type() end

---@param name LuaValue
function LNoiseGenerator:typeOf(name) end

---@param x LuaValue
---@param y LuaValue
---@param strength LuaValue
function LNoiseGenerator:warpDomain(x, y, strength) end

---@param x LuaValue
---@param y LuaValue
---@param dist_name? LuaValue
---@param f2? LuaValue
function LNoiseGenerator:worley2d(x, y, dist_name, f2) end

---@param x LuaValue
---@param y LuaValue
---@param z LuaValue
---@param dist_name? LuaValue
---@param f2? LuaValue
function LNoiseGenerator:worley3d(x, y, z, dist_name, f2) end

---@class LRandomGenerator
LRandomGenerator = {}

function LRandomGenerator:getSeed() end

function LRandomGenerator:getState() end

function LRandomGenerator:random() end

---@param min LuaValue
---@param max LuaValue
function LRandomGenerator:randomFloat(min, max) end

---@param min LuaValue
---@param max LuaValue
function LRandomGenerator:randomInt(min, max) end

---@param stddev? LuaValue
---@param mean? LuaValue
function LRandomGenerator:randomNormal(stddev, mean) end

---@param seed LuaValue
function LRandomGenerator:setSeed(seed) end

---@param state LuaValue
function LRandomGenerator:setState(state) end

function LRandomGenerator:type() end

---@param name LuaValue
function LRandomGenerator:typeOf(name) end

---@class LRectPacker
LRectPacker = {}

function LRectPacker:clear() end

function LRectPacker:getPacked() end

function LRectPacker:occupancy() end

---@param w LuaValue
---@param h LuaValue
---@param id? LuaValue
function LRectPacker:pack(w, h, id) end

---@class LSpatialHash
LSpatialHash = {}

function LSpatialHash:clear() end

function LSpatialHash:getCellSize() end

function LSpatialHash:getItemCount() end

---@param id LuaValue
---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LSpatialHash:insert(id, x, y, w, h) end

---@param cx LuaValue
---@param cy LuaValue
---@param radius LuaValue
function LSpatialHash:queryCircle(cx, cy, radius) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LSpatialHash:queryRect(x, y, w, h) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
function LSpatialHash:querySegment(x1, y1, x2, y2) end

---@param id LuaValue
function LSpatialHash:remove(id) end

function LSpatialHash:type() end

---@param name LuaValue
function LSpatialHash:typeOf(name) end

---@param id LuaValue
---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LSpatialHash:update(id, x, y, w, h) end

---@class LTransform
LTransform = {}

function LTransform:clone() end

function LTransform:decompose() end

function LTransform:getMatrix() end

function LTransform:inverse() end

---@param x LuaValue
---@param y LuaValue
function LTransform:inverseTransformPoint(x, y) end

function LTransform:reset() end

---@param angle LuaValue
function LTransform:rotate(angle) end

---@param sx LuaValue
---@param sy? LuaValue
function LTransform:scale(sx, sy) end

function LTransform:setTransformation() end

---@param kx LuaValue
---@param ky LuaValue
function LTransform:shear(kx, ky) end

---@param x LuaValue
---@param y LuaValue
function LTransform:transformPoint(x, y) end

---@param dx LuaValue
---@param dy LuaValue
function LTransform:translate(dx, dy) end

function LTransform:type() end

---@param name LuaValue
function LTransform:typeOf(name) end

---@class LTween
LTween = {}

---@param start LuaValue
---@param target LuaValue
function LTween:addValue(start, target) end

function LTween:getAllValues() end

function LTween:getClock() end

function LTween:getDuration() end

function LTween:getEasingName() end

function LTween:getTime() end

---@param index? LuaValue
function LTween:getValue(index) end

function LTween:getValueCount() end

function LTween:isComplete() end

function LTween:reset() end

---@param t LuaValue
function LTween:set(t) end

---@param t LuaValue
function LTween:setTime(t) end

function LTween:type() end

---@param name LuaValue
function LTween:typeOf(name) end

---@param dt LuaValue
function LTween:update(dt) end

---@class LVec2
---@field x number  x component
---@field y number  y component
LVec2 = {}

function LVec2:angle() end

---@param other LuaValue
function LVec2:cross(other) end

---@param other LuaValue
function LVec2:distance(other) end

---@param other LuaValue
function LVec2:dot(other) end

---@param radians LuaValue
LVec2.fromAngle = function(radians) end

function LVec2:length() end

function LVec2:lengthSquared() end

---@param other LuaValue
---@param t LuaValue
function LVec2:lerp(other, t) end

function LVec2:normalize() end

function LVec2:normalized() end

function LVec2:perpendicular() end

---@param normal LuaValue
function LVec2:reflect(normal) end

---@param angle LuaValue
function LVec2:rotate(angle) end

function LVec2:type() end

---@param name LuaValue
function LVec2:typeOf(name) end

function LVec2:x() end

function LVec2:y() end

---@class LVec3
---@field x number  x component
---@field y number  y component
---@field z number  z component
LVec3 = {}

---@param other LuaValue
function LVec3:add(other) end

---@param other LuaValue
function LVec3:cross(other) end

---@param other LuaValue
function LVec3:distance(other) end

---@param other LuaValue
function LVec3:dot(other) end

function LVec3:length() end

function LVec3:lengthSquared() end

---@param other LuaValue
---@param t LuaValue
function LVec3:lerp(other, t) end

function LVec3:normalize() end

---@param s LuaValue
function LVec3:scale(s) end

---@param v LuaValue
LVec3.splat = function(v) end

---@param other LuaValue
function LVec3:sub(other) end

function LVec3:type() end

---@param name LuaValue
function LVec3:typeOf(name) end

---@param x LuaValue
---@param y LuaValue
lurek.math.Vec2 = function(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param z LuaValue
lurek.math.Vec3 = function(x, y, z) end

lurek.math.aabbTree = function() end

---@param x LuaValue
lurek.math.abs = function(x) end

---@param x LuaValue
lurek.math.acos = function(x) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
lurek.math.angleBetween = function(x1, y1, x2, y2) end

---@param name LuaValue
---@param t LuaValue
lurek.math.applyEasing = function(name, t) end

---@param x LuaValue
lurek.math.asin = function(x) end

---@param y LuaValue
---@param x? LuaValue
lurek.math.atan = function(y, x) end

---@param y LuaValue
---@param x LuaValue
lurek.math.atan2 = function(y, x) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
lurek.math.bresenham = function(x1, y1, x2, y2) end

---@param points LuaValue
lurek.math.catmullRom = function(points) end

---@param x LuaValue
lurek.math.ceil = function(x) end

---@param cx LuaValue
---@param cy LuaValue
---@param r LuaValue
---@param px LuaValue
---@param py LuaValue
lurek.math.circleContainsPoint = function(cx, cy, r, px, py) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param r1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param r2 LuaValue
lurek.math.circleIntersectsCircle = function(x1, y1, r1, x2, y2, r2) end

---@param cx LuaValue
---@param cy LuaValue
---@param r LuaValue
---@param lx1 LuaValue
---@param ly1 LuaValue
---@param lx2 LuaValue
---@param ly2 LuaValue
lurek.math.circleIntersectsLine = function(cx, cy, r, lx1, ly1, lx2, ly2) end

---@param cx LuaValue
---@param cy LuaValue
---@param r LuaValue
---@param sx1 LuaValue
---@param sy1 LuaValue
---@param sx2 LuaValue
---@param sy2 LuaValue
lurek.math.circleIntersectsSegment = function(cx, cy, r, sx1, sy1, sx2, sy2) end

---@param v LuaValue
---@param min LuaValue
---@param max LuaValue
lurek.math.clamp = function(v, min, max) end

---@param px LuaValue
---@param py LuaValue
---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
lurek.math.closestPointOnSegment = function(px, py, x1, y1, x2, y2) end

---@param pts LuaValue
lurek.math.convexHull = function(pts) end

---@param x LuaValue
lurek.math.cos = function(x) end

---@param rad LuaValue
lurek.math.deg = function(rad) end

---@param pts LuaValue
lurek.math.delaunayTriangulate = function(pts) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
lurek.math.distance = function(x1, y1, x2, y2) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
lurek.math.distanceSq = function(x1, y1, x2, y2) end

---@param x LuaValue
lurek.math.exp = function(x) end

lurek.math.fbm = function() end

---@param x LuaValue
lurek.math.floor = function(x) end

---@param x LuaValue
---@param y LuaValue
lurek.math.fmod = function(x, y) end

---@param hex LuaValue
lurek.math.fromHex = function(hex) end

---@param c LuaValue
lurek.math.gammaToLinear = function(c) end

---@param p0x LuaValue
---@param p0y LuaValue
---@param p1x LuaValue
---@param p1y LuaValue
---@param m0x LuaValue
---@param m0y LuaValue
---@param m1x LuaValue
---@param m1y LuaValue
lurek.math.hermite = function(p0x, p0y, p1x, p1y, m0x, m0y, m1x, m1y) end

---@param h LuaValue
---@param s LuaValue
---@param l LuaValue
lurek.math.hslToRgb = function(h, s, l) end

---@param t LuaValue
lurek.math.inBack = function(t) end

---@param t LuaValue
lurek.math.inBounce = function(t) end

---@param t LuaValue
lurek.math.inCubic = function(t) end

---@param t LuaValue
lurek.math.inElastic = function(t) end

---@param t LuaValue
lurek.math.inExpo = function(t) end

---@param t LuaValue
lurek.math.inOutBack = function(t) end

---@param t LuaValue
lurek.math.inOutBounce = function(t) end

---@param t LuaValue
lurek.math.inOutCubic = function(t) end

---@param t LuaValue
lurek.math.inOutElastic = function(t) end

---@param t LuaValue
lurek.math.inOutExpo = function(t) end

---@param t LuaValue
lurek.math.inOutQuad = function(t) end

---@param t LuaValue
lurek.math.inOutQuart = function(t) end

---@param t LuaValue
lurek.math.inOutSine = function(t) end

---@param t LuaValue
lurek.math.inQuad = function(t) end

---@param t LuaValue
lurek.math.inQuart = function(t) end

---@param t LuaValue
lurek.math.inSine = function(t) end

---@param a LuaValue
---@param b LuaValue
---@param v LuaValue
lurek.math.inverseLerp = function(a, b, v) end

---@param pts LuaValue
lurek.math.isConvex = function(pts) end

---@param a LuaValue
---@param b LuaValue
---@param t LuaValue
lurek.math.lerp = function(a, b, t) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param x3 LuaValue
---@param y3 LuaValue
---@param x4 LuaValue
---@param y4 LuaValue
lurek.math.lineIntersect = function(x1, y1, x2, y2, x3, y3, x4, y4) end

---@param t LuaValue
lurek.math.linear = function(t) end

---@param c LuaValue
lurek.math.linearToGamma = function(c) end

---@param x LuaValue
---@param b? LuaValue
lurek.math.log = function(x, b) end

lurek.math.max = function() end

lurek.math.min = function() end

---@param points LuaValue
lurek.math.newBezierCurve = function(points) end

---@param x LuaValue
---@param y LuaValue
---@param radius LuaValue
lurek.math.newCircle = function(x, y, radius) end

---@param seed? LuaValue
lurek.math.newNoiseGenerator = function(seed) end

---@param seed? LuaValue
lurek.math.newRandomGenerator = function(seed) end

---@param width LuaValue
---@param height LuaValue
---@param padding? LuaValue
lurek.math.newRectPacker = function(width, height, padding) end

---@param cell_size LuaValue
lurek.math.newSpatialHash = function(cell_size) end

lurek.math.newTransform = function() end

---@param duration LuaValue
---@param easing_name? LuaValue
lurek.math.newTween = function(duration, easing_name) end

---@param t LuaValue
lurek.math.outBack = function(t) end

---@param t LuaValue
lurek.math.outBounce = function(t) end

---@param t LuaValue
lurek.math.outCubic = function(t) end

---@param t LuaValue
lurek.math.outElastic = function(t) end

---@param t LuaValue
lurek.math.outExpo = function(t) end

---@param t LuaValue
lurek.math.outQuad = function(t) end

---@param t LuaValue
lurek.math.outQuart = function(t) end

---@param t LuaValue
lurek.math.outSine = function(t) end

---@param x LuaValue
---@param y LuaValue
---@param seed? LuaValue
lurek.math.perlin2d = function(x, y, seed) end

---@param x LuaValue
---@param y LuaValue
---@param z LuaValue
---@param seed? LuaValue
lurek.math.perlin3d = function(x, y, z, seed) end

---@param pts LuaValue
---@param px LuaValue
---@param py LuaValue
lurek.math.pointInPolygon = function(pts, px, py) end

---@param pts LuaValue
lurek.math.polygonArea = function(pts) end

---@param pts LuaValue
lurek.math.polygonCentroid = function(pts) end

---@param pts LuaValue
---@param nx LuaValue
---@param ny LuaValue
---@param d LuaValue
lurek.math.polygonClip = function(pts, nx, ny, d) end

---@param a LuaValue
---@param b LuaValue
lurek.math.polygonDifference = function(a, b) end

---@param a LuaValue
---@param b LuaValue
lurek.math.polygonIntersection = function(a, b) end

---@param a LuaValue
---@param b LuaValue
lurek.math.polygonUnion = function(a, b) end

---@param x LuaValue
---@param y LuaValue
lurek.math.pow = function(x, y) end

---@param deg LuaValue
lurek.math.rad = function(deg) end

---@param a? LuaValue
---@param b? LuaValue
lurek.math.random = function(a, b) end

---@param lo LuaValue
---@param hi LuaValue
lurek.math.randomInt = function(lo, hi) end

---@param cx LuaValue
---@param cy LuaValue
---@param w LuaValue
---@param h LuaValue
lurek.math.rectFromCenter = function(cx, cy, w, h) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param w1 LuaValue
---@param h1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param w2 LuaValue
---@param h2 LuaValue
lurek.math.rectUnion = function(x1, y1, w1, h1, x2, y2, w2, h2) end

---@param v LuaValue
---@param in_min LuaValue
---@param in_max LuaValue
---@param out_min LuaValue
---@param out_max LuaValue
lurek.math.remap = function(v, in_min, in_max, out_min, out_max) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
lurek.math.rgbToHsl = function(r, g, b) end

---@param x LuaValue
lurek.math.round = function(x) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param x3 LuaValue
---@param y3 LuaValue
---@param x4 LuaValue
---@param y4 LuaValue
lurek.math.segmentIntersectsSegment = function(x1, y1, x2, y2, x3, y3, x4, y4) end

---@param v LuaValue
lurek.math.sign = function(v) end

---@param x LuaValue
---@param y LuaValue
---@param seed? LuaValue
lurek.math.simplex2d = function(x, y, seed) end

---@param x LuaValue
---@param y LuaValue
---@param z? LuaValue
lurek.math.simplexNoise = function(x, y, z) end

---@param x LuaValue
lurek.math.sin = function(x) end

---@param edge0 LuaValue
---@param edge1 LuaValue
---@param x LuaValue
lurek.math.smoothstep = function(edge0, edge1, x) end

---@param x LuaValue
lurek.math.sqrt = function(x) end

---@param x LuaValue
lurek.math.tan = function(x) end

---@param pts LuaValue
lurek.math.triangulate = function(pts) end

---@param x LuaValue
---@param y LuaValue
lurek.math.vec2 = function(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param z LuaValue
lurek.math.vec3 = function(x, y, z) end

---@param points LuaValue
lurek.math.voronoi = function(points) end

---@class lurek.minimap
lurek.minimap = {}

---@class LMinimap
LMinimap = {}

function LMinimap:addMarker() end

---@param name LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LMinimap:addObjectType(name, r, g, b, a) end

function LMinimap:addPing() end

---@param id LuaValue
function LMinimap:clearMarkerAnimation(id) end

---@param id LuaValue
function LMinimap:clearMarkerTexture(id) end

---@param type_idx LuaValue
function LMinimap:clearObjectTypeTexture(type_idx) end

function LMinimap:clearObjects() end

function LMinimap:clearOverlay() end

---@param id? LuaValue
function LMinimap:clearPath(id) end

function LMinimap:clearViewportRect() end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param color_tbl LuaValue
function LMinimap:drawLine(x1, y1, x2, y2, color_tbl) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
---@param color_tbl LuaValue
function LMinimap:drawRect(x, y, w, h, color_tbl) end

---@param pixel_size LuaValue
function LMinimap:drawToImage(pixel_size) end

function LMinimap:getCellCount() end

function LMinimap:getCenter() end

function LMinimap:getCenterX() end

function LMinimap:getCenterY() end

function LMinimap:getColorMode() end

function LMinimap:getDisplayHeight() end

function LMinimap:getDisplaySize() end

function LMinimap:getDisplayWidth() end

function LMinimap:getFogColor() end

---@param x LuaValue
---@param y LuaValue
function LMinimap:getFogLevel(x, y) end

function LMinimap:getGridHeight() end

function LMinimap:getGridSize() end

function LMinimap:getGridWidth() end

---@param sx LuaValue
---@param sy LuaValue
---@param mx LuaValue
---@param my LuaValue
function LMinimap:getHoverInfo(sx, sy, mx, my) end

function LMinimap:getLayer() end

function LMinimap:getLayerCount() end

---@param layer LuaValue
function LMinimap:getLayerData(layer) end

function LMinimap:getMarkerCount() end

---@param id LuaValue
function LMinimap:getMarkerDescription(id) end

function LMinimap:getObjectCount() end

function LMinimap:getObjectTypeCount() end

function LMinimap:getOverlayShapeCount() end

---@param owner LuaValue
function LMinimap:getOwnerColor(owner) end

function LMinimap:getPathCount() end

function LMinimap:getPingCount() end

---@param x LuaValue
---@param y LuaValue
function LMinimap:getTerrain(x, y) end

---@param terrain_type LuaValue
function LMinimap:getTerrainColor(terrain_type) end

---@param type_id LuaValue
function LMinimap:getTileDescription(type_id) end

function LMinimap:getViewportColor() end

function LMinimap:getViewportRect() end

function LMinimap:getZoom() end

---@param gx LuaValue
---@param gy LuaValue
---@param mx LuaValue
---@param my LuaValue
function LMinimap:gridToScreen(gx, gy, mx, my) end

---@param id LuaValue
function LMinimap:hasMarker(id) end

function LMinimap:isAntiAlias() end

function LMinimap:isClickable() end

function LMinimap:isFogEnabled() end

---@param type_idx LuaValue
function LMinimap:isObjectTypeVisible(type_idx) end

function LMinimap:isViewportVisible() end

---@param id LuaValue
function LMinimap:removeMarker(id) end

---@param id LuaValue
function LMinimap:removeObject(id) end

---@param x? LuaValue
---@param y? LuaValue
function LMinimap:render(x, y) end

---@param cx LuaValue
---@param cy LuaValue
---@param radius LuaValue
function LMinimap:revealRadius(cx, cy, radius) end

---@param sx LuaValue
---@param sy LuaValue
---@param mx LuaValue
---@param my LuaValue
function LMinimap:screenToGrid(sx, sy, mx, my) end

---@param enabled LuaValue
function LMinimap:setAntiAlias(enabled) end

---@param x LuaValue
---@param y LuaValue
function LMinimap:setCenter(x, y) end

---@param enabled LuaValue
function LMinimap:setClickable(enabled) end

---@param mode LuaValue
function LMinimap:setColorMode(mode) end

---@param w LuaValue
---@param h LuaValue
function LMinimap:setDisplaySize(w, h) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LMinimap:setFogColor(r, g, b, a) end

---@param data LuaValue
function LMinimap:setFogData(data) end

---@param enabled LuaValue
function LMinimap:setFogEnabled(enabled) end

---@param x LuaValue
---@param y LuaValue
---@param level LuaValue
function LMinimap:setFogLevel(x, y, level) end

---@param layer LuaValue
function LMinimap:setLayer(layer) end

---@param layer LuaValue
---@param data_tbl LuaValue
function LMinimap:setLayerData(layer, data_tbl) end

---@param id LuaValue
---@param anim_type LuaValue
---@param speed LuaValue
function LMinimap:setMarkerAnimation(id, anim_type, speed) end

---@param id LuaValue
---@param image_ud LuaValue
---@param width? LuaValue
---@param height? LuaValue
function LMinimap:setMarkerTexture(id, image_ud, width, height) end

---@param id LuaValue
---@param x LuaValue
---@param y LuaValue
---@param type_idx LuaValue
---@param owner? LuaValue
function LMinimap:setObject(id, x, y, type_idx, owner) end

function LMinimap:setObjectTypeTexture() end

---@param type_idx LuaValue
---@param visible LuaValue
function LMinimap:setObjectTypeVisible(type_idx, visible) end

---@param owner LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LMinimap:setOwnerColor(owner, r, g, b, a) end

---@param x LuaValue
---@param y LuaValue
---@param terrain_type LuaValue
function LMinimap:setTerrain(x, y, terrain_type) end

---@param terrain_type LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LMinimap:setTerrainColor(terrain_type, r, g, b, a) end

---@param data LuaValue
function LMinimap:setTerrainData(data) end

---@param type_id LuaValue
---@param desc LuaValue
function LMinimap:setTileDescription(type_id, desc) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LMinimap:setViewportColor(r, g, b, a) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LMinimap:setViewportRect(x, y, w, h) end

---@param visible LuaValue
function LMinimap:setViewportVisible(visible) end

---@param zoom LuaValue
function LMinimap:setZoom(zoom) end

---@param points_tbl LuaValue
---@param color_tbl LuaValue
function LMinimap:showPath(points_tbl, color_tbl) end

---@param camera_ud LuaValue
function LMinimap:trackCamera(camera_ud) end

function LMinimap:type() end

---@param name LuaValue
function LMinimap:typeOf(name) end

---@param dt LuaValue
function LMinimap:update(dt) end

---@param grid_w LuaValue
---@param grid_h LuaValue
---@param display_w? LuaValue
---@param display_h? LuaValue
lurek.minimap.newMinimap = function(grid_w, grid_h, display_w, display_h) end

---@class lurek.mods
lurek.mods = {}

---@class LContentRegistry
LContentRegistry = {}

---@param type_name LuaValue
---@param id LuaValue
function LContentRegistry:get(type_name, id) end

---@param type_name LuaValue
function LContentRegistry:getAll(type_name) end

function LContentRegistry:getTypes() end

---@param type_name LuaValue
---@param id LuaValue
---@param obj LuaValue
function LContentRegistry:register(type_name, id, obj) end

---@param type_name LuaValue
function LContentRegistry:registerType(type_name) end

function LContentRegistry:type() end

---@param name LuaValue
function LContentRegistry:typeOf(name) end

---@class LMod
LMod = {}

function LMod:getApiVersion() end

function LMod:getAuthor() end

function LMod:getCapabilities() end

function LMod:getConfig() end

function LMod:getConfigSchema() end

function LMod:getDependencies() end

function LMod:getDescription() end

---@param name LuaValue
function LMod:getHook(name) end

function LMod:getHookNames() end

function LMod:getId() end

function LMod:getName() end

function LMod:getPriority() end

function LMod:getVersion() end

---@param name LuaValue
function LMod:hasHook(name) end

function LMod:isEnabled() end

function LMod:isLoaded() end

function LMod:releaseRefs() end

---@param api_version LuaValue
function LMod:setApiVersion(api_version) end

---@param caps LuaValue
function LMod:setCapabilities(caps) end

---@param value LuaValue
function LMod:setConfig(value) end

---@param schema LuaValue
function LMod:setConfigSchema(schema) end

---@param enabled LuaValue
function LMod:setEnabled(enabled) end

---@param name LuaValue
---@param func LuaValue
function LMod:setHook(name, func) end

function LMod:type() end

---@param name LuaValue
function LMod:typeOf(name) end

---@class LModManager
LModManager = {}

function LModManager:clearLoadOrder() end

function LModManager:clearReloadQueue() end

function LModManager:getAllMods() end

function LModManager:getLoadOrder() end

function LModManager:getModCount() end

---@param mod_id LuaValue
function LModManager:getModPath(mod_id) end

---@param capability LuaValue
function LModManager:getModsByCapability(capability) end

function LModManager:getReloadQueue() end

function LModManager:hasCircularDependencies() end

---@param mod_id LuaValue
function LModManager:hasMod(mod_id) end

---@param mod_id LuaValue
function LModManager:markForReload(mod_id) end

function LModManager:processReloadQueue() end

---@param ud LuaValue
function LModManager:registerMod(ud) end

---@param path LuaValue
function LModManager:scanFolder(path) end

---@param order_table LuaValue
function LModManager:setLoadOrder(order_table) end

function LModManager:type() end

---@param name LuaValue
function LModManager:typeOf(name) end

---@param mod_id LuaValue
function LModManager:unregisterMod(mod_id) end

function LModManager:validateDependencies() end

---@param mod_ud LuaValue
---@param host_version LuaValue
lurek.mods.checkApiVersion = function(mod_ud, host_version) end

---@param info LuaValue
lurek.mods.newMod = function(info) end

lurek.mods.newModManager = function() end

lurek.mods.newRegistry = function() end

---@class lurek.network
lurek.network = {}

---@class LNetworkHost
LNetworkHost = {}

---@param channel_id LuaValue
---@param data LuaValue
---@param reliable? LuaValue
function LNetworkHost:broadcast(channel_id, data, reliable) end

---@param addr_str LuaValue
---@param channels? LuaValue
---@param data? LuaValue
function LNetworkHost:connect(addr_str, channels, data) end

function LNetworkHost:destroy() end

---@param peer_id LuaValue
---@param data? LuaValue
function LNetworkHost:disconnect(peer_id, data) end

---@param peer_id LuaValue
---@param data? LuaValue
function LNetworkHost:disconnectLater(peer_id, data) end

---@param peer_id LuaValue
---@param data? LuaValue
function LNetworkHost:disconnectNow(peer_id, data) end

function LNetworkHost:flush() end

function LNetworkHost:getAddress() end

function LNetworkHost:getBandwidthLimit() end

function LNetworkHost:getChannelLimit() end

function LNetworkHost:getConnectedPeerCount() end

function LNetworkHost:getConnectedPeerIds() end

---@param peer_id LuaValue
function LNetworkHost:getPeerAddress(peer_id) end

function LNetworkHost:getPeerLimit() end

---@param peer_id LuaValue
function LNetworkHost:getPeerState(peer_id) end

---@param peer_id LuaValue
function LNetworkHost:getPeerStats(peer_id) end

function LNetworkHost:getRole() end

---@param peer_id LuaValue
function LNetworkHost:getRoundTripTime(peer_id) end

function LNetworkHost:isClient() end

function LNetworkHost:isDestroyed() end

function LNetworkHost:isServer() end

---@param peer_id LuaValue
function LNetworkHost:ping(peer_id) end

---@param peer_id LuaValue
function LNetworkHost:resetPeer(peer_id) end

---@param peer_id LuaValue
---@param channel_id LuaValue
---@param data LuaValue
---@param reliable? LuaValue
function LNetworkHost:send(peer_id, channel_id, data, reliable) end

function LNetworkHost:service() end

---@param incoming? LuaValue
---@param outgoing? LuaValue
function LNetworkHost:setBandwidthLimit(incoming, outgoing) end

---@param limit LuaValue
function LNetworkHost:setChannelLimit(limit) end

function LNetworkHost:type() end

---@param name LuaValue
function LNetworkHost:typeOf(name) end

---@class LNetworkRuntime
LNetworkRuntime = {}

---@param url LuaValue
---@param headers? LuaValue
function LNetworkRuntime:httpGet(url, headers) end

---@param url LuaValue
---@param body LuaValue
---@param headers? LuaValue
function LNetworkRuntime:httpPost(url, body, headers) end

---@param opts LuaValue
function LNetworkRuntime:httpRequest(opts) end

function LNetworkRuntime:poll() end

function LNetworkRuntime:shutdown() end

---@param id LuaValue
function LNetworkRuntime:tcpClose(id) end

---@param addr LuaValue
function LNetworkRuntime:tcpConnect(addr) end

---@param id LuaValue
---@param data LuaValue
function LNetworkRuntime:tcpSend(id, data) end

function LNetworkRuntime:type() end

---@param name LuaValue
function LNetworkRuntime:typeOf(name) end

---@param id LuaValue
function LNetworkRuntime:wsClose(id) end

---@param url LuaValue
function LNetworkRuntime:wsConnect(url) end

---@param id LuaValue
---@param data LuaValue
function LNetworkRuntime:wsSend(id, data) end

---@param name LuaValue
---@param port LuaValue
---@param player_count? LuaValue
---@param max_players? LuaValue
lurek.network.createLobby = function(name, port, player_count, max_players) end

---@param name LuaValue
---@param host LuaValue
---@param max_players? LuaValue
lurek.network.createRoom = function(name, host, max_players) end

---@param timeout_ms? LuaValue
lurek.network.discoverLobbies = function(timeout_ms) end

---@param id LuaValue
lurek.network.joinRoom = function(id) end

---@param id LuaValue
lurek.network.leaveRoom = function(id) end

lurek.network.listRooms = function() end

---@param peer_id LuaValue
lurek.network.makePunchProbe = function(peer_id) end

---@param opts LuaValue
lurek.network.newClient = function(opts) end

---@param opts LuaValue
lurek.network.newHost = function(opts) end

---@param room_id LuaValue
---@param peer_id LuaValue
lurek.network.newRelayTicket = function(room_id, peer_id) end

lurek.network.newRuntime = function() end

---@param opts LuaValue
lurek.network.newServer = function(opts) end

---@param value LuaValue
lurek.network.pack = function(value) end

---@param payload LuaValue
lurek.network.parsePunchProbe = function(payload) end

---@param token LuaValue
lurek.network.parseRelayTicket = function(token) end

---@param snapshot LuaValue
---@param dt LuaValue
lurek.network.predictLinear = function(snapshot, dt) end

---@param pred LuaValue
---@param auth LuaValue
---@param alpha LuaValue
lurek.network.reconcileSnapshot = function(pred, auth, alpha) end

lurek.network.syncEntity = function() end

---@param data LuaValue
lurek.network.unpack = function(data) end

---@class lurek.parallax
lurek.parallax = {}

---@class LParallaxLayer
LParallaxLayer = {}

---@param effect_name LuaValue
---@param params? LuaValue
function LParallaxLayer:addEffectPass(effect_name, params) end

function LParallaxLayer:clearClamp() end

function LParallaxLayer:clearEffects() end

function LParallaxLayer:effectCount() end

function LParallaxLayer:getAutoscroll() end

function LParallaxLayer:getBlendMode() end

function LParallaxLayer:getDepth() end

function LParallaxLayer:getMotionStretch() end

function LParallaxLayer:getOffset() end

function LParallaxLayer:getOpacity() end

function LParallaxLayer:getScrollFactor() end

function LParallaxLayer:getTiling() end

function LParallaxLayer:getTint() end

function LParallaxLayer:getZ() end

function LParallaxLayer:isVisible() end

---@param cam_x LuaValue
---@param cam_y LuaValue
function LParallaxLayer:render(cam_x, cam_y) end

function LParallaxLayer:renderAuto() end

function LParallaxLayer:resetAutoscroll() end

---@param vx LuaValue
---@param vy LuaValue
function LParallaxLayer:setAutoscroll(vx, vy) end

---@param mode LuaValue
function LParallaxLayer:setBlendMode(mode) end

---@param min_x LuaValue
---@param min_y LuaValue
---@param max_x LuaValue
---@param max_y LuaValue
function LParallaxLayer:setClamp(min_x, min_y, max_x, max_y) end

---@param z LuaValue
function LParallaxLayer:setDepth(z) end

---@param enabled LuaValue
---@param strength LuaValue
---@param max_scale LuaValue
function LParallaxLayer:setMotionStretch(enabled, strength, max_scale) end

---@param x LuaValue
---@param y LuaValue
function LParallaxLayer:setOffset(x, y) end

---@param a LuaValue
function LParallaxLayer:setOpacity(a) end

---@param rx LuaValue
---@param ry LuaValue
function LParallaxLayer:setRepeat(rx, ry) end

---@param sx LuaValue
---@param sy LuaValue
function LParallaxLayer:setScale(sx, sy) end

---@param x LuaValue
---@param y LuaValue
function LParallaxLayer:setScrollFactor(x, y) end

---@param w LuaValue
---@param h LuaValue
function LParallaxLayer:setTileSize(w, h) end

---@param enabled LuaValue
function LParallaxLayer:setTiling(enabled) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LParallaxLayer:setTint(r, g, b, a) end

---@param v LuaValue
function LParallaxLayer:setVisible(v) end

---@param z LuaValue
function LParallaxLayer:setZ(z) end

function LParallaxLayer:type() end

---@param dt LuaValue
function LParallaxLayer:update(dt) end

---@class LParallaxSet
LParallaxSet = {}

---@param layer LuaValue
function LParallaxSet:addLayer(layer) end

---@param index LuaValue
function LParallaxSet:getLayerZAt(index) end

function LParallaxSet:getName() end

function LParallaxSet:isVisible() end

function LParallaxSet:layerCount() end

---@param index LuaValue
function LParallaxSet:removeLayerAt(index) end

---@param cam_x LuaValue
---@param cam_y LuaValue
function LParallaxSet:render(cam_x, cam_y) end

function LParallaxSet:renderAuto() end

---@param name LuaValue
function LParallaxSet:setName(name) end

---@param v LuaValue
function LParallaxSet:setVisible(v) end

function LParallaxSet:sortByZ() end

function LParallaxSet:type() end

---@param dt LuaValue
function LParallaxSet:update(dt) end

---@param opts LuaValue
lurek.parallax.newLayer = function(opts) end

---@param preset_name LuaValue
---@param img_ud LuaValue
lurek.parallax.newPresetLayer = function(preset_name, img_ud) end

---@param name LuaValue
lurek.parallax.newSet = function(name) end

---@class lurek.particle
lurek.particle = {}

---@class LParticleSystem
LParticleSystem = {}

---@param x LuaValue
---@param y LuaValue
---@param strength LuaValue
---@param radius LuaValue
function LParticleSystem:addAttractor(x, y, strength, radius) end

---@param config_tbl LuaValue
---@param burst_count? LuaValue
function LParticleSystem:addSubEmitter(config_tbl, burst_count) end

---@param config_tbl LuaValue
function LParticleSystem:addSubSystem(config_tbl) end

function LParticleSystem:clearAttractors() end

function LParticleSystem:clearBounds() end

function LParticleSystem:clearCollidesWithPhysics() end

function LParticleSystem:clone() end

function LParticleSystem:count() end

---@param w LuaValue
---@param h LuaValue
function LParticleSystem:drawToImage(w, h) end

---@param count LuaValue
function LParticleSystem:emit(count) end

function LParticleSystem:getAttractorCount() end

function LParticleSystem:getBufferSize() end

function LParticleSystem:getColors() end

function LParticleSystem:getCount() end

function LParticleSystem:getDirection() end

function LParticleSystem:getEmissionArea() end

function LParticleSystem:getEmissionRate() end

function LParticleSystem:getEmitterLifetime() end

function LParticleSystem:getFlipbook() end

function LParticleSystem:getGravity() end

function LParticleSystem:getInsertMode() end

function LParticleSystem:getLinearAcceleration() end

function LParticleSystem:getLinearDamping() end

function LParticleSystem:getOffset() end

function LParticleSystem:getParticleLifetime() end

function LParticleSystem:getPosition() end

function LParticleSystem:getRadialAcceleration() end

function LParticleSystem:getRotation() end

function LParticleSystem:getShape() end

function LParticleSystem:getSizeVariation() end

function LParticleSystem:getSizes() end

function LParticleSystem:getSpeed() end

function LParticleSystem:getSpin() end

function LParticleSystem:getSpinVariation() end

function LParticleSystem:getSpread() end

function LParticleSystem:getTangentialAcceleration() end

function LParticleSystem:hasCollidesWithPhysics() end

function LParticleSystem:hasRelativeRotation() end

function LParticleSystem:isActive() end

function LParticleSystem:isEmpty() end

function LParticleSystem:isFull() end

function LParticleSystem:isPaused() end

function LParticleSystem:isStopped() end

---@param x LuaValue
---@param y LuaValue
function LParticleSystem:moveTo(x, y) end

function LParticleSystem:pause() end

function LParticleSystem:release() end

---@param ox? LuaValue
---@param oy? LuaValue
function LParticleSystem:render(ox, oy) end

function LParticleSystem:reset() end

function LParticleSystem:resume() end

---@param xmin LuaValue
---@param xmax LuaValue
---@param ymin LuaValue
---@param ymax LuaValue
---@param restitution LuaValue
function LParticleSystem:setBounds(xmin, xmax, ymin, ymax, restitution) end

---@param n LuaValue
function LParticleSystem:setBufferSize(n) end

---@param world_ud LuaValue
---@param probe_radius? LuaValue
---@param restitution? LuaValue
function LParticleSystem:setCollidesWithPhysics(world_ud, probe_radius, restitution) end

---@param ... LuaValue
function LParticleSystem:setColors(...) end

---@param cb LuaValue
function LParticleSystem:setCustomEmissionShape(cb) end

---@param dir LuaValue
function LParticleSystem:setDirection(dir) end

---@param dist LuaValue
---@param w LuaValue
---@param h LuaValue
---@param angle? LuaValue
---@param dir_rel? LuaValue
function LParticleSystem:setEmissionArea(dist, w, h, angle, dir_rel) end

---@param rate LuaValue
function LParticleSystem:setEmissionRate(rate) end

---@param t LuaValue
function LParticleSystem:setEmitterLifetime(t) end

---@param cols LuaValue
---@param rows LuaValue
---@param fps LuaValue
function LParticleSystem:setFlipbook(cols, rows, fps) end

---@param gx LuaValue
---@param gy LuaValue
function LParticleSystem:setGravity(gx, gy) end

---@param mode LuaValue
function LParticleSystem:setInsertMode(mode) end

---@param xmin LuaValue
---@param ymin LuaValue
---@param xmax LuaValue
---@param ymax LuaValue
function LParticleSystem:setLinearAcceleration(xmin, ymin, xmax, ymax) end

---@param min LuaValue
---@param max LuaValue
function LParticleSystem:setLinearDamping(min, max) end

---@param ox LuaValue
---@param oy LuaValue
function LParticleSystem:setOffset(ox, oy) end

---@param cb LuaValue
function LParticleSystem:setOnDeathBatch(cb) end

---@param min LuaValue
---@param max LuaValue
function LParticleSystem:setParticleLifetime(min, max) end

---@param x LuaValue
---@param y LuaValue
function LParticleSystem:setPosition(x, y) end

---@param min LuaValue
---@param max LuaValue
function LParticleSystem:setRadialAcceleration(min, max) end

---@param v LuaValue
function LParticleSystem:setRelativeRotation(v) end

---@param min LuaValue
---@param max LuaValue
function LParticleSystem:setRotation(min, max) end

---@param shape LuaValue
function LParticleSystem:setShape(shape) end

---@param v LuaValue
function LParticleSystem:setSizeVariation(v) end

---@param ... LuaValue
function LParticleSystem:setSizes(...) end

---@param min LuaValue
---@param max LuaValue
function LParticleSystem:setSpeed(min, max) end

---@param min LuaValue
---@param max LuaValue
function LParticleSystem:setSpin(min, max) end

---@param v LuaValue
function LParticleSystem:setSpinVariation(v) end

---@param spread LuaValue
function LParticleSystem:setSpread(spread) end

---@param min LuaValue
---@param max LuaValue
function LParticleSystem:setTangentialAcceleration(min, max) end

function LParticleSystem:start() end

function LParticleSystem:stop() end

function LParticleSystem:subSystemCount() end

---@param w LuaValue
---@param h LuaValue
function LParticleSystem:toImage(w, h) end

function LParticleSystem:type() end

---@param name LuaValue
function LParticleSystem:typeOf(name) end

---@param dt LuaValue
function LParticleSystem:update(dt) end

---@param seconds LuaValue
function LParticleSystem:warmUp(seconds) end

---@class LTrail
LTrail = {}

function LTrail:clear() end

---@param w LuaValue
---@param h LuaValue
function LTrail:drawToImage(w, h) end

function LTrail:getLifetime() end

function LTrail:getPointCount() end

function LTrail:getWidth() end

---@param x LuaValue
---@param y LuaValue
function LTrail:pushPoint(x, y) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LTrail:setHeadColor(r, g, b, a) end

---@param lifetime LuaValue
function LTrail:setLifetime(lifetime) end

---@param distance LuaValue
function LTrail:setMinDistance(distance) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LTrail:setTailColor(r, g, b, a) end

---@param start LuaValue
---@param end_? LuaValue
function LTrail:setWidth(start, end_) end

function LTrail:type() end

---@param name LuaValue
function LTrail:typeOf(name) end

---@param dt LuaValue
function LTrail:update(dt) end

---@param path LuaValue
lurek.particle.fromTOML = function(path) end

---@param name LuaValue
lurek.particle.newPreset = function(name) end

---@param config? LuaValue
lurek.particle.newSystem = function(config) end

---@param lifetime LuaValue
---@param start_width LuaValue
lurek.particle.newTrail = function(lifetime, start_width) end

-- Flat forwarding: lurek.particle.METHOD(ps,...) == ps:METHOD(...)
lurek.particle.addAttractor = LParticleSystem.addAttractor
lurek.particle.addSubEmitter = LParticleSystem.addSubEmitter
lurek.particle.addSubSystem = LParticleSystem.addSubSystem
lurek.particle.clearAttractors = LParticleSystem.clearAttractors
lurek.particle.clearBounds = LParticleSystem.clearBounds
lurek.particle.clearCollidesWithPhysics = LParticleSystem.clearCollidesWithPhysics
lurek.particle.clone = LParticleSystem.clone
lurek.particle.count = LParticleSystem.count
lurek.particle.drawToImage = LParticleSystem.drawToImage
lurek.particle.emit = LParticleSystem.emit
lurek.particle.getAttractorCount = LParticleSystem.getAttractorCount
lurek.particle.getBufferSize = LParticleSystem.getBufferSize
lurek.particle.getColors = LParticleSystem.getColors
lurek.particle.getCount = LParticleSystem.getCount
lurek.particle.getDirection = LParticleSystem.getDirection
lurek.particle.getEmissionArea = LParticleSystem.getEmissionArea
lurek.particle.getEmissionRate = LParticleSystem.getEmissionRate
lurek.particle.getEmitterLifetime = LParticleSystem.getEmitterLifetime
lurek.particle.getFlipbook = LParticleSystem.getFlipbook
lurek.particle.getGravity = LParticleSystem.getGravity
lurek.particle.getInsertMode = LParticleSystem.getInsertMode
lurek.particle.getLinearAcceleration = LParticleSystem.getLinearAcceleration
lurek.particle.getLinearDamping = LParticleSystem.getLinearDamping
lurek.particle.getOffset = LParticleSystem.getOffset
lurek.particle.getParticleLifetime = LParticleSystem.getParticleLifetime
lurek.particle.getPosition = LParticleSystem.getPosition
lurek.particle.getRadialAcceleration = LParticleSystem.getRadialAcceleration
lurek.particle.getRotation = LParticleSystem.getRotation
lurek.particle.getShape = LParticleSystem.getShape
lurek.particle.getSizeVariation = LParticleSystem.getSizeVariation
lurek.particle.getSizes = LParticleSystem.getSizes
lurek.particle.getSpeed = LParticleSystem.getSpeed
lurek.particle.getSpin = LParticleSystem.getSpin
lurek.particle.getSpinVariation = LParticleSystem.getSpinVariation
lurek.particle.getSpread = LParticleSystem.getSpread
lurek.particle.getTangentialAcceleration = LParticleSystem.getTangentialAcceleration
lurek.particle.hasCollidesWithPhysics = LParticleSystem.hasCollidesWithPhysics
lurek.particle.hasRelativeRotation = LParticleSystem.hasRelativeRotation
lurek.particle.isActive = LParticleSystem.isActive
lurek.particle.isEmpty = LParticleSystem.isEmpty
lurek.particle.isFull = LParticleSystem.isFull
lurek.particle.isPaused = LParticleSystem.isPaused
lurek.particle.isStopped = LParticleSystem.isStopped
lurek.particle.moveTo = LParticleSystem.moveTo
lurek.particle.pause = LParticleSystem.pause
lurek.particle.release = LParticleSystem.release
lurek.particle.render = LParticleSystem.render
lurek.particle.reset = LParticleSystem.reset
lurek.particle.resume = LParticleSystem.resume
lurek.particle.setBounds = LParticleSystem.setBounds
lurek.particle.setBufferSize = LParticleSystem.setBufferSize
lurek.particle.setCollidesWithPhysics = LParticleSystem.setCollidesWithPhysics
lurek.particle.setColors = LParticleSystem.setColors
lurek.particle.setCustomEmissionShape = LParticleSystem.setCustomEmissionShape
lurek.particle.setDirection = LParticleSystem.setDirection
lurek.particle.setEmissionArea = LParticleSystem.setEmissionArea
lurek.particle.setEmissionRate = LParticleSystem.setEmissionRate
lurek.particle.setEmitterLifetime = LParticleSystem.setEmitterLifetime
lurek.particle.setFlipbook = LParticleSystem.setFlipbook
lurek.particle.setGravity = LParticleSystem.setGravity
lurek.particle.setInsertMode = LParticleSystem.setInsertMode
lurek.particle.setLinearAcceleration = LParticleSystem.setLinearAcceleration
lurek.particle.setLinearDamping = LParticleSystem.setLinearDamping
lurek.particle.setOffset = LParticleSystem.setOffset
lurek.particle.setOnDeathBatch = LParticleSystem.setOnDeathBatch
lurek.particle.setParticleLifetime = LParticleSystem.setParticleLifetime
lurek.particle.setPosition = LParticleSystem.setPosition
lurek.particle.setRadialAcceleration = LParticleSystem.setRadialAcceleration
lurek.particle.setRelativeRotation = LParticleSystem.setRelativeRotation
lurek.particle.setRotation = LParticleSystem.setRotation
lurek.particle.setShape = LParticleSystem.setShape
lurek.particle.setSizeVariation = LParticleSystem.setSizeVariation
lurek.particle.setSizes = LParticleSystem.setSizes
lurek.particle.setSpeed = LParticleSystem.setSpeed
lurek.particle.setSpin = LParticleSystem.setSpin
lurek.particle.setSpinVariation = LParticleSystem.setSpinVariation
lurek.particle.setSpread = LParticleSystem.setSpread
lurek.particle.setTangentialAcceleration = LParticleSystem.setTangentialAcceleration
lurek.particle.start = LParticleSystem.start
lurek.particle.stop = LParticleSystem.stop
lurek.particle.subSystemCount = LParticleSystem.subSystemCount
lurek.particle.toImage = LParticleSystem.toImage
lurek.particle.type = LParticleSystem.type
lurek.particle.typeOf = LParticleSystem.typeOf
lurek.particle.update = LParticleSystem.update
lurek.particle.warmUp = LParticleSystem.warmUp

---@class lurek.pathfind
lurek.pathfind = {}

---@class LAIFlowField
LAIFlowField = {}

---@param x LuaValue
---@param y LuaValue
function LAIFlowField:getDirection(x, y) end

---@param x LuaValue
---@param y LuaValue
function LAIFlowField:getDistance(x, y) end

function LAIFlowField:getGoal() end

function LAIFlowField:getHeight() end

function LAIFlowField:getWidth() end

function LAIFlowField:hasGoal() end

---@param x LuaValue
---@param y LuaValue
function LAIFlowField:setGoal(x, y) end

function LAIFlowField:type() end

---@param name LuaValue
function LAIFlowField:typeOf(name) end

---@class LFlowField
LFlowField = {}

---@param tx LuaValue
---@param ty LuaValue
---@param unit_size? LuaValue
function LFlowField:calculate(tx, ty, unit_size) end

---@param targets LuaValue
---@param unit_size? LuaValue
function LFlowField:calculateMulti(targets, unit_size) end

---@param x LuaValue
---@param y LuaValue
function LFlowField:getCostToTarget(x, y) end

---@param x LuaValue
---@param y LuaValue
function LFlowField:getDirection(x, y) end

---@param x LuaValue
---@param y LuaValue
function LFlowField:getDirectionAngle(x, y) end

function LFlowField:getTargets() end

function LFlowField:isCalculated() end

---@param wx LuaValue
---@param wy LuaValue
---@param speed LuaValue
---@param tw LuaValue
---@param th LuaValue
function LFlowField:steer(wx, wy, speed, tw, th) end

function LFlowField:type() end

---@param name LuaValue
function LFlowField:typeOf(name) end

---@class LHexGrid
LHexGrid = {}

---@param c1 LuaValue
---@param r1 LuaValue
---@param c2 LuaValue
---@param r2 LuaValue
function LHexGrid:distance(c1, r1, c2, r2) end

---@param col LuaValue
---@param row LuaValue
---@param max_range LuaValue
function LHexGrid:fieldOfView(col, row, max_range) end

---@param fc LuaValue
---@param fr LuaValue
---@param tc LuaValue
---@param tr LuaValue
function LHexGrid:findPath(fc, fr, tc, tr) end

---@param col LuaValue
---@param row LuaValue
function LHexGrid:isBlocked(col, row) end

---@param fc LuaValue
---@param fr LuaValue
---@param tc LuaValue
---@param tr LuaValue
function LHexGrid:lineOfSight(fc, fr, tc, tr) end

---@param col LuaValue
---@param row LuaValue
---@param budget LuaValue
function LHexGrid:rangeOfMovement(col, row, budget) end

---@param col LuaValue
---@param row LuaValue
---@param blocked LuaValue
function LHexGrid:setBlocked(col, row, blocked) end

---@param col LuaValue
---@param row LuaValue
---@param cost LuaValue
function LHexGrid:setCost(col, row, cost) end

function LHexGrid:type() end

---@param name LuaValue
function LHexGrid:typeOf(name) end

---@class LJpsGrid
LJpsGrid = {}

---@param fx LuaValue
---@param fy LuaValue
---@param tx LuaValue
---@param ty LuaValue
function LJpsGrid:findPath(fx, fy, tx, ty) end

---@param x LuaValue
---@param y LuaValue
function LJpsGrid:isBlocked(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param blocked LuaValue
function LJpsGrid:setBlocked(x, y, blocked) end

function LJpsGrid:type() end

---@param name LuaValue
function LJpsGrid:typeOf(name) end

---@class LNavGrid
LNavGrid = {}

function LNavGrid:clearDirty() end

---@param cost LuaValue
function LNavGrid:fill(cost) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
---@param cost LuaValue
function LNavGrid:fillRect(x, y, w, h, cost) end

function LNavGrid:getChunkSize() end

---@param x LuaValue
---@param y LuaValue
function LNavGrid:getCost(x, y) end

function LNavGrid:getDiagonalMode() end

function LNavGrid:getDimensions() end

function LNavGrid:getHeight() end

function LNavGrid:getWidth() end

---@param x LuaValue
---@param y LuaValue
function LNavGrid:isBlocked(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param unit_size? LuaValue
function LNavGrid:isWalkable(x, y, unit_size) end

---@param data LuaValue
function LNavGrid:loadFromString(data) end

function LNavGrid:rebuildAbstract() end

function LNavGrid:saveToString() end

---@param x LuaValue
---@param y LuaValue
---@param blocked LuaValue
function LNavGrid:setBlocked(x, y, blocked) end

---@param size LuaValue
function LNavGrid:setChunkSize(size) end

---@param x LuaValue
---@param y LuaValue
---@param cost LuaValue
function LNavGrid:setCost(x, y, cost) end

---@param mode LuaValue
function LNavGrid:setDiagonalMode(mode) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LNavGrid:setDirty(x, y, w, h) end

function LNavGrid:type() end

---@param name LuaValue
function LNavGrid:typeOf(name) end

---@class LNavMesh
LNavMesh = {}

---@param vertices LuaValue
function LNavMesh:addPolygon(vertices) end

---@param a LuaValue
---@param b LuaValue
---@param bidirectional? LuaValue
function LNavMesh:connectPolygons(a, b, bidirectional) end

---@param sx LuaValue
---@param sy LuaValue
---@param gx LuaValue
---@param gy LuaValue
function LNavMesh:findPath(sx, sy, gx, gy) end

function LNavMesh:getPolygonCount() end

function LNavMesh:type() end

---@param name LuaValue
function LNavMesh:typeOf(name) end

---@class LPathGrid
LPathGrid = {}

---@param sx LuaValue
---@param sy LuaValue
---@param gx LuaValue
---@param gy LuaValue
function LPathGrid:findPath(sx, sy, gx, gy) end

---@param sx LuaValue
---@param sy LuaValue
---@param gx LuaValue
---@param gy LuaValue
function LPathGrid:findPathSmoothed(sx, sy, gx, gy) end

function LPathGrid:getCellSize() end

---@param x LuaValue
---@param y LuaValue
function LPathGrid:getCost(x, y) end

function LPathGrid:getHeight() end

function LPathGrid:getWidth() end

---@param x LuaValue
---@param y LuaValue
function LPathGrid:isWalkable(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param cost LuaValue
function LPathGrid:setCost(x, y, cost) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
function LPathGrid:setWalkable(x, y, w) end

function LPathGrid:type() end

---@param name LuaValue
function LPathGrid:typeOf(name) end

---@class LUnitPathfinder
LUnitPathfinder = {}

function LUnitPathfinder:clearCache() end

---@param x LuaValue
---@param y LuaValue
---@param max_radius LuaValue
---@param unit_size? LuaValue
function LUnitPathfinder:findNearestWalkable(x, y, max_radius, unit_size) end

function LUnitPathfinder:findPartialPath() end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param unit_size? LuaValue
function LUnitPathfinder:findPath(x1, y1, x2, y2, unit_size) end

function LUnitPathfinder:findPathBidirectional() end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param unit_size? LuaValue
function LUnitPathfinder:findPathSmooth(x1, y1, x2, y2, unit_size) end

function LUnitPathfinder:getCacheSize() end

---@param path LuaValue
function LUnitPathfinder:getPathCost(path) end

---@param path LuaValue
function LUnitPathfinder:getPathLength(path) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
function LUnitPathfinder:heuristicDistance(x1, y1, x2, y2) end

function LUnitPathfinder:isCacheEnabled() end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param unit_size? LuaValue
function LUnitPathfinder:isReachable(x1, y1, x2, y2, unit_size) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param unit_size? LuaValue
function LUnitPathfinder:lineOfSight(x1, y1, x2, y2, unit_size) end

---@param enabled LuaValue
function LUnitPathfinder:setCacheEnabled(enabled) end

---@param n LuaValue
function LUnitPathfinder:setCacheMaxSize(n) end

function LUnitPathfinder:type() end

---@param name LuaValue
function LUnitPathfinder:typeOf(name) end

lurek.pathfind.getThreadCount = function() end

---@param grid_ud LuaValue
lurek.pathfind.newFlowField = function(grid_ud) end

---@param width LuaValue
---@param height LuaValue
---@param layout_str? LuaValue
lurek.pathfind.newHexGrid = function(width, height, layout_str) end

---@param width LuaValue
---@param height LuaValue
lurek.pathfind.newJpsGrid = function(width, height) end

---@param width LuaValue
---@param height LuaValue
lurek.pathfind.newNavGrid = function(width, height) end

---@param tm_ud LuaValue
---@param layer_index LuaValue
---@param blocked_table LuaValue
lurek.pathfind.newNavGridFromTileMap = function(tm_ud, layer_index, blocked_table) end

lurek.pathfind.newNavMesh = function() end

---@param grid_ud LuaValue
lurek.pathfind.newPathFlowField = function(grid_ud) end

---@param w LuaValue
---@param h LuaValue
---@param cell_size LuaValue
lurek.pathfind.newPathGrid = function(w, h, cell_size) end

---@param grid_ud LuaValue
lurek.pathfind.newPathfinder = function(grid_ud) end

---@param opts LuaValue
lurek.pathfind.rangeMap = function(opts) end

---@param count LuaValue
lurek.pathfind.setThreadCount = function(count) end

---@class lurek.patterns
lurek.patterns = {}

---@class LBehaviorTree
LBehaviorTree = {}

---@param parent_id LuaValue
---@param child_id LuaValue
function LBehaviorTree:addChild(parent_id, child_id) end

---@param label? LuaValue
function LBehaviorTree:addInverter(label) end

---@param name LuaValue
---@param label? LuaValue
function LBehaviorTree:addLeaf(name, label) end

---@param min_success LuaValue
---@param label? LuaValue
function LBehaviorTree:addParallel(min_success, label) end

---@param count LuaValue
---@param label? LuaValue
function LBehaviorTree:addRepeat(count, label) end

---@param label? LuaValue
function LBehaviorTree:addSelector(label) end

---@param label? LuaValue
function LBehaviorTree:addSequence(label) end

function LBehaviorTree:clearAll() end

function LBehaviorTree:nodeCount() end

function LBehaviorTree:resetState() end

---@param name LuaValue
---@param callback LuaValue
function LBehaviorTree:setLeaf(name, callback) end

---@param id LuaValue
function LBehaviorTree:setRoot(id) end

function LBehaviorTree:tick() end

---@class LBlackboard
LBlackboard = {}

---@param key LuaValue
function LBlackboard:clear(key) end

function LBlackboard:clearAll() end

---@param key LuaValue
function LBlackboard:get(key) end

function LBlackboard:getRevision() end

---@param key LuaValue
function LBlackboard:has(key) end

function LBlackboard:keys() end

---@param key LuaValue
---@param value LuaValue
function LBlackboard:set(key, value) end

function LBlackboard:snapshot() end

---@param id LuaValue
function LBlackboard:unwatch(id) end

---@param key LuaValue
---@param callback LuaValue
function LBlackboard:watch(key, callback) end

---@class LCommandStack
LCommandStack = {}

function LCommandStack:canRedo() end

function LCommandStack:canUndo() end

function LCommandStack:clearAll() end

---@param name LuaValue
---@param exec_fn LuaValue
---@param undo_fn? LuaValue
function LCommandStack:execute(name, exec_fn, undo_fn) end

function LCommandStack:getCurrentName() end

function LCommandStack:getHistorySize() end

function LCommandStack:redo() end

function LCommandStack:undo() end

---@class LDebounce
LDebounce = {}

function LDebounce:cancel() end

function LDebounce:getFireCount() end

function LDebounce:isPending() end

---@param f LuaValue
function LDebounce:onFire(f) end

function LDebounce:trigger() end

---@param dt LuaValue
function LDebounce:update(dt) end

---@class LEventBus
LEventBus = {}

---@param event LuaValue
function LEventBus:clear(event) end

function LEventBus:clearAll() end

---@param ... LuaValue
function LEventBus:emit(...) end

function LEventBus:getEvents() end

---@param event LuaValue
function LEventBus:getListenerCount(event) end

---@param id LuaValue
function LEventBus:off(id) end

---@param event LuaValue
---@param callback LuaValue
---@param priority? LuaValue
function LEventBus:on(event, callback, priority) end

---@class LFactory
LFactory = {}

---@param alias LuaValue
---@param canonical LuaValue
function LFactory:alias(alias, canonical) end

function LFactory:clearAll() end

---@param ... LuaValue
function LFactory:create(...) end

function LFactory:getTypes() end

---@param type_name LuaValue
function LFactory:has(type_name) end

---@param type_name LuaValue
---@param ctor LuaValue
function LFactory:register(type_name, ctor) end

---@param type_name LuaValue
function LFactory:remove(type_name) end

---@class LFunnel
LFunnel = {}

function LFunnel:discard() end

function LFunnel:flush() end

function LFunnel:getFlushCount() end

---@param f LuaValue
function LFunnel:onFlush(f) end

function LFunnel:pendingCount() end

---@param tag LuaValue
---@param value? LuaValue
function LFunnel:push(tag, value) end

---@param dt LuaValue
function LFunnel:update(dt) end

---@class LGraph
LGraph = {}

---@param from LuaValue
---@param to LuaValue
---@param weight? LuaValue
---@param label? LuaValue
function LGraph:addEdge(from, to, weight, label) end

---@param label? LuaValue
---@param value? LuaValue
function LGraph:addNode(label, value) end

---@param start LuaValue
function LGraph:bfs(start) end

function LGraph:clearAll() end

---@param start LuaValue
function LGraph:dfs(start) end

function LGraph:edgeCount() end

---@param id LuaValue
function LGraph:getNodeValue(id) end

---@param id LuaValue
function LGraph:hasNode(id) end

---@param from LuaValue
---@param to LuaValue
function LGraph:isConnected(from, to) end

---@param id LuaValue
function LGraph:neighbors(id) end

function LGraph:nodeCount() end

---@param id LuaValue
function LGraph:removeEdge(id) end

---@param id LuaValue
function LGraph:removeNode(id) end

---@class LList
LList = {}

---@param value LuaValue
function LList:add(value) end

function LList:clear() end

---@param value LuaValue
function LList:contains(value) end

---@param index LuaValue
function LList:get(index) end

---@param value LuaValue
function LList:indexOf(value) end

---@param index LuaValue
---@param value LuaValue
function LList:insert(index, value) end

function LList:isEmpty() end

function LList:len() end

function LList:pop() end

---@param value LuaValue
function LList:push(value) end

---@param index LuaValue
function LList:remove(index) end

function LList:reverse() end

---@param index LuaValue
---@param value LuaValue
function LList:set(index, value) end

function LList:shift() end

function LList:toArray() end

---@param value LuaValue
function LList:unshift(value) end

---@class LMap
LMap = {}

function LMap:clear() end

function LMap:entries() end

---@param key LuaValue
function LMap:get(key) end

---@param key LuaValue
function LMap:has(key) end

function LMap:isEmpty() end

function LMap:keys() end

function LMap:len() end

---@param other LuaValue
function LMap:merge(other) end

---@param key LuaValue
function LMap:remove(key) end

---@param key LuaValue
---@param value LuaValue
function LMap:set(key, value) end

function LMap:values() end

---@class LMediator
LMediator = {}

---@param ... LuaValue
function LMediator:broadcast(...) end

function LMediator:channels() end

function LMediator:clear() end

---@param channel LuaValue
function LMediator:handlerCount(channel) end

---@param channel LuaValue
---@param id LuaValue
function LMediator:off(channel, id) end

---@param channel LuaValue
---@param callback LuaValue
function LMediator:on(channel, callback) end

---@param channel LuaValue
function LMediator:removeChannel(channel) end

---@param ... LuaValue
function LMediator:send(...) end

---@class LObjectPool
LObjectPool = {}

function LObjectPool:acquire() end

---@param value LuaValue
function LObjectPool:add(value) end

function LObjectPool:clearAll() end

function LObjectPool:getActiveCount() end

function LObjectPool:getAvailableCount() end

function LObjectPool:getTotalCount() end

---@param value LuaValue
function LObjectPool:release(value) end

---@class LObserver
LObserver = {}

---@param key LuaValue
function LObserver:get(key) end

function LObserver:getCount() end

---@param key LuaValue
---@param new_val LuaValue
function LObserver:set(key, new_val) end

---@param key LuaValue
---@param callback LuaValue
---@param once? LuaValue
function LObserver:subscribe(key, callback, once) end

---@param id LuaValue
function LObserver:unsubscribe(id) end

---@class LPriorityQueue
LPriorityQueue = {}

function LPriorityQueue:clearAll() end

function LPriorityQueue:isEmpty() end

function LPriorityQueue:len() end

function LPriorityQueue:peek() end

function LPriorityQueue:pop() end

---@param priority LuaValue
---@param value LuaValue
---@param label? LuaValue
function LPriorityQueue:push(priority, value, label) end

---@class LQueue
LQueue = {}

function LQueue:back() end

function LQueue:clear() end

function LQueue:dequeue() end

function LQueue:dequeueBack() end

---@param value LuaValue
function LQueue:enqueue(value) end

---@param value LuaValue
function LQueue:enqueueFront(value) end

function LQueue:front() end

---@param index LuaValue
---@param value LuaValue
function LQueue:insertAt(index, value) end

function LQueue:isEmpty() end

function LQueue:isFull() end

function LQueue:len() end

---@param index LuaValue
function LQueue:peekAt(index) end

---@param index LuaValue
function LQueue:removeAt(index) end

function LQueue:toArray() end

---@class LRelationshipManager
LRelationshipManager = {}

---@param a LuaValue
---@param b LuaValue
---@param delta LuaValue
function LRelationshipManager:adjustValue(a, b, delta) end

---@param name LuaValue
---@param levels LuaValue
---@param default_level? LuaValue
function LRelationshipManager:defineType(name, levels, default_level) end

---@param a LuaValue
---@param b LuaValue
---@param type_name LuaValue
function LRelationshipManager:getLevel(a, b, type_name) end

---@param a LuaValue
---@param b LuaValue
function LRelationshipManager:getValue(a, b) end

function LRelationshipManager:pairCount() end

---@param a LuaValue
---@param b LuaValue
function LRelationshipManager:removePair(a, b) end

---@param name LuaValue
function LRelationshipManager:removeType(name) end

---@param a LuaValue
---@param b LuaValue
---@param type_name LuaValue
---@param level LuaValue
function LRelationshipManager:setLevel(a, b, type_name, level) end

---@param a LuaValue
---@param b LuaValue
---@param value LuaValue
function LRelationshipManager:setValue(a, b, value) end

function LRelationshipManager:typeNames() end

---@class LRing
LRing = {}

function LRing:average() end

function LRing:clear() end

function LRing:isFull() end

function LRing:latest() end

function LRing:len() end

---@param value LuaValue
---@param tag? LuaValue
function LRing:push(value, tag) end

function LRing:sum() end

function LRing:toArray() end

---@class LServiceLocator
LServiceLocator = {}

function LServiceLocator:clearAll() end

function LServiceLocator:getServices() end

---@param name LuaValue
function LServiceLocator:has(name) end

---@param name LuaValue
function LServiceLocator:locate(name) end

---@param name LuaValue
---@param value LuaValue
function LServiceLocator:provide(name, value) end

---@param name LuaValue
function LServiceLocator:remove(name) end

---@class LSet
LSet = {}

---@param key LuaValue
function LSet:add(key) end

function LSet:clear() end

---@param key LuaValue
function LSet:has(key) end

---@param other LuaValue
function LSet:intersection(other) end

function LSet:isEmpty() end

function LSet:len() end

---@param key LuaValue
function LSet:remove(key) end

function LSet:toArray() end

---@param other LuaValue
function LSet:union(other) end

---@class LSimpleState
LSimpleState = {}

---@param name LuaValue
---@param callbacks? LuaValue
function LSimpleState:addState(name, callbacks) end

function LSimpleState:clearAll() end

function LSimpleState:getCurrent() end

function LSimpleState:getStates() end

---@param name LuaValue
function LSimpleState:hasState(name) end

---@param name LuaValue
function LSimpleState:transitionTo(name) end

---@param dt LuaValue
function LSimpleState:update(dt) end

---@class LStack
LStack = {}

function LStack:clear() end

---@param index LuaValue
---@param value LuaValue
function LStack:insertAt(index, value) end

function LStack:isEmpty() end

function LStack:isFull() end

function LStack:len() end

---@param from LuaValue
---@param to LuaValue
function LStack:moveWithin(from, to) end

function LStack:peek() end

---@param index LuaValue
function LStack:peekAt(index) end

function LStack:peekBottom() end

function LStack:pop() end

function LStack:popBottom() end

---@param count LuaValue
function LStack:popMany(count) end

---@param value LuaValue
function LStack:push(value) end

---@param value LuaValue
function LStack:pushBottom(value) end

---@param index LuaValue
function LStack:removeAt(index) end

function LStack:toArray() end

---@class LStrategy
LStrategy = {}

function LStrategy:clear() end

---@param ... LuaValue
function LStrategy:execute(...) end

function LStrategy:getCurrent() end

---@param name LuaValue
function LStrategy:has(name) end

function LStrategy:names() end

---@param name LuaValue
---@param callback LuaValue
function LStrategy:register(name, callback) end

---@param name LuaValue
function LStrategy:remove(name) end

---@param name LuaValue
function LStrategy:set(name) end

---@class LThrottle
LThrottle = {}

function LThrottle:getFireCount() end

function LThrottle:getProgress() end

---@param f LuaValue
function LThrottle:onFire(f) end

function LThrottle:reset() end

---@param v LuaValue
function LThrottle:setEnabled(v) end

---@param dt LuaValue
function LThrottle:update(dt) end

---@class LWeightedRandom
LWeightedRandom = {}

---@param weight LuaValue
---@param value LuaValue
---@param label? LuaValue
function LWeightedRandom:add(weight, value, label) end

function LWeightedRandom:clearAll() end

function LWeightedRandom:getRevision() end

function LWeightedRandom:isEmpty() end

function LWeightedRandom:len() end

---@param sample LuaValue
function LWeightedRandom:pick(sample) end

---@param count LuaValue
---@param samples LuaValue
function LWeightedRandom:pickN(count, samples) end

---@param id LuaValue
function LWeightedRandom:remove(id) end

---@param id LuaValue
---@param weight LuaValue
function LWeightedRandom:setWeight(id, weight) end

function LWeightedRandom:totalWeight() end

lurek.patterns.newBehaviorTree = function() end

---@param name? LuaValue
lurek.patterns.newBlackboard = function(name) end

---@param max_size? LuaValue
lurek.patterns.newCommandStack = function(max_size) end

---@param wait LuaValue
lurek.patterns.newDebounce = function(wait) end

---@param name? LuaValue
lurek.patterns.newEventBus = function(name) end

lurek.patterns.newFactory = function() end

---@param window LuaValue
---@param max_entries? LuaValue
---@param name? LuaValue
lurek.patterns.newFunnel = function(window, max_entries, name) end

---@param undirected? LuaValue
lurek.patterns.newGraph = function(undirected) end

lurek.patterns.newList = function() end

lurek.patterns.newMap = function() end

lurek.patterns.newMediator = function() end

lurek.patterns.newObjectPool = function() end

---@param name? LuaValue
lurek.patterns.newObserver = function(name) end

---@param name? LuaValue
lurek.patterns.newPriorityQueue = function(name) end

---@param capacity? LuaValue
lurek.patterns.newQueue = function(capacity) end

lurek.patterns.newRelationshipManager = function() end

---@param capacity LuaValue
---@param name? LuaValue
lurek.patterns.newRing = function(capacity, name) end

lurek.patterns.newServiceLocator = function() end

lurek.patterns.newSet = function() end

lurek.patterns.newSimpleState = function() end

---@param capacity? LuaValue
lurek.patterns.newStack = function(capacity) end

lurek.patterns.newStrategy = function() end

---@param interval LuaValue
lurek.patterns.newThrottle = function(interval) end

lurek.patterns.newWeightedRandom = function() end

---@class lurek.physics
---@field CELL_AIR number  empty air cell (0)
---@field CELL_SAND number  sand cell (1)
---@field CELL_WATER number  water cell (2)
---@field CELL_ROCK number  rock cell (3)
---@field CELL_FIRE number  fire cell (4)
---@field CELL_GAS number  gas cell (5)
lurek.physics = {}

---@class LBody
LBody = {}

---@param impulse LuaValue
function LBody:applyAngularImpulse(impulse) end

---@param fx LuaValue
---@param fy LuaValue
function LBody:applyForce(fx, fy) end

---@param fx LuaValue
---@param fy LuaValue
---@param px LuaValue
---@param py LuaValue
function LBody:applyForceAtPoint(fx, fy, px, py) end

---@param ix LuaValue
---@param iy LuaValue
function LBody:applyImpulse(ix, iy) end

---@param torque LuaValue
function LBody:applyTorque(torque) end

function LBody:destroy() end

function LBody:getAngle() end

function LBody:getAngularDamping() end

function LBody:getAngularVelocity() end

function LBody:getFriction() end

function LBody:getGravityScale() end

function LBody:getHeight() end

function LBody:getId() end

function LBody:getLayer() end

function LBody:getLinearDamping() end

function LBody:getMask() end

function LBody:getMass() end

function LBody:getPosition() end

function LBody:getRestitution() end

function LBody:getType() end

function LBody:getVelocity() end

function LBody:getWidth() end

function LBody:getX() end

function LBody:getY() end

function LBody:isBullet() end

function LBody:isFixedRotation() end

function LBody:isSleeping() end

function LBody:isSleepingAllowed() end

---@param angle LuaValue
function LBody:setAngle(angle) end

---@param damping LuaValue
function LBody:setAngularDamping(damping) end

---@param omega LuaValue
function LBody:setAngularVelocity(omega) end

---@param bullet LuaValue
function LBody:setBullet(bullet) end

---@param fixed LuaValue
function LBody:setFixedRotation(fixed) end

---@param friction LuaValue
function LBody:setFriction(friction) end

---@param scale LuaValue
function LBody:setGravityScale(scale) end

---@param layer LuaValue
function LBody:setLayer(layer) end

---@param damping LuaValue
function LBody:setLinearDamping(damping) end

---@param mask LuaValue
function LBody:setMask(mask) end

---@param mass LuaValue
function LBody:setMass(mass) end

---@param x LuaValue
---@param y LuaValue
function LBody:setPosition(x, y) end

---@param restitution LuaValue
function LBody:setRestitution(restitution) end

---@param allowed LuaValue
function LBody:setSleepingAllowed(allowed) end

---@param bt LuaValue
function LBody:setType(bt) end

---@param vx LuaValue
---@param vy LuaValue
function LBody:setVelocity(vx, vy) end

function LBody:sleep() end

function LBody:type() end

---@param name LuaValue
function LBody:typeOf(name) end

function LBody:wakeUp() end

---@class LCellular
LCellular = {}

---@param t LuaValue
function LCellular:countCells(t) end

---@param cx LuaValue
---@param cy LuaValue
---@param r LuaValue
---@param t LuaValue
function LCellular:fillCircle(cx, cy, r, t) end

---@param cx0 LuaValue
---@param cy0 LuaValue
---@param cw LuaValue
---@param ch LuaValue
---@param t LuaValue
function LCellular:fillRect(cx0, cy0, cw, ch, t) end

---@param t LuaValue
function LCellular:findCells(t) end

---@param cx LuaValue
---@param cy LuaValue
function LCellular:getCell(cx, cy) end

---@param data LuaValue
function LCellular:loadFromBytes(data) end

---@param cx LuaValue
---@param cy LuaValue
---@param t LuaValue
function LCellular:setCell(cx, cy, t) end

function LCellular:step() end

---@param n LuaValue
function LCellular:stepN(n) end

function LCellular:toBytes() end

function LCellular:toImageData() end

---@param cx0 LuaValue
---@param cy0 LuaValue
---@param cw LuaValue
---@param ch LuaValue
function LCellular:toImageDataRegion(cx0, cy0, cw, ch) end

function LCellular:type() end

---@param name LuaValue
function LCellular:typeOf(name) end

---@class LPhysicsShape
LPhysicsShape = {}

function LPhysicsShape:destroy() end

function LPhysicsShape:getBoundingBox() end

function LPhysicsShape:getRadius() end

function LPhysicsShape:getType() end

---@param density LuaValue
function LPhysicsShape:setDensity(density) end

---@param friction LuaValue
function LPhysicsShape:setFriction(friction) end

---@param restitution LuaValue
function LPhysicsShape:setRestitution(restitution) end

---@param sensor LuaValue
function LPhysicsShape:setSensor(sensor) end

function LPhysicsShape:type() end

---@param name LuaValue
function LPhysicsShape:typeOf(name) end

---@class LTerrain
LTerrain = {}

function LTerrain:collapseColumns() end

---@param solid LuaValue
function LTerrain:fillAll(solid) end

---@param wx LuaValue
---@param wy LuaValue
---@param radius LuaValue
---@param solid LuaValue
function LTerrain:fillCircle(wx, wy, radius, solid) end

---@param wx LuaValue
---@param wy LuaValue
---@param w LuaValue
---@param h LuaValue
---@param solid LuaValue
function LTerrain:fillRect(wx, wy, w, h, solid) end

function LTerrain:flush() end

---@param cx LuaValue
---@param cy LuaValue
function LTerrain:getCell(cx, cy) end

function LTerrain:isDirty() end

---@param data LuaValue
function LTerrain:loadFromBytes(data) end

---@param cx LuaValue
---@param cy LuaValue
---@param solid LuaValue
function LTerrain:setCell(cx, cy, solid) end

function LTerrain:solidPositions() end

---@param positions LuaValue
---@param mass LuaValue
---@param restitution LuaValue
function LTerrain:spawnDebris(positions, mass, restitution) end

function LTerrain:toBytes() end

---@param sr LuaValue
---@param sg LuaValue
---@param sb LuaValue
---@param er LuaValue
---@param eg LuaValue
---@param eb LuaValue
function LTerrain:toImageData(sr, sg, sb, er, eg, eb) end

function LTerrain:type() end

---@param name LuaValue
function LTerrain:typeOf(name) end

---@class LWorld
LWorld = {}

---@param a LuaValue
---@param b LuaValue
---@param ax1 LuaValue
---@param ay1 LuaValue
---@param ax2 LuaValue
---@param ay2 LuaValue
---@param len LuaValue
function LWorld:addDistanceJoint(a, b, ax1, ay1, ax2, ay2, len) end

function LWorld:addFixture() end

---@param a LuaValue
---@param b LuaValue
---@param ax LuaValue
---@param ay LuaValue
---@param max_f LuaValue
---@param max_t LuaValue
function LWorld:addFrictionJoint(a, b, ax, ay, max_f, max_t) end

---@param a LuaValue
---@param b LuaValue
---@param ax LuaValue
---@param ay LuaValue
function LWorld:addGearJoint(a, b, ax, ay) end

---@param a LuaValue
---@param b LuaValue
---@param factor LuaValue
function LWorld:addMotorJoint(a, b, factor) end

---@param body_id LuaValue
---@param tx LuaValue
---@param ty LuaValue
---@param max_f LuaValue
function LWorld:addMouseJoint(body_id, tx, ty, max_f) end

---@param a LuaValue
---@param b LuaValue
---@param ax LuaValue
---@param ay LuaValue
---@param axis_x LuaValue
---@param axis_y LuaValue
function LWorld:addPrismaticJoint(a, b, ax, ay, axis_x, axis_y) end

---@param a LuaValue
---@param b LuaValue
---@param ax LuaValue
---@param ay LuaValue
function LWorld:addPulleyJoint(a, b, ax, ay) end

---@param a LuaValue
---@param b LuaValue
---@param ax LuaValue
---@param ay LuaValue
function LWorld:addRevoluteJoint(a, b, ax, ay) end

---@param a LuaValue
---@param b LuaValue
---@param ax1 LuaValue
---@param ay1 LuaValue
---@param ax2 LuaValue
---@param ay2 LuaValue
---@param max LuaValue
function LWorld:addRopeJoint(a, b, ax1, ay1, ax2, ay2, max) end

---@param a LuaValue
---@param b LuaValue
---@param ax LuaValue
---@param ay LuaValue
function LWorld:addWeldJoint(a, b, ax, ay) end

---@param a LuaValue
---@param b LuaValue
---@param ax LuaValue
---@param ay LuaValue
---@param axis_x LuaValue
---@param axis_y LuaValue
function LWorld:addWheelJoint(a, b, ax, ay, axis_x, axis_y) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LWorld:addZone(x, y, w, h) end

function LWorld:clear() end

function LWorld:clearBeginContact() end

---@param id LuaValue
function LWorld:clearBodyData(id) end

---@param id LuaValue
function LWorld:clearBodyOneWay(id) end

function LWorld:clearEndContact() end

---@param id LuaValue
function LWorld:destroyBody(id) end

---@param jid LuaValue
function LWorld:destroyJoint(jid) end

function LWorld:drawDebug() end

---@param body_id LuaValue
function LWorld:fixtureCount(body_id) end

function LWorld:getBeginContactEvents() end

---@param x LuaValue
---@param y LuaValue
function LWorld:getBodyAtPoint(x, y) end

---@param id LuaValue
function LWorld:getBodyCCD(id) end

---@param body_id LuaValue
function LWorld:getBodyContacts(body_id) end

function LWorld:getBodyCount() end

---@param id LuaValue
function LWorld:getBodyData(id) end

function LWorld:getBodyIds() end

---@param id LuaValue
function LWorld:getBodyOneWay(id) end

---@param id LuaValue
function LWorld:getBodyType(id) end

function LWorld:getCollisionEvents() end

function LWorld:getContacts() end

function LWorld:getEndContactEvents() end

function LWorld:getGravity() end

---@param jid LuaValue
function LWorld:getJointBodies(jid) end

---@param jid LuaValue
function LWorld:getJointBreakForce(jid) end

function LWorld:getJointIds() end

---@param jid LuaValue
function LWorld:getJointLimits(jid) end

---@param jid LuaValue
function LWorld:getJointMotorSpeed(jid) end

---@param jid LuaValue
function LWorld:getJointType(jid) end

function LWorld:getMeter() end

function LWorld:getSolverIterations() end

function LWorld:getZoneEvents() end

---@param id LuaValue
function LWorld:isBodySleeping(id) end

function LWorld:jointCount() end

---@param specs LuaValue
function LWorld:newBodies(specs) end

---@param x LuaValue
---@param y LuaValue
---@param bt LuaValue
function LWorld:newBody(x, y, bt) end

---@param x LuaValue
---@param y LuaValue
---@param tbl LuaValue
---@param closed LuaValue
---@param bt LuaValue
function LWorld:newChainBody(x, y, tbl, closed, bt) end

---@param x LuaValue
---@param y LuaValue
---@param radius LuaValue
---@param bt LuaValue
function LWorld:newCircleBody(x, y, radius, bt) end

---@param x LuaValue
---@param y LuaValue
---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param bt LuaValue
function LWorld:newEdgeBody(x, y, x1, y1, x2, y2, bt) end

---@param x LuaValue
---@param y LuaValue
---@param tbl LuaValue
---@param bt LuaValue
function LWorld:newPolygonBody(x, y, tbl, bt) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LWorld:queryAABB(x, y, w, h) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
function LWorld:raycast(x1, y1, x2, y2) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param dx LuaValue
---@param dy LuaValue
---@param max_dist LuaValue
function LWorld:raycastAll(x1, y1, dx, dy, max_dist) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param dx LuaValue
---@param dy LuaValue
---@param max_dist LuaValue
function LWorld:raycastClosest(x1, y1, dx, dy, max_dist) end

---@param f LuaValue
function LWorld:setBeginContact(f) end

---@param id LuaValue
---@param enabled LuaValue
function LWorld:setBodyCCD(id, enabled) end

---@param id LuaValue
---@param value LuaValue
function LWorld:setBodyData(id, value) end

---@param id LuaValue
---@param nx LuaValue
---@param ny LuaValue
function LWorld:setBodyOneWay(id, nx, ny) end

---@param id LuaValue
---@param bt LuaValue
function LWorld:setBodyType(id, bt) end

---@param f LuaValue
function LWorld:setEndContact(f) end

---@param body_id LuaValue
---@param fix_idx LuaValue
---@param friction LuaValue
function LWorld:setFixtureFriction(body_id, fix_idx, friction) end

---@param body_id LuaValue
---@param fix_idx LuaValue
---@param restitution LuaValue
function LWorld:setFixtureRestitution(body_id, fix_idx, restitution) end

---@param body_id LuaValue
---@param fix_idx LuaValue
---@param sensor LuaValue
function LWorld:setFixtureSensor(body_id, fix_idx, sensor) end

---@param gx LuaValue
---@param gy LuaValue
function LWorld:setGravity(gx, gy) end

---@param jid LuaValue
---@param f LuaValue
function LWorld:setJointBreakForce(jid, f) end

---@param jid LuaValue
---@param lower LuaValue
---@param upper LuaValue
function LWorld:setJointLimits(jid, lower, upper) end

---@param jid LuaValue
---@param enabled LuaValue
function LWorld:setJointLimitsEnabled(jid, enabled) end

---@param jid LuaValue
---@param speed LuaValue
function LWorld:setJointMotorSpeed(jid, speed) end

---@param ppm LuaValue
function LWorld:setMeter(ppm) end

---@param jid LuaValue
---@param x LuaValue
---@param y LuaValue
function LWorld:setMouseJointTarget(jid, x, y) end

---@param n LuaValue
function LWorld:setSolverIterations(n) end

---@param id LuaValue
function LWorld:sleepBody(id) end

---@param dt LuaValue
function LWorld:step(dt) end

---@param accum LuaValue
---@param step_dt LuaValue
---@param max_steps LuaValue
function LWorld:stepFixed(accum, step_dt, max_steps) end

---@param px LuaValue
function LWorld:toPhysics(px) end

---@param m LuaValue
function LWorld:toPixels(m) end

function LWorld:type() end

---@param name LuaValue
function LWorld:typeOf(name) end

---@param id LuaValue
function LWorld:wakeUpBody(id) end

---@class LZone
LZone = {}

function LZone:destroy() end

function LZone:getId() end

---@param value? LuaValue
function LZone:setAngularDampingOverride(value) end

---@param cx LuaValue
---@param cy LuaValue
---@param radius LuaValue
function LZone:setCircle(cx, cy, radius) end

---@param enabled LuaValue
function LZone:setEnabled(enabled) end

---@param gx LuaValue
---@param gy LuaValue
function LZone:setGravityDirectional(gx, gy) end

---@param cx LuaValue
---@param cy LuaValue
---@param strength LuaValue
function LZone:setGravityPoint(cx, cy, strength) end

---@param cx LuaValue
---@param cy LuaValue
---@param strength LuaValue
function LZone:setGravityRepulsor(cx, cy, strength) end

function LZone:setGravityZero() end

---@param mask LuaValue
function LZone:setLayerMask(mask) end

---@param value? LuaValue
function LZone:setLinearDampingOverride(value) end

---@param priority LuaValue
function LZone:setPriority(priority) end

function LZone:type() end

---@param name LuaValue
function LZone:typeOf(name) end

---@param body_ud LuaValue
---@param shape_ud LuaValue
lurek.physics.attachShape = function(body_ud, shape_ud) end

---@param enable LuaValue
lurek.physics.debugDraw = function(enable) end

---@param world_ud LuaValue
lurek.physics.destroyWorld = function(world_ud) end

---@param world_ud LuaValue
---@param config_val LuaValue
lurek.physics.drawDebugGpu = function(world_ud, config_val) end

---@param world_ud LuaValue
---@param body_ud LuaValue
lurek.physics.getBody = function(world_ud, body_ud) end

---@param world_ud LuaValue
lurek.physics.getCollisions = function(world_ud) end

---@param world_ud LuaValue
---@param body_ud LuaValue
lurek.physics.isSleepingAllowed = function(world_ud, body_ud) end

---@param world_ud LuaValue
---@param x LuaValue
---@param y LuaValue
---@param bt LuaValue
lurek.physics.newBody = function(world_ud, x, y, bt) end

---@param width LuaValue
---@param height LuaValue
lurek.physics.newCellular = function(width, height) end

---@param closed LuaValue
---@param coords LuaValue
lurek.physics.newChainShape = function(closed, coords) end

---@param r LuaValue
lurek.physics.newCircleShape = function(r) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
lurek.physics.newEdgeShape = function(x1, y1, x2, y2) end

lurek.physics.newPolygonShape = function() end

---@param w LuaValue
---@param h LuaValue
lurek.physics.newRectangleShape = function(w, h) end

---@param width LuaValue
---@param height LuaValue
---@param cell_size LuaValue
---@param world_ud LuaValue
lurek.physics.newTerrain = function(width, height, cell_size, world_ud) end

---@param gx LuaValue
---@param gy LuaValue
lurek.physics.newWorld = function(gx, gy) end

---@param world_ud LuaValue
---@param body_ud LuaValue
---@param vx LuaValue
---@param vy LuaValue
lurek.physics.setBodyVelocity = function(world_ud, body_ud, vx, vy) end

---@param world_ud LuaValue
---@param body_ud LuaValue
---@param allowed LuaValue
lurek.physics.setSleepingAllowed = function(world_ud, body_ud, allowed) end

---@param world_ud LuaValue
---@param dt LuaValue
lurek.physics.step = function(world_ud, dt) end

---@param ax LuaValue
---@param ay LuaValue
---@param aw LuaValue
---@param ah LuaValue
---@param bx LuaValue
---@param by LuaValue
---@param bw LuaValue
---@param bh LuaValue
lurek.physics.testAABB = function(ax, ay, aw, ah, bx, by, bw, bh) end

---@param cx LuaValue
---@param cy LuaValue
---@param cr LuaValue
---@param ax LuaValue
---@param ay LuaValue
---@param aw LuaValue
---@param ah LuaValue
lurek.physics.testCircleAABB = function(cx, cy, cr, ax, ay, aw, ah) end

---@param ax LuaValue
---@param ay LuaValue
---@param ar LuaValue
---@param bx LuaValue
---@param by LuaValue
---@param br LuaValue
lurek.physics.testCircles = function(ax, ay, ar, bx, by, br) end

---@param px LuaValue
---@param py LuaValue
---@param ax LuaValue
---@param ay LuaValue
---@param aw LuaValue
---@param ah LuaValue
lurek.physics.testPoint = function(px, py, ax, ay, aw, ah) end

---@class lurek.pipeline
lurek.pipeline = {}

---@class LPipeline
LPipeline = {}

function LPipeline:addBranch() end

---@param name LuaValue
---@param deps_tbl LuaValue
---@param cb LuaValue
---@param cond LuaValue
function LPipeline:addConditional(name, deps_tbl, cb, cond) end

---@param step_ud LuaValue
function LPipeline:addStep(step_ud) end

---@param sub_ud LuaValue
---@param alias LuaValue
---@param deps_tbl? LuaValue
function LPipeline:addSubPipeline(sub_ud, alias, deps_tbl) end

function LPipeline:cancel() end

function LPipeline:clear() end

function LPipeline:getContext() end

function LPipeline:getErrorMode() end

function LPipeline:getExecutionOrder() end

function LPipeline:getName() end

function LPipeline:getParallelGroups() end

function LPipeline:getResult() end

---@param name LuaValue
function LPipeline:getStep(name) end

function LPipeline:getStepCount() end

function LPipeline:getSteps() end

---@param tag LuaValue
function LPipeline:getStepsByTag(tag) end

function LPipeline:isComplete() end

function LPipeline:isRunning() end

---@param cb LuaValue
function LPipeline:onEvent(cb) end

---@param cb LuaValue
function LPipeline:onProgress(cb) end

---@param name LuaValue
function LPipeline:removeStep(name) end

function LPipeline:reset() end

---@param context? LuaValue
function LPipeline:run(context) end

---@param context? LuaValue
function LPipeline:runAsync(context) end

---@param mode LuaValue
function LPipeline:setErrorMode(mode) end

---@param name LuaValue
function LPipeline:setName(name) end

---@param cb? LuaValue
function LPipeline:setOnComplete(cb) end

---@param cb? LuaValue
function LPipeline:setOnStepComplete(cb) end

---@param cb? LuaValue
function LPipeline:setOnStepError(cb) end

function LPipeline:toAscii() end

function LPipeline:toTable() end

function LPipeline:type() end

---@param name LuaValue
function LPipeline:typeOf(name) end

---@param dt LuaValue
function LPipeline:update(dt) end

function LPipeline:validate() end

---@class LPipelineStep
LPipelineStep = {}

---@param dep LuaValue
function LPipelineStep:dependsOn(dep) end

function LPipelineStep:getAttempt() end

---@param key LuaValue
function LPipelineStep:getData(key) end

function LPipelineStep:getDelay() end

function LPipelineStep:getDependencies() end

function LPipelineStep:getDependencyCount() end

function LPipelineStep:getDuration() end

function LPipelineStep:getError() end

function LPipelineStep:getName() end

function LPipelineStep:getRetryCount() end

function LPipelineStep:getStatus() end

function LPipelineStep:getTag() end

function LPipelineStep:getTimeout() end

function LPipelineStep:isAsync() end

function LPipelineStep:isOptional() end

---@param enabled LuaValue
function LPipelineStep:setAsync(enabled) end

---@param cb LuaValue
function LPipelineStep:setCallback(cb) end

---@param cond? LuaValue
function LPipelineStep:setCondition(cond) end

---@param key LuaValue
---@param value LuaValue
function LPipelineStep:setData(key, value) end

---@param seconds LuaValue
function LPipelineStep:setDelay(seconds) end

---@param cb? LuaValue
function LPipelineStep:setOnError(cb) end

---@param optional LuaValue
function LPipelineStep:setOptional(optional) end

---@param count LuaValue
function LPipelineStep:setRetryCount(count) end

---@param seconds LuaValue
function LPipelineStep:setRetryDelay(seconds) end

---@param tag LuaValue
function LPipelineStep:setTag(tag) end

---@param seconds LuaValue
function LPipelineStep:setTimeout(seconds) end

function LPipelineStep:type() end

---@param name LuaValue
function LPipelineStep:typeOf(name) end

---@param def LuaValue
lurek.pipeline.fromTable = function(def) end

---@param name? LuaValue
lurek.pipeline.newPipeline = function(name) end

---@param name LuaValue
---@param callback? LuaValue
lurek.pipeline.newStep = function(name, callback) end

---@class lurek.procgen
lurek.procgen = {}

---@class BiomeClassifier
BiomeClassifier = {}

---@param h LuaValue
---@param m LuaValue
---@param t LuaValue
function BiomeClassifier:classify(h, m, t) end

---@param width LuaValue
---@param height LuaValue
---@param ht LuaValue
---@param mt LuaValue
---@param tt? LuaValue
function BiomeClassifier:classifyMap(width, height, ht, mt, tt) end

function BiomeClassifier:type() end

---@param name LuaValue
function BiomeClassifier:typeOf(name) end

---@param name LuaValue
lurek.procgen.biomeColor = function(name) end

---@param opts? LuaValue
lurek.procgen.bspDungeon = function(opts) end

---@param opts? LuaValue
---@param prefabs_tbl LuaValue
lurek.procgen.bspDungeonWithPrefabs = function(opts, prefabs_tbl) end

---@param w LuaValue
---@param h LuaValue
---@param opts? LuaValue
lurek.procgen.cellularAutomata = function(w, h, opts) end

lurek.procgen.floodFill = function() end

lurek.procgen.generateName = function() end

lurek.procgen.generateNames = function() end

---@param opts? LuaValue
lurek.procgen.heightmap = function(opts) end

---@param width LuaValue
---@param height LuaValue
---@param cells_tbl LuaValue
---@param floor_value? LuaValue
lurek.procgen.heightmapFromCellular = function(width, height, cells_tbl, floor_value) end

---@param opts LuaValue
lurek.procgen.lsystem = function(opts) end

---@param opts LuaValue
---@param angle_deg? LuaValue
---@param step? LuaValue
lurek.procgen.lsystemSegments = function(opts, angle_deg, step) end

---@param opts? LuaValue
lurek.procgen.newBiomeClassifier = function(opts) end

---@param width LuaValue
---@param height LuaValue
---@param opts? LuaValue
lurek.procgen.noiseMap = function(width, height, opts) end

---@param width LuaValue
---@param height LuaValue
---@param opts? LuaValue
lurek.procgen.noiseMapParallel = function(width, height, opts) end

---@param width LuaValue
---@param height LuaValue
---@param opts? LuaValue
lurek.procgen.noiseMapParallelSeeded = function(width, height, opts) end

---@param x LuaValue
---@param y LuaValue
---@param px LuaValue
---@param py LuaValue
lurek.procgen.perlinNoise = function(x, y, px, py) end

---@param w LuaValue
---@param h LuaValue
---@param min_dist LuaValue
---@param max_attempts? LuaValue
---@param seed? LuaValue
lurek.procgen.poissonDisk = function(w, h, min_dist, max_attempts, seed) end

---@param opts? LuaValue
lurek.procgen.roomsDungeon = function(opts) end

---@param opts? LuaValue
---@param prefabs_tbl LuaValue
---@param stamp_value? LuaValue
lurek.procgen.roomsDungeonWithPrefabs = function(opts, prefabs_tbl, stamp_value) end

---@param x LuaValue
---@param y LuaValue
lurek.procgen.simplex2d = function(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param z LuaValue
lurek.procgen.simplex3d = function(x, y, z) end

---@param w LuaValue
---@param h LuaValue
---@param pts_tbl LuaValue
---@param opts_tbl? LuaValue
lurek.procgen.voronoi = function(w, h, pts_tbl, opts_tbl) end

---@param opts LuaValue
lurek.procgen.wfcGenerate = function(opts) end

---@param width LuaValue
---@param height LuaValue
---@param region_count LuaValue
---@param seed? LuaValue
lurek.procgen.worldGraph = function(width, height, region_count, seed) end

---@class lurek.province
lurek.province = {}

---@class LProvinceRegistry
LProvinceRegistry = {}

function LProvinceRegistry:adjacencies() end

function LProvinceRegistry:borderSegments() end

---@param screen_w LuaValue
---@param screen_h LuaValue
---@param pixel_size? LuaValue
function LProvinceRegistry:fitCamera(screen_w, screen_h, pixel_size) end

---@param x LuaValue
---@param y LuaValue
function LProvinceRegistry:getAt(x, y) end

---@param a LuaValue
---@param b LuaValue
function LProvinceRegistry:getBorderClass(a, b) end

---@param revision LuaValue
function LProvinceRegistry:getChangesSince(revision) end

function LProvinceRegistry:getHeight() end

function LProvinceRegistry:getName() end

---@param id LuaValue
function LProvinceRegistry:getNeighbors(id) end

---@param id LuaValue
function LProvinceRegistry:getProvince(id) end

function LProvinceRegistry:getRevision() end

function LProvinceRegistry:getWidth() end

---@param opts LuaValue
function LProvinceRegistry:importMetadataFromFiles(opts) end

function LProvinceRegistry:provinceCount() end

function LProvinceRegistry:provinceIds() end

function LProvinceRegistry:provinceSpans() end

---@param opts? LuaValue
function LProvinceRegistry:render(opts) end

function LProvinceRegistry:screenToMap() end

function LProvinceRegistry:screenToProvince() end

---@param id LuaValue
---@param key LuaValue
---@param value LuaValue
function LProvinceRegistry:setAttr(id, key, value) end

---@param a LuaValue
---@param b LuaValue
---@param class LuaValue
function LProvinceRegistry:setBorderClass(a, b, class) end

---@param id LuaValue
---@param border_style LuaValue
function LProvinceRegistry:setBorderStyle(id, border_style) end

---@param id LuaValue
---@param x LuaValue
---@param y LuaValue
function LProvinceRegistry:setCapital(id, x, y) end

---@param id LuaValue
---@param fog_state LuaValue
function LProvinceRegistry:setFogState(id, fog_state) end

---@param id LuaValue
---@param ax LuaValue
---@param ay LuaValue
---@param bx LuaValue
---@param by LuaValue
function LProvinceRegistry:setLabelLine(id, ax, ay, bx, by) end

---@param id LuaValue
---@param text LuaValue
function LProvinceRegistry:setLabelText(id, text) end

---@param id LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LProvinceRegistry:setPoliticalColor(id, r, g, b, a) end

---@param id LuaValue
---@param terrain_type LuaValue
function LProvinceRegistry:setTerrainType(id, terrain_type) end

---@param id LuaValue
---@param visibility_state LuaValue
function LProvinceRegistry:setVisibilityState(id, visibility_state) end

function LProvinceRegistry:type() end

---@param name LuaValue
function LProvinceRegistry:typeOf(name) end

---@param name LuaValue
lurek.province.exists = function(name) end

---@param name LuaValue
lurek.province.get = function(name) end

lurek.province.getActive = function() end

---@param name LuaValue
---@param png_path LuaValue
lurek.province.newFromPng = function(name, png_path) end

---@param name LuaValue
lurek.province.remove = function(name) end

---@param input_png LuaValue
---@param output_png LuaValue
---@param opts? LuaValue
lurek.province.sanitizeMarkedPng = function(input_png, output_png, opts) end

---@param name LuaValue
lurek.province.setActive = function(name) end

lurek.province.zoomCameraAt = function() end

---@class lurek.raycaster
lurek.raycaster = {}

---@class LDoorManager
LDoorManager = {}

---@param x LuaValue
---@param y LuaValue
---@param dir_str LuaValue
---@param speed LuaValue
function LDoorManager:addDoor(x, y, dir_str, speed) end

---@param index LuaValue
function LDoorManager:closeDoor(index) end

function LDoorManager:count() end

---@param index LuaValue
function LDoorManager:getDoor(index) end

---@param index LuaValue
function LDoorManager:openDoor(index) end

function LDoorManager:type() end

---@param name LuaValue
function LDoorManager:typeOf(name) end

---@param dt LuaValue
function LDoorManager:update(dt) end

---@class LHeightMap
LHeightMap = {}

---@param x LuaValue
---@param y LuaValue
function LHeightMap:ceilingAt(x, y) end

---@param x LuaValue
---@param y LuaValue
function LHeightMap:floorAt(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param h LuaValue
function LHeightMap:setCeiling(x, y, h) end

---@param x LuaValue
---@param y LuaValue
---@param h LuaValue
function LHeightMap:setFloor(x, y, h) end

function LHeightMap:type() end

---@param name LuaValue
function LHeightMap:typeOf(name) end

---@class LPointLight
LPointLight = {}

function LPointLight:color() end

function LPointLight:intensity() end

function LPointLight:radius() end

---@param x LuaValue
---@param y LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param radius LuaValue
---@param intensity LuaValue
function LPointLight:set(x, y, r, g, b, radius, intensity) end

function LPointLight:type() end

---@param name LuaValue
function LPointLight:typeOf(name) end

function LPointLight:x() end

function LPointLight:y() end

---@class LRaycaster
LRaycaster = {}

---@param center_x LuaValue
---@param center_y LuaValue
---@param radius LuaValue
---@param ambient LuaValue
---@param lights_tbl LuaValue
function LRaycaster:buildMinimapWindow(center_x, center_y, radius, ambient, lights_tbl) end

function LRaycaster:buildScene() end

function LRaycaster:buildSceneWithModels() end

function LRaycaster:castFloorRow() end

---@param ox LuaValue
---@param oy LuaValue
---@param angle LuaValue
---@param max_dist LuaValue
function LRaycaster:castRay(ox, oy, angle, max_dist) end

---@param ox LuaValue
---@param oy LuaValue
---@param angle LuaValue
---@param max_dist LuaValue
---@param max_hits? LuaValue
function LRaycaster:castRayMulti(ox, oy, angle, max_dist, max_hits) end

---@param ox LuaValue
---@param oy LuaValue
---@param angle LuaValue
---@param fov LuaValue
---@param count LuaValue
---@param max_dist LuaValue
function LRaycaster:castRays(ox, oy, angle, fov, count, max_dist) end

---@param ox LuaValue
---@param oy LuaValue
---@param angle LuaValue
---@param fov LuaValue
---@param count LuaValue
---@param max_dist LuaValue
function LRaycaster:castRaysFlat(ox, oy, angle, fov, count, max_dist) end

---@param x LuaValue
---@param y LuaValue
---@param ambient LuaValue
---@param lights_tbl LuaValue
function LRaycaster:computeTileLight(x, y, ambient, lights_tbl) end

---@param x LuaValue
---@param y LuaValue
---@param fov LuaValue
---@param max_dist LuaValue
---@param num_frames LuaValue
---@param fw LuaValue
---@param fh LuaValue
function LRaycaster:drawCameraSweep(x, y, fov, max_dist, num_frames, fw, fh) end

function LRaycaster:drawDepthMap() end

---@param ax LuaValue
---@param ay LuaValue
---@param bx LuaValue
---@param by LuaValue
---@param scale LuaValue
function LRaycaster:drawLineOfSight(ax, ay, bx, by, scale) end

---@param px LuaValue
---@param py LuaValue
---@param angle LuaValue
---@param scale LuaValue
function LRaycaster:drawTopDown(px, py, angle, scale) end

---@param px LuaValue
---@param py LuaValue
---@param angle LuaValue
---@param fov LuaValue
---@param w LuaValue
---@param h LuaValue
---@param max_dist LuaValue
function LRaycaster:drawView(px, py, angle, fov, w, h, max_dist) end

---@param x LuaValue
---@param y LuaValue
function LRaycaster:getCeilingTextureCell(x, y) end

---@param x LuaValue
---@param y LuaValue
function LRaycaster:getCell(x, y) end

---@param x LuaValue
---@param y LuaValue
function LRaycaster:getFloorTextureCell(x, y) end

---@param x LuaValue
---@param y LuaValue
function LRaycaster:getLoweredFloorCell(x, y) end

---@param tile_type LuaValue
function LRaycaster:getWallAlpha(tile_type) end

---@param px LuaValue
---@param py LuaValue
---@param dir LuaValue
---@param action LuaValue
---@param step LuaValue
function LRaycaster:gridMove(px, py, dir, action, step) end

function LRaycaster:height() end

---@param x LuaValue
---@param y LuaValue
function LRaycaster:isBlocked(x, y) end

---@param x LuaValue
---@param y LuaValue
function LRaycaster:isWalkBlocked(x, y) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
function LRaycaster:lineOfSight(x1, y1, x2, y2) end

---@param sx LuaValue
---@param sy LuaValue
---@param px LuaValue
---@param py LuaValue
---@param pa LuaValue
---@param fov LuaValue
---@param screen_w LuaValue
function LRaycaster:projectSprite(sx, sy, px, py, pa, fov, screen_w) end

function LRaycaster:revealCellsFromRays() end

---@param x LuaValue
---@param y LuaValue
---@param texture LuaValue
function LRaycaster:setCeilingTextureCell(x, y, texture) end

---@param x LuaValue
---@param y LuaValue
---@param val LuaValue
function LRaycaster:setCell(x, y, val) end

---@param cells_tbl LuaValue
function LRaycaster:setCells(cells_tbl) end

---@param x LuaValue
---@param y LuaValue
---@param texture LuaValue
function LRaycaster:setFloorTextureCell(x, y, texture) end

---@param x LuaValue
---@param y LuaValue
---@param opts LuaValue
function LRaycaster:setLoweredFloorCell(x, y, opts) end

---@param tile_type LuaValue
---@param alpha LuaValue
function LRaycaster:setWallAlpha(tile_type, alpha) end

---@param px LuaValue
---@param py LuaValue
---@param dx LuaValue
---@param dy LuaValue
function LRaycaster:tryMove(px, py, dx, dy) end

function LRaycaster:type() end

---@param name LuaValue
function LRaycaster:typeOf(name) end

function LRaycaster:width() end

---@class LSpriteManager
LSpriteManager = {}

---@param x LuaValue
---@param y LuaValue
---@param texture LuaValue
---@param scale? LuaValue
function LSpriteManager:add(x, y, texture, scale) end

function LSpriteManager:clear() end

---@param id LuaValue
function LSpriteManager:remove(id) end

---@param id LuaValue
---@param x LuaValue
---@param y LuaValue
function LSpriteManager:setPosition(id, x, y) end

---@param id LuaValue
---@param visible LuaValue
function LSpriteManager:setVisible(id, visible) end

---@param cam_x LuaValue
---@param cam_y LuaValue
---@param cam_angle LuaValue
function LSpriteManager:sortAndProject(cam_x, cam_y, cam_angle) end

function LSpriteManager:type() end

---@param name LuaValue
function LSpriteManager:typeOf(name) end

---@param distance LuaValue
---@param max_distance LuaValue
lurek.raycaster.distanceShade = function(distance, max_distance) end

---@param w LuaValue
---@param h LuaValue
lurek.raycaster.new = function(w, h) end

lurek.raycaster.newDoorManager = function() end

---@param w LuaValue
---@param h LuaValue
lurek.raycaster.newHeightMap = function(w, h) end

---@param w LuaValue
---@param h LuaValue
lurek.raycaster.newMap = function(w, h) end

---@param x LuaValue
---@param y LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param radius LuaValue
---@param intensity LuaValue
lurek.raycaster.newPointLight = function(x, y, r, g, b, radius, intensity) end

lurek.raycaster.newSpriteManager = function() end

---@param distance LuaValue
---@param fov LuaValue
---@param screen_height LuaValue
lurek.raycaster.projectColumn = function(distance, fov, screen_height) end

---@class lurek.render
lurek.render = {}

---@class LCanvas
LCanvas = {}

function LCanvas:getDimensions() end

function LCanvas:getHeight() end

function LCanvas:getWidth() end

function LCanvas:release() end

function LCanvas:type() end

function LCanvas:typeOf() end

---@class LDrawLayer
LDrawLayer = {}

function LDrawLayer:clear() end

function LDrawLayer:flush() end

function LDrawLayer:getCount() end

---@param z LuaValue
---@param f LuaValue
function LDrawLayer:queue(z, f) end

function LDrawLayer:type() end

---@param name LuaValue
function LDrawLayer:typeOf(name) end

---@class LFont
LFont = {}

function LFont:getAscent() end

function LFont:getDescent() end

function LFont:getHeight() end

function LFont:getLineHeight() end

---@param text LuaValue
function LFont:getWidth(text) end

---@param text LuaValue
---@param limit LuaValue
function LFont:getWrap(text, limit) end

function LFont:release() end

---@param height LuaValue
function LFont:setLineHeight(height) end

function LFont:type() end

function LFont:typeOf() end

---@class LImage
LImage = {}

function LImage:getDimensions() end

function LImage:getHeight() end

function LImage:getId() end

function LImage:getWidth() end

function LImage:release() end

function LImage:type() end

function LImage:typeOf() end

---@class LImageData
LImageData = {}

---@param src_ud LuaValue
---@param dst_x LuaValue
---@param dst_y LuaValue
function LImageData:blit(src_ud, dst_x, dst_y) end

---@param other_ud LuaValue
function LImageData:diff(other_ud) end

function LImageData:getHeight() end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LImageData:getRegion(x, y, w, h) end

function LImageData:getWidth() end

---@param callback LuaValue
function LImageData:mapPixels(callback) end

---@param w LuaValue
---@param h LuaValue
function LImageData:resize(w, h) end

function LImageData:type() end

---@param name LuaValue
function LImageData:typeOf(name) end

---@class LMesh
LMesh = {}

---@param index LuaValue
function LMesh:getVertex(index) end

function LMesh:getVertexCount() end

function LMesh:release() end

---@param ud? LuaValue
function LMesh:setTexture(ud) end

---@param index LuaValue
---@param data LuaValue
function LMesh:setVertex(index, data) end

function LMesh:type() end

function LMesh:typeOf() end

---@class LNineSlice
LNineSlice = {}

function LNineSlice:getInsets() end

function LNineSlice:getTextureSize() end

function LNineSlice:type() end

---@param name LuaValue
function LNineSlice:typeOf(name) end

---@class LObjModel
LObjModel = {}

function LObjModel:getFaceCount() end

function LObjModel:getNormalCount() end

function LObjModel:getUvCount() end

function LObjModel:getVertexCount() end

---@param cam_tbl LuaValue
---@param screen_w LuaValue
---@param screen_h LuaValue
function LObjModel:projectToMesh(cam_tbl, screen_w, screen_h) end

---@param width LuaValue
---@param height LuaValue
---@param rotation? LuaValue
function LObjModel:renderToImage(width, height, rotation) end

---@class LQuad
LQuad = {}

function LQuad:getTextureDimensions() end

function LQuad:getViewport() end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LQuad:setViewport(x, y, w, h) end

function LQuad:type() end

function LQuad:typeOf() end

---@class LShader
LShader = {}

---@param name LuaValue
function LShader:hasUniform(name) end

function LShader:release() end

---@param name LuaValue
---@param value LuaValue
function LShader:send(name, value) end

function LShader:type() end

function LShader:typeOf() end

---@class LShape
LShape = {}

function LShape:arc() end

---@param mode LuaValue
---@param x LuaValue
---@param y LuaValue
---@param r LuaValue
function LShape:circle(mode, x, y, r) end

function LShape:clear() end

function LShape:draw() end

---@param mode LuaValue
---@param x LuaValue
---@param y LuaValue
---@param rx LuaValue
---@param ry LuaValue
function LShape:ellipse(mode, x, y, rx, ry) end

function LShape:getCommandCount() end

---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
function LShape:line(x1, y1, x2, y2) end

---@param mode LuaValue
---@param coords LuaValue
function LShape:polygon(mode, coords) end

function LShape:polyline() end

---@param mode LuaValue
---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LShape:rectangle(mode, x, y, w, h) end

---@param mode LuaValue
---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
---@param rx LuaValue
---@param ry? LuaValue
function LShape:roundedRectangle(mode, x, y, w, h, rx, ry) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LShape:setColor(r, g, b, a) end

---@param w LuaValue
function LShape:setLineWidth(w) end

---@param mode LuaValue
---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param x3 LuaValue
---@param y3 LuaValue
function LShape:triangle(mode, x1, y1, x2, y2, x3, y3) end

function LShape:type() end

---@param name LuaValue
function LShape:typeOf(name) end

---@class LSpriteBatch
LSpriteBatch = {}

function LSpriteBatch:add() end

function LSpriteBatch:clear() end

function LSpriteBatch:getBufferSize() end

function LSpriteBatch:getCount() end

function LSpriteBatch:release() end

function LSpriteBatch:type() end

function LSpriteBatch:typeOf() end

---@param mat LuaValue
lurek.render.applyTransform = function(mat) end

lurek.render.arc = function() end

---@param id LuaValue
lurek.render.beginSortGroup = function(id) end

---@param id LuaValue
lurek.render.beginSortGroup = function(id) end

---@param callback LuaValue
lurek.render.captureScreenshot = function(callback) end

---@param mode LuaValue
---@param x LuaValue
---@param y LuaValue
---@param radius LuaValue
lurek.render.circle = function(mode, x, y, radius) end

---@param r? LuaValue
---@param g? LuaValue
---@param b? LuaValue
lurek.render.clear = function(r, g, b) end

lurek.render.clearStencil = function() end

lurek.render.currentLayer = function() end

---@param ... LuaValue
lurek.render.draw = function(...) end

lurek.render.drawBevelRect = function() end

lurek.render.drawBevelRect = function() end

---@param vertices LuaValue
---@param colors LuaValue
---@param mode? LuaValue
lurek.render.drawColoredPolygon = function(vertices, colors, mode) end

---@param vertices LuaValue
---@param colors LuaValue
---@param mode? LuaValue
lurek.render.drawColoredPolygon = function(vertices, colors, mode) end

lurek.render.drawCubicBezier = function() end

lurek.render.drawCubicBezier = function() end

lurek.render.drawGradientRect = function() end

lurek.render.drawGradientRect = function() end

lurek.render.drawHexTile = function() end

lurek.render.drawHexTile = function() end

---@param sx LuaValue
---@param sy LuaValue
---@param half_w LuaValue
---@param half_h LuaValue
---@param opts? LuaValue
lurek.render.drawIsoCubeTile = function(sx, sy, half_w, half_h, opts) end

---@param sx LuaValue
---@param sy LuaValue
---@param half_w LuaValue
---@param half_h LuaValue
---@param opts? LuaValue
lurek.render.drawIsoCubeTile = function(sx, sy, half_w, half_h, opts) end

---@param list LuaValue
lurek.render.drawMany = function(list) end

---@param slice LuaValue
---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
lurek.render.drawNineSlice = function(slice, x, y, w, h) end

---@param path LuaValue
---@param mode? LuaValue
---@param close? LuaValue
lurek.render.drawPath = function(path, mode, close) end

---@param path LuaValue
---@param mode? LuaValue
---@param close? LuaValue
lurek.render.drawPath = function(path, mode, close) end

---@param x1 LuaValue
---@param y1 LuaValue
---@param cx LuaValue
---@param cy LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param segs? LuaValue
lurek.render.drawQuadBezier = function(x1, y1, cx, cy, x2, y2, segs) end

lurek.render.drawQuadBezier = function() end

lurek.render.drawq = function() end

---@param mode LuaValue
---@param x LuaValue
---@param y LuaValue
---@param rx LuaValue
---@param ry LuaValue
lurek.render.ellipse = function(mode, x, y, rx, ry) end

---@param id LuaValue
lurek.render.flushSortGroup = function(id) end

---@param id LuaValue
lurek.render.flushSortGroup = function(id) end

lurek.render.getBackgroundColor = function() end

lurek.render.getBlendMode = function() end

lurek.render.getCanvas = function() end

---@param ud LuaValue
lurek.render.getCanvasSize = function(ud) end

lurek.render.getColor = function() end

lurek.render.getColorMask = function() end

lurek.render.getDefaultFilter = function() end

---@param pixel_height? LuaValue
lurek.render.getDefaultFont = function(pixel_height) end

lurek.render.getDepthMode = function() end

lurek.render.getDimensions = function() end

lurek.render.getFont = function() end

---@param ud LuaValue
lurek.render.getFontAscent = function(ud) end

---@param ud LuaValue
lurek.render.getFontCellWidth = function(ud) end

---@param ud LuaValue
lurek.render.getFontDescent = function(ud) end

---@param ud LuaValue
lurek.render.getFontHeight = function(ud) end

---@param ud LuaValue
lurek.render.getFontLineHeight = function(ud) end

lurek.render.getFontSizes = function() end

---@param ud LuaValue
---@param text LuaValue
lurek.render.getFontWidth = function(ud, text) end

---@param text LuaValue
---@param limit LuaValue
lurek.render.getFontWrap = function(text, limit) end

lurek.render.getHeight = function() end

---@param name LuaValue
lurek.render.getLayerZOrder = function(name) end

lurek.render.getLineWidth = function() end

lurek.render.getPointSize = function() end

lurek.render.getScissor = function() end

lurek.render.getShader = function() end

lurek.render.getStats = function() end

lurek.render.getStencilMode = function() end

lurek.render.getWidth = function() end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
lurek.render.intersectScissor = function(x, y, w, h) end

---@param name LuaValue
lurek.render.isLayerVisible = function(name) end

lurek.render.isWireframe = function() end

---@param ... LuaValue
lurek.render.line = function(...) end

---@param path LuaValue
lurek.render.loadModel = function(path) end

---@param path LuaValue
lurek.render.loadObj = function(path) end

---@param width LuaValue
---@param height LuaValue
lurek.render.newCanvas = function(width, height) end

lurek.render.newDrawLayer = function() end

---@param ... LuaValue
lurek.render.newFont = function(...) end

---@param ... LuaValue
lurek.render.newImage = function(...) end

---@param name LuaValue
---@param z_order? LuaValue
lurek.render.newLayer = function(name, z_order) end

---@param verts LuaValue
---@param mode? LuaValue
lurek.render.newMesh = function(verts, mode) end

---@param image LuaValue
---@param top LuaValue
---@param right LuaValue
---@param bottom LuaValue
---@param left LuaValue
lurek.render.newNineSlice = function(image, top, right, bottom, left) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
---@param sw LuaValue
---@param sh LuaValue
lurek.render.newQuad = function(x, y, w, h, sw, sh) end

---@param code LuaValue
lurek.render.newShader = function(code) end

lurek.render.newShape = function() end

---@param ud LuaValue
---@param max? LuaValue
lurek.render.newSpriteBatch = function(ud, max) end

lurek.render.origin = function() end

---@param ... LuaValue
lurek.render.points = function(...) end

---@param ... LuaValue
lurek.render.polygon = function(...) end

lurek.render.pop = function() end

---@param id LuaValue
lurek.render.popLayer = function(id) end

---@param id LuaValue
lurek.render.popLayer = function(id) end

---@param text LuaValue
---@param x? LuaValue
---@param y? LuaValue
---@param scale? LuaValue
lurek.render.print = function(text, x, y, scale) end

---@param spans_table LuaValue
---@param x LuaValue
---@param y LuaValue
lurek.render.printRich = function(spans_table, x, y) end

---@param text LuaValue
---@param x LuaValue
---@param y LuaValue
---@param angle LuaValue
---@param scale? LuaValue
lurek.render.printRotated = function(text, x, y, angle, scale) end

---@param text LuaValue
---@param x LuaValue
---@param y LuaValue
---@param limit LuaValue
---@param align? LuaValue
lurek.render.printf = function(text, x, y, limit, align) end

lurek.render.push = function() end

---@param id LuaValue
---@param alpha? LuaValue
---@param blend_mode? LuaValue
lurek.render.pushLayer = function(id, alpha, blend_mode) end

---@param id LuaValue
---@param alpha? LuaValue
---@param blend_mode? LuaValue
lurek.render.pushLayer = function(id, alpha, blend_mode) end

---@param depth LuaValue
lurek.render.pushSortKey = function(depth) end

---@param depth LuaValue
lurek.render.pushSortKey = function(depth) end

lurek.render.rectangle = function() end

---@param angle LuaValue
lurek.render.rotate = function(angle) end

---@param path LuaValue
lurek.render.saveScreenshot = function(path) end

---@param sx LuaValue
---@param sy? LuaValue
lurek.render.scale = function(sx, sy) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
lurek.render.setBackgroundColor = function(r, g, b) end

---@param mode LuaValue
lurek.render.setBlendMode = function(mode) end

---@param ud? LuaValue
lurek.render.setCanvas = function(ud) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
lurek.render.setColor = function(r, g, b, a) end

---@param ... LuaValue
lurek.render.setColorMask = function(...) end

---@param min LuaValue
---@param mag LuaValue
---@param anisotropy? LuaValue
lurek.render.setDefaultFilter = function(min, mag, anisotropy) end

---@param mode LuaValue
---@param write? LuaValue
lurek.render.setDepthMode = function(mode, write) end

---@param ud LuaValue
lurek.render.setFont = function(ud) end

---@param font LuaValue
---@param lh LuaValue
lurek.render.setFontLineHeight = function(font, lh) end

---@param name LuaValue
lurek.render.setLayer = function(name) end

---@param name LuaValue
---@param visible LuaValue
lurek.render.setLayerVisible = function(name, visible) end

---@param name LuaValue
---@param z LuaValue
lurek.render.setLayerZOrder = function(name, z) end

---@param w LuaValue
lurek.render.setLineWidth = function(w) end

---@param size LuaValue
lurek.render.setPointSize = function(size) end

---@param ... LuaValue
lurek.render.setScissor = function(...) end

---@param ud? LuaValue
lurek.render.setShader = function(ud) end

---@param action LuaValue
---@param compare? LuaValue
---@param value? LuaValue
lurek.render.setStencilMode = function(action, compare, value) end

---@param compare? LuaValue
---@param value? LuaValue
lurek.render.setStencilTest = function(compare, value) end

---@param enabled LuaValue
lurek.render.setWireframe = function(enabled) end

---@param kx LuaValue
---@param ky LuaValue
lurek.render.shear = function(kx, ky) end

---@param action? LuaValue
---@param value? LuaValue
lurek.render.stencil = function(action, value) end

---@param x LuaValue
---@param y LuaValue
lurek.render.translate = function(x, y) end

---@param mode LuaValue
---@param x1 LuaValue
---@param y1 LuaValue
---@param x2 LuaValue
---@param y2 LuaValue
---@param x3 LuaValue
---@param y3 LuaValue
lurek.render.triangle = function(mode, x1, y1, x2, y2, x3, y3) end

---@class lurek.save
lurek.save = {}

---@class LSaveManager
LSaveManager = {}

---@param from_ver LuaValue
---@param func LuaValue
function LSaveManager:addMigration(from_ver, func) end

function LSaveManager:collect() end

---@param slot LuaValue
function LSaveManager:delete(slot) end

function LSaveManager:disableAutoSave() end

---@param interval LuaValue
---@param slot LuaValue
function LSaveManager:enableAutoSave(interval, slot) end

---@param slot LuaValue
function LSaveManager:exists(slot) end

function LSaveManager:getSchemaVersion() end

---@param slot LuaValue
function LSaveManager:getSlotInfo(slot) end

function LSaveManager:getSlots() end

function LSaveManager:getSummary() end

function LSaveManager:isCompressed() end

function LSaveManager:isDirty() end

---@param slot LuaValue
function LSaveManager:load(slot) end

function LSaveManager:markDirty() end

---@param func LuaValue
function LSaveManager:onAfterLoad(func) end

---@param func LuaValue
function LSaveManager:onBeforeSave(func) end

---@param name LuaValue
---@param collect_fn LuaValue
---@param restore_fn LuaValue
function LSaveManager:register(name, collect_fn, restore_fn) end

function LSaveManager:reset() end

---@param data LuaValue
function LSaveManager:restore(data) end

---@param slot LuaValue
function LSaveManager:save(slot) end

---@param enabled LuaValue
function LSaveManager:setCompress(enabled) end

---@param version LuaValue
function LSaveManager:setSchemaVersion(version) end

---@param summary LuaValue
function LSaveManager:setSummary(summary) end

function LSaveManager:type() end

---@param name LuaValue
function LSaveManager:typeOf(name) end

---@param name LuaValue
function LSaveManager:unregister(name) end

---@param dt LuaValue
function LSaveManager:update(dt) end

lurek.save.newSaveManager = function() end

---@class lurek.scene
lurek.scene = {}

---@class LDepthSorter
LDepthSorter = {}

---@param callback LuaValue
---@param depth LuaValue
function LDepthSorter:add(callback, depth) end

---@param obj LuaValue
function LDepthSorter:addObject(obj) end

function LDepthSorter:clear() end

function LDepthSorter:flush() end

function LDepthSorter:getCount() end

function LDepthSorter:isStable() end

---@param stable LuaValue
function LDepthSorter:setStable(stable) end

function LDepthSorter:sort() end

function LDepthSorter:type() end

---@param name LuaValue
function LDepthSorter:typeOf(name) end

lurek.scene.clear = function() end

lurek.scene.clearQueuedTransitions = function() end

---@param def? LuaValue
lurek.scene.define = function(def) end

lurek.scene.depth = function() end

---@param snapshot LuaValue
lurek.scene.deserializeScene = function(snapshot) end

lurek.scene.draw = function() end

---@param duration? LuaValue
lurek.scene.fade = function(duration) end

lurek.scene.getActiveScenes = function() end

lurek.scene.getCurrent = function() end

lurek.scene.getCurrentLayer = function() end

---@param key LuaValue
lurek.scene.getData = function(key) end

lurek.scene.getQueuedTransitionCount = function() end

---@param name LuaValue
lurek.scene.getRegistered = function(name) end

lurek.scene.getRegisteredNames = function() end

lurek.scene.getStackSize = function() end

lurek.scene.getTransitionProgress = function() end

lurek.scene.getTransitionProgressEased = function() end

lurek.scene.getTransitionTypes = function() end

---@param key LuaValue
lurek.scene.hasData = function(key) end

---@param name LuaValue
lurek.scene.hasRegistered = function(name) end

---@param duration? LuaValue
lurek.scene.iris = function(duration) end

lurek.scene.isEmpty = function() end

lurek.scene.isOverlay = function() end

---@param name LuaValue
lurek.scene.isPreloaded = function(name) end

lurek.scene.isTransitioning = function() end

---@param def? LuaValue
lurek.scene.new = function(def) end

lurek.scene.newDepthSorter = function() end

---@param def? LuaValue
lurek.scene.newScene = function(def) end

---@param transition? LuaValue
---@param duration? LuaValue
---@param easing? LuaValue
lurek.scene.pop = function(transition, duration, easing) end

---@param name LuaValue
lurek.scene.popTo = function(name) end

---@param name LuaValue
---@param loader LuaValue
lurek.scene.preload = function(name, loader) end

---@param dt LuaValue
lurek.scene.process = function(dt) end

---@param dt LuaValue
lurek.scene.processLate = function(dt) end

---@param dt LuaValue
lurek.scene.processPhysics = function(dt) end

lurek.scene.push = function() end

lurek.scene.pushOverlay = function() end

lurek.scene.pushPreloaded = function() end

---@param transition LuaValue
---@param duration LuaValue
---@param easing? LuaValue
lurek.scene.queueTransition = function(transition, duration, easing) end

---@param name LuaValue
---@param scene LuaValue
lurek.scene.registerScene = function(name, scene) end

---@param key LuaValue
lurek.scene.removeData = function(key) end

lurek.scene.render = function() end

lurek.scene.renderUi = function() end

lurek.scene.serializeScene = function() end

---@param layer LuaValue
lurek.scene.setCurrentLayer = function(layer) end

---@param key LuaValue
---@param value LuaValue
lurek.scene.setData = function(key, value) end

---@param direction? LuaValue
---@param duration? LuaValue
lurek.scene.slide = function(direction, duration) end

lurek.scene.switchTo = function() end

---@param name LuaValue
lurek.scene.unregisterScene = function(name) end

---@param dt LuaValue
lurek.scene.update = function(dt) end

---@param duration? LuaValue
lurek.scene.wipe = function(duration) end

---@class lurek.serial
lurek.serial = {}

---@param value LuaValue
---@param schema LuaValue
lurek.serial.applyDefaults = function(value, schema) end

---@param payload LuaValue
---@param format? LuaValue
---@param opts? LuaValue
lurek.serial.decode = function(payload, format, opts) end

lurek.serial.decodeMsgPack = function() end

---@param s LuaValue
lurek.serial.decodeXml = function(s) end

---@param s LuaValue
lurek.serial.detectFormat = function(s) end

---@param value LuaValue
---@param format LuaValue
---@param opts? LuaValue
lurek.serial.encode = function(value, format, opts) end

---@param value LuaValue
lurek.serial.encodeMsgPack = function(value) end

---@param s LuaValue
---@param delim? LuaValue
---@param headers? LuaValue
lurek.serial.fromCsv = function(s, delim, headers) end

---@param s LuaValue
lurek.serial.fromIni = function(s) end

---@param s LuaValue
lurek.serial.fromJson = function(s) end

---@param s LuaValue
lurek.serial.fromToml = function(s) end

---@param value LuaValue
---@param delim? LuaValue
---@param headers? LuaValue
lurek.serial.toCsv = function(value, delim, headers) end

---@param value LuaValue
---@param pretty? LuaValue
lurek.serial.toJson = function(value, pretty) end

---@param value LuaValue
lurek.serial.toToml = function(value) end

---@param value LuaValue
---@param schema LuaValue
lurek.serial.validate = function(value, schema) end

---@class lurek.spine
lurek.spine = {}

---@class LSkeleton
LSkeleton = {}

---@param anim_ud LuaValue
function LSkeleton:addAnimation(anim_ud) end

---@param name LuaValue
---@param opts? LuaValue
function LSkeleton:addBone(name, opts) end

---@param name LuaValue
---@param parent_idx LuaValue
---@param opts? LuaValue
function LSkeleton:addChildBone(name, parent_idx, opts) end

---@param name LuaValue
---@param chain_tbl LuaValue
---@param bend_positive? LuaValue
function LSkeleton:addIKConstraint(name, chain_tbl, bend_positive) end

---@param name LuaValue
function LSkeleton:addSkin(name) end

---@param name LuaValue
---@param bone_idx LuaValue
---@param attachment? LuaValue
function LSkeleton:addSlot(name, bone_idx, attachment) end

---@param anim_ud LuaValue
---@param time LuaValue
---@param blend_weight? LuaValue
function LSkeleton:blendAnimation(anim_ud, time, blend_weight) end

function LSkeleton:boneCount() end

---@param w LuaValue
---@param h LuaValue
function LSkeleton:drawToImage(w, h) end

---@param name LuaValue
function LSkeleton:findBone(name) end

---@param name LuaValue
function LSkeleton:findSlot(name) end

function LSkeleton:getAnimationTime() end

---@param idx LuaValue
function LSkeleton:getBoneWorld(idx) end

function LSkeleton:getSkin() end

---@param name LuaValue
---@param looping? LuaValue
function LSkeleton:playAnimation(name, looping) end

---@param name LuaValue
---@param x LuaValue
---@param y LuaValue
function LSkeleton:setIKTarget(name, x, y) end

---@param x LuaValue
---@param y LuaValue
function LSkeleton:setPosition(x, y) end

---@param name LuaValue
function LSkeleton:setSkin(name) end

---@param skin LuaValue
---@param slot LuaValue
---@param attachment LuaValue
function LSkeleton:setSkinMapping(skin, slot, attachment) end

function LSkeleton:slotCount() end

function LSkeleton:stopAnimation() end

function LSkeleton:type() end

---@param name LuaValue
function LSkeleton:typeOf(name) end

---@param dt LuaValue
function LSkeleton:updateAnimation(dt) end

function LSkeleton:updateWorldTransforms() end

---@class LSkeletonAnimation
LSkeletonAnimation = {}

---@param time LuaValue
---@param name LuaValue
---@param value? LuaValue
function LSkeletonAnimation:addEventKey(time, name, value) end

function LSkeletonAnimation:addKeyframe() end

function LSkeletonAnimation:getDuration() end

---@param from LuaValue
---@param to LuaValue
function LSkeletonAnimation:getEvents(from, to) end

function LSkeletonAnimation:getTimelineCount() end

---@param time LuaValue
function LSkeletonAnimation:poseAt(time) end

function LSkeletonAnimation:reverse() end

function LSkeletonAnimation:type() end

---@param name LuaValue
function LSkeletonAnimation:typeOf(name) end

---@param json LuaValue
lurek.spine.animationFromJson = function(json) end

---@param name LuaValue
lurek.spine.newSkeleton = function(name) end

---@param name LuaValue
---@param duration LuaValue
lurek.spine.newSkeletonAnimation = function(name, duration) end

---@class lurek.sprite
lurek.sprite = {}

---@class LSpriteAtlas
LSpriteAtlas = {}

function LSpriteAtlas:entryCount() end

function LSpriteAtlas:entryNames() end

---@param index LuaValue
function LSpriteAtlas:getByIndex(index) end

---@param name LuaValue
function LSpriteAtlas:getEntry(name) end

---@param name LuaValue
---@param flip_x LuaValue
---@param flip_y LuaValue
function LSpriteAtlas:getFlipped(name, flip_x, flip_y) end

function LSpriteAtlas:type() end

---@param name LuaValue
function LSpriteAtlas:typeOf(name) end

---@class LSpriteSheet
LSpriteSheet = {}

---@param w LuaValue
---@param h LuaValue
function LSpriteSheet:drawToImage(w, h) end

---@param col LuaValue
function LSpriteSheet:getColumn(col) end

---@param index LuaValue
function LSpriteSheet:getFrame(index) end

function LSpriteSheet:getFrameCount() end

function LSpriteSheet:getFrameSize() end

function LSpriteSheet:getGridSize() end

---@param name LuaValue
function LSpriteSheet:getGroupFrames(name) end

function LSpriteSheet:getGroupNames() end

---@param row LuaValue
function LSpriteSheet:getRow(row) end

---@param name LuaValue
---@param start LuaValue
---@param count LuaValue
function LSpriteSheet:nameGroup(name, start, count) end

function LSpriteSheet:type() end

---@param name LuaValue
function LSpriteSheet:typeOf(name) end

---@param atlas_ud LuaValue
---@param sw LuaValue
---@param sh LuaValue
lurek.sprite.newAtlasSheet = function(atlas_ud, sw, sh) end

---@param tw LuaValue
---@param th LuaValue
lurek.sprite.newRPGMakerSheet = function(tw, th) end

---@param tw LuaValue
---@param th LuaValue
---@param fw LuaValue
---@param fh LuaValue
lurek.sprite.newSheet = function(tw, th, fw, fh) end

---@param json_str LuaValue
lurek.sprite.parseAsepriteAtlas = function(json_str) end

---@param json_str LuaValue
lurek.sprite.parseAtlas = function(json_str) end

---@class lurek.system
lurek.system = {}

---@param msg LuaValue
lurek.runtime.errorSnapshot = function(msg) end

lurek.runtime.getArch = function() end

lurek.runtime.getArgs = function() end

---@param results LuaValue
lurek.runtime.getBatchResults = function(results) end

lurek.runtime.getClipboardText = function() end

lurek.runtime.getConfig = function() end

lurek.runtime.getDebugOverlay = function() end

---@param name LuaValue
lurek.runtime.getEnv = function(name) end

lurek.runtime.getInfo = function() end

lurek.runtime.getLastError = function() end

lurek.runtime.getLogLevel = function() end

lurek.runtime.getMemorySize = function() end

---@param id LuaValue
lurek.runtime.getMessage = function(id) end

lurek.runtime.getMessageCount = function() end

lurek.runtime.getOS = function() end

lurek.runtime.getPowerInfo = function() end

lurek.runtime.getPreferredLocales = function() end

lurek.runtime.getProcessorCount = function() end

lurek.runtime.getVersion = function() end

---@param id LuaValue
lurek.runtime.hasMessage = function(id) end

---@param level LuaValue
---@param message LuaValue
lurek.runtime.log = function(level, message) end

---@param url LuaValue
lurek.runtime.openURL = function(url) end

---@param args? LuaValue
lurek.runtime.parseArgs = function(args) end

lurek.runtime.reloadConfig = function() end

---@param tasks LuaValue
---@param opts? LuaValue
lurek.runtime.runBatch = function(tasks, opts) end

---@param text LuaValue
lurek.runtime.setClipboardText = function(text) end

---@param enabled LuaValue
lurek.runtime.setDebugOverlay = function(enabled) end

---@param level LuaValue
lurek.runtime.setLogLevel = function(level) end

---@class lurek.terminal
lurek.terminal = {}

---@class LTerminal
LTerminal = {}

---@param widget_ud LuaValue
function LTerminal:addWidget(widget_ud) end

function LTerminal:autoResize() end

function LTerminal:clear() end

function LTerminal:clearWidgets() end

---@param col LuaValue
---@param row LuaValue
function LTerminal:get(col, row) end

function LTerminal:getCellSize() end

function LTerminal:getDimensions() end

function LTerminal:getFocused() end

function LTerminal:getWidgetCount() end

---@param key LuaValue
function LTerminal:keypressed(key) end

---@param px LuaValue
---@param py LuaValue
---@param button? LuaValue
function LTerminal:mousepressed(px, py, button) end

---@param widget_ud LuaValue
function LTerminal:removeWidget(widget_ud) end

---@param x? LuaValue
---@param y? LuaValue
function LTerminal:render(x, y) end

function LTerminal:resetCellSize() end

---@param ... LuaValue
function LTerminal:set(...) end

---@param w LuaValue
---@param h LuaValue
function LTerminal:setCellSize(w, h) end

---@param value LuaValue
function LTerminal:setFocus(value) end

---@param height LuaValue
function LTerminal:setFont(height) end

---@param text LuaValue
function LTerminal:textinput(text) end

function LTerminal:type() end

---@param name LuaValue
function LTerminal:typeOf(name) end

---@class LWidget
LWidget = {}

---@param child_ud LuaValue
function LWidget:addChild(child_ud) end

---@param item LuaValue
function LWidget:addItem(item) end

function LWidget:clearChildren() end

function LWidget:clearItems() end

---@param index LuaValue
function LWidget:getChild(index) end

function LWidget:getChildCount() end

function LWidget:getColor() end

---@param index LuaValue
function LWidget:getItem(index) end

function LWidget:getItemCount() end

function LWidget:getMaxLength() end

function LWidget:getPosition() end

function LWidget:getSelected() end

function LWidget:getSize() end

function LWidget:getStyle() end

function LWidget:getTag() end

function LWidget:getText() end

function LWidget:getTitle() end

function LWidget:isEnabled() end

function LWidget:isVisible() end

---@param child_ud LuaValue
function LWidget:removeChild(child_ud) end

---@param index LuaValue
function LWidget:removeItem(index) end

---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a? LuaValue
function LWidget:setColor(r, g, b, a) end

---@param enabled LuaValue
function LWidget:setEnabled(enabled) end

---@param max_length LuaValue
function LWidget:setMaxLength(max_length) end

---@param callback? LuaValue
function LWidget:setOnChange(callback) end

---@param callback? LuaValue
function LWidget:setOnClick(callback) end

---@param callback? LuaValue
function LWidget:setOnSelect(callback) end

---@param col LuaValue
---@param row LuaValue
function LWidget:setPosition(col, row) end

---@param index? LuaValue
function LWidget:setSelected(index) end

---@param width LuaValue
---@param height LuaValue
function LWidget:setSize(width, height) end

---@param style_name LuaValue
function LWidget:setStyle(style_name) end

---@param tag LuaValue
function LWidget:setTag(tag) end

---@param text LuaValue
function LWidget:setText(text) end

---@param title LuaValue
function LWidget:setTitle(title) end

---@param visible LuaValue
function LWidget:setVisible(visible) end

function LWidget:type() end

---@param name LuaValue
function LWidget:typeOf(name) end

---@param candidate LuaValue
lurek.terminal.addCompletion = function(candidate) end

---@param term_ud LuaValue
---@param theme LuaValue
lurek.terminal.applyTheme = function(term_ud, theme) end

---@param term_ud LuaValue
lurek.terminal.clearCmdHistory = function(term_ud) end

lurek.terminal.clearCompletions = function() end

---@param term_ud LuaValue
lurek.terminal.cmdHistoryLen = function(term_ud) end

---@param prefix LuaValue
lurek.terminal.getCompletions = function(prefix) end

lurek.terminal.getMaxCols = function() end

lurek.terminal.getMaxRows = function() end

---@param term_ud LuaValue
---@param offset LuaValue
---@param count LuaValue
lurek.terminal.getScrollback = function(term_ud, offset, count) end

---@param col LuaValue
---@param row LuaValue
---@param width LuaValue
---@param height LuaValue
lurek.terminal.newBorder = function(col, row, width, height) end

lurek.terminal.newButton = function() end

---@param col LuaValue
---@param row LuaValue
---@param text? LuaValue
lurek.terminal.newLabel = function(col, row, text) end

---@param col LuaValue
---@param row LuaValue
---@param width LuaValue
---@param height LuaValue
lurek.terminal.newList = function(col, row, width, height) end

---@param col LuaValue
---@param row LuaValue
---@param width? LuaValue
---@param height? LuaValue
lurek.terminal.newPanel = function(col, row, width, height) end

---@param cols? LuaValue
---@param rows? LuaValue
lurek.terminal.newTerminal = function(cols, rows) end

---@param col LuaValue
---@param row LuaValue
---@param width LuaValue
lurek.terminal.newTextBox = function(col, row, width) end

---@param term_ud LuaValue
lurek.terminal.nextCmd = function(term_ud) end

---@param prefix LuaValue
lurek.terminal.nextCompletion = function(prefix) end

---@param text LuaValue
lurek.terminal.parseAnsi = function(text) end

---@param term_ud LuaValue
lurek.terminal.prevCmd = function(term_ud) end

---@param t_ud LuaValue
---@param col LuaValue
---@param row LuaValue
---@param text LuaValue
lurek.terminal.printAnsi = function(t_ud, col, row, text) end

lurek.terminal.printHighlighted = function() end

---@param term_ud LuaValue
---@param cmd LuaValue
lurek.terminal.pushCmdHistory = function(term_ud, cmd) end

---@param term_ud LuaValue
---@param line LuaValue
lurek.terminal.pushScrollback = function(term_ud, line) end

---@param candidate LuaValue
lurek.terminal.removeCompletion = function(candidate) end

lurek.terminal.resetCompletion = function() end

---@param term_ud LuaValue
lurek.terminal.scrollbackLen = function(term_ud) end

---@param term_ud LuaValue
---@param cap LuaValue
lurek.terminal.setScrollbackCap = function(term_ud, cap) end

---@param text LuaValue
lurek.terminal.stripAnsi = function(text) end

---@class lurek.thread
lurek.thread = {}

---@class LChannel
LChannel = {}

function LChannel:clear() end

---@param timeout? LuaValue
function LChannel:demand(timeout) end

function LChannel:getCapacity() end

function LChannel:getCount() end

function LChannel:isBounded() end

function LChannel:peek() end

function LChannel:pop() end

function LChannel:popBytes() end

function LChannel:popTable() end

---@param value LuaValue
function LChannel:push(value) end

---@param data LuaValue
function LChannel:pushBytes(data) end

---@param value LuaValue
function LChannel:pushTable(value) end

---@param value LuaValue
function LChannel:supply(value) end

---@param value LuaValue
function LChannel:tryPush(value) end

function LChannel:type() end

---@param name LuaValue
function LChannel:typeOf(name) end

---@class LPromise
LPromise = {}

---@param code LuaValue
---@param ... LuaValue
function LPromise:chain(code, ...) end

function LPromise:getError() end

function LPromise:isDone() end

function LPromise:result() end

function LPromise:type() end

---@param name LuaValue
function LPromise:typeOf(name) end

---@class LThread
LThread = {}

function LThread:getError() end

function LThread:isRunning() end

---@param ... LuaValue
function LThread:start(...) end

function LThread:type() end

---@param name LuaValue
function LThread:typeOf(name) end

function LThread:wait() end

---@class LThreadPool
LThreadPool = {}

function LThreadPool:collect() end

function LThreadPool:getInputChannel() end

function LThreadPool:getOutputChannel() end

---@param timeout? LuaValue
function LThreadPool:join(timeout) end

function LThreadPool:size() end

---@param value LuaValue
function LThreadPool:submit(value) end

function LThreadPool:type() end

---@param name LuaValue
function LThreadPool:typeOf(name) end

---@param ... LuaValue
lurek.thread.async = function(...) end

---@param name LuaValue
lurek.thread.getChannel = function(name) end

lurek.thread.getWorkerCapabilities = function() end

---@param capacity LuaValue
lurek.thread.newBoundedChannel = function(capacity) end

lurek.thread.newChannel = function() end

---@param size LuaValue
---@param code LuaValue
lurek.thread.newPool = function(size, code) end

---@param code LuaValue
lurek.thread.newThread = function(code) end

---@class lurek.tilemap
---@field FLOOR number  solid floor tile type (1)
---@field NORTH_WALL number  north-facing wall tile type (2)
---@field WEST_WALL number  west-facing wall tile type (3)
---@field OBJECT number  object tile type (4)
lurek.tilemap = {}

---@class LAutoTileSheet
LAutoTileSheet = {}

---@param ts_ud LuaValue
---@param type_name LuaValue
---@param start_gid? LuaValue
function LAutoTileSheet:applyToTileSet(ts_ud, type_name, start_gid) end

---@param tile_id LuaValue
function LAutoTileSheet:getBitmaskForTile(tile_id) end

function LAutoTileSheet:getLayout() end

---@param tile_id LuaValue
function LAutoTileSheet:getQuad(tile_id) end

function LAutoTileSheet:getTileCount() end

---@param bitmask LuaValue
function LAutoTileSheet:getTileForBitmask(bitmask) end

function LAutoTileSheet:getTileHeight() end

function LAutoTileSheet:getTileWidth() end

function LAutoTileSheet:type() end

---@param name LuaValue
function LAutoTileSheet:typeOf(name) end

---@class LChunkMap
LChunkMap = {}

---@param cx LuaValue
---@param cy LuaValue
function LChunkMap:chunkTileRange(cx, cy) end

---@param x LuaValue
---@param y LuaValue
function LChunkMap:clearTile(x, y) end

---@param x0 LuaValue
---@param y0 LuaValue
---@param x1 LuaValue
---@param y1 LuaValue
---@param gid LuaValue
function LChunkMap:fillRect(x0, y0, x1, y1, gid) end

function LChunkMap:getChunkSize() end

---@param vx LuaValue
---@param vy LuaValue
---@param vw LuaValue
---@param vh LuaValue
---@param tw LuaValue
---@param th LuaValue
function LChunkMap:getChunksInView(vx, vy, vw, vh, tw, th) end

function LChunkMap:getLoadedChunks() end

---@param x LuaValue
---@param y LuaValue
function LChunkMap:getTile(x, y) end

---@param cx LuaValue
---@param cy LuaValue
function LChunkMap:loadChunk(cx, cy) end

---@param x LuaValue
---@param y LuaValue
---@param gid LuaValue
function LChunkMap:setTile(x, y, gid) end

function LChunkMap:type() end

---@param name LuaValue
function LChunkMap:typeOf(name) end

---@param cx LuaValue
---@param cy LuaValue
function LChunkMap:unloadChunk(cx, cy) end

---@class LIsoMap
LIsoMap = {}

function LIsoMap:addLevel() end

---@param z LuaValue
---@param part LuaValue
---@param gid LuaValue
function LIsoMap:fillLevel(z, part, gid) end

function LIsoMap:getHeight() end

function LIsoMap:getLevelCount() end

function LIsoMap:getLevelHeight() end

function LIsoMap:getPartCount() end

function LIsoMap:getPartOrder() end

function LIsoMap:getTileHeight() end

---@param z LuaValue
---@param x LuaValue
---@param y LuaValue
---@param part LuaValue
function LIsoMap:getTilePart(z, x, y, part) end

function LIsoMap:getTileWidth() end

function LIsoMap:getWidth() end

---@param z LuaValue
function LIsoMap:isLevelVisible(z) end

---@param sx LuaValue
---@param sy LuaValue
function LIsoMap:screenToTile(sx, sy) end

---@param z LuaValue
---@param visible LuaValue
function LIsoMap:setLevelVisible(z, visible) end

---@param x LuaValue
---@param y LuaValue
function LIsoMap:setOrigin(x, y) end

---@param order LuaValue
function LIsoMap:setPartOrder(order) end

---@param z LuaValue
---@param x LuaValue
---@param y LuaValue
---@param part LuaValue
---@param gid LuaValue
function LIsoMap:setTilePart(z, x, y, part, gid) end

---@param tx LuaValue
---@param ty LuaValue
---@param tz LuaValue
function LIsoMap:tileToScreen(tx, ty, tz) end

function LIsoMap:type() end

---@param name LuaValue
function LIsoMap:typeOf(name) end

---@class LLargeMapRenderer
LLargeMapRenderer = {}

function LLargeMapRenderer:getChunkSize() end

function LLargeMapRenderer:getMapSize() end

---@param x LuaValue
---@param y LuaValue
function LLargeMapRenderer:getTile(x, y) end

function LLargeMapRenderer:getTilesetColumns() end

function LLargeMapRenderer:getTotalChunks() end

function LLargeMapRenderer:getVisibleChunks() end

function LLargeMapRenderer:invalidateAll() end

---@param cx LuaValue
---@param cy LuaValue
function LLargeMapRenderer:invalidateChunk(cx, cy) end

function LLargeMapRenderer:isLodEnabled() end

---@param x LuaValue
---@param y LuaValue
---@param zoom LuaValue
function LLargeMapRenderer:setCamera(x, y, zoom) end

---@param size LuaValue
function LLargeMapRenderer:setChunkSize(size) end

---@param enabled LuaValue
function LLargeMapRenderer:setLodEnabled(enabled) end

---@param levels LuaValue
function LLargeMapRenderer:setLodThresholds(levels) end

---@param data LuaValue
---@param width LuaValue
---@param height LuaValue
function LLargeMapRenderer:setMapData(data, width, height) end

---@param x LuaValue
---@param y LuaValue
---@param tile_id LuaValue
function LLargeMapRenderer:setTile(x, y, tile_id) end

---@param cols LuaValue
function LLargeMapRenderer:setTilesetColumns(cols) end

---@param w LuaValue
---@param h LuaValue
function LLargeMapRenderer:setViewport(w, h) end

function LLargeMapRenderer:type() end

---@param name LuaValue
function LLargeMapRenderer:typeOf(name) end

---@class LMapBlock
LMapBlock = {}

function LMapBlock:getDimensions() end

function LMapBlock:getHeight() end

function LMapBlock:getHeightInSegments() end

function LMapBlock:getLayerCount() end

function LMapBlock:getName() end

function LMapBlock:getSegmentSize() end

---@param edge_str LuaValue
---@param segment LuaValue
function LMapBlock:getSide(edge_str, segment) end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
function LMapBlock:getTile(layer, x, y) end

function LMapBlock:getWeight() end

function LMapBlock:getWidth() end

function LMapBlock:getWidthInSegments() end

---@param name LuaValue
function LMapBlock:setName(name) end

---@param edge_str LuaValue
---@param segment LuaValue
---@param side_id LuaValue
function LMapBlock:setSide(edge_str, segment, side_id) end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
---@param gid LuaValue
function LMapBlock:setTile(layer, x, y, gid) end

---@param weight LuaValue
function LMapBlock:setWeight(weight) end

function LMapBlock:type() end

---@param name LuaValue
function LMapBlock:typeOf(name) end

---@class LMapGen
LMapGen = {}

---@param script_idx? LuaValue
---@param seed? LuaValue
---@param layer_name? LuaValue
function LMapGen:generate(script_idx, seed, layer_name) end

function LMapGen:type() end

---@param name LuaValue
function LMapGen:typeOf(name) end

---@class LMapGroup
LMapGroup = {}

---@param block_ud LuaValue
function LMapGroup:addBlock(block_ud) end

---@param script_ud LuaValue
function LMapGroup:addScript(script_ud) end

function LMapGroup:getBlockCount() end

function LMapGroup:getName() end

function LMapGroup:getScriptCount() end

---@param idx LuaValue
function LMapGroup:removeBlock(idx) end

function LMapGroup:type() end

---@param name LuaValue
function LMapGroup:typeOf(name) end

---@class LMapScript
LMapScript = {}

---@param step_def LuaValue
function LMapScript:addStep(step_def) end

function LMapScript:getStepCount() end

function LMapScript:type() end

---@param name LuaValue
function LMapScript:typeOf(name) end

---@class LTileMap
LTileMap = {}

---@param name LuaValue
---@param w LuaValue
---@param h LuaValue
function LTileMap:addLayer(name, w, h) end

---@param ts_ud LuaValue
function LTileMap:addTileSet(ts_ud) end

---@param layer LuaValue
---@param type_name LuaValue
function LTileMap:applyAutoTile(layer, type_name) end

---@param layer LuaValue
---@param type_name LuaValue
function LTileMap:applyAutoTile8(layer, type_name) end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
---@param type_name LuaValue
function LTileMap:applyAutoTile8At(layer, x, y, type_name) end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
---@param type_name LuaValue
function LTileMap:applyAutoTileAt(layer, x, y, type_name) end

---@param layer LuaValue
---@param entities LuaValue
function LTileMap:checkEntities(layer, entities) end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
function LTileMap:clearTile(layer, x, y) end

---@param tile_size LuaValue
function LTileMap:drawToImage(tile_size) end

---@param layer LuaValue
---@param gid LuaValue
function LTileMap:fill(layer, gid) end

---@param layer LuaValue
---@param gid LuaValue
function LTileMap:findTilesByGid(layer, gid) end

---@param gid LuaValue
---@param entity LuaValue
---@param tx LuaValue
---@param ty LuaValue
function LTileMap:fireTileExit(gid, entity, tx, ty) end

---@param gid LuaValue
---@param entity LuaValue
---@param tx LuaValue
---@param ty LuaValue
function LTileMap:fireTileStep(gid, entity, tx, ty) end

function LTileMap:getChunkSize() end

---@param idx LuaValue
function LTileMap:getLayerColor(idx) end

function LTileMap:getLayerCount() end

---@param idx LuaValue
function LTileMap:getLayerName(idx) end

---@param idx LuaValue
function LTileMap:getLayerOffset(idx) end

---@param idx LuaValue
function LTileMap:getLayerParallax(idx) end

---@param idx LuaValue
function LTileMap:getLayerVisible(idx) end

function LTileMap:getOrientation() end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
function LTileMap:getTile(layer, x, y) end

function LTileMap:getTileDimensions() end

function LTileMap:getTileHeight() end

---@param idx LuaValue
function LTileMap:getTileSet(idx) end

function LTileMap:getTileSetCount() end

function LTileMap:getTileWidth() end

function LTileMap:getViewport() end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
function LTileMap:isSolid(layer, x, y) end

---@param gid LuaValue
---@param func LuaValue
function LTileMap:onTileEnter(gid, func) end

---@param gid LuaValue
---@param func LuaValue
function LTileMap:onTileExit(gid, func) end

---@param gid LuaValue
---@param func LuaValue
function LTileMap:onTileStep(gid, func) end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LTileMap:rectOverlapsSolid(layer, x, y, w, h) end

---@param ox? LuaValue
---@param oy? LuaValue
function LTileMap:render(ox, oy) end

---@param idx LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LTileMap:setLayerColor(idx, r, g, b, a) end

---@param idx LuaValue
---@param ox LuaValue
---@param oy LuaValue
function LTileMap:setLayerOffset(idx, ox, oy) end

---@param idx LuaValue
---@param px LuaValue
---@param py LuaValue
function LTileMap:setLayerParallax(idx, px, py) end

---@param idx LuaValue
---@param visible LuaValue
function LTileMap:setLayerVisible(idx, visible) end

---@param orientation LuaValue
function LTileMap:setOrientation(orientation) end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
---@param gid LuaValue
function LTileMap:setTile(layer, x, y, gid) end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
---@param a LuaValue
function LTileMap:setTileTint(layer, x, y, r, g, b, a) end

---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
function LTileMap:setViewport(x, y, w, h) end

---@param layer LuaValue
---@param x LuaValue
---@param y LuaValue
---@param w LuaValue
---@param h LuaValue
---@param dx LuaValue
---@param dy LuaValue
function LTileMap:sweepRect(layer, x, y, w, h, dx, dy) end

---@param tx LuaValue
---@param ty LuaValue
function LTileMap:tileToWorld(tx, ty) end

---@param layer LuaValue
function LTileMap:tileTypeIndex(layer) end

---@param layer LuaValue
---@param gids_tbl LuaValue
function LTileMap:toNavGrid(layer, gids_tbl) end

function LTileMap:type() end

---@param name LuaValue
function LTileMap:typeOf(name) end

---@param dt LuaValue
function LTileMap:update(dt) end

---@param wx LuaValue
---@param wy LuaValue
function LTileMap:worldToTile(wx, wy) end

---@class LTileSet
LTileSet = {}

---@param tile_id LuaValue
function LTileSet:getAnimation(tile_id) end

---@param type_name LuaValue
---@param bitmask LuaValue
function LTileSet:getAutoTileId(type_name, bitmask) end

---@param type_name LuaValue
---@param bitmask LuaValue
function LTileSet:getAutoTileId8(type_name, bitmask) end

function LTileSet:getColumns() end

function LTileSet:getFirstGid() end

function LTileSet:getMargin() end

---@param tile_id LuaValue
function LTileSet:getQuad(tile_id) end

function LTileSet:getSpacing() end

function LTileSet:getTileCount() end

function LTileSet:getTileDimensions() end

function LTileSet:getTileHeight() end

function LTileSet:getTileWidth() end

---@param tile_id LuaValue
function LTileSet:isSolid(tile_id) end

---@param tile_id LuaValue
---@param frames LuaValue
function LTileSet:setAnimation(tile_id, frames) end

---@param type_name LuaValue
---@param bitmask LuaValue
---@param tile_id LuaValue
function LTileSet:setAutoTileRule(type_name, bitmask, tile_id) end

---@param type_name LuaValue
---@param bitmask LuaValue
---@param tile_id LuaValue
function LTileSet:setAutoTileRule8(type_name, bitmask, tile_id) end

---@param tile_id LuaValue
---@param solid LuaValue
function LTileSet:setSolid(tile_id, solid) end

function LTileSet:type() end

---@param name LuaValue
function LTileSet:typeOf(name) end

---@param json_str LuaValue
---@param level_name? LuaValue
lurek.tilemap.fromLDtk = function(json_str, level_name) end

---@param sx LuaValue
---@param sy LuaValue
---@param size LuaValue
lurek.tilemap.fromScreenHex = function(sx, sy, size) end

---@param sx LuaValue
---@param sy LuaValue
---@param tw LuaValue
---@param th LuaValue
lurek.tilemap.fromScreenIso = function(sx, sy, tw, th) end

---@param q LuaValue
---@param r LuaValue
---@param radius LuaValue
lurek.tilemap.hexArea = function(q, r, radius) end

---@param q1 LuaValue
---@param r1 LuaValue
---@param q2 LuaValue
---@param r2 LuaValue
lurek.tilemap.hexDistance = function(q1, r1, q2, r2) end

---@param q1 LuaValue
---@param r1 LuaValue
---@param q2 LuaValue
---@param r2 LuaValue
lurek.tilemap.hexLine = function(q1, r1, q2, r2) end

---@param q LuaValue
---@param r LuaValue
lurek.tilemap.hexNeighbors = function(q, r) end

---@param q LuaValue
---@param r LuaValue
---@param center_q LuaValue
---@param center_r LuaValue
---@param axis LuaValue
lurek.tilemap.hexReflect = function(q, r, center_q, center_r, axis) end

---@param q LuaValue
---@param r LuaValue
---@param radius LuaValue
lurek.tilemap.hexRing = function(q, r, radius) end

---@param q LuaValue
---@param r LuaValue
---@param center_q LuaValue
---@param center_r LuaValue
---@param steps LuaValue
lurek.tilemap.hexRotate = function(q, r, center_q, center_r, steps) end

---@param q LuaValue
---@param r LuaValue
lurek.tilemap.hexRound = function(q, r) end

---@param q LuaValue
---@param r LuaValue
---@param radius LuaValue
lurek.tilemap.hexSpiral = function(q, r, radius) end

---@param angle LuaValue
lurek.tilemap.isoDirectionFromAngle = function(angle) end

---@param direction LuaValue
lurek.tilemap.isoDirectionName = function(direction) end

---@param direction LuaValue
---@param steps LuaValue
lurek.tilemap.isoRotate = function(direction, steps) end

---@param xml LuaValue
lurek.tilemap.loadTMX = function(xml) end

---@param tile_w LuaValue
---@param tile_h LuaValue
---@param layout_str LuaValue
lurek.tilemap.newAutoTileSheet = function(tile_w, tile_h, layout_str) end

---@param chunk_size? LuaValue
lurek.tilemap.newChunkMap = function(chunk_size) end

lurek.tilemap.newIsoMap = function() end

---@param tile_w LuaValue
---@param tile_h LuaValue
lurek.tilemap.newLargeMapRenderer = function(tile_w, tile_h) end

---@param width LuaValue
---@param height LuaValue
---@param layers? LuaValue
---@param segment_size? LuaValue
lurek.tilemap.newMapBlock = function(width, height, layers, segment_size) end

lurek.tilemap.newMapGen = function() end

---@param name LuaValue
lurek.tilemap.newMapGroup = function(name) end

lurek.tilemap.newMapScript = function() end

---@param tile_width LuaValue
---@param tile_height LuaValue
---@param chunk_size? LuaValue
lurek.tilemap.newTileMap = function(tile_width, tile_height, chunk_size) end

lurek.tilemap.newTileSet = function() end

---@param q LuaValue
---@param r LuaValue
---@param size LuaValue
lurek.tilemap.toScreenHex = function(q, r, size) end

---@param tx LuaValue
---@param ty LuaValue
---@param tw LuaValue
---@param th LuaValue
lurek.tilemap.toScreenIso = function(tx, ty, tw, th) end

---@class lurek.timer
lurek.timer = {}

---@class LScheduler
LScheduler = {}

---@param delay LuaValue
---@param func LuaValue
function LScheduler:after(delay, func) end

---@param n LuaValue
---@param func LuaValue
function LScheduler:afterFrames(n, func) end

---@param name LuaValue
---@param delay LuaValue
---@param func LuaValue
function LScheduler:afterNamed(name, delay, func) end

---@param id LuaValue
function LScheduler:cancel(id) end

function LScheduler:cancelAll() end

---@param name LuaValue
function LScheduler:cancelNamed(name) end

---@param interval LuaValue
---@param func LuaValue
---@param count? LuaValue
function LScheduler:every(interval, func, count) end

---@param n LuaValue
---@param func LuaValue
---@param count? LuaValue
function LScheduler:everyFrames(n, func, count) end

---@param name LuaValue
---@param interval LuaValue
---@param func LuaValue
---@param count? LuaValue
function LScheduler:everyNamed(name, interval, func, count) end

function LScheduler:getCount() end

---@param id LuaValue
function LScheduler:getInterval(id) end

---@param id LuaValue
function LScheduler:getRemaining(id) end

---@param id LuaValue
function LScheduler:getRepeatCount(id) end

function LScheduler:getTimeScale() end

function LScheduler:isEmpty() end

---@param id LuaValue
function LScheduler:isPaused(id) end

---@param name LuaValue
function LScheduler:isPausedNamed(name) end

---@param id LuaValue
function LScheduler:pause(id) end

---@param name LuaValue
function LScheduler:pauseNamed(name) end

---@param id LuaValue
function LScheduler:resetEvent(id) end

---@param id LuaValue
function LScheduler:resume(id) end

---@param name LuaValue
function LScheduler:resumeNamed(name) end

---@param id LuaValue
---@param interval LuaValue
function LScheduler:setInterval(id, interval) end

---@param scale LuaValue
function LScheduler:setTimeScale(scale) end

function LScheduler:type() end

---@param name LuaValue
function LScheduler:typeOf(name) end

---@param dt LuaValue
function LScheduler:update(dt) end

function LScheduler:updateFrames() end

---@param delay LuaValue
---@param func LuaValue
lurek.timer.afterReal = function(delay, func) end

---@param steps LuaValue
lurek.timer.chain = function(steps) end

lurek.timer.getAverageDelta = function() end

lurek.timer.getDelta = function() end

lurek.timer.getFPS = function() end

lurek.timer.getFrameCount = function() end

lurek.timer.getMicroTime = function() end

lurek.timer.getPhysicsDelta = function() end

lurek.timer.getPhysicsMaxSteps = function() end

lurek.timer.getSmoothedDelta = function() end

lurek.timer.getTime = function() end

lurek.timer.newScheduler = function() end

---@param dt LuaValue
lurek.timer.setPhysicsDelta = function(dt) end

---@param n LuaValue
lurek.timer.setPhysicsMaxSteps = function(n) end

---@param alpha LuaValue
lurek.timer.setSmoothingFactor = function(alpha) end

---@param seconds LuaValue
lurek.timer.sleep = function(seconds) end

lurek.timer.step = function() end

lurek.timer.tickRealTimers = function() end

lurek.timer.tickWaits = function() end

---@param frames LuaValue
lurek.timer.waitFrames = function(frames) end

---@param seconds LuaValue
lurek.timer.waitSeconds = function(seconds) end

---@class lurek.tween
lurek.tween = {}

---@class LSpring
LSpring = {}

function LSpring:cancel() end

---@param field LuaValue
function LSpring:getPosition(field) end

function LSpring:isActive() end

function LSpring:isSettled() end

---@param value LuaValue
function LSpring:setDamping(value) end

---@param value LuaValue
function LSpring:setStiffness(value) end

---@param fields_tbl LuaValue
function LSpring:setTarget(fields_tbl) end

function LSpring:type() end

---@param name LuaValue
function LSpring:typeOf(name) end

---@param dt LuaValue
function LSpring:update(dt) end

---@class LTween
LTween = {}

---@param ud LuaValue
LTween.await = function(ud) end

---@param ud LuaValue
LTween.cancel = function(ud) end

function LTween:getDuration() end

function LTween:getElapsed() end

function LTween:getFields() end

function LTween:getProgress() end

function LTween:getRemaining() end

function LTween:isActive() end

---@param ud LuaValue
---@param f LuaValue
LTween.onCancel = function(ud, f) end

---@param ud LuaValue
---@param f LuaValue
LTween.onComplete = function(ud, f) end

---@param ud LuaValue
---@param f LuaValue
LTween.onUpdate = function(ud, f) end

function LTween:pause() end

---@param ud LuaValue
---@param enabled LuaValue
LTween.relative = function(ud, enabled) end

function LTween:resume() end

---@param enabled LuaValue
function LTween:setRelative(enabled) end

---@param n LuaValue
function LTween:setRepeat(n) end

---@param enabled LuaValue
function LTween:setYoyo(enabled) end

function LTween:type() end

---@param name LuaValue
function LTween:typeOf(name) end

---@class LTweenParallel
LTweenParallel = {}

---@param par_ud LuaValue
---@param tw_ud LuaValue
LTweenParallel.add = function(par_ud, tw_ud) end

function LTweenParallel:cancel() end

function LTweenParallel:isActive() end

---@param ud LuaValue
---@param f LuaValue
LTweenParallel.onComplete = function(ud, f) end

---@param ud LuaValue
LTweenParallel.start = function(ud) end

LTweenParallel.tween = function() end

function LTweenParallel:type() end

---@param name LuaValue
function LTweenParallel:typeOf(name) end

---@class LTweenSequence
LTweenSequence = {}

---@param ud LuaValue
LTweenSequence.await = function(ud) end

---@param ud LuaValue
---@param f LuaValue
LTweenSequence.callback = function(ud, f) end

function LTweenSequence:cancel() end

---@param ud LuaValue
---@param seconds LuaValue
---@param cb? LuaValue
LTweenSequence.delay = function(ud, seconds, cb) end

function LTweenSequence:getProgress() end

function LTweenSequence:isActive() end

---@param ud LuaValue
---@param f LuaValue
LTweenSequence.onComplete = function(ud, f) end

---@param ud LuaValue
LTweenSequence.start = function(ud) end

LTweenSequence.tween = function() end

function LTweenSequence:type() end

---@param name LuaValue
function LTweenSequence:typeOf(name) end

---@class LTweenState
---@field paused boolean  whether the tween is currently paused
LTweenState = {}

function LTweenState:isComplete() end

---@param start LuaValue
---@param finish LuaValue
function LTweenState:lerp(start, finish) end

function LTweenState:reset() end

function LTweenState:t() end

---@param dt LuaValue
function LTweenState:tick(dt) end

function LTweenState:type() end

---@param name LuaValue
function LTweenState:typeOf(name) end

lurek.tween.cancelAll = function() end

---@param seconds LuaValue
---@param cb? LuaValue
lurek.tween.delay = function(seconds, cb) end

lurek.tween.getActiveCount = function() end

lurek.tween.getEasingNames = function() end

---@param duration LuaValue
---@param easing? LuaValue
lurek.tween.newState = function(duration, easing) end

lurek.tween.parallel = function() end

---@param name LuaValue
---@param f LuaValue
lurek.tween.registerEasing = function(name, f) end

lurek.tween.sequence = function() end

---@param target_tbl LuaValue
---@param fields_tbl LuaValue
---@param opts? LuaValue
lurek.tween.spring = function(target_tbl, fields_tbl, opts) end

lurek.tween.to = function() end

lurek.tween.tween = function() end

---@param steps LuaValue
lurek.tween.tweenChain = function(steps) end

lurek.tween.tweenColor = function() end

---@param dt LuaValue
lurek.tween.update = function(dt) end

---@class lurek.ui
lurek.ui = {}

---@class LAccordion : LUiWidget
LAccordion = {}

--- /// Returns a value for addSection (auto-generated).
---@param title LuaValue
---@param content_idx? LuaValue
LAccordion.addSection = function(title, content_idx) end

--- /// Returns a value for getSectionCount (auto-generated).
LAccordion.getSectionCount = function() end

--- /// Returns a value for getSectionTitle (auto-generated).
---@param section_idx LuaValue
LAccordion.getSectionTitle = function(section_idx) end

--- /// Returns a value for isExclusive (auto-generated).
LAccordion.isExclusive = function() end

--- /// Returns a value for isSectionExpanded (auto-generated).
---@param section_idx LuaValue
LAccordion.isSectionExpanded = function(section_idx) end

--- /// Returns a value for setExclusive (auto-generated).
---@param v LuaValue
LAccordion.setExclusive = function(v) end

--- /// Returns a value for toggleSection (auto-generated).
---@param section_idx LuaValue
LAccordion.toggleSection = function(section_idx) end

---@class LAreaChart
LAreaChart = {}

---@param name LuaValue
---@param vals_tbl LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
function LAreaChart:addLayer(name, vals_tbl, r, g, b) end

function LAreaChart:drawToImage() end

---@param v LuaValue
function LAreaChart:setYMax(v) end

function LAreaChart:type() end

---@param name LuaValue
function LAreaChart:typeOf(name) end

---@class LBadge : LUiWidget
LBadge = {}

--- /// Returns a value for getCount (auto-generated).
LBadge.getCount = function() end

--- /// Returns a value for getDisplayText (auto-generated).
LBadge.getDisplayText = function() end

--- /// Returns a value for setCount (auto-generated).
---@param count LuaValue
LBadge.setCount = function(count) end

---@class LBarChart
LBarChart = {}

---@param label LuaValue
---@param vals_tbl LuaValue
function LBarChart:addCategory(label, vals_tbl) end

---@param name LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
function LBarChart:addSeries(name, r, g, b) end

function LBarChart:drawToImage() end

function LBarChart:type() end

---@param name LuaValue
function LBarChart:typeOf(name) end

---@class LButton : LUiWidget
LButton = {}

--- /// Returns a value for getText (auto-generated).
LButton.getText = function() end

--- /// Returns a value for setText (auto-generated).
---@param text LuaValue
LButton.setText = function(text) end

---@class LCheckbox : LUiWidget
LCheckbox = {}

--- /// Returns a value for getText (auto-generated).
LCheckbox.getText = function() end

--- /// Returns a value for isChecked (auto-generated).
LCheckbox.isChecked = function() end

--- /// Returns a value for setChecked (auto-generated).
---@param checked LuaValue
LCheckbox.setChecked = function(checked) end

--- /// Returns a value for setText (auto-generated).
---@param text LuaValue
LCheckbox.setText = function(text) end

---@class LColorPicker : LUiWidget
LColorPicker = {}

--- /// Returns a value for getColor (auto-generated).
LColorPicker.getColor = function() end

--- /// Returns a value for getColorMode (auto-generated).
LColorPicker.getColorMode = function() end

--- /// Returns a value for getShowAlpha (auto-generated).
LColorPicker.getShowAlpha = function() end

--- /// Returns a value for setColor (auto-generated).
---@param r LuaValue
---@param green LuaValue
---@param b LuaValue
---@param a? LuaValue
LColorPicker.setColor = function(r, green, b, a) end

--- /// Returns a value for setColorMode (auto-generated).
---@param mode LuaValue
LColorPicker.setColorMode = function(mode) end

--- /// Returns a value for setOnChange (auto-generated).
---@param f LuaValue
LColorPicker.setOnChange = function(f) end

--- /// Returns a value for setShowAlpha (auto-generated).
---@param v LuaValue
LColorPicker.setShowAlpha = function(v) end

---@class LComboBox : LUiWidget
LComboBox = {}

--- /// Returns a value for addItem (auto-generated).
---@param text LuaValue
LComboBox.addItem = function(text) end

--- /// Returns a value for clearItems (auto-generated).
LComboBox.clearItems = function() end

--- /// Returns a value for getItem (auto-generated).
---@param index LuaValue
LComboBox.getItem = function(index) end

--- /// Returns a value for getItemCount (auto-generated).
LComboBox.getItemCount = function() end

--- /// Returns a value for getSelectedIndex (auto-generated).
LComboBox.getSelectedIndex = function() end

--- /// Returns a value for getSelectedItem (auto-generated).
LComboBox.getSelectedItem = function() end

--- /// Returns a value for removeItem (auto-generated).
---@param index LuaValue
LComboBox.removeItem = function(index) end

--- /// Returns a value for setSelectedIndex (auto-generated).
---@param index LuaValue
LComboBox.setSelectedIndex = function(index) end

---@class LDialog : LUiWidget
LDialog = {}

--- /// Returns a value for addButton (auto-generated).
---@param text LuaValue
---@param cb? LuaValue
LDialog.addButton = function(text, cb) end

--- /// Returns a value for close (auto-generated).
LDialog.close = function() end

--- /// Returns a value for getContent (auto-generated).
LDialog.getContent = function() end

--- /// Returns a value for getTitle (auto-generated).
LDialog.getTitle = function() end

--- /// Returns a value for isModal (auto-generated).
LDialog.isModal = function() end

--- /// Returns a value for isOpen (auto-generated).
LDialog.isOpen = function() end

--- /// Returns a value for open (auto-generated).
LDialog.open = function() end

--- /// Returns a value for setContent (auto-generated).
---@param content_idx? LuaValue
LDialog.setContent = function(content_idx) end

--- /// Returns a value for setModal (auto-generated).
---@param v LuaValue
LDialog.setModal = function(v) end

--- /// Returns a value for setOnClose (auto-generated).
---@param f LuaValue
LDialog.setOnClose = function(f) end

--- /// Returns a value for setTitle (auto-generated).
---@param title LuaValue
LDialog.setTitle = function(title) end

---@class LDockPanel : LUiWidget
LDockPanel = {}

--- /// Returns a value for dock (auto-generated).
---@param child_idx LuaValue
---@param side LuaValue
LDockPanel.dock = function(child_idx, side) end

--- /// Returns a value for getDockedCount (auto-generated).
LDockPanel.getDockedCount = function() end

--- /// Returns a value for getSplitSize (auto-generated).
---@param side LuaValue
LDockPanel.getSplitSize = function(side) end

--- /// Returns a value for setSplitSize (auto-generated).
---@param side LuaValue
---@param size LuaValue
LDockPanel.setSplitSize = function(side, size) end

--- /// Returns a value for undock (auto-generated).
---@param child_idx LuaValue
LDockPanel.undock = function(child_idx) end

---@class LGuiTable : LUiWidget
LGuiTable = {}

--- /// Returns a value for addColumn (auto-generated).
---@param header LuaValue
---@param width? LuaValue
LGuiTable.addColumn = function(header, width) end

--- /// Returns a value for addRow (auto-generated).
---@param cells LuaValue
LGuiTable.addRow = function(cells) end

--- /// Returns a value for getCell (auto-generated).
---@param row LuaValue
---@param col LuaValue
LGuiTable.getCell = function(row, col) end

--- /// Returns a value for getColumnCount (auto-generated).
LGuiTable.getColumnCount = function() end

--- /// Returns a value for getRowCount (auto-generated).
LGuiTable.getRowCount = function() end

--- /// Returns a value for getSelectedRow (auto-generated).
LGuiTable.getSelectedRow = function() end

--- /// Returns a value for isSortable (auto-generated).
LGuiTable.isSortable = function() end

--- /// Returns a value for setCell (auto-generated).
---@param row LuaValue
---@param col LuaValue
---@param text LuaValue
LGuiTable.setCell = function(row, col, text) end

--- /// Returns a value for setOnSelect (auto-generated).
---@param f LuaValue
LGuiTable.setOnSelect = function(f) end

--- /// Returns a value for setSelectedRow (auto-generated).
---@param row? LuaValue
LGuiTable.setSelectedRow = function(row) end

--- /// Returns a value for setSortable (auto-generated).
---@param v LuaValue
LGuiTable.setSortable = function(v) end

---@class LGuiWindow : LUiWidget
LGuiWindow = {}

--- /// Returns a value for getTitle (auto-generated).
LGuiWindow.getTitle = function() end

--- /// Returns a value for isCloseable (auto-generated).
LGuiWindow.isCloseable = function() end

--- /// Returns a value for isDraggable (auto-generated).
LGuiWindow.isDraggable = function() end

--- /// Returns a value for isResizable (auto-generated).
LGuiWindow.isResizable = function() end

--- /// Returns a value for setCloseable (auto-generated).
---@param v LuaValue
LGuiWindow.setCloseable = function(v) end

--- /// Returns a value for setDraggable (auto-generated).
---@param v LuaValue
LGuiWindow.setDraggable = function(v) end

--- /// Returns a value for setOnClose (auto-generated).
---@param f LuaValue
LGuiWindow.setOnClose = function(f) end

--- /// Returns a value for setResizable (auto-generated).
---@param v LuaValue
LGuiWindow.setResizable = function(v) end

--- /// Returns a value for setTitle (auto-generated).
---@param title LuaValue
LGuiWindow.setTitle = function(title) end

---@class LImageWidget : LUiWidget
LImageWidget = {}

--- /// Returns a value for getScaleMode (auto-generated).
LImageWidget.getScaleMode = function() end

--- /// Returns a value for getTint (auto-generated).
LImageWidget.getTint = function() end

--- /// Returns a value for setScaleMode (auto-generated).
---@param mode LuaValue
LImageWidget.setScaleMode = function(mode) end

--- /// Returns a value for setTint (auto-generated).
---@param r LuaValue
---@param green LuaValue
---@param b LuaValue
---@param a? LuaValue
LImageWidget.setTint = function(r, green, b, a) end

---@class LLabel : LUiWidget
LLabel = {}

--- /// Returns a value for getText (auto-generated).
LLabel.getText = function() end

--- /// Returns a value for setText (auto-generated).
---@param text LuaValue
LLabel.setText = function(text) end

---@class LLayout : LUiWidget
LLayout = {}

--- /// Returns a value for getAlign (auto-generated).
LLayout.getAlign = function() end

--- /// Returns a value for getDirection (auto-generated).
LLayout.getDirection = function() end

--- /// Returns a value for getJustify (auto-generated).
LLayout.getJustify = function() end

--- /// Returns a value for getSpacing (auto-generated).
LLayout.getSpacing = function() end

--- /// Returns a value for getWrap (auto-generated).
LLayout.getWrap = function() end

--- /// Returns a value for setAlign (auto-generated).
---@param align LuaValue
LLayout.setAlign = function(align) end

--- /// Returns a value for setColumns (auto-generated).
---@param n LuaValue
LLayout.setColumns = function(n) end

--- /// Returns a value for setDirection (auto-generated).
---@param dir LuaValue
LLayout.setDirection = function(dir) end

--- /// Returns a value for setJustify (auto-generated).
---@param justify LuaValue
LLayout.setJustify = function(justify) end

--- /// Returns a value for setSpacing (auto-generated).
---@param spacing LuaValue
LLayout.setSpacing = function(spacing) end

--- /// Returns a value for setWrap (auto-generated).
---@param wrap LuaValue
LLayout.setWrap = function(wrap) end

---@class LLineChart
LLineChart = {}

---@param name LuaValue
---@param pts_tbl LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
function LLineChart:addSeries(name, pts_tbl, r, g, b) end

function LLineChart:drawToImage() end

---@param v LuaValue
function LLineChart:setXMax(v) end

---@param v LuaValue
function LLineChart:setYMax(v) end

function LLineChart:type() end

---@param name LuaValue
function LLineChart:typeOf(name) end

---@class LListBox : LUiWidget
LListBox = {}

--- /// Returns a value for addItem (auto-generated).
---@param text LuaValue
LListBox.addItem = function(text) end

--- /// Returns a value for clearItems (auto-generated).
LListBox.clearItems = function() end

--- /// Returns a value for getItem (auto-generated).
---@param index LuaValue
LListBox.getItem = function(index) end

--- /// Returns a value for getItemCount (auto-generated).
LListBox.getItemCount = function() end

--- /// Returns a value for getSelectedIndex (auto-generated).
LListBox.getSelectedIndex = function() end

--- /// Returns a value for removeItem (auto-generated).
---@param index LuaValue
LListBox.removeItem = function(index) end

--- /// Returns a value for setItemHeight (auto-generated).
---@param h LuaValue
LListBox.setItemHeight = function(h) end

--- /// Returns a value for setSelectedIndex (auto-generated).
---@param index LuaValue
LListBox.setSelectedIndex = function(index) end

---@class LMenuBar : LUiWidget
LMenuBar = {}

--- /// Returns a value for addMenu (auto-generated).
---@param menu_idx LuaValue
LMenuBar.addMenu = function(menu_idx) end

--- /// Returns a value for getMenuCount (auto-generated).
LMenuBar.getMenuCount = function() end

--- /// Returns a value for getMenus (auto-generated).
LMenuBar.getMenus = function() end

--- /// Returns a value for removeMenu (auto-generated).
---@param menu_idx LuaValue
LMenuBar.removeMenu = function(menu_idx) end

---@class LMenuItem : LUiWidget
LMenuItem = {}

--- /// Returns a value for addSubItem (auto-generated).
---@param child_idx LuaValue
LMenuItem.addSubItem = function(child_idx) end

--- /// Returns a value for getShortcut (auto-generated).
LMenuItem.getShortcut = function() end

--- /// Returns a value for getSubItems (auto-generated).
LMenuItem.getSubItems = function() end

--- /// Returns a value for getText (auto-generated).
LMenuItem.getText = function() end

--- /// Returns a value for isChecked (auto-generated).
LMenuItem.isChecked = function() end

--- /// Returns a value for setChecked (auto-generated).
---@param v LuaValue
LMenuItem.setChecked = function(v) end

--- /// Returns a value for setOnClick (auto-generated).
---@param f LuaValue
LMenuItem.setOnClick = function(f) end

--- /// Returns a value for setShortcut (auto-generated).
---@param shortcut LuaValue
LMenuItem.setShortcut = function(shortcut) end

--- /// Returns a value for setText (auto-generated).
---@param text LuaValue
LMenuItem.setText = function(text) end

---@class LNinePatch : LUiWidget
LNinePatch = {}

--- /// Returns a value for getImageDimensions (auto-generated).
LNinePatch.getImageDimensions = function() end

--- /// Returns a value for getInsets (auto-generated).
LNinePatch.getInsets = function() end

--- /// Returns a value for getSlices (auto-generated).
LNinePatch.getSlices = function() end

--- /// Returns a value for setImageDimensions (auto-generated).
---@param w LuaValue
---@param h LuaValue
LNinePatch.setImageDimensions = function(w, h) end

--- /// Returns a value for setInsets (auto-generated).
---@param left LuaValue
---@param top LuaValue
---@param right LuaValue
---@param bottom LuaValue
LNinePatch.setInsets = function(left, top, right, bottom) end

---@class LPanel : LUiWidget
LPanel = {}

--- /// Returns a value for getTitle (auto-generated).
LPanel.getTitle = function() end

--- /// Returns a value for setScrollable (auto-generated).
---@param scrollable LuaValue
LPanel.setScrollable = function(scrollable) end

--- /// Returns a value for setTitle (auto-generated).
---@param title LuaValue
LPanel.setTitle = function(title) end

---@class LPieChart
LPieChart = {}

---@param label LuaValue
---@param value LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
function LPieChart:addSegment(label, value, r, g, b) end

function LPieChart:drawToImage() end

function LPieChart:type() end

---@param name LuaValue
function LPieChart:typeOf(name) end

---@class LProgressBar : LUiWidget
LProgressBar = {}

--- /// Returns a value for getMax (auto-generated).
LProgressBar.getMax = function() end

--- /// Returns a value for getMin (auto-generated).
LProgressBar.getMin = function() end

--- /// Returns a value for getProgress (auto-generated).
LProgressBar.getProgress = function() end

--- /// Returns a value for getValue (auto-generated).
LProgressBar.getValue = function() end

--- /// Returns a value for setRange (auto-generated).
---@param min LuaValue
---@param max LuaValue
LProgressBar.setRange = function(min, max) end

--- /// Returns a value for setValue (auto-generated).
---@param v LuaValue
LProgressBar.setValue = function(v) end

---@class LRadioButton : LUiWidget
LRadioButton = {}

--- /// Returns a value for getGroup (auto-generated).
LRadioButton.getGroup = function() end

--- /// Returns a value for getText (auto-generated).
LRadioButton.getText = function() end

--- /// Returns a value for isSelected (auto-generated).
LRadioButton.isSelected = function() end

--- /// Returns a value for setGroup (auto-generated).
---@param group LuaValue
LRadioButton.setGroup = function(group) end

--- /// Returns a value for setOnChange (auto-generated).
---@param f LuaValue
LRadioButton.setOnChange = function(f) end

--- /// Returns a value for setSelected (auto-generated).
---@param v LuaValue
LRadioButton.setSelected = function(v) end

--- /// Returns a value for setText (auto-generated).
---@param text LuaValue
LRadioButton.setText = function(text) end

---@class LScatterPlot
LScatterPlot = {}

---@param name LuaValue
---@param pts_tbl LuaValue
---@param r LuaValue
---@param g LuaValue
---@param b LuaValue
function LScatterPlot:addSeries(name, pts_tbl, r, g, b) end

function LScatterPlot:drawToImage() end

---@param mn LuaValue
---@param mx LuaValue
function LScatterPlot:setXRange(mn, mx) end

---@param mn LuaValue
---@param mx LuaValue
function LScatterPlot:setYRange(mn, mx) end

function LScatterPlot:type() end

---@param name LuaValue
function LScatterPlot:typeOf(name) end

---@class LScrollBar : LUiWidget
LScrollBar = {}

--- /// Returns a value for getContentSize (auto-generated).
LScrollBar.getContentSize = function() end

--- /// Returns a value for getScrollPosition (auto-generated).
LScrollBar.getScrollPosition = function() end

--- /// Returns a value for getViewSize (auto-generated).
LScrollBar.getViewSize = function() end

--- /// Returns a value for isVertical (auto-generated).
LScrollBar.isVertical = function() end

--- /// Returns a value for setContentSize (auto-generated).
---@param v LuaValue
LScrollBar.setContentSize = function(v) end

--- /// Returns a value for setOnChange (auto-generated).
---@param f LuaValue
LScrollBar.setOnChange = function(f) end

--- /// Returns a value for setScrollPosition (auto-generated).
---@param v LuaValue
LScrollBar.setScrollPosition = function(v) end

--- /// Returns a value for setViewSize (auto-generated).
---@param v LuaValue
LScrollBar.setViewSize = function(v) end

---@class LScrollPanel : LUiWidget
LScrollPanel = {}

--- /// Returns a value for getContentSize (auto-generated).
LScrollPanel.getContentSize = function() end

--- /// Returns a value for getMaxScroll (auto-generated).
LScrollPanel.getMaxScroll = function() end

--- /// Returns a value for getScrollPosition (auto-generated).
LScrollPanel.getScrollPosition = function() end

--- /// Returns a value for getScrollSpeed (auto-generated).
LScrollPanel.getScrollSpeed = function() end

--- /// Returns a value for setContentSize (auto-generated).
---@param w LuaValue
---@param h LuaValue
LScrollPanel.setContentSize = function(w, h) end

--- /// Returns a value for setScrollPosition (auto-generated).
---@param x LuaValue
---@param y LuaValue
LScrollPanel.setScrollPosition = function(x, y) end

--- /// Returns a value for setScrollSpeed (auto-generated).
---@param speed LuaValue
LScrollPanel.setScrollSpeed = function(speed) end

---@class LSeparator : LUiWidget
LSeparator = {}

--- /// Returns a value for getThickness (auto-generated).
LSeparator.getThickness = function() end

--- /// Returns a value for isVertical (auto-generated).
LSeparator.isVertical = function() end

--- /// Returns a value for setThickness (auto-generated).
---@param thickness LuaValue
LSeparator.setThickness = function(thickness) end

--- /// Returns a value for setVertical (auto-generated).
---@param v LuaValue
LSeparator.setVertical = function(v) end

---@class LSlider : LUiWidget
LSlider = {}

--- /// Returns a value for getMax (auto-generated).
LSlider.getMax = function() end

--- /// Returns a value for getMin (auto-generated).
LSlider.getMin = function() end

--- /// Returns a value for getValue (auto-generated).
LSlider.getValue = function() end

--- /// Returns a value for setRange (auto-generated).
---@param min LuaValue
---@param max LuaValue
LSlider.setRange = function(min, max) end

--- /// Returns a value for setStep (auto-generated).
---@param step LuaValue
LSlider.setStep = function(step) end

--- /// Returns a value for setValue (auto-generated).
---@param v LuaValue
LSlider.setValue = function(v) end

---@class LSpinBox : LUiWidget
LSpinBox = {}

--- /// Returns a value for decrement (auto-generated).
LSpinBox.decrement = function() end

--- /// Returns a value for getValue (auto-generated).
LSpinBox.getValue = function() end

--- /// Returns a value for increment (auto-generated).
LSpinBox.increment = function() end

--- /// Returns a value for setRange (auto-generated).
---@param min LuaValue
---@param max LuaValue
LSpinBox.setRange = function(min, max) end

--- /// Returns a value for setStep (auto-generated).
---@param step LuaValue
LSpinBox.setStep = function(step) end

--- /// Returns a value for setValue (auto-generated).
---@param v LuaValue
LSpinBox.setValue = function(v) end

---@class LSplitPanel : LUiWidget
LSplitPanel = {}

--- /// Returns a value for getFirstChild (auto-generated).
LSplitPanel.getFirstChild = function() end

--- /// Returns a value for getMinPanelSize (auto-generated).
LSplitPanel.getMinPanelSize = function() end

--- /// Returns a value for getOrientation (auto-generated).
LSplitPanel.getOrientation = function() end

--- /// Returns a value for getSecondChild (auto-generated).
LSplitPanel.getSecondChild = function() end

--- /// Returns a value for getSplitPosition (auto-generated).
LSplitPanel.getSplitPosition = function() end

--- /// Returns a value for setFirstChild (auto-generated).
---@param child_idx LuaValue
LSplitPanel.setFirstChild = function(child_idx) end

--- /// Returns a value for setMinPanelSize (auto-generated).
---@param v LuaValue
LSplitPanel.setMinPanelSize = function(v) end

--- /// Returns a value for setOrientation (auto-generated).
---@param v LuaValue
LSplitPanel.setOrientation = function(v) end

--- /// Returns a value for setSecondChild (auto-generated).
---@param child_idx LuaValue
LSplitPanel.setSecondChild = function(child_idx) end

--- /// Returns a value for setSplitPosition (auto-generated).
---@param v LuaValue
LSplitPanel.setSplitPosition = function(v) end

---@class LStatusBar : LUiWidget
LStatusBar = {}

--- /// Returns a value for addSection (auto-generated).
---@param text LuaValue
---@param width? LuaValue
LStatusBar.addSection = function(text, width) end

--- /// Returns a value for getSectionCount (auto-generated).
LStatusBar.getSectionCount = function() end

--- /// Returns a value for getSectionText (auto-generated).
---@param section_idx LuaValue
LStatusBar.getSectionText = function(section_idx) end

--- /// Returns a value for setSectionCount (auto-generated).
---@param count LuaValue
LStatusBar.setSectionCount = function(count) end

--- /// Returns a value for setSectionText (auto-generated).
---@param section_idx LuaValue
---@param text LuaValue
LStatusBar.setSectionText = function(section_idx, text) end

--- /// Returns a value for setSectionWidget (auto-generated).
---@param section_idx LuaValue
---@param widget LuaValue
LStatusBar.setSectionWidget = function(section_idx, widget) end

---@class LSwitch : LUiWidget
LSwitch = {}

--- /// Returns a value for isOn (auto-generated).
LSwitch.isOn = function() end

--- /// Returns a value for setOn (auto-generated).
---@param on LuaValue
LSwitch.setOn = function(on) end

--- /// Returns a value for toggle (auto-generated).
LSwitch.toggle = function() end

---@class LTabBar : LUiWidget
LTabBar = {}

--- /// Returns a value for addTab (auto-generated).
---@param label LuaValue
LTabBar.addTab = function(label) end

--- /// Returns a value for getActiveTab (auto-generated).
LTabBar.getActiveTab = function() end

--- /// Returns a value for getTab (auto-generated).
---@param index LuaValue
LTabBar.getTab = function(index) end

--- /// Returns a value for getTabCount (auto-generated).
LTabBar.getTabCount = function() end

--- /// Returns a value for removeTab (auto-generated).
---@param index LuaValue
LTabBar.removeTab = function(index) end

--- /// Returns a value for setActiveTab (auto-generated).
---@param index LuaValue
LTabBar.setActiveTab = function(index) end

---@class LTextInput : LUiWidget
LTextInput = {}

--- /// Returns a value for getCursorPosition (auto-generated).
LTextInput.getCursorPosition = function() end

--- /// Returns a value for getPlaceholder (auto-generated).
LTextInput.getPlaceholder = function() end

--- /// Returns a value for getText (auto-generated).
LTextInput.getText = function() end

--- /// Returns a value for isFocused (auto-generated).
LTextInput.isFocused = function() end

--- /// Returns a value for setMaxLength (auto-generated).
---@param n LuaValue
LTextInput.setMaxLength = function(n) end

--- /// Returns a value for setPlaceholder (auto-generated).
---@param text LuaValue
LTextInput.setPlaceholder = function(text) end

--- /// Returns a value for setText (auto-generated).
---@param text LuaValue
LTextInput.setText = function(text) end

---@class LTheme
LTheme = {}

---@param widget_type LuaValue
---@param state LuaValue
---@param style_table LuaValue
function LTheme:setStyle(widget_type, state, style_table) end

function LTheme:type() end

---@param name LuaValue
function LTheme:typeOf(name) end

---@class LToast : LUiWidget
LToast = {}

--- /// Returns a value for getDuration (auto-generated).
LToast.getDuration = function() end

--- /// Returns a value for getMessage (auto-generated).
LToast.getMessage = function() end

--- /// Returns a value for getProgress (auto-generated).
LToast.getProgress = function() end

--- /// Returns a value for isExpired (auto-generated).
LToast.isExpired = function() end

--- /// Returns a value for setDuration (auto-generated).
---@param d LuaValue
LToast.setDuration = function(d) end

--- /// Returns a value for setMessage (auto-generated).
---@param msg LuaValue
LToast.setMessage = function(msg) end

---@class LToolbar : LUiWidget
LToolbar = {}

--- /// Returns a value for addButton (auto-generated).
---@param id LuaValue
---@param tooltip? LuaValue
LToolbar.addButton = function(id, tooltip) end

--- /// Returns a value for addSeparator (auto-generated).
LToolbar.addSeparator = function() end

--- /// Returns a value for addSpacer (auto-generated).
---@param size? LuaValue
LToolbar.addSpacer = function(size) end

--- /// Returns a value for getButton (auto-generated).
---@param id LuaValue
LToolbar.getButton = function(id) end

--- /// Returns a value for getOrientation (auto-generated).
LToolbar.getOrientation = function() end

--- /// Returns a value for isButtonToggled (auto-generated).
---@param id LuaValue
LToolbar.isButtonToggled = function(id) end

--- /// Returns a value for setButtonEnabled (auto-generated).
---@param id LuaValue
---@param enabled LuaValue
LToolbar.setButtonEnabled = function(id, enabled) end

--- /// Returns a value for setButtonToggled (auto-generated).
---@param id LuaValue
---@param toggled LuaValue
LToolbar.setButtonToggled = function(id, toggled) end

--- /// Returns a value for setOrientation (auto-generated).
---@param v LuaValue
LToolbar.setOrientation = function(v) end

---@class LTooltipPanel : LUiWidget
LTooltipPanel = {}

--- /// Returns a value for getDelay (auto-generated).
LTooltipPanel.getDelay = function() end

--- /// Returns a value for getTarget (auto-generated).
LTooltipPanel.getTarget = function() end

--- /// Returns a value for getText (auto-generated).
LTooltipPanel.getText = function() end

--- /// Returns a value for setDelay (auto-generated).
---@param v LuaValue
LTooltipPanel.setDelay = function(v) end

--- /// Returns a value for setTarget (auto-generated).
---@param target? LuaValue
LTooltipPanel.setTarget = function(target) end

--- /// Returns a value for setText (auto-generated).
---@param text LuaValue
LTooltipPanel.setText = function(text) end

---@class LTreeView : LUiWidget
LTreeView = {}

--- /// Returns a value for addNode (auto-generated).
---@param text LuaValue
---@param parent_index? LuaValue
LTreeView.addNode = function(text, parent_index) end

--- /// Returns a value for clearNodes (auto-generated).
LTreeView.clearNodes = function() end

--- /// Returns a value for collapseAll (auto-generated).
LTreeView.collapseAll = function() end

--- /// Returns a value for collapseNode (auto-generated).
---@param index LuaValue
LTreeView.collapseNode = function(index) end

--- /// Returns a value for expandAll (auto-generated).
LTreeView.expandAll = function() end

--- /// Returns a value for expandNode (auto-generated).
---@param index LuaValue
LTreeView.expandNode = function(index) end

--- /// Returns a value for getChildNodes (auto-generated).
---@param index LuaValue
LTreeView.getChildNodes = function(index) end

--- /// Returns a value for getNodeCount (auto-generated).
LTreeView.getNodeCount = function() end

--- /// Returns a value for getNodeDepth (auto-generated).
---@param index LuaValue
LTreeView.getNodeDepth = function(index) end

--- /// Returns a value for getNodeText (auto-generated).
---@param index LuaValue
LTreeView.getNodeText = function(index) end

--- /// Returns a value for getParentNode (auto-generated).
---@param index LuaValue
LTreeView.getParentNode = function(index) end

--- /// Returns a value for getSelectedNode (auto-generated).
LTreeView.getSelectedNode = function() end

--- /// Returns a value for isExpanded (auto-generated).
---@param index LuaValue
LTreeView.isExpanded = function(index) end

--- /// Returns a value for isNodeExpanded (auto-generated).
---@param index LuaValue
LTreeView.isNodeExpanded = function(index) end

--- /// Returns a value for removeNode (auto-generated).
---@param index LuaValue
LTreeView.removeNode = function(index) end

--- /// Returns a value for setNodeIcon (auto-generated).
---@param index LuaValue
---@param icon LuaValue
LTreeView.setNodeIcon = function(index, icon) end

--- /// Returns a value for setNodeText (auto-generated).
---@param index LuaValue
---@param text LuaValue
LTreeView.setNodeText = function(index, text) end

--- /// Returns a value for setSelectedNode (auto-generated).
---@param index LuaValue
LTreeView.setSelectedNode = function(index) end

--- /// Returns a value for toggleNode (auto-generated).
---@param index LuaValue
LTreeView.toggleNode = function(index) end

---@class LUiWidget
LUiWidget = {}

--- /// Returns a value for addChild (auto-generated).
---@param child LuaValue
LUiWidget.addChild = function(child) end

--- /// Returns a value for animateAlpha (auto-generated).
---@param target LuaValue
---@param duration? LuaValue
---@param hide_on_complete? LuaValue
LUiWidget.animateAlpha = function(target, duration, hide_on_complete) end

--- /// Returns a value for animatePosition (auto-generated).
---@param x LuaValue
---@param y LuaValue
---@param duration? LuaValue
LUiWidget.animatePosition = function(x, y, duration) end

--- /// Returns a value for attachToEntity (auto-generated).
---@param entity_id LuaValue
LUiWidget.attachToEntity = function(entity_id) end

--- /// Returns a value for bind (auto-generated).
---@param key LuaValue
LUiWidget.bind = function(key) end

--- /// Returns a value for cancelAnimations (auto-generated).
LUiWidget.cancelAnimations = function() end

--- /// Returns a value for clearAnchor (auto-generated).
LUiWidget.clearAnchor = function() end

--- /// Returns a value for containsPoint (auto-generated).
---@param x LuaValue
---@param y LuaValue
LUiWidget.containsPoint = function(x, y) end

--- /// Returns a value for detachFromEntity (auto-generated).
LUiWidget.detachFromEntity = function() end

--- /// Returns a value for fadeIn (auto-generated).
LUiWidget.fadeIn = function() end

--- /// Returns a value for fadeOut (auto-generated).
LUiWidget.fadeOut = function() end

--- /// Returns a value for findById (auto-generated).
---@param id LuaValue
LUiWidget.findById = function(id) end

--- /// Returns a value for getAlpha (auto-generated).
LUiWidget.getAlpha = function() end

--- /// Returns a value for getChildCount (auto-generated).
LUiWidget.getChildCount = function() end

--- /// Returns a value for getChildren (auto-generated).
LUiWidget.getChildren = function() end

--- /// Returns a value for getFlexGrow (auto-generated).
LUiWidget.getFlexGrow = function() end

--- /// Returns a value for getFlexShrink (auto-generated).
LUiWidget.getFlexShrink = function() end

--- /// Returns a value for getId (auto-generated).
LUiWidget.getId = function() end

--- /// Returns a value for getMargin (auto-generated).
LUiWidget.getMargin = function() end

--- /// Returns a value for getMaxSize (auto-generated).
LUiWidget.getMaxSize = function() end

--- /// Returns a value for getMinSize (auto-generated).
LUiWidget.getMinSize = function() end

--- /// Returns a value for getPadding (auto-generated).
LUiWidget.getPadding = function() end

--- /// Returns a value for getPosition (auto-generated).
LUiWidget.getPosition = function() end

--- /// Returns a value for getRect (auto-generated).
LUiWidget.getRect = function() end

--- /// Returns a value for getSize (auto-generated).
LUiWidget.getSize = function() end

--- /// Returns a value for getState (auto-generated).
LUiWidget.getState = function() end

--- /// Returns a value for getTooltip (auto-generated).
LUiWidget.getTooltip = function() end

--- /// Returns a value for getZOrder (auto-generated).
LUiWidget.getZOrder = function() end

--- /// Returns a value for isAnimating (auto-generated).
LUiWidget.isAnimating = function() end

--- /// Returns a value for isEnabled (auto-generated).
LUiWidget.isEnabled = function() end

--- /// Returns a value for isVisible (auto-generated).
LUiWidget.isVisible = function() end

--- /// Returns a value for removeChild (auto-generated).
---@param child LuaValue
LUiWidget.removeChild = function(child) end

--- /// Returns a value for setAlpha (auto-generated).
---@param alpha LuaValue
LUiWidget.setAlpha = function(alpha) end

--- /// Returns a value for setAnchor (auto-generated).
LUiWidget.setAnchor = function() end

--- /// Returns a value for setAnchorCenter (auto-generated).
---@param cx? LuaValue
---@param cy? LuaValue
LUiWidget.setAnchorCenter = function(cx, cy) end

--- /// Returns a value for setEnabled (auto-generated).
---@param v LuaValue
LUiWidget.setEnabled = function(v) end

--- /// Returns a value for setFlexGrow (auto-generated).
---@param grow LuaValue
LUiWidget.setFlexGrow = function(grow) end

--- /// Returns a value for setFlexShrink (auto-generated).
---@param shrink LuaValue
LUiWidget.setFlexShrink = function(shrink) end

--- /// Returns a value for setId (auto-generated).
---@param id LuaValue
LUiWidget.setId = function(id) end

--- /// Returns a value for setMargin (auto-generated).
---@param top LuaValue
---@param right? LuaValue
---@param bottom? LuaValue
---@param left? LuaValue
LUiWidget.setMargin = function(top, right, bottom, left) end

--- /// Returns a value for setMaxSize (auto-generated).
---@param w LuaValue
---@param h LuaValue
LUiWidget.setMaxSize = function(w, h) end

--- /// Returns a value for setMinSize (auto-generated).
---@param w LuaValue
---@param h LuaValue
LUiWidget.setMinSize = function(w, h) end

--- /// Returns a value for setOnChange (auto-generated).
---@param f LuaValue
LUiWidget.setOnChange = function(f) end

--- /// Returns a value for setOnClick (auto-generated).
---@param f LuaValue
LUiWidget.setOnClick = function(f) end

--- /// Returns a value for setOnDraw (auto-generated).
---@param self LuaValue
---@param f LuaValue
LUiWidget.setOnDraw = function(self, f) end

--- /// Returns a value for setPadding (auto-generated).
---@param top LuaValue
---@param right? LuaValue
---@param bottom? LuaValue
---@param left? LuaValue
LUiWidget.setPadding = function(top, right, bottom, left) end

--- /// Returns a value for setPosition (auto-generated).
---@param x LuaValue
---@param y LuaValue
LUiWidget.setPosition = function(x, y) end

--- /// Returns a value for setSize (auto-generated).
---@param w LuaValue
---@param h LuaValue
LUiWidget.setSize = function(w, h) end

--- /// Returns a value for setTooltip (auto-generated).
---@param text LuaValue
LUiWidget.setTooltip = function(text) end

--- /// Returns a value for setVisible (auto-generated).
---@param v LuaValue
LUiWidget.setVisible = function(v) end

--- /// Returns a value for setZOrder (auto-generated).
---@param z LuaValue
LUiWidget.setZOrder = function(z) end

--- /// Returns a value for slideIn (auto-generated).
---@param x LuaValue
---@param y LuaValue
LUiWidget.slideIn = function(x, y) end

--- /// Returns a value for slideOut (auto-generated).
---@param x LuaValue
---@param y LuaValue
LUiWidget.slideOut = function(x, y) end

--- /// Returns a value for type (auto-generated).
LUiWidget.type = function() end

--- /// Returns a value for typeOf (auto-generated).
---@param name LuaValue
LUiWidget.typeOf = function(name) end

--- /// Returns a value for unbind (auto-generated).
LUiWidget.unbind = function() end

---@param toast_table LuaValue
lurek.ui.addToast = function(toast_table) end

---@param widget LuaValue
lurek.ui.beginDrag = function(widget) end

lurek.ui.clearFocus = function() end

lurek.ui.draw = function() end

---@param w LuaValue
---@param h LuaValue
lurek.ui.drawToImage = function(w, h) end

---@param target LuaValue
lurek.ui.dropOn = function(target) end

lurek.ui.endDrag = function() end

lurek.ui.flushCache = function() end

lurek.ui.focusNext = function() end

lurek.ui.focusPrev = function() end

lurek.ui.getActiveDrag = function() end

lurek.ui.getFocus = function() end

lurek.ui.getRoot = function() end

lurek.ui.getTheme = function() end

lurek.ui.getToastCount = function() end

lurek.ui.getWidgetCount = function() end

---@param key LuaValue
lurek.ui.keypressed = function(key) end

lurek.ui.loadLayout = function() end

---@param path LuaValue
lurek.ui.loadLayoutFile = function(path) end

---@param x LuaValue
---@param y LuaValue
lurek.ui.mousemoved = function(x, y) end

---@param x LuaValue
---@param y LuaValue
---@param btn? LuaValue
lurek.ui.mousepressed = function(x, y, btn) end

---@param x LuaValue
---@param y LuaValue
---@param btn? LuaValue
lurek.ui.mousereleased = function(x, y, btn) end

lurek.ui.newAccordion = function() end

---@param opts LuaValue
lurek.ui.newAreaChart = function(opts) end

---@param count? LuaValue
lurek.ui.newBadge = function(count) end

---@param opts LuaValue
lurek.ui.newBarChart = function(opts) end

---@param text? LuaValue
lurek.ui.newButton = function(text) end

---@param text? LuaValue
lurek.ui.newCheckbox = function(text) end

lurek.ui.newColorPicker = function() end

lurek.ui.newComboBox = function() end

---@param config? LuaValue
lurek.ui.newCustomWidget = function(config) end

---@param title? LuaValue
lurek.ui.newDialog = function(title) end

lurek.ui.newDockPanel = function() end

lurek.ui.newImageWidget = function() end

---@param text? LuaValue
lurek.ui.newLabel = function(text) end

---@param direction? LuaValue
lurek.ui.newLayout = function(direction) end

---@param opts LuaValue
lurek.ui.newLineChart = function(opts) end

lurek.ui.newList = function() end

lurek.ui.newMenuBar = function() end

---@param text? LuaValue
lurek.ui.newMenuItem = function(text) end

lurek.ui.newNinePatch = function() end

lurek.ui.newPanel = function() end

---@param opts LuaValue
lurek.ui.newPieChart = function(opts) end

---@param min? LuaValue
---@param max? LuaValue
lurek.ui.newProgressBar = function(min, max) end

---@param text? LuaValue
---@param group? LuaValue
lurek.ui.newRadioButton = function(text, group) end

---@param opts LuaValue
lurek.ui.newScatterPlot = function(opts) end

---@param vertical? LuaValue
lurek.ui.newScrollBar = function(vertical) end

lurek.ui.newScrollPanel = function() end

---@param vertical? LuaValue
lurek.ui.newSeparator = function(vertical) end

---@param min? LuaValue
---@param max? LuaValue
lurek.ui.newSlider = function(min, max) end

---@param w? LuaValue
---@param h? LuaValue
lurek.ui.newSpacer = function(w, h) end

---@param min? LuaValue
---@param max? LuaValue
lurek.ui.newSpinBox = function(min, max) end

---@param orientation? LuaValue
lurek.ui.newSplitPanel = function(orientation) end

lurek.ui.newStatusBar = function() end

---@param on? LuaValue
lurek.ui.newSwitch = function(on) end

lurek.ui.newTabBar = function() end

lurek.ui.newTable = function() end

lurek.ui.newTextInput = function() end

lurek.ui.newTheme = function() end

---@param message? LuaValue
---@param duration? LuaValue
lurek.ui.newToast = function(message, duration) end

---@param orientation? LuaValue
lurek.ui.newToolbar = function(orientation) end

---@param text? LuaValue
lurek.ui.newTooltipPanel = function(text) end

lurek.ui.newTreeView = function() end

---@param title? LuaValue
lurek.ui.newWindow = function(title) end

---@param state LuaValue
lurek.ui.parseWidgetState = function(state) end

---@param width LuaValue
---@param height LuaValue
---@param path LuaValue
lurek.ui.renderToImage = function(width, height, path) end

lurek.ui.setDefaultTheme = function() end

---@param widget? LuaValue
lurek.ui.setFocus = function(widget) end

---@param theme_ud LuaValue
lurek.ui.setTheme = function(theme_ud) end

---@param w LuaValue
---@param h LuaValue
lurek.ui.setViewport = function(w, h) end

---@param text LuaValue
lurek.ui.textinput = function(text) end

---@param dt LuaValue
lurek.ui.update = function(dt) end

lurek.ui.update_bindings = function() end

---@param x LuaValue
---@param y LuaValue
lurek.ui.wheelmoved = function(x, y) end

---@class lurek.window
lurek.window = {}

lurek.window.close = function() end

lurek.window.flash = function() end

lurek.window.focus = function() end

---@param value LuaValue
lurek.window.fromPixels = function(value) end

lurek.window.getCurrentDisplay = function() end

lurek.window.getDPIScale = function() end

---@param display? LuaValue
lurek.window.getDesktopDimensions = function(display) end

lurek.window.getDimensions = function() end

lurek.window.getDisplayCount = function() end

---@param display? LuaValue
lurek.window.getDisplayName = function(display) end

lurek.window.getDisplayOrientation = function() end

lurek.window.getDisplays = function() end

lurek.window.getFullscreen = function() end

lurek.window.getFullscreenModes = function() end

lurek.window.getGameHeight = function() end

lurek.window.getGameWidth = function() end

lurek.window.getHeight = function() end

lurek.window.getMode = function() end

lurek.window.getNativeDPIScale = function() end

lurek.window.getPixelDimensions = function() end

lurek.window.getPosition = function() end

lurek.window.getSafeArea = function() end

lurek.window.getScaleInfo = function() end

lurek.window.getScaleMode = function() end

lurek.window.getSystemTheme = function() end

lurek.window.getTitle = function() end

lurek.window.getVSync = function() end

lurek.window.getWidth = function() end

lurek.window.hasFocus = function() end

lurek.window.hasMouseFocus = function() end

lurek.window.isFullscreen = function() end

lurek.window.isHighDPIAllowed = function() end

lurek.window.isMaximized = function() end

lurek.window.isMinimized = function() end

lurek.window.isOpen = function() end

lurek.window.isResizable = function() end

lurek.window.isVisible = function() end

lurek.window.maximize = function() end

lurek.window.minimize = function() end

---@param func LuaValue
lurek.window.onDpiChange = function(func) end

---@param opts? LuaValue
lurek.window.openFileDialog = function(opts) end

lurek.window.pollDpiChange = function() end

lurek.window.requestAttention = function() end

lurek.window.restore = function() end

---@param display LuaValue
lurek.window.setDisplay = function(display) end

---@param enabled LuaValue
---@param fstype? LuaValue
lurek.window.setFullscreen = function(enabled, fstype) end

---@param path LuaValue
lurek.window.setIcon = function(path) end

---@param w LuaValue
---@param h LuaValue
---@param flags? LuaValue
lurek.window.setMode = function(w, h, flags) end

---@param x LuaValue
---@param y LuaValue
lurek.window.setPosition = function(x, y) end

---@param mode LuaValue
lurek.window.setScaleMode = function(mode) end

---@param title LuaValue
lurek.window.setTitle = function(title) end

---@param mode LuaValue
lurek.window.setVSync = function(mode) end

lurek.window.showMessageBox = function() end

---@param value LuaValue
lurek.window.toPixels = function(value) end

---@param opts LuaValue
lurek.window.windowConfig = function(opts) end
