-- Lurek2D lurek.log API validation tests  (test_log_api.lua)
-- Headless-safe (no window / GPU / audio required).
-- Covers: function presence, nil-message rejection, setLevel error on invalid
-- level, normal logging, and rotating sink creation.

-- @description Validates the core lurek.log.* function contract: presence,
--              type safety, level validation, and rotating sink support.

describe("lurek.log namespace", function()
    -- @description Confirms the global lurek.log value is a table.
    it("has info function", function()
        expect_equal(type(lurek.log.info), "function")
    end)

    -- @description Checks that warn is a callable function.
    it("has warn function", function()
        expect_equal(type(lurek.log.warn), "function")
    end)

    -- @description Checks that error is a callable function.
    it("has error function", function()
        expect_equal(type(lurek.log.error), "function")
    end)

    -- @description Checks that debug is a callable function.
    it("has debug function", function()
        expect_equal(type(lurek.log.debug), "function")
    end)

    -- @description Checks that setLevel is a callable function.
    it("has setLevel function", function()
        expect_equal(type(lurek.log.setLevel), "function")
    end)

    -- @description Calls info with a valid string and expects no error.
    it("logs without error", function()
        lurek.log.info("test message from Lua")
        expect_equal(true, true)
    end)

    -- @description Passes nil to info and expects a Lua type error.
    it("errors on non-string message", function()
        expect_error(function() lurek.log.info(nil) end)
    end)

    -- @description Passes an unrecognised level string and expects an error.
    it("errors on invalid level string", function()
        expect_error(function() lurek.log.setLevel("verbose") end)
    end)
end)

-- Level round-trip
describe("lurek.log.setLevel validation", function()
    -- @description Each accepted level name should be accepted without error.
    it("accepts error level", function()
        expect_no_error(function() lurek.log.setLevel("error") end)
    end)

    it("accepts warn level", function()
        expect_no_error(function() lurek.log.setLevel("warn") end)
    end)

    it("accepts info level", function()
        expect_no_error(function() lurek.log.setLevel("info") end)
    end)

    it("accepts debug level", function()
        expect_no_error(function() lurek.log.setLevel("debug") end)
    end)

    it("accepts off level", function()
        expect_no_error(function() lurek.log.setLevel("off") end)
    end)

    -- @description Rejects a completely unknown string.
    it("rejects unknown level 'verbose'", function()
        expect_error(function() lurek.log.setLevel("verbose") end)
    end)

    it("rejects unknown level 'critical'", function()
        expect_error(function() lurek.log.setLevel("critical") end)
    end)
end)

-- Rotating sink
describe("lurek.log rotating sink", function()
    -- @description Creates a rotating sink at a temp path and expects a numeric id.
    it("addSink type=rotating returns a number id", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({
            type       = "rotating",
            path       = "save/_test_rotate.log",
            level      = "debug",
            max_bytes  = 4096,
            keep_files = 2,
        })
        expect_type("number", id)
        expect_true(id > 0)
        lurek.log.removeSink(id)
    end)

    -- @description Writes to a rotating sink and verifies no error occurs.
    it("writing to rotating sink does not error", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({
            type      = "rotating",
            path      = "save/_test_rotate2.log",
            max_bytes = 4096,
        })
        lurek.log.setLevel("debug")
        expect_no_error(function() lurek.log.info("rotation test message") end)
        lurek.log.removeSink(id)
    end)

    -- @description listSinks reports type="rotating" for a rotating sink.
    it("listSinks reflects rotating type correctly", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({
            type = "rotating",
            path = "save/_test_rotate3.log",
        })
        local sinks = lurek.log.listSinks()
        local found = false
        for _, s in ipairs(sinks) do
            if s.id == id and s.type == "rotating" then
                found = true
            end
        end
        lurek.log.removeSink(id)
        expect_true(found, "expected rotating type in listSinks")
    end)

    -- @description Rejects addSink type=rotating when path is missing.
    it("addSink type=rotating errors when path is missing", function()
        lurek.log.clearSinks()
        expect_error(function()
            lurek.log.addSink({ type = "rotating" })
        end)
    end)
end)

-- Restore defaults
lurek.log.setLevel("info")
lurek.log.clearSinks()
test_summary()
