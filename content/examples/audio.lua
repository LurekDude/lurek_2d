-- content/examples/audio.lua
-- Hand-written coverage of the lurek.audio API (212 items).
--
-- Audio playback runs against the active rodio device, so most snippets
-- place their calls inside a `function lurek.init() ... end` callback that
-- the engine invokes once the device is ready. Sources, buses, MIDI players,
-- pools, decoders, and SoundData buffers are constructed in-block so each
-- example is self-contained and shows where the handle comes from.
--
-- Run: cargo run -- content/examples/audio.lua

-- ── lurek.audio.* functions ──

--@api-stub: lurek.audio.newSource
-- Loads an audio file and returns a Source handle.
-- Pass "static" for short SFX (decoded once, cheap to replay) and the default streaming mode for music.
do  -- lurek.audio.newSource
  function lurek.init()
    local jump = lurek.audio.newSource("sfx/jump.ogg", "static")
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setLooping(music, true)
    lurek.audio.play(music)
    _G.jump_sfx = jump
  end
end

--@api-stub: lurek.audio.play
-- Plays a source, with optional bus routing via options table.
-- Pass an `{bus = "sfx"}` options table to route the source through a previously created mix bus.
do  -- lurek.audio.play
  function lurek.init()
    local hit = lurek.audio.newSource("sfx/hit.ogg", "static")
    lurek.audio.newBus("sfx")
    lurek.audio.play(hit, {bus = "sfx"})
  end
end

--@api-stub: lurek.audio.stop
-- Stops playback and resets seek position.
-- Stops and rewinds the source so the next `play` call restarts cleanly from the first sample.
do  -- lurek.audio.stop
  function lurek.init()
    local sirene = lurek.audio.newSource("sfx/alarm.ogg", "static")
    lurek.audio.play(sirene)
    lurek.audio.stop(sirene)
  end
end

--@api-stub: lurek.audio.setVolume
-- Sets source playback volume.
-- Volume is a linear 0.0–1.0 multiplier; for perceptual fades use a curve like `vol = target ^ 2`.
do  -- lurek.audio.setVolume
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setVolume(music, 0.7)
    lurek.audio.play(music)
  end
end

--@api-stub: lurek.audio.getVolume
-- Returns the source volume.
-- Read back the per-source volume (independent of master and bus volume) for HUD bars or save state.
do  -- lurek.audio.getVolume
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setVolume(music, 0.7)
    local v = lurek.audio.getVolume(music)
    lurek.log.info("music volume=" .. v, "audio")
  end
end

--@api-stub: lurek.audio.pause
-- Pauses playback at the current position.
-- Pause keeps the playhead in place so `resume` continues; use `stop` if you want to restart from zero.
do  -- lurek.audio.pause
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music)
    lurek.audio.pause(music)
  end
end

--@api-stub: lurek.audio.resume
-- Resumes playback from pause.
-- Pair with `pause` to implement an in-game pause menu without losing the current playback position.
do  -- lurek.audio.resume
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music)
    lurek.audio.pause(music)
    lurek.audio.resume(music)
  end
end

--@api-stub: lurek.audio.setPitch
-- Sets source pitch multiplier.
-- Pitch shifts time too; values >1.0 speed up and raise pitch, <1.0 slow down. Range roughly 0.5–2.0.
do  -- lurek.audio.setPitch
  function lurek.init()
    local engine = lurek.audio.newSource("sfx/engine.ogg", "static")
    lurek.audio.setPitch(engine, 1.25)
    lurek.audio.play(engine)
  end
end

--@api-stub: lurek.audio.getPitch
-- Returns the source pitch multiplier.
-- Useful when chaining pitch tweens: read the current value, interpolate, then `setPitch` to the result.
do  -- lurek.audio.getPitch
  function lurek.init()
    local engine = lurek.audio.newSource("sfx/engine.ogg", "static")
    lurek.audio.setPitch(engine, 1.25)
    local p = lurek.audio.getPitch(engine)
    lurek.log.info("engine pitch=" .. p, "audio")
  end
end

--@api-stub: lurek.audio.isPlaying
-- Returns true if the source is playing.
-- Poll once per frame to decide whether to start the next looped clip in a queued playlist.
do  -- lurek.audio.isPlaying
  function lurek.init()
    local sting = lurek.audio.newSource("sfx/sting.ogg", "static")
    lurek.audio.play(sting)
    if lurek.audio.isPlaying(sting) then lurek.log.info("sting active", "audio") end
  end
end

--@api-stub: lurek.audio.isPaused
-- Returns true if the source is paused.
-- Distinguishes paused-but-positioned from fully stopped sources; useful for resume buttons.
do  -- lurek.audio.isPaused
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music); lurek.audio.pause(music)
    if lurek.audio.isPaused(music) then lurek.audio.resume(music) end
  end
end

--@api-stub: lurek.audio.isStopped
-- Returns true if the source is stopped.
-- Returns true after `stop` or natural end-of-stream; use to recycle voices in a custom pool.
do  -- lurek.audio.isStopped
  function lurek.init()
    local sting = lurek.audio.newSource("sfx/sting.ogg", "static")
    lurek.audio.play(sting); lurek.audio.stop(sting)
    if lurek.audio.isStopped(sting) then lurek.log.info("sting free", "audio") end
  end
end

--@api-stub: lurek.audio.setLooping
-- Enables or disables looping.
-- Call before `play` for music tracks; setting it on a one-shot SFX makes the clip repeat indefinitely.
do  -- lurek.audio.setLooping
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setLooping(music, true)
    lurek.audio.play(music)
  end
end

--@api-stub: lurek.audio.isLooping
-- Returns true if looping is enabled.
-- Read the looping flag when persisting per-source mixer state to a save file.
do  -- lurek.audio.isLooping
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setLooping(music, true)
    if lurek.audio.isLooping(music) then lurek.log.info("looping", "audio") end
  end
end

--@api-stub: lurek.audio.playLooping
-- Plays the source in a continuous loop.
-- Shortcut that sets looping=true and plays in one call; preferred for ambient loops and music beds.
do  -- lurek.audio.playLooping
  function lurek.init()
    local rain = lurek.audio.newSource("music/rain_loop.ogg")
    lurek.audio.setVolume(rain, 0.7)
    lurek.audio.playLooping(rain)
  end
end

--@api-stub: lurek.audio.setPan
-- Sets stereo panning (-1.0 left to 1.0 right).
-- Pan is mono-aware: -1 hard left, 0 centre, +1 hard right. For stereo sources combine with setStereoWidth.
do  -- lurek.audio.setPan
  function lurek.init()
    local sfx = lurek.audio.newSource("sfx/swoosh.ogg", "static")
    lurek.audio.setPan(sfx, -0.5)
    lurek.audio.play(sfx)
  end
end

--@api-stub: lurek.audio.getPan
-- Returns the source stereo panning.
-- Surface the current pan value to a debug overlay so designers can tune positional cues.
do  -- lurek.audio.getPan
  function lurek.init()
    local sfx = lurek.audio.newSource("sfx/swoosh.ogg", "static")
    lurek.audio.setPan(sfx, -0.5)
    local p = lurek.audio.getPan(sfx)
    lurek.log.info("pan=" .. p, "audio")
  end
end

--@api-stub: lurek.audio.setMasterVolume
-- Sets the global master volume.
-- Apply once at startup from a settings file; clamps in [0, 1] internally so user input is safe.
do  -- lurek.audio.setMasterVolume
  function lurek.init()
    local user_volume = 0.7
    lurek.audio.setMasterVolume(user_volume)
  end
end

--@api-stub: lurek.audio.getMasterVolume
-- Returns the global master volume.
-- Read the live master gain when drawing the settings slider so it reflects any in-game changes.
do  -- lurek.audio.getMasterVolume
  function lurek.init()
    lurek.audio.setMasterVolume(0.7)
    local mv = lurek.audio.getMasterVolume()
    lurek.log.info("master=" .. mv, "audio")
  end
end

--@api-stub: lurek.audio.getActiveSourceCount
-- Returns the number of currently playing sources.
-- Watch this counter while developing to catch leaked or never-released sources eating mixer voices.
do  -- lurek.audio.getActiveSourceCount
  function lurek.init()
    local sfx = lurek.audio.newSource("sfx/jump.ogg", "static")
    lurek.audio.play(sfx)
    lurek.log.info("active=" .. lurek.audio.getActiveSourceCount(), "audio")
  end
end

--@api-stub: lurek.audio.getSourceCount
-- Returns the total number of registered sources.
-- Returns total registered sources (playing or not) — useful for diagnosing slow source leaks.
do  -- lurek.audio.getSourceCount
  function lurek.init()
    local _ = lurek.audio.newSource("sfx/coin.ogg", "static")
    local n = lurek.audio.getSourceCount()
    lurek.log.info("sources=" .. n, "audio")
  end
end

--@api-stub: lurek.audio.getSourceType
-- Returns the type string ("static" or "stream") of a source.
-- Returns "static" or "stream"; branch when applying effects that only make sense for one mode.
do  -- lurek.audio.getSourceType
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    local t = lurek.audio.getSourceType(music)
    if t == "stream" then lurek.log.info("streamed", "audio") end
  end
end

--@api-stub: lurek.audio.clone
-- Creates an independent copy of a source.
-- Cheap polyphony: clone a static source so it can play overlapping copies without restarting.
do  -- lurek.audio.clone
  function lurek.init()
    local hit = lurek.audio.newSource("sfx/hit.ogg", "static")
    local hit2 = lurek.audio.clone(hit)
    lurek.audio.play(hit); lurek.audio.play(hit2)
  end
end

--@api-stub: lurek.audio.pauseAll
-- Pauses all currently playing sources.
-- Call from the pause-menu open hook to silence everything; pair with `resumeAll` on close.
do  -- lurek.audio.pauseAll
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music)
    lurek.audio.pauseAll()
  end
end

--@api-stub: lurek.audio.stopAll
-- Stops all currently playing sources.
-- Use on scene transitions or game-over to drop every voice cleanly before loading the next level.
do  -- lurek.audio.stopAll
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music)
    lurek.audio.stopAll()
  end
