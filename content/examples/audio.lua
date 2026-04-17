-- content/examples/audio.lua
-- Lurek2D lurek.audio API Reference
-- Run with: cargo run -- content/examples/audio
--
-- Scenario: A side-scrolling platformer with layered audio — background music,
-- sound effects for jumping/landing/collecting coins, spatial audio for enemies,
-- audio buses for mixing, MIDI playback for chiptune tracks, sound pooling for
-- rapid-fire effects, procedural waveform generation, and offline DSP processing.

print("=== lurek.audio — Platformer Audio System ===\n")

-- =============================================================================
-- Source Creation & Basic Playback
-- =============================================================================

-- ---- Stub: lurek.audio.newSource ------------------------------------------
--@api-stub: lurek.audio.newSource
-- Load a sound file into a Source object. "static" loads entirely into memory
-- (good for short SFX), "stream" decodes on-the-fly (good for long music).
local jump_sfx = lurek.audio.newSource("assets/audio/jump.wav", "static")
local coin_sfx = lurek.audio.newSource("assets/audio/coin.wav", "static")
local bgm = lurek.audio.newSource("assets/audio/level1_theme.ogg", "stream")
print("loaded: jump_sfx (static), coin_sfx (static), bgm (stream)")

-- ---- Stub: lurek.audio.play -----------------------------------------------
--@api-stub: lurek.audio.play
-- Play a source from the beginning. If already playing, restarts.
lurek.audio.play(jump_sfx)
print("jump SFX playing")

-- ---- Stub: lurek.audio.stop -----------------------------------------------
--@api-stub: lurek.audio.stop
-- Stop playback and reset position to the start.
lurek.audio.stop(jump_sfx)
print("jump SFX stopped")

-- ---- Stub: lurek.audio.pause ----------------------------------------------
--@api-stub: lurek.audio.pause
-- Pause without resetting position — resume picks up where it left off.
lurek.audio.play(bgm)
lurek.audio.pause(bgm)
print("BGM paused mid-track")

-- ---- Stub: lurek.audio.resume ---------------------------------------------
--@api-stub: lurek.audio.resume
lurek.audio.resume(bgm)
print("BGM resumed from pause point")

-- ---- Stub: lurek.audio.playLooping ----------------------------------------
--@api-stub: lurek.audio.playLooping
-- Start looping playback — perfect for background music and ambient loops.
lurek.audio.playLooping(bgm)
print("BGM looping indefinitely")

-- =============================================================================
-- Volume, Pitch & Pan — per-source audio properties
-- =============================================================================

-- ---- Stub: lurek.audio.setVolume ------------------------------------------
--@api-stub: lurek.audio.setVolume
-- Set per-source volume (0.0 = silent, 1.0 = full). Stack with master volume.
lurek.audio.setVolume(jump_sfx, 0.7)
lurek.audio.setVolume(coin_sfx, 0.5)
lurek.audio.setVolume(bgm, 0.4)
print("volumes: jump=0.7, coin=0.5, bgm=0.4")

-- ---- Stub: lurek.audio.getVolume ------------------------------------------
--@api-stub: lurek.audio.getVolume
local bgm_vol = lurek.audio.getVolume(bgm)
print("BGM volume: " .. string.format("%.1f", bgm_vol))

-- ---- Stub: lurek.audio.setPitch -------------------------------------------
--@api-stub: lurek.audio.setPitch
-- Pitch shift: 0.5 = octave down, 2.0 = octave up. Good for power-up effects.
lurek.audio.setPitch(coin_sfx, 1.2)
print("coin SFX pitched up 20% (sparkly feeling)")

-- ---- Stub: lurek.audio.getPitch -------------------------------------------
--@api-stub: lurek.audio.getPitch
print("coin pitch: " .. tostring(lurek.audio.getPitch(coin_sfx)))

-- ---- Stub: lurek.audio.setPan ---------------------------------------------
--@api-stub: lurek.audio.setPan
-- Pan left/right: -1.0 = full left, 0.0 = center, 1.0 = full right.
lurek.audio.setPan(jump_sfx, -0.3)
print("jump SFX panned slightly left (player on left side of screen)")

-- ---- Stub: lurek.audio.getPan ---------------------------------------------
--@api-stub: lurek.audio.getPan
print("jump pan: " .. tostring(lurek.audio.getPan(jump_sfx)))

-- ---- Stub: lurek.audio.setMasterVolume ------------------------------------
--@api-stub: lurek.audio.setMasterVolume
-- Master volume scales ALL sources. Use for the global volume slider in settings.
lurek.audio.setMasterVolume(0.8)
print("master volume set to 80%")

-- ---- Stub: lurek.audio.getMasterVolume ------------------------------------
--@api-stub: lurek.audio.getMasterVolume
print("master volume: " .. tostring(lurek.audio.getMasterVolume()))

-- =============================================================================
-- Source State Queries
-- =============================================================================

-- ---- Stub: lurek.audio.isPlaying ------------------------------------------
--@api-stub: lurek.audio.isPlaying
print("BGM playing: " .. tostring(lurek.audio.isPlaying(bgm)))

-- ---- Stub: lurek.audio.isPaused -------------------------------------------
--@api-stub: lurek.audio.isPaused
print("BGM paused: " .. tostring(lurek.audio.isPaused(bgm)))

-- ---- Stub: lurek.audio.isStopped ------------------------------------------
--@api-stub: lurek.audio.isStopped
print("jump stopped: " .. tostring(lurek.audio.isStopped(jump_sfx)))

-- ---- Stub: lurek.audio.setLooping -----------------------------------------
--@api-stub: lurek.audio.setLooping
lurek.audio.setLooping(bgm, true)
print("BGM looping enabled")

-- ---- Stub: lurek.audio.isLooping ------------------------------------------
--@api-stub: lurek.audio.isLooping
print("BGM looping: " .. tostring(lurek.audio.isLooping(bgm)))

-- ---- Stub: lurek.audio.getActiveSourceCount -------------------------------
--@api-stub: lurek.audio.getActiveSourceCount
print("active sources: " .. tostring(lurek.audio.getActiveSourceCount()))

-- ---- Stub: lurek.audio.getSourceCount -------------------------------------
--@api-stub: lurek.audio.getSourceCount
print("total sources loaded: " .. tostring(lurek.audio.getSourceCount()))

-- ---- Stub: lurek.audio.getSourceType --------------------------------------
--@api-stub: lurek.audio.getSourceType
-- "static" for in-memory SFX, "stream" for on-the-fly decoded music.
print("jump type: " .. tostring(lurek.audio.getSourceType(jump_sfx)))
print("bgm type: " .. tostring(lurek.audio.getSourceType(bgm)))

-- ---- Stub: lurek.audio.getMaxSources --------------------------------------
--@api-stub: lurek.audio.getMaxSources
print("max simultaneous sources: " .. tostring(lurek.audio.getMaxSources()))

