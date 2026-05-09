-- tests/lua/unit/test_net_core_unit.lua
-- Raw ENet alias unit tests for lurek.net.

-- @describe lurek.net availability
describe("lurek.net availability", function()
  -- @covers lurek.net
  it("module may be absent in some builds", function()
    local t = type(lurek.net)
    expect_true(t == "nil" or t == "table")
  end)
end)

-- NOTE: lurek.net may not be registered in all builds.
if lurek.net then
  -- @describe lurek.net
  describe("lurek.net", function()
    -- @covers lurek.net
    it("is a table", function()
      expect_equal(type(lurek.net), "table")
    end)

    -- @covers lurek.net.host_create
    it("host_create is a function", function()
      expect_equal(type(lurek.net.host_create), "function")
    end)

    -- @covers lurek.net.linked_version
    it("linked_version is a function", function()
      expect_equal(type(lurek.net.linked_version), "function")
    end)
  end)

  -- @describe lurek.net.linked_version
  describe("lurek.net.linked_version", function()
    -- @covers lurek.net.linked_version
    it("returns a string", function()
      local ver = lurek.net.linked_version()
      expect_equal(type(ver), "string")
    end)
  end)

  -- @describe lurek.net.host_create
  describe("lurek.net.host_create", function()
    -- @covers lurek.net.host_create
    it("creates a client host with no arguments", function()
      local host = lurek.net.host_create()
      expect_equal(type(host), "userdata")
      host:destroy()
    end)

    -- @covers lurek.net.host_create
    it("creates a server host with bind address", function()
      local host = lurek.net.host_create("*:0")
      expect_equal(type(host), "userdata")
      host:destroy()
    end)

    -- @covers lurek.net.host_create
    it("creates a host with peer count", function()
      local host = lurek.net.host_create(nil, 6)
      expect_equal(type(host), "userdata")
      host:destroy()
    end)

    -- @covers lurek.net.host_create
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
      local ev = host:service(0)
      expect_equal(ev, nil)
      host:destroy()
    end)

    -- @covers LNetworkHost:service
    it("service timeout argument accepted", function()
      local host = lurek.net.host_create()
      local ev = host:service(1)
      expect_equal(ev, nil)
      host:destroy()
    end)

    -- @covers LNetworkHost:flush
    it("flush is callable", function()
      local host = lurek.net.host_create()
      host:flush()
      host:destroy()
    end)

    -- @covers LNetworkHost:broadcast
    it("broadcast is callable", function()
      local host = lurek.net.host_create()
      host:broadcast(0, "hello")
      host:destroy()
    end)

    -- @covers LNetworkHost:check_events
    it("check_events returns nil when no events", function()
      local host = lurek.net.host_create()
      local ev = host:check_events()
      expect_equal(ev, nil)
      host:destroy()
    end)

    -- @covers LNetworkHost:received_address
    it("received_address returns a string", function()
      local host = lurek.net.host_create()
      local addr = host:received_address()
      expect_equal(type(addr), "string")
      host:destroy()
    end)
  end)

  -- @describe lurek.net time
  describe("lurek.net time", function()
    -- @covers lurek.net.time_get
    it("time_get returns a number", function()
      local t = lurek.net.time_get()
      expect_equal(type(t), "number")
    end)

    -- @covers lurek.net.time_get
    it("time_get increases monotonically", function()
      local t1 = lurek.net.time_get()
      local t2 = lurek.net.time_get()
      expect_equal(t2 >= t1, true)
    end)
  end)
end

---@type { enet?: { host_create: function, linked_version: fun(): string } }
local global_env = _G

if global_env.enet then
  -- @describe enet global alias
  describe("enet global alias", function()
    -- @covers enet
    it("enet is a table", function()
      expect_equal(type(global_env.enet), "table")
    end)

    -- @covers enet.host_create
    it("enet.host_create is a function", function()
      expect_equal(type(global_env.enet.host_create), "function")
    end)

    -- @covers enet.linked_version
    it("enet.linked_version returns a string", function()
      expect_equal(type(global_env.enet.linked_version()), "string")
    end)
  end)
end

test_summary()