end

--@api-stub: lurek.audio.resumeAll
-- Resumes all paused sources.
-- Mirror of `pauseAll` — restart anything paused while preserving each source's playhead.
do  -- lurek.audio.resumeAll
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music); lurek.audio.pauseAll()
    lurek.audio.resumeAll()
  end
end

--@api-stub: lurek.audio.release
-- Releases a source and frees its memory.
-- Frees mixer memory; subsequent calls on the released handle raise an error so guard with isStopped.
do  -- lurek.audio.release
  function lurek.init()
    local sfx = lurek.audio.newSource("sfx/coin.ogg", "static")
    lurek.audio.stop(sfx)
    lurek.audio.release(sfx)
  end
end

--@api-stub: lurek.audio.newBus
-- Creates a named audio bus for grouping sources.
-- Create one bus per mix group ("music", "sfx", "voice") at startup, then route sources via `setSourceBus`.
do  -- lurek.audio.newBus
  function lurek.init()
    local sfx_bus = lurek.audio.newBus("sfx")
    sfx_bus:setVolume(0.7)
    lurek.log.info("bus=" .. sfx_bus:getName(), "audio")
  end
end

--@api-stub: lurek.audio.setSourceBus
-- Assigns a source to a bus.
-- Move a source to a different bus mid-game (e.g. when an NPC voice should duck under cinematic music).
do  -- lurek.audio.setSourceBus
  function lurek.init()
    local voice_bus = lurek.audio.newBus("voice")
    local line = lurek.audio.newSource("voice/line01.ogg", "static")
    lurek.audio.setSourceBus(line, voice_bus)
  end
end

--@api-stub: lurek.audio.getSourceBus
-- Returns the bus a source is assigned to, or nil.
-- Returns the current Bus handle (or nil) so you can re-apply per-bus volume after a settings change.
do  -- lurek.audio.getSourceBus
  function lurek.init()
    local sfx_bus = lurek.audio.newBus("sfx")
    local hit = lurek.audio.newSource("sfx/hit.ogg", "static")
    lurek.audio.setSourceBus(hit, sfx_bus)
    local b = lurek.audio.getSourceBus(hit)
    if b then lurek.log.info("on " .. b:getName(), "audio") end
  end
end

--@api-stub: lurek.audio.getMaxSources
-- Returns the maximum number of simultaneous sources.
-- Read once at startup to size your custom voice pool; current implementation reports 64 hardware voices.
do  -- lurek.audio.getMaxSources
  function lurek.init()
    local cap = lurek.audio.getMaxSources()
    lurek.log.info("max voices=" .. cap, "audio")
  end
end

--@api-stub: lurek.audio.getDuration
-- Returns the total duration of a source in seconds.
-- Use at level load to pre-roll a progress bar that tracks `tell / getDuration` across the cue.
do  -- lurek.audio.getDuration
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    local d = lurek.audio.getDuration(music)
    lurek.log.info("len=" .. d .. "s", "audio")
  end
end

--@api-stub: lurek.audio.tell
-- Returns the current playback position in seconds.
-- Read each frame to drive a beatmap or rhythm-game playhead; combine with seek for scrubbing UIs.
do  -- lurek.audio.tell
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music)
    local pos = lurek.audio.tell(music)
    lurek.log.info("at=" .. pos, "audio")
  end
end

--@api-stub: lurek.audio.seek
-- Seeks to a time position in seconds.
-- Position is in seconds; clamping past `getDuration` is the engine's job, but rounding is still on you.
do  -- lurek.audio.seek
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music)
    lurek.audio.seek(music, 30.0)
  end
end

--@api-stub: lurek.audio.setLowpass
-- Applies a low-pass filter to a source.
-- Use ~800 Hz for the muffled "underwater" effect; ~3000 Hz for room-vs-hallway separation.
do  -- lurek.audio.setLowpass
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music)
    lurek.audio.setLowpass(music, 800)
  end
end

--@api-stub: lurek.audio.setHighpass
-- Applies a high-pass filter to a source.
-- Strip subwoofer rumble (~80 Hz) before applying spatial reverb to keep mixes from getting muddy.
do  -- lurek.audio.setHighpass
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.play(music)
    lurek.audio.setHighpass(music, 200)
  end
end

--@api-stub: lurek.audio.getLowpass
-- Returns the low-pass filter cutoff of a source.
-- Inspect the active cutoff to drive a debug HUD or to lerp it back to 0 when the player surfaces.
do  -- lurek.audio.getLowpass
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setLowpass(music, 800)
    lurek.log.info("lpf=" .. lurek.audio.getLowpass(music), "audio")
  end
end

--@api-stub: lurek.audio.getHighpass
-- Returns the high-pass filter cutoff of a source.
-- Mirror of `getLowpass`; together they let you save and restore filter state per-source.
do  -- lurek.audio.getHighpass
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setHighpass(music, 200)
    lurek.log.info("hpf=" .. lurek.audio.getHighpass(music), "audio")
  end
end

--@api-stub: lurek.audio.clearFilter
-- Removes any active filter from a source.
-- Removes both low- and high-pass; call before reusing a source for a different sound class.
do  -- lurek.audio.clearFilter
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setLowpass(music, 800)
    lurek.audio.clearFilter(music)
  end
end

--@api-stub: lurek.audio.fadeIn
-- Fades a source in from silence over the given duration.
-- Schedules a linear fade from 0 to current volume over `dur` seconds — call before `play` for clean entries.
do  -- lurek.audio.fadeIn
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.fadeIn(music, 2.5)
    lurek.audio.play(music)
  end
end

--@api-stub: lurek.audio.getFadeIn
-- Returns the fade-in duration of a source.
-- Returns the configured fade-in seconds; useful when persisting per-cue fade settings to a save file.
do  -- lurek.audio.getFadeIn
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.fadeIn(music, 2.5)
    lurek.log.info("fade=" .. lurek.audio.getFadeIn(music), "audio")
  end
end

--@api-stub: lurek.audio.setListener2D
-- Sets the 2D listener position for spatial audio.
-- Drive each frame from your camera centre so positional sources pan correctly as the player moves.
do  -- lurek.audio.setListener2D
  function lurek.init()
    local cam_x, cam_y = 320.0, 240.0
    lurek.audio.setListener2D(cam_x, cam_y)
  end
end

--@api-stub: lurek.audio.getListener2D
-- Returns the 2D listener position (x, y).
-- Read back the listener after camera updates to confirm the audio system tracks the player.
do  -- lurek.audio.getListener2D
  function lurek.init()
    lurek.audio.setListener2D(320.0, 240.0)
    local lx, ly = lurek.audio.getListener2D()
    lurek.log.info("listener=" .. lx .. "," .. ly, "audio")
  end
end

--@api-stub: lurek.audio.setListener
-- Sets the 3D listener position.
-- 3D variant; pass z=0 for top-down games or use a small positive z to give vertical separation.
do  -- lurek.audio.setListener
  function lurek.init()
    lurek.audio.setListener(320.0, 240.0, 0.0)
  end
end

--@api-stub: lurek.audio.getListener
-- Returns the 3D listener position (x, y, z).
-- Returns the 3D listener position; pair with setVelocity for a full Doppler-aware setup.
do  -- lurek.audio.getListener
  function lurek.init()
    lurek.audio.setListener(320.0, 240.0, 0.0)
    local x, y, z = lurek.audio.getListener()
    lurek.log.info("listener=" .. x .. "," .. y .. "," .. z, "audio")
  end
end

--@api-stub: lurek.audio.setPosition
-- Sets the 3D position of a source.
-- Place positional sources in world coordinates; combine with `setDistanceModel` for falloff curves.
do  -- lurek.audio.setPosition
  function lurek.init()
    local foot = lurek.audio.newSource("sfx/footstep.ogg", "static")
    lurek.audio.setPosition(foot, 480.0, 240.0, 0.0)
    lurek.audio.play(foot)
  end
end

--@api-stub: lurek.audio.getPosition
-- Returns the 3D position of a source (x, y, z).
-- Read the source position to draw debug gizmos at audio emitter locations during development.
do  -- lurek.audio.getPosition
  function lurek.init()
    local foot = lurek.audio.newSource("sfx/footstep.ogg", "static")
    lurek.audio.setPosition(foot, 480.0, 240.0, 0.0)
    local x, y, z = lurek.audio.getPosition(foot)
    lurek.log.info("emitter=" .. x .. "," .. y .. "," .. z, "audio")
  end
end

--@api-stub: lurek.audio.setVelocity
-- Sets the velocity of a source for Doppler.
-- Update velocity each frame from the entity's movement delta so Doppler shift sounds natural.
do  -- lurek.audio.setVelocity
  function lurek.init()
    local car = lurek.audio.newSource("sfx/engine.ogg", "static")
    lurek.audio.setVelocity(car, 60.0, 0.0, 0.0)
    lurek.audio.play(car)
  end
end

--@api-stub: lurek.audio.getVelocity
-- Returns the velocity of a source (x, y, z).
-- Read back the stored velocity for debugging Doppler artefacts (clicks, frequency oscillation).
do  -- lurek.audio.getVelocity
  function lurek.init()
    local car = lurek.audio.newSource("sfx/engine.ogg", "static")
    lurek.audio.setVelocity(car, 60.0, 0.0, 0.0)
    local vx, vy, vz = lurek.audio.getVelocity(car)
    lurek.log.info("vel=" .. vx .. "," .. vy .. "," .. vz, "audio")
  end
end

--@api-stub: lurek.audio.setOrientation
-- Sets the 6-component orientation of a source.
-- Pass forward (fx,fy,fz) and up (ux,uy,uz) vectors; identity is forward=(0,0,-1) up=(0,1,0).
do  -- lurek.audio.setOrientation
  function lurek.init()
    local cone = lurek.audio.newSource("sfx/horn.ogg", "static")
    lurek.audio.setOrientation(cone, 0.0, 0.0, -1.0, 0.0, 1.0, 0.0)
    lurek.audio.play(cone)
  end
end

