# network — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/network.md`
**Files**: UDP networking via ENet, peer-to-peer model

## Purpose

Lightweight multiplayer networking: create/join sessions, send/receive data over UDP (reliable and unreliable channels) via ENet, max 8 peers. Exposes host and client roles with event-based message handling.

## Current Feature Summary

- `lurek.network.host(port, maxPeers?)` — start a host (server) on a port
- `lurek.network.connect(host, port)` — connect to a host as client
- `lurek.network.send(peerId, data, reliable?)` — send data to a specific peer
- `lurek.network.broadcast(data, reliable?)` — send data to all connected peers
- `lurek.network.poll()` — poll for events (connect, disconnect, receive)
- `lurek.network.disconnect(peerId?)` — disconnect specific peer or all
- `lurek.network.getPeers()` — list connected peers with round-trip time
- `lurek.network.getStats()` — bandwidth and packet stats
- Event-driven: `on_connect`, `on_disconnect`, `on_receive` callbacks
- ENet reliable ordered delivery (TCP-like) AND unreliable channels
- Max 8 peers (hardcoded)
- Ping/RTT measurement

## Feature Gaps

1. **8-peer limit is very restrictive**: Hardcoded to 8 peers. Many indie multiplayer games need 16-32 players. Even party games want 8-12.
2. **No lobby/room system**: No way to discover or list available sessions. Must know the host IP/port.
3. **No matchmaking**: No service for finding players. Expected for any multiplayer-focused engine.
4. **No NAT traversal**: Can't connect players behind routers without manual port forwarding. This blocks casual multiplayer.
5. **No WebSocket/HTTP**: No web protocols. Can't communicate with web services, REST APIs, or leaderboard servers.
6. **No state synchronization**: No built-in entity/state sync. Must manually serialize and send all game state.
7. **No delta compression**: No snapshot diffing or delta encoding for efficient state updates.
8. **No rollback/netcode**: No built-in input prediction, rollback, or lag compensation. Essential for action games.
9. **No encryption**: Data is sent in plaintext. No TLS or encryption layer.
10. **No connection timeout config**: No way to configure timeout, retry, or keepalive parameters.
11. **No bandwidth limiting**: No throttling or QoS controls.

## Structural Issues

- **Correct Tier 1 placement**: Networking is a core subsystem. No Tier 1 cross-dependencies.
- **UDP-only is correct for game networking**: TCP is wrong for real-time games. ENet's reliable UDP is the right choice.
- **No thread integration**: Network polling is synchronous on the main thread. Should support polling from a `lurek.thread` worker for non-blocking operation.
- **"network" is a big scope**: The module is currently small (basic UDP), but the feature gaps suggest it should grow significantly. Consider sub-namespaces: `lurek.network.udp.*`, `lurek.network.http.*`.

## Suggestions

1. **Increase peer limit**: Make max peers configurable at host creation time, with a reasonable default (32-64).
2. **Add HTTP client**: `lurek.network.httpGet(url, callback)` / `lurek.network.httpPost(url, body, callback)` — essential for leaderboards, analytics, content downloads. Run in a background thread.
3. **Add WebSocket**: `lurek.network.websocket(url)` — persistent connection for real-time web services.
4. **Add NAT punchthrough**: Even basic UDP hole-punching with a relay server would make casual multiplayer viable.
5. **Add state sync helpers**: `lurek.network.syncEntity(id, data)` / `lurek.network.onEntityUpdate(callback)` — automatic serialization and delta compression for entity states.
6. **Add input prediction/rollback**: `lurek.network.sendInput(frame, input)` with configurable rollback window. Complex but transformative for fighting/action games.
7. **Add lobby system**: `lurek.network.createLobby(name, maxPlayers)` / `lurek.network.listLobbies()` — even a LAN discovery version would help.
8. **Add background polling**: Allow `lurek.network.poll()` to run on a worker thread via `lurek.thread`, returning events on the main thread.

## Competitor Comparison

| Feature | Lurek2D | Engine A | Engine B | Engine D | Engine C |
|---|---|---|---|---|---|
| UDP (ENet) | ✅ | ✅ (enet) | ❌ | ❌ | ✅ |
| Reliable channels | ✅ | ✅ | N/A | N/A | ✅ |
| HTTP client | ❌ | ✅ (socket) | ✅ | ✅ | ✅ |
| WebSocket | ❌ | ✅ (plugin) | ❌ | ✅ | ✅ |
| State sync | ❌ | ❌ | ❌ | ✅ | ✅ |
| Rollback netcode | ❌ | ❌ | ❌ | ✅ (GGRS) | ❌ |
| Lobby/matchmaking | ❌ | ❌ | ❌ | ❌ | ❌ |
| Max peers | 8 | 64+ | N/A | Unlimited | 4096 |

Lurek2D's 8-peer limit and lack of HTTP/WebSocket are the critical gaps. Most competitors at least offer HTTP for web service communication.

## Priority

**HIGH** — HTTP client is the highest-priority addition (leaderboards, content delivery, OAuth). Peer limit increase is a quick fix. NAT traversal and state sync are medium-term improvements that would make Lurek2D competitive for multiplayer games.
