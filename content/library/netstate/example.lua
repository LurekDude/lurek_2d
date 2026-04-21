--- Example usage for library.netstate.
-- Run with: lua content/library/netstate/example.lua
-- Demonstrates offline state tracking — set/get with versioning,
-- per-key change callbacks, dirty tracking, deterministic hashing for
-- desync detection, and optional JSON snapshot via lurek.serial.
-- No real network required: pass nil for the host argument.
-- @module example.netstate

local M = require("library.netstate")

-- ── 1. Create an authoritative state on the "server" peer ─────────────────────
local server = M.new(nil, { authority = true })
print(string.format("[example.netstate] server authority=%s key_count=%d",
    tostring(server:isAuthority()), server:getKeyCount()))

-- ── 2. Observe changes via global and per-key callbacks ───────────────────────
local global_changes = {}
server:onChange(function(key, value, old, peer)
    global_changes[#global_changes + 1] = key
    print(string.format("[example.netstate] (global) %s: %s -> %s (peer=%s)",
        key, tostring(old), tostring(value), tostring(peer)))
end)

server:onChanged("score", function(key, value, old)
    print(string.format("[example.netstate] (score-only) %s went from %s to %s",
        key, tostring(old), tostring(value)))
end)

-- ── 3. Authority writes — version increments per key ──────────────────────────
server:set("score",  0)
server:set("score", 10)
server:set("phase", "waiting")
server:set("phase", "playing")

print(string.format("[example.netstate] score v=%d phase v=%d total v=%d",
    server:getKeyVersion("score"),
    server:getKeyVersion("phase"),
    server:getVersion()))

-- ── 4. Dirty tracking — keys mutated since last sync() ────────────────────────
print(string.format("[example.netstate] dirty count=%d (would be broadcast on sync)",
    server:getDirtyCount()))

-- ── 5. Non-authority writes are rejected ──────────────────────────────────────
local client = M.new(nil, { authority = false })
local ok, err = client:set("score", 999)
print(string.format("[example.netstate] client write ok=%s err=%s",
    tostring(ok), tostring(err)))

-- ── 6. Deterministic hash for desync detection ────────────────────────────────
-- Build a second authoritative state and apply the SAME write history so
-- both per-key versions match (hashState mixes value + version, so an
-- identical replay is required for the hashes to agree).
local mirror = M.new(nil, { authority = true })
mirror:set("score",  0)
mirror:set("score", 10)
mirror:set("phase", "waiting")
mirror:set("phase", "playing")

local h1, h2 = server:hashState(), mirror:hashState()
print(string.format("[example.netstate] server hash=0x%08x mirror hash=0x%08x match=%s",
    h1, h2, tostring(h1 == h2)))

-- Mutate mirror and confirm hashes diverge
mirror:set("score", 11)
print(string.format("[example.netstate] after divergence match=%s",
    tostring(server:hashState() == mirror:hashState())))

-- ── 7. Optional JSON snapshot via lurek.serial (guarded) ───────────────────────
local lurek_ok = pcall(function() return lurek and lurek.serial end)
if lurek_ok and lurek and lurek.serial and lurek.serial.toJson then
    local s = server:toJson()
    print(string.format("[example.netstate] JSON snapshot len=%d", s and #s or 0))
else
    -- Manual hand-rolled snapshot for environments without lurek.serial.
    local all = server:getAll()
    local parts = {}
    for k, v in pairs(all) do
        parts[#parts + 1] = string.format("%s=%s", k, tostring(v))
    end
    table.sort(parts)
    print(string.format("[example.netstate] state snapshot: { %s }",
        table.concat(parts, ", ")))
end

print(string.format("[example.netstate] global change events captured: %s",
    table.concat(global_changes, ",")))

print("[example.netstate] done.")
