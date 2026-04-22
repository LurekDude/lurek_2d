-- content/examples/globe.lua
-- Scaffolded coverage of the lurek.globe API (44 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/globe_api.rs   (Lua binding, arg types, return shape)
--   * src/globe/                 (semantics, side effects)
--   * docs/specs/globe.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/globe.lua

-- ── lurek.globe.* functions ──

--@api-stub: lurek.globe.new
-- Creates a new globe instance with default settings and empty collections.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: lurek.globe.new
  local _todo = "TODO: write a real lurek.globe.new usage example"
  print(_todo)
end

--@api-stub: lurek.globe.get
-- Get an existing globe by name, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: lurek.globe.get
  local _todo = "TODO: write a real lurek.globe.get usage example"
  print(_todo)
end

--@api-stub: lurek.globe.loadFromTOML
-- Load provinces from a TOML string and create a globe.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: lurek.globe.loadFromTOML
  local _todo = "TODO: write a real lurek.globe.loadFromTOML usage example"
  print(_todo)
end

--@api-stub: lurek.globe.greatCircleDistance
-- Great-circle distance between two lat/lon points (in unit-sphere radians).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: lurek.globe.greatCircleDistance
  local _todo = "TODO: write a real lurek.globe.greatCircleDistance usage example"
  print(_todo)
end

--@api-stub: lurek.globe.greatCirclePath
-- Great-circle path as a table of {lat, lon} pairs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: lurek.globe.greatCirclePath
  local _todo = "TODO: write a real lurek.globe.greatCirclePath usage example"
  print(_todo)
end

--@api-stub: lurek.globe.latLonToUnit
-- Convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z}.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: lurek.globe.latLonToUnit
  local _todo = "TODO: write a real lurek.globe.latLonToUnit usage example"
  print(_todo)
end

-- ── Globe methods ──

