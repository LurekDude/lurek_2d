# Particle System & Audio — Threading Opportunities

## Part 1: Particle System

### Current Architecture

`src/particle/system.rs` implements emitter-based 2D particles:

- Each `ParticleSystem` owns a pool of `Particle` structs
- Per-frame update iterates ALL particles sequentially:
  ```
  for particle in &mut self.particles {
      particle.position += particle.velocity * dt;
      particle.velocity += acceleration * dt;
      particle.lifetime -= dt;
      // interpolate size, color, alpha, spin
  }
  ```
- Draw phase generates one quad (4 verts, 6 indices) per living particle

### Performance Profile

| Particle Count | Update Cost (est.) | Draw Cost (est.) |
|----------------|-------------------|------------------|
| 100 | ~0.01ms | ~0.02ms |
| 1,000 | ~0.1ms | ~0.2ms |
| 10,000 | ~1.0ms | ~2.0ms |
| 50,000 | ~5.0ms | ~10.0ms |

At 60 FPS, frame budget is 16.6ms. 10,000+ particles start consuming
significant frame budget.

### Opportunity 1: Rayon Parallel Update (Effort: Low, Impact: 4–8×)

Particle updates are **embarrassingly parallel** — each particle's state
update is independent of every other particle.

```rust
use rayon::prelude::*;

// Before (sequential):
for p in &mut self.particles {
    p.update(dt);
}

// After (parallel):
self.particles.par_iter_mut().for_each(|p| {
    p.update(dt);
});
```

**Requirements**:
- `Particle` must be `Send + Sync` (it is — all fields are primitive types)
- Add `rayon` as direct dependency (already transitive via rapier2d)
- Threshold: only parallelize when `particle_count > 1000` (avoid overhead)

**Expected Speedup**:
- 4-core CPU: ~3.5× (accounting for rayon overhead)
- 8-core CPU: ~6× on 10k+ particles
- Below 1000 particles: sequential is faster (thread dispatch overhead)

### Opportunity 2: GPU Particle Simulation via Compute Shaders (Effort: HIGH)

For 50k+ particles, move the entire simulation to GPU:

```
Frame N:
  CPU: Spawn new particles → upload spawn buffer
  GPU Compute: Update all particles (position, velocity, lifetime)
  GPU Vertex: Generate quads from particle buffer
  GPU Fragment: Render with blending

No CPU readback needed — particles live entirely on GPU.
```

**wgpu Compute Shader Pattern**:
```wgsl
@compute @workgroup_size(64)
fn update_particles(@builtin(global_invocation_id) id: vec3<u32>) {
    let i = id.x;
    if (i >= particle_count) { return; }

    particles[i].position += particles[i].velocity * dt;
    particles[i].lifetime -= dt;
    // ... interpolation
}
```

**Impact**: 100× for 100k+ particles (GPU has thousands of cores)
**Risk**: Requires compute shader pipeline, GPU buffer management, and
fallback for GPUs without compute support

### Opportunity 3: Dead Particle Culling Optimization (Effort: Low)

Currently dead particles (`lifetime <= 0`) remain in the array and are
skipped with an `if` check each frame. Over time, the living/dead ratio
degrades.

**Solution**: Swap-remove dead particles and compact the array periodically:
```rust
// Every N frames, compact:
self.particles.retain(|p| p.lifetime > 0.0);
```

Or use a free-list to recycle particle slots without compaction.

---

## Part 2: Audio System

### Current Architecture

`src/audio/mixer.rs` + `src/audio/decoder.rs`:

```
Sound File (WAV/OGG/MP3/FLAC)
    ↓ std::fs::read() — BLOCKING on main thread
    ↓ rodio::Decoder::new() — BLOCKING PCM decode on main thread
    ↓ .collect::<Vec<i16>>() — full file decoded into memory
Arc<Vec<u8>> (static source)
    ↓ rodio::Sink::append() — handed to rodio's internal audio thread
Playback (rodio manages its own output thread)
```

### Bottleneck: Synchronous Audio Decoding

When `luna.audio.newSource(path, "static")` is called:
1. File is read from disk synchronously
2. Entire file is decoded to PCM synchronously
3. Result stored in `Arc<Vec<u8>>`
4. Only then does the Lua call return

