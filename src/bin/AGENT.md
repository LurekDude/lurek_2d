# bin

## Module Info
- Module name: bin
- Module group: Edge/Integration
- Spec path: docs/specs/bin.md
- Lua API path(s): None
- Rust test path(s): None dedicated
- Lua test path(s): None

## Module Purpose

The bin module holds alternative compiled entry points for the engine. It exists so the project can ship or develop with different binary behaviors while still routing all real startup logic through the shared library crate.

Right now the important distinction is between the main console-attached launcher and the console-less Windows launcher under src/bin/. The bin module keeps that packaging concern separate from engine startup behavior, which still belongs in lib.rs and app.

This module does not own configuration parsing, platform initialization, splash behavior, or the event loop. If a change affects engine boot semantics rather than which binary wrapper calls into them, it belongs somewhere else.

## Files
- lurekc.rs: Minimal console-less launcher for Windows builds that applies the windows_subsystem attribute and then delegates straight to lurek2d::lurek_run(). This file should stay intentionally tiny because it is only a wrapper binary.

## Key Types
- main: The only meaningful symbol in this module is the binary entry function in lurekc.rs. Its entire purpose is to hand control to the shared library entry point without adding alternate boot logic.