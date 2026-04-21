-- content/examples/animation.lua
-- Lurek2D lurek.animation API Reference
-- Run with: cargo run -- content/examples/animation
--
-- Scenario: A character controller with sprite-sheet animations — idle, walk,
-- attack clips — managed by a state machine that transitions between them.
-- Includes animation curves for property interpolation and sync groups for
-- coordinated multi-character animations.

print("=== lurek.animation — Sprite Animation ===\n")

-- =============================================================================
-- Animation Creation
-- =============================================================================

--@api-stub: lurek.animation.new
local anim = lurek.animation.new()

-- =============================================================================
-- Frame Management
-- =============================================================================

--@api-stub: Animation:addFrame
-- Add individual frames (quad, duration).
anim:addFrame(0, 0, 32, 32, 0.1)
anim:addFrame(32, 0, 32, 32, 0.1)
anim:addFrame(64, 0, 32, 32, 0.1)
anim:addFrame(96, 0, 32, 32, 0.1)

--@api-stub: Animation:addFramesFromGrid
-- Add frames from a spritesheet grid (cols, rows, frame_count, duration_each).
anim:addFramesFromGrid(4, 4, 8, 0.1)

--@api-stub: Animation:getFrameCount
print("frames: " .. anim:getFrameCount())

-- =============================================================================
-- Clips — Named animation sequences
-- =============================================================================

--@api-stub: Animation:addClip
anim:addClip("idle", 0, 3, 0.15, true)

--@api-stub: Animation:addClipFromGrid
anim:addClipFromGrid("walk", 0, 1, 8, 0.08, true)

--@api-stub: Animation:getClipCount
print("clips: " .. anim:getClipCount())

--@api-stub: Animation:getClip
local clip = anim:getClip("idle")
print("idle clip: " .. tostring(clip))

-- =============================================================================
-- Playback Control
-- =============================================================================

--@api-stub: Animation:play
anim:play("walk")

--@api-stub: Animation:isPlaying
print("playing: " .. tostring(anim:isPlaying()))

--@api-stub: Animation:isLooping
print("looping: " .. tostring(anim:isLooping()))

--@api-stub: Animation:setSpeed
anim:setSpeed(1.5)

--@api-stub: Animation:getSpeed
print("speed: " .. anim:getSpeed())

--@api-stub: Animation:update
anim:update(1/60)

--@api-stub: Animation:getCurrentFrame
print("frame: " .. anim:getCurrentFrame())

--@api-stub: Animation:setFrame
anim:setFrame(2)

--@api-stub: Animation:getQuad
local quad = anim:getQuad()

--@api-stub: Animation:getBlendState
local blend = anim:getBlendState()

--@api-stub: Animation:pollEvents
local events = anim:pollEvents()
print("events: " .. #events)

--@api-stub: Animation:pause
anim:pause()

--@api-stub: Animation:resume
anim:resume()

--@api-stub: Animation:stop
anim:stop()

-- =============================================================================
-- Aseprite Import
-- =============================================================================

--@api-stub: lurek.animation.fromAseprite
local aseprite_anim = lurek.animation.fromAseprite("assets/sprites/hero.json")
print("aseprite loaded")

-- =============================================================================
-- State Machine — Automatic transitions
-- =============================================================================

--@api-stub: lurek.animation.newStateMachine
local sm = lurek.animation.newStateMachine()

--@api-stub: AnimStateMachine:update
sm:update(1/60)

--@api-stub: AnimStateMachine:getState
print("state: " .. tostring(sm:getState()))

--@api-stub: AnimStateMachine:forceState
sm:forceState("idle")

--@api-stub: AnimStateMachine:getQuad
local sm_quad = sm:getQuad()

-- =============================================================================
-- Animation Curves — Property interpolation
-- =============================================================================

--@api-stub: lurek.animation.newCurve
local curve = lurek.animation.newCurve()

--@api-stub: AnimCurve:addKeyframe
curve:addKeyframe(0.0, 0.0)
curve:addKeyframe(0.5, 1.0)
curve:addKeyframe(1.0, 0.0)

--@api-stub: AnimCurve:keyframeCount
print("keyframes: " .. curve:keyframeCount())

--@api-stub: AnimCurve:eval
print("curve at 0.25: " .. curve:eval(0.25))
print("curve at 0.75: " .. curve:eval(0.75))

--@api-stub: AnimCurve:setEasing
curve:setEasing("inOutQuad")

--@api-stub: AnimCurve:clear
-- curve:clear()

-- =============================================================================
-- Sync Groups — Coordinated animations
-- =============================================================================

--@api-stub: lurek.animation.newSyncGroup
local sync = lurek.animation.newSyncGroup()

--@api-stub: AnimSyncGroup:add
sync:add("hero_walk")
sync:add("companion_walk")

--@api-stub: AnimSyncGroup:memberCount
print("sync members: " .. sync:memberCount())

--@api-stub: AnimSyncGroup:remove
sync:remove("companion_walk")

--@api-stub: AnimSyncGroup:clear
sync:clear()

-- =============================================================================
-- Blend Layer Sets — Multi-layer blending
-- =============================================================================

--@api-stub: lurek.animation.newBlendLayerSet
local layers = lurek.animation.newBlendLayerSet()

--@api-stub: BlendLayerSet:setWeight
layers:setWeight("upper_body", 1.0)

--@api-stub: BlendLayerSet:getWeight
print("upper weight: " .. layers:getWeight("upper_body"))

--@api-stub: BlendLayerSet:setMask
layers:setMask("upper_body", {head = true, torso = true, arms = true})

--@api-stub: BlendLayerSet:listLayers
local layer_list = layers:listLayers()
print("layers: " .. #layer_list)

--@api-stub: BlendLayerSet:removeLayer
layers:removeLayer("upper_body")

--@api-stub: BlendLayerSet:len
print("blend layers: " .. layers:len())

print("\n-- animation.lua example complete --")

-- =============================================================================
-- STUBS: 2 uncovered lurek.animation API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- AnimStateMachine methods
-- -----------------------------------------------------------------------------

-- ---- Stub: AnimStateMachine:setParam -------------------------------------
--@api-stub: AnimStateMachine:setParam
-- Sets an FSM parameter value (number, boolean, or integer supported).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- animStateMachine_stub:setParam("hero", 42)
-- (replace animStateMachine_stub with your real AnimStateMachine instance above)

-- -----------------------------------------------------------------------------
-- Animation methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Animation:drawToImage -----------------------------------------
--@api-stub: Animation:drawToImage
-- Renders the current animation frame into a new ImageData (white bg, blue frame rect).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- animation_stub:drawToImage(64.0, 64.0)  -- -> ImageData
-- (replace animation_stub with your real Animation instance above)
