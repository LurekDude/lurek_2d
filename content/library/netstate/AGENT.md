# `netstate` — Agent Reference (Lunasome)

| Property       | Value                                                                                                    |
| -------------- | -------------------------------------------------------------------------------------------------------- |
| **Tier**       | Tier 3 — Lunasome (pure Lua, no Rust dependencies)                                                       |
| **Source**     | `library/netstate/init.lua`                                                                              |
| **Lua Tests**  | `tests/lua/library/test_library_netstate.lua`                                                            |
| **Depends on** | `lurek.network` (mandatory for online mode), `lurek.serial` (optional, `:toJson`), `lurek.log` (optional) |
| **Status**     | Full                                                                                                     |

## Summary

Pure-Lua **network state replication** with per-key versioning, authority
control, delta updates, and an optional turn-based protocol. Sits on top of
`lurek.network` and matches the on-the-wire format used by `library.lobby`
(MessagePack via `lurek.network.pack` / `:unpack`).

Designed to make turn-based and lockstep multiplayer games trivial:

- **Authority model** — exactly one peer (typically the server) owns writes;
  others apply deltas read-only. Per-key version numbers prevent stale
  replays under concurrent updates.
- **Delta sync** — call `:sync()` once per frame on the authority; only dirty
  keys go on the wire.
- **Full snapshots** — joining clients call `:requestFullState()` to receive
  the authority's current state (no built-in timeout — caller responsible).
- **Turn-based** — opt-in via `opts.turnBased = true`; rotating peer order,
  monotonic turn counter, broadcast on `:beginTurn()`.
- **Desync detection** — `:hashState()` returns a deterministic FNV-1a 32-bit
  digest of all replicated state for cheap divergence checks.

## Wire Format

State deltas (`action="delta"`), full snapshots (`action="full"`), full-state
requests (`action="full_request"`), and turn changes (`action="turn"`) are
encoded with `lurek.network.pack` (MessagePack — the canonical ENet payload
format). For human-readable persistence (snapshots written to disk) call
`:toJson()`, which delegates to `lurek.serial.toJson`.

## Architecture

```
M.new(host?, opts?) → NetState
  ├── _host           (lurek.network host or nil)
  ├── _channel        (ENet channel, default 0)
  ├── _authority      (boolean — only authority can :set)
  ├── _state          ({ key = {value, version, owner} })
  ├── _callbacks      ({ key = {fn, ...} })
  ├── _on_change      (global callback)
  ├── _dirty          (set of keys pending sync)
  ├── _dirty_order    (insertion-order list for maxDirtyKeys eviction)
  ├── _max_dirty      (cap on dirty set; nil = unlimited)
  ├── turn-based      (current_turn, turn_peer, turn_order, turn_index, on_turn)
  └── on_full_state_timeout (caller-implemented)

NetState methods:
  setAuthority(b) / isAuthority() → boolean
  set(key, value)             → ok, err? (authority only)
  get(key) / getKeyVersion(key) / hasKey(key) / remove(key)
  getAll() / getKeyCount() / getDirtyCount() / getVersion()
  onChange(fn) / onChanged(key, fn) / clearCallbacks(key)
  sync()                      (authority broadcast)
  poll() → array of {key, value, old_value, peer_id}
  requestFullState() → ok    (no built-in timeout)
  onFullStateTimeout(fn)     (caller-driven)
  hashState() → number       (FNV-1a 32-bit, desync detection)
  toJson() → string|nil      (uses lurek.serial.toJson when available)

Turn-based:
  setTurnOrder({peer_id, ...}) / beginTurn() / endTurn() / getCurrentTurn()
  getTurnPeer() / onTurn(fn) / isTurn(peer_id)

Logging:
  M.setLogging(enabled, custom_log?)   (delegates to lurek.log.debug)
```

## Source Files

| File                        | Purpose                                                                      |
| --------------------------- | ---------------------------------------------------------------------------- |
| `library/netstate/init.lua` | Full implementation — NetState manager, delta protocol, turn-based, hashing. |

## Key Types

| Type     | Constructor           | Purpose                    |
| -------- | --------------------- | -------------------------- |
| NetState | `M.new(host?, opts?)` | State replication manager. |

## Notes

- **Authority is required** to call `:set()`. Non-authority writes return
  `false, "not authority"` and are not silently dropped.
- **Per-key versioning** is monotonic per key (not global). Two peers
  modifying *different* keys at the same logical tick do not race.
- **Dirty key cap** (`opts.maxDirtyKeys`) evicts the oldest dirty key when
  exceeded — useful in scripted stress where the dirty set could grow
  unbounded between syncs.
- **`requestFullState` has no built-in timeout** — use `onFullStateTimeout` or
  `lurek.timer.Scheduler:after(...)` to drive a retry.
- **`:hashState()` is not a cryptographic hash** — it is a deterministic
  FNV-1a digest sufficient for desync detection. Will delegate to
  `lurek.data.hash` once that P4 lift candidate lands.
- **Wire format is MessagePack**, not JSON. Do not mix `:toJson()` payloads
  on the same channel.

## Lua API Reference

See LDoc-generated page: `docs/API/libs/netstate.md` (regenerated by
`python tools/docs/gen_lib_docs.py` in P11).
