---@meta
--- Auto-generated Lurek2D API documentation for LuaCATS.

lurek = {}

---@alias AIBlackboard LAIBlackboard

---@alias AIDirector LAIDirector

---@alias AILod LAILod

---@alias AIWorld LAIWorld

---@alias AabbTree LAabbTree

---@alias Agent LAgent

---@alias AiFlowField LAIFlowField

---@alias AnimCurve LAnimCurve

---@alias AnimStateMachine LAnimStateMachine

---@alias AnimSyncGroup LAnimSyncGroup

---@alias Animation LAnimation

---@alias ApiCatalog LApiCatalog

---@alias AreaChart LAreaChart

---@alias Array LArray

---@alias AutoTileSheet LAutoTileSheet

---@alias BTNode LBTNode

---@alias Bandit LBandit

---@alias BarChart LBarChart

---@alias BehaviorTree LBehaviorTree

---@alias BezierCurve LBezierCurve

---@alias Blackboard LBlackboard

---@alias BlendLayerSet LBlendLayerSet

---@alias Body LBody

---@alias Bus LBus

---@alias ByteData LByteData

---@alias Camera2D LCamera

---@alias Canvas LCanvas

---@alias CatmullRom LCatmullRom

---@alias Cellular LCellular

---@alias Channel LChannel

---@alias ChunkMap LChunkMap

---@alias Circle LCircle

---@alias Combo LCombo

---@alias CommandQueue LCommandQueue

---@alias CommandStack LCommandStack

---@alias CompressedImageData LCompressedImageData

---@alias ContentRegistry LContentRegistry

---@alias ContextSteering LContextSteering

---@alias Cursor LCursor

---@alias DataFrame LDataFrame

---@alias DataView LDataView

---@alias DataWriter LDataWriter

---@alias Database LDatabase

---@alias Debounce LDebounce

---@alias Decoder LDecoder

---@alias DepthSorter LDepthSorter

---@alias DoorManager LDoorManager

---@alias DrawLayer LDrawLayer

---@alias Edge LGraphEdge

---@alias EmotionModel LEmotionModel

---@alias Environment any

---@alias Factory LFactory

---@alias FileData LFileData

---@alias FileHandle LFileHandle

---@alias FileWatcher LFileWatcher

---@alias FlowField LFlowField

---@alias Font LFont

---@alias Funnel LFunnel

---@alias GID integer

---@alias GOAPPlanner LGOAPPlanner

---@alias GeneticAlgorithm LGeneticAlgorithm

---@alias Globe LGlobe

---@alias Graph LGraph

---@alias GraphItem LGraphItem

---@alias GroupedFrame LGroupedFrame

---@alias HTNDomain LHTNDomain

---@alias HeightMap LHeightMap

---@alias Hermite LHermite

---@alias HexGrid LHexGrid

---@alias HtmlDocument LHtmlDocument

---@alias HtmlElement LHtmlElement

---@alias ID integer

---@alias Image LImage

---@alias ImageData LImageData

---@alias ImageEffect LImageEffect

---@alias InfluenceMap LInfluenceMap

---@alias IsoMap LIsoMap

---@alias JpsGrid LJpsGrid

---@alias LargeMapRenderer LLargeMapRenderer

---@alias LayeredImage LLayeredImage

---@alias Light LLight

---@alias LineChart LLineChart

---@class Linux
Linux = {}

---@alias List LList

---@class Lua
Lua = {}

---@alias LuaParallaxLayer LParallaxLayer

---@alias LuaParallaxSet LParallaxSet

---@alias LuaValue any

---@alias MCTSEngine LMCTSEngine

---@alias MapBlock LMapBlock

---@alias MapGen LMapGen

---@alias MapGroup LMapGroup

---@alias MapScript LMapScript

---@alias Mediator LMediator

---@alias Mesh LMesh

---@alias MidiPlayer LMidiPlayer

---@alias Minimap LMinimap

---@alias Mod LMod

---@alias ModManager LModManager

---@alias MultiValue any

---@alias NavGrid LNavGrid

---@alias NeedSystem LNeedSystem

---@alias NetworkHost LNetworkHost

---@alias NetworkRuntime LNetworkRuntime

---@alias NeuralNet LNeuralNet

---@alias Neuroevolution LNeuroevolution

---@alias NineSlice LNineSlice

---@alias Node LGraphNode

---@alias NoiseGenerator LNoiseGenerator

---@alias ORCASolver LORCASolver

---@alias ObjectPool LObjectPool

---@alias Observer LObserver

---@alias Occluder LOccluder

---@alias Overlay LOverlay

---@alias PaletteLUT LPaletteLUT

---@alias ParticleSystem LParticleSystem

---@alias PathGrid LPathGrid

---@alias PhysicsShape LPhysicsShape

---@alias PieChart LPieChart

---@alias Pipeline LPipeline

---@alias PointLight LPointLight

---@alias PostFxEffect LPostFxEffect

---@alias PostFxStack LPostFxStack

---@alias PriorityQueue LPriorityQueue

---@alias Promise LPromise

---@alias ProvinceGrid LProvinceGrid

---@alias QLearner LQLearner

---@alias Quad LQuad

---@alias Queue LQueue

---@alias Radius number

---@alias RandomGenerator LRandomGenerator

---@alias Raycaster LRaycaster

---@alias RelationshipManager LRelationshipManager

---@alias ReplConsole LReplConsole

---@alias Ring LRing

---@alias RingBuffer LRingBuffer

---@alias SaveManager LSaveManager

---@alias ScatterPlot LScatterPlot

---@alias ScreenTransition LScreenTransition

---@alias ServiceLocator LServiceLocator

---@alias Set LSet

---@alias Shader LShader

---@alias Shape LShape

---@alias Signal LSignal

---@alias SimpleState LSimpleState

---@alias Skeleton LSkeleton

---@alias SkeletonAnimation LSkeletonAnimation

---@alias SoundData LSoundData

---@alias SoundPool LSoundPool

---@alias Source LSource

---@alias SpatialHash LSpatialHash

---@alias Spring LSpring

---@alias SpriteAtlas LSpriteAtlas

---@alias SpriteBatch LSpriteBatch

---@alias SpriteManager LSpriteManager

---@alias SpriteSheet LSpriteSheet

---@alias Squad LSquad

---@alias StateMachine LStateMachine

---@alias SteeringManager LSteeringManager

---@alias Step LPipelineStep

---@alias StimulusWorld LStimulusWorld

---@alias Strategy LStrategy

---@alias StrategyAI LStrategyAI

---@alias Terminal LTerminal

---@alias Terrain LTerrain

---@alias TextureKey any

---@alias Theme LTheme

---@alias ThreadHandle LThread

---@alias ThreadPool LThreadPool

---@alias Throttle LThrottle

---@alias TileMap LTileMap

---@alias TileSet LTileSet

---@alias Tint any

---@alias Trail LTrail

---@alias TraitProfile LTraitProfile

---@alias Transform LTransform

---@alias Tween LTween

---@alias TweenParallel LTweenParallel

---@alias TweenSequence LTweenSequence

---@alias TweenState LTweenState

---@alias UnitPathfinder LUnitPathfinder

---@alias Universe LUniverse

---@alias UtilityAI LUtilityAI

---@alias ValidationReport LValidationReport

---@alias Vec2 LVec2

---@alias Vec3 LVec3

---@alias VecFrame LVecFrame

---@alias Widget LWidget

---@alias World LWorld

---@alias ZipMount LZipMount

---@alias Zone LZone

---@class lurek.ai
lurek.ai = {}

--- Lua-side wrapper around a [`Blackboard`].
---@class LAIBlackboard
LAIBlackboard = {}

--- Removes all local entries.
---@return nil
function LAIBlackboard:clear() end

--- Returns the boolean for the given key, or default.
---@param key string
---@param default? boolean
---@return boolean
function LAIBlackboard:getBool(key, default) end

--- Returns all local keys as a table.
---@return table
function LAIBlackboard:getKeys() end

--- Returns the number for the given key, or default.
---@param key string
---@param default? number
---@return number
function LAIBlackboard:getNumber(key, default) end

--- Returns the number of local entries.
---@return number
function LAIBlackboard:getSize() end

--- Returns the string for the given key, or default.
---@param key string
---@param default? string
---@return string
function LAIBlackboard:getString(key, default) end

--- Returns true if a value exists under the key.
---@param key string
---@return boolean
function LAIBlackboard:has(key) end

--- Removes the entry at key.
---@param key string
---@return nil
function LAIBlackboard:remove(key) end

--- Stores a boolean under the given key.
---@param key string
---@param value boolean
---@return nil
function LAIBlackboard:setBool(key, value) end

--- Stores a number under the given key.
---@param key string
---@param value number
---@return nil
function LAIBlackboard:setNumber(key, value) end

--- Stores a string under the given key.
---@param key string
---@param value string
---@return nil
function LAIBlackboard:setString(key, value) end

--- Returns the type name of this object.
---@return string
function LAIBlackboard:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAIBlackboard:typeOf(name) end

--- Lua wrapper for [`crate::ai::director::AIDirector`].
---@class LAIDirector
LAIDirector = {}

--- Returns or performs ambient intensity.
---@return number
function LAIDirector:ambientIntensity() end

--- Returns or performs loot factor.
---@return number
function LAIDirector:lootFactor() end

--- Returns or performs phase.
---@return string
function LAIDirector:phase() end

--- Pushes a gameplay event with the given intensity to the director for awareness analysis.
---@param intensity number
---@return nil
function LAIDirector:pushEvent(intensity) end

--- Resets or clears the state.
---@return nil
function LAIDirector:reset() end

--- Sets the global narrative tension level (0â€“1 scale).
---@param value number
---@return nil
function LAIDirector:setTension(value) end

--- Returns or performs spawn rate factor.
---@return number
function LAIDirector:spawnRateFactor() end

--- Returns or performs tension.
---@return number
function LAIDirector:tension() end

--- Returns the type name of this object.
---@return string
function LAIDirector:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAIDirector:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number
---@return nil
function LAIDirector:update(dt) end

--- Lua wrapper for [`crate::ai::lod::AILod`].
---@class LAILod
LAILod = {}

--- Returns or performs should update.
---@param tier integer
---@param frame_number integer
---@return boolean
function LAILod:shouldUpdate(tier, frame_number) end

--- Returns or performs tier count.
---@return number
function LAILod:tierCount() end

--- Returns or performs tier for.
---@param agent_x number
---@param agent_y number
---@param ref_x number
---@param ref_y number
---@return number
function LAILod:tierFor(agent_x, agent_y, ref_x, ref_y) end

--- Returns or performs tier name.
---@param tier integer
---@return string
function LAILod:tierName(tier) end

--- Returns the type name of this object.
---@return string
function LAILod:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAILod:typeOf(name) end

--- Lua-side wrapper around an [`AIWorld`].
---@class LAIWorld
LAIWorld = {}

--- Registers a new named agent and returns its handle.
---@param name string
---@return Agent
function LAIWorld:addAgent(name) end

--- Returns the agent handle for the given name, or nil.
---@param name string
---@return nil
function LAIWorld:getAgent(name) end

--- Returns the number of registered agents.
---@return number
function LAIWorld:getAgentCount() end

--- Returns a snapshot of the world-level blackboard.
---@return AIBlackboard
function LAIWorld:getGlobalBlackboard() end

--- Removes an agent by its userdata handle.
---@param agent Agent
---@return nil
function LAIWorld:removeAgent(agent) end

--- Returns the type name of this object.
---@return string
function LAIWorld:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAIWorld:typeOf(name) end

--- Advances all agents by dt seconds, then invokes any custom-model callbacks.
---@param dt number
---@return nil
function LAIWorld:update(dt) end

--- Lua-side wrapper for an agent accessed by name through the owning world.
---@class LAgent
LAgent = {}

--- Adds a tag to this agent.
---@param tag string
---@return nil
function LAgent:addTag(tag) end

--- Returns the agent's local blackboard.
---@return AIBlackboard
function LAgent:getBlackboard() end

--- Returns the name of the current decision model.
---@return string
function LAgent:getDecisionModel() end

--- Returns the maximum steering force cap.
---@return number
function LAgent:getMaxForce() end

--- Returns the maximum speed cap.
---@return number
function LAgent:getMaxSpeed() end

--- Returns the agent's registered name.
---@return string
function LAgent:getName() end

--- Returns the agent's current position.
---@return number
---@return number
function LAgent:getPosition() end

--- Returns the agent's scheduling priority.
---@return number
function LAgent:getPriority() end

--- Returns the agent's current velocity.
---@return number
---@return number
function LAgent:getVelocity() end

--- Returns true if the agent has the given tag.
---@param tag string
---@return boolean
function LAgent:hasTag(tag) end

--- Removes a tag from this agent.
---@param tag string
---@return nil
function LAgent:removeTag(tag) end

--- Installs a Lua-driven decision model on this agent.
---@param callback function(agent,blackboard,dt)
---@return nil
function LAgent:setCustomModel(callback) end

--- Sets the active decision model.
---@param model string
---@return nil
function LAgent:setDecisionModel(model) end

--- Sets the maximum steering force cap.
---@param v number
---@return nil
function LAgent:setMaxForce(v) end

--- Sets the maximum speed cap.
---@param v number
---@return nil
function LAgent:setMaxSpeed(v) end

--- Sets the agent's world-space position.
---@param x number
---@param y number
---@return nil
function LAgent:setPosition(x, y) end

--- Sets the scheduling priority (higher = earlier).
---@param p integer
---@return nil
function LAgent:setPriority(p) end

--- Sets the agent's velocity vector.
---@param x number
---@param y number
---@return nil
function LAgent:setVelocity(x, y) end

--- Returns the type name of this object.
---@return string
function LAgent:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAgent:typeOf(name) end

--- Lua-side wrapper around a [`BTNode`].
---@class LBTNode
LBTNode = {}

--- Adds a child node (Selector, Sequence, or Parallel only).
---@param child BTNode
---@return nil
function LBTNode:addChild(child) end

--- Returns the number of direct children.
---@return number
function LBTNode:getChildCount() end

--- Returns the repeat count, or 0 if not a Repeater.
---@return number
function LBTNode:getCount() end

--- Returns the node type as a string.
---@return string
function LBTNode:getNodeType() end

--- Resets all running-child memos and repeater counters.
---@return nil
function LBTNode:reset() end

--- Sets the single child of a decorator node.
---@param child BTNode
---@return nil
function LBTNode:setChild(child) end

--- Sets the repeat count for a Repeater node.
---@param n integer
---@return nil
function LBTNode:setCount(n) end

--- Sets the failure policy for a Parallel node.
---@param policy string
---@return nil
function LBTNode:setFailurePolicy(policy) end

--- Sets the success policy for a Parallel node.
---@param policy string
---@return nil
function LBTNode:setSuccessPolicy(policy) end

--- Returns the type name of this object.
---@return string
function LBTNode:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LBTNode:typeOf(name) end

--- Lua wrapper for [`crate::ai::bandit::Bandit`].
---@class LBandit
LBandit = {}

--- Returns or performs arm count.
---@return number
function LBandit:armCount() end

--- Returns or performs best arm.
---@return number
function LBandit:bestArm() end

--- Resets or clears the state.
---@return nil
function LBandit:reset() end

--- Returns or performs select.
---@return number
function LBandit:select() end

--- Returns or performs total pulls.
---@return number
function LBandit:totalPulls() end

--- Returns the type name of this object.
---@return string
function LBandit:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LBandit:typeOf(name) end

--- Advances the simulation by one time step.
---@param index integer
---@param reward number
---@return nil
function LBandit:update(index, reward) end

--- Lua-side wrapper around a [`BehaviorTree`].
---@class LBehaviorTree
LBehaviorTree = {}

--- Returns a diagnostic snapshot of this behavior tree.
---@return table
function LBehaviorTree:getDebugState() end

--- Returns the status from the last tick.
---@return string
function LBehaviorTree:getLastStatus() end

--- Sets the root node of this behavior tree.
---@param node BTNode
---@return nil
function LBehaviorTree:setRoot(node) end

--- Returns the type name of this object.
---@return string
function LBehaviorTree:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LBehaviorTree:typeOf(name) end

--- Lua-side wrapper around a [`CommandQueue`].
---@class LCommandQueue
LCommandQueue = {}

--- Cancels the front command if it is interruptible.
---@return boolean
function LCommandQueue:cancelCurrent() end

--- Discards all queued commands.
---@return nil
function LCommandQueue:clear() end

--- Appends a command to the back of the queue.
---@param kind string
---@param callback function
---@param opts? table
---@return nil
function LCommandQueue:enqueue(kind, callback, opts) end

--- Returns the number of queued commands.
---@return number
function LCommandQueue:getCount() end

--- Returns the target coordinates of the front command.
---@return number
---@return number
function LCommandQueue:getCurrentTarget() end

--- Returns the kind of the front command, or nil.
---@return string
function LCommandQueue:getCurrentType() end

--- Returns true if there are no queued commands.
---@return boolean
function LCommandQueue:isEmpty() end

--- Inserts a command at the front, interrupting the current one.
---@param kind string
---@param callback function
---@param opts? table
---@return nil
function LCommandQueue:pushFront(kind, callback, opts) end

--- Clears the queue and enqueues one new command.
---@param kind string
---@param callback function
---@param opts? table
---@return nil
function LCommandQueue:replace(kind, callback, opts) end

--- Returns the type name of this object.
---@return string
function LCommandQueue:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LCommandQueue:typeOf(name) end

--- Lua wrapper for [`crate::ai::context_steering::ContextSteering`].
---@class LContextSteering
LContextSteering = {}

--- Registers a rectangular region this agent must avoid.
---@param min_x number
---@param min_y number
---@param max_x number
---@param max_y number
---@param margin number
---@param weight number
---@return nil
function LContextSteering:addAvoidBounds(min_x, min_y, max_x, max_y, margin, weight) end

--- Adds a world-space point that this agent steers away from.
---@param x number
---@param y number
---@param radius number
---@param weight number
---@return nil
function LContextSteering:addAvoidPoint(x, y, radius, weight) end

--- Adds a world-space target that this agent steers towards.
---@param tx number
---@param ty number
---@param weight number
---@return nil
function LContextSteering:addSeekTarget(tx, ty, weight) end

--- Adds a wander behavior with jitter and weight to the context steering evaluator.
---@param jitter number
---@param weight number
---@return nil
function LContextSteering:addWander(jitter, weight) end

--- Returns or performs chosen magnitude.
---@return number
function LContextSteering:chosenMagnitude() end

--- Resets or clears the behaviors.
---@return nil
function LContextSteering:clearBehaviors() end

--- Evaluates and returns the computed result.
---@param ax number
---@param ay number
---@param vx number
---@param vy number
---@return number
---@return number
function LContextSteering:evaluate(ax, ay, vx, vy) end

--- Returns or performs slot count.
---@return number
function LContextSteering:slotCount() end

--- Returns the type name of this object.
---@return string
function LContextSteering:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LContextSteering:typeOf(name) end

--- Lua wrapper for [`crate::ai::emotion::EmotionModel`].
---@class LEmotionModel
LEmotionModel = {}

--- Adds an emotion category with the given name and initial intensity to the model.
---@param name string
---@param resting_level number
---@param decay_rate number
---@param min_visible number
---@return nil
function LEmotionModel:add(name, resting_level, decay_rate, min_visible) end

--- Returns or performs dominant.
---@return string
function LEmotionModel:dominant() end

--- Returns the current float value of this emotion dimension.
---@param name string
---@return number
function LEmotionModel:get(name) end

--- Returns `true` if the emotion dimension is currently active and above threshold.
---@param name string
---@return boolean
function LEmotionModel:isActive(name) end

--- Resets or clears the state.
---@return nil
function LEmotionModel:reset() end

--- Returns or performs trigger.
---@param name string
---@param amount number
---@return nil
function LEmotionModel:trigger(name, amount) end

--- Returns the type name of this object.
---@return string
function LEmotionModel:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LEmotionModel:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number
---@return nil
function LEmotionModel:update(dt) end

--- Lua-side wrapper around a [`GOAPPlanner`].
---@class LGOAPPlanner
LGOAPPlanner = {}

--- Adds a GOAP action with optional cost and callback.
---@param name string
---@param cost? number
---@param callback? function
---@return nil
function LGOAPPlanner:addAction(name, cost, callback) end

--- Adds a planning goal with optional priority.
---@param name string
---@param priority? number
---@return nil
function LGOAPPlanner:addGoal(name, priority) end

--- Returns the number of registered actions.
---@return number
function LGOAPPlanner:getActionCount() end

--- Returns the number of registered goals.
---@return number
function LGOAPPlanner:getGoalCount() end

--- Returns the maximum A* planning iterations.
---@return number
function LGOAPPlanner:getMaxIterations() end

--- Runs A* planning and returns an action sequence table.
---@param worldState table
---@param maxDepth? integer
---@return table
function LGOAPPlanner:plan(worldState, maxDepth) end

--- Sets a boolean effect on an action.
---@param actionName string
---@param key string
---@param value boolean
---@return nil
function LGOAPPlanner:setEffect(actionName, key, value) end

--- Sets a boolean condition on a goal.
---@param goalName string
---@param key string
---@param value boolean
---@return nil
function LGOAPPlanner:setGoalState(goalName, key, value) end

--- Sets the maximum A* planning iterations (0 = unlimited).
---@param n integer
---@return nil
function LGOAPPlanner:setMaxIterations(n) end

--- Sets a boolean precondition on an action.
---@param actionName string
---@param key string
---@param value boolean
---@return nil
function LGOAPPlanner:setPrecondition(actionName, key, value) end

--- Returns the type name of this object.
---@return string
function LGOAPPlanner:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LGOAPPlanner:typeOf(name) end

--- Lua wrapper for [`crate::ai::genetic::GeneticAlgorithm`].
---@class LGeneticAlgorithm
LGeneticAlgorithm = {}

--- Returns or performs best genes.
---@return table
function LGeneticAlgorithm:bestGenes() end

--- Runs one generation of the evolutionary algorithm.
---@return nil
function LGeneticAlgorithm:evolve() end

--- Returns or performs generation.
---@return number
function LGeneticAlgorithm:generation() end

--- Returns the chromosome as an ordered table of gene values.
---@param index integer
---@return table
function LGeneticAlgorithm:getGenes(index) end

--- Returns or performs pop size.
---@return number
function LGeneticAlgorithm:popSize() end

--- Sets the fitness score used by the genetic algorithm selection step.
---@param index integer
---@param fitness number
---@return nil
function LGeneticAlgorithm:setFitness(index, fitness) end

--- Returns the type name of this object.
---@return string
function LGeneticAlgorithm:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LGeneticAlgorithm:typeOf(name) end

--- Lua wrapper for [`crate::ai::htn::HTNDomain`].
---@class LHTNDomain
LHTNDomain = {}

--- Registers a compound HTN task that decomposes into sub-tasks.
---@param compound_name string
---@param methods table
---@return nil
function LHTNDomain:addCompound(compound_name, methods) end

--- Registers a primitive HTN task with a direct operator function.
---@param name string
---@param preconditions table
---@param effects table
---@param effects_clear table
---@return nil
function LHTNDomain:addPrimitive(name, preconditions, effects, effects_clear) end

--- Runs planning and returns the resulting action sequence.
---@param root_task string
---@param state table
---@return table
function LHTNDomain:plan(root_task, state) end

--- Returns or performs task count.
---@return number
function LHTNDomain:taskCount() end

--- Returns the type name of this object.
---@return string
function LHTNDomain:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LHTNDomain:typeOf(name) end

--- Lua-side wrapper around an [`InfluenceMap`].
---@class LInfluenceMap
LInfluenceMap = {}

--- Adds a named influence layer.
---@param name string
---@return nil
function LInfluenceMap:addLayer(name) end

--- Blends two layers into a destination layer.
---@param layerA string
---@param weightA number
---@param layerB string
---@param weightB number
---@param dest string
---@return nil
function LInfluenceMap:blend(layerA, weightA, layerB, weightB, dest) end

--- Removes all influence values from every layer in the map.
---@return nil
function LInfluenceMap:clearAll() end

--- Clears all influence in a layer.
---@param layer string
---@return nil
function LInfluenceMap:clearLayer(layer) end

--- Multiplies all influences by a decay factor.
---@param layer string
---@param factor number
---@return nil
function LInfluenceMap:decay(layer, factor) end

--- Returns the cell size in world units.
---@return number
function LInfluenceMap:getCellSize() end

--- Returns the influence map height in grid cells.
---@return number
function LInfluenceMap:getHeight() end

--- Returns the influence value at a cell (1-based).
---@param layer string
---@param x integer
---@param y integer
---@return number
function LInfluenceMap:getInfluence(layer, x, y) end

--- Returns the world-space position of the maximum value.
---@param layer string
---@return number
---@return number
function LInfluenceMap:getMaxPosition(layer) end

--- Returns the world-space position of the minimum value.
---@param layer string
---@return number
---@return number
function LInfluenceMap:getMinPosition(layer) end

--- Returns the influence map width in grid cells.
---@return number
function LInfluenceMap:getWidth() end

--- Returns true if the named layer exists.
---@param name string
---@return boolean
function LInfluenceMap:hasLayer(name) end

--- Propagates influence values with momentum.
---@param layer string
---@param momentum? number
---@return nil
function LInfluenceMap:propagate(layer, momentum) end

--- Returns the summed influence in a world-space rectangle.
---@param layer string
---@param wx number
---@param wy number
---@param ww number
---@param wh number
---@return number
function LInfluenceMap:queryRect(layer, wx, wy, ww, wh) end

--- Sets the influence value at a cell (1-based).
---@param layer string
---@param x integer
---@param y integer
---@param value number
---@return nil
function LInfluenceMap:setInfluence(layer, x, y, value) end

--- Stamps influence in a radial area.
---@param layer string
---@param wx number
---@param wy number
---@param radius number
---@param value number
---@param falloff? number
---@return nil
function LInfluenceMap:stampInfluence(layer, wx, wy, radius, value, falloff) end

--- Returns the type name of this object.
---@return string
function LInfluenceMap:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LInfluenceMap:typeOf(name) end

--- Lua wrapper for [`crate::ai::mcts::MCTSEngine`].
---@class LMCTSEngine
LMCTSEngine = {}

--- Uses Lua closures for game logic. All closures receive/return integer states.
---@param root_state integer
---@param get_actions function(state)->table
---@param apply_action function(state,action)->integer
---@param evaluate function(state)->number
---@return number
function LMCTSEngine:search(root_state, get_actions, apply_action, evaluate) end

--- Returns the type name of this object.
---@return string
function LMCTSEngine:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LMCTSEngine:typeOf(name) end

--- Lua wrapper for [`crate::ai::needs::NeedSystem`].
---@class LNeedSystem
LNeedSystem = {}

--- Registers a new need with the specified name, urgency, and decay rate in the system.
---@param name string
---@param decay_rate number
---@param urgency_threshold number
---@param urgency_factor number
---@return nil
function LNeedSystem:addNeed(name, decay_rate, urgency_threshold, urgency_factor) end

--- Returns or performs most urgent.
---@return string
function LNeedSystem:mostUrgent() end

--- Returns or performs satisfy.
---@param name string
---@param amount number
---@return nil
function LNeedSystem:satisfy(name, amount) end

--- Returns the type name of this object.
---@return string
function LNeedSystem:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LNeedSystem:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number
---@return nil
function LNeedSystem:update(dt) end

--- Returns or performs value of.
---@param name string
---@return number
function LNeedSystem:valueOf(name) end

--- Lua wrapper for [`crate::ai::neural_net::NeuralNet`].
---@class LNeuralNet
LNeuralNet = {}

--- Adds a neural network layer with inputs, outputs, and an activation function.
---@param inputs integer
---@param outputs integer
---@param activation string
---@return nil
function LNeuralNet:addLayer(inputs, outputs, activation) end

--- Returns or performs forward.
---@param input table
---@return table
function LNeuralNet:forward(input) end

--- Returns a flat table of all connection weight values in the network.
---@return table
function LNeuralNet:getWeights() end

--- Returns or performs layer count.
---@return number
function LNeuralNet:layerCount() end

--- Returns or performs param count.
---@return number
function LNeuralNet:paramCount() end

--- Overwrites all connection weights with values from a flat table.
---@param weights table
---@return boolean
function LNeuralNet:setWeights(weights) end

--- Returns the type name of this object.
---@return string
function LNeuralNet:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LNeuralNet:typeOf(name) end

--- Lua wrapper for [`crate::ai::neuroevolution::Neuroevolution`].
---@class LNeuroevolution
LNeuroevolution = {}

--- Returns or performs best fitness.
---@return number
function LNeuroevolution:bestFitness() end

--- Returns or performs best network.
---@return nil
function LNeuroevolution:bestNetwork() end

--- Returns or performs chromosome to net.
---@param index integer
---@return nil
function LNeuroevolution:chromosomeToNet(index) end

--- Runs one generation of the evolutionary algorithm.
---@return nil
function LNeuroevolution:evolve() end

--- Returns or performs generation.
---@return number
function LNeuroevolution:generation() end

--- Returns or performs pop size.
---@return number
function LNeuroevolution:popSize() end

--- Sets the fitness score used by the genetic algorithm selection step.
---@param index integer
---@param fitness number
---@return nil
function LNeuroevolution:setFitness(index, fitness) end

--- Returns the type name of this object.
---@return string
function LNeuroevolution:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LNeuroevolution:typeOf(name) end

--- Lua wrapper for [`crate::ai::orca::ORCASolver`].
---@class LORCASolver
LORCASolver = {}

--- Adds an ORCA agent at the given position with radius and max speed to the solver.
---@param x number
---@param y number
---@param radius number
---@param max_speed number
---@return number
function LORCASolver:addAgent(x, y, radius, max_speed) end

--- Returns or performs agent count.
---@return number
function LORCASolver:agentCount() end

--- Computes and returns the result.
---@param dt number
---@return nil
function LORCASolver:compute(dt) end

--- Returns the safe velocity.
---@param index integer
---@return number
---@return number
function LORCASolver:getSafeVelocity(index) end

--- Sets the agent's current world-space position for ORCA velocity computation.
---@param index integer
---@param x number
---@param y number
---@return nil
function LORCASolver:setPosition(index, x, y) end

--- Sets the preferred velocity.
---@param index integer
---@param pvx number
---@param pvy number
---@return nil
function LORCASolver:setPreferredVelocity(index, pvx, pvy) end

--- Returns the type name of this object.
---@return string
function LORCASolver:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LORCASolver:typeOf(name) end

--- Lua-side wrapper around a [`QLearner`].
---@class LQLearner
LQLearner = {}

--- Returns the greedy-best action for the state (1-based).
---@param state integer
---@return number
function LQLearner:bestAction(state) end

--- Selects an action using epsilon-greedy policy (1-based).
---@param state integer
---@return number
function LQLearner:chooseAction(state) end

--- Restores the Q-table from a JSON string.
---@param json string
---@return nil
function LQLearner:deserialize(json) end

--- Ends the current episode, applying epsilon decay.
---@return nil
function LQLearner:endEpisode() end

--- Returns the number of discrete actions.
---@return number
function LQLearner:getActionCount() end

--- Returns the current discount factor.
---@return number
function LQLearner:getDiscountFactor() end

--- Returns the number of completed episodes.
---@return number
function LQLearner:getEpisodeCount() end

--- Returns the epsilon decay multiplier.
---@return number
function LQLearner:getExplorationDecay() end

--- Returns the current exploration rate.
---@return number
function LQLearner:getExplorationRate() end

--- Returns the current learning rate.
---@return number
function LQLearner:getLearningRate() end

--- Returns the Q-value for a state-action pair (1-based).
---@param state integer
---@param action integer
---@return number
function LQLearner:getQValue(state, action) end

--- Returns the number of discrete states.
---@return number
function LQLearner:getStateCount() end

--- Performs one Bellman Q-learning update (1-based indices).
---@param state integer
---@param action integer
---@param reward number
---@param nextState integer
---@return nil
function LQLearner:learn(state, action, reward, nextState) end

--- Serializes the Q-table to a JSON string.
---@return string
function LQLearner:serialize() end

--- Sets the discount factor gamma.
---@param v number
---@return nil
function LQLearner:setDiscountFactor(v) end

--- Sets the epsilon decay multiplier.
---@param v number
---@return nil
function LQLearner:setExplorationDecay(v) end

--- Sets the exploration rate epsilon.
---@param v number
---@return nil
function LQLearner:setExplorationRate(v) end

--- Sets the learning rate alpha.
---@param v number
---@return nil
function LQLearner:setLearningRate(v) end

--- Overwrites the Q-value for a state-action pair (1-based).
---@param state integer
---@param action integer
---@param value number
---@return nil
function LQLearner:setQValue(state, action, value) end

--- Returns the type name of this object.
---@return string
function LQLearner:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LQLearner:typeOf(name) end

--- Lua-side wrapper around a [`Squad`].
---@class LSquad
LSquad = {}

--- Adds an agent by name to this squad.
---@param name string
---@return nil
function LSquad:addMember(name) end

--- Returns the squad's shared blackboard.
---@return AIBlackboard
function LSquad:getBlackboard() end

--- Returns the current formation type name.
---@return string
function LSquad:getFormation() end

--- Computes the world-space position for a member index (1-based).
---@param memberIdx integer
---@param leaderX number
---@param leaderY number
---@return number
---@return number
function LSquad:getFormationPosition(memberIdx, leaderX, leaderY) end

--- Returns the formation spacing in world units.
---@return number
function LSquad:getFormationSpacing() end

--- Returns the leader name, or nil.
---@return string
function LSquad:getLeader() end

--- Returns the number of squad members.
---@return number
function LSquad:getMemberCount() end

--- Returns the member names as a table.
---@return table
function LSquad:getMembers() end

--- Returns the unique name string assigned to this squad.
---@return string
function LSquad:getName() end

--- Removes an agent by name from this squad.
---@param name string
---@return nil
function LSquad:removeMember(name) end

--- Sets the formation type and optional spacing.
---@param ftype string
---@param spacing? number
---@return nil
function LSquad:setFormation(ftype, spacing) end

--- Sets the squad leader by name.
---@param name string
---@return nil
function LSquad:setLeader(name) end

--- Returns the type name of this object.
---@return string
function LSquad:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSquad:typeOf(name) end

--- Lua-side wrapper around a [`StateMachine`].
---@class LStateMachine
LStateMachine = {}

--- Registers a named state with optional lifecycle callbacks.
---@param name string
---@param opts table
---@return nil
function LStateMachine:addState(name, opts) end

--- Adds a guarded transition between states.
---@param from string
---@param to string
---@param guard? function
---@param priority? integer
---@return nil
function LStateMachine:addTransition(from, to, guard, priority) end

--- Forces a transition to the named state.
---@param name string
---@return nil
function LStateMachine:forceState(name) end

--- Returns the current state name, or nil.
---@return string
function LStateMachine:getCurrentState() end

--- Returns seconds spent in the current state.
---@return number
function LStateMachine:getTimeInState() end

--- Sets the FSM's initial state; must be called before the first update.
---@param name string
---@return nil
function LStateMachine:setInitialState(name) end

--- Returns the type name of this object.
---@return string
function LStateMachine:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LStateMachine:typeOf(name) end

--- Lua-side wrapper around a [`SteeringManager`].
---@class LSteeringManager
LSteeringManager = {}

--- Adds an Arrive behavior with deceleration.
---@param tx number
---@param ty number
---@param slowingRadius? number
---@param weight? number
---@return nil
function LSteeringManager:addArrive(tx, ty, slowingRadius, weight) end

--- Registers a Lua callback as a custom steering behavior.
---@param callback function(agent,dt)->dx,dy
---@param weight? number
---@return nil
function LSteeringManager:addCustomBehavior(callback, weight) end

--- Adds an Evade behavior fleeing from a named agent.
---@param threatName? string
---@param weight? number
---@return nil
function LSteeringManager:addEvade(threatName, weight) end

--- Adds a Flee behavior away from the target.
---@param tx number
---@param ty number
---@param panicDist? number
---@param weight? number
---@return nil
function LSteeringManager:addFlee(tx, ty, panicDist, weight) end

--- Adds a Flock behavior for group movement.
---@param neighborRadius? number
---@param sepWeight? number
---@param alignWeight? number
---@param cohWeight? number
---@param weight? number
---@return nil
function LSteeringManager:addFlock(neighborRadius, sepWeight, alignWeight, cohWeight, weight) end

--- Adds a Pursue behavior targeting a named agent.
---@param targetName? string
---@param weight? number
---@return nil
function LSteeringManager:addPursue(targetName, weight) end

--- Adds a Seek behavior toward the target.
---@param tx number
---@param ty number
---@param weight? number
---@return nil
function LSteeringManager:addSeek(tx, ty, weight) end

--- Adds a Wander behavior for random meandering.
---@param radius? number
---@param dist? number
---@param jitter? number
---@param weight? number
---@return nil
function LSteeringManager:addWander(radius, dist, jitter, weight) end

--- Invokes all registered custom steering callbacks and returns the combined force.
---@param agent Agent
---@param dt number
---@return number
---@return number
function LSteeringManager:applyCustomSteering(agent, dt) end

--- Computes the combined steering force for the given agent state.
---@param px number
---@param py number
---@param vx number
---@param vy number
---@param maxSpeed number
---@param maxForce number
---@param dt number
---@return number
---@return number
function LSteeringManager:calculate(px, py, vx, vy, maxSpeed, maxForce, dt) end

--- Enables or disables spatial-hash bucketing for neighbourhood queries.
---@param enabled boolean
---@return nil
function LSteeringManager:enableSpatialHash(enabled) end

--- Returns the number of active behaviors.
---@return number
function LSteeringManager:getBehaviorCount() end

--- Returns the current combination mode.
---@return string
function LSteeringManager:getCombineMode() end

--- Returns the last computed steering force.
---@return number
---@return number
function LSteeringManager:getLastSteering() end

--- Sets the force combination mode.
---@param mode string
---@return nil
function LSteeringManager:setCombineMode(mode) end

--- Sets the cell size used by the spatial-hash neighbourhood search.
---@param size number
---@return nil
function LSteeringManager:setSpatialHashCellSize(size) end

--- Returns the type name of this object.
---@return string
function LSteeringManager:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSteeringManager:typeOf(name) end

--- Lua wrapper for [`crate::ai::perception::StimulusWorld`].
---@class LStimulusWorld
LStimulusWorld = {}

--- Registers an auditory stimulus at a world-space position.
---@param x number
---@param y number
---@param intensity number
---@param radius number
---@param decay_rate number
---@param tag string|nil
---@return number
function LStimulusWorld:addAuditory(x, y, intensity, radius, decay_rate, tag) end

--- Adds a visual stimulus at the specified world position with radius and intensity.
---@param x number
---@param y number
---@param intensity number
---@param radius number
---@param tag? string
---@return number
function LStimulusWorld:addVisual(x, y, intensity, radius, tag) end

--- Resets or clears the state.
---@return nil
function LStimulusWorld:clear() end

--- Returns or performs count.
---@return number
function LStimulusWorld:count() end

--- Removes the specified item.
---@param id integer
---@return boolean
function LStimulusWorld:remove(id) end

--- Returns the type name of this object.
---@return string
function LStimulusWorld:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LStimulusWorld:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number
---@return nil
function LStimulusWorld:update(dt) end

--- Lua wrapper for [`crate::ai::strategy::StrategyAI`].
---@class LStrategyAI
LStrategyAI = {}

--- Returns or performs active goal.
---@return string
function LStrategyAI:activeGoal() end

--- Adds a strategic goal with priority score to the planner for future evaluation.
---@param name string
---@return nil
function LStrategyAI:addGoal(name) end

--- Adds a string tag to the strategy AI instance for goal filtering and categorization.
---@param tag string
---@return nil
function LStrategyAI:addTag(tag) end

--- Returns or performs force evaluate.
---@param scorer function(goal_name)->number
---@return nil
function LStrategyAI:forceEvaluate(scorer) end

--- Removes the specified tag.
---@param tag string
---@return nil
function LStrategyAI:removeTag(tag) end

--- Returns or performs time until next.
---@return number
function LStrategyAI:timeUntilNext() end

--- Returns the type name of this object.
---@return string
function LStrategyAI:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LStrategyAI:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number
---@param scorer function(goal_name)->number
---@return nil
function LStrategyAI:update(dt, scorer) end

--- Lua wrapper for [`crate::ai::traits::TraitProfile`].
---@class LTraitProfile
LTraitProfile = {}

--- Adds a named modifier that adjusts the trait value by a delta.
---@param trait_name string
---@param delta number
---@param duration? number
---@param source string
---@return nil
function LTraitProfile:addModifier(trait_name, delta, duration, source) end

--- Returns or performs archetype.
---@return string
function LTraitProfile:archetype() end

--- Returns the current float value of this emotion dimension.
---@param name string
---@return number
function LTraitProfile:get(name) end

--- Returns the unmodified base value of this trait before modifiers.
---@param name string
---@return number
function LTraitProfile:getBase(name) end

--- Returns true if a item is present.
---@param name string
---@return boolean
function LTraitProfile:has(name) end

--- Removes the specified modifiers.
---@param source string
---@return nil
function LTraitProfile:removeModifiers(source) end

--- Sets the base value of this trait, replacing any previous base.
---@param name string
---@param value number
---@return nil
function LTraitProfile:set(name, value) end

--- Returns or performs trait count.
---@return number
function LTraitProfile:traitCount() end

--- Returns the type name of this object.
---@return string
function LTraitProfile:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTraitProfile:typeOf(name) end

--- Advances the simulation by one time step.
---@param dt number
---@return nil
function LTraitProfile:update(dt) end

--- Lua-side wrapper around a [`UtilityAI`].
---@class LUtilityAI
LUtilityAI = {}

--- Adds a scored action with optional momentum weight.
---@param name string
---@param scorer function
---@param weight? number
---@return nil
function LUtilityAI:addAction(name, scorer, weight) end

--- Adds a multi-axis consideration to a named action.
---@param actionName string
---@param name string
---@param scorerFn function()
---@param curve string|function(x)->y
---@param p1? number
---@param p2? number
---@param p3? number
---@param weight? number
---@return nil
function LUtilityAI:addConsideration(actionName, name, scorerFn, curve, p1, p2, p3, weight) end

--- Evaluates all actions and returns the best action name, or nil.
---@return string
function LUtilityAI:evaluate() end

--- Returns the number of registered actions.
---@return number
function LUtilityAI:getActionCount() end

--- Returns the name of the last chosen action, or nil.
---@return string
function LUtilityAI:getLastAction() end

--- Returns the type name of this object.
---@return string
function LUtilityAI:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LUtilityAI:typeOf(name) end

--- Creates a new AI pacing director with default config.
---@return AIDirector
lurek.ai.newAIDirector = function() end

--- Creates a new AI LOD controller with default 3-tier config.
---@return AILod
lurek.ai.newAILod = function() end

--- Creates a BT action leaf with a Lua callback.
---@param callback function
---@return BTNode
lurek.ai.newAction = function(callback) end

--- Creates a new multi-armed bandit.
---@param arm_count integer
---@param strategy string
---@param epsilon number
---@param seed integer
---@return Bandit
lurek.ai.newBandit = function(arm_count, strategy, epsilon, seed) end

--- Creates a new behavior tree.
---@return BehaviorTree
lurek.ai.newBehaviorTree = function() end

--- Creates a new standalone blackboard.
---@return AIBlackboard
lurek.ai.newBlackboard = function() end

--- Creates an RTS-style command queue.
---@return CommandQueue
lurek.ai.newCommandQueue = function() end

--- Creates a BT condition leaf with a Lua predicate.
---@param callback function
---@return BTNode
lurek.ai.newCondition = function(callback) end

--- Creates a new context steering controller.
---@param slots integer
---@return ContextSteering
lurek.ai.newContextSteering = function(slots) end

--- Creates a new affective emotion model.
---@return EmotionModel
lurek.ai.newEmotionModel = function() end

--- Creates a new GOAP planning solver.
---@return GOAPPlanner
lurek.ai.newGOAPPlanner = function() end

--- Creates a new genetic algorithm.
---@param pop_size integer
---@param gene_count integer
---@param seed integer
---@return GeneticAlgorithm
lurek.ai.newGeneticAlgorithm = function(pop_size, gene_count, seed) end

--- Creates a BT Guard decorator. The predicate is evaluated before each tick;
---@param predicate function(agent,blackboard)->boolean
---@param child BTNode
---@return BTNode
lurek.ai.newGuard = function(predicate, child) end

--- Creates a new Hierarchical Task Network domain.
---@return HTNDomain
lurek.ai.newHTNDomain = function() end

--- Creates a multi-layer influence map grid.
---@param width integer
---@param height integer
---@param cellSize number
---@return InfluenceMap
lurek.ai.newInfluenceMap = function(width, height, cellSize) end

--- Creates a BT inverter decorator.
---@return BTNode
lurek.ai.newInverter = function() end

--- Creates a new Monte Carlo Tree Search engine.
---@param iterations integer
---@param uct_c number
---@param rollout_depth integer
---@param seed integer
---@return MCTSEngine
lurek.ai.newMCTSEngine = function(iterations, uct_c, rollout_depth, seed) end

--- Creates a new motivational need system.
---@return NeedSystem
lurek.ai.newNeedSystem = function() end

--- Creates a new feedforward neural network (inference only).
---@return NeuralNet
lurek.ai.newNeuralNet = function() end

--- Creates a neuroevolution trainer (GA for neural network weights).
---@param layer_spec table
---@param pop_size integer
---@param seed integer
---@return Neuroevolution
lurek.ai.newNeuroevolution = function(layer_spec, pop_size, seed) end

--- Creates a new ORCA crowd avoidance solver.
---@param time_horizon number
---@return ORCASolver
lurek.ai.newORCASolver = function(time_horizon) end

--- Creates a BT parallel node with optional policies.
---@param successPolicy? string
---@param failurePolicy? string
---@return BTNode
lurek.ai.newParallel = function(successPolicy, failurePolicy) end

--- Creates a tabular Q-learner.
---@param stateCount integer
---@param actionCount integer
---@return QLearner
lurek.ai.newQLearner = function(stateCount, actionCount) end

--- Creates a BT repeater decorator.
---@param count? integer
---@return BTNode
lurek.ai.newRepeater = function(count) end

--- Creates a BT selector node.
---@return BTNode
lurek.ai.newSelector = function() end

--- Creates a BT sequence node.
---@return BTNode
lurek.ai.newSequence = function() end

--- Creates a named squad for formation positioning.
---@param name string
---@return Squad
lurek.ai.newSquad = function(name) end

--- Creates a new finite state machine.
---@return StateMachine
lurek.ai.newStateMachine = function() end

--- Creates a new steering behavior manager.
---@return SteeringManager
lurek.ai.newSteeringManager = function() end

--- Creates a new stimulus perception world.
---@return StimulusWorld
lurek.ai.newStimulusWorld = function() end

--- Creates a new throttled strategy AI.
---@param update_interval number
---@return StrategyAI
lurek.ai.newStrategyAI = function(update_interval) end

--- Creates a BT succeeder decorator.
---@return BTNode
lurek.ai.newSucceeder = function() end

--- Creates a new personality trait profile.
---@return TraitProfile
lurek.ai.newTraitProfile = function() end

--- Creates a new utility AI evaluator.
---@return UtilityAI
lurek.ai.newUtilityAI = function() end

--- Creates a new AI world container.
---@return AIWorld
lurek.ai.newWorld = function() end

---@class lurek.animation
lurek.animation = {}

--- Lua-side wrapper around an [`AnimCurve`].
---@class LAnimCurve
LAnimCurve = {}

--- Inserts a keyframe at the given time. If a keyframe at the same time already
---@param time number
---@param value number
---@return nil
function LAnimCurve:addKeyframe(time, value) end

--- Removes all keyframes from this animation curve, resetting it to empty.
---@return nil
function LAnimCurve:clear() end

--- Returns the interpolated value at the given time using the curve's easing.
---@param t number
---@return number
function LAnimCurve:eval(t) end

--- Returns the number of keyframes currently stored.
---@return number
function LAnimCurve:keyframeCount() end

--- Set a custom Lua easing function for this curve.
---@param fn function(t: number)→ number — receives time t,returns output value
---@return nil
function LAnimCurve:setCustomEasing(fn) end

--- Sets the easing kind applied between all keyframe segments.
---@param mode string
---@return nil
function LAnimCurve:setEasing(mode) end

--- Returns the type name of this object.
---@return string
function LAnimCurve:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAnimCurve:typeOf(name) end

--- Lua-side wrapper around an [`AnimStateMachine`] FSM controller.
---@class LAnimStateMachine
LAnimStateMachine = {}

--- Registers a new named state that plays a clip from the embedded animation.
---@param name string
---@param clip string
---@param looping boolean
---@return nil
function LAnimStateMachine:addState(name, clip, looping) end

--- Adds a conditional transition between two states.
---@param from_state string
---@param to_state string
---@param condition string
---@return nil
function LAnimStateMachine:addTransition(from_state, to_state, condition) end

--- Immediately jumps to the named state, bypassing transition conditions.
---@param name string
---@return boolean
function LAnimStateMachine:forceState(name) end

--- Returns the source quad for the current animation frame, or nil.
---@return table
function LAnimStateMachine:getQuad() end

--- Returns the name of the currently active state.
---@return string
function LAnimStateMachine:getState() end

--- Sets an FSM parameter value (number, boolean, or integer supported).
---@param name string
---@param value number|boolean
---@return nil
function LAnimStateMachine:setParam(name, value) end

--- Returns the type name of this object.
---@return string
function LAnimStateMachine:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAnimStateMachine:typeOf(name) end

--- Advances the FSM by `dt` seconds, evaluating transitions.
---@param dt number
---@return nil
function LAnimStateMachine:update(dt) end

--- Lua-side wrapper around an [`AnimSyncGroup`].
---@class LAnimSyncGroup
LAnimSyncGroup = {}

--- Adds an animation handle to the group.
---@param handle integer
---@return nil
function LAnimSyncGroup:add(handle) end

--- Removes all animation handles from the group.
---@return nil
function LAnimSyncGroup:clear() end

--- Returns the number of animations currently in the group.
---@return number
function LAnimSyncGroup:memberCount() end

--- Removes an animation handle from the group.
---@param handle integer
---@return nil
function LAnimSyncGroup:remove(handle) end

--- Returns the type name of this object.
---@return string
function LAnimSyncGroup:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAnimSyncGroup:typeOf(name) end

--- Lua-side wrapper around an [`Animation`] controller.
---@class LAnimation
LAnimation = {}

--- Adds a named clip from explicit frame indices.
---@param name string
---@param indices table
---@param fps number
---@param looping boolean
---@return nil
function LAnimation:addClip(name, indices, fps, looping) end

--- Adds a named clip sliced from a sprite-sheet grid.
---@param name string
---@param tex_w integer
---@param tex_h integer
---@param frame_w integer
---@param frame_h integer
---@param start integer
---@param count integer
---@param fps number
---@param looping boolean
---@return nil
function LAnimation:addClipFromGrid(name, tex_w, tex_h, frame_w, frame_h, start, count, fps, looping) end

--- Adds a single frame to the frame pool by source rectangle.
---@param x number
---@param y number
---@param w number
---@param h number
---@return number
function LAnimation:addFrame(x, y, w, h) end

--- Slices a sprite-sheet grid into frames and appends them.
---@param tex_w integer
---@param tex_h integer
---@param frame_w integer
---@param frame_h integer
---@param start integer
---@param count integer
---@return number
function LAnimation:addFramesFromGrid(tex_w, tex_h, frame_w, frame_h, start, count) end

--- Begins a smooth crossfade from the current clip to a new named clip.
---@param clip_name string
---@param duration number
---@return boolean
function LAnimation:crossfade(clip_name, duration) end

--- Renders the current animation frame into a new ImageData (white bg, blue frame rect).
---@param width integer
---@param height integer
---@return ImageData
function LAnimation:drawToImage(width, height) end

--- Returns the two quads and blend factor during a crossfade, or nil when not blending.
---@return table
function LAnimation:getBlendState() end

--- Returns the name of the currently playing clip, or nil.
---@return string
function LAnimation:getClip() end

--- Returns the number of registered clips.
---@return number
function LAnimation:getClipCount() end

--- Returns the current position within the active clip (0-based).
---@return number
function LAnimation:getCurrentFrame() end

--- Returns the total number of frames in the frame pool.
---@return number
function LAnimation:getFrameCount() end

--- Returns the source quad (x, y, w, h) for the current frame, or nil.
---@return table
function LAnimation:getQuad() end

--- Returns the playback speed multiplier.
---@return number
function LAnimation:getSpeed() end

--- Returns true if the current clip is set to loop.
---@return boolean
function LAnimation:isLooping() end

--- Returns true if a clip is currently playing.
---@return boolean
function LAnimation:isPlaying() end

--- Pauses playback at the current frame.
---@return nil
function LAnimation:pause() end

--- Starts playback of the named clip.
---@param name string
---@return boolean
function LAnimation:play(name) end

--- Drains and returns all pending animation events as a table.
---@return table
function LAnimation:pollEvents() end

--- Resumes playback from the current frame.
---@return nil
function LAnimation:resume() end

--- Sets the playback position within the current clip.
---@param index integer
---@return nil
function LAnimation:setFrame(index) end

--- Sets the playback speed multiplier.
---@param speed number
---@return nil
function LAnimation:setSpeed(speed) end

--- Stops playback and resets to frame 0.
---@return nil
function LAnimation:stop() end

--- Returns the type name of this object.
---@return string
function LAnimation:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAnimation:typeOf(name) end

--- Advances the animation by dt seconds.
---@param dt number
---@return nil
function LAnimation:update(dt) end

--- Lua-side wrapper around a [`BlendLayerSet`] blend layer compositor.
---@class LBlendLayerSet
LBlendLayerSet = {}

--- Appends a new blend layer.
---@param name string
---@param clip_name string
---@param weight number
---@param bones? table
---@return boolean
function LBlendLayerSet:addLayer(name, clip_name, weight, bones) end

--- Returns the blend weight of a named layer, or nil if not found.
---@param name string
---@return number
function LBlendLayerSet:getWeight(name) end

--- Returns the number of blend layers.
---@return number
function LBlendLayerSet:len() end

--- Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
---@return table
function LBlendLayerSet:listLayers() end

--- Removes a blend layer by name.
---@param name string
---@return boolean
function LBlendLayerSet:removeLayer(name) end

--- Replaces the bone mask of a layer.
---@param name string
---@param bones table
---@return boolean
function LBlendLayerSet:setMask(name, bones) end

--- Sets the blend weight of a named layer (clamped to [0, 1]).
---@param name string
---@param weight number
---@return boolean
function LBlendLayerSet:setWeight(name, weight) end

--- Returns the type name of this object.
---@return string
function LBlendLayerSet:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LBlendLayerSet:typeOf(name) end

--- Parses an Aseprite JSON export string and builds an Animation with clips and frames.
---@param json_str string
---@return table
lurek.animation.fromAseprite = function(json_str) end

--- Creates a new, empty Animation controller.
---@return Animation
lurek.animation.new = function() end

--- Creates a new empty [`BlendLayerSet`] for compositing multiple animation clips.
---@return BlendLayerSet
lurek.animation.newBlendLayerSet = function() end

--- Creates a new empty [`AnimCurve`] with linear interpolation.
---@return AnimCurve
lurek.animation.newCurve = function() end

--- Creates an animation FSM from an Animation controller and an initial state name.
---@param anim Animation
---@param initial_state string
---@return AnimStateMachine
lurek.animation.newStateMachine = function(anim, initial_state) end

--- Creates a new empty [`AnimSyncGroup`].
---@return AnimSyncGroup
lurek.animation.newSyncGroup = function() end

---@class lurek.audio
lurek.audio = {}

--- Lua-side wrapper for an audio bus resource.
---@class LBus
LBus = {}

--- Removes the ducking target from this bus, restoring the target bus
---@return nil
function LBus:clearDuck() end

--- Returns the unique name string assigned to this audio bus.
---@return string
function LBus:getName() end

--- Returns the average peak amplitude of all sources currently on this bus.
---@return nil
function LBus:getPeak() end

--- Returns the bus pitch multiplier.
---@return number
function LBus:getPitch() end

--- Returns the current volume multiplier applied to all sources on this bus.
---@return number
function LBus:getVolume() end

--- Returns true if this bus is paused.
---@return boolean
function LBus:isPaused() end

--- Pauses all sources on this bus.
---@return nil
function LBus:pause() end

--- Resumes all sources on this bus.
---@return nil
function LBus:resume() end

--- Configures this bus to duck (lower the volume of) another bus when
---@param targetBusName string
---@param duckVolume number
---@return nil
function LBus:setDuckTarget(targetBusName, duckVolume) end

--- Sets the pitch multiplier for all sources on this bus.
---@param pitch number
---@return nil
function LBus:setPitch(pitch) end

--- Sets the volume for all sources on this bus.
---@param vol number
---@return nil
function LBus:setVolume(vol) end

--- Returns the type name of this object.
---@return string
function LBus:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LBus:typeOf(name) end

--- Lua-side wrapper for a streaming audio decoder.
---@class LDecoder
LDecoder = {}

--- Decodes the next chunk of samples, or nil at EOF.
---@return SoundData
function LDecoder:decode() end

--- Returns the per-sample bit depth of this decoded audio stream.
---@return number
function LDecoder:getBitDepth() end

--- Returns the number of audio channels.
---@return number
function LDecoder:getChannelCount() end

--- Returns the total duration in seconds.
---@return number
function LDecoder:getDuration() end

--- Returns the sample rate in Hz.
---@return number
function LDecoder:getSampleRate() end

--- Returns true if seeking is supported.
---@return boolean
function LDecoder:isSeekable() end

--- Releases the decoder (no-op).
---@return nil
function LDecoder:release() end

--- Rewinds to the beginning.
---@return nil
function LDecoder:rewind() end

--- Seeks to a time offset in seconds.
---@param offset number
---@return nil
function LDecoder:seek(offset) end

--- Returns the current position in seconds.
---@return number
function LDecoder:tell() end

--- Returns the type name of this object.
---@return string
function LDecoder:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LDecoder:typeOf(name) end

--- Lua-side wrapper for the MIDI player.
---@class LMidiPlayer
LMidiPlayer = {}

--- Returns the assigned bus, or nil.
---@return Bus
function LMidiPlayer:getBus() end

--- Returns the number of MIDI channels.
---@return number
function LMidiPlayer:getChannelCount() end

--- Returns the GM instrument for a MIDI channel (1-indexed).
---@param ch integer
---@return number
function LMidiPlayer:getChannelInstrument(ch) end

--- Returns the volume for a MIDI channel (1-indexed).
---@param ch integer
---@return number
function LMidiPlayer:getChannelVolume(ch) end

--- Returns the PCM output channel count (1 = mono, 2 = stereo).
---@return number
function LMidiPlayer:getChannels() end

--- Returns the total MIDI duration in seconds.
---@return number
function LMidiPlayer:getDuration() end

--- Returns the file path of the loaded MIDI, or nil.
---@return string
function LMidiPlayer:getFilePath() end

--- Returns the total note count in the MIDI sequence.
---@return number
function LMidiPlayer:getNoteCount() end

--- Returns the original MIDI file tempo in BPM.
---@return number
function LMidiPlayer:getOriginalTempo() end

--- Returns the PCM output sample rate in Hz.
---@return number
function LMidiPlayer:getSampleRate() end

--- Returns the SoundFont file path, or nil (stub).
---@return string
function LMidiPlayer:getSoundFontPath() end

--- Returns the current tempo in BPM.
---@return number
function LMidiPlayer:getTempo() end

--- Returns the current tempo scale factor.
---@return number
function LMidiPlayer:getTempoScale() end

--- Returns the PPQ resolution from the MIDI header.
---@return number
function LMidiPlayer:getTicksPerBeat() end

--- Returns the number of tracks in the MIDI sequence.
---@return number
function LMidiPlayer:getTrackCount() end

--- Returns the name of a MIDI track (1-indexed), or nil.
---@param idx integer
---@return string
function LMidiPlayer:getTrackName(idx) end

--- Returns the current MIDI volume.
---@return number
function LMidiPlayer:getVolume() end

--- Returns true if a MIDI channel is muted (1-indexed).
---@param ch integer
---@return boolean
function LMidiPlayer:isChannelMuted(ch) end

--- Returns true if a MIDI sequence is loaded.
---@return boolean
function LMidiPlayer:isLoaded() end

--- Returns true if looping is enabled.
---@return boolean
function LMidiPlayer:isLooping() end

--- Returns true if MIDI playback is paused.
---@return boolean
function LMidiPlayer:isPaused() end

--- Returns true if MIDI is currently playing.
---@return boolean
function LMidiPlayer:isPlaying() end

--- Returns true if a track is muted (1-indexed).
---@param idx integer
---@return boolean
function LMidiPlayer:isTrackMuted(idx) end

--- Loads a MIDI file from the given path.
---@param path string
---@return boolean
function LMidiPlayer:load(path) end

--- Loads MIDI data from a Lua string.
---@param data string
---@return boolean
function LMidiPlayer:loadData(data) end

--- Pauses the MIDI sequence at the current position; resume with `play()`.
---@return nil
function LMidiPlayer:pause() end

--- Starts or resumes MIDI sequence playback from the current position.
---@return nil
function LMidiPlayer:play() end

--- Seeks to a time position in seconds.
---@param secs number
---@return nil
function LMidiPlayer:seek(secs) end

--- Routes MIDI output through a bus (or nil to clear).
---@param bus_val Bus
---@return nil
function LMidiPlayer:setBus(bus_val) end

--- Sets the GM instrument for a MIDI channel (1-indexed).
---@param ch integer
---@param inst integer
---@return nil
function LMidiPlayer:setChannelInstrument(ch, inst) end

--- Mutes or unmutes a MIDI channel (1-indexed).
---@param ch integer
---@param muted boolean
---@return nil
function LMidiPlayer:setChannelMuted(ch, muted) end

--- Sets volume for a MIDI channel (1-indexed).
---@param ch integer
---@param vol number
---@return nil
function LMidiPlayer:setChannelVolume(ch, vol) end

--- Sets the PCM output channel count (clamped 1â€“2).
---@param channels integer
---@return nil
function LMidiPlayer:setChannels(channels) end

--- Enables or disables looping.
---@param looping boolean
---@return nil
function LMidiPlayer:setLooping(looping) end

--- Registers a playback-end callback (stub).
---@param cb function
---@return nil
function LMidiPlayer:setOnEnd(cb) end

--- Registers a note-off callback (stub).
---@param cb function
---@return nil
function LMidiPlayer:setOnNoteOff(cb) end

--- Registers a note-on callback (stub).
---@param cb function
---@return nil
function LMidiPlayer:setOnNoteOn(cb) end

--- Sets the PCM output sample rate in Hz (clamped 8000â€“192000).
---@param rate integer
---@return nil
function LMidiPlayer:setSampleRate(rate) end

--- Loads a SoundFont file into this player (stub).
---@param path string
---@return nil
function LMidiPlayer:setSoundFont(path) end

--- Sets playback tempo in BPM.
---@param bpm number
---@return nil
function LMidiPlayer:setTempo(bpm) end

--- Sets the tempo scale factor (1.0 = original speed).
---@param scale number
---@return nil
function LMidiPlayer:setTempoScale(scale) end

--- Mutes or unmutes a track (1-indexed).
---@param idx integer
---@param muted boolean
---@return nil
function LMidiPlayer:setTrackMuted(idx, muted) end

--- Sets MIDI playback volume.
---@param vol number
---@return nil
function LMidiPlayer:setVolume(vol) end

--- Solos a MIDI channel (1-indexed).
---@param ch integer
---@return nil
function LMidiPlayer:soloChannel(ch) end

--- Stops MIDI playback and resets the playhead to the beginning.
---@return nil
function LMidiPlayer:stop() end

--- Returns the current playback position in seconds.
---@return number
function LMidiPlayer:tell() end

--- Returns the type name of this object.
---@return string
function LMidiPlayer:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LMidiPlayer:typeOf(name) end

--- Clears solo on all channels.
---@return nil
function LMidiPlayer:unsoloAll() end

--- Reverts to the built-in default SoundFont (stub).
---@return nil
function LMidiPlayer:useDefaultSoundFont() end

--- Decoded PCM audio buffer that can be created from a file or synthesised sample-by-sample.
---@class LSoundData
LSoundData = {}

--- Draws the waveform onto an ImageData buffer.
---@param target ImageData
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@return nil
function LSoundData:drawWaveform(target, x, y, w, h, r, g, b, a) end

--- Returns the bit depth of this audio buffer (typically 16 or 32 bits per sample).
---@return number
function LSoundData:getBitDepth() end

--- Get the number of channels.
---@return number
function LSoundData:getChannelCount() end

--- Get the audio duration in seconds.
---@return number
function LSoundData:getDuration() end

--- Get a specific sample by index.
---@param index integer
---@return number
function LSoundData:getSample(index) end

--- Get the total number of samples.
---@return number
function LSoundData:getSampleCount() end

--- Returns the sample rate of this audio buffer in Hz (e.g. 44100 or 48000).
---@return number
function LSoundData:getSampleRate() end

--- Set a specific sample by index.
---@param index integer
---@param value number
---@return nil
function LSoundData:setSample(index, value) end

--- Lua-side wrapper for a polyphonic [`crate::audio::SoundPool`].
---@class LSoundPool
LSoundPool = {}

--- Returns the total number of voices in this pool.
---@return number
function LSoundPool:getVoiceCount() end

--- Plays the next available voice and returns its SoundKey as an integer.
---@return number
function LSoundPool:play() end

--- Releases all voices from the mixer and invalidates this pool.
---@return nil
function LSoundPool:release() end

--- Routes all voices through the named bus.
---@param name string
---@return nil
function LSoundPool:setBus(name) end

--- Sets the volume for all voices in this pool.
---@param vol number
---@return nil
function LSoundPool:setVolume(vol) end

--- Stops all voices in this pool.
---@return nil
function LSoundPool:stopAll() end

--- Returns the type name of this object.
---@return string
function LSoundPool:type() end

--- Returns true if the type name matches.
---@param name string
---@return boolean
function LSoundPool:typeOf(name) end

--- Lua-side wrapper for an audio source resource.
---@class LSource
LSource = {}

--- Removes any active filter from this source.
---@return nil
function LSource:clearFilter() end

--- Creates an independent copy of this source.
---@return Source
function LSource:clone() end

--- Fades in from silence over the given duration in seconds.
---@param dur number
---@return nil
function LSource:fadeIn(dur) end

--- Returns the total duration in seconds.
---@return number
function LSource:getDuration() end

--- Returns the current fade-in duration in seconds.
---@return number
function LSource:getFadeIn() end

--- Returns the high-pass filter cutoff frequency.
---@return number
function LSource:getHighpass() end

--- Returns the low-pass filter cutoff frequency.
---@return number
function LSource:getLowpass() end

--- Returns the current stereo panning value.
---@return number
function LSource:getPan() end

--- Returns the current pitch multiplier.
---@return number
function LSource:getPitch() end

--- Returns the source type ("static" or "stream").
---@return string
function LSource:getType() end

--- Returns the current volume multiplier.
---@return number
function LSource:getVolume() end

--- Returns true if looping is enabled.
---@return boolean
function LSource:isLooping() end

--- Returns true if playback is paused.
---@return boolean
function LSource:isPaused() end

--- Returns true if currently playing.
---@return boolean
function LSource:isPlaying() end

--- Returns true if playback has stopped.
---@return boolean
function LSource:isStopped() end

--- Pauses playback at the current position.
---@return nil
function LSource:pause() end

--- Starts or resumes playback.
---@return nil
function LSource:play() end

--- Resumes playback from the paused position.
---@return nil
function LSource:resume() end

--- Seeks to a time position in seconds.
---@param pos number
---@return nil
function LSource:seek(pos) end

--- Applies a high-pass filter at the given cutoff frequency.
---@param cutoff_hz integer
---@return nil
function LSource:setHighpass(cutoff_hz) end

--- Enables or disables looping playback.
---@param looping boolean
---@return nil
function LSource:setLooping(looping) end

--- Applies a low-pass filter at the given cutoff frequency.
---@param cutoff_hz integer
---@return nil
function LSource:setLowpass(cutoff_hz) end

--- Sets stereo panning (-1.0 left to 1.0 right).
---@param pan number
---@return nil
function LSource:setPan(pan) end

--- Sets the pitch multiplier (1.0 = normal).
---@param pitch number
---@return nil
function LSource:setPitch(pitch) end

--- Sets playback volume (0.0 = silent, 1.0 = full).
---@param vol number
---@return nil
function LSource:setVolume(vol) end

--- Stops playback and resets seek position.
---@return nil
function LSource:stop() end

--- Returns the current playback position in seconds.
---@return number
function LSource:tell() end

--- Returns the type name of this object.
---@return string
function LSource:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSource:typeOf(name) end

--- Adds a DSP effect to a bus.
---@param bus_name string
---@param effect_type string
---@param params? table
---@return number
lurek.audio.add_effect = function(bus_name, effect_type, params) end

--- Applies a bandpass filter (high-pass then low-pass) to a SoundData in-place.
---@param sounddata SoundData
---@param low_hz number
---@param high_hz number
---@return nil
lurek.audio.applyBandpass = function(sounddata, low_hz, high_hz) end

--- Scales every sample by gain (clamped to [-1, 1]).
---@param sounddata SoundData
---@param gain number
---@return nil
lurek.audio.applyGain = function(sounddata, gain) end

--- Applies a first-order IIR high-pass filter to a SoundData in-place.
---@param sounddata SoundData
---@param cutoff_hz number
---@return nil
lurek.audio.applyHighpass = function(sounddata, cutoff_hz) end

--- Applies a first-order IIR low-pass filter to a SoundData in-place.
---@param sounddata SoundData
---@param cutoff_hz number
---@return nil
lurek.audio.applyLowpass = function(sounddata, cutoff_hz) end

--- Removes any active filter from a source.
---@param source Source
---@return nil
lurek.audio.clearFilter = function(source) end

--- Unloads the active SoundFont.
---@return nil
lurek.audio.clearMidiSoundFont = function() end

--- Clears any random pitch range on a source, restoring fixed pitch.
---@param src Source
---@return nil
lurek.audio.clearRandomPitch = function(src) end

--- Creates an independent copy of a source.
---@param source Source
---@return Source
lurek.audio.clone = function(source) end

--- Creates a bus by name (functional style).
---@param name string
---@param parent_name? string
---@return nil
lurek.audio.create_bus = function(name, parent_name) end

--- Crossfades from one source to another over a duration.
---@param from Source
---@param to Source
---@param duration number
---@return nil
lurek.audio.crossfade = function(from, to, duration) end

--- Fades a source in from silence over the given duration.
---@param source Source
---@param dur number
---@return nil
lurek.audio.fadeIn = function(source, dur) end

--- Returns the number of currently playing sources.
---@return number
lurek.audio.getActiveSourceCount = function() end

--- Returns the peak signal level of the named bus (stub: always 0.0).
---@param bus_name string
---@return number
lurek.audio.getBusPeak = function(bus_name) end

--- Returns the RMS signal level of the named bus (stub: always 0.0).
---@param bus_name string
---@return number
lurek.audio.getBusRms = function(bus_name) end

--- Returns the current distance model name.
---@return string
lurek.audio.getDistanceModel = function() end

--- Returns the current Doppler scale.
---@return number
lurek.audio.getDopplerScale = function() end

--- Returns the total duration of a source in seconds.
---@param source Source
---@return number
lurek.audio.getDuration = function(source) end

--- Returns the fade-in duration of a source.
---@param source Source
---@return number
lurek.audio.getFadeIn = function(source) end

--- Returns the free buffer slots in a queueable source.
---@param qsource_id integer
---@return number
lurek.audio.getFreeBufferCount = function(qsource_id) end

--- Returns the high-pass filter cutoff of a source.
---@param source Source
---@return number
lurek.audio.getHighpass = function(source) end

--- Returns the 3D listener position (x, y, z).
---@return number
---@return number
---@return number
lurek.audio.getListener = function() end

--- Returns the 2D listener position (x, y).
---@return number
---@return number
lurek.audio.getListener2D = function() end

--- Returns the low-pass filter cutoff of a source.
---@param source Source
---@return number
lurek.audio.getLowpass = function(source) end

--- Returns the global master volume.
---@return number
lurek.audio.getMasterVolume = function() end

--- Returns the maximum number of simultaneous sources.
---@return number
lurek.audio.getMaxSources = function() end

--- Returns the stored master peak meter level.
---@return table
lurek.audio.getMeter = function() end

--- Returns the 6-component orientation of a source.
---@param source Source
---@return table
lurek.audio.getOrientation = function(source) end

--- Returns the source stereo panning.
---@param source Source
---@return number
lurek.audio.getPan = function(source) end

--- Returns the source pitch multiplier.
---@param source Source
---@return number
lurek.audio.getPitch = function(source) end

--- Returns the current audio output device name.
---@return string
lurek.audio.getPlaybackDevice = function() end

--- Returns a table of available audio output device names.
---@return table
lurek.audio.getPlaybackDevices = function() end

--- Returns the 3D position of a source (x, y, z).
---@param source Source
---@return number
---@return number
---@return number
lurek.audio.getPosition = function(source) end

--- Returns the bus a source is assigned to, or nil.
---@param source Source
---@return Bus
lurek.audio.getSourceBus = function(source) end

--- Returns the total number of registered sources.
---@return number
lurek.audio.getSourceCount = function() end

--- Returns the type string ("static" or "stream") of a source.
---@param source Source
---@return string
lurek.audio.getSourceType = function(source) end

--- Returns the current stereo width for a source.
---@param src Source
---@return number
lurek.audio.getStereoWidth = function(src) end

--- Returns the velocity of a source (x, y, z).
---@param source Source
---@return number
---@return number
---@return number
lurek.audio.getVelocity = function(source) end

--- Returns the source volume.
---@param source Source
---@return number
lurek.audio.getVolume = function(source) end

--- Returns true if a SoundFont is loaded.
---@return boolean
lurek.audio.hasMidiSoundFont = function() end

--- Returns true if looping is enabled.
---@param source Source
---@return boolean
lurek.audio.isLooping = function(source) end

--- Returns true if the source is paused.
---@param source Source
---@return boolean
lurek.audio.isPaused = function(source) end

--- Returns true if the source is playing.
---@param source Source
---@return boolean
lurek.audio.isPlaying = function(source) end

--- Returns true if the source is stopped.
---@param source Source
---@return boolean
lurek.audio.isStopped = function(source) end

--- Additively mixes another SoundData into the destination in-place.
---@param dest SoundData
---@param src SoundData
---@return nil
lurek.audio.mixInto = function(dest, src) end

--- Creates a named audio bus for grouping sources.
---@param name string
---@return Bus
lurek.audio.newBus = function(name) end

--- Creates a streaming audio decoder.
---@param source string
---@param buffersize? integer
---@return Decoder
lurek.audio.newDecoder = function(source, buffersize) end

--- Creates a MIDI player, optionally loading a file.
---@param path? string
---@return MidiPlayer
lurek.audio.newMidiPlayer = function(path) end

--- Creates a polyphonic sound pool for the given file with N simultaneous voices.
---@param file_path string
---@param voice_count integer
---@return SoundPool
lurek.audio.newPool = function(file_path, voice_count) end

--- Creates a queueable source for manual PCM buffering.
---@param sample_rate integer
---@param bit_depth integer
---@param channels integer
---@param buffer_count? integer
---@return number
lurek.audio.newQueueableSource = function(sample_rate, bit_depth, channels, buffer_count) end

--- Generate a mono sawtooth-wave SoundData buffer.
---@param freq number
---@param duration number
---@param sampleRate number
---@param amplitude number
---@return SoundData
lurek.audio.newSawtoothWave = function(freq, duration, sampleRate, amplitude) end

--- Generate a mono sine-wave SoundData buffer.
---@param freq number
---@param duration number
---@param sampleRate number
---@param amplitude number
---@return SoundData
lurek.audio.newSineWave = function(freq, duration, sampleRate, amplitude) end

--- Creates a SoundData from a file or as a silent buffer.
---@param ... string|integer
---@return SoundData
lurek.audio.newSoundData = function(...) end

--- Loads an audio file and returns a Source handle.
---@param ... string
---@return Source
lurek.audio.newSource = function(...) end

--- Generate a mono square-wave SoundData buffer.
---@param freq number
---@param duration number
---@param sampleRate number
---@param amplitude number
---@return SoundData
lurek.audio.newSquareWave = function(freq, duration, sampleRate, amplitude) end

--- Generate a mono triangle-wave SoundData buffer.
---@param freq number
---@param duration number
---@param sampleRate number
---@param amplitude number
---@return SoundData
lurek.audio.newTriangleWave = function(freq, duration, sampleRate, amplitude) end

--- Generate a reproducible white-noise SoundData buffer.
---@param duration number
---@param sampleRate number
---@param amplitude number
---@param seed integer
---@return SoundData
lurek.audio.newWhiteNoise = function(duration, sampleRate, amplitude, seed) end

--- Normalizes a WAV file peak amplitude to target_level and writes output.
---@param input_path string
---@param output_path string
---@param target_level number
---@return nil
lurek.audio.normalizeFile = function(input_path, output_path, target_level) end

--- Pauses playback at the current position.
---@param source Source
---@return nil
lurek.audio.pause = function(source) end

--- Pauses all currently playing sources.
---@return nil
lurek.audio.pauseAll = function() end

--- Plays a source, with optional bus routing via options table.
---@param source Source
---@param options? table
---@return number
lurek.audio.play = function(source, options) end

--- Plays the source in a continuous loop.
---@param source Source
---@return nil
lurek.audio.playLooping = function(source) end

--- Starts playback of a queueable source.
---@param qsource_id integer
---@return nil
lurek.audio.playQueueable = function(qsource_id) end

--- Applies a DSP effect chain to a WAV file and writes output.
---@param input_path string
---@param output_path string
---@param effects table
---@return nil
lurek.audio.processOffline = function(input_path, output_path, effects) end

--- Pushes a SoundData buffer into a queueable source.
---@param qsource_id integer
---@param sounddata SoundData
---@return nil
lurek.audio.queueSource = function(qsource_id, sounddata) end

--- Releases a source and frees its memory.
---@param source Source
---@return boolean
lurek.audio.release = function(source) end

--- Removes a DSP effect from a bus.
---@param bus_name string
---@param effect_id integer
---@return boolean
lurek.audio.remove_effect = function(bus_name, effect_id) end

--- Resumes playback from pause.
---@param source Source
---@return nil
lurek.audio.resume = function(source) end

--- Resumes all paused sources.
---@return nil
lurek.audio.resumeAll = function() end

--- Saves a SoundData as a 16-bit PCM WAV file at the given path.
---@param sounddata SoundData
---@param path string
---@return nil
lurek.audio.saveWAV = function(sounddata, path) end

--- Seeks to a time position in seconds.
---@param source Source
---@param pos number
---@return nil
lurek.audio.seek = function(source, pos) end

--- Sets the distance attenuation model.
---@param model string
---@return nil
lurek.audio.setDistanceModel = function(model) end

--- Sets the global Doppler effect scale.
---@param scale number
---@return nil
lurek.audio.setDopplerScale = function(scale) end

--- Applies a high-pass filter to a source.
---@param source Source
---@param cutoff_hz integer
---@return nil
lurek.audio.setHighpass = function(source, cutoff_hz) end

--- Sets the 3D listener position.
---@param x number
---@param y number
---@param z? number
---@return nil
lurek.audio.setListener = function(x, y, z) end

--- Sets the 2D listener position for spatial audio.
---@param x number
---@param y number
---@return nil
lurek.audio.setListener2D = function(x, y) end

--- Enables or disables looping.
---@param source Source
---@param looping boolean
---@return nil
lurek.audio.setLooping = function(source, looping) end

--- Applies a low-pass filter to a source.
---@param source Source
---@param cutoff_hz integer
---@return nil
lurek.audio.setLowpass = function(source, cutoff_hz) end

--- Sets the global master volume.
---@param vol number
---@return nil
lurek.audio.setMasterVolume = function(vol) end

--- Sets the master peak meter level (0.0â€“1.0).
---@param level number
---@return nil
lurek.audio.setMeter = function(level) end

--- Sets the global SoundFont for MIDI synthesis.
---@param path string
---@return nil
lurek.audio.setMidiSoundFont = function(path) end

--- Sets the 6-component orientation of a source.
---@param source Source
---@param fx number
---@param fy number
---@param fz number
---@param ux number
---@param uy number
---@param uz number
---@return nil
lurek.audio.setOrientation = function(source, fx, fy, fz, ux, uy, uz) end

--- Sets stereo panning (-1.0 left to 1.0 right).
---@param source Source
---@param pan number
---@return nil
lurek.audio.setPan = function(source, pan) end

--- Sets source pitch multiplier.
---@param source Source
---@param pitch number
---@return nil
lurek.audio.setPitch = function(source, pitch) end

--- Selects an audio output device by name.
---@param name string
---@return nil
lurek.audio.setPlaybackDevice = function(name) end

--- Sets the 3D position of a source.
---@param source Source
---@param x number
---@param y number
---@param z? number
---@return nil
lurek.audio.setPosition = function(source, x, y, z) end

--- Sets a random pitch range applied each time the source is played.
---@param src Source
---@param min number
---@param max number
---@return nil
lurek.audio.setRandomPitch = function(src, min, max) end

--- Assigns a source to a bus.
---@param source Source
---@param bus Bus
---@return nil
lurek.audio.setSourceBus = function(source, bus) end

--- Sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono).
---@param src Source
---@param width number
---@return nil
lurek.audio.setStereoWidth = function(src, width) end

--- Sets the velocity of a source for Doppler.
---@param source Source
---@param x number
---@param y number
---@param z? number
---@return nil
lurek.audio.setVelocity = function(source, x, y, z) end

--- Sets source playback volume.
---@param source Source
---@param vol number
---@return nil
lurek.audio.setVolume = function(source, vol) end

--- Sets a bus volume by name.
---@param name string
---@param volume number
---@return nil
lurek.audio.set_bus_volume = function(name, volume) end

--- Sets a parameter on a DSP effect.
---@param bus_name string
---@param effect_id integer
---@param param_name string
---@param value number
---@return boolean
lurek.audio.set_effect_param = function(bus_name, effect_id, param_name, value) end

--- Renders a time-frequency spectrogram of a WAV file to a PNG image.
---@param input_wav string
---@param output_png string
---@param width integer
---@param height integer
---@return nil
lurek.audio.spectrogramToPng = function(input_wav, output_png, width, height) end

--- Stops playback and resets seek position.
---@param source Source
---@return nil
lurek.audio.stop = function(source) end

--- Stops all currently playing sources.
---@return nil
lurek.audio.stopAll = function() end

--- Stops a queueable source and drains its buffers.
---@param qsource_id integer
---@return nil
lurek.audio.stopQueueable = function(qsource_id) end

--- Returns the current playback position in seconds.
---@param source Source
---@return number
lurek.audio.tell = function(source) end

--- Renders the waveform of a WAV file to a PNG image.
---@param input_wav string
---@param output_png string
---@param width integer
---@param height integer
---@return nil
lurek.audio.waveformToPng = function(input_wav, output_png, width, height) end

---@class lurek.simulator
lurek.simulator = {}

--- Returns the name of the active script, or nil if idle.
---@return string
lurek.simulator.getCurrentScript = function() end

--- Returns the index of the next step to be dispatched.
---@return number
lurek.simulator.getCurrentStep = function() end

--- Returns seconds elapsed since playback started.
---@return number
lurek.simulator.getElapsedTime = function() end

--- Returns the current playback speed multiplier (default 1.0).
---@return number
lurek.simulator.getPlaybackSpeed = function() end

--- Returns an array of all registered script names.
---@return table
lurek.simulator.getScripts = function() end

--- Returns the total number of steps in the active script.
---@return number
lurek.simulator.getStepCount = function() end

--- Returns the step limit for the named script, or nil if not found.
---@param name string
---@return number
lurek.simulator.getStepLimit = function(name) end

--- Returns true if a macro with the given name has been saved.
---@param name string
---@return boolean
lurek.simulator.hasMacro = function(name) end

--- Returns true if a script with the given name is registered.
---@param name string
---@return boolean
lurek.simulator.hasScript = function(name) end

--- Returns true if all steps in the active script have been dispatched.
---@return boolean
lurek.simulator.isComplete = function() end

--- Returns whether the highlight overlay hint is active.
---@return boolean
lurek.simulator.isHighlightMode = function() end

--- Returns true if playback is currently paused.
---@return boolean
lurek.simulator.isPaused = function() end

--- Returns true if the simulator is actively playing a script.
---@return boolean
lurek.simulator.isRunning = function() end

--- Returns an array of all saved macro names.
---@return table
lurek.simulator.listMacros = function() end

--- Loads a named script from a Lua data table containing a steps array.
---@param name string
---@param data table
---@return nil
lurek.simulator.load = function(name, data) end

--- Parses a TOML string and registers it as a named script.
---@param name string
---@param toml_str string
---@return nil
lurek.simulator.loadFromToml = function(name, toml_str) end

--- Pauses playback at the current step position.
---@return nil
lurek.simulator.pause = function() end

--- Loads and starts playback of a previously saved macro.
---@param name string
---@return nil
lurek.simulator.playMacro = function(name) end

--- Resumes playback from a paused position.
---@return nil
lurek.simulator.resume = function() end

--- Saves a currently-loaded script under a macro name for fast replay.
---@param macro_name string
---@param script_name string
---@return nil
lurek.simulator.saveMacro = function(macro_name, script_name) end

--- Enables or disables the highlight overlay hint.
---@param enable boolean
---@return nil
lurek.simulator.setHighlightMode = function(enable) end

--- Sets the dt multiplier for script playback (0.5 = half speed, 2.0 = double).
---@param factor number
---@return nil
lurek.simulator.setPlaybackSpeed = function(factor) end

--- Sets the step limit for the named script (clamped to 1..MAX_STEPS).
---@param name string
---@param n integer
---@return boolean
lurek.simulator.setStepLimit = function(name, n) end

--- Starts playback of the named script from the beginning.
---@param name string
---@return nil
lurek.simulator.start = function(name) end

--- Stops playback and resets the simulator to idle.
---@return nil
lurek.simulator.stop = function() end

--- Removes a loaded script by name, returning true if it existed.
---@param name string
---@return boolean
lurek.simulator.unload = function(name) end

--- Advances the playback clock by `dt` seconds, dispatching due steps.
---@param dt number
---@return nil
lurek.simulator.update = function(dt) end

--- Pauses playback advancement until predicate() returns true or timeout seconds elapse.
---@param predicate function -- must return boolean
---@param timeout number -- maximum seconds to wait before auto-resuming
---@return nil
lurek.simulator.waitUntil = function(predicate, timeout) end

---@class lurek.camera
lurek.camera = {}

--- Lua-side wrapper around a [`Camera2D`] instance.
---@class LCamera
LCamera = {}

--- Applies this camera's transform to the render stack.
---@return nil
function LCamera:apply() end

--- Alias for `apply()`. Applies this camera's transform to the render stack.
---@return nil
function LCamera:attach() end

--- Removes all parallax factor overrides.
---@return nil
function LCamera:clearParallaxFactors() end

--- Clears the follow target so the camera stops tracking.
---@return nil
function LCamera:clearTarget() end

--- Alias for `reset()`. Pops the camera transform from the render stack.
---@return nil
function LCamera:detach() end

--- Animates the camera along a sequence of world-space waypoints over
---@param points table
---@param duration number
---@return nil
function LCamera:followPath(points, duration) end

--- Returns the current sway x, y world-space offset.
---@return number
---@return number
function LCamera:getEffectOffset() end

--- Returns the current zoom level including zoom pulse and breathing deltas.
---@return number
function LCamera:getEffectiveZoom() end

--- Returns the parallax factor for the named layer, or `1.0` if unset.
---@param layer string
---@return number
function LCamera:getParallaxFactor(layer) end

--- Returns the camera's world-space position as x, y.
---@return number
---@return number
function LCamera:getPosition() end

--- Returns the rotation in radians.
---@return number
function LCamera:getRotation() end

--- Returns the current viewport as x, y, w, h.
---@return number
---@return number
---@return number
---@return number
function LCamera:getViewport() end

--- Returns the visible world area as x, y, w, h.
---@return number
---@return number
---@return number
---@return number
function LCamera:getVisibleArea() end

--- Returns the current zoom factor.
---@return number
function LCamera:getZoom() end

--- Returns true if the breathing effect is currently active.
---@return boolean
function LCamera:isBreathing() end

--- Returns true if the sway effect is currently active.
---@return boolean
function LCamera:isSway() end

--- Instantly moves the camera to look at the given position.
---@param x number
---@param y number
---@return nil
function LCamera:lookAt(x, y) end

--- Translates the camera by dx, dy in world space.
---@param dx number
---@param dy number
---@return nil
function LCamera:move(dx, dy) end

--- Returns the fractional progress `[0, 1]` of the active path, or
---@return number
function LCamera:pathProgress() end

--- Removes previously set world-space bounds.
---@return nil
function LCamera:removeBounds() end

--- Pops the camera transform from the render stack.
---@return nil
function LCamera:reset() end

--- Sets world-space bounds for camera clamping.
---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function LCamera:setBounds(x, y, w, h) end

--- Sets the dead zone half-extents for camera follow.
---@param w number
---@param h number
---@return nil
function LCamera:setDeadZone(w, h) end

--- Sets the follow smooth interpolation speed (0.0 = instant snap).
---@param speed number
---@return nil
function LCamera:setFollowSmooth(speed) end

--- Sets the look-ahead multiplier for follow prediction.
---@param mul number
---@return nil
function LCamera:setLookAhead(mul) end

--- Sets the parallax scroll factor for the named render layer.
---@param layer string
---@param factor number
---@return nil
function LCamera:setParallaxFactor(layer, factor) end

--- Sets the camera's world-space position.
---@param x number
---@param y number
---@return nil
function LCamera:setPosition(x, y) end

--- Sets the rotation in radians.
---@param r number
---@return nil
function LCamera:setRotation(r) end

--- Sets the follow target position.
---@param x number
---@param y number
---@return nil
function LCamera:setTarget(x, y) end

--- Sets the viewport rectangle in screen pixels.
---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function LCamera:setViewport(x, y, w, h) end

--- Sets the uniform zoom factor (1.0 = natural size).
---@param zoom number
---@return nil
function LCamera:setZoom(zoom) end

--- Starts a screen-shake effect.
---@param intensity number
---@param duration number
---@return nil
function LCamera:shake(intensity, duration) end

--- Starts a subtle periodic zoom oscillation for a "living camera" feel.
---@param amplitude? number
---@param rate? number
---@return nil
function LCamera:startBreathing(amplitude, rate) end

--- Starts a sinusoidal x/y offset oscillation (e.g., boat rocking).
---@param amplitude_x number
---@param amplitude_y number
---@param frequency number
---@param decay? number
---@return nil
function LCamera:startSway(amplitude_x, amplitude_y, frequency, decay) end

--- Stops the active breathing effect.
---@return nil
function LCamera:stopBreathing() end

--- Cancels the active camera path animation.
---@return nil
function LCamera:stopPath() end

--- Stops the active sway effect immediately.
---@return nil
function LCamera:stopSway() end

--- Cancels the active zoom tween.
---@return nil
function LCamera:stopZoom() end

--- Converts world coordinates to screen coordinates.
---@param wx number
---@param wy number
---@return number
---@return number
function LCamera:toScreen(wx, wy) end

--- Converts screen coordinates to world coordinates.
---@param sx number
---@param sy number
---@return number
---@return number
function LCamera:toWorld(sx, sy) end

--- Returns the type name of this object.
---@return string
function LCamera:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LCamera:typeOf(name) end

--- Advances the camera simulation by dt seconds.
---@param dt number
---@return nil
function LCamera:update(dt) end

--- Advances the path animation by `dt` seconds and applies the
---@param dt number
---@return boolean
function LCamera:updatePath(dt) end

--- Advances the zoom tween by `dt` seconds and applies the resulting
---@param dt number
---@return boolean
function LCamera:updateZoom(dt) end

--- Triggers a momentary zoom-in that decays back via a sine envelope.
---@param amplitude number
---@param duration number
---@return nil
function LCamera:zoomPulse(amplitude, duration) end

--- Smoothly tweens the camera zoom from its current level to
---@param target_zoom number
---@param duration number
---@return nil
function LCamera:zoomTo(target_zoom, duration) end

--- Creates a new Camera2D with the given viewport dimensions.
---@param viewport_w? number
---@param viewport_h? number
---@return Camera2D
lurek.camera.new = function(viewport_w, viewport_h) end

--- Creates a new 2D camera with the given viewport dimensions.
---@param viewport_w? number
---@param viewport_h? number
---@return Camera2D
lurek.camera.newCamera = function(viewport_w, viewport_h) end

---@class lurek.compute
lurek.compute = {}

--- Lua-side wrapper around [`NdArray`].
---@class LArray
LArray = {}

--- Element-wise absolute value.
---@return Array
function LArray:abs() end

--- Returns true if all elements are nonzero.
---@return boolean
function LArray:all() end

--- Returns true if any element is nonzero.
---@return boolean
function LArray:any() end

--- Returns the 1-based flat index of the maximum element.
---@return number
function LArray:argmax() end

--- Returns the 1-based flat index of the minimum element.
---@return number
function LArray:argmin() end

--- Bitwise AND of two Int32 arrays.
---@param other Array
---@return Array
function LArray:bitwiseAnd(other) end

--- Bitwise left shift of an Int32 array.
---@param amount integer
---@return Array
function LArray:bitwiseLShift(amount) end

--- Bitwise NOT of an Int32 array.
---@return Array
function LArray:bitwiseNot() end

--- Bitwise OR of two Int32 arrays.
---@param other Array
---@return Array
function LArray:bitwiseOr(other) end

--- Bitwise right shift of an Int32 array.
---@param amount integer
---@return Array
function LArray:bitwiseRShift(amount) end

--- Bitwise XOR of two Int32 arrays.
---@param other Array
---@return Array
function LArray:bitwiseXor(other) end

--- Clamps each element to the given range.
---@param min number
---@param max number
---@return Array
function LArray:clamp(min, max) end

--- Returns a deep copy of this array.
---@return Array
function LArray:clone() end

--- 1D convolution with a kernel array (full output).
---@param kernel Array
---@return Array
function LArray:convolve1d(kernel) end

--- 2D convolution with zero-padding.
---@param kernel Array
---@return Array
function LArray:convolve2D(kernel) end

--- 1D cross-correlation with a template array (valid output).
---@param template Array
---@return Array
function LArray:correlate1d(template) end

--- Returns the count of nonzero elements.
---@return number
function LArray:countNonZero() end

--- Population covariance with another 1D array.
---@param other Array
---@return number
function LArray:covariance(other) end

--- Signed 2D cross product with another length-2 array.
---@param other Array
---@return number
function LArray:cross2d(other) end

--- Cumulative sum of all elements (flattened).
---@return Array
function LArray:cumsum() end

--- Discrete difference applied `order` times.
---@param order? integer
---@return Array
function LArray:diff(order) end

--- Morphological dilation with a diamond structuring element.
---@param radius integer
---@return Array
function LArray:dilate(radius) end

--- Dot product of two 1D arrays.
---@param other Array
---@return number
function LArray:dot(other) end

--- Computes the dominant eigenvalue and its eigenvector using power iteration.
---@param max_iter? integer
---@param tol? number?(default 1e-10)
---@return table
function LArray:eigenPower(max_iter, tol) end

--- Morphological erosion with a diamond structuring element.
---@param radius integer
---@return Array
function LArray:erode(radius) end

--- Evaluate a Lua expression string element-wise, returning a new Array.
---@param expr string — Lua expression using `x` as the input variable
---@return Array — new array with transformed values
function LArray:eval(expr) end

--- Fills all elements with the given value in-place.
---@param val number
---@return nil
function LArray:fill(val) end

--- Flood fill from a 1-based (row, col) with a new value.
---@param row integer
---@param col integer
---@param val number
---@return Array
function LArray:floodFill(row, col, val) end

--- Returns the element at the given 1-based indices.
---@param ... integer
---@return number
function LArray:get(...) end

--- Returns the element data type name.
---@return string
function LArray:getDataType() end

--- Returns the number of dimensions.
---@return number
function LArray:getDimensions() end

--- Extracts a rectangular sub-region (1-based row, col).
---@param row integer
---@param col integer
---@param rows integer
---@param cols integer
---@return Array
function LArray:getRegion(row, col, rows, cols) end

--- Returns the shape as a table of dimension sizes.
---@return table
function LArray:getShape() end

--- Returns the total number of elements.
---@return number
function LArray:getSize() end

--- Compute a histogram. Returns a table of {lo, hi, count} tables.
---@param bins integer
---@param lo? number
---@param hi? number
---@return table
function LArray:histogram(bins, lo, hi) end

--- Returns false (CPU arrays only).
---@return boolean
function LArray:isOnGPU() end

--- Solve AÂ·x = b where this array is A (square [n,n]) and b is a 1D vector.
---@param b Array
---@return Array
function LArray:linsolve(b) end

--- Decomposes this square matrix into L and U factors with partial pivoting.
---@return table
function LArray:luDecompose() end

--- Apply a Lua callback element-wise, returning a new Array of the same shape.
---@param fn function(value: number)→ number — called for each element
---@return Array — new array with transformed values
function LArray:map(fn) end

--- Matrix multiplication of two 2D arrays.
---@param other Array
---@return Array
function LArray:matmul(other) end

--- Maximum of all elements, or along an axis (1-based).
---@param axis? integer
---@return nil
function LArray:max(axis) end

--- Mean of all elements, or along an axis (1-based).
---@param axis? integer
---@return nil
function LArray:mean(axis) end

--- Minimum of all elements, or along an axis (1-based).
---@param axis? integer
---@return nil
function LArray:min(axis) end

--- Returns a new Array with every element negated (multiplied by â’1).
---@return Array
function LArray:neg() end

--- Linearly rescale values to [out_min, out_max].
---@param out_min number
---@param out_max number
---@return Array
function LArray:normalizeRange(out_min, out_max) end

--- L2-normalise a 1D vector.
---@return Array
function LArray:normalizeVec() end

--- Outer product of two 1D vectors â†’ 2D array [m, n].
---@param other Array
---@return Array
function LArray:outer(other) end

--- Pearson correlation coefficient with another 1D array.
---@param other Array
---@return number
function LArray:pearsonCorr(other) end

--- Compute the p-th percentile (0â€“100).
---@param p number
---@return number
function LArray:percentile(p) end

--- Raises each element to a scalar exponent.
---@param exp number
---@return Array
function LArray:pow(exp) end

--- Fold the array left-to-right with an accumulator.
---@param fn function(acc: number,value: number)→ number — accumulator function
---@param init number — initial accumulator value
---@return number
function LArray:reduce(fn, init) end

--- Returns a new array with the given shape and the same data.
---@param shape table
---@return Array
function LArray:reshape(shape) end

--- Running accumulation — like reduce but returns every intermediate result.
---@param fn function(acc: number,value: number)→ number — accumulator function
---@param init number — initial accumulator value
---@return Array — array of cumulative values(same length as input)
function LArray:scan(fn, init) end

--- Sets the element at the given 1-based indices to a value.
---@param ... number
---@return nil
function LArray:set(...) end

--- Copies a source array into this array at the given 1-based position.
---@param row integer
---@param col integer
---@param source Array
---@return nil
function LArray:setRegion(row, col, source) end

--- Apply Sobel edge detection to a 2D array. Returns {gx=Array, gy=Array}.
---@return table
function LArray:sobel() end

--- Element-wise square root.
---@return Array
function LArray:sqrt() end

--- Sum of all elements, or along an axis (1-based).
---@param axis? integer
---@return nil
function LArray:sum(axis) end

--- Returns a mask array with 1.0 where elements >= val, else 0.0.
---@param val number
---@return Array
function LArray:threshold(val) end

--- Returns all elements as a flat table of numbers.
---@return table
function LArray:toTable() end

--- Apply this 2Ă—2 or 3Ă—3 matrix to an [N,2] points array.
---@param points Array
---@return Array
function LArray:transformPoints(points) end

--- Returns the transposed 2D array.
---@return Array
function LArray:transpose() end

--- Returns the type name "Array".
---@return string
function LArray:type() end

--- Returns true when the given name matches "Array" or a parent type.
---@param name string
---@return boolean
function LArray:typeOf(name) end

--- Selects elements from this where mask is nonzero, else from other.
---@param mask Array
---@param other Array
---@return Array
function LArray:where(mask, other) end

--- Standardise values to zero mean and unit variance.
---@return Array
function LArray:zscore() end

--- Creates a 3Ă—3 homogeneous affine matrix.
---@param tx number
---@param ty number
---@param angle_rad number
---@param sx number
---@param sy number
---@return Array
lurek.compute.affine2d = function(tx, ty, angle_rad, sx, sy) end

--- Computes the discrete Fourier transform of a 1D real-valued sample array.
---@param samples table
---@return table
lurek.compute.fft = function(samples) end

--- Returns the magnitude spectrum `|X[k]|` of a real-valued sample array.
---@param samples table
---@return table
lurek.compute.fftMagnitude = function(samples) end

--- Creates an array from a Lua table of numbers with optional shape and dtype.
---@param data table
---@param shape? table
---@param dtype? string
---@return Array
lurek.compute.fromTable = function(data, shape, dtype) end

--- Creates a sizeĂ—size Gaussian kernel array.
---@param size integer
---@param sigma number
---@return Array
lurek.compute.gaussianKernel = function(size, sigma) end

--- Computes the inverse discrete Fourier transform.
---@param freqs table
---@return table
lurek.compute.ifft = function(freqs) end

--- Creates a zero-initialized array with the given shape and optional dtype.
---@param shape table
---@param dtype? string
---@return Array
lurek.compute.newArray = function(shape, dtype) end

--- Creates a one-filled array with the given shape and optional dtype.
---@param shape table
---@param dtype? string
---@return Array
lurek.compute.ones = function(shape, dtype) end

--- Creates a 1D array from start to stop with optional step and dtype.
---@param start number
---@param stop number
---@param step? number
---@param dtype? string
---@return Array
lurek.compute.range = function(start, stop, step, dtype) end

--- Creates a 2Ă—2 rotation matrix for the given angle in radians.
---@param angle_rad number
---@return Array
lurek.compute.rotate2dMatrix = function(angle_rad) end

--- Creates a zero-filled array with the given shape and optional dtype.
---@param shape table
---@param dtype? string
---@return Array
lurek.compute.zeros = function(shape, dtype) end

---@class lurek.data
lurek.data = {}

--- Raw byte buffer for binary I/O; addressable by byte or bit offset.
---@class LByteData
LByteData = {}

--- Creates an independent copy of this byte buffer with identical contents.
---@return ByteData
function LByteData:clone() end

--- Returns the value of a single bit within the buffer.
---@param byte_offset integer
---@param bit_offset integer
---@return boolean
function LByteData:getBit(byte_offset, bit_offset) end

--- Get a byte at the specified offset.
---@param offset integer
---@return number
function LByteData:getByte(offset) end

--- Returns the total byte length of this buffer.
---@return number
function LByteData:getSize() end

--- Get the string representation.
---@return string
function LByteData:getString() end

--- Reads `count` consecutive bits starting at `byte_offset`/`bit_offset`
---@param byte_offset integer
---@param bit_offset integer
---@param count integer
---@return nil
function LByteData:readBits(byte_offset, bit_offset, count) end

--- Sets or clears a single bit within the buffer.
---@param byte_offset integer
---@param bit_offset integer
---@param value boolean
---@return nil
function LByteData:setBit(byte_offset, bit_offset, value) end

--- Set a byte at the specified offset.
---@param offset integer
---@param value integer
---@return nil
function LByteData:setByte(offset, value) end

--- Access structured binary data efficiently without copying.
---@class LDataView
LDataView = {}

--- Reads a 64-bit float at the given offset.
---@param offset integer
---@return number
function LDataView:getDouble(offset) end

--- Reads a 32-bit float at the given offset.
---@param offset integer
---@return number
function LDataView:getFloat(offset) end

--- Reads a signed 16-bit integer at the given offset.
---@param offset integer
---@return number
function LDataView:getInt16(offset) end

--- Reads a signed 32-bit integer at the given offset.
---@param offset integer
---@return number
function LDataView:getInt32(offset) end

--- Reads a signed 8-bit integer at the given offset.
---@param offset integer
---@return number
function LDataView:getInt8(offset) end

--- Returns the size of this view in bytes.
---@return number
function LDataView:getSize() end

--- Reads an unsigned 16-bit integer at the given offset.
---@param offset integer
---@return number
function LDataView:getUInt16(offset) end

--- Reads an unsigned 32-bit integer at the given offset.
---@param offset integer
---@return number
function LDataView:getUInt32(offset) end

--- Reads an unsigned 8-bit integer at the given offset.
---@param offset integer
---@return number
function LDataView:getUInt8(offset) end

--- Returns the type name of this object.
---@return string
function LDataView:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LDataView:typeOf(name) end

--- Write-cursor wrapper for the `lurek.data` module.
---@class LDataWriter
LDataWriter = {}

--- Returns the total buffer length.
---@return number
function LDataWriter:len() end

--- Moves the write cursor to the given position.
---@param pos integer
function LDataWriter:seek(pos) end

--- Returns the current write cursor position.
---@return number
function LDataWriter:tell() end

--- Returns the buffer contents as a Lua string.
---@return string
function LDataWriter:toBytes() end

--- Returns the type name of this object.
---@return string
function LDataWriter:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LDataWriter:typeOf(name) end

--- Writes raw bytes from a Lua string.
---@param value string
function LDataWriter:writeBytes(value) end

--- Writes a 32-bit LE float.
---@param value number
function LDataWriter:writeF32LE(value) end

--- Writes a 64-bit LE float.
---@param value number
function LDataWriter:writeF64LE(value) end

--- Writes a signed 16-bit LE integer.
---@param value integer
function LDataWriter:writeI16LE(value) end

--- Writes a signed 32-bit LE integer.
---@param value integer
function LDataWriter:writeI32LE(value) end

--- Writes a signed 8-bit integer.
---@param value integer
function LDataWriter:writeI8(value) end

--- Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
---@param value string
function LDataWriter:writeString(value) end

--- Writes an unsigned 16-bit BE integer.
---@param value integer
function LDataWriter:writeU16BE(value) end

--- Writes an unsigned 16-bit LE integer.
---@param value integer
function LDataWriter:writeU16LE(value) end

--- Writes an unsigned 32-bit LE integer.
---@param value integer
function LDataWriter:writeU32LE(value) end

--- Writes an unsigned 8-bit integer.
---@param value integer
function LDataWriter:writeU8(value) end

--- Lua-side fixed-capacity ring buffer that holds any Lua value.
---@class LRingBuffer
LRingBuffer = {}

--- Returns the maximum number of elements the buffer can hold.
---@return number
function LRingBuffer:capacity() end

--- Removes all elements from the buffer, releasing their registry entries.
---@return nil
function LRingBuffer:clear() end

--- Returns true if the buffer contains no elements.
---@return boolean
function LRingBuffer:isEmpty() end

--- Returns true if the buffer has reached its capacity.
---@return boolean
function LRingBuffer:isFull() end

--- Returns the number of elements currently in the buffer.
---@return number
function LRingBuffer:len() end

--- Returns the oldest element without removing it, or nil if empty.
---@return table
function LRingBuffer:peek() end

--- Returns the newest element without removing it, or nil if empty.
---@return table
function LRingBuffer:peekNewest() end

--- Removes and returns the oldest element, or nil if the buffer is empty.
---@return table
function LRingBuffer:pop() end

--- Pushes a value onto the ring buffer.
---@param value any
---@return boolean
function LRingBuffer:push(value) end

--- Returns all elements as an array table ordered oldest-first.
---@return table
function LRingBuffer:toTable() end

--- Returns the type name of this object.
---@return string
function LRingBuffer:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LRingBuffer:typeOf(name) end

--- Compresses data using the given algorithm (deflate, gzip, lz4).
---@param format string
---@param data string
---@param level? integer
---@return string
lurek.data.compress = function(format, data, level) end

--- Returns the CRC-32 checksum of the input data as an integer.
---@param data string
---@return number
lurek.data.crc32 = function(data) end

--- Decodes encoded text back to binary (base64, hex).
---@param format string
---@param encoded string
---@return string
lurek.data.decode = function(format, encoded) end

--- Decompresses data using the given algorithm (deflate, gzip, lz4).
---@param format string
---@param data string
---@return string
lurek.data.decompress = function(format, data) end

--- Encodes binary data using the given format (base64, hex).
---@param format string
---@param data string
---@return string
lurek.data.encode = function(format, data) end

--- Encodes a Lua table into a TOML string.
---@param tbl table
---@return string
lurek.data.encodeToml = function(tbl) end

--- Deserializes a MessagePack binary string back into a Lua value.
---@param bytes string
---@return table
lurek.data.fromMsgPack = function(bytes) end

--- Returns the number of bytes the given format and values would occupy.
---@param format string
---@param ... any
---@return number
lurek.data.getPackedSize = function(format, ...) end

--- Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
---@param algorithm string
---@param data string
---@return string
lurek.data.hash = function(algorithm, data) end

--- Instantiates a raw byte data container object.
---@param value integer|number|string
---@return ByteData
lurek.data.newByteData = function(value) end

--- Creates a read-only windowed view into a byte string.
---@param data string
---@param offset? integer
---@param size? integer
---@return DataView
lurek.data.newDataView = function(data, offset, size) end

--- Creates a fixed-capacity ring buffer that can store any Lua value.
---@param capacity integer
---@return RingBuffer
lurek.data.newRingBuffer = function(capacity) end

--- Creates a new write-cursor for building binary data.
---@return DataWriter
lurek.data.newWriter = function() end

--- Packs values into a binary byte string using the format string.
---@param format string
---@param ... any
---@return string
lurek.data.pack = function(format, ...) end

--- Parses a TOML string into a Lua table.
---@param text string
---@return table
lurek.data.parseToml = function(text) end

--- Reads values using the Lurek2D Binary Pack Format.
---@param format string
---@param data string
---@param offset? integer
---@return table
lurek.data.read = function(format, data, offset) end

--- Returns the byte size of a Lurek2D Binary Pack Format string.
---@param format string
---@return number
lurek.data.size = function(format) end

--- Serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary.
---@param value any
---@return string
lurek.data.toMsgPack = function(value) end

--- Unpacks values from a binary byte string, returning values followed by next offset.
---@param format string
---@param data string
---@param offset? integer
---@return table
lurek.data.unpack = function(format, data, offset) end

--- Writes values using the Lurek2D Binary Pack Format.
---@param format string
---@param ... any
---@return string
lurek.data.write = function(format, ...) end

---@class lurek.dataframe
lurek.dataframe = {}

--- Lua-side wrapper around a shared [`DataFrame`].
---@class LDataFrame
LDataFrame = {}

--- Adds a new column with an optional default value.
---@param name string
---@param default? LuaValue
---@return nil
function LDataFrame:addColumn(name, default) end

--- Adds a row from an optional table of name-value pairs, returns 1-based index.
---@param row_tbl? table
---@return number
function LDataFrame:addRow(row_tbl) end

--- Add multiple rows at once from a table of row tables.
---@param rows table
---@return nil
function LDataFrame:addRowBatch(rows) end

--- Applies a function to each value in a column, replacing cells with results.
---@param col string|integer
---@param func function
---@return nil
function LDataFrame:apply(col, func) end

--- Returns a deep copy of this DataFrame.
---@return DataFrame
function LDataFrame:clone() end

--- Returns a table of column names.
---@return table
function LDataFrame:columns() end

--- Pearson correlation coefficient between two numeric columns.
---@param col_a string|integer
---@param col_b string|integer
---@return number
function LDataFrame:corr(col_a, col_b) end

--- Compute a correlation matrix for all numeric columns.
---@return DataFrame
function LDataFrame:correlationMatrix() end

--- Returns the row count (alias for nrows).
---@return number
function LDataFrame:count() end

--- Counts distinct values in a column, returns a DataFrame with value and count columns.
---@param col string|integer
---@return DataFrame
function LDataFrame:countBy(col) end

--- Returns descriptive statistics for all numeric columns.
---@return DataFrame
function LDataFrame:describe() end

--- Removes rows where the given column is nil, returns a new DataFrame.
---@param col string|integer
---@return DataFrame
function LDataFrame:dropNil(col) end

--- Shannon entropy (bits) of the value distribution in a column.
---@param col string|integer
---@return number
function LDataFrame:entropy(col) end

--- Replaces nil values in a column with the given value.
---@param col string|integer
---@param val LuaValue
---@return nil
function LDataFrame:fillNil(col, val) end

--- Filters rows where column matches a condition, returns a new DataFrame.
---@param col string|integer
---@param op string
---@param val LuaValue
---@return DataFrame
function LDataFrame:filter(col, op, val) end

--- Returns all values in a column as a table.
---@param col string|integer
---@return table
function LDataFrame:getColumn(col) end

--- Return a numeric column as a Lua array of numbers (nils → 0/nan).
---@param col string|integer
---@return table
function LDataFrame:getColumnAsF64(col) end

--- Returns a row as a table of name-value pairs.
---@param row integer
---@return table
function LDataFrame:getRow(row) end

--- Returns a single cell value.
---@param row integer
---@param col string|integer
---@return LuaValue
function LDataFrame:getValue(row, col) end

--- Aggregate agg_col grouped by group_col using the named function.
---@param group_col string|integer
---@param agg_col string|integer
---@param fn_name string
---@return DataFrame
function LDataFrame:groupAgg(group_col, agg_col, fn_name) end

--- Groups rows by column value, returns a table of DataFrames keyed by value.
---@param col string|integer
---@return table
function LDataFrame:groupBy(col) end

--- Groups rows by column value, returns a GroupedFrame object supporting aggregate().
---@param col string|integer
---@return GroupedFrame
function LDataFrame:groupByObj(col) end

--- Returns the first n rows (default 5).
---@param n? integer
---@return DataFrame
function LDataFrame:head(n) end

--- Joins with another DataFrame on matching columns.
---@param other DataFrame
---@param this_col string|integer
---@param other_col string|integer
---@param join_type? string
---@return DataFrame
function LDataFrame:join(other, this_col, other_col, join_type) end

--- Returns the maximum numeric value in a column.
---@param col string|integer
---@return number
function LDataFrame:max(col) end

--- Returns the mean of numeric values in a column.
---@param col string|integer
---@return number
function LDataFrame:mean(col) end

--- Returns the median of numeric values in a column.
---@param col string|integer
---@return number
function LDataFrame:median(col) end

--- Appends rows from another DataFrame in-place.
---@param other DataFrame
---@return nil
function LDataFrame:merge(other) end

--- Returns the minimum numeric value in a column.
---@param col string|integer
---@return number
function LDataFrame:min(col) end

--- Return the most frequent value in a column (nil if empty).
---@param col string|integer
---@return table
function LDataFrame:modeVal(col) end

--- Returns the number of columns.
---@return number
function LDataFrame:ncols() end

--- Add a min-max normalized column scaled to [out_min, out_max].
---@param col string|integer
---@param out_min number
---@param out_max number
---@param name string
---@return nil
function LDataFrame:normalizeCol(col, out_min, out_max, name) end

--- Returns the number of rows.
---@return number
function LDataFrame:nrows() end

--- Return a new DataFrame with only outlier rows (|z-score| > threshold).
---@param col string|integer
---@param threshold? number
---@return DataFrame
function LDataFrame:outliers(col, threshold) end

--- Creates a wide pivot table by reshaping rows into columns.
---@param row_col string|integer
---@param col_col string|integer
---@param val_col string|integer
---@return DataFrame
function LDataFrame:pivot(row_col, col_col, val_col) end

--- Reshapes a long-format DataFrame into wide format.
---@param row_key string|integer
---@param col_key string|integer
---@param value_key string|integer
---@param agg? string
---@return DataFrame
function LDataFrame:pivotTable(row_key, col_key, value_key, agg) end

--- Executes a SQL query against this DataFrame.
---@param sql_str string
---@return DataFrame
function LDataFrame:query(sql_str) end

--- Returns a new DataFrame with a dense-rank column appended.
---@param col string|integer
---@param order? string
---@param result_col? string
---@return DataFrame
function LDataFrame:rank(col, order, result_col) end

--- Removes a column by name or index.
---@param col string|integer
---@return nil
function LDataFrame:removeColumn(col) end

--- Removes a row by 1-based index.
---@param row integer
---@return nil
function LDataFrame:removeRow(row) end

--- Renames the column `old_name` to `new_name` in this DataFrame.
---@param col string|integer
---@param new_name string
---@return nil
function LDataFrame:rename(col, new_name) end

--- Returns a new DataFrame with a rolling mean column appended.
---@param col string|integer
---@param window integer
---@param result_col? string
---@return DataFrame
function LDataFrame:rollingMean(col, window, result_col) end

--- Returns a new DataFrame with a rolling sum column appended.
---@param col string|integer
---@param window integer
---@param result_col? string
---@return DataFrame
function LDataFrame:rollingSum(col, window, result_col) end

--- Returns a random sample of n rows.
---@param n integer
---@param seed? integer
---@return DataFrame
function LDataFrame:sample(n, seed) end

--- Selects a subset of columns, returns a new DataFrame.
---@param ... string|integer
---@return DataFrame
function LDataFrame:select(...) end

--- Set a numeric column from a Lua array of numbers.
---@param col string|integer
---@param values table
---@return nil
function LDataFrame:setColumnFromF64(col, values) end

--- Sets a single cell value.
---@param row integer
---@param col string|integer
---@param val LuaValue
---@return nil
function LDataFrame:setValue(row, col, val) end

--- Returns rows from start to end (1-based, inclusive).
---@param start integer
---@param end_idx integer
---@return DataFrame
function LDataFrame:slice(start, end_idx) end

--- Sorts by column, returns a new DataFrame.
---@param col string|integer
---@param ascending? boolean
---@return DataFrame
function LDataFrame:sort(col, ascending) end

--- Returns the population standard deviation of numeric values in a column.
---@param col string|integer
---@return number
function LDataFrame:stddev(col) end

--- Returns the sum of numeric values in a column.
---@param col string|integer
---@return number
function LDataFrame:sum(col) end

--- Returns the last n rows (default 5).
---@param n? integer
---@return DataFrame
function LDataFrame:tail(n) end

--- Serializes this DataFrame to a binary LVDF string.
---@return string
function LDataFrame:toBinary() end

--- Serializes this DataFrame to a CSV string.
---@return string
function LDataFrame:toCSV() end

--- Serializes this DataFrame to a JSON string.
---@return string
function LDataFrame:toJSON() end

--- Returns a formatted string table representation.
---@return string
function LDataFrame:toString() end

--- Converts this DataFrame to a Lua table of row tables.
---@return table
function LDataFrame:toTable() end

--- Returns the type name of this object.
---@return string
function LDataFrame:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LDataFrame:typeOf(name) end

--- Returns unique values in a column as a table.
---@param col string|integer
---@return table
function LDataFrame:unique(col) end

--- Returns the population variance of numeric values in a column.
---@param col string|integer
---@return number
function LDataFrame:variance(col) end

--- Add a cumulative-sum column.
---@param col string|integer
---@param name string
---@return nil
function LDataFrame:withCumsum(col, name) end

--- Returns a new DataFrame with an additional computed column named `col_name`.
---@param col_name string
---@param expr string
---@return DataFrame
function LDataFrame:withEval(col_name, expr) end

--- Add a percent-change-from-previous-row column.
---@param col string|integer
---@param name string
---@return nil
function LDataFrame:withPctChange(col, name) end

--- Add a rank column (1-based, ties averaged).
---@param col string|integer
---@param ascending? boolean
---@param name string
---@return nil
function LDataFrame:withRank(col, ascending, name) end

--- Add a rolling maximum column.
---@param col string|integer
---@param window integer
---@param name string
---@return nil
function LDataFrame:withRollingMax(col, window, name) end

--- Add a rolling mean column. Rows with insufficient history get nil.
---@param col string|integer
---@param window integer
---@param name string
---@return nil
function LDataFrame:withRollingMean(col, window, name) end

--- Add a rolling minimum column.
---@param col string|integer
---@param window integer
---@param name string
---@return nil
function LDataFrame:withRollingMin(col, window, name) end

--- Add a rolling sum column.
---@param col string|integer
---@param window integer
---@param name string
---@return nil
function LDataFrame:withRollingSum(col, window, name) end

--- Add a z-score column for the given numeric column.
---@param col string|integer
---@param name string
---@return nil
function LDataFrame:zscoreCol(col, name) end

--- Lua-side wrapper around a shared [`Database`].
---@class LDatabase
LDatabase = {}

--- Adds or replaces a table by cloning the given DataFrame.
---@param name string
---@param df DataFrame
---@return nil
function LDatabase:addTable(name, df) end

--- Drops every table from this in-memory database, leaving it empty.
---@return nil
function LDatabase:clear() end

--- Returns a copy of a table by name, or nil if not found.
---@param name string
---@return DataFrame?
function LDatabase:getTable(name) end

--- Returns true if a table with the given name exists.
---@param name string
---@return boolean
function LDatabase:hasTable(name) end

--- Returns a table of all table names.
---@return table
function LDatabase:listTables() end

--- Merges all tables from another Database into this one.
---@param other Database
---@return nil
function LDatabase:merge(other) end

--- Executes a SQL query against the database tables.
---@param sql_str string
---@return DataFrame
function LDatabase:query(sql_str) end

--- Drops the named table from this in-memory database if it exists.
---@param name string
---@return nil
function LDatabase:removeTable(name) end

--- Returns the number of tables.
---@return number
function LDatabase:tableCount() end

--- Serializes all tables to a JSON object string.
---@return string
function LDatabase:toJSON() end

--- Returns the type name of this object.
---@return string
function LDatabase:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LDatabase:typeOf(name) end

--- Lua-side wrapper around a grouped result from [`DataFrame::group_by`].
---@class LGroupedFrame
LGroupedFrame = {}

--- Apply a Lua function to aggregate a column's values per group.
---@param col_name string — column to aggregate
---@param fn function(values: table)→ number — receives array of column values,returns aggregate
---@return DataFrame — new dataframe with group keys and aggregated values
function LGroupedFrame:aggregate(col_name, fn) end

--- Returns the type name of this object.
---@return string
function LGroupedFrame:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LGroupedFrame:typeOf(name) end

--- Thin Lua wrapper around a [`VecFrame`]: typed-column vectorized DataFrame.
---@class LVecFrame
LVecFrame = {}

--- Return a new VecFrame containing only the rows where mask[i] is true.
---@param mask table
---@return VecFrame
function LVecFrame:applyMask(mask) end

--- Apply absolute value to every element of a Float64 column.
---@param col string
function LVecFrame:colAbs(col) end

--- Add a scalar to every element of a Float64 column.
---@param col string
---@param val number
function LVecFrame:colAdd(col, val) end

--- Cast a column to a new dtype: "float64", "int64", or "text".
---@param col string
---@param dtype string
function LVecFrame:colCast(col, dtype) end

--- Apply ceiling to every element of a Float64 column.
---@param col string
function LVecFrame:colCeil(col) end

--- Clamp every element of a Float64 column to [min, max].
---@param col string
---@param min_val number
---@param max_val number
function LVecFrame:colClamp(col, min_val, max_val) end

--- Divide every element of a Float64 column by a scalar.
---@param col string
---@param val number
function LVecFrame:colDiv(col, val) end

--- Apply floor to every element of a Float64 column.
---@param col string
function LVecFrame:colFloor(col) end

--- Multiply every element of a Float64 column by a scalar.
---@param col string
---@param val number
function LVecFrame:colMul(col, val) end

--- Negate every element of a Float64 column.
---@param col string
function LVecFrame:colNeg(col) end

--- Compute out[i] = left[i] op right[i] for every row.
---@param out_col string
---@param left_col string
---@param op string
---@param right_col string
function LVecFrame:colOp(out_col, left_col, op, right_col) end

--- Apply square root to every element of a Float64 column.
---@param col string
function LVecFrame:colSqrt(col) end

--- Subtract a scalar from every element of a Float64 column.
---@param col string
---@param val number
function LVecFrame:colSub(col, val) end

--- Return the dtype name of a column: "float64", "int64", "bool", or "text".
---@param col string
---@return string
function LVecFrame:colType(col) end

--- Return a table of column names.
---@return table
function LVecFrame:columns() end

--- Build a boolean row mask: mask[i] = col[i] cmp_op val.
---@param col string
---@param cmp_op string
---@param val number
---@return table
function LVecFrame:filterMask(col, cmp_op, val) end

--- Return the number of columns.
---@return number
function LVecFrame:ncols() end

--- Return the number of rows.
---@return number
function LVecFrame:nrows() end

--- Reduce multiple columns in parallel, returning {col → value} table.
---@param cols table
---@param op string
---@return table
function LVecFrame:parReduce(cols, op) end

--- Apply a scalar op in parallel to multiple Float64 columns.
---@param cols table
---@param op string
---@param val number
function LVecFrame:parScalarOp(cols, op, val) end

--- Reduce an entire numeric column to a single value.
---@param col string
---@param op string
---@return number
function LVecFrame:reduce(col, op) end

--- Convert this VecFrame back to a DataFrame.
---@return DataFrame
function LVecFrame:toDataFrame() end

--- Returns the type name of this object.
---@return string
function LVecFrame:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LVecFrame:typeOf(name) end

--- Deserializes a binary LVDF string into a DataFrame.
---@param s string
---@return DataFrame
lurek.dataframe.fromBinary = function(s) end

--- Parses a CSV string into a DataFrame.
---@param s string
---@return DataFrame
lurek.dataframe.fromCSV = function(s) end

--- Parses a JSON string into a DataFrame.
---@param s string
---@return DataFrame
lurek.dataframe.fromJSON = function(s) end

--- Creates a DataFrame from an array of row tables.
---@param rows table
---@return DataFrame
lurek.dataframe.fromTable = function(rows) end

--- Converts a VecFrame back to a DataFrame.
---@param vf VecFrame
---@return DataFrame
lurek.dataframe.fromVec = function(vf) end

--- Creates a new empty DataFrame.
---@return DataFrame
lurek.dataframe.newDataFrame = function() end

--- Creates a new empty Database.
---@return Database
lurek.dataframe.newDatabase = function() end

--- Generates a DataFrame with random data from column definitions.
---@param defs table
---@param n integer
---@param seed? integer
---@return DataFrame
lurek.dataframe.random = function(defs, n, seed) end

--- Converts a DataFrame to a VecFrame for vectorized column operations.
---@param df DataFrame
---@return VecFrame
lurek.dataframe.toVec = function(df) end

---@class lurek.debugbridge
lurek.debugbridge = {}

--- Broadcasts a JSON event to all connected clients.
---@param event string
---@param json_data string
lurek.debugbridge.broadcast = function(event, json_data) end

--- Captures a print message and broadcasts it to connected clients.
---@param msg string
---@param source? string
---@param line? integer
lurek.debugbridge.capturePrint = function(msg, source, line) end

--- Clears the print history.
lurek.debugbridge.clearPrintHistory = function() end

--- Returns the number of connected TCP clients.
---@return number
lurek.debugbridge.getClientCount = function() end

--- Returns performance statistics.
---@return table
lurek.debugbridge.getPerformance = function() end

--- Returns the server port (0 if not running).
---@return number
lurek.debugbridge.getPort = function() end

--- Returns the print history.
---@param count? integer
---@return table
lurek.debugbridge.getPrintHistory = function(count) end

--- Returns whether the server is currently running.
---@return boolean
lurek.debugbridge.isRunning = function() end

--- Returns whether a screenshot is currently requested.
---@return boolean
lurek.debugbridge.isScreenshotRequested = function() end

--- Poll for pending Lua-dependent requests from TCP clients.
---@return table
lurek.debugbridge.poll = function() end

--- Flags a screenshot request for the next frame.
---@param scale? integer
lurek.debugbridge.requestScreenshot = function(scale) end

--- Sets the maximum print history size.
---@param max integer
lurek.debugbridge.setMaxPrintHistory = function(max) end

--- Start the TCP debug server on 127.0.0.1:port.
---@param port? integer
---@return boolean
lurek.debugbridge.start = function(port) end

--- Stop the TCP debug server and close all connections.
lurek.debugbridge.stop = function() end

---@class lurek.devtools
lurek.devtools = {}

--- Lua-side handle for a per-path file watcher.
---@class LFileWatcher
LFileWatcher = {}

--- Removes the stored `onChanged` callback and stops future notifications.
---@return nil
function LFileWatcher:cancel() end

--- Polls the watcher. If the file has changed since the last call, fires the
---@return boolean
function LFileWatcher:check() end

--- Returns the watched path string.
---@return string
function LFileWatcher:getPath() end

--- Registers a callback invoked (with no arguments) when the watched path changes.
---@param fn function
---@return nil
function LFileWatcher:onChanged(fn) end

--- Returns the type name of this object.
---@return string
function LFileWatcher:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LFileWatcher:typeOf(name) end

--- Lua-side wrapper around a [`ReplConsole`] interactive evaluator.
---@class LReplConsole
LReplConsole = {}

--- Clears the REPL history buffer.
---@return nil
function LReplConsole:clear() end

--- Evaluates a Lua snippet and records the input in history.
---@param code string
---@return string
function LReplConsole:eval(code) end

--- Returns an ordered array of past inputs (oldest first).
---@return table
function LReplConsole:history() end

--- Returns the number of history entries.
---@return number
function LReplConsole:len() end

--- Returns the type name of this object.
---@return string
function LReplConsole:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LReplConsole:typeOf(name) end

--- Discards all accumulated log entries from the in-memory devtools log buffer.
---@return nil
lurek.devtools.clearLog = function() end

--- Clears all watched paths.
---@return nil
lurek.devtools.clearWatches = function() end

--- Logs a message at DEBUG level.
---@param message string
---@return nil
lurek.devtools.debug = function(message) end

--- Logs a message at ERROR level.
---@param message string
---@return nil
lurek.devtools.error = function(message) end

--- Evaluates a Lua string and returns (success, results...).
---@param code string
---@return boolean
lurek.devtools.eval = function(code) end

--- Registers a named live watch. The getter function is called on demand to sample a value.
---@param name string
---@param getter function
---@param category? string
---@return number
lurek.devtools.exposeWatch = function(name, getter, category) end

--- Logs a message at FATAL level.
---@param message string
---@return nil
lurek.devtools.fatal = function(message) end

--- Returns the Lua call stack as a table of frames.
---@param max_depth? integer
---@return table
lurek.devtools.getCallStack = function(max_depth) end

--- Returns the raw frame-time sample array.
---@return table
lurek.devtools.getFrameHistory = function() end

--- Returns the current frame-history buffer capacity.
---@return number
lurek.devtools.getFrameHistorySize = function() end

--- Returns a table of computed frame statistics.
---@return table
lurek.devtools.getFrameStats = function() end

--- Returns whether console log output is enabled.
---@return boolean
lurek.devtools.getLogConsole = function() end

--- Returns the current log file path.
---@return string
lurek.devtools.getLogFile = function() end

--- Returns recent log entries as an array of tables.
---@param count? integer
---@return table
lurek.devtools.getLogHistory = function(count) end

--- Returns the current minimum log level.
---@return string
lurek.devtools.getLogLevel = function() end

--- Returns zone data table for a specific frame (0 or nil = most recent).
---@param frame? integer
---@return table
lurek.devtools.getProfileData = function(frame) end

--- Returns the number of retained profile frames.
---@return number
lurek.devtools.getProfileFrameCount = function() end

--- Returns the file watch poll interval in seconds.
---@return number
lurek.devtools.getWatchInterval = function() end

--- Returns an array of all watched paths.
---@return table
lurek.devtools.getWatchedPaths = function() end

--- Calls all registered watch getters and returns a table of {name, category, value} records.
---@return table
lurek.devtools.getWatches = function() end

--- Logs a message at INFO level.
---@param message string
---@return nil
lurek.devtools.info = function(message) end

--- Returns whether the console is considered open.
---@return boolean
lurek.devtools.isConsoleOpen = function() end

--- Returns whether the profiler is enabled.
---@return boolean
lurek.devtools.isProfilingEnabled = function() end

--- Logs a message at the given level.
---@param level string
---@param message string
---@return nil
lurek.devtools.log = function(level, message) end

--- Creates a standalone per-path file watcher. Call `:check()` once per frame
---@param path string
---@return FileWatcher
lurek.devtools.newFileWatcher = function(path) end

--- Creates an interactive Lua REPL console with a bounded history buffer.
---@param max_history? integer
---@return ReplConsole
lurek.devtools.newRepl = function(max_history) end

--- Opens the console window (updates the console flag; returns true).
---@return boolean
lurek.devtools.openConsole = function() end

--- Seals the current frame of profiling data.
---@return nil
lurek.devtools.profileFrame = function() end

--- Closes the most recent profiling zone.
---@return nil
lurek.devtools.profilePop = function() end

--- Opens a named profiling zone on the stack.
---@param name string
---@return nil
lurek.devtools.profilePush = function(name) end

--- Returns a flat summary table of all recorded profiler zones across all stored
---@return table
lurek.devtools.profilerReport = function() end

--- Records a frame-time sample (call each frame with delta time in seconds).
---@param dt number
---@return nil
lurek.devtools.recordFrameTime = function(dt) end

--- Removes a watch by the id returned from exposeWatch. Returns true if removed.
---@param id integer
---@return boolean
lurek.devtools.removeWatch = function(id) end

--- Clears all profiling data and resets the zone stack.
---@return nil
lurek.devtools.resetProfile = function() end

--- Polls all watched paths and returns paths whose mtime changed.
---@return table
lurek.devtools.scan = function() end

--- Sets the frame-history buffer capacity (clamped 10-10000).
---@param size integer
---@return nil
lurek.devtools.setFrameHistorySize = function(size) end

--- Enables or disables console log output.
---@param enabled boolean
---@return nil
lurek.devtools.setLogConsole = function(enabled) end

--- Sets the log file path (empty string disables file output).
---@param path string
---@return nil
lurek.devtools.setLogFile = function(path) end

--- Sets the minimum log level.
---@param level string
---@return nil
lurek.devtools.setLogLevel = function(level) end

--- Enables or disables the profiler.
---@param enabled boolean
---@return nil
lurek.devtools.setProfilingEnabled = function(enabled) end

--- Sets the file watch poll interval in seconds.
---@param interval number
---@return nil
lurek.devtools.setWatchInterval = function(interval) end

--- Takes a structured snapshot of all watches + frame stats + last profile frame.
---@return table
lurek.devtools.snapshot = function() end

--- Logs a message at TRACE level.
---@param message string
---@return nil
lurek.devtools.trace = function(message) end

--- Removes a file path from the watch list.
---@param path string
---@return boolean
lurek.devtools.unwatch = function(path) end

--- Logs a message at WARN level.
---@param message string
---@return nil
lurek.devtools.warn = function(message) end

--- Adds a file path to the watch list. Returns false if already watched.
---@param path string
---@return boolean
lurek.devtools.watch = function(path) end

---@class lurek.docs
lurek.docs = {}

--- Wraps a catalog snapshot of API entries for Lua access.
---@class LApiCatalog
LApiCatalog = {}

--- Returns the number of entries, optionally scoped to a module.
---@param module? string
---@return number
function LApiCatalog:entryCount(module) end

--- Returns a new catalog containing only entries for which predicate returns true.
---@param predicate function
---@return ApiCatalog
function LApiCatalog:filter(predicate) end

--- Returns all entries, optionally filtered to a single module.
---@param module? string
---@return table
function LApiCatalog:getEntries(module) end

--- Returns a single entry by qualified name, or nil.
---@param qualified_name string
---@return nil
function LApiCatalog:getEntry(qualified_name) end

--- Returns a sorted list of module names present in the catalog.
---@return table
function LApiCatalog:getModules() end

--- Returns entries that are methods of the given type qualified name.
---@param qualified_name string
---@return table
function LApiCatalog:getTypeMethods(qualified_name) end

--- Returns the names of all entries with kind "type" in the given module.
---@param module_name string
---@return table
function LApiCatalog:getTypes(module_name) end

--- Returns a new catalog that is the union of this and another catalog, with other overriding duplicates.
---@param other userdata
---@return ApiCatalog
function LApiCatalog:merge(other) end

--- Returns a table of entries whose name, qualified name, or description contains query.
---@param query string
---@return table
function LApiCatalog:search(query) end

--- Serialises the catalog to a pretty-printed JSON string.
---@return string
function LApiCatalog:toJSON() end

--- Converts the catalog to a plain Lua table array.
---@return table
function LApiCatalog:toTable() end

--- Returns the type name of this object.
---@return string
function LApiCatalog:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LApiCatalog:typeOf(name) end

--- Wraps a single doc entry for Lua access.
---@class LDocEntry
LDocEntry = {}

--- Returns the deprecation message, or nil.
---@return string
function LDocEntry:getDeprecated() end

--- Returns the human-readable description text for this documentation entry.
---@return string
function LDocEntry:getDescription() end

--- Returns the example snippet, or nil.
---@return string
function LDocEntry:getExample() end

--- Returns the kind tag for this entry (e.g. `'function'`, `'method'`, `'class'`).
---@return string
function LDocEntry:getKind() end

--- Returns the Lua module name this entry belongs to (e.g. `'lurek.math'`).
---@return string
function LDocEntry:getModule() end

--- Returns the symbol name for this documentation entry.
---@return string
function LDocEntry:getName() end

--- Returns the parameters as a table of `{name, type, description, optional, default?}` records.
---@return table
function LDocEntry:getParameters() end

--- Returns the qualified name.
---@return string
function LDocEntry:getQualifiedName() end

--- Returns the return values as a table of `{type, description}` records.
---@return table
function LDocEntry:getReturns() end

--- Returns the quality score in [0,1].
---@return number
function LDocEntry:getScore() end

--- Returns the since version string, or nil.
---@return string
function LDocEntry:getSince() end

--- Returns true when the entry has a non-empty description.
---@return boolean
function LDocEntry:hasDescription() end

--- Returns true when the entry has an example snippet.
---@return boolean
function LDocEntry:hasExample() end

--- Returns true when the entry has at least one parameter.
---@return boolean
function LDocEntry:hasParameters() end

--- Returns true when the entry declares at least one return type.
---@return boolean
function LDocEntry:hasReturnType() end

--- Returns the type name of this object.
---@return string
function LDocEntry:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LDocEntry:typeOf(name) end

--- Wraps documentation quality metrics for Lua access.
---@class LQualityReport
LQualityReport = {}

--- Returns up to count entries with the highest quality scores.
---@param count? integer
---@return table
function LQualityReport:getBest(count) end

--- Returns entries whose grade exactly matches the given letter grade.
---@param grade string
---@return table
function LQualityReport:getByGrade(grade) end

--- Returns the letter grade for the overall score.
---@return string
function LQualityReport:getGrade() end

--- Returns a table mapping module name to its average quality score.
---@return table
function LQualityReport:getModuleScores() end

--- Returns the overall quality score in [0,1].
---@return number
function LQualityReport:getOverallScore() end

--- Returns a multi-line human-readable summary of quality by module.
---@return string
function LQualityReport:getSummary() end

--- Returns up to count entries with the lowest quality scores.
---@param count? integer
---@return table
function LQualityReport:getWorst(count) end

--- Serialises the quality report to a pretty-printed JSON string.
---@return string
function LQualityReport:toJSON() end

--- Converts the quality report to a plain Lua table.
---@return table
function LQualityReport:toTable() end

--- Returns the type name of this object.
---@return string
function LQualityReport:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LQualityReport:typeOf(name) end

--- Lua wrapper for a runtime data-validation schema.
---@class LSchema
LSchema = {}

--- Validates data and throws a Lua error on failure with all error messages joined.
---@param data table
---@return nil
function LSchema:assert(data) end

--- Returns true when the data passes all schema rules.
---@param data table
---@return boolean
function LSchema:check(data) end

--- Returns a table of declared field names.
---@return table
function LSchema:getFields() end

--- Returns the name identifier of this API schema group.
---@return string
function LSchema:getName() end

--- Returns the type name of this object.
---@return string
function LSchema:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSchema:typeOf(name) end

--- Validates a Lua table against the schema.
---@param data table
---@return nil
function LSchema:validate(data) end

--- Wraps a validation report for Lua access.
---@class LValidationReport
LValidationReport = {}

--- Returns the list of qualified names whose catalog entry is incomplete.
---@return table
function LValidationReport:getIncomplete() end

--- Returns the list of qualified names present in the live API but missing from the catalog.
---@return table
function LValidationReport:getMissing() end

--- Returns the list of qualified names in the catalog that are not present in the live API.
---@return table
function LValidationReport:getPhantom() end

--- Returns a single-line summary of the validation results.
---@return string
function LValidationReport:getSummary() end

--- Returns the count of incomplete entries.
---@return number
function LValidationReport:incompleteCount() end

--- Returns true when the report has no missing entries.
---@return boolean
function LValidationReport:isValid() end

--- Returns the count of missing entries.
---@return number
function LValidationReport:missingCount() end

--- Returns the count of phantom entries.
---@return number
function LValidationReport:phantomCount() end

--- Serialises the report to a pretty-printed JSON string.
---@return string
function LValidationReport:toJSON() end

--- Converts the report to a plain Lua table.
---@return table
function LValidationReport:toTable() end

--- Returns the type name of this object.
---@return string
function LValidationReport:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LValidationReport:typeOf(name) end

--- Compare catalog entries against source files in a directory for staleness.
---@param catalog_ud userdata
---@param source_dir string
---@return table
lurek.docs.checkStaleness = function(catalog_ud, source_dir) end

--- Return (documented_count, total_live_count) coverage tuple.
---@param catalog_ud? userdata
---@return integer
---@return integer
lurek.docs.coverage = function(catalog_ud) end

--- Return (documented_count, total_live_count) for a single module.
---@param module_name string
---@param catalog_ud? userdata
---@return integer
---@return integer
lurek.docs.coverageModule = function(module_name, catalog_ud) end

--- Inject or update a description for a named API entry.
---@param qualified_name string
---@param description string
lurek.docs.describe = function(qualified_name, description) end

--- Export completions.json, hover.json, and signatures.json to a directory.
---@param catalog_ud userdata
---@param output_dir string
lurek.docs.exportAll = function(catalog_ud, output_dir) end

--- Export a one-line-per-function plain-text cheatsheet.
---@param catalog_ud userdata
---@param path string
lurek.docs.exportCheatsheet = function(catalog_ud, path) end

--- Export VS Code IntelliSense completions JSON to a file.
---@param catalog_ud userdata
---@param path string
lurek.docs.exportCompletions = function(catalog_ud, path) end

--- Export VS Code hover JSON to a file.
---@param catalog_ud userdata
---@param path string
lurek.docs.exportHover = function(catalog_ud, path) end

--- Export a Markdown API reference file.
---@param catalog_ud userdata
---@param path string
lurek.docs.exportMarkdown = function(catalog_ud, path) end

--- Export VS Code signature-help JSON to a file.
---@param catalog_ud userdata
---@param path string
lurek.docs.exportSignatures = function(catalog_ud, path) end

--- Return the current internal catalog as an ApiCatalog userdata.
lurek.docs.getCatalog = function() end

--- Load all .toml files in a directory and merge into a single ApiCatalog.
---@param directory string
---@return ApiCatalog
lurek.docs.loadAll = function(directory) end

--- Load a TOML doc file into an ApiCatalog.
---@param path string
---@return ApiCatalog
lurek.docs.loadToml = function(path) end

--- Calculate quality metrics for a catalog or the internal catalog.
---@param catalog_ud? userdata
---@return table
lurek.docs.quality = function(catalog_ud) end

--- Calculate quality metrics for a single module.
---@param module_name string
---@param catalog_ud? userdata
---@return table
lurek.docs.qualityModule = function(module_name, catalog_ud) end

--- Walks the live lurek.* Lua table and returns a structured reflection of all
---@param ns? string
---@return table
lurek.docs.reflectLive = function(ns) end

--- Reflects any Lua table, returning a structure describing its keys,
---@param tbl table
---@param name? string
---@return table
lurek.docs.reflectTable = function(tbl, name) end

--- Clear all entries from the internal catalog.
lurek.docs.resetCatalog = function() end

--- Scan the lurek.* namespace to build an API catalog from live bindings.
---@param opts? table
---@return ApiCatalog
lurek.docs.scan = function(opts) end

--- Scan a single module's bindings.
---@param module_name string
---@return ApiCatalog
lurek.docs.scanModule = function(module_name) end

--- Creates a Schema validator from a rules table.
---@param rules table
---@param name? string
---@return userdata
lurek.docs.schema = function(rules, name) end

--- Set the parameter metadata for a catalog entry.
---@param qualified_name string
---@param params table
lurek.docs.setParamInfo = function(qualified_name, params) end

--- Set the return type metadata for a catalog entry.
---@param qualified_name string
---@param returns table
lurek.docs.setReturnInfo = function(qualified_name, returns) end

--- Validate catalog completeness against the live lurek.* bindings.
---@param catalog_ud? userdata
---@return ValidationReport
lurek.docs.validate = function(catalog_ud) end

--- Validate a single module against the live lurek.<module>.* bindings.
---@param module_name string
---@param catalog_ud? userdata
---@return ValidationReport
lurek.docs.validateModule = function(module_name, catalog_ud) end

---@class lurek.ecs
lurek.ecs = {}

--- Lua-side wrapper around a [`Universe`] ECS world.
---@class LUniverse
LUniverse = {}

--- Adds a directed named relationship from entity `from` to entity `to`.
---@param from integer
---@param name string
---@param to integer
---@return nil
function LUniverse:addRelation(from, name, to) end

--- Adds a system table to the universe with an optional priority (lower = earlier).
---@param system table
---@param opts? table? â€”{priority: integer}
---@return nil
function LUniverse:addSystem(system, opts) end

--- Attaches a string tag to an entity.
---@param id integer
---@param tag string
---@return nil
function LUniverse:addTag(id, tag) end

--- Adds a bitmap tag to an entity.
---@param id integer
---@param name string
---@return nil
function LUniverse:bitmapTag(id, name) end

--- Removes a bitmap tag from an entity.
---@param id integer
---@param name string
---@return nil
function LUniverse:bitmapUntag(id, name) end

--- Removes all entities, components, tags, layers, and systems. Blueprints are preserved.
---@return nil
function LUniverse:clear() end

--- Removes all directed named relationships of type `name` from entity `from`.
---@param from integer
---@param name string
---@return nil
function LUniverse:clearRelations(from, name) end

--- Defines a blueprint from a component table.
---@param name string
---@param components table
---@return nil
function LUniverse:defineBlueprint(name, components) end

--- Defines a bitmap tag name, returning its bit index.
---@param name string
---@return number
function LUniverse:defineTag(name) end

--- Restores entity state from a snapshot produced by serialize().
---@param snapshot table
---@return nil
function LUniverse:deserialize(snapshot) end

--- Calls callback(id, value) for every entity with the named component.
---@param name string
---@param callback function
---@return nil
function LUniverse:each(name, callback) end

--- Emits a named event to all systems that implement the handler, in priority order.
---@param ... string
---@return nil
function LUniverse:emit(...) end

--- Defines a blueprint by extending a parent with overrides.
---@param name string
---@param parent string
---@param overrides table
---@return nil
function LUniverse:extendBlueprint(name, parent, overrides) end

--- Dispatches all pending component-add and component-remove events to registered callbacks.
---@return nil
function LUniverse:flushObservers() end

--- Returns the component value for an entity, or nil if missing.
---@param id integer
---@param name string
---@return table
function LUniverse:get(id, name) end

--- Returns the bit index for a bitmap tag name, or nil if undefined.
---@param name string
---@return number
function LUniverse:getBitmapTagBit(name) end

--- Returns a deep copy of a blueprint's component table, or nil.
---@param name string
---@return table
function LUniverse:getBlueprintComponents(name) end

--- Returns all direct child entity IDs.
---@param parent_id integer
---@return table
function LUniverse:getChildren(parent_id) end

--- Returns all component names for an entity.
---@param id integer
---@return table
function LUniverse:getComponents(id) end

--- Returns all alive entity IDs.
---@return table
function LUniverse:getEntities() end

--- Returns all alive entities on a specific layer.
---@param layer integer
---@return table
function LUniverse:getEntitiesByLayer(layer) end

--- Returns all alive entities with the given string tag.
---@param tag string
---@return table
function LUniverse:getEntitiesByTag(tag) end

--- Returns all alive entities sorted by layer then ID.
---@return table
function LUniverse:getEntitiesSorted() end

--- Returns the number of alive entities.
---@return number
function LUniverse:getEntityCount() end

--- Returns the layer for an entity, defaulting to zero.
---@param id integer
---@return number
function LUniverse:getLayer(id) end

--- Returns the parent entity ID, or nil if unparented.
---@param child_id integer
---@return number
function LUniverse:getParent(child_id) end

--- Returns all entity IDs reachable from `from` via the named relationship.
---@param from integer
---@param name string
---@return table
function LUniverse:getRelated(from, name) end

--- Returns the number of registered systems.
---@return number
function LUniverse:getSystemCount() end

--- Returns all string tags for an entity.
---@param id integer
---@return table
function LUniverse:getTags(id) end

--- Returns true if the entity has the named component.
---@param id integer
---@param name string
---@return boolean
function LUniverse:has(id, name) end

--- Returns true if the entity has the given bitmap tag.
---@param id integer
---@param name string
---@return boolean
function LUniverse:hasBitmapTag(id, name) end

--- Returns true if a blueprint with the given name exists.
---@param name string
---@return boolean
function LUniverse:hasBlueprint(name) end

--- Returns true if a directed named relationship from `from` to `to` exists.
---@param from integer
---@param name string
---@param to integer
---@return boolean
function LUniverse:hasRelation(from, name, to) end

--- Returns true if the entity carries the given tag.
---@param id integer
---@param tag string
---@return boolean
function LUniverse:hasTag(id, tag) end

--- Returns true if the entity ID is currently alive.
---@param id integer
---@return boolean
function LUniverse:isAlive(id) end

--- Destroys the entity with the given ID, freeing its slot for reuse.
---@param id integer
---@return nil
function LUniverse:kill(id) end

--- Kills an entity and all its descendants recursively.
---@param id integer
---@return nil
function LUniverse:killRecursive(id) end

--- Returns all defined blueprint names.
---@return table
function LUniverse:listBlueprints() end

--- Registers a callback to fire when a component is added to any entity.
---@param name string
---@param callback function
---@return nil
function LUniverse:onComponentAdded(name, callback) end

--- Registers a callback to fire when a component is removed from any entity.
---@param name string
---@param callback function
---@return nil
function LUniverse:onComponentRemoved(name, callback) end

--- Returns entity IDs that have all listed component names.
---@param ... string
---@return table
function LUniverse:query(...) end

--- Returns all alive entities with all of the listed bitmap tags.
---@param names table
---@return table
function LUniverse:queryBitmapAll(names) end

--- Returns all alive entities with any of the listed bitmap tags.
---@param names table
---@return table
function LUniverse:queryBitmapAny(names) end

--- Returns all alive entities with the given bitmap tag.
---@param name string
---@return table
function LUniverse:queryBitmapTag(name) end

--- Returns entity IDs that have all `with` components and none of the `without` components.
---@param with_table table
---@param without_table table
---@return table
function LUniverse:queryNot(with_table, without_table) end

--- Releases all universe state, equivalent to clear.
---@return nil
function LUniverse:release() end

--- Removes a component from an entity.
---@param id integer
---@param name string
---@return nil
function LUniverse:remove(id, name) end

--- Removes a blueprint definition.
---@param name string
---@return nil
function LUniverse:removeBlueprint(name) end

--- Removes the directed named relationship from entity `from` to entity `to`.
---@param from integer
---@param name string
---@param to integer
---@return nil
function LUniverse:removeRelation(from, name, to) end

--- Removes a system table from the universe.
---@param system table
---@return nil
function LUniverse:removeSystem(system) end

--- Removes a string tag from an entity.
---@param id integer
---@param tag string
---@return nil
function LUniverse:removeTag(id, tag) end

--- Calls render(system, world) on each registered system in priority order.
---@return nil
function LUniverse:render() end

--- Serializes all alive entities to a Lua table snapshot.
---@return table
function LUniverse:serialize() end

--- Sets a component value on an entity.
---@param id integer
---@param name string
---@param value any
---@return nil
function LUniverse:set(id, name, value) end

--- Sets the layer for an entity.
---@param id integer
---@param layer integer
---@return nil
function LUniverse:setLayer(id, layer) end

--- Sets or clears the parent of an entity.
---@param child_id integer
---@param parent_id? integer
---@return nil
function LUniverse:setParent(child_id, parent_id) end

--- Creates a new entity and returns its packed ID.
---@return number
function LUniverse:spawn() end

--- Spawns an entity from a blueprint with optional overrides.
---@param name string
---@param overrides? table
---@return number
function LUniverse:spawnBlueprint(name, overrides) end

--- Spawns `count` entities from a blueprint, returns an array of entity IDs.
---@param name string
---@param count integer
---@param overrides? table
---@return table
function LUniverse:spawnBulk(name, count, overrides) end

--- Returns the type name of this object.
---@return string
function LUniverse:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LUniverse:typeOf(name) end

--- Calls update(system, world, dt) on each registered system in priority order.
---@param dt number
---@return nil
function LUniverse:update(dt) end

--- Creates a new empty ECS universe.
---@return Universe
lurek.ecs.newUniverse = function() end

---@class lurek.effect
lurek.effect = {}

--- Lua-side wrapper around [`ImageEffect`].
---@class LImageEffect
LImageEffect = {}

--- Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
---@param name string
---@return PostFxEffect
function LImageEffect:addEffect(name) end

--- Removes all effects from the chain (alias for clearEffects).
---@return nil
function LImageEffect:clear() end

--- Removes all effects from the chain.
---@return nil
function LImageEffect:clearEffects() end

--- Returns a deep copy of this ImageEffect chain.
---@return ImageEffect
function LImageEffect:clone() end

--- Returns the number of effects in the chain.
---@return number
function LImageEffect:effectCount() end

--- Returns the effect at the given 1-based index or with the given type name.
---@param key integer|string
---@return nil
function LImageEffect:getEffect(key) end

--- Returns the number of effects in the chain (alias for effectCount).
---@return number
function LImageEffect:getEffectCount() end

--- Removes the effect at the given 0-based index from the chain.
---@param idx integer
---@return boolean
function LImageEffect:removeByIndex(idx) end

--- Removes the first effect matching the given type name.
---@param name string
---@return boolean
function LImageEffect:removeByName(name) end

--- Removes the effect at the given 1-based index or with the given type name.
---@param key integer|string
---@return boolean
function LImageEffect:removeEffect(key) end

--- Stub: no-op serialisation placeholder.
---@return boolean
function LImageEffect:save() end

--- Returns the type name "ImageEffect".
---@return string
function LImageEffect:type() end

--- Returns true when the given name matches "ImageEffect" or a parent type.
---@param name string
---@return boolean
function LImageEffect:typeOf(name) end

--- Lua-side wrapper around [`Overlay`].
---@class LOverlay
LOverlay = {}

--- Resets all effect subsystems to their default inactive state.
---@return nil
function LOverlay:clear() end

--- Renders the effect state (flash, fade, effects) to a CPU ImageData.
---@param width integer
---@param height integer
---@return ImageData
function LOverlay:drawToImage(width, height) end

--- Animates a full-screen colour fade; alpha defaults to 1.0, duration to 1.0 s.
---@param r number
---@param g number
---@param b number
---@param alpha? number
---@param duration? number
---@return nil
function LOverlay:fade(r, g, b, alpha, duration) end

--- Triggers a full-screen colour flash; alpha defaults to 1.0, duration to 0.2 s.
---@param r number
---@param g number
---@param b number
---@param a? number
---@param duration? number
---@return nil
function LOverlay:flash(r, g, b, a, duration) end

--- Returns the current ambient tint as r, g, b, a components.
---@return number
---@return number
---@return number
---@return number
function LOverlay:getAmbientColor() end

--- Returns the current cloud shadow instance count.
---@return number
function LOverlay:getCloudCount() end

--- Returns the current cloud shadow opacity.
---@return number
function LOverlay:getCloudOpacity() end

--- Returns the current cloud shadow scale.
---@return number
function LOverlay:getCloudScale() end

--- Returns the current cloud shadow scroll speed.
---@return number
function LOverlay:getCloudSpeed() end

--- Returns the effect width and height.
---@return integer
---@return integer
function LOverlay:getDimensions() end

--- Returns the current film-grain intensity.
---@return number
function LOverlay:getFilmGrainIntensity() end

--- Returns the current flash overlay alpha value.
---@return number
function LOverlay:getFlashAlpha() end

--- Returns the current fog tint as r, g, b, a components.
---@return number
---@return number
---@return number
---@return number
function LOverlay:getFogColor() end

--- Returns the current fog density.
---@return number
function LOverlay:getFogDensity() end

--- Returns the current heat-haze distortion intensity.
---@return number
function LOverlay:getHeatHazeIntensity() end

--- Returns the effect height.
---@return number
function LOverlay:getHeight() end

--- Returns the current lightning overlay alpha value.
---@return number
function LOverlay:getLightningAlpha() end

--- Returns the lightning flash tint as r, g, b, a components.
---@return number
---@return number
---@return number
---@return number
function LOverlay:getLightningColor() end

--- Returns the current shake displacement as x, y.
---@return number
---@return number
function LOverlay:getShakeOffset() end

--- Returns the current simulated time-of-day (0â€“24).
---@return number
function LOverlay:getTimeOfDay() end

--- Returns the current vignette strength.
---@return number
function LOverlay:getVignetteStrength() end

--- Returns a table describing the current water overlay state.
---@return table
function LOverlay:getWater() end

--- Returns the name of the current weather type.
---@return string
function LOverlay:getWeather() end

--- Returns the current weather intensity.
---@return number
function LOverlay:getWeatherIntensity() end

--- Returns the effect width.
---@return number
function LOverlay:getWidth() end

--- Returns the current wind direction in radians.
---@return number
function LOverlay:getWindDirection() end

--- Returns the current wind speed.
---@return number
function LOverlay:getWindSpeed() end

--- Returns true if any effect subsystem is currently active.
---@return boolean
function LOverlay:isActive() end

--- Returns whether the ambient light layer is active.
---@return boolean
function LOverlay:isAmbientEnabled() end

--- Returns whether cloud shadows are active.
---@return boolean
function LOverlay:isCloudShadowsEnabled() end

--- Returns true while a fade effect is in progress.
---@return boolean
function LOverlay:isFading() end

--- Returns whether the film-grain layer is active.
---@return boolean
function LOverlay:isFilmGrainEnabled() end

--- Returns true while a flash effect is in progress.
---@return boolean
function LOverlay:isFlashing() end

--- Returns whether the fog layer is active.
---@return boolean
function LOverlay:isFogEnabled() end

--- Returns whether the heat-haze layer is active.
---@return boolean
function LOverlay:isHeatHazeEnabled() end

--- Returns true while a shake effect is in progress.
---@return boolean
function LOverlay:isShaking() end

--- Returns whether the vignette layer is active.
---@return boolean
function LOverlay:isVignetteEnabled() end

--- Returns whether the weather particle system is active.
---@return boolean
function LOverlay:isWeatherEnabled() end

--- Emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette).
---@return nil
function LOverlay:render() end

--- Resizes the effect to match new window dimensions.
---@param width integer
---@param height integer
---@return nil
function LOverlay:resize(width, height) end

--- Sets the ambient light tint colour; alpha defaults to 1.0.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LOverlay:setAmbientColor(r, g, b, a) end

--- Enables or disables the ambient light layer.
---@param enabled boolean
---@return nil
function LOverlay:setAmbientEnabled(enabled) end

--- Sets the number of cloud shadow instances to render.
---@param count integer
---@return nil
function LOverlay:setCloudCount(count) end

--- Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
---@param opacity number
---@return nil
function LOverlay:setCloudOpacity(opacity) end

--- Sets the scale multiplier applied to each cloud shadow.
---@param scale number
---@return nil
function LOverlay:setCloudScale(scale) end

--- Enables or disables scrolling cloud-shadow projection.
---@param enabled boolean
---@return nil
function LOverlay:setCloudShadows(enabled) end

--- Sets the horizontal scroll speed of cloud shadows in pixels per second.
---@param speed number
---@return nil
function LOverlay:setCloudSpeed(speed) end

--- Assigns a custom shader name to the effect, or clears it when `nil` is passed.
---@param name? string
---@return nil
function LOverlay:setCustomShader(name) end

--- Enables or disables the film-grain noise layer.
---@param enabled boolean
---@return nil
function LOverlay:setFilmGrainEnabled(enabled) end

--- Sets the film-grain noise intensity (0.0â€“1.0).
---@param intensity number
---@return nil
function LOverlay:setFilmGrainIntensity(intensity) end

--- Sets the fog tint colour; alpha defaults to 1.0.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LOverlay:setFogColor(r, g, b, a) end

--- Sets the fog density (0.0 = clear, 1.0 = fully opaque).
---@param density number
---@return nil
function LOverlay:setFogDensity(density) end

--- Enables or disables the fog layer.
---@param enabled boolean
---@return nil
function LOverlay:setFogEnabled(enabled) end

--- Enables or disables the heat-haze distortion layer.
---@param enabled boolean
---@return nil
function LOverlay:setHeatHazeEnabled(enabled) end

--- Sets the heat-haze distortion intensity (0.0â€“1.0).
---@param intensity number
---@return nil
function LOverlay:setHeatHazeIntensity(intensity) end

--- Sets the lightning flash tint colour; alpha defaults to 1.0.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LOverlay:setLightningColor(r, g, b, a) end

--- Sets the simulated time-of-day (0â€“24) which drives ambient colour.
---@param hour number
---@return nil
function LOverlay:setTimeOfDay(hour) end

--- Enables or disables the screen-edge vignette layer.
---@param enabled boolean
---@return nil
function LOverlay:setVignetteEnabled(enabled) end

--- Sets the vignette darkening strength (0.0â€“1.0).
---@param strength number
---@return nil
function LOverlay:setVignetteStrength(strength) end

--- Enables the water UV-distortion overlay and sets its wave parameters.
---@param amplitude number
---@param frequency number
---@param speed number
---@return nil
function LOverlay:setWater(amplitude, frequency, speed) end

--- Sets the water tint colour and blend strength.
---@param r number
---@param g number
---@param b number
---@param strength number â€” Tint blend factor[0.0,1.0]
---@return nil
function LOverlay:setWaterTint(r, g, b, strength) end

--- Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
---@param name string
---@return nil
function LOverlay:setWeather(name) end

--- Enables or disables the weather particle system.
---@param enabled boolean
---@return nil
function LOverlay:setWeatherEnabled(enabled) end

--- Sets the particle spawn rate multiplier (0.0â€“1.0).
---@param intensity number
---@return nil
function LOverlay:setWeatherIntensity(intensity) end

--- Sets the wind direction in radians (0 = right, Ď€/2 = down).
---@param radians number
---@return nil
function LOverlay:setWindDirection(radians) end

--- Sets the wind speed applied to weather particles in units per second.
---@param speed number
---@return nil
function LOverlay:setWindSpeed(speed) end

--- Triggers a camera shake; duration defaults to 0.5 s.
---@param intensity number
---@param duration? number
---@return nil
function LOverlay:shake(intensity, duration) end

--- Triggers a screen fade effect to the given colour and alpha.
---@param r number
---@param g number
---@param b number
---@param target_alpha number
---@param duration number
---@return nil
function LOverlay:triggerFade(r, g, b, target_alpha, duration) end

--- Triggers a screen-wide colour flash effect.
---@param r number
---@param g number
---@param b number
---@param a number
---@param duration number
---@return nil
function LOverlay:triggerFlash(r, g, b, a, duration) end

--- Triggers a lightning flash effect.
---@return nil
function LOverlay:triggerLightning() end

--- Triggers a screen shake effect with the given intensity and duration.
---@param intensity number
---@param duration number
---@return nil
function LOverlay:triggerShake(intensity, duration) end

--- Returns the type name of this object ("Overlay").
---@return string
function LOverlay:type() end

--- Returns true if this object is of the given type ("Object" or "Overlay").
---@param name string
---@return boolean
function LOverlay:typeOf(name) end

--- Advances all effect subsystems by the given delta time.
---@param dt number
---@return nil
function LOverlay:update(dt) end

--- Lua-side wrapper around [`PostFxEffect`].
---@class LPostFxEffect
LPostFxEffect = {}

--- Disables auto-injection of common uniforms into shader slot p[3].
---@return nil
function LPostFxEffect:disableAutoUniforms() end

--- Enables auto-injection of common uniforms into shader slot p[3] each frame.
---@return nil
function LPostFxEffect:enableAutoUniforms() end

--- Returns the type name of this effect (alias for getTypeName).
---@return string
function LPostFxEffect:getEffectType() end

--- Returns a named parameter value, or the default if not set.
---@param name string
---@param default? number
---@return number
function LPostFxEffect:getParameter(name, default) end

--- Returns a list of all parameter names on this effect.
---@return table
function LPostFxEffect:getParameterNames() end

--- Returns the type name of this effect (alias for getTypeName).
---@return string
function LPostFxEffect:getType() end

--- Returns the display name of this effect type.
---@return string
function LPostFxEffect:getTypeName() end

--- Returns true if the named parameter exists on this effect.
---@param name string
---@return boolean
function LPostFxEffect:hasParameter(name) end

--- Returns whether auto-uniform injection is enabled for this effect.
---@return boolean
function LPostFxEffect:isAutoUniforms() end

--- Returns true if this is a built-in effect, false if custom.
---@return boolean
function LPostFxEffect:isBuiltIn() end

--- Returns whether this effect is currently active.
---@return boolean
function LPostFxEffect:isEnabled() end

--- Sets the brightness parameter of this effect.
---@param value number
---@return nil
function LPostFxEffect:setBrightness(value) end

--- Sets the contrast parameter of this effect.
---@param value number
---@return nil
function LPostFxEffect:setContrast(value) end

--- Enables or disables this effect.
---@param enabled boolean
---@return nil
function LPostFxEffect:setEnabled(enabled) end

--- Sets the intensity parameter of this effect.
---@param value number
---@return nil
function LPostFxEffect:setIntensity(value) end

--- Sets the offset parameter of this effect.
---@param value number
---@return nil
function LPostFxEffect:setOffset(value) end

--- Sets a named float parameter on this effect.
---@param name string
---@param value number
---@return nil
function LPostFxEffect:setParameter(name, value) end

--- Sets the radius parameter of this effect.
---@param value number
---@return nil
function LPostFxEffect:setRadius(value) end

--- Sets the saturation parameter of this effect.
---@param value number
---@return nil
function LPostFxEffect:setSaturation(value) end

--- Sets the scanline strength parameter of this effect.
---@param value number
---@return nil
function LPostFxEffect:setScanlineStrength(value) end

--- Sets the strength parameter of this effect.
---@param value number
---@return nil
function LPostFxEffect:setStrength(value) end

--- Sets the threshold parameter of this effect.
---@param value number
---@return nil
function LPostFxEffect:setThreshold(value) end

--- Returns the type name "PostFxEffect".
---@return string
function LPostFxEffect:type() end

--- Returns true when the given name matches "PostFxEffect" or a parent type.
---@param name string
---@return boolean
function LPostFxEffect:typeOf(name) end

--- Lua-side wrapper around [`PostFxStack`].
---@class LPostFxStack
LPostFxStack = {}

--- Appends a PostFxEffect to the end of the pipeline.
---@param effect PostFxEffect
---@return nil
function LPostFxStack:add(effect) end

--- Applies all enabled effects in the stack and composites the result to screen.
---@return nil
function LPostFxStack:apply() end

--- Begins capturing the scene for post-processing.
---@return nil
function LPostFxStack:beginCapture() end

--- Removes all effects from the pipeline.
---@return nil
function LPostFxStack:clear() end

--- Resets the feedback intensity to `0.0` (disables feedback).
---@return nil
function LPostFxStack:clearFeedback() end

--- Removes duplicate effects from the pipeline, keeping the first occurrence
---@return nil
function LPostFxStack:dedup() end

--- Ends scene capture for post-processing.
---@return nil
function LPostFxStack:endCapture() end

--- Returns width and height of the render target.
---@return integer
---@return integer
function LPostFxStack:getDimensions() end

--- Returns the effect at the given 1-based position, or nil.
---@param index integer
---@return nil
function LPostFxStack:getEffect(index) end

--- Returns the number of effects in the pipeline.
---@return number
function LPostFxStack:getEffectCount() end

--- Returns a list of currently enabled effect objects.
---@return table
function LPostFxStack:getEnabledEffects() end

--- Returns the current feedback loop intensity `[0.0, 1.0]`.
---@return number
function LPostFxStack:getFeedback() end

--- Returns the height of the render target.
---@return number
function LPostFxStack:getHeight() end

--- Returns the width of the render target.
---@return number
function LPostFxStack:getWidth() end

--- Inserts a PostFxEffect at a specific 1-based position in the pipeline.
---@param position integer
---@param effect PostFxEffect
---@return nil
function LPostFxStack:insert(position, effect) end

--- Returns whether the stack is currently capturing the scene.
---@return boolean
function LPostFxStack:isCapturing() end

--- Returns true if the pipeline has no effect slots.
---@return boolean
function LPostFxStack:isEmpty() end

--- Returns whether the effect at the given 1-based position is enabled.
---@param position integer
---@return boolean
function LPostFxStack:isEnabled(position) end

--- Returns the total number of effect slots in the pipeline.
---@return number
function LPostFxStack:len() end

--- Removes the given PostFxEffect from the pipeline.
---@param effect PostFxEffect
---@return boolean
function LPostFxStack:remove(effect) end

--- Resizes the render target to the given dimensions.
---@param width integer
---@param height integer
---@return nil
function LPostFxStack:resize(width, height) end

--- Enables or disables the effect at the given 1-based position.
---@param position integer
---@param enabled boolean
---@return nil
function LPostFxStack:setEnabled(position, enabled) end

--- Sets the feedback loop intensity. At `0.0` (default) there is no
---@param factor number
---@return nil
function LPostFxStack:setFeedback(factor) end

--- Returns the type name "PostFxStack".
---@return string
function LPostFxStack:type() end

--- Returns true when the given name matches "PostFxStack" or a parent type.
---@param name string
---@return boolean
function LPostFxStack:typeOf(name) end

--- Lua-side wrapper around a [`crate::effect::ScreenTransition`].
---@class LScreenTransition
LScreenTransition = {}

--- Returns the fill color as four numbers: `r, g, b, a`.
---@return number
---@return number
---@return number
---@return number
function LScreenTransition:color() end

--- Returns `true` while the transition is running.
---@return boolean
function LScreenTransition:isActive() end

--- Returns `true` after the transition has completed.
---@return boolean
function LScreenTransition:isDone() end

--- Returns the transition kind name (`"fade"`, `"wipe"`, `"iris_wipe"`,
---@return string
function LScreenTransition:kind() end

--- Starts the transition playing forward (scene fades/wipes out).
---@return nil
function LScreenTransition:play() end

--- Returns the fractional progress `[0, 1]` of the transition, taking
---@return number
function LScreenTransition:progress() end

--- Starts the transition in reverse (scene fades/wipes in).
---@return nil
function LScreenTransition:reverse() end

--- Updates the fill color from `{r, g, b, a?}`.
---@param color table
---@return nil
function LScreenTransition:setColor(color) end

--- Returns the type name of this object ("ScreenTransition").
---@return string
function LScreenTransition:type() end

--- Returns true if this object is of the given type name or a parent type.
---@param name string
---@return boolean
function LScreenTransition:typeOf(name) end

--- Advances the transition by `dt` seconds. Returns `true` while
---@param dt number
---@return boolean
function LScreenTransition:update(dt) end

--- Returns the list of all built-in effect type names.
---@return table
lurek.effect.getEffectTypes = function() end

--- Returns whether shader error display is currently enabled.
---@return boolean
lurek.effect.getShaderErrorDisplay = function() end

--- Creates a custom shader post-processing effect.
---@param shader_id integer
---@return PostFxEffect
lurek.effect.newCustomEffect = function(shader_id) end

--- Creates a new built-in post-processing effect by type name.
---@param type_name string
---@return PostFxEffect
lurek.effect.newEffect = function(type_name) end

--- Creates a new per-image effect chain. Accepts:
---@param ... MultiValue
---@return ImageEffect
lurek.effect.newImageEffect = function(...) end

--- Creates a new screen overlay controller for weather, flash, shake, and fade effects.
---@param width? integer
---@param height? integer
---@return Overlay
lurek.effect.newOverlay = function(width, height) end

--- Creates a custom-shader post-processing effect (alias for newCustomEffect).
---@param shader_id integer
---@return PostFxEffect
lurek.effect.newPass = function(shader_id) end

--- Creates a pre-configured effect stack from a named preset.
---@param name string
---@param width? integer
---@param height? integer
---@return PostFxStack
lurek.effect.newPresetStack = function(name, width, height) end

--- Creates a new post-processing pipeline stack.
---@param width? integer
---@param height? integer
---@return PostFxStack
lurek.effect.newStack = function(width, height) end

--- Creates a new screen-transition controller. `kind` is one of:
---@param kind? string
---@param duration? number
---@param color? table
---@return ScreenTransition
lurek.effect.newTransition = function(kind, duration, color) end

--- Enables or disables the effect that renders shader compile errors as red text
---@param enabled boolean
---@return nil
lurek.effect.setShaderErrorDisplay = function(enabled) end

---@class lurek.engine
lurek.engine = {}

--- Returns the current measured frames-per-second.
---@return number
lurek.engine.fps = function() end

--- Returns the total number of frames processed since engine start.
---@return number
lurek.engine.frameCount = function() end

--- Returns the target frame budget in milliseconds (default: 1000 / 60 â‰ 16.667 ms).
---@return number
lurek.engine.getFrameBudget = function() end

--- Returns a table with resident resource memory statistics.
---@return table
lurek.engine.getResourceStats = function() end

--- Returns the engine version string (from `Cargo.toml`).
---@return string
lurek.engine.getVersion = function() end

--- Returns `true` if the engine was compiled in debug mode.
---@return boolean
lurek.engine.isDebug = function() end

--- Returns a table with `lua_bytes` (Lua GC heap usage in bytes) and
---@return table
lurek.engine.memoryUsage = function() end

--- Returns a string identifying the host operating system:
---@return string
lurek.engine.platform = function() end

--- Sets the maximum resident texture memory budget in bytes.
---@param budget_bytes integer
lurek.engine.setResourceBudget = function(budget_bytes) end

--- Returns the total engine uptime in seconds (sum of all processed deltas).
---@return number
lurek.engine.uptime = function() end

---@class lurek.signal
lurek.signal = {}

--- Lua-side wrapper around a [`Signal`] with registry-stored callbacks.
---@class LSignal
LSignal = {}

--- Removes all callbacks for the named event.
---@param name string
---@return number
function LSignal:clear(name) end

--- Removes all callbacks across all events.
---@return number
function LSignal:clearAll() end

--- Subscribes to an event name or wildcard pattern. When the pattern contains
---@param name string
---@param func function callback invoked with(...)args from emit
---@return nil
function LSignal:connect(name, func) end

--- Emits the named event, calling all registered callbacks with extra arguments.
---@param ... string
---@return nil
function LSignal:emit(...) end

--- Returns the callback count for the named event.
---@param name string
---@return number
function LSignal:getCount(name) end

--- Returns the total callback count across all events.
---@return number
function LSignal:getTotalCount() end

--- Registers a one-shot callback that fires at most once then auto-removes itself.
---@param name string
---@param callback function
---@return number
function LSignal:once(name, callback) end

--- Registers a callback for the named event and returns its handle ID.
---@param name string
---@param callback function
---@return number
function LSignal:register(name, callback) end

--- Registers a callback with a filter predicate. The callback only fires if the
---@param name string
---@param callback function
---@param filter function
---@return number
function LSignal:registerWithFilter(name, callback, filter) end

--- Removes a subscription by handle ID.
---@param handle integer
---@return boolean
function LSignal:remove(handle) end

--- Returns the type name of this object.
---@return string
function LSignal:type() end

--- Returns true if the given type name matches this object's type or any parent type.
---@param name string
---@return boolean
function LSignal:typeOf(name) end

--- Discards all pending events in the queue.
---@return nil
lurek.signal.clear = function() end

--- Clears all recorded event history.
---@return nil
lurek.signal.clearHistory = function() end

--- Enables event history recording, keeping the last `capacity` pushed events.
---@param capacity integer
---@return nil
lurek.signal.enableHistory = function(capacity) end

--- Pushes an exit event, requesting the engine to stop.
---@param code? integer
---@return nil
lurek.signal.exit = function(code) end

--- Moves all buffered deferred events into the main event queue and clears the buffer.
---@return table
lurek.signal.flushDeferred = function() end

--- Returns an array of recent events as `{name, args}` tables.
---@return table
lurek.signal.getHistory = function() end

--- Creates a new pub-sub Signal dispatcher.
---@return Signal
lurek.signal.newSignal = function() end

--- Returns an iterator function that pops events from the queue.
---@return function
lurek.signal.poll = function() end

--- Syncs OS-level events into the queue (no-op in Lurek2D push model).
---@return nil
lurek.signal.pump = function() end

--- Adds an event item to the end of the event queue for processing.
---@param ... MultiValue
lurek.signal.push = function(...) end

--- Pushes a named event to the deferred buffer; it will not reach the main queue
---@param ... string
---@return nil
lurek.signal.pushDeferred = function(...) end

--- Alias for `exit()` â€” requests the engine to stop at the end of the current frame.
---@return nil
lurek.signal.quit = function() end

--- Requests that the engine restart at the beginning of the next frame.
---@return nil
lurek.signal.restart = function() end

--- Blocks until the next event arrives or the optional timeout elapses.
---@param timeout? number
---@return string
lurek.signal.wait = function(timeout) end

---@class lurek.filesystem
lurek.filesystem = {}

--- Lua-side wrapper around a [`FileData`] buffer.
---@class LFileData
LFileData = {}

--- Returns the virtual path this data was loaded from.
---@return string
function LFileData:getFilename() end

--- Returns the file size in bytes.
---@return number
function LFileData:getSize() end

--- Returns the file content as a Lua string.
---@return string
function LFileData:getString() end

--- Returns the type name of this object.
---@return string
function LFileData:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LFileData:typeOf(name) end

--- Lua-side wrapper around a [`FileHandle`] with interior mutability.
---@class LFileHandle
LFileHandle = {}

--- Flushes any pending writes and closes the file handle.
---@return nil
function LFileHandle:close() end

--- Flushes all buffered writes to disk without closing the handle.
---@return nil
function LFileHandle:flush() end

--- Returns the access mode the file was opened with.
---@return string
function LFileHandle:getMode() end

--- Returns the size of the open file in bytes.
---@return number
function LFileHandle:getSize() end

--- Returns whether the read cursor has reached the end of the file.
---@return boolean
function LFileHandle:isEOF() end

--- Reads bytes from the file, returning them as a string.
---@param count? integer
---@return string
function LFileHandle:read(count) end

--- Reads the next line from the file without the trailing newline.
---@return string
function LFileHandle:readLine() end

--- Seeks the file position to the given byte offset from the start.
---@param pos integer
---@return number
function LFileHandle:seek(pos) end

--- Returns the current read/write byte offset from the start of the file.
---@return number
function LFileHandle:tell() end

--- Returns the type name of this object.
---@return string
function LFileHandle:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LFileHandle:typeOf(name) end

--- Writes a string to the file and returns the number of bytes written.
---@param data string
---@return number
function LFileHandle:write(data) end

--- Lua userdata wrapper around a [`ZipMount`].
---@class LZipMount
LZipMount = {}

--- Returns true if `virtual_path` exists inside this ZIP mount.
---@param virtual_path string
---@return boolean
function LZipMount:contains(virtual_path) end

--- Returns a sorted array of all virtual paths exposed by this ZIP mount.
---@return table
function LZipMount:listFiles() end

--- Returns the virtual path prefix this archive was mounted under.
---@return string
function LZipMount:prefix() end

--- Reads a file from the ZIP and returns it as a string of bytes.
---@param virtual_path string
---@return string
function LZipMount:readFile(virtual_path) end

--- Returns the type name of this object.
---@return string
function LZipMount:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LZipMount:typeOf(name) end

--- Opens the file in append mode and writes the given string at the end.
---@param path string
---@param data string
---@return nil
lurek.filesystem.append = function(path, data) end

--- Copies a file within the sandbox.
---@param src string
---@param dst string
---@return nil
lurek.filesystem.copy = function(src, dst) end

--- Creates a directory and any missing parent directories in the save area.
---@param path string
---@return nil
lurek.filesystem.createDirectory = function(path) end

--- Creates an empty temporary file in the `save/` sandbox and returns its
---@param prefix? string
---@return string
lurek.filesystem.createTempFile = function(prefix) end

--- Returns whether the given file or directory exists.
---@param path string
---@return boolean
lurek.filesystem.exists = function(path) end

--- Returns a table containing the names of every file and subdirectory in the given path.
---@param path string
---@return table
lurek.filesystem.getDirectoryItems = function(path) end

--- Returns the identity string used to locate the game's save directory.
---@return string
lurek.filesystem.getIdentity = function() end

--- Returns a table of metadata for a path, or nil if the path does not exist.
---@param path string
---@return table
lurek.filesystem.getInfo = function(path) end

--- Returns the sandboxed save data directory path.
---@return string
lurek.filesystem.getSaveDirectory = function() end

--- Returns the absolute path of the directory the game was loaded from.
---@return string
lurek.filesystem.getSource = function() end

--- Returns the current user's home directory path.
---@return string
lurek.filesystem.getUserDirectory = function() end

--- Returns the current working directory path.
---@return string
lurek.filesystem.getWorkingDirectory = function() end

--- Returns a sorted list of paths matching a simple wildcard pattern.
---@param pattern string
---@return table
lurek.filesystem.glob = function(pattern) end

--- Returns whether the given path is a directory.
---@param path string
---@return boolean
lurek.filesystem.isDirectory = function(path) end

--- Returns whether the given path is a regular file.
---@param path string
---@return boolean
lurek.filesystem.isFile = function(path) end

--- Returns an iterator function over the lines of a text file.
---@param path string
---@return function
lurek.filesystem.lines = function(path) end

--- Returns a sorted list of all files under `path`, recursively.
---@param path string
---@return table
lurek.filesystem.listRecursive = function(path) end

--- Loads and compiles a Lua file from the VFS, returning it as a callable function.
---@param path string
---@return function
lurek.filesystem.load = function(path) end

--- Creates a directory (and any missing parents) relative to the game root.
---@param path string
---@return nil
lurek.filesystem.mkdir = function(path) end

--- Mounts a directory at a virtual path inside the game filesystem.
---@param source string
---@param mountpoint string
---@return boolean
lurek.filesystem.mount = function(source, mountpoint) end

--- Mounts a ZIP archive at a virtual path prefix, making its contents readable
---@param archive_path string
---@param prefix string
---@return ZipMount
lurek.filesystem.mountZip = function(archive_path, prefix) end

--- Moves (renames) a file within the `save/` directory.
---@param src string
---@param dst string
---@return nil
lurek.filesystem.move = function(src, dst) end

--- Loads a file from the VFS into a FileData buffer.
---@param path string
---@return FileData
lurek.filesystem.newFileData = function(path) end

--- Opens a file and returns a readable/writable file handle.
---@param path string
---@param mode string
---@return FileHandle
lurek.filesystem.openFile = function(path, mode) end

--- Polls an async load handle, returning status and optional data.
---@param handle integer
---@return string
lurek.filesystem.pollAsync = function(handle) end

--- Polls all watched paths and returns an array of paths that changed since the
---@return table
lurek.filesystem.pollWatchers = function() end

--- Reads a text file and returns its contents as a string.
---@param path string
---@return string
lurek.filesystem.read = function(path) end

--- Starts loading a file in the background and returns an opaque handle.
---@param path string
---@return number
lurek.filesystem.readAsync = function(path) end

--- Permanently deletes a file or empty directory from the save directory.
---@param path string
---@return nil
lurek.filesystem.remove = function(path) end

--- Recursively deletes a directory and all its contents within `save/`.
---@param path string
---@return nil
lurek.filesystem.removeDir = function(path) end

--- Sets the identity string that names the game's sandboxed save-data directory.
---@param name string
---@return nil
lurek.filesystem.setIdentity = function(name) end

--- Returns lightweight file statistics for the given path.
---@param path string
---@return table
lurek.filesystem.stat = function(path) end

--- Resolves a path relative to the game root to an absolute OS path string.
---@param path string
---@return string
lurek.filesystem.toAbsolutePath = function(path) end

--- Removes a virtual mount layer by mountpoint.
---@param mountpoint string
---@return boolean
lurek.filesystem.unmount = function(mountpoint) end

--- Removes `path` from the polled file-watch list.  No-op if not watched.
---@param path string
---@return nil
lurek.filesystem.unwatchPath = function(path) end

--- Adds `path` to the polled file-watch list.
---@param path string
---@return nil
lurek.filesystem.watchPath = function(path) end

--- Writes a string to a file in the save directory.
---@param path string
---@param data string
---@return nil
lurek.filesystem.write = function(path, data) end

---@class lurek.globe
lurek.globe = {}

--- Lua-accessible handle to a `Globe` inside a `GlobeRegistry`.
---@class LGlobe
LGlobe = {}

--- Add an arc (great-circle path between two lat/lon points).
---@param lat1 number
---@param lon1 number
---@param lat2 number
---@param lon2 number
---@param steps? integer
---@return number
function LGlobe:addArc(lat1, lon1, lat2, lon2, steps) end

--- Add a text label. Returns label ID.
---@param ltype string
---@param lat number
---@param lon number
---@param text string
---@return number
function LGlobe:addLabel(ltype, lat, lon, text) end

--- Add or replace a named thematic layer.
---@param name string
---@param z_order? integer
function LGlobe:addLayer(name, z_order) end

--- Add a marker. Returns marker ID.
---@param mtype string
---@param lat number
---@param lon number
---@param label? string
---@return number
function LGlobe:addMarker(mtype, lat, lon, label) end

--- Adds a province from a table {id, centroid={lat,lon}, vertices={{lat,lon},...},
---@param p table
---@return boolean
function LGlobe:addProvince(p) end

--- Find the shortest province path from `from_id` to `to_id`.
---@param from_id integer
---@param to_id integer
---@return number
function LGlobe:findPath(from_id, to_id) end

--- Get the current camera (lat, lon, zoom).
---@return number
---@return number
---@return number
function LGlobe:getCamera() end

--- Returns the current LOD tier as a string: "far", "mid", or "near".
---@return string
function LGlobe:getLod() end

--- Get a string attribute from a marker.
---@param id integer
---@param key string
---@return string
function LGlobe:getMarkerAttr(id, key) end

--- Returns the string identifier name assigned to this globe instance.
---@return string
function LGlobe:getName() end

--- Returns the neighbor IDs of a province.
---@param id integer
---@return number
function LGlobe:getNeighbors(id) end

--- Gets a string attribute from a province.
---@param id integer
---@param key string
---@return string
function LGlobe:getProvinceAttr(id, key) end

--- Gets the current simulated time of day for daylight computation.
---@return number
function LGlobe:getTimeOfDay() end

--- Hide a province for a viewer.
---@param viewer string
---@param id integer
function LGlobe:hideProvince(viewer, id) end

--- Returns true if the province is visible to the viewer.
---@param viewer string
---@param id integer
---@return boolean
function LGlobe:isVisible(viewer, id) end

--- Move a marker to a new lat/lon.
---@param id integer
---@param lat number
---@param lon number
function LGlobe:moveMarker(id, lat, lon) end

--- Pan the orbit camera by delta-latitude and delta-longitude (degrees).
---@param dlat number
---@param dlon number
function LGlobe:pan(dlat, dlon) end

--- Returns the province ID under screen coordinates, or nil.
---@param sx number
---@param sy number
---@return number
function LGlobe:pick(sx, sy) end

--- Returns (lat, lon) of the screen point on the globe surface, or nil.
---@param sx number
---@param sy number
---@return number
function LGlobe:pickLatLon(sx, sy) end

--- Returns the number of provinces.
---@return number
function LGlobe:provinceCount() end

--- Return all provinces reachable within `max_cost` steps from `start_id`.
---@param start_id integer
---@param max_cost number
---@return number
function LGlobe:reachable(start_id, max_cost) end

--- Removes an arc from the globe map by its unique string identifier.
---@param id integer
function LGlobe:removeArc(id) end

--- Removes a text label from the globe map by its unique string identifier.
---@param id integer
function LGlobe:removeLabel(id) end

--- Removes a texture layer from the globe map by its unique string identifier.
---@param name string
function LGlobe:removeLayer(name) end

--- Removes a marker from the globe map by its unique string identifier.
---@param id integer
---@return boolean
function LGlobe:removeMarker(id) end

--- Removes a province by ID. Returns true if it existed.
---@param id integer
---@return boolean
function LGlobe:removeProvince(id) end

--- Reveal all provinces for a viewer.
---@param viewer string
function LGlobe:revealAll(viewer) end

--- Reveal a province for a viewer.
---@param viewer string
---@param id integer
function LGlobe:revealProvince(viewer, id) end

--- Set the faction/viewer whose fog mask filters rendering.
---@param viewer? string
function LGlobe:setActiveViewer(viewer) end

--- Enable or disable province border rendering.
---@param show boolean
function LGlobe:setBorders(show) end

--- Set the camera position directly.
---@param lat number
---@param lon number
---@param zoom number
function LGlobe:setCamera(lat, lon, zoom) end

--- Updates the visible text content of an existing globe label.
---@param id integer
---@param text string
function LGlobe:setLabelText(id, text) end

--- Sets whether this specific label is visible on the globe.
---@param id integer
---@param visible boolean
function LGlobe:setLabelVisible(id, visible) end

--- Set layer opacity (0.0–1.0).
---@param name string
---@param alpha number
function LGlobe:setLayerAlpha(name, alpha) end

--- Set a per-province color override on a layer.
---@param layer string
---@param province_id integer
---@param r number
---@param g number
---@param b number
---@param a number
function LGlobe:setLayerColor(layer, province_id, r, g, b, a) end

--- Sets whether this specific texture layer is visible on the globe.
---@param name string
---@param visible boolean
function LGlobe:setLayerVisible(name, visible) end

--- Set a string attribute on a marker.
---@param id integer
---@param key string
---@param value string
function LGlobe:setMarkerAttr(id, key, value) end

--- Sets whether this specific marker is visible on the globe.
---@param id integer
---@param visible boolean
function LGlobe:setMarkerVisible(id, visible) end

--- Sets a string attribute on a province.
---@param id integer
---@param key string
---@param value string
function LGlobe:setProvinceAttr(id, key, value) end

--- Set planet rotation (degrees).
---@param deg number
function LGlobe:setRotation(deg) end

--- Set time of day (0.0–24.0 hours).
---@param t number
function LGlobe:setTimeOfDay(t) end

--- Returns the type name of this object.
---@return string
function LGlobe:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LGlobe:typeOf(name) end

--- Advance globe simulation by dt seconds.
---@param dt number
function LGlobe:update(dt) end

--- Zoom the camera by a multiplier (>1 zooms in, <1 zooms out).
---@param factor number
function LGlobe:zoom(factor) end

--- Lua-accessible handle to the shared `GlobeRegistry`.
---@class LGlobeRegistry
LGlobeRegistry = {}

--- Get an existing globe by name, or nil.
---@param name string
---@return Globe?
function LGlobeRegistry:get(name) end

--- Returns a table of all globe names.
---@return string
function LGlobeRegistry:names() end

--- Create a globe with the given name and optional spec table.
---@param name string
---@param spec? table
---@return Globe
function LGlobeRegistry:new(name, spec) end

--- Removes a globe from the central registry by its string name.
---@param name string
---@return boolean
function LGlobeRegistry:remove(name) end

--- Returns the type name of this object.
---@return string
function LGlobeRegistry:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LGlobeRegistry:typeOf(name) end

--- Get an existing globe by name, or nil.
---@param name string
---@return Globe?
lurek.globe.get = function(name) end

--- Great-circle distance between two lat/lon points (in unit-sphere radians).
---@param lat1 number
---@param lon1 number
---@param lat2 number
---@param lon2 number
---@return number
lurek.globe.greatCircleDistance = function(lat1, lon1, lat2, lon2) end

--- Great-circle path as a table of {lat, lon} pairs.
---@param lat1 number
---@param lon1 number
---@param lat2 number
---@param lon2 number
---@param steps integer
---@return table
lurek.globe.greatCirclePath = function(lat1, lon1, lat2, lon2, steps) end

--- Convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z}.
---@param lat number
---@param lon number
---@return table
lurek.globe.latLonToUnit = function(lat, lon) end

--- Load provinces from a TOML string and create a globe.
---@param name string
---@param toml_src string
---@param spec? table
---@return Globe
lurek.globe.loadFromTOML = function(name, toml_src, spec) end

--- Creates a new globe instance with default settings and empty collections.
---@param name string
---@param spec? table
---@return Globe
lurek.globe.new = function(name, spec) end

---@class lurek.graph
lurek.graph = {}

--- Lua wrapper around a directed `Graph` with event callback registry.
---@class LGraph
LGraph = {}

--- Adds a directed edge between two nodes and returns its handle.
---@param from_ud Node
---@param to_ud Node
---@param edge_type? string
---@return Edge
function LGraph:addEdge(from_ud, to_ud, edge_type) end

--- Places an item at a node.
---@param item_ud GraphItem
---@param node_ud Node
---@return boolean
function LGraph:addItem(item_ud, node_ud) end

--- Adds a node and returns its handle.
---@param node_type? string
---@param capacity? integer
---@return Node
function LGraph:addNode(node_type, capacity) end

--- Finds the shortest path between two nodes using A*.
---@param from_node Node
---@param to_node Node
---@return table
function LGraph:astar(from_node, to_node) end

--- Assigns each node the smallest non-negative integer colour not shared with any
---@return table
function LGraph:colorGraph() end

--- Creates a new unplaced item and returns its handle.
---@param item_type? string
---@param decay_time? number
---@return GraphItem
function LGraph:createItem(item_type, decay_time) end

--- Finds the shortest path between two nodes using Dijkstra.
---@param from_ud Node
---@param to_ud Node
---@return table
function LGraph:findPath(from_ud, to_ud) end

--- Finds the shortest path for a specific item, filtering by item type.
---@param item_ud GraphItem
---@param from_ud Node
---@param to_ud Node
---@return table
function LGraph:findPathForItem(item_ud, from_ud, to_ud) end

--- Returns weakly connected components as a table of tables of Node handles.
---@return table
function LGraph:getComponents() end

--- Returns the shortest path distance, or nil if unreachable.
---@param from_ud Node
---@param to_ud Node
---@return number
function LGraph:getDistance(from_ud, to_ud) end

--- Returns the edge between two nodes, or nil if none exists.
---@param from_ud Node
---@param to_ud Node
---@return nil
function LGraph:getEdgeBetween(from_ud, to_ud) end

--- Returns the number of edges in the graph.
---@return number
function LGraph:getEdgeCount() end

--- Returns a table of all Edge handles.
---@return table
function LGraph:getEdges() end

--- Returns the number of items in the graph.
---@return number
function LGraph:getItemCount() end

--- Returns a table of all GraphItem handles.
---@return table
function LGraph:getItems() end

--- Returns a table of direct neighbor Node handles.
---@param node_ud Node
---@return table
function LGraph:getNeighbors(node_ud) end

--- Returns the number of nodes in the graph.
---@return number
function LGraph:getNodeCount() end

--- Returns a table of all Node handles.
---@return table
function LGraph:getNodes() end

--- Returns a table of Node handles reachable from the given node.
---@param from_ud Node
---@param max_dist? number
---@return table
function LGraph:getReachable(from_ud, max_dist) end

--- Returns a statistics snapshot table.
---@return table
function LGraph:getStats() end

--- Returns true if the graph contains a directed cycle.
---@return boolean
function LGraph:hasCycle() end

--- Returns true if the edge exists in the graph.
---@param edge_ud Edge
---@return boolean
function LGraph:hasEdge(edge_ud) end

--- Returns true if the item exists in the graph.
---@param item_ud GraphItem
---@return boolean
function LGraph:hasItem(item_ud) end

--- Returns true if the node exists in the graph.
---@param node_ud Node
---@return boolean
function LGraph:hasNode(node_ud) end

--- Returns `true` when the graph can be 2-coloured (bipartite check via BFS).
---@return boolean
function LGraph:isBipartite() end

--- Returns edge IDs forming a minimum spanning tree (Kruskal, undirected view).
---@return table
function LGraph:mst() end

--- Registers a callback for a graph simulation event.
---@param event_name string
---@param func function
---@return nil
function LGraph:on(event_name, func) end

--- Processes all supply/demand declarations and fires event callbacks.
---@return nil
function LGraph:processDemand() end

--- Removes an edge from the graph.
---@param edge_ud Edge
---@return boolean
function LGraph:removeEdge(edge_ud) end

--- Removes an item from the graph entirely.
---@param item_ud GraphItem
---@return boolean
function LGraph:removeItem(item_ud) end

--- Removes a node from the graph.
---@param node_ud Node
---@return boolean
function LGraph:removeNode(node_ud) end

--- Sends an item onto an edge to begin transit.
---@param item_ud GraphItem
---@param edge_ud Edge
---@return boolean
function LGraph:sendItem(item_ud, edge_ud) end

--- Runs one discrete simulation step and fires event callbacks.
---@return nil
function LGraph:step() end

--- Advances simulation by dt seconds using a parallelised decay phase.
---@param dt number
---@return nil
function LGraph:tickParallel(dt) end

--- Returns a topologically sorted table of Node handles, or nil if a cycle exists.
---@return table
function LGraph:topologicalSort() end

--- Returns the type name of this object.
---@return string
function LGraph:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LGraph:typeOf(name) end

--- Advances simulation by dt seconds and fires event callbacks.
---@param dt number
---@return nil
function LGraph:update(dt) end

--- Lua handle for an edge inside a `Graph`.
---@class LGraphEdge
LGraphEdge = {}

--- Adds an item type to the edge allow-list.
---@param t string
---@return nil
function LGraphEdge:addAllowedType(t) end

--- Clears the edge allow-list so all item types are permitted.
---@return nil
function LGraphEdge:clearAllowedTypes() end

--- Returns the edge capacity (-1 = unlimited).
---@return number
function LGraphEdge:getCapacity() end

--- Returns the cooldown duration in seconds.
---@return number
function LGraphEdge:getCooldown() end

--- Returns the source node handle.
---@return Node
function LGraphEdge:getFrom() end

--- Returns a table of GraphItem handles currently in transit on this edge.
---@return table
function LGraphEdge:getItemsInTransit() end

--- Returns the speed modifier applied to items in transit.
---@return number
function LGraphEdge:getSpeedModifier() end

--- Returns items per second this edge can transfer.
---@return number
function LGraphEdge:getThroughput() end

--- Returns the destination node handle.
---@return Node
function LGraphEdge:getTo() end

--- Returns the travel time in seconds for items on this edge.
---@return number
function LGraphEdge:getTravelTime() end

--- Returns the edge type string.
---@return string
function LGraphEdge:getType() end

--- Returns the pathfinding weight of this edge.
---@return number
function LGraphEdge:getWeight() end

--- Returns true if the edge is active.
---@return boolean
function LGraphEdge:isActive() end

--- Returns true if items can travel the edge in either direction.
---@return boolean
function LGraphEdge:isBidirectional() end

--- Returns true if the given item type is allowed on this edge.
---@param t string
---@return boolean
function LGraphEdge:isItemTypeAllowed(t) end

--- Returns true if the edge is currently on cooldown.
---@return boolean
function LGraphEdge:isOnCooldown() end

--- Removes an item type from the edge allow-list.
---@param t string
---@return boolean
function LGraphEdge:removeAllowedType(t) end

--- Sets the active state of this edge.
---@param a boolean
---@return nil
function LGraphEdge:setActive(a) end

--- Sets whether items can travel the edge in either direction.
---@param b boolean
---@return nil
function LGraphEdge:setBidirectional(b) end

--- Sets the edge capacity (-1 = unlimited).
---@param c integer
---@return nil
function LGraphEdge:setCapacity(c) end

--- Sets the cooldown duration in seconds.
---@param c number
---@return nil
function LGraphEdge:setCooldown(c) end

--- Sets the speed modifier applied to items in transit.
---@param m number
---@return nil
function LGraphEdge:setSpeedModifier(m) end

--- Sets items per second this edge can transfer.
---@param t number
---@return nil
function LGraphEdge:setThroughput(t) end

--- Sets the travel time in seconds for items on this edge.
---@param t number
---@return nil
function LGraphEdge:setTravelTime(t) end

--- Sets the edge type string.
---@param t string
---@return nil
function LGraphEdge:setType(t) end

--- Sets the pathfinding weight of this edge.
---@param w number
---@return nil
function LGraphEdge:setWeight(w) end

--- Returns the type name "GraphEdge".
---@return string
function LGraphEdge:type() end

--- Returns true when the given name matches "GraphEdge" or a parent type.
---@param name string
---@return boolean
function LGraphEdge:typeOf(name) end

--- Lua handle for an item inside a `Graph`.
---@class LGraphItem
LGraphItem = {}

--- Returns the decay time in seconds (-1 = immortal).
---@return number
function LGraphItem:getDecayTime() end

--- Returns the item position: node userdata if at a node, (edge, progress)
---@return nil
function LGraphItem:getPosition() end

--- Returns the item priority.
---@return number
function LGraphItem:getPriority() end

--- Returns the remaining life in seconds.
---@return number
function LGraphItem:getRemainingLife() end

--- Returns the item type string.
---@return string
function LGraphItem:getType() end

--- Returns true if the item is alive.
---@return boolean
function LGraphItem:isAlive() end

--- Marks this graph item as dead so it is removed on the next cleanup pass.
---@return nil
function LGraphItem:kill() end

--- Sets the decay time in seconds (-1 = immortal).
---@param t number
---@return nil
function LGraphItem:setDecayTime(t) end

--- Sets the scheduling priority; higher values are processed before lower ones.
---@param p integer
---@return nil
function LGraphItem:setPriority(p) end

--- Sets the item type string.
---@param t string
---@return nil
function LGraphItem:setType(t) end

--- Returns the type name of this object.
---@return string
function LGraphItem:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LGraphItem:typeOf(name) end

--- Lua handle for a node inside a `Graph`.
---@class LGraphNode
LGraphNode = {}

--- Declares a demand for the given item type, quantity, and priority.
---@param item_type string
---@param quantity integer
---@param priority? integer
---@return nil
function LGraphNode:addDemand(item_type, quantity, priority) end

--- Declares a supply of the given item type and quantity at this node.
---@param item_type string
---@param quantity integer
---@return nil
function LGraphNode:addSupply(item_type, quantity) end

--- Attaches a string tag to this node for fast group queries.
---@param tag string
---@return nil
function LGraphNode:addTag(tag) end

--- Removes all conversion rules from this node.
---@return nil
function LGraphNode:clearAllConversions() end

--- Removes the conversion rule for the given input type.
---@param in_type string
---@return nil
function LGraphNode:clearConversion(in_type) end

--- Removes all demand declarations from this node.
---@return nil
function LGraphNode:clearDemands() end

--- Removes all supply declarations from this node.
---@return nil
function LGraphNode:clearSupplies() end

--- Removes all tags from this node.
---@return nil
function LGraphNode:clearTags() end

--- Pops the next item from the node queue, or nil if empty.
---@return nil
function LGraphNode:dequeue() end

--- Pushes an item into the node queue.
---@param item_ud GraphItem
---@return boolean
function LGraphNode:enqueue(item_ud) end

--- Returns the node capacity (-1 = unlimited).
---@return number
function LGraphNode:getCapacity() end

--- Returns a table of Edge handles connected to this node.
---@param dir? string
---@return table
function LGraphNode:getEdges(dir) end

--- Returns the flow mode as a string.
---@return string
function LGraphNode:getFlowMode() end

--- Returns the number of items currently at this node.
---@return number
function LGraphNode:getItemCount() end

--- Returns a table of GraphItem handles at this node.
---@return table
function LGraphNode:getItems() end

--- Returns the overflow policy as a string.
---@return string
function LGraphNode:getOverflowPolicy() end

--- Returns the processing time in seconds.
---@return number
function LGraphNode:getProcessTime() end

--- Returns the pull filter string, or nil if unset.
---@return string
function LGraphNode:getPullFilter() end

--- Returns items per second this node pulls.
---@return number
function LGraphNode:getPullRate() end

--- Returns the push filter string, or nil if unset.
---@return string
function LGraphNode:getPushFilter() end

--- Returns items per second this node pushes.
---@return number
function LGraphNode:getPushRate() end

--- Returns the queue capacity (-1 = unlimited).
---@return number
function LGraphNode:getQueueCapacity() end

--- Returns the number of items currently in the queue.
---@return number
function LGraphNode:getQueueSize() end

--- Returns a table of tag strings on this node.
---@return table
function LGraphNode:getTags() end

--- Returns the node type string.
---@return string
function LGraphNode:getType() end

--- Returns true if this node has the given tag.
---@param tag string
---@return boolean
function LGraphNode:hasTag(tag) end

--- Returns true if the node is active.
---@return boolean
function LGraphNode:isActive() end

--- Returns true if the node has reached its capacity.
---@return boolean
function LGraphNode:isFull() end

--- Returns true if the node queue is enabled.
---@return boolean
function LGraphNode:isQueueEnabled() end

--- Removes the demand declaration for the given item type.
---@param item_type string
---@return boolean
function LGraphNode:removeDemand(item_type) end

--- Removes the supply declaration for the given item type.
---@param item_type string
---@return boolean
function LGraphNode:removeSupply(item_type) end

--- Removes a tag from this node.
---@param tag string
---@return boolean
function LGraphNode:removeTag(tag) end

--- Sets the active state of this node.
---@param a boolean
---@return nil
function LGraphNode:setActive(a) end

--- Sets the node capacity (-1 = unlimited).
---@param c integer
---@return nil
function LGraphNode:setCapacity(c) end

--- Adds or replaces a conversion rule on this node.
---@param in_type string
---@param out_type string
---@param in_count? integer
---@param out_count? integer
---@return nil
function LGraphNode:setConversion(in_type, out_type, in_count, out_count) end

--- Sets the flow mode from a string.
---@param m string
---@return nil
function LGraphNode:setFlowMode(m) end

--- Sets the overflow policy from a string.
---@param p string
---@return nil
function LGraphNode:setOverflowPolicy(p) end

--- Sets the processing time in seconds.
---@param t number
---@return nil
function LGraphNode:setProcessTime(t) end

--- Sets the pull filter string, or nil to clear.
---@param f? string
---@return nil
function LGraphNode:setPullFilter(f) end

--- Sets items per second this node pulls.
---@param r number
---@return nil
function LGraphNode:setPullRate(r) end

--- Sets the push filter string, or nil to clear.
---@param f? string
---@return nil
function LGraphNode:setPushFilter(f) end

--- Sets items per second this node pushes.
---@param r number
---@return nil
function LGraphNode:setPushRate(r) end

--- Sets the queue capacity (-1 = unlimited).
---@param c integer
---@return nil
function LGraphNode:setQueueCapacity(c) end

--- Enables or disables the node queue.
---@param e boolean
---@return nil
function LGraphNode:setQueueEnabled(e) end

--- Sets the node type string.
---@param t string
---@return nil
function LGraphNode:setType(t) end

--- Returns the type name "GraphNode".
---@return string
function LGraphNode:type() end

--- Returns true when the given name matches "GraphNode" or a parent type.
---@param name string
---@return boolean
function LGraphNode:typeOf(name) end

--- Creates a new empty directed graph for item flow simulation.
---@param opts? table
---@return Graph
lurek.graph.newGraph = function(opts) end

---@class lurek.html
lurek.html = {}

--- Lua wrapper around a shared `HtmlDocument` and its callback registry.
---@class LHtmlDocument
LHtmlDocument = {}

--- Appends stylesheet text after existing CSS rules.
---@param css string
---@return nil
function LHtmlDocument:addCss(css) end

--- Removes all stylesheet rules from this document.
---@return nil
function LHtmlDocument:clearCss() end

--- Builds the current draw command list and discards it for now.
---@param x? number
---@param y? number
---@return nil
function LHtmlDocument:draw(x, y) end

--- Finds the first element whose id attribute matches the given value, or nil.
---@param id string
---@return HtmlElement?
function LHtmlDocument:getElementById(id) end

--- Returns the source markup used by this document.
---@return string
function LHtmlDocument:getHtml() end

--- Returns the root element for this document.
---@return HtmlElement
function LHtmlDocument:getRoot() end

--- Returns the document layout viewport in UI pixels.
---@return number
---@return number
function LHtmlDocument:getViewport() end

--- Returns whether DOM, CSS, viewport, or layout state changed.
---@return boolean
function LHtmlDocument:isDirty() end

--- Forwards a key press and emits a keydown event.
---@param key string
---@return boolean
function LHtmlDocument:keypressed(key) end

--- Forwards a mouse move event.
---@param x number
---@param y number
---@return boolean
function LHtmlDocument:mousemoved(x, y) end

--- Forwards a mouse press and emits a minimal click event.
---@param x number
---@param y number
---@param button? integer
---@return boolean
function LHtmlDocument:mousepressed(x, y, button) end

--- Forwards a mouse release event.
---@param x number
---@param y number
---@param button? integer
---@return boolean
function LHtmlDocument:mousereleased(x, y, button) end

--- Removes a document-level event listener.
---@param handle integer
---@return nil
function LHtmlDocument:off(handle) end

--- Registers a document-level event listener.
---@param event string
---@param fn function
---@return number
function LHtmlDocument:on(event, fn) end

--- Finds the first element matching a supported selector.
---@param selector string
---@return HtmlElement?
function LHtmlDocument:query(selector) end

--- Returns all elements matching a supported selector in document order.
---@param selector string
---@return table
function LHtmlDocument:queryAll(selector) end

--- Forces a layout pass immediately.
---@return nil
function LHtmlDocument:relayout() end

--- Replaces this document's stylesheet text.
---@param css string
---@return nil
function LHtmlDocument:setCss(css) end

--- Replaces this document's markup and invalidates existing element handles.
---@param html string
---@return nil
function LHtmlDocument:setHtml(html) end

--- Sets the document layout viewport in UI pixels.
---@param w number
---@param h number
---@return nil
function LHtmlDocument:setViewport(w, h) end

--- Forwards text input and emits an input event for focused input elements.
---@param text string
---@return boolean
function LHtmlDocument:textinput(text) end

--- Returns the type name of this object.
---@return string
function LHtmlDocument:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LHtmlDocument:typeOf(name) end

--- Advances document state and runs layout if needed.
---@param dt number
---@return nil
function LHtmlDocument:update(dt) end

--- Forwards a mouse wheel event.
---@param dx number
---@param dy number
---@return boolean
function LHtmlDocument:wheelmoved(dx, dy) end

--- Lua wrapper that references a single element inside a shared `HtmlDocument`.
---@class LHtmlElement
LHtmlElement = {}

--- Adds a CSS class to this element.
---@param name string
---@return nil
function LHtmlElement:addClass(name) end

--- Appends HTML inside this element.
---@param html string
---@return nil
function LHtmlElement:appendHtml(html) end

--- Clears focus from this element if it currently has focus.
---@return nil
function LHtmlElement:blur() end

--- Gives focus to this element.
---@return nil
function LHtmlElement:focus() end

--- Returns an attribute value or nil.
---@param name string
---@return string
function LHtmlElement:getAttribute(name) end

--- Returns the owning HtmlDocument.
---@return HtmlDocument
function LHtmlElement:getDocument() end

--- Returns this element's inner HTML.
---@return string
function LHtmlElement:getHtml() end

--- Returns this element's id or nil.
---@return string
function LHtmlElement:getId() end

--- Returns this element's last computed layout rectangle.
---@return number
---@return number
---@return number
---@return number
function LHtmlElement:getRect() end

--- Returns an inline or stylesheet value for a property.
---@param name string
---@return string
function LHtmlElement:getStyle(name) end

--- Returns this element's tag name.
---@return string
function LHtmlElement:getTagName() end

--- Returns this element's text content.
---@return string
function LHtmlElement:getText() end

--- Returns whether this element has a CSS class.
---@param name string
---@return boolean
function LHtmlElement:hasClass(name) end

--- Removes an element event listener.
---@param handle integer
---@return nil
function LHtmlElement:off(handle) end

--- Registers an element event listener.
---@param event string
---@param fn function
---@return number
function LHtmlElement:on(event, fn) end

--- Finds the first descendant matching a selector.
---@param selector string
---@return HtmlElement?
function LHtmlElement:query(selector) end

--- Returns all descendants matching a selector.
---@param selector string
---@return table
function LHtmlElement:queryAll(selector) end

--- Removes this element from the document tree.
---@return nil
function LHtmlElement:remove() end

--- Removes the named attribute from this element; does nothing if absent.
---@param name string
---@return nil
function LHtmlElement:removeAttribute(name) end

--- Removes a CSS class from this element.
---@param name string
---@return nil
function LHtmlElement:removeClass(name) end

--- Sets or removes an attribute value.
---@param name string
---@param value? string
---@return nil
function LHtmlElement:setAttribute(name, value) end

--- Replaces this element's inner HTML.
---@param html string
---@return nil
function LHtmlElement:setHtml(html) end

--- Sets or removes this element's id.
---@param id? string
---@return nil
function LHtmlElement:setId(id) end

--- Sets or removes an inline style value.
---@param name string
---@param value? string
---@return nil
function LHtmlElement:setStyle(name, value) end

--- Replaces this element's text content.
---@param text string
---@return nil
function LHtmlElement:setText(text) end

--- Toggles a CSS class and returns the final state.
---@param name string
---@param force? boolean
---@return boolean
function LHtmlElement:toggleClass(name, force) end

--- Returns the type name of this object.
---@return string
function LHtmlElement:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LHtmlElement:typeOf(name) end

--- Returns true if `preventDefault` has been called on this event.
---@return boolean
lurek.html.isDefaultPrevented = function() end

--- Placeholder for future sandboxed document loading.
---@param path string
---@param opts? table
---@return HtmlDocument
lurek.html.loadDocument = function(path, opts) end

--- Creates a detached HTML document from markup and optional CSS/viewport options.
---@param html? string
---@param opts? table
---@return HtmlDocument
lurek.html.newDocument = function(html, opts) end

--- Prevents the default browser action associated with this event.
lurek.html.preventDefault = function() end

--- Stops the event from bubbling up to parent elements.
lurek.html.stopPropagation = function() end

--- Returns whether the active HTML facade supports a named feature.
---@param feature string
---@return boolean
lurek.html.supports = function(feature) end

---@class lurek.i18n
lurek.i18n = {}

--- Builds an inverted word index for the active locale. Returns index as {word â†’ {keys}}.
---@return table
lurek.i18n.buildIndex = function() end

--- Returns unique first-path-segment category prefixes for all active locale keys.
---@return table
lurek.i18n.categories = function() end

--- Formats a Unix timestamp according to the active locale's date order.
---@param timestamp integer
---@param fmt? string
---@return string
lurek.i18n.formatDate = function(timestamp, fmt) end

--- Formats a number with locale-aware decimal and thousands separators.
---@param n number
---@param opts? table
---@return string
lurek.i18n.formatNumber = function(n, opts) end

--- Returns all loaded locale codes (alias for getLanguages).
---@return table
lurek.i18n.getAvailableLanguages = function() end

--- Returns the base/fallback language.
---@return string
lurek.i18n.getBase = function() end

--- Returns the current fallback locale array.
---@return table
lurek.i18n.getFallbacks = function() end

--- Returns all known keys for the active locale.
---@return table
lurek.i18n.getKeys = function() end

--- Returns the currently active locale code, or nil if unset.
---@return string
lurek.i18n.getLanguage = function() end

--- Returns all loaded locale codes.
---@return table
lurek.i18n.getLanguages = function() end

--- Returns an array of all currently loaded locale codes.
---@return table
lurek.i18n.getLoadedLocales = function() end

--- Returns whether a key exists in the active locale.
---@param key string
---@return boolean
lurek.i18n.hasKey = function(key) end

--- Returns whether a locale has been loaded.
---@param locale string
---@return boolean
lurek.i18n.hasLanguage = function(locale) end

--- Interpolates {name} placeholders in a template string.
---@param template string
---@param vars table
---@return string
lurek.i18n.interpolate = function(template, vars) end

--- Returns the number of keys loaded in the active locale.
---@return number
lurek.i18n.keyCount = function() end

--- Returns all keys in the active locale whose first path segment matches category.
---@param category string
---@return table
lurek.i18n.keysInCategory = function(category) end

--- Loads a language table under the given locale code.
---@param locale string
---@param table table
---@return nil
lurek.i18n.loadTable = function(locale, table) end

--- Merges a flat keyâ†’value table into an existing locale without replacing the whole table.
---@param locale string
---@param entries table
---@return nil
lurek.i18n.mergeLocale = function(locale, entries) end

--- Unregisters all onChange callbacks (cb arg is ignored; all callbacks are cleared).
---@param cb? function
---@return nil
lurek.i18n.offChange = function(cb) end

--- Registers a callback invoked when setLanguage() is called (alias: onChange).
---@param cb function
---@return nil
lurek.i18n.onChange = function(cb) end

--- Registers a callback invoked when setLanguage() is called.
---@param cb function
---@return nil
lurek.i18n.onLanguageChange = function(cb) end

--- Returns the CLDR plural category for a number ("one" or "other", etc.).
---@param n number
---@return string
lurek.i18n.pluralFor = function(n) end

--- Searches active locale values for a substring query (case-insensitive). Returns {key, value} pairs.
---@param query string
---@param limit? integer
---@return table
lurek.i18n.search = function(query, limit) end

--- Searches the provided pre-built index for entries matching all words in query.
---@param index table
---@param query string
---@param limit? integer
---@return table
lurek.i18n.searchIndexed = function(index, query, limit) end

--- Sets the base/fallback language (adds it as first fallback).
---@param locale string
---@return nil
lurek.i18n.setBase = function(locale) end

--- Sets the ordered list of fallback locale codes tried when a key is missing.
---@param locales table
---@return nil
lurek.i18n.setFallbacks = function(locales) end

--- Inserts or overwrites a single key in the given locale.
---@param locale string
---@param key string
---@param value string
---@return nil
lurek.i18n.setKey = function(locale, key, value) end

--- Sets the active translation language.
---@param locale string
---@return nil
lurek.i18n.setLanguage = function(locale) end

--- Translates a key against the active locale with optional variable
---@param key string
---@param vars? table
---@param count? number
---@return string
lurek.i18n.t = function(key, vars, count) end

--- Looks up a translation key augmented with a gender suffix.
---@param key string
---@param gender string
---@param vars? table
---@return string
lurek.i18n.tGender = function(key, gender, vars) end

--- Unloads a locale from the catalog.
---@param locale string
---@return boolean
lurek.i18n.unloadTable = function(locale) end

---@class lurek.image
lurek.image = {}

--- Lua-side wrapper around [`CompressedImageData`].
---@class LCompressedImageData
LCompressedImageData = {}

--- Returns the width and height of the base mip level.
---@return integer
---@return integer
function LCompressedImageData:getDimensions() end

--- Returns the compressed format name string.
---@return string
function LCompressedImageData:getFormat() end

--- Returns the height of the base mip level in pixels.
---@return number
function LCompressedImageData:getHeight() end

--- Returns the number of mipmap levels stored.
---@return number
function LCompressedImageData:getMipmapCount() end

--- Returns the width of the base mip level in pixels.
---@return number
function LCompressedImageData:getWidth() end

--- Returns the type name of this object.
---@return string
function LCompressedImageData:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LCompressedImageData:typeOf(name) end

--- RGBA pixel buffer for software image manipulation, pixel access, and encoding.
---@class LImageData
LImageData = {}

--- Scales every pixel's alpha channel by factor; use to fade an image in or out uniformly.
---@param factor number
---@return nil
function LImageData:alphaMask(factor) end

--- Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
---@param lut PaletteLUT
---@return nil
function LImageData:applyPaletteLut(lut) end

--- Blits the source ImageData onto this image at (dst_x, dst_y) using Porter-Duff over.
---@param src ImageData
---@param dst_x integer
---@param dst_y integer
---@return nil
function LImageData:blit(src, dst_x, dst_y) end

--- Returns a new ImageData with a box blur applied using the given pixel radius.
---@param radius integer
---@return ImageData
function LImageData:blur(radius) end

--- Adjusts the brightness of every pixel by the given factor (< 1.0 darkens, > 1.0 brightens).
---@param factor number
---@return nil
function LImageData:brightness(factor) end

--- Adjusts the contrast of every pixel by the given factor (< 1.0 reduces, > 1.0 increases).
---@param factor number
---@return nil
function LImageData:contrast(factor) end

--- Applies a custom NxN convolution kernel to the image and returns a new ImageData.
---@param kernel table
---@param ksize integer
---@return ImageData
function LImageData:convolve(kernel, ksize) end

--- Returns a new ImageData containing the rectangular sub-region at (x, y) of the given width and height.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@return ImageData
function LImageData:crop(x, y, w, h) end

--- Returns the sum of absolute per-channel pixel differences with another ImageData.
---@param other ImageData
---@return number
function LImageData:diff(other) end

--- Draws a filled circle onto the image.
---@param cx integer
---@param cy integer
---@param radius integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@return nil
function LImageData:drawCircle(cx, cy, radius, r, g, b, a) end

--- Draws a line using Bresenham's algorithm.
---@param x0 integer
---@param y0 integer
---@param x1 integer
---@param y1 integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@return nil
function LImageData:drawLine(x0, y0, x1, y1, r, g, b, a) end

--- Draws a filled rectangle onto the image.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@return nil
function LImageData:drawRect(x, y, w, h, r, g, b, a) end

--- Encodes the image into a byte string in the specified format (currently "png").
---@param format string
---@return string
function LImageData:encode(format) end

--- Fills every pixel with the given solid RGBA colour, overwriting all existing content.
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@return nil
function LImageData:fill(r, g, b, a) end

--- Flips the image left-to-right (mirror across vertical axis), modifying in place.
---@return nil
function LImageData:flipHorizontal() end

--- Flips the image top-to-bottom (mirror across horizontal axis), modifying in place.
---@return nil
function LImageData:flipVertical() end

--- Applies gamma correction; values < 1.0 brighten shadows, > 1.0 darken them.
---@param gamma number
---@return nil
function LImageData:gamma(gamma) end

--- Returns the width and height of the image as two integers.
---@return integer
---@return integer
function LImageData:getDimensions() end

--- Returns the height of the image in pixels.
---@return number
function LImageData:getHeight() end

--- Returns the RGBA colour components of the pixel at (x, y) as four integers (0-255).
---@param x integer
---@param y integer
---@return integer
---@return integer
---@return integer
---@return integer
function LImageData:getPixel(x, y) end

--- Returns a copy of the rectangular sub-region as a new ImageData.
---@param x integer
---@param y integer
---@param width integer
---@param height integer
---@return ImageData?
function LImageData:getRegion(x, y, width, height) end

--- Returns the raw pixel bytes of the image as a Lua string.
---@return string
function LImageData:getString() end

--- Returns the width of the image in pixels.
---@return number
function LImageData:getWidth() end

--- Converts the image to grayscale using luminance weights (BT.601).
---@return nil
function LImageData:grayscale() end

--- Inverts every colour channel (subtracts each R/G/B value from 255); alpha is preserved.
---@return nil
function LImageData:invert() end

--- Calls func(x, y, r, g, b, a) for each pixel and writes the returned RGBA back.
---@param func function
---@return nil
function LImageData:mapPixel(func) end

--- Applies a function to every pixel in-place.
---@param fn function
---@return nil
function LImageData:mapPixels(fn) end

--- Adds random noise to every pixel channel; amount controls the maximum per-channel perturbation.
---@param amount integer
---@return nil
function LImageData:noise(amount) end

--- Copies pixels from `source` onto this image starting at (dx, dy).
---@param source ImageData
---@param dx integer
---@param dy integer
---@return nil
function LImageData:paste(source, dx, dy) end

--- Reduces each channel to `levels` discrete steps, creating a flat poster-paint look.
---@param levels integer
---@return nil
function LImageData:posterize(levels) end

--- Returns a bilinear-interpolated copy of the image at the given dimensions.
---@param width integer
---@param height integer
---@return ImageData?
function LImageData:resize(width, height) end

--- Returns a new ImageData scaled to (new_w, new_h) using nearest-neighbour interpolation.
---@param new_w integer
---@param new_h integer
---@return ImageData
function LImageData:resizeNearest(new_w, new_h) end

--- Returns a new ImageData rotated 90 degrees clockwise; the original is not modified.
---@return ImageData
function LImageData:rotate90cw() end

--- Adjusts colour saturation; 0.0 produces grayscale, 1.0 is unchanged, > 1.0 boosts saturation.
---@param factor number
---@return nil
function LImageData:saturation(factor) end

--- Applies a warm sepia tone to the image using standard sepia matrix weights.
---@return nil
function LImageData:sepia() end

--- Sets the RGBA colour of the pixel at (x, y); returns an error if coordinates are out of bounds.
---@param x integer
---@param y integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@return nil
function LImageData:setPixel(x, y, r, g, b, a) end

--- Replaces all pixel data from a raw RGBA byte string.
---@param bytes string
---@return nil
function LImageData:setRawData(bytes) end

--- Returns a new ImageData with a sharpening convolution kernel applied.
---@return ImageData
function LImageData:sharpen() end

--- Converts the image to black-and-white: pixels above value become white, at or below become black.
---@param value integer
---@return nil
function LImageData:threshold(value) end

--- Blends an RGB tint colour into every pixel, controlled by factor (0.0 = no change, 1.0 = full tint).
---@param tr integer
---@param tg integer
---@param tb integer
---@param factor number
---@return nil
function LImageData:tint(tr, tg, tb, factor) end

--- Returns the type name of this object.
---@return string
function LImageData:type() end

--- Returns true if this object is of the given type name.
---@param name string
---@return boolean
function LImageData:typeOf(name) end

--- Lua-side wrapper around [`LayeredImage`].
---@class LLayeredImage
LLayeredImage = {}

--- Appends a new blank transparent layer on top and returns its 1-based index.
---@param name? string
---@return number
function LLayeredImage:addLayer(name) end

--- Returns the canvas height shared by all layers.
---@return number
function LLayeredImage:getHeight() end

--- Returns a copy of the layer's pixel buffer as an ImageData.
---@param index integer
---@return ImageData
function LLayeredImage:getLayer(index) end

--- Returns the name of a layer.
---@param index integer
---@return string
function LLayeredImage:getName(index) end

--- Returns the opacity of a layer in [0.0, 1.0].
---@param index integer
---@return number
function LLayeredImage:getOpacity(index) end

--- Returns the canvas width shared by all layers.
---@return number
function LLayeredImage:getWidth() end

--- Returns whether a layer is visible.
---@param index integer
---@return boolean
function LLayeredImage:isVisible(index) end

--- Returns the number of layers in the stack.
---@return number
function LLayeredImage:layerCount() end

--- Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
---@return ImageData
function LLayeredImage:merge() end

--- Moves a layer from one position to another, shifting layers in between.
---@param from_index integer
---@param to_index integer
---@return boolean
function LLayeredImage:moveLayer(from_index, to_index) end

--- Removes the layer at the given 1-based index. Returns true on success.
---@param index integer
---@return boolean
function LLayeredImage:removeLayer(index) end

--- Saves the layered image to a LIMG binary file at the given path.
---@param path string
---@return nil
function LLayeredImage:save(path) end

--- Replaces a layer's pixel buffer with a copy of the given ImageData.
---@param index integer
---@param imagedata ImageData
---@return boolean
function LLayeredImage:setLayer(index, imagedata) end

--- Renames the layer at the given index to the new name string.
---@param index integer
---@param name string
---@return boolean
function LLayeredImage:setName(index, name) end

--- Sets the opacity of a layer. Value is clamped to [0.0, 1.0].
---@param index integer
---@param opacity number
---@return boolean
function LLayeredImage:setOpacity(index, opacity) end

--- Shows or hides a layer during compositing.
---@param index integer
---@param visible boolean
---@return boolean
function LLayeredImage:setVisible(index, visible) end

--- Swaps two layers by their 1-based indices, changing their compositing order.
---@param a integer
---@param b integer
---@return boolean
function LLayeredImage:swapLayers(a, b) end

--- Returns the type name of this object.
---@return string
function LLayeredImage:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LLayeredImage:typeOf(name) end

--- Lua-side wrapper around [`PaletteLUT`].
---@class LPaletteLUT
LPaletteLUT = {}

--- Removes all colour mapping entries.
---@return nil
function LPaletteLUT:clear() end

--- Returns the number of colour mapping entries.
---@return number
function LPaletteLUT:getColorCount() end

--- Appends a colour mapping entry to the palette: when a pixel exactly matching
---@param from_r integer
---@param from_g integer
---@param from_b integer
---@param from_a integer
---@param to_r integer
---@param to_g integer
---@param to_b integer
---@param to_a integer
---@return nil
function LPaletteLUT:setColor(from_r, from_g, from_b, from_a, to_r, to_g, to_b, to_a) end

--- Returns the type name of this object.
---@return string
function LPaletteLUT:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LPaletteLUT:typeOf(name) end

--- Lua-side wrapper around [`ProvinceGrid`].
---@class LProvinceGrid
LProvinceGrid = {}

--- Returns an array of adjacency records. Each record is {province_a, province_b, border_pixels}.
---@return table
function LProvinceGrid:adjacencies() end

--- Returns the province ID at pixel coordinates (x, y). Returns 0 for background or out-of-bounds.
---@param x integer
---@param y integer
---@return number
function LProvinceGrid:getAt(x, y) end

--- Returns the grid height in pixels.
---@return number
function LProvinceGrid:getHeight() end

--- Returns the grid width in pixels.
---@return number
function LProvinceGrid:getWidth() end

--- Returns the number of unique non-zero province IDs detected in the map.
---@return number
function LProvinceGrid:provinceCount() end

--- Returns the type name of this object.
---@return string
function LProvinceGrid:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LProvinceGrid:typeOf(name) end

--- Returns true if the file at the given path is a DDS file.
---@param filename string
---@return boolean
lurek.image.isCompressed = function(filename) end

--- Loads an ImageData from a LIMG binary file.
---@param path string
---@return ImageData
lurek.image.loadImage = function(path) end

--- Loads a LayeredImage from a LIMG binary file.
---@param path string
---@return LayeredImage
lurek.image.loadLayered = function(path) end

--- Loads compressed texture data from a DDS file.
---@param filename string
---@return CompressedImageData
lurek.image.newCompressedData = function(filename) end

--- Creates a new blank ImageData or loads one from a file.
---@param ... integer|string|integer|nil
---@return ImageData
lurek.image.newImageData = function(...) end

--- Creates a new empty LayeredImage canvas with no layers.
---@param width integer
---@param height integer
---@return LayeredImage
lurek.image.newLayeredImage = function(width, height) end

--- Creates a new empty `PaletteLUT` used to remap colours in an image.
---@return PaletteLUT
lurek.image.newPaletteLut = function() end

--- Loads a province map PNG and builds an O(1) spatial index with adjacency data.
---@param filename string
---@return ProvinceGrid
lurek.image.newProvinceGrid = function(filename) end

--- Saves a flat ImageData to a LIMG binary file at the given path.
---@param imagedata ImageData
---@param path string
---@return nil
lurek.image.saveImage = function(imagedata, path) end

--- Saves a flat ImageData as a PNG file at the given path.
---@param imagedata ImageData
---@param path string
---@return nil
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

--- Feed a key-press event into the combo detector.
---@param key string
---@return nil
function LCombo:feed(key) end

--- Returns the step at the given 1-based index as `{key=..., gap_ms=...}`.
---@param index integer
---@return nil
function LCombo:getStep(index) end

--- Returns true if the detector is currently mid-sequence.
---@return boolean
function LCombo:isInProgress() end

--- Returns the number of steps matched so far (0 when idle).
---@return number
function LCombo:progress() end

--- Reset the detector to its initial idle state, cancelling any in-progress sequence.
---@return nil
function LCombo:reset() end

--- Advance the internal clock by `dt` seconds and check for timeouts.
---@param dt number
---@return nil
function LCombo:tick(dt) end

--- Returns the total number of steps in the combo sequence.
---@return number
function LCombo:totalSteps() end

--- Returns the type name of this object.
---@return string
function LCombo:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LCombo:typeOf(name) end

--- Lua-side wrapper around a mouse cursor handle.
---@class LCursor
LCursor = {}

--- Returns the cursor type as "system" or "custom".
---@return string
function LCursor:getType() end

--- Releases the cursor resource (no-op on desktop).
---@return nil
function LCursor:release() end

--- Returns the type name of this object.
---@return string
function LCursor:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LCursor:typeOf(name) end

--- Lua userdata wrapper for a completed [`crate::input::recorder::InputRecording`].
---@class LInputRecording
LInputRecording = {}

--- Returns the number of sparse event frames stored in this recording.
---@return number
function LInputRecording:frameCount() end

--- Serializes this recording to a JSON string for saving to disk.
---@return string
function LInputRecording:toJson() end

--- Returns the total frame count when recording was stopped.
---@return number
function LInputRecording:totalFrames() end

--- Returns the type name of this object.
---@return string
function LInputRecording:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LInputRecording:typeOf(name) end

--- Advances playback by one frame and returns an array of key/button events for that
---@return table
lurek.input.advancePlayback = function() end

--- Maps an action name to one or more key/button names.
---@param action string
---@param keys string|table
---@return nil
lurek.input.bind = function(action, keys) end

--- Removes all action bindings.
---@return nil
lurek.input.clearBindings = function() end

--- Returns the current value (-1 to 1) of a gamepad analog axis.
---@param id integer
---@param axis integer
---@return number
lurek.input.gamepad.getAxis = function(id, axis) end

--- Returns the total number of analog axes on the gamepad.
---@param id integer
---@return number
lurek.input.gamepad.getAxisCount = function(id) end

--- Returns whether background gamepad events are enabled.
---@return boolean
lurek.input.gamepad.getBackgroundEvents = function() end

--- Returns a table mapping each action name to its bound keys.
---@return table
lurek.input.getBindings = function() end

--- Returns the total number of buttons on the gamepad.
---@param id integer
---@return number
lurek.input.gamepad.getButtonCount = function(id) end

--- Returns the number of connected gamepads.
---@return number
lurek.input.gamepad.getCount = function() end

--- Returns the name of the currently active system cursor.
---@return string
lurek.input.mouse.getCursor = function() end

--- Returns the hardware GUID string of the gamepad.
---@param id integer
---@return string
lurek.input.gamepad.getGUID = function(id) end

--- Returns the stored mapping string for the given GUID, or nil.
---@param guid string
---@return string
lurek.input.gamepad.getGamepadMappingString = function(guid) end

--- Returns the direction string of a hat switch on the gamepad.
---@param id integer
---@param hat integer
---@return string
lurek.input.gamepad.getHat = function(id, hat) end

--- Returns the number of tracked gamepad slots.
---@return number
lurek.input.gamepad.getJoystickCount = function() end

--- Returns a list of connected gamepad IDs.
---@return table
lurek.input.gamepad.getJoysticks = function() end

--- Returns the key name for the given hardware scancode.
---@param scancode string
---@return string
lurek.input.keyboard.getKeyFromScancode = function(scancode) end

--- Returns the human-readable name of a gamepad.
---@param id integer
---@return string
lurek.input.gamepad.getName = function(id) end

--- Returns the current playback frame index (0-based).  Returns 0 when not playing.
---@return number
lurek.input.getPlaybackFrame = function() end

--- Returns the current cursor position as (x, y).
---@return number
---@return number
lurek.input.mouse.getPosition = function() end

--- Returns the position (x, y) of the touch with the given ID.
---@param id integer
---@return number
---@return number
lurek.input.touch.getPosition = function(id) end

--- Returns the pressure (0-1) of the touch with the given ID.
---@param id integer
---@return number
lurek.input.touch.getPressure = function(id) end

--- Returns whether relative mouse mode is active.
---@return boolean
lurek.input.mouse.getRelativeMode = function() end

--- Returns the hardware scancode for the given key name.
---@param key string
---@return string
lurek.input.keyboard.getScancodeFromKey = function(key) end

--- Returns a system cursor object for the named cursor shape.
---@param name string
---@return Cursor
lurek.input.mouse.getSystemCursor = function(name) end

--- Returns the number of currently active touch points.
---@return number
lurek.input.touch.getTouchCount = function() end

--- Returns a table of active touch points with id, x, y, and pressure fields.
---@return table
lurek.input.touch.getTouches = function() end

--- Returns the mouse scroll wheel delta (dx, dy) since last frame.
---@return number
---@return number
lurek.input.mouse.getWheelDelta = function() end

--- Returns the current mouse X position in window coordinates.
---@return number
lurek.input.mouse.getX = function() end

--- Returns the current mouse Y position in window coordinates.
---@return number
lurek.input.mouse.getY = function() end

--- Returns whether key-repeat is currently enabled.
---@return boolean
lurek.input.keyboard.hasKeyRepeat = function() end

--- Returns whether text input mode is currently active.
---@return boolean
lurek.input.keyboard.hasTextInput = function() end

--- Returns true if any key bound to the action is currently held down.
---@param action string
---@return boolean
lurek.input.isActionDown = function(action) end

--- Returns whether the gamepad with the given ID is connected.
---@param id integer
---@return boolean
lurek.input.gamepad.isConnected = function(id) end

--- Returns whether cursor customisation is supported on this platform.
---@return boolean
lurek.input.mouse.isCursorSupported = function() end

--- Returns true if any of the given keys is currently held down.
---@param ... string
---@return boolean
lurek.input.keyboard.isDown = function(...) end

--- Returns whether the given mouse button is currently held down.
---@param button integer
---@return boolean
lurek.input.mouse.isDown = function(button) end

--- Returns whether the given button on the gamepad is currently held.
---@param id integer
---@param button integer
---@return boolean
lurek.input.gamepad.isDown = function(id, button) end

--- Returns whether the joystick at the given slot is a recognized gamepad.
---@param id integer
---@return boolean
lurek.input.gamepad.isGamepad = function(id) end

--- Returns whether the mouse cursor is locked to the window.
---@return boolean
lurek.input.mouse.isGrabbed = function() end

--- Returns whether the named modifier key is currently held.
---@param modifier string
---@return boolean
lurek.input.keyboard.isModifierActive = function(modifier) end

--- Returns true if input playback is currently active.
---@return boolean
lurek.input.isPlayingBack = function() end

--- Returns true if input recording is currently active.
---@return boolean
lurek.input.isRecording = function() end

--- Returns whether the key with the given scancode is held.
---@param scancode string
---@return boolean
lurek.input.keyboard.isScancodeDown = function(scancode) end

--- Returns whether the gamepad supports haptic vibration.
---@param id integer
---@return boolean
lurek.input.gamepad.isVibrationSupported = function(id) end

--- Returns whether the mouse cursor is currently visible.
---@return boolean
lurek.input.mouse.isVisible = function() end

--- Loads SDL2 GameControllerDB-format mappings from a file.
---@param path string
---@return number
lurek.input.gamepad.loadGamepadMappings = function(path) end

--- Loads a JSON-encoded recording string for playback.
---@param json string
---@return nil
lurek.input.loadRecording = function(json) end

--- Creates a new combo detector from an ordered list of steps.
---@param steps table
---@param opts? table
---@return Combo
lurek.input.newCombo = function(steps, opts) end

--- Creates a custom mouse cursor from RGBA pixel data.
---@param pixels table
---@param width integer
---@param height integer
---@param hotx? integer
---@param hoty? integer
---@return Cursor
lurek.input.mouse.newCursor = function(pixels, width, height, hotx, hoty) end

--- Saves all stored gamepad mappings to a plain-text file.
---@param path string
---@return nil
lurek.input.gamepad.saveGamepadMappings = function(path) end

--- Enable or disable receiving gamepad events when the window is not focused.
---@param enable boolean
---@return nil
lurek.input.gamepad.setBackgroundEvents = function(enable) end

--- Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
---@param cursor Cursor|string|nil
---@return nil
lurek.input.mouse.setCursor = function(cursor) end

--- Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
---@param guid string
---@param mapping string
---@return nil
lurek.input.gamepad.setGamepadMapping = function(guid, mapping) end

--- Locks or unlocks the mouse cursor to the window.
---@param grabbed boolean
---@return nil
lurek.input.mouse.setGrabbed = function(grabbed) end

--- Enables or disables key-repeat events.
---@param enabled boolean
---@return nil
lurek.input.keyboard.setKeyRepeat = function(enabled) end

--- Moves the mouse cursor to the given window-space position.
---@param x number
---@param y number
---@return nil
lurek.input.mouse.setPosition = function(x, y) end

--- Enables or disables raw relative mouse motion mode.
---@param relative boolean
---@return nil
lurek.input.mouse.setRelativeMode = function(relative) end

--- Enables or disables Unicode text input mode.
---@param enabled boolean
---@return nil
lurek.input.keyboard.setTextInput = function(enabled) end

--- Triggers haptic rumble (currently a no-op stub).
---@param ... any
---@return boolean
lurek.input.gamepad.setVibration = function(...) end

--- Shows or hides the operating-system mouse cursor.
---@param visible boolean
---@return nil
lurek.input.mouse.setVisible = function(visible) end

--- Starts playback from the beginning of the loaded recording.
---@return nil
lurek.input.startPlayback = function() end

--- Starts capturing input events frame-by-frame.  Clears any previous recording.
---@return nil
lurek.input.startRecording = function() end

--- Stops playback immediately.
---@return nil
lurek.input.stopPlayback = function() end

--- Stops recording and returns an `InputRecording` userdata, or nil if not recording.
---@return table
lurek.input.stopRecording = function() end

--- Removes all key bindings for the given action name.
---@param action string
---@return boolean
lurek.input.unbind = function(action) end

--- Requests haptic vibration on a gamepad.
---@param id integer
---@param low_freq number
---@param high_freq number
---@param duration_ms number
---@return boolean
lurek.input.gamepad.vibrate = function(id, low_freq, high_freq, duration_ms) end

--- Returns true if any key bound to the action was pressed this frame.
---@param action string
---@return boolean
lurek.input.wasActionPressed = function(action) end

--- Was action pressed within.
---@param action string
---@param frames integer
---@return boolean
lurek.input.wasActionPressedWithin = function(action, frames) end

--- Returns true if any key bound to the action was released this frame.
---@param action string
---@return boolean
lurek.input.wasActionReleased = function(action) end

---@class lurek.light
lurek.light = {}

--- Lua-side handle to a light resource stored in [`LightWorld`].
---@class LLight
LLight = {}

--- Convenience method to set a flicker effect using amplitude range and
---@param min number
---@param max number
---@param hz number
---@return nil
function LLight:addFlicker(min, max, hz) end

--- Removes the cookie texture assignment.
---@return nil
function LLight:clearCookie() end

--- Returns the custom attenuation coefficients as (constant, linear, quadratic).
---@return number
---@return number
---@return number
function LLight:getAttenuation() end

--- Returns the blend mode as a string.
---@return string
function LLight:getBlendMode() end

--- Returns the light's tint color as (r, g, b, a).
---@return number
---@return number
---@return number
---@return number
function LLight:getColor() end

--- Returns the current cookie texture path, or `nil` if unset.
---@return string
function LLight:getCookie() end

--- Returns the direction angle in radians.
---@return number
function LLight:getDirection() end

--- Returns the energy scaling factor.
---@return number
function LLight:getEnergy() end

--- Returns the falloff mode as a string.
---@return string
function LLight:getFalloff() end

--- Returns the flicker effect speed and strength.
---@return number
---@return number
function LLight:getFlicker() end

--- Returns the group identifier.
---@return number
function LLight:getGroupId() end

--- Returns the inner cone angle in radians.
---@return number
function LLight:getInnerAngle() end

--- Returns the brightness multiplier.
---@return number
function LLight:getIntensity() end

--- Returns the light interaction bitmask.
---@return number
function LLight:getLightMask() end

--- Returns the geometric light type as a string.
---@return string
function LLight:getLightType() end

--- Returns the outer cone angle in radians.
---@return number
function LLight:getOuterAngle() end

--- Returns the light's world-space position.
---@return number
---@return number
function LLight:getPosition() end

--- Returns the light's influence radius.
---@return number
function LLight:getRadius() end

--- Returns the shadow region color as (r, g, b, a).
---@return number
---@return number
---@return number
---@return number
function LLight:getShadowColor() end

--- Returns the shadow edge filter as a string.
---@return string
function LLight:getShadowFilter() end

--- Returns the shadow casting bitmask.
---@return number
function LLight:getShadowMask() end

--- Returns the shadow edge smoothing factor.
---@return number
function LLight:getShadowSmooth() end

--- Returns whether this light is active.
---@return boolean
function LLight:isEnabled() end

--- Returns whether the flicker effect is active.
---@return boolean
function LLight:isFlickerEnabled() end

--- Returns whether this light casts shadows.
---@return boolean
function LLight:isShadowEnabled() end

--- Returns whether this light handle is still valid.
---@return boolean
function LLight:isValid() end

--- Returns whether this light hints at volumetric scattering.
---@return boolean
function LLight:isVolumetric() end

--- Removes this light from the world.
---@return nil
function LLight:remove() end

--- Sets the custom attenuation coefficients (constant, linear, quadratic).
---@param c number
---@param l number
---@param q number
---@return nil
function LLight:setAttenuation(c, l, q) end

--- Sets the blend mode ('add', 'sub', or 'mix').
---@param mode string
---@return nil
function LLight:setBlendMode(mode) end

--- Sets the light's tint color.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LLight:setColor(r, g, b, a) end

--- Sets the texture path used as a light cookie (mask) for projection.
---@param path string
---@return nil
function LLight:setCookie(path) end

--- Sets the direction angle in radians.
---@param dir number
---@return nil
function LLight:setDirection(dir) end

--- Sets whether this light is active.
---@param enabled boolean
---@return nil
function LLight:setEnabled(enabled) end

--- Sets the energy scaling factor.
---@param e number
---@return nil
function LLight:setEnergy(e) end

--- Sets the falloff mode ('linear', 'smooth', or 'constant').
---@param mode string
---@return nil
function LLight:setFalloff(mode) end

--- Sets the flicker effect speed and strength (enables flicker).
---@param speed number
---@param strength number
---@return nil
function LLight:setFlicker(speed, strength) end

--- Sets whether the flicker effect is active.
---@param enabled boolean
---@return nil
function LLight:setFlickerEnabled(enabled) end

--- Sets the group identifier for batch operations.
---@param id integer
---@return nil
function LLight:setGroupId(id) end

--- Sets the inner cone angle in radians for spot lights.
---@param angle number
---@return nil
function LLight:setInnerAngle(angle) end

--- Sets the brightness multiplier.
---@param i number
---@return nil
function LLight:setIntensity(i) end

--- Sets the light interaction bitmask.
---@param mask integer
---@return nil
function LLight:setLightMask(mask) end

--- Sets the geometric light type ('point', 'directional', or 'spot').
---@param t string
---@return nil
function LLight:setLightType(t) end

--- Sets the outer cone angle in radians for spot lights.
---@param angle number
---@return nil
function LLight:setOuterAngle(angle) end

--- Sets the light's world-space position.
---@param x number
---@param y number
---@return nil
function LLight:setPosition(x, y) end

--- Sets the light's influence radius.
---@param r number
---@return nil
function LLight:setRadius(r) end

--- Sets the shadow region color.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LLight:setShadowColor(r, g, b, a) end

--- Sets whether this light casts shadows.
---@param enabled boolean
---@return nil
function LLight:setShadowEnabled(enabled) end

--- Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
---@param filter string
---@return nil
function LLight:setShadowFilter(filter) end

--- Sets the shadow casting bitmask.
---@param mask integer
---@return nil
function LLight:setShadowMask(mask) end

--- Sets the shadow edge smoothing factor.
---@param smooth number
---@return nil
function LLight:setShadowSmooth(smooth) end

--- Sets whether this light hints at volumetric scattering.
---@param enabled boolean
---@return nil
function LLight:setVolumetric(enabled) end

--- Cancels the active light transition.
---@return nil
function LLight:stopTransition() end

--- Returns the fractional progress `[0, 1]` of the active transition,
---@return number
function LLight:transitionProgress() end

--- Begins a smooth linear transition of the light's color, intensity,
---@param target table
---@param duration number
---@return nil
function LLight:transitionTo(target, duration) end

--- Returns the type name of this object.
---@return string
function LLight:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LLight:typeOf(name) end

--- Advances the active transition by `dt` seconds and applies the
---@param dt number
---@return boolean
function LLight:updateTransition(dt) end

--- Lua-side handle to an occluder resource stored in [`LightWorld`].
---@class LOccluder
LOccluder = {}

--- Returns the light interaction bitmask.
---@return number
function LOccluder:getLightMask() end

--- Returns the shadow opacity.
---@return number
function LOccluder:getOpacity() end

--- Returns the translation offset as (x, y).
---@return number
---@return number
function LOccluder:getPosition() end

--- Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
---@return table
function LOccluder:getVertices() end

--- Returns whether this occluder is active.
---@return boolean
function LOccluder:isEnabled() end

--- Returns whether this occluder handle is still valid.
---@return boolean
function LOccluder:isValid() end

--- Removes this occluder from the world.
---@return nil
function LOccluder:remove() end

--- Sets whether this occluder is active.
---@param enabled boolean
---@return nil
function LOccluder:setEnabled(enabled) end

--- Sets the light interaction bitmask.
---@param mask integer
---@return nil
function LOccluder:setLightMask(mask) end

--- Sets the shadow opacity (0.0â€“1.0).
---@param opacity number
---@return nil
function LOccluder:setOpacity(opacity) end

--- Sets the translation offset applied to all vertices.
---@param x number
---@param y number
---@return nil
function LOccluder:setPosition(x, y) end

--- Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
---@param vertices table
---@return nil
function LOccluder:setVertices(vertices) end

--- Returns the type name of this object.
---@return string
function LOccluder:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LOccluder:typeOf(name) end

--- Advances flicker phase for all lights with flicker enabled.
---@param dt number
---@return nil
lurek.light.advanceFlickers = function(dt) end

--- Removes all lights and occluders, resets ambient to default.
---@return nil
lurek.light.clear = function() end

--- Returns the global ambient light color as (r, g, b, a).
---@return number
---@return number
---@return number
---@return number
lurek.light.getAmbient = function() end

--- Returns a list of directional light hints for god-ray rendering.
---@return table
lurek.light.getGodRayHints = function() end

--- Returns the number of lights in the given group.
---@param groupId integer
---@return number
lurek.light.getGroupCount = function(groupId) end

--- Returns the number of lights in the world.
---@return number
lurek.light.getLightCount = function() end

--- Returns the maximum number of lights processed per frame.
---@return number
lurek.light.getMaxLights = function() end

--- Returns the number of occluders in the world.
---@return number
lurek.light.getOccluderCount = function() end

--- Returns whether the lighting system is active.
---@return boolean
lurek.light.isEnabled = function() end

--- Creates a new light at (x, y) with the given radius and optional settings.
---@param x number
---@param y number
---@param radius number
---@param opts? table
---@return Light
lurek.light.newLight = function(x, y, radius, opts) end

--- Creates a new shadow occluder from a vertex table and optional settings.
---@param vertices table
---@param opts? table
---@return Occluder
lurek.light.newOccluder = function(vertices, opts) end

--- Sets the global ambient light color.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
lurek.light.setAmbient = function(r, g, b, a) end

--- Sets whether the lighting system is active.
---@param enabled boolean
---@return nil
lurek.light.setEnabled = function(enabled) end

--- Sets the color for all lights in the given group.
---@param groupId integer
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
lurek.light.setGroupColor = function(groupId, r, g, b, a) end

--- Sets the enabled state for all lights in the given group.
---@param groupId integer
---@param enabled boolean
---@return nil
lurek.light.setGroupEnabled = function(groupId, enabled) end

--- Sets the intensity for all lights in the given group.
---@param groupId integer
---@param intensity number
---@return nil
lurek.light.setGroupIntensity = function(groupId, intensity) end

--- Sets the maximum number of lights processed per frame (clamped 1â€“256).
---@param n integer
---@return nil
lurek.light.setMaxLights = function(n) end

--- Returns the current ambient light colour as (r, g, b, a).
---@return number
---@return number
---@return number
---@return number
lurek.light.syncAmbient = function() end

---@class lurek.log
lurek.log = {}

--- Registers a new output sink. Returns its numeric id.
---@param config table
---@return number
lurek.log.addSink = function(config) end

--- Removes all registered sinks (the default stderr channel is unaffected).
---@return nil
lurek.log.clearSinks = function() end

--- Emits a debug-severity log message. Also dispatches to configured sinks.
---@param message string
---@param tag? string
---@return nil
lurek.log.debug = function(message, tag) end

--- Emits a debug structured log message. Shorthand for `struct("debug", ...)`.
---@param message string
---@param fields_table table
---@return nil
lurek.log.debug_fields = function(message, fields_table) end

--- Emits an error-severity log message. Also dispatches to configured sinks.
---@param message string
---@param tag? string
---@return nil
lurek.log.error = function(message, tag) end

--- Emits an error structured log message. Shorthand for `struct("error", ...)`.
---@param message string
---@param fields_table table
---@return nil
lurek.log.error_fields = function(message, fields_table) end

--- Flushes the OS write buffer for a file sink.
---@param id integer
---@return nil
lurek.log.flushFile = function(id) end

--- Returns the name of the currently active minimum log level.
---@return string
lurek.log.getLevel = function() end

--- Emits an info-severity log message. Also dispatches to configured sinks.
---@param message string
---@param tag? string
---@return nil
lurek.log.info = function(message, tag) end

--- Emits an info structured log message. Shorthand for `struct("info", ...)`.
---@param message string
---@param fields_table table
---@return nil
lurek.log.info_fields = function(message, fields_table) end

--- Returns a table describing all registered sinks.
---@return table
lurek.log.listSinks = function() end

--- Emits a log message at the specified level. Also dispatches to sinks.
---@param level string
---@param message string
---@param tag? string
---@return nil
lurek.log.print = function(level, message, tag) end

--- Reads entries from a memory sink. If drain=true the buffer is cleared.
---@param id integer
---@param drain? boolean
---@return table
lurek.log.readMemory = function(id, drain) end

--- Removes a sink by id. Returns true if one was removed.
---@param id integer
---@return boolean
lurek.log.removeSink = function(id) end

--- Sets the minimum severity level for the default log channel.
---@param level string
---@return nil
lurek.log.setLevel = function(level) end

--- Emits a structured log message with key-value fields.
---@param level string
---@param message string
---@param fields_table table
---@return nil
lurek.log.struct = function(level, message, fields_table) end

--- Emits a warn-severity log message. Also dispatches to configured sinks.
---@param message string
---@param tag? string
---@return nil
lurek.log.warn = function(message, tag) end

--- Emits a warn structured log message. Shorthand for `struct("warn", ...)`.
---@param message string
---@param fields_table table
---@return nil
lurek.log.warn_fields = function(message, fields_table) end

---@class lurek.math
---@field pi number  π ≈ 3.14159265358979
---@field tau number  τ = 2π ≈ 6.28318530717959
lurek.math = {}

--- Lua-side wrapper around an [`AabbTree`].
---@class LAabbTree
LAabbTree = {}

--- Removes all entries from the tree.
---@return nil
function LAabbTree:clear() end

--- Returns true if an entry with the given id exists in the tree.
---@param id integer
---@return boolean
function LAabbTree:contains(id) end

--- Inserts an entry with the given AABB into the tree.
---@param id integer
---@param min_x number
---@param min_y number
---@param max_x number
---@param max_y number
---@return nil
function LAabbTree:insert(id, min_x, min_y, max_x, max_y) end

--- Returns true if the tree contains no entries.
---@return boolean
function LAabbTree:isEmpty() end

--- Returns the number of entries in the tree.
---@return number
function LAabbTree:len() end

--- Returns the ids of all entries whose AABBs overlap the query rectangle.
---@param min_x number
---@param min_y number
---@param max_x number
---@param max_y number
---@return table
function LAabbTree:query(min_x, min_y, max_x, max_y) end

--- Returns the ids of all entries whose AABBs contain the given point.
---@param x number
---@param y number
---@return table
function LAabbTree:queryPoint(x, y) end

--- Removes the entry with the given id.
---@param id integer
---@return boolean
function LAabbTree:remove(id) end

--- Returns the type name of this object.
---@return string
function LAabbTree:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAabbTree:typeOf(name) end

--- Updates the AABB for an existing entry.
---@param id integer
---@param min_x number
---@param min_y number
---@param max_x number
---@param max_y number
---@return boolean
function LAabbTree:update(id, min_x, min_y, max_x, max_y) end

--- Lua-side wrapper around a [`BezierCurve`].
---@class LBezierCurve
LBezierCurve = {}

--- Evaluates the curve at parameter t, returning (x, y).
---@param t number
---@return number
---@return number
function LBezierCurve:evaluate(t) end

--- Returns the control point at 1-based index as (x, y), or nil.
---@param index integer
---@return nil
function LBezierCurve:getControlPoint(index) end

--- Returns the number of control points.
---@return number
function LBezierCurve:getControlPointCount() end

--- Returns a new BezierCurve representing the first derivative.
---@return BezierCurve
function LBezierCurve:getDerivative() end

--- Inserts a control point. If index is given (1-based), inserts at that position.
---@param x number
---@param y number
---@param index? integer
---@return nil
function LBezierCurve:insertControlPoint(x, y, index) end

--- Returns the approximate arc length of the curve.
---@return number
function LBezierCurve:length() end

--- Removes a control point at 1-based index.
---@param index integer
---@return boolean
function LBezierCurve:removeControlPoint(index) end

--- Renders the curve as a polyline with the given number of segments.
---@param segments integer
---@return table
function LBezierCurve:render(segments) end

--- Rotates all control points around a pivot by angle radians.
---@param angle number
---@param ox number
---@param oy number
---@return nil
function LBezierCurve:rotate(angle, ox, oy) end

--- Scales all control points around a pivot by factor s.
---@param s number
---@param ox number
---@param oy number
---@return nil
function LBezierCurve:scale(s, ox, oy) end

--- Sets the control point at 1-based index.
---@param index integer
---@param x number
---@param y number
---@return boolean
function LBezierCurve:setControlPoint(index, x, y) end

--- Translates all control points by (dx, dy).
---@param dx number
---@param dy number
---@return nil
function LBezierCurve:translate(dx, dy) end

--- Returns the type name of this object.
---@return string
function LBezierCurve:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LBezierCurve:typeOf(name) end

--- Lua-side wrapper around a [`CatmullRomSpline`].
---@class LCatmullRom
LCatmullRom = {}

--- Appends a control point to the spline.
---@param x number
---@param y number
function LCatmullRom:addPoint(x, y) end

--- Number of control points.
---@return number
function LCatmullRom:len() end

--- Removes the control point at `index` (0-based) and returns it.
---@param index integer
---@return number
---@return number
function LCatmullRom:removePoint(index) end

--- Sample the spline at global t in [0, 1].
---@param t number
---@return number
---@return number
function LCatmullRom:sample(t) end

--- Sample a specific segment at local t in [0, 1].
---@param seg integer
---@param t number
---@return number
---@return number
function LCatmullRom:sampleSegment(seg, t) end

--- Returns the type name of this object.
---@return string
function LCatmullRom:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LCatmullRom:typeOf(name) end

--- Lua-side wrapper around a [`Circle`].
---@class LCircle
LCircle = {}

--- Returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y).
---@return number
---@return number
---@return number
---@return number
function LCircle:aabb() end

--- Returns the area of the circle (π r²).
---@return number
function LCircle:area() end

--- Returns true if the point (px, py) lies inside or on the boundary.
---@param px number
---@param py number
---@return boolean
function LCircle:contains(px, py) end

--- Returns true if this circle overlaps another circle.
---@param other Circle
---@return boolean
function LCircle:intersects(other) end

--- Returns the circumference of the circle (2 π r).
---@return number
function LCircle:perimeter() end

--- Returns the circle radius.
---@return number
function LCircle:radius() end

--- Returns the type name of this object.
---@return string
function LCircle:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LCircle:typeOf(name) end

--- Returns the circle centre X.
---@return number
function LCircle:x() end

--- Returns the circle centre Y.
---@return number
function LCircle:y() end

--- Lua-side wrapper around a [`HermiteSpline`].
---@class LHermite
LHermite = {}

--- Evaluate the spline at parameter t in [0, 1].
---@param t number
---@return number
---@return number
function LHermite:sample(t) end

--- Returns the type name of this object.
---@return string
function LHermite:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LHermite:typeOf(name) end

--- Lua-side wrapper around a [`NoiseGenerator`].
---@class LNoiseGenerator
LNoiseGenerator = {}

--- Returns fractal Brownian motion noise at (x, y).
---@param x number
---@param y number
---@param octaves? integer
---@param lacunarity? number
---@param persistence? number
---@param kind? string
---@return number
function LNoiseGenerator:fbm(x, y, octaves, lacunarity, persistence, kind) end

--- Generates a 2D noise map as a flat table (row-major).
---@param width integer
---@param height integer
---@param opts? table
---@return table
function LNoiseGenerator:generateMap(width, height, opts) end

--- Returns the current seed.
---@return number
function LNoiseGenerator:getSeed() end

--- Returns 1D Perlin noise at x.
---@param x number
---@return number
function LNoiseGenerator:perlin1d(x) end

--- Returns 2D Perlin noise at (x, y).
---@param x number
---@param y number
---@return number
function LNoiseGenerator:perlin2d(x, y) end

--- Returns 3D Perlin noise at (x, y, z).
---@param x number
---@param y number
---@param z number
---@return number
function LNoiseGenerator:perlin3d(x, y, z) end

--- Returns 4D Perlin noise at (x, y, z, w).
---@param x number
---@param y number
---@param z number
---@param w number
---@return number
function LNoiseGenerator:perlin4d(x, y, z, w) end

--- Returns ridged multi-fractal noise at (x, y).
---@param x number
---@param y number
---@param octaves? integer
---@param lacunarity? number
---@param persistence? number
---@param kind? string
---@return number
function LNoiseGenerator:ridged(x, y, octaves, lacunarity, persistence, kind) end

--- Sets the seed and rebuilds the permutation table.
---@param seed integer
---@return nil
function LNoiseGenerator:setSeed(seed) end

--- Returns 1D Simplex noise at x.
---@param x number
---@return number
function LNoiseGenerator:simplex1d(x) end

--- Returns 2D Simplex noise at (x, y).
---@param x number
---@param y number
---@return number
function LNoiseGenerator:simplex2d(x, y) end

--- Returns 3D Simplex noise at (x, y, z).
---@param x number
---@param y number
---@param z number
---@return number
function LNoiseGenerator:simplex3d(x, y, z) end

--- Returns turbulence noise at (x, y).
---@param x number
---@param y number
---@param octaves? integer
---@param lacunarity? number
---@param persistence? number
---@param kind? string
---@return number
function LNoiseGenerator:turbulence(x, y, octaves, lacunarity, persistence, kind) end

--- Returns the type name of this object.
---@return string
function LNoiseGenerator:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LNoiseGenerator:typeOf(name) end

--- Applies domain warping, returning offset (x, y).
---@param x number
---@param y number
---@param strength number
---@return number
---@return number
function LNoiseGenerator:warpDomain(x, y, strength) end

--- Returns 2D Worley (cellular) noise at (x, y).
---@param x number
---@param y number
---@param distType? string
---@param f2? boolean
---@return number
function LNoiseGenerator:worley2d(x, y, distType, f2) end

--- Returns 3D Worley (cellular) noise at (x, y, z).
---@param x number
---@param y number
---@param z number
---@param distType? string
---@param f2? boolean
---@return number
function LNoiseGenerator:worley3d(x, y, z, distType, f2) end

--- Lua-side wrapper around a [`RandomGenerator`].
---@class LRandomGenerator
LRandomGenerator = {}

--- Returns the seed used to initialise this generator.
---@return number
function LRandomGenerator:getSeed() end

--- Serialises the generator state as a string for later restoration.
---@return string
function LRandomGenerator:getState() end

--- Returns a uniform random number in [0, 1).
---@return number
function LRandomGenerator:random() end

--- Returns a uniform random float in [min, max).
---@param min number
---@param max number
---@return number
function LRandomGenerator:randomFloat(min, max) end

--- Returns a uniform random integer in [min, max].
---@param min integer
---@param max integer
---@return number
function LRandomGenerator:randomInt(min, max) end

--- Returns a random number from a normal (Gaussian) distribution.
---@param stddev? number
---@param mean? number
---@return number
function LRandomGenerator:randomNormal(stddev, mean) end

--- Sets the seed, fully resetting the generator state.
---@param seed integer
---@return nil
function LRandomGenerator:setSeed(seed) end

--- Restores the generator state from a previously serialised string.
---@param state string
---@return nil
function LRandomGenerator:setState(state) end

--- Returns the type name of this object.
---@return string
function LRandomGenerator:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LRandomGenerator:typeOf(name) end

--- Lua-side wrapper around a [`SpatialHash`].
---@class LSpatialHash
LSpatialHash = {}

--- Removes all registered items from this spatial hash, leaving it empty.
---@return nil
function LSpatialHash:clear() end

--- Returns the cell size used to partition the spatial hash grid.
---@return number
function LSpatialHash:getCellSize() end

--- Returns the number of items in the hash.
---@return number
function LSpatialHash:getItemCount() end

--- Inserts an item with the given AABB.
---@param id string
---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function LSpatialHash:insert(id, x, y, w, h) end

--- Returns IDs of items overlapping the query circle.
---@param cx number
---@param cy number
---@param radius number
---@return table
function LSpatialHash:queryCircle(cx, cy, radius) end

--- Returns IDs of items overlapping the query rectangle.
---@param x number
---@param y number
---@param w number
---@param h number
---@return table
function LSpatialHash:queryRect(x, y, w, h) end

--- Returns IDs of items whose AABBs are intersected by the line segment.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return table
function LSpatialHash:querySegment(x1, y1, x2, y2) end

--- Removes an item by its ID.
---@param id string
---@return nil
function LSpatialHash:remove(id) end

--- Returns the type name of this object.
---@return string
function LSpatialHash:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSpatialHash:typeOf(name) end

--- Updates an existing item's AABB.
---@param id string
---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function LSpatialHash:update(id, x, y, w, h) end

--- Lua-side wrapper around a [`Transform`].
---@class LTransform
LTransform = {}

--- Returns a copy of this transform.
---@return Transform
function LTransform:clone() end

--- Decomposes this transform into translation, rotation, and scale.
---@return number
---@return number
function LTransform:decompose() end

--- Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
---@return table
function LTransform:getMatrix() end

--- Returns a new Transform that undoes this transform.
---@return Transform
function LTransform:inverse() end

--- Transforms a point from world space back to local space.
---@param x number
---@param y number
---@return number
---@return number
function LTransform:inverseTransformPoint(x, y) end

--- Resets the transform to identity.
---@return nil
function LTransform:reset() end

--- Applies a rotation in radians.
---@param angle number
---@return nil
function LTransform:rotate(angle) end

--- Applies non-uniform scaling.
---@param sx number
---@param sy? number
---@return nil
function LTransform:scale(sx, sy) end

--- Replaces the transform with full transformation parameters.
---@param x number
---@param y number
---@param angle? number
---@param sx? number
---@param sy? number
---@param ox? number
---@param oy? number
---@param kx? number
---@param ky? number
function LTransform:setTransformation(x, y, angle, sx, sy, ox, oy, kx, ky) end

--- Applies horizontal and vertical shear factors to this transform matrix.
---@param kx number
---@param ky number
---@return nil
function LTransform:shear(kx, ky) end

--- Transforms a point from local space to world space.
---@param x number
---@param y number
---@return number
---@return number
function LTransform:transformPoint(x, y) end

--- Applies translation to the transform.
---@param dx number
---@param dy number
---@return nil
function LTransform:translate(dx, dy) end

--- Returns the type name of this object.
---@return string
function LTransform:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTransform:typeOf(name) end

--- Lua-side wrapper around a [`Tween`].
---@class LTween
LTween = {}

--- Adds a start/target value pair. Returns the 1-based index.
---@param start number
---@param target number
---@return number
function LTween:addValue(start, target) end

--- Returns all interpolated values as a table.
---@return table
function LTween:getAllValues() end

--- Alias for getTime(). Returns the current clock time.
---@return number
function LTween:getClock() end

--- Returns the tween duration in seconds.
---@return number
function LTween:getDuration() end

--- Returns the easing function name.
---@return string
function LTween:getEasingName() end

--- Returns the current clock time.
---@return number
function LTween:getTime() end

--- Returns the interpolated value at 1-based index, or all values as a
---@param index? integer
---@return nil
function LTween:getValue(index) end

--- Returns the number of values in this tween.
---@return number
function LTween:getValueCount() end

--- Returns true if the tween has finished.
---@return boolean
function LTween:isComplete() end

--- Resets the tween elapsed time to zero, restarting the animation.
---@return nil
function LTween:reset() end

--- Alias for setTime(). Sets the clock to t, clamped to [0, duration].
---@param t number
---@return nil
function LTween:set(t) end

--- Sets the clock to a specific time, clamped to [0, duration].
---@param t number
---@return nil
function LTween:setTime(t) end

--- Returns the type name of this object.
---@return string
function LTween:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTween:typeOf(name) end

--- Advances the clock by dt seconds. Returns true when complete.
---@param dt number
---@return boolean
function LTween:update(dt) end

--- Lua-side wrapper around a [`Vec2`] value type.
---@class LVec2
---@field x number  x component
---@field y number  y component
LVec2 = {}

--- Returns the angle of this vector in radians (atan2(y, x)).
---@return number
function LVec2:angle() end

--- Returns the 2D cross product (scalar) with another vector.
---@param other Vec2
---@return number
function LVec2:cross(other) end

--- Returns the Euclidean distance from this vector to another.
---@param other Vec2
---@return number
function LVec2:distance(other) end

--- Returns the dot product with another vector.
---@param other Vec2
---@return number
function LVec2:dot(other) end

--- Creates a unit vector from an angle in radians.
---@param radians number
---@return Vec2
LVec2.fromAngle = function(radians) end

--- Returns the Euclidean length of the vector.
---@return number
function LVec2:length() end

--- Returns the squared length of the vector (faster than length).
---@return number
function LVec2:lengthSquared() end

--- Returns a linearly interpolated vector between this and other at parameter t.
---@param other Vec2
---@param t number
---@return Vec2
function LVec2:lerp(other, t) end

--- Returns a unit-length copy of this vector. Returns zero if length is zero.
---@return Vec2
function LVec2:normalize() end

--- Compatibility alias for `normalize`.
---@return Vec2
function LVec2:normalized() end

--- Returns the perpendicular vector (-y, x).
---@return Vec2
function LVec2:perpendicular() end

--- Reflects this vector off a surface with the given normal.
---@param normal Vec2
---@return Vec2
function LVec2:reflect(normal) end

--- Returns a new vector rotated by the given angle in radians.
---@param angle number
---@return Vec2
function LVec2:rotate(angle) end

--- Returns the type name of this object.
---@return string
function LVec2:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LVec2:typeOf(name) end

--- Returns the horizontal component of the vector.
---@return number
function LVec2:x() end

--- Returns the vertical component of the vector.
---@return number
function LVec2:y() end

--- Lua-side wrapper around a [`Vec3`] value type.
---@class LVec3
---@field x number  x component
---@field y number  y component
---@field z number  z component
LVec3 = {}

--- Add another Vec3 and return the result.
---@param other Vec3
---@return Vec3
function LVec3:add(other) end

--- Cross product with another Vec3.
---@param other Vec3
---@return Vec3
function LVec3:cross(other) end

--- Euclidean distance to another Vec3.
---@param other Vec3
---@return number
function LVec3:distance(other) end

--- Dot product with another Vec3.
---@param other Vec3
---@return number
function LVec3:dot(other) end

--- Returns the Euclidean length of the vector.
---@return number
function LVec3:length() end

--- Returns the squared Euclidean length (avoids sqrt).
---@return number
function LVec3:lengthSquared() end

--- Linear interpolation towards another Vec3.
---@param other Vec3
---@param t number
---@return Vec3
function LVec3:lerp(other, t) end

--- Returns a unit-length version of this vector.
---@return Vec3
function LVec3:normalize() end

--- Scale this vector by a scalar and return the result.
---@param s number
---@return Vec3
function LVec3:scale(s) end

--- Creates a Vec3 with all components set to `v`.
---@param v number
---@return Vec3
LVec3.splat = function(v) end

--- Subtract another Vec3 and return the result.
---@param other Vec3
---@return Vec3
function LVec3:sub(other) end

--- Returns the type name of this object.
---@return string
function LVec3:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LVec3:typeOf(name) end

--- Compatibility alias for `vec2`.
---@param x number
---@param y number
---@return Vec2
lurek.math.Vec2 = function(x, y) end

--- Compatibility alias for `vec3`.
---@param x number
---@param y number
---@param z number
---@return Vec3
lurek.math.Vec3 = function(x, y, z) end

--- Creates a new empty AABB tree for efficient broad-phase overlap queries.
---@return AabbTree
lurek.math.aabbTree = function() end

--- Returns the absolute value of x.
---@param x number
---@return number
lurek.math.abs = function(x) end

--- Returns the arccosine of x, in radians.
---@param x number
---@return number
lurek.math.acos = function(x) end

--- Returns the angle in radians from (x1, y1) to (x2, y2).
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
lurek.math.angleBetween = function(x1, y1, x2, y2) end

--- Applies a named easing function to progress value t.
---@param name string
---@param t number
---@return number
lurek.math.applyEasing = function(name, t) end

--- Returns the arcsine of x, in radians.
---@param x number
---@return number
lurek.math.asin = function(x) end

--- Returns the arctangent of x (or atan2(y, x) when two args given).
---@param y number
---@param x? number
---@return number
lurek.math.atan = function(y, x) end

--- Returns atan(y/x) using the signs of both args to determine the quadrant.
---@param y number
---@param x number
---@return number
lurek.math.atan2 = function(y, x) end

--- Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm. Returns a table of {x,y} tables.
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@return table
lurek.math.bresenham = function(x1, y1, x2, y2) end

--- Creates a Catmull-Rom spline through the given control points.
---@param points table
---@return CatmullRom
lurek.math.catmullRom = function(points) end

--- Returns the smallest integer ≥ x.
---@param x number
---@return number
lurek.math.ceil = function(x) end

--- Returns true if the point (px, py) lies inside the circle.
---@param cx number
---@param cy number
---@param r number
---@param px number
---@param py number
---@return boolean
lurek.math.circleContainsPoint = function(cx, cy, r, px, py) end

--- Returns true if two circles overlap.
---@param x1 number
---@param y1 number
---@param r1 number
---@param x2 number
---@param y2 number
---@param r2 number
---@return boolean
lurek.math.circleIntersectsCircle = function(x1, y1, r1, x2, y2, r2) end

--- Tests an infinite line against a circle. Returns hit, then two optional hit-point pairs.
---@param cx number
---@param cy number
---@param r number
---@param lx1 number
---@param ly1 number
---@param lx2 number
---@param ly2 number
---@return table
lurek.math.circleIntersectsLine = function(cx, cy, r, lx1, ly1, lx2, ly2) end

--- Tests a line segment against a circle. Returns hit, then two optional hit-point pairs.
---@param cx number
---@param cy number
---@param r number
---@param sx1 number
---@param sy1 number
---@param sx2 number
---@param sy2 number
---@return table
lurek.math.circleIntersectsSegment = function(cx, cy, r, sx1, sy1, sx2, sy2) end

--- Clamps `v` between `min` and `max`.
---@param v number
---@param min number
---@param max number
---@return number
lurek.math.clamp = function(v, min, max) end

--- Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
---@param px number
---@param py number
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
---@return number
lurek.math.closestPointOnSegment = function(px, py, x1, y1, x2, y2) end

--- Computes the convex hull of a flat {x1,y1,...} point list. Returns a flat table.
---@param points table
---@return table
lurek.math.convexHull = function(points) end

--- Returns the cosine of x (radians).
---@param x number
---@return number
lurek.math.cos = function(x) end

--- Converts radians to degrees.
---@param rad number
---@return number
lurek.math.deg = function(rad) end

--- Delaunay triangulation of a flat {x1,y1,...} point list. Returns a table of flat 6-number triangle tables.
---@param points table
---@return table
lurek.math.delaunayTriangulate = function(points) end

--- Returns the Euclidean distance between (x1,y1) and (x2,y2).
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
lurek.math.distance = function(x1, y1, x2, y2) end

--- Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
lurek.math.distanceSq = function(x1, y1, x2, y2) end

--- Returns e raised to the power x.
---@param x number
---@return number
lurek.math.exp = function(x) end

--- Returns fractal Brownian motion noise at (x, y).
---@param x number
---@param y number
---@param seed? integer
---@param octaves? integer
---@param lacunarity? number
---@param gain? number
---@return number
lurek.math.fbm = function(x, y, seed, octaves, lacunarity, gain) end

--- Returns the largest integer ≤ x.
---@param x number
---@return number
lurek.math.floor = function(x) end

--- Returns the remainder of x / y (fmod).
---@param x number
---@param y number
---@return number
lurek.math.fmod = function(x, y) end

--- Parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats.
---@param hex string
---@return number
---@return number
---@return number
---@return number
lurek.math.fromHex = function(hex) end

--- Converts a gamma-encoded sRGB value to linear space.
---@param c number
---@return number
lurek.math.gammaToLinear = function(c) end

--- Creates a Hermite spline defined by two endpoints and tangents.
---@param p0x number
---@param p0y number
---@param p1x number
---@param p1y number
---@param m0x number
---@param m0y number
---@param m1x number
---@param m1y number
---@return Hermite
lurek.math.hermite = function(p0x, p0y, p1x, p1y, m0x, m0y, m1x, m1y) end

--- Converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats.
---@param h number
---@param s number
---@param l number
---@return number
---@return number
---@return number
---@return number
lurek.math.hslToRgb = function(h, s, l) end

--- Back ease-in — overshoots slightly before settling at the target.
---@param t number
---@return number
lurek.math.inBack = function(t) end

--- Bounce ease-in — reverse bounce effect that accelerates into the motion.
---@param t number
---@return number
lurek.math.inBounce = function(t) end

--- Cubic ease-in — acceleration starts slowly then increases sharply.
---@param t number
---@return number
lurek.math.inCubic = function(t) end

--- Elastic ease-in — spring-like overshoot at the beginning of the motion.
---@param t number
---@return number
lurek.math.inElastic = function(t) end

--- Exponential ease-in — very slow start that accelerates sharply near the end.
---@param t number
---@return number
lurek.math.inExpo = function(t) end

--- Back ease-in-out — overshoot on both ends.
---@param t number
---@return number
lurek.math.inOutBack = function(t) end

--- Bounce ease-in-out — bouncing motion on both ends.
---@param t number
---@return number
lurek.math.inOutBounce = function(t) end

--- Cubic ease-in-out — slow start and end with fast cubic middle.
---@param t number
---@return number
lurek.math.inOutCubic = function(t) end

--- Elastic ease-in-out — spring-like oscillation on both ends.
---@param t number
---@return number
lurek.math.inOutElastic = function(t) end

--- Exponential ease-in-out — very slow start and end with an exponential surge.
---@param t number
---@return number
lurek.math.inOutExpo = function(t) end

--- Quadratic ease-in-out — slow start, fast middle, slow end.
---@param t number
---@return number
lurek.math.inOutQuad = function(t) end

--- Quartic ease-in-out — very slow start and end with a sharp middle peak.
---@param t number
---@return number
lurek.math.inOutQuart = function(t) end

--- Sinusoidal ease-in-out — smooth S-curve based on cosine interpolation.
---@param t number
---@return number
lurek.math.inOutSine = function(t) end

--- Quadratic ease-in — acceleration that starts at zero and increases.
---@param t number
---@return number
lurek.math.inQuad = function(t) end

--- Quartic ease-in — strongly delayed acceleration using a power-of-4 curve.
---@param t number
---@return number
lurek.math.inQuart = function(t) end

--- Sinusoidal ease-in — gentle acceleration based on a sine curve.
---@param t number
---@return number
lurek.math.inSine = function(t) end

--- Returns the interpolation parameter t for `v` in [a, b].
---@param a number
---@param b number
---@param v number
---@return number
lurek.math.inverseLerp = function(a, b, v) end

--- Returns true if the polygon (flat table {x1,y1,...}) is convex.
---@param polygon table
---@return boolean
lurek.math.isConvex = function(polygon) end

--- Linear interpolation between two numbers: a + (b - a) * t.
---@param a number
---@param b number
---@param t number
---@return number
lurek.math.lerp = function(a, b, t) end

--- Infinite line intersection. Returns (x, y) or (nil, nil) if lines are parallel.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@param x4 number
---@param y4 number
---@return table
lurek.math.lineIntersect = function(x1, y1, x2, y2, x3, y3, x4, y4) end

--- Linear easing (identity).
---@param t number
---@return number
lurek.math.linear = function(t) end

--- Converts a linear-space value to gamma-encoded sRGB.
---@param c number
---@return number
lurek.math.linearToGamma = function(c) end

--- Returns the natural log of x, or log base b if b is supplied.
---@param x number
---@param b? number
---@return number
lurek.math.log = function(x, b) end

--- Returns the largest of the supplied numbers.
---@param ... number
---@return number
lurek.math.max = function(...) end

--- Returns the smallest of the supplied numbers.
---@param ... number
---@return number
lurek.math.min = function(...) end

--- Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
---@param points table
---@return BezierCurve
lurek.math.newBezierCurve = function(points) end

--- Creates a new Circle value type with the given centre and radius.
---@param x number
---@param y number
---@param radius number Radius(clamped to 0 if negative)
---@return Circle
lurek.math.newCircle = function(x, y, radius) end

--- Creates a new seeded noise generator.
---@param seed? integer
---@return NoiseGenerator
lurek.math.newNoiseGenerator = function(seed) end

--- Creates a new random number generator with an optional seed.
---@param seed? integer
---@return RandomGenerator
lurek.math.newRandomGenerator = function(seed) end

--- Creates a new SpatialHash with the given cell size.
---@param cellSize number
---@return SpatialHash
lurek.math.newSpatialHash = function(cellSize) end

--- Creates a new Transform, optionally initialised from full parameters.
---@param x? number
---@param y? number
---@param angle? number
---@param sx? number
---@param sy? number
---@param ox? number
---@param oy? number
---@param kx? number
---@param ky? number
---@return Transform
lurek.math.newTransform = function(x, y, angle, sx, sy, ox, oy, kx, ky) end

--- Creates a new Tween with the given duration and easing name.
---@param duration number
---@param easingName? string
---@return Tween
lurek.math.newTween = function(duration, easingName) end

--- Back ease-out — overshoots the target then snaps back into place.
---@param t number
---@return number
lurek.math.outBack = function(t) end

--- Bounce ease-out — simulates a ball bouncing against the target value.
---@param t number
---@return number
lurek.math.outBounce = function(t) end

--- Cubic ease-out — rapid deceleration using a cubic power curve.
---@param t number
---@return number
lurek.math.outCubic = function(t) end

--- Elastic ease-out — spring-like oscillation that settles at the target.
---@param t number
---@return number
lurek.math.outElastic = function(t) end

--- Exponential ease-out — sharp initial speed that decelerates exponentially.
---@param t number
---@return number
lurek.math.outExpo = function(t) end

--- Quadratic ease-out — deceleration that starts fast and ends at zero.
---@param t number
---@return number
lurek.math.outQuad = function(t) end

--- Quartic ease-out — rapid deceleration using a power-of-4 curve.
---@param t number
---@return number
lurek.math.outQuart = function(t) end

--- Sinusoidal ease-out — gentle deceleration based on a cosine curve.
---@param t number
---@return number
lurek.math.outSine = function(t) end

--- Returns 2D Perlin noise at (x, y) with the given seed.
---@param x number
---@param y number
---@param seed? integer
---@return number
lurek.math.perlin2d = function(x, y, seed) end

--- Returns 3D Perlin noise at (x, y, z) with the given seed.
---@param x number
---@param y number
---@param z number
---@param seed? integer
---@return number
lurek.math.perlin3d = function(x, y, z, seed) end

--- Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
---@param polygon table
---@param px number
---@param py number
---@return boolean
lurek.math.pointInPolygon = function(polygon, px, py) end

--- Returns the signed area of a polygon given as a flat {x1,y1,...} table.
---@param polygon table
---@return number
lurek.math.polygonArea = function(polygon) end

--- Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
---@param polygon table
---@return number
---@return number
lurek.math.polygonCentroid = function(polygon) end

--- Clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
---@param polygon table
---@param nx number
---@param ny number
---@param d number
---@return table
lurek.math.polygonClip = function(polygon, nx, ny, d) end

--- Computes the approximate difference `A - B` (the part of A not covered by B).
---@param a table
---@param b table
---@return table
lurek.math.polygonDifference = function(a, b) end

--- Computes the intersection of two convex polygons using the Sutherland-Hodgman
---@param a table
---@param b table
---@return table
lurek.math.polygonIntersection = function(a, b) end

--- Computes the approximate union of two convex polygons as the convex hull of
---@param a table
---@param b table
---@return table
lurek.math.polygonUnion = function(a, b) end

--- Returns x raised to the power y.
---@param x number
---@param y number
---@return number
lurek.math.pow = function(x, y) end

--- Converts degrees to radians.
---@param deg number
---@return number
lurek.math.rad = function(deg) end

--- Returns a pseudo-random number in [0,1) with no args,
---@param min_or_max? number
---@param max? number
---@return number
lurek.math.random = function(min_or_max, max) end

--- Returns a pseudo-random integer in [lo, hi] (inclusive).
---@param lo integer
---@param hi integer
---@return number
lurek.math.randomInt = function(lo, hi) end

--- Creates a rectangle centered at (cx, cy) with the given width and height.
---@param cx number
---@param cy number
---@param w number
---@param h number
---@return number
---@return number
---@return number
---@return number
lurek.math.rectFromCenter = function(cx, cy, w, h) end

--- Returns the union (bounding box) of two rectangles.
---@param x1 number
---@param y1 number
---@param w1 number
---@param h1 number
---@param x2 number
---@param y2 number
---@param w2 number
---@param h2 number
---@return number
---@return number
---@return number
---@return number
lurek.math.rectUnion = function(x1, y1, w1, h1, x2, y2, w2, h2) end

--- Remaps `v` from [in_min, in_max] to [out_min, out_max].
---@param v number
---@param in_min number
---@param in_max number
---@param out_min number
---@param out_max number
---@return number
lurek.math.remap = function(v, in_min, in_max, out_min, out_max) end

--- Converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1).
---@param r number
---@param g number
---@param b number
---@return number
---@return number
---@return number
lurek.math.rgbToHsl = function(r, g, b) end

--- Returns x rounded to the nearest integer (half-up).
---@param x number
---@return number
lurek.math.round = function(x) end

--- Tests if two line segments intersect. Returns (hit, ix?, iy?).
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@param x4 number
---@param y4 number
---@return table
lurek.math.segmentIntersectsSegment = function(x1, y1, x2, y2, x3, y3, x4, y4) end

--- Returns -1, 0, or 1 depending on the sign of `v`.
---@param v number
---@return number
lurek.math.sign = function(v) end

--- Returns 2D Simplex noise at (x, y) with the given seed.
---@param x number
---@param y number
---@param seed? integer
---@return number
lurek.math.simplex2d = function(x, y, seed) end

--- Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
---@param x number
---@param y number
---@param z? number
---@return number
lurek.math.simplexNoise = function(x, y, z) end

--- Returns the sine of x (radians).
---@param x number
---@return number
lurek.math.sin = function(x) end

--- Hermite smoothstep between `edge0` and `edge1`.
---@param edge0 number
---@param edge1 number
---@param x number
---@return number
lurek.math.smoothstep = function(edge0, edge1, x) end

--- Returns the square root of x.
---@param x number
---@return number
lurek.math.sqrt = function(x) end

--- Returns the tangent of x (radians).
---@param x number
---@return number
lurek.math.tan = function(x) end

--- Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
---@param polygon table
---@return table
lurek.math.triangulate = function(polygon) end

--- Creates a 2D vector with x and y components.
---@param x number
---@param y number
---@return Vec2
lurek.math.vec2 = function(x, y) end

--- Creates a 3D vector `{x, y, z}` table with numeric components.
---@param x number
---@param y number
---@param z number
---@return Vec3
lurek.math.vec3 = function(x, y, z) end

--- Computes the Voronoi diagram for a list of 2-D seed points.
---@param points table -- array of `{x,y}` tables
---@return table
lurek.math.voronoi = function(points) end

---@class lurek.minimap
lurek.minimap = {}

--- Lua-side wrapper around a [`Minimap`].
---@class LMinimap
LMinimap = {}

--- Adds a persistent marker and returns its auto-assigned ID.
---@param x number
---@param y number
---@param desc? string
---@param r? number
---@param g? number
---@param b? number
---@param a? number
---@return number
function LMinimap:addMarker(x, y, desc, r, g, b, a) end

--- Registers a new object type and returns its 1-based index.
---@param name string
---@param r number
---@param g number
---@param b number
---@param a? number
---@return number
function LMinimap:addObjectType(name, r, g, b, a) end

--- Adds an animated ping at grid coordinates with a duration and optional color.
---@param x number
---@param y number
---@param duration number
---@param r? number
---@param g? number
---@param b? number
---@param a? number
---@return nil
function LMinimap:addPing(x, y, duration, r, g, b, a) end

--- Removes the animation from a marker, reverting it to static.
---@param id integer
---@return nil
function LMinimap:clearMarkerAnimation(id) end

--- Removes all tracked objects.
---@return nil
function LMinimap:clearObjects() end

--- Removes all custom geometry from the minimap overlay.
---@return nil
function LMinimap:clearOverlay() end

--- Removes a displayed path. If id is nil, all paths are removed.
---@param id? integer
---@return nil
function LMinimap:clearPath(id) end

--- Clears the viewport rectangle overlay.
---@return nil
function LMinimap:clearViewportRect() end

--- Draws a custom line segment on the minimap overlay.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param color table
---@return nil
function LMinimap:drawLine(x1, y1, x2, y2, color) end

--- Draws a custom rectangle on the minimap overlay.
---@param x number
---@param y number
---@param w number
---@param h number
---@param color table
---@return nil
function LMinimap:drawRect(x, y, w, h, color) end

--- Renders the minimap grid to a CPU ImageData.
---@param pixel_size integer
---@return ImageData
function LMinimap:drawToImage(pixel_size) end

--- Returns the center coordinates as x, y.
---@return number
---@return number
function LMinimap:getCenter() end

--- Returns the center X coordinate.
---@return number
function LMinimap:getCenterX() end

--- Returns the center Y coordinate.
---@return number
function LMinimap:getCenterY() end

--- Returns the current color mode as a string.
---@return string
function LMinimap:getColorMode() end

--- Returns the display height in pixels.
---@return number
function LMinimap:getDisplayHeight() end

--- Returns the display width and height as two values.
---@return integer
---@return integer
function LMinimap:getDisplaySize() end

--- Returns the display width in pixels.
---@return number
function LMinimap:getDisplayWidth() end

--- Returns the fog overlay color as r, g, b, a.
---@return number
---@return number
---@return number
---@return number
function LMinimap:getFogColor() end

--- Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
---@param x integer
---@param y integer
---@return number
function LMinimap:getFogLevel(x, y) end

--- Returns the grid height in cells.
---@return number
function LMinimap:getGridHeight() end

--- Returns the grid width and height as two values.
---@return integer
---@return integer
function LMinimap:getGridSize() end

--- Returns the grid width in cells.
---@return number
function LMinimap:getGridWidth() end

--- Returns hover tooltip text for the element under screen coordinates, or nil.
---@param sx number
---@param sy number
---@param minimap_x number
---@param minimap_y number
---@return string
function LMinimap:getHoverInfo(sx, sy, minimap_x, minimap_y) end

--- Returns the index of the currently active render layer.
---@return number
function LMinimap:getLayer() end

--- Returns the number of markers.
---@return number
function LMinimap:getMarkerCount() end

--- Returns the description of a marker, or nil.
---@param id integer
---@return string
function LMinimap:getMarkerDescription(id) end

--- Returns the number of tracked objects.
---@return number
function LMinimap:getObjectCount() end

--- Returns the number of registered object types.
---@return number
function LMinimap:getObjectTypeCount() end

--- Returns the display color for an owner/faction as r, g, b, a.
---@param owner integer
---@return number
---@return number
---@return number
---@return number
function LMinimap:getOwnerColor(owner) end

--- Returns the number of active pings.
---@return number
function LMinimap:getPingCount() end

--- Returns the terrain type at a 1-based grid position.
---@param x integer
---@param y integer
---@return number
function LMinimap:getTerrain(x, y) end

--- Returns the display color for a terrain type as r, g, b, a.
---@param terrain_type integer
---@return number
---@return number
---@return number
---@return number
function LMinimap:getTerrainColor(terrain_type) end

--- Returns the hover tooltip string for a terrain type ID, or nil.
---@param type_id integer
---@return string
function LMinimap:getTileDescription(type_id) end

--- Returns the viewport rectangle color as r, g, b, a.
---@return number
---@return number
---@return number
---@return number
function LMinimap:getViewportColor() end

--- Returns the viewport rectangle as x, y, w, h or nil if not set.
---@return nil
function LMinimap:getViewportRect() end

--- Returns the current zoom level.
---@return number
function LMinimap:getZoom() end

--- Converts grid coordinates to screen coordinates.
---@param gx number
---@param gy number
---@param minimap_x number
---@param minimap_y number
---@return number
---@return number
function LMinimap:gridToScreen(gx, gy, minimap_x, minimap_y) end

--- Returns whether a marker with the given ID exists.
---@param id integer
---@return boolean
function LMinimap:hasMarker(id) end

--- Returns whether anti-aliasing is enabled.
---@return boolean
function LMinimap:isAntiAlias() end

--- Returns whether this minimap responds to click hit-testing.
---@return boolean
function LMinimap:isClickable() end

--- Returns whether fog of war is enabled.
---@return boolean
function LMinimap:isFogEnabled() end

--- Returns whether an object type (1-based index) is visible.
---@param type_idx integer
---@return boolean
function LMinimap:isObjectTypeVisible(type_idx) end

--- Returns whether the viewport rectangle is visible.
---@return boolean
function LMinimap:isViewportVisible() end

--- Removes the minimap marker with the given integer ID, if present.
---@param id integer
---@return boolean
function LMinimap:removeMarker(id) end

--- Removes a tracked object by ID.
---@param id integer
---@return boolean
function LMinimap:removeObject(id) end

--- Renders the minimap to the screen at the given position.
---@param x? number
---@param y? number
---@return nil
function LMinimap:render(x, y) end

--- Converts screen coordinates to grid coordinates.
---@param sx number
---@param sy number
---@param minimap_x number
---@param minimap_y number
---@return number
---@return number
function LMinimap:screenToGrid(sx, sy, minimap_x, minimap_y) end

--- Sets whether anti-aliasing is enabled.
---@param enabled boolean
---@return nil
function LMinimap:setAntiAlias(enabled) end

--- Sets the center of the minimap view in grid coordinates.
---@param x number
---@param y number
---@return nil
function LMinimap:setCenter(x, y) end

--- Sets whether this minimap responds to click hit-testing.
---@param enabled boolean
---@return nil
function LMinimap:setClickable(enabled) end

--- Sets the color mode ("terrain" or "political").
---@param mode string
---@return nil
function LMinimap:setColorMode(mode) end

--- Sets the display size in pixels.
---@param w integer
---@param h integer
---@return nil
function LMinimap:setDisplaySize(w, h) end

--- Sets the fog overlay color.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LMinimap:setFogColor(r, g, b, a) end

--- Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
---@param data table
---@return nil
function LMinimap:setFogData(data) end

--- Enables or disables fog of war.
---@param enabled boolean
---@return nil
function LMinimap:setFogEnabled(enabled) end

--- Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
---@param x integer
---@param y integer
---@param level integer
---@return nil
function LMinimap:setFogLevel(x, y, level) end

--- Switches the minimap's active render layer (0-based index).
---@param layer integer
---@return nil
function LMinimap:setLayer(layer) end

--- Stores tile data for a specific layer index.
---@param layer integer
---@param data table
---@return nil
function LMinimap:setLayerData(layer, data) end

--- Attaches an animation to a marker. Does nothing if the ID does not exist.
---@param id integer
---@param anim_type string
---@param speed number
---@return nil
function LMinimap:setMarkerAnimation(id, anim_type, speed) end

--- Sets or updates a tracked object on the minimap.
---@param id integer
---@param x number
---@param y number
---@param type_idx integer
---@param owner? integer
---@return nil
function LMinimap:setObject(id, x, y, type_idx, owner) end

--- Sets whether an object type (1-based index) is visible.
---@param type_idx integer
---@param visible boolean
---@return nil
function LMinimap:setObjectTypeVisible(type_idx, visible) end

--- Sets the display color for an owner/faction.
---@param owner integer
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LMinimap:setOwnerColor(owner, r, g, b, a) end

--- Sets the terrain type at a 1-based grid position.
---@param x integer
---@param y integer
---@param terrain_type integer
---@return nil
function LMinimap:setTerrain(x, y, terrain_type) end

--- Sets the display color for a terrain type.
---@param terrain_type integer
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LMinimap:setTerrainColor(terrain_type, r, g, b, a) end

--- Sets terrain types from a flat 1-based Lua table of integers (row-major).
---@param data table
---@return nil
function LMinimap:setTerrainData(data) end

--- Sets a hover tooltip string for a terrain type ID.
---@param type_id integer
---@param desc string
---@return nil
function LMinimap:setTileDescription(type_id, desc) end

--- Sets the viewport rectangle color.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LMinimap:setViewportColor(r, g, b, a) end

--- Sets the viewport rectangle overlay in grid coordinates.
---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function LMinimap:setViewportRect(x, y, w, h) end

--- Sets whether the viewport rectangle is visible.
---@param visible boolean
---@return nil
function LMinimap:setViewportVisible(visible) end

--- Sets the zoom level (minimum 0.1).
---@param zoom number
---@return nil
function LMinimap:setZoom(zoom) end

--- Displays a pathfinding route on the minimap and returns its path ID.
---@param points table
---@param color table
---@return nil
function LMinimap:showPath(points, color) end

--- Returns the type name of this object.
---@return string
function LMinimap:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LMinimap:typeOf(name) end

--- Advances time-based effects by dt seconds (expires pings).
---@param dt number
---@return nil
function LMinimap:update(dt) end

--- Creates a new grid-based minimap.
---@param grid_w integer
---@param grid_h integer
---@param display_w? integer
---@param display_h? integer
---@return Minimap
lurek.minimap.newMinimap = function(grid_w, grid_h, display_w, display_h) end

---@class lurek.mods
lurek.mods = {}

--- A typed content registry for mod-contributed assets and objects.
---@class LContentRegistry
LContentRegistry = {}

--- Retrieve a content entry.
---@param type_name string — registered type name
---@param id string — content identifier
---@return number
function LContentRegistry:get(type_name, id) end

--- Get all entries for a type.
---@param type_name string — registered type name
---@return number
function LContentRegistry:getAll(type_name) end

--- Get all registered type names.
---@return string
function LContentRegistry:getTypes() end

--- Register a content entry.
---@param type_name string — registered type name
---@param id string — unique identifier for this entry
---@param obj any — the content object to store
---@return nil
function LContentRegistry:register(type_name, id, obj) end

--- Register a new content type.
---@param type_name string — type identifier(e.g. "weapon","spell")
---@return nil
function LContentRegistry:registerType(type_name) end

--- Returns the type name of this object.
---@return string
function LContentRegistry:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LContentRegistry:typeOf(name) end

--- Lua-side wrapper around [`ModInfo`] with per-mod hook and config storage.
---@class LMod
LMod = {}

--- Returns the required engine API version string, or nil if not set
---@return string
function LMod:getApiVersion() end

--- Returns the author name string from this mod's metadata manifest
---@return string
function LMod:getAuthor() end

--- Returns an array of declared capability flags
---@return table
function LMod:getCapabilities() end

--- Returns the stored config value, or nil
---@return table
function LMod:getConfig() end

--- Returns the config schema as an array of `{key, type, default}` tables.
---@return table
function LMod:getConfigSchema() end

--- Returns the list of required mod IDs
---@return table
function LMod:getDependencies() end

--- Returns the mod description
---@return string
function LMod:getDescription() end

--- Returns the hook function for the given name, or nil
---@param name string
---@return function
function LMod:getHook(name) end

--- Returns an array of registered hook names
---@return table
function LMod:getHookNames() end

--- Returns the unique mod identifier
---@return string
function LMod:getId() end

--- Returns the localized or human-readable display name of the mod.
---@return string
function LMod:getName() end

--- Returns the load-order priority
---@return number
function LMod:getPriority() end

--- Returns the version string
---@return string
function LMod:getVersion() end

--- Returns whether a hook with the given name exists
---@param name string
---@return boolean
function LMod:hasHook(name) end

--- Returns whether the mod is enabled
---@return boolean
function LMod:isEnabled() end

--- Returns whether the mod has been loaded
---@return boolean
function LMod:isLoaded() end

--- Releases all hook and config registry references
---@return nil
function LMod:releaseRefs() end

--- Sets the required engine API version string
---@param api_version string
---@return nil
function LMod:setApiVersion(api_version) end

--- Replaces the capability list with the given array of strings
---@param caps table
---@return nil
function LMod:setCapabilities(caps) end

--- Stores an arbitrary config value for this mod
---@param value table
---@return nil
function LMod:setConfig(value) end

--- Replaces the config schema with the given array of `{key, type, default}` tables.
---@param schema table
---@return nil
function LMod:setConfigSchema(schema) end

--- Enables or disables this mod; disabled mods are skipped during loading
---@param enabled boolean
---@return nil
function LMod:setEnabled(enabled) end

--- Registers a named hook callback, replacing any existing one
---@param name string
---@param func function
---@return nil
function LMod:setHook(name, func) end

--- Returns the type name of this object.
---@return string
function LMod:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LMod:typeOf(name) end

--- Lua-side wrapper around [`ModManager`].
---@class LModManager
LModManager = {}

--- Clears the custom load order, reverting to priority-based sorting
---@return nil
function LModManager:clearLoadOrder() end

--- Clears the reload queue without reloading
---@return nil
function LModManager:clearReloadQueue() end

--- Returns an array of info tables for all registered mods
---@return table
function LModManager:getAllMods() end

--- Returns an array of info tables in effective load order
---@return table
function LModManager:getLoadOrder() end

--- Returns the number of registered mods
---@return number
function LModManager:getModCount() end

--- Returns the filesystem path of a registered mod, or nil
---@param mod_id string
---@return string
function LModManager:getModPath(mod_id) end

--- Returns the array of mod IDs pending hot-reload
---@return table
function LModManager:getReloadQueue() end

--- Returns whether any circular dependency cycles exist
---@return boolean
function LModManager:hasCircularDependencies() end

--- Returns whether a mod with the given ID is registered
---@param mod_id string
---@return boolean
function LModManager:hasMod(mod_id) end

--- Marks a registered mod for hot-reload
---@param mod_id string
---@return boolean
function LModManager:markForReload(mod_id) end

--- Registers a mod from its Mod userdata
---@param mod_ud Mod
---@return nil
function LModManager:registerMod(mod_ud) end

--- Scans a directory for mods with mod.toml and registers them
---@param path string
---@return table
function LModManager:scanFolder(path) end

--- Sets an explicit load order from an array of mod ID strings
---@param order table
---@return nil
function LModManager:setLoadOrder(order) end

--- Returns the type name of this object.
---@return string
function LModManager:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LModManager:typeOf(name) end

--- Removes a mod by ID and returns whether it was found
---@param mod_id string
---@return boolean
function LModManager:unregisterMod(mod_id) end

--- Returns an array of mod IDs with missing dependencies
---@return table
function LModManager:validateDependencies() end

--- Checks whether a mod's required `api_version` is compatible with the given `host_version`.
---@param mod_ud Mod
---@param host_version string
---@return table
lurek.mods.checkApiVersion = function(mod_ud, host_version) end

--- Creates a new Mod from an info table with at least an `id` field.
---@param info table
---@return Mod
lurek.mods.newMod = function(info) end

--- Creates a new empty ModManager.
---@return ModManager
lurek.mods.newModManager = function() end

--- Creates a new empty ContentRegistry for mod-contributed assets.
---@return ContentRegistry
lurek.mods.newRegistry = function() end

---@class lurek.network
lurek.network = {}

--- Lua-side wrapper around [`NetworkHost`].
---@class LNetworkHost
LNetworkHost = {}

--- Broadcasts data to all connected peers on a channel.
---@param channel_id integer
---@param data string
---@param reliable? boolean
---@return nil
function LNetworkHost:broadcast(channel_id, data, reliable) end

--- Initiates a connection to a remote host, returning the peer ID.
---@param addr string
---@param channels? integer
---@param data? integer
---@return number
function LNetworkHost:connect(addr, channels, data) end

--- Destroys the host, closing the underlying socket.
---@return nil
function LNetworkHost:destroy() end

--- Gracefully disconnects a peer.
---@param peer_id integer
---@param data? integer
---@return nil
function LNetworkHost:disconnect(peer_id, data) end

--- Disconnects a peer after all queued packets have been sent.
---@param peer_id integer
---@param data? integer
---@return nil
function LNetworkHost:disconnectLater(peer_id, data) end

--- Immediately disconnects a peer without handshake.
---@param peer_id integer
---@param data? integer
---@return nil
function LNetworkHost:disconnectNow(peer_id, data) end

--- Flushes all pending sends immediately.
---@return nil
function LNetworkHost:flush() end

--- Returns the local bind address as a string.
---@return string
function LNetworkHost:getAddress() end

--- Returns the bandwidth limits as a table with incoming and outgoing fields.
---@return table
function LNetworkHost:getBandwidthLimit() end

--- Returns the maximum number of channels per connection.
---@return number
function LNetworkHost:getChannelLimit() end

--- Returns the number of currently connected peers.
---@return number
function LNetworkHost:getConnectedPeerCount() end

--- Returns a table of connected peer IDs.
---@return table
function LNetworkHost:getConnectedPeerIds() end

--- Returns the remote address of a peer, or nil if unavailable.
---@param peer_id integer
---@return string
function LNetworkHost:getPeerAddress(peer_id) end

--- Returns the maximum number of peer slots.
---@return number
function LNetworkHost:getPeerLimit() end

--- Returns the connection state of a peer as a string.
---@param peer_id integer
---@return string
function LNetworkHost:getPeerState(peer_id) end

--- Returns a statistics table for a peer.
---@param peer_id integer
---@return table
function LNetworkHost:getPeerStats(peer_id) end

--- Returns the multiplayer role of this host ("server", "client", or "host").
---@return string
function LNetworkHost:getRole() end

--- Returns the round-trip time estimate for a peer in milliseconds.
---@param peer_id integer
---@return number
function LNetworkHost:getRoundTripTime(peer_id) end

--- Returns true if this host was created as a client.
---@return boolean
function LNetworkHost:isClient() end

--- Returns true if the host has been destroyed.
---@return boolean
function LNetworkHost:isDestroyed() end

--- Returns true if this host was created as a server.
---@return boolean
function LNetworkHost:isServer() end

--- Sends a ping to a peer to measure round-trip time.
---@param peer_id integer
---@return nil
function LNetworkHost:ping(peer_id) end

--- Resets a peer connection immediately without notifying the remote side.
---@param peer_id integer
---@return nil
function LNetworkHost:resetPeer(peer_id) end

--- Sends data to a specific peer on a channel.
---@param peer_id integer
---@param channel_id integer
---@param data string
---@param reliable? boolean
---@return nil
function LNetworkHost:send(peer_id, channel_id, data, reliable) end

--- Polls the network for one event, returning an event table or nil.
---@param timeout_ms? integer
---@return table
function LNetworkHost:service(timeout_ms) end

--- Sets the bandwidth limits in bytes per second.
---@param incoming? integer
---@param outgoing? integer
---@return nil
function LNetworkHost:setBandwidthLimit(incoming, outgoing) end

--- Sets the channel limit for future connections.
---@param limit integer
---@return nil
function LNetworkHost:setChannelLimit(limit) end

--- Returns the type name of this object.
---@return string
function LNetworkHost:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LNetworkHost:typeOf(name) end

--- Lua-side wrapper around [`NetworkRuntime`] for async HTTP/TCP/WebSocket.
---@class LNetworkRuntime
LNetworkRuntime = {}

--- Convenience: sends an HTTP GET request.
---@param url string
---@param headers? table
---@return number
function LNetworkRuntime:httpGet(url, headers) end

--- Convenience: sends an HTTP POST request.
---@param url string
---@param body string
---@param headers? table
---@return number
function LNetworkRuntime:httpPost(url, body, headers) end

--- Sends an HTTP request asynchronously. Poll with `poll()` for the response.
---@param opts table —{method,url,headers?,body?,timeout?}
---@return nil
function LNetworkRuntime:httpRequest(opts) end

--- Polls for completed async responses (HTTP, TCP events, WebSocket events).
---@return table
function LNetworkRuntime:poll() end

--- Shuts down the background network thread.
---@return nil
function LNetworkRuntime:shutdown() end

--- Closes the TCP connection identified by the given connection handle.
---@param id integer — connection ID
---@return nil
function LNetworkRuntime:tcpClose(id) end

--- Opens a TCP connection to a remote address.
---@param addr string
---@return number
function LNetworkRuntime:tcpConnect(addr) end

--- Sends data over a TCP connection.
---@param id integer — connection ID
---@param data string
---@return nil
function LNetworkRuntime:tcpSend(id, data) end

--- Returns the type name of this object.
---@return string
function LNetworkRuntime:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LNetworkRuntime:typeOf(name) end

--- Closes a WebSocket connection.
---@param id integer — connection ID
---@return nil
function LNetworkRuntime:wsClose(id) end

--- Opens a WebSocket connection.
---@param url string
---@return number
function LNetworkRuntime:wsConnect(url) end

--- Sends a text message over a WebSocket connection.
---@param id integer — connection ID
---@param data string
---@return nil
function LNetworkRuntime:wsSend(id, data) end

--- Creates a LobbyInfo record and broadcasts it once on the local network.
---@param name string
---@param port integer
---@param player_count? integer
---@param max_players? integer
---@return table
lurek.network.createLobby = function(name, port, player_count, max_players) end

--- Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
---@param timeout_ms? integer
---@return table
lurek.network.discoverLobbies = function(timeout_ms) end

--- Creates a client host that connects to a remote server.
---@param opts table —{addr,channels?,data?}
---@return NetworkHost
lurek.network.newClient = function(opts) end

--- Creates a new network host bound to the given address.
---@param opts? table —{addr?,maxPeers?,peers?,channels?,inBandwidth?,outBandwidth?}
---@return NetworkHost
lurek.network.newHost = function(opts) end

--- Creates a background network runtime for async HTTP, TCP, and WebSocket.
---@return NetworkRuntime
lurek.network.newRuntime = function() end

--- Creates a server host that binds to a port and accepts connections.
---@param opts table —{port,maxPeers?,peers?,channels?}
---@return NetworkHost
lurek.network.newServer = function(opts) end

--- Serializes a Lua value to a binary MessagePack string.
---@param value any
---@return string
lurek.network.pack = function(value) end

--- Convenience helper: packs an entity snapshot and broadcasts it to all peers.
---@param host NetworkHost
---@param entity_id integer
---@param data table
---@param channel? integer
---@param reliable? boolean
---@return nil
lurek.network.syncEntity = function(host, entity_id, data, channel, reliable) end

--- Deserializes a MessagePack binary string back to a Lua value.
---@param data string
---@return table
lurek.network.unpack = function(data) end

---@class lurek.parallax
lurek.parallax = {}

--- Lua-side handle to a single parallax background layer.
---@class LParallaxLayer
LParallaxLayer = {}

--- Removes scroll clamping so the layer scrolls freely.
---@return nil
function LParallaxLayer:clearClamp() end

--- Returns the autoscroll velocity as `(vx, vy)`.
---@return number
---@return number
function LParallaxLayer:getAutoscroll() end

--- Returns the current blend mode as a string.
---@return string
function LParallaxLayer:getBlendMode() end

--- Returns the current floating-point depth.
---@return number
function LParallaxLayer:getDepth() end

--- Returns the static offset as `(x, y)`.
---@return number
---@return number
function LParallaxLayer:getOffset() end

--- Returns the current opacity.
---@return number
function LParallaxLayer:getOpacity() end

--- Returns the scroll factor as `(x, y)`.
---@return number
---@return number
function LParallaxLayer:getScrollFactor() end

--- Returns `true` if seamless infinite tiling is enabled.
---@return boolean
function LParallaxLayer:getTiling() end

--- Returns the current tint as `(r, g, b, a)`.
---@return number
---@return number
---@return number
---@return number
function LParallaxLayer:getTint() end

--- Returns the draw-order depth.
---@return number
function LParallaxLayer:getZ() end

--- Returns `true` if the layer is currently visible.
---@return boolean
function LParallaxLayer:isVisible() end

--- Draws the layer using an explicit camera world position.
---@param cam_x number
---@param cam_y number
---@return nil
function LParallaxLayer:render(cam_x, cam_y) end

--- Draws the layer using the engine active camera position automatically.
---@return nil
function LParallaxLayer:renderAuto() end

--- Resets the autonomous scroll accumulator to zero.
---@return nil
function LParallaxLayer:resetAutoscroll() end

--- Sets the autonomous scroll velocity in world-pixels per second.
---@param vx number
---@param vy number
---@return nil
function LParallaxLayer:setAutoscroll(vx, vy) end

--- Sets the GPU blend mode for this layer.
---@param mode string
---@return nil
function LParallaxLayer:setBlendMode(mode) end

--- Clamps the scroll offset to a world-pixel range on each axis.
---@param min_x number
---@param min_y number
---@param max_x number
---@param max_y number
---@return nil
function LParallaxLayer:setClamp(min_x, min_y, max_x, max_y) end

--- Sets the floating-point draw depth for fine-grained layer ordering.
---@param z number
---@return nil
function LParallaxLayer:setDepth(z) end

--- Sets the static world-pixel position bias added on top of camera scroll.
---@param x number
---@param y number
---@return nil
function LParallaxLayer:setOffset(x, y) end

--- Sets the layer-wide opacity override in `[0.0, 1.0]`.
---@param a number
---@return nil
function LParallaxLayer:setOpacity(a) end

--- Sets whether the layer tiles on the X and Y axes.
---@param repeat_x boolean
---@param repeat_y boolean
---@return nil
function LParallaxLayer:setRepeat(repeat_x, repeat_y) end

--- Sets the texture display scale factor on each axis.
---@param sx number
---@param sy number
---@return nil
function LParallaxLayer:setScale(sx, sy) end

--- Sets the scroll factor relative to camera movement on each axis.
---@param x number
---@param y number
---@return nil
function LParallaxLayer:setScrollFactor(x, y) end

--- Sets explicit tile dimensions in logical pixels, overriding the default
---@param w number
---@param h number
---@return nil
function LParallaxLayer:setTileSize(w, h) end

--- Enables or disables seamless infinite tiling on both axes simultaneously.
---@param enabled boolean
---@return nil
function LParallaxLayer:setTiling(enabled) end

--- Sets the multiplicative RGBA tint applied to all pixels of this layer.
---@param r number
---@param g number
---@param b number
---@param a number
---@return nil
function LParallaxLayer:setTint(r, g, b, a) end

--- Shows or hides this layer.
---@param visible boolean
---@return nil
function LParallaxLayer:setVisible(visible) end

--- Sets the draw-order depth. Lower values render first (further back).
---@param z integer
---@return nil
function LParallaxLayer:setZ(z) end

--- Returns the type name of this object.
---@return string
function LParallaxLayer:type() end

--- Advances the autonomous scroll accumulator by `dt` seconds.
---@param dt number
---@return nil
function LParallaxLayer:update(dt) end

--- Lua-side container that groups `LuaParallaxLayer` objects for scene-level management.
---@class LParallaxSet
LParallaxSet = {}

--- Adds a layer to this set.
---@param layer LuaParallaxLayer
---@return nil
function LParallaxSet:addLayer(layer) end

--- Returns the name of this set.
---@return string
function LParallaxSet:getName() end

--- Returns `true` if the set is currently visible.
---@return boolean
function LParallaxSet:isVisible() end

--- Returns the number of layers in this set.
---@return number
function LParallaxSet:layerCount() end

--- Removes the layer at the given 1-based index.
---@param index integer
---@return boolean
function LParallaxSet:removeLayerAt(index) end

--- Draws all visible layers in ascending `z` order using an explicit camera position.
---@param cam_x number
---@param cam_y number
---@return nil
function LParallaxSet:render(cam_x, cam_y) end

--- Draws all visible layers using the engine active camera position.
---@return nil
function LParallaxSet:renderAuto() end

--- Sets the name of this set.
---@param name string
---@return nil
function LParallaxSet:setName(name) end

--- Shows or hides all layers in this set.
---@param visible boolean
---@return nil
function LParallaxSet:setVisible(visible) end

--- Re-sorts all layers by ascending `z` value.
---@return nil
function LParallaxSet:sortByZ() end

--- Returns the type name of this object.
---@return string
function LParallaxSet:type() end

--- Advances the autoscroll accumulator of every layer by `dt` seconds.
---@param dt number
---@return nil
function LParallaxSet:update(dt) end

--- Creates a new parallax background layer from an options table.
---@param opts table
---@return LuaParallaxLayer
lurek.parallax.newLayer = function(opts) end

--- Creates a new empty parallax set with the given name.
---@param name string
---@return LuaParallaxSet
lurek.parallax.newSet = function(name) end

---@class lurek.particle
lurek.particle = {}

--- Lua-side handle to a particle system stored in SharedState.
---@class LParticleSystem
LParticleSystem = {}

--- Adds a gravity well that pulls (positive strength) or repels
---@param x number
---@param y number
---@param strength number
---@param radius number
---@return nil
function LParticleSystem:addAttractor(x, y, strength, radius) end

--- Attaches a sub-emitter that bursts when a particle dies.
---@param config_tbl table
---@param burst_count? number
---@return nil
function LParticleSystem:addSubEmitter(config_tbl, burst_count) end

--- Adds a child emitter that updates and renders with this system.
---@param config table
---@return number
function LParticleSystem:addSubSystem(config) end

--- Removes all attractors from this particle system.
---@return nil
function LParticleSystem:clearAttractors() end

--- Removes the bounding rectangle so particles can move freely.
---@return nil
function LParticleSystem:clearBounds() end

--- Creates a copy of this particle system (config only, no live particles).
---@return ParticleSystem
function LParticleSystem:clone() end

--- Returns the number of living particles.
---@return number
function LParticleSystem:count() end

--- Renders all live particles to a CPU ImageData.
---@param width integer
---@param height integer
---@return ImageData
function LParticleSystem:drawToImage(width, height) end

--- Emits a burst of the given number of particles.
---@param count integer
---@return nil
function LParticleSystem:emit(count) end

--- Returns the number of attractors currently registered on this system.
---@return number
function LParticleSystem:getAttractorCount() end

--- Returns the maximum particle count.
---@return number
function LParticleSystem:getBufferSize() end

--- Returns color keyframes as a table of {r,g,b,a} tables.
---@return table
function LParticleSystem:getColors() end

--- Returns the number of living particles (alias for count).
---@return number
function LParticleSystem:getCount() end

--- Returns emission direction in radians.
---@return number
function LParticleSystem:getDirection() end

--- Returns emission area: dist-string, w, h.
---@return nil
function LParticleSystem:getEmissionArea() end

--- Returns particles emitted per second.
---@return number
function LParticleSystem:getEmissionRate() end

--- Returns the emitter lifetime.
---@return number
function LParticleSystem:getEmitterLifetime() end

--- Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
---@return nil
function LParticleSystem:getFlipbook() end

--- Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
---@return number
---@return number
function LParticleSystem:getGravity() end

--- Returns the insert mode as a string.
---@return string
function LParticleSystem:getInsertMode() end

--- Returns linear acceleration range.
---@return number
---@return number
---@return number
---@return number
function LParticleSystem:getLinearAcceleration() end

--- Returns linear damping range.
---@return number
---@return number
function LParticleSystem:getLinearDamping() end

--- Returns the render origin offset.
---@return number
---@return number
function LParticleSystem:getOffset() end

--- Returns min and max particle lifetime.
---@return number
---@return number
function LParticleSystem:getParticleLifetime() end

--- Returns the emitter world position.
---@return number
---@return number
function LParticleSystem:getPosition() end

--- Returns radial acceleration range.
---@return number
---@return number
function LParticleSystem:getRadialAcceleration() end

--- Returns initial rotation range.
---@return number
---@return number
function LParticleSystem:getRotation() end

--- Returns the particle draw shape as a string.
---@return string
function LParticleSystem:getShape() end

--- Returns the maximum random size variation applied to newly emitted particles.
---@return number
function LParticleSystem:getSizeVariation() end

--- Returns size keyframes as a Lua table.
---@return table
function LParticleSystem:getSizes() end

--- Returns min/max initial speed.
---@return number
---@return number
function LParticleSystem:getSpeed() end

--- Returns angular velocity range.
---@return number
---@return number
function LParticleSystem:getSpin() end

--- Returns the maximum random angular velocity variation for new particles.
---@return number
function LParticleSystem:getSpinVariation() end

--- Returns the half-angle spread in radians for the emission cone.
---@return number
function LParticleSystem:getSpread() end

--- Returns tangential acceleration range.
---@return number
---@return number
function LParticleSystem:getTangentialAcceleration() end

--- Returns whether relative rotation is enabled.
---@return boolean
function LParticleSystem:hasRelativeRotation() end

--- Returns true if the emitter is currently emitting or has live particles.
---@return boolean
function LParticleSystem:isActive() end

--- Returns true if there are no live particles.
---@return boolean
function LParticleSystem:isEmpty() end

--- Returns true if the system has reached max_particles.
---@return boolean
function LParticleSystem:isFull() end

--- Returns true if the emitter is paused.
---@return boolean
function LParticleSystem:isPaused() end

--- Returns true if the emitter is stopped.
---@return boolean
function LParticleSystem:isStopped() end

--- Moves the emitter to the given world position.
---@param x number
---@param y number
---@return nil
function LParticleSystem:moveTo(x, y) end

--- Pauses particle emission; existing particles continue to simulate.
---@return nil
function LParticleSystem:pause() end

--- Removes the particle system from the engine, freeing its slot.
---@return nil
function LParticleSystem:release() end

--- Renders all live particles to the GPU command queue.
---@param ox? number
---@param oy? number
---@return nil
function LParticleSystem:render(ox, oy) end

--- Removes all particles and resets the emitter.
---@return nil
function LParticleSystem:reset() end

--- Resumes a paused emitter.
---@return nil
function LParticleSystem:resume() end

--- Constrains all particles to an axis-aligned bounding rectangle.
---@param xmin number
---@param xmax number
---@param ymin number
---@param ymax number
---@param restitution number
---@return nil
function LParticleSystem:setBounds(xmin, xmax, ymin, ymax, restitution) end

--- Sets the maximum number of particles (resizes the pool).
---@param n integer
---@return nil
function LParticleSystem:setBufferSize(n) end

--- Sets color keyframes. Each arg is a table {r, g, b, a}.
---@param ... table
---@return nil
function LParticleSystem:setColors(...) end

--- Sets a Lua function that returns (offset_x, offset_y) for each newly spawned
---@param fn function
---@return nil
function LParticleSystem:setCustomEmissionShape(fn) end

--- Sets emission direction in radians.
---@param dir number
---@return nil
function LParticleSystem:setDirection(dir) end

--- Sets emission area distribution and size.
---@param dist string
---@param w number
---@param h number
---@param angle? number
---@param dir_relative? boolean
---@return nil
function LParticleSystem:setEmissionArea(dist, w, h, angle, dir_relative) end

--- Sets particles emitted per second.
---@param rate number
---@return nil
function LParticleSystem:setEmissionRate(rate) end

--- Sets how long the emitter runs before auto-stopping. Negative = infinite.
---@param t number
---@return nil
function LParticleSystem:setEmitterLifetime(t) end

--- Configures sprite-sheet flipbook animation by dividing the texture into a grid.
---@param cols number -- columns in the sprite sheet
---@param rows number -- rows in the sprite sheet
---@param fps number -- animation speed in frames per second
---@return nil
function LParticleSystem:setFlipbook(cols, rows, fps) end

--- Sets the gravity acceleration applied to all active particles each frame.
---@param gx number
---@param gy number
---@return nil
function LParticleSystem:setGravity(gx, gy) end

--- Sets the insert mode: "top", "bottom", or "random".
---@param mode string
---@return nil
function LParticleSystem:setInsertMode(mode) end

--- Sets linear acceleration range.
---@param xmin number
---@param ymin number
---@param xmax number
---@param ymax number
---@return nil
function LParticleSystem:setLinearAcceleration(xmin, ymin, xmax, ymax) end

--- Sets linear damping range.
---@param min number
---@param max number
---@return nil
function LParticleSystem:setLinearDamping(min, max) end

--- Sets the render origin offset.
---@param ox number
---@param oy number
---@return nil
function LParticleSystem:setOffset(ox, oy) end

--- Sets a Lua function called after each update() with all particles that died
---@param fn function
---@return nil
function LParticleSystem:setOnDeathBatch(fn) end

--- Sets min and max particle lifetime in seconds.
---@param min number
---@param max number
---@return nil
function LParticleSystem:setParticleLifetime(min, max) end

--- Sets the emitter world position.
---@param x number
---@param y number
---@return nil
function LParticleSystem:setPosition(x, y) end

--- Sets radial acceleration range.
---@param min number
---@param max number
---@return nil
function LParticleSystem:setRadialAcceleration(min, max) end

--- Sets whether particle rotation follows velocity direction.
---@param v boolean
---@return nil
function LParticleSystem:setRelativeRotation(v) end

--- Sets initial rotation range in radians.
---@param min number
---@param max number
---@return nil
function LParticleSystem:setRotation(min, max) end

--- Sets the particle draw shape.
---@param shape string
---@return nil
function LParticleSystem:setShape(shape) end

--- Sets size variation (0â€“1).
---@param v number
---@return nil
function LParticleSystem:setSizeVariation(v) end

--- Sets size keyframes (varargs: each number is one keyframe).
---@param ... number
---@return nil
function LParticleSystem:setSizes(...) end

--- Sets min/max initial speed.
---@param min number
---@param max number
---@return nil
function LParticleSystem:setSpeed(min, max) end

--- Sets angular velocity range.
---@param min number
---@param max number
---@return nil
function LParticleSystem:setSpin(min, max) end

--- Sets spin variation (0â€“1).
---@param v number
---@return nil
function LParticleSystem:setSpinVariation(v) end

--- Sets emission spread (half-angle cone) in radians.
---@param spread number
---@return nil
function LParticleSystem:setSpread(spread) end

--- Sets tangential acceleration range.
---@param min number
---@param max number
---@return nil
function LParticleSystem:setTangentialAcceleration(min, max) end

--- Starts or restarts particle emission.
---@return nil
function LParticleSystem:start() end

--- Stops particle emission immediately.
---@return nil
function LParticleSystem:stop() end

--- Returns the number of direct child sub-systems attached to this emitter.
---@return number
function LParticleSystem:subSystemCount() end

--- Alias for `drawToImage`. Renders all live particles to a CPU ImageData.
---@param width integer
---@param height integer
---@return ImageData
function LParticleSystem:toImage(width, height) end

--- Returns the type name "ParticleSystem".
---@return string
function LParticleSystem:type() end

--- Returns true if this matches the given type name.
---@param name string
---@return boolean
function LParticleSystem:typeOf(name) end

--- Advances the particle simulation by dt seconds.
---@param dt number
---@return nil
function LParticleSystem:update(dt) end

--- Pre-simulates the particle system for `seconds` so it appears fully
---@param seconds number
---@return nil
function LParticleSystem:warmUp(seconds) end

--- Lua-side wrapper around a [`Trail`] ribbon effect.
---@class LTrail
LTrail = {}

--- Removes all trail points.
---@return nil
function LTrail:clear() end

--- Renders the trail ribbon to a CPU ImageData.
---@param width integer
---@param height integer
---@return ImageData
function LTrail:drawToImage(width, height) end

--- Returns the trail point lifetime in seconds.
---@return number
function LTrail:getLifetime() end

--- Returns the number of active trail points.
---@return number
function LTrail:getPointCount() end

--- Returns the start and end width.
---@return number
---@return number
function LTrail:getWidth() end

--- Appends a new point to the trail head.
---@param x number
---@param y number
---@return nil
function LTrail:pushPoint(x, y) end

--- Sets the colour at the newest end of the trail.
---@param r number
---@param g number
---@param b number
---@param a number
---@return nil
function LTrail:setHeadColor(r, g, b, a) end

--- Sets how long each trail point persists in seconds.
---@param lifetime number
---@return nil
function LTrail:setLifetime(lifetime) end

--- Sets the minimum distance between trail points.
---@param distance number
---@return nil
function LTrail:setMinDistance(distance) end

--- Sets the colour at the oldest end of the trail.
---@param r number
---@param g number
---@param b number
---@param a number
---@return nil
function LTrail:setTailColor(r, g, b, a) end

--- Sets the start and end width of the trail ribbon.
---@param start_width number
---@param end_width? number
---@return nil
function LTrail:setWidth(start_width, end_width) end

--- Returns the type name of this object.
---@return string
function LTrail:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTrail:typeOf(name) end

--- Ages trail points and removes expired ones.
---@param dt number
---@return nil
function LTrail:update(dt) end

--- Creates a new particle system from a TOML config file.
---@param path string
---@return ParticleSystem
lurek.particle.fromTOML = function(path) end

--- Creates a new particle system and stores it in the engine pool.
---@param config? table
---@return ParticleSystem
lurek.particle.newSystem = function(config) end

--- Creates a new trail ribbon effect.
---@param lifetime number
---@param start_width number
---@return Trail
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
---@param x integer
---@param y integer
---@return number
---@return number
function LAIFlowField:getDirection(x, y) end

--- Returns the BFS distance to the goal (1-based coordinates).
---@param x integer
---@param y integer
---@return number
function LAIFlowField:getDistance(x, y) end

--- Returns the goal cell (1-based coordinates) or nil if unset.
---@return nil
function LAIFlowField:getGoal() end

--- Returns the flow field grid height in cells.
---@return number
function LAIFlowField:getHeight() end

--- Returns the flow field grid width in cells.
---@return number
function LAIFlowField:getWidth() end

--- Returns true if a goal has been set.
---@return boolean
function LAIFlowField:hasGoal() end

--- Sets the goal cell and triggers BFS recomputation (1-based coordinates).
---@param x integer
---@param y integer
---@return nil
function LAIFlowField:setGoal(x, y) end

--- Returns the type name of this object.
---@return string
function LAIFlowField:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAIFlowField:typeOf(name) end

--- Lua-side wrapper around a [`FlowField`].
---@class LFlowField
LFlowField = {}

--- Computes the flow field toward a single target (1-based coordinates).
---@param tx integer
---@param ty integer
---@param unitSize? integer
---@return nil
function LFlowField:calculate(tx, ty, unitSize) end

--- Computes the flow field toward multiple targets (1-based coordinates).
---@param targets table
---@param unitSize? integer
---@return nil
function LFlowField:calculateMulti(targets, unitSize) end

--- Returns the integrated cost to the nearest target (1-based coordinates).
---@param x integer
---@param y integer
---@return number
function LFlowField:getCostToTarget(x, y) end

--- Returns the normalised direction vector at a cell (1-based coordinates).
---@param x integer
---@param y integer
---@return number
---@return number
function LFlowField:getDirection(x, y) end

--- Returns the flow direction as an angle in radians (1-based coordinates).
---@param x integer
---@param y integer
---@return number
function LFlowField:getDirectionAngle(x, y) end

--- Returns the target cells from the most recent computation (1-based coordinates).
---@return table
function LFlowField:getTargets() end

--- Returns true if the flow field has been computed at least once.
---@return boolean
function LFlowField:isCalculated() end

--- Converts a world-space position into a velocity vector via the flow field.
---@param wx number
---@param wy number
---@param speed number
---@param tw number
---@param th number
---@return number
---@return number
function LFlowField:steer(wx, wy, speed, tw, th) end

--- Returns the type name of this object.
---@return string
function LFlowField:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LFlowField:typeOf(name) end

--- Lua-side wrapper around a [`HexGrid`].
---@class LHexGrid
LHexGrid = {}

--- Hex-distance between two cells.
---@param col1 integer
---@param row1 integer
---@param col2 integer
---@param row2 integer
---@return number
function LHexGrid:distance(col1, row1, col2, row2) end

--- Returns all cells visible from origin within max_range (1-based coordinates).
---@param col integer
---@param row integer
---@param max_range integer
---@return table
function LHexGrid:fieldOfView(col, row, max_range) end

--- Find A* path between two cells (1-based coordinates).
---@param from_col integer
---@param from_row integer
---@param to_col integer
---@param to_row integer
---@return table
function LHexGrid:findPath(from_col, from_row, to_col, to_row) end

--- Returns true if a cell is blocked (1-based coordinates).
---@param col integer
---@param row integer
---@return boolean
function LHexGrid:isBlocked(col, row) end

--- Returns true if there is an unobstructed line between two cells (1-based).
---@param from_col integer
---@param from_row integer
---@param to_col integer
---@param to_row integer
---@return boolean
function LHexGrid:lineOfSight(from_col, from_row, to_col, to_row) end

--- Returns all cells reachable from origin within movement budget (1-based).
---@param col integer
---@param row integer
---@param budget number
---@return table
function LHexGrid:rangeOfMovement(col, row, budget) end

--- Mark/unmark a cell as blocked (1-based coordinates).
---@param col integer
---@param row integer
---@param blocked boolean
---@return nil
function LHexGrid:setBlocked(col, row, blocked) end

--- Set movement cost for a cell (1-based coordinates).
---@param col integer
---@param row integer
---@param cost number
---@return nil
function LHexGrid:setCost(col, row, cost) end

--- Returns the type name of this object.
---@return string
function LHexGrid:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LHexGrid:typeOf(name) end

--- Lua-side wrapper around a [`JpsGrid`].
---@class LJpsGrid
LJpsGrid = {}

--- Find a JPS path between two cells (1-based coordinates).
---@param from_x integer
---@param from_y integer
---@param to_x integer
---@param to_y integer
---@return table
function LJpsGrid:findPath(from_x, from_y, to_x, to_y) end

--- Returns true if the cell is blocked (1-based coordinates).
---@param x integer
---@param y integer
---@return boolean
function LJpsGrid:isBlocked(x, y) end

--- Mark/unmark a cell as blocked (1-based coordinates).
---@param x integer
---@param y integer
---@param blocked boolean
---@return nil
function LJpsGrid:setBlocked(x, y, blocked) end

--- Returns the type name of this object.
---@return string
function LJpsGrid:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LJpsGrid:typeOf(name) end

--- Lua-side wrapper around a [`NavGrid`] with optional HPA★ abstract graph.
---@class LNavGrid
LNavGrid = {}

--- Clears all pending dirty rectangles.
---@return nil
function LNavGrid:clearDirty() end

--- Sets every cell to the given cost.
---@param cost integer
---@return nil
function LNavGrid:fill(cost) end

--- Sets all cells in a rectangle to the given cost (1-based coordinates).
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param cost integer
---@return nil
function LNavGrid:fillRect(x, y, w, h, cost) end

--- Returns the current HPA★ chunk size.
---@return number
function LNavGrid:getChunkSize() end

--- Returns the traversal cost of a cell (1-based coordinates).
---@param x integer
---@param y integer
---@return number
function LNavGrid:getCost(x, y) end

--- Returns the current diagonal movement mode as a string.
---@return string
function LNavGrid:getDiagonalMode() end

--- Returns the grid dimensions as width, height.
---@return integer
---@return integer
function LNavGrid:getDimensions() end

--- Returns the grid height in cells.
---@return number
function LNavGrid:getHeight() end

--- Returns the grid width in cells.
---@return number
function LNavGrid:getWidth() end

--- Returns true if the cell is blocked (1-based coordinates).
---@param x integer
---@param y integer
---@return boolean
function LNavGrid:isBlocked(x, y) end

--- Returns true if a unit footprint is fully walkable (1-based coordinates).
---@param x integer
---@param y integer
---@param unitSize? integer
---@return boolean
function LNavGrid:isWalkable(x, y, unitSize) end

--- Overwrites the grid from a raw byte string (row-major, one byte per cell).
---@param data string
---@return nil
function LNavGrid:loadFromString(data) end

--- Rebuilds the HPA★ abstract graph from the current grid state.
---@return nil
function LNavGrid:rebuildAbstract() end

--- Exports the cost grid as a byte string (row-major, one byte per cell).
---@return string
function LNavGrid:saveToString() end

--- Marks a cell as blocked or unblocked (1-based coordinates).
---@param x integer
---@param y integer
---@param blocked boolean
---@return nil
function LNavGrid:setBlocked(x, y, blocked) end

--- Sets the HPA★ chunk size.
---@param size integer
---@return nil
function LNavGrid:setChunkSize(size) end

--- Sets the traversal cost of a cell (1-based coordinates).
---@param x integer
---@param y integer
---@param cost integer
---@return nil
function LNavGrid:setCost(x, y, cost) end

--- Sets the diagonal movement mode.
---@param mode string
---@return nil
function LNavGrid:setDiagonalMode(mode) end

--- Records a dirty rectangle for incremental HPA★ updates (1-based coordinates).
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@return nil
function LNavGrid:setDirty(x, y, w, h) end

--- Returns the type name of this object.
---@return string
function LNavGrid:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LNavGrid:typeOf(name) end

--- Lua-side wrapper around a [`PathGrid`] (A★ weighted grid with per-cell cost).
---@class LPathGrid
LPathGrid = {}

--- Finds an A★ path returning world-space waypoints (1-based coordinates).
---@param sx integer
---@param sy integer
---@param gx integer
---@param gy integer
---@return table
function LPathGrid:findPath(sx, sy, gx, gy) end

--- Finds a smoothed A★ path with string-pulling (1-based coordinates).
---@param sx integer
---@param sy integer
---@param gx integer
---@param gy integer
---@return table
function LPathGrid:findPathSmoothed(sx, sy, gx, gy) end

--- Returns the world-space size of each cell.
---@return number
function LPathGrid:getCellSize() end

--- Returns the cost multiplier for a cell (1-based coordinates).
---@param x integer
---@param y integer
---@return number
function LPathGrid:getCost(x, y) end

--- Returns the grid height in cells.
---@return number
function LPathGrid:getHeight() end

--- Returns the grid width in cells.
---@return number
function LPathGrid:getWidth() end

--- Returns true if a cell is walkable (1-based coordinates).
---@param x integer
---@param y integer
---@return boolean
function LPathGrid:isWalkable(x, y) end

--- Sets the cost multiplier for a cell (1-based coordinates).
---@param x integer
---@param y integer
---@param cost number
---@return nil
function LPathGrid:setCost(x, y, cost) end

--- Sets the walkability of a cell (1-based coordinates).
---@param x integer
---@param y integer
---@param walkable boolean
---@return nil
function LPathGrid:setWalkable(x, y, walkable) end

--- Returns the type name of this object.
---@return string
function LPathGrid:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LPathGrid:typeOf(name) end

--- Lua-side wrapper around a [`UnitPathfinder`].
---@class LUnitPathfinder
LUnitPathfinder = {}

--- Removes all cached path results.
---@return nil
function LUnitPathfinder:clearCache() end

--- Finds the nearest walkable cell within a radius (1-based coordinates).
---@param x integer
---@param y integer
---@param maxRadius integer
---@param unitSize? integer
---@return nil
function LUnitPathfinder:findNearestWalkable(x, y, maxRadius, unitSize) end

--- Finds a partial path with a node expansion limit (1-based coordinates).
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param maxNodes integer
---@param unitSize? integer
---@return table
---@return boolean
function LUnitPathfinder:findPartialPath(x1, y1, x2, y2, maxNodes, unitSize) end

--- Finds an A★ path between two cells (1-based coordinates).
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param unitSize? integer
---@return table
function LUnitPathfinder:findPath(x1, y1, x2, y2, unitSize) end

--- Finds a path using bidirectional A★, expanding from start and goal simultaneously
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param unitSize? integer
---@param maxNodes? integer
---@return nil
function LUnitPathfinder:findPathBidirectional(x1, y1, x2, y2, unitSize, maxNodes) end

--- Finds a Theta★ smoothed path between two cells (1-based coordinates).
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param unitSize? integer
---@return table
function LUnitPathfinder:findPathSmooth(x1, y1, x2, y2, unitSize) end

--- Returns the number of entries in the path cache.
---@return number
function LUnitPathfinder:getCacheSize() end

--- Returns the sum of grid traversal costs along a path.
---@param path table
---@return number
function LUnitPathfinder:getPathCost(path) end

--- Returns the euclidean length of a path table.
---@param path table
---@return number
function LUnitPathfinder:getPathLength(path) end

--- Returns the octile heuristic distance between two cells (1-based coordinates).
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@return number
function LUnitPathfinder:heuristicDistance(x1, y1, x2, y2) end

--- Returns true if path result caching is enabled.
---@return boolean
function LUnitPathfinder:isCacheEnabled() end

--- Returns true if a path exists between two cells (1-based coordinates).
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param unitSize? integer
---@return boolean
function LUnitPathfinder:isReachable(x1, y1, x2, y2, unitSize) end

--- Returns true if there is a clear line of sight between two cells (1-based coordinates).
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param unitSize? integer
---@return boolean
function LUnitPathfinder:lineOfSight(x1, y1, x2, y2, unitSize) end

--- Enables or disables path result caching.
---@param enabled boolean
---@return nil
function LUnitPathfinder:setCacheEnabled(enabled) end

--- Sets the maximum number of cached path entries.
---@param n integer
---@return nil
function LUnitPathfinder:setCacheMaxSize(n) end

--- Returns the type name of this object.
---@return string
function LUnitPathfinder:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LUnitPathfinder:typeOf(name) end

--- Returns the background pathfinding thread count (currently always 0).
---@return number
lurek.pathfind.getThreadCount = function() end

--- Creates a new FlowField backed by a NavGrid.
---@param grid NavGrid
---@return FlowField
lurek.pathfind.newFlowField = function(grid) end

--- Creates a hex grid for pathfinding, LOS, FOV, and range queries.
---@param width integer
---@param height integer
---@param layout? string
---@return HexGrid
lurek.pathfind.newHexGrid = function(width, height, layout) end

--- Creates a uniform-cost grid optimised for Jump Point Search (orthogonal + diagonal).
---@param width integer
---@param height integer
---@return JpsGrid
lurek.pathfind.newJpsGrid = function(width, height) end

--- Creates a new NavGrid with all cells walkable.
---@param width integer
---@param height integer
---@return NavGrid
lurek.pathfind.newNavGrid = function(width, height) end

--- Builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable).
---@param tilemap TileMap
---@param layer_index integer
---@param blocked_gids table
---@return NavGrid
lurek.pathfind.newNavGridFromTileMap = function(tilemap, layer_index, blocked_gids) end

--- Creates a new BFS flow field from a PathGrid.
---@param grid PathGrid
---@return AiFlowField
lurek.pathfind.newPathFlowField = function(grid) end

--- Creates a new PathGrid with per-cell cost and walkability.
---@param w integer
---@param h integer
---@param cellSize number
---@return PathGrid
lurek.pathfind.newPathGrid = function(w, h, cellSize) end

--- Creates a new UnitPathfinder backed by a NavGrid.
---@param grid NavGrid
---@return UnitPathfinder
lurek.pathfind.newPathfinder = function(grid) end

--- Computes a Dijkstra range-of-movement map from an origin within a movement budget.
---@param opts table
---@return table
lurek.pathfind.rangeMap = function(opts) end

--- Sets the background pathfinding thread count (currently a no-op).
---@param count integer
---@return nil
lurek.pathfind.setThreadCount = function(count) end

---@class lurek.patterns
lurek.patterns = {}

--- Lua wrapper for the Blackboard pattern.
---@class LBlackboard
LBlackboard = {}

--- Removes a fact from the blackboard.
---@param key string
---@return nil
function LBlackboard:clear(key) end

--- Clears all facts from the blackboard.
---@return nil
function LBlackboard:clearAll() end

--- Gets a fact from the blackboard. Returns nil if not set.
---@param key string
---@return string
function LBlackboard:get(key) end

--- Returns the monotonic revision counter (incremented on every write).
---@return number
function LBlackboard:getRevision() end

--- Returns true when the key has a non-nil value.
---@param key string
---@return boolean
function LBlackboard:has(key) end

--- Returns all set fact keys as a table.
---@return table
function LBlackboard:keys() end

--- Sets a fact on the blackboard. Accepts boolean, number, or string values.
---@param key string
---@param value any
---@return nil
function LBlackboard:set(key, value) end

--- Returns all facts as a flat keyâ†’value table.
---@return table
function LBlackboard:snapshot() end

--- Removes a watcher subscription by id.
---@param id integer
---@return nil
function LBlackboard:unwatch(id) end

--- Subscribes to changes on a specific key (or "*" for all changes).
---@param key string
---@param callback function
---@return number
function LBlackboard:watch(key, callback) end

--- Lua wrapper for the CommandStack pattern.
---@class LCommandStack
LCommandStack = {}

--- Returns true if there is a command available to redo.
---@return boolean
function LCommandStack:canRedo() end

--- Returns true if the most recent command can be undone.
---@return boolean
function LCommandStack:canUndo() end

--- Clears all command history, releasing Lua registry values.
---@return nil
function LCommandStack:clearAll() end

--- Executes a named command and records it in undo/redo history.
---@param name string
---@param exec_fn function
---@param undo_fn? function
---@return nil
function LCommandStack:execute(name, exec_fn, undo_fn) end

--- Returns the name of the most recently executed command, or nil.
---@return string
function LCommandStack:getCurrentName() end

--- Returns the total number of recorded commands (undo + redo).
---@return number
function LCommandStack:getHistorySize() end

--- Re-executes the next undone command. Returns true if successful.
---@return boolean
function LCommandStack:redo() end

--- Undoes the most recent command. Returns true if successful.
---@return boolean
function LCommandStack:undo() end

--- Lua wrapper for the Debounce pattern.
---@class LDebounce
LDebounce = {}

--- Cancels the pending trigger without firing.
---@return nil
function LDebounce:cancel() end

--- Returns the total number of times this debounce has fired.
---@return number
function LDebounce:getFireCount() end

--- Returns true when a trigger is pending.
---@return boolean
function LDebounce:isPending() end

--- Sets the callback invoked when the debounce fires.
---@param fn function
---@return nil
function LDebounce:onFire(fn) end

--- Records an input event, resetting the idle timer.
---@return nil
function LDebounce:trigger() end

--- Advances the idle timer by dt seconds; fires the callback if idle wait expired.
---@param dt number
---@return boolean
function LDebounce:update(dt) end

--- Lua wrapper for the EventBus pattern.
---@class LEventBus
LEventBus = {}

--- Removes all listeners for a specific event.
---@param event string
---@return nil
function LEventBus:clear(event) end

--- Removes all listeners on this EventBus.
---@return nil
function LEventBus:clearAll() end

--- Dispatches an event, calling all registered listeners in priority order.
---@param event string
---@param ... any
---@return nil
function LEventBus:emit(event, ...) end

--- Returns all event names that have at least one listener.
---@return table
function LEventBus:getEvents() end

--- Returns the number of listeners registered for an event.
---@param event string
---@return number
function LEventBus:getListenerCount(event) end

--- Removes a previously registered event listener by subscription ID.
---@param id integer
---@return nil
function LEventBus:off(id) end

--- Registers a listener callback for an event.
---@param event string
---@param callback function
---@param priority? integer
---@return number
function LEventBus:on(event, callback, priority) end

--- Lua wrapper for the Factory pattern.
---@class LFactory
LFactory = {}

--- Registers an alias pointing to an existing canonical type name.
---@param alias string
---@param canonical string
---@return nil
function LFactory:alias(alias, canonical) end

--- Removes all registered type constructors and aliases.
---@return nil
function LFactory:clearAll() end

--- Creates an instance of the named type by invoking its constructor.
---@param type_name string
---@param ... any
---@return table
function LFactory:create(type_name, ...) end

--- Returns a table of all registered type names.
---@return table
function LFactory:getTypes() end

--- Returns true if the named type (or alias) is registered.
---@param type_name string
---@return boolean
function LFactory:has(type_name) end

--- Registers a named type constructor function.
---@param type_name string
---@param ctor function
---@return nil
function LFactory:register(type_name, ctor) end

--- Unregisters a type constructor (and any aliases pointing to it).
---@param type_name string
---@return nil
function LFactory:remove(type_name) end

--- Lua wrapper for the Funnel (event aggregator) pattern.
---@class LFunnel
LFunnel = {}

--- Discards all buffered entries without flushing.
---@return nil
function LFunnel:discard() end

--- Manually flushes all pending entries, invoking the onFlush callback.
---@return nil
function LFunnel:flush() end

--- Returns the total number of flushes performed.
---@return number
function LFunnel:getFlushCount() end

--- Sets a callback invoked when the funnel flushes. Receives a table of {tag, value} entries.
---@param fn function
---@return nil
function LFunnel:onFlush(fn) end

--- Returns the number of buffered entries not yet flushed.
---@return number
function LFunnel:pendingCount() end

--- Adds an event to the funnel. Immediately flushes if max_entries reached or window is 0.
---@param tag string
---@param value? number
---@return nil
function LFunnel:push(tag, value) end

--- Advances the window timer by dt seconds; flushes when window expires.
---@param dt number
---@return boolean
function LFunnel:update(dt) end

--- Lua wrapper for an ordered, resizable list.
---@class LList
LList = {}

--- Appends a value to the end of the list.
---@param value any
---@return nil
function LList:add(value) end

--- Removes all values from the list.
---@return nil
function LList:clear() end

--- Returns true if the list contains a value equal to the given Lua value (string/number/boolean).
---@param value any
---@return boolean
function LList:contains(value) end

--- Returns the value at a 1-based index, or nil.
---@param index integer
---@return table
function LList:get(index) end

--- Returns true if the list is empty.
---@return boolean
function LList:isEmpty() end

--- Returns the number of items in the list.
---@return number
function LList:len() end

--- Removes and returns the value at a 1-based index.
---@param index integer
---@return table
function LList:remove(index) end

--- Replaces the value at a 1-based index.
---@param index integer
---@param value any
---@return nil
function LList:set(index, value) end

--- Returns all items as a Lua table.
---@return table
function LList:toArray() end

--- Lua wrapper for the Mediator pattern.
---@class LMediator
LMediator = {}

--- Dispatches a message to all handlers across all channels.
---@param ... any
---@return nil
function LMediator:broadcast(...) end

--- Returns all registered channel names.
---@return table
function LMediator:channels() end

--- Removes all channels and handlers.
---@return nil
function LMediator:clear() end

--- Returns the number of handlers on a channel.
---@param channel string
---@return number
function LMediator:handlerCount(channel) end

--- Unregisters a handler by ID.
---@param channel string
---@param id integer
---@return nil
function LMediator:off(channel, id) end

--- Registers a handler callback on a channel; returns handler ID.
---@param channel string
---@param callback function
---@return number
function LMediator:on(channel, callback) end

--- Removes a channel and all its handlers.
---@param channel string
---@return nil
function LMediator:removeChannel(channel) end

--- Dispatches a message to all handlers on a channel.
---@param channel string
---@param ... any
---@return nil
function LMediator:send(channel, ...) end

--- Lua wrapper for the ObjectPool pattern.
---@class LObjectPool
LObjectPool = {}

--- Acquires an available object from the pool; returns nil if empty.
---@return string
function LObjectPool:acquire() end

--- Inserts a pre-built object into the available pool.
---@param value any
---@return nil
function LObjectPool:add(value) end

--- Clears all objects from the pool, releasing Lua registry values.
---@return nil
function LObjectPool:clearAll() end

--- Returns the number of currently active (acquired) objects.
---@return number
function LObjectPool:getActiveCount() end

--- Returns the number of available (idle) objects in the pool.
---@return number
function LObjectPool:getAvailableCount() end

--- Returns the total number of tracked objects (active + available).
---@return number
function LObjectPool:getTotalCount() end

--- Returns an object to the available pool.
---@param value any
---@return nil
function LObjectPool:release(value) end

--- Lua wrapper for the Observer pattern.
---@class LObserver
LObserver = {}

--- Gets a property value, or nil if not set.
---@param key string
---@return string
function LObserver:get(key) end

--- Returns the total number of active subscriptions.
---@return number
function LObserver:getCount() end

--- Sets a property value and fires subscribed watchers.
---@param key string
---@param value any
---@return nil
function LObserver:set(key, value) end

--- Subscribes to changes on a property key (or "*" for all).
---@param key string
---@param callback function
---@param once? boolean
---@return number
function LObserver:subscribe(key, callback, once) end

--- Removes a subscription by id.
---@param id integer
---@return nil
function LObserver:unsubscribe(id) end

--- Lua wrapper for the PriorityQueue pattern.
---@class LPriorityQueue
LPriorityQueue = {}

--- Removes all items from the queue.
---@return nil
function LPriorityQueue:clearAll() end

--- Returns true when the queue has no items.
---@return boolean
function LPriorityQueue:isEmpty() end

--- Returns the number of items in the queue.
---@return number
function LPriorityQueue:len() end

--- Returns the highest-priority item without removing it, or nil if empty.
---@return string
function LPriorityQueue:peek() end

--- Removes and returns the highest-priority item, or nil if empty.
---@return string
function LPriorityQueue:pop() end

--- Inserts an item with a priority. Higher priorities are dequeued first.
---@param priority integer
---@param value any
---@param label? string
---@return number
function LPriorityQueue:push(priority, value, label) end

--- Lua wrapper for a FIFO queue.
---@class LQueue
LQueue = {}

--- Removes all values from the queue.
---@return nil
function LQueue:clear() end

--- Removes and returns the front value, or nil if empty.
---@return table
function LQueue:dequeue() end

--- Adds a value to the back of the queue. Returns false if capacity is full.
---@param value any
---@return boolean
function LQueue:enqueue(value) end

--- Returns the front value without removing it, or nil if empty.
---@return table
function LQueue:front() end

--- Returns true if the queue is empty.
---@return boolean
function LQueue:isEmpty() end

--- Returns true if the queue is at its capacity limit.
---@return boolean
function LQueue:isFull() end

--- Returns the number of items in the queue.
---@return number
function LQueue:len() end

--- Returns all items as a Lua table (front to back).
---@return table
function LQueue:toArray() end

--- Lua wrapper for the RelationshipManager pattern.
---@class LRelationshipManager
LRelationshipManager = {}

--- Adjusts the numeric relationship value by a delta.
---@param a integer
---@param b integer
---@param delta number
---@return nil
function LRelationshipManager:adjustValue(a, b, delta) end

--- Defines a relationship type with ordered levels.
---@param name string
---@param levels table
---@param default_level? string
---@return nil
function LRelationshipManager:defineType(name, levels, default_level) end

--- Returns the named level for a typed relationship, or nil.
---@param a integer
---@param b integer
---@param type_name string
---@return string
function LRelationshipManager:getLevel(a, b, type_name) end

--- Returns the numeric relationship value between two entities (default 0.0).
---@param a integer
---@param b integer
---@return number
function LRelationshipManager:getValue(a, b) end

--- Returns the total number of stored relationship pairs.
---@return number
function LRelationshipManager:pairCount() end

--- Removes all relationship data between two entities.
---@param a integer
---@param b integer
---@return nil
function LRelationshipManager:removePair(a, b) end

--- Removes a relationship type definition.
---@param name string
---@return nil
function LRelationshipManager:removeType(name) end

--- Sets a named level for a typed relationship between two entities.
---@param a integer
---@param b integer
---@param type_name string
---@param level string
---@return boolean
function LRelationshipManager:setLevel(a, b, type_name, level) end

--- Sets the numeric relationship value between two entities.
---@param a integer
---@param b integer
---@param value number
---@return nil
function LRelationshipManager:setValue(a, b, value) end

--- Returns all defined relationship type names.
---@return table
function LRelationshipManager:typeNames() end

--- Lua wrapper for the Ring (circular buffer) pattern.
---@class LRing
LRing = {}

--- Returns the average of all numeric values, or 0 if empty.
---@return number
function LRing:average() end

--- Removes all entries from the ring.
---@return nil
function LRing:clear() end

--- Returns true when the ring is at capacity.
---@return boolean
function LRing:isFull() end

--- Returns the most recently pushed entry, or nil.
---@return table
function LRing:latest() end

--- Returns the number of entries currently in the ring.
---@return number
function LRing:len() end

--- Pushes a value (number or string) with an optional tag. Overwrites oldest on overflow.
---@param value any
---@param tag? string
---@return number
function LRing:push(value, tag) end

--- Returns the sum of all numeric values in the ring.
---@return number
function LRing:sum() end

--- Returns all entries (oldest first) as an array of {id, tag, value?, text?} tables.
---@return table
function LRing:toArray() end

--- Lua wrapper for the ServiceLocator pattern.
---@class LServiceLocator
LServiceLocator = {}

--- Removes all registered services.
---@return nil
function LServiceLocator:clearAll() end

--- Returns a table of all registered service names.
---@return table
function LServiceLocator:getServices() end

--- Returns true if a service with the given name is registered.
---@param name string
---@return boolean
function LServiceLocator:has(name) end

--- Retrieves a registered service by name; returns nil if not found.
---@param name string
---@return string
function LServiceLocator:locate(name) end

--- Registers a named service with an associated Lua value.
---@param name string
---@param value any
---@return nil
function LServiceLocator:provide(name, value) end

--- Unregisters and removes a named service.
---@param name string
---@return nil
function LServiceLocator:remove(name) end

--- Lua wrapper for an unordered set. Values are keyed by their string representation.
---@class LSet
LSet = {}

--- Adds a string key to the set. Returns true if it was not already present.
---@param key string
---@return boolean
function LSet:add(key) end

--- Removes all keys from the set.
---@return nil
function LSet:clear() end

--- Returns true if the key is in the set.
---@param key string
---@return boolean
function LSet:has(key) end

--- Returns the intersection of this set and another as a new Set.
---@param other Set
---@return Set
function LSet:intersection(other) end

--- Returns true if the set is empty.
---@return boolean
function LSet:isEmpty() end

--- Returns the number of distinct keys in the set.
---@return number
function LSet:len() end

--- Removes a key from the set. Returns true if it was present.
---@param key string
---@return boolean
function LSet:remove(key) end

--- Returns all keys as a Lua table (unordered).
---@return table
function LSet:toArray() end

--- Returns the union of this set and another as a new Set.
---@param other Set
---@return Set
function LSet:union(other) end

--- Lua wrapper for the SimpleState finite state machine pattern.
---@class LSimpleState
LSimpleState = {}

--- Registers a named state with optional enter, exit, and update callbacks.
---@param name string
---@param callbacks? table
---@return nil
function LSimpleState:addState(name, callbacks) end

--- Removes all states and callbacks from this state machine.
---@return nil
function LSimpleState:clearAll() end

--- Returns the name of the current state, or nil if none is active.
---@return string
function LSimpleState:getCurrent() end

--- Returns a table of all registered state names.
---@return table
function LSimpleState:getStates() end

--- Returns true if a state with the given name is registered.
---@param name string
---@return boolean
function LSimpleState:hasState(name) end

--- Transitions to a named state, calling exit/enter callbacks as needed.
---@param name string
---@return boolean
function LSimpleState:transitionTo(name) end

--- Calls the update callback of the current state with the given delta time.
---@param dt number
---@return nil
function LSimpleState:update(dt) end

--- Lua wrapper for a LIFO stack.
---@class LStack
LStack = {}

--- Removes all values from the stack.
---@return nil
function LStack:clear() end

--- Returns true if the stack is empty.
---@return boolean
function LStack:isEmpty() end

--- Returns true if the stack is at its capacity limit.
---@return boolean
function LStack:isFull() end

--- Returns the number of items on the stack.
---@return number
function LStack:len() end

--- Returns the top value without removing it, or nil if empty.
---@return table
function LStack:peek() end

--- Removes and returns the top value, or nil if empty.
---@return table
function LStack:pop() end

--- Pushes a value onto the stack. Returns false if capacity is full.
---@param value any
---@return boolean
function LStack:push(value) end

--- Returns all items as a Lua table (bottom to top).
---@return table
function LStack:toArray() end

--- Lua wrapper for the Strategy pattern.
---@class LStrategy
LStrategy = {}

--- Removes all strategies and clears the active selection.
---@return nil
function LStrategy:clear() end

--- Calls the currently active strategy function with the given arguments.
---@param ... any
---@return table
function LStrategy:execute(...) end

--- Returns the name of the active strategy, or nil.
---@return string
function LStrategy:getCurrent() end

--- Returns true if a strategy with this name is registered.
---@param name string
---@return boolean
function LStrategy:has(name) end

--- Returns all registered strategy names.
---@return table
function LStrategy:names() end

--- Registers a named strategy function.
---@param name string
---@param callback function
---@return nil
function LStrategy:register(name, callback) end

--- Removes a strategy by name.
---@param name string
---@return boolean
function LStrategy:remove(name) end

--- Sets the active strategy by name. Returns false if not registered.
---@param name string
---@return boolean
function LStrategy:set(name) end

--- Lua wrapper for the Throttle pattern.
---@class LThrottle
LThrottle = {}

--- Returns the total number of times this throttle has fired.
---@return number
function LThrottle:getFireCount() end

--- Returns the normalised progress through the current interval [0, 1].
---@return number
function LThrottle:getProgress() end

--- Sets the callback invoked when the throttle fires.
---@param fn function
---@return nil
function LThrottle:onFire(fn) end

--- Resets the elapsed counter without firing.
---@return nil
function LThrottle:reset() end

--- Enables or disables the throttle.
---@param enabled boolean
---@return nil
function LThrottle:setEnabled(enabled) end

--- Advances the timer by dt seconds; fires the callback if the interval elapsed.
---@param dt number
---@return boolean
function LThrottle:update(dt) end

--- Creates a new Blackboard shared key-value store.
---@param name? string
---@return Blackboard
lurek.patterns.newBlackboard = function(name) end

--- Creates a new CommandStack instance.
---@param max_size? integer
---@return CommandStack
lurek.patterns.newCommandStack = function(max_size) end

--- Creates a trailing-edge debounce that fires after the input stream is idle for wait seconds.
---@param wait number
---@return Debounce
lurek.patterns.newDebounce = function(wait) end

--- Creates a new EventBus instance.
---@param name? string
---@return LEventBus
lurek.patterns.newEventBus = function(name) end

--- Creates a new Factory instance.
---@return Factory
lurek.patterns.newFactory = function() end

--- Creates a time-windowed event aggregator. window=0 means flush on every push.
---@param window number
---@param max_entries? integer
---@param name? string
---@return Funnel
lurek.patterns.newFunnel = function(window, max_entries, name) end

--- Creates an ordered, resizable list.
---@return List
lurek.patterns.newList = function() end

--- Creates a new named-channel message broker.
---@return Mediator
lurek.patterns.newMediator = function() end

--- Creates a new ObjectPool instance.
---@return ObjectPool
lurek.patterns.newObjectPool = function() end

--- Creates a new reactive property Observer.
---@param name? string
---@return Observer
lurek.patterns.newObserver = function(name) end

--- Creates a stable priority-ordered task queue.
---@param name? string
---@return PriorityQueue
lurek.patterns.newPriorityQueue = function(name) end

--- Creates a FIFO queue. capacity=0 means unlimited.
---@param capacity? integer
---@return Queue
lurek.patterns.newQueue = function(capacity) end

--- Creates a new entity relationship manager.
---@return RelationshipManager
lurek.patterns.newRelationshipManager = function() end

--- Creates a fixed-capacity circular history buffer.
---@param capacity integer
---@param name? string
---@return Ring
lurek.patterns.newRing = function(capacity, name) end

--- Creates a new ServiceLocator instance.
---@return ServiceLocator
lurek.patterns.newServiceLocator = function() end

--- Creates an unordered set that rejects duplicate values (by string key).
---@return Set
lurek.patterns.newSet = function() end

--- Creates a new SimpleState finite state machine instance.
---@return SimpleState
lurek.patterns.newSimpleState = function() end

--- Creates a LIFO stack. capacity=0 means unlimited.
---@param capacity? integer
---@return LStack
lurek.patterns.newStack = function(capacity) end

--- Creates a new strategy registry.
---@return Strategy
lurek.patterns.newStrategy = function() end

--- Creates a leading-edge rate limiter that fires at most once per interval seconds.
---@param interval number
---@return Throttle
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
---@param impulse number
---@return nil
function LBody:applyAngularImpulse(impulse) end

--- Applies a continuous force to the body.
---@param fx number
---@param fy number
---@return nil
function LBody:applyForce(fx, fy) end

--- Applies a force at a specific world-space point.
---@param fx number
---@param fy number
---@param px number
---@param py number
---@return nil
function LBody:applyForceAtPoint(fx, fy, px, py) end

--- Applies a linear impulse to the body.
---@param ix number
---@param iy number
---@return nil
function LBody:applyImpulse(ix, iy) end

--- Applies a torque (rotational force).
---@param torque number
---@return nil
function LBody:applyTorque(torque) end

--- Removes this body from the world.
---@return nil
function LBody:destroy() end

--- Returns the body angle in radians.
---@return number
function LBody:getAngle() end

--- Returns the angular damping coefficient.
---@return number
function LBody:getAngularDamping() end

--- Returns the angular velocity in radians/s.
---@return number
function LBody:getAngularVelocity() end

--- Returns the body friction coefficient.
---@return number
function LBody:getFriction() end

--- Returns the per-body gravity multiplier.
---@return number
function LBody:getGravityScale() end

--- Returns the height of this body's primary collider shape in world units.
---@return number
function LBody:getHeight() end

--- Returns the body's integer ID.
---@return number
function LBody:getId() end

--- Returns the collision layer bitmask.
---@return number
function LBody:getLayer() end

--- Returns the linear damping coefficient.
---@return number
function LBody:getLinearDamping() end

--- Returns the collision mask bitmask.
---@return number
function LBody:getMask() end

--- Returns the body mass in kilograms used for force and impulse calculations.
---@return number
function LBody:getMass() end

--- Returns the body position (x, y).
---@return number
---@return number
function LBody:getPosition() end

--- Returns the body restitution (bounciness).
---@return number
function LBody:getRestitution() end

--- Returns the body type as a string.
---@return string
function LBody:getType() end

--- Returns the body velocity (vx, vy).
---@return number
---@return number
function LBody:getVelocity() end

--- Returns the width of this body's primary collider shape in world units.
---@return number
function LBody:getWidth() end

--- Returns the body X position.
---@return number
function LBody:getX() end

--- Returns the body Y position.
---@return number
function LBody:getY() end

--- Returns whether CCD is enabled.
---@return boolean
function LBody:isBullet() end

--- Returns whether rotation is locked.
---@return boolean
function LBody:isFixedRotation() end

--- Returns true if this body is currently sleeping (inactive).
---@return boolean
function LBody:isSleeping() end

--- Returns whether the body can sleep.
---@return boolean
function LBody:isSleepingAllowed() end

--- Sets the body angle in radians.
---@param angle number
---@return nil
function LBody:setAngle(angle) end

--- Sets the angular damping coefficient.
---@param damping number
---@return nil
function LBody:setAngularDamping(damping) end

--- Sets the angular velocity.
---@param omega number
---@return nil
function LBody:setAngularVelocity(omega) end

--- Enables or disables continuous collision detection (CCD) for fast-moving bodies.
---@param bullet boolean
---@return nil
function LBody:setBullet(bullet) end

--- Locks or unlocks rotation.
---@param fixed boolean
---@return nil
function LBody:setFixedRotation(fixed) end

--- Sets the body friction coefficient.
---@param friction number
---@return nil
function LBody:setFriction(friction) end

--- Sets the per-body gravity multiplier.
---@param scale number
---@return nil
function LBody:setGravityScale(scale) end

--- Sets the collision layer bitmask.
---@param layer integer
---@return nil
function LBody:setLayer(layer) end

--- Sets the linear damping coefficient.
---@param damping number
---@return nil
function LBody:setLinearDamping(damping) end

--- Sets the collision mask bitmask.
---@param mask integer
---@return nil
function LBody:setMask(mask) end

--- Sets the body mass; affects how forces and impulses change velocity.
---@param mass number
---@return nil
function LBody:setMass(mass) end

--- Teleports the body to the given world-space position, bypassing collision.
---@param x number
---@param y number
---@return nil
function LBody:setPosition(x, y) end

--- Sets the body restitution (bounciness).
---@param restitution number
---@return nil
function LBody:setRestitution(restitution) end

--- Sets whether the body can sleep.
---@param allowed boolean
---@return nil
function LBody:setSleepingAllowed(allowed) end

--- Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
---@param bodyType string
---@return nil
function LBody:setType(bodyType) end

--- Sets the body's linear velocity in world units per second.
---@param vx number
---@param vy number
---@return nil
function LBody:setVelocity(vx, vy) end

--- Puts this body to sleep immediately.
---@return nil
function LBody:sleep() end

--- Returns the type name of this object.
---@return string
function LBody:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LBody:typeOf(name) end

--- Forcibly wakes up this body.
---@return nil
function LBody:wakeUp() end

--- Lua-side handle to a falling-sand [`CellularWorld`].
---@class LCellular
LCellular = {}

--- Counts cells of the given material type.
---@param cell_type integer
---@return number
function LCellular:countCells(cell_type) end

--- Fills a circle of cells with the given material.
---@param cx_c integer
---@param cy_c integer
---@param r_cells integer
---@param cell_type integer
---@return nil
function LCellular:fillCircle(cx_c, cy_c, r_cells, cell_type) end

--- Fills a rectangular region of cells with the given material.
---@param cx0 integer
---@param cy0 integer
---@param cw integer
---@param ch integer
---@param cell_type integer
---@return nil
function LCellular:fillRect(cx0, cy0, cw, ch, cell_type) end

--- Returns positions of all cells of the given material as an array of `{x, y}` tables.
---@param cell_type integer
---@return table
function LCellular:findCells(cell_type) end

--- Returns the material at `(cx, cy)` as an integer constant.
---@param cx integer
---@param cy integer
---@return number
function LCellular:getCell(cx, cy) end

--- Loads grid data from bytes produced by `toBytes`.
---@param data string
---@return nil
function LCellular:loadFromBytes(data) end

--- Sets the material of a cell.
---@param cx integer
---@param cy integer
---@param cell_type integer
---@return nil
function LCellular:setCell(cx, cy, cell_type) end

--- Advances the simulation by one tick.
---@return nil
function LCellular:step() end

--- Advances the simulation by `n` ticks.
---@param n integer
---@return nil
function LCellular:stepN(n) end

--- Serialises the grid to a byte string.
---@return string
function LCellular:toBytes() end

--- Returns the full grid as an RGBA byte string using the default colour palette.
---@return nil
function LCellular:toImageData() end

--- Returns a sub-region as an RGBA byte string.
---@param cx0 integer
---@param cy0 integer
---@param cw integer
---@param ch integer
---@return string
function LCellular:toImageDataRegion(cx0, cy0, cw, ch) end

--- Returns the type name of this object.
---@return string
function LCellular:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LCellular:typeOf(name) end

--- Lua-side standalone shape object (circle, rectangle, edge, polygon, chain).
---@class LPhysicsShape
LPhysicsShape = {}

--- Releases this shape handle (GC handles cleanup).
---@return nil
function LPhysicsShape:destroy() end

--- Returns the axis-aligned bounding box (x1, y1, x2, y2).
---@return number
---@return number
---@return number
---@return number
function LPhysicsShape:getBoundingBox() end

--- Returns the radius. Only valid for circle shapes.
---@return number
function LPhysicsShape:getRadius() end

--- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
---@return string
function LPhysicsShape:getType() end

--- Sets the density for this shape (used when attaching to a body).
---@param density number
---@return nil
function LPhysicsShape:setDensity(density) end

--- Sets the friction coefficient.
---@param friction number
---@return nil
function LPhysicsShape:setFriction(friction) end

--- Sets the restitution (bounciness) coefficient.
---@param restitution number
---@return nil
function LPhysicsShape:setRestitution(restitution) end

--- Sets whether this shape is a sensor (non-colliding trigger).
---@param sensor boolean
---@return nil
function LPhysicsShape:setSensor(sensor) end

--- Returns the type name of this object.
---@return string
function LPhysicsShape:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LPhysicsShape:typeOf(name) end

--- Lua-side handle to a destructible [`TerrainMap`].
---@class LTerrain
LTerrain = {}

--- Removes unsupported cells, returning the number of cells that fell.
---@return nil
function LTerrain:collapseColumns() end

--- Sets every cell in the grid to `solid`.
---@param solid boolean
---@return nil
function LTerrain:fillAll(solid) end

--- Fills a circle of cells centred at world position `(wx, wy)`.
---@param wx number
---@param wy number
---@param radius number
---@param solid boolean
---@return nil
function LTerrain:fillCircle(wx, wy, radius, solid) end

--- Fills a rectangular region of cells.
---@param wx number
---@param wy number
---@param w number
---@param h number
---@param solid boolean
---@return nil
function LTerrain:fillRect(wx, wy, w, h, solid) end

--- Rebuilds physics bodies for all dirty chunks.
---@return nil
function LTerrain:flush() end

--- Returns whether a cell is solid.
---@param cx integer
---@param cy integer
---@return boolean
function LTerrain:getCell(cx, cy) end

--- Returns `true` when at least one chunk needs flushing.
---@return boolean
function LTerrain:isDirty() end

--- Loads terrain cell data from bytes produced by `toBytes`.
---@param data string
---@return nil
function LTerrain:loadFromBytes(data) end

--- Sets a single terrain cell to solid or empty.
---@param cx integer
---@param cy integer
---@param solid boolean
---@return nil
function LTerrain:setCell(cx, cy, solid) end

--- Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
---@return table
function LTerrain:solidPositions() end

--- Spawns dynamic debris bodies at the given positions.
---@param positions table
---@param mass number
---@param restitution number
---@return table
function LTerrain:spawnDebris(positions, mass, restitution) end

--- Serialises the terrain grid to a byte string for save/load.
---@return string
function LTerrain:toBytes() end

--- Returns the terrain as an RGBA byte string.
---@param sr integer
---@param sg integer
---@param sb integer
---@param er integer
---@param eg integer
---@param eb integer
---@return string
function LTerrain:toImageData(sr, sg, sb, er, eg, eb) end

--- Returns the type name of this object.
---@return string
function LTerrain:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTerrain:typeOf(name) end

--- Lua-side handle wrapping a physics World.
---@class LWorld
LWorld = {}

--- Creates a distance joint between two bodies.
---@param bodyA integer
---@param bodyB integer
---@param ax1 number
---@param ay1 number
---@param ax2 number
---@param ay2 number
---@param length number
---@return number
function LWorld:addDistanceJoint(bodyA, bodyB, ax1, ay1, ax2, ay2, length) end

--- Adds an extra fixture (collider) to a body.
---@param bodyId integer
---@param shapeType string
---@param ... any
---@return number
function LWorld:addFixture(bodyId, shapeType, ...) end

--- Creates a friction joint that resists relative motion.
---@param bodyA integer
---@param bodyB integer
---@param anchorX number
---@param anchorY number
---@param maxForce number
---@param maxTorque number
---@return number
function LWorld:addFrictionJoint(bodyA, bodyB, anchorX, anchorY, maxForce, maxTorque) end

--- Creates a gear joint (stub — falls back to weld joint).
---@param bodyA integer
---@param bodyB integer
---@param anchorX number
---@param anchorY number
---@return number
function LWorld:addGearJoint(bodyA, bodyB, anchorX, anchorY) end

--- Creates a motor joint that drives body_b toward body_a.
---@param bodyA integer
---@param bodyB integer
---@param correctionFactor number
---@return number
function LWorld:addMotorJoint(bodyA, bodyB, correctionFactor) end

--- Creates a mouse joint connecting a body to a target point.
---@param bodyId integer
---@param targetX number
---@param targetY number
---@param maxForce number
---@return number
function LWorld:addMouseJoint(bodyId, targetX, targetY, maxForce) end

--- Creates a prismatic (slider) joint between two bodies.
---@param bodyA integer
---@param bodyB integer
---@param anchorX number
---@param anchorY number
---@param axisX number
---@param axisY number
---@return number
function LWorld:addPrismaticJoint(bodyA, bodyB, anchorX, anchorY, axisX, axisY) end

--- Creates a pulley joint (stub — falls back to weld joint).
---@param bodyA integer
---@param bodyB integer
---@param anchorX number
---@param anchorY number
---@return number
function LWorld:addPulleyJoint(bodyA, bodyB, anchorX, anchorY) end

--- Creates a revolute (pin) joint between two bodies.
---@param bodyA integer
---@param bodyB integer
---@param anchorX number
---@param anchorY number
---@return number
function LWorld:addRevoluteJoint(bodyA, bodyB, anchorX, anchorY) end

--- Creates a rope joint with a maximum distance.
---@param bodyA integer
---@param bodyB integer
---@param ax1 number
---@param ay1 number
---@param ax2 number
---@param ay2 number
---@param maxLength number
---@return number
function LWorld:addRopeJoint(bodyA, bodyB, ax1, ay1, ax2, ay2, maxLength) end

--- Creates a weld (rigid) joint between two bodies.
---@param bodyA integer
---@param bodyB integer
---@param anchorX number
---@param anchorY number
---@return number
function LWorld:addWeldJoint(bodyA, bodyB, anchorX, anchorY) end

--- Creates a wheel joint (prismatic + rotation).
---@param bodyA integer
---@param bodyB integer
---@param anchorX number
---@param anchorY number
---@param axisX number
---@param axisY number
---@return number
function LWorld:addWheelJoint(bodyA, bodyB, anchorX, anchorY, axisX, axisY) end

--- Creates a rectangular gravity/damping zone and returns a LuaZone handle.
---@param x number
---@param y number
---@param width number
---@param height number
---@return Zone
function LWorld:addZone(x, y, width, height) end

--- Resets the world, removing all bodies and joints.
---@return nil
function LWorld:clear() end

--- Removes the begin-contact callback.
---@return nil
function LWorld:clearBeginContact() end

--- Removes the Lua data attached to a body.
---@param bodyId integer
---@return nil
function LWorld:clearBodyData(bodyId) end

--- Removes the one-way platform flag from a body.
---@param bodyId integer
---@return nil
function LWorld:clearBodyOneWay(bodyId) end

--- Removes the end-contact callback.
---@return nil
function LWorld:clearEndContact() end

--- Removes a body from the world.
---@param id integer
---@return nil
function LWorld:destroyBody(id) end

--- Removes a joint from the world.
---@param jointId integer
---@return nil
function LWorld:destroyJoint(jointId) end

--- Draws physics objects for debugging
---@param target ImageData
---@param r number?[default=0]
---@param g number?[default=255]
---@param b number?[default=0]
---@param a number?[default=255]
---@return nil
function LWorld:drawDebug(target, r, g, b, a) end

--- Returns the number of fixtures on a body.
---@param bodyId integer
---@return number
function LWorld:fixtureCount(bodyId) end

--- Returns begin-contact events from the last step.
---@return table
function LWorld:getBeginContactEvents() end

--- Returns the body ID at a world-space point, or nil.
---@param x number
---@param y number
---@return number
function LWorld:getBodyAtPoint(x, y) end

--- Returns whether CCD is enabled for a body.
---@param bodyId integer
---@return boolean
function LWorld:getBodyCCD(bodyId) end

--- Returns contacts involving a specific body.
---@param bodyId integer
---@return table
function LWorld:getBodyContacts(bodyId) end

--- Returns the total number of bodies in the world.
---@return number
function LWorld:getBodyCount() end

--- Returns the Lua data previously attached to a body, or nil if none is set.
---@param bodyId integer
---@return nil
function LWorld:getBodyData(bodyId) end

--- Returns all body IDs in the world.
---@return table
function LWorld:getBodyIds() end

--- Returns the one-way normal for a body, or nil if not configured.
---@param bodyId integer
---@return nil
function LWorld:getBodyOneWay(bodyId) end

--- Returns the body type as a string.
---@param bodyId integer
---@return string
function LWorld:getBodyType(bodyId) end

--- Returns collision events from the last step.
---@return table
function LWorld:getCollisionEvents() end

--- Returns all contact pairs from the narrow phase.
---@return table
function LWorld:getContacts() end

--- Returns end-contact events from the last step.
---@return table
function LWorld:getEndContactEvents() end

--- Returns the gravity vector (gx, gy).
---@return number
---@return number
function LWorld:getGravity() end

--- Returns the two body IDs connected by a joint.
---@param jointId integer
---@return integer
---@return integer
function LWorld:getJointBodies(jointId) end

--- Returns the break threshold for a joint, or nil if not set.
---@param jointId integer
---@return nil
function LWorld:getJointBreakForce(jointId) end

--- Returns a table of integer IDs for every joint attached to this world.
---@return table
function LWorld:getJointIds() end

--- Returns the angular limits on a joint.
---@param jointId integer
---@return number
---@return number
function LWorld:getJointLimits(jointId) end

--- Returns the motor speed on a joint's angular axis.
---@param jointId integer
---@return number
function LWorld:getJointMotorSpeed(jointId) end

--- Returns the type name of a joint.
---@param jointId integer
---@return string
function LWorld:getJointType(jointId) end

--- Returns the pixels-per-meter scaling factor.
---@return number
function LWorld:getMeter() end

--- Returns the current number of solver iterations per step.
---@return number
function LWorld:getSolverIterations() end

--- Returns zone enter/leave events produced by the most recent step.
---@return table
function LWorld:getZoneEvents() end

--- Returns true if a body is currently sleeping (inactive).
---@param bodyId integer
---@return boolean
function LWorld:isBodySleeping(bodyId) end

--- Returns the total number of joints.
---@return number
function LWorld:jointCount() end

--- Creates multiple bodies in one call.
---@param specs table
---@return nil
function LWorld:newBodies(specs) end

--- Creates a new rectangular body and adds it to the world.
---@param x number
---@param y number
---@param bodyType string
---@return Body
function LWorld:newBody(x, y, bodyType) end

--- Creates a new chain body from a flat vertex table and adds it to the world.
---@param x number
---@param y number
---@param vertices table
---@param closed boolean
---@param bodyType string
---@return Body
function LWorld:newChainBody(x, y, vertices, closed, bodyType) end

--- Creates a new circular body and adds it to the world.
---@param x number
---@param y number
---@param radius number
---@param bodyType string
---@return Body
function LWorld:newCircleBody(x, y, radius, bodyType) end

--- Creates a new edge (line segment) body and adds it to the world.
---@param x number
---@param y number
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param bodyType string
---@return Body
function LWorld:newEdgeBody(x, y, x1, y1, x2, y2, bodyType) end

--- Creates a new polygon body from a flat vertex table and adds it to the world.
---@param x number
---@param y number
---@param vertices table
---@param bodyType string
---@return Body
function LWorld:newPolygonBody(x, y, vertices, bodyType) end

--- Returns body IDs within an axis-aligned bounding box.
---@param x number
---@param y number
---@param w number
---@param h number
---@return table
function LWorld:queryAABB(x, y, w, h) end

--- Casts a ray and returns the nearest hit, or nil.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return table
function LWorld:raycast(x1, y1, x2, y2) end

--- Casts a ray and returns all hits.
---@param x1 number
---@param y1 number
---@param dx number
---@param dy number
---@param maxDist number
---@return table
function LWorld:raycastAll(x1, y1, dx, dy, maxDist) end

--- Casts a ray and returns the closest hit using the query pipeline.
---@param x1 number
---@param y1 number
---@param dx number
---@param dy number
---@param maxDist number
---@return table
function LWorld:raycastClosest(x1, y1, dx, dy, maxDist) end

--- Registers a Lua function called with (bodyIdA, bodyIdB) when two
---@param fn function
---@return nil
function LWorld:setBeginContact(fn) end

--- Enables or disables Continuous Collision Detection for a body.
---@param bodyId integer
---@param enabled boolean
---@return nil
function LWorld:setBodyCCD(bodyId, enabled) end

--- Attaches arbitrary Lua data to a body for retrieval in collision callbacks.
---@param bodyId integer
---@param data any
---@return nil
function LWorld:setBodyData(bodyId, data) end

--- Marks a body as a one-way platform.  Bodies approaching from the
---@param bodyId integer
---@param nx number
---@param ny number
---@return nil
function LWorld:setBodyOneWay(bodyId, nx, ny) end

--- Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
---@param bodyId integer
---@param bodyType string
---@return nil
function LWorld:setBodyType(bodyId, bodyType) end

--- Registers a Lua function called with (bodyIdA, bodyIdB) when two
---@param fn function
---@return nil
function LWorld:setEndContact(fn) end

--- Sets friction on a fixture by index.
---@param bodyId integer
---@param fixtureIdx integer
---@param friction number
---@return nil
function LWorld:setFixtureFriction(bodyId, fixtureIdx, friction) end

--- Sets restitution on a fixture by index.
---@param bodyId integer
---@param fixtureIdx integer
---@param restitution number
---@return nil
function LWorld:setFixtureRestitution(bodyId, fixtureIdx, restitution) end

--- Sets whether a fixture is a sensor.
---@param bodyId integer
---@param fixtureIdx integer
---@param sensor boolean
---@return nil
function LWorld:setFixtureSensor(bodyId, fixtureIdx, sensor) end

--- Sets the world gravity vector; default is `(0, 9.81)` (downward).
---@param gx number
---@param gy number
---@return nil
function LWorld:setGravity(gx, gy) end

--- Sets the relative-velocity threshold above which a joint breaks.
---@param jointId integer
---@param maxForce number
---@return nil
function LWorld:setJointBreakForce(jointId, maxForce) end

--- Sets the angular limits on a joint.
---@param jointId integer
---@param lower number
---@param upper number
---@return nil
function LWorld:setJointLimits(jointId, lower, upper) end

--- Enables or disables angular limits on a joint.
---@param jointId integer
---@param enabled boolean
---@return nil
function LWorld:setJointLimitsEnabled(jointId, enabled) end

--- Sets the motor speed on a joint's angular axis.
---@param jointId integer
---@param speed number
---@return nil
function LWorld:setJointMotorSpeed(jointId, speed) end

--- Sets the pixels-per-meter scaling factor.
---@param ppm number
---@return nil
function LWorld:setMeter(ppm) end

--- Updates the target position of a mouse joint.
---@param jointId integer
---@param x number
---@param y number
---@return nil
function LWorld:setMouseJointTarget(jointId, x, y) end

--- Sets the number of constraint solver iterations per step.
---@param n integer
---@return nil
function LWorld:setSolverIterations(n) end

--- Puts a body to sleep immediately.
---@param bodyId integer
---@return nil
function LWorld:sleepBody(bodyId) end

--- Advances the physics simulation by dt seconds, firing onBeginContact /
---@param dt number
---@return nil
function LWorld:step(dt) end

--- Steps the world using a fixed sub-step size to consume accumulated time.
---@param accum number
---@param step_dt number
---@param max_steps integer
---@return nil
function LWorld:stepFixed(accum, step_dt, max_steps) end

--- Converts a pixel value to physics units.
---@param px number
---@return number
function LWorld:toPhysics(px) end

--- Converts a physics-unit value to pixels.
---@param m number
---@return number
function LWorld:toPixels(m) end

--- Returns the type name of this object.
---@return string
function LWorld:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LWorld:typeOf(name) end

--- Forcibly wakes up a sleeping body.
---@param bodyId integer
---@return nil
function LWorld:wakeUpBody(bodyId) end

--- Lua-side handle to a [`PhysicsZone`] living inside a [`World`].
---@class LZone
LZone = {}

--- Removes the zone from the world.
---@return nil
function LZone:destroy() end

--- Returns the zone's integer ID.
---@return number
function LZone:getId() end

--- Sets an optional angular damping override for bodies inside the zone.
---@param value? number
---@return nil
function LZone:setAngularDampingOverride(value) end

--- Replaces the zone boundary with a circle.
---@param cx number
---@param cy number
---@param radius number
---@return nil
function LZone:setCircle(cx, cy, radius) end

--- Enables or disables the zone.
---@param enabled boolean
---@return nil
function LZone:setEnabled(enabled) end

--- Sets directional gravity inside the zone.
---@param gx number
---@param gy number
---@return nil
function LZone:setGravityDirectional(gx, gy) end

--- Sets point-attractor gravity inside the zone.
---@param cx number
---@param cy number
---@param strength number
---@return nil
function LZone:setGravityPoint(cx, cy, strength) end

--- Sets point-repulsor gravity inside the zone.
---@param cx number
---@param cy number
---@param strength number
---@return nil
function LZone:setGravityRepulsor(cx, cy, strength) end

--- Suppresses gravity inside the zone (zero-g pocket).
---@return nil
function LZone:setGravityZero() end

--- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
---@param mask integer
---@return nil
function LZone:setLayerMask(mask) end

--- Sets an optional linear damping override for bodies inside the zone.
---@param value? number
---@return nil
function LZone:setLinearDampingOverride(value) end

--- Sets the zone priority; higher values win over lower when zones overlap.
---@param priority integer
---@return nil
function LZone:setPriority(priority) end

--- Returns the type name of this object.
---@return string
function LZone:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LZone:typeOf(name) end

--- Attaches a standalone shape to a body as an additional fixture.
---@param body Body
---@param shape PhysicsShape
---@return nil
lurek.physics.attachShape = function(body, shape) end

--- Enables or disables the physics debug overlay (AABB boxes and velocity vectors).
---@param enable boolean
---@return nil
lurek.physics.debugDraw = function(enable) end

--- Marks a physics world for destruction. Subsequent operations on the world
---@param world World
---@return nil
lurek.physics.destroyWorld = function(world) end

--- Extracts collider geometry from a World and queues a GPU physics debug
---@param world World
---@param config table|nil
---@return nil
lurek.physics.drawDebugGpu = function(world, config) end

--- Returns the position and velocity of a body (x, y, vx, vy).
---@param world World
---@param body Body
---@return number
---@return number
---@return number
---@return number
lurek.physics.getBody = function(world, body) end

--- Returns all collision events from the last simulation step.
---@param world World
---@return table
lurek.physics.getCollisions = function(world) end

--- Returns whether the body is allowed to sleep.
---@param world World
---@param body Body
---@return boolean
lurek.physics.isSleepingAllowed = function(world, body) end

--- Creates a new rectangular body in the given world.
---@param world World
---@param x number
---@param y number
---@param bodyType string
---@return Body
lurek.physics.newBody = function(world, x, y, bodyType) end

--- Creates a falling-sand cellular automaton grid.
---@param width integer
---@param height integer
---@return Cellular
lurek.physics.newCellular = function(width, height) end

--- Creates a chain shape userdata from flat variadic vertex pairs.
---@param closed boolean
---@param ... number
---@return PhysicsShape
lurek.physics.newChainShape = function(closed, ...) end

--- Creates a circle shape userdata.
---@param radius number
---@return PhysicsShape
lurek.physics.newCircleShape = function(radius) end

--- Creates an edge (line segment) shape userdata.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return PhysicsShape
lurek.physics.newEdgeShape = function(x1, y1, x2, y2) end

--- Creates a convex polygon shape userdata from flat variadic vertex pairs.
---@param ... number
---@return PhysicsShape
lurek.physics.newPolygonShape = function(...) end

--- Creates a rectangle shape userdata.
---@param width number
---@param height number
---@return PhysicsShape
lurek.physics.newRectangleShape = function(width, height) end

--- Creates a destructible terrain grid.
---@param width integer
---@param height integer
---@param cell_size number
---@param world_handle World
---@return Terrain
lurek.physics.newTerrain = function(width, height, cell_size, world_handle) end

--- Creates a new physics world with the given gravity vector.
---@param gx number
---@param gy number
---@return World
lurek.physics.newWorld = function(gx, gy) end

--- Sets the velocity of a body.
---@param world World
---@param body Body
---@param vx number
---@param vy number
---@return nil
lurek.physics.setBodyVelocity = function(world, body, vx, vy) end

--- Sets whether the body is allowed to sleep.
---@param world World
---@param body Body
---@param allowed boolean
---@return nil
lurek.physics.setSleepingAllowed = function(world, body, allowed) end

--- Advances the physics world by dt seconds.
---@param world World
---@param dt number
---@return nil
lurek.physics.step = function(world, dt) end

--- Returns true when two axis-aligned bounding boxes overlap.
---@param ax number
---@param ay number
---@param aw number
---@param ah number
---@param bx number
---@param by number
---@param bw number
---@param bh number
---@return boolean
lurek.physics.testAABB = function(ax, ay, aw, ah, bx, by, bw, bh) end

--- Returns true when a circle overlaps an AABB.
---@param cx number
---@param cy number
---@param cr number
---@param ax number
---@param ay number
---@param aw number
---@param ah number
---@return boolean
lurek.physics.testCircleAABB = function(cx, cy, cr, ax, ay, aw, ah) end

--- Returns true when two circles overlap.
---@param ax number
---@param ay number
---@param ar number
---@param bx number
---@param by number
---@param br number
---@return boolean
lurek.physics.testCircles = function(ax, ay, ar, bx, by, br) end

--- Returns true when point (px, py) lies inside the AABB.
---@param px number
---@param py number
---@param ax number
---@param ay number
---@param aw number
---@param ah number
---@return boolean
lurek.physics.testPoint = function(px, py, ax, ay, aw, ah) end

---@class lurek.pipeline
lurek.pipeline = {}

--- Lua-side wrapper around a [`Pipeline`] DAG with scheduler and Lua callback registry.
---@class LPipeline
LPipeline = {}

--- Adds a step with a runtime condition guard: the step is skipped when `when_fn()` returns false.
---@param name string
---@param deps table -- array of dependency step names
---@param fn function -- step body
---@param when_fn function -- returns boolean; false skips the step
---@return Pipeline
function LPipeline:addConditional(name, deps, fn, when_fn) end

--- Adds a step to the pipeline. Returns self for chaining.
---@param step Step
---@return Pipeline
function LPipeline:addStep(step) end

--- Inlines all steps from `sub_pipeline` into this pipeline, prefixing
---@param sub_pipeline Pipeline
---@param alias string
---@param outer_deps? table
---@return nil
function LPipeline:addSubPipeline(sub_pipeline, alias, outer_deps) end

--- Cancels all pending and waiting steps.
---@return nil
function LPipeline:cancel() end

--- Clears all steps from the pipeline.
---@return nil
function LPipeline:clear() end

--- Returns the stored async context table, or nil.
---@return table
function LPipeline:getContext() end

--- Returns the current error mode as a string.
---@return string
function LPipeline:getErrorMode() end

--- Returns the topological execution order as an array of step names.
---@return nil
function LPipeline:getExecutionOrder() end

--- Returns the pipeline's name.
---@return string
function LPipeline:getName() end

--- Returns parallel execution groups as a nested array of step name arrays.
---@return nil
function LPipeline:getParallelGroups() end

--- Returns the current result table built from step states, or nil.
---@return table
function LPipeline:getResult() end

--- Returns the LuaStep wrapper for the named step, or nil.
---@param name string
---@return Step?
function LPipeline:getStep(name) end

--- Returns the total number of steps.
---@return number
function LPipeline:getStepCount() end

--- Returns a Lua array of all step wrappers in the pipeline.
---@return table
function LPipeline:getSteps() end

--- Returns a Lua array of all steps whose tag matches the given string.
---@param tag string
---@return table
function LPipeline:getStepsByTag(tag) end

--- Returns true if all steps have reached a terminal state.
---@return boolean
function LPipeline:isComplete() end

--- Returns true if the pipeline is currently running asynchronously.
---@return boolean
function LPipeline:isRunning() end

--- Registers a callback invoked after every step with `(step_name, status)`.
---@param fn function
---@return nil
function LPipeline:onProgress(fn) end

--- Removes a step from the pipeline by name.
---@param name string
---@return nil
function LPipeline:removeStep(name) end

--- Resets all step states and clears the async context.
---@return nil
function LPipeline:reset() end

--- Executes the pipeline synchronously in topological order.
---@param context? table
---@return table
function LPipeline:run(context) end

--- Starts an async pipeline run. Steps are executed one-per-frame via update(dt).
---@param context? table
---@return nil
function LPipeline:runAsync(context) end

--- Sets the pipeline error mode: "abort" or "continue".
---@param mode string
---@return nil
function LPipeline:setErrorMode(mode) end

--- Sets the pipeline's name.
---@param name string
---@return nil
function LPipeline:setName(name) end

--- Sets the callback to invoke when the pipeline completes.
---@param fn? function
---@return nil
function LPipeline:setOnComplete(fn) end

--- Sets the callback to invoke each time a step completes successfully.
---@param fn? function
---@return nil
function LPipeline:setOnStepComplete(fn) end

--- Sets the callback to invoke each time a step fails.
---@param fn? function
---@return nil
function LPipeline:setOnStepError(fn) end

--- Returns a multi-line ASCII string visualising the pipeline DAG.
---@return string
function LPipeline:toAscii() end

--- Serialises the pipeline definition to a Lua table (no callbacks).
---@return table
function LPipeline:toTable() end

--- Returns the type name of this object.
---@return string
function LPipeline:type() end

--- Returns the type identifier string of this pipeline stage object.
---@param name string
---@return boolean
function LPipeline:typeOf(name) end

--- Advances the async pipeline by one tick. Returns true when all steps are done.
---@param dt number
---@return boolean
function LPipeline:update(dt) end

--- Validates the pipeline DAG. Returns (ok, error_array).
---@return nil
function LPipeline:validate() end

--- Lua-side wrapper around a single [`PipelineStep`], plus Lua callback registry keys.
---@class LPipelineStep
LPipelineStep = {}

--- Adds a dependency on another step by name or PipelineStep. Returns self for chaining
---@param dep string|Step
---@return Step
function LPipelineStep:dependsOn(dep) end

--- Returns the number of execution attempts so far
---@return number
function LPipelineStep:getAttempt() end

--- Retrieves a metadata value by key, returning nil if not found
---@param key string
---@return string
function LPipelineStep:getData(key) end

--- Returns the configured delay in seconds
---@return number
function LPipelineStep:getDelay() end

--- Returns the list of dependency step names
---@return table
function LPipelineStep:getDependencies() end

--- Returns the number of declared dependencies
---@return number
function LPipelineStep:getDependencyCount() end

--- Returns total seconds spent executing this step
---@return number
function LPipelineStep:getDuration() end

--- Returns the error message from the last failed attempt, or nil
---@return string
function LPipelineStep:getError() end

--- Returns the unique name of this step
---@return string
function LPipelineStep:getName() end

--- Returns the configured retry count
---@return number
function LPipelineStep:getRetryCount() end

--- Returns the current execution status as a string
---@return string
function LPipelineStep:getStatus() end

--- Returns the tag on this step, or nil if unset
---@return string
function LPipelineStep:getTag() end

--- Returns the timeout stored in metadata, or 0.0 if unset
---@return number
function LPipelineStep:getTimeout() end

--- Returns whether this step is marked as optional
---@return boolean
function LPipelineStep:isOptional() end

--- Stores a Lua function as the execute callback for this step
---@param fn function
---@return nil
function LPipelineStep:setCallback(fn) end

--- Stores a Lua function (or nil) as the run-condition for this step
---@param fn? function
---@return nil
function LPipelineStep:setCondition(fn) end

--- Stores an arbitrary string value under the given key in step metadata
---@param key string
---@param value string
---@return nil
function LPipelineStep:setData(key, value) end

--- Sets the delay in seconds to wait after dependencies finish
---@param seconds number
---@return nil
function LPipelineStep:setDelay(seconds) end

--- Stores a Lua function (or nil) to call if this step fails
---@param fn? function
---@return nil
function LPipelineStep:setOnError(fn) end

--- Marks whether this step is optional (downstream steps continue on failure)
---@param optional boolean
---@return nil
function LPipelineStep:setOptional(optional) end

--- Sets the maximum number of retry attempts on failure
---@param count integer
---@return nil
function LPipelineStep:setRetryCount(count) end

--- Sets the delay in seconds between retry attempts
---@param seconds number
---@return nil
function LPipelineStep:setRetryDelay(seconds) end

--- Sets the tag on this step for grouping and filtering
---@param tag string
---@return nil
function LPipelineStep:setTag(tag) end

--- Stores a timeout in seconds in the step's metadata
---@param seconds number
---@return nil
function LPipelineStep:setTimeout(seconds) end

--- Returns the type name "PipelineStep"
---@return string
function LPipelineStep:type() end

--- Returns true when the given name matches "PipelineStep" or a parent type
---@param name string
---@return boolean
function LPipelineStep:typeOf(name) end

--- Deserialises a pipeline from a definition table.
---@param def table
---@return Pipeline
lurek.pipeline.fromTable = function(def) end

--- Creates a new empty pipeline with the given name (defaults to "pipeline").
---@param name? string
---@return Pipeline
lurek.pipeline.newPipeline = function(name) end

--- Creates a new pipeline step with the given name and optional callback.
---@param name string
---@param fn? function
---@return Step
lurek.pipeline.newStep = function(name, fn) end

---@class lurek.procgen
lurek.procgen = {}

--- Generates a dungeon using Binary Space Partitioning.
---@param opts? table
---@return table
lurek.procgen.bspDungeon = function(opts) end

--- Generates a cave-like map using cellular automata.
---@param w integer
---@param h integer
---@param opts? table
---@return table
lurek.procgen.cellularAutomata = function(w, h, opts) end

--- BFS flood fill on a flat grid of bytes.
---@param data table
---@param w integer
---@param h integer
---@param sx integer
---@param sy integer
---@param threshold? integer
---@param above? boolean
---@return table
lurek.procgen.floodFill = function(data, w, h, sx, sy, threshold, above) end

--- Generates a single procedural name using a Markov chain.
---@param samples table
---@param min_len? integer
---@param max_len? integer
---@param seed? integer
---@return string
lurek.procgen.generateName = function(samples, min_len, max_len, seed) end

--- Generates N procedural names using a Markov chain.
---@param samples table
---@param n integer
---@param min_len? integer
---@param max_len? integer
---@param seed? integer
---@return table
lurek.procgen.generateNames = function(samples, n, min_len, max_len, seed) end

--- Generates a heightmap using fractal noise.
---@param opts? table
---@return table
lurek.procgen.heightmap = function(opts) end

--- Generates an L-system string.
---@param opts table
---@param iterations? integer
---@return string
lurek.procgen.lsystem = function(opts, iterations) end

--- Generates L-system line segments for rendering.
---@param opts table
---@param angle_deg? number
---@param step? number
---@return table
lurek.procgen.lsystemSegments = function(opts, angle_deg, step) end

--- Generates a noise map using the configurable NoiseGenerator.
---@param width integer
---@param height integer
---@param opts? table
---@return table
lurek.procgen.noiseMap = function(width, height, opts) end

--- Generates a noise map using rayon parallel processing.
---@param width integer
---@param height integer
---@param opts? table
---@return table
lurek.procgen.noiseMapParallel = function(width, height, opts) end

--- Evaluates periodic Perlin noise at a point.
---@param x number
---@param y number
---@param px number
---@param py number
---@return number
lurek.procgen.perlinNoise = function(x, y, px, py) end

--- Generates Poisson disk sample points using Bridson's algorithm.
---@param w number
---@param h number
---@param min_dist number
---@param max_attempts? integer
---@param seed? integer
---@return table
lurek.procgen.poissonDisk = function(w, h, min_dist, max_attempts, seed) end

--- Generates a rooms-and-corridors dungeon.
---@param opts? table
---@return table
lurek.procgen.roomsDungeon = function(opts) end

--- Returns a single Simplex noise value at the given 2-D coordinate.
---@param x number
---@param y number
---@return number
lurek.procgen.simplex2d = function(x, y) end

--- Returns a single Simplex noise value at the given 3-D coordinate.
---@param x number
---@param y number
---@param z number
---@return number
lurek.procgen.simplex3d = function(x, y, z) end

--- Generates a Voronoi diagram for a set of seed points.
---@param w integer
---@param h integer
---@param pts table
---@param opts? table
---@return table
lurek.procgen.voronoi = function(w, h, pts, opts) end

--- Generates a tile grid using Wave Function Collapse.
---@param opts table
---@return table
lurek.procgen.wfcGenerate = function(opts) end

--- Generates a world graph with scattered regions and edges.
---@param width number
---@param height number
---@param region_count integer
---@param seed? integer
---@return table
lurek.procgen.worldGraph = function(width, height, region_count, seed) end

---@class lurek.raycaster
lurek.raycaster = {}

--- Lua-side wrapper around a [`DoorManager`], managing sliding doors in a level.
---@class LDoorManager
LDoorManager = {}

--- Registers a door at grid position (x, y).
---@param x integer
---@param y integer
---@param direction string
---@param speed number
---@return number
function LDoorManager:addDoor(x, y, direction, speed) end

--- Begins closing the door at the given index.
---@param index integer
---@return nil
function LDoorManager:closeDoor(index) end

--- Returns the number of registered doors.
---@return number
function LDoorManager:count() end

--- Returns the state table for door at index, or nil if out of range.
---@param index integer
---@return nil
function LDoorManager:getDoor(index) end

--- Begins opening the door at the given index.
---@param index integer
---@return nil
function LDoorManager:openDoor(index) end

--- Returns the type string "DoorManager".
---@return string
function LDoorManager:type() end

--- Returns the type string "DoorManager".
---@return string
function LDoorManager:typeOf() end

--- Advances all door animations by dt seconds.
---@param dt number
---@return nil
function LDoorManager:update(dt) end

--- Lua-side wrapper around a [`HeightMap`] for variable floor/ceiling heights.
---@class LHeightMap
LHeightMap = {}

--- Returns the ceiling height at (x, y). Returns 1.0 for out-of-bounds.
---@param x integer
---@param y integer
---@return number
function LHeightMap:ceilingAt(x, y) end

--- Returns the floor height at (x, y). Returns 0.0 for out-of-bounds.
---@param x integer
---@param y integer
---@return number
function LHeightMap:floorAt(x, y) end

--- Sets the ceiling height at (x, y).
---@param x integer
---@param y integer
---@param h number
---@return nil
function LHeightMap:setCeiling(x, y, h) end

--- Sets the floor height at (x, y).
---@param x integer
---@param y integer
---@param h number
---@return nil
function LHeightMap:setFloor(x, y, h) end

--- Returns the type string "HeightMap".
---@return string
function LHeightMap:type() end

--- Returns the type string "HeightMap".
---@return string
function LHeightMap:typeOf() end

--- Lua-side value wrapper around a raycaster [`PointLight`].
---@class LPointLight
LPointLight = {}

--- Returns the RGB color as three separate values.
---@return number
---@return number
---@return number
function LPointLight:color() end

--- Returns the intensity multiplier.
---@return number
function LPointLight:intensity() end

--- Returns the illumination radius.
---@return number
function LPointLight:radius() end

--- Updates all light properties at once.
---@param x number
---@param y number
---@param r number
---@param g number
---@param b number
---@param radius number
---@param intensity number
---@return nil
function LPointLight:set(x, y, r, g, b, radius, intensity) end

--- Returns the type string "PointLight".
---@return string
function LPointLight:type() end

--- Returns the type string "PointLight".
---@return string
function LPointLight:typeOf() end

--- Returns the world-space X position.
---@return number
function LPointLight:x() end

--- Returns the world-space Y position.
---@return number
function LPointLight:y() end

--- Lua-side wrapper around a [`Raycaster2D`] grid.
---@class LRaycaster
LRaycaster = {}

--- Builds a raycaster scene and stores it in SharedState for GPU rendering.
---@param params table â€”{px,py,angle,fov,rays,max_dist,screen_w,screen_h,ambient?,shade_dist?,floor_color?,ceiling_color?}
---@param lights table|nil â€” array of{x,y,radius,r,g,b,intensity}
---@param sprites table|nil â€” array of{x,y,texture,size}
---@param wall_textures table|nil â€”{[cell_value]= TextureKey}
---@return nil
function LRaycaster:buildScene(params, lights, sprites, wall_textures) end

--- Computes floor (or ceiling) texture UV coordinates for one horizontal screen row.
---@param cam_x number
---@param cam_y number
---@param dir_x number
---@param dir_y number
---@param plane_x number
---@param plane_y number
---@param row integer
---@return table
function LRaycaster:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, row) end

--- Casts a single ray and returns a hit table, or nil if nothing was hit.
---@param ox number
---@param oy number
---@param angle number
---@param max_dist number
---@return table
function LRaycaster:castRay(ox, oy, angle, max_dist) end

--- Casts a ray collecting up to max_hits wall layers, continuing through
---@param ox number
---@param oy number
---@param angle number
---@param max_dist number
---@param max_hits? integer
---@return table
function LRaycaster:castRayMulti(ox, oy, angle, max_dist, max_hits) end

--- Casts multiple rays across a field of view, returns an array of hit tables.
---@param ox number
---@param oy number
---@param angle number
---@param fov number
---@param count integer
---@param max_dist number
---@return table
function LRaycaster:castRays(ox, oy, angle, fov, count, max_dist) end

--- Casts multiple rays and returns a flat array of 5 floats per ray.
---@param ox number
---@param oy number
---@param angle number
---@param fov number
---@param count integer
---@param max_dist number
---@return table
function LRaycaster:castRaysFlat(ox, oy, angle, fov, count, max_dist) end

--- Renders a mosaic of first-person views from evenly spaced angles to an ImageData.
---@param x number
---@param y number
---@param fov number
---@param max_dist number
---@param num_frames integer
---@param frame_w integer
---@param frame_h integer
---@return ImageData
function LRaycaster:drawCameraSweep(x, y, fov, max_dist, num_frames, frame_w, frame_h) end

--- Renders a depth-map column view to an ImageData.
---@param px number
---@param py number
---@param angle number
---@param fov number
---@param num_rays integer
---@param width integer
---@param height integer
---@param max_dist number
---@return ImageData
function LRaycaster:drawDepthMap(px, py, angle, fov, num_rays, width, height, max_dist) end

--- Renders a line-of-sight test between two points to an ImageData.
---@param ax number
---@param ay number
---@param bx number
---@param by number
---@param scale integer
---@return ImageData
function LRaycaster:drawLineOfSight(ax, ay, bx, by, scale) end

--- Renders a top-down grid view with player marker to an ImageData.
---@param px number
---@param py number
---@param angle number
---@param scale integer
---@return ImageData
function LRaycaster:drawTopDown(px, py, angle, scale) end

--- Renders a first-person column view to an ImageData.
---@param px number
---@param py number
---@param angle number
---@param fov number
---@param width integer
---@param height integer
---@param max_dist number
---@return ImageData
function LRaycaster:drawView(px, py, angle, fov, width, height, max_dist) end

--- Returns the cell value at (x, y).
---@param x integer
---@param y integer
---@return number
function LRaycaster:getCell(x, y) end

--- Returns the opacity for a wall tile type. Returns 1.0 if not set.
---@param tile_type integer
---@return number
function LRaycaster:getWallAlpha(tile_type) end

--- Returns the grid height in cells.
---@return number
function LRaycaster:height() end

--- Returns true when the cell at (x, y) is a wall (value > 0).
---@param x integer
---@param y integer
---@return boolean
function LRaycaster:isBlocked(x, y) end

--- Checks line of sight between two points using DDA traversal.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return boolean
function LRaycaster:lineOfSight(x1, y1, x2, y2) end

--- Projects a world-space sprite onto screen space.
---@param sx number
---@param sy number
---@param px number
---@param py number
---@param pa number
---@param fov number
---@param screen_w number
---@return table
function LRaycaster:projectSprite(sx, sy, px, py, pa, fov, screen_w) end

--- Sets the cell value at grid position (x, y).
---@param x integer
---@param y integer
---@param val integer
---@return nil
function LRaycaster:setCell(x, y, val) end

--- Replaces all grid cells from a flat array of values in row-major order.
---@param cells table
---@return nil
function LRaycaster:setCells(cells) end

--- Sets the opacity for a wall tile type. Alpha is clamped to [0, 1].
---@param tile_type integer
---@param alpha number
---@return nil
function LRaycaster:setWallAlpha(tile_type, alpha) end

--- Returns the type name of this object.
---@return string
function LRaycaster:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LRaycaster:typeOf(name) end

--- Returns the grid width in cells.
---@return number
function LRaycaster:width() end

--- Lua-side wrapper around a [`SpriteManager`] for batch depth-sorted sprite projection.
---@class LSpriteManager
LSpriteManager = {}

--- Adds a sprite at world position (x, y) and returns its unique id.
---@param x number
---@param y number
---@param texture string
---@param scale? number
---@return number
function LSpriteManager:add(x, y, texture, scale) end

--- Removes all sprites from the manager.
---@return nil
function LSpriteManager:clear() end

--- Removes the sprite with the given id. No-op if not found.
---@param id integer
---@return nil
function LSpriteManager:remove(id) end

--- Moves the sprite with the given id to world (x, y).
---@param id integer
---@param x number
---@param y number
---@return nil
function LSpriteManager:setPosition(id, x, y) end

--- Shows or hides the sprite with the given id.
---@param id integer
---@param visible boolean
---@return nil
function LSpriteManager:setVisible(id, visible) end

--- Returns an array of visible sprites sorted back-to-front from camera position.
---@param cam_x number
---@param cam_y number
---@param cam_angle number
---@return table
function LSpriteManager:sortAndProject(cam_x, cam_y, cam_angle) end

--- Returns the type string "SpriteManager".
---@return string
function LSpriteManager:type() end

--- Returns the type string "SpriteManager".
---@return string
function LSpriteManager:typeOf() end

--- Returns distance-based brightness in [0, 1].
---@param distance number
---@param max_distance number
---@return number
lurek.raycaster.distanceShade = function(distance, max_distance) end

--- Creates a new raycaster grid of the given dimensions.
---@param width integer
---@param height integer
---@return Raycaster
lurek.raycaster.new = function(width, height) end

--- Creates a new empty door manager.
---@return DoorManager
lurek.raycaster.newDoorManager = function() end

--- Creates a new height map with default floor (0.0) and ceiling (1.0) values.
---@param width integer
---@param height integer
---@return HeightMap
lurek.raycaster.newHeightMap = function(width, height) end

--- Alias for `new`. Creates a new raycaster grid of the given dimensions.
---@param width integer
---@param height integer
---@return Raycaster
lurek.raycaster.newMap = function(width, height) end

--- Creates a point light for use in raycaster scene lighting.
---@param x number
---@param y number
---@param r number
---@param g number
---@param b number
---@param radius number
---@param intensity number
---@return PointLight
lurek.raycaster.newPointLight = function(x, y, r, g, b, radius, intensity) end

--- Creates a new empty batch sprite manager for depth-sorted projection.
---@return SpriteManager
lurek.raycaster.newSpriteManager = function() end

--- Projects a wall distance to screen-space drawing parameters.
---@param distance number
---@param fov number
---@param screen_height number
---@return number
---@return number
---@return number
lurek.raycaster.projectColumn = function(distance, fov, screen_height) end

---@class lurek.render
lurek.render = {}

--- Lua-side handle to an off-screen render target stored in SharedState.
---@class LCanvas
LCanvas = {}

--- Returns width and height of this canvas.
---@return integer
---@return integer
function LCanvas:getDimensions() end

--- Returns the height of this canvas in pixels.
---@return number
function LCanvas:getHeight() end

--- Returns the width of this canvas in pixels.
---@return number
function LCanvas:getWidth() end

--- Releases GPU framebuffer memory for this canvas.
---@return boolean
function LCanvas:release() end

--- Returns the type name of this object.
---@return string
function LCanvas:type() end

--- Returns the type name of this object.
---@param name? string
---@return string
function LCanvas:typeOf(name) end

--- Lua-side z-ordered draw queue. Callbacks are sorted by z and called on `flush()`.
---@class LDrawLayer
LDrawLayer = {}

--- Removes all queued callbacks without calling them.
---@return number
function LDrawLayer:clear() end

--- Sorts and calls all queued callbacks, then empties the queue.
---@return nil
function LDrawLayer:flush() end

--- Returns the number of queued callbacks.
---@return number
function LDrawLayer:getCount() end

--- Queues a draw callback at the given z-order.
---@param z number
---@param fn function
---@return nil
function LDrawLayer:queue(z, fn) end

--- Returns the string type identifier of this draw layer (e.g. `'sprite'`).
---@return string
function LDrawLayer:type() end

--- Returns true if this object is an instance of the given type name.
---@param name string
---@return boolean
function LDrawLayer:typeOf(name) end

--- Lua-side handle to a loaded font stored in SharedState.
---@class LFont
LFont = {}

--- Returns the ascent of this font in pixels.
---@return number
function LFont:getAscent() end

--- Returns the descent of this font in pixels.
---@return number
function LFont:getDescent() end

--- Returns the line height of this font.
---@return number
function LFont:getHeight() end

--- Returns the line height multiplier of this font.
---@return number
function LFont:getLineHeight() end

--- Returns the rendered width of the given text string.
---@param text string
---@return number
function LFont:getWidth(text) end

--- Wraps text to the given width and returns the lines.
---@param text string
---@param limit number
---@return nil
function LFont:getWrap(text, limit) end

--- Releases this font and frees its atlas memory.
---@return boolean
function LFont:release() end

--- Sets the line height multiplier for this font.
---@param height number
---@return nil
function LFont:setLineHeight(height) end

--- Returns the type name of this object.
---@return string
function LFont:type() end

--- Returns the type name of this object.
---@param name? string
---@return string
function LFont:typeOf(name) end

--- Lua-side handle to a loaded GPU texture stored in the engine's texture pool.
---@class LImage
LImage = {}

--- Returns width and height of this image.
---@return integer
---@return integer
function LImage:getDimensions() end

--- Returns the height of this image in pixels.
---@return number
function LImage:getHeight() end

--- Returns the width of this image in pixels.
---@return number
function LImage:getWidth() end

--- Releases the GPU texture memory for this image.
---@return boolean
function LImage:release() end

--- Returns the type name of this object.
---@return string
function LImage:type() end

--- Returns the type name of this object.
---@param name? string
---@return string
function LImage:typeOf(name) end

--- Lua-side handle to a loaded texture stored in SharedState.
---@class LImageData
LImageData = {}

--- Blits the source ImageData onto this image at (dst_x, dst_y) using Porter-Duff `over`.
---@param src ImageData
---@param dst_x integer
---@param dst_y integer
---@return nil
function LImageData:blit(src, dst_x, dst_y) end

--- Returns the sum of absolute per-channel differences between this image and `other`.
---@param other ImageData
---@return number
function LImageData:diff(other) end

--- Returns the pixel height of this image buffer.
---@return number
function LImageData:getHeight() end

--- Returns a copy of the rectangular sub-region as a new ImageData.
---@param x integer
---@param y integer
---@param width integer
---@param height integer
---@return nil
function LImageData:getRegion(x, y, width, height) end

--- Returns the pixel width of this image buffer.
---@return number
function LImageData:getWidth() end

--- Applies a Lua function to every pixel in-place.
---@param fn function
---@return nil
function LImageData:mapPixels(fn) end

--- Returns a new ImageData scaled to the given dimensions using bilinear interpolation.
---@param width integer
---@param height integer
---@return nil
function LImageData:resize(width, height) end

--- Returns the type name "ImageData".
---@return string
function LImageData:type() end

--- Returns true when the given name matches "ImageData" or a parent type.
---@param name string
---@return boolean
function LImageData:typeOf(name) end

--- Lua-side handle to a mesh stored in SharedState.
---@class LMesh
LMesh = {}

--- Returns vertex data at the given 1-based index.
---@param index integer
---@return nil
function LMesh:getVertex(index) end

--- Returns the number of vertices in this mesh.
---@return number
function LMesh:getVertexCount() end

--- Releases the GPU mesh resource, freeing VRAM immediately.
---@return boolean
function LMesh:release() end

--- Assigns a texture to this mesh.
---@param image? Image
---@return nil
function LMesh:setTexture(image) end

--- Sets vertex data at the given 1-based index.
---@param index integer
---@param data table
---@return nil
function LMesh:setVertex(index, data) end

--- Returns the type name of this object.
---@return string
function LMesh:type() end

--- Returns the type name of this object.
---@param name? string
---@return string
function LMesh:typeOf(name) end

--- Lua-side 9-slice descriptor.
---@class LNineSlice
LNineSlice = {}

--- Compatibility stub: queuing handled by lurek.graphic.drawNineSlice.
---@param x any
---@param y any
---@param w any
---@param h any
---@return nil
function LNineSlice:draw(x, y, w, h) end

--- Returns the four inset values as (top, right, bottom, left).
---@return number
---@return number
---@return number
---@return number
function LNineSlice:getInsets() end

--- Returns the width and height of the source texture.
---@return integer
---@return integer
function LNineSlice:getTextureSize() end

--- Returns the type name "NineSlice".
---@return string
function LNineSlice:type() end

--- Returns true when the given name matches "NineSlice" or a parent type.
---@param name string
---@return boolean
function LNineSlice:typeOf(name) end

--- Lua-side quad viewport into a texture.
---@class LQuad
LQuad = {}

--- Returns the reference texture dimensions.
---@return number
---@return number
function LQuad:getTextureDimensions() end

--- Returns the quad viewport rectangle.
---@return number
---@return number
---@return number
---@return number
function LQuad:getViewport() end

--- Sets the quad viewport rectangle.
---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function LQuad:setViewport(x, y, w, h) end

--- Returns the type name of this object.
---@return string
function LQuad:type() end

--- Returns the type name of this object.
---@param name? string
---@return string
function LQuad:typeOf(name) end

--- Lua-side handle to a compiled shader stored in SharedState.
---@class LShader
LShader = {}

--- Returns whether this shader has a uniform with the given name.
---@param name string
---@return boolean
function LShader:hasUniform(name) end

--- Releases the compiled GPU shader, freeing VRAM and shader slots.
---@return boolean
function LShader:release() end

--- Sends a uniform value to this shader.
---@param name string
---@param value number|table
---@return nil
function LShader:send(name, value) end

--- Returns the type name of this object.
---@return string
function LShader:type() end

--- Returns the type name of this object.
---@param name? string
---@return string
function LShader:typeOf(name) end

--- Lua-side handle to a [`CompoundShape`] stored in [`SharedState::shapes`].
---@class LShape
LShape = {}

--- Queues a filled or outlined arc draw command onto this shape.
---@param mode string
---@param x number
---@param y number
---@param r number
---@param astart number
---@param aend number
---@param segments? integer
---@return nil
function LShape:arc(mode, x, y, r, astart, aend, segments) end

--- Queues a filled or outlined circle draw command onto this shape.
---@param mode string
---@param x number
---@param y number
---@param r number
---@return nil
function LShape:circle(mode, x, y, r) end

--- Removes all commands and resets the shape to empty.
---@return nil
function LShape:clear() end

--- Queues a draw command for this shape at the given position.
---@param x number
---@param y number
---@param rotation? number
---@param sx? number
---@param sy? number
---@param ox? number
---@param oy? number
---@return nil
function LShape:draw(x, y, rotation, sx, sy, ox, oy) end

--- Queues an ellipse command.
---@param mode string
---@param x number
---@param y number
---@param rx number
---@param ry number
---@return nil
function LShape:ellipse(mode, x, y, rx, ry) end

--- Returns the number of drawing commands currently stored.
---@return number
function LShape:getCommandCount() end

--- Queues a line segment command.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return nil
function LShape:line(x1, y1, x2, y2) end

--- Queues a polygon command from variadic (x, y) coordinate pairs.
---@param mode string
---@param ... number
---@return nil
function LShape:polygon(mode, ...) end

--- Queues a polyline command from variadic (x, y) coordinate pairs.
---@param ... number
---@return nil
function LShape:polyline(...) end

--- Queues a rectangle command.
---@param mode string
---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function LShape:rectangle(mode, x, y, w, h) end

--- Queues a rounded rectangle command.
---@param mode string
---@param x number
---@param y number
---@param w number
---@param h number
---@param rx number
---@param ry? number
---@return nil
function LShape:roundedRectangle(mode, x, y, w, h, rx, ry) end

--- Sets the drawing color for subsequent primitives.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LShape:setColor(r, g, b, a) end

--- Sets the stroke width for subsequent outlined primitives.
---@param w number
---@return nil
function LShape:setLineWidth(w) end

--- Queues a triangle command.
---@param mode string
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@return nil
function LShape:triangle(mode, x1, y1, x2, y2, x3, y3) end

--- Returns the type name of this object.
---@return string
function LShape:type() end

--- Returns true if the given type name matches this object's type or any parent type.
---@param name string
---@return boolean
function LShape:typeOf(name) end

--- Lua-side handle to a sprite batch stored in SharedState.
---@class LSpriteBatch
LSpriteBatch = {}

--- Adds a sprite entry to this batch.
---@param x number
---@param y number
---@param r? number
---@param sx? number
---@param sy? number
---@param ox? number
---@param oy? number
---@return number
function LSpriteBatch:add(x, y, r, sx, sy, ox, oy) end

--- Removes all sprites from this batch.
---@return nil
function LSpriteBatch:clear() end

--- Returns the maximum capacity of this batch.
---@return number
function LSpriteBatch:getBufferSize() end

--- Returns the number of sprites in this batch.
---@return number
function LSpriteBatch:getCount() end

--- Releases this sprite batch.
---@return boolean
function LSpriteBatch:release() end

--- Returns the type name of this object.
---@return string
function LSpriteBatch:type() end

--- Returns the type name of this object.
---@param name? string
---@return string
function LSpriteBatch:typeOf(name) end

--- Applies an affine transform matrix.
---@param matrix table
lurek.render.applyTransform = function(matrix) end

--- Draws a partial circle arc at the given position with specified radius and angle range.
---@param mode string
---@param x number
---@param y number
---@param radius number
---@param angle1 number
---@param angle2 number
---@param segments? integer
lurek.render.arc = function(mode, x, y, radius, angle1, angle2, segments) end

--- Begins a Y/Z depth sort group. Draw commands until flushSortGroup are depth-sortable.
---@param id integer
lurek.render.beginSortGroup = function(id) end

--- Begins a Y/Z depth sort group identified by id.
---@param id integer
lurek.render.beginSortGroup = function(id) end

--- Calls the given callback with an ImageData captured from the current frame (stub: creates blank).
---@param callback function(ImageData)
---@return nil
lurek.render.captureScreenshot = function(callback) end

--- Draws a filled or outlined circle at the given world-space position.
---@param mode string
---@param x number
---@param y number
---@param radius number
lurek.render.circle = function(mode, x, y, radius) end

--- Clears the draw command queue (resets the screen).
---@param r? number
---@param g? number
---@param b? number
lurek.render.clear = function(r, g, b) end

--- Resets the stencil mode to the default (keep / always / 0).
---@return nil
lurek.render.clearStencil = function() end

--- Returns the name of the currently active named layer.
---@return string
lurek.render.currentLayer = function() end

--- Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
---@param ... Image|Canvas|SpriteBatch|Mesh|number|nil
---@return table
lurek.render.draw = function(...) end

--- Queues a beveled border rectangle with inner fill.
---@param x number
---@param y number
---@param w number
---@param h number
---@param bevelW? number
---@param style? string
---@param opts? table
lurek.render.drawBevelRect = function(x, y, w, h, bevelW, style, opts) end

--- Queues a beveled border rectangle.
---@param x number
---@param y number
---@param w number
---@param h number
---@param bevelW? number
---@param style? string
---@param opts? table
lurek.render.drawBevelRect = function(x, y, w, h, bevelW, style, opts) end

--- Queues a convex polygon with per-vertex colours.
---@param vertices table
---@param colors table
---@param mode? string
lurek.render.drawColoredPolygon = function(vertices, colors, mode) end

--- Queues a convex polygon with per-vertex colours.
---@param vertices table
---@param colors table
---@param mode? string
lurek.render.drawColoredPolygon = function(vertices, colors, mode) end

--- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
---@param x1 number
---@param y1 number
---@param cx1 number
---@param cy1 number
---@param cx2 number
---@param cy2 number
---@param x2 number
---@param y2 number
---@param segments? integer
lurek.render.drawCubicBezier = function(x1, y1, cx1, cy1, cx2, cy2, x2, y2, segments) end

--- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
---@param x1 number
---@param y1 number
---@param cx1 number
---@param cy1 number
---@param cx2 number
---@param cy2 number
---@param x2 number
---@param y2 number
---@param segments? integer
lurek.render.drawCubicBezier = function(x1, y1, cx1, cy1, cx2, cy2, x2, y2, segments) end

--- Queues a gradient-filled rectangle. color1/color2 are {r,g,b,a} tables.
---@param x number
---@param y number
---@param w number
---@param h number
---@param color1 table
---@param color2 table
---@param direction? string
lurek.render.drawGradientRect = function(x, y, w, h, color1, color2, direction) end

--- Queues a gradient-filled rectangle. Both colors are RGBA tables {r,g,b,a} or positional {[1]=r,[2]=g,[3]=b,[4]=a}.
---@param x number
---@param y number
---@param w number
---@param h number
---@param color1 table
---@param color2 table
---@param direction? string
lurek.render.drawGradientRect = function(x, y, w, h, color1, color2, direction) end

--- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
---@param cx number
---@param cy number
---@param size number
---@param orientation? string
---@param mode? string
lurek.render.drawHexTile = function(cx, cy, size, orientation, mode) end

--- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
---@param cx number
---@param cy number
---@param size number
---@param orientation? string
---@param mode? string
lurek.render.drawHexTile = function(cx, cy, size, orientation, mode) end

--- Queues a three-face isometric cube tile at screen position (sx, sy).
---@param sx number
---@param sy number
---@param halfW number
---@param halfH number
---@param opts? table
lurek.render.drawIsoCubeTile = function(sx, sy, halfW, halfH, opts) end

--- Queues a three-face isometric cube tile at screen position (sx, sy).
---@param sx number
---@param sy number
---@param halfW number
---@param halfH number
---@param opts? table
lurek.render.drawIsoCubeTile = function(sx, sy, halfW, halfH, opts) end

--- Queues a 9-slice draw call inside lurek.draw / lurek.draw_ui.
---@param slice NineSlice
---@param x number
---@param y number
---@param width number
---@param height number
---@return nil
lurek.render.drawNineSlice = function(slice, x, y, width, height) end

--- Queues a multi-segment vector path.
---@param path table
---@param mode? string
---@param close? boolean
lurek.render.drawPath = function(path, mode, close) end

--- Queues a multi-segment vector path.
---@param path table
---@param mode? string
---@param close? boolean
lurek.render.drawPath = function(path, mode, close) end

--- Queues a quadratic BĂ©zier curve from (x1,y1) to (x2,y2) with one control point.
---@param x1 number
---@param y1 number
---@param cx number
---@param cy number
---@param x2 number
---@param y2 number
---@param segments? integer
lurek.render.drawQuadBezier = function(x1, y1, cx, cy, x2, y2, segments) end

--- Must be called inside lurek.draw or lurek.draw_ui.
---@param x1 number
---@param y1 number
---@param cx number
---@param cy number
---@param x2 number
---@param y2 number
---@param segments? integer
lurek.render.drawQuadBezier = function(x1, y1, cx, cy, x2, y2, segments) end

--- Draws a portion of an image defined by a Quad.
---@param image Image
---@param quad Quad
---@param x? number
---@param y? number
---@param r? number
---@param sx? number
---@param sy? number
---@param ox? number
---@param oy? number
lurek.render.drawq = function(image, quad, x, y, r, sx, sy, ox, oy) end

--- Draws a filled or outlined ellipse with independent x/y radii.
---@param mode string
---@param x number
---@param y number
---@param rx number
---@param ry number
lurek.render.ellipse = function(mode, x, y, rx, ry) end

--- Sorts and flushes all draw commands in the sort group.
---@param id integer
lurek.render.flushSortGroup = function(id) end

--- Sorts and flushes all draw commands in the sort group.
---@param id integer
lurek.render.flushSortGroup = function(id) end

--- Returns the current background color.
---@return number
---@return number
---@return number
---@return number
lurek.render.getBackgroundColor = function() end

--- Returns the current blend mode as a string.
---@return string
lurek.render.getBlendMode = function() end

--- Returns the current canvas, or nil if drawing to screen.
---@return table
lurek.render.getCanvas = function() end

--- Returns the dimensions of a canvas.
---@param canvas Canvas
---@return integer
---@return integer
lurek.render.getCanvasSize = function(canvas) end

--- Returns the current drawing color.
---@return number
---@return number
---@return number
---@return number
lurek.render.getColor = function() end

--- Returns the current color mask.
lurek.render.getColorMask = function() end

--- Returns the default texture filter mode.
---@return table
lurek.render.getDefaultFilter = function() end

--- Returns a built-in font by pixel height (snaps to nearest available size).
---@param pixel_height? number
---@return Font
lurek.render.getDefaultFont = function(pixel_height) end

--- Returns the current depth mode as (mode, write).
---@return table
lurek.render.getDepthMode = function() end

--- Returns window width and height.
---@return integer
---@return integer
lurek.render.getDimensions = function() end

--- Returns the currently active font, or nil.
---@return table
lurek.render.getFont = function() end

--- Returns the ascent of the given font.
---@param font Font
---@return number
lurek.render.getFontAscent = function(font) end

--- Returns the cell width of the given font (for monospaced bitmap fonts).
---@param font Font
---@return number
lurek.render.getFontCellWidth = function(font) end

--- Returns the descent of the given font.
---@param font Font
---@return number
lurek.render.getFontDescent = function(font) end

--- Returns the line height of the given font.
---@param font Font
---@return number
lurek.render.getFontHeight = function(font) end

--- Returns the line height of the given font (alias for getFontHeight).
---@param font Font
---@return number
lurek.render.getFontLineHeight = function(font) end

--- Returns a table of available built-in font pixel heights.
---@return table
lurek.render.getFontSizes = function() end

--- Returns the pixel width of text in the given font.
---@param font Font
---@param text string
---@return number
lurek.render.getFontWidth = function(font, text) end

--- Returns wrapped lines and the maximum line width.
---@param text string
---@param limit number
---@return table
lurek.render.getFontWrap = function(text, limit) end

--- Returns the window height in pixels.
---@return number
lurek.render.getHeight = function() end

--- Returns the z-order of the named layer, or `0` if unregistered.
---@param name string
---@return number
lurek.render.getLayerZOrder = function(name) end

--- Returns the current line width.
---@return number
lurek.render.getLineWidth = function() end

--- Returns the current point size.
---@return number
lurek.render.getPointSize = function() end

--- Returns the active scissor rectangle, or nothing.
---@return table
lurek.render.getScissor = function() end

--- Returns the active shader, or nil.
---@return table
lurek.render.getShader = function() end

--- Returns a table of renderer statistics.
---@return table
lurek.render.getStats = function() end

--- Returns the current stencil mode as (action, compare, value).
---@return table
lurek.render.getStencilMode = function() end

--- Returns the window width in pixels.
---@return number
lurek.render.getWidth = function() end

--- Intersects the current scissor with a new rectangle.
---@param x number
---@param y number
---@param w number
---@param h number
lurek.render.intersectScissor = function(x, y, w, h) end

--- Returns `true` if the named layer is visible (default: `true`).
---@param name string
---@return boolean
lurek.render.isLayerVisible = function(name) end

--- Returns whether wireframe mode is active.
---@return boolean
lurek.render.isWireframe = function() end

--- Draws a line between two points.
---@param ... number
lurek.render.line = function(...) end

--- Creates an off-screen render canvas.
---@param width integer
---@param height integer
---@return Canvas
lurek.render.newCanvas = function(width, height) end

--- Creates a new z-ordered draw-call queue.
---@return DrawLayer
lurek.render.newDrawLayer = function() end

--- Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
---@param ... string|number|number|nil
---@return Font
lurek.render.newFont = function(...) end

--- Loads an image from a file path or creates one from ImageData.
---@param path_or_data string|ImageData
---@return Image
lurek.render.newImage = function(path_or_data) end

--- Registers a named render layer with an optional z-order (default 0).
---@param name string
---@param z_order? integer
---@return nil
lurek.render.newLayer = function(name, z_order) end

--- Creates a custom mesh from vertex data.
---@param vertices table
---@param mode? string
---@return Mesh
lurek.render.newMesh = function(vertices, mode) end

--- Creates a 9-slice descriptor from a texture and inset values.
---@param image Image
---@param top number
---@param right number
---@param bottom number
---@param left number
---@return NineSlice
lurek.render.newNineSlice = function(image, top, right, bottom, left) end

--- Creates a new Quad viewport into a texture.
---@param x number
---@param y number
---@param w number
---@param h number
---@param sw number
---@param sh number
---@return Quad
lurek.render.newQuad = function(x, y, w, h, sw, sh) end

--- Compiles a custom WGSL shader and returns its handle.
---@param code string
---@return Shader
lurek.render.newShader = function(code) end

--- Creates a new empty [`CompoundShape`] stored in the resource pool.
---@return Shape
lurek.render.newShape = function() end

--- Creates a new sprite batch for the given image.
---@param image Image
---@param max_sprites? integer
---@return SpriteBatch
lurek.render.newSpriteBatch = function(image, max_sprites) end

--- Resets the transform to the identity.
lurek.render.origin = function() end

--- Draws a batch of individual points at the specified world-space coordinates.
---@param ... number|table
lurek.render.points = function(...) end

--- Draws a polygon from a list of vertices.
---@param mode string
---@param ... number
lurek.render.polygon = function(mode, ...) end

--- Pops the transform from the stack.
lurek.render.pop = function() end

--- Ends and composites the named layer back to its parent.
---@param id integer
lurek.render.popLayer = function(id) end

--- Ends and composites the named layer.
---@param id integer
lurek.render.popLayer = function(id) end

--- Draws text at the given position.
---@param text string
---@param x? number
---@param y? number
---@param scale? number
lurek.render.print = function(text, x, y, scale) end

--- Draws a sequence of individually-styled text spans at `(x, y)`.
---@param spans table[]
---@param x number
---@param y number
lurek.render.printRich = function(spans, x, y) end

--- Draws word-wrapped text within a given width.
---@param text string
---@param x number
---@param y number
---@param limit number
---@param align? string
lurek.render.printf = function(text, x, y, limit, align) end

--- Pushes the current transform onto the stack.
lurek.render.push = function() end

--- Begins a named compositing layer with optional alpha and blend mode.
---@param id integer
---@param alpha? number
---@param blendMode? string
lurek.render.pushLayer = function(id, alpha, blendMode) end

--- Begins a named compositing layer. Provides alpha and blend mode for composite.
---@param id integer
---@param alpha? number
---@param blendMode? string
lurek.render.pushLayer = function(id, alpha, blendMode) end

--- Associates the previous draw command with a depth value within the active sort group.
---@param depth number
lurek.render.pushSortKey = function(depth) end

--- Associates the previous draw command with a depth value within the active sort group.
---@param depth number
lurek.render.pushSortKey = function(depth) end

--- Draws a filled or outlined axis-aligned rectangle at the given position.
---@param mode string
---@param x number
---@param y number
---@param w number
---@param h number
---@param rx? number
---@param ry? number
lurek.render.rectangle = function(mode, x, y, w, h, rx, ry) end

--- Rotates the coordinate system.
---@param angle number
lurek.render.rotate = function(angle) end

--- Queues a screenshot to be saved after the current frame.
---@param path string
lurek.render.saveScreenshot = function(path) end

--- Scales the coordinate system.
---@param sx number
---@param sy? number
lurek.render.scale = function(sx, sy) end

--- Sets the background clear color.
---@param r number
---@param g number
---@param b number
lurek.render.setBackgroundColor = function(r, g, b) end

--- Sets the blend mode for drawing.
---@param mode string
lurek.render.setBlendMode = function(mode) end

--- Sets the active render target to a Canvas, or back to the screen.
---@param canvas? Canvas
lurek.render.setCanvas = function(canvas) end

--- Sets the current drawing color.
---@param r number
---@param g number
---@param b number
---@param a? number
lurek.render.setColor = function(r, g, b, a) end

--- Sets which RGBA channels are written. Reset with no args.
---@param ... boolean|nil
lurek.render.setColorMask = function(...) end

--- Sets the default texture filter mode.
---@param min string
---@param mag string
---@param anisotropy? integer
lurek.render.setDefaultFilter = function(min, mag, anisotropy) end

--- Sets the depth test comparison and write enable.
---@param mode string
---@param write? boolean? â€” default false
lurek.render.setDepthMode = function(mode, write) end

--- Sets the active font for print calls.
---@param font Font
lurek.render.setFont = function(font) end

--- Sets the line height of the given font (stub â€” returns nil; fonts are immutable in headless mode).
---@param font Font
---@param line_height number
---@return nil
lurek.render.setFontLineHeight = function(font, line_height) end

--- Sets the active named layer. Draw calls made after this will be
---@param name string
---@return nil
lurek.render.setLayer = function(name) end

--- Shows or hides the named layer. Hidden layers are excluded from
---@param name string
---@param visible boolean
---@return nil
lurek.render.setLayerVisible = function(name, visible) end

--- Updates the z-order of the named layer. Auto-creates the layer if
---@param name string
---@param z_order integer
---@return nil
lurek.render.setLayerZOrder = function(name, z_order) end

--- Sets the line width for outline drawing.
---@param width number
lurek.render.setLineWidth = function(width) end

--- Sets the point diameter in pixels.
---@param size number
lurek.render.setPointSize = function(size) end

--- Restricts drawing to a rectangle, or clears scissor if no args.
---@param ... number|nil
lurek.render.setScissor = function(...) end

--- Sets the active shader, or clears it.
---@param shader? Shader
lurek.render.setShader = function(shader) end

--- Sets the stencil buffer write/test mode.
---@param action string
---@param compare? string? â€” "always"|"equal"|"notequal"|"less"|"lequal"|"greater"|"gequal"
---@param value? integer
lurek.render.setStencilMode = function(action, compare, value) end

--- Sets the stencil comparison test, or disables stencil testing.
---@param compare? string
---@param value? integer
lurek.render.setStencilTest = function(compare, value) end

--- Enables or disables wireframe rendering.
---@param enabled boolean
lurek.render.setWireframe = function(enabled) end

--- Shears the coordinate system.
---@param kx number
---@param ky number
lurek.render.shear = function(kx, ky) end

--- Begins stencil writing with the given action and value.
---@param action? string
---@param value? integer
lurek.render.stencil = function(action, value) end

--- Translates the coordinate system.
---@param x number
---@param y number
lurek.render.translate = function(x, y) end

--- Draws a filled or outlined triangle connecting three world-space vertices.
---@param mode string
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
lurek.render.triangle = function(mode, x1, y1, x2, y2, x3, y3) end

---@class lurek.save
lurek.save = {}

--- Lua-side wrapper around [`SaveManager`] with per-module callback storage.
---@class LSaveManager
LSaveManager = {}

--- Registers a migration function for upgrading from a schema version
---@param from_version integer
---@param func function
---@return nil
function LSaveManager:addMigration(from_version, func) end

--- Collects data from all registered collectors into a table with metadata
---@return table
function LSaveManager:collect() end

--- Deletes a save file for the given slot.
---@param slot string
---@return nil
function LSaveManager:delete(slot) end

--- Disables automatic periodic saving; manual `write()` calls still work.
---@return nil
function LSaveManager:disableAutoSave() end

--- Enables auto-save with a given interval and target slot
---@param interval number
---@param slot string
---@return nil
function LSaveManager:enableAutoSave(interval, slot) end

--- Returns whether a save file exists for the given slot.
---@param slot string
---@return boolean
function LSaveManager:exists(slot) end

--- Returns the current schema version
---@return number
function LSaveManager:getSchemaVersion() end

--- Returns metadata for a single slot, or nil if not found.
---@param slot string
---@return table
function LSaveManager:getSlotInfo(slot) end

--- Returns a list of all save slots with metadata.
---@return table
function LSaveManager:getSlots() end

--- Returns the current summary string
---@return string
function LSaveManager:getSummary() end

--- Returns whether compression is currently enabled.
---@return boolean
function LSaveManager:isCompressed() end

--- Returns whether data has been modified since the last save or load
---@return boolean
function LSaveManager:isDirty() end

--- Loads data from a slot file, applies migrations, and restores.
---@param slot string
---@return nil
function LSaveManager:load(slot) end

--- Marks data as modified since the last save or load
---@return nil
function LSaveManager:markDirty() end

--- Registers a callback that fires after every successful load operation.
---@param func? function
---@return nil
function LSaveManager:onAfterLoad(func) end

--- Registers a callback that fires before every save operation.
---@param func? function
---@return nil
function LSaveManager:onBeforeSave(func) end

--- Registers a named module with collector and restorer callbacks
---@param name string
---@param collector function
---@param restorer function
---@return nil
function LSaveManager:register(name, collector, restorer) end

--- Resets all state, removing callbacks and clearing the manager
---@return nil
function LSaveManager:reset() end

--- Restores data from a table, applying migrations and calling restorers
---@param data table
---@return nil
function LSaveManager:restore(data) end

--- Collects data and writes it to a slot file.
---@param slot string
---@return nil
function LSaveManager:save(slot) end

--- Enables or disables LZ4 compression for saved data
---@param enabled boolean
---@return nil
function LSaveManager:setCompress(enabled) end

--- Sets the current schema version for new saves
---@param version integer
---@return nil
function LSaveManager:setSchemaVersion(version) end

--- Sets the summary string included in save metadata
---@param summary string
---@return nil
function LSaveManager:setSummary(summary) end

--- Returns the type name of this object.
---@return string
function LSaveManager:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSaveManager:typeOf(name) end

--- Removes a named module and its callbacks
---@param name string
---@return nil
function LSaveManager:unregister(name) end

--- Advances the auto-save timer, returning the slot name if a save should trigger
---@param dt number
---@return string
function LSaveManager:update(dt) end

--- Creates a new SaveManager for slot-based save/load operations.
---@return SaveManager
lurek.save.newSaveManager = function() end

---@class lurek.scene
lurek.scene = {}

--- Lua-side wrapper around a [`DepthSorter`] with registry-stored callbacks.
---@class LDepthSorter
LDepthSorter = {}

--- Registers a draw callback at the given depth layer.
---@param callback function
---@param depth number
---@return nil
function LDepthSorter:add(callback, depth) end

--- Registers a table object with a draw method at the given depth.
---@param obj table
---@return nil
function LDepthSorter:addObject(obj) end

--- Removes all registered callbacks without calling them.
---@return nil
function LDepthSorter:clear() end

--- Calls all draw callbacks in sorted depth order, then clears.
---@return nil
function LDepthSorter:flush() end

--- Returns the number of registered draw entries.
---@return number
function LDepthSorter:getCount() end

--- Returns true if stable sort mode is enabled.
---@return boolean
function LDepthSorter:isStable() end

--- Sets whether equal-depth entries preserve insertion order.
---@param stable boolean
---@return nil
function LDepthSorter:setStable(stable) end

--- Sorts all registered callbacks by depth ascending.
---@return nil
function LDepthSorter:sort() end

--- Returns the type name of this object.
---@return string
function LDepthSorter:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LDepthSorter:typeOf(name) end

--- Clears all scenes from the stack, calling leave on each.
---@return nil
lurek.scene.clear = function() end

--- Creates a reusable scene class â€” returns a zero-argument constructor function.
---@param def? table
---@return function
lurek.scene.define = function(def) end

--- Returns the number of scenes on the stack.
---@return number
lurek.scene.depth = function() end

--- Restores scene data_refs from a snapshot produced by serializeScene().
---@param snapshot table
---@return nil
lurek.scene.deserializeScene = function(snapshot) end

--- Draws all scenes in the stack from bottom to top (legacy name; prefer `render`).
---@return nil
lurek.scene.draw = function() end

--- Returns a fade cross-dissolve transition config table.
---@param duration? number
---@return table
lurek.scene.fade = function(duration) end

--- Returns a table array of all active scene tables.
---@return table
lurek.scene.getActiveScenes = function() end

--- Returns the current top scene table, or nil if the stack is empty.
---@return table
lurek.scene.getCurrent = function() end

--- Returns a value from the inter-scene data store, or nil if not found.
---@param key string
---@return table
lurek.scene.getData = function(key) end

--- Returns a registered scene table by name, or nil if not found.
---@param name string
---@return table
lurek.scene.getRegistered = function(name) end

--- Returns a list of all registered scene names.
---@return table
lurek.scene.getRegisteredNames = function() end

--- Returns the number of scenes on the stack.
---@return number
lurek.scene.getStackSize = function() end

--- Returns the transition progress from 0.0 to 1.0.
---@return number
lurek.scene.getTransitionProgress = function() end

--- Returns the easing-adjusted transition progress from 0.0 to 1.0.
---@return number
lurek.scene.getTransitionProgressEased = function() end

--- Returns a table listing all supported transition type strings.
---@return table
lurek.scene.getTransitionTypes = function() end

--- Returns true if the given key exists in the data store.
---@param key string
---@return boolean
lurek.scene.hasData = function(key) end

--- Returns true if a scene is registered under the given name.
---@param name string
---@return boolean
lurek.scene.hasRegistered = function(name) end

--- Returns an iris in/out (circular reveal) transition config table.
---@param duration? number
---@return table
lurek.scene.iris = function(duration) end

--- Returns true if the scene stack is empty.
---@return boolean
lurek.scene.isEmpty = function() end

--- Returns true if the current top scene was pushed as an overlay.
---@return boolean
lurek.scene.isOverlay = function() end

--- Returns true if the named scene has been preloaded.
---@param name string
---@return boolean
lurek.scene.isPreloaded = function(name) end

--- Returns true if a scene transition is currently active.
---@return boolean
lurek.scene.isTransitioning = function() end

--- Creates a scene instance directly from a methods table.
---@param def? table
---@return table
lurek.scene.new = function(def) end

--- Creates a new DepthSorter for z-ordered draw batching.
---@return DepthSorter
lurek.scene.newDepthSorter = function() end

--- Alias for `lurek.scene.new`. Creates a scene instance from a methods table.
---@param def? table
---@return table
lurek.scene.newScene = function(def) end

--- Pops the top scene from the stack with an optional transition and easing.
---@param transition? string
---@param duration? number
---@param easing? string
---@return nil
lurek.scene.pop = function(transition, duration, easing) end

--- Pops scenes until the named scene is on top, calling leave on each removed.
---@param name string
---@return boolean
lurek.scene.popTo = function(name) end

--- Registers a loader function for a named scene. The loader is called
---@param name string
---@param loader function
---@return nil
lurek.scene.preload = function(name, loader) end

--- Calls `scene:ready(self)` once per scene on the first tick after enter,
---@param dt number
---@return nil
lurek.scene.process = function(dt) end

--- Calls `scene:process_late(dt)` on all active scenes (after process, before render).
---@param dt number
---@return nil
lurek.scene.processLate = function(dt) end

--- Calls `scene:process_physics(dt)` on all active scenes (fixed timestep).
---@param dt number
---@return nil
lurek.scene.processPhysics = function(dt) end

--- Pushes a scene table onto the stack with an optional transition and easing.
---@param scene table
---@param transition? string
---@param duration? number
---@param easing? string
---@param params? table
---@return nil
lurek.scene.push = function(scene, transition, duration, easing, params) end

--- Pushes a scene as a non-pausing overlay over the current top scene.
---@param scene table
---@param transition? string
---@param duration? number
---@param easing? string
---@param params? table
---@return nil
lurek.scene.pushOverlay = function(scene, transition, duration, easing, params) end

--- Pushes a registered scene by name, running its loader if not yet preloaded.
---@param name string
---@param transition? string
---@param duration? number
---@param easing? string
---@param params? table
---@return nil
lurek.scene.pushPreloaded = function(name, transition, duration, easing, params) end

--- Registers a scene table by name for later retrieval.
---@param name string
---@param scene table
---@return nil
lurek.scene.registerScene = function(name, scene) end

--- Removes a value from the inter-scene data store by key.
---@param key string
---@return nil
lurek.scene.removeData = function(key) end

--- Draws all scenes in the stack from bottom to top.
---@return nil
lurek.scene.render = function() end

--- Draws UI overlay for all scenes in the stack from bottom to top.
---@return nil
lurek.scene.renderUi = function() end

--- Returns a snapshot of the scene stack as a Lua table: { stack=[name...], data={key=val} }.
---@return table
lurek.scene.serializeScene = function() end

--- Stores a value in the inter-scene data store under the given key.
---@param key string
---@param value table
---@return nil
lurek.scene.setData = function(key, value) end

--- Returns a directional slide transition config table.
---@param direction? string
---@param duration? number
---@return table
lurek.scene.slide = function(direction, duration) end

--- Replaces the top scene with a new one, calling leave and enter callbacks.
---@param scene table
---@param transition? string
---@param duration? number
---@param easing? string
---@param params? table
---@return nil
lurek.scene.switchTo = function(scene, transition, duration, easing, params) end

--- Removes a scene from the registry by name.
---@param name string
---@return nil
lurek.scene.unregisterScene = function(name) end

--- Updates the top scene and any active transition (legacy name; prefer `process`).
---@param dt number
---@return nil
lurek.scene.update = function(dt) end

--- Returns a wipe/curtain transition config table.
---@param duration? number
---@return table
lurek.scene.wipe = function(duration) end

---@class lurek.serial
lurek.serial = {}

--- Decodes a binary MessagePack string into a Lua table.
---@param bytes string
---@return table
lurek.serial.decodeMsgPack = function(bytes) end

--- Parses an XML string and returns a nested Lua table.
---@param s string
---@return table
lurek.serial.decodeXml = function(s) end

--- Encodes a Lua table to a binary MessagePack string.
---@param value any
---@return string
lurek.serial.encodeMsgPack = function(value) end

--- Parses a CSV string and returns a sequence of row tables.
---@param s string
---@param delimiter? string
---@param has_headers? boolean
---@return table
lurek.serial.fromCsv = function(s, delimiter, has_headers) end

--- Parses a JSON string and returns a Lua table.
---@param s string
---@return table
lurek.serial.fromJson = function(s) end

--- Parses a TOML string and returns a Lua table.
---@param s string
---@return table
lurek.serial.fromToml = function(s) end

--- Serializes a sequence of row tables to a CSV string.
---@param value any
---@param delimiter? string
---@param has_headers? boolean
---@return string
lurek.serial.toCsv = function(value, delimiter, has_headers) end

--- Serializes a Lua value to a JSON string.
---@param value any
---@param pretty? boolean
---@return string
lurek.serial.toJson = function(value, pretty) end

--- Serializes a Lua table to a TOML string.
---@param value any
---@return string
lurek.serial.toToml = function(value) end

--- Validates a Lua table against a schema table.
---@param value any
---@param schema table
lurek.serial.validate = function(value, schema) end

---@class lurek.spine
lurek.spine = {}

--- Lua-side wrapper around a [`Skeleton`].
---@class LSkeleton
LSkeleton = {}

--- Adds a SkeletonAnimation to this skeleton's library.
---@param anim SkeletonAnimation
---@return nil
function LSkeleton:addAnimation(anim) end

--- Adds a root bone with optional local transform and returns its index.
---@param name string
---@param opts? table
---@return number
function LSkeleton:addBone(name, opts) end

--- Adds a child bone attached to a parent and returns its index.
---@param name string
---@param parent_idx integer
---@param opts? table
---@return number
function LSkeleton:addChildBone(name, parent_idx, opts) end

--- Adds a two-bone IK constraint and returns its index.
---@param name string
---@param bone_chain table
---@param bend_positive? boolean
---@return number
function LSkeleton:addIKConstraint(name, bone_chain, bend_positive) end

--- Registers a new empty skin by name.
---@param name string
---@return nil
function LSkeleton:addSkin(name) end

--- Adds a slot bound to a bone and returns its index.
---@param name string
---@param bone_idx integer
---@param attachment? string
---@return number
function LSkeleton:addSlot(name, bone_idx, attachment) end

--- Evaluates `anim` at `time` and blends the result into this skeleton
---@param anim SkeletonAnimation
---@param time number
---@param blend_weight? number
---@return nil
function LSkeleton:blendAnimation(anim, time, blend_weight) end

--- Returns the total number of bones.
---@return number
function LSkeleton:boneCount() end

--- Renders the skeleton as a stick-figure debug view into a new ImageData.
---@param width integer
---@param height integer
---@return ImageData
function LSkeleton:drawToImage(width, height) end

--- Returns the index of the named bone, or nil if not found.
---@param name string
---@return number
function LSkeleton:findBone(name) end

--- Returns the index of the named slot, or nil if not found.
---@param name string
---@return number
function LSkeleton:findSlot(name) end

--- Returns the current playback time in seconds of the active animation.
---@return number
function LSkeleton:getAnimationTime() end

--- Returns the world-space transform of a bone as a table, or nil if out of range.
---@param idx integer
---@return table
function LSkeleton:getBoneWorld(idx) end

--- Returns the name of the currently active skin, or nil.
---@return string
function LSkeleton:getSkin() end

--- Starts playback of the named skeletal animation clip.
---@param name string
---@param looping? boolean
---@return boolean
function LSkeleton:playAnimation(name, looping) end

--- Sets the world-space target position for the named IK constraint.
---@param name string
---@param x number
---@param y number
---@return boolean
function LSkeleton:setIKTarget(name, x, y) end

--- Sets the root bone position and propagates world transforms.
---@param x number
---@param y number
---@return nil
function LSkeleton:setPosition(x, y) end

--- Activates the named skin for attachment lookups.
---@param name string
---@return boolean
function LSkeleton:setSkin(name) end

--- Registers a slot-to-attachment mapping in the named skin.
---@param skin string
---@param slot string
---@param attachment string
---@return nil
function LSkeleton:setSkinMapping(skin, slot, attachment) end

--- Returns the total number of slots.
---@return number
function LSkeleton:slotCount() end

--- Stops the current skeletal animation.
---@return nil
function LSkeleton:stopAnimation() end

--- Returns the type name of this object.
---@return string
function LSkeleton:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSkeleton:typeOf(name) end

--- Advances the playing animation by `dt` seconds and applies keyframes.
---@param dt number
---@return nil
function LSkeleton:updateAnimation(dt) end

--- Propagates local transforms down the bone hierarchy to compute world positions.
---@return nil
function LSkeleton:updateWorldTransforms() end

--- Lua-side wrapper around a [`SkeletonAnimation`] keyframe clip.
---@class LSkeletonAnimation
LSkeletonAnimation = {}

--- Adds a named event marker at `time` seconds in the animation.
---@param time number
---@param name string
---@param value? number
---@return nil
function LSkeletonAnimation:addEventKey(time, name, value) end

--- Adds a keyframe to the bone timeline for the given property and bone index.
---@param bone_idx integer
---@param property string
---@param time number
---@param value number
---@param easing? string
---@return nil
function LSkeletonAnimation:addKeyframe(bone_idx, property, time, value, easing) end

--- Returns the total duration of the animation in seconds.
---@return number
function LSkeletonAnimation:getDuration() end

--- Returns a list of event names that fall in the half-open interval `(from, to]`.
---@param from number
---@param to number
---@return nil
function LSkeletonAnimation:getEvents(from, to) end

--- Returns the number of bone timelines in this animation.
---@return number
function LSkeletonAnimation:getTimelineCount() end

--- Returns the type name of this object.
---@return string
function LSkeletonAnimation:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSkeletonAnimation:typeOf(name) end

--- Creates a new empty skeleton with the given name.
---@param name string
---@return Skeleton
lurek.spine.newSkeleton = function(name) end

--- Creates a new empty SkeletonAnimation clip with the given name and duration.
---@param name string
---@param duration number
---@return SkeletonAnimation
lurek.spine.newSkeletonAnimation = function(name, duration) end

---@class lurek.sprite
lurek.sprite = {}

--- Lua-side wrapper around a [`SpriteAtlas`] named-region store.
---@class LSpriteAtlas
LSpriteAtlas = {}

--- Returns the total number of named regions in the atlas.
---@return number
function LSpriteAtlas:entryCount() end

--- Returns a sequential table of all region names.
---@return table
function LSpriteAtlas:entryNames() end

--- Returns the region at the given 1-based insertion index, or nil.
---@param index integer
---@return table
function LSpriteAtlas:getByIndex(index) end

--- Returns the named region as a table `{name, x, y, w, h, rotated}`, or nil.
---@param name string
---@return table
function LSpriteAtlas:getEntry(name) end

--- Returns a copy of the named region with `flip_x` and `flip_y` flags set.
---@param name string
---@param flip_x boolean
---@param flip_y boolean
---@return table
function LSpriteAtlas:getFlipped(name, flip_x, flip_y) end

--- Returns the type name of this object.
---@return string
function LSpriteAtlas:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSpriteAtlas:typeOf(name) end

--- Lua-side wrapper around a [`SpriteSheet`] frame-grid calculator.
---@class LSpriteSheet
LSpriteSheet = {}

--- Renders the sheet grid as a debug view into a new ImageData.
---@param width integer
---@param height integer
---@return ImageData
function LSpriteSheet:drawToImage(width, height) end

--- Returns a sequential table of quad tables for every frame in the given column.
---@param col integer
---@return table
function LSpriteSheet:getColumn(col) end

--- Returns the quad for the 0-based frame index, or nil if out of range.
---@param index integer
---@return table
function LSpriteSheet:getFrame(index) end

--- Returns the total number of frames in the sheet.
---@return number
function LSpriteSheet:getFrameCount() end

--- Returns the width and height of a single frame cell in pixels.
---@return integer
---@return integer
function LSpriteSheet:getFrameSize() end

--- Returns the number of columns and rows in the grid.
---@return integer
---@return integer
function LSpriteSheet:getGridSize() end

--- Returns a sequential table of quad tables for the named frame group, or nil.
---@param name string
---@return table
function LSpriteSheet:getGroupFrames(name) end

--- Returns a sequential table of all defined group names.
---@return table
function LSpriteSheet:getGroupNames() end

--- Returns a sequential table of quad tables for every frame in the given row.
---@param row integer
---@return table
function LSpriteSheet:getRow(row) end

--- Registers a named frame group starting at `start_frame` with `count` frames.
---@param name string
---@param start_frame integer
---@param count integer
---@return nil
function LSpriteSheet:nameGroup(name, start_frame, count) end

--- Returns the type name of this object.
---@return string
function LSpriteSheet:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSpriteSheet:typeOf(name) end

--- Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
---@param atlas SpriteAtlas
---@param sheet_width integer
---@param sheet_height integer
---@return SpriteSheet
lurek.sprite.newAtlasSheet = function(atlas, sheet_width, sheet_height) end

--- Creates an RPGMaker VX/Ace character sheet (3 cols Ă— 4 rows) with "down", "left", "right", "up" groups.
---@param texture_width integer
---@param texture_height integer
---@return SpriteSheet
lurek.sprite.newRPGMakerSheet = function(texture_width, texture_height) end

--- Creates a sprite sheet with a uniform grid of `frame_w Ă— frame_h` frames.
---@param texture_width integer
---@param texture_height integer
---@param frame_width integer
---@param frame_height integer
---@return SpriteSheet
lurek.sprite.newSheet = function(texture_width, texture_height, frame_width, frame_height) end

--- Parses an Aseprite JSON export string and returns a `SpriteAtlas`.
---@param json_str string
---@return SpriteAtlas
lurek.sprite.parseAsepriteAtlas = function(json_str) end

--- Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
---@param json_str string
---@return SpriteAtlas
lurek.sprite.parseAtlas = function(json_str) end

---@class lurek.system
lurek.system = {}

--- Serialises an engine error message to a compact JSON string.
---@param err string
---@return string
lurek.runtime.errorSnapshot = function(err) end

--- Returns the CPU architecture string for the current machine.
---@return string
lurek.runtime.getArch = function() end

--- Returns the command-line arguments as a table.
---@return table
lurek.runtime.getArgs = function() end

--- Returns the output table from the most recently completed runBatch call.
---@param results table
---@return integer
---@return integer
---@return integer
lurek.runtime.getBatchResults = function(results) end

--- Returns the current contents of the system clipboard.
---@return string
lurek.runtime.getClipboardText = function() end

--- Returns whether the debug overlay is currently visible.
lurek.runtime.getDebugOverlay = function() end

--- Returns the value of an environment variable, or nil if not set.
---@param name string Environment variable name(case-sensitive on Linux/macOS)
---@return string
lurek.runtime.getEnv = function(name) end

--- Returns a table of system information including OS name, CPU model, and installed RAM.
---@return table
lurek.runtime.getInfo = function() end

--- Returns the last unhandled error message, or nil.
---@return table
lurek.runtime.getLastError = function() end

--- Returns the name of the current minimum log level for runtime messages.
lurek.runtime.getLogLevel = function() end

--- Returns the total amount of installed system RAM in megabytes.
---@return number
lurek.runtime.getMemorySize = function() end

--- Resolves a stable runtime message ID such as 'L001' to its human-readable text.
---@param id string
---@return string
lurek.runtime.getMessage = function(id) end

--- Returns the total number of message entries loaded into the runtime message catalog.
---@return number
lurek.runtime.getMessageCount = function() end

--- Returns the host operating system name ('Windows', 'Linux', 'macOS').
---@return string
lurek.runtime.getOS = function() end

--- Returns battery state, percentage charged, and estimated time remaining.
---@return table
lurek.runtime.getPowerInfo = function() end

--- Returns an ordered list of the user's preferred locale strings (e.g. 'en-US').
---@return table
lurek.runtime.getPreferredLocales = function() end

--- Returns the number of logical CPU cores available.
---@return number
lurek.runtime.getProcessorCount = function() end

--- Returns the Lurek2D engine version string.
---@return string
lurek.runtime.getVersion = function() end

--- Returns true when the runtime message catalog contains the given stable message ID.
---@param id string
---@return boolean
lurek.runtime.hasMessage = function(id) end

--- Emit a log message from Lua at the specified level.
---@param level string
---@param message string
lurek.runtime.log = function(level, message) end

--- Opens a URL in the system's default browser.
---@param url string
---@return boolean
lurek.runtime.openURL = function(url) end

--- Parses a command-line argument string and returns a structured key/value table.
---@param args? table
---@return table
lurek.runtime.parseArgs = function(args) end

--- Runs a list of shell commands in parallel and returns immediately without blocking.
---@param tasks table
---@param opts? table
---@return table
lurek.runtime.runBatch = function(tasks, opts) end

--- Replaces the system clipboard contents with the given string.
---@param text string
lurek.runtime.setClipboardText = function(text) end

--- Shows or hides the FPS/draw-call debug overlay.
---@param enabled boolean
lurek.runtime.setDebugOverlay = function(enabled) end

--- Sets the minimum severity level for runtime log messages.
---@param level string
lurek.runtime.setLogLevel = function(level) end

---@class lurek.terminal
lurek.terminal = {}

--- Lua-side wrapper around a [`Terminal`] with widget binding management.
---@class LTerminal
LTerminal = {}

--- Attaches a widget to this terminal.
---@param widget Widget
---@return nil
function LTerminal:addWidget(widget) end

--- Resizes the window to exactly fit the terminal grid at the current font size.
---@return nil
function LTerminal:autoResize() end

--- Clears all cells to defaults.
---@return nil
function LTerminal:clear() end

--- Detaches all widgets from this terminal.
---@return nil
function LTerminal:clearWidgets() end

--- Returns the cell data at 1-based coordinates.
---@param col integer
---@param row integer
---@return nil
function LTerminal:get(col, row) end

--- Returns the active cell size override as `{w, h}`, or `nil` if none is set.
---@return table
function LTerminal:getCellSize() end

--- Returns the terminal grid dimensions.
---@return integer
---@return integer
function LTerminal:getDimensions() end

--- Returns the currently focused widget, or nil.
---@return nil
function LTerminal:getFocused() end

--- Returns the number of attached widgets.
---@return number
function LTerminal:getWidgetCount() end

--- Routes a key press to the focused widget and fires callbacks.
---@param key string
---@return boolean
function LTerminal:keypressed(key) end

--- Routes a mouse press to widgets using pixel coordinates.
---@param px number
---@param py number
---@param button? integer
---@return nil
function LTerminal:mousepressed(px, py, button) end

--- Detaches a widget from this terminal.
---@param widget Widget
---@return nil
function LTerminal:removeWidget(widget) end

--- Renders the terminal grid and widgets as render commands.
---@param x? number
---@param y? number
---@return nil
function LTerminal:render(x, y) end

--- Removes the cell size override, restoring font-derived cell dimensions.
---@return nil
function LTerminal:resetCellSize() end

--- Sets a cell at 1-based coordinates with character FG and BG colours.
---@param ... integer|string
---@return nil
function LTerminal:set(...) end

--- Sets a per-terminal cell pixel size override, bypassing the font-derived size.
---@param w number
---@param h number
---@return nil
function LTerminal:setCellSize(w, h) end

--- Sets the focused widget, or clears focus if nil is passed.
---@param widget? Widget
---@return nil
function LTerminal:setFocus(widget) end

--- Sets the terminal font by pixel height, snapping to the nearest built-in size.
---@param height integer
---@return nil
function LTerminal:setFont(height) end

--- Routes text input to the focused widget and fires callbacks.
---@param text string
---@return boolean
function LTerminal:textinput(text) end

--- Returns the type name of this object.
---@return string
function LTerminal:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTerminal:typeOf(name) end

--- Lua-side wrapper around a [`Widget`] with attachment and callback state.
---@class LWidget
LWidget = {}

--- Adds a child widget to a panel widget.
---@param child Widget
---@return nil
function LWidget:addChild(child) end

--- Adds an item to a list widget.
---@param item string
---@return nil
function LWidget:addItem(item) end

--- Removes all children from a panel widget.
---@return nil
function LWidget:clearChildren() end

--- Removes all items from a list widget.
---@return nil
function LWidget:clearItems() end

--- Returns a child widget from a panel by 1-based index, or nil.
---@param index integer
---@return nil
function LWidget:getChild(index) end

--- Returns the number of children in a panel widget.
---@return number
function LWidget:getChildCount() end

--- Returns the colour of a label or border widget.
---@return number
---@return number
---@return number
---@return number
function LWidget:getColor() end

--- Returns a list item by 1-based index.
---@param index integer
---@return string
function LWidget:getItem(index) end

--- Returns the number of items in a list widget.
---@return number
function LWidget:getItemCount() end

--- Returns the maximum character length of a text box widget.
---@return number
function LWidget:getMaxLength() end

--- Returns the widget position as 1-based coordinates.
---@return integer
---@return integer
function LWidget:getPosition() end

--- Returns the selected item index (1-based) in a list widget, or nil.
---@return number
function LWidget:getSelected() end

--- Returns the widget size in cells.
---@return integer
---@return integer
function LWidget:getSize() end

--- Returns the border style name of a border widget.
---@return string
function LWidget:getStyle() end

--- Returns the free-form identification tag.
---@return string
function LWidget:getTag() end

--- Returns the text content of a label, button, or text box widget.
---@return string
function LWidget:getText() end

--- Returns the title of a border widget.
---@return string
function LWidget:getTitle() end

--- Returns whether the widget accepts input.
---@return boolean
function LWidget:isEnabled() end

--- Returns whether the widget is visible.
---@return boolean
function LWidget:isVisible() end

--- Removes a child widget from a panel widget.
---@param child Widget
---@return nil
function LWidget:removeChild(child) end

--- Removes an item from a list widget by 1-based index.
---@param index integer
---@return nil
function LWidget:removeItem(index) end

--- Sets the colour of a label or border widget.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return nil
function LWidget:setColor(r, g, b, a) end

--- Sets whether the widget accepts input.
---@param enabled boolean
---@return nil
function LWidget:setEnabled(enabled) end

--- Sets the maximum character length of a text box widget.
---@param max_length integer
---@return nil
function LWidget:setMaxLength(max_length) end

--- Registers a text change callback for a text box widget.
---@param callback? function
---@return nil
function LWidget:setOnChange(callback) end

--- Registers a click callback for a button widget.
---@param callback? function
---@return nil
function LWidget:setOnClick(callback) end

--- Registers a selection change callback for a list widget.
---@param callback? function
---@return nil
function LWidget:setOnSelect(callback) end

--- Sets the widget position from 1-based coordinates.
---@param col integer
---@param row integer
---@return nil
function LWidget:setPosition(col, row) end

--- Sets the selected item in a list widget by 1-based index.
---@param index? integer
---@return nil
function LWidget:setSelected(index) end

--- Sets the widget size in cells.
---@param width integer
---@param height integer
---@return nil
function LWidget:setSize(width, height) end

--- Sets the border style of a border widget.
---@param style string
---@return nil
function LWidget:setStyle(style) end

--- Sets the free-form identification tag.
---@param tag string
---@return nil
function LWidget:setTag(tag) end

--- Sets the text content of a label, button, or text box widget.
---@param text string
---@return nil
function LWidget:setText(text) end

--- Sets the title of a border widget.
---@param title string
---@return nil
function LWidget:setTitle(title) end

--- Sets the widget visibility.
---@param visible boolean
---@return nil
function LWidget:setVisible(visible) end

--- Returns the type name of this object.
---@return string
function LWidget:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LWidget:typeOf(name) end

--- Adds a candidate string to the tab-completion engine.
---@param candidate string
---@return nil
lurek.terminal.addCompletion = function(candidate) end

--- Applies a named colour theme to a terminal, recolouring all existing cells.
---@param terminal Terminal
---@param theme string
---@return nil
lurek.terminal.applyTheme = function(terminal, theme) end

--- Clears all entries from this terminal's command history.
---@param terminal Terminal
---@return nil
lurek.terminal.clearCmdHistory = function(terminal) end

--- Clears all completion candidates.
---@return nil
lurek.terminal.clearCompletions = function() end

--- Returns the total number of entries in this terminal's command history.
---@param terminal Terminal
---@return number
lurek.terminal.cmdHistoryLen = function(terminal) end

--- Returns all registered candidates that start with `prefix`, as a sorted array.
---@param prefix string
---@return table
lurek.terminal.getCompletions = function(prefix) end

--- Returns the maximum number of columns a Terminal can be constructed with.
---@return number
lurek.terminal.getMaxCols = function() end

--- Returns the maximum number of rows a Terminal can be constructed with.
---@return number
lurek.terminal.getMaxRows = function() end

--- Returns a table of lines from the scrollback buffer.
---@param terminal Terminal
---@param offset integer
---@param count integer
---@return table
lurek.terminal.getScrollback = function(terminal, offset, count) end

--- Creates a new decorative border widget at 1-based coordinates.
---@param col integer
---@param row integer
---@param width integer
---@param height integer
---@return Widget
lurek.terminal.newBorder = function(col, row, width, height) end

--- Creates a new button widget at 1-based coordinates.
---@param col integer
---@param row integer
---@param width integer
---@param height? integer
---@param text? string
---@return Widget
lurek.terminal.newButton = function(col, row, width, height, text) end

--- Creates a new label widget at 1-based coordinates.
---@param col integer
---@param row integer
---@param text? string
---@return Widget
lurek.terminal.newLabel = function(col, row, text) end

--- Creates a new scrollable list widget at 1-based coordinates.
---@param col integer
---@param row integer
---@param width integer
---@param height integer
---@return Widget
lurek.terminal.newList = function(col, row, width, height) end

--- Creates a new container panel widget at 1-based coordinates.
---@param col integer
---@param row integer
---@param width? integer
---@param height? integer
---@return Widget
lurek.terminal.newPanel = function(col, row, width, height) end

--- Creates a new terminal grid with the given dimensions.
---@param cols? integer
---@param rows? integer
---@return Terminal
lurek.terminal.newTerminal = function(cols, rows) end

--- Creates a new single-line text box widget at 1-based coordinates.
---@param col integer
---@param row integer
---@param width integer
---@return Widget
lurek.terminal.newTextBox = function(col, row, width) end

--- Steps one entry forward in command history (toward newer commands).
---@param terminal Terminal
---@return string
lurek.terminal.nextCmd = function(terminal) end

--- Returns the next candidate for `prefix`, cycling on repeated calls.
---@param prefix string
---@return string
lurek.terminal.nextCompletion = function(prefix) end

--- Parses `text` into coloured spans.  Returns an array of tables, each with
---@param text string
---@return table
lurek.terminal.parseAnsi = function(text) end

--- Steps one entry back in command history (toward older commands).
---@param terminal Terminal
---@return string
lurek.terminal.prevCmd = function(terminal) end

--- Prints ANSI-escaped `text` onto terminal `t` starting at `(col, row)`.
---@param t Terminal
---@param col integer
---@param row integer
---@param text string
---@return nil
lurek.terminal.printAnsi = function(t, col, row, text) end

--- Prints text at 1-based `(col, row)` with per-keyword colour highlighting.
---@param terminal Terminal
---@param col integer
---@param row integer
---@param text string
---@param rules table
---@return nil
lurek.terminal.printHighlighted = function(terminal, col, row, text, rules) end

--- Appends a command string to this terminal's history.
---@param terminal Terminal
---@param cmd string
---@return nil
lurek.terminal.pushCmdHistory = function(terminal, cmd) end

--- Appends a line to this terminal's scrollback buffer.
---@param terminal Terminal
---@param line string
---@return nil
lurek.terminal.pushScrollback = function(terminal, line) end

--- Removes a candidate string from the tab-completion engine.
---@param candidate string
---@return nil
lurek.terminal.removeCompletion = function(candidate) end

--- Resets the cycling cursor without clearing the candidate list.
---@return nil
lurek.terminal.resetCompletion = function() end

--- Returns the number of lines currently in this terminal's scrollback buffer.
---@param terminal Terminal
---@return number
lurek.terminal.scrollbackLen = function(terminal) end

--- Sets the maximum number of lines retained in the scrollback buffer.
---@param terminal Terminal
---@param cap integer
---@return nil
lurek.terminal.setScrollbackCap = function(terminal, cap) end

--- Strips all ANSI escape codes from `text` and returns the plain string.
---@param text string
---@return string
lurek.terminal.stripAnsi = function(text) end

---@class lurek.thread
lurek.thread = {}

--- A synchronized message queue for cross-VM communication.
---@class LChannel
LChannel = {}

--- Clears all items from the channel.
---@return nil
function LChannel:clear() end

--- Blocks until a value is available or the timeout expires, then removes and returns it.
---@param timeout? number
---@return string
function LChannel:demand(timeout) end

--- Returns the number of items in the channel.
---@return number
function LChannel:getCount() end

--- Retrieves the value from the channel without removing it.
---@return string
function LChannel:peek() end

--- Retrieves and removes a value from the channel.
---@return string
function LChannel:pop() end

--- Pops a bytes value from the channel and returns it as a Lua string.
---@return string
function LChannel:popBytes() end

--- Pops a value from the channel expecting a table.
---@return table
function LChannel:popTable() end

--- Pushes a value to the channel.
---@param value any
---@return number
function LChannel:push(value) end

--- Pushes raw binary data (a Lua string treated as a byte array) to the channel.
---@param data string
---@return number
function LChannel:pushBytes(data) end

--- Serializes a Lua table and pushes it to the channel.
---@param value table
---@return number
function LChannel:pushTable(value) end

--- Blocks until the channel has space, then adds the value.
---@param value any
---@return nil
function LChannel:supply(value) end

--- Returns the type of the object.
---@return string
function LChannel:type() end

--- Checks if the object is of the specified type.
---@param name string
---@return boolean
function LChannel:typeOf(name) end

--- Lua-side wrapper around a one-shot [`Promise`].
---@class LPromise
LPromise = {}

--- Returns the worker error string if the promise failed, otherwise nil.
---@return string
function LPromise:getError() end

--- Returns true if the promise has a result or has errored (non-blocking).
---@return boolean
function LPromise:isDone() end

--- Pops and returns the promise result, or nil if not yet ready.
---@return table
function LPromise:result() end

--- Returns the type name of this object.
---@return string
function LPromise:type() end

--- Returns whether this object is of the given type.
---@param name string
---@return boolean
function LPromise:typeOf(name) end

--- Lua-side wrapper around a background [`LuaThread`].
---@class LThread
LThread = {}

--- Returns the error message if the thread failed, or nil.
---@return string
function LThread:getError() end

--- Returns whether the thread is currently executing.
---@return boolean
function LThread:isRunning() end

--- Launches the background thread, passing optional arguments via varargs.
---@param ... any
---@return nil
function LThread:start(...) end

--- Returns the type name of this object.
---@return string
function LThread:type() end

--- Returns whether this object is of the given type.
---@param name string
---@return boolean
function LThread:typeOf(name) end

--- Blocks the calling thread until the background thread finishes.
---@return nil
function LThread:wait() end

--- Lua-side wrapper around a [`ThreadPool`].
---@class LThreadPool
LThreadPool = {}

--- Retrieves the next result from the pool's output channel (non-blocking).
---@return table
function LThreadPool:collect() end

--- Returns the shared input Channel (main â†’ workers).
---@return Channel
function LThreadPool:getInputChannel() end

--- Returns the shared output Channel (workers â†’ main).
---@return Channel
function LThreadPool:getOutputChannel() end

--- Blocks until all workers in the pool have finished execution.
---@return nil
function LThreadPool:join() end

--- Returns the number of workers in this pool.
---@return number
function LThreadPool:size() end

--- Submits a value to the pool's input channel for processing by a worker.
---@param value any
---@return nil
function LThreadPool:submit(value) end

--- Returns the type name of this object.
---@return string
function LThreadPool:type() end

--- Returns whether this object is of the given type.
---@param name string
---@return boolean
function LThreadPool:typeOf(name) end

--- Starts a one-shot background computation and returns a Promise.
---@param code string
---@param ... MultiValue
---@return Promise
lurek.thread.async = function(code, ...) end

--- Gets or creates a named global channel shared across threads.
---@param name string
---@return Channel
lurek.thread.getChannel = function(name) end

--- Creates an unnamed thread-safe channel for inter-thread communication.
---@param name? string
---@return Channel
lurek.thread.newChannel = function(name) end

--- Creates a thread pool of N workers all running the same Lua code.
---@param size integer
---@param code string
---@return ThreadPool
lurek.thread.newPool = function(size, code) end

--- Creates a new background thread from a Lua code string.
---@param code string
---@return ThreadHandle
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
---@param tileset TileSet
---@param typeName string
---@param startGid? integer
---@return nil
function LAutoTileSheet:applyToTileSet(tileset, typeName, startGid) end

--- Returns the bitmask value associated with a 1-based local tile ID.
---@param tileId integer
---@return number
function LAutoTileSheet:getBitmaskForTile(tileId) end

--- Returns the layout variant as a string.
---@return string
function LAutoTileSheet:getLayout() end

--- Returns the atlas region rectangle for the 1-based tile ID.
---@param tileId integer
---@return number
---@return number
---@return number
---@return number
function LAutoTileSheet:getQuad(tileId) end

--- Returns the number of tiles in this sheet.
---@return number
function LAutoTileSheet:getTileCount() end

--- Returns the 1-based tile ID for a given bitmask, or nil.
---@param bitmask integer
---@return number
function LAutoTileSheet:getTileForBitmask(bitmask) end

--- Returns the tile height in pixels.
---@return number
function LAutoTileSheet:getTileHeight() end

--- Returns the tile width in pixels.
---@return number
function LAutoTileSheet:getTileWidth() end

--- Returns the type name of this object.
---@return string
function LAutoTileSheet:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAutoTileSheet:typeOf(name) end

--- Lua-side wrapper around a [`ChunkMap`].
---@class LChunkMap
LChunkMap = {}

--- Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
---@param cx integer
---@param cy integer
---@return integer
---@return integer
---@return integer
---@return integer
function LChunkMap:chunkTileRange(cx, cy) end

--- Clears the tile at (x, y) by setting its GID to 0.
---@param x integer
---@param y integer
---@return nil
function LChunkMap:clearTile(x, y) end

--- Fills the rectangular tile region with a GID.
---@param x0 integer
---@param y0 integer
---@param x1 integer
---@param y1 integer
---@param gid integer
---@return nil
function LChunkMap:fillRect(x0, y0, x1, y1, gid) end

--- Returns the chunk size (tiles per side).
---@return number
function LChunkMap:getChunkSize() end

--- Returns chunk coordinates whose world-pixel footprint overlaps the given viewport.
---@param vx number
---@param vy number
---@param vw number
---@param vh number
---@param tw number
---@param th number
---@return table
function LChunkMap:getChunksInView(vx, vy, vw, vh, tw, th) end

--- Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
---@return table
function LChunkMap:getLoadedChunks() end

--- Returns the GID at tile coordinate (x, y).
---@param x integer
---@param y integer
---@return number
function LChunkMap:getTile(x, y) end

--- Pre-allocates the chunk at chunk coordinates (cx, cy).
---@param cx integer
---@param cy integer
---@return nil
function LChunkMap:loadChunk(cx, cy) end

--- Sets the GID at tile coordinate (x, y).
---@param x integer
---@param y integer
---@param gid integer
---@return nil
function LChunkMap:setTile(x, y, gid) end

--- Returns the type name of this object.
---@return string
function LChunkMap:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LChunkMap:typeOf(name) end

--- Removes the chunk at chunk coordinates (cx, cy) from memory.
---@param cx integer
---@param cy integer
---@return nil
function LChunkMap:unloadChunk(cx, cy) end

--- Lua-side wrapper around an [`IsoMap`].
---@class LIsoMap
LIsoMap = {}

--- Appends a new empty Z-level and returns its 1-based index.
---@return number
function LIsoMap:addLevel() end

--- Fills every cell in level z with gid for the given part (1-based z; 0-based part).
---@param z integer
---@param part integer
---@param gid integer
---@return nil
function LIsoMap:fillLevel(z, part, gid) end

--- Returns the map height in tiles.
---@return number
function LIsoMap:getHeight() end

--- Returns the number of Z-levels currently in the map.
---@return number
function LIsoMap:getLevelCount() end

--- Returns the vertical pixel offset between consecutive Z-levels.
---@return number
function LIsoMap:getLevelHeight() end

--- Returns the number of GID slots per tile.
---@return number
function LIsoMap:getPartCount() end

--- Returns the current draw-order array (0-based part slot indices).
---@return table
function LIsoMap:getPartOrder() end

--- Returns the tile footprint height in pixels.
---@return number
function LIsoMap:getTileHeight() end

--- Reads the GID in the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
---@param z integer
---@param x integer
---@param y integer
---@param part integer
---@return number
function LIsoMap:getTilePart(z, x, y, part) end

--- Returns the tile footprint width in pixels.
---@return number
function LIsoMap:getTileWidth() end

--- Returns the map width in tiles.
---@return number
function LIsoMap:getWidth() end

--- Returns the visibility of a level (1-based z).
---@param z integer
---@return boolean
function LIsoMap:isLevelVisible(z) end

--- Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
---@param sx number
---@param sy number
---@return number
---@return number
function LIsoMap:screenToTile(sx, sy) end

--- Sets the visibility of a level (1-based z).
---@param z integer
---@param visible boolean
---@return nil
function LIsoMap:setLevelVisible(z, visible) end

--- Sets the screen pixel origin.
---@param x number
---@param y number
---@return nil
function LIsoMap:setOrigin(x, y) end

--- Overrides the draw order for this IsoMap. Length must equal partCount.
---@param order table
---@return nil
function LIsoMap:setPartOrder(order) end

--- Writes a GID into the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
---@param z integer
---@param x integer
---@param y integer
---@param part integer
---@param gid integer
---@return nil
function LIsoMap:setTilePart(z, x, y, part, gid) end

--- Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
---@param tx number
---@param ty number
---@param tz number
---@return number
---@return number
function LIsoMap:tileToScreen(tx, ty, tz) end

--- Returns the type name of this object.
---@return string
function LIsoMap:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LIsoMap:typeOf(name) end

--- Lua-side wrapper around a [`LargeMapRenderer`] for chunk-level occlusion culling on large worlds.
---@class LLargeMapRenderer
LLargeMapRenderer = {}

--- Returns the current chunk size.
---@return number
function LLargeMapRenderer:getChunkSize() end

--- Returns the map dimensions as (width, height) in tiles.
---@return integer
---@return integer
function LLargeMapRenderer:getMapSize() end

--- Returns the tile ID at (x, y), or nil if out of bounds.
---@param x integer
---@param y integer
---@return number
function LLargeMapRenderer:getTile(x, y) end

--- Returns the number of tileset atlas columns.
---@return number
function LLargeMapRenderer:getTilesetColumns() end

--- Returns the total number of chunks that cover the loaded map.
---@return number
function LLargeMapRenderer:getTotalChunks() end

--- Returns the number of chunks currently within the camera viewport.
---@return number
function LLargeMapRenderer:getVisibleChunks() end

--- Marks every chunk as dirty.
---@return nil
function LLargeMapRenderer:invalidateAll() end

--- Marks a chunk at chunk-grid coordinates (cx, cy) as dirty,
---@param cx integer
---@param cy integer
---@return nil
function LLargeMapRenderer:invalidateChunk(cx, cy) end

--- Returns whether LOD rendering is currently enabled.
---@return boolean
function LLargeMapRenderer:isLodEnabled() end

--- Updates the camera position and zoom used for visibility culling.
---@param x number
---@param y number
---@param zoom number
---@return nil
function LLargeMapRenderer:setCamera(x, y, zoom) end

--- Sets the chunk size used for culling (default 16).
---@param size integer
---@return nil
function LLargeMapRenderer:setChunkSize(size) end

--- Enables or disables level-of-detail rendering for distant chunks.
---@param enabled boolean
---@return nil
function LLargeMapRenderer:setLodEnabled(enabled) end

--- Sets the distance thresholds (in tile units) at which each LOD level activates.
---@param levels table
---@return nil
function LLargeMapRenderer:setLodThresholds(levels) end

--- Loads a flat array of tile IDs (row-major) covering width Ă— height tiles.
---@param data table
---@param width integer
---@param height integer
---@return nil
function LLargeMapRenderer:setMapData(data, width, height) end

--- Sets a single tile ID at (x, y).  Coordinates are 0-based.
---@param x integer
---@param y integer
---@param tileId integer
---@return nil
function LLargeMapRenderer:setTile(x, y, tileId) end

--- Sets the number of tile columns in the atlas texture used for UV calculation.
---@param cols integer
---@return nil
function LLargeMapRenderer:setTilesetColumns(cols) end

--- Sets the viewport dimensions in pixels used for visibility culling.
---@param width number
---@param height number
---@return nil
function LLargeMapRenderer:setViewport(width, height) end

--- Returns the type name of this object.
---@return string
function LLargeMapRenderer:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LLargeMapRenderer:typeOf(name) end

--- Lua-side wrapper around a [`MapBlock`].
---@class LMapBlock
LMapBlock = {}

--- Returns the block dimensions as (width, height) in tiles.
---@return integer
---@return integer
function LMapBlock:getDimensions() end

--- Returns the block height in tiles.
---@return number
function LMapBlock:getHeight() end

--- Returns the number of segments along the height.
---@return number
function LMapBlock:getHeightInSegments() end

--- Returns the number of layers in this block.
---@return number
function LMapBlock:getLayerCount() end

--- Returns the name of this block.
---@return string
function LMapBlock:getName() end

--- Returns the segment size in tiles.
---@return number
function LMapBlock:getSegmentSize() end

--- Returns the side connection ID for a segment on a given edge.
---@param edge string
---@param segment integer
---@return number
function LMapBlock:getSide(edge, segment) end

--- Returns the GID of the tile at (x, y) on the given layer (1-based).
---@param layer integer
---@param x integer
---@param y integer
---@return number
function LMapBlock:getTile(layer, x, y) end

--- Returns the placement weight.
---@return number
function LMapBlock:getWeight() end

--- Returns the block width in tiles.
---@return number
function LMapBlock:getWidth() end

--- Returns the number of segments along the width.
---@return number
function LMapBlock:getWidthInSegments() end

--- Sets the human-readable name of this block.
---@param name string
---@return nil
function LMapBlock:setName(name) end

--- Sets the side connection ID for a segment on a given edge.
---@param edge string
---@param segment integer
---@param sideId integer
---@return nil
function LMapBlock:setSide(edge, segment, sideId) end

--- Sets the GID of a tile at (x, y) on the given layer (1-based).
---@param layer integer
---@param x integer
---@param y integer
---@param gid integer
---@return nil
function LMapBlock:setTile(layer, x, y, gid) end

--- Sets the placement weight.
---@param weight number
---@return nil
function LMapBlock:setWeight(weight) end

--- Returns the type name of this object.
---@return string
function LMapBlock:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LMapBlock:typeOf(name) end

--- Lua-side wrapper for a map generator (size preset or explicit dimensions).
---@class LMapGen
LMapGen = {}

--- Generates a TileMap using the group's blocks and an optional script index, seed, and layer name.
---@param scriptIndex? integer
---@param seed? integer
---@param layerName? string
---@return TileMap
function LMapGen:generate(scriptIndex, seed, layerName) end

--- Returns the type name of this object.
---@return string
function LMapGen:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LMapGen:typeOf(name) end

--- Lua-side wrapper around a [`MapGroup`].
---@class LMapGroup
LMapGroup = {}

--- Adds a block to this group.
---@param block MapBlock
---@return nil
function LMapGroup:addBlock(block) end

--- Adds a MapScript to this group.
---@param script MapScript
---@return nil
function LMapGroup:addScript(script) end

--- Returns the number of blocks in this group.
---@return number
function LMapGroup:getBlockCount() end

--- Returns the name of this group.
---@return string
function LMapGroup:getName() end

--- Returns the number of scripts in this group.
---@return number
function LMapGroup:getScriptCount() end

--- Removes a block by 1-based index.
---@param idx integer
---@return nil
function LMapGroup:removeBlock(idx) end

--- Returns the type name of this object.
---@return string
function LMapGroup:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LMapGroup:typeOf(name) end

--- Lua-side wrapper around a [`MapScript`] procedural generation script.
---@class LMapScript
LMapScript = {}

--- Appends a generation step from a step-definition table.
---@param stepDef table
---@return nil
function LMapScript:addStep(stepDef) end

--- Returns the number of steps in this script.
---@return number
function LMapScript:getStepCount() end

--- Returns the type name of this object.
---@return string
function LMapScript:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LMapScript:typeOf(name) end

--- Lua-side wrapper around a [`TileMap`].
---@class LTileMap
LTileMap = {}

--- Adds a new empty layer and returns its 1-based index.
---@param name string
---@param w integer
---@param h integer
---@return number
function LTileMap:addLayer(name, w, h) end

--- Adds a tileset to this map.
---@param tileset TileSet
---@return nil
function LTileMap:addTileSet(tileset) end

--- Applies 4-bit cardinal autotile rules to every tile on layer (1-based).
---@param layer integer
---@param typeName string
---@return nil
function LTileMap:applyAutoTile(layer, typeName) end

--- Applies 8-bit directional autotile rules to every tile on layer (1-based).
---@param layer integer
---@param typeName string
---@return nil
function LTileMap:applyAutoTile8(layer, typeName) end

--- Applies 8-bit directional autotile at a single cell and its 3x3 neighborhood (1-based).
---@param layer integer
---@param x integer
---@param y integer
---@param typeName string
---@return nil
function LTileMap:applyAutoTile8At(layer, x, y, typeName) end

--- Applies 4-bit cardinal autotile at a single cell and its 3x3 neighborhood (1-based).
---@param layer integer
---@param x integer
---@param y integer
---@param typeName string
---@return nil
function LTileMap:applyAutoTileAt(layer, x, y, typeName) end

--- Checks a list of entity positions against registered tile callbacks and fires matches.
---@param layer integer
---@param entities table
---@return nil
function LTileMap:checkEntities(layer, entities) end

--- Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
---@param layer integer
---@param x integer
---@param y integer
---@return nil
function LTileMap:clearTile(layer, x, y) end

--- Renders the tile map to a CPU ImageData using the given tile pixel size.
---@param tile_size integer
---@return ImageData
function LTileMap:drawToImage(tile_size) end

--- Fills an entire layer with the given GID (1-based layer).
---@param layer integer
---@param gid integer
---@return nil
function LTileMap:fill(layer, gid) end

--- Fire the tile exit callback for the given GID (call when entity leaves tile).
---@param gid integer — tile GID
---@param entity table — entity data
---@param tile_x integer — tile column
---@param tile_y integer — tile row
---@return nil
function LTileMap:fireTileExit(gid, entity, tile_x, tile_y) end

--- Fire the tile step callback for the given GID (call each frame while entity is on tile).
---@param gid integer — tile GID
---@param entity table — entity data passed to callback
---@param tile_x integer — tile column
---@param tile_y integer — tile row
---@return nil
function LTileMap:fireTileStep(gid, entity, tile_x, tile_y) end

--- Returns the chunk size used for spatial partitioning.
---@return number
function LTileMap:getChunkSize() end

--- Returns the RGBA tint color of a layer.
---@param idx integer
---@return number
---@return number
---@return number
---@return number
function LTileMap:getLayerColor(idx) end

--- Returns the number of layers.
---@return number
function LTileMap:getLayerCount() end

--- Returns the name of a layer by 1-based index.
---@param idx integer
---@return string
function LTileMap:getLayerName(idx) end

--- Returns the pixel offset of a layer.
---@param idx integer
---@return number
---@return number
function LTileMap:getLayerOffset(idx) end

--- Returns the parallax factor of a layer.
---@param idx integer
---@return number
---@return number
function LTileMap:getLayerParallax(idx) end

--- Returns layer visibility.
---@param idx integer
---@return boolean
function LTileMap:getLayerVisible(idx) end

--- Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
---@return string
function LTileMap:getOrientation() end

--- Returns the GID at (x, y) on the given layer (1-based).
---@param layer integer
---@param x integer
---@param y integer
---@return number
function LTileMap:getTile(layer, x, y) end

--- Returns tile dimensions as (width, height).
---@return integer
---@return integer
function LTileMap:getTileDimensions() end

--- Returns the tile height in pixels.
---@return number
function LTileMap:getTileHeight() end

--- Returns a tileset by 1-based index, or nil if out of range.
---@param idx integer
---@return nil
function LTileMap:getTileSet(idx) end

--- Returns the number of tilesets attached to this map.
---@return number
function LTileMap:getTileSetCount() end

--- Returns the tile width in pixels.
---@return number
function LTileMap:getTileWidth() end

--- Returns the viewport as (x, y, w, h) or nil if not set.
---@return number
---@return number
---@return number
---@return number
function LTileMap:getViewport() end

--- Returns true if the tile at (x, y) on layer is solid (1-based).
---@param layer integer
---@param x integer
---@param y integer
---@return boolean
function LTileMap:isSolid(layer, x, y) end

--- Registers a callback fired when any entity's tile GID matches `gid`.
---@param gid integer
---@param func function
---@return nil
function LTileMap:onTileEnter(gid, func) end

--- Register a callback for when an entity exits a tile with the given GID.
---@param gid integer — tile global ID
---@param fn function(entity: table,tile_x: integer,tile_y: integer)
---@return nil
function LTileMap:onTileExit(gid, fn) end

--- Register a callback for when an entity steps on a tile with the given GID.
---@param gid integer — tile global ID
---@param fn function(entity: table,tile_x: integer,tile_y: integer)
---@return nil
function LTileMap:onTileStep(gid, fn) end

--- Returns true if any solid tile overlaps the given world-space rectangle on layer (1-based).
---@param layer integer
---@param x number
---@param y number
---@param w number
---@param h number
---@return boolean
function LTileMap:rectOverlapsSolid(layer, x, y, w, h) end

--- Renders the tile map to the screen at the given offset.
---@param ox? number
---@param oy? number
---@return nil
function LTileMap:render(ox, oy) end

--- Sets the RGBA tint color for a layer.
---@param idx integer
---@param r number
---@param g number
---@param b number
---@param a number
---@return nil
function LTileMap:setLayerColor(idx, r, g, b, a) end

--- Sets the pixel offset for a layer.
---@param idx integer
---@param ox number
---@param oy number
---@return nil
function LTileMap:setLayerOffset(idx, ox, oy) end

--- Sets the parallax scrolling factor for a layer.
---@param idx integer
---@param px number
---@param py number
---@return nil
function LTileMap:setLayerParallax(idx, px, py) end

--- Shows or hides a tile layer by its 1-based index.
---@param idx integer
---@param visible boolean
---@return nil
function LTileMap:setLayerVisible(idx, visible) end

--- Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
---@param orientation string
---@return nil
function LTileMap:setOrientation(orientation) end

--- Sets the GID of a tile at (x, y) on the given layer (1-based).
---@param layer integer
---@param x integer
---@param y integer
---@param gid integer
---@return nil
function LTileMap:setTile(layer, x, y, gid) end

--- Sets a per-tile RGBA tint override (1-based layer, x, y).
---@param layer integer
---@param x integer
---@param y integer
---@param r number
---@param g number
---@param b number
---@param a number
---@return nil
function LTileMap:setTileTint(layer, x, y, r, g, b, a) end

--- Sets the viewport rectangle for rendering culling.
---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function LTileMap:setViewport(x, y, w, h) end

--- Performs a swept AABB collision test against solid tiles on layer (1-based).
---@param layer integer
---@param x number
---@param y number
---@param w number
---@param h number
---@param dx number
---@param dy number
---@return nil
function LTileMap:sweepRect(layer, x, y, w, h, dx, dy) end

--- Converts tile coordinates to world pixel coordinates (1-based input).
---@param tx integer
---@param ty integer
---@return number
---@return number
function LTileMap:tileToWorld(tx, ty) end

--- Converts the given layer into a 2D navigation grid.
---@param layer integer
---@param walkable_gids table
---@return table
function LTileMap:toNavGrid(layer, walkable_gids) end

--- Returns the type name of this object.
---@return string
function LTileMap:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTileMap:typeOf(name) end

--- Advances tile animation timers by dt seconds.
---@param dt number
---@return nil
function LTileMap:update(dt) end

--- Converts world pixel coordinates to tile coordinates.
---@param wx number
---@param wy number
---@return integer
---@return integer
function LTileMap:worldToTile(wx, wy) end

--- Lua-side wrapper around a [`TileSet`].
---@class LTileSet
LTileSet = {}

--- Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
---@param tileId integer
---@return table
function LTileSet:getAnimation(tileId) end

--- Looks up the 1-based local tile ID for a 4-bit cardinal autotile bitmask, or nil.
---@param typeName string
---@param bitmask integer
---@return number
function LTileSet:getAutoTileId(typeName, bitmask) end

--- Looks up the 1-based local tile ID for an 8-bit directional autotile bitmask, or nil.
---@param typeName string
---@param bitmask integer
---@return number
function LTileSet:getAutoTileId8(typeName, bitmask) end

--- Returns the number of tile columns in the atlas texture.
---@return number
function LTileSet:getColumns() end

--- Returns the first global ID assigned to this tileset.
---@return number
function LTileSet:getFirstGid() end

--- Returns the margin in pixels around the edges of the atlas.
---@return number
function LTileSet:getMargin() end

--- Computes the atlas source rectangle for a 1-based local tile ID.
---@param tileId integer
---@return table
function LTileSet:getQuad(tileId) end

--- Returns the spacing in pixels between tiles in the atlas.
---@return number
function LTileSet:getSpacing() end

--- Returns the total number of tiles in this tileset.
---@return number
function LTileSet:getTileCount() end

--- Returns the tile dimensions as (width, height).
---@return integer
---@return integer
function LTileSet:getTileDimensions() end

--- Returns the height of a single tile in pixels.
---@return number
function LTileSet:getTileHeight() end

--- Returns the width of a single tile in pixels.
---@return number
function LTileSet:getTileWidth() end

--- Returns whether a 1-based local tile ID is solid.
---@param tileId integer
---@return boolean
function LTileSet:isSolid(tileId) end

--- Sets the animation frames for a 1-based local tile ID from a table of {tileid, duration}.
---@param tileId integer
---@param frames table
---@return nil
function LTileSet:setAnimation(tileId, frames) end

--- Registers a 4-bit cardinal autotile rule. tileId is 1-based.
---@param typeName string
---@param bitmask integer
---@param tileId integer
---@return nil
function LTileSet:setAutoTileRule(typeName, bitmask, tileId) end

--- Registers an 8-bit directional autotile rule. tileId is 1-based.
---@param typeName string
---@param bitmask integer
---@param tileId integer
---@return nil
function LTileSet:setAutoTileRule8(typeName, bitmask, tileId) end

--- Sets whether a 1-based local tile ID is solid for collision purposes.
---@param tileId integer
---@param solid boolean
---@return nil
function LTileSet:setSolid(tileId, solid) end

--- Returns the type name of this object.
---@return string
function LTileSet:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTileSet:typeOf(name) end

--- Parses an LDtk JSON export string and returns a TileMap.
---@param json_str string
---@param level_name? string
---@return TileMap
lurek.tilemap.fromLDtk = function(json_str, level_name) end

--- Converts screen position back to axial hex coordinates (pointy-top layout).
---@param sx number
---@param sy number
---@param size number
---@return integer
---@return integer
lurek.tilemap.fromScreenHex = function(sx, sy, size) end

--- Converts screen position back to tile coordinates for diamond isometric projection.
---@param sx number
---@param sy number
---@param tileW number
---@param tileH number
---@return number
---@return number
lurek.tilemap.fromScreenIso = function(sx, sy, tileW, tileH) end

--- Returns all hex cells within radius distance (filled hex circle) as a table.
---@param q integer
---@param r integer
---@param radius integer
---@return table
lurek.tilemap.hexArea = function(q, r, radius) end

--- Returns the hex distance between two axial coordinates.
---@param q1 integer
---@param r1 integer
---@param q2 integer
---@param r2 integer
---@return number
lurek.tilemap.hexDistance = function(q1, r1, q2, r2) end

--- Returns all hex cells along a line between two axial coordinates as a table.
---@param q1 integer
---@param r1 integer
---@param q2 integer
---@param r2 integer
---@return table
lurek.tilemap.hexLine = function(q1, r1, q2, r2) end

--- Returns the six axial neighbor coordinates as a table of {q, r} pairs.
---@param q integer
---@param r integer
---@return table
lurek.tilemap.hexNeighbors = function(q, r) end

--- Reflects hex coordinates across an axis through the center.
---@param q integer
---@param r integer
---@param centerQ integer
---@param centerR integer
---@param axis string
---@return integer
---@return integer
lurek.tilemap.hexReflect = function(q, r, centerQ, centerR, axis) end

--- Returns all cells at exactly radius distance from (q, r) as a table.
---@param q integer
---@param r integer
---@param radius integer
---@return table
lurek.tilemap.hexRing = function(q, r, radius) end

--- Rotates hex coordinates around a center by steps x 60 degrees clockwise.
---@param q integer
---@param r integer
---@param centerQ integer
---@param centerR integer
---@param steps integer
---@return integer
---@return integer
lurek.tilemap.hexRotate = function(q, r, centerQ, centerR, steps) end

--- Rounds fractional axial coordinates to the nearest hex cell.
---@param q number
---@param r number
---@return integer
---@return integer
lurek.tilemap.hexRound = function(q, r) end

--- Returns all hex cells from center outward to radius, ring by ring, as a table.
---@param q integer
---@param r integer
---@param radius integer
---@return table
lurek.tilemap.hexSpiral = function(q, r, radius) end

--- Snaps an angle (in radians) to the nearest isometric direction (1-4).
---@param angle number
---@return number
lurek.tilemap.isoDirectionFromAngle = function(angle) end

--- Returns the name of an isometric direction (1-4).
---@param direction integer
---@return string
lurek.tilemap.isoDirectionName = function(direction) end

--- Rotates an isometric direction (1-4) clockwise by steps.
---@param direction integer
---@param steps integer
---@return number
lurek.tilemap.isoRotate = function(direction, steps) end

--- Parses a TMX XML string and returns a table with map metadata and layers.
---@param xml string
---@return table
lurek.tilemap.loadTMX = function(xml) end

--- Creates a new AutoTileSheet with the given tile dimensions and layout.
---@param tileWidth integer
---@param tileHeight integer
---@param layout? string
---@return AutoTileSheet
lurek.tilemap.newAutoTileSheet = function(tileWidth, tileHeight, layout) end

--- Creates a new ChunkMap with the given chunk size.
---@param chunkSize? integer
---@return ChunkMap
lurek.tilemap.newChunkMap = function(chunkSize) end

--- Creates a new IsoMap with no levels.
---@param width integer
---@param height integer
---@param tileW integer
---@param tileH integer
---@param levelHeight integer
---@param partCount? integer
---@return IsoMap
lurek.tilemap.newIsoMap = function(width, height, tileW, tileH, levelHeight, partCount) end

--- Creates a LargeMapRenderer for chunk-level occlusion culling on maps > 200Ă—200 tiles.
---@param tileW integer
---@param tileH integer
---@return LargeMapRenderer
lurek.tilemap.newLargeMapRenderer = function(tileW, tileH) end

--- Creates a new MapBlock with the given dimensions.
---@param width integer
---@param height integer
---@param layers? integer
---@param segmentSize? integer
---@return MapBlock
lurek.tilemap.newMapBlock = function(width, height, layers, segmentSize) end

--- Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
---@param group MapGroup
---@param preset string
---@param segmentSize integer
---@return MapGen
lurek.tilemap.newMapGen = function(group, preset, segmentSize) end

--- Creates a new empty MapGroup with the given name.
---@param name string
---@return MapGroup
lurek.tilemap.newMapGroup = function(name) end

--- Creates a new empty MapScript procedural generation script.
---@return MapScript
lurek.tilemap.newMapScript = function() end

--- Creates a new TileMap with the given tile size and chunk size.
---@param tileWidth integer
---@param tileHeight integer
---@param chunkSize? integer
---@return TileMap
lurek.tilemap.newTileMap = function(tileWidth, tileHeight, chunkSize) end

--- Creates a new TileSet with the given atlas layout parameters.
---@param firstGid integer
---@param tileCount integer
---@param columns integer
---@param tileWidth integer
---@param tileHeight integer
---@param spacing? integer
---@param margin? integer
---@return TileSet
lurek.tilemap.newTileSet = function(firstGid, tileCount, columns, tileWidth, tileHeight, spacing, margin) end

--- Converts axial hex coordinates to screen position (pointy-top layout).
---@param q integer
---@param r integer
---@param size number
---@return number
---@return number
lurek.tilemap.toScreenHex = function(q, r, size) end

--- Converts tile coordinates to screen position using diamond isometric projection.
---@param tx number
---@param ty number
---@param tileW number
---@param tileH number
---@return number
---@return number
lurek.tilemap.toScreenIso = function(tx, ty, tileW, tileH) end

---@class lurek.time
lurek.time = {}

--- Lua-side wrapper around a [`Scheduler`] with per-event callback storage.
---@class LScheduler
LScheduler = {}

--- Schedules a callback to fire once after a delay.
---@param delay number
---@param func function
---@return number
function LScheduler:after(delay, func) end

--- Schedules a callback to fire once after `n` frames.
---@param n integer
---@param func function
---@return number
function LScheduler:afterFrames(n, func) end

--- Schedules a named one-shot callback, replacing any existing event with the same name.
---@param name string
---@param delay number
---@param func function
---@return number
function LScheduler:afterNamed(name, delay, func) end

--- Cancels a scheduled event by its numeric ID.
---@param id integer
---@return boolean
function LScheduler:cancel(id) end

--- Cancels all scheduled events and returns the count removed.
---@return number
function LScheduler:cancelAll() end

--- Cancels a scheduled event by its string name.
---@param name string
---@return boolean
function LScheduler:cancelNamed(name) end

--- Schedules a callback to fire repeatedly at the given interval.
---@param interval number
---@param func function
---@param count? integer
---@return number
function LScheduler:every(interval, func, count) end

--- Schedules a callback to fire every `n` frames.
---@param n integer â€” frame interval
---@param func function â€” callback
---@param count? integer? â€” repetitions(-1 = infinite,default)
---@return number
function LScheduler:everyFrames(n, func, count) end

--- Schedules a named repeating callback, replacing any existing event with the same name.
---@param name string
---@param interval number
---@param func function
---@param count? integer
---@return number
function LScheduler:everyNamed(name, interval, func, count) end

--- Returns the number of active scheduled events.
---@return number
function LScheduler:getCount() end

--- Returns the base interval in seconds for an event, or nil.
---@param id integer
---@return number
function LScheduler:getInterval(id) end

--- Returns the seconds remaining until the next fire for an event, or nil.
---@param id integer
---@return number
function LScheduler:getRemaining(id) end

--- Returns the repeat count remaining for an event, or nil.
---@param id integer
---@return number
function LScheduler:getRepeatCount(id) end

--- Returns the current time-scale multiplier.
---@return number
function LScheduler:getTimeScale() end

--- Returns whether the scheduler has no active events.
---@return boolean
function LScheduler:isEmpty() end

--- Returns whether the given event is currently paused.
---@param id integer
---@return boolean
function LScheduler:isPaused(id) end

--- Returns whether the named event is currently paused.
---@param name string
---@return boolean
function LScheduler:isPausedNamed(name) end

--- Pauses a scheduled event by its ID.
---@param id integer
---@return boolean
function LScheduler:pause(id) end

--- Pauses a scheduled event by its string name.
---@param name string
---@return boolean
function LScheduler:pauseNamed(name) end

--- Resets an event's remaining time back to its original interval.
---@param id integer
---@return boolean
function LScheduler:resetEvent(id) end

--- Resumes a paused event by its ID.
---@param id integer
---@return boolean
function LScheduler:resume(id) end

--- Resumes a paused event by its string name.
---@param name string
---@return boolean
function LScheduler:resumeNamed(name) end

--- Changes the repeat interval of an existing event.
---@param id integer
---@param interval number
---@return boolean
function LScheduler:setInterval(id, interval) end

--- Sets a global time-scale multiplier for this scheduler.
---@param scale number
---@return nil
function LScheduler:setTimeScale(scale) end

--- Returns the type name of this object.
---@return string
function LScheduler:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LScheduler:typeOf(name) end

--- Advances all timers by dt seconds, firing due callbacks.
---@param dt number
---@return number
function LScheduler:update(dt) end

--- Advances frame-based events by one frame, firing due callbacks.
---@return number
function LScheduler:updateFrames() end

--- Schedules a one-shot callback that fires after `delay` wall-clock seconds,
---@param delay number
---@param func function
---@return nil
lurek.time.afterReal = function(delay, func) end

--- Creates a new Scheduler loaded with a sequenced one-shot chain.
---@param steps table
---@return Scheduler
lurek.time.chain = function(steps) end

--- Returns the rolling-average frame delta time in seconds.
---@return number
lurek.time.getAverageDelta = function() end

--- Returns the delta time in seconds for the current frame.
---@return number
lurek.time.getDelta = function() end

--- Returns the current frames-per-second measurement.
---@return number
lurek.time.getFPS = function() end

--- Returns the total number of frames rendered since engine start.
---@return number
lurek.time.getFrameCount = function() end

--- Returns the high-resolution elapsed time since engine start in seconds.
---@return number
lurek.time.getMicroTime = function() end

--- Returns the fixed timestep used by `process_physics` callbacks (seconds).
---@return number
lurek.time.getPhysicsDelta = function() end

--- Returns the maximum number of physics sub-steps allowed per frame.
---@return number
lurek.time.getPhysicsMaxSteps = function() end

--- Returns the exponential moving-average of frame deltas in seconds.
---@return number
lurek.time.getSmoothedDelta = function() end

--- Returns the total elapsed time since engine start in seconds.
---@return number
lurek.time.getTime = function() end

--- Creates a new independent Scheduler for managing timed callbacks.
---@return Scheduler
lurek.time.newScheduler = function() end

--- Sets the fixed timestep for `process_physics` callbacks (seconds).
---@param dt number
---@return nil
lurek.time.setPhysicsDelta = function(dt) end

--- Sets the maximum number of physics sub-steps allowed per frame (clamped 1â€“64).
---@param n integer
lurek.time.setPhysicsMaxSteps = function(n) end

--- Sets the smoothing factor (alpha) for `getSmoothedDelta`. Must be in [0.01, 1.0].
---@param alpha number
---@return nil
lurek.time.setSmoothingFactor = function(alpha) end

--- Suspends execution for the given number of seconds.
---@param seconds number
---@return nil
lurek.time.sleep = function(seconds) end

--- Advances the timer by one frame, returning the delta time.
---@return number
lurek.time.step = function() end

--- Advances all real-time timers by one tick; called automatically each frame.
---@return table
lurek.time.tickRealTimers = function() end

--- Advances all `lurek.timer.wait()` coroutines by one tick; called each frame.
---@return table
lurek.time.tickWaits = function() end

--- Yields the current Lua coroutine for at least `frames` engine frames.
---@param frames integer
---@return nil
lurek.time.waitFrames = function(frames) end

--- Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
---@param seconds number
---@return nil
lurek.time.waitSeconds = function(seconds) end

---@class lurek.tween
lurek.tween = {}

--- Lua-side spring handle: wraps [`SpringSystem`] and a registry reference to the target table.
---@class LSpring
LSpring = {}

--- Stops the spring. The engine will drop it on the next `update(dt)` call.
---@return nil
function LSpring:cancel() end

--- Returns the current interpolated position for the named field, or `nil`.
---@param field string
---@return number
function LSpring:getPosition(field) end

--- Returns `true` if the spring has not been cancelled or settled.
---@return boolean
function LSpring:isActive() end

--- Returns `true` when all spring axes have converged within `precision`.
---@return boolean
function LSpring:isSettled() end

--- Updates the damping coefficient on all axes.
---@param value number
---@return nil
function LSpring:setDamping(value) end

--- Updates the stiffness constant on all axes.
---@param value number
---@return nil
function LSpring:setStiffness(value) end

--- Updates target values for all fields present in `fields_table`.
---@param fields_table table
---@return nil
function LSpring:setTarget(fields_table) end

--- Returns the type name of this object.
---@return string
function LSpring:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LSpring:typeOf(name) end

--- Advances the spring by `dt` seconds and writes positions to the target table.
---@param dt number
---@return boolean
function LSpring:update(dt) end

--- A managed interpolation from start to end values over time.
---@class LTween
LTween = {}

--- Cancels this tween immediately; fires the `onCancel` callback if set.
---@param ud any
---@return nil
LTween.cancel = function(ud) end

--- Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
---@return number
function LTween:getProgress() end

--- Returns true if the tween is still running (not completed or cancelled).
---@return boolean
function LTween:isActive() end

--- Sets a callback called when the tween is cancelled. Returns self.
---@param self Tween
---@param f function
---@return Tween
LTween.onCancel = function(self, f) end

--- Sets a callback to fire when the tween finishes all cycles. Returns self for chaining.
---@param self Tween
---@param f function
---@return Tween
LTween.onComplete = function(self, f) end

--- Sets a callback called every tick with the current eased `t` (0..=1). Returns self.
---@param self Tween
---@param f function
---@return Tween
LTween.onUpdate = function(self, f) end

--- Pauses this tween; time stops advancing but the tween is not cancelled.
---@return nil
function LTween:pause() end

--- Resumes a paused tween, continuing from the position where it was paused.
---@return nil
function LTween:resume() end

--- Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
---@param n integer
---@return nil
function LTween:setRepeat(n) end

--- Enables or disables yoyo (ping-pong) on each repeat cycle.
---@param enabled boolean
---@return nil
function LTween:setYoyo(enabled) end

--- Returns the type name of this object.
---@return string
function LTween:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTween:typeOf(name) end

--- A group of animations that run simultaneously over the same duration.
---@class LTweenParallel
LTweenParallel = {}

--- Adds an existing LuaTween to the parallel group; marks the tween as owned.
---@param self TweenParallel
---@param tween Tween
---@return nil
LTweenParallel.add = function(self, tween) end

--- Cancels the parallel group immediately.
---@return nil
function LTweenParallel:cancel() end

--- Returns true if the parallel is running and not yet complete.
---@return boolean
function LTweenParallel:isActive() end

--- Sets a callback fired when all child tweens finish. Returns self.
---@param self TweenParallel
---@param fn function
---@return TweenParallel
LTweenParallel.onComplete = function(self, fn) end

--- Marks the parallel as active. Returns self.
---@param self TweenParallel
---@return TweenParallel
LTweenParallel.start = function(self) end

--- Creates and adds an inline tween entry to the parallel group. Returns self.
---@param self TweenParallel
---@param duration number
---@param target table
---@param fields table
---@param easing? string
---@return TweenParallel
LTweenParallel.tween = function(self, duration, target, fields, easing) end

--- Returns the type name of this object.
---@return string
function LTweenParallel:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTweenParallel:typeOf(name) end

--- A chained sequence of animations that run one after another.
---@class LTweenSequence
LTweenSequence = {}

--- Appends an immediate callback step. Returns self.
---@param self TweenSequence
---@param fn function
---@return TweenSequence
LTweenSequence.callback = function(self, fn) end

--- Cancels the sequence and stops all pending steps.
---@return nil
function LTweenSequence:cancel() end

--- Appends a delay step that waits `seconds` before proceeding. Returns self.
---@param self TweenSequence
---@param seconds number
---@param fn? function
---@return TweenSequence
LTweenSequence.delay = function(self, seconds, fn) end

--- Returns true if the sequence has been started and has not yet completed.
---@return boolean
function LTweenSequence:isActive() end

--- Sets a callback fired when all steps complete. Returns self.
---@param self TweenSequence
---@param fn function
---@return TweenSequence
LTweenSequence.onComplete = function(self, fn) end

--- Marks the sequence as active so `lurek.tween.update(dt)` begins ticking it. Returns self.
---@param self TweenSequence
---@return TweenSequence
LTweenSequence.start = function(self) end

--- Appends a tween step: animates `fields` on `target` over `duration`. Returns self.
---@param self TweenSequence
---@param duration number
---@param target table
---@param fields table
---@param easing? string
---@return TweenSequence
LTweenSequence.tween = function(self, duration, target, fields, easing) end

--- Returns the type name of this object.
---@return string
function LTweenSequence:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTweenSequence:typeOf(name) end

--- Lua-side wrapper around the pure-Rust [`TweenState`] timing core.
---@class LTweenState
---@field paused boolean  whether the tween is currently paused
LTweenState = {}

--- Returns whether the tween state has completed.
---@return boolean
function LTweenState:isComplete() end

--- Interpolates from `start` to `finish` using the eased tween progress.
---@param start number
---@param finish number
---@return number
function LTweenState:lerp(start, finish) end

--- Resets the tween state to elapsed time zero.
---@return nil
function LTweenState:reset() end

--- Returns the raw 0..1 playback progress.
---@return number
function LTweenState:t() end

--- Advances the tween state by `dt` seconds.
---@param dt number
---@return boolean
function LTweenState:tick(dt) end

--- Returns the type name of this object.
---@return string
function LTweenState:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTweenState:typeOf(name) end

--- Cancels all active tweens, sequences, parallels, and springs immediately.
---@return nil
lurek.tween.cancelAll = function() end

--- Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
---@param seconds number
---@param fn? function
---@return TweenSequence
lurek.tween.delay = function(seconds, fn) end

--- Returns the number of currently active tween objects (tweens + seqs + pars).
---@return number
lurek.tween.getActiveCount = function() end

--- Returns a list of all available easing names (built-in + custom).
---@return table
lurek.tween.getEasingNames = function() end

--- Creates a standalone tween timing state without registering it with the engine.
---@param duration number
---@param easing? string
---@return TweenState
lurek.tween.newState = function(duration, easing) end

--- Creates an empty TweenParallel. Add entries with :tween() or :add(tween),
---@return TweenParallel
lurek.tween.parallel = function() end

--- Registers a custom easing function under `name`. `fn(t)` receives 0..1, returns 0..1.
---@param name string
---@param fn function
---@return nil
lurek.tween.registerEasing = function(name, fn) end

--- Creates an empty TweenSequence. Add steps with :tween(), :delay(), :callback(),
---@return TweenSequence
lurek.tween.sequence = function() end

--- Creates a physics-based spring animation that drives named fields on `target_table`
---@param target_table table
---@param fields_table table
---@param opts? table
---@return Spring
lurek.tween.spring = function(target_table, fields_table, opts) end

--- Sugar for `tween()` with `target` first â€” natural read order.
---@param target table
---@param fields table
---@param duration number
---@param easing? string
---@return Tween
lurek.tween.to = function(target, fields, duration, easing) end

--- Creates a new property tween and registers it for automatic updating.
---@param duration number
---@param target table
---@param fields table
---@param easing? string
---@return Tween
lurek.tween.tween = function(duration, target, fields, easing) end

--- Advances all active tweens, sequences, and parallels by `dt` seconds.
---@param dt number
---@return nil
lurek.tween.update = function(dt) end

---@class lurek.ui
lurek.ui = {}

--- Adds Accordion-specific methods (1-based sections in Lua).
---@class LAccordion
LAccordion = {}

--- Adds a section entry to this Accordion widget.
---@param title string
---@param content_idx? integer
---@return nil
function LAccordion:addSection(title, content_idx) end

--- Returns the section count of this Accordion widget.
---@return number
function LAccordion:getSectionCount() end

--- Returns the section title of this Accordion widget.
---@param section_idx integer
---@return nil
function LAccordion:getSectionTitle(section_idx) end

--- Returns true if exclusive is enabled for this Accordion widget.
---@return boolean
function LAccordion:isExclusive() end

--- Returns true if section expanded is enabled for this Accordion widget.
---@param section_idx integer
---@return boolean
function LAccordion:isSectionExpanded(section_idx) end

--- Sets the exclusive for this Accordion widget.
---@param v boolean
---@return nil
function LAccordion:setExclusive(v) end

--- Toggles the expanded/collapsed status of an Accordion section.
---@param section_idx integer
---@return nil
function LAccordion:toggleSection(section_idx) end

--- Lua wrapper for a stacked area chart renderer.
---@class LAreaChart
LAreaChart = {}

--- Renders the area chart into an existing ImageData.
---@param target ImageData
---@return nil
function LAreaChart:drawToImage(target) end

--- Sets the maximum Y value for axis scaling.
---@param v number
---@return nil
function LAreaChart:setYMax(v) end

--- Returns the type name of this object.
---@return string
function LAreaChart:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LAreaChart:typeOf(name) end

--- Adds Badge-specific methods to a widget table.
---@class LBadge
LBadge = {}

--- Returns the raw count of this Badge widget.
---@return number
function LBadge:getCount() end

--- Returns the display text of this Badge widget, e.g. "99+" when over the max.
---@return string
function LBadge:getDisplayText() end

--- Sets the count displayed on this Badge widget.
---@param count integer
---@return nil
function LBadge:setCount(count) end

--- Lua wrapper for a grouped bar chart renderer.
---@class LBarChart
LBarChart = {}

--- Renders the bar chart into an existing ImageData.
---@param target ImageData
---@return nil
function LBarChart:drawToImage(target) end

--- Returns the type name of this object.
---@return string
function LBarChart:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LBarChart:typeOf(name) end

--- Adds Button-specific methods to a widget table.
---@class LButton
LButton = {}

--- Returns the text of this Button widget.
---@return string
function LButton:getText() end

--- Sets the text for this Button widget.
---@param text string
---@return nil
function LButton:setText(text) end

--- Adds CheckBox-specific methods to a widget table.
---@class LCheckbox
LCheckbox = {}

--- Returns the text of this Checkbox widget.
---@return string
function LCheckbox:getText() end

--- Returns true if checked is enabled for this Checkbox widget.
---@return boolean
function LCheckbox:isChecked() end

--- Sets the checked for this Checkbox widget.
---@param checked boolean
---@return nil
function LCheckbox:setChecked(checked) end

--- Sets the text for this Checkbox widget.
---@param text string
---@return nil
function LCheckbox:setText(text) end

--- Adds ColorPicker-specific methods.
---@class LColorPicker
LColorPicker = {}

--- Returns the color of this Color_Picker widget.
---@return number
---@return number
---@return number
---@return number
function LColorPicker:getColor() end

--- Returns the color mode of this Color_Picker widget.
---@return string
function LColorPicker:getColorMode() end

--- Returns the show alpha of this Color_Picker widget.
---@return boolean
function LColorPicker:getShowAlpha() end

--- Sets the color for this Color_Picker widget.
---@param r number
---@param green number
---@param b number
---@param a? number
---@return nil
function LColorPicker:setColor(r, green, b, a) end

--- Sets the color mode for this Color_Picker widget.
---@param mode string
---@return nil
function LColorPicker:setColorMode(mode) end

--- Registers a callback invoked when this widget's value changes.
---@param fn function
---@return nil
function LColorPicker:setOnChange(fn) end

--- Sets the show alpha for this Color_Picker widget.
---@param v boolean
---@return nil
function LColorPicker:setShowAlpha(v) end

--- Adds ComboBox-specific methods (1-based indices in Lua).
---@class LComboBox
LComboBox = {}

--- Adds a item entry to this Combo_Box widget.
---@param text string
---@return nil
function LComboBox:addItem(text) end

--- Clears all items entries from this Combo_Box widget.
---@return nil
function LComboBox:clearItems() end

--- Returns the item of this Combo_Box widget.
---@param index integer
---@return string
function LComboBox:getItem(index) end

--- Returns the item count of this Combo_Box widget.
---@return number
function LComboBox:getItemCount() end

--- Returns the selected index of this Combo_Box widget.
---@return number
function LComboBox:getSelectedIndex() end

--- Returns the selected item of this Combo_Box widget.
---@return string
function LComboBox:getSelectedItem() end

--- Removes the item from this Combo_Box widget.
---@param index integer
---@return nil
function LComboBox:removeItem(index) end

--- Sets the selected index for this Combo_Box widget.
---@param index integer
---@return nil
function LComboBox:setSelectedIndex(index) end

--- Adds Dialog-specific methods.
---@class LDialog
LDialog = {}

--- Adds a button entry to this Dialog widget.
---@param text string
---@param cb? function
---@return nil
function LDialog:addButton(text, cb) end

--- Closes and removes this dialog from the screen.
---@return nil
function LDialog:close() end

--- Returns the content of this Dialog widget.
---@return number
function LDialog:getContent() end

--- Returns the title of this Dialog widget.
---@return string
function LDialog:getTitle() end

--- Returns true if modal is enabled for this Dialog widget.
---@return boolean
function LDialog:isModal() end

--- Returns true if open is enabled for this Dialog widget.
---@return boolean
function LDialog:isOpen() end

--- Performs the open operation on this Dialog widget.
---@return nil
function LDialog:open() end

--- Sets the content for this Dialog widget.
---@param content_idx? integer
---@return nil
function LDialog:setContent(content_idx) end

--- Sets the modal for this Dialog widget.
---@param v boolean
---@return nil
function LDialog:setModal(v) end

--- Registers a callback invoked when this dialog is closed.
---@param fn function
---@return nil
function LDialog:setOnClose(fn) end

--- Sets the title for this Dialog widget.
---@param title string
---@return nil
function LDialog:setTitle(title) end

--- Adds DockPanel-specific methods.
---@class LDockPanel
LDockPanel = {}

--- Performs the dock operation on this Dock_Panel widget.
---@param child_idx integer
---@param side string
---@return nil
function LDockPanel:dock(child_idx, side) end

--- Returns the docked count of this Dock_Panel widget.
---@return number
function LDockPanel:getDockedCount() end

--- Returns the split size of this Dock_Panel widget.
---@param side string
---@return nil
function LDockPanel:getSplitSize(side) end

--- Sets the split size for this Dock_Panel widget.
---@param side string
---@param size number
---@return nil
function LDockPanel:setSplitSize(side, size) end

--- Performs the undock operation on this Dock_Panel widget.
---@param child_idx integer
---@return nil
function LDockPanel:undock(child_idx) end

--- Adds GUITable-specific methods (1-based rows/cols in Lua).
---@class LGuiTable
LGuiTable = {}

--- Adds a column entry to this Gui_Table widget.
---@param header string
---@param width? number
---@return nil
function LGuiTable:addColumn(header, width) end

--- Adds a row entry to this Gui_Table widget.
---@param cells table
---@return nil
function LGuiTable:addRow(cells) end

--- Returns the cell of this Gui_Table widget.
---@param row integer
---@param col integer
---@return nil
function LGuiTable:getCell(row, col) end

--- Returns the column count of this Gui_Table widget.
---@return number
function LGuiTable:getColumnCount() end

--- Returns the row count of this Gui_Table widget.
---@return number
function LGuiTable:getRowCount() end

--- Returns the selected row of this Gui_Table widget.
---@return nil
function LGuiTable:getSelectedRow() end

--- Returns true if sortable is enabled for this Gui_Table widget.
---@return boolean
function LGuiTable:isSortable() end

--- Sets the cell for this Gui_Table widget.
---@param row integer
---@param col integer
---@param text string
---@return nil
function LGuiTable:setCell(row, col, text) end

--- Registers a callback invoked when a table row is selected.
---@param fn function
---@return nil
function LGuiTable:setOnSelect(fn) end

--- Sets the selected row for this Gui_Table widget.
---@param row? integer
---@return nil
function LGuiTable:setSelectedRow(row) end

--- Sets the sortable for this Gui_Table widget.
---@param v boolean
---@return nil
function LGuiTable:setSortable(v) end

--- Adds GUIWindow-specific methods.
---@class LGuiWindow
LGuiWindow = {}

--- Returns the title of this Gui_Window widget.
---@return string
function LGuiWindow:getTitle() end

--- Returns true if closeable is enabled for this Gui_Window widget.
---@return boolean
function LGuiWindow:isCloseable() end

--- Returns true if draggable is enabled for this Gui_Window widget.
---@return boolean
function LGuiWindow:isDraggable() end

--- Returns true if resizable is enabled for this Gui_Window widget.
---@return boolean
function LGuiWindow:isResizable() end

--- Sets the closeable for this Gui_Window widget.
---@param v boolean
---@return nil
function LGuiWindow:setCloseable(v) end

--- Sets the draggable for this Gui_Window widget.
---@param v boolean
---@return nil
function LGuiWindow:setDraggable(v) end

--- Registers a callback invoked when this window is closed.
---@param fn function
---@return nil
function LGuiWindow:setOnClose(fn) end

--- Sets the resizable for this Gui_Window widget.
---@param v boolean
---@return nil
function LGuiWindow:setResizable(v) end

--- Sets the title for this Gui_Window widget.
---@param title string
---@return nil
function LGuiWindow:setTitle(title) end

--- Adds ImageWidget-specific methods.
---@class LImageWidget
LImageWidget = {}

--- Returns the scale mode of this Image_Widget widget.
---@return string
function LImageWidget:getScaleMode() end

--- Returns the tint of this Image_Widget widget.
---@return number
---@return number
---@return number
---@return number
function LImageWidget:getTint() end

--- Sets the scale mode for this Image_Widget widget.
---@param mode string
---@return nil
function LImageWidget:setScaleMode(mode) end

--- Sets the tint for this Image_Widget widget.
---@param r number
---@param green number
---@param b number
---@param a? number
---@return nil
function LImageWidget:setTint(r, green, b, a) end

--- Adds Label-specific methods to a widget table.
---@class LLabel
LLabel = {}

--- Returns the text of this Label widget.
---@return string
function LLabel:getText() end

--- Sets the text for this Label widget.
---@param text string
---@return nil
function LLabel:setText(text) end

--- Adds Layout-specific methods.
---@class LLayout
LLayout = {}

--- Returns the align of this Layout widget.
---@return string
function LLayout:getAlign() end

--- Returns the direction of this Layout widget.
---@return string
function LLayout:getDirection() end

--- Returns the justify of this Layout widget.
---@return string
function LLayout:getJustify() end

--- Returns the spacing of this Layout widget.
---@return number
function LLayout:getSpacing() end

--- Returns the wrap of this Layout widget.
---@return boolean
function LLayout:getWrap() end

--- Sets the align for this Layout widget.
---@param align string
---@return nil
function LLayout:setAlign(align) end

--- Sets the columns for this Layout widget.
---@param n integer
---@return nil
function LLayout:setColumns(n) end

--- Sets the direction for this Layout widget.
---@param dir string
---@return nil
function LLayout:setDirection(dir) end

--- Sets the justify for this Layout widget.
---@param justify string
---@return nil
function LLayout:setJustify(justify) end

--- Sets the spacing for this Layout widget.
---@param spacing number
---@return nil
function LLayout:setSpacing(spacing) end

--- Sets the wrap for this Layout widget.
---@param wrap boolean
---@return nil
function LLayout:setWrap(wrap) end

--- Lua wrapper for a line chart renderer.
---@class LLineChart
LLineChart = {}

--- Renders the line chart into an existing ImageData.
---@param target ImageData
---@return nil
function LLineChart:drawToImage(target) end

--- Sets the maximum X value for axis scaling.
---@param v number
---@return nil
function LLineChart:setXMax(v) end

--- Sets the maximum Y value for axis scaling.
---@param v number
---@return nil
function LLineChart:setYMax(v) end

--- Returns the type name of this object.
---@return string
function LLineChart:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LLineChart:typeOf(name) end

--- Adds ListBox-specific methods (1-based indices in Lua).
---@class LListBox
LListBox = {}

--- Adds a item entry to this List_Box widget.
---@param text string
---@return nil
function LListBox:addItem(text) end

--- Clears all items entries from this List_Box widget.
---@return nil
function LListBox:clearItems() end

--- Returns the item of this List_Box widget.
---@param index integer
---@return string
function LListBox:getItem(index) end

--- Returns the item count of this List_Box widget.
---@return number
function LListBox:getItemCount() end

--- Returns the selected index of this List_Box widget.
---@return number
function LListBox:getSelectedIndex() end

--- Removes the item from this List_Box widget.
---@param index integer
---@return nil
function LListBox:removeItem(index) end

--- Sets the item height for this List_Box widget.
---@param h number
---@return nil
function LListBox:setItemHeight(h) end

--- Sets the selected index for this List_Box widget.
---@param index integer
---@return nil
function LListBox:setSelectedIndex(index) end

--- Adds MenuBar-specific methods.
---@class LMenuBar
LMenuBar = {}

--- Adds a menu entry to this Menu_Bar widget.
---@param menu_idx integer
---@return nil
function LMenuBar:addMenu(menu_idx) end

--- Returns the menu count of this Menu_Bar widget.
---@return number
function LMenuBar:getMenuCount() end

--- Returns the menus of this Menu_Bar widget.
---@return nil
function LMenuBar:getMenus() end

--- Removes the menu from this Menu_Bar widget.
---@param menu_idx integer
---@return nil
function LMenuBar:removeMenu(menu_idx) end

--- Adds MenuItem-specific methods.
---@class LMenuItem
LMenuItem = {}

--- Adds a sub item entry to this Menu_Item widget.
---@param child_idx integer
---@return nil
function LMenuItem:addSubItem(child_idx) end

--- Returns the shortcut of this Menu_Item widget.
---@return string
function LMenuItem:getShortcut() end

--- Returns the sub items of this Menu_Item widget.
---@return nil
function LMenuItem:getSubItems() end

--- Returns the text of this Menu_Item widget.
---@return string
function LMenuItem:getText() end

--- Returns true if checked is enabled for this Menu_Item widget.
---@return boolean
function LMenuItem:isChecked() end

--- Sets the checked for this Menu_Item widget.
---@param v boolean
---@return nil
function LMenuItem:setChecked(v) end

--- Registers a callback invoked when this menu item is clicked.
---@param fn function
---@return nil
function LMenuItem:setOnClick(fn) end

--- Sets the shortcut for this Menu_Item widget.
---@param shortcut string
---@return nil
function LMenuItem:setShortcut(shortcut) end

--- Sets the text for this Menu_Item widget.
---@param text string
---@return nil
function LMenuItem:setText(text) end

--- Adds NinePatch-specific methods.
---@class LNinePatch
LNinePatch = {}

--- Returns the image dimensions of this Nine_Patch widget.
---@return integer
---@return integer
function LNinePatch:getImageDimensions() end

--- Returns the insets of this Nine_Patch widget.
---@return integer
---@return integer
---@return integer
---@return integer
function LNinePatch:getInsets() end

--- Returns the slices of this Nine_Patch widget.
---@return table
function LNinePatch:getSlices() end

--- Sets the image dimensions for this Nine_Patch widget.
---@param w integer
---@param h integer
---@return nil
function LNinePatch:setImageDimensions(w, h) end

--- Sets the insets for this Nine_Patch widget.
---@param left integer
---@param top integer
---@param right integer
---@param bottom integer
---@return nil
function LNinePatch:setInsets(left, top, right, bottom) end

--- Adds Panel-specific methods.
---@class LPanel
LPanel = {}

--- Returns the title of this Panel widget.
---@return string
function LPanel:getTitle() end

--- Sets the scrollable for this Panel widget.
---@param scrollable boolean
---@return nil
function LPanel:setScrollable(scrollable) end

--- Sets the title for this Panel widget.
---@param title string
---@return nil
function LPanel:setTitle(title) end

--- Lua wrapper for a pie chart renderer.
---@class LPieChart
LPieChart = {}

--- Renders the pie chart into an existing ImageData.
---@param target ImageData
---@return nil
function LPieChart:drawToImage(target) end

--- Returns the type name of this object.
---@return string
function LPieChart:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LPieChart:typeOf(name) end

--- Adds ProgressBar-specific methods to a widget table.
---@class LProgressBar
LProgressBar = {}

--- Returns the max of this Progress_Bar widget.
---@return number
function LProgressBar:getMax() end

--- Returns the min of this Progress_Bar widget.
---@return number
function LProgressBar:getMin() end

--- Returns the progress of this Progress_Bar widget.
---@return number
function LProgressBar:getProgress() end

--- Returns the value of this Progress_Bar widget.
---@return number
function LProgressBar:getValue() end

--- Sets the range for this Progress_Bar widget.
---@param min number
---@param max number
---@return nil
function LProgressBar:setRange(min, max) end

--- Sets the value for this Progress_Bar widget.
---@param v number
---@return nil
function LProgressBar:setValue(v) end

--- Adds RadioButton-specific methods.
---@class LRadioButton
LRadioButton = {}

--- Returns the group of this Radio_Button widget.
---@return string
function LRadioButton:getGroup() end

--- Returns the text of this Radio_Button widget.
---@return string
function LRadioButton:getText() end

--- Returns true if selected is enabled for this Radio_Button widget.
---@return boolean
function LRadioButton:isSelected() end

--- Sets the group for this Radio_Button widget.
---@param group string
---@return nil
function LRadioButton:setGroup(group) end

--- Registers a callback invoked when this widget's value changes.
---@param fn function
---@return nil
function LRadioButton:setOnChange(fn) end

--- Sets the selected for this Radio_Button widget.
---@param v boolean
---@return nil
function LRadioButton:setSelected(v) end

--- Sets the text for this Radio_Button widget.
---@param text string
---@return nil
function LRadioButton:setText(text) end

--- Lua wrapper for a scatter plot renderer.
---@class LScatterPlot
LScatterPlot = {}

--- Renders the scatter plot into an existing ImageData.
---@param target ImageData
---@return nil
function LScatterPlot:drawToImage(target) end

--- Sets the X-axis data range.
---@param min number
---@param max number
---@return nil
function LScatterPlot:setXRange(min, max) end

--- Sets the Y-axis data range.
---@param min number
---@param max number
---@return nil
function LScatterPlot:setYRange(min, max) end

--- Returns the type name of this object.
---@return string
function LScatterPlot:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LScatterPlot:typeOf(name) end

--- Adds ScrollBar-specific methods.
---@class LScrollBar
LScrollBar = {}

--- Returns the content size of this Scroll_Bar widget.
---@return number
function LScrollBar:getContentSize() end

--- Returns the scroll position of this Scroll_Bar widget.
---@return number
function LScrollBar:getScrollPosition() end

--- Returns the view size of this Scroll_Bar widget.
---@return number
function LScrollBar:getViewSize() end

--- Returns true if vertical is enabled for this Scroll_Bar widget.
---@return boolean
function LScrollBar:isVertical() end

--- Sets the content size for this Scroll_Bar widget.
---@param v number
---@return nil
function LScrollBar:setContentSize(v) end

--- Registers a callback invoked when this widget's value changes.
---@param fn function
---@return nil
function LScrollBar:setOnChange(fn) end

--- Sets the scroll position for this Scroll_Bar widget.
---@param v number
---@return nil
function LScrollBar:setScrollPosition(v) end

--- Sets the view size for this Scroll_Bar widget.
---@param v number
---@return nil
function LScrollBar:setViewSize(v) end

--- Adds ScrollPanel-specific methods.
---@class LScrollPanel
LScrollPanel = {}

--- Returns the content size of this Scroll_Panel widget.
---@return number
---@return number
function LScrollPanel:getContentSize() end

--- Returns the max scroll of this Scroll_Panel widget.
---@return number
---@return number
function LScrollPanel:getMaxScroll() end

--- Returns the scroll position of this Scroll_Panel widget.
---@return number
---@return number
function LScrollPanel:getScrollPosition() end

--- Returns the scroll speed of this Scroll_Panel widget.
---@return number
function LScrollPanel:getScrollSpeed() end

--- Sets the content size for this Scroll_Panel widget.
---@param w number
---@param h number
---@return nil
function LScrollPanel:setContentSize(w, h) end

--- Sets the scroll position for this Scroll_Panel widget.
---@param x number
---@param y number
---@return nil
function LScrollPanel:setScrollPosition(x, y) end

--- Sets the scroll speed for this Scroll_Panel widget.
---@param speed number
---@return nil
function LScrollPanel:setScrollSpeed(speed) end

--- Adds Separator-specific methods.
---@class LSeparator
LSeparator = {}

--- Returns the thickness of this Separator widget.
---@return number
function LSeparator:getThickness() end

--- Returns true if vertical is enabled for this Separator widget.
---@return boolean
function LSeparator:isVertical() end

--- Sets the thickness for this Separator widget.
---@param thickness number
---@return nil
function LSeparator:setThickness(thickness) end

--- Sets the vertical for this Separator widget.
---@param v boolean
---@return nil
function LSeparator:setVertical(v) end

--- Adds Slider-specific methods to a widget table.
---@class LSlider
LSlider = {}

--- Returns the max of this Slider widget.
---@return number
function LSlider:getMax() end

--- Returns the min of this Slider widget.
---@return number
function LSlider:getMin() end

--- Returns the value of this Slider widget.
---@return number
function LSlider:getValue() end

--- Sets the range for this Slider widget.
---@param min number
---@param max number
---@return nil
function LSlider:setRange(min, max) end

--- Sets the step for this Slider widget.
---@param step number
---@return nil
function LSlider:setStep(step) end

--- Sets the value for this Slider widget.
---@param v number
---@return nil
function LSlider:setValue(v) end

--- Adds SpinBox-specific methods to a widget table.
---@class LSpinBox
LSpinBox = {}

--- Decrements the value by one step.
---@return nil
function LSpinBox:decrement() end

--- Returns the current value of this SpinBox widget.
---@return number
function LSpinBox:getValue() end

--- Increments the value by one step.
---@return nil
function LSpinBox:increment() end

--- Sets the valid range for this SpinBox widget.
---@param min number
---@param max number
---@return nil
function LSpinBox:setRange(min, max) end

--- Sets the increment step for this SpinBox widget.
---@param step number
---@return nil
function LSpinBox:setStep(step) end

--- Sets the value for this SpinBox widget.
---@param v number
---@return nil
function LSpinBox:setValue(v) end

--- Adds SplitPanel-specific methods.
---@class LSplitPanel
LSplitPanel = {}

--- Returns the first child of this Split_Panel widget.
---@return nil
function LSplitPanel:getFirstChild() end

--- Returns the min panel size of this Split_Panel widget.
---@return number
function LSplitPanel:getMinPanelSize() end

--- Returns the orientation of this Split_Panel widget.
---@return string
function LSplitPanel:getOrientation() end

--- Returns the second child of this Split_Panel widget.
---@return nil
function LSplitPanel:getSecondChild() end

--- Returns the split position of this Split_Panel widget.
---@return number
function LSplitPanel:getSplitPosition() end

--- Sets the first child for this Split_Panel widget.
---@param child_idx integer
---@return nil
function LSplitPanel:setFirstChild(child_idx) end

--- Sets the min panel size for this Split_Panel widget.
---@param v number
---@return nil
function LSplitPanel:setMinPanelSize(v) end

--- Sets the orientation for this Split_Panel widget.
---@param v string
---@return nil
function LSplitPanel:setOrientation(v) end

--- Sets the second child for this Split_Panel widget.
---@param child_idx integer
---@return nil
function LSplitPanel:setSecondChild(child_idx) end

--- Sets the split position for this Split_Panel widget.
---@param v number
---@return nil
function LSplitPanel:setSplitPosition(v) end

--- Adds StatusBar-specific methods.
---@class LStatusBar
LStatusBar = {}

--- Adds a section entry to this Status_Bar widget.
---@param text string
---@param width? number
---@return nil
function LStatusBar:addSection(text, width) end

--- Returns the section count of this Status_Bar widget.
---@return number
function LStatusBar:getSectionCount() end

--- Returns the section text of this Status_Bar widget.
---@param section_idx integer
---@return number
function LStatusBar:getSectionText(section_idx) end

--- Resizes the section list for this Status_Bar widget.
---@param count integer
---@return nil
function LStatusBar:setSectionCount(count) end

--- Sets the section text for this Status_Bar widget.
---@param section_idx integer
---@param text string
---@return nil
function LStatusBar:setSectionText(section_idx, text) end

--- Compatibility shim for assigning a widget to a section.
---@param section_idx integer
---@param widget any
---@return nil
function LStatusBar:setSectionWidget(section_idx, widget) end

--- Adds Switch-specific methods to a widget table.
---@class LSwitch
LSwitch = {}

--- Returns the on/off state of this Switch widget.
---@return boolean
function LSwitch:isOn() end

--- Sets the on/off state of this Switch widget.
---@param on boolean
---@return nil
function LSwitch:setOn(on) end

--- Toggles the on/off state of this Switch widget.
---@return nil
function LSwitch:toggle() end

--- Adds TabBar-specific methods (1-based indices in Lua).
---@class LTabBar
LTabBar = {}

--- Adds a tab entry to this Tab_Bar widget.
---@param label string
---@return nil
function LTabBar:addTab(label) end

--- Returns the active tab of this Tab_Bar widget.
---@return number
function LTabBar:getActiveTab() end

--- Returns the tab of this Tab_Bar widget.
---@param index integer
---@return number
function LTabBar:getTab(index) end

--- Returns the tab count of this Tab_Bar widget.
---@return number
function LTabBar:getTabCount() end

--- Removes the tab from this Tab_Bar widget.
---@param index integer
---@return nil
function LTabBar:removeTab(index) end

--- Sets the active tab for this Tab_Bar widget.
---@param index integer
---@return nil
function LTabBar:setActiveTab(index) end

--- Adds TextInput-specific methods to a widget table.
---@class LTextInput
LTextInput = {}

--- Returns the cursor position of this Text_Input widget.
---@return number
function LTextInput:getCursorPosition() end

--- Returns the placeholder of this Text_Input widget.
---@return string
function LTextInput:getPlaceholder() end

--- Returns the text of this Text_Input widget.
---@return string
function LTextInput:getText() end

--- Returns true if focused is enabled for this Text_Input widget.
---@return boolean
function LTextInput:isFocused() end

--- Sets the max length for this Text_Input widget.
---@param n integer
---@return nil
function LTextInput:setMaxLength(n) end

--- Sets the placeholder for this Text_Input widget.
---@param text string
---@return nil
function LTextInput:setPlaceholder(text) end

--- Sets the text for this Text_Input widget.
---@param text string
---@return nil
function LTextInput:setText(text) end

--- Lua-side wrapper around a GUI [`Theme`].
---@class LTheme
LTheme = {}

--- Returns the type name of this object.
---@return string
function LTheme:type() end

--- Returns true if this object is of the given type.
---@param name string
---@return boolean
function LTheme:typeOf(name) end

--- Adds Toast-specific methods.
---@class LToast
LToast = {}

--- Returns the duration of this Toast widget.
---@return number
function LToast:getDuration() end

--- Returns the message of this Toast widget.
---@return string
function LToast:getMessage() end

--- Returns the progress of this Toast widget.
---@return number
function LToast:getProgress() end

--- Returns true if expired is enabled for this Toast widget.
---@return boolean
function LToast:isExpired() end

--- Sets the duration for this Toast widget.
---@param d number
---@return nil
function LToast:setDuration(d) end

--- Sets the message for this Toast widget.
---@param msg string
---@return nil
function LToast:setMessage(msg) end

--- Adds Toolbar-specific methods.
---@class LToolbar
LToolbar = {}

--- Adds a button entry to this Toolbar widget.
---@param id string
---@param tooltip? string
---@return nil
function LToolbar:addButton(id, tooltip) end

--- Adds a separator entry to this Toolbar widget.
---@return nil
function LToolbar:addSeparator() end

--- Adds a spacer entry to this Toolbar widget.
---@param size? number
---@return nil
function LToolbar:addSpacer(size) end

--- Returns the button of this Toolbar widget.
---@param id string
---@return boolean
function LToolbar:getButton(id) end

--- Returns the orientation of this Toolbar widget.
---@return string
function LToolbar:getOrientation() end

--- Returns true if button toggled is enabled for this Toolbar widget.
---@param id string
---@return boolean
function LToolbar:isButtonToggled(id) end

--- Sets the button enabled for this Toolbar widget.
---@param id string
---@param enabled boolean
---@return nil
function LToolbar:setButtonEnabled(id, enabled) end

--- Sets the button toggled for this Toolbar widget.
---@param id string
---@param toggled boolean
---@return nil
function LToolbar:setButtonToggled(id, toggled) end

--- Sets the orientation for this Toolbar widget.
---@param v string
---@return nil
function LToolbar:setOrientation(v) end

--- Adds TooltipPanel-specific methods.
---@class LTooltipPanel
LTooltipPanel = {}

--- Returns the delay of this Tooltip_Panel widget.
---@return number
function LTooltipPanel:getDelay() end

--- Returns the target of this Tooltip_Panel widget.
---@return nil
function LTooltipPanel:getTarget() end

--- Returns the text of this Tooltip_Panel widget.
---@return string
function LTooltipPanel:getText() end

--- Sets the delay for this Tooltip_Panel widget.
---@param v number
---@return nil
function LTooltipPanel:setDelay(v) end

--- Sets the target for this Tooltip_Panel widget.
---@param target? integer
---@return nil
function LTooltipPanel:setTarget(target) end

--- Sets the text for this Tooltip_Panel widget.
---@param text string
---@return nil
function LTooltipPanel:setText(text) end

--- Adds TreeView-specific methods (1-based indices in Lua).
---@class LTreeView
LTreeView = {}

--- Adds a node entry to this Tree_View widget.
---@param text string
---@param parent_index? integer
---@return nil
function LTreeView:addNode(text, parent_index) end

--- Clears all nodes entries from this Tree_View widget.
---@return nil
function LTreeView:clearNodes() end

--- Performs the collapse all operation on this Tree_View widget.
---@return nil
function LTreeView:collapseAll() end

--- Performs the collapse node operation on this Tree_View widget.
---@param index integer
---@return nil
function LTreeView:collapseNode(index) end

--- Performs the expand all operation on this Tree_View widget.
---@return nil
function LTreeView:expandAll() end

--- Performs the expand node operation on this Tree_View widget.
---@param index integer
---@return nil
function LTreeView:expandNode(index) end

--- Returns the child nodes of this Tree_View widget.
---@param index integer
---@return nil
function LTreeView:getChildNodes(index) end

--- Returns the node count of this Tree_View widget.
---@return number
function LTreeView:getNodeCount() end

--- Returns the node depth of this Tree_View widget.
---@param index integer
---@return nil
function LTreeView:getNodeDepth(index) end

--- Returns the node text of this Tree_View widget.
---@param index integer
---@return string
function LTreeView:getNodeText(index) end

--- Returns the parent node of this Tree_View widget.
---@param index integer
---@return nil
function LTreeView:getParentNode(index) end

--- Returns the selected node of this Tree_View widget.
---@return number
function LTreeView:getSelectedNode() end

--- Returns true if expanded is enabled for this Tree_View widget.
---@param index integer
---@return boolean
function LTreeView:isExpanded(index) end

--- Returns true if node expanded is enabled for this Tree_View widget.
---@param index integer
---@return boolean
function LTreeView:isNodeExpanded(index) end

--- Removes the node from this Tree_View widget.
---@param index integer
---@return nil
function LTreeView:removeNode(index) end

--- Sets the node icon for this Tree_View widget.
---@param index integer
---@param icon string
---@return nil
function LTreeView:setNodeIcon(index, icon) end

--- Sets the node text for this Tree_View widget.
---@param index integer
---@param text string
---@return nil
function LTreeView:setNodeText(index, text) end

--- Sets the selected node for this Tree_View widget.
---@param index integer
---@return nil
function LTreeView:setSelectedNode(index) end

--- Toggles the expanded/collapsed status of a Tree_View node.
---@param index integer
---@return nil
function LTreeView:toggleNode(index) end

--- Adds a child widget to this container.
---@param child table|integer
---@return nil
lurek.ui.addChild = function(child) end

--- Queues a toast notification from a table.
---@param toast table
---@return nil
lurek.ui.addToast = function(toast) end

--- Anchors this widget to a world-space entity by its numeric ID.
---@param entity_id integer
lurek.ui.attachToEntity = function(entity_id) end

--- Registers a data-binding key on this widget.
---@param key string
lurek.ui.bind = function(key) end

--- Removes all anchor constraints.
---@return nil
lurek.ui.clearAnchor = function() end

--- Removes keyboard focus from this widget so key events go to the next focusable.
---@return nil
lurek.ui.clearFocus = function() end

--- Returns whether (x, y) is inside this widget.
---@param x number
---@param y number
---@return boolean
---@return nil
lurek.ui.containsPoint = function(x, y) end

--- Removes the entity anchor from this widget, restoring normal layout positioning.
---@return nil
lurek.ui.detachFromEntity = function() end

--- Invokes all registered on_draw callbacks, each receiving the widget's
---@return nil
lurek.ui.draw = function() end

--- Renders the UI widget tree to a CPU ImageData at the given resolution.
---@param w integer
---@param h integer
---@return ImageData
lurek.ui.drawToImage = function(w, h) end

--- Instantly fades the widget in (sets alpha to `1.0`).
---@return nil
lurek.ui.fadeIn = function() end

--- Instantly fades the widget out (sets alpha to `0.0` and hides it).
---@return nil
lurek.ui.fadeOut = function() end

--- Recursively searches for a widget by id starting from this widget.
---@param id string
---@return table
---@return nil
lurek.ui.findById = function(id) end

--- Returns true if the widget tree changed since the last call, then resets the flag.
---@return boolean
lurek.ui.flushCache = function() end

--- Moves focus to the next focusable widget.
---@return nil
lurek.ui.focusNext = function() end

--- Moves focus to the previous focusable widget.
---@return nil
lurek.ui.focusPrev = function() end

--- Returns the widget's current alpha transparency.
---@return number
lurek.ui.getAlpha = function() end

--- Returns the number of children in this container.
---@return number
---@return nil
lurek.ui.getChildCount = function() end

--- Returns this container's children as widget-handle tables.
---@return table
lurek.ui.getChildren = function() end

--- Returns the flex-grow factor.
---@return number
---@return nil
lurek.ui.getFlexGrow = function() end

--- Returns the flex-shrink factor.
---@return number
lurek.ui.getFlexShrink = function() end

--- Returns the focused widget index or nil.
---@return number
---@return nil
lurek.ui.getFocus = function() end

--- Returns the widget string identifier.
---@return string
---@return nil
lurek.ui.getId = function() end

--- Returns the widget margin (top, right, bottom, left).
---@return number
---@return number
---@return number
---@return number
---@return nil
lurek.ui.getMargin = function() end

--- Returns the maximum widget size.
---@return number
---@return number
---@return nil
lurek.ui.getMaxSize = function() end

--- Returns the minimum widget size.
---@return number
---@return number
---@return nil
lurek.ui.getMinSize = function() end

--- Returns the widget padding (top, right, bottom, left).
---@return number
---@return number
---@return number
---@return number
---@return nil
lurek.ui.getPadding = function() end

--- Returns the widget position.
---@return number
---@return number
---@return nil
lurek.ui.getPosition = function() end

--- Returns the computed screen-space rectangle after layout.
---@return number
---@return number
---@return number
---@return number
lurek.ui.getRect = function() end

--- Returns the root panel widget table.
---@return table
lurek.ui.getRoot = function() end

--- Returns the current width and height of the widget in UI pixels.
---@return number
---@return number
---@return nil
lurek.ui.getSize = function() end

--- Returns the widget interaction state name.
---@return string
---@return nil
lurek.ui.getState = function() end

--- Returns whether a theme is set.
---@return boolean
---@return nil
lurek.ui.getTheme = function() end

--- Returns the number of active toasts.
---@return number
---@return nil
lurek.ui.getToastCount = function() end

--- Returns the widget tooltip text.
---@return string
---@return nil
lurek.ui.getTooltip = function() end

--- Returns the total widget count in the context.
---@return number
---@return nil
lurek.ui.getWidgetCount = function() end

--- Returns the widget z-order.
---@return number
---@return nil
lurek.ui.getZOrder = function() end

--- Returns whether the widget is enabled.
---@return boolean
---@return nil
lurek.ui.isEnabled = function() end

--- Returns whether the widget is visible.
---@return boolean
---@return nil
lurek.ui.isVisible = function() end

--- Forwards a key press event to the GUI.
---@param key string
---@return boolean
---@return nil
lurek.ui.keypressed = function(key) end

--- Load a widget tree from a Lua table definition and attach it to the UI
---@param def table
---@return number
lurek.ui.loadLayout = function(def) end

--- Load a widget tree from a TOML layout file and attach it to the UI root.
---@param path string
---@return number
lurek.ui.loadLayoutFile = function(path) end

--- Forwards a mouse move event to the GUI.
---@param x number
---@param y number
---@return boolean
---@return nil
lurek.ui.mousemoved = function(x, y) end

--- Forwards a mouse press event to the GUI.
---@param x number
---@param y number
---@param button? number
---@return boolean
---@return nil
lurek.ui.mousepressed = function(x, y, button) end

--- Forwards a mouse release event to the GUI.
---@param x number
---@param y number
---@param button? number
---@return boolean
---@return nil
lurek.ui.mousereleased = function(x, y, button) end

--- Creates a collapsible accordion widget.
---@return table
---@return nil
lurek.ui.newAccordion = function() end

--- Creates a new stacked-area chart.
---@param opts table
---@return AreaChart
lurek.ui.newAreaChart = function(opts) end

--- Creates a badge widget displaying a numeric count.
---@param count? integer
---@return table
lurek.ui.newBadge = function(count) end

--- Creates and returns a new bar chart widget attached to this image widget.
---@param opts table
---@return BarChart
lurek.ui.newBarChart = function(opts) end

--- Creates and returns a new interactive button widget as a child of this widget.
---@param text? string
---@return table
---@return nil
lurek.ui.newButton = function(text) end

--- Creates a checkbox widget.
---@param text? string
---@return table
---@return nil
lurek.ui.newCheckbox = function(text) end

--- Creates a color picker widget.
---@return table
---@return nil
lurek.ui.newColorPicker = function() end

--- Creates a dropdown combo box widget.
---@return table
---@return nil
lurek.ui.newComboBox = function() end

--- Creates a new widget with custom Lua-driven rendering.
---@param config? table
---@return table
lurek.ui.newCustomWidget = function(config) end

--- Creates a modal dialog widget.
---@param title? string
---@return table
---@return nil
lurek.ui.newDialog = function(title) end

--- Creates and returns a new docking panel that arranges children along its edges.
---@return table
---@return nil
lurek.ui.newDockPanel = function() end

--- Creates an image display widget.
---@return table
---@return nil
lurek.ui.newImageWidget = function() end

--- Creates a text label widget.
---@param text? string
---@return table
---@return nil
lurek.ui.newLabel = function(text) end

--- Creates a flexbox layout container.
---@param direction? string
---@return table
---@return nil
lurek.ui.newLayout = function(direction) end

--- Creates a new line chart.
---@param opts table
---@return LineChart
lurek.ui.newLineChart = function(opts) end

--- Creates a selectable list widget.
---@return table
---@return nil
lurek.ui.newList = function() end

--- Creates a menu bar widget.
---@return table
---@return nil
lurek.ui.newMenuBar = function() end

--- Creates a menu item widget.
---@param text? string
---@return table
---@return nil
lurek.ui.newMenuItem = function(text) end

--- Creates a 9-patch slicer widget.
---@return table
---@return nil
lurek.ui.newNinePatch = function() end

--- Creates a container panel widget.
---@return table
---@return nil
lurek.ui.newPanel = function() end

--- Creates and returns a new pie chart widget attached to this image widget.
---@param opts table
---@return PieChart
lurek.ui.newPieChart = function(opts) end

--- Creates a progress bar widget.
---@param min? number
---@param max? number
---@return table
---@return nil
lurek.ui.newProgressBar = function(min, max) end

--- Creates a grouped radio button widget.
---@param text string
---@param group string
---@return table
---@return nil
lurek.ui.newRadioButton = function(text, group) end

--- Creates a new scatter plot.
---@param opts table
---@return ScatterPlot
lurek.ui.newScatterPlot = function(opts) end

--- Creates a scroll bar widget.
---@param vertical? boolean
---@return table
---@return nil
lurek.ui.newScrollBar = function(vertical) end

--- Creates a scrollable panel widget.
---@return table
---@return nil
lurek.ui.newScrollPanel = function() end

--- Creates a separator line.
---@param vertical? boolean
---@return table
---@return nil
lurek.ui.newSeparator = function(vertical) end

--- Creates a value slider widget.
---@param min? number
---@param max? number
---@return table
---@return nil
lurek.ui.newSlider = function(min, max) end

--- Creates a spacing filler widget.
---@param w? number
---@param h? number
---@return table
---@return nil
lurek.ui.newSpacer = function(w, h) end

--- Creates a numeric spin box widget with increment and decrement buttons.
---@param min? number
---@param max? number
---@return table
lurek.ui.newSpinBox = function(min, max) end

--- Creates a resizable split panel.
---@param orientation? string
---@return table
---@return nil
lurek.ui.newSplitPanel = function(orientation) end

--- Creates a status bar widget.
---@return table
---@return nil
lurek.ui.newStatusBar = function() end

--- Creates a toggle switch widget.
---@param on? boolean
---@return table
lurek.ui.newSwitch = function(on) end

--- Creates a tab bar widget.
---@return table
---@return nil
lurek.ui.newTabBar = function() end

--- Creates a data table widget.
---@return table
---@return nil
lurek.ui.newTable = function() end

--- Creates a text input widget.
---@return table
---@return nil
lurek.ui.newTextInput = function() end

--- Creates a new theme instance.
---@return Theme
lurek.ui.newTheme = function() end

--- Creates a toast notification widget.
---@param message string
---@param duration number
---@return table
---@return nil
lurek.ui.newToast = function(message, duration) end

--- Creates a toolbar widget.
---@param orientation? string
---@return table
---@return nil
lurek.ui.newToolbar = function(orientation) end

--- Creates a tooltip panel widget.
---@param text? string
---@return table
---@return nil
lurek.ui.newTooltipPanel = function(text) end

--- Creates a collapsible tree view widget.
---@return table
---@return nil
lurek.ui.newTreeView = function() end

--- Creates a draggable window widget.
---@param title? string
---@return table
---@return nil
lurek.ui.newWindow = function(title) end

--- Parses a widget state string, returning the canonical form or nil if invalid.
---@param state string
---@return string
lurek.ui.parseWidgetState = function(state) end

--- Removes a child widget from this container.
---@param child table|integer
---@return nil
lurek.ui.removeChild = function(child) end

--- Render the current UI widget tree to a PNG file for testing purposes.
---@param width number
---@param height number
---@param path string
lurek.ui.renderToImage = function(width, height, path) end

--- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
---@param alpha number
lurek.ui.setAlpha = function(alpha) end

--- Sets anchor edges (left, top, right, bottom).
---@param left number
---@param top number
---@param right number
---@param bottom number
---@return nil
lurek.ui.setAnchor = function(left, top, right, bottom) end

--- Sets center anchor offsets.
---@param cx? number
---@param cy? number
---@return nil
lurek.ui.setAnchorCenter = function(cx, cy) end

--- Installs the built-in dark theme as the active GUI theme.
---@return nil
lurek.ui.setDefaultTheme = function() end

--- Sets whether the widget is enabled.
---@param enabled boolean
---@return nil
lurek.ui.setEnabled = function(enabled) end

--- Sets the flex-grow factor.
---@param grow number
---@return nil
lurek.ui.setFlexGrow = function(grow) end

--- Sets the flex-shrink factor.
---@param shrink number
---@return nil
lurek.ui.setFlexShrink = function(shrink) end

--- Sets keyboard focus to a widget or clears it.
---@param widget? table
---@return nil
lurek.ui.setFocus = function(widget) end

--- Sets the widget string identifier.
---@param id string
---@return nil
lurek.ui.setId = function(id) end

--- Sets widget margin (CSS-like: top, right?, bottom?, left?).
---@param top number
---@param right? number
---@param bottom? number
---@param left? number
---@return nil
lurek.ui.setMargin = function(top, right, bottom, left) end

--- Sets the maximum widget size.
---@param w number
---@param h number
---@return nil
lurek.ui.setMaxSize = function(w, h) end

--- Sets the minimum widget size.
---@param w number
---@param h number
---@return nil
lurek.ui.setMinSize = function(w, h) end

--- Registers a callback invoked when this widget's value changes.
---@param fn function
---@return nil
lurek.ui.setOnChange = function(fn) end

--- Registers a callback invoked when this widget is clicked.
---@param fn function
---@return nil
lurek.ui.setOnClick = function(fn) end

--- Stores a custom draw callback for later invocation.
---@param fn function
---@param f any
---@return nil
lurek.ui.setOnDraw = function(fn, f) end

--- Sets widget padding (CSS-like: top, right?, bottom?, left?).
---@param top number
---@param right? number
---@param bottom? number
---@param left? number
---@return nil
lurek.ui.setPadding = function(top, right, bottom, left) end

--- Sets the widget position.
---@param x number
---@param y number
---@return nil
lurek.ui.setPosition = function(x, y) end

--- Sets the width and height of the widget in UI pixels.
---@param w number
---@param h number
---@return nil
lurek.ui.setSize = function(w, h) end

--- Sets the active GUI theme.
---@param theme Theme
---@return nil
lurek.ui.setTheme = function(theme) end

--- Sets the widget tooltip text.
---@param text string
---@return nil
lurek.ui.setTooltip = function(text) end

--- Sets the viewport dimensions used for anchor constraints and layout.
---@param w number
---@param h number
---@return nil
lurek.ui.setViewport = function(w, h) end

--- Shows or hides the widget; hidden widgets are not rendered or interactive.
---@param visible boolean
---@return nil
lurek.ui.setVisible = function(visible) end

--- Sets the widget z-order for draw sorting.
---@param z number
---@return nil
lurek.ui.setZOrder = function(z) end

--- Instantly moves the widget to `(x, y)` and makes it visible.
---@param x number
---@param y number
lurek.ui.slideIn = function(x, y) end

--- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
---@param x number
---@param y number
lurek.ui.slideOut = function(x, y) end

--- Forwards text input to the focused text input widget.
---@param text string
---@return boolean
---@return nil
lurek.ui.textinput = function(text) end

--- Returns the Lua type name of this widget (e.g. "LButton").
---@return string
lurek.ui.type = function() end

--- Returns true if this widget is of the given type, "LWidget", or "Object".
---@param name string
---@return boolean
lurek.ui.typeOf = function(name) end

--- Removes the data-binding key from this widget.
---@return nil
lurek.ui.unbind = function() end

--- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
---@param dt number
---@return nil
lurek.ui.update = function(dt) end

--- Updates all widgets that have a data-binding key registered via `:bind(key)`.
---@param data table
lurek.ui.update_bindings = function(data) end

--- Forwards a mouse wheel event to the GUI.
---@param x number
---@param y number
---@return boolean
---@return nil
lurek.ui.wheelmoved = function(x, y) end

---@class lurek.window
lurek.window = {}

--- Requests the window to close.
---@return nil
lurek.window.close = function() end

--- Requests the window manager to bring the window to the foreground.
---@return nil
lurek.window.focus = function() end

--- Converts physical pixels to device-independent coordinates.
---@param value number
---@return number
lurek.window.fromPixels = function(value) end

--- Returns the DPI scaling factor for the window.
---@return number
lurek.window.getDPIScale = function() end

--- Returns the desktop resolution as width, height.
---@return integer
---@return integer
lurek.window.getDesktopDimensions = function() end

--- Returns the window dimensions as width, height.
---@return integer
---@return integer
lurek.window.getDimensions = function() end

--- Returns the number of connected displays.
---@return number
lurek.window.getDisplayCount = function() end

--- Returns the name of the current display.
---@param display? integer
---@return string
lurek.window.getDisplayName = function(display) end

--- Returns the current display orientation.
---@return string
lurek.window.getDisplayOrientation = function() end

--- Returns the fullscreen state and type string.
---@return boolean
---@return string
lurek.window.getFullscreen = function() end

--- Returns all available fullscreen video modes.
---@return table
lurek.window.getFullscreenModes = function() end

--- Returns the logical game height in virtual pixels.
---@return number
lurek.window.getGameHeight = function() end

--- Returns the logical game width in virtual pixels.
---@return number
lurek.window.getGameWidth = function() end

--- Returns the window height in pixels.
---@return number
lurek.window.getHeight = function() end

--- Returns the window dimensions and mode flags as width, height, flags.
---@return integer
---@return integer
---@return table
lurek.window.getMode = function() end

--- Returns the native DPI scale factor.
---@return number
lurek.window.getNativeDPIScale = function() end

--- Returns the window dimensions in physical pixels.
---@return integer
---@return integer
lurek.window.getPixelDimensions = function() end

--- Returns the window position as x, y in screen coordinates.
---@return integer
---@return integer
lurek.window.getPosition = function() end

--- Returns the safe display area as x, y, w, h.
---@return number
---@return number
---@return number
---@return number
lurek.window.getSafeArea = function() end

--- Returns viewport scale and offset information as a table.
---@return table
lurek.window.getScaleInfo = function() end

--- Returns the current viewport scale mode string.
---@return string
lurek.window.getScaleMode = function() end

--- Returns the OS color theme preference.
---@return string
lurek.window.getSystemTheme = function() end

--- Returns the current window title.
---@return string
lurek.window.getTitle = function() end

--- Returns the current VSync mode integer.
---@return number
lurek.window.getVSync = function() end

--- Returns the window width in pixels.
---@return number
lurek.window.getWidth = function() end

--- Returns whether the window has keyboard focus.
---@return boolean
lurek.window.hasFocus = function() end

--- Returns whether the mouse cursor is inside the window.
---@return boolean
lurek.window.hasMouseFocus = function() end

--- Returns whether the window is in fullscreen mode.
---@return boolean
lurek.window.isFullscreen = function() end

--- Returns whether high-DPI rendering is allowed.
---@return boolean
lurek.window.isHighDPIAllowed = function() end

--- Returns whether the window is maximized.
---@return boolean
lurek.window.isMaximized = function() end

--- Returns whether the window is minimized.
---@return boolean
lurek.window.isMinimized = function() end

--- Returns whether the window is open.
---@return boolean
lurek.window.isOpen = function() end

--- Returns whether the window can be resized by the user.
---@return boolean
lurek.window.isResizable = function() end

--- Returns whether the window is visible.
---@return boolean
lurek.window.isVisible = function() end

--- Maximizes the window to fill the desktop.
---@return nil
lurek.window.maximize = function() end

--- Minimizes the window to the taskbar.
---@return nil
lurek.window.minimize = function() end

--- Registers a callback invoked (with the new scale factor) when the display
---@param fn function
---@return nil
lurek.window.onDpiChange = function(fn) end

--- Opens a blocking native file-open dialog. Returns the chosen path string
---@param opts? table
---@return string
lurek.window.openFileDialog = function(opts) end

--- Polls for a pending DPI change event and returns the new scale factor if any.
---@return table
lurek.window.pollDpiChange = function() end

--- Flashes the window in the taskbar to request user attention.
---@return nil
lurek.window.requestAttention = function() end

--- Restores the window from minimized or maximized state.
---@return nil
lurek.window.restore = function() end

--- Enables or disables fullscreen mode.
---@param enabled boolean
---@param fstype? string
---@return nil
lurek.window.setFullscreen = function(enabled, fstype) end

--- Sets the window icon from a file path.
---@param path string
---@return nil
lurek.window.setIcon = function(path) end

--- Resizes the window and optionally changes fullscreen and vsync.
---@param w integer
---@param h integer
---@param flags? table
---@return nil
lurek.window.setMode = function(w, h, flags) end

--- Moves the window to the given screen position.
---@param x integer
---@param y integer
---@return nil
lurek.window.setPosition = function(x, y) end

--- Sets the viewport scale mode.
---@param mode string
---@return nil
lurek.window.setScaleMode = function(mode) end

--- Sets the window title bar text.
---@param title string
---@return nil
lurek.window.setTitle = function(title) end

--- Sets the VSync mode (1=on, 0=off, -1=adaptive).
---@param mode integer
---@return nil
lurek.window.setVSync = function(mode) end

--- Shows a platform-native message box dialog.
---@param title string
---@param message string
---@param boxType? string
---@param btnType? string
---@return string
lurek.window.showMessageBox = function(title, message, boxType, btnType) end

--- Converts a device-independent coordinate to physical pixels.
---@param value number
---@return number
lurek.window.toPixels = function(value) end
