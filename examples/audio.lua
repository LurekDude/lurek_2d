-- examples/audio.lua
-- Luna2D luna.audio API Reference
-- This file is documentation code, not a runnable game.
-- Covers Sources, Buses, MIDI Player, and SoundData.

-- ─────────────────────────────────────────────────────────────────────────────
-- Creating Audio Sources
-- ─────────────────────────────────────────────────────────────────────────────

-- Source types:
--   "static"  — fully decoded into RAM, low latency, best for short SFX
--   "stream"  — decoded on the fly, lower RAM usage, best for music/ambience

local sfx_jump  = luna.audio.newSource("sounds/jump.wav",     "static")
local sfx_coin  = luna.audio.newSource("sounds/coin.ogg",     "static")
local music     = luna.audio.newSource("music/theme.ogg",     "stream")
local ambience  = luna.audio.newSource("ambient/forest.ogg",  "stream")

-- ─────────────────────────────────────────────────────────────────────────────
-- Playback Control
-- ─────────────────────────────────────────────────────────────────────────────

music:play()
music:pause()
music:resume()
music:stop()   -- rewinds to start

-- Query playback state
local playing  = music:isPlaying()
local paused   = music:isPaused()
local stopped  = music:isStopped()

-- Duration in seconds (may be nil for streams before they start)
local duration = music:getDuration()

-- Current playback position in seconds
local pos = music:tell()

-- Seek to a position (static sources only; streams may not support exact seek)
music:seek(30.5)  -- jump to 30.5 seconds

-- ─────────────────────────────────────────────────────────────────────────────
-- Volume, Pitch, Pan
-- ─────────────────────────────────────────────────────────────────────────────

-- Volume: 0.0 (silent) to 1.0 (full) and beyond (amplify)
music:setVolume(0.75)
local vol = music:getVolume()

-- Pitch: 1.0 = normal, 2.0 = one octave up, 0.5 = one octave down
music:setPitch(1.05)  -- slight pitch shift
local pitch = music:getPitch()

-- Stereo pan: -1.0 = full left, 0.0 = centre, +1.0 = full right
sfx_jump:setPan(-0.3)  -- slightly to the left
local pan = sfx_jump:getPan()

-- ─────────────────────────────────────────────────────────────────────────────
-- Looping
-- ─────────────────────────────────────────────────────────────────────────────

music:setLooping(true)     -- loop indefinitely
music:setLooping(false)    -- play once and stop
local loops = music:isLooping()

-- ─────────────────────────────────────────────────────────────────────────────
-- Filters (EQ / tone shaping)
-- ─────────────────────────────────────────────────────────────────────────────

-- Low-pass filter: attenuates frequencies above the cutoff (muffled sound)
music:setLowpass(800)   -- 800 Hz cutoff (good for underwater or behind walls)
local lp = music:getLowpass()

-- High-pass filter: attenuates frequencies below the cutoff (thin sound)
music:setHighpass(200)  -- 200 Hz cutoff (removes bass rumble)
local hp = music:getHighpass()

-- Remove all filters
music:clearFilter()

-- ─────────────────────────────────────────────────────────────────────────────
-- Fade In
-- ─────────────────────────────────────────────────────────────────────────────

-- Begin playback with a fade-in over N seconds
music:fadeIn(2.0)         -- fade in over 2 s
local fade_dur = music:getFadeIn()

-- ─────────────────────────────────────────────────────────────────────────────
-- Clone (for polyphonic playback of the same sound)
-- ─────────────────────────────────────────────────────────────────────────────

-- Clone creates a second source referencing the same underlying audio data.
-- Use this to play the same sound effect multiple times simultaneously.
local sfx2 = sfx_coin:clone()
sfx2:play()   -- plays at the same time as sfx_coin

-- Source type query
local t = sfx_jump:getType()   -- → "static" or "stream"

-- ─────────────────────────────────────────────────────────────────────────────
-- Master Volume
-- ─────────────────────────────────────────────────────────────────────────────

luna.audio.setMasterVolume(0.9)
local master = luna.audio.getMasterVolume()

-- Get a list of all currently playing/paused Sources
local active = luna.audio.getActiveSources()  -- → {Source, Source, ...}

-- ─────────────────────────────────────────────────────────────────────────────
-- Buses (mixer channels for category-level volume control)
-- ─────────────────────────────────────────────────────────────────────────────

