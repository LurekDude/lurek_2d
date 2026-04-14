# bin

## General Info

- Module group: `Edge/Integration`
- Source path: `src/bin/`
- Lua API path(s): None direct
- Primary Lua namespace: None direct
- Rust test path(s): None dedicated
- Lua test path(s): None

## Summary

The `bin` module provides alternative binary entry points for the Lurek2D engine. It is not a library module — it contains only `main()`-bearing source files for building secondary executables alongside the primary `lurek2d` binary.

Currently the module contains a single entry point: `lurekc.rs`, the console-less launcher for Windows distribution. On Windows the `#![cfg_attr(windows, windows_subsystem = "windows")]` attribute prevents the black terminal console window from appearing alongside the game window when an end-user launches a distributed game. On Linux and macOS the attribute is ignored and `lurekc` behaves identically to the standard `lurek2d` binary. Both binaries call the same `lurek2d::lurek_run()` entry function.

Game developers use `lurekc.exe` when packaging a release for Windows users to provide a polished, console-free experience. The standard `lurek2d.exe` remains the preferred binary for development because it shows engine log output in the console.

**Scope boundary**: Edge/Integration tier. A Cargo binary target, not a library module. Contains no domain logic.

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
