-- OBJ loader example for Lurek2D
-- Run: lurek2d.exe content/examples/obj_loader

local model
local mesh
local t = 0.0

function lurek.init()
    lurek.window.setTitle("OBJ Loader Example")
    lurek.render.setBackgroundColor(0.08, 0.10, 0.14)
    model = lurek.render.loadObj("../../games/retro/dungeon_crawler/assets/models/sectoid.obj")
end

local function rebuild_mesh()
    local cam = {
        x = math.sin(t) * 4.0,
        y = 2.2,
        z = math.cos(t) * 4.0,
        tx = 0.0,
        ty = 0.7,
        tz = 0.0,
        fov = 60.0,
    }
    local verts = model:projectToMesh(cam, 640, 480)
    mesh = lurek.render.newMesh(verts, "triangles")
end

function lurek.process(dt)
    t = t + dt * 0.7
    rebuild_mesh()
end

function lurek.draw()
    if mesh then
        lurek.render.draw(mesh, 0, 0)
    end
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("OBJ: sectoid.obj projected to 2D mesh", 8, 8)
end
