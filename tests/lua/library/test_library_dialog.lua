-- tests/lua/unit/test_library_dialog.lua
-- BDD tests for library/dialog/init.lua (pure-Lua dialog sequencer).

local dialog = require("library.dialog")

-- @description Exercises the dialog sequencer core state machine across say, choice, wait, call, event, jump, and completion flows.
describe("library.dialog", function()

    -- @description Verifies a new sequencer starts idle, inactive, and configured with the documented default typewriter speed.
    describe("newSequencer", function()
        -- @covers library.dialog.newSequencer
        -- @covers library.dialog
        -- @description Confirms a freshly created sequencer starts in the idle state and reports itself as inactive.
        it("creates a sequencer in idle state", function()
            local seq = dialog.newSequencer()
            expect_equal(seq:getState(), "idle")
            expect_equal(seq:isActive(), false)
        end)

        -- @covers library.dialog.newSequencer
        -- @description Checks the default typewriter speed used by new sequencers before any overrides are applied.
        it("default speed is 20", function()
            local seq = dialog.newSequencer()
            expect_equal(20, seq:getSpeed())
        end)
    end)

    -- @description Covers say-node behavior including entering typing state, revealing text over time, advancing to later nodes, and skipping to full text.
    describe("say node", function()
        -- @covers library.dialog.newSequencer
        -- @description Verifies starting a script with a say node enters typing state and exposes the active speaker.
        it("transitions idle -> typing on start", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "say", speaker = "NPC", text = "Hello" },
            })
            seq:start()
            expect_equal(seq:getState(), "typing")
            expect_equal(seq:currentSpeaker(), "NPC")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Checks that update reveals say-node text over time and transitions to waiting once the full line is visible.
        it("reveals text over time", function()
            local seq = dialog.newSequencer()
            seq:setSpeed(100) -- 100 cps â†’ 1 char per 0.01s
            seq:load({
                { type = "say", speaker = "NPC", text = "Hello" },
            })
            seq:start()
            -- At start, 0 chars revealed
            expect_equal(seq:revealedText(), "")
            -- After enough time, all 5 chars appear
            seq:update(0.1) -- 100 cps * 0.1s = 10 chars â†’ whole word
            expect_equal(seq:revealedText(), "Hello")
            expect_equal(seq:getState(), "waiting")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Confirms advancing after a completed say node moves the sequencer to the next dialogue line.
        it("advance moves to next node", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "say", speaker = "A", text = "First" },
                { type = "say", speaker = "B", text = "Second" },
            })
            seq:start()
            seq:update(10) -- finish typing
            expect_equal(seq:getState(), "waiting")
            seq:advance()
            expect_equal(seq:getState(), "typing")
            expect_equal(seq:currentSpeaker(), "B")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Verifies skipping a say node immediately reveals its full text and enters the waiting state.
        it("skip instantly reveals text", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "say", speaker = "A", text = "Long text here" },
            })
            seq:start()
            seq:skip()
            expect_equal(seq:revealedText(), "Long text here")
            expect_equal(seq:getState(), "waiting")
        end)
    end)

    -- @description Tests choice-node entry, label enumeration, waiting-for-choice state, and branch execution after a selection.
    describe("choice node", function()
        -- @covers library.dialog.newSequencer
        -- @description Checks that choice nodes enter choice state and expose the option labels in order.
        it("enters choice state with labels", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "choice", text = "Pick one", options = {
                    { label = "Yes", branch = {} },
                    { label = "No",  branch = {} },
                }},
            })
            seq:start()
            expect_equal(seq:getState(), "choice")
            expect_equal(seq:isWaitingForChoice(), true)
            local labels = seq:getChoiceLabels()
            expect_equal(#labels, 2)
            expect_equal(labels[1], "Yes")
            expect_equal(labels[2], "No")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Verifies selecting a choice branch loads and executes the branch nodes as the next sequence.
        it("choosing a branch executes its nodes", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "choice", text = "Pick", options = {
                    { label = "A", branch = {
                        { type = "say", speaker = "X", text = "Branch A" },
                    }},
                    { label = "B", branch = {} },
                }},
            })
            seq:start()
            seq:choose(1) -- pick option A
            expect_equal(seq:getState(), "typing")
            expect_equal(seq:currentSpeaker(), "X")
        end)
    end)

    -- @description Verifies wait nodes hold the sequencer in a paused state until the configured duration expires, then continue into the next node.
    describe("wait node", function()
        -- @covers library.dialog.newSequencer
        -- @description Confirms wait nodes keep the sequencer paused until enough time has elapsed, then resume the next node.
        it("pauses for the specified duration", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "wait", time = 0.5 },
                { type = "say", speaker = "A", text = "After wait" },
            })
            seq:start()
            expect_equal(seq:getState(), "paused")
            seq:update(0.3)
            expect_equal(seq:getState(), "paused")
            seq:update(0.3) -- total 0.6 > 0.5
            expect_equal(seq:getState(), "typing")
            expect_equal(seq:currentSpeaker(), "A")
        end)
    end)

    -- @description Confirms call nodes execute embedded Lua callbacks immediately and then continue sequencing without blocking.
    describe("call node", function()
        -- @covers library.dialog.newSequencer
        -- @description Verifies call nodes invoke their callback and continue directly into the following dialogue node.
        it("executes the function and continues", function()
            local called = false
            local seq = dialog.newSequencer()
            seq:load({
                { type = "call", fn = function() called = true end },
                { type = "say", speaker = "A", text = "After call" },
            })
            seq:start()
            -- call node executes and immediately moves to next
            expect_equal(called, true)
            expect_equal(seq:getState(), "typing")
        end)
    end)

    -- @description Validates emitted line, finished, choice, and handler-removal events so the sequencer notifies listeners at the correct transitions.
    describe("events", function()
        -- @covers library.dialog.newSequencer
        -- @description Checks line events fire with the active speaker and full text when a say node begins.
        it("fires line event on say node", function()
            local fired_speaker, fired_text
            local seq = dialog.newSequencer()
            seq:on("line", function(speaker, text)
                fired_speaker = speaker
                fired_text = text
            end)
            seq:load({
                { type = "say", speaker = "NPC", text = "Hello" },
            })
            seq:start()
            expect_equal(fired_speaker, "NPC")
            expect_equal(fired_text, "Hello")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Verifies the finished event fires after the final node is advanced past and the sequencer becomes done.
        it("fires finished event when done", function()
            local finished = false
            local seq = dialog.newSequencer()
            seq:on("finished", function() finished = true end)
            seq:load({
                { type = "say", speaker = "A", text = "Hi" },
            })
            seq:start()
            seq:update(10)  -- finish typing
            seq:advance()   -- advance past last node -> done
            expect_equal(finished, true)
            expect_equal(seq:getState(), "done")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Confirms entering a choice node emits the choice event immediately.
        it("fires choice event", function()
            local fired = false
            local seq = dialog.newSequencer()
            seq:on("choice", function() fired = true end)
            seq:load({
                { type = "choice", text = "Pick", options = {
                    { label = "A", branch = {} },
                }},
            })
            seq:start()
            expect_equal(true, fired)
        end)

        -- @covers library.dialog.newSequencer
        -- @description Checks removing an event handler prevents subsequent matching events from invoking the old callback.
        it("off removes event handler", function()
            local count = 0
            local seq = dialog.newSequencer()
            seq:on("line", function() count = count + 1 end)
            seq:load({
                { type = "say", speaker = "A", text = "First" },
                { type = "say", speaker = "B", text = "Second" },
            })
            seq:start()              -- fires "line" -> count = 1
            expect_equal(1, count)
            seq:off("line")          -- remove handler
            seq:skip()               -- typing -> waiting
            seq:advance()            -- moves to next node, fires "line" (no-op)
            expect_equal(1, count)   -- count unchanged
        end)
    end)

    -- @description Exercises empty-script completion and partial text reveal edge cases at nonzero and low update intervals.
    describe("edge cases", function()
        -- @covers library.dialog.newSequencer
        -- @description Verifies starting an empty script completes immediately and deactivates the sequencer.
        it("empty script immediately finishes", function()
            local seq = dialog.newSequencer()
            seq:load({})
            seq:start()
            expect_equal("done", seq:getState())
            expect_equal(false, seq:isActive())
        end)

        -- @covers library.dialog.newSequencer
        -- @description Checks partial updates reveal only part of a line when insufficient time has passed to finish typing.
        it("partial text reveal via update", function()
            local seq = dialog.newSequencer()
            seq:setSpeed(10)  -- 10 cps
            seq:load({
                { type = "say", speaker = "A", text = "Hello" },
            })
            seq:start()
            seq:update(0.3)  -- 10 * 0.3 = 3 chars of 5
            local revealed = seq:revealedText()
            expect_equal(true, #revealed > 0)
            expect_equal(true, #revealed < 5)
            expect_equal("typing", seq:getState())
        end)
    end)

    -- @description Runs a small multi-line sequence end to end to verify the sequencer reaches the done state after successive advances.
    describe("full sequence", function()
        -- @covers library.dialog.newSequencer
        -- @description Verifies a multi-line script can be advanced through completely until the sequencer reaches done.
        it("plays through multiple nodes to done", function()
            local seq = dialog.newSequencer()
            seq:setSpeed(1000)
            seq:load({
                { type = "say", speaker = "A", text = "One" },
                { type = "say", speaker = "B", text = "Two" },
            })
            seq:start()
            seq:update(1)    -- finish first
            seq:advance()    -- move to second
            seq:update(1)    -- finish second
            seq:advance()    -- done
            expect_equal(seq:getState(), "done")
            expect_equal(seq:isActive(), false)
        end)
    end)
end)

-- â”€â”€â”€ Node constructor helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies the dialog helper constructors and exported node or state enums build the expected node tables and constant values.
describe("node constructors", function()
    -- @covers library.dialog.say
    -- @covers library.dialog.choice
    -- @covers library.dialog.wait
    -- @covers library.dialog.event
    -- @covers library.dialog.call
    -- @covers library.dialog.jump
    -- @description Confirms the say constructor builds a say-node table with the supplied speaker and text.
    it("M.say creates a say node", function()
        local node = dialog.say("Alice", "Hello")
        expect_equal(node.type,    "say")
        expect_equal(node.speaker, "Alice")
        expect_equal(node.text,    "Hello")
    end)

    -- @covers library.dialog.say
    -- @description Verifies the say constructor forwards optional metadata from the provided options table.
    it("M.say accepts opts table", function()
        local node = dialog.say("Bob", "Hi", { label = "start" })
        expect_equal(node.label, "start")
        expect_equal(node.speaker, "Bob")
    end)

    -- @covers library.dialog.choice
    -- @description Checks the choice constructor builds a choice node with the supplied prompt and option list.
    it("M.choice creates a choice node", function()
        local opts = { { label = "Yes", branch = {} }, { label = "No", branch = {} } }
        local node = dialog.choice("Pick one", opts)
        expect_equal(node.type,    "choice")
        expect_equal(node.text,    "Pick one")
        expect_equal(#node.options, 2)
        expect_equal(node.options[1].label, "Yes")
    end)

    -- @covers library.dialog.wait
    -- @description Confirms the wait constructor records an explicit delay duration on the returned wait node.
    it("M.wait creates a wait node", function()
        local node = dialog.wait(1.5)
        expect_equal(node.type, "wait")
        expect_equal(node.time, 1.5)
    end)

    -- @covers library.dialog.wait
    -- @description Verifies the wait constructor falls back to the documented one-second default when omitted.
    it("M.wait defaults time to 1.0", function()
        local node = dialog.wait()
        expect_equal(node.time, 1.0)
    end)

    -- @covers library.dialog.event
    -- @description Checks the event constructor stores both the event name and attached payload table.
    it("M.event creates an event node", function()
        local node = dialog.event("unlock", { key = "door" })
        expect_equal(node.type,     "event")
        expect_equal(node.name,     "unlock")
        expect_equal(node.data.key, "door")
    end)

    -- @covers library.dialog.call
    -- @description Verifies the call constructor wraps the supplied callback in a call-node table.
    it("M.call creates a call node", function()
        local fn = function() end
        local node = dialog.call(fn)
        expect_equal(node.type, "call")
        expect_equal(node.fn,   fn)
    end)

    -- @covers library.dialog.jump
    -- @description Confirms the jump constructor records the label target to jump to.
    it("M.jump creates a jump node", function()
        local node = dialog.jump("end_label")
        expect_equal(node.type,   "jump")
        expect_equal(node.target, "end_label")
    end)

    -- @covers library.dialog.NodeType
    -- @description Checks the exported node-type enum strings match the constructor node types.
    it("M.NodeType constants have correct values", function()
        expect_equal(dialog.NodeType.SAY,    "say")
        expect_equal(dialog.NodeType.CHOICE, "choice")
        expect_equal(dialog.NodeType.WAIT,   "wait")
        expect_equal(dialog.NodeType.EVENT,  "event")
        expect_equal(dialog.NodeType.CALL,   "call")
        expect_equal(dialog.NodeType.JUMP,   "jump")
    end)

    -- @covers library.dialog.SequencerState
    -- @description Verifies the sequencer-state enum exports the canonical runtime state strings.
    it("M.SequencerState constants match sequencer states", function()
        expect_equal(dialog.SequencerState.IDLE,    "idle")
        expect_equal(dialog.SequencerState.TYPING,  "typing")
        expect_equal(dialog.SequencerState.WAITING, "waiting")
        expect_equal(dialog.SequencerState.CHOICE,  "choice")
        expect_equal(dialog.SequencerState.PAUSED,  "paused")
        expect_equal(dialog.SequencerState.DONE,    "done")
    end)

    -- @covers library.dialog.SequencerState
    -- @description Confirms the legacy sequencer-state aliases still point at the expected canonical states.
    it("M.SequencerState legacy aliases are present", function()
        expect_equal(dialog.SequencerState.RUNNING,        "typing")
        expect_equal(dialog.SequencerState.WAITING_CHOICE, "choice")
    end)
end)

-- â”€â”€â”€ event node â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests event nodes and constructor-built event nodes to ensure event callbacks receive name and payload before sequencing continues.
describe("event node", function()
    -- @covers library.dialog.newSequencer
    -- @covers library.dialog.event
    -- @description Verifies raw event nodes emit the event callback with name and payload before sequencing into the next node.
    it("fires the event callback with name and data then continues", function()
        local fired_name, fired_data
        local seq = dialog.newSequencer()
        seq:on("event", function(name, data)
            fired_name = name
            fired_data = data
        end)
        seq:load({
            { type = "event", name = "unlock", data = { key = "door" } },
            { type = "say",   speaker = "A", text = "After event" },
        })
        seq:start()
        expect_equal(fired_name,    "unlock")
        expect_equal(fired_data.key, "door")
        expect_equal(seq:getState(), "typing")
        expect_equal(seq:currentSpeaker(), "A")
    end)

    -- @covers library.dialog.newSequencer
    -- @covers library.dialog.event
    -- @description Confirms constructor-built event nodes trigger the event callback and finish a one-node script.
    it("M.event node fires correctly through constructor", function()
        local fired = false
        local seq = dialog.newSequencer()
        seq:on("event", function() fired = true end)
        seq:load({ dialog.event("test") })
        seq:start()
        expect_equal(fired, true)
        expect_equal(seq:getState(), "done")
    end)
end)

-- â”€â”€â”€ jump node â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises jump nodes for successful label targeting, constructor parity, and unknown-label fallthrough behavior.
describe("jump node", function()
    -- @covers library.dialog.newSequencer
    -- @covers library.dialog.jump
    -- @description Checks jump nodes skip intermediate nodes and land on the matching labeled node.
    it("jumps to the labeled node, skipping intermediate nodes", function()
        local seq = dialog.newSequencer()
        seq:load({
            { type = "jump",  target  = "end" },
            { type = "say",   speaker = "A", text = "skipped" },
            { type = "say",   speaker = "B", text = "reached", label = "end" },
        })
        seq:start()
        expect_equal(seq:currentSpeaker(), "B")
        expect_equal(seq:currentText(),    "reached")
    end)

    -- @covers library.dialog.newSequencer
    -- @covers library.dialog.jump
    -- @description Verifies jump nodes created through the constructor behave the same as inline jump tables.
    it("M.jump constructor produces correct node", function()
        local seq = dialog.newSequencer()
        seq:load({
            dialog.jump("target"),
            dialog.say("A", "skipped"),
            { type = "say", speaker = "B", text = "ok", label = "target" },
        })
        seq:start()
        expect_equal(seq:currentSpeaker(), "B")
    end)

    -- @covers library.dialog.newSequencer
    -- @covers library.dialog.jump
    -- @description Confirms unknown jump labels fall through without crashing and leave the sequencer in an active or completed state.
    it("jump to unknown label advances normally", function()
        local seq = dialog.newSequencer()
        seq:load({
            { type = "jump", target = "nowhere" },
            { type = "say", speaker = "A", text = "fallthrough" },
        })
        seq:start()
        -- unknown target: step() is called, resumes from wherever _pc was
        -- (may be typing or done depending on linear scan result)
        expect_equal(seq:isActive() or seq:getState() == "done", true)
    end)
end)

-- â”€â”€â”€ cond predicate â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies conditional predicates can skip one or multiple nodes while still allowing true predicates to keep nodes active.
describe("cond predicate", function()
    -- @covers library.dialog.newSequencer
    -- @description Verifies nodes with a false condition predicate are skipped in favor of the next eligible node.
    it("skips a node when cond returns false", function()
        local seq = dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "skipped",
              cond = function() return false end },
            { type = "say", speaker = "B", text = "shown" },
        })
        seq:start()
        expect_equal(seq:currentSpeaker(), "B")
        expect_equal(seq:currentText(),    "shown")
    end)

    -- @covers library.dialog.newSequencer
    -- @description Confirms nodes remain active when their condition predicate returns true.
    it("does not skip a node when cond returns true", function()
        local seq = dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "shown",
              cond = function() return true end },
        })
        seq:start()
        expect_equal(seq:currentSpeaker(), "A")
    end)

    -- @covers library.dialog.newSequencer
    -- @description Checks consecutive false condition predicates can skip multiple nodes before a valid node is shown.
    it("skips multiple consecutive nodes with false cond", function()
        local seq = dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "X", text = "skip1",
              cond = function() return false end },
            { type = "say", speaker = "Y", text = "skip2",
              cond = function() return false end },
            { type = "say", speaker = "Z", text = "final" },
        })
        seq:start()
        expect_equal(seq:currentSpeaker(), "Z")
    end)
