# Savegame, Modding, and I/O Threading Deep Dive

## Modules Covered
- `src/savegame/` — slot-based save/load, schema migration
- `src/modding/` — mod discovery, dependency resolution, hot-reload
- `src/filesystem/` — async loading (extension of 06-io-filesystem.md)

---

## Savegame Module

### Current: Synchronous Write Blocks Frame

```rust
// src/savegame/slot.rs — approximate current behavior
pub fn save(&self, slot: usize) -> Result<(), SaveError> {
    let serialized = toml::to_string(&self.data)?;  // ~1ms for 50KB save
    let path = self.slot_path(slot);
    std::fs::write(&path, serialized)?;              // ~5ms for HDD write
    Ok(())
}
```

Total: **6ms per save call** = one dropped frame at 60Hz. On spinning HDD,
this can be 50ms.

---

### Fix 1: Write-Behind Thread

```rust
// src/savegame/async_save.rs
use std::sync::mpsc;
use std::thread;

pub struct AsyncSaveSystem {
    tx:     mpsc::Sender<SaveJob>,
    handle: Option<thread::JoinHandle<()>>,
}

struct SaveJob {
    path:    std::path::PathBuf,
    content: String,
    reply:   Option<mpsc::SyncSender<Result<(), std::io::Error>>>,
}

impl AsyncSaveSystem {
    pub fn new() -> Self {
        let (tx, rx) = mpsc::channel::<SaveJob>();
        let handle = thread::spawn(move || {
            while let Ok(job) = rx.recv() {
                let result = std::fs::write(&job.path, &job.content);
                if let Some(reply) = job.reply {
                    let _ = reply.send(result.map_err(Into::into));
                }
            }
        });
        Self { tx, handle: Some(handle) }
    }
    
    /// Fire-and-forget save (returns immediately)
    pub fn save_async(&self, path: impl Into<std::path::PathBuf>, content: String) {
        let _ = self.tx.send(SaveJob { path: path.into(), content, reply: None });
    }
    
    /// Blocking save with confirmation (for critical saves)
    pub fn save_sync(&self, path: impl Into<std::path::PathBuf>, content: String) 
        -> Result<(), std::io::Error> 
    {
        let (reply_tx, reply_rx) = mpsc::sync_channel(1);
        let _ = self.tx.send(SaveJob { path: path.into(), content, reply: Some(reply_tx) });
        reply_rx.recv().map_err(|_| std::io::Error::other("save thread died"))?
    }
}
```

**Lua API**:
```lua
luna.savegame.save(1, data)         -- fire-and-forget (no frame stall)
luna.savegame.save_sync(1, data)    -- wait for confirmation
local pending = luna.savegame.is_pending(1)  -- poll for completion
```

---

### Fix 2: Atomic Save File (Crash-Safe)

```rust
pub fn atomic_write(path: &Path, content: &str) -> std::io::Result<()> {
    // Write to temp file next to target
    let temp_path = path.with_extension("tmp");
    std::fs::write(&temp_path, content)?;
    // Atomic rename: either old or new, never corrupt
    std::fs::rename(&temp_path, path)?;
    Ok(())
}
```

Prevents save corruption on crash mid-write (operating system guarantees
rename is atomic on local filesystems).

---

### Fix 3: Parallel Schema Migration

When loading a save from an older game version, multiple slots may need
migration. With 10 save slots and a 3-hop migration chain:

```rust
pub fn migrate_all_slots(slots: &mut [SaveSlot], current_version: u32) {
    use rayon::prelude::*;
    slots.par_iter_mut().for_each(|slot| {
        while slot.schema_version < current_version {
            apply_migration(slot);
        }
    });
}
```

**Speedup**: 4× for 10+ slots with complex migrations.

---

## Modding Module

### Dependency Resolution: Topological Sort

