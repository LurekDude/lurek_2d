-- lurek.parallax — scrolling background example
--
-- Demonstrates:
--   * Basic parallax layer creation and camera-driven scroll
--   * Seamless infinite tiling  (TODO 1: setTiling / setTileSize)
--   * Floating-point depth ordering  (TODO 2: setDepth)
--   * Per-layer blend mode  (TODO 3: setBlendMode / getBlendMode)
--
-- Run:  cargo run -- content/examples/parallax.lua

-- ─────────────────────────────────────────────────────────
-- Assets (replace with real paths in your project)
-- ─────────────────────────────────────────────────────────
local sky_img     = lurek.graphic.newImage("assets/sky.png")
local clouds_img  = lurek.graphic.newImage("assets/clouds.png")
local hills_img   = lurek.graphic.newImage("assets/hills.png")
local overlay_img = lurek.graphic.newImage("assets/overlay.png")

-- ─────────────────────────────────────────────────────────
-- TODO 1 — Infinite tiling
-- ─────────────────────────────────────────────────────────
-- A sky layer that tiles seamlessly in all directions as the
-- camera scrolls.  setTiling(true) is equivalent to setting
-- both repeat_x and repeat_y to true at once.
local sky = lurek.parallax.newLayer({
    texture          = sky_img,
    scroll_factor_x  = 0.1,   -- moves very slowly (far background)
    scroll_factor_y  = 0.05,
})
sky:setTiling(true)            -- enable seamless tiling on both axes
sky:setTileSize(512, 288)      -- optional: override tile size (pixels)

print("sky tiling enabled:", sky:getTiling())   -- true

-- ─────────────────────────────────────────────────────────
-- TODO 2 — Floating-point depth ordering
-- ─────────────────────────────────────────────────────────
-- Layers with lower depth values render first (further back).
-- setDepth() provides fine-grained f32 ordering alongside the
-- existing integer setZ().
local clouds = lurek.parallax.newLayer({
    texture         = clouds_img,
    scroll_factor_x = 0.3,
    scroll_factor_y = 0.0,
})
clouds:setDepth(-2.0)   -- render behind hills

local hills = lurek.parallax.newLayer({
    texture         = hills_img,
    scroll_factor_x = 0.7,
    scroll_factor_y = 0.0,
})
hills:setDepth(-1.0)    -- in front of clouds, behind overlay

print("clouds depth:", clouds:getDepth())   -- -2.0
print("hills depth:",  hills:getDepth())    -- -1.0

-- ─────────────────────────────────────────────────────────
-- TODO 3 — Per-layer blend mode
-- ─────────────────────────────────────────────────────────
-- Canonical modes: "normal" (default), "additive", "multiply",
-- "screen", "replace".  Legacy aliases "alpha" and "add" still work.
local overlay = lurek.parallax.newLayer({
    texture          = overlay_img,
    scroll_factor_x  = 1.0,
    scroll_factor_y  = 1.0,
    opacity          = 0.4,
})
overlay:setBlendMode("additive")   -- bright atmospheric glow layer
overlay:setDepth(0.0)

print("overlay blend:", overlay:getBlendMode())  -- "additive"

-- ─────────────────────────────────────────────────────────
-- Group layers into a ParallaxSet for single-call update/draw
-- ─────────────────────────────────────────────────────────
local bg = lurek.parallax.newSet("background")
bg:addLayer(sky)
bg:addLayer(clouds)
bg:addLayer(hills)
bg:addLayer(overlay)

-- ─────────────────────────────────────────────────────────
-- Game callbacks
-- ─────────────────────────────────────────────────────────
local cam_x = 0.0

lurek.process(function(dt)
    -- Pan the camera to the right over time.
    cam_x = cam_x + 80 * dt
    bg:update(dt)
end)

lurek.render(function()
    lurek.graphic.clear(0.1, 0.1, 0.2)
    bg:render(cam_x, 0.0)
end)