end)

-- â”€â”€â”€ typewrite per-char event â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers per-character typewrite events during reveal and confirms no typewrite events fire when speed is zero.
describe("typewrite event", function()
    -- @covers library.dialog.newSequencer
    -- @description Verifies the typewrite event fires once for each newly revealed character during text progression.
    it("fires once per newly revealed character", function()
        local chars = {}
        local seq = dialog.newSequencer()
        seq:on("typewrite", function(ch, full)
            table.insert(chars, ch)
        end)
        seq:setSpeed(1000)  -- 1000 cps
        seq:load({ { type = "say", speaker = "A", text = "ABC" } })
        seq:start()
        expect_equal(#chars, 0)   -- no chars revealed yet
        seq:update(0.003)         -- 1000 * 0.003 = 3.0 chars => 3 fired
        expect_equal(#chars, 3)
        expect_equal(chars[1], "A")
        expect_equal(chars[2], "B")
        expect_equal(chars[3], "C")
        expect_equal(seq:getState(), "waiting")
    end)

    -- @covers library.dialog.newSequencer
    -- @description Confirms a zero typing speed prevents reveal progress and therefore suppresses typewrite events.
    it("does not fire typewrite when speed=0 (text never advances)", function()
        local chars = {}
        local seq = dialog.newSequencer()
        seq:on("typewrite", function(ch) table.insert(chars, ch) end)
        seq:setSpeed(0)
        seq:load({ { type = "say", speaker = "A", text = "Hi" } })
        seq:start()
        seq:update(0.016)  -- cps=0 means _revealed stays at 0.0
        expect_equal(seq:getState(), "typing")   -- still typing (no advancement)
        expect_equal(#chars, 0)                  -- no chars fired
    end)
end)

-- â”€â”€â”€ done event alias â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates the done alias event both for normal sequence completion and for empty scripts that finish immediately on start.
describe("done event", function()
    -- @covers library.dialog.newSequencer
    -- @description Checks the done alias and finished event both fire when a non-empty sequence reaches completion.
    it("fires done alongside finished when sequence ends", function()
        local done_fired     = false
        local finished_fired = false
        local seq = dialog.newSequencer()
        seq:on("done",     function() done_fired     = true end)
        seq:on("finished", function() finished_fired = true end)
        seq:load({ { type = "say", speaker = "A", text = "Hi" } })
        seq:start()
        seq:update(10)
        seq:advance()  -- advance past last node -> done
        expect_equal(done_fired,     true)
        expect_equal(finished_fired, true)
    end)

    -- @covers library.dialog.newSequencer
    -- @description Verifies empty scripts emit the done event immediately when started.
    it("done fires when empty script starts", function()
        local fired = false
        local seq = dialog.newSequencer()
        seq:on("done", function() fired = true end)
        seq:load({})
        seq:start()
        expect_equal(fired, true)
    end)
end)

-- ——— bug fixes ————————————————————————————————————————————————————————————

describe("bug fixes", function()

    describe("jump loop detection", function()
        -- @covers library.dialog.newSequencer
        -- @description A direct self-referencing jump label should hit the loop guard and force done.
        it("direct self-jump loop forces done", function()
            local seq = dialog.newSequencer()
            local done_fired = false
            seq:on("done", function() done_fired = true end)
            seq:load({
                { type = "jump", target = "loop", label = "loop" },
            })
            seq:start()
            expect_equal(seq:getState(), "done")
            expect_equal(done_fired, true)
        end)

        -- @covers library.dialog.newSequencer
        -- @description An A->B->A mutual jump cycle should be caught by the 100-jump guard.
        it("stops infinite A->B->A loop and forces done", function()
            local seq = dialog.newSequencer()
            local done_fired = false
            seq:on("done", function() done_fired = true end)
            seq:load({
                { type = "say", speaker = "X", text = "start", label = "A" },
                { type = "jump", target = "B" },
                { type = "say", speaker = "Y", text = "mid", label = "B" },
                { type = "jump", target = "A" },
            })
            seq:start()
            -- First say node executes normally
            expect_equal(seq:getState(), "typing")
            -- Advance through the loop until guard kicks in
            local safety = 0
            while seq:isActive() and safety < 300 do
                if seq:getState() == "typing" then
                    seq:update(10)
                end
                if seq:getState() == "waiting" then
                    seq:advance()
                end
                safety = safety + 1
            end
            expect_equal(seq:getState(), "done")
            expect_equal(done_fired, true)
        end)
    end)

    describe("choice index validation", function()
        -- @covers library.dialog.newSequencer
        -- @description Non-number choice index should raise an error.
        it("errors on non-number index", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "choice", text = "Pick", options = {
                    { label = "A", branch = {} },
                }},
            })
            seq:start()
            expect_equal(seq:getState(), "choice")
            expect_error(function() seq:choose("bad") end)
        end)

        -- @covers library.dialog.newSequencer
        -- @description Index 0 is below the valid 1-based range and should error.
        it("errors on index below 1", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "choice", text = "Pick", options = {
                    { label = "A", branch = {} },
                }},
            })
            seq:start()
            expect_error(function() seq:choose(0) end)
        end)

        -- @covers library.dialog.newSequencer
        -- @description Index above the option count should error.
        it("errors on index above option count", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "choice", text = "Pick", options = {
                    { label = "A", branch = {} },
                    { label = "B", branch = {} },
                }},
            })
            seq:start()
            expect_error(function() seq:choose(3) end)
        end)

        -- @covers library.dialog.newSequencer
        -- @description choose() outside choice state should be silently ignored.
        it("ignores choose when not in choice state", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "say", speaker = "A", text = "Hello" },
            })
            seq:start()
            seq:choose(1)
            expect_equal(seq:getState(), "typing")
        end)
    end)

    describe("dt validation", function()
        -- @covers library.dialog.newSequencer
        -- @description Negative dt should not advance text reveal.
        it("clamps negative dt to no-op", function()
            local seq = dialog.newSequencer()
            seq:setSpeed(100)
            seq:load({
                { type = "say", speaker = "A", text = "Hello" },
            })
            seq:start()
            seq:update(-1.0)
            expect_equal(seq:revealedText(), "")
            expect_equal(seq:getState(), "typing")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Zero dt should not advance text reveal.
        it("clamps zero dt to no-op", function()
            local seq = dialog.newSequencer()
            seq:setSpeed(100)
            seq:load({
                { type = "say", speaker = "A", text = "Hello" },
            })
            seq:start()
            seq:update(0)
            expect_equal(seq:revealedText(), "")
            expect_equal(seq:getState(), "typing")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Non-number dt should raise an error.
        it("errors on non-number dt", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "say", speaker = "A", text = "Hello" },
            })
            seq:start()
            expect_error(function() seq:update("bad") end)
            expect_error(function() seq:update(nil) end)
        end)
    end)

    describe("load validation", function()
        -- @covers library.dialog.newSequencer
        -- @description nil argument to load should be treated as empty script.
        it("treats nil as empty script", function()
            local seq = dialog.newSequencer()
            seq:load(nil)
            seq:start()
            expect_equal(seq:getState(), "done")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Non-table argument to load should raise an error.
        it("errors on non-table argument", function()
            local seq = dialog.newSequencer()
            expect_error(function() seq:load("bad") end)
            expect_error(function() seq:load(42) end)
        end)
    end)

    describe("cond error recovery", function()
        -- @covers library.dialog.newSequencer
        -- @description A cond() that throws should be caught by pcall and the node skipped.
        it("skips node when cond() throws an error", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "say", speaker = "A", text = "skipped",
                  cond = function() error("boom") end },
                { type = "say", speaker = "B", text = "shown" },
            })
            seq:start()
            expect_equal(seq:currentSpeaker(), "B")
            expect_equal(seq:currentText(), "shown")
        end)

        -- @covers library.dialog.newSequencer
        -- @description Multiple consecutive cond() errors should all be caught and skipped.
        it("skips multiple nodes with throwing cond()", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "say", speaker = "A", text = "s1",
                  cond = function() error("err1") end },
                { type = "say", speaker = "B", text = "s2",
                  cond = function() error("err2") end },
                { type = "say", speaker = "C", text = "final" },
            })
            seq:start()
            expect_equal(seq:currentSpeaker(), "C")
        end)
    end)
end)

test_summary()