-- ---- Stub: lurek.audio.getDuration ----------------------------------------
--@api-stub: lurek.audio.getDuration
local dur = lurek.audio.getDuration(bgm)
print("BGM duration: " .. string.format("%.1f", dur) .. " seconds")

-- =============================================================================
-- Seek & Tell — playback position
-- =============================================================================

-- ---- Stub: lurek.audio.tell -----------------------------------------------
--@api-stub: lurek.audio.tell
-- Get current playback position in seconds. Use for lyrics sync or progress bars.
local pos = lurek.audio.tell(bgm)
print("BGM position: " .. string.format("%.2f", pos) .. "s")

-- ---- Stub: lurek.audio.seek -----------------------------------------------
--@api-stub: lurek.audio.seek
-- Jump to a specific time. Use for checkpoint restarts or music section skips.
lurek.audio.seek(bgm, 30.0)
print("BGM seeked to 30.0s (skipped intro)")

-- =============================================================================
-- Global Playback Control
-- =============================================================================

-- ---- Stub: lurek.audio.pauseAll -------------------------------------------
--@api-stub: lurek.audio.pauseAll
-- Pause everything at once — use when opening the pause menu.
lurek.audio.pauseAll()
print("all audio paused (pause menu opened)")

-- ---- Stub: lurek.audio.resumeAll ------------------------------------------
--@api-stub: lurek.audio.resumeAll
lurek.audio.resumeAll()
print("all audio resumed (pause menu closed)")

-- ---- Stub: lurek.audio.stopAll --------------------------------------------
--@api-stub: lurek.audio.stopAll
-- Stop and reset everything — use on level transitions.
lurek.audio.stopAll()
print("all audio stopped (level transition)")

-- ---- Stub: lurek.audio.clone ----------------------------------------------
--@api-stub: lurek.audio.clone
-- Clone a source to play overlapping instances of the same sound.
-- Essential for rapid-fire SFX like footsteps or gunshots.
local jump_sfx2 = lurek.audio.clone(jump_sfx)
print("jump SFX cloned for overlapping playback")

-- ---- Stub: lurek.audio.release --------------------------------------------
--@api-stub: lurek.audio.release
-- Free a source's memory when no longer needed.
lurek.audio.release(jump_sfx2)
print("cloned jump SFX released")

-- =============================================================================
-- Filters — low/highpass for environmental effects
-- =============================================================================

-- ---- Stub: lurek.audio.setLowpass -----------------------------------------
--@api-stub: lurek.audio.setLowpass
-- Lowpass filter: muffle sounds when underwater or behind walls.
-- Cutoff 0.0=fully muffled, 1.0=no filter.
lurek.audio.setLowpass(bgm, 0.3)
print("BGM lowpass at 0.3 (underwater effect)")

-- ---- Stub: lurek.audio.getLowpass -----------------------------------------
--@api-stub: lurek.audio.getLowpass
print("BGM lowpass: " .. tostring(lurek.audio.getLowpass(bgm)))

-- ---- Stub: lurek.audio.setHighpass ----------------------------------------
--@api-stub: lurek.audio.setHighpass
-- Highpass filter: thin tinny sound for radio/phone effects.
lurek.audio.setHighpass(bgm, 0.6)
print("BGM highpass at 0.6 (radio transmission effect)")

-- ---- Stub: lurek.audio.getHighpass ----------------------------------------
--@api-stub: lurek.audio.getHighpass
print("BGM highpass: " .. tostring(lurek.audio.getHighpass(bgm)))

-- ---- Stub: lurek.audio.clearFilter ----------------------------------------
--@api-stub: lurek.audio.clearFilter
lurek.audio.clearFilter(bgm)
print("BGM filters cleared (back to normal)")

-- ---- Stub: lurek.audio.fadeIn ---------------------------------------------
--@api-stub: lurek.audio.fadeIn
-- Fade in over N seconds. Perfect for scene transitions.
lurek.audio.fadeIn(bgm, 2.0)
print("BGM fading in over 2 seconds")

-- ---- Stub: lurek.audio.getFadeIn ------------------------------------------
--@api-stub: lurek.audio.getFadeIn
print("BGM fade-in duration: " .. tostring(lurek.audio.getFadeIn(bgm)) .. "s")

-- =============================================================================
-- Stereo Width & Random Pitch — variation for SFX
-- =============================================================================

-- ---- Stub: lurek.audio.setStereoWidth -------------------------------------
--@api-stub: lurek.audio.setStereoWidth
-- Widen or narrow the stereo image. 1.0=normal, 0.0=mono, 2.0=extra wide.
lurek.audio.setStereoWidth(bgm, 1.5)
print("BGM stereo width: 1.5 (wider soundstage)")

-- ---- Stub: lurek.audio.getStereoWidth -------------------------------------
--@api-stub: lurek.audio.getStereoWidth
print("BGM stereo width: " .. tostring(lurek.audio.getStereoWidth(bgm)))

-- ---- Stub: lurek.audio.setRandomPitch -------------------------------------
--@api-stub: lurek.audio.setRandomPitch
-- Add pitch variation each time the source plays. Prevents repetitive SFX.
-- Range 0.05 means pitch varies +/-5% around the base pitch.
lurek.audio.setRandomPitch(coin_sfx, 0.08)
print("coin SFX: random pitch +/-8% (each pickup sounds slightly different)")

-- ---- Stub: lurek.audio.clearRandomPitch -----------------------------------
--@api-stub: lurek.audio.clearRandomPitch
lurek.audio.clearRandomPitch(coin_sfx)
print("coin random pitch cleared")

-- ---- Stub: lurek.audio.crossfade ------------------------------------------
--@api-stub: lurek.audio.crossfade
-- Smoothly transition between two sources over N seconds.
-- Use for zone transitions: forest ambience -> cave ambience.
local cave_ambience = lurek.audio.newSource("assets/audio/cave_drips.ogg", "stream")
lurek.audio.crossfade(bgm, cave_ambience, 3.0)
print("crossfading BGM -> cave ambience over 3 seconds")

-- =============================================================================
-- 2D Spatial Audio — positional sound for enemies and items
-- =============================================================================

-- ---- Stub: lurek.audio.setListener2D --------------------------------------
--@api-stub: lurek.audio.setListener2D
-- Set the 2D listener (camera/player) position. All spatial audio is relative to this.
lurek.audio.setListener2D(400, 300)
print("2D listener at player position (400, 300)")

-- ---- Stub: lurek.audio.getListener2D --------------------------------------
--@api-stub: lurek.audio.getListener2D
local lx, ly = lurek.audio.getListener2D()
print("listener 2D: (" .. tostring(lx) .. ", " .. tostring(ly) .. ")")

-- ---- Stub: lurek.audio.setListener ----------------------------------------
--@api-stub: lurek.audio.setListener
-- 3D listener position (x, y, z). Z=0 for 2D games.
lurek.audio.setListener(400, 300, 0)
print("3D listener at (400, 300, 0)")

-- ---- Stub: lurek.audio.getListener ----------------------------------------
--@api-stub: lurek.audio.getListener
local l3x, l3y, l3z = lurek.audio.getListener()
print("3D listener: (" .. tostring(l3x) .. ", " .. tostring(l3y) .. ", " .. tostring(l3z) .. ")")

