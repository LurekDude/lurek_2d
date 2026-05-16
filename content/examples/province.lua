-- content/examples/province.lua
-- lurek.province API examples.
-- Run: cargo run -- content/examples/province.lua

--@api-stub: lurek.province.newFromPng
-- Creates a new province registry by loading a color-coded PNG where each unique color represents a distinct province
do
  local ok, reg = pcall(lurek.province.newFromPng, "world", "content/games/strategy/eu2/map.png")
  if ok and reg then
    lurek.log.info("province registry created: " .. reg:getName(), "province")
  end
end

--@api-stub: lurek.province.get
-- Retrieves an existing province registry by name
do
  local reg = lurek.province.get("world")
  if reg then
    lurek.log.info("got registry width=" .. reg:getWidth(), "province")
  end
end

--@api-stub: lurek.province.exists
-- Checks whether a province registry with the given name exists
do
  local found = lurek.province.exists("world")
  lurek.log.info("exists=" .. tostring(found), "province")
end

--@api-stub: lurek.province.remove
-- Removes a province registry by name and clears the active registry if it was the one removed
do
  pcall(lurek.province.newFromPng, "temp_map", "content/games/strategy/eu2/map.png")
  local removed = lurek.province.remove("temp_map")
  lurek.log.info("removed=" .. tostring(removed), "province")
end

--@api-stub: lurek.province.setActive
-- Sets the named registry as the active province registry
do
  lurek.province.setActive("world")
  lurek.log.info("active registry set to world", "province")
end

--@api-stub: lurek.province.getActive
-- Returns the currently active province registry, or nil if none is set
do
  local active = lurek.province.getActive()
  if active then
    lurek.log.info("active=" .. active:getName(), "province")
  end
end

-- -----------------------------------------------------------------------------
-- LProvinceRegistry methods
-- -----------------------------------------------------------------------------

--@api-stub: LProvinceRegistry:getName
-- Returns the string name used to identify this registry in the province system
do
  local reg = lurek.province.get("world")
  if reg then
    local name = reg:getName()
    lurek.log.info("name=" .. tostring(name), "province")
  end
end

--@api-stub: LProvinceRegistry:getWidth
-- Returns the width of the province grid in cells (pixels of the source PNG)
do
  local reg = lurek.province.get("world")
  if reg then
    local w = reg:getWidth()
    lurek.log.info("width=" .. tostring(w), "province")
  end
end

--@api-stub: LProvinceRegistry:getHeight
-- Returns the height of the province grid in cells (pixels of the source PNG)
do
  local reg = lurek.province.get("world")
  if reg then
    local h = reg:getHeight()
    lurek.log.info("height=" .. tostring(h), "province")
  end
end

--@api-stub: LProvinceRegistry:getAt
-- Returns the province ID at the given grid cell coordinates
do
  local reg = lurek.province.get("world")
  if reg then
    local pid = reg:getAt(0.0, 0.0)
    lurek.log.info("province at (0,0)=" .. tostring(pid), "province")
  end
end

--@api-stub: LProvinceRegistry:provinceCount
-- Returns the total number of distinct provinces in this registry (excluding ID 0)
do
  local reg = lurek.province.get("world")
  if reg then
    local count = reg:provinceCount()
    lurek.log.info("provinceCount=" .. tostring(count), "province")
  end
end

