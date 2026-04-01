-- luna.load()
TILE_SIZE = 32
tileset = { [1] = luna.graphics.new_image("grass.png"), [2] = luna.graphics.new_image("stone.png") }
map = { {1,1,2}, {1,2,1}, {2,1,1} }   -- map[row][col]
collision = { {false,false,true}, {false,true,false}, {true,false,false} }
map_width, map_height = 3, 3

-- luna.draw()  (camera handled by luna.graphics.set_camera)
local cam_x, cam_y = luna.graphics.get_camera()
local vw, vh = luna.window.get_width(), luna.window.get_height()
local c0 = math.max(1, math.floor(cam_x / TILE_SIZE) + 1)
local r0 = math.max(1, math.floor(cam_y / TILE_SIZE) + 1)
local c1 = math.min(map_width,  c0 + math.ceil(vw / TILE_SIZE) + 1)
local r1 = math.min(map_height, r0 + math.ceil(vh / TILE_SIZE) + 1)
for row = r0, r1 do
  for col = c0, c1 do
    local tid = map[row][col]
    if tid and tid ~= 0 then
      luna.graphics.draw(tileset[tid], (col-1)*TILE_SIZE, (row-1)*TILE_SIZE)
    end
  end
end
