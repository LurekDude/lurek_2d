---
name: logging
description: "Load this skill when adding or tuning log output, log levels, RUST_LOG filters, or log-based diagnosis. Skip it for general debugging strategy or log analytics."
---
# logging

## Mission
- Own runtime log output, level choice, and filter strategy.

## When To Load
- Add new log lines.
- Change log levels.
- Tune RUST_LOG usage.
- Diagnose behavior through logs.

## When To Skip
- General debugging strategy.
- Analytics from saved logs.

## Domain Knowledge
- Log crate target naming convention: `lurek2d::<module>` for engine modules (e.g., `lurek2d::render`, `lurek2d::physics`), `lurek2d::lua_api::<module>` for binding layer. RUST_LOG filters work on these targets: `RUST_LOG=lurek2d::render=trace,lurek2d::lua_api=debug cargo run`.
- Level assignment rules: `error!` = operation failed and the engine cannot continue safely (fatal, developer must act). `warn!` = operation failed but the engine recovered or fell back (developer should investigate). `info!` = significant lifecycle event (startup, shutdown, scene load). `debug!` = developer-relevant decision point. `trace!` = per-frame or high-frequency detail. Never use `info!` for anything that fires more than once per second at runtime.
- Hot path log guard: every `trace!` or `debug!` call inside `on_process`, render loop, physics step, or audio callback must be guarded by `if log::log_enabled!(log::Level::Trace)`. Unguarded log calls in hot paths disable the JIT for surrounding Lua code and add Rust string allocation overhead even when output is suppressed.
- `println!` in `src/<module>/` is a defect — the `module-audit` scanner flags it. All engine output goes through `log::*`. `eprintln!` is acceptable in `src/bin/` and `tools/` only.
- Context format rule: `warn!("lurek2d::audio: failed to load source '{}': {}", normalized_path, err)`. The message must include the module path, the key identifiers (path, handle, config key), and the error. Do not include absolute host paths — use the GameFS-normalized path.
- `parse_test_log.py` expects log lines in the standard `[LEVEL target] message` format. Custom log formats or log redirection that changes this format will break the CI log parser.
- `src/log/` configures the log sink (env_logger or custom). When modifying startup log configuration, check that headless test mode (`LUREK_HEADLESS=1`) does not suppress error-level output needed by CI.
- For Lua-side logging: `lurek.log.debug(msg)`, `lurek.log.warn(msg)`, `lurek.log.error(msg)` route through the same sink with target `lurek2d::lua_script`. Game authors should use these instead of `print()` for structured, filterable output.
- Structured event logging for analytics: game events (score, death, level complete) should use `lurek.log.event(name, data_table)` rather than plain log messages. This produces JSON lines in `logs/data/` that analytics tools can query.
## Companion File Index
- None.

## References
- src/log/
- src/main.rs
- logs/
- tools/audit/parse_test_log.py
