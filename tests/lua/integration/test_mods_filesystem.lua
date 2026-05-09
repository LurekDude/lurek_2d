-- Integration: mod discovery via ModManager combined with filesystem operations
describe("mods + filesystem integration", function()
    -- @integration LModManager:hasMod
    -- @integration LModManager:scanFolder
    -- @integration lurek.filesystem.createDirectory
    -- @integration lurek.filesystem.exists
    -- @integration lurek.filesystem.removeDir
    -- @integration lurek.filesystem.write
    -- @integration lurek.mods.newModManager
    it("ModManager:scanFolder registers mods discovered on disk", function()
        local root = "save/_mods_scan_case/"
        local mod_dir = root .. "my-mod/"

        if lurek.filesystem.exists(root) then
            lurek.filesystem.removeDir(root)
        end

        lurek.filesystem.createDirectory(mod_dir)
        lurek.filesystem.write(
            mod_dir .. "mod.toml",
            "id = \"my-mod\"\nname = \"My Mod\"\nversion = \"2.0.0\"\npriority = 5\n"
        )

        local mm = lurek.mods.newModManager()
        local found = mm:scanFolder(root)

        expect_equal(1, #found)
        expect_equal("my-mod", found[1].id)
        expect_equal("2.0.0", found[1].version)
        expect_equal(5, found[1].priority)
        expect_true(mm:hasMod("my-mod"))

        lurek.filesystem.removeDir(root)
    end)
end)

test_summary()
