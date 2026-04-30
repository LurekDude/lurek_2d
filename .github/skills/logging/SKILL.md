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
- The repo uses the log crate, and src/log/ plus startup paths define sinks and default filter behavior, so log changes should stay consistent with the existing runtime pipeline.
- Avoid noisy info or warn logs in hot paths such as render, physics, timer, worker polling, or per-frame AI loops; the observability gain rarely justifies the runtime cost.
- Include enough identifiers for grep and parse_test_log.py without leaking absolute paths, private handles, or irrelevant implementation detail.
- Trace and debug are for transient state and developer diagnosis, while info, warn, and error should map to operational impact a user or tester can understand.
- One log line should usually answer one question: what operation ran, what object or path it touched, and why it succeeded, failed, or changed state.
- For tests, pair RUST_LOG with --nocapture before adding temporary output; prefer filter tuning to permanent noisy logs when the problem is still under investigation.
- Avoid duplicated logging at every layer of the same failure path; log where the event becomes actionable, then propagate errors cleanly.
- RUST_LOG filters, log level choice, and parseable context matter because repo tooling already expects structured diagnosis from captured output and grep-driven review.
- Logging in hot loops should be rare and deliberate; if high-frequency detail is necessary, guard it tightly behind trace or debug and keep the wording compact.
- Good log wording in this repo is stable, grep-friendly, and concrete enough that later audits can cluster similar failures without post-hoc interpretation.
- This skill owns runtime observability wording, level choice, and filter strategy, not general debugging method, failure semantics, or offline analytics.
## Companion File Index
- None.

## References
- src/log/
- src/main.rs
- logs/
- tools/audit/parse_test_log.py
