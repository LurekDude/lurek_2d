-- tests/lua/content/demos/test_tween_demo.lua
-- Smoke test for content/games/showcase/tween_demo/main.lua.

local DEMO_PATH = "content/games/showcase/tween_demo/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("tween_demo", DEMO_PATH)

describe("tween_demo: tween API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("creates a tween (lurek.tween.new or tween())", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.tween%.new") ~= nil or
            src:find("lurek%.tween%.to") ~= nil or
            src:find("lurek%.tween%(") ~= nil,
            "No tween creation call found")
    end)

    it("updates tweens or uses auto-update", function()
        if not src then pending("source missing") return end
        -- Either explicit :update(dt) call or lurek.tween global update
        local has_update = src:find(":update%s*%(") ~= nil or
                           src:find("lurek%.tween%.update%s*%(") ~= nil or
                           src:find("tween.*update") ~= nil
        expect_true(has_update, "No tween update call found — tweens will not animate")
    end)

    it("does not use lurek.tween.create (wrong factory)", function()
        if not src then pending("source missing") return end
        expect_false(
            src:find("lurek%.tween%.create%s*%(") ~= nil,
            "lurek.tween.create() is invalid — use lurek.tween.new()")
    end)

    it("uses an easing function or easing string", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("ease") ~= nil or src:find("linear") ~= nil or src:find("quad") ~= nil,
            "No easing reference found — tween uses no easing function")
    end)
end)
