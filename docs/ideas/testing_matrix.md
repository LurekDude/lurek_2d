# testing_matrix — iLove Module Test Coverage Matrix

> **Test location:** `tests/ilove/` (unit), `tests/integration/` (integration)
> **Runner:** `tests/runner.lua` with `--layer ilove`
> **Purpose:** Defines what to test for each iLove-specific module (unit tests) and which module pairs need integration testing, with a 1-2 sentence description of each test's intent.

---

## Unit Tests by Module

### luna2d.init

| Test | Description |
|---|---|
| module loads | Verify that `require("ilove")` returns a non-nil table. |
| lazy access returns submodules | Accessing `luna2d.class`, `luna2d.signal`, etc. auto-loads submodules on first access. |
| multiple access returns same table | Repeated access to the same submodule returns the identical table reference (no duplicate loading). |
| registerUpdater / unregisterUpdater | Named update hooks are called each frame and can be removed to stop execution. |
| registerDrawer / unregisterDrawer | Named draw hooks are called each draw pass and can be removed cleanly. |
| update passes dt | The dt value given to `luna2d.update()` is forwarded to all registered updaters. |
| _VERSION is a string | `luna2d._VERSION` returns a version string. |

### luna2d.class

| Test | Description |
|---|---|
| creates a named class | `class("Foo")` produces a table with `__name` set to `"Foo"`. |
| creates instances via __call | Calling the class table invokes `init()` and returns a new instance with fields set. |
| isInstance works | `C.isInstance(obj)` returns true for instances of C and false for plain tables or numbers. |
| supports inheritance | Child classes inherit parent methods and can add their own; `init` chains manually. |
| __tostring includes class name | `tostring(obj)` contains the class name for debugging. |
| __tostring includes _id if set | If the instance has a `_id` field, it appears in the tostring output. |
| instances have separate state | Two instances of the same class hold independent field values. |
| methods are shared via metatable | Method functions are shared across instances through the metatable, not duplicated. |
| init called on creation | The `init` method is invoked automatically during instantiation. |
| isInstance with parent class | `Parent.isInstance(childObj)` returns true (polymorphic identity check). |
| child can override parent methods | A child method with the same name shadows the parent's version. |
| child can call parent method explicitly | `Parent.method(self, ...)` allows explicit super-call from child overrides. |
| class without init does not error | Classes without an `init` method can still be instantiated safely. |
| three-level inheritance | Grandchild → Child → Base inheritance chain works correctly with method resolution. |

### luna2d.animation

| Test | Description |
|---|---|
| creates an animation | `newAnimation()` returns a non-nil animation object with configurable frame dimensions. |
| getCurrentFrame starts at 1 | Newly created animations begin at frame 1 (1-based indexing). |
| getFrameCount returns total | After adding N frames, `getFrameCount()` returns N. |
| play / isPlaying | `play()` sets the animation to playing state; `isPlaying()` reflects the change. |
| update advances frames | Calling `update(dt)` while playing advances past frame boundaries based on accumulated time. |
| pause stops advancement | `pause()` freezes the current frame; subsequent `update()` calls don't change it. |
| play after pause resumes | Calling `play()` after `pause()` resumes from the paused frame. |
| stop resets to frame 1 | `stop()` rewinds to frame 1 and sets playing to false. |
| restart plays from frame 1 | `restart()` rewinds to frame 1 but keeps playing state active. |
| setCurrentFrame jumps | Directly jumping to a specific frame index works without needing to advance through time. |
| setLoop / isLooping | Loop flag can be toggled; non-looping animations stop at the last frame. |
| setSpeed / getSpeed | Playback speed multiplier can be set and retrieved (affects frame advancement rate). |
| setFlipX / isFlippedX | Horizontal flip state can be toggled for mirrored rendering. |
| setFlipY / isFlippedY | Vertical flip state can be toggled for vertical mirroring. |
| isFinished on non-looping | A non-looping animation reports `isFinished()` true after advancing past all frames. |
| AnimationSet add/play/getCurrentName | AnimationSet holds named animations; `play("name")` switches active animation and `getCurrentName()` reflects it. |

### luna2d.camera

| Test | Description |
|---|---|
| newCamera creates instance | `newCamera()` returns a non-nil camera with default position at origin. |
| newCamera with position | `newCamera(x, y)` initializes position to the given coordinates. |
| setPosition / getPosition | Position round-trip: set then get returns the same x,y values. |
| setX / getX, setY / getY | Individual axis accessors work independently. |
| move offsets position | `move(dx, dy)` adds the delta to the current position. |
| setZoom / getZoom | Zoom factor round-trip works correctly. |
| setRotation / getRotation | Rotation angle (radians) round-trip works correctly. |
| resize | `resize(w, h)` changes the camera's viewport dimensions. |
| getViewport | Returns the current viewport dimensions as multiple values. |
| setBounds / clearBounds | Position clamping limits can be set and then cleared. |
| shake / isShaking | `shake(intensity, duration)` triggers camera shake; `isShaking()` tracks the state. |
| update | `update(dt)` processes shake decay, follow smoothing, and other time-dependent state. |
| screenToWorld | Transforms screen pixel coordinates to world coordinates accounting for position, zoom, and rotation. |
| worldToScreen | Reverse transform from world coordinates back to screen pixels. |
| getVisibleArea | Returns the world-space rectangle currently visible through the camera viewport. |
| setFollow / clearFollow | Camera can track a target table with `x,y` fields; `clearFollow()` stops tracking. |
| setDeadzone / clearDeadzone | Deadzone rectangle defines a region where target movement doesn't trigger camera scrolling. |
| setTargetZoom | Smooth zoom transition toward a target zoom value over time. |
| attach / detach | `attach()` pushes the camera transform onto the graphics stack; `detach()` pops it. |

### luna2d.vec2

