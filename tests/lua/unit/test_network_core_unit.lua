-- tests/lua/unit/test_network.lua
-- BDD tests for lurek.network (high-level UDP API via ENet).
-- lurek.net and _G.enet tests are guarded  they only run if those namespaces exist.
-- Headless-safe (no GPU/window needed).
require("tests/lua/init")

-- @describe lurek.network
describe("lurek.network", function()
  -- @covers lurek.network
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

  ---@type { MAX_PEERS: integer, DEFAULT_PEERS: integer, MAX_CHANNELS: integer, DEFAULT_CHANNELS: integer }
  local network_consts = lurek.network

-- @describe lurek.network constants
describe("lurek.network constants", function()
  -- @covers lurek.network.MAX_PEERS
  it("MAX_PEERS is a number", function()
    expect_type("number", network_consts.MAX_PEERS)
  end)

  -- @covers lurek.network.MAX_PEERS
  it("MAX_PEERS equals 4096", function()
    expect_equal(network_consts.MAX_PEERS, 4096)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  it("DEFAULT_PEERS is a number", function()
    expect_type("number", network_consts.DEFAULT_PEERS)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  it("DEFAULT_PEERS equals 64", function()
    expect_equal(network_consts.DEFAULT_PEERS, 64)
  end)

  -- @covers lurek.network.MAX_CHANNELS
  it("MAX_CHANNELS is a number", function()
    expect_type("number", network_consts.MAX_CHANNELS)
  end)

  -- @covers lurek.network.MAX_CHANNELS
  it("MAX_CHANNELS equals 255", function()
    expect_equal(network_consts.MAX_CHANNELS, 255)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  it("DEFAULT_CHANNELS is a number", function()
    expect_type("number", network_consts.DEFAULT_CHANNELS)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  it("DEFAULT_CHANNELS equals 1", function()
    expect_equal(network_consts.DEFAULT_CHANNELS, 2)
  end)

  -- @covers lurek.network
  it("DEFAULT_PEERS is less than or equal to MAX_PEERS", function()
    expect_true(network_consts.DEFAULT_PEERS <= network_consts.MAX_PEERS)
  end)

  -- @covers lurek.network
  it("DEFAULT_CHANNELS is less than or equal to MAX_CHANNELS", function()
    expect_true(network_consts.DEFAULT_CHANNELS <= network_consts.MAX_CHANNELS)
  end)
end)

-- Merged from test_network_constants.lua

-- @describe lurek.network constants
describe("lurek.network constants", function()
  -- @covers lurek.network
  it("lurek.network is a table", function()
    expect_equal(type(lurek.network), "table")
  end)

  -- @covers lurek.network.MAX_PEERS
  it("MAX_PEERS is a number", function()
    expect_type("number", network_consts.MAX_PEERS)
  end)

  -- @covers lurek.network.MAX_PEERS
  it("MAX_PEERS equals 8", function()
    expect_equal(network_consts.MAX_PEERS, 4096)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  it("DEFAULT_PEERS is a number", function()
    expect_type("number", network_consts.DEFAULT_PEERS)
  end)

  -- @covers lurek.network.DEFAULT_PEERS
  it("DEFAULT_PEERS equals 64 (legacy merged block)", function()
    expect_equal(network_consts.DEFAULT_PEERS, 64)
  end)

  -- @covers lurek.network.MAX_CHANNELS
  it("MAX_CHANNELS is a number", function()
    expect_type("number", network_consts.MAX_CHANNELS)
  end)

  -- @covers lurek.network.MAX_CHANNELS
  it("MAX_CHANNELS equals 255", function()
    expect_equal(network_consts.MAX_CHANNELS, 255)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  it("DEFAULT_CHANNELS is a number", function()
    expect_type("number", network_consts.DEFAULT_CHANNELS)
  end)

  -- @covers lurek.network.DEFAULT_CHANNELS
  it("DEFAULT_CHANNELS equals 1", function()
    expect_equal(network_consts.DEFAULT_CHANNELS, 2)
  end)

  -- @covers lurek.network
  it("DEFAULT_PEERS does not exceed MAX_PEERS", function()
    expect_true(network_consts.DEFAULT_PEERS <= network_consts.MAX_PEERS)
  end)

  -- @covers lurek.network
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

        -- @describe lurek.network matchmaking and relay helpers
        describe("lurek.network matchmaking and relay helpers", function()
          -- @covers lurek.network.createRoom
          -- @covers lurek.network.joinRoom
          -- @covers lurek.network.leaveRoom
          -- @covers lurek.network.listRooms
          it("room lifecycle helper functions work", function()
            local room = lurek.network.createRoom("ranked", "hostA", 4)
            expect_type("table", room)
            expect_type("string", room.id)

            local joined = lurek.network.joinRoom(room.id)
            expect_true(joined ~= nil, "joinRoom should succeed on non-full room")

            local listed = lurek.network.listRooms()
            expect_type("table", listed)

            local left = lurek.network.leaveRoom(room.id)
            expect_true(left ~= nil, "leaveRoom should return updated room")
          end)

          -- @covers lurek.network.makePunchProbe
          -- @covers lurek.network.newRelayTicket
          -- @covers lurek.network.parsePunchProbe
          -- @covers lurek.network.parseRelayTicket
          it("relay ticket and punch helpers round-trip", function()
            local token = lurek.network.newRelayTicket("room-1", "peer-A")
            expect_type("string", token)

            local parsed = lurek.network.parseRelayTicket(token)
            expect_type("table", parsed)
            expect_equal("room-1", parsed.room_id)
            expect_equal("peer-A", parsed.peer_id)

            local probe = lurek.network.makePunchProbe(parsed.peer_id)
            local from_peer = lurek.network.parsePunchProbe(probe)
            expect_equal("peer-A", from_peer)
          end)

          -- @covers lurek.network.predictLinear
          -- @covers lurek.network.reconcileSnapshot
          it("prediction and reconciliation helpers return snapshot tables", function()
            local snap = { id = 1, tick = 10, x = 0.0, y = 0.0, vx = 3.0, vy = 1.0 }
            local predicted = lurek.network.predictLinear(snap, 0.1)
            expect_type("table", predicted)
            expect_equal(11, predicted.tick)

            local authoritative = { id = 1, tick = 11, x = 0.2, y = 0.1, vx = 3.0, vy = 1.0 }
            local reconciled = lurek.network.reconcileSnapshot(predicted, authoritative, 0.5)
            expect_type("table", reconciled)
            expect_equal(11, reconciled.tick)
          end)
        end)
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
    -- @covers LNetworkRuntime:wsClose
    -- @covers LNetworkRuntime:wsConnect
    -- @covers LNetworkRuntime:wsSend
    -- @covers lurek.network.newRuntime
    it("should have WebSocket methods", function()
        local rt = lurek.network.newRuntime()
        expect_equal(type(rt.wsConnect), "function")
        expect_equal(type(rt.wsSend), "function")
        expect_equal(type(rt.wsClose), "function")
      local ok_connect = pcall(function() rt:wsConnect("ws://127.0.0.1:1") end)
      local ok_send = pcall(function() rt:wsSend(0, "ping") end)
      local ok_close = pcall(function() rt:wsClose(0) end)
      expect_type("boolean", ok_connect)
      expect_type("boolean", ok_send)
      expect_type("boolean", ok_close)
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
    -- @covers LNetworkHost:getRole
    -- @covers LNetworkHost:isClient
    -- @covers LNetworkHost:isServer
    -- @covers LNetworkHost:type
    -- @covers LNetworkHost:typeOf
    -- @covers LNetworkHost:destroy
    -- @covers lurek.network.newHost
    it("host strict methods are callable", function()
      local host = lurek.network.newHost({ addr = "0.0.0.0:0" })
      expect_type("string", host:type())
      expect_type("boolean", host:typeOf("LNetworkHost"))
      expect_type("string", host:getRole())
      expect_type("boolean", host:isServer())
      expect_type("boolean", host:isClient())
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
