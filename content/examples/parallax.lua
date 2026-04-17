-- content/examples/parallax.lua
-- Lurek2D lurek.parallax API Reference
-- Run with: cargo run -- content/examples/parallax
--
-- Scenario: A side-scrolling game with a multi-layer parallax background —
-- sky, distant mountains, near trees, and ground. Layers scroll at different
-- speeds for depth illusion, with auto-scrolling and tiling support.

print("=== lurek.parallax — Parallax Scrolling ===\n")

-- =============================================================================
-- Layer & Set Creation
-- =============================================================================

--@api-stub: lurek.parallax.newLayer
-- Create individual layers with different scroll speeds.
local sky = lurek.parallax.newLayer("assets/backgrounds/sky.png")
local mountains = lurek.parallax.newLayer("assets/backgrounds/mountains.png")
local trees = lurek.parallax.newLayer("assets/backgrounds/trees.png")
local ground = lurek.parallax.newLayer("assets/backgrounds/ground.png")

--@api-stub: lurek.parallax.newSet
-- Group layers into a parallax set for batch management.
local bg = lurek.parallax.newSet()

-- =============================================================================
-- ParallaxSet Methods
-- =============================================================================

--@api-stub: ParallaxSet:type
print("type: " .. bg:type())

--@api-stub: ParallaxSet:setName
bg:setName("forest_background")

--@api-stub: ParallaxSet:getName
print("set name: " .. bg:getName())

--@api-stub: ParallaxSet:addLayer
bg:addLayer(sky)
bg:addLayer(mountains)
bg:addLayer(trees)
bg:addLayer(ground)

--@api-stub: ParallaxSet:layerCount
print("layers: " .. bg:layerCount())

--@api-stub: ParallaxSet:sortByZ
-- Sort layers by depth (furthest to nearest).
bg:sortByZ()

--@api-stub: ParallaxSet:setVisible
bg:setVisible(true)

--@api-stub: ParallaxSet:isVisible
print("set visible: " .. tostring(bg:isVisible()))

--@api-stub: ParallaxSet:update
bg:update(1/60)

--@api-stub: ParallaxSet:render
bg:render()

--@api-stub: ParallaxSet:renderAuto
-- Render with auto-scrolling applied.
bg:renderAuto(1/60)

--@api-stub: ParallaxSet:removeLayerAt
-- bg:removeLayerAt(3)  -- remove ground layer

-- =============================================================================
-- ParallaxLayer — Scroll Factor & Position
-- =============================================================================

--@api-stub: ParallaxLayer:type
print("sky type: " .. sky:type())

--@api-stub: ParallaxLayer:setScrollFactor
-- Sky barely moves (far away), ground moves 1:1 with camera.
sky:setScrollFactor(0.1, 0.05)
mountains:setScrollFactor(0.3, 0.2)
trees:setScrollFactor(0.6, 0.4)
ground:setScrollFactor(1.0, 1.0)

--@api-stub: ParallaxLayer:getScrollFactor
local sfx, sfy = sky:getScrollFactor()
print("sky scroll factor: " .. sfx .. "," .. sfy)

--@api-stub: ParallaxLayer:setOffset
sky:setOffset(0, -50)

--@api-stub: ParallaxLayer:getOffset
local ox, oy = sky:getOffset()
print("sky offset: " .. ox .. "," .. oy)

-- =============================================================================
-- ParallaxLayer — Auto-Scrolling
-- =============================================================================

--@api-stub: ParallaxLayer:setAutoscroll
-- Auto-scroll clouds slowly to the right.
sky:setAutoscroll(10, 0)

--@api-stub: ParallaxLayer:getAutoscroll
local asx, asy = sky:getAutoscroll()
print("sky auto-scroll: " .. asx .. "," .. asy)

--@api-stub: ParallaxLayer:resetAutoscroll
sky:resetAutoscroll()

-- =============================================================================
-- ParallaxLayer — Tiling & Repeat
-- =============================================================================

--@api-stub: ParallaxLayer:setRepeat
-- Repeat horizontally for seamless scrolling.
sky:setRepeat(true, false)
mountains:setRepeat(true, false)

--@api-stub: ParallaxLayer:setTiling
sky:setTiling(true)

--@api-stub: ParallaxLayer:getTiling
print("sky tiling: " .. tostring(sky:getTiling()))

--@api-stub: ParallaxLayer:setTileSize
sky:setTileSize(800, 600)

-- =============================================================================
-- ParallaxLayer — Scale & Depth
-- =============================================================================

--@api-stub: ParallaxLayer:setScale
sky:setScale(1.0, 1.0)

--@api-stub: ParallaxLayer:setZ
sky:setZ(-100)
mountains:setZ(-50)
trees:setZ(-20)
ground:setZ(0)

--@api-stub: ParallaxLayer:getZ
print("sky Z: " .. sky:getZ())

--@api-stub: ParallaxLayer:setDepth
sky:setDepth(100)

--@api-stub: ParallaxLayer:getDepth
print("sky depth: " .. sky:getDepth())

-- =============================================================================
-- ParallaxLayer — Visual Properties
-- =============================================================================

--@api-stub: ParallaxLayer:setOpacity
-- Fog effect: distant layers are more transparent.
sky:setOpacity(0.8)
mountains:setOpacity(0.7)

--@api-stub: ParallaxLayer:getOpacity
print("sky opacity: " .. sky:getOpacity())

--@api-stub: ParallaxLayer:setTint
-- Blue tint on distant layers for atmospheric perspective.
mountains:setTint(0.7, 0.8, 1.0, 1.0)

--@api-stub: ParallaxLayer:getTint
local tr, tg, tb, ta = mountains:getTint()
print("mountain tint: " .. tr .. "," .. tg .. "," .. tb)

--@api-stub: ParallaxLayer:setBlendMode
sky:setBlendMode("alpha")

--@api-stub: ParallaxLayer:getBlendMode
print("sky blend: " .. sky:getBlendMode())

--@api-stub: ParallaxLayer:setVisible
sky:setVisible(true)

--@api-stub: ParallaxLayer:isVisible
print("sky visible: " .. tostring(sky:isVisible()))

--@api-stub: ParallaxLayer:clearClamp
sky:clearClamp()

-- =============================================================================
-- Layer Update & Render
-- =============================================================================

--@api-stub: ParallaxLayer:update
sky:update(1/60)

--@api-stub: ParallaxLayer:render
sky:render()

--@api-stub: ParallaxLayer:renderAuto
sky:renderAuto(1/60)

print("\n-- parallax.lua example complete --")
