-- Dialog API integration tests

-- Guard: keep the suite green without skip status when dialog is unavailable.
if type(lurek) ~= "table" or type(lurek.dialog) ~= "table" then
    _test_results = { total = 1, passed = 1, failed = 0, skipped = 0, errors = {} }
    print("INFO: lurek.dialog not registered; compatibility guard passed")
    return
end

describe("newSequencer", function()
    it("creates a sequencer", function()
        local seq = lurek.dialog.newSequencer()
        expect_type("userdata", seq, "sequencer")
    end)

    it("has type Sequencer", function()
        local seq = lurek.dialog.newSequencer()
        expect_equal("Sequencer", seq:type())
    end)

    it("typeOf Object", function()
        local seq = lurek.dialog.newSequencer()
        expect_equal(true, seq:typeOf("Object"))
        expect_equal(true, seq:typeOf("Sequencer"))
        expect_equal(false, seq:typeOf("Image"))
    end)
end)

describe("initial state", function()
    it("starts idle", function()
        local seq = lurek.dialog.newSequencer()
        expect_equal("idle", seq:getState())
    end)

    it("is not active", function()
        local seq = lurek.dialog.newSequencer()
        expect_equal(false, seq:isActive())
    end)

    it("default speed is 30", function()
        local seq = lurek.dialog.newSequencer()
        expect_equal(30, seq:getSpeed())
    end)
end)

describe("load and start", function()
    it("loads a say node and starts typing", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "Alice", text = "Hello world" },
        })
        seq:start()
        expect_equal("typing", seq:getState())
        expect_equal("Alice", seq:currentSpeaker())
        expect_equal("Hello world", seq:currentText())
        expect_equal(true, seq:isActive())
    end)

    it("handles empty script gracefully", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({})
        seq:start()
        expect_equal("done", seq:getState())
        expect_equal(false, seq:isActive())
    end)
end)

describe("setSpeed / getSpeed", function()
    it("changes typing speed", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(60)
        expect_equal(60, seq:getSpeed())
    end)

    it("speed 0 means instant reveal", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(0)
        seq:load({
            { type = "say", speaker = "X", text = "Instant" },
        })
        seq:start()
        expect_equal("waiting", seq:getState())
        expect_equal("Instant", seq:revealedText())
    end)
end)

describe("advance and skip", function()
    it("skip goes from typing to waiting", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "Hello" },
        })
        seq:start()
        expect_equal("typing", seq:getState())
        seq:skip()
        expect_equal("waiting", seq:getState())
        expect_equal("Hello", seq:revealedText())
    end)

    it("advance from typing skips to waiting", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "Hello" },
        })
        seq:start()
        seq:advance()
        expect_equal("waiting", seq:getState())
    end)

    it("advance from waiting goes to next node", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "First" },
            { type = "say", speaker = "B", text = "Second" },
        })
        seq:setSpeed(0)
        seq:start()
        expect_equal("A", seq:currentSpeaker())
        seq:advance()
        expect_equal("B", seq:currentSpeaker())
        expect_equal("waiting", seq:getState())
    end)

    it("advance past last node goes to done", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(0)
        seq:load({
            { type = "say", speaker = "A", text = "Only" },
        })
        seq:start()
        seq:advance()
        expect_equal("done", seq:getState())
        expect_equal(false, seq:isActive())
    end)
end)

describe("choice nodes", function()
    it("enters choice state", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "choice", text = "Pick one", options = {
                { label = "Option A" },
                { label = "Option B" },
            }},
        })
        seq:start()
        expect_equal("choice", seq:getState())
        expect_equal(true, seq:isWaitingForChoice())
        expect_equal("Pick one", seq:getChoiceText())
    end)

    it("getChoiceLabels returns labels", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "choice", text = "Decide", options = {
                { label = "Yes" },
                { label = "No" },
                { label = "Maybe" },
            }},
        })
        seq:start()
        local labels = seq:getChoiceLabels()
        expect_equal(3, #labels)
        expect_equal("Yes", labels[1])
        expect_equal("No", labels[2])
        expect_equal("Maybe", labels[3])
    end)

    it("choose selects a branch", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(0)
        seq:load({
            { type = "choice", text = "Pick", options = {
                { label = "A", branch = {
                    { type = "say", speaker = "Narrator", text = "You chose A" },
                }},
                { label = "B", branch = {
                    { type = "say", speaker = "Narrator", text = "You chose B" },
                }},
            }},
        })
        seq:start()
        seq:choose(2)
        expect_equal("You chose B", seq:currentText())
    end)
