-- content/examples/audio.lua
-- lurek.audio API examples.
-- Run: cargo run -- content/examples/audio.lua

--@api-stub: lurek.audio.newSource
-- Creates a new audio source from a file path, either fully loaded or streaming
do
  function lurek.init()
    -- "static" loads the entire file into memory — best for short SFX that play often.
    -- Omitting the second arg (or "stream") streams from disk — best for music/long files.
    local ok_jump, jump = pcall(lurek.audio.newSource, "sfx/jump.ogg", "static")
    if not ok_jump then return end

    -- Streaming source for background music — low memory, reads file progressively.
    local music = lurek.audio.newSource("music/level.mp3")

    -- Loop the music so it repeats until explicitly stopped.
    lurek.audio.setLooping(music, true)
    lurek.audio.play(music)

    -- Store the SFX handle globally so lurek.update() or input callbacks can trigger it.
    _G.jump_sfx = jump
  end
end

--@api-stub: lurek.audio.play
-- Starts playback of a source by handle, optionally routing through a named bus
do
  function lurek.init()
    local ok_hit, hit = pcall(lurek.audio.newSource, "sfx/hit.ogg", "static")
    if not ok_hit then return end

    -- Create a bus for grouping all sound effects — lets you control SFX volume separately.
    lurek.audio.newBus("sfx")

    -- Route this source through the "sfx" bus. The bus applies its volume/effects to all
    -- sources assigned to it, so muting SFX for cutscenes is one call.
    lurek.audio.play(hit, {bus = "sfx"})
  end
end

--@api-stub: lurek.audio.stop
-- Stops playback of a source and resets its position to the beginning
do
  function lurek.init()
    local ok_sirene, sirene = pcall(lurek.audio.newSource, "sfx/alarm.ogg", "static")
    if not ok_sirene then return end

    lurek.audio.play(sirene)

    -- stop() halts playback and rewinds to 0. Next play() starts from the beginning.
    -- Use this when the player leaves a danger zone and the alarm should cut off.
    lurek.audio.stop(sirene)
  end
end

--@api-stub: lurek.audio.setVolume
-- Sets the volume of a source by handle
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    -- Volume is a multiplier: 0.0 = silent, 1.0 = full, values above 1.0 amplify.
    -- Set volume before play() so the source starts at the desired level.
    lurek.audio.setVolume(music, 0.7)
    lurek.audio.play(music)
  end
end

--@api-stub: lurek.audio.getVolume
-- Returns the current volume of a source
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.setVolume(music, 0.7)

    -- Useful for displaying volume in a HUD or gradually fading via lerp in update().
    local v = lurek.audio.getVolume(music)
    lurek.log.info("music volume=" .. v, "audio")
  end
end

--@api-stub: lurek.audio.pause
-- Pauses playback of a source at its current position
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)

    -- pause() remembers the current playback position. Use when opening a pause menu.
    lurek.audio.pause(music)
  end
end

--@api-stub: lurek.audio.resume
-- Resumes playback of a paused source
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)
    lurek.audio.pause(music)

    -- resume() continues from where pause() stopped — no audible glitch or restart.
    lurek.audio.resume(music)
  end
end

--@api-stub: lurek.audio.setPitch
-- Sets the pitch multiplier of a source, affecting playback speed and tone
do
  function lurek.init()
    local ok_engine, engine = pcall(lurek.audio.newSource, "sfx/engine.ogg", "static")
    if not ok_engine then return end

    -- Pitch 1.0 = normal. Higher values = faster and higher pitched.
    -- Game use: tie pitch to car speed (e.g. pitch = 0.8 + speed/max_speed * 0.7).
    lurek.audio.setPitch(engine, 1.25)
    lurek.audio.play(engine)
  end
end

--@api-stub: lurek.audio.getPitch
-- Returns the current pitch multiplier of a source
do
  function lurek.init()
    local ok_engine, engine = pcall(lurek.audio.newSource, "sfx/engine.ogg", "static")
    if not ok_engine then return end

    lurek.audio.setPitch(engine, 1.25)
    local p = lurek.audio.getPitch(engine)
    lurek.log.info("engine pitch=" .. p, "audio")
  end
end

--@api-stub: lurek.audio.isPlaying
-- Returns whether a source is currently playing
do
  function lurek.init()
    local ok_sting, sting = pcall(lurek.audio.newSource, "sfx/sting.ogg", "static")
    if not ok_sting then return end

    lurek.audio.play(sting)

    -- Check before triggering again to avoid overlapping the same one-shot SFX.
    if lurek.audio.isPlaying(sting) then
      lurek.log.info("sting active — skip duplicate play", "audio")
    end
  end
end

--@api-stub: lurek.audio.isPaused
-- Returns whether a source is currently paused
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)
    lurek.audio.pause(music)

    -- Useful for toggling pause/resume with a single key press.
    if lurek.audio.isPaused(music) then
      lurek.audio.resume(music)
    end
  end
end

--@api-stub: lurek.audio.isStopped
-- Returns whether a source is currently stopped
do
  function lurek.init()
    local ok_sting, sting = pcall(lurek.audio.newSource, "sfx/sting.ogg", "static")
    if not ok_sting then return end

    lurek.audio.play(sting)
    lurek.audio.stop(sting)

    -- isStopped returns true when the source finished naturally or was explicitly stopped.
    -- Use to detect when a one-shot sound ended so you can trigger the next event.
    if lurek.audio.isStopped(sting) then
      lurek.log.info("sting finished — voice slot free", "audio")
    end
  end
end

--@api-stub: lurek.audio.setLooping
-- Enables or disables looping for a source
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    -- Looping makes the source restart from sample 0 when it reaches the end.
    -- Essential for background music and ambient loops.
    lurek.audio.setLooping(music, true)
    lurek.audio.play(music)
  end
end

--@api-stub: lurek.audio.isLooping
-- Returns whether a source has looping enabled
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.setLooping(music, true)
    if lurek.audio.isLooping(music) then
      lurek.log.info("music will loop indefinitely", "audio")
    end
  end
end

--@api-stub: lurek.audio.playLooping
-- Starts playback of a source with looping enabled in one call
do
  function lurek.init()
    local ok_rain, rain = pcall(lurek.audio.newSource, "music/rain_loop.ogg")
    if not ok_rain then return end

    -- Convenience: sets looping AND starts playback in one call.
    -- Equivalent to setLooping(rain, true) followed by play(rain).
    lurek.audio.setVolume(rain, 0.7)
    lurek.audio.playLooping(rain)
  end
end

--@api-stub: lurek.audio.setPan
-- Sets the stereo panning of a source
do
  function lurek.init()
    local ok_sfx, sfx = pcall(lurek.audio.newSource, "sfx/swoosh.ogg", "static")
    if not ok_sfx then return end

    -- Pan: -1.0 = full left, 0.0 = center, 1.0 = full right.
    -- Use for simple left/right positional audio without full 3D spatial setup.
    lurek.audio.setPan(sfx, -0.5)
    lurek.audio.play(sfx)
  end
end

--@api-stub: lurek.audio.getPan
-- Returns the current stereo pan position of a source
do
  function lurek.init()
    local ok_sfx, sfx = pcall(lurek.audio.newSource, "sfx/swoosh.ogg", "static")
    if not ok_sfx then return end

    lurek.audio.setPan(sfx, -0.5)
    local p = lurek.audio.getPan(sfx)
    lurek.log.info("pan=" .. p, "audio")
  end
end

--@api-stub: lurek.audio.setMasterVolume
-- Sets the global master volume affecting all audio output
do
  function lurek.init()
    -- Master volume scales ALL sources and buses. Use it for a global volume slider
    -- in your options menu. Range: 0.0 (mute everything) to 1.0 (full output).
    local user_volume = 0.7
    lurek.audio.setMasterVolume(user_volume)
  end
end

--@api-stub: lurek.audio.getMasterVolume
-- Returns the current global master volume level
do
  function lurek.init()
    lurek.audio.setMasterVolume(0.7)
    local mv = lurek.audio.getMasterVolume()
    lurek.log.info("master=" .. mv, "audio")
  end
end

--@api-stub: lurek.audio.getActiveSourceCount
-- Returns the number of sources currently playing audio
do
  function lurek.init()
    local ok_sfx, sfx = pcall(lurek.audio.newSource, "sfx/jump.ogg", "static")
    if not ok_sfx then return end

    lurek.audio.play(sfx)

    -- Useful for debugging voice counts or limiting simultaneous sounds.
    lurek.log.info("active=" .. lurek.audio.getActiveSourceCount(), "audio")
  end
end

--@api-stub: lurek.audio.getSourceCount
-- Returns the total number of loaded audio sources (playing or idle)
do
  function lurek.init()
    local ok__, _ = pcall(lurek.audio.newSource, "sfx/coin.ogg", "static")
    if not ok__ then return end

    -- Includes all sources: playing, paused, and stopped but not yet released.
    local n = lurek.audio.getSourceCount()
    lurek.log.info("total loaded sources=" .. n, "audio")
  end
end

--@api-stub: lurek.audio.getSourceType
-- Returns whether a source is static or streaming
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    -- Returns "static" (fully in RAM) or "stream" (decoded progressively from disk).
    local t = lurek.audio.getSourceType(music)
    if t == "stream" then
      lurek.log.info("music is streamed — low memory use", "audio")
    end
  end
end

--@api-stub: lurek.audio.clone
-- Creates an independent copy of a source sharing the same audio data
do
  function lurek.init()
    local ok_hit, hit = pcall(lurek.audio.newSource, "sfx/hit.ogg", "static")
    if not ok_hit then return end

    -- clone() creates a new source with the same audio buffer but independent state.
    -- Use to play overlapping instances of the same SFX (e.g. rapid-fire gunshots).
    local hit2 = lurek.audio.clone(hit)
    lurek.audio.play(hit)
    lurek.audio.play(hit2)
  end
end

--@api-stub: lurek.audio.pauseAll
-- Pauses all currently playing audio sources
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)

    -- pauseAll() is ideal for a global pause menu — freezes every active source at once.
    lurek.audio.pauseAll()
  end
end

--@api-stub: lurek.audio.stopAll
-- Stops all audio sources and resets their positions
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)

    -- stopAll() when transitioning scenes — ensures no lingering audio from the old scene.
    lurek.audio.stopAll()
  end
end

--@api-stub: lurek.audio.resumeAll
-- Resumes all paused audio sources
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)
    lurek.audio.pauseAll()

    -- resumeAll() when closing the pause menu — restores all frozen audio.
    lurek.audio.resumeAll()
  end
end

--@api-stub: lurek.audio.release
-- Releases an audio source, freeing its memory and stopping playback
do
  function lurek.init()
    local ok_sfx, sfx = pcall(lurek.audio.newSource, "sfx/coin.ogg", "static")
    if not ok_sfx then return end

    lurek.audio.stop(sfx)

    -- release() frees the audio buffer memory. The handle becomes invalid after this.
    -- Use when you know a source will never play again (e.g. level-specific sounds on exit).
    lurek.audio.release(sfx)
  end
end

--@api-stub: lurek.audio.newBus
-- Creates a new audio mixing bus for grouping and controlling sources
do
  function lurek.init()
    -- Buses let you group sources (music, sfx, voice) and control them together.
    -- Great for volume sliders in options: one slider per bus.
    local sfx_bus = lurek.audio.newBus("sfx")
    sfx_bus:setVolume(0.7)
    lurek.log.info("bus=" .. sfx_bus:getName(), "audio")
  end
end

