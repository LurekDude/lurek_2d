-- content/examples/parallax.lua
-- Lurek2D lurek.parallax API Reference
-- Run with: cargo run -- content/examples/parallax
--
Scenario: A side-scrolling game with a multi-layer parallax background —
-- sky, distant mountains, near trees, and ground. Layers scroll at different
-- speeds for depth illusion, with auto-scrolling and tiling support.

print("=== lurek.parallax — Parallax Scrolling ===\n")

-- =============================================================================
-- Layer & Set Creation
-- =============================================================================

-- Create individual layers with different scroll speeds.
local sky = lurek.parallax.newLayer("assets/backgrounds/sky.png")
local mountains = lurek.parallax.newLayer("assets/backgrounds/mountains.png")
local trees = lurek.parallax.newLayer("assets/backgrounds/trees.png")
local ground = lurek.parallax.newLayer("assets/backgrounds/ground.png")

-- Group layers into a parallax set for batch management.
local bg = lurek.parallax.newSet()

-- =============================================================================
-- ParallaxSet Methods
-- =============================================================================

print("type: " .. bg:type())

bg:setName("forest_background")

print("set name: " .. bg:getName())

bg:addLayer(sky)
bg:addLayer(mountains)
bg:addLayer(trees)
bg:addLayer(ground)

print("layers: " .. bg:layerCount())

-- Sort layers by depth (furthest to nearest).
bg:sortByZ()

bg:setVisible(true)

print("set visible: " .. tostring(bg:isVisible()))

bg:update(1/60)

bg:render()

-- Render with auto-scrolling applied.
bg:renderAuto(1/60)

bg:removeLayerAt(3)  -- remove ground layer

-- =============================================================================
-- ParallaxLayer — Scroll Factor & Position
-- =============================================================================

print("sky type: " .. sky:type())

-- Sky barely moves (far away), ground moves 1:1 with camera.
sky:setScrollFactor(0.1, 0.05)
mountains:setScrollFactor(0.3, 0.2)
trees:setScrollFactor(0.6, 0.4)
ground:setScrollFactor(1.0, 1.0)

local sfx, sfy = sky:getScrollFactor()
print("sky scroll factor: " .. sfx .. "," .. sfy)

sky:setOffset(0, -50)

local ox, oy = sky:getOffset()
print("sky offset: " .. ox .. "," .. oy)

-- =============================================================================
-- ParallaxLayer — Auto-Scrolling
-- =============================================================================

-- Auto-scroll clouds slowly to the right.
sky:setAutoscroll(10, 0)

local asx, asy = sky:getAutoscroll()
print("sky auto-scroll: " .. asx .. "," .. asy)

sky:resetAutoscroll()

-- =============================================================================
-- ParallaxLayer — Tiling & Repeat
-- =============================================================================

-- Repeat horizontally for seamless scrolling.
sky:setRepeat(true, false)
mountains:setRepeat(true, false)

sky:setTiling(true)

print("sky tiling: " .. tostring(sky:getTiling()))

sky:setTileSize(800, 600)

-- =============================================================================
-- ParallaxLayer — Scale & Depth
-- =============================================================================

sky:setScale(1.0, 1.0)

sky:setZ(-100)
mountains:setZ(-50)
trees:setZ(-20)
ground:setZ(0)

print("sky Z: " .. sky:getZ())

sky:setDepth(100)

print("sky depth: " .. sky:getDepth())

-- =============================================================================
-- ParallaxLayer — Visual Properties
-- =============================================================================

-- Fog effect: distant layers are more transparent.
sky:setOpacity(0.8)
mountains:setOpacity(0.7)

print("sky opacity: " .. sky:getOpacity())

-- Blue tint on distant layers for atmospheric perspective.
mountains:setTint(0.7, 0.8, 1.0, 1.0)

local tr, tg, tb, ta = mountains:getTint()
print("mountain tint: " .. tr .. "," .. tg .. "," .. tb)

sky:setBlendMode("alpha")

print("sky blend: " .. sky:getBlendMode())

sky:setVisible(true)

print("sky visible: " .. tostring(sky:isVisible()))

sky:clearClamp()

-- =============================================================================
-- Layer Update & Render
-- =============================================================================

sky:update(1/60)

sky:render()

sky:renderAuto(1/60)

print("\n-- parallax.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ParallaxSet methods
-- -----------------------------------------------------------------------------

-- Removes the layer at the given 1-based index.
parallaxSet_stub:removeLayerAt(1)  -- -> boolean
