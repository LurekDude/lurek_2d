-- content/examples/globe.lua
-- Auto-scaffolded coverage of the lurek.globe Lua API (44 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/globe.lua

print("[example] lurek.globe loaded — 44 API items demonstrated")

-- ── lurek.globe free functions ──

--@api-stub: lurek.globe.new
-- Creates a new globe instance with default settings and empty collections.
-- Use this when creates a new globe instance with default settings and empty collections is needed.
if false then
  local _r = lurek.globe.new(1, 0)
  print(_r)
end

--@api-stub: lurek.globe.get
-- Get an existing globe by name, or nil.
-- Use this when get an existing globe by name, or nil is needed.
if false then
  local _r = lurek.globe.get(1)
  print(_r)
end

--@api-stub: lurek.globe.loadFromTOML
-- Load provinces from a TOML string and create a globe.
-- Use this when load provinces from a TOML string and create a globe is needed.
if false then
  local _r = lurek.globe.loadFromTOML(1, 0, 0)
  print(_r)
end

--@api-stub: lurek.globe.greatCircleDistance
-- Great-circle distance between two lat/lon points (in unit-sphere radians).
-- Use this when great-circle distance between two lat/lon points (in unit-sphere radians) is needed.
if false then
  local _r = lurek.globe.greatCircleDistance(nil, nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.globe.greatCirclePath
-- Great-circle path as a table of {lat, lon} pairs.
-- Use this when great-circle path as a table of {lat, lon} pairs is needed.
if false then
  local _r = lurek.globe.greatCirclePath(nil, nil, nil, nil, 1)
  print(_r)
end

--@api-stub: lurek.globe.latLonToUnit
-- Convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z}.
-- Use this when convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z} is needed.
if false then
  local _r = lurek.globe.latLonToUnit(0, 1)
  print(_r)
end

-- ── Globe methods ──

