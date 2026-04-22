# `library.netstate`

Pure-Lua network state synchronization and turn-based game support.

Built on `lurek.network`, provides automatic state replication between peers
with per-key versioning, change callbacks, authority control, delta updates,
and turn-based game management.

**Authority model**: One peer is the *authority* (typically the server).
Only the authority can write state via `set()`. Non-authority peers receive
delta updates and full-state snapshots. Authority is set at construction
and can be toggled with `setAuthority()`.

**Per-key versioning**: Each key maintains its own monotonically increasing
version number. When a delta arrives, only entries whose version exceeds
the locally stored per-key version are applied — preventing stale replays
even under concurrent updates.

**Turn-based protocol**: Optional. When `turnBased = true`, the authority
manages a turn counter and a rotating peer order. `beginTurn()` advances
the turn and broadcasts the change. Clients receive turn events via `onTurn`.

**Wire format**: state deltas and full-state snapshots are encoded with
`lurek.network.pack` / `lurek.network.unpack` (MessagePack — the canonical
ENet payload format). For human-readable persistence (e.g. write a snapshot
to disk for inspection), pair `:getAll()` with `lurek.serial.toJson`.

**Hash helper**: `:hashState()` is a deterministic FNV-1a digest of all
replicated keys/values; useful for desync detection. When a future
`lurek.data.hash` lift lands (P4 candidate), this should delegate.

**Limitation**: `requestFullState()` has no built-in timeout. If the authority
never responds, the client will not receive a snapshot. Callers should
implement their own timer-based retry or use the `onFullStateTimeout`
callback.

*30 functions, 0 module fields documented.*

