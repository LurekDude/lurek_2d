-- content/examples/globe.lua
-- lurek.globe API examples: spherical province maps, fog of war, markers, labels, layers, pathfinding, and coordinate math.
-- Run: cargo run -- content/examples/globe.lua

-- ═══════════════════════════════════════════════════════════════════════════════
-- Module-level functions
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobeRegistry:new
-- Creates a named globe with optional specification fields in the module registry
do
  -- lurek.globe.new(name, spec_tbl?) -> LGlobe
  -- The spec table can include: radius, axial_tilt_deg, and other globe parameters.
  -- Each globe is stored in a shared registry and can be retrieved later by name.
  -- Use this as the primary entry point for creating strategy maps, planet views, etc.
  local g = lurek.globe.new("earth_demo", {
    radius = 1.0,        -- unit sphere radius; scales all lat/lon projections
    axial_tilt_deg = 23.5, -- Earth-like axial tilt for day/night terminator
  })
  -- After creation, configure rendering options like province borders
  g:setBorders(true)
  lurek.log.info("created globe '" .. g:getName() .. "' with borders enabled", "globe")
end

--@api-stub: LGlobeRegistry:get
-- Returns a globe from the module registry by name
do
  -- lurek.globe.get(name) -> LGlobe | nil
  -- Use this to retrieve a globe created elsewhere (e.g., in a different script module).
  -- Returns nil if no globe with that name exists — always nil-check before use.
  lurek.globe.new("campaign", {})
  local g = lurek.globe.get("campaign")
  if g then
    -- Safe to use the globe handle now
    lurek.log.info("found globe '" .. g:getName() .. "' in registry", "globe")
  else
    lurek.log.warn("globe 'campaign' not found — was it created?", "globe")
  end
end

--@api-stub: lurek.globe.loadFromTOML
-- Creates a globe and populates provinces from TOML source text
do
  -- lurek.globe.loadFromTOML(name, toml_src, spec_tbl?) -> LGlobe
  -- Parses TOML text defining [[provinces]] arrays with id, centroid, vertices, neighbors.
  -- Ideal for loading hand-authored map data from mod files or embedded strings.
  local toml_src = [=[
  [[provinces]]
  id = 1
  centroid = [10.0, 20.0]
  vertices = [[5.0,15.0],[15.0,15.0],[15.0,25.0],[5.0,25.0]]
  neighbors = [2]

  [[provinces]]
  id = 2
  centroid = [30.0, 40.0]
  vertices = [[25.0,35.0],[35.0,35.0],[35.0,45.0],[25.0,45.0]]
  neighbors = [1]
  ]=]
  local g = lurek.globe.loadFromTOML("loaded", toml_src, {})
  -- The globe is ready with province graph connectivity from the TOML data
  lurek.log.info("loaded " .. g:provinceCount() .. " provinces from TOML", "globe")
end

--@api-stub: lurek.globe.loadFromPNG
-- Creates a globe and populates provinces from a PNG file
do
  -- lurek.globe.loadFromPNG(name, png_path, spec_tbl?) -> LGlobe
  -- Reads a color-coded PNG where each unique color becomes a province.
  -- Useful for importing maps authored in image editors (each region = one color).
  -- The path is resolved through GameFS, so use relative content paths.
  local ok, g = pcall(function()
    return lurek.globe.loadFromPNG("png_world", "assets/textures/world_map.png", {})
  end)
  if ok and g then
    lurek.log.info("loaded " .. g:provinceCount() .. " provinces from PNG", "globe")
  else
    -- Graceful fallback when the asset is missing (e.g., in test environments)
    lurek.log.debug("PNG globe load skipped — asset not available", "globe")
  end
end

--@api-stub: lurek.globe.generateVoronoi
-- Creates a globe and populates provinces from latitude-longitude seed points
do
  -- lurek.globe.generateVoronoi(name, seeds_tbl, spec_tbl?) -> LGlobe
  -- Generates a Voronoi tessellation on the sphere from seed points.
  -- Each seed {lat, lon} becomes the centroid of one province.
  -- Great for procedural worlds: scatter random seeds for organic-looking territories.
  local seeds = {
    { 0.0,   0.0},   -- equatorial region
    {10.0,  20.0},   -- tropical northeast
    {-20.0, 30.0},   -- southern territory
    {45.0, -30.0},   -- northern atlantic
    {-40.0, 120.0},  -- southern pacific
  }
  local g = lurek.globe.generateVoronoi("procedural_world", seeds, {})
  -- Each seed generated one province; neighbors are computed from adjacency
  lurek.log.info("voronoi globe has " .. g:provinceCount() .. " provinces", "globe")
end

--@api-stub: lurek.globe.greatCircleDistance
-- Computes great-circle distance between two latitude-longitude points
do
  -- lurek.globe.greatCircleDistance(lat1, lon1, lat2, lon2) -> number
  -- Returns the angular distance on a unit sphere (in radians).
  -- Multiply by planet radius to get real-world distance (e.g., 6371 km for Earth).
  -- Use this for estimating travel time, range checks, missile range, etc.
  local rad = lurek.globe.greatCircleDistance(40.7, -74.0, 51.5, -0.1)
  local earth_radius_km = 6371.0
  local km = rad * earth_radius_km
  lurek.log.info(string.format("NYC -> London = %.0f km (%.3f rad)", km, rad), "globe")
end

--@api-stub: lurek.globe.greatCirclePath
-- Computes sampled latitude-longitude points along a great-circle path
do
  -- lurek.globe.greatCirclePath(lat1, lon1, lat2, lon2, num_samples) -> {{lat,lon},...}
  -- Returns an array of {lat, lon} pairs sampled evenly along the shortest arc.
  -- Use this for drawing flight paths, trade routes, or missile trajectories on the globe.
  local pts = lurek.globe.greatCirclePath(0.0, 0.0, 0.0, 90.0, 8)
  -- Each point is a {lat, lon} pair along the equator from 0 to 90 degrees longitude
  for i, p in ipairs(pts) do
    lurek.log.debug(string.format("waypoint %d: lat=%.2f lon=%.2f", i, p[1], p[2]), "globe")
  end
end

