-- content/examples/province.lua
-- Demonstrates the lurek.province API: province registries, spatial queries, style mutations, camera, and rendering.
-- Run: cargo run -- content/examples/province.lua

-- =============================================================================
-- Module functions: lurek.province.*
-- =============================================================================

--@api-stub: lurek.province.newFromPng
-- Creates a province registry from a color-coded PNG where each unique color is a distinct province
do
  -- Load a strategy map image; each pixel color defines which province owns that cell.
  -- The registry name ("world") is used later to retrieve or set it active.
  local reg = lurek.province.newFromPng("world", "content/games/strategy/eu2/map.png")
  local count = reg:provinceCount()
  lurek.log.info("created registry 'world' with " .. count .. " provinces", "province")
end

--@api-stub: lurek.province.get
-- Retrieves an existing province registry by name, returning nil if not found
do
  -- Use get() to access a previously created registry without re-parsing the PNG.
  local reg = lurek.province.get("world")
  if reg then
    lurek.log.info("retrieved 'world': " .. reg:getWidth() .. "x" .. reg:getHeight() .. " cells", "province")
  else
    lurek.log.warn("registry 'world' not found", "province")
  end
end

--@api-stub: lurek.province.exists
-- Checks whether a registry with the given name has been created
do
  -- Useful before calling get() to avoid nil checks, or to guard against duplicate creation.
  local has_world = lurek.province.exists("world")
  local has_missing = lurek.province.exists("nonexistent_map")
  lurek.log.info("world exists=" .. tostring(has_world) .. ", nonexistent=" .. tostring(has_missing), "province")
end

--@api-stub: lurek.province.setActive
-- Sets the named registry as the active one for rendering and global queries
do
  -- Only one registry can be active at a time. Set it before calling render().
  local ok = lurek.province.setActive("world")
  lurek.log.info("setActive('world')=" .. tostring(ok), "province")
end

--@api-stub: lurek.province.getActive
-- Returns the currently active province registry handle, or nil if none is set
do
  -- Retrieve the active registry to use in callbacks without passing it around.
  local active = lurek.province.getActive()
  if active then
    lurek.log.info("active registry: " .. active:getName(), "province")
  end
end

--@api-stub: lurek.province.remove
-- Removes a registry by name and clears it from active if it was the active one
do
  -- Create a temporary registry, then clean it up to free memory.
  local ok, temp = pcall(lurek.province.newFromPng, "temp_cleanup", "content/games/strategy/eu2/map.png")
  if ok and temp then
    local removed = lurek.province.remove("temp_cleanup")
    lurek.log.info("removed temp_cleanup=" .. tostring(removed), "province")
  end
end

--@api-stub: lurek.province.sanitizeMarkedPng
-- Pre-processes a marker PNG by replacing capital/label pixels with surrounding province color
do
  -- Marker PNGs have special colored pixels for capitals (bright red) and labels (green).
  -- sanitizeMarkedPng replaces those with the actual province color so newFromPng parses cleanly.
  local output_path = "save/example_province/map_sanitized.png"
  local summary = lurek.province.sanitizeMarkedPng(
    "content/games/strategy/eu2/map.png",
    output_path,
    { capital_min = 200, label_r_min = 0, label_g_max = 50, label_b_min = 200, search_radius = 3 }
  )
  lurek.log.info("sanitized: replaced=" .. tostring(summary.replaced_pixels)
    .. " unresolved=" .. tostring(summary.unresolved_pixels), "province")
end

--@api-stub: lurek.province.zoomCameraAt
-- Computes new camera position after zooming centered on an anchor point
do
  -- When the player scrolls the mouse wheel at screen position (mx, my),
  -- use zoomCameraAt to keep that point visually stationary while zoom changes.
  local cam_x, cam_y = 400.0, 300.0
  local old_zoom, new_zoom = 1.0, 1.5
  local anchor_x, anchor_y = 640.0, 360.0  -- mouse position on screen
  local new_cx, new_cy = lurek.province.zoomCameraAt(anchor_x, anchor_y, cam_x, cam_y, old_zoom, new_zoom)
  lurek.log.info("zoom: camera moved from ("
    .. cam_x .. "," .. cam_y .. ") to (" .. new_cx .. "," .. new_cy .. ")", "province")
end

-- =============================================================================
-- LProvinceRegistry methods
-- =============================================================================

--@api-stub: LProvinceRegistry:getName
-- Returns the string name used to identify this registry
do
  local reg = lurek.province.get("world")
  if reg then
    -- The name matches what was passed to newFromPng.
    local name = reg:getName()
    lurek.log.info("registry name: " .. name, "province")
  end
end

--@api-stub: LProvinceRegistry:getWidth
-- Returns the province grid width in cells (source PNG pixel columns)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Width determines the x-range for getAt() and screen-to-map conversion.
    local w = reg:getWidth()
    lurek.log.info("grid width: " .. w .. " cells", "province")
  end
