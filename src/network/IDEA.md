# IDEA.md — `network` module

> Migrated from `ideas/features/network.md` and `ideas/performance/23-network-pipeline-future.md`.
> Status checked against `src/network/` and `src/lua_api/network_api.rs`.
> Lua namespaces: `lurek.network` (ENet UDP) and `lurek.network.net` (async HTTP/WS).

---

## Features

### ✅ DONE — HTTP Client (`httpGet`, `httpPost`)
**Source**: features/network.md — Suggestions #2 (HIGH)

`httpGet` / `httpPost` implemented in `network_api.rs` (line ~502+). Async via background
`NetworkRuntime` started with `lurek.network.newRuntime()`. Handles callbacks via `poll()`.

---

### ✅ DONE — WebSocket
**Source**: features/network.md — Suggestions #3

`openWebSocket`, `sendWebSocket`, `closeWebSocket` all implemented in `network_api.rs`
(lines ~584–609). Polled for events via `poll()`.

---

### ✅ DONE — MessagePack Serialization
**Source**: features/network.md (implied)

`network_api.rs` header (line ~3) documents MessagePack as a provided feature.

---

### ❌ TODO — Configurable Peer Limit (Increase from 8)
**Source**: features/network.md — Feature Gaps #1

8-peer limit is hardcoded. Make `maxPeers` a parameter to `lurek.network.host(port, maxPeers)`.
Many party and co-op games need 8–32 peers. Verify ENet limits.

---

### ❌ DEFERRED — NAT Punchthrough
**Source**: features/network.md — Feature Gaps #4

Requires relay server infrastructure. Deferred.

---

### ✅ DONE — Lobby / Session Discovery
**Source**: features/network.md — Feature Gaps #2

UDP LAN broadcast lobby implemented in `src/network/lobby.rs`.
API: `lurek.network.createLobby(name, port, player_count?, max_players?)` and
`lurek.network.discoverLobbies(timeout_ms?)` added to `src/lua_api/network_api.rs`.

---

### ✅ DONE — State Sync Helpers
**Source**: features/network.md — Feature Gaps #6 / Suggestions #5

`lurek.network.syncEntity(host, entity_id, data, channel?, reliable?)` added to
`src/lua_api/network_api.rs`. Packs `{id, data}` via MessagePack and broadcasts to all peers.

---

### ❌ DEFERRED — Input Prediction / Rollback (Action Games)
**Source**: features/network.md — Feature Gaps #8

Complex to implement correctly. Deferred until multiplayer action game demos prove demand.

---

### ❌ TODO — Background Network Polling via Thread
**Source**: features/network.md — Structural Issues / Suggestions #8

`poll()` runs on the main thread. For high-frequency networking, this budgets main-thread
time. Add documented guidance or native support for running network polling on a
`lurek.thread` worker and returning events to the main thread via Channel.
