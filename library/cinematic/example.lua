-- content/library/cinematic/example.lua
-- Self-contained cinematic example — short intro with camera moves, shake,
-- dialog, audio, label skip, and a completion callback.

local cine = require("library.cinematic")

local intro = cine.newTimeline({ timeScale = 1.0, autoStart = true })

intro:setDialogHandler(function(line)
    print(string.format("[dialog] %s: %s",
        line.speaker or "???", line.text or ""))
end)

local cam   = intro:track("camera")
local sfx   = intro:track("sfx")
local talk  = intro:track("dialog")
local logic = intro:track("logic")

cam:cameraTo(0.0, 2.0, 100, 200, 1.0, "outQuad")
   :shake(2.0, 0.4, 0.6)
   :cameraTo(2.4, 1.5, 300, 200, 1.5, "inOutSine")

sfx:audio(0.0, "audio/intro_swell.ogg", { fade = 1.0 })
   :audio(2.0, "audio/explosion.wav")

talk:dialog(0.5, { speaker = "Hero",   text = "What is this place?" })
    :dialog(2.5, { speaker = "Spirit", text = "It begins." })

local triggered = { intro_done = false }
logic:call(3.5, function() triggered.intro_done = true end, { reversible = true })

intro:label(2.0, "explosion")
intro:onComplete(function()
    print("[on_complete] cutscene finished at t = "..intro:getTime())
end)

print("--- step the cutscene 0.5s at a time ---")
for _ = 1, 10 do
    intro:update(0.5)
    print(string.format("t=%.2f playing=%s finished=%s",
        intro:getTime(), tostring(intro:isPlaying()), tostring(intro:isFinished())))
end

-- Now demonstrate scrubbing.
print("--- scrub back to start, then jump to label ---")
intro:setTime(0)
intro:skipTo("explosion")
print(string.format("after skipTo('explosion') t = %.2f", intro:getTime()))

print(string.format("intro_done flag = %s", tostring(triggered.intro_done)))

return intro
