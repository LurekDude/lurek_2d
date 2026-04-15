-- tests/lua/unit/test_log_structured.lua
-- BDD tests for lurek.log structured logging (struct, *_fields, readMemory.fields).
-- No GPU, audio, or window APIs used.

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
