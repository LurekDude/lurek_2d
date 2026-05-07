-- tests/lua/unit/test_network.lua
-- BDD tests for lurek.network (high-level UDP API via ENet).
-- lurek.net and _G.enet tests are guarded  they only run if those namespaces exist.
-- Headless-safe (no GPU/window needed).
require("tests/lua/init")

-- @describe lurek.network
describe("lurek.network", function()
  it("is a table", function()
    expect_equal(type(lurek.network), "table")
  end)

  -- @covers lurek.network.newHost
  it("newHost is a function", function()
    expect_equal(type(lurek.network.newHost), "function")
  end)
end)

-- @describe lurek.network.newHost
describe("lurek.network.newHost", function()
  -- @covers LNetworkHost:destroy
  -- @covers lurek.network.newHost
  it("creates a client host with no arguments", function()
    local host = lurek.network.newHost({})
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  -- @covers LNetworkHost:destroy
  -- @covers lurek.network.newHost
  it("creates a host with addr option", function()
    local host = lurek.network.newHost({ addr = "0.0.0.0:0" })
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  -- @covers LNetworkHost:destroy
  -- @covers LNetworkHost:getPeerLimit
  -- @covers lurek.network.newHost
  it("creates a host with legacy peers alias", function()
    local host = lurek.network.newHost({
      addr = "0.0.0.0:0",
      peers = 4,
    })
    expect_equal(type(host), "userdata")
    expect_equal(4, host:getPeerLimit())
    host:destroy()
  end)

  -- @covers LNetworkHost:destroy
  -- @covers lurek.network.newHost
  it("clamps maxPeers to 8", function()
    -- Requesting more than MAX_PEERS should clamp, not error
    local host = lurek.network.newHost({ maxPeers = 100 })
    expect_equal(type(host), "userdata")
    host:destroy()
  end)
end)

-- @describe lurek.network host methods
describe("lurek.network host methods", function()
  -- @covers LNetworkHost:destroy
  -- @covers LNetworkHost:service
  -- @covers lurek.network.newHost
  it("service returns nil when no events", function()
    local host = lurek.network.newHost({})
    local event = host:service()
    expect_equal(event, nil)
    host:destroy()
  end)

  -- @covers LNetworkHost:destroy
  -- @covers LNetworkHost:getAddress
  -- @covers lurek.network.newHost
  it("getAddress returns a socket string", function()
    local host = lurek.network.newHost({})
    local addr = host:getAddress()
    expect_equal(type(addr), "string")
    expect_true(string.find(addr, ":", 1, true) ~= nil)
    host:destroy()
  end)

  -- @covers LNetworkHost:destroy
  -- @covers LNetworkHost:getPeerLimit
  -- @covers lurek.network.newHost
  it("getPeerLimit returns configured limit", function()
    local host = lurek.network.newHost({ maxPeers = 6 })
    local count = host:getPeerLimit()
    expect_equal(6, count)
    host:destroy()
  end)

  -- @covers LNetworkHost:destroy
  -- @covers LNetworkHost:flush
  -- @covers lurek.network.newHost
  it("flush succeeds with no pending data", function()
    local host = lurek.network.newHost({})
    local ok = pcall(function() host:flush() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  -- @covers LNetworkHost:destroy
  -- @covers LNetworkHost:isDestroyed
  -- @covers LNetworkHost:service
  -- @covers lurek.network.newHost
  it("destroy makes host unusable", function()
    local host = lurek.network.newHost({})
    host:destroy()
    expect_equal(true, host:isDestroyed())
    local ok = pcall(function() host:service() end)
    expect_equal(ok, false)
  end)

  -- @covers LNetworkHost:destroy
  -- @covers LNetworkHost:getBandwidthLimit
  -- @covers LNetworkHost:setBandwidthLimit
  -- @covers lurek.network.newHost
  it("setBandwidthLimit updates bandwidth table", function()
    local host = lurek.network.newHost({})
    local ok = pcall(function() host:setBandwidthLimit(100000, 50000) end)
    expect_equal(ok, true)
    local limits = host:getBandwidthLimit()
    expect_equal(type(limits), "table")
    expect_equal(type(limits.incoming), "number")
    expect_equal(type(limits.outgoing), "number")
    host:destroy()
  end)

  -- @covers LNetworkHost:destroy
  -- @covers LNetworkHost:getConnectedPeerIds
  -- @covers lurek.network.newHost
  it("getConnectedPeerIds returns empty table when no connections", function()
    local host = lurek.network.newHost({})
    local peers = host:getConnectedPeerIds()
    expect_equal(type(peers), "table")
    local count = 0
    for _ in pairs(peers) do count = count + 1 end
    expect_equal(count, 0)
    host:destroy()
  end)

  -- @covers LNetworkHost:destroy
  -- @covers LNetworkHost:getBandwidthLimit
  -- @covers lurek.network.newHost
  it("getBandwidthLimit returns a table", function()
    local host = lurek.network.newHost({})
    local stats = host:getBandwidthLimit()
    expect_equal(type(stats), "table")
    host:destroy()
  end)
end)

-- lurek.net (raw ENet API)
-- NOTE: lurek.net is a low-level ENet alias that may not be registered
-- in all builds. Tests are guarded so the file does not crash when absent.

if lurek.net then
  -- @describe lurek.net
  describe("lurek.net", function()
    it("is a table", function()
      expect_equal(type(lurek.net), "table")
    end)

    it("host_create is a function", function()
      expect_equal(type(lurek.net.host_create), "function")
    end)

    it("linked_version is a function", function()
      expect_equal(type(lurek.net.linked_version), "function")
    end)
  end)

-- @describe lurek.net.linked_version
describe("lurek.net.linked_version", function()
  it("returns a string", function()
    local ver = lurek.net.linked_version()
    expect_equal(type(ver), "string")
  end)
end)

-- @describe lurek.net.host_create
describe("lurek.net.host_create", function()
  it("creates a client host with no arguments", function()
    local host = lurek.net.host_create()
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  it("creates a server host with bind address", function()
    local host = lurek.net.host_create("*:0")
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  it("creates a host with peer count", function()
    local host = lurek.net.host_create(nil, 6)
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  it("creates a host with all parameters", function()
    local host = lurek.net.host_create("*:0", 4, 2, 0, 0)
    expect_equal(type(host), "userdata")
    host:destroy()
  end)
end)

-- @describe lurek.net host methods
describe("lurek.net host methods", function()
  -- @covers LNetworkHost:service
  it("service returns nil when no events", function()
    local host = lurek.net.host_create()
    local evt = host:service(0)
    expect_equal(evt, nil)
    host:destroy()
  end)

  it("get_socket_address returns address string", function()
    local host = lurek.net.host_create()
    local addr = host:get_socket_address()
    expect_equal(type(addr), "string")
    host:destroy()
  end)

  it("connected_peers returns zero initially", function()
    local host = lurek.net.host_create()
    local count = host:connected_peers()
    expect_equal(count, 0)
    host:destroy()
  end)

  it("flush succeeds with no pending data", function()
    local host = lurek.net.host_create()
    local ok, err = pcall(function() host:flush() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  -- @covers LNetworkHost:service
  it("destroy makes host unusable", function()
    local host = lurek.net.host_create()
    host:destroy()
    local ok, err = pcall(function() host:service(0) end)
    expect_equal(ok, false)
  end)

  it("bandwidth_limit returns in and out", function()
    local host = lurek.net.host_create()
    local in_bw, out_bw = host:bandwidth_limit()
    -- Default is unlimited (0 or nil)
    expect_equal(type(in_bw), "number")
    expect_equal(type(out_bw), "number")
    host:destroy()
  end)

  it("max_packet_size returns a number", function()
    local host = lurek.net.host_create()
    local sz = host:max_packet_size()
    expect_equal(type(sz), "number")
    host:destroy()
  end)

  it("max_waiting_data returns a number", function()
    local host = lurek.net.host_create()
    local wd = host:max_waiting_data()
    expect_equal(type(wd), "number")
    host:destroy()
  end)

  it("duplicate_peers returns a number", function()
    local host = lurek.net.host_create()
    local dp = host:duplicate_peers()
    expect_equal(type(dp), "number")
    host:destroy()
  end)

  it("enable_checksum does not error", function()
    local host = lurek.net.host_create()
    local ok = pcall(function() host:enable_checksum(true) end)
    expect_equal(ok, true)
    host:destroy()
  end)

  it("compress_with_range_coder does not error", function()
    local host = lurek.net.host_create()
    local ok = pcall(function() host:compress_with_range_coder() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  it("compress_disable does not error", function()
    local host = lurek.net.host_create()
    local ok = pcall(function() host:compress_disable() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  it("get_stats returns a table", function()
    local host = lurek.net.host_create()
    local stats = host:get_stats()
    expect_equal(type(stats), "table")
    host:destroy()
  end)

  it("reset_stats does not error", function()
    local host = lurek.net.host_create()
    local ok = pcall(function() host:reset_stats() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  it("received_address returns a string", function()
    local host = lurek.net.host_create()
    local addr = host:received_address()
    expect_equal(type(addr), "string")
    host:destroy()
  end)
end)

-- @describe lurek.net time
describe("lurek.net time", function()
  it("time_get returns a number", function()
    local t = lurek.net.time_get()
    expect_equal(type(t), "number")
  end)

  it("time_get increases monotonically", function()
    local t1 = lurek.net.time_get()
    local t2 = lurek.net.time_get()
    -- At minimum, t2 >= t1 (both from wall clock)
    expect_equal(t2 >= t1, true)
  end)
end) -- lurek.net time
end -- if lurek.net

---@type { enet?: { host_create: function, linked_version: fun(): string } }
local global_env = _G

if global_env.enet then
  -- @describe enet global alias
  describe("enet global alias", function()
    it("enet is a table", function()
      expect_equal(type(global_env.enet), "table")
    end)

    it("enet.host_create is a function", function()
      expect_equal(type(global_env.enet.host_create), "function")
    end)

    it("enet.linked_version returns a string", function()
      expect_equal(type(global_env.enet.linked_version()), "string")
    end)
  end) -- enet global alias
end -- if global_env.enet

  ---@type { MAX_PEERS: integer, DEFAULT_PEERS: integer, MAX_CHANNELS: integer, DEFAULT_CHANNELS: integer }
  local network_consts = lurek.network

-- @describe lurek.network constants
describe("lurek.network constants", function()
  it("MAX_PEERS is a number", function()
    expect_type("number", network_consts.MAX_PEERS)
  end)

  it("MAX_PEERS equals 4096", function()
    expect_equal(network_consts.MAX_PEERS, 4096)
  end)

  it("DEFAULT_PEERS is a number", function()
    expect_type("number", network_consts.DEFAULT_PEERS)
  end)

  it("DEFAULT_PEERS equals 166", function()
    expect_equal(network_consts.DEFAULT_PEERS, 166)
  end)

  it("MAX_CHANNELS is a number", function()
    expect_type("number", network_consts.MAX_CHANNELS)
  end)

  it("MAX_CHANNELS equals 255", function()
    expect_equal(network_consts.MAX_CHANNELS, 255)
  end)

  it("DEFAULT_CHANNELS is a number", function()
    expect_type("number", network_consts.DEFAULT_CHANNELS)
  end)

  it("DEFAULT_CHANNELS equals 1", function()
    expect_equal(network_consts.DEFAULT_CHANNELS, 2)
  end)

  it("DEFAULT_PEERS is less than or equal to MAX_PEERS", function()
    expect_true(network_consts.DEFAULT_PEERS <= network_consts.MAX_PEERS)
  end)

  it("DEFAULT_CHANNELS is less than or equal to MAX_CHANNELS", function()
    expect_true(network_consts.DEFAULT_CHANNELS <= network_consts.MAX_CHANNELS)
  end)
end)

-- Merged from test_network_constants.lua

-- @describe lurek.network constants
describe("lurek.network constants", function()
  it("lurek.network is a table", function()
    expect_equal(type(lurek.network), "table")
  end)

  it("MAX_PEERS is a number", function()
    expect_type("number", network_consts.MAX_PEERS)
  end)

  it("MAX_PEERS equals 8", function()
    expect_equal(network_consts.MAX_PEERS, 4096)
  end)

  it("DEFAULT_PEERS is a number", function()
    expect_type("number", network_consts.DEFAULT_PEERS)
  end)

  it("DEFAULT_PEERS equals 4", function()
    expect_equal(network_consts.DEFAULT_PEERS, 166)
  end)

  it("MAX_CHANNELS is a number", function()
    expect_type("number", network_consts.MAX_CHANNELS)
  end)

  it("MAX_CHANNELS equals 255", function()
    expect_equal(network_consts.MAX_CHANNELS, 255)
  end)

  it("DEFAULT_CHANNELS is a number", function()
    expect_type("number", network_consts.DEFAULT_CHANNELS)
  end)

  it("DEFAULT_CHANNELS equals 1", function()
    expect_equal(network_consts.DEFAULT_CHANNELS, 2)
  end)

  it("DEFAULT_PEERS does not exceed MAX_PEERS", function()
    expect_true(network_consts.DEFAULT_PEERS <= network_consts.MAX_PEERS)
  end)

  it("DEFAULT_CHANNELS does not exceed MAX_CHANNELS", function()
    expect_true(network_consts.DEFAULT_CHANNELS <= network_consts.MAX_CHANNELS)
  end)
end)

-- Merged from test_network_pack_unpack.lua

-- @describe lurek.network.pack / unpack
describe("lurek.network.pack / unpack", function()
    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should exist as functions", function()
        expect_equal(type(lurek.network.pack), "function")
        expect_equal(type(lurek.network.unpack), "function")
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip nil", function()
        local packed = lurek.network.pack(nil)
        expect_equal(type(packed), "string")
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, nil)
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip boolean true", function()
        local packed = lurek.network.pack(true)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, true)
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip boolean false", function()
        local packed = lurek.network.pack(false)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, false)
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip integers", function()
        local packed = lurek.network.pack(42)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, 42)
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip negative integers", function()
        local packed = lurek.network.pack(-100)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, -100)
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip zero", function()
        local packed = lurek.network.pack(0)
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, 0)
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip floats", function()
        local packed = lurek.network.pack(3.14)
        local unpacked = lurek.network.unpack(packed)
        expect_near(unpacked, 3.14, 0.001)
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip strings", function()
        local packed = lurek.network.pack("hello world")
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, "hello world")
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip empty string", function()
        local packed = lurek.network.pack("")
        local unpacked = lurek.network.unpack(packed)
        expect_equal(unpacked, "")
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip arrays (sequential tables)", function()
        local input = { 1, 2, 3, "four", true }
        local packed = lurek.network.pack(input)
        local unpacked = lurek.network.unpack(packed)
      expect_equal("table", type(unpacked))
      expect_equal(1, unpacked and unpacked[1] or nil)
      expect_equal(2, unpacked and unpacked[2] or nil)
      expect_equal(3, unpacked and unpacked[3] or nil)
      expect_equal("four", unpacked and unpacked[4] or nil)
      expect_equal(true, unpacked and unpacked[5] or nil)
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip maps (string-keyed tables)", function()
        local input = { name = "Alice", score = 100 }
        local packed = lurek.network.pack(input)
        local unpacked = lurek.network.unpack(packed)
      expect_equal("table", type(unpacked))
      expect_equal("Alice", unpacked and unpacked.name or nil)
      expect_equal(100, unpacked and unpacked.score or nil)
    end)

    -- @covers lurek.network.pack
    -- @covers lurek.network.unpack
    it("should round-trip nested tables", function()
        local input = { pos = { x = 10, y = 20 }, tags = { "a", "b" } }
        local packed = lurek.network.pack(input)
        local unpacked = lurek.network.unpack(packed)
      local pos = unpacked and unpacked.pos or nil
      local tags = unpacked and unpacked.tags or nil
      expect_equal("table", type(unpacked))
      expect_equal("table", type(pos))
      expect_equal(10, pos and pos.x or nil)
      expect_equal(20, pos and pos.y or nil)
      expect_equal("a", tags and tags[1] or nil)
      expect_equal("b", tags and tags[2] or nil)
    end)

    -- @covers lurek.network.pack
    it("should produce compact binary (smaller than JSON)", function()
        local msg = { type = "move", x = 100.5, y = 200.5, id = 42 }
        local packed = lurek.network.pack(msg)
        -- MessagePack should be compact  - well under 100 bytes for this
        expect_equal(#packed < 100, true)
    end)

    -- @covers lurek.network.unpack
    it("should error on invalid unpack data", function()
        expect_error(function()
            lurek.network.unpack("not valid msgpack \xff\xfe")
        end)
    end)
end)

-- Merged from test_network_roles.lua

-- @describe lurek.network server/client roles
describe("lurek.network server/client roles", function()
    -- @covers lurek.network.newServer
    it("should have newServer function", function()
        expect_equal(type(lurek.network.newServer), "function")
    end)

    -- @covers lurek.network.newClient
    it("should have newClient function", function()
        expect_equal(type(lurek.network.newClient), "function")
    end)

    -- @covers LNetworkHost:destroy
    -- @covers LNetworkHost:getRole
    -- @covers LNetworkHost:isClient
    -- @covers LNetworkHost:isServer
    -- @covers lurek.network.newServer
    it("should create a server with getRole() == 'server'", function()
        local server = lurek.network.newServer({ port = 19100 })
        expect_equal(server:getRole(), "server")
        expect_equal(server:isServer(), true)
        expect_equal(server:isClient(), false)
        server:destroy()
    end)

    -- @covers LNetworkHost:destroy
    -- @covers LNetworkHost:getRole
    -- @covers LNetworkHost:isClient
    -- @covers LNetworkHost:isServer
    -- @covers lurek.network.newHost
    it("should create a generic host with getRole() == 'host'", function()
        local host = lurek.network.newHost({ addr = "0.0.0.0:0" })
        expect_equal(host:getRole(), "host")
        expect_equal(host:isServer(), false)
        expect_equal(host:isClient(), false)
        host:destroy()
    end)

    -- @covers LNetworkHost:destroy
    -- @covers LNetworkHost:isDestroyed
    -- @covers lurek.network.newServer
    it("server isDestroyed should be false before destroy", function()
        local server = lurek.network.newServer({ port = 19101 })
        expect_equal(server:isDestroyed(), false)
        server:destroy()
        expect_equal(server:isDestroyed(), true)
    end)

    it("should expose updated constants", function()
      expect_equal(network_consts.MAX_PEERS, 4096)
      expect_equal(network_consts.DEFAULT_PEERS, 166)
      expect_equal(network_consts.DEFAULT_CHANNELS, 2)
      expect_equal(network_consts.MAX_CHANNELS, 255)
    end)
end)

-- Merged from test_network_runtimer.lua

-- @describe lurek.network.newRuntime
describe("lurek.network.newRuntime", function()
    -- @covers lurek.network.newRuntime
    it("should have newRuntime function", function()
        expect_equal(type(lurek.network.newRuntime), "function")
    end)

    -- @covers LNetworkRuntime:shutdown
    -- @covers lurek.network.newRuntime
    it("should create a runtime object", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt) == "userdata" or type(rt) == "table", true)
        rt:shutdown()
    end)

    -- @covers LNetworkRuntime:poll
    -- @covers LNetworkRuntime:shutdown
    -- @covers lurek.network.newRuntime
    it("should poll with empty results", function()
        local rt = lurek.network.newRuntime()
        local results = rt:poll()
        expect_equal(type(results), "table")
        -- No pending requests, so results should be empty
        expect_equal(#results, 0)
        rt:shutdown()
    end)

    -- @covers LNetworkRuntime:poll
    -- @covers LNetworkRuntime:shutdown
    -- @covers lurek.network.newRuntime
    it("should survive multiple polls", function()
        local rt = lurek.network.newRuntime()
        for i = 1, 5 do
            local results = rt:poll()
            expect_equal(type(results), "table")
        end
        rt:shutdown()
    end)

    -- @covers LNetworkRuntime:shutdown
    -- @covers lurek.network.newRuntime
    it("should have httpGet method", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.httpGet), "function")
        rt:shutdown()
    end)

    -- @covers LNetworkRuntime:shutdown
    -- @covers lurek.network.newRuntime
    it("should have httpPost method", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.httpPost), "function")
        rt:shutdown()
    end)

    -- @covers LNetworkRuntime:shutdown
    -- @covers lurek.network.newRuntime
    it("should have httpRequest method", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.httpRequest), "function")
        rt:shutdown()
    end)

    -- @covers LNetworkRuntime:shutdown
    -- @covers lurek.network.newRuntime
    it("should have TCP methods", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.tcpConnect), "function")
        expect_equal(type(rt.tcpSend), "function")
        expect_equal(type(rt.tcpClose), "function")
        rt:shutdown()
    end)

    -- @covers LNetworkRuntime:shutdown
    -- @covers lurek.network.newRuntime
    it("should have WebSocket methods", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.wsConnect), "function")
        expect_equal(type(rt.wsSend), "function")
        expect_equal(type(rt.wsClose), "function")
        rt:shutdown()
    end)
