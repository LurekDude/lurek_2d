-- examples/network.lua
-- UDP networking via ENet for multiplayer games
-- API: lurek.network
--
-- Based on the ENet reliable UDP library. Supports peer-to-peer and
-- client/server topologies, multiple channels, bandwidth throttling,
-- and both reliable and unreliable packet delivery.
--
-- NOTE: lurek.network requires the network module enabled in conf.lua
function lurek.conf(t)
t.modules.network = true
end

--------------------------------------------------------------------------------
-- Creating a host
--------------------------------------------------------------------------------

-- Server: bind to a fixed port, accept up to 16 peers on 2 channels
local server = lurek.network.newHost({
    addr         = "0.0.0.0:27015",   -- bind address (host:port)
    peers        = 16,                 -- max simultaneous peers
    channels     = 2,                  -- channel count (default 1)
    inBandwidth  = 0,                  -- 0 = unlimited
    outBandwidth = 0,
})

-- Client: bind to any ephemeral port (no addr required)
local client = lurek.network.newHost({})
-- Or with a specific source address:
local client = lurek.network.newHost({ addr = "0.0.0.0:0" })

--------------------------------------------------------------------------------
-- Connecting (client side)
--------------------------------------------------------------------------------

-- connect(addr, channels?, data?) → peer_id
local peer_id = client:connect("127.0.0.1:27015", 2, 0)
-- peer_id is the local handle for this connection

--------------------------------------------------------------------------------
-- The event loop
--------------------------------------------------------------------------------

-- service() → event table or nil (non-blocking poll for ONE event)
-- Call per-frame inside lurek.process(dt)

lurek.process = function(dt)
    -- Server event pump
    local ev = server:service()
    while ev ~= nil do
        if ev.type == "connect" then
            print("peer connected:", ev.peer_id, "data:", ev.data)

        elseif ev.type == "disconnect" then
            print("peer disconnected:", ev.peer_id, "data:", ev.data)

        elseif ev.type == "receive" then
            -- ev.peer_id    — which peer sent it
            -- ev.channel_id — which channel (0-based)
            -- ev.data       — Lua string payload
            print("received from", ev.peer_id, "on ch", ev.channel_id, ":", ev.data)
        end

        ev = server:service()  -- poll next
    end

    -- Client event pump
    local cev = client:service()
    while cev ~= nil do
        if cev.type == "connect" then
            print("connected to server, peer_id =", cev.peer_id)
        elseif cev.type == "receive" then
            print("got from server:", cev.data)
        end
        cev = client:service()
    end
end

--------------------------------------------------------------------------------
-- Sending messages
--------------------------------------------------------------------------------

-- send(peer_id, channel_id, data_string, reliable?)
-- reliable defaults to true
server:send(peer_id, 0, "Hello, client!", true)
server:send(peer_id, 1, "Fast channel", false)   -- unreliable (channel 1)

-- broadcast(channel_id, data_string, reliable?) → sends to ALL connected peers
server:broadcast(0, "Hello everyone!", true)

-- Flush all pending sends immediately (normally automatic at frame end)
server:flush()

--------------------------------------------------------------------------------
-- Disconnecting
--------------------------------------------------------------------------------

-- Graceful: waits for pending packets to arrive, notifies remote side
server:disconnect(peer_id)              -- with 0 data
server:disconnect(peer_id, 42)          -- with data code

-- Immediate: no notification to remote
server:disconnectNow(peer_id, 0)

-- Deferred: notified after all queued outbound packets are sent
server:disconnectLater(peer_id, 0)

-- Reset: hard reset (no remote notification, no queued flush)
server:resetPeer(peer_id)

--------------------------------------------------------------------------------
-- Peer inspection
--------------------------------------------------------------------------------

-- Ping a peer to update RTT estimate
client:ping(peer_id)

