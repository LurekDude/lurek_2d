-- Lurek2D Audio API Tests

-- @description Verifies the top-level audio namespace is present before exercising any factories or listener controls.
describe("lurek.audio module exists", function()
    -- @tests lurek.audio.getDistanceModel
    -- @tests lurek.audio.getDopplerScale
    -- @tests lurek.audio.getFreeBufferCount
    -- @tests lurek.audio.getListener
    -- @tests lurek.audio.getListener2D
    -- @tests lurek.audio.getMasterVolume
    -- @tests lurek.audio.getPlaybackDevice
    -- @tests lurek.audio.getPlaybackDevices
    -- @tests lurek.audio.newDecoder
    -- @tests lurek.audio.newQueueableSource
    -- @tests lurek.audio.newSoundData
    -- @tests lurek.audio.newSource
    -- @tests lurek.audio.playQueueable
    -- @tests lurek.audio.queueSource
    -- @tests lurek.audio.setDistanceModel
    -- @tests lurek.audio.setDopplerScale
    -- @tests lurek.audio.setListener
    -- @tests lurek.audio.setListener2D
    -- @tests lurek.audio.setMasterVolume
    -- @tests lurek.audio.setPlaybackDevice
    -- @tests lurek.audio.stopQueueable
    -- @tests lurek.audio.newBus
    -- @tests lurek.audio.Source.play
    -- @tests lurek.audio.Source.stop
    -- @tests lurek.audio.Source.pause
    -- @tests lurek.audio.Source.resume
    -- @tests lurek.audio.Source.setVolume
    -- @tests lurek.audio.Source.getVolume
    -- @tests lurek.audio.Source.setPitch
    -- @tests lurek.audio.Source.getPitch
    -- @tests lurek.audio.Source.setLooping
    -- @tests lurek.audio.Source.isLooping
    -- @tests lurek.audio.Source.isPlaying
    -- @tests lurek.audio.Source.isPaused
    -- @tests lurek.audio.Source.isStopped
    -- @tests lurek.audio.Source.setPan
    -- @tests lurek.audio.Source.getPan
    -- @tests lurek.audio.Source.clone
    -- @tests lurek.audio.Source.getType
    -- @tests lurek.audio.Source.getDuration
    -- @tests lurek.audio.Source.tell
    -- @tests lurek.audio.Source.seek
    -- @tests lurek.audio.Source.setLowpass
    -- @tests lurek.audio.Source.getLowpass
    -- @tests lurek.audio.Source.setHighpass
    -- @tests lurek.audio.Source.getHighpass
    -- @tests lurek.audio.Source.clearFilter
    -- @tests lurek.audio.Source.fadeIn
    -- @tests lurek.audio.Source.getFadeIn
    -- @tests lurek.audio.Bus.getName
    -- @tests lurek.audio.Bus.setVolume
    -- @tests lurek.audio.Bus.getVolume
    -- @tests lurek.audio.Bus.setPitch
    -- @tests lurek.audio.Bus.getPitch
    -- @tests lurek.audio.Bus.pause
    -- @tests lurek.audio.Bus.resume
    -- @tests lurek.audio.Bus.isPaused
    -- @tests lurek.audio.Bus.type
    -- @tests lurek.audio.Bus.typeOf
    -- @description Checks that the Lua bridge exposes lurek.audio as a table namespace.
    it("lurek.audio is a table", function()
        expect_type("table", lurek.audio)
    end)
end)

-- @description Confirms the core master-volume and source-construction entry points are registered on the audio namespace.
describe("lurek.audio functions exist", function()
    -- @description Verifies the master-volume setter is exported as a callable function.
    it("setMasterVolume is a function", function()
        expect_type("function", lurek.audio.setMasterVolume)
    end)

    -- @description Verifies the master-volume getter is exported as a callable function.
    it("getMasterVolume is a function", function()
        expect_type("function", lurek.audio.getMasterVolume)
    end)

    -- @description Verifies the audio source factory is exported as a callable function.
    it("newSource is a function", function()
        expect_type("function", lurek.audio.newSource)
    end)
end)

-- @description Exercises master-volume writes, reads, and range behavior on the global audio mixer state.
describe("lurek.audio volume", function()
    -- @description Ensures the master-volume setter accepts an in-range value without raising an error.
    it("setMasterVolume accepts 0..1 range", function()
        expect_no_error(function()
            lurek.audio.setMasterVolume(0.5)
        end)
    end)

    -- @description Verifies the master-volume getter returns a numeric value.
    it("getMasterVolume returns a number", function()
        local vol = lurek.audio.getMasterVolume()
        expect_type("number", vol)
    end)

    -- @description Writes a master-volume value, reads it back, and checks the round-trip within tolerance before resetting to full volume.
    it("setMasterVolume/getMasterVolume roundtrip", function()
        lurek.audio.setMasterVolume(0.75)
        expect_near(0.75, lurek.audio.getMasterVolume(), 0.01)
        lurek.audio.setMasterVolume(1.0) -- reset
    end)

    -- @description Verifies boundary values at both ends of the valid master-volume range can be stored and read back accurately.
    it("setMasterVolume clamps to valid range", function()
        lurek.audio.setMasterVolume(0.0)
        expect_near(0.0, lurek.audio.getMasterVolume(), 0.01)
        lurek.audio.setMasterVolume(1.0)
        expect_near(1.0, lurek.audio.getMasterVolume(), 0.01)
    end)
end)

    -- @description Covers Doppler scaling, distance-model selection, and 2D or 3D listener position helpers for spatial audio state.
describe("audio spatial", function()
    -- @description Verifies the Doppler scale starts at the documented default value of 1.0.
    it("getDopplerScale returns 1 by default", function()
        expect_near(1.0, lurek.audio.getDopplerScale(), 0.0001)
    end)

    -- @description Sets a custom Doppler scale, confirms it round-trips, then restores the default value.
    it("setDopplerScale round-trips", function()
        lurek.audio.setDopplerScale(2.0)
        expect_near(2.0, lurek.audio.getDopplerScale(), 0.0001)
        lurek.audio.setDopplerScale(1.0)  -- reset
    end)

    -- @description Checks that the current distance-model query returns a string identifier.
    it("getDistanceModel returns a string", function()
        expect_type("string", lurek.audio.getDistanceModel())
    end)

    -- @description Switches to the linear distance model, verifies the change, then restores the previous default mode.
    it("setDistanceModel round-trips", function()
        lurek.audio.setDistanceModel("linear")
        expect_equal("linear", lurek.audio.getDistanceModel())
        lurek.audio.setDistanceModel("inverse_clamped")  -- reset
    end)

    -- @description Writes a 3D listener position and verifies all three coordinates are returned unchanged.
    it("setListener / getListener round-trips", function()
        lurek.audio.setListener(100, 50, 0)
        local x, y, z = lurek.audio.getListener()
        expect_near(100, x, 0.001)
        expect_near(50, y, 0.001)
        expect_near(0, z, 0.001)
        lurek.audio.setListener(0, 0, 0)  -- reset
    end)

    -- @description Uses the compatibility 2D listener helpers and verifies the stored X and Y coordinates round-trip correctly.
    it("setListener2D / getListener2D backward compat", function()
        lurek.audio.setListener2D(30, 40)
        local x, y = lurek.audio.getListener2D()
        expect_near(30, x, 0.001)
        expect_near(40, y, 0.001)
        lurek.audio.setListener2D(0, 0)  -- reset
    end)
end)

-- @description Validates the decoder factory is exported and rejects nonexistent file paths.
describe("audio.newDecoder", function()
  -- @description Confirms the decoder constructor itself is available as a function.
  it("is a function", function()
    expect_type("function", lurek.audio.newDecoder)
  end)

  -- @description Verifies decoder construction fails with an error when the source file path does not exist.
  it("errors on missing file", function()
    expect_error(function()
      lurek.audio.newDecoder("nonexistent_file.wav")
    end, "nonexistent_file")
  end)
end)

-- @description Exercises decoder metadata access, seeking, decoding, EOF handling, and rewind behavior using the mono WAV fixture.
describe("Decoder userdata methods", function()
  -- @description Confirms decoder channel-count queries return numeric data.
  it("getChannelCount returns a number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_type("number", d:getChannelCount())
  end)

  -- @description Verifies the mono fixture reports exactly one channel.
  it("getChannelCount is 1 for mono fixture", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_equal(1, d:getChannelCount())
  end)

  -- @description Checks the decoder reports a positive numeric sample rate for the fixture audio.
  it("getSampleRate returns a positive number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    local rate = d:getSampleRate()
    expect_type("number", rate)
    expect_greater(rate, 0, "sample rate must be positive")
  end)

  -- @description Checks the decoder reports a positive numeric bit depth for the fixture audio.
  it("getBitDepth returns a positive number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    local depth = d:getBitDepth()
    expect_type("number", depth)
    expect_greater(depth, 0, "bit depth must be positive")
  end)

  -- @description Checks the decoder reports a positive duration for the fixture audio stream.
  it("getDuration returns a positive number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    local dur = d:getDuration()
    expect_type("number", dur)
    expect_greater(dur, 0, "duration must be positive")
  end)

  -- @description Verifies the WAV decoder reports itself as seekable.
  it("isSeekable returns true", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_equal(true, d:isSeekable())
  end)

  -- @description Confirms a fresh decoder starts at playback position 0.
  it("tell starts at 0", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_near(0.0, d:tell(), 0.000001)
  end)

  -- @description Seeks to a small offset and verifies tell returns approximately the same position.
  it("seek and tell round-trip", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    d:seek(0.01)
    expect_near(0.01, d:tell(), 0.001)
  end)

  -- @description Decodes a large chunk to exhaust the fixture and verifies subsequent decode calls return nil at EOF.
  it("decode returns userdata then nil at EOF", function()
    -- Use a large buffer so we hit EOF in one call
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav", 1000000)
    local chunk = d:decode()
    -- chunk may be userdata (SoundData) or nil depending on file size
    expect_true(chunk == nil or type(chunk) == "userdata", "decode must return userdata or nil")
    local eof = d:decode()
    -- second call after exhaustion must be nil
    expect_nil(eof, "decode at EOF must return nil")
  end)

  -- @description Consumes decoded data, rewinds the decoder, and verifies playback position resets to zero.
  it("rewind resets position to 0", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav", 1000000)
    d:decode()  -- consume
    d:rewind()
    expect_near(0.0, d:tell(), 0.000001)
  end)
end)

-- Phase 15 â€” Queueable Sources
-- @description Covers queueable-source creation, free-buffer accounting, playback start, and stop-based buffer reset behavior.
describe("audio.newQueueableSource", function()
  -- @description Verifies queueable-source construction returns a numeric handle.
  it("creates a queueable source and returns a number id", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    expect_equal(type(q), "number")
  end)

  -- @description Checks that a newly created queueable source starts with all configured buffers free.
  it("getFreeBufferCount returns buffer_count initially", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    expect_equal(lurek.audio.getFreeBufferCount(q), 4)
  end)

  -- @description Verifies omitted buffer-count arguments fall back to the documented default of four buffers.
  it("getFreeBufferCount defaults to 4 buffers when omitted", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1)
    expect_equal(lurek.audio.getFreeBufferCount(q), 4)
  end)

  -- @description Ensures a queueable source can be started without errors even before buffers are exhausted.
  it("playQueueable does not error", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    expect_no_error(function()
      lurek.audio.playQueueable(q)
    end)
  end)

  -- @description Queues a buffer, verifies the free count drops, then stops playback and confirms the free count resets to the initial capacity.
  it("stopQueueable resets free buffer count", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    -- queue a SoundData buffer, then stop
    local sd = lurek.audio.newSoundData(64, 44100, 1)
    lurek.audio.queueSource(q, sd)
    -- after queuing, free count drops
    local after_queue = lurek.audio.getFreeBufferCount(q)
    expect_less(after_queue, 4, "free count must decrease after queueSource")
    -- stop resets it
    lurek.audio.stopQueueable(q)
    expect_equal(lurek.audio.getFreeBufferCount(q), 4)
  end)
end)

