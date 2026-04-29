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
- The repo uses the log crate; src/log/ and startup paths determine sinks and default filter behavior.
- Avoid noisy info or warn logs in hot paths such as render, physics, timer, or per-frame AI loops.
- Include enough identifiers for grep and parse_test_log.py without leaking absolute paths or private implementation detail.
- Trace/debug is for transient state; info/warn/error should map to operational impact a user or tester can understand.
- For tests, pair RUST_LOG with --nocapture before adding temporary output.
- Logging should help diagnosis without becoming a hidden performance bug.
- RUST_LOG filters, log level choice, and parseable context are especially important because repo tooling already expects structured diagnosis from captured output.
- Logging in hot loops should be rare and deliberate; trace or debug should guard high-frequency details.
- This skill owns runtime observability wording and filter strategy, not root-cause reasoning or offline trend analysis.
## Companion File Index
- None.

## References
- src/log/
- src/main.rs
- logs/
- tools/audit/parse_test_log.py
