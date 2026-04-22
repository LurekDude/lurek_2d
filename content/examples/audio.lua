-- content/examples/audio.lua
-- Practical usage examples for the lurek.audio API (212 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.audio.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/audio.lua

print("[example] lurek.audio — 212 API entries")

-- ── lurek.audio.* free functions ──

--@api-stub: lurek.audio.newSource
-- Loads an audio file and returns a Source handle.
-- Call when you need to create a new source.
local ok, obj = pcall(function() return lurek.audio.newSource({}) end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newSource ok=", ok)

--@api-stub: lurek.audio.play
-- Plays a source, with optional bus routing via options table.
-- Call when you need to invoke play.
local ok, result = pcall(function() return lurek.audio.play(nil, {}) end)
if not ok then print("action skipped:", result) end
print("lurek.audio.play fired=", ok)

--@api-stub: lurek.audio.stop
-- Stops playback and resets seek position.
-- Call when you need to invoke stop.
local ok, result = pcall(function() return lurek.audio.stop(nil) end)
if not ok then print("action skipped:", result) end
print("lurek.audio.stop fired=", ok)

--@api-stub: lurek.audio.setVolume
-- Sets source playback volume.
-- Call when you need to assign volume.
local ok, err = pcall(function() lurek.audio.setVolume(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setVolume applied=", ok)

--@api-stub: lurek.audio.getVolume
-- Returns the source volume.
-- Call when you need to read volume.
local ok, value = pcall(function() return lurek.audio.getVolume(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getVolume ->", v)

--@api-stub: lurek.audio.pause
-- Pauses playback at the current position.
-- Call when you need to invoke pause.
local ok, result = pcall(function() return lurek.audio.pause(nil) end)
if not ok then print("action skipped:", result) end
print("lurek.audio.pause fired=", ok)

--@api-stub: lurek.audio.resume
-- Resumes playback from pause.
-- Call when you need to invoke resume.
local ok, result = pcall(function() return lurek.audio.resume(nil) end)
if not ok then print("action skipped:", result) end
print("lurek.audio.resume fired=", ok)

--@api-stub: lurek.audio.setPitch
-- Sets source pitch multiplier.
-- Call when you need to assign pitch.
local ok, err = pcall(function() lurek.audio.setPitch(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setPitch applied=", ok)

--@api-stub: lurek.audio.getPitch
-- Returns the source pitch multiplier.
-- Call when you need to read pitch.
local ok, value = pcall(function() return lurek.audio.getPitch(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getPitch ->", v)

--@api-stub: lurek.audio.isPlaying
-- Returns true if the source is playing.
-- Call when you need to check is playing.
local ok, result = pcall(function() return lurek.audio.isPlaying(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.audio.isPlaying ok=", ok)

--@api-stub: lurek.audio.isPaused
-- Returns true if the source is paused.
-- Call when you need to check is paused.
local ok, result = pcall(function() return lurek.audio.isPaused(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.audio.isPaused ok=", ok)

--@api-stub: lurek.audio.isStopped
-- Returns true if the source is stopped.
-- Call when you need to check is stopped.
local ok, result = pcall(function() return lurek.audio.isStopped(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.audio.isStopped ok=", ok)

--@api-stub: lurek.audio.setLooping
-- Enables or disables looping.
-- Call when you need to assign looping.
local ok, err = pcall(function() lurek.audio.setLooping(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setLooping applied=", ok)

--@api-stub: lurek.audio.isLooping
-- Returns true if looping is enabled.
-- Call when you need to check is looping.
local ok, result = pcall(function() return lurek.audio.isLooping(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.audio.isLooping ok=", ok)

--@api-stub: lurek.audio.playLooping
-- Plays the source in a continuous loop.
-- Call when you need to play looping.
local ok, result = pcall(function() return lurek.audio.playLooping(nil) end)
if not ok then print("action skipped:", result) end
print("lurek.audio.playLooping fired=", ok)

--@api-stub: lurek.audio.setPan
-- Sets stereo panning (-1.0 left to 1.0 right).
-- Call when you need to assign pan.
local ok, err = pcall(function() lurek.audio.setPan(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setPan applied=", ok)

--@api-stub: lurek.audio.getPan
-- Returns the source stereo panning.
-- Call when you need to read pan.
local ok, value = pcall(function() return lurek.audio.getPan(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getPan ->", v)

--@api-stub: lurek.audio.setMasterVolume
-- Sets the global master volume.
-- Call when you need to assign master volume.
local ok, err = pcall(function() lurek.audio.setMasterVolume(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setMasterVolume applied=", ok)

--@api-stub: lurek.audio.getMasterVolume
-- Returns the global master volume.
-- Call when you need to read master volume.
local ok, value = pcall(function() return lurek.audio.getMasterVolume() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getMasterVolume ->", v)

--@api-stub: lurek.audio.getActiveSourceCount
-- Returns the number of currently playing sources.
-- Call when you need to read active source count.
local ok, value = pcall(function() return lurek.audio.getActiveSourceCount() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getActiveSourceCount ->", v)

--@api-stub: lurek.audio.getSourceCount
-- Returns the total number of registered sources.
-- Call when you need to read source count.
local ok, value = pcall(function() return lurek.audio.getSourceCount() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getSourceCount ->", v)

--@api-stub: lurek.audio.getSourceType
-- Returns the type string ("static" or "stream") of a source.
-- Call when you need to read source type.
local ok, value = pcall(function() return lurek.audio.getSourceType(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getSourceType ->", v)

--@api-stub: lurek.audio.clone
-- Creates an independent copy of a source.
-- Call when you need to invoke clone.
local ok, result = pcall(function() return lurek.audio.clone(nil) end)
if ok then print("lurek.audio.clone ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.pauseAll
-- Pauses all currently playing sources.
-- Call when you need to invoke pause all.
local ok, result = pcall(function() return lurek.audio.pauseAll() end)
if not ok then print("action skipped:", result) end
print("lurek.audio.pauseAll fired=", ok)

--@api-stub: lurek.audio.stopAll
-- Stops all currently playing sources.
-- Call when you need to invoke stop all.
local ok, result = pcall(function() return lurek.audio.stopAll() end)
if not ok then print("action skipped:", result) end
print("lurek.audio.stopAll fired=", ok)

--@api-stub: lurek.audio.resumeAll
-- Resumes all paused sources.
-- Call when you need to invoke resume all.
local ok, result = pcall(function() return lurek.audio.resumeAll() end)
if not ok then print("action skipped:", result) end
print("lurek.audio.resumeAll fired=", ok)

--@api-stub: lurek.audio.release
-- Releases a source and frees its memory.
-- Call when you need to invoke release.
local ok, result = pcall(function() return lurek.audio.release(nil) end)
if ok then print("lurek.audio.release ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.newBus
-- Creates a named audio bus for grouping sources.
-- Call when you need to create a new bus.
local ok, obj = pcall(function() return lurek.audio.newBus("sfx/click.ogg") end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newBus ok=", ok)

--@api-stub: lurek.audio.setSourceBus
-- Assigns a source to a bus.
-- Call when you need to assign source bus.
local ok, err = pcall(function() lurek.audio.setSourceBus(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setSourceBus applied=", ok)

--@api-stub: lurek.audio.getSourceBus
-- Returns the bus a source is assigned to, or nil.
-- Call when you need to read source bus.
local ok, value = pcall(function() return lurek.audio.getSourceBus(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getSourceBus ->", v)

--@api-stub: lurek.audio.getMaxSources
-- Returns the maximum number of simultaneous sources.
-- Call when you need to read max sources.
local ok, value = pcall(function() return lurek.audio.getMaxSources() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getMaxSources ->", v)

--@api-stub: lurek.audio.getDuration
-- Returns the total duration of a source in seconds.
-- Call when you need to read duration.
local ok, value = pcall(function() return lurek.audio.getDuration(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getDuration ->", v)

--@api-stub: lurek.audio.tell
-- Returns the current playback position in seconds.
-- Call when you need to invoke tell.
local ok, result = pcall(function() return lurek.audio.tell(nil) end)
if ok then print("lurek.audio.tell ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.seek
-- Seeks to a time position in seconds.
-- Call when you need to invoke seek.
local ok, result = pcall(function() return lurek.audio.seek(nil, nil) end)
if ok then print("lurek.audio.seek ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.setLowpass
-- Applies a low-pass filter to a source.
-- Call when you need to assign lowpass.
local ok, err = pcall(function() lurek.audio.setLowpass(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setLowpass applied=", ok)

--@api-stub: lurek.audio.setHighpass
-- Applies a high-pass filter to a source.
-- Call when you need to assign highpass.
local ok, err = pcall(function() lurek.audio.setHighpass(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setHighpass applied=", ok)

--@api-stub: lurek.audio.getLowpass
-- Returns the low-pass filter cutoff of a source.
-- Call when you need to read lowpass.
local ok, value = pcall(function() return lurek.audio.getLowpass(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getLowpass ->", v)

--@api-stub: lurek.audio.getHighpass
-- Returns the high-pass filter cutoff of a source.
-- Call when you need to read highpass.
local ok, value = pcall(function() return lurek.audio.getHighpass(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getHighpass ->", v)

--@api-stub: lurek.audio.clearFilter
-- Removes any active filter from a source.
-- Call when you need to invoke clear filter.
local ok, err = pcall(function() lurek.audio.clearFilter(nil) end)
if not ok then print("skipped:", err) end
print("lurek.audio.clearFilter cleared=", ok)

--@api-stub: lurek.audio.fadeIn
-- Fades a source in from silence over the given duration.
-- Call when you need to invoke fade in.
local ok, result = pcall(function() return lurek.audio.fadeIn(nil, nil) end)
if ok then print("lurek.audio.fadeIn ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.getFadeIn
-- Returns the fade-in duration of a source.
-- Call when you need to read fade in.
local ok, value = pcall(function() return lurek.audio.getFadeIn(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getFadeIn ->", v)

--@api-stub: lurek.audio.setListener2D
-- Sets the 2D listener position for spatial audio.
-- Call when you need to assign listener2 d.
local ok, err = pcall(function() lurek.audio.setListener2D(0, 0) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setListener2D applied=", ok)

--@api-stub: lurek.audio.getListener2D
-- Returns the 2D listener position (x, y).
-- Call when you need to read listener2 d.
local ok, value = pcall(function() return lurek.audio.getListener2D() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getListener2D ->", v)

--@api-stub: lurek.audio.setListener
-- Sets the 3D listener position.
-- Call when you need to assign listener.
local ok, err = pcall(function() lurek.audio.setListener(0, 0, 0) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setListener applied=", ok)

--@api-stub: lurek.audio.getListener
-- Returns the 3D listener position (x, y, z).
-- Call when you need to read listener.
local ok, value = pcall(function() return lurek.audio.getListener() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getListener ->", v)

--@api-stub: lurek.audio.setPosition
-- Sets the 3D position of a source.
-- Call when you need to assign position.
local ok, err = pcall(function() lurek.audio.setPosition(nil, 0, 0, 0) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setPosition applied=", ok)

--@api-stub: lurek.audio.getPosition
-- Returns the 3D position of a source (x, y, z).
-- Call when you need to read position.
local ok, value = pcall(function() return lurek.audio.getPosition(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getPosition ->", v)

--@api-stub: lurek.audio.setVelocity
-- Sets the velocity of a source for Doppler.
-- Call when you need to assign velocity.
local ok, err = pcall(function() lurek.audio.setVelocity(nil, 0, 0, 0) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setVelocity applied=", ok)

--@api-stub: lurek.audio.getVelocity
-- Returns the velocity of a source (x, y, z).
-- Call when you need to read velocity.
local ok, value = pcall(function() return lurek.audio.getVelocity(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getVelocity ->", v)

--@api-stub: lurek.audio.setOrientation
-- Sets the 6-component orientation of a source.
-- Call when you need to assign orientation.
local ok, err = pcall(function() lurek.audio.setOrientation(nil, nil, nil, nil, nil, nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setOrientation applied=", ok)

--@api-stub: lurek.audio.getOrientation
-- Returns the 6-component orientation of a source.
-- Call when you need to read orientation.
local ok, value = pcall(function() return lurek.audio.getOrientation(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getOrientation ->", v)

--@api-stub: lurek.audio.setDopplerScale
-- Sets the global Doppler effect scale.
-- Call when you need to assign doppler scale.
local ok, err = pcall(function() lurek.audio.setDopplerScale(1) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setDopplerScale applied=", ok)

--@api-stub: lurek.audio.getDopplerScale
-- Returns the current Doppler scale.
-- Call when you need to read doppler scale.
local ok, value = pcall(function() return lurek.audio.getDopplerScale() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getDopplerScale ->", v)

--@api-stub: lurek.audio.setDistanceModel
-- Sets the distance attenuation model.
-- Call when you need to assign distance model.
local ok, err = pcall(function() lurek.audio.setDistanceModel(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setDistanceModel applied=", ok)

--@api-stub: lurek.audio.getDistanceModel
-- Returns the current distance model name.
-- Call when you need to read distance model.
local ok, value = pcall(function() return lurek.audio.getDistanceModel() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getDistanceModel ->", v)

--@api-stub: lurek.audio.setMeter
-- Sets the master peak meter level (0.0â€“1.0).
-- Call when you need to assign meter.
local ok, err = pcall(function() lurek.audio.setMeter(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setMeter applied=", ok)

--@api-stub: lurek.audio.getMeter
-- Returns the stored master peak meter level.
-- Call when you need to read meter.
local ok, value = pcall(function() return lurek.audio.getMeter() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getMeter ->", v)

--@api-stub: lurek.audio.newMidiPlayer
-- Creates a MIDI player, optionally loading a file.
-- Call when you need to create a new midi player.
local ok, obj = pcall(function() return lurek.audio.newMidiPlayer("sfx/click.ogg") end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newMidiPlayer ok=", ok)

--@api-stub: lurek.audio.newSoundData
-- Creates a SoundData from a file or as a silent buffer.
-- Call when you need to create a new sound data.
local ok, obj = pcall(function() return lurek.audio.newSoundData({}) end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newSoundData ok=", ok)

--@api-stub: lurek.audio.setMidiSoundFont
-- Sets the global SoundFont for MIDI synthesis.
-- Call when you need to assign midi sound font.
local ok, err = pcall(function() lurek.audio.setMidiSoundFont("sfx/click.ogg") end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setMidiSoundFont applied=", ok)

--@api-stub: lurek.audio.hasMidiSoundFont
-- Returns true if a SoundFont is loaded.
-- Call when you need to check has midi sound font.
local ok, result = pcall(function() return lurek.audio.hasMidiSoundFont() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.audio.hasMidiSoundFont ok=", ok)

--@api-stub: lurek.audio.clearMidiSoundFont
-- Unloads the active SoundFont.
-- Call when you need to invoke clear midi sound font.
local ok, err = pcall(function() lurek.audio.clearMidiSoundFont() end)
if not ok then print("skipped:", err) end
print("lurek.audio.clearMidiSoundFont cleared=", ok)

--@api-stub: lurek.audio.newDecoder
-- Creates a streaming audio decoder.
-- Call when you need to create a new decoder.
local ok, obj = pcall(function() return lurek.audio.newDecoder(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newDecoder ok=", ok)

--@api-stub: lurek.audio.newQueueableSource
-- Creates a queueable source for manual PCM buffering.
-- Call when you need to create a new queueable source.
local ok, obj = pcall(function() return lurek.audio.newQueueableSource() end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newQueueableSource ok=", ok)

--@api-stub: lurek.audio.queueSource
-- Pushes a SoundData buffer into a queueable source.
-- Call when you need to invoke queue source.
local ok, result = pcall(function() return lurek.audio.queueSource(1, nil) end)
if ok then print("lurek.audio.queueSource ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.getFreeBufferCount
-- Returns the free buffer slots in a queueable source.
-- Call when you need to read free buffer count.
local ok, value = pcall(function() return lurek.audio.getFreeBufferCount(1) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getFreeBufferCount ->", v)

--@api-stub: lurek.audio.playQueueable
-- Starts playback of a queueable source.
-- Call when you need to play queueable.
local ok, result = pcall(function() return lurek.audio.playQueueable(1) end)
if not ok then print("action skipped:", result) end
print("lurek.audio.playQueueable fired=", ok)

--@api-stub: lurek.audio.stopQueueable
-- Stops a queueable source and drains its buffers.
-- Call when you need to invoke stop queueable.
local ok, result = pcall(function() return lurek.audio.stopQueueable(1) end)
if not ok then print("action skipped:", result) end
print("lurek.audio.stopQueueable fired=", ok)

--@api-stub: lurek.audio.getPlaybackDevices
-- Returns a table of available audio output device names.
-- Call when you need to read playback devices.
local ok, value = pcall(function() return lurek.audio.getPlaybackDevices() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getPlaybackDevices ->", v)

--@api-stub: lurek.audio.getPlaybackDevice
-- Returns the current audio output device name.
-- Call when you need to read playback device.
local ok, value = pcall(function() return lurek.audio.getPlaybackDevice() end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getPlaybackDevice ->", v)

--@api-stub: lurek.audio.setPlaybackDevice
-- Selects an audio output device by name.
-- Call when you need to assign playback device.
local ok, err = pcall(function() lurek.audio.setPlaybackDevice("sfx/click.ogg") end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setPlaybackDevice applied=", ok)

--@api-stub: lurek.audio.create_bus
-- Creates a bus by name (functional style).
-- Call when you need to invoke create_bus.
local ok, obj = pcall(function() return lurek.audio.create_bus("sfx/click.ogg", "sfx/click.ogg") end)
if ok and obj then print("created:", obj) end
print("lurek.audio.create_bus ok=", ok)

--@api-stub: lurek.audio.set_bus_volume
-- Sets a bus volume by name.
-- Call when you need to invoke set_bus_volume.
local ok, err = pcall(function() lurek.audio.set_bus_volume("sfx/click.ogg", nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.set_bus_volume applied=", ok)

--@api-stub: lurek.audio.add_effect
-- Adds a DSP effect to a bus.
-- Call when you need to invoke add_effect.
local ok, err = pcall(function() lurek.audio.add_effect("sfx/click.ogg", "effect_type_str value", {}) end)
if not ok then print("mutator skipped:", err) end
print("lurek.audio.add_effect done=", ok)

--@api-stub: lurek.audio.remove_effect
-- Removes a DSP effect from a bus.
-- Call when you need to invoke remove_effect.
local ok, err = pcall(function() lurek.audio.remove_effect("sfx/click.ogg", 1) end)
if not ok then print("skipped:", err) end
print("lurek.audio.remove_effect cleared=", ok)

--@api-stub: lurek.audio.set_effect_param
-- Sets a parameter on a DSP effect.
-- Call when you need to invoke set_effect_param.
local ok, err = pcall(function() lurek.audio.set_effect_param("sfx/click.ogg", 1, "sfx/click.ogg", nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.set_effect_param applied=", ok)

--@api-stub: lurek.audio.newSineWave
-- Generate a mono sine-wave SoundData buffer.
-- Call when you need to create a new sine wave.
local ok, obj = pcall(function() return lurek.audio.newSineWave(nil, 1.0, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newSineWave ok=", ok)

--@api-stub: lurek.audio.newSquareWave
-- Generate a mono square-wave SoundData buffer.
-- Call when you need to create a new square wave.
local ok, obj = pcall(function() return lurek.audio.newSquareWave(nil, 1.0, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newSquareWave ok=", ok)

--@api-stub: lurek.audio.newSawtoothWave
-- Generate a mono sawtooth-wave SoundData buffer.
-- Call when you need to create a new sawtooth wave.
local ok, obj = pcall(function() return lurek.audio.newSawtoothWave(nil, 1.0, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newSawtoothWave ok=", ok)

--@api-stub: lurek.audio.newTriangleWave
-- Generate a mono triangle-wave SoundData buffer.
-- Call when you need to create a new triangle wave.
local ok, obj = pcall(function() return lurek.audio.newTriangleWave(nil, 1.0, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newTriangleWave ok=", ok)

--@api-stub: lurek.audio.newWhiteNoise
-- Generate a reproducible white-noise SoundData buffer.
-- Call when you need to create a new white noise.
local ok, obj = pcall(function() return lurek.audio.newWhiteNoise(1.0, nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newWhiteNoise ok=", ok)

--@api-stub: lurek.audio.applyLowpass
-- Applies a first-order IIR low-pass filter to a SoundData in-place.
-- Call when you need to invoke apply lowpass.
local ok, err = pcall(function() lurek.audio.applyLowpass(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.applyLowpass applied=", ok)

--@api-stub: lurek.audio.applyHighpass
-- Applies a first-order IIR high-pass filter to a SoundData in-place.
-- Call when you need to invoke apply highpass.
local ok, err = pcall(function() lurek.audio.applyHighpass(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.applyHighpass applied=", ok)

--@api-stub: lurek.audio.applyBandpass
-- Applies a bandpass filter (high-pass then low-pass) to a SoundData in-place.
-- Call when you need to invoke apply bandpass.
local ok, err = pcall(function() lurek.audio.applyBandpass(nil, nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.applyBandpass applied=", ok)

--@api-stub: lurek.audio.applyGain
-- Scales every sample by gain (clamped to [-1, 1]).
-- Call when you need to invoke apply gain.
local ok, err = pcall(function() lurek.audio.applyGain(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.applyGain applied=", ok)

--@api-stub: lurek.audio.mixInto
-- Additively mixes another SoundData into the destination in-place.
-- Call when you need to invoke mix into.
local ok, result = pcall(function() return lurek.audio.mixInto(nil, nil) end)
if ok then print("lurek.audio.mixInto ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.saveWAV
-- Saves a SoundData as a 16-bit PCM WAV file at the given path.
-- Call when you need to invoke save w a v.
local ok, obj = pcall(function() return lurek.audio.saveWAV(nil, "sfx/click.ogg") end)
if ok and obj then print("created:", obj) end
print("lurek.audio.saveWAV ok=", ok)

--@api-stub: lurek.audio.setStereoWidth
-- Sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono).
-- Call when you need to assign stereo width.
local ok, err = pcall(function() lurek.audio.setStereoWidth(nil, 100) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setStereoWidth applied=", ok)

--@api-stub: lurek.audio.getStereoWidth
-- Returns the current stereo width for a source.
-- Call when you need to read stereo width.
local ok, value = pcall(function() return lurek.audio.getStereoWidth(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getStereoWidth ->", v)

--@api-stub: lurek.audio.setRandomPitch
-- Sets a random pitch range applied each time the source is played.
-- Call when you need to assign random pitch.
local ok, err = pcall(function() lurek.audio.setRandomPitch(nil, 0, 100) end)
if not ok then print("set skipped:", err) end
print("lurek.audio.setRandomPitch applied=", ok)

--@api-stub: lurek.audio.clearRandomPitch
-- Clears any random pitch range on a source, restoring fixed pitch.
-- Call when you need to invoke clear random pitch.
local ok, err = pcall(function() lurek.audio.clearRandomPitch(nil) end)
if not ok then print("skipped:", err) end
print("lurek.audio.clearRandomPitch cleared=", ok)

--@api-stub: lurek.audio.crossfade
-- Crossfades from one source to another over a duration.
-- Call when you need to invoke crossfade.
local ok, result = pcall(function() return lurek.audio.crossfade(nil, nil, 1.0) end)
if ok then print("lurek.audio.crossfade ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.getBusPeak
-- Returns the peak signal level of the named bus (stub: always 0.0).
-- Call when you need to read bus peak.
local ok, value = pcall(function() return lurek.audio.getBusPeak("sfx/click.ogg") end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getBusPeak ->", v)

--@api-stub: lurek.audio.getBusRms
-- Returns the RMS signal level of the named bus (stub: always 0.0).
-- Call when you need to read bus rms.
local ok, value = pcall(function() return lurek.audio.getBusRms("sfx/click.ogg") end)
local v = ok and value or "(unavailable)"
print("lurek.audio.getBusRms ->", v)

--@api-stub: lurek.audio.newPool
-- Creates a polyphonic sound pool for the given file with N simultaneous voices.
-- Call when you need to create a new pool.
local ok, obj = pcall(function() return lurek.audio.newPool("sfx/click.ogg", 10) end)
if ok and obj then print("created:", obj) end
print("lurek.audio.newPool ok=", ok)

--@api-stub: lurek.audio.processOffline
-- Applies a DSP effect chain to a WAV file and writes output.
-- Call when you need to invoke process offline.
local ok, result = pcall(function() return lurek.audio.processOffline(nil, nil, nil) end)
if ok then print("lurek.audio.processOffline ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.normalizeFile
-- Normalizes a WAV file peak amplitude to target_level and writes output.
-- Call when you need to invoke normalize file.
local ok, result = pcall(function() return lurek.audio.normalizeFile(nil, nil, nil) end)
if ok then print("lurek.audio.normalizeFile ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.waveformToPng
-- Renders the waveform of a WAV file to a PNG image.
-- Call when you need to invoke waveform to png.
local ok, result = pcall(function() return lurek.audio.waveformToPng(nil, nil, 100, 100) end)
if ok then print("lurek.audio.waveformToPng ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.audio.spectrogramToPng
-- Renders a time-frequency spectrogram of a WAV file to a PNG image.
-- Call when you need to invoke spectrogram to png.
local ok, result = pcall(function() return lurek.audio.spectrogramToPng(nil, nil, 100, 100) end)
if ok then print("lurek.audio.spectrogramToPng ->", result)
else print("unavailable:", result) end

-- ── Source methods ──

--@api-stub: Source:play
-- Starts or resumes playback.
-- Call when you need to invoke play.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:play() end)
  print("Source:play ->", ok, result)
end

--@api-stub: Source:stop
-- Stops playback and resets seek position.
-- Call when you need to invoke stop.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:stop() end)
  print("Source:stop ->", ok, result)
end

--@api-stub: Source:pause
-- Pauses playback at the current position.
-- Call when you need to invoke pause.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:pause() end)
  print("Source:pause ->", ok, result)
end

--@api-stub: Source:resume
-- Resumes playback from the paused position.
-- Call when you need to invoke resume.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:resume() end)
  print("Source:resume ->", ok, result)
end

--@api-stub: Source:setVolume
-- Sets playback volume (0.0 = silent, 1.0 = full).
-- Call when you need to assign volume.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:setVolume(nil) end)
  print("Source:setVolume ->", ok, result)
end

--@api-stub: Source:getVolume
-- Returns the current volume multiplier.
-- Call when you need to read volume.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:getVolume() end)
  print("Source:getVolume ->", ok, result)
end

--@api-stub: Source:setPitch
-- Sets the pitch multiplier (1.0 = normal).
-- Call when you need to assign pitch.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:setPitch(nil) end)
  print("Source:setPitch ->", ok, result)
end

--@api-stub: Source:getPitch
-- Returns the current pitch multiplier.
-- Call when you need to read pitch.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:getPitch() end)
  print("Source:getPitch ->", ok, result)
end

--@api-stub: Source:setLooping
-- Enables or disables looping playback.
-- Call when you need to assign looping.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:setLooping(nil) end)
  print("Source:setLooping ->", ok, result)
end

--@api-stub: Source:isLooping
-- Returns true if looping is enabled.
-- Call when you need to check is looping.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:isLooping() end)
  print("Source:isLooping ->", ok, result)
end

--@api-stub: Source:isPlaying
-- Returns true if currently playing.
-- Call when you need to check is playing.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:isPlaying() end)
  print("Source:isPlaying ->", ok, result)
end

--@api-stub: Source:isPaused
-- Returns true if playback is paused.
-- Call when you need to check is paused.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:isPaused() end)
  print("Source:isPaused ->", ok, result)
end

--@api-stub: Source:isStopped
-- Returns true if playback has stopped.
-- Call when you need to check is stopped.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:isStopped() end)
  print("Source:isStopped ->", ok, result)
end

--@api-stub: Source:setPan
-- Sets stereo panning (-1.0 left to 1.0 right).
-- Call when you need to assign pan.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:setPan(nil) end)
  print("Source:setPan ->", ok, result)
end

--@api-stub: Source:getPan
-- Returns the current stereo panning value.
-- Call when you need to read pan.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:getPan() end)
  print("Source:getPan ->", ok, result)
end

--@api-stub: Source:clone
-- Creates an independent copy of this source.
-- Call when you need to invoke clone.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:clone() end)
  print("Source:clone ->", ok, result)
end

--@api-stub: Source:getType
-- Returns the source type ("static" or "stream").
-- Call when you need to read type.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:getType() end)
  print("Source:getType ->", ok, result)
end

--@api-stub: Source:getDuration
-- Returns the total duration in seconds.
-- Call when you need to read duration.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:getDuration() end)
  print("Source:getDuration ->", ok, result)
end

--@api-stub: Source:tell
-- Returns the current playback position in seconds.
-- Call when you need to invoke tell.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:tell() end)
  print("Source:tell ->", ok, result)
end

--@api-stub: Source:seek
-- Seeks to a time position in seconds.
-- Call when you need to invoke seek.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:seek(nil) end)
  print("Source:seek ->", ok, result)
end

--@api-stub: Source:setLowpass
-- Applies a low-pass filter at the given cutoff frequency.
-- Call when you need to assign lowpass.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:setLowpass(nil) end)
  print("Source:setLowpass ->", ok, result)
end

--@api-stub: Source:setHighpass
-- Applies a high-pass filter at the given cutoff frequency.
-- Call when you need to assign highpass.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:setHighpass(nil) end)
  print("Source:setHighpass ->", ok, result)
end

--@api-stub: Source:getLowpass
-- Returns the low-pass filter cutoff frequency.
-- Call when you need to read lowpass.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:getLowpass() end)
  print("Source:getLowpass ->", ok, result)
end

--@api-stub: Source:getHighpass
-- Returns the high-pass filter cutoff frequency.
-- Call when you need to read highpass.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:getHighpass() end)
  print("Source:getHighpass ->", ok, result)
end

--@api-stub: Source:clearFilter
-- Removes any active filter from this source.
-- Call when you need to invoke clear filter.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:clearFilter() end)
  print("Source:clearFilter ->", ok, result)
end

--@api-stub: Source:fadeIn
-- Fades in from silence over the given duration in seconds.
-- Call when you need to invoke fade in.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:fadeIn(nil) end)
  print("Source:fadeIn ->", ok, result)
end

--@api-stub: Source:getFadeIn
-- Returns the current fade-in duration in seconds.
-- Call when you need to read fade in.
-- Build a Source via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSource(...)
if instance then
  local ok, result = pcall(function() return instance:getFadeIn() end)
  print("Source:getFadeIn ->", ok, result)
end

-- ── Bus methods ──

--@api-stub: Bus:getName
-- Returns the unique name string assigned to this audio bus.
-- Call when you need to read name.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("Bus:getName ->", ok, result)
end

--@api-stub: Bus:setVolume
-- Sets the volume for all sources on this bus.
-- Call when you need to assign volume.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:setVolume(nil) end)
  print("Bus:setVolume ->", ok, result)
end

--@api-stub: Bus:getVolume
-- Returns the current volume multiplier applied to all sources on this bus.
-- Call when you need to read volume.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:getVolume() end)
  print("Bus:getVolume ->", ok, result)
end

--@api-stub: Bus:setPitch
-- Sets the pitch multiplier for all sources on this bus.
-- Call when you need to assign pitch.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:setPitch(nil) end)
  print("Bus:setPitch ->", ok, result)
end

--@api-stub: Bus:getPitch
-- Returns the bus pitch multiplier.
-- Call when you need to read pitch.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:getPitch() end)
  print("Bus:getPitch ->", ok, result)
end

--@api-stub: Bus:pause
-- Pauses all sources on this bus.
-- Call when you need to invoke pause.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:pause() end)
  print("Bus:pause ->", ok, result)
end

--@api-stub: Bus:resume
-- Resumes all sources on this bus.
-- Call when you need to invoke resume.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:resume() end)
  print("Bus:resume ->", ok, result)
end

--@api-stub: Bus:isPaused
-- Returns true if this bus is paused.
-- Call when you need to check is paused.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:isPaused() end)
  print("Bus:isPaused ->", ok, result)
end

--@api-stub: Bus:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Bus:type ->", ok, result)
end

--@api-stub: Bus:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("sfx/click.ogg") end)
  print("Bus:typeOf ->", ok, result)
end

--@api-stub: Bus:clearDuck
-- Removes the ducking target from this bus, restoring the target bus.
-- Call when you need to invoke clear duck.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:clearDuck() end)
  print("Bus:clearDuck ->", ok, result)
end

--@api-stub: Bus:getPeak
-- Returns the average peak amplitude of all sources currently on this bus.
-- Call when you need to read peak.
-- Build a Bus via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newBus(...)
if instance then
  local ok, result = pcall(function() return instance:getPeak() end)
  print("Bus:getPeak ->", ok, result)
end

-- ── MidiPlayer methods ──

--@api-stub: MidiPlayer:load
-- Loads a MIDI file from the given path.
-- Call when you need to invoke load.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:load("sfx/click.ogg") end)
  print("MidiPlayer:load ->", ok, result)
end

--@api-stub: MidiPlayer:loadData
-- Loads MIDI data from a Lua string.
-- Call when you need to load data.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:loadData() end)
  print("MidiPlayer:loadData ->", ok, result)
end

--@api-stub: MidiPlayer:isLoaded
-- Returns true if a MIDI sequence is loaded.
-- Call when you need to check is loaded.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:isLoaded() end)
  print("MidiPlayer:isLoaded ->", ok, result)
end

--@api-stub: MidiPlayer:getFilePath
-- Returns the file path of the loaded MIDI, or nil.
-- Call when you need to read file path.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getFilePath() end)
  print("MidiPlayer:getFilePath ->", ok, result)
end

--@api-stub: MidiPlayer:setSoundFont
-- Loads a SoundFont file into this player (stub).
-- Call when you need to assign sound font.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setSoundFont("sfx/click.ogg") end)
  print("MidiPlayer:setSoundFont ->", ok, result)
end

--@api-stub: MidiPlayer:getSoundFontPath
-- Returns the SoundFont file path, or nil (stub).
-- Call when you need to read sound font path.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getSoundFontPath() end)
  print("MidiPlayer:getSoundFontPath ->", ok, result)
end

--@api-stub: MidiPlayer:useDefaultSoundFont
-- Reverts to the built-in default SoundFont (stub).
-- Call when you need to invoke use default sound font.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:useDefaultSoundFont() end)
  print("MidiPlayer:useDefaultSoundFont ->", ok, result)
end

--@api-stub: MidiPlayer:play
-- Starts or resumes MIDI sequence playback from the current position.
-- Call when you need to invoke play.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:play() end)
  print("MidiPlayer:play ->", ok, result)
end

--@api-stub: MidiPlayer:pause
-- Pauses the MIDI sequence at the current position; resume with `play()`.
-- Call when you need to invoke pause.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:pause() end)
  print("MidiPlayer:pause ->", ok, result)
end

--@api-stub: MidiPlayer:stop
-- Stops MIDI playback and resets the playhead to the beginning.
-- Call when you need to invoke stop.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:stop() end)
  print("MidiPlayer:stop ->", ok, result)
end

--@api-stub: MidiPlayer:isPlaying
-- Returns true if MIDI is currently playing.
-- Call when you need to check is playing.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:isPlaying() end)
  print("MidiPlayer:isPlaying ->", ok, result)
end

--@api-stub: MidiPlayer:isPaused
-- Returns true if MIDI playback is paused.
-- Call when you need to check is paused.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:isPaused() end)
  print("MidiPlayer:isPaused ->", ok, result)
end

--@api-stub: MidiPlayer:seek
-- Seeks to a time position in seconds.
-- Call when you need to invoke seek.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:seek(nil) end)
  print("MidiPlayer:seek ->", ok, result)
end

--@api-stub: MidiPlayer:tell
-- Returns the current playback position in seconds.
-- Call when you need to invoke tell.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:tell() end)
  print("MidiPlayer:tell ->", ok, result)
end

--@api-stub: MidiPlayer:getDuration
-- Returns the total MIDI duration in seconds.
-- Call when you need to read duration.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getDuration() end)
  print("MidiPlayer:getDuration ->", ok, result)
end

--@api-stub: MidiPlayer:setLooping
-- Enables or disables looping.
-- Call when you need to assign looping.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setLooping(nil) end)
  print("MidiPlayer:setLooping ->", ok, result)
end

--@api-stub: MidiPlayer:isLooping
-- Returns true if looping is enabled.
-- Call when you need to check is looping.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:isLooping() end)
  print("MidiPlayer:isLooping ->", ok, result)
end

--@api-stub: MidiPlayer:setVolume
-- Sets MIDI playback volume.
-- Call when you need to assign volume.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setVolume(nil) end)
  print("MidiPlayer:setVolume ->", ok, result)
end

--@api-stub: MidiPlayer:getVolume
-- Returns the current MIDI volume.
-- Call when you need to read volume.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getVolume() end)
  print("MidiPlayer:getVolume ->", ok, result)
end

--@api-stub: MidiPlayer:setBus
-- Routes MIDI output through a bus (or nil to clear).
-- Call when you need to assign bus.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setBus(nil) end)
  print("MidiPlayer:setBus ->", ok, result)
end

--@api-stub: MidiPlayer:getBus
-- Returns the assigned bus, or nil.
-- Call when you need to read bus.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getBus() end)
  print("MidiPlayer:getBus ->", ok, result)
end

--@api-stub: MidiPlayer:setTempo
-- Sets playback tempo in BPM.
-- Call when you need to assign tempo.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setTempo(nil) end)
  print("MidiPlayer:setTempo ->", ok, result)
end

--@api-stub: MidiPlayer:getTempo
-- Returns the current tempo in BPM.
-- Call when you need to read tempo.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getTempo() end)
  print("MidiPlayer:getTempo ->", ok, result)
end

--@api-stub: MidiPlayer:getOriginalTempo
-- Returns the original MIDI file tempo in BPM.
-- Call when you need to read original tempo.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getOriginalTempo() end)
  print("MidiPlayer:getOriginalTempo ->", ok, result)
end

--@api-stub: MidiPlayer:setTempoScale
-- Sets the tempo scale factor (1.0 = original speed).
-- Call when you need to assign tempo scale.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setTempoScale(1) end)
  print("MidiPlayer:setTempoScale ->", ok, result)
end

--@api-stub: MidiPlayer:getTempoScale
-- Returns the current tempo scale factor.
-- Call when you need to read tempo scale.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getTempoScale() end)
  print("MidiPlayer:getTempoScale ->", ok, result)
end

--@api-stub: MidiPlayer:getTicksPerBeat
-- Returns the PPQ resolution from the MIDI header.
-- Call when you need to read ticks per beat.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getTicksPerBeat() end)
  print("MidiPlayer:getTicksPerBeat ->", ok, result)
end

--@api-stub: MidiPlayer:setChannelVolume
-- Sets volume for a MIDI channel (1-indexed).
-- Call when you need to assign channel volume.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setChannelVolume(nil, nil) end)
  print("MidiPlayer:setChannelVolume ->", ok, result)
end

--@api-stub: MidiPlayer:getChannelVolume
-- Returns the volume for a MIDI channel (1-indexed).
-- Call when you need to read channel volume.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getChannelVolume(nil) end)
  print("MidiPlayer:getChannelVolume ->", ok, result)
end

--@api-stub: MidiPlayer:setChannelMuted
-- Mutes or unmutes a MIDI channel (1-indexed).
-- Call when you need to assign channel muted.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setChannelMuted(nil, nil) end)
  print("MidiPlayer:setChannelMuted ->", ok, result)
end

--@api-stub: MidiPlayer:isChannelMuted
-- Returns true if a MIDI channel is muted (1-indexed).
-- Call when you need to check is channel muted.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:isChannelMuted(nil) end)
  print("MidiPlayer:isChannelMuted ->", ok, result)
end

--@api-stub: MidiPlayer:getChannelInstrument
-- Returns the GM instrument for a MIDI channel (1-indexed).
-- Call when you need to read channel instrument.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getChannelInstrument(nil) end)
  print("MidiPlayer:getChannelInstrument ->", ok, result)
end

--@api-stub: MidiPlayer:getChannelCount
-- Returns the number of MIDI channels.
-- Call when you need to read channel count.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getChannelCount() end)
  print("MidiPlayer:getChannelCount ->", ok, result)
end

--@api-stub: MidiPlayer:soloChannel
-- Solos a MIDI channel (1-indexed).
-- Call when you need to invoke solo channel.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:soloChannel(nil) end)
  print("MidiPlayer:soloChannel ->", ok, result)
end

--@api-stub: MidiPlayer:unsoloAll
-- Clears solo on all channels.
-- Call when you need to invoke unsolo all.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:unsoloAll() end)
  print("MidiPlayer:unsoloAll ->", ok, result)
end

--@api-stub: MidiPlayer:getTrackCount
-- Returns the number of tracks in the MIDI sequence.
-- Call when you need to read track count.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getTrackCount() end)
  print("MidiPlayer:getTrackCount ->", ok, result)
end

--@api-stub: MidiPlayer:getTrackName
-- Returns the name of a MIDI track (1-indexed), or nil.
-- Call when you need to read track name.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getTrackName(1) end)
  print("MidiPlayer:getTrackName ->", ok, result)
end

--@api-stub: MidiPlayer:setTrackMuted
-- Mutes or unmutes a track (1-indexed).
-- Call when you need to assign track muted.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setTrackMuted(1, nil) end)
  print("MidiPlayer:setTrackMuted ->", ok, result)
end

--@api-stub: MidiPlayer:isTrackMuted
-- Returns true if a track is muted (1-indexed).
-- Call when you need to check is track muted.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:isTrackMuted(1) end)
  print("MidiPlayer:isTrackMuted ->", ok, result)
end

--@api-stub: MidiPlayer:getNoteCount
-- Returns the total note count in the MIDI sequence.
-- Call when you need to read note count.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getNoteCount() end)
  print("MidiPlayer:getNoteCount ->", ok, result)
end

--@api-stub: MidiPlayer:setOnNoteOn
-- Registers a note-on callback (stub).
-- Call when you need to assign on note on.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setOnNoteOn(function() end) end)
  print("MidiPlayer:setOnNoteOn ->", ok, result)
end

--@api-stub: MidiPlayer:setOnNoteOff
-- Registers a note-off callback (stub).
-- Call when you need to assign on note off.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setOnNoteOff(function() end) end)
  print("MidiPlayer:setOnNoteOff ->", ok, result)
end

--@api-stub: MidiPlayer:setOnEnd
-- Registers a playback-end callback (stub).
-- Call when you need to assign on end.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setOnEnd(function() end) end)
  print("MidiPlayer:setOnEnd ->", ok, result)
end

--@api-stub: MidiPlayer:getSampleRate
-- Returns the PCM output sample rate in Hz.
-- Call when you need to read sample rate.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getSampleRate() end)
  print("MidiPlayer:getSampleRate ->", ok, result)
end

--@api-stub: MidiPlayer:setSampleRate
-- Sets the PCM output sample rate in Hz (clamped 8000â€“192000).
-- Call when you need to assign sample rate.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setSampleRate(nil) end)
  print("MidiPlayer:setSampleRate ->", ok, result)
end

--@api-stub: MidiPlayer:getChannels
-- Returns the PCM output channel count (1 = mono, 2 = stereo).
-- Call when you need to read channels.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:getChannels() end)
  print("MidiPlayer:getChannels ->", ok, result)
end

--@api-stub: MidiPlayer:setChannels
-- Sets the PCM output channel count (clamped 1â€“2).
-- Call when you need to assign channels.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:setChannels(nil) end)
  print("MidiPlayer:setChannels ->", ok, result)
end

--@api-stub: MidiPlayer:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("MidiPlayer:type ->", ok, result)
end

--@api-stub: MidiPlayer:typeOf
-- Returns true if this object is of the given type.
-- Call when you need to invoke type of.
-- Build a MidiPlayer via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newMidiPlayer(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("sfx/click.ogg") end)
  print("MidiPlayer:typeOf ->", ok, result)
end

-- ── SoundPool methods ──

--@api-stub: SoundPool:play
-- Plays the next available voice and returns its SoundKey as an integer.
-- Call when you need to invoke play.
-- Build a SoundPool via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSoundPool(...)
if instance then
  local ok, result = pcall(function() return instance:play() end)
  print("SoundPool:play ->", ok, result)
end

--@api-stub: SoundPool:stopAll
-- Stops all voices in this pool.
-- Call when you need to invoke stop all.
-- Build a SoundPool via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSoundPool(...)
if instance then
  local ok, result = pcall(function() return instance:stopAll() end)
  print("SoundPool:stopAll ->", ok, result)
end

--@api-stub: SoundPool:setVolume
-- Sets the volume for all voices in this pool.
-- Call when you need to assign volume.
-- Build a SoundPool via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSoundPool(...)
if instance then
  local ok, result = pcall(function() return instance:setVolume(nil) end)
  print("SoundPool:setVolume ->", ok, result)
end

--@api-stub: SoundPool:setBus
-- Routes all voices through the named bus.
-- Call when you need to assign bus.
-- Build a SoundPool via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSoundPool(...)
if instance then
  local ok, result = pcall(function() return instance:setBus("sfx/click.ogg") end)
  print("SoundPool:setBus ->", ok, result)
end

--@api-stub: SoundPool:release
-- Releases all voices from the mixer and invalidates this pool.
-- Call when you need to invoke release.
-- Build a SoundPool via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSoundPool(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("SoundPool:release ->", ok, result)
end

--@api-stub: SoundPool:getVoiceCount
-- Returns the total number of voices in this pool.
-- Call when you need to read voice count.
-- Build a SoundPool via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSoundPool(...)
if instance then
  local ok, result = pcall(function() return instance:getVoiceCount() end)
  print("SoundPool:getVoiceCount ->", ok, result)
end

--@api-stub: SoundPool:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a SoundPool via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSoundPool(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("SoundPool:type ->", ok, result)
end

--@api-stub: SoundPool:typeOf
-- Returns true if the type name matches.
-- Call when you need to invoke type of.
-- Build a SoundPool via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newSoundPool(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("sfx/click.ogg") end)
  print("SoundPool:typeOf ->", ok, result)
end

-- ── Decoder methods ──

--@api-stub: Decoder:decode
-- Decodes the next chunk of samples, or nil at EOF.
-- Call when you need to invoke decode.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:decode() end)
  print("Decoder:decode ->", ok, result)
end

--@api-stub: Decoder:getChannelCount
-- Returns the number of audio channels.
-- Call when you need to read channel count.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:getChannelCount() end)
  print("Decoder:getChannelCount ->", ok, result)
end

--@api-stub: Decoder:getBitDepth
-- Returns the per-sample bit depth of this decoded audio stream.
-- Call when you need to read bit depth.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:getBitDepth() end)
  print("Decoder:getBitDepth ->", ok, result)
end

--@api-stub: Decoder:getSampleRate
-- Returns the sample rate in Hz.
-- Call when you need to read sample rate.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:getSampleRate() end)
  print("Decoder:getSampleRate ->", ok, result)
end

--@api-stub: Decoder:getDuration
-- Returns the total duration in seconds.
-- Call when you need to read duration.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:getDuration() end)
  print("Decoder:getDuration ->", ok, result)
end

--@api-stub: Decoder:seek
-- Seeks to a time offset in seconds.
-- Call when you need to invoke seek.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:seek(nil) end)
  print("Decoder:seek ->", ok, result)
end

--@api-stub: Decoder:rewind
-- Rewinds to the beginning.
-- Call when you need to invoke rewind.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:rewind() end)
  print("Decoder:rewind ->", ok, result)
end

--@api-stub: Decoder:tell
-- Returns the current position in seconds.
-- Call when you need to invoke tell.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:tell() end)
  print("Decoder:tell ->", ok, result)
end

--@api-stub: Decoder:isSeekable
-- Returns true if seeking is supported.
-- Call when you need to check is seekable.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:isSeekable() end)
  print("Decoder:isSeekable ->", ok, result)
end

--@api-stub: Decoder:release
-- Releases the decoder (no-op).
-- Call when you need to invoke release.
-- Build a Decoder via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newDecoder(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("Decoder:release ->", ok, result)
end

-- ── mlua methods ──

--@api-stub: mlua:getSampleCount
-- Get the total number of samples.
-- Call when you need to read sample count.
-- Build a mlua via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getSampleCount() end)
  print("mlua:getSampleCount ->", ok, result)
end

--@api-stub: mlua:getSampleRate
-- Get the sample rate.
-- Call when you need to read sample rate.
-- Build a mlua via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getSampleRate() end)
  print("mlua:getSampleRate ->", ok, result)
end

--@api-stub: mlua:getChannelCount
-- Get the number of channels.
-- Call when you need to read channel count.
-- Build a mlua via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getChannelCount() end)
  print("mlua:getChannelCount ->", ok, result)
end

--@api-stub: mlua:getDuration
-- Get the audio duration in seconds.
-- Call when you need to read duration.
-- Build a mlua via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getDuration() end)
  print("mlua:getDuration ->", ok, result)
end

--@api-stub: mlua:getBitDepth
-- Get the bit depth.
-- Call when you need to read bit depth.
-- Build a mlua via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getBitDepth() end)
  print("mlua:getBitDepth ->", ok, result)
end

--@api-stub: mlua:getSample
-- Get a specific sample by index.
-- Call when you need to read sample.
-- Build a mlua via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getSample(1) end)
  print("mlua:getSample ->", ok, result)
end

--@api-stub: mlua:setSample
-- Set a specific sample by index.
-- Call when you need to assign sample.
-- Build a mlua via the appropriate lurek.audio.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.audio.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:setSample(1, nil) end)
  print("mlua:setSample ->", ok, result)
end

