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
- Use the log crate flow, not println or eprintln in engine paths.
- Match log level to impact and frequency.
- Avoid noisy per-frame info or warn logs.
- Include enough context to make grep and diagnosis useful.
- Keep hot-path logging behind debug or trace where appropriate.
- Make tests and repro runs explicit about RUST_LOG and nocapture when needed.

## Companion File Index
- None.

## References
- src/main.rs
- src/log/