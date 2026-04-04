# Luna2D

Luna2D is a desktop-only 2D game engine written in Rust that executes Lua game scripts. You write game logic in Lua through the `luna.*` API, and the engine handles the runtime work: windowing, GPU rendering, input, audio, physics, filesystems, and frame orchestration.

## What Luna2D emphasizes

- Lua scripting with a straightforward callback model and a single `luna.*` namespace
- A Rust engine core for GPU work, multithreading, and other performance-critical systems
- GPU rendering through `wgpu` on Windows, Linux, and macOS
- A layered runtime split into Baseline, Tier 1 core engine subsystems, Tier 2 reusable engine extensions, and Tier 3 Lunasome libraries in `library/`
- An AI-first workflow, with the official developer tooling delivered through a separate first-party VS Code extension

## Quick Start

```bash
cargo build
cargo run
cargo run -- examples/hello_world
cargo run -- examples/physics_demo
cargo build --release
```

`cargo run` with no game directory shows the built-in splash screen. `cargo run -- <path-to-game>` runs a folder containing a `main.lua` entry point.

While the splash screen is visible you can also **drag and drop a game folder** (one that contains `main.lua`) onto the window to load it immediately — no restart required. Dropping a file inside a game folder is also accepted.

## Repository Layers

Luna2D's active stack is organized as follows:

- Baseline — `src/math/` and `src/engine/`, the always-on runtime substrate
- `src/lua_api/` — the bridge that registers the public `luna.*` API
- Tier 1 — core engine subsystems in `src/`
- Tier 2 — reusable engine extensions in `src/`
- Tier 3 — Lunasome, the pure-Lua standard library in `library/`
- `examples/` — runnable reference projects built on the public Lua surface

Legacy gameplay-oriented Rust modules still exist under `src/` during migration. They remain buildable contributor-facing code, but they are not the current Tier 3 layer.

## Design Principles

- Luna2D is a 2D engine. It does not target a full 3D pipeline.
- Luna2D is desktop only: Windows, Linux, and macOS. Mobile and WASM are out of scope.
- The engine is a runtime, not an IDE. Official tooling lives in the separate VS Code extension.
- Game code stays simple in Lua; batching, GPU submission, and concurrency are engine responsibilities.
- Documentation and AI usability are treated as product requirements, not optional extras.

## VS Code Extension

The official developer tooling for Luna2D lives in the separate first-party VS Code extension under [vscode-extension/README.md](vscode-extension/README.md). It is a companion product, not part of the runtime itself, and provides API documentation, example-running workflows, and AI-oriented tooling for Luna2D projects.

## Documentation

Two generated references exist for different audiences: [docs/api_generated.md](docs/api_generated.md) is the Rust-side API inventory for engine contributors, while [docs/lua_api_reference_generated.md](docs/lua_api_reference_generated.md) is the `luna.*` reference for Lua API users.

- [docs/](docs/)
- [docs/architecture.md](docs/architecture.md)
- [docs/zen-of-luna.md](docs/zen-of-luna.md)
- [docs/design-assumptions.md](docs/design-assumptions.md)
- [library/README.md](library/README.md)
- [docs/API/test-structure-audit.md](docs/API/test-structure-audit.md)
- [docs/api_generated.md](docs/api_generated.md)
- [docs/lua_api_reference_generated.md](docs/lua_api_reference_generated.md)

## Security And License

Security reporting instructions are in [SECURITY.md](SECURITY.md).

Luna2D is released under the MIT License. See [LICENSE](LICENSE).