-- ---- Stub: lurek.audio.setPosition ----------------------------------------
--@api-stub: lurek.audio.setPosition
-- Place an enemy growl at world position (600, 200) so it pans/attenuates
-- relative to the listener.
local enemy_growl = lurek.audio.newSource("assets/audio/growl.wav", "static")
lurek.audio.setPosition(enemy_growl, 600, 200, 0)
print("enemy growl positioned at (600, 200)")

-- ---- Stub: lurek.audio.getPosition ----------------------------------------
--@api-stub: lurek.audio.getPosition
local ex, ey, ez = lurek.audio.getPosition(enemy_growl)
print("growl position: (" .. tostring(ex) .. ", " .. tostring(ey) .. ", " .. tostring(ez) .. ")")

-- ---- Stub: lurek.audio.setVelocity ---------------------------------------
--@api-stub: lurek.audio.setVelocity
-- Set source velocity for Doppler effect. Moving enemy = pitch shift.
lurek.audio.setVelocity(enemy_growl, -5.0, 0, 0)
print("enemy moving left at 5 units/s (Doppler: pitch drops as it passes)")

-- ---- Stub: lurek.audio.getVelocity ---------------------------------------
--@api-stub: lurek.audio.getVelocity
local vx, vy, vz = lurek.audio.getVelocity(enemy_growl)
print("growl velocity: (" .. tostring(vx) .. ", " .. tostring(vy) .. ", " .. tostring(vz) .. ")")

-- ---- Stub: lurek.audio.setOrientation -------------------------------------
--@api-stub: lurek.audio.setOrientation
-- Listener facing direction. (forward_x, forward_y, forward_z, up_x, up_y, up_z)
lurek.audio.setOrientation(1, 0, 0, 0, 1, 0)
print("listener facing right (+X), up is +Y")

-- ---- Stub: lurek.audio.getOrientation -------------------------------------
--@api-stub: lurek.audio.getOrientation
local fx, fy, fz, ux, uy, uz = lurek.audio.getOrientation()
print("orientation: forward=(" .. fx .. "," .. fy .. "," .. fz .. ") up=(" .. ux .. "," .. uy .. "," .. uz .. ")")

-- ---- Stub: lurek.audio.setDopplerScale ------------------------------------
--@api-stub: lurek.audio.setDopplerScale
-- Exaggerate or reduce Doppler effect. 0=off, 1=realistic, 2=dramatic.
lurek.audio.setDopplerScale(1.5)
print("Doppler scale: 1.5 (slightly exaggerated for fun)")

-- ---- Stub: lurek.audio.getDopplerScale ------------------------------------
--@api-stub: lurek.audio.getDopplerScale
print("Doppler scale: " .. tostring(lurek.audio.getDopplerScale()))

-- ---- Stub: lurek.audio.setDistanceModel -----------------------------------
--@api-stub: lurek.audio.setDistanceModel
-- Controls how volume drops off with distance. "inverse" is most natural.
lurek.audio.setDistanceModel("inverse")
print("distance model: inverse (realistic falloff)")

-- ---- Stub: lurek.audio.getDistanceModel -----------------------------------
--@api-stub: lurek.audio.getDistanceModel
print("distance model: " .. tostring(lurek.audio.getDistanceModel()))

-- ---- Stub: lurek.audio.setMeter -------------------------------------------
--@api-stub: lurek.audio.setMeter
-- How many world units = 1 meter for distance calculations.
-- If your world uses pixels, set 1 meter = 64 pixels.
lurek.audio.setMeter(64.0)
print("meter scale: 64 pixels = 1 meter")

-- ---- Stub: lurek.audio.getMeter -------------------------------------------
--@api-stub: lurek.audio.getMeter
print("meter scale: " .. tostring(lurek.audio.getMeter()) .. " units/meter")

-- =============================================================================
-- Audio Buses — mixing groups
-- =============================================================================

-- ---- Stub: lurek.audio.newBus ---------------------------------------------
--@api-stub: lurek.audio.newBus
-- Buses group sources for collective volume/effect control.
-- Typical setup: "master" -> "music", "sfx", "voice", "ambient".
local sfx_bus = lurek.audio.newBus("sfx")
local music_bus = lurek.audio.newBus("music")
local ambient_bus = lurek.audio.newBus("ambient")
print("buses created: sfx, music, ambient")

-- ---- Stub: lurek.audio.setSourceBus ---------------------------------------
--@api-stub: lurek.audio.setSourceBus
-- Route sources to their appropriate bus.
lurek.audio.setSourceBus(jump_sfx, "sfx")
lurek.audio.setSourceBus(coin_sfx, "sfx")
lurek.audio.setSourceBus(bgm, "music")
lurek.audio.setSourceBus(cave_ambience, "ambient")
print("sources routed: SFX->sfx bus, BGM->music bus")

-- ---- Stub: lurek.audio.getSourceBus ---------------------------------------
--@api-stub: lurek.audio.getSourceBus
print("jump SFX bus: " .. tostring(lurek.audio.getSourceBus(jump_sfx)))
print("BGM bus: " .. tostring(lurek.audio.getSourceBus(bgm)))

-- ---- Stub: lurek.audio.create_bus -----------------------------------------
--@api-stub: lurek.audio.create_bus
-- Alternative bus creation with inline configuration.
lurek.audio.create_bus("voice", { volume = 0.9 })
print("voice bus created with volume 0.9")

-- ---- Stub: lurek.audio.set_bus_volume -------------------------------------
--@api-stub: lurek.audio.set_bus_volume
-- Adjust bus volume from settings menu sliders.
lurek.audio.set_bus_volume("sfx", 0.7)
lurek.audio.set_bus_volume("music", 0.5)
print("bus volumes: sfx=0.7, music=0.5")

-- ---- Stub: lurek.audio.add_effect ----------------------------------------
--@api-stub: lurek.audio.add_effect
-- Add a reverb effect to the ambient bus for cave echo.
lurek.audio.add_effect("ambient", "reverb", { decay = 2.0, wet = 0.6 })
print("reverb added to ambient bus (cave echo)")

-- ---- Stub: lurek.audio.remove_effect --------------------------------------
--@api-stub: lurek.audio.remove_effect
lurek.audio.remove_effect("ambient", "reverb")
print("reverb removed from ambient bus")

-- ---- Stub: lurek.audio.set_effect_param -----------------------------------
--@api-stub: lurek.audio.set_effect_param
-- Re-add and tweak effect parameters at runtime.
lurek.audio.add_effect("ambient", "reverb", { decay = 2.0, wet = 0.6 })
lurek.audio.set_effect_param("ambient", "reverb", "wet", 0.8)
print("ambient reverb wetness increased to 0.8 (deeper cave)")

