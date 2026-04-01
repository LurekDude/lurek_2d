---
name: threading-patterns
description: "Load this skill when working with Luna2D background threads: Channel inter-thread communication, Worker background Lua execution, or thread-safe data passing. Skip it for single-threaded game logic, AI, or rendering."
---

# Threading Patterns — Luna2D Engine

## Load When

- Spawning background Worker threads for Lua execution
- Sending data between threads via Channel
- Designing thread-safe communication patterns
- Working with `luna.thread.*` or `luna.channel.*` APIs

## Owns

- `src/thread/` module — Channel and Worker implementations
- `src/lua_api/thread_api.rs` — `luna.thread.*` and `luna.channel.*` Lua bindings
- Inter-thread message passing patterns
- Background Lua execution lifecycle

## Does Not Cover

- Async pathfinding → use `pathfinding-systems` skill (PathThreadPool)
- Game loop timing → use `game-loop` skill
- Audio threading → use `audio-integration` skill (rodio handles its own threads)

## Live Repository Contracts

- `src/thread/channel.rs` — `Channel` (FIFO inter-thread message queue)
- `src/thread/worker.rs` — `Worker` (background Lua VM thread)
- `tests/thread_tests.rs` — Channel push/pop, type preservation, named channels

## Decision Rules

- **Channels are FIFO** — messages delivered in insertion order
- **Channel values preserve types** — Nil, Bool, Number, String all round-trip correctly
- **Named channels share via Arc** — multiple references to the same channel by name
- **Workers run separate Lua VMs** — no SharedState sharing between threads; each Worker has its own VM
- **Communication is message-based** — threads exchange data through Channel, never shared mutable state
- **Workers are for CPU-heavy Lua** — pathfinding, generation, AI planning; not for I/O
- **Main thread polls results** — check Channel in `luna.update()` for completed work

## Best Practices

- Use Channel for all inter-thread data — never use shared mutable state
- Keep Worker tasks self-contained — pass all needed data via Channel at spawn
- Poll for results in `luna.update()` — don't block the game loop waiting for Workers
- Use named channels for typed communication (`"pathfinding_results"`, `"generation_done"`)
- Limit active Workers — each spawns a Lua VM; too many waste memory

## Anti-Patterns

- **Shared mutable state**: Trying to access SharedState from a Worker — Workers have separate VMs
- **Blocking main thread**: Waiting synchronously for Worker results in `luna.update()` — poll instead
- **Unlimited Workers**: Spawning a Worker per entity — pool work into fewer Workers
- **Large messages**: Sending huge tables through Channel — serialize/chunk large data
