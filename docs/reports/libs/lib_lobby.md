# `library.lobby`

Pure-Lua lobby and room management built on `lurek.network`.

Provides room creation, joining, player tracking, ready-check
coordination, host election, and password protection for multiplayer
pre-game lobbies.

Room lifecycle:

1. Server creates a room via `createRoom(name, opts)`.
2. Players join with `joinRoom(name, ...)`.  The first player becomes host.
3. Players toggle ready state with `setReady(ready, ...)`.
4. When `isAllReady()` returns true the host may start the game.
5. Players leave with `leaveRoom(...)`; host is re-elected automatically.
6. An empty room is removed automatically.

Player states: **not-ready** (default on join) → **ready** (via setReady).


Wire format note: messages between peers are encoded with
`lurek.network.pack` / `lurek.network.unpack` (MessagePack — the canonical
ENet payload format). For human-readable persistence (e.g. saved lobby
state), use `lurek.serial.toJson` / `lurek.serial.fromJson`.

*23 functions, 0 module fields documented.*

See: [`lurek.network`](../lua-api.md#lureknetwork), [`lurek.patterns.newEventBus`](../lua-api.md#lurekpatternsneweventbus), [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson)

## Functions

### `_new(name, opts)`

Create a new Room instance.

**Parameters**

- `name` *string* — Unique room name.
- `opts` *table* — `{ maxPlayers=8, password=nil, data={} }`.

**Returns**

- *Room*

### `addPlayer(peer_id, name, data)`

Add a player to the room.

**Parameters**

- `peer_id` *number* — Peer identifier.
- `name` *string* — Display name (defaults to "Player<peer_id>").
- `data` *table* — Arbitrary per-player data.

**Returns**

- *boolean* — success
- *string|nil* — error

### `removePlayer(peer_id)`

Remove a player from the room.  Re-elects host deterministically by picking the earliest-joined remaining player.

**Parameters**

- `peer_id` *number* — Peer identifier to remove.

### `getPlayerCount()`

Return the number of players currently in this room.

**Returns**

- *number*

### `isAllReady()`

Check whether all players are ready (minimum 2 players required).

**Returns**

- *boolean*

### `getHost()`

Return the current host peer_id (or nil if empty).

**Returns**

- *number|nil*

### `new(host, channel)`

Create a new lobby manager. The lobby coordinates room creation, joining, leaving, ready-checks, and host election.  Pass a network host for online use, or `nil` for local-only / offline lobby management (e.g. tests). host.  May be `nil` for offline / test usage.

**Parameters**

- `host` *userdata* — A `lurek.network.newHost` / `lurek.network.newServer`
- `channel` *number* — ENet channel for lobby traffic.

**Returns**

- *Lobby*

### `getEventBus()`

Return the underlying `EventBus` (optional, may be nil). When non-nil, `:on(event, callback)` lets multiple listeners subscribe to the same lifecycle event without overwriting each other.  Event names match the strings passed to `:onEvent(fn)` (`room_created`, `room_removed`, `player_joined`, `player_left`, `player_ready`, `host_changed`, `player_disconnected`). unavailable in this runtime.

**Returns**

- *userdata|nil* — `EventBus` userdata, or nil if `lurek.patterns` is

See: [`lurek.patterns.newEventBus`](../lua-api.md#lurekpatternsneweventbus)

### `setPlayerName(name)`

Set the local player name used when joining rooms.

**Parameters**

- `name` *string* — Non-empty display name.

### `onEvent(fn)`

Register a callback for lobby events. For multi-listener pub-sub, prefer `:getEventBus():on(event, fn)` when `lurek.patterns` is available. `"room_created"`, `"room_removed"`, `"player_joined"`, `"player_left"`, `"player_ready"`, `"host_changed"`, `"player_disconnected"`.

**Parameters**

- `fn` *function* — `fn(event_type, data)` where event_type is one of:

See: `Lobby:getEventBus`

### `createRoom(name, opts)`

Create a new room (server-side).

**Parameters**

- `name` *string* — Room name (unique, non-empty).
- `opts` *table* — `{ maxPlayers=8, password=nil, data={} }`.

**Returns**

- *boolean* — success
- *string|nil* — error

### `removeRoom(name)`

Remove a room (server-side).  All players in the room are evicted.

**Parameters**

- `name` *string* — Room name to remove.

### `joinRoom(name, peer_id, player_name, password)`

Join a room by name (local or via network message). When `peer_id` is nil the local player joins (using peer 0 internally). When `peer_id` is provided the server records that remote peer.

**Parameters**

- `name` *string* — Room name to join.
- `peer_id` *number* — Peer joining (server-side).  Nil for local.
- `player_name` *string* — Display name override.
- `password` *string* — Room password (required if room has one).

**Returns**

- *boolean* — success
- *string|nil* — error

### `leaveRoom(peer_id)`

Leave a room. When `peer_id` is nil the local player leaves their current room. When `peer_id` is provided the server removes that remote peer from whichever room they are in.

**Parameters**

- `peer_id` *number* — Peer leaving (server-side).  Nil for local.

**Returns**

- *boolean* — success
- *string|nil* — error

### `listRooms()`

List all available rooms.

**Returns**

- *table* — Array of `{ name, players, maxPlayers, hasPassword }` tables.

### `getPlayers(name)`

Get players in a specific room (or current room if name is nil).

**Parameters**

- `name` *string* — Room name.  Defaults to the local player's room.

**Returns**

- *table* — Array of `{ peer_id, name, ready }` tables.

### `setReady(ready, peer_id)`

Set ready state for a player. When `peer_id` is nil the local player's ready state is updated in their current room.  When `peer_id` is provided the server looks up that peer's room via the internal reverse map (unified code path).

**Parameters**

- `ready` *boolean* — New ready state.
- `peer_id` *number* — Peer (server-side).  Nil for local player.

### `isAllReady()`

Check if all players in the current room are ready.

**Returns**

- *boolean*

### `getCurrentRoom()`

Get the current room name (client-side / local player).

**Returns**

- *string|nil*

### `getHost(name)`

Get the host peer_id for a room (or the local player's room).

**Parameters**

- `name` *string* — Room name.  Defaults to local player's room.

**Returns**

- *number|nil*

### `getRoomCount()`

Get the number of rooms.

**Returns**

- *number*

### `poll()`

Process incoming lobby network messages.  Call once per frame.

**Returns**

- *table* — Array of processed events.

### `_handle(peer_id, data, events)`

Internal: handle a decoded lobby message from a peer.

**Parameters**

- `peer_id` *number* — Sender peer.
- `data` *table* — Decoded lobby message.
- `events` *table* — Accumulator for emitted events.
