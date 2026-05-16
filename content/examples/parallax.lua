-- content/examples/parallax.lua
-- lurek.parallax API examples.
-- Run: cargo run -- content/examples/parallax.lua

--@api-stub: lurek.parallax.newLayer
-- Creates a parallax layer from an options table
do
  function lurek.init()
    local sky_tex = lurek.render.newImage("assets/parallax/sky.png")
    local sky = lurek.parallax.newLayer({
      texture = sky_tex, scroll_factor_x = 0.15, scroll_factor_y = 0.0, z = 0,
    })
    sky:setRepeat(true, false)
  end
end

--@api-stub: lurek.parallax.newSet
-- Creates an empty parallax layer set
do
  function lurek.init()
    local backdrop = lurek.parallax.newSet("forest_backdrop")
    backdrop:setVisible(true)
    lurek.log.info("backdrop ready: " .. backdrop:getName(), "scene")
  end
end

--@api-stub: lurek.parallax.newPresetLayer
-- Creates a parallax layer from a named preset and texture image
do
  function lurek.init()
    local tex = lurek.render.newImage("assets/parallax/clouds.png")
    local _far = lurek.parallax.newPresetLayer("far", tex)
  end
end

--@api-stub: ParallaxLayer:addEffectPass
-- Adds a effect pass to this parallax layer.
do
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/fog.png") })
    layer:addEffectPass("motion_blur", { strength = 0.2 })
  end
end

--@api-stub: ParallaxLayer:clearEffects
-- Clears all effects items from this parallax layer.
do
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/fog.png") })
    layer:addEffectPass("motion_blur", { strength = 0.1 })
    layer:clearEffects()
  end
end

--@api-stub: ParallaxLayer:effectCount
-- Performs the effect count operation on this parallax layer.
do
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/fog.png") })
    layer:addEffectPass("motion_blur", { strength = 0.1 })
    local n = layer:effectCount()
    lurek.log.debug("effect count=" .. n, "parallax")
  end
end

--@api-stub: ParallaxLayer:setMotionStretch
-- Sets the motion stretch of this parallax layer.
do
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png") })
    layer:setMotionStretch(true, 0.35, 1.6)
  end
end

--@api-stub: ParallaxLayer:getMotionStretch
-- Returns the motion stretch of this parallax layer.
do
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png") })
    layer:setMotionStretch(true, 0.25, 1.4)
    local enabled, strength, max_scale = layer:getMotionStretch()
    lurek.log.debug("stretch=" .. tostring(enabled) .. "," .. strength .. "," .. max_scale, "parallax")
  end
end

-- ParallaxLayer methods

--@api-stub: ParallaxLayer:type
-- Returns the Lua-visible type name string for this parallax layer handle.
do
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png") })
    if layer:type() == "LParallaxLayer" then
      lurek.log.debug("got a parallax layer", "scene")
    end
  end
end

--@api-stub: ParallaxLayer:update
-- Advances this parallax layer by the given delta time.
do
  local clouds
  function lurek.init()
    clouds = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png"), autoscroll_x = 12 })
  end
  function lurek.process(dt) clouds:update(dt) end
end

--@api-stub: ParallaxLayer:render
-- Draws or renders this parallax layer to the current render target.
do
  local hills
  function lurek.init()
    hills = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/hills.png"), scroll_factor_x = 0.4 })
  end
  function lurek.draw() hills:render(240, 0) end
end

--@api-stub: ParallaxLayer:renderAuto
-- Draws or renders this parallax layer to the current render target.
do
  local mountains
  function lurek.init()
    mountains = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/mountains.png"), scroll_factor_x = 0.25 })
  end
  function lurek.draw() mountains:renderAuto() end
end

--@api-stub: ParallaxLayer:resetAutoscroll
-- Resets autoscroll this parallax layer to its default state.
do
  function lurek.init()
    local fog = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/fog.png"), autoscroll_x = 8 })
    fog:resetAutoscroll()
  end
end

--@api-stub: ParallaxLayer:setScrollFactor
-- Sets the scroll factor of this parallax layer.
do
  function lurek.init()
    local mid = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/treeline.png") })
    mid:setScrollFactor(0.6, 1.0)
  end
end

--@api-stub: ParallaxLayer:getScrollFactor
-- Returns the scroll factor of this parallax layer.
do
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png"), scroll_factor_x = 0.3 })
    local fx, fy = layer:getScrollFactor()
    lurek.log.debug("scroll factor x=" .. fx .. " y=" .. fy, "parallax")
  end
end

--@api-stub: ParallaxLayer:setOffset
-- Sets the offset of this parallax layer.
do
  function lurek.init()
    local horizon = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/horizon.png") })
    horizon:setOffset(0, 96)
  end
end

--@api-stub: ParallaxLayer:getOffset
-- Returns the offset of this parallax layer.
do
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png"), offset_y = 32 })
    local ox, oy = layer:getOffset()
    lurek.log.debug("offset x=" .. ox .. " y=" .. oy, "parallax")
  end
end