| Test | Description |
|---|---|
| creates a vector | `vec2.new(x, y)` returns a vector with `.x` and `.y` fields. |
| add (operator +) | Vector addition returns a new vector with component-wise sums. |
| sub (operator -) | Vector subtraction returns a new vector with component-wise differences. |
| scale (operator *) | Scalar multiplication scales both components. |
| length | `length()` computes the Euclidean magnitude (e.g. 3,4 → 5). |
| normalize | `normalize()` produces a unit vector (length ≈ 1.0). |
| dot product | `dot(other)` returns the scalar dot product (perpendicular vectors → 0). |
| cross product | `cross(other)` returns the 2D cross product (scalar z-component of the 3D cross). |
| distance | `distance(other)` computes Euclidean distance between two position vectors. |
| angle | `angle()` returns the angle in radians from the positive x-axis. |
| rotate | Rotating a vector by an angle produces correct component changes. |

### luna2d.geometry

| Test | Description |
|---|---|
| distancePoints | Computes Euclidean distance between two 2D points (e.g. 0,0 to 3,4 → 5). |
| distancePointsSq | Returns squared distance (avoids sqrt for performance comparisons). |
| angleBetween | Returns the angle in radians between two points. |
| midpoint | Computes the center point between two 2D positions. |
| lerp | Linear interpolation between two points at a given t value (0..1). |
| lineLength | Returns the length of a line segment defined by two endpoints. |
| distancePointToLine | Computes the perpendicular distance from a point to an infinite line. |
| closestPointOnSegment | Finds the nearest point on a line segment to a given point. |
| linesIntersect | Detects whether two line segments cross and returns the intersection point. |
| linesIntersect parallel | Returns false for parallel (non-crossing) line segments. |
| pointInCircle | Tests whether a point lies inside a circle defined by center and radius. |
| circlesOverlap | Tests whether two circles defined by center+radius overlap. |
| pointInRect | Tests whether a point is inside an axis-aligned rectangle. |
| rectsOverlap | Tests whether two axis-aligned rectangles overlap. |
| circleRectOverlap | Tests whether a circle and an axis-aligned rectangle overlap. |

### luna2d.grid

| Test | Description |
|---|---|
| newGrid creates instance | `newGrid(w, h)` creates a grid with the specified dimensions. |
| getWidth / getHeight | Returns the grid's column and row counts. |
| isValid | Checks whether coordinates are within grid bounds (1-based). |
| setWalkable / isWalkable | Cells default to walkable; can be set to non-walkable and queried back. |
| setCost / getCost | Per-cell movement cost can be set and retrieved for weighted pathfinding. |
| getNeighbors | Returns adjacent cells (4-directional or 8-directional depending on config). |
| findPath | A* pathfinding from start to goal returns an ordered list of waypoints. |
| findPath blocked | Returns nil or empty table when no path exists (wall blocks all routes). |
| floodFill | Floods from a seed cell and returns all connected walkable cells. |

### luna2d.noise

| Test | Description |
|---|---|
| module-level noise | `noise.noise(x, y)` returns a number (stateless noise sampling). |
| noise with seed | Same coordinates + same seed produces identical values (deterministic). |
| newNoiseGenerator | Creates a configurable noise generator instance with seed. |
| get/set seed | Seed can be changed after creation; generator produces different values with different seeds. |
| get/set octaves | Number of fractal octaves for multi-frequency noise layering. |
| get/set frequency | Base frequency controls the scale of noise features. |
| get/set amplitude | Amplitude controls the output value range. |
| get/set lacunarity | Lacunarity controls frequency increase per octave. |
| get/set persistence | Persistence controls amplitude decrease per octave. |
| noise2d returns in range | `noise2d(x, y)` returns a value in [-1, 1]. |
| fbm | Fractal Brownian motion combines multiple octaves for natural-looking terrain noise. |

### luna2d.spatial

| Test | Description |
|---|---|
| newSpatialHash | Creates a spatial hash with configurable cell size. |
| getCellSize | Returns the configured cell size used for spatial bucketing. |
| insert / getCount | Inserting an object with a bounding rect increases the count. |
| remove | Removing an object decreases the count back to zero. |
| has | Checks whether a specific object key is currently in the spatial hash. |
| clear | Empties all objects from the hash. |
| queryRect | Returns all objects whose bounds overlap a given query rectangle. |
| queryPoint | Returns all objects whose bounds contain a given point. |
| queryRadius | Returns all objects within a circular radius from a point. |
| update | Moving an object updates its spatial hash bucket positions. |

### luna2d.signal

| Test | Description |
|---|---|
| newSignal | Creates a new signal (event emitter) instance. |
| connect / emit | Connecting a handler then emitting the signal invokes the handler with the emitted value. |
| disconnect | Disconnecting by ID prevents the handler from being called on subsequent emits. |
| getSlotCount | Tracks the number of connected handlers. |
| clear | Removes all connected handlers at once. |
| priority ordering | Higher-priority handlers fire before lower-priority ones. |
| multiple args | `emit(a, b, c)` passes all arguments through to every connected handler. |
| multiple listeners | All connected listeners fire on a single emit (fan-out). |

### luna2d.scheduler

| Test | Description |
|---|---|
| after | Schedules a one-shot callback that fires after a delay (accumulated via `update(dt)`). |
| every | Schedules a repeating callback that fires on interval up to a max repeat count. |
| cancel | Cancels a scheduled task by ID so it never fires. |
| cancelAll | Clears all pending scheduled tasks. |
| getCount | Returns the number of active scheduled tasks. |
| newScheduler | Creates an independent scheduler instance (vs. the global module-level scheduler). |
| instance after / update | Instance-level `after()` and `update()` work the same as the global API. |
| instance every | Instance-level `every()` repeats correctly with independent tick counting. |
| instance cancel | Instance-level cancel removes a task scoped to that scheduler. |

### luna2d.light