-- ---- Stub: lurek.audio.getBusPeak -----------------------------------------
--@api-stub: lurek.audio.getBusPeak
-- Peak meter reading for VU meter display.
local peak = lurek.audio.getBusPeak("sfx")
print("SFX bus peak: " .. string.format("%.3f", peak))

-- ---- Stub: lurek.audio.getBusRms ------------------------------------------
--@api-stub: lurek.audio.getBusRms
-- RMS (average loudness) for smoother VU meter display.
local rms = lurek.audio.getBusRms("sfx")
print("SFX bus RMS: " .. string.format("%.3f", rms))

-- =============================================================================
-- Bus Object Methods
-- =============================================================================

-- ---- Stub: Bus:getName ----------------------------------------------------
--@api-stub: Bus:getName
print("bus name: " .. sfx_bus:getName())

-- ---- Stub: Bus:setVolume --------------------------------------------------
--@api-stub: Bus:setVolume
sfx_bus:setVolume(0.8)
print("SFX bus volume set to 0.8")

-- ---- Stub: Bus:getVolume --------------------------------------------------
--@api-stub: Bus:getVolume
print("SFX bus volume: " .. tostring(sfx_bus:getVolume()))

-- ---- Stub: Bus:setPitch ---------------------------------------------------
--@api-stub: Bus:setPitch
-- Slow down all SFX during a slow-motion power-up.
sfx_bus:setPitch(0.7)
print("SFX bus pitch: 0.7 (slow-motion effect)")

-- ---- Stub: Bus:getPitch ---------------------------------------------------
--@api-stub: Bus:getPitch
print("SFX bus pitch: " .. tostring(sfx_bus:getPitch()))

-- ---- Stub: Bus:pause ------------------------------------------------------
--@api-stub: Bus:pause
-- Pause just the music bus when entering a menu (SFX still play).
music_bus:pause()
print("music bus paused (menu opened, SFX still active)")

-- ---- Stub: Bus:resume -----------------------------------------------------
--@api-stub: Bus:resume
music_bus:resume()
print("music bus resumed")

-- ---- Stub: Bus:isPaused ---------------------------------------------------
--@api-stub: Bus:isPaused
print("music bus paused: " .. tostring(music_bus:isPaused()))

-- ---- Stub: Bus:type -------------------------------------------------------
--@api-stub: Bus:type
-- ---- Stub: Bus:typeOf -----------------------------------------------------
--@api-stub: Bus:typeOf
print("bus type: " .. tostring(sfx_bus:type()))
print("bus typeOf: " .. tostring(sfx_bus:typeOf("Bus")))

-- ---- Stub: Bus:clearDuck --------------------------------------------------
--@api-stub: Bus:clearDuck
-- Clear ducking (auto-volume-reduction when another bus is active).
sfx_bus:clearDuck()
print("SFX bus ducking cleared")

-- ---- Stub: Bus:getPeak ----------------------------------------------------
--@api-stub: Bus:getPeak
local bus_peak = sfx_bus:getPeak()
print("SFX bus peak level: " .. string.format("%.3f", bus_peak))

-- =============================================================================
-- MIDI Player — chiptune music playback
-- =============================================================================

-- ---- Stub: lurek.audio.newMidiPlayer --------------------------------------
--@api-stub: lurek.audio.newMidiPlayer
-- MIDI player for tracker-style or chiptune music. Requires a SoundFont.
local midi = lurek.audio.newMidiPlayer()
print("MIDI player created")

-- ---- Stub: lurek.audio.setMidiSoundFont -----------------------------------
--@api-stub: lurek.audio.setMidiSoundFont
-- Set a global default SoundFont that all MIDI players use.
lurek.audio.setMidiSoundFont("assets/audio/gm_soundfont.sf2")
print("default SoundFont set: gm_soundfont.sf2")

-- ---- Stub: lurek.audio.hasMidiSoundFont -----------------------------------
--@api-stub: lurek.audio.hasMidiSoundFont
print("has default SoundFont: " .. tostring(lurek.audio.hasMidiSoundFont()))

-- ---- Stub: lurek.audio.clearMidiSoundFont ---------------------------------
--@api-stub: lurek.audio.clearMidiSoundFont
lurek.audio.clearMidiSoundFont()
print("default SoundFont cleared")

-- ---- Stub: MidiPlayer:load -----------------------------------------------
--@api-stub: MidiPlayer:load
midi:load("assets/audio/boss_battle.mid")
print("MIDI file loaded: boss_battle.mid")

-- ---- Stub: MidiPlayer:loadData --------------------------------------------
--@api-stub: MidiPlayer:loadData
-- Load MIDI from raw byte data (e.g. from a network stream or memory).
local midi_bytes = "\0\0\0\0"  -- placeholder; real data would come from a file
midi:loadData(midi_bytes)
print("MIDI loaded from raw data")

-- ---- Stub: MidiPlayer:isLoaded --------------------------------------------
--@api-stub: MidiPlayer:isLoaded
print("MIDI loaded: " .. tostring(midi:isLoaded()))

-- ---- Stub: MidiPlayer:getFilePath -----------------------------------------
--@api-stub: MidiPlayer:getFilePath
print("MIDI file: " .. tostring(midi:getFilePath()))

-- ---- Stub: MidiPlayer:setSoundFont ----------------------------------------
--@api-stub: MidiPlayer:setSoundFont
-- Override the default SoundFont for this specific player.
midi:setSoundFont("assets/audio/retro_synth.sf2")
print("per-player SoundFont: retro_synth.sf2")

-- ---- Stub: MidiPlayer:getSoundFontPath ------------------------------------
--@api-stub: MidiPlayer:getSoundFontPath
print("MIDI SoundFont: " .. tostring(midi:getSoundFontPath()))

-- ---- Stub: MidiPlayer:useDefaultSoundFont ---------------------------------
--@api-stub: MidiPlayer:useDefaultSoundFont
midi:useDefaultSoundFont()
print("MIDI player reverted to default SoundFont")

-- ---- Stub: MidiPlayer:play -----------------------------------------------
--@api-stub: MidiPlayer:play
midi:play()
print("MIDI playing")

-- ---- Stub: MidiPlayer:pause -----------------------------------------------
--@api-stub: MidiPlayer:pause
midi:pause()
print("MIDI paused")

-- ---- Stub: MidiPlayer:stop ------------------------------------------------
--@api-stub: MidiPlayer:stop
midi:stop()
print("MIDI stopped")

-- ---- Stub: MidiPlayer:isPlaying -------------------------------------------
--@api-stub: MidiPlayer:isPlaying
print("MIDI playing: " .. tostring(midi:isPlaying()))

-- ---- Stub: MidiPlayer:isPaused --------------------------------------------
--@api-stub: MidiPlayer:isPaused
print("MIDI paused: " .. tostring(midi:isPaused()))

-- ---- Stub: MidiPlayer:seek ------------------------------------------------
--@api-stub: MidiPlayer:seek
midi:seek(15.0)
print("MIDI seeked to 15.0s (skip to chorus)")

-- ---- Stub: MidiPlayer:tell ------------------------------------------------
--@api-stub: MidiPlayer:tell
print("MIDI position: " .. string.format("%.2f", midi:tell()) .. "s")

