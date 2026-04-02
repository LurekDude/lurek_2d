# The Zen of Luna2D

> First principles for every design decision in the Luna2D engine.
> When in doubt, return here before picking an implementation approach.

---

## The Core Idea

A game creator should write Lua. The engine writes everything else.

The engine owns the GPU, the threads, and the OS. The game script owns the game logic. Neither side reaches into the other's domain without a clean contract.

---

## Principles

### 1. One executable, one install

The engine is a single binary. No separate runtime, no DLL maze, no version negotiation between the game and the engine. Drop `luna2d.exe` next to `main.lua` and run it.

### 2. Lua scripts are the game

The user writes Lua. The engine never exposes Rust internals. Every API lives under `luna.*`, is synchronous from the Lua perspective, and has sensible defaults so a beginner can call it without looking anything up.

### 3. The engine is silent unless something is wrong

No debug output unless the user asks for it. No allocation churn every frame. No blocking the game loop for file I/O. Errors are descriptive and point at the Lua source line, not at an internal Rust stack trace.

### 4. The dependency graph is load-bearing

Every module has a tier. The tier determines what it may import. Tiers are not aesthetic — they are what makes it possible to ship a light build (Tier 1 only) or a full RPG build (all tiers) from the same codebase without circular dependencies. Violating tier rules is not a style issue; it is a correctness issue.

### 5. Tests are proof, not process

A test exists because it catches a real failure mode, not because policy requires one. Every new public Rust API must have an integration test. Every new `luna.*` function must have a Lua BDD test. No feature ships without its test.

### 6. Platforms are a Tier 4 problem

Steam, Epic, itch.io, cloud saves — these are distribution concerns, not engine concerns. Core engine modules (Tier 1–3) never import platform SDK code. The engine should compile and run without any platform SDK present.

### 7. The engine runs on a laptop from 2018

Integrated GPU, 8 GB RAM, no discrete card. The engine must be playable on this hardware. Spare GPU bandwidth for the game, not the engine.

### 8. A blank `main.lua` is a valid game

The engine starts, opens a window, and ticks without crashing if `main.lua` is completely empty. Every callback is optional. The engine does not mandate any particular game structure.

### 9. Desktop first, desktop only (for now)

Windows, Linux, macOS. x86_64 and ARM. No WASM, no mobile, no consoles. Doing one platform well beats doing five platforms badly.

### 10. Lua is synchronous; Rust is parallel

Lua scripts run single-threaded. If a game needs background work (pathfinding, chunk gen, AI), it spawns a `luna.thread.new()` worker (Rust thread with a `Channel`). The Lua side polls; it never blocks. The engine never creates threads on behalf of the script without explicit opt-in.

---

## Decision Heuristics

When you face a design choice, run it through these:

- **Could an AI agent use this API correctly without a clarifying question?** If not, simplify the API.
- **Does this add a cross-tier import?** If so, it needs explicit justification in the design-assumptions doc.
- **Does this allocate per frame?** If so, can it be pre-allocated at startup?
- **Is this a platform concern?** If so, it belongs in Tier 4, not in core.
- **Does the simplest implementation work on an integrated GPU?** If not, it's too expensive.
- **Would removing this force a game to roll its own version in Lua?** If yes, it belongs in the engine. If no, skip it.
