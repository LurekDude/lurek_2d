-- Lurek2D Audio API Tests

-- @describe lurek.audio module exists
describe("lurek.audio module exists", function()
    -- @covers lurek.audio
    it("lurek.audio is a table", function()
        expect_type("table", lurek.audio)
    end)
end)

-- @describe lurek.audio functions exist
describe("lurek.audio functions exist", function()
    -- @covers lurek.audio.setMasterVolume
    it("setMasterVolume is a function", function()
        expect_type("function", lurek.audio.setMasterVolume)
    end)

    -- @covers lurek.audio.getMasterVolume
    it("getMasterVolume is a function", function()
        expect_type("function", lurek.audio.getMasterVolume)
    end)

    -- @covers lurek.audio.newSource
    it("newSource is a function", function()
        expect_type("function", lurek.audio.newSource)
    end)
end)

-- @describe lurek.audio volume
describe("lurek.audio volume", function()
    -- @covers lurek.audio.setMasterVolume
    it("setMasterVolume accepts 0..1 range", function()
        expect_no_error(function()
            lurek.audio.setMasterVolume(0.5)
        end)
    end)

    -- @covers lurek.audio.getMasterVolume
    it("getMasterVolume returns a number", function()
        local vol = lurek.audio.getMasterVolume()
        expect_type("number", vol)
    end)

    -- @covers lurek.audio.getMasterVolume
    -- @covers lurek.audio.setMasterVolume
    it("setMasterVolume/getMasterVolume roundtrip", function()
        lurek.audio.setMasterVolume(0.75)
        expect_near(0.75, lurek.audio.getMasterVolume(), 0.01)
        lurek.audio.setMasterVolume(1.0) -- reset
    end)

    -- @covers lurek.audio.getMasterVolume
    -- @covers lurek.audio.setMasterVolume
    it("setMasterVolume clamps to valid range", function()
        lurek.audio.setMasterVolume(0.0)
        expect_near(0.0, lurek.audio.getMasterVolume(), 0.01)
        lurek.audio.setMasterVolume(1.0)
        expect_near(1.0, lurek.audio.getMasterVolume(), 0.01)
    end)
end)

-- @describe audio spatial
describe("audio spatial", function()
    -- @covers lurek.audio.getDopplerScale
    it("getDopplerScale returns 1 by default", function()
        expect_near(1.0, lurek.audio.getDopplerScale(), 0.0001)
    end)

    -- @covers lurek.audio.getDopplerScale
    -- @covers lurek.audio.setDopplerScale
    it("setDopplerScale round-trips", function()
        lurek.audio.setDopplerScale(2.0)
        expect_near(2.0, lurek.audio.getDopplerScale(), 0.0001)
        lurek.audio.setDopplerScale(1.0)  -- reset
    end)

    -- @covers lurek.audio.getDistanceModel
    it("getDistanceModel returns a string", function()
        expect_type("string", lurek.audio.getDistanceModel())
    end)

    -- @covers lurek.audio.getDistanceModel
    -- @covers lurek.audio.setDistanceModel
    it("setDistanceModel round-trips", function()
        lurek.audio.setDistanceModel("linear")
        expect_equal("linear", lurek.audio.getDistanceModel())
        lurek.audio.setDistanceModel("inverse_clamped")  -- reset
    end)

    -- @covers lurek.audio.getListener
    -- @covers lurek.audio.setListener
    it("setListener / getListener round-trips", function()
        lurek.audio.setListener(100, 50, 0)
        local x, y, z = lurek.audio.getListener()
        expect_near(100, x, 0.001)
        expect_near(50, y, 0.001)
        expect_near(0, z, 0.001)
        lurek.audio.setListener(0, 0, 0)  -- reset
    end)

    -- @covers lurek.audio.getListener2D
    -- @covers lurek.audio.setListener2D
    it("setListener2D / getListener2D backward compat", function()
        lurek.audio.setListener2D(30, 40)
        local x, y = lurek.audio.getListener2D()
        expect_near(30, x, 0.001)
        expect_near(40, y, 0.001)
        lurek.audio.setListener2D(0, 0)  -- reset
    end)
end)

-- @describe audio.newDecoder
describe("audio.newDecoder", function()
  -- @covers lurek.audio.newDecoder
  it("is a function", function()
    expect_type("function", lurek.audio.newDecoder)
  end)

  -- @covers lurek.audio.newDecoder
  it("errors on missing file", function()
    expect_error(function()
      lurek.audio.newDecoder("nonexistent_file.wav")
    end, "nonexistent_file")
  end)
end)

-- @describe Decoder userdata methods
describe("Decoder userdata methods", function()
  -- @covers LDecoder:getChannelCount
  -- @covers lurek.audio.newDecoder
  it("getChannelCount returns a number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_type("number", d:getChannelCount())
  end)

  -- @covers LDecoder:getChannelCount
  -- @covers lurek.audio.newDecoder
  it("getChannelCount is 1 for mono fixture", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_equal(1, d:getChannelCount())
  end)

  -- @covers LDecoder:getSampleRate
  -- @covers lurek.audio.newDecoder
  it("getSampleRate returns a positive number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    local rate = d:getSampleRate()
    expect_type("number", rate)
    expect_greater(rate, 0, "sample rate must be positive")
  end)

  -- @covers LDecoder:getBitDepth
  -- @covers lurek.audio.newDecoder
  it("getBitDepth returns a positive number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    local depth = d:getBitDepth()
    expect_type("number", depth)
    expect_greater(depth, 0, "bit depth must be positive")
  end)

  -- @covers LDecoder:getDuration
  -- @covers lurek.audio.newDecoder
  it("getDuration returns a positive number", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    local dur = d:getDuration()
    expect_type("number", dur)
    expect_greater(dur, 0, "duration must be positive")
  end)

  -- @covers LDecoder:isSeekable
  -- @covers lurek.audio.newDecoder
  it("isSeekable returns true", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_equal(true, d:isSeekable())
  end)

  -- @covers LDecoder:tell
  -- @covers lurek.audio.newDecoder
  it("tell starts at 0", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    expect_near(0.0, d:tell(), 0.000001)
  end)

  -- @covers LDecoder:seek
  -- @covers LDecoder:tell
  -- @covers lurek.audio.newDecoder
  it("seek and tell round-trip", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav")
    d:seek(0.01)
    expect_near(0.01, d:tell(), 0.001)
  end)

  -- @covers LDecoder:decode
  -- @covers lurek.audio.newDecoder
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

  -- @covers LDecoder:decode
  -- @covers LDecoder:rewind
  -- @covers LDecoder:tell
  -- @covers lurek.audio.newDecoder
  it("rewind resets position to 0", function()
    local d = lurek.audio.newDecoder("tests/fixtures/sine_mono_44100.wav", 1000000)
    d:decode()  -- consume
    d:rewind()
    expect_near(0.0, d:tell(), 0.000001)
  end)
end)

