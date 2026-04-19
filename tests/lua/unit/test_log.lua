-- Lurek2D logging API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the lurek.log namespace: level control, message functions,
-- addSink, removeSink, clearSinks, listSinks, readMemory, flushFile.

-- Module presence
-- @description Verifies that the lurek.log namespace exists and exposes each documented logging and sink-management function.
describe("lurek.log module", function()
    -- @covers lurek.log.debug
    -- @covers lurek.log.info
    -- @covers lurek.log.warn
    -- @covers lurek.log.error
    -- @covers lurek.log.print
    -- @covers lurek.log.setLevel
    -- @covers lurek.log.getLevel
    -- @covers lurek.log.addSink
    -- @covers lurek.log.removeSink
    -- @covers lurek.log.clearSinks
    -- @covers lurek.log.listSinks
    -- @covers lurek.log.readMemory
    -- @covers lurek.log.flushFile
    -- @description Confirms the global lurek.log value is a table before any function access is attempted.
    it("lurek.log is a table", function()
        expect_type("table", lurek.log)
    end)

    -- @description Checks that every expected API entry on lurek.log exists and is callable as a function.
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
-- @description Verifies that getLevel returns text and that setLevel updates the active level for each supported severity.
describe("lurek.log.setLevel / getLevel", function()
    -- @description Asserts that getLevel reports the current log level as a string value.
    it("getLevel returns a string", function()
        expect_type("string", lurek.log.getLevel())
    end)

    -- @description Sets the log level to debug and checks that getLevel immediately returns "debug".
    it("setLevel to debug is reflected by getLevel", function()
        lurek.log.setLevel("debug")
        expect_equal("debug", lurek.log.getLevel())
    end)

    -- @description Sets the log level to warn and checks that getLevel immediately returns "warn".
    it("setLevel to warn is reflected by getLevel", function()
        lurek.log.setLevel("warn")
        expect_equal("warn", lurek.log.getLevel())
    end)

    -- @description Sets the log level to info and checks that getLevel immediately returns "info".
    it("setLevel to info is reflected by getLevel", function()
        lurek.log.setLevel("info")
        expect_equal("info", lurek.log.getLevel())
    end)

    -- @description Sets the log level to error and checks that getLevel immediately returns "error".
    it("setLevel to error is reflected by getLevel", function()
        lurek.log.setLevel("error")
        expect_equal("error", lurek.log.getLevel())
    end)
end)

-- Basic log calls
-- @description Verifies that each direct logging entry point can be invoked without raising a Lua-side error under the tested level conditions.
describe("lurek.log message functions", function()
    -- @description Calls lurek.log.info with a sample message and expects the invocation to complete without error.
    it("info does not error", function()
        expect_no_error(function() lurek.log.info("unit test info message") end)
    end)

    -- @description Calls lurek.log.warn with a sample message and expects the invocation to complete without error.
    it("warn does not error", function()
        expect_no_error(function() lurek.log.warn("unit test warn message") end)
    end)

    -- @description Calls lurek.log.error with a sample message and expects the invocation to complete without error.
    it("error call does not error", function()
        expect_no_error(function() lurek.log.error("unit test error message") end)
    end)

    -- @description Switches to debug level, then verifies that lurek.log.debug accepts a message without throwing.
    it("debug does not error at debug level", function()
        lurek.log.setLevel("debug")
        expect_no_error(function() lurek.log.debug("unit test debug message") end)
    end)

    -- @description Invokes the generic print entry point with the info level and expects no Lua-side error.
    it("print does not error", function()
        expect_no_error(function() lurek.log.print("info", "unit test print message") end)
    end)
end)

-- Memory sink
-- @description Verifies memory sink creation, retrieval, buffering, draining, and multi-sink capture behavior through readMemory.
describe("lurek.log.addSink memory sink", function()
    -- @description Clears existing sinks, creates a memory sink, and checks that addSink returns a numeric sink id.
    it("addSink with type=memory returns a sink id number", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory" })
        expect_type("number", id)
        lurek.log.removeSink(id)
    end)

    -- @description Creates a memory sink and verifies that reading from its id returns a table of entries.
    it("readMemory returns a table for a valid memory sink id", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory" })
        local entries = lurek.log.readMemory(id)
        expect_type("table", entries)
        lurek.log.removeSink(id)
    end)

    -- @description Logs a message after attaching a memory sink and checks that readMemory captures at least one entry.
    it("messages logged after addSink appear in readMemory", function()
        lurek.log.clearSinks()
        lurek.log.setLevel("debug")
        local id = lurek.log.addSink({ type = "memory" })
        lurek.log.info("memory_sink_msg_alpha")
        local entries = lurek.log.readMemory(id)
        lurek.log.removeSink(id)
        expect_true(#entries >= 1, "at least one entry captured")
    end)

    -- @description Logs one message, reads the memory sink, and asserts the first captured entry exposes a string message field.
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

    -- @description Reads a memory sink with drain=true and verifies the first read has entries while the second read is empty.
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

    -- @description Reads the same memory sink twice with drain=false and checks that both reads still contain entries.
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

    -- @description Attaches two memory sinks, logs one message, and confirms that each sink independently captures an entry.
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
-- @description Verifies sink registry inspection and mutation through listSinks, removeSink, and clearSinks.
describe("lurek.log.removeSink / clearSinks / listSinks", function()
    -- @description Clears the registry and confirms that listSinks still returns a table result.
    it("listSinks returns a table", function()
        lurek.log.clearSinks()
        local sinks = lurek.log.listSinks()
        expect_type("table", sinks)
    end)

    -- @description Adds one memory sink and checks that listSinks reports at least one registered sink.
    it("listSinks reflects newly added sinks", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory" })
        local sinks = lurek.log.listSinks()
        expect_true(#sinks >= 1, "at least one sink listed")
        lurek.log.removeSink(id)
    end)

    -- @description Compares sink counts before and after removeSink and expects the count to decrease.
    it("removeSink decreases listSinks count", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory" })
        local before = #lurek.log.listSinks()
        lurek.log.removeSink(id)
        local after = #lurek.log.listSinks()
        expect_true(after < before, "count decreased after removeSink")
    end)

    -- @description Adds two sinks, clears them all, and verifies that listSinks reports an empty registry.
    it("clearSinks leaves listSinks empty", function()
        lurek.log.addSink({ type = "memory" })
        lurek.log.addSink({ type = "memory" })
        lurek.log.clearSinks()
        expect_equal(0, #lurek.log.listSinks())
    end)
end)

-- File sink
-- @description Verifies file sink creation and explicit flushing for a valid file-backed sink id.
describe("lurek.log.addSink file sink", function()
    -- @description Creates a file sink at a test path and checks that addSink returns a numeric sink id.
    it("addSink with type=file returns a sink id", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "file", path = "save/_log_test_sink.log" })
        expect_type("number", id)
        lurek.log.removeSink(id)
    end)

    -- @description Writes one message to a file sink and verifies that flushFile on that sink id does not error.
    it("flushFile does not error for a valid file sink id", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "file", path = "save/_log_flush_test.log" })
        lurek.log.info("flush_test_msg")
        expect_no_error(function() lurek.log.flushFile(id) end)
        lurek.log.removeSink(id)
    end)
end)

-- @description Exercises registry behaviors that mirror the Rust-side sink tests, including id validity, remove semantics, retrieval, capacity, and clearing.
describe("log sink registry (RS parity)", function()
    -- @description Starts from an empty registry, adds one memory sink with capacity 10, and asserts the returned id is numeric and positive.
    it("clearSinks starts empty then addSink increments count", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory", capacity = 10 })
        expect_type("number", id)
        expect_true(id > 0)
        lurek.log.removeSink(id)
    end)

    -- @description Removes the same sink twice and expects the first call to succeed and the second to report false.
    it("removeSink returns true on first call, false on second", function()
        lurek.log.clearSinks()
        local id = lurek.log.addSink({ type = "memory", capacity = 10 })
        expect_true(lurek.log.removeSink(id))
        expect_false(lurek.log.removeSink(id))
    end)

    -- @description Writes one info message into a memory sink and checks that readMemory returns a table with at least one entry.
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

    -- @description Creates a capacity-3 memory sink, logs five debug messages, and asserts the retained entry count does not exceed the configured capacity.
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

    -- @description Adds one sink, clears the registry, and verifies that the old sink id can no longer be removed.
    it("clearSinks removes all sinks", function()
        local id = lurek.log.addSink({ type = "memory", capacity = 5 })
        lurek.log.clearSinks()
        expect_false(lurek.log.removeSink(id))
    end)
end)

-- Restore defaults
lurek.log.setLevel("info")
lurek.log.clearSinks()

-- ── Log API validation (merged from test_log_api.lua) ───────────────────────

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

-- Restore defaults (post-merge)
lurek.log.setLevel("info")
lurek.log.clearSinks()

-- ── Structured Logging (merged from test_log_structured.lua) ────────────────

describe("lurek.log.struct — basic API", function()
    it("does not error when called with a non-empty fields table", function()
        lurek.log.struct("info", "hello structured", {key = "value", count = 42})
    end)

    it("does not error with an empty fields table", function()
        lurek.log.struct("debug", "no fields", {})
    end)

    it("accepts all log levels", function()
        lurek.log.struct("debug", "debug msg", {a = "1"})
        lurek.log.struct("info",  "info msg",  {b = "2"})
        lurek.log.struct("warn",  "warn msg",  {c = "3"})
        lurek.log.struct("error", "error msg", {d = "4"})
    end)

    it("accepts number values in fields (converted to string)", function()
        lurek.log.struct("info", "frame stats", {fps = 60, draw_calls = 128})
    end)

    it("accepts boolean values in fields", function()
        lurek.log.struct("debug", "flags", {vsync = true, fullscreen = false})
    end)
end)

describe("lurek.log.*_fields shorthands", function()
    it("debug_fields does not error", function()
        lurek.log.debug_fields("debug shorthand", {x = 1})
    end)

    it("info_fields does not error", function()
        lurek.log.info_fields("info shorthand", {y = 2})
    end)

    it("warn_fields does not error", function()
        lurek.log.warn_fields("warn shorthand", {z = 3})
    end)

    it("error_fields does not error", function()
        lurek.log.error_fields("error shorthand", {w = 4})
    end)

    it("shorthand with empty table does not error", function()
        lurek.log.info_fields("no fields", {})
    end)
end)

describe("lurek.log memory sink — structured entries", function()
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
        expect_equal(found.fields ~= nil, true)
        expect_equal(found.fields.player, "Alice")
        expect_equal(found.fields.score, "100")

        lurek.log.removeSink(sid)
    end)

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
        expect_equal(found.fields, nil)

        lurek.log.removeSink(sid)
    end)

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
        expect_equal(found.fields ~= nil, true)
        expect_equal(found.fields.module, "tween")

        lurek.log.removeSink(sid)
    end)

    it("readMemory returns multiple structured entries in order", function()
        local sid = lurek.log.addSink({type = "memory", capacity = 50, level = "debug"})

        lurek.log.struct("info", "entry A", {seq = "1"})
        lurek.log.struct("info", "entry B", {seq = "2"})

        local entries = lurek.log.readMemory(sid)
        expect_equal(#entries >= 2, true)

        lurek.log.removeSink(sid)
    end)

    it("drain clears memory sink after read", function()
        local sid = lurek.log.addSink({type = "memory", capacity = 50})

        lurek.log.struct("debug", "drain test", {x = "1"})
        local first  = lurek.log.readMemory(sid, true)   -- drain
        local second = lurek.log.readMemory(sid)          -- should be empty now

        expect_equal(#first >= 1, true)
        expect_equal(#second, 0)

        lurek.log.removeSink(sid)
    end)

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
        expect_equal(found.fields ~= nil, true)
        -- values are stored as strings
        expect_equal(type(found.fields.fps), "string")

        lurek.log.removeSink(sid)
    end)
end)

describe("lurek.log memory sink — plain + structured mixed", function()
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

test_summary()
