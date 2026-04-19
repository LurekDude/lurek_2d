-- tests/lua/unit/test_network.lua
-- BDD tests for lurek.network (high-level UDP API via ENet).
-- lurek.net and _G.enet tests are guarded â€” they only run if those namespaces exist.
-- Headless-safe (no GPU/window needed).
require("tests/lua/init")

-- @description Covers suite: lurek.network.
describe("lurek.network", function()
  -- @covers lurek.network
  -- @covers lurek.network.newHost
  -- @covers lurek.network.Host.service
  -- @covers lurek.network.Host.getAddress
  -- @covers lurek.network.Host.getPeerCount
  -- @covers lurek.network.Host.flush
  -- @covers lurek.network.Host.destroy
  -- @covers lurek.network.Host.setBandwidthLimit
  -- @covers lurek.network.Host.getPeers
  -- @covers lurek.network.Host.connect
  -- @covers lurek.network.Host.broadcast
  -- @description Verifies the high-level network namespace is available as a table.
  it("is a table", function()
    expect_equal(type(lurek.network), "table")
  end)

  -- @covers lurek.network.newHost
  -- @description Verifies the high-level newHost constructor is exposed.
  it("newHost is a function", function()
    expect_equal(type(lurek.network.newHost), "function")
  end)
end)

