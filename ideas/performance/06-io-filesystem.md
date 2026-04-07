# File I/O & Filesystem — Threading Opportunities

## Current Architecture

### AsyncLoader (src/filesystem/async_loader.rs)

Luna2D already has a background file loading system:

```
Main Thread                     AsyncLoader Worker Thread
───────────                     ─────────────────────────
request_load(path)
  → AtomicU64 ID++
  → SyncSender.try_send() ──→ recv() from bounded channel (64)
  → return LoadHandle           std::fs::read(path)
                                 result → Arc<Mutex<HashMap>>
poll(handle)
  → lock HashMap
  → remove + return result
```

**Strengths**:
- Non-blocking from main thread (poll-based)
- Single worker thread with bounded queue (64 pending requests)
- Results stored in `Arc<Mutex<HashMap<u64, LoadResult>>>`

**Weaknesses**:
- **Single worker thread** — sequential file reads
- No priority system (all requests equal)
- No streaming support (entire file loaded into memory)
- Queue capacity fixed at 64 (panics on overflow? or returns error?)

### GameFS (src/filesystem/mod.rs)

Sandboxed virtual filesystem:
- `read(path)` — synchronous file read, returns `Vec<u8>`
- `write(path, data)` — synchronous write to save directory
- `exists(path)` — synchronous stat
- All paths validated against sandbox roots

**All GameFS operations are synchronous and block the calling thread.**

---

## Opportunity 1: Multi-Worker AsyncLoader (Effort: Low)

### Problem
Single worker thread processes files sequentially. Loading 100 texture files
at startup takes 100× single-file-read time.

### Solution
Spawn N worker threads (default: `num_cpus / 2`, max 4):

```rust
pub fn new(worker_count: usize) -> Self {
    let (tx, rx) = mpsc::sync_channel(64);
    let rx = Arc::new(Mutex::new(rx));
    let results = Arc::new(Mutex::new(HashMap::new()));

    for _ in 0..worker_count {
        let rx = rx.clone();
        let results = results.clone();
        thread::spawn(move || {
            loop {
                let req: LoadRequest = rx.lock().unwrap().recv().unwrap();
                let data = std::fs::read(&req.path);
                results.lock().unwrap().insert(req.id, data);
            }
        });
    }
    // ...
}
```

**Impact**: 2–4× faster bulk loading on SSD (I/O parallelism)
**Limitation**: On HDD, parallel reads may be slower due to seek thrashing

### Threshold
- SSD: 2–4 workers optimal
- HDD: 1 worker (sequential access pattern is faster)
- Auto-detect: Check if storage supports parallel I/O (difficult; default to 2)

---

## Opportunity 2: Priority Loading Queue (Effort: Medium)

### Problem
All load requests are equal. A game loading a splash screen image should
get higher priority than pre-caching distant level data.

### Solution
Replace `SyncSender` with a priority queue:

```rust
enum LoadPriority {
    Critical,  // Needed this frame (texture being drawn)
    High,      // Needed soon (next scene assets)
    Normal,    // Background pre-cache
    Low,       // Speculative pre-fetch
}

struct PriorityLoadRequest {
    priority: LoadPriority,
    path: String,
    handle: LoadHandle,
}
```

Workers pull highest-priority requests first using a `BinaryHeap`.

---

## Opportunity 3: Texture Streaming (Effort: High)

### Problem
Large textures (2048×2048+) loaded entirely into memory before GPU upload.
A game with 50 large textures loads ~800MB of pixel data.

### Solution: Mipmap Streaming
1. Load smallest mipmap (e.g., 64×64) synchronously → display immediately
2. Background thread loads larger mipmaps incrementally
3. GPU texture updated progressively as higher-res data arrives

```
Frame 0: Load 64×64 thumbnail → upload to GPU → display (blurry)
Frame 5: 256×256 loaded → update GPU texture → display (better)
Frame 15: 2048×2048 loaded → final GPU texture → display (crisp)
```

### Implementation
- Requires mipmap-aware GPU texture creation (`wgpu::TextureDescriptor.mip_level_count`)
- Background thread decodes image at multiple resolutions
- Main thread uploads new mip levels as they arrive