--@api-stub: lurek.audio.getOrientation
-- Returns the 6-component orientation of a source.
-- Returns six numbers (fx, fy, fz, ux, uy, uz) — useful when serialising spatial state.
do  -- lurek.audio.getOrientation
  function lurek.init()
    local cone = lurek.audio.newSource("sfx/horn.ogg", "static")
    lurek.audio.setOrientation(cone, 0.0, 0.0, -1.0, 0.0, 1.0, 0.0)
    local fx, fy, fz, ux, uy, uz = lurek.audio.getOrientation(cone)
    lurek.log.info("fwd=" .. fx .. "," .. fy .. "," .. fz, "audio")
  end
end

--@api-stub: lurek.audio.setDopplerScale
-- Sets the global Doppler effect scale.
-- 0.0 disables Doppler entirely; 1.0 is realistic; 2.0 exaggerates for arcade racing-style cues.
do  -- lurek.audio.setDopplerScale
  function lurek.init()
    lurek.audio.setDopplerScale(1.0)
  end
end

--@api-stub: lurek.audio.getDopplerScale
-- Returns the current Doppler scale.
-- Read back when wiring Doppler into a settings menu so the slider reflects engine state.
do  -- lurek.audio.getDopplerScale
  function lurek.init()
    lurek.audio.setDopplerScale(1.5)
    lurek.log.info("doppler=" .. lurek.audio.getDopplerScale(), "audio")
  end
end

--@api-stub: lurek.audio.setDistanceModel
-- Sets the distance attenuation model.
-- Names: "none", "inverse", "linear", "exponential". "linear" is the friendliest for top-down games.
do  -- lurek.audio.setDistanceModel
  function lurek.init()
    lurek.audio.setDistanceModel("linear")
  end
end

--@api-stub: lurek.audio.getDistanceModel
-- Returns the current distance model name.
-- Returns the active model name string — log on startup to confirm settings round-trip correctly.
do  -- lurek.audio.getDistanceModel
  function lurek.init()
    lurek.audio.setDistanceModel("linear")
    lurek.log.info("model=" .. lurek.audio.getDistanceModel(), "audio")
  end
end

--@api-stub: lurek.audio.setMeter
-- Sets the master peak meter level (0.0â€“1.0).
-- Game scripts publish their own master peak (0–1) so visualisers don't need direct DSP access.
do  -- lurek.audio.setMeter
  function lurek.init()
    lurek.audio.setMeter(0.7)
  end
end

--@api-stub: lurek.audio.getMeter
-- Returns the stored master peak meter level.
-- Read each frame to drive a VU-meter widget without hooking into the mixer audio thread.
do  -- lurek.audio.getMeter
  function lurek.init()
    lurek.audio.setMeter(0.7)
    lurek.log.info("meter=" .. lurek.audio.getMeter(), "audio")
  end
end

--@api-stub: lurek.audio.newMidiPlayer
-- Creates a MIDI player, optionally loading a file.
-- Pass a `.mid` path to load immediately; pass nil to construct empty and call `:load(path)` later.
do  -- lurek.audio.newMidiPlayer
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setLooping(true)
    mp:play()
  end
end

