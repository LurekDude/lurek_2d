---
name: threading
description: "Load this skill when designing or implementing multi-threaded Lua behaviour in Lurek2D using the lurek.thread API: spawning worker threads, using Channel for inter-VM communication, handling errors in background threads, or understanding which lurek.* modules are safe to use in worker VMs. Use for: background computation, async file I/O in workers, producer-consumer patterns, parallel data processing. Skip it for Rust-side thread management internals (see docs/specs/thread.md), or for general game scripting (use lua-scripting)."
companion_files:
  examples: [examples/spawning-a-thread.lua, examples/creating-a-channel.lua, examples/starting-a-thread.lua, examples/channel-operations.lua, examples/channelvalue-constraint.lua, examples/error-handling-in-workers.lua, examples/error-handling-in-workers-2.lua, examples/work-queue.lua, examples/background-save.lua]
  templates: []
  snippets: [snippets/threading-model.txt, snippets/extended-notes.md]
related_skills: []
---

# threading

## Mission

# Threading — Lurek2D

## When To Load

- Adding background computation or I/O to a game via `lurek.thread.newThread()`
- Designing a producer-consumer or work-queue pattern with `Channel`
- Working out which `lurek.*` API is safe to call from a worker thread Lua VM
- Handling errors thrown in a background thread
- Explaining the threading model to a new contributor

## When To Skip

- Skip it for Rust-side thread management internals (see docs/specs/thread.

## Domain Knowledge

### Owns
- Lurek2D threading model: one Lua VM per thread, no shared state
- `lurek.thread.*` Lua API patterns
- `Channel` communication patterns (push / pop / demand)
- Worker VM module restrictions
- Error reporting from worker VMs back to the main VM
- When to use threads vs when to stay single-threaded

---

### Threading Model
Lurek2D uses **one Lua VM per thread**. Worker threads cannot share `SharedState` with the main game thread. This eliminates data races at the cost of requiring explicit message passing for all cross-thread communication.

> See [snippets/threading-model.txt](snippets/threading-model.txt) for the example.

**Key consequence**: The main thread is the only thread that can call `lurek.gfx.*`, `lurek.audio.*`, `lurek.physics.*`, and `lurek.input.*`. Workers send results back via `Channel` and the main thread applies them.

---

### Core API
### Spawning a thread

> See [examples/spawning-a-thread.lua](examples/spawning-a-thread.lua) for the example.

### Creating a channel

> See [examples/creating-a-channel.lua](examples/creating-a-channel.lua) for the example.

### Starting a thread

> See [examples/starting-a-thread.lua](examples/starting-a-thread.lua) for the example.

### Channel operations

> See [examples/channel-operations.lua](examples/channel-operations.lua) for the example.

---

### ChannelValue Constraint
**Channels carry only these Lua types:**

| Lua type | Transmitted as |
|----------|---------------|
| `nil` | nil |
| `boolean` | bool |
| `number` | f64 |
| `string` | heap-copied string |
| UserData | **NOT supported** — will error |
| table | **NOT supported** — serialize to string first |

To pass structured data:
> See [examples/channelvalue-constraint.lua](examples/channelvalue-constraint.lua) for the example.

---

### Worker VM — Safe Modules
Worker threads get an isolated VM with only these `lurek.*` modules available:

| Module | Available in worker? | Notes |
|--------|---------------------|-------|
| `lurek.math` | ✅ Full | Safe (pure computation) |
| `lurek.thread` | ✅ Full | Channels, thread control |
| `lurek.time` | ✅ Read-only | `lurek.time.getTime()`, `lurek.time.getDelta()` |
| `lurek.fs` | ✅ Read-only | File reads only; no write |
| `lurek.platform` | ✅ Read-only | OS info, `getProcessorCount()` |
| `lurek.gfx` | ❌ | GPU resources are main-thread only |

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/threading-model.txt](snippets/threading-model.txt) — Threading Model
- [examples/spawning-a-thread.lua](examples/spawning-a-thread.lua) — Spawning a thread
- [examples/creating-a-channel.lua](examples/creating-a-channel.lua) — Creating a channel
- [examples/starting-a-thread.lua](examples/starting-a-thread.lua) — Starting a thread
- [examples/channel-operations.lua](examples/channel-operations.lua) — Channel operations
- [examples/channelvalue-constraint.lua](examples/channelvalue-constraint.lua) — ChannelValue Constraint
- [examples/error-handling-in-workers.lua](examples/error-handling-in-workers.lua) — Error Handling in Workers
- [examples/error-handling-in-workers-2.lua](examples/error-handling-in-workers-2.lua) — Error Handling in Workers
- [examples/work-queue.lua](examples/work-queue.lua) — Work Queue
- [examples/background-save.lua](examples/background-save.lua) — Background Save
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
