-- tests/lua/unit/test_library_dialog.lua
-- BDD tests for library/dialog/init.lua (pure-Lua dialog sequencer).

local dialog = require("library.dialog")

describe("library.dialog", function()

    describe("newSequencer", function()
        it("creates a sequencer in idle state", function()
            local seq = dialog.newSequencer()
            expect_equal(seq:getState(), "idle")
            expect_equal(seq:isActive(), false)
        end)
    end)

    describe("say node", function()
        it("transitions idle -> typing on start", function()
            local seq = dialog.newSequencer()
            seq:load({
                { type = "say", speaker = "NPC", text = "Hello" },
            })
            seq:start()
            expect_equal(seq:getState(), "typing")
            expect_equal(seq:currentSpeaker(), "NPC")
        end)

        it("reveals text over time", function()
            local seq = dialog.newSequencer()
            seq:setSpeed(100) -- 100 cps → 1 char per 0.01s
            seq:load({
                { type = "say", speaker = "NPC", text = "Hello" },
            })
            seq:start()
            -- At start, 0 chars revealed
            expect_equal(seq:revealedText(), "")
            -- After enough time, all 5 chars appear
            seq:update(0.1) -- 100 cps * 0.1s = 10 chars → whole word
            expect_equal(seq:revealedText(), "Hello")
            expect_equal(seq:getState(), "waiting")
        end)

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

    describe("choice node", function()
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

    describe("wait node", function()
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

    describe("call node", function()
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

    describe("events", function()
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
    end)

    describe("full sequence", function()
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

test_summary()
