### Conditional verbose mode

> See [examples/conditional-verbose-mode.lua](examples/conditional-verbose-mode.lua) for the example.

---

### Log to File (Rust Side)
`env_logger` writes to stderr by default. To capture to a file during development:

> See [snippets/log-to-file-rust-side.ps1](snippets/log-to-file-rust-side.ps1) for the example.

For production log files, consider adding a `WriteLogger` via the `fern` or `simplelog` crate alongside `env_logger` � but do not add new logging crates to Lurek2D's `Cargo.toml` without a design decision.

---

### During Tests
> See [snippets/during-tests.ps1](snippets/during-tests.ps1) for the example.

Note: `env_logger` writes to stderr. `--nocapture` shows both stdout and stderr in `cargo test`.

---

### Anti-Patterns
- **`println!` in engine code** � always use `log::info!` / `log::debug!`. `println!` bypasses the log facade and can't be filtered or silenced.
- **`log::error!` + `panic!` on the same condition** � pick one. Use `error!` for recoverable faults; use `panic!` (with `// SAFETY:` comment) only for truly unreachable invariant violations.
- **Per-frame `info!` or `warn!`** � these generate thousands of lines per second. Hot-path messages must be `debug!` or `trace!`.
- **No context in error messages** � always include the resource name, key, or value that caused the error.
- **Silencing all output in tests** � don't set `RUST_LOG=""` in test fixtures. Let tests use the default filter; the developer controls verbosity via the env var at run time.
