-- content/examples/animation.lua
-- Lurek2D lurek.animation API Reference
-- Run with: cargo run -- content/examples/animation
--
Scenario: A character controller with sprite-sheet animations — idle, walk,
-- attack clips — managed by a state machine that transitions between them.
-- Includes animation curves for property interpolation and sync groups for
-- coordinated multi-character animations.

print("=== lurek.animation — Sprite Animation ===\n")

-- =============================================================================
-- Animation Creation
-- =============================================================================

local anim = lurek.animation.new()

-- =============================================================================
-- Frame Management
-- =============================================================================

-- Add individual frames (quad, duration).
anim:addFrame(0, 0, 32, 32, 0.1)
anim:addFrame(32, 0, 32, 32, 0.1)
anim:addFrame(64, 0, 32, 32, 0.1)
anim:addFrame(96, 0, 32, 32, 0.1)

-- Add frames from a spritesheet grid (cols, rows, frame_count, duration_each).
anim:addFramesFromGrid(4, 4, 8, 0.1)

print("frames: " .. anim:getFrameCount())

-- =============================================================================
-- Clips — Named animation sequences
-- =============================================================================

anim:addClip("idle", 0, 3, 0.15, true)

anim:addClipFromGrid("walk", 0, 1, 8, 0.08, true)

print("clips: " .. anim:getClipCount())

local clip = anim:getClip("idle")
print("idle clip: " .. tostring(clip))

-- =============================================================================
-- Playback Control
-- =============================================================================

anim:play("walk")

print("playing: " .. tostring(anim:isPlaying()))

print("looping: " .. tostring(anim:isLooping()))

anim:setSpeed(1.5)

print("speed: " .. anim:getSpeed())

anim:update(1/60)

print("frame: " .. anim:getCurrentFrame())

anim:setFrame(2)

local quad = anim:getQuad()

local blend = anim:getBlendState()

local events = anim:pollEvents()
print("events: " .. #events)

anim:pause()

anim:resume()

anim:stop()

-- =============================================================================
-- Aseprite Import
-- =============================================================================

local aseprite_anim = lurek.animation.fromAseprite("assets/sprites/hero.json")
print("aseprite loaded")

-- =============================================================================
-- State Machine — Automatic transitions
-- =============================================================================

local sm = lurek.animation.newStateMachine()

sm:update(1/60)

print("state: " .. tostring(sm:getState()))

sm:forceState("idle")

local sm_quad = sm:getQuad()

-- =============================================================================
-- Animation Curves — Property interpolation
-- =============================================================================

local curve = lurek.animation.newCurve()

curve:addKeyframe(0.0, 0.0)
curve:addKeyframe(0.5, 1.0)
curve:addKeyframe(1.0, 0.0)

print("keyframes: " .. curve:keyframeCount())

print("curve at 0.25: " .. curve:eval(0.25))
print("curve at 0.75: " .. curve:eval(0.75))

curve:setEasing("inOutQuad")

curve:clear()

-- =============================================================================
-- Sync Groups — Coordinated animations
-- =============================================================================

local sync = lurek.animation.newSyncGroup()

sync:add("hero_walk")
sync:add("companion_walk")

print("sync members: " .. sync:memberCount())

sync:remove("companion_walk")

sync:clear()

-- =============================================================================
-- Blend Layer Sets — Multi-layer blending
-- =============================================================================

local layers = lurek.animation.newBlendLayerSet()

layers:setWeight("upper_body", 1.0)

print("upper weight: " .. layers:getWeight("upper_body"))

layers:setMask("upper_body", {head = true, torso = true, arms = true})

local layer_list = layers:listLayers()
print("layers: " .. #layer_list)

layers:removeLayer("upper_body")

print("blend layers: " .. layers:len())

print("\n-- animation.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- AnimStateMachine methods
-- -----------------------------------------------------------------------------

-- Sets an FSM parameter value (number, boolean, or integer supported).
animStateMachine_stub:setParam("hero", 42)
-- -----------------------------------------------------------------------------
-- Animation methods
-- -----------------------------------------------------------------------------

-- Renders the current animation frame into a new ImageData (white bg, blue frame rect).
anim:drawToImage(64.0, 64.0)  -- -> ImageData