end

--@api-stub: LProvinceRegistry:getHeight
-- Returns the province grid height in cells (source PNG pixel rows)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Height determines the y-range and total map bounds.
    local h = reg:getHeight()
    lurek.log.info("grid height: " .. h .. " cells", "province")
  end
end

--@api-stub: LProvinceRegistry:provinceCount
-- Returns the total number of distinct provinces (excluding ID 0 which is unowned)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Use this to size UI lists, allocate per-province data, or validate map loading.
    local count = reg:provinceCount()
    lurek.log.info("total provinces: " .. count, "province")
  end
end

--@api-stub: LProvinceRegistry:provinceIds
-- Returns a sequential table of all province IDs in the registry
do
  local reg = lurek.province.get("world")
  if reg then
    -- Iterate over all provinces to initialize game state (owners, armies, resources).
    local ids = reg:provinceIds()
    lurek.log.info("province IDs: " .. #ids .. " entries, first=" .. tostring(ids[1]), "province")
  end
end

--@api-stub: LProvinceRegistry:getAt
-- Returns the province ID at grid coordinates, or 0 if unowned (sea/wasteland)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Check which province owns the top-left corner cell.
    local pid = reg:getAt(0.0, 0.0)
    if pid > 0 then
      lurek.log.info("province at (0,0): ID " .. pid, "province")
    else
      lurek.log.info("cell (0,0) is unowned (sea or wasteland)", "province")
    end
  end
end

--@api-stub: LProvinceRegistry:getProvince
-- Returns a snapshot table for one province: ID, revision, style, centroid, and custom attributes
do
  local reg = lurek.province.get("world")
  if reg then
    -- Retrieve full province data for a tooltip or info panel.
    local snap = reg:getProvince(1)
    if snap then
      lurek.log.info("province #1: terrain=" .. tostring(snap.style.terrain_type)
        .. " fog=" .. tostring(snap.style.fog_state), "province")
    end
  end
end

--@api-stub: LProvinceRegistry:getNeighbors
-- Returns a table of province IDs that share a border with the given province
do
  local reg = lurek.province.get("world")
  if reg then
    -- Use neighbors for movement validation: a unit can only move to adjacent provinces.
    local neighbors = reg:getNeighbors(1)
    lurek.log.info("province #1 has " .. #neighbors .. " neighbors", "province")
    if #neighbors > 0 then
      lurek.log.debug("  first neighbor: ID " .. neighbors[1], "province")
    end
  end
end

--@api-stub: LProvinceRegistry:adjacencies
-- Returns all adjacency pairs in the registry with province_a and province_b fields
do
  local reg = lurek.province.get("world")
  if reg then
    -- Build a full adjacency graph for pathfinding or trade route computation.
    local adj = reg:adjacencies()
    lurek.log.info("adjacency pairs: " .. #adj, "province")
    if #adj > 0 then
      local first = adj[1]
      lurek.log.debug("  pair: " .. first.province_a .. " <-> " .. first.province_b, "province")
    end
  end
end

--@api-stub: LProvinceRegistry:borderSegments
-- Returns all border line segments between adjacent provinces for custom rendering
do
  local reg = lurek.province.get("world")
  if reg then
    -- Each segment is a line from (x0,y0) to (x1,y1) separating two provinces.
    -- Draw these with lurek.graphics for a custom border overlay.
    local segs = reg:borderSegments()
    lurek.log.info("border segments: " .. #segs, "province")
    if #segs > 0 then
      local s = segs[1]
      lurek.log.debug("  segment: (" .. s.x0 .. "," .. s.y0 .. ")->(" .. s.x1 .. "," .. s.y1 .. ")", "province")
    end
  end
end

--@api-stub: LProvinceRegistry:provinceSpans
-- Returns raw horizontal span data for all provinces (useful for custom rendering or analysis)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Each span is {province_id, y, x0, x1} — a horizontal run of cells on one row.
    -- Use spans for flood-fill style rendering or area calculation.
    local spans = reg:provinceSpans()
    lurek.log.info("total spans: " .. #spans, "province")
  end
end

--@api-stub: LProvinceRegistry:getBorderClass
-- Returns the border classification string between two provinces, or nil if unset
do
  local reg = lurek.province.get("world")
  if reg then
    -- Border classes: "land_land", "coast", "sea_sea", "special". Controls rendering and gameplay.
    local cls = reg:getBorderClass(1, 2)
    if cls then
      lurek.log.info("border class between 1 and 2: " .. cls, "province")
    else
      lurek.log.info("no border class set between provinces 1 and 2", "province")
    end
  end
end

--@api-stub: LProvinceRegistry:setBorderClass
-- Sets the border classification between two adjacent provinces
do
  local reg = lurek.province.get("world")
  if reg then
    -- Mark the border between province 1 and 2 as a coast.
    -- Valid classes: "land_land", "coast", "sea_sea", "special".
    reg:setBorderClass(1, 2, "coast")
    lurek.log.info("set border 1-2 class to 'coast'", "province")
  end
end

--@api-stub: LProvinceRegistry:setPoliticalColor
-- Sets the political map color (RGBA) for a province
do
  local reg = lurek.province.get("world")
  if reg then
    -- Paint province #1 in gold to indicate it belongs to the player's faction.
    reg:setPoliticalColor(1, 0.9, 0.75, 0.2, 1.0)
    lurek.log.info("province #1 painted gold (political map)", "province")
  end
end

--@api-stub: LProvinceRegistry:setTerrainType
-- Sets the terrain type index for a province (controls fill in terrain map mode)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Terrain types are game-defined: e.g. 0=sea, 1=plains, 2=forest, 3=mountain.
    -- The render system uses this index to pick the fill color or texture.
    reg:setTerrainType(1, 2)  -- province #1 is forest
    lurek.log.info("province #1 terrain set to forest (type 2)", "province")
  end
end

--@api-stub: LProvinceRegistry:setBorderStyle
-- Sets the border rendering style index for a province
do
  local reg = lurek.province.get("world")
  if reg then
    -- Border style controls line thickness and pattern. E.g. 0=thin, 1=thick, 2=dashed.
    reg:setBorderStyle(1, 1)
    lurek.log.info("province #1 border style set to thick (1)", "province")
  end
end

--@api-stub: LProvinceRegistry:setFogState
-- Sets the fog-of-war state for a province (0=revealed, 1=fogged, 2=hidden)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Reveal province #1 when the player moves a unit there.
    reg:setFogState(1, 0)  -- 0 = fully revealed
    lurek.log.info("province #1 fog state: revealed", "province")
  end
end

--@api-stub: LProvinceRegistry:setVisibilityState
-- Sets the visibility state for a province (separate from fog: scouted vs unscouted)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Visibility is a separate layer: a province can be fogged but previously scouted.
    -- 0=unscouted (never seen), 1=scouted (terrain known but units hidden).
    reg:setVisibilityState(1, 1)
    lurek.log.info("province #1 visibility: scouted", "province")
  end
end

--@api-stub: LProvinceRegistry:setAttr
-- Sets a custom string attribute on a province for game-specific metadata
do
  local reg = lurek.province.get("world")
  if reg then
    -- Store arbitrary game data per province. Retrieved via getProvince().attrs table.
    reg:setAttr(1, "owner", "player_1")
    reg:setAttr(1, "population", "15000")
    reg:setAttr(1, "resource", "iron")
    lurek.log.info("province #1 attrs set: owner, population, resource", "province")
  end
end

--@api-stub: LProvinceRegistry:setCapital
-- Sets the capital marker position for a province (drawn when draw_capitals=true)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Place the capital icon at the center of the main city within this province.
    reg:setCapital(1, 50.0, 30.0)
    lurek.log.info("province #1 capital placed at (50, 30)", "province")
  end
end

--@api-stub: LProvinceRegistry:setLabelLine
-- Sets the label baseline for a province (text rendered along this line)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Define a horizontal line from (10,25) to (90,25) for the province name.
    -- The text follows this baseline, allowing angled or curved labels.
    reg:setLabelLine(1, 10.0, 25.0, 90.0, 25.0)
    lurek.log.info("province #1 label line set", "province")
  end
end

--@api-stub: LProvinceRegistry:setLabelText
-- Sets the display name text for a province (shown when draw_labels=true)
do
  local reg = lurek.province.get("world")
  if reg then
    -- The label text is drawn along the label line defined by setLabelLine.
    reg:setLabelText(1, "Heartland")
    lurek.log.info("province #1 label: 'Heartland'", "province")
  end
end

--@api-stub: LProvinceRegistry:getRevision
-- Returns the current change revision counter (incremented on every mutation)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Track the revision to implement incremental UI updates.
    local rev_before = reg:getRevision()
    reg:setPoliticalColor(1, 0.5, 0.5, 0.5, 1.0)
    local rev_after = reg:getRevision()
    lurek.log.info("revision: " .. rev_before .. " -> " .. rev_after .. " (after color change)", "province")
  end
end

--@api-stub: LProvinceRegistry:getChangesSince
-- Returns all province changes after a given revision for incremental UI updates
do
  local reg = lurek.province.get("world")
  if reg then
    -- Use with getRevision() to only repaint provinces that actually changed.
    local last_known = reg:getRevision()
    reg:setTerrainType(1, 3)  -- trigger a change
    reg:setFogState(1, 1)     -- trigger another change
    local changes = reg:getChangesSince(last_known)
    lurek.log.info("changes since rev " .. last_known .. ": " .. #changes .. " entries", "province")
    for _, change in ipairs(changes) do
      lurek.log.debug("  change: revision=" .. tostring(change.revision), "province")
    end
  end
end

--@api-stub: LProvinceRegistry:fitCamera
-- Computes camera position and zoom so the entire map fits within screen dimensions
do
  local reg = lurek.province.get("world")
  if reg then
    -- Call fitCamera on game start to show the full map in the viewport.
    local screen_w, screen_h = 1280, 720
    local cam_x, cam_y, zoom = reg:fitCamera(screen_w, screen_h, 1.0)
    lurek.log.info("fitCamera: center=(" .. cam_x .. "," .. cam_y .. ") zoom=" .. zoom, "province")
  end
end

--@api-stub: LProvinceRegistry:screenToMap
-- Converts screen pixel coordinates to map-space coordinates using camera transform
do
  local reg = lurek.province.get("world")
  if reg then
    -- Convert the mouse cursor position to map coordinates for hover detection.
    local cam_x, cam_y, zoom = reg:fitCamera(1280, 720, 1.0)
    local mouse_sx, mouse_sy = 640, 360  -- center of screen
    local map_x, map_y = reg:screenToMap(mouse_sx, mouse_sy, cam_x, cam_y, zoom, 1.0)
    lurek.log.info("screen (640,360) -> map (" .. map_x .. "," .. map_y .. ")", "province")
  end
end

--@api-stub: LProvinceRegistry:screenToProvince
-- Converts screen coordinates directly to a province ID (nil if outside map or unowned)
do
  local reg = lurek.province.get("world")
  if reg then
    -- Quick hover detection: get the province under the cursor in one call.
    local cam_x, cam_y, zoom = reg:fitCamera(1280, 720, 1.0)
    local pid = reg:screenToProvince(640, 360, cam_x, cam_y, zoom, 1.0)
    if pid then
      lurek.log.info("province under screen center: ID " .. pid, "province")
    else
      lurek.log.info("no province under screen center (sea or out of bounds)", "province")
    end
  end
end

--@api-stub: LProvinceRegistry:importMetadataFromFiles
-- Bulk-imports province metadata (colors, capitals, labels, terrain) from external files
do
  -- Sanitize the map first, then import metadata from CSV and TOML definitions.
  local sanitized = "save/example_province/map_sanitized.png"
  lurek.province.sanitizeMarkedPng("content/games/strategy/eu2/map.png", sanitized)

  local reg = lurek.province.newFromPng("example_import", sanitized)
  local summary = reg:importMetadataFromFiles({
    color_map_png = sanitized,
    marker_png = "content/games/strategy/eu2/map.png",
    color_csv = "content/games/strategy/eu2/prov_cols.csv",
    province_toml = "content/games/strategy/eu2/province.toml",
    water_terrain_tokens = { "sea", "river" },
    water_terrain_type = 0,
    land_terrain_type = 1,
    set_political_colors = true,
    set_label_text = true,
    set_capitals = true,
    set_label_lines = true,
  })
  lurek.log.info("import: mapped=" .. summary.mapped_provinces
    .. " capitals=" .. summary.capitals_set
    .. " labels=" .. summary.labels_set, "province")
  lurek.province.remove("example_import")
end

--@api-stub: LProvinceRegistry:render
-- Renders the province map with fills, borders, labels, and capitals
do
  local reg = lurek.province.get("world")
  if reg then
    -- Render with full options for a political map view with hover highlight.
    local cam_x, cam_y, zoom = reg:fitCamera(1280, 720, 1.0)
    local ok, err = pcall(function()
      reg:render({
        map_mode = "political",
        x = cam_x,
        y = cam_y,
        zoom = zoom,
        pixel_size = 1.0,
        screen_w = 1280,
        screen_h = 720,
        draw_fills = true,
        draw_borders = true,
        draw_labels = true,
        draw_capitals = true,
        border_width = 2.0,
        hovered_id = 1,
        selected_id = nil,
      })
    end)
    lurek.log.info("render ok=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:type
-- Returns the type name string for this userdata object
do
  local reg = lurek.province.get("world")
  if reg then
    local t = reg:type()
    lurek.log.info("type: " .. t, "province")  -- "LProvinceRegistry"
  end
end

--@api-stub: LProvinceRegistry:typeOf
-- Checks whether this object matches the given type name
do
  local reg = lurek.province.get("world")
  if reg then
    -- typeOf returns true for "LProvinceRegistry" and the generic "Object" base.
    local is_reg = reg:typeOf("LProvinceRegistry")
    local is_obj = reg:typeOf("Object")
    lurek.log.info("typeOf LProvinceRegistry=" .. tostring(is_reg)
      .. ", Object=" .. tostring(is_obj), "province")
  end
end

print("content/examples/province.lua")
