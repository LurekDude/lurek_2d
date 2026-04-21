# `lobby` — Agent Reference (Lunasome)

| Property       | Value                                                                                                            |
| -------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Tier**       | Tier 3 — Lunasome (pure Lua, no Rust dependencies)                                                               |
| **Source**     | `library/lobby/init.lua`                                                                                         |
| **Lua Tests**  | `tests/lua/library/test_library_lobby.lua`                                                                       |
| **Depends on** | `lurek.network` (mandatory for online mode), `lurek.patterns` (optional, for `EventBus`), `lurek.log` (optional) |
| **Status**     | Full                                                                                                             |

## Summary

Pure-Lua **lobby manager** for multiplayer pre-game coordination. Provides
named rooms with optional passwords, player tracking with display names,
ready-check coordination, deterministic host election (earliest-joined
remaining player), automatic empty-room cleanup, and a network message
protocol on top of `lurek.network`.

Works in two modes:

- **Online**: pass a `lurek.network` host (server, client, or peer host) to
  `M.new(host, channel?)` and call `:poll()` once per frame to drain incoming
  messages.
- **Offline / test**: pass `nil` as the host. All network calls become
  no-ops; the lobby tracks state in-process, which makes it ideal for unit
  tests and single-player UI prototyping.

## Wire Format

Lobby messages are encoded with `lurek.network.pack` / `lurek.network.unpack`
(MessagePack — the canonical ENet payload format). For human-readable
persistence (e.g. saving lobby snapshots to disk) use
`lurek.serial.toJson` / `lurek.serial.fromJson` outside of the wire path.

## Events

`Lobby:onEvent(fn)` registers a single legacy callback receiving
`(event_type, data)`. For multi-listener pub-sub, `Lobby:getEventBus()` returns
a `lurek.patterns.newEventBus()` instance (when the runtime exposes
`lurek.patterns`); subscribers can call `:on(event_type, fn)` on it without
overwriting each other. Both paths receive identical payloads.

Event types: `room_created`, `room_removed`, `player_joined`, `player_left`,
`player_ready`, `host_changed`, `player_disconnected`.

## Architecture

```
M.new(host?, channel?) → Lobby
  ├── _host         (lurek.network host or nil)
  ├── _channel      (ENet channel, default 0)
  ├── _rooms        ({ name = Room })
  ├── _peer_rooms   ({ peer_id = room_name } reverse map)
  ├── _my_room      (current room name on the local peer)
  ├── _my_name      (display name; setPlayerName(name))
  ├── _on_event     (single legacy callback)
  └── _event_bus    (optional lurek.patterns.newEventBus())

Lobby methods:
  setPlayerName(name)
  onEvent(fn)              | getEventBus() → EventBus|nil
  createRoom(name, opts?)  → ok, err?    (server-side)
  removeRoom(name)
  joinRoom(name, peer?, player_name?, password?) → ok, err?
  leaveRoom(peer?) → ok, err?
  setReady(ready, peer?)
  isAllReady() → boolean   (≥2 players, all ready)
  listRooms() → { {name, players, maxPlayers, hasPassword}, ... }
  getPlayers(name?) → array of {peer_id, name, ready}
  getCurrentRoom() → string|nil
  getHost(name?) → peer_id|nil
  getRoomCount() → number
  poll() → array of processed events  (call once per frame)

Room (internal):
  addPlayer / removePlayer (deterministic host re-election)
  getPlayerCount / isAllReady / getHost
```

## Source Files

| File                     | Purpose                                                   |
| ------------------------ | --------------------------------------------------------- |
| `library/lobby/init.lua` | Full implementation — Room internal type + Lobby manager. |

## Key Types

| Type  | Constructor                  | Purpose                                                  |
| ----- | ---------------------------- | -------------------------------------------------------- |
| Lobby | `M.new(host?, channel?)`     | Lobby manager (online or offline).                       |
| Room  | (internal, via `createRoom`) | Single room state: players, password, host, max players. |

## Notes

- Host election is **deterministic** by join order — the earliest-joined
  remaining player becomes the new host on disconnect.
- `isAllReady()` requires ≥2 players to return true (single-player rooms can't
  start).
- Empty rooms are auto-removed.
- `joinRoom` accepts an optional `password`; rooms without a password ignore
  the parameter.
- Wire-format layer (`lurek.network.pack`) is binary MessagePack — do not mix
  with `lurek.serial.toJson` payloads on the same channel.

## Lua API Reference

See LDoc-generated page: `docs/API/libs/lobby.md` (regenerated by
`python tools/docs/gen_lib_docs.py` in P11).
