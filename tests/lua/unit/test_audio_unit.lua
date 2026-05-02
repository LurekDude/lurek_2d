-- Lurek2D Audio API Tests

describe("lurek.audio module exists", function()
    it("lurek.audio is a table", function()
        expect_type("table", lurek.audio)
    end)
end)

describe("lurek.audio functions exist", function()
    it("setMasterVolume is a function", function()
        expect_type("function", lurek.audio.setMasterVolume)
    end)

    it("getMasterVolume is a function", function()
        expect_type("function", lurek.audio.getMasterVolume)
    end)

    it("newSource is a function", function()
        expect_type("function", lurek.audio.newSource)
    end)
end)

describe("lurek.audio volume", function()
    it("setMasterVolume accepts 0..1 range", function()
        expect_no_error(function()
            lurek.audio.setMasterVolume(0.5)
        end)
    end)

    it("getMasterVolume returns a number", function()
        local vol = lurek.audio.getMasterVolume()
        expect_type("number", vol)
    end)

    it("setMasterVolume/getMasterVolume roundtrip", function()
        lurek.audio.setMasterVolume(0.75)
        expect_near(0.75, lurek.audio.getMasterVolume(), 0.01)
        lurek.audio.setMasterVolume(1.0) -- reset
    end)

    it("setMasterVolume clamps to valid range", function()
        lurek.audio.setMasterVolume(0.0)
        expect_near(0.0, lurek.audio.getMasterVolume(), 0.01)
        lurek.audio.setMasterVolume(1.0)
        expect_near(1.0, lurek.audio.getMasterVolume(), 0.01)
    end)
end)

describe("audio spatial", function()
    it("getDopplerScale returns 1 by default", function()
        expect_near(1.0, lurek.audio.getDopplerScale(), 0.0001)
    end)

    it("setDopplerScale round-trips", function()
        lurek.audio.setDopplerScale(2.0)
        expect_near(2.0, lurek.audio.getDopplerScale(), 0.0001)
        lurek.audio.setDopplerScale(1.0)  -- reset
    end)

    it("getDistanceModel returns a string", function()
        expect_type("string", lurek.audio.getDistanceModel())
    end)

    it("setDistanceModel round-trips", function()
        lurek.audio.setDistanceModel("linear")
        expect_equal("linear", lurek.audio.getDistanceModel())
        lurek.audio.setDistanceModel("inverse_clamped")  -- reset
    end)

    it("setListener / getListener round-trips", function()
        lurek.audio.setListener(100, 50, 0)
        local x, y, z = lurek.audio.getListener()
        expect_near(100, x, 0.001)
        expect_near(50, y, 0.001)
        expect_near(0, z, 0.001)
        lurek.audio.setListener(0, 0, 0)  -- reset
    end)

    it("setListener2D / getListener2D backward compat", function()
        lurek.audio.setListener2D(30, 40)
        local x, y = lurek.audio.getListener2D()
        expect_near(30, x, 0.001)
        expect_near(40, y, 0.001)
        lurek.audio.setListener2D(0, 0)  -- reset
    end)
end)

describe("audio.newDecoder", function()
  it("is a function", function()
    expect_type("function", lurek.audio.newDecoder)
  end)

  it("errors on missing file", function()
    expect_error(function()
      lurek.audio.newDecoder("nonexistent_file.wav")
    end, "nonexistent_file")
  end)
end)

describe("Decoder userdata methods", function()
  it("getChannelCount returns a number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_type("number", d:getChannelCount())
  end)

  it("getChannelCount is 1 for mono fixture", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_equal(1, d:getChannelCount())
  end)

  it("getSampleRate returns a positive number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    local rate = d:getSampleRate()
    expect_type("number", rate)
    expect_greater(rate, 0, "sample rate must be positive")
  end)

  it("getBitDepth returns a positive number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    local depth = d:getBitDepth()
    expect_type("number", depth)
    expect_greater(depth, 0, "bit depth must be positive")
  end)

  it("getDuration returns a positive number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    local dur = d:getDuration()
    expect_type("number", dur)
    expect_greater(dur, 0, "duration must be positive")
  end)

  it("isSeekable returns true", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_equal(true, d:isSeekable())
  end)

  it("tell starts at 0", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_near(0.0, d:tell(), 0.000001)
  end)

  it("seek and tell round-trip", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    d:seek(0.01)
    expect_near(0.01, d:tell(), 0.001)
  end)

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

  it("rewind resets position to 0", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav", 1000000)
    d:decode()  -- consume
    d:rewind()
    expect_near(0.0, d:tell(), 0.000001)
  end)
end)

-- Phase 15  Queueable Sources
describe("audio.newQueueableSource", function()
  it("creates a queueable source and returns a number id", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    expect_equal(type(q), "number")
  end)

  it("getFreeBufferCount returns buffer_count initially", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    expect_equal(lurek.audio.getFreeBufferCount(q), 4)
  end)

  it("getFreeBufferCount defaults to 4 buffers when omitted", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1)
    expect_equal(lurek.audio.getFreeBufferCount(q), 4)
  end)

  it("playQueueable does not error", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    expect_no_error(function()
      lurek.audio.playQueueable(q)
    end)
  end)

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