--@api-stub: lurek.audio.setSourceBus
-- Routes a source through a specific audio bus for grouped mixing
do
  function lurek.init()
    local voice_bus = lurek.audio.newBus("voice")
    local ok_line, line = pcall(lurek.audio.newSource, "voice/line01.ogg", "static")
    if not ok_line then return end

    -- After this call, the source's effective volume = source_vol * bus_vol * master_vol.
    -- Muting the bus silences all dialogue lines at once.
    lurek.audio.setSourceBus(line, voice_bus)
  end
end

--@api-stub: lurek.audio.getSourceBus
-- Returns the bus a source is routed through
do
  function lurek.init()
    local sfx_bus = lurek.audio.newBus("sfx")
    local ok_hit, hit = pcall(lurek.audio.newSource, "sfx/hit.ogg", "static")
    if not ok_hit then return end

    lurek.audio.setSourceBus(hit, sfx_bus)

    -- Returns the LBus object or nil if the source has no bus assignment.
    local b = lurek.audio.getSourceBus(hit)
    if b then lurek.log.info("routed through: " .. b:getName(), "audio") end
  end
end

--@api-stub: lurek.audio.getMaxSources
-- Returns the maximum number of simultaneous audio sources supported
do
  function lurek.init()
    -- Engine hard limit. Plan your sound budget accordingly — prioritize important sounds.
    local cap = lurek.audio.getMaxSources()
    lurek.log.info("max simultaneous voices=" .. cap, "audio")
  end
end

--@api-stub: lurek.audio.getDuration
-- Returns the total duration of a source in seconds
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    -- Useful for progress bars or scheduling events at specific track times.
    local d = lurek.audio.getDuration(music)
    lurek.log.info("track length=" .. d .. "s", "audio")
  end
end

--@api-stub: lurek.audio.tell
-- Returns the current playback position of a source in seconds
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)

    -- tell() returns how many seconds have played. Use for syncing game events to music.
    local pos = lurek.audio.tell(music)
    lurek.log.info("playback at=" .. pos .. "s", "audio")
  end
end

--@api-stub: lurek.audio.seek
-- Seeks a source to a specific position in seconds
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)

    -- Jump to 30 seconds in — useful for resuming from a save point or skipping intros.
    lurek.audio.seek(music, 30.0)
  end
end

--@api-stub: lurek.audio.setLowpass
-- Applies a lowpass filter to a source, attenuating high frequencies
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)

    -- Lowpass at 800 Hz makes audio sound muffled — like being underwater or behind a wall.
    -- Cutoff in Hz: frequencies above this are attenuated.
    lurek.audio.setLowpass(music, 800)
  end
end

--@api-stub: lurek.audio.setHighpass
-- Applies a highpass filter to a source, attenuating low frequencies
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.play(music)

    -- Highpass at 200 Hz removes bass rumble — simulates a tinny radio or phone speaker.
    lurek.audio.setHighpass(music, 200)
  end
end

--@api-stub: lurek.audio.getLowpass
-- Returns the current lowpass filter cutoff of a source
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.setLowpass(music, 800)
    lurek.log.info("lowpass cutoff=" .. lurek.audio.getLowpass(music) .. " Hz", "audio")
  end
end

--@api-stub: lurek.audio.getHighpass
-- Returns the current highpass filter cutoff of a source
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.setHighpass(music, 200)
    lurek.log.info("highpass cutoff=" .. lurek.audio.getHighpass(music) .. " Hz", "audio")
  end
end

--@api-stub: lurek.audio.clearFilter
-- Removes all frequency filters from a source
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.setLowpass(music, 800)

    -- clearFilter() removes both lowpass and highpass — restores full-frequency playback.
    -- Use when the player surfaces from underwater or exits a muffled room.
    lurek.audio.clearFilter(music)
  end
end

--@api-stub: lurek.audio.fadeIn
-- Sets the fade-in duration for a source so it ramps from silence on play
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    -- Set fade-in BEFORE calling play(). The source will ramp from 0 to its set volume
    -- over 2.5 seconds. Avoids abrupt audio starts between scenes.
    lurek.audio.fadeIn(music, 2.5)
    lurek.audio.play(music)
  end
end

--@api-stub: lurek.audio.getFadeIn
-- Returns the configured fade-in duration of a source
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.fadeIn(music, 2.5)
    lurek.log.info("fade-in duration=" .. lurek.audio.getFadeIn(music) .. "s", "audio")
  end
end

--@api-stub: lurek.audio.setListener2D
-- Sets the 2D listener position for spatial audio calculations
do
  function lurek.init()
    -- The listener is typically the camera or player position.
    -- Sources with setPosition will be panned/attenuated relative to this point.
    local cam_x, cam_y = 320.0, 240.0
    lurek.audio.setListener2D(cam_x, cam_y)
  end
end

--@api-stub: lurek.audio.getListener2D
-- Returns the current 2D listener position
do
  function lurek.init()
    lurek.audio.setListener2D(320.0, 240.0)
    local lx, ly = lurek.audio.getListener2D()
    lurek.log.info("listener at " .. lx .. ", " .. ly, "audio")
  end
end

--@api-stub: lurek.audio.setListener
-- Sets the 3D listener position for spatial audio (Z defaults to 0 for 2D games)
do
  function lurek.init()
    -- For 2D games, set Z to 0. The engine uses all three axes for distance calculations.
    lurek.audio.setListener(320.0, 240.0, 0.0)
  end
end

--@api-stub: lurek.audio.getListener
-- Returns the current 3D listener position
do
  function lurek.init()
    lurek.audio.setListener(320.0, 240.0, 0.0)
    local x, y, z = lurek.audio.getListener()
    lurek.log.info("listener 3D=" .. x .. "," .. y .. "," .. z, "audio")
  end
end

--@api-stub: lurek.audio.setPosition
-- Sets the 3D position of a source for spatial audio panning and attenuation
do
  function lurek.init()
    local ok_foot, foot = pcall(lurek.audio.newSource, "sfx/footstep.ogg", "static")
    if not ok_foot then return end

    -- Place the source at a world position. The engine calculates panning and volume
    -- based on distance from the listener using the active distance model.
    lurek.audio.setPosition(foot, 480.0, 240.0, 0.0)
    lurek.audio.play(foot)
  end
end

--@api-stub: lurek.audio.getPosition
-- Returns the 3D position of a source
do
  function lurek.init()
    local ok_foot, foot = pcall(lurek.audio.newSource, "sfx/footstep.ogg", "static")
    if not ok_foot then return end

    lurek.audio.setPosition(foot, 480.0, 240.0, 0.0)
    local x, y, z = lurek.audio.getPosition(foot)
    lurek.log.info("emitter at " .. x .. "," .. y .. "," .. z, "audio")
  end
end

--@api-stub: lurek.audio.setVelocity
-- Sets the velocity of a source for Doppler effect calculations
do
  function lurek.init()
    local ok_car, car = pcall(lurek.audio.newSource, "sfx/engine.ogg", "static")
    if not ok_car then return end

    -- Velocity is in units/second. Combined with Doppler scale, this causes pitch shift
    -- when the source moves toward or away from the listener (think passing car).
    lurek.audio.setVelocity(car, 60.0, 0.0, 0.0)
    lurek.audio.play(car)
  end
end

--@api-stub: lurek.audio.getVelocity
-- Returns the velocity vector of a source
do
  function lurek.init()
    local ok_car, car = pcall(lurek.audio.newSource, "sfx/engine.ogg", "static")
    if not ok_car then return end

    lurek.audio.setVelocity(car, 60.0, 0.0, 0.0)
    local vx, vy, vz = lurek.audio.getVelocity(car)
    lurek.log.info("velocity=" .. vx .. "," .. vy .. "," .. vz, "audio")
  end
end

--@api-stub: lurek.audio.setOrientation
-- Sets the orientation of a source using forward and up vectors
do
  function lurek.init()
    local ok_cone, cone = pcall(lurek.audio.newSource, "sfx/horn.ogg", "static")
    if not ok_cone then return end

    -- 6 floats: forward_x, forward_y, forward_z, up_x, up_y, up_z.
    -- Orientation matters for directional sources (cone attenuation).
    lurek.audio.setOrientation(cone, 0.0, 0.0, -1.0, 0.0, 1.0, 0.0)
    lurek.audio.play(cone)
  end
end

--@api-stub: lurek.audio.getOrientation
-- Returns the orientation vectors of a source
do
  function lurek.init()
    local ok_cone, cone = pcall(lurek.audio.newSource, "sfx/horn.ogg", "static")
    if not ok_cone then return end

    lurek.audio.setOrientation(cone, 0.0, 0.0, -1.0, 0.0, 1.0, 0.0)
    local fx, fy, fz, ux, uy, uz = lurek.audio.getOrientation(cone)
    lurek.log.info("forward=" .. fx .. "," .. fy .. "," .. fz, "audio")
  end
end

--@api-stub: lurek.audio.setDopplerScale
-- Sets the global Doppler effect intensity multiplier
do
  function lurek.init()
    -- 1.0 = realistic Doppler. 0.0 = disabled. Higher = exaggerated effect.
    -- Set once at game start based on your world scale.
    lurek.audio.setDopplerScale(1.0)
  end
end

--@api-stub: lurek.audio.getDopplerScale
-- Returns the current global Doppler effect scale
do
  function lurek.init()
    lurek.audio.setDopplerScale(1.5)
    lurek.log.info("doppler scale=" .. lurek.audio.getDopplerScale(), "audio")
  end
end

--@api-stub: lurek.audio.setDistanceModel
-- Sets the distance attenuation model for spatial audio
do
  function lurek.init()
    -- Available models: "linear", "inverse", "exponent".
    -- "linear" = predictable falloff. "inverse" = more natural. "exponent" = steep dropoff.
    lurek.audio.setDistanceModel("linear")
  end
end

--@api-stub: lurek.audio.getDistanceModel
-- Returns the current distance attenuation model name
do
  function lurek.init()
    lurek.audio.setDistanceModel("linear")
    lurek.log.info("distance model=" .. lurek.audio.getDistanceModel(), "audio")
  end
end

--@api-stub: lurek.audio.setMeter
-- Sets the master peak level for metering purposes
do
  function lurek.init()
    -- Used by VU meter displays. The engine tracks peak level internally;
    -- this lets you override it for testing UI without audio playing.
    lurek.audio.setMeter(0.7)
  end
end

--@api-stub: lurek.audio.getMeter
-- Returns the current master peak level for VU-meter displays
do
  function lurek.init()
    lurek.audio.setMeter(0.7)

    -- Read this each frame to drive a VU meter bar in your HUD.
    lurek.log.info("meter peak=" .. lurek.audio.getMeter(), "audio")
  end
end

--@api-stub: lurek.audio.newMidiPlayer
-- Creates a new MIDI player instance, optionally loading a file immediately
do
  function lurek.init()
    -- Pass a path to load immediately, or call :load() later.
    -- MIDI playback requires a SoundFont — see setMidiSoundFont().
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setLooping(true)
    mp:play()
  end
end