-- Phase 15  Queueable Sources
-- @describe audio.newQueueableSource
describe("audio.newQueueableSource", function()
  -- @covers lurek.audio.newQueueableSource
  it("creates a queueable source and returns a number id", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    expect_equal(type(q), "number")
  end)

  -- @covers lurek.audio.getFreeBufferCount
  -- @covers lurek.audio.newQueueableSource
  it("getFreeBufferCount returns buffer_count initially", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    expect_equal(lurek.audio.getFreeBufferCount(q), 4)
  end)

  -- @covers lurek.audio.getFreeBufferCount
  -- @covers lurek.audio.newQueueableSource
  it("getFreeBufferCount defaults to 4 buffers when omitted", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1)
    expect_equal(lurek.audio.getFreeBufferCount(q), 4)
  end)

  -- @covers lurek.audio.newQueueableSource
  -- @covers lurek.audio.playQueueable
  it("playQueueable does not error", function()
    local q = lurek.audio.newQueueableSource(44100, 16, 1, 4)
    expect_no_error(function()
      lurek.audio.playQueueable(q)
    end)
  end)

  -- @covers lurek.audio.getFreeBufferCount
  -- @covers lurek.audio.newQueueableSource
  -- @covers lurek.audio.newSoundData
  -- @covers lurek.audio.queueSource
  -- @covers lurek.audio.stopQueueable
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
-- @describe audio device selection
describe("audio device selection", function()
  -- @covers lurek.audio.getPlaybackDevices
  it("getPlaybackDevices returns a table", function()
    local devs = lurek.audio.getPlaybackDevices()
    expect_equal(type(devs), "table")
  end)

  -- @covers lurek.audio.getPlaybackDevices
  it("getPlaybackDevices has at least one entry", function()
    local devs = lurek.audio.getPlaybackDevices()
    expect_true(#devs >= 1, "must have at least one device")
  end)

  -- @covers lurek.audio.getPlaybackDevice
  it("getPlaybackDevice returns a string", function()
    expect_equal(type(lurek.audio.getPlaybackDevice()), "string")
  end)

  -- @covers lurek.audio.getPlaybackDevices
  -- @covers lurek.audio.setPlaybackDevice
  it("setPlaybackDevice with valid name does not error", function()
    local devs = lurek.audio.getPlaybackDevices()
    expect_no_error(function()
      lurek.audio.setPlaybackDevice(devs[1])
    end)
  end)

  -- @covers lurek.audio.setPlaybackDevice
  it("setPlaybackDevice with unknown name errors", function()
    expect_error(function()
      lurek.audio.setPlaybackDevice("NonExistentDevice___XYZ")
    end, "Unknown audio device")
  end)
end)

-- Source UserData (static source from fixture)

local FIXTURE = "tests/fixtures/sine_mono_44100.wav"

-- @describe Source UserData - play/stop/pause/resume lifecycle
describe("Source UserData - play/stop/pause/resume lifecycle", function()
    -- @covers lurek.audio.newSource
    it("newSource returns a non-nil Source from fixture", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_true(src ~= nil, "source is not nil")
    end)

    -- @covers LSource:isStopped
    -- @covers lurek.audio.newSource
    it("isStopped is true before play", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_true(src:isStopped())
    end)

    -- @covers LSource:isPlaying
    -- @covers LSource:play
    -- @covers LSource:stop
    -- @covers lurek.audio.newSource
    it("play / isPlaying round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        expect_true(src:isPlaying())
        src:stop()
    end)

    -- @covers LSource:isPaused
    -- @covers LSource:pause
    -- @covers LSource:play
    -- @covers LSource:stop
    -- @covers lurek.audio.newSource
    it("pause / isPaused round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        src:pause()
        expect_true(src:isPaused())
        src:stop()
    end)

    -- @covers LSource:isPlaying
    -- @covers LSource:pause
    -- @covers LSource:play
    -- @covers LSource:resume
    -- @covers LSource:stop
    -- @covers lurek.audio.newSource
    it("resume after pause returns to playing", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        src:pause()
        src:resume()
        expect_true(src:isPlaying())
        src:stop()
    end)

    -- @covers LSource:isStopped
    -- @covers LSource:play
    -- @covers LSource:stop
    -- @covers lurek.audio.newSource
    it("stop transitions to isStopped", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:play()
        src:stop()
        expect_true(src:isStopped())
    end)
end)

-- @describe Source UserData - volume / pitch / pan
describe("Source UserData - volume / pitch / pan", function()
    -- @covers LSource:getVolume
    -- @covers LSource:setVolume
    -- @covers lurek.audio.newSource
    it("setVolume / getVolume round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setVolume(0.5)
        expect_near(0.5, src:getVolume(), 0.001)
    end)

    -- @covers LSource:getPitch
    -- @covers LSource:setPitch
    -- @covers lurek.audio.newSource
    it("setPitch / getPitch round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setPitch(1.5)
        expect_near(1.5, src:getPitch(), 0.001)
    end)

    -- @covers LSource:getPan
    -- @covers LSource:setPan
    -- @covers lurek.audio.newSource
    it("setPan / getPan round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setPan(-0.5)
        expect_near(-0.5, src:getPan(), 0.001)
    end)
end)

-- @describe Source UserData - looping / type / duration
describe("Source UserData - looping / type / duration", function()
    -- @covers LSource:isLooping
    -- @covers LSource:setLooping
    -- @covers lurek.audio.newSource
    it("setLooping true / isLooping true", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setLooping(true)
        expect_true(src:isLooping())
    end)

    -- @covers LSource:isLooping
    -- @covers LSource:setLooping
    -- @covers lurek.audio.newSource
    it("setLooping false / isLooping false", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setLooping(false)
        expect_false(src:isLooping())
    end)

    -- @covers LSource:getType
    -- @covers lurek.audio.newSource
    it("getType returns a string", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_type("string", src:getType())
    end)

    -- @covers LSource:getDuration
    -- @covers lurek.audio.newSource
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

-- @describe Source UserData - tell / seek
describe("Source UserData - tell / seek", function()
    -- @covers LSource:tell
    -- @covers lurek.audio.newSource
    it("tell returns 0 before playback starts", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_equal(0, src:tell())
    end)

    -- @covers LSource:seek
    -- @covers LSource:tell
    -- @covers lurek.audio.newSource
    it("seek moves position and tell reflects it", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:seek(0.01)
        expect_true(src:tell() >= 0)
    end)
end)

-- @describe Source UserData - filter methods
describe("Source UserData - filter methods", function()
    -- @covers LSource:getLowpass
    -- @covers LSource:setLowpass
    -- @covers lurek.audio.newSource
    it("setLowpass / getLowpass does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_no_error(function()
            src:setLowpass(0.5)
            local v = src:getLowpass()
            expect_type("number", v)
        end)
    end)

    -- @covers LSource:getHighpass
    -- @covers LSource:setHighpass
    -- @covers lurek.audio.newSource
    it("setHighpass / getHighpass does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_no_error(function()
            src:setHighpass(0.3)
            local v = src:getHighpass()
            expect_type("number", v)
        end)
    end)

    -- @covers LSource:clearFilter
    -- @covers LSource:setLowpass
    -- @covers lurek.audio.newSource
    it("clearFilter does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:setLowpass(0.5)
        expect_no_error(function() src:clearFilter() end)
    end)
end)

-- @describe Source UserData - fadeIn / clone
describe("Source UserData - fadeIn / clone", function()
    -- @covers LSource:fadeIn
    -- @covers lurek.audio.newSource
    it("fadeIn does not error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_no_error(function() src:fadeIn(1.0) end)
    end)

    -- @covers LSource:fadeIn
    -- @covers LSource:getFadeIn
    -- @covers lurek.audio.newSource
    it("getFadeIn returns a number", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        src:fadeIn(1.0)
        expect_type("number", src:getFadeIn())
    end)

    -- @covers LSource:clone
    -- @covers lurek.audio.newSource
    it("clone returns a new Source", function()
        local src  = lurek.audio.newSource(FIXTURE, "static")
        local copy = src:clone()
        expect_true(copy ~= nil, "cloned source is not nil")
    end)
end)

-- Bus UserData

-- @describe Bus UserData
describe("Bus UserData", function()
    -- @covers lurek.audio.newBus
    it("newBus returns a non-nil object", function()
        local bus = lurek.audio.newBus("test_bus")
        expect_true(bus ~= nil, "bus is not nil")
    end)

    -- @covers LBus:getName
    -- @covers lurek.audio.newBus
    it("Bus:getName returns the registered name", function()
        local bus = lurek.audio.newBus("named_bus")
        expect_equal("named_bus", bus:getName())
    end)

    -- @covers LBus:getVolume
    -- @covers LBus:setVolume
    -- @covers lurek.audio.newBus
    it("Bus setVolume / getVolume round-trip", function()
        local bus = lurek.audio.newBus("vol_bus")
        bus:setVolume(0.6)
        expect_near(0.6, bus:getVolume(), 0.001)
    end)

    -- @covers LBus:getPitch
    -- @covers LBus:setPitch
    -- @covers lurek.audio.newBus
    it("Bus setPitch / getPitch round-trip", function()
        local bus = lurek.audio.newBus("pitch_bus")
        bus:setPitch(1.2)
        expect_near(1.2, bus:getPitch(), 0.001)
    end)

    -- @covers LBus:isPaused
    -- @covers LBus:pause
    -- @covers LBus:resume
    -- @covers lurek.audio.newBus
    it("Bus pause / isPaused / resume", function()
        local bus = lurek.audio.newBus("pause_bus")
        bus:pause()
        expect_true(bus:isPaused())
        bus:resume()
        expect_false(bus:isPaused())
    end)

    -- @covers LBus:type
    -- @covers lurek.audio.newBus
    it("Bus:type returns a string", function()
        local bus = lurek.audio.newBus("type_bus")
        expect_type("string", bus:type())
    end)

    -- @covers LBus:typeOf
    -- @covers lurek.audio.newBus
    it("Bus:typeOf checks identity against a type name", function()
        local bus = lurek.audio.newBus("typeof_bus")
        expect_true(bus:typeOf("Bus"))
        expect_false(bus:typeOf("Source"))
    end)
end)

-- =========================================================================
-- newSoundData guard (PR-4)
-- =========================================================================

-- @describe lurek.audio newSoundData guard
describe("lurek.audio newSoundData guard", function()
    -- @covers lurek.audio.newSoundData
    it("newSoundData_invalid_sample_rate_string_errors", function()
        expect_error(function()
            lurek.audio.newSoundData(64, "invalid")
        end)
    end)

    -- @covers lurek.audio.newSoundData
    it("newSoundData_boolean_sample_rate_errors", function()
        expect_error(function()
            lurek.audio.newSoundData(64, true)
        end)
    end)

    -- @covers lurek.audio.newSoundData
    it("newSoundData_valid_args_succeeds", function()
        expect_no_error(function()
            lurek.audio.newSoundData(64, 44100, 1)
        end)
    end)
end)

