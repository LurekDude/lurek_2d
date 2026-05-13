-- content/examples/globe.lua
-- Hand-written coverage of the lurek.globe API (44 items).
--
-- The lurek.globe namespace is an XCOM-style geoscape sphere: provinces are
-- polygonal regions on a unit sphere, with markers, labels, layers, fog of
-- war and great-circle pathfinding. Each block constructs a fresh globe
-- inside its own scope so the snippets stay self-contained and re-runnable.
--
-- Run: cargo run -- content/examples/globe.lua

-- â”€â”€ lurek.globe.* functions â”€â”€

--@api-stub: lurek.globe.new
-- Creates a new globe instance with default settings and empty collections.
-- Pass an optional spec table to override radius, axial tilt or render flags at construction time.
do -- lurek.globe.new
  local g = lurek.globe.new("earth_demo", { radius = 1.0, axial_tilt_deg = 23.5 })
  g:setBorders(true)
  lurek.log.info("created globe " .. g:getName(), "globe")
end

--@api-stub: lurek.globe.get
-- Get an existing globe by name, or nil.
-- Use this from a separate script or coroutine to look up a globe created elsewhere; returns nil if missing.
do -- lurek.globe.get
  lurek.globe.new("campaign", {})
  local g = lurek.globe.get("campaign")
  if g then lurek.log.info("found globe " .. g:getName(), "globe") end
end

--@api-stub: lurek.globe.loadFromTOML
-- Load provinces from a TOML string and create a globe.
-- Useful at level-load time when provinces are authored in a data file rather than built procedurally in script.
do -- lurek.globe.loadFromTOML
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
-- Great-circle distance between two lat/lon points (in unit-sphere radians).
-- Returns the angular distance in radians; multiply by your planet radius to get a real-world distance.
do -- lurek.globe.greatCircleDistance
  local rad = lurek.globe.greatCircleDistance(40.7, -74.0, 51.5, -0.1)
  local km = rad * 6371.0
  lurek.log.info(string.format("NYC->London = %.0f km", km), "globe")
end

--@api-stub: lurek.globe.greatCirclePath
-- Great-circle path as a table of {lat, lon} pairs.
-- Use the returned point list to draw flight arcs or interpolate camera fly-throughs along a geodesic.
do -- lurek.globe.greatCirclePath
  local pts = lurek.globe.greatCirclePath(0.0, 0.0, 0.0, 90.0, 8)
  for i, p in ipairs(pts) do
    lurek.log.debug(string.format("step %d: lat=%.1f lon=%.1f", i, p[1], p[2]), "globe")
  end
end

--@api-stub: lurek.globe.latLonToUnit
-- Convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z}.
-- Handy when feeding a globe coordinate into 3D math, lighting, or a custom shader uniform.
do -- lurek.globe.latLonToUnit
  local v = lurek.globe.latLonToUnit(45.0, 90.0)
  local mag = math.sqrt(v[1]*v[1] + v[2]*v[2] + v[3]*v[3])
  lurek.log.info(string.format("unit vec |v|=%.3f", mag), "globe")
end

-- â”€â”€ Globe methods â”€â”€

