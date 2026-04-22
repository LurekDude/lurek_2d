--- Example usage for library.dialog.
-- Run from project root with: lua content/library/dialog/example.lua
-- @module example.dialog

package.path = "content/?.lua;content/?/init.lua;" .. package.path
local dialog = require("library.dialog")

print("[example.dialog] === Scenario 1: build a script with node helpers ===")

local script = {
    dialog.say("Alice", "Hello, traveller!"),
    dialog.say("Alice", "What brings you to the woods?"),
    dialog.choice("Choose your reply:", {
        { label = "I seek adventure.", branch = {
            dialog.say("Alice", "Then take the eastern path."),
        }},
        { label = "I am lost.",        branch = {
            dialog.say("Alice", "The village lies south of here."),
            dialog.event("quest_hint", { topic = "village" }),
        }},
    }),
    dialog.wait(0.2),
    dialog.event("scene_end", { scene = "intro" }),
}
print(string.format("  script nodes: %d", #script))

print("[example.dialog] === Scenario 2: attach printing observer ===")

local seq = dialog.newSequencer()
seq:setSpeed(1000)  -- effectively instant reveal for the demo

seq:on("line", function(speaker, text)
    print(string.format("  [LINE]   %s: %s", speaker, text))
end)
seq:on("choice", function()
    print(string.format("  [CHOICE] %s", seq:getChoiceText()))
end)
seq:on("event", function(name, data)
    local key = (data and next(data)) or "<no-data>"
    print(string.format("  [EVENT]  %s  data.%s=%s",
        name, key, tostring(data and data[key])))
end)
seq:on("done", function() print("  [DONE]   sequence complete") end)

seq:load(script)
seq:start()

print("[example.dialog] === Scenario 3: drive sequence with simulated input ===")

-- Big dt to flush typing for the first say node.
seq:update(1.0)
print(string.format("  state after first update: %s", seq:getState()))
seq:advance()                       -- to second say
seq:update(1.0); seq:advance()      -- to choice
print(string.format("  state at choice: %s isChoice=%s",
    seq:getState(), tostring(seq:isWaitingForChoice())))
print("  options: " .. table.concat(seq:getChoiceLabels(), " | "))
seq:choose(2)                       -- pick "I am lost"
seq:update(1.0); seq:advance()      -- play branch say
seq:update(1.0); seq:advance()      -- branch event
seq:update(1.0)                     -- wait
seq:update(1.0); seq:advance()      -- final event
print(string.format("  final state: %s", seq:getState()))

print("[example.dialog] === Scenario 4: skip the typewriter mid-line ===")

local seq2 = dialog.newSequencer()
seq2:setSpeed(2)  -- very slow
seq2:load({ dialog.say("Bard", "A long, slowly-revealed line.") })
seq2:start()
seq2:update(0.05)
print(string.format("  partial: %q", seq2:revealedText()))
seq2:skip()
print(string.format("  after skip: %q  state=%s",
    seq2:revealedText(), seq2:getState()))

print("[example.dialog] === Scenario 5: jump label control flow ===")

local seq3 = dialog.newSequencer()
seq3:on("line", function(s, t) print(string.format("  [LINE]   %s: %s", s, t)) end)
seq3:load({
    dialog.say("Narrator", "Skipping ahead..."),
    dialog.jump("end_label"),
    dialog.say("Narrator", "(this should not appear)"),
    dialog.say("Narrator", "Goodbye.", { label = "end_label" }),
})
seq3:setSpeed(1000)
seq3:start()
for _ = 1, 10 do seq3:update(0.5); seq3:advance() end

print("[example.dialog] === Scenario 6: serialise script via lurek.serial if available ===")

local ok_codec, codec = pcall(require, "lurek.serial")
if ok_codec and codec and codec.toJson then
    local snapshot = { dialog.say("Alice", "round-trip"), dialog.wait(0.5) }
    local s = codec.toJson(snapshot)
    print("  codec.toJson: " .. s)
    if codec.fromJson then
        local t = codec.fromJson(s)
        print(string.format("  codec.fromJson type[1]=%s", t[1] and t[1].type))
    end
else
    print("  no lurek.serial — script can be saved as a Lua table literal manually")
end

print("[example.dialog] done.")