-- ---- Stub: MidiPlayer:getDuration -----------------------------------------
--@api-stub: MidiPlayer:getDuration
print("MIDI duration: " .. string.format("%.1f", midi:getDuration()) .. "s")

-- ---- Stub: MidiPlayer:setLooping ------------------------------------------
--@api-stub: MidiPlayer:setLooping
midi:setLooping(true)
print("MIDI looping enabled (boss music loops)")

-- ---- Stub: MidiPlayer:isLooping -------------------------------------------
--@api-stub: MidiPlayer:isLooping
print("MIDI looping: " .. tostring(midi:isLooping()))

-- ---- Stub: MidiPlayer:setVolume -------------------------------------------
--@api-stub: MidiPlayer:setVolume
midi:setVolume(0.6)
print("MIDI volume: 0.6")

-- ---- Stub: MidiPlayer:getVolume -------------------------------------------
--@api-stub: MidiPlayer:getVolume
print("MIDI volume: " .. tostring(midi:getVolume()))

-- ---- Stub: MidiPlayer:setBus ----------------------------------------------
--@api-stub: MidiPlayer:setBus
midi:setBus("music")
print("MIDI routed to music bus")

-- ---- Stub: MidiPlayer:getBus ----------------------------------------------
--@api-stub: MidiPlayer:getBus
print("MIDI bus: " .. tostring(midi:getBus()))

-- ---- Stub: MidiPlayer:setTempo --------------------------------------------
--@api-stub: MidiPlayer:setTempo
-- Override tempo in BPM. Use for dramatic slow-downs or speed-ups.
midi:setTempo(140)
print("MIDI tempo set to 140 BPM (battle intensity)")

-- ---- Stub: MidiPlayer:getTempo --------------------------------------------
--@api-stub: MidiPlayer:getTempo
print("MIDI tempo: " .. tostring(midi:getTempo()) .. " BPM")

-- ---- Stub: MidiPlayer:getOriginalTempo ------------------------------------
--@api-stub: MidiPlayer:getOriginalTempo
print("MIDI original tempo: " .. tostring(midi:getOriginalTempo()) .. " BPM")

-- ---- Stub: MidiPlayer:setTempoScale ---------------------------------------
--@api-stub: MidiPlayer:setTempoScale
-- Scale tempo relative to original. 1.0=normal, 1.5=50% faster.
midi:setTempoScale(1.2)
print("MIDI tempo scale: 1.2x (20% faster during combat rush)")

-- ---- Stub: MidiPlayer:getTempoScale ---------------------------------------
--@api-stub: MidiPlayer:getTempoScale
print("MIDI tempo scale: " .. tostring(midi:getTempoScale()))

-- ---- Stub: MidiPlayer:getTicksPerBeat -------------------------------------
--@api-stub: MidiPlayer:getTicksPerBeat
print("MIDI ticks/beat: " .. tostring(midi:getTicksPerBeat()))

-- ---- Stub: MidiPlayer:setChannelVolume ------------------------------------
--@api-stub: MidiPlayer:setChannelVolume
-- Mute the drum channel during a quiet stealth section.
midi:setChannelVolume(9, 0.2)  -- channel 9 = drums in General MIDI
print("MIDI drum channel (9) volume reduced to 0.2")

-- ---- Stub: MidiPlayer:getChannelVolume ------------------------------------
--@api-stub: MidiPlayer:getChannelVolume
print("drum channel volume: " .. tostring(midi:getChannelVolume(9)))

-- ---- Stub: MidiPlayer:setChannelMuted -------------------------------------
--@api-stub: MidiPlayer:setChannelMuted
midi:setChannelMuted(9, true)
print("drum channel muted (stealth mode)")

-- ---- Stub: MidiPlayer:isChannelMuted --------------------------------------
--@api-stub: MidiPlayer:isChannelMuted
print("drum channel muted: " .. tostring(midi:isChannelMuted(9)))

-- ---- Stub: MidiPlayer:getChannelInstrument --------------------------------
--@api-stub: MidiPlayer:getChannelInstrument
local instr = midi:getChannelInstrument(0)
print("channel 0 instrument: " .. tostring(instr))

-- ---- Stub: MidiPlayer:getChannelCount -------------------------------------
--@api-stub: MidiPlayer:getChannelCount
print("MIDI channels: " .. tostring(midi:getChannelCount()))

-- ---- Stub: MidiPlayer:soloChannel -----------------------------------------
--@api-stub: MidiPlayer:soloChannel
-- Solo the melody channel for a musical puzzle where the player listens to one part.
midi:soloChannel(0)
print("channel 0 soloed (melody only for puzzle)")

-- ---- Stub: MidiPlayer:unsoloAll -------------------------------------------
--@api-stub: MidiPlayer:unsoloAll
midi:unsoloAll()
print("all channels unsoloed (full arrangement restored)")

-- ---- Stub: MidiPlayer:getTrackCount --------------------------------------
--@api-stub: MidiPlayer:getTrackCount
print("MIDI tracks: " .. tostring(midi:getTrackCount()))

-- ---- Stub: MidiPlayer:getTrackName ----------------------------------------
--@api-stub: MidiPlayer:getTrackName
local track_name = midi:getTrackName(0)
print("track 0 name: " .. tostring(track_name))

-- ---- Stub: MidiPlayer:setTrackMuted ---------------------------------------
--@api-stub: MidiPlayer:setTrackMuted
midi:setTrackMuted(0, false)
print("track 0 unmuted")

-- ---- Stub: MidiPlayer:isTrackMuted ----------------------------------------
--@api-stub: MidiPlayer:isTrackMuted
print("track 0 muted: " .. tostring(midi:isTrackMuted(0)))

-- ---- Stub: MidiPlayer:getNoteCount ----------------------------------------
--@api-stub: MidiPlayer:getNoteCount
print("MIDI note count: " .. tostring(midi:getNoteCount()))

-- ---- Stub: MidiPlayer:setOnNoteOn -----------------------------------------
--@api-stub: MidiPlayer:setOnNoteOn
-- Trigger visual effects when notes play (e.g. particles on beat).
midi:setOnNoteOn(function(channel, note, velocity)
    if velocity > 80 then
        print("  [MIDI] loud note! ch=" .. channel .. " note=" .. note .. " vel=" .. velocity)
    end
end)
print("MIDI note-on callback set (triggers particle effects)")

-- ---- Stub: MidiPlayer:setOnNoteOff ----------------------------------------
--@api-stub: MidiPlayer:setOnNoteOff
midi:setOnNoteOff(function(channel, note)
    -- Release visual effect when note ends
end)
print("MIDI note-off callback set")

-- ---- Stub: MidiPlayer:setOnEnd --------------------------------------------
--@api-stub: MidiPlayer:setOnEnd
midi:setOnEnd(function()
    print("  [MIDI] track ended — transitioning to next phase")
end)
print("MIDI end callback set (triggers music transition)")

