-- content/examples/parallax.lua
-- Hand-written coverage of the lurek.parallax API (43 items).
--
-- The lurek.parallax namespace builds layered scrolling backgrounds:
-- each ParallaxLayer wraps a texture and moves at a fractional camera
-- speed; ParallaxSet groups layers and sorts them by z. Some blocks
-- below define `function lurek.draw()` callbacks which would shadow
-- the lurek.render namespace, so we capture it once into `gfx` here.
--
-- Run: cargo run -- content/examples/parallax.lua

-- ── lurek.parallax.* functions ──

--@api-stub: lurek.parallax.newLayer
-- Creates a new parallax background layer from an options table.
-- The `texture` field is mandatory; everything else has a sensible default and can be tuned later via setters.
do  -- lurek.parallax.newLayer
  function lurek.init()
    local sky_tex = lurek.render.newImage("assets/parallax/sky.png")
    local sky = lurek.parallax.newLayer({
      texture = sky_tex, scroll_factor_x = 0.15, scroll_factor_y = 0.0, z = 0,
    })
    sky:setRepeat(true, false)
  end
end

--@api-stub: lurek.parallax.newSet
-- Creates a new empty parallax set with the given name.
-- Use one set per scene so you can show/hide a whole backdrop with a single setVisible call.
do  -- lurek.parallax.newSet
  function lurek.init()
    local backdrop = lurek.parallax.newSet("forest_backdrop")
    backdrop:setVisible(true)
    lurek.log.info("backdrop ready: " .. backdrop:getName(), "scene")
  end
end

-- ── ParallaxLayer methods ──

--@api-stub: ParallaxLayer:type
-- Returns the type name of this object.
-- Useful in generic code that walks a list of mixed userdata to dispatch on shape.
do  -- ParallaxLayer:type
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png") })
    if layer:type() == "ParallaxLayer" then
      lurek.log.debug("got a parallax layer", "scene")
    end
  end
end

--@api-stub: ParallaxLayer:update
-- Advances the autonomous scroll accumulator by `dt` seconds.
-- Call once per frame in lurek.process so an autoscroll layer drifts smoothly even when the camera is still.
do  -- ParallaxLayer:update
  local clouds
  function lurek.init()
    clouds = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png"), autoscroll_x = 12 })
  end
  function lurek.process(dt) clouds:update(dt) end
end

--@api-stub: ParallaxLayer:render
-- Draws the layer using an explicit camera world position.
-- Use when you have a virtual camera (e.g. cutscene) whose position differs from the engine camera.
do  -- ParallaxLayer:render
  local hills
  function lurek.init()
    hills = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/hills.png"), scroll_factor_x = 0.4 })
  end
  function lurek.draw() hills:render(240, 0) end
end

--@api-stub: ParallaxLayer:renderAuto
-- Draws the layer using the engine active camera position automatically.
-- Preferred for normal gameplay so the layer tracks lurek.camera without you wiring coords manually.
do  -- ParallaxLayer:renderAuto
  local mountains
  function lurek.init()
    mountains = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/mountains.png"), scroll_factor_x = 0.25 })
  end
  function lurek.draw() mountains:renderAuto() end
end

--@api-stub: ParallaxLayer:resetAutoscroll
-- Resets the autonomous scroll accumulator to zero.
-- Call when changing scenes so the new screen begins drift from a known origin instead of mid-frame.
do  -- ParallaxLayer:resetAutoscroll
  function lurek.init()
    local fog = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/fog.png"), autoscroll_x = 8 })
    fog:resetAutoscroll()
  end
end

--@api-stub: ParallaxLayer:setScrollFactor
-- Sets the scroll factor relative to camera movement on each axis.
-- 0 = locked sky, 1 = locked to world; pick ~0.2 for far layers and ~0.7 for near layers.
do  -- ParallaxLayer:setScrollFactor
  function lurek.init()
    local mid = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/treeline.png") })
    mid:setScrollFactor(0.6, 1.0)
  end
end

--@api-stub: ParallaxLayer:getScrollFactor
-- Returns the scroll factor as `(x, y)`.
-- Read it back to confirm a runtime configuration tweak landed before the next render frame.
do  -- ParallaxLayer:getScrollFactor
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png"), scroll_factor_x = 0.3 })
    local fx, fy = layer:getScrollFactor()
    lurek.log.debug("scroll factor x=" .. fx .. " y=" .. fy, "parallax")
  end
end

--@api-stub: ParallaxLayer:setOffset
-- Sets the static world-pixel position bias added on top of camera scroll.
-- Use to nudge a layer down a few pixels so its horizon meets the tilemap.
do  -- ParallaxLayer:setOffset
  function lurek.init()
    local horizon = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/horizon.png") })
    horizon:setOffset(0, 96)
  end
end

