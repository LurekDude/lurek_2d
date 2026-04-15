# IDEA.md — `runtime` module

> Migrated from `ideas/features/engine.md` (runtime / infrastructure sections).
> Status checked against `src/runtime/` (config.rs, resource_keys.rs, shared_state.rs, etc.).
> Lua namespace: N/A — `runtime` is internal infrastructure; no direct Lua exposure.

---

## Features

### ✅ DONE — Typed Resource Keys (`SlotMap`)
**Source**: features/engine.md — Summary

`src/runtime/resource_keys.rs` — `new_key_type!` macros for:
TextureKey, FontKey, ShaderKey, MeshKey, CanvasKey, SpriteBatchKey, ParticleKey.

---

### ✅ DONE — Config Loading (`conf.toml` / `conf.lua`)
**Source**: features/engine.md — Summary

`Config::load()` supports `conf.toml` (preferred) and `conf.lua` (legacy fallback).

---

### ✅ DONE — SharedState Container
**Source**: features/engine.md — Summary

`Rc<RefCell<SharedState>>` shared between Lua closures and engine loop.
All resource pools centralized here.

---

### ✅ DONE — ModulesConfig (Selective Module Enablement)
**Source**: `src/runtime/config.rs`

`ModulesConfig` struct with per-module enable flags. Some modules conditionally
registered based on config.

> ⚠️ **NOTE**: `data_api` and `dataframe_api` are always registered regardless of
> ModulesConfig flags. See Lua API registration mismatches in repo memory.

---

### ❌ TODO — Config Fallback on `conf.lua` Parse Error
**Source**: features/engine.md — Structural Issues

Syntax error in `conf.lua` crashes before the error screen exists.
A verified default config struct allows the engine to boot and display the error.

---

### ❌ TODO — Streaming Resource Loading (Background Thread)
**Source**: general performance patterns

All resource loading (textures, audio, fonts) is synchronous on the main thread.
A background loading slot with completion callback would eliminate loading hitches in
large game loading screens.

---

### ❌ TODO — Resource Eviction Policy
**Source**: general resource management

No LRU eviction or explicit resource budget. All resources stay resident until
manually freed. Memory pressure grows proportionally with content size.

---

### ✅ DONE — Expose `lurek.engine.*` Introspection Namespace
**Source**: features/engine.md — Structural Issues

No `lurek.engine.getVersion()`, `lurek.engine.getFrameBudget()`, or
`lurek.engine.memoryUsage()` from Lua. Currently only accessible via debug overlay.
A thin `lurek.engine.*` namespace exposing read-only runtime metrics would be useful
for adaptive quality and telemetry.

---

### 🤔 CONSIDER — Config Hot Reload
**Source**: features/engine.md — Feature Gaps #1

If file watcher is added to `app` module, also support reloading `conf.toml` at runtime
for adjustable settings (window title, frame budget, active modules) without restart.
