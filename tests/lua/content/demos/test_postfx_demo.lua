-- tests/lua/content/demos/test_postfx_demo.lua
-- Smoke test for content/games/showcase/postfx_demo/main.lua.

local DEMO_PATH = "content/games/showcase/postfx_demo/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("postfx_demo", DEMO_PATH)

describe("postfx_demo: post-processing API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("uses lurek.effect for post-processing", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.effect") ~= nil,
            "No lurek.effect reference found — demo has no post-processing")
    end)

    it("applies or creates at least one effect pass", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.effect%.new%s*%(") ~= nil or
            src:find("lurek%.effect%.apply%s*%(") ~= nil or
            src:find("lurek%.effect%.bloom") ~= nil or
            src:find("lurek%.effect%.blur") ~= nil or
            src:find("lurek%.effect%.vignette") ~= nil or
            src:find(":apply%s*%(") ~= nil,
            "No effect application call found")
    end)

    it("does not use lurek.postfx (old namespace)", function()
        if not src then pending("source missing") return end
        expect_false(
            src:find("lurek%.postfx") ~= nil,
            "Old namespace lurek.postfx found — use lurek.effect")
    end)
end)
