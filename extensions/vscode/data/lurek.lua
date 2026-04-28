---@meta
--- Auto-generated Lurek2D API documentation for LuaCATS.

lurek = {}

---@alias LuaValue nil|boolean|number|string|table|function|userdata|thread

---@alias AnimCurve LAnimCurve

---@alias AnimStateMachine LAnimStateMachine

---@alias AnimSyncGroup LAnimSyncGroup

---@alias Animation LAnimation

---@alias Array LArray

---@alias BlendLayerSet LBlendLayerSet

---@alias ByteData LByteData

---@alias CompressedImageData LCompressedImageData

---@alias DepthSorter LDepthSorter

---@alias DoorManager LDoorManager

---@alias Edge LGraphEdge

---@alias FileWatcher LFileWatcher

---@alias Graph LGraph

---@alias GraphItem LGraphItem

---@alias HeightMap LHeightMap

---@alias ImageData LImageData

---@class LSpacer
LSpacer = {}

---@alias LayeredImage LLayeredImage

---@alias Minimap LMinimap

---@alias Node LGraphNode

---@alias PaletteLUT LPaletteLUT

---@alias PointLight LPointLight

---@alias ProvinceGrid LProvinceGrid

---@alias Raycaster LRaycaster

---@alias ReplConsole LReplConsole

---@alias SoundData LSoundData

---@alias SpriteManager LSpriteManager

---@alias Terminal LTerminal

---@alias Widget LWidget

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

--- Lua-side wrapper around a [`Blackboard`].
---@class LAIBlackboard
LAIBlackboard = {}

--- Removes all local entries.
---@return nil No value is returned.
function LAIBlackboard:clear() end

--- Returns the boolean for the given key, or default.
---@param key string Blackboard entry name.
---@param default? boolean Fallback value when the key is missing.
---@return boolean Stored boolean, or the provided default.
function LAIBlackboard:getBool(key, default) end

--- Returns all local keys as a table.
---@return table Array-style table of local key names.
function LAIBlackboard:getKeys() end

--- Returns the number for the given key, or default.
---@param key string Blackboard entry name.
---@param default? number Fallback value when the key is missing.
---@return number Stored number, or the provided default.
function LAIBlackboard:getNumber(key, default) end

--- Returns the number of local entries.
---@return integer Number of entries stored in this blackboard.
function LAIBlackboard:getSize() end

--- Returns the string for the given key, or default.
---@param key string Blackboard entry name.
---@param default? string Fallback value when the key is missing.
---@return string Stored string, or the provided default.
function LAIBlackboard:getString(key, default) end

--- Returns true if a value exists under the key.
---@param key string Blackboard entry name.
---@return boolean True if the key exists.
function LAIBlackboard:has(key) end

--- Removes the entry at key.
---@param key string Blackboard entry name to remove.
---@return nil No value is returned.
function LAIBlackboard:remove(key) end

--- Stores a boolean under the given key.
---@param key string Blackboard entry name.
---@param value boolean Boolean to store.
---@return nil No value is returned.
function LAIBlackboard:setBool(key, value) end

--- Stores a number under the given key.
---@param key string Blackboard entry name.
---@param value number Number to store.
---@return nil No value is returned.
function LAIBlackboard:setNumber(key, value) end

--- Stores a string under the given key.
---@param key string Blackboard entry name.
---@param value string String to store.
---@return nil No value is returned.
function LAIBlackboard:setString(key, value) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LAIBlackboard:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches AIBlackboard, Blackboard, or Object.
function LAIBlackboard:typeOf(name) end

--- Lua wrapper for [`crate::ai::director::AIDirector`].
---@class LAIDirector
LAIDirector = {}

--- Returns the current ambient intensity value.
---@return number Current ambient intensity value.
function LAIDirector:ambientIntensity() end

--- Returns the current loot factor.
---@return number Current loot factor.
function LAIDirector:lootFactor() end

--- Returns the current pacing phase name.
---@return string Current pacing phase name.
function LAIDirector:phase() end

--- Pushes a gameplay event with the given intensity to the director for awareness analysis.
---@param intensity number Intensity value for the event.
---@return nil No value is returned.
function LAIDirector:pushEvent(intensity) end

--- Resets the director state.
---@return nil No value is returned.
function LAIDirector:reset() end

--- Sets the global narrative tension level (0-1 scale).
---@param value number Tension value to apply.
---@return nil No value is returned.
function LAIDirector:setTension(value) end

--- Returns the current spawn rate factor.
---@return number Current spawn rate factor.
function LAIDirector:spawnRateFactor() end

--- Returns the current director tension value.
---@return number Current tension value.
function LAIDirector:tension() end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LAIDirector:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LAIDirector or Object.
function LAIDirector:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LAIDirector:update(dt) end

--- Lua wrapper for [`crate::ai::lod::AILod`].
---@class LAILod
LAILod = {}

--- Returns whether a tier should update on a frame.
---@param tier integer LOD tier index.
---@param frame_number integer Current frame number.
---@return boolean True if the tier should update on the frame.
function LAILod:shouldUpdate(tier, frame_number) end

--- Returns the number of LOD tiers.
---@return integer Number of LOD tiers.
function LAILod:tierCount() end

--- Returns the LOD tier for an agent relative to a reference position.
---@param agent_x number Agent x position.
---@param agent_y number Agent y position.
---@param ref_x number Reference x position.
---@param ref_y number Reference y position.
---@return integer LOD tier index.
function LAILod:tierFor(agent_x, agent_y, ref_x, ref_y) end

--- Returns the name of a tier.
---@param tier integer LOD tier index.
---@return string Tier name, or nil if the tier is missing.
function LAILod:tierName(tier) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LAILod:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LAILod or Object.
function LAILod:typeOf(name) end

--- Lua-side wrapper around an [`AIWorld`].
---@class LAIWorld
LAIWorld = {}

--- Registers a new named agent and returns its handle.
---@param name string Agent name to register in the world.
---@return LAgent Agent handle for the registered name.
function LAIWorld:addAgent(name) end

--- Returns the agent handle for the given name, or nil if it does not exist.
---@param name string Agent name to look up.
---@return LAgent Agent handle for the requested name, or nil if it does not exist.
function LAIWorld:getAgent(name) end

--- Returns the number of registered agents.
---@return integer Number of agents currently registered in the world.
function LAIWorld:getAgentCount() end

--- Returns a snapshot of the world-level blackboard.
---@return LAIBlackboard Copy of the world blackboard at call time.
function LAIWorld:getGlobalBlackboard() end

--- Removes an agent by its userdata handle.
---@param agent LAgent Agent handle to remove from the world.
---@return nil No value is returned.
function LAIWorld:removeAgent(agent) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LAIWorld:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches AIWorld or Object.
function LAIWorld:typeOf(name) end

--- Advances all agents by dt seconds, then invokes any custom-model callbacks.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LAIWorld:update(dt) end

--- Lua-side wrapper for an agent accessed by name through the owning world.
---@class LAgent
LAgent = {}

--- Adds a tag to this agent.
---@param tag string Tag to add to this agent.
---@return nil No value is returned.
function LAgent:addTag(tag) end

--- Returns the agent's local blackboard.
---@return LAIBlackboard Copy of the agent blackboard at call time.
function LAgent:getBlackboard() end

--- Returns the name of the current decision model.
---@return string Name of the current decision model.
function LAgent:getDecisionModel() end

--- Returns the maximum steering force cap.
---@return number Maximum steering force.
function LAgent:getMaxForce() end

--- Returns the maximum speed cap.
---@return number Maximum movement speed.
function LAgent:getMaxSpeed() end

--- Returns the agent's registered name.
---@return string Registered name of this agent.
function LAgent:getName() end

--- Returns the agent's current position.
---@return number Current world-space X coordinate.
---@return number Current world-space Y coordinate.
function LAgent:getPosition() end

--- Returns the agent's scheduling priority.
---@return integer Scheduling priority for this agent.
function LAgent:getPriority() end

--- Returns the agent's current velocity.
---@return number Current velocity X component.
---@return number Current velocity Y component.
function LAgent:getVelocity() end

--- Returns true if the agent has the given tag.
---@param tag string Tag to check on this agent.
---@return boolean True if the agent currently has the tag.
function LAgent:hasTag(tag) end

--- Removes a tag from this agent.
---@param tag string Tag to remove from this agent.
---@return nil No value is returned.
function LAgent:removeTag(tag) end

--- Installs a Lua-driven decision model on this agent.
---@param callback function Callback invoked during world updates with agent, blackboard, and dt.
---@return nil No value is returned.
function LAgent:setCustomModel(callback) end

--- Sets the active decision model.
---@param model string Decision model name to parse and apply.
---@return nil No value is returned.
function LAgent:setDecisionModel(model) end

--- Sets the maximum steering force cap.
---@param v number Maximum steering force.
---@return nil No value is returned.
function LAgent:setMaxForce(v) end

--- Sets the maximum speed cap.
---@param v number Maximum movement speed.
---@return nil No value is returned.
function LAgent:setMaxSpeed(v) end

--- Sets the agent's world-space position.
---@param x number World-space x coordinate.
---@param y number World-space y coordinate.
---@return nil No value is returned.
function LAgent:setPosition(x, y) end

--- Sets the scheduling priority (higher = earlier).
---@param p integer Scheduling priority value.
---@return nil No value is returned.
function LAgent:setPriority(p) end

--- Sets the agent's velocity vector.
---@param x number Velocity x component.
---@param y number Velocity y component.
---@return nil No value is returned.
function LAgent:setVelocity(x, y) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LAgent:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches Agent or Object.
function LAgent:typeOf(name) end

--- Lua-side wrapper around a [`BTNode`].
---@class LBTNode
LBTNode = {}

--- Adds a child node (Selector, Sequence, or Parallel only).
---@param child LBTNode Child node to append.
---@return nil No value is returned.
function LBTNode:addChild(child) end

--- Returns the number of direct children.
---@return integer Number of direct child nodes.
function LBTNode:getChildCount() end

--- Returns the repeat count, or 0 if not a Repeater.
---@return integer Repeat count, or 0 if this node is not a repeater.
function LBTNode:getCount() end

--- Returns the node type as a string.
---@return string Node type name.
function LBTNode:getNodeType() end

--- Resets all running-child memos and repeater counters.
---@return nil No value is returned.
function LBTNode:reset() end

--- Sets the single child of a decorator node.
---@param child LBTNode Child node to install on the decorator.
---@return nil No value is returned.
function LBTNode:setChild(child) end

--- Sets the repeat count for a Repeater node.
---@param n integer Repeat count to apply.
---@return nil No value is returned.
function LBTNode:setCount(n) end

--- Sets the failure policy for a Parallel node.
---@param policy string Failure policy name to parse.
---@return nil No value is returned.
function LBTNode:setFailurePolicy(policy) end

--- Sets the success policy for a Parallel node.
---@param policy string Success policy name to parse.
---@return nil No value is returned.
function LBTNode:setSuccessPolicy(policy) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LBTNode:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches BTNode or Object.
function LBTNode:typeOf(name) end

--- Lua wrapper for [`crate::ai::bandit::Bandit`].
---@class LBandit
LBandit = {}

--- Returns the number of arms.
---@return integer Number of bandit arms.
function LBandit:armCount() end

--- Returns the best arm index.
---@return integer Best arm index.
function LBandit:bestArm() end

--- Resets the bandit state.
---@return nil No value is returned.
function LBandit:reset() end

--- Selects an arm index using the current bandit strategy.
---@return integer Selected arm index.
function LBandit:select() end

--- Returns the total number of pulls.
---@return integer Total number of pulls.
function LBandit:totalPulls() end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LBandit:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LBandit or Object.
function LBandit:typeOf(name) end

--- Advances the simulation by one time step.
---@param index integer Arm index to update.
---@param reward number Reward observed for the arm.
---@return nil No value is returned.
function LBandit:update(index, reward) end

--- Lua-side wrapper around a [`BehaviorTree`].
---@class LBehaviorTree
LBehaviorTree = {}

--- Returns a diagnostic snapshot of this behavior tree.
---@return table Table with node_count and last_status fields.
function LBehaviorTree:getDebugState() end

--- Returns the status from the last tick.
---@return string Status returned by the most recent tree tick.
function LBehaviorTree:getLastStatus() end

--- Sets the root node of this behavior tree.
---@param node LBTNode Node to install as the tree root.
---@return nil No value is returned.
function LBehaviorTree:setRoot(node) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LBehaviorTree:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches BehaviorTree or Object.
function LBehaviorTree:typeOf(name) end

--- Lua-side wrapper around a [`CommandQueue`].
---@class LCommandQueue
LCommandQueue = {}

--- Cancels the front command if it is interruptible.
---@return boolean True if the current command was canceled.
function LCommandQueue:cancelCurrent() end

--- Discards all queued commands.
---@return nil No value is returned.
function LCommandQueue:clear() end

--- Appends a command to the back of the queue.
---@param kind string Command type name.
---@param callback function Lua callback for the command.
---@param opts? table Optional command options table.
---@return nil No value is returned.
function LCommandQueue:enqueue(kind, callback, opts) end

--- Returns the number of queued commands.
---@return integer Number of queued commands.
function LCommandQueue:getCount() end

--- Returns the target coordinates of the front command.
---@return number Front command target X coordinate.
---@return number Front command target Y coordinate.
function LCommandQueue:getCurrentTarget() end

--- Returns the kind of the front command, or nil if the queue is empty.
---@return string Front command kind, or nil if the queue is empty.
function LCommandQueue:getCurrentType() end

--- Returns true if there are no queued commands.
---@return boolean True if the queue is empty.
function LCommandQueue:isEmpty() end

--- Inserts a command at the front, interrupting the current one.
---@param kind string Command type name.
---@param callback function Lua callback for the command.
---@param opts? table Optional command options table.
---@return nil No value is returned.
function LCommandQueue:pushFront(kind, callback, opts) end

--- Clears the queue and enqueues one new command.
---@param kind string Command type name.
---@param callback function Lua callback for the command.
---@param opts? table Optional command options table.
---@return nil No value is returned.
function LCommandQueue:replace(kind, callback, opts) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LCommandQueue:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches CommandQueue or Object.
function LCommandQueue:typeOf(name) end

--- Lua wrapper for [`crate::ai::context_steering::ContextSteering`].
---@class LContextSteering
LContextSteering = {}

--- Registers a rectangular region this agent must avoid.
---@param min_x number Minimum x coordinate.
---@param min_y number Minimum y coordinate.
---@param max_x number Maximum x coordinate.
---@param max_y number Maximum y coordinate.
---@param margin number Extra avoidance margin.
---@param weight number Behavior weight.
---@return nil No value is returned.
function LContextSteering:addAvoidBounds(min_x, min_y, max_x, max_y, margin, weight) end

--- Adds a world-space point that this agent steers away from.
---@param x number Avoid point x coordinate.
---@param y number Avoid point y coordinate.
---@param radius number Avoidance radius.
---@param weight number Behavior weight.
---@return nil No value is returned.
function LContextSteering:addAvoidPoint(x, y, radius, weight) end

--- Adds a world-space target that this agent steers towards.
---@param tx number Target x coordinate.
---@param ty number Target y coordinate.
---@param weight number Target weight.
---@return nil No value is returned.
function LContextSteering:addSeekTarget(tx, ty, weight) end

--- Adds a wander behavior with jitter and weight to the context steering evaluator.
---@param jitter number Wander jitter amount.
---@param weight number Behavior weight.
---@return nil No value is returned.
function LContextSteering:addWander(jitter, weight) end

--- Returns the magnitude of the last chosen steering direction.
---@return number Magnitude of the chosen steering direction.
function LContextSteering:chosenMagnitude() end

--- Clears all registered context steering behaviors.
---@return nil No value is returned.
function LContextSteering:clearBehaviors() end

--- Evaluates the steering context and returns the chosen direction.
---@param ax number Agent x position.
---@param ay number Agent y position.
---@param vx number Agent velocity x component.
---@param vy number Agent velocity y component.
---@return number Chosen direction X component.
---@return number Chosen direction Y component.
function LContextSteering:evaluate(ax, ay, vx, vy) end

--- Returns the number of steering slots.
---@return integer Number of steering slots.
function LContextSteering:slotCount() end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LContextSteering:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LContextSteering or Object.
function LContextSteering:typeOf(name) end

--- Lua wrapper for [`crate::ai::emotion::EmotionModel`].
---@class LEmotionModel
LEmotionModel = {}

--- Adds an emotion category with the given name and initial intensity to the model.
---@param name string Emotion name to register.
---@param resting_level number Resting value for the emotion.
---@param decay_rate number Per-update decay rate.
---@param min_visible number Minimum visible threshold.
---@return nil No value is returned.
function LEmotionModel:add(name, resting_level, decay_rate, min_visible) end

--- Returns the dominant emotion name, or nil if there is none.
---@return string Dominant emotion name, or nil if there is none.
function LEmotionModel:dominant() end

--- Returns the current float value of this emotion dimension.
---@param name string Emotion name to read.
---@return number Current emotion value.
function LEmotionModel:get(name) end

--- Returns `true` if the emotion dimension is currently active and above threshold.
---@param name string Emotion name to check.
---@return boolean True if the emotion is active.
function LEmotionModel:isActive(name) end

--- Resets the emotion model state.
---@return nil No value is returned.
function LEmotionModel:reset() end

--- Triggers a named emotion by the given amount.
---@param name string Emotion name to trigger.
---@param amount number Amount to add.
---@return nil No value is returned.
function LEmotionModel:trigger(name, amount) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LEmotionModel:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LEmotionModel or Object.
function LEmotionModel:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LEmotionModel:update(dt) end

--- Lua-side wrapper around a [`GOAPPlanner`].
---@class LGOAPPlanner
LGOAPPlanner = {}

--- Adds a GOAP action with optional cost and callback.
---@param name string Action name to register.
---@param cost? number Optional action cost.
---@param callback? function Optional Lua callback for the action.
---@return nil No value is returned.
function LGOAPPlanner:addAction(name, cost, callback) end

--- Adds a planning goal with optional priority.
---@param name string Goal name to register.
---@param priority? number Optional goal priority.
---@return nil No value is returned.
function LGOAPPlanner:addGoal(name, priority) end

--- Returns the number of registered actions.
---@return integer Number of registered actions.
function LGOAPPlanner:getActionCount() end

--- Returns the number of registered goals.
---@return integer Number of registered goals.
function LGOAPPlanner:getGoalCount() end

--- Returns the maximum A* planning iterations.
---@return integer Maximum number of planning iterations.
function LGOAPPlanner:getMaxIterations() end

--- Runs A* planning and returns an action sequence table.
---@param worldState table Table of boolean world-state flags.
---@param maxDepth? integer Optional maximum search depth.
---@return table Array-style table of planned action names.
function LGOAPPlanner:plan(worldState, maxDepth) end

--- Sets a boolean effect on an action.
---@param actionName string Action name to modify.
---@param key string Effect key.
---@param value boolean Effect value.
---@return nil No value is returned.
function LGOAPPlanner:setEffect(actionName, key, value) end

--- Sets a boolean condition on a goal.
---@param goalName string Goal name to modify.
---@param key string Goal state key.
---@param value boolean Goal state value.
---@return nil No value is returned.
function LGOAPPlanner:setGoalState(goalName, key, value) end

--- Sets the maximum A* planning iterations (0 = unlimited).
---@param n integer Maximum iteration count, or 0 for unlimited.
---@return nil No value is returned.
function LGOAPPlanner:setMaxIterations(n) end

--- Sets a boolean precondition on an action.
---@param actionName string Action name to modify.
---@param key string Precondition key.
---@param value boolean Precondition value.
---@return nil No value is returned.
function LGOAPPlanner:setPrecondition(actionName, key, value) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LGOAPPlanner:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches GOAPPlanner or Object.
function LGOAPPlanner:typeOf(name) end

--- Lua wrapper for [`crate::ai::genetic::GeneticAlgorithm`].
---@class LGeneticAlgorithm
LGeneticAlgorithm = {}

--- Returns the genes from the best chromosome.
---@return table Array-style table of gene values from the best chromosome.
function LGeneticAlgorithm:bestGenes() end

--- Runs one generation of the evolutionary algorithm.
---@return nil No value is returned.
function LGeneticAlgorithm:evolve() end

--- Returns the current generation number.
---@return integer Current generation number.
function LGeneticAlgorithm:generation() end

--- Returns the chromosome as an ordered table of gene values.
---@param index integer Chromosome index to read.
---@return table Array-style table of gene values.
function LGeneticAlgorithm:getGenes(index) end

--- Returns the population size.
---@return integer Population size.
function LGeneticAlgorithm:popSize() end

--- Sets the fitness score used by the genetic algorithm selection step.
---@param index integer Chromosome index to update.
---@param fitness number Fitness score to store.
---@return nil No value is returned.
function LGeneticAlgorithm:setFitness(index, fitness) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LGeneticAlgorithm:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LGeneticAlgorithm or Object.
function LGeneticAlgorithm:typeOf(name) end

--- Lua wrapper for [`crate::ai::htn::HTNDomain`].
---@class LHTNDomain
LHTNDomain = {}

--- Registers a compound HTN task that decomposes into sub-tasks.
---@param compound_name string Compound task name.
---@param methods table Array-style table of method definitions.
---@return nil No value is returned.
function LHTNDomain:addCompound(compound_name, methods) end

--- Registers a primitive HTN task with a direct operator function.
---@param name string Primitive task name.
---@param preconditions table Array-style table of precondition names.
---@param effects table Array-style table of effect names.
---@param effects_clear table Array-style table of cleared effect names.
---@return nil No value is returned.
function LHTNDomain:addPrimitive(name, preconditions, effects, effects_clear) end

--- Runs planning and returns the resulting action sequence, or nil if no plan is found.
---@param root_task string Root task name to plan from.
---@param state table Table of world-state values.
---@return table Array-style table of planned steps, or nil if no plan is found.
function LHTNDomain:plan(root_task, state) end

--- Returns the number of registered tasks.
---@return integer Number of registered tasks.
function LHTNDomain:taskCount() end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LHTNDomain:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LHTNDomain or Object.
function LHTNDomain:typeOf(name) end

--- Lua-side wrapper around an [`InfluenceMap`].
---@class LInfluenceMap
LInfluenceMap = {}

--- Adds a named influence layer.
---@param name string Layer name to add.
---@return nil No value is returned.
function LInfluenceMap:addLayer(name) end

--- Blends two layers into a destination layer.
---@param layerA string First source layer name.
---@param weightA number Weight for the first source layer.
---@param layerB string Second source layer name.
---@param weightB number Weight for the second source layer.
---@param dest string Destination layer name.
---@return nil No value is returned.
function LInfluenceMap:blend(layerA, weightA, layerB, weightB, dest) end

--- Removes all influence values from every layer in the map.
---@return nil No value is returned.
function LInfluenceMap:clearAll() end

--- Clears all influence in a layer.
---@param layer string Layer name to clear.
---@return nil No value is returned.
function LInfluenceMap:clearLayer(layer) end

--- Multiplies all influences by a decay factor.
---@param layer string Layer name to decay.
---@param factor number Decay factor to apply.
---@return nil No value is returned.
function LInfluenceMap:decay(layer, factor) end

--- Returns the cell size in world units.
---@return number Cell size in world units.
function LInfluenceMap:getCellSize() end

--- Returns the influence map height in grid cells.
---@return integer Influence map height in cells.
function LInfluenceMap:getHeight() end

--- Returns the influence value at a cell (1-based).
---@param layer string Layer name to read from.
---@param x integer One-based cell x coordinate.
---@param y integer One-based cell y coordinate.
---@return number Influence value at the requested cell.
function LInfluenceMap:getInfluence(layer, x, y) end

--- Returns the world-space position of the maximum value.
---@param layer string Layer name to query.
---@return number World-space X position of the maximum value.
---@return number World-space Y position of the maximum value.
function LInfluenceMap:getMaxPosition(layer) end

--- Returns the world-space position of the minimum value.
---@param layer string Layer name to query.
---@return number World-space X position of the minimum value.
---@return number World-space Y position of the minimum value.
function LInfluenceMap:getMinPosition(layer) end

--- Returns the influence map width in grid cells.
---@return integer Influence map width in cells.
function LInfluenceMap:getWidth() end

--- Returns true if the named layer exists.
---@param name string Layer name to check.
---@return boolean True if the layer exists.
function LInfluenceMap:hasLayer(name) end

--- Propagates influence values with momentum.
---@param layer string Layer name to propagate.
---@param momentum? number Optional momentum factor.
---@return nil No value is returned.
function LInfluenceMap:propagate(layer, momentum) end

--- Returns the summed influence in a world-space rectangle.
---@param layer string Layer name to query.
---@param wx number World-space rectangle x coordinate.
---@param wy number World-space rectangle y coordinate.
---@param ww number Rectangle width.
---@param wh number Rectangle height.
---@return number Summed influence within the rectangle.
function LInfluenceMap:queryRect(layer, wx, wy, ww, wh) end

--- Sets the influence value at a cell (1-based).
---@param layer string Layer name to write to.
---@param x integer One-based cell x coordinate.
---@param y integer One-based cell y coordinate.
---@param value number Influence value to store.
---@return nil No value is returned.
function LInfluenceMap:setInfluence(layer, x, y, value) end

--- Stamps influence in a radial area.
---@param layer string Layer name to modify.
---@param wx number World-space x center.
---@param wy number World-space y center.
---@param radius number Stamp radius.
---@param value number Influence value to stamp.
---@param falloff? number Optional radial falloff factor.
---@return nil No value is returned.
function LInfluenceMap:stampInfluence(layer, wx, wy, radius, value, falloff) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LInfluenceMap:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches InfluenceMap or Object.
function LInfluenceMap:typeOf(name) end

--- Lua wrapper for [`crate::ai::mcts::MCTSEngine`].
---@class LMCTSEngine
LMCTSEngine = {}

--- Uses Lua closures for game logic. All closures receive/return integer states.
---@param root_state integer Root state value for the search.
---@param get_actions function Callback that returns available actions for a state.
---@param apply_action function Callback that returns the next state for a state and action.
---@param evaluate function Callback that returns a score for a state.
---@return integer Selected action, or nil if no action is found.
function LMCTSEngine:search(root_state, get_actions, apply_action, evaluate) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LMCTSEngine:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LMCTSEngine or Object.
function LMCTSEngine:typeOf(name) end

--- Lua wrapper for [`crate::ai::needs::NeedSystem`].
---@class LNeedSystem
LNeedSystem = {}

--- Registers a new need with the specified name, urgency, and decay rate in the system.
---@param name string Need name to register.
---@param decay_rate number Per-update decay rate.
---@param urgency_threshold number Threshold where the need becomes urgent.
---@param urgency_factor number Urgency scaling factor.
---@return nil No value is returned.
function LNeedSystem:addNeed(name, decay_rate, urgency_threshold, urgency_factor) end

--- Returns the most urgent need name, or nil if no need is urgent.
---@return string Most urgent need name, or nil if no need is urgent.
function LNeedSystem:mostUrgent() end

--- Satisfies part of a named need.
---@param name string Need name to satisfy.
---@param amount number Satisfaction amount.
---@return nil No value is returned.
function LNeedSystem:satisfy(name, amount) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LNeedSystem:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LNeedSystem or Object.
function LNeedSystem:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LNeedSystem:update(dt) end

--- Returns the current value of a named need.
---@param name string Need name to read.
---@return number Current value of the need.
function LNeedSystem:valueOf(name) end

--- Lua wrapper for [`crate::ai::neural_net::NeuralNet`].
---@class LNeuralNet
LNeuralNet = {}

--- Adds a neural network layer with inputs, outputs, and an activation function.
---@param inputs integer Number of input units.
---@param outputs integer Number of output units.
---@param activation string Activation function name.
---@return nil No value is returned.
function LNeuralNet:addLayer(inputs, outputs, activation) end

--- Runs a forward pass through the network.
---@param input table Array-style table of input values.
---@return table Array-style table of output values.
function LNeuralNet:forward(input) end

--- Returns a flat table of all connection weight values in the network.
---@return table Flat array of all network weights.
function LNeuralNet:getWeights() end

--- Returns the number of network layers.
---@return integer Number of network layers.
function LNeuralNet:layerCount() end

--- Returns the number of network parameters.
---@return integer Number of network parameters.
function LNeuralNet:paramCount() end

--- Overwrites all connection weights with values from a flat table.
---@param weights table Flat array of weight values.
---@return boolean True if the provided weights were applied.
function LNeuralNet:setWeights(weights) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LNeuralNet:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LNeuralNet or Object.
function LNeuralNet:typeOf(name) end

--- Lua wrapper for [`crate::ai::neuroevolution::Neuroevolution`].
---@class LNeuroevolution
LNeuroevolution = {}

--- Returns the best fitness score.
---@return number Best fitness score.
function LNeuroevolution:bestFitness() end

--- Returns the best neural network, or nil if no network is available.
---@return LNeuralNet Best neural network, or nil if no network is available.
function LNeuroevolution:bestNetwork() end

--- Returns the neural network built from a chromosome, or nil if the index is invalid.
---@param index integer Chromosome index to convert.
---@return LNeuralNet Neural network built from the chromosome, or nil if the index is invalid.
function LNeuroevolution:chromosomeToNet(index) end

--- Runs one generation of the evolutionary algorithm.
---@return nil No value is returned.
function LNeuroevolution:evolve() end

--- Returns the current generation number.
---@return integer Current generation number.
function LNeuroevolution:generation() end

--- Returns the population size.
---@return integer Population size.
function LNeuroevolution:popSize() end

--- Sets the fitness score used by the genetic algorithm selection step.
---@param index integer Chromosome index to update.
---@param fitness number Fitness score to store.
---@return nil No value is returned.
function LNeuroevolution:setFitness(index, fitness) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LNeuroevolution:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LNeuroevolution or Object.
function LNeuroevolution:typeOf(name) end

--- Lua wrapper for [`crate::ai::orca::ORCASolver`].
---@class LORCASolver
LORCASolver = {}

--- Adds an ORCA agent at the given position with radius and max speed to the solver.
---@param x number Agent x position.
---@param y number Agent y position.
---@param radius number Agent radius.
---@param max_speed number Agent maximum speed.
---@return integer Index of the created ORCA agent.
function LORCASolver:addAgent(x, y, radius, max_speed) end

--- Returns the number of registered ORCA agents.
---@return integer Number of registered ORCA agents.
function LORCASolver:agentCount() end

--- Computes safe velocities for all registered agents.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LORCASolver:compute(dt) end

--- Returns the safe velocity for an agent.
---@param index integer Agent index to query.
---@return number Safe velocity X component.
---@return number Safe velocity Y component.
function LORCASolver:getSafeVelocity(index) end

--- Sets the agent's current world-space position for ORCA velocity computation.
---@param index integer Agent index to update.
---@param x number Agent x position.
---@param y number Agent y position.
---@return nil No value is returned.
function LORCASolver:setPosition(index, x, y) end

--- Sets the preferred velocity.
---@param index integer Agent index to update.
---@param pvx number Preferred velocity x component.
---@param pvy number Preferred velocity y component.
---@return nil No value is returned.
function LORCASolver:setPreferredVelocity(index, pvx, pvy) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LORCASolver:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LORCASolver or Object.
function LORCASolver:typeOf(name) end

--- Lua-side wrapper around a [`QLearner`].
---@class LQLearner
LQLearner = {}

--- Returns the greedy-best action for the state (1-based).
---@param state integer One-based state index.
---@return integer One-based greedy action index.
function LQLearner:bestAction(state) end

--- Selects an action using epsilon-greedy policy (1-based).
---@param state integer One-based state index.
---@return integer One-based selected action index.
function LQLearner:chooseAction(state) end

--- Restores the Q-table from a JSON string.
---@param json string JSON representation of a Q-table.
---@return nil No value is returned.
function LQLearner:deserialize(json) end

--- Ends the current episode, applying epsilon decay.
---@return nil No value is returned.
function LQLearner:endEpisode() end

--- Returns the number of discrete actions.
---@return integer Number of discrete actions.
function LQLearner:getActionCount() end

--- Returns the current discount factor.
---@return number Current discount factor.
function LQLearner:getDiscountFactor() end

--- Returns the number of completed episodes.
---@return integer Number of completed episodes.
function LQLearner:getEpisodeCount() end

--- Returns the epsilon decay multiplier.
---@return number Exploration decay multiplier.
function LQLearner:getExplorationDecay() end

--- Returns the current exploration rate.
---@return number Current exploration rate.
function LQLearner:getExplorationRate() end

--- Returns the current learning rate.
---@return number Current learning rate.
function LQLearner:getLearningRate() end

--- Returns the Q-value for a state-action pair (1-based).
---@param state integer One-based state index.
---@param action integer One-based action index.
---@return number Q-value for the requested state-action pair.
function LQLearner:getQValue(state, action) end

--- Returns the number of discrete states.
---@return integer Number of discrete states.
function LQLearner:getStateCount() end

--- Performs one Bellman Q-learning update (1-based indices).
---@param state integer One-based current state index.
---@param action integer One-based action index.
---@param reward number Reward value for the transition.
---@param nextState integer One-based next state index.
---@return nil No value is returned.
function LQLearner:learn(state, action, reward, nextState) end

--- Serializes the Q-table to a JSON string.
---@return string JSON representation of the Q-table.
function LQLearner:serialize() end

--- Sets the discount factor gamma.
---@param v number Discount factor value.
---@return nil No value is returned.
function LQLearner:setDiscountFactor(v) end

--- Sets the epsilon decay multiplier.
---@param v number Exploration decay multiplier.
---@return nil No value is returned.
function LQLearner:setExplorationDecay(v) end

--- Sets the exploration rate epsilon.
---@param v number Exploration rate value.
---@return nil No value is returned.
function LQLearner:setExplorationRate(v) end

--- Sets the learning rate alpha.
---@param v number Learning rate value.
---@return nil No value is returned.
function LQLearner:setLearningRate(v) end

--- Overwrites the Q-value for a state-action pair (1-based).
---@param state integer One-based state index.
---@param action integer One-based action index.
---@param value number Q-value to store.
---@return nil No value is returned.
function LQLearner:setQValue(state, action, value) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LQLearner:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches QLearner or Object.
function LQLearner:typeOf(name) end

--- Lua-side wrapper around a [`Squad`].
---@class LSquad
LSquad = {}

--- Adds an agent by name to this squad.
---@param name string Agent name to add.
---@return nil No value is returned.
function LSquad:addMember(name) end

--- Returns the squad's shared blackboard.
---@return LAIBlackboard Copy of the squad blackboard at call time.
function LSquad:getBlackboard() end

--- Returns the current formation type name.
---@return string Current formation type name.
function LSquad:getFormation() end

--- Computes the world-space position for a member index (1-based).
---@param memberIdx integer One-based member index.
---@param leaderX number Leader x coordinate.
---@param leaderY number Leader y coordinate.
---@return number World-space X position for the member slot.
---@return number World-space Y position for the member slot.
function LSquad:getFormationPosition(memberIdx, leaderX, leaderY) end

--- Returns the formation spacing in world units.
---@return number Formation spacing in world units.
function LSquad:getFormationSpacing() end

--- Returns the leader name, or nil if no leader is set.
---@return string Leader name, or nil if no leader is set.
function LSquad:getLeader() end

--- Returns the number of squad members.
---@return integer Number of squad members.
function LSquad:getMemberCount() end

--- Returns the member names as a table.
---@return table Array-style table of squad member names.
function LSquad:getMembers() end

--- Returns the unique name string assigned to this squad.
---@return string Squad name.
function LSquad:getName() end

--- Removes an agent by name from this squad.
---@param name string Agent name to remove.
---@return nil No value is returned.
function LSquad:removeMember(name) end

--- Sets the formation type and optional spacing.
---@param ftype string Formation type name.
---@param spacing? number Optional formation spacing.
---@return nil No value is returned.
function LSquad:setFormation(ftype, spacing) end

--- Sets the squad leader by name.
---@param name string Leader agent name.
---@return nil No value is returned.
function LSquad:setLeader(name) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LSquad:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches Squad or Object.
function LSquad:typeOf(name) end

--- Lua-side wrapper around a [`StateMachine`].
---@class LStateMachine
LStateMachine = {}

--- Registers a named state with optional lifecycle callbacks.
---@param name string State name to register.
---@param opts table State options table with optional lifecycle callbacks.
---@return nil No value is returned.
function LStateMachine:addState(name, opts) end

--- Adds a guarded transition between states.
---@param from string Source state name.
---@param to string Destination state name.
---@param guard? function Optional guard callback for the transition.
---@param priority? integer Optional transition priority.
---@return nil No value is returned.
function LStateMachine:addTransition(from, to, guard, priority) end

--- Forces a transition to the named state.
---@param name string State name to force as current.
---@return nil No value is returned.
function LStateMachine:forceState(name) end

--- Returns the current state name, or nil if no state is active.
---@return string Current state name, or nil if no state is active.
function LStateMachine:getCurrentState() end

--- Returns seconds spent in the current state.
---@return number Seconds spent in the current state.
function LStateMachine:getTimeInState() end

--- Sets the FSM's initial state; must be called before the first update.
---@param name string State name to set as the initial state.
---@return nil No value is returned.
function LStateMachine:setInitialState(name) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LStateMachine:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches StateMachine or Object.
function LStateMachine:typeOf(name) end

--- Lua-side wrapper around a [`SteeringManager`].
---@class LSteeringManager
LSteeringManager = {}

--- Adds an Arrive behavior with deceleration.
---@param tx number Target x coordinate.
---@param ty number Target y coordinate.
---@param slowingRadius? number Optional slowing radius.
---@param weight? number Optional behavior weight.
---@return nil No value is returned.
function LSteeringManager:addArrive(tx, ty, slowingRadius, weight) end

--- Registers a Lua callback as a custom steering behavior.
---@param callback function Callback that returns steering x and y components for an agent and dt.
---@param weight? number Optional behavior weight.
---@return nil No value is returned.
function LSteeringManager:addCustomBehavior(callback, weight) end

--- Adds an Evade behavior fleeing from a named agent.
---@param threatName? string Optional threat agent name.
---@param weight? number Optional behavior weight.
---@return nil No value is returned.
function LSteeringManager:addEvade(threatName, weight) end

--- Adds a Flee behavior away from the target.
---@param tx number Threat x coordinate.
---@param ty number Threat y coordinate.
---@param panicDist? number Optional panic distance.
---@param weight? number Optional behavior weight.
---@return nil No value is returned.
function LSteeringManager:addFlee(tx, ty, panicDist, weight) end

--- Adds a Flock behavior for group movement.
---@param neighborRadius? number Optional neighbor search radius.
---@param sepWeight? number Optional separation weight.
---@param alignWeight? number Optional alignment weight.
---@param cohWeight? number Optional cohesion weight.
---@param weight? number Optional overall behavior weight.
---@return nil No value is returned.
function LSteeringManager:addFlock(neighborRadius, sepWeight, alignWeight, cohWeight, weight) end

--- Adds a Pursue behavior targeting a named agent.
---@param targetName? string Optional target agent name.
---@param weight? number Optional behavior weight.
---@return nil No value is returned.
function LSteeringManager:addPursue(targetName, weight) end

--- Adds a Seek behavior toward the target.
---@param tx number Target x coordinate.
---@param ty number Target y coordinate.
---@param weight? number Optional behavior weight.
---@return nil No value is returned.
function LSteeringManager:addSeek(tx, ty, weight) end

--- Adds a Wander behavior for random meandering.
---@param radius? number Optional wander circle radius.
---@param dist? number Optional wander circle distance.
---@param jitter? number Optional wander jitter amount.
---@param weight? number Optional behavior weight.
---@return nil No value is returned.
function LSteeringManager:addWander(radius, dist, jitter, weight) end

--- Invokes all registered custom steering callbacks and returns the combined force.
---@param agent LAgent Agent passed to each custom steering callback.
---@param dt number Delta time in seconds.
---@return number Combined force X component.
---@return number Combined force Y component.
function LSteeringManager:applyCustomSteering(agent, dt) end

--- Computes the combined steering force for the given agent state.
---@param px number Agent x position.
---@param py number Agent y position.
---@param vx number Agent velocity x component.
---@param vy number Agent velocity y component.
---@param maxSpeed number Agent maximum speed.
---@param maxForce number Agent maximum steering force.
---@param dt number Delta time in seconds.
---@return number Combined steering force X component.
---@return number Combined steering force Y component.
function LSteeringManager:calculate(px, py, vx, vy, maxSpeed, maxForce, dt) end

--- Enables or disables spatial-hash bucketing for neighbourhood queries.
---@param enabled boolean True to enable spatial-hash bucketing.
---@return nil No value is returned.
function LSteeringManager:enableSpatialHash(enabled) end

--- Returns the number of active behaviors.
---@return integer Number of active steering behaviors.
function LSteeringManager:getBehaviorCount() end

--- Returns the current combination mode.
---@return string Current steering combination mode name.
function LSteeringManager:getCombineMode() end

--- Returns the last computed steering force.
---@return number Last computed force X component.
---@return number Last computed force Y component.
function LSteeringManager:getLastSteering() end

--- Sets the force combination mode.
---@param mode string Combination mode name to parse.
---@return nil No value is returned.
function LSteeringManager:setCombineMode(mode) end

--- Sets the cell size used by the spatial-hash neighborhood search.
---@param size number Cell size for neighborhood bucketing.
---@return nil No value is returned.
function LSteeringManager:setSpatialHashCellSize(size) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LSteeringManager:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches SteeringManager or Object.
function LSteeringManager:typeOf(name) end

--- Lua wrapper for [`crate::ai::perception::StimulusWorld`].
---@class LStimulusWorld
LStimulusWorld = {}

--- Registers an auditory stimulus at a world-space position.
---@param x number World-space x position.
---@param y number World-space y position.
---@param intensity number Stimulus intensity.
---@param radius number Stimulus radius.
---@param decay_rate number Per-update decay rate.
---@param tag? string Optional stimulus tag.
---@return integer Identifier of the created stimulus.
function LStimulusWorld:addAuditory(x, y, intensity, radius, decay_rate, tag) end

--- Adds a visual stimulus at the specified world position with radius and intensity.
---@param x number World-space x position.
---@param y number World-space y position.
---@param intensity number Stimulus intensity.
---@param radius number Stimulus radius.
---@param tag? string Optional stimulus tag.
---@return integer Identifier of the created stimulus.
function LStimulusWorld:addVisual(x, y, intensity, radius, tag) end

--- Clears all stimuli from the world.
---@return nil No value is returned.
function LStimulusWorld:clear() end

--- Returns the number of active stimuli.
---@return integer Number of active stimuli.
function LStimulusWorld:count() end

--- Removes the specified item.
---@param id integer Stimulus identifier to remove.
---@return boolean True if a stimulus was removed.
function LStimulusWorld:remove(id) end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LStimulusWorld:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LStimulusWorld or Object.
function LStimulusWorld:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LStimulusWorld:update(dt) end

--- Lua wrapper for [`crate::ai::strategy::StrategyAI`].
---@class LStrategyAI
LStrategyAI = {}

--- Returns the active goal name, or nil if no goal is active.
---@return string Active goal name, or nil if no goal is active.
function LStrategyAI:activeGoal() end

--- Adds a strategic goal with priority score to the planner for future evaluation.
---@param name string Goal name to add.
---@return nil No value is returned.
function LStrategyAI:addGoal(name) end

--- Adds a string tag to the strategy AI instance for goal filtering and categorization.
---@param tag string Tag to add.
---@return nil No value is returned.
function LStrategyAI:addTag(tag) end

--- Forces an immediate strategy evaluation.
---@param scorer function Callback that scores a goal name.
---@return nil No value is returned.
function LStrategyAI:forceEvaluate(scorer) end

--- Removes the specified tag.
---@param tag string Tag to remove.
---@return nil No value is returned.
function LStrategyAI:removeTag(tag) end

--- Returns the time until the next scheduled evaluation.
---@return number Time until the next scheduled evaluation.
function LStrategyAI:timeUntilNext() end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LStrategyAI:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LStrategyAI or Object.
function LStrategyAI:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number Delta time in seconds.
---@param scorer function Callback that scores a goal name.
---@return nil No value is returned.
function LStrategyAI:update(dt, scorer) end

--- Lua wrapper for [`crate::ai::traits::TraitProfile`].
---@class LTraitProfile
LTraitProfile = {}

--- Adds a named modifier that adjusts the trait value by a delta.
---@param trait_name string Trait name to modify.
---@param delta number Modifier delta to apply.
---@param duration? number Optional modifier duration in seconds.
---@param source string Source label for the modifier.
---@return nil No value is returned.
function LTraitProfile:addModifier(trait_name, delta, duration, source) end

--- Returns the current archetype name, or nil if none is set.
---@return string Archetype name, or nil if none is set.
function LTraitProfile:archetype() end

--- Returns the current float value of this emotion dimension.
---@param name string Trait name to read.
---@return number Current trait value.
function LTraitProfile:get(name) end

--- Returns the unmodified base value of this trait before modifiers.
---@param name string Trait name to read.
---@return number Stored base value for the trait.
function LTraitProfile:getBase(name) end

--- Returns true if a item is present.
---@param name string Trait name to check.
---@return boolean True if the trait exists.
function LTraitProfile:has(name) end

--- Removes the specified modifiers.
---@param source string Source label of the modifiers to remove.
---@return nil No value is returned.
function LTraitProfile:removeModifiers(source) end

--- Sets the base value of this trait, replacing any previous base.
---@param name string Trait name to update.
---@param value number Base value to store.
---@return nil No value is returned.
function LTraitProfile:set(name, value) end

--- Returns the number of tracked traits.
---@return number Number of tracked traits.
function LTraitProfile:traitCount() end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LTraitProfile:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches LTraitProfile or Object.
function LTraitProfile:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LTraitProfile:update(dt) end

--- Lua-side wrapper around a [`UtilityAI`].
---@class LUtilityAI
LUtilityAI = {}

--- Adds a scored action with optional momentum weight.
---@param name string Action name to register.
---@param scorer function Lua scorer callback for the action.
---@param weight? number Optional momentum bonus.
---@return nil No value is returned.
function LUtilityAI:addAction(name, scorer, weight) end

--- Adds a multi-axis consideration to a named action.
---@param actionName string Action name that receives the consideration.
---@param name string Consideration name.
---@param scorerFn function Lua callback that returns the raw consideration value.
---@param curve LuaValue Curve name string or custom curve callback.
---@param p1? number Optional first curve parameter.
---@param p2? number Optional second curve parameter.
---@param p3? number Optional third curve parameter.
---@param weight? number Optional consideration weight.
---@return nil No value is returned.
function LUtilityAI:addConsideration(actionName, name, scorerFn, curve, p1, p2, p3, weight) end

--- Evaluates all actions and returns the best action name, or nil if none is chosen.
---@return string Best action name, or nil if none is chosen.
function LUtilityAI:evaluate() end

--- Returns the number of registered actions.
---@return integer Number of registered actions.
function LUtilityAI:getActionCount() end

--- Returns the name of the last chosen action, or nil if none has been chosen.
---@return string Last chosen action name, or nil if none has been chosen.
function LUtilityAI:getLastAction() end

--- Returns the type name of this object.
---@return string Type name for this userdata.
function LUtilityAI:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the type matches UtilityAI or Object.
function LUtilityAI:typeOf(name) end

--- Creates a new AI pacing director with default config.
---@return LAIDirector New AI director userdata.
lurek.ai.newAIDirector = function() end

--- Creates a new AI LOD controller with default 3-tier config.
---@return LAILod New AI LOD userdata.
lurek.ai.newAILod = function() end

--- Creates a BT action leaf with a Lua callback.
---@param callback function Action callback invoked by the node.
---@return LBTNode New action node userdata.
lurek.ai.newAction = function(callback) end

--- Creates a new multi-armed bandit.
---@param arm_count integer Number of bandit arms.
---@param strategy string Strategy name such as epsilon_greedy, ucb1, or thompson.
---@param epsilon number Epsilon value used by epsilon_greedy.
---@param seed integer Random seed value.
---@return LBandit New bandit userdata.
lurek.ai.newBandit = function(arm_count, strategy, epsilon, seed) end

--- Creates a new behavior tree.
---@return LBehaviorTree New behavior tree userdata.
lurek.ai.newBehaviorTree = function() end

--- Creates a new standalone blackboard.
---@return LAIBlackboard New blackboard userdata.
lurek.ai.newBlackboard = function() end

--- Creates an RTS-style command queue.
---@return LCommandQueue New command queue userdata.
lurek.ai.newCommandQueue = function() end

--- Creates a BT condition leaf with a Lua predicate.
---@param callback function Predicate callback invoked by the node.
---@return LBTNode New condition node userdata.
lurek.ai.newCondition = function(callback) end

--- Creates a new context steering controller.
---@param slots integer Number of steering slots to create.
---@return LContextSteering New context steering userdata.
lurek.ai.newContextSteering = function(slots) end

--- Creates a new affective emotion model.
---@return LEmotionModel New emotion model userdata.
lurek.ai.newEmotionModel = function() end

--- Creates a new GOAP planning solver.
---@return LGOAPPlanner New GOAP planner userdata.
lurek.ai.newGOAPPlanner = function() end

--- Creates a new genetic algorithm.
---@param pop_size integer Population size.
---@param gene_count integer Number of genes per chromosome.
---@param seed integer Random seed value.
---@return LGeneticAlgorithm New genetic algorithm userdata.
lurek.ai.newGeneticAlgorithm = function(pop_size, gene_count, seed) end

--- Creates a BT guard decorator.
---@param predicate function Predicate callback invoked with agent and blackboard.
---@param child LBTNode Child node guarded by the predicate.
---@return LBTNode New guard node userdata.
lurek.ai.newGuard = function(predicate, child) end

--- Creates a new Hierarchical Task Network domain.
---@return LHTNDomain New HTN domain userdata.
lurek.ai.newHTNDomain = function() end

--- Creates a multi-layer influence map grid.
---@param width integer Grid width in cells.
---@param height integer Grid height in cells.
---@param cellSize number Cell size in world units.
---@return LInfluenceMap New influence map userdata.
lurek.ai.newInfluenceMap = function(width, height, cellSize) end

--- Creates a BT inverter decorator.
---@return LBTNode New inverter node userdata.
lurek.ai.newInverter = function() end

--- Creates a new Monte Carlo Tree Search engine.
---@param iterations integer Number of MCTS iterations.
---@param uct_c number UCT exploration constant.
---@param rollout_depth integer Maximum rollout depth.
---@param seed integer Random seed value.
---@return LMCTSEngine New MCTS engine userdata.
lurek.ai.newMCTSEngine = function(iterations, uct_c, rollout_depth, seed) end

--- Creates a new motivational need system.
---@return LNeedSystem New need system userdata.
lurek.ai.newNeedSystem = function() end

--- Creates a new feedforward neural network (inference only).
---@return LNeuralNet New neural network userdata.
lurek.ai.newNeuralNet = function() end

--- Creates a neuroevolution trainer (GA for neural network weights).
---@param layer_spec table Array-style table of layer definitions.
---@param pop_size integer Population size.
---@param seed integer Random seed value.
---@return LNeuroevolution New neuroevolution userdata.
lurek.ai.newNeuroevolution = function(layer_spec, pop_size, seed) end

--- Creates a new ORCA crowd avoidance solver.
---@param time_horizon number Time horizon for ORCA avoidance.
---@return LORCASolver New ORCA solver userdata.
lurek.ai.newORCASolver = function(time_horizon) end

--- Creates a BT parallel node with optional policies.
---@param successPolicy? string Optional success policy name.
---@param failurePolicy? string Optional failure policy name.
---@return LBTNode New parallel node userdata.
lurek.ai.newParallel = function(successPolicy, failurePolicy) end

--- Creates a tabular Q-learner.
---@param stateCount integer Number of discrete states.
---@param actionCount integer Number of discrete actions.
---@return LQLearner New Q-learner userdata.
lurek.ai.newQLearner = function(stateCount, actionCount) end

--- Creates a BT repeater decorator.
---@param count? integer Optional repeat count.
---@return LBTNode New repeater node userdata.
lurek.ai.newRepeater = function(count) end

--- Creates a BT selector node.
---@return LBTNode New selector node userdata.
lurek.ai.newSelector = function() end

--- Creates a BT sequence node.
---@return LBTNode New sequence node userdata.
lurek.ai.newSequence = function() end

--- Creates a named squad for formation positioning.
---@param name string Squad name.
---@return LSquad New squad userdata.
lurek.ai.newSquad = function(name) end

--- Creates a new finite state machine.
---@return LStateMachine New state machine userdata.
lurek.ai.newStateMachine = function() end

--- Creates a new steering behavior manager.
---@return LSteeringManager New steering manager userdata.
lurek.ai.newSteeringManager = function() end

--- Creates a new stimulus perception world.
---@return LStimulusWorld New stimulus world userdata.
lurek.ai.newStimulusWorld = function() end

--- Creates a new throttled strategy AI.
---@param update_interval number Seconds between re-evaluations.
---@return LStrategyAI New strategy AI userdata.
lurek.ai.newStrategyAI = function(update_interval) end

--- Creates a BT succeeder decorator.
---@return LBTNode New succeeder node userdata.
lurek.ai.newSucceeder = function() end

--- Creates a new personality trait profile.
---@return LTraitProfile New trait profile userdata.
lurek.ai.newTraitProfile = function() end

--- Creates a new utility AI evaluator.
---@return LUtilityAI New utility AI userdata.
lurek.ai.newUtilityAI = function() end

--- Creates a new AI world container.
---@return LAIWorld New AI world userdata.
lurek.ai.newWorld = function() end

---@class lurek.animation
lurek.animation = {}

--- Lua-side wrapper around an [`AnimCurve`].
---@class LAnimCurve
LAnimCurve = {}

--- Inserts or replaces a keyframe at the given time.
---@param time number Keyframe time.
---@param value number Keyframe value.
---@return nil Returns nothing.
function LAnimCurve:addKeyframe(time, value) end

--- Removes all keyframes from this animation curve, resetting it to empty.
---@return nil Returns nothing.
function LAnimCurve:clear() end

--- Returns the interpolated curve value at the given time.
---@param t number Sample time.
---@return number Returns the evaluated curve value.
function LAnimCurve:eval(t) end

--- Returns the number of keyframes currently stored.
---@return integer Returns the number of keyframes.
function LAnimCurve:keyframeCount() end

--- Sets or clears a custom Lua easing function for this curve.
---@param fn LuaValue Lua function receiving time and returning a number, or nil to clear it.
---@return nil Returns nothing.
function LAnimCurve:setCustomEasing(fn) end

--- Sets the easing kind applied between all keyframe segments.
---@param mode string Easing mode: step, linear, ease_in, ease_out, or ease_in_out.
---@return nil Returns nothing.
function LAnimCurve:setEasing(mode) end

--- Returns the type name of this object.
---@return string Returns LAnimCurve.
function LAnimCurve:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean Returns true for LAnimCurve or Object.
function LAnimCurve:typeOf(name) end

--- Lua-side wrapper around an [`AnimStateMachine`] FSM controller.
---@class LAnimStateMachine
LAnimStateMachine = {}

--- Registers a new named state that plays a clip from the embedded animation.
---@param name string State name.
---@param clip string Clip played by the state.
---@param looping boolean Whether the state clip loops.
---@return nil Returns nothing.
function LAnimStateMachine:addState(name, clip, looping) end

--- Adds a conditional transition between two states using a condition string like "speed > 0.5".
---@param from_state string Source state name.
---@param to_state string Destination state name.
---@param condition string Transition condition expression.
---@return nil Returns nothing.
function LAnimStateMachine:addTransition(from_state, to_state, condition) end

--- Immediately jumps to the named state, bypassing transition conditions.
---@param name string State name to activate.
---@return boolean Returns true if the state changed.
function LAnimStateMachine:forceState(name) end

--- Returns the source quad for the current animation frame.
---@return table Returns a table with x, y, w, and h fields, or nil if no frame is active.
function LAnimStateMachine:getQuad() end

--- Returns the name of the currently active state.
---@return string Returns the active state name.
function LAnimStateMachine:getState() end

--- Sets an FSM parameter value (number, boolean, or integer supported).
---@param name string Parameter name.
---@param value LuaValue Parameter value as a boolean, integer, or number.
---@return nil Returns nothing.
function LAnimStateMachine:setParam(name, value) end

--- Returns the type name of this object.
---@return string Returns LAnimStateMachine.
function LAnimStateMachine:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean Returns true for LAnimStateMachine or Object.
function LAnimStateMachine:typeOf(name) end

--- Advances the FSM by `dt` seconds, evaluating transitions.
---@param dt number Delta time in seconds.
---@return nil Returns nothing.
function LAnimStateMachine:update(dt) end

--- Lua-side wrapper around an [`AnimSyncGroup`].
---@class LAnimSyncGroup
LAnimSyncGroup = {}

--- Adds an animation handle to the group.
---@param handle integer Animation handle to add.
---@return nil Returns nothing.
function LAnimSyncGroup:add(handle) end

--- Removes all animation handles from the group.
---@return nil Returns nothing.
function LAnimSyncGroup:clear() end

--- Returns the number of animations currently in the group.
---@return integer Returns the number of member animations.
function LAnimSyncGroup:memberCount() end

--- Removes an animation handle from the group.
---@param handle integer Animation handle to remove.
---@return nil Returns nothing.
function LAnimSyncGroup:remove(handle) end

--- Returns the type name of this object.
---@return string Returns LAnimSyncGroup.
function LAnimSyncGroup:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean Returns true for LAnimSyncGroup or Object.
function LAnimSyncGroup:typeOf(name) end

--- Lua-side wrapper around an [`Animation`] controller.
---@class LAnimation
LAnimation = {}

--- Adds a named clip from explicit frame indices.
---@param name string Clip name.
---@param indices table Ordered frame indices for the clip.
---@param fps number Clip playback rate in frames per second.
---@param looping boolean Whether the clip should loop.
---@return nil Returns nothing.
function LAnimation:addClip(name, indices, fps, looping) end

--- Adds a named clip sliced from a sprite-sheet grid.
---@param name string Clip name.
---@param tex_w integer Source texture width in pixels.
---@param tex_h integer Source texture height in pixels.
---@param frame_w integer Frame width in pixels.
---@param frame_h integer Frame height in pixels.
---@param start integer Starting frame index in the grid.
---@param count integer Number of frames to include.
---@param fps number Clip playback rate in frames per second.
---@param looping boolean Whether the clip should loop.
---@return nil Returns nothing.
function LAnimation:addClipFromGrid(name, tex_w, tex_h, frame_w, frame_h, start, count, fps, looping) end

--- Adds a single frame to the frame pool by source rectangle.
---@param x number Source rectangle X coordinate.
---@param y number Source rectangle Y coordinate.
---@param w number Source rectangle width.
---@param h number Source rectangle height.
---@return integer Returns the added frame index.
function LAnimation:addFrame(x, y, w, h) end

--- Slices a sprite-sheet grid into frames and appends them.
---@param tex_w integer Source texture width in pixels.
---@param tex_h integer Source texture height in pixels.
---@param frame_w integer Frame width in pixels.
---@param frame_h integer Frame height in pixels.
---@param start integer Starting frame index in the grid.
---@param count integer Number of frames to append.
---@return integer Returns the total number of frames added.
function LAnimation:addFramesFromGrid(tex_w, tex_h, frame_w, frame_h, start, count) end

--- Begins a smooth crossfade from the current clip to a new named clip.
---@param clip_name string Target clip name.
---@param duration number Crossfade duration in seconds.
---@return boolean Returns true if the crossfade started.
function LAnimation:crossfade(clip_name, duration) end

--- Renders the current animation frame into a new ImageData (white bg, blue frame rect).
---@param width integer Output image width in pixels.
---@param height integer Output image height in pixels.
---@return ImageData Returns the rendered image data.
function LAnimation:drawToImage(width, height) end

--- Returns the active crossfade state.
---@return table Returns a table with from, to, and blend fields, or nil when not blending.
function LAnimation:getBlendState() end

--- Returns the name of the currently playing clip.
---@return string Returns the current clip name, or nil if no clip is active.
function LAnimation:getClip() end

--- Returns the number of registered clips.
---@return integer Returns the number of clips.
function LAnimation:getClipCount() end

--- Returns the current position within the active clip (0-based).
---@return integer Returns the current clip-local frame index.
function LAnimation:getCurrentFrame() end

--- Returns the total number of frames in the frame pool.
---@return integer Returns the total frame count.
function LAnimation:getFrameCount() end

--- Returns the source quad for the current frame.
---@return table Returns a table with x, y, w, and h fields, or nil if no frame is active.
function LAnimation:getQuad() end

--- Returns the playback speed multiplier.
---@return number Returns the playback speed multiplier.
function LAnimation:getSpeed() end

--- Returns true if the current clip is set to loop.
---@return boolean Returns true when the current clip loops.
function LAnimation:isLooping() end

--- Returns true if a clip is currently playing.
---@return boolean Returns true when a clip is playing.
function LAnimation:isPlaying() end

--- Pauses playback at the current frame.
---@return nil Returns nothing.
function LAnimation:pause() end

--- Starts playback of the named clip.
---@param name string Clip name to start.
---@return boolean Returns true if the clip started.
function LAnimation:play(name) end

--- Drains and returns all pending animation events as a table.
---@return table Returns an array of event tables.
function LAnimation:pollEvents() end

--- Resumes playback from the current frame.
---@return nil Returns nothing.
function LAnimation:resume() end

--- Sets the playback position within the current clip.
---@param index integer Clip-local frame index to select.
---@return nil Returns nothing.
function LAnimation:setFrame(index) end

--- Sets the playback speed multiplier.
---@param speed number Playback speed multiplier.
---@return nil Returns nothing.
function LAnimation:setSpeed(speed) end

--- Stops playback and resets to frame 0.
---@return nil Returns nothing.
function LAnimation:stop() end

--- Returns the type name of this object.
---@return string Returns LAnimation.
function LAnimation:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean Returns true for LAnimation or Object.
function LAnimation:typeOf(name) end

--- Advances the animation by dt seconds.
---@param dt number Delta time in seconds.
---@return nil Returns nothing.
function LAnimation:update(dt) end

--- Lua-side wrapper around a [`BlendLayerSet`] blend layer compositor.
---@class LBlendLayerSet
LBlendLayerSet = {}

--- Appends a new blend layer.
---@param name string Layer name.
---@param clip_name string Clip used by the layer.
---@param weight number Blend weight in the range 0 to 1.
---@param bones? table Optional list of bone names for the mask.
---@return boolean Returns true when the layer is added.
function LBlendLayerSet:addLayer(name, clip_name, weight, bones) end

--- Returns the blend weight of a named layer.
---@param name string Layer name.
---@return number Returns the layer weight, or nil if the layer is missing.
function LBlendLayerSet:getWeight(name) end

--- Returns the number of blend layers.
---@return integer Returns the number of layers.
function LBlendLayerSet:len() end

--- Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
---@return table Returns an array of layer info tables.
function LBlendLayerSet:listLayers() end

--- Removes a blend layer by name.
---@param name string Layer name.
---@return boolean Returns true when the layer is removed.
function LBlendLayerSet:removeLayer(name) end

--- Replaces the bone mask of a layer.
---@param name string Layer name.
---@param bones table List of bone names for the new mask.
---@return boolean Returns true when the mask is updated.
function LBlendLayerSet:setMask(name, bones) end

--- Sets the blend weight of a named layer (clamped to [0, 1]).
---@param name string Layer name.
---@param weight number New blend weight.
---@return boolean Returns true when the weight is updated.
function LBlendLayerSet:setWeight(name, weight) end

--- Returns the type name of this object.
---@return string Returns LBlendLayerSet.
function LBlendLayerSet:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean Returns true for LBlendLayerSet or Object.
function LBlendLayerSet:typeOf(name) end

--- Parses an Aseprite JSON export string and builds an animation.
---@param json_str string Aseprite JSON export text.
---@return Animation Returns a new animation controller.
lurek.animation.fromAseprite = function(json_str) end

--- Creates a new, empty Animation controller.
---@return Animation Returns a new animation controller.
lurek.animation.new = function() end

--- Creates a new empty blend layer set for compositing multiple animation clips.
---@return BlendLayerSet Returns a new blend layer set.
lurek.animation.newBlendLayerSet = function() end

--- Creates a new empty animation curve with linear interpolation.
---@return AnimCurve Returns a new animation curve.
lurek.animation.newCurve = function() end

--- Creates an animation FSM from an Animation controller and an initial state name.
---@param anim Animation Source animation controller.
---@param initial_state string Initial state name.
---@return AnimStateMachine Returns a new animation state machine.
lurek.animation.newStateMachine = function(anim, initial_state) end

--- Creates a new empty animation sync group.
---@return AnimSyncGroup Returns a new animation sync group.
lurek.animation.newSyncGroup = function() end

---@class lurek.audio
lurek.audio = {}

--- Lua-side wrapper for an audio bus resource.
---@class LBus
LBus = {}

--- Removes the ducking target from this bus.
---@return nil No value is returned.
function LBus:clearDuck() end

--- Returns the unique name string assigned to this audio bus.
---@return string Bus name.
function LBus:getName() end

--- Returns the average peak amplitude of all sources on this bus.
---@return number Average peak level for this bus.
function LBus:getPeak() end

--- Returns the bus pitch multiplier.
---@return number Current bus pitch multiplier.
function LBus:getPitch() end

--- Returns the current volume multiplier applied to all sources on this bus.
---@return number Current bus volume multiplier.
function LBus:getVolume() end

--- Returns true if this bus is paused.
---@return boolean True when the bus is paused.
function LBus:isPaused() end

--- Pauses all sources on this bus.
---@return nil No value is returned.
function LBus:pause() end

--- Resumes all sources on this bus.
---@return nil No value is returned.
function LBus:resume() end

--- Configures this bus to duck another bus while it has active sources.
---@param targetBusName string Name of the bus to duck.
---@param duckVolume number Target volume to apply while ducking.
---@return nil No value is returned.
function LBus:setDuckTarget(targetBusName, duckVolume) end

--- Sets the pitch multiplier for all sources on this bus.
---@param pitch number Pitch multiplier to apply.
---@return nil No value is returned.
function LBus:setPitch(pitch) end

--- Sets the volume for all sources on this bus.
---@param vol number Volume multiplier to apply.
---@return nil No value is returned.
function LBus:setVolume(vol) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LBus:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LBus:typeOf(name) end

--- Lua-side wrapper for a streaming audio decoder.
---@class LDecoder
LDecoder = {}

--- Decodes the next chunk of samples, or nil at EOF.
---@return SoundData Decoded audio buffer, or nil at end of stream.
function LDecoder:decode() end

--- Returns the per-sample bit depth of this decoded audio stream.
---@return integer Bit depth per sample.
function LDecoder:getBitDepth() end

--- Returns the number of audio channels.
---@return integer Number of audio channels.
function LDecoder:getChannelCount() end

--- Returns the total duration in seconds.
---@return number Total duration in seconds.
function LDecoder:getDuration() end

--- Returns the sample rate in Hz.
---@return integer Sample rate in Hz.
function LDecoder:getSampleRate() end

--- Returns true if seeking is supported.
---@return boolean True when seeking is supported.
function LDecoder:isSeekable() end

--- Releases the decoder (no-op).
---@return nil No value is returned.
function LDecoder:release() end

--- Rewinds to the beginning.
---@return nil No value is returned.
function LDecoder:rewind() end

--- Seeks to a time offset in seconds.
---@param offset number Time offset in seconds.
---@return nil No value is returned.
function LDecoder:seek(offset) end

--- Returns the current position in seconds.
---@return number Current position in seconds.
function LDecoder:tell() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LDecoder:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LDecoder:typeOf(name) end

--- Lua-side wrapper for the MIDI player.
---@class LMidiPlayer
LMidiPlayer = {}

--- Returns the assigned bus, or nil.
---@return LBus Assigned bus, or nil if no bus is set.
function LMidiPlayer:getBus() end

--- Returns the number of MIDI channels.
---@return integer Number of MIDI channels.
function LMidiPlayer:getChannelCount() end

--- Returns the GM instrument for a MIDI channel (1-indexed).
---@param ch integer MIDI channel index starting at 1.
---@return integer General MIDI instrument number.
function LMidiPlayer:getChannelInstrument(ch) end

--- Returns the volume for a MIDI channel (1-indexed).
---@param ch integer MIDI channel index starting at 1.
---@return number Channel volume multiplier.
function LMidiPlayer:getChannelVolume(ch) end

--- Returns the PCM output channel count (1 = mono, 2 = stereo).
---@return integer Output channel count.
function LMidiPlayer:getChannels() end

--- Returns the total MIDI duration in seconds.
---@return number Total MIDI duration in seconds.
function LMidiPlayer:getDuration() end

--- Returns the file path of the loaded MIDI, or nil.
---@return string Loaded MIDI file path, or nil if none is loaded.
function LMidiPlayer:getFilePath() end

--- Returns the total note count in the MIDI sequence.
---@return integer Total note count in the sequence.
function LMidiPlayer:getNoteCount() end

--- Returns the original MIDI file tempo in BPM.
---@return number Original tempo in beats per minute.
function LMidiPlayer:getOriginalTempo() end

--- Returns the PCM output sample rate in Hz.
---@return integer Output sample rate in Hz.
function LMidiPlayer:getSampleRate() end

--- Returns the SoundFont file path, or nil (stub).
---@return string SoundFont file path, or nil if none is set.
function LMidiPlayer:getSoundFontPath() end

--- Returns the current tempo in BPM.
---@return number Current tempo in beats per minute.
function LMidiPlayer:getTempo() end

--- Returns the current tempo scale factor.
---@return number Current tempo scale factor.
function LMidiPlayer:getTempoScale() end

--- Returns the PPQ resolution from the MIDI header.
---@return integer Ticks per beat from the MIDI header.
function LMidiPlayer:getTicksPerBeat() end

--- Returns the number of tracks in the MIDI sequence.
---@return integer Number of tracks in the sequence.
function LMidiPlayer:getTrackCount() end

--- Returns the name of a MIDI track (1-indexed), or nil.
---@param idx integer Track index starting at 1.
---@return string Track name, or nil if the track has no name.
function LMidiPlayer:getTrackName(idx) end

--- Returns the current MIDI volume.
---@return number Current MIDI volume multiplier.
function LMidiPlayer:getVolume() end

--- Returns true if a MIDI channel is muted (1-indexed).
---@param ch integer MIDI channel index starting at 1.
---@return boolean True when the channel is muted.
function LMidiPlayer:isChannelMuted(ch) end

--- Returns true if a MIDI sequence is loaded.
---@return boolean True when a MIDI sequence is loaded.
function LMidiPlayer:isLoaded() end

--- Returns true if looping is enabled.
---@return boolean True when looping is enabled.
function LMidiPlayer:isLooping() end

--- Returns true if MIDI playback is paused.
---@return boolean True when MIDI playback is paused.
function LMidiPlayer:isPaused() end

--- Returns true if MIDI is currently playing.
---@return boolean True when MIDI playback is active.
function LMidiPlayer:isPlaying() end

--- Returns true if a track is muted (1-indexed).
---@param idx integer Track index starting at 1.
---@return boolean True when the track is muted.
function LMidiPlayer:isTrackMuted(idx) end

--- Loads a MIDI file from the given path.
---@param path string MIDI file path relative to the game directory.
---@return boolean True when the file loads successfully.
function LMidiPlayer:load(path) end

--- Loads MIDI data from a Lua string.
---@param data string Raw MIDI data bytes.
---@return boolean True when the data loads successfully.
function LMidiPlayer:loadData(data) end

--- Pauses the MIDI sequence at the current position; resume with `play()`.
---@return nil No value is returned.
function LMidiPlayer:pause() end

--- Starts or resumes MIDI sequence playback from the current position.
---@return nil No value is returned.
function LMidiPlayer:play() end

--- Seeks to a time position in seconds.
---@param secs number Playback position in seconds.
---@return nil No value is returned.
function LMidiPlayer:seek(secs) end

--- Routes MIDI output through a bus (or nil to clear).
---@param bus_val? LBus Bus to route through, or nil to clear routing.
---@return nil No value is returned.
function LMidiPlayer:setBus(bus_val) end

--- Sets the GM instrument for a MIDI channel (1-indexed).
---@param ch integer MIDI channel index starting at 1.
---@param inst integer General MIDI instrument number.
---@return nil No value is returned.
function LMidiPlayer:setChannelInstrument(ch, inst) end

--- Mutes or unmutes a MIDI channel (1-indexed).
---@param ch integer MIDI channel index starting at 1.
---@param muted boolean True to mute the channel.
---@return nil No value is returned.
function LMidiPlayer:setChannelMuted(ch, muted) end

--- Sets volume for a MIDI channel (1-indexed).
---@param ch integer MIDI channel index starting at 1.
---@param vol number Volume multiplier to apply.
---@return nil No value is returned.
function LMidiPlayer:setChannelVolume(ch, vol) end

--- Sets the PCM output channel count (clamped 1-2).
---@param channels integer Output channel count to set.
---@return nil No value is returned.
function LMidiPlayer:setChannels(channels) end

--- Enables or disables looping.
---@param looping boolean True to loop playback.
---@return nil No value is returned.
function LMidiPlayer:setLooping(looping) end

--- Registers a playback-end callback (stub).
---@param cb function Callback to register.
---@return nil No value is returned.
function LMidiPlayer:setOnEnd(cb) end

--- Registers a note-off callback (stub).
---@param cb function Callback to register.
---@return nil No value is returned.
function LMidiPlayer:setOnNoteOff(cb) end

--- Registers a note-on callback (stub).
---@param cb function Callback to register.
---@return nil No value is returned.
function LMidiPlayer:setOnNoteOn(cb) end

--- Sets the PCM output sample rate in Hz (clamped 8000-192000).
---@param rate integer Output sample rate in Hz.
---@return nil No value is returned.
function LMidiPlayer:setSampleRate(rate) end

--- Loads a SoundFont file into this player (stub).
---@param path string SoundFont file path.
---@return nil No value is returned.
function LMidiPlayer:setSoundFont(path) end

--- Sets playback tempo in BPM.
---@param bpm number Tempo in beats per minute.
---@return nil No value is returned.
function LMidiPlayer:setTempo(bpm) end

--- Sets the tempo scale factor (1.0 = original speed).
---@param scale number Tempo scale factor to apply.
---@return nil No value is returned.
function LMidiPlayer:setTempoScale(scale) end

--- Mutes or unmutes a track (1-indexed).
---@param idx integer Track index starting at 1.
---@param muted boolean True to mute the track.
---@return nil No value is returned.
function LMidiPlayer:setTrackMuted(idx, muted) end

--- Sets MIDI playback volume.
---@param vol number Volume multiplier to apply.
---@return nil No value is returned.
function LMidiPlayer:setVolume(vol) end

--- Solos a MIDI channel (1-indexed).
---@param ch integer MIDI channel index starting at 1.
---@return nil No value is returned.
function LMidiPlayer:soloChannel(ch) end

--- Stops MIDI playback and resets the playhead to the beginning.
---@return nil No value is returned.
function LMidiPlayer:stop() end

--- Returns the current playback position in seconds.
---@return number Current playback position in seconds.
function LMidiPlayer:tell() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LMidiPlayer:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LMidiPlayer:typeOf(name) end

--- Clears solo on all channels.
---@return nil No value is returned.
function LMidiPlayer:unsoloAll() end

--- Reverts to the built-in default SoundFont (stub).
---@return nil No value is returned.
function LMidiPlayer:useDefaultSoundFont() end

--- Decoded PCM audio buffer that can be created from a file or synthesised sample-by-sample.
---@class LSoundData
LSoundData = {}

--- Draws the waveform onto an ImageData buffer.
---@param target ImageData Target image buffer.
---@param x integer Left position in pixels.
---@param y integer Top position in pixels.
---@param w integer Width in pixels.
---@param h integer Height in pixels.
---@param r integer Red channel value.
---@param g integer Green channel value.
---@param b integer Blue channel value.
---@param a integer Alpha channel value.
---@return nil No value is returned.
function LSoundData:drawWaveform(target, x, y, w, h, r, g, b, a) end

--- Returns the bit depth of this audio buffer (typically 16 or 32 bits per sample).
---@return integer Bit depth per sample.
function LSoundData:getBitDepth() end

--- Get the number of channels.
---@return integer Channel count.
function LSoundData:getChannelCount() end

--- Get the audio duration in seconds.
---@return number Audio duration in seconds.
function LSoundData:getDuration() end

--- Get a specific sample by index.
---@param index integer Sample index.
---@return number Sample value.
function LSoundData:getSample(index) end

--- Get the total number of samples.
---@return integer Total sample count.
function LSoundData:getSampleCount() end

--- Returns the sample rate of this audio buffer in Hz (e.g. 44100 or 48000).
---@return integer Sample rate in Hz.
function LSoundData:getSampleRate() end

--- Set a specific sample by index.
---@param index integer Sample index.
---@param value number Sample value to store.
---@return nil No value is returned.
function LSoundData:setSample(index, value) end

--- Lua-side wrapper for a polyphonic [`crate::audio::SoundPool`].
---@class LSoundPool
LSoundPool = {}

--- Returns the total number of voices in this pool.
---@return integer Number of voices in the pool.
function LSoundPool:getVoiceCount() end

--- Plays the next available voice and returns its SoundKey as an integer.
---@return integer Packed source id for the voice that was played.
function LSoundPool:play() end

--- Releases all voices from the mixer and invalidates this pool.
---@return nil No value is returned.
function LSoundPool:release() end

--- Routes all voices through the named bus.
---@param name string Bus name to route voices through.
---@return nil No value is returned.
function LSoundPool:setBus(name) end

--- Sets the volume for all voices in this pool.
---@param vol number Volume multiplier to apply.
---@return nil No value is returned.
function LSoundPool:setVolume(vol) end

--- Stops all voices in this pool.
---@return nil No value is returned.
function LSoundPool:stopAll() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LSoundPool:type() end

--- Returns true if the type name matches.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LSoundPool:typeOf(name) end

--- Lua-side wrapper for an audio source resource.
---@class LSource
LSource = {}

--- Removes any active filter from this source.
---@return nil No value is returned.
function LSource:clearFilter() end

--- Creates an independent copy of this source.
---@return LSource Cloned source handle.
function LSource:clone() end

--- Fades in from silence over the given duration in seconds.
---@param dur number Fade-in duration in seconds.
---@return nil No value is returned.
function LSource:fadeIn(dur) end

--- Returns the total duration in seconds.
---@return number Total duration in seconds.
function LSource:getDuration() end

--- Returns the current fade-in duration in seconds.
---@return number Current fade-in duration in seconds.
function LSource:getFadeIn() end

--- Returns the high-pass filter cutoff frequency.
---@return number High-pass cutoff frequency in Hz.
function LSource:getHighpass() end

--- Returns the low-pass filter cutoff frequency.
---@return number Low-pass cutoff frequency in Hz.
function LSource:getLowpass() end

--- Returns the current stereo panning value.
---@return number Current stereo pan value.
function LSource:getPan() end

--- Returns the current pitch multiplier.
---@return number Current pitch multiplier.
function LSource:getPitch() end

--- Returns the source type ("static" or "stream").
---@return string Source type name.
function LSource:getType() end

--- Returns the current volume multiplier.
---@return number Current volume multiplier.
function LSource:getVolume() end

--- Returns true if looping is enabled.
---@return boolean True when looping is enabled.
function LSource:isLooping() end

--- Returns true if playback is paused.
---@return boolean True when playback is paused.
function LSource:isPaused() end

--- Returns true if currently playing.
---@return boolean True when playback is active.
function LSource:isPlaying() end

--- Returns true if playback has stopped.
---@return boolean True when playback is stopped.
function LSource:isStopped() end

--- Pauses playback at the current position.
---@return nil No value is returned.
function LSource:pause() end

--- Starts or resumes playback.
---@return nil No value is returned.
function LSource:play() end

--- Resumes playback from the paused position.
---@return nil No value is returned.
function LSource:resume() end

--- Seeks to a time position in seconds.
---@param pos number Playback position in seconds.
---@return nil No value is returned.
function LSource:seek(pos) end

--- Applies a high-pass filter at the given cutoff frequency.
---@param cutoff_hz integer High-pass cutoff frequency in Hz.
---@return nil No value is returned.
function LSource:setHighpass(cutoff_hz) end

--- Enables or disables looping playback.
---@param looping boolean True to loop playback.
---@return nil No value is returned.
function LSource:setLooping(looping) end

--- Applies a low-pass filter at the given cutoff frequency.
---@param cutoff_hz integer Low-pass cutoff frequency in Hz.
---@return nil No value is returned.
function LSource:setLowpass(cutoff_hz) end

--- Sets stereo panning (-1.0 left to 1.0 right).
---@param pan number Stereo pan value from -1.0 to 1.0.
---@return nil No value is returned.
function LSource:setPan(pan) end

--- Sets the pitch multiplier (1.0 = normal).
---@param pitch number Pitch multiplier to apply.
---@return nil No value is returned.
function LSource:setPitch(pitch) end

--- Sets playback volume (0.0 = silent, 1.0 = full).
---@param vol number Volume multiplier to apply.
---@return nil No value is returned.
function LSource:setVolume(vol) end

--- Stops playback and resets seek position.
---@return nil No value is returned.
function LSource:stop() end

--- Returns the current playback position in seconds.
---@return number Current playback position in seconds.
function LSource:tell() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LSource:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LSource:typeOf(name) end

--- Adds a DSP effect to a bus.
---@param bus_name string Bus name.
---@param effect_type string Effect type name.
---@param params? table Optional effect parameter table.
---@return integer Created effect id.
lurek.audio.add_effect = function(bus_name, effect_type, params) end

--- Applies a bandpass filter (high-pass then low-pass) to a SoundData in-place.
---@param sounddata SoundData Audio buffer to modify.
---@param low_hz number High-pass cutoff frequency in Hz.
---@param high_hz number Low-pass cutoff frequency in Hz.
---@return nil No value is returned.
lurek.audio.applyBandpass = function(sounddata, low_hz, high_hz) end

--- Scales every sample by gain (clamped to [-1, 1]).
---@param sounddata SoundData Audio buffer to modify.
---@param gain number Gain multiplier to apply.
---@return nil No value is returned.
lurek.audio.applyGain = function(sounddata, gain) end

--- Applies a first-order IIR high-pass filter to a SoundData in-place.
---@param sounddata SoundData Audio buffer to modify.
---@param cutoff_hz number High-pass cutoff frequency in Hz.
---@return nil No value is returned.
lurek.audio.applyHighpass = function(sounddata, cutoff_hz) end

--- Applies a first-order IIR low-pass filter to a SoundData in-place.
---@param sounddata SoundData Audio buffer to modify.
---@param cutoff_hz number Low-pass cutoff frequency in Hz.
---@return nil No value is returned.
lurek.audio.applyLowpass = function(sounddata, cutoff_hz) end

--- Removes any active filter from a source.
---@param source LuaValue LSource userdata or numeric source id.
---@return nil No value is returned.
lurek.audio.clearFilter = function(source) end

--- Unloads the active SoundFont.
---@return nil No value is returned.
lurek.audio.clearMidiSoundFont = function() end

--- Clears any random pitch range on a source, restoring fixed pitch.
---@param src LSource Source handle.
---@return nil No value is returned.
lurek.audio.clearRandomPitch = function(src) end

--- Creates an independent copy of a source.
---@param source LuaValue LSource userdata or numeric source id.
---@return LSource Cloned source handle.
lurek.audio.clone = function(source) end

--- Creates a bus by name (functional style).
---@param name string Bus name to create.
---@param parent_name? string Optional parent bus name.
---@return nil No value is returned.
lurek.audio.create_bus = function(name, parent_name) end

--- Crossfades from one source to another over a duration.
---@param from LSource Source handle to fade out.
---@param to LSource Source handle to fade in.
---@param duration number Crossfade duration in seconds.
---@return nil No value is returned.
lurek.audio.crossfade = function(from, to, duration) end

--- Fades a source in from silence over the given duration.
---@param source LuaValue LSource userdata or numeric source id.
---@param dur number Fade-in duration in seconds.
---@return nil No value is returned.
lurek.audio.fadeIn = function(source, dur) end

--- Returns the number of currently playing sources.
---@return integer Number of active sources.
lurek.audio.getActiveSourceCount = function() end

--- Returns the peak signal level of the named bus (stub: always 0.0).
---@param bus_name string Bus name.
---@return number Peak signal level for the bus.
lurek.audio.getBusPeak = function(bus_name) end

--- Returns the RMS signal level of the named bus (stub: always 0.0).
---@param bus_name string Bus name.
---@return number RMS signal level for the bus.
lurek.audio.getBusRms = function(bus_name) end

--- Returns the current distance model name.
---@return string Current distance model name.
lurek.audio.getDistanceModel = function() end

--- Returns the current Doppler scale.
---@return number Current Doppler scale factor.
lurek.audio.getDopplerScale = function() end

--- Returns the total duration of a source in seconds.
---@param source LuaValue LSource userdata or numeric source id.
---@return number Total duration in seconds.
lurek.audio.getDuration = function(source) end

--- Returns the fade-in duration of a source.
---@param source LuaValue LSource userdata or numeric source id.
---@return number Fade-in duration in seconds.
lurek.audio.getFadeIn = function(source) end

--- Returns the free buffer slots in a queueable source.
---@param qsource_id integer Packed queueable source id.
---@return integer Number of free buffer slots.
lurek.audio.getFreeBufferCount = function(qsource_id) end

--- Returns the high-pass filter cutoff of a source.
---@param source LuaValue LSource userdata or numeric source id.
---@return number High-pass cutoff frequency in Hz.
lurek.audio.getHighpass = function(source) end

--- Returns the 3D listener position (x, y, z).
---@return number Listener X position.
---@return number Listener Y position.
---@return number Listener Z position.
lurek.audio.getListener = function() end

--- Returns the 2D listener position (x, y).
---@return number Listener X position.
---@return number Listener Y position.
lurek.audio.getListener2D = function() end

--- Returns the low-pass filter cutoff of a source.
---@param source LuaValue LSource userdata or numeric source id.
---@return number Low-pass cutoff frequency in Hz.
lurek.audio.getLowpass = function(source) end

--- Returns the global master volume.
---@return number Current master volume multiplier.
lurek.audio.getMasterVolume = function() end

--- Returns the maximum number of simultaneous sources.
---@return integer Maximum simultaneous source count.
lurek.audio.getMaxSources = function() end

--- Returns the stored master peak meter level.
---@return number Peak level from the last `setMeter` call.
lurek.audio.getMeter = function() end

--- Returns the 6-component orientation of a source.
---@param source LuaValue LSource userdata or numeric source id.
---@return number Forward vector X component.
---@return number Forward vector Y component.
---@return number Forward vector Z component.
---@return number Up vector X component.
---@return number Up vector Y component.
---@return number Up vector Z component.
lurek.audio.getOrientation = function(source) end

--- Returns the source stereo panning.
---@param source LuaValue LSource userdata or numeric source id.
---@return number Current stereo pan value.
lurek.audio.getPan = function(source) end

--- Returns the source pitch multiplier.
---@param source LuaValue LSource userdata or numeric source id.
---@return number Current source pitch multiplier.
lurek.audio.getPitch = function(source) end

--- Returns the current audio output device name.
---@return string Current output device name.
lurek.audio.getPlaybackDevice = function() end

--- Returns a table of available audio output device names.
---@return table Array-style table of device names.
lurek.audio.getPlaybackDevices = function() end

--- Returns the 3D position of a source (x, y, z).
---@param source LuaValue LSource userdata or numeric source id.
---@return number Source X position.
---@return number Source Y position.
---@return number Source Z position.
lurek.audio.getPosition = function(source) end

--- Returns the bus a source is assigned to, or nil.
---@param source LuaValue LSource userdata or numeric source id.
---@return LBus Assigned bus handle, or nil if no bus is set.
lurek.audio.getSourceBus = function(source) end

--- Returns the total number of registered sources.
---@return integer Number of registered sources.
lurek.audio.getSourceCount = function() end

--- Returns the type string ("static" or "stream") of a source.
---@param source LuaValue LSource userdata or numeric source id.
---@return string Source type name.
lurek.audio.getSourceType = function(source) end

--- Returns the current stereo width for a source.
---@param src LSource Source handle.
---@return number Current stereo width multiplier.
lurek.audio.getStereoWidth = function(src) end

--- Returns the velocity of a source (x, y, z).
---@param source LuaValue LSource userdata or numeric source id.
---@return number Source velocity on the X axis.
---@return number Source velocity on the Y axis.
---@return number Source velocity on the Z axis.
lurek.audio.getVelocity = function(source) end

--- Returns the source volume.
---@param source LuaValue LSource userdata or numeric source id.
---@return number Current source volume multiplier.
lurek.audio.getVolume = function(source) end

--- Returns true if a SoundFont is loaded.
---@return boolean True when a SoundFont is loaded.
lurek.audio.hasMidiSoundFont = function() end

--- Returns true if looping is enabled.
---@param source LuaValue LSource userdata or numeric source id.
---@return boolean True when looping is enabled.
lurek.audio.isLooping = function(source) end

--- Returns true if the source is paused.
---@param source LuaValue LSource userdata or numeric source id.
---@return boolean True when playback is paused.
lurek.audio.isPaused = function(source) end

--- Returns true if the source is playing.
---@param source LuaValue LSource userdata or numeric source id.
---@return boolean True when playback is active.
lurek.audio.isPlaying = function(source) end

--- Returns true if the source is stopped.
---@param source LuaValue LSource userdata or numeric source id.
---@return boolean True when playback is stopped.
lurek.audio.isStopped = function(source) end

--- Additively mixes another SoundData into the destination in-place.
---@param dest SoundData Destination audio buffer.
---@param src SoundData Source audio buffer.
---@return nil No value is returned.
lurek.audio.mixInto = function(dest, src) end

--- Creates a named audio bus for grouping sources.
---@param name string Bus name.
---@return LBus Created bus handle.
lurek.audio.newBus = function(name) end

--- Creates a streaming audio decoder.
---@param source string Audio file path relative to the game directory.
---@param buffersize? integer Optional decoder buffer size.
---@return LDecoder Decoder handle.
lurek.audio.newDecoder = function(source, buffersize) end

--- Creates a MIDI player, optionally loading a file.
---@param path? string Optional MIDI file path to load immediately.
---@return LMidiPlayer MIDI player handle.
lurek.audio.newMidiPlayer = function(path) end

--- Creates a polyphonic sound pool for the given file with N simultaneous voices.
---@param file_path string Audio file path relative to the game directory.
---@param voice_count integer Number of voices to allocate.
---@return LSoundPool Sound pool handle.
lurek.audio.newPool = function(file_path, voice_count) end

--- Creates a queueable source for manual PCM buffering.
---@param sample_rate integer Sample rate in Hz.
---@param bit_depth integer Bit depth per sample.
---@param channels integer Channel count.
---@param buffer_count? integer Optional number of queued buffers.
---@return integer Packed queueable source id.
lurek.audio.newQueueableSource = function(sample_rate, bit_depth, channels, buffer_count) end

--- Generates a mono sawtooth-wave SoundData buffer.
---@param freq number Wave frequency in Hz.
---@param duration number Buffer duration in seconds.
---@param sampleRate number Output sample rate in Hz.
---@param amplitude number Peak amplitude.
---@return SoundData Generated audio buffer.
lurek.audio.newSawtoothWave = function(freq, duration, sampleRate, amplitude) end

--- Generates a mono sine-wave SoundData buffer.
---@param freq number Wave frequency in Hz.
---@param duration number Buffer duration in seconds.
---@param sampleRate number Output sample rate in Hz.
---@param amplitude number Peak amplitude.
---@return SoundData Generated audio buffer.
lurek.audio.newSineWave = function(freq, duration, sampleRate, amplitude) end

--- Creates a SoundData from a file or as a silent buffer.
---@param ... LuaValue
---@return SoundData Created audio buffer.
lurek.audio.newSoundData = function(...) end

--- Loads an audio file and returns a source handle.
---@param ... string
---@return LSource Loaded source handle.
lurek.audio.newSource = function(...) end

--- Generates a mono square-wave SoundData buffer.
---@param freq number Wave frequency in Hz.
---@param duration number Buffer duration in seconds.
---@param sampleRate number Output sample rate in Hz.
---@param amplitude number Peak amplitude.
---@return SoundData Generated audio buffer.
lurek.audio.newSquareWave = function(freq, duration, sampleRate, amplitude) end

--- Generates a mono triangle-wave SoundData buffer.
---@param freq number Wave frequency in Hz.
---@param duration number Buffer duration in seconds.
---@param sampleRate number Output sample rate in Hz.
---@param amplitude number Peak amplitude.
---@return SoundData Generated audio buffer.
lurek.audio.newTriangleWave = function(freq, duration, sampleRate, amplitude) end

--- Generates a reproducible white-noise SoundData buffer.
---@param duration number Buffer duration in seconds.
---@param sampleRate number Output sample rate in Hz.
---@param amplitude number Peak amplitude.
---@param seed integer Random seed value.
---@return SoundData Generated audio buffer.
lurek.audio.newWhiteNoise = function(duration, sampleRate, amplitude, seed) end

--- Normalizes a WAV file peak amplitude to target_level and writes output.
---@param input_path string Input WAV path relative to the game directory.
---@param output_path string Output WAV path relative to the game directory.
---@param target_level number Target peak amplitude.
---@return nil No value is returned.
lurek.audio.normalizeFile = function(input_path, output_path, target_level) end

--- Pauses playback at the current position.
---@param source LuaValue LSource userdata or numeric source id.
---@return nil No value is returned.
lurek.audio.pause = function(source) end

--- Pauses all currently playing sources.
---@return nil No value is returned.
lurek.audio.pauseAll = function() end

--- Plays a source with optional bus routing.
---@param source LuaValue LSource userdata or numeric source id.
---@param options? table Optional settings table.
---@return integer Packed source id.
lurek.audio.play = function(source, options) end

--- Plays the source in a continuous loop.
---@param source LuaValue LSource userdata or numeric source id.
---@return nil No value is returned.
lurek.audio.playLooping = function(source) end

--- Starts playback of a queueable source.
---@param qsource_id integer Packed queueable source id.
---@return nil No value is returned.
lurek.audio.playQueueable = function(qsource_id) end

--- Applies a DSP effect chain to a WAV file and writes output.
---@param input_path string Input WAV path relative to the game directory.
---@param output_path string Output WAV path relative to the game directory.
---@param effects table Effect list table.
---@return nil No value is returned.
lurek.audio.processOffline = function(input_path, output_path, effects) end

--- Pushes a SoundData buffer into a queueable source.
---@param qsource_id integer Packed queueable source id.
---@param sounddata SoundData Audio buffer to queue.
---@return nil No value is returned.
lurek.audio.queueSource = function(qsource_id, sounddata) end

--- Releases a source and frees its memory.
---@param source LuaValue LSource userdata or numeric source id.
---@return boolean True when the source is released.
lurek.audio.release = function(source) end

--- Removes a DSP effect from a bus.
---@param bus_name string Bus name.
---@param effect_id integer Effect id to remove.
---@return boolean True when the effect is removed.
lurek.audio.remove_effect = function(bus_name, effect_id) end

--- Resumes playback from pause.
---@param source LuaValue LSource userdata or numeric source id.
---@return nil No value is returned.
lurek.audio.resume = function(source) end

--- Resumes all paused sources.
---@return nil No value is returned.
lurek.audio.resumeAll = function() end

--- Saves a SoundData as a 16-bit PCM WAV file at the given path.
---@param sounddata SoundData Audio buffer to save.
---@param path string Output file path relative to the game directory.
---@return nil No value is returned.
lurek.audio.saveWAV = function(sounddata, path) end

--- Seeks to a time position in seconds.
---@param source LuaValue LSource userdata or numeric source id.
---@param pos number Playback position in seconds.
---@return nil No value is returned.
lurek.audio.seek = function(source, pos) end

--- Sets the distance attenuation model.
---@param model string Distance model name.
---@return nil No value is returned.
lurek.audio.setDistanceModel = function(model) end

--- Sets the global Doppler effect scale.
---@param scale number Doppler scale factor to apply.
---@return nil No value is returned.
lurek.audio.setDopplerScale = function(scale) end

--- Applies a high-pass filter to a source.
---@param source LuaValue LSource userdata or numeric source id.
---@param cutoff_hz integer High-pass cutoff frequency in Hz.
---@return nil No value is returned.
lurek.audio.setHighpass = function(source, cutoff_hz) end

--- Sets the 3D listener position.
---@param x number Listener X position.
---@param y number Listener Y position.
---@param z? number Optional listener Z position.
---@return nil No value is returned.
lurek.audio.setListener = function(x, y, z) end

--- Sets the 2D listener position for spatial audio.
---@param x number Listener X position.
---@param y number Listener Y position.
---@return nil No value is returned.
lurek.audio.setListener2D = function(x, y) end

--- Enables or disables looping.
---@param source LuaValue LSource userdata or numeric source id.
---@param looping boolean True to loop playback.
---@return nil No value is returned.
lurek.audio.setLooping = function(source, looping) end

--- Applies a low-pass filter to a source.
---@param source LuaValue LSource userdata or numeric source id.
---@param cutoff_hz integer Low-pass cutoff frequency in Hz.
---@return nil No value is returned.
lurek.audio.setLowpass = function(source, cutoff_hz) end

--- Sets the global master volume.
---@param vol number Master volume multiplier to apply.
---@return nil No value is returned.
lurek.audio.setMasterVolume = function(vol) end

--- Sets the master peak meter level.
---@param level number Peak level in the range [0, 1].
---@return nil No value is returned.
lurek.audio.setMeter = function(level) end

--- Sets the global SoundFont for MIDI synthesis.
---@param path string SoundFont file path relative to the game directory.
---@return nil No value is returned.
lurek.audio.setMidiSoundFont = function(path) end

--- Sets the 6-component orientation of a source.
---@param source LuaValue LSource userdata or numeric source id.
---@param fx number Forward X component.
---@param fy number Forward Y component.
---@param fz number Forward Z component.
---@param ux number Up X component.
---@param uy number Up Y component.
---@param uz number Up Z component.
---@return nil No value is returned.
lurek.audio.setOrientation = function(source, fx, fy, fz, ux, uy, uz) end

--- Sets stereo panning (-1.0 left to 1.0 right).
---@param source LuaValue LSource userdata or numeric source id.
---@param pan number Stereo pan value from -1.0 to 1.0.
---@return nil No value is returned.
lurek.audio.setPan = function(source, pan) end

--- Sets source pitch multiplier.
---@param source LuaValue LSource userdata or numeric source id.
---@param pitch number Pitch multiplier to apply.
---@return nil No value is returned.
lurek.audio.setPitch = function(source, pitch) end

--- Selects an audio output device by name.
---@param name string Output device name.
---@return nil No value is returned.
lurek.audio.setPlaybackDevice = function(name) end

--- Sets the 3D position of a source.
---@param source LuaValue LSource userdata or numeric source id.
---@param x number Source X position.
---@param y number Source Y position.
---@param z? number Optional source Z position.
---@return nil No value is returned.
lurek.audio.setPosition = function(source, x, y, z) end

--- Sets a random pitch range applied each time the source is played.
---@param src LSource Source handle.
---@param min number Minimum random pitch multiplier.
---@param max number Maximum random pitch multiplier.
---@return nil No value is returned.
lurek.audio.setRandomPitch = function(src, min, max) end

--- Assigns a source to a bus.
---@param source LuaValue LSource userdata or numeric source id.
---@param bus LBus Bus handle to assign.
---@return nil No value is returned.
lurek.audio.setSourceBus = function(source, bus) end

--- Sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono).
---@param src LSource Source handle.
---@param width number Stereo width multiplier to apply.
---@return nil No value is returned.
lurek.audio.setStereoWidth = function(src, width) end

--- Sets the velocity of a source for Doppler.
---@param source LuaValue LSource userdata or numeric source id.
---@param x number Source velocity on the X axis.
---@param y number Source velocity on the Y axis.
---@param z? number Optional source velocity on the Z axis.
---@return nil No value is returned.
lurek.audio.setVelocity = function(source, x, y, z) end

--- Sets source playback volume.
---@param source LuaValue LSource userdata or numeric source id.
---@param vol number Volume multiplier to apply.
---@return nil No value is returned.
lurek.audio.setVolume = function(source, vol) end

--- Sets a bus volume by name.
---@param name string Bus name.
---@param volume number Volume multiplier to apply.
---@return nil No value is returned.
lurek.audio.set_bus_volume = function(name, volume) end

--- Sets a parameter on a DSP effect.
---@param bus_name string Bus name.
---@param effect_id integer Effect id to modify.
---@param param_name string Effect parameter name.
---@param value number Parameter value to set.
---@return boolean True when the parameter is updated.
lurek.audio.set_effect_param = function(bus_name, effect_id, param_name, value) end

--- Renders a time-frequency spectrogram of a WAV file to a PNG image.
---@param input_wav string Input WAV path relative to the game directory.
---@param output_png string Output PNG path relative to the game directory.
---@param width integer Image width in pixels.
---@param height integer Image height in pixels.
---@return nil No value is returned.
lurek.audio.spectrogramToPng = function(input_wav, output_png, width, height) end

--- Stops playback and resets seek position.
---@param source LuaValue LSource userdata or numeric source id.
---@return nil No value is returned.
lurek.audio.stop = function(source) end

--- Stops all currently playing sources.
---@return nil No value is returned.
lurek.audio.stopAll = function() end

--- Stops a queueable source and drains its buffers.
---@param qsource_id integer Packed queueable source id.
---@return nil No value is returned.
lurek.audio.stopQueueable = function(qsource_id) end

--- Returns the current playback position in seconds.
---@param source LuaValue LSource userdata or numeric source id.
---@return number Current playback position in seconds.
lurek.audio.tell = function(source) end

--- Renders the waveform of a WAV file to a PNG image.
---@param input_wav string Input WAV path relative to the game directory.
---@param output_png string Output PNG path relative to the game directory.
---@param width integer Image width in pixels.
---@param height integer Image height in pixels.
---@return nil No value is returned.
lurek.audio.waveformToPng = function(input_wav, output_png, width, height) end

---@class lurek.automation
lurek.automation = {}

--- Returns the name of the active script.
---@return string Active script name.
lurek.automation.getCurrentScript = function() end

--- Returns the index of the next step to be dispatched.
---@return integer Zero-based step index.
lurek.automation.getCurrentStep = function() end

--- Returns seconds elapsed since playback started.
---@return number Elapsed playback time in seconds.
lurek.automation.getElapsedTime = function() end

--- Returns the current playback speed multiplier (default 1.0).
---@return number Current playback speed multiplier.
lurek.automation.getPlaybackSpeed = function() end

--- Returns an array of all registered script names.
---@return table Array of registered script names.
lurek.automation.getScripts = function() end

--- Returns the total number of steps in the active script.
---@return integer Total number of steps.
lurek.automation.getStepCount = function() end

--- Returns the step limit for the named script.
---@param name string Script name to inspect.
---@return integer Step limit value.
lurek.automation.getStepLimit = function(name) end

--- Returns true if a macro with the given name has been saved.
---@param name string Macro name to check.
---@return boolean True when the macro exists.
lurek.automation.hasMacro = function(name) end

--- Returns true if a script with the given name is registered.
---@param name string Script name to check.
---@return boolean True when the script is registered.
lurek.automation.hasScript = function(name) end

--- Returns true if all steps in the active script have been dispatched.
---@return boolean True when the active script has finished.
lurek.automation.isComplete = function() end

--- Returns whether the highlight overlay hint is active.
---@return boolean True when highlight mode is enabled.
lurek.automation.isHighlightMode = function() end

--- Returns true if playback is currently paused.
---@return boolean True when playback is paused.
lurek.automation.isPaused = function() end

--- Returns true if the simulator is actively playing a script.
---@return boolean True when a script is currently playing.
lurek.automation.isRunning = function() end

--- Returns an array of all saved macro names.
---@return table Array of saved macro names.
lurek.automation.listMacros = function() end

--- Loads a named script from a Lua data table containing a steps array.
---@param name string Script name to register.
---@param data table Script data table containing a `steps` array.
---@return nil No value is returned.
lurek.automation.load = function(name, data) end

--- Parses a TOML string and registers it as a named script.
---@param name string Script name to register.
---@param toml_str string TOML string to parse into a script.
---@return nil No value is returned.
lurek.automation.loadFromToml = function(name, toml_str) end

--- Pauses playback at the current step position.
---@return nil No value is returned.
lurek.automation.pause = function() end

--- Loads and starts playback of a previously saved macro.
---@param name string Macro name to play.
---@return nil No value is returned.
lurek.automation.playMacro = function(name) end

--- Resumes playback from a paused position.
---@return nil No value is returned.
lurek.automation.resume = function() end

--- Saves a loaded script under a macro name for fast replay.
---@param macro_name string Macro name to save.
---@param script_name string Existing script name to copy.
---@return nil No value is returned.
lurek.automation.saveMacro = function(macro_name, script_name) end

--- Enables or disables the highlight overlay hint.
---@param enable boolean True to enable the hint overlay.
---@return nil No value is returned.
lurek.automation.setHighlightMode = function(enable) end

--- Sets the playback speed multiplier.
---@param factor number Multiplier applied to playback time.
---@return nil No value is returned.
lurek.automation.setPlaybackSpeed = function(factor) end

--- Sets the step limit for the named script.
---@param name string Script name to update.
---@param n integer New step limit value.
---@return boolean True when the script was found and updated.
lurek.automation.setStepLimit = function(name, n) end

--- Starts playback of the named script from the beginning.
---@param name string Script name to play.
---@return nil No value is returned.
lurek.automation.start = function(name) end

--- Stops playback and resets the simulator to idle.
---@return nil No value is returned.
lurek.automation.stop = function() end

--- Removes a loaded script by name, returning true if it existed.
---@param name string Script name to remove.
---@return boolean True when the script existed and was removed.
lurek.automation.unload = function(name) end

--- Advances the playback clock by `dt` seconds.
---@param dt number Seconds to advance while dispatching due steps.
---@return nil No value is returned.
lurek.automation.update = function(dt) end

--- Pauses playback advancement until a predicate returns true or a timeout expires.
---@param predicate function Callback that must return a boolean.
---@param timeout number Maximum seconds to wait before resuming.
---@return nil No value is returned.
lurek.automation.waitUntil = function(predicate, timeout) end

---@class lurek.camera
lurek.camera = {}

--- Lua-side wrapper around a [`Camera2D`] instance.
---@class LCamera
LCamera = {}

--- Applies this camera's transform to the render stack.
---@return nil No return value.
function LCamera:apply() end

--- Alias for `apply()`.
---@return nil No return value.
function LCamera:attach() end

--- Removes all parallax factor overrides, resetting every layer to the default factor of 1.0 (no parallax).
---@return nil No return value.
function LCamera:clearParallaxFactors() end

--- Clears the follow target so the camera stops tracking any position.
---@return nil No return value.
function LCamera:clearTarget() end

--- Alias for `reset()`.
---@return nil No return value.
function LCamera:detach() end

--- Animates the camera along a sequence of world-space waypoints over the given duration (seconds).
---@param points table Point array.
---@param duration number Duration in seconds.
---@return nil No return value.
function LCamera:followPath(points, duration) end

--- Returns the current world-space x/y offset contributed by the sway and shake effects.
---@return number World-space X offset in world units.
---@return number World-space Y offset in world units.
function LCamera:getEffectOffset() end

--- Returns the current zoom level including contributions from zoom pulse and breathing effects on top of the base zoom factor.
---@return number The total effective zoom level
function LCamera:getEffectiveZoom() end

--- Returns the parallax scroll factor for the named render layer.
---@param layer string The render layer name to query
---@return number The parallax factor (1.0 = moves with camera)
function LCamera:getParallaxFactor(layer) end

--- Returns the camera's current world-space position as two values.
---@return number Camera X coordinate in world space.
---@return number Camera Y coordinate in world space.
function LCamera:getPosition() end

--- Returns the camera's current rotation angle in radians.
---@return number The rotation angle in radians
function LCamera:getRotation() end

--- Returns the current screen-space viewport rectangle as four values.
---@return number Viewport X position in screen pixels.
---@return number Viewport Y position in screen pixels.
---@return number Viewport width in screen pixels.
---@return number Viewport height in screen pixels.
function LCamera:getViewport() end

--- Returns the axis-aligned bounding rectangle of the currently visible world area as four values.
---@return number Visible area X position in world space.
---@return number Visible area Y position in world space.
---@return number Visible area width in world units.
---@return number Visible area height in world units.
function LCamera:getVisibleArea() end

--- Returns the camera's current base zoom factor (before any pulse or breathing effect is applied).
---@return number The base zoom multiplier
function LCamera:getZoom() end

--- Returns true if the breathing zoom oscillation is currently active.
---@return boolean True if breathing is active
function LCamera:isBreathing() end

--- Returns true if the sway oscillation effect is currently running.
---@return boolean True if sway is active
function LCamera:isSway() end

--- Instantly snaps the camera to look at the given world-space position.
---@param x number The world X coordinate to center on
---@param y number The world Y coordinate to center on
---@return nil No return value.
function LCamera:lookAt(x, y) end

--- Translates the camera by the given delta in world space.
---@param dx number Horizontal offset in world units
---@param dy number Vertical offset in world units
---@return nil No return value.
function LCamera:move(dx, dy) end

--- Returns the fractional progress `[0, 1]` of the active path, or `1` if no path is running.
---@return number Current path progress from 0 to 1.
function LCamera:pathProgress() end

--- Removes previously set world-space bounds, allowing the camera to move freely in any direction without clamping.
---@return nil No return value.
function LCamera:removeBounds() end

--- Pops the camera transform from the render stack.
---@return nil No return value.
function LCamera:reset() end

--- Sets world-space rectangular bounds that clamp the camera position.
---@param x number Left edge of the bounding rectangle in world space
---@param y number Top edge of the bounding rectangle in world space
---@param w number Width of the bounding rectangle in world units
---@param h number Height of the bounding rectangle in world units
---@return nil No return value.
function LCamera:setBounds(x, y, w, h) end

--- Sets the dead zone half-extents for camera follow.
---@param w number Half-width of the dead zone in world units
---@param h number Half-height of the dead zone in world units
---@return nil No return value.
function LCamera:setDeadZone(w, h) end

--- Sets the follow interpolation speed for smooth camera tracking.
---@param speed number Interpolation speed (0.0 = instant, higher = faster catch-up)
---@return nil No return value.
function LCamera:setFollowSmooth(speed) end

--- Sets the look-ahead multiplier for predictive camera follow.
---@param mul number Look-ahead multiplier (0.0 = disabled, 1.0 = full velocity offset)
---@return nil No return value.
function LCamera:setLookAhead(mul) end

--- Sets the parallax scroll factor for the named render layer.
---@param layer string Layer index.
---@param factor number Factor value.
---@return nil No return value.
function LCamera:setParallaxFactor(layer, factor) end

--- Sets the camera's world-space position to the given coordinates.
---@param x number The X coordinate in world space
---@param y number The Y coordinate in world space
---@return nil No return value.
function LCamera:setPosition(x, y) end

--- Sets the camera rotation angle in radians.
---@param r number The rotation angle in radians
---@return nil No return value.
function LCamera:setRotation(r) end

--- Sets the follow target position in world space.
---@param x number The target X coordinate in world space
---@param y number The target Y coordinate in world space
---@return nil No return value.
function LCamera:setTarget(x, y) end

--- Sets the screen-space viewport rectangle in pixels.
---@param x number Left edge of the viewport in screen pixels
---@param y number Top edge of the viewport in screen pixels
---@param w number Width of the viewport in screen pixels
---@param h number Height of the viewport in screen pixels
---@return nil No return value.
function LCamera:setViewport(x, y, w, h) end

--- Sets the camera's uniform zoom factor.
---@param zoom number The zoom multiplier (1.0 = 100%)
---@return nil No return value.
function LCamera:setZoom(zoom) end

--- Starts a screen-shake effect with the given intensity and duration.
---@param intensity number Maximum random offset in world units
---@param duration number Duration of the shake effect in seconds
---@return nil No return value.
function LCamera:shake(intensity, duration) end

--- Starts a subtle periodic zoom oscillation that gives the camera a "living" feel, as if the viewport is gently breathing.
---@param amplitude? number Peak zoom offset from base (default 0.005)
---@param rate? number Oscillation rate in cycles per second (default 0.2)
---@return nil No return value.
function LCamera:startBreathing(amplitude, rate) end

--- Starts a sinusoidal x/y offset oscillation for ambient camera motion (e.g.
---@param amplitude_x number Maximum horizontal offset in world units
---@param amplitude_y number Maximum vertical offset in world units
---@param frequency number Oscillation frequency in cycles per second
---@param decay? number Decay multiplier applied each second (default 1.0 = no decay)
---@return nil No return value.
function LCamera:startSway(amplitude_x, amplitude_y, frequency, decay) end

--- Stops the active breathing zoom oscillation effect immediately.
---@return nil No return value.
function LCamera:stopBreathing() end

--- Cancels the active camera path animation immediately, leaving the camera at its current position along the path.
---@return nil No return value.
function LCamera:stopPath() end

--- Stops the active sway oscillation effect immediately, resetting the camera's offset back to zero.
---@return nil No return value.
function LCamera:stopSway() end

--- Cancels the active smooth zoom tween immediately, leaving the camera at its current zoom level.
---@return nil No return value.
function LCamera:stopZoom() end

--- Converts world-space coordinates to screen-space pixel coordinates accounting for the camera's position, zoom, rotation, and viewport.
---@param wx number World X coordinate
---@param wy number World Y coordinate
---@return number Corresponding screen-space X coordinate.
---@return number Corresponding screen-space Y coordinate.
function LCamera:toScreen(wx, wy) end

--- Converts screen-space pixel coordinates to world-space coordinates accounting for the camera's position, zoom, rotation, and viewport.
---@param sx number Screen X coordinate in pixels
---@param sy number Screen Y coordinate in pixels
---@return number Corresponding world-space X coordinate.
---@return number Corresponding world-space Y coordinate.
function LCamera:toWorld(sx, sy) end

--- Returns the string type name of this userdata object.
---@return string The type name (e.g. "LScheduler", "LCamera", "LSignal")
function LCamera:type() end

--- Checks whether this object matches the given type name.
---@param name string The type name to check against (e.g. "LScheduler", "Object")
---@return boolean True if this object matches the given type name
function LCamera:typeOf(name) end

--- Advances the camera simulation by `dt` seconds.
---@param dt number Delta time in seconds since the last frame
---@return nil No return value.
function LCamera:update(dt) end

--- Advances the path animation by `dt` seconds and applies the resulting position to the camera.
---@param dt number Delta time in seconds.
---@return boolean True if the path updated and produced a new position.
function LCamera:updatePath(dt) end

--- Advances the zoom tween by `dt` seconds and applies the resulting zoom level to the camera.
---@param dt number Delta time in seconds.
---@return boolean True if the zoom tween updated and produced a zoom value.
function LCamera:updateZoom(dt) end

--- Triggers a momentary zoom-in effect that decays back to the base zoom level via a sine envelope.
---@param amplitude number Maximum zoom offset at the pulse peak
---@param duration number Total duration of the pulse effect in seconds
---@return nil No return value.
function LCamera:zoomPulse(amplitude, duration) end

--- Smoothly tweens the camera zoom from its current level to `target_zoom` over `duration` seconds.
---@param target_zoom number Target zoom.
---@param duration number Duration in seconds.
---@return nil No return value.
function LCamera:zoomTo(target_zoom, duration) end

--- Creates a new Camera2D with the given viewport dimensions.
---@param viewport_w? number Viewport width in pixels (default 800)
---@param viewport_h? number Viewport height in pixels (default 600)
---@return LCamera New Camera2D with the given viewport dimensions.
lurek.camera.new = function(viewport_w, viewport_h) end

--- Creates a new 2D camera with the given viewport dimensions.
---@param viewport_w? number Viewport width in pixels (default 800)
---@param viewport_h? number Viewport height in pixels (default 600)
---@return LCamera New 2D camera with the given viewport dimensions.
lurek.camera.newCamera = function(viewport_w, viewport_h) end

---@class lurek.compute
lurek.compute = {}

--- Lua-side wrapper around [`NdArray`].
---@class LArray
LArray = {}

--- Element-wise absolute value.
---@return Array Absolute-value array.
function LArray:abs() end

--- Returns true if all elements are nonzero.
---@return boolean True if all elements are nonzero.
function LArray:all() end

--- Returns true if any element is nonzero.
---@return boolean True if any element is nonzero.
function LArray:any() end

--- Returns the 1-based flat index of the maximum element.
---@return integer One-based flat index of the maximum element.
function LArray:argmax() end

--- Returns the 1-based flat index of the minimum element.
---@return integer One-based flat index of the minimum element.
function LArray:argmin() end

--- Bitwise AND of two Int32 arrays.
---@param other Array Right-hand operand array.
---@return Array Bitwise AND result array.
function LArray:bitwiseAnd(other) end

--- Bitwise left shift of an Int32 array.
---@param amount integer Shift amount.
---@return Array Left-shifted array.
function LArray:bitwiseLShift(amount) end

--- Bitwise NOT of an Int32 array.
---@return Array Bitwise NOT result array.
function LArray:bitwiseNot() end

--- Bitwise OR of two Int32 arrays.
---@param other Array Right-hand operand array.
---@return Array Bitwise OR result array.
function LArray:bitwiseOr(other) end

--- Bitwise right shift of an Int32 array.
---@param amount integer Shift amount.
---@return Array Right-shifted array.
function LArray:bitwiseRShift(amount) end

--- Bitwise XOR of two Int32 arrays.
---@param other Array Right-hand operand array.
---@return Array Bitwise XOR result array.
function LArray:bitwiseXor(other) end

--- Clamps each element to the given range.
---@param min number Lower bound.
---@param max number Upper bound.
---@return Array Clamped array.
function LArray:clamp(min, max) end

--- Returns a deep copy of this array.
---@return Array Deep copy of this array.
function LArray:clone() end

--- 1D convolution with a kernel array (full output).
---@param kernel Array Kernel array.
---@return Array Convolution result array.
function LArray:convolve1d(kernel) end

--- 2D convolution with zero-padding.
---@param kernel Array Convolution kernel array.
---@return Array Convolution result array.
function LArray:convolve2D(kernel) end

--- 1D cross-correlation with a template array (valid output).
---@param template Array Template array.
---@return Array Correlation result array.
function LArray:correlate1d(template) end

--- Returns the count of nonzero elements.
---@return integer Nonzero element count.
function LArray:countNonZero() end

--- Population covariance with another 1D array.
---@param other Array Other one-dimensional array.
---@return number Covariance value.
function LArray:covariance(other) end

--- Signed 2D cross product with another length-2 array.
---@param other Array Other input value.
---@return number Signed 2D cross product.
function LArray:cross2d(other) end

--- Cumulative sum of all elements (flattened).
---@return Array Cumulative-sum array.
function LArray:cumsum() end

--- Discrete difference applied `order` times.
---@param order? integer Optional difference order.
---@return Array Difference array.
function LArray:diff(order) end

--- Morphological dilation with a diamond structuring element.
---@param radius integer Structuring element radius.
---@return Array Dilated array.
function LArray:dilate(radius) end

--- Dot product of two 1D arrays.
---@param other Array Right-hand operand array.
---@return number Dot product value.
function LArray:dot(other) end

--- Computes the dominant eigenvalue and its eigenvector using power iteration.
---@param max_iter? integer (default 1000).
---@param tol? number (default 1e-10).
---@return table Table with the dominant eigenvalue and eigenvector.
function LArray:eigenPower(max_iter, tol) end

--- Morphological erosion with a diamond structuring element.
---@param radius integer Structuring element radius.
---@return Array Eroded array.
function LArray:erode(radius) end

--- Evaluate a Lua expression string element-wise, returning a new Array.
---@param expr string - Lua expression using `x` as the input variable.
---@return Array New array with transformed values.
function LArray:eval(expr) end

--- Fills all elements with the given value in-place.
---@param val number Fill value.
---@return nil No value is returned.
function LArray:fill(val) end

--- Flood fill from a 1-based (row, col) with a new value.
---@param row integer One-based row index.
---@param col integer One-based column index.
---@param val number Fill value.
---@return Array Flood-filled result array.
function LArray:floodFill(row, col, val) end

--- Returns the element at the given 1-based indices.
---@param ... integer
---@return number Element value.
function LArray:get(...) end

--- Returns the element data type name.
---@return string Data type name.
function LArray:getDataType() end

--- Returns the number of dimensions.
---@return integer Dimension count.
function LArray:getDimensions() end

--- Extracts a rectangular sub-region (1-based row, col).
---@param row integer One-based start row.
---@param col integer One-based start column.
---@param rows integer Region row count.
---@param cols integer Region column count.
---@return Array Extracted region array.
function LArray:getRegion(row, col, rows, cols) end

--- Returns the shape as a table of dimension sizes.
---@return table Array of dimension sizes.
function LArray:getShape() end

--- Returns the total number of elements.
---@return integer Total element count.
function LArray:getSize() end

--- Compute a histogram. Returns a table of {lo, hi, count} tables.
---@param bins integer Number of histogram bins.
---@param lo? number Optional lower bound.
---@param hi? number Optional upper bound.
---@return table Array of histogram bin tables.
function LArray:histogram(bins, lo, hi) end

--- Returns false (CPU arrays only).
---@return boolean Always false for CPU arrays.
function LArray:isOnGPU() end

--- Solve A*x = b where this array is A (square [n,n]) and b is a 1D vector.
---@param b Array Blue component.
---@return Array New array.
function LArray:linsolve(b) end

--- Decomposes this square matrix into L and U factors with partial pivoting.
---@return table LU decomposition data with permutation and matrix buffers.
function LArray:luDecompose() end

--- Apply a Lua callback element-wise, returning a new Array of the same shape.
---@param fn function(value: number) -> number - called for each element.
---@return Array New array with transformed values.
function LArray:map(fn) end

--- Matrix multiplication of two 2D arrays.
---@param other Array Right-hand operand array.
---@return Array Matrix product array.
function LArray:matmul(other) end

--- Maximum of all elements, or along an axis (1-based).
---@param axis? integer Optional one-based axis.
---@return Array Reduced array, or scalar number when axis is omitted.
function LArray:max(axis) end

--- Mean of all elements, or along an axis (1-based).
---@param axis? integer Optional one-based axis.
---@return Array Reduced array, or scalar number when axis is omitted.
function LArray:mean(axis) end

--- Minimum of all elements, or along an axis (1-based).
---@param axis? integer Optional one-based axis.
---@return Array Reduced array, or scalar number when axis is omitted.
function LArray:min(axis) end

--- Returns a new Array with every element negated (multiplied by -1).
---@return Array Negated array.
function LArray:neg() end

--- Linearly rescale values to [out_min, out_max].
---@param out_min number Output minimum.
---@param out_max number Output maximum.
---@return Array Rescaled array.
function LArray:normalizeRange(out_min, out_max) end

--- L2-normalise a 1D vector.
---@return Array Normalized vector array.
function LArray:normalizeVec() end

--- Outer product of two 1D vectors -> 2D array [m, n].
---@param other Array Other input value.
---@return Array New array.
function LArray:outer(other) end

--- Pearson correlation coefficient with another 1D array.
---@param other Array Other one-dimensional array.
---@return number Correlation coefficient.
function LArray:pearsonCorr(other) end

--- Compute the p-th percentile (0-100).
---@param p number Percentile from 0 to 100.
---@return number Percentile value.
function LArray:percentile(p) end

--- Raises each element to a scalar exponent.
---@param exp number Exponent value.
---@return Array Exponentiated array.
function LArray:pow(exp) end

--- Fold the array left-to-right with an accumulator.
---@param fn function(acc: number, value: number) -> number - accumulator function.
---@param init number - initial accumulator value.
---@return number Final accumulated value.
function LArray:reduce(fn, init) end

--- Returns a new array with the given shape and the same data.
---@param shape table Target shape table.
---@return Array Reshaped array.
function LArray:reshape(shape) end

--- Running accumulation - like reduce but returns every intermediate result.
---@param fn function(acc: number, value: number) -> number - accumulator function.
---@param init number - initial accumulator value.
---@return Array Array of cumulative values (same length as input).
function LArray:scan(fn, init) end

--- Sets the element at the given 1-based indices to a value.
---@param ... number One-based indices followed by the new value.
---@return nil No value is returned.
function LArray:set(...) end

--- Copies a source array into this array at the given 1-based position.
---@param row integer One-based destination row.
---@param col integer One-based destination column.
---@param source Array Source region array.
---@return nil No value is returned.
function LArray:setRegion(row, col, source) end

--- Apply Sobel edge detection to a 2D array. Returns {gx=Array, gy=Array}.
---@return table Table with gx and gy gradient arrays.
function LArray:sobel() end

--- Element-wise square root.
---@return Array Square-rooted array.
function LArray:sqrt() end

--- Sum of all elements, or along an axis (1-based).
---@param axis? integer Optional one-based axis.
---@return Array Reduced array, or scalar number when axis is omitted.
function LArray:sum(axis) end

--- Returns a mask array with 1.0 where elements >= val, else 0.0.
---@param val number Threshold value.
---@return Array Threshold mask array.
function LArray:threshold(val) end

--- Returns all elements as a flat table of numbers.
---@return table Flat array of element values.
function LArray:toTable() end

--- Apply this 2Ă-2 or 3Ă-3 matrix to an [N,2] points array.
---@param points Array Point array.
---@return Array New array.
function LArray:transformPoints(points) end

--- Returns the transposed 2D array.
---@return Array Transposed array.
function LArray:transpose() end

--- Returns the type name "Array".
---@return string Lua-visible type name.
function LArray:type() end

--- Returns true when the given name matches "Array" or a parent type.
---@param name string Name string.
---@return boolean True if the type name matches Array or Object.
function LArray:typeOf(name) end

--- Selects elements from this where mask is nonzero, else from other.
---@param mask Array Mask array.
---@param other Array Fallback array.
---@return Array Selected result array.
function LArray:where(mask, other) end

--- Standardise values to zero mean and unit variance.
---@return Array Z-score normalized array.
function LArray:zscore() end

--- Creates a 3Ă-3 homogeneous affine matrix.
---@param tx number Translation X offset.
---@param ty number Translation Y offset.
---@param angle_rad number Angle in radians.
---@param sx number Scale factor on the X axis.
---@param sy number Scale factor on the Y axis.
---@return Array New 3Ă-3 homogeneous affine matrix.
lurek.compute.affine2d = function(tx, ty, angle_rad, sx, sy) end

--- Computes the discrete Fourier transform of a 1D real-valued sample array.
---@param samples table Sample list.
---@return table Complex frequency bins as {re, im} tables.
lurek.compute.fft = function(samples) end

--- Returns the magnitude spectrum `|X[k]|` of a real-valued sample array.
---@param samples table Sample list.
---@return table Magnitude values for each frequency bin.
lurek.compute.fftMagnitude = function(samples) end

--- Creates an array from a Lua table of numbers with optional shape and dtype.
---@param data table Input data table.
---@param shape? table Shape table.
---@param dtype? string Element data type.
---@return Array New an array from a Lua table of numbers with optional shape and dtype.
lurek.compute.fromTable = function(data, shape, dtype) end

--- Creates a sizeĂ-size Gaussian kernel array.
---@param size integer Requested size.
---@param sigma number Gaussian sigma value.
---@return Array New sizeĂ-size Gaussian kernel array.
lurek.compute.gaussianKernel = function(size, sigma) end

--- Computes the inverse discrete Fourier transform.
---@param freqs table Frequency list.
---@return table Reconstructed real-valued samples.
lurek.compute.ifft = function(freqs) end

--- Creates a zero-initialized array with the given shape and optional dtype.
---@param shape table Shape table.
---@param dtype? string Element data type.
---@return Array New zero-initialized array with the given shape and optional dtype.
lurek.compute.newArray = function(shape, dtype) end

--- Creates a one-filled array with the given shape and optional dtype.
---@param shape table Shape table.
---@param dtype? string Element data type.
---@return Array New one-filled array with the given shape and optional dtype.
lurek.compute.ones = function(shape, dtype) end

--- Creates a 1D array from start to stop with optional step and dtype.
---@param start number Start value.
---@param stop number Stop value.
---@param step? number Step value.
---@param dtype? string Element data type.
---@return Array New 1D array from start to stop with optional step and dtype.
lurek.compute.range = function(start, stop, step, dtype) end

--- Creates a 2Ă-2 rotation matrix for the given angle in radians.
---@param angle_rad number Angle in radians.
---@return Array New 2Ă-2 rotation matrix for the given angle in radians.
lurek.compute.rotate2dMatrix = function(angle_rad) end

--- Creates a zero-filled array with the given shape and optional dtype.
---@param shape table Shape table.
---@param dtype? string Element data type.
---@return Array New zero-filled array with the given shape and optional dtype.
lurek.compute.zeros = function(shape, dtype) end

---@class lurek.data
lurek.data = {}

--- Raw byte buffer for binary I/O; addressable by byte or bit offset.
---@class LByteData
LByteData = {}

--- Creates an independent copy of this byte buffer with identical contents.
---@return ByteData Cloned byte buffer.
function LByteData:clone() end

--- Returns the value of a single bit within the buffer.
---@param byte_offset integer Zero-based byte index.
---@param bit_offset integer Bit index within the byte in the range `[0, 7]`.
---@return boolean Bit value at the requested position.
function LByteData:getBit(byte_offset, bit_offset) end

--- Get a byte at the specified offset.
---@param offset integer Zero-based byte offset.
---@return integer Byte value at the requested offset.
function LByteData:getByte(offset) end

--- Returns the total byte length of this buffer.
---@return integer Total byte length of the buffer.
function LByteData:getSize() end

--- Get the string representation.
---@return string Buffer contents interpreted as a lossy UTF-8 string.
function LByteData:getString() end

--- Reads consecutive bits and packs them into a 32-bit integer.
---@param byte_offset integer Zero-based starting byte index.
---@param bit_offset integer Starting bit within the starting byte in the range `[0, 7]`.
---@param count integer Number of bits to read in the range `[1, 32]`.
---@return integer Bits packed LSB-first into a 32-bit integer.
function LByteData:readBits(byte_offset, bit_offset, count) end

--- Sets or clears a single bit within the buffer.
---@param byte_offset integer Zero-based byte index.
---@param bit_offset integer Bit index within the byte in the range `[0, 7]`.
---@param value boolean True to set the bit, false to clear it.
---@return nil No value is returned.
function LByteData:setBit(byte_offset, bit_offset, value) end

--- Set a byte at the specified offset.
---@param offset integer Zero-based byte offset.
---@param value integer Byte value to store.
---@return nil No value is returned.
function LByteData:setByte(offset, value) end

--- Access structured binary data efficiently without copying.
---@class LDataView
LDataView = {}

--- Reads a 64-bit float at the given offset.
---@param offset integer Byte offset relative to the view start.
---@return number 64-bit floating-point value.
function LDataView:getDouble(offset) end

--- Reads a 32-bit float at the given offset.
---@param offset integer Byte offset relative to the view start.
---@return number 32-bit floating-point value.
function LDataView:getFloat(offset) end

--- Reads a signed 16-bit integer at the given offset.
---@param offset integer Byte offset relative to the view start.
---@return integer Signed 16-bit value.
function LDataView:getInt16(offset) end

--- Reads a signed 32-bit integer at the given offset.
---@param offset integer Byte offset relative to the view start.
---@return integer Signed 32-bit value.
function LDataView:getInt32(offset) end

--- Reads a signed 8-bit integer at the given offset.
---@param offset integer Byte offset relative to the view start.
---@return integer Signed 8-bit value.
function LDataView:getInt8(offset) end

--- Returns the size of this view in bytes.
---@return integer Size of this view in bytes.
function LDataView:getSize() end

--- Reads an unsigned 16-bit integer at the given offset.
---@param offset integer Byte offset relative to the view start.
---@return integer Unsigned 16-bit value.
function LDataView:getUInt16(offset) end

--- Reads an unsigned 32-bit integer at the given offset.
---@param offset integer Byte offset relative to the view start.
---@return integer Unsigned 32-bit value.
function LDataView:getUInt32(offset) end

--- Reads an unsigned 8-bit integer at the given offset.
---@param offset integer Byte offset relative to the view start.
---@return integer Unsigned 8-bit value.
function LDataView:getUInt8(offset) end

--- Returns the type name of this object.
---@return string Type name `LDataView`.
function LDataView:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the object matches the requested type.
function LDataView:typeOf(name) end

--- Write-cursor wrapper for the `lurek.data` module.
---@class LDataWriter
LDataWriter = {}

--- Returns the total buffer length.
---@return integer Total buffer length in bytes.
function LDataWriter:len() end

--- Moves the write cursor to the given position.
---@param pos integer New write cursor position.
---@return nil No value is returned.
function LDataWriter:seek(pos) end

--- Returns the current write cursor position.
---@return integer Current write cursor position.
function LDataWriter:tell() end

--- Returns the buffer contents as a Lua string.
---@return string Buffer contents as raw bytes.
function LDataWriter:toBytes() end

--- Returns the type name of this object.
---@return string Type name `LDataWriter`.
function LDataWriter:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the object matches the requested type.
function LDataWriter:typeOf(name) end

--- Writes raw bytes from a Lua string.
---@param value string Raw bytes to append.
---@return nil No value is returned.
function LDataWriter:writeBytes(value) end

--- Writes a 32-bit LE float.
---@param value number 32-bit float value to write in little-endian order.
---@return nil No value is returned.
function LDataWriter:writeF32LE(value) end

--- Writes a 64-bit LE float.
---@param value number 64-bit float value to write in little-endian order.
---@return nil No value is returned.
function LDataWriter:writeF64LE(value) end

--- Writes a signed 16-bit LE integer.
---@param value integer Signed 16-bit value to write in little-endian order.
---@return nil No value is returned.
function LDataWriter:writeI16LE(value) end

--- Writes a signed 32-bit LE integer.
---@param value integer Signed 32-bit value to write in little-endian order.
---@return nil No value is returned.
function LDataWriter:writeI32LE(value) end

--- Writes a signed 8-bit integer.
---@param value integer Signed 8-bit value to write.
---@return nil No value is returned.
function LDataWriter:writeI8(value) end

--- Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
---@param value string UTF-8 string to write.
---@return nil No value is returned.
function LDataWriter:writeString(value) end

--- Writes an unsigned 16-bit BE integer.
---@param value integer Unsigned 16-bit value to write in big-endian order.
---@return nil No value is returned.
function LDataWriter:writeU16BE(value) end

--- Writes an unsigned 16-bit LE integer.
---@param value integer Unsigned 16-bit value to write in little-endian order.
---@return nil No value is returned.
function LDataWriter:writeU16LE(value) end

--- Writes an unsigned 32-bit LE integer.
---@param value integer Unsigned 32-bit value to write in little-endian order.
---@return nil No value is returned.
function LDataWriter:writeU32LE(value) end

--- Writes an unsigned 8-bit integer.
---@param value integer Unsigned 8-bit value to write.
---@return nil No value is returned.
function LDataWriter:writeU8(value) end

--- Lua-side fixed-capacity ring buffer that holds any Lua value.
---@class LRingBuffer
LRingBuffer = {}

--- Returns the maximum number of elements the buffer can hold.
---@return integer Maximum capacity of the buffer.
function LRingBuffer:capacity() end

--- Removes all elements from the buffer, releasing their registry entries.
---@return nil No value is returned.
function LRingBuffer:clear() end

--- Returns true if the buffer contains no elements.
---@return boolean True when the buffer contains no elements.
function LRingBuffer:isEmpty() end

--- Returns true if the buffer has reached its capacity.
---@return boolean True when the buffer has reached capacity.
function LRingBuffer:isFull() end

--- Returns the number of elements currently in the buffer.
---@return integer Number of elements currently stored.
function LRingBuffer:len() end

--- Returns the oldest element without removing it, or nil if empty.
---@return LuaValue Oldest stored value, or nil when the buffer is empty.
function LRingBuffer:peek() end

--- Returns the newest element without removing it, or nil if empty.
---@return LuaValue Newest stored value, or nil when the buffer is empty.
function LRingBuffer:peekNewest() end

--- Removes and returns the oldest element, or nil if the buffer is empty.
---@return LuaValue Oldest stored value, or nil when the buffer is empty.
function LRingBuffer:pop() end

--- Pushes a value onto the ring buffer.
---@param value LuaValue Value to store in the buffer.
---@return boolean Whether the push overwrote the oldest element.
function LRingBuffer:push(value) end

--- Returns all elements as an array table ordered oldest-first.
---@return table Array table ordered from oldest element to newest.
function LRingBuffer:toTable() end

--- Returns the type name of this object.
---@return string Type name `LRingBuffer`.
function LRingBuffer:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the object matches the requested type.
function LRingBuffer:typeOf(name) end

--- Compresses data using the given algorithm (deflate, gzip, lz4).
---@param format string Compression format name.
---@param data string Raw bytes to compress.
---@param level? integer Optional compression level.
---@return string Compressed bytes as a Lua string.
lurek.data.compress = function(format, data, level) end

--- Returns the CRC-32 checksum of the input data as an integer.
---@param data string Input bytes to checksum.
---@return integer CRC-32 value in the range `[0, 2^32)`.
lurek.data.crc32 = function(data) end

--- Decodes encoded text back to binary (base64, hex).
---@param format string Encoding format name.
---@param encoded string Encoded text to decode.
---@return string Decoded raw bytes as a Lua string.
lurek.data.decode = function(format, encoded) end

--- Decompresses data using the given algorithm (deflate, gzip, lz4).
---@param format string Compression format name.
---@param data string Compressed bytes to decompress.
---@return string Decompressed bytes as a Lua string.
lurek.data.decompress = function(format, data) end

--- Encodes binary data using the given format (base64, hex).
---@param format string Encoding format name.
---@param data string Raw bytes to encode.
---@return string Encoded text.
lurek.data.encode = function(format, data) end

--- Encodes a Lua table into a TOML string.
---@param tbl table Lua table to encode as TOML.
---@return string Encoded TOML document text.
lurek.data.encodeToml = function(tbl) end

--- Deserializes a MessagePack binary string back into a Lua value.
---@param bytes string MessagePack bytes to decode.
---@return LuaValue Decoded Lua value.
lurek.data.fromMsgPack = function(bytes) end

--- Returns the number of bytes the given format and values would occupy.
---@param format string Pack format string.
---@param ... LuaValue Values whose packed size should be measured.
---@return integer Total packed size in bytes.
lurek.data.getPackedSize = function(format, ...) end

--- Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
---@param algorithm string Hash algorithm name.
---@param data string Raw bytes to hash.
---@return string Hex-encoded digest string.
lurek.data.hash = function(algorithm, data) end

--- Instantiates a raw byte data container object.
---@param value integer number | string source data, or buffer size in bytes.
---@return ByteData New byte buffer instance.
lurek.data.newByteData = function(value) end

--- Creates a read-only windowed view into a byte string.
---@param data string Source byte string.
---@param offset? integer Optional starting byte offset.
---@param size? integer Optional view size in bytes.
---@return LDataView New read-only data view.
lurek.data.newDataView = function(data, offset, size) end

--- Creates a fixed-capacity ring buffer that can store any Lua value.
---@param capacity integer Maximum number of elements to retain.
---@return LRingBuffer New ring buffer instance.
lurek.data.newRingBuffer = function(capacity) end

--- Creates a new write-cursor for building binary data.
---@return LDataWriter New binary data writer.
lurek.data.newWriter = function() end

--- Packs values into a binary byte string using the format string.
---@param format string Pack format string.
---@param ... LuaValue Values to encode using the format string.
---@return string Packed bytes as a Lua string.
lurek.data.pack = function(format, ...) end

--- Parses a TOML string into a Lua table.
---@param text string TOML document text.
---@return table Parsed TOML value as a Lua table.
lurek.data.parseToml = function(text) end

--- Reads values using the Lurek2D Binary Pack Format.
---@param format string Binary pack format string.
---@param data string Packed byte string to read from.
---@param offset? integer Optional starting byte offset.
---@return LuaValue Decoded Lua values.
lurek.data.read = function(format, data, offset) end

--- Returns the byte size of a Lurek2D Binary Pack Format string.
---@param format string Binary pack format string.
---@return integer Size of the format in bytes.
lurek.data.size = function(format) end

--- Serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary.
---@param value LuaValue Lua value to serialize.
---@return string MessagePack bytes as a Lua string.
lurek.data.toMsgPack = function(value) end

--- Unpacks values from a binary byte string, returning values followed by next offset.
---@param format string Pack format string.
---@param data string Packed byte string to read from.
---@param offset? integer Optional starting byte offset.
---@return LuaValue Unpacked Lua value or values.
---@return integer Next byte offset after the unpacked values.
lurek.data.unpack = function(format, data, offset) end

--- Writes values using the Lurek2D Binary Pack Format.
---@param format string Binary pack format string.
---@param ... LuaValue Values to write using the binary format.
---@return string Packed bytes as a Lua string.
lurek.data.write = function(format, ...) end

---@class lurek.dataframe
lurek.dataframe = {}

--- Lua-side wrapper around a shared [`DataFrame`].
---@class LDataFrame
LDataFrame = {}

--- Adds a new column with an optional default value.
---@param name string New column name.
---@param default? nil boolean|number|string | Default value for new rows in the column.
---@return nil No value is returned.
function LDataFrame:addColumn(name, default) end

--- Adds a row from an optional table of name-value pairs, returns 1-based index.
---@param row_tbl? table Row values keyed by column name.
---@return integer 1-based row index of the new row.
function LDataFrame:addRow(row_tbl) end

--- Add multiple rows at once from a table of row tables.
---@param rows table Row count.
---@return nil No value is returned.
function LDataFrame:addRowBatch(rows) end

--- Applies a function to each value in a column, replacing cells with results.
---@param col string integer | Column name or 1-based column index.
---@param func function Callback applied to each cell value.
---@return nil No value is returned.
function LDataFrame:apply(col, func) end

--- Returns a deep copy of this DataFrame.
---@return LDataFrame Independent copy of the dataframe.
function LDataFrame:clone() end

--- Returns a table of column names.
---@return table Column names.
function LDataFrame:columns() end

--- Pearson correlation coefficient between two numeric columns.
---@param col_a string integer | Left column name or index.
---@param col_b string integer | Right column name or index.
---@return number Pearson correlation coefficient.
function LDataFrame:corr(col_a, col_b) end

--- Compute a correlation matrix for all numeric columns.
---@return LDataFrame DataFrame result.
function LDataFrame:correlationMatrix() end

--- Returns the row count (alias for nrows).
---@return integer Row count.
function LDataFrame:count() end

--- Counts distinct values in a column, returns a DataFrame with value and count columns.
---@param col string integer | Column name or 1-based column index.
---@return LDataFrame Dataframe with value and count columns.
function LDataFrame:countBy(col) end

--- Returns descriptive statistics for all numeric columns.
---@return LDataFrame Dataframe of descriptive statistics.
function LDataFrame:describe() end

--- Removes rows where the given column is nil, returns a new DataFrame.
---@param col string integer | Column name or 1-based column index.
---@return LDataFrame Dataframe without nil values in that column.
function LDataFrame:dropNil(col) end

--- Shannon entropy (bits) of the value distribution in a column.
---@param col string integer | Column name or index.
---@return number Shannon entropy of the column value distribution.
function LDataFrame:entropy(col) end

--- Replaces nil values in a column with the given value.
---@param col string integer | Column name or 1-based column index.
---@param val nil boolean|number|string | Replacement value for nil cells.
---@return nil No value is returned.
function LDataFrame:fillNil(col, val) end

--- Filters rows where column matches a condition, returns a new DataFrame.
---@param col string integer | Column name or 1-based column index.
---@param op string Comparison operator.
---@param val nil boolean|number|string | Value to compare against.
---@return LDataFrame Filtered dataframe copy.
function LDataFrame:filter(col, op, val) end

--- Returns all values in a column as a table.
---@param col string integer | Column name or 1-based column index.
---@return table Column values.
function LDataFrame:getColumn(col) end

--- Return a numeric column as a Lua array of numbers (nils -> 0/nan).
---@param col string integer | Column name or index.
---@return table Numeric column values as numbers.
function LDataFrame:getColumnAsF64(col) end

--- Returns a row as a table of name-value pairs.
---@param row integer 1-based row index.
---@return table Row values keyed by column name.
function LDataFrame:getRow(row) end

--- Returns a single cell value.
---@param row integer 1-based row index.
---@param col string integer | Column name or 1-based column index.
---@return table Cell value table, or nil when unavailable.
function LDataFrame:getValue(row, col) end

--- Aggregate agg_col grouped by group_col using the named function.
---@param group_col string integer | Group column name or index.
---@param agg_col string integer | Aggregate column name or index.
---@param fn_name string Function name.
---@return LDataFrame DataFrame result.
function LDataFrame:groupAgg(group_col, agg_col, fn_name) end

--- Groups rows by column value, returns a table of DataFrames keyed by value.
---@param col string integer | Column name or 1-based column index.
---@return table DataFrames keyed by grouped column values.
function LDataFrame:groupBy(col) end

--- Groups rows by column value, returns a GroupedFrame object supporting aggregate().
---@param col string integer | Column name or 1-based column index.
---@return LGroupedFrame Grouped frame for chained aggregation.
function LDataFrame:groupByObj(col) end

--- Returns the first n rows (default 5).
---@param n? integer Number of rows to keep from the start.
---@return LDataFrame Dataframe with the first rows.
function LDataFrame:head(n) end

--- Joins with another DataFrame on matching columns.
---@param other LDataFrame Dataframe to join with.
---@param this_col string integer | Join column in this dataframe.
---@param other_col string integer | Join column in the other dataframe.
---@param join_type? string Join mode such as inner, left, right, or outer.
---@return LDataFrame Joined dataframe result.
function LDataFrame:join(other, this_col, other_col, join_type) end

--- Returns the maximum numeric value in a column.
---@param col string integer | Column name or 1-based column index.
---@return number Maximum numeric value in the column.
function LDataFrame:max(col) end

--- Returns the mean of numeric values in a column.
---@param col string integer | Column name or 1-based column index.
---@return number Mean of numeric values in the column.
function LDataFrame:mean(col) end

--- Returns the median of numeric values in a column.
---@param col string integer | Column name or 1-based column index.
---@return number Median of numeric values in the column.
function LDataFrame:median(col) end

--- Appends rows from another DataFrame in-place.
---@param other LDataFrame Dataframe whose rows are appended.
---@return nil No value is returned.
function LDataFrame:merge(other) end

--- Returns the minimum numeric value in a column.
---@param col string integer | Column name or 1-based column index.
---@return number Minimum numeric value in the column.
function LDataFrame:min(col) end

--- Return the most frequent value in a column (nil if empty).
---@param col string integer | Column name or index.
---@return table Most frequent value in the column.
function LDataFrame:modeVal(col) end

--- Returns the number of columns.
---@return integer Number of columns.
function LDataFrame:ncols() end

--- Add a min-max normalized column scaled to [out_min, out_max].
---@param col string integer | Column name or index.
---@param out_min number Output min.
---@param out_max number Output max.
---@param name string Name string.
---@return nil No value is returned.
function LDataFrame:normalizeCol(col, out_min, out_max, name) end

--- Returns the number of rows.
---@return integer Number of rows.
function LDataFrame:nrows() end

--- Return a new DataFrame with only outlier rows (|z-score| > threshold).
---@param col string integer | Column name or index.
---@param threshold? number Threshold value.
---@return LDataFrame DataFrame result.
function LDataFrame:outliers(col, threshold) end

--- Creates a wide pivot table by reshaping rows into columns.
---@param row_col string integer | Column whose values become row keys.
---@param col_col string integer | Column whose distinct values become headers.
---@param val_col string integer | Column to place in the pivot cells.
---@return LDataFrame New wide pivot table by reshaping rows into columns.
function LDataFrame:pivot(row_col, col_col, val_col) end

--- Reshapes a long-format DataFrame into wide format.
---@param row_key string integer | Row key column.
---@param col_key string integer | Column key column.
---@param value_key string integer | Value column.
---@param agg? string Aggregation name.
---@return LDataFrame DataFrame result.
function LDataFrame:pivotTable(row_key, col_key, value_key, agg) end

--- Executes a SQL query against this DataFrame.
---@param sql_str string SQL query string.
---@return LDataFrame Dataframe returned by the query.
function LDataFrame:query(sql_str) end

--- Returns a new DataFrame with a dense-rank column appended.
---@param col string integer | Column name or index.
---@param order? string Sort order.
---@param result_col? string Result column name.
---@return LDataFrame New DataFrame with a dense-rank column appended.
function LDataFrame:rank(col, order, result_col) end

--- Removes a column by name or index.
---@param col string integer | Column name or 1-based column index.
---@return nil No value is returned.
function LDataFrame:removeColumn(col) end

--- Removes a row by 1-based index.
---@param row integer 1-based row index.
---@return nil No value is returned.
function LDataFrame:removeRow(row) end

--- Renames the column `old_name` to `new_name` in this DataFrame.
---@param col string integer | Column name or 1-based column index.
---@param new_name string Replacement column name.
---@return nil No value is returned.
function LDataFrame:rename(col, new_name) end

--- Returns a new DataFrame with a rolling mean column appended.
---@param col string integer | Column name or index.
---@param window integer Window size.
---@param result_col? string Result column name.
---@return LDataFrame New DataFrame with a rolling mean column appended.
function LDataFrame:rollingMean(col, window, result_col) end

--- Returns a new DataFrame with a rolling sum column appended.
---@param col string integer | Column name or index.
---@param window integer Window size.
---@param result_col? string Result column name.
---@return LDataFrame New DataFrame with a rolling sum column appended.
function LDataFrame:rollingSum(col, window, result_col) end

--- Returns a random sample of n rows.
---@param n integer Number of rows to sample.
---@param seed? integer Optional random seed.
---@return LDataFrame Sampled dataframe copy.
function LDataFrame:sample(n, seed) end

--- Selects a subset of columns, returns a new DataFrame.
---@param ... string
---@return LDataFrame Dataframe with only the selected columns.
function LDataFrame:select(...) end

--- Set a numeric column from a Lua array of numbers.
---@param col string integer | Column name or index.
---@param values table Value list.
---@return nil No value is returned.
function LDataFrame:setColumnFromF64(col, values) end

--- Sets a single cell value.
---@param row integer 1-based row index.
---@param col string integer | Column name or 1-based column index.
---@param val nil boolean|number|string | New cell value.
---@return nil No value is returned.
function LDataFrame:setValue(row, col, val) end

--- Returns rows from start to end (1-based, inclusive).
---@param start integer First 1-based row index to include.
---@param end_idx integer Last 1-based row index to include.
---@return LDataFrame Dataframe slice for the requested row range.
function LDataFrame:slice(start, end_idx) end

--- Sorts by column, returns a new DataFrame.
---@param col string integer | Column name or 1-based column index.
---@param ascending? boolean True for ascending order, false for descending.
---@return LDataFrame Sorted dataframe copy.
function LDataFrame:sort(col, ascending) end

--- Returns the population standard deviation of numeric values in a column.
---@param col string integer | Column name or 1-based column index.
---@return number Population standard deviation of the column.
function LDataFrame:stddev(col) end

--- Returns the sum of numeric values in a column.
---@param col string integer | Column name or 1-based column index.
---@return number Sum of numeric values in the column.
function LDataFrame:sum(col) end

--- Returns the last n rows (default 5).
---@param n? integer Number of rows to keep from the end.
---@return LDataFrame Dataframe with the last rows.
function LDataFrame:tail(n) end

--- Serializes this DataFrame to a binary LVDF string.
---@return string Binary LVDF payload as a Lua string.
function LDataFrame:toBinary() end

--- Serializes this DataFrame to a CSV string.
---@return string CSV serialization of this DataFrame.
function LDataFrame:toCSV() end

--- Serializes this DataFrame to a JSON string.
---@return string JSON serialization of this DataFrame.
function LDataFrame:toJSON() end

--- Returns a formatted string table representation.
---@return string Formatted table representation.
function LDataFrame:toString() end

--- Converts this DataFrame to a Lua table of row tables.
---@return table Array of row tables.
function LDataFrame:toTable() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LDataFrame:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True if the type name matches DataFrame or Object.
function LDataFrame:typeOf(name) end

--- Returns unique values in a column as a table.
---@param col string integer | Column name or 1-based column index.
---@return table Unique values from the column.
function LDataFrame:unique(col) end

--- Returns the population variance of numeric values in a column.
---@param col string integer | Column name or 1-based column index.
---@return number Population variance of the column.
function LDataFrame:variance(col) end

--- Add a cumulative-sum column.
---@param col string integer | Column name or index.
---@param name string Name string.
---@return nil No value is returned.
function LDataFrame:withCumsum(col, name) end

--- Returns a new DataFrame with an additional computed column named `col_name`.
---@param col_name string Output column name.
---@param expr string Expression string.
---@return LDataFrame New DataFrame with an additional computed column named col_name.
function LDataFrame:withEval(col_name, expr) end

--- Add a percent-change-from-previous-row column.
---@param col string integer | Column name or index.
---@param name string Name string.
---@return nil No value is returned.
function LDataFrame:withPctChange(col, name) end

--- Add a rank column (1-based, ties averaged).
---@param col string integer | Source column name or 1-based column index.
---@param ascending? boolean True for ascending rank, false for descending.
---@param name string Name of the output column.
---@return nil No value is returned.
function LDataFrame:withRank(col, ascending, name) end

--- Add a rolling maximum column.
---@param col string integer | Source column name or 1-based column index.
---@param window integer Window size in rows.
---@param name string Name of the output column.
---@return nil No value is returned.
function LDataFrame:withRollingMax(col, window, name) end

--- Add a rolling mean column. Rows with insufficient history get nil.
---@param col string integer | Source column name or 1-based column index.
---@param window integer Window size in rows.
---@param name string Name of the output column.
---@return nil No value is returned.
function LDataFrame:withRollingMean(col, window, name) end

--- Add a rolling minimum column.
---@param col string integer | Source column name or 1-based column index.
---@param window integer Window size in rows.
---@param name string Name of the output column.
---@return nil No value is returned.
function LDataFrame:withRollingMin(col, window, name) end

--- Add a rolling sum column.
---@param col string integer | Source column name or 1-based column index.
---@param window integer Window size in rows.
---@param name string Name of the output column.
---@return nil No value is returned.
function LDataFrame:withRollingSum(col, window, name) end

--- Add a z-score column for the given numeric column.
---@param col string integer | Column name or index.
---@param name string Name string.
---@return nil No value is returned.
function LDataFrame:zscoreCol(col, name) end

--- Lua-side wrapper around a shared [`Database`].
---@class LDatabase
LDatabase = {}

--- Adds or replaces a table by cloning the given DataFrame.
---@param name string Name string.
---@param df LDataFrame Df value.
---@return nil No value is returned.
function LDatabase:addTable(name, df) end

--- Drops every table from this in-memory database, leaving it empty.
---@return nil No value is returned.
function LDatabase:clear() end

--- Returns a copy of a table by name, or nil if not found.
---@param name string Name string.
---@return LDataFrame Copy of a table by name, or nil if not found.
function LDatabase:getTable(name) end

--- Returns true if a table with the given name exists.
---@param name string Name string.
---@return boolean True when a table with the given name exists.
function LDatabase:hasTable(name) end

--- Returns a table of all table names.
---@return table Sequential table of table names.
function LDatabase:listTables() end

--- Merges all tables from another Database into this one.
---@param other LDatabase Other input value.
---@return nil No value is returned.
function LDatabase:merge(other) end

--- Executes a SQL query against the database tables.
---@param sql_str string SQL query string.
---@return LDataFrame DataFrame result.
function LDatabase:query(sql_str) end

--- Drops the named table from this in-memory database if it exists.
---@param name string Name string.
---@return nil No value is returned.
function LDatabase:removeTable(name) end

--- Returns the number of tables.
---@return integer Number of tables in the database.
function LDatabase:tableCount() end

--- Serializes all tables to a JSON object string.
---@return string JSON object string containing all tables.
function LDatabase:toJSON() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LDatabase:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True when the requested type name matches this userdata.
function LDatabase:typeOf(name) end

--- Lua-side wrapper around a grouped result from [`DataFrame::group_by`].
---@class LGroupedFrame
LGroupedFrame = {}

--- Apply a Lua function to aggregate a column's values per group.
---@param col_name string Column to aggregate.
---@param fn function Callback that receives the group's numeric values.
---@return LDataFrame DataFrame with group keys and aggregated values.
function LGroupedFrame:aggregate(col_name, fn) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LGroupedFrame:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True if the type name matches LGroupedFrame or Object.
function LGroupedFrame:typeOf(name) end

--- Thin Lua wrapper around a [`VecFrame`]: typed-column vectorized DataFrame.
---@class LVecFrame
LVecFrame = {}

--- Return a new VecFrame containing only the rows where mask[i] is true.
---@param mask table array of booleans (from filterMask).
---@return LVecFrame Vector frame userdata.
function LVecFrame:applyMask(mask) end

--- Apply absolute value to every element of a Float64 column.
---@param col string Column name or index.
---@return nil No value is returned.
function LVecFrame:colAbs(col) end

--- Add a scalar to every element of a Float64 column.
---@param col string Column name or index.
---@param val number Val value.
---@return nil No value is returned.
function LVecFrame:colAdd(col, val) end

--- Cast a column to a new dtype: "float64", "int64", or "text".
---@param col string Column name or index.
---@param dtype string Element data type.
---@return nil No value is returned.
function LVecFrame:colCast(col, dtype) end

--- Apply ceiling to every element of a Float64 column.
---@param col string Column name or index.
---@return nil No value is returned.
function LVecFrame:colCeil(col) end

--- Clamp every element of a Float64 column to [min, max].
---@param col string Column name or index.
---@param min_val number Minimum val.
---@param max_val number Maximum val.
---@return nil No value is returned.
function LVecFrame:colClamp(col, min_val, max_val) end

--- Divide every element of a Float64 column by a scalar.
---@param col string Column name or index.
---@param val number Val value.
---@return nil No value is returned.
function LVecFrame:colDiv(col, val) end

--- Apply floor to every element of a Float64 column.
---@param col string Column name or index.
---@return nil No value is returned.
function LVecFrame:colFloor(col) end

--- Multiply every element of a Float64 column by a scalar.
---@param col string Column name or index.
---@param val number Val value.
---@return nil No value is returned.
function LVecFrame:colMul(col, val) end

--- Negate every element of a Float64 column.
---@param col string Column name or index.
---@return nil No value is returned.
function LVecFrame:colNeg(col) end

--- Compute out[i] = left[i] op right[i] for every row.
---@param out_col string Output column name.
---@param left_col string Left input column.
---@param op string Operation name.
---@param right_col string Right input column.
---@return nil No value is returned.
function LVecFrame:colOp(out_col, left_col, op, right_col) end

--- Apply square root to every element of a Float64 column.
---@param col string Column name or index.
---@return nil No value is returned.
function LVecFrame:colSqrt(col) end

--- Subtract a scalar from every element of a Float64 column.
---@param col string Column name or index.
---@param val number Val value.
---@return nil No value is returned.
function LVecFrame:colSub(col, val) end

--- Return the dtype name of a column: "float64", "int64", "bool", or "text".
---@param col string Column name or index.
---@return string Column dtype name.
function LVecFrame:colType(col) end

--- Return a table of column names.
---@return table Sequential table of column names.
function LVecFrame:columns() end

--- Build a boolean row mask: mask[i] = col[i] cmp_op val.
---@param col string Column name or index.
---@param cmp_op string Comparison operator.
---@param val number Comparison value.
---@return table array of booleans.
function LVecFrame:filterMask(col, cmp_op, val) end

--- Return the number of columns.
---@return integer Number of columns.
function LVecFrame:ncols() end

--- Return the number of rows.
---@return integer Number of rows.
function LVecFrame:nrows() end

--- Reduce multiple columns in parallel, returning {col -> value} table.
---@param cols table array of column name strings.
---@param op string Operation name.
---@return table Table mapping each column name to its reduced value.
function LVecFrame:parReduce(cols, op) end

--- Apply a scalar op in parallel to multiple Float64 columns.
---@param cols table array of column name strings.
---@param op string Operation name.
---@param val number Val value.
---@return nil No value is returned.
function LVecFrame:parScalarOp(cols, op, val) end

--- Reduce an entire numeric column to a single value.
---@param col string Column name or index.
---@param op string Operation name.
---@return number Reduced numeric value for the column.
function LVecFrame:reduce(col, op) end

--- Convert this VecFrame back to a DataFrame.
---@return LDataFrame DataFrame result.
function LVecFrame:toDataFrame() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LVecFrame:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True when the requested type name matches this userdata.
function LVecFrame:typeOf(name) end

--- Deserializes a binary LVDF string into a DataFrame.
---@param s string Binary LVDF data.
---@return LDataFrame Dataframe parsed from the binary payload.
lurek.dataframe.fromBinary = function(s) end

--- Parses a CSV string into a DataFrame.
---@param s string CSV text to parse.
---@return LDataFrame Dataframe parsed from the CSV text.
lurek.dataframe.fromCSV = function(s) end

--- Parses a JSON string into a DataFrame.
---@param s string JSON text to parse.
---@return LDataFrame Dataframe parsed from the JSON text.
lurek.dataframe.fromJSON = function(s) end

--- Creates a DataFrame from an array of row tables.
---@param rows table Array of row tables keyed by column name.
---@return LDataFrame Dataframe built from the input rows.
lurek.dataframe.fromTable = function(rows) end

--- Converts a VecFrame back to a DataFrame.
---@param vf LVecFrame Source vectorized frame.
---@return LDataFrame Dataframe converted from the vectorized frame.
lurek.dataframe.fromVec = function(vf) end

--- Creates a new empty DataFrame.
---@return LDataFrame New empty dataframe.
lurek.dataframe.newDataFrame = function() end

--- Creates a new empty Database.
---@return LDatabase New empty database.
lurek.dataframe.newDatabase = function() end

--- Generates a DataFrame with random data from column definitions.
---@param defs table Array of column definition pairs.
---@param n integer Number of rows to generate.
---@param seed? integer Optional random seed.
---@return LDataFrame Randomly generated dataframe.
lurek.dataframe.random = function(defs, n, seed) end

--- Converts a DataFrame to a VecFrame for vectorized column operations.
---@param df LDataFrame Source dataframe.
---@return LVecFrame Vectorized frame built from the dataframe.
lurek.dataframe.toVec = function(df) end

---@class lurek.debugbridge
lurek.debugbridge = {}

--- Broadcasts a JSON event to all connected clients.
---@param event string Event name to broadcast.
---@param json_data string JSON payload string for the event.
---@return nil No value is returned.
lurek.debugbridge.broadcast = function(event, json_data) end

--- Captures a print message and broadcasts it to connected clients.
---@param msg string Print message text.
---@param source? string Optional source name for the message.
---@param line? integer Optional source line number.
---@return nil No value is returned.
lurek.debugbridge.capturePrint = function(msg, source, line) end

--- Clears the print history.
---@return nil No value is returned.
lurek.debugbridge.clearPrintHistory = function() end

--- Returns the number of connected TCP clients.
---@return integer Number of currently connected clients.
lurek.debugbridge.getClientCount = function() end

--- Returns performance statistics.
---@return table Performance metrics table.
lurek.debugbridge.getPerformance = function() end

--- Returns the server port (0 if not running).
---@return integer Bound TCP port, or 0 when stopped.
lurek.debugbridge.getPort = function() end

--- Returns the print history.
---@param count? integer Optional maximum number of recent entries to return.
---@return table Print history entries.
lurek.debugbridge.getPrintHistory = function(count) end

--- Returns whether the server is currently running.
---@return boolean Whether the debug server is active.
lurek.debugbridge.isRunning = function() end

--- Returns whether a screenshot is currently requested.
---@return boolean Whether a screenshot request is pending.
lurek.debugbridge.isScreenshotRequested = function() end

--- Poll for pending Lua-dependent requests from TCP clients.
---@return nil No value is returned.
lurek.debugbridge.poll = function() end

--- Flags a screenshot request for the next frame.
---@param scale? integer Optional screenshot scale factor clamped to 1 through 8.
---@return nil No value is returned.
lurek.debugbridge.requestScreenshot = function(scale) end

--- Sets the maximum print history size.
---@param max integer Maximum number of entries to retain.
---@return nil No value is returned.
lurek.debugbridge.setMaxPrintHistory = function(max) end

--- Start the TCP debug server on 127.0.0.1:port.
---@param port? integer Optional TCP port to bind on localhost.
---@return boolean Whether the server was started.
lurek.debugbridge.start = function(port) end

--- Stop the TCP debug server and close all connections.
---@return nil No value is returned.
lurek.debugbridge.stop = function() end

---@class lurek.devtools
lurek.devtools = {}

--- Lua-side handle for a per-path file watcher.
---@class LFileWatcher
LFileWatcher = {}

--- Removes the stored `onChanged` callback and stops future notifications.
---@return nil No value is returned.
function LFileWatcher:cancel() end

--- Polls the watcher. If the file has changed since the last call, fires the
---@return boolean True if the watched path changed.
function LFileWatcher:check() end

--- Returns the watched path string.
---@return string Watched path.
function LFileWatcher:getPath() end

--- Registers a callback invoked (with no arguments) when the watched path changes.
---@param fn function Fn value.
---@return nil No value is returned.
function LFileWatcher:onChanged(fn) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LFileWatcher:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True if the type name matches LFileWatcher or Object.
function LFileWatcher:typeOf(name) end

--- Lua-side wrapper around a [`ReplConsole`] interactive evaluator.
---@class LReplConsole
LReplConsole = {}

--- Clears the REPL history buffer.
---@return nil No value is returned.
function LReplConsole:clear() end

--- Evaluates a Lua snippet and records the input in history.
---@param code string Lua code string.
---@return string REPL result or error text.
function LReplConsole:eval(code) end

--- Returns an ordered array of past inputs (oldest first).
---@return table History entries from oldest to newest.
function LReplConsole:history() end

--- Returns the number of history entries.
---@return integer Number of history entries.
function LReplConsole:len() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LReplConsole:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True if the type name matches LReplConsole or Object.
function LReplConsole:typeOf(name) end

--- Discards all accumulated log entries from the in-memory devtools log buffer.
---@return nil No value is returned.
lurek.devtools.clearLog = function() end

--- Clears all watched paths.
---@return nil No value is returned.
lurek.devtools.clearWatches = function() end

--- Logs a message at DEBUG level.
---@param message string Message text.
---@return nil No value is returned.
lurek.devtools.debug = function(message) end

--- Logs a message at ERROR level.
---@param message string Message text.
---@return nil No value is returned.
lurek.devtools.error = function(message) end

--- Evaluates a Lua string and returns (success, results...).
---@param code string Lua code string.
---@return boolean True if the code executed successfully.
lurek.devtools.eval = function(code) end

--- Registers a named live watch. The getter function is called on demand to sample a value.
---@param name string Name string.
---@param getter function Getter callback.
---@param category? string Category name.
---@return integer Identifier for the new watch.
lurek.devtools.exposeWatch = function(name, getter, category) end

--- Logs a message at FATAL level.
---@param message string Message text.
---@return nil No value is returned.
lurek.devtools.fatal = function(message) end

--- Returns the Lua call stack as a table of frames.
---@param max_depth? integer Maximum recursion depth.
---@return table Sequential table of Lua stack-frame tables.
lurek.devtools.getCallStack = function(max_depth) end

--- Returns the raw frame-time sample array.
---@return table Recorded frame-time samples.
lurek.devtools.getFrameHistory = function() end

--- Returns the current frame-history buffer capacity.
---@return integer Frame-history buffer capacity.
lurek.devtools.getFrameHistorySize = function() end

--- Returns a table of computed frame statistics.
---@return table Computed frame statistics.
lurek.devtools.getFrameStats = function() end

--- Returns whether console log output is enabled.
---@return boolean True if console log output is enabled.
lurek.devtools.getLogConsole = function() end

--- Returns the current log file path.
---@return string Current log file path.
lurek.devtools.getLogFile = function() end

--- Returns recent log entries as an array of tables.
---@param count? integer Maximum number of entries to return.
---@return table Recent log entry records.
lurek.devtools.getLogHistory = function(count) end

--- Returns the current minimum log level.
---@return string Current minimum log level name.
lurek.devtools.getLogLevel = function() end

--- Returns zone data table for a specific frame (0 or nil = most recent).
---@param frame? integer Frame value.
---@return table Zone data records for the requested frame.
lurek.devtools.getProfileData = function(frame) end

--- Returns the number of retained profile frames.
---@return integer Number of retained profile frames.
lurek.devtools.getProfileFrameCount = function() end

--- Returns the file watch poll interval in seconds.
---@return number File watch poll interval in seconds.
lurek.devtools.getWatchInterval = function() end

--- Returns an array of all watched paths.
---@return table Watched file paths.
lurek.devtools.getWatchedPaths = function() end

--- Calls all registered watch getters and returns a table of {name, category, value} records.
---@return table Watch records with name, category, and sampled value.
lurek.devtools.getWatches = function() end

--- Logs a message at INFO level.
---@param message string Message text.
---@return nil No value is returned.
lurek.devtools.info = function(message) end

--- Returns whether the console is considered open.
---@return boolean True if the console is open.
lurek.devtools.isConsoleOpen = function() end

--- Returns whether the profiler is enabled.
---@return boolean True if the profiler is enabled.
lurek.devtools.isProfilingEnabled = function() end

--- Logs a message at the given level.
---@param level string Level name.
---@param message string Message text.
---@return nil No value is returned.
lurek.devtools.log = function(level, message) end

--- Creates a standalone per-path file watcher. Call `:check()` once per frame
---@param path string file or directory path to watch.
---@return FileWatcher New standalone per-path file watcher. Call :check() once per frame.
lurek.devtools.newFileWatcher = function(path) end

--- Creates an interactive Lua REPL console with a bounded history buffer.
---@param max_history? integer Maximum history length.
---@return ReplConsole REPL console userdata.
lurek.devtools.newRepl = function(max_history) end

--- Opens the console window (updates the console flag; returns true).
---@return boolean True after opening the console flag.
lurek.devtools.openConsole = function() end

--- Seals the current frame of profiling data.
---@return nil No value is returned.
lurek.devtools.profileFrame = function() end

--- Closes the most recent profiling zone.
---@param value? string Value to store.
---@return nil No value is returned.
lurek.devtools.profilePop = function(value) end

--- Opens a named profiling zone on the stack.
---@param name string Name string.
---@return nil No value is returned.
lurek.devtools.profilePush = function(name) end

--- Returns a flat summary table of all recorded profiler zones across all stored
---@return table Profiler zone summary records.
lurek.devtools.profilerReport = function() end

--- Records a frame-time sample (call each frame with delta time in seconds).
---@param dt number Delta time in seconds.
---@return nil No value is returned.
lurek.devtools.recordFrameTime = function(dt) end

--- Removes a watch by the id returned from exposeWatch. Returns true if removed.
---@param id integer Watch identifier returned by exposeWatch.
---@return boolean True if the watch was removed.
lurek.devtools.removeWatch = function(id) end

--- Clears all profiling data and resets the zone stack.
---@return nil No value is returned.
lurek.devtools.resetProfile = function() end

--- Polls all watched paths and returns paths whose mtime changed.
---@return table Paths whose modification time changed.
lurek.devtools.scan = function() end

--- Sets the frame-history buffer capacity (clamped 10-10000).
---@param size integer Requested size.
---@return nil No value is returned.
lurek.devtools.setFrameHistorySize = function(size) end

--- Enables or disables console log output.
---@param enabled boolean Whether it is enabled.
---@return nil No value is returned.
lurek.devtools.setLogConsole = function(enabled) end

--- Sets the log file path (empty string disables file output).
---@param path string Filesystem path.
---@return nil No value is returned.
lurek.devtools.setLogFile = function(path) end

--- Sets the minimum log level.
---@param level string Level name.
---@return nil No value is returned.
lurek.devtools.setLogLevel = function(level) end

--- Enables or disables the profiler.
---@param enabled boolean Whether it is enabled.
---@return nil No value is returned.
lurek.devtools.setProfilingEnabled = function(enabled) end

--- Sets the file watch poll interval in seconds.
---@param interval number Interval in seconds.
---@return nil No value is returned.
lurek.devtools.setWatchInterval = function(interval) end

--- Takes a structured snapshot of all watches + frame stats + last profile frame.
---@return table Snapshot of watches, frame stats, profile, and log data.
lurek.devtools.snapshot = function() end

--- Logs a message at TRACE level.
---@param message string Message text.
---@return nil No value is returned.
lurek.devtools.trace = function(message) end

--- Removes a file path from the watch list.
---@param path string Filesystem path.
---@return boolean True if the path was removed from the watch list.
lurek.devtools.unwatch = function(path) end

--- Logs a message at WARN level.
---@param message string Message text.
---@return nil No value is returned.
lurek.devtools.warn = function(message) end

--- Adds a file path to the watch list. Returns false if already watched.
---@param path string Filesystem path.
---@return boolean True if the path was added to the watch list.
lurek.devtools.watch = function(path) end

---@class lurek.docs
lurek.docs = {}

--- Wraps a catalog snapshot of API entries for Lua access.
---@class LApiCatalog
LApiCatalog = {}

--- Returns the number of entries, optionally scoped to a module.
---@param module? string Optional module name filter.
---@return integer Number of matching entries.
function LApiCatalog:entryCount(module) end

--- Returns a new catalog containing only entries for which predicate returns true.
---@param predicate function Predicate called with each entry.
---@return LApiCatalog Filtered API catalog.
function LApiCatalog:filter(predicate) end

--- Returns all entries, optionally filtered to a single module.
---@param module? string Optional module name filter.
---@return table Array of matching documentation entries.
function LApiCatalog:getEntries(module) end

--- Returns a single entry by qualified name, or nil.
---@param qualified_name string Qualified entry name.
---@return LDocEntry Matching documentation entry when found.
function LApiCatalog:getEntry(qualified_name) end

--- Returns a sorted list of module names present in the catalog.
---@return table Array of module names.
function LApiCatalog:getModules() end

--- Returns entries that are methods of the given type qualified name.
---@param qualified_name string Qualified type name.
---@return table Array of matching method entries.
function LApiCatalog:getTypeMethods(qualified_name) end

--- Returns the names of all entries with kind "type" in the given module.
---@param module_name string Module name to inspect.
---@return table Array of type names.
function LApiCatalog:getTypes(module_name) end

--- Returns a new catalog that is the union of this and another catalog, with other overriding duplicates.
---@param other userdata Another API catalog userdata.
---@return LApiCatalog Merged API catalog.
function LApiCatalog:merge(other) end

--- Returns a table of entries whose name, qualified name, or description contains query.
---@param query string Search text.
---@return table Array of matching entries.
function LApiCatalog:search(query) end

--- Serialises the catalog to a pretty-printed JSON string.
---@return string Pretty-printed JSON representation.
function LApiCatalog:toJSON() end

--- Converts the catalog to a plain Lua table array.
---@return table Plain Lua table array of entries.
function LApiCatalog:toTable() end

--- Returns the type name of this object.
---@return string Type name.
function LApiCatalog:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True when the type matches.
function LApiCatalog:typeOf(name) end

--- Wraps a single doc entry for Lua access.
---@class LDocEntry
LDocEntry = {}

--- Returns the deprecation message, or nil.
---@return string Deprecation message when present.
function LDocEntry:getDeprecated() end

--- Returns the human-readable description text for this documentation entry.
---@return string Description text.
function LDocEntry:getDescription() end

--- Returns the example snippet, or nil.
---@return string Example snippet when present.
function LDocEntry:getExample() end

--- Returns the kind tag for this entry (e.g. `'function'`, `'method'`, `'class'`).
---@return string Entry kind.
function LDocEntry:getKind() end

--- Returns the Lua module name this entry belongs to (e.g. `'lurek.math'`).
---@return string Module name.
function LDocEntry:getModule() end

--- Returns the symbol name for this documentation entry.
---@return string Entry name.
function LDocEntry:getName() end

--- Returns the parameters as a table of `{name, type, description, optional, default?}` records.
---@return table Array of parameter records.
function LDocEntry:getParameters() end

--- Returns the qualified name.
---@return string Fully qualified entry name.
function LDocEntry:getQualifiedName() end

--- Returns the return values as a table of `{type, description}` records.
---@return table Array of return-value records.
function LDocEntry:getReturns() end

--- Returns the quality score in [0,1].
---@return number Quality score.
function LDocEntry:getScore() end

--- Returns the since version string, or nil.
---@return string Since version when present.
function LDocEntry:getSince() end

--- Returns true when the entry has a non-empty description.
---@return boolean True when the entry has a description.
function LDocEntry:hasDescription() end

--- Returns true when the entry has an example snippet.
---@return boolean True when the entry has an example.
function LDocEntry:hasExample() end

--- Returns true when the entry has at least one parameter.
---@return boolean True when the entry has parameters.
function LDocEntry:hasParameters() end

--- Returns true when the entry declares at least one return type.
---@return boolean True when the entry declares return values.
function LDocEntry:hasReturnType() end

--- Returns the type name of this object.
---@return string Type name.
function LDocEntry:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True when the type matches.
function LDocEntry:typeOf(name) end

--- Wraps documentation quality metrics for Lua access.
---@class LQualityReport
LQualityReport = {}

--- Returns up to count entries with the highest quality scores.
---@param count? integer Maximum number of entries to return.
---@return table Array of highest-scoring entries.
function LQualityReport:getBest(count) end

--- Returns entries whose grade exactly matches the given letter grade.
---@param grade string Letter grade to match.
---@return table Array of matching entries.
function LQualityReport:getByGrade(grade) end

--- Returns the letter grade for the overall score.
---@return string Letter grade.
function LQualityReport:getGrade() end

--- Returns a table mapping module name to its average quality score.
---@return table Table mapping module names to scores.
function LQualityReport:getModuleScores() end

--- Returns the overall quality score in [0,1].
---@return number Overall quality score.
function LQualityReport:getOverallScore() end

--- Returns a multi-line human-readable summary of quality by module.
---@return string Multi-line summary.
function LQualityReport:getSummary() end

--- Returns up to count entries with the lowest quality scores.
---@param count? integer Maximum number of entries to return.
---@return table Array of lowest-scoring entries.
function LQualityReport:getWorst(count) end

--- Serialises the quality report to a pretty-printed JSON string.
---@return string Pretty-printed JSON representation.
function LQualityReport:toJSON() end

--- Converts the quality report to a plain Lua table.
---@return table Plain Lua table representation.
function LQualityReport:toTable() end

--- Returns the type name of this object.
---@return string Type name.
function LQualityReport:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True when the type matches.
function LQualityReport:typeOf(name) end

--- Lua wrapper for a runtime data-validation schema.
---@class LSchema
LSchema = {}

--- Validates data and throws a Lua error on failure with all error messages joined.
---@param data table Table to validate.
---@return nil No value is returned.
function LSchema:assert(data) end

--- Returns true when the data passes all schema rules.
---@param data table Table to validate.
---@return boolean True when the table passes validation.
function LSchema:check(data) end

--- Returns a table of declared field names.
---@return table Array of declared field names.
function LSchema:getFields() end

--- Returns the name identifier of this API schema group.
---@return string Schema group name.
function LSchema:getName() end

--- Returns the type name of this object.
---@return string Type name.
function LSchema:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True when the type matches.
function LSchema:typeOf(name) end

--- Validates a Lua table against the schema.
---@param data table Table to validate.
---@return boolean True when the table satisfies the schema.
---@return table Array of validation error records.
function LSchema:validate(data) end

--- Wraps a validation report for Lua access.
---@class LValidationReport
LValidationReport = {}

--- Returns the list of qualified names whose catalog entry is incomplete.
---@return table Array of incomplete qualified names.
function LValidationReport:getIncomplete() end

--- Returns the list of qualified names present in the live API but missing from the catalog.
---@return table Array of missing qualified names.
function LValidationReport:getMissing() end

--- Returns the list of qualified names in the catalog that are not present in the live API.
---@return table Array of phantom qualified names.
function LValidationReport:getPhantom() end

--- Returns a single-line summary of the validation results.
---@return string Summary string.
function LValidationReport:getSummary() end

--- Returns the count of incomplete entries.
---@return integer Number of incomplete entries.
function LValidationReport:incompleteCount() end

--- Returns true when the report has no missing entries.
---@return boolean True when no entries are missing.
function LValidationReport:isValid() end

--- Returns the count of missing entries.
---@return integer Number of missing entries.
function LValidationReport:missingCount() end

--- Returns the count of phantom entries.
---@return integer Number of phantom entries.
function LValidationReport:phantomCount() end

--- Serialises the report to a pretty-printed JSON string.
---@return string Pretty-printed JSON representation.
function LValidationReport:toJSON() end

--- Converts the report to a plain Lua table.
---@return table Plain Lua table representation.
function LValidationReport:toTable() end

--- Returns the type name of this object.
---@return string Type name.
function LValidationReport:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True when the type matches.
function LValidationReport:typeOf(name) end

--- Compare catalog entries against source files in a directory for staleness.
---@param catalog_ud LApiCatalog Catalog to compare.
---@param source_dir string Source directory to inspect.
---@return table Table containing stale, current, and missing lists.
lurek.docs.checkStaleness = function(catalog_ud, source_dir) end

--- Return (documented_count, total_live_count) coverage tuple.
---@param catalog_ud? LApiCatalog Optional catalog to inspect.
---@return integer Number of documented entries.
---@return integer Number of live entries discovered in the runtime.
lurek.docs.coverage = function(catalog_ud) end

--- Return (documented_count, total_live_count) for a single module.
---@param module_name string Module name to inspect.
---@param catalog_ud? LApiCatalog Optional catalog to inspect.
---@return integer Number of documented entries for the module.
---@return integer Number of live entries discovered for the module.
lurek.docs.coverageModule = function(module_name, catalog_ud) end

--- Inject or update a description for a named API entry.
---@param qualified_name string Qualified entry name.
---@param description string Description text to store.
---@return nil No value is returned.
lurek.docs.describe = function(qualified_name, description) end

--- Export completions.json, hover.json, and signatures.json to a directory.
---@param catalog_ud LApiCatalog Catalog to export.
---@param output_dir string Output directory path.
---@return nil No value is returned.
lurek.docs.exportAll = function(catalog_ud, output_dir) end

--- Export a one-line-per-function plain-text cheatsheet.
---@param catalog_ud LApiCatalog Catalog to export.
---@param path string Output file path.
---@return nil No value is returned.
lurek.docs.exportCheatsheet = function(catalog_ud, path) end

--- Export VS Code IntelliSense completions JSON to a file.
---@param catalog_ud LApiCatalog Catalog to export.
---@param path string Output file path.
---@return nil No value is returned.
lurek.docs.exportCompletions = function(catalog_ud, path) end

--- Export VS Code hover JSON to a file.
---@param catalog_ud LApiCatalog Catalog to export.
---@param path string Output file path.
---@return nil No value is returned.
lurek.docs.exportHover = function(catalog_ud, path) end

--- Export a Markdown API reference file.
---@param catalog_ud LApiCatalog Catalog to export.
---@param path string Output file path.
---@return nil No value is returned.
lurek.docs.exportMarkdown = function(catalog_ud, path) end

--- Export VS Code signature-help JSON to a file.
---@param catalog_ud LApiCatalog Catalog to export.
---@param path string Output file path.
---@return nil No value is returned.
lurek.docs.exportSignatures = function(catalog_ud, path) end

--- Return the current internal catalog as an ApiCatalog userdata.
---@return LApiCatalog Current internal catalog.
lurek.docs.getCatalog = function() end

--- Load all .toml files in a directory and merge into a single ApiCatalog.
---@param directory string Directory containing TOML files.
---@return LApiCatalog Merged catalog from all TOML files.
lurek.docs.loadAll = function(directory) end

--- Load a TOML doc file into an ApiCatalog.
---@param path string Path to the TOML file.
---@return LApiCatalog Catalog loaded from the file.
lurek.docs.loadToml = function(path) end

--- Calculate quality metrics for a catalog or the internal catalog.
---@param catalog_ud? LApiCatalog Optional catalog to inspect.
---@return LQualityReport Quality report.
lurek.docs.quality = function(catalog_ud) end

--- Calculate quality metrics for a single module.
---@param module_name string Module name to inspect.
---@param catalog_ud? LApiCatalog Optional catalog to inspect.
---@return LQualityReport Quality report for the module.
lurek.docs.qualityModule = function(module_name, catalog_ud) end

--- Walks the live lurek.* Lua table and returns a structured reflection table.
---@param ns? string Optional namespace to reflect.
---@return table Reflection table keyed by namespace.
lurek.docs.reflectLive = function(ns) end

--- Reflects any Lua table and returns a structure describing its keys and value types.
---@param tbl table Table to reflect.
---@param name? string Optional prefix for qualified names.
---@return table Reflection array for the table.
lurek.docs.reflectTable = function(tbl, name) end

--- Clear all entries from the internal catalog.
---@return nil No value is returned.
lurek.docs.resetCatalog = function() end

--- Scan the lurek.* namespace to build an API catalog from live bindings.
---@param opts? table Optional scan options table.
---@return LApiCatalog Catalog built from live bindings.
lurek.docs.scan = function(opts) end

--- Scan a single module's bindings.
---@param module_name string Module name to scan.
---@return LApiCatalog Catalog built from the selected module.
lurek.docs.scanModule = function(module_name) end

--- Creates a schema validator from a rules table.
---@param rules table Rules table describing fields and constraints.
---@param name? string Optional schema name.
---@return LSchema Schema validator userdata.
lurek.docs.schema = function(rules, name) end

--- Set the parameter metadata for a catalog entry.
---@param qualified_name string Qualified entry name.
---@param params table Array of parameter metadata records.
---@return nil No value is returned.
lurek.docs.setParamInfo = function(qualified_name, params) end

--- Set the return type metadata for a catalog entry.
---@param qualified_name string Qualified entry name.
---@param returns table Array of return metadata records.
---@return nil No value is returned.
lurek.docs.setReturnInfo = function(qualified_name, returns) end

--- Validate catalog completeness against the live lurek.* bindings.
---@param catalog_ud? LApiCatalog Optional catalog to validate.
---@return LValidationReport Validation report.
lurek.docs.validate = function(catalog_ud) end

--- Validate a single module against the live lurek.<module>.* bindings.
---@param module_name string Module name to validate.
---@param catalog_ud? LApiCatalog Optional catalog to validate.
---@return LValidationReport Validation report.
lurek.docs.validateModule = function(module_name, catalog_ud) end

---@class lurek.ecs
lurek.ecs = {}

--- Lua-side wrapper around a [`Universe`] ECS world.
---@class LUniverse
LUniverse = {}

--- Adds a directed named relationship from entity `from` to entity `to`, ignoring duplicates.
---@param from integer Source entity ID.
---@param name string Relationship name.
---@param to integer Target entity ID.
---@return nil No value is returned.
function LUniverse:addRelation(from, name, to) end

--- Adds a system table to the universe with an optional priority (lower = earlier).
---@param system table System table to register.
---@param opts? table Optional table with a `priority` integer field.
---@return nil No value is returned.
function LUniverse:addSystem(system, opts) end

--- Attaches a string tag to an entity.
---@param id integer Entity ID to tag.
---@param tag string Tag name to attach.
---@return nil No value is returned.
function LUniverse:addTag(id, tag) end

--- Adds a bitmap tag to an entity.
---@param id integer Entity ID to update.
---@param name string Bitmap tag name to add.
---@return nil No value is returned.
function LUniverse:bitmapTag(id, name) end

--- Removes a bitmap tag from an entity.
---@param id integer Entity ID to update.
---@param name string Bitmap tag name to remove.
---@return nil No value is returned.
function LUniverse:bitmapUntag(id, name) end

--- Removes all entities, components, tags, layers, and systems. Blueprints are preserved.
---@return nil No value is returned.
function LUniverse:clear() end

--- Removes all directed named relationships of type `name` from entity `from`.
---@param from integer Source entity ID.
---@param name string Relationship name.
---@return nil No value is returned.
function LUniverse:clearRelations(from, name) end

--- Defines a blueprint from a component table.
---@param name string Blueprint name.
---@param components table Component table for the blueprint.
---@return nil No value is returned.
function LUniverse:defineBlueprint(name, components) end

--- Defines a bitmap tag name, returning its bit index.
---@param name string Bitmap tag name to define.
---@return integer Assigned bit index.
function LUniverse:defineTag(name) end

--- Restores entity state from a snapshot produced by serialize() while preserving blueprints and systems.
---@param snapshot table Snapshot table to load.
---@return nil No value is returned.
function LUniverse:deserialize(snapshot) end

--- Calls callback(id, value) for every entity with the named component.
---@param name string Component name to iterate.
---@param callback function Callback called with each entity ID and value.
---@return nil No value is returned.
function LUniverse:each(name, callback) end

--- Emits a named event to all systems that implement the handler, in priority order.
---@param ... string
---@return nil No value is returned.
function LUniverse:emit(...) end

--- Defines a blueprint by extending a parent with overrides.
---@param name string Blueprint name to create.
---@param parent string Parent blueprint name.
---@param overrides table Component overrides to apply.
---@return nil No value is returned.
function LUniverse:extendBlueprint(name, parent, overrides) end

--- Dispatches all pending component-add and component-remove events to registered callbacks.
---@return nil No value is returned.
function LUniverse:flushObservers() end

--- Returns the component value for an entity, or nil if missing.
---@param id integer Entity ID to read.
---@param name string Component name.
---@return table Component value when present.
function LUniverse:get(id, name) end

--- Returns the bit index for a bitmap tag name, or nil if undefined.
---@param name string Bitmap tag name to look up.
---@return integer Bit index for the tag when it is defined.
function LUniverse:getBitmapTagBit(name) end

--- Returns a deep copy of a blueprint's component table, or nil.
---@param name string Blueprint name to read.
---@return table Component table for the blueprint.
function LUniverse:getBlueprintComponents(name) end

--- Returns all direct child entity IDs.
---@param parent_id integer Parent entity ID.
---@return table Array of child entity IDs.
function LUniverse:getChildren(parent_id) end

--- Returns all component names for an entity.
---@param id integer Entity ID to inspect.
---@return table Array of component names.
function LUniverse:getComponents(id) end

--- Returns all alive entity IDs.
---@return table Array of alive entity IDs.
function LUniverse:getEntities() end

--- Returns all alive entities on a specific layer.
---@param layer integer Layer index to query.
---@return table Array of matching entity IDs.
function LUniverse:getEntitiesByLayer(layer) end

--- Returns all alive entities with the given string tag.
---@param tag string Tag name to query.
---@return table Array of matching entity IDs.
function LUniverse:getEntitiesByTag(tag) end

--- Returns all alive entities sorted by layer then ID.
---@return table Array of entity IDs sorted by layer then ID.
function LUniverse:getEntitiesSorted() end

--- Returns the number of alive entities.
---@return integer Number of alive entities.
function LUniverse:getEntityCount() end

--- Returns the layer for an entity, defaulting to zero.
---@param id integer Entity ID to inspect.
---@return integer Assigned layer index.
function LUniverse:getLayer(id) end

--- Returns the parent entity ID, or nil if unparented.
---@param child_id integer Child entity ID.
---@return integer Parent entity ID when one is set.
function LUniverse:getParent(child_id) end

--- Returns all entity IDs reachable from `from` via the named relationship.
---@param from integer Source entity ID.
---@param name string Relationship name.
---@return table Array of related entity IDs.
function LUniverse:getRelated(from, name) end

--- Returns the number of registered systems.
---@return integer Number of registered systems.
function LUniverse:getSystemCount() end

--- Returns all string tags for an entity.
---@param id integer Entity ID to inspect.
---@return table Array of tag names.
function LUniverse:getTags(id) end

--- Returns true if the entity has the named component.
---@param id integer Entity ID to inspect.
---@param name string Component name.
---@return boolean True when the component exists.
function LUniverse:has(id, name) end

--- Returns true if the entity has the given bitmap tag.
---@param id integer Entity ID to inspect.
---@param name string Bitmap tag name to check.
---@return boolean True when the bitmap tag is present.
function LUniverse:hasBitmapTag(id, name) end

--- Returns true if a blueprint with the given name exists.
---@param name string Blueprint name to check.
---@return boolean True when the blueprint exists.
function LUniverse:hasBlueprint(name) end

--- Returns true if a directed named relationship from `from` to `to` exists.
---@param from integer Source entity ID.
---@param name string Relationship name.
---@param to integer Target entity ID.
---@return boolean True when the relationship exists.
function LUniverse:hasRelation(from, name, to) end

--- Returns true if the entity carries the given tag.
---@param id integer Entity ID to inspect.
---@param tag string Tag name to check.
---@return boolean True when the entity has the tag.
function LUniverse:hasTag(id, tag) end

--- Returns true if the entity ID is currently alive.
---@param id integer Entity ID to check.
---@return boolean True when the entity is alive.
function LUniverse:isAlive(id) end

--- Destroys the entity with the given ID, freeing its slot for reuse.
---@param id integer Entity ID to destroy.
---@return nil No value is returned.
function LUniverse:kill(id) end

--- Kills an entity and all its descendants recursively.
---@param id integer Root entity ID to destroy.
---@return nil No value is returned.
function LUniverse:killRecursive(id) end

--- Returns all defined blueprint names.
---@return table Array of blueprint names.
function LUniverse:listBlueprints() end

--- Registers a callback for component-added events that is dispatched by flushObservers().
---@param name string Component name to observe.
---@param callback function Callback receiving entity_id and component_name.
---@return nil No value is returned.
function LUniverse:onComponentAdded(name, callback) end

--- Registers a callback for component-removed events that is dispatched by flushObservers().
---@param name string Component name to observe.
---@param callback function Callback receiving entity_id and component_name.
---@return nil No value is returned.
function LUniverse:onComponentRemoved(name, callback) end

--- Returns entity IDs that have all listed component names.
---@param ... string Component names that must all exist.
---@return table Array of matching entity IDs.
function LUniverse:query(...) end

--- Returns all alive entities with all of the listed bitmap tags.
---@param names table Array of bitmap tag names.
---@return table Array of matching entity IDs.
function LUniverse:queryBitmapAll(names) end

--- Returns all alive entities with any of the listed bitmap tags.
---@param names table Array of bitmap tag names.
---@return table Array of matching entity IDs.
function LUniverse:queryBitmapAny(names) end

--- Returns all alive entities with the given bitmap tag.
---@param name string Bitmap tag name to query.
---@return table Array of matching entity IDs.
function LUniverse:queryBitmapTag(name) end

--- Returns entity IDs that have all `with` components and none of the `without` components.
---@param with_table table Component names that must exist.
---@param without_table table Component names that must not exist.
---@return table Array of matching entity IDs.
function LUniverse:queryNot(with_table, without_table) end

--- Releases all universe state, equivalent to clear.
---@return nil No value is returned.
function LUniverse:release() end

--- Removes a component from an entity.
---@param id integer Entity ID to modify.
---@param name string Component name.
---@return nil No value is returned.
function LUniverse:remove(id, name) end

--- Removes a blueprint definition.
---@param name string Blueprint name to remove.
---@return nil No value is returned.
function LUniverse:removeBlueprint(name) end

--- Removes the directed named relationship from entity `from` to entity `to`.
---@param from integer Source entity ID.
---@param name string Relationship name.
---@param to integer Target entity ID.
---@return nil No value is returned.
function LUniverse:removeRelation(from, name, to) end

--- Removes a system table from the universe.
---@param system table System table to remove.
---@return nil No value is returned.
function LUniverse:removeSystem(system) end

--- Removes a string tag from an entity.
---@param id integer Entity ID to update.
---@param tag string Tag name to remove.
---@return nil No value is returned.
function LUniverse:removeTag(id, tag) end

--- Calls render(system, world) on each system in priority order and falls back to draw(system, world).
---@return nil No value is returned.
function LUniverse:render() end

--- Serializes all alive entities to a Lua table snapshot.
---@return table Snapshot table of all alive entities.
function LUniverse:serialize() end

--- Sets a component value on an entity.
---@param id integer Entity ID to modify.
---@param name string Component name.
---@param value LuaValue Component value to store.
---@return nil No value is returned.
function LUniverse:set(id, name, value) end

--- Sets the layer for an entity.
---@param id integer Entity ID to update.
---@param layer integer Layer index to assign.
---@return nil No value is returned.
function LUniverse:setLayer(id, layer) end

--- Sets or clears the parent of an entity.
---@param child_id integer Child entity ID.
---@param parent_id? integer Parent entity ID, or nil to clear it.
---@return nil No value is returned.
function LUniverse:setParent(child_id, parent_id) end

--- Creates a new entity and returns its packed ID.
---@return integer Packed entity ID.
function LUniverse:spawn() end

--- Spawns an entity from a blueprint with optional overrides.
---@param name string Blueprint name to spawn.
---@param overrides? table Optional component overrides.
---@return integer Spawned entity ID.
function LUniverse:spawnBlueprint(name, overrides) end

--- Spawns `count` entities from a blueprint, returns an array of entity IDs.
---@param name string Blueprint name to spawn.
---@param count integer Number of entities to create.
---@param overrides? table Optional component overrides.
---@return table Array of spawned entity IDs.
function LUniverse:spawnBulk(name, count, overrides) end

--- Returns the type name of this object.
---@return string Type name.
function LUniverse:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True when the type matches.
function LUniverse:typeOf(name) end

--- Calls update(system, world, dt) on each registered system in priority order.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LUniverse:update(dt) end

--- Creates a new empty ECS universe.
---@return LUniverse New ECS universe wrapper.
lurek.ecs.newUniverse = function() end

---@class lurek.effect
lurek.effect = {}

--- Lua-side wrapper around [`ImageEffect`].
---@class LImageEffect
LImageEffect = {}

--- Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
---@param name string Built-in effect type name.
---@return LPostFxEffect Shared effect userdata that was appended.
function LImageEffect:addEffect(name) end

--- Removes all effects from the chain (alias for clearEffects).
---@return nil No return value.
function LImageEffect:clear() end

--- Removes all effects from the chain.
---@return nil No return value.
function LImageEffect:clearEffects() end

--- Returns a deep copy of this ImageEffect chain.
---@return LImageEffect Deep copy of this image-effect chain.
function LImageEffect:clone() end

--- Returns the number of effects in the chain.
---@return integer Number of effects in the chain.
function LImageEffect:effectCount() end

--- Returns the effect at the given 1-based index or with the given type name.
---@param key LuaValue 1-based index or effect type name.
---@return LPostFxEffect Effect userdata matching the key.
function LImageEffect:getEffect(key) end

--- Returns the number of effects in the chain (alias for effectCount).
---@return integer Number of effects in the chain.
function LImageEffect:getEffectCount() end

--- Removes the effect at the given 0-based index from the chain.
---@param idx integer 0-based effect index.
---@return boolean True when an effect was removed.
function LImageEffect:removeByIndex(idx) end

--- Removes the first effect matching the given type name.
---@param name string Effect type name.
---@return boolean True when an effect was removed.
function LImageEffect:removeByName(name) end

--- Removes the effect at the given 1-based index or with the given type name.
---@param key LuaValue 1-based index or effect type name.
---@return boolean True when an effect was removed.
function LImageEffect:removeEffect(key) end

--- Stub: no-op serialisation placeholder.
---@return boolean Always returns true.
function LImageEffect:save() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LImageEffect:type() end

--- Returns true when the given name matches this object or a parent type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LImageEffect:typeOf(name) end

--- Lua-side wrapper around [`Overlay`].
---@class LOverlay
LOverlay = {}

--- Resets all effect subsystems to their default inactive state.
---@return nil No return value.
function LOverlay:clear() end

--- Renders the effect state (flash, fade, effects) to a CPU ImageData.
---@param width integer Target image width in pixels.
---@param height integer Target image height in pixels.
---@return LImageData Rendered image userdata.
function LOverlay:drawToImage(width, height) end

--- Animates a full-screen colour fade; alpha defaults to 1.0, duration to 1.0 s.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param alpha? number Optional target alpha.
---@param duration? number Optional fade duration in seconds.
---@return nil No return value.
function LOverlay:fade(r, g, b, alpha, duration) end

--- Triggers a full-screen colour flash; alpha defaults to 1.0, duration to 0.2 s.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a? number Optional alpha channel.
---@param duration? number Optional flash duration in seconds.
---@return nil No return value.
function LOverlay:flash(r, g, b, a, duration) end

--- Returns the current ambient tint as r, g, b, a components.
---@return number Ambient tint red component.
---@return number Ambient tint green component.
---@return number Ambient tint blue component.
---@return number Ambient tint alpha component.
function LOverlay:getAmbientColor() end

--- Returns the current cloud shadow instance count.
---@return integer Number of cloud shadow instances.
function LOverlay:getCloudCount() end

--- Returns the current cloud shadow opacity.
---@return number Cloud shadow opacity.
function LOverlay:getCloudOpacity() end

--- Returns the current cloud shadow scale.
---@return number Cloud shadow scale multiplier.
function LOverlay:getCloudScale() end

--- Returns the current cloud shadow scroll speed.
---@return number Cloud shadow scroll speed.
function LOverlay:getCloudSpeed() end

--- Returns the effect width and height.
---@return integer Effect width in pixels.
---@return integer Effect height in pixels.
function LOverlay:getDimensions() end

--- Returns the current film-grain intensity.
---@return number Film-grain intensity.
function LOverlay:getFilmGrainIntensity() end

--- Returns the current flash overlay alpha value.
---@return number Current flash alpha.
function LOverlay:getFlashAlpha() end

--- Returns the current fog tint as r, g, b, a components.
---@return number Fog tint red component.
---@return number Fog tint green component.
---@return number Fog tint blue component.
---@return number Fog tint alpha component.
function LOverlay:getFogColor() end

--- Returns the current fog density.
---@return number Fog density.
function LOverlay:getFogDensity() end

--- Returns the current heat-haze distortion intensity.
---@return number Heat-haze intensity.
function LOverlay:getHeatHazeIntensity() end

--- Returns the effect height.
---@return integer Effect height in pixels.
function LOverlay:getHeight() end

--- Returns the current lightning overlay alpha value.
---@return number Current lightning alpha.
function LOverlay:getLightningAlpha() end

--- Returns the lightning flash tint as r, g, b, a components.
---@return number Lightning tint red component.
---@return number Lightning tint green component.
---@return number Lightning tint blue component.
---@return number Lightning tint alpha component.
function LOverlay:getLightningColor() end

--- Returns the current shake displacement as x, y.
---@return number Shake offset X value.
---@return number Shake offset Y value.
function LOverlay:getShakeOffset() end

--- Returns the current simulated time-of-day (0-24).
---@return number Simulated hour of day.
function LOverlay:getTimeOfDay() end

--- Returns the current vignette strength.
---@return number Vignette strength.
function LOverlay:getVignetteStrength() end

--- Returns a table describing the current water overlay state.
---@return table Water state fields including enablement, wave settings, tint, depth tint, and time.
function LOverlay:getWater() end

--- Returns the name of the current weather type.
---@return string Current weather type name.
function LOverlay:getWeather() end

--- Returns the current weather intensity.
---@return number Weather intensity multiplier.
function LOverlay:getWeatherIntensity() end

--- Returns the effect width.
---@return integer Effect width in pixels.
function LOverlay:getWidth() end

--- Returns the current wind direction in radians.
---@return number Wind direction in radians.
function LOverlay:getWindDirection() end

--- Returns the current wind speed.
---@return number Wind speed.
function LOverlay:getWindSpeed() end

--- Returns true if any effect subsystem is currently active.
---@return boolean True when any overlay effect is active.
function LOverlay:isActive() end

--- Returns whether the ambient light layer is active.
---@return boolean True when the ambient light layer is active.
function LOverlay:isAmbientEnabled() end

--- Returns whether cloud shadows are active.
---@return boolean True when cloud shadows are active.
function LOverlay:isCloudShadowsEnabled() end

--- Returns true while a fade effect is in progress.
---@return boolean True when a fade effect is active.
function LOverlay:isFading() end

--- Returns whether the film-grain layer is active.
---@return boolean True when film grain is active.
function LOverlay:isFilmGrainEnabled() end

--- Returns true while a flash effect is in progress.
---@return boolean True when a flash effect is active.
function LOverlay:isFlashing() end

--- Returns whether the fog layer is active.
---@return boolean True when fog is active.
function LOverlay:isFogEnabled() end

--- Returns whether the heat-haze layer is active.
---@return boolean True when heat haze is active.
function LOverlay:isHeatHazeEnabled() end

--- Returns true while a shake effect is in progress.
---@return boolean True when a shake effect is active.
function LOverlay:isShaking() end

--- Returns whether the vignette layer is active.
---@return boolean True when vignette is active.
function LOverlay:isVignetteEnabled() end

--- Returns whether the weather particle system is active.
---@return boolean True when weather is active.
function LOverlay:isWeatherEnabled() end

--- Emits GPU render commands for all active overlay effects.
---@return nil No return value.
function LOverlay:render() end

--- Resizes the effect to match new window dimensions.
---@param width integer New effect width in pixels.
---@param height integer New effect height in pixels.
---@return nil No return value.
function LOverlay:resize(width, height) end

--- Sets the ambient light tint colour; alpha defaults to 1.0.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a? number Optional alpha channel.
---@return nil No return value.
function LOverlay:setAmbientColor(r, g, b, a) end

--- Enables or disables the ambient light layer.
---@param enabled boolean Whether ambient light should be enabled.
---@return nil No return value.
function LOverlay:setAmbientEnabled(enabled) end

--- Sets the number of cloud shadow instances to render.
---@param count integer Number of cloud shadow instances.
---@return nil No return value.
function LOverlay:setCloudCount(count) end

--- Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
---@param opacity number Cloud shadow opacity.
---@return nil No return value.
function LOverlay:setCloudOpacity(opacity) end

--- Sets the scale multiplier applied to each cloud shadow.
---@param scale number Cloud shadow scale multiplier.
---@return nil No return value.
function LOverlay:setCloudScale(scale) end

--- Enables or disables scrolling cloud-shadow projection.
---@param enabled boolean Whether cloud shadows should be enabled.
---@return nil No return value.
function LOverlay:setCloudShadows(enabled) end

--- Sets the horizontal scroll speed of cloud shadows in pixels per second.
---@param speed number Cloud shadow scroll speed.
---@return nil No return value.
function LOverlay:setCloudSpeed(speed) end

--- Assigns a custom shader name to the effect.
---@param name? string Shader name to assign, or nil to clear it.
---@return nil No return value.
function LOverlay:setCustomShader(name) end

--- Enables or disables the film-grain noise layer.
---@param enabled boolean Whether film grain should be enabled.
---@return nil No return value.
function LOverlay:setFilmGrainEnabled(enabled) end

--- Sets the film-grain noise intensity (0.0-1.0).
---@param intensity number Film-grain intensity.
---@return nil No return value.
function LOverlay:setFilmGrainIntensity(intensity) end

--- Sets the fog tint colour; alpha defaults to 1.0.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a? number Optional alpha channel.
---@return nil No return value.
function LOverlay:setFogColor(r, g, b, a) end

--- Sets the fog density (0.0 = clear, 1.0 = fully opaque).
---@param density number Fog density.
---@return nil No return value.
function LOverlay:setFogDensity(density) end

--- Enables or disables the fog layer.
---@param enabled boolean Whether fog should be enabled.
---@return nil No return value.
function LOverlay:setFogEnabled(enabled) end

--- Enables or disables the heat-haze distortion layer.
---@param enabled boolean Whether heat haze should be enabled.
---@return nil No return value.
function LOverlay:setHeatHazeEnabled(enabled) end

--- Sets the heat-haze distortion intensity (0.0-1.0).
---@param intensity number Heat-haze intensity.
---@return nil No return value.
function LOverlay:setHeatHazeIntensity(intensity) end

--- Sets the lightning flash tint colour; alpha defaults to 1.0.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a? number Optional alpha channel.
---@return nil No return value.
function LOverlay:setLightningColor(r, g, b, a) end

--- Sets the simulated time-of-day (0-24) which drives ambient colour.
---@param hour number Simulated hour of day.
---@return nil No return value.
function LOverlay:setTimeOfDay(hour) end

--- Enables or disables the screen-edge vignette layer.
---@param enabled boolean Whether vignette should be enabled.
---@return nil No return value.
function LOverlay:setVignetteEnabled(enabled) end

--- Sets the vignette darkening strength (0.0-1.0).
---@param strength number Vignette strength.
---@return nil No return value.
function LOverlay:setVignetteStrength(strength) end

--- Enables the water overlay and sets its wave parameters.
---@param amplitude number Wave displacement intensity.
---@param frequency number Wave spatial frequency.
---@param speed number Wave animation speed.
---@return nil No return value.
function LOverlay:setWater(amplitude, frequency, speed) end

--- Sets the water tint colour and blend strength.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param strength number Tint blend factor.
---@return nil No return value.
function LOverlay:setWaterTint(r, g, b, strength) end

--- Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
---@param name string Weather type name.
---@return nil No return value.
function LOverlay:setWeather(name) end

--- Enables or disables the weather particle system.
---@param enabled boolean Whether weather should be enabled.
---@return nil No return value.
function LOverlay:setWeatherEnabled(enabled) end

--- Sets the particle spawn rate multiplier (0.0-1.0).
---@param intensity number Weather intensity multiplier.
---@return nil No return value.
function LOverlay:setWeatherIntensity(intensity) end

--- Sets the wind direction in radians (0 = right, Ď€/2 = down).
---@param radians number Wind direction in radians.
---@return nil No return value.
function LOverlay:setWindDirection(radians) end

--- Sets the wind speed applied to weather particles in units per second.
---@param speed number Wind speed.
---@return nil No return value.
function LOverlay:setWindSpeed(speed) end

--- Triggers a camera shake; duration defaults to 0.5 s.
---@param intensity number Shake intensity.
---@param duration? number Optional shake duration in seconds.
---@return nil No return value.
function LOverlay:shake(intensity, duration) end

--- Triggers a screen fade effect to the given colour and alpha.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param target_alpha number Target alpha value.
---@param duration number Fade duration in seconds.
---@return nil No return value.
function LOverlay:triggerFade(r, g, b, target_alpha, duration) end

--- Triggers a screen-wide colour flash effect.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a number Alpha channel.
---@param duration number Flash duration in seconds.
---@return nil No return value.
function LOverlay:triggerFlash(r, g, b, a, duration) end

--- Triggers a lightning flash effect.
---@return nil No return value.
function LOverlay:triggerLightning() end

--- Triggers a screen shake effect with the given intensity and duration.
---@param intensity number Shake intensity.
---@param duration number Shake duration in seconds.
---@return nil No return value.
function LOverlay:triggerShake(intensity, duration) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LOverlay:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LOverlay:typeOf(name) end

--- Advances all effect subsystems by the given delta time.
---@param dt number Delta time in seconds.
---@return nil No return value.
function LOverlay:update(dt) end

--- Lua-side wrapper around [`PostFxEffect`].
---@class LPostFxEffect
LPostFxEffect = {}

--- Disables auto-injection of common uniforms into shader slot p[3].
---@return nil No return value.
function LPostFxEffect:disableAutoUniforms() end

--- Enables auto-injection of common uniforms into shader slot p[3] each frame.
---@return nil No return value.
function LPostFxEffect:enableAutoUniforms() end

--- Returns the type name of this effect (alias for getTypeName).
---@return string Display name of the effect type.
function LPostFxEffect:getEffectType() end

--- Returns a named parameter value, or the default if not set.
---@param name string Parameter name.
---@param default? number Fallback value when the parameter is missing.
---@return number Parameter value.
function LPostFxEffect:getParameter(name, default) end

--- Returns a list of all parameter names on this effect.
---@return table Parameter names in effect order.
function LPostFxEffect:getParameterNames() end

--- Returns the type name of this effect (alias for getTypeName).
---@return string Display name of the effect type.
function LPostFxEffect:getType() end

--- Returns the display name of this effect type.
---@return string Display name of the effect type.
function LPostFxEffect:getTypeName() end

--- Returns true if the named parameter exists on this effect.
---@param name string Parameter name.
---@return boolean True when the parameter exists.
function LPostFxEffect:hasParameter(name) end

--- Returns whether auto-uniform injection is enabled for this effect.
---@return boolean True when auto-uniform injection is enabled.
function LPostFxEffect:isAutoUniforms() end

--- Returns true if this is a built-in effect, false if custom.
---@return boolean True when the effect is built in.
function LPostFxEffect:isBuiltIn() end

--- Returns whether this effect is currently active.
---@return boolean True when the effect is enabled.
function LPostFxEffect:isEnabled() end

--- Sets the brightness parameter of this effect.
---@param value number Brightness parameter value.
---@return nil No return value.
function LPostFxEffect:setBrightness(value) end

--- Sets the contrast parameter of this effect.
---@param value number Contrast parameter value.
---@return nil No return value.
function LPostFxEffect:setContrast(value) end

--- Enables or disables this effect.
---@param enabled boolean Whether the effect should be enabled.
---@return nil No return value.
function LPostFxEffect:setEnabled(enabled) end

--- Sets the intensity parameter of this effect.
---@param value number Intensity parameter value.
---@return nil No return value.
function LPostFxEffect:setIntensity(value) end

--- Sets the offset parameter of this effect.
---@param value number Offset parameter value.
---@return nil No return value.
function LPostFxEffect:setOffset(value) end

--- Sets a named float parameter on this effect.
---@param name string Parameter name.
---@param value number Parameter value.
---@return nil No return value.
function LPostFxEffect:setParameter(name, value) end

--- Sets the radius parameter of this effect.
---@param value number Radius parameter value.
---@return nil No return value.
function LPostFxEffect:setRadius(value) end

--- Sets the saturation parameter of this effect.
---@param value number Saturation parameter value.
---@return nil No return value.
function LPostFxEffect:setSaturation(value) end

--- Sets the scanline strength parameter of this effect.
---@param value number Scanline strength parameter value.
---@return nil No return value.
function LPostFxEffect:setScanlineStrength(value) end

--- Sets the strength parameter of this effect.
---@param value number Strength parameter value.
---@return nil No return value.
function LPostFxEffect:setStrength(value) end

--- Sets the threshold parameter of this effect.
---@param value number Threshold parameter value.
---@return nil No return value.
function LPostFxEffect:setThreshold(value) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LPostFxEffect:type() end

--- Returns true when the given name matches this object or a parent type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LPostFxEffect:typeOf(name) end

--- Lua-side wrapper around [`PostFxStack`].
---@class LPostFxStack
LPostFxStack = {}

--- Appends a PostFxEffect to the end of the pipeline.
---@param effect LPostFxEffect Effect userdata to append.
---@return nil No return value.
function LPostFxStack:add(effect) end

--- Applies all enabled effects in the stack and composites the result to the screen.
---@return nil No return value.
function LPostFxStack:apply() end

--- Begins capturing the scene for post-processing.
---@return nil No return value.
function LPostFxStack:beginCapture() end

--- Removes all effects from the pipeline.
---@return nil No return value.
function LPostFxStack:clear() end

--- Resets the feedback intensity to `0.0` (disables feedback).
---@return nil No return value.
function LPostFxStack:clearFeedback() end

--- Removes duplicate effects from the pipeline.
---@return integer Number of effect slots removed.
function LPostFxStack:dedup() end

--- Ends scene capture for post-processing.
---@return nil No return value.
function LPostFxStack:endCapture() end

--- Returns width and height of the render target.
---@return integer Render-target width in pixels.
---@return integer Render-target height in pixels.
function LPostFxStack:getDimensions() end

--- Returns the effect at the given 1-based position, or nil.
---@param index integer 1-based effect position.
---@return LPostFxEffect Effect userdata at the given position.
function LPostFxStack:getEffect(index) end

--- Returns the number of effects in the pipeline.
---@return integer Number of effect slots in the pipeline.
function LPostFxStack:getEffectCount() end

--- Returns a list of currently enabled effect objects.
---@return table Enabled `LPostFxEffect` userdata values.
function LPostFxStack:getEnabledEffects() end

--- Returns the current feedback loop intensity `[0.0, 1.0]`.
---@return number Feedback intensity.
function LPostFxStack:getFeedback() end

--- Returns the height of the render target.
---@return integer Render-target height in pixels.
function LPostFxStack:getHeight() end

--- Returns the width of the render target.
---@return integer Render-target width in pixels.
function LPostFxStack:getWidth() end

--- Inserts a PostFxEffect at a specific 1-based position in the pipeline.
---@param position integer 1-based insertion position.
---@param effect LPostFxEffect Effect userdata to insert.
---@return nil No return value.
function LPostFxStack:insert(position, effect) end

--- Returns whether the stack is currently capturing the scene.
---@return boolean True when scene capture is active.
function LPostFxStack:isCapturing() end

--- Returns true if the pipeline has no effect slots.
---@return boolean True when the pipeline is empty.
function LPostFxStack:isEmpty() end

--- Returns whether the effect at the given 1-based position is enabled.
---@param position integer 1-based effect position.
---@return boolean True when the effect is enabled.
function LPostFxStack:isEnabled(position) end

--- Returns the total number of effect slots in the pipeline.
---@return integer Number of effect slots in the pipeline.
function LPostFxStack:len() end

--- Removes the given PostFxEffect from the pipeline.
---@param effect LPostFxEffect Effect userdata to remove.
---@return boolean True when an effect was removed.
function LPostFxStack:remove(effect) end

--- Resizes the render target to the given dimensions.
---@param width integer New render-target width in pixels.
---@param height integer New render-target height in pixels.
---@return nil No return value.
function LPostFxStack:resize(width, height) end

--- Enables or disables the effect at the given 1-based position.
---@param position integer 1-based effect position.
---@param enabled boolean Whether the effect should be enabled.
---@return nil No return value.
function LPostFxStack:setEnabled(position, enabled) end

--- Sets the feedback loop intensity between `0.0` and `1.0`.
---@param factor number Feedback intensity.
---@return nil No return value.
function LPostFxStack:setFeedback(factor) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LPostFxStack:type() end

--- Returns true when the given name matches this object or a parent type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LPostFxStack:typeOf(name) end

--- Lua-side wrapper around a [`crate::effect::ScreenTransition`].
---@class LScreenTransition
LScreenTransition = {}

--- Returns the fill color as four numbers: `r, g, b, a`.
---@return number Fill color red component.
---@return number Fill color green component.
---@return number Fill color blue component.
---@return number Fill color alpha component.
function LScreenTransition:color() end

--- Returns true while the transition is running.
---@return boolean True when the transition is active.
function LScreenTransition:isActive() end

--- Returns true after the transition has completed.
---@return boolean True when the transition is finished.
function LScreenTransition:isDone() end

--- Returns the transition kind name.
---@return string Transition kind name.
function LScreenTransition:kind() end

--- Starts the transition playing forward (scene fades/wipes out).
---@return nil No return value.
function LScreenTransition:play() end

--- Returns the fractional progress of the transition.
---@return number Progress value in the range `[0, 1]`.
function LScreenTransition:progress() end

--- Starts the transition in reverse (scene fades/wipes in).
---@return nil No return value.
function LScreenTransition:reverse() end

--- Updates the fill color from `{r, g, b, a?}`.
---@param color table Color entries as `{r, g, b, a?}`.
---@return nil No return value.
function LScreenTransition:setColor(color) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LScreenTransition:type() end

--- Returns true if this object is of the given type name or a parent type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LScreenTransition:typeOf(name) end

--- Advances the transition by `dt` seconds.
---@param dt number Delta time in seconds.
---@return boolean True while the transition is still running.
function LScreenTransition:update(dt) end

--- Returns the list of all built-in effect type names.
---@return table Built-in effect type names.
lurek.effect.getEffectTypes = function() end

--- Returns whether shader error display is currently enabled.
---@return boolean True when shader error display is enabled.
lurek.effect.getShaderErrorDisplay = function() end

--- Creates a custom shader post-processing effect.
---@param shader_id integer Shader identifier.
---@return LPostFxEffect New custom effect userdata.
lurek.effect.newCustomEffect = function(shader_id) end

--- Creates a new built-in post-processing effect by type name.
---@param type_name string Built-in effect type name.
---@return LPostFxEffect New effect userdata.
lurek.effect.newEffect = function(type_name) end

--- Creates a new per-image effect chain.
---@param ... LuaValue
---@return LImageEffect New image-effect chain userdata.
lurek.effect.newImageEffect = function(...) end

--- Creates a new screen overlay controller for weather, flash, shake, and fade effects.
---@param width? integer Optional overlay width in pixels.
---@param height? integer Optional overlay height in pixels.
---@return LOverlay New overlay userdata.
lurek.effect.newOverlay = function(width, height) end

--- Creates a custom-shader post-processing effect (alias for newCustomEffect).
---@param shader_id integer Shader identifier.
---@return LPostFxEffect New custom effect userdata.
lurek.effect.newPass = function(shader_id) end

--- Creates a pre-configured effect stack from a named preset.
---@param name string Preset stack name.
---@param width? integer Optional stack width in pixels.
---@param height? integer Optional stack height in pixels.
---@return LPostFxStack New preset stack userdata.
lurek.effect.newPresetStack = function(name, width, height) end

--- Creates a new post-processing pipeline stack.
---@param width? integer Optional stack width in pixels.
---@param height? integer Optional stack height in pixels.
---@return LPostFxStack New post-processing stack userdata.
lurek.effect.newStack = function(width, height) end

--- Creates a new screen-transition controller.
---@param kind? string Optional transition kind name.
---@param duration? number Optional transition duration in seconds.
---@param color? table Optional fill color as `{r, g, b, a?}`.
---@return LScreenTransition New screen-transition userdata.
lurek.effect.newTransition = function(kind, duration, color) end

--- Enables or disables on-screen shader error display.
---@param enabled boolean Whether shader error display should be enabled.
---@return nil No return value.
lurek.effect.setShaderErrorDisplay = function(enabled) end

---@class lurek.engine
lurek.engine = {}

--- Returns the current measured frames-per-second.
---@return number Current frames-per-second estimate.
lurek.engine.fps = function() end

--- Returns the total number of frames processed since engine start.
---@return integer Total processed frame count.
lurek.engine.frameCount = function() end

--- Returns the target frame budget in milliseconds (default: 1000 / 60 ~ 16.667 ms).
---@return number Target frame budget in milliseconds.
lurek.engine.getFrameBudget = function() end

--- Returns a table with resident resource memory statistics.
---@return table Table with `texture_bytes`, `budget_bytes`, and `texture_count` fields.
lurek.engine.getResourceStats = function() end

--- Returns the engine version string (from `Cargo.toml`).
---@return string Engine version string.
lurek.engine.getVersion = function() end

--- Returns `true` if the engine was compiled in debug mode.
---@return boolean Whether debug assertions are enabled.
lurek.engine.isDebug = function() end

--- Returns Lua memory usage in bytes and kilobytes.
---@return table Table with `lua_bytes` and `lua_kb` fields.
lurek.engine.memoryUsage = function() end

--- Returns the host operating system name.
---@return string One of `windows`, `linux`, `macos`, or `unknown`.
lurek.engine.platform = function() end

--- Sets the maximum resident texture memory budget in bytes.
---@param budget_bytes integer Maximum texture memory budget in bytes, or 0 for unlimited.
---@return nil No value is returned.
lurek.engine.setResourceBudget = function(budget_bytes) end

--- Returns the total engine uptime in seconds (sum of all processed deltas).
---@return number Total engine uptime in seconds.
lurek.engine.uptime = function() end

---@class lurek.event
lurek.event = {}

--- Lua-side wrapper around a [`Signal`] with registry-stored callbacks.
---@class LSignal
LSignal = {}

--- Removes every callback registered for the specified event name and releases their Lua registry entries.
---@param name string The event name whose callbacks should be cleared
---@return integer The number of callbacks that were removed
function LSignal:clear(name) end

--- Removes every callback across all event names in this Signal instance, effectively resetting it to an empty state.
---@return integer The total number of callbacks that were removed
function LSignal:clearAll() end

--- Subscribes to an event name or wildcard glob pattern and returns a handle.
---@param name string An event name or wildcard pattern (e.g. "player.*")
---@param func function The Lua function to invoke when a matching event fires
---@return integer A unique handle ID for this subscription
function LSignal:connect(name, func) end

--- Fires all callbacks registered for the named event, passing any extra arguments to each callback function.
---@param ... string
---@return nil No return value.
function LSignal:emit(...) end

--- Returns the number of callbacks currently registered for the specified event name.
---@param name string The event name to query
---@return integer The number of active callbacks for this event
function LSignal:getCount(name) end

--- Returns the total number of callbacks registered across all event names in this Signal instance.
---@return integer The total number of active callbacks
function LSignal:getTotalCount() end

--- Registers a one-shot callback that fires at most once for the named event and then automatically removes itself.
---@param name string The event name to subscribe to (case-sensitive)
---@param callback function The Lua function to invoke exactly once
---@return integer A unique handle ID for this one-shot subscription
function LSignal:once(name, callback) end

--- Registers a Lua callback function for the named event and returns a numeric handle ID.
---@param name string The event name to subscribe to (case-sensitive)
---@param callback function The Lua function to invoke when the event fires
---@return integer A unique handle ID for this subscription
function LSignal:register(name, callback) end

--- Registers a callback with an associated filter predicate function.
---@param name string The event name to subscribe to (case-sensitive)
---@param callback function The Lua function to invoke when the filter passes
---@param filter function A predicate function that receives emit args and returns boolean
---@return integer A unique handle ID for this filtered subscription
function LSignal:registerWithFilter(name, callback, filter) end

--- Removes a previously registered subscription identified by its numeric handle.
---@param handle integer The subscription handle returned by `register` or `once`
---@return boolean True if the subscription existed and was removed
function LSignal:remove(handle) end

--- Returns the string type name of this userdata object.
---@return string The type name (e.g. "LScheduler", "LCamera", "LSignal")
function LSignal:type() end

--- Returns true if the given type name matches this object's type or any parent type.
---@param name string type name to test
---@return boolean True if the object matches the requested type.
function LSignal:typeOf(name) end

--- Discards every pending event in the engine event queue without processing them.
---@return nil No return value.
lurek.event.clear = function() end

--- Clears all recorded event history entries from the ring buffer.
---@return nil No return value.
lurek.event.clearHistory = function() end

--- Enables event history recording, keeping a ring buffer of the last `capacity` events pushed via `push()`.
---@param capacity integer Maximum number of events to retain (0 to disable)
---@return nil No return value.
lurek.event.enableHistory = function(capacity) end

--- Pushes an exit event onto the engine event queue, requesting a graceful shutdown at the end of the current frame.
---@param code? integer Optional OS exit code (default 0)
---@return nil No return value.
lurek.event.exit = function(code) end

--- Moves all events from the deferred buffer into the main engine event queue and clears the buffer.
---@return integer The number of deferred events moved to the main queue
lurek.event.flushDeferred = function() end

--- Returns an array of recently pushed events as tables.
---@return table Array of {name: string, args: table} event records
lurek.event.getHistory = function() end

--- Creates and returns a new independent Signal pub-sub dispatcher.
---@return LSignal A new empty Signal instance
lurek.event.newSignal = function() end

--- Returns an iterator function that pops events one at a time from the engine event queue.
---@return function An iterator function that yields (name, ...) tuples
lurek.event.poll = function() end

--- Synchronises OS-level windowing events into the engine event queue.
---@return nil No return value.
lurek.event.pump = function() end

---@param ... LuaValue
lurek.event.push = function(...) end

--- Pushes a named event into the deferred buffer instead of the main queue.
---@param ... string
---@return nil No return value.
lurek.event.pushDeferred = function(...) end

--- Alias for `exit()` - requests the engine to stop gracefully at the end of the current frame with exit code 0.
---@return nil No return value.
lurek.event.quit = function() end

--- Requests that the engine perform a full restart at the beginning of the next frame.
---@return nil No return value.
lurek.event.restart = function() end

--- Blocks the current thread until the next engine event arrives or the optional timeout elapses.
---@param timeout? number Maximum seconds to wait (nil = wait indefinitely)
---@return boolean True when an event was received before the timeout elapsed.
---@return string Name of the received event.
---@return table Payload array for the received event.
lurek.event.wait = function(timeout) end

---@class lurek.filesystem
lurek.filesystem = {}

--- Lua-side wrapper around a [`FileData`] buffer.
---@class LFileData
LFileData = {}

--- Returns the virtual path this data was loaded from.
---@return string Virtual path of this file data.
function LFileData:getFilename() end

--- Returns the file size in bytes.
---@return integer File size in bytes.
function LFileData:getSize() end

--- Returns the file content as a Lua string.
---@return string File contents as a Lua string.
function LFileData:getString() end

--- Returns the type name of this object.
---@return string Lua type name.
function LFileData:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LFileData:typeOf(name) end

--- Lua-side wrapper around a [`FileHandle`] with interior mutability.
---@class LFileHandle
LFileHandle = {}

--- Flushes any pending writes and closes the file handle.
---@return nil No return value.
function LFileHandle:close() end

--- Flushes all buffered writes to disk without closing the handle.
---@return nil No return value.
function LFileHandle:flush() end

--- Returns the access mode the file was opened with.
---@return string File access mode.
function LFileHandle:getMode() end

--- Returns the size of the open file in bytes.
---@return integer File size in bytes.
function LFileHandle:getSize() end

--- Returns whether the read cursor has reached the end of the file.
---@return boolean True when the file is at end-of-file.
function LFileHandle:isEOF() end

--- Reads bytes from the file, returning them as a string.
---@param count? integer Maximum bytes to read, or nil to read the rest of the file.
---@return string Bytes read from the file as a Lua string.
function LFileHandle:read(count) end

--- Reads the next line from the file without the trailing newline.
---@return string Next line, or nil at end of file.
function LFileHandle:readLine() end

--- Seeks the file position to the given byte offset from the start.
---@param pos integer Byte offset from the start of the file.
---@return integer New byte offset after seeking.
function LFileHandle:seek(pos) end

--- Returns the current read/write byte offset from the start of the file.
---@return integer Current byte offset.
function LFileHandle:tell() end

--- Returns the type name of this object.
---@return string Lua type name.
function LFileHandle:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LFileHandle:typeOf(name) end

--- Writes a string to the file and returns the number of bytes written.
---@param data string Text to write.
---@return integer Number of bytes written.
function LFileHandle:write(data) end

--- Lua userdata wrapper around a [`ZipMount`].
---@class LZipMount
LZipMount = {}

--- Returns true if `virtual_path` exists inside this ZIP mount.
---@param virtual_path string Virtual path to check inside the archive.
---@return boolean True when the path exists in the ZIP mount.
function LZipMount:contains(virtual_path) end

--- Returns a sorted array of all virtual paths exposed by this ZIP mount.
---@return table Array of virtual path strings.
function LZipMount:listFiles() end

--- Returns the virtual path prefix this archive was mounted under.
---@return string Virtual mount prefix.
function LZipMount:prefix() end

--- Reads a file from the ZIP and returns it as a string of bytes.
---@param virtual_path string Virtual path inside the mounted ZIP archive.
---@return string File contents as a Lua string.
function LZipMount:readFile(virtual_path) end

--- Returns the type name of this object.
---@return string Lua type name.
function LZipMount:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LZipMount:typeOf(name) end

--- Opens the file in append mode and writes the given string at the end.
---@param path string Save path to append to.
---@param data string Text to append.
---@return nil No return value.
lurek.filesystem.append = function(path, data) end

--- Copies a file within the sandbox from the game root into `save/`.
---@param src string Source path relative to the game root.
---@param dst string Destination path inside `save/`.
---@return nil No return value.
lurek.filesystem.copy = function(src, dst) end

--- Creates a directory and any missing parent directories in the save area.
---@param path string Save directory path to create.
---@return nil No return value.
lurek.filesystem.createDirectory = function(path) end

--- Creates an empty temporary file in the `save/` sandbox and returns its relative path.
---@param prefix? string Name prefix, or nil to use `tmp`.
---@return string Relative path of the created temp file.
lurek.filesystem.createTempFile = function(prefix) end

--- Returns whether the given file or directory exists.
---@param path string Virtual path to check.
---@return boolean True when the path exists.
lurek.filesystem.exists = function(path) end

--- Returns a table containing the names of every file and subdirectory in the given path.
---@param path string Directory path to list.
---@return table Array of entry names.
lurek.filesystem.getDirectoryItems = function(path) end

--- Returns the identity string used to locate the game's save directory.
---@return string Filesystem identity string.
lurek.filesystem.getIdentity = function() end

--- Returns a table of metadata for a path, or nil if the path does not exist.
---@param path string Virtual path to inspect.
---@return table Metadata table, or nil if the path does not exist.
lurek.filesystem.getInfo = function(path) end

--- Returns the sandboxed save data directory path.
---@return string Absolute save directory path.
lurek.filesystem.getSaveDirectory = function() end

--- Returns the absolute path of the directory the game was loaded from.
---@return string Absolute source directory path.
lurek.filesystem.getSource = function() end

--- Returns the current user's home directory path.
---@return string Current user's home directory path.
lurek.filesystem.getUserDirectory = function() end

--- Returns the current working directory path.
---@return string Current working directory path.
lurek.filesystem.getWorkingDirectory = function() end

--- Returns a sorted list of paths matching a simple wildcard pattern.
---@param pattern string Relative pattern where `*` matches many characters and `?` matches one character.
---@return table Array of matching relative paths.
lurek.filesystem.glob = function(pattern) end

--- Returns whether the given path is a directory.
---@param path string Virtual path to check.
---@return boolean True when the path is a directory.
lurek.filesystem.isDirectory = function(path) end

--- Returns whether the given path is a regular file.
---@param path string Virtual path to check.
---@return boolean True when the path is a regular file.
lurek.filesystem.isFile = function(path) end

--- Returns an iterator function over the lines of a text file.
---@param path string Virtual path to the text file.
---@return function Iterator function that returns the next line, or nil at end of file.
lurek.filesystem.lines = function(path) end

--- Returns a sorted list of all files under `path`, recursively.
---@param path string Root path to scan recursively.
---@return table Array of relative file paths using `/` separators.
lurek.filesystem.listRecursive = function(path) end

--- Loads and compiles a Lua file from the VFS, returning it as a callable function.
---@param path string Virtual path to the Lua chunk.
---@return function Compiled Lua function.
lurek.filesystem.load = function(path) end

--- Creates a directory and any missing parents relative to the game root.
---@param path string Relative directory path to create.
---@return nil No return value.
lurek.filesystem.mkdir = function(path) end

--- Mounts a directory at a virtual path inside the game filesystem.
---@param source string Source directory path.
---@param mountpoint string Virtual mount point.
---@return boolean True when the mount succeeds.
lurek.filesystem.mount = function(source, mountpoint) end

--- Mounts a ZIP archive at a virtual path prefix and returns a mount handle.
---@param archive_path string Path to the ZIP archive file.
---@param prefix string Virtual mount point, for example `mods/extra`.
---@return LZipMount Mounted ZIP archive handle.
lurek.filesystem.mountZip = function(archive_path, prefix) end

--- Moves or renames a file within the `save/` directory.
---@param src string Source path inside `save/`.
---@param dst string Destination path inside `save/`.
---@return nil No return value.
lurek.filesystem.move = function(src, dst) end

--- Loads a file from the VFS into a FileData buffer.
---@param path string Virtual path to load.
---@return LFileData Loaded file data buffer.
lurek.filesystem.newFileData = function(path) end

--- Opens a file and returns a readable/writable file handle.
---@param path string Virtual path to open.
---@param mode string File access mode.
---@return LFileHandle Open file handle.
lurek.filesystem.openFile = function(path, mode) end

--- Polls an async load handle, returning status and optional data.
---@param handle integer Async load handle returned by `readAsync`.
---@return string Current async load status.
---@return string Loaded payload when the async read completes.
lurek.filesystem.pollAsync = function(handle) end

--- Polls watched paths and returns the ones that changed since the last poll.
---@return table Array of changed path strings.
lurek.filesystem.pollWatchers = function() end

--- Reads a text file and returns its contents as a string.
---@param path string Virtual path to the text file.
---@return string File contents.
lurek.filesystem.read = function(path) end

--- Starts loading a file in the background and returns an opaque handle.
---@param path string Virtual path to load asynchronously.
---@return integer Async load handle.
lurek.filesystem.readAsync = function(path) end

--- Permanently deletes a file or empty directory from the save directory.
---@param path string Save path to remove.
---@return nil No return value.
lurek.filesystem.remove = function(path) end

--- Recursively deletes a directory and all its contents within `save/`.
---@param path string Directory path inside `save/`.
---@return nil No return value.
lurek.filesystem.removeDir = function(path) end

--- Sets the identity string that names the game's sandboxed save-data directory.
---@param name string New filesystem identity string.
---@return nil No return value.
lurek.filesystem.setIdentity = function(name) end

--- Returns lightweight file statistics for the given path.
---@param path string Virtual path to inspect.
---@return table Table with `size`, `isFile`, and `isDir` fields.
lurek.filesystem.stat = function(path) end

--- Resolves a relative game path to an absolute OS path string.
---@param path string Relative path to resolve.
---@return string Absolute OS path string.
lurek.filesystem.toAbsolutePath = function(path) end

--- Removes a virtual mount layer by mountpoint.
---@param mountpoint string Virtual mount point to remove.
---@return boolean True when a mount was removed.
lurek.filesystem.unmount = function(mountpoint) end

--- Removes `path` from the polled file-watch list.  No-op if not watched.
---@param path string Path to stop watching.
---@return nil No return value.
lurek.filesystem.unwatchPath = function(path) end

--- Adds `path` to the polled file-watch list.
---@param path string Path to start watching.
---@return nil No return value.
lurek.filesystem.watchPath = function(path) end

--- Writes a string to a file in the save directory.
---@param path string Save path to write.
---@param data string Text to write.
---@return nil No return value.
lurek.filesystem.write = function(path, data) end

---@class lurek.globe
---@field MAX_PROVINCES integer  Maximum number of provinces the globe supports.
---@field LOD_FAR string  LOD tier constant "far" — zoomed-out view (zoom < 1.5).
---@field LOD_MID string  LOD tier constant "mid" — medium zoom (1.5 ≤ zoom < 4.0).
---@field LOD_NEAR string  LOD tier constant "near" — close-zoom view (zoom ≥ 4.0).
lurek.globe = {}

--- Lua-accessible handle to a `Globe` inside a `GlobeRegistry`.
---@class LGlobe
LGlobe = {}

--- Add an arc (great-circle path between two lat/lon points).
---@param lat1 number Start latitude in degrees.
---@param lon1 number Start longitude in degrees.
---@param lat2 number End latitude in degrees.
---@param lon2 number End longitude in degrees.
---@param steps? integer Optional point count for the arc.
---@return integer Arc ID.
function LGlobe:addArc(lat1, lon1, lat2, lon2, steps) end

--- Add a text label. Returns label ID.
---@param ltype string Label type name.
---@param lat number Latitude in degrees.
---@param lon number Longitude in degrees.
---@param text string Label text.
---@return integer Label ID.
function LGlobe:addLabel(ltype, lat, lon, text) end

--- Add or replace a named thematic layer.
---@param name string Layer name.
---@param z_order? integer Optional layer draw order.
---@return nil No value is returned.
function LGlobe:addLayer(name, z_order) end

--- Add a marker. Returns marker ID.
---@param mtype string Marker type name.
---@param lat number Latitude in degrees.
---@param lon number Longitude in degrees.
---@param label? string Optional label text.
---@return integer Marker ID.
function LGlobe:addMarker(mtype, lat, lon, label) end

--- Adds a province from a table with id, centroid, vertices, neighbors, and base_color fields.
---@param p table Province definition table.
---@return boolean True when the province was added.
function LGlobe:addProvince(p) end

--- Find the shortest province path from `from_id` to `to_id`.
---@param from_id integer Starting province ID.
---@param to_id integer Target province ID.
---@return table Array of province IDs for the path.
function LGlobe:findPath(from_id, to_id) end

--- Get the current camera (lat, lon, zoom).
---@return number Camera latitude in degrees.
---@return number Camera longitude in degrees.
---@return number Camera zoom level.
function LGlobe:getCamera() end

--- Returns the current LOD tier as a string: "far", "mid", or "near".
---@return string Current LOD tier.
function LGlobe:getLod() end

--- Get a string attribute from a marker.
---@param id integer Marker ID to inspect.
---@param key string Attribute name.
---@return string Attribute value when present.
function LGlobe:getMarkerAttr(id, key) end

--- Returns the string identifier name assigned to this globe instance.
---@return string Globe name.
function LGlobe:getName() end

--- Returns the neighbor IDs of a province.
---@param id integer Province ID to inspect.
---@return table Array of neighbor province IDs.
function LGlobe:getNeighbors(id) end

--- Gets a string attribute from a province.
---@param id integer Province ID to inspect.
---@param key string Attribute name.
---@return string Attribute value when present.
function LGlobe:getProvinceAttr(id, key) end

--- Gets the current simulated time of day for daylight computation.
---@return number Current time of day in hours.
function LGlobe:getTimeOfDay() end

--- Hide a province for a viewer.
---@param viewer string Viewer name.
---@param id integer Province ID to hide.
---@return nil No value is returned.
function LGlobe:hideProvince(viewer, id) end

--- Returns true if the province is visible to the viewer.
---@param viewer string Viewer name.
---@param id integer Province ID to test.
---@return boolean True when the province is visible.
function LGlobe:isVisible(viewer, id) end

--- Move a marker to a new lat/lon.
---@param id integer Marker ID to move.
---@param lat number Latitude in degrees.
---@param lon number Longitude in degrees.
---@return nil No value is returned.
function LGlobe:moveMarker(id, lat, lon) end

--- Pan the orbit camera by delta-latitude and delta-longitude (degrees).
---@param dlat number Latitude delta in degrees.
---@param dlon number Longitude delta in degrees.
---@return nil No value is returned.
function LGlobe:pan(dlat, dlon) end

--- Returns the province ID under screen coordinates, or nil.
---@param sx number Screen x coordinate.
---@param sy number Screen y coordinate.
---@return integer Picked province ID when one is found.
function LGlobe:pick(sx, sy) end

--- Returns (lat, lon) of the screen point on the globe surface, or nil.
---@param sx number Screen x coordinate.
---@param sy number Screen y coordinate.
---@return number Picked latitude in degrees.
---@return number Picked longitude in degrees.
function LGlobe:pickLatLon(sx, sy) end

--- Returns the number of provinces.
---@return integer Number of provinces.
function LGlobe:provinceCount() end

--- Return all provinces reachable within `max_cost` steps from `start_id`.
---@param start_id integer Starting province ID.
---@param max_cost number Maximum traversal cost.
---@return table Table mapping province IDs to reach costs.
function LGlobe:reachable(start_id, max_cost) end

--- Removes an arc from the globe map by its unique string identifier.
---@param id integer Arc ID to remove.
---@return boolean True when the arc existed.
function LGlobe:removeArc(id) end

--- Removes a text label from the globe map by its unique string identifier.
---@param id integer Label ID to remove.
---@return boolean True when the label existed.
function LGlobe:removeLabel(id) end

--- Removes a texture layer from the globe map by its unique string identifier.
---@param name string Layer name to remove.
---@return boolean True when the layer existed.
function LGlobe:removeLayer(name) end

--- Removes a marker from the globe map by its unique string identifier.
---@param id integer Marker ID to remove.
---@return boolean True when the marker existed.
function LGlobe:removeMarker(id) end

--- Removes a province by ID. Returns true if it existed.
---@param id integer Province ID to remove.
---@return boolean True when the province existed.
function LGlobe:removeProvince(id) end

--- Reveal all provinces for a viewer.
---@param viewer string Viewer name.
---@return nil No value is returned.
function LGlobe:revealAll(viewer) end

--- Reveal a province for a viewer.
---@param viewer string Viewer name.
---@param id integer Province ID to reveal.
---@return nil No value is returned.
function LGlobe:revealProvince(viewer, id) end

--- Set the faction/viewer whose fog mask filters rendering.
---@param viewer? string Viewer name, or nil to clear it.
---@return nil No value is returned.
function LGlobe:setActiveViewer(viewer) end

--- Enable or disable province border rendering.
---@param show boolean Border visibility flag.
---@return nil No value is returned.
function LGlobe:setBorders(show) end

--- Set the camera position directly.
---@param lat number Latitude in degrees.
---@param lon number Longitude in degrees.
---@param zoom number Zoom factor.
---@return nil No value is returned.
function LGlobe:setCamera(lat, lon, zoom) end

--- Updates the visible text content of an existing globe label.
---@param id integer Label ID to update.
---@param text string New label text.
---@return nil No value is returned.
function LGlobe:setLabelText(id, text) end

--- Sets whether this specific label is visible on the globe.
---@param id integer Label ID to update.
---@param visible boolean Visibility flag.
---@return nil No value is returned.
function LGlobe:setLabelVisible(id, visible) end

--- Set layer opacity (0.0–1.0).
---@param name string Layer name.
---@param alpha number Opacity value.
---@return nil No value is returned.
function LGlobe:setLayerAlpha(name, alpha) end

--- Set a per-province color override on a layer.
---@param layer string Layer name.
---@param province_id integer Province ID to recolor.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a number Alpha channel.
---@return nil No value is returned.
function LGlobe:setLayerColor(layer, province_id, r, g, b, a) end

--- Sets whether this specific texture layer is visible on the globe.
---@param name string Layer name.
---@param visible boolean Visibility flag.
---@return nil No value is returned.
function LGlobe:setLayerVisible(name, visible) end

--- Set a string attribute on a marker.
---@param id integer Marker ID to update.
---@param key string Attribute name.
---@param value string Attribute value.
---@return nil No value is returned.
function LGlobe:setMarkerAttr(id, key, value) end

--- Sets whether this specific marker is visible on the globe.
---@param id integer Marker ID to update.
---@param visible boolean Visibility flag.
---@return nil No value is returned.
function LGlobe:setMarkerVisible(id, visible) end

--- Sets a string attribute on a province.
---@param id integer Province ID to update.
---@param key string Attribute name.
---@param value string Attribute value.
---@return boolean True when the province exists.
function LGlobe:setProvinceAttr(id, key, value) end

--- Set planet rotation (degrees).
---@param deg number Rotation in degrees.
---@return nil No value is returned.
function LGlobe:setRotation(deg) end

--- Set time of day (0.0–24.0 hours).
---@param t number Time of day in hours.
---@return nil No value is returned.
function LGlobe:setTimeOfDay(t) end

--- Returns the type name of this object.
---@return string Type name.
function LGlobe:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True when the type matches.
function LGlobe:typeOf(name) end

--- Advance globe simulation by dt seconds.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LGlobe:update(dt) end

--- Zoom the camera by a multiplier (>1 zooms in, <1 zooms out).
---@param factor number Zoom multiplier.
---@return nil No value is returned.
function LGlobe:zoom(factor) end

--- Lua-accessible handle to the shared `GlobeRegistry`.
---@class LGlobeRegistry
LGlobeRegistry = {}

--- Get an existing globe by name, or nil.
---@param name string Globe name.
---@return LGlobe Existing globe instance when found.
function LGlobeRegistry:get(name) end

--- Returns a table of all globe names.
---@return table Array of globe names.
function LGlobeRegistry:names() end

--- Create a globe with the given name and optional spec table.
---@param name string Globe name.
---@param spec? table Optional globe specification table.
---@return LGlobe New globe instance.
function LGlobeRegistry:new(name, spec) end

--- Removes a globe from the central registry by its string name.
---@param name string Globe name to remove.
---@return boolean True when the globe existed.
function LGlobeRegistry:remove(name) end

--- Returns the type name of this object.
---@return string Type name.
function LGlobeRegistry:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True when the type matches.
function LGlobeRegistry:typeOf(name) end

--- Get an existing globe by name, or nil.
---@param name string Globe name.
---@return LGlobe Existing globe instance when found.
lurek.globe.get = function(name) end

--- Great-circle distance between two lat/lon points (in unit-sphere radians).
---@param lat1 number Start latitude in degrees.
---@param lon1 number Start longitude in degrees.
---@param lat2 number End latitude in degrees.
---@param lon2 number End longitude in degrees.
---@return number Great-circle distance in radians.
lurek.globe.greatCircleDistance = function(lat1, lon1, lat2, lon2) end

--- Great-circle path as a table of {lat, lon} pairs.
---@param lat1 number Start latitude in degrees.
---@param lon1 number Start longitude in degrees.
---@param lat2 number End latitude in degrees.
---@param lon2 number End longitude in degrees.
---@param steps integer Number of interpolation steps.
---@return table Array of latitude and longitude pairs.
lurek.globe.greatCirclePath = function(lat1, lon1, lat2, lon2, steps) end

--- Convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z}.
---@param lat number Latitude in degrees.
---@param lon number Longitude in degrees.
---@return table Cartesian vector table with x, y, and z values.
lurek.globe.latLonToUnit = function(lat, lon) end

--- Load provinces from a TOML string and create a globe.
---@param name string Globe name.
---@param toml_src string TOML source string.
---@param spec? table Optional globe specification table.
---@return LGlobe Loaded globe instance.
lurek.globe.loadFromTOML = function(name, toml_src, spec) end

--- Creates a new globe instance with default settings and empty collections.
---@param name string Globe name.
---@param spec? table Optional globe specification table.
---@return LGlobe New globe instance.
lurek.globe.new = function(name, spec) end

---@class lurek.graph
lurek.graph = {}

---@class LGraph
LGraph = {}

--- Adds a directed edge between two nodes and returns its handle.
---@param from_ud Node Source node handle.
---@param to_ud Node Destination node handle.
---@param edge_type? string Type name for the new edge.
---@return Edge Newly created edge handle.
function LGraph:addEdge(from_ud, to_ud, edge_type) end

--- Places an item at a node.
---@param item_ud GraphItem Item handle to place.
---@param node_ud Node Destination node handle.
---@return boolean True if the item was placed at the node.
function LGraph:addItem(item_ud, node_ud) end

--- Adds a node and returns its handle.
---@param node_type? string Type name for the new node.
---@param capacity? integer Capacity for the new node.
---@return Node Newly created node handle.
function LGraph:addNode(node_type, capacity) end

--- Finds the shortest path between two nodes using A*.
---@param from_node Node Start node handle.
---@param to_node Node Goal node handle.
---@return table Path node handles from start to goal.
function LGraph:astar(from_node, to_node) end

--- Assigns each node the smallest non-negative integer colour not shared with any
---@return table Mapping from node ID to assigned color.
function LGraph:colorGraph() end

--- Creates a new unplaced item and returns its handle.
---@param item_type? string Type name for the new item.
---@param decay_time? number Initial decay time in seconds.
---@return GraphItem Newly created item handle.
function LGraph:createItem(item_type, decay_time) end

--- Finds the shortest path between two nodes using Dijkstra.
---@param from_ud Node Start node userdata.
---@param to_ud Node End node userdata.
---@return table Path result table with nodes, edges, and cost.
function LGraph:findPath(from_ud, to_ud) end

--- Finds the shortest path for a specific item, filtering by item type.
---@param item_ud GraphItem Graph item userdata.
---@param from_ud Node Start node userdata.
---@param to_ud Node End node userdata.
---@return table Path result table with nodes, edges, and cost.
function LGraph:findPathForItem(item_ud, from_ud, to_ud) end

--- Returns weakly connected components as a table of tables of Node handles.
---@return table Weakly connected components as tables of node handles.
function LGraph:getComponents() end

--- Returns the shortest path distance, or nil if unreachable.
---@param from_ud Node Start node userdata.
---@param to_ud Node End node userdata.
---@return number Shortest path distance between the two nodes.
function LGraph:getDistance(from_ud, to_ud) end

--- Returns the edge between two nodes, or nil if none exists.
---@param from_ud Node Source node handle.
---@param to_ud Node Destination node handle.
---@return Edge Edge between the two nodes.
function LGraph:getEdgeBetween(from_ud, to_ud) end

--- Returns the number of edges in the graph.
---@return integer Number of edges in the graph.
function LGraph:getEdgeCount() end

--- Returns a table of all Edge handles.
---@return table All edge handles in the graph.
function LGraph:getEdges() end

--- Returns the number of items in the graph.
---@return integer Number of items in the graph.
function LGraph:getItemCount() end

--- Returns a table of all GraphItem handles.
---@return table All GraphItem handles in the graph.
function LGraph:getItems() end

--- Returns a table of direct neighbor Node handles.
---@param node_ud Node Node userdata.
---@return table Direct neighbor node handles.
function LGraph:getNeighbors(node_ud) end

--- Returns the number of nodes in the graph.
---@return integer Number of nodes in the graph.
function LGraph:getNodeCount() end

--- Returns a table of all Node handles.
---@return table All node handles in the graph.
function LGraph:getNodes() end

--- Returns a table of Node handles reachable from the given node.
---@param from_ud Node Start node userdata.
---@param max_dist? number Maximum distance.
---@return table Reachable node handles from the start node.
function LGraph:getReachable(from_ud, max_dist) end

--- Returns a statistics snapshot table.
---@return table Statistics snapshot for the graph.
function LGraph:getStats() end

--- Returns true if the graph contains a directed cycle.
---@return boolean True if the graph contains a directed cycle.
function LGraph:hasCycle() end

--- Returns true if the edge exists in the graph.
---@param edge_ud Edge Edge handle to test.
---@return boolean True if the graph contains the edge.
function LGraph:hasEdge(edge_ud) end

--- Returns true if the item exists in the graph.
---@param item_ud GraphItem Graph item userdata.
---@return boolean True if the graph contains the item.
function LGraph:hasItem(item_ud) end

--- Returns true if the node exists in the graph.
---@param node_ud Node Node handle to test.
---@return boolean True if the graph contains the node.
function LGraph:hasNode(node_ud) end

--- Returns `true` when the graph can be 2-coloured (bipartite check via BFS).
---@return boolean True if the graph is bipartite.
function LGraph:isBipartite() end

--- Returns edge IDs forming a minimum spanning tree (Kruskal, undirected view).
---@return table Edge IDs in a minimum spanning tree.
function LGraph:mst() end

--- Registers a callback for a graph simulation event.
---@param event_name string Graph event name.
---@param func function Callback to register for that event.
---@return nil No value is returned.
function LGraph:on(event_name, func) end

--- Processes all supply/demand declarations and fires event callbacks.
---@return nil No value is returned.
function LGraph:processDemand() end

--- Removes an edge from the graph.
---@param edge_ud Edge Edge handle to remove.
---@return boolean True if the edge was removed.
function LGraph:removeEdge(edge_ud) end

--- Removes an item from the graph entirely.
---@param item_ud GraphItem Graph item userdata.
---@return boolean True if the item was removed.
function LGraph:removeItem(item_ud) end

--- Removes a node from the graph.
---@param node_ud Node Node handle to remove.
---@return boolean True if the node was removed.
function LGraph:removeNode(node_ud) end

--- Sends an item onto an edge to begin transit.
---@param item_ud GraphItem Graph item userdata.
---@param edge_ud Edge Edge userdata.
---@return boolean True when the item was queued onto the edge.
function LGraph:sendItem(item_ud, edge_ud) end

--- Runs one discrete simulation step and fires event callbacks.
---@return nil No value is returned.
function LGraph:step() end

--- Advances simulation by dt seconds using a parallelised decay phase.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LGraph:tickParallel(dt) end

--- Returns a topologically sorted table of Node handles, or nil if a cycle exists.
---@return table Topologically sorted node handles.
function LGraph:topologicalSort() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LGraph:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True if the type name matches Graph or Object.
function LGraph:typeOf(name) end

--- Advances simulation by dt seconds and fires event callbacks.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LGraph:update(dt) end

---@class LGraphEdge
LGraphEdge = {}

--- Adds an item type to the edge allow-list.
---@param t string Item type to allow.
---@return nil No value is returned.
function LGraphEdge:addAllowedType(t) end

--- Clears the edge allow-list so all item types are permitted.
---@return nil No value is returned.
function LGraphEdge:clearAllowedTypes() end

--- Returns the edge capacity (-1 = unlimited).
---@return integer Edge capacity, or -1 if unlimited.
function LGraphEdge:getCapacity() end

--- Returns the cooldown duration in seconds.
---@return number Cooldown duration in seconds.
function LGraphEdge:getCooldown() end

--- Returns the source node handle.
---@return Node Source node handle.
function LGraphEdge:getFrom() end

--- Returns a table of GraphItem handles currently in transit on this edge.
---@return table GraphItem handles currently in transit on this edge.
function LGraphEdge:getItemsInTransit() end

--- Returns the speed modifier applied to items in transit.
---@return number Speed modifier for items in transit.
function LGraphEdge:getSpeedModifier() end

--- Returns items per second this edge can transfer.
---@return number Edge throughput in items per second.
function LGraphEdge:getThroughput() end

--- Returns the destination node handle.
---@return Node Destination node handle.
function LGraphEdge:getTo() end

--- Returns the travel time in seconds for items on this edge.
---@return number Travel time in seconds.
function LGraphEdge:getTravelTime() end

--- Returns the edge type string.
---@return string Edge type name.
function LGraphEdge:getType() end

--- Returns the pathfinding weight of this edge.
---@return number Pathfinding weight.
function LGraphEdge:getWeight() end

--- Returns true if the edge is active.
---@return boolean True if this edge is active.
function LGraphEdge:isActive() end

--- Returns true if items can travel the edge in either direction.
---@return boolean True if items can travel in both directions.
function LGraphEdge:isBidirectional() end

--- Returns true if the given item type is allowed on this edge.
---@param t string Item type to test.
---@return boolean True if the item type is allowed on this edge.
function LGraphEdge:isItemTypeAllowed(t) end

--- Returns true if the edge is currently on cooldown.
---@return boolean True if this edge is currently on cooldown.
function LGraphEdge:isOnCooldown() end

--- Removes an item type from the edge allow-list.
---@param t string Item type to remove.
---@return boolean True if the item type was removed.
function LGraphEdge:removeAllowedType(t) end

--- Sets the active state of this edge.
---@param a boolean New active state.
---@return nil No value is returned.
function LGraphEdge:setActive(a) end

--- Sets whether items can travel the edge in either direction.
---@param b boolean New bidirectional state.
---@return nil No value is returned.
function LGraphEdge:setBidirectional(b) end

--- Sets the edge capacity (-1 = unlimited).
---@param c integer New edge capacity.
---@return nil No value is returned.
function LGraphEdge:setCapacity(c) end

--- Sets the cooldown duration in seconds.
---@param c number New cooldown duration in seconds.
---@return nil No value is returned.
function LGraphEdge:setCooldown(c) end

--- Sets the speed modifier applied to items in transit.
---@param m number New speed modifier.
---@return nil No value is returned.
function LGraphEdge:setSpeedModifier(m) end

--- Sets items per second this edge can transfer.
---@param t number New edge throughput.
---@return nil No value is returned.
function LGraphEdge:setThroughput(t) end

--- Sets the travel time in seconds for items on this edge.
---@param t number New travel time in seconds.
---@return nil No value is returned.
function LGraphEdge:setTravelTime(t) end

--- Sets the edge type string.
---@param t string New edge type name.
---@return nil No value is returned.
function LGraphEdge:setType(t) end

--- Sets the pathfinding weight of this edge.
---@param w number New pathfinding weight.
---@return nil No value is returned.
function LGraphEdge:setWeight(w) end

--- Returns the type name "GraphEdge".
---@return string Lua-visible type name.
function LGraphEdge:type() end

--- Returns true when the given name matches "GraphEdge" or a parent type.
---@param name string Type name to compare.
---@return boolean True when the type name matches GraphEdge or Object.
function LGraphEdge:typeOf(name) end

---@class LGraphItem
LGraphItem = {}

--- Returns the decay time in seconds (-1 = immortal).
---@return number Decay time in seconds, or -1 for an immortal item.
function LGraphItem:getDecayTime() end

--- Returns the item position: node userdata if at a node, (edge, progress)
---@return nil No value is returned.
function LGraphItem:getPosition() end

--- Returns the item priority.
---@return integer Current item priority.
function LGraphItem:getPriority() end

--- Returns the remaining life in seconds.
---@return number Remaining life in seconds.
function LGraphItem:getRemainingLife() end

--- Returns the item type string.
---@return string Item type name.
function LGraphItem:getType() end

--- Returns true if the item is alive.
---@return boolean True if the item is still alive.
function LGraphItem:isAlive() end

--- Marks this graph item as dead so it is removed on the next cleanup pass.
---@return nil No value is returned.
function LGraphItem:kill() end

--- Sets the decay time in seconds (-1 = immortal).
---@param t number New decay time in seconds.
---@return nil No value is returned.
function LGraphItem:setDecayTime(t) end

--- Sets the scheduling priority; higher values are processed before lower ones.
---@param p integer New item priority.
---@return nil No value is returned.
function LGraphItem:setPriority(p) end

--- Sets the item type string.
---@param t string New item type name.
---@return nil No value is returned.
function LGraphItem:setType(t) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LGraphItem:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True if the type name matches GraphItem or Object.
function LGraphItem:typeOf(name) end

---@class LGraphNode
LGraphNode = {}

--- Declares a demand for the given item type, quantity, and priority.
---@param item_type string Item type name.
---@param quantity integer Quantity value.
---@param priority? integer Priority value.
---@return nil No value is returned.
function LGraphNode:addDemand(item_type, quantity, priority) end

--- Declares a supply of the given item type and quantity at this node.
---@param item_type string Item type name.
---@param quantity integer Quantity value.
---@return nil No value is returned.
function LGraphNode:addSupply(item_type, quantity) end

--- Attaches a string tag to this node for fast group queries.
---@param tag string Tag name.
---@return nil No value is returned.
function LGraphNode:addTag(tag) end

--- Removes all conversion rules from this node.
---@return nil No value is returned.
function LGraphNode:clearAllConversions() end

--- Removes the conversion rule for the given input type.
---@param in_type string Input type name.
---@return nil No value is returned.
function LGraphNode:clearConversion(in_type) end

--- Removes all demand declarations from this node.
---@return nil No value is returned.
function LGraphNode:clearDemands() end

--- Removes all supply declarations from this node.
---@return nil No value is returned.
function LGraphNode:clearSupplies() end

--- Removes all tags from this node.
---@return nil No value is returned.
function LGraphNode:clearTags() end

--- Pops the next item from the node queue, or nil if empty.
---@return nil No value is returned.
function LGraphNode:dequeue() end

--- Pushes an item into the node queue.
---@param item_ud GraphItem Graph item userdata.
---@return boolean True if the item was queued.
function LGraphNode:enqueue(item_ud) end

--- Returns the node capacity (-1 = unlimited).
---@return integer Node capacity, or -1 if unlimited.
function LGraphNode:getCapacity() end

--- Returns a table of Edge handles connected to this node.
---@param dir? string Edge direction filter: in, out, or both.
---@return table Edge handles connected to this node.
function LGraphNode:getEdges(dir) end

--- Returns the flow mode as a string.
---@return string Flow mode name.
function LGraphNode:getFlowMode() end

--- Returns the number of items currently at this node.
---@return integer Number of items at this node.
function LGraphNode:getItemCount() end

--- Returns a table of GraphItem handles at this node.
---@return table GraphItem handles currently at this node.
function LGraphNode:getItems() end

--- Returns the overflow policy as a string.
---@return string Overflow policy name.
function LGraphNode:getOverflowPolicy() end

--- Returns the processing time in seconds.
---@return number Processing time in seconds.
function LGraphNode:getProcessTime() end

--- Returns the pull filter string, or nil if unset.
---@return string Configured pull filter item type.
function LGraphNode:getPullFilter() end

--- Returns items per second this node pulls.
---@return number Pull rate in items per second.
function LGraphNode:getPullRate() end

--- Returns the push filter string, or nil if unset.
---@return string Configured push filter item type.
function LGraphNode:getPushFilter() end

--- Returns items per second this node pushes.
---@return number Push rate in items per second.
function LGraphNode:getPushRate() end

--- Returns the queue capacity (-1 = unlimited).
---@return integer Queue capacity, or -1 if unlimited.
function LGraphNode:getQueueCapacity() end

--- Returns the number of items currently in the queue.
---@return integer Number of items currently in the queue.
function LGraphNode:getQueueSize() end

--- Returns a table of tag strings on this node.
---@return table Tag strings attached to this node.
function LGraphNode:getTags() end

--- Returns the node type string.
---@return string Current node type string.
function LGraphNode:getType() end

--- Returns true if this node has the given tag.
---@param tag string Tag name.
---@return boolean True if this node has the tag.
function LGraphNode:hasTag(tag) end

--- Returns true if the node is active.
---@return boolean True if this node is active.
function LGraphNode:isActive() end

--- Returns true if the node has reached its capacity.
---@return boolean True if this node has reached capacity.
function LGraphNode:isFull() end

--- Returns true if the node queue is enabled.
---@return boolean True if the node queue is enabled.
function LGraphNode:isQueueEnabled() end

--- Removes the demand declaration for the given item type.
---@param item_type string Item type name.
---@return boolean True if the demand entry was removed.
function LGraphNode:removeDemand(item_type) end

--- Removes the supply declaration for the given item type.
---@param item_type string Item type name.
---@return boolean True if the supply entry was removed.
function LGraphNode:removeSupply(item_type) end

--- Removes a tag from this node.
---@param tag string Tag name.
---@return boolean True if the tag was removed.
function LGraphNode:removeTag(tag) end

--- Sets the active state of this node.
---@param a boolean New active state.
---@return nil No value is returned.
function LGraphNode:setActive(a) end

--- Sets the node capacity (-1 = unlimited).
---@param c integer New node capacity.
---@return nil No value is returned.
function LGraphNode:setCapacity(c) end

--- Adds or replaces a conversion rule on this node.
---@param in_type string Input item type.
---@param out_type string Output item type.
---@param in_count? integer Number of input items required.
---@param out_count? integer Number of output items produced.
---@return nil No value is returned.
function LGraphNode:setConversion(in_type, out_type, in_count, out_count) end

--- Sets the flow mode from a string.
---@param m string Flow mode name.
---@return nil No value is returned.
function LGraphNode:setFlowMode(m) end

--- Sets the overflow policy from a string.
---@param p string Overflow policy name.
---@return nil No value is returned.
function LGraphNode:setOverflowPolicy(p) end

--- Sets the processing time in seconds.
---@param t number New processing time in seconds.
---@return nil No value is returned.
function LGraphNode:setProcessTime(t) end

--- Sets the pull filter string, or nil to clear.
---@param f? string Item type filter for pulled items.
---@return nil No value is returned.
function LGraphNode:setPullFilter(f) end

--- Sets items per second this node pulls.
---@param r number New pull rate.
---@return nil No value is returned.
function LGraphNode:setPullRate(r) end

--- Sets the push filter string, or nil to clear.
---@param f? string Item type filter for pushed items.
---@return nil No value is returned.
function LGraphNode:setPushFilter(f) end

--- Sets items per second this node pushes.
---@param r number New push rate.
---@return nil No value is returned.
function LGraphNode:setPushRate(r) end

--- Sets the queue capacity (-1 = unlimited).
---@param c integer New queue capacity.
---@return nil No value is returned.
function LGraphNode:setQueueCapacity(c) end

--- Enables or disables the node queue.
---@param e boolean New queue enabled state.
---@return nil No value is returned.
function LGraphNode:setQueueEnabled(e) end

--- Sets the node type string.
---@param t string New node type name.
---@return nil No value is returned.
function LGraphNode:setType(t) end

--- Returns the type name "GraphNode".
---@return string Lua-visible type name.
function LGraphNode:type() end

--- Returns true when the given name matches "GraphNode" or a parent type.
---@param name string Node or graph name.
---@return boolean True if the type name matches GraphNode or Object.
function LGraphNode:typeOf(name) end

--- Creates a new empty directed graph for item flow simulation.
---@return Graph New empty graph.
lurek.graph.newGraph = function() end

---@class lurek.html
lurek.html = {}

--- Lua wrapper around a shared `HtmlDocument` and its callback registry.
---@class LHtmlDocument
LHtmlDocument = {}

--- Appends stylesheet text after existing CSS rules.
---@param css string Stylesheet text to append after existing CSS rules.
---@return nil No value is returned.
function LHtmlDocument:addCss(css) end

--- Removes all stylesheet rules from this document.
---@return nil No value is returned.
function LHtmlDocument:clearCss() end

--- Builds the current draw command list and discards it for now.
---@param x? number Optional X offset for the draw origin.
---@param y? number Optional Y offset for the draw origin.
---@return nil No value is returned.
function LHtmlDocument:draw(x, y) end

--- Finds the first element whose id attribute matches the given value, or nil.
---@param id string Element id attribute to look up.
---@return LHtmlElement Matching element handle.
function LHtmlDocument:getElementById(id) end

--- Returns the source markup used by this document.
---@return string Current document HTML markup.
function LHtmlDocument:getHtml() end

--- Returns the root element for this document.
---@return LHtmlElement Root element handle for this document.
function LHtmlDocument:getRoot() end

--- Returns the document layout viewport in UI pixels.
---@return number Viewport width in UI pixels.
---@return number Viewport height in UI pixels.
function LHtmlDocument:getViewport() end

--- Returns whether DOM, CSS, viewport, or layout state changed.
---@return boolean True when the document needs to be redrawn or relaid out.
function LHtmlDocument:isDirty() end

--- Forwards a key press and emits a keydown event.
---@param key string Key name to dispatch.
---@return boolean True when the key press was consumed by the document.
function LHtmlDocument:keypressed(key) end

--- Forwards a mouse move event.
---@param x number Mouse X coordinate in UI pixels.
---@param y number Mouse Y coordinate in UI pixels.
---@return boolean True when the movement affected hovered state.
function LHtmlDocument:mousemoved(x, y) end

--- Forwards a mouse press and emits a minimal click event.
---@param x number Mouse X coordinate in UI pixels.
---@param y number Mouse Y coordinate in UI pixels.
---@param button? integer Optional mouse button index.
---@return boolean True when the press was consumed by the document.
function LHtmlDocument:mousepressed(x, y, button) end

--- Forwards a mouse release event.
---@param x number Mouse X coordinate in UI pixels.
---@param y number Mouse Y coordinate in UI pixels.
---@param button? integer Optional mouse button index.
---@return boolean True when the release was consumed by the document.
function LHtmlDocument:mousereleased(x, y, button) end

--- Removes a document-level event listener.
---@param handle integer Listener handle returned by `on`.
---@return nil No value is returned.
function LHtmlDocument:off(handle) end

--- Registers a document-level event listener.
---@param event string DOM event name to listen for.
---@param fn function Lua callback to invoke when the event fires.
---@return integer Listener handle that can be passed to `off`.
function LHtmlDocument:on(event, fn) end

--- Finds the first element matching a supported selector.
---@param selector string CSS selector to evaluate.
---@return LHtmlElement First element that matches the selector.
function LHtmlDocument:query(selector) end

--- Returns all elements matching a supported selector in document order.
---@param selector string CSS selector to evaluate.
---@return table Array of matching `LHtmlElement` handles.
function LHtmlDocument:queryAll(selector) end

--- Forces a layout pass immediately.
---@return nil No value is returned.
function LHtmlDocument:relayout() end

--- Replaces this document's stylesheet text.
---@param css string Stylesheet text to replace the current CSS rules.
---@return nil No value is returned.
function LHtmlDocument:setCss(css) end

--- Replaces this document's markup and invalidates existing element handles.
---@param html string HTML markup string to load into the document.
---@return nil No value is returned.
function LHtmlDocument:setHtml(html) end

--- Sets the document layout viewport in UI pixels.
---@param w number Viewport width in UI pixels.
---@param h number Viewport height in UI pixels.
---@return nil No value is returned.
function LHtmlDocument:setViewport(w, h) end

--- Forwards text input and emits an input event for focused input elements.
---@param text string Text input payload to insert.
---@return boolean True when the text input was consumed by the document.
function LHtmlDocument:textinput(text) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LHtmlDocument:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches this object.
function LHtmlDocument:typeOf(name) end

--- Advances document state and runs layout if needed.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LHtmlDocument:update(dt) end

--- Forwards a mouse wheel event.
---@param dx number Horizontal wheel delta.
---@param dy number Vertical wheel delta.
---@return boolean True when the wheel event affected the document.
function LHtmlDocument:wheelmoved(dx, dy) end

--- Lua wrapper that references a single element inside a shared `HtmlDocument`.
---@class LHtmlElement
LHtmlElement = {}

--- Adds a CSS class to this element.
---@param name string CSS class name to add.
---@return nil No value is returned.
function LHtmlElement:addClass(name) end

--- Appends HTML inside this element.
---@param html string HTML markup to append inside the element.
---@return nil No value is returned.
function LHtmlElement:appendHtml(html) end

--- Clears focus from this element if it currently has focus.
---@return nil No value is returned.
function LHtmlElement:blur() end

--- Gives focus to this element.
---@return nil No value is returned.
function LHtmlElement:focus() end

--- Returns an attribute value or nil.
---@param name string Attribute name to read.
---@return string Attribute value for the requested name.
function LHtmlElement:getAttribute(name) end

--- Returns the owning HtmlDocument.
---@return LHtmlDocument Document handle that owns this element.
function LHtmlElement:getDocument() end

--- Returns this element's inner HTML.
---@return string Inner HTML markup for this element.
function LHtmlElement:getHtml() end

--- Returns this element's id or nil.
---@return string Current `id` attribute value.
function LHtmlElement:getId() end

--- Returns this element's last computed layout rectangle.
---@return number Layout X position in UI pixels.
---@return number Layout Y position in UI pixels.
---@return number Layout width in UI pixels.
---@return number Layout height in UI pixels.
function LHtmlElement:getRect() end

--- Returns an inline or stylesheet value for a property.
---@param name string CSS property name to read.
---@return string Resolved style value for the property.
function LHtmlElement:getStyle(name) end

--- Returns this element's tag name.
---@return string Tag name of this element.
function LHtmlElement:getTagName() end

--- Returns this element's text content.
---@return string Text content of this element.
function LHtmlElement:getText() end

--- Returns whether this element has a CSS class.
---@param name string CSS class name to check.
---@return boolean True when the element has the class.
function LHtmlElement:hasClass(name) end

--- Removes an element event listener.
---@param handle integer Listener handle returned by `on`.
---@return nil No value is returned.
function LHtmlElement:off(handle) end

--- Registers an element event listener.
---@param event string DOM event name to listen for.
---@param fn function Lua callback to invoke when the event fires.
---@return integer Listener handle that can be passed to `off`.
function LHtmlElement:on(event, fn) end

--- Finds the first descendant matching a selector.
---@param selector string CSS selector to evaluate.
---@return LHtmlElement First descendant that matches the selector.
function LHtmlElement:query(selector) end

--- Returns all descendants matching a selector.
---@param selector string CSS selector to evaluate.
---@return table Array of matching descendant `LHtmlElement` handles.
function LHtmlElement:queryAll(selector) end

--- Removes this element from the document tree.
---@return nil No value is returned.
function LHtmlElement:remove() end

--- Removes the named attribute from this element; does nothing if absent.
---@param name string Attribute name to remove.
---@return nil No value is returned.
function LHtmlElement:removeAttribute(name) end

--- Removes a CSS class from this element.
---@param name string CSS class name to remove.
---@return nil No value is returned.
function LHtmlElement:removeClass(name) end

--- Sets or removes an attribute value.
---@param name string Attribute name to update.
---@param value? string New attribute value.
---@return nil No value is returned.
function LHtmlElement:setAttribute(name, value) end

--- Replaces this element's inner HTML.
---@param html string Replacement inner HTML markup.
---@return nil No value is returned.
function LHtmlElement:setHtml(html) end

--- Sets or removes this element's id.
---@param id? string New `id` attribute value.
---@return nil No value is returned.
function LHtmlElement:setId(id) end

--- Sets or removes an inline style value.
---@param name string CSS property name to update.
---@param value? string New inline style value.
---@return nil No value is returned.
function LHtmlElement:setStyle(name, value) end

--- Replaces this element's text content.
---@param text string Replacement text content.
---@return nil No value is returned.
function LHtmlElement:setText(text) end

--- Toggles a CSS class and returns the final state.
---@param name string CSS class name to toggle.
---@param force? boolean Optional forced final state.
---@return boolean Final presence of the CSS class after toggling.
function LHtmlElement:toggleClass(name, force) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LHtmlElement:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches this object.
function LHtmlElement:typeOf(name) end

--- Returns true if `preventDefault` has been called on this event.
---@return boolean True when `preventDefault()` has been called.
lurek.html.isDefaultPrevented = function() end

--- Placeholder for future sandboxed document loading.
---@param path string Source path to load once this API is implemented.
---@param opts? table Optional CSS and viewport configuration table.
---@return LHtmlDocument Loaded HTML document.
lurek.html.loadDocument = function(path, opts) end

--- Creates a detached HTML document from markup and optional CSS/viewport options.
---@param html? string Initial HTML markup string for the document.
---@param opts? table Optional CSS and viewport configuration table.
---@return LHtmlDocument Newly created detached HTML document.
lurek.html.newDocument = function(html, opts) end

--- Prevents the default browser action associated with this event.
lurek.html.preventDefault = function() end

--- Stops the event from bubbling up to parent elements.
lurek.html.stopPropagation = function() end

--- Returns whether the active HTML facade supports a named feature.
---@param feature string Feature name to query.
---@return boolean True when the feature is supported.
lurek.html.supports = function(feature) end

---@class lurek.i18n
lurek.i18n = {}

--- Builds an inverted word index for the active locale.
---@return table Index table that maps each word to an array of matching keys.
lurek.i18n.buildIndex = function() end

--- Returns unique first-path-segment category prefixes for all active locale keys.
---@return table Array of category prefix strings.
lurek.i18n.categories = function() end

--- Formats a Unix timestamp according to the active locale's date order.
---@param timestamp integer Unix timestamp in UTC seconds.
---@param fmt? string Optional format name such as `short`, `long`, or `iso`.
---@return string Formatted date string.
lurek.i18n.formatDate = function(timestamp, fmt) end

--- Formats a number with locale-aware decimal and thousands separators.
---@param n number Number to format.
---@param opts? table Optional formatting options such as `decimals`.
---@return string Formatted number string.
lurek.i18n.formatNumber = function(n, opts) end

--- Returns all loaded locale codes.
---@return table Array of loaded locale code strings.
lurek.i18n.getAvailableLanguages = function() end

--- Returns the base fallback language.
---@return string Stored base locale code.
lurek.i18n.getBase = function() end

--- Returns the current fallback locale array.
---@return table Array of fallback locale code strings.
lurek.i18n.getFallbacks = function() end

--- Returns all known keys for the active locale.
---@return table Array of translation key strings.
lurek.i18n.getKeys = function() end

--- Returns the currently active locale code.
---@return string Active locale code.
lurek.i18n.getLanguage = function() end

--- Returns all loaded locale codes.
---@return table Array of loaded locale code strings.
lurek.i18n.getLanguages = function() end

--- Returns an array of all currently loaded locale codes.
---@return table Array of loaded locale code strings.
lurek.i18n.getLoadedLocales = function() end

--- Returns whether a key exists in the active locale.
---@param key string Translation key to check.
---@return boolean True when the active locale contains the key.
lurek.i18n.hasKey = function(key) end

--- Returns whether a locale has been loaded.
---@param locale string Locale code to check.
---@return boolean True when the locale exists in the catalog.
lurek.i18n.hasLanguage = function(locale) end

--- Interpolates `{name}` placeholders in a template string.
---@param template string Template string containing placeholders.
---@param vars table Placeholder values keyed by name.
---@return string Interpolated string result.
lurek.i18n.interpolate = function(template, vars) end

--- Returns the number of keys loaded in the active locale.
---@return integer Count of translation keys in the active locale.
lurek.i18n.keyCount = function() end

--- Returns all keys in the active locale whose first path segment matches the category.
---@param category string Category prefix to match.
---@return table Array of matching translation key strings.
lurek.i18n.keysInCategory = function(category) end

--- Loads a language table under the given locale code.
---@param locale string Locale code to load.
---@param table table Nested translation table to flatten and store.
---@return nil No value is returned.
lurek.i18n.loadTable = function(locale, table) end

--- Merges a flat key-value table into an existing locale without replacing the whole table.
---@param locale string Locale code to modify.
---@param entries table Flat translation table keyed by translation key.
---@return nil No value is returned.
lurek.i18n.mergeLocale = function(locale, entries) end

--- Unregisters all language-change callbacks.
---@return nil No value is returned.
lurek.i18n.offChange = function() end

--- Registers a callback invoked when `setLanguage()` is called.
---@param cb function Callback that receives `(new_locale, old_locale)`.
---@return nil No value is returned.
lurek.i18n.onChange = function(cb) end

--- Registers a callback invoked when `setLanguage()` is called.
---@param cb function Callback that receives `(new_locale, old_locale)`.
---@return nil No value is returned.
lurek.i18n.onLanguageChange = function(cb) end

--- Returns the CLDR plural category for a number.
---@param n number Number to classify.
---@return string Plural category string such as `one` or `other`.
lurek.i18n.pluralFor = function(n) end

--- Searches active locale values for a case-insensitive substring query.
---@param query string Search text to match within translation values.
---@param limit? integer Optional maximum number of results to return.
---@return table Array of `{ key, value }` result tables.
lurek.i18n.search = function(query, limit) end

--- Searches the provided pre-built index for entries matching all words in the query.
---@param index table Index table returned by `buildIndex`.
---@param query string Search text to split into words.
---@param limit? integer Optional maximum number of results to return.
---@return table Array of matching translation key strings.
lurek.i18n.searchIndexed = function(index, query, limit) end

--- Sets the base fallback language.
---@param locale string Locale code to store as the base language.
---@return nil No value is returned.
lurek.i18n.setBase = function(locale) end

--- Sets the ordered list of fallback locale codes tried when a key is missing.
---@param locales table Array of fallback locale code strings.
---@return nil No value is returned.
lurek.i18n.setFallbacks = function(locales) end

--- Inserts or overwrites a single key in the given locale.
---@param locale string Locale code to modify.
---@param key string Translation key to set.
---@param value string Translation value to store.
---@return nil No value is returned.
lurek.i18n.setKey = function(locale, key, value) end

--- Sets the active translation language.
---@param locale string Locale code to make active.
---@return nil No value is returned.
lurek.i18n.setLanguage = function(locale) end

--- Translates a key against the active locale with optional interpolation and pluralization.
---@param key string Translation key to resolve.
---@param vars? table Optional placeholder values for interpolation.
---@param count? number Optional count used for plural form selection.
---@return string Resolved translation string.
lurek.i18n.t = function(key, vars, count) end

--- Looks up a translation key augmented with a gender suffix.
---@param key string Base translation key.
---@param gender string Gender suffix such as `masculine`, `feminine`, or `neutral`.
---@param vars? table Optional placeholder substitutions passed to `t`.
---@return string Gender-specific translation, or the base translation when missing.
lurek.i18n.tGender = function(key, gender, vars) end

--- Unloads a locale from the catalog.
---@param locale string Locale code to remove.
---@return boolean True when the locale existed and was removed.
lurek.i18n.unloadTable = function(locale) end

---@class lurek.image
lurek.image = {}

--- Lua-side wrapper around [`CompressedImageData`].
---@class LCompressedImageData
LCompressedImageData = {}

--- Returns the width and height of the base mip level.
---@return integer Image width in pixels.
---@return integer Image height in pixels.
function LCompressedImageData:getDimensions() end

--- Returns the compressed format name string.
---@return string Compressed format name.
function LCompressedImageData:getFormat() end

--- Returns the height of the base mip level in pixels.
---@return integer Base mip level height in pixels.
function LCompressedImageData:getHeight() end

--- Returns the number of mipmap levels stored.
---@return integer Number of stored mipmap levels.
function LCompressedImageData:getMipmapCount() end

--- Returns the width of the base mip level in pixels.
---@return integer Base mip level width in pixels.
function LCompressedImageData:getWidth() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LCompressedImageData:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True if the type name matches LCompressedImageData or Object.
function LCompressedImageData:typeOf(name) end

--- RGBA pixel buffer for software image manipulation, pixel access, and encoding.
---@class LImageData
LImageData = {}

--- Scales every pixel's alpha channel by factor; use to fade an image in or out uniformly.
---@param factor number multiplier for the alpha channel [0.0-1.0].
---@return nil No value is returned.
function LImageData:alphaMask(factor) end

--- Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
---@param lut PaletteLUT Palette lookup table.
---@return nil No value is returned.
function LImageData:applyPaletteLut(lut) end

--- Blits the source ImageData onto this image at (dst_x, dst_y) using Porter-Duff over.
---@param src ImageData Source image data.
---@param dst_x integer Destination X position.
---@param dst_y integer Destination Y position.
---@return nil No value is returned.
function LImageData:blit(src, dst_x, dst_y) end

--- Returns a new ImageData with a box blur applied using the given pixel radius.
---@param radius integer Radius value.
---@return ImageData New ImageData with a box blur applied using the given pixel radius.
function LImageData:blur(radius) end

--- Adjusts the brightness of every pixel by the given factor (< 1.0 darkens, > 1.0 brightens).
---@param factor number Brightness multiplier.
---@return nil No value is returned.
function LImageData:brightness(factor) end

--- Adjusts the contrast of every pixel by the given factor (< 1.0 reduces, > 1.0 increases).
---@param factor number Contrast multiplier.
---@return nil No value is returned.
function LImageData:contrast(factor) end

--- Applies a custom NxN convolution kernel to the image and returns a new ImageData.
---@param kernel table Kernel coefficient table.
---@param ksize integer Kernel size.
---@return ImageData Image data object.
function LImageData:convolve(kernel, ksize) end

--- Returns a new ImageData containing the rectangular sub-region at (x, y) of the given width and height.
---@param x integer X position.
---@param y integer Y position.
---@param w integer Width value.
---@param h integer Height value.
---@return ImageData New ImageData containing the rectangular sub-region at (x, y) of the given width and height.
function LImageData:crop(x, y, w, h) end

--- Returns the sum of absolute per-channel pixel differences with another ImageData.
---@param other ImageData Other input value.
---@return integer Sum of absolute per-channel pixel differences.
function LImageData:diff(other) end

--- Draws a filled circle onto the image.
---@param cx integer Center X position.
---@param cy integer Center Y position.
---@param radius integer Radius value.
---@param r integer Red component.
---@param g integer Green component.
---@param b integer Blue component.
---@param a integer Alpha component.
---@return nil No value is returned.
function LImageData:drawCircle(cx, cy, radius, r, g, b, a) end

--- Draws a line using Bresenham's algorithm.
---@param x0 integer Start X position.
---@param y0 integer Start Y position.
---@param x1 integer End X position.
---@param y1 integer End Y position.
---@param r integer Red component.
---@param g integer Green component.
---@param b integer Blue component.
---@param a integer Alpha component.
---@return nil No value is returned.
function LImageData:drawLine(x0, y0, x1, y1, r, g, b, a) end

--- Draws a filled rectangle onto the image.
---@param x integer X position.
---@param y integer Y position.
---@param w integer Width value.
---@param h integer Height value.
---@param r integer Red component.
---@param g integer Green component.
---@param b integer Blue component.
---@param a integer Alpha component.
---@return nil No value is returned.
function LImageData:drawRect(x, y, w, h, r, g, b, a) end

--- Encodes the image into a byte string in the specified format (currently "png").
---@param format string encoding format; "png" is the only supported value.
---@return string Encoded image bytes as a Lua string.
function LImageData:encode(format) end

--- Fills every pixel with the given solid RGBA colour, overwriting all existing content.
---@param r integer red [0-255].
---@param g integer green [0-255].
---@param b integer blue [0-255].
---@param a integer alpha [0-255].
---@return nil No value is returned.
function LImageData:fill(r, g, b, a) end

--- Flips the image left-to-right (mirror across vertical axis), modifying in place.
---@return nil No value is returned.
function LImageData:flipHorizontal() end

--- Flips the image top-to-bottom (mirror across horizontal axis), modifying in place.
---@return nil No value is returned.
function LImageData:flipVertical() end

--- Applies gamma correction; values < 1.0 brighten shadows, > 1.0 darken them.
---@param gamma number Gamma correction value.
---@return nil No value is returned.
function LImageData:gamma(gamma) end

--- Returns the width and height of the image as two integers.
---@return integer Image width in pixels.
---@return integer Image height in pixels.
function LImageData:getDimensions() end

--- Returns the height of the image in pixels.
---@return integer Image height in pixels.
function LImageData:getHeight() end

--- Returns the RGBA colour components of the pixel at (x, y) as four integers (0-255).
---@param x integer Zero-based pixel x coordinate.
---@param y integer Zero-based pixel y coordinate.
---@return integer Red channel value.
---@return integer Green channel value.
---@return integer Blue channel value.
---@return integer Alpha channel value.
function LImageData:getPixel(x, y) end

--- Returns a copy of the rectangular sub-region as a new ImageData.
---@param x integer X position.
---@param y integer Y position.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return ImageData Copy of the rectangular sub-region as a new ImageData.
function LImageData:getRegion(x, y, width, height) end

--- Returns the raw pixel bytes of the image as a Lua string.
---@return string Raw RGBA pixel bytes.
function LImageData:getString() end

--- Returns the width of the image in pixels.
---@return integer Image width in pixels.
function LImageData:getWidth() end

--- Converts the image to grayscale using luminance weights (BT.601).
---@return nil No value is returned.
function LImageData:grayscale() end

--- Inverts every colour channel (subtracts each R/G/B value from 255); alpha is preserved.
---@return nil No value is returned.
function LImageData:invert() end

--- Calls func(x, y, r, g, b, a) for each pixel and writes the returned RGBA back.
---@param func function Callback that returns replacement RGBA values.
---@return nil No value is returned.
function LImageData:mapPixel(func) end

--- Applies a function to every pixel in-place.
---@param fn function Fn value.
---@return nil No value is returned.
function LImageData:mapPixels(fn) end

--- Adds random noise to every pixel channel; amount controls the maximum per-channel perturbation.
---@param amount integer max perturbation per channel [0-255].
---@return nil No value is returned.
function LImageData:noise(amount) end

--- Copies pixels from `source` onto this image starting at (dx, dy).
---@param source ImageData Source image data.
---@param dx integer Dx value.
---@param dy integer Dy value.
---@return nil No value is returned.
function LImageData:paste(source, dx, dy) end

--- Reduces each channel to `levels` discrete steps, creating a flat poster-paint look.
---@param levels integer number of colour levels per channel [1-255].
---@return nil No value is returned.
function LImageData:posterize(levels) end

--- Returns a bilinear-interpolated copy of the image at the given dimensions.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return ImageData Bilinear-interpolated copy of the image at the given dimensions.
function LImageData:resize(width, height) end

--- Returns a new ImageData scaled to (new_w, new_h) using nearest-neighbour interpolation.
---@param new_w integer New width in pixels.
---@param new_h integer New height in pixels.
---@return ImageData New ImageData scaled to (new_w, new_h) using nearest-neighbour interpolation.
function LImageData:resizeNearest(new_w, new_h) end

--- Returns a new ImageData rotated 90 degrees clockwise; the original is not modified.
---@return ImageData New ImageData rotated 90 degrees clockwise; the original is not modified.
function LImageData:rotate90cw() end

--- Adjusts colour saturation; 0.0 produces grayscale, 1.0 is unchanged, > 1.0 boosts saturation.
---@param factor number Saturation multiplier.
---@return nil No value is returned.
function LImageData:saturation(factor) end

--- Applies a warm sepia tone to the image using standard sepia matrix weights.
---@return nil No value is returned.
function LImageData:sepia() end

--- Sets the RGBA colour of the pixel at (x, y); returns an error if coordinates are out of bounds.
---@param x integer Zero-based pixel x coordinate.
---@param y integer Zero-based pixel y coordinate.
---@param r integer red [0-255].
---@param g integer green [0-255].
---@param b integer blue [0-255].
---@param a integer alpha [0-255].
---@return nil No value is returned.
function LImageData:setPixel(x, y, r, g, b, a) end

--- Replaces all pixel data from a raw RGBA byte string.
---@param bytes string Encoded byte string.
---@return nil No value is returned.
function LImageData:setRawData(bytes) end

--- Returns a new ImageData with a sharpening convolution kernel applied.
---@return ImageData New ImageData with a sharpening convolution kernel applied.
function LImageData:sharpen() end

--- Converts the image to black-and-white: pixels above value become white, at or below become black.
---@param value integer threshold [0-255].
---@return nil No value is returned.
function LImageData:threshold(value) end

--- Blends an RGB tint colour into every pixel, controlled by factor (0.0 = no change, 1.0 = full tint).
---@param tr integer red component [0-255].
---@param tg integer green component [0-255].
---@param tb integer blue component [0-255].
---@param factor number blend weight [0.0-1.0].
---@return nil No value is returned.
function LImageData:tint(tr, tg, tb, factor) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LImageData:type() end

--- Returns true if this object is of the given type name.
---@param name string Name string.
---@return boolean True if the type name matches ImageData.
function LImageData:typeOf(name) end

--- Lua-side wrapper around [`LayeredImage`].
---@class LLayeredImage
LLayeredImage = {}

--- Appends a new blank transparent layer on top and returns its 1-based index.
---@param name? string New image layer name.
---@return integer 1-based index of the new layer.
function LLayeredImage:addLayer(name) end

--- Returns the canvas height shared by all layers.
---@return integer Canvas height in pixels.
function LLayeredImage:getHeight() end

--- Returns a copy of the layer's pixel buffer as an ImageData.
---@param index integer 1-based layer index.
---@return ImageData Image data for the requested layer.
function LLayeredImage:getLayer(index) end

--- Returns the name of a layer.
---@param index integer 1-based layer index.
---@return string Layer name.
function LLayeredImage:getName(index) end

--- Returns the opacity of a layer in [0.0, 1.0].
---@param index integer 1-based layer index.
---@return number Layer opacity in the range [0.0, 1.0].
function LLayeredImage:getOpacity(index) end

--- Returns the canvas width shared by all layers.
---@return integer Canvas width in pixels.
function LLayeredImage:getWidth() end

--- Returns whether a layer is visible.
---@param index integer 1-based layer index.
---@return boolean True if the layer is visible.
function LLayeredImage:isVisible(index) end

--- Returns the number of layers in the stack.
---@return integer Number of layers in the stack.
function LLayeredImage:layerCount() end

--- Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
---@return ImageData Flattened image of all visible layers.
function LLayeredImage:merge() end

--- Moves a layer from one position to another, shifting layers in between.
---@param from_index integer Current 1-based layer index.
---@param to_index integer Target 1-based layer index.
---@return boolean True if the layer was moved.
function LLayeredImage:moveLayer(from_index, to_index) end

--- Removes the layer at the given 1-based index. Returns true on success.
---@param index integer 1-based layer index.
---@return boolean True if the layer was removed.
function LLayeredImage:removeLayer(index) end

--- Saves the layered image to a LIMG binary file at the given path.
---@param path string Output file path relative to the game directory.
---@return nil No value is returned.
function LLayeredImage:save(path) end

--- Replaces a layer's pixel buffer with a copy of the given ImageData.
---@param index integer 1-based layer index.
---@param imagedata ImageData Replacement image data.
---@return boolean True if the layer image was replaced.
function LLayeredImage:setLayer(index, imagedata) end

--- Renames the layer at the given index to the new name string.
---@param index integer 1-based layer index.
---@param name string New image layer name.
---@return boolean True if the layer was renamed.
function LLayeredImage:setName(index, name) end

--- Sets the opacity of a layer. Value is clamped to [0.0, 1.0].
---@param index integer 1-based layer index.
---@param opacity number New layer opacity.
---@return boolean True if the layer opacity was updated.
function LLayeredImage:setOpacity(index, opacity) end

--- Shows or hides a layer during compositing.
---@param index integer 1-based layer index.
---@param visible boolean New layer visibility state.
---@return boolean True if the layer visibility was updated.
function LLayeredImage:setVisible(index, visible) end

--- Swaps two layers by their 1-based indices, changing their compositing order.
---@param a integer First 1-based layer index.
---@param b integer Second 1-based layer index.
---@return boolean True if the two layers were swapped.
function LLayeredImage:swapLayers(a, b) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LLayeredImage:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True if the type name matches LLayeredImage or Object.
function LLayeredImage:typeOf(name) end

--- Lua-side wrapper around [`PaletteLUT`].
---@class LPaletteLUT
LPaletteLUT = {}

--- Removes all colour mapping entries.
---@return nil No value is returned.
function LPaletteLUT:clear() end

--- Returns the number of colour mapping entries.
---@return integer Number of colour mapping entries.
function LPaletteLUT:getColorCount() end

--- Appends a colour mapping entry to the palette: when a pixel exactly matching
---@param from_r integer 0-255.
---@param from_g integer 0-255.
---@param from_b integer 0-255.
---@param from_a integer 0-255  (255 = fully opaque).
---@param to_r integer 0-255.
---@param to_g integer 0-255.
---@param to_b integer 0-255.
---@param to_a integer 0-255.
---@return nil No value is returned.
function LPaletteLUT:setColor(from_r, from_g, from_b, from_a, to_r, to_g, to_b, to_a) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LPaletteLUT:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True if the type name matches LPaletteLUT or Object.
function LPaletteLUT:typeOf(name) end

--- Lua-side wrapper around [`ProvinceGrid`].
---@class LProvinceGrid
LProvinceGrid = {}

--- Returns an array of adjacency records. Each record is {province_a, province_b, border_pixels}.
---@return table Adjacency records between neighboring provinces.
function LProvinceGrid:adjacencies() end

--- Returns the province ID at pixel coordinates (x, y). Returns 0 for background or out-of-bounds.
---@param x integer Zero-based pixel x coordinate.
---@param y integer Zero-based pixel y coordinate.
---@return integer Province ID at the given pixel.
function LProvinceGrid:getAt(x, y) end

--- Returns the grid height in pixels.
---@return integer Grid height in pixels.
function LProvinceGrid:getHeight() end

--- Returns the grid width in pixels.
---@return integer Grid width in pixels.
function LProvinceGrid:getWidth() end

--- Returns the number of unique non-zero province IDs detected in the map.
---@return integer Number of unique non-zero province IDs.
function LProvinceGrid:provinceCount() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LProvinceGrid:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean True if the type name matches LProvinceGrid or Object.
function LProvinceGrid:typeOf(name) end

--- Returns true if the file at the given path is a DDS file.
---@param filename string File path to test.
---@return boolean True if the file is a DDS image.
lurek.image.isCompressed = function(filename) end

--- Loads an ImageData from a LIMG binary file.
---@param path string Input LIMG path relative to the game directory.
---@return ImageData Loaded image data.
lurek.image.loadImage = function(path) end

--- Loads a LayeredImage from a LIMG binary file.
---@param path string Input layered image path relative to the game directory.
---@return LayeredImage Loaded layered image.
lurek.image.loadLayered = function(path) end

--- Loads compressed texture data from a DDS file.
---@param filename string DDS file path relative to the game directory.
---@return CompressedImageData Loaded compressed texture data.
lurek.image.newCompressedData = function(filename) end

--- Creates a new blank ImageData or loads one from a file.
---@param ... integer|integer
---@return ImageData New or loaded image data.
lurek.image.newImageData = function(...) end

--- Creates a new empty LayeredImage canvas with no layers.
---@param width integer Canvas width in pixels.
---@param height integer Canvas height in pixels.
---@return LayeredImage New empty layered image.
lurek.image.newLayeredImage = function(width, height) end

--- Creates a new empty `PaletteLUT` used to remap colours in an image.
---@return PaletteLUT New empty palette lookup table.
lurek.image.newPaletteLut = function() end

--- Loads a province map PNG and builds an O(1) spatial index with adjacency data.
---@param filename string Province map PNG path relative to the game directory.
---@return ProvinceGrid Loaded province grid with adjacency data.
lurek.image.newProvinceGrid = function(filename) end

--- Saves a flat ImageData to a LIMG binary file at the given path.
---@param imagedata ImageData Image data to save.
---@param path string Output file path relative to the game directory.
---@return nil No value is returned.
lurek.image.saveImage = function(imagedata, path) end

--- Saves a flat ImageData as a PNG file at the given path.
---@param imagedata ImageData Image data to save.
---@param path string Output PNG path relative to the game directory.
---@return nil No value is returned.
lurek.image.savePNG = function(imagedata, path) end

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

--- Lua-side wrapper for a [`ComboDetector`] with an integrated millisecond clock.
---@class LCombo
LCombo = {}

--- Feeds a key-press event into the combo detector.
---@param key string Pressed key name.
---@return string Combo state: "idle", "advanced", "completed", or "broken".
function LCombo:feed(key) end

--- Returns the step at the given 1-based index as `{key=..., gap_ms=...}`.
---@param index integer One-based step index.
---@return table Step data table, or nil when the index is out of range.
function LCombo:getStep(index) end

--- Returns true if the detector is currently mid-sequence.
---@return boolean True if a combo is currently in progress.
function LCombo:isInProgress() end

--- Returns the number of steps matched so far (0 when idle).
---@return integer Number of matched steps.
function LCombo:progress() end

--- Reset the detector to its initial idle state, cancelling any in-progress sequence.
---@return nil No value is returned.
function LCombo:reset() end

--- Advances the combo clock and checks for timeouts.
---@param dt number Frame delta in seconds.
---@return string Timeout state: "expired", "in_progress", or "idle".
function LCombo:tick(dt) end

--- Returns the total number of steps in the combo sequence.
---@return integer Total combo step count.
function LCombo:totalSteps() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LCombo:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the given type.
function LCombo:typeOf(name) end

--- Lua-side wrapper around a mouse cursor handle.
---@class LCursor
LCursor = {}

--- Returns the cursor type as "system" or "custom".
---@return string Cursor type name.
function LCursor:getType() end

--- Releases the cursor resource (no-op on desktop).
---@return nil No value is returned.
function LCursor:release() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LCursor:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the given type.
function LCursor:typeOf(name) end

--- Lua userdata wrapper for a completed [`crate::input::recorder::InputRecording`].
---@class LInputRecording
LInputRecording = {}

--- Returns the number of sparse event frames stored in this recording.
---@return integer Number of stored sparse event frames.
function LInputRecording:frameCount() end

--- Serializes this recording to a JSON string for saving to disk.
---@return string Recording JSON data.
function LInputRecording:toJson() end

--- Returns the total frame count when recording was stopped.
---@return integer Total recorded frame count.
function LInputRecording:totalFrames() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LInputRecording:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the given type.
function LInputRecording:typeOf(name) end

--- Advances playback by one frame and returns that frame's input events.
---@return table Array of event tables with `kind` and `name` fields.
lurek.input.advancePlayback = function() end

--- Maps an action name to one or more key or button names.
---@param action string Action name to bind.
---@param keys LuaValue One key name or an array of key names.
---@return nil No value is returned.
lurek.input.bind = function(action, keys) end

--- Removes all action bindings.
---@return nil No value is returned.
lurek.input.clearBindings = function() end

--- Returns the current value (-1 to 1) of a gamepad analog axis.
---@param id integer Gamepad ID.
---@param axis integer Axis index.
---@return number Current axis value.
lurek.input.gamepad.getAxis = function(id, axis) end

--- Returns the total number of analog axes on the gamepad.
---@param id integer Gamepad ID.
---@return integer Total axis count.
lurek.input.gamepad.getAxisCount = function(id) end

--- Returns whether background gamepad events are enabled.
---@return boolean True if background events are enabled.
lurek.input.gamepad.getBackgroundEvents = function() end

--- Returns a table mapping each action name to its bound keys.
---@return table Action-to-bindings map.
lurek.input.getBindings = function() end

--- Returns the total number of buttons on the gamepad.
---@param id integer Gamepad ID.
---@return integer Total button count.
lurek.input.gamepad.getButtonCount = function(id) end

--- Returns the number of connected gamepads.
---@return integer Connected gamepad count.
lurek.input.gamepad.getCount = function() end

--- Returns the name of the currently active system cursor.
---@return string Active system cursor name.
lurek.input.mouse.getCursor = function() end

--- Returns the hardware GUID string of the gamepad.
---@param id integer Gamepad ID.
---@return string Hardware GUID string.
lurek.input.gamepad.getGUID = function(id) end

--- Returns the stored mapping string for the given GUID, or nil.
---@param guid string Controller GUID string.
---@return string Stored mapping string, or nil if no mapping exists.
lurek.input.gamepad.getGamepadMappingString = function(guid) end

--- Returns the direction string of a hat switch on the gamepad.
---@param id integer Gamepad ID.
---@param hat integer Hat switch index.
---@return string Hat direction string.
lurek.input.gamepad.getHat = function(id, hat) end

--- Returns the number of tracked gamepad slots.
---@return integer Tracked gamepad slot count.
lurek.input.gamepad.getJoystickCount = function() end

--- Returns a list of connected gamepad IDs.
---@return table Array of connected gamepad IDs.
lurek.input.gamepad.getJoysticks = function() end

--- Returns the key name for the given hardware scancode.
---@param scancode string Scancode name to resolve.
---@return string Matching key name, or nil if the scancode is unknown.
lurek.input.keyboard.getKeyFromScancode = function(scancode) end

--- Returns the human-readable name of a gamepad.
---@param id integer Gamepad ID.
---@return string Gamepad display name.
lurek.input.gamepad.getName = function(id) end

--- Returns the current playback frame index.
---@return integer Zero-based playback frame index.
lurek.input.getPlaybackFrame = function() end

--- Returns the current cursor position as (x, y).
---@return number Cursor X position.
---@return number Cursor Y position.
lurek.input.mouse.getPosition = function() end

--- Returns the position (x, y) of the touch with the given ID.
---@param id integer Touch identifier.
---@return number Touch X position.
---@return number Touch Y position.
lurek.input.touch.getPosition = function(id) end

--- Returns the pressure (0-1) of the touch with the given ID.
---@param id integer Touch identifier.
---@return number Touch pressure.
lurek.input.touch.getPressure = function(id) end

--- Returns whether relative mouse mode is active.
---@return boolean True if relative mouse mode is active.
lurek.input.mouse.getRelativeMode = function() end

--- Returns the hardware scancode for the given key name.
---@param key string Key name to resolve.
---@return string Matching scancode, or nil if the key is unknown.
lurek.input.keyboard.getScancodeFromKey = function(key) end

--- Returns a system cursor object for the named cursor shape.
---@param name string System cursor shape name.
---@return LCursor System cursor handle.
lurek.input.mouse.getSystemCursor = function(name) end

--- Returns the number of currently active touch points.
---@return integer Active touch count.
lurek.input.touch.getTouchCount = function() end

--- Returns a table of active touch points with id, x, y, and pressure fields.
---@return table Array of active touch point tables.
lurek.input.touch.getTouches = function() end

--- Returns the mouse scroll wheel delta (dx, dy) since last frame.
---@return number Horizontal scroll delta.
---@return number Vertical scroll delta.
lurek.input.mouse.getWheelDelta = function() end

--- Returns the current mouse X position in window coordinates.
---@return number Cursor X position.
lurek.input.mouse.getX = function() end

--- Returns the current mouse Y position in window coordinates.
---@return number Cursor Y position.
lurek.input.mouse.getY = function() end

--- Returns whether key-repeat is currently enabled.
---@return boolean True if key repeat is enabled.
lurek.input.keyboard.hasKeyRepeat = function() end

--- Returns whether text input mode is currently active.
---@return boolean True if text input mode is active.
lurek.input.keyboard.hasTextInput = function() end

--- Returns true if any key bound to the action is currently held down.
---@param action string Action name to test.
---@return boolean True if any bound key is down.
lurek.input.isActionDown = function(action) end

--- Returns whether the gamepad with the given ID is connected.
---@param id integer Gamepad ID.
---@return boolean True if the gamepad is connected.
lurek.input.gamepad.isConnected = function(id) end

--- Returns whether cursor customisation is supported on this platform.
---@return boolean True if cursor customisation is supported.
lurek.input.mouse.isCursorSupported = function() end

--- Returns true if any of the given keys is currently held down.
---@param ... string Key names to test.
---@return boolean True if any listed key is down.
lurek.input.keyboard.isDown = function(...) end

--- Returns whether the given mouse button is currently held down.
---@param button integer One-based mouse button index.
---@return boolean True if the button is down.
lurek.input.mouse.isDown = function(button) end

--- Returns whether the given button on the gamepad is currently held.
---@param id integer Gamepad ID.
---@param button integer Button index.
---@return boolean True if the button is down.
lurek.input.gamepad.isDown = function(id, button) end

--- Returns whether the joystick at the given slot is a recognized gamepad.
---@param id integer Gamepad slot ID.
---@return boolean True if the slot is a recognized gamepad.
lurek.input.gamepad.isGamepad = function(id) end

--- Returns whether the mouse cursor is locked to the window.
---@return boolean True if the cursor is locked.
lurek.input.mouse.isGrabbed = function() end

--- Returns whether the named modifier key is currently held.
---@param modifier string Modifier name to test.
---@return boolean True if the modifier is active.
lurek.input.keyboard.isModifierActive = function(modifier) end

--- Returns true if input playback is currently active.
---@return boolean True if playback is active.
lurek.input.isPlayingBack = function() end

--- Returns true if input recording is currently active.
---@return boolean True if recording is active.
lurek.input.isRecording = function() end

--- Returns whether the key with the given scancode is held.
---@param scancode string Hardware scancode name.
---@return boolean True if the scancode is down.
lurek.input.keyboard.isScancodeDown = function(scancode) end

--- Returns whether the gamepad supports haptic vibration.
---@param id integer Gamepad ID.
---@return boolean Always false on the current backend.
lurek.input.gamepad.isVibrationSupported = function(id) end

--- Returns whether the mouse cursor is currently visible.
---@return boolean True if the cursor is visible.
lurek.input.mouse.isVisible = function() end

--- Loads SDL2 GameControllerDB-format mappings from a file.
---@param path string Source file path.
---@return integer Number of loaded mappings.
lurek.input.gamepad.loadGamepadMappings = function(path) end

--- Loads a JSON-encoded recording string for playback.
---@param json string Recording JSON data.
---@return nil No value is returned.
lurek.input.loadRecording = function(json) end

--- Creates a new combo detector from an ordered list of steps.
---@param steps table Array of key names or `{key, gap}` tables.
---@param opts? table Optional settings table with `total_gap`.
---@return LCombo Created combo detector.
lurek.input.newCombo = function(steps, opts) end

--- Creates a custom mouse cursor from RGBA pixel data.
---@param pixels table RGBA pixel byte data.
---@param width integer Cursor width in pixels.
---@param height integer Cursor height in pixels.
---@param hotx? integer Optional hot-spot X coordinate.
---@param hoty? integer Optional hot-spot Y coordinate.
---@return LCursor Created cursor handle.
lurek.input.mouse.newCursor = function(pixels, width, height, hotx, hoty) end

--- Saves all stored gamepad mappings to a plain-text file.
---@param path string Destination file path.
---@return nil No value is returned.
lurek.input.gamepad.saveGamepadMappings = function(path) end

--- Enable or disable receiving gamepad events when the window is not focused.
---@param enable boolean Whether background events should be enabled.
---@return nil No value is returned.
lurek.input.gamepad.setBackgroundEvents = function(enable) end

--- Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
---@param cursor LuaValue Cursor handle, cursor name, or nil to reset.
---@return nil No value is returned.
lurek.input.mouse.setCursor = function(cursor) end

--- Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
---@param guid string Controller GUID string.
---@param mapping string SDL2 mapping string.
---@return nil No value is returned.
lurek.input.gamepad.setGamepadMapping = function(guid, mapping) end

--- Locks or unlocks the mouse cursor to the window.
---@param grabbed boolean Whether the cursor should be locked.
---@return nil No value is returned.
lurek.input.mouse.setGrabbed = function(grabbed) end

--- Enables or disables key-repeat events.
---@param enabled boolean Whether key repeat should be enabled.
---@return nil No value is returned.
lurek.input.keyboard.setKeyRepeat = function(enabled) end

--- Moves the mouse cursor to the given window-space position.
---@param x number Target X position.
---@param y number Target Y position.
---@return nil No value is returned.
lurek.input.mouse.setPosition = function(x, y) end

--- Enables or disables raw relative mouse motion mode.
---@param relative boolean Whether relative mode should be enabled.
---@return nil No value is returned.
lurek.input.mouse.setRelativeMode = function(relative) end

--- Enables or disables Unicode text input mode.
---@param enabled boolean Whether text input mode should be enabled.
---@return nil No value is returned.
lurek.input.keyboard.setTextInput = function(enabled) end

--- Triggers haptic rumble (currently a no-op stub).
---@param ... LuaValue
---@return boolean Always false on the current backend.
lurek.input.gamepad.setVibration = function(...) end

--- Shows or hides the operating-system mouse cursor.
---@param visible boolean Whether the cursor should be visible.
---@return nil No value is returned.
lurek.input.mouse.setVisible = function(visible) end

--- Starts playback from the beginning of the loaded recording.
---@return nil No value is returned.
lurek.input.startPlayback = function() end

--- Starts capturing input events frame by frame.
---@return nil No value is returned.
lurek.input.startRecording = function() end

--- Stops playback immediately.
---@return nil No value is returned.
lurek.input.stopPlayback = function() end

--- Stops recording and returns the captured recording handle.
---@return LInputRecording Recording handle, or nil if recording was not active.
lurek.input.stopRecording = function() end

--- Removes all key bindings for the given action name.
---@param action string Action name to remove.
---@return boolean True if the action existed.
lurek.input.unbind = function(action) end

--- Requests haptic vibration on a gamepad.
---@param id integer Gamepad ID.
---@param low_freq number Low-frequency motor intensity from 0.0 to 1.0.
---@param high_freq number High-frequency motor intensity from 0.0 to 1.0.
---@param duration_ms number Vibration duration in milliseconds.
---@return boolean Always false on the current backend.
lurek.input.gamepad.vibrate = function(id, low_freq, high_freq, duration_ms) end

--- Returns true if any key bound to the action was pressed this frame.
---@param action string Action name to test.
---@return boolean True if the action was pressed this frame.
lurek.input.wasActionPressed = function(action) end

---@param action LuaValue
---@param frames LuaValue
lurek.input.wasActionPressedWithin = function(action, frames) end

--- Returns true if any key bound to the action was released this frame.
---@param action string Action name to test.
---@return boolean True if the action was released this frame.
lurek.input.wasActionReleased = function(action) end

---@class lurek.light
lurek.light = {}

--- Lua-side handle to a light resource stored in [`LightWorld`].
---@class LLight
LLight = {}

--- Sets a flicker effect from an intensity range and frequency.
---@param min number Lower intensity multiplier.
---@param max number Upper intensity multiplier.
---@param hz number Oscillation frequency in cycles per second.
---@return nil No value is returned.
function LLight:addFlicker(min, max, hz) end

--- Removes the cookie texture assignment.
---@return nil No value is returned.
function LLight:clearCookie() end

--- Returns the custom attenuation coefficients as (constant, linear, quadratic).
---@return number Constant attenuation factor.
---@return number Linear attenuation factor.
---@return number Quadratic attenuation factor.
function LLight:getAttenuation() end

--- Returns the blend mode as a string.
---@return string Blend mode name.
function LLight:getBlendMode() end

--- Returns the light's tint color as (r, g, b, a).
---@return number Red channel.
---@return number Green channel.
---@return number Blue channel.
---@return number Alpha channel.
function LLight:getColor() end

--- Returns the current cookie texture path, or `nil` if unset.
---@return string Cookie texture path, or nil if unset.
function LLight:getCookie() end

--- Returns the direction angle in radians.
---@return number Direction angle in radians.
function LLight:getDirection() end

--- Returns the energy scaling factor.
---@return number Energy scaling factor.
function LLight:getEnergy() end

--- Returns the falloff mode as a string.
---@return string Falloff mode name.
function LLight:getFalloff() end

--- Returns the flicker effect speed and strength.
---@return number Flicker speed.
---@return number Flicker strength.
function LLight:getFlicker() end

--- Returns the group identifier.
---@return integer Group identifier.
function LLight:getGroupId() end

--- Returns the inner cone angle in radians.
---@return number Inner cone angle in radians.
function LLight:getInnerAngle() end

--- Returns the brightness multiplier.
---@return number Intensity multiplier.
function LLight:getIntensity() end

--- Returns the light interaction bitmask.
---@return integer Light interaction bitmask.
function LLight:getLightMask() end

--- Returns the geometric light type as a string.
---@return string Light type name.
function LLight:getLightType() end

--- Returns the outer cone angle in radians.
---@return number Outer cone angle in radians.
function LLight:getOuterAngle() end

--- Returns the light's world-space position.
---@return number World-space X position.
---@return number World-space Y position.
function LLight:getPosition() end

--- Returns the light's influence radius.
---@return number Light radius.
function LLight:getRadius() end

--- Returns the shadow region color as (r, g, b, a).
---@return number Red channel.
---@return number Green channel.
---@return number Blue channel.
---@return number Alpha channel.
function LLight:getShadowColor() end

--- Returns the shadow edge filter as a string.
---@return string Shadow filter name.
function LLight:getShadowFilter() end

--- Returns the shadow casting bitmask.
---@return integer Shadow casting bitmask.
function LLight:getShadowMask() end

--- Returns the shadow edge smoothing factor.
---@return number Shadow smoothing factor.
function LLight:getShadowSmooth() end

--- Returns whether this light is active.
---@return boolean True if the light is active.
function LLight:isEnabled() end

--- Returns whether the flicker effect is active.
---@return boolean True if flicker is enabled.
function LLight:isFlickerEnabled() end

--- Returns whether this light casts shadows.
---@return boolean True if shadows are enabled.
function LLight:isShadowEnabled() end

--- Returns whether this light handle is still valid.
---@return boolean True if the handle is still valid.
function LLight:isValid() end

--- Returns whether this light hints at volumetric scattering.
---@return boolean True if volumetric scattering is enabled.
function LLight:isVolumetric() end

--- Removes this light from the world.
---@return nil No value is returned.
function LLight:remove() end

--- Sets the custom attenuation coefficients (constant, linear, quadratic).
---@param c number Constant attenuation factor.
---@param l number Linear attenuation factor.
---@param q number Quadratic attenuation factor.
---@return nil No value is returned.
function LLight:setAttenuation(c, l, q) end

--- Sets the blend mode ('add', 'sub', or 'mix').
---@param mode string Blend mode name.
---@return nil No value is returned.
function LLight:setBlendMode(mode) end

--- Sets the light's tint color.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a? number Optional alpha channel.
---@return nil No value is returned.
function LLight:setColor(r, g, b, a) end

--- Sets the texture path used as a light cookie for projection.
---@param path string Cookie texture path.
---@return nil No value is returned.
function LLight:setCookie(path) end

--- Sets the direction angle in radians.
---@param dir number Direction angle in radians.
---@return nil No value is returned.
function LLight:setDirection(dir) end

--- Sets whether this light is active.
---@param enabled boolean Whether the light should be active.
---@return nil No value is returned.
function LLight:setEnabled(enabled) end

--- Sets the energy scaling factor.
---@param e number Energy scaling factor.
---@return nil No value is returned.
function LLight:setEnergy(e) end

--- Sets the falloff mode ('linear', 'smooth', or 'constant').
---@param mode string Falloff mode name.
---@return nil No value is returned.
function LLight:setFalloff(mode) end

--- Sets the flicker effect speed and strength (enables flicker).
---@param speed number Flicker speed.
---@param strength number Flicker strength.
---@return nil No value is returned.
function LLight:setFlicker(speed, strength) end

--- Sets whether the flicker effect is active.
---@param enabled boolean Whether flicker should be enabled.
---@return nil No value is returned.
function LLight:setFlickerEnabled(enabled) end

--- Sets the group identifier for batch operations.
---@param id integer Group identifier.
---@return nil No value is returned.
function LLight:setGroupId(id) end

--- Sets the inner cone angle in radians for spot lights.
---@param angle number Inner cone angle in radians.
---@return nil No value is returned.
function LLight:setInnerAngle(angle) end

--- Sets the brightness multiplier.
---@param i number Intensity multiplier.
---@return nil No value is returned.
function LLight:setIntensity(i) end

--- Sets the light interaction bitmask.
---@param mask integer Light interaction bitmask.
---@return nil No value is returned.
function LLight:setLightMask(mask) end

--- Sets the geometric light type ('point', 'directional', or 'spot').
---@param t string Light type name.
---@return nil No value is returned.
function LLight:setLightType(t) end

--- Sets the outer cone angle in radians for spot lights.
---@param angle number Outer cone angle in radians.
---@return nil No value is returned.
function LLight:setOuterAngle(angle) end

--- Sets the light's world-space position.
---@param x number World-space X position.
---@param y number World-space Y position.
---@return nil No value is returned.
function LLight:setPosition(x, y) end

--- Sets the light's influence radius.
---@param r number Light radius.
---@return nil No value is returned.
function LLight:setRadius(r) end

--- Sets the shadow region color.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a? number Optional alpha channel.
---@return nil No value is returned.
function LLight:setShadowColor(r, g, b, a) end

--- Sets whether this light casts shadows.
---@param enabled boolean Whether shadows should be enabled.
---@return nil No value is returned.
function LLight:setShadowEnabled(enabled) end

--- Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
---@param filter string Shadow filter name.
---@return nil No value is returned.
function LLight:setShadowFilter(filter) end

--- Sets the shadow casting bitmask.
---@param mask integer Shadow casting bitmask.
---@return nil No value is returned.
function LLight:setShadowMask(mask) end

--- Sets the shadow edge smoothing factor.
---@param smooth number Shadow smoothing factor.
---@return nil No value is returned.
function LLight:setShadowSmooth(smooth) end

--- Sets whether this light hints at volumetric scattering.
---@param enabled boolean Whether volumetric scattering should be enabled.
---@return nil No value is returned.
function LLight:setVolumetric(enabled) end

--- Cancels the active light transition.
---@return nil No value is returned.
function LLight:stopTransition() end

--- Returns the fractional progress of the active transition.
---@return number Transition progress from 0 to 1.
function LLight:transitionProgress() end

--- Starts a smooth transition toward the target light properties.
---@param target table Target fields such as `color`, `intensity`, and `radius`.
---@param duration number Transition duration in seconds.
---@return nil No value is returned.
function LLight:transitionTo(target, duration) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LLight:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the given type.
function LLight:typeOf(name) end

--- Advances the active transition and applies interpolated values.
---@param dt number Frame delta in seconds.
---@return boolean True while the transition is still running.
function LLight:updateTransition(dt) end

--- Lua-side handle to an occluder resource stored in [`LightWorld`].
---@class LOccluder
LOccluder = {}

--- Returns the light interaction bitmask.
---@return integer Light interaction bitmask.
function LOccluder:getLightMask() end

--- Returns the shadow opacity.
---@return number Shadow opacity.
function LOccluder:getOpacity() end

--- Returns the translation offset as (x, y).
---@return number Translation X offset.
---@return number Translation Y offset.
function LOccluder:getPosition() end

--- Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
---@return table Flat vertex coordinate table.
function LOccluder:getVertices() end

--- Returns whether this occluder is active.
---@return boolean True if the occluder is active.
function LOccluder:isEnabled() end

--- Returns whether this occluder handle is still valid.
---@return boolean True if the handle is still valid.
function LOccluder:isValid() end

--- Removes this occluder from the world.
---@return nil No value is returned.
function LOccluder:remove() end

--- Sets whether this occluder is active.
---@param enabled boolean Whether the occluder should be active.
---@return nil No value is returned.
function LOccluder:setEnabled(enabled) end

--- Sets the light interaction bitmask.
---@param mask integer Light interaction bitmask.
---@return nil No value is returned.
function LOccluder:setLightMask(mask) end

--- Sets the shadow opacity (0.0-1.0).
---@param opacity number Shadow opacity from 0.0 to 1.0.
---@return nil No value is returned.
function LOccluder:setOpacity(opacity) end

--- Sets the translation offset applied to all vertices.
---@param x number World-space X offset.
---@param y number World-space Y offset.
---@return nil No value is returned.
function LOccluder:setPosition(x, y) end

--- Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
---@param vertices table Flat vertex coordinate table.
---@return nil No value is returned.
function LOccluder:setVertices(vertices) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LOccluder:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the given type.
function LOccluder:typeOf(name) end

--- Advances flicker phase for all lights with flicker enabled.
---@param dt number Frame delta in seconds.
---@return nil No value is returned.
lurek.light.advanceFlickers = function(dt) end

--- Removes all lights and occluders, resets ambient to default.
---@return nil No value is returned.
lurek.light.clear = function() end

--- Returns the global ambient light color as (r, g, b, a).
---@return number Ambient red component.
---@return number Ambient green component.
---@return number Ambient blue component.
---@return number Ambient alpha component.
lurek.light.getAmbient = function() end

--- Returns directional light hints for god-ray rendering.
---@return table Array of `{x, y, angle}` hint tables.
lurek.light.getGodRayHints = function() end

--- Returns the number of lights in the given group.
---@param groupId integer Group identifier.
---@return integer Number of lights in the group.
lurek.light.getGroupCount = function(groupId) end

--- Returns the number of lights in the world.
---@return integer Light count.
lurek.light.getLightCount = function() end

--- Returns the maximum number of lights processed per frame.
---@return integer Maximum per-frame light count.
lurek.light.getMaxLights = function() end

--- Returns the number of occluders in the world.
---@return integer Occluder count.
lurek.light.getOccluderCount = function() end

--- Returns whether the lighting system is active.
---@return boolean True if the lighting system is active.
lurek.light.isEnabled = function() end

--- Creates a new light at (x, y) with the given radius and optional settings.
---@param x number World-space X position.
---@param y number World-space Y position.
---@param radius number Light radius.
---@param opts? table Optional light settings table.
---@return LLight Created light handle.
lurek.light.newLight = function(x, y, radius, opts) end

--- Creates a new shadow occluder from a vertex table and optional settings.
---@param vertices table Flat vertex coordinate table.
---@param opts? table Optional occluder settings table.
---@return LOccluder Created occluder handle.
lurek.light.newOccluder = function(vertices, opts) end

--- Sets the global ambient light color.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a? number Optional alpha channel.
---@return nil No value is returned.
lurek.light.setAmbient = function(r, g, b, a) end

--- Sets whether the lighting system is active.
---@param enabled boolean Whether the lighting system should be active.
---@return nil No value is returned.
lurek.light.setEnabled = function(enabled) end

--- Sets the color for all lights in the given group.
---@param groupId integer Group identifier.
---@param r number Red channel.
---@param g number Green channel.
---@param b number Blue channel.
---@param a? number Optional alpha channel.
---@return nil No value is returned.
lurek.light.setGroupColor = function(groupId, r, g, b, a) end

--- Sets the enabled state for all lights in the given group.
---@param groupId integer Group identifier.
---@param enabled boolean Whether the group should be enabled.
---@return nil No value is returned.
lurek.light.setGroupEnabled = function(groupId, enabled) end

--- Sets the intensity for all lights in the given group.
---@param groupId integer Group identifier.
---@param intensity number Group intensity multiplier.
---@return nil No value is returned.
lurek.light.setGroupIntensity = function(groupId, intensity) end

--- Sets the maximum number of lights processed per frame (clamped 1-256).
---@param n integer Requested per-frame light limit.
---@return nil No value is returned.
lurek.light.setMaxLights = function(n) end

--- Returns the current ambient light color snapshot.
---@return number Ambient red component snapshot.
---@return number Ambient green component snapshot.
---@return number Ambient blue component snapshot.
---@return number Ambient alpha component snapshot.
lurek.light.syncAmbient = function() end

---@class lurek.log
lurek.log = {}

--- Creates and registers a new log output sink from the given configuration table.
---@param config table Configuration table with keys: type (string), level (string), path (string, for file/rotating), capacity (integer, for memory), max_bytes (integer, for rotating), keep_files (integer, for rotating)
---@return integer The unique identifier of the newly created sink
lurek.log.addSink = function(config) end

--- Removes every registered log sink, returning the logging system to its default state where messages go only to the engine log backend (stderr).
---@return nil No return value.
lurek.log.clearSinks = function() end

--- Emits a message at debug severity to the engine log and all registered sinks.
---@param message string The text content of the log message
---@param tag? string Optional category tag (defaults to "Lua" when omitted)
---@return nil No return value.
lurek.log.debug = function(message, tag) end

--- Emits a structured log message at debug severity with key-value metadata.
---@param message string The human-readable log message
---@param fields_table table Key-value pairs of metadata (string keys, any values)
---@return nil No return value.
lurek.log.debug_fields = function(message, fields_table) end

--- Emits a message at error severity to the engine log and all registered sinks.
---@param message string The text content of the error message
---@param tag? string Optional category tag (defaults to "Lua" when omitted)
---@return nil No return value.
lurek.log.error = function(message, tag) end

--- Emits a structured log message at error severity with key-value metadata.
---@param message string The human-readable error message
---@param fields_table table Key-value pairs of metadata (string keys, any values)
---@return nil No return value.
lurek.log.error_fields = function(message, fields_table) end

--- Forces the operating system to write any buffered data for a file-type sink to disk.
---@param id integer The file sink identifier returned by addSink
---@return nil No return value.
lurek.log.flushFile = function(id) end

--- Returns the name of the current global minimum severity threshold as a lowercase string (e.g.
---@return string The active log level name
lurek.log.getLevel = function() end

--- Emits a message at info severity to the engine log and all registered sinks.
---@param message string The text content of the log message
---@param tag? string Optional category tag (defaults to "Lua" when omitted)
---@return nil No return value.
lurek.log.info = function(message, tag) end

--- Emits a structured log message at info severity with key-value metadata.
---@param message string The human-readable log message
---@param fields_table table Key-value pairs of metadata (string keys, any values)
---@return nil No return value.
lurek.log.info_fields = function(message, fields_table) end

--- Returns an array-like table where each entry is a table describing one registered sink.
---@return table Array of sink descriptor tables
lurek.log.listSinks = function() end

--- Emits a log message at an arbitrary severity level specified as a string.
---@param level string Severity name: "debug", "info", "warn", "error", or "trace"
---@param message string The text content of the log message
---@param tag? string Optional category tag (defaults to "Lua" when omitted)
---@return nil No return value.
lurek.log.print = function(level, message, tag) end

--- Reads log entries stored in a memory-type sink.
---@param id integer The memory sink identifier returned by addSink
---@param drain? boolean When true, clears read entries from the buffer (default false)
---@return table Array of log entry tables
lurek.log.readMemory = function(id, drain) end

--- Removes a previously registered log sink by its numeric identifier.
---@param id integer The sink identifier returned by addSink
---@return boolean True if the sink existed and was removed
lurek.log.removeSink = function(id) end

--- Sets the global minimum severity threshold for the engine log backend.
---@param level string One of "error", "warn", "info", "debug", "trace", or "off"
---@return nil No return value.
lurek.log.setLevel = function(level) end

--- Emits a structured log message that includes arbitrary key-value metadata alongside the human-readable text.
---@param level string Severity name: "debug", "info", "warn", or "error"
---@param message string The human-readable log message
---@param fields_table table Key-value pairs of metadata (string keys, any values)
---@return nil No return value.
lurek.log.struct = function(level, message, fields_table) end

--- Emits a message at warning severity to the engine log and all registered sinks.
---@param message string The text content of the warning message
---@param tag? string Optional category tag (defaults to "Lua" when omitted)
---@return nil No return value.
lurek.log.warn = function(message, tag) end

--- Emits a structured log message at warning severity with key-value metadata.
---@param message string The human-readable warning message
---@param fields_table table Key-value pairs of metadata (string keys, any values)
---@return nil No return value.
lurek.log.warn_fields = function(message, fields_table) end

---@class lurek.math
---@field pi number  π ≈ 3.14159265358979
---@field tau number  τ = 2π ≈ 6.28318530717959
lurek.math = {}

--- Lua-side wrapper around an [`AabbTree`].
---@class LAabbTree
LAabbTree = {}

--- Removes all entries from the tree.
---@return nil No value is returned.
function LAabbTree:clear() end

--- Returns true if an entry with the given id exists in the tree.
---@param id integer Entry identifier.
---@return boolean True when the entry exists.
function LAabbTree:contains(id) end

--- Inserts an entry with the given AABB into the tree.
---@param id integer Entry identifier.
---@param min_x number Minimum x coordinate.
---@param min_y number Minimum y coordinate.
---@param max_x number Maximum x coordinate.
---@param max_y number Maximum y coordinate.
---@return nil No value is returned.
function LAabbTree:insert(id, min_x, min_y, max_x, max_y) end

--- Returns true if the tree contains no entries.
---@return boolean True when the tree is empty.
function LAabbTree:isEmpty() end

--- Returns the number of entries in the tree.
---@return integer Entry count.
function LAabbTree:len() end

--- Returns the ids of all entries whose AABBs overlap the query rectangle.
---@param min_x number Query minimum x coordinate.
---@param min_y number Query minimum y coordinate.
---@param max_x number Query maximum x coordinate.
---@param max_y number Query maximum y coordinate.
---@return table Matching entry IDs.
function LAabbTree:query(min_x, min_y, max_x, max_y) end

--- Returns the ids of all entries whose AABBs contain the given point.
---@param x number Point x coordinate.
---@param y number Point y coordinate.
---@return table Matching entry IDs.
function LAabbTree:queryPoint(x, y) end

--- Removes the entry with the given id.
---@param id integer Entry identifier.
---@return boolean True when the entry was removed.
function LAabbTree:remove(id) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LAabbTree:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LAabbTree:typeOf(name) end

--- Updates the AABB for an existing entry.
---@param id integer Entry identifier.
---@param min_x number Minimum x coordinate.
---@param min_y number Minimum y coordinate.
---@param max_x number Maximum x coordinate.
---@param max_y number Maximum y coordinate.
---@return boolean True when the entry was updated.
function LAabbTree:update(id, min_x, min_y, max_x, max_y) end

--- Lua-side wrapper around a [`BezierCurve`].
---@class LBezierCurve
LBezierCurve = {}

--- Evaluates the curve at parameter t, returning (x, y).
---@param t number Curve parameter.
---@return number Evaluated X coordinate.
---@return number Evaluated Y coordinate.
function LBezierCurve:evaluate(t) end

--- Returns the control point at 1-based index as (x, y), or nil.
---@param index integer One-based control point index.
---@return number Control point X coordinate.
---@return number Control point Y coordinate.
function LBezierCurve:getControlPoint(index) end

--- Returns the number of control points.
---@return integer Control point count.
function LBezierCurve:getControlPointCount() end

--- Returns a new BezierCurve representing the first derivative.
---@return LBezierCurve First-derivative curve.
function LBezierCurve:getDerivative() end

--- Inserts a control point. If index is given (1-based), inserts at that position.
---@param x number Control point x coordinate.
---@param y number Control point y coordinate.
---@param index? integer Optional one-based insertion index.
---@return nil No value is returned.
function LBezierCurve:insertControlPoint(x, y, index) end

--- Returns the approximate arc length of the curve.
---@return number Approximate arc length.
function LBezierCurve:length() end

--- Removes a control point at 1-based index.
---@param index integer One-based control point index.
---@return boolean True when the control point was removed.
function LBezierCurve:removeControlPoint(index) end

--- Renders the curve as a polyline with the given number of segments.
---@param segments integer Number of polyline segments.
---@return table Rendered points as `{x, y}` arrays.
function LBezierCurve:render(segments) end

--- Rotates all control points around a pivot by angle radians.
---@param angle number Rotation angle in radians.
---@param ox number Pivot x coordinate.
---@param oy number Pivot y coordinate.
---@return nil No value is returned.
function LBezierCurve:rotate(angle, ox, oy) end

--- Scales all control points around a pivot by factor s.
---@param s number Scale factor.
---@param ox number Pivot x coordinate.
---@param oy number Pivot y coordinate.
---@return nil No value is returned.
function LBezierCurve:scale(s, ox, oy) end

--- Sets the control point at 1-based index.
---@param index integer One-based control point index.
---@param x number Control point x coordinate.
---@param y number Control point y coordinate.
---@return boolean True when the control point was updated.
function LBezierCurve:setControlPoint(index, x, y) end

--- Translates all control points by (dx, dy).
---@param dx number Horizontal offset.
---@param dy number Vertical offset.
---@return nil No value is returned.
function LBezierCurve:translate(dx, dy) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LBezierCurve:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LBezierCurve:typeOf(name) end

--- Lua-side wrapper around a [`CatmullRomSpline`].
---@class LCatmullRom
LCatmullRom = {}

--- Appends a control point to the spline.
---@param x number Control point x coordinate.
---@param y number Control point y coordinate.
---@return nil No value is returned.
function LCatmullRom:addPoint(x, y) end

--- Number of control points.
---@return integer Control point count.
function LCatmullRom:len() end

--- Removes the control point at `index` (0-based) and returns it.
---@param index integer Zero-based control point index.
---@return number Removed point X coordinate.
---@return number Removed point Y coordinate.
function LCatmullRom:removePoint(index) end

--- Samples the spline at global parameter `t` in `[0, 1]`.
---@param t number Spline parameter.
---@return number X coordinate at the sampled point.
---@return number Y coordinate at the sampled point.
function LCatmullRom:sample(t) end

--- Samples one segment at local parameter `t` in `[0, 1]`.
---@param seg integer Segment index.
---@param t number Segment-local parameter.
---@return number X coordinate at the sampled point.
---@return number Y coordinate at the sampled point.
function LCatmullRom:sampleSegment(seg, t) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LCatmullRom:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LCatmullRom:typeOf(name) end

--- Lua-side wrapper around a [`Circle`].
---@class LCircle
LCircle = {}

--- Returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y).
---@return number Minimum X coordinate.
---@return number Minimum Y coordinate.
---@return number Maximum X coordinate.
---@return number Maximum Y coordinate.
function LCircle:aabb() end

--- Returns the area of the circle (π r²).
---@return number Circle area.
function LCircle:area() end

--- Returns true if the point (px, py) lies inside or on the boundary.
---@param px number Point x coordinate.
---@param py number Point y coordinate.
---@return boolean True when the point lies inside or on the circle.
function LCircle:contains(px, py) end

--- Returns true if this circle overlaps another circle.
---@param other LCircle Circle to test against.
---@return boolean True when the circles overlap.
function LCircle:intersects(other) end

--- Returns the circumference of the circle (2 π r).
---@return number Circle perimeter.
function LCircle:perimeter() end

--- Returns the circle radius.
---@return number Circle radius.
function LCircle:radius() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LCircle:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LCircle:typeOf(name) end

--- Returns the circle centre X.
---@return number Circle center x coordinate.
function LCircle:x() end

--- Returns the circle centre Y.
---@return number Circle center y coordinate.
function LCircle:y() end

--- Lua-side wrapper around a [`HermiteSpline`].
---@class LHermite
LHermite = {}

--- Samples the spline at parameter `t` in `[0, 1]`.
---@param t number Spline parameter.
---@return number X coordinate at the sampled point.
---@return number Y coordinate at the sampled point.
function LHermite:sample(t) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LHermite:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LHermite:typeOf(name) end

--- Lua-side wrapper around a [`NoiseGenerator`].
---@class LNoiseGenerator
LNoiseGenerator = {}

--- Returns fractal Brownian motion noise at (x, y).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param octaves? integer Optional octave count.
---@param lacunarity? number Optional lacunarity value.
---@param persistence? number Optional persistence value.
---@param kind? string Optional base noise kind.
---@return number Noise value.
function LNoiseGenerator:fbm(x, y, octaves, lacunarity, persistence, kind) end

--- Generates a 2D noise map as a flat table (row-major).
---@param width integer Map width.
---@param height integer Map height.
---@param opts? table Optional generation settings.
---@return table Flat row-major noise values.
function LNoiseGenerator:generateMap(width, height, opts) end

--- Returns the current seed.
---@return integer Current seed value.
function LNoiseGenerator:getSeed() end

--- Returns 1D Perlin noise at x.
---@param x number Sample x coordinate.
---@return number Noise value.
function LNoiseGenerator:perlin1d(x) end

--- Returns 2D Perlin noise at (x, y).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@return number Noise value.
function LNoiseGenerator:perlin2d(x, y) end

--- Returns 3D Perlin noise at (x, y, z).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param z number Sample z coordinate.
---@return number Noise value.
function LNoiseGenerator:perlin3d(x, y, z) end

--- Returns 4D Perlin noise at (x, y, z, w).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param z number Sample z coordinate.
---@param w number Sample w coordinate.
---@return number Noise value.
function LNoiseGenerator:perlin4d(x, y, z, w) end

--- Returns ridged multi-fractal noise at (x, y).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param octaves? integer Optional octave count.
---@param lacunarity? number Optional lacunarity value.
---@param persistence? number Optional persistence value.
---@param kind? string Optional base noise kind.
---@return number Noise value.
function LNoiseGenerator:ridged(x, y, octaves, lacunarity, persistence, kind) end

--- Sets the seed and rebuilds the permutation table.
---@param seed integer Seed value to apply.
---@return nil No value is returned.
function LNoiseGenerator:setSeed(seed) end

--- Returns 1D Simplex noise at x.
---@param x number Sample x coordinate.
---@return number Noise value.
function LNoiseGenerator:simplex1d(x) end

--- Returns 2D Simplex noise at (x, y).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@return number Noise value.
function LNoiseGenerator:simplex2d(x, y) end

--- Returns 3D Simplex noise at (x, y, z).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param z number Sample z coordinate.
---@return number Noise value.
function LNoiseGenerator:simplex3d(x, y, z) end

--- Returns turbulence noise at (x, y).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param octaves? integer Optional octave count.
---@param lacunarity? number Optional lacunarity value.
---@param persistence? number Optional persistence value.
---@param kind? string Optional base noise kind.
---@return number Noise value.
function LNoiseGenerator:turbulence(x, y, octaves, lacunarity, persistence, kind) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LNoiseGenerator:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LNoiseGenerator:typeOf(name) end

--- Applies domain warping, returning offset (x, y).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param strength number Warp strength.
---@return number Warped X coordinate.
---@return number Warped Y coordinate.
function LNoiseGenerator:warpDomain(x, y, strength) end

--- Returns 2D Worley (cellular) noise at (x, y).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param distType? string Optional distance metric name.
---@param f2? boolean Optional second-feature toggle.
---@return number Noise value.
function LNoiseGenerator:worley2d(x, y, distType, f2) end

--- Returns 3D Worley (cellular) noise at (x, y, z).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param z number Sample z coordinate.
---@param distType? string Optional distance metric name.
---@param f2? boolean Optional second-feature toggle.
---@return number Noise value.
function LNoiseGenerator:worley3d(x, y, z, distType, f2) end

--- Lua-side wrapper around a [`RandomGenerator`].
---@class LRandomGenerator
LRandomGenerator = {}

--- Returns the seed used to initialise this generator.
---@return integer Current seed value.
function LRandomGenerator:getSeed() end

--- Serialises the generator state as a string for later restoration.
---@return string Serialized generator state.
function LRandomGenerator:getState() end

--- Returns a uniform random number in [0, 1).
---@return number Random value.
function LRandomGenerator:random() end

--- Returns a uniform random float in [min, max).
---@param min number Lower bound.
---@param max number Upper bound.
---@return number Random value in the range.
function LRandomGenerator:randomFloat(min, max) end

--- Returns a uniform random integer in [min, max].
---@param min integer Lower bound.
---@param max integer Upper bound.
---@return integer Random integer in the range.
function LRandomGenerator:randomInt(min, max) end

--- Returns a random number from a normal (Gaussian) distribution.
---@param stddev? number Standard deviation override.
---@param mean? number Mean override.
---@return number Random value from the distribution.
function LRandomGenerator:randomNormal(stddev, mean) end

--- Sets the seed, fully resetting the generator state.
---@param seed integer Seed value to apply.
---@return nil No value is returned.
function LRandomGenerator:setSeed(seed) end

--- Restores the generator state from a previously serialised string.
---@param state string Serialized generator state.
---@return nil No value is returned.
function LRandomGenerator:setState(state) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LRandomGenerator:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LRandomGenerator:typeOf(name) end

--- Lua-side wrapper around a [`SpatialHash`].
---@class LSpatialHash
LSpatialHash = {}

--- Removes all registered items from this spatial hash, leaving it empty.
---@return nil No value is returned.
function LSpatialHash:clear() end

--- Returns the cell size used to partition the spatial hash grid.
---@return number Spatial hash cell size.
function LSpatialHash:getCellSize() end

--- Returns the number of items in the hash.
---@return integer Number of stored items.
function LSpatialHash:getItemCount() end

--- Inserts an item with the given AABB.
---@param id string Item identifier.
---@param x number AABB x coordinate.
---@param y number AABB y coordinate.
---@param w number AABB width.
---@param h number AABB height.
---@return nil No value is returned.
function LSpatialHash:insert(id, x, y, w, h) end

--- Returns IDs of items overlapping the query circle.
---@param cx number Circle center x coordinate.
---@param cy number Circle center y coordinate.
---@param radius number Circle radius.
---@return table Matching item IDs.
function LSpatialHash:queryCircle(cx, cy, radius) end

--- Returns IDs of items overlapping the query rectangle.
---@param x number Query rectangle x coordinate.
---@param y number Query rectangle y coordinate.
---@param w number Query rectangle width.
---@param h number Query rectangle height.
---@return table Matching item IDs.
function LSpatialHash:queryRect(x, y, w, h) end

--- Returns IDs of items whose AABBs are intersected by the line segment.
---@param x1 number Segment start x coordinate.
---@param y1 number Segment start y coordinate.
---@param x2 number Segment end x coordinate.
---@param y2 number Segment end y coordinate.
---@return table Matching item IDs.
function LSpatialHash:querySegment(x1, y1, x2, y2) end

--- Removes an item by its ID.
---@param id string Item identifier.
---@return nil No value is returned.
function LSpatialHash:remove(id) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LSpatialHash:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LSpatialHash:typeOf(name) end

--- Updates an existing item's AABB.
---@param id string Item identifier.
---@param x number AABB x coordinate.
---@param y number AABB y coordinate.
---@param w number AABB width.
---@param h number AABB height.
---@return nil No value is returned.
function LSpatialHash:update(id, x, y, w, h) end

--- Lua-side wrapper around a [`Transform`].
---@class LTransform
LTransform = {}

--- Returns a copy of this transform.
---@return LTransform Copy of this transform.
function LTransform:clone() end

--- Decomposes this transform into translation, rotation, and scale.
---@return number Translation X component.
---@return number Translation Y component.
---@return number Rotation angle.
---@return number Scale X component.
---@return number Scale Y component.
function LTransform:decompose() end

--- Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
---@return table Row-major 3x3 matrix values.
function LTransform:getMatrix() end

--- Returns a new Transform that undoes this transform.
---@return LTransform Inverse transform.
function LTransform:inverse() end

--- Transforms a point from world space back to local space.
---@param x number World-space x coordinate.
---@param y number World-space y coordinate.
---@return number Local-space X coordinate.
---@return number Local-space Y coordinate.
function LTransform:inverseTransformPoint(x, y) end

--- Resets the transform to identity.
---@return nil No value is returned.
function LTransform:reset() end

--- Applies a rotation in radians.
---@param angle number Rotation angle in radians.
---@return nil No value is returned.
function LTransform:rotate(angle) end

--- Applies non-uniform scaling.
---@param sx number Horizontal scale factor.
---@param sy? number Vertical scale factor.
---@return nil No value is returned.
function LTransform:scale(sx, sy) end

--- Replaces the transform with full transformation parameters.
---@param x number Translation x value.
---@param y number Translation y value.
---@param angle? number Rotation angle in radians.
---@param sx? number Horizontal scale factor.
---@param sy? number Vertical scale factor.
---@param ox? number Origin x value.
---@param oy? number Origin y value.
---@param kx? number Horizontal shear factor.
---@param ky? number Vertical shear factor.
---@return nil No value is returned.
function LTransform:setTransformation(x, y, angle, sx, sy, ox, oy, kx, ky) end

--- Applies horizontal and vertical shear factors to this transform matrix.
---@param kx number Horizontal shear factor.
---@param ky number Vertical shear factor.
---@return nil No value is returned.
function LTransform:shear(kx, ky) end

--- Transforms a point from local space to world space.
---@param x number Local-space x coordinate.
---@param y number Local-space y coordinate.
---@return number World-space X coordinate.
---@return number World-space Y coordinate.
function LTransform:transformPoint(x, y) end

--- Applies translation to the transform.
---@param dx number Horizontal offset.
---@param dy number Vertical offset.
---@return nil No value is returned.
function LTransform:translate(dx, dy) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LTransform:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LTransform:typeOf(name) end

--- Lua-side wrapper around a [`Tween`].
---@class LTween
LTween = {}

--- Adds a start/target value pair. Returns the 1-based index.
---@param start number Start value.
---@param target number Target value.
---@return integer One-based value index.
function LTween:addValue(start, target) end

--- Returns all interpolated values as a table.
---@return table All tween values.
function LTween:getAllValues() end

--- Alias for getTime(). Returns the current clock time.
---@return number Current tween time.
function LTween:getClock() end

--- Returns the tween duration in seconds.
---@return number Tween duration.
function LTween:getDuration() end

--- Returns the easing function name.
---@return string Easing function name.
function LTween:getEasingName() end

--- Returns the current clock time.
---@return number Current tween time.
function LTween:getTime() end

--- Returns the interpolated value at 1-based index, or all values when no index is given.
---@param index? integer Optional one-based value index.
---@return number Value at the given index, or a table when no index is given.
function LTween:getValue(index) end

--- Returns the number of values in this tween.
---@return integer Number of tweened values.
function LTween:getValueCount() end

--- Returns true if the tween has finished.
---@return boolean True when the tween is complete.
function LTween:isComplete() end

--- Resets the tween elapsed time to zero, restarting the animation.
---@return nil No value is returned.
function LTween:reset() end

--- Alias for setTime(). Sets the clock to t, clamped to [0, duration].
---@param t number New tween time.
---@return nil No value is returned.
function LTween:set(t) end

--- Sets the clock to a specific time, clamped to [0, duration].
---@param t number New tween time.
---@return nil No value is returned.
function LTween:setTime(t) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LTween:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LTween:typeOf(name) end

--- Advances the clock by dt seconds. Returns true when complete.
---@param dt number Time step in seconds.
---@return boolean True when the tween is complete.
function LTween:update(dt) end

--- Lua-side wrapper around a [`Vec2`] value type.
---@class LVec2
---@field x number  x component
---@field y number  y component
LVec2 = {}

--- Returns the angle of this vector in radians (atan2(y, x)).
---@return number Vector angle in radians.
function LVec2:angle() end

--- Returns the 2D cross product (scalar) with another vector.
---@param other LVec2 Vector to cross against this vector.
---@return number Scalar cross product result.
function LVec2:cross(other) end

--- Returns the Euclidean distance from this vector to another.
---@param other LVec2 Vector to measure against.
---@return number Distance between the vectors.
function LVec2:distance(other) end

--- Returns the dot product with another vector.
---@param other LVec2 Vector to dot against this vector.
---@return number Dot product result.
function LVec2:dot(other) end

--- Creates a unit vector from an angle in radians.
---@param radians number Angle in radians.
---@return LVec2 Unit vector for the angle.
LVec2.fromAngle = function(radians) end

--- Returns the Euclidean length of the vector.
---@return number Vector length.
function LVec2:length() end

--- Returns the squared length of the vector (faster than length).
---@return number Squared vector length.
function LVec2:lengthSquared() end

--- Returns a linearly interpolated vector between this and other at parameter t.
---@param other LVec2 Target vector.
---@param t number Interpolation factor.
---@return LVec2 Interpolated vector.
function LVec2:lerp(other, t) end

--- Returns a unit-length copy of this vector. Returns zero if length is zero.
---@return LVec2 Normalized vector.
function LVec2:normalize() end

--- Compatibility alias for `normalize`.
---@return LVec2 Normalized vector.
function LVec2:normalized() end

--- Returns the perpendicular vector (-y, x).
---@return LVec2 Perpendicular vector.
function LVec2:perpendicular() end

--- Reflects this vector off a surface with the given normal.
---@param normal LVec2 Surface normal.
---@return LVec2 Reflected vector.
function LVec2:reflect(normal) end

--- Returns a new vector rotated by the given angle in radians.
---@param angle number Rotation angle in radians.
---@return LVec2 Rotated vector.
function LVec2:rotate(angle) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LVec2:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LVec2:typeOf(name) end

--- Returns the horizontal component of the vector.
---@return number Horizontal component value.
function LVec2:x() end

--- Returns the vertical component of the vector.
---@return number Vertical component value.
function LVec2:y() end

--- Lua-side wrapper around a [`Vec3`] value type.
---@class LVec3
---@field x number  x component
---@field y number  y component
---@field z number  z component
LVec3 = {}

--- Add another Vec3 and return the result.
---@param other LVec3 Vector to add.
---@return LVec3 Sum of the vectors.
function LVec3:add(other) end

--- Cross product with another Vec3.
---@param other LVec3 Vector to cross against this vector.
---@return LVec3 Cross product vector.
function LVec3:cross(other) end

--- Euclidean distance to another Vec3.
---@param other LVec3 Vector to measure against.
---@return number Distance between the vectors.
function LVec3:distance(other) end

--- Dot product with another Vec3.
---@param other LVec3 Vector to dot against this vector.
---@return number Dot product result.
function LVec3:dot(other) end

--- Returns the Euclidean length of the vector.
---@return number Vector length.
function LVec3:length() end

--- Returns the squared Euclidean length (avoids sqrt).
---@return number Squared vector length.
function LVec3:lengthSquared() end

--- Linear interpolation towards another Vec3.
---@param other LVec3 Target vector.
---@param t number Interpolation factor.
---@return LVec3 Interpolated vector.
function LVec3:lerp(other, t) end

--- Returns a unit-length version of this vector.
---@return LVec3 Normalized vector.
function LVec3:normalize() end

--- Scale this vector by a scalar and return the result.
---@param s number Scale factor.
---@return LVec3 Scaled vector.
function LVec3:scale(s) end

--- Creates a Vec3 with all components set to `v`.
---@param v number Component value to use for all axes.
---@return LVec3 Vector with all components set to the value.
LVec3.splat = function(v) end

--- Subtract another Vec3 and return the result.
---@param other LVec3 Vector to subtract.
---@return LVec3 Difference of the vectors.
function LVec3:sub(other) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LVec3:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type name matches.
function LVec3:typeOf(name) end

--- Compatibility alias for `vec2`.
---@param x number X component.
---@param y number Y component.
---@return LVec2 New vector.
lurek.math.Vec2 = function(x, y) end

--- Compatibility alias for `vec3`.
---@param x number X component.
---@param y number Y component.
---@param z number Z component.
---@return LVec3 New vector.
lurek.math.Vec3 = function(x, y, z) end

--- Creates a new empty AABB tree for efficient broad-phase overlap queries.
---@return LAabbTree New AABB tree.
lurek.math.aabbTree = function() end

--- Returns the absolute value of x.
---@param x number Input value.
---@return number Absolute value.
lurek.math.abs = function(x) end

--- Returns the arccosine of x, in radians.
---@param x number Input value.
---@return number Angle in radians.
lurek.math.acos = function(x) end

--- Returns the angle in radians from (x1, y1) to (x2, y2).
---@param x1 number Start x coordinate.
---@param y1 number Start y coordinate.
---@param x2 number End x coordinate.
---@param y2 number End y coordinate.
---@return number Angle in radians.
lurek.math.angleBetween = function(x1, y1, x2, y2) end

--- Applies a named easing function to progress value t.
---@param name string Easing function name.
---@param t number Progress value.
---@return number Eased value.
lurek.math.applyEasing = function(name, t) end

--- Returns the arcsine of x, in radians.
---@param x number Input value.
---@return number Angle in radians.
lurek.math.asin = function(x) end

--- Returns the arctangent of x (or atan2(y, x) when two args given).
---@param y number Y value.
---@param x? number Optional x value for atan2.
---@return number Angle in radians.
lurek.math.atan = function(y, x) end

--- Returns atan(y/x) using the signs of both args to determine the quadrant.
---@param y number Y value.
---@param x number X value.
---@return number Angle in radians.
lurek.math.atan2 = function(y, x) end

--- Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm. Returns a table of {x,y} tables.
---@param x1 integer Start x coordinate.
---@param y1 integer Start y coordinate.
---@param x2 integer End x coordinate.
---@param y2 integer End y coordinate.
---@return table Rasterized `{x, y}` points.
lurek.math.bresenham = function(x1, y1, x2, y2) end

--- Creates a Catmull-Rom spline through the given control points.
---@param points table Control points as `{x, y}` tables.
---@return LCatmullRom New spline.
lurek.math.catmullRom = function(points) end

--- Returns the smallest integer ≥ x.
---@param x number Input value.
---@return number Ceiled value.
lurek.math.ceil = function(x) end

--- Returns true if the point (px, py) lies inside the circle.
---@param cx number Circle center x coordinate.
---@param cy number Circle center y coordinate.
---@param r number Circle radius.
---@param px number Point x coordinate.
---@param py number Point y coordinate.
---@return boolean True when the point is inside the circle.
lurek.math.circleContainsPoint = function(cx, cy, r, px, py) end

--- Returns true if two circles overlap.
---@param x1 number First circle center x coordinate.
---@param y1 number First circle center y coordinate.
---@param r1 number First circle radius.
---@param x2 number Second circle center x coordinate.
---@param y2 number Second circle center y coordinate.
---@param r2 number Second circle radius.
---@return boolean True when the circles overlap.
lurek.math.circleIntersectsCircle = function(x1, y1, r1, x2, y2, r2) end

--- Tests an infinite line against a circle. Returns hit, then two optional hit-point pairs.
---@param cx number Circle center x coordinate.
---@param cy number Circle center y coordinate.
---@param r number Circle radius.
---@param lx1 number First line point x coordinate.
---@param ly1 number First line point y coordinate.
---@param lx2 number Second line point x coordinate.
---@param ly2 number Second line point y coordinate.
---@return boolean True when the line intersects the circle.
---@return number First hit-point X coordinate.
---@return number First hit-point Y coordinate.
---@return number Second hit-point X coordinate.
---@return number Second hit-point Y coordinate.
lurek.math.circleIntersectsLine = function(cx, cy, r, lx1, ly1, lx2, ly2) end

--- Tests a line segment against a circle. Returns hit, then two optional hit-point pairs.
---@param cx number Circle center x coordinate.
---@param cy number Circle center y coordinate.
---@param r number Circle radius.
---@param sx1 number Segment start x coordinate.
---@param sy1 number Segment start y coordinate.
---@param sx2 number Segment end x coordinate.
---@param sy2 number Segment end y coordinate.
---@return boolean True when the segment intersects the circle.
---@return number First hit-point X coordinate.
---@return number First hit-point Y coordinate.
---@return number Second hit-point X coordinate.
---@return number Second hit-point Y coordinate.
lurek.math.circleIntersectsSegment = function(cx, cy, r, sx1, sy1, sx2, sy2) end

--- Clamps `v` between `min` and `max`.
---@param v number Value to clamp.
---@param min number Lower bound.
---@param max number Upper bound.
---@return number Clamped value.
lurek.math.clamp = function(v, min, max) end

--- Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
---@param px number Point x coordinate.
---@param py number Point y coordinate.
---@param x1 number Segment start x coordinate.
---@param y1 number Segment start y coordinate.
---@param x2 number Segment end x coordinate.
---@param y2 number Segment end y coordinate.
---@return number Closest point X coordinate.
---@return number Closest point Y coordinate.
lurek.math.closestPointOnSegment = function(px, py, x1, y1, x2, y2) end

--- Computes the convex hull of a flat {x1,y1,...} point list. Returns a flat table.
---@param points table Flat point list.
---@return table Flat hull point list.
lurek.math.convexHull = function(points) end

--- Returns the cosine of x (radians).
---@param x number Angle in radians.
---@return number Cosine value.
lurek.math.cos = function(x) end

--- Converts radians to degrees.
---@param rad number Angle in radians.
---@return number Angle in degrees.
lurek.math.deg = function(rad) end

--- Delaunay triangulation of a flat {x1,y1,...} point list. Returns a table of flat 6-number triangle tables.
---@param points table Flat point list.
---@return table Triangle tables with 6 numbers each.
lurek.math.delaunayTriangulate = function(points) end

--- Returns the Euclidean distance between (x1,y1) and (x2,y2).
---@param x1 number First point x coordinate.
---@param y1 number First point y coordinate.
---@param x2 number Second point x coordinate.
---@param y2 number Second point y coordinate.
---@return number Euclidean distance.
lurek.math.distance = function(x1, y1, x2, y2) end

--- Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
---@param x1 number First point x coordinate.
---@param y1 number First point y coordinate.
---@param x2 number Second point x coordinate.
---@param y2 number Second point y coordinate.
---@return number Squared Euclidean distance.
lurek.math.distanceSq = function(x1, y1, x2, y2) end

--- Returns e raised to the power x.
---@param x number Exponent value.
---@return number Result of `e^x`.
lurek.math.exp = function(x) end

--- Returns fractal Brownian motion noise at (x, y).
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param seed? integer Optional seed override.
---@param octaves? integer Optional octave count.
---@param lacunarity? number Optional lacunarity value.
---@param gain? number Optional gain value.
---@return number Noise value.
lurek.math.fbm = function(x, y, seed, octaves, lacunarity, gain) end

--- Returns the largest integer ≤ x.
---@param x number Input value.
---@return number Floored value.
lurek.math.floor = function(x) end

--- Returns the remainder of x / y (fmod).
---@param x number Dividend value.
---@param y number Divisor value.
---@return number Remainder value.
lurek.math.fmod = function(x, y) end

--- Parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats.
---@param hex string Hex color string.
---@return number Red component.
---@return number Green component.
---@return number Blue component.
---@return number Alpha component.
lurek.math.fromHex = function(hex) end

--- Converts a gamma-encoded sRGB value to linear space.
---@param c number Gamma-encoded value.
---@return number Linear-space value.
lurek.math.gammaToLinear = function(c) end

--- Creates a Hermite spline defined by two endpoints and tangents.
---@param p0x number First endpoint x coordinate.
---@param p0y number First endpoint y coordinate.
---@param p1x number Second endpoint x coordinate.
---@param p1y number Second endpoint y coordinate.
---@param m0x number First tangent x component.
---@param m0y number First tangent y component.
---@param m1x number Second tangent x component.
---@param m1y number Second tangent y component.
---@return LHermite New spline.
lurek.math.hermite = function(p0x, p0y, p1x, p1y, m0x, m0y, m1x, m1y) end

--- Converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats.
---@param h number Hue value.
---@param s number Saturation value.
---@param l number Lightness value.
---@return number Red component.
---@return number Green component.
---@return number Blue component.
---@return number Alpha component.
lurek.math.hslToRgb = function(h, s, l) end

--- Back ease-in — overshoots slightly before settling at the target.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inBack = function(t) end

--- Bounce ease-in — reverse bounce effect that accelerates into the motion.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inBounce = function(t) end

--- Cubic ease-in — acceleration starts slowly then increases sharply.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inCubic = function(t) end

--- Elastic ease-in — spring-like overshoot at the beginning of the motion.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inElastic = function(t) end

--- Exponential ease-in — very slow start that accelerates sharply near the end.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inExpo = function(t) end

--- Back ease-in-out — overshoot on both ends.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inOutBack = function(t) end

--- Bounce ease-in-out — bouncing motion on both ends.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inOutBounce = function(t) end

--- Cubic ease-in-out — slow start and end with fast cubic middle.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inOutCubic = function(t) end

--- Elastic ease-in-out — spring-like oscillation on both ends.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inOutElastic = function(t) end

--- Exponential ease-in-out — very slow start and end with an exponential surge.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inOutExpo = function(t) end

--- Quadratic ease-in-out — slow start, fast middle, slow end.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inOutQuad = function(t) end

--- Quartic ease-in-out — very slow start and end with a sharp middle peak.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inOutQuart = function(t) end

--- Sinusoidal ease-in-out — smooth S-curve based on cosine interpolation.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inOutSine = function(t) end

--- Quadratic ease-in — acceleration that starts at zero and increases.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inQuad = function(t) end

--- Quartic ease-in — strongly delayed acceleration using a power-of-4 curve.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inQuart = function(t) end

--- Sinusoidal ease-in — gentle acceleration based on a sine curve.
---@param t number Progress value.
---@return number Eased value.
lurek.math.inSine = function(t) end

--- Returns the interpolation parameter t for `v` in [a, b].
---@param a number Start value.
---@param b number End value.
---@param v number Sample value.
---@return number Interpolation factor.
lurek.math.inverseLerp = function(a, b, v) end

--- Returns true if the polygon (flat table {x1,y1,...}) is convex.
---@param polygon table Flat polygon vertex list.
---@return boolean True when the polygon is convex.
lurek.math.isConvex = function(polygon) end

--- Linear interpolation between two numbers: a + (b - a) * t.
---@param a number Start value.
---@param b number End value.
---@param t number Interpolation factor.
---@return number Interpolated value.
lurek.math.lerp = function(a, b, t) end

--- Infinite line intersection. Returns (x, y) or (nil, nil) if lines are parallel.
---@param x1 number First line start x coordinate.
---@param y1 number First line start y coordinate.
---@param x2 number First line end x coordinate.
---@param y2 number First line end y coordinate.
---@param x3 number Second line start x coordinate.
---@param y3 number Second line start y coordinate.
---@param x4 number Second line end x coordinate.
---@param y4 number Second line end y coordinate.
---@return number Intersection X coordinate.
---@return number Intersection Y coordinate.
lurek.math.lineIntersect = function(x1, y1, x2, y2, x3, y3, x4, y4) end

--- Linear easing (identity).
---@param t number Progress value.
---@return number Eased value.
lurek.math.linear = function(t) end

--- Converts a linear-space value to gamma-encoded sRGB.
---@param c number Linear-space value.
---@return number Gamma-encoded value.
lurek.math.linearToGamma = function(c) end

--- Returns the natural log of x, or log base b if b is supplied.
---@param x number Input value.
---@param b? number Optional logarithm base.
---@return number Logarithm result.
lurek.math.log = function(x, b) end

--- Returns the largest of the supplied numbers.
---@param ... number Numbers to compare.
---@return number Largest supplied value.
lurek.math.max = function(...) end

--- Returns the smallest of the supplied numbers.
---@param ... number Numbers to compare.
---@return number Smallest supplied value.
lurek.math.min = function(...) end

--- Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
---@param points table Flat coordinate list.
---@return LBezierCurve New Bezier curve.
lurek.math.newBezierCurve = function(points) end

--- Creates a new Circle value type with the given centre and radius.
---@param x number Centre x coordinate.
---@param y number Centre y coordinate.
---@param radius number Radius value.
---@return LCircle New circle.
lurek.math.newCircle = function(x, y, radius) end

--- Creates a new seeded noise generator.
---@param seed? integer Optional seed value.
---@return LNoiseGenerator New noise generator.
lurek.math.newNoiseGenerator = function(seed) end

--- Creates a new random number generator with an optional seed.
---@param seed? integer Optional seed value.
---@return LRandomGenerator New random generator.
lurek.math.newRandomGenerator = function(seed) end

--- Creates a new SpatialHash with the given cell size.
---@param cellSize number Spatial hash cell size.
---@return LSpatialHash New spatial hash.
lurek.math.newSpatialHash = function(cellSize) end

--- Creates a new Transform, optionally initialised from full parameters.
---@param x? number Translation x value.
---@param y? number Translation y value.
---@param angle? number Rotation angle in radians.
---@param sx? number Horizontal scale factor.
---@param sy? number Vertical scale factor.
---@param ox? number Origin x value.
---@param oy? number Origin y value.
---@param kx? number Horizontal shear factor.
---@param ky? number Vertical shear factor.
---@return LTransform New transform.
lurek.math.newTransform = function(x, y, angle, sx, sy, ox, oy, kx, ky) end

--- Creates a new Tween with the given duration and easing name.
---@param duration number Tween duration in seconds.
---@param easingName? string Optional easing function name.
---@return LTween New tween.
lurek.math.newTween = function(duration, easingName) end

--- Back ease-out — overshoots the target then snaps back into place.
---@param t number Progress value.
---@return number Eased value.
lurek.math.outBack = function(t) end

--- Bounce ease-out — simulates a ball bouncing against the target value.
---@param t number Progress value.
---@return number Eased value.
lurek.math.outBounce = function(t) end

--- Cubic ease-out — rapid deceleration using a cubic power curve.
---@param t number Progress value.
---@return number Eased value.
lurek.math.outCubic = function(t) end

--- Elastic ease-out — spring-like oscillation that settles at the target.
---@param t number Progress value.
---@return number Eased value.
lurek.math.outElastic = function(t) end

--- Exponential ease-out — sharp initial speed that decelerates exponentially.
---@param t number Progress value.
---@return number Eased value.
lurek.math.outExpo = function(t) end

--- Quadratic ease-out — deceleration that starts fast and ends at zero.
---@param t number Progress value.
---@return number Eased value.
lurek.math.outQuad = function(t) end

--- Quartic ease-out — rapid deceleration using a power-of-4 curve.
---@param t number Progress value.
---@return number Eased value.
lurek.math.outQuart = function(t) end

--- Sinusoidal ease-out — gentle deceleration based on a cosine curve.
---@param t number Progress value.
---@return number Eased value.
lurek.math.outSine = function(t) end

--- Returns 2D Perlin noise at (x, y) with the given seed.
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param seed? integer Optional seed override.
---@return number Noise value.
lurek.math.perlin2d = function(x, y, seed) end

--- Returns 3D Perlin noise at (x, y, z) with the given seed.
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param z number Sample z coordinate.
---@param seed? integer Optional seed override.
---@return number Noise value.
lurek.math.perlin3d = function(x, y, z, seed) end

--- Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
---@param polygon table Flat polygon vertex list.
---@param px number Point x coordinate.
---@param py number Point y coordinate.
---@return boolean True when the point is inside the polygon.
lurek.math.pointInPolygon = function(polygon, px, py) end

--- Returns the signed area of a polygon given as a flat {x1,y1,...} table.
---@param polygon table Flat polygon vertex list.
---@return number Signed polygon area.
lurek.math.polygonArea = function(polygon) end

--- Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
---@param polygon table Flat polygon vertex list.
---@return number Centroid X coordinate.
---@return number Centroid Y coordinate.
lurek.math.polygonCentroid = function(polygon) end

--- Clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
---@param polygon table Flat polygon vertex list.
---@param nx number Half-plane normal x component.
---@param ny number Half-plane normal y component.
---@param d number Half-plane distance value.
---@return table Clipped polygon as a flat `{x1, y1, ...}` table.
lurek.math.polygonClip = function(polygon, nx, ny, d) end

--- Computes the approximate difference `A - B` for convex polygon inputs.
---@param a table First polygon as `{x, y}` tables.
---@param b table Second polygon as `{x, y}` tables.
---@return table Difference polygon as `{x, y}` tables.
lurek.math.polygonDifference = function(a, b) end

--- Computes the intersection of two convex polygons.
---@param a table First polygon as `{x, y}` tables.
---@param b table Second polygon as `{x, y}` tables.
---@return table Intersection polygon as `{x, y}` tables.
lurek.math.polygonIntersection = function(a, b) end

--- Computes the approximate union of two convex polygons as a convex hull.
---@param a table First polygon as `{x, y}` tables.
---@param b table Second polygon as `{x, y}` tables.
---@return table Union polygon as `{x, y}` tables.
lurek.math.polygonUnion = function(a, b) end

--- Returns x raised to the power y.
---@param x number Base value.
---@param y number Exponent value.
---@return number Power result.
lurek.math.pow = function(x, y) end

--- Converts degrees to radians.
---@param deg number Angle in degrees.
---@return number Angle in radians.
lurek.math.rad = function(deg) end

--- Returns a pseudo-random number using Lua's built-in `math.random` behavior.
---@param min_or_max? number Optional upper bound, or lower bound when `max` is also set.
---@param max? number Optional upper bound.
---@return number Random number.
lurek.math.random = function(min_or_max, max) end

--- Returns a pseudo-random integer in [lo, hi] (inclusive).
---@param lo integer Lower bound.
---@param hi integer Upper bound.
---@return integer Random integer.
lurek.math.randomInt = function(lo, hi) end

--- Creates a rectangle centered at (cx, cy) with the given width and height.
---@param cx number Center x coordinate.
---@param cy number Center y coordinate.
---@param w number Rectangle width.
---@param h number Rectangle height.
---@return number Rectangle X coordinate.
---@return number Rectangle Y coordinate.
---@return number Rectangle width.
---@return number Rectangle height.
lurek.math.rectFromCenter = function(cx, cy, w, h) end

--- Returns the union (bounding box) of two rectangles.
---@param x1 number First rectangle x coordinate.
---@param y1 number First rectangle y coordinate.
---@param w1 number First rectangle width.
---@param h1 number First rectangle height.
---@param x2 number Second rectangle x coordinate.
---@param y2 number Second rectangle y coordinate.
---@param w2 number Second rectangle width.
---@param h2 number Second rectangle height.
---@return number Union rectangle X coordinate.
---@return number Union rectangle Y coordinate.
---@return number Union rectangle width.
---@return number Union rectangle height.
lurek.math.rectUnion = function(x1, y1, w1, h1, x2, y2, w2, h2) end

--- Remaps `v` from [in_min, in_max] to [out_min, out_max].
---@param v number Value to remap.
---@param in_min number Input range minimum.
---@param in_max number Input range maximum.
---@param out_min number Output range minimum.
---@param out_max number Output range maximum.
---@return number Remapped value.
lurek.math.remap = function(v, in_min, in_max, out_min, out_max) end

--- Converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1).
---@param r number Red value.
---@param g number Green value.
---@param b number Blue value.
---@return number Hue value.
---@return number Saturation value.
---@return number Lightness value.
lurek.math.rgbToHsl = function(r, g, b) end

--- Returns x rounded to the nearest integer (half-up).
---@param x number Input value.
---@return number Rounded value.
lurek.math.round = function(x) end

--- Tests if two line segments intersect. Returns (hit, ix?, iy?).
---@param x1 number First segment start x coordinate.
---@param y1 number First segment start y coordinate.
---@param x2 number First segment end x coordinate.
---@param y2 number First segment end y coordinate.
---@param x3 number Second segment start x coordinate.
---@param y3 number Second segment start y coordinate.
---@param x4 number Second segment end x coordinate.
---@param y4 number Second segment end y coordinate.
---@return boolean True when the segments intersect.
---@return number Intersection X coordinate.
---@return number Intersection Y coordinate.
lurek.math.segmentIntersectsSegment = function(x1, y1, x2, y2, x3, y3, x4, y4) end

--- Returns -1, 0, or 1 depending on the sign of `v`.
---@param v number Input value.
---@return number Sign result.
lurek.math.sign = function(v) end

--- Returns 2D Simplex noise at (x, y) with the given seed.
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param seed? integer Optional seed override.
---@return number Noise value.
lurek.math.simplex2d = function(x, y, seed) end

--- Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
---@param x number Sample x coordinate.
---@param y number Sample y coordinate.
---@param z? number Optional sample z coordinate.
---@return number Noise value.
lurek.math.simplexNoise = function(x, y, z) end

--- Returns the sine of x (radians).
---@param x number Angle in radians.
---@return number Sine value.
lurek.math.sin = function(x) end

--- Hermite smoothstep between `edge0` and `edge1`.
---@param edge0 number Lower edge.
---@param edge1 number Upper edge.
---@param x number Input value.
---@return number Smoothed interpolation value.
lurek.math.smoothstep = function(edge0, edge1, x) end

--- Returns the square root of x.
---@param x number Input value.
---@return number Square root.
lurek.math.sqrt = function(x) end

--- Returns the tangent of x (radians).
---@param x number Angle in radians.
---@return number Tangent value.
lurek.math.tan = function(x) end

--- Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
---@param polygon table Flat polygon vertex list.
---@return table Triangle tables with 6 numbers each.
lurek.math.triangulate = function(polygon) end

--- Creates a 2D vector with x and y components.
---@param x number X component.
---@param y number Y component.
---@return LVec2 New vector.
lurek.math.vec2 = function(x, y) end

--- Creates a 3D vector `{x, y, z}` table with numeric components.
---@param x number X component.
---@param y number Y component.
---@param z number Z component.
---@return LVec3 New vector.
lurek.math.vec3 = function(x, y, z) end

--- Computes the Voronoi diagram for a list of 2-D seed points.
---@param points table Seed points as `{x, y}` tables.
---@return table Cells with `site` and `vertices` tables.
lurek.math.voronoi = function(points) end

---@class lurek.minimap
lurek.minimap = {}

--- Lua-side wrapper around a [`Minimap`].
---@class LMinimap
LMinimap = {}

--- Adds a persistent marker and returns its auto-assigned ID.
---@param x number X position.
---@param y number Y position.
---@param desc? string Marker description.
---@param r? number Red component.
---@param g? number Green component.
---@param b? number Blue component.
---@param a? number Alpha component.
---@return integer Auto-assigned marker ID.
function LMinimap:addMarker(x, y, desc, r, g, b, a) end

--- Registers a new object type and returns its 1-based index.
---@param name string Name string.
---@param r number Red component.
---@param g number Green component.
---@param b number Blue component.
---@param a? number Alpha component.
---@return integer 1-based index of the new object type.
function LMinimap:addObjectType(name, r, g, b, a) end

--- Adds an animated ping at grid coordinates with a duration and optional color.
---@param x number X position.
---@param y number Y position.
---@param duration number Duration in seconds.
---@param r? number Red component.
---@param g? number Green component.
---@param b? number Blue component.
---@param a? number Alpha component.
---@return nil No value is returned.
function LMinimap:addPing(x, y, duration, r, g, b, a) end

--- Removes the animation from a marker, reverting it to static.
---@param id integer Object id.
---@return nil No value is returned.
function LMinimap:clearMarkerAnimation(id) end

--- Removes all tracked objects.
---@return nil No value is returned.
function LMinimap:clearObjects() end

--- Removes all custom geometry from the minimap overlay.
---@return nil No value is returned.
function LMinimap:clearOverlay() end

--- Removes a displayed path. If id is nil, all paths are removed.
---@param id? integer Object id.
---@return nil No value is returned.
function LMinimap:clearPath(id) end

--- Clears the viewport rectangle overlay.
---@return nil No value is returned.
function LMinimap:clearViewportRect() end

--- Draws a custom line segment on the minimap overlay.
---@param x1 number End X position.
---@param y1 number End Y position.
---@param x2 number Second X position.
---@param y2 number Second Y position.
---@param color table {r, g, b, a} integers 0-255.
---@return nil No value is returned.
function LMinimap:drawLine(x1, y1, x2, y2, color) end

--- Draws a custom rectangle on the minimap overlay.
---@param x number X position.
---@param y number Y position.
---@param w number Width value.
---@param h number Height value.
---@param color table {r, g, b, a} integers 0-255.
---@return nil No value is returned.
function LMinimap:drawRect(x, y, w, h, color) end

--- Renders the minimap grid to a CPU ImageData.
---@param pixel_size integer Pixel size in source cells.
---@return ImageData Image data object.
function LMinimap:drawToImage(pixel_size) end

--- Returns the center coordinates as x, y.
---@return number Center X coordinate.
---@return number Center Y coordinate.
function LMinimap:getCenter() end

--- Returns the center X coordinate.
---@return number Center X coordinate.
function LMinimap:getCenterX() end

--- Returns the center Y coordinate.
---@return number Center Y coordinate.
function LMinimap:getCenterY() end

--- Returns the current color mode as a string.
---@return string Current color mode string.
function LMinimap:getColorMode() end

--- Returns the display height in pixels.
---@return integer Display height in pixels.
function LMinimap:getDisplayHeight() end

--- Returns the display width and height as two values.
---@return integer Display width in pixels.
---@return integer Display height in pixels.
function LMinimap:getDisplaySize() end

--- Returns the display width in pixels.
---@return integer Display width in pixels.
function LMinimap:getDisplayWidth() end

--- Returns the fog overlay color as r, g, b, a.
---@return number Fog red component.
---@return number Fog green component.
---@return number Fog blue component.
---@return number Fog alpha component.
function LMinimap:getFogColor() end

--- Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
---@param x integer X position.
---@param y integer Y position.
---@return integer Fog level at the grid cell: 0 hidden, 1 explored, 2 visible.
function LMinimap:getFogLevel(x, y) end

--- Returns the grid height in cells.
---@return integer Grid height in cells.
function LMinimap:getGridHeight() end

--- Returns the grid width and height as two values.
---@return integer Grid width in cells.
---@return integer Grid height in cells.
function LMinimap:getGridSize() end

--- Returns the grid width in cells.
---@return integer Grid width in cells.
function LMinimap:getGridWidth() end

--- Returns hover tooltip text for the element under screen coordinates, or nil.
---@param sx number Screen X position.
---@param sy number Screen Y position.
---@param minimap_x number Minimap x value.
---@param minimap_y number Minimap y value.
---@return string Hover tooltip string, or nil if nothing is under the cursor.
function LMinimap:getHoverInfo(sx, sy, minimap_x, minimap_y) end

--- Returns the index of the currently active render layer.
---@return integer Index of the currently active render layer.
function LMinimap:getLayer() end

--- Returns the number of markers.
---@return integer Number of markers.
function LMinimap:getMarkerCount() end

--- Returns the description of a marker, or nil.
---@param id integer Object id.
---@return string Marker description string, or nil if not found.
function LMinimap:getMarkerDescription(id) end

--- Returns the number of tracked objects.
---@return integer Number of tracked objects.
function LMinimap:getObjectCount() end

--- Returns the number of registered object types.
---@return integer Number of registered object types.
function LMinimap:getObjectTypeCount() end

--- Returns the display color for an owner/faction as r, g, b, a.
---@param owner integer Owner id.
---@return number Owner red component.
---@return number Owner green component.
---@return number Owner blue component.
---@return number Owner alpha component.
function LMinimap:getOwnerColor(owner) end

--- Returns the number of active pings.
---@return integer Number of active pings.
function LMinimap:getPingCount() end

--- Returns the terrain type at a 1-based grid position.
---@param x integer 1-based grid column.
---@param y integer 1-based grid row.
---@return integer Terrain type ID at the cell.
function LMinimap:getTerrain(x, y) end

--- Returns the display color for a terrain type as r, g, b, a.
---@param terrain_type integer Terrain type ID to query.
---@return number Red component.
---@return number Green component.
---@return number Blue component.
---@return number Alpha component.
function LMinimap:getTerrainColor(terrain_type) end

--- Returns the hover tooltip string for a terrain type ID, or nil.
---@param type_id integer Type id.
---@return string Tile description string, or nil if none was set.
function LMinimap:getTileDescription(type_id) end

--- Returns the viewport rectangle color as r, g, b, a.
---@return number Viewport red component.
---@return number Viewport green component.
---@return number Viewport blue component.
---@return number Viewport alpha component.
function LMinimap:getViewportColor() end

--- Returns the viewport rectangle as x, y, w, h or nil if not set.
---@return nil No value is returned.
function LMinimap:getViewportRect() end

--- Returns the current zoom level.
---@return number Current zoom level.
function LMinimap:getZoom() end

--- Converts grid coordinates to screen coordinates.
---@param gx number X-axis value.
---@param gy number Y-axis value.
---@param minimap_x number Minimap x value.
---@param minimap_y number Minimap y value.
---@return number Screen X coordinate.
---@return number Screen Y coordinate.
function LMinimap:gridToScreen(gx, gy, minimap_x, minimap_y) end

--- Returns whether a marker with the given ID exists.
---@param id integer Object id.
---@return boolean Whether a marker with the given ID exists.
function LMinimap:hasMarker(id) end

--- Returns whether anti-aliasing is enabled.
---@return boolean Whether anti-aliasing is enabled.
function LMinimap:isAntiAlias() end

--- Returns whether this minimap responds to click hit-testing.
---@return boolean Whether the minimap responds to click hit-testing.
function LMinimap:isClickable() end

--- Returns whether fog of war is enabled.
---@return boolean Whether fog of war is enabled.
function LMinimap:isFogEnabled() end

--- Returns whether an object type (1-based index) is visible.
---@param type_idx integer Type idx.
---@return boolean Whether the object type is visible.
function LMinimap:isObjectTypeVisible(type_idx) end

--- Returns whether the viewport rectangle is visible.
---@return boolean Whether the viewport rectangle is visible.
function LMinimap:isViewportVisible() end

--- Removes the minimap marker with the given integer ID, if present.
---@param id integer Object id.
---@return boolean True if the marker existed and was removed.
function LMinimap:removeMarker(id) end

--- Removes a tracked object by ID.
---@param id integer Object id.
---@return boolean True if the object existed and was removed.
function LMinimap:removeObject(id) end

--- Renders the minimap to the screen at the given position.
---@param x? number X position.
---@param y? number Y position.
---@return nil No value is returned.
function LMinimap:render(x, y) end

--- Converts screen coordinates to grid coordinates.
---@param sx number Screen X position.
---@param sy number Screen Y position.
---@param minimap_x number Minimap x value.
---@param minimap_y number Minimap y value.
---@return number Grid X coordinate.
---@return number Grid Y coordinate.
function LMinimap:screenToGrid(sx, sy, minimap_x, minimap_y) end

--- Sets whether anti-aliasing is enabled.
---@param enabled boolean Whether it is enabled.
---@return nil No value is returned.
function LMinimap:setAntiAlias(enabled) end

--- Sets the center of the minimap view in grid coordinates.
---@param x number X position.
---@param y number Y position.
---@return nil No value is returned.
function LMinimap:setCenter(x, y) end

--- Sets whether this minimap responds to click hit-testing.
---@param enabled boolean Whether it is enabled.
---@return nil No value is returned.
function LMinimap:setClickable(enabled) end

--- Sets the color mode ("terrain" or "political").
---@param mode string Mode name.
---@return nil No value is returned.
function LMinimap:setColorMode(mode) end

--- Sets the display size in pixels.
---@param w integer New display width in pixels.
---@param h integer New display height in pixels.
---@return nil No value is returned.
function LMinimap:setDisplaySize(w, h) end

--- Sets the fog overlay color.
---@param r number Red component.
---@param g number Green component.
---@param b number Blue component.
---@param a? number Alpha component.
---@return nil No value is returned.
function LMinimap:setFogColor(r, g, b, a) end

--- Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
---@param data table Input data table.
---@return nil No value is returned.
function LMinimap:setFogData(data) end

--- Enables or disables fog of war.
---@param enabled boolean Whether it is enabled.
---@return nil No value is returned.
function LMinimap:setFogEnabled(enabled) end

--- Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
---@param x integer X position.
---@param y integer Y position.
---@param level integer Level name.
---@return nil No value is returned.
function LMinimap:setFogLevel(x, y, level) end

--- Switches the minimap's active render layer (0-based index).
---@param layer integer Layer index.
---@return nil No value is returned.
function LMinimap:setLayer(layer) end

--- Stores tile data for a specific layer index.
---@param layer integer Layer index.
---@param data table flat 1-based table of terrain type integers.
---@return nil No value is returned.
function LMinimap:setLayerData(layer, data) end

--- Attaches an animation to a marker. Does nothing if the ID does not exist.
---@param id integer Object id.
---@param anim_type string "blink", "pulse", or "rotate".
---@param speed number Speed value.
---@return nil No value is returned.
function LMinimap:setMarkerAnimation(id, anim_type, speed) end

--- Sets or updates a tracked object on the minimap.
---@param id integer Object id.
---@param x number X position.
---@param y number Y position.
---@param type_idx integer Type idx.
---@param owner? integer Owner id.
---@return nil No value is returned.
function LMinimap:setObject(id, x, y, type_idx, owner) end

--- Sets whether an object type (1-based index) is visible.
---@param type_idx integer Type idx.
---@param visible boolean Whether it is visible.
---@return nil No value is returned.
function LMinimap:setObjectTypeVisible(type_idx, visible) end

--- Sets the display color for an owner/faction.
---@param owner integer Owner id.
---@param r number Red component.
---@param g number Green component.
---@param b number Blue component.
---@param a? number Alpha component.
---@return nil No value is returned.
function LMinimap:setOwnerColor(owner, r, g, b, a) end

--- Sets the terrain type at a 1-based grid position.
---@param x integer 1-based grid column.
---@param y integer 1-based grid row.
---@param terrain_type integer Terrain type ID to store.
---@return nil No value is returned.
function LMinimap:setTerrain(x, y, terrain_type) end

--- Sets the display color for a terrain type.
---@param terrain_type integer Terrain type ID to recolor.
---@param r number Red component in the range 0 to 1.
---@param g number Green component in the range 0 to 1.
---@param b number Blue component in the range 0 to 1.
---@param a? number Alpha component in the range 0 to 1.
---@return nil No value is returned.
function LMinimap:setTerrainColor(terrain_type, r, g, b, a) end

--- Sets terrain types from a flat 1-based Lua table of integers (row-major).
---@param data table Flat row-major terrain ID table.
---@return nil No value is returned.
function LMinimap:setTerrainData(data) end

--- Sets a hover tooltip string for a terrain type ID.
---@param type_id integer Terrain type ID to annotate.
---@param desc string Tooltip text shown for that tile type.
---@return nil No value is returned.
function LMinimap:setTileDescription(type_id, desc) end

--- Sets the viewport rectangle color.
---@param r number Red component.
---@param g number Green component.
---@param b number Blue component.
---@param a? number Alpha component.
---@return nil No value is returned.
function LMinimap:setViewportColor(r, g, b, a) end

--- Sets the viewport rectangle overlay in grid coordinates.
---@param x number X position.
---@param y number Y position.
---@param w number Width value.
---@param h number Height value.
---@return nil No value is returned.
function LMinimap:setViewportRect(x, y, w, h) end

--- Sets whether the viewport rectangle is visible.
---@param visible boolean Whether it is visible.
---@return nil No value is returned.
function LMinimap:setViewportVisible(visible) end

--- Sets the zoom level (minimum 0.1).
---@param zoom number Zoom factor.
---@return nil No value is returned.
function LMinimap:setZoom(zoom) end

--- Displays a pathfinding route on the minimap and returns its path ID.
---@param points table {{ x, y }, { x, y }, ... }.
---@param color table { r, g, b, a } integers 0-255.
---@return nil No value is returned.
function LMinimap:showPath(points, color) end

--- Returns the type name of this object.
---@return string Always "LMinimap".
function LMinimap:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True if the given type name matches this object.
function LMinimap:typeOf(name) end

--- Advances time-based effects by dt seconds (expires pings).
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LMinimap:update(dt) end

--- Creates a new grid-based minimap.
---@param grid_w integer Grid width.
---@param grid_h integer Grid height.
---@param display_w? integer Display width in pixels.
---@param display_h? integer Display height in pixels.
---@return Minimap New grid-based minimap.
lurek.minimap.newMinimap = function(grid_w, grid_h, display_w, display_h) end

---@class lurek.mods
lurek.mods = {}

--- A typed content registry for mod-contributed assets and objects.
---@class LContentRegistry
LContentRegistry = {}

--- Retrieves a content entry.
---@param type_name string Registered content type name.
---@param id string Content identifier.
---@return table Returns the stored content entry.
function LContentRegistry:get(type_name, id) end

--- Returns all entries for a type.
---@param type_name string Registered content type name.
---@return table Returns the map of entries for the type.
function LContentRegistry:getAll(type_name) end

--- Returns all registered type names.
---@return table Returns the registered type name array.
function LContentRegistry:getTypes() end

--- Registers a content entry.
---@param type_name string Registered content type name.
---@param id string Unique identifier for the entry.
---@param obj LuaValue Content object to store.
---@return nil No value is returned.
function LContentRegistry:register(type_name, id, obj) end

--- Registers a new content type.
---@param type_name string Type identifier such as `weapon` or `spell`.
---@return nil No value is returned.
function LContentRegistry:registerType(type_name) end

--- Returns the type name of this object.
---@return string Returns the Lua-visible type name.
function LContentRegistry:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean Returns whether the object matches the type name.
function LContentRegistry:typeOf(name) end

--- Lua-side wrapper around [`ModInfo`] with per-mod hook and config storage.
---@class LMod
LMod = {}

--- Returns the required engine API version string when one is set.
---@return string Returns the required API version string.
function LMod:getApiVersion() end

--- Returns the author name string from this mod's metadata manifest.
---@return string Returns the author name.
function LMod:getAuthor() end

--- Returns an array of declared capability flags.
---@return table Returns the capability string array.
function LMod:getCapabilities() end

--- Returns the stored config value.
---@return table Returns the stored config value.
function LMod:getConfig() end

--- Returns the config schema as an array of `{key, type, default}` tables.
---@return table Returns the config schema table.
function LMod:getConfigSchema() end

--- Returns the list of required mod IDs.
---@return table Returns the dependency ID array.
function LMod:getDependencies() end

--- Returns the mod description.
---@return string Returns the mod description.
function LMod:getDescription() end

--- Returns the hook function for the given name.
---@param name string Hook name.
---@return function Returns the stored hook function.
function LMod:getHook(name) end

--- Returns an array of registered hook names.
---@return table Returns the hook name array.
function LMod:getHookNames() end

--- Returns the unique mod identifier.
---@return string Returns the mod identifier.
function LMod:getId() end

--- Returns the localized or human-readable display name of the mod.
---@return string Returns the mod display name.
function LMod:getName() end

--- Returns the load-order priority.
---@return integer Returns the mod priority value.
function LMod:getPriority() end

--- Returns the version string.
---@return string Returns the mod version string.
function LMod:getVersion() end

--- Returns whether a hook with the given name exists.
---@param name string Hook name.
---@return boolean Returns whether the hook exists.
function LMod:hasHook(name) end

--- Returns whether the mod is enabled.
---@return boolean Returns whether the mod is enabled.
function LMod:isEnabled() end

--- Returns whether the mod has been loaded.
---@return boolean Returns whether the mod is loaded.
function LMod:isLoaded() end

--- Releases all hook and config registry references.
---@return nil No value is returned.
function LMod:releaseRefs() end

--- Sets the required engine API version string.
---@param api_version string Required engine API version string.
---@return nil No value is returned.
function LMod:setApiVersion(api_version) end

--- Replaces the capability list with the given array of strings.
---@param caps table Capability string array.
---@return nil No value is returned.
function LMod:setCapabilities(caps) end

--- Stores an arbitrary config value for this mod.
---@param value LuaValue Config value to store.
---@return nil No value is returned.
function LMod:setConfig(value) end

--- Replaces the config schema with the given array of `{key, type, default}` tables.
---@param schema table Config schema table.
---@return nil No value is returned.
function LMod:setConfigSchema(schema) end

--- Enables or disables this mod.
---@param enabled boolean Whether the mod should be enabled.
---@return nil No value is returned.
function LMod:setEnabled(enabled) end

--- Registers a named hook callback, replacing any existing one.
---@param name string Hook name.
---@param func function Hook callback to store.
---@return nil No value is returned.
function LMod:setHook(name, func) end

--- Returns the type name of this object.
---@return string Returns the Lua-visible type name.
function LMod:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean Returns whether the object matches the type name.
function LMod:typeOf(name) end

--- Lua-side wrapper around [`ModManager`].
---@class LModManager
LModManager = {}

--- Clears the custom load order.
---@return nil No value is returned.
function LModManager:clearLoadOrder() end

--- Clears the reload queue without reloading.
---@return nil No value is returned.
function LModManager:clearReloadQueue() end

--- Returns an array of info tables for all registered mods.
---@return table Returns the full mod info array.
function LModManager:getAllMods() end

--- Returns an array of info tables in effective load order.
---@return table Returns the load-order info array.
function LModManager:getLoadOrder() end

--- Returns the number of registered mods.
---@return integer Returns the registered mod count.
function LModManager:getModCount() end

--- Returns the filesystem path of a registered mod.
---@param mod_id string Mod identifier to inspect.
---@return string Returns the registered mod path.
function LModManager:getModPath(mod_id) end

--- Returns the array of mod IDs pending hot-reload.
---@return table Returns the queued mod ID array.
function LModManager:getReloadQueue() end

--- Returns whether any circular dependency cycles exist.
---@return boolean Returns whether dependency cycles exist.
function LModManager:hasCircularDependencies() end

--- Returns whether a mod with the given ID is registered.
---@param mod_id string Mod identifier to check.
---@return boolean Returns whether the mod exists.
function LModManager:hasMod(mod_id) end

--- Marks a registered mod for hot-reload.
---@param mod_id string Mod identifier to queue.
---@return boolean Returns whether the mod was queued.
function LModManager:markForReload(mod_id) end

--- Registers a mod from its mod userdata.
---@param mod_ud LMod Mod userdata to register.
---@return nil No value is returned.
function LModManager:registerMod(mod_ud) end

--- Scans a directory for mods with `mod.toml` and registers them.
---@param path string Directory path to scan.
---@return table Returns the discovered mod info array.
function LModManager:scanFolder(path) end

--- Sets an explicit load order from an array of mod ID strings.
---@param order table Array of mod IDs in load order.
---@return nil No value is returned.
function LModManager:setLoadOrder(order) end

--- Returns the type name of this object.
---@return string Returns the Lua-visible type name.
function LModManager:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean Returns whether the object matches the type name.
function LModManager:typeOf(name) end

--- Removes a mod by ID and returns whether it was found.
---@param mod_id string Mod identifier to remove.
---@return boolean Returns whether the mod was removed.
function LModManager:unregisterMod(mod_id) end

--- Returns an array of mod IDs with missing dependencies.
---@return table Returns the missing dependency ID array.
function LModManager:validateDependencies() end

--- Checks whether a mod's required `api_version` is compatible with the given `host_version`.
---@param mod_ud LMod Mod userdata to validate.
---@param host_version string Host API version string.
---@return boolean True when the mod is compatible with the host API version.
---@return string Incompatibility error message.
lurek.mods.checkApiVersion = function(mod_ud, host_version) end

--- Creates a new Mod from an info table with at least an `id` field.
---@param info table Mod info table.
---@return LMod Returns the new mod userdata.
lurek.mods.newMod = function(info) end

--- Creates a new empty ModManager.
---@return LModManager Returns the new mod manager userdata.
lurek.mods.newModManager = function() end

--- Creates a new empty ContentRegistry for mod-contributed assets.
---@return LContentRegistry Returns the new content registry userdata.
lurek.mods.newRegistry = function() end

---@class lurek.network
lurek.network = {}

--- Lua-side wrapper around [`NetworkHost`].
---@class LNetworkHost
LNetworkHost = {}

--- Broadcasts data to all connected peers on a channel.
---@param channel_id integer Channel index for the packet.
---@param data string Raw payload bytes.
---@param reliable? boolean Whether to send reliably.
---@return nil No value is returned.
function LNetworkHost:broadcast(channel_id, data, reliable) end

--- Initiates a connection to a remote host, returning the peer ID.
---@param addr string Remote address in `host:port` format.
---@param channels? integer Number of channels to open.
---@param data? integer Optional connection data value.
---@return integer Peer ID for the new connection.
function LNetworkHost:connect(addr, channels, data) end

--- Destroys the host, closing the underlying socket.
---@return nil No value is returned.
function LNetworkHost:destroy() end

--- Gracefully disconnects a peer.
---@param peer_id integer Peer ID to disconnect.
---@param data? integer Optional disconnect data value.
---@return nil No value is returned.
function LNetworkHost:disconnect(peer_id, data) end

--- Disconnects a peer after all queued packets have been sent.
---@param peer_id integer Peer ID to disconnect.
---@param data? integer Optional disconnect data value.
---@return nil No value is returned.
function LNetworkHost:disconnectLater(peer_id, data) end

--- Immediately disconnects a peer without handshake.
---@param peer_id integer Peer ID to disconnect.
---@param data? integer Optional disconnect data value.
---@return nil No value is returned.
function LNetworkHost:disconnectNow(peer_id, data) end

--- Flushes all pending sends immediately.
---@return nil No value is returned.
function LNetworkHost:flush() end

--- Returns the local bind address as a string.
---@return string Local bind address.
function LNetworkHost:getAddress() end

--- Returns the bandwidth limits as a table with incoming and outgoing fields.
---@return table Table with `incoming` and `outgoing` fields.
function LNetworkHost:getBandwidthLimit() end

--- Returns the maximum number of channels per connection.
---@return integer Maximum number of channels per connection.
function LNetworkHost:getChannelLimit() end

--- Returns the number of currently connected peers.
---@return integer Number of currently connected peers.
function LNetworkHost:getConnectedPeerCount() end

--- Returns a table of connected peer IDs.
---@return table Array of connected peer IDs.
function LNetworkHost:getConnectedPeerIds() end

--- Returns the remote address of a peer, or nil if unavailable.
---@param peer_id integer Peer ID to inspect.
---@return string Remote address string, or nil if unavailable.
function LNetworkHost:getPeerAddress(peer_id) end

--- Returns the maximum number of peer slots.
---@return integer Maximum number of peer slots.
function LNetworkHost:getPeerLimit() end

--- Returns the connection state of a peer as a string.
---@param peer_id integer Peer ID to inspect.
---@return string Connection state name.
function LNetworkHost:getPeerState(peer_id) end

--- Returns a statistics table for a peer.
---@param peer_id integer Peer ID to inspect.
---@return table Statistics table for the peer.
function LNetworkHost:getPeerStats(peer_id) end

--- Returns the multiplayer role of this host ("server", "client", or "host").
---@return string Multiplayer role name.
function LNetworkHost:getRole() end

--- Returns the round-trip time estimate for a peer in milliseconds.
---@param peer_id integer Peer ID to inspect.
---@return number Estimated round-trip time in milliseconds.
function LNetworkHost:getRoundTripTime(peer_id) end

--- Returns true if this host was created as a client.
---@return boolean Whether this host is a client.
function LNetworkHost:isClient() end

--- Returns true if the host has been destroyed.
---@return boolean Whether the host has been destroyed.
function LNetworkHost:isDestroyed() end

--- Returns true if this host was created as a server.
---@return boolean Whether this host is a server.
function LNetworkHost:isServer() end

--- Sends a ping to a peer to measure round-trip time.
---@param peer_id integer Peer ID to ping.
---@return nil No value is returned.
function LNetworkHost:ping(peer_id) end

--- Resets a peer connection immediately without notifying the remote side.
---@param peer_id integer Peer ID to reset.
---@return nil No value is returned.
function LNetworkHost:resetPeer(peer_id) end

--- Sends data to a specific peer on a channel.
---@param peer_id integer Peer ID to send to.
---@param channel_id integer Channel index for the packet.
---@param data string Raw payload bytes.
---@param reliable? boolean Whether to send reliably.
---@return nil No value is returned.
function LNetworkHost:send(peer_id, channel_id, data, reliable) end

--- Polls the network for one event, returning an event table or nil.
---@return table Event table, or nil if no event is available.
function LNetworkHost:service() end

--- Sets the bandwidth limits in bytes per second.
---@param incoming? integer Incoming bandwidth limit in bytes per second.
---@param outgoing? integer Outgoing bandwidth limit in bytes per second.
---@return nil No value is returned.
function LNetworkHost:setBandwidthLimit(incoming, outgoing) end

--- Sets the channel limit for future connections.
---@param limit integer New channel limit.
---@return nil No value is returned.
function LNetworkHost:setChannelLimit(limit) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LNetworkHost:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean Whether this object matches the given type.
function LNetworkHost:typeOf(name) end

--- Lua-side wrapper around [`NetworkRuntime`] for async HTTP/TCP/WebSocket.
---@class LNetworkRuntime
LNetworkRuntime = {}

--- Convenience: sends an HTTP GET request.
---@param url string Request URL.
---@param headers? table Optional header table.
---@return integer Request ID.
function LNetworkRuntime:httpGet(url, headers) end

--- Convenience: sends an HTTP POST request.
---@param url string Request URL.
---@param body string Request body string.
---@param headers? table Optional header table.
---@return integer Request ID.
function LNetworkRuntime:httpPost(url, body, headers) end

--- Sends an HTTP request asynchronously. Poll with `poll()` for the response.
---@param opts table Request options table with `method`, `url`, `headers?`, `body?`, and `timeout?` fields.
---@return integer Request ID.
function LNetworkRuntime:httpRequest(opts) end

--- Polls for completed async responses (HTTP, TCP events, WebSocket events).
---@return table Array of response or event tables, or an empty table if none are ready.
function LNetworkRuntime:poll() end

--- Shuts down the background network thread.
---@return nil No value is returned.
function LNetworkRuntime:shutdown() end

--- Closes the TCP connection identified by the given connection handle.
---@param id integer Connection ID.
---@return nil No value is returned.
function LNetworkRuntime:tcpClose(id) end

--- Opens a TCP connection to a remote address.
---@param addr string Remote address in `host:port` format.
---@return integer Connection ID.
function LNetworkRuntime:tcpConnect(addr) end

--- Sends data over a TCP connection.
---@param id integer Connection ID.
---@param data string Raw payload bytes.
---@return nil No value is returned.
function LNetworkRuntime:tcpSend(id, data) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LNetworkRuntime:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean Whether this object matches the given type.
function LNetworkRuntime:typeOf(name) end

--- Closes a WebSocket connection.
---@param id integer Connection ID.
---@return nil No value is returned.
function LNetworkRuntime:wsClose(id) end

--- Opens a WebSocket connection.
---@param url string WebSocket URL.
---@return integer Connection ID.
function LNetworkRuntime:wsConnect(url) end

--- Sends a text message over a WebSocket connection.
---@param id integer Connection ID.
---@param data string Text payload.
---@return nil No value is returned.
function LNetworkRuntime:wsSend(id, data) end

--- Creates a LobbyInfo record and broadcasts it once on the local network.
---@param name string Lobby name.
---@param port integer Port advertised for the lobby.
---@param player_count? integer Current player count.
---@param max_players? integer Maximum player count.
---@return table Lobby table with `name`, `host`, `port`, `player_count`, and `max_players` fields.
lurek.network.createLobby = function(name, port, player_count, max_players) end

--- Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
---@param timeout_ms? integer Listen timeout in milliseconds.
---@return table Array of lobby tables with `name`, `host`, `port`, `player_count`, and `max_players` fields.
lurek.network.discoverLobbies = function(timeout_ms) end

--- Creates a client host that connects to a remote server.
---@param opts table Options table with `addr`, `channels?`, and `data?` fields.
---@return LNetworkHost New client host wrapper.
lurek.network.newClient = function(opts) end

--- Creates a new network host bound to the given address.
---@param opts table Options table with `addr?`, `maxPeers?`, `peers?`, `channels?`, `inBandwidth?`, and `outBandwidth?` fields.
---@return LNetworkHost New network host wrapper.
lurek.network.newHost = function(opts) end

--- Creates a background network runtime for async HTTP, TCP, and WebSocket.
---@return LNetworkRuntime New async network runtime wrapper.
lurek.network.newRuntime = function() end

--- Creates a server host that binds to a port and accepts connections.
---@param opts table Options table with `port`, `maxPeers?`, `peers?`, and `channels?` fields.
---@return LNetworkHost New server host wrapper.
lurek.network.newServer = function(opts) end

--- Serializes a Lua value to a binary MessagePack string.
---@param value LuaValue Lua value to serialize.
---@return string Binary MessagePack payload.
lurek.network.pack = function(value) end

--- Convenience helper: packs an entity snapshot and broadcasts it to all peers.
---@param host LNetworkHost Host wrapper used to broadcast the snapshot.
---@param entity_id integer Entity ID to include in the envelope.
---@param data table MessagePack-serializable entity data table.
---@param channel? integer Channel index to use.
---@param reliable? boolean Whether to send reliably.
---@return nil No value is returned.
lurek.network.syncEntity = function(host, entity_id, data, channel, reliable) end

--- Deserializes a MessagePack binary string back to a Lua value.
---@param data string Binary MessagePack payload.
---@return LuaValue Deserialized Lua value.
lurek.network.unpack = function(data) end

---@class lurek.parallax
lurek.parallax = {}

--- Lua-side handle to a single parallax background layer.
---@class LParallaxLayer
LParallaxLayer = {}

--- Removes scroll clamping so the layer scrolls freely.
---@return nil No value is returned.
function LParallaxLayer:clearClamp() end

--- Returns the autoscroll velocity as `(vx, vy)`.
---@return number Horizontal autoscroll velocity.
---@return number Vertical autoscroll velocity.
function LParallaxLayer:getAutoscroll() end

--- Returns the current blend mode as a string.
---@return string Returns the current blend mode string.
function LParallaxLayer:getBlendMode() end

--- Returns the current floating-point depth.
---@return number Returns the floating-point depth value.
function LParallaxLayer:getDepth() end

--- Returns the static offset as `(x, y)`.
---@return number Horizontal offset.
---@return number Vertical offset.
function LParallaxLayer:getOffset() end

--- Returns the current opacity.
---@return number Returns the current opacity value.
function LParallaxLayer:getOpacity() end

--- Returns the scroll factor as `(x, y)`.
---@return number Horizontal scroll factor.
---@return number Vertical scroll factor.
function LParallaxLayer:getScrollFactor() end

--- Returns `true` if seamless infinite tiling is enabled.
---@return boolean Returns whether seamless tiling is enabled.
function LParallaxLayer:getTiling() end

--- Returns the current tint as `(r, g, b, a)`.
---@return number Tint red component.
---@return number Tint green component.
---@return number Tint blue component.
---@return number Tint alpha component.
function LParallaxLayer:getTint() end

--- Returns the draw-order depth.
---@return integer Returns the integer draw-order depth.
function LParallaxLayer:getZ() end

--- Returns `true` if the layer is currently visible.
---@return boolean Returns whether the layer is visible.
function LParallaxLayer:isVisible() end

--- Draws the layer using an explicit camera world position.
---@param cam_x number Camera world X position.
---@param cam_y number Camera world Y position.
---@return nil No value is returned.
function LParallaxLayer:render(cam_x, cam_y) end

--- Draws the layer using the engine active camera position automatically.
---@return nil No value is returned.
function LParallaxLayer:renderAuto() end

--- Resets the autonomous scroll accumulator to zero.
---@return nil No value is returned.
function LParallaxLayer:resetAutoscroll() end

--- Sets the autonomous scroll velocity in world-pixels per second.
---@param vx number Horizontal autoscroll velocity.
---@param vy number Vertical autoscroll velocity.
---@return nil No value is returned.
function LParallaxLayer:setAutoscroll(vx, vy) end

--- Sets the GPU blend mode for this layer.
---@param mode string Blend mode string such as `normal`, `additive`, or `multiply`.
---@return nil No value is returned.
function LParallaxLayer:setBlendMode(mode) end

--- Clamps the scroll offset to a world-pixel range on each axis.
---@param min_x number Minimum horizontal offset.
---@param min_y number Minimum vertical offset.
---@param max_x number Maximum horizontal offset.
---@param max_y number Maximum vertical offset.
---@return nil No value is returned.
function LParallaxLayer:setClamp(min_x, min_y, max_x, max_y) end

--- Sets the floating-point draw depth for fine-grained layer ordering.
---@param z number Floating-point depth value.
---@return nil No value is returned.
function LParallaxLayer:setDepth(z) end

--- Sets the static world-pixel position bias added on top of camera scroll.
---@param x number Horizontal offset in world pixels.
---@param y number Vertical offset in world pixels.
---@return nil No value is returned.
function LParallaxLayer:setOffset(x, y) end

--- Sets the layer-wide opacity override in `[0.0, 1.0]`.
---@param a number Opacity value in the range `[0.0, 1.0]`.
---@return nil No value is returned.
function LParallaxLayer:setOpacity(a) end

--- Sets whether the layer tiles on the X and Y axes.
---@param repeat_x boolean Whether the layer repeats on the X axis.
---@param repeat_y boolean Whether the layer repeats on the Y axis.
---@return nil No value is returned.
function LParallaxLayer:setRepeat(repeat_x, repeat_y) end

--- Sets the texture display scale factor on each axis.
---@param sx number Horizontal scale factor.
---@param sy number Vertical scale factor.
---@return nil No value is returned.
function LParallaxLayer:setScale(sx, sy) end

--- Sets the scroll factor relative to camera movement on each axis.
---@param x number Horizontal scroll factor.
---@param y number Vertical scroll factor.
---@return nil No value is returned.
function LParallaxLayer:setScrollFactor(x, y) end

--- Sets explicit tile dimensions in logical pixels.
---@param w number Tile width in logical pixels.
---@param h number Tile height in logical pixels.
---@return nil No value is returned.
function LParallaxLayer:setTileSize(w, h) end

--- Enables or disables seamless infinite tiling on both axes simultaneously.
---@param enabled boolean Whether seamless tiling should be enabled.
---@return nil No value is returned.
function LParallaxLayer:setTiling(enabled) end

--- Sets the multiplicative RGBA tint applied to all pixels of this layer.
---@param r number Red tint component.
---@param g number Green tint component.
---@param b number Blue tint component.
---@param a number Alpha tint component.
---@return nil No value is returned.
function LParallaxLayer:setTint(r, g, b, a) end

--- Shows or hides this layer.
---@param visible boolean Whether the layer should be visible.
---@return nil No value is returned.
function LParallaxLayer:setVisible(visible) end

--- Sets the draw-order depth. Lower values render first (further back).
---@param z integer Integer draw-order depth.
---@return nil No value is returned.
function LParallaxLayer:setZ(z) end

--- Returns the type name of this object.
---@return string Returns the Lua-visible type name.
function LParallaxLayer:type() end

--- Advances the autonomous scroll accumulator by `dt` seconds.
---@param dt number Elapsed time in seconds.
---@return nil No value is returned.
function LParallaxLayer:update(dt) end

--- Lua-side container that groups `LuaParallaxLayer` objects for scene-level management.
---@class LParallaxSet
LParallaxSet = {}

--- Adds a layer to this set.
---@param layer LParallaxLayer Layer userdata to add.
---@return nil No value is returned.
function LParallaxSet:addLayer(layer) end

--- Returns the name of this set.
---@return string Returns the set name.
function LParallaxSet:getName() end

--- Returns `true` if the set is currently visible.
---@return boolean Returns whether the set is visible.
function LParallaxSet:isVisible() end

--- Returns the number of layers in this set.
---@return integer Returns the number of layers in the set.
function LParallaxSet:layerCount() end

--- Removes the layer at the given 1-based index.
---@param index integer One-based layer index.
---@return boolean Returns whether a layer was removed.
function LParallaxSet:removeLayerAt(index) end

--- Draws all visible layers in ascending `z` order using an explicit camera position.
---@param cam_x number Camera world X position.
---@param cam_y number Camera world Y position.
---@return nil No value is returned.
function LParallaxSet:render(cam_x, cam_y) end

--- Draws all visible layers using the engine active camera position.
---@return nil No value is returned.
function LParallaxSet:renderAuto() end

--- Sets the name of this set.
---@param name string New set name.
---@return nil No value is returned.
function LParallaxSet:setName(name) end

--- Shows or hides all layers in this set.
---@param visible boolean Whether the set should be visible.
---@return nil No value is returned.
function LParallaxSet:setVisible(visible) end

--- Re-sorts all layers by ascending `z` value.
---@return nil No value is returned.
function LParallaxSet:sortByZ() end

--- Returns the type name of this object.
---@return string Returns the Lua-visible type name.
function LParallaxSet:type() end

--- Advances the autoscroll accumulator of every layer by `dt` seconds.
---@param dt number Elapsed time in seconds.
---@return nil No value is returned.
function LParallaxSet:update(dt) end

--- Creates a new parallax background layer from an options table.
---@param opts table Layer options including a required `texture` field.
---@return LParallaxLayer Returns the new parallax layer userdata.
lurek.parallax.newLayer = function(opts) end

--- Creates a new empty parallax set with the given name.
---@param name string Name assigned to the new set.
---@return LParallaxSet Returns the new parallax set userdata.
lurek.parallax.newSet = function(name) end

---@class lurek.particle
lurek.particle = {}

--- Lua-side handle to a particle system stored in SharedState.
---@class LParticleSystem
LParticleSystem = {}

--- Adds a gravity well that pulls (positive strength) or repels
---@param x number X position.
---@param y number Y position.
---@param strength number Strength value.
---@param radius number Radius value.
---@return nil No value is returned.
function LParticleSystem:addAttractor(x, y, strength, radius) end

--- Attaches a sub-emitter that bursts when a particle dies.
---@param config_tbl table Configuration table.
---@param burst_count? number Burst particle count.
---@return nil No value is returned.
function LParticleSystem:addSubEmitter(config_tbl, burst_count) end

--- Adds a child emitter that updates and renders with this system.
---@param config table same format as lurek.particle.newSystem config.
---@return integer integer  1-based index of the new sub-system.
function LParticleSystem:addSubSystem(config) end

--- Removes all attractors from this particle system.
---@return nil No value is returned.
function LParticleSystem:clearAttractors() end

--- Removes the bounding rectangle so particles can move freely.
---@return nil No value is returned.
function LParticleSystem:clearBounds() end

--- Creates a copy of this particle system (config only, no live particles).
---@return LParticleSystem New copy of this particle system (config only, no live particles).
function LParticleSystem:clone() end

--- Returns the number of living particles.
---@return integer Number of living particles.
function LParticleSystem:count() end

--- Renders all live particles to a CPU ImageData.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return LImageData Image data object.
function LParticleSystem:drawToImage(width, height) end

--- Emits a burst of the given number of particles.
---@param count integer Number of particles to emit.
---@return nil No value is returned.
function LParticleSystem:emit(count) end

--- Returns the number of attractors currently registered on this system.
---@return integer Number of attractors currently registered on this system.
function LParticleSystem:getAttractorCount() end

--- Returns the maximum particle count.
---@return integer Maximum particle capacity.
function LParticleSystem:getBufferSize() end

--- Returns color keyframes as a table of {r,g,b,a} tables.
---@return table Table of color keyframes as {r, g, b, a} entries.
function LParticleSystem:getColors() end

--- Returns the number of living particles (alias for count).
---@return integer Number of living particles.
function LParticleSystem:getCount() end

--- Returns emission direction in radians.
---@return number Emission direction in radians.
function LParticleSystem:getDirection() end

--- Returns emission area: dist-string, w, h.
---@return nil No value is returned.
function LParticleSystem:getEmissionArea() end

--- Returns particles emitted per second.
---@return number Particles emitted per second.
function LParticleSystem:getEmissionRate() end

--- Returns the emitter lifetime.
---@return number Emitter lifetime in seconds. Negative values mean infinite.
function LParticleSystem:getEmitterLifetime() end

--- Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
---@return nil No value is returned.
function LParticleSystem:getFlipbook() end

--- Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
---@return number Gravity X acceleration.
---@return number Gravity Y acceleration.
function LParticleSystem:getGravity() end

--- Returns the insert mode as a string.
---@return string Insert mode string.
function LParticleSystem:getInsertMode() end

--- Returns linear acceleration range.
---@return number Minimum X acceleration.
---@return number Minimum Y acceleration.
---@return number Maximum X acceleration.
---@return number Maximum Y acceleration.
function LParticleSystem:getLinearAcceleration() end

--- Returns linear damping range.
---@return number Minimum linear damping.
---@return number Maximum linear damping.
function LParticleSystem:getLinearDamping() end

--- Returns the render origin offset.
---@return number Render origin X offset.
---@return number Render origin Y offset.
function LParticleSystem:getOffset() end

--- Returns min and max particle lifetime.
---@return number Minimum particle lifetime.
---@return number Maximum particle lifetime.
function LParticleSystem:getParticleLifetime() end

--- Returns the emitter world position.
---@return number Emitter world X position.
---@return number Emitter world Y position.
function LParticleSystem:getPosition() end

--- Returns radial acceleration range.
---@return number Minimum radial acceleration.
---@return number Maximum radial acceleration.
function LParticleSystem:getRadialAcceleration() end

--- Returns initial rotation range.
---@return number Minimum initial rotation.
---@return number Maximum initial rotation.
function LParticleSystem:getRotation() end

--- Returns the particle draw shape as a string.
---@return string Particle draw shape string.
function LParticleSystem:getShape() end

--- Returns the maximum random size variation applied to newly emitted particles.
---@return number Maximum random size variation for new particles.
function LParticleSystem:getSizeVariation() end

--- Returns size keyframes as a Lua table.
---@return table Table of size keyframes.
function LParticleSystem:getSizes() end

--- Returns min/max initial speed.
---@return number Minimum initial speed.
---@return number Maximum initial speed.
function LParticleSystem:getSpeed() end

--- Returns angular velocity range.
---@return number Minimum angular velocity.
---@return number Maximum angular velocity.
function LParticleSystem:getSpin() end

--- Returns the maximum random angular velocity variation for new particles.
---@return number Maximum random angular velocity variation for new particles.
function LParticleSystem:getSpinVariation() end

--- Returns the half-angle spread in radians for the emission cone.
---@return number Half-angle spread in radians for the emission cone.
function LParticleSystem:getSpread() end

--- Returns tangential acceleration range.
---@return number Minimum tangential acceleration.
---@return number Maximum tangential acceleration.
function LParticleSystem:getTangentialAcceleration() end

--- Returns whether relative rotation is enabled.
---@return boolean Whether particle rotation follows velocity direction.
function LParticleSystem:hasRelativeRotation() end

--- Returns true if the emitter is currently emitting or has live particles.
---@return boolean Whether the emitter is currently emitting or has live particles.
function LParticleSystem:isActive() end

--- Returns true if there are no live particles.
---@return boolean Whether there are no live particles.
function LParticleSystem:isEmpty() end

--- Returns true if the system has reached max_particles.
---@return boolean Whether the system has reached max_particles.
function LParticleSystem:isFull() end

--- Returns true if the emitter is paused.
---@return boolean Whether the emitter is paused.
function LParticleSystem:isPaused() end

--- Returns true if the emitter is stopped.
---@return boolean Whether the emitter is stopped.
function LParticleSystem:isStopped() end

--- Moves the emitter to the given world position.
---@param x number X position.
---@param y number Y position.
---@return nil No value is returned.
function LParticleSystem:moveTo(x, y) end

--- Pauses particle emission; existing particles continue to simulate.
---@return nil No value is returned.
function LParticleSystem:pause() end

--- Removes the particle system from the engine, freeing its slot.
---@return nil No value is returned.
function LParticleSystem:release() end

--- Renders all live particles to the GPU command queue.
---@param ox? number World X offset added to every particle (default 0).
---@param oy? number World Y offset added to every particle (default 0).
---@return nil No value is returned.
function LParticleSystem:render(ox, oy) end

--- Removes all particles and resets the emitter.
---@return nil No value is returned.
function LParticleSystem:reset() end

--- Resumes a paused emitter.
---@return nil No value is returned.
function LParticleSystem:resume() end

--- Constrains all particles to an axis-aligned bounding rectangle.
---@param xmin number Minimum X bound.
---@param xmax number Maximum X bound.
---@param ymin number Minimum Y bound.
---@param ymax number Maximum Y bound.
---@param restitution number Bounce restitution.
---@return nil No value is returned.
function LParticleSystem:setBounds(xmin, xmax, ymin, ymax, restitution) end

--- Sets the maximum number of particles (resizes the pool).
---@param n integer Maximum particle capacity.
---@return nil No value is returned.
function LParticleSystem:setBufferSize(n) end

--- Sets color keyframes. Each arg is a table {r, g, b, a}.
---@param ... table Variadic values value.
---@return nil No value is returned.
function LParticleSystem:setColors(...) end

--- Sets a Lua function that returns (offset_x, offset_y) for each newly spawned
---@param fn function () -> number, number.
---@return nil No value is returned.
function LParticleSystem:setCustomEmissionShape(fn) end

--- Sets emission direction in radians.
---@param dir number Direction angle.
---@return nil No value is returned.
function LParticleSystem:setDirection(dir) end

--- Sets emission area distribution and size.
---@param dist string "none"|"uniform"|"normal"|"ellipse"|"borderellipse"|"borderrectangle".
---@param w number Width value.
---@param h number Height value.
---@param angle? number Angle in radians.
---@param dir_relative? boolean Dir relative value.
---@return nil No value is returned.
function LParticleSystem:setEmissionArea(dist, w, h, angle, dir_relative) end

--- Sets particles emitted per second.
---@param rate number Emission rate.
---@return nil No value is returned.
function LParticleSystem:setEmissionRate(rate) end

--- Sets how long the emitter runs before auto-stopping. Negative = infinite.
---@param t number Terminal userdata.
---@return nil No value is returned.
function LParticleSystem:setEmitterLifetime(t) end

--- Configures sprite-sheet flipbook animation by dividing the texture into a grid.
---@param cols number columns in the sprite sheet.
---@param rows number rows in the sprite sheet.
---@param fps number animation speed in frames per second.
---@return nil No value is returned.
function LParticleSystem:setFlipbook(cols, rows, fps) end

--- Sets the gravity acceleration applied to all active particles each frame.
---@param gx number Gravity X component.
---@param gy number Gravity Y component.
---@return nil No value is returned.
function LParticleSystem:setGravity(gx, gy) end

--- Sets the insert mode: "top", "bottom", or "random".
---@param mode string Mode name.
---@return nil No value is returned.
function LParticleSystem:setInsertMode(mode) end

--- Sets linear acceleration range.
---@param xmin number Minimum X bound.
---@param ymin number Minimum Y bound.
---@param xmax number Maximum X bound.
---@param ymax number Maximum Y bound.
---@return nil No value is returned.
function LParticleSystem:setLinearAcceleration(xmin, ymin, xmax, ymax) end

--- Sets linear damping range.
---@param min number Minimum value.
---@param max number Maximum value.
---@return nil No value is returned.
function LParticleSystem:setLinearDamping(min, max) end

--- Sets the render origin offset.
---@param ox number Origin X offset.
---@param oy number Origin Y offset.
---@return nil No value is returned.
function LParticleSystem:setOffset(ox, oy) end

--- Sets a Lua function called after each update() with all particles that died
---@param fn function (batch: table) -> nil.
---@return nil No value is returned.
function LParticleSystem:setOnDeathBatch(fn) end

--- Sets min and max particle lifetime in seconds.
---@param min number Minimum value.
---@param max number Maximum value.
---@return nil No value is returned.
function LParticleSystem:setParticleLifetime(min, max) end

--- Sets the emitter world position.
---@param x number X position.
---@param y number Y position.
---@return nil No value is returned.
function LParticleSystem:setPosition(x, y) end

--- Sets radial acceleration range.
---@param min number Minimum value.
---@param max number Maximum value.
---@return nil No value is returned.
function LParticleSystem:setRadialAcceleration(min, max) end

--- Sets whether particle rotation follows velocity direction.
---@param v boolean Value to set.
---@return nil No value is returned.
function LParticleSystem:setRelativeRotation(v) end

--- Sets initial rotation range in radians.
---@param min number Minimum value.
---@param max number Maximum value.
---@return nil No value is returned.
function LParticleSystem:setRotation(min, max) end

--- Sets the particle draw shape.
---@param shape string "square"|"circle"|"triangle"|"spark"|"diamond"|"shrapnel"|"ray"|"puff"|"ring"|"capsule".
---@return nil No value is returned.
function LParticleSystem:setShape(shape) end

--- Sets size variation (0-1).
---@param v number Value to set.
---@return nil No value is returned.
function LParticleSystem:setSizeVariation(v) end

--- Sets size keyframes (varargs: each number is one keyframe).
---@param ... number Variadic values value.
---@return nil No value is returned.
function LParticleSystem:setSizes(...) end

--- Sets min/max initial speed.
---@param min number Minimum value.
---@param max number Maximum value.
---@return nil No value is returned.
function LParticleSystem:setSpeed(min, max) end

--- Sets angular velocity range.
---@param min number Minimum value.
---@param max number Maximum value.
---@return nil No value is returned.
function LParticleSystem:setSpin(min, max) end

--- Sets spin variation (0-1).
---@param v number Value to set.
---@return nil No value is returned.
function LParticleSystem:setSpinVariation(v) end

--- Sets emission spread (half-angle cone) in radians.
---@param spread number Spread angle.
---@return nil No value is returned.
function LParticleSystem:setSpread(spread) end

--- Sets tangential acceleration range.
---@param min number Minimum value.
---@param max number Maximum value.
---@return nil No value is returned.
function LParticleSystem:setTangentialAcceleration(min, max) end

--- Starts or restarts particle emission.
---@return nil No value is returned.
function LParticleSystem:start() end

--- Stops particle emission immediately.
---@return nil No value is returned.
function LParticleSystem:stop() end

--- Returns the number of direct child sub-systems attached to this emitter.
---@return integer integer.
function LParticleSystem:subSystemCount() end

--- Alias for `drawToImage`. Renders all live particles to a CPU ImageData.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return LImageData Image data object.
function LParticleSystem:toImage(width, height) end

--- Returns the type name "ParticleSystem".
---@return string Always "LParticleSystem".
function LParticleSystem:type() end

--- Returns true if this matches the given type name.
---@param name string Name string.
---@return boolean True if name matches ParticleSystem, Drawable, or Object.
function LParticleSystem:typeOf(name) end

--- Advances the particle simulation by dt seconds.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LParticleSystem:update(dt) end

--- Pre-simulates the particle system for `seconds` so it appears fully
---@param seconds number Duration in seconds.
---@return nil No value is returned.
function LParticleSystem:warmUp(seconds) end

--- Lua-side wrapper around a [`Trail`] ribbon effect.
---@class LTrail
LTrail = {}

--- Removes all trail points.
---@return nil No value is returned.
function LTrail:clear() end

--- Renders the trail ribbon to a CPU ImageData.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return ImageData Image data object.
function LTrail:drawToImage(width, height) end

--- Returns the trail point lifetime in seconds.
---@return number Trail point lifetime in seconds.
function LTrail:getLifetime() end

--- Returns the number of active trail points.
---@return integer Number of active trail points.
function LTrail:getPointCount() end

--- Returns the start and end width.
---@return number Start width.
---@return number End width.
function LTrail:getWidth() end

--- Appends a new point to the trail head.
---@param x number X position.
---@param y number Y position.
---@return nil No value is returned.
function LTrail:pushPoint(x, y) end

--- Sets the colour at the newest end of the trail.
---@param r number Red component.
---@param g number Green component.
---@param b number Blue component.
---@param a number Alpha component.
---@return nil No value is returned.
function LTrail:setHeadColor(r, g, b, a) end

--- Sets how long each trail point persists in seconds.
---@param lifetime number Lifetime in seconds.
---@return nil No value is returned.
function LTrail:setLifetime(lifetime) end

--- Sets the minimum distance between trail points.
---@param distance number Distance value.
---@return nil No value is returned.
function LTrail:setMinDistance(distance) end

--- Sets the colour at the oldest end of the trail.
---@param r number Red component.
---@param g number Green component.
---@param b number Blue component.
---@param a number Alpha component.
---@return nil No value is returned.
function LTrail:setTailColor(r, g, b, a) end

--- Sets the start and end width of the trail ribbon.
---@param start_width number Starting width.
---@param end_width? number Ending width.
---@return nil No value is returned.
function LTrail:setWidth(start_width, end_width) end

--- Returns the type name of this object.
---@return string Always "LTrail".
function LTrail:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True if name matches LTrail or Object.
function LTrail:typeOf(name) end

--- Ages trail points and removes expired ones.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LTrail:update(dt) end

--- Creates a new particle system from a TOML config file.
---@param path string Path to the TOML config file.
---@return LParticleSystem New particle system from a TOML config file.
lurek.particle.fromTOML = function(path) end

--- Creates a new particle system and stores it in the engine pool.
---@param config? table Configuration table.
---@return LParticleSystem New particle system and stores it in the engine pool.
lurek.particle.newSystem = function(config) end

--- Creates a new trail ribbon effect.
---@param lifetime number Lifetime in seconds.
---@param start_width number Starting width.
---@return LTrail New trail ribbon effect.
lurek.particle.newTrail = function(lifetime, start_width) end

-- Flat forwarding: lurek.particle.METHOD(ps,...) == ps:METHOD(...)
lurek.particle.addAttractor = LParticleSystem.addAttractor
lurek.particle.addSubEmitter = LParticleSystem.addSubEmitter
lurek.particle.addSubSystem = LParticleSystem.addSubSystem
lurek.particle.clearAttractors = LParticleSystem.clearAttractors
lurek.particle.clearBounds = LParticleSystem.clearBounds
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

--- Lua-side wrapper around a PathGrid-based [`AiFlowField`].
---@class LAIFlowField
LAIFlowField = {}

--- Returns the normalised direction toward the goal (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return number Normalized X direction component.
---@return number Normalized Y direction component.
function LAIFlowField:getDirection(x, y) end

--- Returns the BFS distance to the goal (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return number BFS distance to the goal.
function LAIFlowField:getDistance(x, y) end

--- Returns the goal cell (1-based coordinates) or nil if unset.
---@return integer 1-based goal cell X coordinate.
---@return integer 1-based goal cell Y coordinate.
function LAIFlowField:getGoal() end

--- Returns the flow field grid height in cells.
---@return integer Flow field height in cells.
function LAIFlowField:getHeight() end

--- Returns the flow field grid width in cells.
---@return integer Flow field width in cells.
function LAIFlowField:getWidth() end

--- Returns true if a goal has been set.
---@return boolean True when a goal is set.
function LAIFlowField:hasGoal() end

--- Sets the goal cell and triggers BFS recomputation (1-based coordinates).
---@param x integer 1-based goal cell X coordinate.
---@param y integer 1-based goal cell Y coordinate.
---@return nil No value is returned.
function LAIFlowField:setGoal(x, y) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LAIFlowField:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LAIFlowField:typeOf(name) end

--- Lua-side wrapper around a [`FlowField`].
---@class LFlowField
LFlowField = {}

--- Computes the flow field toward a single target (1-based coordinates).
---@param tx integer 1-based target cell X coordinate.
---@param ty integer 1-based target cell Y coordinate.
---@param unitSize? integer Optional unit footprint size in cells.
---@return nil No value is returned.
function LFlowField:calculate(tx, ty, unitSize) end

--- Computes the flow field toward multiple targets (1-based coordinates).
---@param targets table Target cell entries as `{x, y}` tables.
---@param unitSize? integer Optional unit footprint size in cells.
---@return nil No value is returned.
function LFlowField:calculateMulti(targets, unitSize) end

--- Returns the integrated cost to the nearest target (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return number Integrated cost to the nearest target.
function LFlowField:getCostToTarget(x, y) end

--- Returns the normalised direction vector at a cell (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return number Normalized X direction component.
---@return number Normalized Y direction component.
function LFlowField:getDirection(x, y) end

--- Returns the flow direction as an angle in radians (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return number Flow direction angle in radians.
function LFlowField:getDirectionAngle(x, y) end

--- Returns the target cells from the most recent computation (1-based coordinates).
---@return table Target cell entries as 1-based `{x, y}` tables.
function LFlowField:getTargets() end

--- Returns true if the flow field has been computed at least once.
---@return boolean True when the flow field has been computed.
function LFlowField:isCalculated() end

--- Converts a world-space position into a velocity vector via the flow field.
---@param wx number World-space X position.
---@param wy number World-space Y position.
---@param speed number Desired movement speed.
---@param tw number Tile width in world units.
---@param th number Tile height in world units.
---@return number Steering velocity X component.
---@return number Steering velocity Y component.
function LFlowField:steer(wx, wy, speed, tw, th) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LFlowField:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LFlowField:typeOf(name) end

--- Lua-side wrapper around a [`HexGrid`].
---@class LHexGrid
LHexGrid = {}

--- Hex-distance between two cells.
---@param col1 integer 1-based first column.
---@param row1 integer 1-based first row.
---@param col2 integer 1-based second column.
---@param row2 integer 1-based second row.
---@return integer Hex distance in cells.
function LHexGrid:distance(col1, row1, col2, row2) end

--- Returns all cells visible from origin within max_range (1-based coordinates).
---@param col integer 1-based origin column.
---@param row integer 1-based origin row.
---@param max_range integer Maximum visibility range in cells.
---@return table Visible cell entries as 1-based `{col, row}` tables.
function LHexGrid:fieldOfView(col, row, max_range) end

--- Find A* path between two cells (1-based coordinates).
---@param from_col integer 1-based start column.
---@param from_row integer 1-based start row.
---@param to_col integer 1-based goal column.
---@param to_row integer 1-based goal row.
---@return table Path entries as 1-based `{col, row}` tables.
function LHexGrid:findPath(from_col, from_row, to_col, to_row) end

--- Returns true if a cell is blocked (1-based coordinates).
---@param col integer 1-based cell column.
---@param row integer 1-based cell row.
---@return boolean True when the cell is blocked.
function LHexGrid:isBlocked(col, row) end

--- Returns true if there is an unobstructed line between two cells (1-based).
---@param from_col integer 1-based start column.
---@param from_row integer 1-based start row.
---@param to_col integer 1-based goal column.
---@param to_row integer 1-based goal row.
---@return boolean True when the line is unobstructed.
function LHexGrid:lineOfSight(from_col, from_row, to_col, to_row) end

--- Returns all cells reachable from origin within movement budget (1-based).
---@param col integer 1-based origin column.
---@param row integer 1-based origin row.
---@param budget number Movement budget to spend.
---@return table Reachable cell entries as 1-based `{col, row}` tables.
function LHexGrid:rangeOfMovement(col, row, budget) end

--- Mark/unmark a cell as blocked (1-based coordinates).
---@param col integer 1-based cell column.
---@param row integer 1-based cell row.
---@param blocked boolean Whether the cell should be blocked.
---@return nil No value is returned.
function LHexGrid:setBlocked(col, row, blocked) end

--- Set movement cost for a cell (1-based coordinates).
---@param col integer 1-based cell column.
---@param row integer 1-based cell row.
---@param cost number Movement cost to assign to the cell.
---@return nil No value is returned.
function LHexGrid:setCost(col, row, cost) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LHexGrid:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LHexGrid:typeOf(name) end

--- Lua-side wrapper around a [`JpsGrid`].
---@class LJpsGrid
LJpsGrid = {}

--- Find a JPS path between two cells (1-based coordinates).
---@param from_x integer 1-based start cell X coordinate.
---@param from_y integer 1-based start cell Y coordinate.
---@param to_x integer 1-based goal cell X coordinate.
---@param to_y integer 1-based goal cell Y coordinate.
---@return table Path entries as 1-based `{x, y}` tables.
function LJpsGrid:findPath(from_x, from_y, to_x, to_y) end

--- Returns true if the cell is blocked (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return boolean True when the cell is blocked.
function LJpsGrid:isBlocked(x, y) end

--- Mark/unmark a cell as blocked (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@param blocked boolean Whether the cell should be blocked.
---@return nil No value is returned.
function LJpsGrid:setBlocked(x, y, blocked) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LJpsGrid:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LJpsGrid:typeOf(name) end

--- Lua-side wrapper around a [`NavGrid`] with optional HPA★ abstract graph.
---@class LNavGrid
LNavGrid = {}

--- Clears all pending dirty rectangles.
---@return nil No value is returned.
function LNavGrid:clearDirty() end

--- Sets every cell to the given cost.
---@param cost integer Traversal cost to assign to every cell.
---@return nil No value is returned.
function LNavGrid:fill(cost) end

--- Sets all cells in a rectangle to the given cost (1-based coordinates).
---@param x integer 1-based rectangle origin X coordinate.
---@param y integer 1-based rectangle origin Y coordinate.
---@param w integer Rectangle width in cells.
---@param h integer Rectangle height in cells.
---@param cost integer Traversal cost to assign inside the rectangle.
---@return nil No value is returned.
function LNavGrid:fillRect(x, y, w, h, cost) end

--- Returns the current HPA★ chunk size.
---@return integer Chunk size in cells.
function LNavGrid:getChunkSize() end

--- Returns the traversal cost of a cell (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return integer Traversal cost for the cell.
function LNavGrid:getCost(x, y) end

--- Returns the current diagonal movement mode as a string.
---@return string Diagonal mode name.
function LNavGrid:getDiagonalMode() end

--- Returns the grid dimensions as width, height.
---@return integer Grid width in cells.
---@return integer Grid height in cells.
function LNavGrid:getDimensions() end

--- Returns the grid height in cells.
---@return integer Grid height in cells.
function LNavGrid:getHeight() end

--- Returns the grid width in cells.
---@return integer Grid width in cells.
function LNavGrid:getWidth() end

--- Returns true if the cell is blocked (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return boolean True when the cell is blocked.
function LNavGrid:isBlocked(x, y) end

--- Returns true if a unit footprint is fully walkable (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@param unitSize? integer Optional unit footprint size in cells.
---@return boolean True when the footprint can occupy the cell.
function LNavGrid:isWalkable(x, y, unitSize) end

--- Overwrites the grid from a raw byte string (row-major, one byte per cell).
---@param data string Serialized grid bytes in row-major order.
---@return nil No value is returned.
function LNavGrid:loadFromString(data) end

--- Rebuilds the HPA★ abstract graph from the current grid state.
---@return nil No value is returned.
function LNavGrid:rebuildAbstract() end

--- Exports the cost grid as a byte string (row-major, one byte per cell).
---@return string Serialized grid bytes in row-major order.
function LNavGrid:saveToString() end

--- Marks a cell as blocked or unblocked (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@param blocked boolean Whether the cell should be blocked.
---@return nil No value is returned.
function LNavGrid:setBlocked(x, y, blocked) end

--- Sets the HPA★ chunk size.
---@param size integer Chunk size in cells.
---@return nil No value is returned.
function LNavGrid:setChunkSize(size) end

--- Sets the traversal cost of a cell (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@param cost integer Traversal cost to assign to the cell.
---@return nil No value is returned.
function LNavGrid:setCost(x, y, cost) end

--- Sets the diagonal movement mode.
---@param mode string Diagonal mode name.
---@return nil No value is returned.
function LNavGrid:setDiagonalMode(mode) end

--- Records a dirty rectangle for incremental HPA★ updates (1-based coordinates).
---@param x integer 1-based dirty rectangle origin X coordinate.
---@param y integer 1-based dirty rectangle origin Y coordinate.
---@param w integer Dirty rectangle width in cells.
---@param h integer Dirty rectangle height in cells.
---@return nil No value is returned.
function LNavGrid:setDirty(x, y, w, h) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LNavGrid:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LNavGrid:typeOf(name) end

--- Lua-side wrapper around a [`PathGrid`] (A★ weighted grid with per-cell cost).
---@class LPathGrid
LPathGrid = {}

--- Finds an A★ path returning world-space waypoints (1-based coordinates).
---@param sx integer 1-based start cell X coordinate.
---@param sy integer 1-based start cell Y coordinate.
---@param gx integer 1-based goal cell X coordinate.
---@param gy integer 1-based goal cell Y coordinate.
---@return table World-space waypoint entries as `{x, y}` tables.
function LPathGrid:findPath(sx, sy, gx, gy) end

--- Finds a smoothed A★ path with string-pulling (1-based coordinates).
---@param sx integer 1-based start cell X coordinate.
---@param sy integer 1-based start cell Y coordinate.
---@param gx integer 1-based goal cell X coordinate.
---@param gy integer 1-based goal cell Y coordinate.
---@return table Smoothed world-space waypoint entries as `{x, y}` tables.
function LPathGrid:findPathSmoothed(sx, sy, gx, gy) end

--- Returns the world-space size of each cell.
---@return number Cell size in world units.
function LPathGrid:getCellSize() end

--- Returns the cost multiplier for a cell (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return number Cost multiplier for the cell.
function LPathGrid:getCost(x, y) end

--- Returns the grid height in cells.
---@return integer Grid height in cells.
function LPathGrid:getHeight() end

--- Returns the grid width in cells.
---@return integer Grid width in cells.
function LPathGrid:getWidth() end

--- Returns true if a cell is walkable (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@return boolean True when the cell is walkable.
function LPathGrid:isWalkable(x, y) end

--- Sets the cost multiplier for a cell (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@param cost number Cost multiplier to assign to the cell.
---@return nil No value is returned.
function LPathGrid:setCost(x, y, cost) end

--- Sets the walkability of a cell (1-based coordinates).
---@param x integer 1-based cell X coordinate.
---@param y integer 1-based cell Y coordinate.
---@param walkable boolean Whether the cell should be walkable.
---@return nil No value is returned.
function LPathGrid:setWalkable(x, y, walkable) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LPathGrid:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LPathGrid:typeOf(name) end

--- Lua-side wrapper around a [`UnitPathfinder`].
---@class LUnitPathfinder
LUnitPathfinder = {}

--- Removes all cached path results.
---@return nil No value is returned.
function LUnitPathfinder:clearCache() end

--- Finds the nearest walkable cell within a radius (1-based coordinates).
---@param x integer 1-based origin cell X coordinate.
---@param y integer 1-based origin cell Y coordinate.
---@param maxRadius integer Maximum search radius in cells.
---@param unitSize? integer Optional unit footprint size in cells.
---@return integer 1-based X coordinate of the nearest walkable cell.
---@return integer 1-based Y coordinate of the nearest walkable cell.
function LUnitPathfinder:findNearestWalkable(x, y, maxRadius, unitSize) end

--- Finds a partial path with a node expansion limit (1-based coordinates).
---@param x1 integer 1-based start cell X coordinate.
---@param y1 integer 1-based start cell Y coordinate.
---@param x2 integer 1-based goal cell X coordinate.
---@param y2 integer 1-based goal cell Y coordinate.
---@param maxNodes integer Maximum node expansions to allow.
---@param unitSize? integer Optional unit footprint size in cells.
---@return table Partial path entries from start toward the goal.
---@return boolean True when the returned path reaches the goal.
function LUnitPathfinder:findPartialPath(x1, y1, x2, y2, maxNodes, unitSize) end

--- Finds an A★ path between two cells (1-based coordinates).
---@param x1 integer 1-based start cell X coordinate.
---@param y1 integer 1-based start cell Y coordinate.
---@param x2 integer 1-based goal cell X coordinate.
---@param y2 integer 1-based goal cell Y coordinate.
---@param unitSize? integer Optional unit footprint size in cells.
---@return table Path entries as 1-based `{x, y}` tables.
function LUnitPathfinder:findPath(x1, y1, x2, y2, unitSize) end

--- Finds a path with bidirectional A★ between two cells.
---@param x1 integer 1-based start cell X coordinate.
---@param y1 integer 1-based start cell Y coordinate.
---@param x2 integer 1-based goal cell X coordinate.
---@param y2 integer 1-based goal cell Y coordinate.
---@param unitSize? integer Optional unit footprint size in cells.
---@param maxNodes? integer Optional node expansion limit.
---@return table Path entries from start toward the goal.
---@return boolean True when the full path to the goal was found.
function LUnitPathfinder:findPathBidirectional(x1, y1, x2, y2, unitSize, maxNodes) end

--- Finds a Theta★ smoothed path between two cells (1-based coordinates).
---@param x1 integer 1-based start cell X coordinate.
---@param y1 integer 1-based start cell Y coordinate.
---@param x2 integer 1-based goal cell X coordinate.
---@param y2 integer 1-based goal cell Y coordinate.
---@param unitSize? integer Optional unit footprint size in cells.
---@return table Smoothed path entries as 1-based `{x, y}` tables.
function LUnitPathfinder:findPathSmooth(x1, y1, x2, y2, unitSize) end

--- Returns the number of entries in the path cache.
---@return integer Number of cached path results.
function LUnitPathfinder:getCacheSize() end

--- Returns the sum of grid traversal costs along a path.
---@param path table Path entries as `{x, y}` tables.
---@return number Total traversal cost along the path.
function LUnitPathfinder:getPathCost(path) end

--- Returns the euclidean length of a path table.
---@param path table Path entries as `{x, y}` tables.
---@return number Euclidean path length.
function LUnitPathfinder:getPathLength(path) end

--- Returns the octile heuristic distance between two cells (1-based coordinates).
---@param x1 integer 1-based first cell X coordinate.
---@param y1 integer 1-based first cell Y coordinate.
---@param x2 integer 1-based second cell X coordinate.
---@param y2 integer 1-based second cell Y coordinate.
---@return number Octile heuristic distance.
function LUnitPathfinder:heuristicDistance(x1, y1, x2, y2) end

--- Returns true if path result caching is enabled.
---@return boolean True when path result caching is enabled.
function LUnitPathfinder:isCacheEnabled() end

--- Returns true if a path exists between two cells (1-based coordinates).
---@param x1 integer 1-based start cell X coordinate.
---@param y1 integer 1-based start cell Y coordinate.
---@param x2 integer 1-based goal cell X coordinate.
---@param y2 integer 1-based goal cell Y coordinate.
---@param unitSize? integer Optional unit footprint size in cells.
---@return boolean True when a path exists.
function LUnitPathfinder:isReachable(x1, y1, x2, y2, unitSize) end

--- Returns true if there is a clear line of sight between two cells (1-based coordinates).
---@param x1 integer 1-based start cell X coordinate.
---@param y1 integer 1-based start cell Y coordinate.
---@param x2 integer 1-based goal cell X coordinate.
---@param y2 integer 1-based goal cell Y coordinate.
---@param unitSize? integer Optional unit footprint size in cells.
---@return boolean True when line of sight is unobstructed.
function LUnitPathfinder:lineOfSight(x1, y1, x2, y2, unitSize) end

--- Enables or disables path result caching.
---@param enabled boolean Whether path caching should be enabled.
---@return nil No value is returned.
function LUnitPathfinder:setCacheEnabled(enabled) end

--- Sets the maximum number of cached path entries.
---@param n integer Maximum number of cached path results.
---@return nil No value is returned.
function LUnitPathfinder:setCacheMaxSize(n) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LUnitPathfinder:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LUnitPathfinder:typeOf(name) end

--- Returns the background pathfinding thread count (currently always 0).
---@return integer Current background thread count.
lurek.pathfind.getThreadCount = function() end

--- Creates a new FlowField backed by a NavGrid.
---@param grid LNavGrid Navigation grid to build from.
---@return LFlowField New flow-field userdata.
lurek.pathfind.newFlowField = function(grid) end

--- Creates a hex grid for pathfinding, LOS, FOV, and range queries.
---@param width integer Grid width in cells.
---@param height integer Grid height in cells.
---@param layout? string Optional hex layout name: `flat` or `pointy`.
---@return LHexGrid New hex-grid userdata.
lurek.pathfind.newHexGrid = function(width, height, layout) end

--- Creates a uniform-cost grid optimised for Jump Point Search (orthogonal + diagonal).
---@param width integer Grid width in cells.
---@param height integer Grid height in cells.
---@return LJpsGrid New Jump Point Search grid userdata.
lurek.pathfind.newJpsGrid = function(width, height) end

--- Creates a new NavGrid with all cells walkable.
---@param width integer Grid width in cells.
---@param height integer Grid height in cells.
---@return LNavGrid New navigation grid userdata.
lurek.pathfind.newNavGrid = function(width, height) end

--- Builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable).
---@param tilemap LTileMap Source tilemap userdata.
---@param layer_index integer 1-based tilemap layer index.
---@param blocked_gids table GID values to treat as blocked.
---@return LNavGrid Navigation grid built from the selected layer.
lurek.pathfind.newNavGridFromTileMap = function(tilemap, layer_index, blocked_gids) end

--- Creates a new BFS flow field from a PathGrid.
---@param grid LPathGrid Weighted path grid to build from.
---@return LAIFlowField New PathGrid-based flow-field userdata.
lurek.pathfind.newPathFlowField = function(grid) end

--- Creates a new PathGrid with per-cell cost and walkability.
---@param w integer Grid width in cells.
---@param h integer Grid height in cells.
---@param cellSize number Cell size in world units.
---@return LPathGrid New weighted path grid userdata.
lurek.pathfind.newPathGrid = function(w, h, cellSize) end

--- Creates a new UnitPathfinder backed by a NavGrid.
---@param grid LNavGrid Navigation grid to path over.
---@return LUnitPathfinder New pathfinder userdata.
lurek.pathfind.newPathfinder = function(grid) end

--- Computes a Dijkstra range-of-movement map from an origin within a movement budget.
---@param opts table Range-map options: width, height, costs, blocked, origin_x, origin_y, budget, and optional diagonal.
---@return table Result table with `cells`, `width`, and `height` fields.
lurek.pathfind.rangeMap = function(opts) end

--- Sets the background pathfinding thread count (currently a no-op).
---@param count integer Requested background thread count.
---@return nil No value is returned.
lurek.pathfind.setThreadCount = function(count) end

---@class lurek.patterns
lurek.patterns = {}

--- Lua wrapper for the Blackboard pattern.
---@class LBlackboard
LBlackboard = {}

--- Removes a fact from the blackboard.
---@param key string Fact key to remove.
---@return nil No return value.
function LBlackboard:clear(key) end

--- Clears all facts from the blackboard.
---@return nil No return value.
function LBlackboard:clearAll() end

--- Gets a fact from the blackboard.
---@param key string Fact key to read.
---@return LuaValue Stored fact value, or nil if the key is unset.
function LBlackboard:get(key) end

--- Returns the monotonic revision counter (incremented on every write).
---@return integer Current blackboard revision number.
function LBlackboard:getRevision() end

--- Returns true when the key has a non-nil value.
---@param key string Fact key to check.
---@return boolean True when the key has a non-nil value.
function LBlackboard:has(key) end

--- Returns all set fact keys as a table.
---@return table Fact keys with stored values.
function LBlackboard:keys() end

--- Sets a fact on the blackboard.
---@param key string Fact key to write.
---@param value LuaValue Fact value to store; nil clears the key.
---@return nil No return value.
function LBlackboard:set(key, value) end

--- Returns all facts as a flat key-value table.
---@return table Snapshot table of all stored facts.
function LBlackboard:snapshot() end

--- Removes a watcher subscription by id.
---@param id integer Watcher subscription ID to remove.
---@return nil No return value.
function LBlackboard:unwatch(id) end

--- Subscribes to changes on a specific key (or "*" for all changes).
---@param key string Fact key to watch, or `*` for all keys.
---@param callback function Callback invoked when the watched key changes.
---@return integer Watcher subscription ID.
function LBlackboard:watch(key, callback) end

--- Lua wrapper for the CommandStack pattern.
---@class LCommandStack
LCommandStack = {}

--- Returns true if there is a command available to redo.
---@return boolean True when a command is available to redo.
function LCommandStack:canRedo() end

--- Returns true if the most recent command can be undone.
---@return boolean True when the most recent command can be undone.
function LCommandStack:canUndo() end

--- Clears all command history, releasing Lua registry values.
---@return nil No return value.
function LCommandStack:clearAll() end

--- Executes a named command and records it in undo/redo history.
---@param name string Command name.
---@param exec_fn function Function to run when the command executes.
---@param undo_fn? function Optional function to run when the command is undone.
---@return nil No return value.
function LCommandStack:execute(name, exec_fn, undo_fn) end

--- Returns the name of the most recently executed command.
---@return string Most recent command name, or nil if the history is empty.
function LCommandStack:getCurrentName() end

--- Returns the total number of recorded commands (undo + redo).
---@return integer Total number of recorded commands.
function LCommandStack:getHistorySize() end

--- Re-executes the next undone command and returns whether it succeeded.
---@return boolean True when a command was redone.
function LCommandStack:redo() end

--- Undoes the most recent command and returns whether it succeeded.
---@return boolean True when a command was undone.
function LCommandStack:undo() end

--- Lua wrapper for the Debounce pattern.
---@class LDebounce
LDebounce = {}

--- Cancels the pending trigger without firing.
---@return nil No return value.
function LDebounce:cancel() end

--- Returns the total number of times this debounce has fired.
---@return integer Number of times the debounce has fired.
function LDebounce:getFireCount() end

--- Returns true when a trigger is pending.
---@return boolean True when a trigger is pending.
function LDebounce:isPending() end

--- Sets the callback invoked when the debounce fires.
---@param callback function Callback to invoke when the debounce fires.
---@return nil No return value.
function LDebounce:onFire(callback) end

--- Records an input event, resetting the idle timer.
---@return nil No return value.
function LDebounce:trigger() end

--- Advances the idle timer by dt seconds; fires the callback if idle wait expired.
---@param dt number Delta time in seconds.
---@return boolean True when the debounce fired.
function LDebounce:update(dt) end

--- Lua wrapper for the EventBus pattern.
---@class LEventBus
LEventBus = {}

--- Removes all listeners for a specific event.
---@param event string Event name to clear listeners from.
---@return nil No return value.
function LEventBus:clear(event) end

--- Removes all listeners on this EventBus.
---@return nil No return value.
function LEventBus:clearAll() end

--- Dispatches an event, calling all registered listeners in priority order.
---@param event string Event name to dispatch.
---@param ... LuaValue Additional values passed to listeners.
---@return nil No return value.
function LEventBus:emit(event, ...) end

--- Returns all event names that have at least one listener.
---@return table Event names with at least one listener.
function LEventBus:getEvents() end

--- Returns the number of listeners registered for an event.
---@param event string Event name to inspect.
---@return integer Number of listeners registered for the event.
function LEventBus:getListenerCount(event) end

--- Removes a previously registered event listener by subscription ID.
---@param id integer Subscription ID to remove.
---@return nil No return value.
function LEventBus:off(id) end

--- Registers a listener callback for an event.
---@param event string Event name to subscribe to.
---@param callback function Listener callback to register.
---@param priority? integer Optional listener priority; higher values run first.
---@return integer Subscription ID.
function LEventBus:on(event, callback, priority) end

--- Lua wrapper for the Factory pattern.
---@class LFactory
LFactory = {}

--- Registers an alias pointing to an existing canonical type name.
---@param alias string Alias name to register.
---@param canonical string Canonical type name the alias should resolve to.
---@return nil No return value.
function LFactory:alias(alias, canonical) end

--- Removes all registered type constructors and aliases.
---@return nil No return value.
function LFactory:clearAll() end

--- Creates an instance of the named type by invoking its constructor.
---@param type_name string Type or alias name to construct.
---@param ... LuaValue Arguments passed to the constructor.
---@return LuaValue Constructed value.
function LFactory:create(type_name, ...) end

--- Returns a table of all registered type names.
---@return table Registered type names.
function LFactory:getTypes() end

--- Returns true if the named type (or alias) is registered.
---@param type_name string Type or alias name to check.
---@return boolean True when the type or alias is registered.
function LFactory:has(type_name) end

--- Registers a named type constructor function.
---@param type_name string Canonical type name.
---@param ctor function Constructor callback to register.
---@return nil No return value.
function LFactory:register(type_name, ctor) end

--- Unregisters a type constructor (and any aliases pointing to it).
---@param type_name string Canonical type name to remove.
---@return nil No return value.
function LFactory:remove(type_name) end

--- Lua wrapper for the Funnel (event aggregator) pattern.
---@class LFunnel
LFunnel = {}

--- Discards all buffered entries without flushing.
---@return nil No return value.
function LFunnel:discard() end

--- Manually flushes all pending entries, invoking the onFlush callback.
---@return nil No return value.
function LFunnel:flush() end

--- Returns the total number of flushes performed.
---@return integer Number of flushes performed.
function LFunnel:getFlushCount() end

--- Sets a callback invoked when the funnel flushes. Receives a table of {tag, value} entries.
---@param callback function Callback invoked when the funnel flushes.
---@return nil No return value.
function LFunnel:onFlush(callback) end

--- Returns the number of buffered entries not yet flushed.
---@return integer Number of buffered entries.
function LFunnel:pendingCount() end

--- Adds an event to the funnel, flushing immediately when `max_entries` is reached or `window` is `0`.
---@param tag string Entry tag.
---@param value? number Optional numeric value for the entry.
---@return nil No return value.
function LFunnel:push(tag, value) end

--- Advances the window timer by dt seconds; flushes when window expires.
---@param dt number Delta time in seconds.
---@return boolean True when the update caused a flush.
function LFunnel:update(dt) end

--- Lua wrapper for an ordered, resizable list.
---@class LList
LList = {}

--- Appends a value to the end of the list.
---@param value LuaValue Value to append to the list.
---@return nil No return value.
function LList:add(value) end

--- Removes all values from the list.
---@return nil No return value.
function LList:clear() end

--- Returns true if the list contains a value equal to the given Lua value (string/number/boolean).
---@param value LuaValue Value to search for.
---@return boolean True when the list contains an equal value.
function LList:contains(value) end

--- Returns the value at a 1-based index.
---@param index integer 1-based list index to read.
---@return LuaValue Value at the index, or nil if the index is out of range.
function LList:get(index) end

--- Returns true if the list is empty.
---@return boolean True when the list is empty.
function LList:isEmpty() end

--- Returns the number of items in the list.
---@return integer Number of items in the list.
function LList:len() end

--- Removes and returns the value at a 1-based index.
---@param index integer 1-based list index to remove.
---@return LuaValue Removed value, or nil if the index is out of range.
function LList:remove(index) end

--- Replaces the value at a 1-based index.
---@param index integer 1-based list index to replace.
---@param value LuaValue Replacement value.
---@return nil No return value.
function LList:set(index, value) end

--- Returns all items as a Lua table.
---@return table List items in order.
function LList:toArray() end

--- Lua wrapper for the Mediator pattern.
---@class LMediator
LMediator = {}

--- Dispatches a message to all handlers across all channels.
---@param ... LuaValue Message values to deliver.
---@return nil No return value.
function LMediator:broadcast(...) end

--- Returns all registered channel names.
---@return table Registered channel names.
function LMediator:channels() end

--- Removes all channels and handlers.
---@return nil No return value.
function LMediator:clear() end

--- Returns the number of handlers on a channel.
---@param channel string Channel name to inspect.
---@return integer Number of handlers registered on the channel.
function LMediator:handlerCount(channel) end

--- Unregisters a handler by ID.
---@param channel string Channel name to remove the handler from.
---@param id integer Handler ID to remove.
---@return nil No return value.
function LMediator:off(channel, id) end

--- Registers a handler callback on a channel and returns its handler ID.
---@param channel string Channel name to subscribe to.
---@param callback function Handler callback to register.
---@return integer Handler ID.
function LMediator:on(channel, callback) end

--- Removes a channel and all its handlers.
---@param channel string Channel name to remove.
---@return nil No return value.
function LMediator:removeChannel(channel) end

--- Dispatches a message to all handlers on a channel.
---@param channel string Channel name to dispatch to.
---@param ... LuaValue Message values to deliver.
---@return nil No return value.
function LMediator:send(channel, ...) end

--- Lua wrapper for the ObjectPool pattern.
---@class LObjectPool
LObjectPool = {}

--- Acquires an available object from the pool.
---@return LuaValue Acquired value, or nil if the pool is empty.
function LObjectPool:acquire() end

--- Inserts a pre-built object into the available pool.
---@param value LuaValue Value to add to the idle pool.
---@return nil No return value.
function LObjectPool:add(value) end

--- Clears all objects from the pool, releasing Lua registry values.
---@return nil No return value.
function LObjectPool:clearAll() end

--- Returns the number of currently active (acquired) objects.
---@return integer Number of currently active objects.
function LObjectPool:getActiveCount() end

--- Returns the number of available (idle) objects in the pool.
---@return integer Number of idle objects in the pool.
function LObjectPool:getAvailableCount() end

--- Returns the total number of tracked objects (active + available).
---@return integer Total number of tracked objects.
function LObjectPool:getTotalCount() end

--- Returns an object to the available pool.
---@param value LuaValue Value to return to the pool.
---@return nil No return value.
function LObjectPool:release(value) end

--- Lua wrapper for the Observer pattern.
---@class LObserver
LObserver = {}

--- Gets a property value.
---@param key string Property key to read.
---@return LuaValue Stored property value, or nil if the key is unset.
function LObserver:get(key) end

--- Returns the total number of active subscriptions.
---@return integer Number of active subscriptions.
function LObserver:getCount() end

--- Sets a property value and fires subscribed watchers.
---@param key string Property key to write.
---@param value LuaValue Property value to store.
---@return nil No return value.
function LObserver:set(key, value) end

--- Subscribes to changes on a property key (or "*" for all).
---@param key string Property key to watch, or `*` for all keys.
---@param callback function Callback invoked when the property changes.
---@param once? boolean Optional flag to remove the subscription after one call.
---@return integer Subscription ID.
function LObserver:subscribe(key, callback, once) end

--- Removes a subscription by id.
---@param id integer Subscription ID to remove.
---@return nil No return value.
function LObserver:unsubscribe(id) end

--- Lua wrapper for the PriorityQueue pattern.
---@class LPriorityQueue
LPriorityQueue = {}

--- Removes all items from the queue.
---@return nil No return value.
function LPriorityQueue:clearAll() end

--- Returns true when the queue has no items.
---@return boolean True when the queue is empty.
function LPriorityQueue:isEmpty() end

--- Returns the number of items in the queue.
---@return integer Number of queued items.
function LPriorityQueue:len() end

--- Returns the highest-priority item without removing it.
---@return LuaValue Highest-priority value, or nil if the queue is empty.
function LPriorityQueue:peek() end

--- Removes and returns the highest-priority item.
---@return LuaValue Dequeued value, or nil if the queue is empty.
function LPriorityQueue:pop() end

--- Inserts an item with a priority. Higher priorities are dequeued first.
---@param priority integer Priority assigned to the item.
---@param value LuaValue Item value to enqueue.
---@param label? string Optional label for the item.
---@return integer Item ID.
function LPriorityQueue:push(priority, value, label) end

--- Lua wrapper for a FIFO queue.
---@class LQueue
LQueue = {}

--- Removes all values from the queue.
---@return nil No return value.
function LQueue:clear() end

--- Removes and returns the front value.
---@return LuaValue Front value, or nil if the queue is empty.
function LQueue:dequeue() end

--- Adds a value to the back of the queue.
---@param value LuaValue Value to enqueue.
---@return boolean True when the value was enqueued.
function LQueue:enqueue(value) end

--- Returns the front value without removing it.
---@return LuaValue Front value, or nil if the queue is empty.
function LQueue:front() end

--- Returns true if the queue is empty.
---@return boolean True when the queue is empty.
function LQueue:isEmpty() end

--- Returns true if the queue is at its capacity limit.
---@return boolean True when the queue is full.
function LQueue:isFull() end

--- Returns the number of items in the queue.
---@return integer Number of items in the queue.
function LQueue:len() end

--- Returns all items as a Lua table (front to back).
---@return table Queue items ordered from front to back.
function LQueue:toArray() end

--- Lua wrapper for the RelationshipManager pattern.
---@class LRelationshipManager
LRelationshipManager = {}

--- Adjusts the numeric relationship value by a delta.
---@param a integer First entity ID.
---@param b integer Second entity ID.
---@param delta number Value delta to apply.
---@return nil No return value.
function LRelationshipManager:adjustValue(a, b, delta) end

--- Defines a relationship type with ordered levels.
---@param name string Relationship type name.
---@param levels table Ordered level names for the relationship type.
---@param default_level? string Optional default level name.
---@return nil No return value.
function LRelationshipManager:defineType(name, levels, default_level) end

--- Returns the named level for a typed relationship.
---@param a integer First entity ID.
---@param b integer Second entity ID.
---@param type_name string Relationship type name.
---@return string Relationship level name, or nil if it is unset.
function LRelationshipManager:getLevel(a, b, type_name) end

--- Returns the numeric relationship value between two entities (default 0.0).
---@param a integer First entity ID.
---@param b integer Second entity ID.
---@return number Relationship value for the entity pair.
function LRelationshipManager:getValue(a, b) end

--- Returns the total number of stored relationship pairs.
---@return integer Number of stored relationship pairs.
function LRelationshipManager:pairCount() end

--- Removes all relationship data between two entities.
---@param a integer First entity ID.
---@param b integer Second entity ID.
---@return nil No return value.
function LRelationshipManager:removePair(a, b) end

--- Removes a relationship type definition.
---@param name string Relationship type name to remove.
---@return nil No return value.
function LRelationshipManager:removeType(name) end

--- Sets a named level for a typed relationship between two entities.
---@param a integer First entity ID.
---@param b integer Second entity ID.
---@param type_name string Relationship type name.
---@param level string Level name to assign.
---@return boolean True when the level was assigned.
function LRelationshipManager:setLevel(a, b, type_name, level) end

--- Sets the numeric relationship value between two entities.
---@param a integer First entity ID.
---@param b integer Second entity ID.
---@param value number Relationship value to assign.
---@return nil No return value.
function LRelationshipManager:setValue(a, b, value) end

--- Returns all defined relationship type names.
---@return table Defined relationship type names.
function LRelationshipManager:typeNames() end

--- Lua wrapper for the Ring (circular buffer) pattern.
---@class LRing
LRing = {}

--- Returns the average of all numeric values, or 0 if empty.
---@return number Average of all numeric values in the ring.
function LRing:average() end

--- Removes all entries from the ring.
---@return nil No return value.
function LRing:clear() end

--- Returns true when the ring is at capacity.
---@return boolean True when the ring is full.
function LRing:isFull() end

--- Returns the most recently pushed entry.
---@return table Most recent entry table, or nil if the ring is empty.
function LRing:latest() end

--- Returns the number of entries currently in the ring.
---@return integer Number of entries currently stored in the ring.
function LRing:len() end

--- Pushes a number or string value with an optional tag, overwriting the oldest entry on overflow.
---@param value LuaValue Number or string value to store.
---@param tag? string Optional tag to associate with the entry.
---@return integer Entry ID.
function LRing:push(value, tag) end

--- Returns the sum of all numeric values in the ring.
---@return number Sum of all numeric values in the ring.
function LRing:sum() end

--- Returns all entries (oldest first) as an array of {id, tag, value?, text?} tables.
---@return table Ring entries ordered from oldest to newest.
function LRing:toArray() end

--- Lua wrapper for the ServiceLocator pattern.
---@class LServiceLocator
LServiceLocator = {}

--- Removes all registered services.
---@return nil No return value.
function LServiceLocator:clearAll() end

--- Returns a table of all registered service names.
---@return table Registered service names.
function LServiceLocator:getServices() end

--- Returns true if a service with the given name is registered.
---@param name string Service name to check.
---@return boolean True when the service is registered.
function LServiceLocator:has(name) end

--- Retrieves a registered service by name.
---@param name string Service name to look up.
---@return LuaValue Stored service value, or nil if the service is missing.
function LServiceLocator:locate(name) end

--- Registers a named service with an associated Lua value.
---@param name string Service name.
---@param value LuaValue Service value to store.
---@return nil No return value.
function LServiceLocator:provide(name, value) end

--- Unregisters and removes a named service.
---@param name string Service name to remove.
---@return nil No return value.
function LServiceLocator:remove(name) end

--- Lua wrapper for an unordered set. Values are keyed by their string representation.
---@class LSet
LSet = {}

--- Adds a string key to the set.
---@param key string Key to add to the set.
---@return boolean True when the key was newly inserted.
function LSet:add(key) end

--- Removes all keys from the set.
---@return nil No return value.
function LSet:clear() end

--- Returns true if the key is in the set.
---@param key string Key to check.
---@return boolean True when the key is present.
function LSet:has(key) end

--- Returns the intersection of this set and another as a new Set.
---@param other LSet Other set to intersect with.
---@return LSet New set containing keys shared by both inputs.
function LSet:intersection(other) end

--- Returns true if the set is empty.
---@return boolean True when the set is empty.
function LSet:isEmpty() end

--- Returns the number of distinct keys in the set.
---@return integer Number of distinct keys in the set.
function LSet:len() end

--- Removes a key from the set.
---@param key string Key to remove from the set.
---@return boolean True when the key was present.
function LSet:remove(key) end

--- Returns all keys as a Lua table (unordered).
---@return table Unordered set keys.
function LSet:toArray() end

--- Returns the union of this set and another as a new Set.
---@param other LSet Other set to union with.
---@return LSet New set containing keys from both inputs.
function LSet:union(other) end

--- Lua wrapper for the SimpleState finite state machine pattern.
---@class LSimpleState
LSimpleState = {}

--- Registers a named state with optional enter, exit, and update callbacks.
---@param name string State name to register.
---@param callbacks? table Optional callbacks table with `enter`, `exit`, and `update` functions.
---@return nil No return value.
function LSimpleState:addState(name, callbacks) end

--- Removes all states and callbacks from this state machine.
---@return nil No return value.
function LSimpleState:clearAll() end

--- Returns the name of the current state.
---@return string Current state name, or nil if no state is active.
function LSimpleState:getCurrent() end

--- Returns a table of all registered state names.
---@return table Registered state names.
function LSimpleState:getStates() end

--- Returns true if a state with the given name is registered.
---@param name string State name to check.
---@return boolean True when the state is registered.
function LSimpleState:hasState(name) end

--- Transitions to a named state, calling exit/enter callbacks as needed.
---@param name string State name to activate.
---@return boolean True when the transition succeeded.
function LSimpleState:transitionTo(name) end

--- Calls the update callback of the current state with the given delta time.
---@param dt number Delta time in seconds.
---@return nil No return value.
function LSimpleState:update(dt) end

--- Lua wrapper for a LIFO stack.
---@class LStack
LStack = {}

--- Removes all values from the stack.
---@return nil No return value.
function LStack:clear() end

--- Returns true if the stack is empty.
---@return boolean True when the stack is empty.
function LStack:isEmpty() end

--- Returns true if the stack is at its capacity limit.
---@return boolean True when the stack is full.
function LStack:isFull() end

--- Returns the number of items on the stack.
---@return integer Number of items on the stack.
function LStack:len() end

--- Returns the top value without removing it.
---@return LuaValue Top value, or nil if the stack is empty.
function LStack:peek() end

--- Removes and returns the top value.
---@return LuaValue Popped value, or nil if the stack is empty.
function LStack:pop() end

--- Pushes a value onto the stack.
---@param value LuaValue Value to push onto the stack.
---@return boolean True when the value was pushed.
function LStack:push(value) end

--- Returns all items as a Lua table (bottom to top).
---@return table Stack items ordered from bottom to top.
function LStack:toArray() end

--- Lua wrapper for the Strategy pattern.
---@class LStrategy
LStrategy = {}

--- Removes all strategies and clears the active selection.
---@return nil No return value.
function LStrategy:clear() end

--- Calls the currently active strategy function with the given arguments.
---@param ... LuaValue Arguments passed to the active strategy.
---@return LuaValue Values returned by the active strategy.
function LStrategy:execute(...) end

--- Returns the name of the active strategy.
---@return string Active strategy name, or nil if no strategy is selected.
function LStrategy:getCurrent() end

--- Returns true if a strategy with this name is registered.
---@param name string Strategy name to check.
---@return boolean True when the strategy is registered.
function LStrategy:has(name) end

--- Returns all registered strategy names.
---@return table Registered strategy names.
function LStrategy:names() end

--- Registers a named strategy function.
---@param name string Strategy name.
---@param callback function Strategy callback to register.
---@return nil No return value.
function LStrategy:register(name, callback) end

--- Removes a strategy by name.
---@param name string Strategy name to remove.
---@return boolean True when the strategy was removed.
function LStrategy:remove(name) end

--- Sets the active strategy by name.
---@param name string Strategy name to activate.
---@return boolean True when the strategy was registered and selected.
function LStrategy:set(name) end

--- Lua wrapper for the Throttle pattern.
---@class LThrottle
LThrottle = {}

--- Returns the total number of times this throttle has fired.
---@return integer Number of times the throttle has fired.
function LThrottle:getFireCount() end

--- Returns the normalised progress through the current interval [0, 1].
---@return number Normalized progress through the current interval.
function LThrottle:getProgress() end

--- Sets the callback invoked when the throttle fires.
---@param callback function Callback to invoke when the throttle fires.
---@return nil No return value.
function LThrottle:onFire(callback) end

--- Resets the elapsed counter without firing.
---@return nil No return value.
function LThrottle:reset() end

--- Enables or disables the throttle.
---@param enabled boolean Whether the throttle should be enabled.
---@return nil No return value.
function LThrottle:setEnabled(enabled) end

--- Advances the timer by dt seconds; fires the callback if the interval elapsed.
---@param dt number Delta time in seconds.
---@return boolean True when the throttle fired.
function LThrottle:update(dt) end

--- Creates a new Blackboard shared key-value store.
---@param name? string Optional blackboard name.
---@return LBlackboard New Blackboard userdata.
lurek.patterns.newBlackboard = function(name) end

--- Creates a new CommandStack instance.
---@param max_size? integer Optional maximum history size.
---@return LCommandStack New CommandStack userdata.
lurek.patterns.newCommandStack = function(max_size) end

--- Creates a trailing-edge debounce that fires after the input stream is idle for wait seconds.
---@param wait number Debounce wait time in seconds.
---@return LDebounce New Debounce userdata.
lurek.patterns.newDebounce = function(wait) end

--- Creates a new EventBus instance.
---@param name? string Optional EventBus name.
---@return LEventBus New EventBus userdata.
lurek.patterns.newEventBus = function(name) end

--- Creates a new Factory instance.
---@return LFactory New Factory userdata.
lurek.patterns.newFactory = function() end

--- Creates a time-windowed event aggregator that flushes on every push when `window` is `0`.
---@param window number Funnel window duration in seconds.
---@param max_entries? integer Optional maximum buffered entry count before flushing.
---@param name? string Optional funnel name.
---@return LFunnel New Funnel userdata.
lurek.patterns.newFunnel = function(window, max_entries, name) end

--- Creates an ordered, resizable list.
---@return LList New list userdata.
lurek.patterns.newList = function() end

--- Creates a new named-channel message broker.
---@return LMediator New Mediator userdata.
lurek.patterns.newMediator = function() end

--- Creates a new ObjectPool instance.
---@return LObjectPool New ObjectPool userdata.
lurek.patterns.newObjectPool = function() end

--- Creates a new reactive property Observer.
---@param name? string Optional observer name.
---@return LObserver New Observer userdata.
lurek.patterns.newObserver = function(name) end

--- Creates a stable priority-ordered task queue.
---@param name? string Optional queue name.
---@return LPriorityQueue New PriorityQueue userdata.
lurek.patterns.newPriorityQueue = function(name) end

--- Creates a FIFO queue. capacity=0 means unlimited.
---@param capacity? integer Optional queue capacity; `0` means unlimited.
---@return LQueue New queue userdata.
lurek.patterns.newQueue = function(capacity) end

--- Creates a new entity relationship manager.
---@return LRelationshipManager New RelationshipManager userdata.
lurek.patterns.newRelationshipManager = function() end

--- Creates a fixed-capacity circular history buffer.
---@param capacity integer Maximum number of entries to retain.
---@param name? string Optional ring name.
---@return LRing New Ring userdata.
lurek.patterns.newRing = function(capacity, name) end

--- Creates a new ServiceLocator instance.
---@return LServiceLocator New ServiceLocator userdata.
lurek.patterns.newServiceLocator = function() end

--- Creates an unordered set that rejects duplicate values (by string key).
---@return LSet New set userdata.
lurek.patterns.newSet = function() end

--- Creates a new SimpleState finite state machine instance.
---@return LSimpleState New SimpleState userdata.
lurek.patterns.newSimpleState = function() end

--- Creates a LIFO stack. capacity=0 means unlimited.
---@param capacity? integer Optional stack capacity; `0` means unlimited.
---@return LStack New stack userdata.
lurek.patterns.newStack = function(capacity) end

--- Creates a new strategy registry.
---@return LStrategy New Strategy userdata.
lurek.patterns.newStrategy = function() end

--- Creates a leading-edge rate limiter that fires at most once per interval seconds.
---@param interval number Throttle interval in seconds.
---@return LThrottle New Throttle userdata.
lurek.patterns.newThrottle = function(interval) end

---@class lurek.physics
---@field CELL_AIR integer  empty air cell (0)
---@field CELL_SAND integer  sand cell (1)
---@field CELL_WATER integer  water cell (2)
---@field CELL_ROCK integer  rock cell (3)
---@field CELL_FIRE integer  fire cell (4)
---@field CELL_GAS integer  gas cell (5)
lurek.physics = {}

--- Lua-side handle to a physics body accessed through its world.
---@class LBody
LBody = {}

--- Applies an angular impulse.
---@param impulse number Angular impulse value.
---@return nil No return value.
function LBody:applyAngularImpulse(impulse) end

--- Applies a continuous force to the body.
---@param fx number Force X component.
---@param fy number Force Y component.
---@return nil No return value.
function LBody:applyForce(fx, fy) end

--- Applies a force at a specific world-space point.
---@param fx number Force X component.
---@param fy number Force Y component.
---@param px number World-space application point X.
---@param py number World-space application point Y.
---@return nil No return value.
function LBody:applyForceAtPoint(fx, fy, px, py) end

--- Applies a linear impulse to the body.
---@param ix number Impulse X component.
---@param iy number Impulse Y component.
---@return nil No return value.
function LBody:applyImpulse(ix, iy) end

--- Applies a torque (rotational force).
---@param torque number Torque value.
---@return nil No return value.
function LBody:applyTorque(torque) end

--- Removes this body from the world.
---@return nil No return value.
function LBody:destroy() end

--- Returns the body angle in radians.
---@return number Body angle in radians.
function LBody:getAngle() end

--- Returns the angular damping coefficient.
---@return number Angular damping coefficient.
function LBody:getAngularDamping() end

--- Returns the angular velocity in radians/s.
---@return number Angular velocity in radians per second.
function LBody:getAngularVelocity() end

--- Returns the body friction coefficient.
---@return number Friction coefficient.
function LBody:getFriction() end

--- Returns the per-body gravity multiplier.
---@return number Gravity multiplier.
function LBody:getGravityScale() end

--- Returns the height of this body's primary collider shape in world units.
---@return number Primary collider height.
function LBody:getHeight() end

--- Returns the body's integer ID.
---@return integer Body ID.
function LBody:getId() end

--- Returns the collision layer bitmask.
---@return integer Collision layer bitmask.
function LBody:getLayer() end

--- Returns the linear damping coefficient.
---@return number Linear damping coefficient.
function LBody:getLinearDamping() end

--- Returns the collision mask bitmask.
---@return integer Collision mask bitmask.
function LBody:getMask() end

--- Returns the body mass in kilograms used for force and impulse calculations.
---@return number Body mass value.
function LBody:getMass() end

--- Returns the body position (x, y).
---@return number Body X position.
---@return number Body Y position.
function LBody:getPosition() end

--- Returns the body restitution (bounciness).
---@return number Restitution coefficient.
function LBody:getRestitution() end

--- Returns the body type as a string.
---@return string Body type name.
function LBody:getType() end

--- Returns the body velocity (vx, vy).
---@return number Linear velocity X component.
---@return number Linear velocity Y component.
function LBody:getVelocity() end

--- Returns the width of this body's primary collider shape in world units.
---@return number Primary collider width.
function LBody:getWidth() end

--- Returns the body X position.
---@return number Body X position.
function LBody:getX() end

--- Returns the body Y position.
---@return number Body Y position.
function LBody:getY() end

--- Returns whether CCD is enabled.
---@return boolean True when CCD is enabled.
function LBody:isBullet() end

--- Returns whether rotation is locked.
---@return boolean True when rotation is locked.
function LBody:isFixedRotation() end

--- Returns true if this body is currently sleeping (inactive).
---@return boolean True when the body is sleeping.
function LBody:isSleeping() end

--- Returns whether the body can sleep.
---@return boolean True when the body can sleep.
function LBody:isSleepingAllowed() end

--- Sets the body angle in radians.
---@param angle number Body angle in radians.
---@return nil No return value.
function LBody:setAngle(angle) end

--- Sets the angular damping coefficient.
---@param damping number Angular damping coefficient.
---@return nil No return value.
function LBody:setAngularDamping(damping) end

--- Sets the angular velocity.
---@param omega number Angular velocity in radians per second.
---@return nil No return value.
function LBody:setAngularVelocity(omega) end

--- Enables or disables continuous collision detection (CCD) for fast-moving bodies.
---@param bullet boolean Whether CCD should be enabled.
---@return nil No return value.
function LBody:setBullet(bullet) end

--- Locks or unlocks rotation.
---@param fixed boolean Whether rotation should be locked.
---@return nil No return value.
function LBody:setFixedRotation(fixed) end

--- Sets the body friction coefficient.
---@param friction number Friction coefficient.
---@return nil No return value.
function LBody:setFriction(friction) end

--- Sets the per-body gravity multiplier.
---@param scale number Gravity multiplier.
---@return nil No return value.
function LBody:setGravityScale(scale) end

--- Sets the collision layer bitmask.
---@param layer integer Collision layer bitmask.
---@return nil No return value.
function LBody:setLayer(layer) end

--- Sets the linear damping coefficient.
---@param damping number Linear damping coefficient.
---@return nil No return value.
function LBody:setLinearDamping(damping) end

--- Sets the collision mask bitmask.
---@param mask integer Collision mask bitmask.
---@return nil No return value.
function LBody:setMask(mask) end

--- Sets the body mass; affects how forces and impulses change velocity.
---@param mass number Body mass value.
---@return nil No return value.
function LBody:setMass(mass) end

--- Teleports the body to the given world-space position, bypassing collision.
---@param x number Target X position.
---@param y number Target Y position.
---@return nil No return value.
function LBody:setPosition(x, y) end

--- Sets the body restitution (bounciness).
---@param restitution number Restitution coefficient.
---@return nil No return value.
function LBody:setRestitution(restitution) end

--- Sets whether the body can sleep.
---@param allowed boolean Whether the body can sleep.
---@return nil No return value.
function LBody:setSleepingAllowed(allowed) end

--- Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
---@param bodyType string New body type name.
---@return nil No return value.
function LBody:setType(bodyType) end

--- Sets the body's linear velocity in world units per second.
---@param vx number Linear velocity X component.
---@param vy number Linear velocity Y component.
---@return nil No return value.
function LBody:setVelocity(vx, vy) end

--- Puts this body to sleep immediately.
---@return nil No return value.
function LBody:sleep() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LBody:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LBody:typeOf(name) end

--- Forcibly wakes up this body.
---@return nil No return value.
function LBody:wakeUp() end

--- Lua-side handle to a falling-sand [`CellularWorld`].
---@class LCellular
LCellular = {}

--- Counts cells of the given material type.
---@param cell_type integer Material constant to count.
---@return integer Number of matching cells.
function LCellular:countCells(cell_type) end

--- Fills a circle of cells with the given material.
---@param cx_c integer Center column.
---@param cy_c integer Center row.
---@param r_cells integer Radius in cells.
---@param cell_type integer Material constant to write.
---@return nil No return value.
function LCellular:fillCircle(cx_c, cy_c, r_cells, cell_type) end

--- Fills a rectangular region of cells with the given material.
---@param cx0 integer Left column.
---@param cy0 integer Top row.
---@param cw integer Width in cells.
---@param ch integer Height in cells.
---@param cell_type integer Material constant to write.
---@return nil No return value.
function LCellular:fillRect(cx0, cy0, cw, ch, cell_type) end

--- Returns positions of all cells of the given material as an array of `{x, y}` tables.
---@param cell_type integer Material constant to search for.
---@return table Array of `{x, y}` tables.
function LCellular:findCells(cell_type) end

--- Returns the material at `(cx, cy)` as an integer constant.
---@param cx integer Cell column.
---@param cy integer Cell row.
---@return integer Material constant at the cell.
function LCellular:getCell(cx, cy) end

--- Loads grid data from bytes produced by `toBytes`.
---@param data string Serialized grid bytes.
---@return boolean True when the grid loads successfully.
function LCellular:loadFromBytes(data) end

--- Sets the material of a cell.
---@param cx integer Cell column.
---@param cy integer Cell row.
---@param cell_type integer Material constant from `lurek.physics.CELL_*`.
---@return nil No return value.
function LCellular:setCell(cx, cy, cell_type) end

--- Advances the simulation by one tick.
---@return nil No return value.
function LCellular:step() end

--- Advances the simulation by `n` ticks.
---@param n integer Number of ticks to advance.
---@return nil No return value.
function LCellular:stepN(n) end

--- Serialises the grid to a byte string.
---@return string Serialized grid bytes.
function LCellular:toBytes() end

--- Returns the full grid as an RGBA byte string using the default colour palette.
---@return string RGBA bytes for the full grid.
function LCellular:toImageData() end

--- Returns a sub-region as an RGBA byte string.
---@param cx0 integer Left column.
---@param cy0 integer Top row.
---@param cw integer Region width in cells.
---@param ch integer Region height in cells.
---@return string RGBA bytes for the requested region.
function LCellular:toImageDataRegion(cx0, cy0, cw, ch) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LCellular:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LCellular:typeOf(name) end

--- Lua-side standalone shape object (circle, rectangle, edge, polygon, chain).
---@class LPhysicsShape
LPhysicsShape = {}

--- Releases this shape handle (GC handles cleanup).
---@return nil No return value.
function LPhysicsShape:destroy() end

--- Returns the axis-aligned bounding box (x1, y1, x2, y2).
---@return number Minimum X coordinate.
---@return number Minimum Y coordinate.
---@return number Maximum X coordinate.
---@return number Maximum Y coordinate.
function LPhysicsShape:getBoundingBox() end

--- Returns the radius. Only valid for circle shapes.
---@return number Circle radius.
function LPhysicsShape:getRadius() end

--- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
---@return string Shape type name.
function LPhysicsShape:getType() end

--- Sets the density for this shape (used when attaching to a body).
---@param density number Shape density value.
---@return nil No return value.
function LPhysicsShape:setDensity(density) end

--- Sets the friction coefficient.
---@param friction number Friction coefficient.
---@return nil No return value.
function LPhysicsShape:setFriction(friction) end

--- Sets the restitution (bounciness) coefficient.
---@param restitution number Restitution coefficient.
---@return nil No return value.
function LPhysicsShape:setRestitution(restitution) end

--- Sets whether this shape is a sensor (non-colliding trigger).
---@param sensor boolean Whether the shape should act as a sensor.
---@return nil No return value.
function LPhysicsShape:setSensor(sensor) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LPhysicsShape:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LPhysicsShape:typeOf(name) end

--- Lua-side handle to a destructible [`TerrainMap`].
---@class LTerrain
LTerrain = {}

--- Removes unsupported cells, returning the number of cells that fell.
---@return integer Number of cells removed.
function LTerrain:collapseColumns() end

--- Sets every cell in the grid to `solid`.
---@param solid boolean Whether every cell should be solid.
---@return nil No return value.
function LTerrain:fillAll(solid) end

--- Fills a circle of cells centred at world position `(wx, wy)`.
---@param wx number World-space center X position.
---@param wy number World-space center Y position.
---@param radius number World-space radius.
---@param solid boolean True to fill, false to dig.
---@return nil No return value.
function LTerrain:fillCircle(wx, wy, radius, solid) end

--- Fills a rectangular region of cells.
---@param wx number Left edge in world pixels.
---@param wy number Top edge in world pixels.
---@param w number Width in world pixels.
---@param h number Height in world pixels.
---@param solid boolean Whether the region should be solid.
---@return nil No return value.
function LTerrain:fillRect(wx, wy, w, h, solid) end

--- Rebuilds physics bodies for all dirty chunks.
---@return nil No return value.
function LTerrain:flush() end

--- Returns whether a cell is solid.
---@param cx integer Cell column.
---@param cy integer Cell row.
---@return boolean True when the cell is solid.
function LTerrain:getCell(cx, cy) end

--- Returns `true` when at least one chunk needs flushing.
---@return boolean True when at least one chunk needs flushing.
function LTerrain:isDirty() end

--- Loads terrain cell data from bytes produced by `toBytes`.
---@param data string Serialized terrain bytes.
---@return boolean True when the terrain data loads successfully.
function LTerrain:loadFromBytes(data) end

--- Sets a single terrain cell to solid or empty.
---@param cx integer Cell column.
---@param cy integer Cell row.
---@param solid boolean Whether the cell should be solid.
---@return nil No return value.
function LTerrain:setCell(cx, cy, solid) end

--- Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
---@return table Array of `{x, y}` tables.
function LTerrain:solidPositions() end

--- Spawns dynamic debris bodies at the given positions.
---@param positions table Array of `{x, y}` tables.
---@param mass number Debris body mass.
---@param restitution number Debris restitution coefficient.
---@return table Array of spawned body IDs.
function LTerrain:spawnDebris(positions, mass, restitution) end

--- Serialises the terrain grid to a byte string for save/load.
---@return string Serialized terrain bytes.
function LTerrain:toBytes() end

--- Returns the terrain as an RGBA byte string.
---@param sr integer Solid-cell red channel.
---@param sg integer Solid-cell green channel.
---@param sb integer Solid-cell blue channel.
---@param er integer Empty-cell red channel.
---@param eg integer Empty-cell green channel.
---@param eb integer Empty-cell blue channel.
---@return string RGBA bytes for the full terrain image.
function LTerrain:toImageData(sr, sg, sb, er, eg, eb) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LTerrain:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LTerrain:typeOf(name) end

--- Lua-side handle wrapping a physics World.
---@class LWorld
LWorld = {}

--- Creates a distance joint between two bodies.
---@param bodyA integer First body ID.
---@param bodyB integer Second body ID.
---@param ax1 number First anchor X position.
---@param ay1 number First anchor Y position.
---@param ax2 number Second anchor X position.
---@param ay2 number Second anchor Y position.
---@param length number Joint length.
---@return integer Joint ID.
function LWorld:addDistanceJoint(bodyA, bodyB, ax1, ay1, ax2, ay2, length) end

--- Adds an extra fixture (collider) to a body.
---@param bodyId integer Body ID that receives the fixture.
---@param shapeType string Shape type name.
---@param density number Fixture density.
---@param friction number Fixture friction coefficient.
---@param restitution number Fixture restitution coefficient.
---@param sensor boolean Whether the fixture acts as a sensor.
---@param ... LuaValue Shape arguments consumed by the selected shape type.
---@return integer Fixture index on the body.
function LWorld:addFixture(bodyId, shapeType, density, friction, restitution, sensor, ...) end

--- Creates a friction joint that resists relative motion.
---@param bodyA integer First body ID.
---@param bodyB integer Second body ID.
---@param anchorX number Anchor X position.
---@param anchorY number Anchor Y position.
---@param maxForce number Maximum linear resistance force.
---@param maxTorque number Maximum angular resistance torque.
---@return integer Joint ID.
function LWorld:addFrictionJoint(bodyA, bodyB, anchorX, anchorY, maxForce, maxTorque) end

--- Creates a gear joint (stub - falls back to weld joint).
---@param bodyA integer First body ID.
---@param bodyB integer Second body ID.
---@param anchorX number Anchor X position.
---@param anchorY number Anchor Y position.
---@return integer Joint ID.
function LWorld:addGearJoint(bodyA, bodyB, anchorX, anchorY) end

--- Creates a motor joint that drives body_b toward body_a.
---@param bodyA integer Target body ID.
---@param bodyB integer Driven body ID.
---@param correctionFactor number Joint correction factor.
---@return integer Joint ID.
function LWorld:addMotorJoint(bodyA, bodyB, correctionFactor) end

--- Creates a mouse joint connecting a body to a target point.
---@param bodyId integer Body ID to constrain.
---@param targetX number Target X position.
---@param targetY number Target Y position.
---@param maxForce number Maximum force applied by the joint.
---@return integer Joint ID.
function LWorld:addMouseJoint(bodyId, targetX, targetY, maxForce) end

--- Creates a prismatic (slider) joint between two bodies.
---@param bodyA integer First body ID.
---@param bodyB integer Second body ID.
---@param anchorX number Anchor X position.
---@param anchorY number Anchor Y position.
---@param axisX number Axis X component.
---@param axisY number Axis Y component.
---@return integer Joint ID.
function LWorld:addPrismaticJoint(bodyA, bodyB, anchorX, anchorY, axisX, axisY) end

--- Creates a pulley joint (stub - falls back to weld joint).
---@param bodyA integer First body ID.
---@param bodyB integer Second body ID.
---@param anchorX number Anchor X position.
---@param anchorY number Anchor Y position.
---@return integer Joint ID.
function LWorld:addPulleyJoint(bodyA, bodyB, anchorX, anchorY) end

--- Creates a revolute (pin) joint between two bodies.
---@param bodyA integer First body ID.
---@param bodyB integer Second body ID.
---@param anchorX number Anchor X position.
---@param anchorY number Anchor Y position.
---@return integer Joint ID.
function LWorld:addRevoluteJoint(bodyA, bodyB, anchorX, anchorY) end

--- Creates a rope joint with a maximum distance.
---@param bodyA integer First body ID.
---@param bodyB integer Second body ID.
---@param ax1 number First anchor X position.
---@param ay1 number First anchor Y position.
---@param ax2 number Second anchor X position.
---@param ay2 number Second anchor Y position.
---@param maxLength number Maximum rope length.
---@return integer Joint ID.
function LWorld:addRopeJoint(bodyA, bodyB, ax1, ay1, ax2, ay2, maxLength) end

--- Creates a weld (rigid) joint between two bodies.
---@param bodyA integer First body ID.
---@param bodyB integer Second body ID.
---@param anchorX number Anchor X position.
---@param anchorY number Anchor Y position.
---@return integer Joint ID.
function LWorld:addWeldJoint(bodyA, bodyB, anchorX, anchorY) end

--- Creates a wheel joint (prismatic + rotation).
---@param bodyA integer First body ID.
---@param bodyB integer Second body ID.
---@param anchorX number Anchor X position.
---@param anchorY number Anchor Y position.
---@param axisX number Axis X component.
---@param axisY number Axis Y component.
---@return integer Joint ID.
function LWorld:addWheelJoint(bodyA, bodyB, anchorX, anchorY, axisX, axisY) end

--- Creates a rectangular gravity or damping zone.
---@param x number Left edge in world pixels.
---@param y number Top edge in world pixels.
---@param width number Zone width in world pixels.
---@param height number Zone height in world pixels.
---@return LZone New zone handle.
function LWorld:addZone(x, y, width, height) end

--- Resets the world, removing all bodies and joints.
---@return nil No return value.
function LWorld:clear() end

--- Removes the begin-contact callback.
---@return nil No return value.
function LWorld:clearBeginContact() end

--- Removes the Lua data attached to a body.
---@param bodyId integer Body ID to clear.
---@return nil No return value.
function LWorld:clearBodyData(bodyId) end

--- Removes the one-way platform flag from a body.
---@param bodyId integer Body ID to modify.
---@return nil No return value.
function LWorld:clearBodyOneWay(bodyId) end

--- Removes the end-contact callback.
---@return nil No return value.
function LWorld:clearEndContact() end

--- Removes a body from the world.
---@param id integer Body ID to remove.
---@return nil No return value.
function LWorld:destroyBody(id) end

--- Removes a joint from the world.
---@param jointId integer Joint ID to remove.
---@return nil No return value.
function LWorld:destroyJoint(jointId) end

--- Draws physics objects into an image for debugging.
---@param target LImageData Target image that receives the debug draw output.
---@param r? integer Optional red channel override; defaults to 0.
---@param g? integer Optional green channel override; defaults to 255.
---@param b? integer Optional blue channel override; defaults to 0.
---@param a? integer Optional alpha channel override; defaults to 255.
---@return nil No return value.
function LWorld:drawDebug(target, r, g, b, a) end

--- Returns the number of fixtures on a body.
---@param bodyId integer Body ID to inspect.
---@return integer Number of fixtures on the body.
function LWorld:fixtureCount(bodyId) end

--- Returns begin-contact events from the last step.
---@return table Array of begin-contact event tables.
function LWorld:getBeginContactEvents() end

--- Returns the body ID at a world-space point, or nil.
---@param x number Query point X position.
---@param y number Query point Y position.
---@return integer Body ID at the point, or nil when none is found.
function LWorld:getBodyAtPoint(x, y) end

--- Returns whether CCD is enabled for a body.
---@param bodyId integer Body ID to inspect.
---@return boolean True when CCD is enabled.
function LWorld:getBodyCCD(bodyId) end

--- Returns contacts involving a specific body.
---@param bodyId integer Body ID to inspect.
---@return table Array of contact tables for the body.
function LWorld:getBodyContacts(bodyId) end

--- Returns the total number of bodies in the world.
---@return integer Total number of bodies.
function LWorld:getBodyCount() end

--- Returns the Lua data previously attached to a body, or nil if none is set.
---@param bodyId integer Body ID to inspect.
---@return LuaValue Stored Lua value, or nil when no value is attached.
function LWorld:getBodyData(bodyId) end

--- Returns all body IDs in the world.
---@return table Array of body IDs.
function LWorld:getBodyIds() end

--- Returns the one-way normal for a body, or nil if not configured.
---@param bodyId integer Body ID to inspect.
---@return number One-way normal X component.
---@return number One-way normal Y component.
function LWorld:getBodyOneWay(bodyId) end

--- Returns the body type as a string.
---@param bodyId integer Body ID to inspect.
---@return string Body type name.
function LWorld:getBodyType(bodyId) end

--- Returns collision events from the last step.
---@return table Array of collision event tables.
function LWorld:getCollisionEvents() end

--- Returns all contact pairs from the narrow phase.
---@return table Array of contact tables.
function LWorld:getContacts() end

--- Returns end-contact events from the last step.
---@return table Array of end-contact event tables.
function LWorld:getEndContactEvents() end

--- Returns the gravity vector (gx, gy).
---@return number Gravity X component.
---@return number Gravity Y component.
function LWorld:getGravity() end

--- Returns the two body IDs connected by a joint.
---@param jointId integer Joint ID to inspect.
---@return integer First connected body ID.
---@return integer Second connected body ID.
function LWorld:getJointBodies(jointId) end

--- Returns the break threshold for a joint, or nil if not set.
---@param jointId integer Joint ID to inspect.
---@return number Break threshold, or nil when no threshold is set.
function LWorld:getJointBreakForce(jointId) end

--- Returns a table of integer IDs for every joint attached to this world.
---@return table Array of joint IDs.
function LWorld:getJointIds() end

--- Returns the angular limits on a joint.
---@param jointId integer Joint ID to inspect.
---@return number Lower angular limit.
---@return number Upper angular limit.
function LWorld:getJointLimits(jointId) end

--- Returns the motor speed on a joint's angular axis.
---@param jointId integer Joint ID to inspect.
---@return number Current motor speed.
function LWorld:getJointMotorSpeed(jointId) end

--- Returns the type name of a joint.
---@param jointId integer Joint ID to inspect.
---@return string Joint type name.
function LWorld:getJointType(jointId) end

--- Returns the pixels-per-meter scaling factor.
---@return number Pixels-per-meter scaling factor.
function LWorld:getMeter() end

--- Returns the current number of solver iterations per step.
---@return integer Solver iteration count.
function LWorld:getSolverIterations() end

--- Returns zone enter and leave events from the most recent step.
---@return table Array of event tables with `zone_id`, `body_id`, and `kind` fields.
function LWorld:getZoneEvents() end

--- Returns true if a body is currently sleeping (inactive).
---@param bodyId integer Body ID to inspect.
---@return boolean True when the body is sleeping.
function LWorld:isBodySleeping(bodyId) end

--- Returns the total number of joints.
---@return integer Total number of joints.
function LWorld:jointCount() end

--- Creates multiple bodies in one call.
---@param specs table Array of `{x, y, bodyType}` tables.
---@return table Array of new body IDs in the same order.
function LWorld:newBodies(specs) end

--- Creates a new rectangular body and adds it to the world.
---@param x number Initial X position.
---@param y number Initial Y position.
---@param bodyType string Body type name.
---@return LBody New body handle.
function LWorld:newBody(x, y, bodyType) end

--- Creates a new chain body from a flat vertex table and adds it to the world.
---@param x number Initial X position.
---@param y number Initial Y position.
---@param vertices table Flat vertex table of x and y pairs.
---@param closed boolean Whether the chain closes back to the first vertex.
---@param bodyType string Body type name.
---@return LBody New body handle.
function LWorld:newChainBody(x, y, vertices, closed, bodyType) end

--- Creates a new circular body and adds it to the world.
---@param x number Initial X position.
---@param y number Initial Y position.
---@param radius number Circle radius.
---@param bodyType string Body type name.
---@return LBody New body handle.
function LWorld:newCircleBody(x, y, radius, bodyType) end

--- Creates a new edge (line segment) body and adds it to the world.
---@param x number Initial X position.
---@param y number Initial Y position.
---@param x1 number First endpoint X offset.
---@param y1 number First endpoint Y offset.
---@param x2 number Second endpoint X offset.
---@param y2 number Second endpoint Y offset.
---@param bodyType string Body type name.
---@return LBody New body handle.
function LWorld:newEdgeBody(x, y, x1, y1, x2, y2, bodyType) end

--- Creates a new polygon body from a flat vertex table and adds it to the world.
---@param x number Initial X position.
---@param y number Initial Y position.
---@param vertices table Flat vertex table of x and y pairs.
---@param bodyType string Body type name.
---@return LBody New body handle.
function LWorld:newPolygonBody(x, y, vertices, bodyType) end

--- Returns body IDs within an axis-aligned bounding box.
---@param x number Bounding box X position.
---@param y number Bounding box Y position.
---@param w number Bounding box width.
---@param h number Bounding box height.
---@return table Array of body IDs inside the box.
function LWorld:queryAABB(x, y, w, h) end

--- Casts a ray and returns the nearest hit, or nil.
---@param x1 number Ray start X position.
---@param y1 number Ray start Y position.
---@param x2 number Ray end X position.
---@param y2 number Ray end Y position.
---@return table Hit table, or nil when nothing is hit.
function LWorld:raycast(x1, y1, x2, y2) end

--- Casts a ray and returns all hits.
---@param x1 number Ray origin X position.
---@param y1 number Ray origin Y position.
---@param dx number Ray direction X component.
---@param dy number Ray direction Y component.
---@param maxDist number Maximum query distance.
---@return table Array of hit tables.
function LWorld:raycastAll(x1, y1, dx, dy, maxDist) end

--- Casts a ray and returns the closest hit using the query pipeline.
---@param x1 number Ray origin X position.
---@param y1 number Ray origin Y position.
---@param dx number Ray direction X component.
---@param dy number Ray direction Y component.
---@param maxDist number Maximum query distance.
---@return table Hit table, or nil when nothing is hit.
function LWorld:raycastClosest(x1, y1, dx, dy, maxDist) end

--- Registers a callback fired when two bodies begin touching.
---@param fn function Callback that receives the two body IDs.
---@return nil No return value.
function LWorld:setBeginContact(fn) end

--- Enables or disables Continuous Collision Detection for a body.
---@param bodyId integer Body ID to modify.
---@param enabled boolean Whether CCD should be enabled.
---@return nil No return value.
function LWorld:setBodyCCD(bodyId, enabled) end

--- Attaches arbitrary Lua data to a body for later retrieval.
---@param bodyId integer Body ID to associate with the value.
---@param data LuaValue Lua value to store for the body.
---@return nil No return value.
function LWorld:setBodyData(bodyId, data) end

--- Marks a body as a one-way platform.
---@param bodyId integer Body ID to modify.
---@param nx number One-way normal X component.
---@param ny number One-way normal Y component.
---@return nil No return value.
function LWorld:setBodyOneWay(bodyId, nx, ny) end

--- Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
---@param bodyId integer Body ID to modify.
---@param bodyType string New body type name.
---@return nil No return value.
function LWorld:setBodyType(bodyId, bodyType) end

--- Registers a callback fired when two bodies stop touching.
---@param fn function Callback that receives the two body IDs.
---@return nil No return value.
function LWorld:setEndContact(fn) end

--- Sets friction on a fixture by index.
---@param bodyId integer Body ID to modify.
---@param fixtureIdx integer Fixture index on the body.
---@param friction number New friction coefficient.
---@return nil No return value.
function LWorld:setFixtureFriction(bodyId, fixtureIdx, friction) end

--- Sets restitution on a fixture by index.
---@param bodyId integer Body ID to modify.
---@param fixtureIdx integer Fixture index on the body.
---@param restitution number New restitution coefficient.
---@return nil No return value.
function LWorld:setFixtureRestitution(bodyId, fixtureIdx, restitution) end

--- Sets whether a fixture is a sensor.
---@param bodyId integer Body ID to modify.
---@param fixtureIdx integer Fixture index on the body.
---@param sensor boolean Whether the fixture should act as a sensor.
---@return nil No return value.
function LWorld:setFixtureSensor(bodyId, fixtureIdx, sensor) end

--- Sets the world gravity vector; default is `(0, 9.81)` (downward).
---@param gx number Horizontal gravity component.
---@param gy number Vertical gravity component.
---@return nil No return value.
function LWorld:setGravity(gx, gy) end

--- Sets the relative-velocity threshold above which a joint breaks.
---@param jointId integer Joint ID to modify.
---@param maxForce number Break threshold value.
---@return nil No return value.
function LWorld:setJointBreakForce(jointId, maxForce) end

--- Sets the angular limits on a joint.
---@param jointId integer Joint ID to modify.
---@param lower number Lower angular limit.
---@param upper number Upper angular limit.
---@return nil No return value.
function LWorld:setJointLimits(jointId, lower, upper) end

--- Enables or disables angular limits on a joint.
---@param jointId integer Joint ID to modify.
---@param enabled boolean Whether angular limits are enabled.
---@return nil No return value.
function LWorld:setJointLimitsEnabled(jointId, enabled) end

--- Sets the motor speed on a joint's angular axis.
---@param jointId integer Joint ID to modify.
---@param speed number Motor speed value.
---@return nil No return value.
function LWorld:setJointMotorSpeed(jointId, speed) end

--- Sets the pixels-per-meter scaling factor.
---@param ppm number Pixels-per-meter scaling factor.
---@return nil No return value.
function LWorld:setMeter(ppm) end

--- Updates the target position of a mouse joint.
---@param jointId integer Mouse joint ID to modify.
---@param x number Target X position.
---@param y number Target Y position.
---@return nil No return value.
function LWorld:setMouseJointTarget(jointId, x, y) end

--- Sets the number of constraint solver iterations per step.
---@param n integer Solver iteration count.
---@return nil No return value.
function LWorld:setSolverIterations(n) end

--- Puts a body to sleep immediately.
---@param bodyId integer Body ID to sleep.
---@return nil No return value.
function LWorld:sleepBody(bodyId) end

--- Advances the physics simulation by `dt` seconds.
---@param dt number Time step in seconds.
---@return nil No return value.
function LWorld:step(dt) end

--- Steps the world using a fixed sub-step size to consume accumulated time.
---@param accum number Accumulated time in seconds.
---@param step_dt number Fixed sub-step size.
---@param max_steps integer Maximum sub-steps to run in one call.
---@return number Unconsumed remainder to pass back on the next frame.
function LWorld:stepFixed(accum, step_dt, max_steps) end

--- Converts a pixel value to physics units.
---@param px number Pixel value to convert.
---@return number Converted value in physics units.
function LWorld:toPhysics(px) end

--- Converts a physics-unit value to pixels.
---@param m number Physics-unit value to convert.
---@return number Converted value in pixels.
function LWorld:toPixels(m) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LWorld:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LWorld:typeOf(name) end

--- Forcibly wakes up a sleeping body.
---@param bodyId integer Body ID to wake.
---@return nil No return value.
function LWorld:wakeUpBody(bodyId) end

--- Lua-side handle to a [`PhysicsZone`] living inside a [`World`].
---@class LZone
LZone = {}

--- Removes the zone from the world.
---@return nil No return value.
function LZone:destroy() end

--- Returns the zone's integer ID.
---@return integer Zone ID.
function LZone:getId() end

--- Sets an optional angular damping override for bodies inside the zone.
---@param value? number Angular damping override, or nil to clear it.
---@return nil No return value.
function LZone:setAngularDampingOverride(value) end

--- Replaces the zone boundary with a circle.
---@param cx number Circle center X in world pixels.
---@param cy number Circle center Y in world pixels.
---@param radius number Circle radius in world pixels.
---@return nil No return value.
function LZone:setCircle(cx, cy, radius) end

--- Enables or disables the zone.
---@param enabled boolean Whether the zone is enabled.
---@return nil No return value.
function LZone:setEnabled(enabled) end

--- Sets directional gravity inside the zone.
---@param gx number Horizontal gravity component.
---@param gy number Vertical gravity component.
---@return nil No return value.
function LZone:setGravityDirectional(gx, gy) end

--- Sets point-attractor gravity inside the zone.
---@param cx number Attractor center X.
---@param cy number Attractor center Y.
---@param strength number Attraction strength constant.
---@return nil No return value.
function LZone:setGravityPoint(cx, cy, strength) end

--- Sets point-repulsor gravity inside the zone.
---@param cx number Repulsor center X.
---@param cy number Repulsor center Y.
---@param strength number Repulsion strength constant.
---@return nil No return value.
function LZone:setGravityRepulsor(cx, cy, strength) end

--- Suppresses gravity inside the zone (zero-g pocket).
---@return nil No return value.
function LZone:setGravityZero() end

--- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
---@param mask integer Layer mask bitset.
---@return nil No return value.
function LZone:setLayerMask(mask) end

--- Sets an optional linear damping override for bodies inside the zone.
---@param value? number Linear damping override, or nil to clear it.
---@return nil No return value.
function LZone:setLinearDampingOverride(value) end

--- Sets the zone priority; higher values win over lower when zones overlap.
---@param priority integer Zone priority value.
---@return nil No return value.
function LZone:setPriority(priority) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LZone:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LZone:typeOf(name) end

--- Attaches a standalone shape to a body as an additional fixture.
---@param body LBody Body handle that receives the shape.
---@param shape LPhysicsShape Shape handle to attach.
---@return nil No return value.
lurek.physics.attachShape = function(body, shape) end

--- Enables or disables the physics debug overlay (AABB boxes and velocity vectors).
---@param enable boolean Whether the debug overlay is enabled.
---@return nil No return value.
lurek.physics.debugDraw = function(enable) end

--- Marks a physics world for destruction.
---@param world LWorld World handle to release.
---@return nil No return value.
lurek.physics.destroyWorld = function(world) end

--- Queues a GPU physics debug draw command for the current frame.
---@param world LWorld Physics world to visualize.
---@param config? table Optional debug draw appearance overrides.
---@return nil No return value.
lurek.physics.drawDebugGpu = function(world, config) end

--- Returns the position and velocity of a body (x, y, vx, vy).
---@param world LWorld World handle kept for API symmetry.
---@param body LBody Body handle to inspect.
---@return number Body X position.
---@return number Body Y position.
---@return number Body X velocity.
---@return number Body Y velocity.
lurek.physics.getBody = function(world, body) end

--- Returns all collision events from the last simulation step.
---@param world LWorld World handle to inspect.
---@return table Array of collision tables with `body_a` and `body_b` fields.
lurek.physics.getCollisions = function(world) end

--- Returns whether the body is allowed to sleep.
---@param world LWorld World handle kept for API symmetry.
---@param body LBody Body handle to inspect.
---@return boolean True when the body can sleep.
lurek.physics.isSleepingAllowed = function(world, body) end

--- Creates a new rectangular body in the given world.
---@param world LWorld World handle that owns the body.
---@param x number Initial X position.
---@param y number Initial Y position.
---@param bodyType string Body type name.
---@return LBody New body handle.
lurek.physics.newBody = function(world, x, y, bodyType) end

--- Creates a falling-sand cellular automaton grid.
---@param width integer Grid width in cells.
---@param height integer Grid height in cells.
---@return LCellular New cellular simulation handle.
lurek.physics.newCellular = function(width, height) end

--- Creates a chain shape userdata from flat variadic vertex pairs.
---@param closed boolean Whether the chain closes back to the start.
---@param ... number Flat x and y vertex pairs with at least two vertices.
---@return LPhysicsShape New shape handle.
lurek.physics.newChainShape = function(closed, ...) end

--- Creates a circle shape userdata.
---@param radius number Circle radius.
---@return LPhysicsShape New shape handle.
lurek.physics.newCircleShape = function(radius) end

--- Creates an edge (line segment) shape userdata.
---@param x1 number First endpoint X position.
---@param y1 number First endpoint Y position.
---@param x2 number Second endpoint X position.
---@param y2 number Second endpoint Y position.
---@return LPhysicsShape New shape handle.
lurek.physics.newEdgeShape = function(x1, y1, x2, y2) end

--- Creates a convex polygon shape userdata from flat variadic vertex pairs.
---@param ... number Flat x and y vertex pairs with at least three vertices.
---@return LPhysicsShape New shape handle.
lurek.physics.newPolygonShape = function(...) end

--- Creates a rectangle shape userdata.
---@param width number Rectangle width.
---@param height number Rectangle height.
---@return LPhysicsShape New shape handle.
lurek.physics.newRectangleShape = function(width, height) end

--- Creates a destructible terrain grid.
---@param width integer Grid width in cells.
---@param height integer Grid height in cells.
---@param cell_size number World units per cell.
---@param world_handle LWorld Physics world that receives terrain colliders.
---@return LTerrain New terrain handle.
lurek.physics.newTerrain = function(width, height, cell_size, world_handle) end

--- Creates a new physics world with the given gravity vector.
---@param gx number Horizontal gravity component.
---@param gy number Vertical gravity component.
---@return LWorld New world handle.
lurek.physics.newWorld = function(gx, gy) end

--- Sets the velocity of a body.
---@param world LWorld World handle kept for API symmetry.
---@param body LBody Body handle to modify.
---@param vx number Linear velocity X component.
---@param vy number Linear velocity Y component.
---@return nil No return value.
lurek.physics.setBodyVelocity = function(world, body, vx, vy) end

--- Sets whether the body is allowed to sleep.
---@param world LWorld World handle kept for API symmetry.
---@param body LBody Body handle to modify.
---@param allowed boolean Whether the body can sleep.
---@return nil No return value.
lurek.physics.setSleepingAllowed = function(world, body, allowed) end

--- Advances the physics world by dt seconds.
---@param world LWorld World handle to step.
---@param dt number Time step in seconds.
---@return nil No return value.
lurek.physics.step = function(world, dt) end

--- Returns true when two axis-aligned bounding boxes overlap.
---@param ax number Left edge of box A.
---@param ay number Top edge of box A.
---@param aw number Width of box A.
---@param ah number Height of box A.
---@param bx number Left edge of box B.
---@param by number Top edge of box B.
---@param bw number Width of box B.
---@param bh number Height of box B.
---@return boolean True when the boxes overlap.
lurek.physics.testAABB = function(ax, ay, aw, ah, bx, by, bw, bh) end

--- Returns true when a circle overlaps an AABB.
---@param cx number Circle center X position.
---@param cy number Circle center Y position.
---@param cr number Circle radius.
---@param ax number Left edge of the AABB.
---@param ay number Top edge of the AABB.
---@param aw number Width of the AABB.
---@param ah number Height of the AABB.
---@return boolean True when the circle overlaps the AABB.
lurek.physics.testCircleAABB = function(cx, cy, cr, ax, ay, aw, ah) end

--- Returns true when two circles overlap.
---@param ax number Center X of circle A.
---@param ay number Center Y of circle A.
---@param ar number Radius of circle A.
---@param bx number Center X of circle B.
---@param by number Center Y of circle B.
---@param br number Radius of circle B.
---@return boolean True when the circles overlap.
lurek.physics.testCircles = function(ax, ay, ar, bx, by, br) end

--- Returns true when point (px, py) lies inside the AABB.
---@param px number Point X position.
---@param py number Point Y position.
---@param ax number Left edge of the AABB.
---@param ay number Top edge of the AABB.
---@param aw number Width of the AABB.
---@param ah number Height of the AABB.
---@return boolean True when the point lies inside the AABB.
lurek.physics.testPoint = function(px, py, ax, ay, aw, ah) end

---@class lurek.pipeline
lurek.pipeline = {}

---@class LPipeline
LPipeline = {}

--- Adds a conditional step to the pipeline.
---@param name string Step name.
---@param deps table Array of dependency step names.
---@param fn function Step callback.
---@param when_fn function Callback that returns whether the step should run.
---@return LPipeline This pipeline for chaining.
function LPipeline:addConditional(name, deps, fn, when_fn) end

--- Adds a step to the pipeline.
---@param step LPipelineStep Step to add.
---@return LPipeline This pipeline for chaining.
function LPipeline:addStep(step) end

--- Inlines all steps from a sub-pipeline into this pipeline.
---@param sub_pipeline LPipeline Source pipeline to inline.
---@param alias string Prefix added to each inlined step name.
---@param outer_deps? table Array of outer step names that entry steps should depend on.
---@return nil No value is returned.
function LPipeline:addSubPipeline(sub_pipeline, alias, outer_deps) end

--- Cancels all pending and waiting steps.
---@return nil No value is returned.
function LPipeline:cancel() end

--- Clears all steps from the pipeline.
---@return nil No value is returned.
function LPipeline:clear() end

--- Returns the stored asynchronous context table.
---@return table Context table, or `nil` if no async run is active.
function LPipeline:getContext() end

--- Returns the current error mode.
---@return string Either `"abort"` or `"continue"`.
function LPipeline:getErrorMode() end

--- Returns the topological execution order.
---@return table Step-name array in execution order.
---@return string Error message when execution order cannot be produced.
function LPipeline:getExecutionOrder() end

--- Returns the pipeline name.
---@return string Pipeline name.
function LPipeline:getName() end

--- Returns the pipeline's parallel execution groups.
---@return table Nested step-name arrays grouped for parallel execution.
---@return string Error message when the groups cannot be produced.
function LPipeline:getParallelGroups() end

--- Returns the current result table.
---@return table Result table, or `nil` if the pipeline has no steps.
function LPipeline:getResult() end

--- Returns the step wrapper for the named step.
---@param name string Step name.
---@return LPipelineStep Matching step wrapper, or `nil` if not found.
function LPipeline:getStep(name) end

--- Returns the total number of steps.
---@return integer Step count.
function LPipeline:getStepCount() end

--- Returns all step wrappers in the pipeline.
---@return table Array of `LPipelineStep` userdata.
function LPipeline:getSteps() end

--- Returns all steps with a matching tag.
---@param tag string Tag to match.
---@return table Array of `LPipelineStep` userdata.
function LPipeline:getStepsByTag(tag) end

--- Returns whether all steps have reached a terminal state.
---@return boolean True when no step is still pending or waiting.
function LPipeline:isComplete() end

--- Returns whether the pipeline is running asynchronously.
---@return boolean True when an async run is active.
function LPipeline:isRunning() end

--- Registers a callback invoked after every step.
---@param fn function Callback called with `(step_name, status)`.
---@return nil No value is returned.
function LPipeline:onProgress(fn) end

--- Removes a step from the pipeline by name.
---@param name string Step name.
---@return nil No value is returned.
function LPipeline:removeStep(name) end

--- Resets all step states and clears async pipeline state.
---@return nil No value is returned.
function LPipeline:reset() end

--- Executes the pipeline synchronously in topological order.
---@param context? table Context table passed to step callbacks.
---@return table Pipeline result table.
function LPipeline:run(context) end

--- Starts an asynchronous pipeline run.
---@param context? table Context table passed to step callbacks.
---@return nil No value is returned.
function LPipeline:runAsync(context) end

--- Sets the pipeline error mode.
---@param mode string Either `"abort"` or `"continue"`.
---@return nil No value is returned.
function LPipeline:setErrorMode(mode) end

--- Sets the pipeline name.
---@param name string New pipeline name.
---@return nil No value is returned.
function LPipeline:setName(name) end

--- Sets the callback invoked when the pipeline completes.
---@param fn? function Callback called with the result table.
---@return nil No value is returned.
function LPipeline:setOnComplete(fn) end

--- Sets the callback invoked when a step completes successfully.
---@param fn? function Callback called with the step name and context table.
---@return nil No value is returned.
function LPipeline:setOnStepComplete(fn) end

--- Sets the callback invoked when a step fails.
---@param fn? function Callback called with the step name and error message.
---@return nil No value is returned.
function LPipeline:setOnStepError(fn) end

--- Returns an ASCII diagram of the pipeline DAG.
---@return string Multi-line diagram showing parallel groups and dependencies.
function LPipeline:toAscii() end

--- Serialises the pipeline definition to a Lua table.
---@return table Pipeline definition table without callbacks.
function LPipeline:toTable() end

--- Returns the Lua-visible type name for this pipeline.
---@return string Always `LPipeline`.
function LPipeline:type() end

--- Returns whether the given type name matches this pipeline.
---@param name string Type name to test.
---@return boolean True when the name matches this type or a parent type.
function LPipeline:typeOf(name) end

--- Advances the asynchronous pipeline by one tick.
---@param dt number Delta time in seconds.
---@return boolean True when all steps have finished.
function LPipeline:update(dt) end

--- Validates the pipeline dependency graph.
---@return boolean True when the pipeline dependency graph is valid.
---@return table Array of validation error strings.
function LPipeline:validate() end

---@class LPipelineStep
LPipelineStep = {}

--- Adds a dependency on another step.
---@param dep LuaValue Dependency step name or `LPipelineStep` userdata.
---@return LPipelineStep This step for chaining.
function LPipelineStep:dependsOn(dep) end

--- Returns the number of execution attempts so far.
---@return integer Attempt count.
function LPipelineStep:getAttempt() end

--- Returns a metadata value by key.
---@param key string Metadata key.
---@return string Metadata value, or `nil` if the key is missing.
function LPipelineStep:getData(key) end

--- Returns the configured delay in seconds.
---@return number Delay in seconds.
function LPipelineStep:getDelay() end

--- Returns the dependency step names.
---@return table Array of dependency step names.
function LPipelineStep:getDependencies() end

--- Returns the number of declared dependencies.
---@return integer Dependency count.
function LPipelineStep:getDependencyCount() end

--- Returns the total time spent executing this step.
---@return number Duration in seconds.
function LPipelineStep:getDuration() end

--- Returns the error message from the last failed attempt.
---@return string Error message, or `nil` if the step has not failed.
function LPipelineStep:getError() end

--- Returns the unique name of this step.
---@return string Step name.
function LPipelineStep:getName() end

--- Returns the configured retry count.
---@return integer Retry count.
function LPipelineStep:getRetryCount() end

--- Returns the current execution status.
---@return string Lowercase status string.
function LPipelineStep:getStatus() end

--- Returns the tag on this step.
---@return string Tag string, or `nil` if unset.
function LPipelineStep:getTag() end

--- Returns the timeout stored in metadata.
---@return number Timeout in seconds, or `0.0` if unset.
function LPipelineStep:getTimeout() end

--- Returns whether this step is marked as optional.
---@return boolean True when the step is optional.
function LPipelineStep:isOptional() end

--- Stores the execute callback for this step.
---@param fn function Callback called with the pipeline context table.
---@return nil No value is returned.
function LPipelineStep:setCallback(fn) end

--- Stores the run condition callback for this step.
---@param fn? function Callback that returns whether the step should run.
---@return nil No value is returned.
function LPipelineStep:setCondition(fn) end

--- Stores a metadata string value on this step.
---@param key string Metadata key.
---@param value string Metadata value.
---@return nil No value is returned.
function LPipelineStep:setData(key, value) end

--- Sets the delay to wait after dependencies finish.
---@param seconds number Delay in seconds.
---@return nil No value is returned.
function LPipelineStep:setDelay(seconds) end

--- Stores the error callback for this step.
---@param fn? function Callback called with the step name and error message.
---@return nil No value is returned.
function LPipelineStep:setOnError(fn) end

--- Sets whether this step is optional.
---@param optional boolean Whether downstream steps continue after this step fails.
---@return nil No value is returned.
function LPipelineStep:setOptional(optional) end

--- Sets the maximum number of retry attempts after failure.
---@param count integer Retry count.
---@return nil No value is returned.
function LPipelineStep:setRetryCount(count) end

--- Sets the delay between retry attempts.
---@param seconds number Delay in seconds.
---@return nil No value is returned.
function LPipelineStep:setRetryDelay(seconds) end

--- Sets the tag on this step.
---@param tag string Tag used for grouping and filtering.
---@return nil No value is returned.
function LPipelineStep:setTag(tag) end

--- Stores a timeout value in this step's metadata.
---@param seconds number Timeout in seconds.
---@return nil No value is returned.
function LPipelineStep:setTimeout(seconds) end

--- Returns the Lua-visible type name for this step.
---@return string Always `LPipelineStep`.
function LPipelineStep:type() end

--- Returns whether the given type name matches this step.
---@param name string Type name to test.
---@return boolean True when the name matches this type or a parent type.
function LPipelineStep:typeOf(name) end

--- Deserialises a pipeline from a definition table.
---@param def table Pipeline definition table.
---@return LPipeline New pipeline wrapper built from the table.
lurek.pipeline.fromTable = function(def) end

--- Creates a new empty pipeline.
---@param name? string Optional pipeline name.
---@return LPipeline New pipeline wrapper.
lurek.pipeline.newPipeline = function(name) end

--- Creates a new pipeline step.
---@param name string Step name.
---@param fn? function Optional step callback.
---@return LPipelineStep New pipeline step wrapper.
lurek.pipeline.newStep = function(name, fn) end

---@class lurek.procgen
lurek.procgen = {}

--- Generates a dungeon using Binary Space Partitioning.
---@param opts? table Optional BSP dungeon settings.
---@return table Generated dungeon data.
lurek.procgen.bspDungeon = function(opts) end

--- Generates a cave-like map using cellular automata.
---@param w integer Output grid width.
---@param h integer Output grid height.
---@param opts? table Optional cellular automata settings.
---@return table Generated grid values.
lurek.procgen.cellularAutomata = function(w, h, opts) end

--- BFS flood fill on a flat grid of bytes.
---@param data table Flat byte grid data.
---@param w integer Grid width.
---@param h integer Grid height.
---@param sx integer Start X coordinate.
---@param sy integer Start Y coordinate.
---@param threshold? integer Optional threshold value.
---@param above? boolean Whether to match values above the threshold.
---@return table Flood-fill mask values.
lurek.procgen.floodFill = function(data, w, h, sx, sy, threshold, above) end

--- Generates a single procedural name using a Markov chain.
---@param samples table Source names used to train the generator.
---@param min_len? integer Optional minimum output length.
---@param max_len? integer Optional maximum output length.
---@param seed? integer Optional random seed.
---@return string Generated name.
lurek.procgen.generateName = function(samples, min_len, max_len, seed) end

--- Generates N procedural names using a Markov chain.
---@param samples table Source names used to train the generator.
---@param n integer Number of names to generate.
---@param min_len? integer Optional minimum output length.
---@param max_len? integer Optional maximum output length.
---@param seed? integer Optional random seed.
---@return table Array of generated names.
lurek.procgen.generateNames = function(samples, n, min_len, max_len, seed) end

--- Generates a heightmap using fractal noise.
---@param opts? table Optional heightmap settings.
---@return table Generated heightmap data.
lurek.procgen.heightmap = function(opts) end

--- Generates an L-system string.
---@param opts table L-system settings table.
---@return string Generated L-system string.
lurek.procgen.lsystem = function(opts) end

--- Generates L-system line segments for rendering.
---@param opts table L-system settings table.
---@param angle_deg? number Optional turn angle in degrees.
---@param step? number Optional step length.
---@return table Array of line-segment tables.
lurek.procgen.lsystemSegments = function(opts, angle_deg, step) end

--- Generates a noise map using the configurable NoiseGenerator.
---@param width integer Output width.
---@param height integer Output height.
---@param opts? table Optional noise generator settings.
---@return table Generated noise values.
lurek.procgen.noiseMap = function(width, height, opts) end

--- Generates a noise map using rayon parallel processing.
---@param width integer Output width.
---@param height integer Output height.
---@param opts? table Optional noise generator settings.
---@return table Generated noise values.
lurek.procgen.noiseMapParallel = function(width, height, opts) end

--- Evaluates periodic Perlin noise at a point.
---@param x number Sample X coordinate.
---@param y number Sample Y coordinate.
---@param px number Period on the X axis.
---@param py number Period on the Y axis.
---@return number Noise value.
lurek.procgen.perlinNoise = function(x, y, px, py) end

--- Generates Poisson disk sample points using Bridson's algorithm.
---@param w number Sample area width.
---@param h number Sample area height.
---@param min_dist number Minimum distance between points.
---@param max_attempts? integer Optional maximum attempts per active point.
---@param seed? integer Optional random seed.
---@return table Array of generated point tables.
lurek.procgen.poissonDisk = function(w, h, min_dist, max_attempts, seed) end

--- Generates a rooms-and-corridors dungeon.
---@param opts? table Optional room dungeon settings.
---@return table Generated dungeon data.
lurek.procgen.roomsDungeon = function(opts) end

--- Returns a single Simplex noise value at the given 2-D coordinate.
---@param x number Sample X coordinate.
---@param y number Sample Y coordinate.
---@return number Noise value.
lurek.procgen.simplex2d = function(x, y) end

--- Returns a single Simplex noise value at the given 3-D coordinate.
---@param x number Sample X coordinate.
---@param y number Sample Y coordinate.
---@param z number Sample Z coordinate.
---@return number Noise value.
lurek.procgen.simplex3d = function(x, y, z) end

--- Generates a Voronoi diagram for a set of seed points.
---@param w integer Diagram width.
---@param h integer Diagram height.
---@param pts table Array of `{ x, y }` seed point tables.
---@param opts? table Optional Voronoi generation settings.
---@return table Region ID values for each cell.
---@return table Distance to the nearest seed for each cell.
---@return table Distance to the second-nearest seed for each cell.
lurek.procgen.voronoi = function(w, h, pts, opts) end

--- Generates a tile grid using Wave Function Collapse.
---@param opts table Wave Function Collapse settings table.
---@return table Generated tile grid data.
lurek.procgen.wfcGenerate = function(opts) end

--- Generates a world graph with scattered regions and edges.
---@param width number World width.
---@param height number World height.
---@param region_count integer Number of regions to generate.
---@param seed? integer Optional random seed.
---@return table Generated world graph data.
lurek.procgen.worldGraph = function(width, height, region_count, seed) end

---@class lurek.raycaster
lurek.raycaster = {}

--- Lua-side wrapper around a [`DoorManager`], managing sliding doors in a level.
---@class LDoorManager
LDoorManager = {}

--- Registers a door at grid position (x, y).
---@param x integer Grid column for the door.
---@param y integer Grid row for the door.
---@param direction string Door orientation: "horizontal" or "vertical".
---@param speed number Door animation speed in units per second.
---@return integer Door index for open/close calls.
function LDoorManager:addDoor(x, y, direction, speed) end

--- Begins closing the door at the given index.
---@param index integer Door index returned by `addDoor`.
---@return nil No value is returned.
function LDoorManager:closeDoor(index) end

--- Returns the number of registered doors.
---@return integer Number of doors tracked by this manager.
function LDoorManager:count() end

--- Returns the state table for door at index, or nil if out of range.
---@param index integer Door index returned by `addDoor`.
---@return table Door state table with x, y, openAmount, and state fields.
function LDoorManager:getDoor(index) end

--- Begins opening the door at the given index.
---@param index integer Door index returned by `addDoor`.
---@return nil No value is returned.
function LDoorManager:openDoor(index) end

--- Returns the Lua type name for this userdata.
---@return string Always `LDoorManager`.
function LDoorManager:type() end

--- Returns the legacy parent type tag used by this binding.
---@return string Always `DoorManager`.
function LDoorManager:typeOf() end

--- Advances all door animations by dt seconds.
---@param dt number Elapsed time in seconds.
---@return nil No value is returned.
function LDoorManager:update(dt) end

--- Lua-side wrapper around a [`HeightMap`] for variable floor/ceiling heights.
---@class LHeightMap
LHeightMap = {}

--- Returns the ceiling height at (x, y). Returns 1.0 for out-of-bounds.
---@param x integer X position.
---@param y integer Y position.
---@return number Ceiling height at the grid cell.
function LHeightMap:ceilingAt(x, y) end

--- Returns the floor height at (x, y). Returns 0.0 for out-of-bounds.
---@param x integer X position.
---@param y integer Y position.
---@return number Floor height at the grid cell.
function LHeightMap:floorAt(x, y) end

--- Sets the ceiling height at (x, y).
---@param x integer X position.
---@param y integer Y position.
---@param h number Height value.
---@return nil No value is returned.
function LHeightMap:setCeiling(x, y, h) end

--- Sets the floor height at (x, y).
---@param x integer X position.
---@param y integer Y position.
---@param h number Height value.
---@return nil No value is returned.
function LHeightMap:setFloor(x, y, h) end

--- Returns the type string "HeightMap".
---@return string Always "LHeightMap".
function LHeightMap:type() end

--- Returns the type string "HeightMap".
---@return string Always "HeightMap".
function LHeightMap:typeOf() end

--- Lua-side value wrapper around a raycaster [`PointLight`].
---@class LPointLight
LPointLight = {}

--- Returns the RGB color as three separate values.
---@return number Red component.
---@return number Green component.
---@return number Blue component.
function LPointLight:color() end

--- Returns the intensity multiplier.
---@return number Intensity multiplier.
function LPointLight:intensity() end

--- Returns the illumination radius.
---@return number Illumination radius.
function LPointLight:radius() end

--- Updates all light properties at once.
---@param x number X position.
---@param y number Y position.
---@param r number - Red   [0,1].
---@param g number - Green [0,1].
---@param b number - Blue  [0,1].
---@param radius number Radius value.
---@param intensity number Intensity value.
---@return nil No value is returned.
function LPointLight:set(x, y, r, g, b, radius, intensity) end

--- Returns the type string "PointLight".
---@return string Always "LPointLight".
function LPointLight:type() end

--- Returns the type string "PointLight".
---@return string Always "PointLight".
function LPointLight:typeOf() end

--- Returns the world-space X position.
---@return number World-space X position.
function LPointLight:x() end

--- Returns the world-space Y position.
---@return number World-space Y position.
function LPointLight:y() end

--- Lua-side wrapper around a [`Raycaster2D`] grid.
---@class LRaycaster
LRaycaster = {}

--- Builds a raycaster scene and stores it in SharedState for GPU rendering.
---@param params table - { px, py, angle, fov, rays, max_dist, screen_w, screen_h, ambient?, shade_dist?, floor_color?, ceiling_color? }.
---@param lights table nil | - array of { x, y, radius, r, g, b, intensity }.
---@param sprites table nil | - array of { x, y, texture, size }.
---@param wall_textures table nil | - { [cell_value] = TextureKey }.
---@return nil No value is returned.
function LRaycaster:buildScene(params, lights, sprites, wall_textures) end

--- Computes floor (or ceiling) texture UV coordinates for one horizontal screen row.
---@param cam_x number Camera X position.
---@param cam_y number Camera Y position.
---@param dir_x number Direction X component.
---@param dir_y number Direction Y component.
---@param plane_x number Camera plane X component.
---@param plane_y number Camera plane Y component.
---@param row integer Row position.
---@return table Array of {u, v} tables for the requested row.
function LRaycaster:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, row) end

--- Casts a single ray and returns a hit table, or nil if nothing was hit.
---@param ox number Origin X offset.
---@param oy number Origin Y offset.
---@param angle number Angle in radians.
---@param max_dist number Maximum distance.
---@return table Hit table, or nil if nothing was hit.
function LRaycaster:castRay(ox, oy, angle, max_dist) end

--- Casts a ray collecting up to max_hits wall layers, continuing through
---@param ox number Origin X offset.
---@param oy number Origin Y offset.
---@param angle number Angle in radians.
---@param max_dist number Maximum distance.
---@param max_hits? integer - layers to collect (default 4, max 8).
---@return table Array of hit tables ordered nearest to farthest.
function LRaycaster:castRayMulti(ox, oy, angle, max_dist, max_hits) end

--- Casts multiple rays across a field of view, returns an array of hit tables.
---@param ox number Origin X offset.
---@param oy number Origin Y offset.
---@param angle number Angle in radians.
---@param fov number Field of view in radians.
---@param count integer Number of rays to cast.
---@param max_dist number Maximum distance.
---@return table Array of hit tables, one per ray.
function LRaycaster:castRays(ox, oy, angle, fov, count, max_dist) end

--- Casts multiple rays and returns a flat array of 5 floats per ray.
---@param ox number Origin X offset.
---@param oy number Origin Y offset.
---@param angle number Angle in radians.
---@param fov number Field of view in radians.
---@param count integer Number of rays to cast.
---@param max_dist number Maximum distance.
---@return table Flat array with five values per ray.
function LRaycaster:castRaysFlat(ox, oy, angle, fov, count, max_dist) end

--- Renders a mosaic of first-person views from evenly spaced angles to an ImageData.
---@param x number X position.
---@param y number Y position.
---@param fov number Field of view in radians.
---@param max_dist number Maximum distance.
---@param num_frames integer Number of frames.
---@param frame_w integer Frame width in pixels.
---@param frame_h integer Frame height in pixels.
---@return ImageData Image data object.
function LRaycaster:drawCameraSweep(x, y, fov, max_dist, num_frames, frame_w, frame_h) end

--- Renders a depth-map column view to an ImageData.
---@param px number Screen X position.
---@param py number Screen Y position.
---@param angle number Angle in radians.
---@param fov number Field of view in radians.
---@param num_rays integer Number of rays.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@param max_dist number Maximum distance.
---@return ImageData Image data object.
function LRaycaster:drawDepthMap(px, py, angle, fov, num_rays, width, height, max_dist) end

--- Renders a line-of-sight test between two points to an ImageData.
---@param ax number Ax value.
---@param ay number Ay value.
---@param bx number Bx value.
---@param by number By value.
---@param scale integer Scale factor.
---@return ImageData Image data object.
function LRaycaster:drawLineOfSight(ax, ay, bx, by, scale) end

--- Renders a top-down grid view with player marker to an ImageData.
---@param px number Screen X position.
---@param py number Screen Y position.
---@param angle number Angle in radians.
---@param scale integer Scale factor.
---@return ImageData Image data object.
function LRaycaster:drawTopDown(px, py, angle, scale) end

--- Renders a first-person column view to an ImageData.
---@param px number Screen X position.
---@param py number Screen Y position.
---@param angle number Angle in radians.
---@param fov number Field of view in radians.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@param max_dist number Maximum distance.
---@return ImageData Image data object.
function LRaycaster:drawView(px, py, angle, fov, width, height, max_dist) end

--- Returns the cell value at (x, y).
---@param x integer X position.
---@param y integer Y position.
---@return integer Cell value at the grid position.
function LRaycaster:getCell(x, y) end

--- Returns the opacity for a wall tile type. Returns 1.0 if not set.
---@param tile_type integer Tile type id.
---@return number Wall opacity for the tile type. Returns 1.0 if unset.
function LRaycaster:getWallAlpha(tile_type) end

--- Returns the grid height in cells.
---@return integer Grid height in cells.
function LRaycaster:height() end

--- Returns true when the cell at (x, y) is a wall (value > 0).
---@param x integer X position.
---@param y integer Y position.
---@return boolean Whether the cell at the grid position is blocked.
function LRaycaster:isBlocked(x, y) end

--- Checks line of sight between two points using DDA traversal.
---@param x1 number End X position.
---@param y1 number End Y position.
---@param x2 number Second X position.
---@param y2 number Second Y position.
---@return boolean True if there is a clear line of sight between the two points.
function LRaycaster:lineOfSight(x1, y1, x2, y2) end

--- Projects a world-space sprite onto screen space.
---@param sx number Screen X position.
---@param sy number Screen Y position.
---@param px number Screen X position.
---@param py number Screen Y position.
---@param pa number Pa value.
---@param fov number Field of view in radians.
---@param screen_w number Screen width in pixels.
---@return table Table with screen_x, scale, distance, and visible fields.
function LRaycaster:projectSprite(sx, sy, px, py, pa, fov, screen_w) end

--- Sets the cell value at grid position (x, y).
---@param x integer X position.
---@param y integer Y position.
---@param val integer Val value.
---@return nil No value is returned.
function LRaycaster:setCell(x, y, val) end

--- Replaces all grid cells from a flat array of values in row-major order.
---@param cells table Cells value.
---@return nil No value is returned.
function LRaycaster:setCells(cells) end

--- Sets the opacity for a wall tile type. Alpha is clamped to [0, 1].
---@param tile_type integer Tile type id.
---@param alpha number Alpha value.
---@return nil No value is returned.
function LRaycaster:setWallAlpha(tile_type, alpha) end

--- Returns the type name of this object.
---@return string Always "LRaycaster".
function LRaycaster:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True if name matches LRaycaster or Object.
function LRaycaster:typeOf(name) end

--- Returns the grid width in cells.
---@return integer Grid width in cells.
function LRaycaster:width() end

--- Lua-side wrapper around a [`SpriteManager`] for batch depth-sorted sprite projection.
---@class LSpriteManager
LSpriteManager = {}

--- Adds a sprite at world position (x, y) and returns its unique id.
---@param x number X position.
---@param y number Y position.
---@param texture string Texture value.
---@param scale? number (optional, default 1.0).
---@return integer Unique sprite ID.
function LSpriteManager:add(x, y, texture, scale) end

--- Removes all sprites from the manager.
---@return nil No value is returned.
function LSpriteManager:clear() end

--- Removes the sprite with the given id. No-op if not found.
---@param id integer Object id.
---@return nil No value is returned.
function LSpriteManager:remove(id) end

--- Moves the sprite with the given id to world (x, y).
---@param id integer Object id.
---@param x number X position.
---@param y number Y position.
---@return nil No value is returned.
function LSpriteManager:setPosition(id, x, y) end

--- Shows or hides the sprite with the given id.
---@param id integer Object id.
---@param visible boolean Whether it is visible.
---@return nil No value is returned.
function LSpriteManager:setVisible(id, visible) end

--- Returns an array of visible sprites sorted back-to-front from camera position.
---@param cam_x number Camera X position.
---@param cam_y number Camera Y position.
---@param cam_angle number Camera angle in radians.
---@return table Array of projected sprite tables.
function LSpriteManager:sortAndProject(cam_x, cam_y, cam_angle) end

--- Returns the type string "SpriteManager".
---@return string Always "LSpriteManager".
function LSpriteManager:type() end

--- Returns the type string "SpriteManager".
---@return string Always "SpriteManager".
function LSpriteManager:typeOf() end

--- Returns distance-based brightness in [0, 1].
---@param distance number Distance value.
---@param max_distance number Maximum distance.
---@return number Distance-based brightness in the range 0 to 1.
lurek.raycaster.distanceShade = function(distance, max_distance) end

--- Creates a new raycaster grid of the given dimensions.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return Raycaster New raycaster grid of the given dimensions.
lurek.raycaster.new = function(width, height) end

--- Creates a new empty door manager.
---@return DoorManager New empty door manager.
lurek.raycaster.newDoorManager = function() end

--- Creates a new height map with default floor (0.0) and ceiling (1.0) values.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return HeightMap New height map with default floor (0.0) and ceiling (1.0) values.
lurek.raycaster.newHeightMap = function(width, height) end

--- Alias for `new`. Creates a new raycaster grid of the given dimensions.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return Raycaster Raycaster userdata.
lurek.raycaster.newMap = function(width, height) end

--- Creates a point light for use in raycaster scene lighting.
---@param x number - World-space X.
---@param y number - World-space Y.
---@param r number - Red   [0,1].
---@param g number - Green [0,1].
---@param b number - Blue  [0,1].
---@param radius number - Maximum illumination radius.
---@param intensity number - Brightness multiplier.
---@return PointLight New point light for use in raycaster scene lighting.
lurek.raycaster.newPointLight = function(x, y, r, g, b, radius, intensity) end

--- Creates a new empty batch sprite manager for depth-sorted projection.
---@return SpriteManager New empty batch sprite manager for depth-sorted projection.
lurek.raycaster.newSpriteManager = function() end

--- Projects a wall distance to screen-space drawing parameters.
---@param distance number Distance value.
---@param fov number Field of view in radians.
---@param screen_height number Screen height value.
---@return number Projected wall height in screen pixels.
---@return number Screen-space start Y coordinate.
---@return number Screen-space end Y coordinate.
lurek.raycaster.projectColumn = function(distance, fov, screen_height) end

---@class lurek.render
lurek.render = {}

--- Lua-side handle to an off-screen render target stored in SharedState.
---@class LCanvas
LCanvas = {}

--- Returns width and height of this canvas.
---@return integer Canvas width in pixels.
---@return integer Canvas height in pixels.
function LCanvas:getDimensions() end

--- Returns the height of this canvas in pixels.
---@return integer Canvas height in pixels.
function LCanvas:getHeight() end

--- Returns the width of this canvas in pixels.
---@return integer Canvas width in pixels.
function LCanvas:getWidth() end

--- Releases GPU framebuffer memory for this canvas.
---@return boolean True when the canvas was released.
function LCanvas:release() end

--- Returns the Lua type name for this canvas handle.
---@return string Lua type name for this object.
function LCanvas:type() end

--- Returns the Lua type name for this canvas object.
---@return string Lua type name for this object.
function LCanvas:typeOf() end

--- Lua-side z-ordered draw queue. Callbacks are sorted by z and called on `flush()`.
---@class LDrawLayer
LDrawLayer = {}

--- Removes all queued callbacks without calling them.
---@return nil No return value.
function LDrawLayer:clear() end

--- Sorts and calls all queued callbacks, then empties the queue.
---@return nil No return value.
function LDrawLayer:flush() end

--- Returns the number of queued callbacks.
---@return number Number of queued callbacks.
function LDrawLayer:getCount() end

--- Queues a draw callback at the given z-order.
---@param z number Z order for the callback.
---@param fn function Callback to queue.
---@return nil No return value.
function LDrawLayer:queue(z, fn) end

--- Returns the string type identifier of this draw layer (for example `LDrawLayer`).
---@return string Lua type name for this object.
function LDrawLayer:type() end

--- Returns true if this object is an instance of the given type name.
---@param name string Type name to test.
---@return boolean True when the name matches this type or a parent type.
function LDrawLayer:typeOf(name) end

--- Lua-side handle to a loaded font stored in SharedState.
---@class LFont
LFont = {}

--- Returns the ascent of this font in pixels.
---@return number Font ascent in pixels.
function LFont:getAscent() end

--- Returns the descent of this font in pixels.
---@return number Font descent in pixels.
function LFont:getDescent() end

--- Returns the line height of this font.
---@return number Line height of this font.
function LFont:getHeight() end

--- Returns the line height multiplier of this font.
---@return number Line height multiplier of this font.
function LFont:getLineHeight() end

--- Returns the rendered width of the given text string.
---@param text string Text to measure.
---@return number Rendered width of the text.
function LFont:getWidth(text) end

--- Wraps text to the given width and returns the lines.
---@param text string Text to wrap.
---@param limit number Maximum line width.
---@return table Wrapped lines as an array of strings.
---@return number Width of the widest wrapped line.
function LFont:getWrap(text, limit) end

--- Releases this font and frees its atlas memory.
---@return boolean True when the font was released.
function LFont:release() end

--- Sets the line height multiplier for this font.
---@param height number New line height multiplier.
---@return nil No return value.
function LFont:setLineHeight(height) end

--- Returns the Lua type name for this font handle.
---@return string Lua type name for this object.
function LFont:type() end

--- Returns the Lua type name for this font object.
---@return string Lua type name for this object.
function LFont:typeOf() end

--- Lua-side handle to a loaded GPU texture stored in the engine's texture pool.
---@class LImage
LImage = {}

--- Returns width and height of this image.
---@return integer Image width in pixels.
---@return integer Image height in pixels.
function LImage:getDimensions() end

--- Returns the height of this image in pixels.
---@return integer Image height in pixels.
function LImage:getHeight() end

--- Returns the width of this image in pixels.
---@return integer Image width in pixels.
function LImage:getWidth() end

--- Releases the GPU texture memory for this image.
---@return boolean True when the image was released.
function LImage:release() end

--- Returns the Lua type name for this image handle.
---@return string Lua type name for this object.
function LImage:type() end

--- Returns the Lua type name for this image object.
---@return string Lua type name for this object.
function LImage:typeOf() end

--- Lua-side handle to a loaded texture stored in SharedState.
---@class LImageData
LImageData = {}

--- Blits another image buffer onto this image at the destination position.
---@param src LImageData Source image data to copy from.
---@param dst_x integer Destination x position in pixels.
---@param dst_y integer Destination y position in pixels.
---@return nil No return value.
function LImageData:blit(src, dst_x, dst_y) end

--- Returns the summed per-channel difference between this image and another image.
---@param other LImageData Image data to compare against.
---@return integer Sum of absolute per-channel differences.
function LImageData:diff(other) end

--- Returns the pixel height of this image buffer.
---@return integer Pixel height of this image buffer.
function LImageData:getHeight() end

--- Returns a copy of a rectangular region from this image buffer.
---@param x integer Left edge of the region in pixels.
---@param y integer Top edge of the region in pixels.
---@param width integer Region width in pixels.
---@param height integer Region height in pixels.
---@return LImageData Copied image region, or nil if the region is empty or outside the image.
function LImageData:getRegion(x, y, width, height) end

--- Returns the pixel width of this image buffer.
---@return integer Pixel width of this image buffer.
function LImageData:getWidth() end

--- Applies a Lua callback to each pixel in this image buffer.
---@param fn function Callback that receives x, y, r, g, b, a and returns r, g, b, a.
---@return nil No return value.
function LImageData:mapPixels(fn) end

--- Returns a resized copy of this image buffer.
---@param width integer Target width in pixels.
---@param height integer Target height in pixels.
---@return LImageData Resized image data, or nil if the resize cannot produce an image.
function LImageData:resize(width, height) end

--- Returns the Lua type name for this image data object.
---@return string Lua type name for this object.
function LImageData:type() end

--- Returns whether this object matches a requested type name.
---@param name string Type name to test.
---@return boolean True when the name matches this type or a parent type.
function LImageData:typeOf(name) end

--- Lua-side handle to a mesh stored in SharedState.
---@class LMesh
LMesh = {}

--- Returns vertex data at the given 1-based index.
---@param index integer 1-based vertex index.
---@return number Vertex X position.
---@return number Vertex Y position.
---@return number Texture U coordinate.
---@return number Texture V coordinate.
---@return number Red component.
---@return number Green component.
---@return number Blue component.
---@return number Alpha component.
function LMesh:getVertex(index) end

--- Returns the number of vertices in this mesh.
---@return integer Number of vertices in this mesh.
function LMesh:getVertexCount() end

--- Releases the GPU mesh resource, freeing VRAM immediately.
---@return boolean True when the mesh was released.
function LMesh:release() end

--- Assigns a texture to this mesh.
---@param image? LImage Image to assign as the mesh texture, or nil to clear it.
---@return nil No return value.
function LMesh:setTexture(image) end

--- Sets vertex data at the given 1-based index.
---@param index integer 1-based vertex index.
---@param data table Vertex data table with x, y, u, v, r, g, b, a values.
---@return nil No return value.
function LMesh:setVertex(index, data) end

--- Returns the Lua type name for this mesh handle.
---@return string Lua type name for this object.
function LMesh:type() end

--- Returns the Lua type name for this mesh object.
---@return string Lua type name for this object.
function LMesh:typeOf() end

--- Lua-side 9-slice descriptor.
---@class LNineSlice
LNineSlice = {}

--- Returns the four inset values as (top, right, bottom, left).
---@return number Top inset value.
---@return number Right inset value.
---@return number Bottom inset value.
---@return number Left inset value.
function LNineSlice:getInsets() end

--- Returns the width and height of the source texture.
---@return integer Source texture width in pixels.
---@return integer Source texture height in pixels.
function LNineSlice:getTextureSize() end

--- Returns the Lua type name for this object.
---@return string Lua type name for this object.
function LNineSlice:type() end

--- Returns whether this object matches a requested type name.
---@param name string Type name to test.
---@return boolean True when the name matches this type or a parent type.
function LNineSlice:typeOf(name) end

--- Lua-side quad viewport into a texture.
---@class LQuad
LQuad = {}

--- Returns the reference texture dimensions.
---@return number Reference texture width.
---@return number Reference texture height.
function LQuad:getTextureDimensions() end

--- Returns the quad viewport rectangle.
---@return number Viewport X coordinate.
---@return number Viewport Y coordinate.
---@return number Viewport width.
---@return number Viewport height.
function LQuad:getViewport() end

--- Sets the quad viewport rectangle.
---@param x number Viewport x position.
---@param y number Viewport y position.
---@param w number Viewport width.
---@param h number Viewport height.
---@return nil No return value.
function LQuad:setViewport(x, y, w, h) end

--- Returns the Lua type name for this quad handle.
---@return string Lua type name for this object.
function LQuad:type() end

--- Returns the Lua type name for this quad object.
---@return string Lua type name for this object.
function LQuad:typeOf() end

--- Lua-side handle to a compiled shader stored in SharedState.
---@class LShader
LShader = {}

--- Returns whether this shader has a uniform with the given name.
---@param name string Uniform name to check.
---@return boolean True when the shader defines the uniform.
function LShader:hasUniform(name) end

--- Releases the compiled GPU shader, freeing VRAM and shader slots.
---@return boolean True when the shader was released.
function LShader:release() end

--- Sends a uniform value to this shader.
---@param name string Uniform name.
---@param value LuaValue Uniform value to send.
---@return nil No return value.
function LShader:send(name, value) end

--- Returns the Lua type name for this shader handle.
---@return string Lua type name for this object.
function LShader:type() end

--- Returns the Lua type name for this shader object.
---@return string Lua type name for this object.
function LShader:typeOf() end

--- Lua-side handle to a [`CompoundShape`] stored in [`SharedState::shapes`].
---@class LShape
LShape = {}

--- Queues a filled or outlined arc draw command onto this shape.
---@param mode string Draw mode, typically "fill" or "line".
---@param x number Arc center x position.
---@param y number Arc center y position.
---@param r number Arc radius.
---@param astart number Start angle in radians.
---@param aend number End angle in radians.
---@param segments? integer Segment count, defaulting to 32.
---@return nil No return value.
function LShape:arc(mode, x, y, r, astart, aend, segments) end

--- Queues a filled or outlined circle draw command onto this shape.
---@param mode string Draw mode, typically "fill" or "line".
---@param x number Circle center x position.
---@param y number Circle center y position.
---@param r number Circle radius.
---@return nil No return value.
function LShape:circle(mode, x, y, r) end

--- Removes all commands and resets the shape to empty.
---@return nil No return value.
function LShape:clear() end

--- Queues this shape for drawing at the given position.
---@param x number World x position.
---@param y number World y position.
---@param rotation? number Rotation in radians, defaulting to 0.
---@param sx? number Horizontal scale, defaulting to 1.
---@param sy? number Vertical scale, defaulting to 1.
---@param ox? number Origin x offset in object space, defaulting to 0.
---@param oy? number Origin y offset in object space, defaulting to 0.
---@return nil No return value.
function LShape:draw(x, y, rotation, sx, sy, ox, oy) end

--- Queues an ellipse command.
---@param mode string Draw mode, typically "fill" or "line".
---@param x number Ellipse center x position.
---@param y number Ellipse center y position.
---@param rx number Horizontal radius.
---@param ry number Vertical radius.
---@return nil No return value.
function LShape:ellipse(mode, x, y, rx, ry) end

--- Returns the number of drawing commands currently stored.
---@return integer Number of drawing commands stored in this shape.
function LShape:getCommandCount() end

--- Queues a line segment command.
---@param x1 number Start x position.
---@param y1 number Start y position.
---@param x2 number End x position.
---@param y2 number End y position.
---@return nil No return value.
function LShape:line(x1, y1, x2, y2) end

--- Queues a polygon command from variadic (x, y) coordinate pairs.
---@param mode string Draw mode, typically "fill" or "line".
---@param ... number Flat x and y coordinate pairs, with at least three vertices.
---@return nil No return value.
function LShape:polygon(mode, ...) end

--- Queues a polyline command from variadic (x, y) coordinate pairs.
---@param ... number Flat x and y coordinate pairs, with at least two points.
---@return nil No return value.
function LShape:polyline(...) end

--- Queues a rectangle command.
---@param mode string Draw mode, typically "fill" or "line".
---@param x number Rectangle x position.
---@param y number Rectangle y position.
---@param w number Rectangle width.
---@param h number Rectangle height.
---@return nil No return value.
function LShape:rectangle(mode, x, y, w, h) end

--- Queues a rounded rectangle command.
---@param mode string Draw mode, typically "fill" or "line".
---@param x number Rectangle x position.
---@param y number Rectangle y position.
---@param w number Rectangle width.
---@param h number Rectangle height.
---@param rx number Horizontal corner radius.
---@param ry? number Vertical corner radius, defaulting to rx.
---@return nil No return value.
function LShape:roundedRectangle(mode, x, y, w, h, rx, ry) end

--- Sets the drawing color for subsequent primitives.
---@param r number Red channel in the range 0 to 1.
---@param g number Green channel in the range 0 to 1.
---@param b number Blue channel in the range 0 to 1.
---@param a? number Alpha channel in the range 0 to 1, defaulting to 1.
---@return nil No return value.
function LShape:setColor(r, g, b, a) end

--- Sets the stroke width for subsequent outlined primitives.
---@param w number Stroke width in pixels.
---@return nil No return value.
function LShape:setLineWidth(w) end

--- Queues a triangle command.
---@param mode string Draw mode, typically "fill" or "line".
---@param x1 number First vertex x position.
---@param y1 number First vertex y position.
---@param x2 number Second vertex x position.
---@param y2 number Second vertex y position.
---@param x3 number Third vertex x position.
---@param y3 number Third vertex y position.
---@return nil No return value.
function LShape:triangle(mode, x1, y1, x2, y2, x3, y3) end

--- Returns the Lua type name for this shape handle.
---@return string Lua type name for this object.
function LShape:type() end

--- Returns whether this object matches a requested type name.
---@param name string Type name to test.
---@return boolean True when the name matches this type or a parent type.
function LShape:typeOf(name) end

--- Lua-side handle to a sprite batch stored in SharedState.
---@class LSpriteBatch
LSpriteBatch = {}

--- Adds a sprite entry to this batch.
---@param x number Sprite x position.
---@param y number Sprite y position.
---@param r? number Sprite rotation in radians.
---@param sx? number Horizontal scale.
---@param sy? number Vertical scale.
---@param ox? number Origin x offset.
---@param oy? number Origin y offset.
---@return integer Index of the added sprite entry.
function LSpriteBatch:add(x, y, r, sx, sy, ox, oy) end

--- Removes all sprites from this batch.
---@return nil No return value.
function LSpriteBatch:clear() end

--- Returns the maximum capacity of this batch.
---@return integer Maximum number of sprites the batch can hold.
function LSpriteBatch:getBufferSize() end

--- Returns the number of sprites in this batch.
---@return integer Number of sprites in this batch.
function LSpriteBatch:getCount() end

--- Releases this sprite batch.
---@return boolean True when the sprite batch was released.
function LSpriteBatch:release() end

--- Returns the Lua type name for this sprite batch handle.
---@return string Lua type name for this object.
function LSpriteBatch:type() end

--- Returns the Lua type name for this sprite batch object.
---@return string Lua type name for this object.
function LSpriteBatch:typeOf() end

--- Applies an affine transform matrix.
---@param matrix table 3x3 affine transform matrix values.
---@return nil No return value.
lurek.render.applyTransform = function(matrix) end

--- Draws a partial circle arc at the given position with specified radius and angle range.
---@param mode string Draw mode, typically "fill" or "line".
---@param x number Arc center x position.
---@param y number Arc center y position.
---@param radius number Arc radius.
---@param angle1 number Start angle in radians.
---@param angle2 number End angle in radians.
---@param segments? integer Segment count, defaulting to 32.
---@return nil No return value.
lurek.render.arc = function(mode, x, y, radius, angle1, angle2, segments) end

--- Begins a Y/Z depth sort group. Draw commands until flushSortGroup are depth-sortable.
---@param id integer Sort group identifier.
---@return nil No return value.
lurek.render.beginSortGroup = function(id) end

--- Begins a Y/Z depth sort group.
---@param id integer Sort group identifier.
---@return nil No return value.
lurek.render.beginSortGroup = function(id) end

--- Calls the given callback with an ImageData captured from the current frame (stub: creates blank).
---@param callback function Callback that receives the captured image data.
---@return nil No return value.
lurek.render.captureScreenshot = function(callback) end

--- Draws a filled or outlined circle at the given world-space position.
---@param mode string Draw mode, typically "fill" or "line".
---@param x number Circle center x position.
---@param y number Circle center y position.
---@param radius number Circle radius.
---@return nil No return value.
lurek.render.circle = function(mode, x, y, radius) end

--- Clears the draw command queue (resets the screen).
---@param r? number Optional red channel.
---@param g? number Optional green channel.
---@param b? number Optional blue channel.
---@return nil No return value.
lurek.render.clear = function(r, g, b) end

--- Resets the stencil mode to the default (keep / always / 0).
---@return nil No return value.
lurek.render.clearStencil = function() end

--- Returns the name of the currently active named layer.
---@return string Name of the active named layer.
lurek.render.currentLayer = function() end

--- Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
---@param ... LuaValue|number
---@return nil No return value.
lurek.render.draw = function(...) end

--- Queues a beveled border rectangle with inner fill.
---@param x number Rectangle x position.
---@param y number Rectangle y position.
---@param w number Rectangle width.
---@param h number Rectangle height.
---@param bevelW? number Bevel width, defaulting to 2.
---@param style? string Bevel style name, defaulting to raised.
---@param opts? table Optional highlight, shadow, and fill colors.
---@return nil No return value.
lurek.render.drawBevelRect = function(x, y, w, h, bevelW, style, opts) end

--- Queues a beveled border rectangle.
---@param x number Rectangle x position.
---@param y number Rectangle y position.
---@param w number Rectangle width.
---@param h number Rectangle height.
---@param bevelW? number Bevel width, defaulting to 2.
---@param style? string Bevel style name, defaulting to raised.
---@param opts? table Optional highlight, shadow, and fill colors.
---@return nil No return value.
lurek.render.drawBevelRect = function(x, y, w, h, bevelW, style, opts) end

--- Queues a convex polygon with per-vertex colors.
---@param vertices table Flat vertex table with x and y pairs.
---@param colors table Per-vertex RGBA color tables.
---@param mode? string Draw mode, defaulting to fill.
---@return nil No return value.
lurek.render.drawColoredPolygon = function(vertices, colors, mode) end

--- Queues a convex polygon with per-vertex colors.
---@param vertices table Flat vertex table with x and y pairs.
---@param colors table Per-vertex RGBA color tables.
---@param mode? string Draw mode, defaulting to fill.
---@return nil No return value.
lurek.render.drawColoredPolygon = function(vertices, colors, mode) end

--- Queues a cubic Bezier curve.
---@param x1 number Start x position.
---@param y1 number Start y position.
---@param cx1 number First control point x position.
---@param cy1 number First control point y position.
---@param cx2 number Second control point x position.
---@param cy2 number Second control point y position.
---@param x2 number End x position.
---@param y2 number End y position.
---@param segments? integer Segment count, defaulting to 16.
---@return nil No return value.
lurek.render.drawCubicBezier = function(x1, y1, cx1, cy1, cx2, cy2, x2, y2, segments) end

--- Queues a cubic Bezier curve.
---@param x1 number Start x position.
---@param y1 number Start y position.
---@param cx1 number First control point x position.
---@param cy1 number First control point y position.
---@param cx2 number Second control point x position.
---@param cy2 number Second control point y position.
---@param x2 number End x position.
---@param y2 number End y position.
---@param segments? integer Segment count, defaulting to 16.
---@return nil No return value.
lurek.render.drawCubicBezier = function(x1, y1, cx1, cy1, cx2, cy2, x2, y2, segments) end

--- Queues a gradient-filled rectangle.
---@param x number Rectangle x position.
---@param y number Rectangle y position.
---@param w number Rectangle width.
---@param h number Rectangle height.
---@param color1 table First RGBA color table.
---@param color2 table Second RGBA color table.
---@param direction? string Gradient direction, defaulting to vertical.
---@return nil No return value.
lurek.render.drawGradientRect = function(x, y, w, h, color1, color2, direction) end

--- Queues a gradient-filled rectangle.
---@param x number Rectangle x position.
---@param y number Rectangle y position.
---@param w number Rectangle width.
---@param h number Rectangle height.
---@param color1 table First RGBA color table.
---@param color2 table Second RGBA color table.
---@param direction? string Gradient direction, defaulting to vertical.
---@return nil No return value.
lurek.render.drawGradientRect = function(x, y, w, h, color1, color2, direction) end

--- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
---@param cx number Center x position.
---@param cy number Center y position.
---@param size number Hex radius.
---@param orientation? string Orientation name, defaulting to pointyTop.
---@param mode? string Draw mode, defaulting to line.
---@return nil No return value.
lurek.render.drawHexTile = function(cx, cy, size, orientation, mode) end

--- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
---@param cx number Center x position.
---@param cy number Center y position.
---@param size number Hex radius.
---@param orientation? string Orientation name, defaulting to pointyTop.
---@param mode? string Draw mode, defaulting to line.
---@return nil No return value.
lurek.render.drawHexTile = function(cx, cy, size, orientation, mode) end

--- Queues a three-face isometric cube tile.
---@param sx number Screen x position.
---@param sy number Screen y position.
---@param halfW number Half tile width.
---@param halfH number Half tile height.
---@param opts? table Optional depth, color, and texture options.
---@return nil No return value.
lurek.render.drawIsoCubeTile = function(sx, sy, halfW, halfH, opts) end

--- Queues a three-face isometric cube tile.
---@param sx number Screen x position.
---@param sy number Screen y position.
---@param halfW number Half tile width.
---@param halfH number Half tile height.
---@param opts? table Optional depth, color, and texture options.
---@return nil No return value.
lurek.render.drawIsoCubeTile = function(sx, sy, halfW, halfH, opts) end

--- Queues a 9-slice draw call inside lurek.draw / lurek.draw_ui.
---@param slice LNineSlice Nine-slice descriptor to draw.
---@param x number Draw x position.
---@param y number Draw y position.
---@param width number Draw width.
---@param height number Draw height.
---@return nil No return value.
lurek.render.drawNineSlice = function(slice, x, y, width, height) end

--- Queues a multi-segment vector path.
---@param path table Path segment table.
---@param mode? string Draw mode, defaulting to line.
---@param close? boolean Whether to close the path, defaulting to false.
---@return nil No return value.
lurek.render.drawPath = function(path, mode, close) end

--- Queues a multi-segment vector path.
---@param path table Path segment table.
---@param mode? string Draw mode, defaulting to line.
---@param close? boolean Whether to close the path, defaulting to false.
---@return nil No return value.
lurek.render.drawPath = function(path, mode, close) end

--- Queues a quadratic Bezier curve.
---@param x1 number Start x position.
---@param y1 number Start y position.
---@param cx number Control point x position.
---@param cy number Control point y position.
---@param x2 number End x position.
---@param y2 number End y position.
---@param segments? integer Segment count, defaulting to 16.
---@return nil No return value.
lurek.render.drawQuadBezier = function(x1, y1, cx, cy, x2, y2, segments) end

--- Queues a quadratic Bezier curve.
---@param x1 number Start x position.
---@param y1 number Start y position.
---@param cx number Control point x position.
---@param cy number Control point y position.
---@param x2 number End x position.
---@param y2 number End y position.
---@param segments? integer Segment count, defaulting to 16.
---@return nil No return value.
lurek.render.drawQuadBezier = function(x1, y1, cx, cy, x2, y2, segments) end

--- Draws a portion of an image defined by a Quad.
---@param image LImage Image to draw from.
---@param quad LQuad Quad that defines the source region.
---@param x? number Draw x position, defaulting to 0.
---@param y? number Draw y position, defaulting to 0.
---@param r? number Rotation in radians, defaulting to 0.
---@param sx? number Horizontal scale, defaulting to 1.
---@param sy? number Vertical scale, defaulting to 1.
---@param ox? number Origin x offset, defaulting to 0.
---@param oy? number Origin y offset, defaulting to 0.
---@return nil No return value.
lurek.render.drawq = function(image, quad, x, y, r, sx, sy, ox, oy) end

--- Draws a filled or outlined ellipse with independent x/y radii.
---@param mode string Draw mode, typically "fill" or "line".
---@param x number Ellipse center x position.
---@param y number Ellipse center y position.
---@param rx number Horizontal radius.
---@param ry number Vertical radius.
---@return nil No return value.
lurek.render.ellipse = function(mode, x, y, rx, ry) end

--- Sorts and flushes all draw commands in the sort group.
---@param id integer Sort group identifier.
---@return nil No return value.
lurek.render.flushSortGroup = function(id) end

--- Sorts and flushes all draw commands in the sort group.
---@param id integer Sort group identifier.
---@return nil No return value.
lurek.render.flushSortGroup = function(id) end

--- Returns the current background color.
---@return number Background red component.
---@return number Background green component.
---@return number Background blue component.
---@return number Background alpha component.
lurek.render.getBackgroundColor = function() end

--- Returns the current blend mode as a string.
---@return string Current blend mode name.
lurek.render.getBlendMode = function() end

--- Returns the current canvas, or nil if drawing to screen.
---@return LCanvas Active canvas handle, or nil when drawing to the screen.
lurek.render.getCanvas = function() end

--- Returns the dimensions of a canvas.
---@param canvas LCanvas Canvas to inspect.
---@return integer Canvas width in pixels.
---@return integer Canvas height in pixels.
lurek.render.getCanvasSize = function(canvas) end

--- Returns the current drawing color.
---@return number Current red component.
---@return number Current green component.
---@return number Current blue component.
---@return number Current alpha component.
lurek.render.getColor = function() end

--- Returns the current color mask.
---@return boolean Whether red writes are enabled.
---@return boolean Whether green writes are enabled.
---@return boolean Whether blue writes are enabled.
---@return boolean Whether alpha writes are enabled.
lurek.render.getColorMask = function() end

--- Returns the default texture filter mode.
---@return string Default minification filter.
---@return string Default magnification filter.
---@return integer Default anisotropy level.
lurek.render.getDefaultFilter = function() end

--- Returns a built-in font by pixel height (snaps to nearest available size).
---@param pixel_height? number Requested built-in font height, defaulting to 14.
---@return LFont Built-in font handle.
lurek.render.getDefaultFont = function(pixel_height) end

--- Returns the current depth mode as (mode, write).
---@return string Current depth comparison mode.
---@return boolean Whether depth writes are enabled.
lurek.render.getDepthMode = function() end

--- Returns window width and height.
---@return integer Window width in pixels.
---@return integer Window height in pixels.
lurek.render.getDimensions = function() end

--- Returns the currently active font, or nil.
---@return LFont Active font handle, or nil if no active font is set.
lurek.render.getFont = function() end

--- Returns the ascent of the given font.
---@param font LFont Font to inspect.
---@return number Font ascent.
lurek.render.getFontAscent = function(font) end

--- Returns the cell width of the given font (for monospaced bitmap fonts).
---@param font LFont Font to inspect.
---@return number Font cell width.
lurek.render.getFontCellWidth = function(font) end

--- Returns the descent of the given font.
---@param font LFont Font to inspect.
---@return number Font descent.
lurek.render.getFontDescent = function(font) end

--- Returns the line height of the given font.
---@param font LFont Font to inspect.
---@return number Font line height.
lurek.render.getFontHeight = function(font) end

--- Returns the line height of the given font (alias for getFontHeight).
---@param font LFont Font to inspect.
---@return number Font line height.
lurek.render.getFontLineHeight = function(font) end

--- Returns a table of available built-in font pixel heights.
---@return table Table of built-in font heights.
lurek.render.getFontSizes = function() end

--- Returns the pixel width of text in the given font.
---@param font LFont Font to measure with.
---@param text string Text to measure.
---@return number Pixel width of the text.
lurek.render.getFontWidth = function(font, text) end

--- Returns wrapped lines and the maximum line width.
---@param text string Text to wrap.
---@param limit number Maximum line width.
---@return table Wrapped lines as an array of strings.
---@return number Maximum wrapped line width.
lurek.render.getFontWrap = function(text, limit) end

--- Returns the window height in pixels.
---@return integer Window height in pixels.
lurek.render.getHeight = function() end

--- Returns the z order of the named layer.
---@param name string Layer name.
---@return integer Layer z order, or 0 if the layer is not registered.
lurek.render.getLayerZOrder = function(name) end

--- Returns the current line width.
---@return number Current line width.
lurek.render.getLineWidth = function() end

--- Returns the current point size.
---@return number Current point size.
lurek.render.getPointSize = function() end

--- Returns the active scissor rectangle, or nothing.
---@return number Scissor X coordinate.
---@return number Scissor Y coordinate.
---@return number Scissor width.
---@return number Scissor height.
lurek.render.getScissor = function() end

--- Returns the active shader, or nil.
---@return LShader Active shader handle, or nil when no shader is active.
lurek.render.getShader = function() end

--- Returns a table of renderer statistics.
---@return table Renderer statistics table.
lurek.render.getStats = function() end

--- Returns the current stencil mode as (action, compare, value).
---@return string Current stencil action.
---@return string Current stencil comparison mode.
---@return integer Current stencil reference value.
lurek.render.getStencilMode = function() end

--- Returns the window width in pixels.
---@return integer Window width in pixels.
lurek.render.getWidth = function() end

--- Intersects the current scissor with a new rectangle.
---@param x number Rectangle x position.
---@param y number Rectangle y position.
---@param w number Rectangle width.
---@param h number Rectangle height.
---@return nil No return value.
lurek.render.intersectScissor = function(x, y, w, h) end

--- Returns whether the named layer is visible.
---@param name string Layer name.
---@return boolean True when the layer is visible.
lurek.render.isLayerVisible = function(name) end

--- Returns whether wireframe mode is active.
---@return boolean True when wireframe mode is active.
lurek.render.isWireframe = function() end

--- Draws a line between two points.
---@param ... number
---@return nil No return value.
lurek.render.line = function(...) end

--- Creates an off-screen render canvas.
---@param width integer Canvas width in pixels.
---@param height integer Canvas height in pixels.
---@return LCanvas Created canvas handle.
lurek.render.newCanvas = function(width, height) end

--- Creates a new z-ordered draw-call queue.
---@return LDrawLayer Created draw layer handle.
lurek.render.newDrawLayer = function() end

--- Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
---@param ... LuaValue|number
---@return LFont Loaded font handle.
lurek.render.newFont = function(...) end

--- Loads an image from a file path or creates one from ImageData.
---@param path_or_data LuaValue Image file path or image data object.
---@return LImage Loaded image handle.
lurek.render.newImage = function(path_or_data) end

--- Registers a named render layer.
---@param name string Layer name.
---@param z_order? integer Layer z order, defaulting to 0.
---@return nil No return value.
lurek.render.newLayer = function(name, z_order) end

--- Creates a custom mesh from vertex data.
---@param vertices table Vertex rows with x, y, u, v, r, g, b, a values.
---@param mode? string Mesh draw mode, defaulting to triangles.
---@return LMesh Created mesh handle.
lurek.render.newMesh = function(vertices, mode) end

--- Creates a 9-slice descriptor from a texture and inset values.
---@param image LImage Source image.
---@param top number Top inset.
---@param right number Right inset.
---@param bottom number Bottom inset.
---@param left number Left inset.
---@return LNineSlice Created nine-slice descriptor.
lurek.render.newNineSlice = function(image, top, right, bottom, left) end

--- Creates a new Quad viewport into a texture.
---@param x number Quad x position in the source texture.
---@param y number Quad y position in the source texture.
---@param w number Quad width.
---@param h number Quad height.
---@param sw number Reference texture width.
---@param sh number Reference texture height.
---@return LQuad Created quad handle.
lurek.render.newQuad = function(x, y, w, h, sw, sh) end

--- Compiles a custom WGSL shader and returns its handle.
---@param code string WGSL shader source code.
---@return LShader Compiled shader handle.
lurek.render.newShader = function(code) end

--- Creates a new empty shape resource.
---@return LShape Created shape handle.
lurek.render.newShape = function() end

--- Creates a new sprite batch for the given image.
---@param image LImage Source image for the batch.
---@param max_sprites? integer Maximum sprite count, defaulting to 1000.
---@return LSpriteBatch Created sprite batch handle.
lurek.render.newSpriteBatch = function(image, max_sprites) end

--- Resets the transform to the identity.
---@return nil No return value.
lurek.render.origin = function() end

--- Draws a batch of individual points at the specified world-space coordinates.
---@param ... LuaValue Point coordinates passed as numbers or as a table of point pairs.
---@return nil No return value.
lurek.render.points = function(...) end

--- Draws a polygon from a list of vertices.
---@param mode string Draw mode, typically "fill" or "line".
---@param ... number Flat x and y coordinate pairs, with at least three vertices.
---@return nil No return value.
lurek.render.polygon = function(mode, ...) end

--- Pops the transform from the stack.
---@return nil No return value.
lurek.render.pop = function() end

--- Ends and composites the named layer back to its parent.
---@param id integer Layer identifier.
---@return nil No return value.
lurek.render.popLayer = function(id) end

--- Ends and composites the named layer.
---@param id integer Layer identifier.
---@return nil No return value.
lurek.render.popLayer = function(id) end

--- Draws text at the given position.
---@param text string Text to draw.
---@param x? number Draw x position, defaulting to 0.
---@param y? number Draw y position, defaulting to 0.
---@param scale? number Text scale, defaulting to 1.
---@return nil No return value.
lurek.render.print = function(text, x, y, scale) end

--- Draws a sequence of styled text spans at the given position.
---@param spans table Table of span tables with text, color, and optional scale fields.
---@param x number Draw x position.
---@param y number Draw y position.
---@return nil No return value.
lurek.render.printRich = function(spans, x, y) end

--- Draws word-wrapped text within a given width.
---@param text string Text to draw.
---@param x number Draw x position.
---@param y number Draw y position.
---@param limit number Wrap width.
---@param align? string Alignment name, defaulting to left.
---@return nil No return value.
lurek.render.printf = function(text, x, y, limit, align) end

--- Pushes the current transform onto the stack.
---@return nil No return value.
lurek.render.push = function() end

--- Begins a named compositing layer with optional alpha and blend mode.
---@param id integer Layer identifier.
---@param alpha? number Layer alpha, defaulting to 1.
---@param blendMode? string Blend mode name, defaulting to alpha.
---@return nil No return value.
lurek.render.pushLayer = function(id, alpha, blendMode) end

--- Begins a named compositing layer. Provides alpha and blend mode for composite.
---@param id integer Layer identifier.
---@param alpha? number Layer alpha, defaulting to 1.
---@param blendMode? string Blend mode name, defaulting to alpha.
---@return nil No return value.
lurek.render.pushLayer = function(id, alpha, blendMode) end

--- Associates the previous draw command with a depth value within the active sort group.
---@param depth number Depth value for the previous draw command.
---@return nil No return value.
lurek.render.pushSortKey = function(depth) end

--- Associates the previous draw command with a depth value within the active sort group.
---@param depth number Depth value for the previous draw command.
---@return nil No return value.
lurek.render.pushSortKey = function(depth) end

--- Draws a filled or outlined axis-aligned rectangle at the given position.
---@param mode string Draw mode, typically "fill" or "line".
---@param x number Rectangle x position.
---@param y number Rectangle y position.
---@param w number Rectangle width.
---@param h number Rectangle height.
---@param rx? number Horizontal corner radius.
---@param ry? number Vertical corner radius.
---@return nil No return value.
lurek.render.rectangle = function(mode, x, y, w, h, rx, ry) end

--- Rotates the coordinate system.
---@param angle number Rotation angle in radians.
---@return nil No return value.
lurek.render.rotate = function(angle) end

--- Queues a screenshot to be saved after the current frame.
---@param path string Output path, which must start with save/.
---@return nil No return value.
lurek.render.saveScreenshot = function(path) end

--- Scales the coordinate system.
---@param sx number Horizontal scale.
---@param sy? number Vertical scale, defaulting to sx.
---@return nil No return value.
lurek.render.scale = function(sx, sy) end

--- Sets the background clear color.
---@param r number Red channel in the range 0 to 1.
---@param g number Green channel in the range 0 to 1.
---@param b number Blue channel in the range 0 to 1.
---@return nil No return value.
lurek.render.setBackgroundColor = function(r, g, b) end

--- Sets the blend mode for drawing.
---@param mode string Blend mode name.
---@return nil No return value.
lurek.render.setBlendMode = function(mode) end

--- Sets the active render target to a Canvas, or back to the screen.
---@param canvas? LCanvas Canvas to target, or nil to draw to the screen.
---@return nil No return value.
lurek.render.setCanvas = function(canvas) end

--- Sets the current drawing color.
---@param r number Red channel in the range 0 to 1.
---@param g number Green channel in the range 0 to 1.
---@param b number Blue channel in the range 0 to 1.
---@param a? number Alpha channel in the range 0 to 1, defaulting to 1.
---@return nil No return value.
lurek.render.setColor = function(r, g, b, a) end

--- Sets which RGBA channels are written. Reset with no args.
---@param ... boolean
---@return nil No return value.
lurek.render.setColorMask = function(...) end

--- Sets the default texture filter mode.
---@param min string Minification filter mode name.
---@param mag string Magnification filter mode name.
---@param anisotropy? integer Anisotropy level, defaulting to 1.
---@return nil No return value.
lurek.render.setDefaultFilter = function(min, mag, anisotropy) end

--- Sets the depth test comparison and write enable.
---@param mode string Depth comparison mode name.
---@param write? boolean Whether depth writes are enabled, defaulting to false.
---@return nil No return value.
lurek.render.setDepthMode = function(mode, write) end

--- Sets the active font for print calls.
---@param font LFont Font to make active.
---@return nil No return value.
lurek.render.setFont = function(font) end

--- Sets the line height of the given font (stub - returns nil; fonts are immutable in headless mode).
---@param font LFont Font to target.
---@param line_height number Requested line height.
---@return nil No return value.
lurek.render.setFontLineHeight = function(font, line_height) end

--- Sets the active named layer.
---@param name string Layer name.
---@return nil No return value.
lurek.render.setLayer = function(name) end

--- Shows or hides the named layer.
---@param name string Layer name.
---@param visible boolean Whether the layer is visible.
---@return nil No return value.
lurek.render.setLayerVisible = function(name, visible) end

--- Updates the z order of the named layer.
---@param name string Layer name.
---@param z_order integer New layer z order.
---@return nil No return value.
lurek.render.setLayerZOrder = function(name, z_order) end

--- Sets the line width for outline drawing.
---@param width number Line width in pixels.
---@return nil No return value.
lurek.render.setLineWidth = function(width) end

--- Sets the point diameter in pixels.
---@param size number Point size in pixels.
---@return nil No return value.
lurek.render.setPointSize = function(size) end

--- Restricts drawing to a rectangle, or clears scissor if no args.
---@param ... number
---@return nil No return value.
lurek.render.setScissor = function(...) end

--- Sets the active shader, or clears it.
---@param shader? LShader Shader to activate, or nil to clear it.
---@return nil No return value.
lurek.render.setShader = function(shader) end

--- Sets the stencil buffer write/test mode.
---@param action string Stencil action name.
---@param compare? string Comparison mode name, defaulting to always.
---@param value? integer Reference value in the range 0 to 255.
---@return nil No return value.
lurek.render.setStencilMode = function(action, compare, value) end

--- Sets the stencil comparison test, or disables stencil testing.
---@param compare? string Comparison mode name, or nil to disable stencil testing.
---@param value? integer Stencil reference value, defaulting to 1.
---@return nil No return value.
lurek.render.setStencilTest = function(compare, value) end

--- Enables or disables wireframe rendering.
---@param enabled boolean True to enable wireframe rendering.
---@return nil No return value.
lurek.render.setWireframe = function(enabled) end

--- Shears the coordinate system.
---@param kx number Shear factor on the x axis.
---@param ky number Shear factor on the y axis.
---@return nil No return value.
lurek.render.shear = function(kx, ky) end

--- Begins stencil writing with the given action and value.
---@param action? string Stencil action name, defaulting to replace.
---@param value? integer Stencil reference value, defaulting to 1.
---@return nil No return value.
lurek.render.stencil = function(action, value) end

--- Translates the coordinate system.
---@param x number Translation amount on the x axis.
---@param y number Translation amount on the y axis.
---@return nil No return value.
lurek.render.translate = function(x, y) end

--- Draws a filled or outlined triangle connecting three world-space vertices.
---@param mode string Draw mode, typically "fill" or "line".
---@param x1 number First vertex x position.
---@param y1 number First vertex y position.
---@param x2 number Second vertex x position.
---@param y2 number Second vertex y position.
---@param x3 number Third vertex x position.
---@param y3 number Third vertex y position.
---@return nil No return value.
lurek.render.triangle = function(mode, x1, y1, x2, y2, x3, y3) end

---@class lurek.save
lurek.save = {}

--- Lua-side wrapper around [`SaveManager`] with per-module callback storage.
---@class LSaveManager
LSaveManager = {}

--- Registers a migration function for upgrading from a schema version.
---@param from_version integer Source schema version handled by the migration.
---@param func function Migration callback that transforms loaded data.
---@return nil No value is returned.
function LSaveManager:addMigration(from_version, func) end

--- Collects data from all registered collectors into a table with metadata.
---@return table Returns the collected save data table.
function LSaveManager:collect() end

--- Deletes a save file for the given slot.
---@param slot string Slot name to delete.
---@return nil No value is returned.
function LSaveManager:delete(slot) end

--- Disables automatic periodic saving; manual `write()` calls still work.
---@return nil No value is returned.
function LSaveManager:disableAutoSave() end

--- Enables auto-save with a given interval and target slot.
---@param interval number Auto-save interval in seconds.
---@param slot string Slot name to write when auto-save triggers.
---@return nil No value is returned.
function LSaveManager:enableAutoSave(interval, slot) end

--- Returns whether a save file exists for the given slot.
---@param slot string Slot name to check.
---@return boolean Returns whether the slot file exists.
function LSaveManager:exists(slot) end

--- Returns the current schema version.
---@return integer Returns the current schema version.
function LSaveManager:getSchemaVersion() end

--- Returns metadata for a single slot, or nil if not found.
---@param slot string Slot name to inspect.
---@return table Returns the slot metadata table when the slot exists.
function LSaveManager:getSlotInfo(slot) end

--- Returns a list of all save slots with metadata.
---@return table Returns the slot metadata list.
function LSaveManager:getSlots() end

--- Returns the current summary string.
---@return string Returns the current summary string.
function LSaveManager:getSummary() end

--- Returns whether compression is currently enabled.
---@return boolean Returns whether compression is enabled.
function LSaveManager:isCompressed() end

--- Returns whether data has been modified since the last save or load.
---@return boolean Returns whether the manager is dirty.
function LSaveManager:isDirty() end

--- Loads data from a slot file, applies migrations, and restores.
---@param slot string Slot name to load.
---@return boolean True when the slot load succeeds.
---@return string Error message when the load fails.
function LSaveManager:load(slot) end

--- Marks data as modified since the last save or load.
---@return nil No value is returned.
function LSaveManager:markDirty() end

--- Registers a callback that fires after every successful load operation.
---@param func? function Callback to run after loading, or `nil` to clear it.
---@return nil No value is returned.
function LSaveManager:onAfterLoad(func) end

--- Registers a callback that fires before every save operation.
---@param func? function Callback to run before saving, or `nil` to clear it.
---@return nil No value is returned.
function LSaveManager:onBeforeSave(func) end

--- Registers a named module with collector and restorer callbacks.
---@param name string Module name to register.
---@param collector function Callback that returns the module save data.
---@param restorer function Callback that restores the module save data.
---@return nil No value is returned.
function LSaveManager:register(name, collector, restorer) end

--- Resets all state, removing callbacks and clearing the manager.
---@return nil No value is returned.
function LSaveManager:reset() end

--- Restores data from a table, applying migrations and calling restorers.
---@param data table Save data table to restore.
---@return nil No value is returned.
function LSaveManager:restore(data) end

--- Collects data and writes it to a slot file.
---@param slot string Slot name to write.
---@return nil No value is returned.
function LSaveManager:save(slot) end

--- Enables or disables LZ4 compression for saved data.
---@param enabled boolean Whether save data should be compressed.
---@return nil No value is returned.
function LSaveManager:setCompress(enabled) end

--- Sets the current schema version for new saves.
---@param version integer Schema version applied to newly written saves.
---@return nil No value is returned.
function LSaveManager:setSchemaVersion(version) end

--- Sets the summary string included in save metadata.
---@param summary string Summary text stored in save metadata.
---@return nil No value is returned.
function LSaveManager:setSummary(summary) end

--- Returns the type name of this object.
---@return string Returns the Lua-visible type name.
function LSaveManager:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare.
---@return boolean Returns whether the object matches the type name.
function LSaveManager:typeOf(name) end

--- Removes a named module and its callbacks.
---@param name string Module name to remove.
---@return nil No value is returned.
function LSaveManager:unregister(name) end

--- Advances the auto-save timer and returns the slot name when a save should trigger.
---@param dt number Elapsed time in seconds.
---@return string Returns the slot name when auto-save triggers.
function LSaveManager:update(dt) end

--- Creates a new SaveManager for slot-based save/load operations.
---@return LSaveManager Returns a new save manager userdata object.
lurek.save.newSaveManager = function() end

---@class lurek.scene
lurek.scene = {}

--- Lua-side wrapper around a [`DepthSorter`] with registry-stored callbacks.
---@class LDepthSorter
LDepthSorter = {}

--- Registers a draw callback at the given depth layer.
---@param callback function Draw callback to register.
---@param depth number Sort depth for the callback.
---@return nil No value is returned.
function LDepthSorter:add(callback, depth) end

--- Registers a table object with a draw method at the given depth.
---@param obj table Scene object with a `drawSorted` method.
---@return nil No value is returned.
function LDepthSorter:addObject(obj) end

--- Removes all registered callbacks without calling them.
---@return nil No value is returned.
function LDepthSorter:clear() end

--- Calls all draw callbacks in sorted depth order, then clears.
---@return nil No value is returned.
function LDepthSorter:flush() end

--- Returns the number of registered draw entries.
---@return integer Number of registered draw entries.
function LDepthSorter:getCount() end

--- Returns true if stable sort mode is enabled.
---@return boolean True when stable sort mode is enabled.
function LDepthSorter:isStable() end

--- Sets whether equal-depth entries preserve insertion order.
---@param stable boolean Whether equal depths keep insertion order.
---@return nil No value is returned.
function LDepthSorter:setStable(stable) end

--- Sorts all registered callbacks by depth ascending.
---@return nil No value is returned.
function LDepthSorter:sort() end

--- Returns the type name of this object.
---@return string Literal type name.
function LDepthSorter:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True if the object matches the requested type.
function LDepthSorter:typeOf(name) end

--- Clears all scenes from the stack, calling leave on each.
---@return nil No value is returned.
lurek.scene.clear = function() end

--- Creates a reusable scene class - returns a zero-argument constructor function.
---@param def? table Scene method table.
---@return function Zero-argument scene constructor function.
lurek.scene.define = function(def) end

--- Returns the number of scenes on the stack; alias for `getStackSize`.
---@return integer Number of scenes on the stack.
lurek.scene.depth = function() end

--- Restores scene data_refs from a snapshot produced by serializeScene().
---@param snapshot table Snapshot value.
---@return nil No value is returned.
lurek.scene.deserializeScene = function(snapshot) end

--- Draws all scenes in the stack from bottom to top (legacy name; prefer `render`).
---@return nil No value is returned.
lurek.scene.draw = function() end

--- Returns a fade cross-dissolve transition config table.
---@param duration? number Duration in seconds. Defaults to 0.5.
---@return table Transition config table.
lurek.scene.fade = function(duration) end

--- Returns a table array of all active scene tables.
---@return table Array of active scene tables.
lurek.scene.getActiveScenes = function() end

--- Returns the current top scene table, or nil if the stack is empty.
---@return table Current top scene table, or nil if the stack is empty.
lurek.scene.getCurrent = function() end

--- Returns a value from the inter-scene data store, or nil if not found.
---@param key string Data-store key.
---@return table Stored value when present, or nil when unavailable.
lurek.scene.getData = function(key) end

--- Returns a registered scene table by name, or nil if not found.
---@param name string Registered scene name.
---@return table Registered scene table, or nil if not found.
lurek.scene.getRegistered = function(name) end

--- Returns a list of all registered scene names.
---@return table Array of registered scene names.
lurek.scene.getRegisteredNames = function() end

--- Returns the number of scenes on the stack.
---@return integer Number of scenes on the stack.
lurek.scene.getStackSize = function() end

--- Returns the transition progress from 0.0 to 1.0.
---@return number Transition progress in the range 0.0 to 1.0.
lurek.scene.getTransitionProgress = function() end

--- Returns the easing-adjusted transition progress from 0.0 to 1.0.
---@return number Easing-adjusted transition progress in the range 0.0 to 1.0.
lurek.scene.getTransitionProgressEased = function() end

--- Returns a table listing all supported transition type strings.
---@return table Array of supported transition type names.
lurek.scene.getTransitionTypes = function() end

--- Returns true if the given key exists in the data store.
---@param key string Data-store key.
---@return boolean True when the data-store key exists.
lurek.scene.hasData = function(key) end

--- Returns true if a scene is registered under the given name.
---@param name string Registered scene name.
---@return boolean True when a scene is registered under the name.
lurek.scene.hasRegistered = function(name) end

--- Returns an iris in/out (circular reveal) transition config table.
---@param duration? number Duration in seconds. Defaults to 0.6.
---@return table Transition config table.
lurek.scene.iris = function(duration) end

--- Returns true if the scene stack is empty.
---@return boolean True when the scene stack has no scenes.
lurek.scene.isEmpty = function() end

--- Returns true if the current top scene was pushed as an overlay.
---@return boolean True when the current top scene is an overlay.
lurek.scene.isOverlay = function() end

--- Returns true if the named scene has been preloaded.
---@param name string Scene name to query.
---@return boolean True when the scene name has been preloaded.
lurek.scene.isPreloaded = function(name) end

--- Returns true if a scene transition is currently active.
---@return boolean True when a scene transition is active.
lurek.scene.isTransitioning = function() end

--- Creates a scene instance directly from a methods table.
---@param def? table Scene method table.
---@return table New scene instance table.
lurek.scene.new = function(def) end

--- Creates a new DepthSorter for z-ordered draw batching.
---@return DepthSorter New depth sorter userdata.
lurek.scene.newDepthSorter = function() end

--- Alias for `lurek.scene.new`. Creates a scene instance from a methods table.
---@param def? table Scene method table.
---@return table New scene instance table.
lurek.scene.newScene = function(def) end

--- Pops the top scene from the stack with an optional transition and easing.
---@param transition? string Transition type name.
---@param duration? number Transition duration in seconds.
---@param easing? string Easing curve name.
---@return nil No value is returned.
lurek.scene.pop = function(transition, duration, easing) end

--- Pops scenes until the named scene is on top, calling leave on each removed.
---@param name string Registered scene name to reveal.
---@return boolean True if the named scene was found and revealed.
lurek.scene.popTo = function(name) end

--- Registers a loader function for a named scene. The loader is called
---@param name string Scene name to preload.
---@param loader function Loader callback for that scene.
---@return nil No value is returned.
lurek.scene.preload = function(name, loader) end

--- Calls `scene:ready(self)` once per scene on the first tick after enter,
---@param dt number Delta time in seconds.
---@return nil No value is returned.
lurek.scene.process = function(dt) end

--- Calls `scene:process_late(dt)` on all active scenes (after process, before render).
---@param dt number Delta time in seconds.
---@return nil No value is returned.
lurek.scene.processLate = function(dt) end

--- Calls `scene:process_physics(dt)` on all active scenes (fixed timestep).
---@param dt number Fixed-step delta time in seconds.
---@return nil No value is returned.
lurek.scene.processPhysics = function(dt) end

--- Pushes a scene table onto the stack with an optional transition and easing.
---@param scene table Scene table to push.
---@param transition? string Transition type name.
---@param duration? number Transition duration in seconds.
---@param easing? string Easing curve name.
---@param params? table Optional `enter` parameters.
---@return nil No value is returned.
lurek.scene.push = function(scene, transition, duration, easing, params) end

--- Pushes a scene as a non-pausing overlay over the current top scene.
---@param scene table Overlay scene table.
---@param transition? string Transition type name.
---@param duration? number Duration in seconds.
---@param easing? string Easing curve name.
---@param params? table Optional parameter table.
---@return nil No value is returned.
lurek.scene.pushOverlay = function(scene, transition, duration, easing, params) end

--- Pushes a registered scene by name, running its loader if not yet preloaded.
---@param name string Preloaded scene name.
---@param transition? string Transition type name.
---@param duration? number Duration in seconds.
---@param easing? string Easing curve name.
---@param params? table Optional parameter table.
---@return nil No value is returned.
lurek.scene.pushPreloaded = function(name, transition, duration, easing, params) end

--- Registers a scene table by name for later retrieval.
---@param name string Registry name for the scene.
---@param scene table Scene table to register.
---@return nil No value is returned.
lurek.scene.registerScene = function(name, scene) end

--- Removes a value from the inter-scene data store by key.
---@param key string Data-store key to remove.
---@return nil No value is returned.
lurek.scene.removeData = function(key) end

--- Draws all scenes in the stack from bottom to top.
---@return nil No value is returned.
lurek.scene.render = function() end

--- Draws UI overlay for all scenes in the stack from bottom to top.
---@return nil No value is returned.
lurek.scene.renderUi = function() end

--- Returns a snapshot of the scene stack as a Lua table: { stack=[name...], data={key=val} }.
---@return table Snapshot table containing stack and data fields.
lurek.scene.serializeScene = function() end

--- Stores a value in the inter-scene data store under the given key.
---@param key string Data-store key.
---@param value LuaValue Value to store.
---@return nil No value is returned.
lurek.scene.setData = function(key, value) end

--- Returns a directional slide transition config table.
---@param direction? string Slide direction: "left", "right", "up", or "down". Defaults to "left".
---@param duration? number Duration in seconds. Defaults to 0.4.
---@return table Transition config table.
lurek.scene.slide = function(direction, duration) end

--- Replaces the top scene with a new one, calling leave and enter callbacks.
---@param scene table Scene table to switch to.
---@param transition? string Transition type name.
---@param duration? number Transition duration in seconds.
---@param easing? string Easing curve name.
---@param params? table Optional `enter` parameters.
---@return nil No value is returned.
lurek.scene.switchTo = function(scene, transition, duration, easing, params) end

--- Removes a scene from the registry by name.
---@param name string Registered scene name to remove.
---@return nil No value is returned.
lurek.scene.unregisterScene = function(name) end

--- Updates the top scene and any active transition (legacy name; prefer `process`).
---@param dt number Delta time in seconds.
---@return nil No value is returned.
lurek.scene.update = function(dt) end

--- Returns a wipe/curtain transition config table.
---@param duration? number Duration in seconds. Defaults to 0.5.
---@return table Transition config table.
lurek.scene.wipe = function(duration) end

---@class lurek.serial
lurek.serial = {}

--- Decodes a binary MessagePack string into a Lua table.
---@param bytes string Binary MessagePack payload.
---@return table Decoded Lua table.
lurek.serial.decodeMsgPack = function(bytes) end

--- Parses an XML string and returns a nested Lua table.
---@param s string XML source text to parse into nested element tables.
---@return table Parsed XML tree with tag, attrs, text, and children fields.
lurek.serial.decodeXml = function(s) end

--- Encodes a Lua table to a binary MessagePack string.
---@param value table Lua table to encode.
---@return string Binary MessagePack payload.
lurek.serial.encodeMsgPack = function(value) end

--- Parses a CSV string and returns a sequence of row tables.
---@param s string CSV source text to parse.
---@param delimiter? string Optional single-character field delimiter.
---@param has_headers? boolean Whether the first row should be treated as headers.
---@return table Parsed sequence of row tables.
lurek.serial.fromCsv = function(s, delimiter, has_headers) end

--- Parses a JSON string and returns a Lua table.
---@param s string JSON source text to parse.
---@return table Parsed Lua table representation.
lurek.serial.fromJson = function(s) end

--- Parses a TOML string and returns a Lua table.
---@param s string TOML source text to parse.
---@return table Parsed Lua table representation.
lurek.serial.fromToml = function(s) end

--- Serializes a sequence of row tables to a CSV string.
---@param value LuaValue Sequence of row tables to serialize.
---@param delimiter? string Optional single-character field delimiter.
---@param has_headers? boolean Whether to emit a header row.
---@return string Serialized CSV string.
lurek.serial.toCsv = function(value, delimiter, has_headers) end

--- Serializes a Lua value to a JSON string.
---@param value LuaValue Lua value to serialize.
---@param pretty? boolean Whether to format the output with indentation.
---@return string Serialized JSON string.
lurek.serial.toJson = function(value, pretty) end

--- Serializes a Lua table to a TOML string.
---@param value LuaValue Lua value to serialize.
---@return string Serialized TOML string.
lurek.serial.toToml = function(value) end

--- Validates a Lua table against a schema table.
---@param value LuaValue Lua value to validate.
---@param schema table Schema table describing the expected structure.
---@return boolean True when the value matches the schema.
---@return string Validation failure message.
lurek.serial.validate = function(value, schema) end

---@class lurek.spine
lurek.spine = {}

--- Lua-side wrapper around a [`Skeleton`].
---@class LSkeleton
LSkeleton = {}

--- Adds a SkeletonAnimation to this skeleton's library.
---@param anim LSkeletonAnimation Animation object to add.
---@return nil No value is returned.
function LSkeleton:addAnimation(anim) end

--- Adds a root bone with optional local transform and returns its index.
---@param name string Bone name.
---@param opts? table Optional local transform settings.
---@return integer Bone index.
function LSkeleton:addBone(name, opts) end

--- Adds a child bone attached to a parent and returns its index.
---@param name string Bone name.
---@param parent_idx integer Parent bone index.
---@param opts? table Optional local transform settings.
---@return integer Bone index.
function LSkeleton:addChildBone(name, parent_idx, opts) end

--- Adds a two-bone IK constraint and returns its index.
---@param name string Constraint name.
---@param bone_chain table Array of bone indices.
---@param bend_positive? boolean Preferred bend direction.
---@return integer Constraint index.
function LSkeleton:addIKConstraint(name, bone_chain, bend_positive) end

--- Registers a new empty skin by name.
---@param name string Skin name.
---@return nil No value is returned.
function LSkeleton:addSkin(name) end

--- Adds a slot bound to a bone and returns its index.
---@param name string Slot name.
---@param bone_idx integer Bone index to attach to.
---@param attachment? string Optional attachment name.
---@return integer Slot index.
function LSkeleton:addSlot(name, bone_idx, attachment) end

--- Evaluates an animation at `time` and blends it into this skeleton.
---@param anim LSkeletonAnimation Animation object to sample.
---@param time number Sample time in seconds.
---@param blend_weight? number Optional blend weight from `0.0` to `1.0`.
---@return nil No value is returned.
function LSkeleton:blendAnimation(anim, time, blend_weight) end

--- Returns the total number of bones.
---@return integer Bone count.
function LSkeleton:boneCount() end

--- Renders the skeleton as a stick-figure debug view into a new ImageData.
---@param width integer Output image width.
---@param height integer Output image height.
---@return ImageData Generated debug image.
function LSkeleton:drawToImage(width, height) end

--- Returns the index of the named bone.
---@param name string Bone name.
---@return integer Bone index.
function LSkeleton:findBone(name) end

--- Returns the index of the named slot.
---@param name string Slot name.
---@return integer Slot index.
function LSkeleton:findSlot(name) end

--- Returns the current playback time in seconds of the active animation.
---@return number Playback time in seconds.
function LSkeleton:getAnimationTime() end

--- Returns the world-space transform of a bone as a table.
---@param idx integer Bone index.
---@return table Bone world transform table.
function LSkeleton:getBoneWorld(idx) end

--- Returns the name of the currently active skin.
---@return string Active skin name.
function LSkeleton:getSkin() end

--- Starts playback of the named skeletal animation clip.
---@param name string Animation clip name.
---@param looping? boolean Whether playback should loop.
---@return boolean True when playback started.
function LSkeleton:playAnimation(name, looping) end

--- Sets the world-space target position for the named IK constraint.
---@param name string Constraint name.
---@param x number Target X coordinate.
---@param y number Target Y coordinate.
---@return boolean True when the constraint was found.
function LSkeleton:setIKTarget(name, x, y) end

--- Sets the root bone position and propagates world transforms.
---@param x number Root X position.
---@param y number Root Y position.
---@return nil No value is returned.
function LSkeleton:setPosition(x, y) end

--- Activates the named skin for attachment lookups.
---@param name string Skin name.
---@return boolean True when the skin was found.
function LSkeleton:setSkin(name) end

--- Registers a slot-to-attachment mapping in the named skin.
---@param skin string Skin name.
---@param slot string Slot name.
---@param attachment string Attachment name.
---@return nil No value is returned.
function LSkeleton:setSkinMapping(skin, slot, attachment) end

--- Returns the total number of slots.
---@return integer Slot count.
function LSkeleton:slotCount() end

--- Stops the current skeletal animation.
---@return nil No value is returned.
function LSkeleton:stopAnimation() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LSkeleton:type() end

--- Returns whether this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LSkeleton:typeOf(name) end

--- Advances the playing animation by `dt` seconds and applies keyframes.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LSkeleton:updateAnimation(dt) end

--- Propagates local transforms down the bone hierarchy to compute world positions.
---@return nil No value is returned.
function LSkeleton:updateWorldTransforms() end

--- Lua-side wrapper around a [`SkeletonAnimation`] keyframe clip.
---@class LSkeletonAnimation
LSkeletonAnimation = {}

--- Adds a named event marker at a time in the animation.
---@param time number Event time in seconds.
---@param name string Event name.
---@param value? number Optional numeric payload.
---@return nil No value is returned.
function LSkeletonAnimation:addEventKey(time, name, value) end

--- Adds a keyframe to a bone timeline for the given property.
---@param bone_idx integer Bone index.
---@param property string Property name such as `x`, `y`, or `rotation`.
---@param time number Keyframe time in seconds.
---@param value number Keyframe value.
---@param easing? string Optional easing mode.
---@return nil No value is returned.
function LSkeletonAnimation:addKeyframe(bone_idx, property, time, value, easing) end

--- Returns the total duration of the animation in seconds.
---@return number Animation duration in seconds.
function LSkeletonAnimation:getDuration() end

--- Returns event entries in the half-open interval `(from, to]`.
---@param from number Interval start time.
---@param to number Interval end time.
---@return table Array of `{ name, value }` event tables.
function LSkeletonAnimation:getEvents(from, to) end

--- Returns the number of bone timelines in this animation.
---@return integer Timeline count.
function LSkeletonAnimation:getTimelineCount() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LSkeletonAnimation:type() end

--- Returns whether this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LSkeletonAnimation:typeOf(name) end

--- Creates a new empty skeleton with the given name.
---@param name string Skeleton name.
---@return LSkeleton New skeleton object.
lurek.spine.newSkeleton = function(name) end

--- Creates a new empty SkeletonAnimation clip with the given name and duration.
---@param name string Animation name.
---@param duration number Clip duration in seconds.
---@return LSkeletonAnimation New animation object.
lurek.spine.newSkeletonAnimation = function(name, duration) end

---@class lurek.sprite
lurek.sprite = {}

--- Lua-side wrapper around a [`SpriteAtlas`] named-region store.
---@class LSpriteAtlas
LSpriteAtlas = {}

--- Returns the total number of named regions in the atlas.
---@return integer Total region count.
function LSpriteAtlas:entryCount() end

--- Returns a sequential table of all region names.
---@return table Array of region name strings.
function LSpriteAtlas:entryNames() end

--- Returns the region at the given 1-based insertion index.
---@param index integer One-based region index.
---@return table Region table.
function LSpriteAtlas:getByIndex(index) end

--- Returns the named region as a table.
---@param name string Region name.
---@return table Region table.
function LSpriteAtlas:getEntry(name) end

--- Returns a copy of the named region with flip flags set.
---@param name string Region name.
---@param flip_x boolean Whether to flip the region horizontally.
---@param flip_y boolean Whether to flip the region vertically.
---@return table Flipped region table.
function LSpriteAtlas:getFlipped(name, flip_x, flip_y) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LSpriteAtlas:type() end

--- Returns whether this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LSpriteAtlas:typeOf(name) end

--- Lua-side wrapper around a [`SpriteSheet`] frame-grid calculator.
---@class LSpriteSheet
LSpriteSheet = {}

--- Renders the sheet grid as a debug view into a new ImageData.
---@param width integer Output image width.
---@param height integer Output image height.
---@return ImageData Generated debug image.
function LSpriteSheet:drawToImage(width, height) end

--- Returns a sequential table of quad tables for every frame in the given column.
---@param col integer Column index.
---@return table Array of frame quad tables.
function LSpriteSheet:getColumn(col) end

--- Returns the quad for the 0-based frame index.
---@param index integer Zero-based frame index.
---@return table Frame quad table.
function LSpriteSheet:getFrame(index) end

--- Returns the total number of frames in the sheet.
---@return integer Total frame count.
function LSpriteSheet:getFrameCount() end

--- Returns the width and height of a single frame cell in pixels.
---@return integer Frame width in pixels.
---@return integer Frame height in pixels.
function LSpriteSheet:getFrameSize() end

--- Returns the number of columns and rows in the grid.
---@return integer Number of columns in the sprite grid.
---@return integer Number of rows in the sprite grid.
function LSpriteSheet:getGridSize() end

--- Returns a sequential table of quad tables for the named frame group.
---@param name string Frame group name.
---@return table Array of frame quad tables.
function LSpriteSheet:getGroupFrames(name) end

--- Returns a sequential table of all defined group names.
---@return table Array of group name strings.
function LSpriteSheet:getGroupNames() end

--- Returns a sequential table of quad tables for every frame in the given row.
---@param row integer Row index.
---@return table Array of frame quad tables.
function LSpriteSheet:getRow(row) end

--- Registers a named frame group starting at `start_frame` with `count` frames.
---@param name string Frame group name.
---@param start_frame integer Zero-based first frame index.
---@param count integer Number of frames in the group.
---@return nil No value is returned.
function LSpriteSheet:nameGroup(name, start_frame, count) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LSpriteSheet:type() end

--- Returns whether this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LSpriteSheet:typeOf(name) end

--- Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
---@param atlas LSpriteAtlas Source atlas object.
---@param sheet_width integer Virtual sheet width in pixels.
---@param sheet_height integer Virtual sheet height in pixels.
---@return LSpriteSheet New sprite sheet object.
lurek.sprite.newAtlasSheet = function(atlas, sheet_width, sheet_height) end

--- Creates an RPGMaker VX/Ace character sheet (3 cols Ă- 4 rows) with "down", "left", "right", "up" groups.
---@param texture_width integer Source texture width in pixels.
---@param texture_height integer Source texture height in pixels.
---@return LSpriteSheet New sprite sheet object.
lurek.sprite.newRPGMakerSheet = function(texture_width, texture_height) end

--- Creates a sprite sheet with a uniform grid of `frame_w Ă- frame_h` frames.
---@param texture_width integer Source texture width in pixels.
---@param texture_height integer Source texture height in pixels.
---@param frame_width integer Frame width in pixels.
---@param frame_height integer Frame height in pixels.
---@return LSpriteSheet New sprite sheet object.
lurek.sprite.newSheet = function(texture_width, texture_height, frame_width, frame_height) end

--- Parses an Aseprite JSON export string and returns a sprite atlas.
---@param json_str string Aseprite JSON export string.
---@return LSpriteAtlas Parsed sprite atlas object.
lurek.sprite.parseAsepriteAtlas = function(json_str) end

--- Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
---@param json_str string TexturePacker JSON string.
---@return LSpriteAtlas Parsed sprite atlas object.
lurek.sprite.parseAtlas = function(json_str) end

---@class lurek.system
lurek.system = {}

--- Serialises an engine error message to a compact JSON string.
---@param err string Error message, such as the second return value from `pcall`.
---@return string Returns a compact JSON object with `message`, `code`, `category`, and `hint` fields.
lurek.runtime.errorSnapshot = function(err) end

--- Returns the CPU architecture string for the current machine.
---@return string Returns the current machine architecture string.
lurek.runtime.getArch = function() end

--- Returns the command-line arguments as a table.
---@return table Returns the command-line arguments as an array table.
lurek.runtime.getArgs = function() end

--- Returns the output table from the most recently completed runBatch call.
---@param results table Results table returned by `runBatch`.
---@return integer Number of passed tasks.
---@return integer Number of failed tasks.
---@return integer Number of skipped tasks.
lurek.runtime.getBatchResults = function(results) end

--- Returns the current contents of the system clipboard.
---@return string Returns the current clipboard text or an empty string on failure.
lurek.runtime.getClipboardText = function() end

lurek.runtime.getDebugOverlay = function() end

--- Returns the value of an environment variable, or nil if not set.
---@param name string Environment variable name.
---@return string Returns the variable value when it is set.
lurek.runtime.getEnv = function(name) end

--- Returns a table of system information including OS name, CPU model, and installed RAM.
---@return table Returns engine and platform information fields.
lurek.runtime.getInfo = function() end

--- Returns the last unhandled error message, or nil.
---@return table Returns the last error snapshot table when one exists.
lurek.runtime.getLastError = function() end

--- Returns the name of the current minimum log level for runtime messages.
---@return string Returns the current minimum log level name.
lurek.runtime.getLogLevel = function() end

--- Returns the total amount of installed system RAM in megabytes.
---@return integer Returns the RAM size in megabytes.
lurek.runtime.getMemorySize = function() end

--- Resolves a stable runtime message ID such as 'L001' to its human-readable text.
---@param id string Stable runtime message identifier.
---@return string Returns the resolved message text.
lurek.runtime.getMessage = function(id) end

--- Returns the total number of message entries loaded into the runtime message catalog.
---@return integer Returns the total number of message entries.
lurek.runtime.getMessageCount = function() end

--- Returns the host operating system name ('Windows', 'Linux', 'macOS').
---@return string Returns the host operating system name.
lurek.runtime.getOS = function() end

--- Returns battery state, percentage charged, and estimated time remaining.
---@return string Battery state name.
---@return integer Battery percentage.
---@return integer Estimated seconds remaining.
lurek.runtime.getPowerInfo = function() end

--- Returns an ordered list of the user's preferred locale strings (e.g. 'en-US').
---@return table Returns locale strings ordered from most to least preferred.
lurek.runtime.getPreferredLocales = function() end

--- Returns the number of logical CPU cores available.
---@return integer Returns the number of logical CPU cores.
lurek.runtime.getProcessorCount = function() end

--- Returns the Lurek2D engine version string.
---@return string Returns the engine version string.
lurek.runtime.getVersion = function() end

--- Returns true when the runtime message catalog contains the given stable message ID.
---@param id string Stable runtime message identifier.
---@return boolean Returns whether the message catalog contains the ID.
lurek.runtime.hasMessage = function(id) end

--- Emit a log message from Lua at the specified level.
---@param level string Log level to emit.
---@param message string Log message text.
---@return nil No value is returned.
lurek.runtime.log = function(level, message) end

--- Opens a URL in the system's default browser.
---@param url string URL to open.
---@return boolean Returns whether the URL launch command was spawned.
lurek.runtime.openURL = function(url) end

--- Parses a command-line argument string and returns a structured key/value table.
---@param args? table Optional argument table to parse instead of process arguments.
---@return table Returns a table with `flags`, `options`, and `positional` fields.
lurek.runtime.parseArgs = function(args) end

--- Runs a list of shell commands in parallel and returns immediately without blocking.
---@param tasks table Table of named batch tasks to execute.
---@param opts? table Optional batch settings such as `stopOnError`.
---@return table Returns the batch results table.
lurek.runtime.runBatch = function(tasks, opts) end

--- Replaces the system clipboard contents with the given string.
---@param text string Clipboard text to write.
---@return nil No value is returned.
lurek.runtime.setClipboardText = function(text) end

--- Shows or hides the FPS/draw-call debug overlay.
---@param enabled boolean Whether the debug overlay should be visible.
---@return nil No value is returned.
lurek.runtime.setDebugOverlay = function(enabled) end

--- Sets the minimum severity level for runtime log messages.
---@param level string Minimum log level such as `debug`, `info`, `warn`, or `error`.
---@return nil No value is returned.
lurek.runtime.setLogLevel = function(level) end

---@class lurek.terminal
lurek.terminal = {}

--- Lua-side wrapper around a [`Terminal`] with widget binding management.
---@class LTerminal
LTerminal = {}

--- Attaches a widget to this terminal.
---@param widget Widget Widget userdata.
---@return nil No value is returned.
function LTerminal:addWidget(widget) end

--- Resizes the window to exactly fit the terminal grid at the current font size.
---@return nil No value is returned.
function LTerminal:autoResize() end

--- Clears all cells to defaults.
---@return nil No value is returned.
function LTerminal:clear() end

--- Detaches all widgets from this terminal.
---@return nil No value is returned.
function LTerminal:clearWidgets() end

--- Returns the cell data at 1-based coordinates.
---@param col integer Column position.
---@param row integer Row position.
---@return nil No value is returned.
function LTerminal:get(col, row) end

--- Returns the active cell size override as `{w, h}`, or `nil` if none is set.
---@return table Table with w and h fields for the active cell size override, or nil.
function LTerminal:getCellSize() end

--- Returns the terminal grid dimensions.
---@return integer Terminal grid width in cells.
---@return integer Terminal grid height in cells.
function LTerminal:getDimensions() end

--- Returns the currently focused widget, or nil.
---@return nil No value is returned.
function LTerminal:getFocused() end

--- Returns the number of attached widgets.
---@return integer Number of attached widgets.
function LTerminal:getWidgetCount() end

--- Routes a key press to the focused widget and fires callbacks.
---@param key string Lookup key.
---@return boolean True if a focused widget consumed the key press.
function LTerminal:keypressed(key) end

--- Routes a mouse press to widgets using pixel coordinates.
---@param px number Screen X position.
---@param py number Screen Y position.
---@param button? integer Mouse button id.
---@return nil No value is returned.
function LTerminal:mousepressed(px, py, button) end

--- Detaches a widget from this terminal.
---@param widget Widget Widget userdata.
---@return nil No value is returned.
function LTerminal:removeWidget(widget) end

--- Renders the terminal grid and widgets as render commands.
---@param x? number X position.
---@param y? number Y position.
---@return nil No value is returned.
function LTerminal:render(x, y) end

--- Removes the cell size override, restoring font-derived cell dimensions.
---@return nil No value is returned.
function LTerminal:resetCellSize() end

--- Sets a cell at 1-based coordinates with character FG and BG colours.
---@param ... integer|string
---@return nil No value is returned.
function LTerminal:set(...) end

--- Sets a per-terminal cell pixel size override, bypassing the font-derived size.
---@param w number Width value.
---@param h number Height value.
---@return nil No value is returned.
function LTerminal:setCellSize(w, h) end

--- Sets the focused widget, or clears focus if nil is passed.
---@param widget? Widget Widget userdata.
---@return nil No value is returned.
function LTerminal:setFocus(widget) end

--- Sets the terminal font by pixel height, snapping to the nearest built-in size.
---@param height integer Height in pixels.
---@return nil No value is returned.
function LTerminal:setFont(height) end

--- Routes text input to the focused widget and fires callbacks.
---@param text string Text content.
---@return boolean True if a focused widget consumed the text input.
function LTerminal:textinput(text) end

--- Returns the type name of this object.
---@return string Always "LTerminal".
function LTerminal:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True if name matches LTerminal or Object.
function LTerminal:typeOf(name) end

--- Lua-side wrapper around a [`Widget`] with attachment and callback state.
---@class LWidget
LWidget = {}

--- Adds a child widget to a panel widget.
---@param child Widget Child widget.
---@return nil No value is returned.
function LWidget:addChild(child) end

--- Adds an item to a list widget.
---@param item string Item text.
---@return nil No value is returned.
function LWidget:addItem(item) end

--- Removes all children from a panel widget.
---@return nil No value is returned.
function LWidget:clearChildren() end

--- Removes all items from a list widget.
---@return nil No value is returned.
function LWidget:clearItems() end

--- Returns a child widget from a panel by 1-based index, or nil.
---@param index integer 1-based item index.
---@return nil No value is returned.
function LWidget:getChild(index) end

--- Returns the number of children in a panel widget.
---@return integer Number of child widgets in the panel.
function LWidget:getChildCount() end

--- Returns the colour of a label or border widget.
---@return number Red color component.
---@return number Green color component.
---@return number Blue color component.
---@return number Alpha color component.
function LWidget:getColor() end

--- Returns a list item by 1-based index.
---@param index integer 1-based item index.
---@return string List item text at the requested index.
function LWidget:getItem(index) end

--- Returns the number of items in a list widget.
---@return integer Number of items in the list widget.
function LWidget:getItemCount() end

--- Returns the maximum character length of a text box widget.
---@return integer Maximum character length for the text box.
function LWidget:getMaxLength() end

--- Returns the widget position as 1-based coordinates.
---@return integer Widget X position as a 1-based coordinate.
---@return integer Widget Y position as a 1-based coordinate.
function LWidget:getPosition() end

--- Returns the selected item index (1-based) in a list widget, or nil.
---@return integer Selected item index, or nil if nothing is selected.
function LWidget:getSelected() end

--- Returns the widget size in cells.
---@return integer Widget width in cells.
---@return integer Widget height in cells.
function LWidget:getSize() end

--- Returns the border style name of a border widget.
---@return string Border style name.
function LWidget:getStyle() end

--- Returns the free-form identification tag.
---@return string Free-form identification tag.
function LWidget:getTag() end

--- Returns the text content of a label, button, or text box widget.
---@return string Text content of the widget.
function LWidget:getText() end

--- Returns the title of a border widget.
---@return string Border widget title text.
function LWidget:getTitle() end

--- Returns whether the widget accepts input.
---@return boolean Whether the widget accepts input.
function LWidget:isEnabled() end

--- Returns whether the widget is visible.
---@return boolean Whether the widget is visible.
function LWidget:isVisible() end

--- Removes a child widget from a panel widget.
---@param child Widget Child widget.
---@return nil No value is returned.
function LWidget:removeChild(child) end

--- Removes an item from a list widget by 1-based index.
---@param index integer 1-based item index.
---@return nil No value is returned.
function LWidget:removeItem(index) end

--- Sets the colour of a label or border widget.
---@param r number Red component.
---@param g number Green component.
---@param b number Blue component.
---@param a? number Alpha component.
---@return nil No value is returned.
function LWidget:setColor(r, g, b, a) end

--- Sets whether the widget accepts input.
---@param enabled boolean Whether it is enabled.
---@return nil No value is returned.
function LWidget:setEnabled(enabled) end

--- Sets the maximum character length of a text box widget.
---@param max_length integer Maximum text length.
---@return nil No value is returned.
function LWidget:setMaxLength(max_length) end

--- Registers a text change callback for a text box widget.
---@param callback? function Callback function.
---@return nil No value is returned.
function LWidget:setOnChange(callback) end

--- Registers a click callback for a button widget.
---@param callback? function Callback function.
---@return nil No value is returned.
function LWidget:setOnClick(callback) end

--- Registers a selection change callback for a list widget.
---@param callback? function Callback function.
---@return nil No value is returned.
function LWidget:setOnSelect(callback) end

--- Sets the widget position from 1-based coordinates.
---@param col integer Column position.
---@param row integer Row position.
---@return nil No value is returned.
function LWidget:setPosition(col, row) end

--- Sets the selected item in a list widget by 1-based index.
---@param index? integer 1-based item index.
---@return nil No value is returned.
function LWidget:setSelected(index) end

--- Sets the widget size in cells.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return nil No value is returned.
function LWidget:setSize(width, height) end

--- Sets the border style of a border widget.
---@param style string Style name.
---@return nil No value is returned.
function LWidget:setStyle(style) end

--- Sets the free-form identification tag.
---@param tag string Tag name.
---@return nil No value is returned.
function LWidget:setTag(tag) end

--- Sets the text content of a label, button, or text box widget.
---@param text string Text content.
---@return nil No value is returned.
function LWidget:setText(text) end

--- Sets the title of a border widget.
---@param title string Title text.
---@return nil No value is returned.
function LWidget:setTitle(title) end

--- Sets the widget visibility.
---@param visible boolean Whether it is visible.
---@return nil No value is returned.
function LWidget:setVisible(visible) end

--- Returns the type name of this object.
---@return string Always "LWidget".
function LWidget:type() end

--- Returns true if this object is of the given type.
---@param name string Name string.
---@return boolean True if name matches LWidget or Object.
function LWidget:typeOf(name) end

--- Adds a candidate string to the tab-completion engine.
---@param candidate string Candidate string.
---@return nil No value is returned.
lurek.terminal.addCompletion = function(candidate) end

--- Applies a named colour theme to a terminal, recolouring all existing cells.
---@param terminal Terminal Terminal userdata.
---@param theme string Theme name.
---@return nil No value is returned.
lurek.terminal.applyTheme = function(terminal, theme) end

--- Clears all entries from this terminal's command history.
---@param terminal Terminal Terminal userdata.
---@return nil No value is returned.
lurek.terminal.clearCmdHistory = function(terminal) end

--- Clears all completion candidates.
---@return nil No value is returned.
lurek.terminal.clearCompletions = function() end

--- Returns the total number of entries in this terminal's command history.
---@param terminal Terminal Terminal userdata.
---@return integer Number of entries in the command history.
lurek.terminal.cmdHistoryLen = function(terminal) end

--- Returns all registered candidates that start with `prefix`, as a sorted array.
---@param prefix string Prefix string.
---@return table Sorted array of matching completion strings.
lurek.terminal.getCompletions = function(prefix) end

--- Returns the maximum number of columns a Terminal can be constructed with.
---@return integer Maximum supported terminal column count.
lurek.terminal.getMaxCols = function() end

--- Returns the maximum number of rows a Terminal can be constructed with.
---@return integer Maximum supported terminal row count.
lurek.terminal.getMaxRows = function() end

--- Returns a table of lines from the scrollback buffer.
---@param terminal Terminal Terminal userdata.
---@param offset integer 0 = bottom (most recent).
---@param count integer maximum number of lines to return.
---@return table Array of scrollback lines.
lurek.terminal.getScrollback = function(terminal, offset, count) end

--- Creates a new decorative border widget at 1-based coordinates.
---@param col integer Column position.
---@param row integer Row position.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return Widget New decorative border widget at 1-based coordinates.
lurek.terminal.newBorder = function(col, row, width, height) end

--- Creates a new button widget at 1-based coordinates.
---@param col integer Column position.
---@param row integer Row position.
---@param width integer Width in pixels.
---@param height? integer Height in pixels.
---@param text? string Text content.
---@return Widget New button widget at 1-based coordinates.
lurek.terminal.newButton = function(col, row, width, height, text) end

--- Creates a new label widget at 1-based coordinates.
---@param col integer Column position.
---@param row integer Row position.
---@param text? string Text content.
---@return Widget New label widget at 1-based coordinates.
lurek.terminal.newLabel = function(col, row, text) end

--- Creates a new scrollable list widget at 1-based coordinates.
---@param col integer Column position.
---@param row integer Row position.
---@param width integer Width in pixels.
---@param height integer Height in pixels.
---@return Widget New scrollable list widget at 1-based coordinates.
lurek.terminal.newList = function(col, row, width, height) end

--- Creates a new container panel widget at 1-based coordinates.
---@param col integer Column position.
---@param row integer Row position.
---@param width? integer Width in pixels.
---@param height? integer Height in pixels.
---@return Widget New container panel widget at 1-based coordinates.
lurek.terminal.newPanel = function(col, row, width, height) end

--- Creates a new terminal grid with the given dimensions.
---@param cols? integer Column count.
---@param rows? integer Row count.
---@return Terminal New terminal grid with the given dimensions.
lurek.terminal.newTerminal = function(cols, rows) end

--- Creates a new single-line text box widget at 1-based coordinates.
---@param col integer Column position.
---@param row integer Row position.
---@param width integer Width in pixels.
---@return Widget New single-line text box widget at 1-based coordinates.
lurek.terminal.newTextBox = function(col, row, width) end

--- Steps one entry forward in command history (toward newer commands).
---@param terminal Terminal Terminal userdata.
---@return string Next command string, or nil when back at live input.
lurek.terminal.nextCmd = function(terminal) end

--- Returns the next candidate for `prefix`, cycling on repeated calls.
---@param prefix string Prefix string.
---@return string Next matching completion string, or nil if there are no matches.
lurek.terminal.nextCompletion = function(prefix) end

--- Parses `text` into colored span tables with optional foreground and background colors.
---@param text string Text that may contain ANSI escape codes.
---@return table Array of span tables with `text`, `bold`, and optional `fg` and `bg` fields.
lurek.terminal.parseAnsi = function(text) end

--- Steps one entry back in command history (toward older commands).
---@param terminal Terminal Terminal userdata.
---@return string Previous command string, or nil if there is no older entry.
lurek.terminal.prevCmd = function(terminal) end

--- Prints ANSI-escaped `text` onto terminal `t` starting at `(col, row)`.
---@param t Terminal Terminal userdata.
---@param col integer Column position.
---@param row integer Row position.
---@param text string Text content.
---@return nil No value is returned.
lurek.terminal.printAnsi = function(t, col, row, text) end

--- Prints text at 1-based `(col, row)` with per-keyword colour highlighting.
---@param terminal Terminal Terminal userdata.
---@param col integer Column position.
---@param row integer Row position.
---@param text string Text content.
---@param rules table Rules value.
---@return nil No value is returned.
lurek.terminal.printHighlighted = function(terminal, col, row, text, rules) end

--- Appends a command string to this terminal's history.
---@param terminal Terminal Terminal userdata.
---@param cmd string Cmd value.
---@return nil No value is returned.
lurek.terminal.pushCmdHistory = function(terminal, cmd) end

--- Appends a line to this terminal's scrollback buffer.
---@param terminal Terminal Terminal userdata.
---@param line string Line value.
---@return nil No value is returned.
lurek.terminal.pushScrollback = function(terminal, line) end

--- Removes a candidate string from the tab-completion engine.
---@param candidate string Candidate string.
---@return nil No value is returned.
lurek.terminal.removeCompletion = function(candidate) end

--- Resets the cycling cursor without clearing the candidate list.
---@return nil No value is returned.
lurek.terminal.resetCompletion = function() end

--- Returns the number of lines currently in this terminal's scrollback buffer.
---@param terminal Terminal Terminal userdata.
---@return integer Number of lines in the scrollback buffer.
lurek.terminal.scrollbackLen = function(terminal) end

--- Sets the maximum number of lines retained in the scrollback buffer.
---@param terminal Terminal Terminal userdata.
---@param cap integer Cap value.
---@return nil No value is returned.
lurek.terminal.setScrollbackCap = function(terminal, cap) end

--- Strips all ANSI escape codes from `text` and returns the plain string.
---@param text string Text content.
---@return string Plain string with ANSI escape codes removed.
lurek.terminal.stripAnsi = function(text) end

---@class lurek.thread
lurek.thread = {}

--- A synchronized message queue for cross-VM communication.
---@class LChannel
LChannel = {}

--- Clears all items from the channel.
---@return nil No value is returned.
function LChannel:clear() end

--- Waits for a value or until the timeout expires, then removes and returns it.
---@param timeout? number Optional timeout in seconds.
---@return table Dequeued value.
function LChannel:demand(timeout) end

--- Returns the number of items in the channel.
---@return integer Number of queued items.
function LChannel:getCount() end

--- Retrieves the next value from the channel without removing it.
---@return table Next value.
function LChannel:peek() end

--- Retrieves and removes a value from the channel.
---@return table Dequeued value.
function LChannel:pop() end

--- Pops a bytes value from the channel and returns it as a Lua string.
---@return string Dequeued byte string.
function LChannel:popBytes() end

--- Pops a value from the channel expecting a table.
---@return table Dequeued table value.
function LChannel:popTable() end

--- Pushes a value to the channel.
---@param value LuaValue Value to enqueue.
---@return integer Message identifier.
function LChannel:push(value) end

--- Pushes raw binary data (a Lua string treated as a byte array) to the channel.
---@param data string Raw bytes stored in a Lua string.
---@return integer Message identifier.
function LChannel:pushBytes(data) end

--- Serializes a Lua table and pushes it to the channel.
---@param value table Lua table to serialize and enqueue.
---@return integer Message identifier.
function LChannel:pushTable(value) end

--- Blocks until the channel has space, then adds the value.
---@param value LuaValue Value to enqueue.
---@return nil No value is returned.
function LChannel:supply(value) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LChannel:type() end

--- Returns whether this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LChannel:typeOf(name) end

--- Lua-side wrapper around a one-shot [`Promise`].
---@class LPromise
LPromise = {}

--- Returns the worker error string if the promise failed.
---@return string Error message string.
function LPromise:getError() end

--- Returns whether the promise has completed.
---@return boolean True when the promise has a result or an error.
function LPromise:isDone() end

--- Pops and returns the promise result.
---@return table Promise result value.
function LPromise:result() end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LPromise:type() end

--- Returns whether this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LPromise:typeOf(name) end

--- Lua-side wrapper around a background [`LuaThread`].
---@class LThread
LThread = {}

--- Returns the error message if the thread failed.
---@return string Error message string.
function LThread:getError() end

--- Returns whether the thread is currently executing.
---@return boolean True when the thread is running.
function LThread:isRunning() end

--- Launches the background thread, passing optional varargs.
---@param ... LuaValue Values passed to the worker thread.
---@return nil No value is returned.
function LThread:start(...) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LThread:type() end

--- Returns whether this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LThread:typeOf(name) end

--- Blocks the calling thread until the background thread finishes.
---@return nil No value is returned.
function LThread:wait() end

--- Lua-side wrapper around a [`ThreadPool`].
---@class LThreadPool
LThreadPool = {}

--- Retrieves the next result from the pool's output channel.
---@return table Next result value.
function LThreadPool:collect() end

--- Returns the shared input channel.
---@return LChannel Shared input channel handle.
function LThreadPool:getInputChannel() end

--- Returns the shared output channel.
---@return LChannel Shared output channel handle.
function LThreadPool:getOutputChannel() end

--- Blocks until all workers in the pool have finished execution.
---@return nil No value is returned.
function LThreadPool:join() end

--- Returns the number of workers in this pool.
---@return integer Worker count.
function LThreadPool:size() end

--- Submits a value to the pool's input channel for processing by a worker.
---@param value LuaValue Value to send to a worker.
---@return nil No value is returned.
function LThreadPool:submit(value) end

--- Returns the type name of this object.
---@return string Lua-visible type name.
function LThreadPool:type() end

--- Returns whether this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the type matches.
function LThreadPool:typeOf(name) end

--- Starts a one-shot background computation and returns a promise.
---@param code string Worker Lua source code.
---@param ... table Argument values passed to the worker.
---@return LPromise New promise handle.
lurek.thread.async = function(code, ...) end

--- Gets or creates a named global channel shared across threads.
---@param name string Channel name.
---@return LChannel Named channel handle.
lurek.thread.getChannel = function(name) end

--- Creates a new unnamed channel for inter-thread communication.
---@return LChannel New channel handle.
lurek.thread.newChannel = function() end

--- Creates a thread pool whose workers all run the same Lua code.
---@param size integer Number of worker threads to spawn.
---@param code string Worker Lua source code.
---@return LThreadPool New thread pool handle.
lurek.thread.newPool = function(size, code) end

--- Creates a new background thread from a Lua code string.
---@param code string Worker Lua source code.
---@return LThread New thread handle.
lurek.thread.newThread = function(code) end

---@class lurek.tilemap
---@field FLOOR integer  solid floor tile type (1)
---@field NORTH_WALL integer  north-facing wall tile type (2)
---@field WEST_WALL integer  west-facing wall tile type (3)
---@field OBJECT integer  object tile type (4)
lurek.tilemap = {}

--- Lua-side wrapper around an [`AutoTileSheet`].
---@class LAutoTileSheet
LAutoTileSheet = {}

--- Applies autotile rules from this sheet to a TileSet.
---@param tileset LTileSet Tileset userdata to modify.
---@param typeName string Autotile rule set name to populate.
---@param startGid? integer Optional starting global ID offset.
---@return nil No value is returned.
function LAutoTileSheet:applyToTileSet(tileset, typeName, startGid) end

--- Returns the bitmask value associated with a 1-based local tile ID.
---@param tileId integer 1-based local tile ID.
---@return integer Bitmask value associated with the tile.
function LAutoTileSheet:getBitmaskForTile(tileId) end

--- Returns the layout variant as a string.
---@return string Layout variant name.
function LAutoTileSheet:getLayout() end

--- Returns the atlas region rectangle for the 1-based tile ID.
---@param tileId integer 1-based tile ID.
---@return number Atlas X coordinate.
---@return number Atlas Y coordinate.
---@return number Atlas region width.
---@return number Atlas region height.
function LAutoTileSheet:getQuad(tileId) end

--- Returns the number of tiles in this sheet.
---@return integer Number of tiles in this sheet.
function LAutoTileSheet:getTileCount() end

--- Returns the 1-based tile ID for a given bitmask, or nil.
---@param bitmask integer Bitmask value to look up.
---@return integer Matching 1-based tile ID, or nil if no tile matches.
function LAutoTileSheet:getTileForBitmask(bitmask) end

--- Returns the tile height in pixels.
---@return integer Tile height in pixels.
function LAutoTileSheet:getTileHeight() end

--- Returns the tile width in pixels.
---@return integer Tile width in pixels.
function LAutoTileSheet:getTileWidth() end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LAutoTileSheet:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LAutoTileSheet:typeOf(name) end

--- Lua-side wrapper around a [`ChunkMap`].
---@class LChunkMap
LChunkMap = {}

--- Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
---@param cx integer Chunk column.
---@param cy integer Chunk row.
---@return integer Starting tile column for the chunk.
---@return integer Starting tile row for the chunk.
---@return integer Ending tile column for the chunk.
---@return integer Ending tile row for the chunk.
function LChunkMap:chunkTileRange(cx, cy) end

--- Clears the tile at (x, y) by setting its GID to 0.
---@param x integer Tile column.
---@param y integer Tile row.
---@return nil No value is returned.
function LChunkMap:clearTile(x, y) end

--- Fills the rectangular tile region with a GID.
---@param x0 integer Starting tile column.
---@param y0 integer Starting tile row.
---@param x1 integer Ending tile column.
---@param y1 integer Ending tile row.
---@param gid integer Tile global ID to write.
---@return nil No value is returned.
function LChunkMap:fillRect(x0, y0, x1, y1, gid) end

--- Returns the chunk size (tiles per side).
---@return integer Chunk size in tiles per side.
function LChunkMap:getChunkSize() end

--- Returns chunk coordinates whose world-pixel footprint overlaps the given viewport.
---@param vx number Viewport left position in world pixels.
---@param vy number Viewport top position in world pixels.
---@param vw number Viewport width in pixels.
---@param vh number Viewport height in pixels.
---@param tw number Tile width in pixels.
---@param th number Tile height in pixels.
---@return table Sequential table of visible chunk coordinate pairs.
function LChunkMap:getChunksInView(vx, vy, vw, vh, tw, th) end

--- Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
---@return table Sequential table of chunk coordinate pairs.
function LChunkMap:getLoadedChunks() end

--- Returns the GID at tile coordinate (x, y).
---@param x integer Tile column.
---@param y integer Tile row.
---@return integer Tile global ID at the requested coordinate.
function LChunkMap:getTile(x, y) end

--- Pre-allocates the chunk at chunk coordinates (cx, cy).
---@param cx integer Chunk column.
---@param cy integer Chunk row.
---@return nil No value is returned.
function LChunkMap:loadChunk(cx, cy) end

--- Sets the GID at tile coordinate (x, y).
---@param x integer Tile column.
---@param y integer Tile row.
---@param gid integer Tile global ID to assign.
---@return nil No value is returned.
function LChunkMap:setTile(x, y, gid) end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LChunkMap:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LChunkMap:typeOf(name) end

--- Removes the chunk at chunk coordinates (cx, cy) from memory.
---@param cx integer Chunk column.
---@param cy integer Chunk row.
---@return nil No value is returned.
function LChunkMap:unloadChunk(cx, cy) end

--- Lua-side wrapper around an [`IsoMap`].
---@class LIsoMap
LIsoMap = {}

--- Appends a new empty Z-level and returns its 1-based index.
---@return integer 1-based index of the new level.
function LIsoMap:addLevel() end

--- Fills every cell in level z with gid for the given part (1-based z; 0-based part).
---@param z integer 1-based level index.
---@param part integer 0-based part slot index.
---@param gid integer Tile global ID to write.
---@return nil No value is returned.
function LIsoMap:fillLevel(z, part, gid) end

--- Returns the map height in tiles.
---@return integer Map height in tiles.
function LIsoMap:getHeight() end

--- Returns the number of Z-levels currently in the map.
---@return integer Number of Z-levels in the map.
function LIsoMap:getLevelCount() end

--- Returns the vertical pixel offset between consecutive Z-levels.
---@return integer Vertical pixel offset between consecutive Z-levels.
function LIsoMap:getLevelHeight() end

--- Returns the number of GID slots per tile.
---@return integer Number of GID slots per tile.
function LIsoMap:getPartCount() end

--- Returns the current draw-order array (0-based part slot indices).
---@return table Sequential table of 0-based part slot indices.
function LIsoMap:getPartOrder() end

--- Returns the tile footprint height in pixels.
---@return integer Tile footprint height in pixels.
function LIsoMap:getTileHeight() end

--- Reads the GID in the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
---@param z integer 1-based level index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@param part integer 0-based part slot index.
---@return integer Tile global ID stored in the requested part slot.
function LIsoMap:getTilePart(z, x, y, part) end

--- Returns the tile footprint width in pixels.
---@return integer Tile footprint width in pixels.
function LIsoMap:getTileWidth() end

--- Returns the map width in tiles.
---@return integer Map width in tiles.
function LIsoMap:getWidth() end

--- Returns the visibility of a level (1-based z).
---@param z integer 1-based level index.
---@return boolean Whether the level is visible.
function LIsoMap:isLevelVisible(z) end

--- Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
---@param sx number Screen x position in pixels.
---@param sy number Screen y position in pixels.
---@return number Tile X coordinate at level 0.
---@return number Tile Y coordinate at level 0.
function LIsoMap:screenToTile(sx, sy) end

--- Sets the visibility of a level (1-based z).
---@param z integer 1-based level index.
---@param visible boolean Whether the level should be visible.
---@return nil No value is returned.
function LIsoMap:setLevelVisible(z, visible) end

--- Sets the screen pixel origin.
---@param x number Screen x origin in pixels.
---@param y number Screen y origin in pixels.
---@return nil No value is returned.
function LIsoMap:setOrigin(x, y) end

--- Overrides the draw order for this IsoMap.
---@param order table Sequential table of 0-based part slot indices with one entry per part.
---@return nil No value is returned.
function LIsoMap:setPartOrder(order) end

--- Writes a GID into the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
---@param z integer 1-based level index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@param part integer 0-based part slot index.
---@param gid integer Tile global ID to write.
---@return nil No value is returned.
function LIsoMap:setTilePart(z, x, y, part, gid) end

--- Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
---@param tx number Tile x coordinate.
---@param ty number Tile y coordinate.
---@param tz number Tile z coordinate.
---@return number Screen X position in pixels.
---@return number Screen Y position in pixels.
function LIsoMap:tileToScreen(tx, ty, tz) end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LIsoMap:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LIsoMap:typeOf(name) end

--- Lua-side wrapper around a [`LargeMapRenderer`] for chunk-level occlusion culling on large worlds.
---@class LLargeMapRenderer
LLargeMapRenderer = {}

--- Returns the current chunk size.
---@return integer Current chunk size.
function LLargeMapRenderer:getChunkSize() end

--- Returns the map dimensions as (width, height) in tiles.
---@return integer Map width in tiles.
---@return integer Map height in tiles.
function LLargeMapRenderer:getMapSize() end

--- Returns the tile ID at (x, y), or nil if out of bounds.
---@param x integer 0-based tile column.
---@param y integer 0-based tile row.
---@return integer Tile ID at the requested coordinate, or nil if it is out of bounds.
function LLargeMapRenderer:getTile(x, y) end

--- Returns the number of tileset atlas columns.
---@return integer Number of tileset atlas columns.
function LLargeMapRenderer:getTilesetColumns() end

--- Returns the total number of chunks that cover the loaded map.
---@return integer Total number of chunks that cover the loaded map.
function LLargeMapRenderer:getTotalChunks() end

--- Returns the number of chunks currently within the camera viewport.
---@return integer Number of chunks currently within the camera viewport.
function LLargeMapRenderer:getVisibleChunks() end

--- Marks every chunk as dirty.
---@return nil No value is returned.
function LLargeMapRenderer:invalidateAll() end

--- Marks a chunk at chunk-grid coordinates (cx, cy) as dirty.
---@param cx integer Chunk column.
---@param cy integer Chunk row.
---@return nil No value is returned.
function LLargeMapRenderer:invalidateChunk(cx, cy) end

--- Returns whether LOD rendering is currently enabled.
---@return boolean Whether LOD rendering is currently enabled.
function LLargeMapRenderer:isLodEnabled() end

--- Updates the camera position and zoom used for visibility culling.
---@param x number Camera x position.
---@param y number Camera y position.
---@param zoom number Camera zoom factor.
---@return nil No value is returned.
function LLargeMapRenderer:setCamera(x, y, zoom) end

--- Sets the chunk size used for culling (default 16).
---@param size integer Chunk size used for culling.
---@return nil No value is returned.
function LLargeMapRenderer:setChunkSize(size) end

--- Enables or disables level-of-detail rendering for distant chunks.
---@param enabled boolean Whether LOD rendering should be enabled.
---@return nil No value is returned.
function LLargeMapRenderer:setLodEnabled(enabled) end

--- Sets the distance thresholds (in tile units) at which each LOD level activates.
---@param levels table Sequential table of LOD threshold distances in tile units.
---@return nil No value is returned.
function LLargeMapRenderer:setLodThresholds(levels) end

--- Loads a flat row-major array of tile IDs covering width by height tiles.
---@param data table Sequential table of tile IDs where 0 represents an empty tile.
---@param width integer Map width in tiles.
---@param height integer Map height in tiles.
---@return nil No value is returned.
function LLargeMapRenderer:setMapData(data, width, height) end

--- Sets a single tile ID at (x, y).  Coordinates are 0-based.
---@param x integer 0-based tile column.
---@param y integer 0-based tile row.
---@param tileId integer Tile ID to assign.
---@return nil No value is returned.
function LLargeMapRenderer:setTile(x, y, tileId) end

--- Sets the number of tile columns in the atlas texture used for UV calculation.
---@param cols integer Number of atlas columns.
---@return nil No value is returned.
function LLargeMapRenderer:setTilesetColumns(cols) end

--- Sets the viewport dimensions in pixels used for visibility culling.
---@param width number Viewport width in pixels.
---@param height number Viewport height in pixels.
---@return nil No value is returned.
function LLargeMapRenderer:setViewport(width, height) end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LLargeMapRenderer:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LLargeMapRenderer:typeOf(name) end

--- Lua-side wrapper around a [`MapBlock`].
---@class LMapBlock
LMapBlock = {}

--- Returns the block dimensions as (width, height) in tiles.
---@return integer Block width in tiles.
---@return integer Block height in tiles.
function LMapBlock:getDimensions() end

--- Returns the block height in tiles.
---@return integer Block height in tiles.
function LMapBlock:getHeight() end

--- Returns the number of segments along the height.
---@return integer Number of segments along the height.
function LMapBlock:getHeightInSegments() end

--- Returns the number of layers in this block.
---@return integer Number of layers in this block.
function LMapBlock:getLayerCount() end

--- Returns the name of this block.
---@return string Human-readable block name.
function LMapBlock:getName() end

--- Returns the segment size in tiles.
---@return integer Segment size in tiles.
function LMapBlock:getSegmentSize() end

--- Returns the side connection ID for a segment on a given edge.
---@param edge string Edge name: north, east, south, or west.
---@param segment integer 1-based segment index on that edge.
---@return integer Side connection ID for the segment.
function LMapBlock:getSide(edge, segment) end

--- Returns the GID of the tile at (x, y) on the given layer (1-based).
---@param layer integer 1-based layer index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@return integer Tile global ID at the requested cell.
function LMapBlock:getTile(layer, x, y) end

--- Returns the placement weight.
---@return number Placement weight value.
function LMapBlock:getWeight() end

--- Returns the block width in tiles.
---@return integer Block width in tiles.
function LMapBlock:getWidth() end

--- Returns the number of segments along the width.
---@return integer Number of segments along the width.
function LMapBlock:getWidthInSegments() end

--- Sets the human-readable name of this block.
---@param name string Human-readable block name.
---@return nil No value is returned.
function LMapBlock:setName(name) end

--- Sets the side connection ID for a segment on a given edge.
---@param edge string Edge name: north, east, south, or west.
---@param segment integer 1-based segment index on that edge.
---@param sideId integer Side connection ID to assign.
---@return nil No value is returned.
function LMapBlock:setSide(edge, segment, sideId) end

--- Sets the GID of a tile at (x, y) on the given layer (1-based).
---@param layer integer 1-based layer index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@param gid integer Tile global ID to assign.
---@return nil No value is returned.
function LMapBlock:setTile(layer, x, y, gid) end

--- Sets the placement weight.
---@param weight number Placement weight value.
---@return nil No value is returned.
function LMapBlock:setWeight(weight) end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LMapBlock:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LMapBlock:typeOf(name) end

--- Lua-side wrapper for a map generator (size preset or explicit dimensions).
---@class LMapGen
LMapGen = {}

--- Generates a TileMap using the group's blocks and an optional script index, seed, and layer name.
---@param scriptIndex? integer Optional 1-based script index to run.
---@param seed? integer Optional random seed.
---@param layerName? string Optional name for the generated layer.
---@return LTileMap Generated tile map userdata.
function LMapGen:generate(scriptIndex, seed, layerName) end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LMapGen:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LMapGen:typeOf(name) end

--- Lua-side wrapper around a [`MapGroup`].
---@class LMapGroup
LMapGroup = {}

--- Adds a block to this group.
---@param block LMapBlock Map block userdata to add.
---@return nil No value is returned.
function LMapGroup:addBlock(block) end

--- Adds a MapScript to this group.
---@param script LMapScript Map script userdata to add.
---@return nil No value is returned.
function LMapGroup:addScript(script) end

--- Returns the number of blocks in this group.
---@return integer Number of blocks in this group.
function LMapGroup:getBlockCount() end

--- Returns the name of this group.
---@return string Group name.
function LMapGroup:getName() end

--- Returns the number of scripts in this group.
---@return integer Number of scripts in this group.
function LMapGroup:getScriptCount() end

--- Removes a block by 1-based index.
---@param idx integer 1-based block index.
---@return nil No value is returned.
function LMapGroup:removeBlock(idx) end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LMapGroup:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LMapGroup:typeOf(name) end

--- Lua-side wrapper around a [`MapScript`] procedural generation script.
---@class LMapScript
LMapScript = {}

--- Appends a generation step from a step-definition table.
---@param stepDef table Step definition table with a type field and optional placement fields.
---@return nil No value is returned.
function LMapScript:addStep(stepDef) end

--- Returns the number of steps in this script.
---@return integer Number of steps in this script.
function LMapScript:getStepCount() end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LMapScript:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LMapScript:typeOf(name) end

--- Lua-side wrapper around a [`TileMap`] with callback registries and shared engine state.`r`n#[derive(Clone)]
---@class LTileMap
LTileMap = {}

--- Adds a new empty layer and returns its 1-based index.
---@param name string Layer name.
---@param w integer Layer width in tiles.
---@param h integer Layer height in tiles.
---@return integer 1-based index of the new layer.
function LTileMap:addLayer(name, w, h) end

--- Adds a tileset to this map.
---@param tileset LTileSet Tileset userdata to attach to the map.
---@return nil No value is returned.
function LTileMap:addTileSet(tileset) end

--- Applies 4-bit cardinal autotile rules to every tile on layer (1-based).
---@param layer integer 1-based layer index.
---@param typeName string Autotile rule set name.
---@return nil No value is returned.
function LTileMap:applyAutoTile(layer, typeName) end

--- Applies 8-bit directional autotile rules to every tile on layer (1-based).
---@param layer integer 1-based layer index.
---@param typeName string Autotile rule set name.
---@return nil No value is returned.
function LTileMap:applyAutoTile8(layer, typeName) end

--- Applies 8-bit directional autotile at a single cell and its 3x3 neighborhood (1-based).
---@param layer integer 1-based layer index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@param typeName string Autotile rule set name.
---@return nil No value is returned.
function LTileMap:applyAutoTile8At(layer, x, y, typeName) end

--- Applies 4-bit cardinal autotile at a single cell and its 3x3 neighborhood (1-based).
---@param layer integer 1-based layer index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@param typeName string Autotile rule set name.
---@return nil No value is returned.
function LTileMap:applyAutoTileAt(layer, x, y, typeName) end

--- Checks entity positions against registered tile-enter callbacks and fires matching callbacks.
---@param layer integer Layer index passed through to the tile lookup.
---@param entities table Sequential table of entity position tables with x and y fields.
---@return nil No value is returned.
function LTileMap:checkEntities(layer, entities) end

--- Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
---@param layer integer 1-based layer index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@return nil No value is returned.
function LTileMap:clearTile(layer, x, y) end

--- Renders the tile map to a CPU ImageData using the given tile pixel size.
---@param tile_size integer Tile size in pixels used for rasterization.
---@return LImageData CPU image data containing the rendered tile map.
function LTileMap:drawToImage(tile_size) end

--- Fills an entire layer with the given GID (1-based layer).
---@param layer integer 1-based layer index.
---@param gid integer Tile global ID to write into every cell.
---@return nil No value is returned.
function LTileMap:fill(layer, gid) end

--- Fires the tile-exit callback for the given GID.
---@param gid integer Tile global ID whose callback should be fired.
---@param entity table Entity data passed to the callback.
---@param tile_x integer Tile column passed to the callback.
---@param tile_y integer Tile row passed to the callback.
---@return nil No value is returned.
function LTileMap:fireTileExit(gid, entity, tile_x, tile_y) end

--- Fires the tile-step callback for the given GID.
---@param gid integer Tile global ID whose callback should be fired.
---@param entity table Entity data passed to the callback.
---@param tile_x integer Tile column passed to the callback.
---@param tile_y integer Tile row passed to the callback.
---@return nil No value is returned.
function LTileMap:fireTileStep(gid, entity, tile_x, tile_y) end

--- Returns the chunk size used for spatial partitioning.
---@return integer Chunk size used for spatial partitioning.
function LTileMap:getChunkSize() end

--- Returns the RGBA tint color of a layer.
---@param idx integer 1-based layer index.
---@return number Layer red tint component.
---@return number Layer green tint component.
---@return number Layer blue tint component.
---@return number Layer alpha tint component.
function LTileMap:getLayerColor(idx) end

--- Returns the number of layers.
---@return integer Number of layers in this map.
function LTileMap:getLayerCount() end

--- Returns the name of a layer by 1-based index.
---@param idx integer 1-based layer index.
---@return string Layer name, or nil if the index is out of range.
function LTileMap:getLayerName(idx) end

--- Returns the pixel offset of a layer.
---@param idx integer 1-based layer index.
---@return number Horizontal pixel offset.
---@return number Vertical pixel offset.
function LTileMap:getLayerOffset(idx) end

--- Returns the parallax factor of a layer.
---@param idx integer 1-based layer index.
---@return number Horizontal parallax factor.
---@return number Vertical parallax factor.
function LTileMap:getLayerParallax(idx) end

--- Returns layer visibility.
---@param idx integer 1-based layer index.
---@return boolean Whether the layer is visible.
function LTileMap:getLayerVisible(idx) end

--- Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
---@return string Current map orientation name.
function LTileMap:getOrientation() end

--- Returns the GID at (x, y) on the given layer (1-based).
---@param layer integer 1-based layer index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@return integer Tile global ID at the requested cell.
function LTileMap:getTile(layer, x, y) end

--- Returns tile dimensions as (width, height).
---@return integer Tile width in pixels.
---@return integer Tile height in pixels.
function LTileMap:getTileDimensions() end

--- Returns the tile height in pixels.
---@return integer Tile height in pixels.
function LTileMap:getTileHeight() end

--- Returns a tileset by 1-based index, or nil if out of range.
---@param idx integer 1-based tileset index.
---@return LTileSet Tileset userdata at the index, or nil if the index is out of range.
function LTileMap:getTileSet(idx) end

--- Returns the number of tilesets attached to this map.
---@return integer Number of tilesets attached to this map.
function LTileMap:getTileSetCount() end

--- Returns the tile width in pixels.
---@return integer Tile width in pixels.
function LTileMap:getTileWidth() end

--- Returns the viewport as (x, y, w, h) or nil if not set.
---@return number Viewport X coordinate.
---@return number Viewport Y coordinate.
---@return number Viewport width.
---@return number Viewport height.
function LTileMap:getViewport() end

--- Returns true if the tile at (x, y) on layer is solid (1-based).
---@param layer integer 1-based layer index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@return boolean Whether the tile at the requested cell is solid.
function LTileMap:isSolid(layer, x, y) end

--- Registers a callback fired when an entity reaches a tile with the given GID.
---@param gid integer Tile global ID to watch for.
---@param func function Callback receiving world_x, world_y, tile_x, and tile_y.
---@return nil No value is returned.
function LTileMap:onTileEnter(gid, func) end

--- Registers a callback for when an entity exits a tile with the given GID.
---@param gid integer Tile global ID to watch for.
---@param fn function Callback receiving entity, tile_x, and tile_y.
---@return nil No value is returned.
function LTileMap:onTileExit(gid, fn) end

--- Registers a callback for when an entity steps on a tile with the given GID.
---@param gid integer Tile global ID to watch for.
---@param fn function Callback receiving entity, tile_x, and tile_y.
---@return nil No value is returned.
function LTileMap:onTileStep(gid, fn) end

--- Returns true if any solid tile overlaps the given world-space rectangle on layer (1-based).
---@param layer integer 1-based layer index.
---@param x number Rectangle left position in world pixels.
---@param y number Rectangle top position in world pixels.
---@param w number Rectangle width in pixels.
---@param h number Rectangle height in pixels.
---@return boolean Whether any solid tile overlaps the rectangle.
function LTileMap:rectOverlapsSolid(layer, x, y, w, h) end

--- Renders the tile map to the screen at the given offset.
---@param ox? number Optional horizontal render offset in pixels.
---@param oy? number Optional vertical render offset in pixels.
---@return nil No value is returned.
function LTileMap:render(ox, oy) end

--- Sets the RGBA tint color for a layer.
---@param idx integer 1-based layer index.
---@param r number Red tint component.
---@param g number Green tint component.
---@param b number Blue tint component.
---@param a number Alpha tint component.
---@return nil No value is returned.
function LTileMap:setLayerColor(idx, r, g, b, a) end

--- Sets the pixel offset for a layer.
---@param idx integer 1-based layer index.
---@param ox number Horizontal pixel offset.
---@param oy number Vertical pixel offset.
---@return nil No value is returned.
function LTileMap:setLayerOffset(idx, ox, oy) end

--- Sets the parallax scrolling factor for a layer.
---@param idx integer 1-based layer index.
---@param px number Horizontal parallax factor.
---@param py number Vertical parallax factor.
---@return nil No value is returned.
function LTileMap:setLayerParallax(idx, px, py) end

--- Shows or hides a tile layer by its 1-based index.
---@param idx integer 1-based layer index.
---@param visible boolean Whether the layer should be visible.
---@return nil No value is returned.
function LTileMap:setLayerVisible(idx, visible) end

--- Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
---@param orientation string Orientation name to apply.
---@return nil No value is returned.
function LTileMap:setOrientation(orientation) end

--- Sets the GID of a tile at (x, y) on the given layer (1-based).
---@param layer integer 1-based layer index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@param gid integer Tile global ID to assign.
---@return nil No value is returned.
function LTileMap:setTile(layer, x, y, gid) end

--- Sets a per-tile RGBA tint override (1-based layer, x, y).
---@param layer integer 1-based layer index.
---@param x integer 1-based tile column.
---@param y integer 1-based tile row.
---@param r number Red tint component.
---@param g number Green tint component.
---@param b number Blue tint component.
---@param a number Alpha tint component.
---@return nil No value is returned.
function LTileMap:setTileTint(layer, x, y, r, g, b, a) end

--- Sets the viewport rectangle for rendering culling.
---@param x number Viewport left position in world pixels.
---@param y number Viewport top position in world pixels.
---@param w number Viewport width in pixels.
---@param h number Viewport height in pixels.
---@return nil No value is returned.
function LTileMap:setViewport(x, y, w, h) end

--- Performs a swept AABB collision test against solid tiles on a 1-based layer.
---@param layer integer 1-based layer index.
---@param x number Starting rectangle left position in world pixels.
---@param y number Starting rectangle top position in world pixels.
---@param w number Rectangle width in pixels.
---@param h number Rectangle height in pixels.
---@param dx number Horizontal movement delta in pixels.
---@param dy number Vertical movement delta in pixels.
---@return number Contact X position.
---@return number Contact Y position.
---@return number Collision normal X component.
---@return number Collision normal Y component.
---@return number 1-based hit tile column.
---@return number 1-based hit tile row.
function LTileMap:sweepRect(layer, x, y, w, h, dx, dy) end

--- Converts tile coordinates to world pixel coordinates (1-based input).
---@param tx integer 1-based tile column.
---@param ty integer 1-based tile row.
---@return number World X position in pixels.
---@return number World Y position in pixels.
function LTileMap:tileToWorld(tx, ty) end

--- Converts the given layer into a 2D navigation grid.
---@param layer integer Layer index passed through to the underlying navigation-grid builder.
---@param walkable_gids table Sequential table of tile global IDs to treat as walkable.
---@return table Table of row tables where true marks a walkable cell.
function LTileMap:toNavGrid(layer, walkable_gids) end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LTileMap:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LTileMap:typeOf(name) end

--- Advances tile animation timers by dt seconds.
---@param dt number Delta time in seconds.
---@return nil No value is returned.
function LTileMap:update(dt) end

--- Converts world pixel coordinates to tile coordinates.
---@param wx number World x position in pixels.
---@param wy number World y position in pixels.
---@return integer 1-based tile column.
---@return integer 1-based tile row.
function LTileMap:worldToTile(wx, wy) end

--- Lua-side wrapper around a [`TileSet`].
---@class LTileSet
LTileSet = {}

--- Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
---@param tileId integer 1-based local tile ID.
---@return table Sequential table of frame tables, or nil if the tile has no animation.
function LTileSet:getAnimation(tileId) end

--- Looks up the 1-based local tile ID for a 4-bit cardinal autotile bitmask, or nil.
---@param typeName string Autotile rule set name.
---@param bitmask integer 4-bit cardinal autotile bitmask.
---@return integer Matching 1-based local tile ID, or nil if no rule matches.
function LTileSet:getAutoTileId(typeName, bitmask) end

--- Looks up the 1-based local tile ID for an 8-bit directional autotile bitmask, or nil.
---@param typeName string Autotile rule set name.
---@param bitmask integer 8-bit directional autotile bitmask.
---@return integer Matching 1-based local tile ID, or nil if no rule matches.
function LTileSet:getAutoTileId8(typeName, bitmask) end

--- Returns the number of tile columns in the atlas texture.
---@return integer Number of tile columns in the atlas texture.
function LTileSet:getColumns() end

--- Returns the first global ID assigned to this tileset.
---@return integer First global tile ID assigned to this tileset.
function LTileSet:getFirstGid() end

--- Returns the margin in pixels around the edges of the atlas.
---@return integer Margin in pixels around the atlas edges.
function LTileSet:getMargin() end

--- Computes the atlas source rectangle for a 1-based local tile ID.
---@param tileId integer 1-based local tile ID.
---@return table Atlas source rectangle table with x, y, width, and height fields.
function LTileSet:getQuad(tileId) end

--- Returns the spacing in pixels between tiles in the atlas.
---@return integer Spacing in pixels between tiles in the atlas.
function LTileSet:getSpacing() end

--- Returns the total number of tiles in this tileset.
---@return integer Total number of tiles in this tileset.
function LTileSet:getTileCount() end

--- Returns the tile dimensions as (width, height).
---@return integer Tile width in pixels.
---@return integer Tile height in pixels.
function LTileSet:getTileDimensions() end

--- Returns the height of a single tile in pixels.
---@return integer Height of a single tile in pixels.
function LTileSet:getTileHeight() end

--- Returns the width of a single tile in pixels.
---@return integer Width of a single tile in pixels.
function LTileSet:getTileWidth() end

--- Returns whether a 1-based local tile ID is solid.
---@param tileId integer 1-based local tile ID.
---@return boolean Whether the tile is solid.
function LTileSet:isSolid(tileId) end

--- Sets the animation frames for a 1-based local tile ID from a table of {tileid, duration}.
---@param tileId integer 1-based local tile ID.
---@param frames table Sequential table of frame tables with tileid and duration fields.
---@return nil No value is returned.
function LTileSet:setAnimation(tileId, frames) end

--- Registers a 4-bit cardinal autotile rule. tileId is 1-based.
---@param typeName string Autotile rule set name.
---@param bitmask integer 4-bit cardinal autotile bitmask.
---@param tileId integer 1-based local tile ID to assign.
---@return nil No value is returned.
function LTileSet:setAutoTileRule(typeName, bitmask, tileId) end

--- Registers an 8-bit directional autotile rule. tileId is 1-based.
---@param typeName string Autotile rule set name.
---@param bitmask integer 8-bit directional autotile bitmask.
---@param tileId integer 1-based local tile ID to assign.
---@return nil No value is returned.
function LTileSet:setAutoTileRule8(typeName, bitmask, tileId) end

--- Sets whether a 1-based local tile ID is solid for collision purposes.
---@param tileId integer 1-based local tile ID.
---@param solid boolean Whether the tile should be treated as solid.
---@return nil No value is returned.
function LTileSet:setSolid(tileId, solid) end

--- Returns the type name of this object.
---@return string Literal type name for this userdata.
function LTileSet:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean Whether this userdata matches the requested type.
function LTileSet:typeOf(name) end

--- Parses an LDtk JSON export string and returns a TileMap.
---@param json_str string LDtk JSON export string.
---@param level_name? string Optional level name to load.
---@return LTileMap Tile map userdata created from the LDtk data.
lurek.tilemap.fromLDtk = function(json_str, level_name) end

--- Converts screen position back to axial hex coordinates (pointy-top layout).
---@param sx number Screen x position.
---@param sy number Screen y position.
---@param size number Hex size in pixels.
---@return integer Axial q coordinate.
---@return integer Axial r coordinate.
lurek.tilemap.fromScreenHex = function(sx, sy, size) end

--- Converts screen position back to tile coordinates for diamond isometric projection.
---@param sx number Screen x position.
---@param sy number Screen y position.
---@param tileW number Tile width in pixels.
---@param tileH number Tile height in pixels.
---@return number Tile X coordinate.
---@return number Tile Y coordinate.
lurek.tilemap.fromScreenIso = function(sx, sy, tileW, tileH) end

--- Returns all hex cells within radius distance (filled hex circle) as a table.
---@param q integer Center axial q coordinate.
---@param r integer Center axial r coordinate.
---@param radius integer Area radius.
---@return table Sequential table of axial coordinate pairs in the area.
lurek.tilemap.hexArea = function(q, r, radius) end

--- Returns the hex distance between two axial coordinates.
---@param q1 integer First axial q coordinate.
---@param r1 integer First axial r coordinate.
---@param q2 integer Second axial q coordinate.
---@param r2 integer Second axial r coordinate.
---@return integer Hex distance between the two coordinates.
lurek.tilemap.hexDistance = function(q1, r1, q2, r2) end

--- Returns all hex cells along a line between two axial coordinates as a table.
---@param q1 integer Starting axial q coordinate.
---@param r1 integer Starting axial r coordinate.
---@param q2 integer Ending axial q coordinate.
---@param r2 integer Ending axial r coordinate.
---@return table Sequential table of axial coordinate pairs along the line.
lurek.tilemap.hexLine = function(q1, r1, q2, r2) end

--- Returns the six axial neighbor coordinates as a table of {q, r} pairs.
---@param q integer Axial q coordinate.
---@param r integer Axial r coordinate.
---@return table Sequential table of neighbor coordinate tables.
lurek.tilemap.hexNeighbors = function(q, r) end

--- Reflects hex coordinates across an axis through the center.
---@param q integer Axial q coordinate to reflect.
---@param r integer Axial r coordinate to reflect.
---@param centerQ integer Center axial q coordinate.
---@param centerR integer Center axial r coordinate.
---@param axis string Reflection axis name.
---@return integer Reflected axial q coordinate.
---@return integer Reflected axial r coordinate.
lurek.tilemap.hexReflect = function(q, r, centerQ, centerR, axis) end

--- Returns all cells at exactly radius distance from (q, r) as a table.
---@param q integer Center axial q coordinate.
---@param r integer Center axial r coordinate.
---@param radius integer Ring radius.
---@return table Sequential table of axial coordinate pairs in the ring.
lurek.tilemap.hexRing = function(q, r, radius) end

--- Rotates hex coordinates around a center by steps x 60 degrees clockwise.
---@param q integer Axial q coordinate to rotate.
---@param r integer Axial r coordinate to rotate.
---@param centerQ integer Center axial q coordinate.
---@param centerR integer Center axial r coordinate.
---@param steps integer Number of 60-degree clockwise steps.
---@return integer Rotated axial q coordinate.
---@return integer Rotated axial r coordinate.
lurek.tilemap.hexRotate = function(q, r, centerQ, centerR, steps) end

--- Rounds fractional axial coordinates to the nearest hex cell.
---@param q number Fractional axial q coordinate.
---@param r number Fractional axial r coordinate.
---@return integer Rounded axial q coordinate.
---@return integer Rounded axial r coordinate.
lurek.tilemap.hexRound = function(q, r) end

--- Returns all hex cells from center outward to radius, ring by ring, as a table.
---@param q integer Center axial q coordinate.
---@param r integer Center axial r coordinate.
---@param radius integer Maximum spiral radius.
---@return table Sequential table of axial coordinate pairs in spiral order.
lurek.tilemap.hexSpiral = function(q, r, radius) end

--- Snaps an angle (in radians) to the nearest isometric direction (1-4).
---@param angle number Angle in radians.
---@return integer Nearest isometric direction index.
lurek.tilemap.isoDirectionFromAngle = function(angle) end

--- Returns the name of an isometric direction (1-4).
---@param direction integer Isometric direction index from 1 to 4.
---@return string Direction name.
lurek.tilemap.isoDirectionName = function(direction) end

--- Rotates an isometric direction (1-4) clockwise by steps.
---@param direction integer Isometric direction index from 1 to 4.
---@param steps integer Number of clockwise rotation steps.
---@return integer Rotated isometric direction index.
lurek.tilemap.isoRotate = function(direction, steps) end

--- Parses a TMX XML string and returns a table with map metadata and layers.
---@param xml string TMX XML source string.
---@return table Table containing map metadata and layer summaries.
lurek.tilemap.loadTMX = function(xml) end

--- Creates a new AutoTileSheet with the given tile dimensions and layout.
---@param tileWidth integer Tile width in pixels.
---@param tileHeight integer Tile height in pixels.
---@param layout string Layout name: blob47, composite48, or minimal16.
---@return LAutoTileSheet New autotile sheet userdata.
lurek.tilemap.newAutoTileSheet = function(tileWidth, tileHeight, layout) end

--- Creates a new ChunkMap with the given chunk size.
---@param chunkSize? integer Optional chunk size in tiles.
---@return LChunkMap New chunk map userdata.
lurek.tilemap.newChunkMap = function(chunkSize) end

--- Creates a new IsoMap with no levels.
---@param width integer Map width in tiles.
---@param height integer Map height in tiles.
---@param tileW integer Tile footprint width in pixels.
---@param tileH integer Tile footprint height in pixels.
---@param levelHeight integer Vertical pixel offset between levels.
---@param partCount? integer Optional number of part slots per tile.
---@return LIsoMap New isometric map userdata.
lurek.tilemap.newIsoMap = function(width, height, tileW, tileH, levelHeight, partCount) end

--- Creates a LargeMapRenderer for chunk-level occlusion culling on maps larger than 200x200 tiles.
---@param tileW integer Tile width in pixels.
---@param tileH integer Tile height in pixels.
---@return LLargeMapRenderer New large-map renderer userdata.
lurek.tilemap.newLargeMapRenderer = function(tileW, tileH) end

--- Creates a new MapBlock with the given dimensions.
---@param width integer Block width in tiles.
---@param height integer Block height in tiles.
---@param layers? integer Optional number of layers.
---@param segmentSize? integer Optional segment size in tiles.
---@return LMapBlock New map block userdata.
lurek.tilemap.newMapBlock = function(width, height, layers, segmentSize) end

--- Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
---@param group LMapGroup Source map group userdata.
---@param presetOrWidth LuaValue Preset name string or explicit width integer.
---@param segmentSizeOrHeight LuaValue Segment size for preset form or explicit height integer.
---@param segmentSize? integer Optional segment size when using explicit width and height.
---@return LMapGen New map generator userdata.
lurek.tilemap.newMapGen = function(group, presetOrWidth, segmentSizeOrHeight, segmentSize) end

--- Creates a new empty MapGroup with the given name.
---@param name string Group name.
---@return LMapGroup New map group userdata.
lurek.tilemap.newMapGroup = function(name) end

--- Creates a new empty MapScript procedural generation script.
---@return LMapScript New map script userdata.
lurek.tilemap.newMapScript = function() end

--- Creates a new TileMap with the given tile size and chunk size.
---@param tileWidth integer Tile width in pixels.
---@param tileHeight integer Tile height in pixels.
---@param chunkSize? integer Optional chunk size in tiles.
---@return LTileMap New tile map userdata.
lurek.tilemap.newTileMap = function(tileWidth, tileHeight, chunkSize) end

--- Creates a new TileSet with the given atlas layout parameters.
---@param firstGid integer First global tile ID assigned to the tileset.
---@param tileCount integer Number of tiles in the tileset.
---@param columns integer Number of columns in the atlas.
---@param tileWidth integer Tile width in pixels.
---@param tileHeight integer Tile height in pixels.
---@param spacing? integer Optional spacing in pixels between atlas tiles.
---@param margin? integer Optional margin in pixels around the atlas.
---@return LTileSet New tileset userdata.
lurek.tilemap.newTileSet = function(firstGid, tileCount, columns, tileWidth, tileHeight, spacing, margin) end

--- Converts axial hex coordinates to screen position (pointy-top layout).
---@param q integer Axial q coordinate.
---@param r integer Axial r coordinate.
---@param size number Hex size in pixels.
---@return number Screen X position.
---@return number Screen Y position.
lurek.tilemap.toScreenHex = function(q, r, size) end

--- Converts tile coordinates to screen position using diamond isometric projection.
---@param tx number Tile x coordinate.
---@param ty number Tile y coordinate.
---@param tileW number Tile width in pixels.
---@param tileH number Tile height in pixels.
---@return number Screen X position.
---@return number Screen Y position.
lurek.tilemap.toScreenIso = function(tx, ty, tileW, tileH) end

---@class lurek.timer
lurek.timer = {}

--- Lua-side wrapper around a [`Scheduler`] with per-event callback storage.
---@class LScheduler
LScheduler = {}

--- Schedules a callback to fire once after a delay.
---@param delay number Delay in seconds.
---@param callback function Callback function.
---@return integer Scheduled event ID.
function LScheduler:after(delay, callback) end

--- Schedules a callback to fire once after `n` frames.
---@param n integer Number of frames to wait.
---@param callback function Callback function.
---@return integer Scheduled event ID.
function LScheduler:afterFrames(n, callback) end

--- Schedules a named one-shot callback, replacing any existing event with the same name.
---@param name string Scheduler event name.
---@param delay number Delay in seconds.
---@param callback function Callback function.
---@return integer Scheduled event ID.
function LScheduler:afterNamed(name, delay, callback) end

--- Cancels a scheduled event by its numeric ID.
---@param id integer Scheduled event ID.
---@return boolean True if the scheduled event was found and cancelled.
function LScheduler:cancel(id) end

--- Cancels all scheduled events and returns the count removed.
---@return integer Returned integer.
function LScheduler:cancelAll() end

--- Cancels and removes a previously scheduled event identified by its string name assigned via `afterNamed` or `everyNamed`.
---@param name string The string name given when the event was scheduled
---@return boolean True if the named event existed and was cancelled
function LScheduler:cancelNamed(name) end

--- Schedules a callback to fire repeatedly at the given interval.
---@param interval number Interval in seconds.
---@param callback function Callback function.
---@param count? integer Optional repeat count; defaults to infinite.
---@return integer Scheduled event ID.
function LScheduler:every(interval, callback, count) end

--- Schedules a callback to fire every `n` frames.
---@param n integer Frame interval between callbacks.
---@param func function Callback function.
---@param count? integer Optional repeat count; defaults to infinite.
---@return integer Scheduled event ID.
function LScheduler:everyFrames(n, func, count) end

--- Schedules a named repeating callback, replacing any existing event with the same name.
---@param name string Scheduler event name.
---@param interval number Interval in seconds.
---@param callback function Callback function.
---@param count? integer Optional repeat count; defaults to infinite.
---@return integer Scheduled event ID.
function LScheduler:everyNamed(name, interval, callback, count) end

--- Returns the total number of currently active (not yet completed or cancelled) events in this scheduler instance.
---@return integer The count of active scheduled events
function LScheduler:getCount() end

--- Returns whether the event exists and its configured base interval in seconds.
---@param id integer The event identifier to query
---@return boolean True when the event exists.
---@return number Configured base interval in seconds.
function LScheduler:getInterval(id) end

--- Returns whether the event exists and how many seconds remain until it fires next.
---@param id integer The event identifier to query
---@return boolean True when the event exists.
---@return number Remaining seconds until the event fires next.
function LScheduler:getRemaining(id) end

--- Returns whether the event exists and its remaining repetition count.
---@param id integer The event identifier to query
---@return boolean True when the event exists.
---@return integer Remaining repetition count.
function LScheduler:getRepeatCount(id) end

--- Returns the current time-scale multiplier for this scheduler instance.
---@return number The active time-scale multiplier
function LScheduler:getTimeScale() end

--- Returns true if this scheduler has zero active events.
---@return boolean True if there are no active events
function LScheduler:isEmpty() end

--- Returns whether the given event is currently paused.
---@param id integer Scheduled event ID.
---@return boolean True when the event is currently paused.
function LScheduler:isPaused(id) end

--- Checks whether the named scheduled event is currently in the paused state.
---@param name string The string name of the event to check
---@return boolean True if the named event is paused
function LScheduler:isPausedNamed(name) end

--- Pauses a scheduled event by its ID.
---@param id integer Scheduled event ID.
---@return boolean True if the event was found and paused.
function LScheduler:pause(id) end

--- Temporarily suspends the named scheduled event so it stops accumulating time.
---@param name string The string name of the event to pause
---@return boolean True if the named event existed and was paused
function LScheduler:pauseNamed(name) end

--- Resets the countdown for a scheduled event back to its full configured interval, as if it had just been created.
---@param id integer The event identifier to reset
---@return boolean True if the event existed and was reset
function LScheduler:resetEvent(id) end

--- Resumes a paused event by its ID.
---@param id integer Scheduled event ID.
---@return boolean True if the event was found and resumed.
function LScheduler:resume(id) end

--- Resumes a previously paused named event so it continues accumulating time.
---@param name string The string name of the event to resume
---@return boolean True if the named event existed and was resumed
function LScheduler:resumeNamed(name) end

--- Modifies the repeat interval of an already-scheduled repeating event.
---@param id integer The event identifier to modify
---@param interval number The new interval in seconds
---@return boolean True if the event existed and its interval was changed
function LScheduler:setInterval(id, interval) end

--- Sets a time-scale multiplier that affects all events in this scheduler.
---@param scale number The time-scale multiplier (0.0 or greater)
---@return nil No return value.
function LScheduler:setTimeScale(scale) end

--- Returns the string type name of this userdata object.
---@return string The type name (e.g. "LScheduler", "LCamera", "LSignal")
function LScheduler:type() end

--- Checks whether this object matches the given type name.
---@param name string The type name to check against (e.g. "LScheduler", "Object")
---@return boolean True if this object matches the given type name
function LScheduler:typeOf(name) end

--- Advances all time-based events in this scheduler by `dt` seconds (scaled by the scheduler's time-scale multiplier).
---@param dt number Delta time in seconds since the last update call
---@return integer The number of callbacks that were fired
function LScheduler:update(dt) end

--- Advances all frame-based events by one frame tick.
---@return integer The number of callbacks that were fired
function LScheduler:updateFrames() end

--- Schedules a one-shot callback that fires after `delay` wall-clock seconds, completely unaffected by the engine's time scale or pause state.
---@param delay number Wall-clock seconds to wait before firing
---@param func function The Lua function to call when the deadline arrives
---@return nil No return value.
lurek.timer.afterReal = function(delay, func) end

--- Creates a new Scheduler pre-loaded with a sequence of one-shot callbacks that fire in order with cumulative delays.
---@param steps table Array of {delay: number, func: function} entries
---@return LScheduler A new scheduler pre-loaded with the chained callbacks
lurek.timer.chain = function(steps) end

--- Returns a rolling average of recent frame delta times in seconds.
---@return number Rolling average delta time in seconds
lurek.timer.getAverageDelta = function() end

--- Returns the time elapsed since the previous frame in seconds.
---@return number Delta time in seconds for the current frame
lurek.timer.getDelta = function() end

--- Returns the current instantaneous frames-per-second as measured by the engine clock.
---@return number The current FPS value
lurek.timer.getFPS = function() end

--- Returns the total number of frames that have been rendered since the engine was initialised.
---@return integer Total frame count since engine start
lurek.timer.getFrameCount = function() end

--- Returns the high-resolution (microsecond-precision) elapsed time since engine start in seconds.
---@return number High-resolution elapsed seconds
lurek.timer.getMicroTime = function() end

--- Returns the fixed timestep interval used by the `process_physics` callback loop, in seconds.
---@return number The fixed physics timestep in seconds
lurek.timer.getPhysicsDelta = function() end

--- Returns the maximum number of physics simulation sub-steps that the engine will perform in a single frame.
---@return integer The maximum physics sub-steps per frame
lurek.timer.getPhysicsMaxSteps = function() end

--- Returns the exponentially smoothed frame delta time in seconds.
---@return number The smoothed delta time in seconds
lurek.timer.getSmoothedDelta = function() end

--- Returns the total wall-clock time that has elapsed since the engine was initialised, in seconds.
---@return number Total elapsed seconds since engine start
lurek.timer.getTime = function() end

--- Creates and returns a new independent Scheduler userdata object for managing timed and frame-based callbacks.
---@return LScheduler A new scheduler instance
lurek.timer.newScheduler = function() end

--- Sets the fixed timestep interval for the `process_physics` callback loop, in seconds.
---@param dt number The desired fixed timestep in seconds
---@return nil No return value.
lurek.timer.setPhysicsDelta = function(dt) end

--- Sets the maximum number of physics simulation sub-steps allowed per frame.
---@param n integer The desired maximum sub-step count (clamped to 1-64)
---@return nil No return value.
lurek.timer.setPhysicsMaxSteps = function(n) end

--- Sets the exponential moving-average smoothing factor (alpha) used by `getSmoothedDelta`.
---@param alpha number Smoothing factor between 0.01 (very smooth) and 1.0 (raw)
---@return nil No return value.
lurek.timer.setSmoothingFactor = function(alpha) end

--- Blocks the current thread for the specified number of seconds using an OS-level sleep.
---@param seconds number Duration to sleep in seconds
---@return nil No return value.
lurek.timer.sleep = function(seconds) end

--- Manually advances the engine timer by one frame tick and returns the resulting delta time.
---@return number The delta time for the stepped frame
lurek.timer.step = function() end

lurek.timer.tickRealTimers = function() end

lurek.timer.tickWaits = function() end

--- Yields the current Lua coroutine until at least `frames` engine frames have elapsed.
---@param frames integer Number of engine frames to wait
---@return nil No return value.
lurek.timer.waitFrames = function(frames) end

--- Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
---@param seconds number Minimum wall-clock seconds to wait
---@return nil No return value.
lurek.timer.waitSeconds = function(seconds) end

---@class lurek.tween
lurek.tween = {}

--- Lua-side spring handle: wraps [`SpringSystem`] and a registry reference to the target table.
---@class LSpring
LSpring = {}

--- Stops the spring.
---@return nil No value is returned.
function LSpring:cancel() end

--- Returns the current interpolated position for the named field.
---@param field string Field name to read from the spring system.
---@return number Current field position; missing fields yield `nil` at runtime.
function LSpring:getPosition(field) end

--- Returns whether the spring is still active.
---@return boolean True when the spring has not been cancelled or settled.
function LSpring:isActive() end

--- Returns whether all spring axes have settled.
---@return boolean True when all axes converged within precision.
function LSpring:isSettled() end

--- Updates the damping coefficient on all axes.
---@param value number New damping value.
---@return nil No value is returned.
function LSpring:setDamping(value) end

--- Updates the stiffness constant on all axes.
---@param value number New stiffness value.
---@return nil No value is returned.
function LSpring:setStiffness(value) end

--- Updates target values for all fields present in `fields_table`.
---@param fields_table table Mapping of field names to new target values.
---@return nil No value is returned.
function LSpring:setTarget(fields_table) end

--- Returns the type name of this object.
---@return string The literal type name.
function LSpring:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the object matches the requested type.
function LSpring:typeOf(name) end

--- Advances the spring by `dt` seconds.
---@param dt number Delta time in seconds.
---@return boolean True while the spring is still moving.
function LSpring:update(dt) end

--- A managed interpolation from start to end values over time.
---@class LTween
LTween = {}

--- Cancels this tween immediately; fires the `onCancel` callback if set.
---@param ud LuaValue
---@return nil No value is returned.
LTween.cancel = function(ud) end

--- Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
---@return number Raw playback progress in the range 0 to 1.
function LTween:getProgress() end

--- Returns true if the tween is still running (not completed or cancelled).
---@return boolean True when the tween is still active.
function LTween:isActive() end

--- Sets a callback called when the tween is cancelled.
---@param self LTween Tween handle returned for chaining.
---@param f function Callback to run when the tween is cancelled.
---@return LTween The same tween handle.
LTween.onCancel = function(self, f) end

--- Sets a callback to fire when the tween finishes all cycles.
---@param self LTween Tween handle returned for chaining.
---@param f function Callback to run when the tween completes.
---@return LTween The same tween handle.
LTween.onComplete = function(self, f) end

--- Sets a callback called every tick with the current eased progress.
---@param self LTween Tween handle returned for chaining.
---@param f function Callback that receives the current eased progress.
---@return LTween The same tween handle.
LTween.onUpdate = function(self, f) end

--- Pauses this tween; time stops advancing but the tween is not cancelled.
---@return nil No value is returned.
function LTween:pause() end

--- Resumes a paused tween, continuing from the position where it was paused.
---@return nil No value is returned.
function LTween:resume() end

--- Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
---@param n integer Extra cycles after the first; use -1 for infinite repeats.
---@return nil No value is returned.
function LTween:setRepeat(n) end

--- Enables or disables yoyo (ping-pong) on each repeat cycle.
---@param enabled boolean True to reverse direction on each repeat cycle.
---@return nil No value is returned.
function LTween:setYoyo(enabled) end

--- Returns the type name of this object.
---@return string The literal type name.
function LTween:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the object matches the requested type.
function LTween:typeOf(name) end

--- A group of animations that run simultaneously over the same duration.
---@class LTweenParallel
LTweenParallel = {}

--- Adds an existing tween handle to the parallel group.
---@param self LTweenParallel Parallel handle that receives the tween.
---@param tween LTween Tween handle to add to the group.
---@return nil No value is returned.
LTweenParallel.add = function(self, tween) end

--- Cancels the parallel group immediately.
---@return nil No value is returned.
function LTweenParallel:cancel() end

--- Returns true if the parallel is running and not yet complete.
---@return boolean True when the parallel is active.
function LTweenParallel:isActive() end

--- Sets a callback fired when all child tweens finish.
---@param self LTweenParallel Parallel handle returned for chaining.
---@param fn function Callback to run when the parallel group completes.
---@return LTweenParallel The same parallel handle.
LTweenParallel.onComplete = function(self, fn) end

--- Marks the parallel as active.
---@param self LTweenParallel Parallel handle returned for chaining.
---@return LTweenParallel The same parallel handle.
LTweenParallel.start = function(self) end

--- Creates and adds an inline tween entry to the parallel group.
---@param self LTweenParallel Parallel handle returned for chaining.
---@param duration number Tween duration in seconds.
---@param target table Lua table whose numeric fields will be animated.
---@param fields table Mapping of field names to target values.
---@param easing? string Optional easing name; defaults to `linear`.
---@return LTweenParallel The same parallel handle.
LTweenParallel.tween = function(self, duration, target, fields, easing) end

--- Returns the type name of this object.
---@return string The literal type name.
function LTweenParallel:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the object matches the requested type.
function LTweenParallel:typeOf(name) end

--- A chained sequence of animations that run one after another.
---@class LTweenSequence
LTweenSequence = {}

--- Appends an immediate callback step to the sequence.
---@param self LTweenSequence Sequence handle returned for chaining.
---@param fn function Callback to run at this step.
---@return LTweenSequence The same sequence handle.
LTweenSequence.callback = function(self, fn) end

--- Cancels the sequence and stops all pending steps.
---@return nil No value is returned.
function LTweenSequence:cancel() end

--- Appends a delay step to the sequence.
---@param self LTweenSequence Sequence handle returned for chaining.
---@param seconds number Delay duration in seconds.
---@param fn? function Optional callback to run after the delay.
---@return LTweenSequence The same sequence handle.
LTweenSequence.delay = function(self, seconds, fn) end

--- Returns true if the sequence has been started and has not yet completed.
---@return boolean True when the sequence is active.
function LTweenSequence:isActive() end

--- Sets a callback fired when all steps complete.
---@param self LTweenSequence Sequence handle returned for chaining.
---@param fn function Callback to run when the sequence completes.
---@return LTweenSequence The same sequence handle.
LTweenSequence.onComplete = function(self, fn) end

--- Marks the sequence as active so `lurek.tween.update(dt)` begins ticking it.
---@param self LTweenSequence Sequence handle returned for chaining.
---@return LTweenSequence The same sequence handle.
LTweenSequence.start = function(self) end

--- Appends a tween step to the sequence.
---@param self LTweenSequence Sequence handle returned for chaining.
---@param duration number Tween duration in seconds.
---@param target table Lua table whose numeric fields will be animated.
---@param fields table Mapping of field names to target values.
---@param easing? string Optional easing name; defaults to `linear`.
---@return LTweenSequence The same sequence handle.
LTweenSequence.tween = function(self, duration, target, fields, easing) end

--- Returns the type name of this object.
---@return string The literal type name.
function LTweenSequence:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the object matches the requested type.
function LTweenSequence:typeOf(name) end

--- Lua-side wrapper around the pure-Rust [`TweenState`] timing core.
---@class LTweenState
---@field paused boolean  whether the tween is currently paused
LTweenState = {}

--- Returns whether the tween state has completed.
---@return boolean True when playback is complete.
function LTweenState:isComplete() end

--- Interpolates from `start` to `finish` using the eased tween progress.
---@param start number Range start value.
---@param finish number Range end value.
---@return number Interpolated value at the current eased progress.
function LTweenState:lerp(start, finish) end

--- Resets the tween state to elapsed time zero.
---@return nil No value is returned.
function LTweenState:reset() end

--- Returns the raw 0..1 playback progress.
---@return number Raw playback progress in the range 0 to 1.
function LTweenState:t() end

--- Advances the tween state by `dt` seconds.
---@param dt number Delta time in seconds.
---@return boolean True when the tween state reached completion.
function LTweenState:tick(dt) end

--- Returns the type name of this object.
---@return string The literal type name.
function LTweenState:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to compare against.
---@return boolean True when the object matches the requested type.
function LTweenState:typeOf(name) end

--- Cancels all active tweens, sequences, parallels, and springs immediately.
---@return nil No value is returned.
lurek.tween.cancelAll = function() end

--- Creates a started delay sequence that waits and then optionally calls a callback.
---@param seconds number Delay duration in seconds.
---@param fn? function Optional callback to run after the delay.
---@return LTweenSequence Started sequence handle.
lurek.tween.delay = function(seconds, fn) end

--- Returns the number of currently active tween objects.
---@return integer Count of active tweens, sequences, parallels, and springs.
lurek.tween.getActiveCount = function() end

--- Returns all available built-in and custom easing names.
---@return table Array-style table of easing names.
lurek.tween.getEasingNames = function() end

--- Creates a standalone tween state that is not registered with the engine.
---@param duration number Tween duration in seconds.
---@param easing? string Optional easing name; defaults to `linear`.
---@return LTweenState New standalone tween state.
lurek.tween.newState = function(duration, easing) end

--- Creates an empty parallel tween handle.
---@return LTweenParallel New parallel handle.
lurek.tween.parallel = function() end

--- Registers a custom easing function under `name`.
---@param name string Easing name used by later tween calls.
---@param fn function Callback that maps progress from 0..1 to 0..1.
---@return nil No value is returned.
lurek.tween.registerEasing = function(name, fn) end

--- Creates an empty tween sequence handle.
---@return LTweenSequence New sequence handle.
lurek.tween.sequence = function() end

--- Creates a spring animation that drives named table fields toward target values.
---@param target_table table Lua table whose numeric fields will be animated.
---@param fields_table table Mapping of field names to target values.
---@param opts? table Optional stiffness, damping, and precision settings.
---@return LSpring New spring handle.
lurek.tween.spring = function(target_table, fields_table, opts) end

--- Creates a tween using `target` as the first argument.
---@param target table Lua table whose numeric fields will be animated.
---@param fields table Mapping of field names to target values.
---@param duration number Tween duration in seconds.
---@param easing? string Optional easing name; defaults to `linear`.
---@return LTween New tween handle.
lurek.tween.to = function(target, fields, duration, easing) end

--- Creates a property tween and registers it for automatic updating.
---@param duration number Tween duration in seconds.
---@param target table Lua table whose numeric fields will be animated.
---@param fields table Mapping of field names to target values.
---@param easing? string Optional easing name; defaults to `linear`.
---@return LTween New tween handle.
lurek.tween.tween = function(duration, target, fields, easing) end

--- Advances all active tweens, sequences, parallels, and springs by `dt` seconds.
---@param dt number Delta time in seconds for this frame.
---@return nil No value is returned.
lurek.tween.update = function(dt) end

---@class lurek.ui
lurek.ui = {}

---@class LAccordion
LAccordion = {}

--- Adds a section entry to this Accordion widget.
---@param title string Section title.
---@param content_idx? integer Optional content widget index. Pass nil to leave the section without linked content.
---@return nil No value is returned.
LAccordion.addSection = function(title, content_idx) end

--- Returns the section count of this Accordion widget.
---@return integer Number of sections in the accordion.
LAccordion.getSectionCount = function() end

--- Returns the section title of this Accordion widget.
---@param section_idx integer 1-based section index.
---@return string Section title. Returns nil if the index is out of range.
LAccordion.getSectionTitle = function(section_idx) end

--- Returns true if exclusive is enabled for this Accordion widget.
---@return boolean True if only one section can be expanded at a time.
LAccordion.isExclusive = function() end

--- Returns true if section expanded is enabled for this Accordion widget.
---@param section_idx integer 1-based section index.
---@return boolean True if the section is currently expanded.
LAccordion.isSectionExpanded = function(section_idx) end

--- Sets the exclusive for this Accordion widget.
---@param v boolean True to force single-section expansion.
---@return nil No value is returned.
LAccordion.setExclusive = function(v) end

--- Toggles the expanded/collapsed status of an Accordion section.
---@param section_idx integer 1-based section index.
---@return boolean True if the section is expanded after toggling.
LAccordion.toggleSection = function(section_idx) end

--- Lua wrapper for a stacked area chart renderer.
---@class LAreaChart
LAreaChart = {}

--- Adds a stacked layer with values and colour.
---@param name string Layer name.
---@param values table Array of values, one for each X sample.
---@param r number Red channel from `0` to `1`.
---@param g number Green channel from `0` to `1`.
---@param b number Blue channel from `0` to `1`.
---@return nil No value is returned.
function LAreaChart:addLayer(name, values, r, g, b) end

--- Renders the area chart into an existing ImageData.
---@param target ImageData Target image buffer.
---@return nil No value is returned.
function LAreaChart:drawToImage(target) end

--- Sets the maximum Y value for axis scaling.
---@param v number Maximum Y-axis value.
---@return nil No value is returned.
function LAreaChart:setYMax(v) end

--- Returns the type name of this object.
---@return string The Lua-visible type name.
function LAreaChart:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the requested type.
function LAreaChart:typeOf(name) end

---@class LBadge
LBadge = {}

--- Returns the raw count of this Badge widget.
---@return integer Raw count stored on this badge.
LBadge.getCount = function() end

--- Returns the display text of this Badge widget, e.g. "99+" when over the max.
---@return string Display text rendered for this badge.
LBadge.getDisplayText = function() end

--- Sets the count displayed on this Badge widget.
---@param count integer Count value to display.
---@return nil No value is returned.
LBadge.setCount = function(count) end

--- Lua wrapper for a grouped bar chart renderer.
---@class LBarChart
LBarChart = {}

--- Adds a category group with per-series values.
---@param label string Category label.
---@param values table Array of values, one for each series.
---@return nil No value is returned.
function LBarChart:addCategory(label, values) end

--- Adds a bar series with a name and colour.
---@param name string Series name.
---@param r number Red channel from `0` to `1`.
---@param g number Green channel from `0` to `1`.
---@param b number Blue channel from `0` to `1`.
---@return nil No value is returned.
function LBarChart:addSeries(name, r, g, b) end

--- Renders the bar chart into an existing ImageData.
---@param target ImageData Target image buffer.
---@return nil No value is returned.
function LBarChart:drawToImage(target) end

--- Returns the type name of this object.
---@return string The Lua-visible type name.
function LBarChart:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the requested type.
function LBarChart:typeOf(name) end

---@class LButton
LButton = {}

--- Returns the text of this Button widget.
---@return string Text displayed on this button.
LButton.getText = function() end

--- Sets the text for this Button widget.
---@param text string Text to display on this button.
---@return nil No value is returned.
LButton.setText = function(text) end

---@class LCheckbox
LCheckbox = {}

--- Returns the text of this Checkbox widget.
---@return string Text displayed next to this checkbox.
LCheckbox.getText = function() end

--- Returns true if checked is enabled for this Checkbox widget.
---@return boolean True when this checkbox is checked.
LCheckbox.isChecked = function() end

--- Sets the checked for this Checkbox widget.
---@param checked boolean Checked state to assign.
---@return nil No value is returned.
LCheckbox.setChecked = function(checked) end

--- Sets the text for this Checkbox widget.
---@param text string Text to display next to this checkbox.
---@return nil No value is returned.
LCheckbox.setText = function(text) end

---@class LColorPicker
LColorPicker = {}

--- Returns the color of this Color_Picker widget.
---@return number Red component.
---@return number Green component.
---@return number Blue component.
---@return number Alpha component.
LColorPicker.getColor = function() end

--- Returns the color mode of this Color_Picker widget.
---@return string Current color mode string.
LColorPicker.getColorMode = function() end

--- Returns the show alpha of this Color_Picker widget.
---@return boolean True if the alpha control is visible.
LColorPicker.getShowAlpha = function() end

--- Sets the color for this Color_Picker widget.
---@param r number Red component.
---@param green number Green component.
---@param b number Blue component.
---@param a? number Optional alpha component. Pass nil to keep the current alpha.
---@return nil No value is returned.
LColorPicker.setColor = function(r, green, b, a) end

--- Sets the color mode for this Color_Picker widget.
---@param mode string Color mode string, such as rgb.
---@return nil No value is returned.
LColorPicker.setColorMode = function(mode) end

--- Registers a callback invoked when this widget's value changes.
---@param fn function Callback to invoke when the color changes.
---@return nil No value is returned.
LColorPicker.setOnChange = function(fn) end

--- Sets the show alpha for this Color_Picker widget.
---@param v boolean True to show the alpha control.
---@return nil No value is returned.
LColorPicker.setShowAlpha = function(v) end

---@class LComboBox
LComboBox = {}

--- Adds a item entry to this Combo_Box widget.
---@param text string Item text to append.
---@return nil No value is returned.
LComboBox.addItem = function(text) end

--- Clears all items entries from this Combo_Box widget.
---@return nil No value is returned.
LComboBox.clearItems = function() end

--- Returns the item of this Combo_Box widget.
---@param index integer 1-based item index to read.
---@return string Item text at the given index. Returns nil when the index is invalid.
LComboBox.getItem = function(index) end

--- Returns the item count of this Combo_Box widget.
---@return integer Number of items in this combo box.
LComboBox.getItemCount = function() end

--- Returns the selected index of this Combo_Box widget.
---@return integer Selected 1-based item index, or 0 when nothing is selected.
LComboBox.getSelectedIndex = function() end

--- Returns the selected item of this Combo_Box widget.
---@return string Selected item text. Returns nil when nothing is selected.
LComboBox.getSelectedItem = function() end

--- Removes the item from this Combo_Box widget.
---@param index integer 1-based item index to remove.
---@return boolean True when an item was removed.
LComboBox.removeItem = function(index) end

--- Sets the selected index for this Combo_Box widget.
---@param index integer 1-based item index to select.
---@return nil No value is returned.
LComboBox.setSelectedIndex = function(index) end

---@class LDialog
LDialog = {}

--- Adds a button entry to this Dialog widget.
---@param text string Button label to add.
---@param cb? function Optional callback argument accepted by the API.
---@return integer 1-based footer button index, or 0 when unavailable.
LDialog.addButton = function(text, cb) end

--- Closes and removes this dialog from the screen.
---@return nil No value is returned.
LDialog.close = function() end

--- Returns the content of this Dialog widget.
---@return integer Content widget index. Returns nil when no content is set.
LDialog.getContent = function() end

--- Returns the title of this Dialog widget.
---@return string Title text displayed by this dialog.
LDialog.getTitle = function() end

--- Returns true if modal is enabled for this Dialog widget.
---@return boolean True when this dialog is modal.
LDialog.isModal = function() end

--- Returns true if open is enabled for this Dialog widget.
---@return boolean True when this dialog is open.
LDialog.isOpen = function() end

--- Performs the open operation on this Dialog widget.
---@return nil No value is returned.
LDialog.open = function() end

--- Sets the content for this Dialog widget.
---@param content_idx? integer Optional widget index to use as dialog content.
---@return nil No value is returned.
LDialog.setContent = function(content_idx) end

--- Sets the modal for this Dialog widget.
---@param v boolean True to make this dialog modal.
---@return nil No value is returned.
LDialog.setModal = function(v) end

--- Registers a callback invoked when this dialog is closed.
---@param fn function Callback to run when this dialog closes.
---@return nil No value is returned.
LDialog.setOnClose = function(fn) end

--- Sets the title for this Dialog widget.
---@param title string Title text to assign.
---@return nil No value is returned.
LDialog.setTitle = function(title) end

---@class LDockPanel
LDockPanel = {}

--- Performs the dock operation on this Dock_Panel widget.
---@param child_idx integer Widget index to dock.
---@param side string Dock side name.
---@return nil No value is returned.
LDockPanel.dock = function(child_idx, side) end

--- Returns the docked count of this Dock_Panel widget.
---@return integer Number of docked child widgets.
LDockPanel.getDockedCount = function() end

--- Returns the split size of this Dock_Panel widget.
---@param side string Dock side name.
---@return number Split size for the given side. Returns nil when the side has no entry.
LDockPanel.getSplitSize = function(side) end

--- Sets the split size for this Dock_Panel widget.
---@param side string Dock side name.
---@param size number Split size to assign.
---@return nil No value is returned.
LDockPanel.setSplitSize = function(side, size) end

--- Performs the undock operation on this Dock_Panel widget.
---@param child_idx integer Widget index to undock.
---@return nil No value is returned.
LDockPanel.undock = function(child_idx) end

---@class LGuiTable
LGuiTable = {}

--- Adds a column entry to this Gui_Table widget.
---@param header string Column header text.
---@param width? number Optional column width in pixels. Pass nil to use the default width.
---@return nil No value is returned.
LGuiTable.addColumn = function(header, width) end

--- Adds a row entry to this Gui_Table widget.
---@param cells table Array of cell text values for the new row.
---@return nil No value is returned.
LGuiTable.addRow = function(cells) end

--- Returns the cell of this Gui_Table widget.
---@param row integer 1-based row index.
---@param col integer 1-based column index.
---@return string Cell text. Returns nil if the row or column is out of range.
LGuiTable.getCell = function(row, col) end

--- Returns the column count of this Gui_Table widget.
---@return integer Number of columns.
LGuiTable.getColumnCount = function() end

--- Returns the row count of this Gui_Table widget.
---@return integer Number of rows.
LGuiTable.getRowCount = function() end

--- Returns the selected row of this Gui_Table widget.
---@return integer Selected 1-based row index. Returns nil if no row is selected.
LGuiTable.getSelectedRow = function() end

--- Returns true if sortable is enabled for this Gui_Table widget.
---@return boolean True if sorting is enabled.
LGuiTable.isSortable = function() end

--- Sets the cell for this Gui_Table widget.
---@param row integer 1-based row index.
---@param col integer 1-based column index.
---@param text string Replacement cell text.
---@return nil No value is returned.
LGuiTable.setCell = function(row, col, text) end

--- Registers a callback invoked when a table row is selected.
---@param fn function Callback to invoke when a row is selected.
---@return nil No value is returned.
LGuiTable.setOnSelect = function(fn) end

--- Sets the selected row for this Gui_Table widget.
---@param row? integer 1-based row index. Pass nil to clear the selection.
---@return nil No value is returned.
LGuiTable.setSelectedRow = function(row) end

--- Sets the sortable for this Gui_Table widget.
---@param v boolean True to enable sorting.
---@return nil No value is returned.
LGuiTable.setSortable = function(v) end

---@class LGuiWindow
LGuiWindow = {}

--- Returns the title of this Gui_Window widget.
---@return string Title text displayed on this GUI window.
LGuiWindow.getTitle = function() end

--- Returns true if closeable is enabled for this Gui_Window widget.
---@return boolean True when this GUI window is closeable.
LGuiWindow.isCloseable = function() end

--- Returns true if draggable is enabled for this Gui_Window widget.
---@return boolean True when this GUI window is draggable.
LGuiWindow.isDraggable = function() end

--- Returns true if resizable is enabled for this Gui_Window widget.
---@return boolean True when this GUI window is resizable.
LGuiWindow.isResizable = function() end

--- Sets the closeable for this Gui_Window widget.
---@param v boolean True to make this GUI window closeable.
---@return nil No value is returned.
LGuiWindow.setCloseable = function(v) end

--- Sets the draggable for this Gui_Window widget.
---@param v boolean True to make this GUI window draggable.
---@return nil No value is returned.
LGuiWindow.setDraggable = function(v) end

--- Registers a callback invoked when this window is closed.
---@param fn function Callback to run when this window closes.
---@return nil No value is returned.
LGuiWindow.setOnClose = function(fn) end

--- Sets the resizable for this Gui_Window widget.
---@param v boolean True to make this GUI window resizable.
---@return nil No value is returned.
LGuiWindow.setResizable = function(v) end

--- Sets the title for this Gui_Window widget.
---@param title string Title text to display on this GUI window.
---@return nil No value is returned.
LGuiWindow.setTitle = function(title) end

---@class LImageWidget
LImageWidget = {}

--- Returns the scale mode of this Image_Widget widget.
---@return string Image scale mode string.
LImageWidget.getScaleMode = function() end

--- Returns the tint of this Image_Widget widget.
---@return number Tint red component.
---@return number Tint green component.
---@return number Tint blue component.
---@return number Tint alpha component.
LImageWidget.getTint = function() end

--- Sets the scale mode for this Image_Widget widget.
---@param mode string Image scale mode string.
---@return nil No value is returned.
LImageWidget.setScaleMode = function(mode) end

--- Sets the tint for this Image_Widget widget.
---@param r number Red tint component.
---@param green number Green tint component.
---@param b number Blue tint component.
---@param a? number Optional alpha tint component. Pass nil to use full opacity.
---@return nil No value is returned.
LImageWidget.setTint = function(r, green, b, a) end

---@class LLabel
LLabel = {}

--- Returns the text of this Label widget.
---@return string Text displayed on this label.
LLabel.getText = function() end

--- Sets the text for this Label widget.
---@param text string Text to display on this label.
---@return nil No value is returned.
LLabel.setText = function(text) end

---@class LLayout
LLayout = {}

--- Returns the align of this Layout widget.
---@return string Current cross-axis alignment name.
LLayout.getAlign = function() end

--- Returns the direction of this Layout widget.
---@return string Current layout direction name.
LLayout.getDirection = function() end

--- Returns the justify of this Layout widget.
---@return string Current main-axis justification name.
LLayout.getJustify = function() end

--- Returns the spacing of this Layout widget.
---@return number Current spacing between layout items.
LLayout.getSpacing = function() end

--- Returns the wrap of this Layout widget.
---@return boolean True when layout wrapping is enabled.
LLayout.getWrap = function() end

--- Sets the align for this Layout widget.
---@param align string Cross-axis alignment name to assign.
---@return nil No value is returned.
LLayout.setAlign = function(align) end

--- Sets the columns for this Layout widget.
---@param n integer Column count to assign.
---@return nil No value is returned.
LLayout.setColumns = function(n) end

--- Sets the direction for this Layout widget.
---@param dir string Layout direction name to assign.
---@return nil No value is returned.
LLayout.setDirection = function(dir) end

--- Sets the justify for this Layout widget.
---@param justify string Main-axis justification name to assign.
---@return nil No value is returned.
LLayout.setJustify = function(justify) end

--- Sets the spacing for this Layout widget.
---@param spacing number Spacing between layout items in UI pixels.
---@return nil No value is returned.
LLayout.setSpacing = function(spacing) end

--- Sets the wrap for this Layout widget.
---@param wrap boolean True to wrap layout items.
---@return nil No value is returned.
LLayout.setWrap = function(wrap) end

--- Lua wrapper for a line chart renderer.
---@class LLineChart
LLineChart = {}

--- Adds a named data series to the chart.
---@param name string Series name.
---@param points table Array of `{x, y}` point tables.
---@param r number Red channel from `0` to `1`.
---@param g number Green channel from `0` to `1`.
---@param b number Blue channel from `0` to `1`.
---@return nil No value is returned.
function LLineChart:addSeries(name, points, r, g, b) end

--- Renders the line chart into an existing ImageData.
---@param target ImageData Target image buffer.
---@return nil No value is returned.
function LLineChart:drawToImage(target) end

--- Sets the maximum X value for axis scaling.
---@param v number Maximum X-axis value.
---@return nil No value is returned.
function LLineChart:setXMax(v) end

--- Sets the maximum Y value for axis scaling.
---@param v number Maximum Y-axis value.
---@return nil No value is returned.
function LLineChart:setYMax(v) end

--- Returns the type name of this object.
---@return string The Lua-visible type name.
function LLineChart:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the requested type.
function LLineChart:typeOf(name) end

---@class LListBox
LListBox = {}

--- Adds a item entry to this List_Box widget.
---@param text string Item text to append.
---@return nil No value is returned.
LListBox.addItem = function(text) end

--- Clears all items entries from this List_Box widget.
---@return nil No value is returned.
LListBox.clearItems = function() end

--- Returns the item of this List_Box widget.
---@param index integer 1-based item index to read.
---@return string Item text at the given index, or an empty string when the index is invalid.
LListBox.getItem = function(index) end

--- Returns the item count of this List_Box widget.
---@return integer Number of items in this list box.
LListBox.getItemCount = function() end

--- Returns the selected index of this List_Box widget.
---@return integer Selected 1-based item index, or 0 when nothing is selected.
LListBox.getSelectedIndex = function() end

--- Removes the item from this List_Box widget.
---@param index integer 1-based item index to remove.
---@return nil No value is returned.
LListBox.removeItem = function(index) end

--- Sets the item height for this List_Box widget.
---@param h number Item height in UI pixels.
---@return nil No value is returned.
LListBox.setItemHeight = function(h) end

--- Sets the selected index for this List_Box widget.
---@param index integer 1-based item index to select.
---@return nil No value is returned.
LListBox.setSelectedIndex = function(index) end

---@class LMenuBar
LMenuBar = {}

--- Adds a menu entry to this Menu_Bar widget.
---@param menu_idx integer Widget index of the menu to add.
---@return nil No value is returned.
LMenuBar.addMenu = function(menu_idx) end

--- Returns the menu count of this Menu_Bar widget.
---@return integer Number of menus in this menu bar.
LMenuBar.getMenuCount = function() end

--- Returns the menus of this Menu_Bar widget.
---@return table Array-style table of menu widget indices.
LMenuBar.getMenus = function() end

--- Removes the menu from this Menu_Bar widget.
---@param menu_idx integer Widget index of the menu to remove.
---@return boolean True when a menu was removed.
LMenuBar.removeMenu = function(menu_idx) end

---@class LMenuItem
LMenuItem = {}

--- Adds a sub item entry to this Menu_Item widget.
---@param child_idx integer Widget index of the submenu item to add.
---@return nil No value is returned.
LMenuItem.addSubItem = function(child_idx) end

--- Returns the shortcut of this Menu_Item widget.
---@return string Shortcut text for this menu item.
LMenuItem.getShortcut = function() end

--- Returns the sub items of this Menu_Item widget.
---@return table Array-style table of submenu item widget indices.
LMenuItem.getSubItems = function() end

--- Returns the text of this Menu_Item widget.
---@return string Text displayed by this menu item.
LMenuItem.getText = function() end

--- Returns true if checked is enabled for this Menu_Item widget.
---@return boolean True when this menu item is checked.
LMenuItem.isChecked = function() end

--- Sets the checked for this Menu_Item widget.
---@param v boolean Checked state to assign.
---@return nil No value is returned.
LMenuItem.setChecked = function(v) end

--- Registers a callback invoked when this menu item is clicked.
---@param fn function Callback to run when this menu item is clicked.
---@return nil No value is returned.
LMenuItem.setOnClick = function(fn) end

--- Sets the shortcut for this Menu_Item widget.
---@param shortcut string Shortcut text to assign.
---@return nil No value is returned.
LMenuItem.setShortcut = function(shortcut) end

--- Sets the text for this Menu_Item widget.
---@param text string Text to display for this menu item.
---@return nil No value is returned.
LMenuItem.setText = function(text) end

---@class LNinePatch
LNinePatch = {}

--- Returns the image dimensions of this Nine_Patch widget.
---@return integer Source image width in pixels.
---@return integer Source image height in pixels.
LNinePatch.getImageDimensions = function() end

--- Returns the insets of this Nine_Patch widget.
---@return integer Left inset value.
---@return integer Top inset value.
---@return integer Right inset value.
---@return integer Bottom inset value.
LNinePatch.getInsets = function() end

--- Returns the slices of this Nine_Patch widget.
---@return table Array-style table of computed nine-patch slices. Returns nil when unavailable.
LNinePatch.getSlices = function() end

--- Sets the image dimensions for this Nine_Patch widget.
---@param w integer Source image width in pixels.
---@param h integer Source image height in pixels.
---@return nil No value is returned.
LNinePatch.setImageDimensions = function(w, h) end

--- Sets the insets for this Nine_Patch widget.
---@param left integer Left inset in pixels.
---@param top integer Top inset in pixels.
---@param right integer Right inset in pixels.
---@param bottom integer Bottom inset in pixels.
---@return nil No value is returned.
LNinePatch.setInsets = function(left, top, right, bottom) end

---@class LPanel
LPanel = {}

--- Returns the title of this Panel widget.
---@return string Title text displayed on this panel.
LPanel.getTitle = function() end

--- Sets the scrollable for this Panel widget.
---@param scrollable boolean True to enable scrolling for this panel.
---@return nil No value is returned.
LPanel.setScrollable = function(scrollable) end

--- Sets the title for this Panel widget.
---@param title string Title text to display on this panel.
---@return nil No value is returned.
LPanel.setTitle = function(title) end

--- Lua wrapper for a pie chart renderer.
---@class LPieChart
LPieChart = {}

--- Adds a labelled pie segment.
---@param label string Segment label.
---@param value number Segment value.
---@param r number Red channel from `0` to `1`.
---@param g number Green channel from `0` to `1`.
---@param b number Blue channel from `0` to `1`.
---@return nil No value is returned.
function LPieChart:addSegment(label, value, r, g, b) end

--- Renders the pie chart into an existing ImageData.
---@param target ImageData Target image buffer.
---@return nil No value is returned.
function LPieChart:drawToImage(target) end

--- Returns the type name of this object.
---@return string The Lua-visible type name.
function LPieChart:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the requested type.
function LPieChart:typeOf(name) end

---@class LProgressBar
LProgressBar = {}

--- Returns the max of this Progress_Bar widget.
---@return number Maximum progress value.
LProgressBar.getMax = function() end

--- Returns the min of this Progress_Bar widget.
---@return number Minimum progress value.
LProgressBar.getMin = function() end

--- Returns the progress of this Progress_Bar widget.
---@return number Current normalized progress value.
LProgressBar.getProgress = function() end

--- Returns the value of this Progress_Bar widget.
---@return number Current progress bar value.
LProgressBar.getValue = function() end

--- Sets the range for this Progress_Bar widget.
---@param min number Minimum progress value.
---@param max number Maximum progress value.
---@return nil No value is returned.
LProgressBar.setRange = function(min, max) end

--- Sets the value for this Progress_Bar widget.
---@param v number Value to assign to this progress bar.
---@return nil No value is returned.
LProgressBar.setValue = function(v) end

---@class LRadioButton
LRadioButton = {}

--- Returns the group of this Radio_Button widget.
---@return string Group name for this radio button.
LRadioButton.getGroup = function() end

--- Returns the text of this Radio_Button widget.
---@return string Text displayed next to this radio button.
LRadioButton.getText = function() end

--- Returns true if selected is enabled for this Radio_Button widget.
---@return boolean True when this radio button is selected.
LRadioButton.isSelected = function() end

--- Sets the group for this Radio_Button widget.
---@param group string Group name to assign.
---@return nil No value is returned.
LRadioButton.setGroup = function(group) end

--- Registers a callback invoked when this widget's value changes.
---@param fn function Callback to run when this radio button changes.
---@return nil No value is returned.
LRadioButton.setOnChange = function(fn) end

--- Sets the selected for this Radio_Button widget.
---@param v boolean Selected state to assign.
---@return nil No value is returned.
LRadioButton.setSelected = function(v) end

--- Sets the text for this Radio_Button widget.
---@param text string Text to display next to this radio button.
---@return nil No value is returned.
LRadioButton.setText = function(text) end

--- Lua wrapper for a scatter plot renderer.
---@class LScatterPlot
LScatterPlot = {}

--- Adds a named data series.
---@param name string Series name.
---@param points table Array of `{x, y}` point tables.
---@param r number Red channel from `0` to `1`.
---@param g number Green channel from `0` to `1`.
---@param b number Blue channel from `0` to `1`.
---@return nil No value is returned.
function LScatterPlot:addSeries(name, points, r, g, b) end

--- Renders the scatter plot into an existing ImageData.
---@param target ImageData Target image buffer.
---@return nil No value is returned.
function LScatterPlot:drawToImage(target) end

--- Sets the X-axis data range.
---@param min number Minimum X-axis value.
---@param max number Maximum X-axis value.
---@return nil No value is returned.
function LScatterPlot:setXRange(min, max) end

--- Sets the Y-axis data range.
---@param min number Minimum Y-axis value.
---@param max number Maximum Y-axis value.
---@return nil No value is returned.
function LScatterPlot:setYRange(min, max) end

--- Returns the type name of this object.
---@return string The Lua-visible type name.
function LScatterPlot:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the requested type.
function LScatterPlot:typeOf(name) end

---@class LScrollBar
LScrollBar = {}

--- Returns the content size of this Scroll_Bar widget.
---@return number Scroll bar content size.
LScrollBar.getContentSize = function() end

--- Returns the scroll position of this Scroll_Bar widget.
---@return number Current scroll position.
LScrollBar.getScrollPosition = function() end

--- Returns the view size of this Scroll_Bar widget.
---@return number Scroll bar view size.
LScrollBar.getViewSize = function() end

--- Returns true if vertical is enabled for this Scroll_Bar widget.
---@return boolean True when this scroll bar is vertical.
LScrollBar.isVertical = function() end

--- Sets the content size for this Scroll_Bar widget.
---@param v number Content size to assign.
---@return nil No value is returned.
LScrollBar.setContentSize = function(v) end

--- Registers a callback invoked when this widget's value changes.
---@param fn function Callback to run when the scroll bar value changes.
---@return nil No value is returned.
LScrollBar.setOnChange = function(fn) end

--- Sets the scroll position for this Scroll_Bar widget.
---@param v number Scroll position to assign.
---@return nil No value is returned.
LScrollBar.setScrollPosition = function(v) end

--- Sets the view size for this Scroll_Bar widget.
---@param v number View size to assign.
---@return nil No value is returned.
LScrollBar.setViewSize = function(v) end

---@class LScrollPanel
LScrollPanel = {}

--- Returns the content size of this Scroll_Panel widget.
---@return number Content width in UI pixels.
---@return number Content height in UI pixels.
LScrollPanel.getContentSize = function() end

--- Returns the max scroll of this Scroll_Panel widget.
---@return number Maximum horizontal scroll position.
---@return number Maximum vertical scroll position.
LScrollPanel.getMaxScroll = function() end

--- Returns the scroll position of this Scroll_Panel widget.
---@return number Current horizontal scroll position.
---@return number Current vertical scroll position.
LScrollPanel.getScrollPosition = function() end

--- Returns the scroll speed of this Scroll_Panel widget.
---@return number Current scroll speed.
LScrollPanel.getScrollSpeed = function() end

--- Sets the content size for this Scroll_Panel widget.
---@param w number Content width in UI pixels.
---@param h number Content height in UI pixels.
---@return nil No value is returned.
LScrollPanel.setContentSize = function(w, h) end

--- Sets the scroll position for this Scroll_Panel widget.
---@param x number Horizontal scroll position.
---@param y number Vertical scroll position.
---@return nil No value is returned.
LScrollPanel.setScrollPosition = function(x, y) end

--- Sets the scroll speed for this Scroll_Panel widget.
---@param speed number Scroll speed to assign.
---@return nil No value is returned.
LScrollPanel.setScrollSpeed = function(speed) end

---@class LSeparator
LSeparator = {}

--- Returns the thickness of this Separator widget.
---@return number Current separator thickness.
LSeparator.getThickness = function() end

--- Returns true if vertical is enabled for this Separator widget.
---@return boolean True when this separator is vertical.
LSeparator.isVertical = function() end

--- Sets the thickness for this Separator widget.
---@param thickness number Separator thickness in UI pixels.
---@return nil No value is returned.
LSeparator.setThickness = function(thickness) end

--- Sets the vertical for this Separator widget.
---@param v boolean True to make the separator vertical.
---@return nil No value is returned.
LSeparator.setVertical = function(v) end

---@class LSlider
LSlider = {}

--- Returns the max of this Slider widget.
---@return number Maximum slider value.
LSlider.getMax = function() end

--- Returns the min of this Slider widget.
---@return number Minimum slider value.
LSlider.getMin = function() end

--- Returns the value of this Slider widget.
---@return number Current slider value.
LSlider.getValue = function() end

--- Sets the range for this Slider widget.
---@param min number Minimum slider value.
---@param max number Maximum slider value.
---@return nil No value is returned.
LSlider.setRange = function(min, max) end

--- Sets the step for this Slider widget.
---@param step number Step size for slider changes.
---@return nil No value is returned.
LSlider.setStep = function(step) end

--- Sets the value for this Slider widget.
---@param v number Value to assign to this slider.
---@return nil No value is returned.
LSlider.setValue = function(v) end

---@class LSpinBox
LSpinBox = {}

--- Decrements the value by one step.
---@return nil No value is returned.
LSpinBox.decrement = function() end

--- Returns the current value of this SpinBox widget.
---@return number Current spin box value.
LSpinBox.getValue = function() end

--- Increments the value by one step.
---@return nil No value is returned.
LSpinBox.increment = function() end

--- Sets the valid range for this SpinBox widget.
---@param min number Minimum spin box value.
---@param max number Maximum spin box value.
---@return nil No value is returned.
LSpinBox.setRange = function(min, max) end

--- Sets the increment step for this SpinBox widget.
---@param step number Increment step size.
---@return nil No value is returned.
LSpinBox.setStep = function(step) end

--- Sets the value for this SpinBox widget.
---@param v number Value to assign to this spin box.
---@return nil No value is returned.
LSpinBox.setValue = function(v) end

---@class LSplitPanel
LSplitPanel = {}

--- Returns the first child of this Split_Panel widget.
---@return integer First child widget index. Returns nil when no first child is set.
LSplitPanel.getFirstChild = function() end

--- Returns the min panel size of this Split_Panel widget.
---@return number Minimum panel size.
LSplitPanel.getMinPanelSize = function() end

--- Returns the orientation of this Split_Panel widget.
---@return string Current split orientation.
LSplitPanel.getOrientation = function() end

--- Returns the second child of this Split_Panel widget.
---@return integer Second child widget index. Returns nil when no second child is set.
LSplitPanel.getSecondChild = function() end

--- Returns the split position of this Split_Panel widget.
---@return number Current split position.
LSplitPanel.getSplitPosition = function() end

--- Sets the first child for this Split_Panel widget.
---@param child_idx integer Widget index to use as the first child.
---@return nil No value is returned.
LSplitPanel.setFirstChild = function(child_idx) end

--- Sets the min panel size for this Split_Panel widget.
---@param v number Minimum panel size to assign.
---@return nil No value is returned.
LSplitPanel.setMinPanelSize = function(v) end

--- Sets the orientation for this Split_Panel widget.
---@param v string Split orientation to assign.
---@return nil No value is returned.
LSplitPanel.setOrientation = function(v) end

--- Sets the second child for this Split_Panel widget.
---@param child_idx integer Widget index to use as the second child.
---@return nil No value is returned.
LSplitPanel.setSecondChild = function(child_idx) end

--- Sets the split position for this Split_Panel widget.
---@param v number Split position to assign.
---@return nil No value is returned.
LSplitPanel.setSplitPosition = function(v) end

---@class LStatusBar
LStatusBar = {}

--- Adds a section entry to this Status_Bar widget.
---@param text string Section text to add.
---@param width? number Optional section width in UI pixels.
---@return nil No value is returned.
LStatusBar.addSection = function(text, width) end

--- Returns the section count of this Status_Bar widget.
---@return integer Number of sections in this status bar.
LStatusBar.getSectionCount = function() end

--- Returns the section text of this Status_Bar widget.
---@param section_idx integer 1-based section index to read.
---@return string Section text at the given index. Returns nil when the index is invalid.
LStatusBar.getSectionText = function(section_idx) end

--- Resizes the section list for this Status_Bar widget.
---@param count integer Desired number of sections.
---@return nil No value is returned.
LStatusBar.setSectionCount = function(count) end

--- Sets the section text for this Status_Bar widget.
---@param section_idx integer 1-based section index to update.
---@param text string New section text.
---@return nil No value is returned.
LStatusBar.setSectionText = function(section_idx, text) end

--- Compatibility shim for assigning a widget to a section.
---@param section_idx integer 1-based section index to target.
---@param widget table integer | Widget table or widget index accepted by this compatibility shim.
---@return nil No value is returned.
LStatusBar.setSectionWidget = function(section_idx, widget) end

---@class LSwitch
LSwitch = {}

--- Returns the on/off state of this Switch widget.
---@return boolean True when this switch is on.
LSwitch.isOn = function() end

--- Sets the on/off state of this Switch widget.
---@param on boolean On/off state to assign.
---@return nil No value is returned.
LSwitch.setOn = function(on) end

--- Toggles the on/off state of this Switch widget.
---@return nil No value is returned.
LSwitch.toggle = function() end

---@class LTabBar
LTabBar = {}

--- Adds a tab entry to this Tab_Bar widget.
---@param label string Tab label to append.
---@return nil No value is returned.
LTabBar.addTab = function(label) end

--- Returns the active tab of this Tab_Bar widget.
---@return integer Active 1-based tab index, or 0 when unavailable.
LTabBar.getActiveTab = function() end

--- Returns the tab of this Tab_Bar widget.
---@param index integer 1-based tab index to read.
---@return string Tab label at the given index. Returns nil when the index is invalid.
LTabBar.getTab = function(index) end

--- Returns the tab count of this Tab_Bar widget.
---@return integer Number of tabs in this tab bar.
LTabBar.getTabCount = function() end

--- Removes the tab from this Tab_Bar widget.
---@param index integer 1-based tab index to remove.
---@return boolean True when a tab was removed.
LTabBar.removeTab = function(index) end

--- Sets the active tab for this Tab_Bar widget.
---@param index integer 1-based tab index to activate.
---@return nil No value is returned.
LTabBar.setActiveTab = function(index) end

---@class LTextInput
LTextInput = {}

--- Returns the cursor position of this Text_Input widget.
---@return integer Current cursor position in this text input.
LTextInput.getCursorPosition = function() end

--- Returns the placeholder of this Text_Input widget.
---@return string Placeholder text for this text input.
LTextInput.getPlaceholder = function() end

--- Returns the text of this Text_Input widget.
---@return string Text stored in this text input.
LTextInput.getText = function() end

--- Returns true if focused is enabled for this Text_Input widget.
---@return boolean True when this text input is focused.
LTextInput.isFocused = function() end

--- Sets the max length for this Text_Input widget.
---@param n integer Maximum number of characters allowed.
---@return nil No value is returned.
LTextInput.setMaxLength = function(n) end

--- Sets the placeholder for this Text_Input widget.
---@param text string Placeholder text to display when the input is empty.
---@return nil No value is returned.
LTextInput.setPlaceholder = function(text) end

--- Sets the text for this Text_Input widget.
---@param text string Text to store in this text input.
---@return nil No value is returned.
LTextInput.setText = function(text) end

--- Lua-side wrapper around a GUI [`Theme`].
---@class LTheme
LTheme = {}

--- Sets a style for a (widget_type, state) pair.
---@param widgetType string Widget type name.
---@param state string Widget state name.
---@param style table Style table to apply.
---@return nil No value is returned.
function LTheme:setStyle(widgetType, state, style) end

--- Returns the type name of this object.
---@return string The Lua-visible type name.
function LTheme:type() end

--- Returns true if this object is of the given type.
---@param name string Type name to test.
---@return boolean True if this object matches the requested type.
function LTheme:typeOf(name) end

---@class LToast
LToast = {}

--- Returns the duration of this Toast widget.
---@return number Configured toast duration in seconds.
LToast.getDuration = function() end

--- Returns the message of this Toast widget.
---@return string Message text displayed by this toast.
LToast.getMessage = function() end

--- Returns the progress of this Toast widget.
---@return number Current toast progress value.
LToast.getProgress = function() end

--- Returns true if expired is enabled for this Toast widget.
---@return boolean True when this toast has expired.
LToast.isExpired = function() end

--- Sets the duration for this Toast widget.
---@param d number Duration in seconds.
---@return nil No value is returned.
LToast.setDuration = function(d) end

--- Sets the message for this Toast widget.
---@param msg string Message text to display.
---@return nil No value is returned.
LToast.setMessage = function(msg) end

---@class LToolbar
LToolbar = {}

--- Adds a button entry to this Toolbar widget.
---@param id string Button identifier to add.
---@param tooltip? string Optional tooltip text for the button.
---@return integer 1-based index of the added button, or 0 when unavailable.
LToolbar.addButton = function(id, tooltip) end

--- Adds a separator entry to this Toolbar widget.
---@return nil No value is returned.
LToolbar.addSeparator = function() end

--- Adds a spacer entry to this Toolbar widget.
---@param size? number Optional spacer size in UI pixels.
---@return nil No value is returned.
LToolbar.addSpacer = function(size) end

--- Returns the button of this Toolbar widget.
---@param id string Button identifier to look up.
---@return table Toolbar button data table. Returns nil when the button is not found.
LToolbar.getButton = function(id) end

--- Returns the orientation of this Toolbar widget.
---@return string Current toolbar orientation.
LToolbar.getOrientation = function() end

--- Returns true if button toggled is enabled for this Toolbar widget.
---@param id string Button identifier to inspect.
---@return boolean Toggled state for the button. Returns nil when the button is not found.
LToolbar.isButtonToggled = function(id) end

--- Sets the button enabled for this Toolbar widget.
---@param id string Button identifier to update.
---@param enabled boolean True to enable the button.
---@return boolean True when the button state was updated.
LToolbar.setButtonEnabled = function(id, enabled) end

--- Sets the button toggled for this Toolbar widget.
---@param id string Button identifier to update.
---@param toggled boolean Toggled state to assign.
---@return boolean True when the button state was updated.
LToolbar.setButtonToggled = function(id, toggled) end

--- Sets the orientation for this Toolbar widget.
---@param v string Toolbar orientation to assign.
---@return nil No value is returned.
LToolbar.setOrientation = function(v) end

---@class LTooltipPanel
LTooltipPanel = {}

--- Returns the delay of this Tooltip_Panel widget.
---@return number Tooltip delay in seconds.
LTooltipPanel.getDelay = function() end

--- Returns the target of this Tooltip_Panel widget.
---@return integer Target widget index. Returns nil if no target is set.
LTooltipPanel.getTarget = function() end

--- Returns the text of this Tooltip_Panel widget.
---@return string Tooltip text.
LTooltipPanel.getText = function() end

--- Sets the delay for this Tooltip_Panel widget.
---@param v number Tooltip delay in seconds.
---@return nil No value is returned.
LTooltipPanel.setDelay = function(v) end

--- Sets the target for this Tooltip_Panel widget.
---@param target? integer Target widget index. Pass nil to clear the target.
---@return nil No value is returned.
LTooltipPanel.setTarget = function(target) end

--- Sets the text for this Tooltip_Panel widget.
---@param text string Tooltip text.
---@return nil No value is returned.
LTooltipPanel.setText = function(text) end

---@class LTreeView
LTreeView = {}

--- Adds a node entry to this Tree_View widget.
---@param text string Node text to add.
---@param parent_index? integer Optional 1-based parent node index.
---@return integer 1-based index of the added node, or 0 when unavailable.
LTreeView.addNode = function(text, parent_index) end

--- Clears all nodes entries from this Tree_View widget.
---@return nil No value is returned.
LTreeView.clearNodes = function() end

--- Performs the collapse all operation on this Tree_View widget.
---@return nil No value is returned.
LTreeView.collapseAll = function() end

--- Performs the collapse node operation on this Tree_View widget.
---@param index integer 1-based node index to collapse.
---@return boolean True when the node was collapsed.
LTreeView.collapseNode = function(index) end

--- Performs the expand all operation on this Tree_View widget.
---@return nil No value is returned.
LTreeView.expandAll = function() end

--- Performs the expand node operation on this Tree_View widget.
---@param index integer 1-based node index to expand.
---@return boolean True when the node was expanded.
LTreeView.expandNode = function(index) end

--- Returns the child nodes of this Tree_View widget.
---@param index integer 1-based node index to inspect.
---@return table Array-style table of 1-based child node indices.
LTreeView.getChildNodes = function(index) end

--- Returns the node count of this Tree_View widget.
---@return integer Number of nodes in this tree view.
LTreeView.getNodeCount = function() end

--- Returns the node depth of this Tree_View widget.
---@param index integer 1-based node index to inspect.
---@return integer Node depth. Returns nil when the index is invalid.
LTreeView.getNodeDepth = function(index) end

--- Returns the node text of this Tree_View widget.
---@param index integer 1-based node index to read.
---@return string Node text at the given index. Returns nil when the index is invalid.
LTreeView.getNodeText = function(index) end

--- Returns the parent node of this Tree_View widget.
---@param index integer 1-based node index to inspect.
---@return integer 1-based parent node index. Returns nil when no parent exists.
LTreeView.getParentNode = function(index) end

--- Returns the selected node of this Tree_View widget.
---@return integer Selected 1-based node index. Returns nil when no node is selected.
LTreeView.getSelectedNode = function() end

--- Returns true if expanded is enabled for this Tree_View widget.
---@param index integer 1-based node index to inspect.
---@return boolean True when the node is expanded.
LTreeView.isExpanded = function(index) end

--- Returns true if node expanded is enabled for this Tree_View widget.
---@param index integer 1-based node index to inspect.
---@return boolean True when the node is expanded. Returns nil when the index is invalid.
LTreeView.isNodeExpanded = function(index) end

--- Removes the node from this Tree_View widget.
---@param index integer 1-based node index to remove.
---@return boolean True when a node was removed.
LTreeView.removeNode = function(index) end

--- Sets the node icon for this Tree_View widget.
---@param index integer 1-based node index to update.
---@param icon string Icon identifier to assign.
---@return boolean True when the node icon was updated.
LTreeView.setNodeIcon = function(index, icon) end

--- Sets the node text for this Tree_View widget.
---@param index integer 1-based node index to update.
---@param text string New node text.
---@return boolean True when the node text was updated.
LTreeView.setNodeText = function(index, text) end

--- Sets the selected node for this Tree_View widget.
---@param index integer 1-based node index to select.
---@return boolean True when the selected node changed.
LTreeView.setSelectedNode = function(index) end

--- Toggles the expanded/collapsed status of a Tree_View node.
---@param index integer 1-based node index to toggle.
---@return boolean True when the node ends in the expanded state.
LTreeView.toggleNode = function(index) end

---@class LUiWidget
LUiWidget = {}

--- Adds a child widget to this container.
---@param child table integer | Child widget table or widget index to attach.
---@return nil No value is returned.
LUiWidget.addChild = function(child) end

--- Anchors this widget to a world-space entity by its numeric ID.
---@param entity_id integer Numeric entity ID to anchor this widget to.
---@return nil No value is returned.
LUiWidget.attachToEntity = function(entity_id) end

--- Registers a data-binding key on this widget.
---@param key string Data key to observe when bindings are updated.
---@return nil No value is returned.
LUiWidget.bind = function(key) end

--- Removes all anchor constraints.
---@return nil No value is returned.
LUiWidget.clearAnchor = function() end

--- Returns whether (x, y) is inside this widget.
---@param x number X coordinate to test.
---@param y number Y coordinate to test.
---@return boolean True when the point is inside the widget.
LUiWidget.containsPoint = function(x, y) end

--- Removes the entity anchor from this widget, restoring normal layout positioning.
---@return nil No value is returned.
LUiWidget.detachFromEntity = function() end

--- Instantly fades the widget in (sets alpha to `1.0`).
---@return nil No value is returned.
LUiWidget.fadeIn = function() end

--- Instantly fades the widget out (sets alpha to `0.0` and hides it).
---@return nil No value is returned.
LUiWidget.fadeOut = function() end

--- Recursively searches for a widget by id starting from this widget.
---@param id string Widget identifier to search for.
---@return table Matching widget handle table. Returns nil when no widget matches.
LUiWidget.findById = function(id) end

--- Returns the widget's current alpha transparency.
---@return number Current widget alpha transparency.
LUiWidget.getAlpha = function() end

--- Returns the number of children in this container.
---@return integer Number of child widgets in this container.
LUiWidget.getChildCount = function() end

--- Returns this container's children as widget-handle tables.
---@return table Array-style table of child widget handles.
LUiWidget.getChildren = function() end

--- Returns the flex-grow factor.
---@return number Current flex-grow factor.
LUiWidget.getFlexGrow = function() end

--- Returns the flex-shrink factor.
---@return number Current flex-shrink factor.
LUiWidget.getFlexShrink = function() end

--- Returns the widget string identifier.
---@return string Widget string identifier.
LUiWidget.getId = function() end

--- Returns the widget margin (top, right, bottom, left).
---@return number Top margin value.
---@return number Right margin value.
---@return number Bottom margin value.
---@return number Left margin value.
LUiWidget.getMargin = function() end

--- Returns the maximum widget size.
---@return number Maximum width in UI pixels.
---@return number Maximum height in UI pixels.
LUiWidget.getMaxSize = function() end

--- Returns the minimum widget size.
---@return number Minimum width in UI pixels.
---@return number Minimum height in UI pixels.
LUiWidget.getMinSize = function() end

--- Returns the widget padding (top, right, bottom, left).
---@return number Top padding value.
---@return number Right padding value.
---@return number Bottom padding value.
---@return number Left padding value.
LUiWidget.getPadding = function() end

--- Returns the widget position.
---@return number Widget X position in UI pixels.
---@return number Widget Y position in UI pixels.
LUiWidget.getPosition = function() end

--- Returns the computed screen-space rectangle after layout.
---@return number Computed X position after layout.
---@return number Computed Y position after layout.
---@return number Computed width after layout.
---@return number Computed height after layout.
LUiWidget.getRect = function() end

--- Returns the current width and height of the widget in UI pixels.
---@return number Current width in UI pixels.
---@return number Current height in UI pixels.
LUiWidget.getSize = function() end

--- Returns the widget interaction state name.
---@return string Current widget interaction state name.
LUiWidget.getState = function() end

--- Returns the widget tooltip text.
---@return string Tooltip text stored on the widget.
LUiWidget.getTooltip = function() end

--- Returns the widget z-order.
---@return integer Current widget z-order value.
LUiWidget.getZOrder = function() end

--- Returns whether the widget is enabled.
---@return boolean True when the widget is enabled.
LUiWidget.isEnabled = function() end

--- Returns whether the widget is visible.
---@return boolean True when the widget is visible.
LUiWidget.isVisible = function() end

--- Removes a child widget from this container.
---@param child table integer | Child widget table or widget index to detach.
---@return nil No value is returned.
LUiWidget.removeChild = function(child) end

--- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
---@param alpha number Alpha transparency value to assign.
---@return nil No value is returned.
LUiWidget.setAlpha = function(alpha) end

--- Sets anchor edges (left, top, right, bottom).
---@param left? number Left anchor value.
---@param top? number Top anchor value.
---@param right? number Right anchor value.
---@param bottom? number Bottom anchor value.
---@return nil No value is returned.
LUiWidget.setAnchor = function(left, top, right, bottom) end

--- Sets center anchor offsets.
---@param cx? number Horizontal center anchor offset.
---@param cy? number Vertical center anchor offset.
---@return nil No value is returned.
LUiWidget.setAnchorCenter = function(cx, cy) end

--- Sets whether the widget is enabled.
---@param enabled boolean True to enable the widget, false to disable it.
---@return nil No value is returned.
LUiWidget.setEnabled = function(enabled) end

--- Sets the flex-grow factor.
---@param grow number Flex-grow factor to assign.
---@return nil No value is returned.
LUiWidget.setFlexGrow = function(grow) end

--- Sets the flex-shrink factor.
---@param shrink number Flex-shrink factor to assign.
---@return nil No value is returned.
LUiWidget.setFlexShrink = function(shrink) end

--- Sets the widget string identifier.
---@param id string String identifier to assign to the widget.
---@return nil No value is returned.
LUiWidget.setId = function(id) end

--- Sets widget margin (CSS-like: top, right?, bottom?, left?).
---@param top number Top margin value.
---@param right? number Right margin value, or nil to reuse top.
---@param bottom? number Bottom margin value, or nil to reuse top.
---@param left? number Left margin value, or nil to reuse the resolved right value.
---@return nil No value is returned.
LUiWidget.setMargin = function(top, right, bottom, left) end

--- Sets the maximum widget size.
---@param w number Maximum width in UI pixels.
---@param h number Maximum height in UI pixels.
---@return nil No value is returned.
LUiWidget.setMaxSize = function(w, h) end

--- Sets the minimum widget size.
---@param w number Minimum width in UI pixels.
---@param h number Minimum height in UI pixels.
---@return nil No value is returned.
LUiWidget.setMinSize = function(w, h) end

--- Registers a callback invoked when this widget's value changes.
---@param fn function Callback to run when this widget value changes.
---@return nil No value is returned.
LUiWidget.setOnChange = function(fn) end

--- Registers a callback invoked when this widget is clicked.
---@param fn function Callback to run when this widget is clicked.
---@return nil No value is returned.
LUiWidget.setOnClick = function(fn) end

--- Stores a custom draw callback for later invocation.
---@param fn function Callback to store for custom drawing.
---@param f LuaValue
---@return nil No value is returned.
LUiWidget.setOnDraw = function(fn, f) end

--- Sets widget padding (CSS-like: top, right?, bottom?, left?).
---@param top number Top padding value.
---@param right? number Right padding value, or nil to reuse top.
---@param bottom? number Bottom padding value, or nil to reuse top.
---@param left? number Left padding value, or nil to reuse the resolved right value.
---@return nil No value is returned.
LUiWidget.setPadding = function(top, right, bottom, left) end

--- Sets the widget position.
---@param x number X position in UI pixels.
---@param y number Y position in UI pixels.
---@return nil No value is returned.
LUiWidget.setPosition = function(x, y) end

--- Sets the width and height of the widget in UI pixels.
---@param w number Width in UI pixels.
---@param h number Height in UI pixels.
---@return nil No value is returned.
LUiWidget.setSize = function(w, h) end

--- Sets the widget tooltip text.
---@param text string Tooltip text to store on the widget.
---@return nil No value is returned.
LUiWidget.setTooltip = function(text) end

--- Shows or hides the widget; hidden widgets are not rendered or interactive.
---@param visible boolean True to show the widget, false to hide it.
---@return nil No value is returned.
LUiWidget.setVisible = function(visible) end

--- Sets the widget z-order for draw sorting.
---@param z integer Z-order value used for draw sorting.
---@return nil No value is returned.
LUiWidget.setZOrder = function(z) end

--- Instantly moves the widget to `(x, y)` and makes it visible.
---@param x number Target X position.
---@param y number Target Y position.
---@return nil No value is returned.
LUiWidget.slideIn = function(x, y) end

--- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
---@param x number Off-screen X position.
---@param y number Off-screen Y position.
---@return nil No value is returned.
LUiWidget.slideOut = function(x, y) end

--- Returns the Lua type name of this widget (e.g. "LButton").
---@return string Lua-visible type name for this widget.
LUiWidget.type = function() end

--- Returns true if this widget is of the given type, "LWidget", or "Object".
---@param name string Type name to compare against.
---@return boolean True when the given type name matches this widget.
LUiWidget.typeOf = function(name) end

--- Removes the data-binding key from this widget.
---@return nil No value is returned.
LUiWidget.unbind = function() end

--- Queues a toast notification from a table.
---@param toast table Toast definition table with `message` and optional `duration`.
---@return nil No value is returned.
lurek.ui.addToast = function(toast) end

--- Removes keyboard focus from this widget so key events go to the next focusable.
---@return nil No value is returned.
lurek.ui.clearFocus = function() end

--- Invokes all registered `on_draw` callbacks with a screen-space rect table.
---@return nil No value is returned.
lurek.ui.draw = function() end

--- Renders the UI widget tree to a CPU ImageData at the given resolution.
---@param w integer Output image width in pixels.
---@param h integer Output image height in pixels.
---@return ImageData Rendered UI image.
lurek.ui.drawToImage = function(w, h) end

--- Returns true if the widget tree changed since the last call, then resets the flag.
---@return boolean True if the widget tree changed since the last flush.
lurek.ui.flushCache = function() end

--- Moves focus to the next focusable widget.
---@return nil No value is returned.
lurek.ui.focusNext = function() end

--- Moves focus to the previous focusable widget.
---@return nil No value is returned.
lurek.ui.focusPrev = function() end

--- Returns the focused widget index or nil.
---@return number Focused widget index. Returns nil if no widget has focus.
lurek.ui.getFocus = function() end

--- Returns the root panel widget table.
---@return LPanel Root panel widget.
lurek.ui.getRoot = function() end

--- Returns whether a theme is set.
---@return boolean True if an active theme is set.
lurek.ui.getTheme = function() end

--- Returns the number of active toasts.
---@return number Number of active toasts.
lurek.ui.getToastCount = function() end

--- Returns the total widget count in the context.
---@return number Total widget count.
lurek.ui.getWidgetCount = function() end

--- Forwards a key press event to the GUI.
---@param key string Key name.
---@return boolean True if the GUI consumed the event.
lurek.ui.keypressed = function(key) end

--- Loads a widget tree from a Lua definition table and attaches it to the UI root.
---@param def table Root widget definition table with a required `type` field and optional `children` array.
---@return number Pool index of the created root widget.
lurek.ui.loadLayout = function(def) end

--- Loads a widget tree from a TOML layout file and attaches it to the UI root.
---@param path string Path to a TOML layout file with a `[root]` widget definition.
---@return number Pool index of the created root widget.
lurek.ui.loadLayoutFile = function(path) end

--- Forwards a mouse move event to the GUI.
---@param x number Mouse x position.
---@param y number Mouse y position.
---@return boolean True if the GUI consumed the event.
lurek.ui.mousemoved = function(x, y) end

--- Forwards a mouse press event to the GUI.
---@param x number Mouse x position.
---@param y number Mouse y position.
---@param button? number Mouse button number. Pass nil to use button `1`.
---@return boolean True if the GUI consumed the event.
lurek.ui.mousepressed = function(x, y, button) end

--- Forwards a mouse release event to the GUI.
---@param x number Mouse x position.
---@param y number Mouse y position.
---@param button? number Mouse button number. Pass nil to use button `1`.
---@return boolean True if the GUI consumed the event.
lurek.ui.mousereleased = function(x, y, button) end

--- Creates a collapsible accordion widget.
---@return LAccordion New accordion widget.
lurek.ui.newAccordion = function() end

--- Creates a new stacked-area chart.
---@param opts table Chart config table with optional `width`, `height`, and `title` fields.
---@return LAreaChart New area chart object.
lurek.ui.newAreaChart = function(opts) end

--- Creates a badge widget displaying a numeric count.
---@param count? integer Optional badge count. Pass nil to use `0`.
---@return LBadge New badge widget.
lurek.ui.newBadge = function(count) end

--- Creates and returns a new bar chart widget attached to this image widget.
---@param opts table Chart config table with optional `width`, `height`, and `title` fields.
---@return LBarChart New bar chart object.
lurek.ui.newBarChart = function(opts) end

--- Creates and returns a new interactive button widget as a child of this widget.
---@param text? string Optional button text. Pass nil for an empty label.
---@return LButton New button widget.
lurek.ui.newButton = function(text) end

--- Creates a checkbox widget.
---@param text? string Optional checkbox label text. Pass nil for an empty label.
---@return LCheckbox New checkbox widget.
lurek.ui.newCheckbox = function(text) end

--- Creates a color picker widget.
---@return LColorPicker New color picker widget.
lurek.ui.newColorPicker = function() end

--- Creates a dropdown combo box widget.
---@return LComboBox New combo box widget.
lurek.ui.newComboBox = function() end

--- Creates a new widget with custom Lua-driven rendering.
---@param config? table Optional widget config table with fields like `id`, `x`, `y`, `width`, `height`, `visible`, and `enabled`.
---@return LWidget New custom widget.
lurek.ui.newCustomWidget = function(config) end

--- Creates a modal dialog widget.
---@param title? string Optional dialog title. Pass nil for an empty title.
---@return LDialog New dialog widget.
lurek.ui.newDialog = function(title) end

--- Creates and returns a new docking panel that arranges children along its edges.
---@return LDockPanel New dock panel widget.
lurek.ui.newDockPanel = function() end

--- Creates an image display widget.
---@return LImageWidget New image widget.
lurek.ui.newImageWidget = function() end

--- Creates a text label widget.
---@param text? string Optional label text. Pass nil for an empty label.
---@return LLabel New label widget.
lurek.ui.newLabel = function(text) end

--- Creates a flexbox layout container.
---@param direction? string Optional layout direction string. Pass nil to use `vertical`.
---@return LLayout New layout widget.
lurek.ui.newLayout = function(direction) end

--- Creates a new line chart.
---@param opts table Chart config table with optional `width`, `height`, and `title` fields.
---@return LLineChart New line chart object.
lurek.ui.newLineChart = function(opts) end

--- Creates a selectable list widget.
---@return LListBox New list widget.
lurek.ui.newList = function() end

--- Creates a menu bar widget.
---@return LMenuBar New menu bar widget.
lurek.ui.newMenuBar = function() end

--- Creates a menu item widget.
---@param text? string Optional menu item text. Pass nil for an empty label.
---@return LMenuItem New menu item widget.
lurek.ui.newMenuItem = function(text) end

--- Creates a 9-patch slicer widget.
---@return LNinePatch New nine-patch widget.
lurek.ui.newNinePatch = function() end

--- Creates a container panel widget.
---@return LPanel New panel widget.
lurek.ui.newPanel = function() end

--- Creates and returns a new pie chart widget attached to this image widget.
---@param opts table Chart config table with optional `width`, `height`, and `title` fields.
---@return LPieChart New pie chart object.
lurek.ui.newPieChart = function(opts) end

--- Creates a progress bar widget.
---@param min? number Optional minimum value. Pass nil to use `0.0`.
---@param max? number Optional maximum value. Pass nil to use `100.0`.
---@return LProgressBar New progress bar widget.
lurek.ui.newProgressBar = function(min, max) end

--- Creates a grouped radio button widget.
---@param text? string Optional radio button label text. Pass nil for an empty label.
---@param group? string Optional radio group name. Pass nil for an empty group.
---@return LRadioButton New radio button widget.
lurek.ui.newRadioButton = function(text, group) end

--- Creates a new scatter plot.
---@param opts table Chart config table with optional `width`, `height`, and `title` fields.
---@return LScatterPlot New scatter plot object.
lurek.ui.newScatterPlot = function(opts) end

--- Creates a scroll bar widget.
---@param vertical? boolean True for a vertical scrollbar. Pass nil to use the default vertical mode.
---@return LScrollBar New scrollbar widget.
lurek.ui.newScrollBar = function(vertical) end

--- Creates a scrollable panel widget.
---@return LScrollPanel New scroll panel widget.
lurek.ui.newScrollPanel = function() end

--- Creates a separator line.
---@param vertical? boolean True for a vertical separator. Pass nil for a horizontal separator.
---@return LSeparator New separator widget.
lurek.ui.newSeparator = function(vertical) end

--- Creates a value slider widget.
---@param min? number Optional minimum value. Pass nil to use `0.0`.
---@param max? number Optional maximum value. Pass nil to use `100.0`.
---@return LSlider New slider widget.
lurek.ui.newSlider = function(min, max) end

--- Creates a spacing filler widget.
---@param w? number Optional spacer width. Pass nil to use `0.0`.
---@param h? number Optional spacer height. Pass nil to use `0.0`.
---@return LSpacer New spacer widget.
lurek.ui.newSpacer = function(w, h) end

--- Creates a numeric spin box widget with increment and decrement buttons.
---@param min? number Optional minimum value. Pass nil to use `0.0`.
---@param max? number Optional maximum value. Pass nil to use `100.0`.
---@return LSpinBox New spin box widget.
lurek.ui.newSpinBox = function(min, max) end

--- Creates a resizable split panel.
---@param orientation? string Optional split orientation. Pass nil to use `horizontal`.
---@return LSplitPanel New split panel widget.
lurek.ui.newSplitPanel = function(orientation) end

--- Creates a status bar widget.
---@return LStatusBar New status bar widget.
lurek.ui.newStatusBar = function() end

--- Creates a toggle switch widget.
---@param on? boolean Optional initial state. Pass nil to start off.
---@return LSwitch New switch widget.
lurek.ui.newSwitch = function(on) end

--- Creates a tab bar widget.
---@return LTabBar New tab bar widget.
lurek.ui.newTabBar = function() end

--- Creates a data table widget.
---@return LGuiTable New data table widget.
lurek.ui.newTable = function() end

--- Creates a text input widget.
---@return LTextInput New text input widget.
lurek.ui.newTextInput = function() end

--- Creates a new theme instance.
---@return LTheme New theme object.
lurek.ui.newTheme = function() end

--- Creates a toast notification widget.
---@param message? string Optional toast message. Pass nil for an empty message.
---@param duration? number Optional toast duration in seconds. Pass nil to use `3.0`.
---@return LToast New toast widget.
lurek.ui.newToast = function(message, duration) end

--- Creates a toolbar widget.
---@param orientation? string Optional toolbar orientation. Pass nil to use `horizontal`.
---@return LToolbar New toolbar widget.
lurek.ui.newToolbar = function(orientation) end

--- Creates a tooltip panel widget.
---@param text? string Optional tooltip text. Pass nil for an empty tooltip.
---@return LTooltipPanel New tooltip panel widget.
lurek.ui.newTooltipPanel = function(text) end

--- Creates a collapsible tree view widget.
---@return LTreeView New tree view widget.
lurek.ui.newTreeView = function() end

--- Creates a draggable window widget.
---@param title? string Optional window title. Pass nil for an empty title.
---@return LGuiWindow New window widget.
lurek.ui.newWindow = function(title) end

--- Parses a widget state string and returns its canonical form.
---@param state string Widget state string such as `normal`, `hovered`, `pressed`, `disabled`, or `focused`.
---@return string Canonical widget state string. Returns nil if the input is invalid.
lurek.ui.parseWidgetState = function(state) end

--- Renders the current UI widget tree to a PNG file for testing.
---@param width number Output image width in pixels.
---@param height number Output image height in pixels.
---@param path string Output PNG file path.
---@return nil No value is returned.
lurek.ui.renderToImage = function(width, height, path) end

--- Installs the built-in dark theme as the active GUI theme.
---@return nil No value is returned.
lurek.ui.setDefaultTheme = function() end

--- Sets keyboard focus to a widget or clears it.
---@param widget? table Widget table to focus. Pass nil to clear focus.
---@return nil No value is returned.
lurek.ui.setFocus = function(widget) end

--- Sets the active GUI theme.
---@param theme LTheme Theme object to install.
---@return nil No value is returned.
lurek.ui.setTheme = function(theme) end

--- Sets the viewport dimensions used for anchor constraints and layout.
---@param w number Viewport width.
---@param h number Viewport height.
---@return nil No value is returned.
lurek.ui.setViewport = function(w, h) end

--- Forwards text input to the focused text input widget.
---@param text string Input text.
---@return boolean True if the GUI consumed the event.
lurek.ui.textinput = function(text) end

--- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
---@param dt number Frame delta time in seconds.
---@return nil No value is returned.
lurek.ui.update = function(dt) end

--- Updates widgets whose bound keys match values in the provided data table.
---@param data table Binding values keyed by widget binding name.
---@return nil No value is returned.
lurek.ui.update_bindings = function(data) end

--- Forwards a mouse wheel event to the GUI.
---@param x number Horizontal wheel delta.
---@param y number Vertical wheel delta.
---@return boolean True if the GUI consumed the event.
lurek.ui.wheelmoved = function(x, y) end

---@class lurek.window
lurek.window = {}

--- Requests the window to close, which will end the game loop after the current frame finishes.
---@return nil No return value.
lurek.window.close = function() end

--- Requests the window manager to bring the window to the foreground.
---@return nil No value is returned.
lurek.window.focus = function() end

--- Converts a physical pixel value back to device-independent (logical) coordinates using the current DPI scale factor.
---@param value number The physical pixel value to convert
---@return number The corresponding logical coordinate value
lurek.window.fromPixels = function(value) end

--- Returns the current DPI scaling factor for the window as a number.
---@return number The DPI scale factor (1.0 = standard density)
lurek.window.getDPIScale = function() end

--- Returns the full desktop resolution of the current monitor as two values (width, height) in physical pixels.
---@return integer Desktop width in pixels.
---@return integer Desktop height in pixels.
lurek.window.getDesktopDimensions = function() end

--- Returns the window dimensions as two values (width, height) in logical pixels.
---@return integer Window width in logical pixels.
---@return integer Window height in logical pixels.
lurek.window.getDimensions = function() end

--- Returns the number of displays (monitors) currently connected to the system.
---@return integer The number of connected displays
lurek.window.getDisplayCount = function() end

--- Returns the human-readable name of a connected display as reported by the operating system (for example "DELL U2723QE" or "Built-in Retina").
---@param display? integer Zero-based display index; omit for the current monitor
---@return string The display name string
lurek.window.getDisplayName = function(display) end

--- Returns the current display orientation.
---@return string Display orientation name: `landscape` or `portrait`.
lurek.window.getDisplayOrientation = function() end

--- Returns the current fullscreen state as two values: a boolean indicating whether fullscreen is active, and a string describing the type ("desktop" or "exclusive").
---@return boolean True when fullscreen is active.
---@return string Fullscreen mode name.
lurek.window.getFullscreen = function() end

--- Returns an array of all available fullscreen video modes supported by the current monitor.
---@return table An array of tables, each with width, height, and refreshRate fields
lurek.window.getFullscreenModes = function() end

--- Returns the logical game height in virtual pixels.
---@return number Logical game height in virtual pixels.
lurek.window.getGameHeight = function() end

--- Returns the logical game width in virtual pixels.
---@return number Logical game width in virtual pixels.
lurek.window.getGameWidth = function() end

--- Returns the current window height in logical pixels.
---@return integer The window height in logical pixels
lurek.window.getHeight = function() end

--- Returns the current window dimensions and mode flags as three values: width, height, and a flags table.
---@return integer Window width in logical pixels.
---@return integer Window height in logical pixels.
---@return table Table of current window mode flags.
lurek.window.getMode = function() end

--- Returns the native DPI scale factor.
---@return number Native DPI scale factor for the current window.
lurek.window.getNativeDPIScale = function() end

--- Returns the window dimensions in physical (device) pixels as two values (width, height).
---@return integer Window width in physical pixels.
---@return integer Window height in physical pixels.
lurek.window.getPixelDimensions = function() end

--- Returns the top-left corner position of the window in screen coordinates as two values (x, y).
---@return integer Window X position in screen coordinates.
---@return integer Window Y position in screen coordinates.
lurek.window.getPosition = function() end

--- Returns the safe display area as x, y, w, h.
---@return number Safe-area X coordinate.
---@return number Safe-area Y coordinate.
---@return number Safe-area width.
---@return number Safe-area height.
lurek.window.getSafeArea = function() end

--- Returns viewport scale and offset information as a table.
---@return table Table with scale, offset, and virtual game size fields.
lurek.window.getScaleInfo = function() end

--- Returns the current viewport scale mode string.
---@return string Current viewport scale mode name.
lurek.window.getScaleMode = function() end

--- Returns the OS color theme preference.
---@return string OS color theme preference string.
lurek.window.getSystemTheme = function() end

--- Returns the current window title bar text as a string.
---@return string The current window title
lurek.window.getTitle = function() end

--- Returns the current vertical synchronisation mode as an integer: 1 = VSync on, 0 = VSync off, -1 = adaptive VSync.
---@return integer The current VSync mode
lurek.window.getVSync = function() end

--- Returns the current window width in logical pixels.
---@return integer The window width in logical pixels
lurek.window.getWidth = function() end

--- Returns whether the window currently has keyboard input focus from the operating system.
---@return boolean True if the window has keyboard focus
lurek.window.hasFocus = function() end

--- Returns whether the mouse cursor is currently inside the window's client area.
---@return boolean True if the mouse cursor is inside the window
lurek.window.hasMouseFocus = function() end

--- Returns whether the window is in fullscreen mode.
---@return boolean Whether the window is currently in fullscreen mode.
lurek.window.isFullscreen = function() end

--- Returns whether high-DPI rendering is allowed.
---@return boolean Always false because high-DPI rendering is not currently supported.
lurek.window.isHighDPIAllowed = function() end

--- Returns whether the window is currently maximised to fill the entire desktop work area.
---@return boolean True if the window is maximised
lurek.window.isMaximized = function() end

--- Returns whether the window is currently minimised to the taskbar.
---@return boolean True if the window is minimised
lurek.window.isMinimized = function() end

--- Returns whether the window is currently open and active.
---@return boolean Always true during normal engine operation
lurek.window.isOpen = function() end

--- Returns whether the window can be resized by the user.
---@return boolean Whether the window can be resized by the user.
lurek.window.isResizable = function() end

--- Returns whether the window is currently visible on screen.
---@return boolean True if the window is visible
lurek.window.isVisible = function() end

--- Maximises the window so it fills the entire desktop work area, excluding the taskbar.
---@return nil No value is returned.
lurek.window.maximize = function() end

--- Minimises the window to the operating system taskbar or dock.
---@return nil No value is returned.
lurek.window.minimize = function() end

--- Registers a callback invoked (with the new scale factor) when the display DPI changes.
---@param callback function Callback function.
---@return nil No value is returned.
lurek.window.onDpiChange = function(callback) end

--- Opens a blocking native file-open dialog.
---@param opts? table Options table.
---@return table Array of selected file paths.
lurek.window.openFileDialog = function(opts) end

lurek.window.pollDpiChange = function() end

--- Flashes the window icon in the operating system taskbar or dock to attract the user's attention.
---@return nil No return value.
lurek.window.requestAttention = function() end

--- Restores the window to its previous size and position after a `minimize` or `maximize` call.
---@return nil No value is returned.
lurek.window.restore = function() end

--- Enables or disables fullscreen mode.
---@param enabled boolean True to enter fullscreen, false to exit
---@param fstype? string Fullscreen type: "desktop" or "exclusive" (default "desktop")
---@return nil No value is returned.
lurek.window.setFullscreen = function(enabled, fstype) end

--- Sets the window icon from an image file located in the game directory.
---@param path string Relative path to the icon image file
---@return nil No return value.
lurek.window.setIcon = function(path) end

--- Resizes the window and optionally changes fullscreen and vsync settings in a single call.
---@param w integer The new window width in logical pixels
---@param h integer The new window height in logical pixels
---@param flags? table Optional table with fullscreen, fullscreentype, and vsync keys
---@return nil No return value.
lurek.window.setMode = function(w, h, flags) end

--- Moves the top-left corner of the window to the given screen coordinates.
---@param x integer The target horizontal screen coordinate in pixels
---@param y integer The target vertical screen coordinate in pixels
---@return nil No value is returned.
lurek.window.setPosition = function(x, y) end

--- Sets the viewport scale mode.
---@param mode string Viewport scale mode name.
---@return nil No value is returned.
lurek.window.setScaleMode = function(mode) end

--- Sets the text displayed in the window's title bar.
---@param title string The new window title text
---@return nil No value is returned.
lurek.window.setTitle = function(title) end

--- Sets the vertical synchronisation mode for the window's swap chain.
---@param mode integer VSync mode: 1 = on, 0 = off, -1 = adaptive
---@return nil No value is returned.
lurek.window.setVSync = function(mode) end

--- Shows a platform-native message box dialog.
---@param title string Window title text.
---@param message string Message text.
---@param boxType? string Message box type.
---@param btnType? string Button layout type.
---@return string Button or result identifier returned by the native dialog.
lurek.window.showMessageBox = function(title, message, boxType, btnType) end

--- Converts a device-independent (logical) coordinate value to its equivalent in physical pixels using the current DPI scale factor.
---@param value number The logical coordinate value to convert
---@return number The corresponding physical pixel value
lurek.window.toPixels = function(value) end
