-- Integration test: library.dialog × lurek.event (runtime name for "lurek.event").
--
-- Scope: Verifies that library.dialog sequencer events ("line", "choice",
-- "finished") can be routed through a `lurek.event.newSignal()` instance
-- so that external observers subscribe to the engine signal layer rather
-- than the library's local handler table. The bridge is a one-line forward
-- (`seq:on(name, function(...) sig:emit(name, ...) end)`) representative
-- of how a game wires dialog into engine-wide event plumbing.
--
-- Fallback: lurek.event is registered as `lurek.event` at runtime
-- (see P1 map). The Signal userdata is the engine's pub/sub primitive;
-- no fallback was needed.
--
-- @covers library.dialog.newSequencer
-- @covers lurek.event.newSignal

local dialog = require("library.dialog")

describe("integration: library.dialog × lurek.event", function()

    local function bridge(seq, sig, events)
        for _, name in ipairs(events) do
            seq:on(name, function(...) sig:emit(name, ...) end)
        end
    end

    -- @description A "line" handler attached via Signal:on receives speaker + text once typing finishes.
    it("line event fires through Signal with payload", function()
        local seq = dialog.newSequencer()
        local sig = lurek.event.newSignal()
        bridge(seq, sig, { "line", "finished" })

        local got_speaker, got_text
        sig:on("line", function(speaker, text)
            got_speaker, got_text = speaker, text
        end)

        seq:setSpeed(100)
        seq:load({ { type = "say", speaker = "Alice", text = "Hi!" } })
        seq:start()
        seq:update(0.5)

        expect_equal("Alice", got_speaker)
        expect_equal("Hi!", got_text)
    end)

    -- @description Multiple Signal subscribers all receive the same dialog "line" event.
    it("multiple Signal subscribers each receive the event", function()
        local seq = dialog.newSequencer()
        local sig = lurek.event.newSignal()
        bridge(seq, sig, { "line" })

        local count_a, count_b = 0, 0
        sig:on("line", function() count_a = count_a + 1 end)
        sig:on("line", function() count_b = count_b + 1 end)

        seq:setSpeed(100)
        seq:load({ { type = "say", speaker = "N", text = "X" } })
        seq:start()
        seq:update(0.5)

        expect_equal(1, count_a)
        expect_equal(1, count_b)
    end)

    -- @description "finished" event fires through Signal when the script completes.
    it("finished event fires through Signal at end of script", function()
        local seq = dialog.newSequencer()
        local sig = lurek.event.newSignal()
        bridge(seq, sig, { "line", "finished" })

        local finished = false
        sig:on("finished", function() finished = true end)

        seq:setSpeed(1000)
        seq:load({ { type = "say", speaker = "N", text = "End." } })
        seq:start()
        seq:update(0.1)
        seq:advance() -- waiting -> next -> done -> finished
        expect_true(finished)
    end)

    -- @description Choice event delivered through Signal carries the dialog into the "choice" state.
    it("choice event fires through Signal when reaching a choice node", function()
        local seq = dialog.newSequencer()
        local sig = lurek.event.newSignal()
        bridge(seq, sig, { "choice" })

        local choice_fired = false
        sig:on("choice", function() choice_fired = true end)

        seq:load({
            { type = "choice", text = "Pick:", options = {
                { label = "A", branch = {} },
                { label = "B", branch = {} },
            } },
        })
        seq:start()
        expect_true(choice_fired)
        expect_equal("choice", seq:getState())
    end)

    -- @description seq:off removes the dialog-side bridge handlers, so further dialog events
    -- no longer reach the Signal subscribers.
    it("seq:off stops further events from reaching Signal subscribers", function()
        local seq = dialog.newSequencer()
        local sig = lurek.event.newSignal()
        bridge(seq, sig, { "line" })

        local count = 0
        sig:on("line", function() count = count + 1 end)

        seq:setSpeed(1000)
        seq:load({
            { type = "say", speaker = "N", text = "1" },
            { type = "say", speaker = "N", text = "2" },
        })
        seq:start()
        seq:update(0.1)
        expect_equal(1, count)

        seq:off("line")
        seq:advance() -- moves to second "say" node, would normally fire "line"
        seq:update(0.1)
        expect_equal(1, count)
    end)

    -- @description Failure path: registering a non-string event name on the dialog raises a clear error.
    it("seq:on rejects non-string event names with a clear error", function()
        local seq = dialog.newSequencer()
        local err = expect_error(function()
            seq:on(123, function() end)
        end)
        expect_contains(tostring(err), "string event name")
    end)

end)

test_summary()