-- Get or create a named bus (buses are global singletons by name)
local sfx_bus   = luna.audio.newBus("sfx")
local music_bus = luna.audio.newBus("music")
local ui_bus    = luna.audio.newBus("ui")

-- Retrieve an already-created bus by name
local mb = luna.audio.getBus("music")

-- Bus controls (affect all sources routed through this bus)
music_bus:setVolume(0.8)
local bvol = music_bus:getVolume()

music_bus:setPitch(1.0)
local bpitch = music_bus:getPitch()

sfx_bus:pause()
sfx_bus:resume()
local is_paused = sfx_bus:isPaused()

local bus_name = music_bus:getName()  -- → "music"

-- Route a source to a bus (platform dependent / future-facing)
-- Currently sources play through the default mixer channel.
-- Bus routing may be extended in future versions.

-- ─────────────────────────────────────────────────────────────────────────────
-- SoundData — Raw PCM Audio Representation
-- ─────────────────────────────────────────────────────────────────────────────

-- Load compressed audio into a decoded PCM buffer.
-- Unlike "static" Sources, SoundData gives you sample-level access.
-- This is useful for: procedural audio, oscilloscope visualisers, custom pitch shifting.

local sd = luna.audio.newSource("sounds/beep.ogg", "static")
local sound_data = sd:getSoundData and sd:getSoundData()  -- retrieve from source if available
-- Or load SoundData directly:
-- local sound_data = luna.sound.newSoundData("sounds/beep.ogg")

-- Metadata
local channels    = sound_data:getChannelCount()   -- 1 (mono) or 2 (stereo)
local bit_depth   = sound_data:getBitDepth()       -- 8 or 16
local sample_rate = sound_data:getSampleRate()     -- e.g. 44100
local dur         = sound_data:getDuration()       -- seconds

-- Seek / tell (by sample offset)
sound_data:seek(0)     -- rewind
local s = sound_data:tell()
local can_seek = sound_data:isSeekable()

-- Decode to a new independent buffer (creates a copy)
local decoded = sound_data:decode()

-- Release memory when finished
sound_data:release()

-- ─────────────────────────────────────────────────────────────────────────────
-- MIDI Playback  (midi_decoder + midi_player)
-- ─────────────────────────────────────────────────────────────────────────────

-- Step 1: Create a decoder and load a SoundFont (SF2 instrument bank)
local decoder = luna.audio.newMidiDecoder()
decoder:setSoundFont("instruments/gm.sf2")  -- standard General MIDI font
decoder:load("music/overworld.mid")

-- Optionally load from in-memory data
-- decoder:loadData(bytes)

local is_loaded   = decoder:isLoaded()

-- Step 2: Create a player wrapping the decoder
local player = luna.audio.newMidiPlayer(decoder)

-- Basic transport
player:play()
player:pause()
player:stop()

local playing_midi = player:isPlaying()
local paused_midi  = player:isPaused()

-- Seek / tell in seconds
player:seek(60.0)
local t2 = player:tell()

local total = player:getDuration()

-- Looping
player:setLooping(true)
local looping = player:isLooping()

-- Volume
player:setVolume(1.0)

-- Tempo
local orig_bpm = player:getOriginalTempo()  -- BPM from the MIDI file
player:setTempo(140)                         -- override BPM
player:setTempoScale(1.25)                   -- scale relative to file tempo

-- Per-MIDI-channel control (channels 0–15; channel 9 = drums)
player:setChannelVolume(0, 0.8)   -- channel 0 at 80%
local ch_vol = player:getChannelVolume(0)

player:setChannelMuted(9, true)   -- silence drums
local muted = player:isChannelMuted(9)

player:soloChannel(0)   -- play only channel 0
player:unsoloAll()      -- restore all channels

-- Per-track control
local tracks = player:getTrackCount()
player:setTrackMuted(2, true)    -- mute track 2 (0-based)
local track_muted = player:isTrackMuted(2)

-- ─── Bus ────────────────────────────────────────────────────────────────────────
-- Bus objects are returned by luna.audio.newBus() and represent a named audio
-- routing channel with independent volume and pitch controls.
local bus_name    = bus:getName()       -- "Music"
bus:setVolume(0.8)
local bus_vol     = bus:getVolume()     -- 0.8
bus:setPitch(1.0)
local bus_pitch   = bus:getPitch()      -- 1.0
bus:pause()
local bus_paused  = bus:isPaused()      -- true
bus:resume()
local bus_type = bus:type()  -- "Bus"
local bus_is_type = bus:typeOf("Bus")   -- true

