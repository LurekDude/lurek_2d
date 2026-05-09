-- Integration: library.dialog sequencer events bridged to lurek.event signals.
--
-- Verifies that dialog events ("line", "choice", "finished") can be forwarded
-- through lurek.event.newSignal() so external observers receive them via the
-- engine-level pub/sub primitive.

local dialog = require("library.dialog")

describe("integration: library.dialog + lurek.event", function()

    local function bridge(seq, sig, events)
        for _, name in ipairs(events) do
            seq:on(name, function(...) sig:emit(name, ...) end)
        end
    end

    -- @integration LSignal:connect
    -- @integration LSignal:emit
    -- @integration lurek.event.newSignal
    it("dialog events are forwarded through engine signal", function()
        local seq = dialog.newSequencer()
        local sig = lurek.event.newSignal()

        local lines = {}
        sig:connect("line", function(speaker, text)
            lines[#lines + 1] = { speaker = speaker, text = text }
        end)

        local finished = false
        sig:connect("finished", function() finished = true end)

        bridge(seq, sig, { "line", "finished" })

        seq:load({ { type = "say", speaker = "Guard", text = "Halt!" } })
        seq:start()
            seq:advance()  -- skip reveal -> "waiting"
            seq:advance()  -- step() -> no more nodes -> fire "finished"

        expect_equal(1, #lines, "one line event received via signal")
        expect_equal("Guard", lines[1].speaker, "correct speaker forwarded")
        expect_equal("Halt!", lines[1].text, "correct text forwarded")
        expect_true(finished, "finished event forwarded after single-say sequence")
    end)

    -- @integration LSignal:connect
    -- @integration LSignal:emit
    -- @integration lurek.event.newSignal
    it("multiple bridge events forwarded independently", function()
        local seq = dialog.newSequencer()
        local sig = lurek.event.newSignal()

        local line_count = 0
        local done_count = 0
        sig:connect("line", function() line_count = line_count + 1 end)
        sig:connect("finished", function() done_count = done_count + 1 end)

        bridge(seq, sig, { "line", "finished" })

        seq:load({
            { type = "say", speaker = "A", text = "One" },
            { type = "say", speaker = "B", text = "Two" },
        })
        seq:start()
        seq:advance()
        seq:advance()
        seq:advance()
        seq:advance()

        expect_true(line_count >= 2, "at least two line events forwarded")
        expect_equal(1, done_count, "exactly one finished event forwarded")
    end)

end)
test_summary()