local rtt = client:getRoundTripTime(peer_id)  -- milliseconds (number)
local state = server:getPeerState(peer_id)    -- "connected" | "disconnected" | ...
local addr  = server:getPeerAddress(peer_id)  -- "192.168.1.5:49152" or nil

-- Local bind address
local localAddr = server:getAddress()         -- "0.0.0.0:27015"

--------------------------------------------------------------------------------
-- Capacity and limits
--------------------------------------------------------------------------------

local peerLimit = server:getPeerLimit()       -- max peers
local chanLimit = server:getChannelLimit()    -- channels per peer
server:setChannelLimit(4)

local bw = server:getBandwidthLimit()
-- bw.incoming, bw.outgoing (bytes/sec, 0=unlimited)
server:setBandwidthLimit(128000, 64000)           -- 128 KB/s in, 64 KB/s out
server:setBandwidthLimit()                         -- restore unlimited

-- Count of currently connected peers
local n = server:getConnectedPeerCount()
local ids = server:getConnectedPeerIds()          -- table of peer_id integers
for _, pid in ipairs(ids) do
    print("connected:", pid)
end

--------------------------------------------------------------------------------
-- Peer statistics
--------------------------------------------------------------------------------

local stats = server:getPeerStats(peer_id)
-- stats.round_trip_time          — average RTT in ms
-- stats.round_trip_time_variance — RTT variance
-- stats.packets_sent             — total packets sent
-- stats.packets_lost             — total packets lost
-- stats.packet_loss              — packet loss rate (0-65536 = 0.0-100%)
-- stats.incoming_bandwidth       — bytes/sec received
-- stats.outgoing_bandwidth       — bytes/sec sent
-- stats.incoming_data_total      — total bytes received
-- stats.outgoing_data_total      — total bytes sent

local loss_pct = stats.packet_loss / 65536 * 100
print(string.format("RTT: %.1f ms | Loss: %.1f%% | Sent: %d",
    stats.round_trip_time, loss_pct, stats.packets_sent))

--------------------------------------------------------------------------------
-- Host lifecycle
--------------------------------------------------------------------------------

-- Destroy the host (closes the underlying socket)
server:destroy()
local gone = server:isDestroyed()   -- true

-- Good practice in luna cleanup:
lurek.quit = function()
    if not client:isDestroyed() then
        client:disconnect(peer_id)
        client:flush()
        client:destroy()
    end
    if not server:isDestroyed() then
        server:destroy()
    end
end

--------------------------------------------------------------------------------
-- Typical game architecture
--------------------------------------------------------------------------------

-- Server-authoritative pattern
local HOST_PORT = 27015

local net_server = nil
local net_client = nil
local my_peer_id = nil

local function startServer()
    net_server = lurek.network.newHost({ addr = "0.0.0.0:" .. HOST_PORT, peers = 8, channels = 2 })
    print("Server listening on :" .. HOST_PORT)
end

local function startClient(host_ip)
    net_client = lurek.network.newHost({})
    my_peer_id = net_client:connect(host_ip .. ":" .. HOST_PORT, 2)
    print("Connecting to", host_ip)
end

local function pumpServer()
    if not net_server then return end
    local ev = net_server:service()
    while ev do
        if ev.type == "connect" then
            -- Send welcome message
            net_server:send(ev.peer_id, 0, "welcome:servertime=" .. lurek.time.getTime())
        elseif ev.type == "receive" then
            -- Echo back (simple test)
            net_server:broadcast(0, "echo:" .. ev.data)
        end
        ev = net_server:service()
    end
end

local function pumpClient()
    if not net_client then return end
    local ev = net_client:service()
    while ev do
        if ev.type == "connect" then
            print("Connected!")
        elseif ev.type == "receive" then
            print("Server says:", ev.data)
        elseif ev.type == "disconnect" then
            print("Disconnected from server")
        end
        ev = net_client:service()
    end
end

lurek.process = function(dt)
    pumpServer()
    pumpClient()
end
