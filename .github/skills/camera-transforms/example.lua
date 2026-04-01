shake = shake * (1 - 8 * dt)           -- 8 = decay rate, tune as needed
local ox = (math.random() - 0.5) * 2 * shake
local oy = (math.random() - 0.5) * 2 * shake
luna.graphics.setCamera(base_x + ox, base_y + oy, zoom, rotation)