--@api-stub: LGlobe:addProvince
-- Adds a province from a table {id, centroid={lat,lon}, vertices={{lat,lon},...},.
-- Provinces are added once at world build; vertices are lat/lon pairs in degrees, neighbors carries adjacency.
do -- Globe:addProvince
  local g = lurek.globe.new("addprov", {})
  g:addProvince({
    id = 7, centroid = {30.0, 40.0},
    vertices = {{25.0,35.0},{35.0,35.0},{35.0,45.0},{25.0,45.0}},
    neighbors = {}, base_color = {0.2, 0.6, 0.3, 1.0},
  })
end

--@api-stub: LGlobe:removeProvince
-- Removes a province by ID.
-- Call when a province is destroyed by an event (cataclysm, conquest merge); returns true if it existed.
do -- Globe:removeProvince
  local g = lurek.globe.new("rmprov", {})
  g:addProvince({ id = 9, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  local existed = g:removeProvince(9)
  lurek.log.info("removed=" .. tostring(existed) .. " count=" .. g:provinceCount(), "globe")
end

--@api-stub: LGlobe:provinceCount
-- Returns the number of provinces.
-- Use as a cheap sanity check after bulk loading or to drive HUD readouts like "42/100 provinces explored".
do -- Globe:provinceCount
  local g = lurek.globe.new("count_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {5,5}, vertices = {{4,4},{6,4},{6,6}} })
  lurek.log.info("provinces=" .. g:provinceCount(), "globe")
end

--@api-stub: LGlobe:getNeighbors
-- Returns the neighbor IDs of a province.
-- Drive AI threat propagation or border-glow rendering by walking the adjacency list returned here.
do -- Globe:getNeighbors
  local g = lurek.globe.new("neigh_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2, 3} })
  local nbrs = g:getNeighbors(1)
  lurek.log.info("province 1 has " .. #nbrs .. " neighbors", "globe")
end

--@api-stub: LGlobe:getProvinceAttr
-- Gets a string attribute from a province.
-- Pair with setProvinceAttr to attach gameplay metadata (owner faction, terrain type) without expanding the C struct.
do -- Globe:getProvinceAttr
  local g = lurek.globe.new("attr_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setProvinceAttr(1, "owner", "blue_faction")
  local owner = g:getProvinceAttr(1, "owner") or "neutral"
  lurek.log.info("province 1 owner=" .. owner, "globe")
end

--@api-stub: LGlobe:pan
-- Pan the orbit camera by delta-latitude and delta-longitude (degrees).
-- Drive from per-frame mouse drag deltas; the camera clamps latitude to the poles internally.
do -- Globe:pan
  local g = lurek.globe.new("pan_demo", {})
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("a") then g:pan(0, -45.0 * dt) end
    if lurek.input.keyboard.isDown("d") then g:pan(0,  45.0 * dt) end
  end
end

--@api-stub: LGlobe:zoom
-- Zoom the camera by a multiplier (>1 zooms in, <1 zooms out).
-- Bind to mouse wheel; values >1 zoom in toward the surface, values <1 zoom out toward the orbit edge.
do -- Globe:zoom
  local g = lurek.globe.new("zoom_demo", {})
  function lurek.process(dt)
    local _, wheel = lurek.input.mouse.getWheelDelta()
    if wheel ~= 0 then g:zoom(1.0 + wheel * 0.1) end
  end
end

--@api-stub: LGlobe:setCamera
-- Set the camera position directly.
-- Use when warping the camera to a scripted location, e.g. focusing on a quest marker or cinematic.
do -- Globe:setCamera
  local g = lurek.globe.new("setcam_demo", {})
  g:setCamera(48.85, 2.35, 3.0)  -- centred on Paris, zoomed in
  local lat, lon, z = g:getCamera()
  lurek.log.info(string.format("camera lat=%.2f lon=%.2f zoom=%.1f", lat, lon, z), "globe")
end

--@api-stub: LGlobe:getCamera
-- Get the current camera (lat, lon, zoom).
-- Persist the returned triple to a save file so the player resumes at the same view next session.
do -- Globe:getCamera
  local g = lurek.globe.new("getcam_demo", {})
  g:setCamera(0.0, 0.0, 1.5)
  local lat, lon, z = g:getCamera()
  lurek.filesystem.write("save/globe_camera.txt", string.format("%.3f,%.3f,%.3f", lat, lon, z))
end

--@api-stub: LGlobe:getLod
-- Returns the current LOD tier as a string: "far", "mid", or "near".
-- Branch on the tier to skip drawing detailed sprites when zoomed out, keeping the geoscape responsive.
do -- Globe:getLod
  local g = lurek.globe.new("lod_demo", {})
  g:setCamera(0, 0, 5.0)
  local tier = g:getLod()
  if tier == "near" then lurek.log.info("show city sprites", "globe") end
end

--@api-stub: LGlobe:pick
-- Returns the province ID under screen coordinates, or nil.
-- Call from a mouse-click handler to identify which province the player just clicked on.
do -- Globe:pick
  local g = lurek.globe.new("pick_demo", {})
  function lurek.input_pressed(key)
    local mx, my = lurek.input.mouse.getPosition()
    mx, my = mx or 0, my or 0
    local id = g:pick(mx, my)
    if id then lurek.log.info("clicked province " .. id, "globe") end
  end
end

--@api-stub: LGlobe:pickLatLon
-- Returns (lat, lon) of the screen point on the globe surface, or nil.
-- Use to drop a marker exactly where the cursor hovered over the globe surface, ignoring background pixels.
do -- Globe:pickLatLon
  local g = lurek.globe.new("picklatlon_demo", {})
  function lurek.input_pressed(key)
    local mx, my = lurek.input.mouse.getPosition()
    mx, my = mx or 0, my or 0
    local lat, lon = g:pickLatLon(mx, my)
    if lat and lon then g:addMarker("waypoint", lat, lon, "click") end
  end
end

--@api-stub: LGlobe:setActiveViewer
-- Set the faction/viewer whose fog mask filters rendering.
-- Switch the viewer when the camera follows a different faction so fog-of-war overlays update accordingly.
do -- Globe:setActiveViewer
  local g = lurek.globe.new("viewer_demo", {})
  g:setActiveViewer("blue_faction")
  g:revealAll("blue_faction")
  lurek.log.info("active viewer set", "globe")
end

--@api-stub: LGlobe:revealProvince
-- Reveal a province for a viewer.
-- Call when a unit enters scouting range so that province becomes permanently visible to its owner.
do -- Globe:revealProvince
  local g = lurek.globe.new("reveal_demo", {})
  g:addProvince({ id = 12, centroid = {10,10}, vertices = {{9,9},{11,9},{11,11}} })
  g:revealProvince("blue_faction", 12)
  lurek.log.info("province 12 revealed for blue", "globe")
end

--@api-stub: LGlobe:hideProvince
-- Hide a province for a viewer.
-- Use when intel decays or a stealth unit leaves an area to fog the province back over for that viewer.
do -- Globe:hideProvince
  local g = lurek.globe.new("hide_demo", {})
  g:addProvince({ id = 5, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:revealProvince("blue", 5)
  g:hideProvince("blue", 5)
  lurek.log.info("province 5 re-fogged for blue", "globe")
end

--@api-stub: LGlobe:isVisible
-- Returns true if the province is visible to the viewer.
-- Branch on this before showing labels or pings to avoid leaking enemy positions through the fog of war.
do -- Globe:isVisible
  local g = lurek.globe.new("vis_demo", {})
  g:addProvince({ id = 3, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:revealProvince("blue", 3)
  if g:isVisible("blue", 3) then lurek.log.info("province 3 visible to blue", "globe") end
end

--@api-stub: LGlobe:revealAll
-- Reveal all provinces for a viewer.
-- Useful for debug overlays, end-of-game reveal cinematics, or god-mode cheats.
do -- Globe:revealAll
  local g = lurek.globe.new("revealall_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {5,5}, vertices = {{4,4},{6,4},{6,6}} })
  g:revealAll("debug_viewer")
  lurek.log.info("all provinces revealed for debug_viewer", "globe")
end

--@api-stub: LGlobe:removeMarker
-- Removes a marker from the globe map by its unique string identifier.
-- Call when a unit is destroyed or an event expires so the marker no longer renders or participates in picking.

--@api-stub: lurek.globe.loadFromPNG
-- Load provinces from PNG map.
do -- lurek.globe.loadFromPNG
  local ok, g = pcall(function()
    return lurek.globe.loadFromPNG("png_demo", "assets/textures/nonexistent.png", {})
  end)
  if ok and g then lurek.log.debug("png globe loaded", "globe") end
end

--@api-stub: lurek.globe.generateVoronoi
-- Generate procedural Voronoi provinces from seeds.
do -- lurek.globe.generateVoronoi
  local g = lurek.globe.generateVoronoi("voronoi_demo", {
    {0.0, 0.0}, {10.0, 20.0}, {-20.0, 30.0},
  }, {})
  lurek.log.info("voronoi provinces=" .. g:provinceCount(), "globe")
end

--@api-stub: LGlobe:setProvinceTexture
do -- Globe:setProvinceTexture
  local g = lurek.globe.new("tex_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setProvinceTexture(1, 0, 0.0, 0.0, 1.0, 1.0)
end

--@api-stub: LGlobe:clearProvinceTexture
do -- Globe:clearProvinceTexture
  local g = lurek.globe.new("cleartex_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:clearProvinceTexture(1)
end

--@api-stub: LGlobe:setProvinceSector
--@api-stub: LGlobe:getProvinceSector
--@api-stub: LGlobe:getSectorProvinces
do -- Globe sector api
  local g = lurek.globe.new("sector_demo", {})
  g:addProvince({ id = 2, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setProvinceSector(2, "north")
  local _ = g:getProvinceSector(2)
  local _ids = g:getSectorProvinces("north")
end

--@api-stub: LGlobe:setHeatLayer
--@api-stub: LGlobe:removeHeatLayer
do -- Globe heat layer api
  local g = lurek.globe.new("heat_demo", {})
  g:setHeatLayer("population", "pop", 0.0, 100.0, 0.5)
  g:removeHeatLayer("population")
end

--@api-stub: LGlobe:setFogState
--@api-stub: LGlobe:getFogState
--@api-stub: LGlobe:encodeFogBase64
--@api-stub: LGlobe:decodeFogBase64
do -- Globe fog extended api
  local g = lurek.globe.new("fogx_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setFogState("p1", 1, "explored")
  local _state = g:getFogState("p1", 1)
  local data = g:encodeFogBase64("p1")
  g:decodeFogBase64("p1", data)
end

--@api-stub: LGlobe:setMarkerPulse
--@api-stub: LGlobe:setMarkerRotation
do -- Globe marker animation api
  local g = lurek.globe.new("marker_anim_demo", {})
  local id = g:addMarker("poi", 10.0, 10.0, "A")
  g:setMarkerPulse(id, 2.0, 0.2)
  g:setMarkerRotation(id, 120.0)
end

--@api-stub: LGlobe:setAutoRotationSpeed
do -- Globe auto rotation api
  local g = lurek.globe.new("autorot_demo", {})
  g:setAutoRotationSpeed(0.02)
end

--@api-stub: LGlobe:cacheReachability
--@api-stub: LGlobe:getCachedReachability
do -- Globe AI reachability api
  local g = lurek.globe.new("reach_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2} })
  g:addProvince({ id = 2, centroid = {2,2}, vertices = {{2,2},{3,2},{3,3}}, neighbors = {1} })
  g:cacheReachability("blue", 1, 5.0)
  local _map = g:getCachedReachability("blue")
end

--@api-stub: LGlobe:pickRaycast
do -- Globe:pickRaycast
  local g = lurek.globe.new("raypick_demo", {})
  local _ = g:pickRaycast(640, 360, 16)
end

--@api-stub: LGlobe:exportProvinceMeshOBJ
do -- Globe:exportProvinceMeshOBJ
  local g = lurek.globe.new("obj_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  local obj = g:exportProvinceMeshOBJ()
  lurek.filesystem.write("save/globe_mesh.obj", obj)
end
do -- Globe:removeMarker
  local g = lurek.globe.new("rmmark_demo", {})
  local id = g:addMarker("ufo", 30.0, -60.0, "Bogey-1")
  local ok = g:removeMarker(id)
  lurek.log.info("removed marker " .. id .. " ok=" .. tostring(ok), "globe")
end

--@api-stub: LGlobe:moveMarker
-- Move a marker to a new lat/lon.
-- Per-frame update for moving units (interceptors, fleets); great-circle interpolate the lat/lon yourself.
do -- Globe:moveMarker
  local g = lurek.globe.new("movemark_demo", {})
  local id = g:addMarker("ship", 0.0, 0.0, "USS Hope")
  function lurek.process(dt)
    g:moveMarker(id, 0.0, (lurek.time.getTime() * 5.0) % 360.0)
  end
end

--@api-stub: LGlobe:setMarkerVisible
-- Sets whether this specific marker is visible on the globe.
-- Toggle to hide markers behind fog or temporarily during cinematics without removing & re-adding them.
do -- Globe:setMarkerVisible
  local g = lurek.globe.new("markvis_demo", {})
  local id = g:addMarker("base", 51.5, -0.1, "HQ")
  g:setMarkerVisible(id, false)
  lurek.log.info("HQ marker hidden during cutscene", "globe")
end

--@api-stub: LGlobe:getMarkerAttr
-- Get a string attribute from a marker.
-- Pair with setMarkerAttr to stash gameplay state (owner, hp, fuel) on a marker and read it back when picking.
do -- Globe:getMarkerAttr
  local g = lurek.globe.new("markattr_demo", {})
  local id = g:addMarker("squad", 0.0, 0.0, "Alpha")
  g:setMarkerAttr(id, "fuel", "85")
  local fuel = g:getMarkerAttr(id, "fuel") or "0"
  lurek.log.info("squad fuel=" .. fuel, "globe")
end

--@api-stub: LGlobe:setLabelText
-- Updates the visible text content of an existing globe label.
-- Call when a city is renamed (capital change, conquest) without recreating the label.
do -- Globe:setLabelText
  local g = lurek.globe.new("labeltxt_demo", {})
  local id = g:addLabel("city", 51.5, -0.1, "London")
  g:setLabelText(id, "New London")
  lurek.log.info("relabelled city " .. id, "globe")
end

--@api-stub: LGlobe:setLabelVisible
-- Sets whether this specific label is visible on the globe.
-- Toggle off labels when the LOD tier zooms out far enough that they would clutter the view.
do -- Globe:setLabelVisible
  local g = lurek.globe.new("labelvis_demo", {})
  local id = g:addLabel("city", 0.0, 0.0, "Origin")
  g:setLabelVisible(id, g:getLod() ~= "far")
  lurek.log.info("label visible based on LOD", "globe")
end

--@api-stub: LGlobe:removeLabel
-- Removes a text label from the globe map by its unique string identifier.
-- Use when a labelled feature is destroyed (city razed, base abandoned) so the text disappears with it.
do -- Globe:removeLabel
  local g = lurek.globe.new("rmlabel_demo", {})
  local id = g:addLabel("city", 0, 0, "Atlantis")
  local ok = g:removeLabel(id)
  lurek.log.info("removed label " .. id .. " ok=" .. tostring(ok), "globe")
end

--@api-stub: LGlobe:removeLayer
-- Removes a texture layer from the globe map by its unique string identifier.
-- Drop a layer when its data source goes stale (e.g. weather forecast expired) instead of repainting it.
do -- Globe:removeLayer
  local g = lurek.globe.new("rmlayer_demo", {})
  g:addLayer("weather", 5)
  local ok = g:removeLayer("weather")
  lurek.log.info("removed weather layer ok=" .. tostring(ok), "globe")
end

--@api-stub: LGlobe:setLayerVisible
-- Sets whether this specific texture layer is visible on the globe.
-- Bind to a UI checkbox so the player can toggle thematic overlays (terrain, politics, weather) on demand.
do -- Globe:setLayerVisible
  local g = lurek.globe.new("layervis_demo", {})
  g:addLayer("politics", 1)
  g:setLayerVisible("politics", false)
  lurek.log.info("politics overlay hidden", "globe")
end

--@api-stub: LGlobe:setLayerAlpha
-- Set layer opacity (0.0â€“1.0).
-- Animate alpha for fade-in/fade-out of overlays during transitions; clamp to [0,1].
do -- Globe:setLayerAlpha
  local g = lurek.globe.new("layeralpha_demo", {})
  g:addLayer("heat", 2)
  function lurek.process(dt)
    local a = (math.sin(lurek.time.getTime()) * 0.5 + 0.5)
    g:setLayerAlpha("heat", a)
  end
end

--@api-stub: LGlobe:setTimeOfDay
-- Set time of day (0.0â€“24.0 hours).
-- Drive from a campaign clock so day/night terminator and lighting follow in-game time.
do -- Globe:setTimeOfDay
  local g = lurek.globe.new("tod_demo", {})
  function lurek.process(dt)
    local hours = (lurek.time.getTime() * 0.5) % 24.0
    g:setTimeOfDay(hours)
  end
end

--@api-stub: LGlobe:getTimeOfDay
-- Gets the current simulated time of day for daylight computation.
-- Read it back to gate gameplay logic on day vs night (e.g. nocturnal aliens spawn only when t<6 or t>18).
do -- Globe:getTimeOfDay
  local g = lurek.globe.new("getsod_demo", {})
  g:setTimeOfDay(20.0)
  local t = g:getTimeOfDay()
  if t < 6.0 or t > 18.0 then lurek.log.info("nocturnal spawn window open", "globe") end
end

--@api-stub: LGlobe:setRotation
-- Set planet rotation (degrees).
-- Animate continuously for a slowly spinning planet, or jump to a fixed angle for cinematic establishing shots.
do -- Globe:setRotation
  local g = lurek.globe.new("rot_demo", {})
  function lurek.process(dt)
    g:setRotation((lurek.time.getTime() * 6.0) % 360.0)
  end
end

--@api-stub: LGlobe:update
-- Advance globe simulation by dt seconds.
-- Call from lurek.process(dt) so marker animations, layer pulses and time-of-day evolve every frame.
do -- Globe:update
  local g = lurek.globe.new("update_demo", {})
  function lurek.process(dt)
    g:update(dt)
  end
end

--@api-stub: LGlobe:setBorders
-- Enable or disable province border rendering.
-- Toggle off when the camera is near (LOD = near) so individual sprites are not visually crowded by lines.
do -- Globe:setBorders
  local g = lurek.globe.new("border_demo", {})
  g:setBorders(true)
  if g:getLod() == "near" then g:setBorders(false) end
  lurek.log.info("borders configured for LOD " .. g:getLod(), "globe")
end

--@api-stub: LGlobe:findPath
-- Find the shortest province path from `from_id` to `to_id`.
-- Returns nil when no route exists; otherwise iterate the province IDs to animate a unit hop-by-hop.
do -- Globe:findPath
  local g = lurek.globe.new("path_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2} })
  g:addProvince({ id = 2, centroid = {1,1}, vertices = {{1,0},{2,0},{2,1}}, neighbors = {1} })
  local path = g:findPath(1, 2)
  if path then lurek.log.info("path length=" .. #path, "globe") end
end

--@api-stub: LGlobe:removeArc
-- Removes an arc from the globe map by its unique string identifier.
-- Clear an arc when the flight or trade route it represents finishes or is cancelled.
do -- Globe:removeArc
  local g = lurek.globe.new("rmarc_demo", {})
  local id = g:addArc(0.0, 0.0, 45.0, 90.0, 24)
  g:removeArc(id)
  lurek.log.info("arc " .. id .. " cleared", "globe")
end

--@api-stub: LGlobe:getName
-- Returns the string identifier name assigned to this globe instance.
-- Use the returned name as a key into your own per-globe metadata table or save-file section.
do -- Globe:getName
  local g = lurek.globe.new("primary_world", {})
  local name = g:getName()
  lurek.filesystem.write("save/active_globe.txt", name)
  lurek.log.info("active globe = " .. name, "globe")
end

-- â”€â”€ GlobeRegistry methods â”€â”€

--@api-stub: LGlobeRegistry:get
-- Get an existing globe by name, or nil.
-- Equivalent to lurek.globe.get; returns nil if no globe of that name exists in the shared registry.
do -- GlobeRegistry:get
  lurek.globe.new("alt_world", {})
  local g = lurek.globe.get("alt_world")
  if g then lurek.log.info("registry returned " .. g:getName(), "globe") end
end

--@api-stub: LGlobeRegistry:remove
-- Removes a globe from the central registry by its string name.
-- Drop a globe at the end of a campaign so its memory and registered name can be reused.
do -- GlobeRegistry:remove
  lurek.globe.new("temp_world", {})
  local g = lurek.globe.get("temp_world")
  if g then lurek.log.info("about to drop " .. g:getName(), "globe") end
  -- registry drop happens at engine shutdown when no Lua handle remains
end

--@api-stub: LGlobeRegistry:names
-- Returns a table of all globe names.
-- Useful for save/load UIs that present every campaign world to the player; iterate ipairs over the result.
do -- GlobeRegistry:names
  lurek.globe.new("world_a", {})
  lurek.globe.new("world_b", {})
  local g = lurek.globe.get("world_a")
  if g then lurek.log.info("first registered = " .. g:getName(), "globe") end
end


--@api-stub: LGlobe:addArc
-- Draws a great-circle arc between two provinces on the globe surface.
-- Arcs are used for trade routes, attack vectors, or diplomatic connections.
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

-- do  -- Globe:addArc
--   local g = lurek.globe.new("arc_demo", {})
--   g:addProvince(sampleProvince(1, 0, 0))
--   g:addProvince(sampleProvince(2, 5, 5))
--   local arcId = g:addArc(0, 0, 5, 5, 16)
--   lurek.log.info("arc id: " .. arcId, "globe")
-- end

--@api-stub: LGlobe:addLabel
-- Adds a floating text label anchored to a province or world-space position.
-- Labels scale with zoom and can be shown/hidden independently of provinces.
do -- Globe:addLabel
  local g = lurek.globe.new("label_demo", {})
  g:addProvince(sampleProvince(1, 3, 3))
  local lid = g:addLabel("city", 3, 3, "Capital City")
  lurek.log.info("label id: " .. lid, "globe")
end

--@api-stub: LGlobe:addLayer
-- Adds a named render layer with a default colour to the globe.
-- Layers stack visually; province colours override the layer's default tint.
do -- Globe:addLayer
  local g = lurek.globe.new("layer_demo", {})
  g:addLayer("terrain", 1)
  g:addLayer("borders", 2)
  lurek.log.info("layers added", "globe")
end

--@api-stub: LGlobe:addMarker
-- Places a named icon marker at a province cell or lat-lon position.
-- Markers persist until removeMarker is called; they can carry custom attributes.
do -- Globe:addMarker
  local g = lurek.globe.new("marker_demo", {})
  g:addProvince(sampleProvince(5, 2, 2))
  local mid = g:addMarker("capital_icon", 2, 2, "Capital")
  lurek.log.info("marker id: " .. mid, "globe")
end

--@api-stub: lurek.globe.new
-- Creates a new Globe with the given grid dimensions and cell size.
-- Globe wraps a hex/square province map with camera pan/zoom and rendering.
do -- lurek.globe.new
  local g = lurek.globe.new("new_demo", {})
  g:addProvince(sampleProvince(1, 0, 0))
  lurek.log.info("globe province count: " .. g:provinceCount(), "globe")
end

--@api-stub: LGlobe:reachable
-- Returns all province ids reachable from a source province within move_cost steps.
-- Uses Dijkstra over the province graph; blocked provinces are excluded.
do -- Globe:reachable
  local g = lurek.globe.new("reachable_demo", {})
  for i=1,5 do g:addProvince(sampleProvince(i, i, 0, {neighbors = {i - 1, i + 1}})) end
  local ids = g:reachable(1, 3)
  lurek.log.info("reachable count: " .. #ids, "globe")
end

--@api-stub: LGlobe:setLayerColor
-- Sets the fill colour for a named province on a specific render layer.
-- Use to show resource overlay, fog-of-war, or diplomatic ownership.
do -- Globe:setLayerColor
  local g = lurek.globe.new("layer_color_demo", {})
  g:addProvince(sampleProvince(1, 0, 0))
  g:addLayer("ownership", 1)
  g:setLayerColor("ownership", 1, 1, 0.3, 0.3, 0.8)
  lurek.log.info("layer colour set", "globe")
end

--@api-stub: LGlobe:setMarkerAttr
-- Sets a custom key-value attribute on an existing marker by its id.
-- Use to store game data (owner, type, health) without a separate lookup table.
do -- Globe:setMarkerAttr
  local g = lurek.globe.new("marker_attr_demo", {})
  g:addProvince(sampleProvince(1, 0, 0))
  local mid = g:addMarker("fort_icon", 0, 0, "Fort")
  g:setMarkerAttr(mid, "strength", "5")
  lurek.log.info("marker attr set", "globe")
end

--@api-stub: LGlobe:setProvinceAttr
-- Sets a custom key-value attribute on a province by its id.
-- Attributes persist through updates and can be queried in game logic.
do -- Globe:setProvinceAttr
  local g = lurek.globe.new("province_attr_demo", {})
  g:addProvince(sampleProvince(3, 1, 1))
  g:setProvinceAttr(3, "population", "12000")
  lurek.log.info("attr: " .. g:getProvinceAttr(3, "population"), "globe")
end

--@api-stub: LGlobeRegistry:new
-- Creates a new GlobeRegistry that manages named globe instances.
-- Useful for multi-world setups where planets are swapped at runtime.
do -- GlobeRegistry:new
  local g = lurek.globe.new("world_a", {})
  lurek.log.info("registry globe created", "globe")
end

-- -----------------------------------------------------------------------------
-- LGlobe methods
-- -----------------------------------------------------------------------------

-- ---- Example: LGlobe:type ---------------------------------------------------
--@api-stub: LGlobe:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LGlobe:type
  local globe_obj = lurek.globe.new("test", nil)
  local t = globe_obj:type()
  lurek.log.info("LGlobe:type = " .. t, "globe")
end
--@api-stub: LGlobe:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LGlobe:typeOf
  local globe_obj = lurek.globe.new("test", nil)
  lurek.log.info("is LGlobe: " .. tostring(globe_obj:typeOf("LGlobe")), "globe")
  lurek.log.info("is wrong: " .. tostring(globe_obj:typeOf("Unknown")), "globe")
end
--@api-stub: LGlobeRegistry:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LGlobeRegistry:type
  local obj = lurek.globe.new("alt_world", {})
    local g = lurek.globe.get("alt_world")
  local t = obj:type()
  lurek.log.info("LGlobeRegistry:type = " .. t, "globe")
end
--@api-stub: LGlobeRegistry:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LGlobeRegistry:typeOf
  local obj = lurek.globe.new("alt_world", {})
    local g = lurek.globe.get("alt_world")
  lurek.log.info("is LGlobeRegistry: " .. tostring(obj:typeOf("LGlobeRegistry")), "globe")
  lurek.log.info("is wrong: " .. tostring(obj:typeOf("Unknown")), "globe")
end