--@api-stub: lurek.audio.newSoundData
-- Creates a new SoundData object from a file path or blank buffer for procedural audio
do
  function lurek.init()
    -- Args: sample_count, sample_rate, channels.
    -- Creates a blank buffer you can fill with setSample() for procedural generation.
    local sd = lurek.audio.newSoundData(44100, 44100, 1)
    lurek.log.info("blank buffer samples=" .. sd:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.setMidiSoundFont
-- Sets the midi sound font for Lua scripts in this module
do
  function lurek.init()
    -- Must be called before MIDI playback. Points to a .sf2 file (General MIDI compatible).
    -- Without a SoundFont, MIDI notes will be silent.
    lurek.audio.setMidiSoundFont("music/gm.sf2")
  end
end

--@api-stub: lurek.audio.hasMidiSoundFont
-- Returns true if midi sound font for Lua scripts in this module
do
  function lurek.init()
    -- Check before playing MIDI to warn users if audio will be silent.
    if not lurek.audio.hasMidiSoundFont() then
      lurek.log.warn("no soundfont loaded — MIDI will be silent", "audio")
    end
  end
end

--@api-stub: lurek.audio.clearMidiSoundFont
-- Clears midi sound font for Lua scripts in this module
do
  function lurek.init()
    lurek.audio.setMidiSoundFont("music/gm.sf2")

    -- Unload the SoundFont to free memory when MIDI is no longer needed.
    lurek.audio.clearMidiSoundFont()
  end
end

--@api-stub: lurek.audio.newDecoder
-- Creates a streaming audio decoder for the given file
do
  function lurek.init()
    -- Args: file_path, buffer_size (samples per chunk).
    -- Use decoders for custom streaming or analysis — decodes PCM chunk by chunk.
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    lurek.log.info("decoder rate=" .. dec:getSampleRate() .. " Hz", "audio")
  end
end

--@api-stub: lurek.audio.newQueueableSource
-- Creates a new queueable audio source for streaming PCM data buffer by buffer
do
  function lurek.init()
    -- Args: sample_rate, bit_depth, channels, buffer_count.
    -- Queueable sources let you feed audio in real-time — perfect for procedural audio,
    -- network streaming, or custom synthesis where you generate samples each frame.
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    lurek.log.info("queueable source id=" .. qs, "audio")
  end
end

--@api-stub: lurek.audio.queueSource
-- Queues a decoded audio chunk for playback on a queueable source
do
  function lurek.init()
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)

    -- Generate a short tone and push it into the queue.
    -- The queueable source plays buffers in FIFO order, seamlessly concatenating them.
    local chunk = lurek.audio.newSineWave(440.0, 0.1, 44100, 0.5)
    lurek.audio.queueSource(qs, chunk)
  end
end

--@api-stub: lurek.audio.getFreeBufferCount
-- Returns the number of free (available) buffer slots on a queueable source
do
  function lurek.init()
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)

    -- Check free slots before queuing. If 0, the source is full — wait for playback to
    -- consume a buffer before pushing more.
    local free = lurek.audio.getFreeBufferCount(qs)
    lurek.log.info("free buffer slots=" .. free, "audio")
  end
end

--@api-stub: lurek.audio.playQueueable
-- Play queueable for Lua scripts in this module
do
  function lurek.init()
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    local chunk = lurek.audio.newSineWave(440.0, 0.5, 44100, 0.5)
    lurek.audio.queueSource(qs, chunk)

    -- Start playback of the queued buffers. Audio plays continuously as long as
    -- there are buffers in the queue.
    lurek.audio.playQueueable(qs)
  end
end

--@api-stub: lurek.audio.stopQueueable
-- Stop queueable for Lua scripts in this module
do
  function lurek.init()
    local qs = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    lurek.audio.playQueueable(qs)

    -- Stops playback and discards remaining queued buffers.
    lurek.audio.stopQueueable(qs)
  end
end

--@api-stub: lurek.audio.getPlaybackDevices
-- Returns the playback devices for Lua scripts in this module
do
  function lurek.init()
    -- Returns a list of available audio output device names (headphones, speakers, etc.).
    -- Use for a device selection dropdown in your options menu.
    local devs = lurek.audio.getPlaybackDevices()
    for i, name in ipairs(devs) do
      lurek.log.info(i .. ": " .. name, "audio")
    end
  end
end

--@api-stub: lurek.audio.getPlaybackDevice
-- Returns the playback device for Lua scripts in this module
do
  function lurek.init()
    local cur = lurek.audio.getPlaybackDevice()
    lurek.log.info("current output device=" .. cur, "audio")
  end
end

--@api-stub: lurek.audio.setPlaybackDevice
-- Sets the playback device for Lua scripts in this module
do
  function lurek.init()
    -- Switch audio output to a specific device by name.
    -- Get available names from getPlaybackDevices() first.
    local devs = lurek.audio.getPlaybackDevices()
    if devs[1] then lurek.audio.setPlaybackDevice(devs[1]) end
  end
end

--@api-stub: lurek.audio.create_bus
-- Create_bus for Lua scripts in this module
do
  function lurek.init()
    -- create_bus creates a named bus. Second arg is optional parent bus name.
    -- Parent-child relationships let you build a mixing hierarchy:
    -- master → music → ambient_music
    lurek.audio.create_bus("music")
    lurek.audio.create_bus("ambient", "music")
  end
end

--@api-stub: lurek.audio.set_bus_volume
-- Sets the volume of a named audio bus
do
  function lurek.init()
    lurek.audio.create_bus("music")

    -- Set volume by bus name. All sources routed to "music" will be scaled by this.
    lurek.audio.set_bus_volume("music", 0.7)
  end
end

--@api-stub: lurek.audio.add_effect
-- Adds an effect to a named audio bus and returns its effect ID
do
  function lurek.init()
    lurek.audio.create_bus("sfx")

    -- Add a lowpass effect to the entire SFX bus. Returns an ID for later removal.
    -- Effect types: "lowpass", "highpass", "bandpass", "gain", etc.
    -- The params table provides effect-specific settings.
    local id = lurek.audio.add_effect("sfx", "lowpass", {value = 1500.0})
    lurek.log.info("effect id=" .. tostring(id), "audio")
  end
end

--@api-stub: lurek.audio.remove_effect
-- Remove_effect for Lua scripts in this module
do
  function lurek.init()
    lurek.audio.create_bus("sfx")
    local id = lurek.audio.add_effect("sfx", "lowpass", {value = 1500.0})

    -- Remove the effect by bus name and effect ID when the player exits the muffled area.
    lurek.audio.remove_effect("sfx", id)
  end
end

--@api-stub: lurek.audio.set_effect_param
-- Set_effect_param for Lua scripts in this module
do
  function lurek.init()
    lurek.audio.create_bus("sfx")
    local id = lurek.audio.add_effect("sfx", "lowpass", {value = 1500.0})

    -- Modify a running effect parameter in real-time. Smoothly animate the cutoff
    -- in update() for gradual transitions (e.g. diving underwater).
    lurek.audio.set_effect_param("sfx", id, "cutoff", 800.0)
  end
end

