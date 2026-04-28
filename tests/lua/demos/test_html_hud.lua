-- tests/lua/demos/test_html_hud.lua
-- Static-analysis checks for the html-hud showcase demo.
-- Verifies that the game script exists and uses the expected lurek.html API.
-- read_file is injected by the test harness; not visible to LuaLS.
---@diagnostic disable: undefined-global

local PATH      = "content/games/showcase/html-hud/main.lua"
local CONF_PATH = "content/games/showcase/html-hud/conf.lua"

describe("demo html-hud â€” static analysis", function()
    local src, conf_src

    before_each(function()
        src      = read_file(PATH)
        conf_src = read_file(CONF_PATH)
    end)

    it("main.lua exists and is readable", function()
        expect_not_nil(src, "html-hud main.lua must be readable via read_file")
    end)

    it("conf.lua exists and is readable", function()
        expect_not_nil(conf_src, "html-hud conf.lua must be readable via read_file")
    end)

    it("calls lurek.html.newDocument", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.html%.newDocument") ~= nil,
            "html-hud must call lurek.html.newDocument"
        )
    end)

    it("forwards mousemoved to the HTML document", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("hud:mousemoved") ~= nil or src:find("doc:mousemoved") ~= nil,
            "html-hud must forward mousemoved to the HUD document"
        )
    end)

    it("calls hud:render() to render the overlay", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":render%(%s*%)") ~= nil,
            "html-hud must call :render() on the HUD document"
        )
    end)

    it("defines lurek.load callback", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("function lurek%.load") ~= nil,
            "html-hud must define lurek.load"
        )
    end)

    it("defines lurek.update callback", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("function lurek%.update") ~= nil,
            "html-hud must define lurek.update"
        )
    end)

    it("defines lurek.draw callback", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("function lurek%.draw") ~= nil,
            "html-hud must define lurek.draw"
        )
    end)
end)

test_summary()