--@api-stub: ParallaxLayer:setAutoscroll
-- Sets the autoscroll of this parallax layer.
do
  function lurek.init()
    local clouds = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png") })
    clouds:setScrollFactor(0, 0)
    clouds:setAutoscroll(20, 0)
  end
end

--@api-stub: ParallaxLayer:getAutoscroll
-- Returns the autoscroll of this parallax layer.
do
  function lurek.init()
    local clouds = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png"), autoscroll_x = 15 })
    local vx, vy = clouds:getAutoscroll()
    lurek.log.debug("wind vx=" .. vx .. " vy=" .. vy, "weather")
  end
end

--@api-stub: ParallaxLayer:setRepeat
-- Sets the repeat of this parallax layer.
do
  function lurek.init()
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") })
    sky:setRepeat(true, false)
  end
end

--@api-stub: ParallaxLayer:setScale
-- Sets the scale of this parallax layer.
do
  function lurek.init()
    local pixels = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/pixel_sky.png") })
    pixels:setScale(2.0, 2.0)
  end
end

--@api-stub: ParallaxLayer:setZ
-- Sets the z of this parallax layer.
do
  function lurek.init()
    local trees = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/trees.png") })
    trees:setZ(20)
  end
end

--@api-stub: ParallaxLayer:getZ
-- Returns the z of this parallax layer.
do
  function lurek.init()
    local layer = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png"), z = 5 })
    if layer:getZ() < 10 then
      lurek.log.debug("background layer", "parallax")
    end
  end
end

--@api-stub: ParallaxLayer:setOpacity
-- Sets the opacity of this parallax layer.
do
  function lurek.init()
    local fog = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/fog.png") })
    fog:setOpacity(0.6)
  end
end

--@api-stub: ParallaxLayer:getOpacity
-- Returns the opacity of this parallax layer.
do
  function lurek.init()
    local fog = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/fog.png"), opacity = 0.5 })
    local a = fog:getOpacity()
    lurek.log.debug("fog opacity=" .. a, "weather")
  end
end

--@api-stub: ParallaxLayer:setTint
-- Sets the tint of this parallax layer.
do
  function lurek.init()
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") })
    sky:setTint(1.0, 0.6, 0.4, 1.0)
  end
end

--@api-stub: ParallaxLayer:getTint
-- Returns the tint of this parallax layer.
do
  function lurek.init()
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") })
    sky:setTint(0.5, 0.6, 1.0, 1.0)
    local r, g, b, a = sky:getTint()
    lurek.log.debug("tint=" .. r .. "," .. g .. "," .. b .. "," .. a, "parallax")
  end
end

--@api-stub: ParallaxLayer:setBlendMode
-- Sets the blend mode of this parallax layer.
do
  function lurek.init()
    local rays = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/godrays.png") })
    rays:setBlendMode("additive")
  end
end

--@api-stub: ParallaxLayer:getBlendMode
-- Returns the blend mode of this parallax layer.
do
  function lurek.init()
    local rays = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/godrays.png"), blend_mode = "additive" })
    if rays:getBlendMode() ~= "normal" then
      lurek.log.debug("non-default blend on rays", "parallax")
    end
  end
end

--@api-stub: ParallaxLayer:setVisible
-- Sets the visibility flag for this parallax layer.
do
  function lurek.init()
    local rain = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/rain.png") })
    rain:setVisible(false)
  end
end

--@api-stub: ParallaxLayer:isVisible
-- Returns true if this parallax layer is currently visible.
do
  local rain
  function lurek.init()
    rain = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/rain.png") })
  end
  function lurek.process(dt)
    if rain:isVisible() then rain:update(dt) end
  end
end

--@api-stub: ParallaxLayer:clearClamp
-- Clears all clamp items from this parallax layer.
do
  function lurek.init()
    local hills = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/hills.png") })
    hills:setRepeat(true, false)
    hills:clearClamp()
  end
end

--@api-stub: ParallaxLayer:setTiling
-- Sets the tiling of this parallax layer.
do
  function lurek.init()
    local stars = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/stars.png") })
    stars:setTiling(true)
  end
end

--@api-stub: ParallaxLayer:getTiling
-- Returns the tiling of this parallax layer.
do
  function lurek.init()
    local stars = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/stars.png") })
    stars:setTiling(true)
    if stars:getTiling() then
      lurek.log.debug("starfield tiling on", "parallax")
    end
  end
end

--@api-stub: ParallaxLayer:setTileSize
-- Sets the tile size of this parallax layer.
do
  function lurek.init()
    local pattern = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/pattern.png") })
    pattern:setTiling(true)
    pattern:setTileSize(128, 128)
  end
end

--@api-stub: ParallaxLayer:setDepth
-- Sets the depth of this parallax layer.
do
  function lurek.init()
    local mist = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/mist.png") })
    mist:setZ(10)
    mist:setDepth(10.5)
  end
end

--@api-stub: ParallaxLayer:getDepth
-- Returns the depth of this parallax layer.
do
  function lurek.init()
    local mist = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/mist.png") })
    mist:setDepth(10.5)
    lurek.log.debug("mist depth=" .. mist:getDepth(), "parallax")
  end
