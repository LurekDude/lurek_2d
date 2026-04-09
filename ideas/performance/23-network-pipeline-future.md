# Network & Pipeline Modules — Future Threading Architecture

## Modules Covered
- `src/network/` — not yet implemented (placeholder)
- `src/pipeline/` — not yet implemented (placeholder)

---

## Network Module: Async Architecture Blueprint

When `src/network/` is implemented, the threading design choices made at
the start will determine performance for the lifetime of the module.
This report documents the right architecture to adopt from day one.

---

### Why Synchronous Networking Would Fail

A synchronous socket read blocks the Lua VM:

```rust
// BAD: blocks the game loop
let data = tcp_stream.read(&mut buf)?;  // could block 100ms on slow connection
```

At 60Hz, 100ms stall = **6 dropped frames**. Unacceptable.

---

### Recommended Architecture: tokio + mpsc bridge

```
┌─────────────────────────────────┐
│          Main Thread            │
│   Lua: lurek.network.poll()      │
│   Returns queued packets        │
│                                 │
│   ┌────────────────────────┐    │
│   │  Incoming packet queue  │◄──┼── rx channel
│   │  Outgoing packet queue  │───┼──► tx channel
│   └────────────────────────┘    │
└─────────────────────────────────┘
              ↑↓ mpsc
┌─────────────────────────────────┐
│      tokio Runtime Thread       │
│   TCP/UDP socket handling       │
│   Non-blocking I/O (io_uring)   │
│   Connection pool management    │
│   TLS handshakes (async)        │
│   Reconnect logic               │
└─────────────────────────────────┘
```

```rust
// src/network/runtime.rs
pub struct NetworkRuntime {
    sender:   mpsc::Sender<OutgoingPacket>,
    receiver: mpsc::Receiver<IncomingPacket>,
    handle:   std::thread::JoinHandle<()>,
}

impl NetworkRuntime {
    pub fn start(config: NetworkConfig) -> Self {
        let (out_tx, out_rx) = mpsc::channel::<OutgoingPacket>();
        let (in_tx, in_rx)   = mpsc::channel::<IncomingPacket>();
        
        let handle = std::thread::spawn(move || {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_io().enable_time().build().unwrap();
            rt.block_on(async move {
                run_network(config, out_rx, in_tx).await;
            });
        });
        
        Self { sender: out_tx, receiver: in_rx, handle }
    }
    
    pub fn poll(&self) -> Vec<IncomingPacket> {
        self.receiver.try_iter().collect()
    }
}
```

**Luna API**:
```lua
local net = lurek.network.connect("ws://localhost:8080")
lurek.update = function(dt)
    local packets = net:poll()
    for _, pkt in ipairs(packets) do
        handle_packet(pkt)
    end
end
```

---

### UDP Multiplayer: Single Thread for Multiple Clients

For real-time multiplayer (game servers, P2P), a single tokio thread
handles thousands of UDP sockets with `tokio::select!`:

```rust
// Handle 100 client connections without spawning 100 threads
tokio::select! {
    data = udp_socket.recv_from(&mut buf) => { ... },
    _ = tick_timer.tick() => { broadcast_game_state(); },
    msg = game_event_rx.recv() => { forward_to_clients(msg); },
}
```

**Scale**: 1 network thread handles 1,000+ clients with async I/O.

---

### Bandwidth Optimization: Delta Compression

Instead of sending full game state each frame, send only deltas:

```rust
// src/network/delta.rs
pub fn compress_state_delta(
    prev: &GameStateSnapshot,
    curr: &GameStateSnapshot
) -> Vec<u8> {
    // Only serialize fields that changed
    let mut delta = Vec::new();
    for entity_id in curr.touched_entities.iter() {
        if let (Some(p), Some(c)) = (prev.entities.get(entity_id), curr.entities.get(entity_id)) {
            if p != c { delta.extend_from_slice(&serialize_entity_delta(p, c)); }
        }
    }
    delta
}
```

**Bandwidth reduction**: 90% reduction vs full state for slow-moving games.

---

## Pipeline Module: Parallel Data Transform Architecture

When `src/pipeline/` is implemented (ETL chains, filter/map/reduce nodes),
design for parallel stage execution from the start.

---

### Architecture: Staged Pipeline with rayon

```
Input Data
   │
[Stage 1: Filter]    ← rayon par_iter().filter()
   │
[Stage 2: Map]       ← rayon par_iter().map()
   │
[Stage 3: Aggregate] ← rayon par_iter().fold() + reduce()
   │
Output
```

```rust
// src/pipeline/mod.rs
pub struct Pipeline<T: Send> {
    stages: Vec<Box<dyn Stage<T> + Send + Sync>>,
}

impl<T: Send + Sync + Clone> Pipeline<T> {
    pub fn run_parallel(&self, data: Vec<T>) -> Vec<T> {
        data.into_par_iter()
            .map(|item| self.apply_stages(item))
            .filter(Option::is_some)
            .map(Option::unwrap)
            .collect()
    }
}
```

**Speedup**: Each pipeline run is O(n/threads) when stages are independent.

---

### GPU Compute Pipeline (Dataframe-scale)

For pipeline stages operating on millions of rows (analytics, game replay processing):

```wgsl
// pipeline_filter.wgsl
@group(0) @binding(0) var<storage, read> input: array<Record>;
@group(0) @binding(1) var<storage, read_write> output: array<Record>;
@group(0) @binding(2) var<storage, read_write> count: atomic<u32>;

@compute @workgroup_size(256)
fn filter_stage(@builtin(global_invocation_id) id: vec3<u32>) {
    let i = id.x;
    if i >= arrayLength(&input) { return; }
    if passes_filter(input[i]) {
        let out_idx = atomicAdd(&count, 1u);
        output[out_idx] = input[i];
    }
}
```

**Stream compaction** (filter → compact → next stage) is a classic GPU pattern.

---

### Pipeline Memory Layout

Design for minimal allocation in the hot path:

```rust
// Pre-allocated double buffer for pipeline stages
pub struct PipelineBuffer<T> {
    buffers: [Vec<T>; 2],
    current: usize,  // which buffer is the "input"
}

impl<T: Clone> PipelineBuffer<T> {
    pub fn apply_stage<F: Fn(&T) -> Option<T>>(&mut self, f: F) {
        let (src, dst) = if self.current == 0 {
            let (a, b) = self.buffers.split_at_mut(1);
            (&a[0], &mut b[0])
        } else {
            let (a, b) = self.buffers.split_at_mut(1);
            (&b[0], &mut a[0])
        };
        dst.clear();
        dst.extend(src.iter().filter_map(f));
        self.current ^= 1;
    }
}
```

**Result**: Zero allocation per pipeline step (reuses pre-allocated capacity).

---

## Summary

| Module | Architecture | Threading | Scale |
|--------|-------------|-----------|-------|
| Network | tokio + mpsc bridge | 1 async thread | 1k+ clients |
| Network | Delta compression | None | -90% bandwidth |
| Network | UDP multiplayer | tokio::select | Real-time |
| Pipeline | Staged rayon | 4+ cores | 100k+ items |
| Pipeline | GPU stream compaction | Compute shader | 1M+ items |
| Pipeline | Double-buffer stages | None (no alloc) | All sizes |
