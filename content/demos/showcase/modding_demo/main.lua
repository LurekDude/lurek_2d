-- Modding Demo for Lurek2D
-- Demonstrates lurek.fs.mount / unmount and load via lurek.fs.load.
-- Mounts a local "mods" folder and loads a Lua chunk from it.
-- Run with: cargo run -- content/demos/showcase/modding_demo

local mod_greeting = "No mod loaded."
local mod_init_ran = false

function lurek.init()
    -- Mount the mod directory at a virtual path
    local ok = lurek.fs.mount("mods/hello_mod", "/hello_mod")
    if ok then
        mod_greeting = "Mod mounted at /hello_mod"

        -- Load a Lua chunk from the mod and execute it (load_chunk resolves VFS mounts)
        local ok2, chunk = pcall(lurek.fs.load, "/hello_mod/init.lua")
        if ok2 and type(chunk) == "function" then
            chunk()
            mod_init_ran = true
        end

        -- Unmount when done
        lurek.fs.unmount("/hello_mod")
    else
        mod_greeting = "Mount failed (mods/hello_mod/ not found)."
    end
end

function lurek.render()
    lurek.render.setColor(1, 1, 1)
    lurek.render.print(mod_greeting, 20, 20)
    lurek.render.print("init.lua executed: " .. tostring(mod_init_ran), 20, 50)
    lurek.render.print("lurek.fs.mount / unmount / load demo", 20, 80)
end
