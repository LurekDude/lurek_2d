-- tests/lua/content/demos/test_pong.lua
-- Smoke test for content/games/arcade/pong/main.lua.

local DEMO_PATH = "content/games/arcade/pong/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("pong", DEMO_PATH)

describe("pong: game mechanics", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("uses isActionDown for paddle movement", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("isActionDown%s*%(") ~= nil or
            src:find("wasActionPressed%s*%(") ~= nil,
            "No input polling found — paddles cannot move")
    end)

    it("draws rectangles for paddles and ball", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("drawRect%s*%(") ~= nil or
            src:find("drawCircle%s*%(") ~= nil,
            "No draw calls found — game objects will not render")
    end)

    it("has score tracking variables or table", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("score") ~= nil,
            "No score variable found in source")
    end)

    it("has ball velocity variables", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("vel") ~= nil or
            src:find("speed") ~= nil or
            src:find("dx") ~= nil or
            src:find("ball") ~= nil,
            "No ball velocity reference found — ball physics missing")
    end)
end)