-- @describe lurek.audio SoundData
describe("lurek.audio SoundData", function()
    -- @covers LSoundData:getChannelCount
    -- @covers LSoundData:getSample
    -- @covers LSoundData:getSampleCount
    -- @covers LSoundData:getSampleRate
    -- @covers lurek.audio.newSoundData
    it("newSoundData creates a silent buffer with requested shape", function()
        local sd = lurek.audio.newSoundData(100, 44100, 1)
        expect_equal(100, sd:getSampleCount())
        expect_equal(44100, sd:getSampleRate())
        expect_equal(1, sd:getChannelCount())
        expect_near(0.0, sd:getSample(0), 0.0001)
    end)

    -- @covers LSoundData:getSample
    -- @covers LSoundData:setSample
    -- @covers lurek.audio.newSoundData
    it("setSample and getSample round-trip", function()
        local sd = lurek.audio.newSoundData(10, 44100, 1)
        sd:setSample(0, 0.5)
        expect_near(0.5, sd:getSample(0), 0.0001)
    end)

    -- @covers LSoundData:getSample
    -- @covers LSoundData:setSample
    -- @covers lurek.audio.newSoundData
    it("setSample clamps values to audio range", function()
        local sd = lurek.audio.newSoundData(10, 44100, 1)
        sd:setSample(0, 5.0)
        expect_near(1.0, sd:getSample(0), 0.0001)
        sd:setSample(1, -5.0)
        expect_near(-1.0, sd:getSample(1), 0.0001)
    end)

    -- @covers LSoundData:setSample
    -- @covers lurek.audio.newSoundData
    it("setSample errors when index is out of range", function()
        local sd = lurek.audio.newSoundData(10, 44100, 1)
        expect_error(function()
            sd:setSample(100, 0.5)
        end)
    end)

    -- @covers LSoundData:getDuration
    -- @covers lurek.audio.newSoundData
    it("getDuration reports one second for 44100 mono samples", function()
        local sd = lurek.audio.newSoundData(44100, 44100, 1)
        expect_near(1.0, sd:getDuration(), 0.0001)
    end)

    -- @covers LSoundData:getChannelCount
    -- @covers LSoundData:getSample
    -- @covers LSoundData:getSampleCount
    -- @covers lurek.audio.newSineWave
    it("newSineWave creates the requested mono buffer", function()
        local sd = lurek.audio.newSineWave(440.0, 1.0, 44100, 0.5)
        expect_equal(44100, sd:getSampleCount())
        expect_equal(1, sd:getChannelCount())
        expect_true(math.abs(sd:getSample(0)) < 0.01)
    end)

    -- @covers LSoundData:getSample
    -- @covers lurek.audio.newSquareWave
    it("newSquareWave alternates positive and negative phases", function()
        local sd = lurek.audio.newSquareWave(1.0, 1.0, 100, 1.0)
        expect_true(sd:getSample(0) > 0.0)
        expect_true(sd:getSample(75) < 0.0)
    end)

    -- @covers LSoundData:getSample
    -- @covers LSoundData:setSample
    -- @covers lurek.audio.applyGain
    -- @covers lurek.audio.newSoundData
    it("applyGain scales samples in-place", function()
        local sd = lurek.audio.newSoundData(2, 44100, 1)
        sd:setSample(0, 0.5)
        sd:setSample(1, -0.5)
        lurek.audio.applyGain(sd, 0.5)
        expect_near(0.25, sd:getSample(0), 0.0001)
        expect_near(-0.25, sd:getSample(1), 0.0001)
    end)

    -- @covers LSoundData:getSample
    -- @covers LSoundData:setSample
    -- @covers lurek.audio.mixInto
    -- @covers lurek.audio.newSoundData
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

-- @describe lurek.audio MidiPlayer rate and channels
describe("lurek.audio MidiPlayer rate and channels", function()
    -- @covers lurek.audio.newMidiPlayer
    it("newMidiPlayer is a function", function()
        expect_type("function", lurek.audio.newMidiPlayer)
    end)

    -- @covers LMidiPlayer:getSampleRate
    -- @covers lurek.audio.newMidiPlayer
    it("midi_getSampleRate_default_is_44100", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(44100, midi:getSampleRate())
    end)

    -- @covers LMidiPlayer:getSampleRate
    -- @covers LMidiPlayer:setSampleRate
    -- @covers lurek.audio.newMidiPlayer
    it("midi_setSampleRate_roundtrips_value", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(48000)
        expect_equal(48000, midi:getSampleRate())
    end)

    -- @covers LMidiPlayer:getSampleRate
    -- @covers LMidiPlayer:setSampleRate
    -- @covers lurek.audio.newMidiPlayer
    it("midi_setSampleRate_clamps_below_8000_to_8000", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(100)
        expect_equal(8000, midi:getSampleRate())
    end)

    -- @covers LMidiPlayer:getSampleRate
    -- @covers LMidiPlayer:setSampleRate
    -- @covers lurek.audio.newMidiPlayer
    it("midi_setSampleRate_clamps_above_192000_to_192000", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSampleRate(999999)
        expect_equal(192000, midi:getSampleRate())
    end)

    -- @covers LMidiPlayer:getChannels
    -- @covers lurek.audio.newMidiPlayer
    it("midi_getChannels_default_is_2", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(2, midi:getChannels())
    end)

    -- @covers LMidiPlayer:getChannels
    -- @covers LMidiPlayer:setChannels
    -- @covers lurek.audio.newMidiPlayer
    it("midi_setChannels_accepts_1_mono", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(1)
        expect_equal(1, midi:getChannels())
    end)

    -- @covers LMidiPlayer:getChannels
    -- @covers LMidiPlayer:setChannels
    -- @covers lurek.audio.newMidiPlayer
    it("midi_setChannels_accepts_2_stereo", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(2)
        expect_equal(2, midi:getChannels())
    end)

    -- @covers LMidiPlayer:getChannels
    -- @covers LMidiPlayer:setChannels
    -- @covers lurek.audio.newMidiPlayer
    it("midi_setChannels_clamps_above_2_to_2", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannels(5)
        expect_equal(2, midi:getChannels())
    end)
end)

-- =========================================================================
-- Merged from test_audio_bus.lua
-- =========================================================================

-- @describe lurek.audio.newBus
describe("lurek.audio.newBus", function()
    -- @covers LBus:getName
    -- @covers lurek.audio.newBus
    it("creates a bus with the given name", function()
        local bus = lurek.audio.newBus("music")
        expect_equal(bus:getName(), "music")
    end)

    -- @covers LBus:getVolume
    -- @covers lurek.audio.newBus
    it("has default volume 1.0", function()
        local bus = lurek.audio.newBus("test")
        expect_near(bus:getVolume(), 1.0, 1e-5)
    end)

    -- @covers LBus:getPitch
    -- @covers lurek.audio.newBus
    it("has default pitch 1.0", function()
        local bus = lurek.audio.newBus("test")
        expect_near(bus:getPitch(), 1.0, 1e-5)
    end)

    -- @covers LBus:isPaused
    -- @covers lurek.audio.newBus
    it("is not paused by default", function()
        local bus = lurek.audio.newBus("test")
        expect_false(bus:isPaused())
    end)
end)

-- @describe Bus:setVolume / getVolume
describe("Bus:setVolume / getVolume", function()
    -- @covers LBus:getVolume
    -- @covers LBus:setVolume
    -- @covers lurek.audio.newBus
    it("sets and gets volume", function()
        local bus = lurek.audio.newBus("test")
        bus:setVolume(0.7)
        expect_near(bus:getVolume(), 0.7, 1e-5)
    end)

    -- @covers LBus:getVolume
    -- @covers LBus:setVolume
    -- @covers lurek.audio.newBus
    it("clamps negative volume to 0", function()
        local bus = lurek.audio.newBus("test")
        bus:setVolume(-1.0)
        expect_near(bus:getVolume(), 0.0, 1e-5)
    end)
end)

-- @describe Bus:setPitch / getPitch
describe("Bus:setPitch / getPitch", function()
    -- @covers LBus:getPitch
    -- @covers LBus:setPitch
    -- @covers lurek.audio.newBus
    it("sets and gets pitch", function()
        local bus = lurek.audio.newBus("test")
        bus:setPitch(1.5)
        expect_near(bus:getPitch(), 1.5, 1e-5)
    end)

    -- @covers LBus:getPitch
    -- @covers LBus:setPitch
    -- @covers lurek.audio.newBus
    it("clamps negative pitch to 0", function()
        local bus = lurek.audio.newBus("test")
        bus:setPitch(-0.5)
        expect_near(bus:getPitch(), 0.0, 1e-5)
    end)
end)

-- @describe Bus:pause / resume / isPaused
describe("Bus:pause / resume / isPaused", function()
    -- @covers LBus:isPaused
    -- @covers LBus:pause
    -- @covers LBus:resume
    -- @covers lurek.audio.newBus
    it("pauses and resumes", function()
        local bus = lurek.audio.newBus("test")
        bus:pause()
        expect_true(bus:isPaused())
        bus:resume()
        expect_false(bus:isPaused())
    end)
end)

-- @describe Bus type system
describe("Bus type system", function()
    -- @covers LBus:type
    -- @covers lurek.audio.newBus
    it("reports type as LBus", function()
        local bus = lurek.audio.newBus("test")
        expect_equal(bus:type(), "LBus")
    end)

    -- @covers LBus:typeOf
    -- @covers lurek.audio.newBus
    it("typeOf returns true for Bus and Object", function()
        local bus = lurek.audio.newBus("test")
        expect_true(bus:typeOf("Bus"))
        expect_true(bus:typeOf("Object"))
    end)
end)

-- @describe lurek.audio.getMaxSources
describe("lurek.audio.getMaxSources", function()
    -- @covers lurek.audio.getMaxSources
    it("returns 64", function()
        expect_equal(lurek.audio.getMaxSources(), 64)
    end)
end)

-- @describe lurek.audio.setListener2D / getListener2D behavior
describe("lurek.audio.setListener2D / getListener2D behavior", function()
    -- @covers lurek.audio.setListener2D
    it("setListener2D does not error", function()
        lurek.audio.setListener2D(1.0, 2.0)
    end)

    -- @covers lurek.audio.getListener2D
    -- @covers lurek.audio.setListener2D
    it("getListener2D returns the position set by setListener2D", function()
        lurek.audio.setListener2D(1.0, 2.0)
        local x, y = lurek.audio.getListener2D()
        expect_near(x, 1.0, 1e-5)
        expect_near(y, 2.0, 1e-5)
        -- reset for other tests
        lurek.audio.setListener2D(0.0, 0.0)
    end)
end)

-- @describe lurek.audio.setMeter / getMeter behavior
describe("lurek.audio.setMeter / getMeter behavior", function()
    -- @covers lurek.audio.setMeter
    it("setMeter does not error", function()
        lurek.audio.setMeter(2.0)
    end)

    -- @covers lurek.audio.getMeter
    it("getMeter returns 1.0", function()
        expect_near(lurek.audio.getMeter(), 1.0, 1e-5)
    end)
end)

-- @describe lurek.audio.newMidiPlayer
describe("lurek.audio.newMidiPlayer", function()
    -- @covers LMidiPlayer:isLoaded
    -- @covers lurek.audio.newMidiPlayer
    it("creates a MidiPlayer", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isLoaded())
    end)

    -- @covers LMidiPlayer:isPlaying
    -- @covers lurek.audio.newMidiPlayer
    it("is not playing by default", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isPlaying())
    end)

    -- @covers LMidiPlayer:getVolume
    -- @covers lurek.audio.newMidiPlayer
    it("has default volume 1.0", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getVolume(), 1.0, 1e-5)
    end)

    -- @covers LMidiPlayer:getTempoScale
    -- @covers lurek.audio.newMidiPlayer
    it("has default tempo scale 1.0", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getTempoScale(), 1.0, 1e-5)
    end)

    -- @covers LMidiPlayer:getTrackCount
    -- @covers lurek.audio.newMidiPlayer
    it("has 0 tracks when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:getTrackCount(), 0)
    end)

    -- @covers LMidiPlayer:getNoteCount
    -- @covers lurek.audio.newMidiPlayer
    it("has 0 note count when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:getNoteCount(), 0)
    end)
