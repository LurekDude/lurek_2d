-- tests/lua/content/demos/test_scene_demo.lua
-- Smoke test for content/games/showcase/scene_demo/main.lua.

local DEMO_PATH = "content/games/showcase/scene_demo/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("scene_demo", DEMO_PATH)

describe("scene_demo: scene API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("uses lurek.scene to manage scenes", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.scene") ~= nil,
            "No lurek.scene reference found")
    end)

    it("registers at least one named scene", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.scene%.register%s*%(") ~= nil or
            src:find("lurek%.scene%.add%s*%(") ~= nil or
            src:find("lurek%.scene%.new%s*%(") ~= nil,
            "No scene registration call found")
    end)

    it("switches to a scene at runtime", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.scene%.switch%s*%(") ~= nil or
            src:find("lurek%.scene%.go%s*%(") ~= nil or
            src:find("lurek%.scene%.push%s*%(") ~= nil or
            src:find(":switch%s*%(") ~= nil,
            "No scene switch/go/push call found")
    end)
end)