| Test | Description |
|---|---|
| newPointLight | Creates a point light at a position with a radius. |
| newSpotLight | Creates a spot light with position, direction angle, and radius. |
| newDirectionalLight | Creates a directional light with an intensity value. |
| newLightWorld | Creates a light world container with specified dimensions. |
| setAmbient / getAmbient | Ambient light color (r,g,b) round-trip on the light world. |
| isEnabled / setEnabled | Light world can be globally enabled/disabled. |
| addLight / removeLight | Lights can be added to and removed from a light world; `getLights()` reflects the change. |
| getLights | Returns a table of all lights currently in the world. |
| resize | Changes the light world's rendering dimensions. |

### luna2d.raycaster

| Test | Description |
|---|---|
| castRay hit | Casts a ray against line segments; returns hit point with x,y and distance on intersection. |
| castRay miss | Returns nil when the ray doesn't intersect any segment. |
| castFan | Casts multiple rays in a fan pattern and returns a table of results per ray. |
| castVisibility | Computes a visibility polygon from a point given surrounding occluder segments. |
| castGridRay | Walks a ray through grid cells using DDA; returns the first blocked cell coordinates. |
| castRay max distance | Respects the maximum distance parameter — segments beyond the limit are ignored. |
| castFan ray count | Fan results table has the correct number of entries matching the requested ray count. |

### luna2d.viewport

| Test | Description |
|---|---|
| newViewport | Creates a viewport instance with default dimensions. |
| newViewport with dimensions | Creates a viewport with specific game width and height. |
| getGameWidth / getGameHeight | Returns the configured logical game resolution. |
| getGameDimensions | Returns both width and height as two values. |
| getScale | Returns the current scale factors (sx, sy) for resolution-independent rendering. |
| getOffset | Returns the letterbox offset values when aspect ratios don't match. |
| getMode / setMode | Scaling mode (e.g. "letterbox", "stretch") can be set and retrieved. |
| setBackgroundColor | Sets the color used for letterbox bars. |
| resize | Updates the viewport when the window dimensions change. |

### luna2d.ai

| Test | Description |
|---|---|
| QLearner create/chooseAction/getQValue | Creates a Q-learning agent; `chooseAction` returns an action string; `getQValue` returns a number. |
| learn sets Q-value | With lr=1.0 and gamma=0.0, learning sets Q exactly to the reward value. |
| setQValue / getBestAction | Manual Q-value override; `getBestAction` returns the action with highest Q. |
| getStateCount / endEpisode | Tracks number of visited states; `endEpisode` increments episode counter and decays exploration. |
| serialize / deserialize | Q-table survives a serialization+deserialization round-trip with values preserved. |
| UtilityAI addAction/evaluate | Utility AI scores actions via callback functions and returns the highest-scoring action. |
| UtilityAI considerations | Adding considerations multiplies into the action score; momentum biases toward the last action. |
| GOAPPlanner plan / unreachable | GOAP planner produces an action sequence to reach a goal state; returns nil when goal is unreachable. |
| GOAPPlanner goals / preconditions | Named goals, preconditions, and effects can be registered and queried. |
| InfluenceMap add/set/get/propagate | Grid-based influence map with layers; `propagate()` spreads values to neighbor cells. |
| InfluenceMap stamp/decay/max/min | Stamp adds influence in a radius; decay reduces values; max/min position queries work. |
| CommandQueue enqueue/update/clear | Queue executes commands in FIFO order with start/update/finish callbacks. |
| CommandQueue pushFront/replace/cancel | Priority insertion, full replacement, and cancellation of the active command. |
| PathGrid create/setWalkable/findPath | Grid-based pathfinding with walkability flags and per-cell costs. |
| FlowField setGoal/getDirection/getDistance | Flow field computes direction vectors and distances from any cell toward a single goal. |
| Squad addMember/setFormation/getFormationPosition | Squad manages members with named formations (line, circle, etc.) and computes per-member positions. |
| Blackboard set/get/has/remove/clear | Key-value store with typed accessors (setNumber, setBool, setString) and parent fallback chains. |
| StateMachine setInitialState/forceState/update | FSM with enter/exit/update callbacks per state; transitions fire on condition functions. |
| BehaviorTree tick/nodes | BT with Action, Condition, Selector, Sequence, Inverter, Succeeder, Repeater, Parallel nodes. |
| SteeringBehaviors seek/flee/arrive/wander/pursue/evade/flocking | Each steering behavior calculates a 2D force vector; configurable parameters (panic distance, slowing radius, etc.). |
| SteeringManager calculate/combine | Aggregates multiple weighted steering behaviors into a combined force vector. |

### luna2d.entity

| Test | Description |
|---|---|
| newUniverse | Creates an ECS universe container. |
| spawn / kill / isAlive | Entity lifecycle: spawn returns numeric ID, kill removes it, isAlive reflects status. |
| set / get / has / remove | Component CRUD: attach values by name, query existence, remove cleanly. |
| getComponents | Returns all component names attached to an entity. |
| query | Returns all entity IDs that have ALL specified components (AND logic). |
| each | Iterates all entities with a named component, calling a callback with (id, value). |
| getEntityCount / getEntities | Count and list of all alive entities. |
| tags | Bitmap tag system (addTag, hasTag, removeTag) independent of components. |
| blueprints | Define a blueprint template; spawn from blueprint deep-copies all component values. |
| layers | Assign entities to named layers; query by layer for draw ordering or update groups. |
| systems | Register system tables with update/draw methods; dispatch in registration order. |

### luna2d.tween

| Test | Description |
|---|---|
| tween creates instance | `tween(duration, target, values, easing)` returns a tween object. |
| update advances values | Calling `update(dt)` interpolates target table fields toward goal values. |
| isActive / complete | Active while running; becomes inactive after duration is reached. |
| onComplete callback | Callback fires once when the tween finishes. |
| stop / reset | `stop()` halts interpolation; `reset()` reverts to initial values. |
| easing functions | Multiple easing curves (linear, inOutQuad, etc.) produce correct interpolation shapes. |

### luna2d.scene