-- @description Covers suite: lurek.network.newHost.
describe("lurek.network.newHost", function()
  -- @covers lurek.network.newHost
  -- @description Verifies newHost can create a client host with default options.
  it("creates a client host with no arguments", function()
    local host = lurek.network.newHost()
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  -- @covers lurek.network.newHost
  -- @description Verifies newHost accepts a port option table.
  it("creates a host with port option", function()
    local host = lurek.network.newHost({ port = 0 })
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  -- @covers lurek.network.newHost
  -- @description Verifies newHost accepts the full option table surface.
  it("creates a host with all options", function()
    local host = lurek.network.newHost({
      port = 0,
      maxPeers = 4,
      channels = 2,
      inBandwidth = 0,
      outBandwidth = 0,
    })
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  -- @covers lurek.network.newHost
  -- @description Verifies maxPeers is clamped instead of rejecting oversized requests.
  it("clamps maxPeers to 8", function()
    -- Requesting more than MAX_PEERS should clamp, not error
    local host = lurek.network.newHost({ maxPeers = 100 })
    expect_equal(type(host), "userdata")
    host:destroy()
  end)
end)

-- @description Covers suite: lurek.network host methods.
describe("lurek.network host methods", function()
  -- @covers lurek.network.Host.service
  -- @description Verifies service returns nil when no events are pending.
  it("service returns nil when no events", function()
    local host = lurek.network.newHost()
    local event = host:service(0)
    expect_equal(event, nil)
    host:destroy()
  end)

  -- @covers lurek.network.Host.getAddress
  -- @description Verifies getAddress returns string host information and a numeric port.
  it("getAddress returns address and port", function()
    local host = lurek.network.newHost()
    local addr, port = host:getAddress()
    expect_equal(type(addr), "string")
    expect_equal(type(port), "number")
    host:destroy()
  end)

  -- @covers lurek.network.Host.getPeerCount
  -- @description Verifies getPeerCount reports the default peer limit.
  it("getPeerCount returns peer limit", function()
    local host = lurek.network.newHost()
    local count = host:getPeerCount()
    expect_equal(4, count)
    host:destroy()
  end)

  -- @covers lurek.network.Host.flush
  -- @description Verifies flush is safe when there is no pending data.
  it("flush succeeds with no pending data", function()
    local host = lurek.network.newHost()
    local ok, err = pcall(function() host:flush() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  -- @covers lurek.network.Host.destroy
  -- @description Verifies destroy invalidates the host for later method calls.
  it("destroy makes host unusable", function()
    local host = lurek.network.newHost()
    host:destroy()
    local ok, err = pcall(function() host:service(0) end)
    expect_equal(ok, false)
  end)

  -- @covers lurek.network.Host.setBandwidthLimit
  -- @description Verifies setBandwidthLimit accepts numeric limits without error.
  it("setBandwidthLimit does not error", function()
    local host = lurek.network.newHost()
    local ok, err = pcall(function() host:setBandwidthLimit(100000, 50000) end)
    expect_equal(ok, true)
    host:destroy()
  end)

  -- @covers lurek.network.Host.getPeers
  -- @description Verifies getPeers returns an empty table when there are no connections.
  it("getPeers returns empty table when no connections", function()
    local host = lurek.network.newHost()
    local peers = host:getPeers()
    expect_equal(type(peers), "table")
    local count = 0
    for _ in pairs(peers) do count = count + 1 end
    expect_equal(count, 0)
    host:destroy()
  end)

  -- @covers lurek.network.Host.getStats
  -- @description Verifies getStats returns a table payload.
  it("getStats returns a table", function()
    local host = lurek.network.newHost()
    local stats = host:getStats()
    expect_equal(type(stats), "table")
    host:destroy()
  end)
end)

-- â”€â”€ lurek.net (raw ENet API) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- NOTE: lurek.net is a low-level ENet alias that may not be registered
-- in all builds. Tests are guarded so the file does not crash when absent.

if lurek.net then
  -- @description Covers suite: lurek.net.
  describe("lurek.net", function()
    -- @covers lurek.net
    -- @description Verifies the low-level ENet alias is exposed when registered.
    it("is a table", function()
      expect_equal(type(lurek.net), "table")
    end)

    -- @covers lurek.net.host_create
    -- @description Verifies the low-level host_create constructor is exposed.
    it("host_create is a function", function()
      expect_equal(type(lurek.net.host_create), "function")
    end)

    -- @covers lurek.net.linked_version
    -- @description Verifies linked_version is exposed.
    it("linked_version is a function", function()
      expect_equal(type(lurek.net.linked_version), "function")
    end)
  end)

-- @description Covers suite: lurek.net.linked_version.
describe("lurek.net.linked_version", function()
  -- @covers lurek.net.linked_version
  -- @description Verifies linked_version returns a string.
  it("returns a string", function()
    local ver = lurek.net.linked_version()
    expect_equal(type(ver), "string")
  end)
end)

-- @description Covers suite: lurek.net.host_create.
describe("lurek.net.host_create", function()
  -- @covers lurek.net.host_create
  -- @description Verifies host_create can build a client host with default arguments.
  it("creates a client host with no arguments", function()
    local host = lurek.net.host_create()
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies host_create accepts a bind address string.
  it("creates a server host with bind address", function()
    local host = lurek.net.host_create("*:0")
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies host_create accepts an explicit peer count.
  it("creates a host with peer count", function()
    local host = lurek.net.host_create(nil, 6)
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies host_create accepts every low-level constructor parameter.
  it("creates a host with all parameters", function()
    local host = lurek.net.host_create("*:0", 4, 2, 0, 0)
    expect_equal(type(host), "userdata")
    host:destroy()
  end)
end)

-- @description Covers suite: lurek.net host methods.
describe("lurek.net host methods", function()
  -- @covers lurek.net.host_create
  -- @description Verifies service returns nil when there are no ENet events.
  it("service returns nil when no events", function()
    local host = lurek.net.host_create()
    local evt = host:service(0)
    expect_equal(evt, nil)
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies get_socket_address returns a string.
  it("get_socket_address returns address string", function()
    local host = lurek.net.host_create()
    local addr = host:get_socket_address()
    expect_equal(type(addr), "string")
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies connected_peers starts at zero.
  it("connected_peers returns zero initially", function()
    local host = lurek.net.host_create()
    local count = host:connected_peers()
    expect_equal(count, 0)
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies flush is safe without pending data.
  it("flush succeeds with no pending data", function()
    local host = lurek.net.host_create()
    local ok, err = pcall(function() host:flush() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies destroy invalidates the low-level host.
  it("destroy makes host unusable", function()
    local host = lurek.net.host_create()
    host:destroy()
    local ok, err = pcall(function() host:service(0) end)
    expect_equal(ok, false)
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies bandwidth_limit returns numeric in and out limits.
  it("bandwidth_limit returns in and out", function()
    local host = lurek.net.host_create()
    local in_bw, out_bw = host:bandwidth_limit()
    -- Default is unlimited (0 or nil)
    expect_equal(type(in_bw), "number")
    expect_equal(type(out_bw), "number")
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies max_packet_size returns a number.
  it("max_packet_size returns a number", function()
    local host = lurek.net.host_create()
    local sz = host:max_packet_size()
    expect_equal(type(sz), "number")
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies max_waiting_data returns a number.
  it("max_waiting_data returns a number", function()
    local host = lurek.net.host_create()
    local wd = host:max_waiting_data()
    expect_equal(type(wd), "number")
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies duplicate_peers returns a number.
  it("duplicate_peers returns a number", function()
    local host = lurek.net.host_create()
    local dp = host:duplicate_peers()
    expect_equal(type(dp), "number")
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies enable_checksum accepts a boolean without error.
  it("enable_checksum does not error", function()
    local host = lurek.net.host_create()
    local ok = pcall(function() host:enable_checksum(true) end)
    expect_equal(ok, true)
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies compress_with_range_coder is callable without error.
  it("compress_with_range_coder does not error", function()
    local host = lurek.net.host_create()
    local ok = pcall(function() host:compress_with_range_coder() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies compress_disable is callable without error.
  it("compress_disable does not error", function()
    local host = lurek.net.host_create()
    local ok = pcall(function() host:compress_disable() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies get_stats returns a table.
  it("get_stats returns a table", function()
    local host = lurek.net.host_create()
    local stats = host:get_stats()
    expect_equal(type(stats), "table")
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies reset_stats can be called without error.
  it("reset_stats does not error", function()
    local host = lurek.net.host_create()
    local ok = pcall(function() host:reset_stats() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  -- @covers lurek.net.host_create
  -- @description Verifies received_address returns a string.
  it("received_address returns a string", function()
    local host = lurek.net.host_create()
    local addr = host:received_address()
    expect_equal(type(addr), "string")
    host:destroy()
  end)
end)

-- @description Covers suite: lurek.net time.
describe("lurek.net time", function()
  -- @covers lurek.net.time_get
  -- @description Verifies time_get returns a number.
  it("time_get returns a number", function()
    local t = lurek.net.time_get()
    expect_equal(type(t), "number")
  end)

  -- @covers lurek.net.time_get
  -- @description Verifies time_get is monotonic across consecutive calls.
  it("time_get increases monotonically", function()
    local t1 = lurek.net.time_get()
    local t2 = lurek.net.time_get()
    -- At minimum, t2 >= t1 (both from wall clock)
    expect_equal(t2 >= t1, true)
  end)
end) -- lurek.net time
end -- if lurek.net

if _G.enet then
  -- @description Covers suite: enet global alias.
  describe("enet global alias", function()
    -- @covers enet
    -- @description Verifies the global enet alias is available when registered.
    it("enet is a table", function()
      expect_equal(type(_G.enet), "table")
    end)

    -- @covers enet.host_create
    -- @description Verifies the global enet alias exposes host_create.
    it("enet.host_create is a function", function()
      expect_equal(type(_G.enet.host_create), "function")
    end)

    -- @covers enet.linked_version
    -- @description Verifies the global enet alias exposes linked_version.
    it("enet.linked_version returns a string", function()
      expect_equal(type(_G.enet.linked_version()), "string")
    end)
  end) -- enet global alias
end -- if _G.enet

-- @description Covers suite: lurek.network constants.
describe("lurek.network constants", function()
  -- @covers lurek.network.MAX_PEERS
  -- @description Verifies MAX_PEERS is numeric in the high-level namespace.
  it("MAX_PEERS is a number", function()
    expect_type("number", lurek.network.MAX_PEERS)
  end)

  -- @covers lurek.network.MAX_PEERS
  -- @description Verifies MAX_PEERS equals 8.
  it("MAX_PEERS equals 8", function()
    expect_equal(lurek.network.MAX_PEERS, 8)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  -- @description Verifies DEFAULT_PEERS is numeric.
  it("DEFAULT_PEERS is a number", function()
    expect_type("number", lurek.network.DEFAULT_PEERS)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  -- @description Verifies DEFAULT_PEERS equals 4.
  it("DEFAULT_PEERS equals 4", function()
    expect_equal(lurek.network.DEFAULT_PEERS, 4)
  end)

  -- @covers lurek.network.MAX_CHANNELS
  -- @description Verifies MAX_CHANNELS is numeric.
  it("MAX_CHANNELS is a number", function()
    expect_type("number", lurek.network.MAX_CHANNELS)
  end)

  -- @covers lurek.network.MAX_CHANNELS
  -- @description Verifies MAX_CHANNELS equals 255.
  it("MAX_CHANNELS equals 255", function()
    expect_equal(lurek.network.MAX_CHANNELS, 255)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  -- @description Verifies DEFAULT_CHANNELS is numeric.
  it("DEFAULT_CHANNELS is a number", function()
    expect_type("number", lurek.network.DEFAULT_CHANNELS)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  -- @description Verifies DEFAULT_CHANNELS equals 1.
  it("DEFAULT_CHANNELS equals 1", function()
    expect_equal(lurek.network.DEFAULT_CHANNELS, 1)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  -- @description Verifies DEFAULT_PEERS does not exceed MAX_PEERS.
  it("DEFAULT_PEERS is less than or equal to MAX_PEERS", function()
    expect_true(lurek.network.DEFAULT_PEERS <= lurek.network.MAX_PEERS)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  -- @description Verifies DEFAULT_CHANNELS does not exceed MAX_CHANNELS.
  it("DEFAULT_CHANNELS is less than or equal to MAX_CHANNELS", function()
    expect_true(lurek.network.DEFAULT_CHANNELS <= lurek.network.MAX_CHANNELS)
  end)
end)

-- ── Merged from test_network_constants.lua ──────────────────────────────

-- @description Covers suite: lurek.network constants.
describe("lurek.network constants", function()
  -- @covers lurek.network
  -- @covers lurek.network.MAX_PEERS
  -- @covers lurek.network.DEFAULT_PEERS
  -- @covers lurek.network.MAX_CHANNELS
  -- @covers lurek.network.DEFAULT_CHANNELS
  -- @description Verifies the network namespace is registered as a Lua table before constant lookups run.
  it("lurek.network is a table", function()
    expect_equal(type(lurek.network), "table")
  end)

  -- @covers lurek.network.MAX_PEERS
  -- @description Verifies MAX_PEERS is exported as a numeric constant.
  it("MAX_PEERS is a number", function()
    expect_type("number", lurek.network.MAX_PEERS)
  end)

  -- @covers lurek.network.MAX_PEERS
  -- @description Verifies MAX_PEERS matches the documented hard limit of 8 peers.
  it("MAX_PEERS equals 8", function()
    expect_equal(lurek.network.MAX_PEERS, 8)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  -- @description Verifies DEFAULT_PEERS is exported as a numeric constant.
  it("DEFAULT_PEERS is a number", function()
    expect_type("number", lurek.network.DEFAULT_PEERS)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  -- @description Verifies DEFAULT_PEERS keeps the expected default peer count of 4.
  it("DEFAULT_PEERS equals 4", function()
    expect_equal(lurek.network.DEFAULT_PEERS, 4)
  end)

  -- @covers lurek.network.MAX_CHANNELS
  -- @description Verifies MAX_CHANNELS is exported as a numeric constant.
  it("MAX_CHANNELS is a number", function()
    expect_type("number", lurek.network.MAX_CHANNELS)
  end)

  -- @covers lurek.network.MAX_CHANNELS
  -- @description Verifies MAX_CHANNELS matches the documented ENet ceiling of 255.
  it("MAX_CHANNELS equals 255", function()
    expect_equal(lurek.network.MAX_CHANNELS, 255)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  -- @description Verifies DEFAULT_CHANNELS is exported as a numeric constant.
  it("DEFAULT_CHANNELS is a number", function()
    expect_type("number", lurek.network.DEFAULT_CHANNELS)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  -- @description Verifies DEFAULT_CHANNELS keeps the default single-channel configuration.
  it("DEFAULT_CHANNELS equals 1", function()
    expect_equal(lurek.network.DEFAULT_CHANNELS, 1)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  -- @description Verifies the default peer count never exceeds the advertised peer cap.
  it("DEFAULT_PEERS does not exceed MAX_PEERS", function()
    expect_true(lurek.network.DEFAULT_PEERS <= lurek.network.MAX_PEERS)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  -- @description Verifies the default channel count stays within the exported channel limit.
  it("DEFAULT_CHANNELS does not exceed MAX_CHANNELS", function()
    expect_true(lurek.network.DEFAULT_CHANNELS <= lurek.network.MAX_CHANNELS)
  end)
end)

-- ── Merged from test_network_pack_unpack.lua ────────────────────────────

describe("lurek.network.pack / unpack", function()
    it("should exist as functions", function()
        expect_equal(type(lurek.network.pack), "function")
        expect_equal(type(lurek.network.unpack), "function")
    end)

    it("should round-trip nil", function()
        local packed = lurek.network.pack(nil)
        expect_equal(type(packed), "string")
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, nil)
    end)

    it("should round-trip boolean true", function()
        local packed = lurek.network.pack(true)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, true)
    end)

    it("should round-trip boolean false", function()
        local packed = lurek.network.pack(false)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, false)
    end)

    it("should round-trip integers", function()
        local packed = lurek.network.pack(42)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, 42)
    end)

    it("should round-trip negative integers", function()
        local packed = lurek.network.pack(-100)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, -100)
    end)

    it("should round-trip zero", function()
        local packed = lurek.network.pack(0)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, 0)
    end)

    it("should round-trip floats", function()
        local packed = lurek.network.pack(3.14)
        local unpacked = lurek.network.unpack(packed)
        expect_near(unpacked, 3.14, 0.001)
    end)

    it("should round-trip strings", function()
        local packed = lurek.network.pack("hello world")
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, "hello world")
    end)

    it("should round-trip empty string", function()
        local packed = lurek.network.pack("")
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, "")
    end)

    it("should round-trip arrays (sequential tables)", function()
        local input = { 1, 2, 3, "four", true }
        local packed = lurek.network.pack(input)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(type(unpacked), "table")
        expect_equal(unpacked[1], 1)
        expect_equal(unpacked[2], 2)
        expect_equal(unpacked[3], 3)
        expect_equal(unpacked[4], "four")
        expect_equal(unpacked[5], true)
    end)

    it("should round-trip maps (string-keyed tables)", function()
        local input = { name = "Alice", score = 100 }
        local packed = lurek.network.pack(input)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(type(unpacked), "table")
        expect_equal(unpacked.name, "Alice")
        expect_equal(unpacked.score, 100)
    end)

    it("should round-trip nested tables", function()
        local input = { pos = { x = 10, y = 20 }, tags = { "a", "b" } }
        local packed = lurek.network.pack(input)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(type(unpacked), "table")
        expect_equal(type(unpacked.pos), "table")
        expect_equal(unpacked.pos.x, 10)
        expect_equal(unpacked.pos.y, 20)
        expect_equal(unpacked.tags[1], "a")
        expect_equal(unpacked.tags[2], "b")
    end)

    it("should produce compact binary (smaller than JSON)", function()
        local msg = { type = "move", x = 100.5, y = 200.5, id = 42 }
        local packed = lurek.network.pack(msg)
        -- MessagePack should be compact — well under 100 bytes for this
        expect_equal(#packed < 100, true)
    end)

    it("should error on invalid unpack data", function()
        expect_error(function()
            lurek.network.unpack("not valid msgpack \xff\xfe")
        end)
    end)
end)

-- ── Merged from test_network_roles.lua ──────────────────────────────────

describe("lurek.network server/client roles", function()
    it("should have newServer function", function()
        expect_equal(type(lurek.network.newServer), "function")
    end)

    it("should have newClient function", function()
        expect_equal(type(lurek.network.newClient), "function")
    end)

    it("should create a server with getRole() == 'server'", function()
        local server = lurek.network.newServer({ port = 19100 })
        expect_equal(server:getRole(), "server")
        expect_equal(server:isServer(), true)
        expect_equal(server:isClient(), false)
        server:destroy()
    end)

    it("should create a generic host with getRole() == 'host'", function()
        local host = lurek.network.newHost({ addr = "0.0.0.0:0" })
        expect_equal(host:getRole(), "host")
        expect_equal(host:isServer(), false)
        expect_equal(host:isClient(), false)
        host:destroy()
    end)

    it("server isDestroyed should be false before destroy", function()
        local server = lurek.network.newServer({ port = 19101 })
        expect_equal(server:isDestroyed(), false)
        server:destroy()
        expect_equal(server:isDestroyed(), true)
    end)

    it("should expose updated constants", function()
        expect_equal(lurek.network.MAX_PEERS, 4096)
        expect_equal(lurek.network.DEFAULT_PEERS, 16)
        expect_equal(lurek.network.DEFAULT_CHANNELS, 2)
        expect_equal(lurek.network.MAX_CHANNELS, 255)
    end)
end)

-- ── Merged from test_network_runtime.lua ────────────────────────────────

describe("lurek.network.newRuntime", function()
    it("should have newRuntime function", function()
        expect_equal(type(lurek.network.newRuntime), "function")
    end)

    it("should create a runtime object", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt) == "userdata" or type(rt) == "table", true)
        rt:shutdown()
    end)

    it("should poll with empty results", function()
        local rt = lurek.network.newRuntime()
        local results = rt:poll()
        expect_equal(type(results), "table")
        -- No pending requests, so results should be empty
        expect_equal(#results, 0)
        rt:shutdown()
    end)

    it("should survive multiple polls", function()
        local rt = lurek.network.newRuntime()
        for i = 1, 5 do
            local results = rt:poll()
            expect_equal(type(results), "table")
        end
        rt:shutdown()
    end)

    it("should have httpGet method", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.httpGet), "function")
        rt:shutdown()
    end)

    it("should have httpPost method", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.httpPost), "function")
        rt:shutdown()
    end)

    it("should have httpRequest method", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.httpRequest), "function")
        rt:shutdown()
    end)

    it("should have TCP methods", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.tcpConnect), "function")
        expect_equal(type(rt.tcpSend), "function")
        expect_equal(type(rt.tcpClose), "function")
        rt:shutdown()
    end)

    it("should have WebSocket methods", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.wsConnect), "function")
        expect_equal(type(rt.wsSend), "function")
        expect_equal(type(rt.wsClose), "function")
        rt:shutdown()
    end)
end)

test_summary()
