-- tests/lua/demos/test_html_inventory.lua
-- Static-analysis checks for the html-inventory showcase demo.

local PATH      = "content/games/showcase/html-inventory/main.lua"
local CONF_PATH = "content/games/showcase/html-inventory/conf.lua"

describe("demo html-inventory â€” static analysis", function()
    local src, conf_src

    before_each(function()
        src      = read_file(PATH)
        conf_src = read_file(CONF_PATH)
    end)

    it("main.lua exists", function()
        expect_not_nil(src, "html-inventory main.lua must exist")
    end)

    it("conf.lua exists", function()
        expect_not_nil(conf_src, "html-inventory conf.lua must exist")
    end)

    it("calls lurek.html.newDocument", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.ui%.html%.newDocument") ~= nil,
            "html-inventory must call newDocument"
        )
    end)

    it("uses queryAll to select multiple slots", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":queryAll") ~= nil,
            "html-inventory must use queryAll for bulk slot selection"
        )
    end)

    it("uses el:on to wire click handlers", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":on%(\"click\"") ~= nil or src:find(":on%('click'") ~= nil,
            "html-inventory must wire click handlers via el:on"
        )
    end)

    it("uses addClass / removeClass for selection state", function()
        if not src then pending("source missing") return end
        local has_add = src:find(":addClass") ~= nil
        local has_rem = src:find(":removeClass") ~= nil
        expect_true(has_add and has_rem,
            "html-inventory must use addClass and removeClass")
    end)

    it("defines lurek.load, lurek.update, lurek.draw", function()
        if not src then pending("source missing") return end
        local ok = src:find("function lurek%.load")
                and src:find("function lurek%.update")
                and src:find("function lurek%.draw")
        expect_true(ok ~= nil, "html-inventory must define all three lurek callbacks")
    end)
end)

test_summary()
