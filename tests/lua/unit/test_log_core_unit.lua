-- Lurek2D logging API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the lurek.log namespace: level control, message functions,
-- addSink, removeSink, clearSinks, listSinks, readMemory, flushFile.

-- Module presence
-- @describe lurek.log module
describe("lurek.log module", function()
    -- @covers lurek.log
    it("lurek.log is a table", function()
        expect_type("table", lurek.log)
    end)

    -- @covers lurek.log
    it("all expected functions are present", function()
        local fns = {
            "debug", "info", "warn", "error", "print",
            "setLevel", "getLevel",
            "addSink", "removeSink", "clearSinks", "listSinks",
            "readMemory", "flushFile",
        }
        for _, name in ipairs(fns) do
            expect_type("function", lurek.log[name], name .. " must be a function")
        end
    end)
end)

-- Level control
-- @describe lurek.log.setLevel / getLevel
describe("lurek.log.setLevel / getLevel", function()
    -- @covers lurek.log.getLevel
    it("getLevel returns a string", function()
        expect_type("string", lurek.log.getLevel())
    end)

    -- @covers lurek.log.getLevel
    -- @covers lurek.log.setLevel
    it("setLevel to debug is reflected by getLevel", function()
        lurek.log.setLevel("debug")
        expect_equal("debug", lurek.log.getLevel())
    end)

    -- @covers lurek.log.getLevel
    -- @covers lurek.log.setLevel
    it("setLevel to warn is reflected by getLevel", function()
        lurek.log.setLevel("warn")
        expect_equal("warn", lurek.log.getLevel())
    end)

    -- @covers lurek.log.getLevel
    -- @covers lurek.log.setLevel
    it("setLevel to info is reflected by getLevel", function()
        lurek.log.setLevel("info")
        expect_equal("info", lurek.log.getLevel())
    end)

    -- @covers lurek.log.getLevel
    -- @covers lurek.log.setLevel
    it("setLevel to error is reflected by getLevel", function()
        lurek.log.setLevel("error")
        expect_equal("error", lurek.log.getLevel())
    end)
end)

-- Basic log calls
-- @describe lurek.log message functions
describe("lurek.log message functions", function()
    -- @covers lurek.log.info
    it("info does not error", function()
        expect_no_error(function() lurek.log.info("unit test info message") end)
    end)

    -- @covers lurek.log.warn
    it("warn does not error", function()
        expect_no_error(function() lurek.log.warn("unit test warn message") end)
    end)

    -- @covers lurek.log.error
    it("error call does not error", function()
        expect_no_error(function() lurek.log.error("unit test error message") end)
    end)

    -- @covers lurek.log.debug
    -- @covers lurek.log.setLevel
    it("debug does not error at debug level", function()
        lurek.log.setLevel("debug")
        expect_no_error(function() lurek.log.debug("unit test debug message") end)
    end)

    -- @covers lurek.log.print
    it("print does not error", function()
        expect_no_error(function() lurek.log.print("info", "unit test print message") end)
    end)
end)