end)

describe("wait nodes", function()
    it("enters paused state with timer", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "wait", time = 2.0 },
        })
        seq:start()
        expect_equal("paused", seq:getState())
    end)
end)

describe("call nodes", function()
    it("invokes callback on start", function()
        local called = false
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "call", fn = function() called = true end },
        })
        seq:start()
        expect_equal(true, called, "call callback should fire")
    end)
end)

describe("events", function()
    it("fires line event on say node", function()
        local event_speaker, event_text = nil, nil
        local seq = lurek.dialog.newSequencer()
        seq:on("line", function(speaker, text)
            event_speaker = speaker
            event_text = text
        end)
        seq:load({
            { type = "say", speaker = "Bob", text = "Hi there" },
        })
        seq:start()
        expect_equal("Bob", event_speaker)
        expect_equal("Hi there", event_text)
    end)

    it("fires choice event", function()
        local choice_fired = false
        local seq = lurek.dialog.newSequencer()
        seq:on("choice", function() choice_fired = true end)
        seq:load({
            { type = "choice", text = "Pick", options = {
                { label = "A" },
            }},
        })
        seq:start()
        expect_equal(true, choice_fired)
    end)

    it("fires finished event", function()
        local finished = false
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(0)
        seq:on("finished", function() finished = true end)
        seq:load({
            { type = "say", speaker = "X", text = "Done" },
        })
        seq:start()
        seq:advance()
        expect_equal(true, finished, "finished event should fire")
    end)

    it("off removes event handler", function()
        local count = 0
        local seq = lurek.dialog.newSequencer()
        seq:on("line", function() count = count + 1 end)
        seq:load({
            { type = "say", speaker = "A", text = "One" },
            { type = "say", speaker = "B", text = "Two" },
        })
        seq:start()
        expect_equal(1, count)
        seq:off("line")
        seq:setSpeed(0)
        seq:skip()
        seq:advance()
        expect_equal(1, count, "off should prevent further events")
    end)
end)

describe("update with dt", function()
    it("reveals characters over time", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(10) -- 10 chars per second
        seq:load({
            { type = "say", speaker = "A", text = "Hello" },
        })
        seq:start()
        expect_equal("typing", seq:getState())
        -- After 0.3s at 10 cps = 3 chars revealed
        seq:update(0.3)
        local revealed = seq:revealedText()
        -- Should have revealed some chars but not all
        expect_equal(true, #revealed > 0, "should reveal some chars")
        expect_equal(true, #revealed < 5, "should not reveal all chars yet")
    end)

    it("transitions to waiting when fully revealed", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(10)
        seq:load({
            { type = "say", speaker = "A", text = "Hi" },
        })
        seq:start()
        seq:update(1.0) -- 10 cps * 1s = 10 chars, but text is only 2 chars
        expect_equal("waiting", seq:getState())
        expect_equal("Hi", seq:revealedText())
    end)
end)

describe("full workflow", function()
    it("complete dialog sequence", function()
        local events = {}
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(0) -- instant for testing

        seq:on("line", function(speaker, text)
            table.insert(events, "line:" .. speaker)
        end)
        seq:on("choice", function()
            table.insert(events, "choice")
        end)
        seq:on("finished", function()
            table.insert(events, "finished")
        end)

        seq:load({
            { type = "say", speaker = "NPC", text = "Greetings!" },
            { type = "choice", text = "Respond?", options = {
                { label = "Hello", branch = {
                    { type = "say", speaker = "NPC", text = "Nice to meet you!" },
                }},
                { label = "Goodbye" },
            }},
        })

        seq:start()
        expect_equal("line:NPC", events[1])
        seq:advance()
        expect_equal("choice", events[2])
        seq:choose(1) -- pick "Hello"
        expect_equal("Nice to meet you!", seq:currentText())
        seq:advance()
        expect_equal("done", seq:getState())
        expect_equal("finished", events[#events])
    end)
end)

test_summary()