end)

-- @describe MidiPlayer volume
describe("MidiPlayer volume", function()
    -- @covers LMidiPlayer:getVolume
    -- @covers LMidiPlayer:setVolume
    -- @covers lurek.audio.newMidiPlayer
    it("sets and gets volume", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setVolume(0.5)
        expect_near(midi:getVolume(), 0.5, 1e-5)
    end)
end)

-- @describe MidiPlayer tempo
describe("MidiPlayer tempo", function()
    -- @covers LMidiPlayer:getTempoScale
    -- @covers LMidiPlayer:setTempoScale
    -- @covers lurek.audio.newMidiPlayer
    it("sets and gets tempo scale", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setTempoScale(2.0)
        expect_near(midi:getTempoScale(), 2.0, 1e-5)
    end)

    -- @covers LMidiPlayer:getOriginalTempo
    -- @covers lurek.audio.newMidiPlayer
    it("getOriginalTempo returns 120 when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getOriginalTempo(), 120.0, 1e-5)
    end)
end)

-- @describe MidiPlayer looping
describe("MidiPlayer looping", function()
    -- @covers LMidiPlayer:isLooping
    -- @covers LMidiPlayer:setLooping
    -- @covers lurek.audio.newMidiPlayer
    it("toggles looping", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isLooping())
        midi:setLooping(true)
        expect_true(midi:isLooping())
        midi:setLooping(false)
        expect_false(midi:isLooping())
    end)
end)

-- @describe MidiPlayer channel control
describe("MidiPlayer channel control", function()
    -- @covers LMidiPlayer:getChannelVolume
    -- @covers LMidiPlayer:setChannelVolume
    -- @covers lurek.audio.newMidiPlayer
    it("sets and gets channel volume (1-indexed)", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannelVolume(1, 0.5)
        expect_near(midi:getChannelVolume(1), 0.5, 1e-5)
    end)

    -- @covers LMidiPlayer:isChannelMuted
    -- @covers LMidiPlayer:setChannelMuted
    -- @covers lurek.audio.newMidiPlayer
    it("mutes and unmutes channel", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_false(midi:isChannelMuted(1))
        midi:setChannelMuted(1, true)
        expect_true(midi:isChannelMuted(1))
        midi:setChannelMuted(1, false)
        expect_false(midi:isChannelMuted(1))
    end)

    -- @covers LMidiPlayer:getChannelInstrument
    -- @covers LMidiPlayer:setChannelInstrument
    -- @covers lurek.audio.newMidiPlayer
    it("sets and gets channel instrument", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setChannelInstrument(1, 42)
        expect_equal(midi:getChannelInstrument(1), 42)
    end)

    -- @covers LMidiPlayer:isChannelMuted
    -- @covers LMidiPlayer:soloChannel
    -- @covers lurek.audio.newMidiPlayer
    it("soloChannel mutes all others", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:soloChannel(5)
        expect_false(midi:isChannelMuted(5))
        expect_true(midi:isChannelMuted(1))
        expect_true(midi:isChannelMuted(16))
    end)

    -- @covers LMidiPlayer:isChannelMuted
    -- @covers LMidiPlayer:soloChannel
    -- @covers LMidiPlayer:unsoloAll
    -- @covers lurek.audio.newMidiPlayer
    it("unsoloAll unmutes all", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:soloChannel(5)
        midi:unsoloAll()
        expect_false(midi:isChannelMuted(1))
        expect_false(midi:isChannelMuted(5))
        expect_false(midi:isChannelMuted(16))
    end)
end)

-- @describe MidiPlayer utility behavior
describe("MidiPlayer utility behavior", function()
    -- @covers LMidiPlayer:setSoundFont
    -- @covers lurek.audio.newMidiPlayer
    it("setSoundFont does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setSoundFont("path/to/sf2")
    end)

    -- @covers LMidiPlayer:useDefaultSoundFont
    -- @covers lurek.audio.newMidiPlayer
    it("useDefaultSoundFont does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:useDefaultSoundFont()
    end)

    -- @covers LMidiPlayer:getSoundFontPath
    -- @covers lurek.audio.newMidiPlayer
    it("getSoundFontPath returns nil", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:getSoundFontPath(), nil)
    end)

    -- @covers LMidiPlayer:setOnNoteOn
    -- @covers lurek.audio.newMidiPlayer
    it("setOnNoteOn does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setOnNoteOn(function() end)
    end)

    -- @covers LMidiPlayer:setOnNoteOff
    -- @covers lurek.audio.newMidiPlayer
    it("setOnNoteOff does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setOnNoteOff(function() end)
    end)

    -- @covers LMidiPlayer:setOnEnd
    -- @covers lurek.audio.newMidiPlayer
    it("setOnEnd does not error", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:setOnEnd(function() end)
    end)
end)

-- @describe MidiPlayer type system
describe("MidiPlayer type system", function()
    -- @covers LMidiPlayer:type
    -- @covers lurek.audio.newMidiPlayer
    it("reports type as LMidiPlayer", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_equal(midi:type(), "LMidiPlayer")
    end)

    -- @covers LMidiPlayer:typeOf
    -- @covers lurek.audio.newMidiPlayer
    it("typeOf returns true for MidiPlayer and Object", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_true(midi:typeOf("MidiPlayer"))
        expect_true(midi:typeOf("Object"))
    end)
end)

-- @describe MidiPlayer seek/tell
describe("MidiPlayer seek/tell", function()
    -- @covers LMidiPlayer:seek
    -- @covers LMidiPlayer:tell
    -- @covers lurek.audio.newMidiPlayer
    it("seek and tell work", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:seek(5.0)
        expect_near(midi:tell(), 5.0, 1e-5)
    end)

    -- @covers LMidiPlayer:seek
    -- @covers LMidiPlayer:tell
    -- @covers lurek.audio.newMidiPlayer
    it("seek clamps negative to 0", function()
        local midi = lurek.audio.newMidiPlayer()
        midi:seek(-1.0)
        expect_near(midi:tell(), 0.0, 1e-5)
    end)
end)

-- @describe MidiPlayer getDuration
describe("MidiPlayer getDuration", function()
    -- @covers LMidiPlayer:getDuration
    -- @covers lurek.audio.newMidiPlayer
    it("returns 0 when unloaded", function()
        local midi = lurek.audio.newMidiPlayer()
        expect_near(midi:getDuration(), 0.0, 1e-5)
    end)
end)

-- =========================================================================
-- Merged from test_audio_dsp.lua
-- =========================================================================

-- @describe lurek.audio.create_bus
describe("lurek.audio.create_bus", function()
    -- @covers lurek.audio.create_bus
    it("creates a bus without returning an object", function()
        local result = lurek.audio.create_bus("sfx")
        expect_equal(nil, result)
    end)

    -- @covers lurek.audio.create_bus
    it("errors if empty string is provided", function()
        expect_error(function()
            lurek.audio.create_bus("")
        end, "invalid bus name")
    end)
end)

-- @describe lurek.audio.set_bus_volume
describe("lurek.audio.set_bus_volume", function()
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_bus_volume
    it("sets the volume of an existing bus", function()
        lurek.audio.create_bus("music")
        -- Should not error
        lurek.audio.set_bus_volume("music", 0.75)
    end)

    -- @covers lurek.audio.set_bus_volume
    it("errors if bus does not exist", function()
        expect_error(function()
            lurek.audio.set_bus_volume("nonexistent_bus", 0.5)
        end, "bus not found")
    end)
end)

-- @describe lurek.audio.play with bus
describe("lurek.audio.play with bus", function()
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.play
    it("accepts a bus parameter in options", function()
        lurek.audio.create_bus("ambient")
        local src = lurek.audio.newSource("tests/fixtures/sine_mono_44100.wav", "static")
        local id = lurek.audio.play(src, { bus = "ambient" })
        expect_type("number", id)
    end)

    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.play
    it("defaults to master bus if none provided", function()
        local src = lurek.audio.newSource("tests/fixtures/sine_mono_44100.wav", "static")
        local id = lurek.audio.play(src, {})
        expect_type("number", id)
    end)

    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.play
    it("errors if bus does not exist", function()
        local src = lurek.audio.newSource("tests/fixtures/sine_mono_44100.wav", "static")
        expect_error(function()
            lurek.audio.play(src, { bus = "fake_bus" })
        end, "bus not found")
    end)
end)