-- ---- Stub: MidiPlayer:getSampleRate ---------------------------------------
--@api-stub: MidiPlayer:getSampleRate
print("MIDI sample rate: " .. tostring(midi:getSampleRate()) .. " Hz")

-- ---- Stub: MidiPlayer:setSampleRate ---------------------------------------
--@api-stub: MidiPlayer:setSampleRate
midi:setSampleRate(44100)
print("MIDI sample rate set to 44100 Hz")

-- ---- Stub: MidiPlayer:getChannels -----------------------------------------
--@api-stub: MidiPlayer:getChannels
print("MIDI output channels: " .. tostring(midi:getChannels()))

-- ---- Stub: MidiPlayer:setChannels -----------------------------------------
--@api-stub: MidiPlayer:setChannels
midi:setChannels(2)
print("MIDI output set to stereo (2 channels)")

-- ---- Stub: MidiPlayer:type ------------------------------------------------
--@api-stub: MidiPlayer:type
-- ---- Stub: MidiPlayer:typeOf ----------------------------------------------
--@api-stub: MidiPlayer:typeOf
print("MIDI type: " .. tostring(midi:type()))
print("MIDI typeOf: " .. tostring(midi:typeOf("MidiPlayer")))

-- =============================================================================
-- SoundData — raw sample manipulation
-- =============================================================================

-- ---- Stub: lurek.audio.newSoundData ---------------------------------------
--@api-stub: lurek.audio.newSoundData
-- Create raw PCM data buffer for procedural audio or sample manipulation.
-- 44100 samples, 1 channel, 16-bit = 1 second of mono audio.
local snd = lurek.audio.newSoundData(44100, 44100, 16, 1)
print("SoundData created: 44100 samples, mono, 16-bit")

-- ---- Stub: mlua:getSampleCount --------------------------------------------
--@api-stub: mlua:getSampleCount
print("sample count: " .. tostring(snd:getSampleCount()))

-- ---- Stub: mlua:getSampleRate ---------------------------------------------
--@api-stub: mlua:getSampleRate
print("sample rate: " .. tostring(snd:getSampleRate()) .. " Hz")

-- ---- Stub: mlua:getChannelCount -------------------------------------------
--@api-stub: mlua:getChannelCount
print("channels: " .. tostring(snd:getChannelCount()))

-- ---- Stub: mlua:getDuration -----------------------------------------------
--@api-stub: mlua:getDuration
print("duration: " .. string.format("%.3f", snd:getDuration()) .. "s")

-- ---- Stub: mlua:getBitDepth -----------------------------------------------
--@api-stub: mlua:getBitDepth
print("bit depth: " .. tostring(snd:getBitDepth()))

-- ---- Stub: mlua:setSample -------------------------------------------------
--@api-stub: mlua:setSample
-- Write a 440 Hz sine wave into the buffer (one second of concert A).
for i = 0, 44099 do
    local t = i / 44100
    local sample = math.sin(2 * math.pi * 440 * t) * 0.5
    snd:setSample(i, sample)
end
print("440 Hz sine wave written to SoundData (1 second)")

-- ---- Stub: mlua:getSample -------------------------------------------------
--@api-stub: mlua:getSample
-- Read back samples for visualization or analysis.
local peak_sample = 0
for i = 0, 999 do
    local s = math.abs(snd:getSample(i))
    if s > peak_sample then peak_sample = s end
end
print("peak sample in first 1000: " .. string.format("%.3f", peak_sample))

-- =============================================================================
-- Source Object Methods — per-instance control
-- =============================================================================

-- ---- Stub: Source:play ----------------------------------------------------
--@api-stub: Source:play
jump_sfx:play()
print("jump SFX: play via method")

-- ---- Stub: Source:stop ----------------------------------------------------
--@api-stub: Source:stop
jump_sfx:stop()
print("jump SFX: stopped via method")

-- ---- Stub: Source:pause ---------------------------------------------------
--@api-stub: Source:pause
bgm:pause()
print("BGM: paused via method")

-- ---- Stub: Source:resume --------------------------------------------------
--@api-stub: Source:resume
bgm:resume()
print("BGM: resumed via method")

-- ---- Stub: Source:setVolume -----------------------------------------------
--@api-stub: Source:setVolume
jump_sfx:setVolume(0.8)
print("jump volume: " .. tostring(jump_sfx:getVolume()))

-- ---- Stub: Source:getVolume -----------------------------------------------
--@api-stub: Source:getVolume
print("jump volume (method): " .. tostring(jump_sfx:getVolume()))

-- ---- Stub: Source:setPitch ------------------------------------------------
--@api-stub: Source:setPitch
-- Speed up the coin sound for combo multiplier feedback.
coin_sfx:setPitch(1.0 + 0.1 * 3)  -- 3x combo = 30% pitch increase
print("coin pitch at 3x combo: " .. tostring(coin_sfx:getPitch()))

-- ---- Stub: Source:getPitch ------------------------------------------------
--@api-stub: Source:getPitch
print("coin pitch: " .. tostring(coin_sfx:getPitch()))

-- ---- Stub: Source:setLooping ----------------------------------------------
--@api-stub: Source:setLooping
bgm:setLooping(true)
print("BGM looping: " .. tostring(bgm:isLooping()))

-- ---- Stub: Source:isLooping -----------------------------------------------
--@api-stub: Source:isLooping
print("BGM looping: " .. tostring(bgm:isLooping()))

-- ---- Stub: Source:isPlaying -----------------------------------------------
--@api-stub: Source:isPlaying
print("BGM playing: " .. tostring(bgm:isPlaying()))

-- ---- Stub: Source:isPaused ------------------------------------------------
--@api-stub: Source:isPaused
print("BGM paused: " .. tostring(bgm:isPaused()))

-- ---- Stub: Source:isStopped -----------------------------------------------
--@api-stub: Source:isStopped
print("jump stopped: " .. tostring(jump_sfx:isStopped()))

-- ---- Stub: Source:setPan --------------------------------------------------
--@api-stub: Source:setPan
coin_sfx:setPan(0.4)
print("coin panned right: " .. tostring(coin_sfx:getPan()))

-- ---- Stub: Source:getPan --------------------------------------------------
--@api-stub: Source:getPan
print("coin pan: " .. tostring(coin_sfx:getPan()))

-- ---- Stub: Source:clone ---------------------------------------------------
--@api-stub: Source:clone
-- Clone for overlapping footstep sounds while the original is still playing.
local footstep_clone = coin_sfx:clone()
print("coin cloned for overlapping playback")

-- ---- Stub: Source:getType -------------------------------------------------
--@api-stub: Source:getType
print("jump source type: " .. tostring(jump_sfx:getType()))

-- ---- Stub: Source:getDuration ---------------------------------------------
--@api-stub: Source:getDuration
print("jump duration: " .. string.format("%.3f", jump_sfx:getDuration()) .. "s")

-- ---- Stub: Source:tell ----------------------------------------------------
--@api-stub: Source:tell
print("BGM position: " .. string.format("%.2f", bgm:tell()) .. "s")