--@api-stub: lurek.audio.newSineWave
-- Generates a sine wave as a `SoundData` buffer
do
  function lurek.init()
    -- Args: frequency_hz, duration_sec, sample_rate, amplitude (0.0-1.0).
    -- Sine waves produce a pure, clean tone — useful for UI beeps or test signals.
    local beep = lurek.audio.newSineWave(440.0, 0.25, 44100, 0.5)
    lurek.log.info("sine wave samples=" .. beep:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.newSquareWave
-- Generates a square wave as a `SoundData` buffer
do
  function lurek.init()
    -- Square waves have a harsh, buzzy timbre — think retro/chiptune sounds.
    local sq = lurek.audio.newSquareWave(220.0, 0.5, 44100, 0.5)
    lurek.log.info("square wave samples=" .. sq:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.newSawtoothWave
-- Generates a sawtooth wave as a `SoundData` buffer
do
  function lurek.init()
    -- Sawtooth waves are bright and rich in harmonics — good base for synth sounds.
    local saw = lurek.audio.newSawtoothWave(110.0, 1.0, 44100, 0.5)
    lurek.log.info("sawtooth duration=" .. saw:getDuration() .. "s", "audio")
  end
end

--@api-stub: lurek.audio.newTriangleWave
-- Generates a triangle wave as a `SoundData` buffer
do
  function lurek.init()
    -- Triangle waves are softer than square waves — suitable for flute-like tones.
    local tri = lurek.audio.newTriangleWave(330.0, 0.5, 44100, 0.5)
    lurek.log.info("triangle samples=" .. tri:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.newWhiteNoise
-- Generates white noise as a `SoundData` buffer using a deterministic seed
do
  function lurek.init()
    -- Args: duration_sec, sample_rate, amplitude, seed.
    -- Deterministic seed means identical output each run — good for reproducible SFX.
    -- White noise is useful for wind, static, explosions (with filters applied).
    local noise = lurek.audio.newWhiteNoise(0.5, 44100, 0.3, 12345)
    lurek.log.info("noise samples=" .. noise:getSampleCount(), "audio")
  end
end

--@api-stub: lurek.audio.applyLowpass
-- Applies a lowpass filter in-place to the sound data
do
  function lurek.init()
    local saw = lurek.audio.newSawtoothWave(110.0, 1.0, 44100, 0.5)

    -- Permanently modifies the buffer — removes frequencies above 800 Hz.
    -- Use for offline sound design: generate raw wave, then shape with filters.
    lurek.audio.applyLowpass(saw, 800.0)
  end
end

--@api-stub: lurek.audio.applyHighpass
-- Applies a highpass filter in-place to the sound data
do
  function lurek.init()
    local saw = lurek.audio.newSawtoothWave(110.0, 1.0, 44100, 0.5)

    -- Removes frequencies below 80 Hz — eliminates rumble and DC offset.
    lurek.audio.applyHighpass(saw, 80.0)
  end
end

--@api-stub: lurek.audio.applyBandpass
-- Applies a bandpass filter in-place to the sound data
do
  function lurek.init()
    local sd = lurek.audio.newWhiteNoise(0.5, 44100, 0.3, 1)

    -- Only keeps frequencies between low_hz and high_hz.
    -- Bandpass on noise = wind effect. 300-3400 Hz is telephone-quality bandwidth.
    lurek.audio.applyBandpass(sd, 300.0, 3400.0)
  end
end

--@api-stub: lurek.audio.applyGain
-- Applies a gain multiplier in-place to the sound data
do
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 0.25, 44100, 0.3)

    -- Multiplies every sample by 1.5. Values above 1.0 amplify, below 1.0 attenuate.
    -- Careful: amplifying can cause clipping if samples exceed -1.0 to 1.0 range.
    lurek.audio.applyGain(sd, 1.5)
  end
end

--@api-stub: lurek.audio.mixInto
-- Mixes the samples of `src` into `dest` in-place (both must have the same format)
do
  function lurek.init()
    -- Create two tones at different frequencies.
    local a = lurek.audio.newSineWave(440.0, 0.5, 44100, 0.3)
    local b = lurek.audio.newSineWave(660.0, 0.5, 44100, 0.3)

    -- Adds b's samples into a — creating a chord (A4 + E5).
    -- Both must have same sample_rate, channels, and length.
    lurek.audio.mixInto(a, b)
  end
end

--@api-stub: lurek.audio.saveWAV
-- Encodes the sound data as a WAV file and saves it to the given path (relative to game dir)
do
  function lurek.init()
    local tone = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)

    -- Export procedurally generated audio as a standard WAV file.
    -- Useful for offline sound generation or recording gameplay audio.
    lurek.audio.saveWAV(tone, "save/tone.wav")
  end
end

--@api-stub: lurek.audio.setStereoWidth
-- Sets the stereo width of an audio source (0
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    -- 0.0 = mono (center only), 1.0 = normal stereo, >1.0 = widened stereo.
    -- Narrowing stereo width helps important sounds cut through a busy mix.
    lurek.audio.setStereoWidth(music, 0.5)
    lurek.audio.play(music)
  end
end

--@api-stub: lurek.audio.getStereoWidth
-- Returns the current stereo width factor of an audio source
do
  function lurek.init()
    local ok_music, music = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_music then return end

    lurek.audio.setStereoWidth(music, 0.5)
    lurek.log.info("stereo width=" .. lurek.audio.getStereoWidth(music), "audio")
  end
end

--@api-stub: lurek.audio.setRandomPitch
-- Sets a random pitch range for a source; each play picks a random pitch between min and max
do
  function lurek.init()
    local ok_foot, foot = pcall(lurek.audio.newSource, "sfx/footstep.ogg", "static")
    if not ok_foot then return end

    -- Each time this source plays, pitch is randomly chosen between 0.95 and 1.05.
    -- Prevents repetitive SFX from sounding robotic (footsteps, gunshots, UI clicks).
    lurek.audio.setRandomPitch(foot, 0.95, 1.05)
    lurek.audio.play(foot)
  end
end

--@api-stub: lurek.audio.clearRandomPitch
-- Clears any random pitch range previously set on the source
do
  function lurek.init()
    local ok_foot, foot = pcall(lurek.audio.newSource, "sfx/footstep.ogg", "static")
    if not ok_foot then return end

    lurek.audio.setRandomPitch(foot, 0.95, 1.05)

    -- Restore fixed pitch behavior.
    lurek.audio.clearRandomPitch(foot)
  end
end

--@api-stub: lurek.audio.crossfade
-- Crossfades from one audio source to another over the given duration
do
  function lurek.init()
    local ok_a, a = pcall(lurek.audio.newSource, "music/level1.mp3")
    if not ok_a then return end
    local b = lurek.audio.newSource("music/level2.mp3")

    lurek.audio.play(a)

    -- Smoothly transitions from source a to source b over 3 seconds.
    -- Source a fades out while b fades in simultaneously — no silence gap.
    -- Use for seamless music transitions between game areas.
    lurek.audio.crossfade(a, b, 3.0)
  end
end

--@api-stub: lurek.audio.getBusPeak
-- Returns the peak amplitude of the named audio bus over the last processing frame
do
  function lurek.init()
    lurek.audio.create_bus("music")

    -- Peak = loudest sample in the last audio frame. Good for VU meters.
    -- Range: 0.0 (silent) to 1.0+ (clipping).
    local peak = lurek.audio.getBusPeak("music")
    lurek.log.info("music bus peak=" .. peak, "audio")
  end
end

--@api-stub: lurek.audio.getBusRms
-- Returns the RMS (root mean square) amplitude of the named audio bus over the last processing frame
do
  function lurek.init()
    lurek.audio.create_bus("music")

    -- RMS = average loudness over the frame. More stable than peak for visual meters.
    -- Use for beat detection or reactive visuals (compare RMS across frames).
    local rms = lurek.audio.getBusRms("music")
    lurek.log.info("music bus rms=" .. rms, "audio")
  end
end

--@api-stub: lurek.audio.newPool
-- Creates a polyphonic sound pool that allows the same audio file to play on multiple simultaneous voices
do
  function lurek.init()
    -- Args: file_path, voice_count.
    -- A pool pre-allocates N copies of the same sound. Calling pool:play() fires the next
    -- available voice in round-robin order — perfect for rapid-fire SFX without clone() calls.
    local foot = lurek.audio.newPool("sfx/footstep.ogg", 8)
    foot:setVolume(0.7)
    foot:play()
  end
end

--@api-stub: lurek.audio.processOffline
-- Processes an audio file offline through a chain of effects and writes the result to an output file
do
  function lurek.init()
    -- Each effect is a table: {type = "...", p1 = ..., p2 = ..., p3 = ...}.
    -- Processes the entire file at once (not real-time). Output is a new WAV file.
    -- Use for pre-baking effects: reverb tails, filtered ambient loops, etc.
    local fx = {{type = "lowpass", p1 = 800.0, p2 = 1.0, p3 = 0.5}}
    lurek.audio.processOffline("music/in.wav", "save/out.wav", fx)
  end
end

--@api-stub: lurek.audio.normalizeFile
-- Normalize file for Lua scripts in this module
do
  function lurek.init()
    -- Scales the audio so the peak reaches the target amplitude (0.95 = 95% of max).
    -- Useful for ensuring consistent volume across user-submitted audio assets.
    lurek.audio.normalizeFile("music/raw.wav", "save/normalised.wav", 0.95)
  end
end

--@api-stub: lurek.audio.waveformToPng
-- Waveform to png for Lua scripts in this module
do
  function lurek.init()
    -- Renders the audio waveform as a PNG image for debug/visualization.
    -- Args: input_path, output_png_path, width, height.
    lurek.audio.waveformToPng("music/level.wav", "save/level_wave.png", 800, 200)
  end
end

--@api-stub: lurek.audio.spectrogramToPng
-- Spectrogram to png for Lua scripts in this module
do
  function lurek.init()
    -- Renders a frequency-over-time spectrogram as PNG — great for audio debugging.
    -- Shows which frequencies are present at each time point.
    lurek.audio.spectrogramToPng("music/level.wav", "save/level_spec.png", 800, 400)
  end
end

-- Source methods

--@api-stub: Source:play
-- Starts playback of on this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "sfx/jump.ogg", "static")
    if not ok_s then return end

    -- OOP-style: call methods directly on the source object.
    -- Equivalent to lurek.audio.play(s).
    s:play()
  end
end

--@api-stub: Source:stop
-- Stops the current operation or playback on this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "sfx/laser.ogg", "static")
    if not ok_s then return end

    s:play()
    -- Stops and rewinds. Next s:play() starts from the beginning.
    s:stop()
  end
end

--@api-stub: Source:pause
-- Pauses the current operation or playback on this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:play()
    -- Freezes at current position. Use s:resume() to continue.
    s:pause()
  end
end

--@api-stub: Source:resume
-- Resumes a previously paused operation or playback on this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:play()
    s:pause()
    -- Continues from the paused position — seamless.
    s:resume()
  end
end

--@api-stub: Source:setVolume
-- Sets the volume of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    -- Method-style volume control. 0.0 = silent, 1.0 = full.
    s:setVolume(0.7)
    s:play()
  end
end

--@api-stub: Source:getVolume
-- Returns the volume of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:setVolume(0.7)
    lurek.log.info("vol=" .. s:getVolume(), "audio")
  end
end

--@api-stub: Source:setPitch
-- Sets the pitch of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "sfx/engine.ogg", "static")
    if not ok_s then return end

    -- Pitch > 1.0 = faster/higher, < 1.0 = slower/lower.
    s:setPitch(1.2)
    s:play()
  end
end

--@api-stub: Source:getPitch
-- Returns the pitch of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "sfx/engine.ogg", "static")
    if not ok_s then return end

    s:setPitch(1.2)
    lurek.log.info("pitch=" .. s:getPitch(), "audio")
  end
end

--@api-stub: Source:setLooping
-- Sets the looping of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:setLooping(true)
    s:play()
  end
end

--@api-stub: Source:isLooping
-- Returns true if this source looping.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:setLooping(true)
    if s:isLooping() then lurek.log.info("will loop", "audio") end
  end
end

--@api-stub: Source:isPlaying
-- Returns true if this source playing.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/sting.ogg", "static")
    if not ok_s then return end

    s:play()
    if s:isPlaying() then lurek.log.info("sting active", "audio") end
  end
end

--@api-stub: Source:isPaused
-- Returns true if this source paused.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:play()
    s:pause()
    if s:isPaused() then s:resume() end
  end
end

--@api-stub: Source:isStopped
-- Returns true if this source stopped.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "sfx/jump.ogg", "static")
    if not ok_s then return end

    s:play()
    s:stop()
    if s:isStopped() then lurek.log.info("source idle", "audio") end
  end
end

--@api-stub: Source:setPan
-- Sets the pan of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "sfx/swoosh.ogg", "static")
    if not ok_s then return end

    -- -1.0 = hard left, 0.0 = center, 1.0 = hard right.
    s:setPan(-0.5)
    s:play()
  end
end

--@api-stub: Source:getPan
-- Returns the pan of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "sfx/swoosh.ogg", "static")
    if not ok_s then return end

    s:setPan(-0.5)
    lurek.log.info("pan=" .. s:getPan(), "audio")
  end
end

--@api-stub: Source:clone
-- Performs the clone operation on this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "sfx/hit.ogg", "static")
    if not ok_s then return end

    -- Clone shares the audio buffer but has independent volume, pitch, and playback state.
    local s2 = s:clone()
    s:play()
    s2:play()
  end
end

--@api-stub: Source:getType
-- Returns the type of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    -- Returns "static" or "stream".
    if s:getType() == "stream" then lurek.log.info("streaming from disk", "audio") end
  end
end

--@api-stub: Source:getDuration
-- Returns the duration of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    lurek.log.info("track length=" .. s:getDuration() .. "s", "audio")
  end
end

--@api-stub: Source:tell
-- Performs the tell operation on this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:play()
    -- Returns current playback position in seconds.
    lurek.log.info("position=" .. s:tell() .. "s", "audio")
  end
end

--@api-stub: Source:seek
-- Performs the seek operation on this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:play()
    -- Jump to 15 seconds into the track.
    s:seek(15.0)
  end
end

--@api-stub: Source:setLowpass
-- Sets the lowpass of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:play()
    -- Muffles audio — good for underwater or behind-wall effects.
    s:setLowpass(800)
  end
end

--@api-stub: Source:setHighpass
-- Sets the highpass of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:play()
    -- Removes bass — simulates tinny speaker or radio.
    s:setHighpass(200)
  end
end

--@api-stub: Source:getLowpass
-- Returns the lowpass of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:setLowpass(800)
    lurek.log.info("lowpass=" .. s:getLowpass() .. " Hz", "audio")
  end
end

--@api-stub: Source:getHighpass
-- Returns the highpass of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:setHighpass(200)
    lurek.log.info("highpass=" .. s:getHighpass() .. " Hz", "audio")
  end
end

--@api-stub: Source:clearFilter
-- Clears all filter items from this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:setLowpass(800)
    -- Remove all filters — restore full frequency range.
    s:clearFilter()
  end
end

--@api-stub: Source:fadeIn
-- Performs the fade in operation on this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    -- Set before play: source ramps from silence over 2.5 seconds.
    s:fadeIn(2.5)
    s:play()
  end
end

--@api-stub: Source:getFadeIn
-- Returns the fade in of this source.
do
  function lurek.init()
    local ok_s, s = pcall(lurek.audio.newSource, "music/level.mp3")
    if not ok_s then return end

    s:fadeIn(2.5)
    lurek.log.info("fade-in=" .. s:getFadeIn() .. "s", "audio")
  end
end

-- Bus methods

--@api-stub: Bus:getName
-- Returns the name of this bus.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")
    lurek.log.info("bus name=" .. b:getName(), "audio")
  end
end

--@api-stub: Bus:setVolume
-- Sets the volume of this bus.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")

    -- All sources routed to this bus will be scaled by this volume.
    -- Combine with per-source volume for fine control.
    b:setVolume(0.7)
  end
end

--@api-stub: Bus:getVolume
-- Returns the volume of this bus.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:setVolume(0.7)
    lurek.log.info("bus vol=" .. b:getVolume(), "audio")
  end
end

--@api-stub: Bus:setPitch
-- Sets the pitch of this bus.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")

    -- Pitch-shift ALL sources on this bus. Useful for slow-motion effects (0.5 = half speed).
    b:setPitch(0.85)
  end
end