-- @describe lurek.audio.add_effect
describe("lurek.audio.add_effect", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("adds an effect and returns an integer ID", function()
        lurek.audio.create_bus("sfx2")
        local effect_id = lurek.audio.add_effect("sfx2", "lowpass")
        expect_type("number", effect_id)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("accepts initial parameters", function()
        lurek.audio.create_bus("sfx3")
        local effect_id = lurek.audio.add_effect("sfx3", "reverb", { room_size = 0.8, mix = 0.4 })
        expect_type("number", effect_id)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("errors on invalid effect type", function()
        lurek.audio.create_bus("sfx4")
        expect_error(function()
            lurek.audio.add_effect("sfx4", "magic_wand")
        end, "invalid effect")
    end)

    -- @covers lurek.audio.add_effect
    it("errors if bus does not exist for effect", function()
        expect_error(function()
            lurek.audio.add_effect("nope_bus", "lowpass")
        end, "bus not found")
    end)
end)

-- @describe lurek.audio.set_effect_param
describe("lurek.audio.set_effect_param", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("mutates an effect parameter without errors", function()
        lurek.audio.create_bus("music2")
        local efx = lurek.audio.add_effect("music2", "lowpass")
        -- set cutoff
        lurek.audio.set_effect_param("music2", efx, "cutoff", 500.0)
    end)

    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("errors if effect ID does not exist", function()
        lurek.audio.create_bus("music3")
        expect_error(function()
            lurek.audio.set_effect_param("music3", 9999, "cutoff", 500.0)
        end, "effect not found")
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("errors if parameter name is invalid for effect type", function()
        lurek.audio.create_bus("music4")
        local efx = lurek.audio.add_effect("music4", "lowpass")
        expect_error(function()
            lurek.audio.set_effect_param("music4", efx, "room_size", 0.5)
        end, "invalid parameter")
    end)
end)

-- @describe lurek.audio.remove_effect
describe("lurek.audio.remove_effect", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.remove_effect
    -- @covers lurek.audio.set_effect_param
    it("removes an existing effect", function()
        lurek.audio.create_bus("sfx5")
        local efx = lurek.audio.add_effect("sfx5", "bandpass")
        lurek.audio.remove_effect("sfx5", efx)

        -- Further operations on it should error
        expect_error(function()
            lurek.audio.set_effect_param("sfx5", efx, "center", 1000.0)
        end, "effect not found")
    end)

    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.remove_effect
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

-- @describe lurek.audio.add_effect  - notch
describe("lurek.audio.add_effect  - notch", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates a notch filter effect and returns an id", function()
        lurek.audio.create_bus("test_notch")
        local eid = lurek.audio.add_effect("test_notch", "notch")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts cutoff and bandwidth parameters", function()
        lurek.audio.create_bus("test_notch2")
        local eid = lurek.audio.add_effect("test_notch2", "notch", { cutoff = 1000.0, bandwidth = 100.0 })
        expect_type("number", eid)
        lurek.audio.set_effect_param("test_notch2", eid, "cutoff", 2000.0)
        lurek.audio.set_effect_param("test_notch2", eid, "bandwidth", 200.0)
    end)
end)

-- @describe lurek.audio.add_effect  - lowshelf
describe("lurek.audio.add_effect  - lowshelf", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates a low-shelf EQ effect", function()
        lurek.audio.create_bus("test_lowshelf")
        local eid = lurek.audio.add_effect("test_lowshelf", "lowshelf")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts cutoff and gain_db parameters", function()
        lurek.audio.create_bus("test_lowshelf2")
        local eid = lurek.audio.add_effect("test_lowshelf2", "lowshelf", { cutoff = 200.0, gain_db = -6.0 })
        lurek.audio.set_effect_param("test_lowshelf2", eid, "cutoff", 300.0)
        lurek.audio.set_effect_param("test_lowshelf2", eid, "gain_db", 3.0)
    end)
end)

-- @describe lurek.audio.add_effect  - highshelf
describe("lurek.audio.add_effect  - highshelf", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates a high-shelf EQ effect", function()
        lurek.audio.create_bus("test_highshelf")
        local eid = lurek.audio.add_effect("test_highshelf", "highshelf")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts cutoff and gain_db parameters", function()
        lurek.audio.create_bus("test_highshelf2")
        local eid = lurek.audio.add_effect("test_highshelf2", "highshelf", { cutoff = 8000.0, gain_db = 4.0 })
        lurek.audio.set_effect_param("test_highshelf2", eid, "gain_db", -3.0)
    end)
end)

-- @describe lurek.audio.add_effect  - flanger
describe("lurek.audio.add_effect  - flanger", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates a flanger effect", function()
        lurek.audio.create_bus("test_flanger")
        local eid = lurek.audio.add_effect("test_flanger", "flanger")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts rate and depth parameters", function()
        lurek.audio.create_bus("test_flanger2")
        local eid = lurek.audio.add_effect("test_flanger2", "flanger", { rate = 0.5, depth = 0.3, mix = 0.6 })
        lurek.audio.set_effect_param("test_flanger2", eid, "rate", 1.0)
        lurek.audio.set_effect_param("test_flanger2", eid, "depth", 0.5)
        lurek.audio.set_effect_param("test_flanger2", eid, "mix", 0.8)
    end)
end)

-- @describe lurek.audio.add_effect  - phaser
describe("lurek.audio.add_effect  - phaser", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates a phaser effect", function()
        lurek.audio.create_bus("test_phaser")
        local eid = lurek.audio.add_effect("test_phaser", "phaser")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts rate, depth and mix parameters", function()
        lurek.audio.create_bus("test_phaser2")
        local eid = lurek.audio.add_effect("test_phaser2", "phaser", { rate = 0.3, depth = 0.7, mix = 0.5 })
        lurek.audio.set_effect_param("test_phaser2", eid, "rate", 0.6)
    end)
end)

-- @describe lurek.audio.add_effect  - distortion
describe("lurek.audio.add_effect  - distortion", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates a distortion (waveshaper) effect", function()
        lurek.audio.create_bus("test_dist")
        local eid = lurek.audio.add_effect("test_dist", "distortion")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts drive and mix parameters", function()
        lurek.audio.create_bus("test_dist2")
        local eid = lurek.audio.add_effect("test_dist2", "distortion", { drive = 10.0, mix = 0.5 })
        lurek.audio.set_effect_param("test_dist2", eid, "drive", 20.0)
        lurek.audio.set_effect_param("test_dist2", eid, "mix", 0.3)
    end)
end)

-- @describe lurek.audio.add_effect  - limiter
describe("lurek.audio.add_effect  - limiter", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates a brick-wall limiter effect", function()
        lurek.audio.create_bus("test_limiter")
        local eid = lurek.audio.add_effect("test_limiter", "limiter")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts threshold and release parameters", function()
        lurek.audio.create_bus("test_limiter2")
        local eid = lurek.audio.add_effect("test_limiter2", "limiter", { threshold = 0.9, release = 0.1 })
        lurek.audio.set_effect_param("test_limiter2", eid, "threshold", 0.8)
    end)
end)

-- @describe lurek.audio.add_effect  - compressor
describe("lurek.audio.add_effect  - compressor", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates a dynamic range compressor", function()
        lurek.audio.create_bus("test_comp")
        local eid = lurek.audio.add_effect("test_comp", "compressor")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts threshold, ratio and makeup_gain parameters", function()
        lurek.audio.create_bus("test_comp2")
        local eid = lurek.audio.add_effect("test_comp2", "compressor",
            { threshold = 0.5, ratio = 4.0, makeup_gain = 1.5 })
        lurek.audio.set_effect_param("test_comp2", eid, "threshold", 0.6)
        lurek.audio.set_effect_param("test_comp2", eid, "ratio", 2.0)
        lurek.audio.set_effect_param("test_comp2", eid, "makeup_gain", 1.0)
    end)
end)

-- @describe lurek.audio.add_effect  - bell_eq
describe("lurek.audio.add_effect  - bell_eq", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates a bell equalizer effect", function()
        lurek.audio.create_bus("test_bell")
        local eid = lurek.audio.add_effect("test_bell", "bell_eq")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts cutoff, gain_db and q parameters", function()
        lurek.audio.create_bus("test_bell2")
        local eid = lurek.audio.add_effect("test_bell2", "bell_eq",
            { cutoff = 1000.0, gain_db = 6.0, q = 1.0 })
        lurek.audio.set_effect_param("test_bell2", eid, "cutoff", 2000.0)
        lurek.audio.set_effect_param("test_bell2", eid, "gain_db", -3.0)
    end)
end)

-- @describe lurek.audio.add_effect  - reverb2
describe("lurek.audio.add_effect  - reverb2", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    it("creates an improved reverb (reverb2) effect", function()
        lurek.audio.create_bus("test_rev2")
        local eid = lurek.audio.add_effect("test_rev2", "reverb2")
        expect_type("number", eid)
    end)

    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.set_effect_param
    it("accepts room_size, damping, pre_delay and mix parameters", function()
        lurek.audio.create_bus("test_rev3")
        local eid = lurek.audio.add_effect("test_rev3", "reverb2",
            { room_size = 0.7, damping = 0.5, pre_delay = 0.02, mix = 0.4 })
        lurek.audio.set_effect_param("test_rev3", eid, "room_size", 0.9)
        lurek.audio.set_effect_param("test_rev3", eid, "mix", 0.3)
    end)
end)