--@api-stub: lurek.audio.newSoundData
-- Creates a SoundData from a file or as a silent buffer.
-- Two forms: `(path)` loads a WAV/OGG file; `(count, rate, channels)` allocates a silent buffer.
do  -- lurek.audio.newSoundData
  function lurek.init()
    local sd = lurek.audio.newSoundData(44100, 44100, 1)
    lurek.log.info("samples=" .. sd:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.setMidiSoundFont
-- Sets the global SoundFont for MIDI synthesis.
-- Call once at startup with a `.sf2` path; affects every MIDI player created afterwards.
do  -- lurek.audio.setMidiSoundFont
  function lurek.init()
    lurek.audio.setMidiSoundFont("music/gm.sf2")
  end
end

--@api-stub: lurek.audio.hasMidiSoundFont
-- Returns true if a SoundFont is loaded.
-- Branch on this before launching MIDI playback to fall back to a recorded version when no SF2 is present.
do  -- lurek.audio.hasMidiSoundFont
  function lurek.init()
    if not lurek.audio.hasMidiSoundFont() then
      lurek.log.warn("no soundfont, MIDI will be silent", "audio")
    end
  end
end

--@api-stub: lurek.audio.clearMidiSoundFont
-- Unloads the active SoundFont.
-- Drops the loaded SoundFont to free memory between scenes that use different instrument banks.
do  -- lurek.audio.clearMidiSoundFont
  function lurek.init()
    lurek.audio.setMidiSoundFont("music/gm.sf2")
    lurek.audio.clearMidiSoundFont()
  end
end

--@api-stub: lurek.audio.newDecoder
-- Creates a streaming audio decoder.
-- Lets you pull PCM chunks manually for streaming visualisers; buffersize defaults to 2048 samples.
do  -- lurek.audio.newDecoder
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    lurek.log.info("rate=" .. dec:getSampleRate(), "audio")
  end
end

--@api-stub: lurek.audio.newQueueableSource
-- Creates a queueable source for manual PCM buffering.
-- Manual PCM streaming: returns an integer handle you feed via `queueSource` / `playQueueable`.
do  -- lurek.audio.newQueueableSource
  function lurek.init()
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    lurek.log.info("queueable id=" .. qs, "audio")
  end
end

--@api-stub: lurek.audio.queueSource
-- Pushes a SoundData buffer into a queueable source.
-- Push a SoundData chunk to a queueable source; check `getFreeBufferCount` first to avoid drops.
do  -- lurek.audio.queueSource
  function lurek.init()
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    local chunk = lurek.audio.newSineWave(440.0, 0.1, 44100, 0.5)
    lurek.audio.queueSource(qs, chunk)
  end
end

--@api-stub: lurek.audio.getFreeBufferCount
-- Returns the free buffer slots in a queueable source.
-- Use as backpressure: only push more chunks while the count is greater than zero.
do  -- lurek.audio.getFreeBufferCount
  function lurek.init()
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    local free = lurek.audio.getFreeBufferCount(qs)
    lurek.log.info("free buffers=" .. free, "audio")
  end
end

--@api-stub: lurek.audio.playQueueable
-- Starts playback of a queueable source.
-- Begin playback once enough buffers are queued; the first chunks must already be present.
do  -- lurek.audio.playQueueable
  function lurek.init()
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    local chunk = lurek.audio.newSineWave(440.0, 0.5, 44100, 0.5)
    lurek.audio.queueSource(qs, chunk)
    lurek.audio.playQueueable(qs)
  end
end

--@api-stub: lurek.audio.stopQueueable
-- Stops a queueable source and drains its buffers.
-- Drains pending chunks and silences the source — call when switching streams to avoid stale audio.
do  -- lurek.audio.stopQueueable
  function lurek.init()
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    lurek.audio.playQueueable(qs)
    lurek.audio.stopQueueable(qs)
  end
end

--@api-stub: lurek.audio.getPlaybackDevices
-- Returns a table of available audio output device names.
-- Returns an array of device-name strings; surface in a settings menu so users pick their headset.
do  -- lurek.audio.getPlaybackDevices
  function lurek.init()
    local devs = lurek.audio.getPlaybackDevices()
    for i, name in ipairs(devs) do lurek.log.info(i .. ": " .. name, "audio") end
  end
end

--@api-stub: lurek.audio.getPlaybackDevice
-- Returns the current audio output device name.
-- Read once after switching devices to confirm the mixer accepted the requested output.
do  -- lurek.audio.getPlaybackDevice
  function lurek.init()
    local cur = lurek.audio.getPlaybackDevice()
    lurek.log.info("device=" .. cur, "audio")
  end
end

--@api-stub: lurek.audio.setPlaybackDevice
-- Selects an audio output device by name.
-- Pass a device name returned by `getPlaybackDevices`; raises an error if the name is unknown.
do  -- lurek.audio.setPlaybackDevice
  function lurek.init()
    local devs = lurek.audio.getPlaybackDevices()
    if devs[1] then lurek.audio.setPlaybackDevice(devs[1]) end
  end
end

--@api-stub: lurek.audio.create_bus
-- Creates a bus by name (functional style).
-- Functional alternative to `newBus`: addresses buses by name, no handle returned. Pass parent for nesting.
do  -- lurek.audio.create_bus
  function lurek.init()
    lurek.audio.create_bus("music")
    lurek.audio.create_bus("ambient", "music")
  end
end

--@api-stub: lurek.audio.set_bus_volume
-- Sets a bus volume by name.
-- Adjust a named bus' gain without holding its handle — handy for menu sliders driven by string keys.
do  -- lurek.audio.set_bus_volume
  function lurek.init()
    lurek.audio.create_bus("music")
    lurek.audio.set_bus_volume("music", 0.7)
  end
end

--@api-stub: lurek.audio.add_effect
-- Adds a DSP effect to a bus.
-- effect_type is one of "lowpass", "highpass", "reverb", … `params.value` seeds the first DSP parameter.
do  -- lurek.audio.add_effect
  function lurek.init()
    lurek.audio.create_bus("sfx")
    local id = lurek.audio.add_effect("sfx", "lowpass", {value = 1500.0})
    lurek.log.info("effect id=" .. tostring(id), "audio")
  end
end

--@api-stub: lurek.audio.remove_effect
-- Removes a DSP effect from a bus.
-- Pass the integer id returned from `add_effect`; returns false (or raises) for unknown ids.
do  -- lurek.audio.remove_effect
  function lurek.init()
    lurek.audio.create_bus("sfx")
    local id = lurek.audio.add_effect("sfx", "lowpass", {value = 1500.0})
    lurek.audio.remove_effect("sfx", id)
  end
end

--@api-stub: lurek.audio.set_effect_param
-- Sets a parameter on a DSP effect.
-- Per-effect parameter names — "cutoff", "q", "mix" — vary; consult the EffectType source for valid keys.
do  -- lurek.audio.set_effect_param
  function lurek.init()
    lurek.audio.create_bus("sfx")
    local id = lurek.audio.add_effect("sfx", "lowpass", {value = 1500.0})
    lurek.audio.set_effect_param("sfx", id, "cutoff", 800.0)
  end
end

--@api-stub: lurek.audio.newSineWave
-- Generate a mono sine-wave SoundData buffer.
-- Synthesise a SoundData buffer for instant tones — handy for UI beeps and procedural music.
do  -- lurek.audio.newSineWave
  function lurek.init()
    local beep = lurek.audio.newSineWave(440.0, 0.25, 44100, 0.5)
    lurek.log.info("beep samples=" .. beep:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.newSquareWave
-- Generate a mono square-wave SoundData buffer.
-- Brighter than a sine; good for chiptune-style retro effects. Amplitude 0.5 avoids clipping.
do  -- lurek.audio.newSquareWave
  function lurek.init()
    local sq = lurek.audio.newSquareWave(220.0, 0.5, 44100, 0.5)
    lurek.log.info("square samples=" .. sq:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.newSawtoothWave
-- Generate a mono sawtooth-wave SoundData buffer.
-- Buzzy harmonic-rich timbre; subtractive-synth lead patches start here then add a low-pass filter.
do  -- lurek.audio.newSawtoothWave
  function lurek.init()
    local saw = lurek.audio.newSawtoothWave(110.0, 1.0, 44100, 0.5)
    lurek.log.info("saw len=" .. saw:getDuration(), "audio")
  end
end

--@api-stub: lurek.audio.newTriangleWave
-- Generate a mono triangle-wave SoundData buffer.
-- Halfway between sine (mellow) and square (bright); classic for soft 8-bit lead voices.
do  -- lurek.audio.newTriangleWave
  function lurek.init()
    local tri = lurek.audio.newTriangleWave(330.0, 0.5, 44100, 0.5)
    lurek.log.info("tri samples=" .. tri:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.newWhiteNoise
-- Generate a reproducible white-noise SoundData buffer.
-- Seedable so playthroughs reproduce identical noise — great for impact stingers and footstep variation.
do  -- lurek.audio.newWhiteNoise
  function lurek.init()
    local noise = lurek.audio.newWhiteNoise(0.5, 44100, 0.3, 12345)
    lurek.log.info("noise samples=" .. noise:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.applyLowpass
-- Applies a first-order IIR low-pass filter to a SoundData in-place.
-- In-place: cuts frequencies above `cutoff_hz` on the SoundData. Good for muffling synth tones offline.
do  -- lurek.audio.applyLowpass
  function lurek.init()
    local saw = lurek.audio.newSawtoothWave(110.0, 1.0, 44100, 0.5)
    lurek.audio.applyLowpass(saw, 800.0)
  end
end

--@api-stub: lurek.audio.applyHighpass
-- Applies a first-order IIR high-pass filter to a SoundData in-place.
-- Removes everything below `cutoff_hz`; use ~80 Hz to clean up DC offset before normalising a buffer.
do  -- lurek.audio.applyHighpass
  function lurek.init()
    local saw = lurek.audio.newSawtoothWave(110.0, 1.0, 44100, 0.5)
    lurek.audio.applyHighpass(saw, 80.0)
  end
end

--@api-stub: lurek.audio.applyBandpass
-- Applies a bandpass filter (high-pass then low-pass) to a SoundData in-place.
-- Combines high-pass and low-pass for a band; tight bands ("telephone EQ") use ~300–3400 Hz.
do  -- lurek.audio.applyBandpass
  function lurek.init()
    local sd = lurek.audio.newWhiteNoise(0.5, 44100, 0.3, 1)
    lurek.audio.applyBandpass(sd, 300.0, 3400.0)
  end
end

--@api-stub: lurek.audio.applyGain
-- Scales every sample by gain (clamped to [-1, 1]).
-- Multiplies every sample, clipping to [-1, 1]; for headroom-safe boosts, prefer `mixInto` with normalise.
do  -- lurek.audio.applyGain
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 0.25, 44100, 0.3)
    lurek.audio.applyGain(sd, 1.5)
  end
end

--@api-stub: lurek.audio.mixInto
-- Additively mixes another SoundData into the destination in-place.
-- Adds `src` samples on top of `dest` in place; both buffers must share sample rate and channel count.
do  -- lurek.audio.mixInto
  function lurek.init()
    local a = lurek.audio.newSineWave(440.0, 0.5, 44100, 0.3)
    local b = lurek.audio.newSineWave(660.0, 0.5, 44100, 0.3)
    lurek.audio.mixInto(a, b)
  end
end

--@api-stub: lurek.audio.saveWAV
-- Saves a SoundData as a 16-bit PCM WAV file at the given path.
-- Writes 16-bit PCM at the SoundData's sample rate; path is resolved relative to the game directory.
do  -- lurek.audio.saveWAV
  function lurek.init()
    local tone = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.audio.saveWAV(tone, "save/tone.wav")
  end
end

--@api-stub: lurek.audio.setStereoWidth
-- Sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono).
-- Width of 1.0 keeps the original stereo image; 0.0 collapses to mono; values above 1 widen.
do  -- lurek.audio.setStereoWidth
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setStereoWidth(music, 0.5)
    lurek.audio.play(music)
  end
end

--@api-stub: lurek.audio.getStereoWidth
-- Returns the current stereo width for a source.
-- Useful when implementing a per-source "focus" or "depth" slider in a settings menu.
do  -- lurek.audio.getStereoWidth
  function lurek.init()
    local music = lurek.audio.newSource("music/level.mp3")
    lurek.audio.setStereoWidth(music, 0.5)
    lurek.log.info("width=" .. lurek.audio.getStereoWidth(music), "audio")
  end
end

--@api-stub: lurek.audio.setRandomPitch
-- Sets a random pitch range applied each time the source is played.
-- Each `play` picks a random pitch in [min, max]; e.g. 0.95–1.05 for natural-sounding footstep variation.
do  -- lurek.audio.setRandomPitch
  function lurek.init()
    local foot = lurek.audio.newSource("sfx/footstep.ogg", "static")
    lurek.audio.setRandomPitch(foot, 0.95, 1.05)
    lurek.audio.play(foot)
  end
end

--@api-stub: lurek.audio.clearRandomPitch
-- Clears any random pitch range on a source, restoring fixed pitch.
-- Restores deterministic pitch — call before recording demos or running automated tests.
do  -- lurek.audio.clearRandomPitch
  function lurek.init()
    local foot = lurek.audio.newSource("sfx/footstep.ogg", "static")
    lurek.audio.setRandomPitch(foot, 0.95, 1.05)
    lurek.audio.clearRandomPitch(foot)
  end
end

--@api-stub: lurek.audio.crossfade
-- Crossfades from one source to another over a duration.
-- Fades `from` out and `to` in over `duration` seconds; both sources should already be created.
do  -- lurek.audio.crossfade
  function lurek.init()
    local a = lurek.audio.newSource("music/level1.mp3")
    local b = lurek.audio.newSource("music/level2.mp3")
    lurek.audio.play(a)
    lurek.audio.crossfade(a, b, 3.0)
  end
end

--@api-stub: lurek.audio.getBusPeak
-- Returns the peak signal level of the named bus (stub: always 0.0).
-- Peak level of the named bus in [0, 1] — drive a per-bus VU meter in your debug overlay.
do  -- lurek.audio.getBusPeak
  function lurek.init()
    lurek.audio.create_bus("music")
    local peak = lurek.audio.getBusPeak("music")
    lurek.log.info("music peak=" .. peak, "audio")
  end
end

--@api-stub: lurek.audio.getBusRms
-- Returns the RMS signal level of the named bus (stub: always 0.0).
-- Smoother than peak; better for slow-moving level meters and dynamic ducking thresholds.
do  -- lurek.audio.getBusRms
  function lurek.init()
    lurek.audio.create_bus("music")
    local rms = lurek.audio.getBusRms("music")
    lurek.log.info("music rms=" .. rms, "audio")
  end
end

--@api-stub: lurek.audio.newPool
-- Creates a polyphonic sound pool for the given file with N simultaneous voices.
-- Pre-allocates `voice_count` voices for one clip; call `pool:play()` for cheap polyphony.
do  -- lurek.audio.newPool
  function lurek.init()
    local foot = lurek.audio.newPool("sfx/footstep.ogg", 8)
    foot:setVolume(0.7)
    foot:play()
  end
end

--@api-stub: lurek.audio.processOffline
-- Applies a DSP effect chain to a WAV file and writes output.
-- Render a WAV with a chain of effects to disk; each entry is `{type=, p1=, p2=, p3=}` where p1/p2/p3 are floats.
do  -- lurek.audio.processOffline
  function lurek.init()
    local fx = {{type = "lowpass", p1 = 800.0, p2 = 1.0, p3 = 0.5}}
    lurek.audio.processOffline("music/in.wav", "save/out.wav", fx)
  end
end

--@api-stub: lurek.audio.normalizeFile
-- Normalizes a WAV file peak amplitude to target_level and writes output.
-- Peak-normalises an input WAV to `target_level` (0–1) and writes the result; preserves sample rate.
do  -- lurek.audio.normalizeFile
  function lurek.init()
    lurek.audio.normalizeFile("music/raw.wav", "save/normalised.wav", 0.95)
  end
end

--@api-stub: lurek.audio.waveformToPng
-- Renders the waveform of a WAV file to a PNG image.
-- Quick offline asset preview: dumps a width×height PNG of the waveform for use in a level editor.
do  -- lurek.audio.waveformToPng
  function lurek.init()
    lurek.audio.waveformToPng("music/level.wav", "save/level_wave.png", 800, 200)
  end
end

--@api-stub: lurek.audio.spectrogramToPng
-- Renders a time-frequency spectrogram of a WAV file to a PNG image.
-- Same idea as `waveformToPng` but renders an STFT magnitude image — useful for spotting audio glitches.
do  -- lurek.audio.spectrogramToPng
  function lurek.init()
    lurek.audio.spectrogramToPng("music/level.wav", "save/level_spec.png", 800, 400)
  end
end

-- ── Source methods ──

--@api-stub: LSource:play
-- Starts or resumes playback.
-- Method form is identical to `lurek.audio.play(src)` — pick whichever style your script favours.
do  -- Source:play
  function lurek.init()
    local s = lurek.audio.newSource("sfx/jump.ogg", "static")
    s:play()
  end
end

--@api-stub: LSource:stop
-- Stops playback and resets seek position.
-- Resets the playhead; use when the player cancels an action mid-cue (e.g. weapon swap).
do  -- Source:stop
  function lurek.init()
    local s = lurek.audio.newSource("sfx/laser.ogg", "static")
    s:play(); s:stop()
  end
end

--@api-stub: LSource:pause
-- Pauses playback at the current position.
-- Keeps the seek position so `:resume()` continues from the same sample frame.
do  -- Source:pause
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:play(); s:pause()
  end
end

--@api-stub: LSource:resume
-- Resumes playback from the paused position.
-- Pair with `:pause()` for in-game pause menus that don't restart cues.
do  -- Source:resume
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:play(); s:pause(); s:resume()
  end
end

--@api-stub: LSource:setVolume
-- Sets playback volume (0.0 = silent, 1.0 = full).
-- Linear 0–1 multiplier; combined multiplicatively with bus volume and master volume.
do  -- Source:setVolume
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:setVolume(0.7); s:play()
  end
end

--@api-stub: LSource:getVolume
-- Returns the current volume multiplier.
-- Save and restore per-source gain across application restarts to remember mixer state.
do  -- Source:getVolume
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:setVolume(0.7)
    lurek.log.info("vol=" .. s:getVolume(), "audio")
  end
end

--@api-stub: LSource:setPitch
-- Sets the pitch multiplier (1.0 = normal).
-- Pitch also alters duration; if you need length-preserving shifts, render offline with a phase vocoder.
do  -- Source:setPitch
  function lurek.init()
    local s = lurek.audio.newSource("sfx/engine.ogg", "static")
    s:setPitch(1.2); s:play()
  end
end

--@api-stub: LSource:getPitch
-- Returns the current pitch multiplier.
-- Read the current multiplier when chaining tweens that animate engine pitch over time.
do  -- Source:getPitch
  function lurek.init()
    local s = lurek.audio.newSource("sfx/engine.ogg", "static")
    s:setPitch(1.2)
    lurek.log.info("pitch=" .. s:getPitch(), "audio")
  end
end

--@api-stub: LSource:setLooping
-- Enables or disables looping playback.
-- Set before `:play()` for music; setting it on a clip already playing applies on the next loop point.
do  -- Source:setLooping
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:setLooping(true); s:play()
  end
end

--@api-stub: LSource:isLooping
-- Returns true if looping is enabled.
-- Branch in your save routine to skip persisting one-shot SFX flags.
do  -- Source:isLooping
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:setLooping(true)
    if s:isLooping() then lurek.log.info("looped", "audio") end
  end
end

--@api-stub: LSource:isPlaying
-- Returns true if currently playing.
-- Use to detect natural end-of-stream so you can chain the next track in a queue.
do  -- Source:isPlaying
  function lurek.init()
    local s = lurek.audio.newSource("music/sting.ogg", "static")
    s:play()
    if s:isPlaying() then lurek.log.info("active", "audio") end
  end
end

--@api-stub: LSource:isPaused
-- Returns true if playback is paused.
-- Distinguishes paused-but-positioned from fully stopped, which matters for resume UI.
do  -- Source:isPaused
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:play(); s:pause()
    if s:isPaused() then s:resume() end
  end
end

--@api-stub: LSource:isStopped
-- Returns true if playback has stopped.
-- Returns true when the playhead is at zero (after `:stop()` or natural end-of-stream).
do  -- Source:isStopped
  function lurek.init()
    local s = lurek.audio.newSource("sfx/jump.ogg", "static")
    s:play(); s:stop()
    if s:isStopped() then lurek.log.info("idle", "audio") end
  end
end

--@api-stub: LSource:setPan
-- Sets stereo panning (-1.0 left to 1.0 right).
-- Range -1 (left) to 1 (right). Apply each frame from `(emitter.x - listener.x) / range`.
do  -- Source:setPan
  function lurek.init()
    local s = lurek.audio.newSource("sfx/swoosh.ogg", "static")
    s:setPan(-0.5); s:play()
  end
end

--@api-stub: LSource:getPan
-- Returns the current stereo panning value.
-- Read back to keep a debug overlay in sync with computed pan values.
do  -- Source:getPan
  function lurek.init()
    local s = lurek.audio.newSource("sfx/swoosh.ogg", "static")
    s:setPan(-0.5)
    lurek.log.info("pan=" .. s:getPan(), "audio")
  end
end

--@api-stub: LSource:clone
-- Creates an independent copy of this source.
-- Cheap way to play overlapping copies of a static SFX without restarting the original.
do  -- Source:clone
  function lurek.init()
    local s = lurek.audio.newSource("sfx/hit.ogg", "static")
    local s2 = s:clone()
    s:play(); s2:play()
  end
end

--@api-stub: LSource:getType
-- Returns the source type ("static" or "stream").
-- Returns "static" for fully decoded clips and "stream" for on-the-fly decoders.
do  -- Source:getType
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    if s:getType() == "stream" then lurek.log.info("streamed", "audio") end
  end
end

--@api-stub: LSource:getDuration
-- Returns the total duration in seconds.
-- Total length in seconds — divide by `:tell()` for a 0-1 progress value.
do  -- Source:getDuration
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    lurek.log.info("len=" .. s:getDuration() .. "s", "audio")
  end
end

--@api-stub: LSource:tell
-- Returns the current playback position in seconds.
-- Read the current playhead each frame to drive a karaoke or rhythm-game cursor.
do  -- Source:tell
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:play()
    lurek.log.info("at=" .. s:tell(), "audio")
  end
end

--@api-stub: LSource:seek
-- Seeks to a time position in seconds.
-- Position is in seconds; clamp to `:getDuration()` before calling to avoid silent no-ops.
do  -- Source:seek
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:play(); s:seek(15.0)
  end
end

--@api-stub: LSource:setLowpass
-- Applies a low-pass filter at the given cutoff frequency.
-- Drop high frequencies for muffled effect — try 800 Hz for underwater, 3000 Hz for behind-walls.
do  -- Source:setLowpass
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:play(); s:setLowpass(800)
  end
end

--@api-stub: LSource:setHighpass
-- Applies a high-pass filter at the given cutoff frequency.
-- Strip rumble before mixing this source into a reverb bus — cleans up bass-heavy material.
do  -- Source:setHighpass
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:play(); s:setHighpass(200)
  end
end

--@api-stub: LSource:getLowpass
-- Returns the low-pass filter cutoff frequency.
-- Read the cutoff so an in-game UI can tween it back to 0 when the player surfaces.
do  -- Source:getLowpass
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:setLowpass(800)
    lurek.log.info("lpf=" .. s:getLowpass(), "audio")
  end
end

--@api-stub: LSource:getHighpass
-- Returns the high-pass filter cutoff frequency.
-- Mirror of `getLowpass`; together let you save and restore filter state on a per-source basis.
do  -- Source:getHighpass
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:setHighpass(200)
    lurek.log.info("hpf=" .. s:getHighpass(), "audio")
  end
end

--@api-stub: LSource:clearFilter
-- Removes any active filter from this source.
-- Clears both filters; cheaper than tweening cutoffs back to default values.
do  -- Source:clearFilter
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:setLowpass(800); s:clearFilter()
  end
end

--@api-stub: LSource:fadeIn
-- Fades in from silence over the given duration in seconds.
-- Schedules a 0→volume fade over `dur` seconds; call before `:play()` for a clean entry.
do  -- Source:fadeIn
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:fadeIn(2.5); s:play()
  end
end

--@api-stub: LSource:getFadeIn
-- Returns the current fade-in duration in seconds.
-- Read the configured fade duration when persisting cue settings to a save file.
do  -- Source:getFadeIn
  function lurek.init()
    local s = lurek.audio.newSource("music/level.mp3")
    s:fadeIn(2.5)
    lurek.log.info("fade=" .. s:getFadeIn(), "audio")
  end
end

-- ── Bus methods ──

--@api-stub: LBus:getName
-- Returns the unique name string assigned to this audio bus.
-- Returns the name passed to `newBus`; useful when iterating mixed bus collections.
do  -- Bus:getName
  function lurek.init()
    local b = lurek.audio.newBus("music")
    lurek.log.info("bus name=" .. b:getName(), "audio")
  end
end

--@api-stub: LBus:setVolume
-- Sets the volume for all sources on this bus.
-- Bus volume is multiplied with each source's own volume — drive a settings slider here.
do  -- Bus:setVolume
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:setVolume(0.7)
  end
end

--@api-stub: LBus:getVolume
-- Returns the current volume multiplier applied to all sources on this bus.
-- Read back the current bus gain to populate a settings menu on first open.
do  -- Bus:getVolume
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:setVolume(0.7)
    lurek.log.info("bus vol=" .. b:getVolume(), "audio")
  end
end

--@api-stub: LBus:setPitch
-- Sets the pitch multiplier for all sources on this bus.
-- Affects every source on the bus; use 0.85 for slow-motion, 1.15 for hectic combat moments.
do  -- Bus:setPitch
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:setPitch(0.85)
  end
end

--@api-stub: LBus:getPitch
-- Returns the bus pitch multiplier.
-- Inspect during a tween that interpolates pitch back to 1.0 over time.
do  -- Bus:getPitch
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:setPitch(0.85)
    lurek.log.info("bus pitch=" .. b:getPitch(), "audio")
  end
end

--@api-stub: LBus:pause
-- Pauses all sources on this bus.
-- Pause every source assigned to this bus in one call — handy for category-specific mute toggles.
do  -- Bus:pause
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:pause()
  end
end

--@api-stub: LBus:resume
-- Resumes all sources on this bus.
-- Mirrors `:pause()`; the engine remembers each source's playhead so resume is glitch-free.
do  -- Bus:resume
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:pause(); b:resume()
  end
end

--@api-stub: LBus:isPaused
-- Returns true if this bus is paused.
-- Read the bus state to keep a UI mute icon in sync with the mixer.
do  -- Bus:isPaused
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:pause()
    if b:isPaused() then lurek.log.info("bus muted", "audio") end
  end
end

--@api-stub: LBus:type
-- Returns the type name of this object.
-- Returns "Bus" — useful in generic mixer-state inspector code that walks userdata.
do  -- Bus:type
  function lurek.init()
    local b = lurek.audio.newBus("music")
    lurek.log.info("kind=" .. b:type(), "audio")
  end
end

--@api-stub: LBus:typeOf
-- Returns true if this object is of the given type.
-- Returns true for "Bus" or the catch-all "Object" — the love2d-style class hierarchy check.
do  -- Bus:typeOf
  function lurek.init()
    local b = lurek.audio.newBus("music")
    if b:typeOf("Bus") then lurek.log.info("is bus", "audio") end
  end
end

--@api-stub: LBus:clearDuck
-- Removes the ducking target from this bus, restoring the target bus.
-- Stops this bus from ducking another; pair with `:setDuckTarget` (not exposed through stub) at startup.
do  -- Bus:clearDuck
  function lurek.init()
    local b = lurek.audio.newBus("voice")
    b:clearDuck()
  end
end

--@api-stub: LBus:getPeak
-- Returns the average peak amplitude of all sources currently on this bus.
-- Returns the average peak across all sources on the bus — drive a per-bus VU meter.
do  -- Bus:getPeak
  function lurek.init()
    local b = lurek.audio.newBus("music")
    lurek.log.info("peak=" .. b:getPeak(), "audio")
  end
end

-- ── MidiPlayer methods ──

--@api-stub: LMidiPlayer:load
-- Loads a MIDI file from the given path.
-- Loads a `.mid` file from disk; pass an empty MidiPlayer (no path arg) when you intend to swap files.
do  -- MidiPlayer:load
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer()
    if mp:load("music/song.mid") then lurek.log.info("midi loaded", "audio") end
  end
end

--@api-stub: LMidiPlayer:loadData
-- Loads MIDI data from a Lua string.
-- Loads MIDI from an in-memory string — useful for procedurally generated sequences.
do  -- MidiPlayer:loadData
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer()
    local data = lurek.fs.read("music/song.mid")
    mp:loadData(data)
  end
end

--@api-stub: LMidiPlayer:isLoaded
-- Returns true if a MIDI sequence is loaded.
-- Branch before `:play()` to fall back to a recorded track when the MIDI is missing.
do  -- MidiPlayer:isLoaded
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    if mp:isLoaded() then mp:play() end
  end
end

--@api-stub: LMidiPlayer:getFilePath
-- Returns the file path of the loaded MIDI, or nil.
-- Returns the loaded file path (or nil) — log when debugging which song is currently active.
do  -- MidiPlayer:getFilePath
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    local path = mp:getFilePath()
    if path then lurek.log.info("midi=" .. path, "audio") end
  end
end

--@api-stub: LMidiPlayer:setSoundFont
-- Loads a SoundFont file into this player (stub).
-- Per-player SoundFont override; stub today, future versions will swap the synthesis bank.
do  -- MidiPlayer:setSoundFont
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setSoundFont("music/orchestra.sf2")
  end
end

--@api-stub: LMidiPlayer:getSoundFontPath
-- Returns the SoundFont file path, or nil (stub).
-- Returns the per-player SoundFont path (currently always nil); log to confirm wiring later.
do  -- MidiPlayer:getSoundFontPath
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    local sf = mp:getSoundFontPath()
    if sf then lurek.log.info("sf=" .. sf, "audio") end
  end
end

--@api-stub: LMidiPlayer:useDefaultSoundFont
-- Reverts to the built-in default SoundFont (stub).
-- Reverts to the engine's built-in GM bank; safe to call on every level start to undo overrides.
do  -- MidiPlayer:useDefaultSoundFont
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:useDefaultSoundFont()
  end
end

--@api-stub: LMidiPlayer:play
-- Starts or resumes MIDI sequence playback from the current position.
-- Starts or resumes from the current playhead; works only after `setMidiSoundFont` is configured.
do  -- MidiPlayer:play
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setLooping(true); mp:play()
  end
end

--@api-stub: LMidiPlayer:pause
-- Pauses the MIDI sequence at the current position; resume with `play()`.
-- Pauses without resetting; pair with `:play()` for an in-game pause menu.
do  -- MidiPlayer:pause
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play(); mp:pause()
  end
end

--@api-stub: LMidiPlayer:stop
-- Stops MIDI playback and resets the playhead to the beginning.
-- Stops and rewinds the playhead to bar 1, beat 1.
do  -- MidiPlayer:stop
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play(); mp:stop()
  end
end

--@api-stub: LMidiPlayer:isPlaying
-- Returns true if MIDI is currently playing.
-- Use to chain into the next sequence when the current one ends naturally.
do  -- MidiPlayer:isPlaying
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play()
    if mp:isPlaying() then lurek.log.info("midi active", "audio") end
  end
end

--@api-stub: LMidiPlayer:isPaused
-- Returns true if MIDI playback is paused.
-- Distinguishes paused from stopped — affects whether `:play()` resumes or restarts.
do  -- MidiPlayer:isPaused
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play(); mp:pause()
    if mp:isPaused() then mp:play() end
  end
end

--@api-stub: LMidiPlayer:seek
-- Seeks to a time position in seconds.
-- Time is in seconds; combine with `:getDuration()` to make percentage-based scrubbing.
do  -- MidiPlayer:seek
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play(); mp:seek(30.0)
  end
end

--@api-stub: LMidiPlayer:tell
-- Returns the current playback position in seconds.
-- Read each frame to drive a beat-synced visualiser overlaid on the game world.
do  -- MidiPlayer:tell
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play()
    lurek.log.info("midi at=" .. mp:tell(), "audio")
  end
end

--@api-stub: LMidiPlayer:getDuration
-- Returns the total MIDI duration in seconds.
-- Returns the full sequence length in seconds for progress bars or end-of-track triggers.
do  -- MidiPlayer:getDuration
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("midi len=" .. mp:getDuration(), "audio")
  end
end

--@api-stub: LMidiPlayer:setLooping
-- Enables or disables looping.
-- Toggle for menu music; off for cutscenes that should fall through to a follow-up cue.
do  -- MidiPlayer:setLooping
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setLooping(true)
  end
end

--@api-stub: LMidiPlayer:isLooping
-- Returns true if looping is enabled.
-- Read back to drive a UI checkbox in a music-debug panel.
do  -- MidiPlayer:isLooping
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setLooping(true)
    if mp:isLooping() then lurek.log.info("midi loop", "audio") end
  end
end

--@api-stub: LMidiPlayer:setVolume
-- Sets MIDI playback volume.
-- Independent of master and bus volumes; multiplied with both during synthesis.
do  -- MidiPlayer:setVolume
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setVolume(0.7)
  end
end

--@api-stub: LMidiPlayer:getVolume
-- Returns the current MIDI volume.
-- Read back the per-player gain when persisting mixer state to a save file.
do  -- MidiPlayer:getVolume
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setVolume(0.7)
    lurek.log.info("midi vol=" .. mp:getVolume(), "audio")
  end
end

--@api-stub: LMidiPlayer:setBus
-- Routes MIDI output through a bus (or nil to clear).
-- Routes synthesis output through a bus so MIDI can be ducked or filtered like any other source.
do  -- MidiPlayer:setBus
  function lurek.init()
    local b = lurek.audio.newBus("music")
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setBus(b)
  end
end

--@api-stub: LMidiPlayer:getBus
-- Returns the assigned bus, or nil.
-- Returns the routed Bus userdata (or nil); useful when reusing players across scenes with different mixes.
do  -- MidiPlayer:getBus
  function lurek.init()
    local b = lurek.audio.newBus("music")
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setBus(b)
    local cur = mp:getBus()
    if cur then lurek.log.info("bus=" .. cur:getName(), "audio") end
  end
end

--@api-stub: LMidiPlayer:setTempo
-- Sets playback tempo in BPM.
-- Tempo is BPM; internally stored as a scale of the file's original tempo.
do  -- MidiPlayer:setTempo
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setTempo(140)
  end
end

--@api-stub: LMidiPlayer:getTempo
-- Returns the current tempo in BPM.
-- Returns the current effective BPM; useful for syncing visuals to playback speed.
do  -- MidiPlayer:getTempo
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setTempo(140)
    lurek.log.info("bpm=" .. mp:getTempo(), "audio")
  end
end

--@api-stub: LMidiPlayer:getOriginalTempo
-- Returns the original MIDI file tempo in BPM.
-- Returns the BPM stored in the MIDI file header — the reference value for the tempo scale.
do  -- MidiPlayer:getOriginalTempo
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("orig bpm=" .. mp:getOriginalTempo(), "audio")
  end
end

--@api-stub: LMidiPlayer:setTempoScale
-- Sets the tempo scale factor (1.0 = original speed).
-- Multiplier on top of the file tempo — 0.5 plays half-speed, 2.0 doubles.
do  -- MidiPlayer:setTempoScale
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setTempoScale(0.85)
  end
end

--@api-stub: LMidiPlayer:getTempoScale
-- Returns the current tempo scale factor.
-- Read the current scale factor when chaining tempo tweens.
do  -- MidiPlayer:getTempoScale
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setTempoScale(0.85)
    lurek.log.info("scale=" .. mp:getTempoScale(), "audio")
  end
end

--@api-stub: LMidiPlayer:getTicksPerBeat
-- Returns the PPQ resolution from the MIDI header.
-- MIDI PPQ resolution — divide `:tell()` ticks by this to get beat positions.
do  -- MidiPlayer:getTicksPerBeat
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("ppq=" .. mp:getTicksPerBeat(), "audio")
  end
end

--@api-stub: LMidiPlayer:setChannelVolume
-- Sets volume for a MIDI channel (1-indexed).
-- Channels are 1-indexed (1-16); use to mix down a single instrument like the drums.
do  -- MidiPlayer:setChannelVolume
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setChannelVolume(10, 0.4)
  end
end

--@api-stub: LMidiPlayer:getChannelVolume
-- Returns the volume for a MIDI channel (1-indexed).
-- Read per-channel gain when restoring mixer state across save files.
do  -- MidiPlayer:getChannelVolume
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setChannelVolume(10, 0.4)
    lurek.log.info("ch10 vol=" .. mp:getChannelVolume(10), "audio")
  end
end

--@api-stub: LMidiPlayer:setChannelMuted
-- Mutes or unmutes a MIDI channel (1-indexed).
-- Mute a single MIDI channel — useful for letting players solo individual instruments in a music-room.
do  -- MidiPlayer:setChannelMuted
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setChannelMuted(10, true)
  end
end

--@api-stub: LMidiPlayer:isChannelMuted
-- Returns true if a MIDI channel is muted (1-indexed).
-- Branch when drawing a per-channel mute toggle in a music-debug overlay.
do  -- MidiPlayer:isChannelMuted
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setChannelMuted(10, true)
    if mp:isChannelMuted(10) then lurek.log.info("drums muted", "audio") end
  end
end

--@api-stub: LMidiPlayer:getChannelInstrument
-- Returns the GM instrument for a MIDI channel (1-indexed).
-- Returns the GM program (0-127) — drive a UI that shows instrument names per channel.
do  -- MidiPlayer:getChannelInstrument
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    local inst = mp:getChannelInstrument(1)
    lurek.log.info("ch1 prog=" .. inst, "audio")
  end
end

--@api-stub: LMidiPlayer:getChannelCount
-- Returns the number of MIDI channels.
-- Always 16 today; loop from 1..count when iterating channels in a UI.
do  -- MidiPlayer:getChannelCount
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("channels=" .. mp:getChannelCount(), "audio")
  end
end

--@api-stub: LMidiPlayer:soloChannel
-- Solos a MIDI channel (1-indexed).
-- Mutes every other channel — useful in a music-room demo where the player can isolate parts.
do  -- MidiPlayer:soloChannel
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:soloChannel(1)
  end
end

--@api-stub: LMidiPlayer:unsoloAll
-- Clears solo on all channels.
-- Counterpart to `soloChannel`; restores the full mix in one call.
do  -- MidiPlayer:unsoloAll
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:soloChannel(1); mp:unsoloAll()
  end
end

--@api-stub: LMidiPlayer:getTrackCount
-- Returns the number of tracks in the MIDI sequence.
-- Returns the number of MIDI tracks (often 1 per instrument in a multi-track export).
do  -- MidiPlayer:getTrackCount
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("tracks=" .. mp:getTrackCount(), "audio")
  end
end

--@api-stub: LMidiPlayer:getTrackName
-- Returns the name of a MIDI track (1-indexed), or nil.
-- Tracks are 1-indexed; nil means the file did not embed a name for that track.
do  -- MidiPlayer:getTrackName
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    local name = mp:getTrackName(1)
    if name then lurek.log.info("track1=" .. name, "audio") end
  end
end

--@api-stub: LMidiPlayer:setTrackMuted
-- Mutes or unmutes a track (1-indexed).
-- Mute by track instead of channel; handy when one track holds multi-instrument sections.
do  -- MidiPlayer:setTrackMuted
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setTrackMuted(2, true)
  end
end

--@api-stub: LMidiPlayer:isTrackMuted
-- Returns true if a track is muted (1-indexed).
-- Drive a per-track mute checkbox in a music editor; pair with `getTrackName` for labelling.
do  -- MidiPlayer:isTrackMuted
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setTrackMuted(2, true)
    if mp:isTrackMuted(2) then lurek.log.info("track2 muted", "audio") end
  end
end

--@api-stub: LMidiPlayer:getNoteCount
-- Returns the total note count in the MIDI sequence.
-- Total note-on events across all tracks; useful for difficulty estimation in rhythm games.
do  -- MidiPlayer:getNoteCount
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("notes=" .. mp:getNoteCount(), "audio")
  end
end

--@api-stub: LMidiPlayer:setOnNoteOn
-- Registers a note-on callback (stub).
-- Stub today — future versions will fire `cb(channel, note, velocity)` on each note-on event.
do  -- MidiPlayer:setOnNoteOn
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setOnNoteOn(function(ch, note) lurek.log.info("note " .. note, "audio") end)
  end
end

--@api-stub: LMidiPlayer:setOnNoteOff
-- Registers a note-off callback (stub).
-- Mirror of `setOnNoteOn`; receives the same arguments when a note ends.
do  -- MidiPlayer:setOnNoteOff
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setOnNoteOff(function(ch, note) lurek.log.info("off " .. note, "audio") end)
  end
end

--@api-stub: LMidiPlayer:setOnEnd
-- Registers a playback-end callback (stub).
-- Fires once when the sequence reaches the final tick — chain into the next song here.
do  -- MidiPlayer:setOnEnd
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setOnEnd(function() lurek.log.info("midi end", "audio") end)
  end
end

--@api-stub: LMidiPlayer:getSampleRate
-- Returns the PCM output sample rate in Hz.
-- PCM output rate in Hz (default 44100); informational unless you tap raw samples.
do  -- MidiPlayer:getSampleRate
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("rate=" .. mp:getSampleRate(), "audio")
  end
end

--@api-stub: LMidiPlayer:setSampleRate
-- Sets the PCM output sample rate in Hz (clamped 8000â€“192000).
-- Clamped to 8000–192000; lower for chiptune effects, higher for mastering output.
do  -- MidiPlayer:setSampleRate
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setSampleRate(48000)
  end
end

--@api-stub: LMidiPlayer:getChannels
-- Returns the PCM output channel count (1 = mono, 2 = stereo).
-- Returns 1 (mono) or 2 (stereo); affects how the synthesised PCM is mixed into the rodio sink.
do  -- MidiPlayer:getChannels
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("ch=" .. mp:getChannels(), "audio")
  end
end

--@api-stub: LMidiPlayer:setChannels
-- Sets the PCM output channel count (clamped 1â€“2).
-- Pass 1 for mono playback (saves bandwidth) or 2 for stereo (the default).
do  -- MidiPlayer:setChannels
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setChannels(2)
  end
end

--@api-stub: LMidiPlayer:type
-- Returns the type name of this object.
-- Returns the literal string "MidiPlayer"; useful in mixed-userdata inspection helpers.
do  -- MidiPlayer:type
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("kind=" .. mp:type(), "audio")
  end
end

--@api-stub: LMidiPlayer:typeOf
-- Returns true if this object is of the given type.
-- Returns true for "MidiPlayer" or "Object" — the love2d-style class hierarchy check.
do  -- MidiPlayer:typeOf
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    if mp:typeOf("MidiPlayer") then lurek.log.info("is midi", "audio") end
  end
end

-- ── SoundPool methods ──

--@api-stub: LSoundPool:play
-- Plays the next available voice and returns its SoundKey as an integer.
-- Returns the integer SoundKey of the next free voice — pass to `lurek.audio.setPan` etc. for variation.
do  -- SoundPool:play
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    local id = pool:play()
    lurek.log.info("voice=" .. id, "audio")
  end
end

--@api-stub: LSoundPool:stopAll
-- Stops all voices in this pool.
-- Stops every voice in the pool — call on level transition to avoid bleed-over.
do  -- SoundPool:stopAll
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    pool:play(); pool:stopAll()
  end
end

--@api-stub: LSoundPool:setVolume
-- Sets the volume for all voices in this pool.
-- Sets one volume for every voice in the pool (and for any voices created later).
do  -- SoundPool:setVolume
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    pool:setVolume(0.7)
  end
end

--@api-stub: LSoundPool:setBus
-- Routes all voices through the named bus.
-- Routes every voice through the named bus; pair with `lurek.audio.create_bus("sfx")` at startup.
do  -- SoundPool:setBus
  function lurek.init()
    lurek.audio.create_bus("sfx")
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    pool:setBus("sfx")
  end
end

--@api-stub: LSoundPool:release
-- Releases all voices from the mixer and invalidates this pool.
-- Frees every voice handle in the pool; the pool itself becomes unusable afterwards.
do  -- SoundPool:release
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    pool:release()
  end
end

--@api-stub: LSoundPool:getVoiceCount
-- Returns the total number of voices in this pool.
-- Returns the configured polyphony — log on startup to confirm pool sizing matches design intent.
do  -- SoundPool:getVoiceCount
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    lurek.log.info("voices=" .. pool:getVoiceCount(), "audio")
  end
end

--@api-stub: LSoundPool:type
-- Returns the type name of this object.
-- Returns the literal string "SoundPool"; useful in generic mixer-state inspector code.
do  -- SoundPool:type
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    lurek.log.info("kind=" .. pool:type(), "audio")
  end
end

--@api-stub: LSoundPool:typeOf
-- Returns true if the type name matches.
-- Returns true for "SoundPool" or the catch-all "Object".
do  -- SoundPool:typeOf
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    if pool:typeOf("SoundPool") then lurek.log.info("is pool", "audio") end
  end
end

-- ── Decoder methods ──

--@api-stub: LDecoder:decode
-- Decodes the next chunk of samples, or nil at EOF.
-- Returns a SoundData chunk (about `buffersize` samples) or nil at EOF — drive a streaming visualiser.
do  -- Decoder:decode
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    local chunk = dec:decode()
    if chunk then lurek.log.info("chunk samples=" .. chunk:getSampleCount(), "audio") end
  end
end

--@api-stub: LDecoder:getChannelCount
-- Returns the number of audio channels.
-- Returns 1 for mono streams, 2 for stereo — plan your visualiser bins accordingly.
do  -- Decoder:getChannelCount
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    lurek.log.info("ch=" .. dec:getChannelCount(), "audio")
  end
end

--@api-stub: LDecoder:getBitDepth
-- Returns the per-sample bit depth of this decoded audio stream.
-- Returns the per-sample bit depth (typically 16); use to size raw PCM buffers manually.
do  -- Decoder:getBitDepth
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    lurek.log.info("bd=" .. dec:getBitDepth(), "audio")
  end
end

--@api-stub: LDecoder:getSampleRate
-- Returns the sample rate in Hz.
-- Hz output rate; pair with `getChannelCount` when feeding samples into a custom DSP path.
do  -- Decoder:getSampleRate
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    lurek.log.info("rate=" .. dec:getSampleRate(), "audio")
  end
end

--@api-stub: LDecoder:getDuration
-- Returns the total duration in seconds.
-- Total stream length in seconds — drives a scrub bar above your custom decode loop.
do  -- Decoder:getDuration
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    lurek.log.info("len=" .. dec:getDuration(), "audio")
  end
end

--@api-stub: LDecoder:seek
-- Seeks to a time offset in seconds.
-- Offset in seconds; combine with `:rewind` and `:tell` for a manual streaming UI.
do  -- Decoder:seek
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    dec:seek(15.0)
  end
end

--@api-stub: LDecoder:rewind
-- Rewinds to the beginning.
-- Shortcut equivalent to `:seek(0)` — handy when a streaming visualiser loops.
do  -- Decoder:rewind
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    dec:seek(15.0); dec:rewind()
  end
end

--@api-stub: LDecoder:tell
-- Returns the current position in seconds.
-- Read each frame to drive the playhead in your custom-decode visualiser.
do  -- Decoder:tell
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    lurek.log.info("at=" .. dec:tell(), "audio")
  end
end

--@api-stub: LDecoder:isSeekable
-- Returns true if seeking is supported.
-- Some compressed streams forbid seeking; branch to disable scrub UI when the answer is false.
do  -- Decoder:isSeekable
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    if dec:isSeekable() then dec:seek(15.0) end
  end
end

--@api-stub: LDecoder:release
-- Releases the decoder (no-op).
-- No-op today (the decoder drops on GC) but call it explicitly to make ownership intent clear.
do  -- Decoder:release
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    dec:release()
  end
end

-- ── SoundData methods ──

--@api-stub: mlua:getSampleCount
-- Get the total number of samples.
-- Total sample frames; for stereo divide by 2 to get pairs.
do  -- mlua:getSampleCount
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.log.info("samples=" .. sd:getSampleCount(), "audio")
  end
end

--@api-stub: mlua:getSampleRate
-- Get the sample rate.
-- Hz at which the buffer was generated — mismatched rates cause pitch shifts when mixed.
do  -- mlua:getSampleRate
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.log.info("rate=" .. sd:getSampleRate(), "audio")
  end
end

--@api-stub: mlua:getChannelCount
-- Get the number of channels.
-- 1 for mono (synthesised waves), 2 for stereo (loaded files).
do  -- mlua:getChannelCount
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.log.info("ch=" .. sd:getChannelCount(), "audio")
  end
end

--@api-stub: mlua:getDuration
-- Get the audio duration in seconds.
-- Length in seconds = sample_count / (sample_rate * channels). Cheaper than recomputing.
do  -- mlua:getDuration
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.log.info("len=" .. sd:getDuration(), "audio")
  end
end

--@api-stub: mlua:getBitDepth
-- Get the bit depth.
-- Synthesised SoundData buffers use 32-bit float internally; loaded WAVs preserve their original depth.
do  -- mlua:getBitDepth
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.log.info("bd=" .. sd:getBitDepth(), "audio")
  end
end

--@api-stub: mlua:getSample
-- Get a specific sample by index.
-- Returns sample value in [-1, 1] at the given index; raises if the index is out of range.
do  -- mlua:getSample
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    local s = sd:getSample(0)
    lurek.log.info("first=" .. s, "audio")
  end
end

--@api-stub: mlua:setSample
-- Set a specific sample by index.
-- Writes one sample in place; useful for quick procedural edits before saving with `lurek.audio.saveWAV`.
do  -- mlua:setSample
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    sd:setSample(0, 0.0)
  end
end

--@api-stub: mlua (SoundData):drawWaveform
-- Renders the SoundData buffer as a waveform into an ImageData object.
-- Useful for visualising recorded audio or showing a UI waveform preview.
do  -- mlua (SoundData):drawWaveform
  function lurek.init()
    local sd = lurek.audio.newSoundData(44100, 44100, 16, 1)
    local img = lurek.image.newImageData(512, 64)
    sd:drawWaveform(img, 0, 0, 512, 64, 255, 255, 255, 255)
    lurek.log.info("waveform size: " .. img:getWidth(), "audio")
  end
end

--@api-stub: LMidiPlayer:setChannelInstrument
-- Sets the General MIDI program number (instrument) for a MIDI channel.
-- Channel 9 is drums by convention; all others use GM program numbers 1-128.
do  -- MidiPlayer:setChannelInstrument
  function lurek.init()
    local midi = lurek.audio.newMidiPlayer()
    midi:setChannelInstrument(0, 41)
    lurek.log.info("channel 0 instrument: " .. midi:getChannelInstrument(0), "audio")
  end
end

--@api-stub: LBus:setDuckTarget
-- Configures automatic ducking: when this bus is active, the target bus volume is reduced.
-- Pass the target bus name and a duck factor (0=silence, 1=no duck) and release time.
do  -- Bus:setDuckTarget
  function lurek.init()
    lurek.audio.newBus("music")
    lurek.audio.newBus("sfx")
    local sfxBus = lurek.audio.newBus("sfx_active")
    sfxBus:setDuckTarget("music", 0.3)
    lurek.log.info("duck target set", "audio")
  end
end

--@api-stub: mlua:drawWaveform
-- Renders the waveform of a SoundData object into an ImageData as a line chart.
-- Use to show audio visualisations in the game HUD or a level editor.
do  -- mlua:drawWaveform
  local ok, err = pcall(function()
    local sd = lurek.audio.newSoundData("music/loop.ogg", 44100)
    local img = lurek.image.newImageData(256, 64)
    sd:drawWaveform(img, 0, 0, 256, 64, 255, 255, 255, 255)
    lurek.log.info("waveform drawn", "audio")
  end)
  if not ok then lurek.log.info("drawWaveform: asset not available", "audio") end
end

-- =============================================================================
-- STUBS: 120 uncovered lurek.audio API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LDecoder methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDecoder:type -------------------------------------------------
--@api-stub: LDecoder:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do  -- LDecoder:type
  local decoder_obj = lurek.audio.newDecoder("assets/sound.ogg", 4096)
  local t = decoder_obj:type()
  lurek.log.info("LDecoder:type = " .. t, "audio")
end
--@api-stub: LDecoder:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do  -- LDecoder:typeOf
  local decoder_obj = lurek.audio.newDecoder("assets/sound.ogg", 4096)
  lurek.log.info("is LDecoder: " .. tostring(decoder_obj:typeOf("LDecoder")), "audio")
  lurek.log.info("is wrong: " .. tostring(decoder_obj:typeOf("Unknown")), "audio")
end
--@api-stub: LSoundData:getSampleCount
-- Get the total number of samples.
-- Use to calculate buffer length or iterate over waveform data.
do  -- LSoundData:getSampleCount
  local sd = lurek.audio.newSineWave(440, 1.0, 44100, 0.5)
  lurek.log.info("sample_count=" .. sd:getSampleCount(), "audio")
end
--@api-stub: LSoundData:getSampleRate
-- Returns the sample rate of this audio buffer in Hz (e.g. 44100 or 48000).
-- Use to compute time offsets or to validate compatibility before mixing.
do  -- LSoundData:getSampleRate
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)
  lurek.log.info("sample_rate=" .. sd:getSampleRate(), "audio")
end
--@api-stub: LSoundData:getChannelCount
-- Get the number of channels.
-- 1 = mono, 2 = stereo. Use to route mixing or panning logic.
do  -- LSoundData:getChannelCount
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)
  lurek.log.info("channels=" .. sd:getChannelCount(), "audio")
end
--@api-stub: LSoundData:getDuration
-- Get the audio duration in seconds.
-- Use to display progress bars or schedule timed events.
do  -- LSoundData:getDuration
  local sd = lurek.audio.newSineWave(440, 2.0, 44100, 0.5)
  lurek.log.info("duration=" .. sd:getDuration() .. "s", "audio")
end
--@api-stub: LSoundData:getBitDepth
-- Returns the bit depth of this audio buffer (typically 16 or 32 bits per sample).
-- Use to choose the right encoding path when exporting WAV data.
do  -- LSoundData:getBitDepth
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)
  lurek.log.info("bit_depth=" .. sd:getBitDepth(), "audio")
