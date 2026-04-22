# `library.rpc`

Enables calling functions on remote peers over ENet with automatic
JSON serialisation via `lurek.serial`. Supports request/response,
fire-and-forget, and broadcast patterns.

## RPC Protocol

Messages are serialised via `lurek.serial.toJson` / `lurek.serial.fromJson`.
Three message types flow over the wire:

- **rpc_call**: `{type="rpc_call", id=N, name="fn", args={...}}`
Sender expects an `rpc_response` back with the matching `id`.
- **rpc_response**: `{type="rpc_response", id=N, success=bool, result={...}}`
Returned by the callee after executing the handler for `rpc_call`.
- **rpc_notify**: `{type="rpc_notify", name="fn", args={...}, peer_id=N}`
Fire-and-forget; no response is sent back. `peer_id` is included so
broadcast handlers can identify the originator.

## Error Handling

Set a global error callback via `onError(fn)`. The callback receives a
single string describing the error context (includes the method name when
available). Handler exceptions during `rpc_call` are caught and sent back
as `{success=false, result={error_string}}` to the caller.

## Request ID Limits

The internal request ID counter is a Lua number. In LuaJIT (double-
precision float) integers are exact up to 2^53. Call `resetIdCounter()`
to reset to 1 if your application may exceed this range.

*16 functions, 0 module fields documented.*

See: [`lurek.network`](../lua-api.md#lureknetwork), [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson), [`lurek.serial.fromJson`](../lua-api.md#lurekcodecfromjson)

## Functions

### `new(host, channel, timeout)`

Create a new RPC manager attached to a NetworkHost.

**Parameters**

- `host` *userdata* — A `lurek.network.newHost/newServer/newClient` host.
- `channel` *number* — The ENet channel used for RPC traffic.
- `timeout` *number* — Default timeout in seconds for pending calls. 0 = no timeout.

**Returns**

- *RPC* — A new RPC manager instance.

### `setLogging(enabled)`

Enable or disable debug logging via `lurek.log`. When enabled, RPC calls, responses, and errors are logged at debug level.

**Parameters**

- `enabled` *boolean* — `true` to enable, `false` to disable.

### `register(name, fn)`

Register a function callable from remote peers.

**Parameters**

- `name` *string* — Unique RPC function name.
- `fn` *function* — Handler: `fn(peer_id, arg1, arg2, ...)` → returns results.

### `unregister(name)`

Unregister a previously registered function.

**Parameters**

- `name` *string* — The RPC function name to remove.

### `onError(fn)`

Set a global error handler for RPC processing errors. The callback receives a single string that includes error context (method name, peer ID) when available.

**Parameters**

- `fn` *function* — `fn(error_string)` — called on RPC processing errors.

### `call(peer_id, name, callback, ...)`

Call a function on a specific remote peer (request/response pattern). When a matching `rpc_response` arrives in `poll()`, the `callback` is invoked with `(success, result_table)`.

**Parameters**

- `peer_id` *number* — Target peer.
- `name` *string* — Function name registered on the remote side.
- `callback` *function* — `fn(success, result)` — called when the response arrives.
- `...` *Arguments* — (must be MessagePack-serializable).

**Returns**

- *number* — Request ID for the pending call.

### `notify(peer_id, name, ...)`

Fire-and-forget call: no response expected. Includes `peer_id` in the wire message so broadcast handlers on the receiving side can identify the originator.

**Parameters**

- `peer_id` *number* — Target peer.
- `name` *string* — Function name registered on the remote side.
- `...` *Arguments* — (must be MessagePack-serializable).

### `broadcast(name, ...)`

Broadcast an RPC call to all connected peers (fire-and-forget). Includes `peer_id = 0` in the wire message (server/broadcast origin).

**Parameters**

- `name` *string* — Function name registered on remote peers.
- `...` *Arguments* — (must be MessagePack-serializable).

### `resetIdCounter()`

Reset the internal request ID counter back to 1. Useful for long-running servers to avoid exceeding the 2^53 integer precision limit of Lua numbers (LuaJIT doubles). **Warning**: Only call this when no pending calls are in flight.

### `getNextId()`

Get the current request ID counter value.

**Returns**

- *number* — The next ID that will be assigned.

### `getPendingCount()`

Get the number of pending (unresolved) RPC calls.

**Returns**

- *number*

### `setTimeout(seconds)`

Set the timeout for future pending calls (seconds). 0 = no timeout.

**Parameters**

- `seconds` *number* — Timeout in seconds. Must be >= 0.

### `poll()`

Process incoming RPC messages. Call once per frame in `lurek.process(dt)`. Dispatches received RPC calls to registered handlers and invokes pending call callbacks when matching responses arrive. Also expires timed-out pending calls.

**Returns**

- *table* — Array of `{id, success, result}` response tables (may be empty).

### `_expireTimeouts()`

Internal: expire pending calls that have exceeded their timeout.

### `_dispatch(peer_id, data, responses)`

Internal: dispatch a decoded RPC message.

**Parameters**

- `peer_id` *number* — The originating peer.
- `data` *table* — Decoded message table.
- `responses` *table* — Accumulator for response entries.

### `getHandlerCount()`

Get the number of registered RPC handlers.

**Returns**

- *number*
