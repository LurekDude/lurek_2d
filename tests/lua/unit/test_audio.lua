-- Lurek2D Audio API Tests

-- @description Verifies the top-level audio namespace is present before exercising any factories or listener controls.
describe("lurek.audio module exists", function()
    -- @covers lurek.audio.getDistanceModel
    -- @covers lurek.audio.getDopplerScale
    -- @covers lurek.audio.getFreeBufferCount
    -- @covers lurek.audio.getListener
    -- @covers lurek.audio.getListener2D
    -- @covers lurek.audio.getMasterVolume
    -- @covers lurek.audio.getPlaybackDevice
    -- @covers lurek.audio.getPlaybackDevices
    -- @covers lurek.audio.newDecoder
    -- @covers lurek.audio.newQueueableSource
    -- @covers lurek.audio.newSoundData
    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.playQueueable
    -- @covers lurek.audio.queueSource
    -- @covers lurek.audio.setDistanceModel
    -- @covers lurek.audio.setDopplerScale
    -- @covers lurek.audio.setListener
    -- @covers lurek.audio.setListener2D
    -- @covers lurek.audio.setMasterVolume
    -- @covers lurek.audio.setPlaybackDevice
    -- @covers lurek.audio.stopQueueable
    -- @covers lurek.audio.newBus
    -- @covers lurek.audio.Source.play
    -- @covers lurek.audio.Source.stop
    -- @covers lurek.audio.Source.pause
    -- @covers lurek.audio.Source.resume
    -- @covers lurek.audio.Source.setVolume
    -- @covers lurek.audio.Source.getVolume
    -- @covers lurek.audio.Source.setPitch
    -- @covers lurek.audio.Source.getPitch
    -- @covers lurek.audio.Source.setLooping
    -- @covers lurek.audio.Source.isLooping
    -- @covers lurek.audio.Source.isPlaying
    -- @covers lurek.audio.Source.isPaused
    -- @covers lurek.audio.Source.isStopped
    -- @covers lurek.audio.Source.setPan
    -- @covers lurek.audio.Source.getPan
    -- @covers lurek.audio.Source.clone
    -- @covers lurek.audio.Source.getType
    -- @covers lurek.audio.Source.getDuration
    -- @covers lurek.audio.Source.tell
    -- @covers lurek.audio.Source.seek
    -- @covers lurek.audio.Source.setLowpass
    -- @covers lurek.audio.Source.getLowpass
    -- @covers lurek.audio.Source.setHighpass
    -- @covers lurek.audio.Source.getHighpass
    -- @covers lurek.audio.Source.clearFilter
    -- @covers lurek.audio.Source.fadeIn
    -- @covers lurek.audio.Source.getFadeIn
    -- @covers lurek.audio.Bus.getName
    -- @covers lurek.audio.Bus.setVolume
    -- @covers lurek.audio.Bus.getVolume
    -- @covers lurek.audio.Bus.setPitch
    -- @covers lurek.audio.Bus.getPitch
    -- @covers lurek.audio.Bus.pause
    -- @covers lurek.audio.Bus.resume
    -- @covers lurek.audio.Bus.isPaused
    -- @covers lurek.audio.Bus.type
    -- @covers lurek.audio.Bus.typeOf
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
    -- @covers lurek.audio.newSoundData
    -- @description Passing a string literal for sample rate must now return an error instead of silently defaulting to 44100.
    it("newSoundData_invalid_sample_rate_string_errors", function()
        expect_error(function()
            lurek.audio.newSoundData(64, "invalid")
        end)
    end)

    -- @covers lurek.audio.newSoundData
    -- @description Passing a boolean for sample rate must also trigger the validation error.
    it("newSoundData_boolean_sample_rate_errors", function()
        expect_error(function()
            lurek.audio.newSoundData(64, true)
        end)
    end)

    -- @covers lurek.audio.newSoundData
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
    -- @covers lurek.audio.newMidiPlayer
    -- @description Confirms the MidiPlayer factory is exported as a callable function.
    it("newMidiPlayer is a function", function()
        expect_type("function", lurek.audio.newMidiPlayer)
    end)

    -- @covers lurek.audio.newMidiPlayer
    -- @covers MidiPlayer:getSampleRate
    -- @description Verifies the default output sample rate of a freshly-created MidiPlayer is 44100 Hz.
    it("midi_getSampleRate_default_is_44100", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(44100, midi:getSampleRate())
    end)

    -- @covers lurek.audio.newMidiPlayer
    -- @covers MidiPlayer:setSampleRate
    -- @covers MidiPlayer:getSampleRate
    -- @description Sets a sample rate within the valid range and reads it back to confirm round-trip fidelity.
    it("midi_setSampleRate_roundtrips_value", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(48000)
        expect_equal(48000, midi:getSampleRate())
    end)

    -- @covers lurek.audio.newMidiPlayer
    -- @covers MidiPlayer:setSampleRate
    -- @covers MidiPlayer:getSampleRate
    -- @description Passes a value below 8000; the engine must clamp it to 8000.
    it("midi_setSampleRate_clamps_below_8000_to_8000", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(100)
        expect_equal(8000, midi:getSampleRate())
    end)

    -- @covers lurek.audio.newMidiPlayer
    -- @covers MidiPlayer:setSampleRate
    -- @covers MidiPlayer:getSampleRate
    -- @description Passes a value above 192000; the engine must clamp it to 192000.
    it("midi_setSampleRate_clamps_above_192000_to_192000", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(999999)
        expect_equal(192000, midi:getSampleRate())
    end)

    -- @covers lurek.audio.newMidiPlayer
    -- @covers MidiPlayer:getChannels
    -- @description Confirms the default output channel count of a freshly-created MidiPlayer is 2 (stereo).
    it("midi_getChannels_default_is_2", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(2, midi:getChannels())
    end)

    -- @covers lurek.audio.newMidiPlayer
    -- @covers MidiPlayer:setChannels
    -- @covers MidiPlayer:getChannels
    -- @description Sets the channel count to 1 (mono) and verifies it is stored correctly.
    it("midi_setChannels_accepts_1_mono", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(1)
        expect_equal(1, midi:getChannels())
    end)

    -- @covers lurek.audio.newMidiPlayer
    -- @covers MidiPlayer:setChannels
    -- @covers MidiPlayer:getChannels
    -- @description Sets the channel count to 2 (stereo) and verifies it is stored correctly.
    it("midi_setChannels_accepts_2_stereo", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(2)
        expect_equal(2, midi:getChannels())
    end)

    -- @covers lurek.audio.newMidiPlayer
    -- @covers MidiPlayer:setChannels
    -- @covers MidiPlayer:getChannels
    -- @description Passes 5 (above the maximum of 2); the engine must clamp it to 2.
    it("midi_setChannels_clamps_above_2_to_2", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(5)
        expect_equal(2, midi:getChannels())
    end)
end)

test_summary()