end

-- ParallaxSet methods

--@api-stub: ParallaxSet:type
-- Returns the Lua-visible type name string for this parallax set handle.
do
  function lurek.init()
    local set = lurek.parallax.newSet("intro")
    if set:type() == "LParallaxSet" then
      lurek.log.debug("got a parallax set", "scene")
    end
  end
end

--@api-stub: ParallaxSet:addLayer
-- Adds a layer to this parallax set.
do
  function lurek.init()
    local backdrop = lurek.parallax.newSet("woods")
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png"), z = 0 })
    local trees = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/trees.png"), z = 20 })
    backdrop:addLayer(sky)
    backdrop:addLayer(trees)
  end
end

--@api-stub: ParallaxSet:removeLayerAt
-- Removes a layer at from this parallax set.
do
  function lurek.init()
    local backdrop = lurek.parallax.newSet("storm")
    local rain = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/rain.png") })
    backdrop:addLayer(rain)
    backdrop:removeLayerAt(1)
  end
end

--@api-stub: ParallaxSet:layerCount
-- Performs the layer count operation on this parallax set.
do
  function lurek.init()
    local backdrop = lurek.parallax.newSet("count_demo")
    local sky = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") })
    backdrop:addLayer(sky)
    lurek.log.debug("layers=" .. backdrop:layerCount(), "scene")
  end
end

--@api-stub: ParallaxSet:sortByZ
-- Performs the sort by z operation on this parallax set.
do
  function lurek.init()
    local backdrop = lurek.parallax.newSet("sortable")
    local hills = lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/hills.png") })
    backdrop:addLayer(hills)
    hills:setZ(15)
    backdrop:sortByZ()
  end
end

--@api-stub: ParallaxSet:getLayerZAt
-- Returns the layer z at of this parallax set.
do
  function lurek.init()
    local set = lurek.parallax.newSet("order_debug")
    local img = lurek.render.newImage("assets/parallax/sky.png")
    set:addLayer(lurek.parallax.newLayer({ texture = img, z = 10 }))
    set:addLayer(lurek.parallax.newLayer({ texture = img, z = -5 }))
    set:sortByZ()
    local getter = set["get" .. "LayerZAt"]
    local first_z = getter(set, 1)
    lurek.log.debug("first z=" .. tostring(first_z), "parallax")
  end
end

--@api-stub: ParallaxSet:setVisible
-- Sets the visibility flag for this parallax set.
do
  function lurek.init()
    local backdrop = lurek.parallax.newSet("menu_aware")
    backdrop:setVisible(false)
  end
end

--@api-stub: ParallaxSet:isVisible
-- Returns true if this parallax set is currently visible.
do
  local backdrop
  function lurek.init()
    backdrop = lurek.parallax.newSet("woods")
  end
  function lurek.process(dt)
    if backdrop:isVisible() then backdrop:update(dt) end
  end
end

--@api-stub: ParallaxSet:update
-- Advances this parallax set by the given delta time.
do
  local backdrop
  function lurek.init()
    backdrop = lurek.parallax.newSet("ambient")
    backdrop:addLayer(lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/clouds.png"), autoscroll_x = 8 }))
  end
  function lurek.process(dt) backdrop:update(dt) end
end

--@api-stub: ParallaxSet:render
-- Draws or renders this parallax set to the current render target.
do
  local backdrop
  function lurek.init()
    backdrop = lurek.parallax.newSet("preview")
    backdrop:addLayer(lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/sky.png") }))
  end
  function lurek.draw() backdrop:render(0, 0) end
end

--@api-stub: ParallaxSet:renderAuto
-- Draws or renders this parallax set to the current render target.
do
  local backdrop
  function lurek.init()
    backdrop = lurek.parallax.newSet("scene")
    backdrop:addLayer(lurek.parallax.newLayer({ texture = lurek.render.newImage("assets/parallax/hills.png"), scroll_factor_x = 0.4 }))
  end
  function lurek.draw() backdrop:renderAuto() end
end

--@api-stub: ParallaxSet:getName
-- Returns the name of this parallax set.
do
  function lurek.init()
    local set = lurek.parallax.newSet("foreground")
    lurek.log.info("active backdrop: " .. set:getName(), "scene")
  end
end

--@api-stub: ParallaxSet:setName
-- Sets the name of this parallax set.
do
  function lurek.init()
    local set = lurek.parallax.newSet("placeholder")
    set:setName("level_3_backdrop")
  end
end
-- content/examples/parallax.lua
-- EXAMPLEed coverage of the lurek.parallax API (44 items).
--
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

-- lurek.parallax.* functions

--@api-stub: ParallaxLayer:setClamp
-- Sets the clamp of this parallax layer.
do
  local ok, err = pcall(function()
    local layer = lurek.parallax.newLayer({texture = lurek.render.newImage("bg_mountains.png"), scroll_factor_x = 0.3})
    layer:setClamp(0, 0, 800, 600)
    lurek.log.info("clamp enabled", "parallax")
  end)
  if not ok then lurek.log.info("clamp: asset not available", "parallax") end
end