**When Worth It**: Only for games with very large textures or limited memory.
Most 2D games use textures ≤ 512×512 where full loading is fast.

---

## Opportunity 4: Write-Behind for Save Files (Effort: Low)

### Problem
`luna.fs.write()` and `luna.savegame.save()` block the main thread
during disk I/O. Large save files (100KB+) can cause frame drops.

### Solution
Queue writes to a background thread:

```rust
pub fn write_async(&self, path: &str, data: Vec<u8>) -> WriteHandle {
    let resolved = self.resolve_write_path(path)?;
    let handle = self.next_write_id.fetch_add(1, Ordering::Relaxed);
    self.write_tx.send(WriteRequest { path: resolved, data, id: handle })?;
    WriteHandle(handle)
}
```

**Implementation**:
- Single writer thread (avoids concurrent writes to same file)
- FIFO queue for write ordering
- `poll_write(handle)` returns completion status
- **Critical**: Must flush on engine shutdown to prevent data loss

---

## Opportunity 5: Directory Scanning Parallelism (Effort: Low)

### Problem
`luna.fs.getDirectoryItems()` scans directories synchronously.
`luna.modding.scan()` reads mod manifests from disk sequentially.

### Solution
Use rayon to parallelize directory scanning:

```rust
let entries: Vec<DirEntry> = std::fs::read_dir(path)?
    .par_bridge()  // rayon parallel iterator over dir entries
    .filter_map(|e| e.ok())
    .collect();
```

For mod manifest loading:
```rust
let manifests: Vec<ModManifest> = mod_dirs
    .par_iter()
    .filter_map(|dir| {
        let manifest_path = dir.join("mod.toml");
        let content = std::fs::read_to_string(&manifest_path).ok()?;
        toml::from_str(&content).ok()
    })
    .collect();
```

**Impact**: Noticeable for games with 20+ mods or deep asset directories.

---

## Opportunity 6: Async Conf/Script Loading (Effort: Medium)

### Problem
`Config::load_from_conf_lua()` creates a temporary Lua VM and executes
`conf.lua` synchronously during startup. `main.lua` execution is also
synchronous.

### Non-Opportunity
Script loading must remain synchronous — Lua execution order matters.
However, **asset preloading** triggered by scripts can be async:

```lua
function luna.init()
    -- These should return immediately, load in background
    local img1 = luna.gfx.newImageAsync("player.png")
    local img2 = luna.gfx.newImageAsync("enemy.png")
    local snd1 = luna.audio.newSourceAsync("music.ogg")

    -- Game loop polls readiness
    -- Engine shows loading screen until all ready
end
```

---

## Current vs Proposed Architecture

### Current
```
Startup:
  [conf.lua sync] → [create window sync] → [GPU init sync]
  → [main.lua sync] → [luna.load() sync]
  → event loop

Asset Loading (during luna.load):
  [read file 1 sync] → [decode sync] → [GPU upload sync]
  → [read file 2 sync] → [decode sync] → [GPU upload sync]
  → ... (serial, one at a time)
```

### Proposed
```
Startup:
  [conf.lua sync] → [create window sync] → [GPU init sync]
  → [main.lua sync] → [luna.load() sync]
  → event loop

Asset Loading (during luna.load):
  [request file 1 async] ─→ Worker 1: [read + decode]
  [request file 2 async] ─→ Worker 2: [read + decode]
  [request file 3 async] ─→ Worker 1: [read + decode]
  Main thread: show loading screen, poll readiness
  All ready → [GPU upload batch sync] → start game
```

---

## Summary

| Opportunity | Effort | Impact | Priority |
|-------------|--------|--------|----------|
| Multi-worker AsyncLoader | Low | HIGH (bulk loading) | **P1** |
| Write-behind for saves | Low | Medium (no frame drops) | **P1** |
| Directory scan parallelism | Low | Low (faster mod loading) | **P3** |
| Priority loading queue | Medium | Medium (better UX) | **P2** |
| Texture streaming (mipmap) | High | Low (rare need for 2D) | **P4** |
| Async asset Lua API | Medium | Medium (loading screens) | **P2** |
