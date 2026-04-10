-- Dialog API integration tests
-- @covers lurek.dialog.newSequencer

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
        print("    ✓ " .. name)
    else
        failed = failed + 1
        print("    ✗ " .. name .. ": " .. tostring(err))
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

describe("newSequencer", function()
    it("creates a sequencer", function()
        local seq = lurek.dialog.newSequencer()
        expect_type(seq, "userdata", "sequencer")
    end)

    it("has type Sequencer", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:type(), "Sequencer")
    end)

    it("typeOf Object", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:typeOf("Object"), true)
        expect_eq(seq:typeOf("Sequencer"), true)
        expect_eq(seq:typeOf("Image"), false)
    end)
end)

describe("initial state", function()
    it("starts idle", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:getState(), "idle")
    end)

    it("is not active", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:isActive(), false)
    end)

    it("default speed is 30", function()
        local seq = lurek.dialog.newSequencer()
        expect_eq(seq:getSpeed(), 30)
    end)
end)

describe("load and start", function()
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

    it("handles empty script gracefully", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({})
        seq:start()
        expect_eq(seq:getState(), "done")
        expect_eq(seq:isActive(), false)
    end)
end)

describe("setSpeed / getSpeed", function()
    it("changes typing speed", function()
        local seq = lurek.dialog.newSequencer()
        seq:setSpeed(60)
        expect_eq(seq:getSpeed(), 60)
    end)

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

describe("advance and skip", function()
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

    it("advance from typing skips to waiting", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "say", speaker = "A", text = "Hello" },
        })
        seq:start()
        seq:advance()
        expect_eq(seq:getState(), "waiting")
    end)

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
        expect_eq(seq:getState(), "choice")
        expect_eq(seq:isWaitingForChoice(), true)
        expect_eq(seq:getChoiceText(), "Pick one")
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
        expect_eq(#labels, 3)
        expect_eq(labels[1], "Yes")
        expect_eq(labels[2], "No")
        expect_eq(labels[3], "Maybe")
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
        expect_eq(seq:currentText(), "You chose B")
    end)
end)

describe("wait nodes", function()
    it("enters paused state with timer", function()
        local seq = lurek.dialog.newSequencer()
        seq:load({
            { type = "wait", time = 2.0 },
        })
        seq:start()
        expect_eq(seq:getState(), "paused")
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
        expect_eq(called, true, "call callback should fire")
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
        expect_eq(event_speaker, "Bob")
        expect_eq(event_text, "Hi there")
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
        expect_eq(choice_fired, true)
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
        expect_eq(finished, true, "finished event should fire")
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
        expect_eq(count, 1)
        seq:off("line")
        seq:setSpeed(0)
        seq:skip()
        seq:advance()
        expect_eq(count, 1, "off should prevent further events")
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
        expect_eq(seq:getState(), "typing")
        -- After 0.3s at 10 cps = 3 chars revealed
        seq:update(0.3)
        local revealed = seq:revealedText()
        -- Should have revealed some chars but not all
        expect_eq(#revealed > 0, true, "should reveal some chars")
        expect_eq(#revealed < 5, true, "should not reveal all chars yet")
    end)

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
