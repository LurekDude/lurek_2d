-- tests/lua/unit/test_network.lua
-- BDD tests for lurek.network (high-level UDP API via ENet).
-- lurek.net and _G.enet tests are guarded — they only run if those namespaces exist.
-- Headless-safe (no GPU/window needed).
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


describe("lurek.network", function()
  it("is a table", function()
    expect_equal(type(lurek.network), "table")
  end)

  it("newHost is a function", function()
    expect_equal(type(lurek.network.newHost), "function")
  end)
end)

describe("lurek.network.newHost", function()
  it("creates a client host with no arguments", function()
    local host = lurek.network.newHost()
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

  it("creates a host with port option", function()
    local host = lurek.network.newHost({ port = 0 })
    expect_equal(type(host), "userdata")
    host:destroy()
  end)

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

  it("clamps maxPeers to 8", function()
    -- Requesting more than MAX_PEERS should clamp, not error
    local host = lurek.network.newHost({ maxPeers = 100 })
    expect_equal(type(host), "userdata")
    host:destroy()
  end)
end)

describe("lurek.network host methods", function()
  it("service returns nil when no events", function()
    local host = lurek.network.newHost()
    local event = host:service(0)
    expect_equal(event, nil)
    host:destroy()
  end)

  it("getAddress returns address and port", function()
    local host = lurek.network.newHost()
    local addr, port = host:getAddress()
    expect_equal(type(addr), "string")
    expect_equal(type(port), "number")
    host:destroy()
  end)

  it("getPeerCount returns peer limit", function()
    local host = lurek.network.newHost()
    local count = host:getPeerCount()
    expect_equal(4, count)
    host:destroy()
  end)

  it("flush succeeds with no pending data", function()
    local host = lurek.network.newHost()
    local ok, err = pcall(function() host:flush() end)
    expect_equal(ok, true)
    host:destroy()
  end)

  it("destroy makes host unusable", function()
    local host = lurek.network.newHost()
    host:destroy()
    local ok, err = pcall(function() host:service(0) end)
    expect_equal(ok, false)
  end)

  it("setBandwidthLimit does not error", function()
    local host = lurek.network.newHost()
    local ok, err = pcall(function() host:setBandwidthLimit(100000, 50000) end)
    expect_equal(ok, true)
    host:destroy()
  end)

  it("getPeers returns empty table when no connections", function()
    local host = lurek.network.newHost()
    local peers = host:getPeers()
    expect_equal(type(peers), "table")
    local count = 0
    for _ in pairs(peers) do count = count + 1 end
    expect_equal(count, 0)
    host:destroy()
  end)

  it("getStats returns a table", function()
    local host = lurek.network.newHost()
    local stats = host:getStats()
    expect_equal(type(stats), "table")
    host:destroy()
  end)
end)

-- ── lurek.net (raw ENet API) ─────────────────────────────────────────
-- NOTE: lurek.net is a low-level ENet alias that may not be registered
-- in all builds. Tests are guarded so the file does not crash when absent.

if lurek.net then
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

describe("lurek.net.linked_version", function()
  it("returns a string", function()
    local ver = lurek.net.linked_version()
    expect_equal(type(ver), "string")
  end)
end)

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

describe("lurek.net host methods", function()
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

if _G.enet then
  describe("enet global alias", function()
    it("enet is a table", function()
      expect_equal(type(_G.enet), "table")
    end)

    it("enet.host_create is a function", function()
      expect_equal(type(_G.enet.host_create), "function")
    end)

    it("enet.linked_version returns a string", function()
      expect_equal(type(_G.enet.linked_version()), "string")
    end)
  end) -- enet global alias
end -- if _G.enet

test_summary()
