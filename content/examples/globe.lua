-- content/examples/globe.lua
-- Practical usage examples for the lurek.globe API (44 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.globe.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/globe.lua

print("[example] lurek.globe — 44 API entries")

-- ── lurek.globe.* free functions ──

--@api-stub: lurek.globe.new
-- Creates a new globe instance with default settings and empty collections.
-- Call when you need to invoke new.
local ok, obj = pcall(function() return lurek.globe.new("name", nil) end)
if ok and obj then print("created:", obj) end
print("lurek.globe.new ok=", ok)

--@api-stub: lurek.globe.get
-- Get an existing globe by name, or nil.
-- Call when you need to invoke get.
local ok, value = pcall(function() return lurek.globe.get("name") end)
local v = ok and value or "(unavailable)"
print("lurek.globe.get ->", v)

--@api-stub: lurek.globe.loadFromTOML
-- Load provinces from a TOML string and create a globe.
-- Call when you need to load from t o m l.
local ok, obj = pcall(function() return lurek.globe.loadFromTOML("name", nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.globe.loadFromTOML ok=", ok)

--@api-stub: lurek.globe.greatCircleDistance
-- Great-circle distance between two lat/lon points (in unit-sphere radians).
-- Call when you need to invoke great circle distance.
local ok, result = pcall(function() return lurek.globe.greatCircleDistance(nil, nil, nil, nil) end)
if ok then print("lurek.globe.greatCircleDistance ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.globe.greatCirclePath
-- Great-circle path as a table of {lat, lon} pairs.
-- Call when you need to invoke great circle path.
local ok, result = pcall(function() return lurek.globe.greatCirclePath(nil, nil, nil, nil, 10) end)
if ok then print("lurek.globe.greatCirclePath ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.globe.latLonToUnit
-- Convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z}.
-- Call when you need to invoke lat lon to unit.
local ok, result = pcall(function() return lurek.globe.latLonToUnit(nil, nil) end)
if ok then print("lurek.globe.latLonToUnit ->", result)
else print("unavailable:", result) end

-- ── Globe methods ──

--@api-stub: Globe:addProvince
-- Adds a province from a table {id, centroid={lat,lon}, vertices={{lat,lon},...},.
-- Call when you need to add province.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:addProvince(nil) end)
  print("Globe:addProvince ->", ok, result)
end

--@api-stub: Globe:removeProvince
-- Removes a province by ID.
-- Returns true if it existed.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:removeProvince(1) end)
  print("Globe:removeProvince ->", ok, result)
end

--@api-stub: Globe:provinceCount
-- Returns the number of provinces.
-- Call when you need to invoke province count.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:provinceCount() end)
  print("Globe:provinceCount ->", ok, result)
end

--@api-stub: Globe:getNeighbors
-- Returns the neighbor IDs of a province.
-- Call when you need to read neighbors.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:getNeighbors(1) end)
  print("Globe:getNeighbors ->", ok, result)
end

--@api-stub: Globe:getProvinceAttr
-- Gets a string attribute from a province.
-- Call when you need to read province attr.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:getProvinceAttr(1, "key") end)
  print("Globe:getProvinceAttr ->", ok, result)
end

--@api-stub: Globe:pan
-- Pan the orbit camera by delta-latitude and delta-longitude (degrees).
-- Call when you need to invoke pan.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:pan(nil, nil) end)
  print("Globe:pan ->", ok, result)
end

--@api-stub: Globe:zoom
-- Zoom the camera by a multiplier (>1 zooms in, <1 zooms out).
-- Call when you need to invoke zoom.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:zoom(1) end)
  print("Globe:zoom ->", ok, result)
end

--@api-stub: Globe:setCamera
-- Set the camera position directly.
-- Call when you need to assign camera.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setCamera(nil, nil, 0) end)
  print("Globe:setCamera ->", ok, result)
end

--@api-stub: Globe:getCamera
-- Get the current camera (lat, lon, zoom).
-- Call when you need to read camera.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:getCamera() end)
  print("Globe:getCamera ->", ok, result)
end

--@api-stub: Globe:getLod
-- Returns the current LOD tier as a string: "far", "mid", or "near".
-- Call when you need to read lod.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:getLod() end)
  print("Globe:getLod ->", ok, result)
end

--@api-stub: Globe:pick
-- Returns the province ID under screen coordinates, or nil.
-- Call when you need to invoke pick.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:pick(nil, nil) end)
  print("Globe:pick ->", ok, result)
end

--@api-stub: Globe:pickLatLon
-- Returns (lat, lon) of the screen point on the globe surface, or nil.
-- Call when you need to invoke pick lat lon.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:pickLatLon(nil, nil) end)
  print("Globe:pickLatLon ->", ok, result)
end

--@api-stub: Globe:setActiveViewer
-- Set the faction/viewer whose fog mask filters rendering.
-- Call when you need to assign active viewer.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setActiveViewer(nil) end)
  print("Globe:setActiveViewer ->", ok, result)
end

--@api-stub: Globe:revealProvince
-- Reveal a province for a viewer.
-- Call when you need to invoke reveal province.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:revealProvince(nil, 1) end)
  print("Globe:revealProvince ->", ok, result)
end

--@api-stub: Globe:hideProvince
-- Hide a province for a viewer.
-- Call when you need to invoke hide province.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:hideProvince(nil, 1) end)
  print("Globe:hideProvince ->", ok, result)
end

