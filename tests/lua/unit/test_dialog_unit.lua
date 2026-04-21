-- Dialog API integration tests
-- @tests lurek.dialog.newSequencer

local total, passed, failed = 0, 0, 0

local function describe(name, fn)
    print("  " .. name)
    fn()
end

local function it(name, fn)
    total = total + 1
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("    âś“ " .. name)
    else
        failed = failed + 1
        print("    âś— " .. name .. ": " .. tostring(err))
    end
end

local function expect_eq(a, b, msg)
    if a ~= b then
        error((msg or "") .. " expected " .. tostring(b) .. " got " .. tostring(a), 2)
    end
end

local function expect_type(val, t, msg)
    if type(val) ~= t then
        error((msg or "") .. " expected type " .. t .. " got " .. type(val), 2)
    end
end

local function expect_no_error(fn, msg)
    local ok, err = pcall(fn)
    if not ok then error((msg or "unexpected error") .. ": " .. tostring(err), 2) end
end

print("Dialog API Tests")
print("================")

-- @description Verifies that a new sequencer instance is created as userdata, reports its concrete type as Sequencer, and matches Object and Sequencer in typeOf while rejecting Image.
describe("newSequencer", function()
    -- @description Creates a sequencer with lurek.dialog.newSequencer() and asserts that the returned value is userdata.
    it("creates a sequencer", function()
        local seq = lurek.dialog.newSequencer()
        expect_type(seq, "userdata", "sequencer")
    end)

    -- @description Calls type() on a fresh sequencer and asserts that it returns the exact string "Sequencer".
    it("has type Sequencer", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:type(), "Sequencer")
    end)

    -- @description Checks typeOf on a fresh sequencer and asserts true for Object and Sequencer, and false for Image.
    it("typeOf Object", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:typeOf("Object"), true)
        expect_eq(seq:typeOf("Sequencer"), true)
        expect_eq(seq:typeOf("Image"), false)
    end)
end)

-- @description Confirms a newly created sequencer starts in the idle state, reports inactive status, and uses the default typing speed of 30.
describe("initial state", function()
    -- @description Asserts that getState() on a fresh sequencer returns "idle" before any script is loaded or started.
    it("starts idle", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:getState(), "idle")
    end)

    -- @description Asserts that isActive() is false on a fresh sequencer before playback begins.
    it("is not active", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:isActive(), false)
    end)

    -- @description Asserts that getSpeed() returns the default typing speed value of 30 on a new sequencer.
    it("default speed is 30", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:getSpeed(), 30)
    end)
end)

-- @description Verifies loading and starting behavior for both a say node and an empty script, including state transitions, speaker/text exposure, and active status.
describe("load and start", function()
    -- @description Loads one say node, starts the sequencer, and asserts typing state, speaker "Alice", text "Hello world", and active status.
    it("loads a say node and starts typing", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "Alice", text = "Hello world" },
        })
        seq:start()
        expect_eq(seq:getState(), "typing")
        expect_eq(seq:currentSpeaker(), "Alice")
        expect_eq(seq:currentText(), "Hello world")
        expect_eq(seq:isActive(), true)
    end)

    -- @description Loads an empty script, starts the sequencer, and asserts that it immediately enters the done state and is not active.
    it("handles empty script gracefully", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({})
        seq:start()
        expect_eq(seq:getState(), "done")
        expect_eq(seq:isActive(), false)
    end)
end)

-- @description Checks that setSpeed updates the configured typing speed and that a speed of 0 reveals say-node text instantly and skips straight to waiting.
describe("setSpeed / getSpeed", function()
    -- @description Sets the speed to 60 and asserts that getSpeed() returns the updated value.
    it("changes typing speed", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(60)
        expect_eq(seq:getSpeed(), 60)
    end)

    -- @description Sets speed to 0, starts a say node, and asserts immediate waiting state with the full revealed text "Instant".
    it("speed 0 means instant reveal", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(0)
        seq:load({
            { type = "say", speaker = "X", text = "Instant" },
        })
        seq:start()
        expect_eq(seq:getState(), "waiting")
        expect_eq(seq:revealedText(), "Instant")
    end)
end)

-- @description Verifies skip and advance behavior across typing, waiting, next-node progression, and completion after the final node.
describe("advance and skip", function()
    -- @description Starts a typing say node, calls skip(), and asserts a transition to waiting with the full text "Hello" revealed.
    it("skip goes from typing to waiting", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "Hello" },
        })
        seq:start()
        expect_eq(seq:getState(), "typing")
        seq:skip()
        expect_eq(seq:getState(), "waiting")
        expect_eq(seq:revealedText(), "Hello")
    end)

    -- @description Starts a typing say node, calls advance() during typing, and asserts that it behaves like a skip by moving to waiting.
    it("advance from typing skips to waiting", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "Hello" },
        })
        seq:start()
        seq:advance()
        expect_eq(seq:getState(), "waiting")
    end)

    -- @description Uses instant speed across two say nodes, advances from the first waiting node, and asserts that speaker control moves from A to B while staying in waiting.
    it("advance from waiting goes to next node", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "First" },
            { type = "say", speaker = "B", text = "Second" },
        })
        seq:setSpeed(0)
        seq:start()
        expect_eq(seq:currentSpeaker(), "A")
        seq:advance()
        expect_eq(seq:currentSpeaker(), "B")
        expect_eq(seq:getState(), "waiting")
    end)

    -- @description Uses instant speed on a single say node, advances past it, and asserts that the sequencer reaches done and becomes inactive.
    it("advance past last node goes to done", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(0)
        seq:load({
            { type = "say", speaker = "A", text = "Only" },
        })
        seq:start()
        seq:advance()
        expect_eq(seq:getState(), "done")
        expect_eq(seq:isActive(), false)
    end)