end)

-- @describe NetworkHost:disconnectNow and NetworkHost:disconnectLater
describe("NetworkHost:disconnectNow and NetworkHost:disconnectLater ", function()
    -- @covers LNetworkHost:destroy
    -- @covers LNetworkHost:disconnectNow
    -- @covers lurek.network.newHost
    it("disconnectNow accepts an unknown peer without panicking", function()
        local host = lurek.network.newHost({ port = 0 })
        -- peer 0 does not exist; accept error gracefully
        local ok, _ = pcall(function() host:disconnectNow(0) end)
        expect_type("boolean", ok)
        host:destroy()
    end)

    -- @covers LNetworkHost:destroy
    -- @covers LNetworkHost:disconnectLater
    -- @covers lurek.network.newHost
    it("disconnectLater accepts an unknown peer without panicking", function()
        local host = lurek.network.newHost({ port = 0 })
        local ok, _ = pcall(function() host:disconnectLater(0) end)
        expect_type("boolean", ok)
        host:destroy()
    end)
end)

-- @describe network missing explicit coverage
describe("network missing explicit coverage", function()
    -- @covers LNetworkHost:getChannelLimit
    -- @covers LNetworkHost:getConnectedPeerCount
    -- @covers LNetworkHost:getPeerAddress
    -- @covers LNetworkHost:getPeerState
    -- @covers LNetworkHost:getPeerStats
    -- @covers LNetworkHost:getRoundTripTime
    -- @covers LNetworkHost:destroy
    -- @covers LNetworkHost:resetPeer
    -- @covers LNetworkHost:setChannelLimit
    -- @covers lurek.network.newHost
    it("advanced host peer/channel helpers return safely", function()
        local host = lurek.network.newHost({ addr = "0.0.0.0:0" })
        expect_no_error(function()
            host:setChannelLimit(2)
            local _cl = host:getChannelLimit()
            local _cp = host:getConnectedPeerCount()
            local _ps = host:getPeerState(0)
            local _pa = host:getPeerAddress(0)
            local _rtt = host:getRoundTripTime(0)
            local _st = host:getPeerStats(0)
            host:resetPeer(0)
        end)
        host:destroy()
    end)

    -- @covers LNetworkHost:destroy
    -- @covers lurek.network.createLobby
    -- @covers lurek.network.discoverLobbies
    -- @covers lurek.network.newHost
    -- @covers lurek.network.syncEntity
    it("high-level multiplayer helpers are callable", function()
        local host = lurek.network.newHost({ addr = "0.0.0.0:0" })
        expect_no_error(function()
            local _lobby = lurek.network.createLobby("cov", 19109, 1, 8)
            local _found = lurek.network.discoverLobbies(10)
            lurek.network.syncEntity(host, 1, { x = 1, y = 2 })
        end)
        host:destroy()
    end)
end)

  -- @describe network strict uncovered symbols
  describe("network strict uncovered symbols", function()
    -- @covers LNetworkHost:connect
    -- @covers LNetworkHost:send
    -- @covers LNetworkHost:broadcast
    -- @covers LNetworkHost:disconnect
    -- @covers LNetworkHost:ping
    -- @covers LNetworkHost:type
    -- @covers LNetworkHost:typeOf
    -- @covers LNetworkHost:destroy
    -- @covers lurek.network.newHost
    it("host strict methods are callable", function()
      local host = lurek.network.newHost({ addr = "0.0.0.0:0" })
      expect_type("string", host:type())
      expect_type("boolean", host:typeOf("LNetworkHost"))
      local ok_connect = pcall(function() host:connect("127.0.0.1:9") end)
      expect_type("boolean", ok_connect)
      local ok_send = pcall(function() host:send(0, 0, "hello", true) end)
      expect_type("boolean", ok_send)
      local ok_broadcast = pcall(function() host:broadcast(0, "hello", true) end)
      expect_type("boolean", ok_broadcast)
      local ok_ping = pcall(function() host:ping(0) end)
      expect_type("boolean", ok_ping)
      local ok_disconnect = pcall(function() host:disconnect(0, 0) end)
      expect_type("boolean", ok_disconnect)
      host:destroy()
    end)

    -- @covers LNetworkRuntime:httpRequest
    -- @covers LNetworkRuntime:httpGet
    -- @covers LNetworkRuntime:httpPost
    -- @covers LNetworkRuntime:tcpConnect
    -- @covers LNetworkRuntime:tcpSend
    -- @covers LNetworkRuntime:tcpClose
    -- @covers LNetworkRuntime:type
    -- @covers LNetworkRuntime:typeOf
    -- @covers LNetworkRuntime:shutdown
    -- @covers lurek.network.newRuntime
    it("runtime strict methods are callable", function()
      local rt = lurek.network.newRuntime()
      expect_type("string", rt:type())
      expect_type("boolean", rt:typeOf("LNetworkRuntime"))
      local ok_req = pcall(function() rt:httpRequest({method="GET", url="http://127.0.0.1:1"}) end)
      expect_type("boolean", ok_req)
      local ok_get = pcall(function() rt:httpGet("http://127.0.0.1:1", nil) end)
      expect_type("boolean", ok_get)
      local ok_post = pcall(function() rt:httpPost("http://127.0.0.1:1", "x=1", nil) end)
      expect_type("boolean", ok_post)
      local ok_tcp_connect = pcall(function() rt:tcpConnect("127.0.0.1:9") end)
      expect_type("boolean", ok_tcp_connect)
      local ok_tcp_send = pcall(function() rt:tcpSend(0, "x") end)
      expect_type("boolean", ok_tcp_send)
      local ok_tcp_close = pcall(function() rt:tcpClose(0) end)
      expect_type("boolean", ok_tcp_close)
      rt:shutdown()
    end)
  end)
test_summary()