| Test | Description |
|---|---|
| push / pop | Stack-based scene management with lifecycle callbacks (enter, leave, pause, resume). |
| switchTo | Replaces the top scene without exposing the one below. |
| clear | Removes all scenes from the stack. |
| update / draw | Forwards dt to the top scene's update; calls draw on visible scenes. |
| registerScene / getRegistered | Named scene templates can be registered and retrieved for reuse. |
| transitions | Animated transitions between scenes with progress tracking. |
| DepthSorter | Collects drawable objects with depth values and flushes them in sorted order. |

### luna2d.dialog

| Test | Description |
|---|---|
| newDialog | Creates a dialog tree from a node table structure. |
| start / getCurrentNode | Begins dialog traversal; returns the current node's text and choices. |
| choose | Selects a choice by index, advancing to the next dialog node. |
| getChoiceLabels | Returns available choice labels for the current node. |
| conditions | Dialog choices can have conditions that hide/show them based on external state. |

### luna2d.quest

| Test | Description |
|---|---|
| newQuest / setFlag / getFlag | Creates a quest state manager; flags track completion of quest objectives. |
| counters | Increment/decrement/get counter values for multi-step objectives (e.g. "collect 5 items"). |
| isComplete | Returns true when all required flags or counter thresholds are met. |
| reset | Clears all flags and counters back to initial state. |
| on observer | Register callbacks that fire when specific quest flags change. |

### luna2d.stats

| Test | Description |
|---|---|
| newSheet | Creates a stat sheet with named stats (hp, atk, def, etc.) and base values. |
| getStat / setStat | Read and write individual stat values. |
| buffs | Temporary modifiers (add/multiply) that stack and can be removed. |
| getCurrent | Returns the effective value after applying all active buffs. |
| clamp | Stats can have min/max bounds enforced automatically. |

### luna2d.resource

| Test | Description |
|---|---|
| newResource | Creates a named resource (gold, mana, etc.) with current value and cap. |
| add / spend / getCurrent | Resource arithmetic with overflow prevention at cap and underflow prevention at zero. |
| regen | Per-tick regeneration amount that can be configured. |
| callbacks | Hooks for on-empty, on-full, on-change events. |

### luna2d.inventory

| Test | Description |
|---|---|
| newItem / newItemStack / newSlot / newContainer / newInventory | Full object creation chain from item definition through to inventory container. |
| Item tags / weight / size | Item properties: type-based tags, weight for carry limits, grid size for spatial slots. |
| ItemStack stacking / quantity | Stacks merge items of the same type up to a configurable stack limit. |
| Slot type filter / state | Slots accept only matching item types; state cycles between active/passive/idle. |
| Container add / remove / find | Container CRUD with mode-based behavior (fixed/unlimited/expandable). |
| Equipment slots | Named equipment slots (head, chest, weapon) with equip/unequip asymmetry. |
| ItemSet bonuses | Set bonuses activate when all required set pieces are equipped. |
| Weight limits / subsystem toggles | Weight system can be enabled/disabled; zero weight limit means unlimited. |

### luna2d.savegame

| Test | Description |
|---|---|
| registerProvider / collect | Multiple save providers contribute sections to a unified save data structure. |
| isDirty | Tracks whether any provider has unsaved changes since last save. |
| serialize / deserialize | JSON encode/decode of the collected save data preserves all values. |

### luna2d.graph

| Test | Description |
|---|---|
| newGraph | Creates a directed or undirected graph with nodes and weighted edges. |
| addNode / removeNode | Node lifecycle management with adjacency cleanup on removal. |
| addEdge with weight | Edges connect nodes with optional numeric weights for pathfinding. |
| getNeighbors | Returns all nodes directly connected by edges. |
| findPath | Shortest-path search (Dijkstra/BFS) between two nodes. |
| getConnectedComponents | Identifies disconnected subgraphs within the graph. |

### luna2d.doll

| Test | Description |
|---|---|
| newDoll / newPart | Creates a paper-doll with socket-based part attachment system. |
| attach / detach / detachAll | Parts snap into named sockets; detaching clears the socket. |
| getDrawList | Returns parts sorted by draw order for layered rendering. |
| setPosition / getPosition | Doll position propagated to all attached parts. |
| Part color / visibility | Individual parts can change color tint and visibility state. |

### luna2d.minimap

| Test | Description |
|---|---|
| newMinimap | Creates a minimap with world-to-minimap coordinate scaling. |
| addObject / removeObject | Track objects on the minimap; removal keeps count correct. |
| setCenter | Centers the minimap view on a specific world position. |
| getObjects | Returns all tracked objects with their minimap-space positions. |

### luna2d.overlay

| Test | Description |
|---|---|
| newOverlay | Creates a screen overlay (fade, tint, flash effects). |
| setColor / getColor | Overlay color and alpha can be set and retrieved. |
| fade / flash | Animated fade-in/out and screen flash with configurable duration. |
| isActive | Reports whether an overlay animation is currently playing. |

### luna2d.patterns

| Test | Description |
|---|---|
| CommandStack execute/undo/redo | Command pattern with undo/redo stack for reversible game actions. |
| EventBus subscribe/publish | Decoupled event bus for cross-system communication without direct references. |
| ObjectPool acquire/release | Pre-allocated object pool to avoid runtime allocation (bullet pools, particle pools). |
| StateMachine (patterns) | Lightweight FSM distinct from the AI state machine; used for game state management. |

### luna2d.modding

| Test | Description |
|---|---|
| newMod / register | Create a mod with metadata and register it with the mod manager. |
| hooks onLoad/onEnter/onAchievement | Lifecycle hooks that fire at specific game events; can be enabled/disabled per mod. |
| config values | Mods can expose configuration values that game systems read at runtime. |
| release | Releasing a mod unregisters all its hooks so signals no longer invoke them. |

### luna2d.localization

| Test | Description |
|---|---|
| setLanguage / getLanguage | Switch active language for all subsequent text lookups. |
| getText | Returns the localized string for a key in the active language. |
| format with parameters | String interpolation with named or positional parameters in localized templates. |
| fallback | Missing keys in the active language fall back to a default language. |

