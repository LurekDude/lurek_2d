#!/usr/bin/env python3
"""
improve_lua_docstrings.py — Rewrites existing thin/incorrect /// docstrings in
src/lua_api/*.rs with richer, class-aware, semantically accurate content.

Targets three common quality problems:
 1. Generic summaries like "Sets the max speed." or "Returns `true` if tag."
 2. Wrong parameter lists (e.g., getters that show a param for an empty closure)
 3. Missing context — no explanation of what the parameter or return value means

Strategy:
 - For each (ClassName, methodName) pair, replace the entire /// block with a
   handcrafted or rule-generated description.
 - Falls back to improved rule-based generation for pairs without a specific template.

Usage:
    python tools/improve_lua_docstrings.py [--dry-run]
"""

import re
import pathlib
import sys
import argparse

WORKSPACE = pathlib.Path(__file__).resolve().parent.parent.parent.parent
LUA_API_DIR = WORKSPACE / "src" / "lua_api"

# ─── Per-(class, method) override table ───────────────────────────────────────
# Maps (ClassName, methodName) → (summary, param_descriptions, returns)
# param_descriptions = list of (name, type, description) or None to auto-detect
# returns = string or None

OVERRIDES: dict[tuple[str, str], tuple[str, list, str | None]] = {

    # ── AIWorld ──
    ("AIWorld", "addAgent"): (
        "Registers a new agent named `name` in this world and returns its handle.",
        [("name", "string", "Unique identifier for the new agent.")],
        "An `Agent` handle ready for further configuration.",
    ),
    ("AIWorld", "getAgent"): (
        "Looks up a registered agent by name.",
        [("name", "string", "Name of the agent to retrieve.")],
        "The `Agent` handle, or `nil` if no agent with that name exists.",
    ),
    ("AIWorld", "removeAgent"): (
        "Removes and destroys the given agent from this world.",
        [("agent", "Agent", "Handle of the agent to remove, obtained from `addAgent`.")],
        None,
    ),
    ("AIWorld", "getAgentCount"): (
        "Returns the number of agents currently registered in this world.",
        [],
        "`integer` — total agent count.",
    ),
    ("AIWorld", "getGlobalBlackboard"): (
        "Returns a snapshot of the shared world-level blackboard.",
        [],
        "A `Blackboard` containing data visible to all agents in this world.",
    ),
    ("AIWorld", "update"): (
        "Advances all agents in the world by `dt` seconds, integrating velocity into position.",
        [("dt", "number", "Elapsed seconds since the last frame.")],
        None,
    ),

    # ── Agent ──
    ("Agent", "getName"): (
        "Returns the unique name this agent was registered under.",
        [],
        "`string` — agent name.",
    ),
    ("Agent", "setPosition"): (
        "Teleports the agent to world-space coordinates (`x`, `y`).",
        [("x", "number", "Horizontal world-space position."),
         ("y", "number", "Vertical world-space position.")],
        None,
    ),
    ("Agent", "getPosition"): (
        "Returns the agent's current world-space position.",
        [],
        "Two numbers `x, y` representing world-space coordinates.",
    ),
    ("Agent", "setVelocity"): (
        "Sets the agent's velocity vector in world units per second.",
        [("x", "number", "Horizontal component."),
         ("y", "number", "Vertical component.")],
        None,
    ),
    ("Agent", "getVelocity"): (
        "Returns the agent's current velocity vector.",
        [],
        "Two numbers `vx, vy` in world units/second.",
    ),
    ("Agent", "setMaxSpeed"): (
        "Sets the maximum movement speed cap in world units/second.",
        [("v", "number", "New speed limit (world units/sec).")],
        None,
    ),
    ("Agent", "getMaxSpeed"): (
        "Returns the maximum movement speed cap in world units/second.",
        [],
        "`number` — speed cap.",
    ),
    ("Agent", "setMaxForce"): (
        "Sets the maximum steering force that can be applied per frame.",
        [("v", "number", "New force cap.")],
        None,
    ),
    ("Agent", "getMaxForce"): (
        "Returns the maximum steering force cap.",
        [],
        "`number` — force cap.",
    ),
    ("Agent", "setPriority"): (
        "Sets the scheduling priority; higher-priority agents are processed first during `update`.",
        [("p", "integer", "Priority value, higher = earlier processing.")],
        None,
    ),
    ("Agent", "getPriority"): (
        "Returns the agent's scheduling priority level.",
        [],
        "`integer` — priority.",
    ),
    ("Agent", "setDecisionModel"): (
        "Switches the agent's active decision model at runtime. Valid values: `\"fsm\"`, `\"bt\"`, `\"utility\"`, `\"goap\"`.",
        [("model", "string", "Decision model identifier.")],
        None,
    ),
    ("Agent", "getDecisionModel"): (
        "Returns the name of the agent's current decision model.",
        [],
        "`string` — e.g. `\"fsm\"`, `\"bt\"`, `\"utility\"`, `\"goap\"`.",
    ),
    ("Agent", "addTag"): (
        "Adds a string tag to this agent's tag set (idempotent).",
        [("tag", "string", "Tag to add.")],
        None,
    ),
    ("Agent", "removeTag"): (
        "Removes a string tag from this agent's tag set (no-op if absent).",
        [("tag", "string", "Tag to remove.")],
        None,
    ),
    ("Agent", "hasTag"): (
        "Returns `true` if this agent's tag set contains `tag`.",
        [("tag", "string", "Tag to test.")],
        "`boolean`.",
    ),
    ("Agent", "getBlackboard"): (
        "Returns this agent's private blackboard for reading or writing typed data.",
        [],
        "A `Blackboard` scoped to this agent.",
    ),

    # ── Blackboard ──
    ("Blackboard", "setNumber"): (
        "Stores a floating-point value under `key` on this blackboard.",
        [("key", "string", "Key to write."),
         ("value", "number", "Value to store.")],
        None,
    ),
    ("Blackboard", "getNumber"): (
        "Reads a stored number from the blackboard.",
        [("key", "string", "Key to read.")],
        "`number` — the stored value, or `0` if the key is not found.",
    ),
    ("Blackboard", "setString"): (
        "Stores a string value under `key` on this blackboard.",
        [("key", "string", "Key to write."),
         ("value", "string", "Value to store.")],
        None,
    ),
    ("Blackboard", "getString"): (
        "Reads a stored string from the blackboard.",
        [("key", "string", "Key to read.")],
        "`string` — the stored value, or `\"\"` if the key is not found.",
    ),
    ("Blackboard", "setBool"): (
        "Stores a boolean value under `key` on this blackboard.",
        [("key", "string", "Key to write."),
         ("value", "boolean", "Value to store.")],
        None,
    ),
    ("Blackboard", "getBool"): (
        "Reads a stored boolean from the blackboard.",
        [("key", "string", "Key to read.")],
        "`boolean` — the stored value, or `false` if not found.",
    ),
    ("Blackboard", "has"): (
        "Returns `true` if a value is stored under `key` in this blackboard.",
        [("key", "string", "Key to check.")],
        "`boolean`.",
    ),
    ("Blackboard", "remove"): (
        "Deletes the entry at `key` from this blackboard (no-op if absent).",
        [("key", "string", "Key to delete.")],
        None,
    ),
    ("Blackboard", "clear"): (
        "Removes all entries from this blackboard.",
        [],
        None,
    ),

    # ── StateMachine ──
    ("StateMachine", "addState"): (
        "Registers a new named state in this FSM.",
        [("name", "string", "Unique name for the state.")],
        None,
    ),
    ("StateMachine", "setTransition"): (
        "Adds a directed transition edge from `from` to `to` labelled `event`.",
        [("from", "string", "Source state name."),
         ("to", "string", "Destination state name."),
         ("event", "string", "Event string that triggers this transition.")],
        None,
    ),
    ("StateMachine", "transition"): (
        "Fires `event` on the running FSM, triggering any matching transition out of the current state.",
        [("event", "string", "Event to fire.")],
        None,
    ),
    ("StateMachine", "getState"): (
        "Returns the name of the currently active FSM state.",
        [],
        "`string` — current state name.",
    ),
    ("StateMachine", "setState"): (
        "Jumps directly to `state`, bypassing transition conditions.",
        [("state", "string", "Name of the target state.")],
        None,
    ),
    ("StateMachine", "update"): (
        "Runs on-state-update callbacks for the active state, passing `dt` as elapsed time.",
        [("dt", "number", "Elapsed seconds since the last frame.")],
        None,
    ),

    # ── BehaviorTree ──
    ("BehaviorTree", "setRoot"): (
        "Sets the top-level root node of this behavior tree.",
        [("node", "BTNode", "Root `BTNode` returned by one of the node constructors.")],
        None,
    ),
    ("BehaviorTree", "tick"): (
        "Evaluates the behavior tree for one frame. Returns the result status of the root node.",
        [("dt", "number", "Elapsed seconds since the last frame.")],
        "`string` — `\"success\"`, `\"failure\"`, or `\"running\"`.",
    ),

    # ── SteeringManager ──
    ("SteeringManager", "seek"): (
        "Applies a seek force towards the world-space target (`tx`, `ty`).",
        [("tx", "number", "Target X in world space."),
         ("ty", "number", "Target Y in world space.")],
        None,
    ),
    ("SteeringManager", "flee"): (
        "Applies a flee force away from the world-space target (`tx`, `ty`).",
        [("tx", "number", "Target X in world space."),
         ("ty", "number", "Target Y in world space.")],
        None,
    ),
    ("SteeringManager", "arrive"): (
        "Applies an arrive force that decelerates as the agent nears the target.",
        [("tx", "number", "Target X in world space."),
         ("ty", "number", "Target Y in world space."),
         ("slow_radius", "number", "Distance at which the agent begins to decelerate.")],
        None,
    ),
    ("SteeringManager", "wander"): (
        "Applies a randomized wander force for naturalistic wandering motion.",
        [],
        None,
    ),
    ("SteeringManager", "update"): (
        "Integrates all accumulated steering forces and updates the owning agent's velocity.",
        [("dt", "number", "Elapsed seconds since the last frame.")],
        None,
    ),

    # ── QLearner ──
    ("QLearner", "learn"): (
        "Updates the Q-table for the given `(state, action)` pair using the observed `reward` and `next_state`.",
        [("state", "string", "The state that was active when the action was taken."),
         ("action", "string", "The action that was executed."),
         ("reward", "number", "Reward signal received after taking the action."),
         ("next_state", "string", "The resulting state after the action.")],
        None,
    ),
    ("QLearner", "bestAction"): (
        "Returns the action with the highest Q-value for `state`.",
        [("state", "string", "State to query.")],
        "`string` — best-known action name.",
    ),
    ("QLearner", "getQ"): (
        "Returns the current Q-value for the given `(state, action)` pair.",
        [("state", "string", "State key."),
         ("action", "string", "Action key.")],
        "`number` — Q-value (0 if unseen).",
    ),

    # ── GOAPPlanner ──
    ("GOAPPlanner", "addAction"): (
        "Registers an action with its `cost`, `preconditions`, and `effects` for use during planning.",
        [("name", "string", "Unique action identifier."),
         ("cost", "number", "Planning cost for this action."),
         ("preconditions", "table", "Key-value table of bool precondition flags."),
         ("effects", "table", "Key-value table of bool world-state changes.")],
        None,
    ),
    ("GOAPPlanner", "plan"): (
        "Runs A* GOAP search from `current_state` to `goal_state` and returns the action sequence.",
        [("current_state", "table", "Key-value bool table of current world state."),
         ("goal_state", "table", "Key-value bool table of desired goal state.")],
        "Ordered `table` of action-name strings, or `nil` if no plan exists.",
    ),

    # ── InfluenceMap ──
    ("InfluenceMap", "addLayer"): (
        "Adds a named influence layer to this map.",
        [("name", "string", "Layer identifier.")],
        None,
    ),
    ("InfluenceMap", "hasLayer"): (
        "Returns `true` if a layer with `name` exists in this map.",
        [("name", "string", "Layer identifier to test.")],
        "`boolean`.",
    ),
    ("InfluenceMap", "setInfluence"): (
        "Writes an influence scalar at grid cell (`col`, `row`) on the named layer.",
        [("layer", "string", "Target layer name."),
         ("col", "integer", "Grid column (x-axis)."),
         ("row", "integer", "Grid row (y-axis)."),
         ("value", "number", "Influence value to write.")],
        None,
    ),
    ("InfluenceMap", "getInfluence"): (
        "Reads the influence value at grid cell (`col`, `row`) on the named layer.",
        [("layer", "string", "Target layer name."),
         ("col", "integer", "Grid column."),
         ("row", "integer", "Grid row.")],
        "`number` — stored influence, or `0` if out of bounds.",
    ),
    ("InfluenceMap", "propagate"): (
        "Spreads influence values across the layer using the configured decay factor.",
        [("layer", "string", "Layer to propagate."),
         ("decay", "number", "Multiplicative decay applied per propagation step (0–1).")],
        None,
    ),

    # ── Squad ──
    ("Squad", "addMember"): (
        "Adds an agent identified by `name` to this squad.",
        [("name", "string", "Name of the agent to enlist.")],
        None,
    ),
    ("Squad", "removeMember"): (
        "Removes the agent identified by `name` from this squad.",
        [("name", "string", "Name of the agent to remove.")],
        None,
    ),
    ("Squad", "getMemberCount"): (
        "Returns the number of agents currently in this squad.",
        [],
        "`integer` — member count.",
    ),
    ("Squad", "setFormation"): (
        "Assigns the formation pattern used to compute per-member offsets.",
        [("formation", "string", "Formation name — `\"line\"`, `\"column\"`, `\"wedge\"`, `\"circle\"`, or `\"box\"`.")],
        None,
    ),
    ("Squad", "update"): (
        "Recomputes formation offsets and issues move-to commands to each member agent.",
        [("dt", "number", "Elapsed seconds since the last frame.")],
        None,
    ),

    # ── CommandQueue ──
    ("CommandQueue", "push"): (
        "Enqueues a new command at the back of the queue.",
        [("cmd", "string", "Command identifier to add.")],
        None,
    ),
    ("CommandQueue", "pop"): (
        "Dequeues and returns the front command, or `nil` if empty.",
        [],
        "`string` — command identifier, or `nil` if the queue is empty.",
    ),
    ("CommandQueue", "peek"): (
        "Returns the front command without removing it.",
        [],
        "`string` — command identifier, or `nil` if the queue is empty.",
    ),
    ("CommandQueue", "isEmpty"): (
        "Returns `true` if there are no commands queued.",
        [],
        "`boolean`.",
    ),
    ("CommandQueue", "clear"): (
        "Discards all queued commands.",
        [],
        None,
    ),
    ("CommandQueue", "size"): (
        "Returns the number of commands currently in the queue.",
        [],
        "`integer` — queue length.",
    ),

    # ── PhysicsWorld ──
    ("World", "createBody"): (
        "Creates a new physics body at position (`x`, `y`). `type` must be `\"dynamic\"`, `\"static\"`, or `\"kinematic\"`.",
        [("x", "number", "Initial horizontal position in world units."),
         ("y", "number", "Initial vertical position in world units."),
         ("body_type", "string", "Physics body type: `\"dynamic\"`, `\"static\"`, or `\"kinematic\"`.")],
        "A `Body` handle.",
    ),
    ("World", "step"): (
        "Advances the physics simulation by `dt` seconds, resolving collisions and integrating forces.",
        [("dt", "number", "Elapsed simulation time in seconds.")],
        None,
    ),
    ("World", "setGravity"): (
        "Sets world gravity. Default is `(0, 9.81)` (downward).",
        [("x", "number", "Horizontal gravity component."),
         ("y", "number", "Vertical gravity component.")],
        None,
    ),
    ("World", "getGravity"): (
        "Returns the current world gravity vector.",
        [],
        "Two numbers `gx, gy`.",
    ),
    ("World", "raycast"): (
        "Casts a ray from (`x1`, `y1`) to (`x2`, `y2`) and returns the first body hit.",
        [("x1", "number", "Ray origin X."),
         ("y1", "number", "Ray origin Y."),
         ("x2", "number", "Ray end X."),
         ("y2", "number", "Ray end Y.")],
        "A `table` with fields `body`, `x`, `y`, `normalX`, `normalY`, or `nil` if no hit.",
    ),
    ("World", "queryAABB"): (
        "Returns all bodies whose AABB overlaps the rectangle defined by (`x1`, `y1`)–(`x2`, `y2`).",
        [("x1", "number", "Left boundary."),
         ("y1", "number", "Top boundary."),
         ("x2", "number", "Right boundary."),
         ("y2", "number", "Bottom boundary.")],
        "`table` of `Body` handles.",
    ),

    # ── PhysicsBody ──
    ("Body", "setLinearVelocity"): (
        "Sets the body's linear velocity in world units/second.",
        [("vx", "number", "Horizontal velocity component."),
         ("vy", "number", "Vertical velocity component.")],
        None,
    ),
    ("Body", "getLinearVelocity"): (
        "Returns the body's current linear velocity.",
        [],
        "Two numbers `vx, vy` in world units/second.",
    ),
    ("Body", "applyForce"): (
        "Applies a continuous force (accumulates until the next physics step) to the body's centre of mass.",
        [("fx", "number", "Horizontal force component."),
         ("fy", "number", "Vertical force component.")],
        None,
    ),
    ("Body", "applyImpulse"): (
        "Applies an instantaneous impulse directly to the body's centre of mass.",
        [("ix", "number", "Horizontal impulse."),
         ("iy", "number", "Vertical impulse.")],
        None,
    ),
    ("Body", "getPosition"): (
        "Returns the body's current world-space position.",
        [],
        "Two numbers `x, y` in world units.",
    ),
    ("Body", "setPosition"): (
        "Teleports the body to the given world-space position (bypasses collision detection).",
        [("x", "number", "Target X position."),
         ("y", "number", "Target Y position.")],
        None,
    ),
    ("Body", "getAngle"): (
        "Returns the body's current rotation angle in radians.",
        [],
        "`number` — angle in radians.",
    ),
    ("Body", "setAngle"): (
        "Sets the body's rotation to `angle` radians (bypasses physics).",
        [("angle", "number", "Target angle in radians.")],
        None,
    ),
    ("Body", "isActive"): (
        "Returns `true` if this body is active and participating in the simulation.",
        [],
        "`boolean`.",
    ),
    ("Body", "setActive"): (
        "Activates or deactivates this body. Inactive bodies are skipped during simulation.",
        [("active", "boolean", "`true` to activate, `false` to deactivate.")],
        None,
    ),

    # ── Image ──
    ("Image", "getWidth"): (
        "Returns the image width in pixels.",
        [],
        "`integer` — pixel width.",
    ),
    ("Image", "getHeight"): (
        "Returns the image height in pixels.",
        [],
        "`integer` — pixel height.",
    ),
    ("Image", "getDimensions"): (
        "Returns image width and height in pixels.",
        [],
        "Two integers `width, height`.",
    ),
    ("Image", "setFilter"): (
        "Sets the minification/magnification filter. Use `\"nearest\"` for pixel art, `\"linear\"` for smooth scaling.",
        [("min", "string", "Minification filter: `\"nearest\"` or `\"linear\"`."),
         ("mag", "string", "Magnification filter: `\"nearest\"` or `\"linear\"`.")],
        None,
    ),
    ("Image", "getFilter"): (
        "Returns the current min and mag texture filters.",
        [],
        "Two strings `min, mag`.",
    ),
    ("Image", "setWrap"): (
        "Sets the texture wrap mode for UV coordinates outside [0, 1].",
        [("h", "string", "Horizontal wrap: `\"clamp\"`, `\"repeat\"`, or `\"mirror\"`."),
         ("v", "string", "Vertical wrap: `\"clamp\"`, `\"repeat\"`, or `\"mirror\"`.")],
        None,
    ),

    # ── Font ──
    ("Font", "getHeight"): (
        "Returns the line height of this font at its loaded size, in pixels.",
        [],
        "`integer` — line height in pixels.",
    ),
    ("Font", "getAscent"): (
        "Returns the ascent (distance from baseline to the top of the tallest glyph) in pixels.",
        [],
        "`number` — ascent in pixels.",
    ),
    ("Font", "getDescent"): (
        "Returns the descent (distance below the baseline for descenders) in pixels.",
        [],
        "`number` — descent in pixels.",
    ),
    ("Font", "getWidth"): (
        "Measures the rendered width of `text` using this font's current size.",
        [("text", "string", "The string to measure.")],
        "`number` — rendered width in pixels.",
    ),

    # ── Canvas ──
    ("Canvas", "getWidth"): ("Returns the canvas width in pixels.", [], "`integer` — pixel width."),
    ("Canvas", "getHeight"): ("Returns the canvas height in pixels.", [], "`integer` — pixel height."),
    ("Canvas", "getDimensions"): ("Returns the canvas width and height in pixels.", [], "Two integers `width, height`."),
    ("Canvas", "clear"): (
        "Clears the canvas to a solid colour. Defaults to transparent black if `r,g,b,a` are omitted.",
        [("r", "number", "Red channel (0–1), optional."),
         ("g", "number", "Green channel (0–1), optional."),
         ("b", "number", "Blue channel (0–1), optional."),
         ("a", "number", "Alpha channel (0–1), optional.")],
        None,
    ),

    # ── AudioSource ──
    ("Source", "play"): ("Starts or resumes playback from the current seek position.", [], None),
    ("Source", "stop"): ("Stops playback and resets the seek position to the beginning.", [], None),
    ("Source", "pause"): ("Pauses playback. Call `play()` to resume.", [], None),
    ("Source", "isPlaying"): ("Returns `true` if this source is currently playing.", [], "`boolean`."),
    ("Source", "isStopped"): ("Returns `true` if playback has stopped (either manually or after the audio ended).", [], "`boolean`."),
    ("Source", "isPaused"): ("Returns `true` if playback is currently paused.", [], "`boolean`."),
    ("Source", "setVolume"): (
        "Sets playback volume. `1.0` is full volume; `0.0` is silent.",
        [("volume", "number", "Volume multiplier (0–1).")],
        None,
    ),
    ("Source", "getVolume"): ("Returns the current volume multiplier.", [], "`number` — volume (0–1)."),
    ("Source", "setPitch"): (
        "Sets the playback pitch multiplier. `1.0` is normal pitch; `2.0` doubles frequency.",
        [("pitch", "number", "Pitch multiplier.")],
        None,
    ),
    ("Source", "getPitch"): ("Returns the current pitch multiplier.", [], "`number` — pitch multiplier."),
    ("Source", "setLooping"): (
        "Enables or disables looping. When enabled, the source restarts automatically when it reaches the end.",
        [("loop", "boolean", "`true` to enable looping.")],
        None,
    ),
    ("Source", "isLooping"): ("Returns `true` if this source is set to loop.", [], "`boolean`."),
    ("Source", "seek"): (
        "Seeks playback to `offset` seconds from the start.",
        [("offset", "number", "Target position in seconds.")],
        None,
    ),
    ("Source", "tell"): (
        "Returns the current playback position in seconds.",
        [],
        "`number` — current position in seconds.",
    ),
    ("Source", "getDuration"): (
        "Returns the total duration of this audio source in seconds.",
        [],
        "`number` — total duration in seconds.",
    ),

    # ── Inventory ──
    ("Inventory", "addItem"): (
        "Adds an item by its string `id` to this inventory. Returns `true` on success, `false` if the inventory is full.",
        [("id", "string", "Item identifier to add.")],
        "`boolean` — `true` if added, `false` if the inventory is full.",
    ),
    ("Inventory", "removeItem"): (
        "Removes one unit of the item with the given `id`. Returns `true` if the item was present.",
        [("id", "string", "Item identifier to remove.")],
        "`boolean`.",
    ),
    ("Inventory", "hasItem"): (
        "Returns `true` if at least one unit of `id` is in this inventory.",
        [("id", "string", "Item identifier to test.")],
        "`boolean`.",
    ),
    ("Inventory", "getCount"): (
        "Returns the number of units of `id` currently in this inventory.",
        [("id", "string", "Item identifier to count.")],
        "`integer` — count.",
    ),
    ("Inventory", "getCapacity"): (
        "Returns the maximum number of item slots available in this inventory.",
        [],
        "`integer` — slot capacity.",
    ),
    ("Inventory", "isFull"): (
        "Returns `true` if the inventory has no remaining free slots.",
        [],
        "`boolean`.",
    ),
    ("Inventory", "isEmpty"): (
        "Returns `true` if the inventory contains no items.",
        [],
        "`boolean`.",
    ),
    ("Inventory", "clear"): (
        "Removes all items from this inventory.",
        [],
        None,
    ),
    ("Inventory", "getItems"): (
        "Returns an ordered `table` of all item IDs currently in this inventory.",
        [],
        "`table` of `string` item IDs.",
    ),

    # ── Entity ──
    ("Universe", "spawn"): (
        "Creates a new entity in this universe and returns its numeric ID.",
        [],
        "`integer` — entity ID.",
    ),
    ("Universe", "kill"): (
        "Destroys the entity with the given `id`, freeing its slot for reuse.",
        [("id", "integer", "Entity ID returned by `spawn`.")],
        None,
    ),
    ("Universe", "isAlive"): (
        "Returns `true` if the entity `id` is currently active in the universe.",
        [("id", "integer", "Entity ID to test.")],
        "`boolean`.",
    ),
    ("Universe", "addTag"): (
        "Attaches a string tag to the entity, enabling fast tag-based group queries.",
        [("id", "integer", "Entity ID."),
         ("tag", "string", "Tag label to add.")],
        None,
    ),
    ("Universe", "removeTag"): (
        "Removes a string tag from the entity.",
        [("id", "integer", "Entity ID."),
         ("tag", "string", "Tag to remove.")],
        None,
    ),
    ("Universe", "hasTag"): (
        "Returns `true` if the entity carries the given tag.",
        [("id", "integer", "Entity ID."),
         ("tag", "string", "Tag to test.")],
        "`boolean`.",
    ),
    ("Universe", "getByTag"): (
        "Returns a `table` of all entity IDs that carry `tag`.",
        [("tag", "string", "Tag to query.")],
        "`table` of `integer` entity IDs.",
    ),
    ("Universe", "count"): (
        "Returns the total number of living entities in this universe.",
        [],
        "`integer` — entity count.",
    ),

    # ── Tilemap ──
    ("TileMap", "setCell"): (
        "Sets the tile ID at grid position (`col`, `row`). Use `0` to clear a cell.",
        [("layer", "integer", "Layer index (0-based)."),
         ("col", "integer", "Column (x-axis cell index)."),
         ("row", "integer", "Row (y-axis cell index)."),
         ("tile_id", "integer", "Tile ID to place, or `0` to erase.")],
        None,
    ),
    ("TileMap", "getCell"): (
        "Returns the tile ID stored at grid position (`col`, `row`) on `layer`.",
        [("layer", "integer", "Layer index."),
         ("col", "integer", "Column index."),
         ("row", "integer", "Row index.")],
        "`integer` — tile ID, or `0` if empty.",
    ),
    ("TileMap", "worldToCell"): (
        "Converts world-space coordinates to grid cell indices.",
        [("x", "number", "World X coordinate."),
         ("y", "number", "World Y coordinate.")],
        "Two integers `col, row`.",
    ),
    ("TileMap", "cellToWorld"): (
        "Converts grid cell indices to world-space coordinates at the cell top-left corner.",
        [("col", "integer", "Column index."),
         ("row", "integer", "Row index.")],
        "Two numbers `x, y` in world space.",
    ),
    ("TileMap", "getWidth"): ("Returns the map width in tiles.", [], "`integer`."),
    ("TileMap", "getHeight"): ("Returns the map height in tiles.", [], "`integer`."),
    ("TileMap", "getTileWidth"): ("Returns the width of a single tile in pixels.", [], "`integer` — tile pixel width."),
    ("TileMap", "getTileHeight"): ("Returns the height of a single tile in pixels.", [], "`integer` — tile pixel height."),
    ("TileMap", "isWalkable"): (
        "Returns `true` if the cell at (`col`, `row`) is flagged as walkable in the collision layer.",
        [("col", "integer", "Column index."),
         ("row", "integer", "Row index.")],
        "`boolean`.",
    ),
    ("TileMap", "draw"): (
        "Draws all visible layers of the tilemap starting at world offset (`ox`, `oy`).",
        [("ox", "number", "World X offset for the top-left of the camera view."),
         ("oy", "number", "World Y offset.")],
        None,
    ),

    # ── NavGrid ──
    ("NavGrid", "setWalkable"): (
        "Marks the cell at (`col`, `row`) as walkable or blocked for pathfinding.",
        [("col", "integer", "Column index."),
         ("row", "integer", "Row index."),
         ("walkable", "boolean", "`true` if the cell is passable.")],
        None,
    ),
    ("NavGrid", "isWalkable"): (
        "Returns `true` if the cell at (`col`, `row`) is marked walkable.",
        [("col", "integer", "Column index."),
         ("row", "integer", "Row index.")],
        "`boolean`.",
    ),
    ("NavGrid", "findPath"): (
        "Runs A* to find the shortest path from (`sx`, `sy`) to (`ex`, `ey`) in grid cells.",
        [("sx", "integer", "Start column."),
         ("sy", "integer", "Start row."),
         ("ex", "integer", "End column."),
         ("ey", "integer", "End row.")],
        "`table` of `{x, y}` tables in cell coordinates, or `nil` if no path exists.",
    ),

    # ── DepthSorter (scene_api.rs) ──
    ("DepthSorter", "add"): (
        "Registers a draw callback at the given depth layer. Higher `depth` values draw in front.",
        [("callback", "function", "Draw callback `function()` called when flushing this layer."),
         ("depth", "number", "Depth value determining draw order (lower = drawn first).")],
        None,
    ),
    ("DepthSorter", "addObject"): (
        "Registers a table object with a `draw` method at the given depth.",
        [("obj", "table", "Object with a `draw()` method. Uses `obj.depth` if no explicit depth is provided.")],
        None,
    ),
    ("DepthSorter", "sort"): (
        "Sorts all registered callbacks and objects by their depth values (ascending).",
        [],
        None,
    ),
    ("DepthSorter", "flush"): (
        "Calls all registered draw callbacks and object `draw()` methods in sorted depth order, then clears the list.",
        [],
        None,
    ),
    ("DepthSorter", "clear"): (
        "Removes all registered callbacks and objects without calling them.",
        [],
        None,
    ),
    ("DepthSorter", "getCount"): (
        "Returns the number of callbacks and objects currently registered.",
        [],
        "`integer` — number of registered draw entries.",
    ),

    # ── ThreadHandle (thread_api.rs) ──
    ("ThreadHandle", "start"): (
        "Launches the background thread, passing optional arguments to the Lua script via `...`.",
        [("...", "any", "Optional arguments forwarded to the thread script as Lua values.")],
        None,
    ),
    ("ThreadHandle", "wait"): (
        "Blocks the calling coroutine until this thread finishes execution.",
        [],
        None,
    ),
    ("ThreadHandle", "isRunning"): (
        "Returns `true` if the thread is currently executing.",
        [],
        "`boolean`.",
    ),
    ("ThreadHandle", "getError"): (
        "Returns the error message if the thread terminated with a Lua error, or `nil` if it completed normally.",
        [],
        "`string` — error message, or `nil`.",
    ),

    # ── SaveManager (savegame_api.rs) ──
    ("SaveManager", "register"): (
        "Registers a named save slot backed by the given Lua table. The table's contents are serialized on `collect`.",
        [("name", "string", "Unique slot name."),
         ("target", "table", "Lua table whose fields will be collected and restored.")],
        None,
    ),
    ("SaveManager", "unregister"): (
        "Removes a previously registered save slot by name.",
        [("name", "string", "Slot name to remove.")],
        None,
    ),
    ("SaveManager", "setSchemaVersion"): (
        "Sets the schema version stored in the save file. Increment when save format changes.",
        [("version", "integer", "New schema version number.")],
        None,
    ),
    ("SaveManager", "getSchemaVersion"): (
        "Returns the schema version currently set on this save manager.",
        [],
        "`integer` — schema version.",
    ),
    ("SaveManager", "collect"): (
        "Snapshots all registered tables into an in-memory serializable form, ready for disk write.",
        [],
        "`table` — the collected save data.",
    ),
    ("SaveManager", "restore"): (
        "Restores all registered tables from a previously collected save data table.",
        [("data", "table", "Save data table as returned by `collect()`.")],
        None,
    ),
    ("SaveManager", "markDirty"): (
        "Marks the save as dirty, ensuring it will be written on the next autosave tick.",
        [],
        None,
    ),
    ("SaveManager", "isDirty"): (
        "Returns `true` if the save data has been modified since the last write.",
        [],
        "`boolean`.",
    ),
    ("SaveManager", "enableAutoSave"): (
        "Enables periodic autosave. The save file is written automatically every `interval` seconds.",
        [("interval", "number", "Autosave interval in seconds.")],
        None,
    ),
    ("SaveManager", "disableAutoSave"): (
        "Disables automatic periodic saving.",
        [],
        None,
    ),
    ("SaveManager", "update"): (
        "Ticks the autosave timer. Must be called from `luna.update(dt)` when autosave is enabled.",
        [("dt", "number", "Elapsed seconds since the last frame.")],
        None,
    ),
    ("SaveManager", "setSummary"): (
        "Sets a human-readable summary string stored alongside the save data (e.g. for save-slot UI).",
        [("summary", "string", "Display text for this save slot.")],
        None,
    ),
    ("SaveManager", "getSummary"): (
        "Returns the summary string set by `setSummary`, or an empty string if none was set.",
        [],
        "`string` — save slot summary.",
    ),
    ("SaveManager", "reset"): (
        "Clears all registered tables back to their initial state and marks the save dirty.",
        [],
        None,
    ),

    # ── Recipe (crafting_api.rs) ──
    ("Recipe", "getId"): ("Returns the unique string identifier of this recipe.", [], "`string` — recipe ID."),
    ("Recipe", "getName"): ("Returns the human-readable display name of this recipe.", [], "`string`."),
    ("Recipe", "setName"): ("Sets the display name of this recipe.", [("name", "string", "New display name.")], None),
    ("Recipe", "getType"): ("Returns the recipe type tag (e.g. `'smelt'`, `'craft'`).", [], "`string` — recipe type."),
    ("Recipe", "getTime"): ("Returns the base crafting duration in seconds.", [], "`number` — duration in seconds."),
    ("Recipe", "setTime"): ("Sets the base crafting duration in seconds.", [("time", "number", "New duration in seconds.")], None),
    ("Recipe", "getStationLevel"): ("Returns the minimum station level required to craft this recipe.", [], "`integer` — required station level."),
    ("Recipe", "setStationLevel"): ("Sets the minimum station level required to craft this recipe.", [("level", "integer", "Minimum station level.")], None),
    ("Recipe", "getStationType"): ("Returns the station type string required to craft this recipe.", [], "`string` — station type."),
    ("Recipe", "setStationType"): ("Sets which station type is required for this recipe.", [("type", "string", "Station type identifier.")], None),
    ("Recipe", "getSkill"): ("Returns the skill name gated on this recipe, or an empty string if none.", [], "`string` — required skill name, or `''`."),
    ("Recipe", "setSkill"): ("Sets the skill required to unlock and use this recipe.", [("skill", "string", "Skill name.")], None),
    ("Recipe", "getSkillXp"): ("Returns the XP awarded to the required skill when this recipe is completed.", [], "`number` — XP awarded."),
    ("Recipe", "setSkillXp"): ("Sets the skill XP awarded on completion.", [("xp", "number", "XP amount.")], None),
    ("Recipe", "getDescription"): ("Returns the lore/description text for this recipe.", [], "`string`."),
    ("Recipe", "setDescription"): ("Sets the description text shown in crafting UI.", [("desc", "string", "Description string.")], None),
    ("Recipe", "isEnabled"): ("Returns `true` if this recipe is currently craftable (not disabled).", [], "`boolean`."),
    ("Recipe", "setEnabled"): ("Enables or disables this recipe. Disabled recipes cannot be enqueued.", [("enabled", "boolean", "`true` to enable.")], None),
    ("Recipe", "hasTag"): ("Returns `true` if this recipe carries the given tag.", [("tag", "string", "Tag to test.")], "`boolean`."),
    ("Recipe", "addTag"): ("Attaches a string tag to this recipe.", [("tag", "string", "Tag to add.")], None),
    ("Recipe", "getTags"): ("Returns a list of all tags attached to this recipe.", [], "`table` of `string` tags."),
    ("Recipe", "addIngredient"): (
        "Adds an ingredient requirement to this recipe.",
        [("id", "string", "Item ID of the ingredient."), ("count", "integer", "Number of units required.")],
        None,
    ),
    ("Recipe", "addOutput"): (
        "Adds an output item produced when this recipe is completed.",
        [("id", "string", "Item ID of the output."), ("count", "integer", "Number of units produced.")],
        None,
    ),
    ("Recipe", "getIngredients"): (
        "Returns a list of all ingredient requirements as `{id, count}` tables.",
        [],
        "`table` of `{id: string, count: integer}` tables.",
    ),
    ("Recipe", "getOutputs"): (
        "Returns a list of all output items as `{id, count}` tables.",
        [],
        "`table` of `{id: string, count: integer}` tables.",
    ),

    # ── RecipeRegistry (crafting_api.rs) ──
    ("RecipeRegistry", "add"): (
        "Registers a recipe in this registry. Raises an error if a recipe with the same ID already exists.",
        [("recipe", "Recipe", "Recipe object to register.")],
        None,
    ),
    ("RecipeRegistry", "get"): (
        "Returns the registered recipe with the given ID, or `nil` if none exists.",
        [("id", "string", "Recipe ID to look up.")],
        "`Recipe` or `nil`.",
    ),
    ("RecipeRegistry", "remove"): (
        "Removes the recipe with the given ID from this registry.",
        [("id", "string", "Recipe ID to remove.")],
        None,
    ),
    ("RecipeRegistry", "count"): ("Returns the total number of registered recipes.", [], "`integer`."),
    ("RecipeRegistry", "getIds"): ("Returns a list of all registered recipe IDs.", [], "`table` of `string` IDs."),
    ("RecipeRegistry", "findByOutput"): (
        "Returns all recipes that produce an item with the given ID.",
        [("item_id", "string", "Output item ID to search for.")],
        "`table` of `Recipe` objects.",
    ),
    ("RecipeRegistry", "findByIngredient"): (
        "Returns all recipes that consume an item with the given ID as an ingredient.",
        [("item_id", "string", "Ingredient item ID to search for.")],
        "`table` of `Recipe` objects.",
    ),
    ("RecipeRegistry", "findByTag"): (
        "Returns all recipes that carry the given tag.",
        [("tag", "string", "Tag string to match.")],
        "`table` of `Recipe` objects.",
    ),
    ("RecipeRegistry", "forStation"): (
        "Returns all recipes that require the given station type.",
        [("station_type", "string", "Station type identifier.")],
        "`table` of `Recipe` objects.",
    ),

    # ── Station (crafting_api.rs) ──
    ("Station", "getType"): ("Returns the station type identifier string.", [], "`string`."),
    ("Station", "getLevel"): ("Returns the current upgrade level of this station.", [], "`integer` — level."),
    ("Station", "setLevel"): ("Sets the station's upgrade level, affecting which recipes it can process.", [("level", "integer", "New station level.")], None),
    ("Station", "getName"): ("Returns the display name of this station.", [], "`string`."),
    ("Station", "setName"): ("Sets the display name of this station.", [("name", "string", "New display name.")], None),
    ("Station", "getSpeedMultiplier"): ("Returns the crafting speed multiplier. `1.0` is normal speed.", [], "`number`."),
    ("Station", "setSpeedMultiplier"): ("Sets the crafting speed multiplier. Values above `1.0` reduce effective recipe time.", [("mult", "number", "Speed multiplier (e.g. `2.0` for double speed).")], None),
    ("Station", "isActive"): ("Returns `true` if this station is operational and can process recipes.", [], "`boolean`."),
    ("Station", "setActive"): ("Enables or disables this station.", [("active", "boolean", "`true` to enable.")], None),
    ("Station", "canProcess"): (
        "Returns `true` if this station can currently process the given recipe (level and type match).",
        [("recipe", "Recipe", "Recipe to check against this station's type and level.")],
        "`boolean`.",
    ),
    ("Station", "effectiveTime"): (
        "Returns the effective crafting time for `recipe` after applying this station's speed multiplier.",
        [("recipe", "Recipe", "The recipe to evaluate.")],
        "`number` — effective time in seconds.",
    ),

    # ── CraftSkill (crafting_api.rs) ──
    ("CraftSkill", "getName"): ("Returns the skill's name identifier.", [], "`string`."),
    ("CraftSkill", "getXp"): ("Returns the total accumulated XP for this skill.", [], "`number` — total XP."),
    ("CraftSkill", "getLevel"): ("Returns the current level derived from total XP.", [], "`integer` — current level."),
    ("CraftSkill", "getXpToNext"): ("Returns the XP required to reach the next level.", [], "`number` — XP needed."),
    ("CraftSkill", "setLevel"): ("Sets the skill directly to the given level, adjusting XP accordingly.", [("level", "integer", "Target level.")], None),
    ("CraftSkill", "addXp"): ("Adds `xp` to this skill's total, potentially triggering level-ups.", [("xp", "number", "XP to add.")], None),
    ("CraftSkill", "canUse"): (
        "Returns `true` if this skill's level meets the minimum required to use the given recipe.",
        [("recipe", "Recipe", "Recipe to check skill requirement against.")],
        "`boolean`.",
    ),

    # ── Card (cardgame_api.rs) ──
    ("Card", "getCardType"): ("Returns the type identifier string for this card.", [], "`string`."),
    ("Card", "getName"): ("Returns the display name of this card.", [], "`string`."),
    ("Card", "setName"): ("Sets the card's display name.", [("name", "string", "New name.")], None),
    ("Card", "getCategory"): ("Returns the category tag for this card (e.g. `'spell'`, `'creature'`).", [], "`string`."),
    ("Card", "setCategory"): ("Sets the category tag for this card.", [("category", "string", "New category.")], None),
    ("Card", "getStat"): (
        "Returns the value of the named numeric stat.",
        [("key", "string", "Stat name (e.g. `'attack'`, `'defense'`).")],
        "`number` — stat value, or `0` if not set.",
    ),
    ("Card", "setStat"): (
        "Sets a numeric stat on this card.",
        [("key", "string", "Stat name."), ("value", "number", "Stat value.")],
        None,
    ),
    ("Card", "getStats"): ("Returns all numeric stats as a key-value table.", [], "`table` of `{stat: number}` pairs."),
    ("Card", "addTag"): ("Attaches a tag to this card.", [("tag", "string", "Tag to add.")], None),
    ("Card", "removeTag"): ("Removes a tag from this card.", [("tag", "string", "Tag to remove.")], None),
    ("Card", "hasTag"): ("Returns `true` if this card carries the given tag.", [("tag", "string", "Tag to test.")], "`boolean`."),
    ("Card", "getTags"): ("Returns a list of all tags attached to this card.", [], "`table` of `string` tags."),
    ("Card", "addCounter"): (
        "Increments the named counter by `amount` (default `1`).",
        [("name", "string", "Counter name."), ("amount", "integer", "Amount to add (optional, default `1`).")],
        None,
    ),
    ("Card", "getCounter"): ("Returns the current value of the named counter.", [("name", "string", "Counter name.")], "`integer` — counter value."),
    ("Card", "removeCounters"): ("Removes all counters of the given name.", [("name", "string", "Counter name to clear.")], None),
    ("Card", "getAllCounters"): ("Returns a key-value table of all counters on this card.", [], "`table` of `{name: integer}` counter pairs."),
    ("Card", "tap"): ("Marks this card as tapped. A tapped card cannot be tapped again until untapped.", [], None),
    ("Card", "untap"): ("Removes the tapped state from this card.", [], None),
    ("Card", "isTapped"): ("Returns `true` if this card is currently tapped.", [], "`boolean`."),
    ("Card", "isFaceUp"): ("Returns `true` if this card is face-up (visible).", [], "`boolean`."),
    ("Card", "setFaceUp"): ("Sets whether this card is face-up (`true`) or face-down (`false`).", [("face_up", "boolean", "Face state.")], None),
    ("Card", "getOwner"): ("Returns the owner identifier string, or `nil` if unowned.", [], "`string` or `nil`."),
    ("Card", "setOwner"): ("Sets the owner identifier for this card.", [("owner", "string", "Owner identifier.")], None),
    ("Card", "getController"): ("Returns the controller identifier (the player currently controlling this card).", [], "`string` or `nil`."),
    ("Card", "setController"): ("Sets the controller for this card.", [("controller", "string", "Controller identifier.")], None),
    ("Card", "getZone"): ("Returns the name of the zone this card currently occupies.", [], "`string` — zone name."),
    ("Card", "getMeta"): ("Returns the metadata value for `key`, or `nil` if not set.", [("key", "string", "Metadata key.")], "The stored value or `nil`."),
    ("Card", "setMeta"): ("Stores an arbitrary metadata value on this card.", [("key", "string", "Metadata key."), ("value", "any", "Value to store.")], None),
    ("Card", "clone"): ("Creates and returns a deep copy of this card with identical stats, tags, and counters.", [], "`Card` — the new copy."),

    # ── Deck (cardgame_api.rs) ──
    ("Deck", "getName"): ("Returns the deck's name.", [], "`string`."),
    ("Deck", "getSize"): ("Returns the number of cards currently in this deck.", [], "`integer`."),
    ("Deck", "isEmpty"): ("Returns `true` if the deck contains no cards.", [], "`boolean`."),
    ("Deck", "shuffle"): ("Shuffles the deck in-place using a Fisher–Yates shuffle.", [], None),
    ("Deck", "insertAt"): (
        "Inserts `card` at position `index` (1-based). Use index `1` for top, or the deck size for bottom.",
        [("index", "integer", "1-based insertion position."), ("card", "Card", "Card to insert.")],
        None,
    ),
    ("Deck", "draw"): ("Removes and returns the top card of the deck, or `nil` if empty.", [], "`Card` or `nil`."),
    ("Deck", "drawBottom"): ("Removes and returns the bottom card of the deck, or `nil` if empty.", [], "`Card` or `nil`."),
    ("Deck", "peek"): ("Returns the top card without removing it, or `nil` if empty.", [], "`Card` or `nil`."),
    ("Deck", "removeAt"): ("Removes and returns the card at 1-based `index`.", [("index", "integer", "1-based position.")], "`Card` or `nil`."),
    ("Deck", "searchByTag"): (
        "Returns a list of all cards in this deck that carry the given tag.",
        [("tag", "string", "Tag to search for.")],
        "`table` of `Card` objects.",
    ),
    ("Deck", "searchByType"): (
        "Returns a list of all cards of the given type.",
        [("card_type", "string", "Card type identifier to match.")],
        "`table` of `Card` objects.",
    ),
    ("Deck", "countByType"): (
        "Returns the count of cards matching the given type.",
        [("card_type", "string", "Card type to count.")],
        "`integer`.",
    ),
    ("Deck", "revealTop"): (
        "Returns the top `n` cards without removing them.",
        [("n", "integer", "Number of cards to reveal.")],
        "`table` of `Card` objects (may be fewer than `n` if the deck is small).",
    ),
    ("Deck", "getCards"): ("Returns the full ordered list of cards in this deck (top to bottom).", [], "`table` of `Card` objects."),
    ("Deck", "moveWithin"): (
        "Moves the card at `from` to `to` (both 1-based), shifting other cards to fill the gap.",
        [("from", "integer", "Source position."), ("to", "integer", "Destination position.")],
        None,
    ),

    # ── Zone (cardgame_api.rs) ──
    ("Zone", "getName"): ("Returns the zone's name identifier.", [], "`string`."),
    ("Zone", "getSize"): ("Returns the number of cards currently in this zone.", [], "`integer`."),
    ("Zone", "isEmpty"): ("Returns `true` if this zone holds no cards.", [], "`boolean`."),
    ("Zone", "getCapacity"): ("Returns the maximum number of cards this zone can hold (`0` = unlimited).", [], "`integer`."),
    ("Zone", "canAdd"): ("Returns `true` if another card can be added (capacity not yet reached).", [], "`boolean`."),
    ("Zone", "add"): ("Adds `card` to this zone. Raises an error if the zone is at capacity.", [("card", "Card", "Card to add.")], None),
    ("Zone", "removeAt"): ("Removes and returns the card at 1-based `index`.", [("index", "integer", "1-based position.")], "`Card` or `nil`."),
    ("Zone", "countByType"): ("Returns the count of cards with the given type in this zone.", [("card_type", "string", "Type to count.")], "`integer`."),
    ("Zone", "getAllTypes"): ("Returns a deduplicated list of all card type strings present in this zone.", [], "`table` of `string` type names."),
    ("Zone", "findByType"): ("Returns all cards of the given type in this zone.", [("card_type", "string", "Type to search for.")], "`table` of `Card` objects."),
    ("Zone", "getCards"): ("Returns the full ordered list of cards in this zone.", [], "`table` of `Card` objects."),

    # ── StackManager (cardgame_api.rs) ──
    ("StackManager", "push"): (
        "Places an effect or action on top of the stack.",
        [("kind", "string", "Effect kind identifier."), ("data", "table", "Effect data table.")],
        None,
    ),
    ("StackManager", "resolve"): (
        "Removes and returns the top effect from the stack, resolving it.",
        [],
        "`table` with `kind` and `data` fields, or `nil` if the stack is empty.",
    ),
    ("StackManager", "peek"): (
        "Returns the top effect without resolving it.",
        [],
        "`table` with `kind` and `data` fields, or `nil`.",
    ),
    ("StackManager", "isEmpty"): ("Returns `true` if the stack holds no pending effects.", [], "`boolean`."),
    ("StackManager", "getSize"): ("Returns the number of effects currently on the stack.", [], "`integer`."),
    ("StackManager", "clear"): ("Discards all pending effects on the stack.", [], None),
    ("StackManager", "findByKind"): (
        "Returns all effects on the stack matching the given kind identifier.",
        [("kind", "string", "Effect kind to search for.")],
        "`table` of effect tables.",
    ),

    # ── StatusEffect (combat_api.rs) ──
    ("StatusEffect", "getName"): ("Returns the status effect's name identifier (e.g. `'poison'`, `'burn'`).", [], "`string`."),
    ("StatusEffect", "getDuration"): ("Returns the remaining duration in turns.", [], "`integer` — turns remaining."),
    ("StatusEffect", "setDuration"): ("Sets the remaining duration in turns.", [("turns", "integer", "New duration.")], None),
    ("StatusEffect", "getStacks"): ("Returns the current stack count of this status effect.", [], "`integer` — stack count."),
    ("StatusEffect", "setStacks"): ("Sets the stack count directly.", [("stacks", "integer", "New stack count.")], None),
    ("StatusEffect", "isExpired"): ("Returns `true` if this effect's duration has reached zero.", [], "`boolean`."),
    ("StatusEffect", "tickTurn"): ("Decrements the duration by 1 and removes the effect if it expires.", [], None),

    # ── CombatAction (combat_api.rs) ──
    ("CombatAction", "getName"): ("Returns the action's name identifier.", [], "`string`."),
    ("CombatAction", "getBaseDamage"): ("Returns the base damage dealt by this action before modifiers.", [], "`number`."),
    ("CombatAction", "setBaseDamage"): ("Sets the base damage for this action.", [("damage", "number", "New base damage value.")], None),
    ("CombatAction", "getDamageType"): ("Returns the damage type string (e.g. `'physical'`, `'fire'`).", [], "`string`."),
    ("CombatAction", "setDamageType"): ("Sets the damage type.", [("dtype", "string", "Damage type string.")], None),
    ("CombatAction", "getAccuracy"): ("Returns the hit chance as a percentage (0–100).", [], "`number` — accuracy percentage."),
    ("CombatAction", "setAccuracy"): ("Sets the hit chance percentage.", [("accuracy", "number", "Hit chance (0–100).")], None),
    ("CombatAction", "getCooldown"): ("Returns the maximum cooldown in turns before this action can be used again.", [], "`integer` — max cooldown turns."),
    ("CombatAction", "setCooldown"): ("Sets the maximum cooldown for this action.", [("turns", "integer", "Cooldown in turns.")], None),
    ("CombatAction", "getCurrentCooldown"): ("Returns the remaining cooldown turns until this action is ready.", [], "`integer` — turns remaining."),
    ("CombatAction", "isReady"): ("Returns `true` if the current cooldown has reached zero.", [], "`boolean`."),
    ("CombatAction", "tickCooldown"): ("Decrements the current cooldown by 1 (minimum 0).", [], None),
    ("CombatAction", "getCostMp"): ("Returns the MP cost to use this action.", [], "`integer` — MP cost."),
    ("CombatAction", "setCostMp"): ("Sets the MP cost for this action.", [("cost", "integer", "New MP cost.")], None),

    # ── Combatant (combat_api.rs) ──
    ("Combatant", "getName"): ("Returns the combatant's display name.", [], "`string`."),
    ("Combatant", "getTeam"): ("Returns the team identifier for this combatant.", [], "`string` — team name."),
    ("Combatant", "setTeam"): ("Assigns this combatant to a team.", [("team", "string", "Team identifier.")], None),
    ("Combatant", "getHp"): ("Returns current HP.", [], "`number`."),
    ("Combatant", "setHp"): ("Sets current HP, clamped to [0, maxHp].", [("hp", "number", "New HP value.")], None),
    ("Combatant", "getMaxHp"): ("Returns maximum HP.", [], "`number`."),
    ("Combatant", "setMaxHp"): ("Sets the maximum HP and clamps current HP if needed.", [("max_hp", "number", "New max HP.")], None),
    ("Combatant", "getMp"): ("Returns current MP.", [], "`number`."),
    ("Combatant", "setMp"): ("Sets current MP, clamped to [0, maxMp].", [("mp", "number", "New MP value.")], None),
    ("Combatant", "getMaxMp"): ("Returns maximum MP.", [], "`number`."),
    ("Combatant", "setMaxMp"): ("Sets the maximum MP.", [("max_mp", "number", "New max MP.")], None),
    ("Combatant", "getSpeed"): ("Returns the initiative speed value used to determine turn order.", [], "`number`."),
    ("Combatant", "setSpeed"): ("Sets the initiative speed value.", [("speed", "number", "New speed value.")], None),
    ("Combatant", "getLevel"): ("Returns the combatant's experience level.", [], "`integer`."),
    ("Combatant", "isAlive"): ("Returns `true` if current HP is greater than zero.", [], "`boolean`."),
    ("Combatant", "takeDamage"): (
        "Applies `amount` damage of `dtype`, reduced by resistances, and returns net damage dealt.",
        [("amount", "number", "Incoming damage before resistance."),
         ("dtype", "string", "Damage type (e.g. `'fire'`, `'physical'`).")],
        "`number` — net damage after resistance.",
    ),
    ("Combatant", "heal"): (
        "Increases current HP by `amount`, clamped at maxHp.",
        [("amount", "number", "Amount to heal.")],
        "`number` — actual HP restored.",
    ),
    ("Combatant", "getStat"): (
        "Returns the value of a named stat (e.g. `'strength'`, `'agility'`).",
        [("key", "string", "Stat name.")],
        "`number` — stat value, or `0` if not set.",
    ),
    ("Combatant", "setStat"): (
        "Sets a named stat value.",
        [("key", "string", "Stat name."), ("value", "number", "New value.")],
        None,
    ),
    ("Combatant", "getResistance"): (
        "Returns the resistance percentage for `dtype` (0–100). `100` means immune.",
        [("dtype", "string", "Damage type.")],
        "`number` — resistance percentage.",
    ),
    ("Combatant", "setResistance"): (
        "Sets resistance for a damage type.",
        [("dtype", "string", "Damage type."), ("pct", "number", "Resistance percentage (0–100).")],
        None,
    ),
    ("Combatant", "addStatus"): (
        "Applies a named status effect, optionally stacking on an existing one.",
        [("name", "string", "Status effect name."),
         ("duration", "integer", "Duration in turns."),
         ("stacks", "integer", "Stack count (optional, default `1`).")],
        None,
    ),
    ("Combatant", "removeStatus"): (
        "Removes the status effect with the given name.",
        [("name", "string", "Status effect name to remove.")],
        None,
    ),
    ("Combatant", "hasStatus"): (
        "Returns `true` if this combatant is affected by the named status.",
        [("name", "string", "Status name to check.")],
        "`boolean`.",
    ),
    ("Combatant", "tickStatuses"): (
        "Decrements all active status effect durations by one turn and removes any that expire.",
        [],
        None,
    ),
    ("Combatant", "getStatuses"): (
        "Returns a list of all active `StatusEffect` objects on this combatant.",
        [],
        "`table` of `StatusEffect` objects.",
    ),
    ("Combatant", "addAction"): (
        "Registers a `CombatAction` that this combatant can use in battle.",
        [("action", "CombatAction", "Action to add.")],
        None,
    ),
    ("Combatant", "hasAction"): (
        "Returns `true` if this combatant has an action with the given name.",
        [("name", "string", "Action name.")],
        "`boolean`.",
    ),
    ("Combatant", "tickCooldowns"): (
        "Decrements all active action cooldowns by one turn.",
        [],
        None,
    ),
    ("Combatant", "getMeta"): (
        "Returns metadata value for `key`, or `nil` if not set.",
        [("key", "string", "Metadata key.")],
        "The stored value or `nil`.",
    ),
    ("Combatant", "setMeta"): (
        "Stores an arbitrary metadata value on this combatant.",
        [("key", "string", "Key."), ("value", "any", "Value.")],
        None,
    ),

    # ── Light2D (graphics_ext_api.rs) ──
    ("Light2D", "setPosition"): (
        "Sets the light source position in world space.",
        [("x", "number", "World X coordinate."), ("y", "number", "World Y coordinate.")],
        None,
    ),
    ("Light2D", "getPosition"): ("Returns the light position in world space.", [], "Two numbers `x, y`."),
    ("Light2D", "setRadius"): (
        "Sets the falloff radius of this light. Pixels beyond the radius receive no illumination.",
        [("radius", "number", "Radius in world units.")],
        None,
    ),
    ("Light2D", "getRadius"): ("Returns the current light radius in world units.", [], "`number`."),
    ("Light2D", "setColor"): (
        "Sets the light color as RGBA components.",
        [("r", "number", "Red (0–1)."), ("g", "number", "Green (0–1)."), ("b", "number", "Blue (0–1)."), ("a", "number", "Alpha/intensity (0–1).")],
        None,
    ),
    ("Light2D", "getColor"): ("Returns the current light color.", [], "Four numbers `r, g, b, a`."),
    ("Light2D", "setEnabled"): (
        "Enables or disables this light. Disabled lights contribute no illumination.",
        [("enabled", "boolean", "`true` to enable.")],
        None,
    ),
    ("Light2D", "isEnabled"): ("Returns `true` if this light is currently enabled.", [], "`boolean`."),

    # ── TextureAtlas (graphics_ext_api.rs) ──
    ("TextureAtlas", "addRegion"): (
        "Defines a named sub-region within the atlas texture.",
        [("name", "string", "Region name."),
         ("x", "integer", "Left pixel of the region."),
         ("y", "integer", "Top pixel of the region."),
         ("w", "integer", "Region width in pixels."),
         ("h", "integer", "Region height in pixels.")],
        None,
    ),
    ("TextureAtlas", "getRegion"): (
        "Returns the pixel bounds of the named region.",
        [("name", "string", "Region name.")],
        "`table` with `x`, `y`, `w`, `h` fields, or `nil` if not found.",
    ),
    ("TextureAtlas", "hasRegion"): (
        "Returns `true` if a region with the given name is registered in this atlas.",
        [("name", "string", "Region name to test.")],
        "`boolean`.",
    ),
    ("TextureAtlas", "getNames"): (
        "Returns a list of all registered region names.",
        [],
        "`table` of `string` names.",
    ),
    ("TextureAtlas", "getCount"): (
        "Returns the number of regions registered in this atlas.",
        [],
        "`integer`.",
    ),

    # ── Viewport (graphics_ext_api.rs) ──
    ("Viewport", "getWidth"): ("Returns the viewport width in pixels.", [], "`integer`."),
    ("Viewport", "getHeight"): ("Returns the viewport height in pixels.", [], "`integer`."),
    ("Viewport", "getDimensions"): ("Returns viewport width and height.", [], "Two integers `width, height`."),
    ("Viewport", "setScale"): (
        "Sets the content scale factor. `2.0` doubles the rendered size.",
        [("scale", "number", "Scale factor.")],
        None,
    ),
    ("Viewport", "getScale"): ("Returns the current content scale factor.", [], "`number`."),
    ("Viewport", "setOffset"): (
        "Sets the scroll offset applied when rendering into this viewport.",
        [("ox", "number", "Horizontal offset."), ("oy", "number", "Vertical offset.")],
        None,
    ),
    ("Viewport", "getOffset"): ("Returns the current viewport scroll offset.", [], "Two numbers `ox, oy`."),
    ("Viewport", "toWorld"): (
        "Converts screen-space pixel coordinates to world-space coordinates within this viewport.",
        [("sx", "number", "Screen X."), ("sy", "number", "Screen Y.")],
        "Two numbers `wx, wy` in world space.",
    ),
    ("Viewport", "toScreen"): (
        "Converts world-space coordinates to screen-space pixel coordinates.",
        [("wx", "number", "World X."), ("wy", "number", "World Y.")],
        "Two numbers `sx, sy` in screen pixels.",
    ),

    # ── SpriteSheet (graphics_ext_api.rs) ──
    ("SpriteSheet", "getFrameCount"): ("Returns the total number of frames in this sprite sheet.", [], "`integer`."),
    ("SpriteSheet", "getFrameWidth"): ("Returns the width of a single frame in pixels.", [], "`integer`."),
    ("SpriteSheet", "getFrameHeight"): ("Returns the height of a single frame in pixels.", [], "`integer`."),
    ("SpriteSheet", "getUV"): (
        "Returns UV texture coordinates for the given 0-based frame index.",
        [("frame", "integer", "0-based frame index.")],
        "Four numbers `u1, v1, u2, v2` in normalized texture space.",
    ),
    ("SpriteSheet", "getFrameRect"): (
        "Returns the pixel rectangle of the given frame within the source texture.",
        [("frame", "integer", "0-based frame index.")],
        "Four integers `x, y, w, h`.",
    ),
    ("SpriteSheet", "getColumns"): ("Returns the number of columns in the sprite sheet grid.", [], "`integer`."),
    ("SpriteSheet", "getRows"): ("Returns the number of rows in the sprite sheet grid.", [], "`integer`."),

    # ── DrawLayer (graphics_ext_api.rs) ──
    ("DrawLayer", "setVisible"): (
        "Shows or hides this draw layer. Hidden layers are skipped during rendering.",
        [("visible", "boolean", "`true` to show.")],
        None,
    ),
    ("DrawLayer", "isVisible"): ("Returns `true` if this layer is currently visible.", [], "`boolean`."),
    ("DrawLayer", "setOpacity"): (
        "Sets the opacity multiplier for all draw calls in this layer. `1.0` is fully opaque.",
        [("opacity", "number", "Opacity (0–1).")],
        None,
    ),
    ("DrawLayer", "getOpacity"): ("Returns the current opacity multiplier.", [], "`number`."),
}