end)

-- @description Verifies choice-node entry state, choice label extraction, and branch selection that swaps the current text to the chosen branch's say node.
describe("choice nodes", function()
    -- @description Starts a choice node and asserts choice state, waiting-for-choice status, and the prompt text "Pick one".
    it("enters choice state", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "choice", text = "Pick one", options = {
                { label = "Option A" },
                { label = "Option B" },
            }},
        })
        seq:start()
        expect_eq(seq:getState(), "choice")
        expect_eq(seq:isWaitingForChoice(), true)
        expect_eq(seq:getChoiceText(), "Pick one")
    end)

    -- @description Starts a three-option choice node, reads the choice labels, and asserts the exact ordered labels Yes, No, and Maybe.
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
        expect_eq(#labels, 3)
        expect_eq(labels[1], "Yes")
        expect_eq(labels[2], "No")
        expect_eq(labels[3], "Maybe")
    end)

    -- @description Starts a two-branch choice, selects option 2, and asserts that the current text becomes the B-branch line "You chose B".
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
        expect_eq(seq:currentText(), "You chose B")
    end)
end)

-- @description Verifies that starting a wait node moves the sequencer into the paused state.
describe("wait nodes", function()
    -- @description Loads a wait node with time 2.0, starts it, and asserts that the sequencer state is "paused".
    it("enters paused state with timer", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "wait", time = 2.0 },
        })
        seq:start()
        expect_eq(seq:getState(), "paused")
    end)
end)

-- @description Verifies that call nodes execute their callback immediately when the sequencer starts.
describe("call nodes", function()
    -- @description Loads a call node whose function flips a local flag and asserts that the flag is true after start().
    it("invokes callback on start", function()
        local called = false
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "call", fn = function() called = true end },
        })
        seq:start()
        expect_eq(called, true, "call callback should fire")
    end)
end)

-- @description Verifies line, choice, and finished event emission, and confirms that off("line") prevents later line callbacks from firing.
describe("events", function()
    -- @description Registers a line handler, starts a say node for Bob saying "Hi there", and asserts that the event receives that exact speaker and text.
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
        expect_eq(event_speaker, "Bob")
        expect_eq(event_text, "Hi there")
    end)

    -- @description Registers a choice handler, starts a choice node, and asserts that the choice event fires by setting the flag to true.
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
        expect_eq(choice_fired, true)
    end)

    -- @description Registers a finished handler, completes an instant one-line sequence, and asserts that the finished event flag becomes true.
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
        expect_eq(finished, true, "finished event should fire")
    end)

    -- @description Registers a line handler across two say nodes, asserts the first line increments the count once, removes the handler with off("line"), and asserts the second line does not increment it again.
    it("off removes event handler", function()
        local count = 0
        local seq = lurek.dialog.newSequencer()
        seq:on("line", function() count = count + 1 end)
        seq:load({
            { type = "say", speaker = "A", text = "One" },
            { type = "say", speaker = "B", text = "Two" },
        })
        seq:start()
        expect_eq(count, 1)
        seq:off("line")
        seq:setSpeed(0)
        seq:skip()
        seq:advance()
        expect_eq(count, 1, "off should prevent further events")
    end)
end)

-- @description Verifies time-based text reveal during typing and the automatic transition to waiting once the entire line has been revealed.
describe("update with dt", function()
    -- @description Sets speed to 10 chars per second, updates for 0.3 seconds on "Hello", and asserts that revealedText has more than 0 but fewer than 5 characters.
    it("reveals characters over time", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(10) -- 10 chars per second
        seq:load({
            { type = "say", speaker = "A", text = "Hello" },
        })
        seq:start()
        expect_eq(seq:getState(), "typing")
        -- After 0.3s at 10 cps = 3 chars revealed
        seq:update(0.3)
        local revealed = seq:revealedText()
        -- Should have revealed some chars but not all
        expect_eq(#revealed > 0, true, "should reveal some chars")
        expect_eq(#revealed < 5, true, "should not reveal all chars yet")
    end)

    -- @description Sets speed to 10 chars per second, updates a two-character line for 1.0 second, and asserts that the state becomes waiting with full text "Hi" revealed.
    it("transitions to waiting when fully revealed", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(10)
        seq:load({
            { type = "say", speaker = "A", text = "Hi" },
        })
        seq:start()
        seq:update(1.0) -- 10 cps * 1s = 10 chars, but text is only 2 chars
        expect_eq(seq:getState(), "waiting")
        expect_eq(seq:revealedText(), "Hi")
    end)
end)

-- @description Verifies an end-to-end sequence with line, choice, branch selection, and finished events, asserting the recorded event order and final done state.
describe("full workflow", function()
    -- @description Runs an instant say-plus-choice sequence, asserts the first event is line:NPC, the next event is choice, choosing option 1 yields "Nice to meet you!", and the sequence ends in done with finished as the last event.
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
        expect_eq(events[1], "line:NPC")
        seq:advance()
        expect_eq(events[2], "choice")
        seq:choose(1) -- pick "Hello"
        expect_eq(seq:currentText(), "Nice to meet you!")
        seq:advance()
        expect_eq(seq:getState(), "done")
        expect_eq(events[#events], "finished")
    end)
end)

_test_results = { total = total, passed = passed, failed = failed }

test_summary()