```rust
// src/modding/mod.rs — Kahn's algorithm for dependency order
pub fn topological_sort(mods: &[ModManifest]) -> Result<Vec<String>, String> {
    let mut in_degree: HashMap<&str, usize> = HashMap::new();
    let mut graph: HashMap<&str, Vec<&str>> = HashMap::new();
    
    for m in mods {
        in_degree.entry(&m.id).or_insert(0);
        for dep in &m.dependencies {
            *in_degree.entry(&m.id).or_insert(0) += 1;
            graph.entry(dep.as_str()).or_default().push(&m.id);
        }
    }
    
    let mut queue: VecDeque<&str> = in_degree.iter()
        .filter(|(_, &d)| d == 0).map(|(&id, _)| id).collect();
    let mut order = Vec::new();
    
    while let Some(id) = queue.pop_front() {
        order.push(id.to_string());
        for &dependent in graph.get(id).into_iter().flatten() {
            *in_degree.get_mut(dependent).unwrap() -= 1;
            if in_degree[dependent] == 0 { queue.push_back(dependent); }
        }
    }
    
    if order.len() == mods.len() { Ok(order) }
    else { Err("Circular dependency detected".into()) }
}
```

This is already O(n + e) — optimal. Key benefit: cycle detection for user error messages.

---

### Parallel Mod Asset Loading

After dependency order is resolved, independent mods at the same depth
level can load their assets in parallel:

```rust
// src/modding/loader.rs
pub fn load_mods_parallel(ordered_mods: &[String], loader: &AssetLoader) {
    // Group by dependency depth (layered parallel execution)
    let layers = build_dependency_layers(ordered_mods);
    
    for layer in &layers {
        // All mods in a layer are independent — load in parallel
        layer.par_iter().for_each(|mod_id| {
            loader.load_mod_assets(mod_id);
        });
    }
}
```

**Speedup**: For a mod pack with 20 independent "content mods" (no deps between them),
all 20 load in parallel → **20× faster** startup with N cores.

---

### Hot-Reload: Event-Driven File Watch

```rust
// src/modding/watcher.rs — file watcher for mod hot-reload
use notify::{Watcher, RecursiveMode, Event};

pub struct ModWatcher {
    _watcher: notify::RecommendedWatcher,
    changes:  mpsc::Receiver<std::path::PathBuf>,
}

impl ModWatcher {
    pub fn poll_changes(&self) -> Vec<std::path::PathBuf> {
        self.changes.try_iter().collect()
    }
}
```

Hot-reload path:
1. `file_watcher` thread detects `.lua` file change in mod folder
2. Sends `PathBuf` over mpsc to main thread
3. Main thread's `luna.update` polls → triggers mod reload on next frame
   (no blocking required)

---

## Filesystem — AsyncLoader at Scale

Extending `06-io-filesystem.md` with large-scale scenarios:

### Mount Priority: Fastest Reads First

```rust
// src/filesystem/gamefs.rs
// Mount order = read priority
// Memory-mapped files are fastest (OS handles caching)
pub fn mount_memory_map(path: &Path) { ... }  // highest priority
pub fn mount_directory(path: &Path) { ... }   // mid priority
pub fn mount_zip(path: &Path) { ... }          // slowest (decompress)
```

### Prefetch Scheduling

Pre-announce assets that will be needed 2–3 seconds in future:

```lua
-- In a loading screen:
luna.filesystem.prefetch("level_data/world2.dat")
luna.filesystem.prefetch("audio/boss_music.ogg")

-- When actually used 3 seconds later:
local data = luna.filesystem.read("level_data/world2.dat")  -- already in cache
```

---

## Summary

| Module | Optimization | Effort | Impact |
|--------|-------------|--------|--------|
| Savegame | Write-behind thread | 3 days | 0 frame stall |
| Savegame | Atomic rename save | 1 day | Crash safety |
| Savegame | Parallel migration | 2 days | N× for N slots |
| Modding | Topological sort | Already optimal | Free cycle detection |
| Modding | Parallel asset loading | 2 days | N× per layer |
| Modding | File-watch hot reload | 3 days | No reload stall |
| Filesystem | Memory-map priority | 2 days | OS-level read cache |
| Filesystem | Prefetch API | 2 days | Zero load stall |
