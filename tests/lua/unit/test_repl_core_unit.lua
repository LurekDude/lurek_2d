-- Lurek2D REPL API unit tests.
-- Headless-safe: exercises release-safe lurek.repl session creation, eval, history,
-- command handling, completion, and file loading without window, render, or input.

local function write_repl_fixture(path, source)
    lurek.filesystem.createDirectory("save/_fs_tests")
    lurek.filesystem.write(path, source)
end

-- @describe lurek.repl module
describe("lurek.repl module", function()
    -- @covers lurek.repl
    -- @covers lurek.repl.new
    it("exists as a table", function()
        expect_type("table", lurek.repl)
        expect_type("function", lurek.repl.new)
    end)
end)

-- @describe LReplSession
describe("LReplSession", function()
    -- @covers LReplSession:eval
    -- @covers lurek.repl.new
    it("evaluates expressions", function()
        local repl = lurek.repl.new(8)
        expect_equal("4", repl:eval("2 + 2"))
    end)

    -- @covers LReplSession:eval
    -- @covers lurek.repl.new
    it("evaluates statements and keeps Lua globals", function()
        local repl = lurek.repl.new(8)
        expect_equal("(ok)", repl:eval("repl_answer = 41"))
        expect_equal("42", repl:eval("repl_answer + 1"))
    end)

    -- @covers LReplSession:eval
    -- @covers LReplSession:history
    -- @covers LReplSession:len
    -- @covers lurek.repl.new
    it("keeps bounded history", function()
        local repl = lurek.repl.new(2)
        repl:eval("1")
        repl:eval("2")
        repl:eval("3")
        local history = repl:history()
        expect_equal(2, #history)
        expect_equal("2", history[1])
        expect_equal("3", history[2])
        expect_equal(2, repl:len())
    end)

    -- @covers LReplSession:eval
    -- @covers LReplSession:len
    -- @covers lurek.repl.new
    it("supports commands", function()
        local repl = lurek.repl.new(8)
        expect_contains(repl:eval(":help"), ":load")
        expect_equal("(quit)", repl:eval(":quit"))
        expect_equal("(cleared)", repl:eval(":clear"))
        expect_equal(0, repl:len())
    end)

    -- @covers LReplSession:complete
    -- @covers lurek.repl.new
    it("returns completions including lurek.repl", function()
        local repl = lurek.repl.new(8)
        local completions = repl:complete("lurek.re")
        local found = false
        for _, item in ipairs(completions) do
            if item == "lurek.repl" then
                found = true
                break
            end
        end
        expect_true(found)
    end)

    -- @covers LReplSession:eval
    -- @covers LReplSession:history
    -- @covers LReplSession:len
    -- @covers lurek.repl.new
    it(":reset returns reset confirmation and clears history", function()
        local repl = lurek.repl.new(8)
        repl:eval("1 + 1")
        repl:eval("2 + 2")
        local result = repl:eval(":reset")
        expect_equal("(reset)", result)
        expect_equal(0, #repl:history())
        expect_equal(0, repl:len())
    end)

    -- @covers LReplSession:eval
    -- @covers lurek.repl.new
    it(":load nonexistent file returns error result", function()
        local repl = lurek.repl.new(8)
        local result = repl:eval(":load __nonexistent_repl_test_file__.lua")
        expect_contains(result, "error:")
    end)

    -- @covers LReplSession:eval
    -- @covers lurek.repl.new
    it(":load with no path returns error result", function()
        local repl = lurek.repl.new(8)
        local result = repl:eval(":load")
        expect_contains(result, "error:")
    end)

    -- @covers LReplSession:eval
    -- @covers lurek.repl.new
    it(":load executes a valid file in the current session", function()
        local repl = lurek.repl.new(8)
        local path = "save/_fs_tests/repl_loaded_snippet.lua"
        write_repl_fixture(path, "loaded_value = 19")

        local result = repl:eval(":load " .. path)
        expect_contains(result, "loaded " .. path)
        expect_equal("19", repl:eval("loaded_value"))
    end)

    -- @covers LReplSession:type
    -- @covers LReplSession:typeOf
    -- @covers lurek.repl.new
    it("reports type identity", function()
        local repl = lurek.repl.new(8)
        expect_equal("LReplSession", repl:type())
        expect_true(repl:typeOf("LReplSession"))
        expect_true(repl:typeOf("Object"))
        expect_false(repl:typeOf("Other"))
    end)
end)

test_summary()