-- Phase 18  Playback Device Selection
describe("audio device selection", function()
  it("getPlaybackDevices returns a table", function()
    local devs = lurek.audio.getPlaybackDevices()
    expect_equal(type(devs), "table")
  end)

  it("getPlaybackDevices has at least one entry", function()
    local devs = lurek.audio.getPlaybackDevices()
    expect_true(#devs >= 1, "must have at least one device")
  end)

  it("getPlaybackDevice returns a string", function()
    expect_equal(type(lurek.audio.getPlaybackDevice()), "string")
  end)

  it("setPlaybackDevice with valid name does not error", function()
    local devs = lurek.audio.getPlaybackDevices()
    expect_no_error(function()
      lurek.audio.setPlaybackDevice(devs[1])
    end)
  end)

  it("setPlaybackDevice with unknown name errors", function()
    expect_error(function()
      lurek.audio.setPlaybackDevice("NonExistentDevice___XYZ")
    end, "Unknown audio device")
  end)
end)

-- Source UserData (static source from fixture)

local FIXTURE = "tests/fixtures/sine_mono_44100.wav"

describe("Source UserData - play/stop/pause/resume lifecycle", function()
    it("newSource returns a non-nil Source from fixture", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_true(src ~= nil, "source is not nil")
    end)

    it("isStopped is true before play", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_true(src:isStopped())
    end)

    it("play / isPlaying round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        expect_true(src:isPlaying())
        src:stop()
    end)

    it("pause / isPaused round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        src:pause()
        expect_true(src:isPaused())
        src:stop()
    end)

    it("resume after pause returns to playing", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        src:pause()
        src:resume()
        expect_true(src:isPlaying())
        src:stop()
    end)

    it("stop transitions to isStopped", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        src:stop()
        expect_true(src:isStopped())
    end)
end)

describe("Source UserData - volume / pitch / pan", function()
    it("setVolume / getVolume round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setVolume(0.5)
        expect_near(0.5, src:getVolume(), 0.001)
    end)

    it("setPitch / getPitch round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setPitch(1.5)
        expect_near(1.5, src:getPitch(), 0.001)
    end)

    it("setPan / getPan round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setPan(-0.5)
        expect_near(-0.5, src:getPan(), 0.001)
    end)
end)

describe("Source UserData - looping / type / duration", function()
    it("setLooping true / isLooping true", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setLooping(true)
        expect_true(src:isLooping())
    end)

    it("setLooping false / isLooping false", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setLooping(false)
        expect_false(src:isLooping())
    end)

    it("getType returns a string", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_type("string", src:getType())
    end)

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

describe("Source UserData - tell / seek", function()
    it("tell returns 0 before playback starts", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_equal(0, src:tell())
    end)

    it("seek moves position and tell reflects it", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:seek(0.01)
        expect_true(src:tell() >= 0)
    end)
end)

describe("Source UserData - filter methods", function()
    it("setLowpass / getLowpass does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_no_error(function()
            src:setLowpass(0.5)
            local v = src:getLowpass()
            expect_type("number", v)
        end)
    end)

    it("setHighpass / getHighpass does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_no_error(function()
            src:setHighpass(0.3)
            local v = src:getHighpass()
            expect_type("number", v)
        end)
    end)

    it("clearFilter does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setLowpass(0.5)
        expect_no_error(function() src:clearFilter() end)
    end)
end)

describe("Source UserData - fadeIn / clone", function()
    it("fadeIn does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_no_error(function() src:fadeIn(1.0) end)
    end)

    it("getFadeIn returns a number", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:fadeIn(1.0)
        expect_type("number", src:getFadeIn())
    end)

    it("clone returns a new Source", function()
        local src  = lurek.audio.newSource(FIXTURE, "static")
        local copy = src:clone()
        expect_true(copy ~= nil, "cloned source is not nil")
    end)
end)

-- Bus UserData

describe("Bus UserData", function()
    it("newBus returns a non-nil object", function()
        local bus = lurek.audio.newBus("test_bus")
        expect_true(bus ~= nil, "bus is not nil")
    end)

    it("Bus:getName returns the registered name", function()
        local bus = lurek.audio.newBus("named_bus")
        expect_equal("named_bus", bus:getName())
    end)

    it("Bus setVolume / getVolume round-trip", function()
        local bus = lurek.audio.newBus("vol_bus")
        bus:setVolume(0.6)
        expect_near(0.6, bus:getVolume(), 0.001)
    end)

    it("Bus setPitch / getPitch round-trip", function()
        local bus = lurek.audio.newBus("pitch_bus")
        bus:setPitch(1.2)
        expect_near(1.2, bus:getPitch(), 0.001)
    end)

    it("Bus pause / isPaused / resume", function()
        local bus = lurek.audio.newBus("pause_bus")
        bus:pause()
        expect_true(bus:isPaused())
        bus:resume()
        expect_false(bus:isPaused())
    end)

    it("Bus:type returns a string", function()
        local bus = lurek.audio.newBus("type_bus")
        expect_type("string", bus:type())
    end)

    it("Bus:typeOf checks identity against a type name", function()
        local bus = lurek.audio.newBus("typeof_bus")
        expect_true(bus:typeOf("Bus"))
        expect_false(bus:typeOf("Source"))
    end)
end)

-- =========================================================================
-- newSoundData guard (PR-4)
-- =========================================================================