--@api-stub: ParallaxLayer:getOffset
-- Returns the static offset as `(x, y)`.
-- Save it into the user's preferences so a custom horizon nudge survives between sessions.
do  -- ParallaxLayer:getOffset
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png"), offset_y = 32 })
    local ox, oy = layer:getOffset()
    lurek.log.debug("offset x=" .. ox .. " y=" .. oy, "parallax")
  end
end

--@api-stub: ParallaxLayer:setAutoscroll
-- Sets the autonomous scroll velocity in world-pixels per second.
-- Combine with setScrollFactor(0,0) for a layer that drifts independently of camera (e.g. clouds at dawn).
do  -- ParallaxLayer:setAutoscroll
  function lurek.init()
    local clouds = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png") })
    clouds:setScrollFactor(0, 0)
    clouds:setAutoscroll(20, 0)
  end
end

--@api-stub: ParallaxLayer:getAutoscroll
-- Returns the autoscroll velocity as `(vx, vy)`.
-- Useful for HUD wind-direction indicators driven off the same source data as the cloud drift.
do  -- ParallaxLayer:getAutoscroll
  function lurek.init()
    local clouds = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png"), autoscroll_x = 15 })
    local vx, vy = clouds:getAutoscroll()
    lurek.log.debug("wind vx=" .. vx .. " vy=" .. vy, "weather")
  end
end

--@api-stub: ParallaxLayer:setRepeat
-- Sets whether the layer tiles on the X and Y axes.
-- Enable X repeat for an endless side-scroller backdrop; leave Y off for fixed-height skylines.
do  -- ParallaxLayer:setRepeat
  function lurek.init()
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") })
    sky:setRepeat(true, false)
  end
end

--@api-stub: ParallaxLayer:setScale
-- Sets the texture display scale factor on each axis.
-- Use sx=2,sy=2 for chunky pixel-art backgrounds rendered at 2x logical resolution.
do  -- ParallaxLayer:setScale
  function lurek.init()
    local pixels = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/pixel_sky.png") })
    pixels:setScale(2.0, 2.0)
  end
end

--@api-stub: ParallaxLayer:setZ
-- Sets the draw-order depth.
-- Lower z draws first; pick z=0 for sky, z=10 for hills, z=20 for trees so a set sorts naturally.
do  -- ParallaxLayer:setZ
  function lurek.init()
    local trees = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/trees.png") })
    trees:setZ(20)
  end
end

--@api-stub: ParallaxLayer:getZ
-- Returns the draw-order depth.
-- Read inside a debug overlay that lists every layer in render order to verify the sort.
do  -- ParallaxLayer:getZ
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png"), z = 5 })
    if layer:getZ() < 10 then
      lurek.log.debug("background layer", "parallax")
    end
  end
end

--@api-stub: ParallaxLayer:setOpacity
-- Sets the layer-wide opacity override in `[0.0, 1.0]`.
-- Fade in over a few frames after a scene transition; set 0 to hide and skip the GPU upload.
do  -- ParallaxLayer:setOpacity
  function lurek.init()
    local fog = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/fog.png") })
    fog:setOpacity(0.6)
  end
end

--@api-stub: ParallaxLayer:getOpacity
-- Returns the current opacity.
-- Drive a tween from the current value rather than assuming 1.0 so partial fades chain smoothly.
do  -- ParallaxLayer:getOpacity
  function lurek.init()
    local fog = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/fog.png"), opacity = 0.5 })
    local a = fog:getOpacity()
    lurek.log.debug("fog opacity=" .. a, "weather")
  end
end

--@api-stub: ParallaxLayer:setTint
-- Sets the multiplicative RGBA tint applied to all pixels of this layer.
-- Tint a sky layer towards orange (1, 0.6, 0.4, 1) for sunset without re-authoring the texture.
do  -- ParallaxLayer:setTint
  function lurek.init()
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") })
    sky:setTint(1.0, 0.6, 0.4, 1.0)
  end
end

--@api-stub: ParallaxLayer:getTint
-- Returns the current tint as `(r, g, b, a)`.
-- Useful when interpolating from a previously authored colour to a new one across a day-night cycle.
do  -- ParallaxLayer:getTint
  function lurek.init()
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") })
    sky:setTint(0.5, 0.6, 1.0, 1.0)
    local r, g, b, a = sky:getTint()
    lurek.log.debug("tint=" .. r .. "," .. g .. "," .. b .. "," .. a, "parallax")
  end
end

--@api-stub: ParallaxLayer:setBlendMode
-- Sets the GPU blend mode for this layer.
-- Use "additive" for light gods-rays / glow layers; reset to "normal" for opaque backdrops.
do  -- ParallaxLayer:setBlendMode
  function lurek.init()
    local rays = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/godrays.png") })
    rays:setBlendMode("additive")
  end
end

