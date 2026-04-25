-- tests/lua/demos/test_html_scoreboard.lua
-- Static-analysis checks for the html-scoreboard showcase demo.

local PATH      = "content/games/showcase/html-scoreboard/main.lua"
local CONF_PATH = "content/games/showcase/html-scoreboard/conf.lua"

describe("demo html-scoreboard â€” static analysis", function()
    local src, conf_src

    before_each(function()
        src      = read_file(PATH)
        conf_src = read_file(CONF_PATH)
    end)

    it("main.lua exists", function()
        expect_not_nil(src, "html-scoreboard main.lua must exist")
    end)

    it("conf.lua exists", function()
        expect_not_nil(conf_src, "html-scoreboard conf.lua must exist")
    end)

    it("calls lurek.html.newDocument", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.ui%.html%.newDocument") ~= nil,
            "html-scoreboard must call newDocument"
        )
    end)

    it("uses HTML table markup (<table>)", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("<table") ~= nil,
            "html-scoreboard must use <table> markup"
        )
    end)

    it("calls setHtml + relayout to refresh the board", function()
        if not src then pending("source missing") return end
        local has_set = src:find(":setHtml") ~= nil
        local has_rel = src:find(":relayout") ~= nil
        expect_true(has_set and has_rel,
            "html-scoreboard must call setHtml and relayout when data changes")
    end)

    it("sorts scores before rendering", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("table%.sort") ~= nil,
            "html-scoreboard must sort scores before building the table"
        )
    end)

    it("defines all required lurek callbacks", function()
        if not src then pending("source missing") return end
        local ok = src:find("function lurek%.load")
                and src:find("function lurek%.update")
                and src:find("function lurek%.draw")
        expect_true(ok ~= nil,
            "html-scoreboard must define lurek.load, lurek.update, lurek.draw")
    end)
end)

test_summary()