-- ─── Decoder ────────────────────────────────────────────────────────────────────
-- Decoder objects are returned by luna.audio.newDecoder() and provide
-- streaming read access to an audio file.
local channels  = decoder:getChannelCount()  -- 2 (stereo)
local bits      = decoder:getBitDepth()      -- 16
local rate      = decoder:getSampleRate()    -- 44100
local dur       = decoder:getDuration()      -- 183.4
local can_seek  = decoder:isSeekable()       -- true
decoder:seek(30.0)                           -- jump to 30 s
local pos       = decoder:tell()             -- 30.0
local buf       = decoder:decode()           -- decode next chunk  
decoder:rewind()
decoder:release()
local decoder_type = decoder:type()  -- "Decoder"
local decoder_is_type = decoder:typeOf("Decoder") -- true

local midi_bus = midiplayer:getBus()  -- Returns the assigned bus, or nil
local channel_instrument = midiplayer:getChannelInstrument(1)  -- Returns the GM instrument for a MIDI channel (1-indexed)
local file_path = midiplayer:getFilePath()  -- Returns the file path of the loaded MIDI, or nil
local note_count = midiplayer:getNoteCount()  -- Returns the total note count in the MIDI sequence
local sound_font_path = midiplayer:getSoundFontPath()  -- Returns the SoundFont file path, or nil (stub)
local tempo = midiplayer:getTempo()  -- Returns the current tempo in BPM
local tempo_scale = midiplayer:getTempoScale()  -- Returns the current tempo scale factor
local ticks_per_beat = midiplayer:getTicksPerBeat()  -- Returns the PPQ resolution from the MIDI header
local track_name = midiplayer:getTrackName(1)  -- Returns the name of a MIDI track (1-indexed), or nil
midiplayer:setBus(bus)  -- Routes MIDI output through a bus (or nil to clear)
midiplayer:setOnEnd(function() end)  -- Registers a playback-end callback (stub)
midiplayer:setOnNoteOff(function() end)  -- Registers a note-off callback (stub)
midiplayer:setOnNoteOn(function() end)  -- Registers a note-on callback (stub)
local midiplayer_type = midiplayer:type()  -- "MidiPlayer"
local midiplayer_is_type = midiplayer:typeOf("MidiPlayer")  -- Returns true if this object is of the given type
midiplayer:useDefaultSoundFont()  -- Reverts to the built-in default SoundFont (stub)

