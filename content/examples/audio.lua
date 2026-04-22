-- content/examples/audio.lua
-- Scaffolded coverage of the lurek.audio API (212 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/audio_api.rs   (Lua binding, arg types, return shape)
--   * src/audio/                 (semantics, side effects)
--   * docs/specs/audio.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/audio.lua

-- ── lurek.audio.* functions ──

--@api-stub: lurek.audio.newSource
-- Loads an audio file and returns a Source handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newSource
  local _todo = "TODO: write a real lurek.audio.newSource usage example"
  print(_todo)
end

--@api-stub: lurek.audio.play
-- Plays a source, with optional bus routing via options table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.play
  local _todo = "TODO: write a real lurek.audio.play usage example"
  print(_todo)
end

--@api-stub: lurek.audio.stop
-- Stops playback and resets seek position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.stop
  local _todo = "TODO: write a real lurek.audio.stop usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setVolume
-- Sets source playback volume.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setVolume
  local _todo = "TODO: write a real lurek.audio.setVolume usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getVolume
-- Returns the source volume.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getVolume
  local _todo = "TODO: write a real lurek.audio.getVolume usage example"
  print(_todo)
end

--@api-stub: lurek.audio.pause
-- Pauses playback at the current position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.pause
  local _todo = "TODO: write a real lurek.audio.pause usage example"
  print(_todo)
end

--@api-stub: lurek.audio.resume
-- Resumes playback from pause.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.resume
  local _todo = "TODO: write a real lurek.audio.resume usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setPitch
-- Sets source pitch multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setPitch
  local _todo = "TODO: write a real lurek.audio.setPitch usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getPitch
-- Returns the source pitch multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getPitch
  local _todo = "TODO: write a real lurek.audio.getPitch usage example"
  print(_todo)
end

--@api-stub: lurek.audio.isPlaying
-- Returns true if the source is playing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.isPlaying
  local _todo = "TODO: write a real lurek.audio.isPlaying usage example"
  print(_todo)
end

--@api-stub: lurek.audio.isPaused
-- Returns true if the source is paused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.isPaused
  local _todo = "TODO: write a real lurek.audio.isPaused usage example"
  print(_todo)
end

--@api-stub: lurek.audio.isStopped
-- Returns true if the source is stopped.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.isStopped
  local _todo = "TODO: write a real lurek.audio.isStopped usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setLooping
-- Enables or disables looping.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setLooping
  local _todo = "TODO: write a real lurek.audio.setLooping usage example"
  print(_todo)
end

--@api-stub: lurek.audio.isLooping
-- Returns true if looping is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.isLooping
  local _todo = "TODO: write a real lurek.audio.isLooping usage example"
  print(_todo)
end

--@api-stub: lurek.audio.playLooping
-- Plays the source in a continuous loop.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.playLooping
  local _todo = "TODO: write a real lurek.audio.playLooping usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setPan
-- Sets stereo panning (-1.0 left to 1.0 right).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setPan
  local _todo = "TODO: write a real lurek.audio.setPan usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getPan
-- Returns the source stereo panning.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getPan
  local _todo = "TODO: write a real lurek.audio.getPan usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setMasterVolume
-- Sets the global master volume.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setMasterVolume
  local _todo = "TODO: write a real lurek.audio.setMasterVolume usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getMasterVolume
-- Returns the global master volume.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getMasterVolume
  local _todo = "TODO: write a real lurek.audio.getMasterVolume usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getActiveSourceCount
-- Returns the number of currently playing sources.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getActiveSourceCount
  local _todo = "TODO: write a real lurek.audio.getActiveSourceCount usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getSourceCount
-- Returns the total number of registered sources.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getSourceCount
  local _todo = "TODO: write a real lurek.audio.getSourceCount usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getSourceType
-- Returns the type string ("static" or "stream") of a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getSourceType
  local _todo = "TODO: write a real lurek.audio.getSourceType usage example"
  print(_todo)
end

--@api-stub: lurek.audio.clone
-- Creates an independent copy of a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.clone
  local _todo = "TODO: write a real lurek.audio.clone usage example"
  print(_todo)
end

--@api-stub: lurek.audio.pauseAll
-- Pauses all currently playing sources.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.pauseAll
  local _todo = "TODO: write a real lurek.audio.pauseAll usage example"
  print(_todo)
end

--@api-stub: lurek.audio.stopAll
-- Stops all currently playing sources.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.stopAll
  local _todo = "TODO: write a real lurek.audio.stopAll usage example"
  print(_todo)
end

--@api-stub: lurek.audio.resumeAll
-- Resumes all paused sources.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.resumeAll
  local _todo = "TODO: write a real lurek.audio.resumeAll usage example"
  print(_todo)
end

--@api-stub: lurek.audio.release
-- Releases a source and frees its memory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.release
  local _todo = "TODO: write a real lurek.audio.release usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newBus
-- Creates a named audio bus for grouping sources.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newBus
  local _todo = "TODO: write a real lurek.audio.newBus usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setSourceBus
-- Assigns a source to a bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setSourceBus
  local _todo = "TODO: write a real lurek.audio.setSourceBus usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getSourceBus
-- Returns the bus a source is assigned to, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getSourceBus
  local _todo = "TODO: write a real lurek.audio.getSourceBus usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getMaxSources
-- Returns the maximum number of simultaneous sources.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getMaxSources
  local _todo = "TODO: write a real lurek.audio.getMaxSources usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getDuration
-- Returns the total duration of a source in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getDuration
  local _todo = "TODO: write a real lurek.audio.getDuration usage example"
  print(_todo)
end

--@api-stub: lurek.audio.tell
-- Returns the current playback position in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.tell
  local _todo = "TODO: write a real lurek.audio.tell usage example"
  print(_todo)
end

--@api-stub: lurek.audio.seek
-- Seeks to a time position in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.seek
  local _todo = "TODO: write a real lurek.audio.seek usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setLowpass
-- Applies a low-pass filter to a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setLowpass
  local _todo = "TODO: write a real lurek.audio.setLowpass usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setHighpass
-- Applies a high-pass filter to a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setHighpass
  local _todo = "TODO: write a real lurek.audio.setHighpass usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getLowpass
-- Returns the low-pass filter cutoff of a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getLowpass
  local _todo = "TODO: write a real lurek.audio.getLowpass usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getHighpass
-- Returns the high-pass filter cutoff of a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getHighpass
  local _todo = "TODO: write a real lurek.audio.getHighpass usage example"
  print(_todo)
end

--@api-stub: lurek.audio.clearFilter
-- Removes any active filter from a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.clearFilter
  local _todo = "TODO: write a real lurek.audio.clearFilter usage example"
  print(_todo)
end

--@api-stub: lurek.audio.fadeIn
-- Fades a source in from silence over the given duration.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.fadeIn
  local _todo = "TODO: write a real lurek.audio.fadeIn usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getFadeIn
-- Returns the fade-in duration of a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getFadeIn
  local _todo = "TODO: write a real lurek.audio.getFadeIn usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setListener2D
-- Sets the 2D listener position for spatial audio.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setListener2D
  local _todo = "TODO: write a real lurek.audio.setListener2D usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getListener2D
-- Returns the 2D listener position (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getListener2D
  local _todo = "TODO: write a real lurek.audio.getListener2D usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setListener
-- Sets the 3D listener position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setListener
  local _todo = "TODO: write a real lurek.audio.setListener usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getListener
-- Returns the 3D listener position (x, y, z).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getListener
  local _todo = "TODO: write a real lurek.audio.getListener usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setPosition
-- Sets the 3D position of a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setPosition
  local _todo = "TODO: write a real lurek.audio.setPosition usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getPosition
-- Returns the 3D position of a source (x, y, z).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getPosition
  local _todo = "TODO: write a real lurek.audio.getPosition usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setVelocity
-- Sets the velocity of a source for Doppler.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setVelocity
  local _todo = "TODO: write a real lurek.audio.setVelocity usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getVelocity
-- Returns the velocity of a source (x, y, z).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getVelocity
  local _todo = "TODO: write a real lurek.audio.getVelocity usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setOrientation
-- Sets the 6-component orientation of a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setOrientation
  local _todo = "TODO: write a real lurek.audio.setOrientation usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getOrientation
-- Returns the 6-component orientation of a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getOrientation
  local _todo = "TODO: write a real lurek.audio.getOrientation usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setDopplerScale
-- Sets the global Doppler effect scale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setDopplerScale
  local _todo = "TODO: write a real lurek.audio.setDopplerScale usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getDopplerScale
-- Returns the current Doppler scale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getDopplerScale
  local _todo = "TODO: write a real lurek.audio.getDopplerScale usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setDistanceModel
-- Sets the distance attenuation model.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setDistanceModel
  local _todo = "TODO: write a real lurek.audio.setDistanceModel usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getDistanceModel
-- Returns the current distance model name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getDistanceModel
  local _todo = "TODO: write a real lurek.audio.getDistanceModel usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setMeter
-- Sets the master peak meter level (0.0â€“1.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setMeter
  local _todo = "TODO: write a real lurek.audio.setMeter usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getMeter
-- Returns the stored master peak meter level.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getMeter
  local _todo = "TODO: write a real lurek.audio.getMeter usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newMidiPlayer
-- Creates a MIDI player, optionally loading a file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newMidiPlayer
  local _todo = "TODO: write a real lurek.audio.newMidiPlayer usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newSoundData
-- Creates a SoundData from a file or as a silent buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newSoundData
  local _todo = "TODO: write a real lurek.audio.newSoundData usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setMidiSoundFont
-- Sets the global SoundFont for MIDI synthesis.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setMidiSoundFont
  local _todo = "TODO: write a real lurek.audio.setMidiSoundFont usage example"
  print(_todo)
end

--@api-stub: lurek.audio.hasMidiSoundFont
-- Returns true if a SoundFont is loaded.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.hasMidiSoundFont
  local _todo = "TODO: write a real lurek.audio.hasMidiSoundFont usage example"
  print(_todo)
end

--@api-stub: lurek.audio.clearMidiSoundFont
-- Unloads the active SoundFont.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.clearMidiSoundFont
  local _todo = "TODO: write a real lurek.audio.clearMidiSoundFont usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newDecoder
-- Creates a streaming audio decoder.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newDecoder
  local _todo = "TODO: write a real lurek.audio.newDecoder usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newQueueableSource
-- Creates a queueable source for manual PCM buffering.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newQueueableSource
  local _todo = "TODO: write a real lurek.audio.newQueueableSource usage example"
  print(_todo)
end

--@api-stub: lurek.audio.queueSource
-- Pushes a SoundData buffer into a queueable source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.queueSource
  local _todo = "TODO: write a real lurek.audio.queueSource usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getFreeBufferCount
-- Returns the free buffer slots in a queueable source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getFreeBufferCount
  local _todo = "TODO: write a real lurek.audio.getFreeBufferCount usage example"
  print(_todo)
end

--@api-stub: lurek.audio.playQueueable
-- Starts playback of a queueable source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.playQueueable
  local _todo = "TODO: write a real lurek.audio.playQueueable usage example"
  print(_todo)
end

--@api-stub: lurek.audio.stopQueueable
-- Stops a queueable source and drains its buffers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.stopQueueable
  local _todo = "TODO: write a real lurek.audio.stopQueueable usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getPlaybackDevices
-- Returns a table of available audio output device names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getPlaybackDevices
  local _todo = "TODO: write a real lurek.audio.getPlaybackDevices usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getPlaybackDevice
-- Returns the current audio output device name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getPlaybackDevice
  local _todo = "TODO: write a real lurek.audio.getPlaybackDevice usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setPlaybackDevice
-- Selects an audio output device by name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setPlaybackDevice
  local _todo = "TODO: write a real lurek.audio.setPlaybackDevice usage example"
  print(_todo)
end

--@api-stub: lurek.audio.create_bus
-- Creates a bus by name (functional style).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.create_bus
  local _todo = "TODO: write a real lurek.audio.create_bus usage example"
  print(_todo)
end

--@api-stub: lurek.audio.set_bus_volume
-- Sets a bus volume by name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.set_bus_volume
  local _todo = "TODO: write a real lurek.audio.set_bus_volume usage example"
  print(_todo)
end

--@api-stub: lurek.audio.add_effect
-- Adds a DSP effect to a bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.add_effect
  local _todo = "TODO: write a real lurek.audio.add_effect usage example"
  print(_todo)
end

--@api-stub: lurek.audio.remove_effect
-- Removes a DSP effect from a bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.remove_effect
  local _todo = "TODO: write a real lurek.audio.remove_effect usage example"
  print(_todo)
end

--@api-stub: lurek.audio.set_effect_param
-- Sets a parameter on a DSP effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.set_effect_param
  local _todo = "TODO: write a real lurek.audio.set_effect_param usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newSineWave
-- Generate a mono sine-wave SoundData buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newSineWave
  local _todo = "TODO: write a real lurek.audio.newSineWave usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newSquareWave
-- Generate a mono square-wave SoundData buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newSquareWave
  local _todo = "TODO: write a real lurek.audio.newSquareWave usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newSawtoothWave
-- Generate a mono sawtooth-wave SoundData buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newSawtoothWave
  local _todo = "TODO: write a real lurek.audio.newSawtoothWave usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newTriangleWave
-- Generate a mono triangle-wave SoundData buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newTriangleWave
  local _todo = "TODO: write a real lurek.audio.newTriangleWave usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newWhiteNoise
-- Generate a reproducible white-noise SoundData buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newWhiteNoise
  local _todo = "TODO: write a real lurek.audio.newWhiteNoise usage example"
  print(_todo)
end

--@api-stub: lurek.audio.applyLowpass
-- Applies a first-order IIR low-pass filter to a SoundData in-place.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.applyLowpass
  local _todo = "TODO: write a real lurek.audio.applyLowpass usage example"
  print(_todo)
end

--@api-stub: lurek.audio.applyHighpass
-- Applies a first-order IIR high-pass filter to a SoundData in-place.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.applyHighpass
  local _todo = "TODO: write a real lurek.audio.applyHighpass usage example"
  print(_todo)
end

--@api-stub: lurek.audio.applyBandpass
-- Applies a bandpass filter (high-pass then low-pass) to a SoundData in-place.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.applyBandpass
  local _todo = "TODO: write a real lurek.audio.applyBandpass usage example"
  print(_todo)
end

--@api-stub: lurek.audio.applyGain
-- Scales every sample by gain (clamped to [-1, 1]).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.applyGain
  local _todo = "TODO: write a real lurek.audio.applyGain usage example"
  print(_todo)
end

--@api-stub: lurek.audio.mixInto
-- Additively mixes another SoundData into the destination in-place.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.mixInto
  local _todo = "TODO: write a real lurek.audio.mixInto usage example"
  print(_todo)
end

--@api-stub: lurek.audio.saveWAV
-- Saves a SoundData as a 16-bit PCM WAV file at the given path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.saveWAV
  local _todo = "TODO: write a real lurek.audio.saveWAV usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setStereoWidth
-- Sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setStereoWidth
  local _todo = "TODO: write a real lurek.audio.setStereoWidth usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getStereoWidth
-- Returns the current stereo width for a source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getStereoWidth
  local _todo = "TODO: write a real lurek.audio.getStereoWidth usage example"
  print(_todo)
end

--@api-stub: lurek.audio.setRandomPitch
-- Sets a random pitch range applied each time the source is played.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.setRandomPitch
  local _todo = "TODO: write a real lurek.audio.setRandomPitch usage example"
  print(_todo)
end

--@api-stub: lurek.audio.clearRandomPitch
-- Clears any random pitch range on a source, restoring fixed pitch.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.clearRandomPitch
  local _todo = "TODO: write a real lurek.audio.clearRandomPitch usage example"
  print(_todo)
end

--@api-stub: lurek.audio.crossfade
-- Crossfades from one source to another over a duration.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.crossfade
  local _todo = "TODO: write a real lurek.audio.crossfade usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getBusPeak
-- Returns the peak signal level of the named bus (stub: always 0.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getBusPeak
  local _todo = "TODO: write a real lurek.audio.getBusPeak usage example"
  print(_todo)
end

--@api-stub: lurek.audio.getBusRms
-- Returns the RMS signal level of the named bus (stub: always 0.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.getBusRms
  local _todo = "TODO: write a real lurek.audio.getBusRms usage example"
  print(_todo)
end

--@api-stub: lurek.audio.newPool
-- Creates a polyphonic sound pool for the given file with N simultaneous voices.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.newPool
  local _todo = "TODO: write a real lurek.audio.newPool usage example"
  print(_todo)
end

--@api-stub: lurek.audio.processOffline
-- Applies a DSP effect chain to a WAV file and writes output.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.processOffline
  local _todo = "TODO: write a real lurek.audio.processOffline usage example"
  print(_todo)
end

--@api-stub: lurek.audio.normalizeFile
-- Normalizes a WAV file peak amplitude to target_level and writes output.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.normalizeFile
  local _todo = "TODO: write a real lurek.audio.normalizeFile usage example"
  print(_todo)
end

--@api-stub: lurek.audio.waveformToPng
-- Renders the waveform of a WAV file to a PNG image.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.waveformToPng
  local _todo = "TODO: write a real lurek.audio.waveformToPng usage example"
  print(_todo)
end

--@api-stub: lurek.audio.spectrogramToPng
-- Renders a time-frequency spectrogram of a WAV file to a PNG image.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: lurek.audio.spectrogramToPng
  local _todo = "TODO: write a real lurek.audio.spectrogramToPng usage example"
  print(_todo)
end

-- ── Source methods ──

--@api-stub: Source:play
-- Starts or resumes playback.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:play
  local _todo = "TODO: write a real Source:play usage example"
  print(_todo)
end

--@api-stub: Source:stop
-- Stops playback and resets seek position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:stop
  local _todo = "TODO: write a real Source:stop usage example"
  print(_todo)
end

--@api-stub: Source:pause
-- Pauses playback at the current position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:pause
  local _todo = "TODO: write a real Source:pause usage example"
  print(_todo)
end

--@api-stub: Source:resume
-- Resumes playback from the paused position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:resume
  local _todo = "TODO: write a real Source:resume usage example"
  print(_todo)
end

--@api-stub: Source:setVolume
-- Sets playback volume (0.0 = silent, 1.0 = full).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:setVolume
  local _todo = "TODO: write a real Source:setVolume usage example"
  print(_todo)
end

--@api-stub: Source:getVolume
-- Returns the current volume multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:getVolume
  local _todo = "TODO: write a real Source:getVolume usage example"
  print(_todo)
end

--@api-stub: Source:setPitch
-- Sets the pitch multiplier (1.0 = normal).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:setPitch
  local _todo = "TODO: write a real Source:setPitch usage example"
  print(_todo)
end

--@api-stub: Source:getPitch
-- Returns the current pitch multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:getPitch
  local _todo = "TODO: write a real Source:getPitch usage example"
  print(_todo)
end

--@api-stub: Source:setLooping
-- Enables or disables looping playback.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:setLooping
  local _todo = "TODO: write a real Source:setLooping usage example"
  print(_todo)
end

--@api-stub: Source:isLooping
-- Returns true if looping is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:isLooping
  local _todo = "TODO: write a real Source:isLooping usage example"
  print(_todo)
end

--@api-stub: Source:isPlaying
-- Returns true if currently playing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:isPlaying
  local _todo = "TODO: write a real Source:isPlaying usage example"
  print(_todo)
end

--@api-stub: Source:isPaused
-- Returns true if playback is paused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:isPaused
  local _todo = "TODO: write a real Source:isPaused usage example"
  print(_todo)
end

--@api-stub: Source:isStopped
-- Returns true if playback has stopped.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:isStopped
  local _todo = "TODO: write a real Source:isStopped usage example"
  print(_todo)
end

--@api-stub: Source:setPan
-- Sets stereo panning (-1.0 left to 1.0 right).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:setPan
  local _todo = "TODO: write a real Source:setPan usage example"
  print(_todo)
end

--@api-stub: Source:getPan
-- Returns the current stereo panning value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:getPan
  local _todo = "TODO: write a real Source:getPan usage example"
  print(_todo)
end

--@api-stub: Source:clone
-- Creates an independent copy of this source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:clone
  local _todo = "TODO: write a real Source:clone usage example"
  print(_todo)
end

--@api-stub: Source:getType
-- Returns the source type ("static" or "stream").
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:getType
  local _todo = "TODO: write a real Source:getType usage example"
  print(_todo)
end

--@api-stub: Source:getDuration
-- Returns the total duration in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:getDuration
  local _todo = "TODO: write a real Source:getDuration usage example"
  print(_todo)
end

--@api-stub: Source:tell
-- Returns the current playback position in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:tell
  local _todo = "TODO: write a real Source:tell usage example"
  print(_todo)
end

--@api-stub: Source:seek
-- Seeks to a time position in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:seek
  local _todo = "TODO: write a real Source:seek usage example"
  print(_todo)
end

--@api-stub: Source:setLowpass
-- Applies a low-pass filter at the given cutoff frequency.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:setLowpass
  local _todo = "TODO: write a real Source:setLowpass usage example"
  print(_todo)
end

--@api-stub: Source:setHighpass
-- Applies a high-pass filter at the given cutoff frequency.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:setHighpass
  local _todo = "TODO: write a real Source:setHighpass usage example"
  print(_todo)
end

--@api-stub: Source:getLowpass
-- Returns the low-pass filter cutoff frequency.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:getLowpass
  local _todo = "TODO: write a real Source:getLowpass usage example"
  print(_todo)
end

--@api-stub: Source:getHighpass
-- Returns the high-pass filter cutoff frequency.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:getHighpass
  local _todo = "TODO: write a real Source:getHighpass usage example"
  print(_todo)
end

--@api-stub: Source:clearFilter
-- Removes any active filter from this source.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:clearFilter
  local _todo = "TODO: write a real Source:clearFilter usage example"
  print(_todo)
end

--@api-stub: Source:fadeIn
-- Fades in from silence over the given duration in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:fadeIn
  local _todo = "TODO: write a real Source:fadeIn usage example"
  print(_todo)
end

--@api-stub: Source:getFadeIn
-- Returns the current fade-in duration in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Source:getFadeIn
  local _todo = "TODO: write a real Source:getFadeIn usage example"
  print(_todo)
end

-- ── Bus methods ──

--@api-stub: Bus:getName
-- Returns the unique name string assigned to this audio bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:getName
  local _todo = "TODO: write a real Bus:getName usage example"
  print(_todo)
end

--@api-stub: Bus:setVolume
-- Sets the volume for all sources on this bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:setVolume
  local _todo = "TODO: write a real Bus:setVolume usage example"
  print(_todo)
end

--@api-stub: Bus:getVolume
-- Returns the current volume multiplier applied to all sources on this bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:getVolume
  local _todo = "TODO: write a real Bus:getVolume usage example"
  print(_todo)
end

--@api-stub: Bus:setPitch
-- Sets the pitch multiplier for all sources on this bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:setPitch
  local _todo = "TODO: write a real Bus:setPitch usage example"
  print(_todo)
end

--@api-stub: Bus:getPitch
-- Returns the bus pitch multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:getPitch
  local _todo = "TODO: write a real Bus:getPitch usage example"
  print(_todo)
end

--@api-stub: Bus:pause
-- Pauses all sources on this bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:pause
  local _todo = "TODO: write a real Bus:pause usage example"
  print(_todo)
end

--@api-stub: Bus:resume
-- Resumes all sources on this bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:resume
  local _todo = "TODO: write a real Bus:resume usage example"
  print(_todo)
end

--@api-stub: Bus:isPaused
-- Returns true if this bus is paused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:isPaused
  local _todo = "TODO: write a real Bus:isPaused usage example"
  print(_todo)
end

--@api-stub: Bus:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:type
  local _todo = "TODO: write a real Bus:type usage example"
  print(_todo)
end

--@api-stub: Bus:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:typeOf
  local _todo = "TODO: write a real Bus:typeOf usage example"
  print(_todo)
end

--@api-stub: Bus:clearDuck
-- Removes the ducking target from this bus, restoring the target bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:clearDuck
  local _todo = "TODO: write a real Bus:clearDuck usage example"
  print(_todo)
end

--@api-stub: Bus:getPeak
-- Returns the average peak amplitude of all sources currently on this bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Bus:getPeak
  local _todo = "TODO: write a real Bus:getPeak usage example"
  print(_todo)
end

-- ── MidiPlayer methods ──

--@api-stub: MidiPlayer:load
-- Loads a MIDI file from the given path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:load
  local _todo = "TODO: write a real MidiPlayer:load usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:loadData
-- Loads MIDI data from a Lua string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:loadData
  local _todo = "TODO: write a real MidiPlayer:loadData usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:isLoaded
-- Returns true if a MIDI sequence is loaded.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:isLoaded
  local _todo = "TODO: write a real MidiPlayer:isLoaded usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getFilePath
-- Returns the file path of the loaded MIDI, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getFilePath
  local _todo = "TODO: write a real MidiPlayer:getFilePath usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setSoundFont
-- Loads a SoundFont file into this player (stub).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setSoundFont
  local _todo = "TODO: write a real MidiPlayer:setSoundFont usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getSoundFontPath
-- Returns the SoundFont file path, or nil (stub).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getSoundFontPath
  local _todo = "TODO: write a real MidiPlayer:getSoundFontPath usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:useDefaultSoundFont
-- Reverts to the built-in default SoundFont (stub).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:useDefaultSoundFont
  local _todo = "TODO: write a real MidiPlayer:useDefaultSoundFont usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:play
-- Starts or resumes MIDI sequence playback from the current position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:play
  local _todo = "TODO: write a real MidiPlayer:play usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:pause
-- Pauses the MIDI sequence at the current position; resume with `play()`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:pause
  local _todo = "TODO: write a real MidiPlayer:pause usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:stop
-- Stops MIDI playback and resets the playhead to the beginning.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:stop
  local _todo = "TODO: write a real MidiPlayer:stop usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:isPlaying
-- Returns true if MIDI is currently playing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:isPlaying
  local _todo = "TODO: write a real MidiPlayer:isPlaying usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:isPaused
-- Returns true if MIDI playback is paused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:isPaused
  local _todo = "TODO: write a real MidiPlayer:isPaused usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:seek
-- Seeks to a time position in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:seek
  local _todo = "TODO: write a real MidiPlayer:seek usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:tell
-- Returns the current playback position in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:tell
  local _todo = "TODO: write a real MidiPlayer:tell usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getDuration
-- Returns the total MIDI duration in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getDuration
  local _todo = "TODO: write a real MidiPlayer:getDuration usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setLooping
-- Enables or disables looping.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setLooping
  local _todo = "TODO: write a real MidiPlayer:setLooping usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:isLooping
-- Returns true if looping is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:isLooping
  local _todo = "TODO: write a real MidiPlayer:isLooping usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setVolume
-- Sets MIDI playback volume.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setVolume
  local _todo = "TODO: write a real MidiPlayer:setVolume usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getVolume
-- Returns the current MIDI volume.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getVolume
  local _todo = "TODO: write a real MidiPlayer:getVolume usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setBus
-- Routes MIDI output through a bus (or nil to clear).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setBus
  local _todo = "TODO: write a real MidiPlayer:setBus usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getBus
-- Returns the assigned bus, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getBus
  local _todo = "TODO: write a real MidiPlayer:getBus usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setTempo
-- Sets playback tempo in BPM.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setTempo
  local _todo = "TODO: write a real MidiPlayer:setTempo usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getTempo
-- Returns the current tempo in BPM.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getTempo
  local _todo = "TODO: write a real MidiPlayer:getTempo usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getOriginalTempo
-- Returns the original MIDI file tempo in BPM.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getOriginalTempo
  local _todo = "TODO: write a real MidiPlayer:getOriginalTempo usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setTempoScale
-- Sets the tempo scale factor (1.0 = original speed).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setTempoScale
  local _todo = "TODO: write a real MidiPlayer:setTempoScale usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getTempoScale
-- Returns the current tempo scale factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getTempoScale
  local _todo = "TODO: write a real MidiPlayer:getTempoScale usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getTicksPerBeat
-- Returns the PPQ resolution from the MIDI header.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getTicksPerBeat
  local _todo = "TODO: write a real MidiPlayer:getTicksPerBeat usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setChannelVolume
-- Sets volume for a MIDI channel (1-indexed).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setChannelVolume
  local _todo = "TODO: write a real MidiPlayer:setChannelVolume usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getChannelVolume
-- Returns the volume for a MIDI channel (1-indexed).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getChannelVolume
  local _todo = "TODO: write a real MidiPlayer:getChannelVolume usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setChannelMuted
-- Mutes or unmutes a MIDI channel (1-indexed).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setChannelMuted
  local _todo = "TODO: write a real MidiPlayer:setChannelMuted usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:isChannelMuted
-- Returns true if a MIDI channel is muted (1-indexed).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:isChannelMuted
  local _todo = "TODO: write a real MidiPlayer:isChannelMuted usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getChannelInstrument
-- Returns the GM instrument for a MIDI channel (1-indexed).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getChannelInstrument
  local _todo = "TODO: write a real MidiPlayer:getChannelInstrument usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getChannelCount
-- Returns the number of MIDI channels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getChannelCount
  local _todo = "TODO: write a real MidiPlayer:getChannelCount usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:soloChannel
-- Solos a MIDI channel (1-indexed).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:soloChannel
  local _todo = "TODO: write a real MidiPlayer:soloChannel usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:unsoloAll
-- Clears solo on all channels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:unsoloAll
  local _todo = "TODO: write a real MidiPlayer:unsoloAll usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getTrackCount
-- Returns the number of tracks in the MIDI sequence.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getTrackCount
  local _todo = "TODO: write a real MidiPlayer:getTrackCount usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getTrackName
-- Returns the name of a MIDI track (1-indexed), or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getTrackName
  local _todo = "TODO: write a real MidiPlayer:getTrackName usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setTrackMuted
-- Mutes or unmutes a track (1-indexed).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setTrackMuted
  local _todo = "TODO: write a real MidiPlayer:setTrackMuted usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:isTrackMuted
-- Returns true if a track is muted (1-indexed).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:isTrackMuted
  local _todo = "TODO: write a real MidiPlayer:isTrackMuted usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getNoteCount
-- Returns the total note count in the MIDI sequence.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getNoteCount
  local _todo = "TODO: write a real MidiPlayer:getNoteCount usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setOnNoteOn
-- Registers a note-on callback (stub).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setOnNoteOn
  local _todo = "TODO: write a real MidiPlayer:setOnNoteOn usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setOnNoteOff
-- Registers a note-off callback (stub).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setOnNoteOff
  local _todo = "TODO: write a real MidiPlayer:setOnNoteOff usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setOnEnd
-- Registers a playback-end callback (stub).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setOnEnd
  local _todo = "TODO: write a real MidiPlayer:setOnEnd usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getSampleRate
-- Returns the PCM output sample rate in Hz.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getSampleRate
  local _todo = "TODO: write a real MidiPlayer:getSampleRate usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setSampleRate
-- Sets the PCM output sample rate in Hz (clamped 8000â€“192000).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setSampleRate
  local _todo = "TODO: write a real MidiPlayer:setSampleRate usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:getChannels
-- Returns the PCM output channel count (1 = mono, 2 = stereo).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:getChannels
  local _todo = "TODO: write a real MidiPlayer:getChannels usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:setChannels
-- Sets the PCM output channel count (clamped 1â€“2).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:setChannels
  local _todo = "TODO: write a real MidiPlayer:setChannels usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:type
  local _todo = "TODO: write a real MidiPlayer:type usage example"
  print(_todo)
end

--@api-stub: MidiPlayer:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: MidiPlayer:typeOf
  local _todo = "TODO: write a real MidiPlayer:typeOf usage example"
  print(_todo)
end

-- ── SoundPool methods ──

--@api-stub: SoundPool:play
-- Plays the next available voice and returns its SoundKey as an integer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: SoundPool:play
  local _todo = "TODO: write a real SoundPool:play usage example"
  print(_todo)
end

--@api-stub: SoundPool:stopAll
-- Stops all voices in this pool.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: SoundPool:stopAll
  local _todo = "TODO: write a real SoundPool:stopAll usage example"
  print(_todo)
end

--@api-stub: SoundPool:setVolume
-- Sets the volume for all voices in this pool.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: SoundPool:setVolume
  local _todo = "TODO: write a real SoundPool:setVolume usage example"
  print(_todo)
end

--@api-stub: SoundPool:setBus
-- Routes all voices through the named bus.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: SoundPool:setBus
  local _todo = "TODO: write a real SoundPool:setBus usage example"
  print(_todo)
end

--@api-stub: SoundPool:release
-- Releases all voices from the mixer and invalidates this pool.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: SoundPool:release
  local _todo = "TODO: write a real SoundPool:release usage example"
  print(_todo)
end

--@api-stub: SoundPool:getVoiceCount
-- Returns the total number of voices in this pool.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: SoundPool:getVoiceCount
  local _todo = "TODO: write a real SoundPool:getVoiceCount usage example"
  print(_todo)
end

--@api-stub: SoundPool:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: SoundPool:type
  local _todo = "TODO: write a real SoundPool:type usage example"
  print(_todo)
end

--@api-stub: SoundPool:typeOf
-- Returns true if the type name matches.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: SoundPool:typeOf
  local _todo = "TODO: write a real SoundPool:typeOf usage example"
  print(_todo)
end

-- ── Decoder methods ──

--@api-stub: Decoder:decode
-- Decodes the next chunk of samples, or nil at EOF.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:decode
  local _todo = "TODO: write a real Decoder:decode usage example"
  print(_todo)
end

--@api-stub: Decoder:getChannelCount
-- Returns the number of audio channels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:getChannelCount
  local _todo = "TODO: write a real Decoder:getChannelCount usage example"
  print(_todo)
end

--@api-stub: Decoder:getBitDepth
-- Returns the per-sample bit depth of this decoded audio stream.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:getBitDepth
  local _todo = "TODO: write a real Decoder:getBitDepth usage example"
  print(_todo)
end

--@api-stub: Decoder:getSampleRate
-- Returns the sample rate in Hz.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:getSampleRate
  local _todo = "TODO: write a real Decoder:getSampleRate usage example"
  print(_todo)
end

--@api-stub: Decoder:getDuration
-- Returns the total duration in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:getDuration
  local _todo = "TODO: write a real Decoder:getDuration usage example"
  print(_todo)
end

--@api-stub: Decoder:seek
-- Seeks to a time offset in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:seek
  local _todo = "TODO: write a real Decoder:seek usage example"
  print(_todo)
end

--@api-stub: Decoder:rewind
-- Rewinds to the beginning.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:rewind
  local _todo = "TODO: write a real Decoder:rewind usage example"
  print(_todo)
end

--@api-stub: Decoder:tell
-- Returns the current position in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:tell
  local _todo = "TODO: write a real Decoder:tell usage example"
  print(_todo)
end

--@api-stub: Decoder:isSeekable
-- Returns true if seeking is supported.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:isSeekable
  local _todo = "TODO: write a real Decoder:isSeekable usage example"
  print(_todo)
end

--@api-stub: Decoder:release
-- Releases the decoder (no-op).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: Decoder:release
  local _todo = "TODO: write a real Decoder:release usage example"
  print(_todo)
end

-- ── mlua methods ──

--@api-stub: mlua:getSampleCount
-- Get the total number of samples.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: mlua:getSampleCount
  local _todo = "TODO: write a real mlua:getSampleCount usage example"
  print(_todo)
end

--@api-stub: mlua:getSampleRate
-- Get the sample rate.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: mlua:getSampleRate
  local _todo = "TODO: write a real mlua:getSampleRate usage example"
  print(_todo)
end

--@api-stub: mlua:getChannelCount
-- Get the number of channels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: mlua:getChannelCount
  local _todo = "TODO: write a real mlua:getChannelCount usage example"
  print(_todo)
end

--@api-stub: mlua:getDuration
-- Get the audio duration in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: mlua:getDuration
  local _todo = "TODO: write a real mlua:getDuration usage example"
  print(_todo)
end

--@api-stub: mlua:getBitDepth
-- Get the bit depth.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: mlua:getBitDepth
  local _todo = "TODO: write a real mlua:getBitDepth usage example"
  print(_todo)
end

--@api-stub: mlua:getSample
-- Get a specific sample by index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: mlua:getSample
  local _todo = "TODO: write a real mlua:getSample usage example"
  print(_todo)
end

--@api-stub: mlua:setSample
-- Set a specific sample by index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/audio_api.rs and docs/specs/audio.md).
do  -- TODO: mlua:setSample
  local _todo = "TODO: write a real mlua:setSample usage example"
  print(_todo)
end

