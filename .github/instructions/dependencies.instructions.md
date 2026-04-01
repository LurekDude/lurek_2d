---
applyTo: "Cargo.toml"
---

# Dependencies Instructions

`Cargo.toml` is the single source of truth for all Rust dependencies. All version pins must be semver-compatible, Lua must remain vendored, and no unnecessary dependencies may be added.

## Core Rules

- **Pin semver**: use exact minor versions (e.g., `"0.27"`, `"0.11"`) — not `"*"` or `">= 0.9"` wildcards
- **Lua stays vendored**: `mlua` must always have `features = ["lua54", "vendored"]` — never depend on a system Lua installation
- **No GPU rendering dependencies**: no `wgpu`, `gl`, `glow`, `glfw`, `sdl2` — the engine is software-only
- **Minimize the dependency count**: prefer Rust stdlib solutions over new crates for simple tasks
- **Check for security advisories** with `cargo audit` before adding any new crate

## Canonical Dependency Set

| Crate | Version | Purpose | Must-have features |
|---|---|---|---|
| `winit` | `0.30` | Windowing and input (ApplicationHandler) | none |
| `wgpu` | `22` | GPU-accelerated 2D rendering | `bytemuck`, `pollster` |
| `mlua` | `0.9` | Lua 5.4 scripting | `lua54`, `vendored` |
| `image` | `0.24` | PNG/JPEG texture loading | none |
| `rodio` | `0.17` | Audio playback | none |
| `log` | `0.4` | Logging facade | none |
| `env_logger` | `0.10` | Log configuration | none |

## Compliance

- `[[bin]] name = "luna2d"` — the binary name must stay `luna2d`
- `[lib] name = "luna2d"` — the library name must stay `luna2d` for integration tests
- `edition = "2021"` — do not downgrade to 2018

## Avoid

- Adding `serde` unless a feature genuinely requires serialization (e.g., save files)
- Adding `tokio` or `async-std` — the engine is synchronous by design
- Duplicate functionality: if `rodio` can decode a format, don't add another audio decoder
- `[patch.crates-io]` without a documented reason in a comment
- Dev-dependency leaking into the main library build
