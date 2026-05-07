-- Headless load test for the EU2 province map demo.
-- Runs as part of games_load_test (auto-discovered via content/games/**/test.lua).

describe("eu2 demo", function()
    it("required APIs exist", function()
        assert(type(lurek.image.newProvinceGrid) == "function",
            "lurek.image.newProvinceGrid must exist")
        assert(type(lurek.image.newImageData) == "function",
            "lurek.image.newImageData must exist")
        assert(type(lurek.serial.fromToml) == "function",
            "lurek.serial.fromToml must exist")
        assert(type(lurek.filesystem.read) == "function",
            "lurek.filesystem.read must exist")
    end)
end)