### luna2d.network

| Test | Description |
|---|---|
| newUDPClient | Creates a UDP client; `isConnected()` returns false before calling connect. |
| newUDPServer | Creates a UDP server bound to a port. |
| send / receive | Basic message round-trip between client and server (localhost). |
| connection state | Connect/disconnect state transitions tracked independently per client instance. |

### luna2d.devtools

| Test | Description |
|---|---|
| info / warn / error | Structured logging at different severity levels. |
| getLog / clearLog | Retrieve and clear the log buffer for inspection. |
| setLogLevel | Filter log entries below a severity threshold. |
| profilePush / profilePop | Scoped profiling markers for measuring execution time of code sections. |

### luna2d.terminal

| Test | Description |
|---|---|
| newTerminal | Creates an in-game debug terminal for command input. |
| registerCommand / execute | Register named commands with callbacks; execute by name with arguments. |
| getOutput | Returns the terminal's output history as a table of strings. |
| clear | Clears the terminal output buffer. |

### luna2d.dataframe

| Test | Description |
|---|---|
| newDataFrame | Creates a tabular data structure from column definitions. |
| addRow / nrows | Row insertion and count tracking. |
| getColumn / getValue | Access individual columns or cell values by row index and column name. |
| filter | Returns a new DataFrame containing only rows matching a predicate function. |
| sort | Sorts rows by a column in ascending or descending order. |
| select | Projects specific columns into a new, slimmer DataFrame. |
| head / tail | Returns the first/last N rows as a new DataFrame. |
| sum / mean / min / max | Aggregate functions on numeric columns. |
| toJSON / fromJSON / toCSV | Serialization to/from JSON and CSV formats. |

### luna2d.compute

| Test | Description |
|---|---|
| newArray 1D/2D | Creates typed numeric arrays with shape metadata (dimensions, size). |
| zeros / ones / fill | Factory functions that create arrays pre-filled with specific values. |
| get / set | Element access by flat index or multi-dimensional coordinates. |
| arithmetic (add/sub/mul/div) | Element-wise arithmetic operations between arrays. |
| sum / mean / min / max | Reduction operations across array elements. |
| reshape / slice | Reshaping changes the logical dimensions; slicing extracts sub-arrays. |
| dot product | Vector dot product for 1D arrays. |

### luna2d.simulator

| Test | Description |
|---|---|
| newSimulator | Creates an automated input simulator for replay and testing. |
| record / replay | Records input events and replays them with timing. |
| step | Single-step execution for deterministic test playback. |

### luna2d.debugbridge

| Test | Description |
|---|---|
| newServer | Creates a TCP JSON debug server for external tool connections. |
| eval / callStack / getLocals | Remote Lua evaluation, call stack inspection, and locals introspection. |
| screenshot | Captures and delivers a screenshot over the debug protocol. |

### luna2d.gui

| Test | Description |
|---|---|
| Widget hierarchy | Widgets parent-child relationships with add/remove and tree traversal. |
| Layout (flex) | Flexible box layout system for automatic widget positioning. |
| Theme / NinePatch | Theming system with nine-patch sprite support for scalable UI backgrounds. |
| Focus navigation | Keyboard/gamepad focus traversal between interactive widgets. |
| ScrollPanel | Scrollable container with viewport clipping and scroll indicators. |

### ilove_native (C++ DLL)

| Test | Description |
|---|---|
| DLL loads | `require("ilove_native")` loads without error when the DLL is built and on cpath. |
| compute submodule | Native compute arrays with hardware-optimized arithmetic operations. |
| dataframe submodule | Native binary dataframe backend for large-dataset performance. |
| socket submodule | Native socket implementation for low-latency networking. |

---

## Integration Tests — Module Pairs

Each integration test verifies that two iLove modules collaborate correctly when used together. Tests are in `tests/integration/test_{moduleA}_{moduleB}.lua`.

### AI + Other Modules

| Pair | What to Test |
|---|---|
| **ai + graph** | Graph pathfinding result stored in AI blackboard; state machine steps through path waypoints; no-path triggers idle state; shortest weighted path selection; directed graph prevents reverse traversal. |
| **ai + pathfinding (grid + entity)** | AI PathGrid computes path and entity follows waypoints; PathGrid blocked cells align with Grid walkability; FlowField directs multiple entities toward the same goal; grid cost data influences routing. |
| **ai + spatial** | Spatial queryRect detects player entity near guard → state machine transitions to "chase"; player outside detection range keeps guard in "patrol"; spatial update triggers mid-tick transition; blackboard stores query results; removing player from spatial hash reverts AI to idle. |
| **ai + stats** | Blackboard holds live stat Sheet; HP below threshold triggers flee transition; heal buff pushes HP above threshold reverting to combat; state enter callback reads stat values. |

### Animation + Other Modules

| Pair | What to Test |
|---|---|
| **animation + entity** | Entity velocity component directs AnimationSet state transitions (idle vs walk vs run); entity system tick drives `animation:update(dt)`; killing entity doesn't affect the animation object itself; two entities own independent animation timers. |
| **animation + scheduler** | Scheduler `after()` fires callback that switches AnimationSet state; chained delays produce correct animation sequences; `every()` advances animation per interval; cancelling prevents animation change. |
| **animation + signal** | onFrame callback on attack frame emits hit signal; foot-step and hit frames fire different signals; signal callback receives animation reference; disconnecting listener stops reaction. |

### Camera + Other Modules

| Pair | What to Test |
|---|---|
| **camera + viewport** | Camera position affects world coordinate transforms but not viewport scale; viewport dimensions are independent of camera; screenToGame conversion is consistent; camera zoom doesn't affect viewport scale; viewport resize doesn't affect camera state. |
| **scene + camera** | Scene push/pop triggers camera reset or restore; camera follows scene-specific targets; scene transitions blend between camera states. |
| **tilemap + camera** | Camera visible area determines which tilemap chunks to render; scrolling the camera updates visible tile range. |
| **minimap + camera** | Minimap view bounds correspond to camera visible area; camera panning updates minimap indicator position. |
| **light + camera** | Light world position tested against camera visible area for culling; lights outside camera view are correctly excluded; zoom affects light screen-space size; panning changes where lights appear on screen. |
| **viewport + camera** | Viewport and camera compose correctly for resolution-independent rendering with proper coordinate transforms. |