--@api-stub: Bus:getPitch
-- Returns the pitch of this bus.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:setPitch(0.85)
    lurek.log.info("bus pitch=" .. b:getPitch(), "audio")
  end
end

--@api-stub: Bus:pause
-- Pauses the current operation or playback on this bus.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")

    -- Pauses all sources routed through this bus.
    b:pause()
  end
end

--@api-stub: Bus:resume
-- Resumes a previously paused operation or playback on this bus.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:pause()

    -- Resumes all sources that were paused by this bus.
    b:resume()
  end
end

--@api-stub: Bus:isPaused
-- Returns true if this bus paused.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")
    b:pause()
    if b:isPaused() then lurek.log.info("music bus paused", "audio") end
  end
end

--@api-stub: Bus:type
-- Returns the Lua-visible type name string for this bus handle.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")

    -- Returns "LBus" — useful for type-checking in generic code.
    lurek.log.info("type=" .. b:type(), "audio")
  end
end

--@api-stub: Bus:typeOf
-- Returns true if this bus handle matches the given type name string.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")

    -- Accepts "LBus", "Bus", or "Object".
    if b:typeOf("Bus") then lurek.log.info("confirmed bus type", "audio") end
  end
end

--@api-stub: Bus:clearDuck
-- Clears all duck items from this bus.
do
  function lurek.init()
    local b = lurek.audio.newBus("voice")

    -- Remove any ducking configuration previously set with setDuckTarget().
    b:clearDuck()
  end
end

--@api-stub: Bus:getPeak
-- Returns the peak of this bus.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")

    -- Peak amplitude from 0.0 to 1.0 over the last processing frame.
    lurek.log.info("peak=" .. b:getPeak(), "audio")
  end
end

-- MidiPlayer methods

--@api-stub: MidiPlayer:load
-- Loads into this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer()

    -- Load a MIDI file after creation. Returns true on success.
    if mp:load("music/song.mid") then
      lurek.log.info("midi loaded successfully", "audio")
    end
  end
end

--@api-stub: MidiPlayer:loadData
-- Loads data into this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer()

    -- Load MIDI from raw binary data (e.g. read from a custom archive or network).
    local data = lurek.fs.read("music/song.mid")
    mp:loadData(data)
  end
end

--@api-stub: MidiPlayer:isLoaded
-- Returns true if this midi player loaded.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Always check before playback — the file might not exist.
    if mp:isLoaded() then mp:play() end
  end
end

--@api-stub: MidiPlayer:getFilePath
-- Returns the file path of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    local path = mp:getFilePath()
    if path then lurek.log.info("loaded midi=" .. path, "audio") end
  end
end

--@api-stub: MidiPlayer:setSoundFont
-- Sets the sound font of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Override the global SoundFont for this player instance.
    mp:setSoundFont("music/orchestra.sf2")
  end
end

--@api-stub: MidiPlayer:getSoundFontPath
-- Returns the sound font path of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    local sf = mp:getSoundFontPath()
    if sf then lurek.log.info("soundfont=" .. sf, "audio") end
  end
end

--@api-stub: MidiPlayer:useDefaultSoundFont
-- Performs the use default sound font operation on this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Revert to the engine's built-in default SoundFont.
    mp:useDefaultSoundFont()
  end
end

--@api-stub: MidiPlayer:play
-- Starts playback of on this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setLooping(true)

    -- Begins MIDI synthesis and audio output through the mixer.
    mp:play()
  end
end

--@api-stub: MidiPlayer:pause
-- Pauses the current operation or playback on this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play()

    -- Pauses at current position. All active notes are silenced.
    mp:pause()
  end
end

--@api-stub: MidiPlayer:stop
-- Stops the current operation or playback on this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play()

    -- Stops and rewinds to the beginning.
    mp:stop()
  end
end

--@api-stub: MidiPlayer:isPlaying
-- Returns true if this midi player playing.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play()
    if mp:isPlaying() then lurek.log.info("midi is active", "audio") end
  end
end

--@api-stub: MidiPlayer:isPaused
-- Returns true if this midi player paused.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play()
    mp:pause()
    if mp:isPaused() then mp:play() end
  end
end

--@api-stub: MidiPlayer:seek
-- Performs the seek operation on this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play()

    -- Jump to 30 seconds into the MIDI file.
    mp:seek(30.0)
  end
end

--@api-stub: MidiPlayer:tell
-- Performs the tell operation on this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:play()

    -- Returns the current playback position in seconds.
    lurek.log.info("midi position=" .. mp:tell() .. "s", "audio")
  end
end

--@api-stub: MidiPlayer:getDuration
-- Returns the duration of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("midi duration=" .. mp:getDuration() .. "s", "audio")
  end
end

--@api-stub: MidiPlayer:setLooping
-- Sets the looping of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Loop the MIDI — it restarts from the beginning when it ends.
    mp:setLooping(true)
  end
end

--@api-stub: MidiPlayer:isLooping
-- Returns true if this midi player looping.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setLooping(true)
    if mp:isLooping() then lurek.log.info("midi will loop", "audio") end
  end
end

--@api-stub: MidiPlayer:setVolume
-- Sets the volume of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Master volume for all MIDI synthesis output.
    mp:setVolume(0.7)
  end
end

--@api-stub: MidiPlayer:getVolume
-- Returns the volume of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setVolume(0.7)
    lurek.log.info("midi volume=" .. mp:getVolume(), "audio")
  end
end

--@api-stub: MidiPlayer:setBus
-- Sets the bus of this midi player.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Route MIDI output through the music bus for grouped volume control.
    mp:setBus(b)
  end
end

--@api-stub: MidiPlayer:getBus
-- Returns the bus of this midi player.
do
  function lurek.init()
    local b = lurek.audio.newBus("music")
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setBus(b)
    local cur = mp:getBus()
    if cur then lurek.log.info("midi bus=" .. cur:getName(), "audio") end
  end
end

--@api-stub: MidiPlayer:setTempo
-- Sets the tempo of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Override the MIDI file's tempo. Value is in BPM (beats per minute).
    mp:setTempo(140)
  end
end

--@api-stub: MidiPlayer:getTempo
-- Returns the tempo of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setTempo(140)
    lurek.log.info("bpm=" .. mp:getTempo(), "audio")
  end
end

--@api-stub: MidiPlayer:getOriginalTempo
-- Returns the original tempo of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- The tempo as authored in the MIDI file — before any setTempo/setTempoScale calls.
    lurek.log.info("original bpm=" .. mp:getOriginalTempo(), "audio")
  end
end

--@api-stub: MidiPlayer:setTempoScale
-- Sets the tempo scale of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Scale relative to original: 1.0 = normal, 0.5 = half speed, 2.0 = double speed.
    -- Easier than setTempo when you want relative changes.
    mp:setTempoScale(0.85)
  end
end

--@api-stub: MidiPlayer:getTempoScale
-- Returns the tempo scale of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setTempoScale(0.85)
    lurek.log.info("tempo scale=" .. mp:getTempoScale(), "audio")
  end
end

--@api-stub: MidiPlayer:getTicksPerBeat
-- Returns the ticks per beat of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- PPQN (Pulses Per Quarter Note) — the MIDI file's timing resolution.
    lurek.log.info("ppq=" .. mp:getTicksPerBeat(), "audio")
  end
end

--@api-stub: MidiPlayer:setChannelVolume
-- Sets the channel volume of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Channel 10 is typically drums in General MIDI. Lower its volume.
    mp:setChannelVolume(10, 0.4)
  end
end

--@api-stub: MidiPlayer:getChannelVolume
-- Returns the channel volume of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setChannelVolume(10, 0.4)
    lurek.log.info("drums vol=" .. mp:getChannelVolume(10), "audio")
  end
end

--@api-stub: MidiPlayer:setChannelMuted
-- Sets the channel muted of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Mute the drum channel for a quieter arrangement.
    mp:setChannelMuted(10, true)
  end
end

--@api-stub: MidiPlayer:isChannelMuted
-- Returns true if this midi player channel muted.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setChannelMuted(10, true)
    if mp:isChannelMuted(10) then lurek.log.info("drums muted", "audio") end
  end
end

--@api-stub: MidiPlayer:getChannelInstrument
-- Returns the channel instrument of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Returns the GM program number (0-127) assigned to channel 1.
    local inst = mp:getChannelInstrument(1)
    lurek.log.info("ch1 instrument=" .. inst, "audio")
  end
end

--@api-stub: MidiPlayer:getChannelCount
-- Returns the number of channel items in this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- How many of the 16 MIDI channels have note data.
    lurek.log.info("active channels=" .. mp:getChannelCount(), "audio")
  end
end

--@api-stub: MidiPlayer:soloChannel
-- Performs the solo channel operation on this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Solo channel 1 — mutes all other channels so you hear only this one.
    -- Useful for isolating instruments during development.
    mp:soloChannel(1)
  end
end

--@api-stub: MidiPlayer:unsoloAll
-- Performs the unsolo all operation on this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:soloChannel(1)

    -- Restore normal playback — all channels audible again.
    mp:unsoloAll()
  end
end

--@api-stub: MidiPlayer:getTrackCount
-- Returns the number of track items in this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("midi tracks=" .. mp:getTrackCount(), "audio")
  end
end

--@api-stub: MidiPlayer:getTrackName
-- Returns the track name of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Track names are metadata embedded in the MIDI file (e.g. "Piano", "Bass").
    local name = mp:getTrackName(1)
    if name then lurek.log.info("track 1=" .. name, "audio") end
  end
end

--@api-stub: MidiPlayer:setTrackMuted
-- Sets the track muted of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Mute track 2 (1-based index). Tracks can contain notes across multiple channels.
    mp:setTrackMuted(2, true)
  end
end

--@api-stub: MidiPlayer:isTrackMuted
-- Returns true if this midi player track muted.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    mp:setTrackMuted(2, true)
    if mp:isTrackMuted(2) then lurek.log.info("track 2 muted", "audio") end
  end
end

--@api-stub: MidiPlayer:getNoteCount
-- Returns the number of note items in this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Total note-on events in the file — useful for progress displays.
    lurek.log.info("total notes=" .. mp:getNoteCount(), "audio")
  end
end

--@api-stub: MidiPlayer:setOnNoteOn
-- Sets the on note on of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Callback fires for each MIDI note-on event. Use for rhythm games or visualizers.
    mp:setOnNoteOn(function(ch, note)
      lurek.log.info("note ON ch=" .. ch .. " note=" .. note, "audio")
    end)
  end
end

--@api-stub: MidiPlayer:setOnNoteOff
-- Sets the on note off of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Callback fires when a note is released.
    mp:setOnNoteOff(function(ch, note)
      lurek.log.info("note OFF ch=" .. ch .. " note=" .. note, "audio")
    end)
  end
end

--@api-stub: MidiPlayer:setOnEnd
-- Sets the on end of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Callback fires when MIDI playback reaches the end (if not looping).
    mp:setOnEnd(function()
      lurek.log.info("midi playback finished", "audio")
    end)
  end
end

--@api-stub: MidiPlayer:getSampleRate
-- Returns the sample rate of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- The synthesis output rate (default 44100 Hz).
    lurek.log.info("midi output rate=" .. mp:getSampleRate() .. " Hz", "audio")
  end
end

--@api-stub: MidiPlayer:setSampleRate
-- Sets the sample rate of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Change synthesis rate. Higher = better quality, more CPU.
    mp:setSampleRate(48000)
  end
end

