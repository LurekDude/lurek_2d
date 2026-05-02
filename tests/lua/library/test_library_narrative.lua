-- tests/lua/library/test_library_narrative.lua
-- BDD tests for library/narrative/init.lua     Ink-subset interpreter.

local narrative = require("library.narrative")


describe("compile + continue", function()
    it("compiles and runs a single-knot prose-only story", function()
        local s = narrative.compile([[
=== START ===
Hello world.
Second line.
-> END
]]):start()
        expect_equal("Hello world.", s:continue())
        expect_equal("Second line.", s:continue())
        -- next continue ends story
        s:continue()
        expect_true(s:isEnded())
    end)

    it("emits choices and advances on choose(index)", function()
        local s = narrative.compile([[
=== START ===
Pick one.
* Left | -> LEFT
* Right | -> RIGHT
=== LEFT ===
You went left.
-> END
=== RIGHT ===
You went right.
-> END
]]):start()
        s:continue()   -- "Pick one."
        s:continue()   -- triggers choice gathering
        expect_true(s:isAtChoice())
        local choices = s:getChoices()
        expect_length(choices, 2)
        expect_equal("Left", choices[1].text)
        s:choose(2)
        expect_equal("You went right.", s:continue())
    end)
end)

describe("conditional choices", function()
    it("hides choices guarded by failing conditions", function()
        local s = narrative.compile([[
VAR has_key = false
=== START ===
A door.
* Knock | -> END
* { has_key } Unlock the door | -> END
-> END
]]):start()
        s:continue()   -- "A door."
        s:continue()   -- triggers choice gathering
        local choices = s:getChoices()
        expect_length(choices, 2)
        expect_true(choices[1].available)
        expect_false(choices[2].available)
    end)

    it("raises when choosing an unavailable choice", function()
        local s = narrative.compile([[
VAR ok = false
=== START ===
Door.
* { ok } Open | -> END
* Leave | -> END
]]):start()
        s:continue()
        expect_error(function() s:choose(1) end)
    end)
end)

describe("variables & inline substitution", function()
    it("substitutes Lua-bound function values inside {fn()} markers", function()
        local s = narrative.compile([[
=== START ===
HP: {hp()}
-> END
]]):start()
        s:bindFunction("hp", function() return 42 end)
        expect_equal("HP: 42", s:continue())
    end)

    it("substitutes simple {var} references", function()
        local s = narrative.compile([[
VAR who = "Alric"
=== START ===
Hello {who}.
-> END
]]):start()
        expect_equal("Hello Alric.", s:continue())
    end)
end)

describe("tags", function()
    it("tag handlers fire when their tag appears", function()
        local seen = {}
        local s = narrative.compile([[
=== START ===
Music. # music:cue1
Quiet line.
-> END
]]):start()
        s:onTag("music:cue1", function(t) seen[#seen + 1] = t end)
        s:continue(); s:continue()
        expect_length(seen, 1)
        expect_equal("music:cue1", seen[1])
    end)
end)

describe("flow control", function()
    it("visit counter increments across diverts", function()
        local s = narrative.compile([[
=== START ===
First.
-> COURT
=== COURT ===
At court.
-> END
]]):start()
        s:continueAll()
        expect_equal(1, s:visit("COURT"))
        expect_equal(1, s:visit("START"))
    end)

    it("turnsSince returns math.huge for never-visited knots", function()
        local s = narrative.compile("=== START ===\nHi.\n-> END\n"):start()
        expect_equal(math.huge, s:turnsSince("MISSING"))
    end)
end)

describe("save / resume", function()
    it("round-trips variables and turn counter", function()
        local src = [[
VAR mood = "happy"
=== START ===
Greetings.
-> END
]]
        local s = narrative.compile(src):start()
        s:setVar("mood", "grim")
        s:continue()   -- "Greetings."
        s:continue()   -- processes -> END divert
        local blob = s:save()
        local s2 = narrative.compile(src):resume(blob)
        expect_equal("grim", s2:getVar("mood"))
        expect_true(s2:isEnded())
    end)
end)

describe("error paths", function()
    it("raises descriptive error on unknown knot divert", function()
        expect_error(function()
            narrative.compile([[
=== START ===
Hi.
-> NOPE
]]):start():continueAll()
        end)
    end)

    it("compile raises on malformed VAR", function()
        expect_error(function()
            narrative.compile("VAR _\n=== START ===\nHi.\n-> END\n")
        end)
    end)

    describe("module helpers", function()
        it("formatList emits Oxford-style enumeration", function()
            expect_equal("a", narrative.formatList({"a"}))
            expect_equal("a and b", narrative.formatList({"a","b"}))
            expect_equal("a, b, and c", narrative.formatList({"a","b","c"}))
        end)
    end)
end)
test_summary()
