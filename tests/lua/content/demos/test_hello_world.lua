-- tests/lua/content/demos/test_hello_world.lua
-- Smoke test for content/games/showcase/hello_world/main.lua.

local DEMO_PATH = "content/games/showcase/hello_world/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("hello_world", DEMO_PATH)

describe("hello_world: content checks", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("calls lurek.render.print or drawText to display greeting", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.render%.print%s*%(") ~= nil or
            src:find("lurek%.render%.drawText%s*%(") ~= nil,
            "No text rendering call found — 'Hello World' will not appear")
    end)

    it("has some form of quit binding or quit handling", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("quit") ~= nil,
            "No quit handling — game has no exit path")
    end)
end)