--@api-stub: MidiPlayer:getChannels
-- Returns the channels of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Output audio channels: 1 = mono, 2 = stereo.
    lurek.log.info("output channels=" .. mp:getChannels(), "audio")
  end
end

--@api-stub: MidiPlayer:setChannels
-- Sets the channels of this midi player.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")

    -- Force stereo output.
    mp:setChannels(2)
  end
end

--@api-stub: MidiPlayer:type
-- Returns the Lua-visible type name string for this midi player handle.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    lurek.log.info("type=" .. mp:type(), "audio")
  end
end

--@api-stub: MidiPlayer:typeOf
-- Returns true if this midi player handle matches the given type name string.
do
  function lurek.init()
    local mp = lurek.audio.newMidiPlayer("music/song.mid")
    if mp:typeOf("MidiPlayer") then lurek.log.info("confirmed MidiPlayer", "audio") end
  end
end

-- SoundPool methods

--@api-stub: SoundPool:play
-- Starts playback of on this sound pool.
do
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)

    -- play() fires the next available voice in round-robin order.
    -- Returns the numeric source ID of the voice that started.
    local id = pool:play()
    lurek.log.info("voice id=" .. id, "audio")
  end
end

--@api-stub: SoundPool:stopAll
-- Stops the current operation or playback on this sound pool.
do
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    pool:play()

    -- Silences all active voices in the pool at once.
    pool:stopAll()
  end
end

--@api-stub: SoundPool:setVolume
-- Sets the volume of this sound pool.
do
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)

    -- Sets volume for ALL voices in the pool.
    pool:setVolume(0.7)
  end
end

--@api-stub: SoundPool:setBus
-- Sets the bus of this sound pool.
do
  function lurek.init()
    lurek.audio.create_bus("sfx")
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)

    -- Route all pool voices through the "sfx" bus.
    pool:setBus("sfx")
  end
end

--@api-stub: SoundPool:release
-- Performs the release operation on this sound pool.
do
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)

    -- Frees all voice slots and audio memory. Pool handle becomes invalid after this.
    pool:release()
  end
end

--@api-stub: SoundPool:getVoiceCount
-- Returns the number of voice items in this sound pool.
do
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)

    -- Returns the total number of pre-allocated voices (not just active ones).
    lurek.log.info("pool voices=" .. pool:getVoiceCount(), "audio")
  end
end

--@api-stub: SoundPool:type
-- Returns the Lua-visible type name string for this sound pool handle.
do
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    lurek.log.info("type=" .. pool:type(), "audio")
  end
end

--@api-stub: SoundPool:typeOf
-- Returns true if this sound pool handle matches the given type name string.
do
  function lurek.init()
    local pool = lurek.audio.newPool("sfx/footstep.ogg", 8)
    if pool:typeOf("SoundPool") then lurek.log.info("confirmed pool type", "audio") end
  end
end

-- Decoder methods

--@api-stub: Decoder:decode
-- Performs the decode operation on this decoder.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)

    -- Decodes the next chunk of PCM data. Returns SoundData or nil at end of stream.
    -- Call in a loop to process the entire file, or feed chunks to a queueable source.
    local chunk = dec:decode()
    if chunk then lurek.log.info("decoded " .. chunk:getSampleCount() .. " samples", "audio") end
  end
end

--@api-stub: Decoder:getChannelCount
-- Returns the number of channel items in this decoder.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)

    -- 1 = mono, 2 = stereo. Matches the source file's channel layout.
    lurek.log.info("decoder channels=" .. dec:getChannelCount(), "audio")
  end
end

--@api-stub: Decoder:getBitDepth
-- Returns the bit depth of this decoder.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)

    -- Typically 16 or 24 bits per sample.
    lurek.log.info("bit depth=" .. dec:getBitDepth(), "audio")
  end
end

--@api-stub: Decoder:getSampleRate
-- Returns the sample rate of this decoder.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    lurek.log.info("sample rate=" .. dec:getSampleRate() .. " Hz", "audio")
  end
end

--@api-stub: Decoder:getDuration
-- Returns the duration of this decoder.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    lurek.log.info("file duration=" .. dec:getDuration() .. "s", "audio")
  end
end

--@api-stub: Decoder:seek
-- Performs the seek operation on this decoder.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)

    -- Jump to 15 seconds. Next decode() returns data from this position.
    dec:seek(15.0)
  end
end

--@api-stub: Decoder:rewind
-- Performs the rewind operation on this decoder.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)
    dec:seek(15.0)

    -- Reset to the beginning. Useful for re-reading the file without recreating the decoder.
    dec:rewind()
  end
end

--@api-stub: Decoder:tell
-- Performs the tell operation on this decoder.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)

    -- Returns current read position in seconds.
    lurek.log.info("decoder at=" .. dec:tell() .. "s", "audio")
  end
end

--@api-stub: Decoder:isSeekable
-- Returns true if this decoder seekable.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)

    -- Some formats/sources may not support seeking. Check before calling seek().
    if dec:isSeekable() then dec:seek(15.0) end
  end
end

--@api-stub: Decoder:release
-- Performs the release operation on this decoder.
do
  function lurek.init()
    local dec = lurek.audio.newDecoder("music/long_track.ogg", 4096)

    -- Free decoder resources. Handle becomes invalid after this.
    dec:release()
  end
end

-- SoundData methods

--@api-stub: mlua:getSampleCount
-- Returns the number of sample items in this mlua.
do
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)

    -- Total number of individual samples in the buffer.
    -- For 1 second at 44100 Hz mono = 44100 samples.
    lurek.log.info("samples=" .. sd:getSampleCount(), "audio")
  end
end

--@api-stub: mlua:getSampleRate
-- Returns the sample rate of this mlua.
do
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.log.info("rate=" .. sd:getSampleRate() .. " Hz", "audio")
  end
end

--@api-stub: mlua:getChannelCount
-- Returns the number of channel items in this mlua.
do
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.log.info("channels=" .. sd:getChannelCount(), "audio")
  end
end

--@api-stub: mlua:getDuration
-- Returns the duration of this mlua.
do
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.log.info("duration=" .. sd:getDuration() .. "s", "audio")
  end
end

--@api-stub: mlua:getBitDepth
-- Returns the bit depth of this mlua.
do
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
    lurek.log.info("bit depth=" .. sd:getBitDepth(), "audio")
  end
end

--@api-stub: mlua:getSample
-- Returns the sample of this mlua.
do
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)

    -- Access individual samples by zero-based index.
    -- Sample values are in the range -1.0 to 1.0 (normalized float).
    local s = sd:getSample(0)
    lurek.log.info("sample[0]=" .. s, "audio")
  end
end

--@api-stub: mlua:setSample
-- Sets the sample of this mlua.
do
  function lurek.init()
    local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)

    -- Write a sample value at a specific index. Use for procedural audio generation
    -- or applying custom effects sample-by-sample.
    sd:setSample(0, 0.0)
  end
end

--@api-stub: LSoundData:type
-- Performs the mlua operation on this .
do
  function lurek.init()
    local sd = lurek.audio.newSoundData(44100, 44100, 1)
    local img = lurek.image.newImageData(512, 64)
    if sd and img then
      -- drawWaveform renders the audio buffer's waveform directly into an image buffer.
      -- Args: target_image, x, y, width, height, r, g, b, a.
      local ok_w = pcall(function() sd:drawWaveform(img, 0, 0, 512, 64, 255, 255, 255, 255) end)
      if ok_w then lurek.log.info("waveform rendered to " .. img:getWidth() .. "px", "audio") end
    end
  end
end

--@api-stub: MidiPlayer:setChannelInstrument
-- Sets the channel instrument of this midi player.
do
  function lurek.init()
    local midi = lurek.audio.newMidiPlayer()

    -- Change the GM instrument on channel 0. Program 41 = Violin.
    -- See General MIDI instrument table for program numbers.
    midi:setChannelInstrument(0, 41)
    lurek.log.info("ch0 instrument=" .. midi:getChannelInstrument(0), "audio")
  end
end

--@api-stub: Bus:setDuckTarget
-- Sets the duck target of this bus.
do
  function lurek.init()
    lurek.audio.newBus("music")
    lurek.audio.newBus("sfx")
    local sfxBus = lurek.audio.newBus("sfx_active")

    -- Ducking: when sfx_active bus has audio playing, automatically reduce the music
    -- bus to 30% volume. Common pattern: duck music during dialogue or important SFX.
    sfxBus:setDuckTarget("music", 0.3)
    lurek.log.info("duck target set: music will lower when sfx_active plays", "audio")
  end
end

--@api-stub: mlua:drawWaveform
-- Draws or renders this mlua to the current render target.
do
  local ok, err = pcall(function()
    local sd = lurek.audio.newSoundData("music/loop.ogg", 44100)
    local img = lurek.image.newImageData(256, 64)

    -- Render the waveform of a loaded audio file into an image for visualization.
    sd:drawWaveform(img, 0, 0, 256, 64, 255, 255, 255, 255)
    lurek.log.info("waveform drawn to image", "audio")
  end)
  if not ok then lurek.log.info("drawWaveform: asset not available", "audio") end
end

-- -----------------------------------------------------------------------------
-- LDecoder methods
-- -----------------------------------------------------------------------------

--@api-stub: LDecoder:type
-- Returns the type name of this object for runtime type-checking
do
  local decoder_obj ---@type LDecoder?
  local ok_d, r = pcall(lurek.audio.newDecoder, "assets/sound.ogg", 4096)
  if ok_d then decoder_obj = r end

  -- Returns "LDecoder" — use for runtime type checks in generic systems.
  local t = decoder_obj and decoder_obj:type() or "LDecoder"
  lurek.log.info("LDecoder:type = " .. t, "audio")
end
--@api-stub: LDecoder:typeOf
-- Checks whether this object matches the given type name
do
  local decoder_obj2 ---@type LDecoder?
  local ok_d2, r2 = pcall(lurek.audio.newDecoder, "assets/sound.ogg", 4096)
  if ok_d2 then decoder_obj2 = r2 end

  -- typeOf checks against "LDecoder", "Decoder", or "Object".
  lurek.log.info("is LDecoder: " .. tostring(decoder_obj2 and decoder_obj2:typeOf("LDecoder") or false), "audio")
  lurek.log.info("is wrong: " .. tostring(decoder_obj2 and decoder_obj2:typeOf("Unknown") or false), "audio")
end
--@api-stub: LSoundData:getSampleCount
-- Returns the total number of samples stored in this sound buffer
do
  local sd = lurek.audio.newSineWave(440, 1.0, 44100, 0.5)
  lurek.log.info("sample_count=" .. sd:getSampleCount(), "audio")
end
--@api-stub: LSoundData:getSampleRate
-- Returns the playback sample rate of this sound buffer
do
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)
  lurek.log.info("sample_rate=" .. sd:getSampleRate(), "audio")
end
--@api-stub: LSoundData:getChannelCount
-- Returns the number of audio channels stored in this sound buffer
do
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)
  lurek.log.info("channels=" .. sd:getChannelCount(), "audio")
end
--@api-stub: LSoundData:getDuration
-- Returns the approximate playback duration of this sound buffer
do
  local sd = lurek.audio.newSineWave(440, 2.0, 44100, 0.5)
  lurek.log.info("duration=" .. sd:getDuration() .. "s", "audio")
end
--@api-stub: LSoundData:getBitDepth
-- Returns the sample bit depth of this sound buffer
do
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)
  lurek.log.info("bit_depth=" .. sd:getBitDepth(), "audio")
