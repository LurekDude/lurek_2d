-- content/examples/globe.lua
-- lurek.globe API examples.
-- Run: cargo run -- content/examples/globe.lua

--@api-stub: lurek.globe.new
-- Creates a named globe with optional specification fields in the module registry
do
  local g = lurek.globe.new("earth_demo", { radius = 1.0, axial_tilt_deg = 23.5 })
  g:setBorders(true)
  lurek.log.info("created globe " .. g:getName(), "globe")
end

--@api-stub: lurek.globe.get
-- Returns a globe from the module registry by name
do
  lurek.globe.new("campaign", {})
  local g = lurek.globe.get("campaign")
  if g then lurek.log.info("found globe " .. g:getName(), "globe") end
end

--@api-stub: lurek.globe.loadFromTOML
-- Creates a globe and populates provinces from TOML source text
do
  local toml_src = [=[
  [[provinces]]
  id = 1
  centroid = [10.0, 20.0]
  vertices = [[5.0,15.0],[15.0,15.0],[15.0,25.0],[5.0,25.0]]
  ]=]
  local g = lurek.globe.loadFromTOML("loaded", toml_src, {})
  lurek.log.info("loaded provinces=" .. g:provinceCount(), "globe")
end

--@api-stub: lurek.globe.greatCircleDistance
-- Computes great-circle distance between two latitude-longitude points
do
  local rad = lurek.globe.greatCircleDistance(40.7, -74.0, 51.5, -0.1)
  local km = rad * 6371.0
  lurek.log.info(string.format("NYC->London = %.0f km", km), "globe")
end

--@api-stub: lurek.globe.greatCirclePath
-- Computes sampled latitude-longitude points along a great-circle path
do
  local pts = lurek.globe.greatCirclePath(0.0, 0.0, 0.0, 90.0, 8)
  for i, p in ipairs(pts) do
    lurek.log.debug(string.format("step %d: lat=%.1f lon=%.1f", i, p[1], p[2]), "globe")
  end
end

--@api-stub: lurek.globe.latLonToUnit
-- Converts latitude and longitude to a unit-sphere 3D vector table
do
  local v = lurek.globe.latLonToUnit(45.0, 90.0)
  local mag = math.sqrt(v[1]*v[1] + v[2]*v[2] + v[3]*v[3])
  lurek.log.info(string.format("unit vec |v|=%.3f", mag), "globe")
end

-- Globe methods

--@api-stub: Globe:addProvince
-- Adds a province to this globe.
do
  local g = lurek.globe.new("addprov", {})
  g:addProvince({
    id = 7, centroid = {30.0, 40.0},
    vertices = {{25.0,35.0},{35.0,35.0},{35.0,45.0},{25.0,45.0}},
    neighbors = {}, base_color = {0.2, 0.6, 0.3, 1.0},
  })
end

