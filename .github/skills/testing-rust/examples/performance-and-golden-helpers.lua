-- measure(name, count, fn) — wraps fn(), prints [PERF] line, returns elapsed, ops_per_sec
local elapsed, ops = measure("ecs_create", 10000, function()
    for i = 1, 10000 do lurek.ecs.newEntity() end
end)
expect_less(elapsed, 1.0, "10k ECS entity creates must finish under 1s")

-- expect_golden(name, data, expected) — deterministic inline comparison
expect_golden("path_result", lurek.pathfind.findPath(...), "[(1,1),(2,1),(3,1)]")

-- expect_canvas_pixel(canvas, x, y, r, g, b, a, tolerance, msg)
-- Reads canvas:getPixel(x, y) and checks each RGBA channel within tolerance
local canvas = lurek.render.newCanvas(64, 64)
canvas:renderTo(function()
    lurek.render.setColor(1, 0, 0, 1)
    lurek.render.rectangle("fill", 0, 0, 64, 64)
end)
expect_canvas_pixel(canvas, 32, 32, 1.0, 0.0, 0.0, 1.0, 0.05, "center pixel must be red")
