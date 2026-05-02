-- tests/lua/demos/test_html_dialog.lua
-- Static-analysis checks for the html-dialog showcase demo.
-- read_file is injected by the test harness; not visible to LuaLS.
---@diagnostic disable: undefined-global

local PATH      = "content/games/showcase/html-dialog/main.lua"
local CONF_PATH = "content/games/showcase/html-dialog/conf.lua"

describe("demo html-dialog â€” static analysis", function()
    local src, conf_src

    before_each(function()
        src      = read_file(PATH)
        conf_src = read_file(CONF_PATH)
    end)

    it("main.lua exists", function()
        expect_not_nil(src, "html-dialog main.lua must exist")
    end)

    it("conf.lua exists", function()
        expect_not_nil(conf_src, "html-dialog conf.lua must exist")
    end)

    it("calls lurek.html.newDocument", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.html%.newDocument") ~= nil,
            "html-dialog must call newDocument"
        )
    end)

    it("rebuilds DOM via setHtml", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":setHtml") ~= nil,
            "html-dialog must call setHtml to rebuild dialog content"
        )
    end)

    it("calls relayout after bulk DOM replacement", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":relayout") ~= nil,
            "html-dialog must call relayout after setHtml"
        )
    end)

    it("uses mousepressed consumed flag to block game clicks", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":mousepressed") ~= nil,
            "html-dialog must call doc:mousepressed and check the return value"
        )
    end)

    it("wires choice button click handlers", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":on%(\"click\"") ~= nil or src:find(":on%('click'") ~= nil,
            "html-dialog must wire button click handlers via :on"
        )
    end)
end)
test_summary()