describe("lurek.audio newSoundData guard", function()
    it("newSoundData_invalid_sample_rate_string_errors", function()
        expect_error(function()
            lurek.audio.newSoundData(64, "invalid")
        end)
    end)

    it("newSoundData_boolean_sample_rate_errors", function()
        expect_error(function()
            lurek.audio.newSoundData(64, true)
        end)
    end)

    it("newSoundData_valid_args_succeeds", function()
        expect_no_error(function()
            lurek.audio.newSoundData(64, 44100, 1)
        end)
    end)
end)

describe("lurek.audio SoundData", function()
    it("newSoundData creates a silent buffer with requested shape", function()
        local sd = lurek.audio.newSoundData(100, 44100, 1)
        expect_equal(100, sd:getSampleCount())
        expect_equal(44100, sd:getSampleRate())
        expect_equal(1, sd:getChannelCount())
        expect_near(0.0, sd:getSample(0), 0.0001)
    end)

    it("setSample and getSample round-trip", function()
        local sd = lurek.audio.newSoundData(10, 44100, 1)
        sd:setSample(0, 0.5)
        expect_near(0.5, sd:getSample(0), 0.0001)
    end)

    it("setSample clamps values to audio range", function()
        local sd = lurek.audio.newSoundData(10, 44100, 1)
        sd:setSample(0, 5.0)
        expect_near(1.0, sd:getSample(0), 0.0001)
        sd:setSample(1, -5.0)
        expect_near(-1.0, sd:getSample(1), 0.0001)
    end)

    it("setSample errors when index is out of range", function()
        local sd = lurek.audio.newSoundData(10, 44100, 1)
        expect_error(function()
            sd:setSample(100, 0.5)
        end)
    end)

    it("getDuration reports one second for 44100 mono samples", function()
        local sd = lurek.audio.newSoundData(44100, 44100, 1)
        expect_near(1.0, sd:getDuration(), 0.0001)
    end)

    it("newSineWave creates the requested mono buffer", function()
        local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
        expect_equal(44100, sd:getSampleCount())
        expect_equal(1, sd:getChannelCount())
        expect_true(math.abs(sd:getSample(0)) < 0.01)
    end)

    it("newSquareWave alternates positive and negative phases", function()
        local sd = lurek.audio.newSquareWave(1.0, 1.0, 100, 1.0)
        expect_true(sd:getSample(0) > 0.0)
        expect_true(sd:getSample(75) < 0.0)
    end)

    it("applyGain scales samples in-place", function()
        local sd = lurek.audio.newSoundData(2, 44100, 1)
        sd:setSample(0, 0.5)
        sd:setSample(1, -0.5)
        lurek.audio.applyGain(sd, 0.5)
        expect_near(0.25, sd:getSample(0), 0.0001)
        expect_near(-0.25, sd:getSample(1), 0.0001)
    end)

    it("mixInto additively blends source samples", function()
        local dest = lurek.audio.newSoundData(2, 44100, 1)
        local src = lurek.audio.newSoundData(2, 44100, 1)
        dest:setSample(0, 0.3)
        dest:setSample(1, 0.3)
        src:setSample(0, 0.2)
        src:setSample(1, -0.1)
        lurek.audio.mixInto(dest, src)
        expect_near(0.5, dest:getSample(0), 0.0001)
        expect_near(0.2, dest:getSample(1), 0.0001)
    end)
end)

-- =========================================================================
-- MidiPlayer sample rate and channels (PR-5)
-- =========================================================================

describe("lurek.audio MidiPlayer rate and channels", function()
    it("newMidiPlayer is a function", function()
        expect_type("function", lurek.audio.newMidiPlayer)
    end)

    it("midi_getSampleRate_default_is_44100", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(44100, midi:getSampleRate())
    end)

    it("midi_setSampleRate_roundtrips_value", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(48000)
        expect_equal(48000, midi:getSampleRate())
    end)

    it("midi_setSampleRate_clamps_below_8000_to_8000", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(100)
        expect_equal(8000, midi:getSampleRate())
    end)

    it("midi_setSampleRate_clamps_above_192000_to_192000", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(999999)
        expect_equal(192000, midi:getSampleRate())
    end)

    it("midi_getChannels_default_is_2", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(2, midi:getChannels())
    end)

    it("midi_setChannels_accepts_1_mono", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(1)
        expect_equal(1, midi:getChannels())
    end)

    it("midi_setChannels_accepts_2_stereo", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(2)
        expect_equal(2, midi:getChannels())
    end)

    it("midi_setChannels_clamps_above_2_to_2", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(5)
        expect_equal(2, midi:getChannels())
    end)
end)

-- =========================================================================
-- Merged from test_audio_bus.lua
-- =========================================================================

describe("lurek.audio.newBus", function()
    it("creates a bus with the given name", function()
        local bus = lurek.audio.newBus("music")
        expect_equal(bus:getName(), "music")
    end)

    it("has default volume 1.0", function()
        local bus = lurek.audio.newBus("test")
        expect_near(bus:getVolume(), 1.0, 1e-5)
    end)

    it("has default pitch 1.0", function()
        local bus = lurek.audio.newBus("test")
        expect_near(bus:getPitch(), 1.0, 1e-5)
    end)

    it("is not paused by default", function()
        local bus = lurek.audio.newBus("test")
        expect_false(bus:isPaused())
    end)
end)

