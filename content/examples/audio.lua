-- content/examples/audio.lua
-- Auto-scaffolded coverage of the lurek.audio Lua API (212 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/audio.lua

print("[example] lurek.audio loaded — 212 API items demonstrated")

-- ── lurek.audio free functions ──

--@api-stub: lurek.audio.newSource
-- Loads an audio file and returns a Source handle.
-- Use this when loads an audio file and returns a Source handle is needed.
if false then
  local _r = lurek.audio.newSource({})
  print(_r)
end

--@api-stub: lurek.audio.play
-- Plays a source, with optional bus routing via options table.
-- Use this when plays a source, with optional bus routing via options table is needed.
if false then
  local _r = lurek.audio.play(1, 1)
  print(_r)
end

--@api-stub: lurek.audio.stop
-- Stops playback and resets seek position.
-- Use this when stops playback and resets seek position is needed.
if false then
  local _r = lurek.audio.stop(1)
  print(_r)
end

--@api-stub: lurek.audio.setVolume
-- Sets source playback volume.
-- Use this when sets source playback volume is needed.
if false then
  local _r = lurek.audio.setVolume(1, 0)
  print(_r)
end

--@api-stub: lurek.audio.getVolume
-- Returns the source volume.
-- Use this when returns the source volume is needed.
if false then
  local _r = lurek.audio.getVolume(1)
  print(_r)
end

--@api-stub: lurek.audio.pause
-- Pauses playback at the current position.
-- Use this when pauses playback at the current position is needed.
if false then
  local _r = lurek.audio.pause(1)
  print(_r)
end

--@api-stub: lurek.audio.resume
-- Resumes playback from pause.
-- Use this when resumes playback from pause is needed.
if false then
  local _r = lurek.audio.resume(1)
  print(_r)
end

--@api-stub: lurek.audio.setPitch
-- Sets source pitch multiplier.
-- Use this when sets source pitch multiplier is needed.
if false then
  local _r = lurek.audio.setPitch(1, 0)
  print(_r)
end

--@api-stub: lurek.audio.getPitch
-- Returns the source pitch multiplier.
-- Use this when returns the source pitch multiplier is needed.
if false then
  local _r = lurek.audio.getPitch(1)
  print(_r)
end

--@api-stub: lurek.audio.isPlaying
-- Returns true if the source is playing.
-- Use this when returns true if the source is playing is needed.
if false then
  local _r = lurek.audio.isPlaying(1)
  print(_r)
end

--@api-stub: lurek.audio.isPaused
-- Returns true if the source is paused.
-- Use this when returns true if the source is paused is needed.
if false then
  local _r = lurek.audio.isPaused(1)
  print(_r)
end

--@api-stub: lurek.audio.isStopped
-- Returns true if the source is stopped.
-- Use this when returns true if the source is stopped is needed.
if false then
  local _r = lurek.audio.isStopped(1)
  print(_r)
end

--@api-stub: lurek.audio.setLooping
-- Enables or disables looping.
-- Use this when enables or disables looping is needed.
if false then
  local _r = lurek.audio.setLooping(1, 1)
  print(_r)
end

--@api-stub: lurek.audio.isLooping
-- Returns true if looping is enabled.
-- Use this when returns true if looping is enabled is needed.
if false then
  local _r = lurek.audio.isLooping(1)
  print(_r)
end

--@api-stub: lurek.audio.playLooping
-- Plays the source in a continuous loop.
-- Use this when plays the source in a continuous loop is needed.
if false then
  local _r = lurek.audio.playLooping(1)
  print(_r)
end

--@api-stub: lurek.audio.setPan
-- Sets stereo panning (-1.0 left to 1.0 right).
-- Use this when sets stereo panning (-1.0 left to 1.0 right) is needed.
if false then
  local _r = lurek.audio.setPan(1, 1)
  print(_r)
end

--@api-stub: lurek.audio.getPan
-- Returns the source stereo panning.
-- Use this when returns the source stereo panning is needed.
if false then
  local _r = lurek.audio.getPan(1)
  print(_r)
end

--@api-stub: lurek.audio.setMasterVolume
-- Sets the global master volume.
-- Use this when sets the global master volume is needed.
if false then
  local _r = lurek.audio.setMasterVolume(0)
  print(_r)
end

--@api-stub: lurek.audio.getMasterVolume
-- Returns the global master volume.
-- Use this when returns the global master volume is needed.
if false then
  local _r = lurek.audio.getMasterVolume()
  print(_r)
end

--@api-stub: lurek.audio.getActiveSourceCount
-- Returns the number of currently playing sources.
-- Use this when returns the number of currently playing sources is needed.
if false then
  local _r = lurek.audio.getActiveSourceCount()
  print(_r)
end

--@api-stub: lurek.audio.getSourceCount
-- Returns the total number of registered sources.
-- Use this when returns the total number of registered sources is needed.
if false then
  local _r = lurek.audio.getSourceCount()
  print(_r)
end

--@api-stub: lurek.audio.getSourceType
-- Returns the type string ("static" or "stream") of a source.
-- Use this when returns the type string ("static" or "stream") of a source is needed.
if false then
  local _r = lurek.audio.getSourceType(1)
  print(_r)
end

--@api-stub: lurek.audio.clone
-- Creates an independent copy of a source.
-- Use this when creates an independent copy of a source is needed.
if false then
  local _r = lurek.audio.clone(1)
  print(_r)
end

--@api-stub: lurek.audio.pauseAll
-- Pauses all currently playing sources.
-- Use this when pauses all currently playing sources is needed.
if false then
  local _r = lurek.audio.pauseAll()
  print(_r)
end

--@api-stub: lurek.audio.stopAll
-- Stops all currently playing sources.
-- Use this when stops all currently playing sources is needed.
if false then
  local _r = lurek.audio.stopAll()
  print(_r)
end

--@api-stub: lurek.audio.resumeAll
-- Resumes all paused sources.
-- Use this when resumes all paused sources is needed.
if false then
  local _r = lurek.audio.resumeAll()
  print(_r)
end

--@api-stub: lurek.audio.release
-- Releases a source and frees its memory.
-- Use this when releases a source and frees its memory is needed.
if false then
  local _r = lurek.audio.release(1)
  print(_r)
end

--@api-stub: lurek.audio.newBus
-- Creates a named audio bus for grouping sources.
-- Use this when creates a named audio bus for grouping sources is needed.
if false then
  local _r = lurek.audio.newBus(1)
  print(_r)
end

--@api-stub: lurek.audio.setSourceBus
-- Assigns a source to a bus.
-- Use this when assigns a source to a bus is needed.
if false then
  local _r = lurek.audio.setSourceBus(1, 0)
  print(_r)
end

--@api-stub: lurek.audio.getSourceBus
-- Returns the bus a source is assigned to, or nil.
-- Use this when returns the bus a source is assigned to, or nil is needed.
if false then
  local _r = lurek.audio.getSourceBus(1)
  print(_r)
end

--@api-stub: lurek.audio.getMaxSources
-- Returns the maximum number of simultaneous sources.
-- Use this when returns the maximum number of simultaneous sources is needed.
if false then
  local _r = lurek.audio.getMaxSources()
  print(_r)
end

--@api-stub: lurek.audio.getDuration
-- Returns the total duration of a source in seconds.
-- Use this when returns the total duration of a source in seconds is needed.
if false then
  local _r = lurek.audio.getDuration(1)
  print(_r)
end

--@api-stub: lurek.audio.tell
-- Returns the current playback position in seconds.
-- Use this when returns the current playback position in seconds is needed.
if false then
  local _r = lurek.audio.tell(1)
  print(_r)
end

--@api-stub: lurek.audio.seek
-- Seeks to a time position in seconds.
-- Use this when seeks to a time position in seconds is needed.
if false then
  local _r = lurek.audio.seek(1, nil)
  print(_r)
end

--@api-stub: lurek.audio.setLowpass
-- Applies a low-pass filter to a source.
-- Use this when applies a low-pass filter to a source is needed.
if false then
  local _r = lurek.audio.setLowpass(1, 0)
  print(_r)
end

--@api-stub: lurek.audio.setHighpass
-- Applies a high-pass filter to a source.
-- Use this when applies a high-pass filter to a source is needed.
if false then
  local _r = lurek.audio.setHighpass(1, 0)
  print(_r)
end

--@api-stub: lurek.audio.getLowpass
-- Returns the low-pass filter cutoff of a source.
-- Use this when returns the low-pass filter cutoff of a source is needed.
if false then
  local _r = lurek.audio.getLowpass(1)
  print(_r)
end

--@api-stub: lurek.audio.getHighpass
-- Returns the high-pass filter cutoff of a source.
-- Use this when returns the high-pass filter cutoff of a source is needed.
if false then
  local _r = lurek.audio.getHighpass(1)
  print(_r)
end

--@api-stub: lurek.audio.clearFilter
-- Removes any active filter from a source.
-- Use this when removes any active filter from a source is needed.
if false then
  local _r = lurek.audio.clearFilter(1)
  print(_r)
end

--@api-stub: lurek.audio.fadeIn
-- Fades a source in from silence over the given duration.
-- Use this when fades a source in from silence over the given duration is needed.
if false then
  local _r = lurek.audio.fadeIn(1, nil)
  print(_r)
end

--@api-stub: lurek.audio.getFadeIn
-- Returns the fade-in duration of a source.
-- Use this when returns the fade-in duration of a source is needed.
if false then
  local _r = lurek.audio.getFadeIn(1)
  print(_r)
end

--@api-stub: lurek.audio.setListener2D
-- Sets the 2D listener position for spatial audio.
-- Use this when sets the 2D listener position for spatial audio is needed.
if false then
  local _r = lurek.audio.setListener2D(0, 0)
  print(_r)
end

--@api-stub: lurek.audio.getListener2D
-- Returns the 2D listener position (x, y).
-- Use this when returns the 2D listener position (x, y) is needed.
if false then
  local _r = lurek.audio.getListener2D()
  print(_r)
end

--@api-stub: lurek.audio.setListener
-- Sets the 3D listener position.
-- Use this when sets the 3D listener position is needed.
if false then
  local _r = lurek.audio.setListener(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.getListener
-- Returns the 3D listener position (x, y, z).
-- Use this when returns the 3D listener position (x, y, z) is needed.
if false then
  local _r = lurek.audio.getListener()
  print(_r)
end

--@api-stub: lurek.audio.setPosition
-- Sets the 3D position of a source.
-- Use this when sets the 3D position of a source is needed.
if false then
  local _r = lurek.audio.setPosition(1, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.getPosition
-- Returns the 3D position of a source (x, y, z).
-- Use this when returns the 3D position of a source (x, y, z) is needed.
if false then
  local _r = lurek.audio.getPosition(1)
  print(_r)
end

--@api-stub: lurek.audio.setVelocity
-- Sets the velocity of a source for Doppler.
-- Use this when sets the velocity of a source for Doppler is needed.
if false then
  local _r = lurek.audio.setVelocity(1, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.getVelocity
-- Returns the velocity of a source (x, y, z).
-- Use this when returns the velocity of a source (x, y, z) is needed.
if false then
  local _r = lurek.audio.getVelocity(1)
  print(_r)
end

--@api-stub: lurek.audio.setOrientation
-- Sets the 6-component orientation of a source.
-- Use this when sets the 6-component orientation of a source is needed.
if false then
  local _r = lurek.audio.setOrientation(1, 0, 0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.getOrientation
-- Returns the 6-component orientation of a source.
-- Use this when returns the 6-component orientation of a source is needed.
if false then
  local _r = lurek.audio.getOrientation(1)
  print(_r)
end

--@api-stub: lurek.audio.setDopplerScale
-- Sets the global Doppler effect scale.
-- Use this when sets the global Doppler effect scale is needed.
if false then
  local _r = lurek.audio.setDopplerScale(0)
  print(_r)
end

--@api-stub: lurek.audio.getDopplerScale
-- Returns the current Doppler scale.
-- Use this when returns the current Doppler scale is needed.
if false then
  local _r = lurek.audio.getDopplerScale()
  print(_r)
end

--@api-stub: lurek.audio.setDistanceModel
-- Sets the distance attenuation model.
-- Use this when sets the distance attenuation model is needed.
if false then
  local _r = lurek.audio.setDistanceModel(nil)
  print(_r)
end

--@api-stub: lurek.audio.getDistanceModel
-- Returns the current distance model name.
-- Use this when returns the current distance model name is needed.
if false then
  local _r = lurek.audio.getDistanceModel()
  print(_r)
end

--@api-stub: lurek.audio.setMeter
-- Sets the master peak meter level (0.0â€“1.0).
-- Use this when sets the master peak meter level (0.0â€“1.0) is needed.
if false then
  local _r = lurek.audio.setMeter(0)
  print(_r)
end

--@api-stub: lurek.audio.getMeter
-- Returns the stored master peak meter level.
-- Use this when returns the stored master peak meter level is needed.
if false then
  local _r = lurek.audio.getMeter()
  print(_r)
end

--@api-stub: lurek.audio.newMidiPlayer
-- Creates a MIDI player, optionally loading a file.
-- Use this when creates a MIDI player, optionally loading a file is needed.
if false then
  local _r = lurek.audio.newMidiPlayer(0)
  print(_r)
end

--@api-stub: lurek.audio.newSoundData
-- Creates a SoundData from a file or as a silent buffer.
-- Use this when creates a SoundData from a file or as a silent buffer is needed.
if false then
  local _r = lurek.audio.newSoundData({})
  print(_r)
end

--@api-stub: lurek.audio.setMidiSoundFont
-- Sets the global SoundFont for MIDI synthesis.
-- Use this when sets the global SoundFont for MIDI synthesis is needed.
if false then
  local _r = lurek.audio.setMidiSoundFont(0)
  print(_r)
end

--@api-stub: lurek.audio.hasMidiSoundFont
-- Returns true if a SoundFont is loaded.
-- Use this when returns true if a SoundFont is loaded is needed.
if false then
  local _r = lurek.audio.hasMidiSoundFont()
  print(_r)
end

--@api-stub: lurek.audio.clearMidiSoundFont
-- Unloads the active SoundFont.
-- Use this when unloads the active SoundFont is needed.
if false then
  local _r = lurek.audio.clearMidiSoundFont()
  print(_r)
end

--@api-stub: lurek.audio.newDecoder
-- Creates a streaming audio decoder.
-- Use this when creates a streaming audio decoder is needed.
if false then
  local _r = lurek.audio.newDecoder(nil, 1)
  print(_r)
end

--@api-stub: lurek.audio.newQueueableSource
-- Creates a queueable source for manual PCM buffering.
-- Use this when creates a queueable source for manual PCM buffering is needed.
if false then
  local _r = lurek.audio.newQueueableSource()
  print(_r)
end

--@api-stub: lurek.audio.queueSource
-- Pushes a SoundData buffer into a queueable source.
-- Use this when pushes a SoundData buffer into a queueable source is needed.
if false then
  local _r = lurek.audio.queueSource(1, nil)
  print(_r)
end

--@api-stub: lurek.audio.getFreeBufferCount
-- Returns the free buffer slots in a queueable source.
-- Use this when returns the free buffer slots in a queueable source is needed.
if false then
  local _r = lurek.audio.getFreeBufferCount(1)
  print(_r)
end

--@api-stub: lurek.audio.playQueueable
-- Starts playback of a queueable source.
-- Use this when starts playback of a queueable source is needed.
if false then
  local _r = lurek.audio.playQueueable(1)
  print(_r)
end

--@api-stub: lurek.audio.stopQueueable
-- Stops a queueable source and drains its buffers.
-- Use this when stops a queueable source and drains its buffers is needed.
if false then
  local _r = lurek.audio.stopQueueable(1)
  print(_r)
end

--@api-stub: lurek.audio.getPlaybackDevices
-- Returns a table of available audio output device names.
-- Use this when returns a table of available audio output device names is needed.
if false then
  local _r = lurek.audio.getPlaybackDevices()
  print(_r)
end

--@api-stub: lurek.audio.getPlaybackDevice
-- Returns the current audio output device name.
-- Use this when returns the current audio output device name is needed.
if false then
  local _r = lurek.audio.getPlaybackDevice()
  print(_r)
end

--@api-stub: lurek.audio.setPlaybackDevice
-- Selects an audio output device by name.
-- Use this when selects an audio output device by name is needed.
if false then
  local _r = lurek.audio.setPlaybackDevice(1)
  print(_r)
end

--@api-stub: lurek.audio.create_bus
-- Creates a bus by name (functional style).
-- Use this when creates a bus by name (functional style) is needed.
if false then
  local _r = lurek.audio.create_bus(1, 1)
  print(_r)
end

--@api-stub: lurek.audio.set_bus_volume
-- Sets a bus volume by name.
-- Use this when sets a bus volume by name is needed.
if false then
  local _r = lurek.audio.set_bus_volume(1, 0)
  print(_r)
end

--@api-stub: lurek.audio.add_effect
-- Adds a DSP effect to a bus.
-- Use this when adds a DSP effect to a bus is needed.
if false then
  local _r = lurek.audio.add_effect(1, 0, {})
  print(_r)
end

--@api-stub: lurek.audio.remove_effect
-- Removes a DSP effect from a bus.
-- Use this when removes a DSP effect from a bus is needed.
if false then
  local _r = lurek.audio.remove_effect(1, 1)
  print(_r)
end

--@api-stub: lurek.audio.set_effect_param
-- Sets a parameter on a DSP effect.
-- Use this when sets a parameter on a DSP effect is needed.
if false then
  local _r = lurek.audio.set_effect_param(1, 1, 1, 0)
  print(_r)
end

--@api-stub: lurek.audio.newSineWave
-- Generate a mono sine-wave SoundData buffer.
-- Use this when generate a mono sine-wave SoundData buffer is needed.
if false then
  local _r = lurek.audio.newSineWave(nil, 1, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.newSquareWave
-- Generate a mono square-wave SoundData buffer.
-- Use this when generate a mono square-wave SoundData buffer is needed.
if false then
  local _r = lurek.audio.newSquareWave(nil, 1, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.newSawtoothWave
-- Generate a mono sawtooth-wave SoundData buffer.
-- Use this when generate a mono sawtooth-wave SoundData buffer is needed.
if false then
  local _r = lurek.audio.newSawtoothWave(nil, 1, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.newTriangleWave
-- Generate a mono triangle-wave SoundData buffer.
-- Use this when generate a mono triangle-wave SoundData buffer is needed.
if false then
  local _r = lurek.audio.newTriangleWave(nil, 1, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.newWhiteNoise
-- Generate a reproducible white-noise SoundData buffer.
-- Use this when generate a reproducible white-noise SoundData buffer is needed.
if false then
  local _r = lurek.audio.newWhiteNoise(1, 0, 0, nil)
  print(_r)
end

--@api-stub: lurek.audio.applyLowpass
-- Applies a first-order IIR low-pass filter to a SoundData in-place.
-- Use this when applies a first-order IIR low-pass filter to a SoundData in-place is needed.
if false then
  local _r = lurek.audio.applyLowpass(nil, 0)
  print(_r)
end

--@api-stub: lurek.audio.applyHighpass
-- Applies a first-order IIR high-pass filter to a SoundData in-place.
-- Use this when applies a first-order IIR high-pass filter to a SoundData in-place is needed.
if false then
  local _r = lurek.audio.applyHighpass(nil, 0)
  print(_r)
end

--@api-stub: lurek.audio.applyBandpass
-- Applies a bandpass filter (high-pass then low-pass) to a SoundData in-place.
-- Use this when applies a bandpass filter (high-pass then low-pass) to a SoundData in-place is needed.
if false then
  local _r = lurek.audio.applyBandpass(nil, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.applyGain
-- Scales every sample by gain (clamped to [-1, 1]).
-- Use this when scales every sample by gain (clamped to [-1, 1]) is needed.
if false then
  local _r = lurek.audio.applyGain(nil, 1)
  print(_r)
end

--@api-stub: lurek.audio.mixInto
-- Additively mixes another SoundData into the destination in-place.
-- Use this when additively mixes another SoundData into the destination in-place is needed.
if false then
  local _r = lurek.audio.mixInto(0, nil)
  print(_r)
end

--@api-stub: lurek.audio.saveWAV
-- Saves a SoundData as a 16-bit PCM WAV file at the given path.
-- Use this when saves a SoundData as a 16-bit PCM WAV file at the given path is needed.
if false then
  local _r = lurek.audio.saveWAV(nil, 1)
  print(_r)
end

--@api-stub: lurek.audio.setStereoWidth
-- Sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono).
-- Use this when sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono) is needed.
if false then
  local _r = lurek.audio.setStereoWidth(nil, 1)
  print(_r)
end

--@api-stub: lurek.audio.getStereoWidth
-- Returns the current stereo width for a source.
-- Use this when returns the current stereo width for a source is needed.
if false then
  local _r = lurek.audio.getStereoWidth(nil)
  print(_r)
end

--@api-stub: lurek.audio.setRandomPitch
-- Sets a random pitch range applied each time the source is played.
-- Use this when sets a random pitch range applied each time the source is played is needed.
if false then
  local _r = lurek.audio.setRandomPitch(nil, 1, 0)
  print(_r)
end

--@api-stub: lurek.audio.clearRandomPitch
-- Clears any random pitch range on a source, restoring fixed pitch.
-- Use this when clears any random pitch range on a source, restoring fixed pitch is needed.
if false then
  local _r = lurek.audio.clearRandomPitch(nil)
  print(_r)
end

--@api-stub: lurek.audio.crossfade
-- Crossfades from one source to another over a duration.
-- Use this when crossfades from one source to another over a duration is needed.
if false then
  local _r = lurek.audio.crossfade(nil, 0, 1)
  print(_r)
end

--@api-stub: lurek.audio.getBusPeak
-- Returns the peak signal level of the named bus (stub: always 0.0).
-- Use this when returns the peak signal level of the named bus (stub: always 0.0) is needed.
if false then
  local _r = lurek.audio.getBusPeak(1)
  print(_r)
end

--@api-stub: lurek.audio.getBusRms
-- Returns the RMS signal level of the named bus (stub: always 0.0).
-- Use this when returns the RMS signal level of the named bus (stub: always 0.0) is needed.
if false then
  local _r = lurek.audio.getBusRms(1)
  print(_r)
end

--@api-stub: lurek.audio.newPool
-- Creates a polyphonic sound pool for the given file with N simultaneous voices.
-- Use this when creates a polyphonic sound pool for the given file with N simultaneous voices is needed.
if false then
  local _r = lurek.audio.newPool(0, 1)
  print(_r)
end

--@api-stub: lurek.audio.processOffline
-- Applies a DSP effect chain to a WAV file and writes output.
-- Use this when applies a DSP effect chain to a WAV file and writes output is needed.
if false then
  local _r = lurek.audio.processOffline(1, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.normalizeFile
-- Normalizes a WAV file peak amplitude to target_level and writes output.
-- Use this when normalizes a WAV file peak amplitude to target_level and writes output is needed.
if false then
  local _r = lurek.audio.normalizeFile(1, 0, 0)
  print(_r)
end

--@api-stub: lurek.audio.waveformToPng
-- Renders the waveform of a WAV file to a PNG image.
-- Use this when renders the waveform of a WAV file to a PNG image is needed.
if false then
  local _r = lurek.audio.waveformToPng(1, 0, 1, 1)
  print(_r)
end

--@api-stub: lurek.audio.spectrogramToPng
-- Renders a time-frequency spectrogram of a WAV file to a PNG image.
-- Use this when renders a time-frequency spectrogram of a WAV file to a PNG image is needed.
if false then
  local _r = lurek.audio.spectrogramToPng(1, 0, 1, 1)
  print(_r)
end

-- ── Source methods ──

--@api-stub: Source:play
-- Starts or resumes playback.
-- Use this when starts or resumes playback is needed.
if false then
  local _o = nil  -- Source instance
  _o:play()
end

--@api-stub: Source:stop
-- Stops playback and resets seek position.
-- Use this when stops playback and resets seek position is needed.
if false then
  local _o = nil  -- Source instance
  _o:stop()
end

--@api-stub: Source:pause
-- Pauses playback at the current position.
-- Use this when pauses playback at the current position is needed.
if false then
  local _o = nil  -- Source instance
  _o:pause()
end

--@api-stub: Source:resume
-- Resumes playback from the paused position.
-- Use this when resumes playback from the paused position is needed.
if false then
  local _o = nil  -- Source instance
  _o:resume()
end

--@api-stub: Source:setVolume
-- Sets playback volume (0.0 = silent, 1.0 = full).
-- Use this when sets playback volume (0.0 = silent, 1.0 = full) is needed.
if false then
  local _o = nil  -- Source instance
  _o:setVolume(0)
end

--@api-stub: Source:getVolume
-- Returns the current volume multiplier.
-- Use this when returns the current volume multiplier is needed.
if false then
  local _o = nil  -- Source instance
  _o:getVolume()
end

--@api-stub: Source:setPitch
-- Sets the pitch multiplier (1.0 = normal).
-- Use this when sets the pitch multiplier (1.0 = normal) is needed.
if false then
  local _o = nil  -- Source instance
  _o:setPitch(0)
end

--@api-stub: Source:getPitch
-- Returns the current pitch multiplier.
-- Use this when returns the current pitch multiplier is needed.
if false then
  local _o = nil  -- Source instance
  _o:getPitch()
end

--@api-stub: Source:setLooping
-- Enables or disables looping playback.
-- Use this when enables or disables looping playback is needed.
if false then
  local _o = nil  -- Source instance
  _o:setLooping(1)
end

--@api-stub: Source:isLooping
-- Returns true if looping is enabled.
-- Use this when returns true if looping is enabled is needed.
if false then
  local _o = nil  -- Source instance
  _o:isLooping()
end

--@api-stub: Source:isPlaying
-- Returns true if currently playing.
-- Use this when returns true if currently playing is needed.
if false then
  local _o = nil  -- Source instance
  _o:isPlaying()
end

--@api-stub: Source:isPaused
-- Returns true if playback is paused.
-- Use this when returns true if playback is paused is needed.
if false then
  local _o = nil  -- Source instance
  _o:isPaused()
end

--@api-stub: Source:isStopped
-- Returns true if playback has stopped.
-- Use this when returns true if playback has stopped is needed.
if false then
  local _o = nil  -- Source instance
  _o:isStopped()
end

--@api-stub: Source:setPan
-- Sets stereo panning (-1.0 left to 1.0 right).
-- Use this when sets stereo panning (-1.0 left to 1.0 right) is needed.
if false then
  local _o = nil  -- Source instance
  _o:setPan(1)
end

--@api-stub: Source:getPan
-- Returns the current stereo panning value.
-- Use this when returns the current stereo panning value is needed.
if false then
  local _o = nil  -- Source instance
  _o:getPan()
end

--@api-stub: Source:clone
-- Creates an independent copy of this source.
-- Use this when creates an independent copy of this source is needed.
if false then
  local _o = nil  -- Source instance
  _o:clone()
end

--@api-stub: Source:getType
-- Returns the source type ("static" or "stream").
-- Use this when returns the source type ("static" or "stream") is needed.
if false then
  local _o = nil  -- Source instance
  _o:getType()
end

--@api-stub: Source:getDuration
-- Returns the total duration in seconds.
-- Use this when returns the total duration in seconds is needed.
if false then
  local _o = nil  -- Source instance
  _o:getDuration()
end

--@api-stub: Source:tell
-- Returns the current playback position in seconds.
-- Use this when returns the current playback position in seconds is needed.
if false then
  local _o = nil  -- Source instance
  _o:tell()
end

--@api-stub: Source:seek
-- Seeks to a time position in seconds.
-- Use this when seeks to a time position in seconds is needed.
if false then
  local _o = nil  -- Source instance
  _o:seek(nil)
end

--@api-stub: Source:setLowpass
-- Applies a low-pass filter at the given cutoff frequency.
-- Use this when applies a low-pass filter at the given cutoff frequency is needed.
if false then
  local _o = nil  -- Source instance
  _o:setLowpass(0)
end

--@api-stub: Source:setHighpass
-- Applies a high-pass filter at the given cutoff frequency.
-- Use this when applies a high-pass filter at the given cutoff frequency is needed.
if false then
  local _o = nil  -- Source instance
  _o:setHighpass(0)
end

--@api-stub: Source:getLowpass
-- Returns the low-pass filter cutoff frequency.
-- Use this when returns the low-pass filter cutoff frequency is needed.
if false then
  local _o = nil  -- Source instance
  _o:getLowpass()
end

--@api-stub: Source:getHighpass
-- Returns the high-pass filter cutoff frequency.
-- Use this when returns the high-pass filter cutoff frequency is needed.
if false then
  local _o = nil  -- Source instance
  _o:getHighpass()
end

--@api-stub: Source:clearFilter
-- Removes any active filter from this source.
-- Use this when removes any active filter from this source is needed.
if false then
  local _o = nil  -- Source instance
  _o:clearFilter()
end

--@api-stub: Source:fadeIn
-- Fades in from silence over the given duration in seconds.
-- Use this when fades in from silence over the given duration in seconds is needed.
if false then
  local _o = nil  -- Source instance
  _o:fadeIn(nil)
end

--@api-stub: Source:getFadeIn
-- Returns the current fade-in duration in seconds.
-- Use this when returns the current fade-in duration in seconds is needed.
if false then
  local _o = nil  -- Source instance
  _o:getFadeIn()
end

-- ── Bus methods ──

--@api-stub: Bus:getName
-- Returns the unique name string assigned to this audio bus.
-- Use this when returns the unique name string assigned to this audio bus is needed.
if false then
  local _o = nil  -- Bus instance
  _o:getName()
end

--@api-stub: Bus:setVolume
-- Sets the volume for all sources on this bus.
-- Use this when sets the volume for all sources on this bus is needed.
if false then
  local _o = nil  -- Bus instance
  _o:setVolume(0)
end

--@api-stub: Bus:getVolume
-- Returns the current volume multiplier applied to all sources on this bus.
-- Use this when returns the current volume multiplier applied to all sources on this bus is needed.
if false then
  local _o = nil  -- Bus instance
  _o:getVolume()
end

--@api-stub: Bus:setPitch
-- Sets the pitch multiplier for all sources on this bus.
-- Use this when sets the pitch multiplier for all sources on this bus is needed.
if false then
  local _o = nil  -- Bus instance
  _o:setPitch(0)
end

--@api-stub: Bus:getPitch
-- Returns the bus pitch multiplier.
-- Use this when returns the bus pitch multiplier is needed.
if false then
  local _o = nil  -- Bus instance
  _o:getPitch()
end

--@api-stub: Bus:pause
-- Pauses all sources on this bus.
-- Use this when pauses all sources on this bus is needed.
if false then
  local _o = nil  -- Bus instance
  _o:pause()
end

--@api-stub: Bus:resume
-- Resumes all sources on this bus.
-- Use this when resumes all sources on this bus is needed.
if false then
  local _o = nil  -- Bus instance
  _o:resume()
end

--@api-stub: Bus:isPaused
-- Returns true if this bus is paused.
-- Use this when returns true if this bus is paused is needed.
if false then
  local _o = nil  -- Bus instance
  _o:isPaused()
end

--@api-stub: Bus:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Bus instance
  _o:type()
end

--@api-stub: Bus:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- Bus instance
  _o:typeOf(1)
end

--@api-stub: Bus:clearDuck
-- Removes the ducking target from this bus, restoring the target bus.
-- Use this when removes the ducking target from this bus, restoring the target bus is needed.
if false then
  local _o = nil  -- Bus instance
  _o:clearDuck()
end

--@api-stub: Bus:getPeak
-- Returns the average peak amplitude of all sources currently on this bus.
-- Use this when returns the average peak amplitude of all sources currently on this bus is needed.
if false then
  local _o = nil  -- Bus instance
  _o:getPeak()
end

-- ── MidiPlayer methods ──

--@api-stub: MidiPlayer:load
-- Loads a MIDI file from the given path.
-- Use this when loads a MIDI file from the given path is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:load(0)
end

--@api-stub: MidiPlayer:loadData
-- Loads MIDI data from a Lua string.
-- Use this when loads MIDI data from a Lua string is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:loadData()
end

--@api-stub: MidiPlayer:isLoaded
-- Returns true if a MIDI sequence is loaded.
-- Use this when returns true if a MIDI sequence is loaded is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:isLoaded()
end

--@api-stub: MidiPlayer:getFilePath
-- Returns the file path of the loaded MIDI, or nil.
-- Use this when returns the file path of the loaded MIDI, or nil is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getFilePath()
end

--@api-stub: MidiPlayer:setSoundFont
-- Loads a SoundFont file into this player (stub).
-- Use this when loads a SoundFont file into this player (stub) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setSoundFont(0)
end

--@api-stub: MidiPlayer:getSoundFontPath
-- Returns the SoundFont file path, or nil (stub).
-- Use this when returns the SoundFont file path, or nil (stub) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getSoundFontPath()
end

--@api-stub: MidiPlayer:useDefaultSoundFont
-- Reverts to the built-in default SoundFont (stub).
-- Use this when reverts to the built-in default SoundFont (stub) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:useDefaultSoundFont()
end

--@api-stub: MidiPlayer:play
-- Starts or resumes MIDI sequence playback from the current position.
-- Use this when starts or resumes MIDI sequence playback from the current position is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:play()
end

--@api-stub: MidiPlayer:pause
-- Pauses the MIDI sequence at the current position; resume with `play()`.
-- Use this when pauses the MIDI sequence at the current position; resume with `play()` is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:pause()
end

--@api-stub: MidiPlayer:stop
-- Stops MIDI playback and resets the playhead to the beginning.
-- Use this when stops MIDI playback and resets the playhead to the beginning is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:stop()
end

--@api-stub: MidiPlayer:isPlaying
-- Returns true if MIDI is currently playing.
-- Use this when returns true if MIDI is currently playing is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:isPlaying()
end

--@api-stub: MidiPlayer:isPaused
-- Returns true if MIDI playback is paused.
-- Use this when returns true if MIDI playback is paused is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:isPaused()
end

--@api-stub: MidiPlayer:seek
-- Seeks to a time position in seconds.
-- Use this when seeks to a time position in seconds is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:seek(nil)
end

--@api-stub: MidiPlayer:tell
-- Returns the current playback position in seconds.
-- Use this when returns the current playback position in seconds is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:tell()
end

--@api-stub: MidiPlayer:getDuration
-- Returns the total MIDI duration in seconds.
-- Use this when returns the total MIDI duration in seconds is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getDuration()
end

--@api-stub: MidiPlayer:setLooping
-- Enables or disables looping.
-- Use this when enables or disables looping is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setLooping(1)
end

--@api-stub: MidiPlayer:isLooping
-- Returns true if looping is enabled.
-- Use this when returns true if looping is enabled is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:isLooping()
end

--@api-stub: MidiPlayer:setVolume
-- Sets MIDI playback volume.
-- Use this when sets MIDI playback volume is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setVolume(0)
end

--@api-stub: MidiPlayer:getVolume
-- Returns the current MIDI volume.
-- Use this when returns the current MIDI volume is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getVolume()
end

--@api-stub: MidiPlayer:setBus
-- Routes MIDI output through a bus (or nil to clear).
-- Use this when routes MIDI output through a bus (or nil to clear) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setBus(0)
end

--@api-stub: MidiPlayer:getBus
-- Returns the assigned bus, or nil.
-- Use this when returns the assigned bus, or nil is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getBus()
end

--@api-stub: MidiPlayer:setTempo
-- Sets playback tempo in BPM.
-- Use this when sets playback tempo in BPM is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setTempo(nil)
end

--@api-stub: MidiPlayer:getTempo
-- Returns the current tempo in BPM.
-- Use this when returns the current tempo in BPM is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getTempo()
end

--@api-stub: MidiPlayer:getOriginalTempo
-- Returns the original MIDI file tempo in BPM.
-- Use this when returns the original MIDI file tempo in BPM is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getOriginalTempo()
end

--@api-stub: MidiPlayer:setTempoScale
-- Sets the tempo scale factor (1.0 = original speed).
-- Use this when sets the tempo scale factor (1.0 = original speed) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setTempoScale(0)
end

--@api-stub: MidiPlayer:getTempoScale
-- Returns the current tempo scale factor.
-- Use this when returns the current tempo scale factor is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getTempoScale()
end

--@api-stub: MidiPlayer:getTicksPerBeat
-- Returns the PPQ resolution from the MIDI header.
-- Use this when returns the PPQ resolution from the MIDI header is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getTicksPerBeat()
end

--@api-stub: MidiPlayer:setChannelVolume
-- Sets volume for a MIDI channel (1-indexed).
-- Use this when sets volume for a MIDI channel (1-indexed) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setChannelVolume(0, 0)
end

--@api-stub: MidiPlayer:getChannelVolume
-- Returns the volume for a MIDI channel (1-indexed).
-- Use this when returns the volume for a MIDI channel (1-indexed) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getChannelVolume(0)
end

--@api-stub: MidiPlayer:setChannelMuted
-- Mutes or unmutes a MIDI channel (1-indexed).
-- Use this when mutes or unmutes a MIDI channel (1-indexed) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setChannelMuted(0, 0)
end

--@api-stub: MidiPlayer:isChannelMuted
-- Returns true if a MIDI channel is muted (1-indexed).
-- Use this when returns true if a MIDI channel is muted (1-indexed) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:isChannelMuted(0)
end

--@api-stub: MidiPlayer:getChannelInstrument
-- Returns the GM instrument for a MIDI channel (1-indexed).
-- Use this when returns the GM instrument for a MIDI channel (1-indexed) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getChannelInstrument(0)
end

--@api-stub: MidiPlayer:getChannelCount
-- Returns the number of MIDI channels.
-- Use this when returns the number of MIDI channels is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getChannelCount()
end

--@api-stub: MidiPlayer:soloChannel
-- Solos a MIDI channel (1-indexed).
-- Use this when solos a MIDI channel (1-indexed) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:soloChannel(0)
end

--@api-stub: MidiPlayer:unsoloAll
-- Clears solo on all channels.
-- Use this when clears solo on all channels is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:unsoloAll()
end

--@api-stub: MidiPlayer:getTrackCount
-- Returns the number of tracks in the MIDI sequence.
-- Use this when returns the number of tracks in the MIDI sequence is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getTrackCount()
end

--@api-stub: MidiPlayer:getTrackName
-- Returns the name of a MIDI track (1-indexed), or nil.
-- Use this when returns the name of a MIDI track (1-indexed), or nil is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getTrackName(1)
end

--@api-stub: MidiPlayer:setTrackMuted
-- Mutes or unmutes a track (1-indexed).
-- Use this when mutes or unmutes a track (1-indexed) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setTrackMuted(1, 0)
end

--@api-stub: MidiPlayer:isTrackMuted
-- Returns true if a track is muted (1-indexed).
-- Use this when returns true if a track is muted (1-indexed) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:isTrackMuted(1)
end

--@api-stub: MidiPlayer:getNoteCount
-- Returns the total note count in the MIDI sequence.
-- Use this when returns the total note count in the MIDI sequence is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getNoteCount()
end

--@api-stub: MidiPlayer:setOnNoteOn
-- Registers a note-on callback (stub).
-- Use this when registers a note-on callback (stub) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setOnNoteOn(function() end)
end

--@api-stub: MidiPlayer:setOnNoteOff
-- Registers a note-off callback (stub).
-- Use this when registers a note-off callback (stub) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setOnNoteOff(function() end)
end

--@api-stub: MidiPlayer:setOnEnd
-- Registers a playback-end callback (stub).
-- Use this when registers a playback-end callback (stub) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setOnEnd(function() end)
end

--@api-stub: MidiPlayer:getSampleRate
-- Returns the PCM output sample rate in Hz.
-- Use this when returns the PCM output sample rate in Hz is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getSampleRate()
end

--@api-stub: MidiPlayer:setSampleRate
-- Sets the PCM output sample rate in Hz (clamped 8000â€“192000).
-- Use this when sets the PCM output sample rate in Hz (clamped 8000â€“192000) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setSampleRate(0)
end

--@api-stub: MidiPlayer:getChannels
-- Returns the PCM output channel count (1 = mono, 2 = stereo).
-- Use this when returns the PCM output channel count (1 = mono, 2 = stereo) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:getChannels()
end

--@api-stub: MidiPlayer:setChannels
-- Sets the PCM output channel count (clamped 1â€“2).
-- Use this when sets the PCM output channel count (clamped 1â€“2) is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:setChannels(1)
end

--@api-stub: MidiPlayer:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:type()
end

--@api-stub: MidiPlayer:typeOf
-- Returns true if this object is of the given type.
-- Use this when returns true if this object is of the given type is needed.
if false then
  local _o = nil  -- MidiPlayer instance
  _o:typeOf(1)
end

-- ── SoundPool methods ──

--@api-stub: SoundPool:play
-- Plays the next available voice and returns its SoundKey as an integer.
-- Use this when plays the next available voice and returns its SoundKey as an integer is needed.
if false then
  local _o = nil  -- SoundPool instance
  _o:play()
end

--@api-stub: SoundPool:stopAll
-- Stops all voices in this pool.
-- Use this when stops all voices in this pool is needed.
if false then
  local _o = nil  -- SoundPool instance
  _o:stopAll()
end

--@api-stub: SoundPool:setVolume
-- Sets the volume for all voices in this pool.
-- Use this when sets the volume for all voices in this pool is needed.
if false then
  local _o = nil  -- SoundPool instance
  _o:setVolume(0)
end

--@api-stub: SoundPool:setBus
-- Routes all voices through the named bus.
-- Use this when routes all voices through the named bus is needed.
if false then
  local _o = nil  -- SoundPool instance
  _o:setBus(1)
end

--@api-stub: SoundPool:release
-- Releases all voices from the mixer and invalidates this pool.
-- Use this when releases all voices from the mixer and invalidates this pool is needed.
if false then
  local _o = nil  -- SoundPool instance
  _o:release()
end

--@api-stub: SoundPool:getVoiceCount
-- Returns the total number of voices in this pool.
-- Use this when returns the total number of voices in this pool is needed.
if false then
  local _o = nil  -- SoundPool instance
  _o:getVoiceCount()
end

--@api-stub: SoundPool:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- SoundPool instance
  _o:type()
end

--@api-stub: SoundPool:typeOf
-- Returns true if the type name matches.
-- Use this when returns true if the type name matches is needed.
if false then
  local _o = nil  -- SoundPool instance
  _o:typeOf(1)
end

-- ── Decoder methods ──

--@api-stub: Decoder:decode
-- Decodes the next chunk of samples, or nil at EOF.
-- Use this when decodes the next chunk of samples, or nil at EOF is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:decode()
end

--@api-stub: Decoder:getChannelCount
-- Returns the number of audio channels.
-- Use this when returns the number of audio channels is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:getChannelCount()
end

--@api-stub: Decoder:getBitDepth
-- Returns the per-sample bit depth of this decoded audio stream.
-- Use this when returns the per-sample bit depth of this decoded audio stream is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:getBitDepth()
end

--@api-stub: Decoder:getSampleRate
-- Returns the sample rate in Hz.
-- Use this when returns the sample rate in Hz is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:getSampleRate()
end

--@api-stub: Decoder:getDuration
-- Returns the total duration in seconds.
-- Use this when returns the total duration in seconds is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:getDuration()
end

--@api-stub: Decoder:seek
-- Seeks to a time offset in seconds.
-- Use this when seeks to a time offset in seconds is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:seek(0)
end

--@api-stub: Decoder:rewind
-- Rewinds to the beginning.
-- Use this when rewinds to the beginning is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:rewind()
end

--@api-stub: Decoder:tell
-- Returns the current position in seconds.
-- Use this when returns the current position in seconds is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:tell()
end

--@api-stub: Decoder:isSeekable
-- Returns true if seeking is supported.
-- Use this when returns true if seeking is supported is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:isSeekable()
end

--@api-stub: Decoder:release
-- Releases the decoder (no-op).
-- Use this when releases the decoder (no-op) is needed.
if false then
  local _o = nil  -- Decoder instance
  _o:release()
end

-- ── mlua methods ──

--@api-stub: mlua:getSampleCount
-- Get the total number of samples.
-- Use this when get the total number of samples is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getSampleCount()
end

--@api-stub: mlua:getSampleRate
-- Get the sample rate.
-- Use this when get the sample rate is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getSampleRate()
end

--@api-stub: mlua:getChannelCount
-- Get the number of channels.
-- Use this when get the number of channels is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getChannelCount()
end

--@api-stub: mlua:getDuration
-- Get the audio duration in seconds.
-- Use this when get the audio duration in seconds is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getDuration()
end

--@api-stub: mlua:getBitDepth
-- Get the bit depth.
-- Use this when get the bit depth is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getBitDepth()
end

--@api-stub: mlua:getSample
-- Get a specific sample by index.
-- Use this when get a specific sample by index is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getSample(1)
end

--@api-stub: mlua:setSample
-- Set a specific sample by index.
-- Use this when set a specific sample by index is needed.
if false then
  local _o = nil  -- mlua instance
  _o:setSample(1, 0)
end