end
--@api-stub: LSoundData:getSample
-- Returns the sample value at the given channel and index.
-- Use to read a specific frame of waveform data for visualisation or analysis.
do  -- LSoundData:getSample
  local sd = lurek.audio.newSineWave(440, 1.0, 44100, 0.5)
  local s = sd:getSample(1, 0)   -- channel 1, frame 0
  lurek.log.info("sample[0]=" .. tostring(s), "audio")
end
--@api-stub: LSoundData:drawWaveform
-- Draws the waveform onto an ImageData buffer.
-- Use to render a waveform visualisation for an audio editor UI.
do  -- LSoundData:drawWaveform
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)
  local idata = lurek.image.newImageData(256, 64)
  sd:drawWaveform(idata, 0, 0, 0.0, 1.0, 0.5)   -- green waveform at (0,0)
  lurek.log.info("waveform drawn to image 256x64", "audio")
end
--@api-stub: LSoundData:setSample
-- Set a specific sample by index.
-- Use for custom synthesis or patching individual samples in a buffer.
do  -- LSoundData:setSample
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)
  sd:setSample(0, 1, 0.0)   -- silence first sample, channel 1
  lurek.log.info("sample[0] after zero=" .. sd:getSample(0, 1), "audio")
end
--@api-stub: LSource:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do  -- LSource:type
  local source_obj = lurek.audio.newSource()
  local t = source_obj:type()
  lurek.log.info("LSource:type = " .. t, "audio")
end
--@api-stub: LSource:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do  -- LSource:typeOf
  local source_obj = lurek.audio.newSource()
  lurek.log.info("is LSource: " .. tostring(source_obj:typeOf("LSource")), "audio")
  lurek.log.info("is wrong: " .. tostring(source_obj:typeOf("Unknown")), "audio")
end