A 5-second MP3 at 44.1kHz stereo = ~1.7 MB PCM. Decoding can take 10–50ms
depending on codec and file size. This **freezes the game** during loading.

### Opportunity 1: Async Audio Decoding (Effort: Low, Impact: Medium)

Use the existing `AsyncLoader` infrastructure to decode audio in background:

```rust
// In mixer.rs, modify load_source():
pub fn load_source_async(&mut self, path: &str) -> AudioLoadHandle {
    let handle = self.async_loader.request_load(path);
    AudioLoadHandle(handle)
}

// Polling from Lua:
// local snd = luna.audio.newSourceAsync("music.ogg")
// if snd:isReady() then snd:play() end
```

**Alternative**: Decode on first `play()` in a background thread:
```rust
pub fn play(&mut self, source_key: SourceKey) {
    let source = &self.sources[source_key];
    if !source.is_decoded() {
        // Spawn decode thread
        let data = source.raw_data.clone();
        thread::spawn(move || {
            let decoded = decode_to_pcm(&data);
            // Send via channel
        });
        return; // Play will start next frame when decode completes
    }
    // ... normal playback
}
```

### Opportunity 2: Streaming Decode for Large Files (Effort: Medium)

For music tracks (2+ minutes), streaming decode avoids loading the entire
file into memory:

```
Main Thread              Decode Thread
───────────              ─────────────
play("music.ogg")
  → open file
  → spawn decode thread ─→ decode chunk 1 (4096 samples)
  → rodio::Sink plays       decode chunk 2
    from ring buffer  ←─── send chunks via bounded channel
                             decode chunk 3
                             ...
```

rodio already supports `Decoder<BufReader<File>>` for streaming, but Luna2D
currently forces full decode for "static" sources.

**Solution**: Add a "stream" source type that uses rodio's native streaming:
```lua
local music = luna.audio.newSource("music.ogg", "stream")
music:play()  -- Immediate, decodes incrementally
```

Luna2D already has this concept (`SourceType::Stream`) but it re-opens the
file on each play and decodes from the main thread's perspective.

### Opportunity 3: Audio Thread for Effect Processing (Effort: High)

For games with many simultaneous sounds (30+), audio mixing can become
CPU-intensive. A dedicated audio processing thread could handle:

- Per-source DSP effects (reverb, EQ, distortion)
- Bus mixing (master, SFX, music, ambient)
- Spatial audio calculations (pan, distance attenuation)

**Architecture**:
```
Main Thread                Audio Thread           Rodio Thread
───────────                ────────────           ────────────
play(source)
  → queue command ────→ receive command
                         mix sources
                         apply effects
                         write to ring buffer ──→ output to device
```

**When Worth It**: Only if audio processing > 1ms/frame with 30+ concurrent
sounds plus DSP effects. Most 2D games won't hit this.

### Opportunity 4: Pre-decode Audio Pool at Startup (Effort: Low)

Instead of decoding on first play, decode all audio files during
`luna.load()` using multiple threads:

```lua
function luna.init()
  -- These all decode in parallel on background threads
  local futures = {
    luna.audio.preloadAsync("sfx/hit.wav"),
    luna.audio.preloadAsync("sfx/jump.wav"),
    luna.audio.preloadAsync("music/theme.ogg"),
  }
  -- Wait for all to complete
  for _, f in ipairs(futures) do f:wait() end
end
```

**Implementation**: Use a thread pool (or rayon) to decode N files in parallel
during the load phase, then cache results.

---

## Summary

| Opportunity | System | Effort | Impact | Priority |
|-------------|--------|--------|--------|----------|
| Rayon particle updates | Particle | Low | HIGH (10k+ particles) | **P1** |
| Async audio decode | Audio | Low | Medium (eliminates load stalls) | **P1** |
| Audio pre-decode pool | Audio | Low | Medium (faster startup) | **P2** |
| Dead particle compaction | Particle | Low | Low (reduces iteration) | **P3** |
| Streaming decode | Audio | Medium | Medium (memory savings) | **P3** |
| GPU particle compute | Particle | High | VERY HIGH (50k+) | **P4** |
| Audio DSP thread | Audio | High | Low (most games <30 sounds) | **P5** |