# ─── Utility: build the new docstring block ───────────────────────────────────

def build_docstring(summary: str, params: list, returns: str | None, indent: str) -> str:
    lines = [f"{indent}/// {summary}"]
    if params:
        lines.append(f"{indent}///")
        lines.append(f"{indent}/// # Parameters")
        for p in params:
            n, t, desc = p
            lines.append(f"{indent}/// - `{n}` — `{t}`: {desc}")
    if returns:
        lines.append(f"{indent}///")
        lines.append(f"{indent}/// # Returns")
        lines.append(f"{indent}/// {returns}")
    return "\n".join(lines)


# ─── Per-file rewrite ─────────────────────────────────────────────────────────

BINDING_RE = re.compile(
    r'((?:add_method_mut|add_method|add_function|add_function_mut)\s*\(\s*"([^"]+)")'
)


def current_class(lines: list[str], idx: int) -> str:
    for j in range(idx - 1, -1, -1):
        m = re.search(r'impl\s+LuaUserData\s+for\s+Lua(\w+)', lines[j])
        if m:
            return m.group(1)
        m2 = re.search(r'struct\s+Lua(\w+)', lines[j])
        if m2:
            return m2.group(1)
    return ""


def find_doc_block_above(lines: list[str], idx: int) -> tuple[int, int] | None:
    """Return (start_line, end_line) inclusive of the /// block above line idx,
    or None if there is no such block."""
    # Skip blank lines, #[...] attributes, let x = y.clone(); lines immediately above
    j = idx - 1
    end = None
    while j >= 0:
        s = lines[j].strip()
        if s.startswith("///"):
            end = j
            break
        elif s == "" or s.startswith("#[") or re.match(r'^let\s+\w+', s) or (s.startswith("//") and not s.startswith("///")):
            j -= 1
        else:
            break

    if end is None:
        return None

    # Walk further up to find the start of the block
    start = end
    k = end - 1
    while k >= 0:
        s = lines[k].strip()
        if s.startswith("///"):
            start = k
            k -= 1
        else:
            break
    return (start, end)


