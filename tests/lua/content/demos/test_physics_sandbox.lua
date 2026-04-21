-- tests/lua/content/demos/test_physics_sandbox.lua
-- Smoke test for content/games/simulation/physics_sandbox/main.lua.

local DEMO_PATH = "content/games/simulation/physics_sandbox/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("physics_sandbox", DEMO_PATH)

describe("physics_sandbox: interactive physics checks", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("spawns physics bodies at mouse click", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("wasActionPressed%s*%(") ~= nil or
            src:find("wasMousePressed%s*%(") ~= nil,
            "No click-to-spawn input found")
    end)

    it("removes or limits body count", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("remove%s*%(") ~= nil or
            src:find("destroy%s*%(") ~= nil or
            src:find("MAX") ~= nil or
            src:find("limit") ~= nil,
            "No body removal or limit found — sandbox will overflow")
    end)

    it("uses gravity", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("gravity") ~= nil or
            src:find("setGravity") ~= nil,
            "No gravity reference found")
    end)

    it("draws physics shapes each frame", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("drawRect%s*%(") ~= nil or
            src:find("drawCircle%s*%(") ~= nil or
            src:find("draw%s*%(") ~= nil,
            "No draw calls found for physics body rendering")
    end)
end)