### Compute + Other Modules

| Pair | What to Test |
|---|---|
| **compute + dataframe** | DataFrame column extracted into compute array; array reductions (mean, min, max) match DataFrame aggregates; computed threshold filters DataFrame rows; element-wise operations compute composite scores. |
| **compute + stats** | Stat sheet values populate compute arrays; element-wise subtraction computes net damage; global multiplier buff applied via array scaling; array sum gives total damage. |

### Dataframe + Other Modules

| Pair | What to Test |
|---|---|
| **dataframe + inventory** | Filter DataFrame for weapon-type rows → create Items from results; sort by damage → top row becomes loot drop; nrows matches item count added to container. |
| **dataframe + savegame** | Sort high scores descending for leaderboard display; filter by level threshold; DataFrame serializes to JSON/CSV and reconstructs correctly. |
| **dataframe + stats** | DataFrame row values become initial stat sheet values; filter finds enemies by template HP; create sheets for all rows then sum HP via DataFrame aggregate. |

### Devtools + Other Modules

| Pair | What to Test |
|---|---|
| **devtools + scheduler** | Profile push/pop surrounds scheduler callback execution; log level filtering applies to scheduler-triggered logs; cancelling scheduler prevents further log entries; clearLog wipes scheduler side-effect history. |
| **devtools + signal** | Signal listener logs events through devtools; warn-level logs from signal subscribers produce correct entries; ordered signal emissions appear as ordered log entries; disconnect prevents new log entries. |
| **terminal + devtools** | Terminal commands can invoke devtools logging functions; terminal output includes devtools log entries. |
| **terminal + stats** | Terminal commands read/modify stat sheet values; stat changes through terminal are reflected in game state. |

### Dialog + Other Modules

| Pair | What to Test |
|---|---|
| **dialog + localization** | Dialog node text pulled from localization keys; language switch changes dialog text; template parameters interpolated in localized dialog strings; missing key falls back to default language. |
| **dialog + stats** | Character stat value determines available dialog choices (e.g. charisma check); stat buff mid-conversation changes available options; completing dialog branch grants stat bonuses. |
| **quest + dialog** | Quest completion unlocks dialog branches; dialog choices set quest flags; quest counter values displayed in dialog text. |

### Doll + Other Modules

| Pair | What to Test |
|---|---|
| **doll + animation** | Fire-frame callback shows/hides muzzle flash part; hurt frame changes part color; draw list sorted by socket draw order; detachAll empties draw list; looping animation toggles parts repeatedly. |
| **doll + entity** | Entity stores Doll as component; health component drives part color change; killing entity triggers detachAll; entity position propagated to doll; query finds all entities with visual component. |
| **doll + inventory** | Equipping helmet item attaches corresponding Part to head socket; unequip reverses attachment; equipping four items fills all sockets; Part attributes carry item metadata; getEmptySockets reflects un-equipped slots. |

### Entity + Other Modules

| Pair | What to Test |
|---|---|
| **entity + components** | Spawn and attach position component; each() iterates matching entities; query returns only entities with all requested components; remove component stops iteration match; kill removes from queries; tags and components coexist independently. |
| **entity + scheduler** | Scheduler periodically spawns entities; scheduled cleanup kills entities after delay. |
| **tween + entity** | Tween animates entity component position; tween onComplete callback kills entity. |
| **spatial + entity** | Entities inserted into spatial hash found by queryRect; entity alive status verified for spatial query results. |
| **graph + entity** | Graph node IDs map to ECS entities; edge weights stored as components; query returns entities with graph_node component; removing node triggers entity kill. |
| **geometry + entity** | rectsOverlap checks entity bounding box collisions; pointInCircle for AoE blast radius; closestPointOnSegment for entity wall sliding; distancePoints for weapon range checks. |
| **raycaster + entity** | Ray cast against entity bounds for line-of-sight checks; grid ray stops at entity-occupied cells. |
| **minimap + entity** | Entity positions fed into minimap as objects; killing entity and removing from minimap keeps count correct; updating entity position refreshes minimap; minimap shows only entities with visible tag. |

### Grid + Other Modules

| Pair | What to Test |
|---|---|
| **grid + spatial** | Entities at walkable grid cells found by spatial query; path cells verified for spatial occupancy; tower at grid cell uses spatial queryRect for targeting; floodFill connected region populated in spatial hash. |
| **graph + grid** | Walkable grid cells added as graph nodes; grid neighbor relationships become graph edges; wall blocks both grid pathfinding and graph traversal; grid costs become edge weights; floodFill and graph connected components identify same regions. |
| **noise + grid** | Noise values drive grid walkability flags; same seed produces identical walkability maps; different seeds produce different grids; pathfinding succeeds on partially-walkable noise terrain; noise fbm values drive per-cell movement costs. |
| **vec2 + grid** | Vec2 positions converted to grid cell coordinates for pathfinding; grid path waypoints converted back to vec2 world positions. |
| **raycaster + grid** | Grid ray walk (DDA) stops at non-walkable cells; ray distance through grid matches expected cell traversal count. |

### Inventory + Other Modules

| Pair | What to Test |
|---|---|
| **inventory + stats** | Equipping items with stat bonuses modifies stat sheet; unequipping removes the bonus; set bonus activation triggers stat buff. |
| **gui + inventory** | Inventory container contents displayed in GUI widgets; drag-drop between GUI slots triggers inventory move operations. |
| **resource + inventory** | Spending resource to purchase item adds it to container; insufficient resource prevents purchase. |
| **savegame + inventory** | Inventory state serialized via savegame provider; loading restores items, stacks, and equipment slots. |
| **patterns + inventory** | CommandStack undo/redo for equip/unequip operations; undoing equip restores previous equipment state. |