--@api-stub: Globe:isVisible
-- Returns true if the province is visible to the viewer.
-- Call when you need to check is visible.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:isVisible(nil, 1) end)
  print("Globe:isVisible ->", ok, result)
end

--@api-stub: Globe:revealAll
-- Reveal all provinces for a viewer.
-- Call when you need to invoke reveal all.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:revealAll(nil) end)
  print("Globe:revealAll ->", ok, result)
end

--@api-stub: Globe:removeMarker
-- Removes a marker from the globe map by its unique string identifier.
-- Call when you need to remove marker.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:removeMarker(1) end)
  print("Globe:removeMarker ->", ok, result)
end

--@api-stub: Globe:moveMarker
-- Move a marker to a new lat/lon.
-- Call when you need to invoke move marker.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:moveMarker(1, nil, nil) end)
  print("Globe:moveMarker ->", ok, result)
end

--@api-stub: Globe:setMarkerVisible
-- Sets whether this specific marker is visible on the globe.
-- Call when you need to assign marker visible.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setMarkerVisible(1, nil) end)
  print("Globe:setMarkerVisible ->", ok, result)
end

--@api-stub: Globe:getMarkerAttr
-- Get a string attribute from a marker.
-- Call when you need to read marker attr.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:getMarkerAttr(1, "key") end)
  print("Globe:getMarkerAttr ->", ok, result)
end

--@api-stub: Globe:setLabelText
-- Updates the visible text content of an existing globe label.
-- Call when you need to assign label text.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setLabelText(1, "text value") end)
  print("Globe:setLabelText ->", ok, result)
end

--@api-stub: Globe:setLabelVisible
-- Sets whether this specific label is visible on the globe.
-- Call when you need to assign label visible.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setLabelVisible(1, nil) end)
  print("Globe:setLabelVisible ->", ok, result)
end

--@api-stub: Globe:removeLabel
-- Removes a text label from the globe map by its unique string identifier.
-- Call when you need to remove label.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:removeLabel(1) end)
  print("Globe:removeLabel ->", ok, result)
end

--@api-stub: Globe:removeLayer
-- Removes a texture layer from the globe map by its unique string identifier.
-- Call when you need to remove layer.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:removeLayer("name") end)
  print("Globe:removeLayer ->", ok, result)
end

--@api-stub: Globe:setLayerVisible
-- Sets whether this specific texture layer is visible on the globe.
-- Call when you need to assign layer visible.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setLayerVisible("name", nil) end)
  print("Globe:setLayerVisible ->", ok, result)
end

--@api-stub: Globe:setLayerAlpha
-- Set layer opacity (0.0–1.0).
-- Call when you need to assign layer alpha.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setLayerAlpha("name", 1) end)
  print("Globe:setLayerAlpha ->", ok, result)
end

--@api-stub: Globe:setTimeOfDay
-- Set time of day (0.0–24.0 hours).
-- Call when you need to assign time of day.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setTimeOfDay(nil) end)
  print("Globe:setTimeOfDay ->", ok, result)
end

--@api-stub: Globe:getTimeOfDay
-- Gets the current simulated time of day for daylight computation.
-- Call when you need to read time of day.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:getTimeOfDay() end)
  print("Globe:getTimeOfDay ->", ok, result)
end

--@api-stub: Globe:setRotation
-- Set planet rotation (degrees).
-- Call when you need to assign rotation.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setRotation(nil) end)
  print("Globe:setRotation ->", ok, result)
end

--@api-stub: Globe:update
-- Advance globe simulation by dt seconds.
-- Call when you need to invoke update.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Globe:update ->", ok, result)
end

--@api-stub: Globe:setBorders
-- Enable or disable province border rendering.
-- Call when you need to assign borders.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:setBorders(nil) end)
  print("Globe:setBorders ->", ok, result)
end

--@api-stub: Globe:findPath
-- Find the shortest province path from `from_id` to `to_id`.
-- Call when you need to invoke find path.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:findPath(1, 1) end)
  print("Globe:findPath ->", ok, result)
end

--@api-stub: Globe:removeArc
-- Removes an arc from the globe map by its unique string identifier.
-- Call when you need to remove arc.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:removeArc(1) end)
  print("Globe:removeArc ->", ok, result)
end

--@api-stub: Globe:getName
-- Returns the string identifier name assigned to this globe instance.
-- Call when you need to read name.
-- Build a Globe via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobe(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("Globe:getName ->", ok, result)
end

-- ── GlobeRegistry methods ──

--@api-stub: GlobeRegistry:get
-- Get an existing globe by name, or nil.
-- Call when you need to invoke get.
-- Build a GlobeRegistry via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobeRegistry(...)
if instance then
  local ok, result = pcall(function() return instance:get("name") end)
  print("GlobeRegistry:get ->", ok, result)
end

--@api-stub: GlobeRegistry:remove
-- Removes a globe from the central registry by its string name.
-- Call when you need to invoke remove.
-- Build a GlobeRegistry via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobeRegistry(...)
if instance then
  local ok, result = pcall(function() return instance:remove("name") end)
  print("GlobeRegistry:remove ->", ok, result)
end

--@api-stub: GlobeRegistry:names
-- Returns a table of all globe names.
-- Call when you need to invoke names.
-- Build a GlobeRegistry via the appropriate lurek.globe.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.globe.newGlobeRegistry(...)
if instance then
  local ok, result = pcall(function() return instance:names() end)
  print("GlobeRegistry:names ->", ok, result)
end