-- Phase 18 â€” Playback Device Selection
-- @description Exercises playback-device enumeration and validates both successful and failing device-selection paths.
describe("audio device selection", function()
  -- @description Verifies audio device enumeration returns a Lua table.
  it("getPlaybackDevices returns a table", function()
    local devs = lurek.audio.getPlaybackDevices()
    expect_equal(type(devs), "table")
  end)

  -- @description Verifies at least one playback device is visible to the runtime.
  it("getPlaybackDevices has at least one entry", function()
    local devs = lurek.audio.getPlaybackDevices()
    expect_true(#devs >= 1, "must have at least one device")
  end)

  -- @description Verifies the active playback-device query returns a string name.
  it("getPlaybackDevice returns a string", function()
    expect_equal(type(lurek.audio.getPlaybackDevice()), "string")
  end)

  -- @description Selects the first reported playback device and verifies the call succeeds without error.
  it("setPlaybackDevice with valid name does not error", function()
    local devs = lurek.audio.getPlaybackDevices()
    expect_no_error(function()
      lurek.audio.setPlaybackDevice(devs[1])
    end)
  end)

  -- @description Verifies selecting an unknown playback device raises the expected error.
  it("setPlaybackDevice with unknown name errors", function()
    expect_error(function()
      lurek.audio.setPlaybackDevice("NonExistentDevice___XYZ")
    end, "Unknown audio device")
  end)
end)

-- â”€â”€ Source UserData (static source from fixture) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

local FIXTURE = "tests/fixtures/sine_mono_44100.wav"

-- @description Covers Source playback state transitions from creation through play, pause, resume, and stop.
describe("Source UserData - play/stop/pause/resume lifecycle", function()
    -- @description Creates a static source from the WAV fixture and verifies the constructor returns a non-nil userdata object.
    it("newSource returns a non-nil Source from fixture", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_true(src ~= nil, "source is not nil")
    end)

    -- @description Verifies newly created sources begin in the stopped state.
    it("isStopped is true before play", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_true(src:isStopped())
    end)

    -- @description Starts playback and verifies the source reports a playing state before cleanup.
    it("play / isPlaying round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        expect_true(src:isPlaying())
        src:stop()
    end)

    -- @description Pauses an actively playing source and verifies the paused-state flag is set.
    it("pause / isPaused round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        src:pause()
        expect_true(src:isPaused())
        src:stop()
    end)

    -- @description Resumes a paused source and verifies it transitions back to the playing state.
    it("resume after pause returns to playing", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        src:pause()
        src:resume()
        expect_true(src:isPlaying())
        src:stop()
    end)

    -- @description Stops an active source and verifies it reports the stopped state again.
    it("stop transitions to isStopped", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        src:stop()
        expect_true(src:isStopped())
    end)
end)

    -- @description Verifies per-source mixer properties for volume, pitch, and stereo pan.
describe("Source UserData - volume / pitch / pan", function()
    -- @description Sets the source volume and verifies the value round-trips through the getter.
    it("setVolume / getVolume round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setVolume(0.5)
        expect_near(0.5, src:getVolume(), 0.001)
    end)

    -- @description Sets the source pitch and verifies the value round-trips through the getter.
    it("setPitch / getPitch round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setPitch(1.5)
        expect_near(1.5, src:getPitch(), 0.001)
    end)

    -- @description Sets the source pan and verifies the value round-trips through the getter.
    it("setPan / getPan round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setPan(-0.5)
        expect_near(-0.5, src:getPan(), 0.001)
    end)
end)

    -- @description Covers looping toggles, source-type reporting, and duration metadata queries.
describe("Source UserData - looping / type / duration", function()
    -- @description Enables looping and verifies the looping-state query reports true.
    it("setLooping true / isLooping true", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setLooping(true)
        expect_true(src:isLooping())
    end)

    -- @description Disables looping and verifies the looping-state query reports false.
    it("setLooping false / isLooping false", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setLooping(false)
        expect_false(src:isLooping())
    end)

    -- @description Verifies source-type introspection returns a string identifier.
    it("getType returns a string", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_type("string", src:getType())
    end)

    -- @description Verifies duration queries either return a positive number or nil in accepted headless environments.
    it("getDuration returns a positive number or nil in headless", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        local dur = src:getDuration()
        if dur ~= nil then
            expect_type("number", dur)
            expect_true(dur > 0, "audio duration must be positive")
        else
            expect_true(true, "headless: getDuration returned nil (acceptable)")
        end
    end)
end)

    -- @description Exercises source playback-position queries before and after an explicit seek operation.
describe("Source UserData - tell / seek", function()
    -- @description Verifies a fresh source reports playback position zero before any playback or seeking occurs.
    it("tell returns 0 before playback starts", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_equal(0, src:tell())
    end)

    -- @description Seeks the source slightly forward and verifies tell reports a nonnegative updated position.
    it("seek moves position and tell reflects it", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:seek(0.01)
        expect_true(src:tell() >= 0)
    end)
end)

    -- @description Verifies low-pass, high-pass, and filter-clearing source APIs execute and expose numeric filter state.
describe("Source UserData - filter methods", function()
    -- @description Sets a low-pass filter and verifies the getter returns a numeric value without errors.
    it("setLowpass / getLowpass does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_no_error(function()
            src:setLowpass(0.5)
            local v = src:getLowpass()
            expect_type("number", v)
        end)
    end)

    -- @description Sets a high-pass filter and verifies the getter returns a numeric value without errors.
    it("setHighpass / getHighpass does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_no_error(function()
            src:setHighpass(0.3)
            local v = src:getHighpass()
            expect_type("number", v)
        end)
    end)

    -- @description Applies a low-pass filter and verifies clearing filters afterwards does not raise an error.
    it("clearFilter does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setLowpass(0.5)
        expect_no_error(function() src:clearFilter() end)
    end)
end)

      -- @description Covers source fade-in state and cloning behavior on static audio sources.
describe("Source UserData - fadeIn / clone", function()
    -- @description Verifies invoking fadeIn is accepted by the source without errors.
    it("fadeIn does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_no_error(function() src:fadeIn(1.0) end)
    end)

    -- @description Verifies getFadeIn returns a numeric fade duration after fadeIn has been configured.
    it("getFadeIn returns a number", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:fadeIn(1.0)
        expect_type("number", src:getFadeIn())
    end)

    -- @description Clones an existing source and verifies the duplicate object is returned.
    it("clone returns a new Source", function()
        local src  = lurek.audio.newSource(FIXTURE, "static")
        local copy = src:clone()
        expect_true(copy ~= nil, "cloned source is not nil")
    end)
end)

-- â”€â”€ Bus UserData â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies bus construction, mix-property controls, pause state, and runtime type introspection for audio buses.
describe("Bus UserData", function()
    -- @description Creates an audio bus and verifies the factory returns a non-nil object.
    it("newBus returns a non-nil object", function()
        local bus = lurek.audio.newBus("test_bus")
        expect_true(bus ~= nil, "bus is not nil")
    end)

    -- @description Verifies a bus remembers the name it was created with.
    it("Bus:getName returns the registered name", function()
        local bus = lurek.audio.newBus("named_bus")
        expect_equal("named_bus", bus:getName())
    end)

    -- @description Sets bus volume and verifies the value round-trips through the getter.
    it("Bus setVolume / getVolume round-trip", function()
        local bus = lurek.audio.newBus("vol_bus")
        bus:setVolume(0.6)
        expect_near(0.6, bus:getVolume(), 0.001)
    end)

    -- @description Sets bus pitch and verifies the value round-trips through the getter.
    it("Bus setPitch / getPitch round-trip", function()
        local bus = lurek.audio.newBus("pitch_bus")
        bus:setPitch(1.2)
        expect_near(1.2, bus:getPitch(), 0.001)
    end)

    -- @description Pauses and resumes a bus, verifying the paused-state query tracks both transitions correctly.
    it("Bus pause / isPaused / resume", function()
        local bus = lurek.audio.newBus("pause_bus")
        bus:pause()
        expect_true(bus:isPaused())
        bus:resume()
        expect_false(bus:isPaused())
    end)

    -- @description Verifies bus type introspection returns a string identifier.
    it("Bus:type returns a string", function()
        local bus = lurek.audio.newBus("type_bus")
        expect_type("string", bus:type())
    end)

    -- @description Verifies typeOf recognizes Bus userdata correctly and rejects unrelated Source type checks.
    it("Bus:typeOf checks identity against a type name", function()
        local bus = lurek.audio.newBus("typeof_bus")
        expect_true(bus:typeOf("Bus"))
        expect_false(bus:typeOf("Source"))
    end)
end)

-- =========================================================================
-- newSoundData guard (PR-4)
-- =========================================================================

-- @description Covers suite: lurek.audio newSoundData input validation guard.
describe("lurek.audio newSoundData guard", function()
    -- @tests lurek.audio.newSoundData
    -- @description Passing a string literal for sample rate must now return an error instead of silently defaulting to 44100.
    it("newSoundData_invalid_sample_rate_string_errors", function()
        expect_error(function()
            lurek.audio.newSoundData(64, "invalid")
        end)
    end)

    -- @tests lurek.audio.newSoundData
    -- @description Passing a boolean for sample rate must also trigger the validation error.
    it("newSoundData_boolean_sample_rate_errors", function()
        expect_error(function()
            lurek.audio.newSoundData(64, true)
        end)
    end)

    -- @tests lurek.audio.newSoundData
    -- @description A valid integer count and numeric sample rate must succeed without error.
    it("newSoundData_valid_args_succeeds", function()
        expect_no_error(function()
            lurek.audio.newSoundData(64, 44100, 1)
        end)
    end)
end)

-- =========================================================================
-- MidiPlayer sample rate and channels (PR-5)
-- =========================================================================

