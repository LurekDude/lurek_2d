-- content/examples/globe.lua
-- XCOM-style Geoscape Globe Example
-- Demonstrates the lurek.globe.* API: province management, camera,
-- fog of war, markers, labels, layers, path-finding, and arcs.
--
-- To run:  lurek2d content/examples/globe.lua

local globe_mod = lurek.globe

-- ──────────────────────────────────────────────────────────────
-- 1. Create a globe
-- ──────────────────────────────────────────────────────────────
local g = globe_mod.new("world", {
    radius          = 300.0,    -- display radius in screen units
    axial_tilt_deg  = 23.5,
    time_of_day     = 12.0,     -- noon
    render_borders  = true,
    border_width    = 1.5,
    ambient         = 0.15,     -- dark side minimum
})

-- ──────────────────────────────────────────────────────────────
-- 2. Add some provinces (normally you'd load from a TOML file)
-- ──────────────────────────────────────────────────────────────
local EUROPE_PROVINCES = {
    {
        id = 1,
        centroid = {51.5, -0.1},    -- {lat, lon}
        vertices = {
            {50.0, -2.0}, {50.0, 2.0}, {53.0, 2.0}, {53.0, -2.0},
        },
        neighbors = {2, 3},
        base_color = {0.30, 0.55, 0.35, 1.0},  -- green
    },
    {
        id = 2,
        centroid = {48.8, 2.3},    -- Paris
        vertices = {
            {47.0, 0.5}, {47.0, 4.5}, {50.5, 4.5}, {50.5, 0.5},
        },
        neighbors = {1, 3},
        base_color = {0.55, 0.30, 0.30, 1.0},  -- red
    },
    {
        id = 3,
        centroid = {52.5, 13.4},   -- Berlin
        vertices = {
            {51.0, 11.5}, {51.0, 15.5}, {54.0, 15.5}, {54.0, 11.5},
        },
        neighbors = {1, 2},
        base_color = {0.30, 0.40, 0.60, 1.0},  -- blue
    },
}

for _, p in ipairs(EUROPE_PROVINCES) do
    g:addProvince(p)
end

print("Province count:", g:provinceCount())   --> 3

-- ──────────────────────────────────────────────────────────────
-- 3. Province attributes
-- ──────────────────────────────────────────────────────────────
g:setProvinceAttr(1, "owner",      "player1")
g:setProvinceAttr(1, "population", "8700000")
g:setProvinceAttr(2, "owner",      "player2")
g:setProvinceAttr(3, "owner",      "neutral")

print("London owner:", g:getProvinceAttr(1, "owner"))   --> player1

-- ──────────────────────────────────────────────────────────────
-- 4. Camera
-- ──────────────────────────────────────────────────────────────
g:setCamera(51.0, 5.0, 3.0)    -- look at central Europe, zoom ×3
local lat, lon, zoom = g:getCamera()
print(string.format("Camera: lat=%.1f  lon=%.1f  zoom=%.1f", lat, lon, zoom))

print("LOD:", g:getLod())   --> "near" at zoom 3.0

-- ──────────────────────────────────────────────────────────────
-- 5. Fog of war
-- ──────────────────────────────────────────────────────────────
g:revealProvince("player1", 1)   -- player1 sees London
g:revealProvince("player1", 2)   -- player1 sees Paris
-- Berlin (3) remains hidden for player1

print("p1 sees London:",  g:isVisible("player1", 1))  --> true
print("p1 sees Berlin:",  g:isVisible("player1", 3))  --> false

g:setActiveViewer("player1")   -- only visible provinces are drawn

-- ──────────────────────────────────────────────────────────────
-- 6. Markers
-- ──────────────────────────────────────────────────────────────
local london_id  = g:addMarker("capital",  51.5, -0.1, "London")
local paris_id   = g:addMarker("capital",  48.8,  2.3, "Paris")
local unit_id    = g:addMarker("unit",     51.0,  1.0)   -- no label
g:setMarkerAttr(unit_id, "type",  "infantry")
g:setMarkerAttr(unit_id, "owner", "player1")

-- Move the unit one step east
g:moveMarker(unit_id, 51.0, 3.0)

print("Unit type:", g:getMarkerAttr(unit_id, "type"))   --> infantry

-- ──────────────────────────────────────────────────────────────
-- 7. Labels
-- ──────────────────────────────────────────────────────────────
local region_id = g:addLabel("region", 50.0, 2.0, "Western Europe")
g:setLabelText(region_id, "W. Europe")   -- shorter alias

-- ──────────────────────────────────────────────────────────────
-- 8. Thematic layer (political ownership)
-- ──────────────────────────────────────────────────────────────
g:addLayer("political", 1)

-- Tint player1 provinces blue, player2 provinces red
local owner_colors = {
    player1 = {0.20, 0.40, 0.80, 0.60},
    player2 = {0.80, 0.20, 0.20, 0.60},
}

for id = 1, 3 do
    local owner = g:getProvinceAttr(id, "owner")
    if owner_colors[owner] then
        local c = owner_colors[owner]
        g:setLayerColor("political", id, c[1], c[2], c[3], c[4])
    end
end

-- ──────────────────────────────────────────────────────────────
-- 9. Arc (great-circle route London → Berlin)
-- ──────────────────────────────────────────────────────────────
local arc_id = g:addArc(51.5, -0.1, 52.5, 13.4, 16)
print("Arc ID:", arc_id)

-- ──────────────────────────────────────────────────────────────
-- 10. Path finding
-- ──────────────────────────────────────────────────────────────
local path = g:findPath(1, 3)   -- London → Berlin
if path then
    io.write("Path London → Berlin: ")
    for i, id in ipairs(path) do
        io.write((i == 1 and "" or " → ") .. id)
    end
    io.write("\n")
else
    print("No path found")
end

-- Reachable provinces within 2 steps from London
local reached = g:reachable(1, 2.0)
io.write("Reachable from London (max cost 2): ")
for id, cost in pairs(reached) do
    io.write(string.format("%d(%.1f) ", id, cost))
end
io.write("\n")

-- ──────────────────────────────────────────────────────────────
-- 11. Math helpers
-- ──────────────────────────────────────────────────────────────
local dist_rad = globe_mod.greatCircleDistance(51.5, -0.1, 52.5, 13.4)
print(string.format("London → Berlin: %.4f rad (%.1f km)",
    dist_rad, dist_rad * 6371.0))

local pt = globe_mod.latLonToUnit(51.5, -0.1)
print(string.format("London unit vector: (%.3f, %.3f, %.3f)", pt[1], pt[2], pt[3]))

-- ──────────────────────────────────────────────────────────────
-- 12. Simulation update
-- ──────────────────────────────────────────────────────────────
print(string.format("Time before update: %.1f h", g:getTimeOfDay()))
g:update(3600.0)   -- advance 1 simulated hour
print(string.format("Time after  update: %.1f h", g:getTimeOfDay()))

-- ──────────────────────────────────────────────────────────────
-- 13. Emit render frame (returns a table of RenderCommand values)
-- ──────────────────────────────────────────────────────────────
-- In a real game this is called inside your lurek.callbacks.draw handler.
-- Pass a FontKey to enable label/marker text rendering.
-- Pass nil to suppress text (useful if you handle text drawing separately).
--
--   function lurek.callbacks.draw()
--       local cmds = g:emitFrame(nil)
--       -- submit cmds to the render pipeline (engine handles this automatically
--       -- when Globe is attached to the current scene)
--   end

-- ──────────────────────────────────────────────────────────────
-- 14. Camera pan and zoom
-- ──────────────────────────────────────────────────────────────
-- pan adjusts the camera's look-at point by a delta in degrees —
-- ideal for responding to mouse drag or gamepad stick input
-- without recomputing the full camera position each frame.
g:pan(-5.0, 10.0)   -- shift 5° south, 10° east
local lat2, lon2, zoom2 = g:getCamera()
print(string.format("After pan: lat=%.1f  lon=%.1f  zoom=%.1f", lat2, lon2, zoom2))

-- zoom multiplies the current zoom factor — >1.0 zooms in, <1.0 zooms out.
-- Clamp or constrain the factor outside this call to set zoom limits.
g:zoom(0.5)   -- zoom out by half
local _, _, zoom_after = g:getCamera()
print(string.format("After zoom ×0.5: zoom=%.1f", zoom_after))
g:zoom(2.0)   -- restore
g:setCamera(51.0, 5.0, 3.0)   -- reset to original position

-- ──────────────────────────────────────────────────────────────
-- 15. Province neighbor list
-- ──────────────────────────────────────────────────────────────
-- getNeighbors returns the IDs declared in a province's neighbor
-- array — the same topology used by findPath and reachable.
-- Use it to enumerate adjacent territories when implementing
-- supply-line checks or custom spreading logic.
local nbrs = g:getNeighbors(1)   -- London's declared neighbors
io.write("London neighbors: ")
for _, nid in ipairs(nbrs) do io.write(nid .. " ") end
io.write("\n")   --> 2 3 (or whatever the province declared)

-- ──────────────────────────────────────────────────────────────
-- 16. Removing a marker
-- ──────────────────────────────────────────────────────────────
-- removeMarker permanently destroys a placed marker — use this
-- when a unit is eliminated, a city is abandoned, or an event
-- has resolved and its pin should disappear from the globe.
local tmp_marker = g:addMarker("event", 44.4, 26.1, "Crisis")   -- Bucharest
g:setMarkerAttr(tmp_marker, "severity", "high")
print("Crisis marker at Bucharest, id:", tmp_marker)
local marker_ok = g:removeMarker(tmp_marker)
print("Crisis marker removed:", marker_ok)   --> true

-- ──────────────────────────────────────────────────────────────
-- 17. Setting time of day
-- ──────────────────────────────────────────────────────────────
-- setTimeOfDay lets you jump the sun to any hour (0–24) directly —
-- useful for cinematic scene transitions or save-game restoration
-- without relying on the continuous update() accumulation.
g:setTimeOfDay(0.0)    -- midnight — terminator fully dark
print(string.format("Time after setTimeOfDay(0): %.1f h", g:getTimeOfDay()))
g:setTimeOfDay(6.0)    -- sunrise
print(string.format("Sunrise: %.1f h", g:getTimeOfDay()))
g:setTimeOfDay(12.0)   -- restore noon

-- ──────────────────────────────────────────────────────────────
-- 18. Retrieve an existing globe by name
-- ──────────────────────────────────────────────────────────────
-- globe.get looks up a previously created globe from the global
-- registry — essential when different game systems need the same
-- globe without threading the reference through every call site.
local same_globe = globe_mod.get("world")
assert(same_globe ~= nil, "globe 'world' must exist after section 1")
print("Retrieved globe name:", same_globe:getName())   --> world

-- ──────────────────────────────────────────────────────────────
-- 19. Load provinces from a TOML string
-- ──────────────────────────────────────────────────────────────
-- loadFromTOML lets map authors write province data in TOML files
-- (or generated strings) rather than Lua tables — useful for
-- mod-friendly campaign editors and procedural map tools.
local toml_src = [[
[[province]]
id = 101
centroid = [55.0, 24.0]
vertices = [[54.0, 22.0], [54.0, 26.0], [56.0, 26.0], [56.0, 22.0]]
neighbors = [102]
base_color = [0.50, 0.28, 0.60, 1.0]

[[province]]
id = 102
centroid = [56.5, 28.0]
vertices = [[55.5, 26.0], [55.5, 30.0], [57.5, 30.0], [57.5, 26.0]]
neighbors = [101]
base_color = [0.28, 0.60, 0.50, 1.0]
]]
local g2 = globe_mod.loadFromTOML("baltic", toml_src, { radius = 200.0 })
print("Baltic provinces loaded:", g2:provinceCount())   --> 2

-- ──────────────────────────────────────────────────────────────
-- 20. Great-circle path between two coordinates
-- ──────────────────────────────────────────────────────────────
-- greatCirclePath returns a sequence of {lat, lon} waypoints along
-- the geodesic arc — use it to animate a camera sweep, draw a
-- missile trajectory, or plan a naval route across open ocean.
local path_pts = globe_mod.greatCirclePath(51.5, -0.1, 35.7, 139.7, 8)  -- London → Tokyo
io.write("London → Tokyo path points: ")
for i, pt in ipairs(path_pts) do
    io.write(string.format("(%.0f°,%.0f°) ", pt[1], pt[2]))
end
io.write("\n")
print("Waypoint count:", #path_pts)   --> 8

-- ──────────────────────────────────────────────────────────────
-- 21. Module constants
-- ──────────────────────────────────────────────────────────────
-- MAX_PROVINCES is the hard per-globe province cap.
-- LOD_FAR / LOD_MID / LOD_NEAR are the canonical tier strings
-- returned by getLod() — compare against them to branch rendering.
print("Max provinces per globe:", globe_mod.MAX_PROVINCES)   --> 8192
print("LOD tier constants:", globe_mod.LOD_FAR, globe_mod.LOD_MID, globe_mod.LOD_NEAR)
-- --> far  mid  near

local lod = g:getLod()
if lod == globe_mod.LOD_FAR then
    print("Far view — suppressing per-province labels to reduce clutter")
elseif lod == globe_mod.LOD_MID then
    print("Mid view — showing region labels")
elseif lod == globe_mod.LOD_NEAR then
    print("Near view — full per-province detail")
end

-- ──────────────────────────────────────────────────────────────
-- 22. Removing a province
-- ──────────────────────────────────────────────────────────────
-- removeProvince destroys a province entirely — useful when a
-- territory is conquered and merged into a neighbour, or when a
-- dynamic map is regenerated mid-campaign.
local removed = g:removeProvince(3)   -- remove Berlin
print("Province 3 removed:", removed)              --> true
print("Province count after removal:", g:provinceCount())  --> 2

-- Re-add it so later sections keep a 3-province map
g:addProvince({
    id       = 3,
    centroid = {52.5, 13.4},
    vertices = {{51.0, 11.5}, {51.0, 15.5}, {54.0, 15.5}, {54.0, 11.5}},
    neighbors = {1, 2},
    base_color = {0.30, 0.40, 0.60, 1.0},
})
g:setProvinceAttr(3, "owner", "neutral")

-- ──────────────────────────────────────────────────────────────
-- 23. Fog-of-war extras: hideProvince and revealAll
-- ──────────────────────────────────────────────────────────────
-- hideProvince puts a revealed province back into fog — use it
-- when a scout is destroyed or a radar station goes offline.
g:revealProvince("player1", 3)
print("p1 sees Berlin (revealed):", g:isVisible("player1", 3))   --> true
g:hideProvince("player1", 3)
print("p1 sees Berlin (hidden):",   g:isVisible("player1", 3))   --> false

-- revealAll is the 'lift all fog' action — good for the end-of-game
-- debrief or a special power that briefly reveals the full map.
g:revealAll("player1")
print("p1 sees Berlin (revealAll):", g:isVisible("player1", 3))  --> true

-- ──────────────────────────────────────────────────────────────
-- 24. Marker visibility toggle
-- ──────────────────────────────────────────────────────────────
-- setMarkerVisible hides or shows a marker without destroying it.
-- Use it when a unit enters a tunnel, goes into stealth mode, or
-- is inside a province hidden by fog of war.
local sub_id = g:addMarker("unit", 49.0, 8.0)   -- Frankfurt — submarine base
g:setMarkerAttr(sub_id, "class", "submarine")
g:setMarkerVisible(sub_id, false)   -- submerged; invisible to opponents
print("Submarine marker hidden (submerged)")
g:setMarkerVisible(sub_id, true)    -- surfaced; visible again
print("Submarine marker revealed (surfaced)")

-- ──────────────────────────────────────────────────────────────
-- 25. Label visibility and removal
-- ──────────────────────────────────────────────────────────────
-- setLabelVisible suppresses a label when camera is too far out
-- to read it, then re-enables it as the player zooms in closer.
local lbl_benelux = g:addLabel("region", 50.5, 3.5, "Benelux")
g:setLabelVisible(lbl_benelux, false)   -- hidden at far zoom
print("Benelux label hidden at far zoom")
g:setLabelVisible(lbl_benelux, true)    -- shown at near zoom
print("Benelux label shown at near zoom")

-- removeLabel permanently deletes a label — use when a region
-- is renamed or dissolved during the campaign narrative.
local lbl_hre = g:addLabel("region", 48.0, 16.0, "Holy Roman Empire")
local lbl_removed = g:removeLabel(lbl_hre)
print("Historical label removed:", lbl_removed)   --> true

-- ──────────────────────────────────────────────────────────────
-- 26. Layer management: visibility, alpha, and removal
-- ──────────────────────────────────────────────────────────────
-- setLayerVisible swaps between overlays without destroying them —
-- the player can toggle between political and terrain views.
g:addLayer("terrain", 2)
for id = 1, 2 do
    g:setLayerColor("terrain", id, 0.50, 0.35, 0.20, 0.50)   -- earth tone
end
g:setLayerVisible("political", false)   -- hide political overlay
g:setLayerVisible("terrain",   true)    -- show terrain overlay
print("Terrain layer now active; political layer hidden")

-- setLayerAlpha dims an overlay for a translucent heat-map effect.
g:setLayerAlpha("terrain", 0.30)
print("Terrain layer at 30% alpha for subtle shading")

-- removeLayer destroys the effect entirely — use when unloading
-- a scenario that had its own thematic data.
local layer_ok = g:removeLayer("terrain")
print("Terrain layer removed:", layer_ok)   --> true

-- ──────────────────────────────────────────────────────────────
-- 27. Removing an arc
-- ──────────────────────────────────────────────────────────────
-- removeArc clears a great-circle route once the mission or flight
-- it represented has resolved (arrived, intercepted, or cancelled).
local transatl = g:addArc(48.8, 2.3, 40.7, -74.0, 32)   -- Paris → New York
print("Transatlantic arc id:", transatl)
local arc_removed = g:removeArc(transatl)
print("Arc removed:", arc_removed)   --> true

-- ──────────────────────────────────────────────────────────────
-- 28. Screen-space province picking
-- ──────────────────────────────────────────────────────────────
-- pick converts a screen pixel to the province under the cursor —
-- the foundation of any click-to-select or hover-highlight feature.
-- (In a live game, pass lurek.input.getPosition() here.)
local px_cx, px_cy = 640, 360   -- fake screen centre for this example
local picked_id = g:pick(px_cx, px_cy)
if picked_id then
    local p_owner = g:getProvinceAttr(picked_id, "owner") or "unknown"
    print(string.format("Province %d at screen centre, owner: %s", picked_id, p_owner))
else
    print("No province at screen centre (ocean or off-globe at this camera)")
end

-- pickLatLon returns the geographic coordinate rather than an ID —
-- use it to drop a custom marker exactly where the player clicked.
local p_lat, p_lon = g:pickLatLon(px_cx, px_cy)
if p_lat then
    print(string.format("Click lat=%.2f lon=%.2f", p_lat, p_lon))
    g:addMarker("waypoint", p_lat, p_lon, "Click target")
else
    print("pickLatLon: click missed the globe surface")
end

-- ──────────────────────────────────────────────────────────────
-- 29. Globe rotation and border rendering
-- ──────────────────────────────────────────────────────────────
-- setRotation sets the longitude offset of the planet's surface —
-- use it to spin the globe independently of the orbit camera (day/night)
-- or to align a specific meridian to the screen centre on startup.
g:setRotation(45.0)   -- rotate 45° eastward
print("Globe surface rotated 45° east")
g:setRotation(0.0)    -- reset to prime meridian

-- setBorders toggles province boundary polylines.
-- Hide them for a solid political-map screenshot or a stylised
-- presentation; re-enable for tactical gameplay.
g:setBorders(false)
print("Province borders hidden (map-art mode)")
g:setBorders(true)
print("Province borders restored")

-- ──────────────────────────────────────────────────────────────
-- 30. Globe name retrieval
-- ──────────────────────────────────────────────────────────────
-- getName returns the string key the globe was registered under.
-- Use it for logging, multi-globe planet-picker UIs, or save-file
-- headers that need to identify which map is active.
local globe_name = g:getName()
print("Globe name:", globe_name)   --> world
assert(globe_name == "world", "globe name must match creation argument")

-- ──────────────────────────────────────────────────────────────
-- 31. Emitting a render frame (advanced usage)
-- ──────────────────────────────────────────────────────────────
-- emitFrame produces the Vec<RenderCommand> that the engine submits
-- to the GPU each draw call.  The engine calls this automatically
-- when the globe is managed by the active scene, so most game code
-- does not need to call it directly.
--
-- Call it manually only when:
--   • You need to intercept or filter render commands (e.g. to
--     composite the globe onto an offscreen canvas).
--   • You are managing the globe outside the scene system.
--
-- Pass nil to skip text rendering (labels/marker text), or pass a
-- FontKey handle to enable it:
--
--   function lurek.render()
--       local cmds = g:emitFrame(nil)   -- RenderCommand table
--       -- cmds are submitted automatically; inspect for debug tools
--   end
--
-- Here we call it outside a frame to verify the API is reachable:
local cmds = g:emitFrame(nil)
print(string.format("emitFrame returned %d render commands", #cmds))

-- ──────────────────────────────────────────────────────────────
-- 32. Summary
-- ──────────────────────────────────────────────────────────────
print("All 53 globe API calls exercised.")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- GlobeRegistry methods
-- -----------------------------------------------------------------------------

-- Get an existing globe by name, or nil.
globeRegistry_stub:get("hero")  -- -> Globe?
-- Remove a globe by name.
globeRegistry_stub:remove("hero")  -- -> boolean
-- Returns a table of all globe names.
globeRegistry_stub:names()  -- -> table<string>