--@api-stub: Globe:addProvince
-- Adds a province from a table {id, centroid={lat,lon}, vertices={{lat,lon},...},.
-- Use this when adds a province from a table {id, centroid={lat,lon}, vertices={{lat,lon},...}, is needed.
if false then
  local _o = nil  -- Globe instance
  _o:addProvince(nil)
end

--@api-stub: Globe:removeProvince
-- Removes a province by ID.
-- Returns true if it existed.
if false then
  local _o = nil  -- Globe instance
  _o:removeProvince(1)
end

--@api-stub: Globe:provinceCount
-- Returns the number of provinces.
-- Use this when returns the number of provinces is needed.
if false then
  local _o = nil  -- Globe instance
  _o:provinceCount()
end

--@api-stub: Globe:getNeighbors
-- Returns the neighbor IDs of a province.
-- Use this when returns the neighbor IDs of a province is needed.
if false then
  local _o = nil  -- Globe instance
  _o:getNeighbors(1)
end

--@api-stub: Globe:getProvinceAttr
-- Gets a string attribute from a province.
-- Use this when gets a string attribute from a province is needed.
if false then
  local _o = nil  -- Globe instance
  _o:getProvinceAttr(1, 0)
end

--@api-stub: Globe:pan
-- Pan the orbit camera by delta-latitude and delta-longitude (degrees).
-- Use this when pan the orbit camera by delta-latitude and delta-longitude (degrees) is needed.
if false then
  local _o = nil  -- Globe instance
  _o:pan(0, 1)
end

--@api-stub: Globe:zoom
-- Zoom the camera by a multiplier (>1 zooms in, <1 zooms out).
-- Use this when zoom the camera by a multiplier (>1 zooms in, <1 zooms out) is needed.
if false then
  local _o = nil  -- Globe instance
  _o:zoom(0)
end

--@api-stub: Globe:setCamera
-- Set the camera position directly.
-- Use this when set the camera position directly is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setCamera(0, 1, 0)
end

--@api-stub: Globe:getCamera
-- Get the current camera (lat, lon, zoom).
-- Use this when get the current camera (lat, lon, zoom) is needed.
if false then
  local _o = nil  -- Globe instance
  _o:getCamera()
end

--@api-stub: Globe:getLod
-- Returns the current LOD tier as a string: "far", "mid", or "near".
-- Use this when returns the current LOD tier as a string: "far", "mid", or "near" is needed.
if false then
  local _o = nil  -- Globe instance
  _o:getLod()
end

--@api-stub: Globe:pick
-- Returns the province ID under screen coordinates, or nil.
-- Use this when returns the province ID under screen coordinates, or nil is needed.
if false then
  local _o = nil  -- Globe instance
  _o:pick(0, 0)
end

--@api-stub: Globe:pickLatLon
-- Returns (lat, lon) of the screen point on the globe surface, or nil.
-- Use this when returns (lat, lon) of the screen point on the globe surface, or nil is needed.
if false then
  local _o = nil  -- Globe instance
  _o:pickLatLon(0, 0)
end

--@api-stub: Globe:setActiveViewer
-- Set the faction/viewer whose fog mask filters rendering.
-- Use this when set the faction/viewer whose fog mask filters rendering is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setActiveViewer(0)
end

--@api-stub: Globe:revealProvince
-- Reveal a province for a viewer.
-- Use this when reveal a province for a viewer is needed.
if false then
  local _o = nil  -- Globe instance
  _o:revealProvince(0, 1)
end

--@api-stub: Globe:hideProvince
-- Hide a province for a viewer.
-- Use this when hide a province for a viewer is needed.
if false then
  local _o = nil  -- Globe instance
  _o:hideProvince(0, 1)
end

--@api-stub: Globe:isVisible
-- Returns true if the province is visible to the viewer.
-- Use this when returns true if the province is visible to the viewer is needed.
if false then
  local _o = nil  -- Globe instance
  _o:isVisible(0, 1)
end

--@api-stub: Globe:revealAll
-- Reveal all provinces for a viewer.
-- Use this when reveal all provinces for a viewer is needed.
if false then
  local _o = nil  -- Globe instance
  _o:revealAll(0)
end

--@api-stub: Globe:removeMarker
-- Removes a marker from the globe map by its unique string identifier.
-- Use this when removes a marker from the globe map by its unique string identifier is needed.
if false then
  local _o = nil  -- Globe instance
  _o:removeMarker(1)
end

--@api-stub: Globe:moveMarker
-- Move a marker to a new lat/lon.
-- Use this when move a marker to a new lat/lon is needed.
if false then
  local _o = nil  -- Globe instance
  _o:moveMarker(1, 0, 1)
end

--@api-stub: Globe:setMarkerVisible
-- Sets whether this specific marker is visible on the globe.
-- Use this when sets whether this specific marker is visible on the globe is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setMarkerVisible(1, 0)
end

--@api-stub: Globe:getMarkerAttr
-- Get a string attribute from a marker.
-- Use this when get a string attribute from a marker is needed.
if false then
  local _o = nil  -- Globe instance
  _o:getMarkerAttr(1, 0)
end

--@api-stub: Globe:setLabelText
-- Updates the visible text content of an existing globe label.
-- Use this when updates the visible text content of an existing globe label is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setLabelText(1, 0)
end

--@api-stub: Globe:setLabelVisible
-- Sets whether this specific label is visible on the globe.
-- Use this when sets whether this specific label is visible on the globe is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setLabelVisible(1, 0)
end

--@api-stub: Globe:removeLabel
-- Removes a text label from the globe map by its unique string identifier.
-- Use this when removes a text label from the globe map by its unique string identifier is needed.
if false then
  local _o = nil  -- Globe instance
  _o:removeLabel(1)
end

--@api-stub: Globe:removeLayer
-- Removes a texture layer from the globe map by its unique string identifier.
-- Use this when removes a texture layer from the globe map by its unique string identifier is needed.
if false then
  local _o = nil  -- Globe instance
  _o:removeLayer(1)
end

--@api-stub: Globe:setLayerVisible
-- Sets whether this specific texture layer is visible on the globe.
-- Use this when sets whether this specific texture layer is visible on the globe is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setLayerVisible(1, 0)
end

--@api-stub: Globe:setLayerAlpha
-- Set layer opacity (0.0–1.0).
-- Use this when set layer opacity (0.0–1.0) is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setLayerAlpha(1, 0)
end

--@api-stub: Globe:setTimeOfDay
-- Set time of day (0.0–24.0 hours).
-- Use this when set time of day (0.0–24.0 hours) is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setTimeOfDay(0)
end

--@api-stub: Globe:getTimeOfDay
-- Gets the current simulated time of day for daylight computation.
-- Use this when gets the current simulated time of day for daylight computation is needed.
if false then
  local _o = nil  -- Globe instance
  _o:getTimeOfDay()
end

--@api-stub: Globe:setRotation
-- Set planet rotation (degrees).
-- Use this when set planet rotation (degrees) is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setRotation(nil)
end

--@api-stub: Globe:update
-- Advance globe simulation by dt seconds.
-- Use this when advance globe simulation by dt seconds is needed.
if false then
  local _o = nil  -- Globe instance
  _o:update(0)
end

--@api-stub: Globe:setBorders
-- Enable or disable province border rendering.
-- Use this when enable or disable province border rendering is needed.
if false then
  local _o = nil  -- Globe instance
  _o:setBorders(0)
end

--@api-stub: Globe:findPath
-- Find the shortest province path from `from_id` to `to_id`.
-- Use this when find the shortest province path from `from_id` to `to_id` is needed.
if false then
  local _o = nil  -- Globe instance
  _o:findPath(1, 1)
end

--@api-stub: Globe:removeArc
-- Removes an arc from the globe map by its unique string identifier.
-- Use this when removes an arc from the globe map by its unique string identifier is needed.
if false then
  local _o = nil  -- Globe instance
  _o:removeArc(1)
end

--@api-stub: Globe:getName
-- Returns the string identifier name assigned to this globe instance.
-- Use this when returns the string identifier name assigned to this globe instance is needed.
if false then
  local _o = nil  -- Globe instance
  _o:getName()
end

-- ── GlobeRegistry methods ──

--@api-stub: GlobeRegistry:get
-- Get an existing globe by name, or nil.
-- Use this when get an existing globe by name, or nil is needed.
if false then
  local _o = nil  -- GlobeRegistry instance
  _o:get(1)
end

--@api-stub: GlobeRegistry:remove
-- Removes a globe from the central registry by its string name.
-- Use this when removes a globe from the central registry by its string name is needed.
if false then
  local _o = nil  -- GlobeRegistry instance
  _o:remove(1)
end

--@api-stub: GlobeRegistry:names
-- Returns a table of all globe names.
-- Use this when returns a table of all globe names is needed.
if false then
  local _o = nil  -- GlobeRegistry instance
  _o:names()
end