--@api-stub: Globe:addProvince
-- Adds a province from a table {id, centroid={lat,lon}, vertices={{lat,lon},...},.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:addProvince
  local _todo = "TODO: write a real Globe:addProvince usage example"
  print(_todo)
end

--@api-stub: Globe:removeProvince
-- Removes a province by ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:removeProvince
  local _todo = "TODO: write a real Globe:removeProvince usage example"
  print(_todo)
end

--@api-stub: Globe:provinceCount
-- Returns the number of provinces.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:provinceCount
  local _todo = "TODO: write a real Globe:provinceCount usage example"
  print(_todo)
end

--@api-stub: Globe:getNeighbors
-- Returns the neighbor IDs of a province.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:getNeighbors
  local _todo = "TODO: write a real Globe:getNeighbors usage example"
  print(_todo)
end

--@api-stub: Globe:getProvinceAttr
-- Gets a string attribute from a province.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:getProvinceAttr
  local _todo = "TODO: write a real Globe:getProvinceAttr usage example"
  print(_todo)
end

--@api-stub: Globe:pan
-- Pan the orbit camera by delta-latitude and delta-longitude (degrees).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:pan
  local _todo = "TODO: write a real Globe:pan usage example"
  print(_todo)
end

--@api-stub: Globe:zoom
-- Zoom the camera by a multiplier (>1 zooms in, <1 zooms out).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:zoom
  local _todo = "TODO: write a real Globe:zoom usage example"
  print(_todo)
end

--@api-stub: Globe:setCamera
-- Set the camera position directly.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setCamera
  local _todo = "TODO: write a real Globe:setCamera usage example"
  print(_todo)
end

--@api-stub: Globe:getCamera
-- Get the current camera (lat, lon, zoom).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:getCamera
  local _todo = "TODO: write a real Globe:getCamera usage example"
  print(_todo)
end

--@api-stub: Globe:getLod
-- Returns the current LOD tier as a string: "far", "mid", or "near".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:getLod
  local _todo = "TODO: write a real Globe:getLod usage example"
  print(_todo)
end

--@api-stub: Globe:pick
-- Returns the province ID under screen coordinates, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:pick
  local _todo = "TODO: write a real Globe:pick usage example"
  print(_todo)
end

--@api-stub: Globe:pickLatLon
-- Returns (lat, lon) of the screen point on the globe surface, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:pickLatLon
  local _todo = "TODO: write a real Globe:pickLatLon usage example"
  print(_todo)
end

--@api-stub: Globe:setActiveViewer
-- Set the faction/viewer whose fog mask filters rendering.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setActiveViewer
  local _todo = "TODO: write a real Globe:setActiveViewer usage example"
  print(_todo)
end

--@api-stub: Globe:revealProvince
-- Reveal a province for a viewer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:revealProvince
  local _todo = "TODO: write a real Globe:revealProvince usage example"
  print(_todo)
end

--@api-stub: Globe:hideProvince
-- Hide a province for a viewer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:hideProvince
  local _todo = "TODO: write a real Globe:hideProvince usage example"
  print(_todo)
end

--@api-stub: Globe:isVisible
-- Returns true if the province is visible to the viewer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:isVisible
  local _todo = "TODO: write a real Globe:isVisible usage example"
  print(_todo)
end

--@api-stub: Globe:revealAll
-- Reveal all provinces for a viewer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:revealAll
  local _todo = "TODO: write a real Globe:revealAll usage example"
  print(_todo)
end

--@api-stub: Globe:removeMarker
-- Removes a marker from the globe map by its unique string identifier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:removeMarker
  local _todo = "TODO: write a real Globe:removeMarker usage example"
  print(_todo)
end

--@api-stub: Globe:moveMarker
-- Move a marker to a new lat/lon.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:moveMarker
  local _todo = "TODO: write a real Globe:moveMarker usage example"
  print(_todo)
end

--@api-stub: Globe:setMarkerVisible
-- Sets whether this specific marker is visible on the globe.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setMarkerVisible
  local _todo = "TODO: write a real Globe:setMarkerVisible usage example"
  print(_todo)
end

--@api-stub: Globe:getMarkerAttr
-- Get a string attribute from a marker.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:getMarkerAttr
  local _todo = "TODO: write a real Globe:getMarkerAttr usage example"
  print(_todo)
end

--@api-stub: Globe:setLabelText
-- Updates the visible text content of an existing globe label.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setLabelText
  local _todo = "TODO: write a real Globe:setLabelText usage example"
  print(_todo)
end

--@api-stub: Globe:setLabelVisible
-- Sets whether this specific label is visible on the globe.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setLabelVisible
  local _todo = "TODO: write a real Globe:setLabelVisible usage example"
  print(_todo)
end

--@api-stub: Globe:removeLabel
-- Removes a text label from the globe map by its unique string identifier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:removeLabel
  local _todo = "TODO: write a real Globe:removeLabel usage example"
  print(_todo)
end

--@api-stub: Globe:removeLayer
-- Removes a texture layer from the globe map by its unique string identifier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:removeLayer
  local _todo = "TODO: write a real Globe:removeLayer usage example"
  print(_todo)
end

--@api-stub: Globe:setLayerVisible
-- Sets whether this specific texture layer is visible on the globe.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setLayerVisible
  local _todo = "TODO: write a real Globe:setLayerVisible usage example"
  print(_todo)
end

--@api-stub: Globe:setLayerAlpha
-- Set layer opacity (0.0–1.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setLayerAlpha
  local _todo = "TODO: write a real Globe:setLayerAlpha usage example"
  print(_todo)
end

--@api-stub: Globe:setTimeOfDay
-- Set time of day (0.0–24.0 hours).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setTimeOfDay
  local _todo = "TODO: write a real Globe:setTimeOfDay usage example"
  print(_todo)
end

--@api-stub: Globe:getTimeOfDay
-- Gets the current simulated time of day for daylight computation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:getTimeOfDay
  local _todo = "TODO: write a real Globe:getTimeOfDay usage example"
  print(_todo)
end

--@api-stub: Globe:setRotation
-- Set planet rotation (degrees).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setRotation
  local _todo = "TODO: write a real Globe:setRotation usage example"
  print(_todo)
end

--@api-stub: Globe:update
-- Advance globe simulation by dt seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:update
  local _todo = "TODO: write a real Globe:update usage example"
  print(_todo)
end

--@api-stub: Globe:setBorders
-- Enable or disable province border rendering.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:setBorders
  local _todo = "TODO: write a real Globe:setBorders usage example"
  print(_todo)
end

--@api-stub: Globe:findPath
-- Find the shortest province path from `from_id` to `to_id`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:findPath
  local _todo = "TODO: write a real Globe:findPath usage example"
  print(_todo)
end

--@api-stub: Globe:removeArc
-- Removes an arc from the globe map by its unique string identifier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:removeArc
  local _todo = "TODO: write a real Globe:removeArc usage example"
  print(_todo)
end

--@api-stub: Globe:getName
-- Returns the string identifier name assigned to this globe instance.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: Globe:getName
  local _todo = "TODO: write a real Globe:getName usage example"
  print(_todo)
end

-- ── GlobeRegistry methods ──

--@api-stub: GlobeRegistry:get
-- Get an existing globe by name, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: GlobeRegistry:get
  local _todo = "TODO: write a real GlobeRegistry:get usage example"
  print(_todo)
end

--@api-stub: GlobeRegistry:remove
-- Removes a globe from the central registry by its string name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: GlobeRegistry:remove
  local _todo = "TODO: write a real GlobeRegistry:remove usage example"
  print(_todo)
end

--@api-stub: GlobeRegistry:names
-- Returns a table of all globe names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/globe_api.rs and docs/specs/globe.md).
do  -- TODO: GlobeRegistry:names
  local _todo = "TODO: write a real GlobeRegistry:names usage example"
  print(_todo)
end