--@api-stub: Globe:removeProvince
-- Removes a province from this globe.
do
  local g = lurek.globe.new("rmprov", {})
  g:addProvince({ id = 9, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  local existed = g:removeProvince(9)
  lurek.log.info("removed=" .. tostring(existed) .. " count=" .. g:provinceCount(), "globe")
end

--@api-stub: Globe:provinceCount
-- Performs the province count operation on this globe.
do
  local g = lurek.globe.new("count_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {5,5}, vertices = {{4,4},{6,4},{6,6}} })
  lurek.log.info("provinces=" .. g:provinceCount(), "globe")
end

--@api-stub: Globe:getNeighbors
-- Returns the neighbors of this globe.
do
  local g = lurek.globe.new("neigh_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2, 3} })
  local nbrs = g:getNeighbors(1)
  lurek.log.info("province 1 has " .. #nbrs .. " neighbors", "globe")
end

--@api-stub: Globe:getProvinceAttr
-- Returns the province attr of this globe.
do
  local g = lurek.globe.new("attr_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setProvinceAttr(1, "owner", "blue_faction")
  local owner = g:getProvinceAttr(1, "owner") or "neutral"
  lurek.log.info("province 1 owner=" .. owner, "globe")
end

--@api-stub: Globe:pan
-- Performs the pan operation on this globe.
do
  local g = lurek.globe.new("pan_demo", {})
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("a") then g:pan(0, -45.0 * dt) end
    if lurek.input.keyboard.isDown("d") then g:pan(0,  45.0 * dt) end
  end
end

--@api-stub: Globe:zoom
-- Performs the zoom operation on this globe.
do
  local g = lurek.globe.new("zoom_demo", {})
  function lurek.process(dt)
    local _, wheel = lurek.input.mouse.getWheelDelta()
    if wheel ~= 0 then g:zoom(1.0 + wheel * 0.1) end
  end
end

--@api-stub: Globe:setCamera
-- Sets the camera of this globe.
do
  local g = lurek.globe.new("setcam_demo", {})
  g:setCamera(48.85, 2.35, 3.0)  -- centred on Paris, zoomed in
  local lat, lon, z = g:getCamera()
  lurek.log.info(string.format("camera lat=%.2f lon=%.2f zoom=%.1f", lat, lon, z), "globe")
end

--@api-stub: Globe:getCamera
-- Returns the camera of this globe.
do
  local g = lurek.globe.new("getcam_demo", {})
  g:setCamera(0.0, 0.0, 1.5)
  local lat, lon, z = g:getCamera()
  lurek.filesystem.write("save/globe_camera.txt", string.format("%.3f,%.3f,%.3f", lat, lon, z))
end

--@api-stub: Globe:getLod
-- Returns the lod of this globe.
do
  local g = lurek.globe.new("lod_demo", {})
  g:setCamera(0, 0, 5.0)
  local tier = g:getLod()
  if tier == "near" then lurek.log.info("show city sprites", "globe") end
end

--@api-stub: Globe:pick
-- Performs the pick operation on this globe.
do
  local g = lurek.globe.new("pick_demo", {})
  function lurek.input_pressed(key)
    local mx, my = lurek.input.mouse.getPosition()
    mx, my = mx or 0, my or 0
    local id = g:pick(mx, my)
    if id then lurek.log.info("clicked province " .. id, "globe") end
  end
end

--@api-stub: Globe:pickLatLon
-- Performs the pick lat lon operation on this globe.
do
  local g = lurek.globe.new("picklatlon_demo", {})
  function lurek.input_pressed(key)
    local mx, my = lurek.input.mouse.getPosition()
    mx, my = mx or 0, my or 0
    local lat, lon = g:pickLatLon(mx, my)
    if lat and lon then g:addMarker("waypoint", lat, lon, "click") end
  end
end

--@api-stub: Globe:setActiveViewer
-- Sets the active viewer of this globe.
do
  local g = lurek.globe.new("viewer_demo", {})
  g:setActiveViewer("blue_faction")
  g:revealAll("blue_faction")
  lurek.log.info("active viewer set", "globe")
end

--@api-stub: Globe:revealProvince
-- Performs the reveal province operation on this globe.
do
  local g = lurek.globe.new("reveal_demo", {})
  g:addProvince({ id = 12, centroid = {10,10}, vertices = {{9,9},{11,9},{11,11}} })
  g:revealProvince("blue_faction", 12)
  lurek.log.info("province 12 revealed for blue", "globe")
end

--@api-stub: Globe:hideProvince
-- Performs the hide province operation on this globe.
do
  local g = lurek.globe.new("hide_demo", {})
  g:addProvince({ id = 5, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:revealProvince("blue", 5)
  g:hideProvince("blue", 5)
  lurek.log.info("province 5 re-fogged for blue", "globe")
end

--@api-stub: Globe:isVisible
-- Returns true if this globe is currently visible.
do
  local g = lurek.globe.new("vis_demo", {})
  g:addProvince({ id = 3, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:revealProvince("blue", 3)
  if g:isVisible("blue", 3) then lurek.log.info("province 3 visible to blue", "globe") end
end

--@api-stub: Globe:revealAll
-- Performs the reveal all operation on this globe.
do
  local g = lurek.globe.new("revealall_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {5,5}, vertices = {{4,4},{6,4},{6,6}} })
  g:revealAll("debug_viewer")
  lurek.log.info("all provinces revealed for debug_viewer", "globe")
end

--@api-stub: lurek.globe.loadFromPNG
-- Creates a globe and populates provinces from a PNG file
do
  local ok, g = pcall(function()
    return lurek.globe.loadFromPNG("png_demo", "assets/textures/nonexistent.png", {})
  end)
  if ok and g then lurek.log.debug("png globe loaded", "globe") end
end

--@api-stub: lurek.globe.generateVoronoi
-- Creates a globe and populates provinces from latitude-longitude seed points
do
  local g = lurek.globe.generateVoronoi("voronoi_demo", {
    {0.0, 0.0}, {10.0, 20.0}, {-20.0, 30.0},
  }, {})
  lurek.log.info("voronoi provinces=" .. g:provinceCount(), "globe")
end

--@api-stub: Globe:setProvinceTexture
-- Sets the province texture of this globe.
do
  local g = lurek.globe.new("tex_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setProvinceTexture(1, 0, 0.0, 0.0, 1.0, 1.0)
end

--@api-stub: Globe:clearProvinceTexture
-- Clears all province texture items from this globe.
do
  local g = lurek.globe.new("cleartex_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:clearProvinceTexture(1)
end

--@api-stub: LGlobe:setProvinceSector
-- Sets the sector name for a province and enables sector-based grouping on this globe.
do
  local g = lurek.globe.new("sector_demo", {})
  g:addProvince({ id = 2, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setProvinceSector(2, "north")
  local _ = g:getProvinceSector(2)
  local _ids = g:getSectorProvinces("north")
end

--@api-stub: LGlobe:setHeatLayer
-- Sets a named heat layer with min, max, and opacity on this globe for province data visualization.
do
  local g = lurek.globe.new("heat_demo", {})
  g:setHeatLayer("population", "pop", 0.0, 100.0, 0.5)
  g:removeHeatLayer("population")
end

--@api-stub: LGlobe:setFogState
-- Sets the fog-of-war exploration state for a province on this globe.
do
  local g = lurek.globe.new("fogx_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setFogState("p1", 1, "explored")
  local _state = g:getFogState("p1", 1)
  local data = g:encodeFogBase64("p1")
  g:decodeFogBase64("p1", data)
end

--@api-stub: LGlobe:setMarkerPulse
-- Sets the pulse animation speed and scale factor for a placed marker on this globe.
do
  local g = lurek.globe.new("marker_anim_demo", {})
  local id = g:addMarker("poi", 10.0, 10.0, "A")
  g:setMarkerPulse(id, 2.0, 0.2)
  g:setMarkerRotation(id, 120.0)
end

--@api-stub: LGlobe:setAutoRotationSpeed
-- Sets the automatic rotation speed in radians per second for this globe.
do
  local g = lurek.globe.new("autorot_demo", {})
  g:setAutoRotationSpeed(0.02)
end

--@api-stub: LGlobe:cacheReachability
-- Pre-computes and caches province reachability from a start province within a max cost budget.
do
  local g = lurek.globe.new("reach_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2} })
  g:addProvince({ id = 2, centroid = {2,2}, vertices = {{2,2},{3,2},{3,3}}, neighbors = {1} })
  g:cacheReachability("blue", 1, 5.0)
  local _map = g:getCachedReachability("blue")
end

--@api-stub: Globe:pickRaycast
-- Performs the pick raycast operation on this globe.
do
  local g = lurek.globe.new("raypick_demo", {})
  local _ = g:pickRaycast(640, 360, 16)
end

--@api-stub: Globe:exportProvinceMeshOBJ
-- Performs the export province mesh obj operation on this globe.
do
  local g = lurek.globe.new("obj_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  local obj = g:exportProvinceMeshOBJ()
  lurek.filesystem.write("save/globe_mesh.obj", obj)
end
--@api-stub: Globe:removeMarker
-- Removes a marker from this globe.
do
  local g = lurek.globe.new("rmmark_demo", {})
  local id = g:addMarker("ufo", 30.0, -60.0, "Bogey-1")
  local ok = g:removeMarker(id)
  lurek.log.info("removed marker " .. id .. " ok=" .. tostring(ok), "globe")
end

--@api-stub: Globe:moveMarker
-- Performs the move marker operation on this globe.
do
  local g = lurek.globe.new("movemark_demo", {})
  local id = g:addMarker("ship", 0.0, 0.0, "USS Hope")
  function lurek.process(dt)
    g:moveMarker(id, 0.0, (lurek.time.getTime() * 5.0) % 360.0)
  end
end

--@api-stub: Globe:setMarkerVisible
-- Sets the visibility flag for this globe.
do
  local g = lurek.globe.new("markvis_demo", {})
  local id = g:addMarker("base", 51.5, -0.1, "HQ")
  g:setMarkerVisible(id, false)
  lurek.log.info("HQ marker hidden during cutscene", "globe")
end

--@api-stub: Globe:getMarkerAttr
-- Returns the marker attr of this globe.
do
  local g = lurek.globe.new("markattr_demo", {})
  local id = g:addMarker("squad", 0.0, 0.0, "Alpha")
  g:setMarkerAttr(id, "fuel", "85")
  local fuel = g:getMarkerAttr(id, "fuel") or "0"
  lurek.log.info("squad fuel=" .. fuel, "globe")
end

--@api-stub: Globe:setLabelText
-- Sets the label text of this globe.
do
  local g = lurek.globe.new("labeltxt_demo", {})
  local id = g:addLabel("city", 51.5, -0.1, "London")
  g:setLabelText(id, "New London")
  lurek.log.info("relabelled city " .. id, "globe")
end

--@api-stub: Globe:setLabelVisible
-- Sets the visibility flag for this globe.
do
  local g = lurek.globe.new("labelvis_demo", {})
  local id = g:addLabel("city", 0.0, 0.0, "Origin")
  g:setLabelVisible(id, g:getLod() ~= "far")
  lurek.log.info("label visible based on LOD", "globe")
end

--@api-stub: Globe:removeLabel
-- Removes a label from this globe.
do
  local g = lurek.globe.new("rmlabel_demo", {})
  local id = g:addLabel("city", 0, 0, "Atlantis")
  local ok = g:removeLabel(id)
  lurek.log.info("removed label " .. id .. " ok=" .. tostring(ok), "globe")
end

--@api-stub: Globe:removeLayer
-- Removes a layer from this globe.
do
  local g = lurek.globe.new("rmlayer_demo", {})
  g:addLayer("weather", 5)
  local ok = g:removeLayer("weather")
  lurek.log.info("removed weather layer ok=" .. tostring(ok), "globe")
end

--@api-stub: Globe:setLayerVisible
-- Sets the visibility flag for this globe.
do
  local g = lurek.globe.new("layervis_demo", {})
  g:addLayer("politics", 1)
  g:setLayerVisible("politics", false)
  lurek.log.info("politics overlay hidden", "globe")
end

--@api-stub: Globe:setLayerAlpha
-- Sets the layer alpha of this globe.
do
  local g = lurek.globe.new("layeralpha_demo", {})
  g:addLayer("heat", 2)
  function lurek.process(dt)
    local a = (math.sin(lurek.time.getTime()) * 0.5 + 0.5)
    g:setLayerAlpha("heat", a)
  end
end

--@api-stub: Globe:setTimeOfDay
-- Sets the time of day of this globe.
do
  local g = lurek.globe.new("tod_demo", {})
  function lurek.process(dt)
    local hours = (lurek.time.getTime() * 0.5) % 24.0
    g:setTimeOfDay(hours)
  end
end

--@api-stub: Globe:getTimeOfDay
-- Returns the time of day of this globe.
do
  local g = lurek.globe.new("getsod_demo", {})
  g:setTimeOfDay(20.0)
  local t = g:getTimeOfDay()
  if t < 6.0 or t > 18.0 then lurek.log.info("nocturnal spawn window open", "globe") end
end

--@api-stub: Globe:setRotation
-- Sets the rotation of this globe.
do
  local g = lurek.globe.new("rot_demo", {})
  function lurek.process(dt)
    g:setRotation((lurek.time.getTime() * 6.0) % 360.0)
  end
end

--@api-stub: Globe:update
-- Advances this globe by the given delta time.
do
  local g = lurek.globe.new("update_demo", {})
  function lurek.process(dt)
    g:update(dt)
  end
end

--@api-stub: Globe:setBorders
-- Sets the borders of this globe.
do
  local g = lurek.globe.new("border_demo", {})
  g:setBorders(true)
  if g:getLod() == "near" then g:setBorders(false) end
  lurek.log.info("borders configured for LOD " .. g:getLod(), "globe")
end

--@api-stub: Globe:findPath
-- Finds and returns the path in this globe by name or id.
do
  local g = lurek.globe.new("path_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2} })
  g:addProvince({ id = 2, centroid = {1,1}, vertices = {{1,0},{2,0},{2,1}}, neighbors = {1} })
  local path = g:findPath(1, 2)
  if path then lurek.log.info("path length=" .. #path, "globe") end
end

--@api-stub: Globe:removeArc
-- Removes a arc from this globe.
do
  local g = lurek.globe.new("rmarc_demo", {})
  local id = g:addArc(0.0, 0.0, 45.0, 90.0, 24)
  g:removeArc(id)
  lurek.log.info("arc " .. id .. " cleared", "globe")
end

--@api-stub: Globe:getName
-- Returns the name of this globe.
do
  local g = lurek.globe.new("primary_world", {})
  local name = g:getName()
  lurek.filesystem.write("save/active_globe.txt", name)
  lurek.log.info("active globe = " .. name, "globe")
end

-- GlobeRegistry methods

--@api-stub: GlobeRegistry:get
-- Returns the  of this globe registry.
do
  lurek.globe.new("alt_world", {})
  local g = lurek.globe.get("alt_world")
  if g then lurek.log.info("registry returned " .. g:getName(), "globe") end
end

--@api-stub: GlobeRegistry:remove
-- Removes a  from this globe registry.
do
  lurek.globe.new("temp_world", {})
  local g = lurek.globe.get("temp_world")
  if g then lurek.log.info("about to drop " .. g:getName(), "globe") end
  -- registry drop happens at engine shutdown when no Lua handle remains
end

--@api-stub: GlobeRegistry:names
-- Performs the names operation on this globe registry.
do
  lurek.globe.new("world_a", {})
  lurek.globe.new("world_b", {})
  local g = lurek.globe.get("world_a")
  if g then lurek.log.info("first registered = " .. g:getName(), "globe") end
end


--@api-stub: Globe:addArc
-- Adds a arc to this globe.
do
  local g = lurek.globe.new("arc_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {5,5}, vertices = {{4,4},{6,4},{6,6}} })
  local arcId = g:addArc(0, 0, 5, 5, 16)
  lurek.log.info("arc id: " .. arcId, "globe")
end

local function sampleProvince(id, lat, lon, opts)
  opts = opts or {}
  return {
    id = id,
    centroid = {lat, lon},
    vertices = {{lat, lon}, {lat + 1, lon}, {lat + 1, lon + 1}},
    neighbors = opts.neighbors or {},
    base_color = opts.base_color or {0.5, 0.6, 0.7, 1.0},
  }
end

--@api-stub: Globe:addLabel
-- Adds a label to this globe.
do
  local g = lurek.globe.new("label_demo", {})
  g:addProvince(sampleProvince(1, 3, 3))
  local lid = g:addLabel("city", 3, 3, "Capital City")
  lurek.log.info("label id: " .. lid, "globe")
end

--@api-stub: Globe:addLayer
-- Adds a layer to this globe.
do
  local g = lurek.globe.new("layer_demo", {})
  g:addLayer("terrain", 1)
  g:addLayer("borders", 2)
  lurek.log.info("layers added", "globe")
end

--@api-stub: Globe:addMarker
-- Adds a marker to this globe.
do
  local g = lurek.globe.new("marker_demo", {})
  g:addProvince(sampleProvince(5, 2, 2))
  local mid = g:addMarker("capital_icon", 2, 2, "Capital")
  lurek.log.info("marker id: " .. mid, "globe")
end

--@api-stub: Globe:reachable
-- Performs the reachable operation on this globe.
do
  local g = lurek.globe.new("reachable_demo", {})
  for i=1,5 do g:addProvince(sampleProvince(i, i, 0, {neighbors = {i - 1, i + 1}})) end
  local ids = g:reachable(1, 3)
  lurek.log.info("reachable count: " .. #ids, "globe")
end

--@api-stub: Globe:setLayerColor
-- Sets the layer color of this globe.
do
  local g = lurek.globe.new("layer_color_demo", {})
  g:addProvince(sampleProvince(1, 0, 0))
  g:addLayer("ownership", 1)
  g:setLayerColor("ownership", 1, 1, 0.3, 0.3, 0.8)
  lurek.log.info("layer colour set", "globe")
end

--@api-stub: Globe:setMarkerAttr
-- Sets the marker attr of this globe.
do
  local g = lurek.globe.new("marker_attr_demo", {})
  g:addProvince(sampleProvince(1, 0, 0))
  local mid = g:addMarker("fort_icon", 0, 0, "Fort")
  g:setMarkerAttr(mid, "strength", "5")
  lurek.log.info("marker attr set", "globe")
end

--@api-stub: Globe:setProvinceAttr
-- Sets the province attr of this globe.
do
  local g = lurek.globe.new("province_attr_demo", {})
  g:addProvince(sampleProvince(3, 1, 1))
  g:setProvinceAttr(3, "population", "12000")
  lurek.log.info("attr: " .. g:getProvinceAttr(3, "population"), "globe")
end

--@api-stub: GlobeRegistry:new
-- Creates and returns a new  widget or object.
do
  local g = lurek.globe.new("world_a", {})
  lurek.log.info("registry globe created", "globe")
end

-- -----------------------------------------------------------------------------
-- LGlobe methods
-- -----------------------------------------------------------------------------

--@api-stub: LGlobe:type
-- Returns the Lua-visible type name for this globe handle
do
  local globe_obj = lurek.globe.new("test", nil)
  local t = globe_obj:type()
  lurek.log.info("LGlobe:type = " .. t, "globe")
end
--@api-stub: LGlobe:typeOf
-- Returns whether this globe handle matches a supported type name
do
  local globe_obj = lurek.globe.new("test", nil)
  lurek.log.info("is LGlobe: " .. tostring(globe_obj:typeOf("LGlobe")), "globe")
  lurek.log.info("is wrong: " .. tostring(globe_obj:typeOf("Unknown")), "globe")
end
--@api-stub: LGlobeRegistry:type
-- Returns the Lua-visible type name for this globe registry handle
do
  local obj = lurek.globe.new("alt_world", {})
    local g = lurek.globe.get("alt_world")
  local t = obj:type()
  lurek.log.info("LGlobeRegistry:type = " .. t, "globe")
end
--@api-stub: LGlobeRegistry:typeOf
-- Returns whether this registry handle matches a supported type name
do
  local obj = lurek.globe.new("alt_world", {})
    local g = lurek.globe.get("alt_world")
  lurek.log.info("is LGlobeRegistry: " .. tostring(obj:typeOf("LGlobeRegistry")), "globe")
  lurek.log.info("is wrong: " .. tostring(obj:typeOf("Unknown")), "globe")
end


--@api-stub: LGlobe:getProvinceSector
-- Returns the sector name assigned to a province on this globe, or nil if none.
do
  local g = lurek.globe.new(512, 256)
  local sector = g:getProvinceSector(1)
  lurek.log.debug("sector=" .. tostring(sector), "globe")
end

--@api-stub: LGlobe:getSectorProvinces
-- Returns a list of province ids that belong to the named sector on this globe.
do
  local g = lurek.globe.new(512, 256)
  g:setProvinceSector(1, "north")
  local ids = g:getSectorProvinces("north")
  lurek.log.debug("sector province count=" .. #ids, "globe")
end

--@api-stub: LGlobe:removeHeatLayer
-- Removes a previously set heat layer by name from this globe.
do
  local g = lurek.globe.new(512, 256)
  g:setHeatLayer("temp", 0, 40, 0.7)
  g:removeHeatLayer("temp")
end

--@api-stub: LGlobe:getFogState
-- Returns the fog-of-war state integer for a province on this globe.
do
  local g = lurek.globe.new(512, 256)
  g:setFogState(1, 1)
  local state = g:getFogState(1)
  lurek.log.debug("fog state=" .. state, "globe")
end

--@api-stub: LGlobe:encodeFogBase64
-- Encodes the current fog-of-war state for all provinces as a base64 string.
do
  local g = lurek.globe.new(512, 256)
  local encoded = g:encodeFogBase64()
  lurek.log.debug("fog encoded bytes=" .. #encoded, "globe")
end

--@api-stub: LGlobe:decodeFogBase64
-- Restores province fog-of-war states from a previously encoded base64 string.
do
  local g = lurek.globe.new(512, 256)
  local enc = g:encodeFogBase64()
  g:decodeFogBase64(enc)
end

--@api-stub: LGlobe:setMarkerRotation
-- Sets the rotation angle in radians for a placed marker on this globe.
do
  local g = lurek.globe.new(512, 256)
  local mid = g:placeMarker(0.5, 0.5, "base")
  g:setMarkerRotation(mid, 1.57)
end

--@api-stub: LGlobe:getCachedReachability
-- Returns the cached reachability cost table computed by a prior cacheReachability call.
do
  local g = lurek.globe.new(512, 256)
  g:cacheReachability(1, 10)
  local reach = g:getCachedReachability(1)
  lurek.log.debug("reachable=" .. (reach and #reach or 0), "globe")
end