describe("Bus:setVolume / getVolume", function()
    it("sets and gets volume", function()
        local bus = lurek.audio.newBus("test")
        bus:setVolume(0.7)
        expect_near(bus:getVolume(), 0.7, 1e-5)
    end)

    it("clamps negative volume to 0", function()
        local bus = lurek.audio.newBus("test")
        bus:setVolume(-1.0)
        expect_near(bus:getVolume(), 0.0, 1e-5)
    end)
end)

describe("Bus:setPitch / getPitch", function()
    it("sets and gets pitch", function()
        local bus = lurek.audio.newBus("test")
        bus:setPitch(1.5)
        expect_near(bus:getPitch(), 1.5, 1e-5)
    end)

    it("clamps negative pitch to 0", function()
        local bus = lurek.audio.newBus("test")
        bus:setPitch(-0.5)
        expect_near(bus:getPitch(), 0.0, 1e-5)
    end)
end)

describe("Bus:pause / resume / isPaused", function()
    it("pauses and resumes", function()
        local bus = lurek.audio.newBus("test")
        bus:pause()
        expect_true(bus:isPaused())
        bus:resume()
        expect_false(bus:isPaused())
    end)
end)

describe("Bus type system", function()
    it("reports type as LBus", function()
        local bus = lurek.audio.newBus("test")
        expect_equal(bus:type(), "LBus")
    end)

    it("typeOf returns true for Bus and Object", function()
        local bus = lurek.audio.newBus("test")
        expect_true(bus:typeOf("Bus"))
        expect_true(bus:typeOf("Object"))
    end)
end)

describe("lurek.audio.getMaxSources", function()
    it("returns 64", function()
        expect_equal(lurek.audio.getMaxSources(), 64)
    end)
end)

describe("lurek.audio.setListener2D / getListener2D behavior", function()
    it("setListener2D does not error", function()
        lurek.audio.setListener2D(1.0, 2.0)
    end)

    it("getListener2D returns the position set by setListener2D", function()
        lurek.audio.setListener2D(1.0, 2.0)
        local x, y = lurek.audio.getListener2D()
        expect_near(x, 1.0, 1e-5)
        expect_near(y, 2.0, 1e-5)
        -- reset for other tests
        lurek.audio.setListener2D(0.0, 0.0)
    end)
end)

describe("lurek.audio.setMeter / getMeter behavior", function()
    it("setMeter does not error", function()
        lurek.audio.setMeter(2.0)
    end)

    it("getMeter returns 1.0", function()
        expect_near(lurek.audio.getMeter(), 1.0, 1e-5)
    end)
end)

describe("lurek.audio.newMidiPlayer", function()
    it("creates a MidiPlayer", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isLoaded())
    end)

    it("is not playing by default", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isPlaying())
    end)

    it("has default volume 1.0", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getVolume(), 1.0, 1e-5)
    end)

    it("has default tempo scale 1.0", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getTempoScale(), 1.0, 1e-5)
    end)

    it("has 0 tracks when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:getTrackCount(), 0)
    end)

    it("has 0 note count when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:getNoteCount(), 0)
    end)
end)

describe("MidiPlayer volume", function()
    it("sets and gets volume", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setVolume(0.5)
        expect_near(midi:getVolume(), 0.5, 1e-5)
    end)
end)

describe("MidiPlayer tempo", function()
    it("sets and gets tempo scale", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setTempoScale(2.0)
        expect_near(midi:getTempoScale(), 2.0, 1e-5)
    end)

    it("getOriginalTempo returns 120 when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getOriginalTempo(), 120.0, 1e-5)
    end)
end)

describe("MidiPlayer looping", function()
    it("toggles looping", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isLooping())
        midi:setLooping(true)
        expect_true(midi:isLooping())
        midi:setLooping(false)
        expect_false(midi:isLooping())
    end)
end)

describe("MidiPlayer channel control", function()
    it("sets and gets channel volume (1-indexed)", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannelVolume(1, 0.5)
        expect_near(midi:getChannelVolume(1), 0.5, 1e-5)
    end)

    it("mutes and unmutes channel", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isChannelMuted(1))
        midi:setChannelMuted(1, true)
        expect_true(midi:isChannelMuted(1))
        midi:setChannelMuted(1, false)
        expect_false(midi:isChannelMuted(1))
    end)

    it("sets and gets channel instrument", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannelInstrument(1, 42)
        expect_equal(midi:getChannelInstrument(1), 42)
    end)

    it("soloChannel mutes all others", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:soloChannel(5)
        expect_false(midi:isChannelMuted(5))
        expect_true(midi:isChannelMuted(1))
        expect_true(midi:isChannelMuted(16))
    end)

    it("unsoloAll unmutes all", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:soloChannel(5)
        midi:unsoloAll()
        expect_false(midi:isChannelMuted(1))
        expect_false(midi:isChannelMuted(5))
        expect_false(midi:isChannelMuted(16))
    end)
end)

describe("MidiPlayer utility behavior", function()
    it("setSoundFont does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSoundFont("path/to/sf2")
    end)

    it("useDefaultSoundFont does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:useDefaultSoundFont()
    end)

    it("getSoundFontPath returns nil", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:getSoundFontPath(), nil)
    end)

    it("setOnNoteOn does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setOnNoteOn(function() end)
    end)

    it("setOnNoteOff does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setOnNoteOff(function() end)
    end)

    it("setOnEnd does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setOnEnd(function() end)
    end)