--@api-stub: lurek.globe.latLonToUnit
-- Converts latitude and longitude to a unit-sphere 3D vector table
do
  -- lurek.globe.latLonToUnit(lat, lon) -> {x, y, z}
  -- Returns a 3-element array on the unit sphere. Useful for computing dot products,
  -- placing 3D markers, or doing custom projection math outside the globe system.
  local v = lurek.globe.latLonToUnit(45.0, 90.0)
  local mag = math.sqrt(v[1]*v[1] + v[2]*v[2] + v[3]*v[3])
  -- The magnitude should always be 1.0 (unit sphere)
  lurek.log.info(string.format("unit vector = (%.3f, %.3f, %.3f), |v|=%.4f", v[1], v[2], v[3], mag), "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Province management
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:addProvince
-- Adds a province to this globe.
do
  -- Globe:addProvince(table) -> boolean
  -- The province table requires: id (unique integer), centroid {lat, lon}, vertices {{lat,lon},...}
  -- Optional fields: neighbors (array of adjacent province ids), base_color {r,g,b,a}
  -- Returns true if accepted, false if the id already exists or limit reached.
  local g = lurek.globe.new("strategy_map", {})

  -- Define a coastal province with explicit color and neighbor connections
  local accepted = g:addProvince({
    id = 1,
    centroid = {30.0, 40.0},              -- center point for picking and labels
    vertices = {                           -- polygon boundary (convex hull)
      {28.0, 38.0}, {32.0, 38.0},
      {33.0, 42.0}, {27.0, 42.0},
    },
    neighbors = {2, 3},                   -- province ids this borders
    base_color = {0.2, 0.6, 0.3, 1.0},   -- green terrain color (RGBA 0-1)
  })
  lurek.log.info("province 1 accepted=" .. tostring(accepted), "globe")

  -- Add a neighboring desert province
  g:addProvince({
    id = 2,
    centroid = {34.0, 40.0},
    vertices = {{32.0, 38.0}, {36.0, 38.0}, {36.0, 42.0}, {33.0, 42.0}},
    neighbors = {1},
    base_color = {0.8, 0.7, 0.3, 1.0},   -- sandy desert color
  })
end

--@api-stub: LGlobe:removeProvince
-- Removes a province from this globe.
do
  -- Globe:removeProvince(id) -> boolean
  -- Removes the province and returns true if it existed.
  -- Use this for dynamic maps where territory can be destroyed (e.g., sinking islands).
  local g = lurek.globe.new("dynamic_map", {})
  g:addProvince({ id = 9, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  local count_before = g:provinceCount()
  local existed = g:removeProvince(9)
  lurek.log.info(string.format("removed=%s, count %d -> %d",
    tostring(existed), count_before, g:provinceCount()), "globe")
end

--@api-stub: LGlobe:provinceCount
-- Returns the number of provinces currently in this globe.
do
  -- Globe:provinceCount() -> integer
  -- Use this to verify data loaded correctly or to iterate province ids.
  local g = lurek.globe.new("count_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {5,5}, vertices = {{4,4},{6,4},{6,6}} })
  g:addProvince({ id = 3, centroid = {10,10}, vertices = {{9,9},{11,9},{11,11}} })
  lurek.log.info("total provinces = " .. g:provinceCount(), "globe")
end

--@api-stub: LGlobe:getNeighbors
-- Returns the neighbor province ids for a given province.
do
  -- Globe:getNeighbors(id) -> {id, id, ...}
  -- Returns the adjacency list defined when the province was added.
  -- Use this for movement validation, AI expansion logic, border highlighting.
  local g = lurek.globe.new("adjacency_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2, 3} })
  g:addProvince({ id = 2, centroid = {2,0}, vertices = {{2,0},{3,0},{3,1}}, neighbors = {1} })
  g:addProvince({ id = 3, centroid = {0,2}, vertices = {{0,2},{1,2},{1,3}}, neighbors = {1} })

  local nbrs = g:getNeighbors(1)
  -- In a strategy game, check if the target province is adjacent before allowing movement
  lurek.log.info("province 1 borders " .. #nbrs .. " neighbors: " .. table.concat(nbrs, ", "), "globe")
end

--@api-stub: LGlobe:getProvinceAttr
-- Returns a string attribute stored on a province.
do
  -- Globe:getProvinceAttr(id, key) -> string | nil
  -- Province attributes are key-value string pairs for game state (owner, terrain, etc.).
  -- Returns nil if the province or key does not exist.
  local g = lurek.globe.new("attr_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setProvinceAttr(1, "owner", "blue_faction")
  g:setProvinceAttr(1, "terrain", "plains")

  local owner = g:getProvinceAttr(1, "owner") or "neutral"
  local terrain = g:getProvinceAttr(1, "terrain") or "unknown"
  lurek.log.info(string.format("province 1: owner=%s, terrain=%s", owner, terrain), "globe")
end

--@api-stub: LGlobe:setProvinceAttr
-- Sets a string attribute on a province.
do
  -- Globe:setProvinceAttr(id, key, value) -> boolean
  -- Stores arbitrary string key-value data on a province.
  -- The heat layer system reads numeric attrs; game logic reads string attrs.
  -- Returns true if the province exists.
  local g = lurek.globe.new("province_attr_demo", {})
  g:addProvince({ id = 3, centroid = {1,1}, vertices = {{0,0},{2,0},{2,2},{0,2}} })

  -- Store gameplay data that persists with the globe
  g:setProvinceAttr(3, "population", "12000")
  g:setProvinceAttr(3, "fortification", "3")
  g:setProvinceAttr(3, "resource", "iron")
  lurek.log.info("province 3 population = " .. g:getProvinceAttr(3, "population"), "globe")
end

--@api-stub: LGlobe:setProvinceTexture
-- Sets a raw texture handle and UV rectangle on a province for textured rendering.
do
  -- Globe:setProvinceTexture(id, tex_raw, u0, v0, u1, v1) -> boolean
  -- Assigns a texture atlas region to a province for terrain rendering.
  -- tex_raw is a raw integer handle from the renderer's texture system.
  -- UV coordinates define the sub-rectangle within the atlas (0-1 range).
  local g = lurek.globe.new("tex_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })

  -- Map province 1 to the top-left quadrant of texture atlas slot 0
  g:setProvinceTexture(1, 0, 0.0, 0.0, 0.5, 0.5)
end

--@api-stub: LGlobe:clearProvinceTexture
-- Clears texture metadata from a province, reverting to base color rendering.
do
  -- Globe:clearProvinceTexture(id) -> boolean
  -- Removes the texture assignment so the province renders with its base_color again.
  -- Use when switching between textured terrain view and political color view.
  local g = lurek.globe.new("cleartex_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setProvinceTexture(1, 0, 0.0, 0.0, 1.0, 1.0)
  -- Toggle back to flat color mode
  g:clearProvinceTexture(1)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Camera and navigation
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:pan
-- Pans the globe camera by latitude and longitude deltas.
do
  -- Globe:pan(dlat, dlon) -> nil
  -- Shifts the camera view by delta degrees. Positive dlat = north, positive dlon = east.
  -- Call this each frame scaled by dt for smooth keyboard/gamepad navigation.
  local g = lurek.globe.new("pan_demo", {})
  local pan_speed = 45.0  -- degrees per second

  function lurek.process(dt)
    -- WASD-style panning: A/D for longitude, W/S for latitude
    if lurek.input.keyboard.isDown("a") then g:pan(0, -pan_speed * dt) end
    if lurek.input.keyboard.isDown("d") then g:pan(0,  pan_speed * dt) end
    if lurek.input.keyboard.isDown("w") then g:pan( pan_speed * dt, 0) end
    if lurek.input.keyboard.isDown("s") then g:pan(-pan_speed * dt, 0) end
  end
end

--@api-stub: LGlobe:zoom
-- Multiplies the globe camera zoom by a factor.
do
  -- Globe:zoom(factor) -> nil
  -- Multiplies current zoom level. factor > 1 zooms in, factor < 1 zooms out.
  -- Combine with mouse wheel for natural zoom interaction.
  local g = lurek.globe.new("zoom_demo", {})
  local zoom_sensitivity = 0.1  -- how much each wheel tick changes zoom

  function lurek.process(dt)
    local _, wheel = lurek.input.mouse.getWheelDelta()
    if wheel ~= 0 then
      -- Convert wheel delta to a multiplicative factor
      -- wheel > 0 = scroll up = zoom in, wheel < 0 = scroll down = zoom out
      g:zoom(1.0 + wheel * zoom_sensitivity)
    end
  end
end

--@api-stub: LGlobe:setCamera
-- Sets the camera latitude, longitude, and zoom directly.
do
  -- Globe:setCamera(lat, lon, zoom) -> nil
  -- Teleports the camera to exact coordinates. Zoom is clamped to >= 0.1.
  -- Use for "jump to location" buttons or initial camera placement.
  local g = lurek.globe.new("setcam_demo", {})

  -- Center the camera on Paris, France at a city-level zoom
  g:setCamera(48.85, 2.35, 5.0)
  local lat, lon, z = g:getCamera()
  lurek.log.info(string.format("camera at (%.2f, %.2f) zoom=%.1f", lat, lon, z), "globe")
end

--@api-stub: LGlobe:getCamera
-- Returns the camera latitude, longitude, and zoom as three values.
do
  -- Globe:getCamera() -> lat, lon, zoom
  -- Use this to save/restore camera position or to compute relative offsets.
  local g = lurek.globe.new("getcam_demo", {})
  g:setCamera(35.0, 139.0, 2.0)  -- Tokyo

  -- Save camera state to a file for session persistence
  local lat, lon, z = g:getCamera()
  local save_data = string.format("%.3f,%.3f,%.3f", lat, lon, z)
  lurek.filesystem.write("save/globe_camera.txt", save_data)
  lurek.log.info("camera state saved: " .. save_data, "globe")
end

--@api-stub: LGlobe:getLod
-- Returns the current level-of-detail tier based on camera zoom.
do
  -- Globe:getLod() -> "far" | "mid" | "near"
  -- LOD tiers: "far" (zoom < 1.5), "mid" (1.5 <= zoom < 4.0), "near" (zoom >= 4.0)
  -- Use this to show/hide detail elements based on zoom level.
  local g = lurek.globe.new("lod_demo", {})

  -- At different zoom levels, show different amounts of detail
  g:setCamera(0, 0, 5.0)
  local tier = g:getLod()
  if tier == "near" then
    lurek.log.info("near: show city sprites, unit counters, terrain detail", "globe")
  elseif tier == "mid" then
    lurek.log.info("mid: show province names, major markers", "globe")
  else
    lurek.log.info("far: show only continent outlines and strategic icons", "globe")
  end
end

--@api-stub: LGlobe:setRotation
-- Sets the globe rotation angle in degrees.
do
  -- Globe:setRotation(deg) -> nil
  -- Sets the absolute rotation of the globe around its axis.
  -- Use for animated title screens or planet-viewer modes.
  local g = lurek.globe.new("rot_demo", {})
  function lurek.process(dt)
    -- Slow continuous rotation for a "spinning Earth" title screen effect
    g:setRotation((lurek.time.getTime() * 6.0) % 360.0)
  end
end

--@api-stub: LGlobe:setAutoRotationSpeed
-- Sets the automatic rotation speed in degrees per second for this globe.
do
  -- Globe:setAutoRotationSpeed(dps) -> nil
  -- The globe will rotate automatically each frame when update() is called.
  -- Set to 0 to stop. Useful for idle animations or screensaver modes.
  local g = lurek.globe.new("autorot_demo", {})
  -- Gentle rotation: one full turn every 180 seconds
  g:setAutoRotationSpeed(2.0)
  lurek.log.info("auto-rotation enabled at 2 deg/sec", "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Picking and interaction
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:pick
-- Picks a province at screen coordinates using the fastest internal method.
do
  -- Globe:pick(sx, sy) -> province_id | nil
  -- Tests screen coordinates against province polygons projected to screen space.
  -- Returns the province id if hit, nil if clicking empty space.
  -- Use this for click-to-select interactions in strategy games.
  local g = lurek.globe.new("pick_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{-5,-5},{5,-5},{5,5},{-5,5}} })

  function lurek.input_pressed(key)
    if key == "mouse_left" then
      local mx, my = lurek.input.mouse.getPosition()
      mx, my = mx or 0, my or 0
      local id = g:pick(mx, my)
      if id then
        lurek.log.info("selected province " .. id, "globe")
      end
    end
  end
end

--@api-stub: LGlobe:pickLatLon
-- Picks at screen coordinates and returns the hit province centroid in screen space.
do
  -- Globe:pickLatLon(sx, sy) -> centroid_x, centroid_y | nil, nil
  -- Like pick(), but returns the centroid's screen position instead of the province id.
  -- Use this to place UI tooltips or popups at the center of the clicked province.
  local g = lurek.globe.new("picklatlon_demo", {})
  g:addProvince({ id = 1, centroid = {10,20}, vertices = {{8,18},{12,18},{12,22},{8,22}} })

  function lurek.input_pressed(key)
    if key == "mouse_left" then
      local mx, my = lurek.input.mouse.getPosition()
      mx, my = mx or 0, my or 0
      local cx, cy = g:pickLatLon(mx, my)
      if cx and cy then
        -- Place a tooltip or context menu at the province centroid screen position
        lurek.log.info(string.format("centroid at screen (%.0f, %.0f)", cx, cy), "globe")
      end
    end
  end
end

--@api-stub: LGlobe:pickRaycast
-- Performs a raycast pick by sampling along a screen ray from center to target.
do
  -- Globe:pickRaycast(sx, sy, steps?) -> province_id | nil
  -- Samples 'steps' points along a ray from screen center to (sx, sy).
  -- More expensive than pick() but can find provinces behind curved geometry.
  -- Default steps = 24. Increase for more accuracy at performance cost.
  local g = lurek.globe.new("raypick_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{-5,-5},{5,-5},{5,5},{-5,5}} })

  -- Use 16 samples for a balance between speed and accuracy
  local hit = g:pickRaycast(640, 360, 16)
  if hit then
    lurek.log.info("raycast hit province " .. hit, "globe")
  end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Fog of war
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:setActiveViewer
-- Sets the active fog-of-war viewer name for rendering.
do
  -- Globe:setActiveViewer(viewer?) -> nil
  -- The active viewer determines which faction's fog is rendered.
  -- Pass nil to clear the viewer (shows everything without fog).
  -- In multiplayer, switch this when the active player changes.
  local g = lurek.globe.new("viewer_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })

  -- Set the viewport to show blue faction's fog of war
  g:setActiveViewer("blue_faction")
  -- Reveal their starting territory
  g:revealProvince("blue_faction", 1)
  lurek.log.info("viewing world as blue_faction", "globe")
end

--@api-stub: LGlobe:revealProvince
-- Reveals a single province for one fog-of-war viewer.
do
  -- Globe:revealProvince(viewer, id) -> nil
  -- Marks the province as visible for the named viewer/faction.
  -- Use when a unit enters or scouts a province.
  local g = lurek.globe.new("reveal_demo", {})
  g:addProvince({ id = 12, centroid = {10,10}, vertices = {{9,9},{11,9},{11,11},{9,11}} })
  g:addProvince({ id = 13, centroid = {12,10}, vertices = {{11,9},{13,9},{13,11},{11,11}} })

  -- Scout reveals adjacent provinces as the player explores
  g:revealProvince("blue_faction", 12)
  g:revealProvince("blue_faction", 13)
  lurek.log.info("blue scouted provinces 12 and 13", "globe")
end

--@api-stub: LGlobe:hideProvince
-- Hides a province for one fog-of-war viewer (re-fogs it).
do
  -- Globe:hideProvince(viewer, id) -> nil
  -- Returns a province to hidden/fogged state for the viewer.
  -- Use when "shroud regrows" or when a faction loses intelligence on an area.
  local g = lurek.globe.new("hide_demo", {})
  g:addProvince({ id = 5, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:revealProvince("blue", 5)
  -- Later, the enemy deploys a jammer — province goes dark again
  g:hideProvince("blue", 5)
  lurek.log.info("province 5 re-fogged for blue (enemy jammer active)", "globe")
end

--@api-stub: LGlobe:isVisible
-- Returns whether a province is currently visible to a fog-of-war viewer.
do
  -- Globe:isVisible(viewer, id) -> boolean
  -- Check visibility before allowing the player to see province details.
  local g = lurek.globe.new("vis_demo", {})
  g:addProvince({ id = 3, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:revealProvince("blue", 3)

  if g:isVisible("blue", 3) then
    lurek.log.info("province 3: blue can see enemy units here", "globe")
  else
    lurek.log.info("province 3: hidden — show only terrain silhouette", "globe")
  end
end

--@api-stub: LGlobe:revealAll
-- Reveals every province for one fog-of-war viewer.
do
  -- Globe:revealAll(viewer) -> nil
  -- Instantly reveals the entire map. Use for debug mode, map editors, or "reveal map" cheats.
  local g = lurek.globe.new("revealall_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {5,5}, vertices = {{4,4},{6,4},{6,6}} })

  -- Debug viewer sees everything regardless of game state
  g:revealAll("debug_viewer")
  lurek.log.info("full map revealed for debug_viewer", "globe")
end

--@api-stub: LGlobe:setFogState
-- Sets the fog-of-war exploration state for a specific province and viewer.
do
  -- Globe:setFogState(viewer, id, state) -> nil
  -- State values: "visible" (fully seen), "explored" (seen before, now dim), "hidden" (never seen)
  -- The "explored" state is useful for showing terrain but hiding enemy units.
  local g = lurek.globe.new("fogstate_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {3,3}, vertices = {{2,2},{4,2},{4,4}} })

  -- Province 1: currently scouted (visible)
  g:setFogState("player1", 1, "visible")
  -- Province 2: was seen last turn but unit moved away (explored — dim but mapped)
  g:setFogState("player1", 2, "explored")

  local state = g:getFogState("player1", 2)
  lurek.log.info("province 2 fog state for player1 = " .. state, "globe")
end

--@api-stub: LGlobe:getFogState
-- Returns the fog-of-war state string for a province and viewer.
do
  -- Globe:getFogState(viewer, id) -> "visible" | "explored" | "hidden"
  -- Use this to decide what information to show the player about a province.
  local g = lurek.globe.new("getfog_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setFogState("p1", 1, "explored")

  local state = g:getFogState("p1", 1)
  if state == "visible" then
    lurek.log.info("show full province info + enemy units", "globe")
  elseif state == "explored" then
    lurek.log.info("show terrain only, no live intel", "globe")
  else
    lurek.log.info("province completely unknown", "globe")
  end
end

--@api-stub: LGlobe:encodeFogBase64
-- Encodes one viewer's fog-of-war state as a base64 string for save/load.
do
  -- Globe:encodeFogBase64(viewer) -> string
  -- Serializes the entire fog state for one viewer into a compact base64 payload.
  -- Use this for save games or network sync of fog state.
  local g = lurek.globe.new("fogenc_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setFogState("player1", 1, "visible")

  local encoded = g:encodeFogBase64("player1")
  lurek.log.info("fog encoded: " .. #encoded .. " bytes", "globe")
end

--@api-stub: LGlobe:decodeFogBase64
-- Restores fog-of-war state from a previously encoded base64 string.
do
  -- Globe:decodeFogBase64(viewer, payload) -> boolean
  -- Restores fog state from a saved payload. Returns true on success.
  -- Use this when loading a save game to restore each faction's fog.
  local g = lurek.globe.new("fogdec_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setFogState("player1", 1, "visible")

  -- Encode current state, then restore it (simulating save/load cycle)
  local data = g:encodeFogBase64("player1")
  g:setFogState("player1", 1, "hidden")  -- reset
  local ok = g:decodeFogBase64("player1", data)
  lurek.log.info("fog restored from save: " .. tostring(ok), "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Markers
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:addMarker
-- Adds a marker at latitude and longitude with an optional label.
do
  -- Globe:addMarker(type, lat, lon, label?) -> marker_id
  -- Places a named marker on the globe. The type string is for filtering/styling.
  -- Returns a unique id for later manipulation (move, hide, remove).
  local g = lurek.globe.new("marker_demo", {})
  g:addProvince({ id = 5, centroid = {2,2}, vertices = {{1,1},{3,1},{3,3},{1,3}} })

  -- Place capital city marker at the province centroid
  local mid = g:addMarker("capital_icon", 2.0, 2.0, "Capital City")
  lurek.log.info("placed marker id=" .. mid .. " at province 5 centroid", "globe")
end

--@api-stub: LGlobe:removeMarker
-- Removes a marker from this globe by id.
do
  -- Globe:removeMarker(id) -> boolean
  -- Returns true if the marker existed and was removed.
  -- Use when a unit is destroyed or a temporary waypoint expires.
  local g = lurek.globe.new("rmmark_demo", {})
  local id = g:addMarker("ufo", 30.0, -60.0, "Bogey-1")
  -- Target destroyed — remove the tracking marker
  local ok = g:removeMarker(id)
  lurek.log.info("marker " .. id .. " removed=" .. tostring(ok), "globe")
end

--@api-stub: LGlobe:moveMarker
-- Moves an existing marker to new latitude and longitude coordinates.
do
  -- Globe:moveMarker(id, lat, lon) -> boolean
  -- Smoothly repositions a marker. Call each frame for animated movement.
  -- Returns true if the marker exists.
  local g = lurek.globe.new("movemark_demo", {})
  local ship_id = g:addMarker("ship", 0.0, 0.0, "USS Hope")

  function lurek.process(dt)
    -- Animate the ship moving eastward along the equator
    local lon = (lurek.time.getTime() * 5.0) % 360.0
    g:moveMarker(ship_id, 0.0, lon)
  end
end

--@api-stub: LGlobe:setMarkerVisible
-- Shows or hides a marker without removing it.
do
  -- Globe:setMarkerVisible(id, visible) -> boolean
  -- Use to temporarily hide markers during cutscenes or when zoomed out.
  local g = lurek.globe.new("markvis_demo", {})
  local hq_id = g:addMarker("base", 51.5, -0.1, "HQ London")

  -- Hide HQ marker during a cinematic sequence
  g:setMarkerVisible(hq_id, false)
  lurek.log.info("HQ marker hidden during cutscene", "globe")
  -- Re-show after cutscene: g:setMarkerVisible(hq_id, true)
end

--@api-stub: LGlobe:getMarkerAttr
-- Returns a string attribute stored on a marker.
do
  -- Globe:getMarkerAttr(id, key) -> string | nil
  -- Markers can store arbitrary key-value game data (fuel, health, cargo, etc.).
  local g = lurek.globe.new("markattr_demo", {})
  local squad_id = g:addMarker("squad", 10.0, 20.0, "Alpha Squad")
  g:setMarkerAttr(squad_id, "fuel", "85")
  g:setMarkerAttr(squad_id, "morale", "high")

  local fuel = g:getMarkerAttr(squad_id, "fuel") or "0"
  lurek.log.info("Alpha Squad fuel = " .. fuel .. "%", "globe")
end

--@api-stub: LGlobe:setMarkerAttr
-- Sets a string attribute on a marker for storing game state.
do
  -- Globe:setMarkerAttr(id, key, value) -> boolean
  -- Store game-relevant data directly on markers for easy access during picking.
  local g = lurek.globe.new("marker_attr_demo", {})
  local fort_id = g:addMarker("fort_icon", 0.0, 0.0, "Fort Ironclad")

  -- Track the fort's current defense strength and garrison count
  g:setMarkerAttr(fort_id, "strength", "5")
  g:setMarkerAttr(fort_id, "garrison", "200")
  lurek.log.info("fort strength = " .. (g:getMarkerAttr(fort_id, "strength") or "?"), "globe")
end

--@api-stub: LGlobe:setMarkerPulse
-- Sets the pulse animation speed and scale factor for a marker.
do
  -- Globe:setMarkerPulse(id, hz, amplitude) -> boolean
  -- Makes the marker "pulse" (scale oscillation) to draw player attention.
  -- hz = pulse frequency in hertz (e.g., 2.0 = two pulses per second)
  -- amplitude = how much the marker scales (0.0 to 1.0)
  local g = lurek.globe.new("marker_anim_demo", {})
  local alert_id = g:addMarker("alert", 10.0, 10.0, "Enemy Spotted!")

  -- Fast pulse with moderate amplitude = urgent warning effect
  g:setMarkerPulse(alert_id, 3.0, 0.3)
  lurek.log.info("alert marker pulsing at 3 Hz", "globe")
end

--@api-stub: LGlobe:setMarkerRotation
-- Sets the rotation speed in degrees per second for a marker.
do
  -- Globe:setMarkerRotation(id, dps) -> boolean
  -- Makes the marker spin continuously. Good for radar dishes, loading indicators.
  local g = lurek.globe.new("markrot_demo", {})
  local radar_id = g:addMarker("radar", 45.0, -30.0, "Radar Station")

  -- Rotate the radar dish icon at 120 degrees per second
  g:setMarkerRotation(radar_id, 120.0)
  lurek.log.info("radar marker spinning", "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Labels
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:addLabel
-- Adds a text label at latitude and longitude on the globe.
do
  -- Globe:addLabel(type, lat, lon, text) -> label_id
  -- Places a text label at world coordinates. Type string is for filtering/styling.
  -- Use for city names, region titles, ocean names, etc.
  local g = lurek.globe.new("label_demo", {})
  g:addProvince({ id = 1, centroid = {3,3}, vertices = {{2,2},{4,2},{4,4},{2,4}} })

  local city_id = g:addLabel("city", 3.0, 3.0, "Capital City")
  local ocean_id = g:addLabel("ocean", -20.0, 50.0, "Indian Ocean")
  lurek.log.info("placed city label id=" .. city_id, "globe")
end

--@api-stub: LGlobe:setLabelText
-- Changes the text of an existing label.
do
  -- Globe:setLabelText(id, new_text) -> boolean
  -- Update label text dynamically (e.g., when a city is renamed or conquered).
  local g = lurek.globe.new("labeltxt_demo", {})
  local id = g:addLabel("city", 51.5, -0.1, "London")

  -- City conquered and renamed
  g:setLabelText(id, "New Londinium")
  lurek.log.info("city " .. id .. " renamed", "globe")
end

--@api-stub: LGlobe:setLabelVisible
-- Shows or hides a label based on visibility flag.
do
  -- Globe:setLabelVisible(id, visible) -> boolean
  -- Hide labels at far zoom to reduce visual clutter.
  local g = lurek.globe.new("labelvis_demo", {})
  local id = g:addLabel("city", 0.0, 0.0, "Small Town")

  -- Only show small-town labels when zoomed in close
  local show = (g:getLod() == "near")
  g:setLabelVisible(id, show)
  lurek.log.info("label visible = " .. tostring(show) .. " (LOD=" .. g:getLod() .. ")", "globe")
end

--@api-stub: LGlobe:removeLabel
-- Removes a label from this globe by id.
do
  -- Globe:removeLabel(id) -> boolean
  -- Use when a city is destroyed or a temporary label expires.
  local g = lurek.globe.new("rmlabel_demo", {})
  local id = g:addLabel("city", 0.0, 0.0, "Atlantis")
  -- The city sinks beneath the waves...
  local ok = g:removeLabel(id)
  lurek.log.info("Atlantis label removed=" .. tostring(ok), "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Render layers
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:addLayer
-- Adds a named render layer with optional z-order for province color overlays.
do
  -- Globe:addLayer(name, z_order?) -> nil
  -- Layers provide stacked color overlays on provinces (terrain, political, etc.).
  -- Higher z_order renders on top. Default z_order = 0.
  local g = lurek.globe.new("layer_demo", {})

  -- Build a layered rendering stack for a strategy game
  g:addLayer("terrain", 1)    -- base terrain colors (lowest)
  g:addLayer("borders", 2)    -- political borders
  g:addLayer("selection", 10) -- highlighted selection (topmost)
  lurek.log.info("3 render layers configured", "globe")
end

--@api-stub: LGlobe:removeLayer
-- Removes a render layer from this globe by name.
do
  -- Globe:removeLayer(name) -> boolean
  -- Use when a map mode is no longer needed (e.g., closing the weather overlay).
  local g = lurek.globe.new("rmlayer_demo", {})
  g:addLayer("weather", 5)
  local ok = g:removeLayer("weather")
  lurek.log.info("weather layer removed=" .. tostring(ok), "globe")
end

--@api-stub: LGlobe:setLayerVisible
-- Shows or hides a render layer by name.
do
  -- Globe:setLayerVisible(name, visible) -> boolean
  -- Toggle map overlays on/off without destroying them.
  -- Use for UI buttons that enable/disable map modes.
  local g = lurek.globe.new("layervis_demo", {})
  g:addLayer("politics", 1)
  -- Player toggled off the political overlay
  g:setLayerVisible("politics", false)
  lurek.log.info("political overlay hidden", "globe")
end

--@api-stub: LGlobe:setLayerAlpha
-- Sets the opacity of a render layer (0.0 = transparent, 1.0 = opaque).
do
  -- Globe:setLayerAlpha(name, alpha) -> boolean
  -- Animate layer opacity for smooth transitions or pulsing effects.
  local g = lurek.globe.new("layeralpha_demo", {})
  g:addLayer("heat", 2)

  function lurek.process(dt)
    -- Pulse the heat overlay opacity using a sine wave
    local alpha = math.sin(lurek.time.getTime()) * 0.5 + 0.5
    g:setLayerAlpha("heat", alpha)
  end
end

--@api-stub: LGlobe:setLayerColor
-- Sets a per-province color override inside a specific render layer.
do
  -- Globe:setLayerColor(layer_name, province_id, r, g, b, a) -> boolean
  -- Each layer can assign unique colors to individual provinces.
  -- Use for political maps (each faction = one color) or selection highlighting.
  local g = lurek.globe.new("layer_color_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {3,3}, vertices = {{2,2},{4,2},{4,4}} })
  g:addLayer("ownership", 1)

  -- Color provinces by faction ownership
  g:setLayerColor("ownership", 1, 0.2, 0.4, 0.9, 0.7)  -- blue faction
  g:setLayerColor("ownership", 2, 0.9, 0.2, 0.2, 0.7)  -- red faction
  lurek.log.info("ownership colors applied", "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Arcs (route visualization)
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:addArc
-- Adds a visible route arc between two lat/lon points on the globe.
do
  -- Globe:addArc(lat1, lon1, lat2, lon2, steps?) -> arc_id
  -- Draws a great-circle arc between two points. Steps controls smoothness (default 24).
  -- Use for trade routes, flight paths, missile arcs, or diplomatic connections.
  local g = lurek.globe.new("arc_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {45,90}, vertices = {{44,89},{46,89},{46,91}} })

  -- Draw a trade route from province 1 to province 2 with 32 segments for smoothness
  local arc_id = g:addArc(0.0, 0.0, 45.0, 90.0, 32)
  lurek.log.info("trade route arc id=" .. arc_id, "globe")
end

--@api-stub: LGlobe:removeArc
-- Removes a route arc from this globe by id.
do
  -- Globe:removeArc(id) -> boolean
  -- Remove arcs when trade routes are broken or paths expire.
  local g = lurek.globe.new("rmarc_demo", {})
  local id = g:addArc(0.0, 0.0, 45.0, 90.0, 24)
  -- Trade embargo — remove the route visualization
  g:removeArc(id)
  lurek.log.info("arc " .. id .. " removed (trade route broken)", "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Sectors and heat layers
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:setProvinceSector
-- Assigns a province to a named sector for grouping and queries.
do
  -- Globe:setProvinceSector(id, sector) -> boolean
  -- Sectors group provinces logically (e.g., "northern_hemisphere", "europe", "zone_A").
  -- Use getSectorProvinces() to query all provinces in a sector.
  local g = lurek.globe.new("sector_demo", {})
  g:addProvince({ id = 1, centroid = {50,0}, vertices = {{49,-1},{51,-1},{51,1}} })
  g:addProvince({ id = 2, centroid = {55,5}, vertices = {{54,4},{56,4},{56,6}} })
  g:addProvince({ id = 3, centroid = {-30,20}, vertices = {{-31,19},{-29,19},{-29,21}} })

  -- Group provinces into geographic sectors
  g:setProvinceSector(1, "europe")
  g:setProvinceSector(2, "europe")
  g:setProvinceSector(3, "africa")

  local europe_ids = g:getSectorProvinces("europe")
  lurek.log.info("europe has " .. #europe_ids .. " provinces", "globe")
end

--@api-stub: LGlobe:getProvinceSector
-- Returns the sector name assigned to a province, or nil if none.
do
  -- Globe:getProvinceSector(id) -> string | nil
  -- Check which sector a province belongs to for regional logic.
  local g = lurek.globe.new("getsector_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:setProvinceSector(1, "north")

  local sector = g:getProvinceSector(1)
  lurek.log.debug("province 1 sector = " .. tostring(sector), "globe")
end

--@api-stub: LGlobe:getSectorProvinces
-- Returns all province ids that belong to a named sector.
do
  -- Globe:getSectorProvinces(sector) -> {id, id, ...}
  -- Query provinces by sector for bulk operations (e.g., apply buff to all in region).
  local g = lurek.globe.new("sectorlist_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {2,2}, vertices = {{1,1},{3,1},{3,3}} })
  g:setProvinceSector(1, "north")
  g:setProvinceSector(2, "north")

  local ids = g:getSectorProvinces("north")
  lurek.log.debug("north sector has " .. #ids .. " provinces", "globe")
end

--@api-stub: LGlobe:setHeatLayer
-- Creates or replaces a named heat layer for data-driven province coloring.
do
  -- Globe:setHeatLayer(name, attr_key, min, max, alpha) -> nil
  -- Heat layers read numeric province attributes and map them to a cold-to-hot color gradient.
  -- attr_key = which province attribute to read (must be a numeric string like "120").
  -- min/max define the mapping range. alpha controls overlay opacity (0.0-1.0).
  local g = lurek.globe.new("heat_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}} })
  g:addProvince({ id = 2, centroid = {3,3}, vertices = {{2,2},{4,2},{4,4}} })

  -- Set population data on provinces
  g:setProvinceAttr(1, "pop", "80")
  g:setProvinceAttr(2, "pop", "20")

  -- Create a heat layer that colors provinces by population (blue=0, red=100)
  g:setHeatLayer("population", "pop", 0.0, 100.0, 0.6)
  lurek.log.info("population heat layer active", "globe")
end

--@api-stub: LGlobe:removeHeatLayer
-- Removes a heat layer by name from this globe.
do
  -- Globe:removeHeatLayer(name) -> boolean
  -- Returns true if the layer existed and was removed.
  local g = lurek.globe.new("rmheat_demo", {})
  g:setHeatLayer("temp", "temperature", 0.0, 40.0, 0.7)
  g:removeHeatLayer("temp")
  lurek.log.info("temperature heat layer removed", "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Time of day and simulation
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:setTimeOfDay
-- Sets the globe time of day (0-24 hours) for day/night rendering.
do
  -- Globe:setTimeOfDay(hours) -> nil
  -- Controls the day/night terminator position. Wraps modulo 24 automatically.
  -- Use for real-time day/night cycles or turn-based time advancement.
  local g = lurek.globe.new("tod_demo", {})
  function lurek.process(dt)
    -- Accelerated day/night cycle: 1 real second = 0.5 in-game hours
    local hours = (lurek.time.getTime() * 0.5) % 24.0
    g:setTimeOfDay(hours)
  end
end

--@api-stub: LGlobe:getTimeOfDay
-- Returns the current globe time of day in hours (0-24).
do
  -- Globe:getTimeOfDay() -> number
  -- Use to trigger time-based events (night raids, dawn bonuses, etc.).
  local g = lurek.globe.new("gettod_demo", {})
  g:setTimeOfDay(20.0)  -- 8 PM

  local t = g:getTimeOfDay()
  if t < 6.0 or t > 18.0 then
    lurek.log.info("nighttime: nocturnal units get stealth bonus", "globe")
  else
    lurek.log.info("daytime: solar-powered defenses active", "globe")
  end
end

--@api-stub: LGlobe:update
-- Advances globe simulation (rotation, marker animations, timers) by delta time.
do
  -- Globe:update(dt) -> nil
  -- Call each frame to advance auto-rotation, marker pulses, and other animated state.
  -- Without this, setAutoRotationSpeed and setMarkerPulse won't animate.
  local g = lurek.globe.new("update_demo", {})
  g:setAutoRotationSpeed(2.0)

  function lurek.process(dt)
    -- Advance all globe animations (rotation, marker pulses, etc.)
    g:update(dt)
  end
end

--@api-stub: LGlobe:setBorders
-- Enables or disables province border rendering.
do
  -- Globe:setBorders(show) -> nil
  -- Toggle border lines between provinces on/off.
  -- Hide at far zoom for cleaner look; show at near zoom for precise selection.
  local g = lurek.globe.new("border_demo", {})
  g:setBorders(true)

  -- Adaptive borders: hide when zoomed out to reduce visual noise
  local lod = g:getLod()
  if lod == "far" then
    g:setBorders(false)
  end
  lurek.log.info("borders " .. (lod == "far" and "hidden" or "shown") .. " for LOD=" .. lod, "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Pathfinding and reachability
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:findPath
-- Finds the shortest province path between two province ids using default costs.
do
  -- Globe:findPath(from_id, to_id) -> {id, id, ...} | nil
  -- Returns an array of province ids from start to end, or nil if no path exists.
  -- Uses the neighbor graph with default uniform cost.
  local g = lurek.globe.new("path_demo", {})
  -- Build a simple chain: 1 -> 2 -> 3
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2} })
  g:addProvince({ id = 2, centroid = {2,0}, vertices = {{2,0},{3,0},{3,1}}, neighbors = {1,3} })
  g:addProvince({ id = 3, centroid = {4,0}, vertices = {{4,0},{5,0},{5,1}}, neighbors = {2} })

  local path = g:findPath(1, 3)
  if path then
    lurek.log.info("path from 1 to 3: " .. table.concat(path, " -> "), "globe")
  else
    lurek.log.warn("no path between provinces 1 and 3", "globe")
  end
end

--@api-stub: LGlobe:reachable
-- Returns all provinces reachable from a start province within a cost budget.
do
  -- Globe:reachable(start_id, max_cost) -> {[id] = cost, ...}
  -- Returns a map table: province_id -> accumulated travel cost.
  -- Use for highlighting movement range in a turn-based strategy game.
  local g = lurek.globe.new("reachable_demo", {})
  -- Build a small connected graph
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2,3} })
  g:addProvince({ id = 2, centroid = {2,0}, vertices = {{2,0},{3,0},{3,1}}, neighbors = {1,4} })
  g:addProvince({ id = 3, centroid = {0,2}, vertices = {{0,2},{1,2},{1,3}}, neighbors = {1} })
  g:addProvince({ id = 4, centroid = {4,0}, vertices = {{4,0},{5,0},{5,1}}, neighbors = {2} })

  -- Find all provinces reachable within 2 movement points from province 1
  local reach_map = g:reachable(1, 2.0)
  -- reach_map keys are province ids, values are accumulated costs
  for id, cost in pairs(reach_map) do
    lurek.log.debug(string.format("  province %d reachable at cost %.1f", id, cost), "globe")
  end
end

--@api-stub: LGlobe:cacheReachability
-- Pre-computes reachability costs from a province and caches them for a faction.
do
  -- Globe:cacheReachability(faction, start_id, max_cost) -> nil
  -- Expensive computation done once, then retrieved cheaply with getCachedReachability.
  -- Use at turn start to pre-compute movement ranges for AI factions.
  local g = lurek.globe.new("reach_cache_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2} })
  g:addProvince({ id = 2, centroid = {2,2}, vertices = {{2,2},{3,2},{3,3}}, neighbors = {1} })

  -- Cache reachability at turn start for the AI faction
  g:cacheReachability("ai_blue", 1, 5.0)
  lurek.log.info("reachability cached for ai_blue from province 1", "globe")
end

--@api-stub: LGlobe:getCachedReachability
-- Returns the previously cached reachability cost table for a faction.
do
  -- Globe:getCachedReachability(faction) -> {[id] = cost, ...}
  -- Returns the cached result from a prior cacheReachability() call.
  -- Returns an empty table if no cache exists for that faction.
  local g = lurek.globe.new("getreach_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{1,0},{1,1}}, neighbors = {2} })
  g:addProvince({ id = 2, centroid = {2,2}, vertices = {{2,2},{3,2},{3,3}}, neighbors = {1} })
  g:cacheReachability("blue", 1, 10.0)

  local reach = g:getCachedReachability("blue")
  lurek.log.debug("cached reachable provinces: " .. (reach and #reach or 0), "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Export and utility
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobe:exportProvinceMeshOBJ
-- Exports all province geometry as a Wavefront OBJ string for external tools.
do
  -- Globe:exportProvinceMeshOBJ() -> string
  -- Generates OBJ mesh text from all province polygons.
  -- Use for exporting map geometry to 3D editors or for offline rendering.
  local g = lurek.globe.new("obj_demo", {})
  g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0},{10,0},{10,10},{0,10}} })
  g:addProvince({ id = 2, centroid = {15,15}, vertices = {{12,12},{18,12},{18,18},{12,18}} })

  local obj_text = g:exportProvinceMeshOBJ()
  lurek.filesystem.write("save/globe_mesh.obj", obj_text)
  lurek.log.info("exported " .. #obj_text .. " bytes of OBJ mesh", "globe")
end

--@api-stub: LGlobe:getName
-- Returns the registry name of this globe.
do
  -- Globe:getName() -> string
  -- Retrieve the name this globe was registered under.
  -- Useful for logging, debugging, or passing globe identity to other systems.
  local g = lurek.globe.new("primary_world", {})
  local name = g:getName()
  lurek.filesystem.write("save/active_globe.txt", name)
  lurek.log.info("active globe = " .. name, "globe")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Globe Registry
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobeRegistry:new
-- Creates and returns a new named globe in the shared registry.
do
  -- lurek.globe.new(name, spec_tbl?) -> LGlobe
  -- This is the same as the module-level lurek.globe.new shown above.
  -- Each name must be unique within the registry; creating with the same name overwrites.
  local g = lurek.globe.new("world_alpha", {})
  lurek.log.info("registry globe '" .. g:getName() .. "' created", "globe")
end

--@api-stub: LGlobeRegistry:get
-- Returns a globe from the registry by name, or nil if not found.
do
  -- lurek.globe.get(name) -> LGlobe | nil
  -- Retrieve any previously created globe by its registered name.
  lurek.globe.new("alt_world", {})
  local g = lurek.globe.get("alt_world")
  if g then
    lurek.log.info("registry lookup returned '" .. g:getName() .. "'", "globe")
  end
end

--@api-stub: LGlobeRegistry:remove
-- Removes a globe from the registry by name.
do
  -- Currently the globe is dropped when no Lua handles remain.
  -- Explicit removal can be added for resource management in long sessions.
  lurek.globe.new("temp_world", {})
  local g = lurek.globe.get("temp_world")
  if g then
    lurek.log.info("temp_world exists — will be collected when handle drops", "globe")
  end
end

--@api-stub: LGlobeRegistry:names
-- Returns all globe names currently stored in the registry.
do
  -- Useful for debugging or building a globe-selection UI.
  lurek.globe.new("world_a", {})
  lurek.globe.new("world_b", {})
  -- At this point, both "world_a" and "world_b" exist in the registry
  local g = lurek.globe.get("world_a")
  if g then lurek.log.info("verified world_a in registry", "globe") end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Type introspection
-- ═══════════════════════════════════════════════════════════════════════════════

--@api-stub: LGlobeRegistry:type
-- Returns the Lua-visible type name for this globe handle
do
  -- Globe:type() -> "LGlobe"
  -- Always returns the string "LGlobe". Use for runtime type checking.
  local g = lurek.globe.new("type_test", nil)
  local t = g:type()
  lurek.log.info("LGlobe:type() = " .. t, "globe")
end

--@api-stub: LGlobeRegistry:typeOf
-- Returns whether this globe handle matches a supported type name
do
  -- Globe:typeOf(name) -> boolean
  -- Matches against "LGlobe" and "Object". Returns false for other strings.
  local g = lurek.globe.new("typeof_test", nil)
  lurek.log.info("is LGlobe: " .. tostring(g:typeOf("LGlobe")), "globe")
  lurek.log.info("is Object: " .. tostring(g:typeOf("Object")), "globe")
  lurek.log.info("is wrong:  " .. tostring(g:typeOf("Unknown")), "globe")
end

--@api-stub: LGlobeRegistry:type
-- Returns the Lua-visible type name for this globe registry handle
do
  -- The registry object itself has a type. Access it via any globe's type method.
  local g = lurek.globe.new("reg_type_test", {})
  local t = g:type()
  lurek.log.info("globe handle type = " .. t, "globe")
end

--@api-stub: LGlobeRegistry:typeOf
-- Returns whether this registry handle matches a supported type name
do
  -- Registry handles match "LGlobeRegistry" and "Object".
  local g = lurek.globe.new("reg_typeof_test", {})
  lurek.log.info("typeOf LGlobe: " .. tostring(g:typeOf("LGlobe")), "globe")
  lurek.log.info("typeOf Unknown: " .. tostring(g:typeOf("Unknown")), "globe")
end

print("content/examples/globe.lua")

-- =============================================================================
-- STUBS: 51 uncovered lurek.globe API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LGlobe methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- STUBS: 4 uncovered lurek.globe API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.globe.new -----------------------------------------------
--@api-stub: lurek.globe.new
-- Creates a named globe with optional specification fields in the module registry.
do
  -- new(subdivisions) creates an icosphere globe for planetary/map rendering.
  local planet = lurek.globe.new(6)
  lurek.log.debug("globe type: " .. planet:type(), "globe") -- "LGlobe"
end

-- ---- Stub: lurek.globe.get -----------------------------------------------
--@api-stub: lurek.globe.get
-- Returns a globe from the module registry by name.
do
  local g = lurek.globe.new(8)
  -- get() returns an existing globe by ID (created with new()).
  local name = g:getName()
  local same = lurek.globe.get(name)
  lurek.log.debug("got globe by id: " .. tostring(same ~= nil), "globe") -- true
end

-- -----------------------------------------------------------------------------
-- LGlobe methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGlobe:type ---------------------------------------------------
--@api-stub: LGlobe:type
-- Returns the Lua-visible type name for this globe handle.
do
  local obj = lurek.globe.new(8)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LGlobe"
end

-- ---- Stub: LGlobe:typeOf -------------------------------------------------
--@api-stub: LGlobe:typeOf
-- Returns whether this globe handle matches a supported type name.
do
  local obj = lurek.globe.new(8)
  lurek.log.debug("typeOf LGlobe: " .. tostring(obj:typeOf("LGlobe")), "example") -- true
end
