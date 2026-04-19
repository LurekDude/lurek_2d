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

print("Globe example completed successfully.")
