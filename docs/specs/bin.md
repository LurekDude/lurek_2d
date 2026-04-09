# `bin` — Agent Reference

| Property       | Value                                            |
|----------------|--------------------------------------------------|
| **Tier**       | Special — CLI entry point (not a numbered tier)  |
| **Status**     | Implemented — Full                               |
| **Lua API**    | —                                                |
| **Source**      | `src/bin/`                                       |
| **Rust Tests** | —                                                |
| **Lua Tests**  | —                                                |
| **Architecture** | —                                              |

## Summary

The `bin` module contains the `lunec` binary entry point — a console-less launcher for
Luna2D on Windows. Setting `#![cfg_attr(windows, windows_subsystem = "windows")]` suppresses
the black terminal window that would otherwise appear alongside the game window, providing a
polished experience for distributed games. On Linux and macOS the attribute is ignored and
`lunec` behaves identically to the standard `luna2d` binary.

The `lunec` binary is auto-discovered by Cargo from `src/bin/lunec.rs`. It contains a single
`main()` function that delegates immediately to `luna2d::luna_run()` — the shared entry point
defined in `src/lib.rs`. All CLI argument parsing, config loading, `.lunar` archive extraction,
panic hook installation, and engine loop execution happen inside `luna_run()`, not in this file.

The companion binary `luna2d` lives at `src/main.rs` and is the console-attached development
binary. Both binaries call the same `luna_run()` function; the only difference is the
`windows_subsystem` attribute on `lunec`.

A batch-file wrapper `lunec.bat` exists at the repository root for scenarios where a separately
compiled `lunec.exe` is unavailable — it launches `luna2d.exe` via `start /B` to detach the
console window.

**Scope boundary**: `lunec.rs` contains zero engine logic. It is a three-line file whose sole
purpose is the Windows subsystem attribute plus a call to the library crate. Any changes to
boot sequence, CLI parsing, or config loading belong in `src/lib.rs` (`luna_run`) or
`src/engine/app.rs` (`App::new` / `App::run`), never here.

## Architecture

```
                     +---------------+      +---------------+
                     |  luna2d.exe   |      |  lunec.exe    |
                     |  src/main.rs  |      | src/bin/lunec |
                     |  (console)    |      |  (no console) |
                     +-------+-------+      +-------+-------+
                             |                      |
                             +----------+-----------+
                                        |
                                        v
                            +-----------------------+
                            |  luna2d::luna_run()   |
                            |     src/lib.rs        |
                            +-----------+-----------+
                                        |
              +-------------------------+-------------------------+
              v                         v                         v
    Install panic hook         Parse CLI args            Extract .lunar
    (Windows msgbox)           (game dir or cwd)         archive if needed
              |                         |                         |
              +-------------------------+-------------------------+
                                        |
                                        v
                            +-----------------------+
                            | Config::load_from_    |
                            |   conf_lua(&game_dir) |
                            +-----------+-----------+
                                        |
                                        v
                            +-----------------------+
                            |  App::new(config)     |
                            |  app.run(game_dir)    |
                            +-----------------------+
```

## Source Files

| File       | Purpose                                                                              |
|------------|--------------------------------------------------------------------------------------|
| `lunec.rs` | Console-less binary entry point; sets `windows_subsystem = "windows"` and calls `luna_run()` |

## Submodules

None. The `bin` directory contains a single standalone binary source file with no submodules.

## Key Types

### Structs

No public structs.

### Enums

No public enums.

## Lua API

No Lua API — CLI binary entry point only.

## Lua Examples

`lunec` is not invoked from Lua. Usage is from the command line:

```sh
# Launch a game without a console window (Windows release distribution)
lunec path/to/my_game

# Show the Luna2D splash screen without a console window
lunec

# Launch a .lunar archive (zip-packaged game)
lunec my_game.lunar
```

Equivalent development commands using the console-attached binary:

```sh
# Development — console stays open for log output
luna2d path/to/my_game
cargo run -- path/to/my_game
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 0     |
| `enum`    | 0     |
| `fn`      | 1     |
| **Total** | **1** |

## References

| Module   | Relationship | Notes                                                             |
|----------|--------------|-------------------------------------------------------------------|
| `lib.rs` | Calls into   | `lunec.rs` calls `luna2d::luna_run()` — the shared boot function  |
| `engine` | Indirect     | `luna_run()` creates `Config` and `App`; `lunec` never touches them directly |

The companion binary `src/main.rs` (`luna2d`) is the console-attached counterpart. Both share
identical behaviour via `luna_run()`; the only difference is the Windows subsystem attribute.

## Notes

- **Three-line file**: `lunec.rs` is intentionally minimal. If you need to change boot
  behaviour, edit `luna_run()` in `src/lib.rs` or `App::new()` / `App::run()` in
  `src/engine/app.rs`. Never add logic to `lunec.rs` itself.
- **Cargo auto-discovery**: `src/bin/lunec.rs` is automatically discovered as the `lunec`
  binary by Cargo. There is no explicit `[[bin]]` entry for it in `Cargo.toml` — only the
  main `luna2d` binary at `src/main.rs` has one.
- **Windows-only effect**: The `#![cfg_attr(windows, windows_subsystem = "windows")]`
  attribute only affects Windows builds. On Linux and macOS `lunec` is functionally identical
  to `luna2d`.
- **Batch-file fallback**: `lunec.bat` at the repo root provides console-less launching
  without a separate binary by using `start "" /B luna2d.exe %*`. This is used in
  distribution scenarios where only one `.exe` is shipped.
- **No tests**: `lunec.rs` has no dedicated tests because it contains no logic — it is a
  pass-through to `luna_run()`. Testing the boot sequence is covered by integration tests
  that exercise `luna_run()` or `App::run()` directly.
