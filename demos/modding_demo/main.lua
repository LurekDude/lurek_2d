-- Modding Demo for Luna2D
-- Demonstrates luna.filesystem.mount / unmount / load and newFileData.
-- Mounts a local "mods" folder, reads a file from it, and loads a Lua chunk.

local mod_greeting = "No mod loaded."

function luna.load()
    -- Mount the mod directory at a virtual path
    local ok = luna.filesystem.mount("mods/hello_mod", "/hello_mod")
    if ok then
        -- Read a plain text file from the mounted directory
        local text = luna.filesystem.read("/hello_mod/greeting.txt")
        if text then
            mod_greeting = text
        end

        -- Load a Lua chunk from the mod and execute it
        local ok2, chunk = pcall(luna.filesystem.load, "/hello_mod/init.lua")
        if ok2 and type(chunk) == "function" then
            chunk()
        end

        -- Unmount when done
        luna.filesystem.unmount("/hello_mod")
    else
        mod_greeting = "Mount failed (create examples/mods/hello_mod/ to test)."
    end
end

function luna.draw()
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print(mod_greeting, 20, 20)
    luna.graphics.print("luna.filesystem.mount / unmount / load demo", 20, 50)
end