-- Memory sink
-- @describe lurek.log.addSink memory sink
describe("lurek.log.addSink memory sink", function()
    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.removeSink
    it("addSink with type=memory returns a sink id number", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory" })
        expect_type("number", id)
        lurek.log.removeSink(id)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    it("readMemory returns a table for a valid memory sink id", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory" })
        local entries = lurek.log.readMemory(id)
        expect_type("table", entries)
        lurek.log.removeSink(id)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
    it("messages logged after addSink appear in readMemory", function()
        lurek.log.clearSinks()
        lurek.log.setLevel("debug")
        local id = lurek.log.addSink({ type = "memory" })
        lurek.log.info("memory_sink_msg_alpha")
        local entries = lurek.log.readMemory(id)
        lurek.log.removeSink(id)
        expect_true(#entries >= 1, "at least one entry captured")
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
    it("readMemory entries have a message field", function()
        lurek.log.clearSinks()
        lurek.log.setLevel("debug")
        local id = lurek.log.addSink({ type = "memory" })
        lurek.log.info("check_entry_structure")
        local entries = lurek.log.readMemory(id)
        lurek.log.removeSink(id)
        expect_true(#entries >= 1, "expected at least one entry")
        expect_type("string", entries[1].message)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
    it("readMemory with drain=true clears the buffer", function()
        lurek.log.clearSinks()
        lurek.log.setLevel("debug")
        local id = lurek.log.addSink({ type = "memory" })
        lurek.log.info("before_drain")
        local first  = lurek.log.readMemory(id, true)
        local second = lurek.log.readMemory(id)
        lurek.log.removeSink(id)
        expect_true(#first >= 1, "first read should have entries")
        expect_equal(0, #second, "buffer should be empty after drain")
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
    it("readMemory with drain=false does not clear the buffer", function()
        lurek.log.clearSinks()
        lurek.log.setLevel("debug")
        local id = lurek.log.addSink({ type = "memory" })
        lurek.log.info("no_drain_msg")
        local first  = lurek.log.readMemory(id, false)
        local second = lurek.log.readMemory(id, false)
        lurek.log.removeSink(id)
        expect_true(#first >= 1,  "first read should have entries")
        expect_true(#second >= 1, "second read should still have entries")
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
    -- @covers lurek.log.warn
    it("memory sink level='warning' drops info and keeps warn", function()
        lurek.log.clearSinks()
        lurek.log.setLevel("debug")
        local id = lurek.log.addSink({ type = "memory", level = "warning" })
        lurek.log.info("warning_alias_drop_info")
        lurek.log.warn("warning_alias_keep_warn")
        local entries = lurek.log.readMemory(id)
        lurek.log.removeSink(id)

        expect_equal(#entries, 1)
        expect_true(entries[1].message:find("warning_alias_keep_warn") ~= nil)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.debug
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
    it("memory sink unknown level falls back to debug", function()
        lurek.log.clearSinks()
        lurek.log.setLevel("debug")
        local id = lurek.log.addSink({ type = "memory", level = "mystery" })
        lurek.log.debug("unknown_level_defaults_to_debug")
        local entries = lurek.log.readMemory(id)
        lurek.log.removeSink(id)

        expect_true(#entries >= 1)
        expect_true(entries[#entries].message:find("unknown_level_defaults_to_debug") ~= nil)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
    it("multiple memory sinks capture messages independently", function()
        lurek.log.clearSinks()
        lurek.log.setLevel("debug")
        local id1 = lurek.log.addSink({ type = "memory" })
        local id2 = lurek.log.addSink({ type = "memory" })
        lurek.log.info("multi_sink_test")
        local e1 = lurek.log.readMemory(id1)
        local e2 = lurek.log.readMemory(id2)
        lurek.log.removeSink(id1)
        lurek.log.removeSink(id2)
        expect_true(#e1 >= 1, "sink 1 captured message")
        expect_true(#e2 >= 1, "sink 2 captured message")
    end)
end)

-- removeSink / clearSinks / listSinks
-- @describe lurek.log.removeSink / clearSinks / listSinks
describe("lurek.log.removeSink / clearSinks / listSinks", function()
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.listSinks
    it("listSinks returns a table", function()
        lurek.log.clearSinks()
        local sinks = lurek.log.listSinks()
        expect_type("table", sinks)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.listSinks
    -- @covers lurek.log.removeSink
    it("listSinks reflects newly added sinks", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory" })
        local sinks = lurek.log.listSinks()
        expect_true(#sinks >= 1, "at least one sink listed")
        lurek.log.removeSink(id)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.listSinks
    -- @covers lurek.log.removeSink
    it("removeSink decreases listSinks count", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory" })
        local before = #lurek.log.listSinks()
        lurek.log.removeSink(id)
        local after = #lurek.log.listSinks()
        expect_true(after < before, "count decreased after removeSink")
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.listSinks
    it("clearSinks leaves listSinks empty", function()
        lurek.log.addSink({ type = "memory" })
        lurek.log.addSink({ type = "memory" })
        lurek.log.clearSinks()
        expect_equal(0, #lurek.log.listSinks())
    end)
end)

-- File sink
-- @describe lurek.log.addSink file sink
describe("lurek.log.addSink file sink", function()
    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.removeSink
    it("addSink with type=file returns a sink id", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "file", path = "save/_log_test_sink.log" })
        expect_type("number", id)
        lurek.log.removeSink(id)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.flushFile
    -- @covers lurek.log.info
    -- @covers lurek.log.removeSink
    it("flushFile does not error for a valid file sink id", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "file", path = "save/_log_flush_test.log" })
        lurek.log.info("flush_test_msg")
        expect_no_error(function() lurek.log.flushFile(id) end)
        lurek.log.removeSink(id)
    end)
end)

-- @describe log sink registry (RS parity)
describe("log sink registry (RS parity)", function()
    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.removeSink
    it("clearSinks starts empty then addSink increments count", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory", capacity = 10 })
        expect_type("number", id)
        expect_true(id > 0)
        lurek.log.removeSink(id)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.removeSink
    it("removeSink returns true on first call, false on second", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory", capacity = 10 })
        expect_true(lurek.log.removeSink(id))
        expect_false(lurek.log.removeSink(id))
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
    it("messages written to memory sink are retrievable", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory", capacity = 20 })
        lurek.log.setLevel("debug")
        lurek.log.info("sink_parity_test_msg")
        local entries = lurek.log.readMemory(id)
        expect_equal("table", type(entries))
        expect_true(#entries >= 1)
        lurek.log.removeSink(id)
        lurek.log.setLevel("info")
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.debug
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
    it("memory sink respects capacity and drops oldest on overflow", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory", capacity = 3 })
        lurek.log.setLevel("debug")
        for i = 1, 5 do lurek.log.debug("msg" .. i) end
        local entries = lurek.log.readMemory(id)
        expect_true(#entries <= 3)
        lurek.log.removeSink(id)
        lurek.log.setLevel("info")
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.removeSink
    it("clearSinks removes all sinks", function()
        local id = lurek.log.addSink({ type = "memory", capacity = 5 })
        lurek.log.clearSinks()
        expect_false(lurek.log.removeSink(id))
    end)
end)

-- Restore defaults
lurek.log.setLevel("info")
lurek.log.clearSinks()

-- Log API validation (merged from test_log_api.lua)

--              type safety, level validation, and rotating sink support.

-- @describe lurek.log namespace
describe("lurek.log namespace", function()
    -- @covers lurek.log.info
    it("has info function", function()
        expect_equal(type(lurek.log.info), "function")
    end)

    -- @covers lurek.log.warn
    it("has warn function", function()
        expect_equal(type(lurek.log.warn), "function")
    end)

    -- @covers lurek.log.error
    it("has error function", function()
        expect_equal(type(lurek.log.error), "function")
    end)

    -- @covers lurek.log.debug
    it("has debug function", function()
        expect_equal(type(lurek.log.debug), "function")
    end)

    -- @covers lurek.log.setLevel
    it("has setLevel function", function()
        expect_equal(type(lurek.log.setLevel), "function")
    end)

    -- @covers lurek.log.info
    it("logs without error", function()
        local ok = pcall(function()
            lurek.log.info("test message from Lua")
        end)
        expect_true(ok)
    end)

    -- @covers lurek.log.info
    it("errors on non-string message", function()
        local bad_message = lurek.__missing_log_message
        expect_error(function() lurek.log.info(bad_message) end)
    end)

    -- @covers lurek.log.setLevel
    it("errors on invalid level string", function()
        expect_error(function() lurek.log.setLevel("verbose") end)
    end)
end)

-- Level round-trip
-- @describe lurek.log.setLevel validation
describe("lurek.log.setLevel validation", function()
    -- @covers lurek.log.setLevel
    it("accepts error level", function()
        expect_no_error(function() lurek.log.setLevel("error") end)
    end)

    -- @covers lurek.log.setLevel
    it("accepts warn level", function()
        expect_no_error(function() lurek.log.setLevel("warn") end)
    end)

    -- @covers lurek.log.setLevel
    it("accepts info level", function()
        expect_no_error(function() lurek.log.setLevel("info") end)
    end)

    -- @covers lurek.log.setLevel
    it("accepts debug level", function()
        expect_no_error(function() lurek.log.setLevel("debug") end)
    end)

    -- @covers lurek.log.setLevel
    it("accepts off level", function()
        expect_no_error(function() lurek.log.setLevel("off") end)
    end)

    -- @covers lurek.log.setLevel
    it("rejects unknown level 'verbose'", function()
        expect_error(function() lurek.log.setLevel("verbose") end)
    end)

    -- @covers lurek.log.setLevel
    it("rejects unknown level 'critical'", function()
        expect_error(function() lurek.log.setLevel("critical") end)
    end)
end)

-- Rotating sink
-- @describe lurek.log rotating sink
describe("lurek.log rotating sink", function()
    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.removeSink
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

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.setLevel
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

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.listSinks
    -- @covers lurek.log.removeSink
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

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    it("addSink type=rotating errors when path is missing", function()
        lurek.log.clearSinks()
        expect_error(function()
            lurek.log.addSink({ type = "rotating" })
        end)
    end)
end)

-- Restore defaults (post-merge)
lurek.log.setLevel("info")
lurek.log.clearSinks()

--  Structured Logging (merged from test_log_structured.lua)

-- @describe lurek.log.struct  basic API
describe("lurek.log.struct  basic API", function()
    -- @covers lurek.log.struct
    it("does not error when called with a non-empty fields table", function()
        lurek.log.struct("info", "hello structured", {key = "value", count = 42})
    end)

    -- @covers lurek.log.struct
    it("does not error with an empty fields table", function()
        lurek.log.struct("debug", "no fields", {})
    end)

    -- @covers lurek.log.struct
    it("accepts all log levels", function()
        lurek.log.struct("debug", "debug msg", {a = "1"})
        lurek.log.struct("info",  "info msg",  {b = "2"})
        lurek.log.struct("warn",  "warn msg",  {c = "3"})
        lurek.log.struct("error", "error msg", {d = "4"})
    end)

    -- @covers lurek.log.struct
    it("accepts number values in fields (converted to string)", function()
        lurek.log.struct("info", "frame stats", {fps = 60, draw_calls = 128})
    end)

    -- @covers lurek.log.struct
    it("accepts boolean values in fields", function()
        lurek.log.struct("debug", "flags", {vsync = true, fullscreen = false})
    end)
end)

-- @describe lurek.log.*_fields shorthands
describe("lurek.log.*_fields shorthands", function()
    -- @covers lurek.log.debug_fields
    it("debug_fields does not error", function()
        lurek.log.debug_fields("debug shorthand", {x = 1})
    end)

    -- @covers lurek.log.info_fields
    it("info_fields does not error", function()
        lurek.log.info_fields("info shorthand", {y = 2})
    end)

    -- @covers lurek.log.warn_fields
    it("warn_fields does not error", function()
        lurek.log.warn_fields("warn shorthand", {z = 3})
    end)

    -- @covers lurek.log.error_fields
    it("error_fields does not error", function()
        lurek.log.error_fields("error shorthand", {w = 4})
    end)

    -- @covers lurek.log.info_fields
    it("shorthand with empty table does not error", function()
        lurek.log.info_fields("no fields", {})
    end)
end)

-- @describe lurek.log memory sink  structured entries
describe("lurek.log memory sink  structured entries", function()
    -- @covers lurek.log.addSink
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.struct
    it("memory sink captures structured entry with fields", function()
        local sid = lurek.log.addSink({type = "memory", capacity = 50, level = "debug"})

        lurek.log.struct("info", "structured msg", {player = "Alice", score = "100"})

        local entries = lurek.log.readMemory(sid)
        expect_equal(entries ~= nil, true)
        expect_equal(#entries >= 1, true)

        -- find the structured entry
        local found = nil
        for _, e in ipairs(entries) do
            if e.message and e.message:find("structured msg") then
                found = e
                break
            end
        end
        expect_equal(found ~= nil, true)
        local fields = found and found["fields"] or nil
        expect_equal(fields ~= nil, true)
        if fields ~= nil then
            expect_equal(fields["player"], "Alice")
            expect_equal(fields["score"], "100")
        end

        lurek.log.removeSink(sid)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    it("plain log entries have nil fields", function()
        local sid = lurek.log.addSink({type = "memory", capacity = 50, level = "debug"})

        lurek.log.info("plain entry without fields")

        local entries = lurek.log.readMemory(sid)
        expect_equal(entries ~= nil, true)
        expect_equal(#entries >= 1, true)

        local found = nil
        for _, e in ipairs(entries) do
            if e.message and e.message:find("plain entry without fields") then
                found = e
                break
            end
        end
        expect_equal(found ~= nil, true)
        expect_equal(found and found["fields"] or nil, nil)

        lurek.log.removeSink(sid)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.debug_fields
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    it("debug_fields shorthand also stores fields in memory sink", function()
        local sid = lurek.log.addSink({type = "memory", capacity = 50, level = "debug"})

        lurek.log.debug_fields("shorthand fields test", {module = "tween", dt = "0.016"})

        local entries = lurek.log.readMemory(sid)
        local found = nil
        for _, e in ipairs(entries) do
            if e.message and e.message:find("shorthand fields test") then
                found = e
                break
            end
        end
        expect_equal(found ~= nil, true)
        local fields = found and found["fields"] or nil
        expect_equal(fields ~= nil, true)
        if fields ~= nil then
            expect_equal(fields["module"], "tween")
        end

        lurek.log.removeSink(sid)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.struct
    it("readMemory returns multiple structured entries in order", function()
        local sid = lurek.log.addSink({type = "memory", capacity = 50, level = "debug"})

        lurek.log.struct("info", "entry A", {seq = "1"})
        lurek.log.struct("info", "entry B", {seq = "2"})

        local entries = lurek.log.readMemory(sid)
        expect_equal(#entries >= 2, true)

        lurek.log.removeSink(sid)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.struct
    it("drain clears memory sink after read", function()
        local sid = lurek.log.addSink({type = "memory", capacity = 50})

        lurek.log.struct("debug", "drain test", {x = "1"})
        local first  = lurek.log.readMemory(sid, true)   -- drain
        local second = lurek.log.readMemory(sid)          -- should be empty now

        expect_equal(#first >= 1, true)
        expect_equal(#second, 0)

        lurek.log.removeSink(sid)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.struct
    it("fields table contains number values converted to string", function()
        local sid = lurek.log.addSink({type = "memory", capacity = 10, level = "debug"})

        lurek.log.struct("info", "numeric fields", {fps = 60, calls = 1024})

        local entries = lurek.log.readMemory(sid)
        local found = nil
        for _, e in ipairs(entries) do
            if e.message and e.message:find("numeric fields") then
                found = e
                break
            end
        end
        expect_equal(found ~= nil, true)
        local fields = found and found["fields"] or nil
        expect_equal(fields ~= nil, true)
        -- values are stored as strings
        if fields ~= nil then
            expect_equal(type(fields["fps"]), "string")
        end

        lurek.log.removeSink(sid)
    end)
end)

-- @describe lurek.log memory sink  plain + structured mixed
describe("lurek.log memory sink  plain + structured mixed", function()
    -- @covers lurek.log.addSink
    -- @covers lurek.log.debug
    -- @covers lurek.log.debug_fields
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    it("mixed plain and structured entries coexist in memory sink", function()
        local sid = lurek.log.addSink({type = "memory", capacity = 50, level = "debug"})

        lurek.log.debug("plain A")
        lurek.log.debug_fields("structured B", {k = "v"})
        lurek.log.info("plain C")

        local entries = lurek.log.readMemory(sid)
        expect_equal(#entries >= 3, true)

        lurek.log.removeSink(sid)
    end)
end)

-- @describe lurek.log advanced sink options
describe("lurek.log advanced sink options", function()
    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.removeSink
    it("memory sink filters by tag", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({
            type = "memory",
            level = "debug",
            tags = { "Allowed" },
        })

        lurek.log.info("tagged_message_ok", "Allowed")
        lurek.log.info("tagged_message_skip", "Blocked")

        local entries = lurek.log.readMemory(id)
        lurek.log.removeSink(id)

        expect_equal(1, #entries)
        expect_equal("Allowed", entries[1].tag)
        expect_true(entries[1].message:find("tagged_message_ok") ~= nil)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.info
    -- @covers lurek.log.removeSink
    it("callback sink receives pushed log records", function()
        lurek.log.clearSinks()
        local seen = {}
        local id = lurek.log.addSink({
            type = "callback",
            level = "debug",
            callback = function(record)
                table.insert(seen, record)
            end,
        })

        lurek.log.info("callback_message", "Ui")
        lurek.log.removeSink(id)

        expect_equal(1, #seen)
        expect_equal("info", seen[1].level)
        expect_equal("Ui", seen[1].tag)
        expect_true(seen[1].message:find("callback_message") ~= nil)
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.flushFile
    -- @covers lurek.log.info
    -- @covers lurek.log.removeSink
    it("file sink can emit timestamped plain lines", function()
        lurek.log.clearSinks()
        local path = "save/_log_timestamp_test.log"
        local id = lurek.log.addSink({
            type = "file",
            path = path,
            timestamp = true,
        })

        lurek.log.info("timestamped_line", "Time")
        lurek.log.flushFile(id)
        lurek.log.removeSink(id)

        local content = assert(lurek.filesystem.read(path))

        expect_true(content:find("^%[%d+%]") ~= nil, "timestamp prefix missing")
        expect_true(content:find("timestamped_line") ~= nil, "message missing")
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.flushFile
    -- @covers lurek.log.info
    -- @covers lurek.log.removeSink
    it("file sink can emit ANSI-coloured plain lines", function()
        lurek.log.clearSinks()
        local path = "save/_log_ansi_test.log"
        local id = lurek.log.addSink({
            type = "file",
            path = path,
            ansi = true,
        })

        lurek.log.info("ansi_line", "Ansi")
        lurek.log.flushFile(id)
        lurek.log.removeSink(id)

        local content = assert(lurek.filesystem.read(path))

        expect_true(content:find("\27%[") ~= nil, "ANSI escape sequence missing")
        expect_true(content:find("ansi_line") ~= nil, "message missing")
    end)

    -- @covers lurek.log.addSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.flushFile
    -- @covers lurek.log.info
    -- @covers lurek.log.removeSink
    it("file sink can emit JSON lines", function()
        lurek.log.clearSinks()
        local path = "save/_log_json_test.log"
        local id = lurek.log.addSink({
            type = "file",
            path = path,
            format = "json",
        })

        lurek.log.info("json_line", "Json")
        lurek.log.flushFile(id)
        lurek.log.removeSink(id)

        local content = assert(lurek.filesystem.read(path))

        expect_true(content:find('"level":"info"') ~= nil, "JSON level missing")
        expect_true(content:find('"message":"json_line"') ~= nil, "JSON message missing")
    end)
end)
test_summary()