end
--@api-stub: LSoundData:getSample
-- Returns the sample value at the given zero-based sample index
do
  local sd = lurek.audio.newSineWave(440, 1.0, 44100, 0.5)

  -- Zero-based index. Returns normalized float value (-1.0 to 1.0).
  local s = sd:getSample(1)
  lurek.log.info("sample[1]=" .. tostring(s), "audio")
end
--@api-stub: LSoundData:drawWaveform
-- Draws this sound buffer as a waveform into an image buffer
do
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)
  local idata = lurek.image.newImageData(256, 64)

  -- Render a green waveform at position (0,0) with size 256x64 pixels.
  -- Useful for audio editors, level meters, or debug visualization.
  sd:drawWaveform(idata, 0, 0, 256, 64, 0, 255, 0, 255)
  lurek.log.info("waveform drawn to image 256x64", "audio")
end
--@api-stub: LSoundData:setSample
-- Overwrites the sample value at the given zero-based sample index
do
  local sd = lurek.audio.newSineWave(440, 0.5, 44100, 0.5)

  -- Zero out the first sample — direct buffer manipulation for procedural audio.
  sd:setSample(0, 0.0)
  lurek.log.info("sample[0] after zero=" .. sd:getSample(0), "audio")
end
--@api-stub: LSource:type
-- Returns the type name of this object for runtime type-checking
do
  local ok_s, source_obj = pcall(lurek.audio.newSource)

  -- Returns "LSource" for type identification in generic collections.
  local t = (ok_s and source_obj) and source_obj:type() or "LSource"
  lurek.log.info("LSource:type = " .. t, "audio")
end
--@api-stub: LSource:typeOf
-- Checks whether this object is of the given type name or a parent type
do
  local ok_s, source_obj = pcall(lurek.audio.newSource)

  -- Accepts "LSource", "Source", or "Object".
  lurek.log.info("is LSource: " .. tostring((ok_s and source_obj) and source_obj:typeOf("LSource") or false), "audio")
  lurek.log.info("is wrong: " .. tostring((ok_s and source_obj) and source_obj:typeOf("Unknown") or false), "audio")
end

print("content/examples/audio.lua")

-- =============================================================================
-- STUBS: 109 uncovered lurek.audio API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LBus methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBus:getName --------------------------------------------------
--@api-stub: LBus:getName
-- Returns the name of this audio bus. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:getName()  -- -> string
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:setVolume ------------------------------------------------
--@api-stub: LBus:setVolume
-- Sets the volume multiplier for all sources routed through this bus.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:setVolume(vol)
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:getVolume ------------------------------------------------
--@api-stub: LBus:getVolume
-- Returns the current volume multiplier of this bus.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:getVolume()  -- -> number
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:setPitch -------------------------------------------------
--@api-stub: LBus:setPitch
-- Sets the pitch multiplier applied to all sources routed through this bus.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:setPitch(pitch)
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:getPitch -------------------------------------------------
--@api-stub: LBus:getPitch
-- Returns the current pitch multiplier of this bus.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:getPitch()  -- -> number
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:pause ----------------------------------------------------
--@api-stub: LBus:pause
-- Pauses all sources routed through this bus.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:pause()
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:resume ---------------------------------------------------
--@api-stub: LBus:resume
-- Resumes all sources routed through this bus that were paused.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:resume()
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:isPaused -------------------------------------------------
--@api-stub: LBus:isPaused
-- Returns whether this bus is currently paused.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:isPaused()  -- -> boolean
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:type -----------------------------------------------------
--@api-stub: LBus:type
-- Returns the type name of this object for runtime type-checking.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:type()  -- -> string
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:typeOf ---------------------------------------------------
--@api-stub: LBus:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:typeOf("hero")  -- -> boolean
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:setDuckTarget --------------------------------------------
--@api-stub: LBus:setDuckTarget
-- Configures ducking so this bus lowers the volume of a target bus when active.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:setDuckTarget(target_name, duck_vol)
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:clearDuck ------------------------------------------------
--@api-stub: LBus:clearDuck
-- Removes the ducking configuration from this bus.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:clearDuck()
-- (replace lBus_stub with your real LBus instance above)

-- ---- Stub: LBus:getPeak --------------------------------------------------
--@api-stub: LBus:getPeak
-- Returns the current peak amplitude level of this bus for VU-meter displays.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBus_stub:getPeak()  -- -> number
-- (replace lBus_stub with your real LBus instance above)

-- -----------------------------------------------------------------------------
-- LDecoder methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDecoder:decode -----------------------------------------------
--@api-stub: LDecoder:decode
-- Decodes the next chunk of audio data and returns it as a LSoundData object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:decode()  -- -> LSoundData
-- (replace lDecoder_stub with your real LDecoder instance above)

-- ---- Stub: LDecoder:getChannelCount --------------------------------------
--@api-stub: LDecoder:getChannelCount
-- Returns the number of audio channels in the source file.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:getChannelCount()  -- -> integer
-- (replace lDecoder_stub with your real LDecoder instance above)

-- ---- Stub: LDecoder:getBitDepth ------------------------------------------
--@api-stub: LDecoder:getBitDepth
-- Returns the bit depth of the source audio file.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:getBitDepth()  -- -> integer
-- (replace lDecoder_stub with your real LDecoder instance above)

-- ---- Stub: LDecoder:getSampleRate ----------------------------------------
--@api-stub: LDecoder:getSampleRate
-- Returns the sample rate of the source audio file.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:getSampleRate()  -- -> integer
-- (replace lDecoder_stub with your real LDecoder instance above)

-- ---- Stub: LDecoder:getDuration ------------------------------------------
--@api-stub: LDecoder:getDuration
-- Returns the total duration of the source audio file in seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:getDuration()  -- -> number
-- (replace lDecoder_stub with your real LDecoder instance above)

-- ---- Stub: LDecoder:seek -------------------------------------------------
--@api-stub: LDecoder:seek
-- Seeks to a specific position in the audio stream.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:seek(offset)
-- (replace lDecoder_stub with your real LDecoder instance above)

-- ---- Stub: LDecoder:rewind -----------------------------------------------
--@api-stub: LDecoder:rewind
-- Rewinds the decoder back to the beginning of the audio stream.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:rewind()
-- (replace lDecoder_stub with your real LDecoder instance above)

-- ---- Stub: LDecoder:tell -------------------------------------------------
--@api-stub: LDecoder:tell
-- Returns the current read position in the audio stream in seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:tell()  -- -> number
-- (replace lDecoder_stub with your real LDecoder instance above)

-- ---- Stub: LDecoder:isSeekable -------------------------------------------
--@api-stub: LDecoder:isSeekable
-- Returns whether this decoder supports seeking.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:isSeekable()  -- -> boolean
-- (replace lDecoder_stub with your real LDecoder instance above)

-- ---- Stub: LDecoder:release ----------------------------------------------
--@api-stub: LDecoder:release
-- Releases decoder resources (no-op, kept for API symmetry).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDecoder_stub:release()
-- (replace lDecoder_stub with your real LDecoder instance above)

-- -----------------------------------------------------------------------------
-- LMidiPlayer methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMidiPlayer:load ----------------------------------------------
--@api-stub: LMidiPlayer:load
-- Loads a MIDI file from the given path relative to the game directory.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:load("assets/hero.png")  -- -> boolean
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:loadData ------------------------------------------
--@api-stub: LMidiPlayer:loadData
-- Loads MIDI data from a raw byte string in memory.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:loadData()  -- -> boolean
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:isLoaded ------------------------------------------
--@api-stub: LMidiPlayer:isLoaded
-- Returns whether a MIDI file is currently loaded and ready to play.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:isLoaded()  -- -> boolean
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getFilePath ---------------------------------------
--@api-stub: LMidiPlayer:getFilePath
-- Returns the file path of the currently loaded MIDI file.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getFilePath()  -- -> string
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setSoundFont --------------------------------------
--@api-stub: LMidiPlayer:setSoundFont
-- Sets a custom SoundFont file for MIDI synthesis (stub, not yet implemented).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setSoundFont("assets/hero.png")
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getSoundFontPath ----------------------------------
--@api-stub: LMidiPlayer:getSoundFontPath
-- Returns the path of the currently set SoundFont (stub, not yet implemented).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getSoundFontPath()  -- -> string
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:useDefaultSoundFont -------------------------------
--@api-stub: LMidiPlayer:useDefaultSoundFont
-- Reverts to the built-in default SoundFont (stub, not yet implemented).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:useDefaultSoundFont()
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:play ----------------------------------------------
--@api-stub: LMidiPlayer:play
-- Starts MIDI playback from the current position using the audio output stream.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:play()
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:pause ---------------------------------------------
--@api-stub: LMidiPlayer:pause
-- Pauses MIDI playback at the current position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:pause()
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:stop ----------------------------------------------
--@api-stub: LMidiPlayer:stop
-- Stops MIDI playback and resets position to the beginning.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:stop()
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:isPlaying -----------------------------------------
--@api-stub: LMidiPlayer:isPlaying
-- Returns whether the MIDI player is currently playing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:isPlaying()  -- -> boolean
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:isPaused ------------------------------------------
--@api-stub: LMidiPlayer:isPaused
-- Returns whether the MIDI player is currently paused.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:isPaused()  -- -> boolean
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:seek ----------------------------------------------
--@api-stub: LMidiPlayer:seek
-- Seeks to a specific position in the MIDI file.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:seek(secs)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:tell ----------------------------------------------
--@api-stub: LMidiPlayer:tell
-- Returns the current playback position of the MIDI player in seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:tell()  -- -> number
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getDuration ---------------------------------------
--@api-stub: LMidiPlayer:getDuration
-- Returns the total duration of the loaded MIDI file in seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getDuration()  -- -> number
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setLooping ----------------------------------------
--@api-stub: LMidiPlayer:setLooping
-- Enables or disables looping for MIDI playback.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setLooping(looping)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:isLooping -----------------------------------------
--@api-stub: LMidiPlayer:isLooping
-- Returns whether MIDI looping is enabled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:isLooping()  -- -> boolean
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setVolume -----------------------------------------
--@api-stub: LMidiPlayer:setVolume
-- Sets the master volume for MIDI playback.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setVolume(vol)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getVolume -----------------------------------------
--@api-stub: LMidiPlayer:getVolume
-- Returns the current master volume of the MIDI player.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getVolume()  -- -> number
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setBus --------------------------------------------
--@api-stub: LMidiPlayer:setBus
-- Routes this MIDI player's output through the specified audio bus.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setBus(bus_val)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getBus --------------------------------------------
--@api-stub: LMidiPlayer:getBus
-- Returns the audio bus this MIDI player is routed through.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getBus()  -- -> LBus
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setTempo ------------------------------------------
--@api-stub: LMidiPlayer:setTempo
-- Sets the playback tempo in beats per minute.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setTempo(bpm)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getTempo ------------------------------------------
--@api-stub: LMidiPlayer:getTempo
-- Returns the current effective tempo in beats per minute.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getTempo()  -- -> number
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getOriginalTempo ----------------------------------
--@api-stub: LMidiPlayer:getOriginalTempo
-- Returns the original tempo of the MIDI file as authored.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getOriginalTempo()  -- -> number
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setTempoScale -------------------------------------
--@api-stub: LMidiPlayer:setTempoScale
-- Sets a tempo multiplier relative to the original speed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setTempoScale(1.0)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getTempoScale -------------------------------------
--@api-stub: LMidiPlayer:getTempoScale
-- Returns the current tempo scale multiplier.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getTempoScale()  -- -> number
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getTicksPerBeat -----------------------------------
--@api-stub: LMidiPlayer:getTicksPerBeat
-- Returns the MIDI file's resolution in ticks per beat (PPQN).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getTicksPerBeat()  -- -> integer
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setChannelVolume ----------------------------------
--@api-stub: LMidiPlayer:setChannelVolume
-- Sets the volume for a specific MIDI channel (1-16).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setChannelVolume(ch, vol)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getChannelVolume ----------------------------------
--@api-stub: LMidiPlayer:getChannelVolume
-- Returns the volume of a specific MIDI channel.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getChannelVolume(ch)  -- -> number
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setChannelMuted -----------------------------------
--@api-stub: LMidiPlayer:setChannelMuted
-- Mutes or unmutes a specific MIDI channel.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setChannelMuted(ch, muted)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:isChannelMuted ------------------------------------
--@api-stub: LMidiPlayer:isChannelMuted
-- Returns whether a specific MIDI channel is muted.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:isChannelMuted(ch)  -- -> boolean
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setChannelInstrument ------------------------------
--@api-stub: LMidiPlayer:setChannelInstrument
-- Sets the General MIDI instrument program for a channel.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setChannelInstrument(ch, inst)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getChannelInstrument ------------------------------
--@api-stub: LMidiPlayer:getChannelInstrument
-- Returns the current GM instrument program for a channel.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getChannelInstrument(ch)  -- -> integer
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getChannelCount -----------------------------------
--@api-stub: LMidiPlayer:getChannelCount
-- Returns the number of active MIDI channels in the loaded file.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getChannelCount()  -- -> integer
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:soloChannel ---------------------------------------
--@api-stub: LMidiPlayer:soloChannel
-- Solos a specific MIDI channel, muting all others.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:soloChannel(ch)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:unsoloAll -----------------------------------------
--@api-stub: LMidiPlayer:unsoloAll
-- Removes solo from all channels, restoring normal playback.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:unsoloAll()
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getTrackCount -------------------------------------
--@api-stub: LMidiPlayer:getTrackCount
-- Returns the number of tracks in the loaded MIDI file.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getTrackCount()  -- -> integer
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getTrackName --------------------------------------
--@api-stub: LMidiPlayer:getTrackName
-- Returns the name of a MIDI track by 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getTrackName(1)  -- -> string
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setTrackMuted -------------------------------------
--@api-stub: LMidiPlayer:setTrackMuted
-- Mutes or unmutes a specific MIDI track.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setTrackMuted(1, muted)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:isTrackMuted --------------------------------------
--@api-stub: LMidiPlayer:isTrackMuted
-- Returns whether a specific MIDI track is muted.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:isTrackMuted(1)  -- -> boolean
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getNoteCount --------------------------------------
--@api-stub: LMidiPlayer:getNoteCount
-- Returns the total number of note events in the loaded MIDI file.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getNoteCount()  -- -> integer
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setOnNoteOn ---------------------------------------
--@api-stub: LMidiPlayer:setOnNoteOn
-- Registers a callback for MIDI note-on events (stub, not yet implemented).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setOnNoteOn(cb)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setOnNoteOff --------------------------------------
--@api-stub: LMidiPlayer:setOnNoteOff
-- Registers a callback for MIDI note-off events (stub, not yet implemented).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setOnNoteOff(cb)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setOnEnd ------------------------------------------
--@api-stub: LMidiPlayer:setOnEnd
-- Registers a callback invoked when MIDI playback finishes (stub, not yet implemented).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setOnEnd(cb)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getSampleRate -------------------------------------
--@api-stub: LMidiPlayer:getSampleRate
-- Returns the output sample rate used for MIDI synthesis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getSampleRate()  -- -> integer
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setSampleRate -------------------------------------
--@api-stub: LMidiPlayer:setSampleRate
-- Sets the output sample rate for MIDI synthesis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setSampleRate(rate)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:getChannels ---------------------------------------
--@api-stub: LMidiPlayer:getChannels
-- Returns the number of output audio channels for MIDI synthesis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:getChannels()  -- -> integer
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:setChannels ---------------------------------------
--@api-stub: LMidiPlayer:setChannels
-- Sets the number of output audio channels for MIDI synthesis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:setChannels(channels)
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:type ----------------------------------------------
--@api-stub: LMidiPlayer:type
-- Returns the type name of this object for runtime type-checking.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:type()  -- -> string
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- ---- Stub: LMidiPlayer:typeOf --------------------------------------------
--@api-stub: LMidiPlayer:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMidiPlayer_stub:typeOf("hero")  -- -> boolean
-- (replace lMidiPlayer_stub with your real LMidiPlayer instance above)

