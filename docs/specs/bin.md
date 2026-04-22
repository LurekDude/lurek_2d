# bin

## General Info

- Module group: `Edge/Integration`
- Source path: `src/bin/`
- Lua API path(s): None direct
- Primary Lua namespace: None direct
- Rust test path(s): None dedicated
- Lua test path(s): None

## Summary

The `bin` module provides alternative binary entry points for Lurek2D, built
alongside the primary `lurek2d` executable. It is an Edge/Integration tier
compilation unit — not a library — containing only Cargo `[[bin]]` targets that
call into the engine through the `lurek_run()` entry function.

**`lurekc` — Console-less Windows launcher**: `src/bin/lurekc.rs` is the
standard distribution binary for Windows end-users. The
`#![cfg_attr(windows, windows_subsystem = "windows")]` attribute suppresses
the Windows console window at launch, eliminating the black terminal backdrop
that `lurek2d.exe` shows in a developer session. On Linux and macOS the
attribute is a no-op, making `lurekc` binary-equivalent to `lurek2d`. Both
binaries call the same `lurek_run()` entry function and therefore share the
same engine behaviour, configuration, and Lua scripting environment.

**Development vs. distribution workflow**: During development, `lurek2d.exe`
is preferred because engine log lines, Lua `print()` output, and `RUST_LOG`
diagnostics stream to the visible console. For a player-facing Windows release
the distribution step (`tools/dist/dist.ps1`) packages `lurekc.exe` as the
primary launcher so games run silently as expected desktop applications. Both
binaries are produced from the same `cargo build --release` invocation.

**`lurekc` is the only file in this module**: There is exactly one source file
in `src/bin/`. It contains a four-line `main()` that calls `lurek_run()`. Any
future headless, server, or batch-runner binary entry point should be added as
a new `[[bin]]` target here, following the same thin-wrapper pattern.

**Design constraints**: The `bin` directory intentionally contains no domain
logic, no library code, and no `lurek.*` Lua-reachable API surface. Keeping
entry points thin ensures that the boot sequence, argument parsing, and engine
configuration live entirely in `src/main.rs` → `lurek_run()`, so changes
propagate automatically to every binary variant without duplication.

**Scope boundary**: Edge/Integration tier. A Cargo `[[bin]]` target, not a
`mod` in the library tree. No types, no public functions, no Lua API surface.
## Files

- `lurekc.rs`: Minimal console-less launcher for Windows builds that applies the windows_subsystem attribute and then delegates straight to lurek2d::lurek_run(). This file should stay intentionally tiny because it is only a wrapper binary.

## Types

- No public Rust types are currently exposed from this module.

## Functions

- No public Rust functions are currently exposed from this module.

## Lua API Reference

- No dedicated direct `lurek.*` namespace is exposed by this module.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/bin/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- This module has no dedicated direct `lurek.*` namespace and is usually consumed through higher integration layers.