--@api-stub: ParallaxLayer:getBlendMode
-- Returns the current blend mode as a string.
-- Compare against the saved scene mode at load time to detect whether a debug toggle left it dirty.
do  -- ParallaxLayer:getBlendMode
  function lurek.init()
    local rays = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/godrays.png"), blend_mode = "additive" })
    if rays:getBlendMode() ~= "normal" then
      lurek.log.debug("non-default blend on rays", "parallax")
    end
  end
end

--@api-stub: ParallaxLayer:setVisible
-- Shows or hides this layer.
-- Hide individual layers (e.g. weather effects) without disturbing the rest of the set's z order.
do  -- ParallaxLayer:setVisible
  function lurek.init()
    local rain = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/rain.png") })
    rain:setVisible(false)
  end
end

--@api-stub: ParallaxLayer:isVisible
-- Returns `true` if the layer is currently visible.
-- Skip an expensive per-frame update when the layer is hidden so CPU stays free for visible work.
do  -- ParallaxLayer:isVisible
  local rain
  function lurek.init()
    rain = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/rain.png") })
  end
  function lurek.process(dt)
    if rain:isVisible() then rain:update(dt) end
  end
end

--@api-stub: ParallaxLayer:clearClamp
-- Removes scroll clamping so the layer scrolls freely.
-- Call when a level transitions from a fixed-size area into an open world chunk with no horizontal bound.
do  -- ParallaxLayer:clearClamp
  function lurek.init()
    local hills = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/hills.png") })
    hills:setRepeat(true, false)
    hills:clearClamp()
  end
end

--@api-stub: ParallaxLayer:setTiling
-- Enables or disables seamless infinite tiling on both axes simultaneously.
-- Faster shortcut than two setRepeat calls when the layer is meant as an endless skybox.
do  -- ParallaxLayer:setTiling
  function lurek.init()
    local stars = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/stars.png") })
    stars:setTiling(true)
  end
end

--@api-stub: ParallaxLayer:getTiling
-- Returns `true` if seamless infinite tiling is enabled.
-- Use in a debug HUD line to confirm a level designer's tiling toggle actually took effect.
do  -- ParallaxLayer:getTiling
  function lurek.init()
    local stars = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/stars.png") })
    stars:setTiling(true)
    if stars:getTiling() then
      lurek.log.debug("starfield tiling on", "parallax")
    end
  end
end

--@api-stub: ParallaxLayer:setTileSize
-- Sets explicit tile dimensions in logical pixels, overriding the default.
-- Override when a texture is non-square or you want it tiled at a finer interval than its native size.
do  -- ParallaxLayer:setTileSize
  function lurek.init()
    local pattern = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/pattern.png") })
    pattern:setTiling(true)
    pattern:setTileSize(128, 128)
  end
end

--@api-stub: ParallaxLayer:setDepth
-- Sets the floating-point draw depth for fine-grained layer ordering.
-- Use depths like 10.5 to slip a new layer between two existing integer-z layers without resorting them.
do  -- ParallaxLayer:setDepth
  function lurek.init()
    local mist = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/mist.png") })
    mist:setZ(10)
    mist:setDepth(10.5)
  end
end

--@api-stub: ParallaxLayer:getDepth
-- Returns the current floating-point depth.
-- Pair with getZ to render a "z=10 (depth 10.50)" debug label so designers can tune layering live.
do  -- ParallaxLayer:getDepth
  function lurek.init()
    local mist = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/mist.png") })
    mist:setDepth(10.5)
    lurek.log.debug("mist depth=" .. mist:getDepth(), "parallax")
  end
end

-- ── ParallaxSet methods ──

--@api-stub: ParallaxSet:type
-- Returns the type name of this object.
-- Branch on the type name in scene-loader code that may receive either a layer or a set.
do  -- ParallaxSet:type
  function lurek.init()
    local set = lurek.parallax.newSet("intro")
    if set:type() == "ParallaxSet" then
      lurek.log.debug("got a parallax set", "scene")
    end
  end
end

--@api-stub: ParallaxSet:addLayer
-- Adds a layer to this set.
-- The set re-sorts on every add, so you can append layers in any order and they'll draw by z.
do  -- ParallaxSet:addLayer
  function lurek.init()
    local backdrop = lurek.parallax.newSet("woods")
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png"), z = 0 })
    local trees = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/trees.png"), z = 20 })
    backdrop:addLayer(sky)
    backdrop:addLayer(trees)
  end
end

--@api-stub: ParallaxSet:removeLayerAt
-- Removes the layer at the given 1-based index.
-- Use to strip a weather overlay (typically the last-added layer) when the storm ends.
do  -- ParallaxSet:removeLayerAt
  function lurek.init()
    local backdrop = lurek.parallax.newSet("storm")
    local rain = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/rain.png") })
    backdrop:addLayer(rain)
    backdrop:removeLayerAt(1)
  end