### Light + Other Modules

| Pair | What to Test |
|---|---|
| **light + spatial** | Point lights inserted into spatial hash found by region query; light outside query region not returned; multiple lights queried returns only nearby ones; clearing spatial hash removes all light references. |

### Localization + Other Modules

| Pair | What to Test |
|---|---|
| **localization + quest** | Quest flag name used as localization key; language switch changes quest description text; quest counter interpolated in localized template; missing key returns fallback; multiple active quests each resolve to localized names. |

### Modding + Other Modules

| Pair | What to Test |
|---|---|
| **modding + quest** | Mod onEnter hook reads quest state; mod onAchievement hook writes quest flag; mod config sets quest counter threshold; disabled mod doesn't modify quest flags; quest observer fires when mod hook changes a flag. |
| **modding + signal** | Mod onLoad hook fires when signal is emitted; disabled mod hook skipped; multiple mods respond independently to same signal; mod hook receives signal payload; releasing mod clears hook. |
| **modding + stats** | Mod hooks can read/write stat sheet values; mod config values influence stat calculations. |

### Network + Other Modules

| Pair | What to Test |
|---|---|
| **network + signal** | UDP client connection state changes emit signals; signal payload contains message data; multiple subscribers all receive network broadcast; two client instances hold independent state. |

### Noise + Other Modules

| Pair | What to Test |
|---|---|
| **noise + tilemap** | Noise2d values bucketed into discrete tile types for terrain generation; noise grid positions convert to isometric screen coordinates; hex neighbors sampled for noise coherence; fbm produces more varied terrain than single-octave noise. |
| **noise + vec2** | Noise value at position rotates a vec2 for flow-field effects; different positions produce varied flow directions; noise scales vec2 velocity for speed variation; neighboring positions get similar noise values (spatial coherence); position offset by noise-derived displacement. |

### Overlay + Other Modules

| Pair | What to Test |
|---|---|
| **overlay + scene** | Scene transition triggers overlay fade effect; overlay state resets on scene switch. |
| **overlay + scheduler** | Scheduler drives time-of-day overlay tint changes on fixed intervals. |
| **overlay + signal** | Signal emission triggers overlay flash effect; overlay completion emits signal back. |

### Quest + Other Modules

| Pair | What to Test |
|---|---|
| **quest + signal** | Quest flag change emits signal; signal listener tracks quest progress; multiple quest signals compose correctly. |
| **quest + stats** | Quest completion grants stat bonuses; stat thresholds unlock quest branches. |
| **graph + quest** | Completing quest enables access to new graph paths; prerequisite edges block until quest flags are set; cyclic quest dependency detected correctly. |
| **patterns + quest** | EventBus publishes quest updates; command pattern tracks quest state changes for undo. |

### Resource + Other Modules

| Pair | What to Test |
|---|---|
| **resource + scheduler** | Scheduler fires regen ticks that add to resource; regen stops when resource is at cap. |
| **resource + signal** | Resource depletion emits signal; resource reaching cap emits signal. |
| **stats + resource** | Stat values influence resource regen rates or caps. |

### Savegame + Other Modules

| Pair | What to Test |
|---|---|
| **savegame + stats** | Stat sheet values persisted via savegame provider; loading restores base values and active buffs. |
| **filesystem + savegame** | Savegame data encoded to JSON, written to filesystem, read back, and decoded with values preserved; dirty flag integrates with filesystem existence check; multiple providers produce independent save file sections. |

### Scene + Other Modules

| Pair | What to Test |
|---|---|
| **scene + signal** | Scene push/pop lifecycle events trigger signals (enter, exit, pause, resume); signal listeners track scene navigation history. |
| **gui + scene** | GUI widget trees scoped per scene; scene switch activates/deactivates GUI layers. |
| **scene + scheduler** | Scene update drives embedded scheduler within the active scene; scheduler tasks scoped to scene lifetime. |

### Scheduler + Other Modules

| Pair | What to Test |
|---|---|
| **scheduler + tween** | Scheduler drives tween updates periodically; tween completes after sufficient scheduler ticks. |
| **scheduler + signal** | Scheduled callback emits signal after delay; signal listener confirms timing. |

### Signal + Other Modules

| Pair | What to Test |
|---|---|
| **signal + patterns** | Signal emission routed through EventBus for decoupled cross-system communication. |
| **spatial + signal** | Spatial query results trigger signals for entity detection events. |
| **tween + signal** | Tween completion emits signal; multiple tweens finishing at different times emit signals in order. |

### Tilemap + Other Modules

| Pair | What to Test |
|---|---|
| **tileset + tilemap** | Tileset tile definitions map correctly to tilemap cell rendering; tile properties propagate through tilemap queries. |

### World Pipeline (Multi-Module)

| Pair | What to Test |
|---|---|
| **grid + spatial + light + camera** | Full world pipeline: grid provides terrain, spatial manages entity positions, lights culled by camera view, all systems compose for a complete game world update cycle. |

---

## Test File Mapping Reference

### Unit Tests (`tests/ilove/`)

