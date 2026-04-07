-- Modding Demo for Luna2D
-- Demonstrates luna.filesystem.mount / unmount and load via luna.filesystem.load.
-- Mounts a local "mods" folder and loads a Lua chunk from it.

local mod_greeting = "No mod loaded."
local mod_init_ran = false

function luna.load()
    -- Mount the mod directory at a virtual path
    local ok = luna.filesystem.mount("mods/hello_mod", "/hello_mod")
    if ok then
        mod_greeting = "Mod mounted at /hello_mod"

        -- Load a Lua chunk from the mod and execute it (load_chunk resolves VFS mounts)
        local ok2, chunk = pcall(luna.filesystem.load, "/hello_mod/init.lua")
        if ok2 and type(chunk) == "function" then
            chunk()
            mod_init_ran = true
        end

        -- Unmount when done
        luna.filesystem.unmount("/hello_mod")
    else
        mod_greeting = "Mount failed (mods/hello_mod/ not found)."
    end
end

function luna.draw()
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print(mod_greeting, 20, 20)
    luna.graphics.print("init.lua executed: " .. tostring(mod_init_ran), 20, 50)
    luna.graphics.print("luna.filesystem.mount / unmount / load demo", 20, 80)
end
