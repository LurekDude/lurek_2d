# Modding Demo

Demonstrates the Luna2D virtual filesystem mod-loading workflow: mounting an external folder at a virtual path, reading files from it, and executing Lua code from a mod.

## What It Shows

- **Mounting a mod folder** — `luna.filesystem.mount("mods/hello_mod", "/hello_mod")`
- **Reading mod assets** — `luna.filesystem.read` to load a text greeting from the mod
- **Executing mod Lua** — `luna.filesystem.load` to load and run an `init.lua` from the mod
- **Unmounting** — `luna.filesystem.unmount` to release the virtual path after loading
- Graceful fallback when the mod folder doesn't exist

## Setup

The demo reads from `examples/mods/hello_mod/`. Create that folder with:

```
examples/mods/hello_mod/greeting.txt  — any greeting text
examples/mods/hello_mod/init.lua      — optional Lua code to run
```

If the folder is absent the demo reports a friendly fallback message on-screen.

## Controls

No interactive controls — the mod loads and unmounts during `luna.load()`.

## Run

```sh
cargo run -- examples/modding_demo
```