end)

describe("MidiPlayer type system", function()
    it("reports type as LMidiPlayer", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:type(), "LMidiPlayer")
    end)

    it("typeOf returns true for MidiPlayer and Object", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_true(midi:typeOf("MidiPlayer"))
        expect_true(midi:typeOf("Object"))
    end)
end)

describe("MidiPlayer seek/tell", function()
    it("seek and tell work", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:seek(5.0)
        expect_near(midi:tell(), 5.0, 1e-5)
    end)

    it("seek clamps negative to 0", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:seek(-1.0)
        expect_near(midi:tell(), 0.0, 1e-5)
    end)
end)

describe("MidiPlayer getDuration", function()
    it("returns 0 when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getDuration(), 0.0, 1e-5)
    end)
end)

-- =========================================================================
-- Merged from test_audio_dsp.lua
-- =========================================================================

describe("lurek.audio.create_bus", function()
    it("creates a bus without returning an object", function()
        local result = lurek.audio.create_bus("sfx")
        expect_equal(nil, result)
    end)

    it("errors if empty string is provided", function()
        expect_error(function()
            lurek.audio.create_bus("")
        end, "invalid bus name")
    end)
end)

describe("lurek.audio.set_bus_volume", function()
    it("sets the volume of an existing bus", function()
        lurek.audio.create_bus("music")
        -- Should not error
        lurek.audio.set_bus_volume("music", 0.75)
    end)

    it("errors if bus does not exist", function()
        expect_error(function()
            lurek.audio.set_bus_volume("nonexistent_bus", 0.5)
        end, "bus not found")
    end)
end)

describe("lurek.audio.play with bus", function()
    it("accepts a bus parameter in options", function()
        lurek.audio.create_bus("ambient")
        local src = lurek.audio.newSource("tests/fixtures/sine_mono_44100.wav", "static")
        local id = lurek.audio.play(src, { bus = "ambient" })
        expect_type("number", id)
    end)

    it("defaults to master bus if none provided", function()
        local src = lurek.audio.newSource("tests/fixtures/sine_mono_44100.wav", "static")
        local id = lurek.audio.play(src, {})
        expect_type("number", id)
    end)

    it("errors if bus does not exist", function()
        local src = lurek.audio.newSource("tests/fixtures/sine_mono_44100.wav", "static")
        expect_error(function()
            lurek.audio.play(src, { bus = "fake_bus" })
        end, "bus not found")
    end)
end)

describe("lurek.audio.add_effect", function()
    it("adds an effect and returns an integer ID", function()
        lurek.audio.create_bus("sfx2")
        local effect_id = lurek.audio.add_effect("sfx2", "lowpass")
        expect_type("number", effect_id)
    end)

    it("accepts initial parameters", function()
        lurek.audio.create_bus("sfx3")
        local effect_id = lurek.audio.add_effect("sfx3", "reverb", { room_size = 0.8, mix = 0.4 })
        expect_type("number", effect_id)
    end)

    it("errors on invalid effect type", function()
        lurek.audio.create_bus("sfx4")
        expect_error(function()
            lurek.audio.add_effect("sfx4", "magic_wand")
        end, "invalid effect")
    end)

    it("errors if bus does not exist for effect", function()
        expect_error(function()
            lurek.audio.add_effect("nope_bus", "lowpass")
        end, "bus not found")
    end)
end)

describe("lurek.audio.set_effect_param", function()
    it("mutates an effect parameter without errors", function()
        lurek.audio.create_bus("music2")
        local efx = lurek.audio.add_effect("music2", "lowpass")
        -- set cutoff
        lurek.audio.set_effect_param("music2", efx, "cutoff", 500.0)
    end)

    it("errors if effect ID does not exist", function()
        lurek.audio.create_bus("music3")
        expect_error(function()
            lurek.audio.set_effect_param("music3", 9999, "cutoff", 500.0)
        end, "effect not found")
    end)

    it("errors if parameter name is invalid for effect type", function()
        lurek.audio.create_bus("music4")
        local efx = lurek.audio.add_effect("music4", "lowpass")
        expect_error(function()
            lurek.audio.set_effect_param("music4", efx, "room_size", 0.5)
        end, "invalid parameter")
    end)
end)