--@api-stub: LProvinceRegistry:provinceIds
-- Returns a sequential table of all province IDs in this registry
do
  local reg = lurek.province.get("world")
  if reg then
    local ids = reg:provinceIds()
    lurek.log.info("provinceIds count=" .. tostring(#ids), "province")
  end
end

--@api-stub: LProvinceRegistry:adjacencies
-- Returns all adjacency pairs in the registry
do
  local reg = lurek.province.get("world")
  if reg then
    local adj = reg:adjacencies()
    lurek.log.info("adjacency pairs=" .. tostring(#adj), "province")
  end
end

--@api-stub: LProvinceRegistry:provinceSpans
-- Returns the raw span data for all provinces
do
  local reg = lurek.province.get("world")
  if reg then
    local spans = reg:provinceSpans()
    lurek.log.info("spans=" .. tostring(#spans), "province")
  end
end

--@api-stub: LProvinceRegistry:borderSegments
-- Returns all border line segments between adjacent provinces
do
  local reg = lurek.province.get("world")
  if reg then
    local segs = reg:borderSegments()
    lurek.log.info("border segments=" .. tostring(#segs), "province")
  end
end

--@api-stub: LProvinceRegistry:getRevision
-- Returns the current change revision counter
do
  local reg = lurek.province.get("world")
  if reg then
    local rev = reg:getRevision()
    lurek.log.info("revision=" .. tostring(rev), "province")
  end
end

--@api-stub: LProvinceRegistry:getProvince
-- Returns a snapshot table describing a single province: its ID, revision, style (political_color, terrain_type, border_style, fog_state, visibility_state), centroid, and custom attributes
do
  local reg = lurek.province.get("world")
  if reg then
    local snap = reg:getProvince(1)
    lurek.log.info("province 1=" .. tostring(snap ~= nil), "province")
  end
end

--@api-stub: LProvinceRegistry:getNeighbors
-- Returns a table of province IDs that share a border with the given province
do
  local reg = lurek.province.get("world")
  if reg then
    local neighbors = reg:getNeighbors(1)
    lurek.log.info("neighbors of 1=" .. tostring(#neighbors), "province")
  end
end

--@api-stub: LProvinceRegistry:getBorderClass
-- Returns the border classification string between two adjacent provinces (e
do
  local reg = lurek.province.get("world")
  if reg then
    local cls = reg:getBorderClass(1, 2)
    lurek.log.info("border class 1-2=" .. tostring(cls), "province")
  end
end

--@api-stub: LProvinceRegistry:setBorderClass
-- Sets the border classification between two adjacent provinces
do
  local reg = lurek.province.get("world")
  if reg then
    reg:setBorderClass(1, 2, "coast")
    lurek.log.info("set border class 1-2 to coast", "province")
  end
end

--@api-stub: LProvinceRegistry:setPoliticalColor
-- Sets the political map color for a province
do
  local reg = lurek.province.get("world")
  if reg then
    local ok = reg:setPoliticalColor(1, 1.0, 0.8, 0.2, 1.0)
    lurek.log.info("setPoliticalColor=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:setTerrainType
-- Sets the terrain type index for a province
do
  local reg = lurek.province.get("world")
  if reg then
    local ok = reg:setTerrainType(1, 2)
    lurek.log.info("setTerrainType=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:setBorderStyle
-- Sets the border rendering style index for a province
do
  local reg = lurek.province.get("world")
  if reg then
    local ok = reg:setBorderStyle(1, 1)
    lurek.log.info("setBorderStyle=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:setFogState
-- Sets the fog-of-war state for a province
do
  local reg = lurek.province.get("world")
  if reg then
    local ok = reg:setFogState(1, 0)
    lurek.log.info("setFogState=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:setVisibilityState
-- Sets the visibility state for a province
do
  local reg = lurek.province.get("world")
  if reg then
    local ok = reg:setVisibilityState(1, 1)
    lurek.log.info("setVisibilityState=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:setAttr
-- Sets a custom string attribute on a province
do
  local reg = lurek.province.get("world")
  if reg then
    local ok = reg:setAttr(1, "player_score", "42")
    lurek.log.info("setAttr=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:getChangesSince
-- Returns all province changes that occurred after the given revision
do
  local reg = lurek.province.get("world")
  if reg then
    local changes = reg:getChangesSince(0)
    lurek.log.info("changes since rev 0=" .. tostring(#changes), "province")
  end
end

--@api-stub: LProvinceRegistry:type
-- Returns the type name string for this userdata object
do
  local reg = lurek.province.get("world")
  if reg then
    local t = reg:type()
    lurek.log.info("type=" .. tostring(t), "province")
  end
end

--@api-stub: LProvinceRegistry:typeOf
-- Checks whether this object matches the given type name
do
  local reg = lurek.province.get("world")
  if reg then
    local is_reg = reg:typeOf("LProvinceRegistry")
    lurek.log.info("typeOf LProvinceRegistry=" .. tostring(is_reg), "province")
  end
end

--@api-stub: lurek.province.zoomCameraAt
-- Computes new camera position after zooming centered on an anchor point
do
  local cam_x, cam_y = 0.0, 0.0
  local new_x, new_y = lurek.province.zoomCameraAt(320.0, 240.0, cam_x, cam_y, 1.0, 1.2)
  lurek.log.debug("zoom anchor camera: " .. tostring(new_x) .. "," .. tostring(new_y), "province")
end

--@api-stub: LProvinceRegistry:fitCamera,
-- Performs the fit camera, operation on this province registry.
do
	local ok, reg = pcall(lurek.province.newFromPng, "example-province-view", "content/games/strategy/eu2/map.png")
	if ok and reg then
		local cam_x, cam_y, zoom = reg:fitCamera(1280, 720, 1.0)
		lurek.log.info("fitCamera: x=" .. tostring(cam_x) .. " y=" .. tostring(cam_y) .. " zoom=" .. tostring(zoom), "province")
		local mx, my = reg:screenToMap(640, 360, cam_x, cam_y, zoom, 1.0)
		lurek.log.info("screenToMap: " .. tostring(mx) .. "," .. tostring(my), "province")
		local pid = reg:screenToProvince(640, 360, cam_x, cam_y, zoom, 1.0)
		lurek.log.info("screenToProvince: pid=" .. tostring(pid), "province")
		lurek.province.remove("example-province-view")
	end
end

--@api-stub: LProvinceRegistry:setCapital
-- Sets the capital marker position for a province
do
  local reg = lurek.province.get("world")
  if reg then
    local ok = reg:setCapital(1, 50.0, 30.0)
    lurek.log.info("setCapital=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:setLabelLine
-- Sets the label baseline for a province
do
  local reg = lurek.province.get("world")
  if reg then
    local ok = reg:setLabelLine(1, 10.0, 20.0, 80.0, 20.0)
    lurek.log.info("setLabelLine=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:setLabelText
-- Sets the display name text for a province
do
  local reg = lurek.province.get("world")
  if reg then
    local ok = reg:setLabelText(1, "Heartland")
    lurek.log.info("setLabelText=" .. tostring(ok), "province")
  end
end

--@api-stub: LProvinceRegistry:render
-- Renders the province map to the screen using the current camera and style settings
do
  local reg = lurek.province.get("world")
  if reg then
    local ok, err = pcall(function() reg:render() end)
    lurek.log.info("render ok=" .. tostring(ok), "province")
  end
end

do
	local sanitized = "save/example_province/map_sanitized.png"
	lurek.province.sanitizeMarkedPng("content/games/strategy/eu2/map.png", sanitized)

	local reg = lurek.province.newFromPng("example-province-import", sanitized)
	reg:importMetadataFromFiles({
		color_map_png = sanitized,
		marker_png = "content/games/strategy/eu2/map.png",
		color_csv = "content/games/strategy/eu2/prov_cols.csv",
		province_toml = "content/games/strategy/eu2/province.toml",
		water_terrain_tokens = { "sea", "river" },
		water_terrain_type = 0,
		land_terrain_type = 1,
	})

	local snap = reg:getProvince(1)
	if snap and snap.attrs then
		lurek.log.debug(
			"imported province #1 name=" .. tostring(snap.attrs.name) ..
			" terrain=" .. tostring(snap.attrs.terrain),
			"province"
		)
	end

	lurek.province.remove("example-province-import")
end


--@api-stub: LProvinceGrid:borderSegments
-- Returns a list of line segment tables representing the borders of a province cell.
do
  local grid = lurek.province.newGrid(800, 600, 64)
  local segs = grid:borderSegments(1)
  lurek.log.debug("border segs=" .. #segs, "province")
end

--@api-stub: LProvinceGrid:deserializeShapeData
-- Restores province shape data from a previously serialized byte string.
do
  local grid = lurek.province.newGrid(800, 600, 64)
  local data = grid:serializeShapeData()
  grid:deserializeShapeData(data)
end

--@api-stub: LProvinceGrid:provinceSpans
-- Returns row-span data for a province as a list of {y, x_start, x_end} tables.
do
  local grid = lurek.province.newGrid(800, 600, 64)
  local spans = grid:provinceSpans(1)
  lurek.log.debug("spans=" .. #spans, "province")
end

--@api-stub: LProvinceGrid:serializeShapeData
-- Serializes all province shape pixel data to a byte string for storage or transfer.
do
  local grid = lurek.province.newGrid(800, 600, 64)
  local data = grid:serializeShapeData()
  lurek.log.debug("serialized bytes=" .. #data, "province")
end

--@api-stub: LProvinceRegistry:fitCamera
-- Adjusts the active camera to frame a specific province in the viewport.
do
  local reg = lurek.province.newRegistry()
  reg:fitCamera(1)
end

--@api-stub: LProvinceRegistry:importMetadataFromFiles
-- Loads province metadata from a list of JSON files and merges them into this registry.
do
  local reg = lurek.province.newRegistry()
  reg:importMetadataFromFiles({"save/example_province/meta.json"})
end

--@api-stub: LProvinceRegistry:screenToMap
-- Converts a screen pixel coordinate to map space coordinates using this registry.
do
  local reg = lurek.province.newRegistry()
  local mx, my = reg:screenToMap(400, 300)
  lurek.log.debug("map=" .. mx .. "," .. my, "province")
end

--@api-stub: LProvinceRegistry:screenToProvince
-- Returns the province id under a given screen pixel coordinate, or nil if none.
do
  local reg = lurek.province.newRegistry()
  local id = reg:screenToProvince(400, 300)
  lurek.log.debug("province=" .. tostring(id), "province")
end