end

--@api-stub: ParallaxSet:layerCount
-- Returns the number of layers in this set.
-- Useful as a guard before calling removeLayerAt so you don't pass an out-of-range index.
do  -- ParallaxSet:layerCount
  function lurek.init()
    local backdrop = lurek.parallax.newSet("count_demo")
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") })
    backdrop:addLayer(sky)
    lurek.log.debug("layers=" .. backdrop:layerCount(), "scene")
  end
end

--@api-stub: ParallaxSet:sortByZ
-- Re-sorts all layers by ascending `z` value.
-- Call after you bulk-mutate `setZ` on several layers; addLayer already sorts on insert.
do  -- ParallaxSet:sortByZ
  function lurek.init()
    local backdrop = lurek.parallax.newSet("sortable")
    local hills = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/hills.png") })
    backdrop:addLayer(hills)
    hills:setZ(15)
    backdrop:sortByZ()
  end
end

--@api-stub: ParallaxSet:setVisible
-- Shows or hides all layers in this set.
-- Toggle off entire backdrops during a fullscreen menu so the GPU isn't drawing hidden geometry.
do  -- ParallaxSet:setVisible
  function lurek.init()
    local backdrop = lurek.parallax.newSet("menu_aware")
    backdrop:setVisible(false)
  end
end

--@api-stub: ParallaxSet:isVisible
-- Returns `true` if the set is currently visible.
-- Skip the per-frame update for an entire backdrop when it's hidden behind a menu.
do  -- ParallaxSet:isVisible
  local backdrop
  function lurek.init()
    backdrop = lurek.parallax.newSet("woods")
  end
  function lurek.process(dt)
    if backdrop:isVisible() then backdrop:update(dt) end
  end
end

--@api-stub: ParallaxSet:update
-- Advances the autoscroll accumulator of every layer by `dt` seconds.
-- One call per frame replaces calling :update on each layer individually.
do  -- ParallaxSet:update
  local backdrop
  function lurek.init()
    backdrop = lurek.parallax.newSet("ambient")
    backdrop:addLayer(lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png"), autoscroll_x = 8 }))
  end
  function lurek.process(dt) backdrop:update(dt) end
end

--@api-stub: ParallaxSet:render
-- Draws all visible layers in ascending `z` order using an explicit camera position.
-- Use when rendering into an offscreen canvas with a virtual camera (e.g. minimap preview).
do  -- ParallaxSet:render
  local backdrop
  function lurek.init()
    backdrop = lurek.parallax.newSet("preview")
    backdrop:addLayer(lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") }))
  end
  function lurek.draw() backdrop:render(0, 0) end
end

--@api-stub: ParallaxSet:renderAuto
-- Draws all visible layers using the engine active camera position.
-- The standard call from your game's render callback when the engine camera is the source of truth.
do  -- ParallaxSet:renderAuto
  local backdrop
  function lurek.init()
    backdrop = lurek.parallax.newSet("scene")
    backdrop:addLayer(lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/hills.png"), scroll_factor_x = 0.4 }))
  end
  function lurek.draw() backdrop:renderAuto() end
end

--@api-stub: ParallaxSet:getName
-- Returns the name of this set.
-- Use as a key in a scene-side table when juggling multiple backdrops (foreground / background / weather).
do  -- ParallaxSet:getName
  function lurek.init()
    local set = lurek.parallax.newSet("foreground")
    lurek.log.info("active backdrop: " .. set:getName(), "scene")
  end
end

--@api-stub: ParallaxSet:setName
-- Sets the name of this set.
-- Rename when an existing set is repurposed for a new scene so logs and debug overlays stay accurate.
do  -- ParallaxSet:setName
  function lurek.init()
    local set = lurek.parallax.newSet("placeholder")
    set:setName("level_3_backdrop")
  end
end
-- content/examples/parallax.lua
-- Scaffolded coverage of the lurek.parallax API (43 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/parallax_api.rs   (Lua binding, arg types, return shape)
--   * src/parallax/                 (semantics, side effects)
--   * docs/specs/parallax.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.draw() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/parallax.lua

-- ── lurek.parallax.* functions ──

--@api-stub: ParallaxLayer:setClamp
-- Enables edge clamping so the layer texture does not tile beyond its bounds.
-- Use for layers with defined edges (mountain silhouettes, foreground props).
do  -- ParallaxLayer:setClamp
  local ok, err = pcall(function()
    local layer = lurek.parallax.newLayer({texture = lurek.render.newImage("bg_mountains.png"), scroll_factor_x = 0.3})
    layer:setClamp(true)
    lurek.log.info("clamp enabled", "parallax")
  end)
  if not ok then lurek.log.info("clamp: asset not available", "parallax") end
end