-- ---- Stub: Source:seek ----------------------------------------------------
--@api-stub: Source:seek
bgm:seek(0)
print("BGM rewound to start")

-- ---- Stub: Source:setLowpass ----------------------------------------------
--@api-stub: Source:setLowpass
-- Muffle the enemy growl when behind a wall.
enemy_growl:setLowpass(0.4)
print("growl lowpass: 0.4 (muffled behind wall)")

-- ---- Stub: Source:setHighpass ---------------------------------------------
--@api-stub: Source:setHighpass
enemy_growl:setHighpass(0.2)
print("growl highpass: 0.2")

-- ---- Stub: Source:getLowpass -----------------------------------------------
--@api-stub: Source:getLowpass
print("growl lowpass: " .. tostring(enemy_growl:getLowpass()))

-- ---- Stub: Source:getHighpass ----------------------------------------------
--@api-stub: Source:getHighpass
print("growl highpass: " .. tostring(enemy_growl:getHighpass()))

-- ---- Stub: Source:clearFilter ---------------------------------------------
--@api-stub: Source:clearFilter
enemy_growl:clearFilter()
print("growl filters cleared (wall destroyed)")

-- ---- Stub: Source:fadeIn --------------------------------------------------
--@api-stub: Source:fadeIn
bgm:fadeIn(1.5)
print("BGM fading in over 1.5s")

-- ---- Stub: Source:getFadeIn -----------------------------------------------
--@api-stub: Source:getFadeIn
print("BGM fade-in: " .. tostring(bgm:getFadeIn()) .. "s")

-- =============================================================================
-- Decoder — stream decoding for large files
-- =============================================================================

-- ---- Stub: lurek.audio.newDecoder -----------------------------------------
--@api-stub: lurek.audio.newDecoder
-- Decoders let you manually decode audio data chunk-by-chunk.
-- Useful for custom streaming, analysis, or real-time visualization.
local decoder = lurek.audio.newDecoder("assets/audio/level1_theme.ogg", 4096)
print("decoder created: 4096-sample buffer")

-- ---- Stub: Decoder:decode -------------------------------------------------
--@api-stub: Decoder:decode
-- Decode the next chunk of samples. Returns nil when the file ends.
local chunk = decoder:decode()
if chunk then
    print("decoded chunk: " .. tostring(chunk:getSampleCount()) .. " samples")
end

-- ---- Stub: Decoder:getChannelCount ----------------------------------------
--@api-stub: Decoder:getChannelCount
print("decoder channels: " .. tostring(decoder:getChannelCount()))

-- ---- Stub: Decoder:getBitDepth --------------------------------------------
--@api-stub: Decoder:getBitDepth
print("decoder bit depth: " .. tostring(decoder:getBitDepth()))

-- ---- Stub: Decoder:getSampleRate ------------------------------------------
--@api-stub: Decoder:getSampleRate
print("decoder sample rate: " .. tostring(decoder:getSampleRate()) .. " Hz")

-- ---- Stub: Decoder:getDuration --------------------------------------------
--@api-stub: Decoder:getDuration
print("decoder duration: " .. string.format("%.1f", decoder:getDuration()) .. "s")

-- ---- Stub: Decoder:seek ---------------------------------------------------
--@api-stub: Decoder:seek
decoder:seek(10.0)
print("decoder seeked to 10.0s")

-- ---- Stub: Decoder:rewind -------------------------------------------------
--@api-stub: Decoder:rewind
decoder:rewind()
print("decoder rewound to start")

-- ---- Stub: Decoder:tell ---------------------------------------------------
--@api-stub: Decoder:tell
print("decoder position: " .. string.format("%.2f", decoder:tell()) .. "s")

-- ---- Stub: Decoder:isSeekable ---------------------------------------------
--@api-stub: Decoder:isSeekable
print("decoder seekable: " .. tostring(decoder:isSeekable()))

-- ---- Stub: Decoder:release ------------------------------------------------
--@api-stub: Decoder:release
decoder:release()
print("decoder released")

-- =============================================================================
-- Queueable Source — gapless playback
-- =============================================================================

-- ---- Stub: lurek.audio.newQueueableSource ---------------------------------
--@api-stub: lurek.audio.newQueueableSource
-- Queueable sources accept pre-decoded buffers for gapless playback.
-- Use for procedural audio or dynamically sequenced music segments.
local queue_src = lurek.audio.newQueueableSource(44100, 16, 2, 4)
print("queueable source: 44100Hz, 16-bit, stereo, 4 buffer slots")

-- ---- Stub: lurek.audio.queueSource ----------------------------------------
--@api-stub: lurek.audio.queueSource
-- Push a SoundData buffer into the queue.
lurek.audio.queueSource(queue_src, snd)
print("sound data queued for gapless playback")

-- ---- Stub: lurek.audio.getFreeBufferCount ---------------------------------
--@api-stub: lurek.audio.getFreeBufferCount
local free = lurek.audio.getFreeBufferCount(queue_src)
print("free queue buffers: " .. tostring(free))

-- ---- Stub: lurek.audio.playQueueable --------------------------------------
--@api-stub: lurek.audio.playQueueable
lurek.audio.playQueueable(queue_src)
print("queueable source playing")

-- ---- Stub: lurek.audio.stopQueueable --------------------------------------
--@api-stub: lurek.audio.stopQueueable
lurek.audio.stopQueueable(queue_src)
print("queueable source stopped")

-- =============================================================================
-- Playback Devices
-- =============================================================================

-- ---- Stub: lurek.audio.getPlaybackDevices ---------------------------------
--@api-stub: lurek.audio.getPlaybackDevices
-- List available audio output devices for a settings menu.
local devices = lurek.audio.getPlaybackDevices()
print("available playback devices:")
for i, dev in ipairs(devices) do
    print("  [" .. i .. "] " .. tostring(dev))
end

-- ---- Stub: lurek.audio.getPlaybackDevice ----------------------------------
--@api-stub: lurek.audio.getPlaybackDevice
print("current device: " .. tostring(lurek.audio.getPlaybackDevice()))

-- ---- Stub: lurek.audio.setPlaybackDevice ----------------------------------
--@api-stub: lurek.audio.setPlaybackDevice
-- Switch output device (e.g. from speakers to headphones).
if #devices > 0 then
    lurek.audio.setPlaybackDevice(devices[1])
    print("switched to device: " .. tostring(devices[1]))
end

-- =============================================================================
-- Sound Pool — rapid-fire SFX with voice limiting
-- =============================================================================

-- ---- Stub: lurek.audio.newPool --------------------------------------------
--@api-stub: lurek.audio.newPool
-- Sound pools manage N simultaneous voices for the same sound.
-- When all voices are busy, the oldest is recycled. Perfect for gunshots,
-- footsteps, or rain drops where hundreds of triggers happen per second.
local footstep_pool = lurek.audio.newPool("assets/audio/footstep.wav", 8)
print("footstep pool: 8 voices (max 8 simultaneous footstep sounds)")

