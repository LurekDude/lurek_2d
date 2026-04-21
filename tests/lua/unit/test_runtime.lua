-- @testCategory unit
-- @description Unit tests for the lurek.runtime.* namespace (engine metadata API).

-- @description Tests for all lurek.runtime.* functions.
describe("lurek.runtime metadata", function()
  -- @covers lurek.runtime.getVersion
  -- @description Returns a non-empty version string.
  it("getVersion returns a non-empty string", function()
    local v = lurek.runtime.getVersion()
    expect_equal(type(v), "string")
    expect_true(#v > 0, "version must be non-empty")
  end)

  -- @covers lurek.runtime.getFrameBudget
  -- @description Returns approximately 16.67 ms for a 60 FPS target budget.
  it("getFrameBudget returns ~16.67 ms", function()
    local b = lurek.runtime.getFrameBudget()
    expect_equal(type(b), "number")
    expect_true(b > 16.0 and b < 17.0, "frame budget must be near 16.67 ms")
  end)

  -- @covers lurek.runtime.memoryUsage
  -- @description Returns a table with lua_bytes and lua_kb fields; both non-negative.
  it("memoryUsage returns lua_bytes and lua_kb", function()
    local m = lurek.runtime.memoryUsage()
    expect_equal(type(m), "table")
    expect_true(type(m.lua_bytes) == "number" and m.lua_bytes >= 0, "lua_bytes must be >= 0")
    expect_true(type(m.lua_kb) == "number" and m.lua_kb >= 0, "lua_kb must be >= 0")
  end)

  -- @covers lurek.runtime.platform
  -- @description Returns one of the expected platform strings.
  it("platform returns a known platform string", function()
    local p = lurek.runtime.platform()
    local valid = { windows = true, linux = true, macos = true, unknown = true }
    expect_true(valid[p] == true, "platform must be a known OS")
  end)

  -- @covers lurek.runtime.uptime
  -- @description Returns a non-negative number.
  it("uptime returns a non-negative number", function()
    local u = lurek.runtime.uptime()
    expect_equal(type(u), "number")
    expect_true(u >= 0, "uptime must be non-negative")
  end)

  -- @covers lurek.runtime.fps
  -- @description Returns a non-negative number.
  it("fps returns a non-negative number", function()
    local f = lurek.runtime.fps()
    expect_equal(type(f), "number")
    expect_true(f >= 0, "fps must be non-negative")
  end)

  -- @covers lurek.runtime.frameCount
  -- @description Returns a non-negative integer.
  it("frameCount returns a non-negative integer", function()
    local c = lurek.runtime.frameCount()
    expect_equal(type(c), "number")
    expect_true(c >= 0, "frameCount must be non-negative")
    expect_equal(math.floor(c), c)
  end)

  -- @covers lurek.runtime.isDebug
  -- @description Returns a boolean without error.
  it("isDebug returns a boolean", function()
    local d = lurek.runtime.isDebug()
    expect_equal(type(d), "boolean")
  end)
end)

test_summary()
