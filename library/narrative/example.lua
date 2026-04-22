-- content/library/narrative/example.lua
-- Self-contained narrative example — three-knot scene with choices, tags,
-- variable interpolation, and save/resume.

local narrative = require("library.narrative")

local source = [[
VAR player_name = "Alric"
VAR met_king = false

=== START ===
The herald announces you, {player_name}. # music:fanfare
* Bow before the king | -> COURT
* { not met_king } Sneak into the antechamber | -> SNEAK
+ Wait silently
-> START

=== COURT ===
~ met_king = true
The king nods, pleased. # mood:warm
You have visited the court {visit_count} times.
-> END

=== SNEAK ===
You slip past the guards. # stealth:ok
-> END
]]

local story = narrative.compile(source):start()

-- Bind a function callable from {visit_count} markers.
story:bindFunction("visit_count", function() return story:visit("COURT") end)

-- Tag handler example.
story:onTag("music", function(tag) print("[music cue]", tag) end)

-- Drain to first choice
print("--- intro ---")
print(story:continueAll())

-- Show + auto-pick the first available choice.
local function pick(idx)
    print(string.format("[choice] %d", idx))
    story:choose(idx)
end

print("--- choices: ---")
for _, c in ipairs(story:getChoices()) do
    print(string.format("  %d. %s%s", c.index, c.text,
        c.available and "" or " [unavailable]"))
end
pick(1)   -- bow before the king

print("--- court ---")
print(story:continueAll())

print(string.format("met_king now = %s, visited COURT %d times",
    tostring(story:getVar("met_king")), story:visit("COURT")))

-- Save / resume round-trip
local blob = story:save()
local cloned = narrative.compile(source):resume(blob)
print(string.format("[restored] knot=%s ended=%s player=%s",
    tostring(cloned._knot), tostring(cloned:isEnded()),
    cloned:getVar("player_name")))

return story