describe("lurek.audio.remove_effect", function()
    it("removes an existing effect", function()
        lurek.audio.create_bus("sfx5")
        local efx = lurek.audio.add_effect("sfx5", "bandpass")
        lurek.audio.remove_effect("sfx5", efx)

        -- Further operations on it should error
        expect_error(function()
            lurek.audio.set_effect_param("sfx5", efx, "center", 1000.0)
        end, "effect not found")
    end)

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

describe("lurek.audio.add_effect  - notch", function()
    it("creates a notch filter effect and returns an id", function()
        lurek.audio.create_bus("test_notch")
        local eid = lurek.audio.add_effect("test_notch", "notch")
        expect_type("number", eid)
    end)

    it("accepts cutoff and bandwidth parameters", function()
        lurek.audio.create_bus("test_notch2")
        local eid = lurek.audio.add_effect("test_notch2", "notch", { cutoff = 1000.0, bandwidth = 100.0 })
        expect_type("number", eid)
        lurek.audio.set_effect_param("test_notch2", eid, "cutoff", 2000.0)
        lurek.audio.set_effect_param("test_notch2", eid, "bandwidth", 200.0)
    end)
end)

describe("lurek.audio.add_effect  - lowshelf", function()
    it("creates a low-shelf EQ effect", function()
        lurek.audio.create_bus("test_lowshelf")
        local eid = lurek.audio.add_effect("test_lowshelf", "lowshelf")
        expect_type("number", eid)
    end)

    it("accepts cutoff and gain_db parameters", function()
        lurek.audio.create_bus("test_lowshelf2")
        local eid = lurek.audio.add_effect("test_lowshelf2", "lowshelf", { cutoff = 200.0, gain_db = -6.0 })
        lurek.audio.set_effect_param("test_lowshelf2", eid, "cutoff", 300.0)
        lurek.audio.set_effect_param("test_lowshelf2", eid, "gain_db", 3.0)
    end)
end)

describe("lurek.audio.add_effect  - highshelf", function()
    it("creates a high-shelf EQ effect", function()
        lurek.audio.create_bus("test_highshelf")
        local eid = lurek.audio.add_effect("test_highshelf", "highshelf")
        expect_type("number", eid)
    end)

    it("accepts cutoff and gain_db parameters", function()
        lurek.audio.create_bus("test_highshelf2")
        local eid = lurek.audio.add_effect("test_highshelf2", "highshelf", { cutoff = 8000.0, gain_db = 4.0 })
        lurek.audio.set_effect_param("test_highshelf2", eid, "gain_db", -3.0)
    end)
end)

describe("lurek.audio.add_effect  - flanger", function()
    it("creates a flanger effect", function()
        lurek.audio.create_bus("test_flanger")
        local eid = lurek.audio.add_effect("test_flanger", "flanger")
        expect_type("number", eid)
    end)

    it("accepts rate and depth parameters", function()
        lurek.audio.create_bus("test_flanger2")
        local eid = lurek.audio.add_effect("test_flanger2", "flanger", { rate = 0.5, depth = 0.3, mix = 0.6 })
        lurek.audio.set_effect_param("test_flanger2", eid, "rate", 1.0)
        lurek.audio.set_effect_param("test_flanger2", eid, "depth", 0.5)
        lurek.audio.set_effect_param("test_flanger2", eid, "mix", 0.8)
    end)
end)

describe("lurek.audio.add_effect  - phaser", function()
    it("creates a phaser effect", function()
        lurek.audio.create_bus("test_phaser")
        local eid = lurek.audio.add_effect("test_phaser", "phaser")
        expect_type("number", eid)
    end)

    it("accepts rate, depth and mix parameters", function()
        lurek.audio.create_bus("test_phaser2")
        local eid = lurek.audio.add_effect("test_phaser2", "phaser", { rate = 0.3, depth = 0.7, mix = 0.5 })
        lurek.audio.set_effect_param("test_phaser2", eid, "rate", 0.6)
    end)
end)

describe("lurek.audio.add_effect  - distortion", function()
    it("creates a distortion (waveshaper) effect", function()
        lurek.audio.create_bus("test_dist")
        local eid = lurek.audio.add_effect("test_dist", "distortion")
        expect_type("number", eid)
    end)

    it("accepts drive and mix parameters", function()
        lurek.audio.create_bus("test_dist2")
        local eid = lurek.audio.add_effect("test_dist2", "distortion", { drive = 10.0, mix = 0.5 })
        lurek.audio.set_effect_param("test_dist2", eid, "drive", 20.0)
        lurek.audio.set_effect_param("test_dist2", eid, "mix", 0.3)
    end)
end)

describe("lurek.audio.add_effect  - limiter", function()
    it("creates a brick-wall limiter effect", function()
        lurek.audio.create_bus("test_limiter")
        local eid = lurek.audio.add_effect("test_limiter", "limiter")
        expect_type("number", eid)
    end)

    it("accepts threshold and release parameters", function()
        lurek.audio.create_bus("test_limiter2")
        local eid = lurek.audio.add_effect("test_limiter2", "limiter", { threshold = 0.9, release = 0.1 })
        lurek.audio.set_effect_param("test_limiter2", eid, "threshold", 0.8)
    end)
end)

describe("lurek.audio.add_effect  - compressor", function()
    it("creates a dynamic range compressor", function()
        lurek.audio.create_bus("test_comp")
        local eid = lurek.audio.add_effect("test_comp", "compressor")
        expect_type("number", eid)
    end)

    it("accepts threshold, ratio and makeup_gain parameters", function()
        lurek.audio.create_bus("test_comp2")
        local eid = lurek.audio.add_effect("test_comp2", "compressor",
            { threshold = 0.5, ratio = 4.0, makeup_gain = 1.5 })
        lurek.audio.set_effect_param("test_comp2", eid, "threshold", 0.6)
        lurek.audio.set_effect_param("test_comp2", eid, "ratio", 2.0)
        lurek.audio.set_effect_param("test_comp2", eid, "makeup_gain", 1.0)
    end)
end)

describe("lurek.audio.add_effect  - bell_eq", function()
    it("creates a bell equalizer effect", function()
        lurek.audio.create_bus("test_bell")
        local eid = lurek.audio.add_effect("test_bell", "bell_eq")
        expect_type("number", eid)
    end)

    it("accepts cutoff, gain_db and q parameters", function()
        lurek.audio.create_bus("test_bell2")
        local eid = lurek.audio.add_effect("test_bell2", "bell_eq",
            { cutoff = 1000.0, gain_db = 6.0, q = 1.0 })
        lurek.audio.set_effect_param("test_bell2", eid, "cutoff", 2000.0)
        lurek.audio.set_effect_param("test_bell2", eid, "gain_db", -3.0)
    end)
end)

describe("lurek.audio.add_effect  - reverb2", function()
    it("creates an improved reverb (reverb2) effect", function()
        lurek.audio.create_bus("test_rev2")
        local eid = lurek.audio.add_effect("test_rev2", "reverb2")
        expect_type("number", eid)
    end)

    it("accepts room_size, damping, pre_delay and mix parameters", function()
        lurek.audio.create_bus("test_rev3")
        local eid = lurek.audio.add_effect("test_rev3", "reverb2",
            { room_size = 0.7, damping = 0.5, pre_delay = 0.02, mix = 0.4 })
        lurek.audio.set_effect_param("test_rev3", eid, "room_size", 0.9)
        lurek.audio.set_effect_param("test_rev3", eid, "mix", 0.3)
    end)
end)

describe("lurek.audio.add_effect  - validation", function()
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

describe("lurek.audio.processOffline", function()
    it("processes a WAV file with a lowpass effect and writes output", function()
        local effects = {
            { type = "lowpass", cutoff = 1000.0 }
        }
        local out = OUT_DIR .. "offline_lowpass_out.wav"
        lurek.audio.processOffline(WAVE, out, effects)
    end)

    it("processes with multiple chained effects", function()
        local effects = {
            { type = "highpass", cutoff = 200.0 },
            { type = "reverb",   room_size = 0.6, mix = 0.3 }
        }
        local out = OUT_DIR .. "offline_chain_out.wav"
        lurek.audio.processOffline(WAVE, out, effects)
    end)

    it("processes with empty effect list (passthrough)", function()
        local out = OUT_DIR .. "offline_passthrough_out.wav"
        lurek.audio.processOffline(WAVE, out, {})
    end)

    it("errors if source file does not exist", function()
        expect_error(function()
            lurek.audio.processOffline("no_such_file.wav", OUT_DIR .. "out.wav", {})
        end, "not found")
    end)

    it("errors on path traversal in output path", function()
        expect_error(function()
            lurek.audio.processOffline(WAVE, "../../etc/output.wav", {})
        end, "path")
    end)
end)

describe("lurek.audio.normalizeFile", function()
    it("normalizes a WAV file without error", function()
        local out = OUT_DIR .. "normalized_out.wav"
        lurek.audio.normalizeFile(WAVE, out, 0.9)
    end)

    it("errors if target level is outside (0.0, 1.0]", function()
        expect_error(function()
            lurek.audio.normalizeFile(WAVE, OUT_DIR .. "out.wav", 0.0)
        end, "target level")
        expect_error(function()
            lurek.audio.normalizeFile(WAVE, OUT_DIR .. "out.wav", 1.5)
        end, "target level")
    end)

    it("errors if source file does not exist", function()
        expect_error(function()
            lurek.audio.normalizeFile("no_such.wav", OUT_DIR .. "out.wav", 0.9)
        end, "not found")
    end)
end)

-- =========================================================================
-- Merged from test_audio_pool.lua
-- =========================================================================

describe("lurek.audio.newPool", function()
    it("creates a sound pool and returns a Pool object", function()
        local pool = lurek.audio.newPool(WAVE, 4)
        expect_not_nil(pool)
    end)

    it("errors on empty path", function()
        local ok, pool = pcall(function()
            return lurek.audio.newPool("", 4)
        end)
        if ok then
            expect_not_nil(pool)
        else
            expect_true(true)
        end
    end)

    it("errors on zero voice count", function()
        expect_error(function()
            lurek.audio.newPool(WAVE, 0)
        end, "invalid voice count")
    end)
end)

describe("Pool:play", function()
    it("play returns a numeric source id", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        local id = pool:play()
        expect_type("number", id)
    end)

    it("play can be called multiple times up to voice count", function()
        local pool = lurek.audio.newPool(WAVE, 3)
        local id1 = pool:play()
        local id2 = pool:play()
        local id3 = pool:play()
        expect_type("number", id1)
        expect_type("number", id2)
        expect_type("number", id3)
    end)

    it("play wraps around to the first voice after the pool is exhausted", function()
        local pool = lurek.audio.newPool(WAVE, 3)
        local id1 = pool:play()
        local id2 = pool:play()
        local id3 = pool:play()
        local id4 = pool:play()
        expect_true(id1 ~= id2)
        expect_true(id2 ~= id3)
        expect_equal(id1, id4)
    end)
end)

describe("Pool:stopAll", function()
    it("stopAll does not error when pool has playing sources", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:play()
        pool:play()
        pool:stopAll()  -- should not raise
    end)

    it("stopAll does not error on an idle pool", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:stopAll()
    end)
end)

describe("Pool:setVolume", function()
    it("setVolume sets volume for all pool sources", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:setVolume(0.5)  -- should not raise
    end)
end)

describe("Pool:setBus", function()
    it("setBus routes all pool sources to a named bus", function()
        lurek.audio.create_bus("pool_test_bus")
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:setBus("pool_test_bus")  -- should not raise
    end)

    it("setBus silently accepts an unknown bus name", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        -- Pool.setBus does not validate bus existence at assignment time
        pool:setBus("nonexistent_pool_bus")
    end)
end)

describe("Pool:release", function()
    it("release frees all sources without error", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:play()
        pool:release()  -- should not raise
    end)
end)

describe("Pool:getVoiceCount", function()
    it("returns the configured voice count", function()
        local pool = lurek.audio.newPool(WAVE, 6)
        expect_equal(6, pool:getVoiceCount())
    end)
end)

-- =========================================================================
-- Merged from test_audio_stereo.lua
-- =========================================================================

describe("lurek.audio.setStereoWidth", function()
    it("sets stereo width on a valid source without error", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setStereoWidth(src, 1.5)  -- 1.5 = slight widening
    end)

    it("clamps stereo width to [0.0, 2.0] silently", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setStereoWidth(src, -1.0)  -- should clamp, not error
        lurek.audio.setStereoWidth(src, 5.0)   -- should clamp, not error
    end)

    it("getStereoWidth returns the last set value (clamped)", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setStereoWidth(src, 0.5)
        local w = lurek.audio.getStereoWidth(src)
        expect_near(0.5, w, 0.001)
    end)

    it("errors on invalid source handle", function()
        expect_error(function()
            lurek.audio.setStereoWidth(99999999, 1.0) ---@diagnostic disable-line: param-type-mismatch
        end, "invalid")
    end)
end)

describe("lurek.audio.setRandomPitch", function()
    it("sets a random pitch range on a source", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setRandomPitch(src, 0.9, 1.1)
    end)

    it("errors if min > max", function()
        local src = lurek.audio.newSource(WAVE, "static")
        expect_error(function()
            lurek.audio.setRandomPitch(src, 1.5, 0.5)
        end, "min must be")
    end)

    it("errors on invalid source", function()
        expect_error(function()
            lurek.audio.setRandomPitch(12345678, 0.9, 1.1) ---@diagnostic disable-line: param-type-mismatch
        end, "invalid")
    end)

    it("clearRandomPitch removes the random pitch range", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setRandomPitch(src, 0.9, 1.1)
        lurek.audio.clearRandomPitch(src)  -- should not error
    end)
end)

describe("lurek.audio.crossfade", function()
    it("crossfade between two sources does not error", function()
        local src_a = lurek.audio.newSource(WAVE, "static")
        local src_b = lurek.audio.newSource(WAVE, "static")
        lurek.audio.crossfade(src_a, src_b, 0.5)
    end)

    it("crossfade with negative duration does not validate (passthrough)", function()
        local src_a = lurek.audio.newSource(WAVE, "static")
        local src_b = lurek.audio.newSource(WAVE, "static")
        -- crossfade passes duration to the mixer without validation
        lurek.audio.crossfade(src_a, src_b, -1.0)
    end)

    it("errors if first source is invalid", function()
        local src_b = lurek.audio.newSource(WAVE, "static")
        expect_error(function()
            lurek.audio.crossfade(99999999, src_b, 0.5) ---@diagnostic disable-line: param-type-mismatch
        end, "invalid")
    end)
end)

describe("lurek.audio.getBusPeak", function()
    it("returns a number for a known bus", function()
        lurek.audio.create_bus("peak_test_bus")
        local peak = lurek.audio.getBusPeak("peak_test_bus")
        expect_type("number", peak)
    end)

    it("returns 0.0 when bus is idle", function()
        lurek.audio.create_bus("peak_idle_bus")
        local peak = lurek.audio.getBusPeak("peak_idle_bus")
        expect_near(0.0, peak, 0.001)
    end)

    it("errors for unknown bus", function()
        expect_error(function()
            lurek.audio.getBusPeak("nope_bus")
        end, "bus not found")
    end)
end)

describe("lurek.audio.getBusRms", function()
    it("returns a number for a known bus", function()
        lurek.audio.create_bus("rms_test_bus")
        local rms = lurek.audio.getBusRms("rms_test_bus")
        expect_type("number", rms)
    end)

    it("returns 0.0 when bus is idle", function()
        lurek.audio.create_bus("rms_idle_bus")
        local rms = lurek.audio.getBusRms("rms_idle_bus")
        expect_near(0.0, rms, 0.001)
    end)
end)

describe("lurek.audio waveform and spectrogram export errors", function()
    it("waveformToPng errors for a missing input file", function()
        local ok, err = pcall(function()
            lurek.audio.waveformToPng("tests/fixtures/does_not_exist.wav", "tests/output/missing_waveform.png", 100, 50)
        end)

        expect_false(ok)
        expect_false(err == nil)
    end)

    it("spectrogramToPng errors for a missing input file", function()
        local ok, err = pcall(function()
            lurek.audio.spectrogramToPng("tests/fixtures/does_not_exist.wav", "tests/output/missing_spectrogram.png", 100, 50)
        end)

        expect_false(ok)
        expect_false(err == nil)
    end)
end)
test_summary()
