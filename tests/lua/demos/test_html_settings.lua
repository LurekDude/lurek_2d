-- tests/lua/demos/test_html_settings.lua
-- Static-analysis checks for the html-settings showcase demo.
-- read_file is injected by the test harness; not visible to LuaLS.
---@diagnostic disable: undefined-global

local PATH      = "content/games/showcase/html-settings/main.lua"
local CONF_PATH = "content/games/showcase/html-settings/conf.lua"

describe("demo html-settings â€” static analysis", function()
    local src, conf_src

    before_each(function()
        src      = read_file(PATH)
        conf_src = read_file(CONF_PATH)
    end)

    it("main.lua exists", function()
        expect_not_nil(src, "html-settings main.lua must exist")
    end)

    it("conf.lua exists", function()
        expect_not_nil(conf_src, "html-settings conf.lua must exist")
    end)

    it("calls lurek.html.newDocument", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.html%.newDocument") ~= nil,
            "html-settings must call newDocument"
        )
    end)

    it("uses queryAll for radio button groups", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":queryAll") ~= nil,
            "html-settings must use queryAll to find radio button groups"
        )
    end)

    it("uses hasClass / addClass / removeClass for toggle state", function()
        expect_not_nil(src, 'source missing')
        local ok = src:find(":hasClass") and src:find(":addClass") and src:find(":removeClass")
        expect_true(ok ~= nil, "html-settings must use hasClass, addClass, removeClass")
    end)

    it("forwards keypressed and textinput to the document", function()
        expect_not_nil(src, 'source missing')
        local has_key  = src:find(":keypressed") ~= nil
        local has_text = src:find(":textinput")  ~= nil
        expect_true(has_key and has_text,
            "html-settings must forward keypressed and textinput for form input")
    end)

    it("defines all required lurek callbacks", function()
        expect_not_nil(src, 'source missing')
        local ok = src:find("function lurek%.load")
                and src:find("function lurek%.update")
                and src:find("function lurek%.draw")
        expect_true(ok ~= nil,
            "html-settings must define lurek.load, lurek.update, lurek.draw")
    end)
end)
test_summary()