-- -----------------------------------------------------------------------------
-- LSoundData methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSoundData:typeOf ---------------------------------------------
--@api-stub: LSoundData:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSoundData_stub:typeOf("hero")  -- -> boolean
-- (replace lSoundData_stub with your real LSoundData instance above)

-- -----------------------------------------------------------------------------
-- LSoundPool methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSoundPool:play -----------------------------------------------
--@api-stub: LSoundPool:play
-- Plays the next available voice from the pool in round-robin order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSoundPool_stub:play()  -- -> integer
-- (replace lSoundPool_stub with your real LSoundPool instance above)

-- ---- Stub: LSoundPool:stopAll --------------------------------------------
--@api-stub: LSoundPool:stopAll
-- Stops all voices in this sound pool immediately.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSoundPool_stub:stopAll()
-- (replace lSoundPool_stub with your real LSoundPool instance above)

-- ---- Stub: LSoundPool:setVolume ------------------------------------------
--@api-stub: LSoundPool:setVolume
-- Sets the volume for all voices in this pool.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSoundPool_stub:setVolume(vol)
-- (replace lSoundPool_stub with your real LSoundPool instance above)

-- ---- Stub: LSoundPool:setBus ---------------------------------------------
--@api-stub: LSoundPool:setBus
-- Routes all voices in this pool through the named audio bus.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSoundPool_stub:setBus("hero")
-- (replace lSoundPool_stub with your real LSoundPool instance above)

-- ---- Stub: LSoundPool:release --------------------------------------------
--@api-stub: LSoundPool:release
-- Releases all voices and frees audio resources held by this pool.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSoundPool_stub:release()
-- (replace lSoundPool_stub with your real LSoundPool instance above)

-- ---- Stub: LSoundPool:getVoiceCount --------------------------------------
--@api-stub: LSoundPool:getVoiceCount
-- Returns the number of pre-allocated voices in this pool.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSoundPool_stub:getVoiceCount()  -- -> integer
-- (replace lSoundPool_stub with your real LSoundPool instance above)

-- ---- Stub: LSoundPool:type -----------------------------------------------
--@api-stub: LSoundPool:type
-- Returns the type name of this object for runtime type-checking.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSoundPool_stub:type()  -- -> string
-- (replace lSoundPool_stub with your real LSoundPool instance above)

-- ---- Stub: LSoundPool:typeOf ---------------------------------------------
--@api-stub: LSoundPool:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSoundPool_stub:typeOf("hero")  -- -> boolean
-- (replace lSoundPool_stub with your real LSoundPool instance above)

-- -----------------------------------------------------------------------------
-- LSource methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSource:play --------------------------------------------------
--@api-stub: LSource:play
-- Starts playback of this audio source from the current position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:play()
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:stop --------------------------------------------------
--@api-stub: LSource:stop
-- Stops playback and resets the source position to the beginning.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:stop()
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:pause -------------------------------------------------
--@api-stub: LSource:pause
-- Pauses playback at the current position, allowing later resumption.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:pause()
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:resume ------------------------------------------------
--@api-stub: LSource:resume
-- Resumes playback from the position where the source was paused.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:resume()
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:setVolume ---------------------------------------------
--@api-stub: LSource:setVolume
-- Sets the volume level of this source where 0.0 is silent and 1.0 is full volume.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:setVolume(vol)
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:getVolume ---------------------------------------------
--@api-stub: LSource:getVolume
-- Returns the current volume level of this audio source.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:getVolume()  -- -> number
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:setPitch ----------------------------------------------
--@api-stub: LSource:setPitch
-- Sets the playback speed multiplier, affecting both pitch and duration.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:setPitch(pitch)
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:getPitch ----------------------------------------------
--@api-stub: LSource:getPitch
-- Returns the current pitch multiplier of this audio source.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:getPitch()  -- -> number
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:setLooping --------------------------------------------
--@api-stub: LSource:setLooping
-- Enables or disables looping so the source restarts automatically after finishing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:setLooping(looping)
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:isLooping ---------------------------------------------
--@api-stub: LSource:isLooping
-- Returns whether this source is set to loop continuously.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:isLooping()  -- -> boolean
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:isPlaying ---------------------------------------------
--@api-stub: LSource:isPlaying
-- Returns whether this source is currently playing audio.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:isPlaying()  -- -> boolean
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:isPaused ----------------------------------------------
--@api-stub: LSource:isPaused
-- Returns whether this source is currently paused.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:isPaused()  -- -> boolean
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:isStopped ---------------------------------------------
--@api-stub: LSource:isStopped
-- Returns whether this source is currently stopped (not playing or paused).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:isStopped()  -- -> boolean
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:setPan ------------------------------------------------
--@api-stub: LSource:setPan
-- Sets the stereo panning position of this source.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:setPan(pan)
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:getPan ------------------------------------------------
--@api-stub: LSource:getPan
-- Returns the current stereo panning position of this source.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:getPan()  -- -> number
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:clone -------------------------------------------------
--@api-stub: LSource:clone
-- Creates an independent copy of this source sharing the same audio data.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:clone()  -- -> LSource
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:getType -----------------------------------------------
--@api-stub: LSource:getType
-- Returns whether this source was loaded as static (fully in memory) or streaming.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:getType()  -- -> string
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:getDuration -------------------------------------------
--@api-stub: LSource:getDuration
-- Returns the total duration of this audio source in seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:getDuration()  -- -> number
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:tell --------------------------------------------------
--@api-stub: LSource:tell
-- Returns the current playback position of this source in seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:tell()  -- -> number
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:seek --------------------------------------------------
--@api-stub: LSource:seek
-- Seeks to a specific position in seconds within this audio source.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:seek(pos)
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:setLowpass --------------------------------------------
--@api-stub: LSource:setLowpass
-- Applies a lowpass filter that attenuates frequencies above the cutoff.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:setLowpass(cutoff_hz)
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:setHighpass -------------------------------------------
--@api-stub: LSource:setHighpass
-- Applies a highpass filter that attenuates frequencies below the cutoff.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:setHighpass(cutoff_hz)
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:getLowpass --------------------------------------------
--@api-stub: LSource:getLowpass
-- Returns the current lowpass filter cutoff frequency in Hertz.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:getLowpass()  -- -> integer
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:getHighpass -------------------------------------------
--@api-stub: LSource:getHighpass
-- Returns the current highpass filter cutoff frequency in Hertz.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:getHighpass()  -- -> integer
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:clearFilter -------------------------------------------
--@api-stub: LSource:clearFilter
-- Removes all frequency filters (lowpass and highpass) from this source.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:clearFilter()
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:fadeIn ------------------------------------------------
--@api-stub: LSource:fadeIn
-- Sets the fade-in duration so the source ramps from silence to full volume on play.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:fadeIn(dur)
-- (replace lSource_stub with your real LSource instance above)

-- ---- Stub: LSource:getFadeIn ---------------------------------------------
--@api-stub: LSource:getFadeIn
-- Returns the configured fade-in duration for this source.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSource_stub:getFadeIn()  -- -> number
-- (replace lSource_stub with your real LSource instance above)