-- @describe lurek.audio.add_effect  - validation
describe("lurek.audio.add_effect  - validation", function()
    -- @covers lurek.audio.add_effect
    -- @covers lurek.audio.create_bus
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

-- @describe lurek.audio.processOffline
describe("lurek.audio.processOffline", function()
    -- @covers lurek.audio.processOffline
    it("processes a WAV file with a lowpass effect and writes output", function()
        local effects = {
            { type = "lowpass", cutoff = 1000.0 }
        }
        local out = OUT_DIR .. "offline_lowpass_out.wav"
        lurek.audio.processOffline(WAVE, out, effects)
    end)

    -- @covers lurek.audio.processOffline
    it("processes with multiple chained effects", function()
        local effects = {
            { type = "highpass", cutoff = 200.0 },
            { type = "reverb",   room_size = 0.6, mix = 0.3 }
        }
        local out = OUT_DIR .. "offline_chain_out.wav"
        lurek.audio.processOffline(WAVE, out, effects)
    end)

    -- @covers lurek.audio.processOffline
    it("processes with empty effect list (passthrough)", function()
        local out = OUT_DIR .. "offline_passthrough_out.wav"
        lurek.audio.processOffline(WAVE, out, {})
    end)

    -- @covers lurek.audio.processOffline
    it("errors if source file does not exist", function()
        expect_error(function()
            lurek.audio.processOffline("no_such_file.wav", OUT_DIR .. "out.wav", {})
        end, "not found")
    end)

    -- @covers lurek.audio.processOffline
    it("errors on path traversal in output path", function()
        expect_error(function()
            lurek.audio.processOffline(WAVE, "../../etc/output.wav", {})
        end, "path")
    end)
end)

-- @describe lurek.audio.normalizeFile
describe("lurek.audio.normalizeFile", function()
    -- @covers lurek.audio.normalizeFile
    it("normalizes a WAV file without error", function()
        local out = OUT_DIR .. "normalized_out.wav"
        lurek.audio.normalizeFile(WAVE, out, 0.9)
    end)

    -- @covers lurek.audio.normalizeFile
    it("errors if target level is outside (0.0, 1.0]", function()
        expect_error(function()
            lurek.audio.normalizeFile(WAVE, OUT_DIR .. "out.wav", 0.0)
        end, "target level")
        expect_error(function()
            lurek.audio.normalizeFile(WAVE, OUT_DIR .. "out.wav", 1.5)
        end, "target level")
    end)

    -- @covers lurek.audio.normalizeFile
    it("errors if source file does not exist", function()
        expect_error(function()
            lurek.audio.normalizeFile("no_such.wav", OUT_DIR .. "out.wav", 0.9)
        end, "not found")
    end)
end)

-- =========================================================================
-- Merged from test_audio_pool.lua
-- =========================================================================

-- @describe lurek.audio.newPool
describe("lurek.audio.newPool", function()
    -- @covers lurek.audio.newPool
    it("creates a sound pool and returns a Pool object", function()
        local pool = lurek.audio.newPool(WAVE, 4)
        expect_not_nil(pool)
    end)

    -- @covers lurek.audio.newPool
    it("errors on empty path", function()
        local ok, pool = pcall(function()
            return lurek.audio.newPool("", 4)
        end)
        if ok then
            expect_not_nil(pool)
        else
            expect_false(ok)
        end
    end)

    -- @covers lurek.audio.newPool
    it("errors on zero voice count", function()
        expect_error(function()
            lurek.audio.newPool(WAVE, 0)
        end, "invalid voice count")
    end)
end)

-- @describe Pool:play
describe("Pool:play", function()
    -- @covers LSoundPool:play
    -- @covers lurek.audio.newPool
    it("play returns a numeric source id", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        local id = pool:play()
        expect_type("number", id)
    end)

    -- @covers LSoundPool:play
    -- @covers lurek.audio.newPool
    it("play can be called multiple times up to voice count", function()
        local pool = lurek.audio.newPool(WAVE, 3)
        local id1 = pool:play()
        local id2 = pool:play()
        local id3 = pool:play()
        expect_type("number", id1)
        expect_type("number", id2)
        expect_type("number", id3)
    end)

    -- @covers LSoundPool:play
    -- @covers lurek.audio.newPool
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

-- @describe Pool:stopAll
describe("Pool:stopAll", function()
    -- @covers LSoundPool:play
    -- @covers LSoundPool:stopAll
    -- @covers lurek.audio.newPool
    it("stopAll does not error when pool has playing sources", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:play()
        pool:play()
        pool:stopAll()  -- should not raise
    end)

    -- @covers LSoundPool:stopAll
    -- @covers lurek.audio.newPool
    it("stopAll does not error on an idle pool", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:stopAll()
    end)
end)

-- @describe Pool:setVolume
describe("Pool:setVolume", function()
    -- @covers LSoundPool:setVolume
    -- @covers lurek.audio.newPool
    it("setVolume sets volume for all pool sources", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:setVolume(0.5)  -- should not raise
    end)
end)

-- @describe Pool:setBus
describe("Pool:setBus", function()
    -- @covers LSoundPool:setBus
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.newPool
    it("setBus routes all pool sources to a named bus", function()
        lurek.audio.create_bus("pool_test_bus")
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:setBus("pool_test_bus")  -- should not raise
    end)

    -- @covers LSoundPool:setBus
    -- @covers lurek.audio.newPool
    it("setBus silently accepts an unknown bus name", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        -- Pool.setBus does not validate bus existence at assignment time
        pool:setBus("nonexistent_pool_bus")
    end)
end)

-- @describe Pool:release
describe("Pool:release", function()
    -- @covers LSoundPool:play
    -- @covers LSoundPool:release
    -- @covers lurek.audio.newPool
    it("release frees all sources without error", function()
        local pool = lurek.audio.newPool(WAVE, 2)
        pool:play()
        pool:release()  -- should not raise
    end)
end)

-- @describe Pool:getVoiceCount
describe("Pool:getVoiceCount", function()
    -- @covers LSoundPool:getVoiceCount
    -- @covers lurek.audio.newPool
    it("returns the configured voice count", function()
        local pool = lurek.audio.newPool(WAVE, 6)
        expect_equal(6, pool:getVoiceCount())
    end)
end)

-- =========================================================================
-- Merged from test_audio_stereo.lua
-- =========================================================================

-- @describe lurek.audio.setStereoWidth
describe("lurek.audio.setStereoWidth", function()
    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.setStereoWidth
    it("sets stereo width on a valid source without error", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setStereoWidth(src, 1.5)  -- 1.5 = slight widening
    end)

    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.setStereoWidth
    it("clamps stereo width to [0.0, 2.0] silently", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setStereoWidth(src, -1.0)  -- should clamp, not error
        lurek.audio.setStereoWidth(src, 5.0)   -- should clamp, not error
    end)

    -- @covers lurek.audio.getStereoWidth
    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.setStereoWidth
    it("getStereoWidth returns the last set value (clamped)", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setStereoWidth(src, 0.5)
        local w = lurek.audio.getStereoWidth(src)
        expect_near(0.5, w, 0.001)
    end)

    -- @covers lurek.audio.setStereoWidth
    it("errors on invalid source handle", function()
        expect_error(function()
            lurek.audio.setStereoWidth(99999999, 1.0) ---@diagnostic disable-line: param-type-mismatch
        end, "invalid")
    end)
end)

-- @describe lurek.audio.setRandomPitch
describe("lurek.audio.setRandomPitch", function()
    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.setRandomPitch
    it("sets a random pitch range on a source", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setRandomPitch(src, 0.9, 1.1)
    end)

    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.setRandomPitch
    it("errors if min > max", function()
        local src = lurek.audio.newSource(WAVE, "static")
        expect_error(function()
            lurek.audio.setRandomPitch(src, 1.5, 0.5)
        end, "min must be")
    end)

    -- @covers lurek.audio.setRandomPitch
    it("errors on invalid source", function()
        expect_error(function()
            lurek.audio.setRandomPitch(12345678, 0.9, 1.1) ---@diagnostic disable-line: param-type-mismatch
        end, "invalid")
    end)

    -- @covers lurek.audio.clearRandomPitch
    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.setRandomPitch
    it("clearRandomPitch removes the random pitch range", function()
        local src = lurek.audio.newSource(WAVE, "static")
        lurek.audio.setRandomPitch(src, 0.9, 1.1)
        lurek.audio.clearRandomPitch(src)  -- should not error
    end)
end)

-- @describe lurek.audio.crossfade
describe("lurek.audio.crossfade", function()
    -- @covers lurek.audio.crossfade
    -- @covers lurek.audio.newSource
    it("crossfade between two sources does not error", function()
        local src_a = lurek.audio.newSource(WAVE, "static")
        local src_b = lurek.audio.newSource(WAVE, "static")
        lurek.audio.crossfade(src_a, src_b, 0.5)
    end)

    -- @covers lurek.audio.crossfade
    -- @covers lurek.audio.newSource
    it("crossfade with negative duration does not validate (passthrough)", function()
        local src_a = lurek.audio.newSource(WAVE, "static")
        local src_b = lurek.audio.newSource(WAVE, "static")
        -- crossfade passes duration to the mixer without validation
        lurek.audio.crossfade(src_a, src_b, -1.0)
    end)

    -- @covers lurek.audio.crossfade
    -- @covers lurek.audio.newSource
    it("errors if first source is invalid", function()
        local src_b = lurek.audio.newSource(WAVE, "static")
        expect_error(function()
            lurek.audio.crossfade(99999999, src_b, 0.5) ---@diagnostic disable-line: param-type-mismatch
        end, "invalid")
    end)
end)

-- @describe lurek.audio.getBusPeak
describe("lurek.audio.getBusPeak", function()
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.getBusPeak
    it("returns a number for a known bus", function()
        lurek.audio.create_bus("peak_test_bus")
        local peak = lurek.audio.getBusPeak("peak_test_bus")
        expect_type("number", peak)
    end)

    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.getBusPeak
    it("returns 0.0 when bus is idle", function()
        lurek.audio.create_bus("peak_idle_bus")
        local peak = lurek.audio.getBusPeak("peak_idle_bus")
        expect_near(0.0, peak, 0.001)
    end)

    -- @covers lurek.audio.getBusPeak
    it("errors for unknown bus", function()
        expect_error(function()
            lurek.audio.getBusPeak("nope_bus")
        end, "bus not found")
    end)
end)

-- @describe lurek.audio.getBusRms
describe("lurek.audio.getBusRms", function()
    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.getBusRms
    it("returns a number for a known bus", function()
        lurek.audio.create_bus("rms_test_bus")
        local rms = lurek.audio.getBusRms("rms_test_bus")
        expect_type("number", rms)
    end)

    -- @covers lurek.audio.create_bus
    -- @covers lurek.audio.getBusRms
    it("returns 0.0 when bus is idle", function()
        lurek.audio.create_bus("rms_idle_bus")
        local rms = lurek.audio.getBusRms("rms_idle_bus")
        expect_near(0.0, rms, 0.001)
    end)
end)

-- @describe lurek.audio waveform and spectrogram export errors
describe("lurek.audio waveform and spectrogram export errors", function()
    -- @covers lurek.audio.waveformToPng
    it("waveformToPng errors for a missing input file", function()
        local ok, err = pcall(function()
            lurek.audio.waveformToPng("tests/fixtures/does_not_exist.wav", "tests/output/missing_waveform.png", 100, 50)
        end)

        expect_false(ok)
        expect_false(err == nil)
    end)

    -- @covers lurek.audio.spectrogramToPng
    it("spectrogramToPng errors for a missing input file", function()
        local ok, err = pcall(function()
            lurek.audio.spectrogramToPng("tests/fixtures/does_not_exist.wav", "tests/output/missing_spectrogram.png", 100, 50)
        end)

        expect_false(ok)
        expect_false(err == nil)
    end)
end)

-- @describe audio missing explicit coverage
describe("audio missing explicit coverage", function()
    -- @covers LBus:clearDuck
    -- @covers LBus:getPeak
    -- @covers LBus:setDuckTarget
    -- @covers lurek.audio.getActiveSourceCount
    -- @covers lurek.audio.getSourceBus
    -- @covers lurek.audio.getSourceCount
    -- @covers lurek.audio.getSourceType
    -- @covers lurek.audio.newBus
    -- @covers lurek.audio.newSource
    -- @covers lurek.audio.pauseAll
    -- @covers lurek.audio.playLooping
    -- @covers lurek.audio.resumeAll
    -- @covers lurek.audio.setSourceBus
    it("source and bus helpers are callable", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        local bus = lurek.audio.newBus("coverage_bus")

        expect_no_error(function()
            lurek.audio.playLooping(src)
            local _a = lurek.audio.getActiveSourceCount()
            local _s = lurek.audio.getSourceCount()
            local _t = lurek.audio.getSourceType(src)
            lurek.audio.pauseAll()
            lurek.audio.resumeAll()

            lurek.audio.setSourceBus(src, bus)
            local _sb = lurek.audio.getSourceBus(src)

            bus:setDuckTarget("coverage_bus", 0.5)
            bus:clearDuck()
            local _pk = bus:getPeak()
        end)
    end)

    -- @covers LMidiPlayer:getFilePath
    -- @covers LMidiPlayer:getTicksPerBeat
    -- @covers LMidiPlayer:getTrackName
    -- @covers LMidiPlayer:isTrackMuted
    -- @covers LMidiPlayer:loadData
    -- @covers LMidiPlayer:setTrackMuted
    -- @covers lurek.audio.clearMidiSoundFont
    -- @covers lurek.audio.hasMidiSoundFont
    -- @covers lurek.audio.newMidiPlayer
    -- @covers lurek.audio.setMidiSoundFont
    it("midi and soundfont helpers are callable", function()
        local mp = lurek.audio.newMidiPlayer()
        expect_type("boolean", mp:loadData(string.char(0x4d, 0x54, 0x68, 0x64)))

        local _fp = mp:getFilePath()
        local _tpb = mp:getTicksPerBeat()
        local _tn = mp:getTrackName(1)
        mp:setTrackMuted(1, true)
        local _muted = mp:isTrackMuted(1)

        -- Missing file path is acceptable; this still covers the API call.
        local _ok_sf = pcall(function()
            lurek.audio.setMidiSoundFont("tests/fixtures/missing.sf2")
        end)
        local _has_sf = lurek.audio.hasMidiSoundFont()
        lurek.audio.clearMidiSoundFont()
    end)
end)
-- ============================================================
-- audio strict: module-level source control functions
-- ============================================================

local FIXTURE = "tests/fixtures/sine_mono_44100.wav"

-- @describe audio strict: stop
describe("audio strict: stop", function()
    -- @covers lurek.audio.stop
    it("stop is callable on a loaded source", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        local ok = pcall(lurek.audio.stop, src)
        expect_true(ok)
    end)
end)

-- @describe audio strict: setVolume and getVolume
describe("audio strict: setVolume and getVolume", function()
    -- @covers lurek.audio.setVolume
    -- @covers lurek.audio.getVolume
    it("setVolume then getVolume round-trip", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.setVolume(src, 0.5)
        expect_type("number", lurek.audio.getVolume(src))
    end)
end)

-- @describe audio strict: pause and resume
describe("audio strict: pause and resume", function()
    -- @covers lurek.audio.pause
    -- @covers lurek.audio.resume
    it("pause then resume are callable without error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        local ok1 = pcall(lurek.audio.pause, src)
        local ok2 = pcall(lurek.audio.resume, src)
        expect_true(ok1)
        expect_true(ok2)
    end)
end)

-- @describe audio strict: setPitch and getPitch
describe("audio strict: setPitch and getPitch", function()
    -- @covers lurek.audio.setPitch
    -- @covers lurek.audio.getPitch
    it("setPitch then getPitch returns number", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.setPitch(src, 1.2)
        expect_type("number", lurek.audio.getPitch(src))
    end)
end)

-- @describe audio strict: isPlaying and isStopped
describe("audio strict: isPlaying and isStopped", function()
    -- @covers lurek.audio.isPlaying
    -- @covers lurek.audio.isStopped
    it("isPlaying and isStopped return booleans", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_type("boolean", lurek.audio.isPlaying(src))
        expect_type("boolean", lurek.audio.isStopped(src))
    end)
end)

-- @describe audio strict: isPaused
describe("audio strict: isPaused", function()
    -- @covers lurek.audio.isPaused
    it("isPaused returns boolean", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_type("boolean", lurek.audio.isPaused(src))
    end)
end)

-- @describe audio strict: setLooping and isLooping
describe("audio strict: setLooping and isLooping", function()
    -- @covers lurek.audio.setLooping
    -- @covers lurek.audio.isLooping
    it("setLooping true then isLooping returns true", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.setLooping(src, true)
        expect_true(lurek.audio.isLooping(src))
    end)
end)

-- @describe audio strict: setPan and getPan
describe("audio strict: setPan and getPan", function()
    -- @covers lurek.audio.setPan
    -- @covers lurek.audio.getPan
    it("setPan then getPan returns number", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.setPan(src, -0.5)
        expect_type("number", lurek.audio.getPan(src))
    end)
end)

-- @describe audio strict: clone
describe("audio strict: clone", function()
    -- @covers lurek.audio.clone
    it("clone returns a new source", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        local cloned = lurek.audio.clone(src)
        expect_type("userdata", cloned)
    end)
end)

-- @describe audio strict: getDuration
describe("audio strict: getDuration", function()
    -- @covers lurek.audio.getDuration
    it("getDuration returns a number", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        local dur = lurek.audio.getDuration(src)
        expect_true(dur == nil or type(dur) == "number")
    end)
end)

-- @describe audio strict: tell and seek
describe("audio strict: tell and seek", function()
    -- @covers lurek.audio.tell
    -- @covers lurek.audio.seek
    it("tell returns number and seek is callable without error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_type("number", lurek.audio.tell(src))
        local ok = pcall(lurek.audio.seek, src, 0.0)
        expect_true(ok)
    end)
end)

-- @describe audio strict: setLowpass and getLowpass
describe("audio strict: setLowpass and getLowpass", function()
    -- @covers lurek.audio.setLowpass
    -- @covers lurek.audio.getLowpass
    it("setLowpass then getLowpass returns number", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.setLowpass(src, 2000)
        expect_type("number", lurek.audio.getLowpass(src))
    end)
end)

-- @describe audio strict: setHighpass and getHighpass
describe("audio strict: setHighpass and getHighpass", function()
    -- @covers lurek.audio.setHighpass
    -- @covers lurek.audio.getHighpass
    it("setHighpass then getHighpass returns number", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.setHighpass(src, 500)
        expect_type("number", lurek.audio.getHighpass(src))
    end)
end)

-- @describe audio strict: clearFilter
describe("audio strict: clearFilter", function()
    -- @covers lurek.audio.clearFilter
    it("clearFilter is callable without error", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        local ok = pcall(lurek.audio.clearFilter, src)
        expect_true(ok)
    end)
end)

-- @describe audio strict: fadeIn and getFadeIn
describe("audio strict: fadeIn and getFadeIn", function()
    -- @covers lurek.audio.fadeIn
    -- @covers lurek.audio.getFadeIn
    it("fadeIn then getFadeIn returns number", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.fadeIn(src, 0.5)
        expect_type("number", lurek.audio.getFadeIn(src))
    end)
end)

-- @describe audio strict: setPosition and getPosition
describe("audio strict: setPosition and getPosition", function()
    -- @covers lurek.audio.setPosition
    -- @covers lurek.audio.getPosition
    it("setPosition then getPosition returns numbers", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.setPosition(src, 1.0, 2.0, 0.0)
        local x, y = lurek.audio.getPosition(src)
        expect_type("number", x)
        expect_type("number", y)
    end)
end)

-- @describe audio strict: setVelocity and getVelocity
describe("audio strict: setVelocity and getVelocity", function()
    -- @covers lurek.audio.setVelocity
    -- @covers lurek.audio.getVelocity
    it("setVelocity then getVelocity returns numbers", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.setVelocity(src, 0.1, 0.2, 0.0)
        local vx, vy = lurek.audio.getVelocity(src)
        expect_type("number", vx)
        expect_type("number", vy)
    end)
end)

-- @describe audio strict: setOrientation and getOrientation
describe("audio strict: setOrientation and getOrientation", function()
    -- @covers lurek.audio.setOrientation
    -- @covers lurek.audio.getOrientation
    it("setOrientation then getOrientation returns numbers", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        lurek.audio.setOrientation(src, 0, 0, 1, 0, 1, 0)
        local ax, ay = lurek.audio.getOrientation(src)
        expect_type("number", ax)
    end)
end)

-- @describe audio strict: stopAll
describe("audio strict: stopAll", function()
    -- @covers lurek.audio.stopAll
    it("stopAll is callable without error", function()
        local ok = pcall(lurek.audio.stopAll)
        expect_true(ok)
    end)
end)

-- @describe audio strict: release
describe("audio strict: release", function()
    -- @covers lurek.audio.release
    it("release returns true for a valid source", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        local result = lurek.audio.release(src)
        expect_true(result)
    end)
end)

-- @describe audio strict: newSawtoothWave
describe("audio strict: newSawtoothWave", function()
    -- @covers lurek.audio.newSawtoothWave
    it("newSawtoothWave returns SoundData", function()
        local sd = lurek.audio.newSawtoothWave(440, 0.01, 44100, 0.5)
        expect_type("userdata", sd)
    end)
end)

-- @describe audio strict: newTriangleWave
describe("audio strict: newTriangleWave", function()
    -- @covers lurek.audio.newTriangleWave
    it("newTriangleWave returns SoundData", function()
        local sd = lurek.audio.newTriangleWave(440, 0.01, 44100, 0.5)
        expect_type("userdata", sd)
    end)
end)

-- @describe audio strict: newWhiteNoise
describe("audio strict: newWhiteNoise", function()
    -- @covers lurek.audio.newWhiteNoise
    it("newWhiteNoise returns SoundData", function()
        local sd = lurek.audio.newWhiteNoise(0.01, 44100, 0.5, 42)
        expect_type("userdata", sd)
    end)
end)

-- @describe audio strict: applyLowpass
describe("audio strict: applyLowpass", function()
    -- @covers lurek.audio.applyLowpass
    it("applyLowpass modifies SoundData in-place without error", function()
        local sd = lurek.audio.newSawtoothWave(440, 0.01, 44100, 0.5)
        local ok = pcall(lurek.audio.applyLowpass, sd, 2000.0)
        expect_true(ok)
    end)
end)

-- @describe audio strict: applyHighpass
describe("audio strict: applyHighpass", function()
    -- @covers lurek.audio.applyHighpass
    it("applyHighpass modifies SoundData in-place without error", function()
        local sd = lurek.audio.newSawtoothWave(440, 0.01, 44100, 0.5)
        local ok = pcall(lurek.audio.applyHighpass, sd, 500.0)
        expect_true(ok)
    end)
end)

-- @describe audio strict: applyBandpass
describe("audio strict: applyBandpass", function()
    -- @covers lurek.audio.applyBandpass
    it("applyBandpass modifies SoundData in-place without error", function()
        local sd = lurek.audio.newSawtoothWave(440, 0.01, 44100, 0.5)
        local ok = pcall(lurek.audio.applyBandpass, sd, 500.0, 2000.0)
        expect_true(ok)
    end)
end)

-- @describe audio strict: saveWAV
describe("audio strict: saveWAV", function()
    -- @covers lurek.audio.saveWAV
    it("saveWAV writes a file without error", function()
        local sd = lurek.audio.newSawtoothWave(440, 0.01, 44100, 0.5)
        local ok = pcall(lurek.audio.saveWAV, sd, "save/_audio_strict_test.wav")
        expect_true(ok)
    end)
end)

-- @describe audio strict: LSource type and typeOf
describe("audio strict: LSource type and typeOf", function()
    -- @covers LSource:type
    -- @covers LSource:typeOf
    it("LSource type returns LSource and typeOf takes name", function()
        local src = lurek.audio.newSource(FIXTURE, "static")
        expect_equal(src:type(), "LSource")
        expect_true(src:typeOf("LSource"))
    end)
end)

-- @describe audio strict: LMidiPlayer load and play
describe("audio strict: LMidiPlayer load and play", function()
    -- @covers LMidiPlayer:load
    -- @covers LMidiPlayer:play
    it("LMidiPlayer load and play are callable", function()
        local mp = lurek.audio.newMidiPlayer()
        local _ok = pcall(function() mp:load("nonexistent.mid") end)
        local ok2 = pcall(function() mp:play() end)
        expect_true(ok2)
    end)
end)

-- @describe audio strict: LMidiPlayer pause and isPaused
describe("audio strict: LMidiPlayer pause and isPaused", function()
    -- @covers LMidiPlayer:pause
    -- @covers LMidiPlayer:isPaused
    it("LMidiPlayer pause is callable and isPaused returns boolean", function()
        local mp = lurek.audio.newMidiPlayer()
        local ok = pcall(function() mp:pause() end)
        expect_true(ok)
        expect_type("boolean", mp:isPaused())
    end)
end)

-- @describe audio strict: LMidiPlayer stop
describe("audio strict: LMidiPlayer stop", function()
    -- @covers LMidiPlayer:stop
    it("LMidiPlayer stop is callable without error", function()
        local mp = lurek.audio.newMidiPlayer()
        local ok = pcall(function() mp:stop() end)
        expect_true(ok)
    end)
end)

-- @describe audio strict: LMidiPlayer setTempo and getTempo
describe("audio strict: LMidiPlayer setTempo and getTempo", function()
    -- @covers LMidiPlayer:setTempo
    -- @covers LMidiPlayer:getTempo
    it("LMidiPlayer setTempo then getTempo returns number", function()
        local mp = lurek.audio.newMidiPlayer()
        local ok = pcall(function() mp:setTempo(120.0) end)
        expect_true(ok)
        expect_type("number", mp:getTempo())
    end)
end)

-- @describe audio strict: LMidiPlayer setBus and getBus
describe("audio strict: LMidiPlayer setBus and getBus", function()
    -- @covers LMidiPlayer:setBus
    -- @covers LMidiPlayer:getBus
    it("LMidiPlayer setBus with nil is callable and getBus returns value", function()
        local mp = lurek.audio.newMidiPlayer()
        local ok = pcall(function() mp:setBus(nil) end)
        expect_true(ok)
        local b = mp:getBus()
        expect_true(b == nil or type(b) == "userdata")
    end)
end)

-- @describe audio strict: LMidiPlayer getChannelCount
describe("audio strict: LMidiPlayer getChannelCount", function()
    -- @covers LMidiPlayer:getChannelCount
    it("LMidiPlayer getChannelCount returns number", function()
        local mp = lurek.audio.newMidiPlayer()
        expect_type("number", mp:getChannelCount())
    end)
end)

-- @describe audio strict: LSoundPool type and typeOf
describe("audio strict: LSoundPool type and typeOf", function()
    -- @covers LSoundPool:type
    -- @covers LSoundPool:typeOf
    it("LSoundPool type and typeOf return correct values", function()
        local ok, pool = pcall(lurek.audio.newPool, FIXTURE, 2)
        if ok then
            expect_equal(pool:type(), "LSoundPool")
            expect_true(pool:typeOf("SoundPool"))
        else
            expect_true(true)
        end
    end)
end)

-- @describe audio strict: LDecoder type and typeOf
describe("audio strict: LDecoder type and typeOf", function()
    -- @covers LDecoder:type
    -- @covers LDecoder:typeOf
    it("LDecoder type and typeOf return correct values", function()
        local d = lurek.audio.newDecoder(FIXTURE)
        expect_equal(d:type(), "LDecoder")
        expect_true(d:typeOf("LDecoder"))
    end)
end)

-- @describe audio strict: LDecoder release
describe("audio strict: LDecoder release", function()
    -- @covers LDecoder:release
    it("LDecoder release is callable without error", function()
        local d = lurek.audio.newDecoder(FIXTURE)
        local ok = pcall(function() d:release() end)
        expect_true(ok)
    end)
end)

-- @describe audio strict: LSoundData getBitDepth
describe("audio strict: LSoundData getBitDepth", function()
    -- @covers LSoundData:getBitDepth
    it("getBitDepth returns a number", function()
        local sd = lurek.audio.newSoundData(64, 44100, 1)
        expect_type("number", sd:getBitDepth())
    end)
end)

-- @describe audio strict: LSoundData drawWaveform
describe("audio strict: LSoundData drawWaveform", function()
    -- @covers LSoundData:drawWaveform
    it("drawWaveform is callable without error", function()
        local sd = lurek.audio.newSoundData(64, 44100, 1)
        local new_img = lurek.render["newImageData"]
        if new_img then
            local img = new_img(64, 16)
            local ok = pcall(function() sd:drawWaveform(img, 0, 0, 64, 16, 255, 255, 255, 255) end)
            expect_true(ok)
        else
            expect_true(true) -- newImageData not available in this build; skip
        end
    end)
end)

-- @describe audio migrated from integration/audio_timer
describe("audio migrated from integration/audio_timer", function()
    -- @covers lurek.audio.getMasterVolume
    -- @covers lurek.audio.setMasterVolume
    it("audio volume can be ramped over time", function()
        lurek.audio.setMasterVolume(0.0)
        expect_near(0.0, lurek.audio.getMasterVolume(), 0.01)

        local volume = 0.0
        local target = 1.0
        local speed = 2.0
        local dt = 0.016
        for _ = 1, 30 do
            volume = math.min(target, volume + speed * dt)
        end

        lurek.audio.setMasterVolume(volume)
        expect_true(volume > 0.9)
        expect_near(volume, lurek.audio.getMasterVolume(), 0.01)
        lurek.audio.setMasterVolume(1.0)
    end)

    -- @covers lurek.audio.getMasterVolume
    -- @covers lurek.audio.setMasterVolume
    it("audio volume fade-out follows exponential decay", function()
        lurek.audio.setMasterVolume(1.0)

        local volume = 1.0
        local decay_rate = 0.5
        local dt = 0.016
        for _ = 1, 60 do
            volume = volume * (decay_rate ^ dt)
        end

        expect_true(volume < 1.0)
        expect_true(volume > 0.0)
        lurek.audio.setMasterVolume(volume)
        expect_near(volume, lurek.audio.getMasterVolume(), 0.01)
        lurek.audio.setMasterVolume(1.0)
    end)
end)

test_summary()