-- ─── luna.audio ────────────────────────────────────────────────────────────────
local add_effect = luna.audio.add_effect("name", "type", {})  -- Adds a DSP effect to a bus
luna.audio.clearFilter(source)  -- Removes any active filter from a source
luna.audio.clearMidiSoundFont()  -- Unloads the active SoundFont
local clone = luna.audio.clone(source)  -- Creates an independent copy of a source
luna.audio.create_bus("name", "name")  -- Creates a bus by name (functional style)
luna.audio.fadeIn(source, 1.0)  -- Fades a source in from silence over the given duration
local active_source_count = luna.audio.getActiveSourceCount()  -- Returns the number of currently playing sources
local distance_model = luna.audio.getDistanceModel()  -- Returns the current distance model name
local doppler_scale = luna.audio.getDopplerScale()  -- Returns the current Doppler scale
local duration = luna.audio.getDuration(source)  -- Returns the total duration of a source in seconds
local fade_in = luna.audio.getFadeIn(source)  -- Returns the fade-in duration of a source
local free_buffer_count = luna.audio.getFreeBufferCount(1)  -- Returns the free buffer slots in a queueable source
local highpass = luna.audio.getHighpass(source)  -- Returns the high-pass filter cutoff of a source
local listener = luna.audio.getListener()  -- Returns the 3D listener position (x, y, z)
local listener2_d = luna.audio.getListener2D()  -- Returns the 2D listener position (x, y)
local lowpass = luna.audio.getLowpass(source)  -- Returns the low-pass filter cutoff of a source
local max_sources = luna.audio.getMaxSources()  -- Returns the maximum number of simultaneous sources
local meter = luna.audio.getMeter()  -- Returns the current peak level (stub)
local orientation = luna.audio.getOrientation(source)  -- Returns the 6-component orientation of a source
local pan = luna.audio.getPan(source)  -- Returns the source stereo panning
local pitch = luna.audio.getPitch(source)  -- Returns the source pitch multiplier
local playback_device = luna.audio.getPlaybackDevice()  -- Returns the current audio output device name
local playback_devices = luna.audio.getPlaybackDevices()  -- Returns a table of available audio output device names
local position = luna.audio.getPosition(source)  -- Returns the 3D position of a source (x, y, z)
local source_bus = luna.audio.getSourceBus(source)  -- Returns the bus a source is assigned to, or nil
local source_count = luna.audio.getSourceCount()  -- Returns the total number of registered sources
local source_type = luna.audio.getSourceType(source)  -- Returns the type string ("static" or "stream") of a source
local velocity = luna.audio.getVelocity(source)  -- Returns the velocity of a source (x, y, z)
local volume = luna.audio.getVolume(source)  -- Returns the source volume
local has_midi_sound_font = luna.audio.hasMidiSoundFont()  -- Returns true if a SoundFont is loaded
local is_looping = luna.audio.isLooping(source)  -- Returns true if looping is enabled
local is_paused = luna.audio.isPaused(source)  -- Returns true if the source is paused
local is_playing = luna.audio.isPlaying(source)  -- Returns true if the source is playing
local is_stopped = luna.audio.isStopped(source)  -- Returns true if the source is stopped
local decoder = luna.audio.newDecoder("music/intro.ogg", 4096)  -- Creates a streaming audio decoder
local queueable_source = luna.audio.newQueueableSource(1, 1, 1, 1)  -- Creates a queueable source for manual PCM buffering
local sounddata = luna.audio.newSoundData("effects/laser.wav")  -- Creates a SoundData from a file, or a silent buffer if nil
luna.audio.pause(source)  -- Pauses playback at the current position
luna.audio.pauseAll()  -- Pauses all currently playing sources
local play = luna.audio.play(source, {})  -- Plays a source, with optional bus routing via options table
luna.audio.playLooping(source)  -- Plays the source in a continuous loop
luna.audio.playQueueable(1)  -- Starts playback of a queueable source
luna.audio.queueSource(1, sounddata)  -- Pushes a SoundData buffer into a queueable source
local release = luna.audio.release(source)  -- Releases a source and frees its memory
local remove_effect = luna.audio.remove_effect("name", 1)  -- Removes a DSP effect from a bus
luna.audio.resume(source)  -- Resumes playback from pause
luna.audio.resumeAll()  -- Resumes all paused sources
luna.audio.seek(source, 1.0)  -- Seeks to a time position in seconds
luna.audio.setDistanceModel("inverse")  -- "none", "inverse", "linear", "exponent"
luna.audio.setDopplerScale(1.0)  -- Sets the global Doppler effect scale
luna.audio.setHighpass(source, 1)  -- Applies a high-pass filter to a source
luna.audio.setListener(1.0, 1.0, 1.0)  -- Sets the 3D listener position
luna.audio.setListener2D(1.0, 1.0)  -- Sets the 2D listener position for spatial audio
luna.audio.setLooping(source, false)  -- Enables or disables looping
luna.audio.setLowpass(source, 1)  -- Applies a low-pass filter to a source
luna.audio.setMeter(1.0)  -- Sets the metering scale (stub)
luna.audio.setMidiSoundFont("path/to/file")  -- Sets the global SoundFont for MIDI synthesis
luna.audio.setOrientation(source, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)  -- Sets the 6-component orientation of a source
luna.audio.setPan(source, 1.0)  -- Sets stereo panning (-1.0 left to 1.0 right)
luna.audio.setPitch(source, 1.0)  -- Sets source pitch multiplier
luna.audio.setPlaybackDevice("name")  -- Selects an audio output device by name
luna.audio.setPosition(source, 1.0, 1.0, 1.0)  -- Sets the 3D position of a source
luna.audio.setSourceBus(source, bus)  -- Assigns a source to a bus
luna.audio.setVelocity(source, 1.0, 1.0, 1.0)  -- Sets the velocity of a source for Doppler
luna.audio.setVolume(source, 1.0)  -- Sets source playback volume
luna.audio.set_bus_volume("name", 1.0)  -- Sets a bus volume by name
local set_effect_param = luna.audio.set_effect_param("name", 1, "name", 1.0)  -- Sets a parameter on a DSP effect
luna.audio.stop(source)  -- Stops playback and resets seek position
luna.audio.stopAll()  -- Stops all currently playing sources
luna.audio.stopQueueable(1)  -- Stops a queueable source and drains its buffers
local tell = luna.audio.tell(source)  -- Returns the current playback position in seconds