| File | Module |
|---|---|
| `test_init.lua` | ilove (init / loader) |
| `test_class.lua` | luna2d.class |
| `test_animation.lua` | luna2d.animation |
| `test_camera.lua` | luna2d.camera |
| `test_vec2.lua` | luna2d.vec2 |
| `test_geometry.lua` | luna2d.geometry |
| `test_grid.lua` | luna2d.grid |
| `test_noise.lua` | luna2d.noise |
| `test_spatial.lua` | luna2d.spatial |
| `test_signal.lua` | luna2d.signal |
| `test_scheduler.lua` | luna2d.scheduler |
| `test_light.lua` | luna2d.light |
| `test_raycaster.lua` | luna2d.raycaster |
| `test_viewport.lua` | luna2d.viewport |
| `test_native.lua` | ilove_native (C++ DLL) |
| `test_ai.lua` | luna2d.ai |
| `test_entity.lua` | luna2d.entity |
| `test_tween.lua` | luna2d.tween |
| `test_scene.lua` | luna2d.scene |
| `test_dialog.lua` | luna2d.dialog |
| `test_quest.lua` | luna2d.quest |
| `test_stats.lua` | luna2d.stats |
| `test_resource.lua` | luna2d.resource |
| `test_inventory.lua` | luna2d.inventory |
| `test_savegame.lua` | luna2d.savegame |
| `test_graph.lua` | luna2d.graph |
| `test_doll.lua` | luna2d.doll |
| `test_minimap.lua` | luna2d.minimap |
| `test_overlay.lua` | luna2d.overlay |
| `test_patterns.lua` | luna2d.patterns |
| `test_modding.lua` | luna2d.modding |
| `test_localization.lua` | luna2d.localization |
| `test_network.lua` | luna2d.network |
| `test_devtools.lua` | luna2d.devtools |
| `test_terminal.lua` | luna2d.terminal |
| `test_dataframe.lua` | luna2d.dataframe |
| `test_compute.lua` | luna2d.compute |
| `test_simulator.lua` | luna2d.simulator |
| `test_debugbridge.lua` | luna2d.debugbridge |
| `test_gui.lua` | luna2d.gui |
| `test_postfx.lua` | luna2d.postfx |
| `test_integration.lua` | Cross-module quick integration |

### Integration Tests (`tests/integration/`)

| File | Module Pair |
|---|---|
| `test_ai_graph.lua` | ai + graph |
| `test_ai_pathfinding.lua` | ai + grid + entity |
| `test_ai_spatial.lua` | ai + spatial |
| `test_ai_stats.lua` | ai + stats |
| `test_animation_entity.lua` | animation + entity |
| `test_animation_scheduler.lua` | animation + scheduler |
| `test_animation_signal.lua` | animation + signal |
| `test_camera_viewport.lua` | camera + viewport |
| `test_compute_dataframe.lua` | compute + dataframe |
| `test_compute_stats.lua` | compute + stats |
| `test_dataframe_inventory.lua` | dataframe + inventory |
| `test_dataframe_savegame.lua` | dataframe + savegame |
| `test_dataframe_stats.lua` | dataframe + stats |
| `test_devtools_scheduler.lua` | devtools + scheduler |
| `test_devtools_signal.lua` | devtools + signal |
| `test_dialog_localization.lua` | dialog + localization |
| `test_dialog_stats.lua` | dialog + stats |
| `test_doll_animation.lua` | doll + animation |
| `test_doll_entity.lua` | doll + entity |
| `test_doll_inventory.lua` | doll + inventory |
| `test_entity_components.lua` | entity components |
| `test_filesystem_savegame.lua` | filesystem + savegame |
| `test_geometry_entity.lua` | geometry + entity |
| `test_geometry_spatial.lua` | geometry + spatial |
| `test_geometry_vec2.lua` | geometry + vec2 |
| `test_graph_entity.lua` | graph + entity |
| `test_graph_grid.lua` | graph + grid |
| `test_graph_quest.lua` | graph + quest |
| `test_grid_spatial.lua` | grid + spatial |
| `test_gui_inventory.lua` | gui + inventory |
| `test_gui_scene.lua` | gui + scene |
| `test_inventory_stats.lua` | inventory + stats |
| `test_light_camera.lua` | light + camera |
| `test_light_spatial.lua` | light + spatial |
| `test_localization_quest.lua` | localization + quest |
| `test_minimap_camera.lua` | minimap + camera |
| `test_minimap_entity.lua` | minimap + entity |
| `test_minimap_spatial.lua` | minimap + spatial |
| `test_modding_quest.lua` | modding + quest |
| `test_modding_signal.lua` | modding + signal |
| `test_modding_stats.lua` | modding + stats |
| `test_network_signal.lua` | network + signal |
| `test_noise_grid.lua` | noise + grid |
| `test_noise_tilemap.lua` | noise + tilemap |
| `test_noise_vec2.lua` | noise + vec2 |
| `test_overlay_scene.lua` | overlay + scene |
| `test_overlay_scheduler.lua` | overlay + scheduler |
| `test_overlay_signal.lua` | overlay + signal |
| `test_patterns_inventory.lua` | patterns + inventory |
| `test_patterns_quest.lua` | patterns + quest |
| `test_quest_dialog.lua` | quest + dialog |
| `test_quest_signal.lua` | quest + signal |
| `test_quest_stats.lua` | quest + stats |
| `test_raycaster_entity.lua` | raycaster + entity |
| `test_raycaster_grid.lua` | raycaster + grid |
| `test_resource_inventory.lua` | resource + inventory |
| `test_resource_scheduler.lua` | resource + scheduler |
| `test_resource_signal.lua` | resource + signal |
| `test_savegame_inventory.lua` | savegame + inventory |
| `test_savegame_stats.lua` | savegame + stats |
| `test_scene_camera.lua` | scene + camera |
| `test_scheduler_tween.lua` | scheduler + tween |
| `test_signal_patterns.lua` | signal + patterns |
| `test_spatial_entity.lua` | spatial + entity |
| `test_spatial_signal.lua` | spatial + signal |
| `test_stats_resource.lua` | stats + resource |
| `test_terminal_devtools.lua` | terminal + devtools |
| `test_terminal_stats.lua` | terminal + stats |
| `test_tilemap_camera.lua` | tilemap + camera |
| `test_tileset_tilemap.lua` | tileset + tilemap |
| `test_tween_entity.lua` | tween + entity |
| `test_tween_signal.lua` | tween + signal |
| `test_vec2_grid.lua` | vec2 + grid |
| `test_viewport_camera.lua` | viewport + camera |
| `test_world_pipeline.lua` | grid + spatial + light + camera |