def process_file(path: pathlib.Path, dry_run: bool = False) -> int:
    text = path.read_text(encoding='utf-8')
    lines = text.splitlines()
    replacements = 0

    # Process in reverse order to preserve indices
    positions = []  # (method_line_idx, class_name, method_name)
    for i, line in enumerate(lines):
        m = BINDING_RE.search(line)
        if not m:
            m2 = re.search(r'\.set\s*\(\s*"([^"]+)"', line)
            if not m2:
                continue
            method_name = m2.group(1)
        else:
            method_name = m.group(2)

        if method_name in ('__index', '__newindex', '__tostring', '__len',
                           '__eq', '__lt', '__le', '__call', '__gc'):
            continue

        class_name = current_class(lines, i)
        key = (class_name, method_name)
        if key not in OVERRIDES:
            continue

        positions.append((i, class_name, method_name))

    for method_idx, class_name, method_name in reversed(positions):
        key = (class_name, method_name)
        summary, params, returns = OVERRIDES[key]
        indent = re.match(r'^(\s*)', lines[method_idx]).group(1)
        new_doc = build_docstring(summary, params, returns, indent)

        doc_range = find_doc_block_above(lines, method_idx)

        if not dry_run:
            if doc_range:
                start, end = doc_range
                # Replace existing doc block
                lines[start:end + 1] = new_doc.splitlines()
            else:
                # Insert before method line
                lines.insert(method_idx, new_doc)

        replacements += 1

    if not dry_run and replacements:
        path.write_text("\n".join(lines) + "\n", encoding='utf-8')

    return replacements


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--file', default=None)
    args = parser.parse_args()

    if args.file:
        files = [LUA_API_DIR / args.file]
    else:
        files = sorted(LUA_API_DIR.glob('*.rs'))

    total = 0
    for f in files:
        n = process_file(f, dry_run=args.dry_run)
        if n:
            verb = "would improve" if args.dry_run else "improved"
            print(f"  {f.name}: {verb} {n} docstrings")
            total += n

    print(f"\nTotal: {total} docstrings {'would be improved' if args.dry_run else 'improved'}.")


if __name__ == '__main__':
    main()