-- ---- Stub: SoundPool:play ------------------------------------------------
--@api-stub: SoundPool:play
-- Fire-and-forget: play one voice from the pool.
footstep_pool:play()
footstep_pool:play()
footstep_pool:play()
print("3 footsteps triggered from pool")

-- ---- Stub: SoundPool:stopAll ----------------------------------------------
--@api-stub: SoundPool:stopAll
footstep_pool:stopAll()
print("all pool voices stopped (player stopped moving)")

-- ---- Stub: SoundPool:setVolume --------------------------------------------
--@api-stub: SoundPool:setVolume
footstep_pool:setVolume(0.4)
print("footstep pool volume: 0.4 (subtle background)")

-- ---- Stub: SoundPool:setBus -----------------------------------------------
--@api-stub: SoundPool:setBus
footstep_pool:setBus("sfx")
print("footstep pool routed to SFX bus")

-- ---- Stub: SoundPool:release ----------------------------------------------
--@api-stub: SoundPool:release
footstep_pool:release()
print("footstep pool released")

-- ---- Stub: SoundPool:getVoiceCount ----------------------------------------
--@api-stub: SoundPool:getVoiceCount
-- Recreate for voice count query demo
local rain_pool = lurek.audio.newPool("assets/audio/raindrop.wav", 16)
print("rain pool voices: " .. tostring(rain_pool:getVoiceCount()))

-- ---- Stub: SoundPool:type -------------------------------------------------
--@api-stub: SoundPool:type
-- ---- Stub: SoundPool:typeOf -----------------------------------------------
--@api-stub: SoundPool:typeOf
print("pool type: " .. tostring(rain_pool:type()))
print("pool typeOf: " .. tostring(rain_pool:typeOf("SoundPool")))

-- =============================================================================
-- Procedural Waveform Generators
-- =============================================================================

-- ---- Stub: lurek.audio.newSineWave ----------------------------------------
--@api-stub: lurek.audio.newSineWave
-- Generate a pure sine wave: smooth tone for menu beeps or synth pads.
local sine = lurek.audio.newSineWave(440, 1.0, 44100)
print("sine wave: 440 Hz, 1.0s duration")

-- ---- Stub: lurek.audio.newSquareWave --------------------------------------
--@api-stub: lurek.audio.newSquareWave
-- Square wave: buzzy chiptune sound for retro SFX.
local square = lurek.audio.newSquareWave(220, 0.5, 44100)
print("square wave: 220 Hz, 0.5s (retro beep)")

-- ---- Stub: lurek.audio.newSawtoothWave ------------------------------------
--@api-stub: lurek.audio.newSawtoothWave
-- Sawtooth: rich harmonics, good for synth bass or alarm sounds.
local sawtooth = lurek.audio.newSawtoothWave(110, 0.3, 44100)
print("sawtooth wave: 110 Hz, 0.3s (alarm tone)")

-- ---- Stub: lurek.audio.newTriangleWave ------------------------------------
--@api-stub: lurek.audio.newTriangleWave
-- Triangle: softer than square, good for flute-like tones.
local triangle = lurek.audio.newTriangleWave(330, 0.8, 44100)
print("triangle wave: 330 Hz, 0.8s (flute-like)")

-- ---- Stub: lurek.audio.newWhiteNoise --------------------------------------
--@api-stub: lurek.audio.newWhiteNoise
-- White noise: use for explosions, wind, static, or percussion synthesis.
local noise = lurek.audio.newWhiteNoise(0.2, 44100)
print("white noise: 0.2s burst (explosion base)")

-- =============================================================================
-- DSP Processing — offline audio manipulation
-- =============================================================================

-- ---- Stub: lurek.audio.applyLowpass ---------------------------------------
--@api-stub: lurek.audio.applyLowpass
-- Apply a lowpass filter to sound data. Cutoff in Hz.
lurek.audio.applyLowpass(sine, 2000)
print("lowpass at 2000 Hz applied to sine wave")

-- ---- Stub: lurek.audio.applyHighpass --------------------------------------
--@api-stub: lurek.audio.applyHighpass
lurek.audio.applyHighpass(noise, 500)
print("highpass at 500 Hz applied to white noise (removes rumble)")

-- ---- Stub: lurek.audio.applyBandpass --------------------------------------
--@api-stub: lurek.audio.applyBandpass
-- Bandpass isolates a frequency range: useful for voice-like filtering.
lurek.audio.applyBandpass(sawtooth, 200, 3000)
print("bandpass 200-3000 Hz applied to sawtooth (voice-range)")

-- ---- Stub: lurek.audio.applyGain ------------------------------------------
--@api-stub: lurek.audio.applyGain
-- Amplify or attenuate sound data. 0.5 = half volume, 2.0 = double.
lurek.audio.applyGain(square, 0.6)
print("gain 0.6 applied to square wave (quieter)")

-- ---- Stub: lurek.audio.mixInto --------------------------------------------
--@api-stub: lurek.audio.mixInto
-- Mix two sound data buffers together. Use for layering explosion + debris.
lurek.audio.mixInto(sine, noise, 0.5)
print("white noise mixed into sine at 50% (layered explosion)")

-- =============================================================================
-- File Operations — save and analyze audio
-- =============================================================================

-- ---- Stub: lurek.audio.saveWAV --------------------------------------------
--@api-stub: lurek.audio.saveWAV
-- Export sound data to a WAV file for debugging or user-generated content.
lurek.audio.saveWAV(sine, "output/generated_tone.wav")
print("sine wave saved to output/generated_tone.wav")

-- ---- Stub: lurek.audio.processOffline -------------------------------------
--@api-stub: lurek.audio.processOffline
-- Run a chain of DSP effects on a file without loading it fully into memory.
lurek.audio.processOffline("assets/audio/raw_recording.wav", "output/processed.wav", {
    { type = "lowpass", cutoff = 4000 },
    { type = "gain", factor = 1.5 }
})
print("offline processing: lowpass + gain applied to recording")

-- ---- Stub: lurek.audio.normalizeFile --------------------------------------
--@api-stub: lurek.audio.normalizeFile
-- Normalize audio to peak amplitude. Ensures consistent loudness across assets.
lurek.audio.normalizeFile("output/processed.wav", "output/normalized.wav")
print("audio normalized to peak amplitude")

-- ---- Stub: lurek.audio.waveformToPng --------------------------------------
--@api-stub: lurek.audio.waveformToPng
-- Generate a waveform visualization PNG for debug or audio editor UI.
lurek.audio.waveformToPng("output/generated_tone.wav", "output/waveform.png", 800, 200)
print("waveform PNG saved: 800x200")

-- ---- Stub: lurek.audio.spectrogramToPng -----------------------------------
--@api-stub: lurek.audio.spectrogramToPng
-- Generate a spectrogram for frequency analysis visualization.
lurek.audio.spectrogramToPng("output/generated_tone.wav", "output/spectrogram.png", 800, 400)
print("spectrogram PNG saved: 800x400")

print("\n-- audio.lua example complete --")