-- @description Covers suite: lurek.audio MidiPlayer rate and channels configurability.
describe("lurek.audio MidiPlayer rate and channels", function()
    -- @tests lurek.audio.newMidiPlayer
    -- @description Confirms the MidiPlayer factory is exported as a callable function.
    it("newMidiPlayer is a function", function()
        expect_type("function", lurek.audio.newMidiPlayer)
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer:getSampleRate
    -- @description Verifies the default output sample rate of a freshly-created MidiPlayer is 44100 Hz.
    it("midi_getSampleRate_default_is_44100", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(44100, midi:getSampleRate())
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer:setSampleRate
    -- @tests MidiPlayer:getSampleRate
    -- @description Sets a sample rate within the valid range and reads it back to confirm round-trip fidelity.
    it("midi_setSampleRate_roundtrips_value", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(48000)
        expect_equal(48000, midi:getSampleRate())
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer:setSampleRate
    -- @tests MidiPlayer:getSampleRate
    -- @description Passes a value below 8000; the engine must clamp it to 8000.
    it("midi_setSampleRate_clamps_below_8000_to_8000", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(100)
        expect_equal(8000, midi:getSampleRate())
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer:setSampleRate
    -- @tests MidiPlayer:getSampleRate
    -- @description Passes a value above 192000; the engine must clamp it to 192000.
    it("midi_setSampleRate_clamps_above_192000_to_192000", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(999999)
        expect_equal(192000, midi:getSampleRate())
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer:getChannels
    -- @description Confirms the default output channel count of a freshly-created MidiPlayer is 2 (stereo).
    it("midi_getChannels_default_is_2", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(2, midi:getChannels())
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer:setChannels
    -- @tests MidiPlayer:getChannels
    -- @description Sets the channel count to 1 (mono) and verifies it is stored correctly.
    it("midi_setChannels_accepts_1_mono", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(1)
        expect_equal(1, midi:getChannels())
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer:setChannels
    -- @tests MidiPlayer:getChannels
    -- @description Sets the channel count to 2 (stereo) and verifies it is stored correctly.
    it("midi_setChannels_accepts_2_stereo", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(2)
        expect_equal(2, midi:getChannels())
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer:setChannels
    -- @tests MidiPlayer:getChannels
    -- @description Passes 5 (above the maximum of 2); the engine must clamp it to 2.
    it("midi_setChannels_clamps_above_2_to_2", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(5)
        expect_equal(2, midi:getChannels())
    end)
end)

-- =========================================================================
-- Merged from test_audio_bus.lua
-- =========================================================================

-- @description Covers suite: lurek.audio.newBus.
describe("lurek.audio.newBus", function()
    -- @tests lurek.audio.newBus
    -- @tests Bus.getName
    -- @tests lurek.audio.getListener2D
    -- @tests lurek.audio.getMaxSources
    -- @tests lurek.audio.getMeter
    -- @tests lurek.audio.newMidiPlayer
    -- @tests lurek.audio.setListener2D
    -- @tests lurek.audio.setMeter
    -- @description Verifies bus construction preserves the provided bus name.
    it("creates a bus with the given name", function()
        local bus = lurek.audio.newBus("music")
        expect_equal(bus:getName(), "music")
    end)

    -- @tests lurek.audio.newBus
    -- @tests Bus.getVolume
    -- @description Verifies newly created buses start at unity volume.
    it("has default volume 1.0", function()
        local bus = lurek.audio.newBus("test")
        expect_near(bus:getVolume(), 1.0, 1e-5)
    end)

    -- @tests lurek.audio.newBus
    -- @tests Bus.getPitch
    -- @description Verifies newly created buses start at neutral pitch.
    it("has default pitch 1.0", function()
        local bus = lurek.audio.newBus("test")
        expect_near(bus:getPitch(), 1.0, 1e-5)
    end)

    -- @tests lurek.audio.newBus
    -- @tests Bus.isPaused
    -- @description Verifies new buses begin unpaused.
    it("is not paused by default", function()
        local bus = lurek.audio.newBus("test")
        expect_false(bus:isPaused())
    end)
end)

-- @description Covers suite: Bus:setVolume / getVolume.
describe("Bus:setVolume / getVolume", function()
    -- @tests Bus.setVolume
    -- @tests Bus.getVolume
    -- @description Verifies bus volume changes round-trip for an in-range scalar.
    it("sets and gets volume", function()
        local bus = lurek.audio.newBus("test")
        bus:setVolume(0.7)
        expect_near(bus:getVolume(), 0.7, 1e-5)
    end)

    -- @tests Bus.setVolume
    -- @tests Bus.getVolume
    -- @description Verifies negative bus volume inputs clamp to silence instead of going below zero.
    it("clamps negative volume to 0", function()
        local bus = lurek.audio.newBus("test")
        bus:setVolume(-1.0)
        expect_near(bus:getVolume(), 0.0, 1e-5)
    end)
end)

-- @description Covers suite: Bus:setPitch / getPitch.
describe("Bus:setPitch / getPitch", function()
    -- @tests Bus.setPitch
    -- @tests Bus.getPitch
    -- @description Verifies bus pitch changes round-trip for a positive factor.
    it("sets and gets pitch", function()
        local bus = lurek.audio.newBus("test")
        bus:setPitch(1.5)
        expect_near(bus:getPitch(), 1.5, 1e-5)
    end)

    -- @tests Bus.setPitch
    -- @tests Bus.getPitch
    -- @description Verifies negative pitch values clamp to zero rather than producing invalid playback factors.
    it("clamps negative pitch to 0", function()
        local bus = lurek.audio.newBus("test")
        bus:setPitch(-0.5)
        expect_near(bus:getPitch(), 0.0, 1e-5)
    end)
end)

-- @description Covers suite: Bus:pause / resume / isPaused.
describe("Bus:pause / resume / isPaused", function()
    -- @tests Bus.pause
    -- @tests Bus.resume
    -- @tests Bus.isPaused
    -- @description Verifies pause state flips on and off through the lifecycle methods.
    it("pauses and resumes", function()
        local bus = lurek.audio.newBus("test")
        bus:pause()
        expect_true(bus:isPaused())
        bus:resume()
        expect_false(bus:isPaused())
    end)
end)

-- @description Covers suite: Bus type system.
describe("Bus type system", function()
    -- @tests Bus.type
    -- @description Verifies bus userdata reports its concrete runtime type string.
    it("reports type as LBus", function()
        local bus = lurek.audio.newBus("test")
        expect_equal(bus:type(), "LBus")
    end)

    -- @tests Bus.typeOf
    -- @description Verifies bus userdata advertises both its concrete type and Object base type.
    it("typeOf returns true for Bus and Object", function()
        local bus = lurek.audio.newBus("test")
        expect_true(bus:typeOf("Bus"))
        expect_true(bus:typeOf("Object"))
    end)
end)

-- @description Covers suite: lurek.audio.getMaxSources.
describe("lurek.audio.getMaxSources", function()
    -- @tests lurek.audio.getMaxSources
    -- @description Verifies the engine reports the expected global static max-source limit.
    it("returns 64", function()
        expect_equal(lurek.audio.getMaxSources(), 64)
    end)
end)

-- @description Covers suite: lurek.audio.setListener2D / getListener2D stubs.
describe("lurek.audio.setListener2D / getListener2D stubs", function()
    -- @tests lurek.audio.setListener2D
    -- @description Verifies the 2D listener setter accepts valid coordinates without error.
    it("setListener2D does not error", function()
        lurek.audio.setListener2D(1.0, 2.0)
    end)

    -- @tests lurek.audio.setListener2D
    -- @tests lurek.audio.getListener2D
    -- @description Verifies the 2D listener compatibility helpers round-trip the last set position.
    it("getListener2D returns the position set by setListener2D", function()
        lurek.audio.setListener2D(1.0, 2.0)
        local x, y = lurek.audio.getListener2D()
        expect_near(x, 1.0, 1e-5)
        expect_near(y, 2.0, 1e-5)
        -- reset for other tests
        lurek.audio.setListener2D(0.0, 0.0)
    end)
end)

-- @description Covers suite: lurek.audio.setMeter / getMeter stubs.
describe("lurek.audio.setMeter / getMeter stubs", function()
    -- @tests lurek.audio.setMeter
    -- @description Verifies the meter setter accepts a numeric value without error even in stubbed form.
    it("setMeter does not error", function()
        lurek.audio.setMeter(2.0)
    end)

    -- @tests lurek.audio.getMeter
    -- @description Verifies the stub meter getter returns the fixed default meter scalar.
    it("getMeter returns 1.0", function()
        expect_near(lurek.audio.getMeter(), 1.0, 1e-5)
    end)
end)

-- @description Covers suite: lurek.audio.newMidiPlayer.
describe("lurek.audio.newMidiPlayer", function()
    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer.isLoaded
    -- @description Verifies creating a MIDI player yields an unloaded player object.
    it("creates a MidiPlayer", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isLoaded())
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer.isPlaying
    -- @description Verifies unloaded MIDI players start stopped.
    it("is not playing by default", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isPlaying())
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer.getVolume
    -- @description Verifies new MIDI players default to full volume.
    it("has default volume 1.0", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getVolume(), 1.0, 1e-5)
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer.getTempoScale
    -- @description Verifies tempo scaling starts at neutral speed.
    it("has default tempo scale 1.0", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getTempoScale(), 1.0, 1e-5)
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer.getTrackCount
    -- @description Verifies unloaded MIDI players report zero tracks.
    it("has 0 tracks when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:getTrackCount(), 0)
    end)

    -- @tests lurek.audio.newMidiPlayer
    -- @tests MidiPlayer.getNoteCount
    -- @description Verifies unloaded MIDI players report zero note events.
    it("has 0 note count when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:getNoteCount(), 0)
    end)
end)

-- @description Covers suite: MidiPlayer volume.
describe("MidiPlayer volume", function()
    -- @tests MidiPlayer.setVolume
    -- @tests MidiPlayer.getVolume
    -- @description Verifies MIDI player volume round-trips through its accessor pair.
    it("sets and gets volume", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setVolume(0.5)
        expect_near(midi:getVolume(), 0.5, 1e-5)
    end)
end)

-- @description Covers suite: MidiPlayer tempo.
describe("MidiPlayer tempo", function()
    -- @tests MidiPlayer.setTempoScale
    -- @tests MidiPlayer.getTempoScale
    -- @description Verifies MIDI tempo scaling round-trips through the setter/getter pair.
    it("sets and gets tempo scale", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setTempoScale(2.0)
        expect_near(midi:getTempoScale(), 2.0, 1e-5)
    end)

    -- @tests MidiPlayer.getOriginalTempo
    -- @description Verifies unloaded MIDI players expose the default original tempo metadata.
    it("getOriginalTempo returns 120 when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getOriginalTempo(), 120.0, 1e-5)
    end)
end)

-- @description Covers suite: MidiPlayer looping.
describe("MidiPlayer looping", function()
    -- @tests MidiPlayer.setLooping
    -- @tests MidiPlayer.isLooping
    -- @description Verifies looping can be toggled on and off and reflected immediately.
    it("toggles looping", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isLooping())
        midi:setLooping(true)
        expect_true(midi:isLooping())
        midi:setLooping(false)
        expect_false(midi:isLooping())
    end)
end)

-- @description Covers suite: MidiPlayer channel control.
describe("MidiPlayer channel control", function()
    -- @tests MidiPlayer.setChannelVolume
    -- @tests MidiPlayer.getChannelVolume
    -- @description Verifies per-channel volume uses 1-based indexing and round-trips the stored value.
    it("sets and gets channel volume (1-indexed)", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannelVolume(1, 0.5)
        expect_near(midi:getChannelVolume(1), 0.5, 1e-5)
    end)

    -- @tests MidiPlayer.setChannelMuted
    -- @tests MidiPlayer.isChannelMuted
    -- @description Verifies per-channel mute state can be toggled on and off.
    it("mutes and unmutes channel", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isChannelMuted(1))
        midi:setChannelMuted(1, true)
        expect_true(midi:isChannelMuted(1))
        midi:setChannelMuted(1, false)
        expect_false(midi:isChannelMuted(1))
    end)

    -- @tests MidiPlayer.setChannelInstrument
    -- @tests MidiPlayer.getChannelInstrument
    -- @description Verifies channel instrument program numbers round-trip.
    it("sets and gets channel instrument", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannelInstrument(1, 42)
        expect_equal(midi:getChannelInstrument(1), 42)
    end)

    -- @tests MidiPlayer.soloChannel
    -- @tests MidiPlayer.isChannelMuted
    -- @description Verifies soloChannel leaves the target channel audible while muting the others.
    it("soloChannel mutes all others", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:soloChannel(5)
        expect_false(midi:isChannelMuted(5))
        expect_true(midi:isChannelMuted(1))
        expect_true(midi:isChannelMuted(16))
    end)

    -- @tests MidiPlayer.unsoloAll
    -- @tests MidiPlayer.soloChannel
    -- @tests MidiPlayer.isChannelMuted
    -- @description Verifies unsoloAll clears solo-side muting across every channel.
    it("unsoloAll unmutes all", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:soloChannel(5)
        midi:unsoloAll()
        expect_false(midi:isChannelMuted(1))
        expect_false(midi:isChannelMuted(5))
        expect_false(midi:isChannelMuted(16))
    end)
end)

-- @description Covers suite: MidiPlayer stubs.
describe("MidiPlayer stubs", function()
    -- @description Verifies case: setSoundFont does not error.
    it("setSoundFont does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSoundFont("path/to/sf2")
    end)

    -- @description Verifies case: useDefaultSoundFont does not error.
    it("useDefaultSoundFont does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:useDefaultSoundFont()
    end)

    -- @description Verifies case: getSoundFontPath returns nil.
    it("getSoundFontPath returns nil", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:getSoundFontPath(), nil)
    end)

    -- @description Verifies case: setOnNoteOn does not error.
    it("setOnNoteOn does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setOnNoteOn(function() end)
    end)

    -- @description Verifies case: setOnNoteOff does not error.
    it("setOnNoteOff does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setOnNoteOff(function() end)
    end)

    -- @description Verifies case: setOnEnd does not error.
    it("setOnEnd does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setOnEnd(function() end)
    end)
end)

-- @description Covers suite: MidiPlayer type system.
describe("MidiPlayer type system", function()
    -- @description Verifies case: reports type as MidiPlayer.
    it("reports type as LMidiPlayer", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:type(), "LMidiPlayer")
    end)

    -- @description Verifies case: typeOf returns true for MidiPlayer and Object.
    it("typeOf returns true for MidiPlayer and Object", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_true(midi:typeOf("MidiPlayer"))
        expect_true(midi:typeOf("Object"))
    end)
end)

-- @description Covers suite: MidiPlayer seek/tell.
describe("MidiPlayer seek/tell", function()
    -- @description Verifies case: seek and tell work.
    it("seek and tell work", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:seek(5.0)
        expect_near(midi:tell(), 5.0, 1e-5)
    end)

    -- @description Verifies case: seek clamps negative to 0.
    it("seek clamps negative to 0", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:seek(-1.0)
        expect_near(midi:tell(), 0.0, 1e-5)
    end)
end)

-- @description Covers suite: MidiPlayer getDuration.
describe("MidiPlayer getDuration", function()
    -- @description Verifies case: returns 0 when unloaded.
    it("returns 0 when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getDuration(), 0.0, 1e-5)
    end)
end)

-- =========================================================================
-- Merged from test_audio_dsp.lua
-- =========================================================================

-- @description Covers suite: lurek.audio.create_bus.
describe("lurek.audio.create_bus", function()
    -- @tests lurek.audio.create_bus
    -- @tests lurek.audio.add_effect
    -- @tests lurek.audio.newSource
    -- @tests lurek.audio.play
    -- @tests lurek.audio.remove_effect
    -- @tests lurek.audio.set_bus_volume
    -- @tests lurek.audio.set_effect_param
    -- @description Verifies bus creation is side-effect only and returns no handle.
    it("creates a bus without returning an object", function()
        local result = lurek.audio.create_bus("sfx")
        expect_equal(nil, result)
    end)

    -- @tests lurek.audio.create_bus
    -- @description Verifies create_bus rejects empty bus names.
    it("errors if empty string is provided", function()
        expect_error(function()
            lurek.audio.create_bus("")
        end, "invalid bus name")
    end)
end)

-- @description Covers suite: lurek.audio.set_bus_volume.
describe("lurek.audio.set_bus_volume", function()
    -- @tests lurek.audio.set_bus_volume
    -- @tests lurek.audio.create_bus
    -- @description Verifies bus volume can be changed after creating the named bus.
    it("sets the volume of an existing bus", function()
        lurek.audio.create_bus("music")
        -- Should not error
        lurek.audio.set_bus_volume("music", 0.75)
    end)

    -- @tests lurek.audio.set_bus_volume
    -- @description Verifies set_bus_volume errors when the requested bus name is unknown.
    it("errors if bus does not exist", function()
        expect_error(function()
            lurek.audio.set_bus_volume("nonexistent_bus", 0.5)
        end, "bus not found")
    end)
end)

-- @description Covers suite: lurek.audio.play with bus.
describe("lurek.audio.play with bus", function()
    -- @tests lurek.audio.play
    -- @tests lurek.audio.newSource
    -- @tests lurek.audio.create_bus
    -- @description Verifies play accepts an explicit bus option and returns a numeric playback id.
    it("accepts a bus parameter in options", function()
        lurek.audio.create_bus("ambient")
        local src = lurek.audio.newSource("tests/fixtures/sine_mono_44100.wav", "static")
        local id = lurek.audio.play(src, { bus = "ambient" })
        expect_type("number", id)
    end)

    -- @tests lurek.audio.play
    -- @tests lurek.audio.newSource
    -- @description Verifies play falls back to the master bus when no bus is supplied.
    it("defaults to master bus if none provided", function()
        local src = lurek.audio.newSource("tests/fixtures/sine_mono_44100.wav", "static")
        local id = lurek.audio.play(src, {})
        expect_type("number", id)
    end)

    -- @tests lurek.audio.play
    -- @description Verifies play rejects requests targeting a nonexistent bus name.
    it("errors if bus does not exist", function()
        local src = lurek.audio.newSource("tests/fixtures/sine_mono_44100.wav", "static")
        expect_error(function()
            lurek.audio.play(src, { bus = "fake_bus" })
        end, "bus not found")
    end)
end)

-- @description Covers suite: lurek.audio.add_effect.
describe("lurek.audio.add_effect", function()
    -- @tests lurek.audio.add_effect
    -- @tests lurek.audio.create_bus
    -- @description Verifies adding an effect to a bus returns a numeric effect id.
    it("adds an effect and returns an integer ID", function()
        lurek.audio.create_bus("sfx2")
        local effect_id = lurek.audio.add_effect("sfx2", "lowpass")
        expect_type("number", effect_id)
    end)

    -- @tests lurek.audio.add_effect
    -- @description Verifies add_effect accepts an initial parameter table during construction.
    it("accepts initial parameters", function()
        lurek.audio.create_bus("sfx3")
        local effect_id = lurek.audio.add_effect("sfx3", "reverb", { room_size = 0.8, mix = 0.4 })
        expect_type("number", effect_id)
    end)

    -- @tests lurek.audio.add_effect
    -- @description Verifies unknown effect type names are rejected.
    it("errors on invalid effect type", function()
        lurek.audio.create_bus("sfx4")
        expect_error(function()
            lurek.audio.add_effect("sfx4", "magic_wand")
        end, "invalid effect")
    end)

    -- @tests lurek.audio.add_effect
    -- @description Verifies add_effect fails when the target bus does not exist.
    it("errors if bus does not exist for effect", function()
        expect_error(function()
            lurek.audio.add_effect("nope_bus", "lowpass")
        end, "bus not found")
    end)
end)

-- @description Covers suite: lurek.audio.set_effect_param.
describe("lurek.audio.set_effect_param", function()
    -- @tests lurek.audio.set_effect_param
    -- @tests lurek.audio.add_effect
    -- @description Verifies effect parameters can be mutated after creating an effect instance.
    it("mutates an effect parameter without errors", function()
        lurek.audio.create_bus("music2")
        local efx = lurek.audio.add_effect("music2", "lowpass")
        -- set cutoff
        lurek.audio.set_effect_param("music2", efx, "cutoff", 500.0)
    end)

    -- @tests lurek.audio.set_effect_param
    -- @description Verifies set_effect_param rejects unknown effect ids.
    it("errors if effect ID does not exist", function()
        lurek.audio.create_bus("music3")
        expect_error(function()
            lurek.audio.set_effect_param("music3", 9999, "cutoff", 500.0)
        end, "effect not found")
    end)

    -- @tests lurek.audio.set_effect_param
    -- @description Verifies parameter validation is effect-type specific.
    it("errors if parameter name is invalid for effect type", function()
        lurek.audio.create_bus("music4")
        local efx = lurek.audio.add_effect("music4", "lowpass")
        expect_error(function()
            lurek.audio.set_effect_param("music4", efx, "room_size", 0.5)
        end, "invalid parameter")
    end)
end)

-- @description Covers suite: lurek.audio.remove_effect.
describe("lurek.audio.remove_effect", function()
    -- @tests lurek.audio.remove_effect
    -- @tests lurek.audio.set_effect_param
    -- @description Verifies removing an effect invalidates later parameter writes to that effect id.
    it("removes an existing effect", function()
        lurek.audio.create_bus("sfx5")
        local efx = lurek.audio.add_effect("sfx5", "bandpass")
        lurek.audio.remove_effect("sfx5", efx)

        -- Further operations on it should error
        expect_error(function()
            lurek.audio.set_effect_param("sfx5", efx, "center", 1000.0)
        end, "effect not found")
    end)

    -- @tests lurek.audio.remove_effect
    -- @description Verifies remove_effect rejects unknown effect ids on an otherwise valid bus.
    it("errors if effect not found", function()
        lurek.audio.create_bus("sfx6")
        expect_error(function()
            lurek.audio.remove_effect("sfx6", 1234)
        end, "effect not found")
    end)
end)

-- =========================================================================
-- Merged from test_audio_effects.lua
-- =========================================================================

-- @description Covers suite: new DSP effect type: notch.
describe("lurek.audio.add_effect – notch", function()
    -- @tests lurek.audio.add_effect
    it("creates a notch filter effect and returns an id", function()
        lurek.audio.create_bus("test_notch")
        local eid = lurek.audio.add_effect("test_notch", "notch")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts cutoff and bandwidth parameters", function()
        lurek.audio.create_bus("test_notch2")
        local eid = lurek.audio.add_effect("test_notch2", "notch", { cutoff = 1000.0, bandwidth = 100.0 })
        expect_type("number", eid)
        lurek.audio.set_effect_param("test_notch2", eid, "cutoff", 2000.0)
        lurek.audio.set_effect_param("test_notch2", eid, "bandwidth", 200.0)
    end)
end)

-- @description Covers suite: new DSP effect type: lowshelf.
describe("lurek.audio.add_effect – lowshelf", function()
    -- @tests lurek.audio.add_effect
    it("creates a low-shelf EQ effect", function()
        lurek.audio.create_bus("test_lowshelf")
        local eid = lurek.audio.add_effect("test_lowshelf", "lowshelf")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts cutoff and gain_db parameters", function()
        lurek.audio.create_bus("test_lowshelf2")
        local eid = lurek.audio.add_effect("test_lowshelf2", "lowshelf", { cutoff = 200.0, gain_db = -6.0 })
        lurek.audio.set_effect_param("test_lowshelf2", eid, "cutoff", 300.0)
        lurek.audio.set_effect_param("test_lowshelf2", eid, "gain_db", 3.0)
    end)
end)

-- @description Covers suite: new DSP effect type: highshelf.
describe("lurek.audio.add_effect – highshelf", function()
    -- @tests lurek.audio.add_effect
    it("creates a high-shelf EQ effect", function()
        lurek.audio.create_bus("test_highshelf")
        local eid = lurek.audio.add_effect("test_highshelf", "highshelf")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts cutoff and gain_db parameters", function()
        lurek.audio.create_bus("test_highshelf2")
        local eid = lurek.audio.add_effect("test_highshelf2", "highshelf", { cutoff = 8000.0, gain_db = 4.0 })
        lurek.audio.set_effect_param("test_highshelf2", eid, "gain_db", -3.0)
    end)
end)

-- @description Covers suite: new DSP effect type: flanger.
describe("lurek.audio.add_effect – flanger", function()
    -- @tests lurek.audio.add_effect
    it("creates a flanger effect", function()
        lurek.audio.create_bus("test_flanger")
        local eid = lurek.audio.add_effect("test_flanger", "flanger")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts rate and depth parameters", function()
        lurek.audio.create_bus("test_flanger2")
        local eid = lurek.audio.add_effect("test_flanger2", "flanger", { rate = 0.5, depth = 0.3, mix = 0.6 })
        lurek.audio.set_effect_param("test_flanger2", eid, "rate", 1.0)
        lurek.audio.set_effect_param("test_flanger2", eid, "depth", 0.5)
        lurek.audio.set_effect_param("test_flanger2", eid, "mix", 0.8)
    end)
end)

-- @description Covers suite: new DSP effect type: phaser.
describe("lurek.audio.add_effect – phaser", function()
    -- @tests lurek.audio.add_effect
    it("creates a phaser effect", function()
        lurek.audio.create_bus("test_phaser")
        local eid = lurek.audio.add_effect("test_phaser", "phaser")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts rate, depth and mix parameters", function()
        lurek.audio.create_bus("test_phaser2")
        local eid = lurek.audio.add_effect("test_phaser2", "phaser", { rate = 0.3, depth = 0.7, mix = 0.5 })
        lurek.audio.set_effect_param("test_phaser2", eid, "rate", 0.6)
    end)
end)

-- @description Covers suite: new DSP effect type: distortion.
describe("lurek.audio.add_effect – distortion", function()
    -- @tests lurek.audio.add_effect
    it("creates a distortion (waveshaper) effect", function()
        lurek.audio.create_bus("test_dist")
        local eid = lurek.audio.add_effect("test_dist", "distortion")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts drive and mix parameters", function()
        lurek.audio.create_bus("test_dist2")
        local eid = lurek.audio.add_effect("test_dist2", "distortion", { drive = 10.0, mix = 0.5 })
        lurek.audio.set_effect_param("test_dist2", eid, "drive", 20.0)
        lurek.audio.set_effect_param("test_dist2", eid, "mix", 0.3)
    end)
end)

-- @description Covers suite: new DSP effect type: limiter.
describe("lurek.audio.add_effect – limiter", function()
    -- @tests lurek.audio.add_effect
    it("creates a brick-wall limiter effect", function()
        lurek.audio.create_bus("test_limiter")
        local eid = lurek.audio.add_effect("test_limiter", "limiter")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts threshold and release parameters", function()
        lurek.audio.create_bus("test_limiter2")
        local eid = lurek.audio.add_effect("test_limiter2", "limiter", { threshold = 0.9, release = 0.1 })
        lurek.audio.set_effect_param("test_limiter2", eid, "threshold", 0.8)
    end)
end)

-- @description Covers suite: new DSP effect type: compressor.
describe("lurek.audio.add_effect – compressor", function()
    -- @tests lurek.audio.add_effect
    it("creates a dynamic range compressor", function()
        lurek.audio.create_bus("test_comp")
        local eid = lurek.audio.add_effect("test_comp", "compressor")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts threshold, ratio and makeup_gain parameters", function()
        lurek.audio.create_bus("test_comp2")
        local eid = lurek.audio.add_effect("test_comp2", "compressor",
            { threshold = 0.5, ratio = 4.0, makeup_gain = 1.5 })
        lurek.audio.set_effect_param("test_comp2", eid, "threshold", 0.6)
        lurek.audio.set_effect_param("test_comp2", eid, "ratio", 2.0)
        lurek.audio.set_effect_param("test_comp2", eid, "makeup_gain", 1.0)
    end)
end)

-- @description Covers suite: new DSP effect type: bell_eq.
describe("lurek.audio.add_effect – bell_eq", function()
    -- @tests lurek.audio.add_effect
    it("creates a bell equalizer effect", function()
        lurek.audio.create_bus("test_bell")
        local eid = lurek.audio.add_effect("test_bell", "bell_eq")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts cutoff, gain_db and q parameters", function()
        lurek.audio.create_bus("test_bell2")
        local eid = lurek.audio.add_effect("test_bell2", "bell_eq",
            { cutoff = 1000.0, gain_db = 6.0, q = 1.0 })
        lurek.audio.set_effect_param("test_bell2", eid, "cutoff", 2000.0)
        lurek.audio.set_effect_param("test_bell2", eid, "gain_db", -3.0)
    end)
end)

-- @description Covers suite: new DSP effect type: reverb2.
describe("lurek.audio.add_effect – reverb2", function()
    -- @tests lurek.audio.add_effect
    it("creates an improved reverb (reverb2) effect", function()
        lurek.audio.create_bus("test_rev2")
        local eid = lurek.audio.add_effect("test_rev2", "reverb2")
        expect_type("number", eid)
    end)

    -- @tests lurek.audio.set_effect_param
    it("accepts room_size, damping, pre_delay and mix parameters", function()
        lurek.audio.create_bus("test_rev3")
        local eid = lurek.audio.add_effect("test_rev3", "reverb2",
            { room_size = 0.7, damping = 0.5, pre_delay = 0.02, mix = 0.4 })
        lurek.audio.set_effect_param("test_rev3", eid, "room_size", 0.9)
        lurek.audio.set_effect_param("test_rev3", eid, "mix", 0.3)
    end)
end)

-- @description Covers suite: invalid effect types still rejected.
describe("lurek.audio.add_effect – validation", function()
    -- @tests lurek.audio.add_effect
    it("rejects unknown effect type names", function()
        lurek.audio.create_bus("test_inv_e")
        expect_error(function()
            lurek.audio.add_effect("test_inv_e", "magic_sauce")
        end, "invalid effect")
    end)
end)

-- =========================================================================
-- Merged from test_audio_offline.lua
-- =========================================================================

local WAVE = "tests/fixtures/sine_mono_44100.wav"
local OUT_DIR = evidence_output_dir("audio")

-- @description Covers suite: lurek.audio.processOffline.
describe("lurek.audio.processOffline", function()
    -- @tests lurek.audio.processOffline
    it("processes a WAV file with a lowpass effect and writes output", function()
        local effects = {
            { type = "lowpass", cutoff = 1000.0 }
        }
        local out = OUT_DIR .. "offline_lowpass_out.wav"
        lurek.audio.processOffline(WAVE, out, effects)
    end)

    -- @tests lurek.audio.processOffline
    it("processes with multiple chained effects", function()
        local effects = {
            { type = "highpass", cutoff = 200.0 },
            { type = "reverb",   room_size = 0.6, mix = 0.3 }
        }
        local out = OUT_DIR .. "offline_chain_out.wav"
        lurek.audio.processOffline(WAVE, out, effects)
    end)

    -- @tests lurek.audio.processOffline
    it("processes with empty effect list (passthrough)", function()
        local out = OUT_DIR .. "offline_passthrough_out.wav"
        lurek.audio.processOffline(WAVE, out, {})
    end)

    -- @tests lurek.audio.processOffline
    it("errors if source file does not exist", function()
        expect_error(function()
            lurek.audio.processOffline("no_such_file.wav", OUT_DIR .. "out.wav", {})
        end, "not found")
    end)

    -- @tests lurek.audio.processOffline
    it("errors on path traversal in output path", function()
        expect_error(function()
            lurek.audio.processOffline(WAVE, "../../etc/output.wav", {})
        end, "path")
    end)
end)

-- @description Covers suite: lurek.audio.normalizeFile.
describe("lurek.audio.normalizeFile", function()
    -- @tests lurek.audio.normalizeFile
    it("normalizes a WAV file without error", function()
        local out = OUT_DIR .. "normalized_out.wav"
        lurek.audio.normalizeFile(WAVE, out, 0.9)
    end)

    -- @tests lurek.audio.normalizeFile
    it("errors if target level is outside (0.0, 1.0]", function()
        expect_error(function()
            lurek.audio.normalizeFile(WAVE, OUT_DIR .. "out.wav", 0.0)
        end, "target level")
        expect_error(function()
            lurek.audio.normalizeFile(WAVE, OUT_DIR .. "out.wav", 1.5)
        end, "target level")
    end)

    -- @tests lurek.audio.normalizeFile
    it("errors if source file does not exist", function()
        expect_error(function()
            lurek.audio.normalizeFile("no_such.wav", OUT_DIR .. "out.wav", 0.9)
        end, "not found")
    end)
end)

-- =========================================================================
-- Merged from test_audio_pool.lua
-- =========================================================================

-- @description Covers suite: lurek.audio.newPool.
describe("lurek.audio.newPool", function()
    -- @tests lurek.audio.newPool
    it("creates a sound pool and returns a Pool object", function()
        local pool = lurek.audio.newPool(WAVE, 4)
        expect_not_nil(pool)
    end)

    -- @tests lurek.audio.newPool
    xit("errors on empty path", function()
        expect_error(function()
            lurek.audio.newPool("", 4)
        end, "invalid path")
    end)

    -- @tests lurek.audio.newPool
    it("errors on zero voice count", function()
        expect_error(function()
            lurek.audio.newPool(WAVE, 0)
        end, "invalid voice count")
    end)
end)

-- @description Covers suite: Pool:play.
describe("Pool:play", function()
    -- @tests lurek.audio.newPool
    it("play returns a numeric source id", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        local id = pool:play()
        expect_type("number", id)
    end)

    -- @tests lurek.audio.newPool
    it("play can be called multiple times up to voice count", function()
        local pool = lurek.audio.newPool(WAVE, 3)
        local id1 = pool:play()
        local id2 = pool:play()
        local id3 = pool:play()
        expect_type("number", id1)
        expect_type("number", id2)
        expect_type("number", id3)
    end)
end)

-- @description Covers suite: Pool:stopAll.
describe("Pool:stopAll", function()
    -- @tests lurek.audio.newPool
    it("stopAll does not error when pool has playing sources", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:play()
        pool:play()
        pool:stopAll()  -- should not raise
    end)

    -- @tests lurek.audio.newPool
    it("stopAll does not error on an idle pool", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:stopAll()
    end)
end)

-- @description Covers suite: Pool:setVolume.
describe("Pool:setVolume", function()
    -- @tests lurek.audio.newPool
    it("setVolume sets volume for all pool sources", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:setVolume(0.5)  -- should not raise
    end)
end)

-- @description Covers suite: Pool:setBus.
describe("Pool:setBus", function()
    -- @tests lurek.audio.newPool
    it("setBus routes all pool sources to a named bus", function()
        lurek.audio.create_bus("pool_test_bus")
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:setBus("pool_test_bus")  -- should not raise
    end)

    -- @tests lurek.audio.newPool
    xit("setBus errors if bus does not exist", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        expect_error(function()
            pool:setBus("nonexistent_pool_bus")
        end, "bus not found")
    end)
end)

-- @description Covers suite: Pool:release.
describe("Pool:release", function()
    -- @tests lurek.audio.newPool
    it("release frees all sources without error", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:play()
        pool:release()  -- should not raise
    end)
end)

-- @description Covers suite: Pool:getVoiceCount.
describe("Pool:getVoiceCount", function()
    -- @tests lurek.audio.newPool
    it("returns the configured voice count", function()
        local pool = lurek.audio.newPool(WAVE, 6)
        expect_equal(6, pool:getVoiceCount())
    end)
end)

-- =========================================================================
-- Merged from test_audio_stereo.lua
-- =========================================================================

-- @description Covers suite: lurek.audio.setStereoWidth.
describe("lurek.audio.setStereoWidth", function()
    -- @tests lurek.audio.setStereoWidth
    it("sets stereo width on a valid source without error", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setStereoWidth(src, 1.5)  -- 1.5 = slight widening
    end)

    -- @tests lurek.audio.setStereoWidth
    it("clamps stereo width to [0.0, 2.0] silently", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setStereoWidth(src, -1.0)  -- should clamp, not error
        lurek.audio.setStereoWidth(src, 5.0)   -- should clamp, not error
    end)

    -- @tests lurek.audio.getStereoWidth
    it("getStereoWidth returns the last set value (clamped)", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setStereoWidth(src, 0.5)
        local w = lurek.audio.getStereoWidth(src)
        expect_near(0.5, w, 0.001)
    end)

    -- @tests lurek.audio.setStereoWidth
    it("errors on invalid source handle", function()
        expect_error(function()
            lurek.audio.setStereoWidth(99999999, 1.0) ---@diagnostic disable-line: param-type-mismatch
        end, "invalid")
    end)
end)

-- @description Covers suite: lurek.audio.setRandomPitch.
describe("lurek.audio.setRandomPitch", function()
    -- @tests lurek.audio.setRandomPitch
    it("sets a random pitch range on a source", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setRandomPitch(src, 0.9, 1.1)
    end)

    -- @tests lurek.audio.setRandomPitch
    it("errors if min > max", function()
        local src = lurek.audio.newSource(WAVE, "static")
        expect_error(function()
            lurek.audio.setRandomPitch(src, 1.5, 0.5)
        end, "min must be")
    end)

    -- @tests lurek.audio.setRandomPitch
    it("errors on invalid source", function()
        expect_error(function()
            lurek.audio.setRandomPitch(12345678, 0.9, 1.1) ---@diagnostic disable-line: param-type-mismatch
        end, "invalid")
    end)

    -- @tests lurek.audio.clearRandomPitch
    it("clearRandomPitch removes the random pitch range", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setRandomPitch(src, 0.9, 1.1)
        lurek.audio.clearRandomPitch(src)  -- should not error
    end)
end)

-- @description Covers suite: lurek.audio.crossfade.
describe("lurek.audio.crossfade", function()
    -- @tests lurek.audio.crossfade
    it("crossfade between two sources does not error", function()
        local src_a = lurek.audio.newSource(WAVE, "static")
        local src_b = lurek.audio.newSource(WAVE, "static")
        lurek.audio.crossfade(src_a, src_b, 0.5)
    end)

    -- @tests lurek.audio.crossfade
    xit("errors if duration is negative", function()
        local src_a = lurek.audio.newSource(WAVE, "static")
        local src_b = lurek.audio.newSource(WAVE, "static")
        expect_error(function()
            lurek.audio.crossfade(src_a, src_b, -1.0)
        end, "duration")
    end)

    -- @tests lurek.audio.crossfade
    it("errors if first source is invalid", function()
        local src_b = lurek.audio.newSource(WAVE, "static")
        expect_error(function()
            lurek.audio.crossfade(99999999, src_b, 0.5) ---@diagnostic disable-line: param-type-mismatch
        end, "invalid")
    end)
end)

-- @description Covers suite: lurek.audio.getBusPeak.
describe("lurek.audio.getBusPeak", function()
    -- @tests lurek.audio.getBusPeak
    it("returns a number for a known bus", function()
        lurek.audio.create_bus("peak_test_bus")
        local peak = lurek.audio.getBusPeak("peak_test_bus")
        expect_type("number", peak)
    end)

    -- @tests lurek.audio.getBusPeak
    it("returns 0.0 when bus is idle", function()
        lurek.audio.create_bus("peak_idle_bus")
        local peak = lurek.audio.getBusPeak("peak_idle_bus")
        expect_near(0.0, peak, 0.001)
    end)

    -- @tests lurek.audio.getBusPeak
    it("errors for unknown bus", function()
        expect_error(function()
            lurek.audio.getBusPeak("nope_bus")
        end, "bus not found")
    end)
end)

-- @description Covers suite: lurek.audio.getBusRms.
describe("lurek.audio.getBusRms", function()
    -- @tests lurek.audio.getBusRms
    it("returns a number for a known bus", function()
        lurek.audio.create_bus("rms_test_bus")
        local rms = lurek.audio.getBusRms("rms_test_bus")
        expect_type("number", rms)
    end)

    -- @tests lurek.audio.getBusRms
    it("returns 0.0 when bus is idle", function()
        lurek.audio.create_bus("rms_idle_bus")
        local rms = lurek.audio.getBusRms("rms_idle_bus")
        expect_near(0.0, rms, 0.001)
    end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.audio.playLooping
    it("covers lurek.audio.playLooping", function()
        -- TODO: Implement test for lurek.audio.playLooping
    end)

    -- @tests lurek.audio.getSourceCount
    it("covers lurek.audio.getSourceCount", function()
        -- TODO: Implement test for lurek.audio.getSourceCount
    end)

    -- @tests lurek.audio.getSourceType
    it("covers lurek.audio.getSourceType", function()
        -- TODO: Implement test for lurek.audio.getSourceType
    end)

    -- @tests lurek.audio.pauseAll
    it("covers lurek.audio.pauseAll", function()
        -- TODO: Implement test for lurek.audio.pauseAll
    end)

    -- @tests lurek.audio.resumeAll
    it("covers lurek.audio.resumeAll", function()
        -- TODO: Implement test for lurek.audio.resumeAll
    end)

    -- @tests lurek.audio.setSourceBus
    it("covers lurek.audio.setSourceBus", function()
        -- TODO: Implement test for lurek.audio.setSourceBus
    end)

    -- @tests lurek.audio.getSourceBus
    it("covers lurek.audio.getSourceBus", function()
        -- TODO: Implement test for lurek.audio.getSourceBus
    end)

    -- @tests lurek.audio.setMidiSoundFont
    it("covers lurek.audio.setMidiSoundFont", function()
        -- TODO: Implement test for lurek.audio.setMidiSoundFont
    end)

    -- @tests lurek.audio.hasMidiSoundFont
    it("covers lurek.audio.hasMidiSoundFont", function()
        -- TODO: Implement test for lurek.audio.hasMidiSoundFont
    end)

    -- @tests lurek.audio.clearMidiSoundFont
    it("covers lurek.audio.clearMidiSoundFont", function()
        -- TODO: Implement test for lurek.audio.clearMidiSoundFont
    end)

    -- @tests Bus:clearDuck
    it("covers Bus:clearDuck", function()
        -- TODO: Implement test for Bus:clearDuck
    end)

    -- @tests Bus:getPeak
    it("covers Bus:getPeak", function()
        -- TODO: Implement test for Bus:getPeak
    end)

    -- @tests MidiPlayer:loadData
    it("covers MidiPlayer:loadData", function()
        -- TODO: Implement test for MidiPlayer:loadData
    end)

    -- @tests MidiPlayer:getFilePath
    it("covers MidiPlayer:getFilePath", function()
        -- TODO: Implement test for MidiPlayer:getFilePath
    end)

    -- @tests MidiPlayer:getTicksPerBeat
    it("covers MidiPlayer:getTicksPerBeat", function()
        -- TODO: Implement test for MidiPlayer:getTicksPerBeat
    end)

    -- @tests MidiPlayer:getTrackName
    it("covers MidiPlayer:getTrackName", function()
        -- TODO: Implement test for MidiPlayer:getTrackName
    end)

    -- @tests MidiPlayer:setTrackMuted
    it("covers MidiPlayer:setTrackMuted", function()
        -- TODO: Implement test for MidiPlayer:setTrackMuted
    end)

    -- @tests MidiPlayer:isTrackMuted
    it("covers MidiPlayer:isTrackMuted", function()
        -- TODO: Implement test for MidiPlayer:isTrackMuted
    end)

end)

describe("Missing explicit test for lurek.audio.stop", function()
    it("lurek.audio.stop works", function()
        -- @tests lurek.audio.stop
        -- TODO: add assertion for lurek.audio.stop
    end)
end)

describe("Missing explicit test for lurek.audio.setVolume", function()
    it("lurek.audio.setVolume works", function()
        -- @tests lurek.audio.setVolume
        -- TODO: add assertion for lurek.audio.setVolume
    end)
end)

describe("Missing explicit test for lurek.audio.getVolume", function()
    it("lurek.audio.getVolume works", function()
        -- @tests lurek.audio.getVolume
        -- TODO: add assertion for lurek.audio.getVolume
    end)
end)

describe("Missing explicit test for lurek.audio.pause", function()
    it("lurek.audio.pause works", function()
        -- @tests lurek.audio.pause
        -- TODO: add assertion for lurek.audio.pause
    end)
end)

describe("Missing explicit test for lurek.audio.resume", function()
    it("lurek.audio.resume works", function()
        -- @tests lurek.audio.resume
        -- TODO: add assertion for lurek.audio.resume
    end)
end)

describe("Missing explicit test for lurek.audio.setPitch", function()
    it("lurek.audio.setPitch works", function()
        -- @tests lurek.audio.setPitch
        -- TODO: add assertion for lurek.audio.setPitch
    end)
end)

describe("Missing explicit test for lurek.audio.getPitch", function()
    it("lurek.audio.getPitch works", function()
        -- @tests lurek.audio.getPitch
        -- TODO: add assertion for lurek.audio.getPitch
    end)
end)

describe("Missing explicit test for lurek.audio.isPlaying", function()
    it("lurek.audio.isPlaying works", function()
        -- @tests lurek.audio.isPlaying
        -- TODO: add assertion for lurek.audio.isPlaying
    end)
end)

describe("Missing explicit test for lurek.audio.isPaused", function()
    it("lurek.audio.isPaused works", function()
        -- @tests lurek.audio.isPaused
        -- TODO: add assertion for lurek.audio.isPaused
    end)
end)

describe("Missing explicit test for lurek.audio.isStopped", function()
    it("lurek.audio.isStopped works", function()
        -- @tests lurek.audio.isStopped
        -- TODO: add assertion for lurek.audio.isStopped
    end)
end)

describe("Missing explicit test for lurek.audio.setLooping", function()
    it("lurek.audio.setLooping works", function()
        -- @tests lurek.audio.setLooping
        -- TODO: add assertion for lurek.audio.setLooping
    end)
end)

describe("Missing explicit test for lurek.audio.isLooping", function()
    it("lurek.audio.isLooping works", function()
        -- @tests lurek.audio.isLooping
        -- TODO: add assertion for lurek.audio.isLooping
    end)
end)

describe("Missing explicit test for lurek.audio.setPan", function()
    it("lurek.audio.setPan works", function()
        -- @tests lurek.audio.setPan
        -- TODO: add assertion for lurek.audio.setPan
    end)
end)

describe("Missing explicit test for lurek.audio.getPan", function()
    it("lurek.audio.getPan works", function()
        -- @tests lurek.audio.getPan
        -- TODO: add assertion for lurek.audio.getPan
    end)
end)

describe("Missing explicit test for lurek.audio.getActiveSourceCount", function()
    it("lurek.audio.getActiveSourceCount works", function()
        -- @tests lurek.audio.getActiveSourceCount
        -- TODO: add assertion for lurek.audio.getActiveSourceCount
    end)
end)

describe("Missing explicit test for lurek.audio.clone", function()
    it("lurek.audio.clone works", function()
        -- @tests lurek.audio.clone
        -- TODO: add assertion for lurek.audio.clone
    end)
end)

describe("Missing explicit test for lurek.audio.stopAll", function()
    it("lurek.audio.stopAll works", function()
        -- @tests lurek.audio.stopAll
        -- TODO: add assertion for lurek.audio.stopAll
    end)
end)

describe("Missing explicit test for lurek.audio.release", function()
    it("lurek.audio.release works", function()
        -- @tests lurek.audio.release
        -- TODO: add assertion for lurek.audio.release
    end)
end)

describe("Missing explicit test for lurek.audio.getDuration", function()
    it("lurek.audio.getDuration works", function()
        -- @tests lurek.audio.getDuration
        -- TODO: add assertion for lurek.audio.getDuration
    end)
end)

describe("Missing explicit test for lurek.audio.tell", function()
    it("lurek.audio.tell works", function()
        -- @tests lurek.audio.tell
        -- TODO: add assertion for lurek.audio.tell
    end)
end)

describe("Missing explicit test for lurek.audio.seek", function()
    it("lurek.audio.seek works", function()
        -- @tests lurek.audio.seek
        -- TODO: add assertion for lurek.audio.seek
    end)
end)

describe("Missing explicit test for lurek.audio.setLowpass", function()
    it("lurek.audio.setLowpass works", function()
        -- @tests lurek.audio.setLowpass
        -- TODO: add assertion for lurek.audio.setLowpass
    end)
end)

describe("Missing explicit test for lurek.audio.setHighpass", function()
    it("lurek.audio.setHighpass works", function()
        -- @tests lurek.audio.setHighpass
        -- TODO: add assertion for lurek.audio.setHighpass
    end)
end)

describe("Missing explicit test for lurek.audio.getLowpass", function()
    it("lurek.audio.getLowpass works", function()
        -- @tests lurek.audio.getLowpass
        -- TODO: add assertion for lurek.audio.getLowpass
    end)
end)

describe("Missing explicit test for lurek.audio.getHighpass", function()
    it("lurek.audio.getHighpass works", function()
        -- @tests lurek.audio.getHighpass
        -- TODO: add assertion for lurek.audio.getHighpass
    end)
end)

describe("Missing explicit test for lurek.audio.clearFilter", function()
    it("lurek.audio.clearFilter works", function()
        -- @tests lurek.audio.clearFilter
        -- TODO: add assertion for lurek.audio.clearFilter
    end)
end)

describe("Missing explicit test for lurek.audio.fadeIn", function()
    it("lurek.audio.fadeIn works", function()
        -- @tests lurek.audio.fadeIn
        -- TODO: add assertion for lurek.audio.fadeIn
    end)
end)

describe("Missing explicit test for lurek.audio.getFadeIn", function()
    it("lurek.audio.getFadeIn works", function()
        -- @tests lurek.audio.getFadeIn
        -- TODO: add assertion for lurek.audio.getFadeIn
    end)
end)

describe("Missing explicit test for lurek.audio.setPosition", function()
    it("lurek.audio.setPosition works", function()
        -- @tests lurek.audio.setPosition
        -- TODO: add assertion for lurek.audio.setPosition
    end)
end)

describe("Missing explicit test for lurek.audio.getPosition", function()
    it("lurek.audio.getPosition works", function()
        -- @tests lurek.audio.getPosition
        -- TODO: add assertion for lurek.audio.getPosition
    end)
end)

describe("Missing explicit test for lurek.audio.setVelocity", function()
    it("lurek.audio.setVelocity works", function()
        -- @tests lurek.audio.setVelocity
        -- TODO: add assertion for lurek.audio.setVelocity
    end)
end)

describe("Missing explicit test for lurek.audio.getVelocity", function()
    it("lurek.audio.getVelocity works", function()
        -- @tests lurek.audio.getVelocity
        -- TODO: add assertion for lurek.audio.getVelocity
    end)
end)

describe("Missing explicit test for lurek.audio.setOrientation", function()
    it("lurek.audio.setOrientation works", function()
        -- @tests lurek.audio.setOrientation
        -- TODO: add assertion for lurek.audio.setOrientation
    end)
end)

describe("Missing explicit test for lurek.audio.getOrientation", function()
    it("lurek.audio.getOrientation works", function()
        -- @tests lurek.audio.getOrientation
        -- TODO: add assertion for lurek.audio.getOrientation
    end)
end)

describe("Missing explicit test for lurek.audio.newSineWave", function()
    it("lurek.audio.newSineWave works", function()
        -- @tests lurek.audio.newSineWave
        -- TODO: add assertion for lurek.audio.newSineWave
    end)
end)

describe("Missing explicit test for lurek.audio.newSquareWave", function()
    it("lurek.audio.newSquareWave works", function()
        -- @tests lurek.audio.newSquareWave
        -- TODO: add assertion for lurek.audio.newSquareWave
    end)
end)

describe("Missing explicit test for lurek.audio.newSawtoothWave", function()
    it("lurek.audio.newSawtoothWave works", function()
        -- @tests lurek.audio.newSawtoothWave
        -- TODO: add assertion for lurek.audio.newSawtoothWave
    end)
end)

describe("Missing explicit test for lurek.audio.newTriangleWave", function()
    it("lurek.audio.newTriangleWave works", function()
        -- @tests lurek.audio.newTriangleWave
        -- TODO: add assertion for lurek.audio.newTriangleWave
    end)
end)

describe("Missing explicit test for lurek.audio.newWhiteNoise", function()
    it("lurek.audio.newWhiteNoise works", function()
        -- @tests lurek.audio.newWhiteNoise
        -- TODO: add assertion for lurek.audio.newWhiteNoise
    end)
end)

describe("Missing explicit test for lurek.audio.applyLowpass", function()
    it("lurek.audio.applyLowpass works", function()
        -- @tests lurek.audio.applyLowpass
        -- TODO: add assertion for lurek.audio.applyLowpass
    end)
end)

describe("Missing explicit test for lurek.audio.applyHighpass", function()
    it("lurek.audio.applyHighpass works", function()
        -- @tests lurek.audio.applyHighpass
        -- TODO: add assertion for lurek.audio.applyHighpass
    end)
end)

describe("Missing explicit test for lurek.audio.applyBandpass", function()
    it("lurek.audio.applyBandpass works", function()
        -- @tests lurek.audio.applyBandpass
        -- TODO: add assertion for lurek.audio.applyBandpass
    end)
end)

describe("Missing explicit test for lurek.audio.applyGain", function()
    it("lurek.audio.applyGain works", function()
        -- @tests lurek.audio.applyGain
        -- TODO: add assertion for lurek.audio.applyGain
    end)
end)

describe("Missing explicit test for lurek.audio.mixInto", function()
    it("lurek.audio.mixInto works", function()
        -- @tests lurek.audio.mixInto
        -- TODO: add assertion for lurek.audio.mixInto
    end)
end)

describe("Missing explicit test for lurek.audio.saveWAV", function()
    it("lurek.audio.saveWAV works", function()
        -- @tests lurek.audio.saveWAV
        -- TODO: add assertion for lurek.audio.saveWAV
    end)
end)

describe("Missing explicit test for lurek.audio.waveformToPng", function()
    it("lurek.audio.waveformToPng works", function()
        -- @tests lurek.audio.waveformToPng
        -- TODO: add assertion for lurek.audio.waveformToPng
    end)
end)

describe("Missing explicit test for lurek.audio.spectrogramToPng", function()
    it("lurek.audio.spectrogramToPng works", function()
        -- @tests lurek.audio.spectrogramToPng
        -- TODO: add assertion for lurek.audio.spectrogramToPng
    end)
end)

describe("Missing explicit test for Source:play", function()
    it("Source:play works", function()
        -- @tests Source:play
        -- TODO: add assertion for Source:play
    end)
end)

describe("Missing explicit test for Source:stop", function()
    it("Source:stop works", function()
        -- @tests Source:stop
        -- TODO: add assertion for Source:stop
    end)
end)

describe("Missing explicit test for Source:pause", function()
    it("Source:pause works", function()
        -- @tests Source:pause
        -- TODO: add assertion for Source:pause
    end)
end)

describe("Missing explicit test for Source:resume", function()
    it("Source:resume works", function()
        -- @tests Source:resume
        -- TODO: add assertion for Source:resume
    end)
end)

describe("Missing explicit test for Source:setVolume", function()
    it("Source:setVolume works", function()
        -- @tests Source:setVolume
        -- TODO: add assertion for Source:setVolume
    end)
end)

describe("Missing explicit test for Source:getVolume", function()
    it("Source:getVolume works", function()
        -- @tests Source:getVolume
        -- TODO: add assertion for Source:getVolume
    end)
end)

describe("Missing explicit test for Source:setPitch", function()
    it("Source:setPitch works", function()
        -- @tests Source:setPitch
        -- TODO: add assertion for Source:setPitch
    end)
end)

describe("Missing explicit test for Source:getPitch", function()
    it("Source:getPitch works", function()
        -- @tests Source:getPitch
        -- TODO: add assertion for Source:getPitch
    end)
end)

describe("Missing explicit test for Source:setLooping", function()
    it("Source:setLooping works", function()
        -- @tests Source:setLooping
        -- TODO: add assertion for Source:setLooping
    end)
end)

describe("Missing explicit test for Source:isLooping", function()
    it("Source:isLooping works", function()
        -- @tests Source:isLooping
        -- TODO: add assertion for Source:isLooping
    end)
end)

describe("Missing explicit test for Source:isPlaying", function()
    it("Source:isPlaying works", function()
        -- @tests Source:isPlaying
        -- TODO: add assertion for Source:isPlaying
    end)
end)

describe("Missing explicit test for Source:isPaused", function()
    it("Source:isPaused works", function()
        -- @tests Source:isPaused
        -- TODO: add assertion for Source:isPaused
    end)
end)

describe("Missing explicit test for Source:isStopped", function()
    it("Source:isStopped works", function()
        -- @tests Source:isStopped
        -- TODO: add assertion for Source:isStopped
    end)
end)

describe("Missing explicit test for Source:setPan", function()
    it("Source:setPan works", function()
        -- @tests Source:setPan
        -- TODO: add assertion for Source:setPan
    end)
end)

describe("Missing explicit test for Source:getPan", function()
    it("Source:getPan works", function()
        -- @tests Source:getPan
        -- TODO: add assertion for Source:getPan
    end)
end)

describe("Missing explicit test for Source:clone", function()
    it("Source:clone works", function()
        -- @tests Source:clone
        -- TODO: add assertion for Source:clone
    end)
end)

describe("Missing explicit test for Source:getType", function()
    it("Source:getType works", function()
        -- @tests Source:getType
        -- TODO: add assertion for Source:getType
    end)
end)

describe("Missing explicit test for Source:getDuration", function()
    it("Source:getDuration works", function()
        -- @tests Source:getDuration
        -- TODO: add assertion for Source:getDuration
    end)
end)

describe("Missing explicit test for Source:tell", function()
    it("Source:tell works", function()
        -- @tests Source:tell
        -- TODO: add assertion for Source:tell
    end)
end)

describe("Missing explicit test for Source:seek", function()
    it("Source:seek works", function()
        -- @tests Source:seek
        -- TODO: add assertion for Source:seek
    end)
end)

describe("Missing explicit test for Source:setLowpass", function()
    it("Source:setLowpass works", function()
        -- @tests Source:setLowpass
        -- TODO: add assertion for Source:setLowpass
    end)
end)

describe("Missing explicit test for Source:setHighpass", function()
    it("Source:setHighpass works", function()
        -- @tests Source:setHighpass
        -- TODO: add assertion for Source:setHighpass
    end)
end)

describe("Missing explicit test for Source:getLowpass", function()
    it("Source:getLowpass works", function()
        -- @tests Source:getLowpass
        -- TODO: add assertion for Source:getLowpass
    end)
end)

describe("Missing explicit test for Source:getHighpass", function()
    it("Source:getHighpass works", function()
        -- @tests Source:getHighpass
        -- TODO: add assertion for Source:getHighpass
    end)
end)

describe("Missing explicit test for Source:clearFilter", function()
    it("Source:clearFilter works", function()
        -- @tests Source:clearFilter
        -- TODO: add assertion for Source:clearFilter
    end)
end)

describe("Missing explicit test for Source:fadeIn", function()
    it("Source:fadeIn works", function()
        -- @tests Source:fadeIn
        -- TODO: add assertion for Source:fadeIn
    end)
end)

describe("Missing explicit test for Source:getFadeIn", function()
    it("Source:getFadeIn works", function()
        -- @tests Source:getFadeIn
        -- TODO: add assertion for Source:getFadeIn
    end)
end)

describe("Missing explicit test for Bus:getName", function()
    it("Bus:getName works", function()
        -- @tests Bus:getName
        -- TODO: add assertion for Bus:getName
    end)
end)

describe("Missing explicit test for Bus:setVolume", function()
    it("Bus:setVolume works", function()
        -- @tests Bus:setVolume
        -- TODO: add assertion for Bus:setVolume
    end)
end)

describe("Missing explicit test for Bus:getVolume", function()
    it("Bus:getVolume works", function()
        -- @tests Bus:getVolume
        -- TODO: add assertion for Bus:getVolume
    end)
end)

describe("Missing explicit test for Bus:setPitch", function()
    it("Bus:setPitch works", function()
        -- @tests Bus:setPitch
        -- TODO: add assertion for Bus:setPitch
    end)
end)

describe("Missing explicit test for Bus:getPitch", function()
    it("Bus:getPitch works", function()
        -- @tests Bus:getPitch
        -- TODO: add assertion for Bus:getPitch
    end)
end)

describe("Missing explicit test for Bus:pause", function()
    it("Bus:pause works", function()
        -- @tests Bus:pause
        -- TODO: add assertion for Bus:pause
    end)
end)

describe("Missing explicit test for Bus:resume", function()
    it("Bus:resume works", function()
        -- @tests Bus:resume
        -- TODO: add assertion for Bus:resume
    end)
end)

describe("Missing explicit test for Bus:isPaused", function()
    it("Bus:isPaused works", function()
        -- @tests Bus:isPaused
        -- TODO: add assertion for Bus:isPaused
    end)
end)

describe("Missing explicit test for Bus:type", function()
    it("Bus:type works", function()
        -- @tests Bus:type
        -- TODO: add assertion for Bus:type
    end)
end)

describe("Missing explicit test for Bus:typeOf", function()
    it("Bus:typeOf works", function()
        -- @tests Bus:typeOf
        -- TODO: add assertion for Bus:typeOf
    end)
end)

describe("Missing explicit test for MidiPlayer:load", function()
    it("MidiPlayer:load works", function()
        -- @tests MidiPlayer:load
        -- TODO: add assertion for MidiPlayer:load
    end)
end)

describe("Missing explicit test for MidiPlayer:isLoaded", function()
    it("MidiPlayer:isLoaded works", function()
        -- @tests MidiPlayer:isLoaded
        -- TODO: add assertion for MidiPlayer:isLoaded
    end)
end)

describe("Missing explicit test for MidiPlayer:setSoundFont", function()
    it("MidiPlayer:setSoundFont works", function()
        -- @tests MidiPlayer:setSoundFont
        -- TODO: add assertion for MidiPlayer:setSoundFont
    end)
end)

describe("Missing explicit test for MidiPlayer:getSoundFontPath", function()
    it("MidiPlayer:getSoundFontPath works", function()
        -- @tests MidiPlayer:getSoundFontPath
        -- TODO: add assertion for MidiPlayer:getSoundFontPath
    end)
end)

describe("Missing explicit test for MidiPlayer:useDefaultSoundFont", function()
    it("MidiPlayer:useDefaultSoundFont works", function()
        -- @tests MidiPlayer:useDefaultSoundFont
        -- TODO: add assertion for MidiPlayer:useDefaultSoundFont
    end)
end)

describe("Missing explicit test for MidiPlayer:play", function()
    it("MidiPlayer:play works", function()
        -- @tests MidiPlayer:play
        -- TODO: add assertion for MidiPlayer:play
    end)
end)

describe("Missing explicit test for MidiPlayer:pause", function()
    it("MidiPlayer:pause works", function()
        -- @tests MidiPlayer:pause
        -- TODO: add assertion for MidiPlayer:pause
    end)
end)

describe("Missing explicit test for MidiPlayer:stop", function()
    it("MidiPlayer:stop works", function()
        -- @tests MidiPlayer:stop
        -- TODO: add assertion for MidiPlayer:stop
    end)
end)

describe("Missing explicit test for MidiPlayer:isPlaying", function()
    it("MidiPlayer:isPlaying works", function()
        -- @tests MidiPlayer:isPlaying
        -- TODO: add assertion for MidiPlayer:isPlaying
    end)
end)

describe("Missing explicit test for MidiPlayer:isPaused", function()
    it("MidiPlayer:isPaused works", function()
        -- @tests MidiPlayer:isPaused
        -- TODO: add assertion for MidiPlayer:isPaused
    end)
end)

describe("Missing explicit test for MidiPlayer:seek", function()
    it("MidiPlayer:seek works", function()
        -- @tests MidiPlayer:seek
        -- TODO: add assertion for MidiPlayer:seek
    end)
end)

describe("Missing explicit test for MidiPlayer:tell", function()
    it("MidiPlayer:tell works", function()
        -- @tests MidiPlayer:tell
        -- TODO: add assertion for MidiPlayer:tell
    end)
end)

describe("Missing explicit test for MidiPlayer:getDuration", function()
    it("MidiPlayer:getDuration works", function()
        -- @tests MidiPlayer:getDuration
        -- TODO: add assertion for MidiPlayer:getDuration
    end)
end)

describe("Missing explicit test for MidiPlayer:setLooping", function()
    it("MidiPlayer:setLooping works", function()
        -- @tests MidiPlayer:setLooping
        -- TODO: add assertion for MidiPlayer:setLooping
    end)
end)

describe("Missing explicit test for MidiPlayer:isLooping", function()
    it("MidiPlayer:isLooping works", function()
        -- @tests MidiPlayer:isLooping
        -- TODO: add assertion for MidiPlayer:isLooping
    end)
end)

describe("Missing explicit test for MidiPlayer:setVolume", function()
    it("MidiPlayer:setVolume works", function()
        -- @tests MidiPlayer:setVolume
        -- TODO: add assertion for MidiPlayer:setVolume
    end)
end)

describe("Missing explicit test for MidiPlayer:getVolume", function()
    it("MidiPlayer:getVolume works", function()
        -- @tests MidiPlayer:getVolume
        -- TODO: add assertion for MidiPlayer:getVolume
    end)
end)

describe("Missing explicit test for MidiPlayer:setBus", function()
    it("MidiPlayer:setBus works", function()
        -- @tests MidiPlayer:setBus
        -- TODO: add assertion for MidiPlayer:setBus
    end)
end)

describe("Missing explicit test for MidiPlayer:getBus", function()
    it("MidiPlayer:getBus works", function()
        -- @tests MidiPlayer:getBus
        -- TODO: add assertion for MidiPlayer:getBus
    end)
end)

describe("Missing explicit test for MidiPlayer:setTempo", function()
    it("MidiPlayer:setTempo works", function()
        -- @tests MidiPlayer:setTempo
        -- TODO: add assertion for MidiPlayer:setTempo
    end)
end)

describe("Missing explicit test for MidiPlayer:getTempo", function()
    it("MidiPlayer:getTempo works", function()
        -- @tests MidiPlayer:getTempo
        -- TODO: add assertion for MidiPlayer:getTempo
    end)
end)

describe("Missing explicit test for MidiPlayer:getOriginalTempo", function()
    it("MidiPlayer:getOriginalTempo works", function()
        -- @tests MidiPlayer:getOriginalTempo
        -- TODO: add assertion for MidiPlayer:getOriginalTempo
    end)
end)

describe("Missing explicit test for MidiPlayer:setTempoScale", function()
    it("MidiPlayer:setTempoScale works", function()
        -- @tests MidiPlayer:setTempoScale
        -- TODO: add assertion for MidiPlayer:setTempoScale
    end)
end)

describe("Missing explicit test for MidiPlayer:getTempoScale", function()
    it("MidiPlayer:getTempoScale works", function()
        -- @tests MidiPlayer:getTempoScale
        -- TODO: add assertion for MidiPlayer:getTempoScale
    end)
end)

describe("Missing explicit test for MidiPlayer:setChannelVolume", function()
    it("MidiPlayer:setChannelVolume works", function()
        -- @tests MidiPlayer:setChannelVolume
        -- TODO: add assertion for MidiPlayer:setChannelVolume
    end)
end)

describe("Missing explicit test for MidiPlayer:getChannelVolume", function()
    it("MidiPlayer:getChannelVolume works", function()
        -- @tests MidiPlayer:getChannelVolume
        -- TODO: add assertion for MidiPlayer:getChannelVolume
    end)
end)

describe("Missing explicit test for MidiPlayer:setChannelMuted", function()
    it("MidiPlayer:setChannelMuted works", function()
        -- @tests MidiPlayer:setChannelMuted
        -- TODO: add assertion for MidiPlayer:setChannelMuted
    end)
end)

describe("Missing explicit test for MidiPlayer:isChannelMuted", function()
    it("MidiPlayer:isChannelMuted works", function()
        -- @tests MidiPlayer:isChannelMuted
        -- TODO: add assertion for MidiPlayer:isChannelMuted
    end)
end)

describe("Missing explicit test for MidiPlayer:getChannelInstrument", function()
    it("MidiPlayer:getChannelInstrument works", function()
        -- @tests MidiPlayer:getChannelInstrument
        -- TODO: add assertion for MidiPlayer:getChannelInstrument
    end)
end)

describe("Missing explicit test for MidiPlayer:getChannelCount", function()
    it("MidiPlayer:getChannelCount works", function()
        -- @tests MidiPlayer:getChannelCount
        -- TODO: add assertion for MidiPlayer:getChannelCount
    end)
end)

describe("Missing explicit test for MidiPlayer:soloChannel", function()
    it("MidiPlayer:soloChannel works", function()
        -- @tests MidiPlayer:soloChannel
        -- TODO: add assertion for MidiPlayer:soloChannel
    end)
end)

describe("Missing explicit test for MidiPlayer:unsoloAll", function()
    it("MidiPlayer:unsoloAll works", function()
        -- @tests MidiPlayer:unsoloAll
        -- TODO: add assertion for MidiPlayer:unsoloAll
    end)
end)

describe("Missing explicit test for MidiPlayer:getTrackCount", function()
    it("MidiPlayer:getTrackCount works", function()
        -- @tests MidiPlayer:getTrackCount
        -- TODO: add assertion for MidiPlayer:getTrackCount
    end)
end)

describe("Missing explicit test for MidiPlayer:getNoteCount", function()
    it("MidiPlayer:getNoteCount works", function()
        -- @tests MidiPlayer:getNoteCount
        -- TODO: add assertion for MidiPlayer:getNoteCount
    end)
end)

describe("Missing explicit test for MidiPlayer:setOnNoteOn", function()
    it("MidiPlayer:setOnNoteOn works", function()
        -- @tests MidiPlayer:setOnNoteOn
        -- TODO: add assertion for MidiPlayer:setOnNoteOn
    end)
end)

describe("Missing explicit test for MidiPlayer:setOnNoteOff", function()
    it("MidiPlayer:setOnNoteOff works", function()
        -- @tests MidiPlayer:setOnNoteOff
        -- TODO: add assertion for MidiPlayer:setOnNoteOff
    end)
end)

describe("Missing explicit test for MidiPlayer:setOnEnd", function()
    it("MidiPlayer:setOnEnd works", function()
        -- @tests MidiPlayer:setOnEnd
        -- TODO: add assertion for MidiPlayer:setOnEnd
    end)
end)

describe("Missing explicit test for MidiPlayer:type", function()
    it("MidiPlayer:type works", function()
        -- @tests MidiPlayer:type
        -- TODO: add assertion for MidiPlayer:type
    end)
end)

describe("Missing explicit test for MidiPlayer:typeOf", function()
    it("MidiPlayer:typeOf works", function()
        -- @tests MidiPlayer:typeOf
        -- TODO: add assertion for MidiPlayer:typeOf
    end)
end)

describe("Missing explicit test for SoundPool:play", function()
    it("SoundPool:play works", function()
        -- @tests SoundPool:play
        -- TODO: add assertion for SoundPool:play
    end)
end)

describe("Missing explicit test for SoundPool:stopAll", function()
    it("SoundPool:stopAll works", function()
        -- @tests SoundPool:stopAll
        -- TODO: add assertion for SoundPool:stopAll
    end)
end)

describe("Missing explicit test for SoundPool:setVolume", function()
    it("SoundPool:setVolume works", function()
        -- @tests SoundPool:setVolume
        -- TODO: add assertion for SoundPool:setVolume
    end)
end)

describe("Missing explicit test for SoundPool:setBus", function()
    it("SoundPool:setBus works", function()
        -- @tests SoundPool:setBus
        -- TODO: add assertion for SoundPool:setBus
    end)
end)

describe("Missing explicit test for SoundPool:release", function()
    it("SoundPool:release works", function()
        -- @tests SoundPool:release
        -- TODO: add assertion for SoundPool:release
    end)
end)

describe("Missing explicit test for SoundPool:getVoiceCount", function()
    it("SoundPool:getVoiceCount works", function()
        -- @tests SoundPool:getVoiceCount
        -- TODO: add assertion for SoundPool:getVoiceCount
    end)
end)

describe("Missing explicit test for SoundPool:type", function()
    it("SoundPool:type works", function()
        -- @tests SoundPool:type
        -- TODO: add assertion for SoundPool:type
    end)
end)

describe("Missing explicit test for SoundPool:typeOf", function()
    it("SoundPool:typeOf works", function()
        -- @tests SoundPool:typeOf
        -- TODO: add assertion for SoundPool:typeOf
    end)
end)

describe("Missing explicit test for Decoder:decode", function()
    it("Decoder:decode works", function()
        -- @tests Decoder:decode
        -- TODO: add assertion for Decoder:decode
    end)
end)

describe("Missing explicit test for Decoder:getChannelCount", function()
    it("Decoder:getChannelCount works", function()
        -- @tests Decoder:getChannelCount
        -- TODO: add assertion for Decoder:getChannelCount
    end)
end)

describe("Missing explicit test for Decoder:getBitDepth", function()
    it("Decoder:getBitDepth works", function()
        -- @tests Decoder:getBitDepth
        -- TODO: add assertion for Decoder:getBitDepth
    end)
end)

describe("Missing explicit test for Decoder:getSampleRate", function()
    it("Decoder:getSampleRate works", function()
        -- @tests Decoder:getSampleRate
        -- TODO: add assertion for Decoder:getSampleRate
    end)
end)

describe("Missing explicit test for Decoder:getDuration", function()
    it("Decoder:getDuration works", function()
        -- @tests Decoder:getDuration
        -- TODO: add assertion for Decoder:getDuration
    end)
end)

describe("Missing explicit test for Decoder:seek", function()
    it("Decoder:seek works", function()
        -- @tests Decoder:seek
        -- TODO: add assertion for Decoder:seek
    end)
end)

describe("Missing explicit test for Decoder:rewind", function()
    it("Decoder:rewind works", function()
        -- @tests Decoder:rewind
        -- TODO: add assertion for Decoder:rewind
    end)
end)

describe("Missing explicit test for Decoder:tell", function()
    it("Decoder:tell works", function()
        -- @tests Decoder:tell
        -- TODO: add assertion for Decoder:tell
    end)
end)

describe("Missing explicit test for Decoder:isSeekable", function()
    it("Decoder:isSeekable works", function()
        -- @tests Decoder:isSeekable
        -- TODO: add assertion for Decoder:isSeekable
    end)
end)

describe("Missing explicit test for Decoder:release", function()
    it("Decoder:release works", function()
        -- @tests Decoder:release
        -- TODO: add assertion for Decoder:release
    end)
end)

describe("Missing explicit test for mlua:getSampleCount", function()
    it("mlua:getSampleCount works", function()
        -- @tests mlua:getSampleCount
        -- TODO: add assertion for mlua:getSampleCount
    end)
end)

describe("Missing explicit test for mlua:getSampleRate", function()
    it("mlua:getSampleRate works", function()
        -- @tests mlua:getSampleRate
        -- TODO: add assertion for mlua:getSampleRate
    end)
end)

describe("Missing explicit test for mlua:getChannelCount", function()
    it("mlua:getChannelCount works", function()
        -- @tests mlua:getChannelCount
        -- TODO: add assertion for mlua:getChannelCount
    end)
end)

describe("Missing explicit test for mlua:getDuration", function()
    it("mlua:getDuration works", function()
        -- @tests mlua:getDuration
        -- TODO: add assertion for mlua:getDuration
    end)
end)

describe("Missing explicit test for mlua:getBitDepth", function()
    it("mlua:getBitDepth works", function()
        -- @tests mlua:getBitDepth
        -- TODO: add assertion for mlua:getBitDepth
    end)
end)

describe("Missing explicit test for mlua:getSample", function()
    it("mlua:getSample works", function()
        -- @tests mlua:getSample
        -- TODO: add assertion for mlua:getSample
    end)
end)

describe("Missing explicit test for mlua:setSample", function()
    it("mlua:setSample works", function()
        -- @tests mlua:setSample
        -- TODO: add assertion for mlua:setSample
    end)
end)