See: [`lurek.network`](../lua-api.md#lureknetwork), [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson), [`lurek.timer.Scheduler`](../lua-api.md#lurektimescheduler)

## Functions

### `setLogging(enabled, custom_log)`

Enable or disable debug logging. When enabled, state changes, authority violations, sync events, and turn changes are logged via `lurek.log.debug` (if available) or a custom function. `lurek.log.debug` when available, otherwise logging is silently skipped.

**Parameters**

- `enabled` *boolean* — Whether to enable logging.
- `custom_log` *function* — Optional `fn(msg)` override. If nil, uses

### `new(host, opts)`

Create a new network state synchronization manager. The `host` parameter is a `lurek.network` host (server, client, or host). If `opts.authority` is not provided, authority defaults to `host:isServer()` when the host supports it, otherwise `false`. or nil for offline/testing mode (network operations become no-ops). - `channel` (number, default 0): Network channel for messages. - `authority` (boolean): Override authority detection. - `turnBased` (boolean, default false): Enable turn-based protocol. - `maxDirtyKeys` (number|nil): Maximum number of dirty keys tracked per sync cycle. When exceeded, oldest dirty keys are evicted. Nil = unlimited.

**Parameters**

- `host` *userdata|nil* — A `lurek.network.newHost/newServer/newClient` host,
- `opts` *table* — Configuration options:

**Returns**

- *NetState* — A new NetState manager instance.

### `setAuthority(auth)`

Set whether this instance is the authority (can write state).

**Parameters**

- `auth` *boolean* — True to grant authority, false to revoke.

### `isAuthority()`

Check if this instance is the authority.

**Returns**

- *boolean* — True if this peer is the authority.

### `onChange(fn)`

Set a global change callback fired for any key change.

**Parameters**

- `fn` *function* — Callback signature: `fn(key, value, old_value, peer_id)`.

### `onFullStateTimeout(fn)`

Register a callback invoked if a full-state request times out. The caller is responsible for implementing timer logic and calling this callback from their own timeout handler.

**Parameters**

- `fn` *function* — Callback signature: `fn()`.

### `set(key, value)`

Set a synced value. Only the authority can set values. Non-authority calls are rejected and return `false, "not authority"`. Keys must be non-empty strings.

**Parameters**

- `key` *string* — The state key (must be a non-empty string).
- `value` *Any* — MessagePack-serializable value.

**Returns**

- *boolean* — True if the value was set successfully.
- *string|nil* — Error message on failure.

### `get(key)`

Get the current value of a synced key.

**Parameters**

- `key` *string* — The state key.

**Returns**

- *any|nil* — The value, or nil if not set.

### `getKeyVersion(key)`

Get the per-key version number.

**Parameters**

- `key` *string* — The state key.

**Returns**

- *number* — The version for this key, or 0 if not set.

### `getAll()`

Get all synced state as a flat table.

**Returns**

- *table* — `{ key = value, ... }` snapshot of current state.

### `onChanged(key, fn)`

Register a callback for changes to a specific key.

**Parameters**

- `key` *string* — The state key to watch.
- `fn` *function* — Callback signature: `fn(value, old_value, peer_id)`.

### `clearCallbacks(key)`

Remove all callbacks for a key.

**Parameters**

- `key` *string* — The state key.

### `getVersion()`

Get the highest version number across all keys.

**Returns**

- *number* — The maximum per-key version, or 0 if no state exists.

### `getKeyCount()`

Get the number of synced keys.

**Returns**

- *number* — Count of keys in the state table.

### `getDirtyCount()`

Get the number of dirty (unsent) keys.

**Returns**

- *number* — Count of keys pending sync.

### `hasKey(key)`

Check if a key exists in the state.

**Parameters**

- `key` *string* — The state key.

**Returns**

- *boolean* — True if the key has been set.

### `remove(key)`

Remove a key from the synced state. Authority only.

**Parameters**

- `key` *string* — The state key to remove.

**Returns**

- *boolean* — True if the key was removed.
- *string|nil* — Error message on failure.

### `setTurnOrder(order)`

Set the turn order (array of peer IDs). Resets the turn index to 1 and turn counter to 0. Each element must be a number. Invalid entries are silently filtered.

**Parameters**

- `order` *table* — Array of peer IDs: `{ peer_id_1, peer_id_2, ... }`.

### `beginTurn()`

Begin a new turn. Advances to the next player in the turn order. Only the authority should call this. If the turn order is empty, the turn counter advances but `turn_peer` remains nil.

**Returns**

- *number* — The new turn number.
- *number|nil* — The peer whose turn it is, or nil if order is empty.

### `endTurn()`

End the current turn. Alias for `beginTurn()` — advances to next.

**Returns**

- *number* — The new turn number.
- *number|nil* — The peer whose turn it is.

### `getCurrentTurn()`

Get the current turn number.

**Returns**

- *number* — The current turn counter value.

### `getTurnPeer()`

Get the peer ID whose turn it currently is.

**Returns**

- *number|nil* — The current turn peer, or nil if not set.

### `onTurn(fn)`

Register a callback for turn changes.

**Parameters**

- `fn` *function* — Callback signature: `fn(turn_number, peer_id)`.

### `isTurn(peer_id)`

Check if it is a specific peer's turn.

**Parameters**

- `peer_id` *number* — The peer to check.

**Returns**

- *boolean* — True if it is this peer's turn.

### `sync()`

Broadcast all dirty state to connected peers. Call once per frame after all `set()` calls (e.g. at end of `lurek.process(dt)`). Requires a valid host; no-op if host is nil or instance is not authority.

### `poll()`

Process incoming state updates from the network. Call once per frame. Requires a valid host; returns empty table if host is nil.

**Returns**

- *table* — Array of `{ key, value, old_value, peer_id }` change events.

### `_markDirty(key)`

Mark a key as dirty, respecting the maxDirtyKeys limit.

**Parameters**

- `key` *string* — The key to mark dirty.

### `hashState()`

Compute a deterministic FNV-1a 32-bit digest of the current synced state. Useful for desync detection between authority and clients (compare digests after a sync round; mismatch indicates state divergence). TODO(P4 lift): when `lurek.data.hash` lands in the engine (P4 lift candidate), this method should delegate to it for the inner string-hashing step.  Until then a small inline FNV-1a implementation keeps the library self-contained and works on both LuaJIT (`bit` library) and Lua 5.4 (native `~`/`&`).

**Returns**

- *number* — 32-bit unsigned hash of the sorted (key, value) pairs.

See: [`lurek.data.hash`](../lua-api.md#lurekdatahash)

### `toJson()`

Serialise the current state to a JSON string via `lurek.serial.toJson`. Suitable for human-readable persistence (NOT for the wire — use the normal `:sync()` MessagePack path for peer-to-peer traffic). Returns nil if `lurek.serial` is unavailable in this runtime.

**Returns**

- *string|nil* — JSON snapshot of `:getAll()`, or nil.

See: [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson)

### `requestFullState()`

Request a full state snapshot from the authority. Useful when a client joins mid-game. **Limitation**: This method has no built-in timeout. If the authority never responds, the client will not receive a snapshot. Callers should implement their own timer-based retry, e.g.: ns:requestFullState() local deadline = lurek.timer.getTime() + 5.0 -- In process loop: if lurek.timer.getTime() > deadline then retry or invoke --   ns:onFullStateTimeout callback

**Returns**

- *boolean* — False if this instance is the authority (no-op), true if sent.

See: [`lurek.timer.getTime`](../lua-api.md#lurektimegettime)
